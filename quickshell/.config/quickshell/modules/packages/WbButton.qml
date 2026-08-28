// modules/packages/WbButton.qml — the workbench's one button shape.
//
// Declared as a real component rather than repeated inline so the three
// tones stay consistent and a disabled button explains itself the same
// way everywhere. Border WIDTH is constant and only the colour changes,
// so hovering or disabling never reflows the row it sits in — the same
// geometry-stability discipline UpdatesPage.qml's PackageCell records.
//
// Operator round 4, item 1 — WHY THIS RECURS: rounds 1-3 kept "fixing"
// the button class by moving hand-rolled chips INTO this component, but
// the DESTINATION was just as loud — `tone: "primary"` painted a SOLID
// `Colours.primary` fill at rest and `tone: "danger"` painted a full-
// strength `Colours.error` border AND label at rest. The label is what
// draws the eye, so every tone now keeps the label at `Colours.onSurface`
// at rest (never itself painted the accent) and puts accent ONLY in the
// border/fill, which stays a light tint at rest and only deepens on
// hover/`active` — no tone shouts just by existing on the screen.
import QtQuick
import ".."
import "../dashboard"

Rectangle {
    id: root

    property string label: ""
    // "primary" — the affirmative action. "danger" — removal. "ghost" —
    // everything else.
    property string tone: "ghost"
    property bool enabled: true
    // Toggled/on-state: renders like hover-at-rest (the deepened accent),
    // WITHOUT requiring the mouse to actually be over the button — so a
    // real toggle (Icons tab's Compare, a variant chip's "currently
    // applied" state) reads as toggled even when the pointer has moved
    // away. Round 3 recorded this state's absence as a limitation.
    property bool active: false

    signal activated

    readonly property bool _live: root.enabled
    readonly property bool _hovered: area.containsMouse || root.active

    implicitWidth: labelText.implicitWidth + Design.spacingMd * 2
    implicitHeight: 30
    width: implicitWidth
    height: implicitHeight
    radius: height / 2

    color: {
        if (!root._live)
            return "transparent";
        if (root.tone === "primary")
            return root._hovered ? Qt.alpha(Colours.primary, 0.28) : Qt.alpha(Colours.primary, 0.16);
        if (root.tone === "danger")
            return root._hovered ? Qt.alpha(Colours.error, 0.18) : "transparent";
        return root._hovered ? Qt.alpha(Colours.onSurface, 0.09) : "transparent";
    }

    border.width: 1
    border.color: {
        if (!root._live)
            return Qt.alpha(Colours.outline, 0.4);
        if (root.tone === "primary")
            return Colours.primary;
        if (root.tone === "danger")
            return root._hovered ? Colours.error : Qt.alpha(Colours.error, 0.5);
        return Colours.outline;
    }

    Behavior on color {
        enabled: Motion.motionEnabled
        ColorAnimation {
            duration: Motion.colourDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Motion.colourEasing
        }
    }

    Behavior on border.color {
        enabled: Motion.motionEnabled
        ColorAnimation {
            duration: Motion.colourDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Motion.colourEasing
        }
    }

    Text {
        id: labelText
        anchors.centerIn: parent
        text: root.label
        font.pixelSize: Design.fontLabel
        font.weight: root.tone === "primary" ? Design.weightEmphasis : Design.weightBody
        color: {
            if (!root._live)
                return Qt.alpha(Colours.onSurfaceVariant, 0.55);
            // Every tone keeps the LABEL at onSurface at rest — accent
            // never shouts just by existing. Danger is the one tone that
            // deliberately amplifies to the full accent on hover/active,
            // matching its border/fill so an irreversible action reads
            // unambiguously once the pointer is actually over it.
            if (root.tone === "danger" && root._hovered)
                return Colours.error;
            return Colours.onSurface;
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        enabled: root._live
        onClicked: root.activated()
    }
}
