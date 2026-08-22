// Launcher.qml — the launcher surface tracer (quick task 260822-sht, Task
// 1). One end-to-end path only: Super+Space -> this PanelWindow -> a
// substring-filtered list of installed applications -> Enter launches the
// highlighted one. Task 2 replaces the substring filter with a vendored
// fuzzy matcher and adds the six prefix-routed modes; Task 3 adds the menu
// tree. Both graft onto LauncherState/this file without restructuring it.
//
// Shape is D-1 (Option B, `.planning/notes/launcher-qml-migration-design.md`):
// its own dedicated PanelWindow + LazyLoader, end-4's shape, NOT
// Caelestia's shared window — the one place the house Caelestia-first bias
// points the wrong way here (measured_ground_truth, plan header).
//
// Layer posture/geometry follow Dashboard.qml's own proven centred-drawer
// shape (anchors.top only, exclusiveZone 0, `quickshell-<surface>`
// namespace — the `^quickshell-.*` family layer-rule pair in
// windowrules.lua already covers blur/ignore_alpha for `quickshell-launcher`
// with zero new Hyprland config, D-42). Focus/dismiss mechanics are copied
// from Overview.qml's HyprlandFocusGrab + WlrKeyboardFocus.OnDemand +
// Component.onCompleted forceActiveFocus() idiom (Overview.qml:54,:1031-1035,
// :1090) — this task's own plan text names those exact lines. The one
// deliberate adaptation: Overview grounds focus on a plain content `Item`
// because it has no text-entry surface; this window's actual interactive
// target is `searchField`, so `forceActiveFocus()` is called on the field
// itself rather than a wrapper Item, which is the literal equivalent for a
// surface whose whole point is receiving typed characters.
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import ".."
import "."

PanelWindow {
    id: launcherWindow

    // shell.qml's launcherLoader listens for this to deactivate itself,
    // which destroys the wl_surface (D-14's zero-idle doctrine) rather
    // than merely hiding it — same contract as Dashboard.qml/Overview.qml.
    signal dismissRequested()

    anchors.top: true

    implicitWidth: 640
    implicitHeight: contentColumn.implicitHeight + contentColumn.anchors.margins * 2

    // Reserve nothing — the launcher never displaces the bar's own
    // reservation, matching Dashboard.qml's own exclusiveZone/exclusionMode
    // pair verbatim.
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Normal

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-launcher"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    // Only the background Rectangle below paints — the window itself stays
    // transparent, matching Dashboard.qml's own rounded-corner technique.
    color: "transparent"

    readonly property color surfaceBase: Colours.surface
    readonly property real surfaceOpacity: 0.94

    // ── App enumeration + substring filter (Task 1's whole surface;
    //    Task 2 replaces this with the vendored fuzzy matcher) ──────────
    readonly property var filteredApps: {
        const q = LauncherState.query.trim().toLowerCase();
        const all = DesktopEntries.applications.values.filter(function (e) {
            return !e.noDisplay;
        });
        if (q === "")
            return all;
        return all.filter(function (e) {
            return (e.name || "").toLowerCase().indexOf(q) !== -1;
        });
    }

    function launchCurrent() {
        const entry = launcherWindow.filteredApps[resultsList.currentIndex];
        if (entry)
            entry.execute();
        launcherWindow.dismissRequested();
    }

    Rectangle {
        id: background
        anchors.fill: parent
        radius: 16
        color: Qt.rgba(launcherWindow.surfaceBase.r, launcherWindow.surfaceBase.g, launcherWindow.surfaceBase.b, launcherWindow.surfaceOpacity)
        border.width: 1
        border.color: Colours.outline
    }

    Column {
        id: contentColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 16
        spacing: 12

        TextField {
            id: searchField
            width: parent.width
            placeholderText: "Search apps…"
            color: Colours.onSurface
            font.pixelSize: 18
            selectByMouse: true
            background: Rectangle {
                radius: 10
                color: Colours.surfaceVariant
                border.width: 1
                border.color: Colours.outline
            }

            // Two-way with LauncherState.query so a future mode can seed
            // or read the same buffer (Task 2's prefix router reads this
            // field to pick a mode).
            text: LauncherState.query
            onTextChanged: {
                if (LauncherState.query !== searchField.text)
                    LauncherState.query = searchField.text;
                resultsList.currentIndex = 0;
            }

            Keys.onEscapePressed: function (event) {
                launcherWindow.dismissRequested();
                event.accepted = true;
            }
            Keys.onReturnPressed: function (event) {
                launcherWindow.launchCurrent();
                event.accepted = true;
            }
            Keys.onEnterPressed: function (event) {
                launcherWindow.launchCurrent();
                event.accepted = true;
            }
            Keys.onDownPressed: function (event) {
                resultsList.currentIndex = Math.min(resultsList.currentIndex + 1, resultsList.count - 1);
                event.accepted = true;
            }
            Keys.onUpPressed: function (event) {
                resultsList.currentIndex = Math.max(resultsList.currentIndex - 1, 0);
                event.accepted = true;
            }
        }

        ListView {
            id: resultsList
            width: parent.width
            height: Math.min(360, count * 48)
            clip: true
            model: launcherWindow.filteredApps
            currentIndex: 0

            delegate: Rectangle {
                id: resultDelegate
                required property var modelData
                required property int index

                width: resultsList.width
                height: 48
                radius: 8
                color: resultsList.currentIndex === resultDelegate.index ? Colours.surfaceVariant : "transparent"

                Column {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 12
                    spacing: 0

                    Text {
                        text: resultDelegate.modelData.name || ""
                        color: Colours.onSurface
                        font.pixelSize: 15
                    }
                    Text {
                        visible: (resultDelegate.modelData.comment || "") !== ""
                        text: resultDelegate.modelData.comment || ""
                        color: Colours.onSurfaceVariant
                        font.pixelSize: 11
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        resultsList.currentIndex = resultDelegate.index;
                        launcherWindow.launchCurrent();
                    }
                }
            }
        }
    }

    // ── Click-outside dismiss — Overview.qml's proven grab shape,
    //    reused verbatim (this task's own plan text names this line). ────
    HyprlandFocusGrab {
        id: grab
        windows: [launcherWindow]
        active: true
        onCleared: launcherWindow.dismissRequested()
    }

    // forceActiveFocus() is required for the field above to actually
    // receive typed input under WlrKeyboardFocus.OnDemand — Overview.qml's
    // own content Item ships the identical mechanism one level up; here
    // the field itself is the equivalent target (see header note).
    Component.onCompleted: {
        LauncherState.reset();
        searchField.forceActiveFocus();
    }
}
