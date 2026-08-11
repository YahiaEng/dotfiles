// WorkspaceCapsule.qml — the workspaces slot (Phase 18 Plan 05, D-18-10).
//
// Owner: 18-09 — live per-app window icons in athena's icon-plus-windows
// shape per D-18-02, fixed-height slots with +N overflow in BOTH
// orientations per D-18-12, click-to-switch through Quickshell.Hyprland
// copying Overview.qml's validate-before-interpolate discipline.
// Entries BarEntryModel already declares for this capsule: `workspaces`.
//
// Task 1 (tracer) proved the whole path — live model, glyph resolution,
// dispatch — on one hardcoded slot. Task 2 below generalises that proof
// into the full fixed-extent slot set: every persistent slot plus any
// workspace beyond the persistent range, each with iconsPerSlot reserved
// cells and +N overflow.
import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../"
import "../dashboard"

BarCapsule {
    id: workspaceCapsule
    capsuleId: "workspaces"

    // ── Why these three constants stay LOCAL rather than in Design.qml ──
    // None of the three appears in 18-UI-SPEC.md's "## New Tokens" table,
    // and this file is the only reader of any of them — Design.qml's own
    // header states the hoisting rule precisely: a value moves to the
    // shared singleton when TWO files need it, and its one recorded
    // deliberately-not-consolidated case (fillAxisAvailable) is a
    // per-file capability flag, not a contract token. All three below are
    // exactly that kind of value. Practical consequence: this plan
    // therefore touches exactly one file, which is what lets 18-08,
    // 18-10 and 18-11 run in the same wave with zero shared files.

    // The always-present slot range (five persistent slots).
    readonly property int persistentSlotCount: 5

    // Reserved icon cells per slot. Must be >= 2: the overflow label
    // occupies the LAST cell rather than an extra one, so a capacity of 1
    // would make every multi-window slot render an overflow count and no
    // glyph at all. 3 is derived from Design.iconSizeMd cells stacking
    // along the slot's main axis — in vertical that axis is the column's
    // length, the scarce one.
    //
    // ── Open question handed forward to 18-19 ────────────────────────────
    // At full scope the vertical column carries all six bar capsules, and
    // only 18-19's GATE-02 pass — once every capsule exists — can see
    // whether they all fit the monitor's height. If they do not, THIS
    // constant is the one sanctioned tuning knob: lowering it is a
    // one-line change. Dropping slots, hiding glyphs behind an expander,
    // or eliding any entry present in the horizontal orientation is
    // forbidden by this phase outright — stated plainly so a future
    // reader under time pressure does not reach for the wrong lever.
    readonly property int iconsPerSlot: 3

    // The Nerd Font family that renders the per-app glyphs below — a
    // hand-carried parity value in the same sense Design.qml's own
    // borderWidth is: the theme engine's live font-name state is only
    // ever rendered EMBEDDED inside app-specific fragments, never as a
    // plain scalar a QML file could watch, so this family does NOT
    // follow a live font change.
    readonly property string appGlyphFontFamily: "FiraCode Nerd Font"
    // The shared bar-wide placeholder — the same Material Symbol the
    // tray capsule uses for a broken pixmap, rendered in the symbol font.
    readonly property string appGlyphFallback: "apps"

    // ── The glyph map — an ORDERED array, not a plain object ────────────
    // Array order is defined, which is what makes the containment stage
    // of glyphFor() below resolve deterministically. Carried verbatim
    // from the retired bar's athena layout's own `window-rewrite` table,
    // in the source table's own order. The retired surface's config path
    // is deliberately not spelled out here — it will not exist once this
    // phase's retirement plan runs, and this file names the mechanism
    // (the athena `window-rewrite` map), not a path that is going away.
    //
    // Two deliberate deviations from the source table, both recorded so
    // neither reads as a transcription error:
    // (a) the source table's own default glyph ("window-rewrite-default")
    //     is NOT carried — UI-SPEC's E2-partial row requires the same
    //     "apps" Material Symbol the tray capsule uses for a broken
    //     pixmap, so the whole bar has one placeholder convention rather
    //     than two, and the two are in different fonts besides (a
    //     fallback that silently depends on font substitution renders a
    //     blank box on a host missing that font).
    // (b) [Phase 18.1 Plan 01 — D-07/D-08 correction] the source table's
    //     state icon set (active/default/urgent/empty under
    //     "format-icons") was not carried when this file was first built —
    //     this comment originally promised "state is carried by colour
    //     instead" while the actual code applied only a foreground TINT to
    //     the numeral (WorkspaceCapsule.qml's pre-18.1 line 349), never
    //     the filled pill Athena itself renders (`#workspaces
    //     button.active { background: @accent; }`,
    //     style-athena.scss:167-171). That gap between this comment's
    //     promise and the code's behaviour is the documented origin of
    //     Phase 18.1. It is now fixed on two fronts: Task 1 gave the
    //     focused slot a real background fill (`BarRoles.accent`/
    //     `BarRoles.onAccent`, via `slotFillColour`/`slotTextColour`), the
    //     urgent-and-unfocused branch stays a foreground tint
    //     (`BarRoles.danger`) matching Athena's own CSS
    //     (`style-athena.scss:175-177`), and the default branch reads
    //     `BarRoles.capsuleFg`. Task 2 restored the actual glyph identity:
    //     the plain numeral is gone, replaced by one of Athena's three
    //     Nerd Font state glyphs (`stateGlyphActive`/`stateGlyphDefault`/
    //     `stateGlyphUrgent`, `format-icons` active/default/urgent) chosen
    //     by `stateGlyphFor(focused, urgent)` with focused taking
    //     precedence over urgent — the same precedence `slotTextColour`
    //     already used. Colour and glyph now both genuinely carry state,
    //     as this comment always claimed. Accepted cost, named by D-08:
    //     the numeral's one-to-one visual mapping onto the Super+N
    //     keybinds is gone — a slot no longer shows which digit activates
    //     it. Athena's fourth state, `empty` (U+F444,
    //     style-athena.scss:180-182, opacity 0.6, for a workspace that
    //     exists but holds zero windows), is NOT implemented here — a
    //     named delta routed to GATE-02, not a silent omission; such a
    //     slot renders `stateGlyphDefault` instead.
    readonly property var appGlyphMap: [
        { appId: "kitty", glyph: "󰆍" },
        { appId: "firefox", glyph: "" },
        { appId: "zen", glyph: "" },
        { appId: "codium", glyph: "󰨞" },
        { appId: "VSCodium", glyph: "󰨞" },
        { appId: "discord", glyph: "" },
        { appId: "spotify", glyph: "" },
        { appId: "obsidian", glyph: "󰹕" },
        { appId: "net.lutris.Lutris", glyph: "" },
        { appId: "steam", glyph: "" },
        { appId: "thunar", glyph: "" },
        { appId: "yazi", glyph: "󰇥" }
    ]

    // ── Athena's three-state workspace-slot glyph identity (D-08) ───────
    // Nerd Font codepoints carried verbatim from config-athena.jsonc's own
    // `format-icons` table (active/default/urgent) — the same table
    // `appGlyphMap` above already draws its per-app glyphs' font family
    // from (`appGlyphFontFamily`). Athena's fourth state, `empty`
    // (U+F444, style-athena.scss:180-182), is a named delta NOT
    // implemented here — see the (b) note above.
    readonly property string stateGlyphActive: "󰮯"   // format-icons.active
    readonly property string stateGlyphDefault: "󰊠"  // format-icons.default
    readonly property string stateGlyphUrgent: "󰧵"   // format-icons.urgent

    // Precedence matches slotTextColour's own: focused wins over urgent,
    // urgent wins over default. Pure function, no side effects.
    function stateGlyphFor(focused, urgent) {
        if (focused)
            return workspaceCapsule.stateGlyphActive;
        if (urgent)
            return workspaceCapsule.stateGlyphUrgent;
        return workspaceCapsule.stateGlyphDefault;
    }

    // Reads a toplevel's app id off its wayland handle, null-guarding
    // both the toplevel and the handle — the same shape 16-25's
    // normalizeAddress() null-guards its own input.
    function appIdFor(toplevel) {
        if (!toplevel || !toplevel.wayland)
            return "";
        return toplevel.wayland.appId || "";
    }

    // Resolves an app id to a glyph in four stages, stopping at the first
    // hit: exact match, case-insensitive exact match, case-insensitive
    // containment (first map entry that matches in declaration order),
    // then the fallback ligature. A null/undefined/empty/whitespace-only
    // app id short-circuits straight to the fallback.
    //
    // The untrusted string is always the SUBJECT of the containment
    // search and a repo literal is always the NEEDLE — no expression is
    // ever compiled from client input, and the work is bounded at twelve
    // comparisons over one bounded string. The returned text is always
    // one of the map's own 12 literals or the fallback ligature, so no
    // client-controlled string can ever reach the screen through this
    // function. Containment is what reproduces the retired module's own
    // substring-matching behaviour (a distribution-suffixed app id still
    // resolves).
    function glyphFor(appId) {
        if (!appId || typeof appId !== "string" || appId.trim() === "")
            return { text: workspaceCapsule.appGlyphFallback, family: Design.symbolFontFamily };

        var map = workspaceCapsule.appGlyphMap;
        var i;

        for (i = 0; i < map.length; i++) {
            if (map[i].appId === appId)
                return { text: map[i].glyph, family: workspaceCapsule.appGlyphFontFamily };
        }

        var lowerAppId = appId.toLowerCase();
        for (i = 0; i < map.length; i++) {
            if (map[i].appId.toLowerCase() === lowerAppId)
                return { text: map[i].glyph, family: workspaceCapsule.appGlyphFontFamily };
        }

        for (i = 0; i < map.length; i++) {
            if (lowerAppId.indexOf(map[i].appId.toLowerCase()) !== -1)
                return { text: map[i].glyph, family: workspaceCapsule.appGlyphFontFamily };
        }

        return { text: workspaceCapsule.appGlyphFallback, family: Design.symbolFontFamily };
    }

    // Pure lookup over the live workspace list — Overview.qml's own
    // workspaceForSlot() shape, reused rather than re-derived.
    function workspaceForId(id) {
        var list = Hyprland.workspaces.values;
        for (var i = 0; i < list.length; i++) {
            if (list[i].id === id)
                return list[i];
        }
        return null;
    }

    // That workspace's toplevel array, or an empty array — null-guards
    // both the workspace and its model. No ordering pass runs over the
    // result: WorkspaceTile.qml's own toplevel repeater follows the same
    // no-sort discipline, and this file matches it.
    function windowsFor(workspace) {
        if (!workspace || !workspace.toplevels || !workspace.toplevels.values)
            return [];
        return workspace.toplevels.values;
    }

    // The range-check predicate, copied from Overview.qml's own
    // isValidWorkspaceToken (integer half only — this capsule never
    // produces the scratchpad literal).
    function isValidWorkspaceId(id) {
        return typeof id === "number" && Number.isInteger(id) && id >= 1 && id <= 10;
    }

    // Click path: the live workspace object's own activate() method is
    // tried FIRST. This is not defensive padding — it is the specific
    // defect Overview.qml's activateTile()/dispatchWorkspaceFocus() found
    // and fixed: a persistent slot for a workspace nobody has opened yet
    // has NO Hyprland object at all, so an object-only implementation
    // would leave the majority of this capsule's slots looking clickable
    // and doing nothing, which is precisely the failure QBAR-03 exists to
    // end. Only when no object exists does this fall back to a
    // range-checked integer interpolated into the SAME dispatch
    // expression keybinds.lua's own Super+N binds use. The only value
    // ever concatenated is an integer this file computed and range
    // checked — no app id, window name or address is ever concatenated
    // anywhere in this file.
    function activateWorkspace(slotId) {
        var workspace = workspaceCapsule.workspaceForId(slotId);
        if (workspace) {
            workspace.activate();
            return true;
        }
        if (!workspaceCapsule.isValidWorkspaceId(slotId)) {
            console.warn("WorkspaceCapsule: refusing workspace focus — id out of range");
            return false;
        }
        Hyprland.dispatch("hl.dsp.focus({workspace=" + String(slotId) + "})");
        return true;
    }

    // ── The full slot set ────────────────────────────────────────────────
    // The ascending union of 1..persistentSlotCount and every existing
    // workspace id above that range, excluding non-positive ids (Hyprland's
    // special workspaces, including the scratchpad — Super+S and the
    // overview own that tile; it is deliberately not a bar slot).
    //
    // Three decisions compressed into this one property, each recorded so
    // none of them reads as an oversight:
    //
    // 1. Five, not six: the canonical modules.jsonc definition shared by
    //    two of the retired layouts AND the athena layout both use 5 —
    //    three of four retired layouts agree on 5, only config-floating
    //    uses 6. That one-slot difference is a NAMED delta routed to
    //    18-19's GATE-02 criterion B; the remedy is a one-integer change
    //    to persistentSlotCount above.
    // 2. Why the dynamic tail exists at all: a workspace beyond the
    //    persistent range that actually exists would otherwise be
    //    invisible on the bar, and since the keybinds bind ten
    //    workspaces the user can be standing on one the bar does not
    //    show. The retired module behaved the same way (persistent slots
    //    plus whatever exists) — this is parity, not an addition.
    // 3. Why the dynamic tail does not violate D-18-12: that guarantee is
    //    scoped, in its own words, to nothing moving AS WINDOWS OPEN AND
    //    CLOSE. Window churn cannot change this set at all — only
    //    creating or destroying a workspace beyond the persistent range
    //    can, which is a rare, deliberate, user-initiated event, not the
    //    per-second churn the decision was written against.
    //
    // Ordering note: slot order is ascending integer id, matching the
    // retired bar's own sort-by-number behaviour, built by inserting each
    // dynamic id at its comparison-found position rather than by a
    // general sort/reverse pass — the persistent range is already
    // ascending by construction, so this is one comparison per dynamic
    // id, not a sorting algorithm over the whole set.
    readonly property var slotIds: {
        var ids = [];
        for (var p = 1; p <= workspaceCapsule.persistentSlotCount; p++)
            ids.push(p);

        var list = Hyprland.workspaces.values;
        for (var i = 0; i < list.length; i++) {
            var id = list[i].id;
            if (id <= workspaceCapsule.persistentSlotCount)
                continue;
            if (ids.indexOf(id) !== -1)
                continue;
            var insertAt = ids.length;
            for (var j = workspaceCapsule.persistentSlotCount; j < ids.length; j++) {
                if (ids[j] > id) {
                    insertAt = j;
                    break;
                }
            }
            ids.splice(insertAt, 0, id);
        }
        return ids;
    }

    // Hidden metrics text reserving the slot identity glyph's extent
    // (UI-SPEC's reserve-worst-case-width rule) — the numeral this
    // reserved is gone (D-08), so this now measures the widest of
    // Athena's three state glyphs (stateGlyphActive) in the same Nerd
    // Font family the slot delegate renders it in, so no state change can
    // ever shift a slot's geometry.
    Text {
        id: slotIdentityMetrics
        visible: false
        text: workspaceCapsule.stateGlyphActive
        font.family: workspaceCapsule.appGlyphFontFamily
        font.pixelSize: Design.fontLabel
        font.weight: Design.weightBody
    }

    Repeater {
        model: workspaceCapsule.slotIds

        delegate: Item {
            id: slotItem
            required property int modelData
            readonly property int slotId: slotItem.modelData
            readonly property var slotWorkspace: workspaceCapsule.workspaceForId(slotItem.slotId)
            readonly property var slotWindows: workspaceCapsule.windowsFor(slotItem.slotWorkspace)
            readonly property bool slotFocused: !!(Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === slotItem.slotId)
            readonly property bool slotUrgent: !!(slotItem.slotWorkspace && slotItem.slotWorkspace.urgent) && !slotItem.slotFocused

            // D-07: the focused slot's fill — a filled pill, not a tint.
            // Every other state (default, urgent-and-unfocused) stays
            // transparent; Athena's own CSS treats urgent as a foreground
            // tint only (style-athena.scss:175-177), never a filled pill.
            readonly property color slotFillColour: slotItem.slotFocused ? BarRoles.accent : "transparent"
            // D-07: the slot's text/glyph colour, in Athena's own
            // precedence — focused wins over urgent, urgent wins over
            // default.
            readonly property color slotTextColour: slotItem.slotFocused ? BarRoles.onAccent : (slotItem.slotUrgent ? BarRoles.danger : BarRoles.capsuleFg)

            // D-08: the slot's Nerd Font state-glyph identity, replacing
            // the plain numeral — same focused-over-urgent precedence as
            // slotTextColour above.
            readonly property string slotStateGlyph: workspaceCapsule.stateGlyphFor(slotItem.slotFocused, slotItem.slotUrgent)

            // The slot's own extent, stated explicitly from the tokens
            // rather than left implicit — the numeral's reserved
            // two-digit width/height, one inter-child gap, and
            // iconsPerSlot reserved cells each Design.iconSizeMd square
            // with their own inter-cell gaps. Stating it here is what
            // makes D-18-12's fixed-extent guarantee readable at the
            // file rather than emergent from whatever happens to be
            // rendered inside — the icon-cell Repeater's model below is
            // the CONSTANT iconsPerSlot, never the window count, so this
            // expression's value cannot change as windows open and close.
            readonly property int numeralMainAxisExtent: workspaceCapsule.vertical ? slotIdentityMetrics.height : slotIdentityMetrics.width
            readonly property int cellsMainAxisExtent: Design.iconSizeMd * workspaceCapsule.iconsPerSlot + Design.spacingXs * (workspaceCapsule.iconsPerSlot - 1)
            readonly property int slotMainAxisExtent: slotItem.numeralMainAxisExtent + Design.spacingXs + slotItem.cellsMainAxisExtent

            // Cross-axis is a single Design.iconSizeMd (24px) — this is
            // what fits both the 24px horizontal content budget and the
            // 28px vertical column budget the shared chrome leaves
            // (BarCapsule's own implicitWidth/implicitHeight expressions),
            // with room to spare in vertical. No text-truncation property
            // is set anywhere in this file: every string rendered here is
            // bounded by construction — a one-glyph icon, a two-digit
            // numeral, a three-character overflow label — so the
            // codebase's precedent for handling unbounded window names
            // has nothing to apply to here.
            implicitWidth: workspaceCapsule.vertical ? Design.iconSizeMd : slotItem.slotMainAxisExtent
            implicitHeight: workspaceCapsule.vertical ? slotItem.slotMainAxisExtent : Design.iconSizeMd
            width: slotItem.implicitWidth
            height: slotItem.implicitHeight

            // D-07: the focused-slot fill — Overview.qml's/BarCapsule.qml's
            // own full-pill idiom (radius: height / 2), painted BEHIND the
            // Grid below so it never occludes the glyph/numeral content.
            // Motion-gated the same shape BarCapsule.qml's own hover
            // Behavior uses, so the fill crossfades in step with every
            // other bar surface rather than snapping.
            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: slotItem.slotFillColour

                Behavior on color {
                    enabled: Motion.motionEnabled
                    ColorAnimation {
                        duration: Motion.standardDuration
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Motion.standardEasing
                    }
                }
            }

            // One bound positioner, never a Row/Column sibling pair — the
            // same discipline the bar root and the shared chrome's own
            // content Grid already use. columns:1 in vertical puts every
            // child (numeral, then each icon cell) on its own row/line;
            // rows:1 in horizontal puts them all in one row. The SAME
            // iconsPerSlot capacity governs both — no second,
            // per-orientation capacity exists anywhere in this file.
            Grid {
                anchors.fill: parent
                rows: workspaceCapsule.vertical ? -1 : 1
                columns: workspaceCapsule.vertical ? 1 : -1
                spacing: Design.spacingXs

                Text {
                    width: slotIdentityMetrics.width
                    horizontalAlignment: Text.AlignHCenter
                    // D-08: the numeral is gone — this now renders one of
                    // Athena's three Nerd Font state glyphs.
                    text: slotItem.slotStateGlyph
                    font.family: workspaceCapsule.appGlyphFontFamily
                    font.pixelSize: Design.fontLabel
                    font.weight: Design.weightBody
                    // D-07: focused/urgent/default resolved through
                    // BarRoles via slotItem.slotTextColour above — the
                    // bar's colour role layer, not the global palette.
                    color: slotItem.slotTextColour
                }

                // The icon-cell Repeater's model is the CONSTANT
                // iconsPerSlot, never slotWindows or its length — this is
                // the whole of D-18-12's mechanism. Because the cell
                // count cannot vary, the slot's extent (above) cannot
                // vary, so no window event can move anything. A
                // cell-count-follows-content Repeater would look
                // identical at rest and fail the requirement the moment
                // a window opened.
                Repeater {
                    model: workspaceCapsule.iconsPerSlot

                    delegate: Item {
                        id: cellItem
                        required property int index
                        width: Design.iconSizeMd
                        height: Design.iconSizeMd

                        // The overflow label displaces the LAST cell's
                        // glyph rather than occupying an extra cell, so
                        // the visible-glyph count is capacity minus 1
                        // whenever the label shows, and the label's own
                        // count is windows-minus-(capacity-1) — never
                        // windows-minus-capacity.
                        readonly property bool isLastCell: cellItem.index === workspaceCapsule.iconsPerSlot - 1
                        readonly property bool showOverflow: cellItem.isLastCell && slotItem.slotWindows.length > workspaceCapsule.iconsPerSlot
                        readonly property var cellWindow: cellItem.showOverflow ? null : (cellItem.index < slotItem.slotWindows.length ? slotItem.slotWindows[cellItem.index] : null)
                        readonly property var cellGlyph: workspaceCapsule.glyphFor(workspaceCapsule.appIdFor(cellItem.cellWindow))

                        Text {
                            anchors.centerIn: parent
                            visible: !cellItem.showOverflow && cellItem.cellWindow !== null
                            text: cellItem.cellGlyph.text
                            font.family: cellItem.cellGlyph.family
                            font.pixelSize: Design.iconSizeMd
                            color: slotItem.slotTextColour
                        }

                        Text {
                            anchors.centerIn: parent
                            visible: cellItem.showOverflow
                            // Clamped at two digits so the label can
                            // never outgrow its cell — protecting the
                            // fixed extent, not because the count is
                            // expected to get large.
                            text: "+" + Math.min(99, slotItem.slotWindows.length - (workspaceCapsule.iconsPerSlot - 1))
                            font.pixelSize: Design.fontLabel
                            color: slotItem.slotTextColour
                        }
                    }
                }
            }

            // Non-hover-consuming click target — TapHandler uses a
            // passive grab and does not intercept hover, so the shared
            // chrome's own HoverHandler (on BarCapsule's root) keeps
            // working for 18-13's popout dwell mechanics. No
            // pressed-state visual: this repo keys visual state off the
            // resulting state change (the workspace becoming active),
            // never off pointer-down.
            TapHandler {
                onTapped: workspaceCapsule.activateWorkspace(slotItem.slotId)
            }
        }
    }

    // ── States handled by degradation, not by invented chrome ───────────
    // A slot with no windows renders its numeral and no glyphs, full
    // extent kept (the icon-cell Repeater's model is always the constant).
    // A slot whose workspace object does not exist (never-opened
    // persistent slot) behaves identically and stays clickable through
    // activateWorkspace()'s dispatch fallback. A window whose app id
    // resolves to nothing renders the fallback ligature via glyphFor().
    // Hyprland IPC being unavailable is NOT handled here at all — that is
    // shell-fatal, not a per-capsule state (UI-SPEC E2 error), and this
    // capsule's natural degradation is its static numbered slots, which
    // is strictly more useful than an error tint the user cannot act on.
    // No skeleton/loading state either: both live models are populated at
    // first paint, and a skeleton would flash on every shell start.
}
