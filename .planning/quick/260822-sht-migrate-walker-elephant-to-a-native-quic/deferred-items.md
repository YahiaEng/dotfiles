# Deferred items — quick-260822-sht

Out-of-scope discoveries logged during Stage 2 execution (Tasks 5-9), per
the executor's scope-boundary rule: only auto-fix issues directly caused
by the current task's own changes.

## 1. quickshell-doctor `bar-surface-registry` (GATE-03) reports `unregistered=1`

**Found during:** post-Task-9 verification (shell restart + `quickshell-doctor` run).

**Root cause (verified via `git show 5c522dad`):** `Launcher.qml`
declared `WlrLayershell.namespace: "quickshell-launcher"` from its very
first commit in Task 1 (2026-08-23, Stage 1) — this predates Tasks 5-9
entirely. `quickshell-doctor`'s `QSD_KNOWN_NONBAR_FRAMES` allowlist
(`hypr/.config/hypr/scripts/quickshell-doctor:431`) lists
`PanelDialog.qml Dashboard.qml Overview.qml Probe.qml
ScreencopyProbe.qml` but was never updated to include `Launcher.qml`
when Task 1 introduced it.

**Why not fixed here:** This is a Stage 1 gap, not something Tasks 5-9
introduced, and is out of this dispatch's scope (Stage 2, dmenu-consumer
migration only). `quickshell-doctor` is explicitly reserved for Task 10
(Stage 3 retirement) per the plan's own file list.

**Fix needed (for whoever picks up Task 10 or a follow-up):** add
`Launcher.qml` to `QSD_KNOWN_NONBAR_FRAMES` in
`hypr/.config/hypr/scripts/quickshell-doctor:431`.

**Evidence:**
```
[FAIL] bar-surface-registry (GATE-03, ...): source: rows=10 missing=0
  unexpected-reservation=0 unregistered=1, live: permanent=1 off-level=0
  wrong-pid=0 unmatched=0
```
All other 27 quickshell-doctor checks passed after the post-Task-9 shell
restart.

## 2. Bar Settings drawer's "Bar Orientation" axis is broken (pre-existing, Task 5)

**Found during:** Task 12 (Stage 3 retirement), while fixing the sibling
"Theme" axis in the same array (`ClockActionsCapsule.qml`'s
`settingsAxes`), which deleting `theme-switch.sh` would otherwise have
broken.

**Root cause:** `SettingsAxisCell` runs `axisLaunchProcess` with
`command: [scriptPath]` — the script bare, with NO arguments. Task 5
(Stage 2) deleted `bar-orientation.sh`'s interactive picker function and
made the no-argument invocation a usage error (`bar-orientation.sh:
usage: bar-orientation.sh <horizontal|vertical>`, exit 1) — verified live
this session. The "Bar Orientation" row in the bar's clock/settings
drawer has therefore been non-functional (silently exits 1, no picker
opens) since Task 5's commit, unrelated to this dispatch's own changes.

**Why not fixed here:** Out of scope per the executor's scope-boundary
rule — this regression was introduced by Task 5 (Stage 2, already
committed prior to this dispatch), not by Task 12's own edits. Task 12
only touched the sibling "Theme" axis because ITS OWN action (deleting
`theme-switch.sh`) would have newly broken that one.

**Fix needed (for a follow-up):** Either give `SettingsAxisCell` a second
`launcherMode`-style axis shape that opens the launcher's own
Style ▸ Bar orientation picker (`PickerMode.qml`, `pickerId:
"barorientation"` per Task 5's own wiring) via `qs ipc call launcher open
<mode>` — the same fix this dispatch applied to the "theme" axis — or
give the axis a fixed argument (though bar orientation is a two-way
toggle, not a fire-and-forget action, so a bare fixed argument does not
fit the same shape as "theme").
