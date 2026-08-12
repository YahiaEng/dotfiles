// ClockActionsCapsule.qml — the clock + actions slot (Phase 18 Plan 05,
// D-18-10).
//
// Owner: 18-11 for the four action entries (`gaming`, `notifications`,
// `settings`, `power`) — the two athena drawers plus three of the four
// permanent extras. The fourth, `idleInhibitor`, relocated to its own
// centre-zone capsule under the GATE-02 fix; see note (a) below.
//
// This one is NOT empty: 18-01's live clock moves here intact, carried
// exactly rather than rebuilt — see the SystemClock declaration below.
//
// ── 18-11 fills the rest of this capsule. Three facts a later reader
//    would otherwise re-litigate: ────────────────────────────────────
// (a) The four action entries below are three of D-18-03's four permanent
//     extras (power, gaming, notifications) plus the settings-drawer
//     trigger. The fourth extra, the idle inhibitor, relocated to its own
//     centre-zone capsule (IdleInhibitorCapsule.qml) under the GATE-02
//     upstream-parity fix — upstream Athena places it in modules-center,
//     immediately right of workspaces (ATHENA-UPSTREAM-SPEC.md), not
//     beside clock/settings on the right. The bulb's backend (the
//     `IdleInhibitor` element and `idleInhibited` property) moved with it;
//     nothing of it remains in this file. The other extra pair's half —
//     the updates count — still lives in the system capsule (18-08),
//     because 18-05's entry list split that pair by kind (readout vs
//     action), not by pairing.
// (b) The notification binding is deliberately temporary and is sealed
//     behind one named component (`NotificationSource` below) so that
//     Phase 19 replaces a backend rather than re-opening a layout that
//     has already passed a render gate.
// (c) This capsule adds exactly one permanent child process to a surface
//     that never unmounts — the notification subscription inside
//     `NotificationSource` — named in source as a charge against QBAR-11
//     that ends when that swap lands.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../"
import "../dashboard"

BarCapsule {
    id: clockActionsCapsule
    capsuleId: "clockActions"

    // Uniform right-side pitch. Every cell here already carries cellPitch's
    // own spacingXs padding on each side, so a contentGap of spacingSm (8)
    // renders a 16px glyph-to-glyph gap — the SAME 16px barCapsuleGap puts
    // between two capsules, which is what makes the whole right side read as
    // one evenly-spaced row instead of tight clusters with wide seams.
    //
    // spacingXs (4) was tried first, to mirror upstream's `margin: 4px 2px` on
    // these glyphs literally. That is correct upstream, where each glyph is its
    // own module inside a surfaced group; here the capsule is bare and its
    // neighbours sit 16px away, so a 4px internal gap made the actions clump.
    // The operator reported the result as unevenly spaced.
    contentGap: Design.spacingSm

    readonly property string homeDir: Quickshell.env("HOME")

    // 14-02's recorded per-file capability flag — Design.qml's own header
    // note records this is deliberately not a shared token, since it is a
    // claim about the font build rather than a design token.
    readonly property bool fillAxisAvailable: true

    // Event-driven clock, deliberately NOT a repeating Timer: this
    // surface never unmounts, so a 1Hz (or any repeating) Timer would be
    // a permanent session cost for a value that changes once a minute.
    // SystemClock at Minutes precision wakes exactly once per minute —
    // 18-01's own permanent-liveness discipline, carried unchanged across
    // this move.
    SystemClock {
        id: barClock
        enabled: true
        precision: SystemClock.Minutes
    }

    // ── Popout wrapper (Phase 18 Plan 14, QBAR-09) — named seam into this
    //    18-11-owned file. Ownership split, stated so it is never
    //    discovered at merge time: 18-11 owns the clock cell's own two
    //    Text elements below, unchanged in content and appearance; this
    //    plan owns only the PopoutTrigger wrapper around them and the
    //    nested Grid that reproduces the outer positioner's own spacing so
    //    wrapping the pair changes nothing about the rendered bar. Change
    //    nothing else: not the gaming, notification, settings or power
    //    cells, not the settings drawer, not the entry order, not the
    //    notification source component. ─────────────────────────────────
    PopoutTrigger {
        id: clockPopoutTrigger
        sectionId: "clock"
        popoutComponent: Component {
            ClockPopout {
                currentDate: barClock.date
            }
        }

        // Athena's filled `secondary`-hued clock pill (D-13,
        // theme.scss:127-145's "filled, but fewer" trio — clock, updates,
        // notification). Declared BEFORE clockTriggerGrid so it renders
        // behind the clock's own two Text elements by declaration order,
        // with no MouseArea/HoverHandler of its own — it must never
        // become a hit target, since the clock popout trigger's own
        // click/hover contract lives on clockPopoutTrigger, not on this
        // fill. Deliberately a SIBLING of clockTriggerGrid (both direct
        // children of contentHost, a plain Item, not a Positioner) rather
        // than nested inside the Grid itself — a Grid positioner forbids
        // anchors on its own direct children ("Cannot specify anchors
        // for items inside Grid", caught live in plan 18.1-02). Grid
        // (a Positioner) auto-sizes its own width/height to its content,
        // so anchoring to clockTriggerGrid's real width/height here is
        // safe.
        Rectangle {
            id: clockFillPill
            anchors.centerIn: clockTriggerGrid
            // Upstream Athena states #clock as PADDING around its text
            // (`padding: 6px 10px 6px 16px`), not as a fixed height, so this
            // derives the same way: content + barCapsulePadding (6) per side.
            //
            // Two earlier shapes were wrong and are recorded so neither is
            // retried: `grid.height + spacingSm * 2` came to ~33px inside a
            // 22px content area and overflowed to the bar's bottom edge (the
            // operator's "the time pill looks out of position"); pinning to
            // barCapsuleHeight (34) then sat flush against that edge with no
            // wallpaper gap and still read as cut off. Deriving from padding
            // leaves the 4px gap Athena's own `margin: 4px 5px` produces.
            // Now that this capsule is unsurfaced, this pill IS the visible
            // module, exactly as upstream's #clock is.
            // spacingLg (24) of horizontal padding, i.e. 12 per side. Athena's
            // #clock carries `padding: 6px 10px 6px 16px` — 26 total — and 24 is
            // the nearest value on the repo's 4px grid. This was spacingMd (16,
            // i.e. 8 per side), which hugged the text and is what the operator
            // reported as the clock pill looking compressed.
            width: clockTriggerGrid.width + Design.spacingLg
            height: clockTriggerGrid.height + Design.barCapsulePadding * 2
            radius: clockActionsCapsule.vertical ? width / 2 : height / 2
            color: BarRoles.fillClock
            Behavior on color {
                enabled: Motion.motionEnabled
                ColorAnimation {
                    duration: Motion.standardDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.standardEasing
                }
            }
        }

        // Phantom right-side padding — measured necessity, not decoration.
        // The pill above is now flush with both edges of its own cell (see
        // clockTriggerGrid's own comment), so this cell carries ZERO
        // built-in padding, unlike every ActionCell (gamingCell immediately
        // after this trigger included), which reserves spacingXs (4px) on
        // each side inside its cellPitch box. Two glyphs that are BOTH
        // zero-padded (every MediaConnectivityCapsule Readout pair) need
        // only contentGap to reach the shared 16px visible pitch; two that
        // are BOTH 4px-padded (every ActionCell pair) also reach it at the
        // SAME contentGap because their two 4px insets sum to the other
        // capsule's whole difference. This pill-to-ActionCell pair is the
        // one boundary with only ONE side padded, so it undershot the
        // shared pitch by exactly that missing 4px (measured: 12px visible
        // where every other adjacent pair measured 16px). A non-rendering
        // spacer the width of that one missing inset closes it — reserving
        // cell width with no drawn content, exactly like BarCapsule's own
        // `visible` contract excludes an empty entry's spacing with no
        // extra code, this does the inverse: adds spacing with no visible
        // content.
        Item {
            id: clockCellRightPad
            // Plain Item, no delegate of its own — draws nothing regardless
            // of `visible`, so that property is left at its default (true)
            // rather than set false: childrenRect (what sizes this cell) is
            // a geometry aggregate, not a positioner, and this repo has no
            // verified guarantee it excludes invisible children the way a
            // Positioner does — leaving visible untouched removes any doubt
            // this spacer's width reaches childrenRect at all.
            x: clockFillPill.x + clockFillPill.width
            width: Design.spacingXs
            height: 1
        }

        // Reproduces contentGrid's own spacing/orientation formula exactly
        // (Design.spacingSm), so wrapping these two Text elements in one
        // trigger cell leaves the rendered gap between them, and between
        // this cell and the next, byte-identical to before.
        Grid {
            id: clockTriggerGrid
            // Phase 18.1 spacing-probe task, measured via mapToItem: this
            // Grid sits flush at contentHost's own (0,0) origin by default,
            // but clockFillPill above is centred ON this Grid at a width
            // spacingLg (24) WIDER than it — so with this Grid flush-left,
            // the pill bled spacingLg/2 (12px) out the LEFT edge of its own
            // allocated cell (measured: pill x=2302.6875 against a cell/
            // capsule left edge of 2314.6875) while leaving 12px of dead
            // space unused on the right (measured: pill right edge 2380.0
            // against the cell's own right edge of 2392.0). The left bleed
            // ate directly into the fixed 16px barCapsuleGap before this
            // capsule (leaving only a 4px visible gap to the network glyph);
            // the right dead space widened the gap to the gaming glyph to
            // 20px. This offset re-centres the Grid inside the cell the
            // pill's own width already reserves, so the pill renders flush
            // with both cell edges instead of overflowing one and starving
            // the other — the padding VALUE (spacingLg) is unchanged, only
            // where it is centred from.
            x: Design.spacingLg / 2
            rows: clockActionsCapsule.vertical ? -1 : 1
            columns: clockActionsCapsule.vertical ? 1 : -1
            spacing: Design.spacingXs

            // Upstream's clock leads with a glyph:
            // `format: "󰃱 <span size='11pt'>{:%H.%M }</span>"`. Ours had none,
            // which the operator reported directly. Rendered as its own Text in
            // Design.symbolFontFamily rather than by pasting upstream's Nerd
            // Font codepoint into the time string: every other glyph in this
            // file is a Material Symbols ligature, and mixing a second glyph
            // font into one pill would depend on font substitution to line up.
            Text {
                id: clockGlyphText
                text: "schedule"
                font.family: Design.symbolFontFamily
                font.pixelSize: Design.barGlyphSize
                color: BarRoles.fillClockFg
                verticalAlignment: Text.AlignVCenter
                height: Design.barGlyphSize
            }

            // Line 1 in both orientations: the time itself.
            Text {
                id: clockTimeText
                font.pixelSize: Design.barBodySize
                // weightBold — Athena's #clock rule is `font-weight: bold`
                // (CSS 700 = Font.Bold). This was weightBody (Normal) with a
                // comment explaining that no bold token existed; the token now
                // exists (Design.qml), so the comment's premise is gone and the
                // operator's "the font is lighter" is fixed at the source
                // rather than approximated with DemiBold.
                font.weight: Design.weightBold
                color: BarRoles.fillClockFg
                text: Qt.formatDateTime(barClock.date, "HH:mm")
                verticalAlignment: Text.AlignVCenter
                height: Design.barGlyphSize
            }

            // Line 2, vertical only (D-18-14's two-stacked-lines form): a
            // short date, sized to fit Design.barColumnWidth with no
            // truncation. Hidden in horizontal, where the capsule stays a
            // single line — and, per the shared chrome's own visibility
            // rule, an invisible child is excluded from the positioner's
            // spacing too.
            Text {
                id: clockDateText
                visible: clockActionsCapsule.vertical
                font.pixelSize: Design.barBodySize
                font.weight: Design.weightBody
                color: BarRoles.fillClockFg
                text: Qt.formatDateTime(barClock.date, "ddd")
            }
        }
    }

    // ── Shared geometry for every extra on this capsule — Task 2's
    //    LauncherCell pitch, reused. ────────────────────────────────────
    readonly property int cellPitch: Design.barGlyphSize + Design.spacingXs * 2

    // ── ActionCell — the shared cell shape for every extra: identical
    //    geometry whether available or not, a live hover target at all
    //    times, and no pressed-state visual (this repo keys visual state
    //    off the resulting state change). ────────────────────────────────
    component ActionCell: Item {
        id: cellItem
        // A badged cell widens to hold its count BESIDE the glyph rather than
        // on top of it. Upstream Athena's #custom-notification is a filled
        // pill containing the bell glyph and the count side by side; ours drew
        // a badge circle of implicitHeight spacingMd (16) anchored to the
        // top-right of a cell whose glyph is barGlyphSize (16), so the badge
        // covered the bell exactly — the operator's "the notifications glyph
        // is messed up".
        width: clockActionsCapsule.cellPitch + (cellItem.badgeVisible ? badge.width + Design.spacingXs : 0)
        height: clockActionsCapsule.cellPitch

        property string glyph: ""
        property string label: ""
        property bool filled: false
        property color tint: clockActionsCapsule.contentColour
        property bool available: true
        property bool badgeVisible: false
        property string badgeText: ""
        // Optional filled background (D-13, only bellCell opts in below).
        // Defaults leave every other ActionCell instance unaffected —
        // Athena has exactly three filled hues and this must not become
        // a fourth.
        property bool fillActive
        property color fillColour: "transparent"
        signal clicked()
        signal rightClicked()

        // D-15-22's present-but-disabled treatment, established by
        // PanelDialog.qml's Advanced button: identical geometry, dropped
        // to this opacity, hover target left live so a tooltip can state
        // the reason. Never removed, never blank, never a dead hit area.
        readonly property real disabledOpacity: 0.38

        // Declared FIRST so it renders behind the glyph below. No
        // MouseArea/HoverHandler of its own — cellMouseArea (below) is
        // the cell's one hit target, unaffected by this addition.
        Rectangle {
            id: cellFillPill
            anchors.fill: parent
            radius: height / 2
            visible: cellItem.fillActive
            color: cellItem.fillColour
            Behavior on color {
                enabled: Motion.motionEnabled
                ColorAnimation {
                    duration: Motion.standardDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.standardEasing
                }
            }
        }

        Text {
            id: glyphText
            // Offset left by half the badge's footprint when badged, so the
            // glyph+count pair is optically centred in the widened cell
            // instead of the glyph staying centred and the count hanging off.
            anchors.verticalCenter: parent.verticalCenter
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: cellItem.badgeVisible ? -(badge.width + Design.spacingXs) / 2 : 0
            text: cellItem.glyph
            font.family: Design.symbolFontFamily
            font.pixelSize: Design.barGlyphSize
            font.variableAxes: clockActionsCapsule.fillAxisAvailable ? { "FILL": cellItem.filled ? 1 : 0 } : ({})
            color: cellItem.tint
            opacity: cellItem.available ? 1 : cellItem.disabledOpacity
        }

        // Badge overlay — used only by the bell, defaults to invisible
        // for every other cell.
        Rectangle {
            id: badge
            visible: cellItem.badgeVisible
            implicitWidth: Math.max(implicitHeight, badgeLabel.implicitWidth + Design.spacingXs)
            implicitHeight: Design.spacingMd
            width: implicitWidth
            height: implicitHeight
            radius: height / 2
            color: BarRoles.accent
            // Beside the glyph, vertically centred — was anchors.top/right,
            // which laid a 16px circle over a 16px glyph.
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: glyphText.right
            anchors.leftMargin: Design.spacingXs

            Text {
                id: badgeLabel
                anchors.centerIn: parent
                text: cellItem.badgeText
                font.pixelSize: Design.barBodySize
                color: BarRoles.onAccent
            }
        }

        MouseArea {
            id: cellMouseArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            onClicked: (mouse) => {
                if (!cellItem.available)
                    return;
                if (mouse.button === Qt.RightButton)
                    cellItem.rightClicked();
                else
                    cellItem.clicked();
            }
        }

        // F2 (quick task 260812-69w) — see IdleInhibitorCapsule.qml's own
        // comment for the measured clamp this replaces. The empty-label
        // suppression this ToolTip used to carry as a second condition
        // (`&& cellItem.label !== ""`) is now folded into `active` itself,
        // per the plan's own instruction — a host with nothing to say
        // never arms its dwell timer. `tipId` is keyed off glyph, the one
        // value distinct across every ActionCell instance in this file
        // (gaming/bell/settings/power all carry a different glyph).
        BarTooltipHost {
            anchorItem: cellItem
            text: cellItem.label
            active: cellMouseArea.containsMouse && cellItem.label !== ""
            tipId: "clockActions-" + cellItem.glyph
        }
    }

    // ── Power ─────────────────────────────────────────────────────────
    readonly property string powerScriptPath: clockActionsCapsule.homeDir + "/.config/hypr/scripts/wleave.sh"
    property bool powerAvailable: true

    Process {
        id: powerAvailabilityProbe
        command: ["test", "-x", clockActionsCapsule.powerScriptPath]
        onExited: function (exitCode, exitStatus) {
            clockActionsCapsule.powerAvailable = exitCode === 0;
        }
    }
    Process {
        id: powerLaunchProcess
        command: [clockActionsCapsule.powerScriptPath]
    }

    // ── Gaming mode — a read-only, compare-only consumer of the state
    //    its owner script writes. No second copy of the on/off logic
    //    exists here; the retired bar's own module carried that same
    //    discipline and it is carried forward, not re-derived. ─────────
    FileView {
        id: gamingStateFile
        path: clockActionsCapsule.homeDir + "/.cache/gaming-mode"
        watchChanges: true
        onFileChanged: reload()
    }
    readonly property string gamingRaw: (gamingStateFile.text() || "").trim()
    readonly property bool gamingOn: (gamingRaw.length > 0 ? gamingRaw : "off") === "on"

    Process {
        id: gamingLaunchProcess
        command: [clockActionsCapsule.homeDir + "/.config/hypr/scripts/gaming-mode-toggle.sh"]
    }

    // ── The notification bell, and the seam D-18-33 promises. ──────────
    // Every name outside this component's own body MUST stay confined to
    // the five below: unreadCount, dndActive, available, openCentre(),
    // toggleDnd(). Everything else — the subscription argv, the field
    // names its output carries, the open-centre argv, the do-not-disturb
    // argv, the vocabulary of state strings it emits — lives inside this
    // component and nowhere else in this file. This binding is to a
    // package this milestone deletes: if any of it leaks into a binding
    // or a layout expression outside this component, the Phase 19
    // replacement stops being a backend swap and becomes a rewrite of a
    // surface that has already passed its render gate.
    component NotificationSource: QtObject {
        id: sourceRoot

        readonly property int unreadCount: sourceRoot._unreadCount
        readonly property bool dndActive: sourceRoot._dndActive
        readonly property bool available: sourceRoot._available

        property int _unreadCount: 0
        property bool _dndActive: false
        property bool _available: true

        // The closed eight-member vocabulary the subscription's own
        // "class" field carries — verified live this plan by running the
        // command directly against the installed swaync, both with and
        // without a real notification present. A compare-only closed
        // list, never an interpolation.
        readonly property var _dndClasses: ["dnd-notification", "dnd-none", "dnd-inhibited-notification", "dnd-inhibited-none"]
        readonly property var _liveClasses: ["notification", "none", "inhibited-notification", "inhibited-none"]

        function openCentre() {
            openCentreProcess.startDetached();
        }
        function toggleDnd() {
            toggleDndProcess.startDetached();
        }

        // QtObject carries no default property of its own, so the three
        // Process children below are attached through one explicit list
        // property rather than declared as anonymous children.
        //
        // The FIRST of the three is the one permanent child process this
        // plan adds to an always-on surface (T-18-11-06) — a
        // subscription, not a poll, so it costs nothing between events.
        // This is the charge named in this plan's SUMMARY as 18-18's soak
        // must account for, alongside the ones 18-08 records in its own
        // liveness-charge document — it is deliberately NOT written into
        // that other document, since 18-08 owns it in the same wave and a
        // shared write would be the one file conflict wave 3 has
        // otherwise avoided entirely. It ends when Phase 19 replaces this
        // component's body.
        property list<QtObject> _processes: [
            Process {
                id: notificationSubscription
                running: true
                command: ["swaync-client", "-swb"]
                stdout: SplitParser {
                    onRead: (line) => {
                        try {
                            const payload = JSON.parse(line);
                            if (payload && typeof payload.text === "string") {
                                const n = Number(payload.text);
                                if (Number.isFinite(n) && n >= 0)
                                    sourceRoot._unreadCount = Math.trunc(n);
                            }
                            if (payload && typeof payload.class === "string") {
                                if (sourceRoot._dndClasses.indexOf(payload.class) !== -1)
                                    sourceRoot._dndActive = true;
                                else if (sourceRoot._liveClasses.indexOf(payload.class) !== -1)
                                    sourceRoot._dndActive = false;
                            }
                            sourceRoot._available = true;
                        } catch (e) {
                            // malformed/truncated line — keep the
                            // last-good values standing, never fall back
                            // to a synthesized zero.
                        }
                    }
                }
                onExited: function (exitCode, exitStatus) {
                    if (exitCode !== 0)
                        sourceRoot._available = false;
                }
            },
            Process {
                id: openCentreProcess
                command: ["swaync-client", "-t", "-sw"]
            },
            Process {
                id: toggleDndProcess
                command: ["swaync-client", "-d", "-sw"]
            }
        ]
    }

    NotificationSource {
        id: notificationSource
    }

    // ── The settings drawer — the same five axes D-18-01 names, sharing
    //    Task 2's drawer shape verbatim. Promoting that shape to a
    //    shared type is a named follow-on, not a licence to edit the
    //    frozen manifest here. ──────────────────────────────────────────
    readonly property var settingsAxes: [
        { id: "theme", glyph: "contrast", label: "Theme", script: "theme-switch.sh" },
        { id: "orientation", glyph: "screen_rotation", label: "Bar Orientation", script: "bar-orientation.sh" },
        { id: "font", glyph: "text_fields", label: "Font", script: "font-switch.sh" },
        { id: "icons", glyph: "palette", label: "Icon Theme", script: "icon-theme-switch.sh" },
        { id: "wallpaper", glyph: "wallpaper", label: "Wallpaper", script: "wallpaper-switch.sh" }
    ]

    // ── The public drawer seam — the hover contract below (Phase 18.1
    //    Plan 05, D-16/D-17/D-18) is the one and only implementation
    //    driving these three names. ─────────────────────────────────────
    property bool settingsExpanded: false
    // The trigger cell's own scene-space centre along the bar's long axis
    // — BarDrawer.qml's `triggerCentre` contract, published ONCE per
    // expand rather than a live binding. Mirrors
    // LauncherCapsule.qml's own publishDrawerAnchor() shape-identically.
    property real _publishedDrawerCentre: 0
    function publishDrawerAnchor() {
        clockActionsCapsule._publishedDrawerCentre = settingsTriggerCell.mapToItem(null, 0, 0).y + settingsTriggerCell.height / 2;
    }
    function requestExpand() {
        // Published before `settingsExpanded` is set true, so both the
        // dwell path and any direct caller publish a fresh centre.
        clockActionsCapsule.publishDrawerAnchor();
        clockActionsCapsule.settingsExpanded = true;
    }
    function requestCollapse() {
        clockActionsCapsule.settingsExpanded = false;
    }
    readonly property int expandedCrossExtent: clockActionsCapsule.settingsAxes.length * clockActionsCapsule.cellPitch + (clockActionsCapsule.settingsAxes.length - 1) * Design.spacingXs

    // ── Hover-reveal (Phase 18.1 Plan 05, D-16/D-17/D-18) — mirrors
    //    LauncherCapsule.qml's mechanism shape-identically (same property
    //    names, same timer ids, same tokens) so the two are diffable with
    //    zero behavioural divergence. Both hover sources (the trigger
    //    cell and the drawer strip, wired below) report through
    //    `reportDrawerHover` into the same `drawerHoverActive` boolean,
    //    so the pointer travelling from the trigger to the strip never
    //    reads as a clean exit — a per-surface boolean would defeat the
    //    grace timer below before it ever ran. The settledness read below
    //    reads Bar.qml's own live rendered/transitioning state through
    //    the shared `QsWindow.window` handle (the same reachable path
    //    IdleInhibitorCapsule.qml's own `barIdleInhibitor`'s
    //    `window: QsWindow.window` binding already proves live) —
    //    deliberately NOT the reveal-machine
    //    singleton's own dead settled latch (D-26 fences that one out by
    //    name). This file writes to no reveal-machine state at all: the
    //    bar's own whole-content hover handler already spans the area the
    //    drawer expands inside, so the bar's own re-hide grace already
    //    covers an open drawer with zero new wiring. ─────────────────────
    property bool _triggerHovered: false
    property bool _stripHovered: false
    property bool drawerHoverActive: false
    function reportDrawerHover(source, entered) {
        if (source === "trigger")
            clockActionsCapsule._triggerHovered = entered;
        else if (source === "strip")
            clockActionsCapsule._stripHovered = entered;
        clockActionsCapsule.drawerHoverActive = clockActionsCapsule._triggerHovered || clockActionsCapsule._stripHovered;
    }

    readonly property bool drawerSettled: QsWindow.window ? (QsWindow.window.barRendered && !QsWindow.window.barTransitionRunning) : false

    onDrawerHoverActiveChanged: {
        if (clockActionsCapsule.drawerHoverActive) {
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
        if (!clockActionsCapsule.drawerSettled && clockActionsCapsule.settingsExpanded) {
            drawerDwellTimer.stop();
            drawerGraceTimer.stop();
            clockActionsCapsule.requestCollapse();
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
            if (clockActionsCapsule.drawerHoverActive && clockActionsCapsule.drawerSettled)
                clockActionsCapsule.requestExpand();
        }
    }

    Timer {
        id: drawerGraceTimer
        interval: Design.popoutDismissGraceMs
        repeat: false
        onTriggered: {
            if (!clockActionsCapsule.drawerHoverActive)
                clockActionsCapsule.requestCollapse();
        }
    }

    // One axis cell — an ActionCell that also owns its own script-present
    // probe and its own detached launcher, keyed off its own `axis` data
    // rather than a second literal script name.
    component SettingsAxisCell: ActionCell {
        id: axisCell
        property var axis: ({})
        glyph: axisCell.axis.glyph ? axisCell.axis.glyph : ""
        label: axisCell.axis.label ? axisCell.axis.label : ""

        readonly property string scriptPath: clockActionsCapsule.homeDir + "/.config/hypr/scripts/" + axisCell.axis.script

        Process {
            id: axisAvailabilityProbe
            command: ["test", "-x", axisCell.scriptPath]
            onExited: function (exitCode, exitStatus) {
                axisCell.available = exitCode === 0;
            }
        }
        Process {
            id: axisLaunchProcess
            command: [axisCell.scriptPath]
        }

        Component.onCompleted: axisAvailabilityProbe.running = true

        onClicked: {
            // Every one of these five opens a focus-stealing picker; a
            // lifetime-bound child would be killed the moment
            // requestCollapse() below re-lays this capsule, orphaning
            // the picker in exactly the half-dead state this repo's own
            // recorded regression describes.
            axisLaunchProcess.startDetached();
            clockActionsCapsule.requestCollapse();
        }
    }

    // ── Capsule assembly — declaration order matches 18-05's entry list
    //    (clock above, then gaming, notifications, settings, power), one
    //    positioner (BarCapsule's own content Grid), nothing hidden or
    //    folded in either orientation. The idle inhibitor is no longer
    //    among these cells — see note (a) above; it now assembles inside
    //    IdleInhibitorCapsule.qml. ────────────────────────────────────────

    ActionCell {
        id: gamingCell
        glyph: "sports_esports"
        label: "Gaming Mode"
        filled: clockActionsCapsule.gamingOn
        tint: clockActionsCapsule.gamingOn ? BarRoles.accent : clockActionsCapsule.contentColour
        onClicked: gamingLaunchProcess.startDetached()
    }

    ActionCell {
        id: bellCell
        glyph: {
            if (!notificationSource.available)
                return "notifications";
            if (notificationSource.dndActive)
                return "notifications_paused";
            if (notificationSource.unreadCount > 0)
                return "notifications_active";
            return "notifications";
        }
        label: "Notifications"
        filled: notificationSource.unreadCount > 0
        // D-13/QBAR-06: the fill, the badge and the FILL variable axis
        // (via `filled` above) all derive from the ONE
        // notificationSource.unreadCount input — no second source of
        // "there are notifications". Three-branch tint: on-fill colour
        // when unread, danger when the source is unavailable (D-24's
        // migration of this branch, landed here rather than migrated
        // twice in Task 3), neutral content colour otherwise.
        fillActive: notificationSource.unreadCount > 0
        fillColour: BarRoles.fillNotification
        tint: {
            if (notificationSource.unreadCount > 0)
                return BarRoles.fillNotificationFg;
            if (!notificationSource.available)
                return BarRoles.danger;
            return clockActionsCapsule.contentColour;
        }
        badgeVisible: notificationSource.unreadCount > 0
        badgeText: notificationSource.unreadCount > 9 ? "9+" : String(notificationSource.unreadCount)
        onClicked: notificationSource.openCentre()
        onRightClicked: notificationSource.toggleDnd()
    }

    // The settings strip — a Repeater over settingsAxes inside one
    // axis-bound Grid, the same rows/columns formula BarCapsule uses
    // internally, never a Row/Column pair. Horizontal orientation: the
    // true drawer, complete here. Vertical orientation: hosted by
    // BarDrawer.qml instead (18-11's Option B, taken by quick task
    // 260812-59l, see the LazyLoader mounted after settingsTriggerCell
    // below), because a layer-shell surface cannot render outside its own
    // buffer and Bar.qml pins the vertical window to
    // Design.barColumnWidth — this Item contributes nothing (both
    // dimensions resolve to 0) and its five cells are destroyed, not
    // merely clipped, whenever clockActionsCapsule.vertical is true.
    //
    // GATE-02 round 4: declared BEFORE settingsTriggerCell, not after —
    // this capsule sits in the bar's END zone (anchors.right, Bar.qml),
    // so a Grid's LAST child's right edge is what stays pinned to the
    // window edge as the Grid's own width changes (the same Qt Quick Grid
    // layout arithmetic MediaConnectivityCapsule.qml's audio/connections
    // strips already rely on — see that file's own comment on
    // audioStripHost for the full arithmetic). The FORMER order (trigger
    // then strip) put the strip AFTER the trigger, so growing it pushed
    // powerCell rightward while leaving the trigger's own screen position
    // to drift with everything before it — the operator's "expands in the
    // opposite direction". Declaring the strip first makes it grow
    // LEFTWARD out of a fixed settingsTriggerCell, matching every other
    // right-side drawer on this bar and upstream's own
    // `transition-left-to-right: false` convention. This declaration
    // order is load-bearing and stays exactly as it was.
    Item {
        id: settingsStripHost
        clip: true
        width: clockActionsCapsule.vertical ? 0 : (clockActionsCapsule.settingsExpanded ? clockActionsCapsule.expandedCrossExtent : 0)
        height: clockActionsCapsule.vertical ? 0 : clockActionsCapsule.cellPitch

        // GATE-02 round 4: a GTK Revealer slide is one ease-out curve, both
        // directions — see Design.barDrawerEasingType's own provenance
        // comment for why the former Motion.emphasizedIn/Out bezier pair is
        // gone (that pairing's acceleration was the operator's "not smooth"
        // report). Horizontal-only now, but left exactly as it was.
        Behavior on width {
            enabled: Motion.motionEnabled
            NumberAnimation {
                duration: Design.barDrawerTransitionMs
                easing.type: Design.barDrawerEasingType
            }
        }
        Behavior on height {
            enabled: Motion.motionEnabled
            NumberAnimation {
                duration: Design.barDrawerTransitionMs
                easing.type: Design.barDrawerEasingType
            }
        }

        HoverHandler {
            id: settingsStripHoverHandler
            onHoveredChanged: clockActionsCapsule.reportDrawerHover("strip", settingsStripHoverHandler.hovered)
        }

        // Gated behind `!vertical` so the five cells below are destroyed
        // in vertical orientation rather than merely clipped — the same
        // zero-idle-cost discipline BarDrawer.qml's own LazyLoader applies
        // to the surface that replaces this Grid there. `sourceComponent`
        // used explicitly (this repo's own convention for a plain
        // QtQuick.Loader — see Dashboard.qml's dashboardTabLoader).
        Loader {
            id: settingsGridLoader
            anchors.fill: parent
            active: !clockActionsCapsule.vertical
            asynchronous: false

            sourceComponent: Component {
                Grid {
                    id: settingsGrid
                    anchors.fill: parent
                    rows: 1
                    columns: -1
                    spacing: Design.spacingXs

                    Repeater {
                        model: clockActionsCapsule.settingsAxes
                        delegate: SettingsAxisCell {
                            axis: modelData
                        }
                    }
                }
            }
        }
    }

    ActionCell {
        id: settingsTriggerCell
        glyph: "settings"
        label: "Settings"
        filled: clockActionsCapsule.settingsExpanded
        // Athena colours the settings-drawer trigger glyph @accent
        // unconditionally, not as a state indicator (style-athena.scss:298)
        // — this is a permanent accent glyph, so no ternary.
        tint: BarRoles.accent

        HoverHandler {
            id: settingsTriggerHoverHandler
            onHoveredChanged: clockActionsCapsule.reportDrawerHover("trigger", settingsTriggerHoverHandler.hovered)
        }
    }

    // ── Vertical-orientation drawer host (18-11's Option B, D-18-11,
    //    quick task 260812-59l, closing GATE-02 row B.4-DRAWER) — the
    //    SAME registered BarDrawer type LauncherCapsule.qml mounts, no
    //    second host type (constraint 7). Mounted behind a LazyLoader
    //    keyed on `vertical && settingsExpanded`, so it costs nothing
    //    while collapsed or in horizontal orientation.
    //    `reportDrawerHover` is the sole hover relay (D-18-19) — no
    //    second dwell or grace timer is added here. Reuses
    //    SettingsAxisCell (this file's own inline component). ────────────
    LazyLoader {
        id: verticalSettingsDrawerLoader
        active: clockActionsCapsule.vertical && clockActionsCapsule.settingsExpanded

        BarDrawer {
            drawerId: "settings"
            crossExtent: clockActionsCapsule.expandedCrossExtent
            cellPitch: clockActionsCapsule.cellPitch
            triggerCentre: clockActionsCapsule._publishedDrawerCentre
            onHoveredChanged: clockActionsCapsule.reportDrawerHover("strip", hovered)

            Repeater {
                model: clockActionsCapsule.settingsAxes
                delegate: SettingsAxisCell {
                    axis: modelData
                }
            }
        }
    }

    ActionCell {
        id: powerCell
        glyph: "power_settings_new"
        label: "Power Menu"
        available: clockActionsCapsule.powerAvailable
        onClicked: powerLaunchProcess.startDetached()
    }

    Component.onCompleted: {
        powerAvailabilityProbe.running = true;
    }
}
