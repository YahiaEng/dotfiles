// Probe.qml — the token inspector (12-06, D-10/D-15). Started life in
// Phase 11 as the QS-02 human input-viability instrumentation panel; this
// plan graduates it into the surface that carries TOKEN-01/TOKEN-02
// criterion 1 by styling it FULLY from Colours/Motion while keeping its
// content diagnostic (D-15) — every element is captioned with the exact
// token it consumes, so a fully-coloured panel still reads as an
// instrument, never a shipped surface.
//
// Content, top to bottom (12-UI-SPEC.md "Token Inspector — Surface
// Contract"): header banner, Colour Roles grid (19 roles — see the
// Colours.qml "17 vs 19" note below), Motion — Semantic Pairs, Replay,
// then Phase 11's four original instruments UNCHANGED underneath (counter
// button, text field, hand-edited JSON state label, screen label) — this
// phase does not remove working instrumentation.
//
// QS-03 per-screen fan-out (D-12, Phase 12 arrangement B, unchanged by this
// plan — 12-06 only rewrites the delegate's CONTENT, not the fan-out
// structure): root type is `Variants` over `Quickshell.screens`, each
// screen's delegate is a summon/dismiss `LazyLoader` wrapping a
// `PanelWindow`. `modules/qmldir` (12-01, extended 12-06 with
// Colours/Motion) is what keeps this directory's type resolution stable.
//
// 12-08 (TOKEN-06, D-26, droppable stretch) adds a `Spring / MD3` toggle
// beside the Replay row: the SAME three swatches gain a SpringAnimation
// variant beside their existing bezier NumberAnimation, switchable in
// place, so a human can judge native QML spring physics against the MD3
// bezier baseline on the identical element/property/range. See the
// comment beside `standardReplaySpringAnim` below for the property-naming
// pitfall this variant has to avoid.
import QtQml
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io

Variants {
    id: probeVariants

    // Summon/dismiss state shared across every screen's delegate — not
    // per-screen — so Super+Shift+G toggles every currently-known screen
    // at once (unchanged from 12-01).
    property bool active: false

    // Emitted when any screen's HyprlandFocusGrab clears (click-outside
    // dismiss). shell.qml listens for this to deactivate `active` so every
    // screen's wl_surface is destroyed, not merely hidden (D-02).
    signal dismissRequested()

    model: Quickshell.screens

    delegate: Component {
        LazyLoader {
            // Variants sets `modelData` as an initial property on the
            // delegate root object (not merely a context property for
            // non-Item roots like LazyLoader) — declare it explicitly.
            required property var modelData
            active: probeVariants.active

            PanelWindow {
                id: probeWindow

                // ── Spacing scale (12-UI-SPEC.md, replaces the inherited
                //    ad hoc spacing: 12 / spacing: 8) ────────────────────
                readonly property int spacingXs: 4
                readonly property int spacingSm: 8
                readonly property int spacingMd: 16
                readonly property int spacingLg: 24
                readonly property int spacingXl: 32

                // TOKEN-06 (D-26): which replay variant is currently wired
                // up — false plays the MD3 bezier baseline (unchanged from
                // 12-06), true plays the SpringAnimation variant. Owned
                // here (not Motion.*) because it is a diagnostic-surface
                // toggle, not a token — motion-lint's CHECK A model must
                // never see it as a dangling Motion.* reference.
                property bool springMode: false

                // ui:overflow/E1,E2,E3 backstop: size FROM CONTENT
                // (panelColumn's own natural implicit size) rather than the
                // inherited fixed 360x260 footprint, which 19 colour roles
                // plus 3 motion rows plus a replay section will exceed.
                // panelColumn is positioned (not anchor-filled) below, so
                // this is not a circular binding.
                implicitWidth: panelColumn.implicitWidth + spacingLg * 2
                implicitHeight: panelColumn.implicitHeight + spacingLg * 2

                // Binds this delegate's own screen from modelData — hotplug
                // order can never change which surface lands on which
                // output (QS-03/ordering, unchanged from 12-01).
                screen: modelData

                // D-21: overlay layer, distinct namespace, zero exclusive zone.
                WlrLayershell.layer: WlrLayer.Overlay
                WlrLayershell.namespace: "quickshell-probe"
                WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
                exclusiveZone: 0

                // ── Click-outside dismiss (unchanged from Phase 11) ────
                HyprlandFocusGrab {
                    id: grab
                    windows: [ probeWindow ]
                    active: true
                    onCleared: probeVariants.dismissRequested()
                }

                // ── Header banner data sources — plain-text state files,
                //    not JSON, so a bare FileView (no JsonAdapter) reading
                //    its own .text() is the right tool (12-UI-SPEC.md
                //    "Token Inspector — Surface Contract" item 1). ───────
                FileView {
                    id: currentThemeFile
                    path: Quickshell.env("HOME") + "/.local/state/theme/current-theme"
                    watchChanges: true
                    onFileChanged: reload()
                }
                FileView {
                    id: modeFile
                    path: Quickshell.env("HOME") + "/.local/state/theme/mode"
                    watchChanges: true
                    onFileChanged: reload()
                }
                readonly property string currentThemeName: (currentThemeFile.text() || "").trim() || "unknown"
                readonly property string currentModeName: (modeFile.text() || "").trim() || "unknown"

                // ── Motion row diagnostics — a SEPARATE, independent raw
                //    read of motion.json, deliberately NOT routed through
                //    `Motion.*` (motion-lint's `load_qml_defs()` only
                //    recognises `<key>Duration`/`<key>Easing`/
                //    `motionEnabled` as valid `Motion.*` references — see
                //    Motion.qml's header comment; any OTHER `Motion.xxx`
                //    name, e.g. a hypothetical `Motion.hasMotionTokens` or
                //    `Motion.pairs`, is a motion-lint CHECK-A dangling
                //    reference, binary-verified this plan by hitting it
                //    live). This read supplies ONLY presence/validity
                //    booleans for the UI's empty/partial markup below —
                //    every actual duration/easing VALUE the rows display
                //    still comes exclusively from the six allowed
                //    `Motion.*` properties, so D-01's "no number written
                //    twice" principle holds; this is metadata, not a
                //    second source of truth for the numbers themselves.
                FileView {
                    id: motionRawFile
                    path: Quickshell.env("HOME") + "/.local/state/theme/motion.json"
                    watchChanges: true
                    onFileChanged: reload()
                }
                readonly property var motionRawSemantic: {
                    var txt = motionRawFile.text();
                    if (!txt) return null;
                    try {
                        var data = JSON.parse(txt);
                        return data.semantic || null;
                    } catch (e) {
                        return null;
                    }
                }
                readonly property bool hasMotionTokensLocal: !!(motionRawSemantic && Object.keys(motionRawSemantic).length > 0)

                function motionRowData(key, easingDisplayName, duration, easing) {
                    var entry = motionRawSemantic ? motionRawSemantic[key] : null;
                    var durationValid = !!entry && typeof entry.duration_ms === "number" && entry.duration_ms > 0;
                    var easingValid = !!entry && Array.isArray(entry.bezier) && entry.bezier.length === 6;
                    return {
                        name: key,
                        easingName: easingDisplayName,
                        duration: duration,
                        easing: easing,
                        durationValid: durationValid,
                        easingValid: easingValid
                    };
                }

                // D-25's fixed three semantic pairs, hardcoded here (not
                // discovered) since only these three are wired to anything
                // real this phase — every VALUE still reads live from the
                // allowed `Motion.*` properties; only the pair NAMES/
                // easing-display-names are literals, matching D-25's own
                // "trimmed semantic layer" fencing.
                readonly property var motionRows: [
                    motionRowData("standard", "standard", Motion.standardDuration, Motion.standardEasing),
                    motionRowData("emphasized-in", "emphasized-decelerate", Motion.emphasizedInDuration, Motion.emphasizedInEasing),
                    motionRowData("emphasized-out", "emphasized-accelerate", Motion.emphasizedOutDuration, Motion.emphasizedOutEasing)
                ]

                // ── Hand-edited JSON state (Phase 11 instrument, D-03/D-20
                //    /QS-04, UNCHANGED) plus D-17's live re-colour mirror
                //    (observedPrimary) — same adapter, same write path, so
                //    theme-stress-test can assert live re-colour off disk
                //    without a human or a screenshot. ────────────────────
                FileView {
                    id: probeState
                    path: Quickshell.env("HOME") + "/.local/state/quickshell/probe.json"
                    watchChanges: true
                    onFileChanged: reload()
                    onAdapterUpdated: writeAdapter()

                    JsonAdapter {
                        id: probeAdapter
                        property string label: "unset"
                        // D-17: kept in lock-step with whatever
                        // Colours.primary currently resolves to via the
                        // Binding below — a script reading probe.json off
                        // disk sees the SAME value the swatch is painted
                        // with, not a second, possibly-stale source.
                        property string observedPrimary: ""
                    }
                }
                // A declarative `Binding` here would be WRONG (binary-
                // verified, Task 2): JsonAdapter's own file-load imperatively
                // sets each declared property from the persisted JSON on
                // every read, which QML's "assigning breaks the binding"
                // rule then permanently detaches — the swatch's live colour
                // would silently stop mirroring into probe.json the moment
                // probe.json is ever re-read with its own historical
                // "observedPrimary" value. Imperative re-assignment on every
                // change (mirroring how `probeAdapter.label` is already a
                // plain read/write property, never a Binding target) has no
                // such conflict.
                Component.onCompleted: probeAdapter.observedPrimary = Colours.primary
                Connections {
                    target: Colours
                    function onPrimaryChanged() {
                        probeAdapter.observedPrimary = Colours.primary;
                    }
                }

                Rectangle {
                    id: panelBackground
                    anchors.fill: parent
                    color: Colours.surface
                    Behavior on color {
                        enabled: Motion.motionEnabled
                        ColorAnimation {
                            duration: Motion.standardDuration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Motion.standardEasing
                        }
                    }

                    Column {
                        id: panelColumn
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.margins: probeWindow.spacingLg
                        spacing: probeWindow.spacingXl

                        // ── 1. Header banner (Display, 22px/600) ────────
                        Label {
                            text: "Screen: " + (probeWindow.screen ? probeWindow.screen.name : "unknown")
                                + " · Theme: " + probeWindow.currentThemeName
                                + " (" + probeWindow.currentModeName + ")"
                            width: 400
                            elide: Text.ElideRight
                            font.pixelSize: 22
                            font.weight: Font.DemiBold
                            color: Colours.primary
                            Behavior on color {
                                enabled: Motion.motionEnabled
                                ColorAnimation { duration: Motion.standardDuration }
                            }
                        }

                        // ── 2. Colour Roles (Heading, 18px/600) ─────────
                        Column {
                            spacing: probeWindow.spacingSm

                            Label {
                                text: "Colour Roles"
                                font.pixelSize: 18
                                font.weight: Font.DemiBold
                                color: Colours.primary
                            }

                            Grid {
                                id: swatchGrid
                                columns: 5
                                spacing: probeWindow.spacingSm

                                Repeater {
                                    id: swatchRepeater
                                    model: Colours.roles

                                    delegate: Column {
                                        id: swatchCell
                                        required property var modelData
                                        spacing: probeWindow.spacingXs
                                        readonly property bool unmapped: modelData.hex.toUpperCase() === "#FF00FF"

                                        Rectangle {
                                            width: 40
                                            height: 40
                                            radius: 6
                                            color: swatchCell.modelData.hex
                                            border.width: 1
                                            border.color: Colours.outline
                                            Behavior on color {
                                                enabled: Motion.motionEnabled
                                                ColorAnimation {
                                                    duration: Motion.standardDuration
                                                    easing.type: Easing.BezierSpline
                                                    easing.bezierCurve: Motion.standardEasing
                                                }
                                            }
                                        }

                                        Label {
                                            // Copywriting Contract: "{token-name} (unmapped)"
                                            // — the debug-magenta sentinel IS the detection
                                            // signal (there is no separate success flag).
                                            text: swatchCell.unmapped
                                                ? (swatchCell.modelData.name + " (unmapped)")
                                                : swatchCell.modelData.name
                                            font.pixelSize: 12
                                            font.weight: Font.Normal
                                            color: swatchCell.unmapped ? Colours.error : Colours.onSurface
                                        }
                                    }
                                }
                            }
                        }

                        // ── 3. Motion — Semantic Pairs ──────────────────
                        Column {
                            spacing: probeWindow.spacingSm

                            Label {
                                text: "Motion — Semantic Pairs"
                                font.pixelSize: 18
                                font.weight: Font.DemiBold
                                color: Colours.primary
                            }

                            // ui:empty/E2: a missing/empty semantic layer
                            // renders ONE explicit row, never a gap.
                            Label {
                                visible: !probeWindow.hasMotionTokensLocal
                                text: "no motion tokens loaded — check motion.json"
                                font.pixelSize: 14
                                color: Colours.onSurface
                            }

                            Column {
                                visible: probeWindow.hasMotionTokensLocal
                                spacing: probeWindow.spacingXs

                                Repeater {
                                    model: probeWindow.hasMotionTokensLocal ? probeWindow.motionRows : []

                                    delegate: Row {
                                        required property var modelData
                                        spacing: probeWindow.spacingMd

                                        Label {
                                            text: modelData.name
                                            width: 140
                                            font.pixelSize: 14
                                            color: Colours.onSurface
                                        }
                                        // ui:error/E2 + ui:partial/E2: each
                                        // field is marked independently —
                                        // the row is never hidden, even if
                                        // only one of the two is broken.
                                        Label {
                                            text: modelData.durationValid ? (modelData.duration + "ms") : "(undefined)"
                                            width: 70
                                            font.pixelSize: 14
                                            color: modelData.durationValid ? Colours.onSurface : Colours.error
                                        }
                                        Label {
                                            text: modelData.easingValid ? modelData.easingName : "(undefined)"
                                            font.pixelSize: 14
                                            color: modelData.easingValid ? Colours.onSurface : Colours.error
                                        }
                                    }
                                }
                            }
                        }

                        // ── 4. Replay ────────────────────────────────────
                        Column {
                            spacing: probeWindow.spacingSm

                            Label {
                                text: "Replay"
                                font.pixelSize: 18
                                font.weight: Font.DemiBold
                                color: Colours.primary
                            }

                            Row {
                                spacing: probeWindow.spacingSm

                                Button {
                                    id: replayButton
                                    text: "Replay motion"
                                    font.pixelSize: 14
                                    onClicked: {
                                        // Pitfall 4 (12-RESEARCH.md): the base
                                        // Animation type has NO `enabled`
                                        // property — only Behavior does — so an
                                        // imperatively-triggered animation must
                                        // be gated at the TRIGGER, not via a
                                        // property binding. Clicked mid-replay
                                        // restarts from frame 0 across all
                                        // three pairs simultaneously (stop()
                                        // then start()) — never disabled, never
                                        // a silent no-op (D-16/ui:loading E4).
                                        // At motion-scale "off", the pairs stay
                                        // stopped: no animation at all, which
                                        // is the tested/expected posture, not a
                                        // bug.
                                        //
                                        // TOKEN-06 (D-26): one imperative gate,
                                        // reused — the springMode branch below
                                        // is still governed by the same single
                                        // Motion.motionEnabled check, not a
                                        // second gating mechanism.
                                        standardReplayAnim.stop();
                                        emphasizedInReplayAnim.stop();
                                        emphasizedOutReplayAnim.stop();
                                        standardReplaySpringAnim.stop();
                                        emphasizedInReplaySpringAnim.stop();
                                        emphasizedOutReplaySpringAnim.stop();
                                        if (Motion.motionEnabled) {
                                            if (probeWindow.springMode) {
                                                standardReplaySpringAnim.start();
                                                emphasizedInReplaySpringAnim.start();
                                                emphasizedOutReplaySpringAnim.start();
                                            } else {
                                                standardReplayAnim.start();
                                                emphasizedInReplayAnim.start();
                                                emphasizedOutReplayAnim.start();
                                            }
                                        }
                                    }
                                }

                                // TOKEN-06 (D-26, droppable stretch, criterion
                                // 5): switches the replay row in place between
                                // the MD3 bezier baseline and the
                                // SpringAnimation variant on the SAME three
                                // swatches — no separate element, no separate
                                // trigger. Deleting this Button and the
                                // SpringAnimation declarations below restores
                                // 12-06's inspector exactly (standing
                                // constraint 5 droppability).
                                Button {
                                    id: springToggleButton
                                    text: "Spring / MD3"
                                    font.pixelSize: 14
                                    onClicked: probeWindow.springMode = !probeWindow.springMode
                                }
                            }

                            // Names which variant is currently wired to the
                            // Replay button, per 12-UI-SPEC.md item 6.
                            Label {
                                id: springModeLabel
                                text: "Playing: " + (probeWindow.springMode ? "Spring" : "MD3")
                                font.pixelSize: 12
                                color: Colours.onSurface
                            }

                            Row {
                                spacing: probeWindow.spacingLg

                                Column {
                                    spacing: probeWindow.spacingXs
                                    Rectangle {
                                        id: standardReplaySwatch
                                        width: 24
                                        height: 24
                                        radius: 12
                                        color: Colours.tertiary
                                        // quick-260821-swp (R-2): "x" is a
                                        // spatial (position) property —
                                        // retargeted onto spatial-move, the
                                        // same name every real windowsMove/
                                        // slide site now binds. Numerically
                                        // identical to the old standard
                                        // duration+easing under `md3`
                                        // (Task 1's seed), so this Replay
                                        // swatch is unchanged today and
                                        // starts reflecting the active
                                        // style the moment a non-md3 style
                                        // is selected.
                                        NumberAnimation on x {
                                            id: standardReplayAnim
                                            running: false
                                            from: 0
                                            to: 80
                                            duration: Motion.spatialMoveDuration
                                            easing.type: Easing.BezierSpline
                                            easing.bezierCurve: Motion.spatialMoveEasing
                                        }
                                        // TOKEN-06 (D-26) spring variant, same
                                        // element/property/range as the bezier
                                        // NumberAnimation above — the ONLY
                                        // difference is the interpolation, so
                                        // the human comparison is honest.
                                        //
                                        // Pitfall 5 (12-RESEARCH.md, binary-
                                        // verified against the installed
                                        // qt6-declarative 6.11.1-3): this
                                        // QQuickSpringAnimation build exposes
                                        // exactly `velocity`, `spring`,
                                        // `damping`, `epsilon`, `modulus` and
                                        // `mass` — nothing more. `spring` is
                                        // its own name for the physical spring
                                        // constant, and `damping` for the
                                        // damping coefficient; there is no
                                        // Compose-borrowed property for either
                                        // a spring rate or a damping ratio on
                                        // this type. Assigning a name QML does
                                        // not recognise here is accepted
                                        // silently — the property is simply
                                        // missing, no warning, no error — and
                                        // the animation then runs on defaults,
                                        // which LOOKS like "springs are
                                        // indistinguishable from bezier" for
                                        // entirely the wrong reason. Because
                                        // spring/damping/mass is a physical
                                        // parameterisation and Compose's is a
                                        // different one entirely, there is no
                                        // 1:1 numeric port between the two —
                                        // the values below are tuned by feel,
                                        // not against a verified constant.
                                        // 12-RESEARCH.md's Assumptions Log
                                        // (A1) could not confirm Material 3
                                        // Expressive's official spring
                                        // constants from any primary source,
                                        // so nobody should later "correct"
                                        // these toward a number found on a
                                        // blog — D-27's human render-and-look
                                        // gate is the actual arbiter of feel
                                        // here.
                                        SpringAnimation {
                                            id: standardReplaySpringAnim
                                            target: standardReplaySwatch
                                            property: "x"
                                            running: false
                                            from: 0
                                            to: 80
                                            spring: 300
                                            damping: 20
                                            mass: 1
                                        }
                                    }
                                    Label { text: "standard → spatial-move"; font.pixelSize: 12; color: Colours.onSurface }
                                }

                                Column {
                                    spacing: probeWindow.spacingXs
                                    Rectangle {
                                        id: emphasizedInReplaySwatch
                                        width: 24
                                        height: 24
                                        radius: 12
                                        color: Colours.tertiary
                                        // quick-260821-swp (R-2): retargeted
                                        // onto spatial-in — see
                                        // standardReplayAnim's comment above.
                                        NumberAnimation on x {
                                            id: emphasizedInReplayAnim
                                            running: false
                                            from: 0
                                            to: 80
                                            duration: Motion.spatialInDuration
                                            easing.type: Easing.BezierSpline
                                            easing.bezierCurve: Motion.spatialInEasing
                                        }
                                        // TOKEN-06 (D-26) spring variant — see
                                        // the full property-naming/no-1:1-port
                                        // rationale beside standardReplaySpringAnim
                                        // above; identical reasoning applies here.
                                        SpringAnimation {
                                            id: emphasizedInReplaySpringAnim
                                            target: emphasizedInReplaySwatch
                                            property: "x"
                                            running: false
                                            from: 0
                                            to: 80
                                            spring: 300
                                            damping: 20
                                            mass: 1
                                        }
                                    }
                                    Label { text: "emphasized-in → spatial-in"; font.pixelSize: 12; color: Colours.onSurface }
                                }

                                Column {
                                    spacing: probeWindow.spacingXs
                                    Rectangle {
                                        id: emphasizedOutReplaySwatch
                                        width: 24
                                        height: 24
                                        radius: 12
                                        color: Colours.tertiary
                                        // quick-260821-swp (R-2): retargeted
                                        // onto spatial-out — see
                                        // standardReplayAnim's comment above.
                                        NumberAnimation on x {
                                            id: emphasizedOutReplayAnim
                                            running: false
                                            from: 0
                                            to: 80
                                            duration: Motion.spatialOutDuration
                                            easing.type: Easing.BezierSpline
                                            easing.bezierCurve: Motion.spatialOutEasing
                                        }
                                        // TOKEN-06 (D-26) spring variant — see
                                        // the full property-naming/no-1:1-port
                                        // rationale beside standardReplaySpringAnim
                                        // above; identical reasoning applies here.
                                        SpringAnimation {
                                            id: emphasizedOutReplaySpringAnim
                                            target: emphasizedOutReplaySwatch
                                            property: "x"
                                            running: false
                                            from: 0
                                            to: 80
                                            spring: 300
                                            damping: 20
                                            mass: 1
                                        }
                                    }
                                    Label { text: "emphasized-out → spatial-out"; font.pixelSize: 12; color: Colours.onSurface }
                                }
                            }
                        }

                        // ── Phase 11 instruments (QS-02 proof surface) —
                        //    UNCHANGED underneath everything above. ───────
                        Column {
                            spacing: probeWindow.spacingMd

                            Row {
                                spacing: probeWindow.spacingSm

                                Button {
                                    id: counterButton
                                    text: "Click me"
                                    onClicked: counterLabel.count += 1
                                }

                                Label {
                                    id: counterLabel
                                    property int count: 0
                                    text: "Count: " + count
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }

                            TextField {
                                id: probeTextField
                                placeholderText: "Type here"
                            }

                            Label {
                                id: stateLabel
                                text: "State label: " + probeAdapter.label
                            }

                            Label {
                                id: screenLabel
                                text: "Screen: " + (probeWindow.screen ? probeWindow.screen.name : "unknown")
                            }
                        }
                    }
                }
            }
        }
    }
}
