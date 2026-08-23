// TrayPopout.qml — the tray capsule's overflow popout (quick task
// 260823-65s, D-1). Lists the 4th-and-later SystemTray item once
// TrayCapsule.qml's inline row (inlineLimit 3) is full, reusing the
// existing PopoutController/SectionPopout machinery rather than a second
// popout mechanism — same shape as EthernetPopout.qml, the smallest
// SectionPopout body in this directory.
//
// Colours here follow EthernetPopout's own layer (Colours.onSurface /
// Colours.onSurfaceVariant) — this is dashboard-scale popout content, not
// bar chrome, and carries the same named quickshell-doctor exemption
// EthernetPopout and its other siblings already carry (bar-colour-role-
// routing; see that script's QSD_BAR_COLOUR_ROLE_EXEMPT array).
//
// Threat T-65s-01: `title`/`id` are attacker-influenced — any app can
// publish them. Every Text below declares textFormat: Text.PlainText and
// elides; no tray string is ever used to construct a command, path or
// dispatch string.
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import "../"
import "../dashboard"

SectionPopout {
    id: root

    // The 4th-and-later tray items, handed down by TrayCapsule.qml. `[]`
    // is an ordinary value here, never an error — the same contract
    // EthernetPopout's own device-handle property carries.
    property var overflowItems: []

    // The BAR's own window handle (quick task 260823-65s round 5,
    // operator-reported bug: right-click "shows the context menu but
    // immediately dismisses it"). MEASURED root cause: SectionPopout.qml's
    // own HyprlandFocusGrab (`popoutGrab`, below in that file) only lists
    // THIS popout window; item.display() opens the platform menu as its
    // OWN separate window, which the grab does not know about, so Hyprland
    // sees focus leave the grabbed set the instant the menu appears and
    // fires onCleared -> requestDismiss(). Checked for a menu-closed
    // signal to suppress-and-rearm the grab around instead (the ideal
    // fix): the installed Quickshell.DBusMenu module exposes only
    // sendOpened/sendClosed/sendTriggered on a hand-rolled DBusMenuItem,
    // none of which are lifecycle signals for the platform menu
    // display() itself opens — no such signal exists to rearm on.
    //
    // The actual fix has two parts, developed over four rounds:
    //   1. Parent the menu to a window that OUTLIVES the popout (this
    //      property) — Bar.qml's own "never unmounts for the life of the
    //      session" window (grep -c HyprlandFocusGrab Bar.qml == 0 —
    //      MEASURED: the bar holds no grab at all, which is WHY the
    //      inline path never had this problem), not the popout's own.
    //   2. Still call requestDismiss() — round 8 tried dropping it
    //      entirely and that was ALSO wrong: the popout's OWN
    //      HyprlandFocusGrab (SectionPopout.qml's popoutGrab) still fires
    //      on the menu taking focus regardless of whether this file calls
    //      requestDismiss() itself, because popoutGrab.onCleared calls it
    //      independently the instant focus leaves the grabbed set. What
    //      round 8 removed wasn't the race — it just stopped firing
    //      requestDismiss() a SECOND time. The real fix (round 9): call
    //      requestDismiss(), then wait for its own `dismissFinished()`
    //      signal (SectionPopout.qml's own — requestDismiss() is
    //      ASYNCHRONOUS, so this must be a signal handler, never assumed
    //      complete by the next line) before calling display(). By the
    //      time dismissFinished() fires, the popout window and its grab
    //      are both fully torn down, so there is nothing left to clear
    //      when the menu subsequently takes focus. See the onClicked
    //      handler below for the full sequencing.
    // Handed down from TrayCapsule.qml as `root._barWindowHandle` — NOT
    // re-read as a bare `QsWindow.window` anywhere in THIS file, which
    // would attach to this popout's own window instead (round 6's actual
    // bug, round 7 fix — see TrayCapsule.qml's own property declaration
    // for the full attached-property-scoping reasoning, confirmed by
    // three repetitions of "Cannot display PlatformMenuEntry with null
    // parent window" in ~/.cache/quickshell.log).
    property var barWindow: null

    // The TrayCapsule instance itself (round 7) — NOT just a window
    // handle, because the ANCHOR COORDINATES for display() have the
    // identical space problem `barWindow` had: `mapToItem(null, ...)`
    // inside this popout maps into the POPOUT's own window, and handing
    // those numbers to a DIFFERENT window (the bar) places the menu
    // wherever that offset lands in the wrong window's space — the same
    // coordinate-space hazard BarTooltipHost.qml's own header warns
    // about, walked into here despite having been correctly heeded
    // earlier in this same file (ThemedToolTip over BarTooltipHost).
    // menuAnchorSource._overflowMenuAnchor() returns the chevron's own
    // anchor point already computed in the BAR window's space, which is
    // the only space that is valid to hand to `barWindow` above.
    property var menuAnchorSource: null

    // Icon tint (260823-65s round 3, final shape round 5) — the SAME
    // Prefs key TrayCapsule.qml reads, so the two surfaces never
    // disagree on mode. Colour source is this popout's OWN content role
    // (Colours.onSurface, the same colour rowLabel below already uses),
    // never BarRoles — that belongs to the bar window, not this one
    // (EthernetPopout's own colour layer, which this file already
    // follows for everything else). See TrayCapsule.qml's own header
    // comment for the full round-5 design reasoning: "tinted"
    // (saturation:-1.0 + colorization:1.0, replacing the retired
    // "monochrome") keeps a tray icon's own logo detail legible while
    // recolouring it, since these are brand logos, not flat pictograms;
    // "desaturate" is the SAME pipeline with colorization:0 — plain
    // greyscale, no tint, distinct from "tinted" at the two mathematical
    // endpoints of one parameter rather than a tuned in-between value.
    //
    // Migration — declared BEFORE the property that calls it (MEMORY
    // qml-declare-before-construction-time-use), same shape as
    // TrayCapsule.qml's own: a stored "monochrome" (written by the
    // ed8928c8 build) maps forward to "tinted" rather than matching none
    // of this file's branches and silently falling through to "off".
    function _normalizeTrayIconTint(raw) {
        if (raw === "monochrome")
            return "tinted";
        if (raw === "tinted" || raw === "desaturate" || raw === "off")
            return raw;
        return "desaturate";
    }
    readonly property string _trayIconTint: root._normalizeTrayIconTint(Prefs.getValue("bar.tray.iconTint"))
    readonly property bool _tintTinted: root._trayIconTint === "tinted"
    readonly property bool _tintDesaturate: root._trayIconTint === "desaturate"
    readonly property bool _tintActive: root._tintTinted || root._tintDesaturate

    sectionId: "tray"
    popoutTitle: "System tray"
    popoutGlyph: "expand_more"

    bodyState: root.overflowItems.length > 0 ? "populated" : "empty"
    emptyStateGlyph: "apps"
    emptyStateText: "No further tray icons"

    wayfindingLabel: "Open in dashboard"
    wayfindingAvailable: false
    wayfindingUnavailableReason: "The dashboard has no system-tray panel"

    // ── Body — one row per overflow item ─────────────────────────────────
    Column {
        width: parent.width
        spacing: Design.spacingSm

        Repeater {
            model: root.overflowItems
            delegate: Item {
                id: overflowRow
                required property var modelData

                width: parent ? parent.width : 0
                height: Math.max(Design.iconSizeMd, rowLabel.implicitHeight)

                // Title, falling back to id, falling back to an em dash —
                // never the string "undefined".
                readonly property string _titleText: {
                    var t = overflowRow.modelData ? overflowRow.modelData.title : "";
                    if (t !== undefined && t !== null && t !== "")
                        return String(t);
                    var i = overflowRow.modelData ? overflowRow.modelData.id : "";
                    if (i !== undefined && i !== null && i !== "")
                        return String(i);
                    return "—";
                }

                // ── Tooltip text (Task 3 operator feedback, 260823-65s) —
                //    same tooltipTitle/title/tooltipDescription contract as
                //    TrayCapsule.qml's inline cells, so overflowed items do
                //    not lose data the protocol hands us just because they
                //    already show a plain-text title inline (tooltipDescription
                //    is never shown any other way in this row).
                readonly property string _tooltipTitle: (overflowRow.modelData && overflowRow.modelData.tooltipTitle) ? overflowRow.modelData.tooltipTitle : ""
                readonly property string _tooltipBase: overflowRow._tooltipTitle !== "" ? overflowRow._tooltipTitle : overflowRow._titleText
                readonly property string _tooltipDescription: (overflowRow.modelData && overflowRow.modelData.tooltipDescription) ? overflowRow.modelData.tooltipDescription : ""
                readonly property string _tooltipText: {
                    if (overflowRow._tooltipDescription !== "" && overflowRow._tooltipDescription !== overflowRow._tooltipBase)
                        return overflowRow._tooltipBase + "\n" + overflowRow._tooltipDescription;
                    return overflowRow._tooltipBase;
                }

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Design.spacingSm

                    // CORRECTION 1 (CONTEXT.md) — `.icon` is a resolved
                    // image:// URI Quickshell itself supplies; bound
                    // straight to source, exactly as the inline cell does.
                    // Tint mechanism identical to TrayCapsule.qml's own
                    // (see that file's own header comment for the full
                    // round-5 reasoning): "off" paints this IconImage
                    // directly; "tinted"/"desaturate" turn it into an
                    // invisible, layered texture source for the Loader
                    // below, which differs only in `colorization` amount
                    // (1.0 vs 0).
                    IconImage {
                        id: overflowIcon
                        width: Design.iconSizeMd
                        height: Design.iconSizeMd
                        implicitSize: Design.iconSizeMd
                        asynchronous: true
                        source: overflowRow.modelData ? overflowRow.modelData.icon : ""
                        visible: !root._tintActive
                        layer.enabled: root._tintActive
                    }

                    // Row is a positioner — it excludes an invisible
                    // child AND its spacing (BarCapsule.qml's own Grid
                    // carries the identical note). visible AND the
                    // explicit width/height are both gated on
                    // _tintActive so this Loader reserves ZERO Row space
                    // in "off" mode; a fixed size here regardless of
                    // `active` would have doubled the icon column's width
                    // whenever the effect is not instantiated.
                    Loader {
                        visible: root._tintActive
                        width: root._tintActive ? Design.iconSizeMd : 0
                        height: root._tintActive ? Design.iconSizeMd : 0
                        active: root._tintActive
                        sourceComponent: MultiEffect {
                            // anchors.fill: parent, NOT overflowIcon —
                            // same fix as TrayCapsule.qml's identical
                            // Loader/MultiEffect pair, same measured root
                            // cause (a Loader's sourceComponent item is a
                            // CHILD of the Loader, so a sibling of the
                            // Loader is two levels away, not one).
                            anchors.fill: parent
                            source: overflowIcon
                            saturation: -1.0
                            colorization: root._tintTinted ? 1.0 : 0.0
                            colorizationColor: Colours.onSurface
                        }
                    }

                    Text {
                        id: rowLabel
                        anchors.verticalCenter: parent.verticalCenter
                        width: Design.popoutMaxWidth - Design.spacingMd * 2 - Design.iconSizeMd - Design.spacingSm
                        text: overflowRow._titleText
                        font.pixelSize: Design.fontBody
                        color: Colours.onSurface
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                    }
                }

                // Same three gestures as an inline cell (CORRECTIONs 2/3).
                //
                // Menu path — round 5 (operator-reported): "Right-click on
                // the hidden vlc tray icon shows the context menu but
                // immediately dismisses it." Round 6 fix (dismiss first,
                // reparent to the bar window) was directionally right but
                // carried TWO further bugs (window-attachment scoping,
                // coordinate-space mismatch), fixed in round 7. Round 7's
                // OWN operator re-test then found a third defect: the menu
                // now had a valid parent and landed in the right place,
                // but still closed before a selection could be made —
                // MEASURED by direct comparison against the inline path,
                // which has never called requestDismiss() and has never
                // had this problem. `requestDismiss()` only STARTS an exit
                // animation (this file's own earlier comment already said
                // so); the popout's `HyprlandFocusGrab` therefore tears
                // down AFTER the menu has already opened and taken focus,
                // and that focus disturbance is what closed it — the exact
                // mechanism of the ORIGINAL round-5 bug, still firing,
                // just now against a menu that would otherwise have
                // survived it. The explicit dismiss was written when the
                // menu was parented to the popout, where the popout dying
                // necessarily killed it too; round 7 already re-parented
                // the menu to the bar (which never unmounts), so the
                // popout no longer needs to be gone before display() is
                // called — dropped entirely. The popout still dismisses
                // itself, via the SAME `popoutGrab.onCleared` path this
                // whole investigation started from: once the menu opens
                // and takes focus, Hyprland reports focus left the grabbed
                // set and the grab's own existing handler closes the
                // popout — now AFTER the menu is already open on a
                // surviving window, so the two no longer race.
                //
                // Applies to BOTH ways this row can reach display() —
                // right-click AND the onlyMenu left-click fall-through.
                //
                // ROUND 9 (operator re-test of round 8's "drop
                // requestDismiss() entirely" fix): menu appears (YES),
                // positioned sensibly (YES) — the round-7 window/anchor
                // fixes are confirmed correct and stay. But dropping the
                // dismiss call outright was ALSO wrong, MEASURED not
                // reasoned: Bar.qml holds `grep -c HyprlandFocusGrab` == 0
                // (the inline path's own window has no grab, which is WHY
                // it never had this problem) while the popout's own grab
                // (SectionPopout.qml's popoutGrab) is real and still fires
                // on the menu taking focus, dismiss call or not. The
                // popout was still going to close itself via
                // `popoutGrab.onCleared -> requestDismiss()` the instant
                // the menu opened — round 8 didn't remove that race, it
                // just stopped calling requestDismiss() a SECOND time.
                //
                // The actual fix: requestDismiss() IS still called, but
                // display() now waits for it to fully FINISH
                // (`dismissFinished()`, SectionPopout.qml's own signal —
                // emitted synchronously in the reduce-motion branch, or
                // via `exitFade.onFinished` otherwise) before opening the
                // menu, instead of firing immediately alongside it.
                // requestDismiss() itself is asynchronous (this file's own
                // earlier comment already established that) — by the time
                // dismissFinished() fires, the popout window is fully gone
                // and popoutGrab has already torn down with it, so there
                // is nothing left to clear when the menu subsequently
                // takes focus. The menu opens into the exact same
                // grab-free end state the inline path always has.
                MouseArea {
                    id: overflowRowMouseArea
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                    // Needed for containsMouse below (the tooltip's hover
                    // signal) — verified this changes no click behaviour.
                    hoverEnabled: true
                    onClicked: (mouse) => {
                        if (!overflowRow.modelData)
                            return;
                        if (mouse.button === Qt.MiddleButton) {
                            overflowRow.modelData.secondaryActivate();
                            return;
                        }
                        var wantsMenu = mouse.button === Qt.RightButton || overflowRow.modelData.onlyMenu;
                        if (wantsMenu) {
                            // Capture BEFORE requestDismiss() — everything
                            // this closure needs after the popout is gone
                            // must be read into locals now, while the row
                            // (and root.barWindow/menuAnchorSource) are
                            // still guaranteed alive.
                            var origin = (root.menuAnchorSource && root.barWindow)
                                ? root.menuAnchorSource._overflowMenuAnchor()
                                : null;
                            var menuItem = overflowRow.modelData;
                            var barWin = root.barWindow;

                            if (origin && barWin) {
                                // ONE-SHOT dismissFinished handler — a
                                // permanent connection would re-fire
                                // display() on every FUTURE dismissal of
                                // this same popout instance, a latent bug
                                // worse than the one being fixed.
                                // Self-disconnects on its own first call,
                                // the standard QML/JS idiom for a one-shot
                                // signal handler.
                                //
                                // Connected BEFORE requestDismiss() is
                                // called, not after — REQUIRED, not
                                // stylistic: when Motion.motionEnabled is
                                // false, SectionPopout.requestDismiss()
                                // emits dismissFinished() SYNCHRONOUSLY,
                                // before the call even returns to this
                                // line. A handler connected after that
                                // call would permanently miss a
                                // synchronous emission and the menu would
                                // never open at all for anyone running
                                // with reduced motion — this was verified
                                // against SectionPopout.qml's own
                                // requestDismiss()/exitFade code, not
                                // assumed.
                                var onPopoutDismissed = function () {
                                    root.dismissFinished.disconnect(onPopoutDismissed);
                                    menuItem.display(barWin, origin.x, origin.y);
                                };
                                root.dismissFinished.connect(onPopoutDismissed);
                                root.requestDismiss();
                            } else {
                                // Fail-safe: no valid window/anchor to
                                // open a menu against. Still dismiss (the
                                // row was clicked), then fall through to
                                // activate() rather than repeat a
                                // null-window display() call.
                                root.requestDismiss();
                                if (!menuItem.onlyMenu)
                                    menuItem.activate();
                            }
                            return;
                        }
                        // Left button, not onlyMenu.
                        overflowRow.modelData.activate();
                    }
                }

                // ThemedToolTip, NOT BarTooltipHost — this row renders
                // inside SectionPopout's own window, several hundred
                // pixels tall (measured for the sibling popouts:
                // popoutH=334), so the QQC2 Popup clamp BarTooltipHost
                // exists to work around lands clear of this row with
                // nothing to fix (BarTooltipHost.qml's own header names
                // AudioPopout.qml/SectionPopout.qml as exactly this
                // family, and both already use ThemedToolTip — this row
                // follows that established, colour-token-bound precedent
                // rather than reaching for the bar-window mechanism).
                ThemedToolTip {
                    visible: overflowRowMouseArea.containsMouse && overflowRow._tooltipText !== ""
                    text: overflowRow._tooltipText
                }
            }
        }
    }
}
