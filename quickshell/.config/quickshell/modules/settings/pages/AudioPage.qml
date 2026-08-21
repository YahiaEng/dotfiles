// modules/settings/pages/AudioPage.qml — page index 3 of the ten-page
// layout (quick-260821-6z1 Task 13, D-01 bundle 4). The real inline
// mixer: composition over the shell's single `AudioBackend` instance,
// threaded through `SettingsState.audioBackend` (Settings.qml relays it
// from shell.qml's own `audioBackendInstance`, the SAME instance the
// audio panel, dashboard and OSD already share — never a second
// instance). `AudioPanel.qml` is not touched at all; its own NavRow here
// still summons it via the existing `sState.panelRequested("audio")`
// relay for the full, unbounded per-app list at a glance.
//
// Device selection passes the real node OBJECT through, never an id: the
// SelectRow model's own `value` field is the node's stable `name`
// (AudioBackend.qml's own always-populated fallback field, not the
// human-readable `deviceLabel()` string), and `onSelected` looks the
// CURRENT node back up by that name before calling
// `setDefaultSink`/`setDefaultSource` — never a cached/stale reference,
// and never the class of id-round-trip bug this repo has already been
// bitten by in a media control (MprisPlayer.uniqueId not round-tripping
// cleanly through a display string).
import QtQuick
import ".."
import "../common"
import "../../"
import "../../dashboard"

PageBase {
    id: root

    readonly property var audioBackend: root.sState.audioBackend

    title: "Audio"

    function _findSinkByName(name) {
        if (!root.audioBackend)
            return null;
        var sinks = root.audioBackend.sinks;
        for (var i = 0; i < sinks.length; i++) {
            if (sinks[i].name === name)
                return sinks[i];
        }
        return null;
    }
    function _findSourceByName(name) {
        if (!root.audioBackend)
            return null;
        var sources = root.audioBackend.sources;
        for (var i = 0; i < sources.length; i++) {
            if (sources[i].name === name)
                return sources[i];
        }
        return null;
    }

    SettingsSection {
        title: "Output"
        icon: "volume_up"

        SliderRow {
            label: "Master volume"
            subtext: "Default output device"
            from: 0; to: 1; stepSize: 0.01
            value: root.audioBackend ? root.audioBackend.masterVolume : 0
            enabled: root.audioBackend !== null
            onMoved: (v) => root.audioBackend && root.audioBackend.setMasterVolume(v)
        }
        ToggleRow {
            label: "Mute"
            subtext: "Mute the default output device"
            checked: root.audioBackend ? root.audioBackend.masterMuted : false
            enabled: root.audioBackend !== null
            onToggled: (value) => root.audioBackend && root.audioBackend.setMasterMuted(value)
        }
        SelectRow {
            label: "Output device"
            subtext: "Default audio output"
            model: root.audioBackend ? root.audioBackend.sinks.map(function (n) {
                return { value: n.name, display: root.audioBackend.deviceLabel(n) };
            }) : []
            currentValue: (root.audioBackend && root.audioBackend.defaultSink) ? root.audioBackend.defaultSink.name : ""
            busy: root.audioBackend && root.audioBackend.pendingDevice === "output"
            onSelected: (value) => {
                var node = root._findSinkByName(value);
                if (node && root.audioBackend)
                    root.audioBackend.setDefaultSink(node);
            }
        }
        InfoRow {
            visible: root.audioBackend && root.audioBackend.failedDevice === "output"
            label: "Output device switch failed"
            subtext: "The device did not confirm within " + (root.audioBackend ? root.audioBackend.deviceSwitchTimeoutMs : 3000) + "ms — try again or pick a different device."
        }
    }

    SettingsSection {
        title: "Input"
        icon: "mic"

        SelectRow {
            label: "Input device"
            subtext: root.audioBackend ? root.audioBackend.streamRouteNote : ""
            model: root.audioBackend ? root.audioBackend.sources.map(function (n) {
                return { value: n.name, display: root.audioBackend.deviceLabel(n) };
            }) : []
            currentValue: (root.audioBackend && root.audioBackend.defaultSource) ? root.audioBackend.defaultSource.name : ""
            busy: root.audioBackend && root.audioBackend.pendingDevice === "input"
            onSelected: (value) => {
                var node = root._findSourceByName(value);
                if (node && root.audioBackend)
                    root.audioBackend.setDefaultSource(node);
            }
        }
        SliderRow {
            label: "Input level"
            subtext: "Default input device"
            from: 0; to: 1; stepSize: 0.01
            value: root.audioBackend ? root.audioBackend.inputVolume : 0
            enabled: root.audioBackend !== null
            onMoved: (v) => root.audioBackend && root.audioBackend.setInputVolume(v)
        }
        ToggleRow {
            label: "Mic mute"
            subtext: "Mute the default input device"
            checked: root.audioBackend ? root.audioBackend.inputMuted : false
            enabled: root.audioBackend !== null
            onToggled: (value) => root.audioBackend && root.audioBackend.setInputMuted(value)
        }
        InfoRow {
            visible: root.audioBackend && root.audioBackend.failedDevice === "input"
            label: "Input device switch failed"
            subtext: "The device did not confirm within " + (root.audioBackend ? root.audioBackend.deviceSwitchTimeoutMs : 3000) + "ms — try again or pick a different device."
        }
    }

    SettingsSection {
        title: "Per-app mixer"
        icon: "tune"

        // Repeater over the real node objects directly — `modelData` IS
        // the node, never an id looked back up (the exact "pass the
        // object, not an id" idiom this repo's own MediaBackend fix
        // already established for MPRIS players).
        Repeater {
            model: root.audioBackend ? root.audioBackend.streamNodes : []

            SliderRow {
                id: streamRow
                required property var modelData

                // Static label (RowIndex's jump-key match is by exact
                // label, and a per-stream dynamic label would collide
                // with itself across Repeater instances — the same
                // reasoning InputPage.qml's per-device rows already
                // apply); the real per-app name rides as subtext.
                label: "Per-app volume"
                subtext: root.audioBackend ? root.audioBackend.streamLabel(streamRow.modelData) : ""
                from: 0; to: 1; stepSize: 0.01
                value: (streamRow.modelData && streamRow.modelData.audio) ? streamRow.modelData.audio.volume : 0
                onMoved: (v) => root.audioBackend && root.audioBackend.setStreamVolume(streamRow.modelData, v)
            }
        }
        InfoRow {
            visible: !root.audioBackend || root.audioBackend.streamNodes.length === 0
            label: "Nothing playing"
            subtext: "Per-app volume sliders appear here once an application is producing audio."
        }

        NavRow {
            label: "Full mixer"
            subtext: "Open the full audio panel for the complete per-app list"
            onActivated: root.sState.panelRequested("audio")
        }
    }
}
