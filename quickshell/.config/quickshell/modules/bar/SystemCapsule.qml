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
// Task 1 (this commit) is the tracer: exactly one entry — cpu — wired the
// whole way from the shell-mounted backend instance, through 18-05's
// handle, into a rendered glyph and a real moving number. ram, disk and
// updates land in the next commit once this shape is proven.
import QtQuick
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
}
