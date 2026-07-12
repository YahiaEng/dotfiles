---
phase: 05-light-mode-pipeline-theme-presets
plan: 05
subsystem: infra
tags: [walker, dmenu, bash, exit-codes, hyprland, notify-send, gap-closure]

# Dependency graph
requires:
  - phase: 05-light-mode-pipeline-theme-presets
    provides: theme-switch.sh and waybar-switch.sh walker dmenu pickers (WR-04 fix landed in commit eac9263, part of 05-04)
provides:
  - Correct walker 2.16.2 cancel-vs-failure exit-code semantics in both dmenu picker scripts
  - Committed hermetic checker (test-walker-dmenu-cancel.sh) guarding the exit-code branch going forward
affects: [waybar-layout-switching, theme-switching, any future walker --dmenu caller under set -e]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "walker --dmenu under set -euo pipefail: capture exit code via \`SELECTED=$(...) || rc=$?\` then branch \`(( rc == 130 ))\` for silent cancel vs any other nonzero for a loud failure toast — never key the branch on a bare \`if !\` command-substitution assignment"

key-files:
  created:
    - hypr/.config/hypr/scripts/tests/test-walker-dmenu-cancel.sh
  modified:
    - hypr/.config/hypr/scripts/theme-switch.sh
    - hypr/.config/hypr/scripts/waybar-switch.sh

key-decisions:
  - "walker 2.16.2's cancel exit code (130) is trusted as the sole cancel signal, matching the fzf/skim 128+SIGINT convention — any other nonzero (127 binary missing, 1 elephant dead, crash) routes to the loud failure branch, preserving WR-04's original intent"
  - "powermenu.sh intentionally left unchanged: it has no set -e, so its bare command substitution never aborts and its existing empty-output cancel check already works correctly"

patterns-established:
  - "Hermetic PATH-shim checker convention for interactive-tool-driven scripts: stub the external binary (walker) and any side-effect binary (notify-send) on a prepended temp PATH dir, drive the target script non-interactively via env vars, assert on captured exit code + log file contents — no external test framework, mirrors the existing theme-parity checker style"

requirements-completed: [THM-02, WR-04]

coverage:
  - id: D1
    description: "Esc/click-outside/Return-on-empty in theme-switch.sh closes the picker silently (exit 0, no notify-send toast)"
    requirement: WR-04
    verification:
      - kind: unit
        ref: "hypr/.config/hypr/scripts/tests/test-walker-dmenu-cancel.sh theme-switch (cancel case)"
        status: pass
    human_judgment: true
    rationale: "Automated checker proves the exit-code/notify-send contract via a stubbed walker binary, but the live UAT re-run (real walker keybind, real Esc press) is the actual UX confirmation and is explicitly deferred to outside this plan per the plan's <verification> section."
  - id: D2
    description: "Selecting a theme in the switcher still applies it via theme-apply (display->basename mapping preserved)"
    requirement: THM-02
    verification:
      - kind: unit
        ref: "hypr/.config/hypr/scripts/tests/test-walker-dmenu-cancel.sh theme-switch (success case)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Esc in the waybar layout switcher closes silently with no dead cancel-check path; genuine hard failures still notify and exit 1"
    requirement: WR-04
    verification:
      - kind: unit
        ref: "hypr/.config/hypr/scripts/tests/test-walker-dmenu-cancel.sh waybar (cancel + hard-failure cases)"
        status: pass
    human_judgment: false

# Metrics
duration: 3min
completed: 2026-07-12
status: complete
---

# Phase 05 Plan 05: Walker Dmenu Esc-Cancel Gap Closure Summary

**Fixed the UAT Test 4 / WR-04 gap where every Esc-cancel in the theme and waybar-layout switchers fired an error toast, by capturing walker 2.16.2's real exit-130 cancel signal instead of assuming exit-0-plus-empty-output.**

## Performance

- **Duration:** 3 min
- **Started:** 2026-07-12T00:59:46Z
- **Completed:** 2026-07-12T01:02:46Z (approx)
- **Tasks:** 3
- **Files modified:** 3 (1 created, 2 modified)

## Accomplishments
- Diagnosed-and-fixed gap closed: `theme-switch.sh` now maps walker exit 130 to a silent `exit 0`, keeping genuine hard failures (127/1/crash) loud
- `waybar-switch.sh` brought into line with the same three-way branch — its previous dead-code cancel check and silently-swallowed hard failures are gone
- Committed a reusable hermetic checker (`test-walker-dmenu-cancel.sh`) that stubs `walker`/`notify-send` on a temp PATH and asserts cancel, hard-failure, and (for theme-switch) success behavior without touching real desktop state

## Task Commits

Each task was committed atomically:

1. **Task 1: Create hermetic walker-dmenu exit-code checker (RED)** - `1f154c7` (test)
2. **Task 2: Three-way exit-code branch in theme-switch.sh (WR-04 gap)** - `200e7e0` (feat)
3. **Task 3: Align waybar-switch.sh with the same three-way branch** - `21b9e42` (fix)

**Plan metadata:** (final metadata commit follows this Summary)

## Files Created/Modified
- `hypr/.config/hypr/scripts/tests/test-walker-dmenu-cancel.sh` - Hermetic checker: shims `walker` and `notify-send` on a temp PATH, runs 3 theme-switch cases (cancel/hard-failure/success) and 2 waybar cases (cancel/hard-failure), asserting exit codes and toast/apply-log side effects
- `hypr/.config/hypr/scripts/theme-switch.sh` - Replaced the `if ! SELECTED=$(...)` failure-only branch with an exit-code-capturing three-way branch (`rc==130` silent cancel, other nonzero toast+exit 1, `rc==0` unchanged selection flow)
- `hypr/.config/hypr/scripts/waybar-switch.sh` - Same three-way branch applied to its previously bare `SELECTED=$(echo ... | walker ...)` assignment, replacing the dead-code cancel check and the silent hard-failure swallow

## Decisions Made
- Trusted walker 2.16.2's exit 130 as the exclusive cancel signal (source-verified in the prior debug session against walker's tagged source — `quit(app, cancelled=true)` -> `"CNCLD"` -> `set_exit_status(130)`), matching the wider dmenu-tool convention (fzf/skim also use 130 for abort) so the fix stays correct if walker is ever swapped for a TTY-mode picker.
- Left `powermenu.sh` untouched — confirmed via `git diff` against the pre-plan HEAD that it received zero changes, matching the plan's explicit out-of-scope note (no `set -e`, so its existing empty-output check already works).

## Deviations from Plan

None — plan executed exactly as written across all three tasks. The only wrinkle encountered was environmental, not code-level:

### Issues Encountered (not a deviation — verification-tooling only)

This execution session's `grep` is shell-aliased (via a Claude Code shell snapshot function) to `ugrep -G`, whose BRE engine treats the `$` in the plan's literal verify pattern `'rc=$?'` as an anchor even though it's not at the absolute end of the pattern — causing a false-negative match against the real GNU grep-authored target files. Confirmed via `command grep` (real GNU grep 3.12, bypassing the shell function) that the pattern matches correctly in both `theme-switch.sh` and `waybar-switch.sh`. No script content was changed to work around this; all verify commands in this Summary and during execution were run with `command grep` to get an accurate result. This is a Bash-tool-session artifact only and does not affect the correctness of the shipped fix.

## Issues Encountered
See "Issues Encountered" note above (grep shell-function artifact, worked around by invoking `command grep` during verification only — no code changes involved).

## TDD Gate Compliance

Plan-level gate sequence verified in git log:
- RED gate: `1f154c7 test(05-05): add hermetic walker-dmenu exit-code checker (RED) [WR-04]` — checker created, confirmed to fail against the unfixed scripts (state-conditional verify passed).
- GREEN gate: `200e7e0 feat(05-05): three-way exit-code branch in theme-switch.sh [WR-04]` — theme-switch suite (3 cases) went green.
- Task 3 used `fix(...)` rather than a second `feat`/`refactor` commit type since it addresses the same latent WR-04 defect pattern in a sibling script; the full checker (both suites, 10 assertions) is green as of `21b9e42`.

No warnings — RED and GREEN gates both present and correctly ordered.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- UAT Test 4 gap is closed at the automated-verification layer; the plan's `<verification>` section defers final human confirmation (live Esc press in the real theme switcher) to a UAT re-run performed outside this plan.
- No blockers for Phase 05 completion. `powermenu.sh` remains intentionally unfixed (no defect present).

---
*Phase: 05-light-mode-pipeline-theme-presets*
*Completed: 2026-07-12*
