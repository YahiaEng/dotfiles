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

## 14-06 Task 2 (Performance tab render-gate prep, 2026-07-29)

- **`Dashboard.qml`'s `activeContentWidth` does not shrink the drawer frame
  when navigating BACKWARD (arrow-Left) from a wider tab to a narrower one —
  only the height updates.** Reproduced live and cleanly isolated: from a
  freshly-restarted shell, summoning the drawer and stepping forward
  Dashboard(1008x572) -> Media(760x424) -> Performance(760x690) ->
  Weather(1068x512) via repeated `Right` correctly resizes the frame at
  every step. Stepping back ONE tab with `Left` (Weather -> Performance)
  settles at `w=1068, h=690` — Weather's width frozen alongside Performance's
  own correct height — and stays there indefinitely (checked at +1.5s and
  +6s, well past `Motion.standardDuration`). Performance's own content is
  confirmed correct throughout (real CPU/memory/storage/battery/network
  values render at the right positions) — this is a frame-sizing defect in
  `Dashboard.qml`'s `activeContentWidth`/Loader-priority mechanism itself,
  not in `PerformanceTab.qml`. Out of this plan's ownership fence
  (`Dashboard.qml` is 14-03's frozen file); not investigated further or
  fixed here. Flagged to the render-gate checkpoint and to 14-08/14-09 as a
  pager-level bug affecting every tab pair, not something specific to the
  Performance surface.
