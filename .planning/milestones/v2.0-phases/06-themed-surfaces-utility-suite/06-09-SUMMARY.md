---
phase: 06-themed-surfaces-utility-suite
plan: 09
subsystem: infra
tags: [hyprland, walker, elephant, hyprpicker, wtype, cliphist, wlogout, keybinds]

# Dependency graph
requires:
  - phase: 06-01
    provides: theme-engine contract.json/reload.sh fan-out conventions this plan's scripts read palette state from
  - phase: 06-03
    provides: wlogout layout redesign (Nerd Font glyph `text` fields, JSON-per-line format) this plan edits the action commands of
  - phase: 06-06
    provides: capture-*.sh / record-toggle.sh sanitized-error and walker --dmenu exit-130-cancel conventions this plan reuses verbatim
provides:
  - emoji-picker.sh (wtype + wl-copy, curated glyph list via walker --dmenu)
  - color-picker.sh (hyprpicker hex + wl-copy + swatch notification)
  - clipboard-wipe.sh (manual wipe, default-No destructive confirm)
  - cliphist -max-items 100 cap on both autostart watchers
  - wlogout session-end cliphist wipe on logout/shutdown/reboot
  - Super+Z/Shift+Z/X/Shift+X/Shift+C utility keybind family
affects: [phase-07-menu-cheat-sheet]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "walker --dmenu stdin-list + exit-130-cancel (theme-switch.sh pattern) reused for self-contained curated-list pickers, not live provider queries"
    - "Sanitized subprocess-error -> notify-send (head -c 200 | tr -d control chars) reused for hyprpicker stderr"
    - "ImageMagick-generated solid-color swatch PNG as a notify-send -i icon path, with graceful text-only degrade"

key-files:
  created:
    - hypr/.config/hypr/scripts/emoji-picker.sh
    - hypr/.config/hypr/scripts/color-picker.sh
    - hypr/.config/hypr/scripts/clipboard-wipe.sh
  modified:
    - hypr/.config/hypr/config/autostart.conf
    - wlogout/.config/wlogout/layout
    - hypr/.config/hypr/config/keybinds.conf

key-decisions:
  - "walker --dmenu -s symbols does not query elephant-symbols (dmenu mode is always a stdin-only list, verified against installed walker 2.16.2 source); emoji-picker.sh uses a self-contained curated glyph list through the same proven walker --dmenu pattern instead"
  - "cliphist wipe prepended with ';' not '&&' in wlogout actions so a wipe failure can never block a real shutdown/reboot/logout"
  - "Super+Shift+C added (not in UI-SPEC's 4-chord table) as the reachable manual clipboard-wipe entry, since modifying the existing Super+C flow was explicitly prohibited"

patterns-established:
  - "Self-contained curated-list walker --dmenu pickers (no live elephant provider query) for glyph/text selection utilities"

requirements-completed: [UTIL-01, UTIL-02, UTIL-03]

coverage:
  - id: D1
    description: "Emoji picker: Super+Z opens a walker picker; selection is typed via wtype into the focused app AND copied to clipboard as backup"
    requirement: "UTIL-01"
    verification:
      - kind: unit
        ref: "bash -n + shellcheck + grep 'wtype'/'wl-copy' on emoji-picker.sh (automated plan verify)"
        status: pass
    human_judgment: true
    rationale: "wtype is not installed on this dev machine (install.sh PACMAN_PKGS lists it, deferred per this phase's established pattern) so the live type-into-focused-window behavior cannot be exercised end-to-end in this session; needs a live-session UAT pass."
  - id: D2
    description: "Color picker: Super+X runs hyprpicker, copies the hex to clipboard, and shows a notification with a swatch (degrading to text-only)"
    requirement: "UTIL-02"
    verification:
      - kind: unit
        ref: "bash -n + shellcheck + grep 'hyprpicker'/'wl-copy' on color-picker.sh (automated plan verify); convert swatch-generation smoke-tested standalone"
        status: pass
    human_judgment: true
    rationale: "hyprpicker is not installed on this dev machine (deferred per this phase's established pattern), so the live screen-color-grab flow cannot be exercised end-to-end in this session; needs a live-session UAT pass."
  - id: D3
    description: "Clipboard history capped at ~100 entries, wiped silently on logout/shutdown/reboot, and manually wipeable with a destructive-safe default-No confirm — Super+C flow untouched"
    requirement: "UTIL-03"
    verification:
      - kind: unit
        ref: "grep 'max-items' autostart.conf; grep 'cliphist wipe' wlogout/layout; python3 json.loads per-line; bash -n clipboard-wipe.sh (automated plan verify)"
        status: pass
    human_judgment: true
    rationale: "A full session-end wipe and a live Super+Shift+C confirm-dialog cycle require an actual wlogout/logout event and live walker session to observe end-to-end; static checks (cap flag present, JSON valid, wipe command wired) all pass."

# Metrics
duration: 12min
completed: 2026-07-12
status: complete
---

# Phase 6 Plan 9: Emoji/Color Pickers, Clipboard Policy, Utility Keybinds Summary

**Emoji picker (curated glyph list via walker --dmenu, wtype+wl-copy), hyprpicker-backed color picker with a swatch notification, cliphist 100-entry cap + session-end wipe + manual wipe entry, and the freed Super+X/Z utility chord family**

## Performance

- **Duration:** 12 min
- **Started:** 2026-07-12T20:49:25+03:00
- **Completed:** 2026-07-12T21:00:54+03:00
- **Tasks:** 3
- **Files modified:** 6 (3 new scripts + 3 edited configs)

## Accomplishments
- `emoji-picker.sh`: 160-entry curated glyph+name list piped through walker's generic `--dmenu` (same exit-130-cancel pattern as `theme-switch.sh`); selected glyph is `wtype`'d into the focused app and `wl-copy`'d as backup, with an exact-line validation gate before typing (UTIL-01/D-21)
- `color-picker.sh`: `hyprpicker -a -f hex` grabs a screen color, copies it via `wl-copy`, and fires a notification with an ImageMagick-generated solid-color swatch PNG icon (degrading gracefully to the plain `color-picker` icon name if ImageMagick or the swatch render is unavailable) (UTIL-02/D-22)
- Clipboard security posture shipped as one unit: `autostart.conf`'s two `cliphist store` watchers capped at `-max-items 100`, `wlogout/layout`'s logout/shutdown/reboot actions now run `cliphist wipe` first (silent, session ending), and `clipboard-wipe.sh` provides a manual wipe with a Yes/No walker `--dmenu` confirm defaulting to No (UTIL-03/D-15)
- Utility keybind family wired: Super+Z (emoji), Super+Shift+Z (icon-theme picker, 06-07), Super+X (color), Super+Shift+X (font switcher, 06-08), plus Super+Shift+C (manual clipboard wipe) — Super+C/T/B/W all confirmed untouched (D-32)

## Task Commits

Each task was committed atomically:

1. **Task 1: emoji-picker.sh + color-picker.sh** - `b24f1f3` (feat)
2. **Task 2: Clipboard cap + session-end wipe + manual wipe** - `4f1c3ff` (feat)
3. **Task 3: Utility keybinds on the freed X/Z family** - `2b447c8` (feat)

**Plan metadata:** (this commit)

## Files Created/Modified
- `hypr/.config/hypr/scripts/emoji-picker.sh` - curated glyph picker, wtype + wl-copy
- `hypr/.config/hypr/scripts/color-picker.sh` - hyprpicker hex grab, wl-copy, swatch notification
- `hypr/.config/hypr/scripts/clipboard-wipe.sh` - manual wipe, default-No destructive confirm
- `hypr/.config/hypr/config/autostart.conf` - cliphist `-max-items 100` on both store watchers
- `wlogout/.config/wlogout/layout` - `cliphist wipe;` prepended to logout/shutdown/reboot actions
- `hypr/.config/hypr/config/keybinds.conf` - Super+Z/Shift+Z/X/Shift+X/Shift+C utility binds

## Decisions Made
- **`walker --dmenu -s symbols` does not work as RESEARCH.md's code example assumed.** Source-verified directly against the installed `walker` 2.16.2 (`src/main.rs`) and `elephant-symbols` 2.21.0 (`internal/providers/symbols/setup.go`) sources: `--dmenu` mode always reads its item list from stdin (`read_lines_async`) regardless of any `-s`/`-m` flag — it never queries a live elephant provider. A normal (non-dmenu) `walker -s symbols` run never prints the selection to stdout either (the only stdout-print path, `handle_dmenu_print`, is gated behind `is_dmenu()`); selecting an item instead invokes elephant-symbols' own `Activate()`, which runs a single configured shell command (default `wl-copy`) read once from `~/.config/elephant/symbols.toml` at elephant daemon startup — not reconfigurable per-invocation without an elephant restart mid-session, and writing that config would add un-stowed host-only state (violates this repo's reproducibility constraint). Given this, and given the automated plan verification requires `wtype`/`wl-copy` literally inside `emoji-picker.sh`, the script uses a self-contained curated glyph list through the same proven `walker --dmenu` stdin pattern `theme-switch.sh` already ships, deterministically extracting and validating the glyph before typing.
- `cliphist wipe` is joined with `;` (not `&&`) in the wlogout actions so a wipe failure (e.g. empty history, cliphist not yet installed) can never block a real shutdown/reboot/logout — matches the plan's own suggested fallback and keeps the Phase-4-audited `hyprshutdown --post-cmd` tail intact.
- `Super+Shift+C` was added as the manual clipboard-wipe entry. UI-SPEC's Interaction Contract table only lists 4 chords (Z/Shift+Z/X/Shift+X); modifying the existing `Super+C` cliphist flow to embed a wipe row was explicitly prohibited by the plan (and pinned by its own automated verify: `cliphist list` must remain the literal command). `Super+Shift+C` is unused, mnemonic (C=clipboard), and consistent with this file's existing Shift-modifier-for-destructive-variant convention (`Super+Shift+Q` = wlogout vs `Super+Q` = killactive).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] emoji-picker.sh built on a source-verified-incorrect architecture, not the RESEARCH.md code example**
- **Found during:** Task 1 (emoji-picker.sh)
- **Issue:** RESEARCH.md's code example (`walker --dmenu -s symbols`, and the tree comment's `walker -s <symbols set> | wtype -`) does not function against the installed walker 2.16.2 / elephant-symbols 2.21.0 — confirmed by reading both projects' source directly (extracted from the AUR clone tarballs already present in `~/.cache/paru/clone/`) rather than attempting an untestable live-GUI click-through in this headless exec session.
- **Fix:** emoji-picker.sh uses a self-contained curated 160-entry glyph+name list piped through walker's generic `--dmenu` (the same stdin-list mechanism `theme-switch.sh` already uses and proves), with an exact-line validation gate (T-06-17) before the extracted glyph is passed to `wtype`/`wl-copy`.
- **Files modified:** hypr/.config/hypr/scripts/emoji-picker.sh
- **Verification:** bash -n clean, shellcheck clean, functional smoke test of the tab-parsing/validation logic (160 lines, correct glyph extraction confirmed for a mid-list and the last entry)
- **Committed in:** b24f1f3 (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 Rule 1 - bug in the plan's own assumed reference implementation, corrected via direct upstream source verification)
**Impact on plan:** The fix delivers the exact same user-facing D-21 behavior (walker-driven selection, typed + copied) the plan required; only the internal data source changed (curated list vs. an unqueryable live provider dump). No scope creep — no new files outside the plan's declared `files_modified`, no elephant daemon config/restart, no new stow package.

## Issues Encountered
- `wtype` and `hyprpicker` are not installed on this dev machine (both are already listed in `install.sh`'s `PACMAN_PKGS`, per this phase's established "not installed locally yet, install deferred" pattern set by 06-02/06-05) — neither script's live end-to-end behavior could be exercised in this session; both were written and statically verified against upstream-confirmed CLI flags (`hyprpicker -a -f hex`, `wtype <text>`) and the codebase's existing sanitized-error/notify-send conventions. Flagged as `human_judgment: true` in this SUMMARY's coverage block for a live-session UAT pass.
- `cliphist -max-items` flag placement (before vs. after the `store` subcommand) was ambiguous from `cliphist --help`'s usage synopsis alone; both orderings were smoke-tested directly against the installed `cliphist` binary and both work — the before-subcommand form (`cliphist -max-items 100 store`) was kept to match the exact synopsis order shown in `--help`.

## User Setup Required
None - no external service configuration required. `wtype` and `hyprpicker` will be installed automatically by `install.sh` on the next full provisioning run (already present in `PACMAN_PKGS`); until then, `emoji-picker.sh` degrades to copy-only and `color-picker.sh` will fail with a clear "hyprpicker not installed" notification rather than a silent no-op.

## Next Phase Readiness
- Phase 6's utility suite (screenshots, emoji, color, clipboard, icon-theme, font) is now fully wired end-to-end; this was the last plan (wave 4) and owns the final `keybinds.conf`/`autostart.conf`/`wlogout/layout` edits for the phase.
- Phase 7's keybind cheat-sheet (MENU-07) can source the chord table directly from the in-file comment block added to `keybinds.conf` in this plan.
- Live-session UAT still needed for D1/D2/D3 (wtype typing, hyprpicker hex grab, full session-end wipe cycle) once `wtype`/`hyprpicker` are installed via `install.sh` — flagged, not blocking, since all static/structural verification passed.

---
*Phase: 06-themed-surfaces-utility-suite*
*Completed: 2026-07-12*

## Self-Check: PASSED

All created/modified files found on disk; all 3 task commits (`b24f1f3`, `4f1c3ff`, `2b447c8`) found in git history.
