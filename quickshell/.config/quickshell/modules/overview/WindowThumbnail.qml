// WindowThumbnail.qml — the single general representation of "a window drawn
// small" (Phase 16 Plan 03, the assumption-delta promotion recorded in
// 16-03-PLAN.md's <assumption_delta_decision>).
//
// Extracted from WorkspaceTile.qml's tracer-inline delegate (16-02). This is
// now the ONLY place in modules/overview/ that instantiates a
// `ScreencopyView` — Task 1's acceptance criteria assert that count is
// exactly 1 across the whole directory, encoding the promotion as a
// contract check rather than a convention a later plan can silently break.
//
// `liveCapture` is the variant switch, deliberately named and defaulted
// rather than left implicit:
// - D-16-07's fallback ladder (snapshot/placeholder/etc. under load) is a
//   property change on THIS type, not a second renderer.
// - D-16-12's drag ghost reuses this exact type with `liveCapture: false`
//   (a still `captureFrame()` snapshot, per 16-UI-SPEC.md's Drag visuals
//   section) instead of building its own capture path.
// - D-16-11 bakes exactly ONE mode into the shipped build (`live: true`
//   everywhere, today) — `liveCapture` is not a user-facing runtime toggle
//   and no settings surface should ever expose it as one. Recorded here so
//   a future reader does not add that knob back in.
//
// Geometry (D-16-02): position/size are read from
// `toplevel.lastIpcObject.at`/`.size`, offset by the owning monitor's own
// origin (multi-monitor honesty, D-16-04) and scaled by `captureScale` —
// identical arithmetic to WorkspaceTile.qml's tracer delegate, just hoisted
// to its own type. Every read is null-guarded: `lastIpcObject` starts as an
// EMPTY object (not null) for a toplevel created after Quickshell's initial
// sync (16-02-SUMMARY.md's confirmed root cause) and never repopulates on
// its own — the caller (WorkspaceTile.qml, via Overview.qml's
// Component.onCompleted) is responsible for calling
// `Hyprland.refreshToplevels()`; this type only guards against the
// consequence, it does not itself trigger the refresh.
//
// ── Phase 16 Plan 05 (D-16-10): three honest capture states ──────────────
// 16-RESEARCH.md Q5 establishes `hasContent` as the ONLY signal
// `ScreencopyView` exposes — no separate error/denied/state property
// exists. A denied capture and a first frame that has not landed present
// IDENTICALLY as `hasContent === false`, so a single boolean transition can
// never distinguish momentary from permanent on its own. The settle timer
// below is the load-bearing piece that makes that distinction possible at
// all — not a defensive nicety layered on top of something that already
// worked.
import QtQuick
import Quickshell.Wayland
import "../"
import "../dashboard"

Item {
    id: root

    // The HyprlandToplevel this thumbnail draws, or null.
    property var toplevel: null
    property real captureScale: 1
    // The owning HyprlandMonitor — geometry is offset by its x/y before
    // scaling into tile-local space (D-16-04).
    property var monitor: null
    // The variant switch documented above. Defaults true: D-16-07 says live
    // on every window first.
    property bool liveCapture: true

    // Guard every lastIpcObject read — see the header note above for why
    // this guard exists and what it protects against (a toplevel whose IPC
    // object hasn't landed yet, or has landed but is missing at/size keys).
    readonly property var ipc: root.toplevel ? root.toplevel.lastIpcObject : null
    readonly property var at: (root.ipc && root.ipc.at) ? root.ipc.at : [0, 0]
    readonly property var size: (root.ipc && root.ipc.size) ? root.ipc.size : [0, 0]
    readonly property real monitorX: root.monitor ? root.monitor.x : 0
    readonly property real monitorY: root.monitor ? root.monitor.y : 0

    x: (root.at[0] - root.monitorX) * root.captureScale
    y: (root.at[1] - root.monitorY) * root.captureScale
    width: Math.max(0, root.size[0] * root.captureScale)
    height: Math.max(0, root.size[1] * root.captureScale)

    // The single home of ScreencopyView in modules/overview/ (Task 1's
    // acceptance criteria assert this count directory-wide).
    ScreencopyView {
        id: captureView
        anchors.fill: parent
        // constraintSize is MANDATORY (16-02-SUMMARY.md's confirmed
        // pattern) — without it, the view paints its captured buffer at
        // native/source resolution instead of scaling into this item's own
        // bounds, relying on an ancestor's clip:true to crop the overflow
        // rather than genuinely scaling down.
        constraintSize: Qt.size(root.width, root.height)
        captureSource: root.toplevel ? root.toplevel.wayland : null
        live: root.liveCapture
    }

    // Exposed so WorkspaceTile.qml's aggregate counts can read this
    // instance's live hasContent without a second lookup path — the same
    // shape the tracer's inline delegate exposed via `captureView` alias.
    readonly property bool hasContent: captureView.hasContent

    // ── D-16-10's three-state capture machine ────────────────────────────
    // `_everPopulated` is sticky in the direction that matters: once a real
    // frame has landed, captureState reads "populated" forever after, even
    // through a later hasContent flicker — "becomes populated and stays
    // there" per this plan's own action text. The settle timer below is
    // what turns a merely-not-arrived-yet frame into a genuine "failed"
    // verdict; it is cancelled the instant content lands (its `running`
    // binding goes false), so the failure itself is NOT sticky — content
    // arriving after the timer has already fired still flips captureState
    // straight to "populated" on the very next hasContent pulse, because
    // the state formula below always checks `_everPopulated` first.
    property bool _everPopulated: false
    property bool _timedOut: false

    onHasContentChanged: {
        if (root.hasContent)
            root._everPopulated = true;
    }

    // The settle window trades one risk against the other, named rather
    // than left implicit: too short and a slow-but-genuine first frame
    // gets libelled a denial; too long and a real denial sits silently as
    // a spinner with nothing telling the user anything is wrong. Sourced
    // from Motion.ambientDuration (the same continuous-loop token the
    // pending glyph below pulses on, never a bare literal) — a few pulse
    // cycles reads as "still loading" without leaving a genuine denial
    // unreported for many seconds.
    readonly property int settleTimeoutMs: Motion.ambientDuration * 3

    Timer {
        id: settleTimer
        interval: root.settleTimeoutMs
        running: !root._everPopulated
        repeat: false
        onTriggered: {
            if (!root._everPopulated)
                root._timedOut = true;
        }
    }

    // Only ever assigned one of these three literals — "populated" when a
    // frame has landed (sticky), "failed" once the settle timer has fired
    // with nothing having landed, "pending" otherwise. No fourth value is
    // possible from this formula.
    readonly property string captureState: root._everPopulated ? "populated"
        : (root._timedOut ? "failed" : "pending")

    // Settled once the state has reached a terminal non-pending value —
    // Task 2's whole-grid catch aggregates this across every tile in the
    // grid to know when it is safe to evaluate at all.
    readonly property bool settled: root.captureState !== "pending"

    // The same four-state name set and state-to-colour-role mapping
    // PanelDialog.qml's own stateColour() already ships
    // (dashboard/PanelDialog.qml, ~lines 99-107) — cited as the source of
    // truth, not re-derived, and deliberately NOT imported: PanelDialog is
    // a panel-family component and this surface does not use the panel
    // frame, so this is a second, independent function whose four case
    // labels and four returned colour roles are provably the same set
    // (this plan's own acceptance criteria compare the two switch bodies'
    // role sets for equality). Only "populated"/"pending"/"failed" are
    // ever assigned to captureState above; "empty" is declared here purely
    // to keep the mapping byte-identical to its source of truth, not
    // because this type's own state machine ever reaches it.
    function stateColour(state) {
        switch (state) {
        case "populated": return Colours.onSurface;
        case "pending": return Colours.primary;
        case "empty": return Colours.onSurfaceVariant;
        case "failed": return Colours.error;
        default: return Colours.onSurface;
        }
    }

    // ── pending: a centred, ambient-pulsing loading glyph ─────────────────
    // Self-resolving by construction — nothing here clears it explicitly,
    // it simply stops being drawn the instant captureState above leaves
    // "pending".
    Item {
        id: pendingState
        anchors.fill: parent
        visible: root.captureState === "pending"

        Text {
            id: pendingGlyph
            anchors.centerIn: parent
            font.family: Design.symbolFontFamily
            font.pixelSize: Design.iconSizeMd
            text: "progress_activity"
            color: root.stateColour("pending")

            // The same corrected ambient loop-period token the wifi scan
            // sweep and bluetooth pairing spinner already ride
            // (WifiPanel.qml/BluetoothPanel.qml), reused here rather than
            // reinvented — an opacity pulse rather than a rotation, since
            // this glyph has no directional motion to suggest.
            SequentialAnimation {
                running: pendingState.visible && Motion.motionEnabled
                loops: Animation.Infinite
                NumberAnimation {
                    target: pendingGlyph
                    property: "opacity"
                    from: 0.35
                    to: 1.0
                    duration: Motion.ambientDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.ambientEasing
                }
                NumberAnimation {
                    target: pendingGlyph
                    property: "opacity"
                    from: 1.0
                    to: 0.35
                    duration: Motion.ambientDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.ambientEasing
                }
                // At `off` motion scale this never runs — the glyph itself,
                // static, still says "pending" (QuickToggles.qml's own
                // recorded fallback voice for its pending-pulse layer).
            }
        }
    }

    // ── failed: icon + the window's real title + one honest, non-
    //    diagnostic line. Padded by Design.spacingMd, icon-to-label gap
    //    Design.spacingXs. Degrades bottom-up at small sizes — the parent
    //    tile clips regardless, but a stack that cannot fit its icon
    //    should drop the reason line before the title and the title
    //    before the icon, per this plan's own action text. ────────────────
    Item {
        id: failedState
        anchors.fill: parent
        visible: root.captureState === "failed"

        readonly property real innerWidth: Math.max(0, failedState.width - Design.spacingMd * 2)
        readonly property real innerHeight: Math.max(0, failedState.height - Design.spacingMd * 2)
        readonly property bool canShowIcon: failedState.innerHeight >= failedIcon.implicitHeight
        readonly property bool canShowTitle: failedState.canShowIcon
            && failedState.innerHeight >= (failedIcon.implicitHeight + Design.spacingXs + failedTitle.implicitHeight)
        readonly property bool canShowReason: failedState.canShowTitle
            && failedState.innerHeight >= (failedIcon.implicitHeight + Design.spacingXs + failedTitle.implicitHeight + Design.spacingXs + failedReason.implicitHeight)

        Column {
            anchors.centerIn: parent
            width: failedState.innerWidth
            spacing: Design.spacingXs

            Text {
                id: failedIcon
                visible: failedState.canShowIcon
                anchors.horizontalCenter: parent.horizontalCenter
                font.family: Design.symbolFontFamily
                font.pixelSize: Design.iconSizeMd
                text: "visibility_off"
                color: root.stateColour("failed")
            }
            Text {
                id: failedTitle
                visible: failedState.canShowTitle
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                // Always known from Hyprland IPC regardless of whether
                // capture succeeded — exactly why it is the identifier
                // used here, per this plan's own action text.
                text: root.toplevel ? root.toplevel.title : ""
                font.pixelSize: Design.fontBody
                color: Colours.onSurface
            }
            Text {
                id: failedReason
                visible: failedState.canShowReason
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                // Deliberately non-diagnostic (16-RESEARCH.md Q5): a
                // genuinely blank window and a denied capture present
                // identically from this view alone, so the copy claims no
                // cause it cannot verify.
                text: "Live preview unavailable"
                font.pixelSize: Design.fontLabel
                color: root.stateColour("failed")
            }
        }
    }
}
