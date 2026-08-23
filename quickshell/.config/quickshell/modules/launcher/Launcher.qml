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
import "fuzzy.js" as Fuzzy

PanelWindow {
    id: launcherWindow

    // shell.qml's launcherLoader listens for this to deactivate itself,
    // which destroys the wl_surface (D-14's zero-idle doctrine) rather
    // than merely hiding it — same contract as Dashboard.qml/Overview.qml.
    signal dismissRequested()

    // Threaded in from shell.qml's single `root.edgeBarEnabled` resolution
    // point (quick task 260823-9ak, Task 6, D-5) — this file has no `root`
    // id of its own to read (a separate document's ids are not visible
    // here), so the value is passed in as a property rather than
    // re-resolved via a second `Prefs.getValue` call. Per D-5: DIRECTION
    // branches on this flag (bottom-anchored ON, top-anchored — today's
    // exact behaviour — OFF); the corner SHAPE below does not branch.
    property bool edgeBarEnabled: false

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
    // not flush against the bar. Per P-2, this margin applies only when
    // the edge bar is OFF (R3: exactly today's behaviour); when the edge
    // bar is ON the launcher is bottom-anchored instead (below) and sits
    // flush (margin 0) against the true screen edges so the flares
    // actually meet the strip.
    readonly property int drawerTopMargin: 10
    margins.top: launcherWindow.edgeBarEnabled ? 0 : launcherWindow.drawerTopMargin
    margins.bottom: 0

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

    // ── App enumeration + fuzzy filter (quick task 260822-sht, Task 2 —
    //    replaces Task 1's plain substring filter with the vendored
    //    `fuzzy.js` matcher). Score is computed ONCE per app per keystroke
    //    (not per comparison) and cached on each match entry alongside the
    //    app itself, so the sort below reads `_score` rather than
    //    recomputing it — the exact same "hoist the expensive read out of
    //    the comparator" discipline this task's own pre-Task-2 fix applied
    //    to the frecency-counts lookup, applied here to fuzzy scoring.
    //
    //    Empty query: no fuzzy scoring at all (a `-1`/`0` split is
    //    meaningless with nothing typed) — every app matches and
    //    `_compareApps` alone (alpha/frecency) orders the list, exactly
    //    Task 1's original empty-query behaviour. Non-empty query: fuzzy
    //    score DESCENDING is the primary order (a better subsequence match
    //    ranks first); `_compareApps` is the tiebreaker for equal scores,
    //    per this task's own plan text ("Task 2's vendored fuzzy matcher
    //    composes with this by calling it as ITS tiebreaker").
    readonly property var filteredApps: {
        const q = LauncherState.query.trim();
        const all = DesktopEntries.applications.values.filter(function (e) {
            return !e.noDisplay;
        });
        const counts = launcherWindow.sortMode === launcherWindow.sortModeFrecency ? Prefs.getValue("launcher.launchCounts") : undefined;

        if (q === "") {
            return all.slice().sort(function (a, b) {
                return launcherWindow._compareApps(a, b, counts);
            });
        }

        const scored = [];
        for (let i = 0; i < all.length; i++) {
            const entry = all[i];
            const s = Fuzzy.score(q, entry.name || "");
            if (s >= 0)
                scored.push({
                    entry: entry,
                    _score: s
                });
        }
        scored.sort(function (a, b) {
            if (a._score !== b._score)
                return b._score - a._score;
            return launcherWindow._compareApps(a.entry, b.entry, counts);
        });
        return scored.map(function (s) {
            return s.entry;
        });
    }

    // ── Generic mode nav glue (quick task 260822-sht, Task 2) ────────────
    // Every mode result view (the apps ListView below, CalcMode,
    // WebSearchMode, FilesMode, the inline providerlist/placeholder
    // Components further down) exposes the same duck-typed trio:
    // `currentIndex`, `count`, `activate()`. `searchField`'s Up/Down/Enter
    // handlers call these three functions instead of reaching into a
    // fixed `resultsList` id directly, so the same three key handlers work
    // unmodified across every mode the results Loader below can show.
    function _activeItem() {
        return resultsLoader.item;
    }

    // Item 3 fix (quick task 260822-sht) — grid-aware row step. A mode
    // that is a grid (EmojiMode) exposes a `columns` property alongside
    // the duck-typed trio above; a plain list (every other mode) does
    // not, so `step` falls back to `1` and this function's behaviour for
    // every existing mode is byte-identical to before this fix — `delta`
    // is still `±1` at both call sites below, only the multiplier
    // changes for a mode that opts in. Reads `item.columns` (the SAME
    // value the grid itself renders with — EmojiMode.qml's `root.columns`
    // — never a second hardcoded `4` here), so navigation stays correct
    // if that column count ever becomes width-responsive.
    // Up/Down. WRAPS at both ends rather than stopping on the last item
    // (operator request): past the bottom returns to the top and vice
    // versa, so a long app list is reachable from either direction.
    function moveSelection(delta) {
        const item = launcherWindow._activeItem();
        // CalcMode/WebSearchMode declare `currentIndex` READONLY (a
        // single-result view is always "row 0") — their `count` is never
        // above 1, so this guard keeps the writes below from ever
        // targeting a readonly property; it is not merely defensive.
        if (!item || item.count === undefined || item.count <= 1)
            return;
        const count = item.count;
        const columns = item.columns !== undefined && item.columns > 0 ? item.columns : 1;

        // Flat list: plain modular wrap. The double-modulo keeps a
        // negative intermediate (index 0 moving up) positive.
        if (columns === 1) {
            item.currentIndex = ((item.currentIndex + delta) % count + count) % count;
            return;
        }

        // Grid (EmojiMode): move a whole row, holding the column, and wrap
        // around the row count. The final row is usually PARTIAL — 160
        // emoji over 4 columns is exact today, but `columns` is a real
        // property and the tsv is operator-editable, so a hole in the last
        // row must not select an index past `count`. Stepping again in the
        // same direction skips the hole; the loop is bounded by `rows`, so
        // a grid with no valid landing simply leaves the selection alone
        // rather than spinning.
        const rows = Math.ceil(count / columns);
        const col = item.currentIndex % columns;
        let row = Math.floor(item.currentIndex / columns);
        for (let i = 0; i < rows; i++) {
            row = ((row + delta) % rows + rows) % rows;
            const candidate = row * columns + col;
            if (candidate < count) {
                item.currentIndex = candidate;
                return;
            }
        }
    }

    // Item 3 fix (quick task 260822-sht) — Left/Right tile-within-row
    // navigation, grid-only. Returns `false` for every mode that does not
    // expose `item.columns` (every mode except EmojiMode), so the
    // searchField's `Keys.onLeftPressed`/`onRightPressed` handlers below
    // leave `event.accepted` unset and the TextField's own default cursor
    // movement runs unchanged while filtering — this function is never
    // reached with intent to move a text cursor.
    //
    // WRAPS WITHIN THE ROW (operator request). Left/Right still never spill
    // into the row above or below — Up/Down own that axis, and that split is
    // what makes the two directions predictable — so wrapping here means
    // running off the right edge returns to that same row's first tile.
    // `rowLength` is computed from `count`, not from `columns`, so a partial
    // final row wraps across the tiles it actually has instead of through
    // empty cells.
    function moveSelectionColumn(delta) {
        const item = launcherWindow._activeItem();
        if (!item || item.columns === undefined || item.columns <= 0 || item.count === undefined || item.count <= 1)
            return false;
        const columns = item.columns;
        const rowStart = Math.floor(item.currentIndex / columns) * columns;
        const rowLength = Math.min(columns, item.count - rowStart);
        if (rowLength <= 1)
            return true;
        const col = item.currentIndex - rowStart;
        const newCol = ((col + delta) % rowLength + rowLength) % rowLength;
        item.currentIndex = rowStart + newCol;
        return true;
    }

    function activateCurrent() {
        const item = launcherWindow._activeItem();
        if (item && typeof item.activate === "function")
            item.activate();
    }

    // Apps mode's own `activate()` implementation, called via the apps
    // ListView's `activate()` below (never called directly by a key
    // handler any more — see `activateCurrent()` above). Reads the
    // CURRENTLY LOADED item's `currentIndex` via `resultsLoader.item`
    // rather than a fixed `resultsList` id, because `resultsList` is now
    // declared INSIDE `appsComponent` below — a `Component` boundary,
    // which is its own id scope (ids inside a `Component` are not visible
    // to bindings/functions declared outside it, the same rule this file's
    // own delegate already relies on in reverse: `resultDelegate` can see
    // `resultsList` because BOTH live inside the same Component).
    // Item 1 fix (quick task 260822-sht, operator-reported: "restarting
    // quickshell kills apps launched from the app list"). ROOT CAUSE:
    // `entry.execute()` (DesktopEntry.execute()) spawns the child INSIDE
    // quickshell's own process, which sits in `quickshell.service`'s
    // `KillMode=control-group` cgroup — a service restart kills every app
    // ever launched from this list. `uwsm app --` is this repo's already-
    // established fix for the same class of problem: it hands the launch
    // to uwsm's app daemon, which starts the child as its OWN systemd
    // scope (verified live: Steam launched via `uwsm app --` lands in
    // `app-Hyprland-steam-<hash>.scope`, not quickshell's). Passing the
    // Desktop Entry ID (not a hand-expanded `execString`) is deliberate:
    // uwsm resolves `StartupWMClass`, `Terminal=` and `%U`/`%f` field
    // codes itself from the entry file — `uwsm`'s own `app()` sets
    // `terminal = True` automatically when `entry.getTerminal()` is true
    // for a Desktop-Entry-ID launch (verified against
    // `/usr/share/uwsm/modules/uwsm/main.py`), so `runInTerminal` entries
    // need no separate handling here. `entry.id` never carries the
    // `.desktop` suffix (`DesktopEntries.byId()` elsewhere in this repo,
    // e.g. NotifGroup.qml:142, is keyed the same bare way) but `uwsm app`
    // requires a full Desktop File ID ending in `.desktop`
    // (`uwsm-app.1`'s own MainArg parser only recognises an argument that
    // `endswith(".desktop")`) — appended here, matching LauncherCapsule.qml's
    // already-shipped `uwsm app -- <id>.desktop` convention verbatim.
    function launchCurrent() {
        const item = resultsLoader.item;
        const idx = item ? item.currentIndex : 0;
        const entry = launcherWindow.filteredApps[idx];
        if (entry && entry.id && entry.id.length > 0) {
            Quickshell.execDetached(["uwsm", "app", "--", entry.id + ".desktop"]);
            launcherWindow._bumpLaunchCount(entry);
        }
        launcherWindow._beginDismiss();
    }

    // The verified counter key is `entry.id` (quickshell-core.qmltypes'
    // `DesktopEntry.id: QString`) — never `name` or a synthesised slug, so
    // the keyspace can't mix. `Prefs.setValue()` refuses every write until
    // its own load has settled (returns false, per its own contract) —
    // that's fine here: `Quickshell.execDetached()` above already fired
    // (fire-and-forget, independent of this surface's own lifetime — see
    // the Item 1 fix comment above), so the launch itself never depends on
    // this succeeding, only the tally can drop.
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

        // ── Drop-down/rise entrance, in QML (quick task 260823-9ak,
        //    Task 6, D-5) ────────────────────────────────────────────
        // The LazyLoader creates this surface fresh on every summon
        // (D-14), so `Component.onCompleted` IS the open event; there is
        // no reopen case to reset. Direction branches on `edgeBarEnabled`
        // (D-5): OFF is `opened ? 0 : -height` unchanged (today's exact
        // drop from the top); ON rises from the bottom instead, flush
        // against `launcherWindow.height` (the window's own local
        // content height, already net of the flush margins above).
        property bool opened: false
        y: launcherWindow.edgeBarEnabled ? (opened ? launcherWindow.height - height : launcherWindow.height) : (opened ? 0 : -height)
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
            // Per D-5 (quick task 260823-9ak, Task 6): the square/round
            // pair flips with direction — round the end the panel RISES
            // FROM (bottom, edge-bar mode) or drops FROM (top, disabled)
            // stays square; the far end is the opposite.
            topLeftRadius: launcherWindow.edgeBarEnabled ? launcherWindow.cornerRadius : 0
            topRightRadius: launcherWindow.edgeBarEnabled ? launcherWindow.cornerRadius : 0
            bottomLeftRadius: launcherWindow.edgeBarEnabled ? 0 : launcherWindow.cornerRadius
            bottomRightRadius: launcherWindow.edgeBarEnabled ? 0 : launcherWindow.cornerRadius
            color: Qt.rgba(launcherWindow.surfaceBase.r, launcherWindow.surfaceBase.g, launcherWindow.surfaceBase.b, launcherWindow.drawerSurfaceOpacity)
        }

        // DASH-10's animated gradient rim, reused verbatim — matches
        // Hyprland's own window border so the drawer reads as part of the
        // same desktop rather than as a foreign panel. Radii are handed
        // across from the same properties `background` uses, mirroring
        // Dashboard.qml:672-680.
        GradientBorder {
            id: launcherGradientBorder
            anchors.fill: parent
            borderWidth: Design.borderWidth
            topLeftRadius: launcherWindow.edgeBarEnabled ? launcherWindow.cornerRadius : 0
            topRightRadius: launcherWindow.edgeBarEnabled ? launcherWindow.cornerRadius : 0
            bottomLeftRadius: launcherWindow.edgeBarEnabled ? 0 : launcherWindow.cornerRadius
            bottomRightRadius: launcherWindow.edgeBarEnabled ? 0 : launcherWindow.cornerRadius
        }

        // ── Attached corners (quick task 260823-9ak, Task 1+6, R7/P-1/D-5) ─
        // Two concave flares joining the panel's own top corners (edge-bar
        // OFF) or bottom corners (edge-bar ON) to the screen edge the
        // panel hangs from — siblings of `background`, painting OUTSIDE
        // the panel's own bounds (`panel` carries no `clip` here, unlike
        // Dashboard.qml's own panel — see that file's own Task 2 note).
        // Per D-5, only the EDGE branches (`edge` ternary + the `y`
        // positioning below, which replaces a fixed `anchors.top: panel.top`
        // so either panel edge can be targeted) — the corner SHAPE itself
        // (AttachedCorner's own geometry) is never branched; it is present
        // and identically shaped in both modes. `angle` reads
        // `startAngle + angle` off the SAME GradientBorder instance above,
        // so the rim's gradient sweep never drifts out of phase with the
        // panel's own rim.
        AttachedCorner {
            id: launcherFlareLeft
            edge: launcherWindow.edgeBarEnabled ? "bottom" : "top"
            side: "left"
            flareRadius: Design.attachedCornerRadius
            anchors.right: panel.left
            y: launcherWindow.edgeBarEnabled ? panel.height - flareRadius : 0
            fillColour: Qt.rgba(launcherWindow.surfaceBase.r, launcherWindow.surfaceBase.g, launcherWindow.surfaceBase.b, launcherWindow.drawerSurfaceOpacity)
            borderWidth: Design.borderWidth
            angle: launcherGradientBorder.startAngle + launcherGradientBorder.angle
            gradientCentre: Qt.point(panel.width / 2 - launcherFlareLeft.x, panel.height / 2 - launcherFlareLeft.y)
            gradientHalfDiagonal: Math.sqrt(panel.width * panel.width + panel.height * panel.height) / 2
        }
        AttachedCorner {
            id: launcherFlareRight
            edge: launcherWindow.edgeBarEnabled ? "bottom" : "top"
            side: "right"
            flareRadius: Design.attachedCornerRadius
            anchors.left: panel.right
            y: launcherWindow.edgeBarEnabled ? panel.height - flareRadius : 0
            fillColour: Qt.rgba(launcherWindow.surfaceBase.r, launcherWindow.surfaceBase.g, launcherWindow.surfaceBase.b, launcherWindow.drawerSurfaceOpacity)
            borderWidth: Design.borderWidth
            angle: launcherGradientBorder.startAngle + launcherGradientBorder.angle
            gradientCentre: Qt.point(panel.width / 2 - launcherFlareRight.x, panel.height / 2 - launcherFlareRight.y)
            gradientHalfDiagonal: Math.sqrt(panel.width * panel.width + panel.height * panel.height) / 2
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
                    //
                    // The per-mode "reset selection to row 0 on a new
                    // filter" reset moved OUT of this handler in Task 2 —
                    // it now lives inside each mode's own result view
                    // (apps ListView's `onModelChanged` below, FilesMode's
                    // own `_search()`), since this field can no longer
                    // reach a single fixed `resultsList` id: which result
                    // view is even loaded now depends on `LauncherState.mode`.
                    text: LauncherState.query
                    onTextChanged: {
                        if (LauncherState.query !== searchField.text)
                            LauncherState.query = searchField.text;
                    }

                    Keys.onEscapePressed: function (event) {
                        launcherWindow._beginDismiss();
                        event.accepted = true;
                    }
                    Keys.onReturnPressed: function (event) {
                        launcherWindow.activateCurrent();
                        event.accepted = true;
                    }
                    Keys.onEnterPressed: function (event) {
                        launcherWindow.activateCurrent();
                        event.accepted = true;
                    }
                    Keys.onDownPressed: function (event) {
                        launcherWindow.moveSelection(1);
                        event.accepted = true;
                    }
                    Keys.onUpPressed: function (event) {
                        launcherWindow.moveSelection(-1);
                        event.accepted = true;
                    }

                    // ── Grid Left/Right (quick task 260822-sht, Item 3,
                    //    operator-requested arrow-key nav) — routed through
                    //    the same searchField key-handler arrangement as
                    //    Up/Down/Enter/Escape above, not a competing
                    //    handler elsewhere. `moveSelectionColumn()` returns
                    //    `false` for every mode except EmojiMode (the only
                    //    one exposing `columns`), so `event.accepted` is
                    //    only ever set true in grid mode — every other
                    //    mode's searchField keeps the TextField's own
                    //    default Left/Right cursor movement while the
                    //    operator is typing a filter query, exactly as
                    //    before this fix.
                    Keys.onLeftPressed: function (event) {
                        if (launcherWindow.moveSelectionColumn(-1))
                            event.accepted = true;
                    }
                    Keys.onRightPressed: function (event) {
                        if (launcherWindow.moveSelectionColumn(1))
                            event.accepted = true;
                    }

                    // ── Backspace-goes-back (quick task 260822-sht,
                    //    feature 2) ─────────────────────────────────────
                    // No dedicated `Keys.onBackspacePressed` compatibility
                    // signal exists (unlike Up/Down/Return/Escape above),
                    // so this reads the raw key. Only ever acts when the
                    // query is ALREADY empty — with any text still in the
                    // field this returns immediately on the first line and
                    // the TextField's own default handling deletes a
                    // character exactly as it always has, which is the one
                    // hazard this feature exists to avoid. Every
                    // prefix-routed mode (calc/files/websearch/clipboard/
                    // symbols/providerlist) already reverts to apps mode
                    // via LauncherState's own `_routeQuery()` the moment
                    // its OWN prefix character is itself backspaced away,
                    // through that same default path — so by the time the
                    // branches below ever run, that transition has already
                    // happened.
                    Keys.onPressed: function (event) {
                        if (event.key !== Qt.Key_Backspace)
                            return;
                        if (searchField.text.length > 0)
                            return;

                        if (LauncherState.mode === LauncherState.modeMenu) {
                            // Reuses MenuMode.qml's own `_goBack()` rather
                            // than duplicating its navStack-pop logic here
                            // — `resultsLoader.item` IS the live MenuMode
                            // instance whenever `mode === modeMenu`.
                            // Empty navStack (menu root): no-op, per this
                            // feature's own explicit requirement — Escape
                            // remains the one way out from there.
                            if (LauncherState.navStack.length > 0) {
                                const item = launcherWindow._activeItem();
                                if (item && typeof item._goBack === "function")
                                    item._goBack();
                            }
                            event.accepted = true;
                            return;
                        }

                        // Leaf mode. MenuMode.qml's own `activate()` never
                        // touches `navStack` when handing off to a `mode:`
                        // leaf (Style ▸ Theme, Tools ▸ Clipboard, etc.), so
                        // a non-empty `navStack` IS the "reached via the
                        // menu" signal here — independent of which mode
                        // name this is, since the SAME mode name (e.g.
                        // "clipboard"/"symbols") is also reachable directly
                        // by typing `:`/`.`, where navStack stays empty the
                        // whole time. A leaf reached via the menu returns
                        // to it at the exact level it was drilled from.
                        if (LauncherState.navStack.length > 0) {
                            LauncherState.mode = LauncherState.modeMenu;
                            event.accepted = true;
                            return;
                        }

                        // Not reached from the menu (apps mode, a typed
                        // prefix route, or recordaudio's mid-flow IPC
                        // entry) — least-surprising choice, mirroring the
                        // menu-root rule two branches up: do nothing.
                        // Escape stays the one way to dismiss from here.
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

            // ── Results area — mode Loader (quick task 260822-sht, Task 2)
            //    ──────────────────────────────────────────────────────────
            // Task 1 shipped a single fixed apps ListView here; Task 2
            // replaces it with a Loader whose `sourceComponent` switches on
            // `LauncherState.mode`, per D-1 Option B's own "one frame,
            // shared search field and chrome, results area swaps component
            // per content type" shape. Every Component below instantiates
            // an item exposing the same duck-typed trio `_activeItem()` /
            // `moveSelection()` / `activateCurrent()` read: `currentIndex`,
            // `count`, `activate()`.
            //
            // No explicit `height:` here — a `Loader` with only `width` set
            // auto-sizes its own height to the loaded item's height (Qt's
            // documented default), so `contentColumn`'s `Column` layout
            // keeps reflowing correctly as the loaded item's own height
            // varies mode to mode, exactly as it did when `resultsList` was
            // this Column's direct child.
            Loader {
                id: resultsLoader
                width: parent.width
                sourceComponent: {
                    switch (LauncherState.mode) {
                    case LauncherState.modeCalc:
                        return calcComponent;
                    case LauncherState.modeFiles:
                        return filesComponent;
                    case LauncherState.modeWebSearch:
                        return webSearchComponent;
                    case LauncherState.modeProviderList:
                        return providerListComponent;
                    case LauncherState.modeClipboard:
                        return clipboardComponent;
                    case LauncherState.modeSymbols:
                        return emojiComponent;
                    case LauncherState.modeMenu:
                        return menuComponent;
                    // "updates"/"systeminfo" (R-1/R-2, quick task
                    // 260822-sht, Task 4) are raw string literals rather
                    // than LauncherState.mode* constants — these two modes
                    // are reachable ONLY via MenuTree.qml's own `mode:
                    // "updates"`/`mode: "systeminfo"` leaf fields (System ▸
                    // Updates, System ▸ System info), never via a typed
                    // route prefix, so they have no reason to live in
                    // LauncherState.qml's prefix-routing table — the exact
                    // same reasoning Tools ▸ Clipboard's `mode: "clipboard"`
                    // already established for a mode value written as a
                    // literal in MenuTree.qml. Task 4 does not touch
                    // LauncherState.qml.
                    case "updates":
                        return updatesComponent;
                    case "systeminfo":
                        return systemInfoComponent;
                    // "theme"/"barorientation" (quick task 260822-sht,
                    // Task 5, consumers 1 and 6) — same raw-literal,
                    // MenuTree-only-reachable shape as "updates"/
                    // "systeminfo" above; one PickerMode.qml type,
                    // distinguished by its own `pickerId` prop.
                    case "theme":
                        return themePickerComponent;
                    case "barorientation":
                        return barOrientationPickerComponent;
                    // "recordaudio"/"clipboardwipe" (quick task
                    // 260822-sht, Task 6, consumers 4 and 5) — same
                    // raw-literal shape. "recordaudio" is reached via the
                    // launcher IPC directly from `record-toggle.sh`'s own
                    // `pick_audio()`, not a MenuTree leaf — the one
                    // exception to "MenuTree-only-reachable" the comment
                    // above names, because this mode fires mid-flow from
                    // a running script, not from browsing the menu.
                    case "recordaudio":
                        return recordAudioPickerComponent;
                    case "clipboardwipe":
                        return clipboardWipeConfirmComponent;
                    // "keybinds" (quick task 260822-sht, Task 9) — same
                    // raw-literal, MenuTree-only-reachable shape.
                    case "keybinds":
                        return keybindsComponent;
                    default:
                        return appsComponent;
                    }
                }
            }

            // ── Apps mode (Task 1's original view, now Loader-hosted) ────
            Component {
                id: appsComponent

                ListView {
                    id: resultsList
                    width: resultsLoader.width
                    height: Math.min(360, count * 48)
                    clip: true
                    model: launcherWindow.filteredApps
                    currentIndex: 0
                    // Replaces the reset that used to live in searchField's
                    // own onTextChanged — `filteredApps` (and therefore
                    // `model`) changes on every query keystroke, so resetting
                    // here keeps the highlighted row from pointing at a
                    // now-unrelated app after a refilter.
                    onModelChanged: currentIndex = 0

                    // Duck-typed `activate()` Launcher.qml's `activateCurrent()`
                    // reads — delegates to `launchCurrent()`, which is only
                    // ever called while THIS item is the loaded one.
                    function activate() {
                        launcherWindow.launchCurrent();
                    }

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

            // ── `=` calc, `@` websearch, `/` files — thin wrappers around
            //    the three standalone mode files (quick task 260822-sht,
            //    Task 2). ───────────────────────────────────────────────
            Component {
                id: calcComponent

                CalcMode {
                }
            }

            Component {
                id: webSearchComponent

                WebSearchMode {
                }
            }

            Component {
                id: filesComponent

                FilesMode {
                }
            }

            // ── Menu mode — the 9 D-2 verb-based roots (quick task
            //    260822-sht, Task 3). `dismissCallback` is evaluated in
            //    THIS Component's own enclosing scope (Launcher.qml's own
            //    document), where `launcherWindow` is a visible id, then
            //    handed to MenuMode.qml as a plain function-valued
            //    property — MenuMode.qml lives in a separate file and has
            //    no other way to close the surface it's hosted in. ──────
            Component {
                id: menuComponent

                MenuMode {
                    dismissCallback: launcherWindow._beginDismiss
                }
            }

            // ── System ▸ Updates / System ▸ System info (quick task
            //    260822-sht, Task 4 — R-1/R-2). Read-only report views;
            //    neither dismisses on activate() since there is nothing to
            //    "pick" — the user reads the list and closes the launcher
            //    themselves (Escape/click-outside), same as leaving apps
            //    mode open after a search that didn't launch anything. ────
            Component {
                id: updatesComponent

                UpdatesMode {
                }
            }

            Component {
                id: systemInfoComponent

                SystemInfoMode {
                }
            }

            // ── Style ▸ Theme / Style ▸ Bar orientation (quick task
            //    260822-sht, Task 5, consumers 1 and 6). Non-interactive
            //    pickers per D-1's inversion of control — Enter runs the
            //    consumer with an argument and dismisses, exactly like
            //    `launchCurrent()`'s own launch-then-dismiss shape.
            //    `dismissCallback` is evaluated in THIS Component's own
            //    enclosing scope, same reasoning as `menuComponent`
            //    above. ─────────────────────────────────────────────────
            Component {
                id: themePickerComponent

                PickerMode {
                    pickerId: "theme"
                    dismissCallback: launcherWindow._beginDismiss
                }
            }

            Component {
                id: barOrientationPickerComponent

                PickerMode {
                    pickerId: "barorientation"
                    dismissCallback: launcherWindow._beginDismiss
                }
            }

            // ── Capture ▸ Record toggle audio / Tools ▸ Clipboard wipe
            //    (quick task 260822-sht, Task 6, consumers 4 and 5). Same
            //    dismiss-on-Enter shape as the two Components above. ────
            Component {
                id: recordAudioPickerComponent

                PickerMode {
                    pickerId: "recordaudio"
                    dismissCallback: launcherWindow._beginDismiss
                }
            }

            Component {
                id: clipboardWipeConfirmComponent

                ConfirmMode {
                    confirmId: "clipboardwipe"
                    dismissCallback: launcherWindow._beginDismiss
                }
            }

            // ── Learn ▸ Keybinds (quick task 260822-sht, Task 9) — a
            //    table reference, not a launcher (T-07-26); dismisses on
            //    activate() the same one-shot shape as the retired
            //    surface (select once, close), whether the pick was a
            //    chord copy or the pinned View-all row. ─────────────────
            Component {
                id: keybindsComponent

                KeybindsMode {
                    dismissCallback: launcherWindow._beginDismiss
                }
            }

            // ── `;` providerlist — rows listing the other five routable
            //    prefixes (quick task 260822-sht, Task 2). Like-for-like
            //    with the retired `providerlist` provider, not net-new
            //    (this task's own plan text). Selecting a row sets
            //    `LauncherState.query` to that provider's bare prefix
            //    character and does NOT dismiss the surface — the point is
            //    to keep typing inside the chosen mode, exactly like typing
            //    the prefix character directly would. ────────────────────
            Component {
                id: providerListComponent

                Item {
                    id: providerListRoot
                    width: resultsLoader.width
                    height: Math.min(320, Math.max(providerListRoot._entries.length, 1) * 40)

                    readonly property var _entries: [
                        {
                            prefix: "=",
                            label: "Calculator"
                        },
                        {
                            prefix: "/",
                            label: "Files"
                        },
                        {
                            prefix: ":",
                            label: "Clipboard"
                        },
                        {
                            prefix: ".",
                            label: "Symbols"
                        },
                        {
                            prefix: "@",
                            label: "Web search"
                        }
                    ]
                    property int currentIndex: 0
                    readonly property int count: providerListRoot._entries.length

                    function activate() {
                        const entry = providerListRoot._entries[providerListRoot.currentIndex];
                        if (entry)
                            LauncherState.query = entry.prefix;
                    }

                    ListView {
                        id: providerListView
                        anchors.fill: parent
                        clip: true
                        interactive: false
                        model: providerListRoot._entries
                        currentIndex: providerListRoot.currentIndex

                        delegate: Rectangle {
                            id: providerDelegate
                            required property var modelData
                            required property int index

                            width: providerListView.width
                            height: 40
                            radius: 8
                            color: providerListRoot.currentIndex === providerDelegate.index ? Colours.surfaceVariant : "transparent"

                            Row {
                                anchors.left: parent.left
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: 12
                                spacing: Design.spacingSm

                                Text {
                                    text: providerDelegate.modelData.prefix
                                    color: Colours.primary
                                    font.pixelSize: 15
                                    font.bold: true
                                }
                                Text {
                                    text: providerDelegate.modelData.label
                                    color: Colours.onSurface
                                    font.pixelSize: 15
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    providerListRoot.currentIndex = providerDelegate.index;
                                    providerListRoot.activate();
                                }
                            }
                        }
                    }
                }
            }

            // ── `.` symbols / Tools ▸ Emoji (quick task 260822-sht, Task
            //    7). `dismissCallback` is evaluated in THIS Component's own
            //    enclosing scope, same reasoning as `menuComponent` above —
            //    picking a glyph is a decisive one-shot action, same shape
            //    as a PickerMode pick. ─────────────────────────────────────
            Component {
                id: emojiComponent

                EmojiMode {
                    dismissCallback: launcherWindow._beginDismiss
                }
            }

            // ── `:` clipboard / Tools ▸ Clipboard (quick task 260822-sht,
            //    Task 8) — the last of the six prefix routes to get its
            //    real component; no placeholder remains in this Loader.
            //    `dismissCallback` fires on restore-pick, same one-shot
            //    shape as EmojiMode above (wipe-all instead switches
            //    `LauncherState.mode` without dismissing, same as any
            //    other mode handoff). ─────────────────────────────────────
            Component {
                id: clipboardComponent

                ClipboardMode {
                    dismissCallback: launcherWindow._beginDismiss
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
