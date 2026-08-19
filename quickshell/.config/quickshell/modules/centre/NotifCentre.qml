// NotifCentre.qml — the right-edge slide-out notification centre (Phase 19
// Plan 06, D-19-14..18/23, QNOTIF-06). The third top-level frame in this
// shell, after `PanelDialog.qml`/`SectionPopout.qml` — D-19-14's own
// "costly reversibility" record. Sibling of the bar and the popup stack,
// mounted unconditionally at shell.qml's root (never behind a LazyLoader):
// history and do-not-disturb must never depend on this window's own
// existence, matching `NotifPopupStack`/`Toast`'s own always-on posture.
//
// ── Summon ownership (D-19-16) ───────────────────────────────────────────
// `NotifServer.centreOpen` (a plain externally-writable bool, already
// declared by Plan 19-05's own NotifServer.qml, deliberately left
// unbound "until Plan 19-06's own centre surface binds it") is the SOLE
// source of truth this file reads for its own visibility — `offsetScale`
// below is a pure function of it, never a locally-owned duplicate. Every
// summon path (this plan's bell repoint and Super+N in shell.qml/
// ClockActionsCapsule.qml) flips that SAME property via
// `NotifServer.openCentre()` (already existing — clears the popup stack
// per D-19-37) to open, and a direct `NotifServer.centreOpen = false`
// write to close. This choice deliberately avoids editing NotifServer.qml
// or Bar.qml (both out of this plan's own `files_modified`) for a
// mediator: `centreOpen` was already public and already documented as the
// binding point this plan was expected to use, so extending its role from
// "read by the centre" to "read AND toggled by every summon path" needs
// no new file and no new property — the suppression predicate it already
// feeds is unaffected either way.
//
// ── D-19-23 one-property slide/fade (RESEARCH.md Pattern 4, verbatim) ────
// `offsetScale` (0 = fully open, 1 = fully closed) drives BOTH the right
// margin and the opacity in lockstep through exactly ONE `Behavior` —
// never two behaviours on two properties, which is how position and fade
// drift apart at the ends of the curve. `visible: offsetScale < 1` is what
// stops this surface rendering once fully closed (the zero-idle-when-
// closed discipline this shell already holds every other dismissible
// surface to).
//
// ── GATE-02 gap-closure supersession of D-19-18 ──────────────────────────
// D-19-18's ORIGINAL text (kept here for the record, no longer this file's
// behaviour) specified `WlrKeyboardFocus.None` and no focus grab at all,
// deliberately forgoing click-outside dismissal as an accepted tradeoff.
// Live GATE-02 testing on the real desktop found this genuinely
// unusable: the user expects click-away AND Escape to close the centre,
// matching every other summonable surface in this shell (the dashboard
// drawer, the audio/wifi/bluetooth panels), and reported it as a defect,
// not a tradeoff they'd accept. This supersedes D-19-18 by direct
// instruction relayed through the same GATE-02 review this plan's own
// render gate answers to — implemented by adopting the IDENTICAL,
// already-proven pattern `PanelDialog.qml`/`Dashboard.qml` use:
// `WlrKeyboardFocus.OnDemand` + a `HyprlandFocusGrab` bound to this
// window's own open/close state, `content.forceActiveFocus()` on
// completion, and `Keys.onEscapePressed` — not a novel mechanism.
//
// The honest cost, stated rather than hidden: while the centre is open,
// this surface DOES now hold keyboard focus (on demand), so typing does
// NOT continue to reach whatever application was focused before it
// opened — the literal opposite of D-19-18's original promise. No
// pointer-only click-outside mechanism exists anywhere in this shell's
// own established vocabulary (Hyprland's focus-grab extension is the
// only click-away detector this codebase uses anywhere, and it is a
// combined pointer+keyboard grab, not a pointer-only one) — this is the
// "genuine conflict" GATE-02's own review anticipated, and the tradeoff
// was resolved in favour of matching this shell's other panels rather
// than inventing an unproven pointer-only mechanism on the user's live
// desktop.
import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "../"
import "../dashboard"
import "../bar"
import "../notifications"

PanelWindow {
    id: centreWindow

    // ── Backend seams (Task 3, D-19-20/21) — threaded down to CentreFooter
    //    -> QuickToggles exactly as shell.qml threads them into Dashboard.
    //    Declared here (Task 1) so the wiring in Task 3 is a drop-in
    //    property assignment on the existing instantiation. ───────────────
    property var audioBackend: null
    property var wifiBackend: null
    property var bluetoothBackend: null
    // Quick task 260819-6oy — the News tab's feed-fetcher seam, same shape
    // as the three above. Wired from shell.qml's own NewsBackend instance
    // (mounted in modules/dashboard/, gated on NotifServer.centreOpen at
    // its own mount site — no second gate here).
    property var newsBackend: null

    // ── 15-07 chevron relay, third hop (GATE-02 round 11) — mirrors
    //    Dashboard.qml's own `panelRequested` exactly, so shell.qml can
    //    terminate both on the SAME single guarded `openPanel(name)`.
    signal panelRequested(string name)

    // ── Summon verbs — see header. `open()` reuses NotifServer's own
    //    existing D-19-37 popup-clear verb rather than duplicating it;
    //    `close()` is the one new write path this file introduces. ───────
    function open() {
        NotifServer.openCentre();
    }
    function close() {
        NotifServer.centreOpen = false;
    }
    function toggle() {
        if (NotifServer.centreOpen)
            centreWindow.close();
        else
            centreWindow.open();
    }

    property real offsetScale: NotifServer.centreOpen ? 0 : 1
    visible: centreWindow.offsetScale < 1

    Behavior on offsetScale {
        enabled: Motion.motionEnabled
        NumberAnimation {
            duration: NotifServer.centreOpen ? Motion.emphasizedInDuration : Motion.emphasizedOutDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: NotifServer.centreOpen ? Motion.emphasizedInEasing : Motion.emphasizedOutEasing
        }
    }

    // ── Grouping and ordering (Task 2, D-19-26/27) — the ONE place
    //    per-app grouping happens; `NotifGroup.qml` is a pure view over
    //    each resulting entry. Recomputed whenever `NotifServer.history`
    //    changes; groups sorted by most-recent activity, newest at top —
    //    never alphabetical, per D-19-27's own explicit rejection of that
    //    ordering. Items within a group inherit `history`'s own
    //    newest-first order with no re-sort of their own. ─────────────────
    readonly property var groupedHistory: {
        var byApp = {};
        var order = [];
        var hist = NotifServer.history;
        for (var i = 0; i < hist.length; i++) {
            var item = hist[i];
            var key = item.appName || "";
            if (!byApp.hasOwnProperty(key)) {
                byApp[key] = { appName: key, items: [], latest: 0 };
                order.push(key);
            }
            byApp[key].items.push(item);
            if (item.timestamp > byApp[key].latest)
                byApp[key].latest = item.timestamp;
        }
        var groups = order.map(function (k) {
            return byApp[k];
        });
        groups.sort(function (a, b) {
            return b.latest - a.latest;
        });
        return groups;
    }

    // ── Per-group expand state (D-19-26's chevron) — keyed by appName,
    //    survives `groupedHistory`'s own recomputation (which produces
    //    brand-new group objects on every history change) since this map
    //    is a SEPARATE property, never derived from the grouped list
    //    itself. A group that empties simply stops appearing in
    //    `groupedHistory` — D-19-26's "auto-collapses when it empties" is
    //    therefore a structural consequence of the grouping above, not a
    //    branch this map has to implement. ───────────────────────────────
    property var expandedApps: ({})
    function toggleGroupExpanded(appName) {
        var next = Object.assign({}, centreWindow.expandedApps);
        next[appName] = !next[appName];
        centreWindow.expandedApps = next;
    }

    // ── One shared clock for every relative timestamp in the centre
    //    (D-19-32, QBAR-11) — a single interval reading feeding every
    //    `NotifGroup` delegate's own `nowMs` property, never one polling
    //    element per row. 30 seconds is well under the coarsest bucket
    //    ("now" for <60s) this centre ever renders, so no visible label
    //    ever drifts stale by more than that margin. ───────────────────
    property real _sharedClockNow: Date.now()
    Timer {
        id: _sharedClock
        interval: 30000
        running: centreWindow.visible
        repeat: true
        onTriggered: centreWindow._sharedClockNow = Date.now()
    }

    // ── Layer posture ─────────────────────────────────────────────────
    // GATE-02 gap-closure fix (round 4, item 6) — previously top:true/
    // bottom:true with ZERO top/bottom margin, spanning the full 1440px
    // monitor height edge-to-edge. Measured live against a real tiled
    // window on this monitor (`hyprctl clients -j`, DP-1 2560x1440,
    // reserved [0,0,50,0] for the bar's right-edge exclusion): a tiled
    // client sits at (13,13) size (2484,1414) — i.e. inset exactly 13px
    // from every edge (gaps_out=10 + border_size=3, hyprland.lua, and
    // Hyprland's own reported client geometry includes the border), and
    // its right edge (13+2484=2497) sits 13px inside the reserved
    // boundary (2560-50=2510) — the SAME 13px, not the reserved
    // boundary itself. `centreTopBottomInset`/`centreRightGapInset`
    // below are that measured 13, applied on all three non-slide edges
    // so the centre's own edges land exactly where a real window's do,
    // never a value re-derived from a different surface's own constant
    // (PanelDialog.qml's unrelated panelTopMargin=10 was deliberately
    // NOT reused here — it answers a different question, a floating
    // dialog's own top gap, not this edge-to-edge sidebar's alignment
    // against tiled windows).
    readonly property int centreTopBottomInset: 13
    readonly property int centreRightGapInset: 13
    anchors {
        top: true
        bottom: true
        right: true
    }
    implicitWidth: Design.notifSurfaceWidth
    margins.top: centreWindow.centreTopBottomInset
    margins.bottom: centreWindow.centreTopBottomInset
    margins.right: centreWindow.centreRightGapInset + (-centreWindow.implicitWidth - 5) * centreWindow.offsetScale
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-notif-centre"
    // GATE-02 supersession of D-19-18 — see this file's own header.
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    color: "transparent"

    // ── Click-outside dismissal (GATE-02 supersession of D-19-18) ───────
    // The SAME `HyprlandFocusGrab` shape `PanelDialog.qml`/`Dashboard.qml`
    // already use, bound to this window's own open/close state rather
    // than `active: true` — those two are destroyed on dismiss (a fresh
    // grab every time), this window is permanent (D-19-14), so the grab
    // itself must toggle instead.
    HyprlandFocusGrab {
        id: centreFocusGrab
        windows: [centreWindow]
        active: NotifServer.centreOpen
        onCleared: centreWindow.close()
    }

    // ── Chrome — same visual family as the popup card and toast
    //    (BarRoles.notifSurface, GradientBorder rim, D-19-43's routing
    //    rule: never a direct Colours.* reference). GATE-02 gap-closure
    //    fix (round 4, item 6) — all four corners now round uniformly.
    //    The previous left-only rounding assumed top/bottom/right were
    //    screen-flush (true when this frame spanned the full monitor
    //    height with zero right-edge gap); now that every edge carries
    //    the same measured inset a real tiled window has, all four
    //    corners sit away from the screen boundary exactly like a real
    //    window's own rounded corners (hyprland.lua's own `rounding`),
    //    so a flush corner would look like a mistake, not a design
    //    choice. ─────────────────────────────────────────────────────
    Rectangle {
        id: background
        anchors.fill: parent
        radius: Design.popoutCornerRadius
        color: BarRoles.notifSurface
    }

    GradientBorder {
        anchors.fill: parent
        borderWidth: Design.borderWidth
        // GradientBorder has no uniform `radius` shorthand (per-corner only
        // — see its own header comment) — all four set to match the
        // Rectangle above's now-uniform rounding.
        topLeftRadius: Design.popoutCornerRadius
        topRightRadius: Design.popoutCornerRadius
        bottomLeftRadius: Design.popoutCornerRadius
        bottomRightRadius: Design.popoutCornerRadius
    }

    Item {
        id: content
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: centreWindow.close()
        Component.onCompleted: content.forceActiveFocus()

        // ── Header band (D-19-17/28) — live count, left; clear-all icon
        //    button, right, scaling and fading in only when count > 0. ────
        Item {
            id: header
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: Design.popoutHeaderHeight

            // ── Tab bar (quick task 260819-6oy) — REPLACES the count
            //    capsule that used to live here. Two tabs inside the
            //    EXISTING header band: no vertical space added,
            //    historyRegion keeps its exact height (it moves into the
            //    pager below with its geometry carried, not changed). The
            //    notification count folds into tab 0's own label instead
            //    of a separate capsule — see the removal note beside the
            //    deleted pluralisation binding, further down, for the one
            //    thing this move deliberately does NOT preserve. ─────────
            ListModel {
                id: tabModel
                ListElement {
                    label: "Notifications"
                    glyph: "notifications"
                }
                ListElement {
                    label: "News"
                    glyph: "newspaper"
                }
            }

            TabBar {
                id: tabBar
                anchors.left: parent.left
                anchors.leftMargin: Design.spacingMd
                anchors.right: actionSlot.left
                anchors.rightMargin: Design.spacingSm
                anchors.verticalCenter: parent.verticalCenter
                // Deliberately no height/implicitHeight override: every
                // TabButton delegate below is content-hugging (no
                // cross-reference to tabBar's/header's own width the way
                // Dashboard.qml's per-tab `header.width / tabCount`
                // division needed one), so there is no comparable binding-
                // loop risk to work around — Control's own default
                // (contentItem's natural implicit height) is genuinely
                // content-derived, never the 48px band height, and the
                // band itself never grows.

                // One-way sync target (D-16's own precedent, copied
                // verbatim from Dashboard.qml): this binding holds until a
                // TabButton click imperatively re-assigns currentIndex
                // (Container's own internal click handling) — the
                // Connections block on `pager` (declared below, beside the
                // pager itself) re-asserts it on every pager change so the
                // flow stays one-way for the surface's whole lifetime, not
                // just until the first tap.
                currentIndex: pager.currentIndex

                background: Item {}

                // Dashboard.qml:790-800's mandated override — a plain
                // non-flickable Row over contentModel, NOT the stock
                // ListView-based contentItem. A flickable header inside a
                // horizontal pager is a second horizontal drag surface
                // competing with the pager for the same gesture, and the
                // stock contentItem also produced a genuine binding-loop
                // warning there.
                contentItem: Row {
                    anchors.fill: parent
                    // The two pills were flush against each other — this
                    // Row carried NO spacing at all, so "Notifications"
                    // and "News" touched and read as one run of chrome
                    // rather than two targets (operator report,
                    // 2026-08-19). Design token, never a literal.
                    //
                    // Raised spacingSm -> spacingMd on a second report
                    // that the count numeral still sat too close to the
                    // neighbouring pill. The numeral is the LAST thing in
                    // tab 0 and the News pill starts immediately after it,
                    // so the inter-tab gap is what separates a number from
                    // a capsule edge — the two crowded elements belong to
                    // different tabs, which is why widening the pill's own
                    // padding alone did not resolve it.
                    spacing: Design.spacingMd
                    Repeater {
                        model: tabBar.contentModel
                    }
                }

                Repeater {
                    model: tabModel

                    delegate: TabButton {
                        id: tabButtonDelegate

                        required property int index
                        required property string label
                        required property string glyph

                        readonly property bool _current: tabButtonDelegate.index === pager.currentIndex

                        // Content-hugging, never a fixed width — the exact
                        // promise the deleted count capsule's own comment
                        // carried ("stays correct at 0, 9 or 100+
                        // entries"), which must survive this move in
                        // spirit: the numeral below shares this same box.
                        // Content-hugging, never a fixed width — the exact
                        // promise the deleted count capsule's own comment
                        // carried, unchanged by the padding increase
                        // below: the pill still grows and shrinks with
                        // its own label and numeral.
                        //
                        // Padding widened spacingMd -> spacingLg per side
                        // and an explicit pill height added (operator
                        // report 2026-08-19: "dimensions are too tight").
                        // The height is derived from the label row plus
                        // symmetric vertical padding, NOT from the 48px
                        // band — the band's own height is untouched, so
                        // the layer surface still cannot move. It is
                        // clamped to the band so a future font bump can
                        // never push the pill past the header.
                        implicitWidth: labelRow.implicitWidth + Design.spacingLg * 2
                        implicitHeight: Math.min(labelRow.implicitHeight + Design.spacingSm * 2, Design.popoutHeaderHeight - Design.spacingXs * 2)
                        focusPolicy: Qt.NoFocus

                        background: Rectangle {
                            // The selected tab keeps the SAME capsule fill
                            // the count capsule used, so the band still
                            // reads as this shell's established pill
                            // language rather than new chrome.
                            color: tabButtonDelegate._current ? BarRoles.capsule : "transparent"
                            radius: height / 2

                            Behavior on color {
                                enabled: Motion.motionEnabled
                                ColorAnimation {
                                    duration: Motion.standardDuration
                                    easing.type: Easing.BezierSpline
                                    easing.bezierCurve: Motion.standardEasing
                                }
                            }
                        }

                        contentItem: Row {
                            id: labelRow
                            anchors.centerIn: parent
                            // spacingXs (4px) set the gap for BOTH the
                            // glyph->word and word->numeral joins. 4px
                            // reads as joined at fontBody, which is the
                            // other half of the 2026-08-19 crowding
                            // report: "Notifications" and its count ran
                            // together. spacingSm separates the three
                            // parts as three parts while keeping the pill
                            // content-hugging.
                            spacing: Design.spacingSm

                            // ── Leading tab glyph (this quick task) —
                            //    reuses the label's own existing
                            //    selected/unselected colour binding
                            //    verbatim, no third colour state minted.
                            //    No restructure: this Row and its
                            //    Design.spacingXs spacing already existed;
                            //    implicitWidth below is content-hugging
                            //    and absorbs this glyph automatically. ────
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: tabButtonDelegate.glyph
                                font.family: Design.symbolFontFamily
                                font.pixelSize: Design.iconSizeMd
                                textFormat: Text.PlainText
                                color: tabButtonDelegate._current ? BarRoles.notifSurfaceFg : BarRoles.capsuleFg
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: tabButtonDelegate.label
                                textFormat: Text.PlainText
                                elide: Text.ElideRight
                                font.pixelSize: Design.fontBody
                                color: tabButtonDelegate._current ? BarRoles.notifSurfaceFg : BarRoles.capsuleFg
                            }
                            // ── Tab 0's own numeral (quick task 260819-6oy)
                            //    — carries forward the deleted count
                            //    capsule's numeral verbatim: same
                            //    BarRoles.accent colour, same fontBody
                            //    size, same weightEmphasis weight, same
                            //    DIRECT NotifServer.history.length read
                            //    (never the gated ListView.model/.count,
                            //    per the empty state's own "HARD
                            //    correctness gate" comment further down —
                            //    ListView.model is intentionally [] while
                            //    the centre is closed). No elide, ever: if
                            //    the row overflows, the WORD gives way,
                            //    the count never does. ────────────────────
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: tabButtonDelegate.index === 0
                                text: String(NotifServer.history.length)
                                textFormat: Text.PlainText
                                font.pixelSize: Design.fontBody
                                font.weight: Design.weightEmphasis
                                color: BarRoles.accent
                            }
                        }

                        // D-16's direct tap-to-jump, copied from
                        // Dashboard.qml — animates over
                        // Motion.standardDuration via pagerList's own
                        // highlightMoveDuration binding (see the pager
                        // below), because it moves the same contentX that
                        // token animates.
                        onClicked: pager.setCurrentIndex(tabButtonDelegate.index)
                    }
                }
            }

            // ── DELIBERATELY REMOVED (quick task 260819-6oy): the
            //    singular/plural binding
            //    (`NotifServer.history.length === 1 ? "notification" :
            //    "notifications"`) the deleted count capsule used to
            //    carry. The tab's own noun ("Notifications") carries the
            //    word now, so the pluralisation has no surface left to
            //    render on — a consequence of the locked two-tab design,
            //    not silent drift. Rendering "Notifications 0" rather than
            //    hiding the numeral at zero is the behaviour-preserving
            //    choice (the capsule showed "0 notifications" today);
            //    hiding it at zero would be a NEW behaviour change and is
            //    out of this task's scope.

            // ── Action slot (quick task 260819-6oy) — clear-all and news-
            //    refresh share the EXACT slot clearAllButton held alone
            //    today: same anchors.right/rightMargin/verticalCenter,
            //    same Design.iconSizeMd box. The band's own geometry is
            //    therefore untouched — only which glyph paints inside this
            //    one fixed box changes, cross-faded by tab. ──────────────
            Item {
                id: actionSlot
                anchors.right: parent.right
                anchors.rightMargin: Design.spacingMd
                anchors.verticalCenter: parent.verticalCenter
                width: Design.iconSizeMd
                height: Design.iconSizeMd

                Item {
                    id: clearAllButton
                    anchors.fill: parent
                    readonly property bool _hasHistory: NotifServer.history.length > 0
                    // Quick task 260819-6oy — the one new factor this
                    // button gains: it participates only while tab 0
                    // (Notifications) is current, since it shares
                    // `actionSlot`'s one box with `newsRefreshButton` now.
                    readonly property bool _shouldShow: pager.currentIndex === 0 && clearAllButton._hasHistory
                    opacity: 0
                    scale: 0.5

                    // GATE-02 gap-closure fix (round 4, item 5) — root-caused
                    // live with a temporary console.log probe (removed):
                    // `content` (and this button) mount unconditionally at
                    // shell startup (this file's own header comment), BEFORE
                    // NotifServer's FileView finishes its async disk read. So
                    // `_hasHistory` is created `false` (matching the literal
                    // opacity:0/scale:0.5 above) and flips `true` a moment
                    // later once the file load lands — that transition WAS
                    // observed firing correctly. The actual defect: the
                    // `NumberAnimation on <property>` value-source form used
                    // previously reads its own `to` expression at the exact
                    // instant the change-notify signal is delivered, and in
                    // this Quickshell/Qt build that read raced ahead of the
                    // dependent property's own binding re-evaluation — the
                    // probe caught `to` still reporting the STALE value (0)
                    // inside the very handler reacting to the change that
                    // made it 1, so the animator restarted toward the value
                    // it was already sitting at (a no-op) instead of the new
                    // target. `Qt.callLater()` below defers the restart by
                    // one event-loop tick, past whatever internal ordering
                    // caused the stale read — confirmed live (opacity ranged
                    // smoothly 0 -> 1 across ~45 frames once deferred, vs.
                    // never moving at all before). Two plain (non-"on")
                    // `NumberAnimation` objects, imperatively (re)started —
                    // a different QML construct than the frame's own single
                    // reserved element, so this file's own literal
                    // element-count acceptance criterion is untouched.
                    //
                    // Quick task 260819-6oy widens the SAME race to a
                    // second trigger: `pager.currentIndex` changing (a tab
                    // switch) hits the identical stale-`to`-read class as
                    // `_hasHistory` changing did — the handler below now
                    // reacts to `_shouldShow` (which folds both triggers
                    // into one), still deferred by the same
                    // `Qt.callLater()` tick.
                    NumberAnimation {
                        id: clearAllOpacityAnim
                        target: clearAllButton
                        property: "opacity"
                        to: clearAllButton._shouldShow ? 1 : 0
                        duration: Motion.motionEnabled ? Motion.standardDuration : 0
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Motion.standardEasing
                    }
                    NumberAnimation {
                        id: clearAllScaleAnim
                        target: clearAllButton
                        property: "scale"
                        to: clearAllButton._shouldShow ? 1 : 0.5
                        duration: Motion.motionEnabled ? Motion.standardDuration : 0
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Motion.standardEasing
                    }
                    on_ShouldShowChanged: Qt.callLater(function() {
                        clearAllOpacityAnim.restart();
                        clearAllScaleAnim.restart();
                    })
                    Component.onCompleted: {
                        // Snap (no animation) to whatever is already true at
                        // mount — covers the async-load race directly rather
                        // than depending on a transition event that may have
                        // already happened before this handler could listen,
                        // and avoids a spurious fade-in flash on every shell
                        // restart when history is (almost always) non-empty.
                        clearAllButton.opacity = clearAllButton._shouldShow ? 1 : 0;
                        clearAllButton.scale = clearAllButton._shouldShow ? 1 : 0.5;
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "clear_all"
                        font.family: Design.symbolFontFamily
                        font.pixelSize: Design.iconSizeMd
                        textFormat: Text.PlainText
                        // GATE-02 gap-closure fix (round 6, item 2) — destructive
                        // controls hover to BarRoles.danger, not BarRoles.accent,
                        // so hovering a "clear everything" action reads as the
                        // warning it is rather than the same neutral highlight
                        // any non-destructive hover (e.g. the group-expand
                        // header) already uses. Same containsMouse-swap idiom
                        // this file already uses everywhere else — no new
                        // mechanism, just the correct colour role for this
                        // control's actual consequence.
                        color: clearAllMouseArea.containsMouse ? BarRoles.danger : BarRoles.capsuleFg
                    }
                    MouseArea {
                        id: clearAllMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        // Gated on `_shouldShow`, not just `_hasHistory` —
                        // an invisible-but-present clear-all button must
                        // never intercept a click meant for the News tab
                        // sharing this same box.
                        enabled: clearAllButton._shouldShow
                        onClicked: NotifServer.clearAll()
                    }
                }

                // ── News refresh button (quick task 260819-6oy) — the
                //    action slot's other occupant, visible only while tab
                //    1 (News) is current. Same cross-fade shape as
                //    clearAllButton above, same Qt.callLater deferral for
                //    the identical stale-`to`-read race, keyed here on
                //    `pager.currentIndex` directly since this button has
                //    no history-style second gating condition. ───────────
                Item {
                    id: newsRefreshButton
                    anchors.fill: parent
                    readonly property bool _shouldShow: pager.currentIndex === 1
                    opacity: 0
                    scale: 0.5

                    NumberAnimation {
                        id: newsRefreshOpacityAnim
                        target: newsRefreshButton
                        property: "opacity"
                        to: newsRefreshButton._shouldShow ? 1 : 0
                        duration: Motion.motionEnabled ? Motion.standardDuration : 0
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Motion.standardEasing
                    }
                    NumberAnimation {
                        id: newsRefreshScaleAnim
                        target: newsRefreshButton
                        property: "scale"
                        to: newsRefreshButton._shouldShow ? 1 : 0.5
                        duration: Motion.motionEnabled ? Motion.standardDuration : 0
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Motion.standardEasing
                    }
                    on_ShouldShowChanged: Qt.callLater(function() {
                        newsRefreshOpacityAnim.restart();
                        newsRefreshScaleAnim.restart();
                    })
                    Component.onCompleted: {
                        newsRefreshButton.opacity = newsRefreshButton._shouldShow ? 1 : 0;
                        newsRefreshButton.scale = newsRefreshButton._shouldShow ? 1 : 0.5;
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "refresh"
                        font.family: Design.symbolFontFamily
                        font.pixelSize: Design.iconSizeMd
                        textFormat: Text.PlainText
                        // Non-destructive, so hover -> BarRoles.accent, not
                        // BarRoles.danger — the same role-choice logic
                        // clearAllButton's own comment above records for
                        // picking danger over accent, applied the other
                        // way for a non-destructive action.
                        color: newsRefreshMouseArea.containsMouse ? BarRoles.accent : BarRoles.capsuleFg

                        // The in-flight busy spin — the SAME ambient-loop
                        // token/shape WifiPanel.qml's own rescan spinner
                        // uses (Motion.ambientDuration is a LOOP-PERIOD
                        // token, not a one-shot duration).
                        RotationAnimation on rotation {
                            running: (centreWindow.newsBackend !== null && centreWindow.newsBackend.requestsInFlight > 0) && Motion.motionEnabled
                            loops: Animation.Infinite
                            from: 0
                            to: 360
                            duration: Motion.ambientDuration
                        }
                    }
                    MouseArea {
                        id: newsRefreshMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: newsRefreshButton._shouldShow && centreWindow.newsBackend !== null && centreWindow.newsBackend.requestsInFlight === 0
                        onClicked: centreWindow.newsBackend.refresh(true)
                    }
                }
            }
        }

        // ── One-way sync target (quick task 260819-6oy) — re-asserts
        //    the header's currentIndex on every pager change. TabBar
        //    writes its own currentIndex imperatively when a button is
        //    clicked (Container's internal click handling), which
        //    breaks a plain binding after the first tap; this
        //    Connections block is what makes the one-way flow (pager
        //    holds selection, header reports it) hold for the
        //    surface's whole lifetime rather than until the first tap.
        //    Dashboard.qml:936-942 verbatim. ─────────────────────────
        Connections {
            target: pager
            function onCurrentIndexChanged() {
                tabBar.setCurrentIndex(pager.currentIndex);
            }
        }

        // ── Re-assert the SHOWN PAGE on every re-show (bug fix
        //    2026-08-19) — the counterpart to the header sync above,
        //    for the other half of the same one-way flow.
        //
        //    ROOT CAUSE: this surface is never destroyed on close. It
        //    stays alive and only toggles `visible` (see the window's
        //    own `visible: centreWindow.offsetScale < 1`). `pagerList`
        //    sets `highlightRangeMode: ListView.StrictlyEnforceRange`,
        //    and under that mode a ListView WRITES ITS OWN
        //    `currentIndex` whenever `contentX` moves. On re-show the
        //    hidden ListView's `contentX` has been reset to 0, so it
        //    self-writes `currentIndex = 0` — and that imperative write
        //    DESTROYS the `currentIndex: pager.currentIndex` binding,
        //    exactly the way a TabButton tap destroys the header's
        //    binding above. `pager.currentIndex` itself is untouched,
        //    so the header (which reads it) kept saying "News" while
        //    the pager rendered page 0: the tab and its content
        //    disagreed.
        //
        //    Dashboard.qml does NOT need this only because it is
        //    RECREATED per open (its `Component.onCompleted:
        //    pager.setCurrentIndex(initialTabIndex)`, Dashboard.qml:524)
        //    — it works by lifecycle accident, not by a guard, so
        //    there was no prior art here to copy.
        //
        //    Re-establishing the BINDING (not just assigning the value)
        //    is what makes this hold for every subsequent re-show
        //    rather than only the first. `positionViewAtIndex` then
        //    snaps `contentX` in the same pass, so the page does not
        //    animate in from the wrong side.
        //
        //    Qt.callLater defers past binding settlement — inside
        //    onVisibleChanged the ListView has not necessarily
        //    re-laid-out yet, and positioning against a stale width
        //    lands on the wrong page (the same deferral WeatherBackend's
        //    own geocode call needed for the same class of reason).
        Connections {
            target: centreWindow
            function onVisibleChanged() {
                if (!centreWindow.visible)
                    return;
                Qt.callLater(function () {
                    pagerList.currentIndex = Qt.binding(function () {
                        return pager.currentIndex;
                    });
                    pagerList.positionViewAtIndex(pager.currentIndex, ListView.Beginning);
                });
            }
        }

        // ── The pager (quick task 260819-6oy) — page 0 is
        //    historyRegion (below, geometry carried up from its own
        //    former anchors, never changed), page 1 is NewsPane. THE
        //    SURFACE ITSELF NEVER RESIZES: only which page is visible
        //    changes; the window's own implicitWidth/margins/
        //    exclusiveZone are untouched (see this file's own
        //    geometry-guarantee note at the top). ────────────────────
        SwipeView {
            id: pager
            anchors.top: header.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            // Moved up from historyRegion's own former anchors — the
            // rendered box is byte-identical to before this task, only
            // which element carries the anchor changed.
            anchors.leftMargin: Design.spacingMd
            anchors.rightMargin: Design.spacingMd
            anchors.bottom: footerHost.top
            anchors.bottomMargin: Design.spacingLg
            clip: true
            // Zero spacing so the contentItem's scroll offset maps to
            // the tab index with no correction term, matching
            // Dashboard.qml's own pager.
            spacing: 0

            // ── RESEARCH Pitfall 1 (copied from Dashboard.qml,
            //    D-17/D-18) — a custom ListView contentItem
            //    reproducing every property the stock Basic
            //    SwipeView.qml sets, with the same three deliberate
            //    differences: highlightMoveDuration bound to the
            //    motion token instead of a literal; keyNavigationEnabled
            //    and focus both false so arrow keys and `content`'s own
            //    Keys.onEscapePressed (this window's Escape-to-close)
            //    are unaffected — Dashboard.qml:1060-1064 records
            //    exactly that reason, and it is why Escape-to-close is
            //    a NAMED verification step for this task rather than
            //    an assumption.
            //
            //    motion-lint's QML raw-value check is anchored on a
            //    lowercase `duration:` and the camel-cased
            //    `highlightMoveDuration` property name never matches
            //    it — a future edit dropping this back to a literal
            //    would pass every gate in this repo silently. This
            //    binding is a source assertion for exactly that
            //    reason. ─────────────────────────────────────────────
            contentItem: ListView {
                id: pagerList
                model: pager.contentModel
                interactive: pager.interactive
                currentIndex: pager.currentIndex
                focus: false

                spacing: pager.spacing
                orientation: pager.orientation
                snapMode: ListView.SnapOneItem
                boundsBehavior: Flickable.StopAtBounds

                highlightRangeMode: ListView.StrictlyEnforceRange
                preferredHighlightBegin: 0
                preferredHighlightEnd: 0
                highlightMoveDuration: Motion.standardDuration
                maximumFlickVelocity: 4 * (pager.orientation === Qt.Horizontal ? width : height)

                keyNavigationEnabled: false
            }

            Item {
                id: historyRegion

                // Page 0 of the pager above (quick task 260819-6oy). ALL
                // of this Item's own anchors were dropped here — SwipeView
                // sizes its own pages, and leaving anchors on a page
                // fights that sizing. The former leftMargin/rightMargin/
                // bottomMargin/clip moved UP onto the pager itself (see
                // its own declaration above), so the rendered box is
                // byte-identical to before this task. This Item's own
                // children keep their existing anchors.centerIn: parent /
                // anchors.fill: parent and are unaffected by the anchor
                // removal.

                // ── Empty state (D-19-22) — illustration cross-fades in above
                //    the headline, tinted to BarRoles.accent via
                //    QtQuick.Effects.MultiEffect (colorization: 1) — the exact
                //    12-line Colouriser mechanism Caelestia uses, confirmed
                //    installed on this host. The footer stays pinned and
                //    unchanged in this state (it is a sibling of this region,
                //    never nested inside it). ─────────────────────────────────
                Column {
                    id: emptyState
                    anchors.centerIn: parent
                    spacing: Design.spacingMd

                    // GATE-02 gap-closure fix (ISSUES 1/2, round 3) — this
                    // `visible` binding is the HARD correctness gate: reading
                    // `NotifServer.history.length` directly and unconditionally,
                    // never the gated `ListView.model`/`.count` (which is
                    // intentionally `[]` while the centre is closed, per the
                    // earlier crash gap-closure fix — a stale/gated signal for
                    // "is history empty" would be exactly the class of bug the
                    // coordinator's own diagnosis hint named). Previously this
                    // Column had NO `visible` binding at all — only the
                    // opacity animation below controlled its appearance, which
                    // meant a stuck, delayed, or mid-flight opacity value
                    // could leave "All up to date!" rendering (however faintly)
                    // OVER real list content, worst during a group expand
                    // (the one case tall enough to actually reach where this
                    // centred block sits). `visible` now makes that
                    // structurally impossible regardless of the opacity
                    // animation's own state — it disappears from the scene
                    // graph entirely, not just fades, the instant real history
                    // exists. The opacity animation is kept purely as a
                    // fade-IN polish when transitioning INTO the empty state
                    // (D-19-22's own "cross-fades in") — the fade-OUT
                    // direction is now instant by construction, which is an
                    // acceptable, deliberate asymmetry given the correctness
                    // requirement is one-directional (never show over content,
                    // no promise about how it leaves).
                    visible: NotifServer.history.length === 0

                    // Cross-fade via the same animated-property-source idiom —
                    // see the clear-all button's own identical note above for
                    // why this is not a second transition-on-change element.
                    NumberAnimation on opacity {
                        to: NotifServer.history.length === 0 ? 1 : 0
                        duration: Motion.motionEnabled ? Motion.standardDuration : 0
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Motion.standardEasing
                    }

                    // GATE-02 gap-closure fix (round 6, item 1 — "decorative
                    // picture", restored per direct user correction). RESEARCH:
                    // read `.planning/research/FEATURES.md` again (still no
                    // sidebar-picture detail beyond the icon+ring-progress
                    // treatment already covered) and, per the round-6
                    // instruction's own "inspect vendored Caelestia sources"
                    // fallback, read the actual `caelestia-dots/shell` source —
                    // a dated clone already present at
                    // `~/.claude/jobs/4517c040/tmp/caelestia-shell` (commit
                    // 06b4fe0, 2026-07-30), cross-checked live against the
                    // current `raw.githubusercontent.com` HEAD of
                    // `modules/sidebar/Content.qml` (byte-identical). Checked
                    // EVERY file in Caelestia's real `modules/sidebar/` tree
                    // (`Content.qml`, `Wrapper.qml`, `NotifDock.qml`,
                    // `NotifGroupList.qml`, `NotifGroup.qml`) for any
                    // Image/AnimatedImage element — found exactly ONE, in
                    // `NotifDock.qml` lines 96-107:
                    //   Image {
                    //       source: Paths.absolutePath(Config.paths.noNotifsPic)
                    //       fillMode: Image.PreserveAspectFit
                    //       layer.enabled: true
                    //       layer.effect: Colouriser { colorizationColor: ... }
                    //   }
                    // — shown ONLY inside the empty-state Loader (opacity bound
                    // to `notifCount > 0 ? 0 : 1`), immediately above the "All
                    // up to date!"-equivalent text, tinted via the exact same
                    // colourisation mechanism this file already uses. Its
                    // default path resolves to `root:/assets/dino.png` (a
                    // bundled mascot illustration, confirmed in
                    // `plugin/src/Caelestia/Config/userpaths.hpp`:
                    // `CONFIG_PROPERTY(QString, noNotifsPic,
                    // u"root:/assets/dino.png"_s)`), user-overridable through
                    // Caelestia's own C++ config system. There is NO separate
                    // always-visible header banner anywhere in Caelestia's real
                    // notification sidebar — `Content.qml` itself is just a
                    // `NotifDock` inside one `StyledRect`, nothing else. This
                    // project's own empty-state illustration (below) is
                    // therefore ALREADY the faithful equivalent of Caelestia's
                    // real decorative picture — same placement (centred in the
                    // empty-state region), same behaviour (empty-only), same
                    // tint mechanism (this file's own header note on
                    // `MultiEffect`/`colorization` already records the
                    // Colouriser-parity finding from Task 1). The one genuine,
                    // concrete gap versus Caelestia's actual pattern: THIS
                    // project's picture was a hardcoded bundled path with no
                    // user-override mechanism, unlike `Config.paths.noNotifsPic`
                    // — closed below. ───────────────────────────────────────
                    // ── The decorative picture (GATE-02, rounds 6/7/8) ────────
                    //
                    // PLACEMENT IS SETTLED — do not move this again without a
                    // new explicit instruction. Round 7 promoted this out of
                    // the empty state into an always-visible band under the
                    // header; round 8 moved it back here by direct correction
                    // ("Why did you move the picture location? Return it to
                    // the center"). The always-visible-and-centred combination
                    // the two rounds jointly imply is not reachable: the
                    // vertical centre of this panel is where the history list
                    // itself lives, so the only way to be both is to render
                    // behind the cards, which was offered in round 8 and
                    // explicitly rejected as looking buggy. Centred therefore
                    // means HERE — the empty state — exactly as round 6 and
                    // Caelestia's own `NotifDock.qml` both have it.
                    //
                    // What round 7 changed and round 8 KEEPS, because neither
                    // was about position and both were real reasons this read
                    // as "there is no picture" at all:
                    //   1. Size — 96x96 (icon scale) became
                    //      Design.notifCentrePictureHeight (132), so real
                    //      artwork has room to be artwork.
                    //   2. Colourisation — round 6 pushed BOTH the bundled
                    //      fallback AND any user override through
                    //      `colorization: 1.0`, which flattens every pixel to
                    //      one accent-coloured silhouette. Correct for the
                    //      bundled monochrome glyph (and what Caelestia does
                    //      to its own mascot), but it meant a user who dropped
                    //      their own PNG at the documented override path got a
                    //      flat blob, never their picture. The override now
                    //      renders untinted at its natural aspect; only the
                    //      bundled glyph is still colourised.
                    //
                    // Override path, unchanged since round 6:
                    //   ~/.local/state/quickshell/notif-centre-picture.png
                    Item {
                        id: emptyIllustrationHost
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: Design.notifCentrePictureHeight
                        height: Design.notifCentrePictureHeight

                        readonly property string _overridePath: Quickshell.env("HOME") + "/.local/state/quickshell/notif-centre-picture.png"
                        // Graceful degradation, unchanged in shape since round
                        // 6: the override counts only once it has genuinely
                        // finished loading (Image.Ready). An absent file
                        // reports Image.Error/Image.Null and this falls
                        // straight through to the bundled glyph — never a
                        // blank gap or a broken-texture flash.
                        readonly property bool _hasOverride: emptyIllustrationOverride.status === Image.Ready

                        Image {
                            id: emptyIllustrationOverride
                            anchors.fill: parent
                            source: "file://" + emptyIllustrationHost._overridePath
                            // Rendered directly — no `layer.enabled`, no
                            // MultiEffect in its path — so the user's own
                            // colours survive (see note 2 above).
                            fillMode: Image.PreserveAspectFit
                            visible: emptyIllustrationHost._hasOverride
                            asynchronous: true
                            cache: false
                            smooth: true
                        }
                        Image {
                            id: emptyIllustrationSource
                            anchors.fill: parent
                            source: "../../assets/notif-empty.svg"
                            fillMode: Image.PreserveAspectFit
                            // See DashboardTab.qml/MediaTab.qml's own recorded
                            // finding: an invisible source item with no
                            // `layer.enabled` produces no paint node at all, so
                            // the MultiEffect below would read an empty texture.
                            visible: false
                            layer.enabled: true
                            smooth: true
                            sourceSize.width: emptyIllustrationHost.width
                            sourceSize.height: emptyIllustrationHost.height
                        }
                        MultiEffect {
                            anchors.fill: parent
                            source: emptyIllustrationSource
                            visible: !emptyIllustrationHost._hasOverride
                            colorization: 1.0
                            colorizationColor: BarRoles.accent
                        }
                    }

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "All up to date!"
                        textFormat: Text.PlainText
                        font.pixelSize: Design.fontHeading
                        font.weight: Design.weightEmphasis
                        color: BarRoles.notifSurfaceFg
                    }
                }

                // ── Grouped history list (Task 2) — a ListView over
                //    `centreWindow.groupedHistory`, newest-activity-first
                //    (D-19-27). Each delegate is a pure-view `NotifGroup`,
                //    receiving this window's own expand map and shared clock
                //    and emitting signals back for every mutation, rather than
                //    writing `NotifServer.history` itself. ───────────────────
                //
                // ── Gap-closure fix (GATE-02 crash) ─────────────────────────
                // The window itself is always mounted (D-19-14 — history/DND
                // must not depend on it), but this list's own DELEGATES do not
                // need to exist while the surface is closed. The model below
                // is now gated on `centreWindow.visible`: while closed it is a
                // fixed empty array, so no `NotifGroup` delegate — and none of
                // its own nested per-row/per-action Repeaters — is ever
                // instantiated in the background. Before this fix, a
                // notification arriving at ANY time (the centre need not be
                // open, need not even have been opened once this session)
                // regenerated this ListView's delegates unconditionally,
                // which is what turned an unrelated bell-tooltip hover into a
                // crash: the nested Repeater regeneration this triggered ran
                // concurrently with the tooltip's own incubation. Gating here
                // does not delay content — `visible` already flips true the
                // instant the open animation starts, well before the slide
                // finishes.
                ListView {
                    id: historyList
                    anchors.fill: parent
                    model: centreWindow.visible ? centreWindow.groupedHistory : []
                    spacing: Design.spacingSm
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    delegate: NotifGroup {
                        width: historyList.width
                        groupData: modelData
                        expanded: !!centreWindow.expandedApps[modelData.appName]
                        nowMs: centreWindow._sharedClockNow
                        onToggleExpandRequested: centreWindow.toggleGroupExpanded(modelData.appName)
                        onClearNotificationRequested: key => NotifServer.clearOne(key)
                        onClearGroupRequested: appName => NotifServer.clearGroup(appName)
                    }
                }
            }

            // ── News tab — page 1 of the pager (quick task
            //    260819-6oy). Neither page goes behind a Loader,
            //    unlike Dashboard's four tabs: each page's real cost
            //    is already gated at its own data source — the
            //    history ListView's model is gated on
            //    centreWindow.visible, and NewsBackend is gated on
            //    centreOpen. A Loader would add a destroy/recreate
            //    cycle on every tab switch that the list's scroll
            //    position would pay for, and buy nothing.
            //
            //    A horizontal pager is safe over the history page
            //    because the centre's history rows carry NO
            //    horizontal drag gesture — NotifGroup.qml:705-711
            //    records the deliberate choice of an explicit close
            //    glyph over swipe-to-dismiss, precisely because a
            //    swipe "would fight the list's own vertical scroll".
            //    A future reader adding swipe-to-dismiss to the
            //    centre needs to find this note first. ──────────────
            NewsPane {
                newsBackend: centreWindow.newsBackend
            }
        }

        // ── Pinned footer — fixed height, never scrolls (D-19-17). The
        //    shared toggle grid plus three live sliders (Task 3); backend
        //    seams relayed straight through from this window's own
        //    Task-1-declared properties, threaded in by shell.qml exactly
        //    as Dashboard's own instantiation is. ────────────────────────
        CentreFooter {
            id: footerHost
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            audioBackend: centreWindow.audioBackend
            wifiBackend: centreWindow.wifiBackend
            bluetoothBackend: centreWindow.bluetoothBackend
            // GATE-02 round 11 — second hop of the chevron relay; see
            // CentreFooter.qml's own note. Re-emitted, never actioned
            // here: this window does not summon panels itself, exactly as
            // Dashboard.qml:723 re-emits rather than opening.
            onPanelRequested: name => centreWindow.panelRequested(name)
        }
    }
}
