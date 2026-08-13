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
import Quickshell.Networking
import "../"
import "../dashboard"

BarCapsule {
    id: root

    capsuleId: "mediaConnectivity"

    // Same uniform right-side pitch as ClockActionsCapsule — see its own note.
    // Left at the barCellGap (18) readout default, this capsule's glyphs sat at
    // a different pitch from the action glyphs a few pixels away, which is the
    // other half of the operator's "right side pills are spaced wrong".
    //
    // spacingSm (8) was tried and measured (Phase 18.1 spacing-probe task):
    // this capsule's Readout component carries NO internal padding around its
    // glyph (unlike ClockActionsCapsule's ActionCell, whose cellPitch bakes in
    // spacingXs (4) on each side), so a contentGap of 8 here rendered an 8px
    // glyph-to-glyph gap while ClockActionsCapsule's SAME contentGap of 8
    // rendered a 16px glyph-to-glyph gap (8 + 4 + 4, ActionCell's own padding
    // on both sides of the gap) — measured directly via mapToItem, not
    // estimated: media-to-audio and audio-to-network both sat at 8px while
    // gaming-to-bell and bell-to-settings both sat at 16px. spacingMd (16)
    // closes that gap: with zero internal padding to add, this capsule's
    // contentGap alone must equal the OTHER capsule's already-16px effective
    // pitch, not merely match its raw contentGap number.
    contentGap: Design.spacingMd

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
        // Numeric readouts stay AlignRight against a FIXED reserve so their
        // digits do not jitter as the value changes. A TITLE is not a number:
        // right-aligning it inside a reserve sized for 30 capital Ms parked the
        // text at the far right of that box while the glyph stayed at the left,
        // which is the operator's "the music glyph is so far to the left of the
        // now playing title". These two knobs let the media entry opt out
        // without changing any numeric readout.
        property int valueAlignment: Text.AlignRight
        property bool valueShrinks: false
        // -1 means "no vertical-specific cap" (the normal case).
        property real maxWidthVertical: -1
        // Opt-in, media only. In VERTICAL orientation, render the value as a
        // 90-degree-rotated line running DOWN the column instead of across it.
        // Every numeric readout leaves this false and is byte-for-byte
        // unchanged: a percentage is short enough to sit beside its glyph, and
        // rotating "47%" would be worse, not better. A track title is the one
        // value on this bar that is long, free-form and third-party, and it is
        // the only value for which the 44px width — not the bar's height — is
        // the binding constraint.
        property bool rotateValueVertical: false
        property real rotatedValueMaxRun: Design.mediaTitleVerticalRun
        // The rotated line shows the FULL value, not the horizontal bar's
        // 30-char capped form: the cap exists because a horizontal capsule
        // cannot grow, whereas here the window is fixed and the text scrolls
        // through it, so nothing needs cutting off. Defaults to valueText so
        // any future opt-in gets sane behaviour without setting it.
        property string rotatedValueText: readoutItem.valueText

        readonly property bool vertical: root.vertical

        // KNOWN RESIDUAL (2026-08-12), left at the simple binding on purpose.
        // Grid sizes columns from children's implicitWidth; the value Text's
        // implicitWidth is its natural extent ("0%" ~12) while its BOUND width is
        // the reserve for maxValueText ("100%" = 33). So this box reports 16 (the
        // glyph), BarCapsule's contentGrid centres a 16-wide slot, and brightness
        // and battery draw 33px of text out to right=47 in the 44px column.
        // Deriving this from entryGrid.childrenRect.width was tried and MEASURED:
        // it improved the overhang to right=45 but Qt reported "Binding loop
        // detected for property implicitWidth", so it was reverted — a loop is
        // worse than 3px. The real fix is for the value Text to reserve its width
        // through a property the Grid can see without a cycle.
        implicitWidth: entryGrid.implicitWidth
        implicitHeight: entryGrid.implicitHeight

        TextMetrics {
            id: valueReserve
            font.pixelSize: Design.barBodySize
            font.weight: Design.weightBody
            text: readoutItem.maxValueText
        }

        // The rendered text's own width, measured in the same font as the
        // reserve above. Used only by valueShrinks entries: it lets the cell hug
        // its content while still capping at the reserve, so a long title elides
        // at the cap and a short one sits right beside its glyph. Measured rather
        // than read off the Text's implicitWidth, which is unreliable once
        // `width` and `elide` are both set on that same element.
        // Natural extent of the ROTATED line, measured in its own font. A third
        // TextMetrics rather than reusing valueActual, because the rotated form
        // shows the full uncapped value while valueActual measures the capped
        // one — sizing the scroll window off the wrong string would either clip
        // a title early or scroll past its end.
        TextMetrics {
            id: rotatedMetrics
            font.pixelSize: Design.barBodySize
            font.weight: Design.weightBody
            text: readoutItem.rotatedValueText
        }

        TextMetrics {
            id: valueActual
            font.pixelSize: Design.barBodySize
            font.weight: Design.weightBody
            text: readoutItem.populated ? readoutItem.valueText : "—"
        }

        Grid {
            id: entryGrid
            rows: readoutItem.vertical ? -1 : 1
            columns: readoutItem.vertical ? 1 : -1
            spacing: Design.spacingXs
            // Same omission BarCapsule's own contentGrid carried, one level
            // down: without item alignment, Grid's AlignLeft/AlignTop defaults
            // left the stacked glyph and value rows sharing a leading edge.
            // MEASURED: brightness and battery reserve 33px for "100%" inside a
            // box whose implicitWidth is the 16px glyph, so both rows started at
            // x=14 and the value ran to right=47 — 3px past the 44px column.
            // Centring makes that overflow SYMMETRIC instead of one-sided
            // (x=5.5, right=38.5), which fits, and it centres the glyph row too.
            horizontalItemAlignment: Grid.AlignHCenter
            verticalItemAlignment: Grid.AlignVCenter

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
                horizontalAlignment: readoutItem.valueAlignment
                elide: readoutItem.elideValue ? Text.ElideRight : Text.ElideNone
                width: {
                    if (!readoutItem.showValue)
                        return 0;
                    var cap = readoutItem.vertical && readoutItem.maxWidthVertical >= 0
                        ? Math.min(valueReserve.width, readoutItem.maxWidthVertical)
                        : valueReserve.width;
                    return readoutItem.valueShrinks ? Math.min(valueActual.width, cap) : cap;
                }
                text: readoutItem.populated ? readoutItem.valueText : "—"
            }

            // The rotated vertical-orientation value (opt-in — media only).
            // Sized from the two TextMetrics above rather than from its own
            // Text: TextMetrics is not an Item and takes no part in layout, so
            // reading it cannot feed back into the Grid that positions this
            // host. That is the whole reason this shape is loop-free where
            // `entryGrid.childrenRect.width` and `Slider.availableWidth` both
            // looped in this same file — a measurement object has nothing
            // downstream of it to cycle through.
            //
            // The host carries the LAYOUT box (line height across the column,
            // title length down it) while the Text inside is rotated within
            // that box. A rotated Item still reports its unrotated width and
            // height to its parent positioner, so without this wrapper the Grid
            // would reserve the title's full horizontal length and blow the
            // 44px column apart.
            Item {
                id: rotatedValueHost
                visible: readoutItem.rotateValueVertical && readoutItem.vertical && readoutItem.populated && readoutItem.rotatedValueText !== ""
                clip: true
                width: visible ? rotatedMetrics.height : 0
                // The WINDOW, deliberately capped: a title longer than the cap
                // scrolls through this box rather than lengthening it. That is
                // what lets both UI-SPEC rules hold at once — E7 requires the
                // capsule extent not grow as the title changes, and the vertical
                // Orientation Transform rule requires no truncation. A static
                // line can satisfy either but never both; a fixed window with
                // moving text satisfies both.
                height: visible ? Math.min(rotatedMetrics.width, readoutItem.rotatedValueMaxRun) : 0

                // How much title does not fit the window. Zero for the common
                // case (a title shorter than the cap), which is what keeps the
                // animation below completely inert most of the time.
                readonly property real overflow: Math.max(0, rotatedMetrics.width - height)
                property real scroll: 0

                Text {
                    id: rotatedValueText
                    // +90, so the title reads top-to-bottom down the column
                    // rather than bottom-to-top, matching the reading direction
                    // of the bar's own entry order.
                    rotation: 90
                    width: rotatedMetrics.width
                    height: rotatedMetrics.height
                    // Rotation is about the item's centre, so placing the centre
                    // on the host's centre and then offsetting y slides the
                    // rotated line ALONG the column. At scroll = +overflow/2 the
                    // title's start is at the window's top edge; at -overflow/2
                    // its end is at the bottom.
                    x: (rotatedValueHost.width - width) / 2
                    y: (rotatedValueHost.height - height) / 2 + rotatedValueHost.scroll
                    font.pixelSize: Design.barBodySize
                    font.weight: Design.weightBody
                    color: root.contentColour
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    text: readoutItem.rotatedValueText
                }

                // Ping-pong scroll, and ONLY when there is something to scroll.
                // `running` is false whenever the host is hidden, motion is
                // disabled, or the title already fits — so a paused player or a
                // short track leaves no animation and no timer alive. That is
                // deliberate: QBAR-11 watches this surface for exactly the class
                // of "idle timers doing nothing" a always-on marquee would add.
                SequentialAnimation on scroll {
                    running: rotatedValueHost.visible && rotatedValueHost.overflow > 0 && Motion.motionEnabled
                    loops: Animation.Infinite
                    // LINEAR, not an ease. This is a marquee, not a transition:
                    // its job is to be legible while moving, and constant speed
                    // is what makes it readable. The first build used
                    // Easing.InOutQuad with a 650ms pause at each end, which
                    // measured as working (two screenshots 3.5s apart showed
                    // different thirds of the title) but read as BROKEN to the
                    // operator — an ease-in-out is nearly motionless either side
                    // of its turnaround, so those two slow tails plus the pause
                    // gave a ~2s window in every 13s cycle where nothing visibly
                    // happened. "It scrolls, you just have to catch it" is not a
                    // working marquee.
                    //
                    // 18ms per pixel of overflow ~= 55px/s, a readable scroll
                    // speed, and the pause is short enough that the head of the
                    // title is legible without the whole thing looking frozen.
                    PauseAnimation {
                        duration: Design.barDrawerGraceMs
                    }
                    NumberAnimation {
                        from: rotatedValueHost.overflow / 2
                        to: -rotatedValueHost.overflow / 2
                        duration: Math.max(1, rotatedValueHost.overflow) * 18
                        easing.type: Easing.Linear
                    }
                    PauseAnimation {
                        duration: Design.barDrawerGraceMs
                    }
                    NumberAnimation {
                        from: -rotatedValueHost.overflow / 2
                        to: rotatedValueHost.overflow / 2
                        duration: Math.max(1, rotatedValueHost.overflow) * 18
                        easing.type: Easing.Linear
                    }
                }
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
            // A title reads as a label beside its glyph, not as a right-aligned
            // figure — see valueAlignment/valueShrinks on the component above.
            valueAlignment: Text.AlignLeft
            valueShrinks: true
            maxValueText: "M".repeat(Design.mediaTitleMaxChars)
            maxWidthVertical: Design.barColumnWidth
            elideValue: true
            populated: true
            valueText: root.mediaTitleCapped
            // GLYPH ONLY in vertical — the title lives in MediaPopout there.
            // A track title cannot be shown in a 44px column, and UI-SPEC's
            // Orientation Transform Rules set the vertical acceptance bar at "no
            // truncation": entries re-stack to "glyph above short value, or glyph
            // beside an abbreviated value, whichever fits 44px WITHOUT
            // truncation". A capped-and-elided title fits the box but only by
            // truncating, which that bar excludes — the operator saw it as "the
            // media module is cropped".
            //
            // Network is the precedent the same spec names: it "deliberately
            // renders {icon} only (SSID in the popout)". Media now reads the same
            // way in vertical, and the popout is reachable exactly as before.
            // maxWidthVertical/elideValue above are retained rather than deleted:
            // they still bound the horizontal case, and they are the fallback if
            // showValue is ever re-enabled here.
            showValue: !root.vertical
            // 2026-08-13, operator: "the now playing module does not display the
            // title of what is playing". It did not, by the decision recorded
            // immediately above — and that decision was right about the
            // constraint and wrong about the only way out of it. A 44px column
            // fits ~5 characters ACROSS; it has ~1400px DOWN. Rotating the title
            // moves it onto the axis that has room, so it is shown in full with
            // no truncation, which is what UI-SPEC's vertical bar actually asks
            // for — the rule was "no truncation", not "no title".
            // The glyph-only fallback stays intact for every other vertical
            // entry, and MediaPopout still carries the full uncapped title.
            rotateValueVertical: true
            // The FULL title, not mediaTitleCapped: the 30-char cap exists so a
            // horizontal capsule cannot be stretched by a long title, and the
            // rotated form is bounded by its own fixed window instead. Feeding
            // the capped string here would elide a title twice — once at 30
            // chars, then again at the window — and scroll to an end that is not
            // the real end of the track name.
            rotatedValueText: root.mediaTitleRaw
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
    //    use for Athena's per-app/per-state glyphs), originally sourced
    //    from the retired bar's own config-athena.jsonc Athena config
    //    (cmap-verified against the installed font per that now-deleted
    //    file's own comments, RETIRE-02/18-20) — and cross-checked
    //    against ATHENA-UPSTREAM-SPEC.md. The two sources disagreed on
    //    which wifi glyph is "disconnected" vs "disabled"; the retired
    //    config's own format-disconnected/format-disabled KEY NAMES
    //    settled it
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
    // The bluetooth glyph's OWN natural width, not drawerCellPitch (24).
    // Measured 2026-08-12 (temporary GAPPROBE, removed before this commit):
    // with a 24px box around a 10.84px glyph, the visible gaps across the
    // expanded row ran 16.00 (audio strip -> volume), 29.16 (volume ->
    // bluetooth), 16.00 (bluetooth -> network). The 13.16px excess is the
    // box's dead space. Phase 18.1 had anchored the trigger to this box's
    // trailing edge to close the bluetooth->network side, which fixed that
    // gap by moving the dead space to the LEADING side rather than removing
    // it — so the defect reappeared on the other side of the same glyph,
    // which is what the operator then reported.
    //
    // The 24px box was justified as "the same touch/hover padding every
    // other bar glyph gets". That premise is false, and the same
    // measurement disproves it: audioPopoutTrigger renders 12.84 wide and
    // wifiPopoutTrigger 14.84 — both their glyphs' natural widths, neither
    // padded to a 24px cell. Binding to the trigger's own implicitWidth
    // makes this glyph match its neighbours on BOTH sides at once, and
    // makes its hover target the same size as theirs rather than twice it.
    // `real`, not `int`: the glyph's implicitWidth is 10.84 and an int
    // truncates it to 10, leaving the right-anchored glyph overhanging its
    // own box by 0.84 and the gap measuring 15.16 instead of 16.00.
    readonly property real connectionsStripExtent: bluetoothPopoutTrigger.implicitWidth

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
        interval: Design.barDrawerGraceMs
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
        // Phase 18.1 trigger-shift fix, measured via mapToItem (temporary
        // MCCPROBE, removed before this commit): in horizontal orientation
        // this host's height was root.drawerCellPitch (24) UNCONDITIONALLY,
        // wider than audioPopoutTrigger's own rendered height (its glyph
        // Text's natural metrics, measured 20) — and BarCapsule's outer
        // content Grid (rows:1 in horizontal) excludes a ZERO-WIDTH item
        // from its row-height max entirely (confirmed live: contentGrid.
        // implicitHeight measured 20 while this host, at width 0, still
        // reported height 24 the same instant), but counts it once width
        // becomes nonzero on hover. That is what silently grew the row from
        // 20 to 24 and shifted every glyph in it upward by (24-20)/2 = 2px
        // — reproducible on every hover, invisible in the code, only
        // visible by measuring mid-transition. Pinning this host's height
        // to the trigger's OWN live height (rather than the unrelated
        // drawerCellPitch token) removes the mismatch structurally: with
        // both values equal, the row's height max cannot change no matter
        // which items the Grid quirk does or doesn't count.
        height: root.vertical ? (root.audioDrawerExpanded ? root.audioStripExtent : 0) : audioPopoutTrigger.height

        // GATE-02 round 4: a GTK Revealer slide is one ease-out curve, both
        // directions, not this repo's semantic-motion emphasizedIn/Out
        // bezier pair — see Design.barDrawerEasingType's own provenance
        // comment. 650ms — Design.barDrawerTransitionMs, upstream's own
        // audio-drawer transition-duration (groups.jsonc), unchanged.
        Behavior on width {
            enabled: Motion.motionEnabled
            NumberAnimation {
                duration: Design.barDrawerTransitionMs
                easing.type: Design.barDrawerEasingType
            }
        }
        Behavior on height {
            enabled: Motion.motionEnabled
            NumberAnimation {
                duration: Design.barDrawerTransitionMs
                easing.type: Design.barDrawerEasingType
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
                // Pinned to audioStripHost's own height (see that property's
                // comment) rather than drawerCellPitch, so this content fills
                // its host exactly instead of overflowing a shorter box under
                // clip:true.
                height: root.vertical ? root.audioSliderLength : audioStripHost.height
                orientation: root.vertical ? Qt.Vertical : Qt.Horizontal
                from: 0
                to: 1
                value: root.audioBackend ? root.audioBackend.masterVolume : 0
                onMoved: {
                    if (root.audioBackend)
                        root.audioBackend.setMasterVolume(Math.max(0, Math.min(1, audioVolumeSlider.value)));
                }

                background: Rectangle {
                    // MEASURED 2026-08-12: in vertical the 4px track sat at
                    // x=10 (centre 12) while the handle centred at 22 — the knob
                    // rendered 10px right of its own groove, which the operator
                    // reported as "the expanded volume slider is shifted to the
                    // right". leftPadding is the correct origin for a HORIZONTAL
                    // track; a vertical one must centre across the slider's width.
                    // KNOWN RESIDUAL (2026-08-12): in vertical the 4px track sits
                    // at x=10 (centre 12) while the handle centres at 22, so the
                    // knob renders ~10px right of its groove — the operator's "the
                    // expanded volume slider is shifted to the right". Two fixes
                    // were tried and MEASURED: centring on the Slider's width put
                    // the track at x=24 (still off, the Slider is wider than its
                    // 24px host), and centring on availableWidth aligned handle and
                    // track at 26 but introduced "Binding loop detected for property
                    // implicitWidth" in PopoutTrigger.qml — availableWidth feeds back
                    // through the strip-extent chain. Reverted: a loop is worse than
                    // the offset. The fix needs a reference that does not depend on
                    // the Slider's own resolved width.
                    // FIXED 2026-08-13. MEASURED before the change: host x=10.0
                    // w=24.0 (centre 22.0 — the 44px column's own centre, so the
                    // strip was never the thing off-centre), track x=10.0 w=4.0
                    // centre 12.0, handle x=16.0 w=12.0 centre 22.0. One cause,
                    // both reported symptoms: `leftPadding` (0) is the correct
                    // ORIGIN for a horizontal track and wrong for a vertical one,
                    // so the groove sat flush left at centre 12 while the handle
                    // correctly centred at 22. The operator's "the expanded volume
                    // bar is not centered" is this track; their "weird dot to its
                    // right" is that correctly-placed 12px round handle, 10px clear
                    // of its own groove.
                    //
                    // The reference here is `root.drawerCellPitch`, which IS this
                    // Slider's width in vertical (see `width:` above) but is reached
                    // as a plain token pair — Design.barGlyphSize + spacingXs * 2 —
                    // never through the Slider's own resolved geometry. That is what
                    // separates it from the reverted attempt: `availableWidth` feeds
                    // back through the strip-extent chain into PopoutTrigger's
                    // childrenRect sizing and looped; two constants cannot depend on
                    // anything downstream of them. Verified 0 binding loops after.
                    x: root.vertical ? (root.drawerCellPitch / 2 - width / 2) : audioVolumeSlider.leftPadding
                    y: audioVolumeSlider.topPadding + audioVolumeSlider.availableHeight / 2 - height / 2
                    width: root.vertical ? 4 : audioVolumeSlider.availableWidth
                    height: root.vertical ? audioVolumeSlider.availableHeight : 4
                    radius: 2
                    color: BarRoles.capsuleTrack

                    Rectangle {
                        // `position`, NOT `visualPosition`, on the vertical axis.
                        // Qt defines visualPosition as 1.0 - position whenever the
                        // control is mirrored OR orientation is Qt.Vertical, so a
                        // vertical fill written against visualPosition renders the
                        // INVERSE of the volume: full at 0%, empty at 100%. The
                        // horizontal branch keeps visualPosition, where it is the
                        // correct RTL-aware value and equals position under LTR.
                        // See the handle below, which had the mirrored form of the
                        // same bug (2026-08-13, operator: "dragging the slider
                        // makes it move opposite to where I am dragging it").
                        anchors.bottom: root.vertical ? parent.bottom : undefined
                        width: root.vertical ? parent.width : audioVolumeSlider.visualPosition * parent.width
                        height: root.vertical ? audioVolumeSlider.position * parent.height : parent.height
                        radius: parent.radius
                        color: BarRoles.accent
                    }
                }
                handle: Rectangle {
                    x: root.vertical
                        ? (audioVolumeSlider.leftPadding + audioVolumeSlider.availableWidth / 2 - width / 2)
                        : (audioVolumeSlider.leftPadding + audioVolumeSlider.visualPosition * (audioVolumeSlider.availableWidth - width))
                    // `visualPosition` directly — NOT `1 - visualPosition`. Qt
                    // already inverts visualPosition for a vertical orientation
                    // (it is defined as 1.0 - position when mirrored or vertical),
                    // so subtracting it from 1 a second time cancels that out and
                    // yields `position` — putting the knob at the BOTTOM at 100%
                    // and at the top at 0%, while the drag gesture moved it the
                    // other way. That double inversion is the operator's "dragging
                    // the slider makes it move opposite to where I am dragging it"
                    // (2026-08-13). The fill Rectangle above carried the same bug
                    // in mirror image and is corrected with it; the two must always
                    // be read against the same convention or the knob and its own
                    // groove disagree.
                    y: root.vertical
                        ? (audioVolumeSlider.topPadding + audioVolumeSlider.visualPosition * (audioVolumeSlider.availableHeight - height))
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
                // Height only (not width — width still feeds
                // audioStripExtent's WIDTH reservation, untouched by this
                // fix) pinned to audioStripHost's own height in horizontal
                // orientation, same reasoning as the slider above; vertical
                // orientation is unaffected (root.drawerCellPitch there is
                // the CROSS-axis dimension, not the one this bug lives in).
                height: root.vertical ? root.drawerCellPitch : audioStripHost.height

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
                }

                // F2 (quick task 260812-69w) — see IdleInhibitorCapsule.qml's
                // own comment for the measured clamp this replaces.
                BarTooltipHost {
                    anchorItem: audioMicCell
                    text: (root.audioBackend && root.audioBackend.inputMuted) ? "Unmute microphone" : "Mute microphone"
                    active: audioMicMouseArea.containsMouse
                    tipId: "mediaConnectivity-mic"
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
        interval: Design.barDrawerGraceMs
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
        // Same fix and same reasoning as audioStripHost's own comment above
        // (Phase 18.1 trigger-shift fix, measured via mapToItem): pinned to
        // wifiPopoutTrigger's own live height instead of the unrelated
        // drawerCellPitch token, so BarCapsule's outer content Grid never
        // sees a taller row once this host's width goes nonzero on hover.
        // The bluetooth Readout nested inside this host already renders at
        // that same natural glyph height with no override, so shrinking
        // this host to match introduces no clipping.
        height: root.vertical ? (root.connectionsDrawerExpanded ? root.connectionsStripExtent : 0) : wifiPopoutTrigger.height

        // GATE-02 round 4: a GTK Revealer slide is one ease-out curve, both
        // directions — see Design.barDrawerEasingType's own provenance
        // comment (audioStripHost above carries the full rationale).
        Behavior on width {
            enabled: Motion.motionEnabled
            NumberAnimation {
                duration: Design.barDrawerTransitionFastMs
                easing.type: Design.barDrawerEasingType
            }
        }
        Behavior on height {
            enabled: Motion.motionEnabled
            NumberAnimation {
                duration: Design.barDrawerTransitionFastMs
                easing.type: Design.barDrawerEasingType
            }
        }

        HoverHandler {
            id: connectionsStripHoverHandler
            onHoveredChanged: root.reportConnectionsDrawerHover("strip", connectionsStripHoverHandler.hovered)
        }

        // Plain Item, not a Grid — this strip only ever holds the ONE
        // bluetooth trigger (unlike audioStripHost's slider+mic pair, which
        // genuinely needs a positioner to arrange two siblings), so a Grid
        // here bought nothing but inherited that pattern's LEFT-alignment
        // default. Phase 18.1 gap-tightening fix, measured via mapToItem
        // (temporary MCCPROBE, removed before this commit): connectionsStripExtent
        // then reserved a full drawerCellPitch (24) box, justified as keeping
        // "the same touch/hover padding every other bar glyph gets".
        // SUPERSEDED 2026-08-12 — that justification was false and a later
        // measurement disproved it: audioPopoutTrigger renders 12.84 wide and
        // wifiPopoutTrigger 14.84, both natural glyph widths with no 24px
        // cell. connectionsStripExtent now binds to the trigger's own
        // implicitWidth, so all three gaps across the expanded row measure
        // 16.00. The paragraph below describes the 18.1 state, kept because
        // the right-edge anchor it introduced is still what holds the
        // bluetooth->network side at 16 — but the former Grid always
        // places its one child flush at the box's OWN (0,0), i.e. the
        // LEADING edge. With this box's own edge (not its content) already
        // sitting exactly barCapsuleGap-pitch (16px) before the network
        // trigger — confirmed by measuring this host's own right edge
        // against wifiPopoutTrigger's left edge — a glyph only 10.84px wide
        // left-aligned in a 24px box left 13.16px of invisible padding
        // BETWEEN the visible glyph and that already-correct 16px gap,
        // reading as a ~29px gap overall (measured: bt glyph right edge
        // 2250.68 to net left edge 2279.84). Anchoring the trigger to this
        // box's OWN trailing edge instead — right in horizontal orientation,
        // where the strip is declared to grow leftward out of a fixed
        // network trigger (see this file's own header comment on that
        // declaration order) — makes the VISIBLE glyph, not just the box,
        // flush against the boundary the 16px pitch is measured from.
        // Vertical orientation is untouched: no anchor override there, so
        // an unanchored child still renders at its parent's origin (0,0),
        // byte-identical to the Grid's own former top-left default.
        Item {
            anchors.fill: parent

            // ── Popout wrapper (Phase 18 Plan 14, QBAR-09) — relocated
            //    verbatim from its former flat top-level position into
            //    this drawer's strip by Phase 18.1 GATE-02 item (d);
            //    sectionId/popoutComponent/click-summon behaviour
            //    unchanged. ───────────────────────────────────────────
            PopoutTrigger {
                id: bluetoothPopoutTrigger
                sectionId: "bluetooth"
                // Explicit x/y, NOT conditional anchors cleared with `undefined`.
                // The comment above claimed vertical was "untouched: no anchor
                // override there, so an unanchored child still renders at its
                // parent's origin (0,0)" — that is false, because assigning
                // `undefined` to an anchor line from inside a binding does not
                // reliably clear it. The right anchor therefore stayed live in
                // vertical and MEASURED at x=-10.8 right=0.0: the glyph rendered
                // entirely left of the column and the host's clip:true erased it,
                // which is the operator's "wifi expansion does not reveal
                // bluetooth". The reveal was working; its content was off-surface.
                //
                // Same failing idiom found the same day in Bar.qml's zone
                // containers, where verticalCenter surviving alongside top/bottom
                // made Qt derive a full-height Grid. Explicit x/y cannot
                // half-apply: trailing edge horizontally (what the 16px pitch is
                // measured from, per the comment above), centred vertically.
                x: root.vertical ? (parent.width - width) / 2 : (parent.width - width)
                y: (parent.height - height) / 2
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

    // ── ethernet ─────────────────────────────────────────────────────────
    // Visible only while a WIRED device reports itself connected, mirroring
    // the battery entry's own conditional-entry idiom below: when false the
    // entry contributes zero extent and zero spacing, so the collapsed row
    // reads exactly as it did before this entry existed.
    //
    // Read from `Networking.devices` — the same passive NetworkManager
    // device list `WifiBackend.qml` already consumes, so this adds NO new
    // service connection and touches neither backend's scan/discovery path,
    // which this file's own header forbids widening. `type` and `connected`
    // are live D-Bus properties; nothing here polls and nothing spawns.
    //
    // Measured on this host 2026-08-12 (temporary ETHPROBE, removed before
    // this commit) rather than assumed, because the obvious alternative is a
    // trap: /sys/class/net reports SIX type=1 interfaces here — eno1 plus
    // docker0, three br-* bridges and a veth — so a /sys-based check would
    // read "ethernet connected" permanently on this machine. NetworkManager
    // already filters those out: `Networking.devices` contains exactly two
    // entries, eno1 (type 2 = Wired) and wlan0 (type 1 = Wifi).
    //
    // The same probe caught the other trap: `managed` is UNDEFINED on this
    // Quickshell build — only `nmManaged` exists — so a predicate written
    // against `managed` would have been falsy forever and this glyph would
    // never once have appeared. It is deliberately not referenced here.
    // Resolved to the DEVICE rather than to a boolean (operator request,
    // 2026-08-12): EthernetPopout.qml needs the object itself to read `name`,
    // `linkSpeed`, `hasLink` and `address` off it. `ethernetConnected` below is
    // now derived from this single resolution rather than walking the model a
    // second time, so the glyph's visibility and the card's contents can never
    // disagree about which device they mean. Same filtered-access shape
    // WifiBackend.qml's own `wifiDevice` uses (RESEARCH Pitfall 1); `null` is
    // an ordinary value, never an error.
    readonly property var ethernetDevice: {
        const devs = Networking.devices;
        if (!devs || !devs.values)
            return null;
        const vals = devs.values;
        for (let i = 0; i < vals.length; i++) {
            const d = vals[i];
            if (d && d.type === DeviceType.Wired && d.connected === true)
                return d;
        }
        return null;
    }

    readonly property bool ethernetConnected: root.ethernetDevice !== null

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

    // Declared AFTER wifiPopoutTrigger so it renders to the RIGHT of the
    // network glyph (operator's placement choice, 2026-08-12; it sat to the
    // left when first added). Position only — the predicate, glyph and
    // zero-extent-when-hidden behaviour are unchanged.
    //
    // U+F0200 is MDI `ethernet` in the Nerd Font range — a literal
    // codepoint, NOT a Material Symbols ligature, matching the network
    // entry's own five-bar ramp above and deliberately avoiding the failure
    // mode GATE-02 row A.3 names (a nonexistent ligature renders as its own
    // name in plain text). Coverage confirmed with fc-list against the
    // capsule's own drawerGlyphFontFamily (FiraCode Nerd Font) before use.
    // Wrapped in a PopoutTrigger (operator request, 2026-08-12): this shipped
    // as a bare Readout, so it was the one glyph in this capsule whose click
    // did nothing while its immediate neighbour opened a full card. The
    // wrapper is the ONLY addition — the predicate, the glyph, the font and
    // the zero-extent-when-hidden behaviour are all unchanged, and `visible`
    // moves onto the trigger so a hidden entry still contributes no extent and
    // cannot be hovered into summoning a card for an absent device.
    //
    // No HoverHandler here, deliberately, unlike wifiPopoutTrigger above: that
    // one feeds the connections drawer's reveal contract, and the drawer's
    // extent is measured off bluetoothPopoutTrigger's own width. Adding a
    // second hover reporter for a conditional entry would make that measured
    // extent depend on whether a cable is plugged in.
    PopoutTrigger {
        id: ethernetPopoutTrigger
        visible: root.ethernetConnected
        sectionId: "ethernet"
        popoutComponent: Component {
            EthernetPopout {
                ethernetDevice: root.ethernetDevice
            }
        }

        Readout {
            glyph: "\u{f0200}"
            glyphFontFamily: root.drawerGlyphFontFamily
            showValue: false
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
