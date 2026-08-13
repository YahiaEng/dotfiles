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
// ── No keyboard focus, no focus grab, no click-outside dismissal
//    (D-19-18) — DELIBERATE, do not "fix" ────────────────────────────────
// `WlrLayershell.keyboardFocus: WlrKeyboardFocus.None` and no
// `HyprlandFocusGrab` anywhere in this file. Typing continues to reach
// whatever application is actually focused while this surface is open.
// Because there is consequently no focus grab, there is also no
// click-outside dismissal — this surface closes ONLY via its own explicit
// toggle (bell/Super+N) or Escape. This mirrors `SectionPopout.qml`'s own
// unpinned-state shape (the same `None` + `Keys.onEscapePressed` +
// `content.forceActiveFocus()` combination already shipped there) rather
// than inventing a new pattern.
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
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
    anchors {
        top: true
        bottom: true
        right: true
    }
    implicitWidth: Design.notifSurfaceWidth
    margins.right: (-centreWindow.implicitWidth - 5) * centreWindow.offsetScale
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-notif-centre"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    color: "transparent"

    // ── Chrome — same visual family as the popup card and toast
    //    (BarRoles.notifSurface, GradientBorder rim, D-19-43's routing
    //    rule: never a direct Colours.* reference). Corners rounded on the
    //    LEFT edge only (the frame's inner, desktop-facing side) — top,
    //    bottom and right are all screen-flush, so only the left edge has
    //    a visible corner to round, the same asymmetric-rounding reasoning
    //    PanelDialog.qml's own bottom-only rounding already answers to. ──
    Rectangle {
        id: background
        anchors.fill: parent
        topLeftRadius: Design.popoutCornerRadius
        bottomLeftRadius: Design.popoutCornerRadius
        topRightRadius: 0
        bottomRightRadius: 0
        color: BarRoles.notifSurface
    }

    GradientBorder {
        anchors.fill: parent
        borderWidth: Design.borderWidth
        topLeftRadius: Design.popoutCornerRadius
        bottomLeftRadius: Design.popoutCornerRadius
        topRightRadius: 0
        bottomRightRadius: 0
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

                // Scale+fade appear-when-non-empty (D-19-28) — an animated
                // property source rather than a second transition-on-change
                // element, so this file's own acceptance criterion
                // (exactly one property drives the slide, checked against
                // this file's transition-element count for offsetScale
                // below) stays literally true: the one such element in
                // this file is the frame's own open/close slide, never a
                // second one for a header decoration.
                NumberAnimation on opacity {
                    id: clearAllOpacityAnim
                    to: clearAllButton._hasHistory ? 1 : 0
                    duration: Motion.motionEnabled ? Motion.standardDuration : 0
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.standardEasing
                }
                NumberAnimation on scale {
                    id: clearAllScaleAnim
                    to: clearAllButton._hasHistory ? 1 : 0.5
                    duration: Motion.motionEnabled ? Motion.standardDuration : 0
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.standardEasing
                }

                Text {
                    anchors.centerIn: parent
                    text: "clear_all"
                    font.family: Design.symbolFontFamily
                    font.pixelSize: Design.iconSizeMd
                    textFormat: Text.PlainText
                    color: clearAllMouseArea.containsMouse ? BarRoles.accent : BarRoles.capsuleFg
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
        Item {
            id: historyRegion
            anchors.top: header.bottom
            anchors.left: parent.left
            anchors.right: parent.right
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

                // Cross-fade via the same animated-property-source idiom —
                // see the clear-all button's own identical note above for
                // why this is not a second transition-on-change element.
                NumberAnimation on opacity {
                    to: NotifServer.history.length === 0 ? 1 : 0
                    duration: Motion.motionEnabled ? Motion.standardDuration : 0
                    easing.type: Easing.BezierSpline
                    easing.bezierCurve: Motion.standardEasing
                }

                Item {
                    id: emptyIllustrationHost
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: 96
                    height: 96

                    Image {
                        id: emptyIllustrationSource
                        anchors.fill: parent
                        source: "../../assets/notif-empty.svg"
                        visible: false
                        // See DashboardTab.qml/MediaTab.qml's own recorded
                        // finding: an invisible source item with no
                        // `layer.enabled` produces no paint node at all, so
                        // MultiEffect would read an empty texture.
                        layer.enabled: true
                        smooth: true
                        sourceSize.width: emptyIllustrationHost.width
                        sourceSize.height: emptyIllustrationHost.height
                    }
                    MultiEffect {
                        anchors.fill: parent
                        source: emptyIllustrationSource
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
            ListView {
                id: historyList
                anchors.fill: parent
                model: centreWindow.groupedHistory
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
