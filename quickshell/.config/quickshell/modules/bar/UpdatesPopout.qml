// modules/bar/UpdatesPopout.qml — what the updates pill shows before it
// upgrades anything (quick task 260828-75k, direction D5).
//
// ── WHY THIS EXISTS ───────────────────────────────────────────────────
// The pill had no popout. Clicking it called `launchUpgrade()` directly,
// which opens the terminal on `paru -Syu` immediately — so there was no
// way to see WHAT was about to change without starting the transaction.
// The pill's `clickable` is now false, which lets the click fall through
// to the PopoutTrigger that wraps it, and this card is what appears.
//
// The upgrade action moves here, onto a button that sits under the list
// of what it will do. Same command, same terminal handoff, same
// notification on success — only now it is the second thing you do
// rather than the first.
//
// ── ONE OWNER FOR THE UPGRADE ─────────────────────────────────────────
// This card REPORTS from PackagesBackend and calls SystemCapsule's own
// `launchUpgrade()` through the `upgrade` signal rather than shelling
// `paru` itself. The capsule keeps that Process because it is the thing
// that can still be alive to fire the completion notification; a popout
// is destroyed the moment it dismisses.
//
// ── WHY IT LIVES IN packages/ AND NOT bar/ ────────────────────────────
// modules/bar/ has NO explicit qmldir — it relies on Quickshell's
// directory-scanner synthesis, and a file added there did not resolve on
// hot reload ("UpdatesPopout is not a type", which took the whole bar
// down until it was moved). modules/packages/ has an explicit manifest
// this file is declared in, and the popout is package-domain anyway.
import QtQuick
import ".."
import "../dashboard"
import "../packages"

SectionPopout {
    id: root

    // Raised by the capsule, which owns the upgrade Process and its
    // completion notification.
    signal upgrade

    sectionId: "updates"
    popoutTitle: "Updates"
    // Same ligature the pill itself uses, so the card names the glyph
    // that summoned it.
    popoutGlyph: "deployed_code_update"

    readonly property var _updates: PackagesBackend.allUpdates

    bodyState: {
        if (!PackagesBackend.updatesProbed)
            return "empty";
        return root._updates.length > 0 ? "populated" : "empty";
    }
    emptyStateGlyph: "deployed_code_update"
    emptyStateText: PackagesBackend.updatesProbed ? "Up to date" : "Checking for updates…"

    wayfindingLabel: "Open package manager"
    onWayfindingActivated: PackagesBackend.openWorkbench("", "updates")

    // At most the first six, then a count — the cap that keeps this a
    // glance surface. The unbounded list is the workbench's job, which is
    // exactly where the foot pill goes.
    readonly property int _cap: 6
    readonly property var _shown: root._updates.slice(0, root._cap)

    Column {
        width: parent.width
        spacing: Design.spacingXs

        Repeater {
            model: root._shown

            delegate: Row {
                id: line
                required property var modelData

                width: parent.width
                spacing: Design.spacingSm

                Text {
                    id: nameText
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(implicitWidth, line.width * 0.45)
                    text: line.modelData.name
                    font.pixelSize: Design.fontLabel
                    color: Colours.onSurface
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: line.modelData.source === "aur"
                    text: "AUR"
                    font.pixelSize: 10
                    color: Colours.tertiary
                    textFormat: Text.PlainText
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: line.width - nameText.width - Design.spacingSm * 2 - (line.modelData.source === "aur" ? 28 : 0)
                    horizontalAlignment: Text.AlignRight
                    // An unparsed line (from/to empty) shows nothing here
                    // rather than a bare arrow — the raw line is already
                    // the name.
                    text: line.modelData.from.length > 0 ? (line.modelData.from + " → " + line.modelData.to) : ""
                    font.pixelSize: Design.fontLabel
                    color: Colours.outline
                    elide: Text.ElideLeft
                    textFormat: Text.PlainText
                }
            }
        }

        Text {
            width: parent.width
            visible: root._updates.length > root._cap
            text: "and " + (root._updates.length - root._cap) + " more"
            font.pixelSize: Design.fontLabel
            color: Colours.outline
            textFormat: Text.PlainText
        }

        Item {
            width: 1
            height: Design.spacingXs
            visible: root._updates.length > 0
        }

        // The action, under the list of what it will do.
        Rectangle {
            visible: root._updates.length > 0
            width: parent.width
            height: 30
            radius: height / 2
            color: PackagesBackend.dbLocked ? "transparent" : (upgradeArea.containsMouse ? Qt.lighter(Colours.primary, 1.1) : Colours.primary)
            border.width: 1
            border.color: PackagesBackend.dbLocked ? Qt.alpha(Colours.outline, 0.4) : Colours.primary

            Behavior on color {
                enabled: Motion.motionEnabled
                ColorAnimation {
                    duration: Motion.colourDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.colourEasing
                }
            }

            Text {
                anchors.centerIn: parent
                text: PackagesBackend.dbLocked ? "pacman is already running" : "Update all"
                font.pixelSize: Design.fontLabel
                font.weight: Design.weightEmphasis
                color: PackagesBackend.dbLocked ? Qt.alpha(Colours.onSurfaceVariant, 0.55) : Colours.onPrimary
                textFormat: Text.PlainText
            }

            MouseArea {
                id: upgradeArea
                anchors.fill: parent
                hoverEnabled: true
                enabled: !PackagesBackend.dbLocked
                onClicked: root.upgrade()
            }
        }
    }
}

