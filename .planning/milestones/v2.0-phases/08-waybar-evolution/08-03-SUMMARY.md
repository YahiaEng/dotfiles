---
phase: 08-waybar-evolution
plan: 03
subsystem: infra
tags: [waybar, gtk3-css, hyprland-ipc, bash, shellcheck, matugen]

# Dependency graph
requires:
  - phase: 08-waybar-evolution
    provides: "08-01's shared-include composition (modules.jsonc, waybar-modules.css, config-{full,minimal,floating}.jsonc as include-composed layouts) and the waybar-equivalence-check D-34 gate"
provides:
  - "OLED luminance trim (D-06): translucent window#waybar, thinned/dimmed border, outline-style active workspace pill — every color still a palette token"
  - "hypr/.config/hypr/scripts/waybar-visibility.sh — the single owner of waybar visibility, CLI-driven, per-source intent files, OR-union computation, auto-clearing keybind override, trigger-dependent actuation"
  - "waybar/.config/waybar/bar-common.jsonc — shared on-sigusr1:hide / on-sigusr2:reload, included by all three layouts"
  - "theme-engine/lib/reload.sh integration — reassert call closes the theme-switch/visibility desync"
  - "A fixed bug in waybar-equivalence-check's effective-config definition (bar-level scalar keys pulled purely via include were previously invisible to the gate)"
affects: [08-04, 08-05, 08-09]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Visibility-owner intent model: N actors declare an intent via a small CLI verb; one script owns the state file(s) and the actual signal/actuation decision — same shape as gaming-mode-toggle.sh, generalized to multiple sources with an OR-union and a staleness-checked override layer"
    - "CSS-dim-vs-true-unmap split for exclusive-zone-dependent hide: a mapped, opacity-only CSS override keeps the layer-shell exclusive zone; an actual on-sigusr1 signal (fixed action, never toggle) drops it — verified live via hyprctl clients, not assumed from documentation"

key-files:
  created:
    - hypr/.config/hypr/scripts/waybar-visibility.sh
    - waybar/.config/waybar/bar-common.jsonc
  modified:
    - waybar/.config/waybar/style-full.css
    - waybar/.config/waybar/style-minimal.css
    - waybar/.config/waybar/style-floating.css
    - waybar/.config/waybar/waybar-modules.css
    - waybar/.config/waybar/config-full.jsonc
    - waybar/.config/waybar/config-minimal.jsonc
    - waybar/.config/waybar/config-floating.jsonc
    - theme-engine/.config/theme-engine/lib/reload.sh
    - hypr/.config/hypr/scripts/waybar-equivalence-check
    - stow.sh
    - .planning/phases/08-waybar-evolution/.waybar-config-baseline/{full,minimal,floating}.json

key-decisions:
  - "UI-SPEC's literal `window#waybar.idle-dimmed { opacity: 0.05; }` selector cannot work (nothing ever adds that class to waybar's own window) — implemented as documented deviation: the imported waybar-visibility.css file's mere PRESENCE of an unqualified `window#waybar { opacity: ...; }` rule IS the dim state; an empty file is the visible state"
  - "A two-element waybar include array (`[\"modules.jsonc\", \"bar-common.jsonc\"]`) resolves cleanly on the installed waybar 0.15.0 binary — verified empirically with a scratch waybar launch + debug log before relying on it, per 08-01's own established discipline"
  - "Fixed a real gap in waybar-equivalence-check (Rule 1): bar-level scalar/array keys introduced purely via a new shared include (e.g. bar-common.jsonc's on-sigusr1/on-sigusr2) were previously excluded from the gate's 'effective config' definition entirely, since they were neither in a layout's own directly-defined keys nor referenced by a modules-*/array. Module *definitions* (dict-valued) keep the original unused-is-inert exemption; only non-dict bar-level keys are now always counted"
  - "An active keybind override is always treated as a 'hard' hide category (never idle-dim) when it results in a hidden state, including the unlisted case of a bare manual hide with no other source demanding hide — a defensible, conservative reading not covered by the plan's explicit truth table but consistent with 'an explicit user action should reclaim the pixels, not merely dim them'"
  - "Applied the D-07 zero-risk CSS-transition bonus (`transition: opacity 0.3s ease;` on window#waybar in all three layouts) after live-verifying it genuinely animates the idle-dim path (rapid grim captures during a real idle-hide showed a gradual ~300ms crossfade, not an instant snap)"

patterns-established:
  - "waybar-visibility.sh joins gaming-mode-toggle.sh as this repo's second 'single owner + per-actor intent CLI + atomic state file' script — the shape 08-04 will extend by wiring idle/fullscreen/gaming actors into this exact entrypoint"

requirements-completed: []  # BAR-01 is NOT marked complete here — this plan delivers the pure waybar-side halves (D-06 trim, D-03/D-04 visibility owner + signal config); 08-04 wires the four actors (idle listener, fullscreen watcher, gaming-mode re-point, keybind) into this owner. BAR-01 completes when 08-04 lands.

coverage:
  - id: D1
    description: "OLED luminance trim (D-06): window#waybar background/border trimmed to translucent/dimmed palette tokens in all three layouts; #workspaces button.active is an outline, not a filled pill; zero hex/black literals anywhere"
    verification:
      - kind: manual_procedural
        ref: "grep sweep for hex/black literals (one documented pre-existing #backlight ID-selector false positive, zero real violations) + theme-doctor CSS-parse PASS on all 3 stylesheets + theme-parity 1630/1630 PASS"
        status: pass
    human_judgment: false
  - id: D2
    description: "waybar-visibility.sh is the sole visibility owner: CLI contract (idle/fullscreen/gaming/keybind/reassert/status), OR-union base state, auto-clearing override, source allowlist rejecting path traversal"
    verification:
      - kind: manual_procedural
        ref: "bash -n + shellcheck -S error clean; full 10-row state-machine truth table driven directly via the CLI and matched exactly; traversal test (`../../evil hide`) exits nonzero with zero files written outside ~/.cache/waybar-visibility.d/"
        status: pass
    human_judgment: false
  - id: D3
    description: "D-04 trigger-dependent exclusive zone: idle-hide keeps the zone (CSS-dim, mapped), fullscreen/gaming-hide drops it (true unmap via fixed on-sigusr1) — verified LIVE against the real running waybar, not assumed"
    verification:
      - kind: manual_procedural
        ref: "hyprctl clients -j before/after each hide path against a real tiled window: fullscreen-hide reflowed the window ([13,50]->[13,13], size grew), idle-hide left it byte-identical while the CSS opacity rule was present"
        status: pass
    human_judgment: false
  - id: D4
    description: "Theme-switch/visibility desync closed: reload.sh's on-sigusr2 (reload, which resets visibility) is followed by a best-effort waybar-visibility.sh reassert"
    verification:
      - kind: manual_procedural
        ref: "Live test: hid the bar (fullscreen hide), ran a real theme-apply catppuccin, confirmed status stayed hidden-hard and the tiled window stayed reflowed afterward"
        status: pass
    human_judgment: false
  - id: D5
    description: "bar-common.jsonc's on-sigusr1:hide / on-sigusr2:reload apply to all three layouts via a verified-working two-element include array; the equivalence gate was re-baselined deliberately after reviewing an exact 2-key-per-layout diff"
    verification:
      - kind: manual_procedural
        ref: "waybar-equivalence-check --resolve diff against pre-existing baseline showed ONLY +on-sigusr1/+on-sigusr2 per layout (after fixing the gate's own blind spot to a bar-level-key-via-include class); re-snapshotted; gate green again"
        status: pass
    human_judgment: false
  - id: D6
    description: "bar-common.jsonc is not mistaken for a selectable layout by the D-32 dynamic enumerators"
    verification:
      - kind: manual_procedural
        ref: "bash glob config-*.jsonc over waybar/.config/waybar returns exactly {config-floating,config-full,config-minimal}.jsonc — bar-common.jsonc (no config- prefix) is excluded"
        status: pass
    human_judgment: false

# Metrics
duration: ~23min
completed: 2026-07-14
status: complete
---

# Phase 8 Plan 3: Waybar OLED Trim + Single Visibility Owner Summary

**Translucent/low-luminance bar styling (D-06) plus a single visibility-owner script (`waybar-visibility.sh`) that replaces the desync-prone shared-SIGUSR1-toggle pattern with fixed signal actions, per-source intent files, and a live-verified CSS-dim-vs-true-unmap split for the exclusive zone (D-03/D-04).**

## Performance

- **Duration:** ~23 min
- **Started:** 2026-07-14T13:45:00Z (approx, first file read)
- **Completed:** 2026-07-14T14:08:11Z (last commit)
- **Tasks:** 2 completed (plus one zero-risk D-07 bonus follow-up commit)
- **Files modified:** 13 (2 created, 11 modified)

## Accomplishments

- Applied the D-06 OLED luminance trim to all three existing layouts: `window#waybar` background `@background` (opaque) → `alpha(@background, 0.90)`; border-bottom `3px solid @primary` → `1px solid alpha(@primary, 0.4)`; the shared `#workspaces button.active` rule changed from a filled `@primary` pill to a transparent/outlined treatment. Floating's `window#waybar` previously had no background/border of its own at all (fully transparent) — brought into the same trimmed treatment per the plan's own "all three stylesheets" acceptance criteria. Zero hex/black literals introduced; every value is still a palette token, confirmed by grep sweep, `theme-doctor`, and `theme-parity` (1630/1630 PASS).
- Added the owner-exclusive `~/.local/state/theme/waybar-visibility.css` seam: imported LAST by every `style-*.css` (after `waybar-modules.css`), seeded empty by `stow.sh` (seed-only-when-absent) and self-healingly created by `waybar-visibility.sh` on first run — the file must always exist or GTK3 discards the whole stylesheet.
- Built `hypr/.config/hypr/scripts/waybar-visibility.sh`, the sole owner of waybar visibility. CLI: `<idle|fullscreen|gaming> <hide|show>`, `keybind toggle`, `reassert`, `status`. Implements D-01's OR-union ("hides on either trigger, returns only when both clear"), D-02's auto-clearing keybind override, and D-04's trigger-dependent actuation (CSS-dim for idle-only hides, true unmap via a fixed `on-sigusr1: hide` signal for fullscreen/gaming). `<source>` validated against a strict allowlist before ever touching a filesystem path (T-08-05). Zero user-facing toast calls — silent infrastructure per the UI-SPEC Copywriting Contract.
- Created `waybar/.config/waybar/bar-common.jsonc` (on-sigusr1: hide, on-sigusr2: reload) and included it from all three layout configs. Empirically verified — BEFORE relying on it — that a two-element `include` array resolves cleanly on the installed waybar 0.15.0 binary (scratch waybar launch with `--log-level debug`, both include files logged as found, module + signal config both took effect, zero errors).
- **Verified the exclusive-zone split LIVE against the real running desktop bar**, not from documentation alone (RESEARCH Open Question 1, closed): with a real tiled window open, `fullscreen hide` reflowed it (`hyprctl clients -j`: `at` moved `[13,50]`→`[13,13]`, `size` grew to reclaim the bar's space — zone dropped) while `idle hide` left the window's `at`/`size` completely unchanged (zone kept) with the CSS opacity rule present in `waybar-visibility.css`.
- Drove the full 10-row state-machine truth table directly via the CLI (fresh→visible, idle hide/show, fullscreen hide dominating idle, fullscreen show, keybind-toggle overriding a persistent fullscreen-hide, override auto-clearing when the base changes, gaming hide) — every row matched exactly.
- Integrated with `theme-engine/lib/reload.sh`: corrected its header comment to scope its ownership claim to the theme-reload fan-out (not an exclusive claim over every future waybar signal — `gaming-mode-toggle.sh` has sent `SIGUSR1` since Phase 7), and added a best-effort `waybar-visibility.sh reassert` call immediately after its own `SIGUSR2` waybar signal, inside the existing headless guard. **Verified live**: hid the bar (`fullscreen hide`), ran a real `theme-apply catppuccin`, confirmed the bar stayed hidden and the tiled window stayed reflowed afterward — the theme-switch/visibility desync this integration exists to close never occurred.
- Re-baselined `waybar-equivalence-check` deliberately, not blindly: ran it after adding `bar-common.jsonc`'s include, confirmed the diff was reviewable, fixed a real gap the review surfaced (see Deviations), confirmed the corrected diff was EXACTLY the two new signal keys per layout and nothing else, then re-snapshotted.
- Applied the D-07 zero-risk animation bonus after actually testing it live: added `transition: opacity 0.3s ease;` to `window#waybar` in all three layouts, then captured a rapid sequence of screenshots during a real idle-hide and measured the average pixel value over the bar's screen region — it crossfaded gradually across roughly 300ms (91.5,114.7,131.7 → 98.8,134.2,156.2 → 103.0,148.9,175.3 → 105.3,148.9,176.2 → settled) rather than snapping instantly on the first frame. The true-hide path (fullscreen/gaming) remains instant per RESEARCH Verdict 1 — no bespoke animation harness was built.
- Confirmed `bar-common.jsonc` is not mistaken for a selectable layout: the D-32 dynamic glob (`config-*.jsonc`) over `waybar/.config/waybar` returns exactly `{config-floating, config-full, config-minimal}.jsonc` — the switcher still offers exactly three layouts.

## Task Commits

1. **Task 1: OLED luminance trim (D-06) and the idle-dim CSS seam** - `b2423b4` (feat)
2. **Task 2: The visibility owner — waybar-visibility.sh, the fixed signal actions, and the reload-fanout integration** - `8b7333c` (feat)
3. **D-07 zero-risk bonus follow-up (CSS transition, live-verified)** - `d4a3ed1` (feat)

## Files Created/Modified

- `hypr/.config/hypr/scripts/waybar-visibility.sh` - New. Sole owner of waybar visibility (D-03).
- `waybar/.config/waybar/bar-common.jsonc` - New. Shared `on-sigusr1: hide` / `on-sigusr2: reload`.
- `waybar/.config/waybar/style-{full,minimal,floating}.css` - OLED trim (D-06), the owner-exclusive CSS import, and the D-07 transition bonus.
- `waybar/.config/waybar/waybar-modules.css` - `#workspaces button.active` trimmed from filled pill to outline.
- `waybar/.config/waybar/config-{full,minimal,floating}.jsonc` - `bar-common.jsonc` added to each `include` array.
- `theme-engine/.config/theme-engine/lib/reload.sh` - Ownership-scoping comment fix + `waybar-visibility.sh reassert` call after its own waybar `SIGUSR2`.
- `hypr/.config/hypr/scripts/waybar-equivalence-check` - Fixed the effective-config gap for bar-level keys pulled purely via include (see Deviations).
- `stow.sh` - Seeds `~/.local/state/theme/waybar-visibility.css` empty, seed-only-when-absent.
- `.planning/phases/08-waybar-evolution/.waybar-config-baseline/{full,minimal,floating}.json` - Re-snapshotted after a reviewed, intentional 2-key-per-layout diff.
- `.planning/phases/08-waybar-evolution/deferred-items.md` - Two pre-existing, out-of-scope issues logged (see Issues Encountered).

## Decisions Made

- The UI-SPEC's literal `window#waybar.idle-dimmed { opacity: 0.05; }` selector cannot work as written — nothing in this design ever adds an `.idle-dimmed` class to waybar's own window. Implemented per the plan's own flagged deviation: the imported `waybar-visibility.css` file's mere presence-or-absence of an unqualified `window#waybar { opacity: ...; }` rule IS the state (dimmed = rule present, visible = file empty). The owner script rewrites the whole file on every state change.
- A two-element waybar `include` array resolves correctly on the installed 0.15.0 binary — verified with a scratch launch before relying on it, so `bar-common.jsonc` could be added as a second include entry rather than folded into `modules.jsonc` or duplicated per-layout.
- An active keybind override always maps to the "hard" hide category (true unmap) rather than idle-dim, including a bare manual hide with no other source demanding hide (not covered by the plan's explicit truth table) — a defensible, conservative reading: an explicit user action should reclaim the pixels, not merely dim them.
- Applied the D-07 CSS-transition bonus only after confirming — via live pixel measurement, not assumption — that it genuinely animates the idle-dim path.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed a gap in `waybar-equivalence-check`'s "effective config" definition**
- **Found during:** Task 2, immediately after adding `bar-common.jsonc` to all three `include` arrays and running the gate per the plan's own instruction ("confirm the printed diff contains ONLY the two new bar-level keys")
- **Issue:** The gate's existing definition of "effective config" was `(keys the layout defines directly) union (shared keys referenced by modules-left/-center/-right)`. `on-sigusr1`/`on-sigusr2` are bar-level keys that no layout defines directly (they come solely from the new `bar-common.jsonc` include) and are not module names referenced by any `modules-*` array — so they were silently excluded from "effective config" entirely. Running the gate produced a clean `PASS: 3 FAIL: 0` with ZERO diff, even though the resolved config had genuinely changed — the gate was blind to this exact class of change, defeating its own stated purpose as "a live drift detector for the rest of the phase."
- **Fix:** The "unused shared module definition is inert JSON" exemption is correct only for module *definitions*, which are always JSON objects in this repo's schema (`"clock": {...}`, `"custom/notification": {...}`). It is not correct for bar-level scalar/array keys, which always affect the running bar regardless of whether any array "uses" them by name (there's no name to use — they're not modules). Changed the filter to also always include any resolved key whose value is not a dict, closing the gap without a hardcoded list of `waybar(5)`'s bar-level key names (staying within D-31's "no preprocessor" constraint).
- **Files modified:** `hypr/.config/hypr/scripts/waybar-equivalence-check`
- **Verification:** Confirmed the fix produces exactly the expected `+on-sigusr1`/`+on-sigusr2` per layout (nothing else) by diffing `--resolve` output against the pre-existing baseline; re-ran the full gate to confirm it now correctly reports `FAIL: 3` before re-snapshotting, then `PASS: 3` after. `bash -n` + `shellcheck -S error` + a Python `ast.parse` of the embedded heredoc all clean.
- **Committed in:** `8b7333c` (Task 2 commit)

### Known, Accepted False Positives (not fixed — pre-existing, documented)

**`#backlight` ID selector matches the acceptance criteria's hex-literal grep pattern.** The literal check `grep -E '#[0-9a-fA-F]{3,8}'` matches `#backlight` because its first three characters after `#` (`b`, `a`, `c`) all happen to be valid hex digits — the exact class of false positive the plan's own acceptance criteria calls out by name for `#clock` ("the `#` in selectors like `#clock` is an ID selector, not a colour"). `#backlight` is a pre-existing selector in `style-floating.css`, untouched by this plan's edits. Confirmed via a targeted regex sweep that this is the ONLY match across all four stylesheets, and confirmed no genuine hex/black literal exists anywhere (every color value added or modified by this plan is a palette token, optionally wrapped in `alpha()`).

---

**Total deviations:** 1 auto-fixed (Rule 1 bug in a supporting gate script), 1 documented pre-existing false positive (not fixed, out of scope).
**Impact on plan:** The gate fix was necessary — without it, `waybar-equivalence-check` would have silently lost its ability to detect any future accidental change to bar-level signal keys, undermining the exact "live drift detector" purpose the plan's own Task 2 action explicitly assigns it. No scope creep: the fix is scoped to the class of bug actually encountered.

## Issues Encountered

- **`./stow.sh` aborts early on a pre-existing, unrelated `vscodium` conflict** (`~/.config/VSCodium/User/settings.json` is a real file on this host, not a stow symlink), before the script reaches the new `waybar-visibility.css` seed line added to its cache-init section. This is the same class of issue `08-01-SUMMARY.md` already documented for a different package. **Not caused by this plan, not fixed** (out of scope — fixing vscodium's settings.json ownership is unrelated to waybar). Verified the seed logic correctly instead by running the exact snippet in isolation against the real `$HOME`: confirmed it creates the file when absent, and confirmed a second run with a non-empty dim rule already present leaves the content untouched (seed-only-when-absent). Logged to `deferred-items.md`.
- `theme-doctor`'s git-clean check fails due to pre-existing dirty files unrelated to this plan (`wallpapers/Pictures/Wallpapers/current.jpg`, `.planning/phases/07-super-key-menu/07-VERIFICATION.md`, `csv`) — already logged in `deferred-items.md` by 08-06; all 40+ other `theme-doctor` checks pass, including the three waybar CSS-parse checks this plan's own changes touch.

## User Setup Required

None - no external service configuration required. `waybar-visibility.sh` is already executable and runnable standalone; 08-04 wires the four actors (hypridle listener, fullscreen watcher, gaming-mode re-point, keybind) into it.

## Next Phase Readiness

- `waybar-visibility.sh` is fully functional standalone (idle/fullscreen/gaming/keybind/reassert/status all verified live) — 08-04 only needs to add callers, not build any new visibility logic.
- The D-03/D-04 substrate is proven correct against the real compositor, not just unit-tested in isolation — 08-04 can wire hypridle's `on-timeout`/`on-resume` and a fullscreen-event listener directly to `waybar-visibility.sh idle hide`/`show` and `waybar-visibility.sh fullscreen hide`/`show` with confidence the exclusive-zone behavior is correct.
- BAR-01 remains correctly unchecked in REQUIREMENTS.md — this plan delivers the pure waybar-side halves; it completes when 08-04 lands the four actor integrations.
- `waybar-equivalence-check`'s effective-config gap fix benefits every subsequent plan in this phase that touches bar-level config (08-05's vertical layout, etc.) — the gate now correctly tracks bar-level keys, not just module definitions.

---
*Phase: 08-waybar-evolution*
*Completed: 2026-07-14*

## Self-Check: PASSED

All 16 claimed files verified present on disk; all 3 commit hashes (`b2423b4`, `8b7333c`, `d4a3ed1`) verified present in `git log --oneline --all`.
