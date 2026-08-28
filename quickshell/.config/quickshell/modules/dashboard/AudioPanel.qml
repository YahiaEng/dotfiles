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
//
// ── Task 4 render-gate fix — the pinned-block/list hierarchy (land
//    verbatim for 15-05/15-06 to mirror) ────────────────────────────────
// The render gate's check 1 (focal point, D-15-10) FAILED as shipped:
// master volume, mic level and every per-app row drew an identical pink
// track and handle at identical visual weight, so the panel read as a
// stack of five interchangeable sliders. There was also no divider, no
// section label and no other marker showing where the pinned block ends
// and the scrolling app list begins — the mic caption text was the only
// thing breaking the run. Two presentation-only moves fix it, neither
// touching `AudioBackend.qml` nor any binding:
//   1. `sectionDivider` — a `Colours.outline` hairline plus an
//      "Applications" section label — renders between `pinnedBlock` and
//      `appListRegion`, naming the boundary explicitly instead of leaving
//      it to be inferred.
//   2. `masterVolumeSlider`'s track and handle are drawn heavier than
//      every other slider in the panel (8px/20px vs. the shared 4px/16px
//      every other slider uses), so the pinned block's own primary
//      control reads as primary rather than as the one slider that
//      happened not to be near-full.
// Check 2 (density, D-15-11's pre-authorized fallback) PASSED as shipped
// and the fallback was explicitly DECLINED: the panel was judged not
// cluttered — there is significant empty space below the per-app list —
// so dropping the input level slider would cost PANEL-01 capability for
// no readability gain. The input level slider stays.
// This hierarchy — an explicit pinned/list boundary plus extra weight on
// the pinned block's own primary control — is the pattern 15-05 (wifi
// network list) and 15-06 (bluetooth device list) should mirror against
// their own primary control and their own scrolling list, not an
// audio-only special case.
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
                }
                // ThemedToolTip (quick-260821-6z1 fix wave) — replaces the
                // bare attached ToolTip shorthand; see ThemedToolTip.qml.
                ThemedToolTip {
                    visible: rowMouseArea.containsMouse && !pickerRow.isPending
                    text: pickerRow.currentLabel
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
                        }
                        ThemedToolTip {
                            visible: candidateMouseArea.containsMouse
                            text: root.backend ? root.backend.deviceLabel(modelData) : ""
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
        visible: !root.panelUnreachable

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
                        }
                        ThemedToolTip {
                            visible: muteMouseArea.containsMouse
                            text: (root.backend && root.backend.masterMuted) ? "Unmute" : "Mute"
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
                        // local copy (D-22 truth-driven): a change made
                        // externally or by a hardware key shows up here
                        // without any panel interaction.
                        value: root.backend ? root.backend.masterVolume : 0
                        // Continuous write on onMoved — the write is a
                        // native property set on a PipeWire node, not a
                        // subprocess (recorded in 15-02's SUMMARY).
                        onMoved: {
                            if (root.backend)
                                root.backend.setMasterVolume(masterVolumeSlider.value);
                        }

                        // Track/handle are deliberately heavier than every
                        // other slider in this panel (8px/20px here vs. the
                        // shared 4px/16px the input-level slider and every
                        // per-app row slider use) — the Task 4 render-gate
                        // fix's weight differentiation, see the file
                        // header's "Task 4 render-gate fix" note. This is
                        // the pinned block's own primary control and reads
                        // as primary regardless of its current value.
                        background: Rectangle {
                            x: masterVolumeSlider.leftPadding
                            y: masterVolumeSlider.topPadding + masterVolumeSlider.availableHeight / 2 - height / 2
                            width: masterVolumeSlider.availableWidth
                            height: 8
                            radius: 4
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
                            width: 20
                            height: 20
                            radius: 10
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
                        }
                        ThemedToolTip {
                            visible: micMouseArea.containsMouse
                            text: (root.backend && root.backend.inputMuted) ? "Unmute microphone" : "Mute microphone"
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

    // ── The PipeWire-unreachable state (E1 `error`, NEW locked contract) ─
    // Single named producer, bound to the negation of the backend's
    // readiness property. This is deliberately NOT the nothing-playing
    // treatment: nothing-playing means the controls still work and there
    // is simply nothing to mix, while unreachable means nothing in the
    // panel can do anything — rendering live-looking sliders that
    // silently do nothing is the exact failure this state exists to
    // avoid. `PanelDialog.bodyState` shipped `readonly` (confirmed by
    // reading PanelDialog.qml — see the file header's state-composition
    // note), so this state is composed locally rather than bound onto the
    // frame's own placeholder; `stateColour(state)` is still called for
    // the palette mapping.
    readonly property bool panelUnreachable: root.backend ? !root.backend.pipewireReady : false

    readonly property int appRowLabelWidth: 168

    // ── sectionDivider — the Task 4 render-gate fix's boundary marker
    //    between the pinned block and the scrolling app list (see the file
    //    header's "Task 4 render-gate fix" note). A plain `Colours.outline`
    //    hairline plus one `Design.fontLabel` heading, so the eye has an
    //    explicit marker instead of inferring the boundary from the mic
    //    caption alone. Hidden together with both the block and the list
    //    under `panelUnreachable` — `Column`'s own invisible-child rule
    //    (matching `pinnedBlock`/`appListRegion`'s existing pattern) means
    //    an invisible `sectionDivider`'s height silently becomes 0 in the
    //    shared `bodyContent` `Column` the frame owns, so no separate guard
    //    is needed anywhere this item's height is read. ───────────────────
    Column {
        id: sectionDivider
        width: parent.width
        visible: !root.panelUnreachable
        spacing: root.spacingXs

        Rectangle {
            width: parent.width
            height: 1
            color: Colours.outlineVariant
        }

        Text {
            text: "Applications"
            font.pixelSize: root.fontLabel
            font.weight: root.weightEmphasis
            color: Colours.onSurfaceVariant
        }
    }

    // ── The scrolling per-app mixer list. Claims the body viewport's
    //    remainder so bodyContent's total height matches the viewport
    //    exactly and the OUTER Flickable never has anything to scroll;
    //    this region gets its own inner scroller instead (D-15-10
    //    achieved without touching PanelDialog.qml). Hidden entirely
    //    (not merely emptied) when panelUnreachable holds, since that
    //    state replaces the WHOLE body, pinned block included. `sectionDivider`
    //    adds a second `spacingMd` gap in the shared `bodyContent` `Column`
    //    (pinnedBlock -> sectionDivider -> appListRegion is now three
    //    visible siblings, not two), so the remainder arithmetic below
    //    subtracts `sectionDivider.height` and `spacingMd * 2` rather than
    //    the single `spacingMd` it subtracted before this fix. ───────────
    Item {
        id: appListRegion
        width: parent.width
        height: Math.max(0, root.bodyViewportHeight - pinnedBlock.height - sectionDivider.height - root.spacingMd * 2)
        visible: !root.panelUnreachable

        // ── StreamRow — the D-15-13 three-element per-app row. `node` is
        //    bound explicitly at the ListView delegate site below (the
        //    established pattern in this file — DevicePickerRow's own API
        //    takes explicit properties rather than relying on implicit
        //    delegate context access inside the component body). ────────
        component StreamRow: Item {
            id: streamRow

            property var node: null
            readonly property bool muted: (streamRow.node && streamRow.node.audio) ? streamRow.node.audio.muted : false
            readonly property real streamVolume: (streamRow.node && streamRow.node.audio) ? streamRow.node.audio.volume : 0

            width: appListRegion.width
            height: root.controlRowHeight

            Row {
                id: streamRowLayout
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: root.spacingSm

                // 1. Icon-as-mute. The muted-speaker glyph in this icon
                //    set IS the slashed form (D-15-13's slash treatment)
                //    — no hand-drawn overlay is added on top of it.
                Text {
                    id: streamIconGlyph
                    width: root.iconSizeMd
                    horizontalAlignment: Text.AlignHCenter
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: root.symbolFontFamily
                    font.pixelSize: root.iconSizeMd
                    text: streamRow.muted ? "volume_off" : (root.backend ? root.backend.streamIcon(streamRow.node) : "volume_up")
                    color: streamRow.muted ? Colours.onSurfaceVariant : Colours.onSurface

                    MouseArea {
                        id: streamMuteArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: {
                            if (root.backend)
                                root.backend.setStreamMuted(streamRow.node, !streamRow.muted);
                        }
                    }
                    ThemedToolTip {
                        visible: streamMuteArea.containsMouse
                        text: streamRow.muted ? "Unmute" : "Mute"
                    }
                }

                // 2. Application name — one line, elided, full name on
                //    hover (E1 long-text locked contract).
                Text {
                    id: streamLabelText
                    width: root.appRowLabelWidth
                    anchors.verticalCenter: parent.verticalCenter
                    elide: Text.ElideRight
                    maximumLineCount: 1
                    text: root.backend ? root.backend.streamLabel(streamRow.node) : ""
                    font.pixelSize: root.fontBody
                    color: Colours.onSurface

                    MouseArea {
                        id: streamLabelHover
                        anchors.fill: parent
                        hoverEnabled: true
                    }
                    ThemedToolTip {
                        visible: streamLabelHover.containsMouse
                        text: root.backend ? root.backend.streamLabel(streamRow.node) : ""
                    }
                }

                // 3. Slider — fills the remaining width. Muted state
                //    carried a THIRD way here (glyph + icon colour above,
                //    now the track fill), comfortably exceeding D-15-13's
                //    "carried twice", applying Phase 14's render-gate
                //    remedy rather than repeating its mistake.
                Slider {
                    id: streamVolumeSlider
                    anchors.verticalCenter: parent.verticalCenter
                    width: streamRowLayout.width - streamIconGlyph.width - streamLabelText.width - root.spacingSm * 2
                    height: root.controlRowHeight
                    from: 0
                    to: 1
                    value: streamRow.streamVolume
                    onMoved: {
                        if (root.backend)
                            root.backend.setStreamVolume(streamRow.node, streamVolumeSlider.value);
                    }

                    background: Rectangle {
                        x: streamVolumeSlider.leftPadding
                        y: streamVolumeSlider.topPadding + streamVolumeSlider.availableHeight / 2 - height / 2
                        width: streamVolumeSlider.availableWidth
                        height: 4
                        radius: 2
                        color: Colours.surfaceVariant

                        Rectangle {
                            width: streamVolumeSlider.visualPosition * parent.width
                            height: parent.height
                            radius: parent.radius
                            color: streamRow.muted ? Colours.onSurfaceVariant : Colours.primary
                        }
                    }
                    handle: Rectangle {
                        x: streamVolumeSlider.leftPadding + streamVolumeSlider.visualPosition * (streamVolumeSlider.availableWidth - width)
                        y: streamVolumeSlider.topPadding + streamVolumeSlider.availableHeight / 2 - height / 2
                        width: 16
                        height: 16
                        radius: 8
                        color: streamRow.muted ? Colours.onSurfaceVariant : Colours.primary
                    }
                }
            }
        }

        // ── The nothing-playing state (D-15-26 case 4, E1 `empty`) ──────
        // Single named producer: true when the backend is reachable and
        // its ordered stream list is empty. Confined to appListRegion —
        // the pinned master row, both device pickers and the mic controls
        // stay fully live and interactive. This is the ONE D-15-26 case
        // explicitly NOT treated as an off/degraded state — nobody should
        // later "fix" it into one.
        readonly property bool nothingPlaying: root.backend ? (root.backend.pipewireReady && root.backend.streamNodes.length === 0) : false

        ListView {
            id: streamListView
            anchors.fill: parent
            clip: true
            boundsBehavior: Flickable.StopAtBounds
            spacing: root.spacingSm
            visible: !appListRegion.nothingPlaying
            model: root.backend ? root.backend.streamNodes : []
            // Ordering comes from the backend's node-id-ascending list and
            // is never re-sorted here by volume, name or activity — a row
            // must never move because its own slider moved. Row identity
            // is the node id via the backend's key function, never the
            // application name — two concurrent streams from one
            // application render as two independently-mutable rows. The
            // delegate reads nothing from its own index.
            delegate: StreamRow {
                node: modelData
            }
        }
        // Scroll indicator (quick task 260828-pol). Sibling of the view,
        // never a child: a Flickable/ListView appends Item children to its
        // scrolled contentItem, so a bar declared inside scrolls away.
        ThemedScrollBar {
            flickable: streamListView
        }

        // Rendered whole, not staggered (D-15-08): staggering N
        // asynchronously-arriving rows at D-21's offsets breaks the
        // settled-under-700ms fence and is incoherent for items that
        // arrive at different times anyway. appListRegion is deliberately
        // NOT a cascade band (see bodyCascadeBands below).
        Column {
            id: nothingPlayingPlaceholder
            anchors.centerIn: parent
            visible: appListRegion.nothingPlaying
            spacing: root.spacingSm

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                font.family: root.symbolFontFamily
                font.pixelSize: root.iconSizeMd
                text: "music_off"
                color: root.stateColour("empty")
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: root.fontBody
                color: root.stateColour("empty")
                text: "Nothing is playing"
            }
        }
    }

    // ── The PipeWire-unreachable state (E1 `error`) — replaces the WHOLE
    //    body (pinnedBlock + appListRegion together) with the D-15-26
    //    case 2 unfixable-empty grammar: quiet symbol, one line naming
    //    the cause, NO button of any kind. The header's Advanced button
    //    stays available and untouched — it is the escape hatch, and the
    //    frame owns it. ───────────────────────────────────────────────
    Item {
        id: panelUnreachablePlaceholder
        width: parent.width
        height: root.bodyViewportHeight
        visible: root.panelUnreachable

        Column {
            anchors.centerIn: parent
            spacing: root.spacingSm

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                font.family: root.symbolFontFamily
                font.pixelSize: root.iconSizeMd
                text: "sync_problem"
                color: root.stateColour("empty")
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: root.fontBody
                color: root.stateColour("empty")
                text: "Audio isn't available — PipeWire isn't running"
            }
        }
    }

    bodyCascadeBands: [pinnedBlock]
}
