// NotifServer.qml — the shell's own org.freedesktop.Notifications owner
// (Phase 19 Plan 01 tracer, QNOTIF-01, T-19-02; extended Plan 19-04 for
// gestures/replaces_id, extended Plan 19-05 for history persistence,
// do-not-disturb ownership and the suppression predicate — QNOTIF-07/09).
//
// pragma Singleton (below) + qmldir's `singleton` keyword are BOTH
// required for bare `NotifServer.propertyName`-style access to resolve at
// all — the same binary-verified finding Colours.qml/Motion.qml/Design.qml
// each restate in their own header (12-06). Both are present here.
//
// ── Capability declaration (D-19-38) ─────────────────────────────────────
// Declares exactly the wire-capability set D-19-38 locks: `body`,
// `body-markup`, `body-hyperlinks`, `actions`, `icon-static`,
// `persistence`. `action-icons`, `inline-reply` and `sound` are
// deliberately left at their `false` default — a false capability claim is
// how senders get silently misrendered, and D-19-38's own text is
// "declare only what is actually implemented." `body` and `actions` are
// the two load-bearing flags for blueman's bluetooth-pairing prompt
// (D-19-39) — neither may ever be dropped; see this plan's
// <reversibility> record on Task 2 and register row T-19-02.
//
// `keepOnReload: true` so a QML hot reload during ordinary theming work
// does not drop in-flight notifications — this shell reloads far more
// often than either reference shell's own deployment (RESEARCH.md
// Pitfall 2's framing, applied here to the server itself rather than only
// to persistence).
//
// ── Public surface (RESEARCH.md § Recommended Project Structure) ────────
// `popups` (the in-flight list), `history`, `dnd`, `unreadCount`, and the
// verbs `dismiss(id)`, `clearAll()`, `openCentre()`, `toggleDnd()` — all
// implemented for real as of this plan. `centreOpen`/`fullscreenBlocking`
// are two more inputs to the suppression predicate below, both plain
// externally-writable properties rather than verbs: `fullscreenBlocking`
// is set by shell.qml's own single fullscreen-focus owner via a `Binding`
// (RESEARCH.md Pattern 6 — reused verbatim, never recomputed here), and
// `centreOpen` is left for Plan 19-06's own centre surface to bind off its
// window lifecycle, mirroring the `panelOpen`/`drawerOpen` precedent
// (AudioBackend.panelOpen, MediaBackend.drawerOpen) rather than a second
// verb pair here.
pragma Singleton
import QtQml
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import "../dashboard"

Singleton {
    id: root

    // ── In-flight popup list — a plain JS array of NotifData wrappers,
    //    reassigned (never mutated in place) so QML's list<QtObject>
    //    change notification fires on every add/remove. New arrivals
    //    prepend, so the ListView they back renders the newest card at
    //    the top of the stack (D-19-01's placement, D-19-02's ordering). ─
    property var popups: []

    // ── History (D-19-24/25/26/27/30) — a plain JS array of history-shape
    //    objects (id/appName/summary/body/appIcon/image/urgency/timestamp),
    //    NOT NotifData QtObject wrappers: a suppressed notification is
    //    recorded here directly from the D-Bus arrival (see onNotification
    //    below) with no popup wrapper ever created for it, so history's
    //    own item shape has to stand on its own regardless of whether a
    //    popup ever existed. Newest-first, same ordering convention as
    //    `popups`. Capped at Design.notifHistoryCap, oldest dropped.
    property var history: []

    // ── Do-not-disturb (D-19-36, QNOTIF-09) — persisted to disk through
    //    the SAME file-backed mechanism as `history` below, never the
    //    toolkit's own hot-reload-scoped persistence type (RESEARCH.md
    //    Pitfall 2 — that type's prototype chain ties it to a QML
    //    hot-reload event, not to disk, so it would look like it works
    //    during development and silently reset the first time the
    //    restart wrapper respawns the process).
    property bool dnd: false

    readonly property int unreadCount: root.popups.length

    // ── The other three suppression inputs (D-19-33..35, QNOTIF-10) ─────
    // `gaming` — read independently off the SAME on-disk truth file
    // ToggleState.qml's gaming tile also reads (~/.cache/gaming-mode).
    // This is a duplicate READ of one fact, not a second source of truth
    // for it: nothing here ever writes this file, and D-19-35's own
    // independence requirement ("gaming mode must not reach in and flip
    // the DND tile's visible state") is about DND's OWN value, which nothing
    // below ever touches from this branch.
    FileView {
        id: gamingFile
        path: Quickshell.env("HOME") + "/.cache/gaming-mode"
        watchChanges: true
        onFileChanged: reload()
    }
    readonly property string _gamingRaw: (gamingFile.text() || "").trim()
    readonly property bool gaming: (root._gamingRaw.length > 0 ? root._gamingRaw : "off") === "on"

    // `centreOpen` — Plan 19-06's own centre surface binds this off its
    // window's lifecycle once it exists; an honest, reachable, currently-
    // unbound input until then (no summon path calls openCentre() yet).
    property bool centreOpen: false

    // `fullscreenBlocking` — set ONLY by shell.qml's `Binding` onto this
    // property, mirroring its own single fullscreen-focus-owner value
    // (RESEARCH.md Pattern 6). This file deliberately reads no compositor
    // state of its own — there is already exactly one owner of that fact
    // in shell.qml, and a second reader recomputing it independently would
    // drift the first time the compositor's own event names change.
    property bool fullscreenBlocking: false

    // ── The suppression predicate (D-19-33, QNOTIF-10) — a single derived
    //    read-only property OR-ing the four independent inputs above.
    //    Suppression means never shown as a popup, but always recorded in
    //    history (enforced in onNotification below, never here). ─────────
    readonly property bool suppressed: root.dnd || root.gaming || root.centreOpen || root.fullscreenBlocking

    // ── Do-not-disturb toast copy (D-19-36, 19-UI-SPEC.md's Copywriting
    //    Contract, verbatim) — declared here rather than inside the toast
    //    frame itself, so `Toast.qml` (Plan 19-05 Task 3) stays a generic
    //    chrome-only frame with zero DND-specific strings; the frame's own
    //    header records why. Emitted through `dndToggled` below rather
    //    than read directly, so a future caller never needs to know these
    //    property names exist. ─────────────────────────────────────────
    readonly property string dndOnHeading: "Do not disturb enabled"
    readonly property string dndOnBody: "Popup notifications are now disabled"
    readonly property string dndOffHeading: "Do not disturb disabled"
    readonly property string dndOffBody: "Popup notifications are now enabled"

    // Fired ONLY from toggleDnd() below — never from the state file's own
    // initial load — so a toast never fires on shell startup, only on a
    // genuine user-driven toggle (from the tile OR a future keyboard
    // shortcut, per D-19-36's own "especially when driven from Super+N"
    // framing).
    signal dndToggled(bool newValue, string heading, string body)

    // ── dismiss(id) — removes the matching wrapper from `popups` (never
    //    mutates the array in place). Called by NotifCard.qml's own D-19-04
    //    auto-dismiss timer AND every gesture path (drag, middle-click,
    //    click-with-no-single-action) — one code path, so "no gesture
    //    destroys data" (this plan's own must_haves) is a property of
    //    THIS function rather than something every caller re-proves.
    //
    //    CORRECTED this plan (Plan 19-05): Plan 19-04's own version of this
    //    function pushed the dismissed wrapper into `history` here — correct
    //    while nothing recorded history any earlier, but this plan's own
    //    onNotification handler below now records EVERY arrival into
    //    history unconditionally, before suppression is even decided. A
    //    second push here would double-record every dismissed notification
    //    and, worse, a genuinely suppressed notification (never popped, so
    //    never dismissed) would have gone unrecorded entirely under the old
    //    scheme — exactly the "silently destroyed" case D-19-33 forbids.
    //    "No gesture destroys data" now holds for a STRONGER reason: the
    //    record exists before any gesture is even possible. ───────────────
    function dismiss(id) {
        var idx = -1;
        for (var i = 0; i < root.popups.length; i++) {
            if (root.popups[i].notifId === id) {
                idx = i;
                break;
            }
        }
        if (idx === -1)
            return;
        var wrapper = root.popups[idx];
        var next = root.popups.slice();
        next.splice(idx, 1);
        root.popups = next;
        wrapper.popup = false;
    }

    // ── clearAll() — D-19-28/29's batched clear, implemented for real.
    //    Removes Design.notifHistoryBatchSize items per timer tick rather
    //    than one synchronous splice, so a full history clear never blocks
    //    the UI thread — Caelestia's own per-app-group batching shape,
    //    applied here to the whole-history clear path (per-app-group
    //    clearing is Plan 19-06's own centre-UI concern).
    //
    //    GATE-02 gap-closure fix (round 5 — ROOT CAUSE of "clear-all does
    //    nothing"). `interval: 0` never actually fired `onTriggered` on
    //    this Quickshell/Qt build — live-confirmed with a temporary
    //    probe (since removed): `Timer.start()` correctly flipped
    //    `running` to `true` (proven via the probe's own before/after
    //    log), yet `onTriggered` never logged a single tick across
    //    repeated real invocations, driven directly through a temporary
    //    IPC verb (no click needed) with up to several seconds' wait —
    //    `historyLen` stayed pinned at 100 the entire time. The click/UI
    //    layer (MouseArea -> signal -> clearAll()) was already proven
    //    working in round 5's own click-chain probes; this Timer was the
    //    actual dead end, silently swallowing every batch tick.
    //    `interval: 1` is still imperceptible (the whole history drains
    //    in a handful of 1ms ticks) and is the minimal change that makes
    //    the timer's own repeating trigger fire at all on this build —
    //    confirmed live: `historyCount` IPC verb went 100 -> 0 after
    //    `clearAll()`, and stayed 0 after a full `systemctl --user
    //    restart quickshell.service` (both in-memory and in the
    //    persisted `notifications.json`). ─────────────────────────────
    Timer {
        id: _clearAllBatchTimer
        interval: 1
        repeat: true
        onTriggered: {
            if (root.history.length === 0) {
                _clearAllBatchTimer.stop();
                root._writeState();
                return;
            }
            root.history = root.history.slice(0, Math.max(0, root.history.length - Design.notifHistoryBatchSize));
        }
    }
    function clearAll() {
        if (root.history.length === 0)
            return;
        _clearAllBatchTimer.start();
    }

    function openCentre() {
        // Plan 19-06 builds the centre's own PanelWindow/summon mechanism
        // and binds `centreOpen` off its own lifecycle (the panelOpen/
        // drawerOpen precedent, not a second verb here). This verb wires
        // only the suppression-clearing half D-19-37 requires, so a future
        // summon path calling it inherits the correct behaviour for free.
        root.centreOpen = true;
        root.popups = [];
    }

    // ── toggleDnd() (D-19-36/37, QNOTIF-09) — flips `dnd`, persists it,
    //    fires the toast signal with the exact copy strings, and — only
    //    when turning ON — clears the in-flight popup stack (D-19-37's own
    //    "flipping DND on" wording; turning it off does not, per this
    //    plan's own <behavior>). T-19-18's backstop: the write is attempted
    //    optimistically but reverted (see stateFile.onSaveFailed below) if
    //    it fails, so a failed write is visually silent rather than
    //    showing a state the system is not actually in. ──────────────────
    property bool _dndTogglePending: false
    property bool _dndPrevValue: false

    function toggleDnd() {
        var prev = root.dnd;
        var next = !prev;
        root._dndPrevValue = prev;
        root._dndTogglePending = true;
        root.dnd = next;
        root._writeState();
        if (next) {
            root.dndToggled(true, root.dndOnHeading, root.dndOnBody);
            root.popups = [];
        } else {
            root.dndToggled(false, root.dndOffHeading, root.dndOffBody);
        }
    }

    // Factory for the per-notification wrapper — createObject() rather
    // than a static child, since one wrapper is created per D-Bus arrival.
    Component {
        id: notifDataComponent

        NotifData {}
    }

    // ── History record — unconditional, on the path BEFORE the
    //    suppression branch inside onNotification below (never after it).
    //    Plain JS object, not a NotifData wrapper: a suppressed
    //    notification never gets a popup wrapper at all, so history's own
    //    shape has to stand alone. Capped at Design.notifHistoryCap,
    //    dropping the oldest (the array is newest-first by construction —
    //    every insert prepends — so "drop oldest" is "trim the tail"). ───
    function _recordHistory(notif) {
        var entry = {
            id: notif.id,
            appName: notif.appName,
            summary: notif.summary,
            body: notif.body,
            appIcon: notif.appIcon,
            image: notif.image,
            // desktopEntry (Phase 19 Plan 06 addition) — the third tier of
            // the icon fallback chain the centre's NotifGroup.qml reuses
            // verbatim from NotifCard.qml (image hint -> app_icon via icon
            // theme -> desktop-entry icon -> generic glyph). Plain string,
            // serializes cleanly.
            desktopEntry: notif.desktopEntry,
            urgency: notif.urgency,
            timestamp: Date.now()
        };
        var next = [entry].concat(root.history);
        if (next.length > Design.notifHistoryCap)
            next = next.slice(0, Design.notifHistoryCap);
        root.history = next;
        root._writeState();
    }

    // ── Per-session action retention (Phase 19 Plan 06 addition,
    //    D-19-31/QNOTIF-04; gap-closure fix, GATE-02 crash) ───────────────
    // GATE-02 finding: the ORIGINAL version of this block stored the raw
    // live `QList<NotificationAction*>` (`notif.actions` itself) into
    // `_sessionActionsById`, and `NotifGroup.qml` bound THAT value straight
    // into a `Repeater.model`. That Repeater's delegate is created lazily,
    // often long after the notification arrived and asynchronously via
    // Quickshell's own incubation controller — by the time it actually
    // ran, `QQmlDelegateModel`'s attempt to convert the stored value
    // SIGSEGV'd inside `QMetaType::convert` (coredump pid 569912, 2026-08-13
    // 16:15:54; nested `QQuickRepeater::regenerate`/`componentComplete`
    // frames matching this exact group-row -> action-chip Repeater
    // nesting). Root cause: a raw QObject-pointer list is not a value safe
    // to hold in a `property var` across an unbounded time gap and then
    // hand to delegate-model machinery — `NotifCard.qml`'s own identical-
    // LOOKING `Repeater { model: card._liveActions }` is safe only because
    // that card's delegate is destroyed in lockstep with the SAME
    // notification's own live popup lifecycle, never outliving it; this
    // map is deliberately session-LONG-lived, which is exactly the
    // condition that makes the raw reference unsafe.
    //
    // Fix: `_sessionActionsById` now stores a PLAIN, serializable snapshot
    // (`[{identifier, text}, ...]`, captured synchronously and safely at
    // arrival, when the objects are certainly live) — this is the ONLY
    // value `NotifGroup.qml`'s Repeater ever sees, so no raw QObject
    // reference ever reaches delegate-model conversion. The raw list is
    // still needed to actually INVOKE an action, so it lives separately in
    // `_sessionRawActionsById` and is touched ONLY inside
    // `invokeSessionAction()` below — a plain imperative function call
    // from a TapHandler at the instant of a real click, never a reactive
    // binding and never a model. Neither map is written to
    // `notifications.json`; an id's absence from `_sessionActionsById`
    // after a restart is still the entire D-19-31 "sender's session is
    // gone" signal.
    property var _sessionActionsById: ({})
    property var _sessionRawActionsById: ({})

    function hasSessionActions(id) {
        return root._sessionActionsById.hasOwnProperty(String(id));
    }
    function actionsForHistoryId(id) {
        var key = String(id);
        return root._sessionActionsById.hasOwnProperty(key) ? root._sessionActionsById[key] : [];
    }
    // Called only from a TapHandler's onTapped — an imperative call at
    // click time, never bound into any property or model. If the
    // underlying action object is by then stale, this fails silently
    // (matching the rest of this file's own no-throw discipline) rather
    // than propagating into anything QML's delegate machinery touches.
    function invokeSessionAction(id, identifier) {
        var key = String(id);
        var raw = root._sessionRawActionsById.hasOwnProperty(key) ? root._sessionRawActionsById[key] : [];
        for (var i = 0; i < raw.length; i++) {
            if (raw[i] && raw[i].identifier === identifier) {
                raw[i].invoke();
                return;
            }
        }
    }

    // ── Per-notification and per-app-group history clears (Phase 19 Plan
    //    06 addition, D-19-29/QNOTIF-06) — `clearAll()` above already
    //    covers the third level. Rule 2 deviation: the centre cannot
    //    implement two of D-19-29's three required clear levels without
    //    either these two verbs or writing `root.history` directly from
    //    outside this file (which would skip `_writeState()` and silently
    //    break D-19-24's persistence guarantee for exactly those two
    //    paths). Per-notification clearing needs no batching (the plan's
    //    own text — one item, one filter); per-app-group clearing DOES
    //    batch, mirroring `clearAll()`'s own Timer shape, so a single
    //    app's very large history cannot stall the UI thread either. ─────
    function clearOne(id) {
        var next = root.history.filter(function (item) {
            return item.id !== id;
        });
        if (next.length === root.history.length)
            return;
        root.history = next;
        root._writeState();
    }

    property string _clearGroupTarget: ""
    // GATE-02 gap-closure fix (round 5) — same root cause and same fix
    // as `_clearAllBatchTimer` above: `interval: 0` never fired on this
    // build, which left `_clearGroupTarget` permanently set after the
    // first call (the timer that resets it back to "" on completion
    // never ran), silently no-opping every subsequent clearGroup() call
    // for ANY app via the early-return guard below. Live-confirmed with
    // the same seed-two-groups/clear-one-verify-the-other test as
    // `clearAll()`'s own note above, including surviving a real
    // `systemctl --user restart` afterward.
    Timer {
        id: _clearGroupBatchTimer
        interval: 1
        repeat: true
        onTriggered: {
            var stillPresent = root.history.some(function (item) {
                return item.appName === root._clearGroupTarget;
            });
            if (!stillPresent) {
                _clearGroupBatchTimer.stop();
                root._clearGroupTarget = "";
                root._writeState();
                return;
            }
            var toRemove = Design.notifHistoryBatchSize;
            var next = [];
            for (var i = 0; i < root.history.length; i++) {
                var item = root.history[i];
                if (item.appName === root._clearGroupTarget && toRemove > 0) {
                    toRemove--;
                    continue;
                }
                next.push(item);
            }
            root.history = next;
        }
    }
    function clearGroup(appName) {
        if (root._clearGroupTarget !== "")
            return;
        var hasAny = root.history.some(function (item) {
            return item.appName === appName;
        });
        if (!hasAny)
            return;
        root._clearGroupTarget = appName;
        _clearGroupBatchTimer.start();
    }

    NotificationServer {
        id: server

        keepOnReload: true

        // ── D-19-38's declared set — see this file's own header table for
        //    the mapping from wire capability to QML property. ───────────
        bodySupported: true
        bodyMarkupSupported: true
        bodyHyperlinksSupported: true
        actionsSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: notif => {
            // MUST set tracked=true or Quickshell may not retain the
            // object past this handler returning (RESEARCH.md Pattern 1).
            notif.tracked = true;

            // Phase 19 Plan 06 addition (D-19-31; gap-closure fix, GATE-02
            // crash — see _sessionActionsById's own header for the full
            // root cause) — captured for EVERY arrival, suppressed or not,
            // so a suppressed notification's eventual centre row can still
            // show working action buttons; never persisted. The RAW list
            // goes only into `_sessionRawActionsById` (touched solely by
            // invokeSessionAction(), never bound to anything); the PLAIN
            // snapshot that actually reaches a Repeater's model is built
            // here, synchronously, while `notif.actions`' own objects are
            // certainly still live. Recorded BEFORE _recordHistory() below:
            // that call reassigns `history`, which is what a centre row's
            // own bindings actually react to, and both maps must already
            // carry this entry by the time a fresh row for it is
            // instantiated.
            var _rawActions = notif.actions || [];
            var _plainActions = [];
            for (var _ai = 0; _ai < _rawActions.length; _ai++) {
                _plainActions.push({
                    identifier: _rawActions[_ai].identifier,
                    text: _rawActions[_ai].text
                });
            }
            root._sessionRawActionsById[String(notif.id)] = _rawActions;
            root._sessionActionsById[String(notif.id)] = _plainActions;

            // D-19-33 — unconditional history record BEFORE the
            // suppression branch: with no soak window and no rollback, a
            // silently destroyed notification leaves no trace at all, so
            // the record has to happen first.
            root._recordHistory(notif);

            if (root.suppressed) {
                // Suppressed: no popup wrapper is ever created — the
                // history record above is already this notification's
                // only visible trace, by design.
                return;
            }

            var wrapper = notifDataComponent.createObject(root, { notification: notif });
            root.popups = [wrapper].concat(root.popups);
        }
    }

    // ── Persistence (D-19-24/25, QNOTIF-09) — one JSON object, one file,
    //    `~/.local/state/quickshell/notifications.json` (XDG state,
    //    deliberately not cache — a cache cleaner would wipe it — and
    //    deliberately not the stow tree, the exact class of mistake Plan
    //    19-03 is in this same phase to undo). Shape: `{ history, dnd }` —
    //    both persisted through the SAME file-backed mechanism, per this
    //    plan's own instruction. `atomicWrites` mirrors WeatherBackend.qml's
    //    own cache-write idiom (T-14-26's write-tearing mitigation). ─────
    property bool _stateLoaded: false

    FileView {
        id: stateFile
        path: Quickshell.env("HOME") + "/.local/state/quickshell/notifications.json"
        watchChanges: false
        atomicWrites: true
        printErrors: true
        onLoaded: root._loadState()
        onLoadFailed: (error) => {
            // Never-persisted / first run is the expected state, not an
            // error (WeatherBackend.qml's own cache-miss framing) —
            // `history` stays `[]` and `dnd` stays `false`.
            root._stateLoaded = true;
        }
        onSaveFailed: (error) => {
            console.log("NotifServer: state write failed: " + error);
            // T-19-18 backstop — a failed write must not leave `dnd`
            // showing a value that was never actually committed to disk.
            if (root._dndTogglePending) {
                root.dnd = root._dndPrevValue;
            }
            root._dndTogglePending = false;
        }
    }

    Component.onCompleted: stateFile.reload()

    // T-19-17 (malformed/hostile state file degrades to empty rather than
    // crashing the shell) — every parse sits inside try/catch behind an
    // explicit shape check, matching Colours.qml/WeatherBackend.qml's own
    // discipline.
    function _loadState() {
        root._stateLoaded = true;
        try {
            var raw = stateFile.text();
            if (!raw || raw.trim().length === 0)
                return;
            var obj = JSON.parse(raw);
            if (Array.isArray(obj)) {
                // A bare array is also a valid history-only shape —
                // tolerated rather than rejected.
                root.history = obj;
            } else if (obj && typeof obj === "object") {
                if (Array.isArray(obj.history))
                    root.history = obj.history;
                if (typeof obj.dnd === "boolean")
                    root.dnd = obj.dnd;
            }
        } catch (e) {
            console.log("NotifServer: state parse failed, starting empty: " + e);
        }
    }

    function _writeState() {
        if (!root._stateLoaded)
            return;
        // `_dndTogglePending` is deliberately NOT cleared here: FileView
        // carries no explicit "save succeeded" signal, only `onSaveFailed`
        // above, so clearing it before that handler has had a chance to
        // fire (if it is going to) would defeat the T-19-18 revert this
        // flag exists for. It is cleared only by `onSaveFailed` itself —
        // a backstop-level implementation (this plan's own
        // must_haves.truths marks this verification "backstop"): a stale
        // `true` left behind by an already-succeeded DND write could, in
        // the narrow window before any later write, cause an unrelated
        // failed write to incorrectly revert `dnd` — accepted rather than
        // engineered around, since Quickshell's `FileView` exposes no
        // per-write completion token to key a precise revert on.
        stateFile.setText(JSON.stringify({ history: root.history, dnd: root.dnd }));
    }
}
