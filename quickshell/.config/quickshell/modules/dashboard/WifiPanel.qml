// WifiPanel.qml — the wifi panel body (Phase 15 Plans 03 and 05,
// PANEL-03/PANEL-06). Root type `PanelDialog`, mirroring `AudioPanel.qml`'s
// own shape so all three panel instances read as one component with three
// contents (PANEL-06) — same frame, same header band, same dismissal set.
//
// 15-03 shipped the two D-15-26 off-state branches and the real, empty,
// scrollable body slot only. 15-05 (this plan, Task 2) fills that slot: the
// scan in-progress line, the refresh control, and the grouped stable list
// with its focal current-connection row. Task 3 adds the row verbs, the
// inline password flow, in-flight/failure and Forget.
//
// ── Hierarchy pattern mirrored from 15-04's render-gate fix (binding,
//    15-05-PLAN.md's inherited contract) ────────────────────────────────
// 15-04's audio panel render gate FAILED on a missing pinned/list boundary
// marker and an under-weighted primary control; the fix — an
// outline-hairline-plus-label boundary and extra weight on the panel's own
// primary control — was declared the pattern every later panel in this
// phase must mirror against its OWN primary control and its OWN list. This
// panel has no separate pinned block (D-15-16 achieves the same focal-point
// effect through ORDERING, not a non-scrolling region — UI-SPEC's own
// per-panel-focal-point table names "the current-connection row at the top
// of the grouped list" as this panel's focal point), so the pattern is
// realized wifi-natively: the current-connection row IS the weighted
// primary control (a `Colours.surfaceVariant` fill the other groups do not
// carry), and the hairline-plus-label boundary marker is applied between
// EVERY group transition (Saved, Other networks) rather than once, since
// this list has more than one internal boundary to name.
import QtQuick
import QtQuick.Controls
import Quickshell.Io
import Quickshell.Networking
import "../"

PanelDialog {
    id: root

    property var backend: null

    panelTitle: "Wi-Fi"
    panelGlyph: "wifi"
    namespaceSuffix: "wifi-panel"

    // T-15-02's mitigation, same discipline as AudioPanel.qml's
    // advancedCommand: a literal array of double-quoted string literals,
    // assigned exactly once. Never appended to, never interpolated, never
    // joined into a string, never handed to a shell interpreter.
    advancedCommand: ["nm-connection-editor"]
    advancedAvailable: root._nmConnectionEditorAvailable
    advancedUnavailableReason: "nm-connection-editor is not installed"

    // ── D-15-22 availability probe — the same mechanism AudioBackend.qml
    //    built for pavucontrol (a fully literal fixed argv, zero
    //    interpolated elements, started once, fail OPEN so a probe that
    //    cannot run at all never hides a working button). Housed in the
    //    PANEL file rather than WifiBackend.qml because that file is
    //    deliberately subprocess-free (RESEARCH Pitfall 1's networking
    //    surface has no CLI dependency at all) — this probe is generic
    //    host-binary detection, not a networking read, so it does not
    //    belong on the networking adapter. ───────────────────────────────
    property bool _nmConnectionEditorAvailable: true

    Process {
        id: nmConnectionEditorProbe
        command: ["which", "nm-connection-editor"]
        onExited: function (exitCode, exitStatus) {
            if (exitCode !== 0)
                root._nmConnectionEditorAvailable = false;
        }
    }
    Component.onCompleted: nmConnectionEditorProbe.running = true

    // ── D-15-26 branch selection — unfixable checked first so it always
    //    wins when both would otherwise apply. Both backend reads are
    //    null-guarded even though `backend` is always set by shell.qml, so
    //    this file never assumes what it cannot verify locally. ──────────
    readonly property bool radioBlockedBranch: !(root.backend && root.backend.wifiHardwareEnabled)
    readonly property bool radioOffBranch: !root.radioBlockedBranch && !(root.backend && root.backend.wifiEnabled)
    // 15-02's four-name vocabulary — both off branches are "empty", the
    // real body slot is "populated". No fifth state name.
    readonly property string panelState: (root.radioBlockedBranch || root.radioOffBranch) ? "empty" : "populated"

    // The body area's own height, computed from the frame's own constants
    // rather than reaching into PanelDialog's private `bodyFlick` id (out
    // of this file's scope) — lets each branch composition centre itself
    // within the panel's real available body region instead of merely its
    // own intrinsic size.
    readonly property int bodyAreaHeight: root.panelHeight - root.headerHeight - (root.panelPadding * 2)

    // Matches AudioPanel.qml's own constant name and value — every
    // interactive row across the three panels shares one row-height token.
    readonly property int controlRowHeight: 32

    // ═══════════════════════════════════════════════════════════════════
    // Task 3 additions (D-15-14/D-15-17/D-15-09) — the inline password row,
    // in-flight Cancel, row-scoped failure copy and Forget's inline
    // confirm. Every property below is keyed by the network OBJECT, never
    // an SSID string (T-15-08) — two rows sharing an SSID must never act
    // on each other.
    // ═══════════════════════════════════════════════════════════════════

    // Which row's password field is expanded (D-15-14). Set by a press on
    // a passphrase-secured row, or by a `NoSecrets` failure on an open/
    // unknown row that turned out to need one (Task 1's `securityKind`
    // maps `Unknown` to "open" on purpose — this is what recovers it).
    property var expandedNetwork: null
    // The row-scoped copy of the backend's in-flight identity. Kept as its
    // OWN property rather than binding straight to `backend.connectingNetwork`
    // so the watchdog below can clear the panel's visual pending state
    // without needing to reach into the backend's own truth-driven property.
    property var pendingNetwork: null
    // The row a rejected connection is scoped to (D-15-09) — never a
    // panel-wide flag.
    property var failedNetwork: null
    property string failedText: ""
    // Which row's inline "Forget X?" confirm is showing (P4) — deliberately
    // a SEPARATE property from `expandedNetwork`: Forget's confirm and the
    // password field are two independent expansions of the same row, not
    // one mechanism wearing two hats.
    property var confirmForgetNetwork: null

    // ═══════════════════════════════════════════════════════════════════
    // G-15-4b gap closure (15-14) — hidden-network join.
    //
    // WHY THESE FOUR ARE DELIBERATELY *NOT* OBJECT-KEYED, and why that is
    // not a relaxation of T-15-08:
    //
    // T-15-08 exists because two rows can share an SSID, so acting on a
    // string could act on the wrong row. A hidden network has NO ROW and
    // NO OBJECT to key against — that is the entire problem. Quickshell
    // filters blank-SSID access points out of `wifiDevice.networks`
    // entirely, so there is no receiver object to call any connect verb
    // on. Measured on this host at one moment: `nmcli` saw 7 hidden access
    // points while a quickshell probe reported a blank-SSID count of 0.
    //
    // So these four are a SEPARATE, parallel state machine that exists
    // only for the window between "user typed a name" and "a real network
    // object appeared". None of the object-keyed properties above may be
    // reused for them, and nothing outside the hidden form may read or
    // write them. The moment an object appears, this state is cleared and
    // the existing object-keyed flow owns everything from there.
    // ═══════════════════════════════════════════════════════════════════
    property bool hiddenFormOpen: false
    property string hiddenSsid: ""
    property bool hiddenProbing: false
    property string hiddenFailedText: ""

    // Which SSID arrived via the hidden path, so the durability follow-up
    // fires ONLY for those and never for an ordinary row's connect. A
    // saved profile reads `802-11-wireless.hidden: no` by default
    // (measured on this host's existing profile, 2026-08-02) — which is
    // exactly why the follow-up is mandatory rather than optional: without
    // it the network connects once and never reconnects on its own.
    property string hiddenPendingSsid: ""

    // Sized against the scan envelope this phase already measured: first
    // results land 300ms–1.5s after a scan begins, and the list is still
    // growing 4.5s later. Too short reports not-found for a network that
    // was about to appear; too long leaves the user on a spinner. Not a
    // motion token — a logic timeout, so `interval:`, never `duration:`
    // (a duration token collapses to zero at the `off` motion scale),
    // matching `rowWatchdogMs` above.
    readonly property int hiddenProbeMs: 8000

    // Backend watchdog — a stranded pending row must not pulse forever if
    // NetworkManager never answers either way. Not a motion token (would
    // collapse to zero at the `off` motion scale): a `Timer` `interval:`,
    // matching QuickToggles.qml's own `chipWatchdogTimer` shape, never
    // `duration:` so it stays outside motion-lint CHECK B.
    readonly property int rowWatchdogMs: 15000

    Timer {
        id: rowWatchdogTimer
        interval: root.rowWatchdogMs
        repeat: false
        // 15-14: also clears the hidden pending state. This is
        // BELT-AND-BRACES, not the primary mechanism — `hiddenProbeTimer`
        // below owns the probe window. This branch covers the different
        // case where a hidden-found network's own connect strands AFTER
        // the handoff, at which point the probe timer is already stopped
        // and only this one is still armed. The two are not redundant.
        onTriggered: {
            root.pendingNetwork = null;
            root.hiddenPendingSsid = "";
        }
    }

    // ── 15-14: the probe window (primary mechanism for the hidden form) ──
    Timer {
        id: hiddenProbeTimer
        interval: root.hiddenProbeMs
        repeat: false
        onTriggered: {
            if (!root.hiddenProbing)
                return;
            root.hiddenProbing = false;
            // Honest about a real ambiguity this feature cannot resolve:
            // with a non-broadcast network, a mistyped name and an
            // out-of-range access point are genuinely indistinguishable
            // from here. Asserting either cause would be a guess rendered
            // as a fact. The field stays open and populated for
            // correction — the same retry posture the password row takes.
            root.hiddenFailedText = "No network answered to that name";
        }
    }

    // All hidden state clears when the panel closes, so a dismissed panel
    // leaves nothing stranded for the next open — the same discipline
    // 15-11's rescan edge follows.
    Connections {
        target: root.backend
        function onPanelOpenChanged() {
            if (root.backend && !root.backend.panelOpen) {
                root.clearHiddenForm();
                root.hiddenPendingSsid = "";
            }
        }
    }

    // ── 15-14: hidden-form lifecycle ─────────────────────────────────────
    function clearHiddenForm() {
        // SSID, pending flag and failure copy clear TOGETHER, so reopening
        // never shows the previous attempt's residue.
        root.hiddenFormOpen = false;
        root.hiddenSsid = "";
        root.hiddenProbing = false;
        root.hiddenFailedText = "";
        hiddenProbeTimer.stop();
    }

    function openHiddenForm() {
        // Mirrors how pressing Forget already clears the expanded row: two
        // expansions of the same list must never be open at once.
        root.collapseExpandedRow();
        root.confirmForgetNetwork = null;
        root.hiddenFailedText = "";
        root.hiddenFormOpen = true;
    }

    function startHiddenProbe() {
        if (root.hiddenSsid.length === 0)
            return;
        root.hiddenFailedText = "";
        root.hiddenProbing = true;
        // Assigned in ONE place. Every element is a literal except
        // exactly one carrying the typed SSID — the array form is what
        // makes an SSID containing spaces, quotes, a semicolon or a
        // leading dash inert, because no shell ever parses it.
        hiddenRescanProcess.command = ["nmcli", "device", "wifi", "rescan", "ssid", root.hiddenSsid];
        hiddenRescanProcess.running = true;
        hiddenProbeTimer.restart();
    }

    // The handoff — the whole point of this design. The typed SSID is used
    // EXACTLY ONCE, here, to locate a real network object. Everything
    // after this line is object-keyed, so this is not a relaxation of
    // T-15-08. From the handoff on, the existing flow owns everything:
    // the password row opens on a real row, `startConnect` runs the single
    // native passphrase call, the pending pulse and Cancel work, and a
    // failure renders through the mapping 15-13 corrected. There is no
    // parallel connect path, no parallel pending glyph and no parallel
    // failure text for the connected case anywhere in this file.
    function tryHiddenHandoff() {
        if (!root.hiddenProbing || root.hiddenSsid.length === 0 || !root.backend)
            return;
        // Both collections, saved first — a hidden network the user has
        // joined before already has a profile and lands in `savedNetworks`.
        var groups = [root.backend.savedNetworks, root.backend.otherNetworks];
        for (var g = 0; g < groups.length; g++) {
            var nets = groups[g];
            if (!nets)
                continue;
            for (var i = 0; i < nets.length; i++) {
                if (nets[i] && nets[i].name === root.hiddenSsid) {
                    var found = nets[i];
                    var ssid = root.hiddenSsid;
                    hiddenProbeTimer.stop();
                    root.clearHiddenForm();
                    root.hiddenPendingSsid = ssid;
                    root.expandedNetwork = found;
                    return;
                }
            }
        }
    }

    // ── 15-14 subprocess exception (Prohibition P1) ──────────────────────
    // `Quickshell.Networking` structurally CANNOT express a hidden
    // network: every connect verb is an instance method on a `Network`
    // object, and blank-SSID access points are filtered out of
    // `wifiDevice.networks` entirely, so there is no receiver to call
    // anything on. `grep -i hidden` over the installed networking
    // qmltypes returns zero hits; `NMSettings` is not a registered QML
    // type and cannot be constructed; `connectWithSettings` is still an
    // instance method needing the receiver that does not exist. A
    // subprocess is therefore unavoidable — a first for this surface.
    //
    // It stays confined to THIS panel file. `WifiBackend.qml` remains
    // subprocess-free and keeps the single native passphrase call site.
    // NO SECRET is passed to either process below: the directed rescan
    // carries only a name, and the durability follow-up carries only a
    // profile field. The passphrase never leaves the native path.
    Process {
        id: hiddenRescanProcess
        onExited: function (exitCode, exitStatus) {
            // A directed rescan is a PROBE, not a query — measured on this
            // host at exit 0 in ~16ms for both a present and an absent
            // SSID. A non-answer is not an error, so the exit code is not
            // rendered; the probe watchdog owns the not-found verdict.
            root.tryHiddenHandoff();
        }
    }

    // The durability follow-up. A profile created through this path reads
    // `802-11-wireless.hidden: no` by default (measured), which means the
    // network connects once and then never reconnects on its own. Same
    // fixed-argv discipline, same no-shell rule, still no secret.
    Process {
        id: hiddenMarkProcess
        onExited: function (exitCode, exitStatus) {
            // A failure here is NOT a connection failure and must not
            // render as one — the network is connected. But it must not be
            // swallowed either: the user needs to learn it will not
            // reconnect on its own.
            if (exitCode !== 0)
                root.hiddenFailedText = "Connected, but it may not reconnect on its own";
        }
    }

    // ── Escape's first stage (D-15-14) ────────────────────────────────────
    function collapseExpandedRow() {
        root.expandedNetwork = null;
        root.failedNetwork = null;
        root.failedText = "";
    }

    // ── Belt-and-braces override of PanelDialog's `handleEscape()` (no
    //    edit to that shared file — see its own header note inviting
    //    exactly this override). The field's own `Keys.onEscapePressed`
    //    already delivers the required two-stage behaviour by consuming
    //    the first Escape before it ever reaches this function; this is
    //    redundancy for the case where a row is expanded but the field
    //    itself does not hold active focus. ─────────────────────────────
    function handleEscape() {
        if (root.expandedNetwork !== null) {
            root.collapseExpandedRow();
            return;
        }
        if (root.confirmForgetNetwork !== null) {
            root.confirmForgetNetwork = null;
            return;
        }
        // 15-14: third stage, added BEFORE the dismiss and AFTER both
        // existing branches. Ordering is the whole risk here — the user
        // explicitly confirmed two-stage Escape working during UAT, and a
        // regression there would be a new failure introduced by a feature
        // nobody asked to change it. Neither branch above was reordered,
        // merged or reworded. Like them, this is redundancy for the case
        // where the form is open but its field does not hold active focus;
        // the field's own `Keys.onEscapePressed` is what normally consumes
        // the first press.
        if (root.hiddenFormOpen) {
            root.clearHiddenForm();
            return;
        }
        root.requestDismiss();
    }

    // ── The row's press, by state (D-15-14) ───────────────────────────────
    function rowVerbLabel(network) {
        if (!network)
            return "";
        if (network.connected)
            return "Disconnect";
        if (root.backend && root.backend.securityKind(network) === "enterprise")
            return "";
        return "Connect";
    }

    function handleRowPress(network) {
        if (!network || !root.backend)
            return;
        root.confirmForgetNetwork = null;
        if (network.connected) {
            // Ordinary reversible action — deliberately not error-toned
            // (UI-SPEC Color table: Destructive is reserved for Forget and
            // the failed-state text, never Disconnect).
            root.backend.disconnect(network);
            return;
        }
        var kind = root.backend.securityKind(network);
        if (kind === "enterprise")
            return; // P2: never offer a control that cannot work.
        if (kind === "passphrase") {
            root.expandedNetwork = network;
            root.failedNetwork = null;
            root.failedText = "";
            return;
        }
        root.startConnect(network, "");
    }

    // ── In-flight (UI-SPEC E4 `loading`) ──────────────────────────────────
    function startConnect(network, password) {
        if (!network || !root.backend)
            return;
        root.pendingNetwork = network;
        root.failedNetwork = null;
        root.failedText = "";
        rowWatchdogTimer.restart();
        // The passphrase is read from the live control at press time by
        // the caller and handed straight through — never copied into a
        // property on this panel, never logged (this file has no
        // diagnostic logging call at all).
        root.backend.connect(network, password);
    }

    // Measured live in Task 3 (see SUMMARY): whichever teardown call
    // actually aborts the pending activation, `cancelConnect()` is the
    // panel's one call site for it either way, so the finding can be
    // acted on in one place if it changes.
    function handleCancel(network) {
        if (!root.backend)
            return;
        root.backend.cancelConnect(network);
        root.pendingNetwork = null;
        rowWatchdogTimer.stop();
    }

    // Success is OBSERVED truth (a row's own `connected` becoming true),
    // never the write merely returning — called from NetworkRow's own
    // `onIsConnectedNowChanged` handler below, mirroring WifiBackend's own
    // truth-driven pattern rather than guessing from the backend's
    // `connectingNetwork` clearing (which also clears on failure, and
    // would race `connectFailed` if used as a success signal here).
    function markConnectedIfPending(network) {
        if (root.pendingNetwork === network) {
            root.pendingNetwork = null;
            root.expandedNetwork = null;
            rowWatchdogTimer.stop();
            // 15-14 durability follow-up — fires ONLY for a network that
            // arrived through the hidden path, never for an ordinary row's
            // connect. Without it the profile keeps its measured default
            // (`802-11-wireless.hidden: no`) and the network connects once
            // and then never reconnects on its own.
            if (root.hiddenPendingSsid.length > 0 && network && network.name === root.hiddenPendingSsid) {
                hiddenMarkProcess.command = ["nmcli", "connection", "modify", root.hiddenPendingSsid, "802-11-wireless.hidden", "yes"];
                hiddenMarkProcess.running = true;
                root.hiddenPendingSsid = "";
            }
        }
    }

    // ── Failure, row-scoped (D-15-09, UI-SPEC E3/E4 `error`) ──────────────
    Connections {
        target: root.backend
        function onConnectFailed(network, reasonText) {
            var wasExpanded = (root.expandedNetwork === network);
            root.pendingNetwork = null;
            rowWatchdogTimer.stop();
            root.failedNetwork = network;
            root.failedText = reasonText;
            // The no-secrets copy is never spelled out here — the panel
            // compares against the backend's own locked mapping output
            // rather than restating the string, so the five failure
            // strings live in exactly one place (WifiBackend.qml).
            //
            // G-15-4 (15-13): the second argument is now passed
            // EXPLICITLY as false, so this comparison means what it says —
            // "the string the backend renders when NO passphrase was
            // supplied". Without it, the same NoSecrets reason that now
            // maps to the rejected-passphrase copy would still match here,
            // and a rejected passphrase would re-open the field as though
            // the user had never entered one.
            if (!wasExpanded && root.backend && reasonText === root.backend.failReasonText(ConnectionFailReason.NoSecrets, false))
                root.expandedNetwork = network;
        }
    }

    // ── strengthGlyph(network) — the never-sorting strength glyph
    //    (D-15-16: rendered per row, takes no part in ordering). Uses the
    //    SAME ligature name at every strength ("network_wifi", already
    //    verified present in the installed font's post table alongside
    //    this repo's existing "wifi"/"wifi_off" ligatures) and encodes the
    //    bucket through the returned OPACITY rather than swapping to a
    //    second glyph name — the same technique QuickToggles.qml's
    //    FILL-axis interpolation and this repo's Colours-role convention
    //    both already rely on: modulate a proven surface rather than risk
    //    an unverified per-bar-count ligature name reading as tofu.
    //    Thresholds span the full theoretical 0.0-1.0 domain (Task 1
    //    measurement 1's declared range for `signalStrength`), not just
    //    this session's observed 0.24-0.49 slice, so a stronger network
    //    arriving later still buckets correctly. Returns -1 when the
    //    network reports no usable strength value (E3 `partial` backstop)
    //    so the caller can render the row without the glyph entirely. ────
    function strengthGlyph(network) {
        if (!network || typeof network.signalStrength !== "number" || isNaN(network.signalStrength) || network.signalStrength < 0)
            return -1;
        var s = network.signalStrength;
        if (s < 0.34)
            return 0.45;
        if (s < 0.67)
            return 0.7;
        return 1;
    }

    // ── Branch 1 (unfixable) — hardware switch, no button ────────────────
    Item {
        id: hardwareBlockedBranch
        width: parent.width
        height: root.bodyAreaHeight
        visible: root.radioBlockedBranch

        Column {
            anchors.centerIn: parent
            spacing: root.spacingSm

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "wifi_off"
                font.family: root.symbolFontFamily
                font.pixelSize: root.iconSizeMd
                color: root.stateColour("empty")
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Wi-Fi is off"
                font.pixelSize: root.fontHeading
                font.weight: root.weightEmphasis
                color: root.stateColour("empty")
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Turned off by a hardware switch"
                font.pixelSize: root.fontBody
                font.weight: root.weightBody
                lineHeight: root.lineHeightNormal
                color: root.stateColour("empty")
            }
        }
    }

    // ── Branch 2 (fixable) — software radio off, Enable button ───────────
    Item {
        id: softOffBranch
        width: parent.width
        height: root.bodyAreaHeight
        visible: root.radioOffBranch

        Column {
            anchors.centerIn: parent
            spacing: root.spacingSm

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "wifi_off"
                font.family: root.symbolFontFamily
                font.pixelSize: root.iconSizeMd
                color: root.stateColour("empty")
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Wi-Fi is off"
                font.pixelSize: root.fontHeading
                font.weight: root.weightEmphasis
                color: root.stateColour("empty")
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Turn on Wi-Fi to see nearby networks"
                font.pixelSize: root.fontBody
                font.weight: root.weightBody
                lineHeight: root.lineHeightNormal
                color: root.stateColour("empty")
            }

            // The branch's one accent use (D-15-26's governing principle:
            // never offer a control that cannot work — this is the ONE
            // control here that can).
            Item {
                id: enableButton
                anchors.horizontalCenter: parent.horizontalCenter
                width: enableLabel.implicitWidth + root.spacingLg * 2
                height: 40

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: Colours.primary
                }
                Text {
                    id: enableLabel
                    anchors.centerIn: parent
                    text: "Enable"
                    font.pixelSize: root.fontBody
                    color: Colours.onPrimary
                }
                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (root.backend)
                            root.backend.setWifiEnabled(true);
                    }
                }
            }
        }
    }

    // ── groupHeader — the hairline-plus-label boundary marker mirrored
    //    from 15-04's render-gate fix (AudioPanel.qml's `sectionDivider`),
    //    applied between every group transition here since this list has
    //    more than one internal boundary to name (Saved, Other networks —
    //    Connected needs none, it directly follows the progress line at
    //    the top of the list). ─────────────────────────────────────────
    component GroupHeader: Column {
        property string label: ""
        width: parent ? parent.width : 0
        spacing: root.spacingXs

        Rectangle {
            width: parent.width
            height: 1
            color: Colours.outline
        }
        Text {
            text: parent.label
            font.pixelSize: root.fontLabel
            font.weight: root.weightEmphasis
            color: Colours.onSurfaceVariant
        }
    }

    // ── NetworkRow — one line, always (UI-SPEC E3 `zero-one-many`, count
    //    invariant, no singular/plural branch). Left to right: the
    //    never-sorting strength glyph, the elided SSID with its full-name
    //    tooltip (E3 `long-text`, NEW locked contract), the trailing verb
    //    region. The current connection's row alone carries
    //    `emphasized: true` — the `Colours.surfaceVariant` fill the other
    //    groups do not carry, mirroring 15-04's primary-control weight
    //    differentiation against THIS panel's own focal point (UI-SPEC
    //    Dimension 2). Rows are keyed by the network OBJECT (`network:
    //    modelData` bound at each Repeater's delegate site) — two rows can
    //    legitimately carry the same SSID and neither may act on the
    //    other.
    //
    //    Task 3 additions below the collapsed row: the inline password
    //    expansion (D-15-14), the enterprise no-op note, the row-scoped
    //    failure line (D-15-09) and Forget's own inline confirm (P4) — two
    //    independent expansions of the same row (`expandedNetwork` and
    //    `confirmForgetNetwork` are separate root properties), not one
    //    mechanism wearing two hats. The whole `Column` grows/shrinks its
    //    own `implicitHeight` (mirroring AudioPanel.qml's DevicePickerRow
    //    shape) — the list below shifts while a row is expanded, honest
    //    and reversible, no popup, no floating overlay (D-15-14). ────────
    component NetworkRow: Item {
        id: networkRow

        property var network: null
        property bool emphasized: false

        readonly property string kind: root.backend ? root.backend.securityKind(networkRow.network) : "open"
        readonly property bool isConnectedNow: networkRow.network ? networkRow.network.connected : false
        readonly property bool isKnownNetwork: networkRow.network ? networkRow.network.known : false
        readonly property bool isExpanded: root.expandedNetwork === networkRow.network
        readonly property bool isPendingRow: root.pendingNetwork === networkRow.network
        readonly property bool isFailedRow: root.failedNetwork === networkRow.network
        readonly property bool isConfirmingForget: root.confirmForgetNetwork === networkRow.network
        // Groups 1+2 only (current + saved) per D-15-17 — `emphasized` is
        // true only for the currentNetwork row, `isKnownNetwork` covers
        // the saved group; otherNetworks is already known-false by
        // construction (WifiBackend's own filter), so this OR is a safety
        // net rather than load-bearing.
        readonly property bool forgetEligible: networkRow.emphasized || networkRow.isKnownNetwork

        readonly property real strengthGlyphOpacity: root.strengthGlyph(networkRow.network)
        readonly property bool hasStrength: networkRow.strengthGlyphOpacity >= 0

        width: parent ? parent.width : 0
        implicitHeight: rowColumn.implicitHeight
        height: implicitHeight

        Behavior on implicitHeight {
            enabled: Motion.motionEnabled
            NumberAnimation {
                duration: Motion.standardDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.standardEasing
            }
        }

        onIsConnectedNowChanged: if (networkRow.isConnectedNow)
            root.markConnectedIfPending(networkRow.network)

        Column {
            id: rowColumn
            width: parent.width
            spacing: root.spacingXs

            Item {
                id: collapsedRow
                width: parent.width
                height: root.controlRowHeight

                Rectangle {
                    anchors.fill: parent
                    radius: root.spacingXs
                    color: networkRow.emphasized ? Colours.surfaceVariant : "transparent"
                }

                // Full-row press target, declared first (underneath) so
                // the more specific verb/cancel/forget MouseAreas declared
                // below it in paint order take priority over their own
                // small regions, while the rest of the row (glyph, blank
                // space) falls through to this one — "pressing a row does
                // the one obvious thing" without needing a hit target the
                // size of the verb text alone.
                MouseArea {
                    id: rowPressArea
                    anchors.fill: parent
                    onClicked: root.handleRowPress(networkRow.network)
                }

                Text {
                    id: strengthIcon
                    anchors.left: parent.left
                    anchors.leftMargin: root.spacingSm
                    anchors.verticalCenter: parent.verticalCenter
                    width: networkRow.hasStrength ? root.iconSizeMd : 0
                    visible: networkRow.hasStrength
                    horizontalAlignment: Text.AlignHCenter
                    font.family: root.symbolFontFamily
                    font.pixelSize: root.iconSizeMd
                    // "network_wifi" — verified present in the installed Material
                    // Symbols Rounded font's `post` table, the SAME ligature
                    // rendered at every bucket (see strengthGlyph()'s own header
                    // note for why opacity carries the bucket instead of a second
                    // glyph name).
                    text: "network_wifi"
                    opacity: networkRow.hasStrength ? networkRow.strengthGlyphOpacity : 1
                    color: Colours.onSurfaceVariant
                }

                Text {
                    id: ssidText
                    anchors.left: strengthIcon.right
                    anchors.leftMargin: root.spacingSm
                    anchors.right: trailingActions.left
                    anchors.rightMargin: root.spacingSm
                    anchors.verticalCenter: parent.verticalCenter
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    text: networkRow.network ? networkRow.network.name : ""
                    font.pixelSize: root.fontBody
                    font.weight: root.weightBody
                    color: Colours.onSurface

                    MouseArea {
                        id: ssidHoverArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.handleRowPress(networkRow.network)
                        ToolTip.visible: ssidHoverArea.containsMouse
                        ToolTip.text: ssidText.text
                        ToolTip.delay: Design.tooltipDelayMs
                    }
                }

                // ── Trailing actions — the primary verb (or the pending
                //    pulse plus a real Cancel) on the left, Forget
                //    separated by `Design.spacingLg` on the right so a
                //    press aimed at the reversible verb cannot land on the
                //    irreversible one (D-15-17, P4). ─────────────────────
                Row {
                    id: trailingActions
                    anchors.right: parent.right
                    anchors.rightMargin: root.spacingSm
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: root.spacingSm

                    Row {
                        id: verbGroup
                        spacing: root.spacingSm
                        visible: networkRow.kind !== "enterprise"

                        // The pending pulse — QuickToggles.qml's own
                        // pending-pulse shape (the same emphasizedIn/Out
                        // duration+easing pair), reused rather than a new
                        // spinner primitive (UI-SPEC Color table: `pending`
                        // reuses this pattern).
                        Text {
                            id: pendingGlyph
                            anchors.verticalCenter: parent.verticalCenter
                            visible: networkRow.isPendingRow
                            font.family: root.symbolFontFamily
                            font.pixelSize: root.iconSizeMd
                            text: "sync"
                            color: Colours.primary
                            opacity: 0.4

                            SequentialAnimation {
                                running: networkRow.isPendingRow && Motion.motionEnabled
                                loops: Animation.Infinite
                                NumberAnimation {
                                    target: pendingGlyph
                                    property: "opacity"
                                    from: 0.3
                                    to: 1.0
                                    duration: Motion.emphasizedInDuration
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: Motion.emphasizedInEasing
                                }
                                NumberAnimation {
                                    target: pendingGlyph
                                    property: "opacity"
                                    from: 1.0
                                    to: 0.3
                                    duration: Motion.emphasizedOutDuration
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: Motion.emphasizedOutEasing
                                }
                            }
                        }

                        // "Connect" / "Disconnect" — Disconnect deliberately
                        // NOT error-toned (UI-SPEC: Destructive is reserved
                        // for Forget and the failed-state text alone; an
                        // ordinary reversible action stays `Colours.primary`).
                        Text {
                            id: verbText
                            anchors.verticalCenter: parent.verticalCenter
                            visible: !networkRow.isPendingRow
                            text: root.rowVerbLabel(networkRow.network)
                            font.pixelSize: root.fontBody
                            color: Colours.primary

                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.handleRowPress(networkRow.network)
                            }
                        }

                        // The real Cancel (UI-SPEC E4 `loading`, NEW locked
                        // contract) — not a silent watchdog alone.
                        Text {
                            id: cancelText
                            anchors.verticalCenter: parent.verticalCenter
                            visible: networkRow.isPendingRow
                            text: "Cancel"
                            font.pixelSize: root.fontBody
                            color: Colours.onSurfaceVariant

                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.handleCancel(networkRow.network)
                            }
                        }
                    }

                    Item {
                        id: forgetSpacer
                        visible: networkRow.forgetEligible
                        width: networkRow.forgetEligible ? Design.spacingLg : 0
                        height: 1
                    }

                    Text {
                        id: forgetText
                        anchors.verticalCenter: parent.verticalCenter
                        visible: networkRow.forgetEligible
                        text: "Forget"
                        font.pixelSize: root.fontBody
                        color: Colours.error

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.expandedNetwork = null;
                                root.confirmForgetNetwork = networkRow.network;
                            }
                        }
                    }
                }
            }

            // ── Enterprise — no field is offered because none could work
            //    (P2): `connectWithPsk` carries one passphrase and
            //    `connectWithSettings` is fenced out by D-15-17 as
            //    Advanced's job. Static, never expands, the row's press
            //    does nothing (handleRowPress() early-returns above). ────
            Text {
                id: enterpriseNote
                width: parent.width
                visible: networkRow.kind === "enterprise"
                text: "Use Advanced to connect"
                font.pixelSize: root.fontLabel
                color: Colours.onSurfaceVariant
            }

            // ── The inline password row (D-15-14, UI-SPEC E4 `populated`).
            //    No popup, no dialog, no navigation — the row itself grows.
            Row {
                id: passwordRow
                width: parent.width
                spacing: root.spacingSm
                visible: networkRow.isExpanded

                TextField {
                    id: passwordField
                    width: parent.width - connectAction.width - root.spacingSm
                    height: root.controlRowHeight
                    echoMode: TextInput.Password
                    color: Colours.onSurface
                    background: Rectangle {
                        radius: root.spacingXs
                        color: Colours.surfaceVariant
                    }
                    // First stage of two-stage Escape (D-15-14): consumed
                    // here, where the field holds active focus, so the
                    // event never reaches PanelDialog's content-root
                    // handler and the panel stays open.
                    Keys.onEscapePressed: function (event) {
                        root.collapseExpandedRow();
                        event.accepted = true;
                    }
                    // Phase 11's QS-02 gate proved a human can type into a
                    // text field on a layer-shell surface under on-demand
                    // keyboard focus — the enabling fact, not an assumption.
                    onVisibleChanged: if (passwordField.visible)
                        passwordField.forceActiveFocus()
                }

                // "Connect" — enabled exactly when non-empty. No minimum
                // length and no character-class check: WPA passphrase
                // rules vary and a guessed floor would reject valid input;
                // NetworkManager is the validator (E4 `empty` backstop).
                Item {
                    id: connectAction
                    width: connectLabel.implicitWidth + root.spacingMd * 2
                    height: root.controlRowHeight

                    readonly property bool enabledNow: passwordField.text.length > 0

                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: Colours.primary
                        opacity: connectAction.enabledNow ? 1 : 0.38
                    }
                    Text {
                        id: connectLabel
                        anchors.centerIn: parent
                        text: "Connect"
                        font.pixelSize: root.fontBody
                        color: Colours.onPrimary
                    }
                    MouseArea {
                        anchors.fill: parent
                        enabled: connectAction.enabledNow
                        onClicked: {
                            // Read at press time, handed straight through,
                            // then discarded — never assigned to a
                            // property on this panel, never logged
                            // (Prohibition P3's residency half).
                            var enteredPassword = passwordField.text;
                            passwordField.text = "";
                            root.startConnect(networkRow.network, enteredPassword);
                        }
                    }
                }
            }

            // ── Row-scoped failure (D-15-09) — renders whether or not the
            //    password row is expanded; the field (if open) stays open
            //    and empty for the correction. ───────────────────────────
            Text {
                id: rowFailureText
                width: parent.width
                visible: networkRow.isFailedRow
                text: root.failedText
                font.pixelSize: root.fontLabel
                color: Colours.error
            }

            // ── Forget's inline confirm (D-15-17, P4) — never a silent
            //    one-press forget; only the confirming press calls
            //    `backend.forget()`. Escape and collapsing the row both
            //    cancel it (see `handleEscape()` above). ────────────────
            Row {
                id: forgetConfirmRow
                width: parent.width
                visible: networkRow.isConfirmingForget
                spacing: root.spacingSm

                Text {
                    id: forgetConfirmLabel
                    width: parent.width - forgetConfirmYes.implicitWidth - forgetConfirmNo.implicitWidth - root.spacingSm * 2
                    text: "Forget " + (networkRow.network ? networkRow.network.name : "") + "?"
                    font.pixelSize: root.fontLabel
                    color: Colours.onSurface
                    wrapMode: Text.WordWrap
                }
                Text {
                    id: forgetConfirmYes
                    text: "Forget"
                    font.pixelSize: root.fontLabel
                    font.weight: root.weightEmphasis
                    color: Colours.error

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.backend.forget(networkRow.network);
                            root.confirmForgetNetwork = null;
                        }
                    }
                }
                Text {
                    id: forgetConfirmNo
                    text: "Cancel"
                    font.pixelSize: root.fontLabel
                    color: Colours.onSurfaceVariant

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.confirmForgetNetwork = null
                    }
                }
            }
        }
    }

    // ── Branch 3 (populated) — the network list. 15-03 left this real and
    //    empty; this task fills it with the scan in-progress line, the
    //    refresh control, and the grouped stable list. Task 3 adds the row
    //    verbs, the password flow, in-flight/failure and Forget on top of
    //    this same structure. ─────────────────────────────────────────
    Item {
        id: listBodySlot
        width: parent.width
        height: listColumn.implicitHeight
        visible: root.panelState === "populated"

        Column {
            id: listColumn
            width: parent.width
            spacing: root.spacingSm

            // ── The in-progress line (D-15-15, UI-SPEC E3 `loading`) and
            //    the refresh control, pinned as the first element of this
            //    list — a fixed-height row whose own visibility toggling
            //    never reflows the group list below it (opacity carries
            //    the on/off language, not `visible`). No text accompanies
            //    the line — the Copywriting Contract says the line is the
            //    whole message. ─────────────────────────────────────────
            Item {
                id: progressLine
                width: parent.width
                height: root.iconSizeMd

                Item {
                    id: progressTrack
                    anchors.left: parent.left
                    anchors.right: refreshControl.left
                    anchors.rightMargin: root.spacingSm
                    anchors.verticalCenter: parent.verticalCenter
                    height: 3
                    opacity: (root.backend && root.backend.scanning) ? 1 : 0

                    Rectangle {
                        anchors.fill: parent
                        radius: height / 2
                        color: Colours.surfaceVariant
                    }

                    Rectangle {
                        id: progressSegment
                        height: parent.height
                        radius: height / 2
                        color: Colours.primary
                        // At `off` motion scale the SequentialAnimation
                        // below never runs (Motion.motionEnabled false) —
                        // the line must still say something true, so it
                        // renders as a static full-width bar rather than
                        // vanishing: "scanning" is information and reduced
                        // motion is not a reason to withhold it (same
                        // fallback voice QuickToggles.qml records for its
                        // own pending-pulse layer at `off`).
                        width: Motion.motionEnabled ? progressTrack.width * 0.3 : progressTrack.width
                        x: 0

                        // G-15-1 RC1: both legs now bind the ambient LOOP
                        // PERIOD token, never the one-shot enter/exit
                        // transition durations (emphasizedIn/Out) this
                        // infinite loop was misusing before — see
                        // Motion.qml's ambientDuration header comment for
                        // the full rationale. The two easings are left
                        // exactly as they were (design_decisions_resolved
                        // item 2): the accelerate-then-decelerate sweep
                        // feel is deliberate and unrelated to the period.
                        SequentialAnimation {
                            running: (root.backend && root.backend.scanning) && Motion.motionEnabled
                            loops: Animation.Infinite
                            NumberAnimation {
                                target: progressSegment
                                property: "x"
                                from: 0
                                to: progressTrack.width - progressSegment.width
                                duration: Motion.ambientDuration
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Motion.emphasizedInEasing
                            }
                            NumberAnimation {
                                target: progressSegment
                                property: "x"
                                from: progressTrack.width - progressSegment.width
                                to: 0
                                duration: Motion.ambientDuration
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Motion.emphasizedOutEasing
                            }
                        }
                    }
                }

                // Ships because Task 1's measurement 2 confirmed the
                // scan-flag toggle produces a genuinely fresh scan (the
                // list clears to 0 within ~200ms of disabling and
                // repopulates within 300ms-1.5s of re-enabling, still
                // growing 4.5s later as new APs are discovered — see
                // 15-05-SUMMARY.md Task 1). Stays available regardless of
                // whether a scan is currently in flight.
                Text {
                    id: refreshControl
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    text: "refresh"
                    font.family: root.symbolFontFamily
                    font.pixelSize: root.iconSizeMd
                    // G-15-1 RC2b: accent while a rescan is in flight, the
                    // existing muted role otherwise. Deliberately NOT
                    // gated on Motion.motionEnabled — at the `off` motion
                    // scale the rotation below never runs, but the glyph
                    // must still say something true (busy), matching the
                    // fallback voice the progress line above records for
                    // its own static-bar case at `off`.
                    color: (root.backend && root.backend.rescanInFlight) ? Colours.primary : Colours.onSurfaceVariant
                    // Immediate, backend-independent press acknowledgement
                    // — fires on the SAME FRAME as the press, deliberately
                    // redundant with the backend's in-flight edge (which
                    // can take a moment to arm): the control is never
                    // silent even if that edge is slow to land.
                    opacity: refreshMouseArea.pressed ? 0.6 : 1.0

                    // The in-flight busy spin — gated on both the backend
                    // edge AND Motion.motionEnabled (the same gating shape
                    // the sweep above uses), period bound to the SAME
                    // ambient loop token as the sweep so the control and
                    // the line read as one instrument.
                    RotationAnimation on rotation {
                        running: (root.backend && root.backend.rescanInFlight) && Motion.motionEnabled
                        loops: Animation.Infinite
                        from: 0
                        to: 360
                        duration: Motion.ambientDuration
                    }

                    MouseArea {
                        id: refreshMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: if (root.backend) root.backend.rescan()
                        ToolTip.visible: refreshMouseArea.containsMouse
                        // Idle copy unchanged; in-flight copy is Task 3's
                        // new Copywriting Contract row (D-15-15 amendment).
                        ToolTip.text: (root.backend && root.backend.rescanInFlight) ? "Rescanning…" : "Rescan"
                        ToolTip.delay: Design.tooltipDelayMs
                    }
                }
            }

            // ── The grouped list (D-15-16) — current, then saved, then
            //    the rest. Three Repeaters, each bound to a plain JS array
            //    on the backend (the grouping work produces those arrays
            //    already, sidestepping the raw-model-binding question
            //    entirely). Rendered as one block (D-15-08): no cascade
            //    band, no per-row entrance animation. ────────────────────
            Column {
                id: networkList
                width: parent.width
                spacing: root.spacingSm

                // Group 1 — Connected. The panel's declared focal point
                // (UI-SPEC Dimension 2): D-15-16's ordering puts "what am
                // I connected to right now" first by construction. No
                // GroupHeader above it — it directly follows the progress
                // line, the top of this list.
                Text {
                    id: connectedLabel
                    text: "Connected"
                    visible: root.backend ? !!root.backend.currentNetwork : false
                    font.pixelSize: root.fontLabel
                    font.weight: root.weightEmphasis
                    color: Colours.onSurfaceVariant
                }
                Repeater {
                    model: (root.backend && root.backend.currentNetwork) ? [root.backend.currentNetwork] : []
                    delegate: NetworkRow {
                        network: modelData
                        emphasized: true
                    }
                }

                // Group 2 — Saved.
                GroupHeader {
                    label: "Saved"
                    visible: root.backend ? root.backend.savedNetworks.length > 0 : false
                }
                Repeater {
                    model: root.backend ? root.backend.savedNetworks : []
                    delegate: NetworkRow {
                        network: modelData
                        emphasized: false
                    }
                }

                // Group 3 — Other networks.
                GroupHeader {
                    label: "Other networks"
                    visible: root.backend ? root.backend.otherNetworks.length > 0 : false
                }
                Repeater {
                    model: root.backend ? root.backend.otherNetworks : []
                    delegate: NetworkRow {
                        network: modelData
                        emphasized: false
                    }
                }
            }

            // ── 15-14 (G-15-4b) — hidden-network entry point. Two
            //    mutually exclusive states at ONE fixed height, copying
            //    the bluetooth discovery section's shape and its stated
            //    reason: a section that changes height as it switches
            //    state shoves the whole list under it, and this one sits
            //    directly above the zero-result line. ───────────────────
            Item {
                id: hiddenSection
                width: parent.width
                height: root.controlRowHeight

                // Idle — a single accent-toned label acting as the entry
                // point, nothing more.
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !root.hiddenFormOpen
                    text: "Join a hidden network"
                    font.pixelSize: root.fontBody
                    color: Colours.primary

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.openHiddenForm()
                    }
                }

                // Open — the SSID field plus the search verb.
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width
                    visible: root.hiddenFormOpen
                    spacing: root.spacingSm

                    TextField {
                        id: hiddenSsidField
                        width: parent.width - hiddenAction.width - root.spacingSm
                        height: root.controlRowHeight
                        placeholderText: "Network name"
                        text: root.hiddenSsid
                        font.pixelSize: root.fontBody
                        color: Colours.onSurface
                        // DELIBERATELY UNMASKED, unlike the passphrase
                        // field: an SSID is not a secret, and masking it
                        // would make a typo undetectable in exactly the
                        // situation where a typo is indistinguishable from
                        // an out-of-range access point. The passphrase
                        // field's own masking is untouched.
                        echoMode: TextInput.Normal
                        // Same background, same height, same
                        // focus-on-visible behaviour as the passphrase
                        // field — reused verbatim so the two read as one
                        // control family.
                        background: Rectangle {
                            radius: root.spacingXs
                            color: Colours.surfaceVariant
                        }
                        onTextChanged: {
                            root.hiddenSsid = hiddenSsidField.text;
                            // A stale message must never sit under fresh
                            // input.
                            root.hiddenFailedText = "";
                        }
                        onAccepted: root.startHiddenProbe()
                        // Consumed where the field holds active focus, so
                        // the event never reaches the frame's content-root
                        // handler and the panel stays open — the same
                        // split the password row already documents. This
                        // is the first-press-closes-the-form behaviour;
                        // handleEscape()'s third branch is the redundancy.
                        Keys.onEscapePressed: function (event) {
                            root.clearHiddenForm();
                            event.accepted = true;
                        }
                        onVisibleChanged: if (hiddenSsidField.visible)
                            hiddenSsidField.forceActiveFocus()
                    }

                    Item {
                        id: hiddenAction
                        anchors.verticalCenter: parent.verticalCenter
                        readonly property bool enabledNow: root.hiddenSsid.length > 0
                        width: hiddenActionLabel.implicitWidth + root.spacingMd * 2
                        height: root.controlRowHeight

                        Rectangle {
                            anchors.fill: parent
                            radius: height / 2
                            color: root.hiddenProbing ? Colours.surfaceVariant : Colours.primary
                            opacity: (root.hiddenProbing || hiddenAction.enabledNow) ? 1 : 0.38
                        }
                        Text {
                            id: hiddenActionLabel
                            anchors.centerIn: parent
                            // No minimum length and no character-class
                            // check — SSID rules are wider than any guess
                            // worth hardcoding.
                            text: root.hiddenProbing ? "Cancel" : "Search"
                            font.pixelSize: root.fontBody
                            color: root.hiddenProbing ? Colours.onSurface : Colours.onPrimary
                            opacity: (root.hiddenProbing || hiddenAction.enabledNow) ? 1 : 0.38
                        }
                        MouseArea {
                            anchors.fill: parent
                            enabled: root.hiddenProbing || hiddenAction.enabledNow
                            onClicked: {
                                if (root.hiddenProbing) {
                                    // Clears the pending state and stops
                                    // the probe watchdog. It deliberately
                                    // does NOT kill the subprocess: a
                                    // directed rescan is fire-and-forget
                                    // with no side effect worth aborting
                                    // (measured: exit 0 in ~16ms whether
                                    // or not the name exists). Stated
                                    // rather than left as an omission a
                                    // reader would take for a bug.
                                    root.hiddenProbing = false;
                                    hiddenProbeTimer.stop();
                                } else {
                                    root.startHiddenProbe();
                                }
                            }
                        }
                    }
                }
            }

            // Form-scoped failure copy — never row-scoped, because there
            // is no row to scope it to until the handoff succeeds.
            Text {
                visible: root.hiddenFailedText.length > 0
                width: parent.width
                text: root.hiddenFailedText
                wrapMode: Text.WordWrap
                font.pixelSize: root.fontLabel
                color: Colours.error
            }

            // ── Zero-result state (backstop, UI-SPEC E3 `empty`'s
            //    third sub-case) — the radio is on, the panel is in the
            //    populated branch, and a completed scan found nothing.
            //    The refresh control above stays visible; this is not the
            //    off-branch composition, the radio is working and the
            //    panel is scanning. ────────────────────────────────────
            Item {
                id: zeroResultState
                width: parent.width
                height: zeroResultText.implicitHeight + root.spacingMd * 2
                visible: root.backend
                    ? (!root.backend.currentNetwork && root.backend.savedNetworks.length === 0 && root.backend.otherNetworks.length === 0)
                    : false

                Text {
                    id: zeroResultText
                    anchors.centerIn: parent
                    text: "No networks found"
                    font.pixelSize: root.fontBody
                    color: Colours.onSurfaceVariant
                }
            }
        }
    }

    // Only the branch actually visible at mount time enters the cascade —
    // the other two are inert Items with no visible content to animate.
    // Evaluated once, at construction, matching AudioPanel.qml's own
    // single-array-literal shape.
    bodyCascadeBands: root.radioBlockedBranch ? [hardwareBlockedBranch] : (root.radioOffBranch ? [softOffBranch] : [listBodySlot])
}
