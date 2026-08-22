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
// ── Layer posture: FULL-SCREEN surface, panel positioned in QML (quick
//    task 260822-sht, Task 1 REWORK) ─────────────────────────────────────
// The tracer shipped `anchors.top: true` alone plus an `implicitWidth`/
// `implicitHeight` pair — exactly the configuration Dashboard.qml's own
// header documents (see that file's "Layer posture" note) as the root
// cause of the drawer jitter it took three revisions to find: a
// top-anchored-only layer surface is compositor-centred, so ANY width
// change drags the whole surface sideways, and an animating/resizing layer
// surface is re-configured, re-buffered and re-rendered every frame. The
// tracer never resized in Task 1, so the jitter never surfaced live, but
// it was the same latent defect — this rework applies Dashboard's already-
// settled fix pre-emptively rather than waiting to rediscover it the same
// three-revision way.
//
// The fix, mirrored verbatim from Dashboard.qml: all four anchors true, no
// `implicitWidth`/`implicitHeight` at all — the surface spans the output
// and NEVER changes size for its whole lifetime — and every motion (the
// drop-down entrance) happens inside QML, on `panel`, where it is a
// scene-graph transform rather than a Wayland reconfigure.
//
// Focus/dismiss mechanics are copied from Overview.qml's
// HyprlandFocusGrab + WlrKeyboardFocus.OnDemand + Component.onCompleted
// forceActiveFocus() idiom (Overview.qml:54,:1031-1035,:1090) — this
// task's own plan text names those exact lines. The one deliberate
// adaptation: Overview grounds focus on a plain content `Item` because it
// has no text-entry surface; this window's actual interactive target is
// `searchField`, so `forceActiveFocus()` is called on the field itself
// rather than a wrapper Item, which is the literal equivalent for a
// surface whose whole point is receiving typed characters.
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import ".."
import "."
import "../dashboard"

PanelWindow {
    id: launcherWindow

    // shell.qml's launcherLoader listens for this to deactivate itself,
    // which destroys the wl_surface (D-14's zero-idle doctrine) rather
    // than merely hiding it — same contract as Dashboard.qml/Overview.qml.
    signal dismissRequested()

    // ── Animated dismiss (quick task 260822-sht, Task 1 REWORK) ─────────
    // Mirrors Dashboard.qml's own `_dismissing`/`_beginDismiss` shape: the
    // real `dismissRequested()` (which shell.qml's loader answers by
    // destroying the surface) is deferred until the panel's own out
    // animation has actually played, so Escape/Enter/click-outside never
    // cut the drop-down off mid-flight.
    property bool _dismissing: false
    function _beginDismiss() {
        if (launcherWindow._dismissing)
            return;
        launcherWindow._dismissing = true;
        panel.opened = false;
        exitTimer.start();
    }
    Timer {
        id: exitTimer
        interval: Motion.motionEnabled ? Motion.emphasizedOutDuration : 0
        repeat: false
        onTriggered: launcherWindow.dismissRequested()
    }

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    // Same value and same rationale as Dashboard.qml's own
    // `drawerTopMargin`: lands the panel's top edge where a real tiled
    // Hyprland window starts (`hyprland.lua`'s `general.gaps_out: 10`),
    // not flush against the bar.
    readonly property int drawerTopMargin: 10
    margins.top: launcherWindow.drawerTopMargin

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
    // Mirrors Dashboard.qml's own `drawerSurfaceOpacity` (D-21-26, frost
    // unification) so the two summonable surfaces read as siblings at the
    // same frost strength — see windowrules.lua's per-surface
    // `ignore_alpha` override for `quickshell-launcher`, which this value
    // must stay above (0.38 > 0.2) or blur dies silently on this panel.
    readonly property real drawerSurfaceOpacity: 0.38

    // Radii shared between `background` and `GradientBorder` below so the
    // rim and the surface can never disagree about the drawer's shape —
    // same discipline as Dashboard.qml's own `cornerRadius`.
    readonly property int cornerRadius: 28

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
        launcherWindow._beginDismiss();
    }

    // ── The drawer rectangle itself (quick task 260822-sht, Task 1
    //    REWORK) ──────────────────────────────────────────────────────
    // Everything that used to fill the window now fills THIS, which is
    // the only thing sized to the launcher's content. Centred in QML
    // rather than by the compositor, so position and size always update
    // in the same frame — the property the compositor could not give us
    // (see the layer-posture note above). Mirrors Dashboard.qml:557-601.
    Item {
        id: panel
        width: 640
        height: contentColumn.implicitHeight + contentColumn.anchors.margins * 2
        anchors.horizontalCenter: parent.horizontalCenter

        // ── Drop-down entrance, in QML ───────────────────────────────
        // The LazyLoader creates this surface fresh on every summon
        // (D-14), so `Component.onCompleted` IS the open event; there is
        // no reopen case to reset.
        property bool opened: false
        y: opened ? 0 : -height
        opacity: opened ? 1 : 0
        Component.onCompleted: panel.opened = true

        // `y` is a spatial (position) property — the panel's own
        // entry/dismiss slide — so it rides the spatial-in/spatial-out
        // pair, matching Dashboard.qml's own `panel.y` Behavior.
        Behavior on y {
            enabled: Motion.motionEnabled
            NumberAnimation {
                duration: launcherWindow._dismissing ? Motion.spatialOutDuration : Motion.spatialInDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: launcherWindow._dismissing ? Motion.spatialOutEasing : Motion.spatialInEasing
            }
        }
        Behavior on opacity {
            enabled: Motion.motionEnabled
            NumberAnimation {
                duration: launcherWindow._dismissing ? Motion.emphasizedOutDuration : Motion.emphasizedInDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: launcherWindow._dismissing ? Motion.emphasizedOutEasing : Motion.emphasizedInEasing
            }
        }

        Rectangle {
            id: background
            anchors.fill: parent
            topLeftRadius: 0
            topRightRadius: 0
            bottomLeftRadius: launcherWindow.cornerRadius
            bottomRightRadius: launcherWindow.cornerRadius
            color: Qt.rgba(launcherWindow.surfaceBase.r, launcherWindow.surfaceBase.g, launcherWindow.surfaceBase.b, launcherWindow.drawerSurfaceOpacity)
        }

        // DASH-10's animated gradient rim, reused verbatim — matches
        // Hyprland's own window border so the drawer reads as part of the
        // same desktop rather than as a foreign panel. Radii are handed
        // across from the same properties `background` uses, mirroring
        // Dashboard.qml:672-680.
        GradientBorder {
            anchors.fill: parent
            borderWidth: Design.borderWidth
            topLeftRadius: 0
            topRightRadius: 0
            bottomLeftRadius: launcherWindow.cornerRadius
            bottomRightRadius: launcherWindow.cornerRadius
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
                    launcherWindow._beginDismiss();
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
    }

    // ── Click-outside dismiss — Overview.qml's proven grab shape,
    //    reused verbatim (this task's own plan text names this line). ────
    HyprlandFocusGrab {
        id: grab
        windows: [launcherWindow]
        active: true
        onCleared: launcherWindow._beginDismiss()
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
