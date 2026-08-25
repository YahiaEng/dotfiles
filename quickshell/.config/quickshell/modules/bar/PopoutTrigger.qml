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
//
// Hover and buttons are reported by two DIFFERENT objects here, which is
// the one thing about this file a reader must not "tidy": buttons come
// from triggerMouseArea, hover comes from triggerHoverHandler attached to
// the root. See triggerHoverHandler's comment for the measurement that
// forced the split (bugfix wifi-glyph-hover-no-popout, 2026-08-12).
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

    // Left button only, and BUTTONS ONLY — this MouseArea deliberately
    // reports no hover whatsoever; the trigger's hover role belongs to
    // triggerHoverHandler below, and that split is load-bearing (see that
    // handler's own comment for the measurement that forced it). Task 1
    // wires only the click, to the controller's toggle function. No
    // stealing-prevention and no composed-event propagation are declared
    // here, and no wheel handling is added at all: the scroll gesture
    // already living on the entry inside this wrapper (18-12) must keep
    // working, which is the one thing about this wrapper a code reader
    // would not predict.
    MouseArea {
        id: triggerMouseArea
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        // Stated explicitly even though false is the default: the point of
        // writing it is to stop a later reader from "restoring" the hover
        // wiring here after finding it missing. Nothing anywhere in the
        // shell reads triggerMouseArea.containsMouse.
        hoverEnabled: false

        onClicked: {
            // Fresh anchor published before either path that can open —
            // the hover-entered path (dwell, armed from
            // triggerHoverHandler) and this click path — so the popout
            // always reads a fresh centre.
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

    // ── The trigger's hover role — on triggerRoot ITSELF ─────────────────
    // Attached here rather than to triggerMouseArea, and it must not be
    // moved back. Everything a caller writes inside a PopoutTrigger {}
    // block lands in contentHost (default property alias content:
    // contentHost.data), and contentHost sits at z: 1 ABOVE
    // triggerMouseArea. A HoverHandler written in that block — the audio
    // and connections drawer triggers in MediaConnectivityCapsule.qml each
    // declare exactly one — therefore makes CONTENTHOST a hover-accepting
    // item, and Qt's hover walk, which visits children front-to-back and
    // stops at the first item that accepts, never reaches the MouseArea
    // underneath. Button events still reach it (a HoverHandler handles no
    // buttons), which is exactly why click worked and hover did not.
    //
    // Measured on the running shell 2026-08-12, not inferred: during pure
    // hover, triggerMouseArea.onEntered fired ZERO times on the two
    // sections with such a sibling (wifi, audio) while firing 6/5/4 times
    // on the three without one (bluetooth, clock, media) — and a
    // HoverHandler on triggerRoot fired on ALL of them, 1:1 with the
    // MouseArea wherever the MouseArea worked at all. That 1:1 agreement is
    // what makes this a like-for-like replacement rather than a new
    // contract.
    //
    // Two non-fixes, recorded so they are not re-attempted: setting
    // blocking: false changes nothing (false is already HoverHandler's
    // default, and it is the parent item's hover acceptance — not the
    // handler's accept flag — that ends the walk), and contentHost's z: 1
    // cannot be dropped (18.1-02 / d5a9698 raised it precisely so the D-25
    // format-alt toggle nested in the wrapped content receives clicks).
    HoverHandler {
        id: triggerHoverHandler

        onHoveredChanged: {
            if (triggerHoverHandler.hovered) {
                triggerRoot.publishAnchor();
                PopoutController.entryEntered(triggerRoot.sectionId);
            } else {
                PopoutController.entryExited(triggerRoot.sectionId);
            }
        }

        // The pointer-move report that arms D-18-19's suppression latch —
        // the direct replacement for MouseArea.onPositionChanged, which
        // cannot fire now that this trigger's MouseArea reports no hover.
        // QQuickSinglePointHandler emits pointChanged for every event the
        // handler processes, so this fires on hover MOTION and not only on
        // the enter edge, which is what keeps the latch's actual meaning —
        // the pointer moved after the bar settled — instead of arming it on
        // the reveal gesture that put the pointer here in the first place.
        // Guarded on hovered because the leave event updates the point too,
        // and a leave is not a move within the entry.
        onPointChanged: {
            if (triggerHoverHandler.hovered)
                PopoutController.entryMoved(triggerRoot.sectionId);
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
            // Publish the anchor HERE as well as on the two pointer paths
            // (quick task 260825-pyf). `publishAnchor()` used to be called
            // only from the hover-entered and click handlers, so a popout
            // summoned any OTHER way — the `popout` IPC target, or anything
            // that sets PopoutController.openSection directly — arrived with
            // `_publishedCentre` still 0 and rooted its bulge at the top of
            // the bar instead of beside this entry. Measured exactly that
            // way: `triggerCentre=0 rootCentre=164` on an IPC-opened wifi
            // popout.
            //
            // This is the one place EVERY summon path passes through, since
            // the loader activates off `openSection` regardless of who set
            // it — so publishing here makes the anchor correct by
            // construction rather than by remembering to add a call to each
            // new caller. The pointer paths keep their own calls: they fire
            // BEFORE the section opens, so they still supply a fresher
            // reading for the common case.
            triggerRoot.publishAnchor();
            popoutLoader.item.vertical = Qt.binding(function () { return BarEntryModel.isVertical; });
            popoutLoader.item.pinned = Qt.binding(function () { return triggerRoot.pinned; });
            popoutLoader.item.triggerCentre = Qt.binding(function () { return triggerRoot._publishedCentre; });
            // `closeNow`, not `close`: this is the END of the exit, so it
            // tears the loader down. `close()` merely ASKS, and the ask is
            // relayed the other way by the connection just below — without
            // that pair the surface was destroyed on the first frame of its
            // own exit (quick task 260825-x9p round 3).
            popoutLoader.item.dismissFinished.connect(PopoutController.closeNow);
            PopoutController.dismissAsked.connect(popoutLoader.item.requestDismiss);
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
