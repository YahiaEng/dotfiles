---
status: diagnosed
trigger: "UAT Test 4: Pressing Esc in walker dmenu theme switcher shows error notification instead of closing silently (post-eac9263)"
created: 2026-07-12T00:00:00Z
updated: 2026-07-12T00:40:00Z
---

## Current Focus
<!-- OVERWRITE on each update - reflects NOW -->

hypothesis: CONFIRMED — walker 2.16.2 deliberately exits 130 (no stdout) on dmenu Esc-cancel; theme-switch.sh's WR-04 branch keys the error toast on any nonzero pipeline exit, so every cancel fires the toast
test: source-level verification against the exact installed version (walker v2.16.2 tagged source from GitHub) + installed binary strings + local process/system state
expecting: n/a — root cause established
next_action: hand off to plan-phase --gaps (goal is find_root_cause_only; no fix applied)

## Symptoms
<!-- Written during gathering, then IMMUTABLE -->

expected: Open theme switcher keybind, press Esc without selecting anything -> switcher closes silently, no error notification. Selecting a theme still applies normally.
actual: An error notification ("walker dmenu failed") appears when Esc is pressed in the walker dmenu theme switcher.
errors: notify-send error toast "Error / walker dmenu failed" (app "Theme Switcher", icon dialog-error) on Esc-cancel
reproduction: Test 4 in .planning/phases/05-light-mode-pipeline-theme-presets/05-UAT.md — run theme-switch keybind, press Esc
started: Discovered during UAT immediately after fix commit eac9263 "fix(05): set -euo pipefail + walker failure handling in theme-switch.sh [WR-04]". Before eac9263, cancel path was `[[ -z "$SELECTED" ]] && exit 0` with no exit-code check, so no toast could appear.

## Eliminated
<!-- APPEND only - prevents re-investigating -->

- hypothesis: "set -o pipefail makes printf's SIGPIPE (exit 141) the pipeline status when walker exits before draining stdin, producing a spurious nonzero exit on cancel"
  evidence: The dmenu input is 22 short lines (20 palette basenames = 216 bytes + 2 Material You entries; well under 1 KB prettified) — orders of magnitude below the 64 KB kernel pipe buffer. printf writes everything into the buffer and exits 0 immediately, long before walker maps its window, so its write can never hit a closed read end. SIGPIPE is physically impossible here; with printf at exit 0, the pipeline status equals walker's own status with or without pipefail. pipefail is a non-factor.
  timestamp: 2026-07-12T00:35:00Z

- hypothesis: "walker signals user-cancel as exit 0 with empty output, and something else (env, notify-send, set -e interaction) causes the toast"
  evidence: walker v2.16.2 source proves cancel is NEVER exit 0 + empty output. Esc -> ACTION_CLOSE -> quit(app, cancelled=true) -> service mode sends "CNCLD" -> client exit status set to 130 (src/ui/window.rs:705, 871-885; src/main.rs:598-608). Even Return on an empty input line converts empty text to "CNCLD" -> 130 (src/ui/window.rs:504-517). The `[[ -z "$SELECTED" ]] && exit 0` cancel path on line 50 is unreachable for real cancels.
  timestamp: 2026-07-12T00:38:00Z

## Evidence
<!-- APPEND only - facts discovered -->

- timestamp: 2026-07-12T00:00:00Z
  checked: hypr/.config/hypr/scripts/theme-switch.sh (current HEAD f918a95) and `git show eac9263`
  found: "Lines 46-49: `if ! SELECTED=$(printf '%s\n' \"${DISPLAYS[@]}\" | walker --dmenu --placeholder 'Select Theme'); then notify-send ... exit 1; fi`. The error branch is keyed SOLELY on the pipeline's exit status. The empty-output cancel check on line 50 is only reachable when the pipeline exits 0. Script has `set -euo pipefail` (line 8)."
  implication: If walker exits nonzero on Esc-cancel, the cancel path is unreachable and the toast fires on every cancel.

- timestamp: 2026-07-12T00:15:00Z
  checked: `walker --version` / `--help`, `pacman -Qi walker`, `pacman -Ql walker`, man pages
  found: walker 2.16.2-1 installed (matches UAT machine). No man page, no packaged docs beyond LICENSE, --help does not document exit codes. Binary is a stripped Rust ELF.
  implication: Exit-code behavior must be established from the binary and upstream tagged source.

- timestamp: 2026-07-12T00:20:00Z
  checked: `pgrep -fa 'walker|elephant'` and `strings /usr/bin/walker`
  found: This machine runs walker in SERVICE mode — `/usr/bin/walker --gapplication-service` (PID 601194) and `/usr/bin/elephant` (PID 917) both alive. Binary strings contain `g_application_command_line_set_exit_status` and `make sure 'walker --gapplication-service' is running!`.
  implication: A `walker --dmenu` invocation from theme-switch.sh is a GApplication remote instance; its exit status is whatever the primary service instance sets via g_application_command_line_set_exit_status. The service-mode code path in main.rs is the live path on this machine.

- timestamp: 2026-07-12T00:30:00Z
  checked: walker v2.16.2 tagged source (raw.githubusercontent.com/abenz1267/walker/v2.16.2): src/main.rs, src/ui/window.rs, src/keybinds.rs
  found: |
    Complete cancel path, service mode (this machine):
    1. keybinds.rs — config.keybinds.close registers ACTION_CLOSE ("%CLOSE%"); Esc is the default close bind.
    2. window.rs:705 — `ACTION_CLOSE => quit(&app, true)`; window.rs:444 — click-outside (click_to_close) also calls `quit(&app_copy, true)`.
    3. window.rs:871-885 — `pub fn quit(app, cancelled)`: if a dmenu sender exists, sends "CNCLD"; in NON-service mode with cancelled=true it calls `process::exit(130)` directly.
    4. main.rs:598-608 — the dmenu command-line handler awaits the oneshot channel: on "CNCLD" -> `cmd.set_exit_status(130)`; on dropped sender -> also 130.
    5. window.rs:504-517 (`handle_dmenu_print`) — empty input text on Return is converted to "CNCLD" -> 130 too.
    Hard-failure codes are distinct: elephant missing -> `process::exit(1)` (main.rs:667); walker binary missing -> shell 127; dead service in non-service startup path prints "make sure 'walker --gapplication-service' is running!" and exits nonzero != 130.
  implication: walker 2.16.2 signals user cancel EXCLUSIVELY via exit status 130 (128+SIGINT convention, same as fzf) with no stdout — in both service and non-service modes. eac9263's assumption (cancel = exit 0 + empty output) is wrong for this tool.

- timestamp: 2026-07-12T00:35:00Z
  checked: byte size of dmenu input vs pipe buffer (pipefail/SIGPIPE analysis)
  found: 20 palette JSONs in ~/.config/theme-engine/palettes (216 bytes of basenames) + 2 Material You entries = 22 lines, <1 KB prettified; kernel pipe buffer is 64 KB.
  implication: printf completes and exits 0 before walker reads anything; SIGPIPE cannot occur; pipefail does not contribute. Pipeline exit status == walker's exit status.

## Resolution
<!-- OVERWRITE as understanding evolves -->

root_cause: |
  Commit eac9263 (WR-04) assumes walker's dmenu signals user-cancel with exit 0 + empty
  output, reserving nonzero exit for hard failures. walker 2.16.2 does the opposite:
  on Esc (and click-outside, and Return-on-empty-input) it deliberately reports exit
  status 130 with no output — via `quit(app, cancelled=true)` -> "CNCLD" ->
  `cmd.set_exit_status(130)` in service mode (the mode running on this machine), or
  `process::exit(130)` standalone (walker v2.16.2 src/ui/window.rs:705,871-885;
  src/main.rs:598-608). theme-switch.sh line 46 keys the error branch on ANY nonzero
  pipeline exit, so every Esc-cancel takes the failure branch and fires the
  notify-send toast; the `[[ -z "$SELECTED" ]] && exit 0` cancel check on line 50 is
  unreachable for real cancels. pipefail/printf-SIGPIPE was analyzed and eliminated
  (input is 22 lines, far below the 64 KB pipe buffer; printf always exits 0 first).
fix: ""  # not applied — goal is find_root_cause_only
verification: ""
files_changed: []

suggested_fix_direction: |
  Capture walker's exit code explicitly instead of a bare `if !` and branch three ways,
  keeping WR-04's intent intact:

    rc=0
    SELECTED=$(printf '%s\n' "${DISPLAYS[@]}" | walker --dmenu --placeholder "Select Theme") || rc=$?
    if (( rc == 130 )); then
        exit 0                     # user cancel — walker's documented cancel status (128+SIGINT)
    elif (( rc != 0 )); then
        notify-send -a "Theme Switcher" "Error" "walker dmenu failed" -i dialog-error 2>/dev/null || true
        exit 1                     # hard failure: not installed (127), elephant dead (1), crash
    fi
    [[ -z "$SELECTED" ]] && exit 0 # defensive; walker never returns 0+empty, but harmless

  Notes for the planner:
  - `|| rc=$?` keeps `set -e` satisfied without a set +e/set -e dance.
  - Treating exit 130 as cancel matches walker's own semantics AND the wider dmenu
    ecosystem (fzf/skim use 130 for abort), so it stays correct if walker is ever
    swapped for fzf in a TTY context.
  - Hard failures remain loud: walker missing -> 127, elephant missing -> walker exits 1,
    service/D-Bus failure -> nonzero != 130. All still hit the toast branch.
  - Edge case accepted: walker also maps an internally dropped dmenu sender to 130
    (main.rs:606-608) — indistinguishable from cancel by design upstream; silent exit
    is the correct UX for it anyway (window closed without a selection).
  - Any other script piping into `walker --dmenu` under `set -e` has the same trap —
    worth a quick repo grep during fix planning (theme-switch.sh is the only hit today).
