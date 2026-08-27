// Lock.qml — shell-root mount point for the in-process lock screen (quick
// task 260827-833 Task 1, LOCK-01). A plain, always-on `Scope` — NOT
// behind a LazyLoader. The screencopy pre-warm below has to run at shell
// start, and a lock that has to be incubated before it can lock is a lock
// that races the compositor.
//
// `mediaBackend` is relayed straight through to `LockSurface`, the same
// "pass the shared instance down as an untyped `property var`" shape
// `Dashboard.qml:664` already uses for the identical reason: a
// cross-module typed property would need `modules/lock/` to import
// `qs.modules.dashboard` just for a type annotation.
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

Scope {
    id: root

    property alias lock: lock
    property var mediaBackend: null
    // Task 2 (LOCK-01) — the "caelestia" layout's left/right column data.
    // Same untyped-`property var` relay shape as mediaBackend above, read-
    // only: this file never widens either backend's own `drawerOpen` gate.
    property var weatherBackend: null
    property var systemResources: null

    WlSessionLock {
        id: lock

        // Renamed from Caelestia's `unlock` — see LockPam.qml's header for
        // why: the installed WlSessionLock type already exposes a native
        // `unlock()` METHOD, and redeclaring a same-named signal on top of
        // it would collide. This signal is the deferred-unlock trigger;
        // the actual `locked = false` write happens at the END of
        // LockSurface's exit animation, not here.
        signal unlockRequested

        LockSurface {
            lock: lock
            pam: pam
            mediaBackend: root.mediaBackend
            weatherBackend: root.weatherBackend
            systemResources: root.systemResources
        }
    }

    LockPam {
        id: pam

        lock: lock
    }

    // Force a load of a screencopy so the one in the lock works
    // My guess is the ICC backend loads async on first request, which if the lock is
    // the first request it fails to capture (because it's async and the compositor
    // refuses capture when locked)
    Loader {
        asynchronous: true
        active: true
        onLoaded: active = false

        sourceComponent: ScreencopyView {
            captureSource: Quickshell.screens[0]
        }
    }

    IpcHandler {
        function lock(): void {
            root.lock.locked = true;
        }

        function unlock(): void {
            root.lock.unlockRequested();
        }

        function isLocked(): bool {
            return root.lock.locked;
        }

        target: "lock"
    }
}
