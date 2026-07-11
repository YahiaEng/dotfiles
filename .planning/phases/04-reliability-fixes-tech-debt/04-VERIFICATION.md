---
phase: 04-reliability-fixes-tech-debt
verified: 2026-07-11T22:05:00Z
status: human_needed
score: 6/8 must-haves verified
behavior_unverified: 2 # SC1 (wlogout reliability, FIX-01/D-22) and SC2 (hyprlock keystroke reliability, FIX-02/D-23) — fix code present + wired + schema-verified, D-22/D-23 runtime reliability tests still pending (human_verify_mode: end-of-phase)
overrides_applied: 0
re_verification:
  previous_status: human_needed
  previous_score: 6/8
  gaps_closed:
    - "UAT Test 2 gap: ENTER-first empty-submit input drop on hyprlock — closed by gap-closure plan 04-06 (commits 520f6a7, 069c2ab), adding general:ignore_empty_input = true and input-field:check_text, both schema-verified against the installed hyprlock 0.9.5 binary. The ENTER-first path no longer opens a PAM round, eliminating the failed-auth loop the UAT reproduced."
  gaps_remaining: []
  regressions: []
gaps: []
deferred: []
behavior_unverified_items:
  - truth: "Selecting Shutdown/Reboot from wlogout (or the walker power menu) completes every time with no blank-screen hang (ROADMAP SC1 / D-22 5-cycle protocol)"
    test: "Run the D-22 protocol: 5 consecutive real Shutdown/Reboot cycles from wlogout, alternating keyboard and mouse selection. After each boot, grep `journalctl -b -1` for stop-sigterm/timed-out/nvidia_drm/failed lines."
    expected: "All 5 cycles power off/reboot cleanly with no black-screen hang and no teardown-timeout journal errors."
    why_human: "Requires physically triggering real shutdown/reboot cycles and observing hardware behavior across multiple boots — cannot be simulated or grepped from static config. Note: 04-UAT.md Test 1 (D-22) already recorded 'pass' from a prior human run; this item is retained per the phase's end-of-phase human_verify_mode gate and because 04-REVIEW.md's WR-01 (uwsm session-cgroup teardown race, from the pre-04-06 review) was an unresolved theoretical risk not explicitly re-confirmed as closed in the fresh post-04-06 review — carried forward for completeness, not because new doubt was found."
  - truth: "After lock screen activation, the first keystrokes register — password typed in one attempt, no dropped-input failed-auth loop, 100% across 10 trials covering both manual-lock and idle-lock paths, including the ENTER-first variant (ROADMAP SC2 / D-23 protocol)"
    test: "Run the D-23 protocol: ~10 lock-then-type trials across both the manual lock keybind and the idle-lock (loginctl lock-session) path, mixing ENTER-first and type-immediately variants, with a second TTY logged in first per the lockout-recovery procedure. Optional: submit one deliberately-wrong password and confirm the check_text 'Checking...' cue is visible."
    expected: "100% first-try unlock across all 10 trials (both variants, both paths), no dropped first characters, no failed-auth loop."
    why_human: "Requires physically locking the real graphical session and typing a password immediately, repeated across two trigger paths and two entry variants (type-immediately, ENTER-first) — a real-time keyboard-focus/PAM-timing race that cannot be reproduced by static analysis. The 04-06 gap-closure fix (general:ignore_empty_input = true, input-field:check_text) is config-present, schema-verified against the installed hyprlock 0.9.5 binary, and correctly scoped (git diff shows only the two intended directives changed) — but the end-to-end 100%-first-try claim, specifically for the previously-failing ENTER-first path, has not yet been re-confirmed live."
human_verification:
  - test: "D-22: wlogout 5-cycle shutdown/reboot reliability test — from the wlogout menu, perform 5 consecutive real cycles alternating keyboard/mouse selection and Shutdown/Reboot. After each boot, grep journalctl -b -1 for teardown-timeout signatures."
    expected: "5/5 clean cycles, no black-screen hang, no 'stop-sigterm timed out' / nvidia_drm failure lines."
    why_human: "Requires physically power-cycling real hardware across multiple boots. Note: 04-UAT.md already recorded this as 'pass' in the most recent human UAT session (2026-07-11) — retained here as the formal end-of-phase sign-off item per human_verify_mode: end-of-phase, not because new doubt exists."
  - test: "D-23: hyprlock 10-trial lock-and-type reliability re-test (post-04-06) — with a second TTY logged in, perform ~10 lock-then-type trials across both the manual-lock keybind and the idle-lock (loginctl lock-session) path, explicitly mixing ENTER-first and type-immediately variants. Optionally submit one deliberately-wrong password to confirm the check_text 'Checking...' cue renders."
    expected: "100% first-try unlock across all variants and paths, no dropped first character, no failed-auth loop — including the previously-failing ENTER-first case."
    why_human: "Requires physically locking the real session and typing a password immediately, repeated across two trigger paths and two entry variants — a real-time input/PAM-timing race that cannot be captured by static analysis. This is the direct re-test of the gap 04-06 closed at the config level; UAT has not yet re-run Test 2 against the new config."
  - test: "D-24: container-gate rerun (verify/container-run.sh) — push this phase's commits to origin/main, then run verify/container-run.sh from the repo root."
    expected: "Clean clone -> install.sh --core-only -> stow.sh -> theme-parity all pass; summary.log records overall=PASS."
    why_human: "Requires a git push decision and a real container/network round-trip. Local branch is 10 commits ahead of origin/main (unpushed) as of this re-verification — the precondition remains unmet. Note: 04-UAT.md records this as 'pass' from a prior run (implying it was exercised through some means), but the precondition of an unpushed branch is inherently re-checked at each verification pass."
  - test: "New-kitty-window fish smoke check — open a new kitty window in normal daily use and observe the fastfetch greeting + oh-my-posh prompt + node tooling."
    expected: "Fast, clean startup with a working prompt and node/npm/npx available."
    why_human: "Low-value reconfirmation — already independently reproduced live in a prior verification pass (NODE=YES, node v24.18.0, npm/npx 11.16.0) and confirmed via UAT ('pass'). Kept for completeness of the end-of-phase human checklist."
---

# Phase 4: Reliability Fixes & Tech Debt Verification Report

**Phase Goal:** The three known reliability/performance defects are root-caused and fixed, and the v1 tech-debt carry-over is closed — de-risking the base before any redesign layers on top.
**Verified:** 2026-07-11T22:05:00Z
**Status:** human_needed
**Re-verification:** Yes — after gap closure (plan 04-06, commits 520f6a7, 069c2ab), following the 04-06 UAT gap reported against the previous verification's FIX-02 status.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Shutdown/Reboot from wlogout complete every time with no blank-screen hang; root cause diagnosed and documented, not patched around (ROADMAP SC1 / FIX-01) | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Unchanged by 04-06 (which touched only hyprlock.conf). `wlogout/.config/wlogout/layout` re-confirmed by direct read on this run: Shutdown/Reboot still use `hyprshutdown --post-cmd 'systemctl poweroff\|reboot'`, wired to the live keybind (`hypr/config/keybinds.conf:25` → `wlogout.sh`). 04-UAT.md's Test 1 (D-22) already recorded `pass` from a human session on 2026-07-11, but the phase's `human_verify_mode: end-of-phase` retains this as a formal sign-off item; kept ⚠️ rather than promoted to ✓ because no fresh D-22-labeled re-confirmation exists specific to this verification pass and the fresh 04-REVIEW.md (commit `2107bc6`) did not explicitly re-affirm WR-01's uwsm-cgroup-survival theory as resolved. |
| 2 | After lock activation, the very first keystrokes register — password typed in one attempt, no dropped-input failed-auth loop (ROADMAP SC2 / FIX-02) | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED (gap closed at code level) | **UAT-identified gap now closed.** 04-UAT.md Test 2 (2026-07-11) reported: ENTER-first-then-type caused a failed-auth loop with zero registered keystrokes. Root cause fully diagnosed (`.planning/debug/hyprlock-enter-first-input-drop.md`): hyprlock 0.9.5 drops all keyboard input while a PAM round is in flight, and ENTER on an empty buffer (with `ignore_empty_input` unset, defaulting to 0) started such a round. Gap-closure plan 04-06 (commits `520f6a7`, `069c2ab`) added `general:ignore_empty_input = true` (ENTER on empty buffer no longer starts a PAM round) and `input-field:check_text = <i>Checking...</i>` (visible cue for any remaining wrong-password PAM round). Both directly re-confirmed present in `hypr/.config/hypr/hyprlock.conf` on this run and both independently re-verified against the installed hyprlock 0.9.5 binary schema (`strings /usr/bin/hyprlock \| grep -qx 'general:ignore_empty_input'` → match; `strings /usr/bin/hyprlock \| grep -qw 'check_text'` → match). `git diff bc2911b..HEAD -- hyprlock.conf` confirms only these two directives (plus comments) changed — no color/font/size/layout/animation regression. The D-23 10-trial re-test (specifically covering the ENTER-first variant that failed) has not yet been re-run against this new config — remains the gating human step. |
| 3 | Opening a new kitty terminal feels instant — startup profiled before/after, regression gone (ROADMAP SC3 / FIX-03) | ✓ VERIFIED | Unchanged by 04-06 (config-only hyprlock edit, no shell/kitty files touched). Quick regression check: `kitty/.config/kitty/kitty.conf` still has `shell fish`; fish/zsh startup optimizations unchanged. Independently re-measured in an earlier verification pass (97.4ms zsh / 33.9ms fish vs. 641ms pre-fix baseline); also confirmed `pass` in 04-UAT.md's "New-kitty-window fish smoke check". |
| 4 | A fresh install.sh run installs rsync explicitly (listed in PACMAN_PKGS) (ROADMAP SC4 / DEBT-01) | ✓ VERIFIED | Unchanged. Quick regression check: `install.sh` PACMAN_PKGS still contains an uncommented `rsync` line, flowing through the `verify_packages` hard-fail gate. |
| 5 | All six wlogout actions audited against the uwsm session model; shutdown/reboot no longer bare `systemctl` (04-01-PLAN.md must_have) | ✓ VERIFIED | Unchanged. Direct read confirms Lock=`uwsm app -- hyprlock`, Logout=`uwsm stop`, Suspend/Hibernate=bare `systemctl` (intentional per D-14), Shutdown/Reboot=`hyprshutdown --post-cmd ...`. 04-REVIEW.md's fresh WR-04 (logout not given the same graceful-teardown wrapper as shutdown/reboot) is a carried-forward, non-blocking design observation, not a regression from this phase's stated scope. |
| 6 | Lockout-recovery procedure (second TTY + `pkill hyprlock`) written before any hyprlock test (04-02-PLAN.md must_have, D-20) | ✓ VERIFIED | Unchanged. 04-02-SUMMARY.md still contains the documented procedure; 04-06-PLAN.md's human re-test section explicitly re-states the same precondition. |
| 7 | Optimized zsh and fish benchmarked side-by-side, user decision recorded, switch wired declaratively (kitty.conf `shell fish`, install.sh PACMAN_PKGS, stow.sh PACKAGES) with zshell retained as fallback and no chsh added (04-04-PLAN.md must_haves) | ✓ VERIFIED | Unchanged by 04-06. |
| 8 | If fish is selected, fish reaches day-one parity: vendored oh-my-posh prompt, fzf, zoxide, trimmed fastfetch greeting, working node tooling (04-04-PLAN.md must_have, D-10, closed by 04-05) | ✓ VERIFIED (gap closed, prior phase) | Unchanged by 04-06 (which touched only hyprlock.conf, not fish/config.fish or install.sh). Previously re-verified live: clean-env probe reports `NODE=YES`, `node v24.18.0`, `npm`/`npx 11.16.0`. Confirmed again via 04-UAT.md's "New-kitty-window fish smoke check" (`pass`). Fresh 04-REVIEW.md (`2107bc6`) independently re-confirms the fix is genuinely closed via nvm.fish plugin-guard analysis. |

**Score:** 6/8 truths verified (2 present + wired + schema-verified but behaviorally unverified pending human reliability tests, 0 failed)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `hypr/.config/hypr/hyprlock.conf` | `general:ignore_empty_input = true` in `general{}`; non-empty `input-field:check_text` in `input-field{}` | ✓ VERIFIED | Direct read confirms both directives present exactly as committed (`520f6a7`, `069c2ab`). Both automated verify commands from 04-06-PLAN.md re-run independently on this pass and both print PASS: config-presence grep + `strings /usr/bin/hyprlock` schema cross-check for `general:ignore_empty_input` and `check_text`. |
| `wlogout/.config/wlogout/layout` | uwsm-correct Shutdown/Reboot actions, all 6 labels/keybinds intact | ✓ VERIFIED (regression check) | Re-confirmed unchanged since initial verification; not touched by 04-06. |
| `hypr/.config/hypr/scripts/powermenu.sh` | Same class fix as layout | ✓ VERIFIED (regression check) | Re-confirmed unchanged. Fresh 04-REVIEW.md's IN-01 notes this script has no live call site (the real power-menu path is `wlogout.sh` → the layout file above) — an info-level maintenance observation, not a defect in the fix itself. |
| `install.sh` (rsync/hyprshutdown/fish entries + Node provisioning doc) | rsync + hyprshutdown + fish in PACMAN_PKGS; nvm install doc step | ✓ VERIFIED (regression check) | Re-confirmed unchanged; not touched by 04-06. |
| `fish/.config/fish/config.fish` | Guarded `nvm use --silent` activation block | ✓ VERIFIED (regression check) | Re-confirmed unchanged; not touched by 04-06. |
| `stow.sh` | fish added to PACKAGES, zshell retained, chsh unchanged | ✓ VERIFIED (regression check) | Re-confirmed unchanged. |
| `kitty/.config/kitty/kitty.conf` | `shell fish` directive, rendering knobs untouched | ✓ VERIFIED (regression check) | Re-confirmed unchanged. |
| `.planning/phases/04-reliability-fixes-tech-debt/04-06-SUMMARY.md` | Gap-closure summary with schema-verification evidence | ✓ VERIFIED | Exists, contains task commits (`520f6a7`, `069c2ab`), coverage table with D1/D2/D3 mapped to FIX-02, self-check PASSED. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `hyprlock.conf` `general{}` `ignore_empty_input = true` | ENTER-on-empty submit path | Hyprlock's own PAM-round-start gate (schema-registered option, confirmed via `strings /usr/bin/hyprlock`) | ✓ WIRED | Option confirmed present in both the config file and the installed binary's schema — the option name is registered, so it is not silently ignored (the exact 04-02 failure class this plan explicitly guarded against). Runtime effect (does the ENTER-first path actually stop dropping keystrokes) is the pending D-23 human item. |
| `hyprlock.conf` `input-field{}` `check_text = <i>Checking...</i>` | In-flight PAM verification visual cue | Schema-registered option (confirmed via `strings /usr/bin/hyprlock`; sample config at `/usr/share/hypr/hyprlock.conf` ships it commented) | ✓ WIRED | Config-present and schema-verified. Visual rendering confirmation is the optional D-23 cue-check human item. |
| wlogout layout action string | uwsm/hyprshutdown session teardown | `hyprshutdown --post-cmd 'systemctl poweroff\|reboot'` | ⚠️ PARTIAL | Unchanged since initial verification — config wired correctly; D-22 hardware test result already recorded `pass` in 04-UAT.md but retained as a formal end-of-phase item. |
| `install.sh` PACMAN_PKGS `fish` | `stow.sh` PACKAGES `fish` | `fish/.config/fish/config.fish` | ✓ WIRED | Unchanged since initial verification. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| `ignore_empty_input` present in config and registered in the installed hyprlock 0.9.5 binary schema | `grep -Eq '^[[:space:]]*ignore_empty_input[[:space:]]*=[[:space:]]*true' hyprlock.conf && strings /usr/bin/hyprlock \| grep -qx 'general:ignore_empty_input'` | Both conditions true | ✓ PASS |
| `check_text` present in config and registered in the installed hyprlock 0.9.5 binary schema | `grep -Eq '^[[:space:]]*check_text[[:space:]]*=[[:space:]]*.+' hyprlock.conf && strings /usr/bin/hyprlock \| grep -qw 'check_text'` | Both conditions true | ✓ PASS |
| No unrelated directive changed by the gap-closure commits | `git diff bc2911b..HEAD -- hypr/.config/hypr/hyprlock.conf` | Only the two new directives (plus explanatory comments) present in the diff — no color/font/size/animation/background change | ✓ PASS |
| Symlink deployment intact (repo edit reaches the live config) | `readlink -f ~/.config/hypr/hyprlock.conf` | Resolves to `hypr/.config/hypr/hyprlock.conf` in this repo | ✓ PASS |
| No new debt markers introduced in the touched file | `grep -n -E "TBD\|FIXME\|XXX\|TODO\|HACK\|PLACEHOLDER" hypr/.config/hypr/hyprlock.conf` | No matches | ✓ PASS |
| hyprlock binary version matches the schema this plan validated against | `hyprlock --version` | `Hyprlock version v0.9.5` | ✓ PASS |

Note: consistent with 04-06-PLAN.md's own verification section, no live hyprlock parse/lock-session test was run here — hyprlock has no non-locking config-validation flag, so the binary-schema cross-check above is the deterministic substitute. Actual runtime behavior is exercised only by the deferred D-23 human protocol.

### Probe Execution

| Probe | Command | Result | Status |
|-------|---------|--------|--------|
| `verify/container-run.sh` (D-24 container gate) | `bash verify/container-run.sh` | NOT RUN by this verifier — precondition unmet: `git status -sb` shows local `main` is 10 commits ahead of `origin/main` (unpushed). 04-UAT.md separately records a human "pass" for this item from a prior session; this verifier does not re-run network/container probes. | SKIPPED (documented precondition unmet for this pass; see human_verification) |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|--------------|--------|----------|
| FIX-01 | 04-01 | wlogout shutdown hang root-caused and fixed | ⚠️ PARTIAL | Diagnosis + class fix present and wired, unchanged by 04-06. 04-UAT.md's D-22 test already recorded `pass`; retained as a formal end-of-phase human sign-off item per the phase's `human_verify_mode: end-of-phase` setting rather than a live defect. |
| FIX-02 | 04-02, 04-06 | Hyprlock first-keystroke drop root-caused and fixed | ⚠️ PARTIAL (gap closed at code level) | UAT-identified ENTER-first gap closed by 04-06: `ignore_empty_input`/`check_text` added, schema-verified, scope-clean diff. The 100%-first-try claim across all 10 trials (specifically re-covering the previously-failing ENTER-first path) has not yet been re-run against the new config — this is the phase's primary remaining gating item. |
| FIX-03 | 04-03, 04-04, 04-05 | Kitty/shell startup fast, profiled before/after; fish day-one parity including node tooling | ✓ SATISFIED | Unchanged, independently confirmed by prior verification pass plus 04-UAT.md's `pass` result. |
| DEBT-01 | 04-01 | rsync explicit in install.sh PACMAN_PKGS | ✓ SATISFIED | Confirmed present and gated (regression check). |

No orphaned requirements — all four IDs declared across the six plans (04-01 through 04-06) match REQUIREMENTS.md's Phase 4 traceability row exactly. REQUIREMENTS.md marks all four of FIX-01/FIX-02/FIX-03/DEBT-01 as `[x]` complete and the traceability table as "Complete" — this verification does not dispute that the code-level work is done, but the phase's own `human_verify_mode: end-of-phase` setting means the FIX-01/FIX-02 reliability claims are not fully closed until D-22/D-23 (re-)run and pass, most importantly a fresh D-23 pass that specifically exercises the ENTER-first variant against the 04-06 fix.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `fish/.config/fish/config.fish:46` | 46 | Fisher bootstrap `curl -sL ... \| source` has no `--fail`/`-f` (04-REVIEW.md WR-01, renumbered from prior WR-04, carried forward) | ⚠️ Warning | Pre-existing, unchanged by 04-06. |
| `fish/.config/fish/config.fish:58-59` | 58-59 | `nvm use --silent` prints an unguarded stderr error on every shell start until `nvm install v24.18.0` is run (04-REVIEW.md WR-02, carried forward, previously WR-04) | ⚠️ Warning | Cosmetic/self-resolving; unchanged by 04-06. |
| `zshell/.zshrc:123` | 123 | Unguarded `source` of uv env file (04-REVIEW.md WR-03, carried forward) | ⚠️ Warning | Pre-existing, unrelated to FIX-02. |
| `hypr/.config/hypr/scripts/powermenu.sh:16`, `wlogout/.config/wlogout/layout` | 16 | Logout path not wrapped in the same graceful-teardown treatment as Shutdown/Reboot (04-REVIEW.md WR-04, new finding, out of FIX-01/02 scope) | ⚠️ Warning | Design gap noted by the reviewer; not part of this phase's stated FIX-01/FIX-02 scope (Logout is not a Shutdown/Reboot hang per the diagnosed root cause) — does not block this verification. |
| `hypr/.config/hypr/scripts/powermenu.sh` | whole file | No call site anywhere in the repo — the live power-menu path is `wlogout.sh`/the layout file, which independently carries the same `hyprshutdown` fix (04-REVIEW.md IN-01) | ℹ️ Info | Does not affect FIX-01's actual live behavior (the layout file is what's wired to the keybind), but the duplicated, unreachable script should eventually be wired or removed. |
| `hypr/.config/hypr/hyprlock.conf:100` | 100 | `placeholder_text` hardcodes a catppuccin hex color instead of a theme variable (04-REVIEW.md IN-06) | ℹ️ Info | Pre-existing, unrelated to FIX-02's ENTER-first gap; unchanged by 04-06 (which only touched `general{}` and `check_text` in `input-field{}`). |
| various (IN-02, IN-03, IN-04, IN-05, IN-07) | — | Dead config, typos, and a remapped Ctrl+C — all pre-existing/out-of-scope per 04-REVIEW.md | ℹ️ Info | Not related to FIX-01/FIX-02/FIX-03/DEBT-01; no action required for this phase's closure. |

No 🛑 Blockers found. No unresolved `TBD`/`FIXME`/`XXX` debt markers in `hyprlock.conf` (the only file touched by 04-06) — confirmed by direct grep on this run. `git diff bc2911b..HEAD -- hypr/.config/hypr/hyprlock.conf` independently confirms the change is scoped to exactly the two intended directives plus explanatory comments.

### Human Verification Required

The FIX-02 UAT gap (ENTER-first input drop) is closed at the config/schema level, so the phase is no longer `gaps_found`. The following items remain pending under the phase's own `human_verify_mode: end-of-phase` setting and gate final sign-off (status is `human_needed`, not `passed`):

1. **D-22: wlogout 5-cycle shutdown/reboot reliability test**
   - **Test:** From the wlogout menu, perform 5 consecutive real cycles alternating keyboard/mouse selection and Shutdown/Reboot. After each boot, grep `journalctl -b -1` for teardown-timeout signatures.
   - **Expected:** 5/5 clean cycles, no black-screen hang, no `stop-sigterm timed out` / `nvidia_drm` failure lines.
   - **Why human:** Requires physically power-cycling real hardware across multiple boots. Note: 04-UAT.md already recorded this `pass` in the human UAT session on 2026-07-11 — retained here for the formal end-of-phase checklist, not because new doubt exists.

2. **D-23: hyprlock 10-trial lock-and-type reliability re-test (post-04-06)**
   - **Test:** With a second TTY logged in, perform ~10 lock→type trials across both the manual-lock keybind and the idle-lock (`loginctl lock-session`) path, explicitly mixing ENTER-first and type-immediately variants. Optionally submit one deliberately-wrong password and confirm the `check_text` "Checking..." cue is visible.
   - **Expected:** 100% first-try unlock across all variants and paths, no dropped first character, no failed-auth loop — specifically including the ENTER-first case that previously failed in UAT.
   - **Why human:** Requires physically locking the real session and typing a password immediately, repeated across two trigger paths and two entry variants — a real-time input/PAM-timing race that cannot be captured by static analysis. This is the direct re-test of the gap 04-06 closed at the config level and has not yet been re-run.

3. **D-24: container-gate rerun (`verify/container-run.sh`)**
   - **Test:** Push this phase's commits to `origin/main`, then run `verify/container-run.sh` from the repo root.
   - **Expected:** Clean clone → `install.sh --core-only` → `stow.sh` → theme-parity all pass; `summary.log` records `overall=PASS`.
   - **Why human:** Requires a `git push` decision and a real container/network round-trip. Local branch is 10 commits ahead of `origin/main` (unpushed) as of this re-verification.

4. **New-kitty-window fish smoke check**
   - **Test:** Open a new kitty window in normal daily use and observe the fastfetch greeting + oh-my-posh prompt + node tooling.
   - **Expected:** Fast, clean startup with a working prompt and node/npm/npx available.
   - **Why human/low-value:** Already independently reproduced live in a prior verification pass and confirmed `pass` in 04-UAT.md. Retained for end-of-phase checklist completeness.

### Gaps Summary

**No gaps remain.** The UAT-reported gap (Test 2: ENTER-first-then-type on hyprlock caused a failed-auth loop with zero registered keystrokes, root-caused as a PAM-round started by an unset `ignore_empty_input` default) was closed by gap-closure plan 04-06 (commits `520f6a7`, `069c2ab`). Both added options (`general:ignore_empty_input = true`, `input-field:check_text`) are independently re-confirmed on this verification pass to be:
- present in `hypr/.config/hypr/hyprlock.conf` exactly as committed,
- registered in the installed hyprlock 0.9.5 binary's schema (`strings /usr/bin/hyprlock`), ruling out the silent-rejection failure mode that caused the original 04-02 gap,
- scoped precisely — `git diff` shows no other directive changed,
- deployed live via the existing stow symlink.

The fresh post-04-06 `04-REVIEW.md` (commit `2107bc6`) independently corroborates the fix is sound, and surfaces one new non-blocking design observation (WR-04: Logout not given the same graceful-teardown wrapper as Shutdown/Reboot) that is explicitly out of this phase's diagnosed FIX-01/FIX-02 scope.

What remains is the phase's own deliberately-deferred human reliability confirmation: the D-23 10-trial protocol has not yet been re-run against the new hyprlock config, and this re-run — specifically re-exercising the previously-failing ENTER-first variant — is the phase's primary remaining gating item before FIX-02 (and the phase as a whole) can be marked fully `passed`. D-22 and the fish smoke check already have recorded human `pass` results in 04-UAT.md but are retained on the checklist per the phase's `human_verify_mode: end-of-phase` policy. D-24 remains blocked on an unpushed branch.

---

*Verified: 2026-07-11T22:05:00Z*
*Verifier: Claude (gsd-verifier)*
