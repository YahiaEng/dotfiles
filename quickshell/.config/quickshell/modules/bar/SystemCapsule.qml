// SystemCapsule.qml — the system-readouts slot (Phase 18 Plan 05, D-18-10).
// Filled by Phase 18 Plan 08 (QBAR-06).
//
// Every value this file renders comes from the ONE SystemResources instance
// the shell root mounts, reached only through the `systemResources` handle
// BarCapsule already carries — a second sampler of any kind in this file
// would be the second backend this repo's zero-idle doctrine forbids. This
// file does not and must not assign that backend's own lifecycle gate
// property (`drawerOpen`): the gate is the shell's to set, 18-05 already
// set it, and a capsule that writes its own backend's gate makes the
// always-on charge 18-BAR-LIVENESS-CHARGE.md records unattributable.
//
// Entries, in BarEntryModel's declared order: cpu, ram, disk, updates. The
// first three read `systemResources`' published fractions AND their own
// D-41 readiness registers. `updates` has no existing backend anywhere in
// this repo; its one-shot reader lives in this file rather than as a new
// `modules/dashboard/` type, because `shell.qml` is frozen for wave 3 by
// 18-05 and a new backend type would need a `qmldir` registration plus a
// `shell.qml` mount to reach it — the wrong trade for one integer. It is
// the ONE entry in this whole file that reads no `systemResources`
// register.
//
// Interactive elements (Phase 18.1 Plan 02, D-25): the updates entry
// carries its own click handler (starts a package upgrade); cpu, ram and
// disk each carry an in-place format-alt VALUE TOGGLE (click reveals the
// value on the same pill, click again hides it) — Athena's literal
// format/format-alt swap, not a popout substitute. All other click,
// hover, dwell and scroll on this capsule belongs to 18-12, 18-13 or
// 18-14, and no stub of any of them exists here. cpu/ram/disk's toggle
// click is resolved inside `resourcesPopoutTrigger` below (see that
// wrapper's own comment) so it does not also summon the popout.
import QtQuick
import Quickshell.Io
import "../"
import "../dashboard"

BarCapsule {
    id: root

    capsuleId: "system"

    // ── The one reusable readout element ────────────────────────────────
    // Declared once, instantiated once here (four times once Task 2 lands
    // ram/disk/updates) rather than hand-copied — a glyph, Design.spacingXs
    // of gap, and a right-aligned value whose width is reserved at the
    // entry's own worst case (never the current value), so the capsule
    // never visibly resizes as a percentage crosses a digit boundary. One
    // bound `Grid` (never a Row/Column pair) provides the orientation swap
    // every entry needs on its own: glyph beside value horizontally, glyph
    // above value vertically. `errored` is bound to the metric's own D-41
    // register reading "empty" — the ONLY state that register reaches from
    // an actual read failure (a parse or missing-file error) rather than
    // from the ordinary pre-first-sample window, which is "pending" and is
    // not treated as an error.
    component Readout: Item {
        id: readoutItem

        property string glyph: ""
        property string valueText: ""
        property string maxValueText: "100%"
        property bool populated: true
        property bool errored: false

        // Only the updates entry sets this true — its click starts a
        // package upgrade via activated().
        property bool clickable: false

        // Set true on the cpu, ram and disk instances only (D-25): an
        // in-place format-alt value toggle, matching Athena's own
        // format/format-alt swap. This file now carries TWO interactive
        // shapes on the shared pointer hit area below (an upgrade-trigger
        // click and a value-reveal click), amending the previous "one
        // interactive element total" rule stated in the header above.
        property bool valueToggleable: false
        property bool valueRevealed: false

        function toggleValue() {
            readoutItem.valueRevealed = !readoutItem.valueRevealed;
        }

        // Threshold-driven colour (D-12/QBAR-06). All three inert at their
        // -1 default — an instance that never sets them (e.g. the updates
        // entry) simply never crosses either comparison below. Fractions,
        // to match what systemResources publishes (0.0-1.0), not percents.
        property real metricFraction: -1
        property real warnThreshold: -1
        property real dangerThreshold: -1

        // Lets ONE non-threshold instance (the updates entry, D-12's
        // filled alert pill) override the plain contentColour fallback
        // with its own fixed on-fill colour, without widening the
        // threshold precedence itself to know about fills.
        property bool useContentOverride: false
        property color contentOverride: "transparent"

        // Set true on the updates entry only (D-12) — draws
        // updatesFillPill (declared below, before entryGrid so it renders
        // behind it) as a solid rounded fill behind this entry's glyph
        // and value, matching Athena's #custom-updates rule. Every other
        // instance leaves this false and the pill stays invisible.
        property bool filled: false

        // Precedence, both boundaries inclusive (>=): errored (the ONLY
        // state "empty" reaches, never "pending" — see the header note on
        // D-41) beats a real threshold breach, which beats the ordinary
        // on-chrome colour. A metric sitting exactly on its threshold
        // value takes the more severe colour, which is why both
        // comparisons below are >= and neither is >.
        readonly property color severityColour: {
            if (readoutItem.errored)
                return BarRoles.danger;
            if (readoutItem.dangerThreshold >= 0 && readoutItem.metricFraction >= readoutItem.dangerThreshold)
                return BarRoles.danger;
            if (readoutItem.warnThreshold >= 0 && readoutItem.metricFraction >= readoutItem.warnThreshold)
                return BarRoles.warn;
            return readoutItem.useContentOverride ? readoutItem.contentOverride : root.contentColour;
        }

        signal activated

        readonly property bool vertical: root.vertical

        implicitWidth: entryGrid.implicitWidth
        implicitHeight: entryGrid.implicitHeight

        // Declared BEFORE entryGrid so it renders behind this entry's
        // glyph/value content by declaration order alone (no explicit z
        // needed — nothing else in this component sets one). Inert
        // (invisible, zero paint cost) on every instance except updates.
        Rectangle {
            id: updatesFillPill
            // Operator: "it needs to be slightly bigger because it is hard to
            // spot". Was exactly the readout's own box, which made the only
            // alert pill on the left the smallest thing there. Grown by one
            // spacing step on each axis and centred, so it reads as a pill
            // around the glyph rather than a tight disc behind it. Deliberately
            // NOT grown to Athena's own `#custom-updates` footprint, which is
            // wider because upstream always renders the count text beside the
            // glyph — ours stays icon-only at rest by the operator's own
            // preference, so it only needs presence, not width.
            anchors.centerIn: parent
            width: readoutItem.width + Design.spacingSm
            height: readoutItem.height + Design.spacingXs
            radius: height / 2
            visible: readoutItem.filled
            color: BarRoles.fillUpdates
            Behavior on color {
                enabled: Motion.motionEnabled
                ColorAnimation {
                    duration: Motion.standardDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.standardEasing
                }
            }
        }

        TextMetrics {
            id: valueReserve
            font.pixelSize: Design.barBodySize
            font.weight: Design.weightBody
            text: readoutItem.maxValueText
        }

        Grid {
            id: entryGrid
            rows: readoutItem.vertical ? -1 : 1
            columns: readoutItem.vertical ? 1 : -1
            spacing: Design.spacingXs

            Text {
                font.family: Design.symbolFontFamily
                font.pixelSize: Design.barGlyphSize
                text: readoutItem.glyph
                color: readoutItem.severityColour
            }

            Text {
                font.pixelSize: Design.barBodySize
                font.weight: Design.weightBody
                color: readoutItem.severityColour
                horizontalAlignment: Text.AlignRight
                // Hidden (not merely blank) AND zero-width when not
                // revealed — QtQuick positioners already exclude
                // non-visible children and their spacing (the same
                // mechanism BarCapsule and the updates entry rely on), so
                // this is what actually shrinks the pill rather than
                // leaving the value's worst-case width reserved.
                visible: readoutItem.valueRevealed
                width: valueRevealed ? valueReserve.width : 0
                text: readoutItem.populated ? readoutItem.valueText : "—"
            }
        }

        // One hit area, not two: extended (never duplicated) to cover
        // both interactive shapes this file now has. valueToggleable
        // takes precedence in onClicked because a resource glyph can
        // never be both toggleable and the upgrade-launcher — the two
        // are mutually exclusive by construction (only the updates
        // instance sets clickable, only cpu/ram/disk set valueToggleable).
        MouseArea {
            anchors.fill: parent
            enabled: readoutItem.clickable || readoutItem.valueToggleable
            visible: readoutItem.clickable || readoutItem.valueToggleable
            onClicked: {
                if (readoutItem.valueToggleable)
                    readoutItem.toggleValue();
                else if (readoutItem.clickable)
                    readoutItem.activated();
            }
        }
    }

    // ── cpu ──────────────────────────────────────────────────────────────
    // Percentage formatting deliberately reuses SystemResources' own
    // formatPercent() — the same convention PerformanceTab.qml already
    // renders these fractions with — rather than a second, invented
    // rounding rule for the same number. The register is read into one
    // local property so `populated`/`errored` below derive from a single
    // read rather than each re-reading the backend's own register.
    readonly property string cpuStateValue: root.systemResources ? root.systemResources.cpuState : "empty"

    // ── ram ──────────────────────────────────────────────────────────────
    readonly property string memoryStateValue: root.systemResources ? root.systemResources.memoryState : "empty"

    // ── disk ─────────────────────────────────────────────────────────────
    readonly property string storageStateValue: root.systemResources ? root.systemResources.storageState : "empty"

    // ── Popout wrapper (Phase 18 Plan 14, QBAR-09) — named seam into this
    //    18-08-owned file. Ownership split, stated so it is never
    //    discovered at merge time: 18-08 owns the three Readout instances'
    //    glyph, precedence and value bindings below; this plan (18.1-02)
    //    additionally owns each instance's new value-toggle flag (D-25).
    //    The wrapper owns only the PopoutTrigger and the nested Grid that
    //    reproduces the capsule's own positioner spacing, so the rendered
    //    geometry is unchanged. The updates readout stays a SIBLING
    //    outside this trigger, deliberately: it already owns a click that
    //    starts a package upgrade, and putting it inside the trigger would
    //    make that click pin a popout instead of upgrading anything.
    //
    //    Click-ordering (D-25/QBAR-09, stated in source, not left to
    //    event-propagation accident): each Readout's own pointer hit area
    //    is nested INSIDE this PopoutTrigger's wrapped content, so a click
    //    on a resource glyph is consumed there — it performs the in-place
    //    value toggle and does NOT also reach the trigger's own hit area
    //    to summon the popout. The popout stays reachable through the
    //    trigger's own hover-dwell path (unaffected — dwell does not
    //    route through a click at all). This precedence requires
    //    PopoutTrigger.qml's content-hosting Item to stack above the
    //    trigger's own hit area, which it does via the explicit z: 1 that
    //    same file now declares (18.1-02 scope amendment) — without it,
    //    the trigger's own hit area sat on top by declaration order alone
    //    and swallowed the click before it ever reached a Readout's
    //    nested one. ───────────────────────────────────────────────────
    PopoutTrigger {
        id: resourcesPopoutTrigger
        sectionId: "resources"
        popoutComponent: Component {
            ResourcesPopout {
                systemResources: root.systemResources
            }
        }

        Grid {
            id: resourcesTriggerGrid
            rows: root.vertical ? -1 : 1
            columns: root.vertical ? 1 : -1
            spacing: Design.spacingSm

            Readout {
                glyph: "memory"
                maxValueText: "100%"
                populated: root.cpuStateValue === "populated"
                errored: root.cpuStateValue === "empty"
                valueToggleable: true
                // Athena's own config-athena.jsonc cpu states block.
                warnThreshold: 0.75
                dangerThreshold: 0.90
                metricFraction: root.systemResources ? root.systemResources.cpuFraction : 0
                valueText: root.systemResources ? root.systemResources.formatPercent(root.systemResources.cpuFraction) : ""
            }

            Readout {
                glyph: "memory_alt"
                maxValueText: "100%"
                populated: root.memoryStateValue === "populated"
                errored: root.memoryStateValue === "empty"
                valueToggleable: true
                // Athena's own config-athena.jsonc memory states block.
                warnThreshold: 0.75
                dangerThreshold: 0.85
                metricFraction: root.systemResources ? root.systemResources.memoryFraction : 0
                valueText: root.systemResources ? root.systemResources.formatPercent(root.systemResources.memoryFraction) : ""
            }

            Readout {
                glyph: "hard_drive_2"
                maxValueText: "100%"
                valueToggleable: true
                populated: root.storageStateValue === "populated"
                errored: root.storageStateValue === "empty"
                // Athena's own config-athena.jsonc disk states block.
                warnThreshold: 0.80
                dangerThreshold: 0.90
                metricFraction: root.systemResources ? root.systemResources.storageFraction : 0
                valueText: root.systemResources ? root.systemResources.formatPercent(root.systemResources.storageFraction) : ""
            }
        }
    }

    // ── updates ──────────────────────────────────────────────────────────
    // Renders nothing at all — zero extent, zero spacing — when the
    // pending count is zero (UI-SPEC's E1-empty row read literally); the
    // shared chrome's own Grid positioner delivers that for free by
    // excluding non-visible children and their spacing, the same
    // mechanism BarCapsule itself uses to drop an empty capsule.
    //
    // Poll cadence is deliberately NOT a Motion token, for the same reason
    // MediaBackend.qml's own header already records: a poll cadence riding
    // the motion-scale axis would reach zero at the "off" preset. The
    // retired bar polled its update-check command every 15 seconds from a
    // dismissible widget; this surface never dismisses, so an inherited
    // 15-second cadence would run that same command roughly 5,700 times a
    // day (240 an hour) against public package-mirror infrastructure from
    // one desktop. Thirty minutes below is two runs an hour — 48 a day —
    // a fivefold-per-day reduction from the number the retired module
    // carried (the plan text this file was built from said "four runs an
    // hour"; the arithmetic for a 1,800,000ms/30-minute interval is two,
    // corrected here and recorded in the SUMMARY as a Rule 1 fix).
    readonly property string updatesCheckCommand: "checkupdates"
    readonly property int updatesPollIntervalMs: 1800000
    property int pendingUpdatesCount: 0

    // Athena's own #custom-updates rule is a FILLED pill (style-athena.scss
    // "background: @fill-updates; color: @fill-updates-fg; font-weight:
    // bold"), not a foreground tint like the resource glyphs — D-12. The
    // fill Rectangle (updatesFillPill, declared inside the Readout
    // component below and enabled via `filled: true` here) lives INSIDE
    // this Readout instance rather than as a sibling item: BarCapsule's
    // `default property alias content: contentGrid.data` reparents every
    // top-level child of this file's root into the shared chrome's own
    // Grid positioner, so a sibling Rectangle here would become a THIRD
    // grid cell (alongside resourcesPopoutTrigger and this entry) rather
    // than an overlay behind this one — a real layout bug, caught before
    // it shipped rather than left as a restated-in-a-comment promise.
    // Nesting keeps the pill "behind" this entry's content by declaration
    // order (it is declared first inside Readout, content Grid second)
    // while inheriting this instance's own visible: pendingUpdatesCount
    // > 0 gate for free — no separate condition to keep in sync.
    Readout {
        glyph: "deployed_code_update"
        maxValueText: "999"
        visible: root.pendingUpdatesCount > 0
        populated: true
        errored: false
        clickable: true
        filled: true
        // Fixed on-fill colour (D-12), not a threshold tint: warnThreshold/
        // dangerThreshold are left at their inert -1 default, so
        // severityColour's threshold branches never fire for this
        // instance and it falls straight to the override below.
        useContentOverride: true
        contentOverride: BarRoles.fillUpdatesFg
        valueText: root.pendingUpdatesCount.toString()
        onActivated: root.launchUpgrade()
    }

    Process {
        id: updatesProcess
        running: false
        command: [root.updatesCheckCommand]
        stdout: StdioCollector {
            id: updatesCollector
        }
        onExited: (exitCode, exitStatus) => {
            // A non-zero exit here is the tool's own "nothing pending"
            // signal, not a failure — the pacman-contrib update-listing
            // command documents this exit convention, and treating it as
            // an error would tint the glyph red on the most common case on
            // a well-maintained system. Only the line count matters.
            const lines = (updatesCollector.text || "").split("\n").filter(function (l) {
                return l.trim() !== "";
            });
            root.pendingUpdatesCount = lines.length;
        }
    }

    // Single-flighted: a tick that fires while the previous run is still
    // in flight is dropped rather than queued, so a slow mirror sync can
    // never stack a second child.
    function refreshUpdates() {
        if (updatesProcess.running)
            return;
        updatesProcess.running = true;
    }

    Timer {
        id: updatesTimer
        interval: root.updatesPollIntervalMs
        running: true
        repeat: true
        onTriggered: root.refreshUpdates()
    }

    Component.onCompleted: root.refreshUpdates()

    // ── The updates click action — the retired bar's own behaviour,
    //    reproduced as two fixed literal argv arrays chained on an exit
    //    code rather than the retired module's shell `&&` operator. Every
    //    element of both arrays is a string literal written in source;
    //    nothing is concatenated, nothing is caller-supplied, and no shell
    //    is invoked to re-split a composed command line — this repo's
    //    standing prohibition on string-built shell commands stays intact,
    //    and the two-argv-chained-on-exit-code shape is byte-equivalent in
    //    effect to the retired module's own terminal-package-upgrade
    //    launch followed by a completion notification. ───────────────────
    Process {
        id: upgradeProcess
        running: false
        command: ["kitty", "-e", "paru", "-Syu"]
        onExited: (exitCode, exitStatus) => {
            if (exitCode === 0) {
                notifyProcess.running = true;
                root.refreshUpdates();
            }
        }
    }

    Process {
        id: notifyProcess
        running: false
        command: ["notify-send", "The system has been updated"]
    }

    function launchUpgrade() {
        if (upgradeProcess.running)
            return;
        upgradeProcess.running = true;
    }
}
