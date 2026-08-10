---
phase: 12-unified-design-token-pipeline
fixed_at: 2026-07-26T23:28:35Z
review_path: .planning/phases/12-unified-design-token-pipeline/12-REVIEW.md
iteration: 1
findings_in_scope: 6
fixed: 6
skipped: 0
status: all_fixed
---

# Phase 12: Code Review Fix Report

**Fixed at:** 2026-07-26T23:28:35Z
**Source review:** .planning/phases/12-unified-design-token-pipeline/12-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 6 (Critical + Warning; IN-01 out of scope per `fix_scope: critical_warning`)
- Fixed: 6
- Skipped: 0

## Fixed Issues

### CR-01: motion-lint vacuously passes a raw duration hidden inside a CSS `var()` fallback

**Files modified:** `hypr/.config/hypr/scripts/motion-lint`, `hypr/.config/hypr/scripts/tests/motion-fixtures/poisoned-fallback-gtk4.css` (new)
**Commit:** `a0a45fa`
**Applied fix:** `VAR_MOTION_RE` now matches both the bare `var(--motion-foo)` and fallback `var(--motion-foo, ...)` forms (was anchored on `)` only, so a fallback's leading `,` made the reference invisible to CHECK A). Added `VAR_MOTION_FALLBACK_RE` to flag any `var(--motion-*, ...)` fallback as its own CHECK B raw-value violation (a fallback duplicates/contradicts the token). Rewrote `VAR_MASK_RE` to handle one level of nested parens (`cubic-bezier(...)` inside a fallback), so it finds the true outer closing paren instead of stopping at the bezier's own `)`. Added a tenth self-test fixture (`poisoned-fallback-gtk4.css`) locking the bypass shut permanently, and updated the two "nine committed fixtures" doc comments to "ten".
**Verified:** Reproduced against the orchestrator-provided `fallback.css`/`control.css` pair before and after — `fallback.css` now correctly FAILs both CHECK A (dangling `--motion-easing-totally-made-up`) and CHECK B (two fallback-raw-value hits), while `control.css` keeps failing exactly as before. `--self-test` now 10/0 (was 9/0 — an expected increase, not a regression). Real-tree run stays 37/0.

### CR-02: stow.sh's pre-existing `set -e`/`pipefail` loop-abort can silently skip the new motion-file seed

**Files modified:** `stow.sh`
**Commit:** `f5404b0`
**Applied fix:** Wrapped the per-package `stow --restow ... | sed ...` pipeline in `if ! ...; then echo "⚠ stow failed for $pkg — continuing" >&2; fi`, per the review's suggested minimal fix. This short-circuits `set -e`'s script-wide abort for a single package's conflict so the loop always reaches the motion-file seed step after it (the seed this file's own comments call "the most critical... must fail loudly, not silently").
**Verified:** `bash -n stow.sh` passes. Confirmed the `if ! cmd | pipe; then` pattern actually prevents `set -euo pipefail` abort (isolated repro script: a failing mid-loop pipeline is caught and the loop reaches its end) rather than assuming the pattern works from inspection alone.

### WR-01: motion-lint's raw-value carve-outs are line-scoped, not property-scoped

**Files modified:** `hypr/.config/hypr/scripts/motion-lint`
**Commit:** `19f0a2c`
**Applied fix:** CSS: added `DELAY_DECL_RE` (matches the `animation-delay:`/`transition-delay:` declaration through its own `;` or end-of-line) and blank out only that span before the raw-value scan, instead of `continue`-skipping the whole line's CHECK B on a mere `DELAY_PROPERTY_RE.search` hit. QML: replaced the `if 'Motion.' not in line:` whole-line gate with masking only the matched `Motion.xxx` token span(s) via `MOTION_PROP_RE.sub(...)` before running `QML_DURATION_RE`/`QML_LITERAL_BEZIER_RE` against the remainder — so a future line combining a legitimate carve-out/reference with an unrelated raw literal can no longer escape detection entirely.
**Verified:** Confirmed no committed real QML surface contains a `Motion.*` reference sharing a line with a `duration:`/`easing.bezierCurve: [` pattern (grep), so no new false positive was introduced. `--self-test` 10/0, real-tree 37/0.

### WR-02: cross-target inconsistency — the `linear` easing resolves in Hyprland but is unreachable in CSS

**Files modified:** `theme-engine/.config/theme-engine/lib/motion.sh`
**Commit:** `bde432d`
**Applied fix:** Chose option "emit every declared easing unconditionally from both writers" (rather than removing `linear` from `motion.json`, which would be a data/scope change). Rewrote the GTK4 writer's jq query from "only easings referenced by a semantic pair, first-reference order" to `.easings | to_entries[] | ...`, mirroring the Hyprland writer's own unconditional iteration exactly (same declaration-order semantics — the three previously-referenced easings keep their existing order, `linear` is now appended).
**Verified:** Sourced the modified `motion.sh` and called `theme_engine_render_motion_files` against a throwaway tmp dir — `gtk-4.0-motion.css` now emits `--motion-easing-linear: cubic-bezier(1, 1, 1, 1);` matching Hyprland's `bezier = motion-linear, 1, 1, 1, 1`. No test/gate anywhere hardcodes an easing count (grepped `theme-doctor`/`theme-parity`/`theme-stress-test`/`contract.json`/`contract.sh`). Full regression run: `theme-parity` 1985/0, `theme-doctor` 180/0 (verified with the recovery sentinel temporarily moved aside, since its presence during this session is itself an expected, transient `git status`-dirtying artifact — see Notes below), `quickshell-doctor` 13/0, real-tree motion-lint 37/0.

### WR-03: motion-lint's QML comment stripper does not respect string literals

**Files modified:** `hypr/.config/hypr/scripts/motion-lint`
**Commit:** `924d9d9`
**Applied fix:** Replaced `line.find('//')` with a char-by-char scanner tracking open-quote state (`"`/`'`, with backslash-escape awareness) so a `//` inside an open string literal (e.g. `"https://example.com"`) is never mistaken for a comment start; only a `//` outside any string span cuts the line.
**Verified:** Isolated Python repro against three cases — a URL-bearing line with trailing real code (`duration: 200` correctly preserved, not eaten), a line with a genuine trailing `//` comment after the string closes (correctly stripped), and an escaped-quote case (`'it\'s a //test'`, correctly kept the code after the string). `--self-test` 10/0, real-tree 37/0.

### WR-04: `LINE_EXEMPTIONS`' wleave carve-out is anchored to hardcoded line numbers with no content check

**Files modified:** `hypr/.config/hypr/scripts/motion-lint`
**Commit:** `ab48250`
**Applied fix:** Replaced the static `'start': 230, 'end': 253` with content anchors (`anchor_start` matching `button:hover,`, `anchor_focus` matching `button:focus {` within the next few lines, `anchor_end` matching the next bare `}`), resolved per-run against whichever file in the current scan actually matches the exemption's path regex. Added a new resolution pass (after surface collection, since it needs file content) that: (a) emits `EXEMPT INFO` with the actual resolved range when the anchor is found, (b) emits `EXEMPT INFO` with an explicit "no matching file in this run" note when no file matches (preserves the existing "debt visible even when not currently applicable" behavior), or (c) emits `EXEMPT FAIL` loud when a matching file exists but the anchor content can't be found (the rule moved/was renamed/was removed). `line_is_exempt` now checks the resolved (possibly `None`) range instead of static ints.
**Verified:** Against the real `wleave/style.css`, the anchor resolves to the exact same `lines 230-253` the hardcoded value previously claimed. Three targeted repro scenarios confirmed the new behavior end-to-end: (1) no matching wleave file present → `EXEMPT INFO ... (no matching file in this run's surface set; anchor not verified this run)`, not a FAIL; (2) a matching file present but missing the anchor content → `EXEMPT FAIL ... content anchor not found`; (3) a copy of the real file with 10 blank lines inserted above the rule → the exemption correctly re-resolved to `lines 240-263`, proving it tracks content rather than staying stuck on stale numbers. `--self-test` 10/0, real-tree 37/0.

## Regression Bar (final, cumulative — all 6 fixes combined)

Verified by temporarily overlaying every fixed file from the isolated worktree onto the live deployed paths (the fixer's own commits live on `gsd-reviewfix/12-*` inside the worktree; this overlay was purely for gate verification and was reverted after each check, confirmed via `git status --short`):

- `motion-lint --self-test`: **10 passed, 0 failed** (baseline 9/0 — the +1 is the new CR-01 fixture, an intentional, expected increase per the orchestrator's own instructions)
- `motion-lint` (real deployed tree): **37 passed, 0 failed** (unchanged from baseline)
- `theme-doctor`: **180 passed, 0 failed** (unchanged from baseline; during the session itself it reads 179/1 because this fixer's own recovery sentinel file, `.review-fix-recovery-pending.json`, makes `git status --porcelain` non-empty — confirmed this is solely a session artifact by temporarily moving the sentinel aside and re-running, which restored 180/0; the sentinel is removed by the cleanup tail before this run ends)
- `theme-parity`: **1985 passed, 0 failed** (unchanged from baseline)
- `quickshell-doctor`: **13 passed, 0 failed, exit 0** (unchanged from baseline)
- `bash -n stow.sh`: clean

## Skipped Issues

None — all 6 in-scope findings were fixed and verified.

## Notes

- IN-01 (Motion.qml doesn't restate Colours.qml's malformed-JSON caveat) is Info-severity and was correctly left untouched per `fix_scope: critical_warning`.
- All work was performed inside an isolated git worktree (`gsd-reviewfix/12-*` branch) per the fixer's isolation protocol; the main working tree was kept clean throughout except for the fixer's own recovery sentinel (removed by the cleanup tail).
- No runtime state on the live desktop was left mutated: all temporary overlays onto the real deployed script/library paths used for gate verification were reverted immediately after each check (confirmed via `git status --short` after every overlay/restore cycle). The motion axis was not touched and remains at whatever value it was before this session.

---

_Fixed: 2026-07-26T23:28:35Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
