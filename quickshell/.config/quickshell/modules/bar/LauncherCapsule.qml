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
// (b) Icons are per-app Nerd Font GLYPHS carried in `appEntries` below,
//     copied from Athena's own `custom/app-*` format fields. D-18-01's
//     redesign half resolved them from the desktop-entry database so they
//     would follow an icon-theme switch; the operator rejected that at
//     GATE-02 because apps with weak or absent themed icons fell back to
//     generic ones. Reverted to Athena's fixed-glyph approach in the 18.1
//     gap closure, accepting that these do not follow an icon-theme change.
// (c) The launch command is built from repo literals. The desktop-entry
//     database is no longer read at all in this file — the lookup chain
//     existed only to find an icon.
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
// Quickshell.Widgets (IconImage) dropped with the icon-theme resolution chain — GATE-02 defect 4.
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
    // group. `desktopId` carries the desktop-entry suffix because it is the
    // launch argument (D-09's `uwsm app -- <id>.desktop` convention) — it is
    // no longer stripped for an icon lookup, because there is no lookup.
    //
    // `glyph` carries Athena's OWN per-app Nerd Font codepoint, read
    // straight out of config-athena.jsonc's `custom/app-*` format fields
    // (GATE-02 defect 4). D-18-01's "redesign half" resolved each cell's
    // icon from the session icon theme instead, so that it would follow an
    // icon-theme switch. The operator rejected the result at GATE-02: apps
    // whose themed icon is weak or absent fell back to a generic icon, and
    // a drawer of mismatched stock icons reads worse than a coherent glyph
    // row. Athena's fix — a fixed app list where each entry carries its own
    // glyph — is restored here. The trade-off is now the stated one: these
    // glyphs do NOT follow an icon-theme change, which is the same
    // trade-off Athena itself makes and the one the operator chose.
    readonly property string appGlyphFontFamily: "FiraCode Nerd Font"
    readonly property var appEntries: [
        { id: "zen", desktopId: "zen.desktop", label: "Zen Browser", glyph: "\u{f269}" },
        { id: "spotify", desktopId: "spotify.desktop", label: "Spotify", glyph: "\u{f1bc}" },
        { id: "discord", desktopId: "discord.desktop", label: "Discord", glyph: "\u{f1ff}" },
        { id: "steam", desktopId: "steam.desktop", label: "Steam", glyph: "\u{f1b6}" },
        { id: "lutris", desktopId: "net.lutris.Lutris.desktop", label: "Lutris", glyph: "\u{f11b}" },
        { id: "obsidian", desktopId: "obsidian.desktop", label: "Obsidian", glyph: "\u{f0e55}" },
        { id: "codium", desktopId: "codium.desktop", label: "VSCodium", glyph: "\u{f0a1e}" }
    ]

    // The shared cell pitch: Design.barGlyphSize (16, Athena's glyph size)
    // centred inside Design.spacingXs (4) of padding on every side — a 24px
    // cell. Derived, never hard-coded, so it tracked the 24->16 glyph
    // correction in the 18.1 gap closure automatically. The workspace
    // capsule's icon cells share the same barGlyphSize, so every glyph on
    // this bar still shares one pitch.
    readonly property int cellPitch: Design.barGlyphSize + Design.spacingXs * 2

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

        // The cell's glyph comes from its own appEntries row — Athena's
        // literal codepoint — so there is no icon resolution to fail and no
        // generic-icon fallback to look wrong (GATE-02 defect 4). The
        // DesktopEntries byId/heuristicLookup chain that used to live here
        // existed ONLY to find an icon; `desktopId` is passed straight to
        // the launch argv below and never needed the database, so removing
        // the chain drops a per-scan re-evaluation with no behaviour left
        // to preserve.
        //
        // The placeholder branch is gone with it, deliberately: a fixed
        // literal list cannot produce an unresolved cell, so a fallback
        // here would be unreachable code asserting a failure mode that no
        // longer exists. A missing glyph is now a font problem (the family
        // below), which shows as tofu and is a visible, diagnosable state
        // rather than a silently-substituted stock icon.
        Text {
            anchors.centerIn: parent
            text: cellItem.entry.glyph ?? ""
            font.family: launcherCapsule.appGlyphFontFamily
            font.pixelSize: Design.barGlyphSize
            // Athena's own drawer-member rule: @capsule-fg at rest, @accent
            // on hover (style-athena.scss:93 and :106). Read directly off
            // BarRoles rather than through the capsule's contentColour,
            // because this is a per-CELL state — the capsule-wide content
            // colour cannot express "this one cell is under the pointer".
            color: cellMouseArea.containsMouse ? BarRoles.accent : BarRoles.capsuleFg

            Behavior on color {
                enabled: Motion.motionEnabled
                ColorAnimation {
                    duration: Motion.standardDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.standardEasing
                }
            }
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
            font.pixelSize: Design.barGlyphSize
            // Reuses BarCapsule.iconFill's tab-bar active-state
            // convention rather than inventing a second active language:
            // filled while the drawer is open.
            font.variableAxes: launcherCapsule.fillAxisAvailable ? { "FILL": launcherCapsule.expanded ? 1 : 0 } : ({})
            // Athena colours the app-launcher trigger glyph @accent
            // unconditionally, not as a state indicator (style-athena.scss:81)
            // — this is a permanent accent glyph, so no ternary.
            color: BarRoles.accent
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
                // The delegate root is a PLAIN Item, not LauncherCell itself.
                // Repeater injects `index`/`modelData` into a plain delegate
                // root, but NOT into an inline component (`component
                // LauncherCell: Item`) used as the root — verified live: a
                // diagnostic in the old shape logged
                // `index=undefined typeof=undefined entryKeys=[] modelLen=7`,
                // i.e. the model held all seven rows and none of them reached
                // a cell. That is GATE-02 defect 4's real cause: `entry` sat at
                // its `({})` default for every cell, so all seven resolved
                // identically to one fallback. Wrapping the component in a
                // plain Item and indexing appEntries explicitly is what
                // actually delivers the data.
                model: launcherCapsule.appEntries.length
                delegate: Item {
                    id: cellSlot
                    required property int index
                    width: launcherCapsule.cellPitch
                    height: launcherCapsule.cellPitch

                    LauncherCell {
                        anchors.fill: parent
                        entry: launcherCapsule.appEntries[cellSlot.index]

                        // GATE-02 defect 3 — "expansion works but it is very
                        // clunky and sudden". The container's width/height
                        // Behaviors were already animating, but the cells inside
                        // popped in at full opacity the instant the strip had
                        // any width, so the reveal snapped regardless of how
                        // smooth the container curve was. Each cell now fades
                        // and rises into place, staggered by index.
                        //
                        // Stagger step is emphasizedIn/6 so the LAST cell still
                        // lands inside the container's own animation window
                        // rather than trailing after the drawer has opened.
                        opacity: launcherCapsule.expanded ? 1 : 0
                        transform: Translate {
                            y: launcherCapsule.expanded ? 0 : Design.spacingXs
                        }

                        Behavior on opacity {
                            enabled: Motion.motionEnabled
                            SequentialAnimation {
                                // Only opening staggers; closing leaves at once
                                // — this repo's quick-to-leave grammar, the same
                                // asymmetry the container Behaviors use.
                                PauseAnimation {
                                    duration: launcherCapsule.expanded ? cellSlot.index * Math.round(Motion.emphasizedInDuration / 6) : 0
                                }
                                NumberAnimation {
                                    duration: launcherCapsule.expanded ? Motion.emphasizedInDuration : Motion.emphasizedOutDuration
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: launcherCapsule.expanded ? Motion.emphasizedInEasing : Motion.emphasizedOutEasing
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
