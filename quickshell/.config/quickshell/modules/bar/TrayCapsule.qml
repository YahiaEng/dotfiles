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
import Quickshell
import Quickshell.Services.SystemTray
// Quickshell.Widgets ships inside the already-installed quickshell package
// (registered in its own qmldir); this is this repo's first import of it,
// so no dependency is added.
import Quickshell.Widgets
import Quickshell.Hyprland
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

    // ── 18-10 Task 2: one-open-at-a-time menu ownership ──────────────────
    // A single root-level property holding the delegate whose menu is
    // open, so opening a second menu closes the first through one guarded
    // path rather than two independent booleans racing — the same
    // one-open-at-a-time discipline shell.qml's own openPanel() already
    // establishes for every other summonable surface in this shell.
    property var openMenuFor: null

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
                    textFormat: Text.PlainText
                    font.family: Design.symbolFontFamily
                    font.pixelSize: Design.iconSizeMd
                    color: trayRoot.contentColour
                    text: "apps"
                    visible: trayIcon.status !== Image.Ready
                }

                // ── 18-10 Task 2: the menu ───────────────────────────────
                // The verified chain: StatusNotifierItem.menu (a
                // DBusMenuHandle) exposes its OWN readonly `menu` property
                // (a DBusMenuItem, whose prototype chain is
                // DBusMenuItem -> QsMenuEntry -> QsMenuHandle, so it is
                // exactly what QsMenuOpener.menu accepts) -> QsMenuOpener
                // .children, an UntypedObjectModel consumed by a Repeater,
                // never indexed by hand. Optional-chaining/nullish
                // coalescing (already this repo's idiom —
                // BluetoothBackend.qml) keeps an item with no menu
                // (`modelData.menu` null) from throwing rather than
                // needing an if/else branch here.
                QsMenuOpener {
                    id: menuOpener
                    menu: modelData.menu?.menu ?? null
                }

                // Submenu drill-in: one surface replaces its own row list
                // with the clicked entry's children plus a leading back
                // row, rather than opening a second anchored window — a
                // second window would need its own edge clamping and its
                // own dismissal for no capability gain, and every entry
                // stays reachable either way.
                property var drilledEntry: null
                QsMenuOpener {
                    id: drillOpener
                    menu: trayDelegate.drilledEntry ?? null
                }

                readonly property bool menuVisible: trayRoot.openMenuFor === trayDelegate

                function closeMenu() {
                    trayDelegate.drilledEntry = null;
                    if (trayRoot.openMenuFor === trayDelegate)
                        trayRoot.openMenuFor = null;
                }

                // Primary click reaches activate(), UNLESS the item
                // declares onlyMenu (no activation action at all — common
                // for menu-only tray items), in which case a primary click
                // opens the menu too. This is what makes QBAR-05's "menus
                // open on click" literally true for menu-only items rather
                // than only for right-click. Middle click reaches
                // secondaryActivate(). Right click opens the menu when the
                // item declares hasMenu, and does nothing otherwise — it
                // is handled by the final `else`, since `acceptedButtons`
                // below restricts this MouseArea to exactly Left/Middle/
                // Right, so anything that is neither Left nor Middle can
                // only be Right.
                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                    onClicked: mouse => {
                        if (!trayDelegate.modelData)
                            return;
                        if (mouse.button === Qt.MiddleButton) {
                            trayDelegate.modelData.secondaryActivate();
                        } else if (mouse.button === Qt.LeftButton && !trayDelegate.modelData.onlyMenu) {
                            trayDelegate.modelData.activate();
                        } else if (trayDelegate.modelData.hasMenu) {
                            trayRoot.openMenuFor = trayDelegate;
                        }
                    }
                }

                // The menu surface — an inline PopupWindow, declared as a
                // plain child object with no qmldir registration, which is
                // what keeps this plan off 18-05's frozen manifest. One
                // PopupWindow per delegate, `visible` gated by
                // `menuVisible` rather than created/destroyed.
                PopupWindow {
                    id: trayMenuPopup
                    // Inline per UI-SPEC's own declaration — used exactly
                    // once, so no Design.qml token is minted for it. Not
                    // related to Design.trayMaxExtent (Task 3): that bound
                    // is the icon row's own axis, this is the menu
                    // surface's fixed width.
                    readonly property int menuWidth: 220

                    visible: trayDelegate.menuVisible
                    color: "transparent"
                    grabFocus: true
                    implicitWidth: trayMenuPopup.menuWidth
                    implicitHeight: menuColumn.implicitHeight

                    anchor.item: trayDelegate
                    // Margins is a grouped value type (left/right/top/
                    // bottom ints) — found live: a bare scalar assignment
                    // produced "Unable to assign int to Margins" in
                    // quickshell.log. All four sides get the identical
                    // Design.spacingXs gap.
                    anchor.margins.left: Design.spacingXs
                    anchor.margins.right: Design.spacingXs
                    anchor.margins.top: Design.spacingXs
                    anchor.margins.bottom: Design.spacingXs
                    anchor.edges: trayRoot.vertical ? Edges.Left : Edges.Bottom
                    anchor.gravity: trayRoot.vertical ? Edges.Left : Edges.Bottom

                    // Belt-and-suspenders dismissal: `grabFocus: true`
                    // above is Quickshell's own click-outside-closes
                    // mechanism; this repo's proven `HyprlandFocusGrab` +
                    // `onCleared` fallback (PanelDialog.qml:200-208) is
                    // layered on top rather than assumed sufficient,
                    // because which of the two this build actually needs
                    // was not resolved by a live observation this session
                    // (see the SUMMARY). Also closes when the entry's
                    // backing handle goes away, so an application that
                    // unregisters mid-open leaves no orphan surface.
                    HyprlandFocusGrab {
                        id: menuFocusGrab
                        windows: [trayMenuPopup]
                        active: trayDelegate.menuVisible
                        onCleared: trayDelegate.closeMenu()
                    }

                    Connections {
                        target: trayDelegate.modelData
                        function onHasMenuChanged() {
                            if (!trayDelegate.modelData.hasMenu)
                                trayDelegate.closeMenu();
                        }
                    }

                    // The one legitimate background rectangle in this
                    // file — the popup is a separate window with no
                    // chrome to inherit, unlike the capsule itself (which
                    // still declares none of its own). Radius 12 is
                    // UI-SPEC's deliberate choice of lighter chrome than a
                    // section popout's radius, because this is a menu
                    // list rather than a custom popout.
                    Rectangle {
                        id: menuSurface
                        anchors.fill: parent
                        radius: 12
                        color: Colours.surfaceVariant

                        Column {
                            id: menuColumn
                            width: trayMenuPopup.menuWidth
                            padding: Design.spacingXs

                            // Back row — visible only while drilled into a
                            // submenu, clears drilledEntry on click so a
                            // re-opened menu always starts at its top
                            // level (also reset in closeMenu()).
                            Item {
                                width: menuColumn.width - menuColumn.padding * 2
                                height: visible ? Design.iconSizeMd + Design.spacingSm * 2 : 0
                                visible: trayDelegate.drilledEntry !== null

                                Row {
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.left: parent.left
                                    anchors.leftMargin: Design.spacingSm
                                    spacing: Design.spacingSm

                                    Text {
                                        textFormat: Text.PlainText
                                        font.family: Design.symbolFontFamily
                                        font.pixelSize: Design.iconSizeMd
                                        color: Colours.onSurfaceVariant
                                        text: "arrow_back"
                                    }
                                    Text {
                                        textFormat: Text.PlainText
                                        font.pixelSize: Design.fontBody
                                        color: Colours.onSurfaceVariant
                                        text: "Back"
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: trayDelegate.drilledEntry = null
                                }
                            }

                            Repeater {
                                id: menuRepeater
                                model: trayDelegate.drilledEntry !== null ? drillOpener.children : menuOpener.children

                                delegate: Item {
                                    id: menuRowRoot
                                    required property var modelData
                                    width: menuColumn.width - menuColumn.padding * 2
                                    height: menuRowRoot.modelData && menuRowRoot.modelData.isSeparator ? (1 + Design.spacingXs * 2) : (Design.iconSizeMd + Design.spacingSm * 2)

                                    // Separator — a 1px outline divider,
                                    // no text, no hit area.
                                    Rectangle {
                                        visible: menuRowRoot.modelData ? menuRowRoot.modelData.isSeparator : false
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        height: 1
                                        color: Colours.outline
                                    }

                                    Item {
                                        id: menuRowContent
                                        anchors.fill: parent
                                        visible: menuRowRoot.modelData ? !menuRowRoot.modelData.isSeparator : false
                                        // Disabled: 0.38 opacity, hit area
                                        // still present but performing no
                                        // activation (PanelDialog.qml's
                                        // exact disabled treatment,
                                        // D-15-22) — the row stays laid
                                        // out identically rather than
                                        // being removed, so the menu's
                                        // shape does not change between an
                                        // application's enabled and
                                        // disabled states.
                                        opacity: (menuRowRoot.modelData && !menuRowRoot.modelData.enabled) ? 0.38 : 1

                                        Rectangle {
                                            id: menuRowHoverBg
                                            anchors.fill: parent
                                            color: menuRowHover.hovered ? Colours.surface : "transparent"
                                            Behavior on color {
                                                enabled: Motion.motionEnabled
                                                ColorAnimation {
                                                    duration: Motion.standardDuration
                                                    easing.type: Easing.BezierSpline
                                                    easing.bezierCurve: Motion.standardEasing
                                                }
                                            }
                                        }
                                        HoverHandler {
                                            id: menuRowHover
                                        }

                                        Row {
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.left: parent.left
                                            anchors.leftMargin: Design.spacingSm
                                            spacing: Design.spacingSm

                                            // Leading affordance — width
                                            // reserved unconditionally so
                                            // rows stay left-aligned with
                                            // each other whether or not
                                            // they carry an icon.
                                            Item {
                                                width: Design.iconSizeMd
                                                height: Design.iconSizeMd

                                                Text {
                                                    anchors.centerIn: parent
                                                    textFormat: Text.PlainText
                                                    visible: menuRowRoot.modelData && menuRowRoot.modelData.buttonType === QsMenuButtonType.CheckBox
                                                    font.family: Design.symbolFontFamily
                                                    font.pixelSize: Design.iconSizeMd
                                                    color: Colours.onSurfaceVariant
                                                    text: (menuRowRoot.modelData && menuRowRoot.modelData.checkState === Qt.Checked) ? "check_box" : "check_box_outline_blank"
                                                }
                                                Text {
                                                    anchors.centerIn: parent
                                                    textFormat: Text.PlainText
                                                    visible: menuRowRoot.modelData && menuRowRoot.modelData.buttonType === QsMenuButtonType.RadioButton
                                                    font.family: Design.symbolFontFamily
                                                    font.pixelSize: Design.iconSizeMd
                                                    color: Colours.onSurfaceVariant
                                                    text: (menuRowRoot.modelData && menuRowRoot.modelData.checkState === Qt.Checked) ? "radio_button_checked" : "radio_button_unchecked"
                                                }
                                                IconImage {
                                                    anchors.centerIn: parent
                                                    implicitSize: Design.iconSizeMd
                                                    asynchronous: true
                                                    visible: menuRowRoot.modelData && menuRowRoot.modelData.buttonType === QsMenuButtonType.None && menuRowRoot.modelData.icon !== ""
                                                    source: (menuRowRoot.modelData && menuRowRoot.modelData.buttonType === QsMenuButtonType.None) ? menuRowRoot.modelData.icon : ""
                                                }
                                            }

                                            // The label — the load-bearing
                                            // string discipline. A menu
                                            // label comes from an arbitrary
                                            // third-party application over
                                            // D-Bus and is displayed and
                                            // NOTHING else: never the rich,
                                            // markdown or styled text
                                            // formats, never parsed, never
                                            // split, never used as a
                                            // lookup key or a path, never
                                            // concatenated into a
                                            // subprocess argument or a
                                            // compositor dispatch string.
                                            // This file launches no
                                            // subprocess and imports no
                                            // process/IO module at all,
                                            // which is what makes that
                                            // guarantee structural rather
                                            // than a promise.
                                            Text {
                                                id: menuRowLabel
                                                width: trayMenuPopup.menuWidth - menuColumn.padding * 2 - Design.spacingSm * 3 - Design.iconSizeMd * 2
                                                textFormat: Text.PlainText
                                                elide: Text.ElideRight
                                                text: menuRowRoot.modelData ? menuRowRoot.modelData.text : ""
                                                font.pixelSize: Design.fontBody
                                                color: Colours.onSurfaceVariant
                                            }

                                            // Trailing affordance — a
                                            // chevron shown only when the
                                            // entry has children.
                                            Text {
                                                width: Design.iconSizeMd
                                                horizontalAlignment: Text.AlignHCenter
                                                textFormat: Text.PlainText
                                                visible: menuRowRoot.modelData ? menuRowRoot.modelData.hasChildren : false
                                                font.family: Design.symbolFontFamily
                                                font.pixelSize: Design.iconSizeMd
                                                color: Colours.onSurfaceVariant
                                                text: "chevron_right"
                                            }
                                        }

                                        MouseArea {
                                            anchors.fill: parent
                                            enabled: menuRowRoot.modelData ? menuRowRoot.modelData.enabled : false
                                            onClicked: {
                                                if (!menuRowRoot.modelData)
                                                    return;
                                                if (menuRowRoot.modelData.hasChildren) {
                                                    trayDelegate.drilledEntry = menuRowRoot.modelData;
                                                } else {
                                                    // The verified leaf-activation call — see the
                                                    // SUMMARY for the candidate ranking, the
                                                    // eliminated alternatives and their file/line
                                                    // provenance. sendTriggered() exists on the
                                                    // concrete DBusMenuItem backing every entry
                                                    // handed out by this menu's QsMenuOpener.
                                                    menuRowRoot.modelData.sendTriggered();
                                                    trayDelegate.closeMenu();
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
