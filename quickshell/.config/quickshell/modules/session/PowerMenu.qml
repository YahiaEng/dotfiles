// PowerMenu.qml — the session/power dialog (Phase 20 Plan 06 Task 1,
// QPOWER-01/02/04, D-20-21..26). Built ON PanelDialog.qml's pattern
// language (background/rim/HyprlandFocusGrab construction), NOT by
// instantiating it: PanelDialog is anchors-top, bottom-rounded, docked
// under the bar — built for drawer-style panels. This is a screen-centred
// modal, so the construction is copied and the geometry diverges.
//
// Scope note: the QPOWER-03 warning banner/detectors and the Cascade.qml
// entrance are plan 20-07's job, not this file's. This plan wires the
// thinnest complete path: Super+Shift+Q opens the dialog, Lock is
// focused, Enter locks the session.
//
// ── Exclusive focus + HyprlandFocusGrab coexistence (D-20-24) ────────────
// WlrKeyboardFocus.Exclusive is a deliberate divergence from D-19-18's
// no-exclusive-focus rule, written for the non-modal notification centre.
// This surface's actions end the session, so it earns exclusive focus —
// every keypress must land here while it is open. HyprlandFocusGrab still
// provides click-outside dismissal ALONGSIDE exclusive focus below — no
// surface in this repo has combined the two before; proven live at this
// plan's Task 1 human-check, not assumed from the OnDemand case.
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
    // taken, the dialog just closes.
    function handleEscape() {
        powerWindow.requestDismiss();
    }

    // ── Layer posture — full-output span so the scrim gives
    //    HyprlandFocusGrab's click-outside dismissal a screen-wide catch
    //    area with no second window to coordinate (Overview.qml's own
    //    full-screen-catch-region precedent). exclusiveZone 0 — an
    //    overlay, reserves nothing. Namespace was declared in 20-03
    //    already; first rendered here. ────────────────────────────────────
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

    // ── Local Design-derived constants — PanelDialog.qml's own idiom ─────
    readonly property real panelSurfaceOpacity: 0.78
    // lineHeightTight/lineHeightNormal — 20-UI-SPEC.md's Step-9.5
    // correction confirmed these are NOT Design.qml tokens (20-03-SUMMARY.md
    // deliberately did not promote them). Declared locally per
    // PanelDialog.qml's own precedent, not a third declaration site.
    readonly property real lineHeightTight: 1.2
    readonly property real lineHeightNormal: 1.5

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
    //    Row order exactly as the selected mockup names it: Lock/Log Out/
    //    Suspend top row (indices 0-2), Hibernate/Reboot/Shut Down bottom
    //    row (indices 3-5) — array order IS grid reading order.
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

    // Lock (index 0, top-left) auto-focused on open — the least
    // destructive action, and the one action QPOWER-03 never warns about
    // (D-20-29).
    property int focusedIndex: 0

    function runAction(index) {
        if (index < 0 || index >= powerWindow.actions.length)
            return;
        actionProcess.command = powerWindow.actions[index].command;
        actionProcess.startDetached();
    }

    // startDetached() — NOT a lifetime-bound `running` assignment —
    // matching PanelDialog.qml's advancedProcess exactly: the LazyLoader
    // that mounts this surface destroys it on dismiss, and a
    // lifetime-bound child would be SIGTERM'd along with it.
    Process {
        id: actionProcess
        command: []
    }

    // Two-dimensional arrow-key move across the 3x2 grid — up/down
    // between rows, left/right within a row, matching visual adjacency.
    // No wraparound (20-UI-SPEC.md's Focus Treatment): a move past the
    // grid edge is a no-op, not a wrap to the opposite edge.
    function moveFocus(dCol, dRow) {
        var col = powerWindow.focusedIndex % 3;
        var row = Math.floor(powerWindow.focusedIndex / 3);
        var newCol = col + dCol;
        var newRow = row + dRow;
        if (newCol < 0 || newCol > 2 || newRow < 0 || newRow > 1)
            return;
        powerWindow.focusedIndex = newRow * 3 + newCol;
    }

    // Mnemonics fire their matching action directly from any focus state
    // — unchanged behaviour from wleave, now visibly surfaced on the
    // tiles (D-20-24).
    function fireMnemonic(letter) {
        for (var i = 0; i < powerWindow.actions.length; i++) {
            if (powerWindow.actions[i].mnemonic === letter) {
                powerWindow.runAction(i);
                return;
            }
        }
    }

    // ── Full-bleed scrim (D-20-21) — gives HyprlandFocusGrab's click-
    //    outside dismissal a screen-wide catch area with no second window
    //    to coordinate; resolves the "scrim as window property vs
    //    separate layer" discretion item in favour of one window. ───────
    Rectangle {
        id: scrim
        anchors.fill: parent
        color: Qt.rgba(Colours.surface.r, Colours.surface.g, Colours.surface.b, Design.sessionScrimOpacity)
    }

    // ── HyprlandFocusGrab (D-20-24) — click-outside dismissal, copied
    //    verbatim from PanelDialog.qml, COEXISTING with Exclusive focus
    //    above — the combination no surface in this repo has used before,
    //    proven live at this plan's Task 1 human-check. ──────────────────
    HyprlandFocusGrab {
        id: grab
        windows: [ powerWindow ]
        active: true
        onCleared: powerWindow.requestDismiss()
    }

    // ── The dialog card — centred, uniform-rounded on all four corners
    //    (unlike PanelDialog's bottom-only rounding), since this card
    //    floats fully clear of every screen edge. ─────────────────────────
    Item {
        id: card
        anchors.centerIn: parent
        implicitWidth: Design.sessionDialogWidth
        implicitHeight: cardColumn.implicitHeight
        focus: true

        Keys.onEscapePressed: powerWindow.handleEscape()
        Keys.onReturnPressed: powerWindow.runAction(powerWindow.focusedIndex)
        Keys.onEnterPressed: powerWindow.runAction(powerWindow.focusedIndex)
        Keys.onLeftPressed: powerWindow.moveFocus(-1, 0)
        Keys.onRightPressed: powerWindow.moveFocus(1, 0)
        Keys.onUpPressed: powerWindow.moveFocus(0, -1)
        Keys.onDownPressed: powerWindow.moveFocus(0, 1)
        Keys.onPressed: (event) => {
            var letter = event.text.toLowerCase();
            for (var i = 0; i < powerWindow.actions.length; i++) {
                if (powerWindow.actions[i].mnemonic === letter) {
                    powerWindow.runAction(i);
                    event.accepted = true;
                    return;
                }
            }
        }
        Component.onCompleted: card.forceActiveFocus()

        Rectangle {
            id: cardBackground
            anchors.fill: parent
            radius: Design.popoutCornerRadius
            color: Qt.rgba(Colours.surface.r, Colours.surface.g, Colours.surface.b, powerWindow.panelSurfaceOpacity)
        }

        GradientBorder {
            anchors.fill: parent
            borderWidth: Design.borderWidth
            topLeftRadius: Design.popoutCornerRadius
            topRightRadius: Design.popoutCornerRadius
            bottomLeftRadius: Design.popoutCornerRadius
            bottomRightRadius: Design.popoutCornerRadius
        }

        Column {
            id: cardColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top

            // ── Header band — popoutHeaderHeight (48px), NOT PanelDialog's
            //    own 72px headerHeight: this dialog carries no Advanced
            //    button and no icon+title pairing at that scale. No close
            //    button — dismissal inherits the Escape/click-outside set
            //    every other dismissible surface in this shell uses. ─────
            Item {
                id: cardHeader
                width: cardColumn.width
                height: Design.popoutHeaderHeight

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: Design.panelPadding
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Session"
                    font.pixelSize: Design.fontHeading
                    font.weight: Design.weightEmphasis
                    lineHeight: powerWindow.lineHeightTight
                    color: Colours.onSurface
                }
            }

            // ── The 3x2 grid — sessionTileWidth(136)*3 + spacingMd(16)*2
            //    gaps + panelPadding(24)*2 sides == sessionDialogWidth
            //    (488) exactly (20-03's own derivation comment), so this
            //    Grid needs no explicit width — its own padding already
            //    resolves to the card's full width. ───────────────────────
            Grid {
                id: tileGrid
                columns: 3
                spacing: Design.spacingMd
                leftPadding: Design.panelPadding
                rightPadding: Design.panelPadding
                topPadding: Design.panelPadding
                bottomPadding: Design.panelPadding

                Repeater {
                    id: tileRepeater
                    model: powerWindow.actions

                    delegate: Item {
                        id: tile
                        width: Design.sessionTileWidth
                        height: Design.sessionTileHeight

                        readonly property bool isFocused: index === powerWindow.focusedIndex
                        readonly property bool hovered: tileMouseArea.containsMouse

                        // Fill: Colours.surfaceVariant at rest — identical
                        // source to PanelDialog's own Advanced button, no
                        // new colour. Hover (pointer only) lifts toward a
                        // lighter blend, the same +0.1-alpha-step idiom
                        // BarRoles.capsule->capsuleHover establishes
                        // (0.85->0.95), applied locally since this dialog
                        // reads Colours.* directly. No per-tile destructive
                        // styling, ever (D-20-28) — all six tiles render
                        // identically at rest regardless of focus/warning
                        // state.
                        Rectangle {
                            id: tileFill
                            anchors.fill: parent
                            radius: Design.sessionTileRadius
                            color: tile.hovered
                                ? Qt.rgba(Colours.surfaceVariant.r, Colours.surfaceVariant.g, Colours.surfaceVariant.b, 0.95)
                                : Qt.rgba(Colours.surfaceVariant.r, Colours.surfaceVariant.g, Colours.surfaceVariant.b, 0.85)
                        }

                        // Visible focus is a RING, never a fill swap
                        // (QPOWER-02, D-20-24): BarRoles.accent at
                        // Design.borderWidth (3px), drawn OUTSIDE the
                        // tile's own sessionTileRadius (16px) boundary so
                        // it reads as an addition to the tile rather than
                        // a recolour of it.
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: -Design.borderWidth
                            radius: Design.sessionTileRadius + Design.borderWidth
                            color: "transparent"
                            border.width: Design.borderWidth
                            border.color: BarRoles.accent
                            visible: tile.isFocused
                        }

                        Column {
                            anchors.centerIn: parent
                            spacing: Design.spacingXs

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.glyph
                                font.family: Design.symbolFontFamily
                                font.pixelSize: Design.sessionTileIconSize
                                color: Colours.onSurfaceVariant
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.label
                                font.pixelSize: Design.fontBody
                                font.weight: Design.weightEmphasis
                                lineHeight: powerWindow.lineHeightTight
                                color: Colours.onSurfaceVariant
                            }
                        }

                        // Mnemonic letter — low-emphasis, bottom-right
                        // corner, inset spacingXs (4px), at the
                        // muted-but-present disabledOpacity register
                        // (0.38) used elsewhere for the same purpose.
                        Text {
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: Design.spacingXs
                            text: modelData.mnemonic
                            font.pixelSize: Design.fontLabel
                            lineHeight: powerWindow.lineHeightNormal
                            color: Colours.onSurfaceVariant
                            opacity: 0.38
                        }

                        MouseArea {
                            id: tileMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                powerWindow.focusedIndex = index;
                                powerWindow.runAction(index);
                            }
                        }
                    }
                }
            }
        }
    }
}
