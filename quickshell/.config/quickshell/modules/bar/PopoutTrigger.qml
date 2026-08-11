// PopoutTrigger.qml — the per-entry wrapper that turns a bar entry into a
// popout target and hosts that popout's surface (Phase 18 Plan 13,
// QBAR-09). Every trigger's LazyLoader is keyed on the SAME shared
// PopoutController.openSection string, which is what makes
// one-open-at-a-time structural rather than remembered — nothing here
// writes PopoutController.openSection or pinnedSection directly; every
// state change routes through the controller's own summon functions.
//
// Task 1 wires only the click path (toggle) and the loader. Task 2 (this
// commit) adds hover reporting — entryEntered/entryMoved/entryExited to
// the controller, the loaded popout's own hover edges relayed to
// popoutEntered/popoutExited, and a fresh publishAnchor() call on both
// paths that can open (hover-entered and click).
import QtQuick
import Quickshell
import "../"
import "../dashboard"

Item {
    id: triggerRoot

    property string sectionId: ""
    property Component popoutComponent: null
    // The wrapped bar entry lands here — the capsule's existing content,
    // unchanged, becomes this item's child instead of a direct child of
    // BarCapsule's own positioner.
    default property alias content: contentHost.data

    readonly property bool pinned: PopoutController.pinnedSection === triggerRoot.sectionId

    implicitWidth: contentHost.implicitWidth
    implicitHeight: contentHost.implicitHeight

    Item {
        id: contentHost
        anchors.fill: parent
        // Explicit stacking (18.1-02 scope amendment, human-authorized):
        // must stack above triggerMouseArea so nested click handlers
        // (D-25 format-alt toggle) receive clicks. With no z anywhere in
        // this file, declaration order alone put triggerMouseArea (below)
        // on top, silently swallowing every click before it reached
        // wrapped content — stating the stacking intent here removes that
        // implicit fragility instead of re-encoding it.
        z: 1
        implicitWidth: childrenRect.width
        implicitHeight: childrenRect.height
    }

    // The trigger's own centre, in scene coordinates, published into the
    // property SectionPopout reads. A function call, not a binding: scene
    // mapping does not re-evaluate when an ancestor moves, so a binding
    // would silently go stale — the bar does not reflow while a popout is
    // open, which is what makes a summon-time computation correct rather
    // than lucky.
    property real _publishedCentre: 0

    function publishAnchor() {
        var origin = triggerRoot.mapToItem(null, 0, 0);
        triggerRoot._publishedCentre = BarEntryModel.isVertical
            ? origin.y + triggerRoot.height / 2
            : origin.x + triggerRoot.width / 2;
    }

    // Left button only. Task 1 wires only the click, to the controller's
    // toggle function. No stealing-prevention and no composed-event
    // propagation are declared here, and no wheel handling is added at
    // all: the scroll gesture already living on the entry inside this
    // wrapper (18-12) must keep working, which is the one thing about
    // this wrapper a code reader would not predict.
    MouseArea {
        id: triggerMouseArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        hoverEnabled: true
        // Fresh anchor published before either path that can open — the
        // hover-entered path (dwell) and the click path — so the popout
        // always reads a fresh centre.
        onEntered: {
            triggerRoot.publishAnchor();
            PopoutController.entryEntered(triggerRoot.sectionId);
        }
        onExited: PopoutController.entryExited(triggerRoot.sectionId)
        onPositionChanged: PopoutController.entryMoved(triggerRoot.sectionId)
        onClicked: {
            triggerRoot.publishAnchor();
            // D-18-18: a click while previewing pins; a click on an
            // already-pinned popout closes it; a click with nothing open
            // opens and pins in one step, bypassing dwell entirely —
            // dwell exists to disambiguate an accidental hover, and a
            // click carries no ambiguity to resolve. toggle() (Task 1)
            // already implements exactly this shape.
            PopoutController.toggle(triggerRoot.sectionId);
        }
    }

    // Keyed on the ONE shared open-section string — the structural half
    // of one-open-at-a-time. Nothing may write this loader's active state
    // directly.
    LazyLoader {
        id: popoutLoader
        active: PopoutController.openSection === triggerRoot.sectionId
        component: triggerRoot.popoutComponent

        onItemChanged: {
            if (!popoutLoader.item)
                return;
            popoutLoader.item.vertical = Qt.binding(function () { return BarEntryModel.isVertical; });
            popoutLoader.item.pinned = Qt.binding(function () { return triggerRoot.pinned; });
            popoutLoader.item.triggerCentre = Qt.binding(function () { return triggerRoot._publishedCentre; });
            popoutLoader.item.dismissFinished.connect(PopoutController.close);
            // The triggering entry and the popout are ONE hover region
            // (D-18-21) — relay the loaded surface's own hover edge into
            // the controller's popoutEntered/popoutExited exactly as this
            // trigger's own MouseArea relays its entry/exit above.
            popoutLoader.item.hoveredChanged.connect(function () {
                if (popoutLoader.item.hovered)
                    PopoutController.popoutEntered();
                else
                    PopoutController.popoutExited();
            });
        }
    }

    // Declares no background, no radius and no fill — the capsule already
    // owns the hover crossfade and a second one here would double-tint.
}
