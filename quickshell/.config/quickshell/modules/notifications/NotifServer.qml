// NotifServer.qml — the shell's own org.freedesktop.Notifications owner
// (Phase 19 Plan 01 tracer, QNOTIF-01, T-19-02).
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
// verbs `dismiss(id)`, `clearAll()`, `openCentre()`, `toggleDnd()`. This
// plan implements `popups`, `unreadCount` and `dismiss(id)` for real;
// `history`/`dnd`/`clearAll()`/`openCentre()`/`toggleDnd()` are honest,
// reachable empty stubs waves 2-3 extend — never unreachable branches.
pragma Singleton
import QtQml
import Quickshell
import Quickshell.Services.Notifications

Singleton {
    id: root

    // ── In-flight popup list — a plain JS array of NotifData wrappers,
    //    reassigned (never mutated in place) so QML's list<QtObject>
    //    change notification fires on every add/remove. New arrivals
    //    prepend, so the ListView they back renders the newest card at
    //    the top of the stack (D-19-01's placement, D-19-02's ordering). ─
    property var popups: []

    // Honest empty declarations this plan does not populate — waves 2-3
    // implement history persistence (D-19-24/25) and DND (D-19-36).
    property var history: []
    property bool dnd: false

    readonly property int unreadCount: root.popups.length

    // ── dismiss(id) — removes the matching wrapper from `popups` (never
    //    mutates the array in place) and moves it into `history`, newest
    //    first. Called by NotifCard.qml's own D-19-04 auto-dismiss timer
    //    AND every gesture path (drag, middle-click, click-with-no-single-
    //    action) built in Plan 19-04 — one code path, so "no gesture
    //    destroys data" (this plan's own must_haves) is a property of
    //    THIS function rather than something every caller re-proves.
    //
    //    CORRECTED Phase 19 Plan 04 (Rule 1 — bug): the Plan 19-01 tracer's
    //    own version of this function called `wrapper.destroy()` after
    //    removing it from `popups` — correct for a wave-1 world where
    //    nothing read `history` yet, but it directly contradicts this
    //    plan's own cornerstone truth ("no gesture destroys data... the
    //    notification is still present in history afterwards") the moment
    //    a real gesture-driven dismiss exists. The wrapper is a live
    //    QtObject the whole time; only its `popups`-membership changes.
    //    `notifHistoryCap`/D-19-30's oldest-dropped-past-100 batching is
    //    explicitly wave-2 scope (history/grouping/clearing) — this
    //    function does not cap `history` itself. ─────────────────────────
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
        root.history = [wrapper].concat(root.history);
    }

    // ── Honest empty verbs — reachable, doing nothing yet, extended by
    //    waves 2-3 rather than left as unreachable branches. ─────────────
    function clearAll() {
        // Wave 2 implements history + the centre's clear-all (D-19-28/29).
    }
    function openCentre() {
        // Wave 2 implements the centre frame itself (D-19-14).
    }
    function toggleDnd() {
        // Wave 3 implements DND persistence and its toast (D-19-36).
    }

    // Factory for the per-notification wrapper — createObject() rather
    // than a static child, since one wrapper is created per D-Bus arrival.
    Component {
        id: notifDataComponent

        NotifData {}
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
            var wrapper = notifDataComponent.createObject(root, { notification: notif });
            root.popups = [wrapper].concat(root.popups);
        }
    }
}
