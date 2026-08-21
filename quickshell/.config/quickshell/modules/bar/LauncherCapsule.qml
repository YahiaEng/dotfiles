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
    // The trigger cell's own scene-space centre along the bar's long axis
    // — BarDrawer.qml's `triggerCentre` contract, published ONCE per
    // expand rather than a live binding, the same PopoutTrigger.qml
    // publishAnchor() discipline SectionPopout.qml's own triggerCentre
    // documents (scene mapping does not re-evaluate when an ancestor
    // moves, so a binding would go stale silently).
    property real _publishedDrawerCentre: 0
    function publishDrawerAnchor() {
        launcherCapsule._publishedDrawerCentre = triggerCell.mapToItem(null, 0, 0).y + triggerCell.height / 2;
    }
    function requestExpand() {
        // Published before `expanded` is set true, so both the dwell
        // path and any direct caller publish a fresh centre.
        launcherCapsule.publishDrawerAnchor();
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
    //    proves live in IdleInhibitorCapsule.qml) — deliberately NOT the
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
        interval: Design.barDrawerDwellMs
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
        interval: Design.barDrawerGraceMs
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

        // F2 (quick task 260812-69w) — see IdleInhibitorCapsule.qml's own
        // comment for the measured clamp this replaces. `tipId` is keyed
        // off desktopId so each of the seven live LauncherCell instances
        // resolves to its own distinct namespace, never a collision.
        BarTooltipHost {
            anchorItem: cellItem
            text: cellItem.entry.label
            active: cellMouseArea.containsMouse
            tipId: "launcher-" + cellItem.entry.desktopId
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
    // here. Vertical orientation: hosted by BarDrawer.qml instead (18-11's
    // Option B, taken by quick task 260812-59l, see the LazyLoader below),
    // because a layer-shell surface cannot render outside its own buffer
    // and Bar.qml pins the vertical window to Design.barColumnWidth — this
    // Item contributes nothing (both dimensions resolve to 0) and its
    // seven cells are destroyed, not merely clipped, whenever
    // launcherCapsule.vertical is true.
    Item {
        id: stripHost
        clip: true
        width: launcherCapsule.vertical ? 0 : (launcherCapsule.expanded ? launcherCapsule.expandedCrossExtent : 0)
        height: launcherCapsule.vertical ? 0 : launcherCapsule.cellPitch

        // GATE-02 round 4: a GTK Revealer slide is one ease-out curve, both
        // directions, not this repo's semantic-motion emphasizedIn/Out
        // bezier pair (that pairing is tuned for panel/dialog reveals and
        // its acceleration is what the operator reported as "not smooth").
        // quick-260821-swp (R-2b): the hardcoded `Design.barDrawerEasingType`
        // (Easing.OutCubic) that used to serve this — a Qt enum with no
        // bezier array, structurally unreachable by the style axis and
        // invisible to any scan of bezier bindings — is retired in favour of
        // `Motion.spatialMoveEasing`, bringing the four bar drawers onto
        // Motion tokens for the first time. Horizontal-only now, but left
        // exactly as it was: this Behavior pair only ever animated the
        // horizontal-orientation width/height shape (vertical's own
        // width/height are now a bare 0 above, not a second animated
        // branch).
        Behavior on width {
            enabled: Motion.motionEnabled
            NumberAnimation {
                duration: Design.barDrawerTransitionMs
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.spatialMoveEasing
            }
        }
        Behavior on height {
            enabled: Motion.motionEnabled
            NumberAnimation {
                duration: Design.barDrawerTransitionMs
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.spatialMoveEasing
            }
        }

        HoverHandler {
            id: stripHoverHandler
            onHoveredChanged: launcherCapsule.reportDrawerHover("strip", stripHoverHandler.hovered)
        }

        // Gated behind `!vertical` so the seven cells below are destroyed
        // in vertical orientation rather than merely clipped — the same
        // zero-idle-cost discipline BarDrawer.qml's own LazyLoader applies
        // to the surface that replaces this Grid there. `sourceComponent`
        // used explicitly (this repo's own convention for a plain
        // QtQuick.Loader — see Dashboard.qml's dashboardTabLoader — rather
        // than relying on a bare child becoming the implicit component).
        Loader {
            id: stripGridLoader
            anchors.fill: parent
            active: !launcherCapsule.vertical
            asynchronous: false

            sourceComponent: Component {
                Grid {
                    id: stripGrid
                    anchors.fill: parent
                    rows: 1
                    columns: -1
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

                            // GATE-02 round 4: a GTK Revealer never staggers or
                            // fades its children individually and never translates
                            // them on the cross axis — it is a single clip-based
                            // slide of the CONTAINER, full stop. The former
                            // per-cell opacity stagger (PauseAnimation keyed off
                            // cellSlot.index) ran ON TOP of the 650ms container
                            // animation above, which is what made the drawer take
                            // far longer than Athena's 650ms to finish opening —
                            // the operator's "slow" report. The former Translate's
                            // cross-axis `y` offset is what made a cell (and, in
                            // MediaConnectivityCapsule's sibling drawers, the
                            // trigger) visibly shift on hover — removed outright,
                            // not just zeroed, since a Translate left at y:0 is
                            // still a per-frame transform Athena's own drawer has
                            // no equivalent of. The stripHost's own clip:true is
                            // what reveals this cell now — exactly like a Revealer.
                            LauncherCell {
                                anchors.fill: parent
                                entry: launcherCapsule.appEntries[cellSlot.index]
                            }
                        }
                    }
                }
            }
        }
    }

    // ── Vertical-orientation drawer host (18-11's Option B, D-18-11,
    //    quick task 260812-59l, closing GATE-02 row B.4-DRAWER) — the
    //    shared BarDrawer type, mounted behind a LazyLoader keyed on
    //    `vertical && expanded` (shell.qml's own default-property idiom,
    //    D-18-24's create/destroy shape), so it costs nothing while
    //    collapsed or in horizontal orientation. `reportDrawerHover` is
    //    the sole hover relay (D-18-19) — no second dwell or grace timer
    //    is added here. Reuses LauncherCell (this file's own inline
    //    component, reachable inside this loaded block) with the same
    //    plain-Item delegate wrapper the horizontal strip above uses. ───
    LazyLoader {
        id: verticalDrawerLoader
        active: launcherCapsule.vertical && launcherCapsule.expanded

        BarDrawer {
            drawerId: "launcher"
            crossExtent: launcherCapsule.expandedCrossExtent
            cellPitch: launcherCapsule.cellPitch
            triggerCentre: launcherCapsule._publishedDrawerCentre
            onHoveredChanged: launcherCapsule.reportDrawerHover("strip", hovered)

            Repeater {
                model: launcherCapsule.appEntries.length
                delegate: Item {
                    id: verticalCellSlot
                    required property int index
                    width: launcherCapsule.cellPitch
                    height: launcherCapsule.cellPitch

                    LauncherCell {
                        anchors.fill: parent
                        entry: launcherCapsule.appEntries[verticalCellSlot.index]
                    }
                }
            }
        }
    }
}
