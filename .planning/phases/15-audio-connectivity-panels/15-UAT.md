---
status: diagnosed
phase: 15-audio-connectivity-panels
source: [15-VERIFICATION.md, 15-09-SUMMARY.md, 15-10-SUMMARY.md, 15-11-SUMMARY.md, 15-12-SUMMARY.md, 15-13-SUMMARY.md, 15-14-SUMMARY.md]
started: 2026-08-02T03:30:00Z
updated: 2026-08-02T18:10:00Z
round: 2
note: |
  Round 1 recorded issues on tests 1, 2 and 4. All five resulting gaps
  (G-15-1, G-15-1b, G-15-2, G-15-4, G-15-4b) were closed by executed
  gap-closure plans 15-10 through 15-14, reconciled below, and retested in
  round 2 — all five confirmed. Round-1 reports are preserved verbatim as
  `round1_reported`. Tests 5 and 6 are new checkpoints covering deliverables
  that did not exist in round 1.

  Test 6 failed on first retest, was diagnosed as G-15-6 (a handoff race in
  WifiPanel.qml — NOT the Route B failure it resembled), fixed inline at the
  user's request in commit 12575ac, and re-passed against the user's own
  hidden AP on a cold cache.

  All six tests pass. One item stays open by design and is not a UAT result:
  the bluetooth device-list half, blocked on hardware this host does not have
  (see deferred-items.md).
---

## Current Test

number: 7
name: Bluetooth device transitions against a real peer
expected: |
  The half of the original test 2 that has never been reachable on this
  host. The adapter is now unblocked and powered, with zero paired devices
  — a clean slate.

  Open the bluetooth panel. It should show "No paired devices" and an "Add
  device" button. Press it: discovery starts, the button becomes "Stop",
  the discovery line sweeps at the corrected ~2000ms pace, and your device
  appears under a "Nearby" heading.

  Press your device to pair. Expect a row-scoped spinner with a working
  Cancel. On success it should move up into "Paired" (or "Connected")
  WITHOUT reordering the peers around it. Then connect, then disconnect.

  Press Forget: an inline confirm reading "Forget <name>?" with Forget and
  Cancel. Confirming removes the device.

  If a pair genuinely fails, expect "Couldn't pair" scoped to that row —
  not a global banner and not an external window.
awaiting: user response

## Tests

### 1. Wifi scan pace and Rescan feedback

expected: Scan progress line sweeps at a readable ~2000ms cycle. Pressing the refresh glyph gives immediate press feedback plus a persistent busy state (primary colour, animating, tooltip "Rescanning…") that clears when results land. Bluetooth's discovery line sweeps at the same corrected pace. The `reduced` motion preset must not be faster than `normal`.
how: `qs ipc call panel toggle wifi` or the Wi-Fi tile chevron. Watch the sweep, then press Rescan and watch the glyph.
closes_gap: G-15-1 (plan 15-11)
round1_reported: "Scan proggress line is moving too fast. Pressing on \"rescan\" needs to show feedback that the rescan action is underway."
result: pass

### 2. Bluetooth blocked-adapter state

expected: This host's bluetooth radio is rfkill soft-blocked. The panel renders a third empty state — heading "Bluetooth is blocked", body "A software block is holding the radio off" — with an Enable button at normal geometry but visibly dimmed. Hovering it shows "Run  rfkill unblock bluetooth  in a terminal to clear it" — the real reason, never a missing package. Pressing it does nothing at all, while hover still reaches the tooltip. Running `rfkill unblock bluetooth` externally makes the panel re-render into the ordinary off-state with a working Enable, with no restart.
how: `qs ipc call panel toggle bluetooth`. Hover the dimmed Enable, press it, then run `rfkill unblock bluetooth` in a terminal and watch the panel.
closes_gap: G-15-2 (plan 15-12)
round1_reported: "Clicking enable on bluetooth does nothing. If this is due to me missing required packages, then the bluetooth should show as disabled and label the reason when I hover on it."
scope_note: The device-list half of the original test 2 (pair / connect / disconnect / forget against a real peer) is NOT part of this checkpoint — it stays open in deferred-items.md behind a hardware blocker this repo cannot close.
result: pass

### 3. Wifi and bluetooth Advanced buttons

expected: nm-connection-editor and blueman-manager each open as a detached window that survives dismissing the panel.
result: pass

### 4. Wrong wifi password stays inside the panel

expected: A wrong passphrase produces NO external window at all — nm-applet's GTK secret dialog is gone, suppressed by a stowed autostart override. The failure renders as row-scoped copy inside the wifi panel naming a rejected passphrase, and the password row does NOT re-open as though nothing had been typed. A network that genuinely needs a passphrase you did not supply still reads "Password required" and still re-expands its row — the two cases stay distinguishable.
how: Expand a secured network, deliberately mistype the passphrase, press Connect, and watch for any window appearing behind the panel.
closes_gap: G-15-4 (plan 15-13)
round1_reported: "A wrong password opens up a different dialogue window which is rendered behind the wifi panel. This is not the behaviour I want, everything should be contained inside the wifi panel."
already_confirmed: Connect with a real password succeeds; Cancel visibly aborts an in-flight attempt; two-stage Escape works (first collapses the expanded row, second dismisses the panel). All three were confirmed in round 1 and are not being re-tested here — but flag it if plan 15-14's third Escape stage regressed either of the first two.
result: pass

### 5. Animated gradient border on all three panels

expected: Opening the audio, wifi or bluetooth panel shows the same animated gradient rim the dashboard drawer already has — same 3px thickness, tracing the same 28px bottom corners. It re-themes on a theme switch and stops rotating at the `off` motion scale, exactly as the drawer's rim does. The drawer's own rim must look unchanged.
how: `qs ipc call panel toggle audio`, then wifi, then bluetooth. Compare against the dashboard drawer (Super+D).
closes_gap: G-15-1b (plan 15-10)
round1_reported: "this is improtant for all panels not just wifi, they need to have the same animated colored border are the rest of dashboard."
result: pass

### 6. Join a hidden network

expected: The wifi panel offers a "Join a hidden network" entry point sitting between the network list and the zero-result line, at a fixed height so opening it never shifts the rows around it. Typing an SSID and pressing "Search" runs a directed probe; while probing, the button reads "Cancel". If the access point answers, it materialises as a normal row and the ENTIRE existing flow takes over unchanged — password field, Connect, pending pulse, Cancel, row-scoped failure copy. If it does not answer within 8 seconds, a form-scoped message says so. Escape gains a third stage (closing the form) without disturbing the two you confirmed in round 1.
how: Open the wifi panel, scroll to below the network list, press "Join a hidden network". Test with a real hidden SSID if you have one; otherwise type a nonsense SSID to confirm the not-found path and the Escape ordering.
closes_gap: G-15-4b (plan 15-14)
round1_reported: "Also, add an option to add a hidden wifi network (a network has it's SSID broadcast turned off)"
unproven: Route B (directed probe) was never proven against a real hidden AP — no hidden SSID on this host is known, and some APs do not answer directed probes. If it fails against a real hidden network, that is the documented Route A fallback trigger, not a regression.
result: pass
round2_reported: "Fail. It cannot detect my hidden network. I have one that I can test on if needed"
resolved_by: "commit 12575ac (inline fix, no gap-closure plan) — retry the handoff on results-landed, re-probe while in flight, raise the window 8000 -> 30000ms"
retest: "Passed against the user's own hidden AP (`!ono^`) on a genuine cold cache — the diagnosis-session reveal had aged out beforehand."
outcome: DIAGNOSED — and the obvious reading was wrong. Measured against the user's own hidden AP (`!ono^`), Route B's directed probe DOES reveal it and Quickshell DOES see it as an ordinary named Network object. The defect is a race inside the panel: tryHiddenHandoff() runs 16-30ms after the probe starts and is never retried, so it always searches a stale list. See gap G-15-6.

### 7. Bluetooth device transitions against a real peer
expected: Discovery starts from "Add device" (button becomes "Stop") and the peer appears under "Nearby". Pairing shows a row-scoped spinner with a working Cancel. Success moves the device into "Paired"/"Connected" without reordering peers. Connect and disconnect work. Forget requires the inline "Forget <name>?" confirm then removes the device. A genuine failure renders "Couldn't pair" scoped to that row.
how: Adapter confirmed unblocked and powered, zero paired devices. `qs ipc call panel toggle bluetooth`, then Add device → pair → connect → disconnect → forget against the user's standby peer.
closes: The device-list half of round-1 test 2 — unreachable until now because the host had no discoverable peer and the Enable control was inert.
provenance: Raised as an open item in deferred-items.md with an owner condition tied to hardware availability. The user supplied the hardware, so it is being closed on its own terms rather than at a phase boundary.
result: issue
reported: "I manged to pair with my device \"z fold 7\". However, the ppair message pops up in an external screen/notification that appears in my upper right corner. And, If the pair fails. there is no explicit rerty button."
severity: major
confirmed_working: The device-list flow itself works end to end against a real peer — discovery, the device appearing, and a successful pair. This is the first time any of it has been exercised on this host, and it closes the deferred-items.md hardware blocker. Two defects sit on top of a working flow; the flow is not in question.
splits_into: [G-15-7 (external pairing prompt), G-15-8 (no explicit retry)]

## Summary

total: 7
passed: 6
issues: 1
pending: 0
skipped: 0
blocked: 0

note: Round 2 confirmed all five round-1 gap closures. Test 6 failed on first
retest, was diagnosed as G-15-6 — a handoff race inside WifiPanel.qml, NOT the
Route B failure it first looked like — fixed inline (12575ac) and re-passed
against the user's own hidden AP on a cold cache. Route B was measured viable,
so the pre-specified Route A fallback was correctly NOT taken.

One item remains open and is deliberately NOT counted as a UAT result: the
device-list half of bluetooth (pair / connect / disconnect / forget) is
unverified behind a hardware blocker — this host has no discoverable peer.
Tracked in deferred-items.md with an owner condition tied to hardware
availability, explicitly not to a phase or milestone boundary.

## Gaps

<!-- All round-1 gaps reconciled 2026-08-02 against executed gap-closure plans. -->
<!-- A resolved gap is not re-diagnosed; if the behaviour is still broken in round 2 -->
<!-- it is recorded as a fresh regression gap with a new gap_id. -->

- gap_id: G-15-1
  truth: "Rescan/scan progress communicates that a scan is underway at a readable pace"
  status: resolved
  resolved_by: 15-11-PLAN.md
  resolved_at: 2026-08-02
  severity: major
  test: 1
  debug_session: ".planning/debug/wifi-scan-progress-feedback.md"

- gap_id: G-15-1b
  truth: "Panels share the animated colored border used by the rest of the dashboard"
  status: resolved
  resolved_by: 15-10-PLAN.md
  resolved_at: 2026-08-02
  severity: major
  test: 5
  debug_session: ".planning/debug/panels-missing-animated-border.md"

- gap_id: G-15-2
  truth: "Clicking enable on the bluetooth panel powers the adapter on, or the control renders as disabled with a hover-legible reason"
  status: resolved
  resolved_by: 15-12-PLAN.md
  resolved_at: 2026-08-02
  severity: major
  test: 2
  residual: "The device-list half (pair/connect/disconnect/forget) remains unverified behind a hardware blocker — tracked in deferred-items.md, not in this gap."
  debug_session: ".planning/debug/bluetooth-enable-inert.md"

- gap_id: G-15-4
  truth: "A wrong wifi password renders row-scoped copy inside the wifi panel, with no external dialog"
  status: resolved
  resolved_by: 15-13-PLAN.md
  resolved_at: 2026-08-02
  severity: major
  test: 4
  debug_session: ".planning/debug/wifi-wrong-password-external-dialog.md"

- gap_id: G-15-4b
  truth: "The wifi panel offers a way to join a hidden network (SSID broadcast disabled)"
  status: resolved
  resolved_by: 15-14-PLAN.md
  resolved_at: 2026-08-02
  severity: minor
  test: 6
  note: "Resolved as SHIPPED — the entry point, form, handoff and Escape stage all exist. Its Route B mechanism failed in round-2 retest against a real hidden AP; that is tracked as the fresh gap G-15-6 below, not as a reopening of this one."
  debug_session: ".planning/debug/wifi-hidden-network-unsupported.md"

# ── Round 2 ──────────────────────────────────────────────────────────────────

- gap_id: G-15-6
  truth: "Typing a real hidden network's SSID into the panel's hidden-network form reveals it and hands off to the normal connect flow"
  status: resolved
  resolved_by: "commit 12575ac (inline fix — user chose to skip formal gap-closure planning)"
  resolved_at: 2026-08-02
  retest_result: "pass — verified by the user against their own hidden AP on a cold cache"

# ── Round 2, bluetooth device list (test 7) ──────────────────────────────────

- gap_id: G-15-7
  truth: "A pairing confirmation is presented inside the bluetooth panel, not as an external window or notification"
  status: failed
  reason: "User reported: the pair message pops up in an external screen/notification that appears in my upper right corner"
  severity: major
  test: 7
  structural_twin_of: G-15-4
  window_ownership: "CONFIRMED blueman-applet, PID 1013 — /usr/bin/python /usr/bin/blueman-applet, autostarted from /etc/xdg/autostart/blueman.desktop via the generated app-blueman@autostart.service (verified active/running), owning org.blueman.Applet on the session bus. It is the registered BlueZ agent and therefore owns every pairing prompt. blueman-tray (PID 1357) is a separate sibling process."
  root_cause: "The panel structurally cannot intercept a pairing request. `Quickshell.Bluetooth`'s installed qmltypes contains ZERO occurrences of 'agent' — no Agent type, no AgentManager binding, no RequestConfirmation/RequestPasskey handler. Its full exposed surface is adapter/device properties plus the five verbs (pair, cancelPair, connect, disconnect, forget). BlueZ routes every pairing interaction to the registered org.bluez.Agent1, which is blueman-applet. This is the exact shape of G-15-4: another process owns the prompt, and no QML change can win it."
  critical_asymmetry_vs_G_15_4: "The G-15-4 remedy MUST NOT be copied here. Suppressing nm-applet was safe because NetworkManager could still complete the connection from the passphrase the panel supplied natively — removing the agent removed only the prompt. Bluetooth is different: a Secure Simple Pairing confirmation (numeric comparison, which is what a modern phone like the reported Z Fold 7 uses) REQUIRES a registered agent to answer it. With blueman suppressed and no replacement, pairing would not become self-contained — it would stop working. Suppression alone converts a cosmetic containment problem into a functional regression."
  measured: "DONE 2026-08-02. Procedure: user Forgot the bonded Z Fold7 through the panel (Forget itself confirmed working); app-blueman@autostart.service stopped and verified inactive with zero blueman processes, zero bonds, and org.bluez.AgentManager1 present but unclaimed; user then drove one pair from the panel against a real peer."
  measurement_result: "PAIRING DOES NOT COMPLETE WITHOUT AN AGENT. No external prompt appeared (as expected), and no bond was created — `bluetoothctl devices` is empty afterwards, the device is not even in the known list. The system journal shows BlueZ creating and tearing down the device object twice (21:22:04→08 and 21:22:21→23, 'unmanaged-link-not-init'), i.e. pairing started and was dropped both times. Notably quickshell logged NO error for this attempt: the whole log contains exactly one 'Failed to pair' WARN and it predates the measurement marker. So BlueZ does not return an error either — the pair silently never completes and the panel's own watchdog is what surfaces it."
  conclusion: "The external prompt is LOAD-BEARING, not cosmetic. Option A ('accept it') is now grounded in a measured platform constraint rather than an assumption inherited from the wifi case, and option C (suppress + auto-accept agent) is doubly wrong — it would be both insecure AND the only thing standing between the user and a non-functional pair. Option B (own the agent) remains the sole containment route and is a genuine build, not a cheap one: it must fully replace blueman's agent, because a missing agent is not a degraded state here, it is a broken one."
  decision: "A — accept it, on measured evidence, AND carry a hard constraint into the notification-server replacement. Option B (build a D-Bus agent) is the wrong investment once the delivery surface is understood."
  delivery_surface: "The prompt is NOT a foreign window. `org.blueman.general notification-daemon` is true, and BluezAgent._on_request_confirmation (BluezAgent.py:200-216) raises a Notification WITH `actions=`. SSP numeric comparison — the modern-phone case — therefore arrives as an ordinary desktop notification carrying Accept/Reject actions. It appeared upper-right because that is where notifications appear, not because a window escaped. This is materially unlike G-15-4, where nm-applet's GTK dialog was genuinely unthemed and unconditionally behind the layer-shell overlay."
  why_option_B_is_wrong: "Quickshell's own notification server (Quickshell.Services.Notifications) exposes `actions` per notification and `invoke` to fire one, plus appName/desktopEntry to identify the sender. Once the shell IS the notification daemon — which the planned swaync replacement implies — blueman's pairing confirmation arrives as a first-class Notification object the shell fully owns, and the shell can route it anywhere, including into the bluetooth panel. Containment then costs a routing rule, not a new daemon: no D-Bus agent, no separate process, no security-critical pairing-confirmation code. Building the agent now would be paying a large cost for something the notification work delivers as a side effect."
  scope_correction: "An earlier reading of this gap said option B required fully replacing blueman. That was too pessimistic. blueman's agent is ONE plugin (AuthAgent.py), declares no `__unloadable__ = False`, and unregisters cleanly in on_unload; PluginManager honours `gsettings set org.blueman.general plugin-list \"['!AuthAgent']\"` to disable just it, leaving the other 25 plugins (PulseAudioProfile for headset audio profiles, KillSwitch for rfkill, AutoConnect, PowerManager, OBEX transfer, PAN/DUN) running. The cost of B was overstated; it is still not worth paying, for the reason above."
  carry_forward_constraint: "BLOCKING REQUIREMENT ON THE SWAYNC REPLACEMENT — see deferred-items.md. blueman chooses its presentation by querying the daemon: Notification.py:295 falls back to a GTK dialog when `forced_fallback or 'body' not in caps or (actions and 'actions' not in caps)`. A notification server that does not declare BOTH `body` and `actions` in GetCapabilities silently pushes bluetooth pairing back onto an unthemed GTK dialog stuck behind the layer-shell panel — reintroducing the exact G-15-4 failure, and presenting as a bluetooth bug rather than a notification-server bug. Quickshell exposes `actionsSupported` for precisely this."
  options:
    - "A — accept the external prompt. Zero work, honest, and pairing keeps working. The panel is then not fully self-contained, which is the same standard G-15-4 was held to and failed."
    - "B — own the agent. Register a BlueZ org.bluez.Agent1 the panel controls, from a small D-Bus process or Quickshell.DBus/Process, since Quickshell.Bluetooth cannot. This is the only route that genuinely contains the prompt. It is the heavier of the two and is the same option that was REJECTED for wifi in G-15-4 on cost grounds — rejecting it there and accepting it here needs a deliberate reason."
    - "C — suppress blueman and register a NoInputNoOutput auto-accepting agent. Rejected on sight: it would silently auto-accept pairing requests, trading a cosmetic complaint for a real security regression."
  artifacts:
    - path: "quickshell/.config/quickshell/modules/dashboard/BluetoothBackend.qml"
      issue: "The five verbs are native and correct; there is no agent seam to add one to, because the platform exposes none"
    - path: "/etc/xdg/autostart/blueman.desktop"
      issue: "The autostart entry that puts the agent on the bus. 15-13 deliberately left this sibling unit generated when it suppressed nm-applet — that scoping was correct then and is the thing to revisit now."
  debug_session: ""

- gap_id: G-15-8
  truth: "After a failed pair, the user is given an explicit way to retry"
  status: resolved
  resolved_by: "commit 18da48c (inline fix — user chose to fix without a gap-closure plan)"
  resolved_at: 2026-08-02
  retest_result: "pass — verified against a REAL failure, not a simulated one. The no-agent pair during the G-15-7 measurement failed genuinely, and the user confirmed the Retry label appeared on the failed row. This is stronger evidence than the planned retest would have produced."
  reason: "User reported: if the pair fails, there is no explicit retry button"
  severity: minor
  test: 7
  root_cause: "Retry EXISTS but is invisible. The row stays pressable after a failure, and `handleRowPress()` (BluetoothPanel.qml:126-133) deliberately clears `failedAddress`/`failedReason` before re-invoking `pressDevice()` — the retry path is implemented and its comment describes exactly that intent. What is missing is any affordance saying so: the row renders `failedText` ('Couldn't pair', error colour, no auto-clear) and nothing else changes, so a failed row looks terminal rather than re-pressable. This is a discoverability defect, not a missing capability."
  note: "Cheapest honest fix is a retry affordance on the failed row rather than a new control elsewhere — the press target already exists and already does the right thing. Worth checking against WifiPanel's own failed-row treatment so the two panels teach the same idiom rather than diverging."
  artifacts:
    - path: "quickshell/.config/quickshell/modules/dashboard/BluetoothPanel.qml"
      issue: "L126-133 handleRowPress() already implements retry-on-press and clears the failure slot; L631-645 failedText renders the failure with no accompanying retry affordance"
  debug_session: ""

- gap_id: G-15-9
  truth: "A pair the user completes successfully is never rendered as a failure"
  status: open
  severity: minor
  test: 7
  kind: suspected — NOT yet measured, recorded so it is not lost
  observation: "The single 'Failed to pair' WARN in the log (quickshell.log:1919, from the user's FIRST pair attempt while blueman was still running) reads: 'Did not receive a reply. Possible causes include: ... the reply timeout expired ...'. The user's account matches — the first attempt failed, the retry succeeded."
  hypothesis: "`device.pair()` is a D-Bus method call whose reply only arrives AFTER the human confirms on blueman's external prompt. A typical D-Bus reply timeout (~25s) is shorter than realistic confirm-on-phone time, so a pair the user is in the middle of completing can time out at the call layer. The panel's own `pairWatchdogMs` is 90000ms and is NOT the culprit — it is comfortably long enough."
  why_not_asserted: "One log line and one user account. The library-level failure may not even reach the panel's `deviceActionFailed` seam (BluetoothBackend's own header notes the failure signal is INFERRED, since Quickshell.Bluetooth exposes none), so whether this renders as a user-visible false failure is unestablished."
  to_measure: "Pair a fresh peer with blueman running and deliberately wait ~30-40s before confirming on the phone. Observe whether the row renders 'Couldn't pair' while the bond still completes in the background — the false-negative case."
  coupling: "Moot if G-15-7 option B is taken — owning the agent removes the external round-trip that creates the delay."
  debug_session: ""
  reason: "User reported: Fail. It cannot detect my hidden network. I have one that I can test on if needed"
  severity: major
  test: 6
  supersedes_mechanism_of: G-15-4b
  prior_prediction: "15-14 shipped Route B (`nmcli device wifi rescan ssid <SSID>` → real Network object → existing flow) and explicitly recorded that it could NOT be proven, because no hidden SSID on this host was known and some APs do not answer directed probes. Route A was specified in advance as the documented fallback. This failure is that predicted branch being taken, not an unforeseen defect."
  measurement_now_possible: "The user has a real hidden network available to test against — the exact resource 15-14's Step Zero lacked. The blind spot that forced Route B to ship unproven is now closable by direct measurement."
  must_measure_before_fixing:

    - "Does `nmcli device wifi rescan ssid <SSID>` followed by `nmcli device wifi list` reveal the AP at all? This separates 'the AP does not answer directed probes' (Route B is dead, go Route A) from 'nmcli sees it but the panel's handoff never fires' (Route B is fine, the QML handoff is the bug)."
    - "If nmcli DOES reveal it: does the revealed AP appear in Quickshell's `wifiDevice.networks` with a non-blank SSID? Quickshell filters blank-SSID APs out entirely (15-14 measured 7 hidden APs in nmcli vs 0 in QML) — a revealed AP that stays blank-SSID to QML means the handoff can never find a receiver object regardless of probe success."
    - "Whether the panel's 8000ms probe watchdog is firing before the AP has time to materialise in QML's network list, which would produce this exact symptom even with a working probe."
  route_a_fallback_as_specified: "`nmcli device wifi connect <SSID> password <pw> hidden yes`, with the passphrase delivered via Process.stdinEnabled + write() against `nmcli --ask` so it never reaches argv (/proc/PID/cmdline is world-readable — Prohibition P3). Needs a new error mapping because nmcli returns exit codes + stderr rather than the ConnectionFailReason enum the panel's row-scoped copy is wired to."
  root_cause: "A race in the panel's own handoff, NOT a Route B failure. `tryHiddenHandoff()` has exactly one caller — `hiddenRescanProcess.onExited` (WifiPanel.qml:309) — which fires 16-30ms after the probe process starts (measured three times: 30/16/16ms, matching 15-14's own ~16ms Step Zero figure). At that instant the scan has not completed and the network list is unchanged, so the search loop finds nothing and returns. It is never called again: no Connections block re-invokes it on a list change (WifiPanel's two blocks target onPanelOpenChanged:209 and onConnectFailed:454). The 8000ms hiddenProbeTimer then fires and renders 'No network answered to that name'. The watchdog owns the verdict; NOTHING owns the retry. This is deterministic — no hidden network can ever be found through this path, on any host, however well it answers."
  route_b_proven_viable: "MEASURED AGAINST THE USER'S OWN HIDDEN AP (SSID `!ono^`). (1) `nmcli device wifi rescan ssid` reveals it — BSSID CC:BA:BD:95:84:B2 gains the name (and the old blank entry lingers alongside, so the reveal ADDS an entry rather than mutating one). (2) Quickshell sees it as an ordinary named Network object: a standalone probe shell using WifiBackend.qml:47-54's own DeviceType.Wifi accessor reported `total=14`, `ssid=[!ono^]`, `blank_ssid_count=0`. So tryHiddenHandoff()'s `nets[i].name === hiddenSsid` comparison WOULD match it. The mechanism 15-14 chose is correct and must NOT be replaced."
  prediction_falsified: "15-14 pre-specified Route A as the fallback on the assumption that failure here would mean the AP does not answer directed probes. Measured false on this host. Switching to Route A would rebuild a working mechanism for no reason, and is strictly worse — it duplicates the connect verb, puts the passphrase on argv unless mitigated with Process.stdinEnabled + `nmcli --ask`, and needs a whole new error mapping because nmcli returns exit codes/stderr instead of the ConnectionFailReason enum the row-scoped copy is wired to."
  artifacts:

    - path: "quickshell/.config/quickshell/modules/dashboard/WifiPanel.qml"
      issue: "L309 — tryHiddenHandoff() called only from hiddenRescanProcess.onExited, 16-30ms after the probe starts, and never retried. This is the defect."

    - path: "quickshell/.config/quickshell/modules/dashboard/WifiPanel.qml"
      issue: "L189-203 — hiddenProbeTimer's 8000ms ceiling is shorter than the measured reveal latency, so it would fire early even once the retry is fixed"

    - path: "quickshell/.config/quickshell/modules/dashboard/WifiPanel.qml"
      issue: "L240-250 — startHiddenProbe() fires exactly ONE probe; a single probe was measured insufficient (12s of polling after one probe showed nothing; repeated probes revealed it)"

    - path: "quickshell/.config/quickshell/modules/dashboard/WifiBackend.qml"
      issue: "L244 — the existing Connections block on wifiDevice.networks is the house precedent for the missing retry trigger (15-11 used the same observable for its rescan edge). Not a defect — the reuse."
  missing:

    - "Re-invoke tryHiddenHandoff() on the real results-landed observable (wifiDevice.networks valuesChanged), gated on hiddenProbing — the trigger 15-11 already established"
    - "Re-probe periodically during the in-flight window instead of probing once; the directed rescan is fire-and-forget, carries no secret and costs ~16ms"
    - "Raise hiddenProbeMs above the measured reveal latency — still a logic timeout, so `interval:` and never a motion `duration:` (the existing comment is correct and must stay correct)"
    - "Do NOT switch to Route A; keep it documented as the fallback it already is"
    - "Confirm the lingering duplicate blank-SSID entry for the same BSSID does not leave a stale duplicate row in the panel's list after a successful hidden join"
  eliminated:

    - "'The AP does not answer directed probes' — FALSE, measured. It answers and NM surfaces the name."
    - "'Quickshell filters the revealed AP as blank-SSID' — FALSE, measured. blank_ssid_count=0 and the SSID is present as an ordinary object."
    - "'The SSID's punctuation (! and ^) breaks the argv or comparison path' — no evidence. The command is fixed-argv (WifiPanel.qml:248) so no shell parses it, and the name round-tripped through nmcli and QML intact."
  residual_unknown: "Exact cold-cache reveal latency for a SINGLE probe was not pinned down — the revealed entry stayed in NM's scan cache for 180s+ without aging out, so the cold-start condition could not be re-created at diagnosis time. The fix is therefore robust to a long, variable reveal (retry on list change + periodic re-probe) rather than tuned to a specific number."
  fix_applied: "12575ac — fixed inline at the user's request (no gap-closure plan). Three changes to WifiPanel.qml: (1) a Connections block on wifiDevice.networks onValuesChanged re-invokes tryHiddenHandoff(), the retry that closes the race; (2) hiddenReprobeTimer re-issues the same fixed-argv, secret-free directed probe every 4000ms while the window is open, because one probe was measured insufficient; (3) hiddenProbeMs raised 8000 -> 30000, above the measured reveal latency. The pulse stops on handoff, Cancel, clearHiddenForm() and watchdog expiry."
  fix_verified: "Static and structural only — the click path still cannot be driven on this host (no synthetic pointer tool). Proven: motion-lint 107 passed / 0 failed (the new timers are `interval:` logic timeouts, correctly outside CHECK B); qmllint reports no syntax errors; the shell reloads with exactly one instance and a clean log; the wifi panel mounts with no runtime error. Critically, the new Connections binding was proven NON-INERT by a standalone probe replicating its exact target expression — `target_is_null=false` and `onValuesChanged` fired 14 times as the list churned. A null target would have been silently inert with no warning, which would have left the fix doing nothing."
  awaiting: "User retest against the real hidden AP. The reveal from the diagnosis session has since aged out (confirmed: a later probe shell saw ono_present=false), so the retest is a genuine cold test rather than one riding a warm cache."
  debug_session: ".planning/debug/wifi-hidden-network-not-detected.md"
