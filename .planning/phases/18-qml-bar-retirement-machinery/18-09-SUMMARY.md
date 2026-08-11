---
phase: 18-qml-bar-retirement-machinery
plan: 09
subsystem: ui
tags: [quickshell, qml, hyprland, workspaces, wlr-layer-shell, dispatch]

# Dependency graph
requires:
  - phase: 18-05
    provides: "WorkspaceCapsule.qml stub rooted on BarCapsule, capsuleId \"workspaces\", modules/bar/qmldir registration (frozen for wave 3), BarCapsule's shared chrome (content Grid, vertical/contentColour/active/hovered properties, five backend handles)"
provides:
  - "WorkspaceCapsule.qml filled in: live per-app window icons in athena's {icon} {windows} shape, fixed-extent slots (constant iconsPerSlot reserved cells), +N overflow in both orientations, click-to-switch via Quickshell.Hyprland (QBAR-03)"
  - "The 12-entry appGlyphMap (ordered array) and four-stage glyphFor() resolver — the glyph vocabulary 18-19's GATE-02 aesthetic pass compares against"
  - "activateWorkspace()/workspaceForId()/windowsFor() — the validate-before-interpolate click path, live-object-first with a range-checked dispatch fallback"
affects: [18-12, 18-13, 18-17, 18-19]

# Actuals (#2632)
actuals:
  tokens: 5980
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Per-file local constants instead of a shared Design.qml token, recorded with the hoisting rule that justifies it (single-consumer, no UI-SPEC New Tokens row) — keeps this plan to one file so 18-08/18-10/18-11 share nothing"
    - "Ordered array (not a plain object) for a lookup table whose containment stage needs a defined declaration order for its tie-break"
    - "Object-first, range-checked-integer-dispatch-fallback click path, copied from Overview.qml's activateTile()/dispatchWorkspaceFocus() — a workspace with no windows yet has no Hyprland object at all, so the object-only half is not sufficient on its own"
    - "Fixed-extent-by-construction: a Repeater whose model is a constant (iconsPerSlot), never the live window count, so slot geometry cannot vary as windows open and close"

key-files:
  modified:
    - quickshell/.config/quickshell/modules/bar/WorkspaceCapsule.qml

key-decisions:
  - "Live hyprctl verification (dispatch-string proof, orientation-flip reserved-array reading) and Task 3's human-check (click-to-switch, live icons, fixed extent under churn, overflow, unmapped-app fallback, vertical fit, theme re-colour) were NOT performed this session — per the standing recorded preference to skip live-probe/screenshot/restart-and-observe verification loops and let the user verify at the machine. Only static checks ran: qmllint (clean) and every grep-based acceptance criterion in the plan's three tasks (all passing). This is a deliberate, named gap, not an oversight — see 'Verification Status' below and the WINDOWS.md ledger entry filed for it."
  - "Colour bindings are written as inline ternaries at each `color:` call site (`slotFocused ? Colours.primary : ...`) rather than factored into a computed `numeralColour` property — the plan's own acceptance grep expects the token reference to appear on the `color:` line itself, and a factored property broke that check on first pass (caught by re-running the grep, fixed before commit)."
  - "The 'no truncation treatment' comment was reworded mid-plan to avoid the literal substrings `ElideRight`/`maximumLineCount` inside a code comment — the plan's own grep gate for 'no elide anywhere' is a bare-word match, not an assignment-anchored one as its parenthetical claims, so explaining the precedent in prose without spelling those two identifiers is what keeps the gate honest without contradicting the plan's own stated intent."

requirements-completed: []
requirements-partial: [QBAR-03]

coverage:
  - id: D1
    description: "Task 1 tracer: local constants (not hoisted to Design.qml), 12-entry ordered glyph map copied verbatim from athena's window-rewrite table, four-stage glyphFor() resolver, activateWorkspace() object-first/range-checked-dispatch-fallback click path, one proof slot"
    requirement: "QBAR-03"
    verification:
      - kind: other
        ref: "qmllint clean; all Task 1 grep-based acceptance criteria pass (constants, glyph keys, fallback, no client string, dispatch shape, range check, activate-before-dispatch ordering, no polling, no ordering pass over windows, colour tokens, no own chrome)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Task 2 full slot set: ascending union of persistentSlotCount and any workspace beyond it (excluded by id sign, never by name literal), one Repeater over slots each a single bound Grid, icon-cell Repeater driven by the CONSTANT iconsPerSlot, +N overflow clamped at two digits, focused/urgent/default numeral colour"
    requirement: "QBAR-03"
    verification:
      - kind: other
        ref: "qmllint clean; all Task 2 grep-based acceptance criteria pass (slotIds, cell-repeater model constant, no windows/toplevels-driven model, repeater count 2, no Row/Column pair, rows-bound-to-vertical, three colour tokens, 3-4 text bindings, overflow bounded, one dispatch site, one file touched)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Task 3 vertical form: same iconsPerSlot capacity governs both orientations, slot extent stated explicitly from Design tokens (Design.iconSizeMd * iconsPerSlot), no truncation property anywhere, tuning-knob handoff comment recorded for 18-19's GATE-02"
    requirement: "QBAR-03"
    verification:
      - kind: other
        ref: "qmllint clean; all Task 3 static grep-based acceptance criteria pass (single capacity constant, token-stated extent expression present, no elide/ElideRight/maximumLineCount, no hardcoded pixel geometry, one file touched)"
        status: pass
    human_judgment: false
  - id: D4
    description: "The live host proof — dispatch expression actually switches the compositor's workspace, the quickshell-bar namespace survives reload, the orientation flip is symmetric and matches 18-05's recorded reserved-array readings, and the human click-through gate (including onto a never-opened workspace, live icon churn, overflow, unmapped-app fallback, theme re-colour) — this is QBAR-03's actual close condition per the plan's own objective (\"restores\" is a behavioural claim, not a source-level one)"
    requirement: "QBAR-03"
    verification: []
    human_judgment: true
    rationale: "Deliberately not run this session — see 'Verification Status' below. Requires the user to relaunch/observe the live bar (or confirm it is already running this build) and click through the six numbered checks in the plan's Task 3 human-check block. Logged as WINDOWS.md ledger entry (unrun-verify) so it stays visible at ship time; does not block continuing to the rest of wave 3 (18-08/18-10/18-11 share no files with this plan), but DOES block 18-19's GATE-02 pass from citing QBAR-03 as closed until performed."

duration: ~20min
completed: 2026-08-11
status: complete
---

# Phase 18 Plan 09: Workspace Capsule — Live Icons, Fixed Extent, Click-to-Switch Summary

**`WorkspaceCapsule.qml` filled in end-to-end — a 12-app glyph map lifted verbatim from athena's `window-rewrite` table, fixed-extent slots whose icon-cell count is a constant rather than the live window count, `+N` overflow in both orientations from one shared capacity, and a click path that tries the live workspace object first and falls back to the exact `hl.dsp.focus({workspace=N})` expression `keybinds.lua` already uses — all built and statically verified, with the live-host proof and the human click-through gate explicitly deferred to the user rather than run by the executor.**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-08-11 (this session)
- **Completed:** 2026-08-11
- **Tasks:** 3 (all completed)
- **Files modified:** 1 (`quickshell/.config/quickshell/modules/bar/WorkspaceCapsule.qml`)

## Accomplishments

- **Task 1 (tracer):** local `persistentSlotCount` (5), `iconsPerSlot` (3, must be ≥2, commented with its derivation and its role as the sanctioned tuning knob) and `appGlyphFontFamily` ("FiraCode Nerd Font") constants, deliberately not hoisted into `Design.qml`; the 12-entry ordered `appGlyphMap` copied byte-for-byte from athena's `window-rewrite` table with both deliberate omissions (the source table's own ghost default and its state icon set) recorded in source; `glyphFor(appId)` — a four-stage resolver (exact, case-insensitive exact, case-insensitive containment, fallback) that never compiles an expression from client input and never returns a client-supplied string; `activateWorkspace(slotId)` — tries the live workspace object's own `activate()` first, falls back to a range-checked integer interpolated into `hl.dsp.focus({workspace=N})` only when no object exists; one proof slot (workspace 1) wired end to end.
- **Task 2 (full slot set):** `slotIds` — the ascending union of the five persistent slots and any workspace beyond them, built by comparison-insertion (not `.sort()`/`.reverse()`) and excluding special workspaces by id sign, never by name literal; one `Repeater` over `slotIds`, each slot a single `Grid` bound to `BarCapsule.vertical` (never a `Row`/`Column` sibling pair) holding the numeral and a second `Repeater` whose model is the **constant** `iconsPerSlot` — never the window count — which is the entire mechanism behind D-18-12's "nothing moves" guarantee; `+N` overflow (`Math.min(99, …)`-clamped) displacing the last cell's glyph once window count exceeds capacity; numeral colour `Colours.primary` when focused, `Colours.error` when urgent-and-unfocused, chrome `contentColour` otherwise.
- **Task 3 (vertical form + handoff):** the slot's main-axis extent stated explicitly from Design tokens (`Design.iconSizeMd * workspaceCapsule.iconsPerSlot + …`) rather than left implicit, using the same `iconsPerSlot` in both orientations (no per-orientation capacity split exists); no truncation property (`elide`/`ElideRight`/`maximumLineCount`) anywhere in the file, since every rendered string is bounded by construction; a recorded open-question comment naming `iconsPerSlot` as the one sanctioned tuning knob if 18-19's GATE-02 finds the full six-capsule vertical column overfull, and naming what is explicitly forbidden instead (dropping slots, hiding glyphs, eliding an entry present in horizontal).
- `qmllint` reports zero diagnostics against the finished file. Every grep-based acceptance criterion across all three tasks in `18-09-PLAN.md` passes (re-run and confirmed after two static-check failures were found and fixed mid-session — see Deviations).

## Task Commits

Each task was committed atomically:

1. **Task 1: Tracer — live glyph, resolver and guarded click dispatch for one workspace slot** — `3c2ef79` (feat)
2. **Task 2: Full fixed-extent workspace slot set — every slot, +N overflow, urgent/focused colour** — `518b44d` (feat)
3. **Task 3: Record the vertical-column tuning-knob handoff to 18-19's GATE-02** — `39d124c` (docs)

**Plan metadata:** pending final commit (this SUMMARY + STATE.md + ROADMAP.md + REQUIREMENTS.md)

## Files Created/Modified

- `quickshell/.config/quickshell/modules/bar/WorkspaceCapsule.qml` — filled in from 18-05's empty stub. No other file touched; `Bar.qml`, `BarEntryModel.qml`, `modules/bar/qmldir` and `Design.qml` are all byte-unchanged (confirmed via `git diff --name-only -- quickshell/` returning exactly this one path throughout).

## The Glyph Vocabulary As Shipped

Carried verbatim from the retired bar's athena layout's own `window-rewrite` table, in the source table's own order (this is `appGlyphMap`'s literal declaration order — order is load-bearing, since it decides the containment stage's tie-break):

| appId | glyph |
|---|---|
| `kitty` | 󰆍 |
| `firefox` |  |
| `zen` |  |
| `codium` | 󰨞 |
| `VSCodium` | 󰨞 |
| `discord` |  |
| `spotify` |  |
| `obsidian` | 󰹕 |
| `net.lutris.Lutris` |  |
| `steam` |  |
| `thunar` |  |
| `yazi` | 󰇥 |

**Deliberately not carried** (both recorded in source, both routed to 18-19's GATE-02 criterion A):
- The source table's own default glyph (`window-rewrite-default`, a ghost icon) — replaced everywhere by the shared bar-wide `"apps"` Material Symbol, the same placeholder the tray capsule uses for a broken pixmap, so the whole bar has one fallback convention instead of two (and the two were in different fonts besides).
- The source table's state icon set (`format-icons`: active/default/urgent/empty) — this capsule's slot identity is the workspace numeral (the shape the canonical `modules.jsonc` definition every other retired layout already shares uses), with state carried by colour instead (`Colours.primary` focused, `Colours.error` urgent). The athena layout showed a ghost glyph where this shows a number; 18-19 judges whether that reads as well.

## Shipped Constants

- `persistentSlotCount`: **5** — matches the canonical `modules.jsonc` definition (shared by two of the four retired layouts) and athena's own count; three of four retired layouts agree on 5, only `config-floating` uses 6. **Named delta for 18-19's GATE-02 criterion B**, one-integer remedy if the gate rules the sixth slot a loss.
- `iconsPerSlot`: **3** — reserved icon cells per slot in BOTH orientations. **The sanctioned tuning knob** if 18-19's GATE-02 pass finds the vertical column overfull once all six bar capsules exist (lowering it is a one-line change); dropping slots, hiding glyphs behind an expander, or eliding any horizontal-only entry is explicitly forbidden as the alternative.
- `appGlyphFontFamily`: **"FiraCode Nerd Font"** — a hand-carried parity value (the same class as `Design.qml`'s own `borderWidth`); the theme engine's live font-name state is only ever rendered embedded inside app-specific CSS/config fragments, never as a plain scalar this file could watch, so this family does **not** follow a live font change. If the Nerd Font family is ever changed via the theme engine, this is the line to update by hand.
- `appGlyphFallback`: **"apps"** — the Material Symbol ligature, rendered in `Design.symbolFontFamily` (not `appGlyphFontFamily`), matching the tray capsule's own broken-pixmap placeholder.

## Verification Status — read this before treating QBAR-03 as closed

**What the automated/static checks in this session established:**
- The dispatch expression's exact string shape (`hl.dsp.focus({workspace=` + a range-checked integer + `})`), matching `keybinds.lua`'s own Super+N binds and `Overview.qml`'s proven pattern — checked at the source level (grep/qmllint), **not exercised against the live compositor**.
- The constant cell count mechanism: the icon-cell `Repeater`'s model is the literal `iconsPerSlot` constant, never `windows`/`toplevels` — checked by grep, confirming the *structural* guarantee that geometry cannot vary with window count. This is a source-level proof, not a live "opened a window and measured pixels" proof.
- The glyph vocabulary: all 12 app-id keys present, fallback wired to the shared `"apps"` placeholder, no retired-surface name leaked into the file, no client-supplied string (`.title`) read anywhere, exactly one `Hyprland.dispatch(` call site with the object path tried first.
- `qmllint` reports zero diagnostics for the finished file (syntax/type-resolution level only — this does not exercise Quickshell's runtime module resolution the way a live reload would).

**What was explicitly NOT done this session, and why:**
- **No live `hyprctl dispatch` proof.** Task 1's `<verify>` calls for running the exact dispatch string live and confirming `hyprctl activeworkspace -j` reports the switched id, then restoring the starting workspace. Not run.
- **No live orientation flip.** Task 3's `<verify>` calls for writing `vertical`/`horizontal` into `~/.local/state/quickshell/bar-orientation`, reading `hyprctl monitors -j`'s reserved array both ways, and confirming it matches 18-05's recorded readings (`[[0,46,0,0]]` horizontal / `[[0,0,50,0]]` vertical). Not run; the orientation value on disk was not touched by this plan.
- **No `~/.cache/quickshell.log` tail-check.** Neither task's live log-error grep was run.
- **Task 3's human-check was not performed** — the six numbered checks (click switches workspaces including onto a never-opened one, icons are live and match open apps, nothing moves under window churn, overflow reads `+N` correctly, an unmapped app shows the shared placeholder, the vertical column fits with no clipping, theme switches re-colour with no magenta flash) require a human at the machine and were not simulated or assumed.
- Consistent with the plan's own instruction to "state clearly ... this proves the STRING, not the CLICK — conflating the two is exactly how a present-but-dead handler passes a gate" — nothing above is claimed as proof that clicking actually switches workspaces on this host. Only the source-level shape of the mechanism is established.

**Why:** recorded standing preference (this session) to skip live-probe/screenshot/restart-and-observe verification loops on already-written code — commit directly, document exactly what was and was not checked, and let the user verify at the machine rather than spending tokens re-deriving what a person sitting at the keyboard can confirm in seconds. Brevity here is explicitly not meant to imply anything was checked that wasn't.

**No Hyprland config reload and no compositor debug overlay were invoked** — trivially true, since no live commands were run at all this session (the plan's prohibition on both is satisfied by inaction rather than by a recorded restraint during an active probing session).

**To close this out:** relaunch/confirm the QML bar is running the current build, then walk through Task 3's `<human-check>` block in `18-09-PLAN.md` verbatim. If any check fails, this plan is blocked (per the plan's own text) — report the specific failure rather than 18-19.

## The Two Named Non-Coverages (for 18-19's GATE-02 criterion B)

- **Scroll-to-switch is not implemented on this capsule.** `config-floating`'s workspace module binds scroll to next/previous workspace; this capsule does not. The identical capability already exists globally via `keybinds.lua`'s `Super + mouse_down` / `Super + mouse_up` binds (`hl.dsp.focus({workspace="e+1"/"e-1"})`), so only scroll-over-the-bar-without-holding-Super is lost. QBAR-03's requirement text is click-only; every scroll gesture in this phase belongs to QBAR-04, owned by 18-12. If 18-19's GATE-02 rules this a loss, 18-12 is the remedy's home.
- **Five persistent slots, not six.** `config-floating` is the lone retired layout using 6; the canonical shared definition and athena both use 5. Remedy if GATE-02 rules against it: change `persistentSlotCount` from 5 to 6, a one-integer edit.

## Decisions Made

- **Constants stay local to this file, not hoisted to `Design.qml`.** None of `persistentSlotCount`/`iconsPerSlot`/`appGlyphFontFamily` appears in `18-UI-SPEC.md`'s New Tokens table, and this is the only file that reads any of them — `Design.qml`'s own header states the hoisting rule (two-file need) and its one recorded not-consolidated precedent (`fillAxisAvailable`, a per-file capability flag). Practical consequence: this plan touches exactly one file, so 18-08/18-10/18-11 share nothing with it in this wave.
- **Colour bindings inlined at the `color:` call site rather than factored into a computed property.** First draft used a `numeralColour` property; the plan's own acceptance grep (`grep -nE '(^|[^A-Za-z.])color:' ... | grep -vE 'Colours\.|contentColour'`) expects the token reference to be textually present on the `color:` line itself, which a factored property defeats even though it resolves to the same token. Caught by re-running the grep before commit; fixed by inlining the ternary.
- **Reworded the "no truncation" comment to avoid the literal words `ElideRight`/`maximumLineCount`.** The plan states the gate for "no truncation treatment" is "anchored on the QML property assignment, not the bare word," but the actual grep pattern (`elide: |ElideRight|maximumLineCount`) matches those two identifiers as bare words anywhere in the file, including comments. Caught by re-running the grep before commit; the explanatory comment now describes the precedent in prose without spelling either flagged identifier, keeping the intent (explain why no truncation is needed) without tripping the literal gate.
- **`slotIds` built by comparison-insertion, not `Array.prototype.sort()`/`.reverse()`.** The plan's ordering contract explicitly forbids "a sorting pass of any kind" in this file while simultaneously requiring ascending slot order — resolved by inserting each dynamic (beyond-persistent-range) workspace id at its comparison-found position rather than calling a general sort function over the whole set, since the persistent range is already ascending by construction.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Colour token not visible at the `color:` call site**

- **Found during:** Task 2, static acceptance-criteria re-check
- **Issue:** The numeral's colour was computed via a `numeralColour` property; the plan's colour-token grep gate checks the `color:` line itself for `Colours.`/`contentColour`, which a factored property doesn't satisfy even though it resolves correctly at runtime.
- **Fix:** Inlined the focused/urgent/default ternary directly at the `color:` binding.
- **Files modified:** `quickshell/.config/quickshell/modules/bar/WorkspaceCapsule.qml`
- **Verification:** Re-ran the grep; 0 matches (was 1).
- **Committed in:** `518b44d`

**2. [Rule 1 - Bug] "No truncation" comment tripped its own literal-word gate**

- **Found during:** Task 2, static acceptance-criteria re-check
- **Issue:** A comment explaining that no truncation treatment is needed used the words `elide`/`maximumLineCount` in prose, which the plan's own `grep -cE 'elide: |ElideRight|maximumLineCount'` gate matches as bare words rather than as property assignments (despite the plan's parenthetical claiming otherwise).
- **Fix:** Reworded the comment to describe the same precedent without spelling either flagged identifier.
- **Files modified:** `quickshell/.config/quickshell/modules/bar/WorkspaceCapsule.qml`
- **Verification:** Re-ran the grep; 0 matches (was 1).
- **Committed in:** `518b44d`

**3. [Rule 1 - Bug] Retired surface's file path leaked into a Task 1 comment**

- **Found during:** Task 1, static acceptance-criteria re-check
- **Issue:** The glyph-map provenance comment initially spelled out the retired bar's own config path (containing the literal substring "waybar"), tripping the plan's "no retired-surface name in live code" gate.
- **Fix:** Reworded to name the mechanism (the athena `window-rewrite` map) rather than a path that will not exist post-retirement.
- **Files modified:** `quickshell/.config/quickshell/modules/bar/WorkspaceCapsule.qml`
- **Verification:** Re-ran `grep -ci waybar`; 0 (was 1).
- **Committed in:** `3c2ef79`

**Total deviations:** 3 auto-fixed (all Rule 1 — self-caught by re-running the plan's own static acceptance criteria before each commit, not found by any external review).
**Impact on plan:** All three were pre-commit corrections to keep the shipped file passing its own stated gates; none is scope creep, and none touched behaviour — only comment wording and where a colour ternary is written.

### Process Deviation (not a Rule 1-4 code fix — recorded separately per plan instruction)

**Live verification and the human-check gate were skipped, by standing preference, not by mistake or oversight.** See "Verification Status" above for the full accounting of what was and was not checked. This is the reason QBAR-03 is marked `requirements-partial` above rather than `requirements-completed`.

## Issues Encountered

None beyond the three self-caught static-gate mismatches above.

## User Setup Required

None for the code itself. **Action needed to close QBAR-03:** walk through `18-09-PLAN.md` Task 3's `<human-check>` block against the live bar (click an indicator, confirm the desktop switches — including onto a never-opened workspace; confirm live icons match open apps; confirm nothing moves under window open/close; confirm `+N` overflow; confirm an unmapped app shows the `"apps"` placeholder; confirm the vertical column fits with `echo vertical > ~/.local/state/quickshell/bar-orientation`; confirm theme switches re-colour correctly), then restore `~/.local/state/quickshell/bar-orientation` to `horizontal` if it was changed.

## Known Stubs

None. Every state this capsule can be in (zero windows, no live workspace object, unmapped app id, overflow, focused, urgent) is handled by real logic — no hardcoded empty value, no placeholder text, no component left unwired. The one thing genuinely missing is *proof*, not *code*: see Verification Status above.

## Next Phase Readiness

- `WorkspaceCapsule.qml` is the third of six wave-3 capsule slots filled; `Bar.qml`, `BarEntryModel.qml`, `modules/bar/qmldir` and `Design.qml` remain byte-unchanged, so 18-08/18-10/18-11 continue to share nothing with this plan.
- **Outstanding, blocking for 18-19's GATE-02 citation of QBAR-03 (not blocking for the rest of wave 3):** the live dispatch-string proof, the orientation-flip reserved-array reading, and the six-point human click-through gate — none performed this session. Logged to `WINDOWS.md` as an `unrun-verify` entry below.
- Two named, on-the-record non-coverages await 18-19's GATE-02 criterion B ruling: scroll-to-switch (remedy: 18-12) and the five-vs-six persistent slot count (remedy: one-integer change here).

## Self-Check: PASSED

- FOUND: `quickshell/.config/quickshell/modules/bar/WorkspaceCapsule.qml`
- FOUND commit: `3c2ef79`
- FOUND commit: `518b44d`
- FOUND commit: `39d124c`

---
*Phase: 18-qml-bar-retirement-machinery*
*Completed: 2026-08-11*
