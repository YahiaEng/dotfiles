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

            Text {
                id: countText
                anchors.left: parent.left
                anchors.leftMargin: Design.spacingMd
                anchors.verticalCenter: parent.verticalCenter
                text: String(NotifServer.history.length)
                textFormat: Text.PlainText
                font.pixelSize: Design.fontHeading
                font.weight: Design.weightEmphasis
                color: BarRoles.notifSurfaceFg
            }

            Item {
                id: clearAllButton
                anchors.right: parent.right
                anchors.rightMargin: Design.spacingMd
                anchors.verticalCenter: parent.verticalCenter
                width: Design.iconSizeMd
                height: Design.iconSizeMd
                readonly property bool _hasHistory: NotifServer.history.length > 0
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
                NumberAnimation {
                    id: clearAllOpacityAnim
                    target: clearAllButton
                    property: "opacity"
                    to: clearAllButton._hasHistory ? 1 : 0
                    duration: Motion.motionEnabled ? Motion.standardDuration : 0
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.standardEasing
                }
                NumberAnimation {
                    id: clearAllScaleAnim
                    target: clearAllButton
                    property: "scale"
                    to: clearAllButton._hasHistory ? 1 : 0.5
                    duration: Motion.motionEnabled ? Motion.standardDuration : 0
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.standardEasing
                }
                on_HasHistoryChanged: Qt.callLater(function() {
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
                    clearAllButton.opacity = clearAllButton._hasHistory ? 1 : 0;
                    clearAllButton.scale = clearAllButton._hasHistory ? 1 : 0.5;
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
                    enabled: clearAllButton._hasHistory
                    onClicked: NotifServer.clearAll()
                }
            }
        }

        // ── History region — scrollable, fills remaining vertical space.
        //    Carries both the empty-state illustration (Task 1) and the
        //    grouped-history ListView (Task 2) as siblings — the empty
        //    state answers to this region's own emptiness independent of
        //    which child is currently rendering content. ─────────────────
        // ── Decorative picture band (GATE-02 gap-closure, round 7 item 1)
        //
        // Round 6 implemented this picture INSIDE the empty-state block,
        // faithfully mirroring Caelestia's own `NotifDock.qml` (its
        // `noNotifsPic` lives in an empty-state Loader, opacity bound to
        // `notifCount > 0 ? 0 : 1`). That reading of Caelestia is still
        // correct — but it is not what was asked for here: the picture was
        // therefore invisible in the ONLY state the user ever opens the
        // centre in, i.e. with notifications present. Per direct round-7
        // correction it is now a PERMANENT element of the centre: always
        // rendered, in its own band under the header and above the history
        // list, independent of `NotifServer.history.length`. This is a
        // deliberate divergence from Caelestia's empty-only placement,
        // recorded here so a future reader does not "restore parity" and
        // silently regress it back to round 6's behaviour.
        //
        // Two further changes were required for it to read as a picture at
        // all, both carried over from the round-6 implementation:
        //   1. Size — it was 96x96 (icon scale). The band is 132px tall
        //      and full-width, so real artwork has room to be artwork.
        //   2. Colourisation — round 6 ran BOTH the bundled fallback AND
        //      any user-supplied override through `colorization: 1.0`,
        //      which flattens every pixel to a single accent-coloured
        //      silhouette. That is right for the bundled monochrome SVG
        //      glyph (and is what Caelestia does to its own mascot), but
        //      it means a user who dropped their own PNG at the documented
        //      override path got a flat accent blob, never their picture.
        //      The override now renders untinted at its natural aspect;
        //      only the bundled glyph is colourised.
        //
        // Override path is unchanged from round 6 (a user who already
        // placed a file there keeps it working):
        //   ~/.local/state/quickshell/notif-centre-picture.png
        Item {
            id: decorPicture
            anchors.top: header.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.leftMargin: Design.spacingMd
            anchors.rightMargin: Design.spacingMd
            height: Design.notifCentrePictureHeight

            readonly property string _overridePath: Quickshell.env("HOME") + "/.local/state/quickshell/notif-centre-picture.png"
            // Graceful degradation, unchanged in shape from round 6: the
            // override counts only once it has genuinely finished loading
            // (Image.Ready). An absent file reports Image.Error/Image.Null
            // and this falls straight through to the bundled glyph — never
            // a blank band or a broken-texture gap.
            readonly property bool _hasOverride: decorPictureOverride.status === Image.Ready

            Image {
                id: decorPictureOverride
                anchors.fill: parent
                source: "file://" + decorPicture._overridePath
                // Rendered directly — no `layer.enabled`, no MultiEffect,
                // so the user's own colours survive (see the note above).
                fillMode: Image.PreserveAspectFit
                visible: decorPicture._hasOverride
                asynchronous: true
                cache: false
                smooth: true
            }

            Image {
                id: decorPictureFallback
                anchors.centerIn: parent
                width: Math.min(parent.width, parent.height)
                height: width
                source: "../../assets/notif-empty.svg"
                fillMode: Image.PreserveAspectFit
                // See DashboardTab.qml/MediaTab.qml's own recorded finding
                // (and this file's round-6 note): an invisible source item
                // with no `layer.enabled` produces no paint node at all, so
                // the MultiEffect below would read an empty texture.
                visible: false
                layer.enabled: true
                smooth: true
                sourceSize.width: width
                sourceSize.height: height
            }
            MultiEffect {
                anchors.fill: decorPictureFallback
                source: decorPictureFallback
                visible: !decorPicture._hasOverride
                colorization: 1.0
                colorizationColor: BarRoles.accent
            }
        }

        Item {
            id: historyRegion
            anchors.top: decorPicture.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            // GATE-02 gap-closure fix (ISSUE c) — this region previously
            // spanned edge-to-edge with NO horizontal inset, so a row's
            // own square-cornered hover highlight (radius: spacingSm,
            // much smaller than the WINDOW's own popoutCornerRadius)
            // could render right up against — and visually poke past —
            // the frame's own ROUNDED left edge near the top/bottom of
            // the list, reading as "clipping outside the centre's
            // bounds". Matches the header's own existing spacingMd inset
            // (see `header`'s Text/clearAllButton anchors.leftMargin/
            // rightMargin above) rather than inventing a new value.
            anchors.leftMargin: Design.spacingMd
            anchors.rightMargin: Design.spacingMd
            anchors.bottom: footerHost.top
            anchors.bottomMargin: Design.spacingLg
            clip: true

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
                // ROUND 7 SUPERSESSION — the illustration that used to sit
                // here has MOVED OUT of the empty state and into the
                // permanent `decorPicture` band declared above this
                // Column's own parent region. Everything the round-6
                // research block above establishes about Caelestia's
                // empty-only placement remains factually accurate and is
                // kept for provenance; it is simply no longer what this
                // project does, by direct instruction (see `decorPicture`'s
                // own header for the full rationale, the override path,
                // and why the override is no longer colourised). Nothing
                // is rendered here now — duplicating the picture would
                // show it twice whenever history happened to be empty, so
                // the empty state keeps only its headline below, beneath
                // the always-visible band.
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
                    onClearNotificationRequested: id => NotifServer.clearOne(id)
                    onClearGroupRequested: appName => NotifServer.clearGroup(appName)
                }
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
        }
    }
}
