---
phase: 04-reliability-fixes-tech-debt
plan: 01
subsystem: wlogout/hyprland-session-teardown, install.sh packaging
tags: [wlogout, uwsm, hyprland, nvidia, session-teardown, install-sh, rsync]
dependency-graph:
  requires: []
  provides: [uwsm-correct-power-actions, rsync-in-pacman-pkgs]
  affects: [wlogout/.config/wlogout/layout, hypr/.config/hypr/scripts/powermenu.sh, install.sh]
tech-stack:
  added: [hyprshutdown 0.1.1-3 (official extra repo, hyprwm upstream)]
  patterns: ["graceful compositor exit before systemd power transition (hyprshutdown --post-cmd)"]
key-files:
  created:
    - .planning/phases/04-reliability-fixes-tech-debt/04-01-SUMMARY.md
  modified:
    - wlogout/.config/wlogout/layout
    - hypr/.config/hypr/scripts/powermenu.sh
    - install.sh
decisions:
  - "FIX-01 fix: hyprshutdown --post-cmd 'systemctl poweroff/reboot' replaces bare systemctl in wlogout layout + powermenu.sh — graceful app+compositor exit before the power transition (class fix per D-13)"
  - "--vt flag omitted: it shells out to 'sudo -n chvt N' (needs a passwordless sudoers rule this machine lacks — would silently no-op) and targets the exit-to-greeter black screen, not the power-transition path"
  - "Suspend/Hibernate stay bare systemctl (D-14): they resume into the same session — wrapping them in session teardown would be a logout-on-suspend bug"
  - "wleave replacement branch did NOT fire (D-15): no evidence implicated the wlogout binary itself; wlogout.sh and keybinds.conf untouched"
  - "hyprshutdown added to install.sh PACMAN_PKGS (reproducibility constraint — layout now depends on it)"
metrics:
  duration: ~50min (excl. human checkpoint wait)
  completed: 2026-07-11
status: complete
---

# Phase 4 Plan 1: FIX-01 wlogout hang + DEBT-01 rsync Summary

Shutdown/Reboot now go through hyprshutdown's graceful compositor teardown (`hyprshutdown --post-cmd 'systemctl poweroff|reboot'`) in both wlogout and the walker power menu, replacing bare in-session `systemctl` calls; rsync is explicit in install.sh PACMAN_PKGS.

## Task 1: Diagnosis from existing evidence (preliminary)

### Evidence gathered

**journalctl grep across last 3 boots** (`journalctl -b -1 / -2 / -3 --no-pager | grep -iE "sigterm|sigkill|nvidia_drm|stop-sigterm|timed out"`):

- `-b -1`: only `systemd-journald` received its own SIGTERM at shutdown (expected, normal journald teardown) and an unrelated kernel clocksource watchdog message. **No** `stop-sigterm timed out. Killing` line, **no** nvidia_drm-correlated failure.
- `-b -2`: same pattern — journald SIGTERM (normal) + clocksource watchdog + an unrelated pacman mirror timeout. No hang signature.
- `-b -3`: same pattern — journald SIGTERM (normal) + clocksource watchdog + an unrelated NTP timeout. No hang signature.
- The tail of `-b -1`'s log shows a **clean** shutdown: `systemd-logind[629]: poweroff requested from client PID 860518 ('shutdown') ... The system will power off now! ... System is powering down.` — no truncation, no abrupt cutoff consistent with a forced power cycle.
- `journalctl -k -b -1 | grep -iE "nvidia_drm|drm"` shows only the nvidia-drm **driver load** messages at boot start (`[drm] [nvidia-drm] [GPU ID 0x00000700] Loading driver`) — as expected, the kernel ring buffer for a boot doesn't capture the *next* boot's early driver-unload timing; this doesn't rule the race in or out, it just confirms no historical hang was captured to inspect.

**coredumpctl** (`coredumpctl list --since="-7 days"`): No coredumps found. (RESEARCH.md's noted hyprlock SIGABRT coredump from 2026-04-02 is outside the 7-day window and is an unrelated symptom — crash, not hang — not relevant to FIX-01.)

**GPU confirmation** (`lspci -k | grep -A3 -i vga`): `NVIDIA Corporation GA104 [GeForce RTX 3070]`, `Kernel driver in use: nvidia` (not nouveau) — matches RESEARCH.md's Assumption A2 (this machine is NVIDIA-only, consistent with the `omarchy#5726` shutdown-race pattern).

**Hyprland version** (`hyprctl version`): `Hyprland 0.55.4`, built June 2026 — well past the March 2024 fix (`hyprwm/Hyprland#4599`, PR #5240) for the historical mouse-click-hangs-logout bug. This corroborates RESEARCH.md Pitfall 1: identical keyboard/mouse behavior in Task 2's reproduction should be read as evidence AGAINST #4599, not for it.

**hyprshutdown package check** (`pacman -Ss hyprshutdown`): `extra/hyprshutdown 0.1.1-3` — confirmed in the official `extra` repo, NOT a separate AUR package. This resolves RESEARCH.md Open Question 3: no AUR legitimacy checkpoint is required to use `hyprshutdown`.

### No historical hang reproduced (Open Question 1, unresolved by evidence alone)

None of the last 3 boots (`-b -1`, `-b -2`, `-b -3`) show a truncated/abrupt ending consistent with a hard power-cycle recovery from a genuine black-screen hang. This matches RESEARCH.md's own finding: the hang has not yet been captured with a timestamp in available journal history. **Task 2's live reproduction (keyboard vs. mouse, on-demand shutdown/reboot) is required to confirm the root cause with direct evidence** — this section is preliminary, not final.

### Six-action uwsm-correctness audit (D-14)

| Action | Current `action` string | uwsm-correct? |
|--------|--------------------------|----------------|
| Lock | `uwsm app -- hyprlock` | Yes — uwsm-wrapped app launch |
| Logout | `uwsm stop` | Yes — ends the uwsm-managed session cleanly |
| Suspend | `systemctl suspend` | No — bare systemctl, but resumes into the *same* session (D-14: not necessarily a defect — see decision below) |
| Hibernate | `systemctl hibernate` | No — bare systemctl, same resume-into-same-session caveat |
| Shutdown | `systemctl poweroff` | No — bare systemctl, terminates the session; root-cause target for FIX-01 |
| Reboot | `systemctl reboot` | No — bare systemctl, terminates the session; root-cause target for FIX-01 |

Identical defect confirmed in `hypr/.config/hypr/scripts/powermenu.sh`'s `case` branches: `Reboot` and `Shutdown` call bare `systemctl reboot`/`systemctl poweroff`; `Suspend` calls bare `systemctl suspend`; `Lock`/`Logout` are already uwsm-correct (`uwsm app -- hyprlock` / `uwsm stop`).

### Leading hypothesis

Per RESEARCH.md: the **NVIDIA compositor-unload-vs-systemd-kill-timeout race** (`basecamp/omarchy#5726`) is the leading hypothesis for FIX-01 — SIGTERM is sent to the compositor on `systemctl poweroff`/`reboot`, but the `nvidia` driver (confirmed in use on this GA104 RTX 3070) doesn't finish unloading before systemd's kill-timeout forcibly SIGKILLs it, producing a black screen instead of a clean VT handoff. This is **not** the old Hyprland mouse-click bug (`hyprwm/Hyprland#4599`) — that was fixed in Hyprland core in March 2024 (PR #5240), and this machine runs Hyprland 0.55.4 (June 2026 build), well past that fix. Per Pitfall 1: if Task 2's reproduction shows **identical** hang behavior for keyboard and mouse triggers, that is evidence AGAINST #4599 and FOR the teardown-race hypothesis — the exec/session-teardown path (bare `systemctl` call from inside a uwsm-managed session), not the input path, is where the defect most likely lives.

### Keyboard-vs-mouse reproduction procedure (for Task 2's human checkpoint)

1. Open wlogout (`Super+Shift+Q`). Trigger **Shutdown** via the **keyboard hotkey** (`s`). Observe: black-screen hang, or clean power-off?
2. If it hangs: hard power-cycle, then on next boot run:
   ```
   journalctl -b -1 --no-pager | grep -iE "stop-sigterm|timed out|nvidia_drm|sigkill"
   ```
   and capture any matching lines.
3. Repeat for **Reboot** (keyboard), then once more triggering **Shutdown by MOUSE CLICK** on the icon (not keyboard) — this isolates input-path (#4599) vs. teardown-path (NVIDIA race).
4. Report: (a) does keyboard behave differently from mouse? (b) the exact journalctl signature captured, or "no hang reproduced in N attempts."

**Interpretation:** identical keyboard/mouse hang + a "stop-sigterm timed out ... Killing" line near `nvidia_drm` confirms the teardown-race root cause → apply the uwsm-correct/`hyprshutdown --vt` fix in Task 3. No difference and no signature after 5 attempts → treat as intermittent, widen the log-capture window (`-b -2`, `-b -3`), and proceed with the uwsm-correctness fix anyway since the audit above already confirms the bare-`systemctl` pattern is present regardless (fixing the class of bug per D-13 is warranted even if this specific race can't be captured on demand).

git diff at this point shows only `04-01-SUMMARY.md` added — `wlogout/layout` and `powermenu.sh` are unchanged (no fix applied yet; Task 2's human-verify checkpoint gates Task 3).

## Task 2: Live reproduction result (human checkpoint, approved)

- **No hang reproduced** — Shutdown and Reboot both completed cleanly in testing.
- **Keyboard vs. mouse: identical results** — no input-path difference. Per Pitfall 1's interpretation rule, this is evidence AGAINST the historical Hyprland mouse-click bug (`hyprwm/Hyprland#4599`, fixed March 2024, this machine runs 0.55.4) and consistent with the teardown-path hypothesis.
- **No journalctl hang signature captured** — nothing to capture, since no hang occurred during the reproduction attempts.

**Final root-cause disposition (D-13/D-25):** FIX-01 is **intermittent / not currently reproducible on demand**. The leading (and only surviving) hypothesis remains the NVIDIA compositor-unload-vs-systemd-kill-timeout race (`basecamp/omarchy#5726` pattern): NVIDIA GA104 RTX 3070 on the `nvidia` driver, SDDM-managed session, and a confirmed structural defect — Shutdown/Reboot dispatched a bare, unmanaged `systemctl poweroff`/`reboot` from *inside* the uwsm-managed session, so the compositor received SIGTERM mid-transition and raced systemd's kill-timeout during driver unload. Per the plan's interpretation guide and the checkpoint approval, the class-of-bug fix was applied on the strength of the Task 1 audit evidence (the bare-systemctl pattern is present and wrong regardless of on-demand reproducibility), not patched around.

## Task 3: Applied fix

### FIX-01 — uwsm-correct session-teardown actions

`wlogout/.config/wlogout/layout` (only `action` strings changed; every `label`, `text`, `keybind` byte-for-byte identical; style.css untouched per D-16):

| Action | Before | After |
|--------|--------|-------|
| Shutdown | `systemctl poweroff` | `hyprshutdown --post-cmd 'systemctl poweroff'` |
| Reboot | `systemctl reboot` | `hyprshutdown --post-cmd 'systemctl reboot'` |

`hypr/.config/hypr/scripts/powermenu.sh` — identical class fix in the `Reboot`/`Shutdown` case branches (the walker power menu is a Phase 7 MENU-05 surface; it no longer carries the same defect).

**Why hyprshutdown:** official `extra` repo package (0.1.1-3, hyprwm upstream — `pacman -Si` verified; **no AUR legitimacy gate required**, resolving RESEARCH.md Open Question 3). It is purpose-built for exactly this failure mode: it daemonizes itself (double-fork + setsid, verified in upstream `src/main.cpp`) so it survives the compositor's death, gracefully closes all apps via Hyprland IPC, exits Hyprland cleanly (non-forced), and only *then* runs the `--post-cmd` power transition — the documented "end the session cleanly before the systemd power transition" pattern from `hyprwm/Hyprland#12174` (RESEARCH.md Pattern 1), implemented by a maintained upstream tool instead of hand-rolled wrapper logic ("Don't Hand-Roll").

**Why NOT `--vt N`:** upstream source shows `--vt` shells out to `sudo -n chvt N`, which requires a passwordless sudoers rule for `chvt` that this machine does not have (`sudo -n` fails) — it would silently no-op. It also targets the NVIDIA+SDDM *exit-to-greeter* black screen (per the upstream code comment), not the power-transition path this plan fixes. If the D-22 five-cycle test still black-screens, the follow-up is a `/etc/sudoers.d/` chvt rule + `--vt` — documented here so the option isn't lost.

**Suspend/Hibernate audit decision (D-14):** left as bare `systemctl suspend`/`systemctl hibernate` in both files. They resume back into the *same* session — tearing the session down first would convert every suspend into a logout (threat T-04-03, disposition: accept). Task 2's evidence did not implicate them.

**wleave branch (D-15): did not fire.** No evidence implicated the wlogout binary itself (the defect was in the action strings' session-teardown semantics). `hypr/.config/hypr/scripts/wlogout.sh` and `hypr/.config/hypr/config/keybinds.conf` are untouched.

### DEBT-01 — rsync explicit in install.sh

Added `rsync` to `PACMAN_PKGS` under the existing `# Utilities` group (alongside jq/psmisc/stow, one package per line). `theme-engine/lib/commit.sh`'s unconditional `rsync -a --delete` no longer relies on a transitive dependency on a minimal fresh Arch install. AUR_PKGS, NVIDIA_PKGS, and verify_packages() untouched — the new entries flow through the existing `VERIFY_PKGS=("${PACMAN_PKGS[@]}" ...)` hard-fail gate automatically.

## Deviations from Plan

### Auto-fixed / auto-added

**1. [Rule 2 - Missing critical functionality] hyprshutdown added to install.sh PACMAN_PKGS**
- **Found during:** Task 3
- **Issue:** The rewritten layout/powermenu actions depend on the `hyprshutdown` binary, which was not in any install.sh package array — a fresh install would have non-functional Shutdown/Reboot menu entries (violates the reproducibility constraint).
- **Fix:** Added `hyprshutdown` to `PACMAN_PKGS` under `# Hyprland ecosystem` (official `extra` repo — no AUR gate needed).
- **Files modified:** install.sh

No other deviations — plan executed as written.

## Authentication gates

**hyprshutdown host install requires sudo (password-gated).** `sudo -n` is unavailable in this environment, so the package could not be installed by the executor. **Before running the D-22 five-cycle test, run:** `sudo pacman -S --needed hyprshutdown`. This is folded into the Task 4 verification checkpoint rather than a separate gate.

## Verification status (Task 4 — end-of-phase human checkpoint, pending)

Per config `human_verify_mode: end-of-phase`, the blocking Task 4 checkpoint is deferred to end-of-phase verification:

- **FIX-01 (D-22), pending:** install hyprshutdown (`sudo pacman -S --needed hyprshutdown`), then 5 consecutive real cycles from the wlogout menu — alternate keyboard/mouse selection, mix Shutdown and Reboot; after each boot run `journalctl -b -1 --no-pager | grep -iE "stop-sigterm|timed out|nvidia_drm|failed"` and confirm no teardown-timeout errors. Do not sign off below 5/5 clean.
- **DEBT-01 (D-24), pending:** `./verify/container-run.sh` rerun. **Note:** the gate performs a genuine `git clone` of the real remote (D-56) — these commits must be pushed to `github.com/yahiaeng/dotfiles` before the rerun tests them.

## Automated verification (executed this session)

- Task 3 plan gate: no uncommented `"action": "systemctl poweroff|reboot"` in layout; `grep -Eq '^[[:space:]]*rsync([[:space:]]|$)' install.sh` passes; keybind count == 6 → **PASS**
- All six `text` values (Lock/Logout/Suspend/Hibernate/Shutdown/Reboot) unchanged → **PASS**
- `git diff --stat`: `wlogout/.config/wlogout/style.css` unchanged; no CSS/icon/asset files touched (D-16 prohibition) → **PASS**
- `bash -n` clean on powermenu.sh and install.sh → **PASS**
- `pacman -Si hyprshutdown` → `extra/hyprshutdown 0.1.1-3` (official repo, no AUR checkpoint required) → **PASS**
