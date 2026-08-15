// Osd.qml — the OSD indicator surface (Phase 20 Plan 04, QOSD-01/QOSD-03).
//
// A `Toast.qml` INSTANCE (D-20-02/D-20-04), never a new frame type — no new
// GATE-03 registry work beyond a namespace registration. Bottom-centre
// (D-20-01, a named divergence from Caelestia's right-edge OSD placement),
// interactive (drag the slider, hover pauses dismiss), on the
// `quickshell-osd` namespace declared in plan 20-03, dismissing after
// `Design.osdHideDelayMs`.
//
// ── The trigger is backend state, never the keybind (D-20-05) ────────────
// The `Connections` block below reacts to `AudioBackend`'s own reactive
// properties. A hardware key changes system state (PipeWire), PipeWire
// propagates it, `AudioBackend`'s property changes, and THAT calls
// `show()` — the keybind itself never calls `show()` directly. This is
// what makes an external `wpctl` call or a bar scroll raise the identical
// indicator to a hardware key press.
//
// ── Task 1 (this tracer) content: one row, volume only ────────────────────
// A glyph -> Design.spacingMd gap -> a Slider reusing AudioPopout.qml's
// track/handle geometry verbatim, value bound to AudioBackend.masterVolume.
// The multi-row column (mic/brightness/caps-lock), the recency window and
// the mic row are plan 20-05's own scope — Task 2 of this plan only widens
// the TRIGGER (mic/brightness backends), never the content shown here.
import QtQuick
import QtQuick.Controls
import Quickshell
import "../"
import "../dashboard"
import "../bar"
import "../toast"

Toast {
    id: osd

    // Threaded in from shell.qml exactly like Bar.qml/Dashboard.qml's own
    // shared-backend pattern — Osd.qml never mounts its own AudioBackend.
    property var audioBackend: null

    edge: "bottom"
    interactive: true
    layerNamespace: "quickshell-osd"
    dismissDurationMs: Design.osdHideDelayMs

    // Width is fixed (D-20-10, deliberately narrower than
    // notifSurfaceWidth); height stays content-hugging — Toast.qml's own
    // implicitHeight binding is untouched, only implicitWidth is
    // overridden here.
    implicitWidth: Design.osdWidth

    Row {
        id: osdRow
        width: Design.osdWidth - Design.spacingMd * 2
        spacing: Design.spacingMd

        Text {
            id: osdVolumeGlyph
            anchors.verticalCenter: parent.verticalCenter
            font.family: Design.symbolFontFamily
            font.pixelSize: Design.iconSizeMd
            color: BarRoles.notifSurfaceFg
            text: (!osd.audioBackend || osd.audioBackend.masterMuted || osd.audioBackend.masterVolume <= 0) ? "volume_off" : "volume_up"
        }

        // Track/handle geometry reused verbatim from AudioPopout.qml's own
        // Slider (per UI-SPEC's resolved discretion item) — same 8px/4r
        // track and 20x20/10r handle, coloured through BarRoles rather than
        // Colours directly since this frame lives in the bar-adjacent
        // colour-role layer.
        Slider {
            id: osdVolumeSlider
            anchors.verticalCenter: parent.verticalCenter
            width: osdRow.width - osdVolumeGlyph.width - Design.spacingMd
            height: osdVolumeGlyph.height
            from: 0
            to: 1
            value: osd.audioBackend ? osd.audioBackend.masterVolume : 0
            onMoved: {
                if (osd.audioBackend)
                    osd.audioBackend.setMasterVolume(Math.max(0, Math.min(1, osdVolumeSlider.value)));
            }

            background: Rectangle {
                x: osdVolumeSlider.leftPadding
                y: osdVolumeSlider.topPadding + osdVolumeSlider.availableHeight / 2 - height / 2
                width: osdVolumeSlider.availableWidth
                height: 8
                radius: 4
                color: BarRoles.capsuleTrack

                Rectangle {
                    width: osdVolumeSlider.visualPosition * parent.width
                    height: parent.height
                    radius: parent.radius
                    color: BarRoles.accent
                }
            }
            handle: Rectangle {
                x: osdVolumeSlider.leftPadding + osdVolumeSlider.visualPosition * (osdVolumeSlider.availableWidth - width)
                y: osdVolumeSlider.topPadding + osdVolumeSlider.availableHeight / 2 - height / 2
                width: 20
                height: 20
                radius: 10
                color: BarRoles.accent
            }
        }
    }

    // ── Trigger — D-20-05, see header. Reacts to the two AudioBackend
    //    properties this task's single row reads. Task 2 widens this SAME
    //    block (mic/brightness) rather than adding a second Connections. ──
    Connections {
        target: osd.audioBackend
        function onMasterVolumeChanged() {
            osd.show();
        }
        function onMasterMutedChanged() {
            osd.show();
        }
    }
}
