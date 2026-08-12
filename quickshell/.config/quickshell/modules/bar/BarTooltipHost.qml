// BarTooltipHost.qml — the dwell-timer + LazyLoader host each bar-window
// tooltip site mounts (quick task 260812-69w, F2). A plain, zero-size
// Item declared as a sibling of the hover target, never a wrapper around
// it — the four BAR-WINDOW sites (IdleInhibitorCapsule.qml,
// ClockActionsCapsule.qml's ActionCell, MediaConnectivityCapsule.qml,
// LauncherCapsule.qml) each declare one instance beside the MouseArea
// whose hover state drives `active`.
//
// The two POPOUT-WINDOW sites (AudioPopout.qml, SectionPopout.qml) do NOT
// use this host — Task 1's Probe B measured their tooltips rendering
// clear of their own glyph already, inside a window several hundred
// pixels tall, so converting them would fix nothing that was broken.
import QtQuick
import Quickshell
import "../"
import "../dashboard"

Item {
    id: hostRoot
    width: 0
    height: 0

    // ── Public contract ───────────────────────────────────────────────
    property Item anchorItem: null
    property string text: ""
    property bool active: false
    property string tipId: ""

    // Published ONCE when the dwell timer fires, never a live binding —
    // scene mapping does not re-evaluate when an ancestor moves, the same
    // reasoning SectionPopout.qml's own triggerCentre and BarDrawer.qml's
    // own triggerCentre both carry.
    property real _publishedCentre: 0
    property bool _dwellElapsed: false

    onActiveChanged: {
        if (hostRoot.active) {
            dwellTimer.restart();
        } else {
            dwellTimer.stop();
            hostRoot._dwellElapsed = false;
        }
    }

    Timer {
        id: dwellTimer
        interval: Design.tooltipDelayMs
        repeat: false
        onTriggered: {
            if (!hostRoot.anchorItem)
                return;
            var scenePos = hostRoot.anchorItem.mapToItem(null, hostRoot.anchorItem.width / 2, hostRoot.anchorItem.height / 2);
            hostRoot._publishedCentre = BarEntryModel.isVertical ? scenePos.y : scenePos.x;
            hostRoot._dwellElapsed = true;
        }
    }

    // Nothing exists while nothing is hovered — the same LazyLoader
    // lifecycle HotZone.qml established under D-18-24: active only while
    // BOTH the dwell has elapsed AND the hover that armed it is still
    // live, so a pointer that left before the dwell finished never
    // mounts a surface at all.
    LazyLoader {
        id: tooltipLoader
        active: hostRoot._dwellElapsed && hostRoot.active

        BarTooltip {
            text: hostRoot.text
            vertical: BarEntryModel.isVertical
            triggerCentre: hostRoot._publishedCentre
            tipId: hostRoot.tipId
        }
    }
}
