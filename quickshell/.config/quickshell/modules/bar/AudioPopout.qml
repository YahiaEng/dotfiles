// AudioPopout.qml — the audio section's popout body (Phase 18 Plan 13,
// QBAR-09). The only body this plan ships, and 18-14's template for the
// remaining five. Reads exclusively through the audioBackend handle
// passed down from the capsule, exactly as AudioPanel.qml's own backend
// property already does — it never reaches for a service singleton of
// its own.
//
// Every text element in this file declares its textFormat explicitly as
// the plain variant, including the ones that render a constant — these
// device labels come from the driver or from whichever application
// created the stream, so they are peer-supplied strings and this is the
// same treatment 18-10 gave tray-supplied text (T-18-13-03).
//
// Task 1 shipped the interaction shape: device label, mute toggle, master
// volume, up to three sinks — reusing AudioPanel.qml's own master-volume
// control shape rather than inventing a second gesture. Task 3 (this
// commit) drives bodyState from the backend's own pending/empty signals
// and adds the foot wayfinding link back to AudioPanel.qml.
//
// ── Task 3's read of AudioBackend.qml, recorded rather than assumed ────
// `pipewireReady` (Pipewire.ready) and `outputsPresent` (sinks.length > 0)
// are genuinely distinct: PipeWire can be ready with zero sinks (a real
// host with no output device attached), and can be unready with sinks
// still holding their last-known list from before a restart. This is
// what makes the UI-SPEC E6-loading treatment implementable as written
// rather than aspirational. No whole-backend failure signal exists
// anywhere in AudioBackend.qml — grepped directly, not guessed — so the
// "failed" state stays declared in the frame's vocabulary and
// deliberately UNEXERCISED here, exactly as PanelDialog.qml's own tracer
// left two of its four states unexercised. Do not invent a mapping to
// make the fourth state light up.
import QtQuick
import QtQuick.Controls
import "../"
import "../dashboard"

SectionPopout {
    id: root

    property var audioBackend: null

    sectionId: "audio"
    popoutTitle: "Audio"
    popoutGlyph: (root.audioBackend && root.audioBackend.masterMuted) ? "volume_off" : "volume_up"

    bodyState: {
        if (!root.audioBackend || !root.audioBackend.pipewireReady)
            return "pending";
        if (!root.audioBackend.outputsPresent)
            return "empty";
        return "populated";
    }
    emptyStateGlyph: "volume_off"
    emptyStateText: "No audio output devices found"

    wayfindingLabel: "Open audio settings"
    onWayfindingActivated: PopoutController.requestPanel("audio")

    readonly property var _sink: root.audioBackend ? root.audioBackend.defaultSink : null
    readonly property string _deviceLabel: (root.audioBackend && root._sink) ? root.audioBackend.deviceLabel(root._sink) : ""
    // At most the first three sinks — the cap that keeps this a glance
    // surface; the unbounded list stays AudioPanel.qml's job.
    readonly property var _sinkRows: root.audioBackend ? root.audioBackend.sinks.slice(0, Design.popoutListCap) : []

    // Body content is gated on `bodyState === "populated"` — the same
    // discipline AudioPanel.qml's own outputSection applies — so a
    // pending/empty popout shows the frame's placeholder alone rather
    // than a blank device label and an inert slider rendering underneath
    // it.
    Text {
        visible: root.bodyState === "populated"
        width: parent.width
        text: root._deviceLabel
        textFormat: Text.PlainText
        elide: Text.ElideRight
        font.pixelSize: Design.fontBody
        font.weight: Design.weightEmphasis
        color: Colours.onSurface
    }

    Row {
        visible: root.bodyState === "populated"
        width: parent.width
        height: Design.iconSizeMd
        spacing: Design.spacingMd

        Text {
            id: audioMuteGlyph
            anchors.verticalCenter: parent.verticalCenter
            font.family: Design.symbolFontFamily
            font.pixelSize: Design.iconSizeMd
            textFormat: Text.PlainText
            text: (root.audioBackend && root.audioBackend.masterMuted) ? "volume_off" : "volume_up"
            color: (root.audioBackend && root.audioBackend.masterMuted) ? Colours.onSurfaceVariant : Colours.primary

            // F2 (quick task 260812-69w) — deliberately LEFT AS the plain
            // attached ToolTip, not converted to BarTooltipHost. This
            // popout renders inside SectionPopout's own window, several
            // hundred pixels tall (measured live: popoutW=360,
            // popoutH=334) — Task 1's Probe B showed this tooltip's own
            // Popup clamp landing at y=60, fully clear of this glyph, with
            // no overlap to fix. A bar-anchored layer surface would
            // compute its margins from the wrong window's coordinate
            // space here; converting a site that already renders correctly
            // would be a regression risk for zero benefit.
            MouseArea {
                id: audioMuteMouseArea
                anchors.fill: parent
                hoverEnabled: true
                onClicked: {
                    if (root.audioBackend)
                        root.audioBackend.setMasterMuted(!root.audioBackend.masterMuted);
                }
                ToolTip.visible: audioMuteMouseArea.containsMouse
                ToolTip.text: (root.audioBackend && root.audioBackend.masterMuted) ? "Unmute" : "Mute"
                ToolTip.delay: Design.tooltipDelayMs
            }
        }

        Slider {
            id: audioVolumeSlider
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - audioMuteGlyph.width - Design.spacingMd
            height: parent.height
            from: 0
            to: 1
            // Always bound to the backend's own masterVolume, never a
            // local copy (D-22 truth-driven, the same discipline
            // AudioPanel.qml's identical control follows) — a change made
            // by the wheel gesture or a hardware key shows up here with
            // no interaction of its own.
            value: root.audioBackend ? root.audioBackend.masterVolume : 0
            onMoved: {
                if (root.audioBackend)
                    // setMasterVolume() carries no range clamp of its own
                    // (read from AudioBackend.qml directly, not assumed)
                    // — clamped here at the call site, mirroring the
                    // wheel handler's own identical guard in
                    // MediaConnectivityCapsule.qml.
                    root.audioBackend.setMasterVolume(Math.max(0, Math.min(1, audioVolumeSlider.value)));
            }

            background: Rectangle {
                x: audioVolumeSlider.leftPadding
                y: audioVolumeSlider.topPadding + audioVolumeSlider.availableHeight / 2 - height / 2
                width: audioVolumeSlider.availableWidth
                height: 8
                radius: 4
                color: Colours.surfaceVariant

                Rectangle {
                    width: audioVolumeSlider.visualPosition * parent.width
                    height: parent.height
                    radius: parent.radius
                    color: Colours.primary
                }
            }
            handle: Rectangle {
                x: audioVolumeSlider.leftPadding + audioVolumeSlider.visualPosition * (audioVolumeSlider.availableWidth - width)
                y: audioVolumeSlider.topPadding + audioVolumeSlider.availableHeight / 2 - height / 2
                width: 20
                height: 20
                radius: 10
                color: Colours.primary
            }
        }
    }

    // Up to three sinks, each a selectable row calling the backend's
    // default-sink setter. No stream list, no input section, no per-app
    // mixer — nothing else belongs in a glance surface.
    Column {
        visible: root.bodyState === "populated"
        width: parent.width
        spacing: Design.spacingSm

        Repeater {
            model: root._sinkRows

            Rectangle {
                id: sinkRow
                required property var modelData
                width: parent.width
                height: Design.iconSizeMd + Design.spacingSm * 2
                radius: Design.spacingSm
                color: sinkMouseArea.containsMouse ? Colours.surfaceVariant : "transparent"

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: Design.spacingSm
                    anchors.right: parent.right
                    anchors.rightMargin: Design.spacingSm
                    anchors.verticalCenter: parent.verticalCenter
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    text: root.audioBackend ? root.audioBackend.deviceLabel(sinkRow.modelData) : ""
                    color: Colours.onSurface
                }

                MouseArea {
                    id: sinkMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (root.audioBackend)
                            root.audioBackend.setDefaultSink(sinkRow.modelData);
                    }
                }
            }
        }
    }

    // Task 3 (this same plan) drives bodyState from
    // AudioBackend.pipewireReady/outputsPresent and adds the foot
    // wayfinding link back to AudioPanel.qml — left as a named comment so
    // the next reader finds the reasoning before the code.
}
