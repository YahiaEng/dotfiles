// LauncherCapsule.qml — the launcher slot (Phase 18 Plan 05, D-18-10).
//
// Owner: 18-11 — D-18-01's 8-icon app-launcher drawer, which expands
// inward horizontally in vertical orientation per D-18-11.
// Entries BarEntryModel already declares for this capsule: `apps`.
//
// ── 18-11 fills this slot. Four facts a later reader would otherwise
//    re-litigate: ──────────────────────────────────────────────────────
// (a) The seven applications below are carried forward VERBATIM from the
//     retired bar's own launcher group — a design-lineage list, not a
//     curated one. Adding or removing one is a design decision, not a
//     maintenance edit.
// (b) Icons are resolved from the desktop-entry database and themed by
//     the session icon theme — this is the redesign half of D-18-01. The
//     retired bar used brand glyphs baked into one font, which could
//     never follow an icon-theme switch; this can.
// (c) The launch command is built from repo literals; the desktop-entry
//     database is read for presentation only (icon + name), never for
//     command construction.
// (d) Expansion is HOVER-driven as of Phase 18.1 Plan 05 (D-16/D-17/D-18),
//     replacing the click toggle this file originally shipped. Both hover
//     sources (the trigger cell and the drawer strip) report through the
//     single `reportDrawerHover` entry point below, so exactly one
//     implementation of the hover contract exists in this file — never a
//     second, unlatched hover trigger, which is exactly the bug D-18-19
//     warned against under the prior click-driven design.
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import "../"
import "../dashboard"

BarCapsule {
    id: launcherCapsule
    capsuleId: "launcher"

    // 14-02's recorded per-file capability flag — Design.qml's own header
    // note records this is deliberately not a shared token, since it is a
    // claim about the font build rather than a design token.
    readonly property bool fillAxisAvailable: true

    // The one place any application identifier appears in this file.
    // Order and identifiers verbatim from the retired bar's own launcher
    // group. `desktopId` carries the desktop-entry suffix because it
    // doubles as the launch argument (D-09's `uwsm app -- <id>.desktop`
    // convention); LauncherCell strips that suffix before resolving the
    // icon, see the comment beside that lookup below.
    readonly property var appEntries: [
        { id: "zen", desktopId: "zen.desktop", label: "Zen Browser" },
        { id: "spotify", desktopId: "spotify.desktop", label: "Spotify" },
        { id: "discord", desktopId: "discord.desktop", label: "Discord" },
        { id: "steam", desktopId: "steam.desktop", label: "Steam" },
        { id: "lutris", desktopId: "net.lutris.Lutris.desktop", label: "Lutris" },
        { id: "obsidian", desktopId: "obsidian.desktop", label: "Obsidian" },
        { id: "codium", desktopId: "codium.desktop", label: "VSCodium" }
    ]

    // The shared cell pitch: Design.iconSizeMd (24) of icon centred
    // inside Design.spacingXs (4) of padding on every side, giving the
    // same 32x32 cell the tray and the workspace capsule use, so every
    // icon on this bar shares one pitch.
    readonly property int cellPitch: Design.iconSizeMd + Design.spacingXs * 2

    // ── The public drawer seam — the hover contract below (Phase 18.1
    //    Plan 05, D-16/D-17/D-18) is the one and only implementation
    //    driving these three names. ─────────────────────────────────────
    property bool expanded: false
    function requestExpand() {
        launcherCapsule.expanded = true;
    }
    function requestCollapse() {
        launcherCapsule.expanded = false;
    }

    // The extent the expanded strip needs on the bar's cross axis if it
    // renders as a single row of cells — the contract the flagged 18-05
    // scope correction (see this plan's `## Scope correction required`)
    // consumes, whichever of its two options is taken. Computed from the
    // cell count and pitch, not hard-coded.
    readonly property int expandedCrossExtent: launcherCapsule.appEntries.length * launcherCapsule.cellPitch + (launcherCapsule.appEntries.length - 1) * Design.spacingXs

    // ── Hover-reveal (Phase 18.1 Plan 05, D-16/D-17/D-18) — the drawer's
    //    ONE hover contract. Both hover sources (the trigger cell and the
    //    drawer strip, wired below) report through `reportDrawerHover`
    //    into the same `drawerHoverActive` boolean, so the pointer
    //    travelling from the trigger to the strip never reads as a clean
    //    exit — a per-surface boolean would defeat the grace timer below
    //    before it ever ran. The settledness read below reads Bar.qml's
    //    own live rendered/transitioning state through the shared
    //    `QsWindow.window` handle (the same reachable path
    //    `barIdleInhibitor`'s `window: QsWindow.window` binding already
    //    proves live in ClockActionsCapsule.qml) — deliberately NOT the
    //    reveal-machine singleton's own dead settled latch (D-26 fences
    //    that one out by name). This file writes to no reveal-machine
    //    state at all: the bar's own whole-content hover handler already
    //    spans the area the drawer expands inside, so the bar's own
    //    re-hide grace already covers an open drawer with zero new
    //    wiring. ────────────────────────────────────────────────────────
    property bool _triggerHovered: false
    property bool _stripHovered: false
    property bool drawerHoverActive: false
    function reportDrawerHover(source, entered) {
        if (source === "trigger")
            launcherCapsule._triggerHovered = entered;
        else if (source === "strip")
            launcherCapsule._stripHovered = entered;
        launcherCapsule.drawerHoverActive = launcherCapsule._triggerHovered || launcherCapsule._stripHovered;
    }

    readonly property bool drawerSettled: QsWindow.window ? (QsWindow.window.barRendered && !QsWindow.window.barTransitionRunning) : false

    onDrawerHoverActiveChanged: {
        if (launcherCapsule.drawerHoverActive) {
            drawerGraceTimer.stop();
            drawerDwellTimer.restart();
        } else {
            drawerDwellTimer.stop();
            drawerGraceTimer.restart();
        }
    }

    // A drawer that survived into a hidden bar would reappear expanded on
    // the next reveal — QBAR-07's boundary case. Collapse immediately,
    // with no grace, the moment the bar stops being settled.
    onDrawerSettledChanged: {
        if (!launcherCapsule.drawerSettled && launcherCapsule.expanded) {
            drawerDwellTimer.stop();
            drawerGraceTimer.stop();
            launcherCapsule.requestCollapse();
        }
    }

    Timer {
        id: drawerDwellTimer
        interval: Design.popoutDwellMs
        repeat: false
        onTriggered: {
            // Re-evaluated at FIRE time, not only at arm time: a dwell
            // armed while the bar was up must not open a drawer into a
            // bar that began hiding moments later.
            if (launcherCapsule.drawerHoverActive && launcherCapsule.drawerSettled)
                launcherCapsule.requestExpand();
        }
    }

    Timer {
        id: drawerGraceTimer
        interval: Design.popoutDismissGraceMs
        repeat: false
        onTriggered: {
            if (!launcherCapsule.drawerHoverActive)
                launcherCapsule.requestCollapse();
        }
    }

    // ── One drawer cell — the tray's own cell geometry, reused. ────────
    component LauncherCell: Item {
        id: cellItem
        width: launcherCapsule.cellPitch
        height: launcherCapsule.cellPitch

        property var entry: ({})

        // Step 1: resolve the desktop entry. Quickshell's DesktopEntries
        // byId lookup wants the BARE identifier with no trailing suffix —
        // resolved empirically this plan (a throwaway `qs -p` probe run
        // against the installed quickshell 0.3.0-2: looking up the bare
        // seven-entry set returned the real entry for every one — id,
        // name and icon all populated — while looking up any of the
        // seven WITH its desktop-entry suffix attached returned null for
        // all seven). `entry.desktopId` keeps that suffix because it
        // also doubles as the launch argument below, so it is stripped
        // right here rather than
        // carrying two separate identifier fields. Reading
        // `DesktopEntries.applications.values.length`, even though the
        // value itself is unused, is what makes this binding re-evaluate
        // once the entry database's own async scan completes shortly
        // after shell start (also proven live this plan: the model holds
        // zero entries for roughly a second at process start) — without
        // that read this expression would freeze at whatever had been
        // indexed at binding-creation time.
        readonly property var resolvedEntry: {
            DesktopEntries.applications.values.length;
            const bareId = cellItem.entry.desktopId ? cellItem.entry.desktopId.replace(/\.desktop$/, "") : "";
            const byIdResult = DesktopEntries.byId(bareId);
            if (byIdResult)
                return byIdResult;
            return DesktopEntries.heuristicLookup(cellItem.entry.label);
        }

        // Step 2: resolve the icon — the checking form of iconPath()
        // returns an empty string when the icon is not installed.
        readonly property string resolvedIconPath: cellItem.resolvedEntry ? Quickshell.iconPath(cellItem.resolvedEntry.icon, true) : ""

        // Step 3: the fallback. Every step above is guarded and none
        // assumes the previous one succeeded — a null entry, an empty
        // icon path, or an IconImage error status all resolve here.
        readonly property bool resolved: cellItem.resolvedEntry !== null && cellItem.resolvedIconPath !== "" && cellIcon.status !== Image.Error

        IconImage {
            id: cellIcon
            anchors.centerIn: parent
            implicitSize: Design.iconSizeMd
            asynchronous: true
            source: cellItem.resolvedIconPath
            visible: cellItem.resolved
        }

        // The one placeholder this bar uses for a broken icon — the same
        // Material Symbol the tray uses for an unresolved pixmap and the
        // workspace capsule uses for an unresolvable window (UI-SPEC is
        // explicit that this bar has one placeholder glyph, not three
        // conventions). The cell is never blank and never a hit target
        // with no visual.
        Text {
            anchors.centerIn: parent
            visible: !cellItem.resolved
            text: "apps"
            font.family: Design.symbolFontFamily
            font.pixelSize: Design.iconSizeMd
            color: launcherCapsule.contentColour
        }

        // Fixed four-element argv — the launcher wrapper, its
        // subcommand, the argument separator, and this cell's own
        // `desktopId` literal (D-09's GUI-app convention). Nothing read
        // from the desktop-entry database ever reaches this array.
        Process {
            id: launchProcess
            command: ["uwsm", "app", "--", cellItem.entry.desktopId]
        }

        MouseArea {
            id: cellMouseArea
            anchors.fill: parent
            hoverEnabled: true
            ToolTip.visible: cellMouseArea.containsMouse
            ToolTip.text: cellItem.entry.label
            ToolTip.delay: Design.tooltipDelayMs
            onClicked: {
                // Every one of these seven applications takes focus, and
                // a lifetime-bound child would be killed the moment
                // requestCollapse() below re-lays this capsule — the
                // recorded detached-launch-vs-lifetime-bound regression
                // this repo has already paid for once.
                launchProcess.startDetached();
                launcherCapsule.requestCollapse();
            }
        }
    }

    // ── Capsule content — one positioner (BarCapsule's own content
    //    Grid, reached through its default property), so there is no
    //    second arrangement. ─────────────────────────────────────────

    // The trigger cell — always present, toggles the drawer.
    Item {
        id: triggerCell
        width: launcherCapsule.cellPitch
        height: launcherCapsule.cellPitch

        Text {
            id: triggerGlyph
            anchors.centerIn: parent
            text: "apps"
            font.family: Design.symbolFontFamily
            font.pixelSize: Design.iconSizeMd
            // Reuses BarCapsule.iconFill's tab-bar active-state
            // convention rather than inventing a second active language:
            // filled while the drawer is open.
            font.variableAxes: launcherCapsule.fillAxisAvailable ? { "FILL": launcherCapsule.expanded ? 1 : 0 } : ({})
            color: launcherCapsule.contentColour
        }

        HoverHandler {
            id: triggerHoverHandler
            onHoveredChanged: launcherCapsule.reportDrawerHover("trigger", triggerHoverHandler.hovered)
        }
    }

    // The strip — a Repeater over appEntries inside one axis-bound Grid,
    // the same rows/columns formula BarCapsule uses internally, never a
    // Row/Column pair. Horizontal orientation: the strip grows along the
    // bar's own axis inside the bar window — the true drawer, complete
    // here. Vertical orientation: D-18-11 wants an inward-horizontal
    // strip growing leftward over the desktop, which this window cannot
    // host (18-05 pinned the vertical window's extent to
    // Design.barColumnWidth, and a layer-shell surface does not render
    // outside its own buffer) — see this plan's `## Scope correction
    // required`. Until that correction lands, this file's own strip
    // expands along the column instead (rows/columns bound to `vertical`
    // exactly as below), the acknowledged, named fallback rather than a
    // silent one.
    Item {
        id: stripHost
        clip: true
        width: launcherCapsule.vertical ? launcherCapsule.cellPitch : (launcherCapsule.expanded ? launcherCapsule.expandedCrossExtent : 0)
        height: launcherCapsule.vertical ? (launcherCapsule.expanded ? launcherCapsule.expandedCrossExtent : 0) : launcherCapsule.cellPitch

        // Asymmetric in/out — this repo's quick-to-leave grammar, reused
        // rather than invented, for every dismissible surface's own
        // expand/collapse.
        Behavior on width {
            enabled: Motion.motionEnabled
            NumberAnimation {
                duration: launcherCapsule.expanded ? Motion.emphasizedInDuration : Motion.emphasizedOutDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: launcherCapsule.expanded ? Motion.emphasizedInEasing : Motion.emphasizedOutEasing
            }
        }
        Behavior on height {
            enabled: Motion.motionEnabled
            NumberAnimation {
                duration: launcherCapsule.expanded ? Motion.emphasizedInDuration : Motion.emphasizedOutDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: launcherCapsule.expanded ? Motion.emphasizedInEasing : Motion.emphasizedOutEasing
            }
        }

        HoverHandler {
            id: stripHoverHandler
            onHoveredChanged: launcherCapsule.reportDrawerHover("strip", stripHoverHandler.hovered)
        }

        Grid {
            id: stripGrid
            anchors.fill: parent
            rows: launcherCapsule.vertical ? -1 : 1
            columns: launcherCapsule.vertical ? 1 : -1
            spacing: Design.spacingXs

            Repeater {
                model: launcherCapsule.appEntries
                delegate: LauncherCell {
                    entry: modelData
                }
            }
        }
    }
}
