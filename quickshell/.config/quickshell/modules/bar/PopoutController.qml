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

    // ── The six-section allowlist (D-18-16) ─────────────────────────────
    // Every popout body this plan or 18-14 ever adds is one of these six
    // names. Validated before a sectionId reaches
    // WlrLayershell.namespace (SectionPopout.qml) — the same
    // validate-before-interpolate discipline Overview.qml applies before a
    // compositor dispatch, because an id outside the family prefix would
    // silently lose the family's blur and alpha layer rules and disappear
    // from GATE-03's checks.
    readonly property var sections: ["audio", "wifi", "bluetooth", "clock", "resources", "media"]

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
}
