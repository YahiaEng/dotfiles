// NotifData.qml — the 1:1 per-Notification wrapper (Phase 19 Plan 01
// tracer, QNOTIF-01/QNOTIF-05).
//
// Binds to the wrapped `Notification`'s own property-changed signals via a
// `Connections` block — NEVER by re-reading `NotifServer`'s notification
// arrival signal (its `on<Signal>Changed`-style handler is deliberately
// absent from this file), which fires exactly once per genuinely NEW
// D-Bus id.
// RESEARCH.md's Pattern 2 (§ "replaces_id mechanics") establishes why this
// binding shape matters: a `replaces_id` re-send reuses this SAME
// underlying `Notification` QObject rather than producing a second arrival
// signal, so subscribing to its property-changed signals is what makes
// D-19-08's "updates in place, does not re-animate or reorder the stack"
// fall out for free — the wrapper object is never destroyed and
// re-created, so the `ListView`/model holding it never removes+re-inserts
// it.
//
// `popup`/`closed` are the two lifecycle flags later plans extend (`popup`
// gates whether this notification still renders in the popup stack;
// `closed` marks it fully gone once history — wave 2 — retires it). This
// plan sets `popup: true` at construction and flips it to `false` on
// `NotifServer.dismiss(id)`; `closed` stays an honest, unused declaration
// this plan does not yet act on.
import QtQml
import Quickshell.Services.Notifications

QtObject {
    id: root

    // The wrapped Notification* — set once at construction by
    // NotifServer.qml's `notifDataComponent.createObject(...)` call and
    // never reassigned afterward.
    property var notification: null

    property bool popup: true
    property bool closed: false

    readonly property int notifId: root.notification ? root.notification.id : -1

    // ── Retained fields — mirror the wrapped Notification's own property
    //    set. Read at construction time via the property initializers
    //    below, then kept live by the Connections block's own handlers on
    //    every subsequent change (including a replaces_id re-send). ──────
    property string summary: root.notification ? root.notification.summary : ""
    property string body: root.notification ? root.notification.body : ""
    property string appName: root.notification ? root.notification.appName : ""
    property string appIcon: root.notification ? root.notification.appIcon : ""
    property string image: root.notification ? root.notification.image : ""
    property int urgency: root.notification ? root.notification.urgency : NotificationUrgency.Normal
    property var actions: root.notification ? root.notification.actions : []
    property real expireTimeout: root.notification ? root.notification.expireTimeout : -1

    // `QtObject` carries no default property, so the Connections block is
    // assigned through an explicit named property rather than declared as
    // an anonymous child (which fails to compile with "Cannot assign to
    // non-existent default property" — a QtObject-root-specific
    // constraint, found live wiring this file).
    property Connections _liveBindings: Connections {
        target: root.notification

        function onSummaryChanged() { root.summary = root.notification.summary; }
        function onBodyChanged() { root.body = root.notification.body; }
        function onAppNameChanged() { root.appName = root.notification.appName; }
        function onAppIconChanged() { root.appIcon = root.notification.appIcon; }
        function onImageChanged() { root.image = root.notification.image; }
        function onUrgencyChanged() { root.urgency = root.notification.urgency; }
        function onActionsChanged() { root.actions = root.notification.actions; }
        // Restarting the dismiss Timer is NotifCard.qml's own job (its
        // Timer.interval is bound to this wrapper's urgency, not to
        // expireTimeout directly, per D-19-04's fixed daemon-matching
        // windows) — this handler only keeps the retained field itself
        // current, so a later plan reading expireTimeout never sees a
        // stale value after a replaces_id re-send.
        function onExpireTimeoutChanged() { root.expireTimeout = root.notification.expireTimeout; }
    }
}
