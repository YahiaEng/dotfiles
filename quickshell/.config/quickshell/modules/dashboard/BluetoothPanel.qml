// BluetoothPanel.qml — the bluetooth panel body (Phase 15 Plan 03 shipped
// the frame and both D-15-26 off-state branches; Phase 15 Plan 06 — this
// revision — fills the populated branch's device list). Root type
// `PanelDialog`, deliberately built as `WifiPanel.qml`'s twin so the two
// connectivity panels read as one grammar (same frame, same header band,
// same dismissal set, same branch composition shape) — only the copy and
// the branch predicates differ.
//
// ── D-15-19 — why there is no overflow menu ─────────────────────────────
// The per-device secondary actions live behind an in-place chevron
// expansion, not an overflow menu. The rejection is specific, not
// stylistic: an overflow menu is a popup, and popup-inside-a-Wayland-
// layer-shell-surface is the exact unverified path D-15-12 already routed
// the device pickers around on this Qt and quickshell build. This is the
// fourth consistent use of the split-affordance idiom — grid tiles, device
// pickers, password rows, and now this — so the shell teaches one language
// rather than four.
//
// ── The discovery-line position differs from wifi's, and the reason is
//    scope ──────────────────────────────────────────────────────────────
// D-15-15 pins wifi's indeterminate line under the header because a wifi
// scan is panel-lifetime — it has no narrower home. This panel's inquiry
// is section-scoped and user-started, so its line lives at the section it
// belongs to (`discoverySection`, between the paired and discovered
// groups). The treatment is identical to wifi's; only the position
// differs, and it differs because the scope differs. The section holds
// one fixed height across both its states so the rows around it never
// move when discovery starts or stops.
import QtQuick
import QtQuick.Controls
import Quickshell.Io
import "../"

PanelDialog {
    id: root

    property var backend: null

    panelTitle: "Bluetooth"
    panelGlyph: "bluetooth"
    namespaceSuffix: "bluetooth-panel"

    // T-15-02's mitigation, same discipline as WifiPanel.qml's
    // advancedCommand: a literal array of double-quoted string literals,
    // assigned exactly once. Never appended to, never interpolated, never
    // joined into a string, never handed to a shell interpreter.
    advancedCommand: ["blueman-manager"]
    advancedAvailable: root._bluemanManagerAvailable
    advancedUnavailableReason: "blueman-manager is not installed"

    // ── D-15-22 availability probe — the same mechanism WifiPanel.qml
    //    uses for nm-connection-editor (a fully literal fixed argv, zero
    //    interpolated elements, started once, fail OPEN). Housed here
    //    rather than in BluetoothBackend.qml for the same reason: that
    //    file is deliberately subprocess-free. ───────────────────────────
    property bool _bluemanManagerAvailable: true

    Process {
        id: bluemanManagerProbe
        command: ["which", "blueman-manager"]
        onExited: function (exitCode, exitStatus) {
            if (exitCode !== 0)
                root._bluemanManagerAvailable = false;
        }
    }
    Component.onCompleted: bluemanManagerProbe.running = true

    // ── D-15-26 branch selection — unfixable checked first so it always
    //    wins when both would otherwise apply. Both backend reads are
    //    null-guarded even though `backend` is always set by shell.qml,
    //    matching WifiPanel.qml's own discipline. ─────────────────────
    readonly property bool noAdapterBranch: !(root.backend && root.backend.adapterPresent)
    // ── G-15-2 gap closure (15-12) — the THIRD branch, and why the
    //    evaluation order below is load-bearing ────────────────────────
    // Order is: no-adapter (genuinely unfixable) FIRST, blocked SECOND,
    // plain adapter-off LAST — and the last one must exclude BOTH of the
    // two above it. Before this gap there was nothing between no-adapter
    // and adapter-off, so an rfkill soft-blocked adapter fell straight
    // through to the *fixable* off branch and rendered an Enable button
    // that provably could not work. Get this order wrong (or drop the
    // `!root.adapterBlockedBranch` term from `adapterOffBranch`) and the
    // fix changes nothing — the host lands on the old branch again.
    readonly property bool adapterBlockedBranch: !root.noAdapterBranch && !!(root.backend && root.backend.adapterBlocked)
    readonly property bool adapterOffBranch: !root.noAdapterBranch && !root.adapterBlockedBranch && !(root.backend && root.backend.adapterEnabled)
    // 15-02's four-name vocabulary — all three off branches are "empty",
    // the real body slot is "populated". No fifth state name.
    readonly property string panelState: (root.noAdapterBranch || root.adapterBlockedBranch || root.adapterOffBranch) ? "empty" : "populated"

    // The body area's own height, computed from the frame's own constants
    // rather than reaching into PanelDialog's private `bodyFlick` id (out
    // of this file's scope) — matches WifiPanel.qml's own approach.
    readonly property int bodyAreaHeight: root.panelHeight - root.headerHeight - (root.panelPadding * 2)

    // Matches AudioPanel.qml/WifiPanel.qml's own constant name and value —
    // every interactive row across the three panels shares one row-height
    // token.
    readonly property int controlRowHeight: 32
    // The trailing action region's FIXED width — idle verb, pending
    // spinner+Cancel and the failed-state text all render inside this same
    // width so a row's press-driven state change never nudges the chevron
    // or reflows a neighbour (the "no row state changes the list's
    // geometry" truth).
    readonly property int trailingActionWidth: 150
    readonly property int chevronWidth: 32

    // ═══════════════════════════════════════════════════════════════════
    // 15-06 additions (D-15-19/D-15-17/D-15-09) — the single-slot bounded
    // states a row can be in. Every one is keyed by the device's ADDRESS
    // (T-15-08), never by name or by object reference: two rows can
    // legitimately report the same `deviceName` and neither may act on,
    // expand, confirm-forget or render the failure of the other.
    // ═══════════════════════════════════════════════════════════════════
    property string expandedAddress: "" // at most one row expanded at a time
    property string confirmingForgetAddress: "" // at most one Forget confirm open at a time
    // Row-scoped failure (D-15-09) — single-slot rather than a per-address
    // map because at most one action is ever in flight (the backend's own
    // press guard), so at most one failure can be current; a map would
    // accumulate stale messages a user never asked to keep.
    property string failedAddress: ""
    property string failedReason: ""

    // ── The row's press, routed through here rather than straight to
    //    `backend.pressDevice` — clearing this row's own failure slot the
    //    moment a NEW action starts on it is what keeps a stale "Couldn't
    //    pair" from lingering under a fresh spinner. ─────────────────────
    function handleRowPress(device) {
        if (!device || !root.backend)
            return;
        root.failedAddress = "";
        root.failedReason = "";
        root.backend.pressDevice(device);
    }

    // ── Belt-and-braces override of PanelDialog's `handleEscape()` (no
    //    edit to that shared file — see its own header note inviting
    //    exactly this override, and WifiPanel.qml's own twin of this
    //    function). Collapses an open confirm first, then an expanded row,
    //    only THEN dismisses — mirrors the two-stage Escape the wifi panel
    //    already teaches. ───────────────────────────────────────────────
    function handleEscape() {
        if (root.confirmingForgetAddress !== "") {
            root.confirmingForgetAddress = "";
            return;
        }
        if (root.expandedAddress !== "") {
            root.expandedAddress = "";
            return;
        }
        root.requestDismiss();
    }

    // ── deviceGlyph(device) — the BlueZ icon class is used ONLY as a
    //    lookup key here and is NEVER itself rendered (T-15-08): an
    //    unrecognised or hostile value selects the generic bluetooth glyph
    //    rather than reaching the screen as a value. ─────────────────────
    function deviceGlyph(device) {
        var icon = device ? device.icon : "";
        switch (icon) {
        case "audio-headset":
        case "audio-headphones":
        case "audio-card":
            return "headphones";
        case "input-keyboard":
            return "keyboard";
        case "input-mouse":
            return "mouse";
        case "input-gaming":
            return "sports_esports";
        case "input-tablet":
            return "stylus";
        case "phone":
        case "phone-smartphone":
            return "smartphone";
        case "computer":
            return "computer";
        case "printer":
            return "print";
        case "camera-video":
            return "videocam";
        default:
            return "bluetooth";
        }
    }

    // ── groupHeadingFor(name) — group heading copy, discretion under the
    //    UI-SPEC's own discretion clause (it locks row and state copy, not
    //    group headings). Kept plain and short, coordinated with
    //    WifiPanel.qml's own "Saved"/"Other networks" dialect. ───────────
    function groupHeadingFor(name) {
        switch (name) {
        case "connected":
            return "Connected";
        case "paired":
            return "Paired";
        case "discovered":
            return "Nearby";
        default:
            return "";
        }
    }

    // ── Failure wiring (RESEARCH Pitfall 2's signal-side consumer) — sets
    //    both single slots; cleared on the next action via
    //    `handleRowPress` above. ─────────────────────────────────────────
    Connections {
        target: root.backend
        function onDeviceActionFailed(device, reasonText) {
            root.failedAddress = device ? device.address : "";
            root.failedReason = reasonText;
        }
    }

    // ── Branch 1 (unfixable) — no adapter at all, no button ──────────────
    Item {
        id: noAdapterBranchItem
        width: parent.width
        height: root.bodyAreaHeight
        visible: root.noAdapterBranch

        Column {
            anchors.centerIn: parent
            spacing: root.spacingSm

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "bluetooth_disabled"
                font.family: root.symbolFontFamily
                font.pixelSize: root.iconSizeMd
                color: root.stateColour("empty")
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "No Bluetooth adapter"
                font.pixelSize: root.fontHeading
                font.weight: root.weightEmphasis
                color: root.stateColour("empty")
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "This device has no Bluetooth hardware"
                font.pixelSize: root.fontBody
                font.weight: root.weightBody
                lineHeight: root.lineHeightNormal
                color: root.stateColour("empty")
            }
        }
    }

    // ── Branch 2 (fixable) — adapter present but powered off, Enable
    //    button ─────────────────────────────────────────────────────────
    Item {
        id: adapterOffBranchItem
        width: parent.width
        height: root.bodyAreaHeight
        visible: root.adapterOffBranch

        Column {
            anchors.centerIn: parent
            spacing: root.spacingSm

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "bluetooth_disabled"
                font.family: root.symbolFontFamily
                font.pixelSize: root.iconSizeMd
                color: root.stateColour("empty")
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Bluetooth is off"
                font.pixelSize: root.fontHeading
                font.weight: root.weightEmphasis
                color: root.stateColour("empty")
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Turn on Bluetooth to see nearby devices"
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
                            root.backend.setAdapterEnabled(true);
                    }
                }
            }
        }
    }

    // ── Branch 3 (G-15-2, 15-12) — adapter present but rfkill
    //    soft-blocked: fixable by the user, but OUTSIDE the panel ────────
    // A third kind, distinct from both branches above: not "fixable
    // in-panel" (branch 2's Enable, which works) and not "unfixable"
    // (branch 1, no button at all). The block is clearable, just not by
    // anything this panel is allowed to do — so the button stays present
    // at identical geometry, dimmed, and carries the remedy on hover.
    Item {
        id: adapterBlockedBranchItem
        width: parent.width
        height: root.bodyAreaHeight
        visible: root.adapterBlockedBranch

        // Same value PanelDialog.qml's D-15-22 `advancedButton` uses for
        // its own present-but-disabled control, hoisted to a named
        // property here exactly as that one does rather than minting a
        // second disabled-opacity number.
        readonly property real disabledOpacity: 0.38

        Column {
            anchors.centerIn: parent
            spacing: root.spacingSm

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "bluetooth_disabled"
                font.family: root.symbolFontFamily
                font.pixelSize: root.iconSizeMd
                color: root.stateColour("empty")
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Bluetooth is blocked"
                font.pixelSize: root.fontHeading
                font.weight: root.weightEmphasis
                color: root.stateColour("empty")
            }
            // Phrased so it can be read neither as something missing from
            // the system (the hypothesis this gap disproved) nor as a
            // physical killswitch — it must stay distinguishable at a
            // glance from WifiPanel's own physical-killswitch line, which
            // is a genuinely different situation with a different remedy.
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "A software block is holding the radio off"
                font.pixelSize: root.fontBody
                font.weight: root.weightBody
                lineHeight: root.lineHeightNormal
                color: root.stateColour("empty")
            }

            Item {
                anchors.horizontalCenter: parent.horizontalCenter
                width: blockedEnableLabel.implicitWidth + root.spacingLg * 2
                height: 40

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: Colours.primary
                    opacity: adapterBlockedBranchItem.disabledOpacity
                }
                Text {
                    id: blockedEnableLabel
                    anchors.centerIn: parent
                    text: "Enable"
                    font.pixelSize: root.fontBody
                    color: Colours.onPrimary
                    opacity: adapterBlockedBranchItem.disabledOpacity
                }
                MouseArea {
                    id: blockedEnableMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    // Deliberate, NOT an oversight: a disabled MouseArea
                    // also stops receiving hover, which would make the
                    // reason UNREACHABLE by hover — directly contradicting
                    // UI-SPEC E7's "the reason is legible before the
                    // press, not after". Press suppression is a different
                    // guard for a different requirement, and lives in
                    // BluetoothBackend.setAdapterEnabled()'s early return.
                    enabled: true
                }
                // ThemedToolTip (quick-260821-6z1 fix wave) — replaces the
                // bare attached ToolTip shorthand; see ThemedToolTip.qml.
                ThemedToolTip {
                    visible: blockedEnableMouseArea.containsMouse
                    text: "Run  rfkill unblock bluetooth  in a terminal to clear it"
                }
            }
        }
    }

    // ── groupHeader — the hairline-plus-label boundary marker mirrored
    //    from 15-04's render-gate fix and reused byte-for-byte in shape
    //    from WifiPanel.qml's own `GroupHeader`, applied between the
    //    Paired and Discovered groups (Connected needs none — it directly
    //    follows the top of the list, the panel's declared focal point). ─
    component GroupHeader: Column {
        property string label: ""
        width: parent ? parent.width : 0
        spacing: root.spacingXs

        Rectangle {
            width: parent.width
            height: 1
            color: Colours.outlineVariant
        }
        Text {
            text: parent.label
            font.pixelSize: root.fontLabel
            font.weight: root.weightEmphasis
            color: Colours.onSurfaceVariant
        }
    }

    // ── DeviceRow — the contextual-verb row (D-15-19). One inline
    //    component, used by all three groups so a device that changes
    //    group does not change shape. Left to right: glyph, elided name
    //    with a plain-text tooltip, a FIXED-width trailing action region,
    //    and the chevron. Row identity is `device.address` (T-15-08) —
    //    every slot lookup below compares against `deviceRow.address`,
    //    never against `deviceRow.device` object identity or its name. ───
    component DeviceRow: Item {
        id: deviceRow

        property var device: null

        readonly property string address: deviceRow.device ? deviceRow.device.address : ""
        readonly property string verb: (root.backend && deviceRow.device) ? root.backend.contextualVerb(deviceRow.device) : ""
        readonly property bool isPending: deviceRow.address !== "" && root.backend && root.backend.pendingAddress === deviceRow.address
        readonly property bool isPendingPair: deviceRow.isPending && root.backend.pendingVerb === "pair"
        readonly property bool isFailed: deviceRow.address !== "" && root.failedAddress === deviceRow.address
        readonly property bool isExpanded: deviceRow.address !== "" && root.expandedAddress === deviceRow.address
        readonly property bool isConfirmingForget: deviceRow.address !== "" && root.confirmingForgetAddress === deviceRow.address
        readonly property bool batteryAvailable: deviceRow.device ? deviceRow.device.batteryAvailable : false

        width: parent ? parent.width : 0
        implicitHeight: rowColumn.implicitHeight
        height: implicitHeight

        // Deliberate: this Behavior animates the EXPANSION transition only
        // (a deliberate chevron press). Idle/pending/failed never touch
        // `implicitHeight` at all — the collapsed row's own height is the
        // fixed `root.controlRowHeight`, unconditionally.
        // quick-260821-swp (R-2): implicitHeight is spatial — retargeted
        // onto spatial-move.
        Behavior on implicitHeight {
            enabled: Motion.motionEnabled
            NumberAnimation {
                duration: Motion.spatialMoveDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.spatialMoveEasing
            }
        }

        Column {
            id: rowColumn
            width: parent.width
            spacing: root.spacingXs

            Item {
                id: collapsedRow
                width: parent.width
                height: root.controlRowHeight

                // Full-row press target, declared first (underneath) so the
                // more specific verb/cancel/chevron regions declared below
                // it in paint order take priority over their own small
                // regions.
                MouseArea {
                    anchors.fill: parent
                    anchors.rightMargin: root.trailingActionWidth + root.spacingSm + root.chevronWidth
                    onClicked: root.handleRowPress(deviceRow.device)
                }

                Text {
                    id: deviceGlyphText
                    anchors.left: parent.left
                    anchors.leftMargin: root.spacingSm
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: root.symbolFontFamily
                    font.pixelSize: root.iconSizeMd
                    text: root.deviceGlyph(deviceRow.device)
                    color: Colours.onSurfaceVariant
                }

                Text {
                    id: deviceNameText
                    anchors.left: deviceGlyphText.right
                    anchors.leftMargin: root.spacingSm
                    anchors.right: trailingRegion.left
                    anchors.rightMargin: root.spacingSm
                    anchors.verticalCenter: parent.verticalCenter
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    // Explicit plain-text pin (T-15-08) — a device name is
                    // attacker-controllable text arriving over the air, and
                    // QML's automatic format detection would render markup
                    // as markup rather than as literal characters.
                    textFormat: Text.PlainText
                    text: deviceRow.device ? deviceRow.device.deviceName : ""
                    font.pixelSize: root.fontBody
                    font.weight: root.weightBody
                    color: Colours.onSurface

                    MouseArea {
                        id: nameHoverArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.handleRowPress(deviceRow.device)
                    }
                    // A standalone `ToolTip` (not the attached-property
                    // shorthand) so its own content item's text format can
                    // be pinned explicitly — the tooltip is where the full,
                    // unelided device name lands, making it the
                    // highest-value target for T-15-08's mitigation.
                    ToolTip {
                        id: nameTooltip
                        visible: nameHoverArea.containsMouse
                        delay: Design.tooltipDelayMs
                        text: deviceNameText.text
                        contentItem: Text {
                            text: nameTooltip.text
                            textFormat: Text.PlainText
                            color: Colours.onSurface
                        }
                        background: Rectangle {
                            color: Colours.surfaceVariant
                            radius: root.spacingXs
                        }
                    }
                }

                // ── Trailing action region — FIXED WIDTH, holds exactly
                //    one of idle-verb / pending-spinner+Cancel /
                //    failed-text at a time. Confirming-Forget lives in the
                //    expanded detail region below (see D), reached only
                //    via a deliberate chevron press, so it never contends
                //    with this region's own fixed geometry. ──────────────
                Item {
                    id: trailingRegion
                    anchors.right: chevronArea.left
                    anchors.rightMargin: root.spacingSm
                    anchors.verticalCenter: parent.verticalCenter
                    width: root.trailingActionWidth
                    height: parent.height

                    // *Idle* — the row's press IS the call to action; no
                    // separate button beyond this label.
                    Text {
                        id: verbLabelText
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        visible: !deviceRow.isPending && !deviceRow.isFailed
                        text: deviceRow.verb === "pair" ? "Pair" : deviceRow.verb === "connect" ? "Connect" : deviceRow.verb === "disconnect" ? "Disconnect" : ""
                        font.pixelSize: root.fontBody
                        color: Colours.primary

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.handleRowPress(deviceRow.device)
                        }
                    }

                    // *Pending* — an indeterminate spinner plus a REAL
                    // Cancel wired to `cancelPair()` for a pairing in
                    // flight (D-15-19: this is the one operation whose
                    // wait is long and user-visible; a silent watchdog
                    // alone is not an adequate answer). The rotation reads
                    // the repo's only rotation-period Motion token and is
                    // gated on `Motion.motionEnabled` so it is static at
                    // `off` — legible there because the Cancel/spinner
                    // presence itself carries the pending state, not the
                    // motion.
                    Row {
                        id: pendingRow
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        visible: deviceRow.isPending
                        spacing: root.spacingSm

                        Text {
                            id: pendingSpinner
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: root.symbolFontFamily
                            font.pixelSize: root.iconSizeMd
                            text: "progress_activity"
                            color: Colours.primary

                            RotationAnimation on rotation {
                                running: deviceRow.isPending && Motion.motionEnabled
                                loops: Animation.Infinite
                                from: 0
                                to: 360
                                duration: Motion.borderRotateDuration
                            }
                        }

                        Text {
                            id: cancelText
                            anchors.verticalCenter: parent.verticalCenter
                            visible: deviceRow.isPendingPair
                            text: "Cancel"
                            font.pixelSize: root.fontBody
                            color: Colours.onSurfaceVariant

                            MouseArea {
                                anchors.fill: parent
                                onClicked: if (root.backend)
                                    root.backend.cancelPair(deviceRow.device)
                            }
                        }
                    }

                    // *Failed* — scoped to this row only (D-15-09), never
                    // panel-wide. Persists until this row is pressed again
                    // or the panel is dismissed; no auto-clear timer — a
                    // message that vanishes before it is read is exactly
                    // the failure the fourth state was minted to fix.
                    //
                    // G-15-8: the failure now carries an explicit Retry.
                    // Retrying was ALWAYS possible — the row stayed
                    // pressable and `handleRowPress()` already clears this
                    // row's failure slot before re-invoking — but nothing
                    // said so, so a failed row read as terminal. This adds
                    // the affordance, not the capability: Retry calls the
                    // exact same `handleRowPress()` the idle verb label
                    // calls, so there is no second retry path to keep in
                    // step with the first.
                    //
                    // The wifi panel needs no equivalent because its failed
                    // row leaves the password field open with its Connect
                    // pill already visible — the retry target is on screen
                    // there. A bluetooth row has no such standing control,
                    // which is the whole difference.
                    Row {
                        id: failedRow
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        visible: deviceRow.isFailed
                        spacing: root.spacingSm

                        // Takes whatever the Retry label does not, so the
                        // pair still honours `trailingRegion`'s fixed
                        // width — the reason that region is fixed at all
                        // is that switching states must never move the
                        // rows above or below.
                        Text {
                            id: failedText
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.max(0, trailingRegion.width - retryLabelText.implicitWidth - root.spacingSm)
                            horizontalAlignment: Text.AlignRight
                            elide: Text.ElideRight
                            text: root.failedReason
                            font.pixelSize: root.fontLabel
                            color: Colours.error
                        }

                        // Styled as `verbLabelText` above, deliberately —
                        // it occupies the same slot and means the same
                        // thing (this row's call to action).
                        Text {
                            id: retryLabelText
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Retry"
                            font.pixelSize: root.fontBody
                            color: Colours.primary

                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.handleRowPress(deviceRow.device)
                            }
                        }
                    }
                }

                // ── Chevron — a second, smaller hit region at the row's
                //    trailing edge, separate from the row's own press area
                //    (D-15-19, the fourth use of the split-affordance
                //    idiom in this shell). ──────────────────────────────
                Item {
                    id: chevronArea
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: root.chevronWidth
                    height: parent.height

                    Text {
                        anchors.centerIn: parent
                        font.family: root.symbolFontFamily
                        font.pixelSize: root.iconSizeMd
                        text: deviceRow.isExpanded ? "expand_less" : "expand_more"
                        color: Colours.onSurfaceVariant
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            root.expandedAddress = deviceRow.isExpanded ? "" : deviceRow.address;
                            root.confirmingForgetAddress = "";
                        }
                    }
                }
            }

            // ── Expansion (D-15-19) — battery (only when available),
            //    address, and a separated Forget (D). Renders in place,
            //    below the row, inside the frame's existing scroll body —
            //    no popup type of any kind. ─────────────────────────────
            Column {
                id: expandedDetail
                width: parent.width
                spacing: root.spacingXs
                visible: deviceRow.isExpanded

                Text {
                    visible: deviceRow.batteryAvailable
                    text: deviceRow.device ? "Battery " + Math.round(deviceRow.device.battery) + "%" : ""
                    font.pixelSize: root.fontLabel
                    color: Colours.onSurfaceVariant
                }
                Text {
                    textFormat: Text.PlainText
                    text: deviceRow.device ? deviceRow.device.address : ""
                    font.pixelSize: root.fontLabel
                    color: Colours.onSurfaceVariant
                }

                // ── Forget — destructive treatment (D-15-17/P4). Its own
                //    sub-region, separated from the detail lines above by
                //    a full `Design.spacingMd` gap — never adjacent to the
                //    row's own press action. `Colours.error` is reserved
                //    for exactly this and the failed state. ─────────────
                Item {
                    width: 1
                    height: root.spacingMd
                }

                Text {
                    id: forgetText
                    visible: !deviceRow.isConfirmingForget
                    text: "Forget"
                    font.pixelSize: root.fontLabel
                    color: Colours.error

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.confirmingForgetAddress = deviceRow.address
                    }
                }

                // Pressing Forget does NOT forget — it reveals this inline
                // confirm. Only the confirming Forget calls
                // `backend.forget(device)` (P4 — no destructive action
                // commits on a single press).
                Row {
                    id: forgetConfirmRow
                    width: parent.width
                    spacing: root.spacingSm
                    visible: deviceRow.isConfirmingForget

                    Text {
                        id: forgetConfirmLabel
                        width: parent.width - forgetConfirmYes.implicitWidth - forgetConfirmNo.implicitWidth - root.spacingSm * 2
                        textFormat: Text.PlainText
                        text: "Forget " + (deviceRow.device ? deviceRow.device.deviceName : "") + "?"
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
                                if (root.backend)
                                    root.backend.forget(deviceRow.device);
                                root.confirmingForgetAddress = "";
                                root.expandedAddress = "";
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
                            onClicked: root.confirmingForgetAddress = ""
                        }
                    }
                }
            }
        }
    }

    // ── Branch 3 (populated) — the device list, grouped connected ->
    //    paired -> discovered (D-15-18). The connected group is the
    //    panel's declared focal point (UI-SPEC Dimension 2): the daily
    //    question "is my headset connected" resolves at the top of this
    //    list without a scroll and without an inquiry. The list renders
    //    WHOLE (D-15-08) — no per-row entrance stagger; only the branch
    //    itself joins the frame's cascade via `bodyCascadeBands` below,
    //    unchanged from 15-03. ───────────────────────────────────────────
    Item {
        id: listBodySlot
        width: parent.width
        height: listColumn.implicitHeight
        visible: root.panelState === "populated"

        Column {
            id: listColumn
            width: parent.width
            spacing: root.spacingSm

            // Group 1 — Connected. No GroupHeader hairline above it (it
            // directly follows the top of the list, matching WifiPanel's
            // own current-connection treatment) — a plain label instead,
            // present only when the group is non-empty.
            Text {
                text: root.groupHeadingFor("connected")
                visible: root.backend ? root.backend.connectedDevices.length > 0 : false
                font.pixelSize: root.fontLabel
                font.weight: root.weightEmphasis
                color: Colours.onSurfaceVariant
            }
            Repeater {
                model: root.backend ? root.backend.connectedDevices : []
                delegate: DeviceRow {
                    device: modelData
                }
            }

            // Group 2 — Paired.
            GroupHeader {
                label: root.groupHeadingFor("paired")
                visible: root.backend ? root.backend.pairedDevices.length > 0 : false
            }
            Repeater {
                model: root.backend ? root.backend.pairedDevices : []
                delegate: DeviceRow {
                    device: modelData
                }
            }

            // ── The empty case (UI-SPEC E5 `empty` backstop, D-15-26's
            //    third branch's "you have paired nothing yet" half) — NOT
            //    a fourth off-state; it lives inside this same populated
            //    branch. Renders only when connected, paired AND
            //    discovered are all empty and no inquiry is running. ─────
            Text {
                id: emptyPairedText
                visible: root.backend
                    ? (root.backend.connectedDevices.length === 0 && root.backend.pairedDevices.length === 0 && root.backend.discoveredDevices.length === 0 && !root.backend.discovering)
                    : false
                text: "No paired devices"
                font.pixelSize: root.fontBody
                color: Colours.onSurfaceVariant
            }

            // ── The discovery section (D-15-18, T-15-04) — one region of
            //    FIXED height, sitting between the paired and discovered
            //    groups so it reads as the discovered group's own heading.
            //    Two states inside that one fixed height so switching
            //    between them never moves the rows above or below. ───────
            Item {
                id: discoverySection
                width: parent.width
                height: root.iconSizeMd

                // *Idle* — the ONLY call site of `startDiscovery()` in
                // this whole repo.
                Item {
                    id: discoveryIdleRow
                    anchors.fill: parent
                    visible: !(root.backend && root.backend.discovering)

                    Text {
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Add device"
                        font.pixelSize: root.fontBody
                        font.weight: root.weightEmphasis
                        color: Colours.primary

                        MouseArea {
                            anchors.fill: parent
                            onClicked: if (root.backend)
                                root.backend.startDiscovery()
                        }
                    }
                }

                // *Discovering* — the indeterminate line, same treatment
                // as the wifi scan (see the header note on why the
                // POSITION differs). The explicit stop affordance is an
                // ADDITION to T-15-04's mitigation, not a substitution: an
                // inquiry a user cannot stop without dismissing the panel
                // is a worse answer to radio contention than one they can.
                Item {
                    id: discoveryActiveRow
                    anchors.fill: parent
                    visible: root.backend ? root.backend.discovering : false

                    Item {
                        id: discoveryProgressTrack
                        anchors.left: parent.left
                        anchors.right: discoveryStopText.left
                        anchors.rightMargin: root.spacingSm
                        anchors.verticalCenter: parent.verticalCenter
                        height: 3

                        Rectangle {
                            anchors.fill: parent
                            radius: height / 2
                            color: Colours.surfaceVariant
                        }
                        Rectangle {
                            id: discoveryProgressSegment
                            height: parent.height
                            radius: height / 2
                            color: Colours.primary
                            width: Motion.motionEnabled ? discoveryProgressTrack.width * 0.3 : discoveryProgressTrack.width
                            x: 0

                            // G-15-1 RC1: same corrected treatment as
                            // WifiPanel.qml's identical sweep idiom — both
                            // legs bind the ambient LOOP PERIOD token
                            // (never the one-shot emphasizedIn/Out
                            // transition durations), easings unchanged.
                            // Sharing the same loop-period token as the
                            // wifi sweep means the two indeterminate lines
                            // run at the same pace, not merely a similar
                            // one.
                            SequentialAnimation {
                                running: (root.backend && root.backend.discovering) && Motion.motionEnabled
                                loops: Animation.Infinite
                                // quick-260821-swp (R-2): "x" is spatial —
                                // retargeted onto the spatial-in/-out pair.
                                NumberAnimation {
                                    target: discoveryProgressSegment
                                    property: "x"
                                    from: 0
                                    to: discoveryProgressTrack.width - discoveryProgressSegment.width
                                    duration: Motion.ambientDuration
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: Motion.spatialInEasing
                                }
                                NumberAnimation {
                                    target: discoveryProgressSegment
                                    property: "x"
                                    from: discoveryProgressTrack.width - discoveryProgressSegment.width
                                    to: 0
                                    duration: Motion.ambientDuration
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: Motion.spatialOutEasing
                                }
                            }
                        }
                    }

                    Text {
                        id: discoveryStopText
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Stop"
                        font.pixelSize: root.fontLabel
                        color: Colours.onSurfaceVariant

                        MouseArea {
                            anchors.fill: parent
                            onClicked: if (root.backend)
                                root.backend.stopDiscovery()
                        }
                    }
                }
            }

            // Group 3 — Discovered (only ever populated once discovery has
            // been asked for).
            GroupHeader {
                label: root.groupHeadingFor("discovered")
                visible: root.backend ? root.backend.discoveredDevices.length > 0 : false
            }
            Repeater {
                model: root.backend ? root.backend.discoveredDevices : []
                delegate: DeviceRow {
                    device: modelData
                }
            }
        }
    }

    // Only the branch actually visible at mount time enters the cascade —
    // matches WifiPanel.qml's own single-array-literal shape.
    bodyCascadeBands: root.noAdapterBranch ? [noAdapterBranchItem] : (root.adapterBlockedBranch ? [adapterBlockedBranchItem] : (root.adapterOffBranch ? [adapterOffBranchItem] : [listBodySlot]))
}
