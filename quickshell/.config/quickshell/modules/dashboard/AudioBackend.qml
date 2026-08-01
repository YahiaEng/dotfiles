// AudioBackend.qml — the audio panel's PipeWire adapter (Phase 15 Plan 02,
// PANEL-02/PANEL-06). The single shared reader/writer the audio panel
// (and, later, 15-04's device pickers and per-app mixer) consumes.
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
    // A2 (measured): the output side re-routes an already-playing stream
    // live, not merely future ones. The input side is accepted-and-ignored
    // on this build — the write reaches the binding but has not been shown
    // to move the live default source; ships in the same single-write
    // shape as the output side regardless (15-04's own render gate
    // re-verifies against a real recording app, per the API probe's
    // disposition).
    function setDefaultSink(node) {
        if (node)
            Pipewire.preferredDefaultAudioSink = node;
    }
    function setDefaultSource(node) {
        if (node)
            Pipewire.preferredDefaultAudioSource = node;
    }

    // ── Display-name fallback chain (A1, cross-validated against
    //    Caelestia's shipping Audio.getStreamName()): application.name ->
    //    application.process.binary -> node.name. Never returns an empty
    //    string. ─────────────────────────────────────────────────────────
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

    // ── Tracker feed (A6: mandatory for ready/audio.volume/audio.muted/
    //    properties to be live) — the empty array while the panel is
    //    closed IS the zero-idle mechanism; nothing is tracked while
    //    dismissed. Reactive on Pipewire.nodes.values, defaultSink and
    //    defaultSource so appearing/departing streams are picked up
    //    automatically without a manual refresh. ───────────────────────
    readonly property var trackedNodes: {
        if (!root.panelOpen)
            return [];
        var list = [];
        if (root.defaultSink)
            list.push(root.defaultSink);
        if (root.defaultSource)
            list.push(root.defaultSource);
        for (var i = 0; i < root.streams.length; i++) {
            if (root.streams[i])
                list.push(root.streams[i]);
        }
        return list;
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
