// modules/launcher/FontMode.qml — the `font` word route (quick task
// 260828-ah9, Task 4, D-01, M2). Specimen's font half: a plain
// (non-grid) ListView over `AppearanceBackend.fontFamilies`, filtered by
// family name — the same `PkgMode.qml` shape (a ListView, `currentIndex`/
// `count`/`activate()`, no `columns`) rather than a strip, since a font
// specimen line needs full width to read.
//
// M2 — MEASURED: 13 families x 2 spacing behaviours (Mono/Propo), never
// 39 rows and never a third "Nerd Font alone" cut — see
// `AppearanceBackend.fontFamilies`'s own header for the full measurement.
import QtQuick
import ".."
import "../dashboard"
import "../appearance"

Item {
    id: root

    property var dismissCallback: null

    readonly property string pattern: LauncherState.queryArg.trim().toLowerCase()

    readonly property var filtered: {
        const all = AppearanceBackend.fontFamilies;
        if (root.pattern.length === 0)
            return all;
        const out = [];
        for (let i = 0; i < all.length; ++i)
            if (all[i].family.toLowerCase().indexOf(root.pattern) >= 0)
                out.push(all[i]);
        return out;
    }

    width: parent ? parent.width : 0
    height: Math.min(360, Math.max(root.count, 1) * 64)

    property int currentIndex: 0
    readonly property int count: root.filtered.length

    onPatternChanged: root.currentIndex = 0

    function activate() {
        const entry = root.filtered[root.currentIndex];
        if (!entry)
            return;
        AppearanceBackend.applyFont(entry.rawName);
        if (root.dismissCallback)
            root.dismissCallback();
    }

    ListView {
        id: fontList
        anchors.fill: parent
        clip: true
        interactive: false
        model: root.filtered
        currentIndex: root.currentIndex

        delegate: Rectangle {
            id: row
            required property var modelData
            required property int index

            width: fontList.width
            height: 60
            radius: 10
            color: root.currentIndex === row.index ? Colours.surfaceVariant : "transparent"

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    root.currentIndex = row.index;
                    root.activate();
                }
            }

            Column {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: Design.spacingMd
                anchors.rightMargin: Design.spacingMd
                spacing: 2

                Row {
                    spacing: Design.spacingSm

                    Text {
                        text: row.modelData.family
                        color: row.modelData.active ? Colours.primary : Colours.onSurface
                        font.pixelSize: Design.settingsFontSub
                        textFormat: Text.PlainText
                    }

                    Text {
                        visible: row.modelData.behaviour.length > 0
                        text: row.modelData.behaviour === "mono" ? "Mono" : (row.modelData.behaviour === "propo" ? "Propo" : "")
                        font.pixelSize: 10
                        color: Colours.tertiary
                        textFormat: Text.PlainText
                    }
                }

                Text {
                    text: "The quick brown fox jumps over the lazy dog"
                    font.family: row.modelData.rawName
                    font.pixelSize: Design.fontBody
                    color: Colours.onSurfaceVariant
                    elide: Text.ElideRight
                    width: parent.width
                    textFormat: Text.PlainText
                }
            }
        }
    }
    // Scroll indicator (quick task 260828-pol). Sibling of the view,
    // never a child: a Flickable/ListView appends Item children to its
    // scrolled contentItem, so a bar declared inside scrolls away.
    ThemedScrollBar {
        flickable: fontList
    }

    Text {
        anchors.centerIn: parent
        visible: root.count === 0
        text: root.pattern.length === 0 ? "No nerd fonts found" : ("Nothing matches “" + root.pattern + "”")
        font.pixelSize: Design.settingsFontSub
        color: Colours.outline
        textFormat: Text.PlainText
    }
}
