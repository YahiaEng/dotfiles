// MediaBackend.qml — the drawer's single shared reader of the existing
// media backend (Phase 14 Plan 05, DASH-04, D-35).
//
// Root type `Scope` (from `Quickshell`, NOT `Item`) — verified present in
// the installed quickshell-core.qmltypes with `children` as its default
// property, which is what lets the `Process` below be declared as a plain
// child.  `Scope` renders nothing and mounts cleanly under `ShellRoot` with
// no window, unlike an `Item`.
//
// `drawerOpen` (D-32/D-36) is the lifecycle gate every wave-3 backend
// carries: the media watch process below runs only while this is true,
// bound by shell.qml to `dashboardLoader.active` (D-14). Zero idle
// footprint is the tracer's promise (14-01).
//
// D-35's two hard fences:
//   1. The drawer is a THIRD READER of the one existing media backend
//      (media-status.sh/media-players.sh) — never a second one. No MPRIS
//      state is ever re-derived in QML, and the toolkit's own MPRIS
//      service module is never imported here even though it is installed
//      and importable on this machine (14-RESEARCH.md Pitfall 2) — every
//      media read comes from the one streaming reader below, every media
//      write goes through the mutator dispatch below.
//   2. The tab designs to the EXISTING media-status.sh payload contract —
//      no media-status.sh extensions this phase. Neither
//      hypr/.config/hypr/scripts/media-status.sh nor
//      hypr/.config/hypr/scripts/media-players.sh is touched by this file.
//
// D-41 widget-state register — "populated" / "pending" / "empty" — carried
// on every one of this phase's nine modules/dashboard/ files, even the
// non-visual backends, so the vocabulary is uniform across the whole
// module surface.
//
// T-14-01's mitigation lives entirely below: every mutating function
// builds a fixed argv array whose only non-literal elements are the
// resolved script path plus, where the verb needs them, a player id
// (sourced only from this file's own stream/list output, both of which
// media-players.sh already filtered through its own validation before
// ever emitting them) and one numeric argument (clamped and converted to
// a plain decimal string before it is ever placed in an argv element).
// The verb itself is always a double-quoted literal from
// media-players.sh's own allowlist — never computed, never a generic
// passthrough. Nothing here is ever joined into a string or handed to a
// shell interpreter for re-splitting.
import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    // Lifecycle gate (D-32/D-36) — bound by shell.qml to
    // dashboardLoader.active. Starts nothing while false.
    property bool drawerOpen: false

    // ── Two paths, resolved once ────────────────────────────────────────
    readonly property string homeDir: Quickshell.env("HOME")
    readonly property string scriptStatusPath: root.homeDir + "/.config/hypr/scripts/media-status.sh"
    readonly property string scriptPlayersPath: root.homeDir + "/.config/hypr/scripts/media-players.sh"

    // ── The default-safe payload shape — every contract field always
    //    exists at its neutral value, so no consumer ever reads an
    //    undefined member and the empty state is a real value rather than
    //    a null check scattered through the tab. Mirrors
    //    media-status.sh's own `_empty_payload` shape exactly. ───────────
    readonly property var emptyPayload: ({
        player: "", label: "", status: "", title: "", artist: "", album: "",
        art: "", position: 0, length: 0, volume: -1, can_seek: false
    })

    property var payload: root.emptyPayload

    // True the first time any line has ever been successfully parsed on
    // this shell-root instance's whole lifetime (never reset on dismiss —
    // the instance itself persists at the shell root, D-14). This is what
    // lets a re-summon after a prior session render the last-good payload
    // immediately instead of a brief "pending" flash: only the very first
    // ever drawer open, before the first line lands, sees "pending".
    property bool _everReceivedLine: false

    // ── The one streaming reader ─────────────────────────────────────────
    // Nothing else in the drawer may read this stream — the Dashboard
    // tab's compact widget (14-08) reads THIS instance's derived
    // properties, which is exactly why this component is mounted once at
    // the shell root rather than instantiated per tab. The script's
    // reserved third subcommand (a lower-cost position-only poll) is
    // deliberately unused: a second child against the same script is the
    // second backend D-35 forbids, and `watch` already re-emits the whole
    // payload whenever the elapsed seconds change, so the seek slider
    // advances at the script's own one-second cadence for free.
    Process {
        id: mediaWatcher
        running: root.drawerOpen
        command: [root.scriptStatusPath, "watch"]
        stdout: SplitParser {
            onRead: (line) => {
                if (!line || line.trim() === "")
                    return;
                var parsed;
                try {
                    parsed = JSON.parse(line);
                } catch (e) {
                    // A truncated/garbled line is a transient — the
                    // previous payload stays standing, the register is
                    // untouched, and this is the only guarded warning per
                    // rejection (never a spam loop).
                    console.warn("MediaBackend: malformed payload line ignored");
                    return;
                }
                if (typeof parsed !== "object" || parsed === null || Array.isArray(parsed))
                    return;
                root.payload = parsed;
                root._everReceivedLine = true;
            }
        }
    }

    // ── Derived display fields — the surface both media views read ──────
    // Neither view re-derives presentation logic, and 14-08's compact
    // widget inherits the same fallbacks for free.
    readonly property bool hasPlayer: (root.payload.player || "") !== ""

    // Case-insensitive, trimmed compare against the playing value
    // media-status.sh passes through from the player itself.
    readonly property bool playing: (root.payload.status || "").trim().toLowerCase() === "playing"

    // Title falls back to the player's own label, then to nothing — never
    // a raw empty string reaching a text element. The tab decides
    // visibility for artist/album; this file only ever hands back the
    // trimmed value or "".
    readonly property string displayTitle: {
        const t = (root.payload.title || "").trim();
        if (t !== "")
            return t;
        return (root.payload.label || "").trim();
    }
    readonly property string displayArtist: (root.payload.artist || "").trim()
    readonly property string displayAlbum: (root.payload.album || "").trim()

    readonly property string artPath: root.payload.art || ""
    readonly property int positionSeconds: root.payload.position || 0
    readonly property int lengthSeconds: root.payload.length || 0

    // volume: the script's own no-volume sentinel is -1 — this is a
    // capability test, never a zero test (a real player at 0% volume must
    // still show the band).
    readonly property bool hasVolume: root.payload.volume !== -1
    readonly property real volumeLevel: root.hasVolume ? root.payload.volume : 0

    // Seekable requires both the payload's own flag AND a positive length
    // (belt-and-suspenders against a stray true with a zero length).
    readonly property bool canSeek: root.payload.can_seek === true && root.lengthSeconds > 0

    // D-41: "populated" | "pending" | "empty". "pending" is the window
    // between the drawer opening and the first line ever landing on this
    // instance's whole lifetime — once any line has landed, the state is
    // read straight from hasPlayer, including immediately on a re-summon
    // (D-14's warm-data promise: the last-good payload survives a
    // dismissal on this shell-root instance).
    readonly property string widgetState: {
        if (root.drawerOpen && !root._everReceivedLine)
            return "pending";
        return root.hasPlayer ? "populated" : "empty";
    }

    // ── The player list — the switcher chips' data source ───────────────
    // A one-shot child of `media-players.sh list`, not a second stream:
    // one file, one owner, a discrete query rather than a persistent
    // reader. Refreshed on exactly three triggers: the drawer opening, the
    // stream payload's player field changing, and a low-frequency timer —
    // never continuously.
    property var players: []
    property string _lastSeenPlayerId: ""

    // The active id is read straight off the stream payload's own player
    // field — already filtered through media-players.sh's own validation
    // before it was ever emitted — never recomputed here.
    readonly property string activePlayerId: root.payload.player || ""

    Process {
        id: playerListProcess
        running: false
        command: [root.scriptPlayersPath, "list"]
        stdout: StdioCollector {
            id: playerListCollector
        }
        onExited: (exitCode, exitStatus) => {
            var parsed;
            try {
                parsed = JSON.parse(playerListCollector.text);
            } catch (e) {
                root.players = [];
                return;
            }
            root.players = Array.isArray(parsed) ? parsed : [];
        }
    }

    function refreshPlayerList() {
        if (playerListProcess.running)
            return;
        playerListProcess.running = true;
    }

    onDrawerOpenChanged: {
        if (root.drawerOpen)
            root.refreshPlayerList();
    }

    onPayloadChanged: {
        if (root.payload.player !== root._lastSeenPlayerId) {
            root._lastSeenPlayerId = root.payload.player || "";
            root.refreshPlayerList();
        }
    }

    // Data-refresh cadence, deliberately NOT a motion token — a poll
    // cadence riding the motion-scale axis would reach zero at the `off`
    // preset (the same reasoning 14-04's chip watchdogs record). A
    // newly-launched second player changes nothing in the stream payload
    // while the active selection stays put, so without this timer the
    // chip row would go stale in exactly the situation it exists for.
    readonly property int playerListRefreshMs: 5000
    Timer {
        id: playerListRefreshTimer
        interval: root.playerListRefreshMs
        running: root.drawerOpen
        repeat: true
        onTriggered: root.refreshPlayerList()
    }

    // ── The mutator dispatch — T-14-01's mitigation, the security-relevant
    //    part of this file. One function per verb; there is no generic
    //    caller-supplied-verb passthrough, because a passthrough is how an
    //    allowlist stops being an allowlist. ─────────────────────────────
    Process {
        id: mutatorProcess
        running: false
    }

    function _dispatch(argv) {
        mutatorProcess.command = argv;
        mutatorProcess.running = true;
    }

    // Plain non-negative decimal string, never scientific notation, never
    // a negative number — the numeric-argument discipline every seek/
    // volume call below shares.
    function _plainNumber(value, decimals) {
        var v = Number(value);
        if (!isFinite(v) || v < 0)
            v = 0;
        return v.toFixed(decimals);
    }

    // Truth-driven, always (D-22): none of these functions assigns any
    // rendered state. `playing`, `positionSeconds` and `volumeLevel` above
    // are read from the stream and only from the stream, so a command
    // that fails, is refused by the player or is rejected by the mutator
    // leaves the drawer showing what the player is actually doing.
    function playPause() {
        if (!root.hasPlayer)
            return;
        root._dispatch([root.scriptPlayersPath, "cmd", root.payload.player, "play-pause"]);
    }
    function nextTrack() {
        if (!root.hasPlayer)
            return;
        root._dispatch([root.scriptPlayersPath, "cmd", root.payload.player, "next"]);
    }
    function previousTrack() {
        if (!root.hasPlayer)
            return;
        root._dispatch([root.scriptPlayersPath, "cmd", root.payload.player, "previous"]);
    }
    function seekTo(seconds) {
        if (!root.hasPlayer)
            return;
        var clamped = Math.max(0, Math.min(root.lengthSeconds, seconds));
        root._dispatch([root.scriptPlayersPath, "cmd", root.payload.player, "seek", root._plainNumber(clamped, 0)]);
    }
    function setVolume(fraction) {
        if (!root.hasPlayer)
            return;
        var clamped = Math.max(0, Math.min(1, fraction));
        root._dispatch([root.scriptPlayersPath, "cmd", root.payload.player, "volume", root._plainNumber(clamped, 2)]);
    }
    // `playerId` is the one argument this dispatch surface accepts from a
    // caller rather than reading off the stream payload directly — it
    // still only ever originates from an entry of `players` above, itself
    // already filtered through media-players.sh's own validation.
    function selectPlayer(playerId) {
        if (typeof playerId !== "string" || playerId === "")
            return;
        root._dispatch([root.scriptPlayersPath, "select", playerId]);
    }
}
