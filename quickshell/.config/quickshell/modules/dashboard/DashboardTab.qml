// DashboardTab.qml — tab 0 shell (Phase 14 Plan 03, filled by Plan 14-04,
// D-38: identity-first single column — clock/date hero, calendar, compact
// media, resources strip, toggle footer).
//
// Root type Item, filled via anchors.fill: parent by the Loader Dashboard.qml
// places it in — actual rendered geometry is UNCHANGED from Task 2 (still
// anchors.fill: parent, so this item always matches whatever size its Loader
// currently has, including mid-resize-animation).
//
// `implicitWidth`/`implicitHeight` below are D-04's "no implicit size"
// prohibition DELIBERATELY REVERSED at this plan's render gate (checkpoint
// feedback 2026-07-29, see 14-03-SUMMARY.md's Deviations): Dashboard.qml
// reads these as an advisory hint to compute the drawer's own animated frame
// target — a pure metadata read, independent of this item's actual rendered
// size above. This is the single content-heaviest tab (clock/date hero +
// calendar + compact media + resources strip + toggle footer stacked in one
// column), so its placeholder footprint is the tallest of the four; 14-04
// replaces these numbers with a value derived from its real column's own
// natural size once built.
//
// D-41 widget-state register — every one of this phase's nine
// modules/dashboard/ files carries this same three-name vocabulary
// ("populated" / "pending" / "empty") so 14-04 fills in real transitions
// rather than inventing a vocabulary per widget. This stub only ever shows
// the "empty" branch.
//
// Property contract this plan declares so 14-04/14-08 never have to touch
// Dashboard.qml themselves: `mediaBackend`/`systemResources` are typed `var`
// rather than a concrete type so this stub compiles before the backends have
// any real surface — the owning plan may narrow the type once one exists.
// `mediaTabIndex`/`performanceTabIndex` exist so the compact media widget and
// resources strip (14-08) deep-link by a named index rather than a magic
// number; `tabRequested` is the deep-link signal itself — the
// compact-widget → its-full-tab convention D-39/D-40 establish and Phase 15
// inherits. Dashboard.qml's Task 2 answers this signal with
// `pager.setCurrentIndex(index)`.
import QtQuick
// Relative directory import to modules/ (parent) — the same mechanism
// shell.qml's own `import "modules"` uses, resolving Colours/Motion off
// that directory's checked-in qmldir. The dotted `qs.modules` module
// identifier in that qmldir is a name, not a registered import path in
// this tree, so every consumer in this repo reaches those singletons via a
// relative directory import rather than `import qs.modules`.
import "../"

Item {
    id: root

    anchors.fill: parent

    // Placeholder content-driven size hint (D-04 superseded) — read by
    // Dashboard.qml's activeContentWidth/activeContentHeight, not by this
    // item's own actual geometry above.
    implicitWidth: 960
    implicitHeight: 460

    // D-41: "populated" | "pending" | "empty" — the state vocabulary every
    // widget in this module carries. This stub is permanently "empty" until
    // 14-04 fills real transitions.
    property string widgetState: "empty"

    // ── Property contract 14-04/14-08 consume ───────────────────────────
    property var mediaBackend: null
    property var systemResources: null
    property int mediaTabIndex: -1
    property int performanceTabIndex: -1

    // Deep-link signal — 14-08's compact media widget and resources strip
    // emit this with a named tab index; Dashboard.qml's Task 2 answers it
    // with pager.setCurrentIndex(index).
    signal tabRequested(int index)

    // ── D-41 empty branch — the only content this stub ever shows ──────
    Column {
        anchors.centerIn: parent
        spacing: 8

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            horizontalAlignment: Text.AlignHCenter
            text: "Dashboard\nNot built yet — plan 14-04"
            font.pixelSize: 16
            color: Colours.onSurfaceVariant
        }
    }
}
