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
import QtQuick.Window
import Quickshell
import ".."
import "../dashboard"

LazyLoader {
    id: loader

    // Opening on a named package is how the launcher's `pkg` route and
    // the bar popout hand off — "show me this one" rather than "show me
    // everything and good luck".
    property string pendingFocus: ""

    function open(): void {
        loader.activeAsync = true;
    }

    function openOn(name: string): void {
        loader.pendingFocus = name || "";
        loader.activeAsync = true;
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

        // ── Escape, and dismiss-on-click-outside (operator round 1) ──
        // A FloatingWindow is a real toplevel, so it does not dismiss on
        // an outside click the way a layer surface does. FloatingWindow
        // exposes no focus property of its own either (checked against
        // quickshell-window.qmltypes: title/minimumSize/visible/…, no
        // `active`), so the signal is Qt's own attached `Window.active`
        // on an item inside — the same mechanism Settings.qml already
        // uses for its focus-retention, and per that file's measured
        // header the one belief that actually tracks activation
        // (`hyprctl activewindow` is NOT a reliable proxy).
        //
        // Deliberate consequence: pressing Review opens the terminal,
        // which takes focus, which closes this window. That is the right
        // behaviour — you have moved to the terminal — and the queue
        // survives it because `selected` lives on the backend singleton,
        // not on this window.
        Item {
            id: focusCatcher
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: loader.activeAsync = false

            Window.onActiveChanged: {
                if (!focusCatcher.Window.active)
                    loader.activeAsync = false;
                else
                    focusCatcher.forceActiveFocus();
            }

            Component.onCompleted: forceActiveFocus()
        }

        Row {
            anchors.fill: parent
            spacing: 0

            WbSidebar {
                id: side
                height: parent.height
                bench: win
            }

            WbTable {
                id: table
                width: parent.width - side.width - detail.width
                height: parent.height
                bench: win
            }

            WbDetail {
                id: detail
                height: parent.height
                bench: win
            }
        }
    }
}
