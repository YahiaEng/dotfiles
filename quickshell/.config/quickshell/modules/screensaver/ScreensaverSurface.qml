// ScreensaverSurface.qml — one full-output layer surface per screen
// (quick task 260827-b52, rulings D2/D3/D5).
//
// Owns the backdrop, the style switch, the keyboard/pointer dismissal
// and the entrance. It does NOT own the exit's teardown: `Screensaver.qml`
// holds one timer for that, because N surfaces each deciding when they
// are finished is N races to destroy shared state (see that file's own
// header).
//
// ── Layer posture, copied deliberately from PowerMenu.qml ─────────────
// `exclusiveZone: -1`, not 0. A non-negative zone OVERRIDES
// `exclusionMode: ExclusionMode.Ignore`, and at 0 a full-output surface
// on this host measured 2510×1428 against a 2560×1440 monitor — short by
// exactly the reserved zone [0,6,50,6]. On a scrim that showed as an
// undimmed strip; on a screensaver it would show as the bar and a 6px
// band staying lit around a black screen. Both modes are kept: the mode
// states the intent, the zone enforces it.
//
// ── keyboardFocus: Exclusive is what makes D3 work ────────────────────
// Ruling D3 is "any input dismisses". hypridle's own `on-resume` calls
// `qs ipc call screensaver hide` and catches everything the compositor
// sees, focus or not — that is the primary path. This surface's own
// handlers are the second line, and they need the grab: without exclusive
// keyboard focus the first keystroke after the saver appears would go to
// whatever was focused underneath and TYPE INTO IT.
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import "../"
import "../dashboard"

PanelWindow {
    id: root

    required property SaverArt art
    required property string style
    // Driven by Screensaver.qml for the whole set at once.
    required property bool dismissing

    signal dismissRequested

    // Guards every dismissal route so a keypress arriving during the exit
    // is a no-op rather than a second teardown. PowerMenu.qml's
    // `_dismissing` serves the same purpose for the same reason.
    property bool _sent: false

    // ── Pointer arming — MEASURED, and it contradicts what this file
    //    originally claimed ──────────────────────────────────────────
    // The first draft asserted that `positionChanged` "only fires on real
    // movement, so a pointer that merely happens to sit under the surface
    // when it appears does not dismiss it instantly". That is FALSE on
    // this compositor: mapping a full-output layer surface under a
    // stationary cursor delivers a position event immediately, so the
    // saver dismissed itself within the same second it appeared. Measured
    // from the log — show() set `surfaces.active = true`, and two seconds
    // later `isActive` read false with zero layer surfaces.
    //
    // Two independent guards, because either alone is defeatable:
    //   _armed      — no pointer dismissal at all for the first
    //                 `Motion.standardDuration`, which also covers the
    //                 entrance animation, so the saver is never killed by
    //                 an event that arrived while it was still fading in.
    //   _originPt   — the first position seen becomes the origin, and only
    //                 movement beyond `_moveThreshold` from it counts.
    //                 This is what makes a synthetic zero-distance event
    //                 harmless even if it somehow arrives after arming.
    //
    // Keyboard, click and wheel are NOT gated by either: those are
    // unambiguous human intent and dismiss on the first event.
    property bool _armed: false
    property point _originPt: Qt.point(-1, -1)
    // A deliberate nudge, not a twitch. Bound to the spacing scale rather
    // than picked, the same way every other distance in this shell is.
    readonly property real _moveThreshold: Design.spacingSm

    Timer {
        running: true
        repeat: false
        interval: Motion.standardDuration
        onTriggered: root._armed = true
    }

    function requestDismiss() {
        if (root._sent || root.dismissing)
            return;
        root._sent = true;
        root.dismissRequested();
    }

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true
    exclusiveZone: -1
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-screensaver"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    // ── D2: true black, the one hard-coded colour in this module ───────
    // Ruling D2, taken by the operator with the trade-off stated: true
    // black is what makes a glowing wordmark read and what costs least on
    // an OLED, and Omarchy forces the same value with an OSC escape
    // (`printf '\033]11;rgb:00/00/00\007'`).
    //
    // It is NOT a theme role and must not become one. No `Colours.*` value
    // is guaranteed to stay black across a theme switch — `Colours.surface`
    // is #282a36 on dracula and would be near-white under a light matugen
    // palette, which is the opposite of what a screensaver backdrop needs.
    //
    // Declared ONCE, here, and read by every style through
    // `root.backdrop`. `colour-lint` carries a LINE_EXEMPTIONS entry
    // anchored to this declaration — a line exemption rather than a
    // whole-file one, so every other colour in this file stays gated.
    readonly property color backdrop: "#000000"

    color: root.backdrop

    Item {
        id: content

        anchors.fill: parent

        // Entrance. A property-value-source animation rather than an
        // imperative start(), for the same reason LockSurface.qml gives:
        // it self-starts at creation and is guaranteed to settle on `to`,
        // so there is no path where a missed trigger leaves a surface that
        // has grabbed the keyboard sitting invisible over the desktop.
        NumberAnimation on opacity {
            from: 0
            to: 1
            duration: Motion.emphasizedInDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Motion.emphasizedInEasing
        }

        // Exit. Driven by the shared `dismissing` flag; the actual
        // unmount happens in Screensaver.qml after this has had time to
        // play (MEMORY exit-animation-vs-loader-teardown — a surface
        // destroyed on frame one has no exit at all).
        opacity: root.dismissing ? 0 : 1

        Behavior on opacity {
            NumberAnimation {
                duration: Motion.emphasizedOutDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.emphasizedOutEasing
            }
        }

        Loader {
            id: styleLoader

            anchors.fill: parent
            // Stops the style's own timers/animations the moment dismissal
            // begins, so nothing repaints behind a fading layer.
            active: true

            sourceComponent: {
                switch (root.style) {
                case "terminal":
                    return terminalComponent;
                case "aurora":
                    return auroraComponent;
                case "constellation":
                    return constellationComponent;
                case "rail":
                    return railComponent;
                default:
                    // Every valid style has its own arm above; this is the
                    // never-blank-surface fallback for a value from a
                    // future version. "off" never reaches here — the
                    // surface is not mounted at all in that case.
                    return terminalComponent;
                }
            }
        }
    }

    Component {
        id: terminalComponent

        SaverTerminal {
            art: root.art
            active: !root.dismissing
        }
    }

    Component {
        id: auroraComponent

        SaverAurora {
            art: root.art
            active: !root.dismissing
        }
    }

    Component {
        id: constellationComponent

        SaverConstellation {
            art: root.art
            active: !root.dismissing
        }
    }

    Component {
        id: railComponent

        SaverRail {
            art: root.art
            active: !root.dismissing
        }
    }

    // ── D3: any input ─────────────────────────────────────────────────
    // Keyboard first. `focus: true` on an anchor-filling Item is the same
    // single-focus-owner shape LockSurface.qml uses, and for the same
    // reason: the styles must never need to know about focus.
    Item {
        id: focusOwner

        anchors.fill: parent
        focus: true

        onActiveFocusChanged: {
            if (!activeFocus && !root.dismissing)
                forceActiveFocus();
        }

        Keys.onPressed: event => {
            event.accepted = true;
            root.requestDismiss();
        }
    }

    // Pointer second. `hoverEnabled` is what catches bare motion — the
    // operator's ruling was "any input", and a mouse nudge with no button
    // press is the commonest way a person un-idles a machine. See the
    // `_armed`/`_originPt` block above for why bare motion needs two
    // guards and the button events need none.
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.AllButtons
        cursorShape: Qt.BlankCursor

        onPositionChanged: mouse => {
            if (!root._armed)
                return;
            if (root._originPt.x < 0) {
                root._originPt = Qt.point(mouse.x, mouse.y);
                return;
            }
            const dx = mouse.x - root._originPt.x;
            const dy = mouse.y - root._originPt.y;
            if (Math.hypot(dx, dy) >= root._moveThreshold)
                root.requestDismiss();
        }

        onPressed: mouse => {
            mouse.accepted = true;
            root.requestDismiss();
        }

        onWheel: wheel => {
            wheel.accepted = true;
            root.requestDismiss();
        }
    }
}
