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
    // Caelestia's own token is `heightMult 0.7`, and that is what shipped —
    // but it reads as a floating window here rather than as the lock screen
    // ("it reads like a hovered window, because the entire thing occupies a
    // small area of the screen center"). Their 0.7 sits on a heavily blurred
    // screencopy that fuses card and ground into one surface; ours reads as
    // an object on a backdrop. Raised to 0.86, which on a 16:9 output leaves
    // an even 7% margin on every side (the card is k% of BOTH axes, since
    // width is height x 16/9 on a 16/9 screen). Deliberate divergence from
    // the reference, on operator report — see `reference-wins-over-my-taste`
    // for why this needs saying out loud rather than being done quietly.
    readonly property real cardHeight: (root.screen?.height ?? 1440) * 0.86
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

                // ── Now playing ───────────────────────────────────────
                // REBUILT 2026-08-27. This previously centred a 14px title
                // and a 12px artist inside a tall fill-height rounded rect
                // and drew nothing else — the operator's "just a giant
                // round box with tiny text in the middle". The study's own
                // media tile (`lock-screen-studies.html`, article `s-a`)
                // has album art, a bottom-anchored title/artist pair and a
                // progress bar; all three were missing. Content is now
                // bottom-aligned so the tile reads as a panel rather than
                // as a caption floating in space.
                Rectangle {
                    id: mediaTile

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: Design.roundingMd
                    color: Colours.surfaceVariant
                    clip: true

                    readonly property bool hasPlayer: root.mediaBackend && root.mediaBackend.hasPlayer === true
                    readonly property real progress: {
                        if (!hasPlayer || !root.mediaBackend.lengthSeconds)
                            return 0;
                        return Math.max(0, Math.min(1, root.mediaBackend.positionSeconds / root.mediaBackend.lengthSeconds));
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 10

                        // Album art fills the tile's spare height.
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Layout.minimumHeight: 0
                            radius: Design.roundingSm
                            color: Colours.surface
                            clip: true

                            Image {
                                id: art

                                anchors.fill: parent
                                source: mediaTile.hasPlayer && root.mediaBackend.artPath ? "file://" + root.mediaBackend.artPath : ""
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                cache: true
                                visible: status === Image.Ready
                            }

                            // Fallback when there is no art (or none yet).
                            Text {
                                anchors.centerIn: parent
                                visible: !art.visible
                                text: "\u266a"
                                color: Colours.outline
                                font.pixelSize: 40
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: mediaTile.hasPlayer ? root.mediaBackend.displayTitle : qsTr("Nothing playing")
                            color: Colours.onSurface
                            font.pixelSize: 15
                            font.bold: true
                        }

                        Text {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            visible: mediaTile.hasPlayer
                            text: root.mediaBackend ? root.mediaBackend.displayArtist : ""
                            color: Colours.onSurfaceVariant
                            font.pixelSize: 12
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            visible: mediaTile.hasPlayer
                            implicitHeight: 4
                            radius: 2
                            color: Colours.outline

                            Rectangle {
                                width: parent.width * mediaTile.progress
                                height: parent.height
                                radius: 2
                                color: Colours.primary

                                Behavior on width {
                                    NumberAnimation {
                                        duration: Motion.standardDuration
                                        easing.type: Easing.BezierSpline
                                        easing.bezierCurve: Motion.standardEasing
                                    }
                                }
                            }
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
                                // Each metric carries its own accent. They were
                                // all `Colours.primary`, which is what the
                                // operator saw as "the system metrics all have
                                // the same color" — the study drew them apart
                                // (`lock-screen-studies.html`, article `s-a`).
                                { label: qsTr("CPU"), frac: resourcesCol.cpuFrac, accent: Colours.secondary },
                                { label: qsTr("MEM"), frac: resourcesCol.memFrac, accent: Colours.tertiary },
                                { label: qsTr("GPU"), frac: resourcesCol.gpuFrac, accent: Colours.primary }
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
                                        color: modelData.accent
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

                            // Each notification sits on its own chip. They
                            // were bare Text items directly on the tile, which
                            // is exactly the operator's "no styling, it just
                            // looks like white text". The study draws a
                            // recessed rounded chip per notification, with the
                            // app name in the accent.
                            delegate: Rectangle {
                                required property var modelData

                                Layout.fillWidth: true
                                implicitHeight: notifBody.implicitHeight + 16
                                radius: Design.roundingSm
                                color: Colours.surface

                                ColumnLayout {
                                    id: notifBody

                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 1

                                    Text {
                                        Layout.fillWidth: true
                                        elide: Text.ElideRight
                                        text: modelData.appName || qsTr("Notification")
                                        color: Colours.secondary
                                        font.pixelSize: 11
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
