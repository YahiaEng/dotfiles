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

    // ── Sort mode (quick task 260822-sht, Task 1 REWORK ROUND 3, operator
    //    tracer-gate feedback) — A→Z vs most-launched-first. Persisted via
    //    Prefs (`launcher.sortMode`); read once at construction, same as
    //    every other Prefs-backed toggle in this shell reads its default —
    //    Prefs is a shell-wide singleton loaded well before this
    //    LazyLoaded panel is ever constructed, so this is never a stale
    //    read. ────────────────────────────────────────────────────────────
    property string sortMode: Prefs.getValue("launcher.sortMode")
    readonly property string sortModeAlpha: "alpha"
    readonly property string sortModeFrecency: "frecency"

    function toggleSortMode() {
        const next = launcherWindow.sortMode === launcherWindow.sortModeFrecency ? launcherWindow.sortModeAlpha : launcherWindow.sortModeFrecency;
        launcherWindow.sortMode = next;
        Prefs.setValue("launcher.sortMode", next);
    }

    // Named function, not inlined into `filteredApps` below — Task 2's
    // vendored fuzzy matcher composes with this by calling it as ITS
    // tiebreaker, per this task's own plan text, rather than rewriting the
    // sort. In frecency mode, equal launch counts (including every
    // zero-count app on first run) fall through to the SAME A→Z comparison
    // alpha mode uses, so ties never come out in an unstable order.
    //
    // ── Hoisted-lookup fix (quick task 260822-sht, pre-Task-2 fix) ───────
    // `counts` is read ONCE per sort by the caller (`filteredApps` below)
    // and threaded through as a third argument, rather than this function
    // calling `Prefs.getValue("launcher.launchCounts")` itself on every
    // pairwise comparison — Array.sort's comparator runs O(n·log n) times
    // per keystroke in frecency mode (~1,500 calls for 200 apps), so a
    // per-comparison Prefs read was ~1,500 redundant map fetches per
    // keystroke for one unchanging map. Chosen over a cached/invalidated
    // property because Task 2's fuzzy matcher composes this function as
    // ITS tiebreaker inside its own single sort/filter pass — passing the
    // already-fetched map straight through composes naturally with that
    // call shape and needs no separate cache-invalidation contract. `counts`
    // is `undefined` in alpha mode (never read) and always defined in
    // frecency mode (`filteredApps` only fetches it when needed).
    function _compareApps(a, b, counts) {
        if (launcherWindow.sortMode === launcherWindow.sortModeFrecency) {
            const countA = counts[a.id] || 0;
            const countB = counts[b.id] || 0;
            if (countA !== countB)
                return countB - countA;
        }
        const nameA = (a.name || "").toLowerCase();
        const nameB = (b.name || "").toLowerCase();
        if (nameA < nameB)
            return -1;
        if (nameA > nameB)
            return 1;
        return 0;
    }

    // ── App enumeration + substring filter (Task 1's whole surface;
    //    Task 2 replaces this with the vendored fuzzy matcher) ──────────
    readonly property var filteredApps: {
        const q = LauncherState.query.trim().toLowerCase();
        const all = DesktopEntries.applications.values.filter(function (e) {
            return !e.noDisplay;
        });
        const matched = q === "" ? all : all.filter(function (e) {
            return (e.name || "").toLowerCase().indexOf(q) !== -1;
        });
        // Fetched once per sort, not once per comparison — see
        // `_compareApps`'s header note above.
        const counts = launcherWindow.sortMode === launcherWindow.sortModeFrecency ? Prefs.getValue("launcher.launchCounts") : undefined;
        return matched.slice().sort(function (a, b) {
            return launcherWindow._compareApps(a, b, counts);
        });
    }

    function launchCurrent() {
        const entry = launcherWindow.filteredApps[resultsList.currentIndex];
        if (entry) {
            entry.execute();
            launcherWindow._bumpLaunchCount(entry);
        }
        launcherWindow._beginDismiss();
    }

    // The verified counter key is `entry.id` (quickshell-core.qmltypes'
    // `DesktopEntry.id: QString`) — never `name` or a synthesised slug, so
    // the keyspace can't mix. `Prefs.setValue()` refuses every write until
    // its own load has settled (returns false, per its own contract) —
    // that's fine here: `entry.execute()` above already ran, so the launch
    // itself never depends on this succeeding, only the tally can drop.
    function _bumpLaunchCount(entry) {
        if (!entry.id || entry.id.length === 0)
            return;
        const counts = Prefs.getValue("launcher.launchCounts");
        const next = {};
        for (const k in counts)
            next[k] = counts[k];
        next[entry.id] = (next[entry.id] || 0) + 1;
        Prefs.setValue("launcher.launchCounts", next);
    }

    // ── Result-row icon resolution (quick task 260822-sht, Task 1 REWORK
    //    ROUND 2, defect 2) — the same chain NotifGroup.qml:121-158 proved
    //    for app_icon: `Quickshell.iconPath(name, "")` alone is unsafe
    //    because an unresolvable THEME NAME can still come back as a
    //    resolvable "missing icon" placeholder pixmap (NotifCard.qml:196-
    //    215's live diagnosis), which then renders as a broken-texture
    //    glyph rather than failing. `Quickshell.hasThemeIcon(name)` is the
    //    real existence check, but only for a bare theme name — a
    //    DesktopEntry's `icon` field can also be a path/URI (kitty's own
    //    real example), which `hasThemeIcon()` correctly reports false for
    //    since it isn't a theme lookup at all. `_looksLikeThemeName` is the
    //    same trust boundary NotifGroup.qml draws: only a bare name goes
    //    through `hasThemeIcon()`; a path/URI is trusted straight to
    //    `iconPath()`, with the Image element's own `status !== Image.Error`
    //    below as the runtime safety net.
    function _looksLikeThemeName(name) {
        return name.indexOf("/") === -1 && name.indexOf("://") === -1;
    }
    function resolveAppIconSource(iconName) {
        if (!iconName || iconName.length === 0)
            return "";
        if (!launcherWindow._looksLikeThemeName(iconName) || Quickshell.hasThemeIcon(iconName)) {
            const p = Quickshell.iconPath(iconName, "");
            if (p.length > 0)
                return p;
        }
        return "";
    }

    // ── Dismiss scrim (quick task 260822-sht, Task 1 REWORK ROUND 2,
    //    defect 1) ──────────────────────────────────────────────────────
    // Root cause, already documented twice in this repo — PowerMenu.qml:
    // 59-70 (2026-08-15) and Dashboard.qml:533-550 (quick task 260818-nwo):
    // once the surface spans the output, a click "outside the drawer"
    // still lands INSIDE this window, so HyprlandFocusGrab's `onCleared` —
    // which fires on a focus CHANGE, never a plain click — never sees it,
    // and the drawer stops dismissing. The launcher inherited this the
    // moment its surface went full-screen. Fix, mirrored from
    // Dashboard.qml:546-550 verbatim: an explicit full-surface MouseArea
    // closes it deterministically, independent of compositor focus-grab
    // semantics. The grab below is kept for the different case of focus
    // genuinely moving to another surface — both routes call the same
    // idempotent `_beginDismiss()`, so there is no double-fire hazard.
    //
    // Declared BEFORE `panel` below, so `panel` (and its search field,
    // result rows, and their own MouseAreas) stacks on top and keeps
    // receiving its own clicks — same declaration-order trick
    // Dashboard.qml uses. Transparent and unpainted: this is an input
    // target only. The launcher is deliberately scrim-less (D-08) and
    // that is unchanged — nothing here dims or tints anything.
    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
        onClicked: launcherWindow._beginDismiss()
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

            // ── Search row (quick task 260822-sht, Task 1 REWORK ROUND 3)
            //    ─ the field plus the sort toggle at its right edge, wrapped
            //    in one Item so the field's own width shrinks to make room
            //    rather than the button overlapping it. ────────────────────
            Item {
                id: searchRow
                width: parent.width
                height: Math.max(searchField.implicitHeight, sortToggle.height)

                TextField {
                    id: searchField
                    anchors.left: parent.left
                    anchors.right: sortToggle.left
                    anchors.rightMargin: Design.spacingSm
                    anchors.verticalCenter: parent.verticalCenter
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

                // ── Sort toggle — cycles alpha/frecency on click and
                //    re-sorts immediately (filteredApps above reads
                //    launcherWindow.sortMode inside its own binding
                //    evaluation, so it re-runs automatically). The glyph
                //    and ThemedToolTip both reflect the ACTIVE mode so it's
                //    discoverable without clicking. A plain MouseArea never
                //    takes keyboard focus in QML — only an explicit
                //    forceActiveFocus() call would — so this can never
                //    steal focus from searchField; this is a static fact
                //    about the type, not something interactively probed
                //    (no click-injection tool exists on this host). Sits
                //    inside `panel`, so — like searchField and every result
                //    row — it stacks above the full-surface dismiss scrim
                //    declared before `panel` and never triggers it.
                Item {
                    id: sortToggle
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: Design.iconSizeMd + Design.spacingSm * 2
                    height: Design.iconSizeMd + Design.spacingSm * 2

                    Text {
                        anchors.centerIn: parent
                        text: launcherWindow.sortMode === launcherWindow.sortModeFrecency ? "trending_up" : "sort_by_alpha"
                        font.family: Design.symbolFontFamily
                        font.pixelSize: Design.iconSizeMd
                        textFormat: Text.PlainText
                        color: sortToggleMouseArea.containsMouse ? Colours.onSurface : Colours.onSurfaceVariant

                        Behavior on color {
                            enabled: Motion.motionEnabled
                            ColorAnimation {
                                duration: Motion.standardDuration
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Motion.standardEasing
                            }
                        }
                    }

                    MouseArea {
                        id: sortToggleMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: launcherWindow.toggleSortMode()
                    }

                    ThemedToolTip {
                        visible: sortToggleMouseArea.containsMouse
                        text: launcherWindow.sortMode === launcherWindow.sortModeFrecency ? "Sort: Most used" : "Sort: A→Z"
                    }
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

                    // ── App icon (quick task 260822-sht, Task 1 REWORK
                    //    ROUND 2, defect 2) — sized from Design.iconSizeMd,
                    //    the same 24px token NotifGroup.qml's own row icon
                    //    slot settled on after its round-11 measured gate
                    //    (dashboard/Design.qml:539); no new token needed.
                    //    Two tiers only (no "picture" tier — a DesktopEntry
                    //    has just one `icon` field): the resolved icon, or
                    //    a generic glyph placeholder so a row with no
                    //    resolvable icon still renders cleanly and stays
                    //    aligned with rows that do have one.
                    Item {
                        id: iconSlot
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        width: Design.iconSizeMd
                        height: Design.iconSizeMd

                        readonly property string _iconSrc: launcherWindow.resolveAppIconSource(resultDelegate.modelData.icon || "")

                        Image {
                            id: iconImage
                            anchors.fill: parent
                            visible: iconSlot._iconSrc.length > 0 && status !== Image.Error
                            source: iconSlot._iconSrc
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: !iconImage.visible
                            text: "apps"
                            font.family: Design.symbolFontFamily
                            font.pixelSize: Design.iconSizeMd
                            textFormat: Text.PlainText
                            color: Colours.onSurfaceVariant
                        }
                    }

                    Column {
                        anchors.left: iconSlot.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: Design.spacingSm
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
