// ResourcesPopout.qml — the resources section's popout body (Phase 18
// Plan 14, QBAR-09). Follows WifiPopout.qml's shape as the closest
// in-plan precedent.
//
// ── Readiness verdict this body relies on ────────────────────────────────
// EXISTS NATIVELY — SystemResources.qml has published a three-value
// per-metric D-41 register (cpuState/memoryState/storageState) since
// Phase 14, set to "pending" on reset and "populated"/"empty" on every
// sample. Confirmed against that file directly: `sampleFast()` sets each
// register independently per metric, never an aggregate write standing in
// for all three, so per-field degradation is real rather than assumed.
//
// ── Per-field degradation is the point of this body ──────────────────────
// Confirmed against Dial.qml and PerformanceTab.qml directly: `widgetState`
// is a property Dial.qml declares PER INSTANCE, and PerformanceTab.qml
// binds each dial's own `widgetState` from its own metric register
// (cpuDial from cpuState, memoryDial from memoryState, storageDial from
// storageState) — the precedent really is per-instance, not per-tab, and
// this body's three rows extend it rather than assume it.
//
// This plan's own header comment for the not-yet-sampled case is the
// whole prohibition in one line: a track filled to nothing is a claim
// about the machine, an empty track beside an em-dash is an admission
// about the shell — deliberately kept close to the branch it describes
// below.
import QtQuick
import "../"
import "../dashboard"

SectionPopout {
    id: root

    property var systemResources: null

    sectionId: "resources"
    popoutTitle: "Resources"
    popoutGlyph: "speed"

    readonly property string _cpuState: root.systemResources ? root.systemResources.cpuState : "empty"
    readonly property string _memoryState: root.systemResources ? root.systemResources.memoryState : "empty"
    readonly property string _storageState: root.systemResources ? root.systemResources.storageState : "empty"

    readonly property string _cpuValueText: root.systemResources ? root.systemResources.formatPercent(root.systemResources.cpuFraction) : ""
    readonly property string _memoryValueText: root.systemResources ? root.systemResources.formatPercent(root.systemResources.memoryFraction) : ""
    readonly property string _storageValueText: root.systemResources ? root.systemResources.formatPercent(root.systemResources.storageFraction) : ""

    readonly property string _memoryDetailText: (root.systemResources && root._memoryState === "populated")
        ? (root.systemResources.formatBytes(root.systemResources.memoryUsedBytes) + " / " + root.systemResources.formatBytes(root.systemResources.memoryTotalBytes))
        : ""
    readonly property string _storageDetailText: (root.systemResources && root._storageState === "populated")
        ? (root.systemResources.formatBytes(root.systemResources.storageUsedBytes) + " / " + root.systemResources.formatBytes(root.systemResources.storageTotalBytes))
        : ""

    // The aggregate governs only the frame's own placeholder; the three
    // rows below degrade independently underneath it, which is precisely
    // what per-field rather than per-body means.
    bodyState: {
        var states = [root._cpuState, root._memoryState, root._storageState];
        var allPending = states.every(function (s) { return s === "pending"; });
        var allEmpty = states.every(function (s) { return s === "empty"; });
        if (allPending)
            return "pending";
        if (allEmpty)
            return "empty";
        return "populated";
    }

    wayfindingLabel: "Open Performance tab"
    // dashboardWindow.tabIndexPerformance (modules/Dashboard.qml) is 2 —
    // confirmed by reading that file's own declared tab constants rather
    // than counting the tab list by hand.
    onWayfindingActivated: PopoutController.requestDashboard(2)

    // One reusable inline row element, declared once and instantiated
    // three times, following 18-08's own one-element-three-instances shape
    // in SystemCapsule.qml so the two files read alike.
    component ResourceRow: Item {
        id: resourceRow

        property string glyph: ""
        property string label: ""
        property string metricState: "empty"
        property real fraction: 0
        property string valueText: ""
        property string detailText: ""

        width: parent ? parent.width : 0
        implicitHeight: rowColumn.implicitHeight
        height: implicitHeight

        Column {
            id: rowColumn
            width: parent.width
            spacing: Design.spacingXs

            Item {
                width: parent.width
                height: Design.iconSizeMd

                Text {
                    id: rowGlyph
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: Design.symbolFontFamily
                    font.pixelSize: Design.iconSizeMd
                    textFormat: Text.PlainText
                    text: resourceRow.glyph
                    color: Colours.onSurfaceVariant
                }
                Text {
                    anchors.left: rowGlyph.right
                    anchors.leftMargin: Design.spacingSm
                    anchors.verticalCenter: parent.verticalCenter
                    textFormat: Text.PlainText
                    text: resourceRow.label
                    font.pixelSize: Design.fontBody
                    color: Colours.onSurface
                }
                // Not yet sampled — no fill at all, and the value renders
                // as an em-dash: a track filled to nothing is a claim
                // about the machine, an empty track beside an em-dash is
                // an admission about the shell, and they look similar
                // enough that the next person to "simplify" this branch
                // will collapse them. The pending value is tinted with the
                // accent role, which the frame's own state mapping already
                // assigns to the not-yet-resolved state.
                Text {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    textFormat: Text.PlainText
                    text: resourceRow.metricState === "populated" ? resourceRow.valueText : "—"
                    font.pixelSize: Design.fontBody
                    color: resourceRow.metricState === "populated" ? Colours.onSurface
                        : resourceRow.metricState === "pending" ? Colours.primary
                        : Colours.onSurfaceVariant
                }
            }

            Item {
                width: parent.width
                height: 4

                Rectangle {
                    anchors.fill: parent
                    radius: height / 2
                    color: Colours.surfaceVariant
                }
                // Real value only — the fill spans the fraction. Both
                // pending and nothing-here render the same empty track
                // (zero width), never a track filled to zero.
                Rectangle {
                    width: resourceRow.metricState === "populated" ? parent.width * Math.max(0, Math.min(1, resourceRow.fraction)) : 0
                    height: parent.height
                    radius: height / 2
                    color: Colours.primary
                }
            }

            Text {
                visible: resourceRow.metricState === "populated" && resourceRow.detailText.length > 0
                textFormat: Text.PlainText
                text: resourceRow.detailText
                font.pixelSize: Design.fontLabel
                color: Colours.onSurfaceVariant
            }
        }
    }

    // Declared in this fixed order — CPU, Memory, Storage — and never
    // sorted. No GPU, no network-rate and no temperature/frequency value
    // is read here: they are the Performance tab's own rows and the foot
    // link is where they live.
    Column {
        width: parent.width
        spacing: Design.spacingSm

        ResourceRow {
            glyph: "memory"
            label: "CPU"
            metricState: root._cpuState
            fraction: root.systemResources ? root.systemResources.cpuFraction : 0
            valueText: root._cpuValueText
        }
        ResourceRow {
            glyph: "memory_alt"
            label: "Memory"
            metricState: root._memoryState
            fraction: root.systemResources ? root.systemResources.memoryFraction : 0
            valueText: root._memoryValueText
            detailText: root._memoryDetailText
        }
        ResourceRow {
            glyph: "hard_drive_2"
            label: "Storage"
            metricState: root._storageState
            fraction: root.systemResources ? root.systemResources.storageFraction : 0
            valueText: root._storageValueText
            detailText: root._storageDetailText
        }
    }
}
