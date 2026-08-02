// AudioPanel.qml — the audio panel body (Phase 15 Plans 02 and 04,
// PANEL-01/PANEL-02/PANEL-06). Root type `PanelDialog`, so shell.qml's
// `LazyLoader` mounts this directly, exactly the same shape as `Dashboard`.
//
// 15-02 shipped master volume + mute only. 15-04 builds the panel PANEL-01
// and PANEL-02 actually describe: a pinned control block (master volume +
// mute, an output device picker and an input device picker as inline
// expanding rows, an input level slider and a mic mute) that never
// scrolls, above a scrolling per-app mixer list, plus the nothing-playing
// and PipeWire-unreachable states.
//
// ── D-15-10 — the focal point (land verbatim per 15-04-PLAN.md
//    <decision_records>) ────────────────────────────────────────────────
// The pinned control block is this panel's declared focal point (UI-SPEC
// Dimension 2), not just its first element: it carries the highest-
// frequency controls, so it is what the eye must land on before the app
// list. It is pinned rather than scrolled because D-15-10's rule is
// "scroll exactly what is unbounded and nothing else" — the app list is
// unbounded, the master and device controls are not. Its accepted cost,
// recorded rather than discovered later, is that the pinned block shortens
// the app list's viewport.
//
// ── State-composition path (15-04-PLAN.md's own required record) ───────
// `PanelDialog.bodyState` shipped as a `readonly property` (confirmed by
// reading PanelDialog.qml directly, per this plan's own instruction) — an
// instance cannot rebind a readonly property. This panel therefore
// composes its own state regions (`nothingPlaying`, `panelUnreachable`,
// the no-output-device backstop) locally in Task 3, calling the frame's
// `stateColour(state)` function for the palette mapping rather than
// touching `PanelDialog.qml`. 15-05/15-06 should copy this same path.
//
// ── Body-slot inset arithmetic (15-04-PLAN.md's own required record) ───
// `PanelDialog.qml`'s `bodyFlick` anchors `anchors.margins:
// panelWindow.panelPadding` uniformly — ONE inset value applied to all
// four sides, so the vertical insets are `panelPadding` top +
// `panelPadding` bottom (two applications of the same single named
// constant, matching this plan's own arithmetic assumption exactly — no
// correction needed). `bodyViewportHeight` below is derived from that
// reading, not assumed blind.
import QtQuick
import QtQuick.Controls
import "../"

PanelDialog {
    id: root

    property var backend: null

    panelTitle: "Audio"
    panelGlyph: "volume_up"
    namespaceSuffix: "audio-panel"
    // T-15-02's whole mitigation: a literal array of double-quoted string
    // literals, assigned exactly once. Never appended to, never
    // interpolated, never joined into a string.
    advancedCommand: ["pavucontrol"]
    advancedAvailable: root.backend ? root.backend.advancedAvailable : true
    advancedUnavailableReason: "pavucontrol is not installed"

    // controlRowHeight mirrors MediaTab.qml's own constant (32px) — every
    // Slider in this file gets an explicit height matching its row, per
    // 15-02's own Task 1 fix (a Slider whose custom background/handle
    // delegates never set implicitHeight collapses its own implicitHeight
    // to 0 and draws nothing).
    readonly property int controlRowHeight: 32

    // ── D-15-11 fallback flag — the pre-authorized cheap fallback ───────
    // Land verbatim per 15-04-PLAN.md <decision_records>: full input
    // symmetry — input device picker, input level slider and mic mute,
    // mirroring the output block — ships as specified because the user
    // OVERRODE the recommendation (which was device selection plus mic
    // mute only, justified on mic gain being set-once while mic mute is
    // moment-to-moment). This is the second recorded override in the
    // project's history. The user supplied the fallback condition
    // unprompted at decision time and PRE-AUTHORIZED it: if the render
    // gate finds the pinned block too cluttered, drop the input level
    // slider and keep device selection plus mic mute — WITHOUT needing a
    // new decision. Taking that fallback is therefore a gate outcome, not
    // a scope reduction. Flipping this one boolean is the whole cost.
    readonly property bool inputLevelSliderEnabled: true

    // ── D-15-07's fixed frame, restated: the panel window's own geometry
    //    never derives from content. No implicitWidth/implicitHeight/
    //    width/height assignment appears at this root indentation level
    //    anywhere in this file. ────────────────────────────────────────

    // Available vertical space inside the body slot's Flickable viewport —
    // see the "Body-slot inset arithmetic" header note above for the
    // insets this subtracts.
    readonly property int bodyViewportHeight: root.panelHeight - root.headerHeight - root.panelPadding * 2

    // ── DevicePickerRow — the D-15-12 inline expanding row ───────────────
    // Reuses QuickToggles.qml's ToggleChip / MediaTab.qml's TransportButton
    // idiom (a reusable row declared as an inline component in its own
    // consuming file). Collapsed: leading glyph, elided current-device
    // label with a full-name tooltip (E2 long-text locked contract),
    // trailing chevron. Expanded: one selectable row per candidate device,
    // current default marked with a check glyph. Pending/failed are read
    // from the backend and scoped to this row alone (D-15-09) — never
    // panel-wide, never a silent revert.
    component DevicePickerRow: Item {
        id: pickerRow

        property string glyph: ""
        property string heading: ""
        property var currentNode: null
        property var candidates: []
        property string deviceSide: ""
        signal activated(var node)

        property bool _expanded: false
        readonly property bool isPending: root.backend && root.backend.pendingDevice === pickerRow.deviceSide
        readonly property bool isFailed: root.backend && root.backend.failedDevice === pickerRow.deviceSide
        readonly property string currentLabel: root.backend ? root.backend.deviceLabel(pickerRow.currentNode) : ""

        width: parent ? parent.width : 0
        implicitHeight: pickerColumn.implicitHeight
        height: implicitHeight

        // Expansion animates the row's own implicitHeight — the layout
        // below shifts and the app list's viewport shrinks while a picker
        // is open, which is honest and reversible (D-15-12: the animated-
        // layout form ships first because it needs no second surface and
        // no floating type; a locally composed overlay remains Claude's
        // discretion for a later round if the render gate prefers it).
        Behavior on implicitHeight {
            enabled: Motion.motionEnabled
            NumberAnimation {
                duration: Motion.standardDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.standardEasing
            }
        }

        Column {
            id: pickerColumn
            width: parent.width
            spacing: root.spacingXs

            Rectangle {
                id: collapsedRow
                width: parent.width
                height: root.controlRowHeight
                radius: height / 2
                color: Colours.surfaceVariant

                Text {
                    id: leadingGlyph
                    anchors.left: parent.left
                    anchors.leftMargin: root.spacingSm
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: root.symbolFontFamily
                    font.pixelSize: root.iconSizeMd
                    text: pickerRow.glyph
                    color: Colours.onSurfaceVariant
                }

                Text {
                    id: deviceLabelText
                    anchors.left: leadingGlyph.right
                    anchors.leftMargin: root.spacingSm
                    anchors.right: trailingIndicator.left
                    anchors.rightMargin: root.spacingSm
                    anchors.verticalCenter: parent.verticalCenter
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    text: pickerRow.isPending ? "Switching…" : pickerRow.currentLabel
                    font.pixelSize: root.fontBody
                    color: Colours.onSurfaceVariant
                }

                Text {
                    id: chevronGlyph
                    anchors.right: parent.right
                    anchors.rightMargin: root.spacingSm
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: root.symbolFontFamily
                    font.pixelSize: root.iconSizeMd
                    text: pickerRow._expanded ? "expand_less" : "expand_more"
                    color: Colours.onSurfaceVariant
                    visible: !pickerRow.isPending
                }

                // Pending indicator — a pulsing glyph replacing the
                // chevron while this row's switch is in flight, reusing
                // QuickToggles.qml's own pending-pulse motion language
                // (the same emphasizedIn/Out duration+easing pair) rather
                // than inventing a second pending idiom.
                Item {
                    id: trailingIndicator
                    anchors.right: parent.right
                    anchors.rightMargin: root.spacingSm
                    anchors.verticalCenter: parent.verticalCenter
                    width: root.iconSizeMd
                    height: root.iconSizeMd
                    visible: pickerRow.isPending

                    Text {
                        id: pendingGlyph
                        anchors.fill: parent
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.family: root.symbolFontFamily
                        font.pixelSize: root.iconSizeMd
                        text: "sync"
                        color: Colours.primary
                        opacity: 0.4

                        SequentialAnimation {
                            running: pickerRow.isPending && Motion.motionEnabled
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
                }

                MouseArea {
                    id: rowMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    enabled: !pickerRow.isPending
                    onClicked: {
                        if (root.backend)
                            root.backend.clearDeviceFailure();
                        pickerRow._expanded = !pickerRow._expanded;
                    }
                    ToolTip.visible: rowMouseArea.containsMouse && !pickerRow.isPending
                    ToolTip.text: pickerRow.currentLabel
                    ToolTip.delay: Design.tooltipDelayMs
                }
            }

            Column {
                id: expandedColumn
                width: parent.width
                visible: pickerRow._expanded
                spacing: root.spacingXs

                Repeater {
                    model: pickerRow.candidates
                    delegate: Item {
                        id: candidateRow
                        width: expandedColumn.width
                        height: root.controlRowHeight

                        readonly property bool isCurrent: pickerRow.currentNode === modelData

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: root.spacingSm
                            anchors.right: parent.right
                            anchors.rightMargin: root.spacingSm
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: root.spacingSm

                            Text {
                                width: root.iconSizeMd
                                horizontalAlignment: Text.AlignHCenter
                                font.family: root.symbolFontFamily
                                font.pixelSize: root.iconSizeMd
                                text: "check"
                                color: Colours.primary
                                visible: candidateRow.isCurrent
                            }

                            Text {
                                id: candidateLabelText
                                width: parent.width - root.iconSizeMd - root.spacingSm
                                elide: Text.ElideRight
                                maximumLineCount: 1
                                text: root.backend ? root.backend.deviceLabel(modelData) : ""
                                font.pixelSize: root.fontBody
                                color: Colours.onSurface
                            }
                        }

                        MouseArea {
                            id: candidateMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                pickerRow.activated(modelData);
                                pickerRow._expanded = false;
                            }
                            ToolTip.visible: candidateMouseArea.containsMouse
                            ToolTip.text: root.backend ? root.backend.deviceLabel(modelData) : ""
                            ToolTip.delay: Design.tooltipDelayMs
                        }
                    }
                }
            }

            // E2 `error` backstop — row-scoped, never panel-wide, never a
            // silent revert. The next press on the collapsed row above
            // clears this (rowMouseArea.onClicked calls
            // backend.clearDeviceFailure()).
            Text {
                id: failedLabel
                width: parent.width
                visible: pickerRow.isFailed
                text: "Couldn't switch device — press to retry"
                font.pixelSize: root.fontLabel
                color: root.stateColour("failed")
            }
        }
    }

    // ── The pinned control block — the declared focal point, never
    //    scrolls. Sized to its own children's implicitHeight; appListRegion
    //    below claims the remainder of the body viewport. ───────────────
    Item {
        id: pinnedBlock
        width: parent.width
        implicitHeight: pinnedColumn.implicitHeight
        height: implicitHeight

        Column {
            id: pinnedColumn
            width: parent.width
            spacing: root.spacingLg

            // ── Output section: master volume + mute, output picker.
            //    E2 `empty` backstop when no output device exists at all —
            //    renders in PLACE of the master row and the output picker,
            //    with no live-looking-but-inert slider. ──────────────────
            Column {
                id: outputSection
                width: parent.width
                spacing: root.spacingSm
                visible: root.backend ? root.backend.outputsPresent : true

                Row {
                    id: masterRow
                    width: parent.width
                    height: root.controlRowHeight
                    spacing: root.spacingMd

                    Text {
                        id: muteGlyph
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: root.symbolFontFamily
                        font.pixelSize: root.iconSizeMd
                        text: (root.backend && root.backend.masterMuted) ? "volume_off" : "volume_up"
                        color: (root.backend && root.backend.masterMuted) ? Colours.onSurfaceVariant : Colours.primary

                        MouseArea {
                            id: muteMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                if (root.backend)
                                    root.backend.setMasterMuted(!root.backend.masterMuted);
                            }
                            ToolTip.visible: muteMouseArea.containsMouse
                            ToolTip.text: (root.backend && root.backend.masterMuted) ? "Unmute" : "Mute"
                            ToolTip.delay: Design.tooltipDelayMs
                        }
                    }

                    Slider {
                        id: masterVolumeSlider
                        anchors.verticalCenter: parent.verticalCenter
                        width: masterRow.width - muteGlyph.width - root.spacingMd
                        height: masterRow.height
                        from: 0
                        to: 1
                        // Always bound to backend.masterVolume, never a
                        // local copy (D-22 truth-driven): a change made by
                        // waybar or a hardware key shows up here without
                        // any panel interaction.
                        value: root.backend ? root.backend.masterVolume : 0
                        // Continuous write on onMoved — the write is a
                        // native property set on a PipeWire node, not a
                        // subprocess (recorded in 15-02's SUMMARY).
                        onMoved: {
                            if (root.backend)
                                root.backend.setMasterVolume(masterVolumeSlider.value);
                        }

                        background: Rectangle {
                            x: masterVolumeSlider.leftPadding
                            y: masterVolumeSlider.topPadding + masterVolumeSlider.availableHeight / 2 - height / 2
                            width: masterVolumeSlider.availableWidth
                            height: 4
                            radius: 2
                            color: Colours.surfaceVariant

                            Rectangle {
                                width: masterVolumeSlider.visualPosition * parent.width
                                height: parent.height
                                radius: parent.radius
                                color: Colours.primary
                            }
                        }
                        handle: Rectangle {
                            x: masterVolumeSlider.leftPadding + masterVolumeSlider.visualPosition * (masterVolumeSlider.availableWidth - width)
                            y: masterVolumeSlider.topPadding + masterVolumeSlider.availableHeight / 2 - height / 2
                            width: 16
                            height: 16
                            radius: 8
                            color: Colours.primary
                        }
                    }
                }

                DevicePickerRow {
                    id: outputPicker
                    glyph: "speaker"
                    heading: "Output"
                    currentNode: root.backend ? root.backend.defaultSink : null
                    candidates: root.backend ? root.backend.sinks : []
                    deviceSide: "output"
                    onActivated: function (node) {
                        if (root.backend)
                            root.backend.setDefaultSink(node);
                    }
                }
            }

            // E2 `empty` backstop — no output device present at all. Quiet
            // symbol, one line, no button: nothing in this panel can
            // conjure a sound card. Rendered in place of outputSection
            // above (the two are mutually exclusive via `visible`).
            Column {
                id: noOutputState
                width: parent.width
                spacing: root.spacingSm
                visible: root.backend ? !root.backend.outputsPresent : false

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.family: root.symbolFontFamily
                    font.pixelSize: root.iconSizeMd
                    text: "speaker_group"
                    color: root.stateColour("empty")
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.pixelSize: root.fontBody
                    color: root.stateColour("empty")
                    text: "No output device"
                }
            }

            // ── D-15-11 — the user override and its pre-authorized
            //    fallback (land verbatim per 15-04-PLAN.md
            //    <decision_records>) ───────────────────────────────────
            // Full input symmetry — input device picker, input level
            // slider and mic mute, mirroring the output block — ships as
            // specified because the user OVERRODE the recommendation
            // (which was device selection plus mic mute only, justified on
            // mic gain being set-once while mic mute is moment-to-moment).
            // This is the second recorded override in the project's
            // history. The user supplied the fallback condition
            // unprompted at decision time and PRE-AUTHORIZED it: if the
            // render gate finds the pinned block too cluttered, drop the
            // input level slider and keep device selection plus mic mute
            // — WITHOUT needing a new decision. Taking that fallback is
            // therefore a gate outcome, not a scope reduction.
            //
            // The E2 `partial` truth: with no input device present, the
            // mic controls are ABSENT, not disabled — ordinary absence,
            // the same treatment the fallback above already established.
            Column {
                id: inputSection
                width: parent.width
                spacing: root.spacingSm
                visible: root.backend ? root.backend.inputsPresent : false

                DevicePickerRow {
                    id: inputPicker
                    glyph: "mic"
                    heading: "Input"
                    currentNode: root.backend ? root.backend.defaultSource : null
                    candidates: root.backend ? root.backend.sources : []
                    deviceSide: "input"
                    onActivated: function (node) {
                        if (root.backend)
                            root.backend.setDefaultSource(node);
                    }
                }

                // ── A2 disposition note — rendered under the INPUT picker
                //    rather than the output one (a placement divergence
                //    from this plan's generic template text, recorded in
                //    the SUMMARY): 15-API-PROBE.md's bounded re-probe
                //    measured the accepted-and-ignored residual on the
                //    INPUT side only — the output side has no residual to
                //    disclose (it re-routes already-playing streams live).
                //    Visible before the user is surprised, not after. ───
                Text {
                    id: routeNoteText
                    width: parent.width
                    wrapMode: Text.WordWrap
                    font.pixelSize: root.fontLabel
                    color: Colours.onSurfaceVariant
                    text: root.backend ? root.backend.streamRouteNote : ""
                }

                Row {
                    id: micRow
                    width: parent.width
                    height: root.controlRowHeight
                    spacing: root.spacingMd

                    Text {
                        id: micGlyph
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: root.symbolFontFamily
                        font.pixelSize: root.iconSizeMd
                        text: (root.backend && root.backend.inputMuted) ? "mic_off" : "mic"
                        color: (root.backend && root.backend.inputMuted) ? Colours.onSurfaceVariant : Colours.primary

                        MouseArea {
                            id: micMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                if (root.backend)
                                    root.backend.setInputMuted(!root.backend.inputMuted);
                            }
                            ToolTip.visible: micMouseArea.containsMouse
                            ToolTip.text: (root.backend && root.backend.inputMuted) ? "Unmute microphone" : "Mute microphone"
                            ToolTip.delay: Design.tooltipDelayMs
                        }
                    }

                    Slider {
                        id: inputLevelSlider
                        anchors.verticalCenter: parent.verticalCenter
                        width: micRow.width - micGlyph.width - root.spacingMd
                        height: micRow.height
                        from: 0
                        to: 1
                        visible: root.inputLevelSliderEnabled
                        value: root.backend ? root.backend.inputVolume : 0
                        onMoved: {
                            if (root.backend)
                                root.backend.setInputVolume(inputLevelSlider.value);
                        }

                        background: Rectangle {
                            x: inputLevelSlider.leftPadding
                            y: inputLevelSlider.topPadding + inputLevelSlider.availableHeight / 2 - height / 2
                            width: inputLevelSlider.availableWidth
                            height: 4
                            radius: 2
                            color: Colours.surfaceVariant

                            Rectangle {
                                width: inputLevelSlider.visualPosition * parent.width
                                height: parent.height
                                radius: parent.radius
                                color: Colours.primary
                            }
                        }
                        handle: Rectangle {
                            x: inputLevelSlider.leftPadding + inputLevelSlider.visualPosition * (inputLevelSlider.availableWidth - width)
                            y: inputLevelSlider.topPadding + inputLevelSlider.availableHeight / 2 - height / 2
                            width: 16
                            height: 16
                            radius: 8
                            color: Colours.primary
                        }
                    }
                }
            }
        }
    }

    // ── The scrolling per-app mixer list — Task 3 fills this region.
    //    Claims the body viewport's remainder so bodyContent's total
    //    height matches the viewport exactly and the OUTER Flickable
    //    never has anything to scroll; this region gets its own inner
    //    scroller instead (D-15-10 achieved without touching
    //    PanelDialog.qml). ─────────────────────────────────────────────
    Item {
        id: appListRegion
        width: parent.width
        height: Math.max(0, root.bodyViewportHeight - pinnedBlock.height - root.spacingMd)
    }

    bodyCascadeBands: [pinnedBlock]
}
