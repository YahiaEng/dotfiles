// BarReveal.qml — the reveal state machine (Phase 18 Plan 16, QBAR-08).
// Singleton (registered in modules/bar/qmldir).
//
// ── Ownership statement (read this before anything else) ────────────────
// `bar-visibility.sh` alone decides the bar's BASE state (visible /
// hidden-idle / hidden-hard) — 18-15's single-owner claim, unchanged by
// this file. This singleton decides only whether a HIDDEN bar is
// TEMPORARILY drawn on top of that base state. The composition is a
// disjunction wired at the bar's mount site in shell.qml
// (`revealOverride: BarReveal.revealActive`), and the arrow points owner
// -> shell and never back. This file holds no file handle, launches no
// subprocess and declares no IPC endpoint of its own — those three
// absences are what make it structurally incapable of being a second
// writer of visibility state. A future edit that adds any of them has
// changed the architecture, not merely the code.
//
// ── Seam confirmation (18-15's shipped identifiers, read from its own
//    source before this file was written) ────────────────────────────────
// `Bar.qml` ships `property bool revealOverride` (writable, this file's
// seam), `readonly property bool barRendered` (the disjunction the
// override already feeds) and `readonly property bool barTransitionRunning`
// (bound to the fade animation's own running state — 18-16's consumer,
// driven from shell.qml in Task 3, not from here). `shell.qml`'s root
// carries `property string barVisibilityState`. All four identifiers
// match this plan's assumption byte-for-byte — no correction needed.
pragma Singleton

import QtQuick
import "../dashboard"

Singleton {
    id: root

    // ── Hover half — two independent named booleans behind the one entry
    //    point below, never a counter. The surfaces that report through
    //    it are destroyed under the pointer by design (the hot zone is
    //    LazyLoader-destroyed the instant the bar becomes visible), so a
    //    lost leave event is expected — a counter could go negative on
    //    that and wedge the bar permanently revealed or permanently
    //    hidden; two named booleans cannot. ──────────────────────────────
    property bool hotZoneHovered: false
    property bool barHovered: false

    // The pointer is on the hot zone or on the bar — recomputed inside
    // reportHover() below, imperatively, rather than as a live binding
    // expression: this is what "two independent named booleans" means in
    // practice, not a third counter tracking how many surfaces are
    // hovered.
    property bool hoverHeld: false

    // Declared here and left undriven — Task 2 is its only writer.
    // Declared now so the disjunction beneath it is written once and never
    // rewritten by a later task.
    property bool superHeld: false

    // The one entry point both hover surfaces (HotZone.qml, Bar.qml) report
    // through — never a direct property write from either file.
    function reportHover(source, entered) {
        if (source === "hotzone")
            root.hotZoneHovered = entered;
        else if (source === "bar")
            root.barHovered = entered;
        root.hoverHeld = root.hotZoneHovered || root.barHovered;
    }

    // ── The disjunction (D-18-26's INPUT, not its output) — hoverHeld and
    //    superHeld, the two raw inputs this file composes. Read only by the
    //    arm/cancel wiring immediately below; nothing outside this file
    //    reads it. ─────────────────────────────────────────────────────
    readonly property bool revealCondition: root.hoverHeld || root.superHeld

    // ── The single timing object this plan introduces anywhere — the bar
    //    has no dismissed state, so a repeating timer added here would run
    //    forever; this one is non-repeating and stopped at rest. Interval
    //    reads Design.barReHideGraceMs (600), never a literal. ───────────
    Timer {
        id: reHideTimer
        interval: Design.barReHideGraceMs
        repeat: false
        running: false
        onTriggered: {
            // Explicit, defensive clear — revealCondition is guaranteed
            // false by the time this fires uninterrupted (arming only
            // happens on its OWN transition to false, and re-entering
            // cancels the timer outright rather than shortening it — see
            // the arm/cancel wiring below), so hoverHeld is already false
            // here. Stated as a clear rather than left implicit, per this
            // task's own action text.
            root.hoverHeld = false;
        }
    }

    // Armed once, on revealCondition's transition to false; cancelled
    // once, on its transition back to true. Re-entering the hot zone,
    // re-entering the bar or re-pressing Super inside the grace window
    // cancels the pending re-hide outright — the next clearance starts a
    // fresh full window, never a resumed remainder (D-18-26's boundary
    // contract).
    onRevealConditionChanged: {
        if (root.revealCondition)
            reHideTimer.stop();
        else
            reHideTimer.restart();
    }

    // ── The ONE value Bar.qml reads (bound to `revealOverride` at the
    //    bar's mount site in shell.qml, never inside Bar.qml itself).
    //    Extends revealCondition through the grace window: true while
    //    either raw input is held, AND true for the `Design.barReHideGraceMs`
    //    beat after both have cleared — which is the entire reason the
    //    timer above exists. `reHideTimer.running` folding into this
    //    expression, rather than the timer's onTriggered writing a second
    //    property, is what keeps this a pure derived binding with no edge
    //    it can miss. ───────────────────────────────────────────────────
    readonly property bool revealActive: root.revealCondition || reHideTimer.running

    // One line per transition, the same one-line console shape 18-13's
    // PopoutController uses for its own latch — the gates read these
    // lines, and so will 18-18's soak.
    onRevealActiveChanged: {
        console.log("reveal: " + (root.revealActive ? "shown" : "hidden"));
    }
}
