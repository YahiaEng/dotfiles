// TrayCapsule.qml — the system tray slot (Phase 18 Plan 05, D-18-10).
//
// Owner: 18-10 — native Quickshell.Services.SystemTray plus
// Quickshell.DBusMenu, always visible with no chevron and no threshold
// collapse per D-18-04, bounded at trayMaxExtent with internal scroll.
// Entries BarEntryModel already declares for this capsule: `tray`.
//
// At zero tray icons this capsule collapses and disappears from the
// layout entirely — the shared chrome's own visibility rule already
// delivers that, so this file does not reimplement it.
//
// ── 18-10 Task 1: the icon row, end to end ───────────────────────────────
// This is the repo's first Quickshell.Services.SystemTray consumer.
// SystemTray.items is a live model whose contents arrive ASYNCHRONOUSLY
// after shell start — a StatusNotifierItem registers with the watcher some
// time after this process is running, so an empty tray at first paint is
// the SAME observable state as a machine running no tray applications at
// all. That is why this file renders neither a skeleton nor a placeholder
// in that window (UI-SPEC E5 loading): a skeleton would flash on every
// shell start, on every machine, forever.
//
// EVERY registered item renders — no filter on `status` or `category`
// anywhere below. An item reporting Status.Passive is the application
// saying it currently has nothing to show, and the common tray convention
// elsewhere is to hide it; this file deliberately does not. D-18-04's
// "always visible, no threshold collapse" and this phase's standing
// no-capability-reduction rule both point the same direction: showing MORE
// than the retired bar did can never be a GATE-02 regression, while
// silently hiding one of the user's own running applications could be —
// and the user would have no way to discover the omission. `status` is
// therefore read-but-unused for visuals: UI-SPEC's tray section names
// exactly one non-default cell state (the broken-pixmap placeholder
// below), and inventing a second attention treatment would be chrome no
// contract authored.
//
// Orientation is inherited from the shared chrome's own `vertical`
// property (BarCapsule, itself reading BarEntryModel.isVertical) — this
// file must never read the orientation state file directly or introduce a
// second orientation source. 18-05's one-value discipline, unchanged here.
//
// No tray tooltip is rendered this phase. UI-SPEC E5 long-text states tray
// icons carry no text at all, and the only tray string it specifies a
// treatment for is the menu row (Task 2). The hover contract that would
// govern a tooltip — the dwell gate, the reveal-settled suppression latch,
// the one-open-at-a-time rule — belongs to 18-13, which 18-05 already
// forbade stubbing early. Named as a carry-forward to 18-13, not a silent
// drop: it also means `title`, `tooltipTitle` and `tooltipDescription`
// never reach the screen at all in this phase — the strongest available
// mitigation for three of the four untrusted tray strings (T-18-10-04).
//
// Nothing in this file launches a subprocess, imports the process/IO
// module, or constructs a command/dispatch string; every update arrives on
// a property-change notification from Quickshell's own services, so no
// repeating timer and no polling loop exists anywhere in it — the zero
// idle-cost commitment this always-mounted, first no-dismissed-state
// surface makes to QBAR-11's soak.
import QtQuick
import Quickshell.Services.SystemTray
// Quickshell.Widgets ships inside the already-installed quickshell package
// (registered in its own qmldir); this is this repo's first import of it,
// so no dependency is added.
import Quickshell.Widgets
import "../"
import "../dashboard"

BarCapsule {
    id: trayRoot
    capsuleId: "tray"

    // ── Geometry — named tokens, never a bare literal at a call site ────
    // FIXED cell size: the tray never shrinks its icons to fit more items,
    // because that would break the bar's one-uniform-icon-size rule.
    // 24 (Design.iconSizeMd) + 4*2 (Design.spacingXs padding) = 32.
    readonly property int cellPitch: Design.iconSizeMd + Design.spacingXs * 2
    readonly property int cellGap: Design.spacingXs

    // One axis-bound positioner for the icon row — the identical
    // single-positioner idiom BarCapsule's own content Grid and Bar.qml's
    // three zone containers already use, for the identical reason a
    // Row/Column pair would be the forked-arrangement failure in
    // miniature. This Grid is itself the lone child BarCapsule's own
    // content Grid receives, so the tray nests one axis-bound positioner
    // inside another rather than declaring a second kind of layout.
    Grid {
        id: trayIconGrid
        spacing: trayRoot.cellGap
        rows: trayRoot.vertical ? -1 : 1
        columns: trayRoot.vertical ? 1 : -1

        Repeater {
            id: trayRepeater
            model: SystemTray.items

            delegate: Item {
                id: trayDelegate
                required property var modelData
                width: trayRoot.cellPitch
                height: trayRoot.cellPitch

                IconImage {
                    id: trayIcon
                    anchors.centerIn: parent
                    implicitSize: Design.iconSizeMd
                    asynchronous: true
                    source: trayDelegate.modelData ? trayDelegate.modelData.icon : ""
                    visible: status === Image.Ready
                }

                // The "apps" Material Symbol placeholder — the SAME glyph
                // WorkspaceCapsule.qml (18-09) uses for an unresolvable
                // app icon, one placeholder across the whole bar rather
                // than two conventions. Shown whenever the image is NOT
                // ready: null, empty, still loading and genuinely broken
                // all land on this one treatment deliberately, because
                // from the user's side the four are indistinguishable.
                // Occupies the identical cell geometry so the row never
                // reflows when an icon resolves late.
                Text {
                    anchors.centerIn: parent
                    font.family: Design.symbolFontFamily
                    font.pixelSize: Design.iconSizeMd
                    color: trayRoot.contentColour
                    text: "apps"
                    visible: trayIcon.status !== Image.Ready
                }

                // Primary click reaches activate(); middle click reaches
                // secondaryActivate(). The onlyMenu branch is left
                // deliberately incomplete here — Task 2 completes it once
                // the menu surface exists to open. The right button is
                // NOT accepted yet: a right-click that visibly does
                // nothing is a worse intermediate state than one that is
                // not accepted at all, and Task 2 adds it with the menu.
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                    onClicked: mouse => {
                        if (!trayDelegate.modelData)
                            return;
                        if (mouse.button === Qt.LeftButton) {
                            if (trayDelegate.modelData.onlyMenu) {
                                // Task 2: open the menu here instead, for
                                // an item declaring it has no activation
                                // action.
                            } else {
                                trayDelegate.modelData.activate();
                            }
                        } else if (mouse.button === Qt.MiddleButton) {
                            trayDelegate.modelData.secondaryActivate();
                        }
                    }
                }
            }
        }
    }
}
