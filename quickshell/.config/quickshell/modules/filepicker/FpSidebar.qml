// modules/filepicker/FpSidebar.qml — the places rail.
//
// Ported from caelestia-dots/shell @ 1d0e5a5
// (components/filedialog/Sidebar.qml). Their rail is a hardcoded list of
// seven XDG names; this one asks `xdg-user-dir` for each so a machine that
// localises or relocates them (XDG_DOWNLOAD_DIR pointing somewhere other
// than ~/Downloads) still gets working entries instead of dead rows. A
// place whose directory does not exist is dropped rather than shown broken.
import QtQuick
import Quickshell
import Quickshell.Io
import ".."
import "../dashboard"

Rectangle {
    id: root

    required property var picker

    // Caelestia's Sizes.sidebarWidth.
    implicitWidth: 230
    color: Colours.surfaceVariant

    readonly property string home: Quickshell.env("HOME") || "/"

    // { name, glyph, path } — seeded with Home, which needs no lookup.
    property var places: [
        {
            name: "Home",
            glyph: "home",
            path: root.home
        }
    ]

    Component.onCompleted: resolver.running = true

    // One bounded `xdg-user-dir` call resolves every place at once. Falls
    // back to the conventional ~/<Name> path for any line that comes back
    // empty or equal to $HOME (which is what xdg-user-dir prints when a
    // directory is not configured).
    Process {
        id: resolver

        running: false
        command: ["sh", "-c", "for d in DESKTOP DOWNLOAD DOCUMENTS MUSIC PICTURES VIDEOS; do printf '%s\\n' \"$(xdg-user-dir $d 2>/dev/null)\"; done"]

        stdout: StdioCollector {
            id: resolverOut
        }

        onExited: (exitCode, exitStatus) => {
            const names = ["Desktop", "Downloads", "Documents", "Music", "Pictures", "Videos"];
            const glyphs = ["desktop_windows", "download", "description", "music_note", "image", "movie"];
            const lines = String(resolverOut.text || "").split("\n");
            const out = [
                {
                    name: "Home",
                    glyph: "home",
                    path: root.home
                }
            ];
            for (let i = 0; i < names.length; i++) {
                let p = (lines[i] || "").trim();
                if (p.length === 0 || p === root.home)
                    p = root.home + "/" + names[i];
                out.push({
                    name: names[i],
                    glyph: glyphs[i],
                    path: p
                });
            }
            root.places = out;
            existence.running = true;
        }
    }

    // Drop places whose directory is absent, so the rail never offers a row
    // that lands the user in an empty phantom folder.
    Process {
        id: existence

        running: false
        command: {
            let args = "";
            for (let i = 0; i < root.places.length; i++)
                args += "[ -d '" + String(root.places[i].path).replace(/'/g, "") + "' ] && echo 1 || echo 0; ";
            return ["sh", "-c", args];
        }

        stdout: StdioCollector {
            id: existenceOut
        }

        onExited: (exitCode, exitStatus) => {
            const flags = String(existenceOut.text || "").trim().split("\n");
            const kept = [];
            for (let i = 0; i < root.places.length; i++)
                if ((flags[i] || "0").trim() === "1")
                    kept.push(root.places[i]);
            if (kept.length > 0)
                root.places = kept;
        }
    }

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Design.spacingMd
        spacing: Design.spacingXs

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            bottomPadding: Design.spacingMd
            text: "Files"
            color: Colours.onSurface
            font.pixelSize: Design.settingsFontRow
            font.weight: Design.weightBold
        }

        Repeater {
            model: root.places

            delegate: Rectangle {
                id: place

                required property var modelData

                readonly property bool selected: root.picker.currentPath === place.modelData.path

                width: parent ? parent.width : 0
                height: placeRow.implicitHeight + Design.spacingMd * 2
                radius: height / 2
                color: place.selected ? Colours.primaryContainer : (placeHover.containsMouse ? Colours.surface : "transparent")

                Behavior on color {
                    enabled: Motion.motionEnabled
                    ColorAnimation {
                        duration: Motion.colourDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Motion.colourEasing
                    }
                }

                Row {
                    id: placeRow

                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: Design.spacingMd
                    spacing: Design.spacingSm

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: Design.symbolFontFamily
                        font.pixelSize: 20
                        color: place.selected ? Colours.onSurface : Colours.onSurfaceVariant
                        text: place.modelData.glyph
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: place.modelData.name
                        color: place.selected ? Colours.onSurface : Colours.onSurfaceVariant
                        font.pixelSize: Design.settingsFontSub
                    }
                }

                MouseArea {
                    id: placeHover

                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: root.picker.navigateTo(place.modelData.path)
                }
            }
        }
    }
}
