// MediaBackend.qml — the drawer's single shared reader of media state
// (originally Phase 14 Plan 05, DASH-04, D-35; repointed by Phase 18 Plan
// 08, D-18-05).
//
// ── D-18-05 repoints this file onto Quickshell.Services.Mpris, the
//    toolkit's own native MPRIS singleton, and SUPERSEDES the D-35 fence
//    this header used to carry ("the toolkit's own MPRIS service module is
//    never imported here even though it is installed and importable").
//    That prohibition is lifted by this later decision — the import below
//    is not an accident and not a violation, it is what D-18-05 asks for.
//    (a) What supersedes what: D-18-05 supersedes D-35's import fence.
//        D-35's OTHER half — the tab designs to a fixed contract shape and
//        no consumer re-derives MPRIS state itself — still holds, and
//        still holds structurally: this remains the ONE place in the repo
//        that reads player state, and every field below still flows
//        through named, typed properties rather than a raw player object
//        reaching a view.
//    (b) What changes observably: player-state transitions now arrive as
//        Qt property-change notifications straight off the native D-Bus
//        binding rather than on the next tick of a 1Hz shell-script
//        reader — play/pause, track change and player appearance/
//        disappearance are reflected within one event loop turn instead of
//        within up to one second. With zero players running, this file now
//        starts no process at all, rather than a reader that polled and
//        reported nothing every second. The previous reader's per-tick
//        subprocess fan-out — roughly ten forks a second while the drawer
//        was open — is gone entirely; the one subprocess that remains
//        (below) is a single-flighted, event-triggered album-art resolve,
//        not a poll.
//    (c) This file remains a READ-ONLY consumer of player state. No MPRIS
//        state is re-derived or cached beyond what the singleton already
//        exposes — `players`/`activePlayer` below are pure projections of
//        `Mpris.players`, recomputed from it, never a second source of
//        truth drifting alongside it.
//    (d) `drawerOpen` is retained by name and still gates the one timer
//        this file keeps (the position-refresh heartbeat below), but 18-05
//        widened what `shell.qml` binds to it (now also
//        `barInstance.requiresMedia`, true from 18-05 onward since the
//        bar's entry list is complete) — so in practice this property is
//        now almost always true. That is this plan's own named always-on
//        charge, measured in `18-BAR-LIVENESS-CHARGE.md`, not an
//        oversight, and the position timer only actually runs while a
//        track is both playing and seekable on top of that.
//
// ── T-14-01's mutator-dispatch discipline, restated for the new dispatch
//    surface. Transport control is now a direct method call on the active
//    `MprisPlayer` object (`togglePlaying()`/`next()`/`previous()`) or a
//    direct, clamped property write (`position =`/`volume =`) rather than
//    an argv handed to a subprocess — the injection surface T-14-01
//    described (a caller-supplied verb reaching a shell) is REDUCED, not
//    merely restated: there is no argv left in this file's mutator path at
//    all. The one remaining subprocess (the album-art resolver) still
//    follows the fixed-argv, no-shell discipline the header used to state
//    for the whole file — see the "Album art" section below.
//
// ── D-41 widget-state register — "populated" | "pending" | "empty" —
//    carried on every one of this phase's modules/dashboard/ files, even
//    the non-visual backends, so the vocabulary is uniform across the
//    whole module surface. "pending" is retained by name here but is now
//    STRUCTURALLY UNREACHABLE: the native singleton is populated at first
//    paint (there is no asynchronous first-line window the old streaming
//    reader had), so this file only ever resolves to "populated" or
//    "empty". The name stays because a switch elsewhere in this repo may
//    compile against all three, not because this file can still produce
//    the middle one.
//
// Root type `Scope` (from `Quickshell`, NOT `Item`) — renders nothing and
// mounts cleanly under `ShellRoot` with no window, unlike an `Item`; kept
// unchanged from the original file.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

Scope {
    id: root

    // Lifecycle gate — bound by shell.qml to
    // dashboardLoader.active || barInstance.requiresMedia (18-05). Gates
    // only the position-refresh Timer below; every other read here is a
    // plain reactive binding over the always-present Mpris singleton.
    property bool drawerOpen: false

    // ── Identity ─────────────────────────────────────────────────────────
    // A player's `identity` is a human-readable display name and is NOT
    // guaranteed unique across two instances of the same app — `uniqueId`
    // (falling back to `dbusName` if a build ever leaves it empty) is the
    // stable key every selection, switcher-row and active-player lookup
    // below is keyed on instead.
    function _playerIdentity(p) {
        if (!p)
            return "";
        return (p.uniqueId && p.uniqueId !== "") ? p.uniqueId : (p.dbusName || "");
    }

    // ── Active player selection ─────────────────────────────────────────
    // Resolution order, stated here rather than left implicit: (1) the
    // explicitly selected player, if it is still present in the model;
    // (2) the first player reporting isPlaying; (3) the first player in
    // the model; (4) null. No sort runs anywhere in this file — the
    // model's own order is used as-is, so two equally-eligible players
    // cannot swap between reads. A selection whose player has vanished
    // falls back through this same rule automatically: `_explicitSelectionId`
    // simply stops matching anything in the model, it is never explicitly
    // cleared.
    property string _explicitSelectionId: ""

    readonly property var activePlayer: {
        const list = Mpris.players ? Mpris.players.values : [];
        if (root._explicitSelectionId !== "") {
            for (var i = 0; i < list.length; i++) {
                if (list[i] && root._playerIdentity(list[i]) === root._explicitSelectionId)
                    return list[i];
            }
        }
        for (var j = 0; j < list.length; j++) {
            if (list[j] && list[j].isPlaying === true)
                return list[j];
        }
        return list.length > 0 ? list[0] : null;
    }

    readonly property string activePlayerId: root._playerIdentity(root.activePlayer)

    // `playerId` is the one argument this surface accepts from a caller
    // rather than reading straight off the active-player resolution above —
    // it is checked against the live model before being accepted, and an
    // unknown id is a no-op rather than a blind write.
    function selectPlayer(playerId) {
        if (typeof playerId !== "string" || playerId === "")
            return;
        const list = Mpris.players ? Mpris.players.values : [];
        for (var i = 0; i < list.length; i++) {
            if (list[i] && root._playerIdentity(list[i]) === playerId) {
                root._explicitSelectionId = playerId;
                return;
            }
        }
    }

    // ── The switcher's data source — same element shape MediaTab.qml's
    //    switcher already consumes ({ id, label, active }), read from that
    //    consumer first and matched here rather than exposing raw player
    //    objects and expecting the tab to adapt. ────────────────────────
    readonly property var players: {
        const list = Mpris.players ? Mpris.players.values : [];
        var out = [];
        for (var i = 0; i < list.length; i++) {
            const p = list[i];
            if (!p)
                continue;
            const pid = root._playerIdentity(p);
            out.push({
                id: pid,
                label: (p.identity && p.identity !== "") ? p.identity : pid,
                active: p === root.activePlayer
            });
        }
        return out;
    }

    // ── Derived display fields — the surface both media views read.
    //    Neither view re-derives presentation logic. ───────────────────
    readonly property bool hasPlayer: root.activePlayer !== null

    readonly property bool playing: root.hasPlayer && root.activePlayer.isPlaying === true

    // Title falls back to the player's own identity, then to nothing —
    // never a raw empty string reaching a text element. Preserves the
    // previous fallback-to-label behaviour precisely.
    readonly property string displayTitle: {
        if (!root.hasPlayer)
            return "";
        const t = (root.activePlayer.trackTitle || "").trim();
        if (t !== "")
            return t;
        return (root.activePlayer.identity || "").trim();
    }
    readonly property string displayArtist: root.hasPlayer ? (root.activePlayer.trackArtist || "").trim() : ""
    readonly property string displayAlbum: root.hasPlayer ? (root.activePlayer.trackAlbum || "").trim() : ""

    // Guarded against the unsupported case, where the raw value is
    // meaningless, by reporting zero rather than a stale or NaN figure.
    readonly property int lengthSeconds: {
        if (!root.hasPlayer || root.activePlayer.lengthSupported !== true)
            return 0;
        const l = root.activePlayer.length;
        return (isFinite(l) && l > 0) ? Math.floor(l) : 0;
    }

    // The native flag is a direct capability test, never a zero test — a
    // real player at zero volume must still show the band, exactly as the
    // previous script-sentinel implementation guaranteed.
    readonly property bool hasVolume: root.hasPlayer && root.activePlayer.volumeSupported === true
    readonly property real volumeLevel: root.hasVolume ? root.activePlayer.volume : 0

    // Belt-and-suspenders guard kept from the previous implementation: the
    // player's own seek capability AND a positive length.
    readonly property bool canSeek: root.hasPlayer && root.activePlayer.canSeek === true && root.lengthSeconds > 0

    // D-41: "populated" | "pending" | "empty" — see the file header for why
    // "pending" is retained by name but is now structurally unreachable
    // from this file; the native singleton has no asynchronous first-line
    // window to be pending in.
    readonly property string widgetState: {
        if (!root.hasPlayer)
            return "empty";
        return "populated";
    }

    // ── Position — a Timer-forced heartbeat, not a bare property binding.
    //    `position` carries a Qt change notification (`positionChanged`),
    //    but MPRIS does not obligate a player to emit it every second
    //    during ordinary playback — the spec's own model expects a client
    //    to interpolate, and this session could not live-verify against a
    //    real playing track whether a plain binding already advances (see
    //    SUMMARY for the recorded gap). A one-second heartbeat that reads
    //    `activePlayer.position` fresh on every tick is the conservative
    //    choice: gated on `drawerOpen && playing && canSeek`, in-process,
    //    no fork — it replaces a reader that forked roughly ten processes
    //    a second, and it is the ONLY remaining timer in this file. ──────
    property int _positionTick: 0

    Timer {
        id: positionRefreshTimer
        interval: 1000
        repeat: true
        running: root.drawerOpen && root.playing && root.canSeek
        onTriggered: root._positionTick = root._positionTick + 1
    }

    readonly property int positionSeconds: {
        const _tick = root._positionTick; // dependency: forces re-evaluation every heartbeat
        return root.hasPlayer ? Math.max(0, Math.floor(root.activePlayer.position)) : 0;
    }

    // ── Album art — the breakable link. `artPath` MUST remain a bare
    //    local filesystem path: MediaTab.qml:613 prefixes it with a
    //    "file://" scheme itself, so a URL-valued artPath here would
    //    produce a doubled scheme and a silently blank art circle. ───────
    readonly property string homeDir: Quickshell.env("HOME")
    readonly property string artResolverPath: root.homeDir + "/.config/hypr/scripts/media-art-resolve.sh"

    // Percent-decodes a file:// URL's path component. No subprocess is
    // needed for this branch, which is the common one.
    function _decodeFileUrl(url) {
        const raw = url.substring("file://".length);
        try {
            return decodeURIComponent(raw);
        } catch (e) {
            return raw;
        }
    }

    // The last-write-wins key: only a resolve whose recorded request URL
    // still equals the CURRENT track's art URL is ever published. A
    // resolve that returns for a track the user has already skipped past
    // is discarded here, not upstream — the process itself is not killed,
    // its result is simply never read into `_resolvedArtPath` consumption.
    property string _artResolveRequestUrl: ""
    property string _resolvedArtPath: ""

    readonly property string artPath: {
        const url = root.hasPlayer ? (root.activePlayer.trackArtUrl || "") : "";
        if (url === "")
            return "";
        if (url.indexOf("file://") === 0)
            return root._decodeFileUrl(url);
        return (root._artResolveRequestUrl === url) ? root._resolvedArtPath : "";
    }

    // Single-flighted: a track change while a resolve is already in flight
    // does not spawn a second child — it is picked up by the chase in
    // `onExited` below once the in-flight one finishes.
    function _triggerArtResolve() {
        if (artResolveProcess.running)
            return;
        const url = root.hasPlayer ? (root.activePlayer.trackArtUrl || "") : "";
        if (url === "" || url.indexOf("file://") === 0)
            return;
        if (url === root._artResolveRequestUrl && root._resolvedArtPath !== "")
            return;
        root._artResolveRequestUrl = url;
        artResolveProcess.command = [root.artResolverPath, url];
        artResolveProcess.running = true;
    }

    // The URL is handed to the resolver unmodified, as a single argv
    // element — never fetched in-process, never re-parsed as code, never
    // concatenated into a command line. The resolver's own scheme
    // allowlist and its pre-flight rejection of loopback and RFC1918
    // hosts are the mitigation for a request-forgery sink pointed at this
    // machine, and re-implementing the fetch here would discard both.
    Process {
        id: artResolveProcess
        running: false
        stdout: StdioCollector {
            id: artResolveCollector
        }
        onExited: (exitCode, exitStatus) => {
            root._resolvedArtPath = (exitCode === 0) ? (artResolveCollector.text || "").trim() : "";
            // Chase a track that moved on while this resolve was in
            // flight — single-flighted (this process just cleared
            // `running`), never queued, never a second concurrent child.
            if (root.hasPlayer) {
                const currentUrl = root.activePlayer.trackArtUrl || "";
                if (currentUrl !== "" && currentUrl.indexOf("file://") !== 0 && currentUrl !== root._artResolveRequestUrl)
                    root._triggerArtResolve();
            }
        }
    }

    onActivePlayerChanged: root._triggerArtResolve()

    Connections {
        target: root.activePlayer
        function onTrackArtUrlChanged() {
            root._triggerArtResolve();
        }
    }

    Component.onCompleted: root._triggerArtResolve()

    // ── Transport and volume — direct method calls / clamped property
    //    writes on the active player, each guarded on there being an
    //    active player AND on the corresponding capability flag, so this
    //    file never asks a player to do something it has declared it
    //    cannot. One function per verb; no generic caller-supplied-verb
    //    passthrough — the reason the old header gave still applies: a
    //    passthrough is how an allowlist stops being an allowlist. ───────
    function playPause() {
        if (!root.hasPlayer || root.activePlayer.canTogglePlaying !== true)
            return;
        root.activePlayer.togglePlaying();
    }
    function nextTrack() {
        if (!root.hasPlayer || root.activePlayer.canGoNext !== true)
            return;
        root.activePlayer.next();
    }
    function previousTrack() {
        if (!root.hasPlayer || root.activePlayer.canGoPrevious !== true)
            return;
        root.activePlayer.previous();
    }
    // Absolute seek via the position property's own writer (`position =`
    // calls the native setPosition), never the relative `seek(offset)`
    // method — MediaTab's slider hands this an absolute second count.
    function seekTo(seconds) {
        if (!root.hasPlayer || root.activePlayer.canSeek !== true)
            return;
        const clamped = Math.max(0, Math.min(root.lengthSeconds, Number(seconds) || 0));
        root.activePlayer.position = clamped;
    }
    function setVolume(fraction) {
        if (!root.hasPlayer || root.activePlayer.volumeSupported !== true)
            return;
        const clamped = Math.max(0, Math.min(1, Number(fraction) || 0));
        root.activePlayer.volume = clamped;
    }
}
