// BarEntryModel.qml — the single entry list QBAR-02 requires (Phase 18
// Plan 05).
//
// (a) This is the ONE entry list. Orientation is a property carried by
//     every entry (D-18-13), never a second arrangement — a parallel
//     ordering array anywhere in this repo would fail QBAR-02 even if it
//     rendered correctly, because the requirement is architectural, not
//     visual.
//
// (b) The orientation value lives at `orientationStatePath` below, a plain
//     one-word text file under quickshell's own state directory —
//     deliberately NOT at either of two more obvious paths. Reason one:
//     the theme state directory has exactly one writer (commit.sh's atomic
//     rsync, T-12-21) and a second writer there is forbidden. Reason two:
//     the retired top bar's own layout-selector file carries a
//     retired-surface name that retirement-check (18-06) would correctly
//     flag in its blocking tier. Quickshell already treats its own state
//     directory as this host's home for exactly this kind of scalar file
//     (see the sibling files already living there).
//
// (c) Write side: 18-11's settings-drawer and Super-menu toggle (D-18-30).
//     This file is a read-only consumer and, like Colours.qml, deliberately
//     never writes back.
//
// (d) An absent file is a valid, defaulted state — no install-time seed
//     exists and none is needed. 18-11 must not add one, and whichever
//     later plan retires the old layout selector must not look for one
//     here either.
pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // ── Orientation ──────────────────────────────────────────────────────
    // A two-member allowlist — no orientation string is ever a bare literal
    // at a comparison site.
    readonly property string orientationHorizontal: "horizontal"
    readonly property string orientationVertical: "vertical"
    readonly property string orientationStatePath: Quickshell.env("HOME") + "/.local/state/quickshell/bar-orientation"

    // Plain-text scalar idiom (Probe.qml's currentThemeFile/modeFile,
    // copied verbatim): a bare FileView, watchChanges + onFileChanged:
    // reload(), read via .text(). No JsonAdapter — this file is one word,
    // not JSON. watchChanges is what makes the flip live with no shell
    // restart.
    FileView {
        id: orientationFile
        path: root.orientationStatePath
        watchChanges: true
        onFileChanged: reload()
    }

    // The validated read. This is a two-member allowlist: every other
    // input — absent file, empty file, whitespace, a typo, a long string, a
    // path-shaped string — resolves to horizontal rather than to a third
    // state or an error. The value is only ever COMPARED here; it never
    // reaches a dispatch string, a process argument or a constructed path.
    readonly property string orientation: {
        var raw = (orientationFile.text() || "").trim();
        return raw === root.orientationVertical ? root.orientationVertical : root.orientationHorizontal;
    }
    // The single boolean every consumer binds to, so no consumer re-does
    // the string comparison itself.
    readonly property bool isVertical: root.orientation === root.orientationVertical

    // ── Zone vocabulary ──────────────────────────────────────────────────
    // One three-name vocabulary shared by BOTH orientations. This is what
    // keeps D-18-13 exactly true while using ONE vocabulary instead of two:
    // start means the left edge horizontally and the top edge vertically;
    // end means the right edge horizontally and the bottom edge
    // vertically; center is used horizontally only (a column has no
    // visual-balance reason to centre-band a group, per UI-SPEC's
    // Orientation Transform Rules) and is simply empty in the other
    // orientation. A single three-name vocabulary is what makes the
    // forked-arrangement failure structurally unrepresentable: Bar.qml
    // builds three zone containers in both orientations and only the
    // per-capsule zone VALUES differ.
    readonly property string zoneStart: "start"
    readonly property string zoneCenter: "center"
    readonly property string zoneEnd: "end"

    // ── The one entry list ───────────────────────────────────────────────
    // One ordered array, six elements, UI-SPEC's canonical group order.
    // Every element carries a zone object with BOTH a horizontal and a
    // vertical key (D-18-13). No second arrangement array exists anywhere
    // in this repo, and adding one would fail QBAR-02 even if it rendered
    // correctly.
    //
    // Two membership calls recorded here because CONTEXT grants the exact
    // capsule split as Claude's Discretion and a later reader would
    // otherwise assume a mistake:
    // First — `updates` sits in `system` as a readout (UI-SPEC's canonical
    // order places it there) while `idleInhibitor` sits in its OWN
    // capsule, `idleInhibitor`, in the centre zone beside `workspaces`
    // (GATE-02 operator fix, item (b) — upstream Athena's own
    // modules-center placement, ATHENA-UPSTREAM-SPEC.md), even though
    // D-18-03 names "updates count + idle inhibitor" as one extra and this
    // capsule started life folded into `clockActions` — they are split by
    // kind (readout vs action) and now also by zone, and GATE-02 A.5 still
    // finds all four extras visibly present.
    // Second — `network` and `bluetooth` declare NO gated backend, which
    // is deliberate and is explained beside the aggregates below.
    readonly property var capsules: [
        {
            id: "launcher",
            zone: { horizontal: root.zoneStart, vertical: root.zoneStart },
            entries: [
                { id: "apps", backends: [], textBearing: false }
            ]
        },
        {
            id: "system",
            zone: { horizontal: root.zoneStart, vertical: root.zoneStart },
            entries: [
                { id: "cpu", backends: ["resources"], textBearing: true },
                { id: "ram", backends: ["resources"], textBearing: true },
                { id: "disk", backends: ["resources"], textBearing: true },
                { id: "updates", backends: [], textBearing: true }
            ]
        },
        {
            id: "workspaces",
            zone: { horizontal: root.zoneCenter, vertical: root.zoneStart },
            entries: [
                { id: "workspaces", backends: [], textBearing: true }
            ]
        },
        {
            // GATE-02 operator fix, item (b): the idle-inhibitor bulb's own
            // capsule, immediately after `workspaces` in this array so
            // declaration order (== render order, see capsulesForZone()
            // below) places it right of workspaces in the centre zone.
            // Same zone shape as `workspaces` above: centre horizontally,
            // start vertically (the vertical column has no centre band —
            // see zoneCenter's own header note). No power-profiles-daemon
            // capsule exists beside it — the operator explicitly does not
            // want one, even though upstream Athena places one there too.
            id: "idleInhibitor",
            zone: { horizontal: root.zoneCenter, vertical: root.zoneStart },
            entries: [
                { id: "idleInhibitor", backends: [], textBearing: false }
            ]
        },
        {
            id: "mediaConnectivity",
            zone: { horizontal: root.zoneEnd, vertical: root.zoneStart },
            entries: [
                { id: "media", backends: ["media"], textBearing: true },
                { id: "audio", backends: ["audio"], textBearing: true },
                // brightness (Phase 18 Plan 12, QBAR-04, D-18-39) sits
                // immediately after audio because they are the bar's only
                // two scroll-adjustable entries — adjacency makes them one
                // contiguous scroll zone. It has no shell-mounted backend
                // (it reads BrightnessBackend, a bar-local singleton) so it
                // carries no name in `backends` here, and it renders
                // nothing when no device is present exactly as `battery`
                // does below — one entry list, one shape, no conditional
                // arrangement.
                { id: "brightness", backends: [], textBearing: true },
                { id: "network", backends: [], textBearing: false },
                { id: "bluetooth", backends: [], textBearing: false },
                { id: "battery", backends: ["power"], textBearing: true }
            ]
        },
        {
            id: "clockActions",
            zone: { horizontal: root.zoneEnd, vertical: root.zoneStart },
            entries: [
                { id: "clock", backends: [], textBearing: true },
                { id: "gaming", backends: [], textBearing: false },
                { id: "notifications", backends: [], textBearing: false },
                { id: "settings", backends: [], textBearing: false },
                { id: "power", backends: [], textBearing: false }
            ]
        }
    ]

    // ── Resolution functions ────────────────────────────────────────────
    // Overview.qml's pure-resolution-function convention. No sort runs
    // anywhere in this file: declaration order IS render order and is
    // therefore stable — two capsules comparing equal on zone cannot swap
    // positions between reloads or between orientations, and that is the
    // ordering contract in must_haves.
    function capsulesForZone(zoneName) {
        var result = [];
        for (var i = 0; i < root.capsules.length; i++) {
            var capsule = root.capsules[i];
            var zoneValue = root.isVertical ? capsule.zone.vertical : capsule.zone.horizontal;
            if (zoneValue === zoneName)
                result.push(capsule);
        }
        return result;
    }

    function zoneFor(capsuleId) {
        var capsule = root.capsuleById(capsuleId);
        if (!capsule)
            return null;
        return root.isVertical ? capsule.zone.vertical : capsule.zone.horizontal;
    }

    function capsuleById(capsuleId) {
        for (var i = 0; i < root.capsules.length; i++) {
            if (root.capsules[i].id === capsuleId)
                return root.capsules[i];
        }
        return null;
    }

    // The accessor every wave-3 capsule file reads, so none of them needs
    // to know the array's internal shape.
    function entriesFor(capsuleId) {
        var capsule = root.capsuleById(capsuleId);
        return capsule ? capsule.entries : [];
    }

    function requiresBackend(backendName) {
        for (var i = 0; i < root.capsules.length; i++) {
            var entries = root.capsules[i].entries;
            for (var j = 0; j < entries.length; j++) {
                if (entries[j].backends.indexOf(backendName) !== -1)
                    return true;
            }
        }
        return false;
    }

    // ── Backend aggregates ───────────────────────────────────────────────
    // Exactly three exist. Deliberately absent: an aggregate for the
    // network entry's backend and one for the bluetooth entry's backend.
    // The two services those entries read gate their own scanning and
    // discovery behind a SEPARATE, ungated-here property
    // (`panelOpen`-shaped on each of those two backend singletons), which
    // D-15-15/D-15-18 forbid running always-on — shell.qml's own comment
    // block already states this in full. The bar reads only those two
    // backends' ungated connection-state bindings, so it needs no gate
    // widening from them, and minting an unconsumed aggregate here would
    // invite a later reader to wire it and silently start a permanent
    // scan.
    //
    // These three are true from THIS plan onward because the entry list is
    // complete from this plan onward — the deliberate cost of
    // pre-declaring the whole list one wave before wave 3 fills it.
    // 18-18's soak diffs this against 18-BAR-IDLE-BASELINE.md: a named
    // charge against QBAR-11, not an incidental widening.
    readonly property bool requiresResources: root.requiresBackend("resources")
    readonly property bool requiresMedia: root.requiresBackend("media")
    readonly property bool requiresAudio: root.requiresBackend("audio")
}
