// BarCapsule.qml — the one shared chrome every capsule slot is built from
// (Phase 18 Plan 05, D-18-09). No capsule component may declare its own
// background Rectangle; this file is the bar's counterpart to
// PanelDialog.qml's role for the panel family.
import QtQuick
import "../"
import "../dashboard"

Rectangle {
    id: capsuleRoot

    // The single value every chrome geometry binding reads — inherited
    // from the one entry list rather than re-read by each capsule.
    readonly property bool vertical: BarEntryModel.isVertical
    // Set by the owning slot component, used to fetch its own entries.
    property string capsuleId: ""
    // The pinned/focused state 18-13 will drive.
    property bool active: false

    // No dwell timer and no popout summon here: popoutDwellMs, the
    // reveal/preview suppression latch and the one-open-at-a-time summon
    // path all belong to 18-13 — a stub of any of them here would give two
    // plans partial ownership of the hover contract.
    readonly property bool hovered: capsuleHover.hovered
    HoverHandler {
        id: capsuleHover
    }

    // Overview.qml's / QuickToggles.qml's full-pill idiom generalised to the
    // second axis. Derived, never a literal, which is why it tracked the
    // 18.1 height corrections on its own: at the horizontal barCapsuleHeight
    // of 34 this is 17, and at the vertical barColumnWidth of 44 it is 22.
    // Generalising the expression rather than minting a second radius token is
    // what keeps one shape idiom across both orientations.
    radius: vertical ? width / 2 : height / 2

    // The quickshell-bar namespace inherits the ^quickshell-.* family blur
    // rule's ignore_alpha floor, so no fill on this surface may sit below
    // that floor without silently killing the blur — every colour here
    // resolves through BarRoles (Phase 18.1 Plan 01), with the repo's
    // motion-gated crossfade. BarRoles.capsule/capsuleHover are themselves
    // translucent (0.85/0.95 over Colours.surfaceVariant), which is now
    // MORE load-bearing than when this fill was opaque: if the blur behind
    // the bar goes missing after this change, capture a screenshot BEFORE
    // touching any alpha value and re-apply layer rules via `hyprctl eval`
    // or a compositor restart — `hyprctl reload` silently drops layer-rule
    // edits and the resulting symptom is indistinguishable from a QML
    // alpha sitting under the ignore_alpha floor.
    // ── `surfaced` — opt IN to carrying a capsule surface ────────────────
    // Operator decision (2026-08-11, GATE-02 rounds 2-3): the surfaced set is
    // the CENTRE WORKSPACE capsule and the CENTRE IDLE-INHIBITOR bulb, and
    // nothing else — every other capsule is bare glyphs directly on the
    // wallpaper. Both surfaced capsules happen to be the two centre-zone ones;
    // that is a consequence of the operator's two choices, not a rule about the
    // centre zone, so a future centre capsule does not inherit a surface.
    //
    // This is a deliberate, recorded DIVERGENCE from upstream Athena, which
    // puts `background-color: @surface_container` on every module group
    // including `#workspaces` (ATHENA-UPSTREAM-SPEC.md). Upstream gets away
    // with it because @surface_container (#1b2023) is an opaque near-black
    // barely above its own #0f1416 background, so it recedes; our
    // BarRoles.capsule is translucent over the live wallpaper and reads far
    // more strongly. The operator was shown both options and chose this one.
    //
    // Default FALSE so the surface cannot spread back by accident: a new
    // capsule is bare unless it explicitly asks to be surfaced, rather than
    // surfaced unless it remembers to opt out. Grep `surfaced: true` for the
    // full set — currently WorkspaceCapsule and IdleInhibitorCapsule.
    property bool surfaced: false

    // Gap between this capsule's own content cells. Defaults to Athena's
    // intra-group pitch (barCellGap, 18) — which is deliberately WIDER than
    // the gap BETWEEN capsules (barCapsuleGap, 16); see Design.qml for why.
    // Capsules whose upstream counterpart is tighter override this:
    // workspace buttons and the right-hand action glyphs both carry only a
    // 2px margin upstream, i.e. a 4px gap.
    property int contentGap: Design.barCellGap

    color: !surfaced ? Qt.alpha(BarRoles.capsule, 0) : (hovered ? BarRoles.capsuleHover : BarRoles.capsule)
    Behavior on color {
        enabled: Motion.motionEnabled
        ColorAnimation {
            duration: Motion.colourDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Motion.colourEasing
        }
    }

    // Exposed for slot content to bind to. There is deliberately no
    // pressed-state visual: this repo keys visual state off the resulting state
    // change, never off pointer-down.
    //
    // capsuleFg unconditionally. The `active ? BarRoles.onAccent` branch this
    // replaces was a latent bug: on-accent is only legible ON an accent
    // fill, and NO BarCapsule background is ever accent-filled — the fill
    // expression below is `hovered ? capsuleHover : capsule`, both neutral.
    // So an active capsule rendered its content at onAccent (#1e1e2e on
    // catppuccin) over a #313244 surface: near-black on near-black.
    //
    // It stayed invisible-but-harmless while the only consumers were raster
    // IconImages and an unreachable placeholder branch. The 18.1 gap closure
    // gave the app drawer real glyphs, which made every cell in an open
    // drawer vanish. Athena has no equivalent state either: its drawer
    // members are @capsule-fg at rest and hover to @accent
    // (style-athena.scss:93/106), never to @on-accent.
    readonly property color contentColour: BarRoles.capsuleFg
    readonly property int iconFill: active ? 1 : 0

    // One axis-bound content positioner — the same single-positioner
    // binding the root (Bar.qml) uses for its three zone containers. A
    // positioner pair would be the forbidden fork in miniature.
    Grid {
        id: contentGrid
        anchors.centerIn: parent
        // Centre every item on the CROSS axis, in both orientations. Grid
        // defaults to AlignLeft/AlignTop, and with one row (horizontal) or one
        // column (vertical) the cross-axis default is what decides whether
        // narrow items line up with wide ones.
        //
        // MEASURED 2026-08-12 in vertical, 44px column: the clock cell (39.1
        // wide, the widest child) set the grid's width, and every narrower cell
        // hugged its leading edge — gaming/bell/settings/power all sat at x=2.0
        // w=24.0, centre 14 against a column centre of 22. The operator reported
        // exactly that split: "clock pill positioned too far to the right" and
        // "power, settings, gaming mode, ethernet, wifi, volume, now playing all
        // positioned to the left too much". Neither was actually mispositioned —
        // the clock was centred and the rest were not.
        //
        // This is the same defect GATE-02's F1 recorded on the OTHER axis ("the
        // time pill looks like it is positioned higher up than the rest"), whose
        // root cause was noted then as "Grid defaults to AlignTop for its items
        // and no verticalItemAlignment is set anywhere in the file". Both axes
        // are set here now, so neither can recur.
        horizontalItemAlignment: Grid.AlignHCenter
        verticalItemAlignment: Grid.AlignVCenter
        // KNOWN RESIDUAL, measured and left open deliberately (2026-08-12):
        // this Grid reports w=16 in mediaConnectivity while holding 33-wide
        // percent readouts (brightness, battery), because those Readouts' value
        // Text carries a reserve for "100%" that its own 16px-wide box never
        // accounts for. Centring them therefore lands at x=14 -> right=47, 3px
        // past the 44px column; before item alignment was set they sat at x=0
        // -> right=33 and fitted only by being left-aligned. Pinning this width
        // to `capsuleRoot.width` was tried and DID NOT take (the binding
        // self-references contentGrid.implicitWidth in its other branch and Qt
        // drops it) — measured no change, so it is not left here as dead code.
        // The real fix belongs in MediaConnectivityCapsule's Readout, whose box
        // must reserve its stacked value's width in vertical.
        spacing: capsuleRoot.contentGap
        rows: capsuleRoot.vertical ? -1 : 1
        columns: capsuleRoot.vertical ? 1 : -1
    }
    // A capsule component's children land inside the grid with no
    // plumbing.
    default property alias content: contentGrid.data

    // barCapsuleHeight tall horizontally (34 — Athena's `margin: 4px 5px` means
    // a capsule floats inside the 42px bar rather than filling it edge to edge;
    // Bar.qml's zone Grids already anchor to parent.verticalCenter, so the freed
    // 8px becomes symmetric breathing room with no extra positioning),
    // barColumnWidth wide vertically, shrinking to fit on the free axis.
    //
    // Padding applies ONLY when this capsule actually draws a surface. Upstream
    // Athena's groups carry `padding: 6px 6px` because they have a background
    // to inset their content from; an UNSURFACED capsule has no edge to inset
    // from, so the same 6px becomes invisible dead space on both sides — which
    // inflated the gap between two adjacent bare capsules to 16 + 6 + 6 = 28px
    // against the intended 16. That is what made the operator report the system
    // readouts as "too far apart from the drawer glyph": the readouts' own
    // pitch was correct, the air between the capsules was not.
    readonly property int contentInset: surfaced ? Design.barCapsulePadding : 0

    implicitWidth: vertical ? Design.barColumnWidth : contentGrid.implicitWidth + contentInset * 2
    implicitHeight: vertical ? contentGrid.implicitHeight + contentInset * 2 : Design.barCapsuleHeight

    // QtQuick positioners exclude non-visible children AND their spacing —
    // this is what delivers UI-SPEC's E7-partial "the remainder re-flow
    // without leaving a gap" with no extra code, and it is also why five
    // of the six slots correctly render nothing until their owning
    // wave-3 plan fills them.
    visible: vertical ? contentGrid.implicitHeight > 0 : contentGrid.implicitWidth > 0

    // ── Backend handles — the seam that keeps wave 3 conflict-free ───────
    // These live on the shared chrome rather than on each capsule so that
    // Bar.qml can bind all five uniformly, once, and freeze; a capsule
    // that later discovers it needs a backend inherits the handle instead
    // of forcing an edit to Bar.qml and serialising wave 3. Binding all
    // five to all six is deliberate redundancy bought for exactly that
    // reason. The handles' lifetimes stay explicit because shell.qml owns
    // the instances and passes them down by property, exactly as
    // AudioPanel's own backend property already does.
    property var audioBackend
    property var mediaBackend
    property var systemResources
    property var wifiBackend
    property var bluetoothBackend
}
