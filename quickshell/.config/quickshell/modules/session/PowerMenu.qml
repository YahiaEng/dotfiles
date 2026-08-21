// PowerMenu.qml — the session/power menu (Phase 20 Plan 06 Task 1,
// QPOWER-01/02/04, D-20-21..26). REWRITTEN 2026-08-15 from a 3x2 grid
// dialog to a radial ring, after the grid was built and shown live and
// the user rejected it verbatim: "It overtakes the entire screen and
// does not behave like a popup that slightly dims the screen. I want a
// floating cards design, circular pills arranged in a circular motion
// each one is colored according to the theme with a frosted look."
// Presented with three sketched radial options, the user locked this
// ring-with-centre-label shape — see 20-CONTEXT.md's D-20-21 revision
// note and 20-UI-SPEC.md's "Power Menu — Frame" (revised) for the full
// contract this file renders. Do not reinterpret the shape.
//
// Still ONE PanelWindow spanning the full output, per the original
// resolution — only the CHILD CONTENT changed from a card+grid to a
// scrim + six-pill ring + centre label. No card, no header, no rim.
//
// Scope note: the QPOWER-03 warning banner/detectors and the Cascade.qml
// staggered entrance are plan 20-07's job, not this file's — unaffected
// by this rewrite.
//
// ── SECOND revision (2026-08-15, same day) — colour/motion polish pass ──
// Live re-verification of the ring found: no entrance animation visible,
// pills reading as flat saturated discs rather than frosted, and a
// poor-reading accent-hued focus ring now that pills carry three
// different severity hues. Asked to choose dimming vs. frost, the user
// said "both". This pass, recorded in full in 20-CONTEXT.md's D-20-21
// second-revision note and 20-UI-SPEC.md's revised tables:
//   - moves each pill's severity colour OFF the fill and onto the icon
//     glyph (full opacity) + a hairline rim (WorkspaceTile.qml's own
//     "hairline, not the structural borderWidth" precedent, 16-07 render
//     gate round 11);
//   - re-fills every pill with same-hue Colours.surface (via the existing
//     surfaceColour property-colour intermediate below — never a direct
//     severity hue on the fill any more), at the lighter
//     Design.sessionPillFillOpacity (0.50, down from 0.72) —
//     WorkspaceTile.qml's own 12-round gate already found a saturated
//     tint over frost "mostly reads as tint" and resolved it exactly this
//     way (modules/overview/WorkspaceTile.qml:140-190);
//   - replaces the focused pill's BarRoles.accent ring with a NEUTRAL
//     Colours.onSurface ring plus a slight Design.sessionFocusScale
//     scale-up, since a chromatic ring can no longer read consistently
//     against three different pill hues;
//   - drops Design.sessionScrimOpacity to 0.15 (still below the
//     quickshell-session namespace's own ignore_alpha 0.2 cutoff, so the
//     scrim keeps dimming without asking the compositor to blur the whole
//     screen behind it — root cause 3 below);
//   - extends Cascade.qml (not a competing animation) with an opt-in
//     circularMotion sweep so the six pills visibly rotate into their
//     ring positions on entrance, rather than the near-invisible
//     straight-line rise the shared component's existing path produced
//     at this shape's own scale.
//
// ── Exclusive focus + HyprlandFocusGrab coexistence (D-20-24) ────────────
// WlrKeyboardFocus.Exclusive is a deliberate divergence from D-19-18's
// no-exclusive-focus rule, written for the non-modal notification centre.
// This surface's actions end the session, so it earns exclusive focus —
// every keypress must land here while it is open.
//
// ── Bug fix (live verification, 2026-08-15) — click-outside dismissal ──
// The grid build paired WlrKeyboardFocus.Exclusive with HyprlandFocusGrab
// and the user found clicking outside the dialog did not dismiss it.
// Root cause: a click on the SCRIM never changes which window holds
// keyboard focus (the scrim is part of THIS same window), so
// HyprlandFocusGrab's onCleared — which fires on a FOCUS change to
// another window — never sees it; Exclusive focus makes this worse by
// guaranteeing no other window can ever take focus while this one is
// open. The fix below is an explicit full-surface MouseArea behind the
// ring (on the scrim itself) whose onClicked deterministically closes
// the menu, independent of compositor focus-grab semantics.
// HyprlandFocusGrab is kept for the (different) case of focus genuinely
// moving to another surface; both routes call the same requestDismiss(),
// which is idempotent (a second call while the loader is already
// inactive is a no-op), so there is no double-fire hazard.
//
// ── Bug fix (live verification, 2026-08-15) — post-unlock flash ────────
// Reproduced on Lock: hyprlock starts correctly, but after unlocking the
// power menu flashes on screen before disappearing — the surface was not
// torn down before its action fired, so it survived (unmapped only via
// the LazyLoader's async destruction) behind the lock screen and
// repainted for a frame on unlock. Lock is merely the case where the
// user survives long enough to see it: Suspend and Hibernate have the
// identical defect on resume. Fix: `closeAndRun()` sets `visible: false`
// — which unmaps the wlr layer-shell surface synchronously, not merely
// opacity 0 — BEFORE the action Process starts, for all six actions.
// `requestDismiss()` (which tears down the LazyLoader item, including
// this window) is called LAST, after the process has already launched,
// so the object this function belongs to is never deleted out from under
// the `actionProcess.startDetached()` call above it.
//
// ── THIRD revision (2026-08-15, live user feedback on the second
//    revision) — reverse dismiss animation, animated focus ring, hover
//    parity, stronger/gradual dimming ─────────────────────────────────
// Four independent asks, none reopening the ring SHAPE (still locked):
//   1. **Reverse cascade on dismiss.** `Cascade.qml` gains an opt-in
//      `runExit()` (see its own header for the full design) — pills sweep
//      back OUT, un-staggered, on `Motion.emphasizedOutDuration`/Easing.
//      Both `closeAndRun()` and `requestDismiss()` now route through one
//      funnel, `_beginDismiss(actionIndex)`, so the Bug-2 ordering
//      guarantee above (unmap BEFORE the action process starts) is
//      enforced in exactly one place: `visible = false` and
//      `actionProcess.startDetached()` now happen in the exit cascade's
//      OWN completion callback, never before it, on BOTH the
//      action-dismiss and no-action-dismiss routes. This adds up to
//      `Motion.emphasizedOutDuration` (150ms fallback) of latency before
//      a session-ending action's process starts — judged acceptable: it
//      is a single un-staggered duration, not stacked per-pill, and the
//      surface is already invisible the instant that duration elapses.
//   2. **Focus ring becomes the animated Hyprland-style gradient rim**
//      (`GradientBorder.qml`, this shell's existing shared rim) — see the
//      pill delegate below. Deliberately its OWN, easily-revertible
//      change: nothing else in this pass touches the focus-ring block.
//      [FOURTH revision, 2026-08-16: REVERTED — see the pill delegate's
//      own comment below for the full story. The ring is back to a
//      static `Colours.onSurface` stroke; this item is kept here as the
//      trial record, not the current state.]
//   3. **Hover now moves `focusedIndex`** — `pillMouseArea.onEntered`
//      writes it directly (see the pill delegate's own comment for the
//      hover/keyboard precedence this establishes). The existing 0.65
//      hover-fill lift is KEPT, not retired — see that same comment for
//      why it is not redundant with the ring/scale now also following
//      hover.
//   4. **Scrim stronger AND gradual.** `Design.sessionScrimOpacity`
//      raised 0.15 -> 0.35 (Design.qml carries the full derivation and
//      the `ignore_alpha` 0.2-cutoff consequence: 0.35 sits ABOVE the
//      `quickshell-session` namespace's own 0.2 override, so this
//      surface's backdrop blur returns — previously split, with the
//      pill fill blurred and the scrim not; now both sit on the SAME
//      side, so the split itself is what this change also resolves, not
//      merely raises a number). "Gradual" is the scrim's own `opacity`
//      (not its baked-in alpha) ramped 0->1 on open and 1->0 on dismiss,
//      via a `Behavior on opacity` whose duration/easing binding reads
//      `_dismissing` to pick `emphasizedIn`/`emphasizedOut` — entrance
//      and exit each borrow the SAME token pair the pill cascade itself
//      uses for its own direction, not a fifth motion value.
//      [FOURTH revision, 2026-08-16: this `Behavior on opacity` mechanism
//      is REMOVED — see the scrim Rectangle's own comment below for why
//      (animating this surface's buffer alpha across the `ignore_alpha`
//      step function snapped the backdrop into blur mid-ramp). The
//      "gradual" dim is now the compositor's own layer fade, and
//      `sessionScrimOpacity` itself moved again, 0.35 -> 0.25.]
// See 20-CONTEXT.md's D-20-21 (fourth revision note) and 20-UI-SPEC.md's
// revised Focus Treatment / Entrance Motion / New Tokens sections for the
// design-contract side of this pass.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland
import "../"
import "../dashboard"
import "../bar"

PanelWindow {
    id: powerWindow

    signal dismissRequested()

    // Third-revision addition — guards every dismissal route
    // (Escape/click-outside/focus-grab-clear/action-selection) so a
    // second dismissal trigger arriving while the exit cascade is already
    // playing is a no-op rather than a second, competing teardown. Set
    // once, in `_beginDismiss()`, never reset — this window is destroyed
    // by the LazyLoader at the end of every dismissal path, so a fresh
    // menu open always gets a fresh instance with this back at `false`.
    property bool _dismissing: false

    function requestDismiss() {
        powerWindow._beginDismiss(-1);
    }

    // Esc routes through this rather than straight to requestDismiss(),
    // matching PanelDialog.qml's own handleEscape() idiom — no action is
    // taken, the menu just closes.
    function handleEscape() {
        powerWindow.requestDismiss();
    }

    // ── Layer posture — full-output span so the scrim gives the click-
    //    outside MouseArea (and HyprlandFocusGrab, for the other case) a
    //    screen-wide catch area with no second window to coordinate
    //    (Overview.qml's own full-screen-catch-region precedent).
    //    exclusiveZone 0 — an overlay, reserves nothing. Namespace
    //    declared in 20-03, first rendered here. ─────────────────────────
    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    exclusiveZone: 0
    // Ignore, NOT Normal (user-reported: "Dimming does not affect the
    // quickshell bar"). Under Normal the compositor shrinks this surface
    // out of the bar's own exclusive zone, so the scrim stopped at the
    // bar's edge and the bar sat undimmed above a dimmed desktop — the
    // modal read as partial. Layer order was never the problem: this
    // surface is already WlrLayer.Overlay (level 3) against the bar's
    // WlrLayer.Top (level 2), so it was always ABOVE the bar, just not
    // BEHIND it in extent.
    //
    // Deliberately diverges from Toast.qml:183, which documents choosing
    // Normal on purpose so transient notices do not cover the bar. The
    // opposite is correct here: a session modal that leaves a live,
    // clickable bar undimmed is not modal.
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-session"
    // D-20-24 — see file header for the full coexistence reasoning.
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive
    color: "transparent"

    // ── Local Design-derived constant — PanelDialog.qml's own idiom ──────
    // lineHeightTight has no consumer on this surface any more — the
    // Heading role (the only thing that used it) is retired: no header,
    // no card, no "Session" title left to carry it (20-UI-SPEC.md
    // Typography table). Only lineHeightNormal (the centre label, Body
    // weight) survives. 20-UI-SPEC.md's Step-9.5 correction confirmed
    // neither is a Design.qml token; declared locally per PanelDialog.qml's
    // own precedent, not a third declaration site.
    readonly property real lineHeightNormal: 1.5

    // ── panelSurfaceOpacity (Phase 20 Plan 07, QPOWER-03) — the warning
    //    chip's own surface opacity. NOT a Design.qml token, despite
    //    20-UI-SPEC.md's own "reuse" framing citing one: verified live
    //    that `panelSurfaceOpacity` is declared LOCALLY in
    //    `PanelDialog.qml:154` and separately in `SectionPopout.qml:256`
    //    — the exact same "not actually on Design.qml" trap this file's
    //    own `lineHeightNormal` above already hit. Declared locally here,
    //    mirroring `PanelDialog.qml`'s own declaration, rather than
    //    written as `Design.panelSurfaceOpacity` — which does not exist
    //    and would silently resolve to `undefined`/`NaN` opacity with no
    //    load error. 0.78 — opaque enough that the chip needs no frost of
    //    its own, since it is transient safety copy, not a themed action
    //    (20-UI-SPEC.md § "Power Menu — Safety Warning").
    readonly property real panelSurfaceOpacity: 0.78

    // ── Colour-typed indirection (Rule 1 bug fix, Phase 20 Plan 07) ──────
    // BarRoles.qml's own header names this exact failure mode: `Colours.*`
    // roles are declared `property string` (Colours.qml's JsonAdapter
    // loads them from palette.json's hex strings), so reading `.r`/`.g`/
    // `.b` directly off `Colours.surface` yields `undefined` for all
    // three, and `Qt.rgba(undefined, undefined, undefined, a)` silently
    // returns OPAQUE BLACK at alpha `a` — no error, no warning. The scrim
    // below (built in plan 20-06) read `Colours.surface.r/g/b` directly,
    // exactly this trap — it would have rendered a solid black overlay
    // instead of a light themed dim, failing Gate B criterion 1 outright.
    // Fixed here by assigning through a `property color`-typed
    // intermediate first, the same indirection `PanelDialog.qml:153`
    // (`surfaceBase`) and `BarRoles.qml:51` (`surfaceColour`) already
    // establish — QML performs the string->colour conversion at THIS
    // assignment, which is what makes `.r`/`.g`/`.b` real numbers
    // afterward. Both the scrim and the warning chip below read through
    // this one property, never `Colours.surface` directly.
    readonly property color surfaceColour: Colours.surface

    // The SCRIM specifically dims through `surfaceVariant`, not `surface`
    // (third revision follow-up, user-reported). `surface` is the theme's
    // own background — on the current Dracula palette it is #282a36, a
    // very dark desaturated blue-grey — so raising the scrim to 0.35 made
    // a legitimately-rendered dim read as the opaque-black bug all over
    // again ("you messed up the dimming. It now looks like the
    // opaque-black bug"). It was NOT that bug: the value resolved
    // correctly through the intermediate above. It simply looked identical,
    // which for a user-facing surface is the same problem.
    // `surfaceVariant` (#44475a on this palette) is materially lighter and
    // more chromatic, so a strong dim still reads as a themed veil rather
    // than a black wash. Same `property color` indirection, same reason.
    readonly property color scrimColour: Colours.surfaceVariant

    // ── The six actions — D-20-26 migration source: 20-BEHAVIOUR-BASELINE.md's
    //    verbatim transcription of the retired power-menu surface's own
    //    layout.json, captured before that file's deletion (RETIRE-05,
    //    Phase 20 Plan 10 — the sole place these strings existed). Every
    //    `command` element below is an inline literal — never built by
    //    concatenation, template literal, or interpolation of a runtime
    //    value. A reader sees every byte that will reach a shell by
    //    reading this one table (mirrors PanelDialog.qml's own
    //    `advancedCommand` discipline: a Process.command bound to a
    //    declared property, never joined into a string).
    //
    //    Array order IS ring order (D-20-21 revised, 20-UI-SPEC.md's
    //    "Ring layout — clock-position assignment"): Lock at 12 o'clock
    //    (0°), then clockwise — Log Out (60°), Suspend (120°), Hibernate
    //    (180°), Reboot (240°), Shut Down (300°). This is also the
    //    rotation model's index order (see rotateFocus() below).
    // quick-260821-6z1 Task 12 (D-01 bundle 3): extracted to
    // PowerActions.qml, a sibling singleton, so SessionPage.qml's own
    // "default focused action" row can read the SAME six names without
    // a live PowerMenu instance to read them from (this window is NOT a
    // singleton — see qmldir's own header). Values, order and every
    // command are byte-identical to what this array held inline before
    // the extraction.
    readonly property var actions: PowerActions.actions

    // Lock (index 0, 12 o'clock) auto-focused on open by default — the
    // least destructive action, and the one action QPOWER-03 never warns
    // about (D-20-29). quick-260821-6z1 Task 12 (D-01 bundle 3): a
    // Prefs-backed default action seeds this instead, read from `actions`
    // itself (never a second hardcoded name list) so the two can never
    // drift apart on what the valid action set is.
    property int focusedIndex: 0

    function _defaultActionIndex() {
        var label = Prefs.getValue("session.defaultAction");
        for (var i = 0; i < powerWindow.actions.length; i++) {
            if (powerWindow.actions[i].label === label)
                return i;
        }
        return 0;
    }
    Component.onCompleted: powerWindow.focusedIndex = powerWindow._defaultActionIndex()

    // ── Severity colour mapping (D-20-21, revised twice — mapping itself
    //    UNCHANGED across both revisions; only WHERE it renders changed —
    //    action -> colour-role table in 20-UI-SPEC.md § "Color"). Kept as
    //    a function rather than baked into the `actions` array above so
    //    every pill's colour stays a LIVE binding on BarRoles' singleton
    //    colours — Gate B criterion 2 requires a live theme switch to
    //    re-colour every pill within one crossfade while the menu is
    //    open, which a one-time JS-array snapshot would not satisfy.
    //
    //    SECOND REVISION: this function's return value now colours the
    //    ICON GLYPH and the hairline RIM (see the pill delegate below),
    //    never the fill — the fill is same-hue Colours.surface at
    //    Design.sessionPillFillOpacity regardless of tier (see
    //    `pillFill` below). `fgRoleFor` (the old `on<Role>` contrast-pair
    //    function used for the icon when the fill itself was an opaque
    //    saturated colour) is retired along with that fill treatment —
    //    the icon now reads the tier's own hue directly, at full opacity,
    //    against the neutral frosted fill, so no separate "on-colour"
    //    pairing is needed any more.
    //
    //    `accent`/`fillNotification` (Colours.primary's hue) stay
    //    excluded from every tier: BarRoles.accent is reserved for the
    //    OSD slider fill/handle elsewhere in this shell, and keeping it
    //    off every pill's severity palette avoids a pill's icon/rim ever
    //    reading as "this is the accent colour" by coincidence — unrelated
    //    to the focus ring, which is neutral (Colours.onSurface) as of
    //    this revision and no longer needs hue-collision avoidance against
    //    any specific pill tier.
    function fillRoleFor(idx) {
        switch (idx) {
        case 0: case 2: return BarRoles.fillClock;     // Lock, Suspend — tier A
        case 1: case 4: return BarRoles.fillUpdates;   // Log Out, Reboot — tier B
        case 3: case 5: return BarRoles.danger;        // Hibernate, Shut Down — tier C
        default: return BarRoles.fillClock;
        }
    }

    // ── QPOWER-03 detectors (Phase 20 Plan 07, D-20-27..30) — a plain
    //    child object, same-directory implicit import (PowerMenuBackend
    //    lives beside this file, registered in this directory's own
    //    qmldir). `active` is bound to THIS window's own `visible` — not
    //    to Component.onCompleted, not to an unconditional `true` — so the
    //    detectors run only while this surface is actually on screen and
    //    stop the instant Bug 2's `closeAndRun()` unmaps it (D-20-30's
    //    zero-idle rule). ───────────────────────────────────────────────
    PowerMenuBackend {
        id: powerMenuBackend
        active: powerWindow.visible
    }

    // ── Warning-chip scope (D-20-29) — Shutdown, Reboot, Hibernate and
    //    Logout are warned; Lock and Suspend are not. Because the chip is
    //    one block below the ring rather than per-pill decoration, "scope"
    //    here is the chip's own presence gated on at least one detector
    //    firing — the copy speaks about the destructive actions in
    //    general, it never annotates, highlights or modifies a pill
    //    (D-20-28's warn-only rule, unaffected by any of this). Hibernate
    //    is included in the warned set because a suspended-to-disk pacman
    //    transaction resumes into an inconsistent package db just as badly
    //    as a hard poweroff (D-20-29's own stated reason) — recorded here
    //    so the inclusion does not read as an over-inclusion to a later
    //    reader.
    // quick-260821-6z1 Task 12 (D-01 bundle 3): Prefs-gated — the warning
    // COMPOSITION itself (which conditions count as "busy") is untouched;
    // only whether the whole thing is allowed to show at all is new.
    readonly property bool warningActive: Prefs.getValue("session.warnWhenBusy") && (powerMenuBackend.pkgManagerBusy || powerMenuBackend.downloadsActive || powerMenuBackend.denyListActive)

    // Copywriting Contract strings, verbatim (20-UI-SPEC.md). Hard bound
    // of three lines — one per detector, no detector can fire twice.
    // Singular/plural deliberately not distinguished on the deny-list
    // line ("1 app(s)") — accepted awkwardness over a second string
    // variant for a rarely-seen count of exactly one.
    readonly property var activeWarnings: {
        var list = [];
        if (powerMenuBackend.pkgManagerBusy)
            list.push("A package manager is currently running");
        if (powerMenuBackend.downloadsActive)
            list.push("A download may still be in progress");
        if (powerMenuBackend.denyListActive)
            list.push(powerMenuBackend.denyListCount + " app(s) may not close cleanly");
        return list;
    }

    // Bug 2 fix, THIRD-REVISION ordering (see file header item 1) — still
    // "unmap BEFORE the action Process starts," but "unmap" now waits on
    // the exit cascade actually finishing, never fires while the surface
    // could still be mid-animation on screen. `closeAndRun()` itself is
    // now just the actionIndex >= 0 entry into the shared funnel below.
    function closeAndRun(index) {
        if (index < 0 || index >= powerWindow.actions.length)
            return;
        powerWindow._beginDismiss(index);
    }

    // ── The single dismissal funnel (third revision) — every route in
    //    this file (Escape, scrim click-outside, HyprlandFocusGrab clear,
    //    action selection) now goes through this ONE function, so the
    //    Bug-2 ordering guarantee and the exit-cascade wait are enforced
    //    in exactly one place rather than duplicated per call site.
    //    `actionIndex >= 0` means "run that action's command after
    //    unmapping"; `-1` means "just close, no action."
    function _beginDismiss(actionIndex) {
        if (powerWindow._dismissing)
            return;
        powerWindow._dismissing = true;
        // No scrim ramp-down here — the compositor's own layersOut fade
        // takes the whole surface out as one image. Driving `scrim.opacity`
        // toward 0 would drag it back across the ignore_alpha threshold and
        // snap the background OUT of blur a frame before the surface goes,
        // the exit-side twin of the entrance pop. See the scrim block.

        function afterExit() {
            powerWindow.entranceCascade.exitFinished.disconnect(afterExit);
            if (actionIndex >= 0) {
                // Bug 2 ordering, preserved and now animation-aware: the
                // surface is only unmapped, and the action process only
                // started, once every pill has actually finished
                // sweeping out — never while a frame of the exit
                // animation could still be on screen.
                var cmd = powerWindow.actions[actionIndex].command;
                powerWindow.visible = false;
                actionProcess.command = cmd;
                actionProcess.startDetached();
            }
            powerWindow.dismissRequested();
        }
        powerWindow.entranceCascade.exitFinished.connect(afterExit);
        powerWindow.entranceCascade.runExit();
    }

    // startDetached() — NOT a lifetime-bound `running` assignment —
    // matching PanelDialog.qml's advancedProcess exactly: the LazyLoader
    // that mounts this surface destroys it on dismiss, and a
    // lifetime-bound child would be SIGTERM'd along with it.
    Process {
        id: actionProcess
        command: []
    }

    // Rotation around the ring (D-20-24, revised) — a ring has one
    // degree of freedom, so both arrow-key axes collapse to
    // "rotate forward/backward". Right and Down both rotate clockwise
    // one pill (60°); Left and Up both rotate counter-clockwise one
    // pill. WRAPS — the pill clockwise of the last one genuinely is the
    // first one, a deliberate reversal of the retired grid's no-wrap
    // rule (a ring has no edge case for a wrap to create).
    function rotateFocus(step) {
        var n = powerWindow.actions.length;
        powerWindow.focusedIndex = (powerWindow.focusedIndex + step + n) % n;
    }

    // Mnemonics fire their matching action directly from any focus state
    // — unchanged behaviour from the retired power-menu surface (RETIRE-05,
    // Phase 20 Plan 10). Still undisplayed under the ring
    // (D-20-24 revised): a pure circle containing only a centred icon has
    // no spare corner to print a letter on, unlike the retired
    // rectangular tile.
    function fireMnemonic(letter) {
        for (var i = 0; i < powerWindow.actions.length; i++) {
            if (powerWindow.actions[i].mnemonic === letter) {
                powerWindow.closeAndRun(i);
                return;
            }
        }
    }

    // ── Entrance cascade (Phase 20 Plan 07, D-20-35 revised for the ring;
    //    SECOND revision adds circularMotion) — reuses PanelDialog.qml's
    //    own `Cascade` component, still not a second hand-rolled stagger
    //    mechanism. Bands are the six ring pills in ring order (Lock, Log
    //    Out, Suspend, Hibernate, Reboot, Shut Down — the SAME order
    //    `actions`/`pillRepeater` already use), then the centre label,
    //    plus the warning chip as an eighth band when it is already
    //    present at open time. There is no header band left on this
    //    surface to seed the first band the way PanelDialog.qml's own
    //    `headerIdentity` does — the cascade starts directly on the first
    //    pill.
    //
    //    `circularMotion: true` (SECOND revision, D-20-21) — Cascade.qml
    //    gained this opt-in property so the six pill bands (which each
    //    declare their own `ringPivot`, see the pill delegate above) sweep
    //    into their resting ring position by ROTATING around the ring's
    //    own centre, rather than the shared component's existing
    //    straight-line rise. This is an EXTENSION of the existing
    //    mechanism, not a competing one — the centre label and warning
    //    chip bands below have no `ringPivot` of their own, so Cascade
    //    still falls back to its pre-existing translate-rise path for
    //    those two, exactly as before this revision. ─────────────────────
    readonly property Cascade entranceCascade: Cascade { circularMotion: true }

    function _buildCascadeBands() {
        var bands = [];
        for (var i = 0; i < pillRepeater.count; i++) {
            var item = pillRepeater.itemAt(i);
            if (item)
                bands.push(item);
        }
        bands.push(centreLabel);
        if (powerWindow.warningActive)
            bands.push(warningChip);
        return bands;
    }

    // ── Full-bleed scrim (D-20-21, revised FOUR times) — a dim
    //    (Design.sessionScrimOpacity, 0.25 as of the FOURTH revision — was
    //    0.35 (third), was 0.15, was 0.32, was 0.55 originally), not a
    //    screen-take-over. 0.25 sits ABOVE the quickshell-session
    //    namespace's own ignore_alpha 0.2 cutoff (windowrules.lua), the
    //    same side the third revision's 0.35 already sat on — see
    //    Design.qml's own sessionScrimOpacity comment for the full
    //    consequence (backdrop blur applies, matching the pill fill's own
    //    side of the same cutoff). "Gradual" is now the COMPOSITOR's own
    //    layer fade (windowrules.lua's `animation = "fade"` for this
    //    namespace, timed by animations.lua's layersIn/layersOut) — NOT a
    //    `Behavior` on this Rectangle's own `opacity`. See the block
    //    immediately below for why the fourth revision removed that
    //    QML-side ramp. Carries the click-outside MouseArea (Bug 1 fix,
    //    see file header) so dismissal is deterministic and independent
    //    of HyprlandFocusGrab's focus-change semantics. ─────────────────
    Rectangle {
        id: scrim
        anchors.fill: parent
        // Third revision, item 4 — "gradual" WAS this Rectangle's own
        // `opacity` (0 at construction, driven to 1/0 by
        // Component.onCompleted / `_beginDismiss()`), animated by a
        // `Behavior on opacity`. Fourth revision: that `Behavior` is
        // REMOVED — see below for why — and `opacity` now holds at a
        // constant 1 for this Rectangle's entire lifetime; `color` alone
        // carries the fixed, fully-resolved RGBA value at the token's own
        // target alpha (`sessionScrimOpacity`). This paragraph is kept as
        // the historical record of the mechanism that used to live here,
        // not a description of what runs now.
        // ── No QML opacity ramp here. This is load-bearing. ─────────────
        // `ignore_alpha` is a STEP function evaluated against this
        // surface's own BUFFER alpha: Hyprland gives the blurred backdrop
        // only to pixels above the threshold (0.2 for quickshell-session).
        // Animating this Rectangle's `opacity` from 0 to its 0.25 target
        // therefore drags the scrim ACROSS that threshold mid-animation,
        // and the whole background snaps into blur in a single frame at
        // ~80% through the ramp — reported as "the dimming screen pops
        // into existence... very jarring".
        //
        // Every attempt to tune that away made it worse, and the step
        // explains why: a longer ramp (factor 3, then 5) pushed the snap
        // LATER; lowering the target 0.35 -> 0.25 moved the crossing from
        // 57% to 80% of the ramp; and switching the curve to linear could
        // not help, because a threshold crossing is not a curve.
        //
        // The compositor's own layer fade (windowrules.lua's
        // `animation = "fade"` for this namespace, driven by animations.lua's
        // layersIn/layersOut) multiplies the FINAL COMPOSITED OUTPUT
        // instead. Blur is computed once against a static buffer alpha and
        // then fades in as one uniform image, so there is no threshold to
        // cross and no step to see. That is why the fade belongs to the
        // compositor and not to this file.
        //
        // Keep `opacity` at 1 and carry the dim strength in `color`'s alpha
        // alone. Anything that re-introduces an opacity Behavior here
        // re-introduces the pop.
        opacity: 1
        color: Qt.rgba(powerWindow.scrimColour.r, powerWindow.scrimColour.g, powerWindow.scrimColour.b, Design.sessionScrimOpacity)

        // Bug 1 fix — declared on the scrim itself, BEHIND the ring
        // (the ring Item is a later sibling below, so its pills' own
        // MouseAreas take input priority over this one wherever they
        // overlap it; empty space inside the ring's bounding box that
        // is not covered by any pill has no MouseArea of its own and
        // passes the click straight through to this one, so clicking
        // "outside" a pill anywhere on screen dismisses the menu).
        MouseArea {
            id: scrimMouseArea
            anchors.fill: parent
            onClicked: powerWindow.requestDismiss()
        }
    }

    // ── HyprlandFocusGrab (D-20-24) — click-outside dismissal for the
    //    case of keyboard focus genuinely moving to ANOTHER surface,
    //    copied verbatim from PanelDialog.qml, coexisting with Exclusive
    //    focus above. Proven live at this plan's Task 1 human-check. The
    //    scrim's own MouseArea above is now the PRIMARY dismissal path
    //    for same-window outside clicks (see file header for why this
    //    grab alone could not see those) — both call the same idempotent
    //    requestDismiss(), so no double-fire hazard. ─────────────────────
    HyprlandFocusGrab {
        id: grab
        windows: [ powerWindow ]
        active: true
        onCleared: powerWindow.requestDismiss()
    }

    // ── The ring — six pure-circle pills plus a centre label, no card,
    //    no header, no rim (D-20-21 revised). Content-only Item, centred
    //    in the output, sized to Design.sessionSurfaceDiameter on both
    //    axes since the content is circular. ─────────────────────────────
    Item {
        id: ring
        anchors.centerIn: parent
        implicitWidth: Design.sessionSurfaceDiameter
        implicitHeight: Design.sessionSurfaceDiameter
        width: implicitWidth
        height: implicitHeight
        focus: true

        Keys.onEscapePressed: powerWindow.handleEscape()
        Keys.onReturnPressed: powerWindow.closeAndRun(powerWindow.focusedIndex)
        Keys.onEnterPressed: powerWindow.closeAndRun(powerWindow.focusedIndex)
        Keys.onLeftPressed: powerWindow.rotateFocus(-1)
        Keys.onUpPressed: powerWindow.rotateFocus(-1)
        Keys.onRightPressed: powerWindow.rotateFocus(1)
        Keys.onDownPressed: powerWindow.rotateFocus(1)
        Keys.onPressed: (event) => {
            var letter = event.text.toLowerCase();
            for (var i = 0; i < powerWindow.actions.length; i++) {
                if (powerWindow.actions[i].mnemonic === letter) {
                    powerWindow.closeAndRun(i);
                    event.accepted = true;
                    return;
                }
            }
        }
        // ── D-20-36 — ring entrance and input readiness are deliberately
        //    NOT serialised (the third option offered, and the one taken).
        //    `ring.forceActiveFocus()` below runs synchronously, in the
        //    SAME Component.onCompleted as arming the cascade — every Key
        //    handler above and every pill's own MouseArea are already live
        //    the instant this surface opens, before the cascade's own
        //    stagger animation has run a single frame. Nothing here gates
        //    `ring.enabled`/`focus` or any pill's MouseArea on
        //    `entranceCascade.runCount` or any animation's own
        //    `running`/`finished` state — that gating is the thing this
        //    comment records was deliberately NOT added. WINDOWS rows 3
        //    and 4 (the Phase 9 hover-during-entrance interaction, never
        //    exercised live) stay open and are triaged in plan 20-02; this
        //    choice does not silently resolve them, and a later reader
        //    finding this file interactive mid-animation should not treat
        //    that as a bug to fix.
        Component.onCompleted: {
            ring.forceActiveFocus();
            powerWindow.entranceCascade.bands = powerWindow._buildCascadeBands();
            powerWindow.entranceCascade.armed = true;
            powerWindow.entranceCascade.run();
            // No scrim ramp-in here — the compositor's layersIn fade brings
            // the whole surface up as one already-composited image, so the
            // dim arrives with it and never crosses the blur threshold
            // mid-animation. See the scrim block for the full reasoning.
            // Cascade.run() itself is what gates the whole stagger on
            // Motion.motionEnabled (the `off`-scale collapse branch) — not
            // re-checked a second time on this surface. Logged here
            // (mirroring Cascade.qml's own "cascade: run" fence trace) so
            // a reader can confirm, without instrumenting anything, that
            // this surface's stagger consumes the SAME shared
            // Motion.staggerOffsetDuration token PanelDialog.qml's own
            // cascade already uses, never a second hand-rolled value.
            console.log("power-menu: cascade armed bands=" + powerWindow.entranceCascade.bands.length + " staggerMs=" + Motion.staggerOffsetDuration + " motionEnabled=" + Motion.motionEnabled + " circularMotion=" + powerWindow.entranceCascade.circularMotion);
        }

        // ── Centre label (D-20-21 revised) — the ONLY place any action's
        //    name appears anywhere on this surface, replacing the retired
        //    design's six simultaneously-visible per-tile labels. Updates
        //    live as focus rotates. No background/chip of its own — sits
        //    directly on the scrim. ────────────────────────────────────
        Text {
            id: centreLabel
            anchors.centerIn: parent
            width: Design.sessionCentreLabelWidth
            horizontalAlignment: Text.AlignHCenter
            text: powerWindow.actions[powerWindow.focusedIndex].label
            font.pixelSize: Design.fontBody
            font.weight: Design.weightEmphasis
            lineHeight: powerWindow.lineHeightNormal
            color: Colours.onSurface
        }

        Repeater {
            id: pillRepeater
            model: powerWindow.actions

            delegate: Item {
                id: pill
                width: Design.sessionPillDiameter
                height: Design.sessionPillDiameter

                readonly property int pillIndex: index
                readonly property real angleRad: pillIndex * 60 * Math.PI / 180
                x: ring.width / 2 + Design.sessionRingRadius * Math.sin(angleRad) - width / 2
                y: ring.height / 2 - Design.sessionRingRadius * Math.cos(angleRad) - height / 2

                // ── ringPivot (SECOND revision) — the ring's own centre,
                //    expressed in THIS pill's local coordinate space (a
                //    Rotation transform's origin is relative to the item's
                //    own untransformed local box, not the parent's — so
                //    this is "ring centre in the ring's coordinate space"
                //    minus "this pill's own x/y offset within the ring",
                //    not simply ring.width/2). Read by Cascade.qml via
                //    duck-typing (`band.ringPivot`), never written by it —
                //    only the ring's own pill delegates define this
                //    property; the centre label and warning chip below do
                //    not, and fall back to Cascade's existing straight-line
                //    rise for those two bands (see Cascade.qml's run()).
                readonly property point ringPivot: Qt.point(ring.width / 2 - pill.x, ring.height / 2 - pill.y)

                readonly property bool isFocused: pillIndex === powerWindow.focusedIndex
                readonly property bool hovered: pillMouseArea.containsMouse
                readonly property color fillRole: powerWindow.fillRoleFor(pillIndex)

                // Focused-pill scale-up (SECOND revision, D-20-21) —
                // Design.sessionFocusScale (1.08), paired with the neutral
                // focus ring below since a single chromatic ring can no
                // longer read consistently against three different pill
                // hues. Scales about the pill's own centre (QML's default
                // transformOrigin: Item.Center), so this never shifts the
                // pill's own ring position.
                scale: pill.isFocused ? Design.sessionFocusScale : 1.0
                Behavior on scale {
                    enabled: Motion.motionEnabled
                    NumberAnimation {
                        duration: Motion.standardDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Motion.standardEasing
                    }
                }

                // Fill: same-hue frost, NOT the severity colour (SECOND
                // revision, D-20-21 — WorkspaceTile.qml's own 12-round
                // render gate already found a saturated tint over frost
                // "mostly reads as tint",
                // modules/overview/WorkspaceTile.qml:140-190). Reads
                // Colours.surface via powerWindow.surfaceColour — the SAME
                // property-colour intermediate the scrim above already
                // uses, never a second `Colours.surface` reference and
                // never `pill.fillRole` on the fill. Hover (pointer only)
                // lifts Design.sessionPillFillOpacity (0.50) toward 0.65,
                // the same +0.1-ish alpha-step idiom
                // BarRoles.capsule->capsuleHover already establishes.
                // No per-pill destructive styling tied to a live warning,
                // ever (D-20-28) — every pill's PERMANENT baseline fill is
                // static, unaffected by any live detector state.
                //
                // ── THIRD REVISION decision — this 0.65 lift is KEPT, not
                //    retired, now that hover also drives focusedIndex (see
                //    pillMouseArea below). It is not redundant: `hovered`
                //    and `isFocused` can DIVERGE — an arrow-key press can
                //    move `focusedIndex` to a different pill while the
                //    pointer sits motionless over this one (see
                //    pillMouseArea's own precedence comment) — so a
                //    hovered-but-not-currently-focused pill would carry
                //    ZERO visual feedback without this lift. It reinforces
                //    the ring+scale when the two coincide (the common
                //    mouse-driven case) and stands alone when they do not.
                Rectangle {
                    id: pillFill
                    anchors.fill: parent
                    radius: width / 2
                    color: Qt.rgba(powerWindow.surfaceColour.r, powerWindow.surfaceColour.g, powerWindow.surfaceColour.b,
                                   pill.hovered ? 0.65 : Design.sessionPillFillOpacity)
                }

                // Severity rim (NEW, SECOND revision) — the tier colour
                // that used to live on the fill now lives here instead, as
                // a hairline stroke ON the pill's own boundary (radius
                // width/2, no outward margin — unlike the focus ring below,
                // which is deliberately OUTSIDE the boundary). Hairline
                // (1px), not Design.borderWidth (3px): WorkspaceTile.qml's
                // own render gate already found the structural 3px width
                // draws "a hard card edge" on a region meant to read as a
                // marking rather than a frame (16-07 gate, round 11) — the
                // same reasoning applies here: the rim is a colour cue, not
                // the pill's own tap-target edge (the fill's circular
                // bound already reads as that).
                Rectangle {
                    id: pillRim
                    anchors.fill: parent
                    radius: width / 2
                    color: "transparent"
                    // Suppressed while focused (third revision follow-up,
                    // user-reported): the gradient focus ring below is
                    // meant to REPLACE this rim, not sit beside it. Left
                    // visible, the 1px severity hairline and the 3px
                    // rotating rim rendered as two concentric strokes —
                    // "the gradient ring overlaps with the outer ring of
                    // the circular pills. It should cover it." Width, not
                    // colour, so no literal is introduced for colour-lint
                    // to reject; the tier hue still reads from the icon
                    // glyph while focused, so no severity signal is lost.
                    border.width: pill.isFocused ? 0 : 1
                    border.color: pill.fillRole
                }

                // Visible focus is a RING, never a fill swap (QPOWER-02,
                // D-20-24) — THIRD REVISION, item 2: the user's own ask,
                // "change the hovered ring to the shifting colours we have
                // on Hyprland," resolved by instantiating the shell's
                // existing GradientBorder.qml here rather than hand-rolling
                // a second animated rotating-gradient implementation.
                // GradientBorder is the exact component Hyprland-border
                // parity already lives in (Toast.qml, NotifCard.qml,
                // Dashboard.qml, NotifCentre.qml, NotifPopupStack.qml,
                // SectionPopout.qml, DragGhost.qml, PanelDialog.qml — see
                // PanelDialog.qml:191-198 for a worked consumer) — its
                // infinite `NumberAnimation on angle` IS the "shifting
                // colours." All four corner radii are set to half of this
                // item's own (post-margin) width, so the rim traces a true
                // circle rather than GradientBorder's usual rounded-rect —
                // a self-referential `width / 2` binding, resolved after
                // `anchors.fill`/`anchors.margins` below have already fixed
                // this item's width.
                //
                // Still drawn OUTSIDE the pill's own `sessionPillDiameter`
                // boundary via the same `-Design.borderWidth` outward
                // margin the retired neutral ring used, and still gated
                // `visible: pill.isFocused` — only the RING TREATMENT
                // changed (a rotating multi-hue gradient in place of a
                // static `Colours.onSurface` stroke); the 1.08×
                // `sessionFocusScale` scale-up above is UNCHANGED and
                // independent of this swap, per the task's own explicit
                // instruction to keep it (it is the non-colour cue that
                // survives every pill hue, orthogonal to whatever colour
                // treatment the ring itself carries).
                //
                // Deliberately its own, easily revertible change — nothing
                // else in this pass touches this block, and reverting it
                // alone (back to the retired static `Colours.onSurface`
                // Rectangle above) needs no other file touched.
                // Focus ring — NEUTRAL, static. The animated
                // GradientBorder rim trialled in the third revision was
                // REVERTED on the user's own call after seeing it live
                // ("Revert the colorful shifting highlighter decision I
                // made earlier"); it was adopted as an explicit
                // try-and-decide, and this is the decide half.
                //
                // The second revision's reasoning stands and is why this
                // is neutral rather than any palette hue: pills carry
                // three different severity colours (fillClock /
                // fillUpdates / danger), so a chromatic ring cannot read
                // consistently against all of them — and the rotating rim
                // made that worse, cycling through the very hues it had to
                // stay distinguishable from.
                //
                // Geometry is deliberately NOT reverted with the colour.
                // The -borderWidth/2 straddle and the suppressed 1px
                // severity hairline (see pillRim above) fixed a separate
                // user-reported fault — the ring rendering as a second
                // concentric stroke beside the hairline instead of
                // covering it — which is independent of what colour the
                // ring is.
                Rectangle {
                    id: focusRing
                    anchors.fill: parent
                    anchors.margins: -Design.borderWidth / 2
                    radius: width / 2
                    color: "transparent"
                    border.width: Design.borderWidth
                    border.color: Colours.onSurface
                    visible: pill.isFocused
                }

                // Icon only — no label, no mnemonic letter on or under
                // the pill (both retired, locked per the user's own
                // "containing an ICON ONLY" ask). SECOND revision: the
                // icon now carries the tier's own severity hue directly
                // (pill.fillRole, e.g. BarRoles.fillClock) at full
                // opacity, rather than the retired on<Role> contrast pair
                // — since the fill beneath it is now a neutral frost, not
                // an opaque saturated colour, the icon (alongside the rim
                // above) is where the colour story now lives. Only the
                // pill's FILL is frosted; the icon glyph itself stays
                // crisp at full opacity, unaffected by this revision.
                Text {
                    anchors.centerIn: parent
                    text: modelData.glyph
                    font.family: Design.symbolFontFamily
                    font.pixelSize: Design.sessionTileIconSize
                    color: pill.fillRole
                }

                // THIRD REVISION, item 3 (bug fix) — hover now moves focus.
                // `pill.hovered` already existed above (this delegate's own
                // `readonly property bool hovered: pillMouseArea.containsMouse`)
                // as `pillMouseArea.containsMouse`, but nothing previously
                // WROTE `focusedIndex` on hover — only `onClicked` did — so
                // hovering lifted the fill's opacity (see the Fill comment
                // above) without moving the ring, the scale-up, or the
                // centre label. `onEntered` closes that gap directly.
                //
                // ── Hover/keyboard precedence (recorded here per the
                //    task's own instruction to decide deliberately, not
                //    leave implicit) — MOST-RECENT-INPUT-WINS, and neither
                //    input source fights the other because neither
                //    continuously re-asserts itself:
                //      - `onEntered` fires EXACTLY ONCE per pointer entry,
                //        not every frame the pointer rests inside the
                //        pill. A stationary pointer therefore never
                //        re-writes `focusedIndex` on its own, so a
                //        subsequent arrow-key press (which writes
                //        `focusedIndex` directly, via `rotateFocus()`)
                //        always wins and STAYS won until the pointer
                //        actually leaves and re-enters some pill.
                //      - Symmetrically, an arrow-key press never fights a
                //        SUBSEQUENT pointer entry into a different pill —
                //        that entry's own `onEntered` simply fires and
                //        wins, same as any other hover.
                //    The one residual case this does NOT resolve — the
                //    pointer already resting over pill A when keyboard
                //    focus moves to pill B — is not a "fight": the ring
                //    shows B (correct, keyboard was the last input), while
                //    pill A's own hover-fill lift (kept, see the Fill
                //    comment above) still shows the pointer's own
                //    location. Two independent, simultaneously-true cues,
                //    not a contradiction.
                MouseArea {
                    id: pillMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: powerWindow.focusedIndex = pill.pillIndex
                    onClicked: {
                        powerWindow.focusedIndex = pill.pillIndex;
                        powerWindow.closeAndRun(pill.pillIndex);
                    }
                }
            }
        }
    }

    // ── QPOWER-03 warning chip (Phase 20 Plan 07, D-20-27..30 revised for
    //    the ring) — a standalone frosted chip, NOT a fourth kind of pill
    //    and NOT on the ring itself, positioned Design.spacingLg (24px)
    //    below the ring's own outer edge — i.e. below the bottommost
    //    pill's lower boundary, which sits at
    //    Design.sessionRingRadius + Design.sessionPillDiameter / 2 from
    //    the ring's centre. `ring.bottom` already IS that outer edge
    //    (ring's own size is Design.sessionSurfaceDiameter, the ring
    //    cluster's own outer-to-outer extent, centred), so anchoring
    //    directly to it needs no re-derivation of that arithmetic here.
    //
    //    Absent-when-clear (S6/empty) — `visible` below is the ENTIRE
    //    reservation mechanism: this Rectangle is anchored, not laid out
    //    in a Column the ring's own position could be pushed by, so when
    //    no detector is active the surface's overall bounding box stays
    //    exactly Design.sessionSurfaceDiameter with no reserved gap for a
    //    chip that is not there — there is nothing to shrink back to
    //    because nothing here ever grew the ring's own layout in the
    //    first place.
    //
    //    Warn only (D-20-28) — this chip is the ONLY new consumer this
    //    task adds, and it reads exclusively BarRoles.warn/onWarn, never
    //    BarRoles.danger/onDanger. The six pills above already carry
    //    plan 20-06's static, PERMANENT severity tint via
    //    fillRoleFor/fgRoleFor — that existing, warning-INDEPENDENT use
    //    is unrelated to this chip's own live-detector-driven visibility
    //    and is not touched by this task. No pill's `enabled`/`opacity`
    //    is ever bound to `powerWindow.warningActive` anywhere in this
    //    file — deliberately: a live QPOWER-03 detector must never be
    //    able to recolour, greyer or gate any of the six actions. This is
    //    the bluetooth panel's own "disabled-with-reason on hover"
    //    convention being DELIBERATELY NOT applied here — the user has
    //    legitimate reason to press through a warning, and a stuck
    //    detector must never be able to lock them out of powering their
    //    own machine down. There is no "Are you sure?" confirmation
    //    anywhere on this surface, warned or not (D-20-28's own rule
    //    extends to copy).
    Rectangle {
        id: warningChip
        visible: powerWindow.warningActive
        anchors.top: ring.bottom
        anchors.topMargin: Design.spacingLg
        anchors.horizontalCenter: ring.horizontalCenter
        radius: Design.popoutCornerRadius
        width: Math.min(Design.sessionSurfaceDiameter, warningColumn.implicitWidth + Design.spacingMd * 2)
        height: warningColumn.implicitHeight + Design.spacingMd * 2
        color: Qt.rgba(powerWindow.surfaceColour.r, powerWindow.surfaceColour.g, powerWindow.surfaceColour.b, powerWindow.panelSurfaceOpacity)

        Column {
            id: warningColumn
            anchors.centerIn: parent
            spacing: Design.spacingSm

            // Multiple simultaneous warnings stack as separate lines
            // within this ONE chip — detectors are independent, so one
            // clearing does not affect another still active (S6/partial).
            // Hard bound of three lines, one per detector
            // (`powerWindow.activeWarnings` above never grows past 3).
            Repeater {
                model: powerWindow.activeWarnings

                delegate: Row {
                    spacing: Design.spacingSm

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: Design.symbolFontFamily
                        font.pixelSize: Design.iconSizeMd
                        text: "warning"
                        color: BarRoles.warn
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: Design.fontBody
                        font.weight: Design.weightBody
                        lineHeight: powerWindow.lineHeightNormal
                        color: BarRoles.onWarn
                        text: modelData
                    }
                }
            }
        }
    }
}
