---
phase: 04-reliability-fixes-tech-debt
plan: 06
subsystem: infra
tags: [hyprlock, hyprland, pam, config, dotfiles]

# Dependency graph
requires:
  - phase: 04-reliability-fixes-tech-debt (plan 02)
    provides: hyprlock 0.9.5 schema migration (grace/no_fade_in/no_fade_out/fail_transition removed, immediate_render + fadeIn disabled)
provides:
  - "general:ignore_empty_input = true — ENTER on an empty password buffer is ignored outright, no PAM round starts"
  - "input-field:check_text = <i>Checking...</i> — visible cue during any legitimate in-flight PAM verification"
affects: [phase-06-hyprlock-redesign, hyprlock-theming]

# Tech tracking
tech-stack:
  added: []
  patterns: ["hyprlock config options verified against installed binary schema via `strings /usr/bin/hyprlock` before relying on them — avoids repeating the 04-02 silent-rejection failure mode"]

key-files:
  created: []
  modified: [hypr/.config/hypr/hyprlock.conf]

key-decisions:
  - "check_text wording left to executor discretion per plan; used '<i>Checking...</i>' to match the existing fail_text pango-markup style"

patterns-established:
  - "Schema cross-check pattern: before adding any hyprlock.conf option, confirm it exists via `strings /usr/bin/hyprlock | grep -qx 'section:option'` — a deterministic substitute for live-parse verification since hyprlock has no non-locking config-validation flag"

requirements-completed: [FIX-02]

coverage:
  - id: D1
    description: "ENTER on an empty password field is ignored — no PAM round starts, no ~2-3s input-blocked window, no pam_faillock tally growth"
    requirement: "FIX-02"
    verification:
      - kind: other
        ref: "grep -Eq '^[[:space:]]*ignore_empty_input[[:space:]]*=[[:space:]]*true' hypr/.config/hypr/hyprlock.conf && strings /usr/bin/hyprlock | grep -qx 'general:ignore_empty_input'"
        status: pass
    human_judgment: true
    rationale: "Config presence + schema registration is automatically verified, but the actual runtime behavior (no dropped keystrokes on ENTER-first unlock) requires a real lock-session UAT re-test, deferred to end-of-phase per human_verify_mode: end-of-phase (D-23 protocol documented in the plan)."
  - id: D2
    description: "After lock activates, the first keystrokes register on the first attempt whether the user types immediately or presses ENTER first — no dropped input, no failed-auth loop"
    requirement: "FIX-02"
    verification:
      - kind: other
        ref: "git diff hypr/.config/hypr/hyprlock.conf — confirms only ignore_empty_input and check_text added, all other directives byte-identical"
        status: pass
    human_judgment: true
    rationale: "The end-to-end unlock-reliability claim can only be confirmed by a real 10-trial lock-and-type UAT session (D-23 protocol) — deferred to end-of-phase human verification, cannot be automated without a graphical session."
  - id: D3
    description: "Any legitimate in-flight PAM verification shows a visible 'checking' cue, so the keyboard is never a silent dead input"
    requirement: "FIX-02"
    verification:
      - kind: other
        ref: "grep -Eq '^[[:space:]]*check_text[[:space:]]*=[[:space:]]*.+' hypr/.config/hypr/hyprlock.conf && strings /usr/bin/hyprlock | grep -qw 'check_text'"
        status: pass
    human_judgment: true
    rationale: "Visual confirmation that the checking text actually renders during a wrong-password PAM round requires a human to observe the lock screen live (optional cue check in the D-23 protocol) — deferred to end-of-phase human verification."

duration: 8min
completed: 2026-07-11
status: complete
---

# Phase 04 Plan 06: Hyprlock ENTER-First Input Drop Gap Closure Summary

**Closed the FIX-02 UAT gap by adding `general:ignore_empty_input = true` and `input-field:check_text` to hyprlock.conf, both pre-verified against the installed hyprlock 0.9.5 binary schema.**

## Performance

- **Duration:** 8 min
- **Started:** 2026-07-11T21:39:19+03:00 (first task commit)
- **Completed:** 2026-07-11T21:39:35+03:00 (second task commit)
- **Tasks:** 2
- **Files modified:** 1

## Accomplishments
- Added `general:ignore_empty_input = true` so ENTER on an empty password buffer is ignored outright — no PAM round starts, no ~2-3s input-blocked window (pam_unix failure delay), no pam_faillock tally growth from repeated empty submits
- Added `input-field:check_text = <i>Checking...</i>` so any legitimate in-flight PAM verification (e.g. a genuinely wrong password) shows a visible "checking" cue instead of a silent dead keyboard
- Both option names pre-verified present in hyprlock 0.9.5's registered schema via `strings /usr/bin/hyprlock`, avoiding the silent-rejection failure mode that caused the original 04-02 gap

## Task Commits

Each task was committed atomically:

1. **Task 1: Guard the empty-submit trigger (general:ignore_empty_input)** - `520f6a7` (fix)
2. **Task 2: Add a visible in-flight verification cue (input-field:check_text)** - `069c2ab` (feat)

**Plan metadata:** (this commit)

## Files Created/Modified
- `hypr/.config/hypr/hyprlock.conf` - Added `ignore_empty_input = true` to `general{}` and `check_text = <i>Checking...</i>` to `input-field{}`; no other directive changed (confirmed via `git diff`)

## Decisions Made
- `check_text` wording left to executor discretion per the plan; chose `<i>Checking...</i>` to match the existing `fail_text = <i>$FAIL</i>` pango-markup convention in the same block.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Config-only fix complete and committed; both options confirmed active against the installed binary schema.
- End-of-phase human re-UAT still required per `human_verify_mode: end-of-phase`: re-run the D-23 10-trial lock-and-type protocol (ENTER-first and type-immediately variants across both manual-keybind and idle-lock paths), plus the optional wrong-password `check_text` visual cue check. Precondition: keep a second TTY authenticated as the lockout-recovery escape hatch (`pkill hyprlock`).
- No blockers for subsequent phase-04 plans or the later Phase 6 hyprlock redesign — this plan only touched `general{}` and `input-field{}` directives already scoped for future redesign work.

---
*Phase: 04-reliability-fixes-tech-debt*
*Completed: 2026-07-11*

## Self-Check: PASSED

- FOUND: hypr/.config/hypr/hyprlock.conf
- FOUND: .planning/phases/04-reliability-fixes-tech-debt/04-06-SUMMARY.md
- FOUND commit: 520f6a7
- FOUND commit: 069c2ab
- FOUND commit: ac50805
