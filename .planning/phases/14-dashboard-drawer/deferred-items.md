# Deferred Items — Phase 14 (dashboard-drawer)

Out-of-scope discoveries logged per the executor's scope-boundary rule: only
auto-fixed if directly caused by the current task's changes. Pre-existing
failures in unrelated subsystems are recorded here, not fixed.

## 14-03 Task 3 (render-gate revision pass, 2026-07-29)

- **`quickshell-doctor` FAIL: headless output remove (QS-03)** — "monitor
  count back to baseline (1 == 1), DP-1 probe still creatable (found: 0),
  shell PID unchanged (389777 == 389777), no crash marker in launcher log
  (hits: 0)". Observed while re-running `quickshell-doctor` as part of this
  plan's render-gate verification pass. This check exercises headless-monitor
  hotplug + `ScreencopyProbe` re-creatability (11-05 / QS-03 territory) —
  entirely unrelated to `modules/Dashboard.qml`'s per-tab dynamic sizing,
  which is the only surface this pass touched. Not investigated or fixed
  here; all other `quickshell-doctor` checks (namespace discipline, reserved-
  space non-claim across summon/dismiss, keybind-doctor, notifications
  ownership, hardware-key handler counts, MPRIS-writer count, hotplug
  reserved-space stability) passed clean both before and after this pass's
  edits.
