// modules/packages/Workbench.qml — the package workbench (quick task
// 260828-75k, direction D4). Its own window, the way FilePicker is its
// own window.
//
// ── WHY A TOPLEVEL AND NOT A SETTINGS PAGE ────────────────────────────
// The operator's stated goal is a replacement for Octopi, which was
// installed on this host at 03:50 on 2026-08-28 and is what prompted the
// task. A Settings page is not that: it is somewhere you visit and
// leave. This is somewhere you leave open while you work, with bulk
// selection and a removal preview — the two capabilities a settings page
// genuinely cannot fake, and the reason the study's own recommendation
// (D1 as a browser) was overruled.
//
// Settings → Packages exists too, but it is deliberately THIN: prefs and
// one button that opens this window. Two full browsers over one backend
// is the redundancy that got the Security Center's two layouts merged in
// its operator round 3, and this task is not repeating it.
//
// ── LIFECYCLE ─────────────────────────────────────────────────────────
// LazyLoader, not a bare FloatingWindow — FilePicker's own pattern: the
// window is constructed on first open, so declaring it in shell.qml
// costs nothing until something calls open(). The BACKEND is a singleton
// and lives outside this loader on purpose, so closing the window does
// not discard the 1420-record model or abandon a preview in flight.
//
// ── NOTHING HERE RUNS A TRANSACTION ───────────────────────────────────
// Every write goes through PackagesBackend's terminal handoff, which
// opens the configured terminal on a real `paru` command so pacman
// prints what it will do and asks. This file constructs no command and
// escalates no privilege; see the backend's header for why that is the
// design rather than a limitation.
import QtQuick
import Quickshell
import Quickshell.Hyprland
import ".."
import "../dashboard"

LazyLoader {
    id: loader

    // Opening on a named package is how the launcher's `pkg` route and
    // the bar popout hand off — "show me this one" rather than "show me
    // everything and good luck".
    property string pendingFocus: ""
    property string pendingFilter: ""

    function open(): void {
        loader.activeAsync = true;
    }

    function openOn(name: string): void {
        loader.pendingFocus = name || "";
        loader.activeAsync = true;
    }

    // Opens straight onto one source (the launcher's System > Updates leaf
    // uses "updates"). Applied on an ALREADY-OPEN window too, so a second
    // request re-aims it rather than doing nothing.
    function openFilter(filterName: string): void {
        loader.pendingFilter = filterName || "";
        loader.activeAsync = true;
        if (loader.item && filterName)
            loader.item.setFilter(filterName);
    }

    function close(): void {
        loader.activeAsync = false;
    }

    FloatingWindow {
        id: win

        // ── View state. Declared before anything that reads it at
        //    construction time (this tree's declare-before-use rule —
        //    a later-declared member reads undefined with no error).
        property string filter: "all"
        property string query: ""
        property string sortKey: "size"
        property bool sortDesc: true
        property string focusName: loader.pendingFocus

        readonly property var backend: PackagesBackend

        // Persisted, so a rail you widened stays widened (operator round
        // 2). Clamped on READ as well as on write: a value from an older
        // or hand-edited config cannot wedge the rail off-screen.
        property int sidebarWidth: Math.max(150, Math.min(460, Prefs.getValue("packages.sidebarWidth")))

        function setSidebarWidth(w) {
            var clamped = Math.max(150, Math.min(460, Math.round(w)));
            if (clamped === win.sidebarWidth)
                return;
            win.sidebarWidth = clamped;
            Prefs.setValue("packages.sidebarWidth", clamped);
        }

        property int detailWidth: Math.max(240, Math.min(620, Prefs.getValue("packages.detailWidth")))

        function setDetailWidth(w) {
            var clamped = Math.max(240, Math.min(620, Math.round(w)));
            if (clamped === win.detailWidth)
                return;
            win.detailWidth = clamped;
            Prefs.setValue("packages.detailWidth", clamped);
        }

        // Lives on the BACKEND, not here: dismiss-on-click-outside makes
        // losing this window easy, and a half-built removal queue is real
        // work. The backend is a singleton, so it survives.
        readonly property var selected: PackagesBackend.queue

        title: "Packages"

        // Frost, matching Settings.qml's own recorded shape: `color:
        // "transparent"` on the toplevel and the alpha on an interior
        // Rectangle. `surfaceBase` is declared as a `property color`
        // rather than read straight off Colours — a Colours role is a
        // STRING, so `Colours.surfaceVariant.r` is undefined and
        // Qt.rgba() of it renders pure black. Assigning through a
        // color-typed property is what coerces it. `Design.
        // panelSurfaceOpacity` does not exist (PowerMenu.qml's recorded
        // finding); the weight is declared locally, as all five
        // precedents in this tree do.
        readonly property color surfaceBase: Colours.surfaceVariant
        readonly property real panelSurfaceOpacity: 0.78
        color: "transparent"

        // ── Size (operator round 1: "scaled too small") ─────────────
        // 1100x640 was a literal and read tiny on a 2560x1440 screen.
        // This is Settings.qml's own formula verbatim — 70% of the screen
        // height at 16:9, floored at a size the three columns still fit —
        // so the two windows in this shell that browse a long list are
        // the same size as each other on any monitor. Measured: Settings
        // renders 1792x1008 here, and so does this now.
        readonly property int _screenHeight: (win.screen && win.screen.height > 0) ? win.screen.height : 1080
        readonly property real _heightMult: 0.7
        readonly property real _aspectRatio: 16 / 9

        implicitHeight: Math.max(560, Math.round(win._screenHeight * win._heightMult))
        implicitWidth: Math.max(900, Math.round(win.implicitHeight * win._aspectRatio))
        minimumSize.width: 900
        minimumSize.height: 560

        onVisibleChanged: {
            if (!visible)
                loader.activeAsync = false;
        }

        // ── Selection ───────────────────────────────────────────────
        function isSelected(name) {
            return win.selected.indexOf(name) >= 0;
        }

        // All three delegate to the backend, which owns the queue and
        // re-previews on every change — the cascade for {a} and for {a,b}
        // are different questions, and a preview left over from the
        // previous selection is worse than none.
        function toggleSelected(name) {
            win.backend.queueToggle(name);
        }

        function clearSelection() {
            win.backend.queueClear();
        }

        function selectAllVisible() {
            var next = [];
            for (var i = 0; i < win.rows.length; ++i)
                if (win.rows[i].installed)
                    next.push(win.rows[i].name);
            win.backend.queueSet(next);
        }

        // ── The row model ───────────────────────────────────────────
        // One uniform row shape whichever source the filter names, so the
        // table never branches on where a row came from.
        function _rowForInstalled(p) {
            var u = win.backend.updateFor(p.name);
            return {
                name: p.name,
                version: p.version,
                sizeMiB: p.sizeMiB,
                sizeText: p.sizeText,
                source: win.backend.sourceOf(p.name),
                foreign: win.backend.isForeign(p.name),
                installed: true,
                explicit: p.explicit,
                orphan: win.backend.isOrphan(p.name),
                installedAt: p.installedAt,
                update: u
            };
        }

        readonly property var rows: {
            var out = [];
            var q = win.query.trim().toLowerCase();
            var i;

            if (win.filter === "repos") {
                // The catalogue is 15,412 entries and only this filter
                // needs it, so it is fetched on demand rather than at
                // startup. An empty query here would render the whole
                // catalogue as a flat list, which is not a useful thing
                // to look at — repo browsing is search-first by design.
                var cat = win.backend.catalogue;
                if (q.length < 2)
                    return [];
                for (i = 0; i < cat.length; ++i) {
                    var c = cat[i];
                    if (c.name.toLowerCase().indexOf(q) < 0)
                        continue;
                    var known = win.backend.packageByName(c.name);
                    out.push({
                        name: c.name,
                        version: known ? known.version : c.version,
                        sizeMiB: known ? known.sizeMiB : 0,
                        sizeText: known ? known.sizeText : "—",
                        source: c.repo,
                        foreign: false,
                        installed: c.installed,
                        explicit: known ? known.explicit : false,
                        orphan: false,
                        installedAt: known ? known.installedAt : 0,
                        update: win.backend.updateFor(c.name)
                    });
                    if (out.length >= 400)
                        break;
                }
            } else if (win.filter === "updates") {
                var ups = win.backend.allUpdates;
                for (i = 0; i < ups.length; ++i) {
                    var known2 = win.backend.packageByName(ups[i].name);
                    if (known2) {
                        out.push(win._rowForInstalled(known2));
                    } else {
                        out.push({
                            name: ups[i].name,
                            version: ups[i].from,
                            sizeMiB: 0,
                            sizeText: "—",
                            source: ups[i].source === "aur" ? "AUR" : "repo",
                            foreign: ups[i].source === "aur",
                            installed: true,
                            explicit: false,
                            orphan: false,
                            installedAt: 0,
                            update: ups[i]
                        });
                    }
                }
            } else {
                var pkgs = win.backend.packages;
                for (i = 0; i < pkgs.length; ++i) {
                    var p = pkgs[i];
                    if (win.filter === "explicit" && !p.explicit)
                        continue;
                    if (win.filter === "aur" && !win.backend.isForeign(p.name))
                        continue;
                    if (win.filter === "orphans" && !win.backend.isOrphan(p.name))
                        continue;
                    if (q.length > 0 && p.name.toLowerCase().indexOf(q) < 0 && p.description.toLowerCase().indexOf(q) < 0)
                        continue;
                    out.push(win._rowForInstalled(p));
                }
            }

            // Sorting. Name is the tiebreaker everywhere so the order is
            // total and a re-render cannot reshuffle equal rows.
            var key = win.sortKey;
            var dir = win.sortDesc ? -1 : 1;
            out.sort(function (a, b) {
                var d = 0;
                if (key === "size")
                    d = a.sizeMiB - b.sizeMiB;
                else if (key === "date")
                    d = a.installedAt - b.installedAt;
                else if (key === "source")
                    d = a.source < b.source ? -1 : (a.source > b.source ? 1 : 0);
                else
                    d = a.name < b.name ? -1 : (a.name > b.name ? 1 : 0);
                if (d !== 0)
                    return d * dir;
                return a.name < b.name ? -1 : (a.name > b.name ? 1 : 0);
            });
            return out;
        }

        readonly property var focusRow: {
            if (win.focusName.length === 0)
                return null;
            for (var i = 0; i < win.rows.length; ++i)
                if (win.rows[i].name === win.focusName)
                    return win.rows[i];
            var p = win.backend.packageByName(win.focusName);
            return p ? win._rowForInstalled(p) : null;
        }

        function setFilter(f) {
            win.filter = f;
            if (f === "repos" && !win.backend.catalogueProbed)
                win.backend.refreshCatalogue();
        }

        function setSort(key) {
            if (win.sortKey === key) {
                win.sortDesc = !win.sortDesc;
                return;
            }
            win.sortKey = key;
            // Size and date are far more useful largest/newest-first;
            // name and source read naturally ascending.
            win.sortDesc = (key === "size" || key === "date");
        }

        Component.onCompleted: {
            if (loader.pendingFocus.length > 0) {
                win.focusName = loader.pendingFocus;
                loader.pendingFocus = "";
            }
            if (loader.pendingFilter.length > 0) {
                win.setFilter(loader.pendingFilter);
                loader.pendingFilter = "";
            }
        }

        Rectangle {
            id: background
            anchors.fill: parent
            color: Qt.rgba(win.surfaceBase.r, win.surfaceBase.g, win.surfaceBase.b, win.panelSurfaceOpacity)

            Behavior on color {
                enabled: Motion.motionEnabled
                ColorAnimation {
                    duration: Motion.colourDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.colourEasing
                }
            }
        }

        // ── Escape, and dismiss-on-click-outside ────────────────────
        // ROUND 2 CORRECTION. Round 1 used Qt's attached `Window.active`,
        // which was wrong on this host for a measurable reason:
        // `hyprctl getoption input:follow_mouse` is 1, so activation
        // follows the POINTER. The window therefore dismissed when the
        // mouse left its bounds rather than when something outside was
        // clicked — exactly what the operator reported.
        //
        // HyprlandFocusGrab is the right instrument: a protocol-level grab
        // whose `cleared` fires on a real click outside the grabbed set,
        // independent of hover focus. Settings.qml uses the same shape for
        // the same job.
        Item {
            id: focusCatcher
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: loader.activeAsync = false
            Component.onCompleted: forceActiveFocus()
        }

        HyprlandFocusGrab {
            id: grab
            windows: [win]
            active: true
            onCleared: loader.activeAsync = false
        }

        // A grab is EXCLUSIVE: while held, a window belonging to another
        // process is input-dead — the Security Center learned this when
        // its polkit prompt could not be clicked. Every transaction here
        // opens a terminal, so the window closes as the terminal launches.
        // That releases the grab with the LazyLoader and is also simply
        // the right behaviour: you have moved to the terminal. The queue
        // survives on the backend singleton.
        Connections {
            target: PackagesBackend

            function onTransactionLaunched(kind) {
                loader.activeAsync = false;
            }
        }


        Row {
            anchors.fill: parent
            spacing: 0

            WbSidebar {
                id: side
                height: parent.height
                bench: win
                width: win.sidebarWidth
            }

            // Drag strip between the rail and the table (operator round 2).
            // Its OWN width is constant, so dragging moves the boundary
            // without changing how much space the three panes divide.
            Item {
                id: sideGrip
                width: 6
                height: parent.height

                Rectangle {
                    anchors.centerIn: parent
                    width: 2
                    height: parent.height
                    color: gripArea.containsMouse || gripArea.pressed ? Colours.primary : Qt.alpha(Colours.outline, 0.35)

                    Behavior on color {
                        enabled: Motion.motionEnabled
                        ColorAnimation {
                            duration: Motion.colourDuration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Motion.colourEasing
                        }
                    }
                }

                // ── WHY SCENE COORDINATES AND NOT `mouse.x` ──────────
                // The first version computed `sidebarWidth + mouse.x -
                // width/2` on every move. That is a delta measured in the
                // GRIP'S OWN frame — and the grip moves the instant the
                // rail resizes, so each frame's measurement was taken
                // against a ruler the previous frame had already shifted.
                // Slow drags hid it (one pixel of error per frame); a fast
                // drag accumulated the error into visible judder and
                // drift, which is exactly the speed-dependent bug the
                // operator reported.
                //
                // Anchoring on the press instead makes it frame-
                // independent: remember the scene x and the width at
                // press, and every subsequent position is an absolute
                // offset from those two fixed numbers. `mapToItem(null,
                // …)` is scene space, which the rail's own resizing
                // cannot move.
                MouseArea {
                    id: gripArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.SizeHorCursor

                    property real pressSceneX: 0
                    property int pressWidth: 0

                    onPressed: mouse => {
                        gripArea.pressSceneX = gripArea.mapToItem(null, mouse.x, 0).x;
                        gripArea.pressWidth = win.sidebarWidth;
                    }

                    onPositionChanged: mouse => {
                        if (!gripArea.pressed)
                            return;
                        var sceneX = gripArea.mapToItem(null, mouse.x, 0).x;
                        win.setSidebarWidth(gripArea.pressWidth + (sceneX - gripArea.pressSceneX));
                    }
                }
            }

            WbTable {
                id: table
                width: parent.width - side.width - sideGrip.width - detailGrip.width - detail.width
                height: parent.height
                bench: win
            }

            // Right-hand grip (operator round 3). Identical mechanism to
            // the rail's, with the delta INVERTED: dragging left grows the
            // detail pane, because the boundary and the pane are on
            // opposite sides of the pointer here.
            Item {
                id: detailGrip
                width: 6
                height: parent.height

                Rectangle {
                    anchors.centerIn: parent
                    width: 2
                    height: parent.height
                    color: detailGripArea.containsMouse || detailGripArea.pressed ? Colours.primary : Qt.alpha(Colours.outline, 0.35)

                    Behavior on color {
                        enabled: Motion.motionEnabled
                        ColorAnimation {
                            duration: Motion.colourDuration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Motion.colourEasing
                        }
                    }
                }

                MouseArea {
                    id: detailGripArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.SizeHorCursor

                    property real pressSceneX: 0
                    property int pressWidth: 0

                    onPressed: mouse => {
                        detailGripArea.pressSceneX = detailGripArea.mapToItem(null, mouse.x, 0).x;
                        detailGripArea.pressWidth = win.detailWidth;
                    }

                    onPositionChanged: mouse => {
                        if (!detailGripArea.pressed)
                            return;
                        var sceneX = detailGripArea.mapToItem(null, mouse.x, 0).x;
                        win.setDetailWidth(detailGripArea.pressWidth - (sceneX - detailGripArea.pressSceneX));
                    }
                }
            }

            WbDetail {
                id: detail
                height: parent.height
                bench: win
                width: win.detailWidth
            }
        }
    }
}
