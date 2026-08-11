// ClockActionsCapsule.qml — the clock + actions slot (Phase 18 Plan 05,
// D-18-10).
//
// Owner: 18-11 for the five action entries (`gaming`, `notifications`,
// `idleInhibitor`, `settings`, `power`) — the two athena drawers plus the
// four permanent extras.
//
// This one is NOT empty: 18-01's live clock moves here intact, carried
// exactly rather than rebuilt — see the SystemClock declaration below.
//
// ── 18-11 fills the rest of this capsule. Three facts a later reader
//    would otherwise re-litigate: ────────────────────────────────────
// (a) The five action entries below are the four permanent extras D-18-03
//     names (power, gaming, notifications, idle inhibitor) plus the
//     settings-drawer trigger. The fourth extra's other half — the
//     updates count — lives in the system capsule (18-08), because
//     18-05's entry list split that pair by kind (readout vs action), not
//     by pairing.
// (b) The notification binding is deliberately temporary and is sealed
//     behind one named component (`NotificationSource` below) so that
//     Phase 19 replaces a backend rather than re-opening a layout that
//     has already passed a render gate.
// (c) This capsule adds exactly one permanent child process to a surface
//     that never unmounts — the notification subscription inside
//     `NotificationSource` — named in source as a charge against QBAR-11
//     that ends when that swap lands.
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../"
import "../dashboard"

BarCapsule {
    id: clockActionsCapsule
    capsuleId: "clockActions"

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
    //    nothing else: not the gaming, notification, idle-inhibitor,
    //    settings or power cells, not the settings drawer, not the entry
    //    order, not the notification source component. ──────────────────
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
            width: clockTriggerGrid.width + Design.spacingSm * 2
            height: clockTriggerGrid.height + Design.spacingSm * 2
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

        // Reproduces contentGrid's own spacing/orientation formula exactly
        // (Design.spacingSm), so wrapping these two Text elements in one
        // trigger cell leaves the rendered gap between them, and between
        // this cell and the next, byte-identical to before.
        Grid {
            id: clockTriggerGrid
            rows: clockActionsCapsule.vertical ? -1 : 1
            columns: clockActionsCapsule.vertical ? 1 : -1
            spacing: Design.spacingSm

            // Line 1 in both orientations: the time itself.
            Text {
                id: clockTimeText
                font.pixelSize: Design.fontLabel
                // No "bold" weight token exists in Design.qml (only
                // weightDisplay/weightEmphasis/weightBody — see this
                // plan's SUMMARY "Decisions Made"). Athena's #clock rule
                // is font-weight: bold; left at weightBody rather than
                // minting a raw numeric weight or repurposing a token
                // under a name it doesn't carry.
                font.weight: Design.weightBody
                color: BarRoles.fillClockFg
                text: Qt.formatDateTime(barClock.date, "HH:mm")
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
                font.pixelSize: Design.fontLabel
                font.weight: Design.weightBody
                color: BarRoles.fillClockFg
                text: Qt.formatDateTime(barClock.date, "ddd")
            }
        }
    }

    // ── Shared geometry for every extra on this capsule — Task 2's
    //    LauncherCell pitch, reused. ────────────────────────────────────
    readonly property int cellPitch: Design.iconSizeMd + Design.spacingXs * 2

    // ── ActionCell — the shared cell shape for every extra: identical
    //    geometry whether available or not, a live hover target at all
    //    times, and no pressed-state visual (this repo keys visual state
    //    off the resulting state change). ────────────────────────────────
    component ActionCell: Item {
        id: cellItem
        width: clockActionsCapsule.cellPitch
        height: clockActionsCapsule.cellPitch

        property string glyph: ""
        property string label: ""
        property bool filled: false
        property color tint: clockActionsCapsule.contentColour
        property bool available: true
        property bool badgeVisible: false
        property string badgeText: ""
        signal clicked()
        signal rightClicked()

        // D-15-22's present-but-disabled treatment, established by
        // PanelDialog.qml's Advanced button: identical geometry, dropped
        // to this opacity, hover target left live so a tooltip can state
        // the reason. Never removed, never blank, never a dead hit area.
        readonly property real disabledOpacity: 0.38

        Text {
            id: glyphText
            anchors.centerIn: parent
            text: cellItem.glyph
            font.family: Design.symbolFontFamily
            font.pixelSize: Design.iconSizeMd
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
            color: Colours.primary
            anchors.top: parent.top
            anchors.right: parent.right

            Text {
                id: badgeLabel
                anchors.centerIn: parent
                text: cellItem.badgeText
                font.pixelSize: Design.fontLabel
                color: Colours.onPrimary
            }
        }

        MouseArea {
            id: cellMouseArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            ToolTip.visible: cellMouseArea.containsMouse && cellItem.label !== ""
            ToolTip.text: cellItem.label
            ToolTip.delay: Design.tooltipDelayMs
            onClicked: (mouse) => {
                if (!cellItem.available)
                    return;
                if (mouse.button === Qt.RightButton)
                    cellItem.rightClicked();
                else
                    cellItem.clicked();
            }
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

    // ── Idle inhibitor — the native wayland idle-inhibit client, bound
    //    to the bar's own permanently-mapped window. Starts disabled on
    //    every shell start and is never persisted: an inhibitor restored
    //    after an automatic restart would keep the machine awake with no
    //    visible cause, the same failure class this repo already records
    //    for a stale gaming state — failing to "not inhibiting" is the
    //    only safe default. ─────────────────────────────────────────────
    property bool idleInhibited: false

    IdleInhibitor {
        id: barIdleInhibitor
        window: QsWindow.window
        enabled: clockActionsCapsule.idleInhibited
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

    property bool settingsExpanded: false
    function requestExpand() {
        clockActionsCapsule.settingsExpanded = true;
    }
    function requestCollapse() {
        clockActionsCapsule.settingsExpanded = false;
    }
    readonly property int expandedCrossExtent: clockActionsCapsule.settingsAxes.length * clockActionsCapsule.cellPitch + (clockActionsCapsule.settingsAxes.length - 1) * Design.spacingXs

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
    //    (clock above, then gaming, notifications, idle inhibitor,
    //    settings, power), one positioner (BarCapsule's own content
    //    Grid), nothing hidden or folded in either orientation. ─────────

    ActionCell {
        id: gamingCell
        glyph: "sports_esports"
        label: "Gaming Mode"
        filled: clockActionsCapsule.gamingOn
        tint: clockActionsCapsule.gamingOn ? Colours.primary : clockActionsCapsule.contentColour
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
        tint: notificationSource.available ? clockActionsCapsule.contentColour : Colours.error
        badgeVisible: notificationSource.unreadCount > 0
        badgeText: notificationSource.unreadCount > 9 ? "9+" : String(notificationSource.unreadCount)
        onClicked: notificationSource.openCentre()
        onRightClicked: notificationSource.toggleDnd()
    }

    ActionCell {
        id: idleCell
        glyph: "lightbulb"
        label: "Keep Awake"
        filled: clockActionsCapsule.idleInhibited
        tint: clockActionsCapsule.idleInhibited ? Colours.primary : clockActionsCapsule.contentColour
        onClicked: clockActionsCapsule.idleInhibited = !clockActionsCapsule.idleInhibited
    }

    ActionCell {
        id: settingsTriggerCell
        glyph: "settings"
        label: "Settings"
        filled: clockActionsCapsule.settingsExpanded
        onClicked: clockActionsCapsule.settingsExpanded ? clockActionsCapsule.requestCollapse() : clockActionsCapsule.requestExpand()
    }

    // The settings strip — a Repeater over settingsAxes inside one
    // axis-bound Grid, the same rows/columns formula BarCapsule uses
    // internally, never a Row/Column pair. Carries the same flagged
    // vertical-orientation host gap Task 2's launcher strip carries — see
    // this plan's `## Scope correction required`.
    Item {
        id: settingsStripHost
        clip: true
        width: clockActionsCapsule.vertical ? clockActionsCapsule.cellPitch : (clockActionsCapsule.settingsExpanded ? clockActionsCapsule.expandedCrossExtent : 0)
        height: clockActionsCapsule.vertical ? (clockActionsCapsule.settingsExpanded ? clockActionsCapsule.expandedCrossExtent : 0) : clockActionsCapsule.cellPitch

        Behavior on width {
            enabled: Motion.motionEnabled
            NumberAnimation {
                duration: clockActionsCapsule.settingsExpanded ? Motion.emphasizedInDuration : Motion.emphasizedOutDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: clockActionsCapsule.settingsExpanded ? Motion.emphasizedInEasing : Motion.emphasizedOutEasing
            }
        }
        Behavior on height {
            enabled: Motion.motionEnabled
            NumberAnimation {
                duration: clockActionsCapsule.settingsExpanded ? Motion.emphasizedInDuration : Motion.emphasizedOutDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: clockActionsCapsule.settingsExpanded ? Motion.emphasizedInEasing : Motion.emphasizedOutEasing
            }
        }

        Grid {
            id: settingsGrid
            anchors.fill: parent
            rows: clockActionsCapsule.vertical ? -1 : 1
            columns: clockActionsCapsule.vertical ? 1 : -1
            spacing: Design.spacingXs

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
