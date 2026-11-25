// Per-screen lock layout, wallpaper and keyboard focus. Lock.qml owns
// the lock lifetime across all outputs.
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

    required property LockPam pam
    property var mediaBackend: null
    // Task 2 (LOCK-01) — the "caelestia" layout's left/right column data,
    // relayed straight through from Lock.qml. Read-only: neither backend's
    // `drawerOpen` gate is touched anywhere in this module tree.
    property var weatherBackend: null
    property var systemResources: null

    property bool unlocking: false

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

    readonly property bool backdropIsBlur: root.layoutKey !== "rail" && root.layoutKey !== "split"

    // The wallpaper is also available on outputs added while locked.
    readonly property url wallpaperUrl: "file://" + Quickshell.env("HOME") + "/.local/state/theme/current.jpg"

    color: Colours.surface

    Item {
        id: content

        anchors.fill: parent

        property real entranceOpacity: 0
        property real exitOpacity: root.unlocking ? 0 : 1
        opacity: entranceOpacity * exitOpacity
        scale: root.unlocking ? 1.06 : 1

        NumberAnimation on entranceOpacity {
            from: 0
            to: 1
            duration: Motion.emphasizedInDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Motion.emphasizedInEasing
        }
        Behavior on exitOpacity {
            NumberAnimation {
                duration: Motion.emphasizedInDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.emphasizedOutEasing
            }
        }
        Behavior on scale {
            NumberAnimation {
                duration: Motion.emphasizedInDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.emphasizedOutEasing
            }
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

        Image {
            anchors.fill: parent
            source: root.wallpaperUrl
            fillMode: Image.PreserveAspectCrop
            cache: false
            layer.enabled: root.backdropIsBlur
            layer.effect: MultiEffect {
                autoPaddingEnabled: false
                blurEnabled: true
                blur: 1
                blurMax: 64
            }
        }

        Rectangle {
            anchors.fill: parent
            color: Colours.surface
            opacity: 0.65
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
        id: continuityComponent

        LockContinuity {
            pam: root.pam
            unlocking: root.unlocking
            mediaBackend: root.mediaBackend
        }
    }

    Component {
        id: caelestiaComponent

        LockCaelestia {
            pam: root.pam
            unlocking: root.unlocking
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
            unlocking: root.unlocking
            mediaBackend: root.mediaBackend
            systemResources: root.systemResources
            screen: root.screen
        }
    }

    Component {
        id: splitComponent

        LockSplit {
            pam: root.pam
            unlocking: root.unlocking
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
            unlocking: root.unlocking
            mediaBackend: root.mediaBackend
            screen: root.screen
        }
    }

}
