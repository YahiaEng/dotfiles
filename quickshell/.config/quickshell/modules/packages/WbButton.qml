// modules/packages/WbButton.qml — the workbench's one button shape.
//
// Declared as a real component rather than repeated inline so the three
// tones stay consistent and a disabled button explains itself the same
// way everywhere. Border WIDTH is constant and only the colour changes,
// so hovering or disabling never reflows the row it sits in — the same
// geometry-stability discipline UpdatesPage.qml's PackageCell records.
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

    signal activated

    readonly property bool _live: root.enabled

    implicitWidth: labelText.implicitWidth + Design.spacingMd * 2
    implicitHeight: 30
    width: implicitWidth
    height: implicitHeight
    radius: height / 2

    color: {
        if (!root._live)
            return "transparent";
        if (root.tone === "primary")
            return area.containsMouse ? Qt.lighter(Colours.primary, 1.1) : Colours.primary;
        if (root.tone === "danger")
            return area.containsMouse ? Qt.alpha(Colours.error, 0.18) : "transparent";
        return area.containsMouse ? Qt.alpha(Colours.onSurface, 0.09) : "transparent";
    }

    border.width: 1
    border.color: {
        if (!root._live)
            return Qt.alpha(Colours.outline, 0.4);
        if (root.tone === "primary")
            return Colours.primary;
        if (root.tone === "danger")
            return Colours.error;
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
            if (root.tone === "primary")
                return Colours.onPrimary;
            if (root.tone === "danger")
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
