---
phase: 08-waybar-evolution
reviewed: 2026-07-14T20:20:00Z
depth: standard
files_reviewed: 32
files_reviewed_list:
  - eww/.config/eww/eww.scss
  - eww/.config/eww/eww.yuck
  - hypr/.config/hypr/config/autostart.conf
  - hypr/.config/hypr/config/keybinds.conf
  - hypr/.config/hypr/hypridle.conf
  - hypr/.config/hypr/scripts/gaming-mode-toggle.sh
  - hypr/.config/hypr/scripts/media-art-resolve.sh
  - hypr/.config/hypr/scripts/media-players.sh
  - hypr/.config/hypr/scripts/media-popup-open.sh
  - hypr/.config/hypr/scripts/media-status.sh
  - hypr/.config/hypr/scripts/tests/test-media-hardening.sh
  - hypr/.config/hypr/scripts/waybar-fullscreen-watch.sh
  - hypr/.config/hypr/scripts/waybar-launch.sh
  - hypr/.config/hypr/scripts/waybar-switch.sh
  - hypr/.config/hypr/scripts/waybar-visibility.sh
  - matugen/.config/matugen/config.toml
  - matugen/.config/matugen/templates/eww-colors.scss
  - swaync/.config/swaync/config.json
  - swaync/.config/swaync/style.css
  - theme-engine/.config/theme-engine/contract.json
  - theme-engine/.config/theme-engine/lib/contract.sh
  - theme-engine/.config/theme-engine/lib/reload.sh
  - waybar/.config/waybar/bar-common.jsonc
  - waybar/.config/waybar/config-floating.jsonc
  - waybar/.config/waybar/config-full.jsonc
  - waybar/.config/waybar/config-minimal.jsonc
  - waybar/.config/waybar/config-vertical.jsonc
  - waybar/.config/waybar/modules.jsonc
  - waybar/.config/waybar/style-floating.css
  - waybar/.config/waybar/style-full.css
  - waybar/.config/waybar/style-minimal.css
  - waybar/.config/waybar/style-vertical.css
  - waybar/.config/waybar/waybar-modules.css
findings:
  critical: 1
  warning: 3
  info: 4
  total: 8
status: issues_found
---

# Phase 8: Code Review Report

**Reviewed:** 2026-07-14T20:20:00Z
**Depth:** standard
**Files Reviewed:** 32 (swaync/style.css read for context; binary asset `blank.png` skipped)
**Status:** issues_found

## Summary

Phase 8 delivers the eww media popup, the four-layout waybar `include`/`@import`
refactor, the single-owner waybar-visibility state machine, and a hardened media
pipeline (`media-*.sh`) with a 19-check adversarial gate.

The injection-hardening posture is genuinely strong: I traced every path where
attacker-controlled MPRIS metadata (title/artist/album/artUrl/bus-id) could reach
a shell, `eval`, or a command string, and found none. IDs are `_valid_id`-gated
before any `playerctl` call; metadata is emitted only through `jq --arg`; eww
`onclick` strings interpolate only validated ids and eww's own numeric slider
substitution; the `file://` branch is mime-gated so path traversal degrades to
"display an image the user can already read." That work holds.

The gate is **not** airtight, however. The SSRF guard in `media-art-resolve.sh`
is trivially bypassable via IPv6-bracket and integer-IP encodings — verified live
on this host — and its own `::1` allowlist entry is structurally dead. That is the
one Critical finding (the domain brief pre-declared any gate-missed bypass as
Critical). Secondary concerns: the visibility owner is a lock-free read-modify-write
shared by four concurrent actors using fixed `.tmp` filenames (lost-update / torn
publish), and the new `scss-kv` contract parser repeats a false-pass charset gap
that `WR-05` already fixed for `hypr-vars`.

## Structural Findings (fallow)

No `<structural_findings>` block was provided with this review; no structural
pre-pass substrate to reconcile against.

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: SSRF guard in media-art-resolve.sh bypassable via IPv6-bracket and integer-IP encodings; `::1` allowlist entry is dead code

**File:** `hypr/.config/hypr/scripts/media-art-resolve.sh:118-128`
**Issue:**
The host is extracted with `host="${host_port%%:*}"` (line 120), which cuts at the
FIRST colon. For a bracketed IPv6 literal that yields `[`, not the address, so the
loopback/RFC1918 `case` block never matches. Verified live on this machine:

```
http://[::1]/x.png              -> host="["           => PASSES GUARD (curl fires)
http://[::ffff:127.0.0.1]/x.png -> host="["           => PASSES GUARD
http://2130706433/x.png         -> host="2130706433"  => PASSES GUARD  (== 127.0.0.1)
http://127.0.0.1/x.png          -> host="127.0.0.1"   => BLOCKED
```

Two consequences:
1. The `::1` token in the allowlist (line 122) can never match any real URL —
   `http://::1/` is malformed; browsers/players emit `http://[::1]/`, which extracts
   to `[`. The entry is dead, so IPv6 loopback is reachable.
2. `mpris:artUrl` is attacker-controlled (a downloaded media file sets it). An
   attacker can therefore make the machine issue an arbitrary GET to loopback or
   LAN (`http://[::1]:PORT/path`, `http://2130706433/`, decimal forms of `10.*`/
   `192.168.*`), reaching services the guard was explicitly written to fence off.
   The response only needs to *not* be cached, but the side-effecting request still
   fires. The test gate (`test-media-hardening.sh`) exercises only `127.0.0.1`
   (Check 9), so it reports "airtight" while missing this class entirely.

This is not the "DNS-rebinding residual risk" the header disclaims — it is a
literal-encoding bypass of the enumerated denylist the code intends to enforce.

**Fix:** Normalize the host before matching, and strip IPv6 brackets. Reject
bracketed literals whose inner address is loopback/link-local/RFC1918, and reject
all-numeric single-integer hosts (or resolve+check the numeric form). Minimum:

```bash
# strip a leading '[' ... ']' IPv6 literal, else cut at first ':'
if [[ "$host_port" == \[*\]* ]]; then
    host="${host_port#\[}"; host="${host%%\]*}"
else
    host="${host_port%%:*}"
fi
case "$host" in
    localhost | 127.* | ::1 | ::ffff:127.* | 0.0.0.0 | 169.254.* | 10.* | 192.168.* | \
    fe80:* | fc00:* | fd00:*) exit 3 ;;
    172.1[6-9].* | 172.2[0-9].* | 172.3[01].*) exit 3 ;;
    # all-numeric single-integer host (decimal IP) — reject conservatively
    *[!0-9]* ) : ;;      # has a non-digit: fall through to normal handling
    *) exit 3 ;;         # bare integer host -> refuse
esac
```

Also add `http://[::1]/` and a decimal-IP case to `test-media-hardening.sh` so the
gate can no longer pass while these bypasses exist.

## Warnings

### WR-01: waybar-visibility.sh is a lock-free read-modify-write shared by four concurrent actors, with fixed `.tmp` filenames

**File:** `hypr/.config/hypr/scripts/waybar-visibility.sh:110-131, 199-234`
**Issue:**
The header claims this is the single serializing owner and that "a torn read must
never be possible," but there is no serialization. Four actors invoke it
concurrently (hypridle, the fullscreen socket watcher, gaming-mode, the keybind —
see `autostart.conf`, `hypridle.conf`, `gaming-mode-toggle.sh`, `keybinds.conf`),
and each invocation does an unlocked `_compute` → read `.actuated` → compare →
write CSS + signal + write `.actuated`.

Two distinct defects:
1. **Lost update / TOCTOU:** two invocations both read `.actuated="visible"`,
   both compute different targets, both signal waybar. The `.actuated` write of the
   loser can land last, leaving `.actuated` disagreeing with what was actuated —
   and because `_actuate 0` short-circuits when `last == target`, the bar can be
   left stuck dimmed/hidden until the next unrelated event or `reassert`.
2. **Shared fixed tmp names:** `_write_css`, `_write_override`, and `_write_actuated`
   all write to a single fixed `$FILE.tmp` (`waybar-visibility.css.tmp`,
   `.override.tmp`, `.actuated.tmp`) regardless of caller. Two concurrent writers to
   the same tmp path (each `> tmp` truncating) can publish the wrong content, and
   the CSS-file winner and `.actuated` winner are chosen independently — so the
   rendered CSS and the recorded state can diverge. `_write_intent` is safe only
   because its tmp name is per-source.

The symptom is exactly the desync class this file was built to eliminate (D-03);
it self-heals on the next event, but a fullscreen-exit + idle-timeout landing in
the same instant (called out as "a real possibility" in the header) is precisely
when it bites.

**Fix:** Serialize the whole compute→actuate critical section with an flock (the
same idiom `media-popup-open.sh` already uses), and give each atomic write a
unique tmp name, e.g. `mktemp "$INTENT_DIR/.actuated.XXXXXX"` before `mv`:

```bash
_lock() { exec 8>"$INTENT_DIR/.owner.lock"; flock 8; }
# in main(), before dispatch to any state-changing verb:
_lock
# and in every _write_*: tmp="$(mktemp "${target}.XXXXXX")"; ... && mv "$tmp" "$target"
```

### WR-02: scss-kv contract parser silently drops digit-bearing / uppercase variable names (repeats the WR-05 false-pass class)

**File:** `theme-engine/.config/theme-engine/lib/contract.sh:92, 189`
**Issue:**
The new `scss-kv` name extractor (`^\$\K[a-z_]+(?=:)`) and value extractor
(`s/^\$([a-z_]+):.../`) accept only lowercase letters and underscores. The adjacent
`hypr-vars` branch carries an explicit `WR-05` note that restricting the charset to
exclude digits "is a false-pass generator" — a variable that vanishes from *both*
name and value extraction makes theme-parity pass on a broken render. `scss-kv`
reintroduces exactly that gap: add `$surface2` or `$primaryContainer` to
`eww-colors.scss` and it disappears from parity silently rather than being flagged.
Today's template (`matugen/.config/matugen/templates/eww-colors.scss`) happens to
use only `[a-z_]` names, so it works — this is a latent robustness defect, not a
live failure.

**Fix:** Match the WR-05 fix — allow digits and uppercase after the first char in
both dispatchers:

```bash
# names:  grep -oP '^\$\K[A-Za-z_][A-Za-z0-9_]*(?=:)'
# values: sed -nE 's/^\$([A-Za-z_][A-Za-z0-9_]*):[[:space:]]*([^;]+);.*$/\1\t\2/p'
```

### WR-03: waybar built-in `mpris` tooltip renders unescaped attacker-controlled metadata as Pango markup

**File:** `waybar/.config/waybar/modules.jsonc:63`, `config-full.jsonc:60`, `config-minimal.jsonc:60`, `config-vertical.jsonc:75`
**Issue:**
Phase 8 closed the Pango-markup vector on the eww side (eww `label :text` does not
parse markup — documented in `eww.yuck`), but the same untrusted `{artist}`/
`{title}`/`{album}` fields flow into waybar's built-in `mpris` `tooltip-format`,
which waybar renders through Pango markup. The `escape: true` option only applies
to `custom/*` modules, not the built-in `mpris` module, so a track title containing
`<`, `&`, or a crafted `<span>` can break tooltip rendering or inject markup. This
is lower severity than command injection (tooltip-only, no code execution) and is
partly inherent to waybar's built-in module, but it is the exact class Phase 8
deliberately hardened everywhere else, so the inconsistency should be resolved or
explicitly accepted.

**Fix:** Verify the installed waybar version's mpris tooltip escaping behavior with
a `<b>x</b> & "y"` title fixture. If it does not escape, drop the raw metadata from
`tooltip-format` (e.g. show only `{player}` / `{status}` / `{position} / {length}`),
or document the accepted residual risk alongside the eww note.

## Info

### IN-01: style-floating.css unitless `border-radius` and mixed tabs/spaces

**File:** `waybar/.config/waybar/style-floating.css:15`
**Issue:** `border-radius: 10;` in the `*` reset lacks a unit (the rest of the file
uses `10px`); depending on the GTK CSS parser this may be ignored, yielding no
corner rounding from the reset. The file also mixes tabs and spaces for indentation
(lines 14-15 vs the surrounding spaces). Pre-existing floating styling, surfaced by
the refactor.
**Fix:** `border-radius: 10px;` and normalize indentation to spaces.

### IN-02: duplicate `color` declaration in #temperature.critical

**File:** `waybar/.config/waybar/waybar-modules.css:78-82`
**Issue:** The rule sets `color: @error;`, then `background: @error;`, then
`color: @on_error;`. The first `color` is dead (overridden by the third). Harmless
but confusing.
**Fix:** Remove the first `color: @error;` line; keep `background: @error; color: @on_error;`.

### IN-03: `line` not declared `local` in _effective_id

**File:** `hypr/.config/hypr/scripts/media-players.sh:54-76`
**Issue:** `_effective_id` uses `line` in its `while` loop but only declares
`local ids saved found=""`. `line` leaks to the global scope. No current bug (it is
overwritten wherever else used), but it is an inconsistency — `_valid_ids` and
`cmd_list` correctly localize their loop vars.
**Fix:** Add `line` to the `local` declaration.

### IN-04: unquoted `$HOME` inside command substitution in custom/gaming-mode exec

**File:** `waybar/.config/waybar/modules.jsonc:161`
**Issue:** `"$(cat $HOME/.cache/gaming-mode 2>/dev/null)"` leaves `$HOME` unquoted
inside the substitution; a `$HOME` containing whitespace would word-split the path.
Extremely unlikely in practice, and the comparison correctly fails safe to OFF, but
inconsistent with the quoting discipline elsewhere in the phase.
**Fix:** Quote it: `"$(cat "$HOME/.cache/gaming-mode" 2>/dev/null)"`.

---

_Reviewed: 2026-07-14T20:20:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
