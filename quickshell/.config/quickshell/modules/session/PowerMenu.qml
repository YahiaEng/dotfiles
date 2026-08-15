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

    function requestDismiss() {
        powerWindow.dismissRequested();
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
    exclusionMode: ExclusionMode.Normal
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

    // ── The six actions — D-20-26 migration source: 20-BEHAVIOUR-BASELINE.md's
    //    verbatim wleave layout.json transcription, captured before that
    //    file's deletion (the sole place these strings existed). Every
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
    readonly property var actions: [
        {
            glyph: "lock", label: "Lock", mnemonic: "l",
            // unchanged from the baseline
            command: ["sh", "-c", "uwsm app -- hyprlock"]
        },
        {
            glyph: "logout", label: "Log Out", mnemonic: "e",
            // D-20-37: a genuine ADDITION of the hyprshutdown wrap — the
            // baseline's bare `cliphist wipe; uwsm stop` never wrapped
            // through hyprshutdown. See 20-LEDGER-02-RECORD.md (Task 3).
            command: ["sh", "-c", "cliphist wipe; hyprshutdown --post-cmd 'uwsm stop'"]
        },
        {
            glyph: "bedtime", label: "Suspend", mnemonic: "u",
            command: ["sh", "-c", "systemctl suspend"]
        },
        {
            glyph: "ac_unit", label: "Hibernate", mnemonic: "h",
            command: ["sh", "-c", "systemctl hibernate"]
        },
        {
            glyph: "restart_alt", label: "Reboot", mnemonic: "r",
            // unchanged — QPOWER-04's graceful compositor exit, carried
            // over verbatim from the baseline, not re-derived.
            command: ["sh", "-c", "cliphist wipe; hyprshutdown --post-cmd 'systemctl reboot'"]
        },
        {
            glyph: "power_settings_new", label: "Shut Down", mnemonic: "s",
            // unchanged — same graceful-exit mechanism as Reboot above.
            command: ["sh", "-c", "cliphist wipe; hyprshutdown --post-cmd 'systemctl poweroff'"]
        }
    ]

    // Lock (index 0, 12 o'clock) auto-focused on open — the least
    // destructive action, and the one action QPOWER-03 never warns about
    // (D-20-29).
    property int focusedIndex: 0

    // ── Severity colour mapping (D-20-21 revised, action -> colour-role
    //    table in 20-UI-SPEC.md § "Color"). Kept as functions rather than
    //    baked into the `actions` array above so every pill's fill stays
    //    a LIVE binding on BarRoles' singleton colours — Gate B criterion
    //    2 requires a live theme switch to re-colour every pill within
    //    one crossfade while the menu is open, which a one-time JS-array
    //    snapshot would not satisfy. `accent`/`fillNotification`
    //    (Colours.primary's hue) are deliberately excluded from every
    //    tier so the focus ring is never drawn against a same-hue fill.
    function fillRoleFor(idx) {
        switch (idx) {
        case 0: case 2: return BarRoles.fillClock;     // Lock, Suspend — tier A
        case 1: case 4: return BarRoles.fillUpdates;   // Log Out, Reboot — tier B
        case 3: case 5: return BarRoles.danger;        // Hibernate, Shut Down — tier C
        default: return BarRoles.fillClock;
        }
    }
    function fgRoleFor(idx) {
        switch (idx) {
        case 0: case 2: return BarRoles.fillClockFg;
        case 1: case 4: return BarRoles.fillUpdatesFg;
        case 3: case 5: return BarRoles.onDanger;
        default: return BarRoles.fillClockFg;
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
    readonly property bool warningActive: powerMenuBackend.pkgManagerBusy || powerMenuBackend.downloadsActive || powerMenuBackend.denyListActive

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

    // Bug 2 fix — see file header. Unmaps the surface (visible = false)
    // BEFORE the action Process starts, for every action, then tears the
    // LazyLoader item down LAST — after the process has already launched,
    // so nothing this function still needs is deleted out from under it.
    function closeAndRun(index) {
        if (index < 0 || index >= powerWindow.actions.length)
            return;
        var cmd = powerWindow.actions[index].command;
        powerWindow.visible = false;
        actionProcess.command = cmd;
        actionProcess.startDetached();
        powerWindow.requestDismiss();
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
    // — unchanged behaviour from wleave. Still undisplayed under the ring
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

    // ── Full-bleed scrim (D-20-21 revised) — a light dim
    //    (Design.sessionScrimOpacity, 0.32), not a screen-take-over.
    //    Carries the click-outside MouseArea (Bug 1 fix, see file
    //    header) so dismissal is deterministic and independent of
    //    HyprlandFocusGrab's focus-change semantics. ────────────────────
    Rectangle {
        id: scrim
        anchors.fill: parent
        color: Qt.rgba(powerWindow.surfaceColour.r, powerWindow.surfaceColour.g, powerWindow.surfaceColour.b, Design.sessionScrimOpacity)

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
        Component.onCompleted: ring.forceActiveFocus()

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

                readonly property bool isFocused: pillIndex === powerWindow.focusedIndex
                readonly property bool hovered: pillMouseArea.containsMouse
                readonly property color fillRole: powerWindow.fillRoleFor(pillIndex)
                readonly property color fgRole: powerWindow.fgRoleFor(pillIndex)

                // Fill: individually frosted and individually coloured
                // per action's severity tier (D-20-21 revised — see the
                // action->colour-role table in 20-UI-SPEC.md § "Color").
                // Hover (pointer only) lifts sessionPillFillOpacity (0.72)
                // toward 0.85, the same +0.1-ish alpha-step idiom
                // BarRoles.capsule->capsuleHover already establishes.
                // No per-pill destructive styling tied to a live warning,
                // ever (D-20-28) — every pill's PERMANENT baseline colour
                // is static, unaffected by any live detector state.
                Rectangle {
                    id: pillFill
                    anchors.fill: parent
                    radius: width / 2
                    color: Qt.rgba(pill.fillRole.r, pill.fillRole.g, pill.fillRole.b,
                                   pill.hovered ? 0.85 : Design.sessionPillFillOpacity)
                }

                // Visible focus is a RING, never a fill swap (QPOWER-02,
                // D-20-24): BarRoles.accent at Design.borderWidth (3px),
                // drawn OUTSIDE the pill's own circular boundary.
                // Colours.primary (accent's hue) is excluded from every
                // tier above so this ring never reads against a
                // same-hue fill.
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: -Design.borderWidth
                    radius: (width) / 2
                    color: "transparent"
                    border.width: Design.borderWidth
                    border.color: BarRoles.accent
                    visible: pill.isFocused
                }

                // Icon only — no label, no mnemonic letter on or under
                // the pill (both retired, locked per the user's own
                // "containing an ICON ONLY" ask). Only the pill's FILL is
                // frosted; the icon glyph itself stays crisp at full
                // opacity.
                Text {
                    anchors.centerIn: parent
                    text: modelData.glyph
                    font.family: Design.symbolFontFamily
                    font.pixelSize: Design.sessionTileIconSize
                    color: pill.fgRole
                }

                MouseArea {
                    id: pillMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
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
