---
phase: 04-reliability-fixes-tech-debt
plan: 02
subsystem: hyprlock (screen lock / authentication)
tags: [hyprlock, hypridle, uwsm, keystroke-drop, config-migration, animations]

requires:
  - phase: 04-reliability-fixes-tech-debt (plan 01)
    provides: uwsm-correct power actions; SUMMARY/diagnosis documentation pattern
provides:
  - Lockout-recovery procedure (second TTY + pkill hyprlock) — reused by Phase 6 LOCK-01
  - Revised FIX-02 root cause — config options silently invalid after hyprlock upgrade + startup input race (NOT hyprwm/hyprlock#423)
  - hyprlock.conf migrated to valid hyprlock 0.9.5 option schema (nothing silently ignored)
  - immediate_render + fadeIn-disabled mitigation for the first-keystroke loss window
affects: [phase-06-lock-redesign, LOCK-01, hyprlock, hypridle]

tech-stack:
  added: []
  patterns:
    - "Verify config options against the installed binary's registered schema (strings /usr/bin/hyprlock) — never assume a config file that parses 'quietly' is fully active"
    - "hyprlock 0.9.x animations{} block (Hyprland-style animation tree) replaces no_fade_in/no_fade_out"

key-files:
  created:
    - .planning/phases/04-reliability-fixes-tech-debt/04-02-SUMMARY.md
  modified:
    - hypr/.config/hypr/hyprlock.conf

key-decisions:
  - "FIX-02 root cause revised at the Task 2 checkpoint: #423 grace-race hypothesis is dead — hyprlock 0.9.5 rejects general:grace entirely, so grace was never active; actual cause is silently-invalid config options + the startup window before the lock surface has keyboard focus"
  - "grace directive removed (not set to 0): general:grace does not exist in hyprlock 0.9.5 — grace is CLI-only (--grace, default 0) and no invocation in this repo passes it, so effective grace is 0 and cannot be re-enabled via config"
  - "First-keystroke mitigation: general:immediate_render = true (commit lock surface without waiting for resources) + animation = fadeIn, 0 (lock screen appears at full opacity instantly, so the visual cue matches when input registers)"
  - "input-field fail_transition removed — option no longer exists in 0.9.5 (log-verified rejection); fail-color transition is handled by the inputFieldColors animation default"
  - "hypridle.conf audited — no change required; idle path routes through the same hyprlock invocation with identical (grace-free) unlock behavior"

patterns-established:
  - "Lockout-safe lock-screen testing: second TTY logged in first, pkill hyprlock escape hatch — mandatory before any hyprlock test (D-20)"
  - "Silently-ignored-config audit: grep the tool's verbose startup output for 'config option ... does not exist' after every version bump"

requirements-completed: [FIX-02]

coverage:
  - id: D1
    description: "Lockout-recovery procedure (second TTY + pkill hyprlock) written before any lock test; reusable by Phase 6 LOCK-01"
    requirement: FIX-02
    verification:
      - kind: other
        ref: "grep -qi 'pkill hyprlock' 04-02-SUMMARY.md && grep -qiE 'second TTY|Ctrl\\+Alt\\+F2' 04-02-SUMMARY.md"
        status: pass
    human_judgment: false
  - id: D2
    description: "FIX-02 root cause diagnosed with captured evidence (grace=5 log run at /tmp/hyprlock-grace5.log): config options silently invalid in hyprlock 0.9.5 + startup input race — #423 ruled out"
    requirement: FIX-02
    verification:
      - kind: manual_procedural
        ref: "Task 2 human checkpoint: reproduced drop, captured hyprlock -v log; #423 signature absent, 4 config-rejection lines present"
        status: pass
    human_judgment: false
  - id: D3
    description: "hyprlock.conf migrated to valid 0.9.5 schema: dead options (grace, no_fade_in, no_fade_out, fail_transition) removed; immediate_render enabled; fadeIn animation disabled; no typography/color/source directive changed"
    requirement: FIX-02
    verification:
      - kind: other
        ref: "grep checks: no dead options remain; source line present; 3 label font_size values (96/22/18) unchanged; no color lines in diff"
        status: pass
    human_judgment: false
  - id: D4
    description: "D-23 10-trial lock-and-type protocol: 10/10 first-try unlocks across manual-lock and idle-lock paths"
    requirement: FIX-02
    verification: []
    human_judgment: true
    rationale: "Requires physically locking the real session and typing the password immediately, 10 times across two trigger paths — cannot be automated; deferred to end-of-phase UAT per human_verify_mode: end-of-phase"

duration: 25min
completed: 2026-07-11
status: complete
---

# Phase 4 Plan 2: Hyprlock First-Keystroke Drop (FIX-02) Summary

**FIX-02 root cause revised from the #423 grace-race to "config options silently invalid after hyprlock upgrade + startup input race" — hyprlock.conf migrated to the real 0.9.5 schema with immediate_render on and fadeIn disabled; 10-trial verification deferred to end-of-phase UAT.**

## Performance

- **Duration:** ~25 min execution (plus human checkpoint reproduction time)
- **Started:** 2026-07-11T13:11:00Z
- **Completed:** 2026-07-11T13:35:00Z
- **Tasks:** 3 of 4 complete (Task 4 = human 10-trial protocol, deferred to end-of-phase UAT)
- **Files modified:** 2

## Accomplishments

- Lockout-recovery procedure written BEFORE any lock test (D-20) — reusable by Phase 6 LOCK-01
- Keystroke drop reproduced at the Task 2 human checkpoint with full `hyprlock -v` capture (252K log, `/tmp/hyprlock-grace5.log`)
- #423 hypothesis definitively ruled out; real root cause identified and evidence-documented (D-19/D-25)
- hyprlock.conf migrated to the valid hyprlock 0.9.5 option schema — nothing silently ignored anymore
- hypridle idle-lock path audited: no change required

## Root Cause (revised — supersedes the plan's #423 hypothesis)

### What the Task 2 checkpoint found

The human reproduced the drop while running `uwsm app -- hyprlock -v 2>&1 | tee /tmp/hyprlock-grace5.log`:
first characters vanished, first auth attempt failed, second succeeded. The #423 signature
("In grace and cursor moved more than 5px, unlocking!" → "Unlock already happend?") was
**absent**. Instead, the log opened with four config rejections:

```
Config error in ... hyprlock.conf at line 8:  config option <general:grace> does not exist.
Config error in ... hyprlock.conf at line 10: config option <general:no_fade_in> does not exist.
Config error in ... hyprlock.conf at line 11: config option <general:no_fade_out> does not exist.
Config error in ... hyprlock.conf at line 87: config option <input-field:fail_transition> does not exist.
Proceeding ignoring faulty entries
```

### Root cause, part 1: config silently invalid after a hyprlock upgrade

hyprlock 0.9.5's registered config schema (verified against the installed binary via
`strings /usr/bin/hyprlock`) contains only these `general:` keys: `fail_timeout`,
`fractional_scaling`, `hide_cursor`, `ignore_empty_input`, `immediate_render`,
`screencopy_mode`, `text_trim`. Consequences:

- **`grace` is no longer a config option at all.** It survives only as the CLI flag
  `--grace`/`-g` (default 0; `--immediate` is deprecated in favor of `--grace 0`). No
  invocation path in this repo (`uwsm app -- hyprlock` in keybinds.conf/powermenu.sh/
  wlogout layout; `pidof hyprlock || hyprlock` in hypridle.conf) passes `--grace`, so
  **effective grace was already 0 at runtime** — `grace = 5` in the config was dead
  weight being ignored. The #423 grace-race could never have been the cause.
- **`no_fade_in`/`no_fade_out` were replaced by the `animations {}` block** (Hyprland-style
  animation tree: `animation = fadeIn, ...` / `fadeOut` / `inputFieldFade` /
  `inputFieldColors` / `inputFieldDots` / `inputFieldWidth`), confirmed by the packaged
  sample config at `/usr/share/hypr/hyprlock.conf`.
- **`input-field:fail_transition` was removed**; the fail-color transition is now the
  `inputFieldColors` animation.

The config predates this upstream option reorganization and was never re-validated after
the version bump — hyprlock "proceeds ignoring faulty entries," so nothing ever failed
loudly.

### Root cause, part 2: startup input race (the actual keystroke loss)

The captured log timeline shows:

1. ~690 lines of Wayland registry binding, EGL/GPU init, DMABUF modifier negotiation,
   and screencopy setup ("Resources gathered after 4 milliseconds" — resource load
   itself is fast; process+GPU init dominates the wall-clock window)
2. line 695 `Starting fade in` → line 710 `onLockLocked called`
3. After `onLockLocked`, rendering is a steady ~166 fps — no post-lock stall
4. line 1252 first `Authenticating` → line 1279 `PAM_PROMPT: Password:` → line 2157
   `ERR auth: Authentication failed` (truncated first password) → second attempt
   `Authenticating` → `auth: authenticated`

Keystrokes typed between invoking hyprlock and the ext-session-lock surface acquiring
keyboard focus (`onLockLocked` + surface commit) are never delivered to hyprlock's
password buffer — they go to the previously-focused client. The first password submission
is therefore missing its leading characters and PAM rejects it. This matches the D-17
fingerprint exactly (manual lock → type immediately → first chars vanish) without any
grace involvement.

## Fix Applied (Task 3)

`hypr/.config/hypr/hyprlock.conf`, scoped changes only:

| Change | Rationale |
|--------|-----------|
| `grace = 5` removed from `general{}` | Option does not exist in 0.9.5; grace is CLI-only, default 0, nothing passes it — the lock always requires a password immediately (satisfies the plan's grace=0 intent *more strongly*: grace cannot be re-enabled via config) |
| `no_fade_in = false` / `no_fade_out = false` removed | Options do not exist; replaced by the `animations{}` block |
| `general: immediate_render = true` added | Documented 0.9.5 mechanism to commit the lock surface without waiting for resources — shrinks the pre-lock window in which typed keys are lost |
| `animations { enabled = true; animation = fadeIn, 0 }` added | Disables ONLY the fade-in: the lock screen appears at full opacity the instant the session locks, so the visual "you can type now" cue matches when input actually registers. `fadeOut` and all input-field animations keep their defaults |
| `input-field: fail_transition = 200` removed (comment left in place) | Option does not exist in 0.9.5 (log-verified rejection at line 87); handled by the `inputFieldColors` animation default |

**Unchanged (parity verified via git diff + grep):** the `source = ~/.local/state/theme/hyprland.conf`
line; all three `label{}` blocks (font_size 96/22/18, FiraCode Nerd Font families, all
`$primary`/`$on_surface`/`$secondary` colors); the `background{}` block; every other
`input-field{}` directive including `fade_on_empty`/`fade_timeout`; no literal hex color
introduced anywhere.

## Hypridle Audit (D-14 completeness, idle path)

`hypr/.config/hypr/hypridle.conf` — **audited, no change required.**

- `lock_cmd = pidof hyprlock || hyprlock` — same binary, no `--grace`, `pidof` guard
  prevents double instances; identical unlock behavior to the manual path
- `before_sleep_cmd = loginctl lock-session` and the 600s `loginctl lock-session`
  listener both route through logind → the same `lock_cmd` — one code path, no
  divergent unlock behavior
- `after_sleep_cmd = hyprctl dispatch dpms on` and the dim/dpms/suspend listeners are
  unrelated to the input path

Per D-17 the symptom was manual-lock-only, consistent with this audit: both trigger
paths converge on the same hyprlock invocation.

## Behavior Changes (UI-SPEC Copywriting Contract)

1. **Grace-period move-cursor-to-unlock convenience: gone.** In practice it was already
   inactive (the option was being ignored), so day-to-day behavior does not change —
   but the *intended* config no longer promises it either. The lock screen always
   requires the password.
2. **No fade-in animation.** The lock screen now appears instantly at full opacity
   instead of fading in. Fade-out on unlock is unchanged. This is a deliberate trade:
   the instant appearance is the honest signal that the keyboard is live.

No typography, color, layout, or theming directive changed.

## Deviations from Plan

### [Rule 1 - Bug / checkpoint-directed re-diagnosis] Plan's #423 hypothesis and grace=0 instruction superseded by evidence

- **Found during:** Task 2 human checkpoint (evidence), applied in Task 3
- **Issue:** The plan assumed `grace = 5` was active and #423 was the root cause. The
  captured log proved `general:grace` (and three other options) do not exist in hyprlock
  0.9.5 and were being silently ignored — grace was never active; the #423 signature was
  absent. Writing `grace = 0` literally (as the plan's Task 3 action and automated verify
  specified) would have re-introduced an invalid option and another "config option does
  not exist" startup error.
- **Fix:** Per the checkpoint response (coordinator instruction), migrated the config to
  the valid 0.9.5 schema instead: dead options removed, `immediate_render = true` +
  `animation = fadeIn, 0` added as the version-correct mitigation for the startup input
  race. The plan's automated check `grep 'grace = 0'` is intentionally unsatisfied; its
  *intent* (no grace-unlock window; password always required) is satisfied more strongly —
  grace cannot be re-enabled via config at all in this version.
- **Files modified:** hypr/.config/hypr/hyprlock.conf

### [Rule 1 - Bug] input-field `fail_transition = 200` removed despite the input-field prohibition

- **Found during:** Task 2 checkpoint evidence (log line 87 rejection)
- **Issue:** The plan prohibited touching `input-field{}` "unless Task 2 evidence
  specifically implicates fade timing". The evidence directly implicates this exact line:
  hyprlock rejects it at startup ("config option <input-field:fail_transition> does not
  exist"). Leaving it would keep the config in a silently-erroring state, contradicting
  the coordinator's directive that nothing be silently ignored.
- **Fix:** Removed the single dead line with an explanatory comment; `fade_on_empty`,
  `fade_timeout`, and every other input-field directive untouched.
- **Files modified:** hypr/.config/hypr/hyprlock.conf

## Verification Record (D-23 / D-24)

**Status: PENDING human 10-trial protocol — deferred to end-of-phase UAT
(`human_verify_mode: end-of-phase`), per the Task 4 checkpoint definition.**

The one-time documented protocol to run (with the lockout-recovery procedure below in
force — second TTY logged in FIRST):

1. Log into a second TTY (`Ctrl+Alt+F2`, sign in), return to the session (`Ctrl+Alt+F1`).
2. Run ~10 lock → immediately-type-password trials, covering BOTH trigger paths:
   - **Manual path:** lock via keybind (`uwsm app -- hyprlock`) or the power menu Lock
     action; type the password the instant the screen locks.
   - **Idle path:** trigger via `loginctl lock-session` (equivalent to the hypridle 600s
     listener — same code path); type immediately.
3. Pass = 100%: every trial unlocks on the first attempt, no dropped first character,
   no failed-auth loop. If any trial drops input, record which path and how many — do
   not sign off below 100%.
4. Optional evidence: run one trial as `uwsm app -- hyprlock -v 2>&1 | tee /tmp/hyprlock-fixed.log`
   and confirm the log now contains **zero** "config option ... does not exist" lines.

## Lockout-Recovery Procedure (D-20 — reused by Phase 6 LOCK-01)

Written BEFORE any hyprlock test in this phase. This procedure is intentionally
generic/reusable — Phase 6 (LOCK-01) reuses it verbatim.

**Before testing any lock-screen change:**

1. **Log into a second TTY first.** Switch with `Ctrl+Alt+F2` (or F3/F4 — any free VT),
   sign in with your normal user credentials at the text login prompt. Keep this session
   open and logged in for the entire duration of hyprlock testing. Do not log out of it
   until testing is finished.
2. **Return to the graphical session** with `Ctrl+Alt+F1` (or whichever VT Hyprland/uwsm
   is running on — typically VT1).
3. **If the lock screen becomes unresponsive or a real lockout occurs** (password not
   accepted, screen frozen, no keyboard response), switch back to the second TTY
   (`Ctrl+Alt+F2`) using the already-authenticated session and run the escape hatch:
   ```bash
   pkill hyprlock
   ```
   This kills the hung/misbehaving hyprlock process from outside the locked session,
   which immediately returns the graphical session to its unlocked state (Hyprland does
   not re-lock automatically after a killed hyprlock process).
4. **Restore a working session:** after `pkill hyprlock`, switch back to `Ctrl+Alt+F1` —
   the desktop should be usable again. If hyprlock needs to be tested again, simply
   re-trigger the lock (keybind, menu action, or `loginctl lock-session`) once ready.
5. **Never test a lock-screen config change without step 1 done first.** A second TTY
   with an already-authenticated shell is the only guaranteed way to recover from a
   stuck/broken lock screen without a hard power cycle.

### Diagnosis capture procedure (as used at the Task 2 checkpoint)

Hyprlock has no persistent log file (`~/.cache/hyprlock/` does not exist) and no
dedicated systemd unit scope on this machine — verbose output only goes to stderr of the
invoking terminal:

```bash
uwsm app -- hyprlock -v 2>&1 | tee /tmp/hyprlock-<label>.log
```

Grep the capture for `config option .* does not exist` (silently-ignored config) and for
auth-flow anomalies (`Authenticating`, `PAM_PROMPT`, `Authentication failed`). The
historical #423 signature ("In grace and cursor moved more than 5px, unlocking!" →
"Unlock already happend?" — sic, upstream typo) is only reachable when a grace period is
actually active, which is impossible via config in hyprlock 0.9.5.

## Threat Model Dispositions

| Threat | Disposition | Outcome |
|--------|-------------|---------|
| T-04-04 (EoP: grace unlock-without-password window) | mitigate | **Stronger than planned:** grace is not just 0 — the option no longer exists in the config schema, and no CLI invocation passes `--grace`. The lock always requires a password |
| T-04-05 (DoS: keystroke drop → failed-auth loops) | mitigate | `immediate_render` + instant (non-faded) lock appearance shrink/signal the input-live window; 100% confirmation pending the D-23 10-trial protocol at end-of-phase UAT |
| T-04-06 (DoS: testing locks the user out) | mitigate | Lockout-recovery procedure written and used before the first test (second TTY was logged in during the Task 2 reproduction) |

## Known Stubs

None — no placeholder values or unwired surfaces introduced.

## Self-Check: PASSED

- 04-02-SUMMARY.md exists; hyprlock.conf modified as documented
- Task commits verified in git log: 37c2dd9 (Task 1), 2e31123 (Task 3)
- No unexpected file deletions in any task commit
