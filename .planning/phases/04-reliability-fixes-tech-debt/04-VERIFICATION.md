---
phase: 04-reliability-fixes-tech-debt
verified: 2026-07-11T19:58:00Z
status: gaps_found
score: 5/8 must-haves verified
behavior_unverified: 2 # SC1 (wlogout reliability) and SC2 (hyprlock keystroke reliability) — fix code present + wired, but the D-22/D-23 runtime reliability tests are still pending (human_verify_mode: end-of-phase)
overrides_applied: 0
gaps:
  - truth: "If fish is selected, fish reaches day-one parity: working node tooling (04-04-PLAN.md must_have, D-10)"
    status: failed
    reason: "fish sources conf.d/*.fish (including nvm.fish's auto-activation) BEFORE config.fish runs. config.fish sets nvm_data/nvm_default_version at lines 24-25, but by then nvm.fish's conf.d guard (`if status is-interactive && set --query nvm_default_version && ! set --query nvm_current_version`) has already evaluated false and skipped activation. No explicit `nvm use` call exists afterward. Reproduced live in this verification session in a clean-environment fish shell: node/npm/npx are absent even though nvm_default_version is correctly set. This is Critical finding CR-01 in 04-REVIEW.md (committed af17f9a) and remains unfixed as of the phase's most recent commit."
    artifacts:
      - path: "fish/.config/fish/config.fish"
        issue: "Lines 24-25 (`set -g nvm_data ...`, `set -g nvm_default_version v24.18.0`) run after nvm.fish's conf.d auto-activation already ran and no-op'd; nothing in config.fish explicitly calls `nvm use` afterward to activate the default version."
    missing:
      - "Add an explicit `if not set -q nvm_current_version; and functions -q nvm; nvm use --silent $nvm_default_version; end` block inside config.fish's status is-interactive section (per 04-REVIEW.md CR-01's proposed fix), or move nvm_data/nvm_default_version into a stowed conf.d/00-nvm-env.fish snippet that sorts before nvm.fish's own conf.d file so nvm.fish's own activation guard sees the vars in time."
      - "Separately: nothing in install.sh provisions Node v24.18.0 into ~/.config/nvm/versions/node on a genuinely fresh machine, so even the fixed activation would silently no-op until a one-time `nvm install v24.18.0` — worth a line in setup docs."
deferred: []
behavior_unverified_items:
  - truth: "Selecting Shutdown/Reboot from wlogout (or the walker power menu) completes every time with no blank-screen hang (ROADMAP SC1 / D-22 5-cycle protocol)"
    test: "Run the D-22 protocol: 5 consecutive real Shutdown/Reboot cycles from wlogout, alternating keyboard and mouse selection. After each boot, grep `journalctl -b -1` for stop-sigterm/timed-out/nvidia_drm/failed lines."
    expected: "All 5 cycles power off/reboot cleanly with no black-screen hang and no teardown-timeout journal errors."
    why_human: "Requires physically triggering real shutdown/reboot cycles and observing hardware behavior across multiple boots — cannot be simulated or grepped from static config. Additionally, 04-REVIEW.md's WR-01 raises an unresolved theoretical risk that `hyprshutdown`'s forked/daemonized process does not escape the uwsm session cgroup, so systemd tearing down the session on `Hyprland` exit could race and kill `hyprshutdown` before its `--post-cmd` runs — the fix's code is present and wired, but whether it actually survives the uwsm teardown path has not been demonstrated on this hardware."
  - truth: "After lock screen activation, the first keystrokes register — password typed in one attempt, no dropped-input failed-auth loop, 100% across 10 trials covering both manual-lock and idle-lock paths (ROADMAP SC2 / D-23 protocol)"
    test: "Run the D-23 protocol: ~10 lock-then-immediately-type trials across both the manual lock keybind and the idle-lock (loginctl lock-session) path, with a second TTY logged in first per the lockout-recovery procedure."
    expected: "100% first-try unlock across all 10 trials, no dropped first characters, no failed-auth loop."
    why_human: "Requires physically locking the real graphical session and typing a password immediately, repeated across two trigger paths — this is a real-time keyboard-focus race that cannot be reproduced by static analysis. The applied mitigation (`immediate_render` + `animation = fadeIn, 0`) shrinks the startup window in which keystrokes are lost but does not structurally guarantee zero loss; only the live 10-trial test settles it."
gaps_closed: []
gaps_remaining: []
regressions: []
---

# Phase 4: Reliability Fixes & Tech Debt Verification Report

**Phase Goal:** The three known reliability/performance defects are root-caused and fixed, and the v1 tech-debt carry-over is closed — de-risking the base before any redesign layers on top.
**Verified:** 2026-07-11T19:58:00Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Shutdown/Reboot from wlogout complete every time with no blank-screen hang; root cause diagnosed (keyboard-vs-mouse, journalctl/coredumpctl) and documented, not patched around (ROADMAP SC1 / FIX-01) | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | `wlogout/.config/wlogout/layout` and `hypr/.config/hypr/scripts/powermenu.sh` confirmed rewritten to `hyprshutdown --post-cmd 'systemctl poweroff\|reboot'` (read directly, matches SUMMARY). Diagnosis is thoroughly documented in 04-01-SUMMARY.md (journalctl -b -1/-2/-3 grep, coredumpctl, lspci NVIDIA confirmation, Hyprland version cross-check) with an honest "intermittent / not reproducible on demand" final disposition — this is genuine root-cause-over-patch-around work, not fabricated. However the D-22 5-cycle reliability test is still pending (human_verify_mode: end-of-phase, per 04-01-SUMMARY.md "Verification status ... pending"), and 04-REVIEW.md's WR-01 raises an unresolved, plausible risk (hyprshutdown forking does not escape the uwsm session cgroup; systemd could kill it before `--post-cmd` runs) that the code fix has not yet been proven to survive on real hardware. |
| 2 | After lock activation, the very first keystrokes register — password typed in one attempt, no dropped-input failed-auth loop (ROADMAP SC2 / FIX-02) | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | `hypr/.config/hypr/hyprlock.conf` confirmed migrated to the hyprlock 0.9.5 schema (`grace`/`no_fade_in`/`no_fade_out`/`fail_transition` removed, `general.immediate_render = true`, `animations { animation = fadeIn, 0 }` added) — read directly, matches 04-02-SUMMARY.md. Root cause was honestly revised mid-phase from the plan's #423 hypothesis to a real, evidence-captured cause (silently-invalid config options + startup keyboard-focus race) — a strong example of following evidence over the plan. But the D-23 10-trial lock-and-type protocol is explicitly recorded as PENDING in 04-02-SUMMARY.md ("Status: PENDING human 10-trial protocol") — the fix's actual reliability (100% first-try unlock) is unconfirmed. |
| 3 | Opening a new kitty terminal feels instant — startup profiled before/after, regression gone (ROADMAP SC3 / FIX-03) | ✓ VERIFIED | Independently re-measured in this verification session: `hyperfine --warmup 2 --min-runs 5 'zsh -i -c exit' 'fish -i -c exit'` → zsh 97.4ms ± 2.0ms, fish 33.9ms ± 1.1ms (fish ~2.87x faster) — closely matches 04-03/04-04-SUMMARY.md's recorded numbers (95.5ms/32.7ms) and the original 641ms pre-fix baseline. `zshell/.zshrc` confirmed to lazy-load nvm (`lazy_load_nvm` function, line 111) and to source oh-my-posh from a local vendored path (`$HOME/.config/oh-my-posh/catppuccin.omp.json`, line 46, no http(s) URL) — both read directly, not just claimed. This truth is genuinely and behaviorally verified, not just present-and-wired. |
| 4 | A fresh install.sh run installs rsync explicitly (listed in PACMAN_PKGS) (ROADMAP SC4 / DEBT-01) | ✓ VERIFIED | `install.sh` PACMAN_PKGS contains an uncommented `rsync` line (read directly, line ~90, under `# Utilities`). Confirmed it flows through `VERIFY_PKGS=("${PACMAN_PKGS[@]}" ...)` → `verify_packages` hard-fail gate (install.sh:403-407). `theme-engine/.config/theme-engine/lib/commit.sh` confirmed to call `rsync -a --delete` unconditionally (line 53) — the key link (install.sh rsync entry → verify_packages gate → commit.sh's rsync call) holds end to end. |
| 5 | All six wlogout actions audited against the uwsm session model; shutdown/reboot no longer bare `systemctl` (04-01-PLAN.md must_have) | ✓ VERIFIED | Direct read of `wlogout/.config/wlogout/layout`: Lock=`uwsm app -- hyprlock`, Logout=`uwsm stop` (already correct), Suspend/Hibernate=bare `systemctl` (audited, intentionally left per D-14 same-session-resume rationale), Shutdown/Reboot=`hyprshutdown --post-cmd ...` (fixed). All 6 keybind entries and text labels present and unchanged. `powermenu.sh` carries the identical class fix in its Reboot/Shutdown case branches. |
| 6 | Lockout-recovery procedure (second TTY + `pkill hyprlock`) written before any hyprlock test (04-02-PLAN.md must_have, D-20) | ✓ VERIFIED | 04-02-SUMMARY.md contains a complete, step-numbered "Lockout-Recovery Procedure" section naming the second-TTY login (`Ctrl+Alt+F2`) and the `pkill hyprlock` escape hatch, written in Task 1 before the Task 2 checkpoint reproduced the drop. |
| 7 | Optimized zsh and fish benchmarked side-by-side with a documented trade-off, user decision recorded, and — since fish won — the switch wired declaratively (kitty.conf `shell fish`, install.sh PACMAN_PKGS, stow.sh PACKAGES) with zshell retained as fallback and no chsh added (04-04-PLAN.md must_haves) | ✓ VERIFIED | `kitty/.config/kitty/kitty.conf` confirmed to contain `shell fish` (line 9) with `repaint_delay`/`input_delay`/`sync_to_monitor` untouched. `install.sh` confirmed to list `fish` under a `# Shell` PACMAN_PKGS group. `stow.sh` confirmed to list both `fish` and `zshell` in PACKAGES, with the pre-existing `sudo chsh -s "$(which zsh)"` line unchanged (no fish chsh added) — `git grep chsh` shows only that one zsh line. |
| 8 | If fish is selected, fish reaches day-one parity: vendored oh-my-posh prompt, fzf, zoxide, trimmed fastfetch greeting, **working node tooling** (04-04-PLAN.md must_have, D-10) | ✗ FAILED | Prompt/fzf/zoxide/fastfetch parity items are all present and correctly wired in `fish/.config/fish/config.fish` (read directly). **Node tooling is not working on a fresh shell** — reproduced live in this verification session: `env -i HOME=$HOME USER=$USER TERM=xterm PATH=/usr/bin:/bin fish -i -c 'type -q node; ...'` → `NODE=NO` even though `nvm_default_version` is correctly set to `v24.18.0`. This is 04-REVIEW.md's Critical finding CR-01, confirmed still unresolved in the current HEAD (`af17f9a`, the most recent commit, is the review report itself — no follow-up fix commit exists). See gap below. |

**Score:** 5/8 truths verified (2 present + wired but behaviorally unverified pending human reliability tests, 1 failed)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `wlogout/.config/wlogout/layout` | uwsm-correct Shutdown/Reboot actions, all 6 labels/keybinds intact | ✓ VERIFIED | Read directly — matches SUMMARY exactly |
| `hypr/.config/hypr/scripts/powermenu.sh` | Same class fix as layout | ✓ VERIFIED | Read directly — Reboot/Shutdown use hyprshutdown |
| `hypr/.config/hypr/hyprlock.conf` | grace-related dead options removed, immediate_render + fadeIn=0 added, typography/color untouched | ✓ VERIFIED | Read directly — 3 label font_size values (96/22/18) intact, `source = ~/.local/state/theme/hyprland.conf` present |
| `install.sh` | rsync + hyprshutdown + fish in PACMAN_PKGS | ✓ VERIFIED | All three present, flow through `verify_packages` gate |
| `stow.sh` | fish added to PACKAGES, zshell retained, chsh unchanged | ✓ VERIFIED | Confirmed directly |
| `kitty/.config/kitty/kitty.conf` | `shell fish` directive, rendering knobs untouched | ✓ VERIFIED | Confirmed directly |
| `fish/.config/fish/config.fish` | Day-one parity config | ⚠️ STUB (node tooling) | Prompt/fzf/zoxide/fastfetch wired; node-tooling activation logic present but non-functional (CR-01) |
| `zshell/.zshrc` | Local oh-my-posh, lazy nvm/bun | ✓ VERIFIED | Confirmed directly, matches SUMMARY |
| `zshell/.config/oh-my-posh/catppuccin.omp.json` | Valid vendored theme JSON | ✓ VERIFIED | `jq .` parses cleanly |
| `04-01-SUMMARY.md` / `04-02-SUMMARY.md` / `04-03-SUMMARY.md` / `04-04-SUMMARY.md` | Root-cause write-ups + verification records | ✓ VERIFIED | All exist, all contain the required diagnosis/evidence sections |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| wlogout layout action string | uwsm/hyprshutdown session teardown | `hyprshutdown --post-cmd 'systemctl poweroff\|reboot'` | ⚠️ PARTIAL | Wired correctly in config; runtime survival under uwsm's session cgroup teardown is the exact concern raised by 04-REVIEW.md WR-01 and not yet proven by the pending D-22 test |
| install.sh PACMAN_PKGS rsync entry | theme-engine/lib/commit.sh rsync call | `VERIFY_PKGS` hard-fail gate | ✓ WIRED | Confirmed end-to-end via direct read of both files |
| hyprlock.conf general{} | PAM auth keystroke input path | `immediate_render` + `animation fadeIn,0` | ⚠️ PARTIAL | Config wired correctly; whether the startup race is actually closed is the exact subject of the pending D-23 test |
| kitty.conf shell directive | fish config.fish parity init | `shell fish` | ✓ WIRED | Confirmed — but the node-tooling portion of the parity init does not deliver its intended effect (see Truth #8) |
| install.sh PACMAN_PKGS fish | stow.sh PACKAGES fish | `fish/.config/fish/config.fish` | ✓ WIRED | Confirmed directly |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| kitty/shell startup is measurably faster than the pre-fix baseline | `hyperfine --warmup 2 --min-runs 5 'zsh -i -c exit' 'fish -i -c exit'` | zsh 97.4ms ± 2.0ms; fish 33.9ms ± 1.1ms (fish ~2.87x faster); both dramatically below the original 641.3ms unoptimized baseline | ✓ PASS |
| fish shell configs and JSON are syntactically valid | `fish -n config.fish`; `zsh -n .zshrc`; `jq . catppuccin.omp.json`; `bash -n install.sh stow.sh` | All exit 0 | ✓ PASS |
| fish provides working node tooling on a fresh interactive shell (D-10 parity claim) | `env -i HOME=$HOME USER=$USER TERM=xterm PATH=/usr/bin:/bin fish -i -c 'type -q node; and echo NODE=YES; or echo NODE=NO'` | `NODE=NO` (nvm_default_version correctly set, but node never activated) | ✗ FAIL |
| hyprshutdown binary is installed and functional as a CLI | `hyprshutdown --help` | v0.1.1, `--post-cmd` flag present | ✓ PASS (binary exists; end-to-end teardown survival is the pending human item, not this check) |

### Probe Execution

| Probe | Command | Result | Status |
|-------|---------|--------|--------|
| `verify/container-run.sh` (D-24 container gate, explicitly declared in 04-01-PLAN.md/SUMMARY.md) | `bash verify/container-run.sh` | NOT RUN — this harness performs a genuine `git clone` of `github.com/yahiaeng/dotfiles` and requires the phase's commits to be pushed first. `git status` shows the local branch is 30 commits ahead of `origin/main` (unpushed) — running it now would either fail immediately or test stale remote state, not this phase's changes. 04-01-SUMMARY.md itself documents this exact precondition ("these commits must be pushed ... before the rerun tests them") and defers it to end-of-phase human verification. | SKIPPED (documented precondition unmet — legitimately deferred, not silently omitted) |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|--------------|--------|----------|
| FIX-01 | 04-01 | wlogout shutdown hang root-caused and fixed | ⚠️ PARTIAL | Diagnosis + class fix present and wired; 5-cycle reliability confirmation (D-22) and WR-01's uwsm-cgroup-survival concern remain open |
| FIX-02 | 04-02 | Hyprlock first-keystroke drop root-caused and fixed | ⚠️ PARTIAL | Diagnosis + mitigation present and wired; 10-trial reliability confirmation (D-23) remains open |
| FIX-03 | 04-03, 04-04 | Kitty startup fast, profiled before/after | ✓ SATISFIED | Independently re-measured; regression conclusively eliminated (641ms → 97ms optimized-zsh → 34ms fish) |
| DEBT-01 | 04-01 | rsync explicit in install.sh PACMAN_PKGS | ✓ SATISFIED | Confirmed present and gated |

No orphaned requirements — all four IDs declared across plans match REQUIREMENTS.md's Phase 4 traceability row exactly.

**Note:** REQUIREMENTS.md currently marks all four of FIX-01/FIX-02/FIX-03/DEBT-01 as `[x]` complete and the traceability table as "Complete" — this verification finds FIX-01 and FIX-02 not yet behaviorally confirmed (pending human tests) and surfaces a functional regression (fish node tooling) introduced by the FIX-03 work. These checkboxes should not be treated as gated sign-off; they reflect the executor's self-report, not verified reliability outcomes.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| `fish/.config/fish/config.fish` | 24-25 vs conf.d/nvm.fish | Node-tooling activation ordering bug (CR-01) | 🛑 Blocker | Every fresh fish shell has no `node`/`npm`/`npx` on PATH — see gap above |
| `wlogout/.config/wlogout/layout`, `hypr/.config/hypr/scripts/powermenu.sh` | action strings | Unverified survival of `hyprshutdown` under uwsm session-cgroup teardown (WR-01) | ⚠️ Warning | The exact failure class FIX-01 targeted could still occur under load; only the pending D-22 hardware test settles it |
| `zshell/.zshrc` | 123 | `. "$HOME/.local/share/../bin/env"` has no existence guard (unlike the guarded nvm lines 4 lines above); `install.sh` never installs `uv` | ⚠️ Warning | Fresh installs print a `no such file or directory` error on every interactive shell start — pre-existing, not introduced by this phase, but sits in a file this phase rewrote for startup quality |
| `fish/.config/fish/config.fish` | 43 | `curl -sL ... \| source` (fisher bootstrap) has no `--fail`/`-f`; failed HTTP responses get sourced as fish code | ⚠️ Warning | Noisy failure mode on network issues; re-attempts (with a network round-trip) on every shell start until it succeeds |
| `install.sh` | PACMAN_PKGS | `neovim` never installed despite `alias vim nvim` in both `.zshrc` and `config.fish` | ℹ️ Info | `vim` is broken on a fresh install in both shells (pre-existing, duplicated into the new fish package) |
| `zshell/.zshrc` | 60 | `HISTDUP=erase` is not a real zsh option (no-op) | ℹ️ Info | Cosmetic — dedup is actually handled by `setopt hist_ignore_all_dups` |

All items above were independently confirmed by direct file reads during this verification, not merely carried over from 04-REVIEW.md's claims.

### Human Verification Required

The following items are recorded as pending in the phase's own SUMMARY.md files under `human_verify_mode: end-of-phase` and remain unresolved at verification time (informational — status is `gaps_found` due to the CR-01 blocker above, not `human_needed`, but these still gate final sign-off before the phase can be considered fully closed):

1. **D-22: wlogout 5-cycle shutdown/reboot reliability test**
   - **Test:** From the wlogout menu, perform 5 consecutive real cycles alternating keyboard/mouse selection and Shutdown/Reboot. After each boot, grep `journalctl -b -1` for teardown-timeout signatures.
   - **Expected:** 5/5 clean cycles, no black-screen hang, no `stop-sigterm timed out` / `nvidia_drm` failure lines.
   - **Why human:** Requires physically power-cycling real hardware across multiple boots; additionally settles WR-01's open question of whether `hyprshutdown` actually survives uwsm's session-cgroup teardown.

2. **D-23: hyprlock 10-trial lock-and-type reliability test**
   - **Test:** With a second TTY logged in, perform ~10 lock→immediately-type trials across both the manual-lock keybind and the idle-lock (`loginctl lock-session`) path.
   - **Expected:** 100% first-try unlock, no dropped first character, no failed-auth loop.
   - **Why human:** Requires physically locking the real session and typing a password immediately, repeated across two trigger paths — a real-time input race that cannot be captured by static analysis.

3. **D-24: container-gate rerun (`verify/container-run.sh`)**
   - **Test:** Push this phase's commits to `origin/main`, then run `verify/container-run.sh` from the repo root.
   - **Expected:** Clean clone → `install.sh --core-only` → `stow.sh` → theme-parity all pass; `summary.log` records `overall=PASS`.
   - **Why human:** Requires a `git push` decision and a real container/network round-trip; explicitly deferred by 04-01-SUMMARY.md pending the push.

4. **New-kitty-window fish smoke check**
   - **Test:** Open a new kitty window in normal daily use and observe the fastfetch greeting + oh-my-posh prompt + node tooling.
   - **Expected:** Fast, clean startup with a working prompt.
   - **Why human/already-known-partial:** The prompt/fastfetch/speed portion of this check will pass (independently verified above); this verification has already established via direct reproduction that `node`/`npm` will NOT be available — the human check would only reconfirm the already-identified CR-01 gap, not surface new information.

### Gaps Summary

Three of the four ROADMAP success criteria (SC1 wlogout, SC2 hyprlock, SC3 kitty speed, SC4 rsync) have solid diagnosis-and-fix work behind them, and SC3/SC4 are independently confirmed working right now. SC1 and SC2, however, still have their core reliability claims ("completes every time" / "100% first-try") sitting on pending human tests that this phase's own `human_verify_mode: end-of-phase` setting deliberately deferred — that is expected process, not a defect, but it means those two success criteria are not yet behaviorally proven.

The one confirmed defect blocking a clean pass is CR-01 from 04-REVIEW.md: Plan 04-04 adopted fish as kitty's default interactive shell, and its own must_haves.truths explicitly requires "working node tooling" as part of day-one parity (D-10). That claim is false as shipped — reproduced live in this verification with a clean-environment fish launch showing `node` absent from PATH despite `nvm_default_version` being correctly set. The root cause is a load-order bug: fish sources `conf.d/nvm.fish` (the plugin's auto-activation) before `config.fish` sets the variables the activation guard checks. This is a new, real regression introduced by this phase's own scope (switching the default interactive shell), not a carry-over from before the phase — it directly undermines "de-risking the base before any redesign layers on top," since a user opening a fresh terminal now has no `node`/`npm`/`npx` until they manually work around it.

This is a single, well-isolated, non-architectural fix (see `missing:` in the gap entry above) — it does not require re-opening the shell-speed work, which stands independently verified.
