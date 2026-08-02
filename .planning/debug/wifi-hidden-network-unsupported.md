---
status: diagnosed
trigger: "add an option to add a hidden wifi network (a network has it's SSID broadcast turned off)"
created: 2026-08-02T19:00:00Z
updated: 2026-08-02T19:10:00Z
---

## Current Focus

kind: feature-request (scoping investigation, NOT a fault diagnosis)
bug_class: n/a — feature absent, never implemented

finding: The blocker is not UI effort. `Quickshell.Networking` structurally cannot
express a hidden network: every connect verb is an instance method on a `Network`
object, and quickshell exposes ZERO objects for hidden APs. A subprocess is
unavoidable. Two routes identified; one preserves the entire existing flow.

next_action: Return diagnosis. Do not implement.

## Symptoms

expected: The wifi panel offers a way to join a hidden network — the user supplies the SSID manually plus security type and passphrase.
actual: "add an option to add a hidden wifi network (a network has it's SSID broadcast turned off)". No such affordance exists.
errors: None reported
reproduction: Test 4 in .planning/phases/15-audio-connectivity-panels/15-UAT.md — open the wifi panel; there is no hidden-network entry point.
started: Requested during UAT of phase 15 (audio-connectivity-panels). Never specified, never planned, never built.

## Eliminated

- hypothesis: "The native Quickshell.Networking API can do this and it just wasn't wired up."
  evidence: "grep -i hidden over /usr/lib/qt6/qml/Quickshell/Networking/quickshell-network.qmltypes returns ZERO hits. Live runtime member enumeration of a real Network object returns: objectName,name,device,nmSettings,connected,known,state,stateChanging,signalStrength,security,connect,connectWithSettings,disconnect,forget,connectWithPsk — no factory, no SSID setter, no hidden flag. WifiNetwork is isCreatable:false."
  timestamp: 2026-08-02

- hypothesis: "connectWithSettings(NMSettings) is the escape hatch — build an NMSettings with hidden=yes."
  evidence: "NMSettings appears in the qmltypes ONLY as a parameter type and as QList<NMSettings*> on the read-only nmSettings property. There is no Component block exporting it, so it is not a registered QML type and cannot be constructed. It is obtainable only read-only from an existing network's saved profiles. Independently moot: connectWithSettings is still an instance method needing a Network receiver, which does not exist for a hidden AP."
  timestamp: 2026-08-02

- hypothesis: "Hidden APs already appear as blank-named rows in the panel (an adjacent cosmetic bug)."
  evidence: "Live probe measured BLANK_SSID_COUNT = 0. Quickshell filters blank-SSID APs out of wifiDevice.networks entirely. No blank rows render. Good news cosmetically, fatal for the feature — there is no receiver object."
  timestamp: 2026-08-02

## Evidence

- timestamp: 2026-08-02
  checked: "Whether 'hidden' was ever specified in phase 15 (grep -i hidden over 15-RESEARCH.md, 15-CONTEXT.md, 15-UI-SPEC.md)"
  found: "Every hit is the UNRELATED D-15-22 sense ('never a silently hidden button', about the Advanced button's disabled treatment). SSID-broadcast hiding appears nowhere in any phase-15 artifact."
  implication: "Confirms feature-absent. Not a regression, not a dropped requirement — never in scope."

- timestamp: 2026-08-02
  checked: "Live: nmcli device wifi list vs the quickshell Networking model, same moment (throwaway quickshell -p probe)"
  found: |
    nmcli sees 5 hidden APs (SSID column '--'):
      CC:BA:BD:95:84:B0  signal 97   WPA2
      CC:BA:BD:95:84:B2  signal 94   WPA2
      CE:BA:BD:75:84:B0  signal 94   WPA2
      CE:BA:BD:25:84:B0  signal 92   WPA2
      94:28:6F:3B:ED:C3  signal 35   WPA2
    quickshell probe at the same moment: total networks = 8, BLANK_SSID_COUNT = 0
    (go-jo, TONLY_TAP_9943D1C, WE_BMNNB, WE_154B4F, QWIDER_New, WE_D30CAB, go-jo_2.5g, WE_190BA1)
  implication: "DECISIVE. The strongest APs on this band are hidden and quickshell shows none of them. There is no Network object to call connect/connectWithPsk/connectWithSettings on. The native path is a hard dead end, measured not inferred. Also confirms quickshell groups APs by SSID (nmcli's 18 BSSID rows collapse to 8 named networks)."

- timestamp: 2026-08-02
  checked: "How the panel currently connects (WifiBackend.qml:246 connect())"
  found: "Native Quickshell.Networking only — network.connectWithPsk(psk) when psk non-empty, else network.connect(). WifiBackend.qml's own header states it 'needs no subprocess, no parser and no timer at all'. The ONLY subprocess in the whole wifi surface is the `which nm-connection-editor` probe, and it lives in WifiPanel.qml:62 not the backend — deliberately, with the rationale recorded at WifiPanel.qml:51-59 ('generic host-binary detection, not a networking read')."
  implication: "A shell-out for hidden networks is an architectural deviation from the backend's stated design, but WifiPanel.qml already has both the Process import and an established precedent for housing a subprocess in the panel file."

- timestamp: 2026-08-02
  checked: "nmcli 1.58.0 man page, hidden-network support"
  found: |
    line 1453: wifi connect (B)SSID [password <pw>] [wep-key-type ...] [ifname ...] [bssid ...] [name ...] [private yes|no] [hidden yes|no]
    line 1499-1503: 'hidden — set to yes when connecting for the first time to an AP not broadcasting its SSID. Otherwise, the SSID would not be found and the connection attempt would fail.'
    line 1456: 'only open, WEP and WPA-PSK networks are supported if no previous connection exists'
    line 1554-1557: 'wifi rescan [ifname] [ssid SSID...] — By using ssid, it is possible to scan for a specific SSID, which is useful for APs with hidden SSIDs.'
  implication: "Two distinct routes exist. The rescan-with-ssid form is a DIRECTED PROBE that carries no secret. nmcli's own new-profile limitation (open/WEP/WPA-PSK only) independently matches the panel's existing enterprise fence."

- timestamp: 2026-08-02
  checked: "Directed rescan accepted on this host; hidden profile property exists (read-only checks)"
  found: "`nmcli device wifi rescan ssid \"GSD-PROBE-NONEXISTENT-SSID\"` exits 0 in 14ms. `nmcli -f 802-11-wireless.hidden connection show go-jo` reads `no` — the property exists and is settable via connection modify."
  implication: "Route B's first step is available. But a profile created from a revealed AP defaults to hidden:no, which breaks autoconnect on a later boot (passive scan won't find it) — Route B needs a secret-free follow-up `nmcli connection modify <name> 802-11-wireless.hidden yes`."

- timestamp: 2026-08-02
  checked: "Quickshell Process stdin capability (quickshell-io.qmltypes)"
  found: "Process exposes stdinEnabled (read/write, line 131) and write(QString) (line 188), plus startDetached()."
  implication: "If a shell-out must carry the passphrase, `nmcli --ask` + stdin is available and avoids /proc/PID/cmdline argv exposure. Relevant to Prohibition P3."

- timestamp: 2026-08-02
  checked: "Existing inline-expansion + reuse inventory in WifiPanel.qml"
  found: "passwordRow (:675) inside the NetworkRow component (:429), gated on isExpanded (root.expandedNetwork === networkRow.network). TextField at :681 is one of only TWO TextFields in the entire shell (the other is Probe.qml, a throwaway harness) — there is no shared text-input component. connectAction pill at :710, pendingGlyph pulse at :564, Cancel at :618, rowFailureText at :749, GroupHeader at :389, Behavior on implicitHeight at :456."
  implication: "Rich reuse surface, but EVERY pending/expanded/failed property is keyed by network OBJECT identity (deliberately, per WifiPanel.qml:95-99 'keyed by the network OBJECT, never an SSID string (T-15-08)'). A hidden entry has no object, so it cannot slot into any of them."

- timestamp: 2026-08-02
  checked: "Structural precedent for an entry-point affordance inside a panel list (BluetoothPanel.qml:739)"
  found: "discoverySection — an Item of FIXED height (root.iconSizeMd) holding two mutually-exclusive states (discoveryIdleRow with a Colours.primary 'Add device' text + MouseArea; discoveryActiveRow with the progress line + Stop). Header note at :734-738: fixed height 'so switching between them never moves the rows above or below'."
  implication: "This is the exact structural template for a 'Join hidden network' entry point. Same phase, same author, same idiom — a planner should copy this shape rather than invent one."

- timestamp: 2026-08-02
  checked: "Coupling with sibling gap G-15-4 (.planning/debug/wifi-wrong-password-external-dialog.md, now status: diagnosed)"
  found: "nm-applet PID 1018 is the SOLE registered NM secret agent. NetworkManager does NOT fail an activation on a PSK mismatch — it re-enters need-auth and issues GetSecrets to that agent, which pops the GTK dialog. Quickshell.Networking exposes no secret-agent API. Recorded blind spot: 'what NM emits when NO agent is registered at all' is unmeasured."
  implication: "The hidden flow terminates in a NetworkManager activation on BOTH routes, so it inherits the identical wrong-password behavior. Risk is structurally HIGHER here — the user types SSID *and* passphrase from memory, and a wrong SSID on a hidden network is indistinguishable from an out-of-range AP. G-15-4's mechanism decision must precede or accompany this feature."

## Resolution

root_cause: |
  Feature absent — never implemented. SSID-broadcast hiding appears in no phase-15
  artifact; it was never specified, planned, or built.

  The non-obvious part, and the real cost driver: this is NOT a UI-only addition.
  Quickshell.Networking cannot express a hidden network at all. Every connect verb
  (connect / connectWithPsk / connectWithSettings) is an instance method on a
  Network object; quickshell filters blank-SSID APs out of wifiDevice.networks, so
  a hidden AP yields no object to call anything on (measured: 5 hidden APs visible
  to nmcli, BLANK_SSID_COUNT = 0 in quickshell, same moment). NMSettings is not a
  registered QML type and cannot be constructed. Therefore a subprocess is
  unavoidable — a first for WifiBackend.qml, which is explicitly subprocess-free.

fix: |
  NOT APPLIED — diagnose-only mode (goal: find_root_cause_only).

  Recommended direction for the planner (Route B, with Route A as proven fallback):
    B1. `nmcli device wifi rescan ssid <SSID>` — directed probe, carries NO secret
    B2. hidden AP responds -> materializes as a real Network object -> the ENTIRE
        existing flow (expandedNetwork, passwordRow, startConnect, pending pulse,
        Cancel, connectFailed row-scoped copy, Forget) works unchanged
    B3. `nmcli connection modify <name> 802-11-wireless.hidden yes` — secret-free,
        makes reconnect durable across boots
  Route B keeps connectWithPsk as the single connect call site, keeps Prohibition
  P3 fully intact (passphrase never leaves the QML process), and reuses the
  existing ConnectionFailReason error mapping.

  MUST be a Step Zero in any plan: Route B is UNPROVEN end-to-end on this host
  because no hidden SSID here is known (that is the nature of hidden). Some APs are
  configured not to answer directed probes, in which case Route B fails where
  Route A succeeds.

  Route A fallback: `nmcli device wifi connect <SSID> password <pw> hidden yes` —
  guaranteed to work, but duplicates the connect verb, puts the passphrase on argv
  (world-readable /proc/PID/cmdline, violates P3 unless routed through
  Process.stdinEnabled + `nmcli --ask`), and needs a NEW error mapping since nmcli
  returns exit codes + stderr rather than a ConnectionFailReason enum.

verification: N/A — diagnose-only. No code changed.
files_changed: []
