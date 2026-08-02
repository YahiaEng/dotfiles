// AudioBackend.qml — the audio panel's PipeWire adapter (Phase 15 Plans 02
// and 04, PANEL-01/PANEL-02/PANEL-06). The single shared reader/writer the
// audio panel consumes. 15-04 completed this file: node-id-ordered
// `streamNodes`, per-stream/per-device writers, label/icon fallbacks,
// device-presence predicates, and the device-switch pending/failed model —
// every value the panel renders and every write it performs has exactly
// one named home here; the panel never touches a raw PipeWire node.
//
// Root type `Scope` (from `Quickshell`, NOT `Item`) — mirrors
// `MediaBackend.qml`'s own header rationale exactly: it renders nothing and
// mounts cleanly under `ShellRoot`, unlike an `Item`.
//
// Every read and write in this file goes through the native
// `Quickshell.Services.Pipewire` members; no subprocess appears anywhere in
// the audio read or write path (Prohibition P1 in 15-02-PLAN.md's
// must_haves), and nothing here ever invokes an OSD client — SwayOSD stays
// the sole OSD producer, triggered only by hardware keys (D-15-24).
//
// ── 15-API-PROBE.md A3/A6/PwNodeType corrections, binding on this file ───
// `Pipewire.nodes` is an `UntypedObjectModel`: no `.count`, no `.get(i)`.
// `.values` is the correct accessor for JS-side iteration (array-like:
// `.length`, index access, `.map`/`.filter`, but `Array.isArray()` is
// false). A node's `ready`, `audio.volume`/`audio.muted` and `properties`
// are all inert placeholders until that node sits inside a
// `PwObjectTracker.objects` list (A6, measured) — `trackedNodes` below
// feeds exactly one tracker, reactive on `Pipewire.nodes.values` so streams
// appearing/departing after mount are tracked/dropped automatically.
// `PwNodeType` flag members are pre-combined composites sharing bits
// (`AudioOutStream`/`AudioInStream` both carry the `Audio`/`Stream` bits) —
// a bitwise-AND membership test produces false positives; every node-type
// filter below uses exact equality against the composite constant.
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire

Scope {
    id: root

    // ── Lifecycle gate — bound by shell.qml to audioPanelLoader.active.
    //    Nothing is tracked while the panel is closed (zero-idle). ───────
    property bool panelOpen: false

    readonly property bool pipewireReady: Pipewire.ready
    readonly property var defaultSink: Pipewire.defaultAudioSink
    readonly property var defaultSource: Pipewire.defaultAudioSource

    // ── Filtered node lists — exact-equality PwNodeType matching (A3's
    //    corrective finding). `.values` is the UntypedObjectModel accessor;
    //    reactive because `Pipewire.nodes.values` re-evaluates live as the
    //    registry changes (A3, proven two ways). ──────────────────────────
    readonly property var sinks: Pipewire.nodes.values.filter(function (n) {
        return n && n.type === PwNodeType.AudioSink;
    })
    readonly property var sources: Pipewire.nodes.values.filter(function (n) {
        return n && n.type === PwNodeType.AudioSource;
    })
    readonly property var streams: Pipewire.nodes.values.filter(function (n) {
        return n && n.type === PwNodeType.AudioOutStream;
    })

    // ── Master volume/mute — null-guarded through defaultSink/defaultSink.
    //    audio (PwNodeAudio exposes volume as a read/write average and
    //    muted as a read/write bool), falling back to 0/false. ────────────
    readonly property real masterVolume: (root.defaultSink && root.defaultSink.audio) ? root.defaultSink.audio.volume : 0
    readonly property bool masterMuted: (root.defaultSink && root.defaultSink.audio) ? root.defaultSink.audio.muted : false
    readonly property real inputVolume: (root.defaultSource && root.defaultSource.audio) ? root.defaultSource.audio.volume : 0
    readonly property bool inputMuted: (root.defaultSource && root.defaultSource.audio) ? root.defaultSource.audio.muted : false

    // ── Writers — the noted addition keeping D-22 (truth-driven, never a
    //    local optimistic copy) intact: the panel never mutates a raw
    //    PipeWire node directly, every write goes through one of these. ──
    function setMasterVolume(v) {
        if (root.defaultSink && root.defaultSink.audio)
            root.defaultSink.audio.volume = v;
    }
    function setMasterMuted(on) {
        if (root.defaultSink && root.defaultSink.audio)
            root.defaultSink.audio.muted = on;
    }
    function setInputVolume(v) {
        if (root.defaultSource && root.defaultSource.audio)
            root.defaultSource.audio.volume = v;
    }
    function setInputMuted(on) {
        if (root.defaultSource && root.defaultSource.audio)
            root.defaultSource.audio.muted = on;
    }
    // ── A2 disposition (15-01's blocking `checkpoint:decision`, carried
    //    here verbatim, NOT re-decided by this plan). The human selected a
    //    THIRD disposition at that checkpoint — neither of the plan's two
    //    pre-written options — a bounded re-probe of the input-side gap,
    //    then accept-and-document PER SIDE:
    //
    //    OUTPUT: `preferredDefaultAudioSink` re-routes an ALREADY-PLAYING
    //    stream live, not merely future ones (15-API-PROBE.md's A2,
    //    measured against a real second sink with a continuous stream
    //    held open). Ships as a single property write with NO residual to
    //    disclose — this is the stronger, non-pessimistic reading.
    //
    //    INPUT: `preferredDefaultAudioSource` was measured
    //    accepted-and-ignored on this build — the bounded re-probe (which
    //    read `Pipewire.preferredDefaultAudioSource` itself back after the
    //    write, not just the read-only `defaultAudioSource`) confirmed the
    //    write reaches the QML binding but has not been shown to move a
    //    live capture within the observation window. Option (b) — a
    //    `PwNodeLinkTracker`/`PwLinkGroup` per-stream re-route function —
    //    was EXPLICITLY REJECTED at 15-01: it is the standard remedy for a
    //    "new streams only" gap, and this is not that; there was no
    //    evidence link-tracking was the actual remedy. Ships as the same
    //    single-write shape as the output side, with the residual named
    //    to the user via `streamRouteNote` below — rendered under the
    //    INPUT picker in AudioPanel.qml, not the output one, because the
    //    measured limitation is on the input side only (a placement
    //    divergence from this plan's own generic template text, recorded
    //    in the SUMMARY). 15-04's own render gate re-verifies this against
    //    a real recording app, per the probe's own disposition.
    function setDefaultSink(node) {
        if (!node)
            return;
        root.failedDevice = "";
        root._pendingSinkNode = node;
        root.pendingDevice = "output";
        deviceSwitchWatchdog.restart();
        Pipewire.preferredDefaultAudioSink = node;
    }
    function setDefaultSource(node) {
        if (!node)
            return;
        root.failedDevice = "";
        root._pendingSourceNode = node;
        root.pendingDevice = "input";
        deviceSwitchWatchdog.restart();
        Pipewire.preferredDefaultAudioSource = node;
    }

    // Branch (a), accept-and-document, shipped — see the disposition
    // comment above. The explicit per-stream re-route function branch (b)
    // was rejected at 15-01 and is absent from this file by design: the
    // limitation it would resolve does not exist on the output side, and
    // was explicitly rejected as the input side's remedy.
    readonly property string streamRouteNote: "Selecting a different microphone may not move audio you're already recording — start a new recording to be sure it picked up."

    // ── Device-switch pending/failed model (D-22's pending model, E2
    //    `error` backstop, D-15-09's row-scoping applied to a non-list
    //    control). Values: "" | "output" | "input" — the picker row that
    //    requested the switch, never a panel-wide flag. `interval:` (never
    //    `duration:`) keeps the watchdog outside motion-lint CHECK B's
    //    reach and off the motion-scale axis — a timeout riding that axis
    //    would collapse to zero at the lowest motion preset and fail a
    //    switch that was merely slow. 3s matches QuickToggles.qml's own
    //    established chip timeout (chipTimeoutMs). ─────────────────────
    property string pendingDevice: ""
    property string failedDevice: ""
    readonly property int deviceSwitchTimeoutMs: 3000
    property var _pendingSinkNode: null
    property var _pendingSourceNode: null

    Timer {
        id: deviceSwitchWatchdog
        interval: root.deviceSwitchTimeoutMs
        repeat: false
        onTriggered: {
            root.failedDevice = root.pendingDevice;
            root.pendingDevice = "";
        }
    }

    // Pending is cleared by OBSERVED TRUTH — the backend's real default
    // becoming the node that was actually requested — never by the write
    // call returning. A switch that never lands therefore surfaces as
    // `failedDevice` on the requesting picker row alone, via the watchdog
    // above, and nowhere else.
    onDefaultSinkChanged: {
        if (root.pendingDevice === "output" && root.defaultSink === root._pendingSinkNode) {
            root.pendingDevice = "";
            root._pendingSinkNode = null;
            deviceSwitchWatchdog.stop();
        }
    }
    onDefaultSourceChanged: {
        if (root.pendingDevice === "input" && root.defaultSource === root._pendingSourceNode) {
            root.pendingDevice = "";
            root._pendingSourceNode = null;
            deviceSwitchWatchdog.stop();
        }
    }

    // A picker row's next press clears its own stale failure before trying
    // again — never cleared implicitly by a second unrelated write.
    function clearDeviceFailure() {
        root.failedDevice = "";
    }

    // ── Display-name fallback chain (A1, cross-validated against
    //    Caelestia's shipping Audio.getStreamName()): application.name ->
    //    application.process.binary -> node.name. Never returns an empty
    //    string — 15-API-PROBE.md's A1(a) measured `node.name` as always
    //    present and non-empty on every observed node, so it is a real
    //    terminal fallback, not merely a hopeful one. `nickname`/
    //    `description` are deliberately NOT in this chain — A1(a) measured
    //    them as populated on device (sink/source) nodes but empty string
    //    (not undefined) on every observed STREAM node; they are
    //    `deviceLabel`'s fallback chain below, not this one — a corrective
    //    distinction the probe itself calls out. ─────────────────────────
    function streamLabel(node) {
        if (!node)
            return "";
        var props = node.properties || {};
        if (props["application.name"] && props["application.name"].length > 0)
            return props["application.name"];
        if (props["application.process.binary"] && props["application.process.binary"].length > 0)
            return props["application.process.binary"];
        return node.name || "";
    }

    // ── E1 `partial` backstop, icon half. 15-API-PROBE.md's A1(b) measured
    //    `application.icon-name` as undefined on EVERY observed node (both
    //    stream nodes, the sink, the source) — there is no live candidate
    //    on this build at all, so the generic fallback is the icon for
    //    every row unconditionally, not a last-resort. The icon-name key
    //    is still read first in case a future build populates it; the
    //    fallback glyph reads as "an application making sound" rather than
    //    an app-specific icon. Never returns an empty string. ────────────
    function streamIcon(node) {
        if (!node)
            return "volume_up";
        var props = node.properties || {};
        if (props["application.icon-name"] && props["application.icon-name"].length > 0)
            return props["application.icon-name"];
        return "volume_up";
    }

    // ── Device-picker label fallback chain — deliberately a SEPARATE
    //    function from streamLabel rather than a mode flag: A1(a) measured
    //    the two chains as genuinely different (nickname/description are
    //    stream-empty but device-populated), and one function pretending
    //    otherwise would hide that from the next reader. Null-guarded,
    //    never returns an empty string when a node is supplied. ──────────
    function deviceLabel(node) {
        if (!node)
            return "";
        if (node.nickname && node.nickname.length > 0)
            return node.nickname;
        if (node.description && node.description.length > 0)
            return node.description;
        return node.name || "";
    }

    // ── Node identity and stream ordering (PANEL-01's adjacency + ordering
    //    truths). Accessor: the typed `PwNodeIface.id` property (`uint`,
    //    `isReadonly: true`, `isPropertyConstant: true`) — 15-API-PROBE.md's
    //    A1(c) names this as the ONLY guaranteed-unique per-stream identity
    //    ("the node id property name is `id`"), not the untyped
    //    `object.id` properties-map entry. Sorted by NUMERIC comparison,
    //    never lexicographic — a string sort reorders as soon as a node id
    //    crosses a digit boundary (e.g. "9" > "10" as strings), which is
    //    exactly the row-reordering the ordering truth forbids. `streams`
    //    itself stays untouched — the raw filtered list 15-02 shipped —
    //    so the ordering has exactly one named home. ───────────────────
    readonly property var streamNodes: root.streams.slice().sort(function (a, b) {
        return a.id - b.id;
    })

    // Row identity for delegates — the node id, never the application name.
    // Two concurrent streams from one application are two nodes and must
    // render as two independently-mutable rows.
    function streamNodeKey(node) {
        return node ? node.id : -1;
    }

    // ── Per-stream writers — mirror the master writers exactly (D-22): the
    //    panel calls a named function, never assigns into a node, and the
    //    rendered value is always a fresh read of backend truth. Volume is
    //    clamped into [0, 1] so a slider overshoot during a drag cannot
    //    push a node outside the range PipeWire accepts. ─────────────────
    function setStreamVolume(node, v) {
        if (!node || !node.audio)
            return;
        node.audio.volume = Math.max(0, Math.min(1, v));
    }
    function setStreamMuted(node, on) {
        if (!node || !node.audio)
            return;
        node.audio.muted = on;
    }

    // ── Device presence predicates — single named producers for the E2
    //    `empty` backstop (no output device at all) and the E2 `partial`
    //    truth (no input device, mic controls absent not inert), rather
    //    than a length check repeated at every call site. ────────────────
    readonly property bool outputsPresent: root.sinks.length > 0
    readonly property bool inputsPresent: root.sources.length > 0

    // ── Tracker feed (A6: mandatory for ready/audio.volume/audio.muted/
    //    properties to be live) — the empty array while the panel is
    //    closed IS the zero-idle mechanism; nothing is tracked while
    //    dismissed. Reactive on Pipewire.nodes.values so appearing/
    //    departing nodes are picked up automatically without a manual
    //    refresh. Widened this plan from "default sink/source + streams"
    //    to "every sink/source/stream": the device pickers' expanded
    //    candidate list needs every device's `nickname`/`description`/
    //    `audio` state live, not only the current default's — the default
    //    sink/source are already members of `sinks`/`sources` (both
    //    filtered by exact-equality PwNodeType), so no separate default
    //    entry is pushed to avoid tracking the same node object twice. ──
    readonly property var trackedNodes: {
        if (!root.panelOpen)
            return [];
        return root.sinks.concat(root.sources).concat(root.streams);
    }

    PwObjectTracker {
        objects: root.trackedNodes
    }

    // ── D-15-22 availability probe — a fully literal fixed argv, zero
    //    interpolated elements, started once. Fail OPEN (matching
    //    shell.qml's own recorded fullscreenBlocking precedent): if the
    //    probe cannot run at all, leave advancedAvailable true, because a
    //    false "not installed" would hide a working button. ─────────────
    property bool advancedAvailable: true

    Process {
        id: pavucontrolProbe
        command: ["which", "pavucontrol"]
        onExited: function (exitCode, exitStatus) {
            if (exitCode !== 0)
                root.advancedAvailable = false;
        }
    }

    Component.onCompleted: pavucontrolProbe.running = true
}
