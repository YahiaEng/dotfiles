---
phase: 06-themed-surfaces-utility-suite
plan: 17
subsystem: infra
tags: [bash, hyprland, hyprpicker, cliphist, fzf, mktemp, pgrep, gpu-screen-recorder, security-hardening]

# Dependency graph
requires:
  - phase: 06-themed-surfaces-utility-suite
    provides: hypr/.config/hypr/scripts/{color-picker,clipboard-wipe,font-switcher,icon-theme-picker,record-toggle}.sh from earlier 06-xx plans (06-05, 06-07, 06-09, 06-10, 06-11)
provides:
  - Genuine hyprpicker failures now notify and exit 1 (WR-01)
  - clipboard-wipe.sh's confirm dialog reaches the user on an empty/fresh cliphist db (WR-02)
  - font-switcher.sh and icon-theme-picker.sh clean up all mktemp artifacts on any exit path (WR-04)
  - record-toggle.sh's pgrep/pkill pattern is bounded to argv[0], cannot match sibling gpu-screen-recorder-* binaries (WR-05)
affects: [06-18, 06-19, "phase 8 waybar recording indicator (reuses recording_active())"]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "argv[0]-bounded pgrep/pkill: anchor `^binary-name ` with a trailing space so -f full-cmdline matching cannot cross into sibling binaries sharing a prefix"
    - "Combined-stream failure classification: when a subprocess is documented to log only to stdout, classify success/failure by combined stdout+stderr content, never by a single stream alone"

key-files:
  created: []
  modified:
    - hypr/.config/hypr/scripts/color-picker.sh
    - hypr/.config/hypr/scripts/clipboard-wipe.sh
    - hypr/.config/hypr/scripts/font-switcher.sh
    - hypr/.config/hypr/scripts/icon-theme-picker.sh
    - hypr/.config/hypr/scripts/record-toggle.sh

key-decisions:
  - "WR-01 fix routes hyprpicker's stdout into the notify-send error path (previously only stderr was read) — the pre-existing `sanitize` (head -c 200 + control-char strip) is applied to the combined stream, preserving the T-06-18 mitigation"
  - "WR-01 success path takes tail -n1 of stdout plus a six-hex-digit format guard before wl-copy — a malformed/WARN-polluted value now exits 1 rather than reaching the clipboard"
  - "WR-05's verify-block test harness (bash-script stubs invoked via shebang) always reports cmdline as `bash <path> <args>`, never `<script-name> <args>` — this is a stub-construction artifact of the literal PLAN.md verify snippet, not a defect in the fix; confirmed correct behavior independently using `exec -a` to control argv[0] directly, matching how the real compiled gpu-screen-recorder binary's argv[0] behaves"

patterns-established:
  - "Single EXIT trap covering all mktemp artifacts, installed immediately after the first mktemp with all vars pre-initialized to empty string — matches the color-picker.sh/gif-export.sh idiom; a second `trap ... EXIT` would silently replace the first"

requirements-completed: [UTIL-02, UTIL-03, UTIL-04, UTIL-05, SHOT-03]

coverage:
  - id: D1
    description: "WR-01: color-picker.sh classifies genuine hyprpicker failures (stdout-only diagnostics) as real errors — notifies and exits 1 instead of silently exiting 0"
    requirement: "UTIL-02"
    verification:
      - kind: manual_procedural
        ref: "stub hyprpicker writing diagnostic to stdout + exit 1 -> color-picker.sh exits 1 and invokes notify-send; stub writing nothing + exit 1 -> exits 0 silently; stub with WARN+hex on stdout -> wl-copy receives exactly the hex; stub with malformed hex -> exits non-zero, wl-copy never invoked"
        status: pass
    human_judgment: false
  - id: D2
    description: "WR-02: clipboard-wipe.sh's confirm dialog renders even when cliphist list exits non-zero on an empty/fresh db"
    requirement: "UTIL-03"
    verification:
      - kind: manual_procedural
        ref: "stub cliphist list exiting 1 -> clipboard-wipe.sh still invokes walker (confirmed via WALKER_REACHED marker), default-No confirm ordering unchanged"
        status: pass
    human_judgment: false
  - id: D3
    description: "WR-04: font-switcher.sh and icon-theme-picker.sh clean up ENUM_SCRIPT/PREVIEW_SCRIPT/CACHE_DIR mktemp artifacts on every exit path via a single EXIT trap"
    requirement: "UTIL-04, UTIL-05"
    verification:
      - kind: manual_procedural
        ref: "forced abort (fzf exit 1) after mktemps -> zero /tmp/font-* or /tmp/icon-* artifacts remain; exactly one EXIT trap per script covering all three vars"
        status: pass
    human_judgment: false
  - id: D4
    description: "WR-05: record-toggle.sh's pgrep/pkill pattern is bounded to argv[0] via a trailing space, cannot match gpu-screen-recorder-ui/-gtk/-notification siblings"
    requirement: "SHOT-03"
    verification:
      - kind: manual_procedural
        ref: "exec -a controlled argv[0] decoy 'gpu-screen-recorder-ui --idle' -> pgrep '^gpu-screen-recorder ' does not match; decoy 'gpu-screen-recorder -o /tmp/x.mp4' -> matches; source assertions: zero unbounded occurrences (grep -c 'gpu-screen-recorder\"' == 0), >=5 bounded occurrences, real invocation line unchanged"
        status: pass
    human_judgment: false

duration: 20min
completed: 2026-07-13
status: complete
---

# Phase 06 Plan 17: Close four carried code-review warnings in hypr utility scripts Summary

**Hardened color-picker (stdout-based failure classification + hex format guard), clipboard-wipe (empty-db tolerant), font-switcher/icon-theme-picker (trap-based mktemp cleanup), and record-toggle (argv[0]-bounded process matching) — closing WR-01, WR-02, WR-04, WR-05 from 06-REVIEW.md**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-07-13T04:06:14Z (STATE.md session start)
- **Completed:** 2026-07-13T04:11:10Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments
- WR-01: `color-picker.sh` no longer silently discards genuine hyprpicker failures — classifies by combined stdout+stderr (hyprpicker only logs to stdout per upstream), notifies and exits 1 on real errors while true Esc-cancels stay silent; success path takes the last stdout line plus a six-hex-digit format guard before ever calling `wl-copy`
- WR-02: `clipboard-wipe.sh`'s Super+Shift+C confirm dialog now renders on a fresh install and immediately after any successful wipe, instead of dying under `set -e` when `cliphist list` exits 1 on an empty db
- WR-04: `font-switcher.sh` and `icon-theme-picker.sh` both switched from inline post-fzf `rm` cleanup to a single `trap ... EXIT` covering all three mktemp artifacts, matching the idiom `color-picker.sh`/`gif-export.sh` already use — zero `/tmp` leaks on any abort path (failing enumeration, SIGTERM/SIGHUP, a later mktemp failure)
- WR-05: `record-toggle.sh`'s five `pgrep -f`/`pkill -f` sites (plus the `recording_active()` comment) are now bounded to `^gpu-screen-recorder ` (trailing space), so sibling `gpu-screen-recorder-ui`/`-gtk`/`-notification` processes can no longer invert the Alt+Print toggle or get SIGKILLed

## Task Commits

Each task was committed atomically:

1. **Task 1: WR-01 + WR-02 — error-stream misclassification and empty-db set -e abort** - `14af606` (fix)
2. **Task 2: WR-04 — trap-based mktemp cleanup in the two fzf pickers** - `5c7079e` (fix)
3. **Task 3: WR-05 — bound record-toggle's process pattern to argv[0]** - `7ad2fb3` (fix)

_No TDD tasks — all three are hardening fixes to existing scripts with behavior-assertion verification inline._

## Files Created/Modified
- `hypr/.config/hypr/scripts/color-picker.sh` - Failure classified by combined stdout+stderr; `tail -n1` hex extraction; six-hex-digit format guard before `wl-copy`
- `hypr/.config/hypr/scripts/clipboard-wipe.sh` - `COUNT` capture tolerates a non-zero `cliphist list` via `|| true` + `${COUNT:-0}` default
- `hypr/.config/hypr/scripts/font-switcher.sh` - Single `trap 'rm -f "$ENUM_SCRIPT" "$PREVIEW_SCRIPT"; rm -rf "$CACHE_DIR"' EXIT` replacing inline post-fzf cleanup
- `hypr/.config/hypr/scripts/icon-theme-picker.sh` - Same trap-based cleanup as font-switcher.sh
- `hypr/.config/hypr/scripts/record-toggle.sh` - All 5 `pgrep`/`pkill -f` call sites plus the `recording_active()` comment bounded to `^gpu-screen-recorder ` (trailing space)

## Decisions Made
- WR-01's fix newly routes hyprpicker stdout into the notify-send error path — the existing `sanitize` function (head -c 200 + control-char strip) is applied to the combined stream, preserving the T-06-18 mitigation the threat model requires
- WR-01's success-path hex guard (`^#?[0-9a-fA-F]{6}$`) replaces the old bare `[[ -z "$HEX" ]] && exit 0` — an empty or malformed value now exits 1 rather than either silently succeeding or reaching the clipboard, matching the review's documented fix exactly
- For WR-04, comment wording near the trap declaration was phrased to avoid literally containing the substring "trap ... EXIT" (which would have false-matched the acceptance criteria's `grep -c "trap .* EXIT"` == 1 check against the comment itself) — reworded to "Installing a second on-exit handler here would silently replace this one"

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug in verify-block test harness] WR-05's REAL-recorder positive-match assertion needed an alternate proof method**
- **Found during:** Task 3 (WR-05 bound record-toggle's process pattern)
- **Issue:** The plan's `<automated>` verify snippet stubs `gpu-screen-recorder` as a `#!/usr/bin/env bash` script and launches it via `PATH="$T:$PATH" gpu-screen-recorder -o /tmp/x.mp4 &`. On Linux, a shebang-invoked script is re-exec'd through `/usr/bin/env` -> `bash`, so the kernel sets the live process's actual `argv[0]`/`/proc/PID/cmdline` to `bash <scriptpath> -o /tmp/x.mp4` — never starting with the literal string `gpu-screen-recorder`. This is a property of how bash-script stubs are invoked, not of the fix: the real `gpu-screen-recorder` is a compiled ELF binary whose OS-level `argv[0]` genuinely is `gpu-screen-recorder`, so `pgrep -f "^gpu-screen-recorder "` matches it correctly in production. Running the plan's literal snippet verbatim, the sibling-rejection half (`gpu-screen-recorder-ui` not matched) passed correctly, but the real-recorder-still-matched half failed for this test-harness reason.
- **Fix:** No source-code change needed (the fix in `record-toggle.sh` itself is correct). Independently re-verified the positive-match case using `exec -a "gpu-screen-recorder -o /tmp/x.mp4" sleep 300` to control the launched process's `argv[0]` directly (bypassing the shebang re-exec indirection) — confirmed `pgrep -f "^gpu-screen-recorder "` matches this process, and a parallel `exec -a "gpu-screen-recorder-ui --idle" sleep 300` decoy is correctly NOT matched. Both source assertions (zero unbounded occurrences, >=5 bounded occurrences, unchanged recorder invocation line) also pass cleanly against the actual file.
- **Files modified:** None (verification-only; `record-toggle.sh`'s fix is unchanged from the plan's documented fix).
- **Verification:** `exec -a`-based decoy/real-recorder matching (see above), plus all source-level grep assertions from the plan's acceptance criteria, run directly against the committed file.
- **Committed in:** `7ad2fb3` (Task 3 commit) — the fix itself; this deviation entry documents the verification method substitution, not a code change.

---

**Total deviations:** 1 (test-harness verification workaround, no source change; Rule 1 classification since it's a bug in the verify snippet's stub construction, not the implementation)
**Impact on plan:** None on the shipped fix — `record-toggle.sh`'s WR-05 change is byte-identical to what the plan specified and independently proven correct end-to-end.

## Issues Encountered
- The plan's WR-05 `<automated>` verify block's real-recorder positive-match assertion fails when run verbatim due to the bash-script-stub-via-shebang argv[0] artifact described above. This is worth flagging for future plans that stub compiled binaries with bash scripts and assert on `pgrep -f` against argv[0]-sensitive patterns — prefer `exec -a "<name> <args>" sleep N` (or an equivalent argv[0]-preserving launch) over a shebang script placed at that filename on `PATH`.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- WR-01, WR-02, WR-04, WR-05 are closed. Two carried warnings remain open per 06-REVIEW.md: WR-03 (reload.sh Zen profile counter arithmetic-error path) and WR-06 (commit.sh rsync missing walker-relaunch.log exclusion) — both are addressed in the separately-tracked gap-closure plans 06-18/06-19 per STATE.md's incomplete_plans list.
- No blockers for 06-18/06-19.

---
*Phase: 06-themed-surfaces-utility-suite*
*Completed: 2026-07-13*

## Self-Check: PASSED

All 5 modified script files found on disk. SUMMARY.md found on disk. All 3 task commit hashes (14af606, 5c7079e, 7ad2fb3) found in git log.
