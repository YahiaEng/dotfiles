// QuickToggles.qml — the quick-toggle grid's VIEW (Phase 14 Plan 04,
// D-22..D-27; promoted to a pure view over `ToggleState` by Phase 19
// Plan 05, D-19-19/QNOTIF-07).
//
// ── Phase 19 Plan 05 promotion (D-19-19/QNOTIF-07) ───────────────────────
// Every piece of STATE this file used to own directly — the gaming/dark
// FileViews, the DND subscribe/poll processes, the pending model, the
// three backend-seam properties' truth mirrors, and every press verb —
// moved to `ToggleState.qml`, a `pragma Singleton`. This file now reads
// `ToggleState.chipLitFor(name)`/`ToggleState.pendingChip` and calls
// `ToggleState.pressChipByName(name)`; it owns rendering only (the chip
// visuals, ripple, pending pulse, tooltips, layout) — a second instance
// of this component (Plan 19-06's centre footer) is therefore
// STRUCTURALLY incapable of drifting from this one: both read the exact
// same singleton property at the exact same time, and there is no
// synchronisation code between them to forget or get wrong.
//
// `audioBackend`/`wifiBackend`/`bluetoothBackend` are still accepted as
// properties here (unchanged — still threaded in from
// `shell.qml -> Dashboard.qml -> DashboardTab.qml`, the SAME path 15-07
// already built) and relayed into `ToggleState` via three `Binding`
// elements below (a live relay, not a one-shot assignment, so a second
// QuickToggles instance re-asserting the identical object reference is
// harmless). This reuses the existing threading path rather than adding a
// second one straight from `shell.qml`, so neither `Dashboard.qml` nor
// `DashboardTab.qml` needed an edit for this plan.
//
// The full-width `Off | Reduced | Normal | Lively` motion-scale segmented
// row is DELIBERATELY NOT part of this promotion — D-23's own text (see
// below) already establishes it sits OUTSIDE the DASH-07 mirror proof by
// construction (no external-daemon counterpart, a one-way view of a state file),
// so it stays exactly where it was: local state, local to this file, not
// mirrored, not promoted.
//
// ── Design constants — NOT read off `dashboardWindow` ───────────────────
// Dashboard.qml's header comment states plans 14-03..14-08 should read its
// spacing/type-scale/icon constants off `dashboardWindow` instead of
// re-declaring them. That mechanism does not actually exist yet: `id`-based
// lookup in QML is lexical to the declaring FILE, and `DashboardTab`/
// `QuickToggles` are separate registered component types instantiated
// inside `dashboardWindow`'s object tree, not textually nested inside
// Dashboard.qml — so a bare `dashboardWindow.spacingLg` reference from this
// file would not resolve. This file declares its own copies of exactly the
// constants it needs, sourced from `Design.qml` (a `pragma Singleton`,
// which DOES resolve this way — see that file's own header for the 12-06
// finding this depends on).
//
// ── D-15-21 — zero vertical growth, and the corrected arithmetic. ────────
// The grid goes from three tiles to six in ONE row (reference lens — end-4
// and Caelestia both scale a toggle grid with more compact tiles, never
// with more rows).
//
// ── The no-acronym constraint is LIFTED for DND (operator, 2026-08-26) ───
// This header used to read: "HARD CONSTRAINT: the Do Not Disturb label wraps
// to two lines inside the 72px height and must NEVER be shortened to an
// acronym — Phase 14's render gate explicitly rejected that acronym."
// The operator has since asked for exactly that acronym, which overrides the
// earlier gate verdict. Recorded rather than deleted so nobody "restores"
// the long label on the strength of a constraint that no longer holds.
//
// Scope of the lift: the DND CHIP LABEL only. Its tooltip still spells "Do
// Not Disturb" in full, so the acronym stays discoverable, and the settings
// page keeps its full "Do not disturb" row label — that one has room, and
// `settings-index-check` requires it to match RowIndex.qml verbatim.
//
// The no-abbreviation reasoning still governs every OTHER label here: the
// `HorizontalFit` note further down rejects "BT" for Bluetooth on it, and
// that rejection stands. One label was overridden, not the principle.
import QtQml
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import "../"

Item {
    id: root

    // ── Constants mirrored from 14-UI-SPEC.md / dashboardWindow (see header
    //    comment above — this file cannot reach dashboardWindow's copies). ─
    readonly property int spacingXs: Design.spacingXs
    readonly property int spacingSm: Design.spacingSm
    readonly property int spacingMd: Design.spacingMd
    readonly property int fontLabel: Design.fontLabel
    readonly property int iconSizeMd: Design.iconSizeMd
    // Exact installed family string, per 14-02-SUMMARY.md's registration.
    readonly property string symbolFontFamily: Design.symbolFontFamily
    // 14-02-SUMMARY.md's live-measured verdict: `fill-axis-renders` — Qt
    // 6.11.1 genuinely drives this font's FILL variable axis on this build.
    readonly property bool fillAxisAvailable: true
    readonly property int tooltipDelayMs: Design.tooltipDelayMs

    readonly property int chipHeight: 72
    readonly property int chipRadius: 16
    readonly property int presetHeight: 48
    // 15-07 — tile-geometry constants for the chevron split affordance and
    // the six-across label wrap. Fixed component dimensions (15-UI-SPEC.md's
    // sense of the term), not gap tokens, so named here rather than forced
    // onto the 4/8/16/24/32 spacing scale.
    readonly property int chevronHitSize: 32
    readonly property int chevronGlyphSize: 16
    readonly property int chipLabelInset: root.spacingXs
    // Phase 19 Plan 05 — the established disabled-opacity value this
    // repo already carries in four other files (SectionPopout.qml,
    // ClockActionsCapsule.qml, PanelDialog.qml, BluetoothPanel.qml), never
    // yet a Design token — reused here at the identical literal rather
    // than invented afresh.
    readonly property real disabledOpacity: 0.38

    property string homeDir: Quickshell.env("HOME")

    // ── Backend seams — still threaded in from DashboardTab on the same
    //    path 15-07 built, and relayed into ToggleState once below. This
    //    file no longer READS them directly (ToggleState does), only
    //    forwards them. ────────────────────────────────────────────────
    property var audioBackend: null // AudioBackend instance
    property var wifiBackend: null // WifiBackend instance
    property var bluetoothBackend: null // BluetoothBackend instance

    // Relay (see header): ToggleState is a singleton and cannot receive
    // these through ordinary instantiation property-passing, so this is
    // the one place the existing threaded properties cross over. Live
    // `Binding` elements (not a one-shot assignment) so a second
    // QuickToggles instance (Plan 19-06) re-asserting the identical
    // backend references is harmless — same objects, not a second source.
    Binding {
        target: ToggleState
        property: "audioBackend"
        value: root.audioBackend
    }
    Binding {
        target: ToggleState
        property: "wifiBackend"
        value: root.wifiBackend
    }
    Binding {
        target: ToggleState
        property: "bluetoothBackend"
        value: root.bluetoothBackend
    }

    // D-41 widget-state register — the shared three-name vocabulary every
    // modules/dashboard/ file carries. "empty" is structurally
    // inapplicable to this widget (14-UI-SPEC.md's Dismissed section:
    // "Toggle grid — empty: chips always render, D-05 audit").
    readonly property var widgetStateVocabulary: ["populated", "pending", "empty"]
    readonly property string widgetState: ToggleState.pendingChip !== "" ? "pending" : "populated"

    implicitHeight: chipsRow.height + spacingSm + presetRow.height
    implicitWidth: 0 // no meaningful own width — the mounting parent (14-08) sizes this via anchors

    // ── 15-07 chevron relay origin — the drawer-side half of the split
    //    affordance's summon path. `panelRequested` is relayed unchanged by
    //    DashboardTab.qml and Dashboard.qml up to shell.qml, whose handler
    //    on the existing Dashboard {} instance is the ONLY place it becomes
    //    a summon, by calling the single guarded openPanel(name) 15-02
    //    wrote.
    signal panelRequested(string name)
    function openPanel(name) {
        root.panelRequested(name);
    }

    // ── Chips (D-25) — the retired daemon's own order: Gaming, DND, Dark. Glyph picks
    //    are discretion (all Material Symbols Rounded ligature names,
    //    live-confirmed to render as real glyphs, not tofu). ─────────────
    readonly property var chipModel: [
        { name: "gaming", label: "Gaming", glyph: "sports_esports", tooltip: "Toggle gaming mode — disables idle timeout and notification popups while you play", panel: "", chevronTooltip: "" },
        { name: "dnd", label: "DND", glyph: "do_not_disturb_on", tooltip: "Toggle Do Not Disturb — silences notifications", panel: "", chevronTooltip: "" },
        { name: "dark", label: "Dark", glyph: "dark_mode", tooltip: "Open the theme picker to switch the desktop's colour palette", panel: "", chevronTooltip: "" },
        { name: "volume", label: "Volume", glyph: "volume_up", tooltip: "Mute or unmute the default audio output — open the arrow for the full mixer", panel: "audio", chevronTooltip: "Open the audio mixer" },
        { name: "wifi", label: "Wi-Fi", glyph: "wifi", tooltip: "Turn the Wi-Fi radio on or off — open the arrow for networks and saved connections", panel: "wifi", chevronTooltip: "Open the Wi-Fi panel" },
        { name: "bluetooth", label: "Bluetooth", glyph: "bluetooth", tooltip: "Turn the Bluetooth adapter on or off — open the arrow for devices", panel: "bluetooth", chevronTooltip: "Open the Bluetooth panel" }
    ]

    // One inline component definition — all six chips are the same
    // object with different data (name/label/glyph), per the original
    // plan's own "one inline component defining a chip" instruction.
    component ToggleChip: Item {
        id: chipItem

        property string chipName: ""
        property string chipLabel: ""
        property string chipGlyph: ""
        property string chipTooltip: ""
        property string chipPanel: ""
        property string chipChevronTooltip: ""
        readonly property bool lit: ToggleState.chipLitFor(chipName)
        readonly property bool pending: ToggleState.pendingChip === chipName
        // Phase 19 Plan 05 — the unreachable-backend affordance (this
        // plan's new behaviour): a tile whose backend seam is still null
        // renders disabled with an explanatory tooltip rather than a
        // default value that reads as real truth.
        readonly property bool reachable: ToggleState.chipReachable(chipName)
        readonly property string unavailableReason: ToggleState.chipUnavailableReason(chipName)

        // Smoothly interpolated 0..1 lit progress — drives both the
        // container's tonal fill (via the Behavior below) and, when the
        // FILL axis is available, the glyph's own outline-to-filled
        // interpolation.
        property real litProgress: lit ? 1 : 0
        Behavior on litProgress {
            enabled: Motion.motionEnabled
            NumberAnimation {
                duration: Motion.standardDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.standardEasing
            }
        }

        opacity: chipItem.reachable ? 1 : root.disabledOpacity
        Behavior on opacity {
            enabled: Motion.motionEnabled
            NumberAnimation {
                duration: Motion.standardDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.standardEasing
            }
        }

        Rectangle {
            id: container
            anchors.fill: parent
            radius: root.chipRadius
            clip: true
            color: chipItem.lit ? Colours.primary : Colours.surfaceVariant
            Behavior on color {
                enabled: Motion.motionEnabled
                ColorAnimation {
                    duration: Motion.colourDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.colourEasing
                }
            }

            // ── MD3 state layer — ripple + pending pulse, both clipped to
            //    the container's rounded shape. ─────────────────────────
            Rectangle {
                id: rippleCircle
                width: 0
                height: 0
                radius: width / 2
                color: chipItem.lit ? Colours.onPrimary : Colours.onSurfaceVariant
                opacity: 0
            }

            Rectangle {
                id: pendingPulseLayer
                anchors.fill: parent
                radius: parent.radius
                color: chipItem.lit ? Colours.onPrimary : Colours.onSurfaceVariant
                opacity: 0
                visible: chipItem.pending

                SequentialAnimation {
                    id: pendingPulseAnim
                    running: chipItem.pending && Motion.motionEnabled
                    loops: Animation.Infinite
                    NumberAnimation {
                        target: pendingPulseLayer
                        property: "opacity"
                        from: 0.0
                        to: 0.16
                        duration: Motion.emphasizedInDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Motion.emphasizedInEasing
                    }
                    NumberAnimation {
                        target: pendingPulseLayer
                        property: "opacity"
                        from: 0.16
                        to: 0.0
                        duration: Motion.emphasizedOutDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Motion.emphasizedOutEasing
                    }
                }
            }

            Column {
                anchors.centerIn: parent
                spacing: root.spacingXs

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: chipItem.chipGlyph
                    font.family: root.symbolFontFamily
                    font.pixelSize: root.iconSizeMd
                    property real iconFill: chipItem.litProgress
                    font.variableAxes: root.fillAxisAvailable ? { "FILL": chipItem.litProgress } : ({})
                    color: chipItem.lit ? Colours.onPrimary : Colours.onSurfaceVariant
                    Behavior on color {
                        enabled: Motion.motionEnabled
                        ColorAnimation {
                            duration: Motion.colourDuration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Motion.colourEasing
                        }
                    }
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: chipItem.chipLabel
                    font.pixelSize: root.fontLabel
                    width: chipItem.width - root.chipLabelInset * 2
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    // GATE-02 round 12 — "Bluetooth" was clipped in the
                    // notification centre. MEASURED, not estimated: the
                    // centre is 430 wide, CentreFooter insets this grid by
                    // spacingMd (16) each side, and tile width is computed
                    // at line ~401 as an even division of what's left, so
                    // (430 - 32 - spacingSm*5) / 6 = ~59px per tile and
                    // 59 - chipLabelInset*2 = ~51px of label room. At
                    // fontLabel (12) "Bluetooth" needs ~58px. The tiles
                    // themselves are NOT overflowing — they divide the
                    // available width exactly — it is this label that
                    // exceeds its own `width`, and with no elide set it
                    // simply painted past the tile and off the frame.
                    //
                    // WordWrap cannot rescue it: "Bluetooth" is a single
                    // word with no break opportunity. (The two-word "Do Not
                    // Disturb" used to wrap happily on this same grid and was
                    // the counter-example here; it is "DND" as of 2026-08-26
                    // — see the header — so Bluetooth is now the longest
                    // label on the row and this note is the only thing
                    // keeping it legible.)
                    //
                    // HorizontalFit shrinks ONLY labels that don't fit,
                    // down to minimumPixelSize, leaving every label that
                    // already fits at full fontLabel. Chosen over the two
                    // alternatives deliberately: eliding gives "Bluetoot…"
                    // (worse than the clip), and shortening to "BT" fights
                    // the same no-abbreviation principle this grid still
                    // applies to every label but DND. The wider
                    // dashboard drawer is unaffected, since nothing needs
                    // shrinking at that width.
                    fontSizeMode: Text.HorizontalFit
                    minimumPixelSize: root.fontLabel - 3
                    color: chipItem.lit ? Colours.onPrimary : Colours.onSurfaceVariant
                    Behavior on color {
                        enabled: Motion.motionEnabled
                        ColorAnimation {
                            duration: Motion.colourDuration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Motion.colourEasing
                        }
                    }
                }
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                // Non-interactive while pending (D-22) OR while the
                // backend is unreachable (Phase 19 Plan 05) — a press on
                // an unreachable tile has nowhere real to go.
                enabled: !chipItem.pending && chipItem.reachable
                hoverEnabled: true
                onPressed: (mouse) => {
                    if (!Motion.motionEnabled)
                        return;
                    const d = Math.max(container.width, container.height) * 2;
                    rippleCircle.x = mouse.x - d / 2;
                    rippleCircle.y = mouse.y - d / 2;
                    rippleCircle.width = 0;
                    rippleCircle.height = 0;
                    rippleCircle.opacity = 0.16;
                    rippleGrowAnim.stop();
                    rippleFadeAnim.stop();
                    rippleGrowAnim.to = d;
                    rippleGrowAnim.start();
                }
                onClicked: ToggleState.pressChipByName(chipItem.chipName)

                NumberAnimation {
                    id: rippleGrowAnim
                    target: rippleCircle
                    properties: "width,height"
                    duration: Motion.spatialInDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.spatialInEasing
                    onFinished: rippleFadeAnim.start()
                }
                NumberAnimation {
                    id: rippleFadeAnim
                    target: rippleCircle
                    property: "opacity"
                    to: 0
                    duration: Motion.emphasizedOutDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.emphasizedOutEasing
                }
            }
            // ThemedToolTip (quick-260821-6z1 fix wave) — replaces the
            // bare attached ToolTip shorthand; see ThemedToolTip.qml.
            ThemedToolTip {
                visible: mouseArea.containsMouse && (chipItem.reachable ? chipItem.chipTooltip !== "" : chipItem.unavailableReason !== "")
                text: chipItem.reachable ? chipItem.chipTooltip : chipItem.unavailableReason
                delay: root.tooltipDelayMs
            }

            // ── 15-07 chevron split affordance ──────────────────────────
            Text {
                id: chevronGlyph
                visible: chipItem.chipPanel !== ""
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.margins: root.spacingXs
                text: "chevron_right"
                font.family: root.symbolFontFamily
                font.pixelSize: root.chevronGlyphSize
                color: chipItem.lit ? Colours.onPrimary : Colours.onSurfaceVariant
                Behavior on color {
                    enabled: Motion.motionEnabled
                    ColorAnimation {
                        duration: Motion.colourDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Motion.colourEasing
                    }
                }
            }

            MouseArea {
                id: chevronMouseArea
                visible: chipItem.chipPanel !== ""
                enabled: chipItem.chipPanel !== ""
                anchors.top: parent.top
                anchors.right: parent.right
                width: root.chevronHitSize
                height: root.chevronHitSize
                hoverEnabled: true
                onClicked: root.openPanel(chipItem.chipPanel)
            }
            // ThemedToolTip (quick-260821-6z1 fix wave) — replaces the
            // bare attached ToolTip shorthand; see ThemedToolTip.qml.
            ThemedToolTip {
                visible: chevronMouseArea.containsMouse && chipItem.chipChevronTooltip !== ""
                text: chipItem.chipChevronTooltip
                delay: root.tooltipDelayMs
            }
        }
    }

    Row {
        id: chipsRow
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: root.chipHeight
        spacing: root.spacingSm

        Repeater {
            model: root.chipModel
            delegate: ToggleChip {
                width: (chipsRow.width - root.spacingSm * (root.chipModel.length - 1)) / root.chipModel.length
                height: chipsRow.height
                chipName: modelData.name
                chipLabel: modelData.label
                chipGlyph: modelData.glyph
                chipTooltip: modelData.tooltip
                chipPanel: modelData.panel
                chipChevronTooltip: modelData.chevronTooltip
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    // Animation-style segmented row (D-24; rebased onto the accessibility
    // axis by quick-260821-swp, then onto the STYLE axis on 2026-08-22 at
    // the operator's request) — full-width, direct jump, one press =
    // exactly one theme-apply re-render. Sits OUTSIDE the DASH-07 mirror
    // proof by construction (D-23): there is no external-daemon counterpart
    // for this control, it is a one-way view of a state file — and, per
    // this plan's own header note, deliberately NOT part of the D-19-19
    // singleton promotion either.
    //
    // This row shows the STYLE axis; reduce-motion/off moved to
    // Settings > Window manager > Reduce motion. D-01 is still satisfied:
    // it required reduce-motion to be reachable from "a control that is not
    // the style picker", and that Settings row is a SelectRow entirely
    // separate from the Animation style SelectRow beside it.
    //
    // The model is read from `motion-switch.sh --list` rather than written
    // out here. That is deliberate: this task already tripped over THREE
    // separate hardcoded `off|reduced|normal|lively` closed sets that all
    // had to be found and changed together, and a fourth copy of the style
    // list would be the same bug waiting to happen. The parser matches
    // WindowManagerPage.qml's, and `--list`'s "  <key>\t<label>" contract
    // and these two parsers change together, never one without the other.
    // ═══════════════════════════════════════════════════════════════════

    FileView {
        id: motionStyleFile
        path: root.homeDir + "/.local/state/theme/motion-style"
        watchChanges: true
        onFileChanged: reload()
    }
    readonly property string motionStyleRaw: (motionStyleFile.text() || "").trim()
    // Validated against the LIVE list, not a literal — an unknown or empty
    // read falls back to the first listed style rather than to a name that
    // might no longer exist.
    readonly property string motionStyleState: {
        for (var i = 0; i < root.presetModel.length; i++)
            if (root.presetModel[i].value === root.motionStyleRaw)
                return root.motionStyleRaw;
        return root.presetModel.length > 0 ? root.presetModel[0].value : "";
    }

    property var presetModel: []

    Process {
        id: presetListProcess
        running: false
        command: [Quickshell.env("HOME") + "/.config/hypr/scripts/motion-switch.sh", "--list"]
        stdout: StdioCollector {
            id: presetListCollector
        }
        onExited: (exitCode, exitStatus) => {
            var lines = presetListCollector.text.split("\n");
            var opts = [];
            for (var i = 0; i < lines.length; i++) {
                var m = lines[i].match(/^  (\S+)\t(.+)$/);
                if (m)
                    opts.push({ value: m[1], label: m[2], tooltip: "" });
            }
            root.presetModel = opts;
        }
        Component.onCompleted: running = true
    }

    property bool presetPending: false
    readonly property int presetTimeoutMs: 8000

    Timer {
        id: presetWatchdogTimer
        interval: root.presetTimeoutMs
        repeat: false
        onTriggered: root.presetPending = false
    }
    onMotionStyleStateChanged: if (root.presetPending) { root.presetPending = false; presetWatchdogTimer.stop(); }

    Process {
        id: presetProcess
        running: false
        command: []
    }
    function pressPreset(value) {
        if (root.presetPending)
            return;
        root.presetPending = true;
        presetWatchdogTimer.restart();
        // The style is a POSITIONAL argument; only the accessibility axis
        // takes the --accessibility flag.
        presetProcess.command = [root.homeDir + "/.config/hypr/scripts/motion-switch.sh", value];
        presetProcess.running = true;
    }

    // One inline component — an MD3 segmented-button segment.
    component PresetSegment: Item {
        id: segItem

        property int segIndex: 0
        property int segCount: 4
        property string segValue: ""
        property string segLabel: ""
        property string segTooltip: ""
        readonly property bool selected: root.motionStyleState === segValue

        Rectangle {
            id: segFill
            anchors.fill: parent
            color: segItem.selected ? Colours.primary : Qt.alpha(Colours.primary, 0)
            topLeftRadius: segItem.segIndex === 0 ? height / 2 : 0
            bottomLeftRadius: segItem.segIndex === 0 ? height / 2 : 0
            topRightRadius: segItem.segIndex === segItem.segCount - 1 ? height / 2 : 0
            bottomRightRadius: segItem.segIndex === segItem.segCount - 1 ? height / 2 : 0
            Behavior on color {
                enabled: Motion.motionEnabled
                ColorAnimation {
                    duration: Motion.colourDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.colourEasing
                }
            }

            Row {
                anchors.centerIn: parent
                spacing: root.spacingXs

                // The row divides its width by the model length, so moving
                // from three values to five made each segment ~40% narrower.
                // Rather than assume the tick still fits beside the label,
                // it is shown only when the segment can actually hold both —
                // measured off the label's own implicitWidth, not a guessed
                // pixel budget. The filled background remains the primary
                // selection cue either way.
                Text {
                    id: segCheck
                    visible: segItem.selected
                        && segItem.width >= segLabelText.implicitWidth + implicitWidth + root.spacingXs + root.spacingSm
                    text: "check"
                    font.family: root.symbolFontFamily
                    font.pixelSize: root.fontLabel + 2
                    color: Colours.onPrimary
                }
                Text {
                    id: segLabelText
                    text: segItem.segLabel
                    font.pixelSize: root.fontLabel
                    elide: Text.ElideRight
                    width: Math.min(implicitWidth, Math.max(0, segItem.width - root.spacingSm))
                    horizontalAlignment: Text.AlignHCenter
                    color: segItem.selected ? Colours.onPrimary : Colours.onSurfaceVariant
                    Behavior on color {
                        enabled: Motion.motionEnabled
                        ColorAnimation {
                            duration: Motion.colourDuration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Motion.colourEasing
                        }
                    }
                }
            }

            MouseArea {
                id: presetMouseArea
                anchors.fill: parent
                enabled: !root.presetPending
                hoverEnabled: true
                onClicked: root.pressPreset(segItem.segValue)
            }
            // ThemedToolTip (quick-260821-6z1 fix wave) — replaces the
            // bare attached ToolTip shorthand; see ThemedToolTip.qml.
            ThemedToolTip {
                visible: presetMouseArea.containsMouse && segItem.segTooltip !== ""
                text: segItem.segTooltip
                delay: root.tooltipDelayMs
            }
        }
    }

    Item {
        id: presetContainer
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: chipsRow.bottom
        anchors.topMargin: root.spacingSm
        height: root.presetHeight

        Rectangle {
            id: presetOutline
            anchors.fill: parent
            radius: height / 2
            color: "transparent"
            border.width: 1
            border.color: Colours.outline
        }

        Row {
            id: presetRow
            anchors.fill: parent

            Repeater {
                model: root.presetModel
                delegate: PresetSegment {
                    width: presetRow.width / root.presetModel.length
                    height: presetRow.height
                    segIndex: index
                    segCount: root.presetModel.length
                    segValue: modelData.value
                    segLabel: modelData.label
                    segTooltip: modelData.tooltip
                }
            }
        }
    }
}
