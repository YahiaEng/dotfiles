// OsdSliderRow.qml — one reusable OSD slider row (Phase 20 Plan 05,
// QOSD-04). A glyph -> Design.spacingMd gap -> a Slider filling the
// remaining row width, reusing AudioPopout.qml's track/handle geometry
// VERBATIM per 20-UI-SPEC.md's resolved "reuse vs. lighter variant"
// discretion item: track height 8 / radius 4, handle 20x20 / radius 10,
// fill+handle BarRoles.accent, track base BarRoles.capsuleTrack — the
// SAME literals Osd.qml's own tracer (plan 20-04) already used for its
// single volume row, now generalised into one type Osd.qml instantiates
// up to three times (Volume, Mic, Brightness).
//
// Public API: `glyph` (a Material Symbols ligature name), `value`
// (normalised to [0,1] regardless of the backend's own native range —
// BrightnessBackend's 0-100 percent is converted by the caller, Osd.qml,
// not here), `moved(value)` (drag, already clamped) and `wheelStepped
// (direction)` (one signed notch per accumulated 120 wheel units, the
// caller decides the step size per control).
//
// ── The clamp travels with the call site (AudioPopout.qml's own finding,
//    repeated here) ─────────────────────────────────────────────────────
// `AudioBackend.setMasterVolume()`/`setInputVolume()` carry no range
// clamp of their own — read from AudioBackend.qml directly, not assumed.
// This row clamps its own `moved`/`wheelStepped` emissions into [0,1]
// before emitting, mirroring `AudioPopout.qml`'s own Slider `onMoved`
// comment and `MediaConnectivityCapsule.qml`'s wheel handler's identical
// guard — the row never emits a value outside the domain a caller can
// blindly forward to a backend writer.
//
// ── WheelHandler acceptedDevices — a MEASURED, load-bearing fix carried
//    forward, not an invented precaution ──────────────────────────────
// `MediaConnectivityCapsule.qml`'s own header (audioWheelHandler,
// brightnessWheelHandler) records a live measurement: on this host, Qt's
// Wayland backend reports the seat pointer as `PointerDevice.TouchPad`
// for EVERY pointing device including a real mouse. A `WheelHandler` left
// at its default `acceptedDevices` (Mouse) NEVER fires here — zero
// events, on every device, confirmed live with a synthetic pointer.
// `acceptedDevices: PointerDevice.AllDevices` below is required for
// scroll-to-adjust to work at all; omitting it would ship a row whose
// scroll silently does nothing, exactly the "looks correct in code
// review" failure this repo has already hit once on this exact platform
// fact.
import QtQuick
import QtQuick.Controls
import "../"
import "../dashboard"
import "../bar"

Row {
    id: root

    property string glyph: "volume_up"
    property real value: 0
    signal moved(real value)
    signal wheelStepped(int direction)

    spacing: Design.spacingMd
    height: Design.iconSizeMd

    Text {
        id: rowGlyph
        anchors.verticalCenter: parent.verticalCenter
        font.family: Design.symbolFontFamily
        font.pixelSize: Design.iconSizeMd
        color: BarRoles.notifSurfaceFg
        text: root.glyph
    }

    Slider {
        id: rowSlider
        anchors.verticalCenter: parent.verticalCenter
        width: root.width - rowGlyph.width - Design.spacingMd
        height: rowGlyph.height
        from: 0
        to: 1
        // Always bound to the caller's own `value` (D-22 truth-driven,
        // the same discipline AudioPopout.qml's identical control
        // follows) — never a locally-held copy, so an external change
        // (a bar scroll, an external wpctl call) shows up here with no
        // interaction of its own.
        value: root.value
        onMoved: root.moved(Math.max(0, Math.min(1, rowSlider.value)))

        background: Rectangle {
            x: rowSlider.leftPadding
            y: rowSlider.topPadding + rowSlider.availableHeight / 2 - height / 2
            width: rowSlider.availableWidth
            height: 8
            radius: 4
            color: BarRoles.capsuleTrack

            Rectangle {
                id: rowFill
                width: rowSlider.visualPosition * parent.width
                height: parent.height
                radius: parent.radius
                color: BarRoles.accent

                // ── The OSD's one motion gap (quick task 260825-v3u) ──────
                // This file carried no `Behavior on` at all, so every
                // volume/brightness step snapped the fill and the handle to
                // their new positions in a single frame while every other
                // surface in the shell eased. The OSD's own *appearance* was
                // never the gap — `Toast.qml` animates the frame this row
                // lives in — which is exactly why a green `motion-lint`
                // (552 passed / 0 failed) never flagged it: CHECK B looks
                // for raw literals at animation sites, and an absent
                // animation has no site to inspect.
                //
                // DISABLED WHILE THE HANDLE IS HELD, deliberately. A
                // `Behavior` on a dragged property interpolates toward the
                // pointer instead of tracking it, so the fill would lag the
                // thumb for the whole gesture. Keyboard, wheel and the
                // XF86Audio*/XF86MonBrightness* binds — every path that
                // changes the value in a jump rather than continuously — all
                // still ease.
                Behavior on width {
                    enabled: Motion.motionEnabled && !rowSlider.pressed
                    NumberAnimation {
                        duration: Motion.standardDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Motion.standardEasing
                    }
                }
            }
        }
        handle: Rectangle {
            id: rowHandle
            x: rowSlider.leftPadding + rowSlider.visualPosition * (rowSlider.availableWidth - width)
            y: rowSlider.topPadding + rowSlider.availableHeight / 2 - height / 2
            width: 20
            height: 20
            radius: 10
            color: BarRoles.accent

            // Same token pair and the same drag exemption as the fill above,
            // so the two never separate mid-travel.
            Behavior on x {
                enabled: Motion.motionEnabled && !rowSlider.pressed
                NumberAnimation {
                    duration: Motion.standardDuration
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.standardEasing
                }
            }
        }
    }

    // ── Scroll-to-adjust — covers the WHOLE row (glyph + slider), not
    //    only the slider's own hit area, so "scrolling over the row"
    //    reads literally. One notch (120 accumulated wheel units) is one
    //    step, the same accumulate-then-drain idiom
    //    MediaConnectivityCapsule.qml's own audio/brightness handlers use
    //    — a high-resolution wheel or a touchpad stays proportional
    //    rather than firing a full step per micro-event, and the signed
    //    accumulator cancels cleanly on an immediate direction reversal.
    WheelHandler {
        id: rowWheel
        target: null
        acceptedDevices: PointerDevice.AllDevices

        property real pendingAngle: 0

        onWheel: (event) => {
            rowWheel.pendingAngle += event.angleDelta.y;
            const notchUnits = 120;
            let notchCount = 0;
            while (Math.abs(rowWheel.pendingAngle) >= notchUnits) {
                const direction = rowWheel.pendingAngle > 0 ? 1 : -1;
                rowWheel.pendingAngle -= direction * notchUnits;
                notchCount += direction;
            }
            if (notchCount !== 0)
                root.wheelStepped(notchCount);
        }
    }
}
