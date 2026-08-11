// MediaConnectivityCapsule.qml — the media + connectivity slot (Phase 18
// Plan 05, D-18-10). Filled by Phase 18 Plan 08 (QBAR-06).
//
// QBAR-06's connectivity and now-playing readout surface. Four of its five
// entries read handles `BarCapsule` already carries (`mediaBackend`,
// `audioBackend`, `wifiBackend`, `bluetoothBackend`); the fifth (battery)
// reads the native `Quickshell.Services.UPower` singleton directly — no new
// service connection, since `SystemResources.qml` already imports the same
// module elsewhere in this process. This file contains the only unbounded
// string on the entire bar surface (the media track title).
//
// The network and bluetooth entries deliberately read ONLY properties that
// are live without a scan or a discovery sweep, so nothing in this file can
// widen either of those two backends' gates:
//   - network reads `wifiBackend.wifiHardwareEnabled`, `.wifiEnabled`,
//     `.wifiDevice` and the resolved device's OWN `connected` flag — never
//     `currentNetwork` for the connected/disconnected decision (that comes
//     from `seenOrder`, which only populates from a scan). `currentNetwork`
//     is read ONLY to pick an already-connected glyph's strength bucket
//     from upstream's own five-glyph ramp when it happens to be non-null
//     (Phase 18.1 GATE-02 item (d) replaced the former opacity-modulation
//     scheme with this literal glyph selection — WifiPanel.qml's own
//     `strengthGlyph()` three-bucket idiom is still the shape reused, only
//     the OUTPUT changed from an alpha value to a glyph index).
//   - bluetooth reads `adapterPresent`, `adapterBlocked`, `adapterEnabled`
//     and `connectedDevices.length` — never the sweep-in-progress flag and
//     never either of the two sweep-control methods (named in
//     BluetoothBackend.qml, deliberately not repeated here, since this
//     file is gated on those identifiers being absent from it entirely).
// D-15-15/D-15-18 forbid running either backend's scan/discovery path
// always-on; a later reader adding a signal-strength arc or a
// nearby-network count from a NEW ungated property would be crossing
// exactly the line those decisions draw. Don't.
//
// ── Scroll contract (Phase 18 Plan 12, QBAR-04) ──────────────────────────
// This file now also carries the bar's scroll gestures, not only its
// readouts. Ownership split, stated so the two plans' seam is never
// discovered at merge time: 18-08 owns the five readout entries above —
// their glyphs, precedences, loading/error treatments, the media title's
// cap-and-elide, and the internal geometry. This plan (18-12) owns every
// scroll gesture on the bar and the sixth entry (brightness). Neither plan
// restyles, re-glyphs or re-wires what the other owns.
//
// 18-08's own acceptance criterion asserting this file holds no
// pointer-handler identifiers (HoverHandler/MouseArea/TapHandler/
// popoutDwellMs/SectionPopout/popoutDismissGraceMs) was a WAVE-3 FREEZE
// STATEMENT, already superseded twice over: 18-12 narrowed it to permit
// wheel handling; 18-13/18-14 (QBAR-09) then added PopoutTrigger and its
// own MouseArea-driven hover-preview/click-summon path, which is what
// audioPopoutTrigger/wifiPopoutTrigger/bluetoothPopoutTrigger/
// mediaPopoutTrigger below actually are. Phase 18.1's GATE-02 fix (item
// (d), the two hover-reveal drawer groups) narrows it a THIRD time: this
// file now also carries HoverHandler, restricted to feeding the two local
// drawer-hover contracts (audio, connections) that reveal the slider+mic
// and bluetooth members — the exact contract LauncherCapsule.qml already
// ships under D-16/D-17/D-18, mirrored here rather than reinvented. It
// coexists with, and does not replace, PopoutTrigger's own independent
// hover/click path: QtQuick pointer handlers observe concurrently with no
// conflict, so the SAME trigger glyph can both reveal its inline strip on
// a short local dwell AND still open its full popout on click. No other
// identifier from the original list (MouseArea/TapHandler/popoutDwellMs)
// is added directly in this file — MouseArea appears only inside the
// mic-mute cell this plan adds, matching WorkspaceCapsule/LauncherCapsule's
// own established per-cell click precedent.
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Services.UPower
import "../"
import "../dashboard"

BarCapsule {
    id: root

    capsuleId: "mediaConnectivity"

    // ── The one reusable readout element — same visual language as
    //    SystemCapsule.qml's own Readout: glyph + Design.spacingXs gap +
    //    right-aligned reserved-width value, one bound Grid for the
    //    orientation swap. Declared once here (a second, textually
    //    identical declaration, since QML has no cross-file component
    //    import for an unregistered inline type) and instantiated five
    //    times below — `showValue: false` is what makes network and
    //    bluetooth render glyph-only with zero reserved value width.
    //    `maxWidthVertical` is the one addition SystemCapsule.qml's
    //    element does not need: only the media title requires a SECOND,
    //    narrower width cap in the 44px vertical column — every other
    //    entry's value is already short enough to fit both orientations
    //    at its normal worst-case reservation. ─────────────────────────
    component Readout: Item {
        id: readoutItem

        property string glyph: ""
        // Phase 18.1 GATE-02 item (d) addition: the volume/network/
        // bluetooth drawer glyphs below are literal Nerd Font codepoints
        // (config-athena.jsonc's own glyph set), not Material Symbols
        // ligatures — the font this Text renders them in has to follow.
        // Defaults to the original hardcoded font so media/brightness/
        // battery (which never set this) are byte-for-byte unchanged.
        property string glyphFontFamily: Design.symbolFontFamily
        property string valueText: ""
        property string maxValueText: ""
        property bool showValue: true
        property bool populated: true
        property bool errored: false
        property bool elideValue: false
        // -1 means "no vertical-specific cap" (the normal case).
        property real maxWidthVertical: -1

        readonly property bool vertical: root.vertical

        implicitWidth: entryGrid.implicitWidth
        implicitHeight: entryGrid.implicitHeight

        TextMetrics {
            id: valueReserve
            font.pixelSize: Design.barBodySize
            font.weight: Design.weightBody
            text: readoutItem.maxValueText
        }

        Grid {
            id: entryGrid
            rows: readoutItem.vertical ? -1 : 1
            columns: readoutItem.vertical ? 1 : -1
            spacing: Design.spacingXs

            Text {
                font.family: readoutItem.glyphFontFamily
                font.pixelSize: Design.barGlyphSize
                text: readoutItem.glyph
                color: readoutItem.errored ? BarRoles.danger : root.contentColour
            }

            Text {
                visible: readoutItem.showValue
                font.pixelSize: Design.barBodySize
                font.weight: Design.weightBody
                color: root.contentColour
                horizontalAlignment: Text.AlignRight
                elide: readoutItem.elideValue ? Text.ElideRight : Text.ElideNone
                width: readoutItem.showValue
                    ? (readoutItem.vertical && readoutItem.maxWidthVertical >= 0
                        ? Math.min(valueReserve.width, readoutItem.maxWidthVertical)
                        : valueReserve.width)
                    : 0
                text: readoutItem.populated ? readoutItem.valueText : "—"
            }
        }
    }

    // ── media ────────────────────────────────────────────────────────────
    // Visible only when a player exists — contributes zero extent and zero
    // spacing otherwise (BarCapsule's own Grid positioner drops a
    // non-visible child's spacing for free). Third-party D-Bus text: a
    // plain `Text` whose `textFormat` is never assigned any rich or markup
    // format, capped at `Design.mediaTitleMaxChars` and elided right — the
    // ONE named truncation exception on the whole bar, legitimate ONLY
    // here because the full title already lives in the media popout
    // (18-14). The capsule's worst-case width is reserved from the CAP,
    // never from the current title, so a long title cannot push the clock
    // or tray sideways.
    readonly property string mediaTitleRaw: root.mediaBackend ? root.mediaBackend.displayTitle : ""
    readonly property string mediaTitleCapped: root.mediaTitleRaw.length > Design.mediaTitleMaxChars
        ? root.mediaTitleRaw.slice(0, Design.mediaTitleMaxChars)
        : root.mediaTitleRaw

    // ── Popout wrapper (Phase 18 Plan 14, QBAR-09) — same seam shape as
    //    the wifi/bluetooth wrappers Task 1 added. The trigger's own
    //    `visible` mirrors the Readout's — a PopoutTrigger wraps a plain
    //    Item, not a positioner, so its own implicit size does not
    //    collapse to zero merely because its child is invisible; without
    //    this the shared chrome's own Grid positioner would keep
    //    reserving space for an empty media entry, the exact regression
    //    this comment exists to prevent (Rule 1). ─────────────────────────
    PopoutTrigger {
        id: mediaPopoutTrigger
        visible: root.mediaBackend ? root.mediaBackend.hasPlayer : false
        sectionId: "media"
        popoutComponent: Component {
            MediaPopout {
                mediaBackend: root.mediaBackend
            }
        }

        Readout {
            visible: root.mediaBackend ? root.mediaBackend.hasPlayer : false
            glyph: "music_note"
            maxValueText: "M".repeat(Design.mediaTitleMaxChars)
            maxWidthVertical: Design.barColumnWidth
            elideValue: true
            populated: true
            valueText: root.mediaTitleCapped
        }
    }

    // ── audio ────────────────────────────────────────────────────────────
    readonly property bool audioMuted: root.audioBackend ? root.audioBackend.masterMuted : false
    readonly property real audioVolume: root.audioBackend ? root.audioBackend.masterVolume : 0
    readonly property bool audioReady: root.audioBackend ? root.audioBackend.pipewireReady : false

    // ── Phase 18.1 GATE-02 fix, item (d) — Athena's two right-side hover
    //    drawers (ATHENA-UPSTREAM-SPEC.md "Drawers"). group/audio: a
    //    volume glyph at rest reveals a slider + mic glyph on hover.
    //    group/connections (declared further below, beside the network/
    //    bluetooth properties): a network glyph at rest reveals a
    //    bluetooth glyph on hover. Both drawers reuse LauncherCapsule.
    //    qml's own hover contract verbatim (drawerHoverActive fed by BOTH
    //    the trigger and the strip through one reportXDrawerHover entry
    //    point, a dwell timer, a grace timer, a clip:true strip host) —
    //    never a second, unlatched hover trigger (D-18-19). Each drawer
    //    gets its OWN latch/timers (audio*/connections*) because this one
    //    capsule now hosts two independent drawers side by side, unlike
    //    LauncherCapsule's single one.
    //
    //    Glyphs are literal Nerd Font codepoints (\u{...} escapes, the
    //    same convention LauncherCapsule.qml/WorkspaceCapsule.qml already
    //    use for Athena's per-app/per-state glyphs), sourced from
    //    config-athena.jsonc — this repo's own waybar Athena config,
    //    already cmap-verified against the installed font per that
    //    file's own comments — and cross-checked against
    //    ATHENA-UPSTREAM-SPEC.md. The two sources disagree on which wifi
    //    glyph is "disconnected" vs "disabled"; config-athena.jsonc's own
    //    format-disconnected/format-disabled KEY NAMES settle it
    //    (disconnected = wifi-strength-off-outline U+F092E, radio on but
    //    no AP; disabled = wifi-off U+F05AA, radio off), and this file
    //    follows that resolution. "FiraCode Nerd Font" is the same family
    //    LauncherCapsule/WorkspaceCapsule already render Athena glyphs in
    //    — Design.symbolFontFamily (Material Symbols Rounded) has no
    //    ligature for a three-level pulseaudio ramp or a five-bar wifi
    //    strength icon, so the shared Readout component above grew one
    //    optional property (glyphFontFamily) rather than a second,
    //    parallel readout type.
    readonly property string drawerGlyphFontFamily: "FiraCode Nerd Font"
    // LauncherCapsule's own cellPitch formula, reused rather than
    // reinvented: Design.barGlyphSize (16) centred inside Design.spacingXs
    // (4) padding on every side.
    readonly property int drawerCellPitch: Design.barGlyphSize + Design.spacingXs * 2
    // No shared Design token exists for an inline bar slider — AudioPopout.
    // qml's own Slider lives in a much wider popout body. Local constant,
    // sized to read clearly at barCapsuleHeight (34) without dominating
    // the row.
    readonly property int audioSliderLength: 72
    readonly property int audioStripExtent: root.audioSliderLength + Design.spacingXs + root.drawerCellPitch
    readonly property int connectionsStripExtent: root.drawerCellPitch

    // Shared by both drawers — QsWindow.window's own live rendered/
    // transitioning state, the exact reachable path LauncherCapsule.qml's
    // own drawerSettled already proves live, never the reveal-machine's
    // dead settled latch (D-26 fences that one out by name).
    readonly property bool drawerSettled: QsWindow.window ? (QsWindow.window.barRendered && !QsWindow.window.barTransitionRunning) : false

    // A drawer that survived into a hidden bar would reappear expanded on
    // the next reveal (QBAR-07's boundary case, LauncherCapsule's own
    // precedent) — collapse both, immediately, with no grace, the moment
    // the bar stops being settled.
    onDrawerSettledChanged: {
        if (root.drawerSettled)
            return;
        if (root.audioDrawerExpanded) {
            audioDrawerDwellTimer.stop();
            audioDrawerGraceTimer.stop();
            root.requestAudioDrawerCollapse();
        }
        if (root.connectionsDrawerExpanded) {
            connectionsDrawerDwellTimer.stop();
            connectionsDrawerGraceTimer.stop();
            root.requestConnectionsDrawerCollapse();
        }
    }

    property bool _audioTriggerHovered: false
    property bool _audioStripHovered: false
    property bool audioDrawerHoverActive: false
    function reportAudioDrawerHover(source, entered) {
        if (source === "trigger")
            root._audioTriggerHovered = entered;
        else if (source === "strip")
            root._audioStripHovered = entered;
        root.audioDrawerHoverActive = root._audioTriggerHovered || root._audioStripHovered;
    }

    property bool audioDrawerExpanded: false
    function requestAudioDrawerExpand() {
        root.audioDrawerExpanded = true;
    }
    function requestAudioDrawerCollapse() {
        root.audioDrawerExpanded = false;
    }

    onAudioDrawerHoverActiveChanged: {
        if (root.audioDrawerHoverActive) {
            audioDrawerGraceTimer.stop();
            audioDrawerDwellTimer.restart();
        } else {
            audioDrawerDwellTimer.stop();
            audioDrawerGraceTimer.restart();
        }
    }

    Timer {
        id: audioDrawerDwellTimer
        interval: Design.barDrawerDwellMs
        repeat: false
        onTriggered: {
            // Re-evaluated at FIRE time, not only at arm time — a dwell
            // armed while the bar was up must not open a drawer into a
            // bar that began hiding moments later.
            if (root.audioDrawerHoverActive && root.drawerSettled)
                root.requestAudioDrawerExpand();
        }
    }
    Timer {
        id: audioDrawerGraceTimer
        interval: Design.popoutDismissGraceMs
        repeat: false
        onTriggered: {
            if (!root.audioDrawerHoverActive)
                root.requestAudioDrawerCollapse();
        }
    }

    // Level/muted precedence — 0.34/0.67 buckets are this file's own
    // established 3-way threshold idiom (WifiPanel.qml's strengthGlyph,
    // already reused once below by networkOpacity's predecessor); reused
    // here rather than a fourth ad hoc pair of cut points. Headphone-type
    // aliasing (Athena's format-icons.headphone/headset/hands-free, all
    // "\u{f02cb}") is NOT implemented: AudioBackend exposes no output
    // device form-factor signal, only a display label string, and
    // pattern-matching that string would be a heuristic this file has no
    // authority to invent — a named delta, not a silent omission.
    readonly property string audioGlyph: {
        if (root.audioMuted)
            return "\u{eee8}"; // fa-volume_xmark (format-muted)
        if (root.audioVolume < 0.34)
            return "\u{f026}"; // fa-volume_off (low)
        if (root.audioVolume < 0.67)
            return "\u{f027}"; // fa-volume_down (medium)
        return "\u{f028}"; // fa-volume_up (high)
    }

    // ── The strip — revealed on hover, BEFORE the trigger in declaration
    //    order. This capsule sits in the bar's END zone (anchors.right),
    //    so a Grid's LAST child's right edge is what stays pinned to the
    //    window edge as the Grid's own width changes (Qt Quick Grid
    //    layout arithmetic: growing an EARLIER sibling shifts everything
    //    before it left while leaving the grid's own right edge, and
    //    everything after the growing sibling, at the same absolute
    //    screen position). Declaring the strip before the trigger is what
    //    makes the reveal grow LEFTWARD out of a fixed trigger position —
    //    upstream's own `transition-left-to-right: false` (groups.jsonc)
    //    — rather than pushing the trigger itself sideways. ─────────────
    Item {
        id: audioStripHost
        clip: true
        width: root.vertical ? root.drawerCellPitch : (root.audioDrawerExpanded ? root.audioStripExtent : 0)
        height: root.vertical ? (root.audioDrawerExpanded ? root.audioStripExtent : 0) : root.drawerCellPitch

        // Asymmetric in/out — this repo's quick-to-leave grammar
        // (LauncherCapsule's own stripHost Behaviors), reused rather than
        // invented. 650ms — Design.barDrawerTransitionMs, upstream's own
        // audio-drawer transition-duration (groups.jsonc).
        Behavior on width {
            enabled: Motion.motionEnabled
            NumberAnimation {
                duration: Design.barDrawerTransitionMs
                easing.type: Easing.BezierSpline
                easing.bezierCurve: root.audioDrawerExpanded ? Motion.emphasizedInEasing : Motion.emphasizedOutEasing
            }
        }
        Behavior on height {
            enabled: Motion.motionEnabled
            NumberAnimation {
                duration: Design.barDrawerTransitionMs
                easing.type: Easing.BezierSpline
                easing.bezierCurve: root.audioDrawerExpanded ? Motion.emphasizedInEasing : Motion.emphasizedOutEasing
            }
        }

        HoverHandler {
            id: audioStripHoverHandler
            onHoveredChanged: root.reportAudioDrawerHover("strip", audioStripHoverHandler.hovered)
        }

        Grid {
            anchors.fill: parent
            rows: root.vertical ? -1 : 1
            columns: root.vertical ? 1 : -1
            spacing: Design.spacingXs

            // Horizontal, min 0 max 100 (upstream pulseaudio/slider,
            // groups.jsonc) — trough BarRoles.capsuleTrack, filled
            // highlight + knob BarRoles.accent, exactly the ground-truth
            // role split (BarRoles.qml's own capsuleTrack doc comment).
            // Same backend call shape as the trigger's own former wheel
            // handler and AudioPopout.qml's identical control: read live,
            // write clamped, never a local optimistic copy (D-22).
            Slider {
                id: audioVolumeSlider
                width: root.vertical ? root.drawerCellPitch : root.audioSliderLength
                height: root.vertical ? root.audioSliderLength : root.drawerCellPitch
                orientation: root.vertical ? Qt.Vertical : Qt.Horizontal
                from: 0
                to: 1
                value: root.audioBackend ? root.audioBackend.masterVolume : 0
                onMoved: {
                    if (root.audioBackend)
                        root.audioBackend.setMasterVolume(Math.max(0, Math.min(1, audioVolumeSlider.value)));
                }

                background: Rectangle {
                    x: audioVolumeSlider.leftPadding
                    y: audioVolumeSlider.topPadding + audioVolumeSlider.availableHeight / 2 - height / 2
                    width: root.vertical ? 4 : audioVolumeSlider.availableWidth
                    height: root.vertical ? audioVolumeSlider.availableHeight : 4
                    radius: 2
                    color: BarRoles.capsuleTrack

                    Rectangle {
                        anchors.bottom: root.vertical ? parent.bottom : undefined
                        width: root.vertical ? parent.width : audioVolumeSlider.visualPosition * parent.width
                        height: root.vertical ? audioVolumeSlider.visualPosition * parent.height : parent.height
                        radius: parent.radius
                        color: BarRoles.accent
                    }
                }
                handle: Rectangle {
                    x: root.vertical
                        ? (audioVolumeSlider.leftPadding + audioVolumeSlider.availableWidth / 2 - width / 2)
                        : (audioVolumeSlider.leftPadding + audioVolumeSlider.visualPosition * (audioVolumeSlider.availableWidth - width))
                    y: root.vertical
                        ? (audioVolumeSlider.topPadding + (1 - audioVolumeSlider.visualPosition) * (audioVolumeSlider.availableHeight - height))
                        : (audioVolumeSlider.topPadding + audioVolumeSlider.availableHeight / 2 - height / 2)
                    width: 12
                    height: 12
                    radius: 6
                    color: BarRoles.accent
                }
            }

            // pulseaudio#microphone (groups.jsonc) — glyph only, click
            // toggles input mute. No popout exists for the input side (
            // AudioPopout.qml carries only master volume/mute + sinks),
            // so this is the one place on the whole bar an input-mute
            // toggle is reachable; MouseArea click-toggle is
            // WorkspaceCapsule/LauncherCapsule's own established per-cell
            // pattern, reused rather than a second gesture invented.
            Item {
                id: audioMicCell
                width: root.drawerCellPitch
                height: root.drawerCellPitch

                Text {
                    anchors.centerIn: parent
                    font.family: root.drawerGlyphFontFamily
                    font.pixelSize: Design.barGlyphSize
                    text: (root.audioBackend && root.audioBackend.inputMuted) ? "\u{f131}" : "\u{f130}"
                    color: audioMicMouseArea.containsMouse ? BarRoles.accent : root.contentColour

                    Behavior on color {
                        enabled: Motion.motionEnabled
                        ColorAnimation {
                            duration: Motion.standardDuration
                            easing.type: Easing.BezierSpline
                            easing.bezierCurve: Motion.standardEasing
                        }
                    }
                }

                MouseArea {
                    id: audioMicMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        if (root.audioBackend)
                            root.audioBackend.setInputMuted(!root.audioBackend.inputMuted);
                    }
                    ToolTip.visible: audioMicMouseArea.containsMouse
                    ToolTip.text: (root.audioBackend && root.audioBackend.inputMuted) ? "Unmute microphone" : "Mute microphone"
                    ToolTip.delay: Design.tooltipDelayMs
                }
            }
        }
    }

    // ── Popout wrapper (Phase 18 Plan 13, QBAR-09) — named seam into this
    //    18-08-owned file. Ownership split, stated so it is never
    //    discovered at merge time: 18-08 owns the Readout's glyph, values
    //    and precedence; 18-12 owns the WheelHandler inside it (UNCHANGED
    //    below — not one line of it is touched by this plan); this plan
    //    owns only the PopoutTrigger wrapper around both, and adds no
    //    other identifier to this file. Phase 18.1 GATE-02 item (d) adds
    //    exactly one more sibling inside this same wrapper — the
    //    HoverHandler feeding the local drawer contract above — and
    //    switches the Readout from icon+percentage to icon-only
    //    (showValue: false), matching upstream's own pulseaudio "format":
    //    "{icon}" (config-athena.jsonc:306), never a percentage badge.
    PopoutTrigger {
        id: audioPopoutTrigger
        sectionId: "audio"
        popoutComponent: Component {
            AudioPopout {
                audioBackend: root.audioBackend
            }
        }

        Readout {
            id: audioReadout
            glyph: root.audioGlyph
            glyphFontFamily: root.drawerGlyphFontFamily
            showValue: false
            populated: root.audioReady

            // ── Scroll-to-adjust (18-12, QBAR-04, the tracer). One notch is
            //    one step, on every pointing device: angleDelta.y accumulates
            //    into a signed running total and one step is emitted per whole
            //    120 units (one notch on a classic wheel), the remainder
            //    carried forward — this is what keeps a high-resolution wheel
            //    or a touchpad proportional rather than firing a full step per
            //    micro-event. The accumulator is signed, so an immediate
            //    direction reversal cancels rather than queueing.
            //    `target: null` and no `property:` are both deliberate: this
            //    handler transforms nothing and mutates no target property —
            //    every effect comes from onWheel below. A handler left at its
            //    defaults with a target property named would silently scale or
            //    rotate this entry, a visible defect no source gate would
            //    catch.
            WheelHandler {
                id: audioWheelHandler
                target: null

                property real pendingAngle: 0

                onWheel: (event) => {
                    if (!root.audioBackend || !root.audioReady)
                        return;
                    audioWheelHandler.pendingAngle += event.angleDelta.y;
                    const notchUnits = 120;
                    while (Math.abs(audioWheelHandler.pendingAngle) >= notchUnits) {
                        const direction = audioWheelHandler.pendingAngle > 0 ? 1 : -1;
                        audioWheelHandler.pendingAngle -= direction * notchUnits;
                        // Read the backend's own masterVolume fresh on every
                        // step rather than accumulating a local running value —
                        // the same D-22 discipline AudioBackend's writers exist
                        // to enforce, and what keeps repeated stepping
                        // non-drifting.
                        const stepFraction = Design.barScrollStepPercent / 100;
                        let nextVolume = root.audioBackend.masterVolume + direction * stepFraction;
                        // Clamp to zero-to-unity at the call site: the shipped
                        // setMasterVolume() null-guards and does nothing else —
                        // there is no range clamp anywhere in it or its
                        // callers' path — and PipeWire treats a value above
                        // unity as amplification. This control is always
                        // visible and always scrollable, so the bound is the
                        // caller's, and it must travel with this call if it is
                        // ever moved.
                        nextVolume = Math.max(0, Math.min(1, nextVolume));
                        root.audioBackend.setMasterVolume(nextVolume);
                    }
                }
            }
        }

        HoverHandler {
            id: audioTriggerHoverHandler
            onHoveredChanged: root.reportAudioDrawerHover("trigger", audioTriggerHoverHandler.hovered)
        }
    }

    // ── brightness (18-12, QBAR-04, D-18-39) ────────────────────────────
    // Present-but-inert, gated on hardware presence: visible only when
    // BrightnessBackend.present reports a real device, contributing zero
    // extent and zero spacing otherwise — D-18-06's battery precedent
    // applied a second time, exactly as D-18-39 asks. On this host it
    // renders nothing (`/sys/class/backlight/` is empty). No greyed glyph,
    // no zero, no placeholder: absence here is honest, never a control
    // that looks live but cannot act.
    Readout {
        id: brightnessReadout
        visible: BrightnessBackend.present
        glyph: "brightness_medium"
        maxValueText: "100%"
        populated: true
        errored: BrightnessBackend.failed
        valueText: BrightnessBackend.percent + "%"

        // A second, separate scroll target from audio — the
        // Design.spacingSm gap the shared chrome inserts between entries
        // belongs to neither, so a gesture landing in the gap adjusts
        // nothing. Same shape as the audio handler above: no target, no
        // target property, angleDelta accumulated into whole notches. This
        // one does not read or clamp a percent itself — brightnessctl's
        // own delta forms own the bounds, which is the whole reason
        // BrightnessBackend.adjust() takes a signed notch count rather
        // than a computed absolute.
        WheelHandler {
            id: brightnessWheelHandler
            target: null

            property real pendingAngle: 0

            onWheel: (event) => {
                if (!BrightnessBackend.present)
                    return;
                brightnessWheelHandler.pendingAngle += event.angleDelta.y;
                const notchUnits = 120;
                let notchCount = 0;
                while (Math.abs(brightnessWheelHandler.pendingAngle) >= notchUnits) {
                    const direction = brightnessWheelHandler.pendingAngle > 0 ? 1 : -1;
                    brightnessWheelHandler.pendingAngle -= direction * notchUnits;
                    notchCount += direction;
                }
                if (notchCount !== 0)
                    BrightnessBackend.adjust(notchCount);
            }
        }
    }

    // ── group/connections (Phase 18.1 GATE-02 item (d)) ──────────────────
    // network is the trigger (always visible, click still opens
    // WifiPopout exactly as before); bluetooth moves from a flat top-level
    // entry into the hover-revealed strip (click still opens
    // BluetoothPopout, relocated verbatim). Same drawer contract shape as
    // group/audio above — see that section's header comment for the full
    // rationale, not repeated here.
    property bool _connTriggerHovered: false
    property bool _connStripHovered: false
    property bool connectionsDrawerHoverActive: false
    function reportConnectionsDrawerHover(source, entered) {
        if (source === "trigger")
            root._connTriggerHovered = entered;
        else if (source === "strip")
            root._connStripHovered = entered;
        root.connectionsDrawerHoverActive = root._connTriggerHovered || root._connStripHovered;
    }

    property bool connectionsDrawerExpanded: false
    function requestConnectionsDrawerExpand() {
        root.connectionsDrawerExpanded = true;
    }
    function requestConnectionsDrawerCollapse() {
        root.connectionsDrawerExpanded = false;
    }

    onConnectionsDrawerHoverActiveChanged: {
        if (root.connectionsDrawerHoverActive) {
            connectionsDrawerGraceTimer.stop();
            connectionsDrawerDwellTimer.restart();
        } else {
            connectionsDrawerDwellTimer.stop();
            connectionsDrawerGraceTimer.restart();
        }
    }

    Timer {
        id: connectionsDrawerDwellTimer
        interval: Design.barDrawerDwellMs
        repeat: false
        onTriggered: {
            if (root.connectionsDrawerHoverActive && root.drawerSettled)
                root.requestConnectionsDrawerExpand();
        }
    }
    Timer {
        id: connectionsDrawerGraceTimer
        interval: Design.popoutDismissGraceMs
        repeat: false
        onTriggered: {
            if (!root.connectionsDrawerHoverActive)
                root.requestConnectionsDrawerCollapse();
        }
    }

    // ── network ──────────────────────────────────────────────────────────
    // Glyph only, no value text, ever. Precedence: hardware radio blocked
    // or radio off (disabled); device unresolved-or-on-but-disconnected
    // (disconnected — the same glyph for both, the pointer's own header
    // comment records it "can take a moment to resolve after startup",
    // and an unresolved device reads to the user exactly like "no
    // connection yet"); connected, graded by strength across upstream's
    // own five-glyph ramp. No ethernet detection: WifiBackend resolves
    // only a WifiDevice (RESEARCH Pitfall 1), there is no ethernet
    // backend anywhere in this repo, and building one is out of this
    // plan's scope — a named delta, not a silent omission.
    readonly property bool wifiHwEnabled: root.wifiBackend ? root.wifiBackend.wifiHardwareEnabled : false
    readonly property bool wifiEnabled: root.wifiBackend ? root.wifiBackend.wifiEnabled : false
    readonly property var wifiDevice: root.wifiBackend ? root.wifiBackend.wifiDevice : null
    readonly property bool wifiDeviceConnected: root.wifiDevice ? root.wifiDevice.connected === true : false
    readonly property var wifiCurrentNetwork: root.wifiBackend ? root.wifiBackend.currentNetwork : null

    // Never sorts, never starts a scan: the strength bucket reads whatever
    // `currentNetwork` already holds (populated by a PAST scan, if any),
    // defaulting to full strength when it is null — correct with no scan
    // ever run, merely prettier after one (the same guarantee the former
    // opacity-based grading this replaces already made).
    readonly property var _wifiStrengthGlyphs: ["\u{f092f}", "\u{f091f}", "\u{f0922}", "\u{f0925}", "\u{f0928}"]

    readonly property string networkGlyph: {
        if (!root.wifiHwEnabled || !root.wifiEnabled)
            return "\u{f05aa}"; // md-wifi_off (format-disabled)
        if (!root.wifiDeviceConnected)
            return "\u{f092e}"; // md-wifi_strength_off_outline (format-disconnected)
        const net = root.wifiCurrentNetwork;
        if (!net || typeof net.signalStrength !== "number" || isNaN(net.signalStrength) || net.signalStrength < 0)
            return root._wifiStrengthGlyphs[root._wifiStrengthGlyphs.length - 1];
        const bucket = Math.max(0, Math.min(root._wifiStrengthGlyphs.length - 1, Math.floor(net.signalStrength * root._wifiStrengthGlyphs.length)));
        return root._wifiStrengthGlyphs[bucket];
    }

    // ── bluetooth ────────────────────────────────────────────────────────
    // Glyph only. No adapter, a blocked adapter and a present-but-off
    // adapter all render the SAME glyph — BluetoothPanel.qml's own three
    // branches (no-adapter/blocked/off) already do exactly this,
    // differentiated only by TEXT the panel shows and this capsule does
    // not carry; the reason-level distinction belongs to the bluetooth
    // popout (18-14), matching that established precedent.
    readonly property bool btPresent: root.bluetoothBackend ? root.bluetoothBackend.adapterPresent : false
    readonly property bool btBlocked: root.bluetoothBackend ? root.bluetoothBackend.adapterBlocked : false
    readonly property bool btEnabled: root.bluetoothBackend ? root.bluetoothBackend.adapterEnabled : false
    readonly property int btConnectedCount: root.bluetoothBackend ? root.bluetoothBackend.connectedDevices.length : 0

    readonly property string bluetoothGlyph: {
        if (!root.btPresent)
            return "\u{f00b2}"; // fa-bluetooth_b crossed / disabled
        if (root.btBlocked)
            return "\u{f00b2}";
        if (!root.btEnabled)
            return "\u{f00b2}";
        return root.btConnectedCount > 0 ? "\u{f00b1}" : "\u{f00af}"; // connected / rest
    }

    // ── The strip — bluetooth, revealed on hover. Declared BEFORE the
    //    network trigger for the same right-anchored-Grid reason
    //    group/audio's strip is declared before ITS trigger above (see
    //    that section's comment for the full Grid-arithmetic rationale):
    //    this keeps the network glyph's own screen position fixed while
    //    the reveal grows leftward out of it, matching upstream's
    //    `transition-left-to-right: false` for connections too
    //    (groups.jsonc). 500ms — Design.barDrawerTransitionFastMs,
    //    upstream's own connections-drawer transition-duration. ─────────
    Item {
        id: connectionsStripHost
        clip: true
        width: root.vertical ? root.drawerCellPitch : (root.connectionsDrawerExpanded ? root.connectionsStripExtent : 0)
        height: root.vertical ? (root.connectionsDrawerExpanded ? root.connectionsStripExtent : 0) : root.drawerCellPitch

        Behavior on width {
            enabled: Motion.motionEnabled
            NumberAnimation {
                duration: Design.barDrawerTransitionFastMs
                easing.type: Easing.BezierSpline
                easing.bezierCurve: root.connectionsDrawerExpanded ? Motion.emphasizedInEasing : Motion.emphasizedOutEasing
            }
        }
        Behavior on height {
            enabled: Motion.motionEnabled
            NumberAnimation {
                duration: Design.barDrawerTransitionFastMs
                easing.type: Easing.BezierSpline
                easing.bezierCurve: root.connectionsDrawerExpanded ? Motion.emphasizedInEasing : Motion.emphasizedOutEasing
            }
        }

        HoverHandler {
            id: connectionsStripHoverHandler
            onHoveredChanged: root.reportConnectionsDrawerHover("strip", connectionsStripHoverHandler.hovered)
        }

        Grid {
            anchors.fill: parent
            rows: root.vertical ? -1 : 1
            columns: root.vertical ? 1 : -1
            spacing: Design.spacingXs

            // ── Popout wrapper (Phase 18 Plan 14, QBAR-09) — relocated
            //    verbatim from its former flat top-level position into
            //    this drawer's strip by Phase 18.1 GATE-02 item (d);
            //    sectionId/popoutComponent/click-summon behaviour
            //    unchanged. ───────────────────────────────────────────
            PopoutTrigger {
                id: bluetoothPopoutTrigger
                sectionId: "bluetooth"
                popoutComponent: Component {
                    BluetoothPopout {
                        bluetoothBackend: root.bluetoothBackend
                    }
                }

                Readout {
                    glyph: root.bluetoothGlyph
                    glyphFontFamily: root.drawerGlyphFontFamily
                    showValue: false
                }
            }
        }
    }

    // ── Popout wrapper (Phase 18 Plan 14, QBAR-09) — named seam into this
    //    18-08-owned file. Ownership split, stated so it is never
    //    discovered at merge time: 18-08 owns the Readout's glyph and
    //    value bindings; this plan owns only the PopoutTrigger wrapper
    //    around it, matching 18-13's own audio-entry precedent exactly.
    //    Phase 18.1 GATE-02 item (d) adds exactly one more sibling inside
    //    this same wrapper — the HoverHandler feeding the connections
    //    drawer contract above — and switches the glyph set from
    //    Material Symbol ligatures to upstream's literal five-bar
    //    strength ramp; the entry order (network stays the trigger) is
    //    unchanged. ───────────────────────────────────────────────────
    PopoutTrigger {
        id: wifiPopoutTrigger
        sectionId: "wifi"
        popoutComponent: Component {
            WifiPopout {
                wifiBackend: root.wifiBackend
            }
        }

        Readout {
            glyph: root.networkGlyph
            glyphFontFamily: root.drawerGlyphFontFamily
            showValue: false
        }

        HoverHandler {
            id: connectionsTriggerHoverHandler
            onHoveredChanged: root.reportConnectionsDrawerHover("trigger", connectionsTriggerHoverHandler.hovered)
        }
    }

    // ── battery ──────────────────────────────────────────────────────────
    // Visible only when the native power singleton's display device is
    // non-null AND reports itself present — D-18-06 read literally. On
    // this host that condition is false and the entry contributes zero
    // extent and zero spacing. No new service connection: `UPower` is
    // already imported by `SystemResources.qml` elsewhere in this process.
    readonly property var batteryDevice: UPower.displayDevice
    readonly property bool batteryPresent: root.batteryDevice !== null
        && root.batteryDevice !== undefined
        && root.batteryDevice.isPresent === true

    readonly property string batteryGlyph: {
        if (!root.batteryPresent)
            return "";
        if (root.batteryDevice.state === UPowerDeviceState.Charging)
            return "battery_charging_full";
        if (root.batteryDevice.percentage <= 15)
            return "battery_alert";
        return "battery_full";
    }

    // Same above-1-is-a-percentage / at-or-below-1-is-a-fraction guard
    // SystemResources.qml's own `batteryFraction` uses, for the same
    // documented reason: the service's own docs never state the range.
    function batteryPercentValue() {
        if (!root.batteryPresent)
            return 0;
        const raw = root.batteryDevice.percentage;
        if (!isFinite(raw) || raw < 0)
            return 0;
        const frac = raw > 1 ? Math.min(1, raw / 100) : Math.min(1, raw);
        return Math.round(frac * 100);
    }

    Readout {
        visible: root.batteryPresent
        glyph: root.batteryGlyph
        maxValueText: "100%"
        populated: true
        valueText: root.batteryPercentValue() + "%"
    }
}
