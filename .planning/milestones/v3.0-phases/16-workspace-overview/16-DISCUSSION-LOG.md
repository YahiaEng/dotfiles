# Phase 16: Workspace Overview - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-02
**Phase:** 16-workspace-overview
**Areas discussed:** Grid composition & scope, Capture fidelity + OVER-04, Drag grammar (OVER-03), Entry/exit & window clicks, Gate coverage, Motion

---

## Grid composition & scope

### Q1 — Which workspaces appear in the grid?

| Option | Description | Selected |
|--------|-------------|----------|
| Fixed 10 slots | Always rendered, occupied or not. Mirrors Super+1..0 binds. Drag targets never move; drag-to-empty-workspace always possible. Matches end-4 and hyprexpo. | ✓ |
| Occupied + one trailing empty | Denser, no dead tiles. Tile positions shift between summons, moving drop targets. | |
| Occupied only | Densest. No way to drag onto a fresh workspace at all. | |

**User's choice:** Fixed 10 slots (recommended)
**Notes:** Spatial constancy judged worth more than density on an aim-and-drop surface.

### Q2 — How do windows lay out inside a tile?

| Option | Description | Selected |
|--------|-------------|----------|
| Real scaled geometry | Windows at actual positions/sizes from `lastIpcObject`, scaled by tileWidth/2560. Recognize a workspace by shape. Tile inherits 16:9. | ✓ |
| Uniform flow grid | Equal-sized cards wrapping in the tile. Larger individual thumbnails, but destroys the spatial signature. | |
| Geometry + declutter overlaps | Real positions, then nudge fully-occluded floaters apart. Positions no longer match reality. | |

**User's choice:** Real scaled geometry (recommended)
**Notes:** Settles tile aspect ratio as a side effect.

### Q3 — Grid arrangement?

| Option | Description | Selected |
|--------|-------------|----------|
| 5 × 2 | Tiles ~480×270. Mirrors the number row: 1 2 3 4 5 over 6 7 8 9 0. | ✓ |
| 4 × 3 | Larger tiles (~600×338) but a ragged two-tile last row; number mapping breaks. | |
| Adaptive to monitor aspect | Computed at summon. Hardware-dependent positions, no benefit on one 16:9 display. | |

**User's choice:** 5 × 2 (recommended)
**Notes:** The keyboard-mirroring argument was decisive; later enabled D-16-16's `Shift+1..0`.

### Q4 — Monitor scope, given QS-03?

| Option | Description | Selected |
|--------|-------------|----------|
| One surface, all workspaces | On the focused monitor, showing every workspace regardless of owner. Dissolves QS-03 rather than fighting it. Recorded as the QS-03 discharge. | ✓ |
| One surface, focused monitor's workspaces only | Stricter semantics, but the other display's workspaces become unreachable. | |
| Re-attempt per-screen fan-out | Contradicts D-13, a locked one-way decision backed by 12-QS03-EVIDENCE.md. | |

**User's choice:** One surface, all workspaces (recommended)

### Q5 — Should the scratchpad (`special:magic`) appear?

| Option | Description | Selected |
|--------|-------------|----------|
| Always-present 11th tile | Reserved, visually distinct, centered below the 5×2 block. Satisfies criterion 1 literally; enables drag out of the scratchpad. | ✓ |
| Show only when occupied | No dead tile, but cannot drag a window *into* the scratchpad. | |
| Omit entirely | Matches hyprexpo and end-4 exactly. Criterion 1 becomes literally false, silently. | |

**User's choice:** Always-present 11th tile (recommended)
**Notes:** Presented explicitly as a case where the standing end-4/Caelestia lens and a hard phase criterion pointed opposite ways; the lens is the tiebreaker only when trade-offs are close.

### Q6 — Backdrop treatment?

| Option | Description | Selected |
|--------|-------------|----------|
| Family blur, blur = fallback lever #1 | Inherits `^quickshell-.*` blur. ~5× larger blur region than anything shipped; dropping it per-namespace is pre-authorized as OVER-04's first fallback. | ✓ |
| Opaque palette surface | Cheapest by far. Breaks visual kinship; reads as a separate app. | |
| Scrim without blur from day one | Middle cost, but a family inconsistency justified up front rather than earned by measurement. | |

**User's choice:** Family blur with blur as fallback lever #1 (recommended)

---

## Capture fidelity + OVER-04

### Q1 — Live thumbnails or frozen snapshots?

| Option | Description | Selected |
|--------|-------------|----------|
| Live first + fallback ladder | `live: true` everywhere, measured, with a pre-authorized descent: drop blur → live only on hovered tile + focused workspace → snapshots everywhere. | ✓ |
| Live only where you're looking | Nearly guaranteed smooth. Pre-concedes the measurement OVER-04 exists to take. | |
| Frozen snapshots everywhere | Cheapest. Gives up the requirement's headline word before testing it. | |

**User's choice:** Live first, fall back if slow (recommended)
**Notes:** ⚠ This question was **rejected on first ask** — the user read "frame and CPU budget" as agent token budget and asked for clarification. It was re-asked in plain language (GPU/CPU while the overview is on screen; live video feeds vs still pictures) and answered. Recorded in CONTEXT.md `<specifics>` as guidance for downstream checkpoints.

### Q2 — What performance bar must be cleared?

| Option | Description | Selected |
|--------|-------------|----------|
| 60fps floor, 165 target, <half a core | Measured with 8+ windows across 3+ workspaces. Below 60fps or above half a core triggers the ladder; 60–165 is recorded as a result, not a failure. | ✓ |
| Must match the monitor's 165fps | Same bar as the drawer. Would fire the ladder even when the surface looks smooth. | |
| Judge it by eye | Simplest. Makes OVER-04 a gate that cannot fail. | |

**User's choice:** 60fps floor / 165 target / under half a core (recommended)

### Q3 — Screen-capture permission lock?

| Option | Description | Selected |
|--------|-------------|----------|
| Enable, prove, leave on | Flip `enforce_permissions`, log out and back in, verify thumbnails + screenshots + colour picker + screen sharing. Closes Phase 11's deferred proof. | ✓ |
| Enable, prove, then disable | Same evidence, no ongoing risk. Ships a verified system that is switched off. | |
| Test in nested Hyprland first | Safest. May not reproduce real screencopy behaviour, so may not count as the proof. | |
| Skip it, record the gap | Zero effort. Requirement open for a third phase; the silent-blank-tile risk stays untested. | |

**User's choice:** Enable, prove, leave on (recommended)

### Q4 — What does a tile show when capture produces no picture?

| Option | Description | Selected |
|--------|-------------|----------|
| Icon + title + real reason on denial | Pending → picture, or icon/title/one-line reason via `hasContent`. Plus a whole-grid catch when nothing anywhere captures. Uses D-15-09's four-state vocabulary. | ✓ |
| Icon + title card, no error text | Visually tidy. Permission denial becomes indistinguishable from a slow first frame. | |
| Leave the tile blank | What the Phase 11 probe does; exactly what the "Owns" clause exists to prevent. | |

**User's choice:** Icon + title + real reason on denial (recommended)

### Q5 — Should the capture mode be runtime-switchable?

| Option | Description | Selected |
|--------|-------------|----------|
| Baked in at build time | One code path, one verdict. Ladder documented in CONTEXT.md. Avoids a second runtime state axis and config that rots. | ✓ |
| Runtime JSON toggle | `FileView`/`JsonAdapter` machinery proven; `motion-switch.sh` is precedent. Three code paths and likely-dead config. | |
| Adapt automatically | Oscillates — thumbnails visibly flip between live and frozen — and makes the measurement non-reproducible. | |

**User's choice:** Baked in at build time (recommended)
**Notes:** The dead `eww-media-popup` layerrules in the current tech-debt list were cited as the concrete precedent for config that rots.

---

## Drag grammar (OVER-03)

### Q1 — What follows the cursor?

| Option | Description | Selected |
|--------|-------------|----------|
| A still snapshot of the window | One frame via `captureFrame()` at drag start. Near-identical visually, free to move. Protects the floor at the load peak. | ✓ |
| The live thumbnail itself | Most physical. Moves a live video feed every frame at the tightest moment. | |
| A plain ghost card | Cheapest. Breaks the visual thread between what was grabbed and what is held. | |

**User's choice:** A still snapshot (recommended)

### Q2 — What happens on drop?

| Option | Description | Selected |
|--------|-------------|----------|
| Move it, overview stays open | Silent move; keep rearranging. Grammar: drag = organize, click = navigate. Matches GNOME and Mission Control. | ✓ |
| Move it, close, and go there | One gesture. Three windows means three summons; two actions both close. | |
| Move it, close, stay put | Multi-move penalty without the payoff. | |

**User's choice:** Move it, overview stays open (recommended)

### Q3 — Drop-target highlight and missed drop?

| Option | Description | Selected |
|--------|-------------|----------|
| Hovered tile lights, miss cancels home | Accent-role shift using D-26's existing lit-tile language. Drop outside cancels; snapshot animates back. | ✓ |
| Highlight plus landing preview | Most informative, but the predicted position is a guess Hyprland overrules on arrival. | |
| All targets glow, hovered strongest | Teaches the affordance. Eleven glowing rectangles per drag; against established restraint. | |

**User's choice:** Hovered tile lights, miss cancels home (recommended)

### Q4 — Should the keyboard do anything while open?

| Option | Description | Selected |
|--------|-------------|----------|
| Esc + number keys | Smallest addition, no new rendered state, cashes in the 5×2 number-row mapping. **(Recommended)** | |
| Full keyboard navigation | Arrows move a selection, Enter focuses, Shift+number moves. A selection state to render, sync and reason about mid-drag. | ✓ |
| Mouse-only, Esc to dismiss | Exactly the criteria and nothing more. | |

**User's choice:** Full keyboard navigation — **RECOMMENDATION OVERRIDDEN**
**Notes:** Third recorded override in this project's history (after Phase 14 D-31 and Phase 15 D-15-11). Recorded in CONTEXT.md as a deliberate scope widening so verification does not read it as drift. A hard boundary was attached at the time: this must not drift into type-to-search, which `REQUIREMENTS.md:100` excludes from v3.0 as OVER-05.

### Q5 — What should keyboard selection move over?

| Option | Description | Selected |
|--------|-------------|----------|
| Two levels: tiles, then windows | Arrows between tiles; Enter/Down drops in; arrows between windows; Enter focuses; Shift+1..0 moves. Two-stage Esc per D-15-14. | ✓ |
| One flat field of windows | No modes, exploits D-16-02's real positions. Ambiguous across tile borders; empty workspaces have no window to land on. | |
| Tiles only, Shift+number moves the active window | Simplest. Cannot move a window you can see unless it's already active. | |

**User's choice:** Two levels (recommended)

### Q6 — Pre-agreed fallback for the keyboard model?

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — fall back to Esc + number keys | If the render gate finds the mode indicator cluttered or the two levels confusing, retreat without a new decision. Same shape as D-15-11. | ✓ |
| Yes, but fall back only one step | Keep window selection, drop the moves. Narrower escape hatch. | |
| No pre-agreed fallback | Fresh decision at the gate with full context. Pauses the phase mid-gate. | |

**User's choice:** Fall back to Esc + number keys (recommended)

---

## Entry, exit & window clicks

### Q1 — Which keybind?

| Option | Description | Selected |
|--------|-------------|----------|
| Super+O | Obeys D-09's first-letter mnemonic; consistent with Super+D and Super+A. O confirmed free. | ✓ |
| Super+Tab | Most discoverable. Breaks D-09; Tab implies cycling. | |
| Super+` (grave) | hyprexpo's default. Breaks D-09; awkward reach. | |

**User's choice:** Super+O (recommended)
**Notes:** Free plain-Super letters recorded as G, H, J, K, M, O, U. Phase 11 Finding 1 (GlobalShortcut needs a process restart to register) noted as applying regardless of choice.

### Q2 — Inherit DASH-08's fullscreen refusal guard?

| Option | Description | Selected |
|--------|-------------|----------|
| Exempt it, document the reason | Navigation surface, not informational. Super+1..0 already navigate while fullscreen; blocking Super+O would be incoherent. | ✓ |
| Inherit the guard | One rule, no exceptions. Unreachable exactly when most useful. | |
| Exempt, but degrade while fullscreen | Protects the budget at its worst moment. A conditional path easy to leave untested. | |

**User's choice:** Exempt it, document the reason (recommended)
**Notes:** The performance counter-argument was answered by folding that condition into D-16-08's measurement rather than by hiding the surface.

### Q3 — What does clicking a window thumbnail do?

| Option | Description | Selected |
|--------|-------------|----------|
| Focus that window; empty area focuses workspace | Both close. Exact parity with the keyboard model. | ✓ |
| Any click focuses the workspace only | Criterion 2 literally. The mouse would do less than the keyboard. | |
| Focus the window, plus hover-× to close | GNOME behaviour. A new capability no criterion asks for; hover chrome over live captures costs render work. | |

**User's choice:** Focus that window; empty area focuses the workspace (recommended)
**Notes:** Hover-× was flagged as out of bounds before the question was asked and is recorded as a deferred idea.

### Q4 — Any entry point besides Super+O?

| Option | Description | Selected |
|--------|-------------|----------|
| Keybind only | Avoids re-opening D-15-21's six-across arithmetic and four waybar configs plus two lint gates. | ✓ |
| Add a dashboard quick-toggle tile | Discoverable without knowing the chord. Re-opens D-15-21; drawer→overview is a two-animation handoff. | |
| Add a waybar button | Always visible. Four configs plus `modules.jsonc`, re-opens two lint gates, duplicates a one-key summon. | |

**User's choice:** Keybind only (recommended)

### Q5 — How is criterion 5's multi-day use note discharged?

| Option | Description | Selected |
|--------|-------------|----------|
| Dated running note, 3+ days, structured first pass | Deliberate first sweep, then ordinary use appended with dates. Closure needs entries spanning 3+ calendar days. | ✓ |
| Structured checklist, two separate days | More rigorous, finishes sooner. A test protocol is the "click-and-look" the criterion is written against. | |
| Free-form note when it feels done | Lightest. Indistinguishable from a same-day sign-off. | |

**User's choice:** Dated running note, 3+ days (recommended)
**Notes:** Scheduling consequence stated explicitly at the time — this phase cannot close on build day, and Phase 17 (the cut candidate) sits behind it.

---

## Gate coverage & motion

### Q1 — How far should `quickshell-doctor`'s coverage extend?

| Option | Description | Selected |
|--------|-------------|----------|
| Namespace + keybind + permissions + capture check | Six checks including live `enforce_permissions` verification, allow-list path resolution, and an `overview` IPC verb reporting tiles-with-content. | ✓ |
| Namespace + keybind + permission guards | Everything except the capture self-check. Blank tiles still depend on a human noticing. | |
| Match Phase 15's scope exactly | Near-zero new code. Leaves both risks this phase owns unguarded. | |

**User's choice:** Full coverage including the capture check (recommended)
**Notes:** Honest caveat recorded: falsifying the capture check via the natural poison (removing quickshell from the allow list) needs a Hyprland restart; the practical falsification is running it while the overview is not summoned.

### Q2 — Entrance motion?

| Option | Description | Selected |
|--------|-------------|----------|
| Cascade by row + fade layerrule | Three steps, ~380ms, well inside D-21's 700ms fence. Reuses the existing stagger token. Fade because a full-screen surface has no edge to slide from. | ✓ |
| Cascade all 11 tiles individually | Most satisfying. Only fits the fence at the bottom of the stagger range (630–850ms); heaviest while captures initialise. | |
| No tile cascade, layer fade only | Cheapest, zero fence risk. The milestone's most prominent surface would carry the least motion in the shell. | |

**User's choice:** Cascade by row + fade layerrule (recommended)

---

## Claude's Discretion

- Empty-tile styling (D-41's vocabulary settles the shape; glyph and weighting are open)
- Workspace number typography and placement, tile corner radius, gap sizes, the multi-monitor badge design, the hint line's copy or its omission
- The mode indicator's visual treatment for two-level keyboard selection
- Scale-up factor, shadow and cancel-animation curve on the dragged snapshot
- How the fps/CPU measurement is instrumented
- Material Symbol picks and tooltip copy
- Plan/wave decomposition and sequencing (granularity: `coarse`)

## Deferred Ideas

- OVER-05 type-to-search inside the overview — explicitly excluded from v3.0
- Hover-× to close windows from the overview
- A dashboard quick-toggle tile for the overview
- A waybar button or workspaces-module route to the overview
- A runtime capture-mode toggle
- Overlap-decluttering inside a tile
- A landing preview during drag
- Per-screen overview instances (blocked by QS-03, not actionable)
