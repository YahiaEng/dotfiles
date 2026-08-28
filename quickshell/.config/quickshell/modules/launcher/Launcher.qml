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
import "../packages"
import "fuzzy.js" as Fuzzy

PanelWindow {
    id: launcherWindow

    // shell.qml's launcherLoader listens for this to deactivate itself,
    // which destroys the wl_surface (D-14's zero-idle doctrine) rather
    // than merely hiding it — same contract as Dashboard.qml/Overview.qml.
    signal dismissRequested()

    // Threaded in from shell.qml's single resolution point (quick task
    // 260823-9ak Task 6 D-5, split into two predicates by quick task
    // 260824-ns3 Task 1, Q2) — this file has no `root` id of its own to
    // read (a separate document's ids are not visible here), so both
    // values are passed in as properties rather than re-resolved via a
    // second `Prefs.getValue` call.
    //
    // `edgeBarRailPresent` answers "is any rail present" — DIRECTION
    // (bottom-anchored when true, top-anchored — today's exact behaviour
    // — when false) branches on THIS one, never on the style string
    // (Q2b, the load-bearing detail).
    property bool edgeBarRailPresent: false
    // `edgeBarPanelsAttach` is a SEPARATE predicate (Q3-brackets): rails
    // can be present while panels do not weld to them (Brackets). The
    // welded/square-round corner shape, the flare and the rim clip below
    // branch on THIS one.
    property bool edgeBarPanelsAttach: false

    // ── Animated dismiss (quick task 260822-sht, Task 1 REWORK) ─────────
    // Mirrors Dashboard.qml's own `_dismissing`/`_beginDismiss` shape: the
    // real `dismissRequested()` (which shell.qml's loader answers by
    // destroying the surface) is deferred until the panel's own out
    // animation has actually played, so Escape/Enter/click-outside never
    // cut the drop-down off mid-flight.
    // ── HOVER-SUMMON DISMISSAL (operator round 12) ──────────────────────
    // The twin of Dashboard.qml's block; see it for the full derivation.
    // Set by shell.qml immediately BEFORE this loader is activated, so it
    // is already correct at construction. Only the bottom bulge's hover
    // path sets it true — Super+Space and Super-tap leave it false.
    //
    // WORTH KNOWING: the bottom bulge's hover opens MENU mode, not apps
    // mode (shell.qml routes it through `launcherMenuShortcut._toggleMenu`,
    // R6), so in practice this arms the MENU surface rather than the app
    // launcher. Both live in this one component.
    property bool hoverSummoned: false
    property bool _hoverArmEligible: false
    property bool _pointerHasEntered: false

    Timer {
        id: hoverLeaveTimer
        interval: Design.drawerHoverLeaveGraceMs
        repeat: false
        onTriggered: launcherWindow._beginDismiss()
    }
    Timer {
        id: hoverIdleTimer
        interval: Design.drawerHoverIdleDismissMs
        repeat: false
        onTriggered: launcherWindow._beginDismiss()
    }

    function _onDrawerHoverChanged(inside: bool): void {
        if (!launcherWindow._hoverArmEligible)
            return;
        if (inside) {
            launcherWindow._pointerHasEntered = true;
            hoverIdleTimer.stop();
            hoverLeaveTimer.stop();
            return;
        }
        if (launcherWindow._pointerHasEntered)
            hoverLeaveTimer.restart();
    }

    property bool _dismissing: false
    function _beginDismiss() {
        hoverLeaveTimer.stop();
        hoverIdleTimer.stop();
        if (launcherWindow._dismissing)
            return;
        launcherWindow._dismissing = true;
        panel.opened = false;
        exitTimer.start();
    }
    // Teardown timer — must OUTLAST the exit animation, or shell.qml's
    // loader destroys the wl_surface mid-slide. A time-reversed exit runs
    // for exactly as long as the entrance it reverses, so this is the max
    // of the two ENTRANCE durations (operator round 9). It read
    // `emphasizedOutDuration` — 150ms — which would now sever the 450ms
    // reversed slide at a third of its travel.
    Timer {
        id: exitTimer
        interval: Motion.motionEnabled ? Math.max(Motion.spatialInDuration, Motion.emphasizedInDuration) : 0
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
    // no rail is present (R3: exactly today's behaviour); when a rail IS
    // present the launcher is bottom-anchored instead (below) and, if its
    // panels weld to that rail, sits flush (margin 0) against the true
    // screen edge so the flares actually meet the strip.
    readonly property int drawerTopMargin: 10
    margins.top: launcherWindow.edgeBarRailPresent ? 0 : launcherWindow.drawerTopMargin
    // Third state (quick task 260824-ns3, Q3-brackets): a rail present but
    // NOT welded (Brackets) floats the panel off the bottom screen edge by
    // the same drawerTopMargin the off-mode top drop uses, rather than
    // sitting flush against an edge it is not welded to.
    margins.bottom: (launcherWindow.edgeBarRailPresent && !launcherWindow.edgeBarPanelsAttach) ? launcherWindow.drawerTopMargin : 0

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
    // `favSet` (quick task 260825-wj2 Task 2) — a plain object keyed by
    // desktop-entry id, the SAME hoisted-lookup-map shape `counts` already
    // uses, for the identical reason: a per-comparison Prefs read would be
    // ~1,500 redundant fetches per keystroke for one unchanging array.
    // Ranks ahead of BOTH the existing alpha/frecency ordering (D-7's own
    // instruction) — a favourited app always sorts before a non-favourited
    // one, regardless of sort mode, and the existing tiebreaker only
    // decides ties WITHIN each favourite/non-favourite half.
    function _compareApps(a, b, counts, favSet) {
        if (favSet) {
            const favA = favSet[a.id] ? 1 : 0;
            const favB = favSet[b.id] ? 1 : 0;
            if (favA !== favB)
                return favB - favA;
        }
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

        // Hidden/favourite (quick task 260825-wj2 Task 2) — THIS is the
        // single point Apps page's two toggles reach the launcher (D-6's
        // own key_links instruction). Both arrays read ONCE per
        // re-evaluation into a lookup map, the same hoist-out-of-the-loop
        // discipline `counts` below already established, never per-app or
        // per-comparison.
        const hidden = Prefs.getValue("launcher.hiddenApps");
        const hiddenSet = {};
        for (let i = 0; i < hidden.length; i++)
            hiddenSet[hidden[i]] = true;
        const favourites = Prefs.getValue("launcher.favouriteApps");
        const favSet = {};
        for (let i = 0; i < favourites.length; i++)
            favSet[favourites[i]] = true;

        const all = DesktopEntries.applications.values.filter(function (e) {
            return !e.noDisplay && !hiddenSet[e.id];
        });
        const counts = launcherWindow.sortMode === launcherWindow.sortModeFrecency ? Prefs.getValue("launcher.launchCounts") : undefined;

        if (q === "") {
            return all.slice().sort(function (a, b) {
                return launcherWindow._compareApps(a, b, counts, favSet);
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
            return launcherWindow._compareApps(a.entry, b.entry, counts, favSet);
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

        // Hover-summon dismissal probe — on `panel`, not the window, which
        // spans the whole output. See Dashboard.qml's twin for why.
        HoverHandler {
            id: drawerHover
            onHoveredChanged: launcherWindow._onDrawerHoverChanged(drawerHover.hovered)
        }

        // Shared with the bottom strip's bulge so the two cannot drift
        // (operator round 7) — see Design.launcherPanelWidth.
        width: Design.launcherPanelWidth
        height: contentColumn.implicitHeight + contentColumn.anchors.margins * 2
        anchors.horizontalCenter: parent.horizontalCenter
        // Anchored to the edge it hangs from; the entrance is a
        // Translate off that anchor (see the slide note below), never a
        // `y` derived from the window height. `undefined` clears the
        // unused anchor — the standard QtQuick idiom for a branched
        // Item anchor.
        anchors.top: launcherWindow.edgeBarRailPresent ? undefined : parent.top
        anchors.bottom: launcherWindow.edgeBarRailPresent ? parent.bottom : undefined

        // ── Drop-down/rise entrance, in QML (quick task 260823-9ak,
        //    Task 6, D-5) ────────────────────────────────────────────
        // The LazyLoader creates this surface fresh on every summon
        // (D-14), so `Component.onCompleted` IS the open event; there is
        // no reopen case to reset. Direction branches on
        // `edgeBarRailPresent` (D-5, renamed by quick task 260824-ns3):
        // no rail is `opened ? 0 : -height` unchanged (today's exact
        // drop from the top); a rail present rises from the bottom
        // instead, flush against `launcherWindow.height` (the window's
        // own local
        // content height, already net of the flush margins above).
        property bool opened: false

        // ── Deferred arm+open (OPERATOR FEEDBACK ROUND 5, 2026-08-23) ────
        // The operator reported the panel "starts from the middle of the
        // screen then slides down" in edge-bar mode — the exact reverse of
        // the intended rise. Measured by diffing 30 frames against a
        // closed-state baseline: top ran 466 -> 750 -> 879 -> 957 -> 975,
        // i.e. it DESCENDED into place.
        //
        // Cause, and it is a construction-order bug, not a direction bug.
        // The closed position in edge-bar mode is `launcherWindow.height`,
        // which is 0 until the layer surface is configured; `panel.height`
        // is likewise 0 until `contentColumn` lays out. `Component.
        // onCompleted` fired with BOTH still 0, so open (`height - height`)
        // and closed (`height`) evaluated to the same 0 and there was
        // nothing to travel. The real geometry then arrived, the binding
        // re-evaluated to ~974, and the Behavior animated y from 0 to 974
        // — a slide DOWN from the top, which is precisely what was seen.
        //
        // Dashboard.qml never had this: its open position is the constant
        // 0 and never reads the window height, so its own zero-geometry
        // window is harmless. Only this file's bottom-anchored branch
        // depends on a value that starts at 0, which is why the operator
        // saw the dashboard behave and the launcher not.
        //
        // So opening waits for real geometry, and the Behaviors stay
        // ── Entrance slide (OPERATOR FEEDBACK ROUNDS 5-6, 2026-08-23) ───
        // The operator reported the panel "starts from the middle of the
        // screen then slides down" in edge-bar mode — the reverse of the
        // intended rise. Two wrong fixes preceded this one; what finally
        // settled it was console.log instrumentation read out of
        // ~/.cache/quickshell.log, not reasoning about the file:
        //
        //   winH=100   panelH=32   -> "ready", opened flipped here
        //   winH=500   panelH=444  -> y=7.2
        //   winH=1424  panelH=444  -> y 173 -> 298 -> 389 ... -> 927 ...
        //
        // `launcherWindow.height` is NEVER 0. The layer surface is
        // configured in STAGES — 100, then 500, then 1424 — so the old
        // open position `launcherWindow.height - height` tracked a value
        // that kept growing, and dragged the panel steadily DOWNWARD long
        // after it had opened. Any "wait for a non-zero height" guard
        // passes at winH=100 and cannot help; the first two attempts here
        // failed for exactly that reason. (Qt.callLater retry loops also
        // cannot help, and are worse: callLater COALESCES into the end of
        // the current event-loop iteration, so a self-rescheduling retry
        // spins inside ONE frame and never waits for a configure at all.)
        //
        // Dashboard.qml is immune because its open position is the
        // constant 0 and never reads the window height — which is why the
        // operator saw the drawer behave and only the launcher invert.
        //
        // THE RULE THIS ENCODES: never derive a layer-shell surface's
        // entrance geometry from that surface's own height. Anchor to the
        // edge and animate a TRANSLATION whose distance depends only on
        // the panel's own height. Staged configures then move the anchor,
        // which is free, instead of retargeting a running animation.
        property bool _armed: false

        // Debounced open: `panel.height` also arrives in stages (32 -> 72
        // -> 444), and flipping at the first non-zero value would slide
        // the panel a token 32px instead of its full height. Each height
        // change restarts the timer, so the slide starts once the size has
        // held still for one interval.
        function _armAndOpen() {
            if (panel.opened || panel.height <= 0)
                return;
            // Arm one tick BEFORE the flip so `Behavior.enabled` has
            // already re-evaluated true when `opened` changes; doing both
            // in one tick leaves that ordering to chance. While disarmed,
            // the closed offset tracks `panel.height` instantly rather
            // than animating, so the panel simply waits off-screen.
            panel._armed = true;
            Qt.callLater(function () {
                panel.opened = true;
            });
        }

        Timer {
            id: settleTimer
            interval: 60
            repeat: false
            onTriggered: panel._armAndOpen()
        }
        onHeightChanged: if (!panel.opened)
            settleTimer.restart()

        // Hard stop: never leave the panel invisible if the size never
        // settles. Routed through the same path so the arm/flip ordering
        // holds here too.
        Timer {
            interval: 500
            running: !panel.opened
            repeat: false
            onTriggered: panel._armAndOpen()
        }

        opacity: opened ? 1 : 0
        Component.onCompleted: settleTimer.restart()

        // The slide itself. `Translate` is relative to wherever the anchors
        // put the panel, so a staged surface configure repositions the
        // anchor without touching this animation.
        transform: Translate {
            id: panelSlide
            y: panel.opened ? 0 : (launcherWindow.edgeBarRailPresent ? panel.height : -panel.height)

            // Spatial (position) motion — rides the spatial-in pair on the
            // way in and its REVERSAL on the way out, matching
            // Dashboard.qml's own Behavior verbatim.
            //
            // OPERATOR ROUND 9 (quick task 260823-9ak): the dismiss branch
            // read `spatialOut` — 150ms on a plain accelerate against this
            // panel's 450ms decelerate-with-overshoot entrance, so it left
            // three times faster than it arrived and on a different curve
            // family. `spatialReverse*` is the entrance easing
            // point-reflected through (0.5, 0.5): the same shape played
            // backwards. See Motion.qml's own note for why it is derived
            // from the in-token rather than authored.
            //
            // Note this reads correctly in BOTH directions without further
            // branching: the closed offset below is already `+panel.height`
            // when the edge bar is on and `-panel.height` when it is off,
            // so the reversed curve simply retraces whichever path the
            // entrance took. The entrance overshoot surfaces as a brief
            // inward recoil at the START of the dismiss — that is the
            // reversal, not a defect.
            Behavior on y {
                enabled: Motion.motionEnabled && panel._armed
                NumberAnimation {
                    duration: Motion.spatialInDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: launcherWindow._dismissing ? Motion.spatialInReverseEasing : Motion.spatialInEasing
                }
            }
        }

        Behavior on opacity {
            enabled: Motion.motionEnabled && panel._armed
            NumberAnimation {
                duration: Motion.emphasizedInDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: launcherWindow._dismissing ? Motion.emphasizedInReverseEasing : Motion.emphasizedInEasing
            }
        }

        Rectangle {
            id: background
            anchors.fill: parent
            // Per D-5 (quick task 260823-9ak, Task 6), extended to a
            // three-state shape by quick task 260824-ns3 Task 1
            // (Q3-brackets): the TOP pair follows DIRECTION
            // (edgeBarRailPresent) — round the end the panel rises from,
            // square the top when it drops from the top instead — and the
            // BOTTOM pair follows ATTACHMENT (edgeBarPanelsAttach) — square
            // only when the panel is genuinely welded to the rail it rose
            // from. A rail present but unattached (Brackets) therefore
            // gets top=round (railPresent) AND bottom=round (not attached)
            // — round on all four corners, a floating panel — while
            // leaving both the no-rail (off) and rail+attached (Continuous
            // etc.) cases at their original byte-identical values.
            topLeftRadius: launcherWindow.edgeBarRailPresent ? launcherWindow.cornerRadius : 0
            topRightRadius: launcherWindow.edgeBarRailPresent ? launcherWindow.cornerRadius : 0
            bottomLeftRadius: launcherWindow.edgeBarPanelsAttach ? 0 : launcherWindow.cornerRadius
            bottomRightRadius: launcherWindow.edgeBarPanelsAttach ? 0 : launcherWindow.cornerRadius
            color: Qt.rgba(launcherWindow.surfaceBase.r, launcherWindow.surfaceBase.g, launcherWindow.surfaceBase.b, launcherWindow.drawerSurfaceOpacity)
        }

        // DASH-10's animated gradient rim, reused verbatim — matches
        // Hyprland's own window border so the drawer reads as part of the
        // same desktop rather than as a foreign panel. Radii are handed
        // across from the same properties `background` uses, mirroring
        // Dashboard.qml:672-680.
        // ── Attached-edge border clip (OPERATOR FEEDBACK ROUND 3,
        //    2026-08-23) ───────────────────────────────────────────────
        // The operator reported "the concave flares exist alongside the
        // old geometry", and a region capture of this panel's own bottom-
        // left corner showed exactly that: TWO parallel rim lines, the
        // flare's arc curving out to the strip and the panel's own side
        // border still running straight down past it to a hard 90 degree
        // junction, with the flare's solid fill sandwiched between them.
        //
        // The flare geometry was never wrong. AttachedCorner deliberately
        // omits a rim on its panel-touching run (see its header) so it
        // does not double-stroke the shared seam — but once a flare is
        // attached, that seam stops being an OUTER edge at all. The last
        // `flareRadius` of each side, and the whole attached edge, become
        // INTERIOR to the merged panel+flare silhouette, and an interior
        // line is precisely what a window border must not draw.
        //
        // So the ring is clipped rather than redrawn: GradientBorder keeps
        // the panel's full geometry (its corner radii must still land in
        // the panel's own corners), and this wrapper hides the attached
        // edge plus the adjacent `attachedCornerRadius` of both sides.
        // What survives ends exactly where the flare's arc leaves the
        // panel edge — AttachedCorner's arc endpoint on the touching run
        // is `flareRadius` from the attached edge, the same inset clipped
        // here — so the two read as one continuous line.
        //
        // Clipping rather than teaching GradientBorder an "open edge"
        // mode: that component has 13 consumers, and an open-ring path
        // built from two nested closed subpaths under OddEvenFill is a
        // real rewrite of its `_ringPath`. This costs one Item.
        // Third state (quick task 260824-ns3, Q3-brackets): "no rim
        // clipping" for a rail present but unattached (Brackets) panel —
        // topMargin already reads 0 whenever a rail is present (matching
        // the welded case, since the panel never attaches at the TOP in
        // either rail-present state) and bottomMargin reads 0 whenever
        // panels do not attach, so both land at 0 together for Brackets:
        // the clip rect equals the panel's own full bounds, i.e. no
        // effective clipping — the full ring is drawn, exactly as the
        // brief asks.
        Item {
            id: launcherBorderClip
            anchors.fill: parent
            anchors.topMargin: launcherWindow.edgeBarRailPresent ? 0 : Design.attachedCornerRadius
            anchors.bottomMargin: launcherWindow.edgeBarPanelsAttach ? Design.attachedCornerRadius : 0
            clip: true

            GradientBorder {
                id: launcherGradientBorder
                x: 0
                // Mirrors `anchors.topMargin` above (not `edgeBarPanelsAttach`
                // alone) so the rim offset stays correct for the no-rail
                // (off) case, which is the only one where this needs to be
                // nonzero — both rail-present states (welded or not) sit at 0.
                y: launcherWindow.edgeBarRailPresent ? 0 : -Design.attachedCornerRadius
                width: panel.width
                height: panel.height
                borderWidth: Design.borderWidth
                // Mirrors `background`'s own radii (comment above them):
                // top pair follows direction, bottom pair follows
                // attachment — see that Rectangle's comment for the full
                // three-state derivation.
                topLeftRadius: launcherWindow.edgeBarRailPresent ? launcherWindow.cornerRadius : 0
                topRightRadius: launcherWindow.edgeBarRailPresent ? launcherWindow.cornerRadius : 0
                bottomLeftRadius: launcherWindow.edgeBarPanelsAttach ? 0 : launcherWindow.cornerRadius
                bottomRightRadius: launcherWindow.edgeBarPanelsAttach ? 0 : launcherWindow.cornerRadius
            }
        }

        // ── Attached corners (quick task 260823-9ak, Task 1+6, R7/P-1/D-5) ─
        // Two concave flares joining the panel's own top corners (no rail)
        // or bottom corners (rail welded) to the screen edge the panel
        // hangs from — siblings of `background`, painting OUTSIDE the
        // panel's own bounds (`panel` carries no `clip` here, unlike
        // Dashboard.qml's own panel — see that file's own Task 2 note).
        // Per D-5, only the EDGE branches (`edge` ternary + the `y`
        // positioning below, which replaces a fixed `anchors.top: panel.top`
        // so either panel edge can be targeted) — the corner SHAPE itself
        // (AttachedCorner's own geometry) is never branched; it is present
        // and identically shaped whenever visible. `angle` reads
        // `startAngle + angle` off the SAME GradientBorder instance above,
        // so the rim's gradient sweep never drifts out of phase with the
        // panel's own rim.
        //
        // `visible` is the third state's own addition (quick task
        // 260824-ns3, Q3-brackets): "no flare" for a rail present but
        // unattached (Brackets) panel. True whenever the panel is NOT in
        // that specific floating state — i.e. true for both the no-rail
        // (off, welds to the plain top screen edge, unchanged) and
        // rail+attached (welds to the rail) cases, false only when a rail
        // is present without attachment.
        AttachedCorner {
            id: launcherFlareLeft
            visible: !launcherWindow.edgeBarRailPresent || launcherWindow.edgeBarPanelsAttach
            edge: launcherWindow.edgeBarPanelsAttach ? "bottom" : "top"
            side: "left"
            flareRadius: Design.attachedCornerRadius
            anchors.right: panel.left
            y: launcherWindow.edgeBarPanelsAttach ? panel.height - flareRadius : 0
            fillColour: Qt.rgba(launcherWindow.surfaceBase.r, launcherWindow.surfaceBase.g, launcherWindow.surfaceBase.b, launcherWindow.drawerSurfaceOpacity)
            borderWidth: Design.borderWidth
            angle: launcherGradientBorder.startAngle + launcherGradientBorder.angle
            gradientCentre: Qt.point(panel.width / 2 - launcherFlareLeft.x, panel.height / 2 - launcherFlareLeft.y)
            gradientHalfDiagonal: Math.sqrt(panel.width * panel.width + panel.height * panel.height) / 2
        }
        AttachedCorner {
            id: launcherFlareRight
            visible: !launcherWindow.edgeBarRailPresent || launcherWindow.edgeBarPanelsAttach
            edge: launcherWindow.edgeBarPanelsAttach ? "bottom" : "top"
            side: "right"
            flareRadius: Design.attachedCornerRadius
            anchors.left: panel.right
            y: launcherWindow.edgeBarPanelsAttach ? panel.height - flareRadius : 0
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
                    // Mode-aware: a sticky mode filters ITSELF, so promising
                    // "apps" while the panel shows a wallpaper strip is a lie
                    // about what typing will do.
                    placeholderText: LauncherState.mode === "wallpaper" ? "Search wallpapers…" : "Search apps…"
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

                    // ── Route prefix painted as a command (quick task
                    //    260828-75k, operator round 3) ──────────────────
                    // An overlay Text drawn over the field's own first
                    // glyphs, not a contentItem replacement: this tree
                    // already records that anchoring a QQC2 Control's
                    // contentItem shrinks its background below its content,
                    // and the field's sizing is not worth risking for a
                    // colour.
                    //
                    // It aligns because it is the SAME string, font and
                    // origin: the shell's family is FiraCode Nerd Font
                    // (monospace) and the position is read from the field's
                    // own leftPadding/topPadding rather than assumed. Only
                    // the prefix span is drawn, so the rest of the query is
                    // the field's own untouched rendering.
                    Text {
                        id: routeToken
                        x: searchField.leftPadding
                        y: searchField.topPadding
                        width: searchField.width - searchField.leftPadding - searchField.rightPadding
                        height: searchField.height - searchField.topPadding - searchField.bottomPadding
                        verticalAlignment: Text.AlignVCenter
                        visible: text.length > 0
                        // A resolved route paints its whole prefix; a
                        // partial one ("p", "pk") paints what has been typed
                        // so far, so the feedback starts on keystroke one.
                        text: LauncherState.routePrefix.length > 0 ? LauncherState.routePrefix : (LauncherState.routePartial ? LauncherState.query : "")
                        font: searchField.font
                        color: LauncherState.routePrefix.length > 0 ? Colours.primary : Colours.tertiary
                        textFormat: Text.PlainText

                        Behavior on color {
                            enabled: Motion.motionEnabled
                            ColorAnimation {
                                duration: Motion.colourDuration
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Motion.colourEasing
                            }
                        }
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
                                duration: Motion.colourDuration
                                easing.type: Easing.BezierSpline
                                easing.bezierCurve: Motion.colourEasing
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
                    case LauncherState.modePkg:
                        return pkgComponent;
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
                    // "wallpaper" (quick task 260826-wl3) — same
                    // literal-mode precedent as "updates"/"systeminfo"
                    // below: reachable only via `qs ipc call launcher open
                    // wallpaper` (which Super+W and Style > Wallpaper both
                    // go through) and never via a typed route prefix, so it
                    // stays out of LauncherState's prefix table too.
                    case "wallpaper":
                        return wallpaperComponent;
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

            // `pkg` packages (quick task 260828-75k). Activating a row opens
            // the workbench on that package rather than installing or
            // removing it — a launcher row is a lookup, and a transaction
            // started from a fuzzy match on a half-typed name is exactly
            // the accident this shell should not make easy.
            Component {
                id: pkgComponent

                PkgMode {
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
            // ── Style > Wallpaper (quick task 260826-wl3) — the
            //    horizontal carousel with live preview. `dismissCallback`
            //    is resolved in THIS document's scope, where
            //    `launcherWindow` is visible, then handed over as a plain
            //    function-valued property, exactly as menuComponent does.
            //    `query` is bound so the search field filters the strip.
            Component {
                id: wallpaperComponent

                WallpaperMode {
                    dismissCallback: launcherWindow._beginDismiss
                    query: LauncherState.query
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
                        },
                        {
                            prefix: "pkg ",
                            label: "Packages"
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
        // Operator round 12 — construction IS the open event (the surface
        // is built fresh on every summon), so the summon's provenance is
        // captured here and the abandoned-peek timer starts.
        launcherWindow._hoverArmEligible = launcherWindow.hoverSummoned;
        if (launcherWindow._hoverArmEligible)
            hoverIdleTimer.start();
    }
}
