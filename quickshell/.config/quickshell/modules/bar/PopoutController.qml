// PopoutController.qml — the popout family's single guarded summon path
// (Phase 18 Plan 13, QBAR-09). The direct counterpart of shell.qml's own
// openPanel(name): nothing outside this file may write openSection or
// pinnedSection, and nothing outside this file may write a PopoutTrigger's
// LazyLoader.active directly — every trigger's loader is keyed on
// PopoutController.openSection, which is what makes one-open-at-a-time
// structural rather than remembered.
//
// Task 1 (this commit) declares only the summon half: the six-section
// allowlist, open/pin/close/toggle, and the outbound wayfinding signals.
// Task 2 (same plan) adds the hover half on top of this — the
// reveal-settled/pointer-moved suppression latch, the two non-repeating
// timers, the combined hover region, and the five events a PopoutTrigger
// reports (entryEntered/entryMoved/entryExited/popoutEntered/popoutExited).
pragma Singleton

import QtQuick
import Quickshell
import "../dashboard"

Singleton {
    id: root

    // ── The section allowlist (D-18-16) ─────────────────────────────────
    // Every popout body this plan or 18-14 ever adds is one of these names.
    // Validated before a sectionId reaches
    // WlrLayershell.namespace (SectionPopout.qml) — the same
    // validate-before-interpolate discipline Overview.qml applies before a
    // compositor dispatch, because an id outside the family prefix would
    // silently lose the family's blur and alpha layer rules and disappear
    // from GATE-03's checks.
    //
    // EXTENDED from D-18-16's original SIX to seven, 2026-08-12, by operator
    // request: "ethernet" joins them so the wired glyph — which shipped as a
    // bare Readout beside a network glyph that had a popout — can open
    // EthernetPopout.qml. Recorded as an extension rather than made quietly,
    // because this list is a deny-by-default gate and its whole value is that
    // growing it is a visible act. The gate's own mechanism is unchanged, and
    // nothing here asserts a COUNT: the previous "six" was prose, never a
    // machine check (verified before editing), so no gate needed relaxing to
    // admit the seventh. GATE-03's bar-surface registry needed no new row
    // either — its SectionPopout entry stores the PATTERN prefix
    // `quickshell-bar-`, which `quickshell-bar-ethernet` already matches.
    //
    // EXTENDED from seven to eight, 2026-08-23, by quick task 260823-65s:
    // "tray" joins them so TrayCapsule.qml's overflow chevron can open
    // TrayPopout.qml for the 4th-and-later tray item (D-1). Same reasoning
    // as the ethernet extension above — recorded because growing this list
    // is a visible act, and no GATE-03 row is needed since
    // `quickshell-bar-tray` already matches the same `quickshell-bar-`
    // pattern prefix.
    readonly property var sections: ["audio", "wifi", "bluetooth", "clock", "resources", "media", "ethernet", "tray"]

    function isValidSection(id) {
        return root.sections.indexOf(id) !== -1;
    }

    // ── Summon state — assigned in exactly two places in the whole shell:
    //    open() and close() below. Nothing else, anywhere, may write
    //    either of these two properties directly. ────────────────────────
    property string openSection: ""
    property string pinnedSection: ""

    // D-18-26's input: no consumer in this plan. 18-16's re-hide grace
    // timer reads this so the bar can never vanish out from under an open
    // popout — exposed here rather than making 18-16 reach into popout
    // internals to find out.
    readonly property bool anyOpen: root.openSection !== ""

    // Refuses and returns false for an id that fails validation; returns
    // true unchanged if it is already the open section; otherwise clears
    // pinnedSection FIRST — the ordered transition that makes "opening a
    // second popout dismisses the first" a single step rather than two
    // loaders racing — then sets openSection. This is the first of the
    // two places openSection is ever assigned.
    function open(sectionId) {
        if (!root.isValidSection(sectionId))
            return false;
        if (root.openSection === sectionId)
            return true;
        root.pinnedSection = "";
        root.openSection = sectionId;
        console.log("popout: open section=" + sectionId);
        return true;
    }

    function pin(sectionId) {
        if (!root.open(sectionId))
            return false;
        root.pinnedSection = sectionId;
        console.log("popout: pin section=" + sectionId);
        return true;
    }

    // The SECOND (and last) place openSection is ever assigned — see
    // open() above for the first. This invariant is what makes
    // one-open-at-a-time hold no matter how many bodies 18-14 adds.
    function close() {
        root.pinnedSection = "";
        root.openSection = "";
        console.log("popout: dismiss");
    }

    function toggle(sectionId) {
        if (root.pinnedSection === sectionId)
            root.close();
        else
            root.pin(sectionId);
    }

    // ── Outbound wayfinding — a popout body reaches the detail surface
    //    without any file under modules/bar/ needing an ambient lookup up
    //    its own parent chain. Bar.qml (Task 3, this same plan) relays
    //    these into the panelRequested/dashboardRequested seams 18-05
    //    already declared and deliberately left un-emitted. ─────────────
    signal panelRequested(string name)
    signal dashboardRequested(int tabIndex)

    function requestPanel(name) {
        root.panelRequested(name);
    }
    function requestDashboard(tabIndex) {
        root.dashboardRequested(tabIndex);
    }

    // powerMenuRequested (Phase 20 Plan 06 Task 2, QPOWER-01/D-20-22) — a
    // THIRD wayfinding seam, reusing this exact mechanism rather than
    // inventing a second one. `ClockActionsCapsule.qml`'s `powerCell`
    // lives inside a capsule instantiated through a loader with no
    // declarative path of its own to shell.qml's window root, identically
    // to the panel/dashboard case above; PowerMenu is a top-level
    // LazyLoader toggle rather than a popout-family member, so it earns
    // its own signal instead of overloading `panelRequested`'s
    // popout-section semantics. Bar.qml relays this the same way it
    // already relays the two above.
    signal powerMenuRequested()

    function requestPowerMenu() {
        root.powerMenuRequested();
    }

    // Operator request (2026-08-21): the settings trigger's HOVER opens the
    // five-axis drawer; its CLICK opens the settings window. Same relay shape
    // as powerMenuRequested above and for the same reason — ClockActionsCapsule
    // has no declarative path to shell.qml's root, and the settings window is a
    // top-level LazyLoader toggle, not a popout-family member.
    signal settingsRequested()

    function requestSettings() {
        root.settingsRequested();
    }

    // ══════════════════════════════════════════════════════════════════
    // Task 2 — the hover contract (D-18-19 through D-18-22)
    // ══════════════════════════════════════════════════════════════════

    // ── The suppression latch (D-18-19) ─────────────────────────────────
    // barSettled is the input 18-16's reveal owner drives: false at the
    // start of a reveal, true on the reveal animation's completion.
    // Defaults true because there is no reveal animation yet — this is
    // the one half of D-18-19 this plan cannot prove today, named rather
    // than quietly assumed.
    property bool barSettled: true

    // Set true by the first pointer move reported on a settled bar; reset
    // to false whenever barSettled goes false, through an explicit change
    // handler rather than a binding, so the reset is a single visible
    // statement.
    property bool pointerMovedSinceSettle: false

    onBarSettledChanged: {
        if (!root.barSettled)
            root.pointerMovedSinceSettle = false;
    }

    readonly property bool previewArmed: root.barSettled && root.pointerMovedSinceSettle

    // Without this latch the reveal gesture and the preview gesture are
    // the same motion, so revealing the bar would fire a popout under
    // wherever the pointer happened to enter — not hypothetical, since
    // D-18-25 puts the reveal hot zone on the physical screen edge, and
    // its own stated goal is that the pointer can slam to that edge
    // without aiming, which means the pointer that reveals the bar lands
    // on an entry every single time. The latch gates PREVIEW ONLY — a
    // click pins regardless of the latch, because a click is unambiguous
    // intent and the ambiguity D-18-19 addresses is entirely in the hover
    // gesture. Do not "fix" that asymmetry later.
    onPreviewArmedChanged: {
        if (root.previewArmed)
            console.log("popout: preview armed");
    }

    // ── The two timers — the ONLY two timing objects the popout family
    //    introduces. Both declare repeat/running explicitly rather than
    //    relying on a default, so a reader can see at a glance that
    //    neither runs at rest — this matters more here than anywhere else
    //    in the shell, because the bar is the first surface with no
    //    dismissed state and a resting cost added here is permanent. ────
    Timer {
        id: dwellTimer
        interval: Design.popoutDwellMs
        repeat: false
        running: false
        onTriggered: {
            // Re-check all three at fire time rather than trusting the
            // state at start time — the pointer can leave during the
            // dwell.
            if (root.hoveredSection === "" || !root.previewArmed || root.pinnedSection !== "")
                return;
            root.open(root.hoveredSection);
        }
    }

    Timer {
        id: graceTimer
        interval: Design.popoutDismissGraceMs
        repeat: false
        running: false
        onTriggered: {
            if (root.combinedHovered || root.pinnedSection !== "")
                return;
            root.close();
        }
    }

    // ── Combined hover region — the triggering entry and its popout held
    //    as TWO independent booleans, never a counter: a counter can go
    //    negative on a lost enter or exit event and wedge the popout
    //    permanently open, and the 4px gap between the two surfaces is
    //    inside this union by construction while it would be outside any
    //    geometric rectangle. ────────────────────────────────────────────
    property string hoveredSection: ""
    property bool popoutHovered: false

    readonly property bool combinedHovered: root.hoveredSection !== "" || root.popoutHovered

    // ── The five reported events — each a function the trigger or the
    //    popout calls; none of them writes openSection except through
    //    open()/close() above. Every hover entry point below returns
    //    early while pinnedSection is non-empty: a STRONGER statement
    //    than "the timers happen not to fire" — no dwell arms, no grace
    //    runs, and pointer-leave does nothing at all, so a pinned popout
    //    behaves identically to a panel-family surface, which dismisses
    //    only on click-outside, Escape, or a second click of its own
    //    trigger (D-18-22). ───────────────────────────────────────────────
    function entryEntered(sectionId) {
        if (root.pinnedSection !== "")
            return;
        graceTimer.stop();
        root.hoveredSection = sectionId;
        // Restarting ONE shared timer, rather than one per entry, is what
        // makes a slide across the whole bar toward the tray open
        // nothing: every entry crossed resets the clock instead of
        // queuing its own.
        if (root.previewArmed)
            dwellTimer.restart();
    }

    function entryMoved(sectionId) {
        root.pointerMovedSinceSettle = true;
        // The path that arms the latch in normal use: if this is already
        // the hovered section and the preview has just become armed with
        // no dwell running, start it.
        if (root.hoveredSection === sectionId && root.previewArmed && !dwellTimer.running)
            dwellTimer.restart();
    }

    function entryExited(sectionId) {
        if (root.pinnedSection !== "")
            return;
        dwellTimer.stop();
        if (root.hoveredSection === sectionId)
            root.hoveredSection = "";
        if (root.anyOpen)
            graceTimer.restart();
    }

    function popoutEntered() {
        root.popoutHovered = true;
        graceTimer.stop();
    }

    function popoutExited() {
        root.popoutHovered = false;
        if (root.pinnedSection === "" && root.anyOpen)
            graceTimer.restart();
    }
}
