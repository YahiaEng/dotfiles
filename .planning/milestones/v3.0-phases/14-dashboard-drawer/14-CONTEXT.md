# Phase 14: Dashboard Drawer - Context

**Gathered:** 2026-07-29
**Status:** Ready for planning

<domain>
## Phase Boundary

The first real QML surface: a Super+D-summoned, four-tab (Dashboard / Media /
Performance / Weather) swipeable dashboard drawer mounted into the existing
Quickshell shell root, reading state the desktop already owns — MPRIS via
`media-status.sh`, swaync's toggle state, the motion-scale axis, system
resources from `/proc`+`/sys` — instead of forking any of it. It **owns** the
"overlay by default, zero exclusive zone" layer-shell convention, the
`quickshell-*` namespace scheme, the in-surface motion vocabulary, the
widget-state vocabulary (populated / pending / empty), and the shared-state
pattern that Phases 15 and 16 inherit.

Requirements: DASH-01..08. One net-new external dependency exists (the weather
service); everything else is a view over existing backends.

**User lens (standing, applies to all downstream design discretion):** when
trade-offs are close, follow the **end-4 (dots-hyprland) and Caelestia shell
conventions** — Material You / Android-quick-settings idioms, lit tonal tiles,
Material Symbols iconography, staggered entrances. Stated explicitly by the
user mid-discussion; recorded in auto-memory as `reference-shell-bias`.

**Deprecation principle (also user-stated):** swaync, walker, and wleave are
v4.0 migration targets — spend no engineering attention coordinating with them
beyond what falls out of drawer-internal mechanisms.

</domain>

<decisions>
## Implementation Decisions

43 decisions were captured across 8 areas. Every "(reference lens)" tag means
the end-4/Caelestia convention was the deciding factor.

### Geometry & placement

- **D-01: Top drop-down, horizontally centered.** The Caelestia dashboard
  shape. Entrance/exit axis (vertical) never collides with tab-swipe axis
  (horizontal).
- **D-02: Compact ~40% width (~850px), ~60% height (~860px), on the 2160x1440 primary.** Glanceable, reference-proportioned; single-column tab layouts
  minimize first-QML-surface design risk. Widening later is a token-level
  change.
- **D-03: Flush to the top edge, bottom corners rounded only.** The drawer
  anchors top and **respects other surfaces' reserved zones** — the compositor
  places it below waybar's reservation automatically, no per-layout offset
  logic. Known weak case: under the floating waybar layout it hovers with
  square top corners over a gap — accepted as-is; a later patch may read the
  waybar-layout state file and round all corners for that layout only
  (deferred). Optional Caelestia-style concave "inverse corner" melt where
  panel meets bar is deferred polish, addable without structural change.
- **D-04: Fixed height across all four tabs.** No mid-swipe height
  incoherence; blur region, silhouette, and click-outside hit zone never move.
  Degraded/empty states keep the frame and show designed placeholders — this
  IS the DASH-06 grace story.
- **D-05: No vertical scrolling anywhere — design-to-fit with ~10-15% vertical slack** (font-axis guard; render gate judges across themes/fonts).
  Nothing in the four tabs is unbounded (audited). Every drag therefore
  unambiguously means tab-swipe. Exemptions require a recorded reason
  (motion-lint exemption discipline); none of the four tabs qualifies.
  Phase 15's per-app mixer list is the expected first legitimate exemption.
- **D-06: MD3 comfortable spacing uniformly** (8dp grid: ~24px panel padding,
  ~16px card gaps). One density regime; Performance-tab fit pressure is solved
  by widget design at its render gate, never by a second density system.
- **D-07: House translucent surface over compositor blur** (`blur = true` +
  `ignore_alpha` layer rules, translucent token surface). Pre-agreed fallback
  if the Performance render gate flags readability: per-widget solid cards
  inside the translucent drawer.
- **D-08: No background scrim.** Undimmed desktop honestly advertises
  DASH-01's stays-interactive promise; blur solves drawer legibility locally;
  `hyprctl layers` stays clean.

### Summon, dismiss, focus

- **D-09: Super+D summons.** Free under all modifiers, repo's first-letter
  mnemonic convention. Mechanism = probe pattern: `GlobalShortcut` +
  `shortcuts.json` manifest entry + one Lua bind line. Known cost: new
  GlobalShortcuts need a Quickshell process restart to register (Phase 11
  finding).
- **D-10 — Dismissal set: Super+D toggles closed, Esc dismisses, click-outside dismisses** (probe's `onPressed: active = !active` pattern + walker/wleave
  Esc convention).
- **D-11: DASH-08 refusal is a silent no-op on TRUE fullscreen only; maximized windows (bar visible) do not block.** No notification on refusal —
  feedback over fullscreen is the disturbance DASH-08 prevents. Matches
  waybar's existing fullscreen-withdraw behavior.
- **D-12: Keyboard focus is grabbed on summon.** Arrows/Esc work with zero
  clicks; click-outside dismisses AND releases focus in one gesture, so focus
  can never be stuck. This is the model Phase 15's password inputs need.
  Whether OnDemand alone grants focus on map or a `HyprlandFocusGrab` is
  required is a **named research item** (note: FocusGrab is
  compositor-exclusive on this build — Phase 11 finding).
- **D-13: Coexistence = focus-loss dismiss only (deprecation principle applied).** The drawer auto-dismisses whenever anything else takes focus —
  a permanent, deprecated-blind rule written for the QML family (drawer vs
  Phase 15 panels). Zero edits to swaync/walker/wleave; the transient
  "CC already open + drawer summoned" visual overlap is tolerated for v3.0's
  lifetime. An optional `swaync-client -cp` one-liner on summon is recorded
  as available ONLY if the overlap annoys in practice (must not outlive
  swaync).
- **D-14 — Lifecycle: destroy on dismiss (probe LazyLoader pattern), with selected-tab memory and data backends living at the shell root.** Zero idle
  footprint, `hyprctl layers` empty when dismissed, warm data + last-tab
  reopen. Per-tab lazy content is the standard answer if summon latency needs
  trimming.

### Tabs & navigation

- **D-15 — Tab order: Dashboard, Media, Performance, Weather** (roadmap order;
  Media adjacent to the Dashboard tab's media widget deep-link; Weather — the
  lowest-frequency tab — at the far end). If end-pair traversal ever dominates
  real use, the fix is reordering tabs, not changing topology.
- **D-16: Header row at the top of the drawer** (bar → tabs → content chrome
  stack), **icon + label per tab** (MD3 primary-tabs idiom), active indicator
  tracks swipe progress.
- **D-17 — Swipe commit: ~1/3 distance OR quick flick** (framework-default
  pager physics — SwipeView-class), spring-back below threshold on motion
  tokens.
- **D-18: Arrow keys cycle tabs; CLAMPED at both ends** (arrows = keyboard
  swipes; one spatial model for both inputs; SwipeView's free physics — no
  PathView). Wraparound rejected (contradictory animation or hand-tuned
  circular physics on the first surface). **Consequence recorded: calendar
  months navigate by chevrons + scroll wheel, never bare arrows.**
- **D-19: Number keys 1-4 NOT bound** — deferred; add later only if arrow
  cycling measures slow.

### Motion (this phase defines the in-surface vocabulary)

- **D-20 — Open/close animation: per-namespace layerrule `slide`** (wleave
  fade-rule precedent); duration/curve come from the global token-driven
  `layersIn`/`layersOut` entries — structurally enforced by Hyprland (style-only
  overrides, Phase 13 verified fact).
- **D-21: Summon-only entrance cascade (reference lens).** After/overlapping
  the slide, the active tab's widgets fade+rise in read-order (~30-50ms
  offsets, each ~150-200ms, settled < 700ms, content legible mid-flight).
  Fences: NEVER fires on tab switches (the pager's own slide is the tab
  transition); collapses under `reduced`/`off` motion scales via existing
  `motionEnabled`/duration plumbing; the stagger offset becomes ONE new
  semantic token in `motion.json` (single-sourced — motion-lint enforces
  consumption). In-repo ancestor: wleave's gate-approved md3_decel cascade.
  — **Reversibility:** reversible — the motion-scale axis is the safety valve;
  `reduced` kills the stagger without redesign.
- **D-22: Truth-driven pending model for all async controls.** Press
  acknowledges instantly (MD3 ripple + pending pulse on motion tokens);
  committed state renders ONLY when the backing state actually changes (file
  watch / subscribe event). Chips disabled while pending (kills theme-apply
  spam). Drift between the dashboard and swaync's grid is structurally
  impossible; failed operations never display a false state. The pending
  affordance is the async convention Phase 15's wifi-connecting /
  bt-pairing states inherit. Pending pulse = named motion-token consumer.

### Quick-toggle grid (DASH-07)

- **D-23: The grid = 3 swaync-mirrored chips (Gaming, DND, Dark) + the motion-scale control.** The motion control is recorded as OUTSIDE the
  DASH-07 mirror-proof (no swaync counterpart — a one-way state-file view; one
  sentence in verification docs prevents it reading as an unexplained
  asymmetry). Rejected: waybar-visibility chip (backwards ergonomics; overlaps
  gaming mode's own bar-hiding side effect), any toggle needing a new backend
  (Phase-15-shaped vertical slices).
- **D-24: Motion-scale control is a full-width MD3 segmented row `Off | Reduced | Normal | Lively` under the 3 chips** — REVISES the earlier
  "cycle chip" framing: every transition costs a full multi-second
  `theme-apply`, so direct-jump (one press = exactly one re-render) beats any
  cycle, and it deletes the accidental-`off`-transit footgun. Also the
  aesthetic pick under the reference lens (Android-QS mixed tiles + axis
  control; meaningful asymmetry over disguised uniformity). Segment label
  abbreviations = render-gate discretion.
- **D-25: Uniform labeled chips** — icon + text, MD3 tonal, active = filled
  with primary. Divergence from swaync's icon-only glyphs is intentional
  (shared truth, medium-appropriate costume). Chip order mirrors swaync:
  Gaming, DND, Dark (identical position = identical meaning across grids).
- **D-26: Theme chip is named "Dark", lit tonal when dark mode is engaged (reference lens — Android-QS convention verbatim; resting-lit tiles are the Material You signature), AND swaync's config.json update-command flips its boolean direction (one line: light→dark echo true) so both grids agree in the DASH-07 side-by-side.** Flip the update-command and its icon/label
  TOGETHER or swaync lies in the other direction. The edited swaync grid gets
  re-judged free at the DASH-07 side-by-side gate.
  — **Reversibility:** reversible, but it re-opens a human-gated Phase 8
  surface — the one-line diff must be visible in review.
- **D-27 — The three mirrored toggles' backends (verified from config):**
  gaming = exec `gaming-mode-toggle.sh`, watch `~/.cache/gaming-mode`;
  DND = `swaync-client -dn/-df`, read via `swaync-client -D`, change-subscribe
  via `swaync-client --subscribe` (**named research-verify item** — the only
  daemon-state read path); dark = exec `theme-switch.sh`, watch
  `~/.local/state/theme/mode`.

### Iconography (QML-family decision)

- **D-28: Material Symbols Rounded is the QML family's icon system, starting with the drawer (reference lens — the end-4/Caelestia recipe).** Outlined →
  filled variants power the chip lit-state language; purpose-built
  weather/metric/signal/transport sets serve Phases 14-16. New font dependency
  in `install.sh` (hard-fail package-verify class; AUR
  `ttf-material-symbols-variable-git` or vendored file — researcher chooses).
  GTK family keeps Nerd Font; the two-icon-language state is
  transitional-intentional, resolved by v4.0's migration.
  — **Reversibility:** costly — the icon system threads through every widget
  of every QML surface from here on; swapping later re-opens all their render
  gates.

### Weather (DASH-06 — the only new external dependency)

- **D-29 — Provider: Open-Meteo.** Keyless + no registration (reproducibility
  is perfect: fresh install works the moment stow finishes; an API key would
  be uncommittable secret host-state). One JSON call returns current + hourly
  + daily; WMO codes map to Material Symbols. Data quality user-probed and
  accepted: it aggregates the national models (ECMWF/GFS/ICON auto-selected
  per location) — weakness is station-level current readings and alerts,
  neither in scope. **Fence: the fetch is isolated in one place so a provider
  swap stays a one-file change.**
- **D-30 — Location: a seeded state-file axis** (the theme/font/motion-scale
  idiom). Committed default is **CITY-LEVEL coordinates only** — the repo is
  public; precise home coords would be self-doxxing. `stow.sh` seeds it;
  refinements live in `~/.local/state/`, never git. GeoIP rejected (second
  wttr.in-class failure surface, VPN shows the exit node's weather with no
  cue, and a GeoIP seed inside install would poison the container gate with
  the datacenter's city).
- **D-31: Units live in the same state file, metric-seeded (USER OVERRODE the fixed-metric recommendation).** Consequences recorded: this is the
  pipeline's first multi-key state file (deliberate pattern deviation —
  validation must know it's intentional), and the QML formatting layer is
  unit-aware for temperature/wind/precipitation.
- **D-32 — Refresh: ~15-min TTL cache + fetch on summon only when stale**
  (render cached instantly, refresh in background; refresh timer runs only
  while the drawer is open; zero requests on days the drawer never opens —
  the zero-idle doctrine translated to networking). Last-good response
  persists to disk (survives daemon restart) and doubles as the DASH-06
  backbone.
- **D-33 — Degradation: calm stale-as-normal.** Stale renders identically to
  fresh + a quiet "updated Nh ago" badge (appears ~1h, warning tone ~6h —
  thresholds are tunable discretion), anchored at the current-conditions
  block (the fast-decaying element; the date-keyed forecast stays
  self-consistent indefinitely). Designed placeholder inside the intact frame
  ONLY when no cache has ever existed. The failure path is the daily path
  plus one label (anti gate-rot); fault-injectable by backdating the cache
  file's timestamp.

### Tab content

- **D-34 — Calendar: display-only month grid** (today highlighted, chevron
  month navigation per D-18's consequence) — exactly what end-4/Caelestia
  ship; pure QML date math, zero backend/state/deps. Events integration
  rejected (PIM slice: sync daemon + credentials = host-only state, no
  reference precedent, not in DASH-03). Todo widget = deferred idea.
- **D-35 — Media tab: Caelestia-style MD3 full player** — large cover art,
  type stack, seek slider (`position`/`length`/`can_seek`), Material Symbols
  transport, volume, player-switcher chips. Deliberate identity split from
  the garuda-style AGS card (ambient piece vs instrument — different dress
  justifies coexistence). **Two hard fences:** (1) NO
  `Quickshell.Services.Mpris` anywhere in the drawer — it would be the second
  media backend DASH-04 forbids; read the `media-status.sh` JSON stream (one
  object per line, the AGS card's contract) and act through
  `media-players.sh` / the established playerctl paths (the sanctioned
  MPRIS-writer discipline). (2) The tab designs to the EXISTING payload
  contract — no `media-status.sh` extensions this phase.
- **D-36: Performance tab: four MD3 circular dials (CPU, memory, storage, battery — the percent-of-capacity species, the Caelestia/end-4 resource look) + an honest network up/down rate row** (a rate is not a percentage —
  no fake normalization). Polling only while the drawer is open: ~1-2s for
  CPU/mem/network, ~30s for storage/battery (exact cadences = discretion).
  Pure `/proc`+`/sys` view — no new daemons; read mechanism (QML timer reads
  vs a small JSON-emitting helper in the `media-status.sh watch` shape) =
  researcher discretion. Light CPU smoothing (2-3 sample average) tuned at
  the render gate. Boundary: trends/history are btop's job — no sparkline
  creep later.
- **D-37 — Weather tab: the full Material stack** — current hero (large temp,
  condition, feels-like/humidity/wind, age badge) + **fixed 8-column** hour
  strip (fixed-width, NOT scrollable — a horizontally scrollable strip inside
  a horizontal pager is the worst available gesture collision) + 5-day row.
  One Open-Meteo call feeds all three bands; fills the fixed canvas.
- **D-38 — Dashboard tab: identity-first single column** — clock/date hero →
  calendar → compact media → resources strip → toggle block as footer (the
  full-width segmented row closes the composition as the tab's base line).
  Android's tiles-first shade order rejected (phone thumb ergonomics; the
  shell references lead with identity). Two-column rejected (solves a
  vertical problem the stack doesn't have; would cramp the segmented row).
- **D-39 — Resources strip: CPU / Memory / Battery mini-dials** — the three
  glance-timescale metrics as small versions of Performance's dials
  (cross-tab design rhyme); clicking jumps to the Performance tab. Storage
  and network stay Performance-only (no glance-rent).
- **D-40 — Compact media widget: art + title/artist + play-pause only; clicking anywhere else deep-links to the Media tab.** Play/pause is the one
  glance-frequency verb; skip/seek/volume live one keypress away. Together
  with D-39 this establishes the **compact-widget → its-full-tab deep-link
  convention**.
- **D-41 — Empty states: uniform in-place placeholders.** Every widget always
  occupies its slot; empty = quiet Material Symbol + one line, controls
  present-but-disabled (reference pattern: placeholder disc + dimmed
  controls). Positions never move as a function of system state. No first-run
  onboarding (audience of one; would need a hints-shown state file). This
  completes the widget-state vocabulary: **populated / pending / empty**,
  each with a defined look, inherited by Phase 15.

### Namespace & inheritance (the "Owns" clause made concrete)

- **D-42 — Namespace scheme: `quickshell-<surface>`, drawer = `quickshell-dashboard`.** The house treatment (blur + ignore_alpha) is
  written ONCE as a family-wide regex layerrule (`^quickshell-.*`) so Phases
  15/16 inherit it by following the naming scheme; per-surface character
  rules (the drawer's `slide`) layer on top as exact matches. **Regex
  namespace matching on `hl.layer_rule` for this build is a named research
  item** — the fallback (same scheme, per-surface exact rules) keeps every
  other benefit. A `quickshell-doctor` check asserting every QS layer
  namespace matches the prefix is noted as the drift guard.
  — **Reversibility:** costly — the namespace threads through layerrules,
  doctor checks, and DASH-01's `hyprctl layers` verification; renaming later
  touches all of them.
- **D-43 — Layer posture (locked by roadmap + Phase 11, restated):** overlay
  layer, zero exclusive zone on any edge waybar reserves,
  `WlrKeyboardFocus.OnDemand` baseline. `hyprctl layers -j` shows nothing
  drawer-related when dismissed (D-14's destroy semantics).

### Claude's Discretion

- Exact QML component choice for the pager (SwipeView-class expected; PathView
  explicitly NOT needed — wraparound rejected).
- Exact pixel values, corner radius token, chip/segment label abbreviations,
  Material Symbol picks per widget, DND chip's lit-direction glyph semantics.
- Weather fetch implementation (QML XMLHttpRequest vs helper script), cache
  file location/format, exact TTL, badge thresholds (~1h/~6h starting
  points).
- Performance read mechanism (QML file reads vs `media-status.sh watch`-shaped
  helper) and exact poll cadences.
- Stagger offset token name and exact cascade timings within D-21's fences.
- Arrow-cycling wraparound sub-behaviors (none — clamp is total), tab-memory
  persistence scope (session-level at shell root is sufficient; disk
  persistence not required).
- Plan/wave decomposition; granularity is `coarse` in `.planning/config.json`.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and standing rules
- `.planning/ROADMAP.md` §"Phase 14: Dashboard Drawer" — the five success
  criteria, the Owns clause (layer convention + shared-state pattern), UI
  hint flag
- `.planning/ROADMAP.md` §"Standing constraints (apply to every v3.0 phase)"
  — constraint 1 (human render gate — this phase has MANY visual gates),
  constraint 2 (verify against the installed binary — D-12's focus mechanics,
  D-42's regex matching, D-27's subscribe verb), constraint 3 (same-commit
  stow registration — the Material Symbols font and any new state seeds),
  constraint 4 (additive-only coexistence + the named collision checklist:
  layer namespaces, keybinds, MPRIS reader/writer discipline)
- `.planning/REQUIREMENTS.md` DASH-01..08 (lines 40-47) and §Traceability
- `.planning/PROJECT.md` §"Key Decisions" — the human-render-gate row, the
  additive-only row, the consolidated-theme-engine row

### Prior phase context that carries forward
- `.planning/phases/12-unified-design-token-pipeline/12-CONTEXT.md` — D-11
  (FileView/JsonAdapter live palette + the crossfade the drawer must not
  break; "Phase 14's drawer has scroll position and a selected tab" was the
  stated motivation), D-18 (NO quickshell step in the reload fan-out — do not
  add one for the drawer), D-21 (motion-scale preset table), D-25 (semantic
  layer growth policy — D-21's stagger token follows it)
- `.planning/phases/13-motion-retrofit-existing-surface-sweep/13-CONTEXT.md`
  — D-06/D-07 (layer motion split, per-namespace style-only overrides —
  verified fact table), the deferred "in-surface client-side motion for
  Phase 14" note this phase now fulfills
- `.planning/phases/11-quickshell-viability-gate/11-QUICKSHELL-EVIDENCE.md` —
  QS-02 gate results (OnDemand focus baseline), HyprlandFocusGrab
  compositor-exclusivity finding, GlobalShortcut restart-to-register finding
- STATE.md Accumulated Context — "XF86 duplicate-key handler determinism"
  unverified item: Phase 14 adds a global keybind, which is exactly where a
  bind-resolution conflict would surface; keybind-doctor covers collisions

### Code this phase builds on (verified during discussion)
- `quickshell/.config/quickshell/shell.qml` — the shell root the drawer
  mounts into (its own header comment says "Phase 14's dashboard drawer
  mounts into this same root"); the probe's LazyLoader summon/dismiss
  pattern, GlobalShortcut wiring
- `quickshell/.config/quickshell/shortcuts.json` — the declared-manifest
  pattern D-09 extends (third entry)
- `quickshell/.config/quickshell/modules/Colours.qml` + `Motion.qml` +
  `qmldir` — the token singletons every drawer widget consumes (note the
  12-06 finding: pragma Singleton + qmldir singleton keyword BOTH required;
  no property X beside property onX in one object)
- `hypr/.config/hypr/config/keybinds.lua` — Super+D bind lands here; the
  Lua multi-modifier ' + ' joining convention (13.1 finding)
- `hypr/.config/hypr/config/windowrules.lua` — layer rules live here
  (lines ~221-232 blur, ~301-345 ignore_alpha); D-42's regex baseline joins
  them; wleave's per-namespace animation rule at ~293 is D-20's precedent
- `hypr/.config/hypr/scripts/media-status.sh` — the media payload contract
  (header documents it: one JSON object per line; player, label, status,
  title, artist, album, art, position, length, volume, can_seek). D-35
  designs to exactly this.
- `hypr/.config/hypr/scripts/media-players.sh` — the sanctioned MPRIS
  mutator (list/active/select verbs); ALL drawer transport actions route
  through it or the established playerctl paths
- `swaync/.config/swaync/config.json` — the toggle grid (lines ~55-77):
  three actions with command + update-command pairs; D-26's one-line flip
  target; D-27's backend truth table source
- `hypr/.config/hypr/scripts/gaming-mode-toggle.sh` — the gaming toggle's
  mutator (now hyprctl-eval based post-13.1)
- `hypr/.config/hypr/scripts/motion-switch.sh` — the motion-scale
  one-entrypoint contract (line ~118) D-24's segmented row execs
- `theme-engine/.config/theme-engine/motion.json` — gains D-21's stagger
  semantic token (follow Phase 12 D-25's growth policy)
- `theme-engine/.config/theme-engine/contract.json` `engine_owned_files` —
  the weather location/units state file and weather cache register here
  (D-29/D-30's lifecycle; Phase 12 D-29's five-occurrence rsync-wipe bug
  class)
- `stow.sh` — seed-when-absent idiom for the weather state file (D-30);
  same-commit registration for anything new
- `install.sh` — Material Symbols font dependency (D-28), hard-fail
  package-verify section

### External references (the user's stated lens)
- end-4/dots-hyprland and Caelestia shell — the taste baseline for every
  design-discretion call: Material You idioms, resource dials, staggered
  entrances, top drop-down dashboard, Material Symbols. Researcher should
  source-check their current Quickshell implementations for component-level
  patterns (as Phase 12's research source-checked their motion tokens).
- Open-Meteo API docs (api.open-meteo.com) — forecast endpoint (current +
  hourly + daily in one call), geocoding endpoint (city name → coords, for
  any future picker), WMO weather codes.

</canonical_refs>

<code_context>
## Existing Code Insights

### Verified facts (checked during discussion — do not re-derive)
- Waybar positions: 3 of 4 layouts top, vertical layout left. swaync CC:
  top-right. Primary monitor 2160x1440@165.
- Every summoned surface already carries `blur = true` + `ignore_alpha`
  layer rules — translucent-over-blur is the established house treatment.
- swaync's theme toggle update-command reports true when mode = LIGHT —
  the boolean direction D-26 flips.
- Free plain-Super letters at discussion time: A, D, G, H, J, K, M, O, S, U
  (D = the pick).
- The media payload contract fields (see media-status.sh ref above) cover
  every widget D-35/D-40 need — no backend extension required.
- Open-Meteo: keyless, ~10k req/day non-commercial, model-aggregator
  (ECMWF/GFS/ICON auto-selected), current+hourly+daily in one call.

### Reusable Assets
- Probe's LazyLoader summon/dismiss + GlobalShortcut + shortcuts.json
  manifest — D-09/D-14 reuse wholesale.
- `Colours.qml`/`Motion.qml` singletons — every widget's color/motion source.
- `media-status.sh watch` line-stream + `media-players.sh` verbs — the whole
  media backend, unchanged.
- swaync toggle command/update-command pairs — the toggle backend truth
  table.
- `motion-switch.sh` preset mechanism — the segmented row's exec target.
- The state-axis idiom (single-value seeded state files + engine_owned_files
  + stow seed) — D-30 follows it; D-31 deviates deliberately (multi-key).
- wleave's entrance cascade — D-21's gate-approved ancestor.

### Established Patterns
- Zero hex/duration literals in repo-authored UI — everything through
  `~/.local/state/theme/` tokens; motion-lint enforces (drawer QML is in
  scope of its QML check).
- A gate must be proven able to fail before it is trusted to pass — D-33's
  cache-backdating fault injection continues it.
- Human render-and-look gates per visual plan (standing constraint 1) — this
  phase has the most visual surface of the milestone so far.
- One entrypoint per state axis; views never write rendered files.

### Integration Points
- `shell.qml` ← drawer mount (Probe-sibling pattern)
- `shortcuts.json` + `keybinds.lua` ← Super+D (keybind-doctor re-run after)
- `windowrules.lua` ← `^quickshell-.*` baseline rules + drawer slide rule
- `motion.json` ← stagger token; `contract.json` ← weather state/cache
  entries; `stow.sh` ← weather seed; `install.sh` ← Material Symbols font
- `swaync/config.json` ← D-26's one-line boolean flip
- `quickshell-doctor` ← prefix-compliance check (noted, not mandated this
  phase)

</code_context>

<specifics>
## Specific Ideas

- **"I have more bias towards our references (end4 - caelestia shell). Take
  this into consideration for every decision we encounter."** — the user's
  standing lens, stated mid-discussion, applied from D-24 onward and
  retroactively consistent with earlier picks. It reversed one decision
  (D-26: from "Light lit=light, don't touch swaync" to "Dark lit=dark + flip
  swaync") and decided D-28 (Material Symbols) and D-21 (cascade).
- **"Software that we will deprecate should not get much attention"** —
  reshaped D-13 from an auto-close-the-CC policy to the deprecated-blind
  focus-loss rule.
- The user asked for deep pros/cons + a recommendation on EVERY decision —
  and overrode a recommendation once (D-31, units field). Downstream agents
  should present trade-offs with the same depth at any checkpoint.
- Aesthetic tiebreakers matter to this user (D-24 was re-litigated purely on
  aesthetics and the reference lens settled it).

</specifics>

<deferred>
## Deferred Ideas

- **Todo widget on the Dashboard tab** (end-4's sidebar combo) — new state +
  CRUD; not in DASH-03's enumeration. A later phase or v4.0 sidebar work.
- **Calendar events integration** (khal/EDS) — rejected outright this phase
  (credentials = host-only state); revisit only if a synced calendar workflow
  ever exists on this machine.
- **Weather chip on the Dashboard tab** — would ease the Dashboard↔Weather
  end-distance; also a natural Phase 15+ polish item.
- **Number keys 1-4 direct tab jump** — only if arrow cycling measures slow.
- **Caelestia-style concave inverse-corner melt** where drawer meets bar —
  pure polish, structurally independent.
- **Floating-waybar-layout corner patch** (read the layout state file, round
  all corners under that layout only) — only if the D-03 wart annoys.
- **`swaync-client -cp` close-on-summon one-liner** — only if the D-13
  overlap wart annoys; must not outlive swaync.
- **media-status.sh payload extensions** (shuffle state, queue position) —
  explicitly fenced out of this phase by D-35.
- **Sparkline/trend views on Performance** — btop's job; fenced by D-36.
- **A graphical weather-location picker** (Open-Meteo geocoding + walker
  list) — the state file is hand-editable this phase; picker is polish.

### Open research items (named during discussion — blocking for planning)
1. **Focus mechanics (D-12):** does OnDemand grant keyboard focus on map, or
   does the drawer need `HyprlandFocusGrab`? (Grab is compositor-exclusive on
   this build — interaction with the probes must be recorded either way.)
   Also carries D-13's focus-loss-dismiss signal source.
2. **`swaync-client --subscribe` (D-27):** verify it emits DND state changes
   on this swaync 0.12.x build; else fall back to polling `-D` while the
   drawer is open.
3. **Regex namespace matching (D-42):** verify `hl.layer_rule` accepts a
   regex namespace match on Hyprland 0.56 Lua; fallback = per-surface exact
   rules under the same naming scheme.
4. **Material Symbols packaging (D-28):** pick AUR package vs vendored font;
   confirm variable-font axes (FILL) work in Qt/QML text rendering — the
   outlined→filled lit-state language depends on it.
5. **SwipeView-class component availability** in the installed Qt/Quickshell
   (D-17/D-18's free physics assumption).
6. **end-4/Caelestia source-check** for component-level drawer patterns
   (Phase 12's research source-checked their motion tokens; same discipline
   here).

</deferred>

---

*Phase: 14-dashboard-drawer*
*Context gathered: 2026-07-29*
