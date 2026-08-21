// CentreFooter.qml — the centre's pinned footer: the shared quick-toggle
// grid plus three live sliders (Phase 19 Plan 06 Task 3, D-19-19..21,
// QNOTIF-07/08).
//
// ── The no-drift contract, made observable (D-19-19/QNOTIF-07) ──────────
// `QuickToggles {}` below is the SAME promoted-to-singleton-backed
// component the dashboard drawer already instantiates, over the SAME
// `ToggleState` singleton (Plan 19-05). This is the second instantiation
// that makes QNOTIF-07's guarantee checkable rather than a vibe check:
// there is no second implementation to compare against, so if the two
// renderings ever differ it can only be the singleton itself. This file
// does not copy the grid, does not fork a centre-specific variant, and
// forwards its own already-threaded `audioBackend`/`wifiBackend`/
// `bluetoothBackend` handles into it exactly as `DashboardTab.qml` does —
// `QuickToggles.qml`'s own three `Binding` elements then relay them into
// `ToggleState` a second time, re-asserting the identical object
// reference, which that file's own header already documents as harmless.
//
// ── Sliders — geometry reused verbatim, colour recoloured (19-UI-SPEC.md
//    § "Sliders") ─────────────────────────────────────────────────────
// Track height 8 / radius 4, handle 20x20 — `AudioPopout.qml`'s own
// custom `Slider` shape, copied verbatim so the control feels identical
// wherever it appears. Colour is NOT copied from that file: `AudioPopout`
// reads `Colours.surfaceVariant`/`Colours.primary` directly, which
// predates D-19-43's BarRoles-only routing rule for this family. This
// surface instead reads `BarRoles.capsuleTrack` (track) and
// `BarRoles.accent` (fill + handle) — a named recolour of an existing
// file, not a locked-decision change.
//
// ── The centre is a THIRD VIEW on these backends, never a third writer
//    ──────────────────────────────────────────────────────────────────
// Every slider binds live to its backend's own current value and writes
// back only through that backend's existing setter
// (`AudioBackend.setMasterVolume`/`setInputVolume`,
// `BrightnessBackend.setPercent`, the Plan 19-05 absolute setter addition)
// — never a locally-held value. A separate volume value here that
// disagreed with the bar's own would be the exact failure QNOTIF-08's "no
// separate, disagreeing volume state" wording forbids.
//
// ── N6's own unresolved backstop, resolved here under Claude's Discretion
//    ──────────────────────────────────────────────────────────────────
// 19-UI-SPEC.md's own UI Considerations table leaves "hide vs. disable a
// slider whose backend is entirely absent" unresolved, and 19-06-PLAN.md's
// own <planner_assumptions> section names the assumed default: render the
// row disabled, never hidden, at the repo's established 0.38
// `disabledOpacity` — so the footer never changes shape between hosts.
// All three rows below follow that assumption; `reachable`/
// `unavailableReason` per row is what implements it.
import QtQuick
import QtQuick.Controls
import Quickshell
import "../"
import "../dashboard"
import "../bar"

Item {
    id: footerRoot

    property var audioBackend: null
    property var wifiBackend: null
    property var bluetoothBackend: null

    readonly property real _disabledOpacity: 0.38

    implicitHeight: toggleGridHost.implicitHeight + Design.spacingLg + slidersColumn.implicitHeight + Design.spacingMd * 2
    height: footerRoot.implicitHeight

    // ── 15-07 chevron relay, centre-side half (GATE-02 round 11) ────────
    // The tiles' own chevrons emit `panelRequested(name)` for the three
    // tiles that declare a `panel` (volume -> audio, wifi, bluetooth).
    // This footer instantiated QuickToggles WITHOUT connecting that
    // signal, so in the centre those chevrons emitted into nothing and
    // clicking them did visibly nothing — while the identical grid in the
    // dashboard drawer worked, because DashboardTab.qml:1423 relays it.
    // Relayed here to the same terminus by the same shape: footer ->
    // NotifCentre -> shell.qml's single guarded `openPanel(name)`, which
    // stays the only place a summon actually happens.
    signal panelRequested(string name)

    QuickToggles {
        id: toggleGridHost
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Design.spacingMd
        onPanelRequested: name => footerRoot.panelRequested(name)
        // A plain Item's own `height` does not auto-track its
        // `implicitHeight` — DashboardTab.qml's own identical
        // instantiation sets this explicitly for the same reason.
        height: implicitHeight
        audioBackend: footerRoot.audioBackend
        wifiBackend: footerRoot.wifiBackend
        bluetoothBackend: footerRoot.bluetoothBackend
    }

    // ── One row shape, three instances — glyph + spacingMd gap + slider
    //    filling the remaining row width (AudioPopout.qml's own row
    //    shape). ──────────────────────────────────────────────────────
    component SliderRow: Item {
        id: row

        property string glyphOn: ""
        property string glyphOff: ""
        property bool muted: false
        property bool reachable: true
        property string unavailableReason: ""
        property real value: 0
        property real toValue: 1
        signal moved(real v)

        height: Design.iconSizeMd
        opacity: row.reachable ? 1 : footerRoot._disabledOpacity

        Row {
            anchors.fill: parent
            spacing: Design.spacingMd

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: row.muted ? row.glyphOff : row.glyphOn
                font.family: Design.symbolFontFamily
                font.pixelSize: Design.iconSizeMd
                textFormat: Text.PlainText
                color: BarRoles.notifSurfaceFg
            }

            Slider {
                id: rowSlider
                anchors.verticalCenter: parent.verticalCenter
                width: row.width - Design.iconSizeMd - Design.spacingMd
                height: row.height
                enabled: row.reachable
                from: 0
                to: row.toValue
                // Always bound to the backend's own live value, never a
                // local copy (D-22's truth-driven discipline, the same
                // one AudioPopout.qml's identical control follows) —
                // matches the bar's own scroll-to-adjust or a hardware
                // key with no interaction of its own.
                value: row.value
                onMoved: row.moved(rowSlider.value)

                // ── Scroll-to-adjust (GATE-02 round 11) ─────────────────
                // The bar's own audio capsule already adjusts on scroll,
                // so a slider that only responds to drag was the odd one
                // out. `WheelHandler` rather than a MouseArea with
                // `onWheel`: a MouseArea filling the slider would sit over
                // the handle and swallow the drag this control already
                // supports, whereas WheelHandler consumes ONLY wheel
                // events and leaves press/drag entirely alone.
                //
                // Emits `row.moved(...)` — the same signal `onMoved`
                // raises — rather than assigning `rowSlider.value`
                // directly: `value` is bound to the backend's live truth
                // (see the note above), so writing it locally would break
                // that binding and desync the control from the hardware.
                // The backend echoes the new value back through the same
                // binding, exactly as a drag or a hardware key does.
                WheelHandler {
                    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                    enabled: row.reachable
                    onWheel: event => {
                        // One notch is 120 units (Qt's standard);
                        // step 5% of the row's own range so volume
                        // (0..1) and brightness (0..100) both move 5%.
                        var notches = event.angleDelta.y / 120;
                        if (notches === 0)
                            return;
                        var step = row.toValue * 0.05 * notches;
                        var next = Math.max(0, Math.min(row.toValue, rowSlider.value + step));
                        if (next !== rowSlider.value)
                            row.moved(next);
                    }
                }

                background: Rectangle {
                    x: rowSlider.leftPadding
                    y: rowSlider.topPadding + rowSlider.availableHeight / 2 - height / 2
                    width: rowSlider.availableWidth
                    height: 8
                    radius: 4
                    color: BarRoles.capsuleTrack

                    Rectangle {
                        width: rowSlider.visualPosition * parent.width
                        height: parent.height
                        radius: parent.radius
                        color: BarRoles.accent
                    }
                }
                handle: Rectangle {
                    x: rowSlider.leftPadding + rowSlider.visualPosition * (rowSlider.availableWidth - width)
                    y: rowSlider.topPadding + rowSlider.availableHeight / 2 - height / 2
                    width: 20
                    height: 20
                    radius: 10
                    color: BarRoles.accent
                }
            }
        }

        // ── D-15-09/D-41 fourth-state grammar, reused verbatim
        //    (PanelDialog.qml's own copy): the reason is reachable by
        //    hover even though the row itself is disabled — a fully
        //    disabled MouseArea would also stop receiving hover, making
        //    the reason unreachable, exactly the failure PanelDialog's
        //    own Advanced button comment already warns against. ─────────
        MouseArea {
            id: footerReasonMouseArea
            anchors.fill: parent
            enabled: !row.reachable
            hoverEnabled: true
            acceptedButtons: Qt.NoButton
        }
        // ThemedToolTip (quick-260821-6z1 fix wave) — replaces the bare
        // attached ToolTip shorthand; see ThemedToolTip.qml's own header.
        ThemedToolTip {
            visible: footerReasonMouseArea.containsMouse && !row.reachable
            text: row.unavailableReason
        }
    }

    Column {
        id: slidersColumn
        anchors.top: toggleGridHost.bottom
        anchors.topMargin: Design.spacingLg
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Design.spacingMd
        spacing: Design.spacingMd

        SliderRow {
            width: parent.width
            glyphOn: "volume_up"
            glyphOff: "volume_off"
            muted: footerRoot.audioBackend ? footerRoot.audioBackend.masterMuted : false
            reachable: !!footerRoot.audioBackend
            unavailableReason: "Volume unavailable — no audio backend mounted, then reopen this panel."
            value: footerRoot.audioBackend ? footerRoot.audioBackend.masterVolume : 0
            onMoved: v => {
                if (footerRoot.audioBackend)
                    footerRoot.audioBackend.setMasterVolume(Math.max(0, Math.min(1, v)));
            }
        }

        SliderRow {
            width: parent.width
            glyphOn: "mic"
            glyphOff: "mic_off"
            muted: footerRoot.audioBackend ? footerRoot.audioBackend.inputMuted : false
            reachable: !!footerRoot.audioBackend
            unavailableReason: "Microphone unavailable — no audio backend mounted, then reopen this panel."
            value: footerRoot.audioBackend ? footerRoot.audioBackend.inputVolume : 0
            onMoved: v => {
                if (footerRoot.audioBackend)
                    footerRoot.audioBackend.setInputVolume(Math.max(0, Math.min(1, v)));
            }
        }

        SliderRow {
            width: parent.width
            glyphOn: "brightness_6"
            glyphOff: "brightness_6"
            reachable: BrightnessBackend.present
            unavailableReason: "Brightness unavailable — no backlight device on this system, then reopen this panel."
            value: BrightnessBackend.percent
            toValue: 100
            onMoved: v => BrightnessBackend.setPercent(v)
        }
    }
}
