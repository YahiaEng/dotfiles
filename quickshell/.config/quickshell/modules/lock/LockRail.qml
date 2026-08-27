// LockRail.qml — layout C, "Edge Rail" (quick task 260827-833 Task 3,
// LOCK-01). Built from the design study's own drawing code
// (`.planning/notes/lock-screen-studies.html`, article `s-c`, lines
// 826-900), not its prose. Geometry read straight off that markup: rail
// left:3.2%, top:6%, width:23%, height:88%, radius 1.4cqw — on this
// 2560x1440 output that is 590x1267 at x=82 (the plan's own measured
// figures). `cqw` in the study is 1% of the OUTPUT width — every size
// below is `root.screen.width` scaled the same way.
//
// ── The 3.2% inset is HARDCODED, not read from WindowInset ─────────────
// (MEMORY design-study-ignores-gaps-out). Checked, not assumed: a 3.2%
// inset on this 2560px-wide output is ~82px; `WindowInset.gapLeft`'s live
// value is 10px (its own declared default `_gapsOut: 10`). 82px and 10px
// are not "a few px apart" — the plan's own stated threshold for
// switching to `WindowInset` — so the study's own percentage is used
// as-is rather than aligned to the live reserved-zone value. A lock
// surface is fullscreen, so `hyprland-window-edge-arithmetic.md`'s
// reserved-zone maths does not apply here in the first place; only the
// VISUAL alignment question was live, and it resolved against measurement
// to "keep the study's number."
//
// ── No dimming pass — opaque ground carries all the legibility risk ────
// The study's own "what it costs" note says so directly. `Colours.surface`
// (opaque, not translucent) is used for exactly that reason. Whether it
// reads against a BRIGHT wallpaper cannot be judged from this shell —
// that is operator checklist item 5, not asserted here.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import "../"

Item {
    id: root

    required property LockPam pam

    // ── Exit ──────────────────────────────────────────────────────────
    // Set by LockSurface while its unlock animation runs, so each layout
    // leaves along the axis it arrived on rather than sharing one flat fade.
    property bool unlocking: false
    property var mediaBackend: null
    property var systemResources: null
    property var screen: null

    // 1% of the output width — the study's own `cqw` unit.
    readonly property real cqw: (root.screen?.width ?? 2560) / 100

    Rectangle {
        id: rail

        x: (root.screen?.width ?? 2560) * 0.032
        y: (root.screen?.height ?? 1440) * 0.06
        width: (root.screen?.width ?? 2560) * 0.23
        height: (root.screen?.height ?? 1440) * 0.88
        radius: root.cqw * 1.4
        color: Colours.surface

        // Entrance: the rail arrives from the edge it is anchored to, which
        // is the whole idea of the direction — it should read as something
        // sliding in off-screen, not as a panel materialising in place.
        //
        // Animated through a Translate rather than on `x` directly: `x` here
        // carries a real binding to the output width, and starting an
        // animation on a bound property destroys the binding. That is
        // precisely how Split Canvas shipped invisible
        // (`qml-configured-after-construction`). A transform is independent
        // of the binding, so there is nothing to lose.
        opacity: 0
        transform: [
        Translate {
            // The "tiny delay before it kicks in" was not a delay — there is
            // no PauseAnimation here. It was the EASING: `emphasized-in`'s
            // bezier starts at [0.05, 0], an almost flat ramp, so the first
            // ~15% of a 400-500ms animation covers almost no distance and
            // reads as dead time. `spatial-in` starts at [0.38, 1.21] and
            // moves immediately. Measured from ~/.local/state/theme/motion.json,
            // not from Motion.qml's fallbacks.
            NumberAnimation on x {
                from: -((root.screen?.width ?? 2560) * 0.262)
                to: 0
                duration: Motion.spatialInDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.spatialInEasing
            }
        },
        // Exit: back out the way it came. Composed as a second Translate
        // because the entrance animation owns the first one's `x` outright.
        Translate {
            x: root.unlocking ? -((root.screen?.width ?? 2560) * 0.262) : 0
            Behavior on x {
                NumberAnimation {
                    duration: Motion.emphasizedOutDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.emphasizedOutEasing
                }
            }
        }
        ]
        NumberAnimation on opacity {
            from: 0
            to: 1
            duration: Motion.standardDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Motion.standardEasing
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: root.cqw * 1.6
            spacing: root.cqw * 1.1

            // Stacked hour/minute clock, left-aligned, tight line-height —
            // NOT the shared LockClock primitive here: the study's rail
            // clock is a two-LINE stack (hour above minute), while
            // LockClock's own layout is a single horizontal row shared by
            // the other four layouts. Built inline to match the study
            // exactly.
            SystemClock {
                id: railClock
                enabled: true
                precision: SystemClock.Minutes
            }

            ColumnLayout {
                spacing: -root.cqw * 0.3

                Text {
                    text: Qt.formatDateTime(railClock.date, "hh")
                    color: Colours.primary
                    font.pixelSize: root.cqw * 3.4
                    font.bold: true
                }
                Text {
                    text: Qt.formatDateTime(railClock.date, "mm")
                    color: Colours.secondary
                    font.pixelSize: root.cqw * 3.4
                    font.bold: true
                }
            }

            SystemClock {
                id: railDateClock
                enabled: true
                precision: SystemClock.Days
            }

            Text {
                text: Qt.formatDateTime(railDateClock.date, "ddd").toUpperCase() + " · " + Qt.formatDateTime(railDateClock.date, "d MMMM").toUpperCase()
                color: Colours.onSurfaceVariant
                font.pixelSize: root.cqw * 0.66
                font.letterSpacing: root.cqw * 0.1
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: Math.max(1, root.cqw * 0.06)
                color: Qt.rgba(Colours.outline.r, Colours.outline.g, Colours.outline.b, 0.35)
            }

            RowLayout {
                spacing: root.cqw * 0.8

                Rectangle {
                    implicitWidth: root.cqw * 2.6
                    implicitHeight: root.cqw * 2.6
                    radius: width / 2
                    color: Qt.rgba(Colours.onSurface.r, Colours.onSurface.g, Colours.onSurface.b, 0.10)

                    Image {
                        id: railFace
                        anchors.fill: parent
                        source: Quickshell.env("HOME") + "/.face"
                        visible: status === Image.Ready
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                    }
                }

                ColumnLayout {
                    spacing: root.cqw * 0.18

                    Text {
                        text: Quickshell.env("USER")
                        color: Colours.onSurface
                        font.pixelSize: root.cqw * 0.78
                        font.weight: Font.Medium
                    }
                    Text {
                        text: qsTr("Arch · Hyprland")
                        color: Colours.onSurfaceVariant
                        font.pixelSize: root.cqw * 0.6
                    }
                }
            }

            LockField {
                Layout.fillWidth: true
                Layout.preferredHeight: root.cqw * 2.3
                pam: root.pam
                fieldRadius: root.cqw * 0.7
            }

            // Moved here 2026-08-27. It previously sat at the very bottom of
            // the rail, below the resources and media tiles, so "wrong
            // password" and "caps lock is on" appeared nowhere near the
            // input that produced them. Feedback belongs adjacent to its
            // control.
            LockStatus {
                Layout.fillWidth: true
                pam: root.pam
            }

            Item {
                Layout.fillHeight: true
            }

            ColumnLayout {
                id: resourceRows
                Layout.fillWidth: true
                spacing: root.cqw * 0.55

                readonly property real cpuFrac: root.systemResources ? root.systemResources.cpuFraction : 0
                readonly property real memFrac: root.systemResources ? root.systemResources.memoryFraction : 0

                Repeater {
                    model: [
                        { label: "CPU", frac: resourceRows.cpuFrac, colour: Colours.primary },
                        { label: "MEM", frac: resourceRows.memFrac, colour: Colours.tertiary }
                    ]

                    delegate: ColumnLayout {
                        required property var modelData
                        Layout.fillWidth: true
                        spacing: root.cqw * 0.2

                        RowLayout {
                            Layout.fillWidth: true
                            Text {
                                text: modelData.label
                                color: Colours.onSurfaceVariant
                                font.pixelSize: root.cqw * 0.6
                            }
                            Item { Layout.fillWidth: true }
                            Text {
                                text: Math.round(modelData.frac * 100) + "%"
                                color: Colours.onSurfaceVariant
                                font.pixelSize: root.cqw * 0.6
                            }
                        }
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: Math.max(1, root.cqw * 0.16)
                            radius: height / 2
                            color: Qt.rgba(Colours.outline.r, Colours.outline.g, Colours.outline.b, 0.35)

                            Rectangle {
                                width: parent.width * Math.max(0, Math.min(1, modelData.frac))
                                height: parent.height
                                radius: height / 2
                                color: modelData.colour
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: railMediaRow.implicitHeight + root.cqw * 1.2
                radius: root.cqw * 0.7
                color: Qt.rgba(Colours.surfaceVariant.r, Colours.surfaceVariant.g, Colours.surfaceVariant.b, 0.55)
                visible: root.mediaBackend && root.mediaBackend.hasPlayer === true

                RowLayout {
                    id: railMediaRow
                    anchors.fill: parent
                    anchors.margins: root.cqw * 0.7
                    spacing: root.cqw * 0.8

                    Rectangle {
                        implicitWidth: root.cqw * 2
                        implicitHeight: root.cqw * 2
                        radius: root.cqw * 0.4
                        color: Colours.primary
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: root.cqw * 0.15

                        Text {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: root.mediaBackend ? root.mediaBackend.displayTitle : ""
                            color: Colours.onSurface
                            font.pixelSize: root.cqw * 0.66
                        }
                        Text {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: root.mediaBackend ? root.mediaBackend.displayArtist : ""
                            color: Colours.onSurfaceVariant
                            font.pixelSize: root.cqw * 0.58
                        }
                    }
                }
            }

        }
    }
}
