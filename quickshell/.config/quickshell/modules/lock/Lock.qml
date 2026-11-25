// Owns the compositor lock, PAM authentication and recovery across outputs.
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../"

Scope {
    id: root

    property alias lock: lock
    property var mediaBackend: null
    // Task 2 (LOCK-01) — the "caelestia" layout's left/right column data.
    // Same untyped-`property var` relay shape as mediaBackend above, read-
    // only: this file never widens either backend's own `drawerOpen` gate.
    property var weatherBackend: null
    property var systemResources: null

    readonly property string instance: Quickshell.env("HYPRLAND_INSTANCE_SIGNATURE")
    property bool unlocking: false
    property bool restorePending: false

    FileView {
        id: lockState
        path: root.instance && Quickshell.env("XDG_RUNTIME_DIR")
            ? Quickshell.env("XDG_RUNTIME_DIR") + "/hypr/" + root.instance + "/quickshell-lock.state"
            : ""
        blockLoading: true
        blockWrites: true
        atomicWrites: true
        printErrors: false
        onSaveFailed: error => console.warn("Unable to save the session lock state:", error)
    }

    function saveLockState(value): void {
        if (lockState.path)
            lockState.setText(value);
    }

    WlSessionLock {
        id: lock

        signal unlockRequested

        onSecureChanged: if (secure) root.saveLockState("locked")
        onUnlockRequested: {
            if (lock.secure && !root.unlocking) {
                root.unlocking = true;
                finishUnlock.restart();
            }
        }

        LockSurface {
            pam: pam
            unlocking: root.unlocking
            mediaBackend: root.mediaBackend
            weatherBackend: root.weatherBackend
            systemResources: root.systemResources
        }
    }

    LockPam {
        id: pam
        lock: lock
    }

    // One timer owns unlock across all outputs, including if an output
    // disappears during the exit animation.
    Timer {
        id: finishUnlock
        interval: Motion.emphasizedInDuration
        onTriggered: {
            lock.locked = false;
            root.unlocking = false;
            root.saveLockState("unlocked");
        }
    }

    // Hyprland keeps an abandoned lock in force. Reattach a PAM-backed
    // client when a real output returns, without clearing that lock.
    Timer {
        interval: 150
        running: root.restorePending && Quickshell.screens.some(screen =>
            screen && screen.name && screen.name !== "FALLBACK")
        onTriggered: {
            root.restorePending = false;
            lock.locked = true;
        }
    }

    Component.onCompleted: {
        if (lockState.path)
            root.restorePending = lockState.text().trim() === "locked";
    }

    IpcHandler {
        function lock(): void {
            root.restorePending = false;
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
