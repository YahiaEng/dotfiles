// WorkspaceCapsule.qml — the workspaces slot (Phase 18 Plan 05, D-18-10).
//
// Owner: 18-09 — live per-app window icons in athena's icon-plus-windows
// shape per D-18-02, click-to-switch through Quickshell.Hyprland copying
// Overview.qml's validate-before-interpolate discipline.
// Entries BarEntryModel already declares for this capsule: `workspaces`.
//
// ── Two DIFFERENT "fixed" guarantees live in this file — do not conflate
//    them, that conflation is exactly what read this file's own prior
//    header as "5 fixed slots that never grow" and became Phase 18.1
//    GATE-02 operator item (c) (ATHENA-UPSTREAM-SPEC.md) ────────────────
// 1. The SLOT SET (how many pills render) is DYNAMIC, matching upstream
//    Athena's `"persistent-workspaces": { "*": 5 }` — a FLOOR, not a cap:
//    slots 1..persistentSlotCount always render, and any workspace id
//    beyond that range that currently EXISTS gets its own extra slot,
//    appended live as `slotIds` below re-derives off Hyprland.workspaces
//    and removed live the moment Hyprland itself destroys that empty
//    workspace. Live-verified 2026-08-11: creating/focusing workspace 6
//    grew the rendered set from 5 to 6 slots with no shell restart;
//    closing its last window and navigating away shrank it back to 5,
//    also with no restart.
// 2. Each individual SLOT's own on-screen EXTENT, once that slot exists,
//    stays fixed regardless of how many windows open/close inside it
//    (D-18-12) — the icon-cell Repeater nested inside each slot delegate
//    below is sized off the CONSTANT iconsPerSlot, never off the window
//    count. D-18-12 is scoped to that per-slot content churn only; it
//    was never a claim about the outer slot count, and `slotIds`
//    growing/shrinking the outer set does not violate it (see slotIds'
//    own comment below, point 3).
//
// Task 1 (tracer) proved the whole path — live model, glyph resolution,
// dispatch — on one hardcoded slot. Task 2 below generalised that proof
// into the full dynamic-count slot set: every persistent slot plus any
// workspace beyond the persistent range that currently exists, each
// slot's own content sized with iconsPerSlot reserved cells and +N
// overflow (guarantee 2 above).
import QtQuick
import Quickshell
import Quickshell.Hyprland
import "../"
import "../dashboard"

BarCapsule {
    id: workspaceCapsule
    capsuleId: "workspaces"

    // One of the two capsules that carry a surface — operator decision, GATE-02
    // rounds 2-3; the other is IdleInhibitorCapsule (the centre bulb). See
    // BarCapsule.qml's `surfaced` for why this narrow set diverges from
    // upstream Athena, which surfaces every group. Every other capsule leaves
    // `surfaced` at its false default and renders bare glyphs on the wallpaper.
    surfaced: true

    // Upstream workspace buttons carry only `margin: 0 2px` (a 4px gap), far
    // tighter than the 18px intra-group pitch the readout capsules use, so
    // this overrides BarCapsule's barCellGap default.
    contentGap: Design.spacingXs

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
    // SIX numbered slots plus the always-present reserved AI slot (id 10) below
    // = seven pills, which is exactly the composition the operator's Athena
    // renders: six numbered workspaces and the reserved tenth. Athena's own
    // config says `persistent-workspaces: {"*": 5}` while rendering more than
    // that, so this follows the operator's stated cap of seven rather than the
    // upstream literal; do not "reconcile" it back to 5.
    //
    // A previous pass set this to 7 and left the AI slot to the dynamic tail,
    // which made it vanish whenever workspace 10 did not exist. The operator
    // asked for it back, so it is now persistent (aiSlotId is unioned into
    // slotIds unconditionally) and the numbered floor drops to six to hold the
    // total at seven.
    readonly property int persistentSlotCount: 6

    // Reserved icon cells per slot. Must be >= 2: the overflow label
    // occupies the LAST cell rather than an extra one, so a capacity of 1
    // would make every multi-window slot render an overflow count and no
    // glyph at all. 3 is derived from Design.barGlyphSize cells stacking
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

    // ── Width floor (GATE-02 round 4, operator item 1: "too compressed,
    //    make it match athena's width") ──────────────────────────────────
    // Upstream's `tokens/workspace.css` gives every workspace button a
    // hard `min-width: 32px` floor — a slot never renders smaller than
    // this even when its content (a bare focused pacman, or a one-digit
    // numeral) would naturally measure less. The 17f729a fix that made
    // `cellsMainAxisExtent` above track OCCUPIED cells instead of
    // reserving all `iconsPerSlot` fixed the centring bug it targeted,
    // but left a slot free to shrink to whatever its content needed —
    // this floor is the missing piece. Applied to `slotMainAxisExtent`
    // below (this file's existing orientation-agnostic "main axis"
    // convention — width in horizontal, height in vertical — the same
    // one every other *MainAxisExtent property here already uses), not
    // hardcoded as a separate horizontal-only path: a slot only ever
    // GROWS beyond 32 when its own content needs more room, matching
    // upstream's own "floor, not fixed size" behaviour. Verified against
    // the live Athena bar by screenshotting both capsules in one frame
    // and measuring pixel widths directly (see the plan's SUMMARY/commit
    // message), not by arithmetic alone.
    readonly property int slotMinMainAxisExtent: 32

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
    //     `BarRoles.capsuleFg`. Task 2 restored a glyph identity for the
    //     focused/urgent states: `stateGlyphActive`/`stateGlyphUrgent`
    //     (`format-icons` active/urgent) chosen with focused taking
    //     precedence over urgent — the same precedence `slotTextColour`
    //     already used. D-08 (Task 2, first pass) went further and also
    //     dropped the numeral for the DEFAULT (non-focused, non-urgent)
    //     branch, replacing it with a fourth glyph (`stateGlyphDefault`,
    //     the ghost). That was never actually correct — see (c) below.
    // (c) [Phase 18.1 GATE-02 round 4 — this fix] D-08's "numeral is gone"
    //     was written from the retired bar's own architecture, never
    //     checked against a live Athena instance. Live observation of the
    //     operator's own config-athena.jsonc retired-bar instance (method:
    //     repeated `hyprctl dispatch hl.dsp.focus({workspace=N})` state
    //     changes, `grim` screenshots compared frame-by-frame, confirmed
    //     against the retired bar's upstream v0.15.0 `Workspace::
    //     selectIcon()` source and cross-checked with its own
    //     `--log-level trace` output) shows the ghost
    //     (`stateGlyphDefault`, format-icons.default) NEVER actually
    //     renders for a live, non-focused, non-urgent slot — every such
    //     slot renders its own NUMBER instead, whether occupied or empty.
    //     D-08's "accepted cost" (losing the Super+N-to-digit mapping)
    //     was therefore never a real trade-off; it was a bug. The numeral
    //     is restored below for the default branch — see the state-glyph
    //     table where `stateGlyphActive`/`stateGlyphUrgent` are declared.
    //     Athena's fourth state, `empty` (format-icons.empty, U+F444, a
    //     small dot), IS real and was directly observed (a
    //     persistent-floor slot with no live backing workspace renders
    //     it) — but its exact trigger did not survive a restart of that
    //     retired bar during verification (see that table's own note)
    //     and is NOT reproduced here; a named delta, not a silent
    //     omission.
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

    // ── Athena's workspace-slot identity rule — DERIVED FROM LIVE
    //    OBSERVATION, Phase 18.1 GATE-02 round 4, 2026-08-11 ────────────
    // Do not re-derive this from config-athena.jsonc's `format-icons`
    // table alone (active/default/urgent/empty) — that table describes
    // the retired bar's INPUT states, not what actually renders, and
    // reading it naively is exactly how the pre-round-4 code got this
    // wrong (every non-focused slot rendered `format-icons.default`, the
    // ghost). The rule below was built by driving the operator's own live
    // config-athena.jsonc retired-bar instance through real state changes
    // (`hyprctl dispatch hl.dsp.focus({workspace=N})`, opening/closing a
    // real `kitty` window) and diffing `grim` screenshots frame-by-frame,
    // THEN cross-checked by reading the upstream v0.15.0 source's own
    // `Workspace::selectIcon()` (confirmed byte-identical to the
    // installed binary via `strings`) and by running that retired bar's
    // own `--log-level trace` against a freshly-restarted instance (full
    // upstream project citation recorded in 18-20-SUMMARY.md's
    // scrubbed-history section):
    //
    // | Precedence | Condition (this slot)          | Rendered identity          |
    // |-----------:|---------------------------------|-----------------------------|
    // | 1          | focused                         | stateGlyphActive (pacman)   |
    // | 2          | urgent, not focused              | stateGlyphUrgent            |
    // | 3          | anything else (occupied OR empty)| its own workspace NUMBER    |
    //
    // Window glyphs (from `glyphFor()`/`appGlyphMap`) append after the
    // identity in every row, exactly as upstream's `"{icon} {windows}"`
    // format does — precedence above governs ONLY the `{icon}` half.
    //
    // `format-icons.default` (the ghost, U+F02A0) is real in the config
    // but was never observed rendering live for a non-focused, non-urgent
    // slot — occupied AND empty slots alike fell through to the plain
    // NUMBER (the retired bar's own final fallback when no state/name/persistent
    // icon key matches — see `selectIcon()`'s trailing `return m_name;`).
    // It is therefore dropped from this file entirely rather than kept as
    // a byte that's never read.
    //
    // `format-icons.empty` (a small dot, U+F444) IS real — a persistent-
    // floor slot with no live backing Hyprland workspace rendered it, and
    // it responded correctly to `hyprctl dispatch hl.dsp.focus({workspace
    // =10})` (became the active pill) and back (returned to the dot).
    // But: (a) restarting the operator's retired-bar process for a controlled
    // check changed the SAME slot range from "numbers" to "ghosts" for
    // EVERY non-focused slot including previously-numbered ones — meaning
    // whatever binary had been running before that restart (Arch does not
    // restart running daemons on package upgrade) was not byte-identical
    // to the on-disk v0.15.0 this file's precedence table was verified
    // against; (b) Hyprland here has NO `workspace = N, persistent:true`
    // rules backing any of these ids (grepped, none found) — so a live
    // "does this workspace currently exist" check flickers (confirmed:
    // `hyprctl dispatch hl.dsp.focus({workspace=4})` then away destroys
    // workspace 4 immediately), which the dot's one clean trigger
    // (workspace 10 specifically, the LAST of Athena's 5-slot persistent
    // block) did not exhibit for its neighbours 6-9. The dot's exact
    // trigger did not resolve to a single, stable rule across repeated
    // verification and is NOT reproduced here — named delta, not a
    // silent omission. This file's own persistent floor (below) already
    // always renders regardless of live existence, which is what keeps
    // rule 3 above stable rather than flickering the way an existence
    // check would.
    readonly property string stateGlyphActive: "󰮯"   // format-icons.active
    readonly property string stateGlyphUrgent: "󰧵"   // format-icons.urgent

    // ── The reserved AI workspace ────────────────────────────────────────
    // Workspace 10 is reserved for AI work (operator, GATE-02 round 4). Athena
    // rendered it as a bare dot — `format-icons.empty` — which carried no
    // meaning; the operator asked for "the star AI symbol" instead, so it gets
    // the identity glyph rather than its numeral.
    //
    // `auto_awesome` — Google's four-pointed sparkle, the icon that has become
    // the de facto "AI" mark. The operator asked for this specifically after
    // trying a Nerd Font robot.
    //
    // It comes from Material Symbols, so it is the ONE identity glyph in this
    // file NOT drawn from appGlyphFontFamily (FiraCode Nerd Font), and
    // identityFontFor() below exists solely to serve it. That special case is a
    // known, accepted cost: an interim Nerd Font glyph had removed it, but the
    // operator wants this specific mark, and matching the requested design beats
    // keeping one font family. Keep the metrics path in step with it — the
    // reservation and the render must agree on family AND size, or the slot
    // mis-measures (that exact mismatch has already been fixed twice here).
    readonly property int aiSlotId: 10
    readonly property string aiSlotGlyph: "auto_awesome"

    function identityFontFor(slotId) {
        return slotId === workspaceCapsule.aiSlotId ? Design.symbolFontFamily : workspaceCapsule.appGlyphFontFamily;
    }

    // Precedence matches slotTextColour's own: focused wins over urgent.
    // Anything else falls through to the caller's own numeral (String(
    // slotId)) per the table above — not a glyph at all, so it is not
    // returned from here. Pure function, no side effects.
    function stateGlyphFor(focused, urgent) {
        if (focused)
            return workspaceCapsule.stateGlyphActive;
        if (urgent)
            return workspaceCapsule.stateGlyphUrgent;
        return "";
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
    // This property IS the mechanism satisfying Phase 18.1 GATE-02
    // operator item (c) ("workspaces should grow above a persistent
    // floor of five, the way upstream Athena does") — see the file
    // header's two-guarantee note. It reads Hyprland.workspaces.values
    // directly, so it is a live QML binding: it re-evaluates whenever
    // that list changes, with no polling and no restart required.
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
        // The reserved AI workspace is persistent, not dynamic: it renders
        // whether or not Hyprland currently has a workspace 10, so the slot the
        // operator reserves for AI work is always there to click. Pushed after
        // the numbered floor and before the dynamic tail's insertion scan, which
        // keeps ids ascending without a sort.
        if (ids.indexOf(workspaceCapsule.aiSlotId) === -1)
            ids.push(workspaceCapsule.aiSlotId);

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

    // Hidden metrics text reserving the slot identity's extent (UI-SPEC's
    // reserve-worst-case-width rule). The identity is now EITHER a glyph
    // (stateGlyphActive/Urgent, focused/urgent) OR a plain two-digit
    // numeral (everything else — see the state-glyph table above), both
    // rendered through the SAME Text element/font/size in the delegate
    // below, so both must be measured and the wider one reserved.
    // Each metrics Text MUST measure at the size its own case actually paints
    // at: a glyph at barGlyphSize (16), a numeral at barBodySize (13). An
    // earlier pass unified both on barGlyphSize to fix a real under-reservation
    // (numerals were being measured at 13 while everything painted at 16);
    // splitting them again is correct now only because the RENDER is split too,
    // driven by the same slotIdentityIsNumeral flag.
    Text {
        id: slotIdentityGlyphMetrics
        visible: false
        text: workspaceCapsule.stateGlyphActive
        font.family: workspaceCapsule.appGlyphFontFamily
        font.pixelSize: Design.barGlyphSize
        font.weight: Design.weightBody
    }
    Text {
        id: slotIdentityNumeralMetrics
        visible: false
        // Worst-case two digits — this file's own dynamic tail
        // (`slotIds`) can carry ids past 9, and isValidWorkspaceId's own
        // upper bound is 10, so single-digit reservation would clip a
        // legitimate id.
        text: "00"
        font.family: workspaceCapsule.appGlyphFontFamily
        font.pixelSize: Design.barBodySize
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

            // The slot's identity text — a glyph when focused/urgent,
            // otherwise its own numeral (see the state-glyph table on
            // stateGlyphFor above; GATE-02 round 4 restored the numeral
            // for the default branch after live-observation showed
            // Athena never actually renders the ghost there).
            // Precedence: focused/urgent state glyph, then the AI slot's own
            // symbol, then the plain numeral. The AI symbol sits BELOW the state
            // glyphs deliberately — when workspace 10 is focused it must show the
            // same pacman every other focused workspace shows, or the focused
            // state would be unreadable on exactly one slot.
            readonly property string slotStateGlyph: workspaceCapsule.stateGlyphFor(slotItem.slotFocused, slotItem.slotUrgent) || (slotItem.slotId === workspaceCapsule.aiSlotId ? workspaceCapsule.aiSlotGlyph : String(slotItem.slotId))
            // True when the identity resolved to a numeral rather than a glyph.
            // Drives BOTH the rendered size and the metrics reservation, so the
            // two can never disagree about which size measured the slot.
            readonly property bool slotIdentityIsNumeral: !workspaceCapsule.stateGlyphFor(slotItem.slotFocused, slotItem.slotUrgent) && slotItem.slotId !== workspaceCapsule.aiSlotId

            // The slot's own extent, stated explicitly from the tokens
            // rather than left implicit — the numeral's reserved
            // two-digit width/height, one inter-child gap, and
            // iconsPerSlot reserved cells each Design.barGlyphSize square
            // with their own inter-cell gaps. Stating it here is what
            // makes D-18-12's fixed-extent guarantee readable at the
            // file rather than emergent from whatever happens to be
            // rendered inside — the icon-cell Repeater's model below is
            // the CONSTANT iconsPerSlot, never the window count, so this
            // expression's value cannot change as windows open and close.
            readonly property int numeralMainAxisExtent: workspaceCapsule.vertical ? Math.max(slotIdentityGlyphMetrics.height, slotIdentityNumeralMetrics.height) : Math.max(slotIdentityGlyphMetrics.width, slotIdentityNumeralMetrics.width)
            // ── D-18-12 NARROWED, deliberately, by the GATE-02 fix ──────
            // This was `barGlyphSize * iconsPerSlot + gaps`, i.e. the extent of
            // ALL iconsPerSlot reserved cells whether or not a window occupied
            // them. That held the slot's width perfectly constant, but it also
            // meant a focused workspace with one window rendered its glyphs
            // against the LEFT of an accent pill sized for three — the visible
            // content sat left of centre inside its own fill, which is the
            // operator's "the pacman glyphs are not centered" (the Grid below is
            // already anchors.centerIn; it was centring a row whose right-hand
            // cells were invisible-but-space-occupying).
            //
            // Upstream Athena sizes a workspace button to the windows it
            // actually has, so this now counts OCCUPIED cells (floor 1, so an
            // empty workspace keeps a slot to click). D-18-12's remaining, still
            // true guarantee is narrower and stated exactly: the slot never
            // exceeds iconsPerSlot cells, so it has a hard UPPER bound and
            // cannot grow without limit as windows open — it is no longer a
            // claim that the width never changes at all.
            readonly property int cellsShown: Math.max(1, Math.min(slotItem.slotWindows.length, workspaceCapsule.iconsPerSlot))
            readonly property int cellsMainAxisExtent: Design.barGlyphSize * slotItem.cellsShown + Design.spacingXs * (slotItem.cellsShown - 1)
            // Athena pads a workspace button horizontally — `padding: 0 12px`
            // when active, `padding: 0 4px` otherwise — so its content never
            // touches the pill edge. Ours had none, which left the focused
            // slot's glyphs flush against the accent fill's left and right
            // edges: the remaining half of the operator's "the pacman glyphs
            // are not centered". The fill is anchors.fill of this slot, so
            // widening the slot IS how the pill gains its padding.
            readonly property int slotSidePadding: slotItem.slotFocused ? Design.spacingMd - Design.spacingXs : Design.spacingXs
            // Content-driven extent, THEN floored at slotMinMainAxisExtent
            // (upstream's `min-width: 32px`, GATE-02 round 4 item 1) — a
            // slot only grows past the floor when its own content needs
            // more, it never shrinks below it. This floor is a MINIMUM;
            // it does not touch D-18-12's own UPPER bound above
            // (cellsShown is still capped at iconsPerSlot regardless of
            // this floor).
            readonly property int slotContentMainAxisExtent: slotItem.numeralMainAxisExtent + Design.spacingXs + slotItem.cellsMainAxisExtent + slotItem.slotSidePadding * 2
            readonly property int slotMainAxisExtent: Math.max(workspaceCapsule.slotMinMainAxisExtent, slotItem.slotContentMainAxisExtent)

            // Cross-axis is a single Design.barGlyphSize (24px) — this is
            // what fits both the 24px horizontal content budget and the
            // 28px vertical column budget the shared chrome leaves
            // (BarCapsule's own implicitWidth/implicitHeight expressions),
            // with room to spare in vertical. No text-truncation property
            // is set anywhere in this file: every string rendered here is
            // bounded by construction — a one-glyph icon, a two-digit
            // numeral, a three-character overflow label — so the
            // codebase's precedent for handling unbounded window names
            // has nothing to apply to here.
            // Cross axis is barSlotHeight (22 = capsule content box), NOT
            // barGlyphSize (16). Upstream's workspace button fills its group's
            // content box, so the active accent pill is content-height tall;
            // sizing the slot to a single glyph made that fill read "too thin"
            // and left the glyphs no vertical room to centre within, which is
            // the operator's remaining pair of workspace complaints.
            implicitWidth: workspaceCapsule.vertical ? Design.barSlotHeight : slotItem.slotMainAxisExtent
            implicitHeight: workspaceCapsule.vertical ? slotItem.slotMainAxisExtent : Design.barSlotHeight
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
                // centerIn, NOT fill (GATE-02 defect 2, "the glyphs are not
                // centered as they should"). A Grid positions its children
                // from its own top-left, so under anchors.fill the row sat
                // flush to the slot's top edge while each child's natural
                // text height differed from the slot's one-glyph cross-axis
                // extent — the glyphs rendered visibly high. centerIn is
                // also what the shared chrome's own content Grid uses
                // (BarCapsule.qml:76), i.e. the convention this block's
                // comment above already claims to follow.
                anchors.centerIn: parent
                rows: workspaceCapsule.vertical ? -1 : 1
                columns: workspaceCapsule.vertical ? 1 : -1
                spacing: Design.spacingXs
                // The operator's "the workspace module is not centered": the
                // module itself measured centred (slots x=11.0 w=22.0 -> centre
                // 22.0, exactly the column centre), but the NUMERAL inside each
                // slot did not (x=11.0 w=16.0 -> centre 19.0, 3px left), because
                // this Grid inherited AlignLeft/AlignTop like BarCapsule's
                // contentGrid did. Same one-property fix, same reason.
                horizontalItemAlignment: Grid.AlignHCenter
                verticalItemAlignment: Grid.AlignVCenter

                Text {
                    width: Math.max(slotIdentityGlyphMetrics.width, slotIdentityNumeralMetrics.width)
                    horizontalAlignment: Text.AlignHCenter
                    // Same explicit one-glyph box + vertical centring the
                    // icon cells below use, so the state glyph shares their
                    // optical baseline instead of sitting on its own
                    // font-metric-derived height.
                    height: Design.barGlyphSize
                    verticalAlignment: Text.AlignVCenter
                    // barGlyphSize, matching the window glyphs beside it.
                    // This was barBodySize (13) against their 16, and a
                    // size mismatch inside one row is what still read as
                    // "not centered as they should" after the centerIn fix
                    // — upstream Athena renders the state icon and the
                    // window glyphs at ONE size, differentiating them by
                    // label margin instead (ATHENA-UPSTREAM-SPEC.md).
                    //
                    // rightPadding lifts the gap after the state icon to 8
                    // (Grid spacing 4 + 4), reproducing upstream's
                    // `#workspaces button label:first-child { margin-right:
                    // 8px }`. The window glyphs keep the tighter 4px pitch
                    // between themselves, exactly as upstream does.
                    rightPadding: Design.spacingSm - Design.spacingXs
                    // GATE-02 round 4: focused/urgent render a Nerd Font
                    // state glyph, everything else renders the slot's own
                    // numeral — see stateGlyphFor's derivation table above.
                    text: slotItem.slotStateGlyph
                    font.pixelSize: slotItem.slotIdentityIsNumeral ? Design.barBodySize : Design.barGlyphSize
                    // Material Symbols for the AI slot's sparkle, the Nerd Font
                    // for every state glyph and numeral. A focused or urgent AI
                    // slot shows the Nerd Font state glyph, so the family has to
                    // follow the same precedence slotStateGlyph itself uses.
                    font.family: slotItem.slotFocused || slotItem.slotUrgent ? workspaceCapsule.appGlyphFontFamily : workspaceCapsule.identityFontFor(slotItem.slotId)
                    // A NUMERAL is bar body text and renders at barBodySize
                    // (13) — Athena's workspace labels inherit its
                    // `* { font-size: 13px }`, and ours painting them at
                    // barGlyphSize (16) is why the operator reported the number
                    // font as not matching. A GLYPH (state or AI symbol) is an
                    // icon and stays at barGlyphSize, which is also what the
                    // window glyphs beside it use.
                    //
                    // The family needed no change: upstream's
                    // "JetBrainsMono Nerd Font" is NOT installed on this host,
                    // and the operator's live Athena renders through
                    // FiraCode Nerd Font — already appGlyphFontFamily here.
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
                        // A cell with no window and no overflow label is now
                        // INVISIBLE, so the Grid excludes it and its spacing
                        // (this file's own shared-chrome note relies on exactly
                        // that positioner behaviour). Without this the slot's
                        // visible glyphs stay left-aligned inside a fill sized
                        // for every reserved cell.
                        visible: cellItem.showOverflow || cellItem.cellWindow !== null || cellItem.index === 0
                        width: Design.barGlyphSize
                        height: Design.barGlyphSize

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
                            font.pixelSize: Design.barGlyphSize
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
                            font.pixelSize: Design.barBodySize
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
