---
status: diagnosed
phase: 15-audio-connectivity-panels
source: [15-VERIFICATION.md, 15-09-SUMMARY.md]
started: 2026-08-02T03:30:00Z
updated: 2026-08-02T07:45:00Z
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
  root_cause: "Two independent causes. (1) The sweep uses MD3 one-shot transition tokens (emphasizedIn 375ms + emphasizedOut 187ms) as an infinite loop period — 562ms/cycle vs MD3's ~2000ms reference. Because the motion multiplier multiplies duration, the `reduced` accessibility preset is the FASTEST at 225ms/cycle. (2) Rescan produces no observable state edge: `scanning` reads back `scannerEnabled`, which the lifecycle Binding already forces true while the panel is open; rescan() writes false then true in one JS frame with no repaint between, so nothing changes. The progress line indicates 'panel is open', never 'scan underway'. The refresh glyph also has no pressed/busy state."
  artifacts:
    - path: "quickshell/.config/quickshell/modules/dashboard/WifiPanel.qml"
      issue: "L865-886 SequentialAnimation loops:Infinite bound to emphasizedIn/Out one-shot tokens; L897-915 refresh glyph is a constant-coloured Text with no pressed state"
    - path: "quickshell/.config/quickshell/modules/dashboard/WifiBackend.qml"
      issue: "L98-113 scanning is a level derived from scannerEnabled, not an edge; rescan() toggle is invisible"
    - path: "quickshell/.config/quickshell/modules/dashboard/Motion.qml"
      issue: "L56 _pairNames is a fixed 4-entry positional list that never reaches the ambient/blink-slow/blink-fast loop-period tokens already present in the rendered motion.json"
    - path: ".planning/phases/15-audio-connectivity-panels/15-UI-SPEC.md"
      issue: "L177 (D-15-15) LOCKED the level semantics — 'pinned for the panel's whole open lifetime while scannerEnabled is true'. The implementation is faithful to spec; closing this gap requires amending the spec too."
  missing:
    - "Expose a loop-period alias on Motion.qml over an existing token (ambient/blink-slow 1250ms) — do NOT hardcode a duration, motion-lint CHECK B forbids it"
    - "Ensure the fix does not let the loop period shrink under the `reduced` motion preset"
    - "Synthesise a bounded 'rescan in flight' edge in WifiBackend — armed by rescan(), cleared on networks.valuesChanged or a watchdog (rowWatchdogTimer at WifiPanel.qml:128-133 is the house precedent)"
    - "Give the refresh control a pressed/busy state driven by that edge"
    - "Amend UI-SPEC D-15-15 so the fix is not flagged as a spec deviation on re-verification"
  debug_session: ".planning/debug/wifi-scan-progress-feedback.md"

- gap_id: G-15-1b
  truth: "Panels share the animated colored border used by the rest of the dashboard"
  status: failed
  reason: "User reported: this is important for all panels not just wifi, they need to have the same animated colored border as the rest of the dashboard."
  severity: major
  test: 1
  scope: cross-cutting — applies to every panel (wifi, bluetooth, audio), not wifi alone
  root_cause: "Missing reuse, not a runtime fault. PanelDialog.qml — the single shared frame all three panels use as their root type — paints only a translucent background Rectangle (L157-174) and declares no border of any kind. It never instantiates GradientBorder, which has exactly one consumer in the tree (Dashboard.qml:387). Phase 15's PanelDialog copied Dashboard.qml's layer posture, corner radii, surface opacity and theme-crossfade Behavior, but the GradientBorder block sitting between background and content was not carried across."
  artifacts:
    - path: "quickshell/.config/quickshell/modules/dashboard/PanelDialog.qml"
      issue: "L157-174 background Rectangle has no border.width/border.color/Shape; no borderWidth property declared"
    - path: "quickshell/.config/quickshell/modules/dashboard/GradientBorder.qml"
      issue: "Reusable as-is — bare Item, geometry-independent, four per-corner radii; already solves the Qt6 Shapes PathRectangle limitation in JS"
  missing:
    - "Add a GradientBorder to PanelDialog.qml between the background Rectangle and the content Item, matching Dashboard.qml:387-394's child-order position and radii handoff (7-line call site)"
    - "Decide deliberately where borderWidth:3 lives — Dashboard.qml:233-239 names it there 'so the parity claim has one home'; a second copy splits that home, and GradientBorder's own default is already 3"
  verified_reusable: "Three potential blockers all ruled out with evidence — (a) no geometry coupling, GradientBorder recomputes from its own width/height; (b) the Qt6 Shapes constraint is already solved inside the component, and the panel's corner set (0/0/28/28) is byte-identical to the drawer's, the exact case the workaround exists for; (c) the `default property alias body` capture hazard was poison-proven under qml6 6.11.1 — same-file children stay direct children of the root."
  call_sites_to_change: 0
  debug_session: ".planning/debug/panels-missing-animated-border.md"

- gap_id: G-15-2
  truth: "Clicking enable on the bluetooth panel powers the adapter on, or the control renders as disabled with a hover-legible reason"
  status: failed
  reason: "User reported: Clicking enable on bluetooth does nothing. If this is due to me missing required packages, then the bluetooth should show as disabled and label the reason when I hover on it."
  severity: major
  test: 2
  note: "Two-part gap — (a) the enable action is inert from the UI even though the enable IPC path was previously proven functional; (b) no degraded-state affordance exists when a prerequisite (package/daemon/adapter) is absent."
  root_cause: "AND-gate, both conditions required. (1) The host's adapter is rfkill SOFT-BLOCKED, so Quickshell's BluetoothAdapter binding refuses the `enabled = true` write outright — it never reaches D-Bus. The running shell's own log records six refusals ('Cannot enable adapter because it is blocked by rfkill', ~/.cache/quickshell.log:1650-1656) matching the user's repeated clicks, visible only on stderr. (2) BluetoothBackend.qml exposes only adapterPresent/adapterEnabled and never reads adapter.state, so BluetoothAdapterState.Blocked is not representable in QML; the panel falls through to the 'fixable' branch and renders an Enable button that provably cannot work, with the binding's refusal swallowed and no failure path."
  user_hypothesis_disproven: "The user guessed missing packages. Wrong, and this changes the fix copy — bluez 5.87-2, bluez-utils 5.87-2 and blueman 2.4.6-2 are all installed, bluetoothd has been up 1d1h, and a real controller (60:E9:AA:20:44:B0) is enumerated. The missing prerequisite is an UNBLOCKED RADIO. The block is soft (user-recoverable via `rfkill unblock bluetooth`), not a hardware killswitch, and it is persistent — systemd-rfkill has saved value 1 for this device, so it survives reboots."
  artifacts:
    - path: "quickshell/.config/quickshell/modules/dashboard/BluetoothBackend.qml"
      issue: "L34/40-46 expose only adapterPresent/adapterEnabled; L52-56 setAdapterEnabled() has no failure path. adapter.state is never read — grep for BluetoothAdapterState across quickshell/ returns zero hits."
    - path: "quickshell/.config/quickshell/modules/dashboard/BluetoothPanel.qml"
      issue: "L72-76 two-branch predicates (noAdapter/adapterOff) with no blocked case; L240-303 renders Enable unconditionally, violating the principle quoted at L273-275 — 'never offer a control that cannot work'"
    - path: "quickshell/.config/quickshell/modules/dashboard/WifiPanel.qml"
      issue: "L76-77, L281-315 — the three-branch precedent (radioBlocked / radioOff / populated) that bluetooth should mirror"
    - path: "quickshell/.config/quickshell/modules/dashboard/PanelDialog.qml"
      issue: "L245-290 (D-15-22 / UI-SPEC E7) — the disabled+hover-reason convention already exists and is already consumed by this panel's Advanced button; it was simply never applied to Enable"
  missing:
    - "Add `adapterBlocked` to BluetoothBackend over adapter.state === BluetoothAdapterState.Blocked (readonly property, notify stateChanged — the signal exists in the installed qmltypes and is unused)"
    - "Add a third branch to BluetoothPanel between noAdapterBranch and adapterOffBranch"
    - "Render Enable at identical geometry with disabledOpacity 0.38, MouseArea left enabled:true so hover still reaches the tooltip, press suppressed by an early-return in setAdapterEnabled()"
    - "Tooltip copy must name the real reason (a software/rfkill block), NOT a missing package"
  cannot_fix: "The panel cannot unblock rfkill itself — Prohibition P1 forbids shelling out and the binding refuses the write. Disabled-with-reason is the only correct affordance, which is exactly what the user asked for."
  verification_claim_contradicted: "15-VERIFICATION.md:40 claims 'the fixable-off-state Enable button was pressed and observed to actually re-enable the radio.' Its own cited source contradicts it — 15-09-SUMMARY.md:297 records external recovery via `rfkill unblock` from OUTSIDE the panel. The Enable button was never pressed in any verification. Separately 15-API-PROBE.md:22 had already recorded state:Blocked as the live distinguishing signal before the panel was built."
  debug_session: ".planning/debug/bluetooth-enable-inert.md"

- gap_id: G-15-4
  truth: "A wrong wifi password renders row-scoped 'Wrong password' copy inside the wifi panel"
  status: failed
  reason: "User reported: A wrong password opens up a different dialogue window which is rendered behind the wifi panel. This is not the behaviour I want, everything should be contained inside the wifi panel."
  severity: major
  test: 4
  note: "Almost certainly NetworkManager's own secret-agent dialog surfacing because the panel is not acting as the agent — not a styling issue. Diagnosis must establish which process owns that window before a fix is planned."
  window_ownership: "CONFIRMED nm-applet, PID 1018 — the sole registered NM secret agent (only agent-registration line in the whole boot). Journal proof from the actual UAT session: wpa_supplicant '4-Way Handshake failed - pre-shared key may be incorrect' → NM 'psk mismatch reported by supplicant, asking for new key' → state config→need-auth → nm-applet 'No keyring secrets found for go-jo/802-11-wireless-security; asking user.' → GTK dialog construction → 9s gap → 'User canceled the secrets request.' → need-auth→failed."
  root_cause: "AND-gate, both conditions required. (1) nm-applet owns every NM secret request. It is autostarted by /etc/xdg/autostart/nm-applet.desktop from the network-manager-applet package, which install.sh:116 installs (added in 15-08) — nothing in the repo launches it, it is an unmanaged package side effect. Critically, NetworkManager does NOT fail an activation on a PSK mismatch: it re-enters need-auth and issues GetSecrets to the registered agent, which prompts. (2) The panel structurally cannot intercept that request — quickshell 0.3.0-2's Networking module has no SecretAgent type, no AgentManager binding and no GetSecrets handler."
  eliminated:
    - "'The panel doesn't supply the password' — FALSE. NM audit log shows op=connection-add-activate name=go-jo pid=2982672 (the live quickshell process) result=success, followed by 'secrets exist. No new secrets needed.' connectWithPsk() works correctly."
    - "'It's a z-order/styling problem' — FALSE and unfixable in QML. It is another process's GTK dialog, and the behind-ness is a guaranteed consequence of PanelDialog.qml:129 WlrLayer.Overlay: a layer-shell overlay is unconditionally above every XDG toplevel in Hyprland. windowrules.lua:40 already floats ^(nm-applet)$ and can never win."
    - "'A polkit agent is prompting' — FALSE. polkit-gnome-authentication-agent-1 is running but shows zero journal activity in the window."
  second_independent_finding: "Even with the dialog gone, the copy would still be wrong. WifiBackend.qml:310-325 maps 'Wrong password' to ConnectionFailReason.WifiAuthTimeout ONLY. The failure NM actually emitted was reason no-secrets → NoSecrets → 'Password required'. Worse, WifiPanel.qml:249 then re-expands the password row on NoSecrets. The handler did run (watchdog 15000ms, failure landed ~12s) — with the wrong string. A real PSK mismatch may never route to WifiAuthTimeout on this NM/quickshell combination."
  artifacts:
    - path: "install.sh"
      issue: "L116 installs network-manager-applet, which drags in the autostart secret agent"
    - path: "quickshell/.config/quickshell/modules/dashboard/WifiBackend.qml"
      issue: "L246-261 connect() is correct; L310-325 failReasonText() maps 'Wrong password' to a reason that may be unreachable"
    - path: "quickshell/.config/quickshell/modules/dashboard/WifiPanel.qml"
      issue: "L236-250 onConnectFailed; the NoSecrets re-expand branch fires on the wrong condition"
    - path: "quickshell/.config/quickshell/modules/dashboard/PanelDialog.qml"
      issue: "L129 WlrLayer.Overlay — why any external dialog is always behind"
  missing:
    - "MEASURE FIRST (blind spot, must not be assumed): what NM emits on a wrong PSK when NO agent is registered, and which ConnectionFailReason reaches connectFailed. Cheaply testable by stopping the nm-applet unit and driving one wrong-PSK connect — but it will drop the live go-jo association, so schedule it deliberately."
    - "Choose a mechanism: (A) displace the agent — suppress the nm-applet autostart via a stowed ~/.config/autostart/nm-applet.desktop with Hidden=true or a masked user unit; conflicts with 15-08's deliberate decision to add network-manager-applet, and leaves NO agent registered. (B) own the agent — register an out-of-band NM secret agent the panel controls (Quickshell.Networking can't, so a small D-Bus process or Quickshell.DBus/Process); heavier, but the only route that makes the panel genuinely self-contained rather than merely silent."
    - "Rework failReasonText() and WifiPanel.qml:249 so the row-scoped 'Wrong password' copy is actually reachable — needed regardless of which mechanism is chosen"
  debug_session: ".planning/debug/wifi-wrong-password-external-dialog.md"

- gap_id: G-15-4b
  truth: "The wifi panel offers a way to join a hidden network (SSID broadcast disabled)"
  status: failed
  reason: "User requested: add an option to add a hidden wifi network (a network has its SSID broadcast turned off)"
  severity: minor
  test: 4
  kind: feature-request
  note: "Additive scope, not a regression against anything phase 15 promised. User confirmed during UAT that it should be fixed in this round."
  root_cause: "Feature absent — never implemented. SSID-broadcast hiding appears in no phase-15 artifact. The non-obvious cost driver: this is NOT a UI-only addition. Quickshell.Networking structurally cannot express a hidden network — every connect verb is an instance method on a Network object, and Quickshell filters blank-SSID APs out of wifiDevice.networks entirely, so a hidden AP yields no receiver object. Measured live at the same moment: `nmcli device wifi list` shows 5 hidden APs (the strongest APs on the band), while a quickshell probe reports total networks=8 with BLANK_SSID_COUNT=0. `grep -i hidden` over quickshell-network.qmltypes = 0 hits. A subprocess is therefore unavoidable — a first for WifiBackend.qml, whose header states it 'needs no subprocess, no parser and no timer at all'."
  artifacts:
    - path: "quickshell/.config/quickshell/modules/dashboard/WifiPanel.qml"
      issue: "Insertion point is listColumn's populated branch — between networkList (ends :975) and zeroResultState (:983). Advanced is NOT reachable from this file (it lives in PanelDialog's shared headerBand :238), so 'next to Advanced' is not an option."
    - path: "quickshell/.config/quickshell/modules/dashboard/BluetoothPanel.qml"
      issue: "L739-765 discoverySection is the shape to copy verbatim — a fixed-height Item holding two mutually-exclusive states, deliberately fixed so switching never moves rows above or below"
    - path: "quickshell/.config/quickshell/modules/dashboard/WifiBackend.qml"
      issue: "Connect path is native (network.connectWithPsk), not nmcli. Every pending/expanded/failed property is keyed by network OBJECT identity (WifiPanel.qml:95-99, T-15-08) — a hidden entry has no object and cannot slot into any of them."
  missing:
    - "STEP ZERO: prove Route B end-to-end. `nmcli device wifi rescan ssid <SSID>` is a directed probe that carries no secret; if the AP answers it materializes as a real Network object and the ENTIRE existing flow works unchanged (expandedNetwork, passwordRow, startConnect, pending pulse, Cancel, connectFailed row-scoped copy, Forget). Unproven here because no hidden SSID on this host is known — and some APs don't answer directed probes."
    - "Route B also requires `nmcli connection modify <name> 802-11-wireless.hidden yes` — secret-free but REQUIRED, since a profile built from a revealed AP defaults to hidden:no (verified live on go-jo) and would fail autoconnect on a later boot"
    - "Route A fallback (proven but costlier): `nmcli device wifi connect <SSID> password <pw> hidden yes` — duplicates the connect verb, puts the passphrase on argv (world-readable /proc/PID/cmdline, violates P3; mitigable via Process.stdinEnabled + write() with nmcli --ask), and needs a new error mapping since nmcli returns exit codes + stderr rather than an enum"
    - "New non-object-keyed state: hiddenFormOpen, hiddenSsid, parallel hiddenPending/hiddenFailedText (do NOT reuse expandedNetwork — handleRowPress, isExpanded, collapseExpandedRow and the NoSecrets recovery all compare object identity)"
    - "rowWatchdogTimer (:128, 15000ms) currently clears pendingNetwork only — must also clear hidden pending"
    - "handleEscape() (:149) needs a third branch before requestDismiss() — do NOT regress two-stage Escape, which the user explicitly confirmed working"
    - "Security selector: smallest honest design is NO selector — an empty passphrase already means open, which is the existing semantics of startConnect(network, '') and connect()'s `if (psk && psk.length > 0)`. No radio/segmented/dropdown primitive exists anywhere in the shell."
  reuse_available: "TextField block (WifiPanel.qml:681-704 — one of only two TextFields in the shell; there is no shared text-input component), Keys.onEscapePressed two-stage consume (:695), forceActiveFocus on visible (:702), connectAction pill (:710-743), pendingGlyph pulse (:564-596), Cancel (:618-630), rowFailureText (:749-756), GroupHeader (:389), Behavior on implicitHeight (:456-463), Process already imported (:30)."
  coupling: "SEQUENCE AFTER G-15-4. The hidden flow terminates in a NetworkManager activation on both routes, so it inherits the external-secret-dialog behaviour identically — and the risk is structurally HIGHER, because the user types SSID and passphrase from memory and a wrong SSID on a hidden network is indistinguishable from an out-of-range AP. Route A does not dodge this either; NM still re-asks."
  debug_session: ".planning/debug/wifi-hidden-network-unsupported.md"
