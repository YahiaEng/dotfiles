// modules/appearance/AtUninstallConfirm.qml — the Atelier's uninstall
// confirmation overlay (operator round 1, defect 1). Mounted ONCE in
// Atelier.qml, visible whenever `AppearanceBackend.uninstallPlan` is
// non-null, regardless of which tab is active — one confirmation surface
// for both the Icons tab's "Uninstall" action and the Fonts tab's own,
// rather than duplicating this panel per tab.
//
// PRIVILEGE: NONE HERE. This file only ever reads
// `AppearanceBackend.uninstallPlan` and calls `confirmUninstall()` /
// `cancelUninstall()` — every resolution step (the system-dir/user-dir
// check, `pacman -Qoq`, the terminal handoff) lives on the backend. It
// NEVER auto-picks a package when more than one owns the target — the
// Adwaita case (`adwaita-cursors` AND `adwaita-icon-theme`) is rendered
// as a full list, every time.
import QtQuick
import ".."
import "../dashboard"
import "../packages"

Item {
    id: root

    readonly property var plan: AppearanceBackend.uninstallPlan
    visible: root.plan !== null
    anchors.fill: parent

    // Swallow clicks so they never reach the tab content BEHIND this
    // overlay (a rail row, an Apply chip) — the Cancel/Uninstall buttons
    // below are the only click targets while a plan is showing. Escape
    // is handled by Atelier.qml's own `focusCatcher`, which checks
    // `AppearanceBackend.uninstallPlan` first so it cancels THIS overlay
    // rather than closing the whole window underneath it.
    MouseArea {
        anchors.fill: parent
        onClicked: {}
    }

    Rectangle {
        anchors.fill: parent
        color: Qt.alpha(Colours.background, 0.55)
    }

    Rectangle {
        id: card
        anchors.centerIn: parent
        width: Math.min(460, root.width - Design.spacingXl * 2)
        radius: 14
        color: Colours.surfaceVariant
        border.width: 1
        border.color: Qt.alpha(Colours.outline, 0.4)
        height: cardColumn.implicitHeight + Design.spacingLg * 2

        Column {
            id: cardColumn
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.margins: Design.spacingLg
            spacing: Design.spacingMd

            Text {
                width: parent.width
                text: root.plan ? ("Uninstall " + (root.plan.forFonts ? "font" : "icon theme") + " — " + root.plan.target) : ""
                font.pixelSize: Design.fontHeading
                font.bold: true
                color: Colours.onSurface
                wrapMode: Text.WordWrap
                textFormat: Text.PlainText
            }

            // ── Resolving ──────────────────────────────────────────────
            Text {
                width: parent.width
                visible: root.plan && root.plan.kind === "resolving"
                text: "Resolving what owns this…"
                color: Colours.onSurfaceVariant
                font.pixelSize: Design.fontBody
                textFormat: Text.PlainText
            }

            // ── Package-owned — EVERY affected package is listed, never
            //    auto-picked (the Adwaita two-package case). ─────────────
            Column {
                width: parent.width
                visible: root.plan && root.plan.kind === "packages"
                spacing: Design.spacingSm

                Text {
                    width: parent.width
                    text: root.plan && root.plan.packages && root.plan.packages.length > 1 ? ("This removes " + root.plan.packages.length + " packages:") : "This removes one package:"
                    color: Colours.onSurfaceVariant
                    font.pixelSize: Design.fontBody
                    wrapMode: Text.WordWrap
                    textFormat: Text.PlainText
                }

                Repeater {
                    model: root.plan && root.plan.packages ? root.plan.packages : []

                    delegate: Text {
                        required property string modelData
                        width: parent.width
                        text: "• " + modelData
                        color: Colours.onSurface
                        font.pixelSize: Design.fontBody
                        textFormat: Text.PlainText
                    }
                }
            }

            // ── Unowned — a real user-dir file/directory, deleted
            //    directly rather than through a package manager. ────────
            Text {
                width: parent.width
                visible: root.plan && root.plan.kind === "userdir"
                text: "This is not a package — it is a user-directory copy that will be deleted directly:\n" + (root.plan ? root.plan.path : "")
                color: Colours.onSurfaceVariant
                font.pixelSize: Design.fontBody
                wrapMode: Text.WordWrap
                textFormat: Text.PlainText
            }

            // ── Missing / error ────────────────────────────────────────
            Text {
                width: parent.width
                visible: root.plan && root.plan.kind === "missing"
                text: "That " + (root.plan && root.plan.forFonts ? "font" : "theme") + " could not be found any more — nothing to remove."
                color: Colours.onSurfaceVariant
                font.pixelSize: Design.fontBody
                wrapMode: Text.WordWrap
                textFormat: Text.PlainText
            }

            Text {
                width: parent.width
                visible: root.plan && root.plan.kind === "error"
                text: root.plan ? root.plan.message : ""
                color: Colours.error
                font.pixelSize: Design.fontBody
                wrapMode: Text.WordWrap
                textFormat: Text.PlainText
            }

            // Never delete the active theme/font without saying so.
            Text {
                width: parent.width
                visible: root.plan && root.plan.active === true
                text: "This is the ACTIVE " + (root.plan && root.plan.forFonts ? "font" : "icon theme") + " — the desktop falls back once it is gone."
                color: Colours.tertiary
                font.pixelSize: Design.fontLabel
                wrapMode: Text.WordWrap
                textFormat: Text.PlainText
            }

            // Operator round 3, item 1 — `WbButton`, not a hand-rolled
            // pair of Rectangles: same two-button language as everywhere
            // else in the Atelier now.
            Row {
                width: parent.width
                spacing: Design.spacingSm
                layoutDirection: Qt.RightToLeft

                WbButton {
                    id: primaryButton
                    readonly property bool _actionable: root.plan && (root.plan.kind === "packages" || root.plan.kind === "userdir")
                    label: primaryButton._actionable ? "Uninstall" : "OK"
                    tone: primaryButton._actionable ? "danger" : "ghost"
                    onActivated: primaryButton._actionable ? AppearanceBackend.confirmUninstall() : AppearanceBackend.cancelUninstall()
                }

                WbButton {
                    id: cancelButton
                    visible: primaryButton._actionable
                    label: "Cancel"
                    tone: "ghost"
                    onActivated: AppearanceBackend.cancelUninstall()
                }
            }
        }
    }
}
