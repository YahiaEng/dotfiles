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
//
// ── Mechanism record (Task 2, QBAR-08's held-Super half) — BLOCKED, NOT
//    SHIPPED. This is the honest outcome, not the preferred one. ─────────
// ATTEMPTED MECHANISM: Branch A — a single Hyprland compositor bind on the
// same "SUPER + SUPER_L" chord line 86's tap-to-menu bind already uses,
// dispatching the Quickshell global-shortcut identifier
// "quickshell:bar-reveal" on the PRESS edge (no `release` option — line 86
// keeps its own `release = true` bind on the SAME chord, untouched). The
// installed Hyprland `GlobalShortcut` type
// (Quickshell.Hyprland._GlobalShortcuts/GlobalShortcut, read directly from
// its own qmltypes file rather than assumed) declares a readonly `pressed`
// boolean with a `pressedChanged` notification AND separate
// `pressed`/`released` signals (with `onPressed`/`onReleased` handlers) —
// both edges genuinely exist on the QML side, correcting RESEARCH.md's
// Open Question 2 / assumption A2, which found no held-modifier signal in
// its scanned surface: the scan was incomplete, not wrong about the risk.
// So the QML half is confirmed live-viable; `setSuperHeld(held)` below
// exists and is ready to be the mechanism's sole writer the day a bind
// reaches it.
//
// WHY IT WAS REVERTED: `keybind-doctor` was run against the drafted bind
// before it was committed, per this task's "verification first" method.
// Its SHADOW check (which distinguishes binds by `(modmask, key, keycode,
// release)`) reported zero conflicts — the two binds ARE different tuples,
// exactly as this plan's threat register predicted. But a SEPARATE check
// the threat register did not anticipate — the quickshell-manifest chord
// COLLISION check, which compares `(modmask, key)` WITHOUT the release
// flag — flagged the drafted bind: it and line 86's bind both claim the
// identical "SUPER + SUPER_L" chord, and the checker's model expects a
// manifest-registered chord to be claimed by exactly one Hyprland bind
// (the matching `hl.dsp.global(...)` line), not shared across two
// dispatchers on different edges. Whether Hyprland's own runtime actually
// dispatches both edges independently and safely (this repo's own
// header comment above keybinds.lua:86 — "Hyprland's native default
// release-bind shadowing" — describes a RELATED but not identical
// phenomenon: how a release-only bind is suppressed when its modifier was
// consumed by another chord mid-press, not whether a same-chord press
// bind and release bind both fire cleanly) could not be settled without a
// live keypress, which this session could not perform (see below).
//
// Per this task's own Step 4 stop condition — "if every candidate shape
// breaks... revert... and hand the choice to the developer... do not ship
// a bind that works most of the time" — the drafted bind, the
// `shortcuts.json` manifest entry and the `GlobalShortcut` declaration in
// shell.qml were all REVERTED rather than committed. `keybinds.lua:86` is
// untouched. Branch B was not attempted for the same reason: it needs the
// identical "SUPER + SUPER_L" chord (a press bind plus a paired release
// bind) to represent "Super, held" at all, so it collides with line 86's
// own release bind exactly the same way, with no chord substitute
// available — QBAR-08 names Super specifically, not a Super+letter chord.
//
// WHAT REMAINS UNVERIFIED, recorded rather than hidden: whether Hyprland
// actually dispatches a press-triggered global-shortcut bind and a
// release-triggered exec_cmd bind on the identical chord independently, on
// their own edges, with no shadowing between them. The nested
// `hypr-lua-harness` instance is where this task's own action block
// specifies that probe should run (Step 2); it was not run this session —
// the live `quickshell` process on this host predates every commit in
// this plan (`qs ipc call bar status` answers "Target not found") and has
// not been restarted, matching 18-08/18-12/18-13/18-15's established
// skip-live-verification precedent, and confirming the compositor-level
// answer does not need a live `quickshell` process at all — only time this
// session did not allocate to it. Logged to WINDOWS.md as a blocked item.
// The next session that picks this up should run that probe FIRST — if it
// answers cleanly, restoring this bind is a three-line reconstruction of
// what this file's git history already shows was reverted here.
pragma Singleton

import QtQuick
import Quickshell
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

    // Task 2's only writer of superHeld — set on the confirmed bind's
    // press edge, cleared on its release edge, nothing else. Called from
    // shell.qml's GlobalShortcut handlers rather than writing the property
    // directly from there, so there is exactly one write SITE regardless
    // of how many edges call it.
    function setSuperHeld(held) {
        root.superHeld = held;
    }

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

    // ── D-18-26's other input, read exactly once (Task 3) — 18-13 declared
    //    this popout-open flag two waves early specifically so this file
    //    would not reach into popout internals; this is that one read.
    //    Never written from here. Reading it through this local alias,
    //    rather than spelling the singleton reference a second time below,
    //    is what keeps this file's own literal reference count at exactly
    //    one while still consuming the value from two places (the timer's
    //    guard and the re-arm handler beneath it). ───────────────────────
    readonly property bool popoutOpen: PopoutController.anyOpen

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
            // D-18-26's full conjunction, evaluated in exactly this one
            // place: the reveal condition has ended (guaranteed by the
            // arm/cancel wiring below) AND no popout is open. A popout
            // still open here means the bar cannot vanish out from under
            // it — re-arm a full window rather than let it fall, so a
            // popout read continuously holds the bar up indefinitely
            // rather than for one more fixed window.
            if (root.popoutOpen) {
                reHideTimer.restart();
                return;
            }
            // Explicit, defensive clear — revealCondition is guaranteed
            // false by the time this fires uninterrupted (arming only
            // happens on its OWN transition to false, and re-entering
            // cancels the timer outright rather than shortening it — see
            // the arm/cancel wiring below), so hoverHeld is already false
            // here. Stated as a clear rather than left implicit, per
            // Task 1's own action text.
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

    // Closing the last popout while the pointer is already away must start
    // a FRESH full grace window, never resume a window that was implicitly
    // extended by the open popout above — the user just finished reading
    // something; they get the whole beat, not a remainder (Task 3's own
    // action text).
    onPopoutOpenChanged: {
        if (!root.popoutOpen && !root.revealCondition)
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
