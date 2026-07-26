---
phase: 12-unified-design-token-pipeline
reviewed: 2026-07-26T23:11:16Z
depth: standard
files_reviewed: 31
files_reviewed_list:
  - hypr/.config/hypr/config/animations.conf
  - hypr/.config/hypr/hyprland.conf
  - hypr/.config/hypr/scripts/motion-lint
  - hypr/.config/hypr/scripts/motion-switch.sh
  - hypr/.config/hypr/scripts/quickshell-doctor
  - hypr/.config/hypr/scripts/tests/motion-fixtures/compliant-gtk4.css
  - hypr/.config/hypr/scripts/tests/motion-fixtures/compliant-hypr.conf
  - hypr/.config/hypr/scripts/tests/motion-fixtures/compliant-qml.qml
  - hypr/.config/hypr/scripts/tests/motion-fixtures/poisoned-dangling-gtk4.css
  - hypr/.config/hypr/scripts/tests/motion-fixtures/poisoned-dangling-hypr.conf
  - hypr/.config/hypr/scripts/tests/motion-fixtures/poisoned-dangling-qml.qml
  - hypr/.config/hypr/scripts/tests/motion-fixtures/poisoned-raw-gtk4.css
  - hypr/.config/hypr/scripts/tests/motion-fixtures/poisoned-raw-hypr.conf
  - hypr/.config/hypr/scripts/tests/motion-fixtures/poisoned-raw-qml.qml
  - matugen/.config/matugen/config.toml
  - matugen/.config/matugen/templates/qml-palette.json
  - quickshell/.config/quickshell/modules/Colours.qml
  - quickshell/.config/quickshell/modules/Motion.qml
  - quickshell/.config/quickshell/modules/Probe.qml
  - quickshell/.config/quickshell/modules/qmldir
  - quickshell/.config/quickshell/shell.qml
  - stow.sh
  - theme-engine/.config/theme-engine/contract.json
  - theme-engine/.config/theme-engine/lib/commit.sh
  - theme-engine/.config/theme-engine/lib/contract.sh
  - theme-engine/.config/theme-engine/lib/generate.sh
  - theme-engine/.config/theme-engine/lib/gtk.sh
  - theme-engine/.config/theme-engine/lib/motion.sh
  - theme-engine/.config/theme-engine/motion.json
  - theme-engine/.config/theme-engine/theme-doctor
  - theme-engine/.config/theme-engine/theme-parity
  - theme-engine/.config/theme-engine/theme-stress-test
  - wleave/.config/wleave/style.css
findings:
  critical: 2
  warning: 4
  info: 1
  total: 7
status: issues_found
---

# Phase 12: Code Review Report

**Reviewed:** 2026-07-26T23:11:16Z
**Depth:** standard
**Files Reviewed:** 31
**Status:** issues_found

## Summary

Reviewed the full unified design-token pipeline: `motion.json` → `lib/motion.sh`'s
three-target renderer → `motion-lint`'s deny-by-default gate → the Quickshell
`Colours`/`Motion` singletons and `Probe.qml` inspector → the theme-doctor/theme-parity/
theme-stress-test gate scripts → `stow.sh`'s new first-boot motion seed.

The overall design is careful and the team has clearly already hunted (and fixed) several
"gate silently passes" bugs of exactly the shape this review was asked to prioritize (the
jq `// empty`/boolean-false bug, the `os.walk` symlink-following bug, and the universal
`animation-delay` false positive). This review found **two more bugs in that same shape**
that were not yet closed, plus four narrower robustness/consistency gaps. All are traceable
to specific lines with a reproduction where practical.

## Critical Issues

### CR-01: motion-lint vacuously passes a raw duration hidden inside a CSS `var()` fallback

**File:** `hypr/.config/hypr/scripts/motion-lint:467-468, 494-536`
**Issue:**
`VAR_MOTION_RE` (line 467) only matches a *bare* reference — `var(--motion-duration-standard)`
with nothing else inside the parens. `VAR_MASK_RE` (line 468), used to blank out legitimate
`var(...)` usages before CHECK B's raw-value scan, matches greedily up to the first `)` —
i.e. it swallows the *entire* `var(...)` expression, fallback value included.

Standard CSS syntax allows a fallback: `var(--motion-duration-standard, 200ms)`. For a line
using that form:

- CHECK A (`VAR_MOTION_RE.finditer(line)`) produces **zero** matches — the reference is
  silently never validated for resolution at all (not flagged as dangling, not confirmed as
  resolving).
- CHECK B masks the whole `var(--motion-duration-standard, 200ms)` span via `VAR_MASK_RE`
  before scanning for raw literals — the embedded `200ms` raw duration is erased before
  `DURATION_RE` ever sees it.

Verified directly:
```
$ python3 -c "
import re
VAR_MOTION_RE = re.compile(r'var\(\s*--(motion-[A-Za-z0-9_-]+)\s*\)')
VAR_MASK_RE = re.compile(r'var\([^)]*\)')
DURATION_RE = re.compile(r'\b\d+(?:\.\d+)?(?:ms|s)\b')
line = 'transition-duration: var(--motion-duration-standard, 200ms);'
print('CHECK A hits:', VAR_MOTION_RE.findall(line))
masked = VAR_MASK_RE.sub(lambda m: 'V'*len(m.group(0)), line)
print('CHECK B hits:', DURATION_RE.findall(masked))
"
CHECK A hits: []
CHECK B hits: []
```
Both checks report clean with a raw, hand-rolled `200ms` literal sitting directly inside the
gated file — a textbook "gate that vacuously passes" of the exact class this phase's own
comments say they went looking for (`// empty`, `os.walk` symlinks, the delay false-positive).
No current committed surface exercises this (wleave's `var()` usages are all bare), but
nothing stops a future author from writing exactly this pattern — CSS fallback syntax is
common and idiomatic.

**Fix:** Either (a) reject a `var()` reference that carries a fallback argument outright
(CHECK B: flag any `var(--motion-*, ...)` with extra content as itself a violation — a
fallback duplicates/contradicts the token, which this repo's own zero-duplicate-value
principle already disallows), or (b) extend `VAR_MOTION_RE` to also capture and validate the
fallback's own raw-value shape against `DURATION_RE`/`CUBIC_BEZIER_RE`/etc. before masking it
out. Example minimal fix (option a):
```python
VAR_MOTION_FALLBACK_RE = re.compile(r'var\(\s*--(motion-[A-Za-z0-9_-]+)\s*,')
# ... in check_css_surface, before masking:
for m in VAR_MOTION_FALLBACK_RE.finditer(line):
    b_hits.append((i, f'var(--{m.group(1)}, ...) — fallback value on a motion token reference is itself a raw-value violation'))
```

### CR-02: stow.sh's pre-existing `set -e`/`pipefail` loop-abort can silently skip the new motion-file seed, contradicting its own "loud, not silent" guarantee

**File:** `stow.sh:81-88` (existing stow loop) interacting with `stow.sh:144-169` (new in this phase)
**Issue:**
`stow.sh` runs under `set -euo pipefail` (line 7). The package loop does:
```bash
for pkg in "${PACKAGES[@]}"; do
    if [[ -d "$pkg" ]]; then
        echo "  → Stowing: $pkg"
        stow --restow "$pkg" --target="$HOME" 2>&1 | sed 's/^/    /'
    else
        echo "  ⚠ Skipping: $pkg (directory not found)"
    fi
done
```
`stow --restow` exits non-zero on any conflict (an existing non-symlink file at the target).
With `pipefail` active, that non-zero status propagates through the `| sed` pipe, and with
`set -e` active that aborts the *entire script* at that point — no `|| true`, no trap, no
continue-on-error. This is pre-existing behavior, not introduced by this phase.

This phase adds a new block *after* that loop (lines 144-169) that seeds the three rendered
motion files (`hyprland-motion.conf`, `gtk-4.0-motion.css`, `motion.json`) by invoking
`theme_engine_render_motion_files` directly, with commentary explicitly stating this is the
most critical seed in the whole file and must fail loudly rather than silently:
> "a missing hyprland-motion.conf is a hard `source=` globbing error... both are config-parse
> failures that keep Hyprland from starting at all... a failure here is loud, not silent"

That guarantee is only honored for failures *inside* the new block (handled via the `|| echo
... >&2` around the subshell). It does not account for the pre-existing risk that the script
never reaches line 144 at all: a stow conflict on **any** earlier package in `PACKAGES`
(`ags`, `elephant`, `fastfetch`, `fish`, `gtk`, `hypr`, `kitty`, `matugen`, `quickshell`,
`swaync`, `swayosd` — eleven packages stow before `theme-engine` is even reached) aborts the
whole script with no warning about the motion-seed step never having run. This is exactly the
scenario `stow.sh` is designed to be run into repeatedly (`WR-05: seed only when absent —
stow.sh is re-runnable`), so a conflict on a re-run is a realistic, not merely theoretical,
trigger — and its effect is the specific "Hyprland will NOT start" failure mode the new code's
own comment calls the worst possible outcome in this file.

**Fix:** Make the stow loop resilient before relying on anything after it:
```bash
for pkg in "${PACKAGES[@]}"; do
    if [[ -d "$pkg" ]]; then
        echo "  → Stowing: $pkg"
        if ! stow --restow "$pkg" --target="$HOME" 2>&1 | sed 's/^/    /'; then
            echo "  ⚠ stow failed for $pkg — continuing with remaining packages" >&2
        fi
    else
        echo "  ⚠ Skipping: $pkg (directory not found)"
    fi
done
```
(`if ! ... | ...; then` short-circuits `set -e`'s abort for that one pipeline.) Alternatively,
move the motion-file seed to run independent of stow's success/failure via a `trap` or an
early, first-class step that does not depend on reaching the bottom of the package loop.

## Warnings

### WR-01: motion-lint's raw-value carve-outs are line-scoped, not property-scoped

**File:** `hypr/.config/hypr/scripts/motion-lint:481, 512` (CSS) and `:604-613` (QML)
**Issue:** The `animation-delay`/`transition-delay` carve-out (`DELAY_PROPERTY_RE`, line 481)
is applied per-line: `if DELAY_PROPERTY_RE.search(line) or line_is_exempt(path, i): continue`
(line 512) skips **all** of CHECK B for that entire line, not just the delay property's own
value. Likewise in `check_qml_surface`, `if 'Motion.' not in line:` (line 608) gates the whole
raw-duration/bezier scan for that line on the mere *presence* of the substring `Motion.`
anywhere in it. Today every real surface writes one CSS property (or one QML property) per
line, so this is not currently exploited, but it means a single line combining a legitimate
`animation-delay:`/`Motion.*` reference with an unrelated raw literal (e.g. a future compacted
rule, or a QML line like `duration: 200 /* fallback while Motion.foo loads */`) would silently
escape detection entirely — the same "carve-out broader than intended" failure shape flagged
as the top priority for this review.
**Fix:** Scope the carve-out to the matched *value*, not the whole line — e.g. strip only the
`animation-delay:`/`transition-delay:` declaration's own value span before masking, and mask
out only the actual `Motion.xxx` token span in QML rather than skipping the whole line's scan.

### WR-02: cross-target inconsistency — the `linear` easing resolves in Hyprland but is unreachable in CSS

**File:** `theme-engine/.config/theme-engine/lib/motion.sh:204-211` (Hyprland writer) vs `:224-231` (GTK4 writer)
**Issue:** The Hyprland writer emits a `bezier = motion-<name>, ...` line for **every** entry
in `motion.json`'s `easings` table unconditionally:
```jq
.easings | to_entries[] | "    bezier = motion-\(.key), \(.value[0]), ..."
```
The GTK4 writer instead only emits a `--motion-easing-<name>` custom property for an easing
that is actually referenced by at least one semantic pair's `.easing` field (first-reference
order, deduplicated). `motion.json`'s `easings` table declares `"linear": [1, 1, 1, 1]`, but
none of the three semantic pairs (`standard`, `emphasized-in`, `emphasized-out`) reference it.

Verified against the live file:
```
$ jq -r '.easings | to_entries[] | "bezier = motion-\(.key)"' motion.json
bezier = motion-standard
bezier = motion-emphasized-decelerate
bezier = motion-emphasized-accelerate
bezier = motion-linear          # <- present for Hyprland
```
but the GTK4 writer's own jq query (run against the same file) produces only three
`--motion-easing-*` properties — `linear` is absent. Any future CSS/QML surface reaching for
`var(--motion-easing-linear)` gets an unconditional motion-lint CHECK-A "dangling reference"
failure, while the semantically identical `motion-linear` bezier is perfectly usable from
Hyprland today. This directly contradicts the one-source-of-truth premise motion.json's own
`_comment` and D-01 assert, and will read as a confusing, hard-to-diagnose gate failure the
first time someone wires "linear" into a stylesheet or QML surface.
**Fix:** Either emit every declared easing unconditionally from both writers (matching
Hyprland's behavior), or drop unreferenced easings from `motion.json` until they have a
consumer — but the two writers must agree on which easings exist.

### WR-03: motion-lint's QML comment stripper does not respect string literals

**File:** `hypr/.config/hypr/scripts/motion-lint:238-245`
**Issue:** `strip_qml_comments` finds the first `//` on each line (after block-comment
stripping) via `line.find('//')` and truncates everything after it, with no awareness of
whether that `//` is inside a string literal (e.g. `"https://example.com"`). A QML line that
places a real `Motion.*` reference or a raw duration/bezier literal *after* a `//`-containing
string on the same line would have that content silently deleted before either CHECK A or
CHECK B ever sees it — another instance of a check that can be defeated into a false PASS. No
committed `.qml` file under `quickshell/` currently triggers this (verified: no `//` occurs
inside a string literal anywhere in that tree today), but it is a structural gap in a
deny-by-default gate that is supposed to make partial-coverage misses visible, not create new
ones.
**Fix:** Track whether the scanner is inside a `"..."` string when looking for `//` (a small
state machine, or a regex that skips quoted spans), mirroring the care already taken for CSS
block comments.

### WR-04: `LINE_EXEMPTIONS`' wleave carve-out is anchored to hardcoded line numbers with no content check

**File:** `hypr/.config/hypr/scripts/motion-lint:369-378, 387-388`
**Issue:** The one `LINE_EXEMPTIONS` entry hardcodes `'start': 230, 'end': 253` against
`wleave/.config/wleave/style.css`. Verified this currently aligns exactly with the intended
`button:hover, button:focus { ... }` block (lines 230-253 in the live file). But nothing ties
this range to the actual rule it's meant to cover — any future edit to `wleave/style.css`
*above* line 230 (a new comment, an inserted rule, even a single blank line) silently shifts
every subsequent line number, so the exemption would then cover the wrong span: either newly
exempting real violations that happen to land in 230-253 after the shift, or ceasing to
protect the actual (now-relocated) hover/focus block and turning it into an unexpected
motion-lint FAIL with no indication of why. The stated design goal ("printed on EVERY run...
so that debt stays visible") only holds if the *scope* stays correct, and there is currently
no assertion that it does.
**Fix:** Anchor the exemption to a content marker instead of (or in addition to) line numbers
— e.g. require the matched span to also contain a recognizable literal such as
`button:hover,` immediately preceding it, and FAIL the exemption entry itself (loud, per this
file's own "empty reason" precedent) if the anchor text isn't found at/near the declared
range.

## Info

### IN-01: Motion.qml doesn't restate Colours.qml's documented malformed-JSON caveat

**File:** `quickshell/.config/quickshell/modules/Motion.qml:1-80`
**Issue:** Colours.qml's header explicitly documents (and accepts) that `FileView`'s
`loadFailed` signal only fires for file-level errors (missing/permission/not-a-file), not for
syntactically invalid JSON content — so a malformed `palette.json` silently leaves stale
values rather than surfacing as an error. The same underlying `FileView`/`JsonAdapter`
mechanism is used identically in `Motion.qml` for `motion.json`, but this same caveat is not
restated there. Not a functional bug (both singletons degrade the same way — stale values,
never a crash — satisfying "must degrade gracefully"), but a future reader of `Motion.qml` in
isolation could reasonably assume malformed JSON is already handled/detected when it isn't.
**Fix:** Add a short cross-reference comment in `Motion.qml` pointing at Colours.qml's
existing writeup, so the limitation isn't only discoverable by reading the sibling file.

---

_Reviewed: 2026-07-26T23:11:16Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
