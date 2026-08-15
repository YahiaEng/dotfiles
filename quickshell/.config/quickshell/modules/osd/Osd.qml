// Osd.qml — the OSD indicator surface (Phase 20 Plans 04/05,
// QOSD-01/QOSD-03/QOSD-04 this commit; QOSD-02 Caps Lock lands in this
// same plan's Task 2, a following commit).
//
// A `Toast.qml` INSTANCE (D-20-02/D-20-04), never a new frame type — no new
// GATE-03 registry work beyond a namespace registration. Bottom-centre
// (D-20-01, a named divergence from Caelestia's right-edge OSD placement),
// interactive (drag a slider, hover pauses dismiss), on the
// `quickshell-osd` namespace declared in plan 20-03, dismissing after
// `Design.osdHideDelayMs`.
//
// ── The trigger is backend state, never the keybind (D-20-05) ────────────
// The `Connections` blocks below react to `AudioBackend`'s/
// `BrightnessBackend`'s own reactive properties. A hardware key changes
// system state, the backend's property changes, and THAT calls `show()` —
// no keybind ever calls `show()` directly. This is what makes an external
// `wpctl` call or a bar scroll raise the identical indicator to a hardware
// key press.
//
// ── Membership — a rolling recency window, not a static flag (D-20-08) ──
// A control's row is visible only while `Design.osdRecencyWindowMs` (1500)
// has not elapsed since ITS OWN last change, the window sliding forward on
// every new change to THAT control only. This is a DELIBERATE divergence
// from Caelestia, which shows its OSD sliders unconditionally behind
// static `enableMicrophone`/`enableBrightness` config flags — do not
// "fix" this file toward that reference; D-20-08 already made this call.
// Order is always Volume -> Mic -> Brightness (Caelestia's own OSD trio
// order), constructed positionally below — never sorted by recency.
//
// ── Present-but-inert scope (D-18-39) ─────────────────────────────────────
// A present-but-inert backend (brightness, on this host — see
// BrightnessBackend.qml's own header) renders no row, because its value
// never changes and the recency gate above never opens — the SAME rule
// that governs "control did not move" and "control does not exist", not a
// third special case. This resolution is scoped to THIS transient OSD
// only and must NOT be propagated to the notification centre's
// always-visible sliders, where 19-UI-SPEC.md's N6/empty question is still
// open where it actually lives.
//
// ── The recency-window ticker (Task 2 of this plan reuses this SAME
//    Timer for Caps Lock polling — see that commit for why) ─────────────
// `osdTicker` below ages out any control whose recency window has
// elapsed, every `_tickerIntervalMs`.
//
// ── Brightness's OWN trigger gap (a separate, already-scoped item) ────────
// `BrightnessBackend.percent` only updates from writes ITS OWN
// `adjustProcess` issues — it has no live subscription to the backlight
// device file the way `AudioBackend` has a live PipeWire subscription (see
// 20-04-SUMMARY.md's own "Baseline Behaviour Comparison" and
// `.planning/todos/pending/2026-08-15-brightness-osd-unverifiable-on-
// desktop.md`). This plan resolves it by routing the WRITE through the
// backend (shell.qml's `osd` IpcHandler, called by the two brightness
// keybinds instead of a raw `brightnessctl` exec) so the backend itself
// remains the sole emitter of `percentChanged`, keeping D-20-05's "trigger
// is backend state, never the keybind" literally true — see shell.qml's
// own comment beside that IpcHandler. This host has no backlight device at
// all (`BrightnessBackend.present` is false here), so neither the old nor
// the new brightness path can be exercised live on this machine; report as
// implemented-but-UNVERIFIED, per the todo file's own verification-debt
// section, until re-tested on real laptop hardware.
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

    // ── Recency state (D-20-08) — one timestamp + one derived visibility
    //    flag per control, aged out by the shared ticker below. Never
    //    read directly by a row; each row's own `visible:` binds to the
    //    `*Recent` flag for its control. ─────────────────────────────────
    property real _volumeChangedAt: 0
    property bool volumeRecent: false
    property real _micChangedAt: 0
    property bool micRecent: false
    property real _brightnessChangedAt: 0
    property bool brightnessRecent: false

    // `interval:` (never `duration:`) — the same reasoning
    // AudioBackend.qml's own `deviceSwitchTimeoutMs` comment already
    // records: this keeps the ticker outside motion-lint's raw-duration
    // reach and off the motion-scale axis. A functional poll/scheduler
    // interval shrinking to zero at the lowest motion preset would be a
    // bug, not a feature — this is a cadence, not an animation.
    readonly property int _tickerIntervalMs: 250

    function _markRecent(control) {
        const now = Date.now();
        if (control === "volume") {
            osd._volumeChangedAt = now;
            osd.volumeRecent = true;
        } else if (control === "mic") {
            osd._micChangedAt = now;
            osd.micRecent = true;
        } else if (control === "brightness") {
            osd._brightnessChangedAt = now;
            osd.brightnessRecent = true;
        }
        osd.show();
    }

    function _tick() {
        const now = Date.now();
        if (osd.volumeRecent && now - osd._volumeChangedAt >= Design.osdRecencyWindowMs)
            osd.volumeRecent = false;
        if (osd.micRecent && now - osd._micChangedAt >= Design.osdRecencyWindowMs)
            osd.micRecent = false;
        if (osd.brightnessRecent && now - osd._brightnessChangedAt >= Design.osdRecencyWindowMs)
            osd.brightnessRecent = false;
    }

    // ── QOSD-04: up to three independently adjustable rows, fixed order,
    //    each present only because its own control actually moved. ──────
    Column {
        id: osdSliderColumn
        width: Design.osdWidth - Design.spacingMd * 2
        spacing: Design.spacingSm

        OsdSliderRow {
            id: osdVolumeRow
            width: osdSliderColumn.width
            visible: osd.volumeRecent
            // Graded by level, matching SwayOSD's own four-state icon
            // behaviour. Cut points (0.34 / 0.67) are taken verbatim from
            // MediaConnectivityCapsule.qml's own `audioGlyph` so the bar
            // capsule and the OSD change glyph at the SAME volume — a
            // second set of thresholds would let the two disagree on
            // screen at once. This logic is BYTE-IDENTICAL to plan
            // 20-04's tracer; only its location moved. Do not refactor
            // into a shared helper that alters thresholds or the zero
            // case (upstream_state's own instruction).
            glyph: {
                if (!osd.audioBackend || osd.audioBackend.masterMuted || osd.audioBackend.masterVolume <= 0)
                    return "volume_off";
                if (osd.audioBackend.masterVolume < 0.34)
                    return "volume_mute";
                if (osd.audioBackend.masterVolume < 0.67)
                    return "volume_down";
                return "volume_up";
            }
            value: osd.audioBackend ? osd.audioBackend.masterVolume : 0
            onMoved: (v) => {
                if (osd.audioBackend)
                    osd.audioBackend.setMasterVolume(Math.max(0, Math.min(1, v)));
            }
            onWheelStepped: (direction) => {
                if (!osd.audioBackend)
                    return;
                const step = Design.barScrollStepPercent / 100;
                const next = Math.max(0, Math.min(1, osd.audioBackend.masterVolume + direction * step));
                osd.audioBackend.setMasterVolume(next);
            }
        }

        OsdSliderRow {
            id: osdMicRow
            width: osdSliderColumn.width
            visible: osd.micRecent
            glyph: (!osd.audioBackend || osd.audioBackend.inputMuted) ? "mic_off" : "mic"
            value: osd.audioBackend ? osd.audioBackend.inputVolume : 0
            onMoved: (v) => {
                if (osd.audioBackend)
                    osd.audioBackend.setInputVolume(Math.max(0, Math.min(1, v)));
            }
            onWheelStepped: (direction) => {
                if (!osd.audioBackend)
                    return;
                const step = Design.barScrollStepPercent / 100;
                const next = Math.max(0, Math.min(1, osd.audioBackend.inputVolume + direction * step));
                osd.audioBackend.setInputVolume(next);
            }
        }

        OsdSliderRow {
            id: osdBrightnessRow
            width: osdSliderColumn.width
            visible: osd.brightnessRecent
            // Not yet used anywhere else in this shell — verified this
            // session against the installed Material Symbols Rounded
            // variable font's own glyph order (fontTools
            // `TTFont.getGlyphOrder()`): "brightness_6" resolves as a
            // named glyph, the identical presence pattern
            // "volume_up"/"mic"/"mic_off" (already rendering correctly on
            // this shell) show under the same lookup. Confirms the glyph
            // NAME exists in the font; the plan's own human-check step
            // still owns confirming the rendered pixel.
            glyph: "brightness_6"
            value: BrightnessBackend.percent / 100
            onMoved: (v) => BrightnessBackend.setPercent(v * 100)
            onWheelStepped: (direction) => BrightnessBackend.adjust(direction)
        }
    }

    // ── The recency-window ticker — see header. Task 2 of this plan
    //    (Caps Lock) reuses this SAME Timer instance for its own poll
    //    rather than declaring a second one — see that commit. ─────────
    Timer {
        id: osdTicker
        interval: osd._tickerIntervalMs
        repeat: true
        running: true
        onTriggered: osd._tick()
    }

    // ── Trigger — D-20-05, see header. One Connections block per backend,
    //    each change marking its own control recent (D-20-08).
    //    `BrightnessBackend` is a singleton (modules/bar/qmldir), reached
    //    directly through the "../bar" import above — no threading
    //    through shell.qml is needed, unlike `audioBackend` which
    //    Osd.qml never mounts itself. ───────────────────────────────────
    Connections {
        target: osd.audioBackend
        function onMasterVolumeChanged() {
            osd._markRecent("volume");
        }
        function onMasterMutedChanged() {
            osd._markRecent("volume");
        }
        function onInputVolumeChanged() {
            osd._markRecent("mic");
        }
        function onInputMutedChanged() {
            osd._markRecent("mic");
        }
    }

    Connections {
        target: BrightnessBackend
        function onPercentChanged() {
            osd._markRecent("brightness");
        }
    }
}
