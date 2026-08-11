// WorkspaceCapsule.qml — the workspaces slot (Phase 18 Plan 05, D-18-10).
//
// Owner: 18-09 — live per-app window icons in athena's icon-plus-windows
// shape per D-18-02, fixed-height slots with +N overflow in BOTH
// orientations per D-18-12, click-to-switch through Quickshell.Hyprland
// copying Overview.qml's validate-before-interpolate discipline.
// Entries BarEntryModel already declares for this capsule: `workspaces`.
//
// ── Task 1 (tracer): one slot, one live glyph, one click that actually
//    switches — the whole path end to end, wired once, before the full
//    slot set is built on top of it. Task 2 replaces the single hardcoded
//    slot below with the full fixed-extent slot set.
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
    // length, the scarce one. This is the single tuning knob if 18-19's
    // GATE-02 pass finds the vertical column overfull once all six
    // capsules exist; lowering it is a one-line change, and removing
    // capability is not the alternative.
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
    // (b) the source table's state icon set (active/default/urgent/empty
    //     under "format-icons") is not carried either — this capsule's
    //     slot identity is the workspace NUMERAL (the shape the
    //     canonical modules.jsonc definition every other layout shares
    //     already uses), which maps one-to-one onto the Super+N
    //     keybinds. State is carried by colour instead (UI-SPEC's Accent
    //     role). The athena layout showed a ghost glyph where this shows
    //     a number — 18-19's GATE-02 criterion A judges whether that
    //     reads as well.
    readonly property var appGlyphMap: [
        { appId: "kitty", glyph: "󰆍" },
        { appId: "firefox", glyph: "" },
        { appId: "zen", glyph: "" },
        { appId: "codium", glyph: "󰨞" },
        { appId: "VSCodium", glyph: "󰨞" },
        { appId: "discord", glyph: "" },
        { appId: "spotify", glyph: "" },
        { appId: "obsidian", glyph: "󰹕" },
        { appId: "net.lutris.Lutris", glyph: "" },
        { appId: "steam", glyph: "" },
        { appId: "thunar", glyph: "" },
        { appId: "yazi", glyph: "󰇥" }
    ]

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

    // ── Task 1's single proof slot (workspace 1 only) ───────────────────
    // Everything above this line is reused unchanged by Task 2's full
    // slot set; only the rendering below is Task 1-specific and gets
    // replaced wholesale.
    Item {
        id: tracerSlot

        readonly property var slotWorkspace: workspaceCapsule.workspaceForId(1)
        readonly property var slotWindows: workspaceCapsule.windowsFor(tracerSlot.slotWorkspace)
        readonly property bool slotFocused: !!(Hyprland.focusedWorkspace && Hyprland.focusedWorkspace.id === 1)
        readonly property var firstGlyph: workspaceCapsule.glyphFor(workspaceCapsule.appIdFor(tracerSlot.slotWindows.length > 0 ? tracerSlot.slotWindows[0] : null))

        implicitWidth: numeralMetrics.width + Design.spacingXs + Design.iconSizeMd
        implicitHeight: Design.iconSizeMd

        Text {
            id: numeralMetrics
            visible: false
            text: "00"
            font.pixelSize: Design.fontLabel
            font.weight: Design.weightBody
        }

        Row {
            anchors.fill: parent
            spacing: Design.spacingXs

            Text {
                width: numeralMetrics.width
                horizontalAlignment: Text.AlignHCenter
                text: "1"
                font.pixelSize: Design.fontLabel
                font.weight: Design.weightBody
                color: tracerSlot.slotFocused ? Colours.primary : workspaceCapsule.contentColour
            }

            Text {
                width: Design.iconSizeMd
                height: Design.iconSizeMd
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                visible: tracerSlot.slotWindows.length > 0
                text: tracerSlot.firstGlyph.text
                font.family: tracerSlot.firstGlyph.family
                font.pixelSize: Design.iconSizeMd
                color: workspaceCapsule.contentColour
            }
        }

        TapHandler {
            onTapped: workspaceCapsule.activateWorkspace(1)
        }
    }
}
