---
status: testing
phase: 15-audio-connectivity-panels
source: [15-VERIFICATION.md, 15-09-SUMMARY.md]
started: 2026-08-02T03:30:00Z
updated: 2026-08-02T03:30:00Z
---

## Current Test

number: 1
name: Wifi panel click-driven flow — scan, password, connect, cancel, two-stage Escape
expected: |
  Scan progress line renders. A secured network's password row appears inline.
  Connect succeeds against a real password. Cancel visibly aborts an in-flight attempt
  rather than silently continuing to NetworkManager's own timeout. First Escape collapses
  an expanded row without dismissing the panel; second Escape dismisses. A wrong password
  renders the row-scoped "Wrong password" copy.
awaiting: user response

## Tests

### 1. Wifi panel click-driven flow
expected: Scan progress renders; inline password row on a secured network; Connect succeeds; Cancel actually aborts in-flight; two-stage Escape (collapse, then dismiss); wrong password shows row-scoped "Wrong password".
how: `qs ipc call panel toggle wifi` or the Wi-Fi tile chevron. Connect to a real network; deliberately mistype once; start a connect and press Cancel mid-spinner.
why_human: No synthetic pointer-input tool on this host (ydotool/dotool/wlrctl/xdotool absent; wtype is keyboard-only) and no saved wifi profile — ethernet is primary. Click paths are source-verified and IPC-proven only.
note: Cancel's real abort effect is the single genuinely unmeasured behaviour in this phase. Nobody knows yet whether `cancelConnect()`'s teardown aborts the WPA handshake or no-ops until NetworkManager times out.
result: [pending]

### 2. Bluetooth panel device transitions
expected: Pairing shows a row-scoped spinner with a working Cancel; a successful pair/connect moves the device between groups without reordering peers; Forget requires the inline confirm then removes the device; a genuine failure renders "Couldn't pair" scoped to that row.
how: Bring a real discoverable peer (phone, headset) near the machine. Open the bluetooth panel, press "Add device", then pair → connect → disconnect → forget.
why_human: Host has zero paired devices and zero discoverable peers (confirmed by a live 8-second scan) plus no pointer tool. The adapter on/off half WAS live-proven via real `rfkill` fault injection in 15-09; only the device-list half is outstanding.
note: This is the one item that needs hardware this machine does not have. Everything else on this list is answerable in one sitting.
result: [pending]

### 3. Wifi and bluetooth Advanced buttons
expected: nm-connection-editor and blueman-manager each open as a detached window that survives dismissing the panel.
how: Click Advanced on the wifi panel, then on the bluetooth panel. Dismiss each panel while the app is open and confirm the app stays running.
why_human: The audio panel's Advanced (pavucontrol) was live-clicked and approved in 15-02's render gate. Wifi/bluetooth reuse the identical shared `PanelDialog.startDetached()` mechanism (3 call sites, no lifetime-bound `running: true`) and both binaries are installed, but neither was actually clicked.
result: [pending]

## Summary

total: 3
passed: 0
issues: 0
pending: 3
skipped: 0
blocked: 0

## Gaps
