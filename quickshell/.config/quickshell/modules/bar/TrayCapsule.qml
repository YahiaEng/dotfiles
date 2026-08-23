// TrayCapsule.qml — the system-tray capsule (quick task 260823-65s).
// Reinstates StatusNotifierItem hosting, lost when waybar was retired
// (Phase 18 Plan 20, RETIRE-02) and the previous tray capsule was deleted
// (Phase 18.1 Plan 04, D-15). See this file's own qmldir row for the D-15
// history note and CONTEXT.md (260823-65s) for the operator decisions
// (D-1..D-4) and D-5 amendment this file implements.
//
// D-1 — up to 3 items render inline; the rest live behind a chevron/popout
// (TrayPopout.qml, wired in Task 2). D-2 — every SNI status renders; no
// hide, no dim, ever (Passive is a known-inconsistent flag and Steam is a
// known offender — hiding it would reproduce the exact fault this capsule
// exists to fix). D-5 — nm-applet/blueman-applet are excluded; see
// _trayExcludedIdPrefixes below.
//
// CORRECTION 1 (CONTEXT.md, measured against
// quickshell-service-statusnotifier.qmltypes): `SystemTrayItem.icon` is
// a resolved image:// URI Quickshell itself supplies, NOT a raw theme
// name/path. It is bound straight to IconImage.source below — routing it
// through Quickshell.iconPath()/hasThemeIcon() (the chain the source todo
// asked for, built for NOTIFICATION appIcon strings) is a category error.
// If an icon ever renders as a broken texture, diagnose against the live
// item; do not reinstate that chain.
//
// CORRECTION 2 — there is no rightClick/openMenu method. The context menu
// is opened via `item.display(parentWindow, x, y)`; Quickshell renders the
// DBusMenu itself. No QML menu tree is hand-rolled anywhere in this file.
//
// CORRECTION 3 — `onlyMenu` items have no activate action; left click must
// fall through to display() for them, or the click does nothing visible.
import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import "../"
import "../dashboard"

BarCapsule {
    id: root
    capsuleId: "systemTray"

    // Tight action-glyph pitch (matches the connections drawer's own
    // glyph-to-glyph spacing), not BarCapsule's 18px intra-group default —
    // this row is a set of bare icon cells, not text-bearing readouts.
    contentGap: Design.spacingXs

    // ── D-5 AMENDMENT (post-planning, CONTEXT.md) — exclude nm-applet and
    //    blueman-applet from the tray model. ─────────────────────────────
    //
    // This does NOT re-open 18.1 D-15 (the tray capsule's removal) — it
    // reinstates only the half of it that was genuinely lost. D-15's own
    // reason, recorded at v4.0-REQUIREMENTS.md:20 under QBAR-05, is that
    // upstream Athena dropped its tray because nm-applet/blueman icons
    // DUPLICATED the connections group. That is still true here today:
    // MediaConnectivityCapsule.qml renders `network` and `bluetooth`
    // entries two capsules to the left of this one. With D-1's 3-slot
    // inline row, letting both applets in risks crowding Steam — the app
    // this capsule exists to fix — straight into the overflow popout.
    //
    // MEASURED 2026-08-23 (Task 2's own restart gave this host its first
    // StatusNotifierWatcher, so the real ids could finally be read via
    // busctl rather than guessed, closing CONTEXT.md's own live-state
    // caveat): nm-applet registers `Id: "nm-applet"` — the guessed prefix
    // was right. blueman-applet registers `Id: "blueman"` — NOT
    // "blueman-applet"; the original guess here would have MISSED it
    // (harmless per this comment's own fail-safe rule, but pointless).
    // Corrected to the measured value. This list is matched by
    // case-insensitive PREFIX so a vendor-suffixed id ("nm-applet-2", say)
    // still matches, but it is never widened to a bare substring — a miss
    // is harmless (the icon just renders, exactly today's status quo),
    // while an over-broad match would hide an unrelated app, which is the
    // severe direction. When in doubt, this must fail toward rendering
    // the item, not hiding it.
    readonly property var _trayExcludedIdPrefixes: ["nm-applet", "blueman"]

    function _isExcludedTrayId(id) {
        if (!id)
            return false;
        var lower = String(id).toLowerCase();
        for (var i = 0; i < root._trayExcludedIdPrefixes.length; i++) {
            if (lower.indexOf(root._trayExcludedIdPrefixes[i]) === 0)
                return true;
        }
        return false;
    }

    // ── The model — D-1's inline/overflow split ──────────────────────────
    // SystemTray.items is an UntypedObjectModel; .values is a plain JS
    // array with its own change notification (valuesChanged), so this
    // re-evaluates live and can be .slice()d with no manual index
    // bookkeeping — the identical idiom Launcher.qml already uses over a
    // different ObjectModel (DesktopEntries.applications.values.filter(...)).
    readonly property var _rawTrayItems: SystemTray.items.values
    readonly property var trayItems: root._rawTrayItems.filter(function (item) {
        return item && !root._isExcludedTrayId(item.id);
    })

    // D-2 — no filter on status or category anywhere in this file. The SNI
    // spec says hide Passive; apps set it inconsistently and Steam is a
    // known offender. Hiding Passive risks making Steam vanish from the
    // tray, which is the exact fault this capsule exists to fix. Do not
    // "restore spec compliance" here.
    readonly property int inlineLimit: 3
    readonly property var inlineItems: root.trayItems.slice(0, root.inlineLimit)

    // ── Icon tint (quick task 260823-65s, operator round-3 feedback:
    //    "we already colour/theme all the other icons/pills/glyphs, this
    //    should not be an exception") — a LIVE Prefs read, re-evaluated
    //    on every getValue() call the same way every other Prefs-backed
    //    binding in this shell already is (Prefs._data is reassigned
    //    wholesale on write, which is what makes a `property var`
    //    binding re-fire). The colour source below (root.contentColour)
    //    is equally live — it traces to BarRoles.capsuleFg ->
    //    Colours.onSurfaceVariant, the same singleton chain every other
    //    themed bar glyph already reads, so this recolours on a theme
    //    switch exactly like its neighbours.
    //
    // ROUND-4 CORRECTION (operator: "Monochrome and desaturated look
    // exactly the same") — the FIRST implementation built "monochrome"
    // on `colorization: 1.0`, on the unverified assumption that a full
    // colorization amount flattens every source pixel to one solid
    // colour. That assumption was never measured: no shader source,
    // formula, or doc comment for `MultiEffect.colorization` exists
    // anywhere on this host (checked plugins.qmltypes, the private C++
    // headers, and the compiled libQt6QuickEffects.so's own symbol
    // table — none carry the actual blend formula). With `saturation:
    // -1.0` applied unconditionally in both branches, the two modes
    // differed only in colorization STRENGTH (1.0 vs 0.55) over the
    // SAME greyscale image — both a weak wash of one muted tone
    // (BarRoles.capsuleFg -> Colours.onSurfaceVariant, `#a89984` on the
    // live palette) at 16px, which is exactly what the operator
    // reported as indistinguishable.
    //
    // Fixed by construction instead of by tuning a number: "monochrome"
    // is now a genuine flat silhouette via MultiEffect's MASK path
    // (`maskSource`/`maskEnabled`) — a solid Rectangle in the content
    // colour, masked by the icon's own alpha. A masked solid fill is
    // definitionally one colour; there is no shader semantic left to
    // get wrong. This is the SAME mask technique already shipped in
    // this repo (NotifGroup.qml/NotifCard.qml's picture-masking
    // MultiEffect blocks), reused rather than invented. "desaturate" no
    // longer carries any colorization tint at all — the operator's own
    // word choice: desaturate means greyscale, not "greyscale then
    // partially re-tinted", and the re-tint is what collapsed it into
    // monochrome. Pure `saturation: -1.0` is unambiguous against a true
    // flat silhouette by construction, with no tuning required.
    readonly property string trayIconTint: Prefs.getValue("bar.tray.iconTint")
    readonly property bool _tintMonochrome: root.trayIconTint === "monochrome"
    readonly property bool _tintDesaturate: root.trayIconTint === "desaturate"
    readonly property bool _tintActive: root._tintMonochrome || root._tintDesaturate

    Repeater {
        model: root.inlineItems
        delegate: Item {
            id: trayCell
            required property var modelData

            width: Design.barGlyphSize + Design.spacingXs * 2
            height: Design.barGlyphSize + Design.spacingXs * 2

            // ── Tooltip text (Task 3 operator feedback, 260823-65s) —
            //    SystemTrayItem exposes tooltipTitle/tooltipDescription;
            //    reading them here matches 4 of this capsule's 5
            //    neighbours (IdleInhibitorCapsule x2, MediaConnectivity-
            //    Capsule, ClockActionsCapsule, LauncherCapsule each carry
            //    a BarTooltipHost; only WorkspaceCapsule has none) rather
            //    than silently dropping data the protocol hands us.
            //    tooltipTitle wins over title; tooltipDescription is
            //    appended only when it is non-empty AND differs from the
            //    text already shown, so a description that merely repeats
            //    the title never duplicates a line.
            readonly property string _tooltipTitle: (trayCell.modelData && trayCell.modelData.tooltipTitle) ? trayCell.modelData.tooltipTitle : ""
            readonly property string _tooltipBase: trayCell._tooltipTitle !== "" ? trayCell._tooltipTitle : ((trayCell.modelData && trayCell.modelData.title) ? trayCell.modelData.title : "")
            readonly property string _tooltipDescription: (trayCell.modelData && trayCell.modelData.tooltipDescription) ? trayCell.modelData.tooltipDescription : ""
            readonly property string _tooltipText: {
                if (trayCell._tooltipBase === "")
                    return "";
                if (trayCell._tooltipDescription !== "" && trayCell._tooltipDescription !== trayCell._tooltipBase)
                    return trayCell._tooltipBase + "\n" + trayCell._tooltipDescription;
                return trayCell._tooltipBase;
            }

            // Resolved image:// URI straight from Quickshell — see
            // CORRECTION 1 above. Empty only when the item genuinely
            // supplies no icon.
            //
            // Icon tint (260823-65s, rebuilt round 4) — painted THREE
            // different ways depending on root.trayIconTint:
            //   "off"        -> trayIcon renders itself directly, exactly
            //                    as before this task existed. Neither
            //                    Loader below is ever active — this mode
            //                    costs nothing and cannot alter a single
            //                    pixel.
            //   "monochrome" -> trayIcon becomes an ALPHA MASK ONLY
            //                    (never its own colour); traySilhouetteFill
            //                    below is the actual colour source. Both
            //                    need visible:false + layer.enabled:true to
            //                    hand MultiEffect a texture while painting
            //                    nothing themselves (NotifCentre.qml's own
            //                    empty-illustration precedent).
            //   "desaturate" -> trayIcon becomes a plain saturation:-1.0
            //                    texture source (no mask, no tint).
            IconImage {
                id: trayIcon
                anchors.centerIn: parent
                implicitSize: Design.barGlyphSize
                asynchronous: true
                source: trayCell.modelData ? trayCell.modelData.icon : ""
                visible: trayIcon.status === Image.Ready && !root._tintActive
                layer.enabled: root._tintActive
                opacity: trayIcon.status === Image.Ready ? 1 : 0

                Behavior on opacity {
                    enabled: Motion.motionEnabled
                    NumberAnimation {
                        duration: Motion.standardDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Motion.standardEasing
                    }
                }
            }

            // The "monochrome" mode's ONLY colour source — a flat fill,
            // never painted itself (visible: false), fed into the mask
            // MultiEffect below as `source`. Never touched by saturation
            // or colorization: it IS the exact content colour already,
            // and a masked solid fill is one colour by definition — there
            // is no shader semantic left to depend on.
            Rectangle {
                id: traySilhouetteFill
                anchors.fill: trayIcon
                color: root.contentColour
                visible: false
                layer.enabled: root._tintMonochrome
            }

            // "monochrome" — NotifGroup.qml/NotifCard.qml's own picture-
            // masking MultiEffect shape, reused verbatim: `source` is the
            // flat fill, `maskSource` is the icon (read for its ALPHA
            // channel only, never its colour), so the result is the
            // icon's own silhouette filled solid. anchors.fill: parent,
            // NOT trayIcon — MEASURED live on this task's own prior round
            // (quickshell.log: "Cannot anchor to an item that isn't a
            // parent or sibling"): a Loader's sourceComponent item is a
            // CHILD of the Loader, so a Loader SIBLING (trayIcon) is two
            // levels away, not one. `parent` here is the Loader, which
            // already carries `anchors.fill: trayIcon` below.
            Loader {
                anchors.fill: trayIcon
                active: root._tintMonochrome
                sourceComponent: MultiEffect {
                    anchors.fill: parent
                    source: traySilhouetteFill
                    maskEnabled: true
                    maskSource: trayIcon
                    maskThresholdMin: 0.5
                    maskSpreadAtMin: 1.0
                    visible: trayIcon.status === Image.Ready
                    opacity: trayIcon.opacity
                }
            }

            // "desaturate" — greyscale, nothing else. No colorization:
            // the operator's own word choice means "strip hue", not
            // "strip hue then partially re-tint" — the re-tint is what
            // made the previous build collapse into monochrome.
            Loader {
                anchors.fill: trayIcon
                active: root._tintDesaturate
                sourceComponent: MultiEffect {
                    anchors.fill: parent
                    source: trayIcon
                    saturation: -1.0
                    visible: trayIcon.status === Image.Ready
                    opacity: trayIcon.opacity
                }
            }

            // Fallback for the genuinely-empty/not-yet-resolved case,
            // occupying the identical cell geometry so the row never
            // reflows when an async icon resolves late.
            Text {
                anchors.centerIn: parent
                text: "apps"
                font.family: Design.symbolFontFamily
                font.pixelSize: Design.barGlyphSize
                textFormat: Text.PlainText
                elide: Text.ElideRight
                color: root.contentColour
                visible: trayIcon.status !== Image.Ready
            }

            // D-2's NeedsAttention accent — a small dot, never a hide or a
            // dim for any other status.
            Rectangle {
                width: Design.spacingXs
                height: Design.spacingXs
                radius: width / 2
                color: BarRoles.fillNotification
                anchors.top: parent.top
                anchors.right: parent.right
                visible: trayCell.modelData ? trayCell.modelData.status === Status.NeedsAttention : false
            }

            // Interaction contract (CONTEXT.md): left activates unless
            // onlyMenu (CORRECTION 3, then falls through to the menu);
            // middle is the secondary action; right opens the menu.
            // display() is called on THIS popup's own window handle — see
            // CORRECTION 2, no menu is ever hand-rolled here.
            //
            // KNOWN GAP, investigated and left unfixed (Task 3 operator
            // feedback, 260823-65s) — Steam's own SNI item implements NO
            // Activate D-Bus method at all (measured: `busctl --user call
            // ... Activate ii 0 0` -> "No such method") while ALSO
            // reporting `ItemIsMenu: false`/`onlyMenu: false` — it
            // under-reports its own capability against the very spec
            // CORRECTION 3's guard trusts. Quickshell exposes no property
            // that distinguishes "this item lacks Activate" from "it has
            // Activate but it's a no-op" (activate() is fire-and-forget,
            // no reply is surfaced to QML), and `hasMenu` is NOT a usable
            // substitute — measured true for BOTH Steam (non-compliant)
            // and Discord (spec-compliant, activate() genuinely restores
            // its window), so branching on it would show a menu on every
            // left click for compliant apps too, breaking their contract.
            // No safe, non-fragile fix exists at this layer: left click on
            // an app that lies about onlyMenu correctly does nothing
            // (activate() is called and silently no-ops). The operator's
            // real path to Steam's menu is RIGHT click, which the
            // `//@ pragma UseQApplication` fix (shell.qml) makes work.
            MouseArea {
                id: trayMouseArea
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                // Needed for containsMouse below (the tooltip's hover
                // signal) — verified this changes no click behaviour:
                // acceptedButtons/onClicked are unaffected by hoverEnabled.
                hoverEnabled: true
                onClicked: (mouse) => {
                    if (!trayCell.modelData)
                        return;
                    if (mouse.button === Qt.MiddleButton) {
                        trayCell.modelData.secondaryActivate();
                        return;
                    }
                    var origin = trayCell.mapToItem(null, 0, trayCell.height);
                    if (mouse.button === Qt.RightButton) {
                        trayCell.modelData.display(QsWindow.window, origin.x, origin.y);
                        return;
                    }
                    // Left button.
                    if (trayCell.modelData.onlyMenu)
                        trayCell.modelData.display(QsWindow.window, origin.x, origin.y);
                    else
                        trayCell.modelData.activate();
                }
            }

            // BarTooltipHost pattern (IdleInhibitorCapsule.qml's own
            // instance, copied exactly) — NOT a QtQuick.Controls ToolTip,
            // which that file's own comment records is clamped wrong in
            // the 42px bar window. Gated on non-empty text too, so a rare
            // item with neither a title nor a tooltip never mounts an
            // empty surface. tipId keyed off the item's own id (already
            // load-bearing for the D-5 exclusion filter, so guaranteed
            // present) so two tray items can never collide in the host.
            BarTooltipHost {
                anchorItem: trayCell
                text: trayCell._tooltipText
                active: trayMouseArea.containsMouse && trayCell._tooltipText !== ""
                tipId: "systemTray-" + (trayCell.modelData ? trayCell.modelData.id : "")
            }
        }
    }

    // ── D-1's overflow half — a counted chevron opening TrayPopout.qml
    //    through the shared PopoutController/SectionPopout machinery
    //    (PopoutController.qml's "tray" section). No second popout
    //    mechanism is introduced. ───────────────────────────────────────
    readonly property int overflowCount: Math.max(0, root.trayItems.length - root.inlineLimit)
    readonly property var overflowItems: root.trayItems.slice(root.inlineLimit)

    PopoutTrigger {
        id: trayOverflowTrigger
        sectionId: "tray"
        // Both the trigger AND its child carry `visible: overflowCount > 0`
        // (MediaConnectivityCapsule.qml's own Rule-1 note): PopoutTrigger
        // wraps a plain Item, not a positioner, so its own implicit size
        // does not collapse to zero just because its child is invisible —
        // without this the content Grid keeps reserving space for an
        // empty chevron cell at 0-3 items.
        visible: root.overflowCount > 0
        popoutComponent: Component {
            TrayPopout {
                overflowItems: root.overflowItems
            }
        }

        // The chevron cell. No second MouseArea here — PopoutTrigger owns
        // its own click/hover paths (see that file's own contentHost
        // z: 1 stacking note); a nested MouseArea would sit above it and
        // swallow the click.
        Item {
            id: trayOverflowCell
            visible: root.overflowCount > 0
            width: overflowRow.implicitWidth + Design.spacingXs * 2
            height: Design.barGlyphSize + Design.spacingXs * 2

            Row {
                id: overflowRow
                anchors.centerIn: parent
                spacing: Design.spacingXs / 2

                Text {
                    text: "expand_more"
                    font.family: Design.symbolFontFamily
                    font.pixelSize: Design.barGlyphSize
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    color: root.contentColour
                }

                Text {
                    text: String(root.overflowCount)
                    font.pixelSize: Design.barBodySize
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    color: root.contentColour
                }
            }
        }
    }
}
