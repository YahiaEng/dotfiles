// Osd.qml — the OSD indicator surface (Phase 20 Plans 04/05,
// QOSD-01/QOSD-02/QOSD-03/QOSD-04).
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
// ── Plan 20-05 content: three shapes, one frame ───────────────────────────
// `body` (Toast.qml's content slot) holds exactly TWO top-level Items —
// `osdSliderColumn` (the QOSD-04 multi-slider column) and `capsLockRow`
// (the QOSD-02 Caps Lock row) — made mutually exclusive purely by their own
// `visible` bindings (D-20-04/D-20-11: one `Toast`, one content region, no
// second frame). `bodyRow` (Toast.qml's own `Row`) skips whichever one is
// currently invisible, so this is structurally identical to "one shape at
// a time" without a Loader or a state machine.
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
// ── One shared Timer, two jobs (load-bearing, read before editing) ───────
// `osdTicker` below is the ONLY `Timer {}` in this module directory. It
// does two things every tick: (1) ages out any control whose recency
// window has elapsed, and (2) calls `capsLockBackend.checkNow()` — see
// `CapsLockBackend.qml`'s own header for why Caps Lock detection is a
// bounded POLL rather than the event-driven watch QOSD-02 was originally
// specified around (GATE-01 measured the watch dead on this host). The
// poll must run for the WHOLE SESSION, not merely while the OSD is
// visible, since it is what CATCHES the ON edge that raises the OSD in the
// first place — it cannot be gated on the OSD's own visibility without
// becoming circular. This is a deliberate, documented divergence from this
// plan's own zero-idle prohibition, made because the originally-specified
// mechanism is measured non-functional here — NOT a silent substitution.
// Do not add a second `Timer {}` anywhere in this directory; extend this
// one's `_tick()` instead, the same way it already serves two owners.
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

    // ── Content-shape switch (D-20-04/D-20-11) — see header. Set true
    //    only by capsLockBackend's own turnedOn() signal below; cleared by
    //    every audio/brightness change, so whichever trigger fired most
    //    recently owns the frame. ─────────────────────────────────────
    property bool showingCapsLock: false

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
        osd.showingCapsLock = false;
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
        capsLockBackend.checkNow();
    }

    // ── QOSD-04: up to three independently adjustable rows, fixed order,
    //    each present only because its own control actually moved. ──────
    Column {
        id: osdSliderColumn
        visible: !osd.showingCapsLock
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

    // ── QOSD-02: replaces the column entirely (D-20-11), never joins it
    //    as a fourth row — see header. Identical geometry to the DND
    //    toast's own content row (Design.spacingSm icon-to-text,
    //    Design.spacingMd frame padding, inherited from Toast.qml). ─────
    Row {
        id: capsLockRow
        visible: osd.showingCapsLock
        width: Design.osdWidth - Design.spacingMd * 2
        spacing: Design.spacingSm

        Text {
            anchors.verticalCenter: parent.verticalCenter
            font.family: Design.symbolFontFamily
            font.pixelSize: Design.iconSizeMd
            color: BarRoles.notifSurfaceFg
            // Not yet used anywhere else in this shell — verified this
            // session the same way as "brightness_6" above:
            // "keyboard_capslock" resolves as a named glyph in the
            // installed Material Symbols Rounded variable font's glyph
            // order, the same presence pattern as this shell's other,
            // already-working glyphs.
            text: "keyboard_capslock"
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: Design.fontBody
            // Body weight, not DemiBold — this is feedback copy, matching
            // the DND toast's own text weight in this shared frame, not a
            // heading (20-UI-SPEC.md's own Typography section).
            font.weight: Design.weightBody
            color: BarRoles.notifSurfaceFg
            text: "Caps Lock"
        }
    }

    // ── The one shared Timer in this module directory — see header. ────
    Timer {
        id: osdTicker
        interval: osd._tickerIntervalMs
        repeat: true
        running: true
        onTriggered: osd._tick()
    }

    CapsLockBackend {
        id: capsLockBackend
    }

    Connections {
        target: capsLockBackend
        function onTurnedOn() {
            osd.showingCapsLock = true;
            osd.show();
        }
    }

    // ── Trigger — D-20-05, see header. One Connections block per backend,
    //    each change marking its own control recent (D-20-08) and
    //    switching the frame back to the slider column if Caps Lock's
    //    content was showing. `BrightnessBackend` is a singleton
    //    (modules/bar/qmldir), reached directly through the "../bar"
    //    import above — no threading through shell.qml is needed, unlike
    //    `audioBackend` which Osd.qml never mounts itself. ─────────────
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
