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
// register, and it is also the only entry that carries an interactive
// element (its own click handler) — every other click, hover, dwell and
// scroll on this capsule belongs to 18-12, 18-13 or 18-14, and no stub of
// any of them exists here.
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

        // Only the updates entry sets this true; every other entry is
        // inert, matching this file's own "one interactive element total"
        // rule stated in the header above.
        property bool clickable: false

        signal activated

        readonly property bool vertical: root.vertical

        implicitWidth: entryGrid.implicitWidth
        implicitHeight: entryGrid.implicitHeight

        TextMetrics {
            id: valueReserve
            font.pixelSize: Design.fontLabel
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
                font.pixelSize: Design.iconSizeMd
                text: readoutItem.glyph
                color: readoutItem.errored ? Colours.error : root.contentColour
            }

            Text {
                font.pixelSize: Design.fontLabel
                font.weight: Design.weightBody
                color: root.contentColour
                horizontalAlignment: Text.AlignRight
                width: valueReserve.width
                text: readoutItem.populated ? readoutItem.valueText : "—"
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: readoutItem.clickable
            visible: readoutItem.clickable
            onClicked: readoutItem.activated()
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

    Readout {
        glyph: "memory"
        maxValueText: "100%"
        populated: root.cpuStateValue === "populated"
        errored: root.cpuStateValue === "empty"
        valueText: root.systemResources ? root.systemResources.formatPercent(root.systemResources.cpuFraction) : ""
    }

    // ── ram ──────────────────────────────────────────────────────────────
    readonly property string memoryStateValue: root.systemResources ? root.systemResources.memoryState : "empty"

    Readout {
        glyph: "memory_alt"
        maxValueText: "100%"
        populated: root.memoryStateValue === "populated"
        errored: root.memoryStateValue === "empty"
        valueText: root.systemResources ? root.systemResources.formatPercent(root.systemResources.memoryFraction) : ""
    }

    // ── disk ─────────────────────────────────────────────────────────────
    readonly property string storageStateValue: root.systemResources ? root.systemResources.storageState : "empty"

    Readout {
        glyph: "hard_drive_2"
        maxValueText: "100%"
        populated: root.storageStateValue === "populated"
        errored: root.storageStateValue === "empty"
        valueText: root.systemResources ? root.systemResources.formatPercent(root.systemResources.storageFraction) : ""
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
    // day against public package-mirror infrastructure from one desktop.
    // Thirty minutes below is four runs an hour instead of two hundred and
    // forty.
    readonly property string updatesCheckCommand: "checkupdates"
    readonly property int updatesPollIntervalMs: 1800000
    property int pendingUpdatesCount: 0

    Readout {
        glyph: "deployed_code_update"
        maxValueText: "999"
        visible: root.pendingUpdatesCount > 0
        populated: true
        errored: false
        clickable: true
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
