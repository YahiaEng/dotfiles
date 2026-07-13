---
phase: 06-themed-surfaces-utility-suite
plan: 14
subsystem: utility-scripts
tags: [hyprland, hyprshot, satty, keybinds, screenshot, getopt, xkb]

# Dependency graph
requires:
  - phase: 06-themed-surfaces-utility-suite
    provides: capture-region.sh/capture-full.sh/capture-window.sh (06-05), keybinds.conf Print-family binds (06-05)
provides:
  - Print-family Hyprland binds matched by physical keycode (code:107), bypassing XKB keysym translation
  - hyprshot invocations using the working --raw long-form flag instead of the broken -r short flag
affects: [06-15, screenshot-suite, hyprland-keybinds]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Hyprland binds on ambiguous/modifier-shifted physical keys (Print/PrtSc) should match by code:<keycode> rather than keysym, to bypass XKB level-shift translation entirely"
    - "When a CLI tool's getopt optstring mismatches its actual flag semantics (boolean vs argument-required), prefer the long-form flag — util-linux getopt silently drops malformed short options rather than erroring loudly"

key-files:
  created: []
  modified:
    - hypr/.config/hypr/config/keybinds.conf
    - hypr/.config/hypr/scripts/capture-region.sh
    - hypr/.config/hypr/scripts/capture-full.sh
    - hypr/.config/hypr/scripts/capture-window.sh

key-decisions:
  - "Print-family binds rebound to code:107 rather than keeping the Print keysym — root cause is structural (ALT+Print keysym is Sys_Req on the us XKB keymap, not Print), not a config typo, so keysym-level fixes were never viable"
  - "hyprshot's --raw long form used everywhere instead of -r — hyprshot 1.3.0's getopt optstring declares -r as argument-required while the handler treats it as boolean, so only the long form parses"

patterns-established:
  - "Bind ambiguous/modifier-shifted physical keys by code:<keycode>, not keysym, when any modifier combination could shift the keysym to a different symbol on the active XKB keymap"

requirements-completed: [SHOT-01, SHOT-02, SHOT-03]

coverage:
  - id: D1
    description: "Print-family binds (Print, Shift+Print, Ctrl+Print, Alt+Print) match physical keycode 107 instead of the Print keysym, deterministically fixing the ALT+Print case"
    requirement: "SHOT-01"
    verification:
      - kind: automated_ui
        ref: "grep -cE 'code:107, exec,' hypr/.config/hypr/config/keybinds.conf == 4"
        status: pass
      - kind: manual_procedural
        ref: "wev keycode check + live keypress test (hyprctl reload, wev, press Print/Shift+Print/Ctrl+Print/Alt+Print)"
        status: unknown
    human_judgment: true
    rationale: "Live keybind firing and physical PrtSc keycode emission can only be confirmed on real hardware via wev + hyprctl reload; the automated grep only proves the config text is correct, not that Hyprland dispatches the bind on this machine's keyboard."
  - id: D2
    description: "All three capture scripts (region/full/window) pipe hyprshot --raw into satty instead of the broken -r short flag, so satty receives valid raw image bytes on stdin"
    requirement: "SHOT-02"
    verification:
      - kind: unit
        ref: "for f in region full window; do grep -qE 'hyprshot -m .*-z --raw \\| satty ' capture-$f.sh && bash -n capture-$f.sh; done"
        status: pass
      - kind: manual_procedural
        ref: "Live keypress: satty opens with frozen image, Enter saves+copies, no 'Unrecognized image file format' error, no PNG dumped to ~"
        status: unknown
    human_judgment: true
    rationale: "Confirming satty actually opens with a valid frozen image and saves correctly requires hyprshot/satty installed and running on real hardware, which is outside this plan's automated verification (both binaries confirmed not yet installed on this dev machine per plan context)."
  - id: D3
    description: "Screenshots save to ~/Pictures/Screenshots and copy to clipboard, with exactly one notification, per the Omarchy-style freeze->annotate->save+copy flow"
    requirement: "SHOT-03"
    verification: []
    human_judgment: true
    rationale: "End-to-end save-path and clipboard behavior requires live human re-UAT with hyprshot/satty installed; no automated harness exists for this in the current toolchain."

duration: 3min
completed: 2026-07-13
status: complete
---

# Phase 06 Plan 14: Print-Key Screenshot Suite Gap Closure Summary

**Rebound the Print-key family to physical keycode 107 and swapped hyprshot's broken `-r` for the working `--raw` long form in all three capture scripts, closing SHOT-01/02/03's two UAT-blocking gaps.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-07-13T00:37:00Z
- **Completed:** 2026-07-13T00:38:16Z
- **Tasks:** 2
- **Files modified:** 4

## Accomplishments
- Print/Shift+Print/Ctrl+Print/Alt+Print binds now match physical `code:107`, bypassing XKB keysym translation and deterministically fixing the Alt case (the us keymap's `<PRSC>` is type `PC_ALT_LEVEL2`, so Alt selects level 2 = `Sys_Req`, never `Print`)
- All three capture scripts (`capture-region.sh`, `capture-full.sh`, `capture-window.sh`) now pipe `hyprshot ... --raw` into satty instead of the getopt-broken `-r` short flag
- Header comments across `keybinds.conf` and all three capture scripts rewritten to document the root cause (keycode vs keysym translation; getopt optstring mismatch) so future maintainers don't reintroduce either bug

## Task Commits

Each task was committed atomically:

1. **Task 1: Rebind the Print-key family by keycode (code:107)** - `bf5a760` (fix)
2. **Task 2: Replace broken -r with --raw in all three capture scripts** - `ddf08da` (fix)

_Note: No TDD tasks in this plan; both tasks are direct config/script edits._

## Files Created/Modified
- `hypr/.config/hypr/config/keybinds.conf` - Print-family binds (`, Print` / `SHIFT, Print` / `CTRL, Print` / `ALT, Print`) changed to `code:107` targets; section comment rewritten with keycode rationale and wev hardware caveat
- `hypr/.config/hypr/scripts/capture-region.sh` - `hyprshot -m region -z -r` → `hyprshot -m region -z --raw`; header comment rewritten to describe `--raw` and the getopt root cause
- `hypr/.config/hypr/scripts/capture-full.sh` - `hyprshot -m output -m active -z -r` → `hyprshot -m output -m active -z --raw`; header comment updated to reference the getopt root cause
- `hypr/.config/hypr/scripts/capture-window.sh` - `hyprshot -m window -z -r` → `hyprshot -m window -z --raw`; header comment updated to reference the getopt root cause

## Decisions Made
- Print-family binds rebound to `code:107` rather than attempting any keysym-level workaround — the root cause is structural (XKB level-shift on the us keymap makes ALT+Print resolve to `Sys_Req`, not `Print`), so no keysym-based fix could ever work for the Alt case.
- `--raw` used everywhere instead of `-r` — hyprshot 1.3.0's getopt optstring declares `-r` as argument-required while the handler treats it as a boolean flag, so only the long form parses cleanly through getopt.
- `SCREENSHOT_DIR="$HOME/Pictures/Screenshots"` (capitalized) left unchanged as directed by the plan — this is the canonical implemented path; the UAT's lowercase wording was the actual mismatch, not the code.

## Deviations from Plan

None - plan executed exactly as written. Both tasks matched their `<action>` blocks precisely; no auto-fixes, blocking issues, or architectural questions arose.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required. Live re-UAT (wev keycode check + keypress test) is documented in the plan's `<verification>` section and should be run manually per the plan's Live human re-UAT steps, since hyprshot/satty are not yet installed on this dev machine.

## Next Phase Readiness

- Both automated verification gates (grep + bash -n) pass cleanly for all 4 files.
- Live re-UAT (wev keycode check on real hardware, then keypress test with hyprshot/satty installed) remains the human step to close out SHOT-01/02/03 fully — coverage entries D1-D3 above are marked `human_judgment: true` pending that live check.
- No blockers for 06-15 (next gap-closure plan in this phase).

---
*Phase: 06-themed-surfaces-utility-suite*
*Completed: 2026-07-13*
