// LockCaelestia.qml — layout A, "Three columns" (quick task 260827-833
// Task 2, LOCK-01). Built from the vendored reference source
// (`.planning/notes/caelestia-lock/Content.qml`, `Center.qml`,
// `WeatherInfo.qml`, `Fetch.qml`, `Media.qml`, `Resources.qml`,
// `NotifDock.qml`, `center/ProfilePic.qml`), NOT from the design study's
// prose — the operator has been burned twice by "improving" Caelestia's
// own values (MEMORY reference-wins-over-my-taste). The card size, the
// centre column's width formula and its `centerScale` clamp are copied
// exactly: `heightMult 0.7`, `ratio 16/9`, `centerWidth 600`, `centerScale
// = min(1, screen.height / 1440)` — 1792x1008 with a 600px centre column
// on this 2560x1440 output.
//
// Left/right column tiles read this shell's OWN backends
// (WeatherBackend/MediaBackend/SystemResources/NotifServer), relayed down
// read-only from Lock.qml — NOT Caelestia's SysInfo/UPower/Weather
// services, which do not exist here. `MaterialShape`/`StyledRect`/
// `WrappedLoader` (Caelestia C++ plugin and QML-library types) are not
// installed; every visual primitive below is plain QtQuick, matching
// LockField's own precedent (Task 1) of trading a bespoke shape library
// for this repo's plain-Rectangle idiom.
//
// The avatar block is copied from THIS repo's own
// `modules/dashboard/DashBento.qml` (~/.face, circular MultiEffect mask,
// "person" glyph fallback) — an existing, already-working local pattern
// for the exact same need Caelestia's `ProfilePic.qml` describes, not a
// re-invention.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import "../"
import "../dashboard"
import "../notifications"

Item {
    id: root

    required property LockPam pam
    property var mediaBackend: null
    property var weatherBackend: null
    property var systemResources: null
    property var screen: null

    readonly property real centerScale: Math.min(1, (root.screen?.height ?? 1440) / 1440)
    readonly property real cardHeight: (root.screen?.height ?? 1440) * 0.7
    readonly property real cardWidth: root.cardHeight * (16 / 9)
    readonly property real centerWidth: 600 * root.centerScale

    Rectangle {
        id: card

        anchors.centerIn: parent
        width: root.cardWidth
        height: root.cardHeight
        radius: Design.roundingXl
        color: Colours.surface

        RowLayout {
            anchors.fill: parent
            anchors.margins: 40
            spacing: 48

            // ── Left column: weather / fetch / media ──────────────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 16

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: weatherCol.implicitHeight + 32
                    radius: Design.roundingMd
                    color: Colours.surfaceVariant

                    ColumnLayout {
                        id: weatherCol
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 4

                        readonly property var current: root.weatherBackend ? root.weatherBackend.current : null

                        Text {
                            text: weatherCol.current ? Math.round(weatherCol.current.temperature) + "°" : qsTr("—")
                            color: Colours.onSurface
                            font.pixelSize: 32
                            font.bold: true
                        }
                        Text {
                            text: weatherCol.current ? weatherCol.current.label : qsTr("Weather unavailable")
                            color: Colours.onSurfaceVariant
                            font.pixelSize: 13
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: fetchCol.implicitHeight + 32
                    radius: Design.roundingMd
                    color: Colours.surfaceVariant

                    ColumnLayout {
                        id: fetchCol
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 6

                        Text {
                            text: qsTr("Arch Linux")
                            color: Colours.primary
                            font.pixelSize: 13
                            font.bold: true
                        }
                        Text {
                            text: qsTr("WM: Hyprland")
                            color: Colours.onSurfaceVariant
                            font.pixelSize: 12
                        }
                        Text {
                            text: qsTr("Shell: %1").arg(Quickshell.env("SHELL") || "fish")
                            color: Colours.onSurfaceVariant
                            font.pixelSize: 12
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Design.roundingMd
                    color: Colours.surfaceVariant

                    ColumnLayout {
                        anchors.centerIn: parent
                        width: parent.width - 32
                        spacing: 4

                        readonly property bool hasPlayer: root.mediaBackend && root.mediaBackend.hasPlayer === true

                        Text {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                            text: parent.hasPlayer ? root.mediaBackend.displayTitle : qsTr("Nothing playing")
                            color: Colours.onSurface
                            font.pixelSize: 14
                        }
                        Text {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            horizontalAlignment: Text.AlignHCenter
                            visible: parent.hasPlayer
                            text: root.mediaBackend ? root.mediaBackend.displayArtist : ""
                            color: Colours.onSurfaceVariant
                            font.pixelSize: 12
                        }
                    }
                }
            }

            // ── Centre column: clock / date / avatar / field / status ──
            ColumnLayout {
                Layout.preferredWidth: root.centerWidth
                Layout.fillWidth: false
                Layout.fillHeight: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 24

                LockClock {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 16
                    scale: 0.75 * root.centerScale
                }

                SystemClock {
                    id: dateClock
                    enabled: true
                    precision: SystemClock.Days
                }

                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: Qt.formatDateTime(dateClock.date, "dddd • d MMM").toUpperCase()
                    color: Colours.onSurface
                    font.pixelSize: 15
                    font.bold: true
                }

                // Avatar — copied from modules/dashboard/DashBento.qml's
                // own ~/.face circular-mask pattern (~line 300-353), not
                // reinvented; NOT the avatar the operator rejected (that
                // one was a themed hyprlock circle in the continuity
                // composition, deleted permanently there).
                Item {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.topMargin: 24 * root.centerScale
                    Layout.bottomMargin: 16 * root.centerScale

                    readonly property real avatarSize: 96 * root.centerScale
                    width: avatarSize
                    height: avatarSize

                    Rectangle {
                        anchors.fill: parent
                        radius: width / 2
                        color: Qt.rgba(Colours.onSurface.r, Colours.onSurface.g, Colours.onSurface.b, 0.10)
                    }

                    Image {
                        id: faceImage
                        anchors.fill: parent
                        source: Quickshell.env("HOME") + "/.face"
                        visible: false
                        fillMode: Image.PreserveAspectCrop
                        sourceSize.width: parent.width * 2
                        sourceSize.height: parent.height * 2
                        asynchronous: true
                    }

                    Rectangle {
                        id: faceMask
                        anchors.fill: parent
                        radius: width / 2
                        visible: false
                        layer.enabled: true
                    }

                    MultiEffect {
                        anchors.fill: parent
                        source: faceImage
                        maskEnabled: true
                        maskSource: faceMask
                        maskThresholdMin: 0.5
                        maskSpreadAtMin: 1.0
                        visible: faceImage.status === Image.Ready
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: faceImage.status !== Image.Ready
                        text: "person"
                        font.family: Design.symbolFontFamily
                        font.pixelSize: parent.avatarSize * 0.5
                        color: Colours.onSurfaceVariant
                    }
                }

                LockField {
                    Layout.alignment: Qt.AlignHCenter
                    Layout.preferredWidth: root.centerWidth * 0.8
                    Layout.preferredHeight: 55 * Math.max(0.8, root.centerScale)
                    pam: root.pam
                    fieldRadius: height / 2
                }

                LockStatus {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    pam: root.pam
                }
            }

            // ── Right column: resources / notification dock ───────────
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 16

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: resourcesCol.implicitHeight + 32
                    radius: Design.roundingMd
                    color: Colours.surfaceVariant

                    ColumnLayout {
                        id: resourcesCol
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 8

                        readonly property real cpuFrac: root.systemResources ? root.systemResources.cpuFraction : 0
                        readonly property real memFrac: root.systemResources ? root.systemResources.memoryFraction : 0
                        readonly property real gpuFrac: root.systemResources ? root.systemResources.gpuFraction : 0

                        Repeater {
                            model: [
                                { label: qsTr("CPU"), frac: resourcesCol.cpuFrac },
                                { label: qsTr("MEM"), frac: resourcesCol.memFrac },
                                { label: qsTr("GPU"), frac: resourcesCol.gpuFrac }
                            ]

                            delegate: ColumnLayout {
                                required property var modelData
                                Layout.fillWidth: true
                                spacing: 2

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: modelData.label
                                        color: Colours.onSurfaceVariant
                                        font.pixelSize: 11
                                    }
                                    Item { Layout.fillWidth: true }
                                    Text {
                                        text: Math.round(modelData.frac * 100) + "%"
                                        color: Colours.onSurface
                                        font.pixelSize: 11
                                    }
                                }
                                Rectangle {
                                    Layout.fillWidth: true
                                    implicitHeight: 4
                                    radius: 2
                                    color: Colours.outline
                                    Rectangle {
                                        width: parent.width * Math.max(0, Math.min(1, modelData.frac))
                                        height: parent.height
                                        radius: 2
                                        color: Colours.primary
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Design.roundingMd
                    color: Colours.surfaceVariant
                    clip: true

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 8

                        Text {
                            text: qsTr("Notifications")
                            color: Colours.onSurfaceVariant
                            font.pixelSize: 12
                            font.bold: true
                        }

                        Repeater {
                            model: NotifServer.history.slice(0, 4)

                            delegate: ColumnLayout {
                                required property var modelData
                                Layout.fillWidth: true
                                spacing: 0

                                Text {
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                    text: modelData.appName || qsTr("Notification")
                                    color: Colours.onSurface
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                                Text {
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                    text: modelData.summary || ""
                                    color: Colours.onSurfaceVariant
                                    font.pixelSize: 11
                                }
                            }
                        }

                        Text {
                            visible: NotifServer.history.length === 0
                            text: qsTr("No notifications")
                            color: Colours.onSurfaceVariant
                            font.pixelSize: 12
                        }

                        Item { Layout.fillHeight: true }
                    }
                }
            }
        }
    }
}
