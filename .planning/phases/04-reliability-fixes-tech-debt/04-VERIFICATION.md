---
phase: 04-reliability-fixes-tech-debt
verified: 2026-07-11T21:10:00Z
status: human_needed
score: 6/8 must-haves verified
behavior_unverified: 2 # SC1 (wlogout reliability) and SC2 (hyprlock keystroke reliability) — fix code present + wired, D-22/D-23 runtime reliability tests still pending (human_verify_mode: end-of-phase); unchanged since initial verification
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 5/8
  gaps_closed:
    - "If fish is selected, fish reaches day-one parity: working node tooling (04-04-PLAN.md must_have, D-10) — CR-01 closed by gap-closure plan 04-05 (commits a9d9653, 58b672d, 3f8f30e)"
  gaps_remaining: []
  regressions: []
gaps: []
deferred: []
behavior_unverified_items:
  - truth: "Selecting Shutdown/Reboot from wlogout (or the walker power menu) completes every time with no blank-screen hang (ROADMAP SC1 / D-22 5-cycle protocol)"
    test: "Run the D-22 protocol: 5 consecutive real Shutdown/Reboot cycles from wlogout, alternating keyboard and mouse selection. After each boot, grep `journalctl -b -1` for stop-sigterm/timed-out/nvidia_drm/failed lines."
    expected: "All 5 cycles power off/reboot cleanly with no black-screen hang and no teardown-timeout journal errors."
    why_human: "Requires physically triggering real shutdown/reboot cycles and observing hardware behavior across multiple boots — cannot be simulated or grepped from static config. 04-REVIEW.md's WR-01 (carried forward, unchanged by the 04-05 gap-closure work) raises an unresolved theoretical risk that hyprshutdown's forked process does not escape the uwsm session cgroup, so systemd tearing down the session on Hyprland exit could race and kill hyprshutdown before its --post-cmd runs — the fix's code is present and wired, but survival under real uwsm teardown has not been demonstrated on this hardware."
  - truth: "After lock screen activation, the first keystrokes register — password typed in one attempt, no dropped-input failed-auth loop, 100% across 10 trials covering both manual-lock and idle-lock paths (ROADMAP SC2 / D-23 protocol)"
    test: "Run the D-23 protocol: ~10 lock-then-immediately-type trials across both the manual lock keybind and the idle-lock (loginctl lock-session) path, with a second TTY logged in first per the lockout-recovery procedure."
    expected: "100% first-try unlock across all 10 trials, no dropped first characters, no failed-auth loop."
    why_human: "Requires physically locking the real graphical session and typing a password immediately, repeated across two trigger paths — a real-time keyboard-focus race that cannot be reproduced by static analysis. Unchanged since initial verification; the applied mitigation (immediate_render + animation fadeIn,0) shrinks the startup window in which keystrokes are lost but does not structurally guarantee zero loss."
human_verification:
  - test: "D-22: wlogout 5-cycle shutdown/reboot reliability test — from the wlogout menu, perform 5 consecutive real cycles alternating keyboard/mouse selection and Shutdown/Reboot. After each boot, grep journalctl -b -1 for teardown-timeout signatures."
    expected: "5/5 clean cycles, no black-screen hang, no 'stop-sigterm timed out' / nvidia_drm failure lines."
    why_human: "Requires physically power-cycling real hardware across multiple boots; also settles WR-01's open question of whether hyprshutdown actually survives uwsm's session-cgroup teardown."
  - test: "D-23: hyprlock 10-trial lock-and-type reliability test — with a second TTY logged in, perform ~10 lock-then-immediately-type trials across both the manual-lock keybind and the idle-lock (loginctl lock-session) path."
    expected: "100% first-try unlock, no dropped first character, no failed-auth loop."
    why_human: "Requires physically locking the real session and typing a password immediately, repeated across two trigger paths — a real-time input race that cannot be captured by static analysis."
  - test: "D-24: container-gate rerun (verify/container-run.sh) — push this phase's commits to origin/main, then run verify/container-run.sh from the repo root."
    expected: "Clean clone -> install.sh --core-only -> stow.sh -> theme-parity all pass; summary.log records overall=PASS."
    why_human: "Requires a git push decision and a real container/network round-trip. Local branch is still 37 commits ahead of origin/main (unpushed) as of this re-verification — the precondition remains legitimately unmet, same as the initial verification run."
  - test: "New-kitty-window fish smoke check — open a new kitty window in normal daily use and observe the fastfetch greeting + oh-my-posh prompt + node tooling."
    expected: "Fast, clean startup with a working prompt and node/npm/npx available."
    why_human: "Low-value reconfirmation — this verification already independently reproduced the fix live (NODE=YES, node v24.18.0, npm/npx 11.16.0) via the exact clean-env probe. Kept for completeness of the end-of-phase human checklist, not because new information is expected."
---

# Phase 4: Reliability Fixes & Tech Debt Verification Report

**Phase Goal:** The three known reliability/performance defects are root-caused and fixed, and the v1 tech-debt carry-over is closed — de-risking the base before any redesign layers on top.
**Verified:** 2026-07-11T21:10:00Z
**Status:** human_needed
**Re-verification:** Yes — after gap closure (plan 04-05, commits a9d9653, 58b672d, 3f8f30e)

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Shutdown/Reboot from wlogout complete every time with no blank-screen hang; root cause diagnosed and documented, not patched around (ROADMAP SC1 / FIX-01) | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Unchanged since initial verification. `wlogout/.config/wlogout/layout` and `hypr/.config/hypr/scripts/powermenu.sh` re-confirmed on this run to still use `hyprshutdown --post-cmd 'systemctl poweroff\|reboot'` for Shutdown/Reboot (direct read). D-22 5-cycle hardware test remains pending; 04-REVIEW.md's WR-01 (uwsm session-cgroup teardown race) is unresolved and explicitly carried forward in the post-gap-closure re-review (f6463e7). |
| 2 | After lock activation, the very first keystrokes register — password typed in one attempt, no dropped-input failed-auth loop (ROADMAP SC2 / FIX-02) | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Unchanged since initial verification. `hypr/.config/hypr/hyprlock.conf` re-confirmed to carry `immediate_render = true` and `animation = fadeIn, 0`. D-23 10-trial lock-and-type reliability protocol remains pending. |
| 3 | Opening a new kitty terminal feels instant — startup profiled before/after, regression gone (ROADMAP SC3 / FIX-03) | ✓ VERIFIED | Quick regression check: `kitty/.config/kitty/kitty.conf` still has `shell fish` (line 9); the fish/zsh startup optimizations (lazy nvm in zsh, vendored oh-my-posh, fish adoption) are unchanged by the gap-closure plan, which touched only config.fish's interactive block and one install.sh doc line. Independently re-measured in the initial verification pass (97.4ms zsh / 33.9ms fish vs. 641ms pre-fix baseline); this run's addition (an `if`-guarded `nvm use --silent` call in an already-interactive block) is a negligible, one-shot cost and does not reintroduce the original blocking synchronous network-init regression. |
| 4 | A fresh install.sh run installs rsync explicitly (listed in PACMAN_PKGS) (ROADMAP SC4 / DEBT-01) | ✓ VERIFIED | Quick regression check: `install.sh` PACMAN_PKGS still contains an uncommented `rsync` line (line 90), flowing through the `verify_packages` hard-fail gate. Untouched by the gap-closure plan. |
| 5 | All six wlogout actions audited against the uwsm session model; shutdown/reboot no longer bare `systemctl` (04-01-PLAN.md must_have) | ✓ VERIFIED | Quick regression check: direct read confirms Lock=`uwsm app -- hyprlock`, Logout=`uwsm stop`, Suspend/Hibernate=bare `systemctl` (intentional per D-14), Shutdown/Reboot=`hyprshutdown --post-cmd ...`. Unchanged. |
| 6 | Lockout-recovery procedure (second TTY + `pkill hyprlock`) written before any hyprlock test (04-02-PLAN.md must_have, D-20) | ✓ VERIFIED | Quick regression check: 04-02-SUMMARY.md still contains the documented procedure. Unchanged, not touched by gap-closure plan. |
| 7 | Optimized zsh and fish benchmarked side-by-side, user decision recorded, switch wired declaratively (kitty.conf `shell fish`, install.sh PACMAN_PKGS, stow.sh PACKAGES) with zshell retained as fallback and no chsh added (04-04-PLAN.md must_haves) | ✓ VERIFIED | Quick regression check: `kitty.conf` `shell fish` present; `install.sh` still lists `fish` under `# Shell` PACMAN_PKGS; `stow.sh` PACKAGES still includes both `fish` and `gtk`/etc. with `zshell` retained; `git grep chsh` still shows only the pre-existing zsh chsh line. Unchanged. |
| 8 | If fish is selected, fish reaches day-one parity: vendored oh-my-posh prompt, fzf, zoxide, trimmed fastfetch greeting, **working node tooling** (04-04-PLAN.md must_have, D-10) | ✓ VERIFIED (gap closed) | **Re-verified live in this session** — the previously-failing clean-env probe now passes: `env -i HOME="$HOME" USER="$USER" TERM=xterm PATH=/usr/bin:/bin fish -i -c 'type -q node; and echo NODE=YES; or echo NODE=NO'` → `NODE=YES` (was `NODE=NO`). Extended probe confirms `$nvm_current_version` = `v24.18.0`, and `node --version` / `npm --version` / `npx --version` all report `v24.18.0` / `11.16.0` / `11.16.0` respectively. `fish/.config/fish/config.fish` lines 50-60 confirmed to contain the guarded `if not set -q nvm_current_version; and functions -q nvm` block calling `nvm use --silent $nvm_default_version`, exactly as committed in `a9d9653`. `fish -n config.fish` and `bash -n install.sh` both exit 0. Prompt/fzf/zoxide/fastfetch parity items remain present and correctly wired (unchanged from initial verification). |

**Score:** 6/8 truths verified (2 present + wired but behaviorally unverified pending human reliability tests, 0 failed)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `fish/.config/fish/config.fish` | Explicit guarded `nvm use --silent` activation block; corrected comment | ✓ VERIFIED | Direct read: lines 18-26 comment rewritten to accurately describe conf.d-before-config.fish ordering; lines 50-60 add the guarded activation block exactly as specified in 04-05-PLAN.md's acceptance criteria. `fish -n` exits 0. Node tooling now functional (see Truth 8). |
| `install.sh` | Documents one-time `nvm install v24.18.0` provisioning step | ✓ VERIFIED | Direct read: lines 410-415 "Next steps" block now includes a numbered step 2 with the literal string `nvm install v24.18.0`; subsequent steps renumbered. `bash -n install.sh` exits 0. `git diff` confirms only added echo lines — no new PACMAN_PKGS/AUR_PKGS/functions/network calls. |
| `.planning/phases/04-reliability-fixes-tech-debt/04-05-SUMMARY.md` | Gap-closure summary with before/after probe evidence | ✓ VERIFIED | Exists, contains before (`NODE=NO`) / after (`NODE=YES`, `v24.18.0`) evidence, task commits (`a9d9653`, `58b672d`), self-check PASSED. |
| `wlogout/.config/wlogout/layout` | uwsm-correct Shutdown/Reboot actions, all 6 labels/keybinds intact | ✓ VERIFIED (regression check) | Re-confirmed unchanged since initial verification. |
| `hypr/.config/hypr/scripts/powermenu.sh` | Same class fix as layout | ✓ VERIFIED (regression check) | Re-confirmed unchanged. |
| `hypr/.config/hypr/hyprlock.conf` | grace-related dead options removed, immediate_render + fadeIn=0 added | ✓ VERIFIED (regression check) | Re-confirmed unchanged. |
| `install.sh` (rsync/hyprshutdown/fish entries) | rsync + hyprshutdown + fish in PACMAN_PKGS | ✓ VERIFIED (regression check) | Re-confirmed unchanged, plus the new Node-provisioning doc line. |
| `stow.sh` | fish added to PACKAGES, zshell retained, chsh unchanged | ✓ VERIFIED (regression check) | Re-confirmed unchanged. |
| `kitty/.config/kitty/kitty.conf` | `shell fish` directive, rendering knobs untouched | ✓ VERIFIED (regression check) | Re-confirmed unchanged. |
| `zshell/.zshrc` | Local oh-my-posh, lazy nvm/bun | ✓ VERIFIED (regression check) | Untouched by gap-closure plan. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `config.fish` `nvm_default_version` (v24.18.0) | Explicit `nvm use --silent` activation | `status is-interactive` block, guarded by `functions -q nvm` + `not set -q nvm_current_version` | ✓ WIRED | Live probe end-to-end confirms: variable set at line 28 → guarded activation at lines 58-60 → `node`/`npm`/`npx` on PATH in a clean-env shell. |
| `install.sh` "Next steps" output | `nvm install v24.18.0` documented step | Literal string in echo block | ✓ WIRED | Confirmed present; corresponding `~/.config/nvm/versions/node/v24.18.0` directory verified to exist on this machine (the provisioning target the doc line describes). |
| wlogout layout action string | uwsm/hyprshutdown session teardown | `hyprshutdown --post-cmd 'systemctl poweroff\|reboot'` | ⚠️ PARTIAL | Unchanged since initial verification — config wired correctly, runtime survival under uwsm teardown is WR-01's still-open concern, D-22 test still pending. |
| `hyprlock.conf` `general{}` | PAM auth keystroke input path | `immediate_render` + `animation fadeIn,0` | ⚠️ PARTIAL | Unchanged — config wired correctly, D-23 test still pending. |
| `install.sh` PACMAN_PKGS `fish` | `stow.sh` PACKAGES `fish` | `fish/.config/fish/config.fish` | ✓ WIRED | Unchanged since initial verification. |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| fish provides working node tooling on a fresh interactive shell (D-10 parity claim, CR-01 fix) | `env -i HOME="$HOME" USER="$USER" TERM=xterm PATH=/usr/bin:/bin fish -i -c 'type -q node; and echo NODE=YES; or echo NODE=NO'` | `NODE=YES` (was `NODE=NO` before the fix) | ✓ PASS |
| nvm auto-activates the pinned default version | `env -i HOME="$HOME" ... fish -i -c 'echo $nvm_current_version'` | `v24.18.0` | ✓ PASS |
| node/npm/npx binaries actually run, not just `type -q` | `env -i HOME="$HOME" ... fish -i -c 'node --version; npm --version; npx --version'` | `v24.18.0` / `11.16.0` / `11.16.0` | ✓ PASS |
| fish and install.sh configs remain syntactically valid after the gap-closure edits | `fish -n fish/.config/fish/config.fish && bash -n install.sh` | Both exit 0 | ✓ PASS |
| No new debt markers introduced in the two touched files | `grep -n -E "TBD\|FIXME\|XXX\|TODO\|HACK\|PLACEHOLDER" fish/.config/fish/config.fish install.sh` | No matches | ✓ PASS |

### Probe Execution

| Probe | Command | Result | Status |
|-------|---------|--------|--------|
| `verify/container-run.sh` (D-24 container gate) | `bash verify/container-run.sh` | NOT RUN — precondition still unmet: `git status -sb` shows local `main` is 37 commits ahead of `origin/main` (unpushed). Same legitimately-deferred precondition as the initial verification run; unchanged by the gap-closure plan. | SKIPPED (documented precondition unmet) |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|--------------|--------|----------|
| FIX-01 | 04-01 | wlogout shutdown hang root-caused and fixed | ⚠️ PARTIAL | Diagnosis + class fix present and wired; D-22 5-cycle reliability confirmation and WR-01's uwsm-cgroup-survival concern remain open (unchanged since initial verification). |
| FIX-02 | 04-02 | Hyprlock first-keystroke drop root-caused and fixed | ⚠️ PARTIAL | Diagnosis + mitigation present and wired; D-23 10-trial reliability confirmation remains open (unchanged). |
| FIX-03 | 04-03, 04-04, 04-05 | Kitty/shell startup fast, profiled before/after; fish day-one parity including node tooling | ✓ SATISFIED | Startup regression conclusively eliminated (previously verified); the fish node-tooling parity gap (CR-01) is now closed and independently re-verified live in this session. |
| DEBT-01 | 04-01 | rsync explicit in install.sh PACMAN_PKGS | ✓ SATISFIED | Confirmed present and gated (regression check). |

No orphaned requirements — all four IDs declared across the five plans (04-01 through 04-05) match REQUIREMENTS.md's Phase 4 traceability row exactly.

**Note:** REQUIREMENTS.md marks all four of FIX-01/FIX-02/FIX-03/DEBT-01 as `[x]` complete and the traceability table as "Complete." This verification independently confirms DEBT-01 and (now, post-gap-closure) FIX-03 as fully satisfied. FIX-01 and FIX-02 still have their core reliability claims ("completes every time" / "100% first-try") resting on pending human hardware tests (D-22/D-23) that the phase's own `human_verify_mode: end-of-phase` setting deliberately defers — this is expected process, not a defect, and should not be read as a silent downgrade of the checkbox state, but the phase is not fully closed until those two human tests run.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `wlogout/.config/wlogout/layout`, `hypr/.config/hypr/scripts/powermenu.sh` | action strings | Unverified survival of `hyprshutdown` under uwsm session-cgroup teardown (WR-01, carried forward) | ⚠️ Warning | The exact failure class FIX-01 targeted could still occur under load; only the pending D-22 hardware test settles it. Unchanged since initial verification. |
| `fish/.config/fish/config.fish` | 58-60 | New finding (04-REVIEW.md WR-04, surfaced by the 04-05 re-review): `nvm use --silent` only suppresses the success-path stdout message — the not-installed error path is unguarded stderr. On a genuinely fresh machine, between running `install.sh`/`stow.sh` and running the documented one-time `nvm install v24.18.0` step, every interactive fish shell prints `nvm: Can't use Node "v24.18.0", version must be installed first` to stderr (possibly twice on the very first shell, per the reviewer's fisher-bootstrap-timing analysis) | ⚠️ Warning | Cosmetic/self-resolving — disappears permanently once the documented provisioning step is run — but degrades the fresh-install first impression this phase targeted, and reads like a broken config rather than a pending setup step. Does not affect this already-provisioned machine (confirmed `NODE=YES` above) and does not violate 04-05-PLAN.md's literal must-have wording ("no-op when nvm.fish is absent or a version is already active" — the not-yet-installed case was not one of the two enumerated no-op conditions). Reviewer's suggested fix (`test -d $nvm_data/$nvm_default_version` guard) is a good candidate for a small follow-up but is not required to close CR-01 as scoped. |
| `zshell/.zshrc` | 123 | `. "$HOME/.local/share/../bin/env"` has no existence guard; `install.sh` never installs `uv` (carried forward) | ⚠️ Warning | Pre-existing, not introduced by this phase or the gap-closure plan. |
| `fish/.config/fish/config.fish` | 46 | `curl -sL ... \| source` (fisher bootstrap) has no `--fail`/`-f` (carried forward) | ⚠️ Warning | Unchanged since initial verification. |
| `install.sh` | PACMAN_PKGS | `neovim` never installed despite `alias vim nvim` in both shells (carried forward) | ℹ️ Info | Pre-existing. |
| `zshell/.zshrc` | 60 | `HISTDUP=erase` is not a real zsh option (no-op) (carried forward) | ℹ️ Info | Cosmetic. |

No 🛑 Blockers found. No unresolved `TBD`/`FIXME`/`XXX` debt markers in the two files touched by this gap-closure plan (`fish/.config/fish/config.fish`, `install.sh`) — confirmed by direct grep. All items above were independently confirmed by direct file reads and live probes during this re-verification, cross-checked against the post-gap-closure `04-REVIEW.md` (commit `f6463e7`).

### Human Verification Required

The CR-01 gap is closed, so the phase is no longer `gaps_found`. The following items remain pending under the phase's own `human_verify_mode: end-of-phase` setting and now gate final sign-off (status is `human_needed`, not `passed`):

1. **D-22: wlogout 5-cycle shutdown/reboot reliability test**
   - **Test:** From the wlogout menu, perform 5 consecutive real cycles alternating keyboard/mouse selection and Shutdown/Reboot. After each boot, grep `journalctl -b -1` for teardown-timeout signatures.
   - **Expected:** 5/5 clean cycles, no black-screen hang, no `stop-sigterm timed out` / `nvidia_drm` failure lines.
   - **Why human:** Requires physically power-cycling real hardware across multiple boots; also settles WR-01's open question of whether `hyprshutdown` actually survives uwsm's session-cgroup teardown.

2. **D-23: hyprlock 10-trial lock-and-type reliability test**
   - **Test:** With a second TTY logged in, perform ~10 lock→immediately-type trials across both the manual-lock keybind and the idle-lock (`loginctl lock-session`) path.
   - **Expected:** 100% first-try unlock, no dropped first character, no failed-auth loop.
   - **Why human:** Requires physically locking the real session and typing a password immediately, repeated across two trigger paths — a real-time input race that cannot be captured by static analysis.

3. **D-24: container-gate rerun (`verify/container-run.sh`)**
   - **Test:** Push this phase's commits to `origin/main`, then run `verify/container-run.sh` from the repo root.
   - **Expected:** Clean clone → `install.sh --core-only` → `stow.sh` → theme-parity all pass; `summary.log` records `overall=PASS`.
   - **Why human:** Requires a `git push` decision and a real container/network round-trip. Local branch is 37 commits ahead of `origin/main` (unpushed) as of this re-verification — same legitimately-deferred precondition as the initial run.

4. **New-kitty-window fish smoke check**
   - **Test:** Open a new kitty window in normal daily use and observe the fastfetch greeting + oh-my-posh prompt + node tooling.
   - **Expected:** Fast, clean startup with a working prompt and node/npm/npx available.
   - **Why human/low-value:** This verification already independently reproduced the fix live via the exact clean-env probe (`NODE=YES`, `node v24.18.0`, `npm`/`npx 11.16.0`). Retained for the end-of-phase checklist's completeness, not because new information is expected.

### Gaps Summary

**No gaps remain.** The single gap identified in the initial verification (CR-01: fish never activated the default Node version because `conf.d/nvm.fish`'s auto-activation guard runs before `config.fish` sets `nvm_default_version`) was closed by gap-closure plan 04-05 (commits `a9d9653`, `58b672d`, `3f8f30e`) and is independently re-verified live in this session: a clean-environment fish shell now reports `NODE=YES`, `nvm_current_version=v24.18.0`, and functional `node`/`npm`/`npx` binaries — the exact reproduction that previously failed now passes.

The re-review that followed the gap closure (04-REVIEW.md, commit `f6463e7`) surfaced one new non-blocking Warning (WR-04): on a genuinely fresh machine, before the documented `nvm install v24.18.0` step is run, every interactive fish shell prints an stderr error from `nvm use --silent` because `--silent` only suppresses the success message, not the not-installed error. This is cosmetic and self-resolving (disappears permanently once the one-time provisioning step is run), does not affect this already-provisioned machine, and does not violate 04-05-PLAN.md's literal must-have wording — it is recorded above as a Warning anti-pattern for potential future cleanup, not as a blocking gap.

FIX-03 and DEBT-01 are now both fully satisfied and independently confirmed. FIX-01 and FIX-02's root-cause diagnosis and code fixes remain solid and correctly wired, but their core reliability claims ("completes every time" / "100% first-try, 10/10") still rest on the phase's own deliberately-deferred D-22/D-23 hardware reliability tests, plus the D-24 container-gate rerun once commits are pushed. These are the phase's remaining human-verification items, not defects — status is `human_needed`.

---

*Verified: 2026-07-11T21:10:00Z*
*Verifier: Claude (gsd-verifier)*
