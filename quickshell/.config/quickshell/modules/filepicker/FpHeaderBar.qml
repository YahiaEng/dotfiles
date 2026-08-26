// modules/filepicker/FpHeaderBar.qml — up-button plus a clickable
// breadcrumb trail.
//
// Ported from caelestia-dots/shell @ 1d0e5a5
// (components/filedialog/HeaderBar.qml). Theirs holds the path as a
// `list<string>` of segment NAMES with "Home" as a magic first element,
// which means a path outside $HOME cannot be represented. This one keeps
// the absolute path as the single source of truth and derives the crumbs
// from it, so /etc or /mnt browse correctly; the $HOME prefix is collapsed
// to a home glyph for display only.
import QtQuick
import Quickshell
import ".."
import "../dashboard"

Rectangle {
    id: root

    required property var picker

    implicitHeight: inner.implicitHeight + Design.spacingMd * 2
    color: Colours.surfaceVariant

    readonly property string home: Quickshell.env("HOME") || "/"

    // [{ label, path, isHome }] — derived, never stored.
    readonly property var crumbs: {
        const p = String(root.picker.currentPath || "/");
        const out = [];
        let rest = p;
        let base = "";

        if (p === root.home || p.indexOf(root.home + "/") === 0) {
            out.push({
                label: "Home",
                path: root.home,
                isHome: true
            });
            base = root.home;
            rest = p.slice(root.home.length);
        } else {
            out.push({
                label: "/",
                path: "/",
                isHome: false
            });
            base = "";
        }

        const parts = rest.split("/").filter(s => s.length > 0);
        for (let i = 0; i < parts.length; i++) {
            base = base + "/" + parts[i];
            out.push({
                label: parts[i],
                path: base,
                isHome: false
            });
        }
        return out;
    }

    Row {
        id: inner

        anchors.fill: parent
        anchors.margins: Design.spacingMd
        spacing: Design.spacingSm

        Rectangle {
            id: upBtn

            readonly property bool enabled_: root.picker.currentPath !== "/"

            width: 34
            height: 34
            radius: 12
            anchors.verticalCenter: parent.verticalCenter
            color: upHover.containsMouse && upBtn.enabled_ ? Colours.surface : "transparent"

            Text {
                anchors.centerIn: parent
                font.family: Design.symbolFontFamily
                font.pixelSize: 20
                color: upBtn.enabled_ ? Colours.onSurface : Colours.outline
                text: "drive_folder_upload"
            }

            MouseArea {
                id: upHover

                anchors.fill: parent
                hoverEnabled: true
                enabled: upBtn.enabled_
                onClicked: root.picker.navigateUp()
            }
        }

        Rectangle {
            width: parent.width - upBtn.width - Design.spacingSm
            height: 34
            anchors.verticalCenter: parent.verticalCenter
            radius: 12
            color: Colours.surface
            clip: true

            Row {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Design.spacingXs
                spacing: 0

                Repeater {
                    model: root.crumbs

                    delegate: Row {
                        id: crumb

                        required property var modelData
                        required property int index

                        readonly property bool last: crumb.index === root.crumbs.length - 1

                        spacing: 0

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: crumb.index > 0
                            text: "/"
                            color: Colours.onSurfaceVariant
                            font.pixelSize: Design.settingsFontSub
                            font.weight: Design.weightBold
                            rightPadding: Design.spacingSm
                            leftPadding: Design.spacingSm
                        }

                        Rectangle {
                            anchors.verticalCenter: parent.verticalCenter
                            width: crumbLabel.implicitWidth + Design.spacingMd * 2
                            height: 28
                            radius: 12
                            color: !crumb.last && crumbHover.containsMouse ? Colours.surfaceVariant : "transparent"

                            Row {
                                id: crumbLabel

                                anchors.centerIn: parent
                                spacing: Design.spacingXs

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    visible: crumb.modelData.isHome
                                    font.family: Design.symbolFontFamily
                                    font.pixelSize: 17
                                    color: crumb.last ? Colours.onSurface : Colours.onSurfaceVariant
                                    text: "home"
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: crumb.modelData.label
                                    color: crumb.last ? Colours.onSurface : Colours.onSurfaceVariant
                                    font.pixelSize: Design.settingsFontSub
                                    font.weight: Design.weightBold
                                }
                            }

                            MouseArea {
                                id: crumbHover

                                anchors.fill: parent
                                hoverEnabled: true
                                enabled: !crumb.last
                                onClicked: root.picker.navigateTo(crumb.modelData.path)
                            }
                        }
                    }
                }
            }
        }
    }
}
