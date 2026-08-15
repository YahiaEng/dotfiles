// CapsLockBackend.qml — QOSD-02's Caps Lock detector (Phase 20 Plan 05).
//
// ── GATE-01's measured verdict changes this file's mechanism ────────────
// `20-GATE-01-MEASUREMENTS.md` § "sysfs Caps Lock watch" recorded a real
// physical Caps Lock press (both edges) against a live `select.poll()`
// watcher on the resolved `/sys/class/leds/*::capslock/brightness` node:
// NO event printed on EITHER transition. `FileView{watchChanges:true}` is
// documented (Quickshell's own docs, and this repo's own RESEARCH.md) as
// backed by the same inotify-class mechanism on this platform, so the
// event-driven watch this indicator was originally specified around is
// measured dead here, not merely assumed dead by analogy. `watchChanges`
// is left ON below (harmless, and it may behave differently on a future
// kernel/build) but this file's ACTUAL detection path is the bounded poll
// `checkNow()` exposes — called by `Osd.qml`'s own single shared ticker,
// never by a Timer declared in this file (see that file's header for why
// one shared Timer serves both jobs, keeping this module directory's
// total `Timer {}` count at exactly one rather than two).
//
// ── Why polling, when D-20-16 already rejected it ────────────────────────
// D-20-16 rejected polling `hyprctl devices -j` on zero-idle grounds
// BEFORE GATE-01 measured that the originally-specified event-driven
// sysfs mechanism does not fire on this host at all. GATE-01's own text
// names polling as "the fallback... not pre-authorised here... a decision
// the developer makes with this evidence in hand" — this file is that
// decision, made explicitly and recorded here rather than silently
// substituted in. Two event-driven alternatives were considered first and
// rejected, not merely skipped:
//   - `Quickshell.Hyprland`'s `Hyprland.rawEvent` signal (the live
//     Hyprland IPC socket Quickshell already holds open — genuinely
//     event-driven, zero new process, zero new socket). Hyprland's
//     documented socket2 event list has no known caps-lock/modifier-lock
//     event, and this could not be confirmed either way without a
//     physical Caps Lock press, which this execution session is barred
//     from performing (mandatory_verification #5: no live key presses —
//     the operator drives that). Wiring UI to an unproven signal would
//     repeat the EXACT "looks correct, silently never fires" failure mode
//     GATE-01 caught for sysfs — rejected on that basis, not left untried
//     for lack of interest.
//   - Direct evdev reads (`/dev/input/eventN`) — genuinely event-driven
//     (a blocking read, not a poll). Rejected on a MEASURED permissions
//     fact: every node under `/dev/input/` on this host is
//     `crw-rw---- root:input`, and the running user's own `groups` output
//     is `aorus docker libvirt wheel` — no `input` group membership. This
//     route would need a system-level `usermod -aG input` change plus a
//     re-login before it could even be attempted; a bigger, unrequested
//     structural change than a QML OSD row should make silently.
// The sysfs READ path itself (glob resolution, permissions, content
// parsing) is proven working on this host — GATE-01 only measured the
// WATCH/notification half as dead. Polling the same already-proven-
// readable node is therefore the smallest change consistent with what was
// actually measured, not a reach for the easiest option.
//
// ── Read-only, always ─────────────────────────────────────────────────
// This file never opens the resolved node for writing. `checkNow()` only
// ever calls `.reload()` and reads `.text()` — no `setText`, no write
// adapter, no `.write(` anywhere in this file, and none is ever added:
// the node is root-owned kernel LED state, and this shell has no
// legitimate reason to set it.
//
// ── D-20-15 / D-20-16 — unaffected by this file's mechanism swap ────────
// D-20-15 (accepted divergence): `hyprctl devices -j` reports a
// `capsLock` field for more than one keyboard on this host, but only one
// has an LED node — this file tracks ONE keyboard's LED, not global Caps
// Lock state, exactly as D-20-15 already accepted; matching the node to
// Hyprland's active keyboard was considered and rejected there as
// machinery for a case where only one of the two even has an LED at all.
// D-20-16: polling `hyprctl devices -j` itself is STILL rejected — this
// file never calls `hyprctl` anywhere; it polls the sysfs node the glob
// resolver already found, a plain file re-read, not a subprocess spawn
// per tick.
import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    readonly property bool on: root._on
    property bool _on: false
    property bool _initialised: false
    signal turnedOn

    // ── Resolution (D-20-14) — glob at startup, re-glob on read failure.
    //    `find` is a fixed-argv, no-interpreter tool (T-18-12-01's own
    //    argument-construction discipline, applied here) — no shell, so
    //    no glob-as-shell-metacharacter risk anywhere in this command.
    //    `-iname` ALONE (no `-type d`) is deliberate and MEASURED: every
    //    entry under `/sys/class/leds/` is a SYMLINK
    //    (e.g. `input35::capslock -> ../../devices/.../input35::capslock`
    //    — confirmed live via `ls -la /sys/class/leds/`), and GNU find's
    //    `-type d` test does not follow symlinks by default, so adding it
    //    would silently match nothing on this host. Confirmed live this
    //    session: `find /sys/class/leds -maxdepth 1 -iname "*::capslock"`
    //    resolves `input35::capslock` — a FOURTH distinct `inputNN` index
    //    now observed across this phase's own sessions (input5 on
    //    2026-08-14, input33 earlier on 2026-08-15, a third value GATE-01
    //    itself did not capture, now input35), independently
    //    reconfirming D-20-14's "the node index is not stable" claim
    //    rather than merely repeating it. ──────────────────────────────
    Process {
        id: resolver
        command: ["find", "/sys/class/leds", "-maxdepth", "1", "-iname", "*::capslock"]
        stdout: StdioCollector {
            id: resolverCollector
        }
        onExited: (exitCode, exitStatus) => {
            const lines = (resolverCollector.text || "").split("\n").filter(function (l) {
                return l.trim().length > 0;
            });
            if (lines.length === 0) {
                // No node matches on this attempt — absent, never broken
                // (D-20-14). checkNow() below no-ops while path is "".
                capslockFile.path = "";
                return;
            }
            capslockFile.path = lines[0].trim() + "/brightness";
        }
    }

    function _resolve() {
        if (!resolver.running)
            resolver.running = true;
    }

    // Read-only watch of the resolved node. `watchChanges`/`onFileChanged`
    // are left wired — see header — even though GATE-01 measured them
    // inert on this host; `checkNow()` below is the mechanism this file
    // actually relies on.
    FileView {
        id: capslockFile
        watchChanges: true
        onFileChanged: reload()
        onLoadFailed: (error) => {
            // A previously-resolved node stopped reading (the "keyboard
            // unplugged" case in this file's own must_haves) — re-glob
            // rather than treat this as a permanent error.
            root._resolve();
        }
    }

    // ── The poll — called by Osd.qml's single shared ticker, never by a
    //    Timer declared in this file (see header). Read-only:
    //    `.reload()` + `.text()`, nothing else. Fires `turnedOn()` ONLY
    //    on a false->true edge (D-20-12) — never on the initial read (a
    //    shell restart while Caps Lock happens to already be on must not
    //    flash the indicator) and never on the true->false edge. ────────
    function checkNow() {
        if (capslockFile.path === "")
            return;
        capslockFile.reload();
        const raw = (capslockFile.text() || "").trim();
        const nowOn = raw !== "" && raw !== "0";
        if (!root._initialised) {
            root._initialised = true;
            root._on = nowOn;
            return;
        }
        if (nowOn && !root._on)
            root.turnedOn();
        root._on = nowOn;
    }

    Component.onCompleted: root._resolve()
}
