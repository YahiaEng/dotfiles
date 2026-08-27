// LockPam.qml — PAM authentication for the in-process lock screen (quick
// task 260827-833 Task 1, LOCK-01). Shape copied from the vendored
// `.planning/notes/caelestia-lock/Pam.qml`, with `ManualPamContext`
// (fprint/howdy) DROPPED ENTIRELY — this host has neither fingerprint nor
// Howdy face-auth, and Caelestia's fprint/howdy contexts reach
// `GlobalConfig`/`SessionManager` types that do not exist in this tree.
//
// ── PAM config decision (measured this session, binding — see the plan's
//    "Measured ground truth" section) ─────────────────────────────────
// `config: "passwd"` with NO `configDirectory` override. The installed
// `/usr/bin/quickshell` binary's own default `configDirectory` is
// `/etc/pam.d` (verified: `strings /usr/bin/quickshell | grep -E
// '^/etc/pam'` finds the literal string). `/etc/pam.d/passwd` exists
// (shipped by `shadow`, always present) and its first line is `auth
// include system-auth` — the real auth stack (pam_faillock -> pam_unix ->
// pam_faillock). `/etc/pam.d/hyprlock` also exists today, but it is
// SHIPPED BY THE HYPRLOCK PACKAGE and disappears the moment Task 8
// uninstalls it — naming it here would build a lock screen that breaks
// the instant its own migration completes. Caelestia's own upstream also
// names `"passwd"`.
//
// ── Naming: `unlockRequested`, NOT `unlock` (deviation from the vendored
//    source, Rule 1 auto-fix — see SUMMARY) ──────────────────────────────
// The installed `Quickshell.Wayland/WlSessionLock` type ALREADY exposes a
// native `Method { name: "unlock" }` (verified directly against
// /usr/lib/qt6/qml/Quickshell/Wayland/quickshell-wayland.qmltypes).
// Caelestia's own Lock.qml declares a CUSTOM `signal unlock` directly on
// its WlSessionLock instance, which would collide with that inherited
// method name and fail to compile on THIS install. The signal is
// renamed `unlockRequested` everywhere in this module tree; the deferred-
// unlock architecture (fire the signal on PAM success, let LockSurface's
// exit animation set `locked = false` at its own end) is otherwise
// unchanged from the reference.
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Pam

Scope {
    id: root

    enum PamState {
        None,
        Error,
        MaxTries,
        Failed
    }

    required property WlSessionLock lock

    readonly property alias passwd: passwd

    property string lockMessage
    property int state: LockPam.None
    property string buffer

    signal flashMsg

    // Copied verbatim from caelestia-lock/Pam.qml's character filter: the
    // regex allows anything except control characters, Enter starts an
    // auth attempt, Backspace deletes one character, Ctrl+Backspace clears
    // the whole buffer. The howdy-trigger-on-empty-enter branch is
    // dropped — there is no howdy context to trigger.
    function handleKey(event) {
        if (passwd.active)
            return;

        if (state === LockPam.MaxTries)
            return;

        if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
            passwd.start();
        } else if (event.key === Qt.Key_Backspace) {
            if (event.modifiers & Qt.ControlModifier) {
                buffer = "";
            } else {
                buffer = buffer.slice(0, -1);
            }
        } else if (/^[^\x00-\x1F\x7F-\x9F]+$/.test(event.text)) {
            // Allow anything except control characters
            buffer += event.text;
        }
    }

    PamContext {
        id: passwd

        config: "passwd"

        onMessageChanged: {
            if (message.startsWith("The account is locked"))
                root.lockMessage = message;
            else if (root.lockMessage && message.endsWith(" left to unlock)"))
                root.lockMessage += "\n" + message;
        }

        onResponseRequiredChanged: {
            if (!responseRequired)
                return;

            respond(root.buffer);
            root.buffer = "";
        }

        onCompleted: res => {
            if (res === PamResult.Success)
                return root.lock.unlockRequested();

            if (res === PamResult.Error)
                root.state = LockPam.Error;
            else if (res === PamResult.MaxTries)
                root.state = LockPam.MaxTries;
            else if (res === PamResult.Failed)
                root.state = LockPam.Failed;

            root.flashMsg();
            pwdStateReset.restart();
        }
    }

    Timer {
        id: pwdStateReset

        interval: 4000
        onTriggered: {
            if (root.state !== LockPam.MaxTries)
                root.state = LockPam.None;
        }
    }

    Connections {
        function onSecureChanged() {
            if (root.lock.secure) {
                root.buffer = "";
                root.state = LockPam.None;
                root.lockMessage = "";
            }
        }

        function onUnlockRequested() {
            passwd.abort();
        }

        target: root.lock
    }
}
