// NotifCard.qml — the compact popup card body (Phase 19 Plan 01 tracer,
// QNOTIF-02, D-19-04/D-19-11/D-19-12).
//
// Fixed `Design.notifSurfaceWidth` (430px) wide, content-driven height —
// only the width is fixed, matching 19-UI-SPEC.md's "Card anatomy" table.
// Fill from `BarRoles.notifSurface`/`notifSurfaceFg` (or the
// `danger`/`onDanger` pair under critical urgency, D-19-11) — never a
// direct `Colours.*` reference or a hex literal (D-19-43, GATE-04).
//
// T-19-01 (LEDGER-08's mitigation, `15-SECURITY.md`'s T-15-08b class):
// both the summary and body `Text` elements pin `textFormat: Text.PlainText`
// explicitly. Both fields are sender-controlled and reach the shell from
// any process on the session bus — leaving Qt to auto-detect rich text is
// the exact untrusted-string class that control exists to close.
//
// D-19-04's dismiss timer — 5s normal, 3s low, critical never auto-
// dismisses — matches swaync's own windows exactly, so nothing about the
// daily rhythm changes on migration day. Gesture-driven dismiss (drag,
// middle-click, D-19-05/06/07) is explicitly out of this tracer's scope;
// this plan's Task 3 action text names only the timer.
import QtQuick
import Quickshell
import Quickshell.Services.Notifications
import "../"
import "../dashboard"
import "../bar"

Item {
    id: card

    // The wrapped NotifData instance (never the raw Notification) — set
    // by NotifPopupStack.qml's ListView delegate, mirroring this repo's
    // own `delegate: StreamRow { node: modelData }` idiom
    // (AudioPanel.qml:832).
    property var notifData: null

    readonly property string summary: card.notifData ? card.notifData.summary : ""
    readonly property string body: card.notifData ? card.notifData.body : ""
    readonly property string appIcon: card.notifData ? card.notifData.appIcon : ""
    readonly property string image: card.notifData ? card.notifData.image : ""
    readonly property int urgency: card.notifData ? card.notifData.urgency : NotificationUrgency.Normal
    readonly property int notifId: card.notifData ? card.notifData.notifId : -1

    readonly property bool _critical: card.urgency === NotificationUrgency.Critical
    readonly property bool _low: card.urgency === NotificationUrgency.Low

    readonly property color _fill: card._critical ? BarRoles.danger : BarRoles.notifSurface
    readonly property color _fg: card._critical ? BarRoles.onDanger : BarRoles.notifSurfaceFg

    width: Design.notifSurfaceWidth
    implicitHeight: Math.max(Design.notifImageSize, contentColumn.implicitHeight) + Design.spacingMd * 2
    height: card.implicitHeight

    Rectangle {
        id: background
        anchors.fill: parent
        radius: Design.popoutCornerRadius
        color: card._fill

        Behavior on color {
            enabled: Motion.motionEnabled
            ColorAnimation {
                duration: Motion.standardDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.standardEasing
            }
        }
    }

    GradientBorder {
        anchors.fill: parent
        borderWidth: Design.notifRingStrokeWidth
        topLeftRadius: Design.popoutCornerRadius
        topRightRadius: Design.popoutCornerRadius
        bottomLeftRadius: Design.popoutCornerRadius
        bottomRightRadius: Design.popoutCornerRadius
    }

    Item {
        id: contentArea
        anchors.fill: parent
        anchors.margins: Design.spacingMd

        // ── Icon slot — D-19-12's fallback chain, simplified for the
        //    tracer: image hint -> named app_icon via the icon theme ->
        //    generic Material Symbols bell glyph. The desktop-entry tier
        //    is left to a later plan (RESEARCH.md flags icon-resolution
        //    helper coverage as an open question for the bar's own tray;
        //    the same caveat applies here). Every tier renders inside the
        //    SAME notifImageSize slot, never a blank slot, never a
        //    card that changes width. ─────────────────────────────────
        Item {
            id: iconSlot
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            width: Design.notifImageSize
            height: Design.notifImageSize

            Image {
                id: notifImage
                anchors.fill: parent
                visible: card.image.length > 0
                source: card.image.length > 0 ? card.image : ""
                fillMode: Image.PreserveAspectFit
                asynchronous: true
            }
            Image {
                id: appIconImage
                anchors.fill: parent
                visible: !notifImage.visible && card.appIcon.length > 0
                source: card.appIcon.length > 0 ? Quickshell.iconPath(card.appIcon) : ""
                fillMode: Image.PreserveAspectFit
                asynchronous: true
            }
            Text {
                anchors.centerIn: parent
                visible: !notifImage.visible && !appIconImage.visible
                text: "notifications"
                font.family: Design.symbolFontFamily
                font.pixelSize: Design.iconSizeMd
                textFormat: Text.PlainText
                color: card._fg
            }
        }

        Column {
            id: contentColumn
            anchors.left: iconSlot.right
            anchors.leftMargin: Design.spacingMd
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: Design.spacingXs

            Text {
                id: summaryText
                width: parent.width
                text: card.summary
                // T-19-01 — pinned plain text, sender-controlled string.
                textFormat: Text.PlainText
                elide: Text.ElideRight
                maximumLineCount: 1
                font.pixelSize: Design.fontHeading
                font.weight: Design.weightEmphasis
                color: card._fg
            }
            Text {
                id: bodyText
                width: parent.width
                visible: card.body.length > 0
                text: card.body
                // T-19-01 — pinned plain text, sender-controlled string.
                textFormat: Text.PlainText
                elide: Text.ElideRight
                maximumLineCount: 1
                font.pixelSize: Design.fontBody
                color: card._fg
            }
        }
    }

    // ── D-19-04 dismiss timer — swaync-identical windows. Critical never
    //    starts a timer at all (never auto-dismisses); low urgency gets
    //    3s, everything else gets 5s. ────────────────────────────────────
    readonly property int _dismissMs: card._critical ? -1 : (card._low ? 3000 : 5000)

    Timer {
        id: dismissTimer
        interval: card._dismissMs > 0 ? card._dismissMs : 1
        running: card._dismissMs > 0
        repeat: false
        onTriggered: NotifServer.dismiss(card.notifId)
    }
}
