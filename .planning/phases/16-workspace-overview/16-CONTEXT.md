# Phase 16: Workspace Overview - Context

**Gathered:** 2026-08-02
**Status:** Ready for planning

<domain>
## Phase Boundary

One new full-screen QML surface — `quickshell-overview` — showing a grid of
workspace tiles, each holding live `ScreencopyView` thumbnails of that
workspace's windows drawn at their real scaled positions. Clicking focuses and
closes; dragging a window thumbnail onto another tile moves it. Requirements:
OVER-01, OVER-02, OVER-03, OVER-04.

The phase **owns** two named risks the roadmap assigns it: live multi-window
screencopy performance (the genuine open risk — the protocol question is
already settled as `ScreencopyView` + `hyprland-toplevel-export-v1`, native,
no plugin, no `hyprpm`), and **silently-denied screencopy permissions
rendering blank tiles instead of erroring**. It also inherits and must
discharge Phase 11's deferred live-enforcement proof for
`ecosystem:enforce_permissions`.

It is the highest-frequency new surface in the milestone, which is why
criterion 5 forbids closing it on a single click-and-look.

**User lens (standing, carried from Phases 14 and 15):** when design
trade-offs are close, follow the **end-4 (dots-hyprland) and Caelestia
shell** conventions. This lens is *not* the tiebreaker when it conflicts with
a hard phase criterion — see D-16-05, where criterion 1's literal wording
overrode it deliberately and with the divergence recorded.

**Standing instruction (carried from Phase 15):** present deep pros/cons plus
an explicit recommendation on every question — at planning checkpoints and
render gates too, never a bare options menu.

</domain>

<decisions>
## Implementation Decisions

24 decisions across 6 areas. The user **overrode the recommendation once**
(D-16-15, full keyboard navigation) — the third recorded override in this
project's history, after Phase 14's D-31 and Phase 15's D-15-11 — and
authorized a pre-agreed fallback for it (D-16-17), continuing the pattern
15-CONTEXT.md named as "the pattern to repeat".

### Grid composition & scope

- **D-16-01: Fixed 10 workspace slots, always rendered, occupied or not.**
  Mirrors the mental model the keybinds already teach (`Super+1..0` focus,
  `Super+Shift+1..0` move). Workspace 7 is always in the same screen position,
  so muscle memory forms and **the drag target never moves between summons** —
  which is what makes criterion 3's aim-and-drop viable. It is also the only
  option that lets you drag a window onto a *fresh* workspace, the commonest
  reason to open an overview at all. Matches hyprexpo and end-4's overview.
  Rejected occupied-only and occupied-plus-one-empty because tile positions
  would shift between summons, moving drop targets under the cursor.
  Accepted cost: empty tiles are visible when few workspaces are in use.

- **D-16-02: Windows drawn at real scaled geometry inside each tile.**
  `HyprlandToplevel.lastIpcObject` carries `at: [x,y]` and `size: [w,h]`
  straight from `hyprctl clients`; scale is `tileWidth / monitorWidth`. Each
  tile is a true miniature, so a workspace is recognizable **by shape** without
  reading any text — the entire reason this surface beats Alt-Tab. Also makes
  the drag honest: you grab the window as it actually appears. Matches
  hyprexpo, end-4, GNOME Activities and Mission Control.
  **Consequence: the tile carries the monitor's aspect ratio (16:9 here)** —
  tile shape is settled by this decision, not chosen separately.
  Accepted costs: overlapping floating windows render overlapping (correct but
  can occlude); at ~450px tile width a half-screen window renders ~220px
  across — ample for recognition, not for reading, which is all criterion 1
  asks. Rejected a uniform flow grid (destroys the spatial signature; two
  workspaces with equal window counts become interchangeable) and
  overlap-decluttering (a second layout pass whose positions no longer match
  reality).

- **D-16-03: 5 columns × 2 rows.**
  Tiles ≈ 480×270 (scale ≈ 0.19), block centered with vertical slack for
  workspace numbers and a hint line. **Decisive argument: it mirrors the
  number row exactly** — `1 2 3 4 5` over `6 7 8 9 0` — so D-16-01's spatial
  constancy *teaches itself*, the grid being literally shaped like the binds
  already pressed. This directly enables D-16-15's number-key behaviour.
  Rejected 4×3 (larger tiles, but a ragged two-tile last row and the
  position-to-number mapping breaks) and monitor-adaptive layout (hardware-
  dependent tile positions for zero benefit on a single 16:9 display).

- **D-16-04: One surface on the focused monitor, showing every workspace
  regardless of which monitor owns it. This is the recorded discharge of the
  roadmap's QS-03 obligation.**
  The roadmap states Phase 16 "inherits a shell root that cannot fan out and
  must solve this itself"; PROJECT.md marks QS-03 Out of Scope as a **one-way**
  decision backed by `12-QS03-EVIDENCE.md` (FM2 reproduced in two structurally
  distinct `Variants` arrangements across a real session restart). Rather than
  re-open a closed decision, the obligation is discharged **by design**: a
  global overview only ever wants one surface, so "cannot fan out" stops being
  a limitation and becomes the correct architecture. On a second monitor you
  summon it wherever focus is and can still see and drag to everything; a small
  monitor badge on tiles covers the ambiguity when more than one display is
  connected. Matches GNOME Activities and hyprexpo.
  **Verification must read this as the requirement's answer, not as a dodged
  requirement.** Rejected focused-monitor-workspaces-only (the other display's
  workspaces become unreachable — worse than the limitation it respects) and
  re-attempting fan-out (contradicts a locked one-way decision).
  — **Reversibility:** one-way in practice — reversing means re-opening D-13,
  which `12-QS03-EVIDENCE.md` closed with live evidence on quickshell 0.3.0-2.

- **D-16-05: The scratchpad (`special:magic`) gets an always-present, visually
  separated 11th tile.**
  **This is a deliberate divergence from the end-4/Caelestia lens, taken with
  the reason recorded.** Both reference shells (and hyprexpo) grid over
  numbered workspaces only. But criterion 1 says "every open window appears as
  a live thumbnail", and a window sent to the scratchpad by `Super+Shift+S` is
  an open window — omitting it makes criterion 1 literally false, and it fails
  in the worst possible way: silently, with a window simply absent from a
  surface claiming completeness. The standing lens is the tiebreaker when
  trade-offs are *close*; a hard phase gate is not close.
  Placed in a permanently reserved position (centered below the 5×2 block,
  distinct styling, scratchpad glyph instead of a number) so the 10 numbered
  tiles never move and D-16-01's constancy is untouched. **Bonus capability:
  drag works symmetrically — pulling a window *out* of the scratchpad, which
  no current keybind does.** Rejected show-only-when-occupied (you then cannot
  drag a window *into* the scratchpad, since the tile does not exist until
  something is already there) and omitting it (criterion 1 becomes false).
  Accepted costs: a usually-empty tile, and the grid is no longer a clean
  rectangle.

- **D-16-06: Translucent scrim inheriting the family `^quickshell-.*` blur —
  and dropping that blur per-namespace is OVER-04's pre-authorized fallback
  lever #1.**
  Consistency with the drawer and panels, zero new layerrule config, and
  dismissal reads as lifting a lens off a desktop that was there all along.
  **Named risk, quantified:** every prior consumer of that blur rule is a
  *panel* (~850px wide); this surface is 2560×1440, so it is roughly a **5×
  larger blur region than anything the shell has drawn to date**, running
  simultaneously with 11 tiles of live capture during the entrance animation.
  That is exactly the load OVER-04 exists to measure. Because the cost is
  named up front, cutting it needs no new decision — see D-16-07's ladder.
  Rejected an opaque palette surface (cheapest, but breaks visual kinship and
  makes the overview read as a separate app) and opting out of blur from day
  one (a visible family inconsistency justified up front rather than earned by
  a measurement).

### Capture fidelity & OVER-04

- **D-16-07: Live capture on every window first, with a pre-authorized
  fallback ladder.**
  `ScreencopyView.live = true` on every window. **This is the shape OVER-04's
  own wording asks for** — *"either stays inside it or ships the documented
  fallback instead — the measurement and the verdict are both recorded"* — i.e.
  the requirement is not "make live work", it is "try live, measure honestly,
  fall back with the verdict written down".
  Mechanics that make this the named risk: each view is an independent capture
  stream, Hyprland copies a buffer per frame per client, and on this host that
  can mean ~15 concurrent streams from a **165Hz** monitor with windows up to
  2560×1440.
  **The ladder, pre-authorized — descend without a new decision:**
  1. Drop the full-screen blur via a per-namespace layerrule (D-16-06).
  2. Live only on the hovered tile and the focused workspace; `captureFrame()`
     snapshots elsewhere.
  3. Snapshot-on-summon everywhere, with an explicit refresh control.
  Rejected starting hybrid or snapshot-only: both pre-concede the measurement
  OVER-04 exists to take, reducing the requirement from recording a *result*
  to recording a *choice*.

- **D-16-08: The budget — 60fps floor, 165fps target, quickshell under half of
  one CPU core, measured with 8+ windows across 3+ workspaces.**
  Below 60fps or above half a core triggers the ladder; landing between 60 and
  165 is **recorded as the result, not as a failure**. The window-count and
  workspace-spread conditions are part of the budget, not an afterthought — a
  measurement taken with two windows open means nothing.
  Rejected holding it to the drawer's full 165fps (Phase 14 got the drawer
  there after the `QSG_RENDER_LOOP=threaded` fix, but applying that bar here
  would fire the ladder even when the surface looks perfectly smooth, trading
  live thumbnails for a number rather than for a visible problem) and judging
  by eye (makes OVER-04 a gate that cannot fail — the exact pattern this
  project's gate discipline refuses).

- **D-16-09: Enable `ecosystem:enforce_permissions`, prove it with a real
  logout, and leave it ON.**
  This closes the proof Phase 11 explicitly deferred here (see
  `11-QUICKSHELL-EVIDENCE.md` §"What was deliberately NOT tested"). The
  mechanism, the type/mode strings, the restart-not-reload requirement and all
  four consumer binary paths are already binary-verified; **only live
  enforcement is unproven**, and `permissions.lua` currently ships inert.
  **The proof:** flip the value, log out and back in, then verify four paths
  still work — overview thumbnails, `Super+Print` screenshots, `Super+X`
  colour picker, and browser screen-sharing. Recovery if the allow-list is
  wrong: flip it back and log in again. Nothing is destroyed.
  Directly relevant to this phase: **if quickshell is not correctly allowed,
  Hyprland does not error — it hands back nothing and every thumbnail goes
  blank**, which is the exact failure this phase's "Owns" clause names.
  Rejected proving-then-disabling (ships a verified permission system that
  does nothing), nested-Hyprland-only (may not reproduce real screencopy
  behaviour faithfully, so may not count as the proof), and skipping (an
  inherited requirement open for a third phase).
  **Known unconfirmed consumer, carried from Phase 11:** `gpu-screen-recorder`
  (SHOT-03, `record-toggle.sh`) shows no direct `screencopy` protocol string
  and likely captures via KMS/DRM or the portal's ScreenCast path — flagged,
  never guessed at. **Verify it under live enforcement as part of this proof.**
  — **Reversibility:** reversible — one value in `permissions.lua` plus a
  restart, but note that any change here needs a full Hyprland restart, never
  `hyprctl reload`.

- **D-16-10: An empty capture renders a pending state, then icon + title +
  a one-line reason on genuine denial — plus a whole-grid catch.**
  `ScreencopyView.hasContent` makes "did this produce a picture" a plain
  boolean, so empty is detectable rather than guessed. Three causes deserve
  different answers: first frame not yet arrived (momentary, self-resolving →
  pending), genuinely blank window, and denied capture (permanent → the user
  must be told). Reuses **D-15-09's four-state vocabulary**
  (populated / pending / empty / failed) rather than inventing a fifth.
  **Whole-grid catch:** if *no* window anywhere in the grid produces content,
  that is a permission problem, not 15 simultaneously-slow windows — say it
  once at the surface level rather than 15 times on 15 tiles.
  Rejected an icon+title card with no error text (a permission denial becomes
  indistinguishable from a slow first frame — the silent failure survives,
  just prettier) and leaving tiles blank (correct for Phase 11's probe;
  precisely what the "Owns" clause exists to prevent).

- **D-16-11: The capture mode is baked in at build time, not runtime-
  switchable.**
  One code path, one tested behaviour, one recorded OVER-04 verdict — which is
  what the requirement asks for ("*the* documented fallback", singular; a menu
  of three modes is a different artifact). Avoids a second runtime state axis
  living outside `theme-apply`, against the "one entrypoint per state axis"
  discipline. **Specific repo-grounded argument:** the tech-debt list currently
  carries dead `eww-media-popup` layerrules unclaimed since Phase 10 — config
  that exists for a case that never arrives does not stay neutral, it rots.
  The ladder stays written down here, so changing course later is a small edit
  rather than a rediscovery.
  Rejected a runtime JSON toggle (the `FileView`/`JsonAdapter` machinery is
  proven from Phase 11 and `motion-switch.sh` is precedent, but it costs three
  code paths and likely-dead config) and automatic adaptation (**actively
  harmful**: a shell that downgrades itself on frame drops oscillates, so
  thumbnails visibly flip between live and frozen while being watched, and the
  OVER-04 measurement stops being reproducible because the thing being measured
  changes itself mid-measurement).

### Drag grammar (OVER-03)

- **D-16-12: A still snapshot follows the cursor; the source tile shows the
  gap.**
  One frame grabbed via `captureFrame()` at drag start, dragged as a static
  image with a slight scale-up and shadow. **Visually near-identical to
  dragging the live view** — the difference only shows if window content
  changes during the ~1s drag — but essentially free to move.
  Decisive reasoning: a drag is the phase's **load peak** — live captures still
  running on every other tile, full-screen blur, drop-target highlight
  animating, and now something tracking the cursor at 165Hz. This choice
  protects D-16-08's floor at exactly that moment.
  Rejected dragging the live thumbnail itself (most physical, but moves a live
  video feed across the screen every frame at the tightest possible moment) and
  a plain ghost card (cheapest, but breaks the visual thread between what was
  grabbed and what is held — which bites when several windows in a tile look
  alike).

- **D-16-13: Drop moves the window *silently*; the overview stays open.**
  Establishes a clean two-verb grammar learnable in one use:
  **drag = organize, click = navigate.** Criterion 2 already assigns click the
  meaning "focus that workspace and close", which frees drop to mean something
  else. A silent move (not a focus-following move) is required because the user
  is still looking at the grid — the compositor's focused workspace must not
  jump. Matches GNOME's overview and Mission Control.
  Rejected close-and-go-there and close-and-stay-put: both make moving three
  windows cost three summons, and both give "how do I get out of here" two
  answers while giving "how do I do several moves" none.
  Accepted cost: one extra keypress to dismiss when finished.

- **D-16-14: The hovered tile lights using D-26's existing lit-tile language;
  a missed drop cancels and animates home.**
  Criterion 3 makes the highlight mandatory, so this is treatment only. Border
  and fill shift to the accent role — the same language D-26 established for
  the quick-toggle grid and Phase 15 reused for the Wi-Fi/Bluetooth tiles, so
  the shell teaches one idiom instead of a second that exists only during
  drags. Dropping outside any tile cancels, snapshot animates back to origin,
  so a mis-aim costs nothing.
  Rejected a landing preview (**the predicted position is a guess — Hyprland's
  tiling decides the real layout on arrival, so a wrong preview misleads worse
  than none** — and it is the heaviest thing to render mid-drag) and glowing
  all valid targets (eleven glowing rectangles on every drag, against this
  project's established restraint — peak meters declined in D-15-13, sparklines
  in D-36).

### Keyboard model

- **D-16-15: Full keyboard navigation. USER OVERRODE the recommendation**
  (which was Esc + number keys only, justified on it being the smallest
  addition with no new rendered state). **Third recorded override in this
  project's history**, after Phase 14's D-31 (the units field) and Phase 15's
  D-15-11 (full input symmetry).
  **Recorded as a deliberate scope widening so verification does not read it as
  drift:** the criteria require only a keybind to open, mouse click to focus,
  and mouse drag to move — everything past Esc-to-dismiss is capability beyond
  their literal text, added on purpose.
  **HARD BOUNDARY: keyboard navigation must NOT drift into type-to-search.**
  `REQUIREMENTS.md:100` excludes OVER-05 from v3.0 specifically to avoid a
  second "type to find a thing" surface competing with walker. Arrows and
  modifiers only — no text field, no filter, no search input.

- **D-16-16: Two-level selection — tiles, then windows within a tile.**
  Arrows move between the 11 tiles; Enter (or Down) drops "into" a tile that
  has windows; arrows then move between that tile's windows; Enter focuses the
  selected window; `Shift+1..0` moves the selected window to that workspace.
  **Esc becomes two-stage** — first press backs out of window selection, second
  dismisses — reusing D-15-14's precedent verbatim (the Wi-Fi password row made
  Esc two-stage for the same structural reason).
  Window-level selection is what makes `Shift+number` mean anything; tile-level
  alone cannot move a window you can see unless it happens to be the active one.
  D-16-01's fixed grid makes tile-level arrow movement completely predictable.
  Rejected one flat 2D field of windows (elegant given D-16-02's real
  positions, but crossing tile boundaries gets ambiguous when layouts differ,
  and selecting an *empty* workspace to move a window into has no window to
  land on) and tiles-only (removes most of the reason to have keyboard moves).
  Accepted cost: two selection states plus a mode indicator that must be
  readable at a glance.

- **D-16-17: PRE-AGREED FALLBACK, authorized at decision time — if the render
  gate finds the mode indicator cluttered or the two levels confusing in the
  hand, fall back to Esc + number keys (focus a workspace and close) WITHOUT a
  new decision.**
  Same shape as D-15-11's pre-agreed fallback, which 15-CONTEXT.md names as
  "the pattern to repeat". Under the fallback, keyboard *moves* are lost;
  keyboard navigation to a workspace survives. The risk being hedged is
  concrete: Phase 14's render gate already once rejected a design for not
  making its controls self-explanatory (forcing "DND" → "Do Not Disturb" and
  tooltips on all six controls).

### Entry, exit & window clicks

- **D-16-18: `Super+O` summons the overview; re-press toggles it closed.**
  Obeys **D-09's first-letter mnemonic**, the convention D-15-04 went out of
  its way to honour (binding `Super+A` for Audio and *documenting* the other
  two panels' asymmetry rather than minting inconsistent chords). Sits
  consistently beside `Super+D` (Dashboard) and `Super+A` (Audio). `O` is
  confirmed free — free plain-Super letters on this host are now
  **G, H, J, K, M, O, U** (A was taken by Phase 15).
  Rejected `Super+Tab` (most discoverable, but breaks D-09 for the third QML
  surface running, and Tab implies cycling, which this grid does not do) and
  `` Super+` `` (hyprexpo's own default, but also breaks D-09 and is an awkward
  far-corner reach for a constantly-opened surface).
  **Inherited constraint regardless of choice — Phase 11 Finding 1:**
  `GlobalShortcut` registration does not hot-reload; a quickshell process
  restart is needed before the chord works. Cost is proven, not estimated: one
  `shortcuts.json` entry + one `keybinds.lua` line + a `keybind-doctor` re-run
  (11-05 and Phase 15 both walked this path).

- **D-16-19: The overview is EXEMPT from DASH-08's fullscreen refusal guard —
  and the exemption requires one documented sentence.**
  The drawer and all three panels silently refuse to open over a fullscreen or
  maximized client (D-11). The overview does not, on a principled distinction:
  **the drawer and panels are informational/control surfaces where popping over
  a game is an interruption; the overview is a navigation surface, and
  navigation is what is needed most while trapped in a fullscreen app.**
  Decisive argument: `Super+2` already works while fullscreen. Blocking
  `Super+O` while allowing `Super+2` would be incoherent — both mean "take me
  somewhere else" — and would block the escape hatch while leaving the fire
  exit open.
  The exemption is documented in one sentence exactly as D-15-04's keybind
  asymmetry was, so it reads as a decision rather than an oversight.
  Acknowledged counter-argument, answered rather than dismissed: fullscreen
  game + full-screen blurred overview + live captures is the worst performance
  moment this phase can produce. **That is an argument for measuring under that
  condition (fold it into D-16-08's measurement), not for making the surface
  unreachable.** Rejected degrade-while-fullscreen (a conditional path that
  only fires in a state awkward to reproduce and easy to leave untested).

- **D-16-20: Clicking a window thumbnail focuses that window and its
  workspace; clicking a tile's empty area focuses the workspace. Both close.**
  Exact parity with D-16-16's keyboard model — Enter on a selected window does
  what clicking it does — so nothing must be learned or tested twice.
  Rejected treating the whole tile as one target (criterion 2 read literally,
  smallest to build, but the mouse would then do strictly *less* than the
  keyboard, backwards on a surface whose premise is pointing at windows).
  **Hover-× to close windows was raised and explicitly deferred** — see
  Deferred Ideas.

- **D-16-21: `Super+O` is the only entry point.**
  Rejected a dashboard quick-toggle tile on concrete cost: **D-15-21
  deliberately solved the grid's fit problem by making it one row of six
  compact tiles (~125px each)** to avoid vertical growth and leave D-05's
  height slack untouched; a seventh tile re-opens that arithmetic (~118px
  each). There is also a mechanical awkwardness — focus-grab exclusivity means
  summoning the overview from the drawer *destroys* the drawer first, a
  two-animation handoff replacing one keypress.
  Rejected a waybar entry: the workspaces module's click already means "go to
  workspace N", so repurposing breaks a working verb, and a separate button
  costs four waybar configs plus `modules.jsonc` and re-opens
  `waybar-equivalence-check` and `waybar-design-lint` — the price D-15-05 paid
  to fix a *genuinely dead* click, spent here to duplicate a one-key summon.
  Both alternatives recorded as deferred, not discarded.

- **D-16-22: Criterion 5 is discharged by a dated running note spanning 3+
  calendar days, opened with one structured pass.**
  The first entry deliberately exercises drag, the keyboard model, opening over
  a fullscreen client, and thumbnails under a heavy window count. After that it
  is appended with whatever is noticed in ordinary use, with dates. Closure
  requires entries spanning at least three calendar days — **mechanically
  checkable rather than a judgement call**.
  **Scheduling consequence, stated plainly: this phase cannot close on the day
  it is built.** Every other phase in this milestone closed on a render gate
  plus UAT in one sitting; this one deliberately cannot, and Phase 17 (the
  milestone's designated cut candidate) sits behind it.
  Rejected a checklist run on two days (**a test protocol is precisely the
  "click-and-look" the criterion is written against** — running the same
  checklist twice will not surface irritations that only appear when not being
  looked for) and a free-form note (indistinguishable from a same-day sign-off,
  making criterion 5 unfalsifiable).

### Gate coverage & motion

- **D-16-23: `quickshell-doctor` gains namespace + keybind + permission +
  capture checks, with a poisoned fixture.**
  Continues D-15-25's pattern and the house rule that *a gate must be proven
  able to fail before it is trusted to pass*. New checks:
  1. `quickshell-overview` conforms to the `quickshell-*` prefix at the right
     layer level with no second claimant.
  2. `Super+O` registers exactly once (via `keybind-doctor`).
  3. Reserved-array summon-and-diff — `hyprctl monitors -j`'s `reserved` array
     byte-identical before/during/after, reusing Phase 11's mechanism.
  4. **`hyprctl getoption ecosystem:enforce_permissions` reports true at
     runtime** — guards D-16-09 against silent revert, since the setting is
     read once at compositor startup and its failure mode is silence.
  5. **Every allow-listed screencopy binary path still resolves on disk** — a
     package update moving `grim` or the portal binary breaks screenshots under
     enforcement with no warning until a key is pressed.
  6. **An `overview` IPC verb reporting how many tiles have content**, so the
     blank-tile failure is machine-detectable rather than dependent on someone
     noticing. Reuses the existing `panel` `IpcHandler` pattern in `shell.qml`
     — one handler, one function.
  **Honest caveat on falsifying check 6:** the natural poison (removing
  quickshell from the allow list) needs a Hyprland restart. The practical
  falsification is running it while the overview is *not* summoned and
  confirming it reports zero and fails.
  Rejected matching Phase 15's scope exactly — it would leave the permission
  silent-revert and the blank-tile failure, the two risks this phase
  specifically owns, unguarded.

- **D-16-24: Entrance cascades by ROW, not by tile — three steps, ~380ms —
  with a `fade` layerrule rather than the panels' `slide`.**
  Row 1, then row 2, then the scratchpad tile. **Arithmetic is decisive:** at
  D-21's 30–50ms stagger, cascading all 11 tiles individually costs 330–550ms
  of offset *plus* each tile's own ~300ms animation, so the last tile finishes
  between ~630ms and ~850ms — straddling D-21's 700ms fence rather than
  clearing it. Row-level lands at ~380ms with margin.
  **Second, phase-specific argument:** the entrance runs at precisely the
  moment 11 live captures are all initialising — the frame-budget spike
  D-16-08 sets a floor against. Less animation at that instant is strictly
  better.
  **Reuses D-21's existing stagger token**, so `motion.json` does not grow and
  Phase 12's D-25 semantic-layer growth policy stays shut — the same discipline
  D-15-08 applied.
  `fade` rather than `slide` because **a surface covering the whole screen has
  no edge to slide in from**; the panels' and drawer's `slide` rules do not
  transfer. A new per-namespace `hl.layer_rule` for `quickshell-overview` is
  needed in `windowrules.lua`.
  Rejected the full 11-tile cascade (most satisfying, but only fits the fence
  at the bottom of the stagger range and is heaviest at the worst moment) and
  no cascade at all (cheapest and zero fence risk, but the milestone's most
  prominent new surface would carry the least motion in the shell, reading as
  unfinished beside the drawer).

### Inherited constraints (recorded, not decided)

- **QS-03 — no per-screen fan-out.** Permanent limitation on quickshell
  0.3.0-2 (PROJECT.md, D-13, one-way). Discharged by D-16-04's design, not
  solved.
- **Phase 11 Finding 1 — `GlobalShortcut` registration does not hot-reload.**
  `Super+O` needs a quickshell process restart to register.
- **Phase 11 Finding 2 — `HyprlandFocusGrab` is exclusive per-compositor.**
  Summoning the overview implicitly clears any other quickshell surface's grab,
  tearing down its LazyLoader. The drawer and panels cannot coexist with it on
  screen; this is platform behaviour, not policy (see D-15-02).
- **D-43 layer posture (locked by roadmap + Phase 11):** overlay layer,
  `exclusiveZone: 0`, `WlrKeyboardFocus.OnDemand` baseline,
  `quickshell-<surface>` namespace so the family-wide `^quickshell-.*`
  blur / `ignore_alpha` layerrules apply without new rules.
  **⚠ D-16-16 may force a deviation here — see Open Research Items #1.**
- **D-14 lifecycle:** `LazyLoader` destroy-on-dismiss — the `wl_surface` is
  destroyed, not hidden, so `hyprctl layers -j` goes empty on every dismissal
  path. All screencopy capture must stop on dismiss (zero-idle doctrine,
  D-32/D-36).
- **D-10 dismissal set:** Esc, click-outside, re-press the summon chord.
  **D-15-20:** dismissing always returns to the desktop, never to another
  quickshell surface.
- **Zero hex/duration literals** in repo-authored QML; everything through
  `~/.local/state/theme/` via the `Design`/`Colours`/`Motion` singletons.
  `motion-lint` is in scope for this surface.
- **Standing constraint 1 (human render-and-look gate)** applies to every
  visual plan in this phase — the roadmap flags this phase **UI hint: yes**.
- **Standing constraint 2 (verify options against the installed binary)**
  applies to the focus-posture question, Qt `Drag`/`DropArea` on a layer-shell
  surface, and the `ScreencopyView` property behaviours.
- **Standing constraint 3 (same-commit stow registration)** — no new stow
  package is expected; this extends the existing `quickshell/` package.
- **Standing constraint 4 (additive-only coexistence)** — check layer
  namespaces, `Super+O`'s chord uniqueness, and that no
  `org.freedesktop.Notifications` second claimant appears while summoned.

### Claude's Discretion

- Empty-tile styling — settled by D-41's existing vocabulary (quiet Material
  Symbol + the workspace number, no invented chrome); exact glyph and
  weighting are discretion.
- Workspace number typography and placement, tile corner radius, gap sizes,
  the monitor badge's design when >1 display is connected, and the hint line's
  copy (or omitting it).
- The mode indicator's visual treatment for D-16-16's two-level selection
  (subject to D-16-17's fallback if the render gate objects).
- Exact scale-up factor and shadow treatment on D-16-12's dragged snapshot,
  and the cancel-animation curve.
- How the fps/CPU measurement is instrumented for D-16-08 (research's call).
- Material Symbol picks throughout; tooltip copy.
- Plan/wave decomposition and sequencing; granularity is `coarse` in
  `.planning/config.json`. Building the grid and capture layer before drag and
  keyboard is the obvious ordering but is not mandated here.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and standing rules
- `.planning/ROADMAP.md` §"Phase 16: Workspace Overview" — the five success
  criteria, the "Owns" clause (live multi-window screencopy performance +
  silently-denied permissions rendering blank tiles), UI hint flag
- `.planning/ROADMAP.md` §"Standing constraints (apply to every v3.0 phase)" —
  constraint 1 (human render gate), constraint 2 (verify against the installed
  binary), constraint 3 (same-commit stow registration), constraint 4
  (additive-only coexistence and the named collision checklist)
- `.planning/ROADMAP.md` §"Phase 11" criterion 5 and its amendment — records
  that the screencopy *mechanism* is verified fact and that **Phase 16 owns the
  live-enforcement proof**
- `.planning/REQUIREMENTS.md` OVER-01..04 (lines 62-65), §Traceability
  (lines 162-165), the OVER-04 placement note (line 193), and **line 100 —
  OVER-05 type-to-search is explicitly out of scope for v3.0** (D-16-15's
  hard boundary)
- `.planning/PROJECT.md` §"Out of Scope" — the QS-03 entry, which states the
  consequence this phase must discharge

### Prior phase context that carries forward
- `.planning/phases/15-audio-connectivity-panels/15-CONTEXT.md` — the
  standalone-surface lifecycle this phase inherits (D-15-02), D-15-09's
  four-state widget vocabulary (used by D-16-10), D-15-14's two-stage Esc
  precedent (used by D-16-16), D-15-20 (dismissal returns to desktop),
  D-15-21's six-across grid arithmetic (why D-16-21 adds no tile), D-15-25's
  doctor-extension pattern (extended by D-16-23), D-15-11's pre-agreed-fallback
  pattern (repeated by D-16-17), and the standing user lens + questioning-depth
  instruction
- `.planning/phases/14-dashboard-drawer/14-CONTEXT.md` — D-09 (first-letter
  keybind mnemonic, used by D-16-18), D-10 (dismissal set), D-11/DASH-08
  (fullscreen refusal guard — **exempted here by D-16-19**), D-14
  (destroy-on-dismiss), D-20/D-21 (layer motion + the 700ms cascade fence used
  by D-16-24), D-26 (lit-tile naming/colour convention used by D-16-14), D-28
  (Material Symbols), D-41 (widget-state vocabulary), D-42/D-43 (namespace and
  layer posture)
- `.planning/phases/12-unified-design-token-pipeline/12-CONTEXT.md` — D-13
  (QS-03 accepted as permanent — the constraint D-16-04 discharges), D-25
  (semantic layer growth policy, which D-16-24 avoids triggering), D-18 (no
  quickshell step in the reload fan-out)
- `.planning/phases/12-unified-design-token-pipeline/12-QS03-EVIDENCE.md` —
  the live evidence behind D-13; read before entertaining any per-screen
  fan-out idea
- `.planning/phases/11-quickshell-viability-gate/11-QUICKSHELL-EVIDENCE.md` —
  **§"Criterion 5 — screencopy feasibility" (lines ~831-937) is the single most
  important upstream section for this phase.** Contains: the human-attested
  four-window live capture result; the binary-verified permission mechanism
  (`ecosystem:enforce_permissions`, the `screencopy`/`allow` strings, the
  restart-not-reload requirement); the full consumer-identification table;
  the explicit statement that **no frame-rate, CPU or memory measurement was
  ever taken** (OVER-04's job); and the recorded reason live enforcement was
  not tested. Also Finding 1 (GlobalShortcut restart-to-register) and Finding 2
  (`HyprlandFocusGrab` per-compositor exclusivity, verified in both orders)
- `.planning/phases/13-motion-retrofit-existing-surface-sweep/13-CONTEXT.md` —
  D-06/D-07 (layer motion split, per-namespace style-only overrides — the
  mechanism D-16-06's fallback and D-16-24's `fade` rule both use)

### Code this phase builds on (verified during this discussion)
- `quickshell/.config/quickshell/shell.qml` — the shell root. A new
  `LazyLoader` + `GlobalShortcut` mount here beside `dashboardLoader` and the
  three panel loaders. **Lines 315-347: the `panel` `IpcHandler` pattern
  D-16-23's capture-check verb copies.** Lines 289-303: the `fullscreenBlocking`
  guard the overview is exempt from (D-16-19). Lines 349-398: the
  `GlobalShortcut` declarations `Super+O` joins
- `quickshell/.config/quickshell/modules/ScreencopyProbe.qml` — **the direct
  ancestor of this phase's surface.** Already demonstrates `ToplevelManager`
  + `Repeater` + `ScreencopyView { captureSource: modelData; live: true }`,
  and the D-43 layer posture. Deliberately unstyled and carries no timing
  instrumentation (D-12 forbade pulling OVER-04 forward)
- `quickshell/.config/quickshell/modules/Dashboard.qml` — lines ~200-215: the
  layer posture and `exclusionMode` the overview adapts; the
  `HyprlandFocusGrab` block; the `Design`-derived spacing/type constants
  pattern
- `quickshell/.config/quickshell/modules/dashboard/PanelDialog.qml` +
  `GradientBorder.qml` + `Cascade.qml` — the shared frame, animated rim and
  cascade machinery; `Cascade.qml` is what D-16-24's row-level stagger uses
- `quickshell/.config/quickshell/modules/dashboard/Design.qml` +
  `modules/Colours.qml` + `modules/Motion.qml` + both `qmldir` files — the
  token singletons every widget consumes. Note the 12-06 finding:
  `pragma Singleton` + the `qmldir singleton` keyword are **both** required
- `quickshell/.config/quickshell/modules/dashboard/QuickToggles.qml` — D-26's
  lit-tile treatment that D-16-14's drop highlight reuses
- `quickshell/.config/quickshell/shortcuts.json` — the declared-manifest
  pattern; `Super+O` becomes the **fifth** entry
- `hypr/.config/hypr/config/keybinds.lua` — `Super+O` lands here. Lua
  multi-modifier `' + '` joining convention (13.1 finding). 80 bind
  declarations; `Super+1..0` at lines 215-224 and `Super+Shift+1..0` at
  227-236 are the binds D-16-03's grid mirrors and D-16-16's `Shift+number`
  echoes; `Super+S` / `Super+Shift+S` (lines 239-240) are the scratchpad binds
  D-16-05 complements
- `hypr/.config/hypr/config/windowrules.lua` — lines 303-321 (per-namespace
  `animation` rules) and 357-358 / 409-410 (the `^quickshell-.*` blur and
  `ignore_alpha` family rules). A new `quickshell-overview` `fade` rule lands
  here (D-16-24), and D-16-06's fallback lever is a blur override here
- `hypr/.config/hypr/config/permissions.lua` — **D-16-09 flips
  `enforce_permissions` to `true` here (single value, line ~76).** Read the
  file's own "WHAT IS AND ISN'T VERIFIED" block before touching it; it names
  the `gpu-screen-recorder` unconfirmed consumer explicitly
- `hypr/.config/hypr/scripts/quickshell-doctor` — D-16-23 extends this
  (13 checks today; includes the reserved-space summon-and-diff being reused)
- `hypr/.config/hypr/scripts/keybind-doctor` — re-run after `Super+O`
  (14 checks today)

### Installed API surface (verified directly this discussion — do not re-derive)
- **`Quickshell.Hyprland` — the entire data model this phase needs is native.**
  From `/usr/lib/qt6/qml/Quickshell/Hyprland/_Ipc/quickshell-hyprland-ipc.qmltypes`:
  - `Hyprland` singleton — `focusedMonitor`, `focusedWorkspace`,
    `activeToplevel`, `monitors`, `workspaces`, `toplevels`, `dispatch()`,
    `monitorFor()`, `refreshMonitors()`, `refreshWorkspaces()`,
    `refreshToplevels()`, `usingLua`
  - `HyprlandWorkspace` — `id`, `name`, `active`, `focused`, `urgent`,
    `hasFullscreen`, `lastIpcObject`, `monitor`, **`toplevels`
    (UntypedObjectModel)**, **`activate()`**
  - `HyprlandToplevel` — `address`, **`wayland`** (the
    `qs::wayland::toplevel_management::Toplevel` that `ScreencopyView.captureSource`
    accepts), `title`, `activated`, `urgent`, **`lastIpcObject`** (carries
    `at`/`size` for D-16-02), **`workspace`**, **`monitor`**
  - `HyprlandMonitor` — `id`, `name`, `description`, `x`, `y`, `width`,
    `height`, `scale`, `lastIpcObject`, `activeWorkspace`, `focused`
  **No IPC text parsing is needed** — workspace→windows, window→workspace and
  window→monitor are all native properties.
- **`Quickshell.Wayland.ScreencopyView`** — `captureSource` (QObject),
  `paintCursor`, **`live`**, **`hasContent`** (D-16-10's blank detector),
  `sourceSize`, `constraintSize`, **`captureFrame()`** (D-16-07 ladder step 3,
  D-16-12's drag snapshot)
- **`Quickshell.Wayland.Toplevel`** — `appId`, `title`, `parent`, `activated`,
  `screens`, `maximized`, `minimized`, `fullscreen`, `activate()`, `close()`,
  `fullscreenOn()`, `setRectangle()`, `unsetRectangle()`
- **Host state:** one monitor, `DP-1`, 2560×1440 @ 164.999Hz, scale 1.0.
- **Free plain-Super letters:** G, H, J, K, M, O, U (A taken by Phase 15's
  audio panel). `Tab` and `` ` `` are also unbound.
- `quickshell/.config/quickshell/shortcuts.json` currently holds four entries:
  `probe`, `screencopy-probe`, `dashboard`, `audio-panel`.

### External references (the user's standing lens)
- **end-4/dots-hyprland and Caelestia shell** — the taste baseline for
  design-discretion calls. Researcher should source-check their current
  Quickshell overview implementations specifically for: workspace-tile
  composition and scaling maths, drag-between-workspaces handling if present,
  keyboard navigation models, and how they treat empty workspaces.
  **Note the recorded divergence:** D-16-05 deliberately departs from both
  (and from hyprexpo) on the scratchpad tile, because criterion 1's literal
  wording outranks the lens.
- **hyprexpo** — Hyprland's own first-party overview plugin. Useful as a
  behaviour and layout reference (fixed grid, click-to-switch, `SUPER, grave`
  default chord) even though this phase deliberately does **not** use it —
  the roadmap settled on native `ScreencopyView` +
  `hyprland-toplevel-export-v1`, no plugin, no `hyprpm`.

</canonical_refs>

<code_context>
## Existing Code Insights

### Verified facts (checked during this discussion — do not re-derive)
- `HyprlandWorkspace.toplevels` and `HyprlandToplevel.workspace` are native
  properties — the workspace↔window mapping needs no `hyprctl` parsing.
- `HyprlandToplevel.wayland` is exactly the object type
  `ScreencopyView.captureSource` accepts, so the Hyprland-side model and the
  capture-side model connect directly.
- `ScreencopyView.hasContent` exists — blank/denied capture is detectable
  programmatically, which is what makes D-16-10 and D-16-23's check 6 possible.
- `hypr/.config/hypr/config/permissions.lua` ships with
  `enforce_permissions = false` and four `hl.permission(...)` grants
  (`/usr/bin/quickshell`, `/usr/bin/grim`, `/usr/bin/hyprpicker`,
  `/usr/lib/xdg-desktop-portal-hyprland`), each an exact absolute path with no
  wildcard (T-11-20 discipline). Grants are read once at compositor startup;
  `hyprctl reload` does **not** apply changes.
- `shell.qml` already carries an `IpcHandler` (`target: "panel"`, verbs
  `open`/`toggle`) — the exact pattern D-16-23's capture-check verb copies.
- The `^quickshell-.*` blur and `ignore_alpha: 0.5` layerrules already exist
  and will cover `quickshell-overview` automatically on naming alone; the
  per-namespace `animation` rules are declared individually per surface.
- Host has one monitor (`DP-1`, 2560×1440 @165Hz), so the multi-monitor paths
  in D-16-04 are unexercised in daily use — same situation Phase 12 recorded
  for QS-03.

### Reusable Assets
- `ScreencopyProbe.qml` — the working `ToplevelManager` → `Repeater` →
  `ScreencopyView` pattern, already proven to render real content on this
  build. The overview is essentially this, grouped by workspace and styled.
- `Dashboard.qml`'s `PanelWindow` + `WlrLayershell` + `HyprlandFocusGrab`
  block — the surface skeleton.
- `Cascade.qml` — D-16-24's row-level entrance stagger.
- `GradientBorder.qml` — DASH-10's animated rim, if the overview wants family
  kinship at its edges (discretion).
- `QuickToggles.qml`'s D-26 lit-tile treatment — D-16-14's drop highlight.
- `Design`/`Colours`/`Motion` singletons — all tokens.
- `quickshell-doctor`'s before/during/after summon-and-diff — reused by
  D-16-23's check 3.
- `shell.qml`'s `IpcHandler` block — reused by D-16-23's check 6.

### Established Patterns
- Zero hex/duration literals in repo-authored UI; `motion-lint` enforces and
  the overview's QML is in scope.
- A gate must be proven able to fail before it is trusted to pass — D-16-23's
  poisoned fixture continues this.
- Human render-and-look gates per visual plan (standing constraint 1); this
  phase is flagged **UI hint: yes**.
- Zero idle footprint — nothing runs while the surface is dismissed
  (D-32/D-36). All screencopy capture must stop on `LazyLoader` deactivation.
- Present-but-disabled for controls that exist but cannot act (D-41).
- Verify against the installed binary, never the documentation (standing
  constraint 2) — this repo has been bitten repeatedly otherwise.

### Integration Points
- `shell.qml` ← one new `LazyLoader` + `GlobalShortcut` + the `overview`
  `IpcHandler` verb
- `shortcuts.json` + `keybinds.lua` ← `Super+O` (fifth manifest entry;
  `keybind-doctor` re-run after)
- `windowrules.lua` ← a `quickshell-overview` `fade` layerrule (D-16-24), and
  the blur-override site for D-16-06's fallback lever
- `permissions.lua` ← `enforce_permissions = true` (D-16-09)
- `quickshell-doctor` ← D-16-23's six new checks + fixture
- New QML module(s) under
  `quickshell/.config/quickshell/modules/` (and/or a new
  `modules/overview/` directory with its own `qmldir`)

</code_context>

<specifics>
## Specific Ideas

- **The grid mirrors the keyboard.** D-16-03's 5×2 arrangement was chosen
  specifically because `1 2 3 4 5` over `6 7 8 9 0` matches the number row —
  making D-16-01's spatial constancy self-teaching, and directly enabling
  D-16-16's `Shift+1..0` window moves. Downstream agents should preserve this
  mapping as load-bearing, not incidental.
- **"Drag organizes, click navigates."** D-16-13's two-verb grammar is the
  phrase to design against; every interaction decision should be checkable
  against it.
- **The user asked for plain-language explanations when a question got
  jargon-heavy.** During this discussion the phrase "frame and CPU budget" was
  misread as agent token budget, and the question had to be re-asked in plain
  terms. Downstream agents presenting checkpoints or render gates should lead
  with what the user will *see or feel*, and put mechanism second.
- **The user overrode a recommendation once** (D-16-15, full keyboard
  navigation) and accepted a pre-agreed fallback for it (D-16-17), continuing
  the D-15-11 pattern. Recording user-authorized fallbacks alongside overrides
  remains the pattern to repeat.

</specifics>

<deferred>
## Deferred Ideas

- **OVER-05 — type-to-search-and-jump inside the overview.** Explicitly
  excluded from v3.0 in `REQUIREMENTS.md:100` to avoid a second "type to find a
  thing" surface competing with walker. **D-16-15's keyboard navigation must
  not drift into this** — arrows and modifiers only, no text field.
- **Hover-× to close windows from the overview** (the GNOME behaviour). Raised
  during D-16-20 and deferred: closing windows is a new capability no criterion
  asks for, arriving in the phase whose named open risk is performance, and
  hover chrome over live captures costs render work of its own.
- **A dashboard quick-toggle tile for the overview** — declined by D-16-21;
  would re-open D-15-21's settled six-across arithmetic and force a
  destroy-then-summon drawer handoff.
- **A waybar button or workspaces-module route to the overview** — declined by
  D-16-21; the workspaces click already means "go to workspace N", and a new
  button costs four configs plus two lint gates to duplicate a one-key summon.
  *(Related standing tech debt, not this phase's job: waybar 0.15.0's
  compiled-in workspace-click dispatch is dead until Quickshell replaces it —
  upstream PR #5013 postdates the release.)*
- **A runtime capture-mode toggle** (live / hover-only / snapshot) — declined
  by D-16-11 in favour of a baked build-time choice; revisit only if the
  OVER-04 measurement lands close enough to the floor that the machine is
  genuinely on the boundary under varying load.
- **Overlap-decluttering inside a tile** (nudging fully-occluded floating
  windows apart) — declined by D-16-02; would make positions no longer match
  reality.
- **A landing preview during drag** (snapping the dragged snapshot into its
  predicted position) — declined by D-16-14 because Hyprland's tiling decides
  the real layout on arrival, so a wrong preview misleads worse than none.
- **Per-screen overview instances** — blocked by QS-03, accepted as a permanent
  quickshell 0.3.0-2 limitation in Phase 12; not a deferral this phase can act
  on. D-16-04 discharges the obligation by design instead.

### Open research items (named during discussion — blocking for planning)

1. **Keyboard focus posture — `OnDemand` vs `Exclusive`. HIGHEST PRIORITY.**
   D-43's locked layer posture is `WlrKeyboardFocus.OnDemand`. Phase 11's QS-02
   gate proved a human can *type* on a layer-shell surface under `OnDemand`,
   but that was **after clicking into a field**. This surface is summoned by a
   keybind and D-16-16 needs arrow keys to work with **no click first**. If
   `OnDemand` cannot deliver that, the overview needs `Exclusive` — a deviation
   from an inherited posture that standing constraint 2 says must be verified
   against the installed binary, not assumed. Settle this before planning; it
   may also interact with `HyprlandFocusGrab`'s click-outside dismiss.
2. **Qt `Drag`/`DropArea` viability inside a Wayland layer-shell surface.**
   OVER-03 depends entirely on it. Phase 15 deliberately routed around QtQuick
   `Popup` (D-15-12/D-15-19) because it was unverified on this build; the same
   caution applies here, and there is no route around drag. If the declarative
   API misbehaves, the fallback is manual `MouseArea` + coordinate hit-testing
   against tile geometry — verify before planning commits to either.
3. **How the OVER-04 measurement is actually instrumented.** Needs a
   repeatable, non-interactive way to read the surface's frame rate and the
   quickshell process's CPU under a controlled window count. Whatever is
   chosen must be rerunnable so the verdict can be re-proven, not a one-off
   observation.
4. **`ScreencopyView` behaviour under load** — whether `live: true` captures
   throttle to window damage or run at monitor refresh; whether a minimized or
   occluded window still produces frames; and what `captureSource` does when
   its `Toplevel` is destroyed mid-drag.
5. **`gpu-screen-recorder` under live enforcement** (carried from Phase 11 as
   an explicitly unconfirmed consumer). `strings` shows no direct `screencopy`
   protocol reference; it likely uses KMS/DRM or the portal's ScreenCast path.
   **Confirm during D-16-09's proof** — if it breaks, `permissions.lua` needs a
   fifth grant.
6. **`hyprctl dispatch movetoworkspacesilent` semantics from
   `Hyprland.dispatch()`** — confirm the silent variant moves without
   following, and confirm the address-targeted form
   (`movetoworkspacesilent <ws>,address:0x...`) works for a window that is not
   currently focused, which D-16-13 requires.
7. **end-4/Caelestia overview source-check** — same discipline Phases 12, 14
   and 15 applied; see canonical refs for the specific things to look for.

</deferred>

---

*Phase: 16-workspace-overview*
*Context gathered: 2026-08-02*
