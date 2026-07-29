// Dial.qml — inert circular-dial stub (Phase 14 Plan 03, filled by Plan
// 14-06, D-36/D-39: the percent-of-capacity circular gauge used by
// Performance's four dials and Dashboard's resources strip — genuinely
// custom QtQuick.Shapes/Canvas work, since no built-in circular-gauge
// component exists anywhere in Qt/Quickshell — 14-RESEARCH.md's "Don't
// Hand-Roll" table confirms this and flags it as real budgeted work, not a
// missed built-in).
//
// Root type Item. Not mounted by this plan — 14-06 uses this inside
// PerformanceTab (and 14-08 inside DashboardTab's resources strip). May
// declare its own implicit size once the arc geometry exists; left
// completely unsized in stub form.
//
// D-41 widget-state register — "populated" / "pending" / "empty" — carried
// on every one of this phase's nine modules/dashboard/ files.
import QtQuick

Item {
    id: root

    // D-41: "populated" | "pending" | "empty"
    property string widgetState: "empty"
}
