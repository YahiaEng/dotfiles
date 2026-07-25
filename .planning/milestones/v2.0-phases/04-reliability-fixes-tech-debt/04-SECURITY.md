---
phase: 04
slug: reliability-fixes-tech-debt
status: verified
# threats_open = count of OPEN threats at or above workflow.security_block_on severity (the blocking gate)
threats_open: 0
asvs_level: 1
created: 2026-07-11
---

# Phase 04 — Security

> Per-phase security contract: threat register, accepted risks, and audit trail.

---

## Trust Boundaries

| Boundary | Description | Data Crossing |
|----------|-------------|---------------|
| wlogout/powermenu UI → shell exec | Menu action strings dispatched as shell commands that transition/terminate the graphical session | Session-control commands |
| session client → systemd-logind/uwsm | Power transitions cross from an in-session client to the system session manager (polkit/logind) | Power-state requests |
| user keyboard → hyprlock → PAM | Untrusted keystrokes and auth submissions cross into the PAM stack at the lock screen | Password material; auth decisions |
| shell startup → network | oh-my-posh prompt config source at every interactive shell start | Remote-controlled config (eliminated — vendored locally) |
| lazy shim eval → shell | nvm/bun lazy-load shims define functions via eval during shell init | Fixed command names only |
| install.sh → pacman/AUR/fisher | Package + plugin manifest drives what a fresh system installs | Supply-chain artifacts |
| kitty.conf shell directive → interactive shell | Terminal launches the named shell; login shell (PAM/TTY) deliberately unchanged (D-12) | Shell selection |
| documented `nvm install` → nodejs.org mirror | One-time, user-invoked Node binary download (pinned v24.18.0) | Node runtime binary |

---

## Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation | Status |
|-----------|----------|-----------|----------|-------------|------------|--------|
| T-04-01 | Denial of Service | wlogout shutdown/reboot → compositor teardown (04-01) | high | mitigate | `wlogout/layout` Shutdown/Reboot use `hyprshutdown --post-cmd 'systemctl poweroff\|reboot'` — compositor exits cleanly before the power transition (FIX-01); D-22 5-cycle UAT passed | closed |
| T-04-02 | Tampering | powermenu.sh / wlogout action strings (04-01) | low | mitigate | Only action/case-branch strings changed; labels/keybinds/CSS preserved, reviewed in git diff | closed |
| T-04-03 | Elevation of Privilege | suspend/hibernate wrapping (04-01) | medium | accept | Audit confirmed suspend/hibernate stay bare (they resume into the same session); rationale documented in 04-01 plan/summary | closed |
| T-04-SC-01 | Tampering (supply chain) | AUR/unofficial install path for wleave/hyprshutdown (04-01) | high | mitigate | Blocking human-verify package-legitimacy checkpoint passed before install; rsync is official `extra` repo | closed |
| T-04-04 | Elevation of Privilege | hyprlock grace-period unlock-without-password window (04-02) | medium | mitigate | `grace` is CLI-only in hyprlock 0.9.5 (default 0) and no invocation passes `--grace` — documented in hyprlock.conf header; lock always requires a password | closed |
| T-04-05 | Denial of Service | hyprlock keystroke drop → failed-auth loop (04-02) | high | mitigate | Grace-race eliminated (see T-04-04) + 04-06 `ignore_empty_input` closes the remaining ENTER-first drop; D-23 10-trial UAT re-test passed (FIX-02) | closed |
| T-04-06 | Denial of Service | lock-screen testing could lock the user out (04-02) | medium | mitigate | Lockout-recovery procedure (second TTY + pkill hyprlock) written before first test (D-20); recorded in 04-02/04-06 summaries and used during UAT | closed |
| T-04-07a | Info Disclosure / Tampering | oh-my-posh remote-URL fetch at shell start (04-03) | medium | mitigate | Theme vendored to `zshell/.config/oh-my-posh/catppuccin.omp.json`; zero remote URLs remain in .zshrc (D-03) — shell startup offline-safe | closed |
| T-04-08a | Tampering | nvm/bun lazy-load shim eval (04-03) | low | accept | Shim wraps fixed command names only (nvm/node/npm/npx/bun), no untrusted input; standard community pattern per RESEARCH.md Pattern 5 | closed |
| T-04-09a | Denial of Service (self) | slow synchronous shell startup (04-03) | medium | mitigate | Profile-driven fixes verified by before/after hyperfine (641ms → 97.4ms zsh / 33.9ms fish) | closed |
| T-04-SC-02 | Tampering (supply chain) | nvm.fish fisher plugin + fish install (04-04) | high | mitigate | Blocking, non-auto-approvable human-verify checkpoint passed before fisher/nvm.fish install; fish itself is official `extra` | closed |
| T-04-10 | Denial of Service | switching kitty to a broken fish config (04-04) | medium | mitigate | `kitty.conf` `shell fish` only — no `chsh` anywhere in install.sh (D-12); TTY recovery stays on zsh, zshell package retained (D-11) | closed |
| T-04-11 | Repudiation | shell switch without recorded rationale (04-04) | low | mitigate | Decision checkpoint benchmark numbers and trade-off recorded in 04-04-SUMMARY.md (D-25) | closed |
| T-04-05-01 | Denial of Service | nvm activation block in config.fish (04-05) | low | mitigate | Guarded by `functions -q nvm` + `not set -q nvm_current_version` + `--silent`; `fish -n` syntax-checked; login shell unaffected (D-12) | closed |
| T-04-05-02 | Repudiation | node-tooling fix without recorded evidence (04-05) | low | mitigate | Before/after clean-env probe output (`NODE=NO` → `NODE=YES v24.18.0`) recorded in 04-05-SUMMARY.md (D-25) | closed |
| T-04-05-SC | Tampering (supply chain) | Node binary via documented `nvm install v24.18.0` (04-05) | low | accept | No new install added by the plan; nvm.fish already human-verified at 04-04's gate; version pinned from official nodejs.org mirror, user-invoked one-time | closed |
| T-04-07b | Denial of Service | hyprlock PAM-in-flight input gate on empty submit (04-06) | medium | mitigate | `general:ignore_empty_input = true` in hyprlock.conf — ENTER on empty buffer opens no PAM round, no ~2-3s dead-input window; schema-verified against hyprlock 0.9.5 binary; D-23 re-test passed | closed |
| T-04-08b | Denial of Service | pam_faillock tally growth via repeated empty submits (04-06) | low | mitigate | Same option eliminates empty-password submits — repeated ENTER no longer accrues toward the deny=3 / 10-minute lockout | closed |
| T-04-09b | Denial of Service | silent checking window on wrong-password round (04-06) | low | mitigate | `input-field:check_text = <i>Checking...</i>` renders a visible in-flight cue; schema-verified against hyprlock 0.9.5 binary | closed |

*Status: open · closed · open — below high threshold (non-blocking)*
*Severity: critical > high > medium > low — only open threats at or above workflow.security_block_on (high) count toward threats_open*
*Disposition: mitigate (implementation required) · accept (documented risk) · transfer (third-party)*
*Note: plans 04-03 and 04-06 independently declared IDs T-04-07/08/09; disambiguated here with a/b suffixes preserving each plan's declared numbering.*

---

## Accepted Risks Log

| Risk ID | Threat Ref | Rationale | Accepted By | Date |
|---------|------------|-----------|-------------|------|
| AR-04-01 | T-04-03 | suspend/hibernate deliberately stay bare — wrapping them in uwsm stop would log the user out instead of resuming the session | plan 04-01 (user-approved plan) | 2026-07-11 |
| AR-04-02 | T-04-08a | Lazy shim evals only fixed command names, no untrusted input; standard community pattern | plan 04-03 (user-approved plan) | 2026-07-11 |
| AR-04-03 | T-04-05-SC | Pinned Node version from official nodejs.org mirror, user-invoked one-time provisioning; plugin already gated at 04-04 | plan 04-05 (user-approved plan) | 2026-07-11 |

---

## Security Audit Trail

| Audit Date | Threats Total | Closed | Open | Run By |
|------------|---------------|--------|------|--------|
| 2026-07-11 | 19 | 19 | 0 | gsd-secure-phase (L1 grep-depth verification, short-circuit: plan-time register, all mitigations verified in implementation) |

---

## Sign-Off

- [x] All threats have a disposition (mitigate / accept / transfer)
- [x] Accepted risks documented in Accepted Risks Log
- [x] `threats_open: 0` confirmed
- [x] `status: verified` set in frontmatter

**Approval:** verified 2026-07-11
