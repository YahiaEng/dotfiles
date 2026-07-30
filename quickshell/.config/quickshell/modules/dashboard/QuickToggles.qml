// QuickToggles.qml — the quick-toggle grid (Phase 14 Plan 04, D-22..D-27).
//
// Three swaync-mirrored chips (Gaming, DND, Dark) on D-22's truth-driven
// pending model: press acknowledges instantly (ripple + pending pulse),
// the lit state is a pure read of the exact same backend swaync's own
// buttons-grid reads/execs (D-27) and is NEVER assigned by a press — a
// failed/cancelled/hung backend leaves the chip on whatever the backend
// actually holds.
//
// Beneath the three chips, a full-width `Off | Reduced | Normal | Lively`
// segmented row jumps the motion-scale axis directly — one press, exactly
// one `theme-apply` re-render, no cycling transit through `off` (D-24).
// D-23's sentence, restated here rather than left implicit: this control
// has NO swaync counterpart — it is a one-way view of a state file — so it
// sits OUTSIDE the DASH-07 mirror proof by construction. The asymmetry
// between three mirrored chips and one unmirrored row is a recorded
// decision, not a gap.
//
// ── Design constants — NOT read off `dashboardWindow` ───────────────────
// Dashboard.qml's header comment states plans 14-03..14-08 should read its
// spacing/type-scale/icon constants off `dashboardWindow` instead of
// re-declaring them. That mechanism does not actually exist yet: `id`-based
// lookup in QML is lexical to the declaring FILE, and `DashboardTab`/
// `QuickToggles` are separate registered component types instantiated
// inside `dashboardWindow`'s object tree, not textually nested inside
// Dashboard.qml — so a bare `dashboardWindow.spacingLg` reference from this
// file would not resolve (and 14-03's own tab stubs never demonstrated
// reaching it either: `DashboardTab.qml`'s placeholder `Text` still hardcodes
// `font.pixelSize: 16`, not a constant read off the root). Per 14-04-PLAN.md's
// own fallback instruction, this file declares its own copies of exactly the
// constants it needs, sourced from 14-UI-SPEC.md's Spacing Scale/Typography
// tables and 14-02-SUMMARY.md's recorded font family — consolidating every
// tab onto one shared constants surface is left to 14-08's composition pass.
//
// ── Round-2 fix, 14-08's render gate (2026-07-30) ────────────────────────
// This file lives outside 14-08-PLAN.md's declared `files_modified`
// (`DashboardTab.qml` only) — touched here as a render-gate-driven
// deviation per that plan's own workflow rules, carried to the SUMMARY.
// Feedback: "A fresh user will not know what their function is" — the
// three toggle chips already carried an icon AND a label ("Gaming"/"DND"/
// "Dark") beneath it, but "DND" is an unexplained acronym to a fresh user
// and none of the six controls (3 chips + 4 motion-scale segments) stated
// what a PRESS actually does, only what it's named. Fixed two ways,
// without touching layout, sizing or the existing D-22 pending model:
//   1. "DND" -> "Do Not Disturb" in the chip's own visible label (chip
//      width comfortably fits it at this font size — no truncation).
//   2. A `QtQuick.Controls` `ToolTip` (new import, same module MediaTab.qml
//      already uses for its `Slider`s — no new styling surface) on every
//      chip and every motion-scale segment, hover-revealed, stating in one
//      short sentence what pressing that control actually does. This is
//      "another mechanism consistent with the drawer's Material language"
//      per the render-gate's own suggested wording, additive only — no
//      existing visible text, color or animation changes.
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
    // Re-verified directly this plan (throwaway qml6 grabToImage proof,
    // FILL:0 vs FILL:1 visually distinct outline-vs-filled glyphs) before
    // being relied on below. If a future build ever regresses this, flip
    // this one property to fix the lit-state language back to a static
    // glyph weight — nothing else in this file needs to change.
    readonly property bool fillAxisAvailable: true

    readonly property int chipHeight: 72
    readonly property int chipRadius: 16
    readonly property int presetHeight: 48

    property string homeDir: Quickshell.env("HOME")

    // D-41 widget-state register — the shared three-name vocabulary every
    // modules/dashboard/ file carries. "empty" is kept in the vocabulary
    // list below purely for register consistency: it is structurally
    // inapplicable to this widget (14-UI-SPEC.md's Dismissed section:
    // "Toggle grid — empty: chips always render, D-05 audit") since every
    // chip has a hard-coded default for a missing backend file, so
    // `widgetState` itself never actually takes that value.
    readonly property var widgetStateVocabulary: ["populated", "pending", "empty"]
    readonly property string widgetState: pendingChip !== "" ? "pending" : "populated"

    implicitHeight: chipsRow.height + spacingSm + presetRow.height
    implicitWidth: 0 // no meaningful own width — the mounting parent (14-08) sizes this via anchors

    // ═══════════════════════════════════════════════════════════════════
    // Backend truth table (D-27) — verified against swaync/config.json's
    // `buttons-grid.actions` (post Task-1 flip) directly in this plan's
    // read_first pass. Each row below is a side-by-side comparison, kept
    // here as the SUMMARY's source of truth for its own copy of this table:
    //
    //   Gaming — swaync: exec `gaming-mode-toggle.sh`,
    //            read `cat ~/.cache/gaming-mode 2>/dev/null || echo off`,
    //            lit iff value == "on".
    //            QML: same script, same path, same "off" default, same
    //            "on" lit test (gamingState below).
    //   DND    — swaync: exec `swaync-client -dn`/`-df` (explicit on/off
    //            pair, chosen by swaync's own prior toggle state), read
    //            `swaync-client -D`.
    //            QML: same explicit on/off pair chosen by the CURRENT
    //            watched dndState (dnd-on when unlit, dnd-off when lit),
    //            same read surface (subscribe stream + `-D` poll fallback,
    //            see below) — never the single unconditional toggle verb.
    //   Dark   — swaync (post Task-1 flip): exec `theme-switch.sh`,
    //            read `cat ~/.local/state/theme/mode 2>/dev/null || echo dark`,
    //            lit iff value == "dark".
    //            QML: same script, same path, same "dark" default, same
    //            "dark" lit test (darkState below). theme-switch.sh takes
    //            no arguments and opens a walker palette picker — pressing
    //            this chip launches walker, walker takes focus, D-13's
    //            focus-loss rule dismisses the drawer, and the pending
    //            affordance dies with the destroyed surface. This is
    //            implemented exactly as D-27 specifies (verified from
    //            config) rather than "improved" into a direct flip: no
    //            such backend exists, and inventing one would be the
    //            second source of truth DASH-07 forbids. Carried to the
    //            render gate (Task 4) for the user to accept or reject.
    // ═══════════════════════════════════════════════════════════════════

    // ── Gaming state reader (bare FileView, Probe.qml's shape) ──────────
    FileView {
        id: gamingFile
        path: root.homeDir + "/.cache/gaming-mode"
        watchChanges: true
        onFileChanged: reload()
    }
    readonly property string gamingRaw: (gamingFile.text() || "").trim()
    readonly property bool gamingState: (gamingRaw.length > 0 ? gamingRaw : "off") === "on"

    // ── Dark (theme mode) state reader — same shape ─────────────────────
    FileView {
        id: modeFile
        path: root.homeDir + "/.local/state/theme/mode"
        watchChanges: true
        onFileChanged: reload()
    }
    readonly property string modeRaw: (modeFile.text() || "").trim()
    readonly property bool darkState: (modeRaw.length > 0 ? modeRaw : "dark") === "dark"

    // ── DND state — the one source with no file to watch. Long-form
    //    `--subscribe` (not `-s`) so the process is unambiguously
    //    identifiable by name for the zero-idle-footprint lifetime
    //    assertion (D-14, T-14-16). Every line is one JSON object
    //    (`{ "count", "dnd", "visible", "inhibited" }`, verified live this
    //    plan by toggling DND while subscribed) parsed defensively — a
    //    malformed/truncated line or a missing `dnd` field leaves the last
    //    known value standing rather than reading as unlit (14-RESEARCH.md
    //    Security Domain V5, matching Colours.qml/Motion.qml's discipline).
    property bool dndState: false

    // OQ1 verdict (14-RESEARCH.md Open Question 1 / D-27's named
    // research-verify item): **subscribe-emits-dnd**. Live-observed this
    // plan: `swaync-client --subscribe` was started, then DND was flipped
    // via `swaync-client -dn`/`-df` from OUTSIDE any drawer instance, and
    // the subscribe stream emitted a fresh `{"dnd":true,...}` /
    // `{"dnd":false,...}` line for every flip with no polling involved.
    // The polling fallback below is still wired (not merely described) in
    // case a future swaync build or config regresses this, guarded by the
    // grace flag so it never arms while subscribe is doing its job.
    property bool dndSubscribeSeen: false

    Process {
        id: dndSubscribeProcess
        running: true
        command: ["swaync-client", "--subscribe"]
        stdout: SplitParser {
            onRead: (line) => {
                try {
                    const payload = JSON.parse(line);
                    if (payload && typeof payload.dnd === "boolean") {
                        root.dndState = payload.dnd;
                        root.dndSubscribeSeen = true;
                    }
                } catch (e) {
                    // malformed/truncated line — keep the last-good value
                }
            }
        }
    }

    // One-shot grace window: if subscribe hasn't produced a single valid
    // line by the time this fires, arm the poller. Deliberately an
    // `interval:`-keyed Timer (not a `duration:`-keyed property) — see
    // motion-lint's CHECK B regex, which only anchors on `duration\s*:`.
    Timer {
        id: dndSubscribeGraceTimer
        interval: 4000
        running: true
        repeat: false
        onTriggered: {
            if (!root.dndSubscribeSeen)
                dndPollTimer.running = true;
        }
    }

    Process {
        id: dndPollProcess
        running: false
        command: ["swaync-client", "-D"]
        stdout: SplitParser {
            onRead: (line) => {
                const v = line.trim();
                if (v === "true" || v === "false")
                    root.dndState = (v === "true");
            }
        }
    }

    Timer {
        id: dndPollTimer
        interval: 2000
        running: false
        repeat: true
        onTriggered: dndPollProcess.running = true
    }

    // ═══════════════════════════════════════════════════════════════════
    // The pending model (D-22) — ONE property naming which chip (if any)
    // is currently in flight. The lit state above is read-only and never
    // assigned by a press; this is the whole of what makes drift between
    // the two grids structurally impossible.
    // ═══════════════════════════════════════════════════════════════════
    property string pendingChip: "" // "" | "gaming" | "dnd" | "dark"

    // Backend watchdog — NOT a motion token: a timeout riding the
    // motion-scale axis would collapse to zero at `off` and revert a chip
    // before any backend could ever answer. ~3s per 14-UI-SPEC.md's pending
    // row. Declared as a Timer `interval`, deliberately not a `duration:`
    // property, for the same motion-lint CHECK B reason noted above.
    readonly property int chipTimeoutMs: 3000

    Timer {
        id: chipWatchdogTimer
        interval: root.chipTimeoutMs
        repeat: false
        onTriggered: root.pendingChip = ""
    }

    onGamingStateChanged: if (root.pendingChip === "gaming") { root.pendingChip = ""; chipWatchdogTimer.stop(); }
    onDarkStateChanged: if (root.pendingChip === "dark") { root.pendingChip = ""; chipWatchdogTimer.stop(); }
    onDndStateChanged: if (root.pendingChip === "dnd") { root.pendingChip = ""; chipWatchdogTimer.stop(); }

    // ── Command construction (T-14-13) — every command below is a fixed
    //    argv array. Its only computed element is the home-prefixed script
    //    path; every other element is a double-quoted literal. No value
    //    read from any state source or process output ever reaches a
    //    command array, and nothing is handed to a shell interpreter. ─────
    Process {
        id: gamingProcess
        running: false
        command: [root.homeDir + "/.config/hypr/scripts/gaming-mode-toggle.sh"]
    }
    Process {
        id: dndProcess
        running: false
        command: ["swaync-client", "-dn"]
    }
    // ── Dark chip's process — startDetached(), not `running: true` ─────
    // (render-gate regression fix, checkpoint feedback 2026-07-29):
    // D-27's own assumption says pressing Dark launches walker, walker
    // takes focus, and D-13's focus-loss rule dismisses THIS drawer. That
    // dismissal destroys QuickToggles' whole item tree, including this
    // `Process` — and a lifetime-bound `running: true` Process is killed
    // when its QML object is destroyed (Quickshell.Io.Process ties the
    // child's lifetime to the object unless explicitly detached). Killing
    // theme-switch.sh's bash mid-flight does NOT kill walker itself (a
    // grandchild, orphaned rather than terminated) — reproduced directly
    // this plan by launching the script, SIGTERM-ing its direct-child PID
    // ~0.6s later (mimicking the drawer's own destroy timing), and
    // observing exactly the reported bug: walker's window stays open and
    // visibly clickable, but selecting a palette does nothing at all,
    // because the parent script that would have called `theme-apply` on
    // walker's selection is already dead. `startDetached()` launches the
    // same fixed argv fully independent of this object's lifetime, so the
    // whole chain (walker -> theme-apply) survives the drawer's dismissal
    // and completes normally — matching what D-27's own assumption
    // actually promised (the mode file changes and the chip picks up the
    // new state on next summon) rather than silently discarding it. The
    // other three commands (`gamingProcess`/`dndProcess`/`presetProcess`)
    // are unaffected: none of them launches a focus-stealing surface, so
    // none of them can race the drawer's own destruction and `running:
    // true`'s pending-state tracking is correct for all three.
    Process {
        id: darkProcess
        command: [root.homeDir + "/.config/hypr/scripts/theme-switch.sh"]
    }

    function pressGaming() {
        if (root.pendingChip !== "")
            return;
        root.pendingChip = "gaming";
        chipWatchdogTimer.restart();
        gamingProcess.running = true;
    }

    function pressDnd() {
        if (root.pendingChip !== "")
            return;
        root.pendingChip = "dnd";
        chipWatchdogTimer.restart();
        // The explicit on/off pair, chosen by the CURRENT watched state —
        // dnd-on when unlit, dnd-off when lit — never the single
        // unconditional toggle verb (D-27's own phrasing).
        dndProcess.command = root.dndState ? ["swaync-client", "-df"] : ["swaync-client", "-dn"];
        dndProcess.running = true;
    }

    function pressDark() {
        if (root.pendingChip !== "")
            return;
        root.pendingChip = "dark";
        chipWatchdogTimer.restart();
        // startDetached() (see darkProcess's own header comment above) —
        // NOT `darkProcess.running = true`. The drawer is expected to
        // dismiss the instant walker takes focus (D-13), which would
        // otherwise kill this process mid-flight before a palette could
        // ever be chosen.
        darkProcess.startDetached();
    }

    function chipLitFor(name) {
        switch (name) {
        case "gaming": return root.gamingState;
        case "dnd": return root.dndState;
        case "dark": return root.darkState;
        }
        return false;
    }

    function pressChipByName(name) {
        switch (name) {
        case "gaming": pressGaming(); break;
        case "dnd": pressDnd(); break;
        case "dark": pressDark(); break;
        }
    }

    // ── Chips (D-25) — swaync's own order: Gaming, DND, Dark. Glyph picks
    //    are discretion (all Material Symbols Rounded ligature names,
    //    live-confirmed to render as real glyphs, not tofu, via a
    //    throwaway qml6 grabToImage proof this plan): a game controller for
    //    Gaming, a do-not-disturb circle for DND (the lit-direction glyph
    //    semantics are explicitly discretion in CONTEXT — one static glyph
    //    name is shown regardless of state, with FILL/colour carrying the
    //    lit/unlit language, matching the Gaming/Dark chips' own treatment
    //    rather than swapping to a second "_off" glyph name), and a
    //    crescent moon for Dark. ────────────────────────────────────────
    readonly property var chipModel: [
        { name: "gaming", label: "Gaming", glyph: "sports_esports", tooltip: "Toggle gaming mode — disables idle timeout and notification popups while you play" },
        // Round-2 fix: "DND" was an unexplained acronym to a fresh user —
        // spelled out in the visible label itself, not just the tooltip.
        { name: "dnd", label: "Do Not Disturb", glyph: "do_not_disturb_on", tooltip: "Toggle Do Not Disturb — silences notifications" },
        { name: "dark", label: "Dark", glyph: "dark_mode", tooltip: "Open the theme picker to switch the desktop's colour palette" }
    ]

    // One inline component definition — all three chips are the same
    // object with different data (name/label/glyph), per the plan's own
    // "one inline component defining a chip" instruction.
    component ToggleChip: Item {
        id: chipItem

        property string chipName: ""
        property string chipLabel: ""
        property string chipGlyph: ""
        // Round-2 fix — a one-sentence hover explanation of what pressing
        // this chip actually DOES, distinct from the always-visible
        // icon+label pair above, which only says what it's named.
        property string chipTooltip: ""
        readonly property bool lit: root.chipLitFor(chipName)
        readonly property bool pending: root.pendingChip === chipName

        // Smoothly interpolated 0..1 lit progress — drives both the
        // container's tonal fill (via the Behavior below) and, when the
        // FILL axis is available, the glyph's own outline-to-filled
        // interpolation. Both effects ride the SAME standard motion pair
        // (Probe.qml's Behavior-on-color shape) so they land together.
        property real litProgress: lit ? 1 : 0
        Behavior on litProgress {
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
                    duration: Motion.standardDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.standardEasing
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
                // At `off` motion scale Motion.motionEnabled is false, so
                // this whole animation never runs — the pending affordance
                // at `off` is carried by the non-interactive appearance
                // alone (see MouseArea.enabled below). A chip that looks
                // identical pending and idle at `off` is intentional, not
                // a bug: recorded here so the next reader finds this
                // decision rather than re-discovering it.
            }

            Column {
                anchors.centerIn: parent
                spacing: root.spacingXs

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: chipItem.chipGlyph
                    font.family: root.symbolFontFamily
                    font.pixelSize: root.iconSizeMd
                    // FILL-axis branch: 14-02 recorded `fill-axis-renders`
                    // live on this build, so the glyph itself interpolates
                    // outline->filled together with the container's tonal
                    // fill above. If `root.fillAxisAvailable` were ever
                    // false, this binding is skipped entirely and the
                    // glyph stays at one static weight, relying on the
                    // container fill alone for the lit-state language (the
                    // alternative 14-02 handed forward).
                    font.variableAxes: root.fillAxisAvailable ? { "FILL": chipItem.litProgress } : ({})
                    color: chipItem.lit ? Colours.onPrimary : Colours.onSurfaceVariant
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
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: chipItem.chipLabel
                    font.pixelSize: root.fontLabel
                    color: chipItem.lit ? Colours.onPrimary : Colours.onSurfaceVariant
                    Behavior on color {
                        enabled: Motion.motionEnabled
                        ColorAnimation {
                            duration: Motion.standardDuration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Motion.standardEasing
                        }
                    }
                }
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                // The literal idempotency mechanism (D-22): a chip whose
                // name matches the pending one is non-interactive — no
                // press event reaches this MouseArea at all while pending,
                // so a double press produces no ripple and issues no
                // second command.
                enabled: !chipItem.pending
                // Round-2 fix — hover-revealed tooltip explaining what the
                // press DOES, additive to the always-visible icon+label.
                hoverEnabled: true
                ToolTip.visible: mouseArea.containsMouse && chipItem.chipTooltip !== ""
                ToolTip.text: chipItem.chipTooltip
                ToolTip.delay: 400
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
                onClicked: root.pressChipByName(chipItem.chipName)

                NumberAnimation {
                    id: rippleGrowAnim
                    target: rippleCircle
                    properties: "width,height"
                    duration: Motion.emphasizedInDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.emphasizedInEasing
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
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════════
    // Motion-scale segmented row (D-24) — full-width, direct jump, one
    // press = exactly one theme-apply re-render. Sits OUTSIDE the DASH-07
    // mirror proof by construction (D-23 — restated in the header comment
    // and the SUMMARY): there is no swaync counterpart for this control,
    // it is a one-way view of a state file.
    // ═══════════════════════════════════════════════════════════════════

    // The committed selection is a direct read of the state file — NOT of
    // `Motion.motionScale`. That property exists at runtime, but
    // motion-lint's `load_qml_defs()` (hypr/.config/hypr/scripts/motion-lint)
    // only admits `<pairKey>Duration`/`<pairKey>Easing`/`motionEnabled` as
    // valid `Motion.*` references — `Motion.motionScale` is a CHECK A
    // dangling reference on this build even though it resolves at runtime.
    // `Probe.qml` already documents this exact finding beside its own raw
    // read of the same state file; this is the same precedent, not a new
    // one. Bare `FileView`, change-watching on, same shape as the chips'
    // own readers above.
    FileView {
        id: motionScaleFile
        path: root.homeDir + "/.local/state/theme/motion-scale"
        watchChanges: true
        onFileChanged: reload()
    }
    readonly property string motionScaleRaw: (motionScaleFile.text() || "").trim()
    // The closed four-value set `motion-switch.sh`'s own reader uses,
    // falling through to its "normal" default on an absent/unrecognised
    // value — asserted (not merely assumed) to equal
    // `theme-engine/.config/theme-engine/motion.json`'s `.scales` object
    // keys, read directly this plan: {"off","reduced","normal","lively"}.
    readonly property var validMotionScales: ["off", "reduced", "normal", "lively"]
    readonly property string motionScaleState: validMotionScales.indexOf(motionScaleRaw) !== -1 ? motionScaleRaw : "normal"

    // Row-level pending model — the SAME truth-driven shape as the chips
    // (a press never assigns the committed selection; only a real file
    // change does), but its OWN separate, deliberately longer watchdog:
    // D-24's whole premise is that a preset change costs a full
    // multi-second `theme-apply` re-render, so the chips' ~3s would time
    // out mid-flight and look like a failure every single time. Both
    // constants are declared together (chipTimeoutMs above, this one
    // below) so the asymmetry reads as a decision. Like the chips'
    // watchdog, this is a backend timeout, NOT a motion token — riding the
    // motion-scale axis would collapse it to zero at the `off` preset,
    // which is precisely the preset most likely to be pressed.
    property bool presetPending: false
    readonly property int presetTimeoutMs: 8000

    Timer {
        id: presetWatchdogTimer
        interval: root.presetTimeoutMs
        repeat: false
        onTriggered: root.presetPending = false
    }
    onMotionScaleStateChanged: if (root.presetPending) { root.presetPending = false; presetWatchdogTimer.stop(); }

    // Fixed argv: the only computed element is the home-prefixed script
    // path; the preset value always comes from `presetModel` below — a
    // closed in-file list index-matched to the segments — never free text.
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
        presetProcess.command = [root.homeDir + "/.config/hypr/scripts/motion-switch.sh", value];
        presetProcess.running = true;
    }

    readonly property var presetModel: [
        // Round-2 fix — a one-sentence hover explanation of what this
        // segment's animation level actually means, additive to the
        // always-visible "Off"/"Reduced"/"Normal"/"Lively" label.
        { value: "off", label: "Off", tooltip: "No animations anywhere in the desktop" },
        { value: "reduced", label: "Reduced", tooltip: "Minimal, short animations" },
        { value: "normal", label: "Normal", tooltip: "The default animation speed" },
        { value: "lively", label: "Lively", tooltip: "Longer, more expressive animations" }
    ]

    // One inline component — an MD3 segmented-button segment. A leading
    // check glyph on the selected segment is the MD3 convention (discretion,
    // recorded here): shown only when selected, Material Symbols "check".
    component PresetSegment: Item {
        id: segItem

        property int segIndex: 0
        property int segCount: 4
        property string segValue: ""
        property string segLabel: ""
        // Round-2 fix — see presetModel's own comment above.
        property string segTooltip: ""
        readonly property bool selected: root.motionScaleState === segValue

        Rectangle {
            id: segFill
            anchors.fill: parent
            color: segItem.selected ? Colours.primary : "transparent"
            // Only the outer corners round — the segments share ONE
            // outline (presetOutline below) and read as one joined row,
            // not three separate pills.
            topLeftRadius: segItem.segIndex === 0 ? height / 2 : 0
            bottomLeftRadius: segItem.segIndex === 0 ? height / 2 : 0
            topRightRadius: segItem.segIndex === segItem.segCount - 1 ? height / 2 : 0
            bottomRightRadius: segItem.segIndex === segItem.segCount - 1 ? height / 2 : 0
            Behavior on color {
                enabled: Motion.motionEnabled
                ColorAnimation {
                    duration: Motion.standardDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.standardEasing
                }
            }

            Row {
                anchors.centerIn: parent
                spacing: root.spacingXs

                Text {
                    visible: segItem.selected
                    text: "check"
                    font.family: root.symbolFontFamily
                    font.pixelSize: root.fontLabel + 2
                    color: Colours.onPrimary
                }
                Text {
                    text: segItem.segLabel
                    font.pixelSize: root.fontLabel
                    color: segItem.selected ? Colours.onPrimary : Colours.onSurfaceVariant
                    Behavior on color {
                        enabled: Motion.motionEnabled
                        ColorAnimation {
                            duration: Motion.standardDuration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Motion.standardEasing
                        }
                    }
                }
            }

            MouseArea {
                id: presetMouseArea
                anchors.fill: parent
                // The whole row — not just this segment — goes
                // non-interactive while a preset press is pending
                // (distinct from the chips, which disable only the one
                // pending chip): a preset change is a single, deliberately
                // long-running operation with no meaningful "different
                // preset" click to allow mid-flight.
                enabled: !root.presetPending
                // Round-2 fix — hover-revealed tooltip, same mechanism as
                // the chips above.
                hoverEnabled: true
                ToolTip.visible: presetMouseArea.containsMouse && segItem.segTooltip !== ""
                ToolTip.text: segItem.segTooltip
                ToolTip.delay: 400
                onClicked: root.pressPreset(segItem.segValue)
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
