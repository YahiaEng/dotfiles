// LockSurface.qml — the per-screen WlSessionLockSurface (quick task
// 260827-833 Task 1, LOCK-01). Owns layout resolution, the backdrop
// (blurred screencopy vs sharp wallpaper), the single keyboard-focus
// owner shared by all five layouts, and the deferred-unlock exit
// animation.
//
// ── layoutKey never resolves to `undefined` ───────────────────────────
// Reads `Prefs.getValue("lock.layout")` and validates it against the five
// known layout strings, falling back to `"continuity"` for anything else
// (missing key, hand-edited prefs.json, a layout name from a future
// version). `cond ? X : undefined` on a real property sticks at 0 forever
// because `cond` is false at construction time (MEMORY
// qml-undefined-branch-destroys-binding) — every branch below returns a
// real value.
//
// ── backdropIsBlur is a static map keyed on layoutKey, NOT read off the
//    loaded layout item ─────────────────────────────────────────────────
// A Loader configures its `item` AFTER construction (MEMORY
// qml-configured-after-construction), so asking the freshly-loaded layout
// item what backdrop it wants is a construction-order bug waiting to
// happen. The map lives here instead.
//
// ── One focus owner, not five ──────────────────────────────────────────
// Caelestia puts `focus: true` + `Keys.onPressed` on its password field
// because it has exactly one layout. This surface has five, so the key
// handler lives once, here, as a non-visual `Item` — every layout's
// `LockField` renders `pam.buffer` but never itself owns focus.
pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import "../"

WlSessionLockSurface {
    id: root

    required property WlSessionLock lock
    required property LockPam pam
    property var mediaBackend: null
    // Task 2 (LOCK-01) — the "caelestia" layout's left/right column data,
    // relayed straight through from Lock.qml. Read-only: neither backend's
    // `drawerOpen` gate is touched anywhere in this module tree.
    property var weatherBackend: null
    property var systemResources: null

    readonly property alias unlocking: unlockAnim.running

    readonly property string layoutKey: {
        const v = Prefs.getValue("lock.layout");
        switch (v) {
        case "caelestia":
        case "continuity":
        case "rail":
        case "split":
        case "focus":
            return v;
        default:
            return "continuity";
        }
    }

    // caelestia/continuity/focus blur a live ScreencopyView; rail/split
    // show the still wallpaper unblurred (the design study's own
    // directions C and D deliberately sidestep screencopy).
    readonly property var _blurMap: ({
        "caelestia": true,
        "continuity": true,
        "rail": false,
        "split": false,
        "focus": true
    })
    readonly property bool backdropIsBlur: root._blurMap[root.layoutKey] !== false

    color: "transparent"

    Item {
        id: content

        anchors.fill: parent

        // ── Entrance ──────────────────────────────────────────────────
        // ADDED 2026-08-27. There was no entrance animation at all: the
        // surface was simply mapped at full opacity, so every layout "just
        // suddenly appears". Only Quiet Focus and Split Canvas looked
        // animated, and only because those two happen to animate their own
        // internal contents — which is exactly the pair the operator named.
        //
        // Written as property-value-source animations (`NumberAnimation on
        // <prop>`) rather than an imperative `start()` in
        // `Component.onCompleted`. They self-start at creation and are
        // guaranteed to settle on `to`, so there is no path where a missed
        // trigger leaves the lock screen invisible — which on THIS surface
        // would mean a black screen with no way to type a password.
        NumberAnimation on opacity {
            from: 0
            to: 1
            duration: Motion.emphasizedInDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Motion.emphasizedInEasing
        }

        NumberAnimation on scale {
            from: 1.04
            to: 1
            duration: Motion.spatialInDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Motion.spatialInEasing
        }

        // Surface-wide click-to-refocus. Declared BEFORE the layout loader
        // so it sits underneath: a LockField's own MouseArea still wins for
        // hover and the I-beam cursor, and this catches clicks anywhere
        // else. Part of the 2026-08-27 fix for "clicking the password input
        // does nothing".
        MouseArea {
            anchors.fill: parent
            onPressed: focusOwner.forceActiveFocus()
        }

        Loader {
            id: backdropLoader

            anchors.fill: parent
            sourceComponent: root.backdropIsBlur ? blurredBackdropComponent : wallpaperBackdropComponent
        }

        Loader {
            id: layoutLoader

            anchors.fill: parent
            sourceComponent: {
                switch (root.layoutKey) {
                case "continuity":
                    return continuityComponent;
                case "caelestia":
                    return caelestiaComponent;
                case "rail":
                    return railComponent;
                case "split":
                    return splitComponent;
                case "focus":
                    return focusComponent;
                default:
                    // Every valid layoutKey value now has its own arm.
                    // This default stays as the never-empty-surface
                    // fallback for any FUTURE unhandled value.
                    return continuityComponent;
                }
            }
        }

        // The single focus-owning item. `Keys.onPressed` routes every
        // keypress through `pam.handleKey`, regardless of which layout is
        // loaded.
        Item {
            id: focusOwner

            anchors.fill: parent
            focus: true

            onActiveFocusChanged: {
                if (!activeFocus)
                    forceActiveFocus();
            }

            Keys.onPressed: event => root.pam.handleKey(event)

            Connections {
                target: root.pam
                function onFocusRequested() {
                    focusOwner.forceActiveFocus();
                }
            }
        }
    }

    Component {
        id: blurredBackdropComponent

        Item {
            anchors.fill: parent

            layer.enabled: true
            layer.effect: MultiEffect {
                autoPaddingEnabled: false
                blurEnabled: true
                blur: 1
                blurMax: 64
                blurMultiplier: 1
            }

            ScreencopyView {
                anchors.fill: parent
                captureSource: root.screen
            }
        }
    }

    Component {
        id: wallpaperBackdropComponent

        Image {
            anchors.fill: parent
            source: "file://" + Quickshell.env("HOME") + "/.local/state/theme/current.jpg"
            fillMode: Image.PreserveAspectCrop
        }
    }

    Component {
        id: continuityComponent

        LockContinuity {
            pam: root.pam
            mediaBackend: root.mediaBackend
        }
    }

    Component {
        id: caelestiaComponent

        LockCaelestia {
            pam: root.pam
            mediaBackend: root.mediaBackend
            weatherBackend: root.weatherBackend
            systemResources: root.systemResources
            screen: root.screen
        }
    }

    Component {
        id: railComponent

        LockRail {
            pam: root.pam
            mediaBackend: root.mediaBackend
            systemResources: root.systemResources
            screen: root.screen
        }
    }

    Component {
        id: splitComponent

        LockSplit {
            pam: root.pam
            mediaBackend: root.mediaBackend
            systemResources: root.systemResources
            weatherBackend: root.weatherBackend
            screen: root.screen
        }
    }

    Component {
        id: focusComponent

        LockFocus {
            pam: root.pam
            mediaBackend: root.mediaBackend
            screen: root.screen
        }
    }

    Connections {
        function onUnlockRequested() {
            unlockAnim.start();
        }

        target: root.lock
    }

    // Deferred unlock: fade+shrink the content out, THEN set
    // `lock.locked = false` as the very last step. Doing the property
    // write at the end (not on the trigger) is what stops the surface
    // being destroyed on frame one (MEMORY
    // exit-animation-vs-loader-teardown).
    SequentialAnimation {
        id: unlockAnim

        // STRENGTHENED 2026-08-27. The exit existed and was correctly
        // deferred, but was imperceptible: opacity over 150ms with a 4%
        // scale change reads as "the lockscreen suddenly disappears".
        // The path itself was never the problem — PAM success emits
        // `unlockRequested`, which starts this, and only its final
        // PropertyAction clears `locked`. Only the magnitudes changed.
        ParallelAnimation {
            NumberAnimation {
                target: content
                property: "opacity"
                to: 0
                duration: Motion.emphasizedInDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.emphasizedOutEasing
            }
            NumberAnimation {
                target: content
                property: "scale"
                to: 1.06
                duration: Motion.emphasizedInDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.emphasizedOutEasing
            }
        }
        PropertyAction {
            target: root.lock
            property: "locked"
            value: false
        }
    }
}
