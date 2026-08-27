// Screensaver.qml — shell-root mount point for the in-process idle
// screensaver (quick task 260827-b52).
//
// Inspired by Omarchy's screensaver, which spawns one terminal window per
// monitor running `tte` over a text file. That mechanism is NOT ported:
// v4.0 retired waybar, swaync, swayosd, walker/elephant and hyprlock
// precisely to stop the shell being split across a second toolkit, and
// `tte` is not packaged on Arch besides. What ports is the idea — a
// full-bleed idle canvas showing the project's own wordmark under cycling
// effects, dismissed by any input.
//
// One consequence worth recording: Omarchy sets its screensaver at 150s
// and its lock at 152s, because spawning a terminal window resets the
// idle timer and the lock's clock restarts. Nothing is spawned here, so
// the ladder needs no such compensation — the saver chains onto the
// existing 300s dim listener and the 600s lock listener is untouched.
//
// ── One `active`, N surfaces, ONE teardown timer ──────────────────────
// Each screen gets its own surface (ruling D5, independent animation),
// but dismissal is shared state. If every surface decided for itself when
// its exit had finished, N timers would race to flip the same `active`
// flag and the last one would be flipping a property whose LazyLoaders
// were already destroyed. So: `hide()` sets `_dismissing`, every surface
// animates out off that one flag, and ONE timer here unmounts them all.
//
// ── The inhibit gate lives at show(), not at the caller ───────────────
// Ruling D4 inhibits the saver while a player is Playing or a window is
// fullscreen. That check is here, at the single entry point, rather than
// in the hypridle command — a trigger added later (a keybind, a settings
// "preview" button) inherits the gate for free instead of having to
// remember it. This is the same reasoning `Toast.qml`'s `suppressed`
// property records for the OSD.
//
// Gaming mode needs no entry here: `gaming-mode-toggle.sh` freezes
// hypridle outright with `pkill -STOP -x hypridle`, so the timeout that
// would call `show()` never fires.
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import "../"

Scope {
    id: root

    // Threaded in from shell.qml — the same shared-instance relay every
    // other surface uses. Never mounts its own backend.
    property var mediaBackend: null
    // shell.qml's own `fullscreenBlocking`, relayed rather than
    // recomputed: it already tracks `Hyprland.activeToplevel`'s fullscreen
    // state for the bar and the launcher, and a second reader of the same
    // IPC object would be a second source of truth for one fact.
    property bool fullscreenBlocking: false

    readonly property bool active: surfaces.active

    // Validated the same way LockSurface.qml validates `lock.layout`: an
    // unrecognised value (hand-edited prefs.json, a style from a future
    // version) resolves to a real string, never `undefined`. "off" is a
    // first-class value here rather than a separate enabled/disabled pref
    // — it is what makes the settings picker its own kill switch, the
    // same shape `shell.qml`'s `edgeBarStyle` already uses.
    readonly property string style: {
        const v = Prefs.getValue("screensaver.style");
        switch (v) {
        case "off":
        case "terminal":
        case "aurora":
        case "constellation":
        case "rail":
            return v;
        default:
            return "terminal";
        }
    }

    readonly property bool mediaPlaying: root.mediaBackend !== null && root.mediaBackend.playing === true

    // Deliberately an affirmative list of reasons to stay away, not a
    // negation of "may show" — each clause is separately readable in a
    // log line and separately removable.
    readonly property bool inhibited: root.style === "off" || root.mediaPlaying || root.fullscreenBlocking

    property bool _dismissing: false

    function show(): void {
        if (root.inhibited || surfaces.active)
            return;
        root._dismissing = false;
        surfaces.active = true;
    }

    function hide(): void {
        if (!surfaces.active || root._dismissing)
            return;
        root._dismissing = true;
        teardown.restart();
    }

    Timer {
        id: teardown

        // The exit animation's own length, read from the same token the
        // surfaces animate on — not a second constant that would drift
        // away from it. A little margin so the unmount lands after the
        // last frame rather than on it.
        interval: Motion.emphasizedOutDuration + Motion.staggerOffsetDuration
        repeat: false
        onTriggered: {
            surfaces.active = false;
            root._dismissing = false;
        }
    }

    // The wordmark, resolved once and shared by every screen's surface —
    // a per-surface SaverArt would mean N FileViews watching the same
    // branding file.
    SaverArt {
        id: sharedArt
    }

    Variants {
        id: surfaces

        property bool active: false

        model: Quickshell.screens

        delegate: Component {
            LazyLoader {
                // Variants sets `modelData` as an initial property on the
                // delegate root object (not merely a context property for
                // non-Item roots like LazyLoader) — declare it explicitly,
                // exactly as Probe.qml does.
                required property var modelData

                active: surfaces.active

                ScreensaverSurface {
                    screen: modelData
                    art: sharedArt
                    style: root.style
                    dismissing: root._dismissing
                    onDismissRequested: root.hide()
                }
            }
        }
    }

    // ── IPC — the surface's only external entry point ─────────────────
    // `show` is what the 300s hypridle listener chains onto; `hide` is
    // what its `on-resume` calls (ruling D3's primary path, since
    // hypridle's idle-notify sees input regardless of which surface holds
    // focus). `isActive` exists so a live check can answer "is it up?"
    // without a screenshot.
    IpcHandler {
        target: "screensaver"

        function show(): void {
            root.show();
        }

        function hide(): void {
            root.hide();
        }

        function toggle(): void {
            if (root.active)
                root.hide();
            else
                root.show();
        }

        function isActive(): bool {
            return root.active;
        }

        // Reports WHY a show() would be refused. A saver that silently
        // does nothing is indistinguishable from a broken one, and this
        // is the cheap way to tell them apart from a shell prompt.
        //
        // The null-backend arm is not defensive padding. `mediaPlaying`
        // is false both when nothing is playing AND when the relay from
        // shell.qml is broken, so without this line a severed D4 inhibit
        // reports exactly the same string as a healthy idle shell — the
        // failure would be invisible to the only instrument that can see
        // it. Same reasoning as the `status()` verb on the bar target,
        // which exists so single ownership is proven rather than asserted.
        function status(): string {
            if (root.style === "off")
                return "off (style picker set to off)";
            if (root.mediaBackend === null)
                return "DEGRADED: media backend not relayed — the D4 media inhibit cannot fire";
            if (root.mediaPlaying)
                return "inhibited (a media player is playing)";
            if (root.fullscreenBlocking)
                return "inhibited (a window is fullscreen)";
            return root.active ? "active (" + root.style + ")" : "idle (" + root.style + ")";
        }
    }
}
