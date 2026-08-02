---
status: complete
phase: 15-audio-connectivity-panels
source: [15-VERIFICATION.md, 15-09-SUMMARY.md]
started: 2026-08-02T03:30:00Z
updated: 2026-08-02T07:20:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Wifi panel click-driven flow
expected: Scan progress renders; inline password row on a secured network; Connect succeeds; Cancel actually aborts in-flight; two-stage Escape (collapse, then dismiss); wrong password shows row-scoped "Wrong password".
how: `qs ipc call panel toggle wifi` or the Wi-Fi tile chevron. Connect to a real network; deliberately mistype once; start a connect and press Cancel mid-spinner.
why_human: No synthetic pointer-input tool on this host (ydotool/dotool/wlrctl/xdotool absent; wtype is keyboard-only) and no saved wifi profile — ethernet is primary. Click paths are source-verified and IPC-proven only.
note: Cancel's real abort effect is the single genuinely unmeasured behaviour in this phase. Nobody knows yet whether `cancelConnect()`'s teardown aborts the WPA handshake or no-ops until NetworkManager times out.
result: issue
reported: "Scan proggress line is moving too fast. Pressing on \"rescan\" needs to show feedback that the rescan action is underway. Also this is improtant for all panels not just wifi, they need to have the same animated colored border are the rest of dashboard."
severity: major
unreported_subchecks: Connect success, Cancel's real in-flight abort, two-stage Escape, and row-scoped "Wrong password" copy were not reported on — split out as test 4 so they are not silently lost.

### 2. Bluetooth panel device transitions
expected: Pairing shows a row-scoped spinner with a working Cancel; a successful pair/connect moves the device between groups without reordering peers; Forget requires the inline confirm then removes the device; a genuine failure renders "Couldn't pair" scoped to that row.
how: Bring a real discoverable peer (phone, headset) near the machine. Open the bluetooth panel, press "Add device", then pair → connect → disconnect → forget.
why_human: Host has zero paired devices and zero discoverable peers (confirmed by a live 8-second scan) plus no pointer tool. The adapter on/off half WAS live-proven via real `rfkill` fault injection in 15-09; only the device-list half is outstanding.
note: This is the one item that needs hardware this machine does not have. Everything else on this list is answerable in one sitting.
result: issue
reported: "Clicking enable on bluetooth does nothing. If this is due to me missing required packages, then the bluetooth should show as disabled and label the reason when I hover on it."
severity: major

### 3. Wifi and bluetooth Advanced buttons
expected: nm-connection-editor and blueman-manager each open as a detached window that survives dismissing the panel.
how: Click Advanced on the wifi panel, then on the bluetooth panel. Dismiss each panel while the app is open and confirm the app stays running.
why_human: The audio panel's Advanced (pavucontrol) was live-clicked and approved in 15-02's render gate. Wifi/bluetooth reuse the identical shared `PanelDialog.startDetached()` mechanism (3 call sites, no lifetime-bound `running: true`) and both binaries are installed, but neither was actually clicked.
result: pass

### 4. Wifi connect / Cancel / two-stage Escape / wrong-password copy
expected: Connect succeeds against a real password. Cancel visibly aborts an in-flight attempt rather than silently continuing to NetworkManager's own timeout. First Escape collapses an expanded row without dismissing the panel; second Escape dismisses. A wrong password renders the row-scoped "Wrong password" copy.
how: Open the wifi panel, expand a secured network, connect with the correct password; then retry with a deliberate typo; then start a connect and press Cancel mid-spinner; then test Escape from an expanded row.
why_human: Split out of test 1 — these sub-behaviours were not reported on when test 1 returned issues. Cancel's real abort effect remains the single genuinely unmeasured behaviour in this phase.
result: issue
reported: "Connection succeeds with a real password. Cancel visibly aborts. First escape collapses an expanded row instead of dismissing the entire panel. Second escape dismisses. A wrong password opens up a different dialogue window which is rendered behind the wifi panel. This is not the behaviour I want, everything should be contained inside the wifi panel. Also, add an option to add a hidden wifi network (a network has it's SSID broadcast turned off)"
severity: major
confirmed_working: Connect with a real password succeeds. Cancel visibly aborts an in-flight attempt — this resolves the phase's single genuinely unmeasured behaviour. Two-stage Escape behaves as specified (first collapses the expanded row, second dismisses the panel).

## Summary

total: 4
passed: 1
issues: 3
pending: 0
skipped: 0
blocked: 0

note: Test 2 (bluetooth device transitions) could not be exercised past the enable control — the
device-list half of that test (pair/connect/disconnect/forget against a real peer) remains
unverified behind gap G-15-2.

## Gaps

- gap_id: G-15-1
  truth: "Rescan/scan progress communicates that a scan is underway at a readable pace"
  status: failed
  reason: "User reported: Scan progress line is moving too fast. Pressing on 'rescan' needs to show feedback that the rescan action is underway."
  severity: major
  test: 1
  artifacts: []
  missing: []

- gap_id: G-15-1b
  truth: "Panels share the animated colored border used by the rest of the dashboard"
  status: failed
  reason: "User reported: this is important for all panels not just wifi, they need to have the same animated colored border as the rest of the dashboard."
  severity: major
  test: 1
  scope: cross-cutting — applies to every panel (wifi, bluetooth, audio), not wifi alone
  artifacts: []
  missing: []

- gap_id: G-15-2
  truth: "Clicking enable on the bluetooth panel powers the adapter on, or the control renders as disabled with a hover-legible reason"
  status: failed
  reason: "User reported: Clicking enable on bluetooth does nothing. If this is due to me missing required packages, then the bluetooth should show as disabled and label the reason when I hover on it."
  severity: major
  test: 2
  note: "Two-part gap — (a) the enable action is inert from the UI even though the enable IPC path was previously proven functional; (b) no degraded-state affordance exists when a prerequisite (package/daemon/adapter) is absent."
  artifacts: []
  missing: []

- gap_id: G-15-4
  truth: "A wrong wifi password renders row-scoped 'Wrong password' copy inside the wifi panel"
  status: failed
  reason: "User reported: A wrong password opens up a different dialogue window which is rendered behind the wifi panel. This is not the behaviour I want, everything should be contained inside the wifi panel."
  severity: major
  test: 4
  note: "Almost certainly NetworkManager's own secret-agent dialog surfacing because the panel is not acting as the agent — not a styling issue. Diagnosis must establish which process owns that window before a fix is planned."
  artifacts: []
  missing: []

- gap_id: G-15-4b
  truth: "The wifi panel offers a way to join a hidden network (SSID broadcast disabled)"
  status: failed
  reason: "User requested: add an option to add a hidden wifi network (a network has its SSID broadcast turned off)"
  severity: minor
  test: 4
  kind: feature-request
  note: "Additive scope, not a regression against anything phase 15 promised. Recorded here because the user asked for it during UAT — drop it from the gap-closure set if it belongs in its own phase."
  artifacts: []
  missing: []
