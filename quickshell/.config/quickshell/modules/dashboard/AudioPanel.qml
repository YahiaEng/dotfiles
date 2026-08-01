// AudioPanel.qml — the audio panel body (Phase 15 Plan 02 tracer,
// PANEL-02/PANEL-06). Root type `PanelDialog`, so shell.qml's `LazyLoader`
// mounts this directly, exactly the same shape as `Dashboard`.
//
// This plan renders master volume + mute ONLY. The output/input device
// pickers and the per-app mixer list are deliberately ABSENT, not stubbed
// (no collapsed row, no placeholder, no disabled control) — 15-04 adds
// them onto this same `PanelDialog` body slot.
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

    // ── Master volume + mute — the ONLY body content this plan renders ──
    Item {
        id: masterBlock
        width: parent.width
        implicitHeight: masterRow.implicitHeight

        Row {
            id: masterRow
            width: parent.width
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
                from: 0
                to: 1
                // Always bound to backend.masterVolume, never a local copy
                // (D-22 truth-driven): a change made by waybar or a
                // hardware key shows up here without any panel interaction.
                value: root.backend ? root.backend.masterVolume : 0
                // Continuous write on onMoved — deliberately diverging from
                // MediaTab.qml's commit-on-release, because that analog
                // commits through a shell script per write while this one
                // sets a property on a native PipeWire node (recorded in
                // the SUMMARY).
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
    }

    bodyCascadeBands: [masterBlock]
}
