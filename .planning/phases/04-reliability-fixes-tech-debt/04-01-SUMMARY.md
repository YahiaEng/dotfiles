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
  added: []
  patterns: ["uwsm-correct session teardown before systemd power transition"]
key-files:
  created: []
  modified:
    - wlogout/.config/wlogout/layout
    - hypr/.config/hypr/scripts/powermenu.sh
    - install.sh
decisions: []
metrics:
  duration: TBD
  completed: TBD
status: in-progress
---

# Phase 4 Plan 1: FIX-01 wlogout hang + DEBT-01 rsync Summary

FIX-01/DEBT-01 root-cause diagnosis and fix, in progress.

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

<!-- gsd:write-continue -->
