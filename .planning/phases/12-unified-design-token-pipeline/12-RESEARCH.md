# Phase 12: Unified Design-Token Pipeline - Research

**Researched:** 2026-07-26
**Domain:** Cross-toolkit design-token pipeline (colour + MD3 motion) spanning bash-based
matugen orchestration, Quickshell/QML, GTK4 CSS, and Hyprland's Lua-free `bezier=`/`animation=`
config DSL.
**Confidence:** HIGH for everything binary-verified on this machine this session (marked
`[VERIFIED]`); MEDIUM for primary-source-cited MD3 token data and Quickshell doc claims
(`[CITED]`); LOW only for the TOKEN-06 spring-physics constants, which are explicitly
tagged `[ASSUMED]` below.

## Summary

CONTEXT.md already locked 32 decisions with rationale. This research does not re-litigate
any of them — it fills the specific gaps CONTEXT.md's `<research_priorities>` flagged as
open, using the repo's own house rule (verify against the installed binary) wherever a
tool existed to do so, and clearly tags anything that had to come from web/primary-source
lookup instead.

Five findings materially change what the planner must write, beyond what CONTEXT.md
already recorded:

1. **Hyprland's `speed` unit is confirmed deciseconds, and `speed = 0` is a hard
   config-parse error** (`invalid speed`), not a silently-accepted degenerate value — this
   makes D-09's clamp-to-a-floor a *correctness* requirement (an unclamped low-scale motion
   value can crash Hyprland's config load, not just look bad), not only a perceptual one.
   Fractional deciseconds (`4.5`, `0.01`, `12.75`) all parse cleanly — no need to round.
2. **GTK4's `transition:` shorthand silently mis-parses when any value inside it uses
   `var(--x)`** on this exact GTK 4.22.4 build: every comma-separated item collapses into
   one raw string duplicated across all four longhand properties (`transition-property`,
   `-duration`, `-timing-function`, `-delay`), rather than being split positionally. The
   fix is to always use the four **longhand** `transition-*` properties with
   comma-aligned value lists when any item is token-driven — verified working cleanly.
   This directly affects D-19's wleave retrofit (`style.css:226-230`'s multi-property hover
   transition uses the shorthand today).
3. **`contract.json`'s existing `gtk-css`/`hypr-vars` format extractors will silently
   break `theme-parity` for the new motion files** if reused as-is: `gtk-css`'s extractor
   greps only for `@define-color`, which a `--motion-*:` custom-property file will never
   contain (zero matches → an empty reference name-set → `theme-parity` FAILs by its own
   design, "Refuse an empty reference name-set"). The Hyprland motion fragment (native
   `bezier =`/`animations {}` syntax) doesn't match the `hypr-vars` extractor's
   `^\$name = value` pattern either. D-03's claim that "no new format handler is needed"
   is true **only** for the QML/JSON target — the GTK4 and Hyprland motion targets need
   two new `contract.sh` format branches (concrete regexes provided below).
4. **Quickshell's directory-scanner race (FM1, the exact bug D-12 targets) is
   structurally closed by a checked-in `qmldir`** — not merely "aimed at" it.
   `[CITED: DeepWiki quickshell-mirror docs]`: an explicit `qmldir` file in a directory
   **disables Quickshell's auto-generation scanner for that directory entirely**, replacing
   the racy synthesis path with static resolution. This gives D-12's fix a structural
   reason to work, not just an empirical one.
5. **QML's `SpringAnimation` type has no "stiffness" property** — the spring-hardness
   parameter is named `spring` (confirmed in the installed `qt6-declarative`
   `plugins.qmltypes`), alongside `damping`, `mass`, `epsilon`, `modulus`, `velocity`. A
   planner reaching for Compose-style naming (`stiffness`) will get a silent
   QML "unknown property" — this is a concrete implementation trap for D-26.

**Primary recommendation:** Follow D-01..D-32 exactly as locked; this document supplies
the concrete numbers, regexes, and API shapes the planner needs to turn those decisions
into tasks without re-deriving anything CONTEXT.md already verified.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Motion Token Source & Emission

- **D-01:** **Motion renders through a new `theme-engine/lib/motion.sh`, following the
  `font.sh` theme-orthogonal axis pattern — not matugen.** `font.sh`'s header already
  establishes the shape: own state file under `$STATE_DIR`, excluded from `commit.sh`'s
  `rsync --delete`, re-rendered on every `theme-apply` run regardless of theme, rendered
  with plain `printf` into the tmp tree from inside `theme_engine_generate`. `generate.sh`
  therefore already contains non-matugen writers (`theme_engine_render_font_files`,
  `theme_engine_render_gtk_settings`) — `motion.sh` is a third sibling, not a second
  pipeline, and inherits the atomic render-then-commit invariant unchanged.
  Explicitly rejected: riding matugen via `--import-json` (verified available on 4.1.0).
  Decisive reason — TOKEN-05's reduced-motion requires **transforming** emitted values at
  render time; that is a few lines of bash in `motion.sh` versus `{% if %}` branching
  duplicated across three template dialects whose conditional support would first need
  verifying. TOKEN-06's spring→bezier fitting, if it ever lands, is the same story.

- **D-02:** **All three guards on emitted curves — they cover non-overlapping failure
  modes.** (a) Render-time validation in `motion.sh`, the only guard reaching the QML and
  GTK4 targets, where no readback exists and GTK4 silently drops a single bad rule
  (the Phase 9 finding). (b) `hyprctl animations -j` readback in `theme-doctor`, the only
  guard catching a value Hyprland accepts then substitutes. (c) A poisoned fixture proving
  the readback can fail before proving it passes.
  **Correction recorded during discussion:** a *missing* bezier is NOT silent — Hyprland
  errors loudly with "no such bezier" at config parse (verified). The silent-substitution
  risk is narrower than originally framed: it applies to malformed control-point *values*,
  not missing names. The readback earns its place by confirming emitted **values**.

- **D-03:** **The three motion outputs get full format-validated `contract.json` `files`
  entries**, not `presence_only_files` like the font fragments. `theme-parity` validates
  the rendered file at its path and does not care which writer produced it. PROJECT.md
  calls `contract.json` the single source of truth for the output contract, and Phase 2's
  lesson was checker/renderer drift — a render target outside the manifest is a drift
  vector. No new format handler needed: D-10 makes the QML target JSON, which
  `contract.sh` already handles.

- **D-04:** **Phase 12 emits curves only into Hyprland; the 14 `animation =` assignment
  lines stay hand-authored for Phase 13.** Respects the roadmap boundary exactly — Phase 12
  owns the pipeline, Phase 13 owns the retrofit, and Phase 13's own dependency note says
  validating fitted curves on already-gated surfaces before building QML on assumptions is
  the deliberate risk ordering. Criterion 2 is fully provable regardless: curves emit and
  `hyprctl` reads back their generated control points.

- **D-05:** **`motion.json` is two-layer** — a `durations` map and an `easings` map
  (control points), plus a semantic layer pairing them into named motions
  (e.g. `emphasized-in: {duration: long2, easing: emphasized-decel}`). Surfaces consume
  semantic names. Decisive reason: **Hyprland's format already works this way** — `bezier =`
  registers named curves independently and `animation =` supplies speed separately, so a
  two-layer source maps one-to-one onto the least flexible target. A flat schema would
  duplicate each curve per token and force the Hyprland emitter to re-derive the bezier
  registry it discarded.

- **D-06:** **A runtime motion-scale axis ships, with reduced-motion as one preset on it.**
  *Accepted expansion past TOKEN-05's literal wording, chosen deliberately after the cost
  was flagged.* Reduced-motion falls out as a preset rather than a parallel mechanism.
  — **Reversibility:** reversible — the axis is one state file plus a read in `motion.sh`.

- **D-07:** **The scale axis ships as state file + CLI only this phase; the graphical
  picker and its Super-key menu entry are deferred.** The whole mechanism — pipeline,
  transform, gate — gets built and proven; only presentation over a working axis is
  deferred. Keeps a GTK/walker surface out of a phase whose subject is the token pipeline,
  and avoids adding a surface Phase 13 would then have to retrofit for motion.

- **D-08:** **"Reduced" means scale durations; "off" is a distinct state that disables at
  the toolkit level.** Hyprland `animations { enabled = false }` (per-animation
  `enabled: false` verified present on 0.56.0 — `shadowangle` uses it), QML animation
  `enabled: false`, GTK4 emitting no transition. Criterion 4 permits either wording
  ("shortens *or* disables"). Two mechanisms because they encode two different user
  intents, and because accessibility reduced-motion means removing motion rather than
  accelerating it — plus it avoids relying on every toolkit behaving sanely at duration 0,
  which already bit this project once when a GTK4 easing curve triggered an assertion
  failure in Phase 9.

- **D-09:** **Every emitted duration is clamped to a minimum non-zero value; token collapse
  warns but does not fail.** Zero is the ambiguous input that invites silent default
  substitution. Collapse at a low scale is imperceptible by definition, so failing on it
  would make low scale values unusable for no benefit. Extends D-02's render-time
  validation rather than adding a fourth guard. **The Hyprland `speed` unit (apparently
  deciseconds — reads back `5.00` where the config says `5`) must be confirmed against the
  binary before the conversion is written.**

### QML Palette, the Live Surface, and QS-03

- **D-10:** **The summoned probe, styled from the palette, carries criterion 1.** The root
  stays headless (D-02 of Phase 11 intact, zero pixels in daily use) and Phase 14 keeps its
  "first real QML surface" billing. Criterion 1 is proven by summoning the probe, switching
  theme, and observing re-colour with the daemon PID unchanged. This *fulfils* Phase 11's
  D-04 rather than reversing it — that decision left the probe unstyled specifically because
  "Phase 12 owns choosing the QML render-target format."
  **Consequence to record:** the roadmap's stated rationale for moving QS-03 into Phase 12
  ("its criterion 1 re-colours a live surface, so it has to solve per-screen fan-out
  anyway") no longer holds. Criterion 6 still requires the fan-out outright, but the two are
  now decoupled rather than one implying the other.

- **D-11:** **The QML palette and QML motion targets are JSON, read via
  `FileView`/`JsonAdapter`, wrapped by a hex-free repo-authored `Colours.qml` built on
  Quickshell's `Singleton` type** (verified exported as `Quickshell/Singleton 0.0` by the
  installed `quickshell-core.qmltypes`, so no `pragma Singleton` and no `qmldir` needed).
  Three reasons, in order of weight:
  1. **Fidelity.** `JsonAdapter` updates property bindings *in place*, so
     `Behavior on color { ColorAnimation }` can render a theme switch as a smooth
     crossfade. A generated QML singleton reloads the document instead (~0.4s, measured in
     Phase 11), giving a hard cut with a visible flash, no expressible transition, and
     discarded surface state — which will matter once Phase 14's drawer has scroll position
     and a selected tab.
  2. **Blast radius.** A generated QML singleton needs a `qmldir` in the state dir, and
     `qmldir` synthesis is exactly where the QS-03 scanner race lives. This avoids widening
     exposure to the bug the same phase must close.
  3. **Contract.** Reuses `contract.json`'s existing `json` handler.
  Transport format has **no** effect on rendered colour precision — both paths deliver the
  same hex into the same QML `color` type. The wrapper preserves `Colours.primary`
  ergonomics and gives derived tokens one home. Its only cost: property names must track
  matugen's key names, though any consumer breaks on a key rename regardless.

- **D-12:** **QS-03 is re-attempted with a targeted fix, bounded, with a spike as escape
  hatch.** Check in an explicit `modules/qmldir` — aimed at FM1's documented root cause,
  since quickshell currently *synthesises* that file by scanning and the recorded failure
  was an empty synthesis with no `Scanning directory` log line — and retry `Variants` with a
  `LazyLoader` per screen rather than the always-instantiated `visible:` binding that
  produced FM2. Both hypotheses target a specific recorded observation. Bounded by an
  explicit budget, escalating to a spike if it does not hold, honouring the house rule
  against open-ended workaround hunting. **quickshell 0.3.0-2 is the latest in `extra` and
  is what is installed — "wait for upstream" is not available.** The proof protocol is fixed
  by the roadmap: re-proven against the always-on autostart daemon across a real session
  restart, not only in a foreground test run.

- **D-13:** **If both the bounded fix and the spike fail, QS-03 is accepted as a permanent
  limitation** — formally moved to Out of Scope in `REQUIREMENTS.md` and `PROJECT.md`
  (dropped, not deferred a second time), with ROADMAP criterion 6 amended. *The ROADMAP
  amendment is in-scope work for this phase under the D-15 precedent from Phase 11, not a
  deviation.* Chosen over blocking phase close; the host has one physical monitor (`DP-1`)
  so the fan-out is unexercised in daily use.
  — **Reversibility:** one-way — dropping the requirement rewrites REQUIREMENTS.md,
  PROJECT.md and ROADMAP.md; Phase 16's full-screen per-monitor overview would inherit a
  root that cannot fan out.

- **D-14:** **On acceptance, `quickshell-doctor` reports the check as a documented SKIP
  printing its reason and evidence pointer, and the script exits 0.** Matches D-07's
  recorded-caveat precedent and D-14's "record *why*, not just what" discipline from Phase
  11. Keeps the gate credible — a rerunnable gate everyone knows is permanently red is a
  gate nobody reads, and its non-zero exit stops being a usable signal for the other 13
  checks.

- **D-15:** **The probe becomes a token inspector.** Styled fully — it must consume real
  palette roles across surface, background, text and accent for criterion 1 to mean
  anything — but its *content* is diagnostic: swatches labelled with the token each element
  consumes, plus the screen name and the active theme. Phase 11's D-04 intent ("the probe
  never being pretty is a feature — it cannot be mistaken for a shipped surface") survives
  through content rather than through refusing colour. It doubles as the instrument for
  criterion 4 and for criterion 5's side-by-side.

- **D-16:** **Both the theme-switch crossfade and a replayable motion row animate.** The
  crossfade is token-driven, so it proves tokens govern real behaviour rather than a demo.
  The replay row — elements each animating on a named motion token, fired from a button —
  makes the human gate repeatable in seconds instead of costing a full theme switch, and
  criterion 5's spring-vs-MD3 comparison is impossible to judge if the only trigger is
  switching themes back and forth.

- **D-17:** **Live re-colour is proven inside `theme-stress-test`'s 10 consecutive
  switches**, not by a single switch. `commit.sh:94` uses `rsync -a --delete` *without*
  `--inplace`, so writes are atomic per-file by temp-then-rename — but **atomic replace
  changes the inode, and path-based file watchers commonly stop firing afterwards.** Phase
  11 proved `FileView` propagation using hand-edits, where the editor may have written in
  place. Under `theme-apply`, live re-colour could work on the first switch and silently
  stop — which a single-switch test passes by construction. `theme-stress-test` exists for
  exactly this works-once-then-degrades class. If it fails, the fix is re-arming the watch
  on replace — a finding, not something to build speculatively.

- **D-18:** **No quickshell step is added to `theme-apply`'s reload fan-out.** Quickshell
  becomes the first surface in the repo needing none — worth stating explicitly so nobody
  adds one for symmetry later. Beyond "unnecessary": a reload would rebuild the surface and
  destroy the crossfade D-11 was chosen to enable. Phase 11's D-13 hook remains the
  evidence-driven fallback if D-17 shows the watch breaking.

### Reduced-Motion Axis

- **D-19:** **wleave is the GTK proof surface for criterion 4.** GTK4, so the emitted
  `cubic-bezier` is proven on the toolkit that renders it natively. It already hand-copies
  Hyprland's `md3_decel` four numbers *with a comment saying so*, so retrofitting it
  demonstrates the exact drift the pipeline eliminates rather than a synthetic case. Phase
  13 opens this file anyway for WR-04. Same boundary shape as D-04: one surface as proof
  here, the sweep stays Phase 13's.

- **D-20:** **The "off" state also sets `org.gnome.desktop.interface enable-animations
  false`.** One line in `gtk.sh`'s existing GSettings block (it already sets five keys).
  Scale values map cleanly: off → false, every other value → true. TOKEN-05 says "across
  every surface", and third-party GTK/libadwaita apps read this key — per PROJECT.md GTK4
  apps pick it up live through the portal without a restart. The difference between "our
  surfaces animate less" and reduced motion actually working.

- **D-21:** **The scale state file holds a named preset** (`off` / `reduced` / `normal` /
  `lively`), **with the name→multiplier table in `motion.json`** so retuning stays a data
  edit rather than a code edit. Decisive reason: D-08 made "off" categorically different
  from a small multiplier, so a pure float would have to overload `0` to mean
  "toolkit-disabled, **not** zero-duration" — a magic value inside a numeric domain whose
  obvious reading is "instant". A closed name set has no such collision, validates itself
  with a `case` statement, and matches every existing state file (verified:
  `current-theme = catppuccin`, `mode = dark`, `font-choice` holds a font name — there is no
  numeric state file in the pipeline). It also maps onto the list-picker shape every picker
  in this repo already uses; there is no slider primitive anywhere in the stack.

- **D-22:** **`animations.conf` reads `enabled = $motion_enabled`; the generated motion file
  wraps its own `animations { }` block and is sourced at top level BEFORE
  `animations.conf`.** Forced by empirical results (see `<code_context>`): `source =` cannot
  appear inside a category block, and curves must be defined before use — which means the
  motion file must precede `animations.conf` for Phase 13's assignments, which in turn means
  the generated block cannot own `enabled` (animations.conf's own `enabled = true` would
  clobber it). The variable's failure mode is identical to the `$primary` colour variables
  already in use — same seed mechanism, no new failure class. Still honours D-04: no
  `animation =` assignment changes.
  **Note for the planner:** the motion `source =` line goes *before* `animations.conf` in
  `hyprland.conf`, not beside the colours at line 16. Phase 12 does not strictly need this —
  its curves are new names nobody references — but placing it correctly now avoids a Phase
  13 reshuffle.

### Motion Lint & Fidelity Ceiling

- **D-23:** **The lint is deny-by-default with an exemption list, and each exemption records
  its reason** — "pending Phase 13 retrofit" versus "GTK3, no variable mechanism exists".
  Covers every new Phase 14–17 surface the moment the file exists; makes outstanding debt
  visible in every run instead of invisible; hands Phase 13 a checklist that shrinks to
  zero. Rejected: an opt-in registry, under which new surfaces across four remaining phases
  go unlinted until someone remembers to register them, and the repo reads compliant while
  most of it is not — the green-gate-over-broken-code pattern that produced the Phase 6 and
  Phase 8 failures. Cost accepted: careful patterns are needed to avoid flagging
  duration-shaped numbers in comments and unrelated config.

- **D-24:** **The lint checks both no-raw-values AND that every token reference resolves.**
  TOKEN-04's wording covers only the first. Decisive reason: the raw-value check *alone
  manufactures the failure it cannot see* — it tells you to delete `200ms` and reference a
  token, and a typo'd token name then satisfies the lint while silently breaking the
  animation. Verified: two of three targets fail silently on a dangling reference (QML
  yields undefined, GTK4 falls back or drops the rule); only Hyprland errors loudly. Exact
  precedent: `waybar-design-lint`'s CHECK A resolves every `@name` colour reference and its
  own header calls that check "the WLOG-01 killer".

- **D-25:** **`motion.json` carries the full MD3 duration and easing scales as raw data, and
  only the semantic pairs real surfaces need now.** The two layers have opposite cost
  profiles: scales are inert numbers, and carrying the complete set means a future token is
  *chosen from a scale* rather than invented; semantic pairs are taste decisions, and
  deciding taste for surfaces that do not exist is the seeded-empty-tree cost Phase 11's
  D-19 rejected. Semantics grow per phase. Real usage today clusters tightly: waybar
  0.2s/0.3s, wleave 150ms/200ms, Hyprland speeds 4/5/10, and a handful of curves.

- **D-26:** **TOKEN-06 is attempted, bounded to a recorded verdict.** The instrument already
  exists — D-15's inspector and D-16's replay row are built for criteria 1 and 4 regardless
  — so the marginal work is one `SpringAnimation` variant beside the bezier one. QML has
  `SpringAnimation` natively and no curve-fitting is required because nothing exports
  springs to the bezier targets. **Explicit bound: if springs win, *adopting* them is a
  later phase's work, not this one.** PROJECT.md already logs this decision as "Pending —
  v3.0 Phase 12", and Phase 14 would otherwise build the first real QML surface without the
  answer. Standing constraint 5 is preserved: nothing depends on the outcome.

- **D-27:** **Per-plan human render-and-look gates, per ROADMAP standing constraint 1 —
  overriding `config.json`'s `human_verify_mode: "end-of-phase"`.** Two blocking gates:
  wleave judged at its own retrofit plan (before/after, no regression in feel), and the
  token inspector judged at its plan (palette maps correctly across themes, motion tokens
  visibly differ, reduced motion visibly shortens). The standing constraint is more
  specific and was written directly out of the Phase 6 and Phase 8 failures. It matters most
  for wleave, a regression risk on a surface already approved once — best judged against
  fresh memory rather than after unrelated work.

- **D-28:** **Criterion 3's poisoned surface is committed fixture pairs per target
  (poisoned + compliant), reached via a path argument, derived from the real compliant
  rules.** Double precedent: `keybind-doctor`'s path-argument self-test (D-18) and
  `theme-doctor`'s poisoned stylesheet. Zero risk to live config and rerunnable forever
  rather than a one-time ceremony. Fixtures' one weakness — drifting from how real surfaces
  are written — is closed by generating them from the real rules and poisoning a single
  value, so shape tracks reality without the git-clean hazard of poisoning a real file.

### Cross-Cutting

- **D-29:** **`contract.json` gains an `engine_owned_files` array; `commit.sh` builds its
  `--exclude` flags from it; a gate asserts every file in `$STATE_DIR` is either a contract
  render target or a declared engine-owned path.** `commit.sh`'s exclusion list documents a
  bug class that has recurred **five times** across eight paths — its own comment reads
  "CR-01 (same bug class, third occurrence)" — where an engine-owned state file not present
  in the rendered tree is silently wiped by `rsync --delete` on the next `theme-apply`.
  D-21's motion-scale state file is exactly that shape. Because the excludes and the gate
  read one array, adding a file fixes both at once and they cannot drift — the same reason
  `contract.json` works for render targets. Converts occurrence #7 from silent data loss
  found weeks later into an immediate gate failure.
  Rejected: a sixth `--exclude` flag (the status quo that has failed five times) and
  wholesale directory segregation (the better end state, but eight paths move and every
  consumer updates — `theme-init.sh`, three pickers, `gtk.sh`, waybar scripts — and WR-02
  shows `current-theme`'s sync-time visibility is already delicate; that belongs in a
  maintenance pass, not this phase).

- **D-30:** **`stow.sh` seeds the motion files when absent, generated by invoking
  `motion.sh`** — mirroring the existing `waybar-visibility.css` seed at `stow.sh:112–120`.
  A missing sourced file and an undefined `$motion_enabled` are both **hard Hyprland config
  errors** (verified), so a wrong posture means the compositor does not start at all on a
  fresh install, debugged from a TTY. `stow.sh:135` already runs `theme-apply` at install
  (D-60/WR-07) and `hyprland.conf:16` already sources a state file, so this exposure exists
  today for colour and is proven by the container gate and graphical VM — motion adds no new
  class. But `theme-apply` there is `|| true` guarded. Seeding from `motion.sh` rather than a
  hand-written stub means one source of truth and nothing that goes stale when Phase 13
  points assignments at generated curves. The repo already chose defensive seed-when-absent
  to prevent a single discarded stylesheet; this guards the whole compositor failing to
  start.

- **D-31:** **`theme-parity` asserts the motion files are byte-identical across all 22
  palettes, both modes, and both render branches at a fixed motion-scale.** Strongest and
  cheapest simultaneously — a hash compare, not a structural walk. Three things are proven
  and two are not available elsewhere: that `motion.sh` is wired into *both* the
  static-preset and materialyou branches; that each emitted file is well-formed; and — the
  one nothing else guards — that no motion token has accidentally been made to depend on a
  colour or on light/dark mode, which is the premise D-01's whole design rests on.

- **D-32:** **QS-03 is sequenced BEFORE the inspector rewrite.** The two cannot be
  parallelised — both modify `shell.qml` and `modules/Probe.qml`. Settling the per-screen
  structure against the current minimal probe means the only failure modes in play are the
  two already recorded; debugging an intermittent `qmldir` scanner race *while* adding
  swatches, a crossfade and a replay row to the same file is a compound problem with no
  clean way to separate new failures from old. Matches how this repo front-loads risky
  unknowns (Phase 10 gated at plan 2, Phase 11's tracer at plan 1). Also means that if QS-03
  ends in D-13 acceptance, that is known before the inspector is built, so it is built once
  in its final structure.
  Everything else follows: the emitter, schema, contract entries, validation, D-29's state
  manifest and D-30's seeding form the foundation; the Hyprland target and readback follow
  it; the lint needs targets to exist so it comes after them; wleave's retrofit carries its
  own human gate; TOKEN-06's verdict needs the inspector, so it goes last.

### Claude's Discretion

- Exact filenames for the three motion render targets and the scale state file.
- The precise semantic token names in `motion.json`'s trimmed semantic layer (D-25).
- Whether the motion lint lives in `hypr/.config/hypr/scripts/` alongside
  `waybar-design-lint` or in `theme-engine/` — follow whichever keeps it runnable when the
  gate has failed, matching Phase 11's D-05 reasoning.
- Exemption-list format and where it lives (D-23).
- Fixture file naming and layout (D-28).
- The bounded budget for D-12's targeted fix before escalating to a spike.
- Plan and wave decomposition within D-32's stated ordering constraints; granularity is set
  to `coarse` in `.planning/config.json`.

### Deferred Ideas (OUT OF SCOPE)

- **Graphical motion-scale picker** (`font-switcher.sh` shape) plus its Super-key settings
  menu entry — deferred from D-07. Natural fit for Phase 13's existing-surface sweep.
- **`@define-color` is deprecated in GTK4 4.22.4** (`GTK_CSS_PARSER_WARNING_DEPRECATED`).
  The existing colour pipeline uses it for the GTK4 target. Migrating to CSS custom
  properties is real tech debt — out of scope for Phase 12, which touches motion only.
- **GTK3 surfaces cannot consume motion tokens by variable.** waybar, swaync and SwayOSD have
  no CSS custom-property support, so Phase 13 inherits an unsolved mechanism question for
  those three. **Not a Phase 12 gap** — TOKEN-03 scopes explicitly to "QML, GTK4 CSS, and
  Hyprland".
- **Adopting spring physics across QML surfaces** if criterion 5's verdict favours them —
  explicitly a later phase's work (D-26).
- **Wholesale segregation of engine-owned state into its own subdirectory** — the better end
  state for D-29's bug class, but eight paths move and every consumer updates. Belongs in a
  maintenance pass.
- **A real second-display hotplug test** — carried over from Phase 11; D-12 still proves
  QS-03 against a virtual headless output. Worth a dated line if a second display becomes
  available.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TOKEN-01 | QML surfaces consume theme colours from `~/.local/state/theme/`, matugen-rendered, `contract.json`-listed — no copied palette file, no hex literal in QML | `Colours.qml`/`Motion.qml` FileView code example below; verified `Quickshell.Io/FileViewInternal` and `JsonAdapter` API shapes; matugen `config.toml` template-entry pattern shown |
| TOKEN-02 | Theme switch re-colours live Quickshell surfaces without restart | Verified `JsonAdapter.onPropertyChanged` in-place update mechanism; verified commit.sh's atomic-rsync inode-replace risk (D-17) with `FileView.reload()` re-arm API confirmed to exist |
| TOKEN-03 | One motion-token definition renders to QML, GTK4 CSS, Hyprland | Verified MD3 duration/easing data (primary source cross-check); verified GTK4 `var()` longhand-vs-shorthand behaviour; verified Hyprland `bezier=`/`animations{}` syntax and `speed` unit/clamp requirement |
| TOKEN-04 | `theme-doctor` fails on any surface hand-rolling raw duration/easing | Concrete lint regex patterns modeled on verified `waybar-design-lint` CHECK A/D; poisoned-fixture precedent (`keybind-doctor` path-arg hook) confirmed |
| TOKEN-05 | Reduced-motion setting shortens/disables animation across QML+GTK | Verified `Behavior.enabled` (bool) exists on installed Qt6; verified base `Animation` type lacks `enabled` (correction to UI-SPEC wording); verified `enable-animations` GSettings key live on this machine; verified Hyprland per-animation `enabled=` syntax |
| TOKEN-06 *(stretch)* | QML spring physics vs MD3 baseline, human-judged | Verified `SpringAnimation` property names (`spring` not `stiffness`); MD3 Expressive spring constants flagged `[ASSUMED]` — could not authoritatively confirm this session |
| QS-03 | Permanent shell root fans out to every `Quickshell.screens` entry | `11-QUICKSHELL-EVIDENCE.md` FM1/FM2 review; `[CITED]` confirmation that an explicit `qmldir` disables Quickshell's racy scanner for that directory |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Colour token authoring | Backend (matugen + theme-engine bash) | — | Existing pipeline; Phase 12 only adds a JSON render target, no new authoring tier |
| Colour token consumption (QML) | Client (Quickshell/QML) | — | `Colours.qml` Singleton reads state-dir JSON via `FileView`; no server round-trip |
| Motion token authoring | Backend (hand-authored `motion.json` + `motion.sh` transform) | — | D-01: theme-orthogonal axis, bash-rendered, same tier as font/icon axes |
| Motion token consumption (QML) | Client (Quickshell/QML) | — | `Motion.qml` Singleton, same FileView pattern as Colours.qml |
| Motion token consumption (GTK4) | Client (GTK4 CssProvider, in-process) | — | CSS custom properties resolved by GTK's own CSS engine at style-computation time; no backend round-trip after initial state-dir write |
| Motion token consumption (Hyprland) | Compositor (Hyprland's own config parser) | — | `bezier=`/`animations{}` block sourced directly into `hyprland.conf`; `hyprctl reload` already fires unconditionally on every `theme-apply` |
| Motion-scale (reduced-motion) axis | Backend (state file + `motion.sh` transform) | Compositor (Hyprland `enabled=`), Client (QML `Behavior.enabled`, GTK `enable-animations`) | One state file, three toolkit-specific application points — this is inherently cross-tier by TOKEN-05's own wording ("across every surface") |
| Motion-lint / gate enforcement | Backend (bash + regex, report-only script) | — | Same tier as `waybar-design-lint`/`theme-doctor` — static analysis over rendered/authored files, never a live toolkit process |
| Per-screen QML surface fan-out (QS-03) | Client (Quickshell `Variants`+`LazyLoader`+`qmldir`) | — | Pure QML/Quickshell-runtime concern; no backend involvement |

## Standard Stack

This phase introduces **no new libraries or packages** — every mechanism below is a
built-in feature of software already installed and verified working on this machine
(see Package Legitimacy Audit).

### Core

| Component | Version (installed) | Purpose | Why Standard (this repo) |
|-----------|---------|---------|--------------|
| Quickshell `FileView`/`JsonAdapter` | quickshell 0.3.0-2 | Live-reloading JSON state read into QML property bindings | `[VERIFIED]` Already the exact mechanism Phase 11's probe uses for hand-edited JSON; qmltypes confirm `path`, `watchChanges`, `adapter`, `reload()`, `writeAdapter()`, `atomicWrites`, `blockWrites` on the installed build |
| Quickshell `Singleton` type | quickshell 0.3.0-2 | Shared-instance QML object exposed to every importer without `pragma Singleton`/`qmldir` singleton declaration | `[VERIFIED]` exported as `Quickshell/Singleton 0.0`, prototype `ReloadPropagator`, in `quickshell-core.qmltypes` |
| Qt Quick `Easing.BezierSpline` + `easing.bezierCurve` | qt6-declarative 6.11.1-3 | Renders an arbitrary cubic-bezier (including MD3's overshoot curves) on any `PropertyAnimation`/`Behavior` | `[VERIFIED]` `BezierSpline` enum value present in `builtins.qmltypes`; `bezierCurve` is a `list<double>` property on `QQmlEasingValueType` |
| Qt Quick `SpringAnimation` | qt6-declarative 6.11.1-3 | Native spring physics for TOKEN-06's stretch comparison | `[VERIFIED]` exported `QtQuick/SpringAnimation`; properties `velocity`, `spring`, `damping`, `epsilon`, `modulus`, `mass` (NOT `stiffness`) |
| Qt Quick `Behavior.enabled` | qt6-declarative 6.11.1-3 | Toolkit-level animation disable for the "off" motion-scale preset | `[VERIFIED]` `bool` property on `QQuickBehavior`; the base `Animation`/`PropertyAnimation` type does **not** have this property — see Pitfalls |
| GTK4 CSS custom properties (`--x`/`var(--x)`) | gtk4 1:4.22.4-1 | Token-driven `transition-duration`/`transition-timing-function` values | `[VERIFIED]` (CONTEXT.md + this session) parses cleanly via `Gtk.CssProvider`; MUST use longhand `transition-*` properties, not the `transition:` shorthand — see Pitfalls |
| Hyprland `bezier =` / `animations { }` | hyprland 0.56.0-2 | Native curve registry + animation-block motion source | `[VERIFIED]` plain syntax (not Lua `hl.curve`) parses cleanly on this exact binary; `source =` of a file wrapping its own `animations {}` block also verified clean |
| `hyprctl animations -j` | hyprland 0.56.0-2 | Readback proof for criterion 2 | `[VERIFIED]` well-formed JSON, `jq`-parses cleanly; element `[1]` carries `name,X0,Y0,X1,Y1`, element `[0]` carries `name,speed,bezier,enabled,style,overridden` |
| gsettings `enable-animations` | dconf 0.49.0 / GSettings schema | GTK/libadwaita-wide reduced-motion signal | `[VERIFIED]` key exists, currently `true` on this machine, live-readable via `gsettings get org.gnome.desktop.interface enable-animations` |
| `python3-gi` (`Gtk.CssProvider`) | already a `theme-doctor` dependency | Headless GTK4 CSS parse validation (no display needed) | `[VERIFIED]` reused this session for the `var()`-in-shorthand test; matches `theme-doctor`'s existing "never call `Gtk.init()`" discipline |
| `jq` | already a repo-wide dependency | JSON extraction for `contract.sh`'s `json` format handler | `[VERIFIED]` already handles the QML palette/motion JSON targets generically — no new code needed for that one target |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `motion.sh` bash transform (D-01, locked) | matugen `--import-json` | Rejected in CONTEXT.md — capability exists (`[VERIFIED]`: `matugen --help` lists `--import-json`/`--import-json-string`) but reduced-motion transform logic would need `{% if %}` branching duplicated across 3 template dialects |
| Single hand-authored `Motion.qml` easing table (locked) | Quickshell's documented `[A-Z]*.qml.json` auto-singleton convention | `[CITED: DeepWiki]` Quickshell can auto-convert a `Foo.qml.json` file into a singleton without any QML wrapper at all — genuinely simpler, but **not chosen**: D-11 already reasoned through the `FileView`/`JsonAdapter`-wrapped-by-hand-authored-QML tradeoff (crossfade fidelity, contract reuse) and this alternate mechanism would not preserve `Colours.primary`-style ergonomics or in-place property updates the same way. Recorded here only so nobody rediscovers it mid-implementation and second-guesses the locked decision. |
| Bezier curves for TOKEN-06's spring comparison | Fitting MD3 Expressive spring physics to a bezier approximation | Rejected by D-26 itself — "nothing exports springs to the bezier targets", so no fitting work is needed; QML's native `SpringAnimation` is used directly |

**Installation:** None — zero new packages. See Package Legitimacy Audit.

**Version verification:**
```
$ pacman -Q hyprland quickshell qt6-declarative qt6-base gtk4 gtk3
hyprland 0.56.0-2
quickshell 0.3.0-2
qt6-declarative 6.11.1-3
qt6-base 6.11.1-1
gtk4 1:4.22.4-1
gtk3 1:3.24.52-1
```
All verified directly on the target machine this session, 2026-07-26.

## Package Legitimacy Audit

**Not applicable this phase.** Every runtime dependency this phase touches (Hyprland,
Quickshell, GTK4/GTK3, matugen, jq, python3-gi) is already installed and was verified
present in Phase 11 and again in this session (`pacman -Q` above). No `npm install`,
`pip install`, or `cargo add` of any kind occurs in this phase — it is pure bash, QML,
and CSS authored inside the existing repo.

## Architecture Patterns

### System Architecture Diagram

```
                    ┌─────────────────────────────┐
                    │  motion.json (hand-authored) │
                    │  durations{} + easings{} +    │
                    │  semantic{} pairs (D-05/D-25) │
                    └───────────────┬───────────────┘
                                    │ read
                                    ▼
┌───────────────────────────────────────────────────────────────────┐
│  theme-engine/lib/motion.sh  (theme_engine_render_motion, D-01)     │
│  — reads motion-scale state file (off/reduced/normal/lively)        │
│  — applies D-09's clamp-and-warn transform per motion-scale preset  │
│  — called from generate.sh's theme_engine_generate, 3rd sibling     │
│    writer alongside render_font_files / render_gtk_settings          │
└───────┬───────────────────────┬───────────────────────┬─────────────┘
        │ writes                │ writes                │ writes
        ▼                       ▼                        ▼
┌───────────────┐   ┌────────────────────────┐  ┌──────────────────────┐
│ motion.json    │   │ gtk-4.0-motion.css      │  │ hyprland-motion.conf  │
│ (QML target)   │   │ :root { --motion-*: }   │  │ animations { bezier=  │
│ $tmp$STATE_DIR │   │ $tmp$STATE_DIR          │  │  enabled=$motion_ena  │
└───────┬────────┘   └───────────┬─────────────┘  └───────────┬────────┘
        │                        │                             │
        ▼ commit.sh atomic rsync (D-14, inode replaces per file)
┌───────────────────────────────────────────────────────────────────┐
│                    ~/.local/state/theme/  (STATE_DIR)                │
└───────┬───────────────────────┬───────────────────────┬─────────────┘
        │                       │                        │
        ▼                       ▼                        ▼
┌────────────────┐   ┌───────────────────────┐  ┌───────────────────────┐
│ Motion.qml       │   │ wleave/style.css        │  │ hyprland.conf source= │
│ FileView+         │   │ @import gtk-4.0-motion  │  │  BEFORE               │
│ JsonAdapter        │   │ .css, var(--motion-*)  │  │  animations.conf      │
│ (Quickshell)       │   │ longhand transitions    │  │  (D-22)               │
└────────┬───────────┘   └────────────────────────┘  └──────────┬────────────┘
         │ Behavior on x { ColorAnimation/                       │ hyprctl reload
         │ NumberAnimation { easing.bezierCurve:                 │ (already fires
         │ Motion.standardBezier } }                              │ unconditionally,
         ▼                                                        │ reload.sh:54)
┌──────────────────────┐                                          ▼
│ Token Inspector        │                                ┌────────────────┐
│ (Probe.qml rewrite,     │                                │ Live Hyprland    │
│  D-15/D-16)             │                                │ window/workspace │
│  - colour swatches       │                                │ animations       │
│  - motion semantic rows   │                                └────────────────┘
│  - "Replay motion" button │
│  - crossfade demo          │
└────────────────────────────┘

        ▲ readback + gates (report-only, never mutate)
        │
┌───────────────────────────────────────────────────────────────────┐
│ theme-doctor: hyprctl animations -j readback (D-02b) + motion-lint  │
│   fold (D-23/D-24)                                                   │
│ theme-parity: byte-identity hash compare across 22 palettes (D-31)   │
│ theme-stress-test: 10-switch live re-colour assertion (D-17)         │
└───────────────────────────────────────────────────────────────────┘
```

### Recommended Project Structure

Filenames below are Claude's Discretion per CONTEXT.md — proposed, not locked, but chosen
to follow the repo's own existing naming conventions exactly (state-dir sibling files
named after their target, `-colors`/`-motion` suffix pattern already used by
`gtk-4.0-colors.css`).

```
theme-engine/.config/theme-engine/
├── motion.json                      # NEW — hand-authored token source (D-05/D-25)
├── lib/
│   └── motion.sh                    # NEW — theme_engine_render_motion_files (D-01)
├── contract.json                    # amended: +3 files entries, +engine_owned_files array
├── theme-doctor                     # amended: hyprctl readback + motion-lint fold
├── theme-parity                     # amended: byte-identity assertion (D-31)
└── theme-stress-test                # amended: live re-colour assertion (D-17)

hypr/.config/hypr/
├── config/
│   └── animations.conf              # amended: enabled = $motion_enabled (D-22)
├── hyprland.conf                    # amended: source= BEFORE animations.conf line
└── scripts/
    └── motion-lint                  # NEW — report-only gate (D-23/D-24), location TBD
                                      # (hypr/scripts/ alongside waybar-design-lint,
                                      # OR theme-engine/ — Claude's Discretion)

quickshell/.config/quickshell/
├── modules/
│   ├── qmldir                       # NEW — explicit module manifest (D-12, closes FM1)
│   ├── Colours.qml                  # NEW — Singleton, FileView+JsonAdapter (D-11)
│   ├── Motion.qml                   # NEW — Singleton, same pattern, sibling to Colours.qml
│   └── Probe.qml                    # REWRITE — token inspector (D-15/D-16), fan-out (D-12)
└── shell.qml                        # amended: Variants+LazyLoader per-screen fan-out

wleave/.config/wleave/
└── style.css                        # amended: 3 retrofit points (D-19), longhand transitions

matugen/.config/matugen/
└── config.toml                      # amended: +1 [templates.X] entry for QML palette JSON

~/.local/state/theme/  (render targets, never git-tracked)
├── motion.json                      # QML target
├── gtk-4.0-motion.css               # GTK4 target
├── hyprland-motion.conf             # Hyprland target
└── motion-scale                     # engine-owned state file (D-21/D-29), NOT rendered
```

### Pattern 1: motion.sh as the third non-matugen writer (D-01)

**What:** A bash function called from `theme_engine_generate`, alongside the two existing
non-matugen writers, rendering plain files via `printf`/heredoc into the tmp render tree.

**When to use:** Any theme-orthogonal axis whose transform logic (here: motion-scale
clamping) is cheaper in bash than in matugen's template language.

**Example** (bash, following `font.sh`'s exact header-comment and function-naming
convention — `theme_engine_read_X` / `theme_engine_render_X_files`):

```bash
# theme-engine/lib/motion.sh — motion-token theme-orthogonal axis (D-01, mirrors font.sh)

MOTION_STATE_FILE="$HOME/.local/state/theme/motion-scale"
MOTION_DEFAULT="normal"
MOTION_JSON="$HOME/.config/theme-engine/motion.json"
MOTION_FLOOR_MS=40   # D-09's collapse floor — just under short1 (50ms)

theme_engine_read_motion_scale() {
    local v
    v="$(cat "$MOTION_STATE_FILE" 2>/dev/null || echo "$MOTION_DEFAULT")"
    case "$v" in
        off|reduced|normal|lively) echo "$v" ;;
        *) echo "$MOTION_DEFAULT" ;;   # D-21: validate with a case statement
    esac
}

theme_engine_render_motion_files() {
    local tmp="$1"
    local scale multiplier enabled_flag
    scale="$(theme_engine_read_motion_scale)"

    # D-21: multiplier table lives in motion.json, not in this script.
    multiplier="$(jq -r --arg s "$scale" '.scales[$s].multiplier // 1.0' "$MOTION_JSON")"
    enabled_flag="true"
    [[ "$scale" == "off" ]] && enabled_flag="false"

    local out_dir="$tmp$STATE_DIR"
    mkdir -p "$out_dir"

    # ── Hyprland target: native bezier=/animations{} syntax, D-22 ─────
    {
        echo "animations {"
        echo "    enabled = \$motion_enabled"
        jq -r '.easings | to_entries[] |
            "    bezier = motion-\(.key), \(.value[0]), \(.value[1]), \(.value[2]), \(.value[3])"' \
            "$MOTION_JSON"
        echo "}"
        echo "\$motion_enabled = $enabled_flag"
    } > "$out_dir/hyprland-motion.conf"

    # ── GTK4 target: custom properties, D-19/D-20's contract ─────────
    {
        echo ":root {"
        jq -r --argjson mult "$multiplier" --argjson floor "$MOTION_FLOOR_MS" \
            '.semantic | to_entries[] |
             .key as $name | .value as $v |
             ($v.duration_ms * $mult) as $scaled |
             (if $scaled < $floor then $floor else $scaled end) as $clamped |
             "  --motion-duration-\($name): \($clamped | floor)ms;"' \
            "$MOTION_JSON"
        jq -r '.semantic | to_entries[] |
             "  --motion-easing-\(.key): cubic-bezier(\(.value.easing_points | join(", ")));"' \
            "$MOTION_JSON"
        echo "}"
    } > "$out_dir/gtk-4.0-motion.css"

    # ── QML target: plain JSON, contract.sh's existing `json` handler ──
    jq --argjson mult "$multiplier" --argjson floor "$MOTION_FLOOR_MS" --arg scale "$scale" \
        '.semantic |= with_entries(.value.duration_ms |=
            (((. * $mult) as $s | if $s < $floor then $floor else $s end) | floor)) |
         . + {motion_enabled: ($scale != "off"), motion_scale: $scale}' \
        "$MOTION_JSON" > "$out_dir/motion.json"
}
```

*This is illustrative shape, not a locked implementation* — the planner owns exact `jq`
filter correctness and the D-09 warn-not-fail collapse-notification path (this sketch
clamps silently; the locked decision requires a **warning** to be surfaced, e.g. to
`GENERATE_LOG`, on every clamp event).

### Pattern 2: QML Singleton over FileView/JsonAdapter (D-11)

**What:** A repo-authored `.qml` file whose root type is Quickshell's `Singleton`,
containing a `FileView` reading a state-dir JSON file through a `JsonAdapter`.

**Verified working precedent already in this repo** (`modules/Probe.qml`, lines 54-65):
```qml
FileView {
    id: probeState
    path: Quickshell.env("HOME") + "/.local/state/quickshell/probe.json"
    watchChanges: true
    onFileChanged: reload()
    onAdapterUpdated: writeAdapter()

    JsonAdapter {
        id: probeAdapter
        property string label: "unset"
    }
}
```

**Proposed `Colours.qml`** (same pattern, read-only — no `onAdapterUpdated: writeAdapter()`
needed since QML never writes this file, only matugen does):

```qml
// Colours.qml — Quickshell.Singleton, no pragma/qmldir needed (D-11, verified)
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    readonly property FileView paletteFile: FileView {
        path: Quickshell.env("HOME") + "/.local/state/theme/palette.json"
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: palette
            // D-11's magenta-fallback contract — never a plausible black/white default
            property string primary: "#FF00FF"
            property string onPrimary: "#FF00FF"
            property string primaryContainer: "#FF00FF"
            // ... one property per matugen key, full 17-role set per UI-SPEC
        }
    }
    readonly property alias primary: palette.primary
    readonly property alias onPrimary: palette.onPrimary
    // ... one readonly alias per role, so consumers write `Colours.primary`
}
```

**Proposed `Motion.qml`** (sibling Singleton, same FileView pattern, sourcing
`motion.json`):

```qml
// Motion.qml — sibling Singleton to Colours.qml (D-11's pattern extended to motion)
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    readonly property FileView motionFile: FileView {
        path: Quickshell.env("HOME") + "/.local/state/theme/motion.json"
        watchChanges: true
        onFileChanged: reload()

        JsonAdapter {
            id: motion
            property bool motionEnabled: true
        }
    }
    readonly property alias motionEnabled: motion.motionEnabled

    // Bezier control points as flat lists — Qt's QEasingCurve.bezierCurve format is
    // [c1x, c1y, c2x, c2y, endx, endy]; endpoint (1,1) appended here so consumers never
    // repeat it (verified against installed builtins.qmltypes: bezierCurve is list<double>)
    readonly property var standardBezier: [0.2, 0, 0, 1, 1, 1]
    readonly property int standardDuration: 200
}
```

**Consumption** (crossfade on a swatch, D-11's whole reason for choosing this transport):
```qml
Rectangle {
    color: Colours.primary
    Behavior on color {
        enabled: Motion.motionEnabled   // D-08/D-20: Behavior.enabled, verified real property
        ColorAnimation {
            duration: Motion.standardDuration
            easing.type: Easing.BezierSpline       // [VERIFIED] present in installed builtins.qmltypes
            easing.bezierCurve: Motion.standardBezier
        }
    }
}
```

**Important correction for the "off" mechanism (see Pitfalls):** the pattern above works
for *implicit* `Behavior`-driven animations (the theme crossfade). It does **not** apply
to *explicit*, imperatively-triggered animations (the replay row's `.start()` calls) —
those must be gated a different way since the base `Animation`/`PropertyAnimation` type
has no `enabled` property on this Qt build.

### Pattern 3: GTK4 motion custom properties — longhand only (verified this session)

**What:** `:root { --motion-*: ... }` custom properties consumed through the four
**longhand** `transition-*` properties, never the `transition:` shorthand, whenever any
value in the list is a `var()` reference.

**Verified broken** (GTK 4.22.4, this session — `Gtk.CssProvider` headless parse):
```css
/* DO NOT DO THIS — parses with no error, but every longhand gets the SAME raw
   unresolved string dumped into it, not a positional split */
button.hover-test {
  transition:
    background-color 150ms ease,
    transform var(--motion-duration-standard) var(--motion-easing-standard);
}
/* provider.to_string() shows transition-duration, transition-property,
   transition-timing-function, transition-delay ALL holding the identical
   literal text "background-color 150ms ease, transform var(...) var(...)" */
```

**Verified working:**
```css
button.hover-fix {
  transition-property:        background-color, border-color, box-shadow, transform;
  transition-duration:        150ms, 150ms, 150ms, var(--motion-duration-standard);
  transition-timing-function: ease, ease, ease, var(--motion-easing-standard);
}
```
Positional alignment across the three lists is standard CSS transition semantics (the
Nth item in `transition-property` pairs with the Nth item in `transition-duration` etc.)
— GTK4 resolves this correctly; it only mis-resolves the `transition:` shorthand when a
`var()` appears anywhere inside it.

**Also verified working** (no shorthand involved — `animation-*` longhands, which is what
wleave's existing `capsule-entrance` keyframe already uses):
```css
button {
  animation-name: capsule-entrance;
  animation-duration: var(--motion-duration-emphasized-in);
  animation-timing-function: var(--motion-easing-emphasized-decelerate);
  animation-fill-mode: backwards;
}
```
wleave's `capsule-entrance` rule (`style.css:557-562`) already uses this exact longhand
shape — the D-19 retrofit of that specific rule is a drop-in `var()` substitution with
**no structural change needed**. Only the `:hover,:focus` multi-property `transition:`
rule (`style.css:226-230`) needs restructuring into the longhand form above.

### Pattern 4: Hyprland motion fragment (D-22's exact ordering)

**Verified via `Hyprland --verify-config` this session** (non-destructive, no live
session touched):

```hyprlang
# ~/.local/state/theme/hyprland-motion.conf — sourced BEFORE animations.conf
animations {
    enabled = $motion_enabled
    bezier = motion-standard, 0.2, 0, 0, 1
    bezier = motion-emphasized-decelerate, 0.05, 0.7, 0.1, 1
    bezier = motion-emphasized-accelerate, 0.3, 0, 0.8, 0.15
    bezier = motion-linear, 1, 1, 1, 1
}
$motion_enabled = true
```
```hyprlang
# hyprland.conf — motion source line goes here, BEFORE animations.conf (D-22)
source = ~/.local/state/theme/hyprland-motion.conf
source = ~/.config/hypr/config/animations.conf
```

Confirmed empirically this session:
- `source =` **inside** an `animations {}` block fails ("Unclosed category at EOF") — matches CONTEXT.md's already-verified fact.
- Fractional decisecond `speed` values (`4.5`, `0.01`, `12.75`) all parse cleanly.
- `speed = 0` and `speed = -1` are **hard parse errors** ("invalid speed") — new finding, see Pitfalls.
- `enabled = $motion_enabled` (with `$motion_enabled` defined via a top-level `$var = value` assignment, not inside the block) parses cleanly — matches the existing `$primary`/`$secondary` colour-variable pattern already used throughout `hyprland.conf`.

### Anti-Patterns to Avoid

- **Using `transition:` shorthand with any `var()` value on GTK4** — silently produces
  garbage (see Pitfalls). Always split into longhand `transition-*` properties.
- **Assuming `Animation.enabled` exists as a generic QML mechanism** — it doesn't; only
  `Behavior.enabled` does. See Pitfalls for the imperative-animation gap this leaves.
- **Reusing the `gtk-css` or `hypr-vars` contract.json format tags unchanged for the
  motion files** — both extractors are hardcoded to color-specific syntax
  (`@define-color`, `$name = value`) that the motion files will never contain. See
  Pitfalls.
- **Assuming matugen's own write step is atomic** — it isn't (`[VERIFIED]` this session:
  same inode across two renders to the same tmp path). This doesn't matter for the live
  pipeline (matugen writes into a fresh `mktemp -d` every run, and the file `FileView`
  actually watches goes through `commit.sh`'s atomic `rsync`), but don't cite matugen's
  own write behavior as evidence either way for the `FileView`-watch-survives-replace
  question — that's `rsync`'s behavior, already correctly identified as atomic in D-17.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Cubic-bezier curve rendering in QML | A custom interpolation function sampling a bezier per-frame | `easing.type: Easing.BezierSpline` + `easing.bezierCurve: [...]` | `[VERIFIED]` native, installed, zero-dependency; handles MD3's overshoot curves (control points outside [0,1]) correctly, same as Hyprland already proves |
| MD3 duration/easing numeric values | Approximating from memory or a blog post | The verified table in this document (cross-checked against `androidx` `MotionTokens.kt`, Google's own source) | Training-knowledge MD3 numbers drift; this table is source-verified this session |
| Colour-token dangling-reference detection in GTK4 CSS | Instantiating a live GTK4 window/widget to observe computed-style fallback | Static regex cross-check: parse `:root { --motion-*: }` definitions vs every `var(--motion-*)` usage, same shape as `waybar-design-lint`'s CHECK A | `[VERIFIED]` this session: a dangling `var()` reference produces **zero** parse-time error from `Gtk.CssProvider` — it's a computed-value-time failure invisible to any headless test this repo's tooling already uses. A static reference-resolution check (already the repo's established pattern) is strictly more reliable than trying to observe runtime fallback behavior |
| Motion-lint JSON/QML token parsing | Hand-rolled string splitting | `jq`, same as every other JSON extraction in this repo (`contract.sh`'s `json` format branch) | Consistency, correctness on edge cases (escaped strings, nested objects) |
| Spring→bezier curve fitting for TOKEN-06 | A least-squares fitter | Nothing — not needed. `SpringAnimation` renders natively in QML; no target requires a spring value expressed as a bezier | D-26 already rejected fitting explicitly |

**Key insight:** Every mechanism this phase needs (bezier easing, spring physics, CSS
custom properties, live JSON file watching) is a **native, already-installed** feature of
the toolkits in play. The entire engineering effort is orchestration (one token source,
three renderers, one lint) — not building any of the underlying motion primitives.

## Common Pitfalls

### Pitfall 1: GTK4 `transition:` shorthand silently mis-splits when mixed with `var()`
**What goes wrong:** All four longhand `transition-*` properties end up holding the
*entire* raw, unresolved multi-value shorthand text, duplicated identically across all
four — not a positional split into `property`/`duration`/`timing-function`/`delay`.
**Why it happens:** `[VERIFIED]` this session via `Gtk.CssProvider.load_from_path()` +
`provider.to_string()` inspection on the installed GTK 4.22.4. The shorthand parser
appears to give up splitting the comma-list into positional longhands once it encounters
a `var()` token inside any item, and instead stores the raw text verbatim into all four
slots.
**How to avoid:** Always write the four longhand properties explicitly with
comma-aligned value lists (see Pattern 3 above) whenever a `var()` value needs to sit
alongside literal values in the same rule.
**Warning signs:** `Gtk.CssProvider.to_string()` shows the identical string repeated
across `transition-property`/`-duration`/`-timing-function`/`-delay` for a rule — this is
the fingerprint. wleave's own retrofit target at `style.css:226-230` has exactly this
shape today (3 literal items + would-become-1 token item) and must be rewritten to
longhand form.

### Pitfall 2: Hyprland `speed = 0` is a hard config-parse error, not a degenerate value
**What goes wrong:** If D-09's clamp logic has a bug that lets a zero-or-negative
duration reach the Hyprland emitter, the **entire Hyprland config fails to parse** —
not just that one animation. `[VERIFIED]` this session:
```
$ Hyprland --verify-config -c test-speed-zero.conf
Config error ... at line 4: invalid speed
```
Confirmed for `speed = 0` and `speed = -1`; confirmed CLEAN for `speed = 0.01` (and
`4.5`, `12.75` — fractional deciseconds are fine, no rounding required).
**Why it happens:** Hyprland's animation speed is deciseconds
(`[CITED: wiki.hypr.land via websearch]` 1 speed unit = 100ms), and the parser rejects
non-positive values outright at config-load time.
**How to avoid:** D-09's floor (proposed: 40ms, per UI-SPEC) must be applied **before**
the ms→decisecond division (`speed = duration_ms / 100.0`), and the floor value itself
must be verified > 0 after any multiplier is applied — this is not just a "smoothness"
requirement, it's a "does the compositor start at all" requirement, directly relevant to
D-30's stow.sh seeding concern (a bad first-boot motion-scale value could brick a fresh
install's Hyprland session).
**Warning signs:** `Hyprland --verify-config -c <path>` (non-destructive, safe to run
against a throwaway copy) reports `invalid speed`.

### Pitfall 3: `contract.json`'s existing format handlers don't fit the motion files
**What goes wrong:** If the GTK4 motion file (`gtk-4.0-motion.css`, custom-property
syntax) is tagged `format: "gtk-css"` in `contract.json`, `contract_extract_names`'s
regex (`@define-color \K\S+`) will find **zero** matches (there is no `@define-color`
line in a `--motion-*:` file). `theme-parity`'s Layer 2 (name-set parity) then hits its
own explicit guard — "Refuse an empty reference name-set: empty == empty would make
every subsequent cross-target comparison vacuous" — and **FAILs** on the very first
target. The same problem applies to the Hyprland motion fragment if tagged `hypr-vars`
(that extractor's regex, `^\$name = value`, will never match `bezier =` lines).
**Why it happens:** `[VERIFIED]` by reading `theme-engine/lib/contract.sh` directly —
each format tag dispatches to a hardcoded regex/parser built for that ONE existing file
shape; there is no generic "extract every declared identifier" fallback.
**How to avoid:** Add two new `contract.sh` format branches:
```bash
# in contract_extract_names():
css-vars)
    grep -oP '^\s*--\K[A-Za-z0-9_-]+(?=:)' "$path" 2>/dev/null | sort -u
    ;;
hypr-motion)
    { grep -oP '^\s*bezier = \K[A-Za-z0-9_-]+(?=,)' "$path" 2>/dev/null
      grep -oP '^\$\K[A-Za-z_][A-Za-z0-9_]*(?= =)' "$path" 2>/dev/null
    } | sort -u
    ;;
# in contract_extract_values():
css-vars)
    sed -nE 's/^\s*--([A-Za-z0-9_-]+):\s*(.*);\s*$/\1\t\2/p' "$path" 2>/dev/null
    ;;
hypr-motion)
    { sed -nE 's/^\s*bezier = ([A-Za-z0-9_-]+), (.*)$/\1\t\2/p' "$path"
      sed -nE 's/^\$([A-Za-z_][A-Za-z0-9_]*) = (.*)$/\1\t\2/p' "$path"
    } 2>/dev/null
    ;;
```
Both new branches must also be exempted from Layer 3's "every value must look like a
color" enforcement — the existing code only enforces color-shape validation on values
that already match a hex/`rgba()` pattern (`theme-parity` lines ~300), so duration/bezier
values naturally skip that specific check; but confirm `enforce_emptiness` behavior is
still correct for these two new tags (empty-value-is-a-bug is still a valid invariant for
motion files — an empty bezier definition is exactly as broken as an empty colour).
The QML target needs **no new handler** — `json` already works generically (`[VERIFIED]`
D-03's claim holds for that one target only).
**Warning signs:** `theme-parity` regressing from its current 1542/0 all-green state the
moment the 3 motion `files` entries are added to `contract.json`, specifically failing at
"name-set captured as reference (non-empty)" for the GTK4/Hyprland motion files.

### Pitfall 4: QML's base `Animation` type has no `enabled` property
**What goes wrong:** D-08/UI-SPEC's phrasing ("QML animation `Animation.enabled = false`")
implies a generic mechanism that doesn't exist on this Qt build. `[VERIFIED]` this
session: `QQuickAbstractAnimation` (the base type behind `PropertyAnimation`,
`NumberAnimation`, `ColorAnimation`, `SpringAnimation`) exposes only `running`, `paused`,
`alwaysRunToEnd` — no `enabled`. Only `QQuickBehavior` (the `Behavior { }` QML element)
has a bool `enabled` property.
**Why it happens:** `Behavior.enabled` gates whether an *implicit* transition fires at
all on a property change; a standalone/imperatively-triggered `PropertyAnimation` has no
equivalent toggle — its "off" state must instead be expressed by never calling `.start()`,
or by setting `duration: 0` at trigger time, or by wrapping it in a `Behavior` too.
**How to avoid:** For the theme crossfade (an implicit `Behavior on color`), use
`Behavior.enabled: Motion.motionEnabled` directly (Pattern 2 above). For the token
inspector's imperative "Replay motion" button (D-16), the trigger code itself must check
`Motion.motionEnabled` before calling `.start()` (or set the animation's `duration` to 0
for that run) — this is a real implementation decision the planner must make explicit in
a task, not something that falls out of a single property binding.
**Warning signs:** A QML console warning ("Cannot assign to non-existent property
'enabled'") if `enabled:` is mistakenly set directly on a `NumberAnimation`/
`ColorAnimation` instead of on its wrapping `Behavior`.

### Pitfall 5: QML `SpringAnimation`'s stiffness parameter is named `spring`, not `stiffness`
**What goes wrong:** A planner porting Compose/Material-style spring terminology
("stiffness", "dampingRatio") directly into QML property names will get an unknown-property
QML warning (property silently ignored, spring behaves with default/zero values).
**Why it happens:** `[VERIFIED]` this session in the installed `qt6-declarative`
`plugins.qmltypes`: `QQuickSpringAnimation` properties are `velocity`, `spring`,
`damping`, `epsilon`, `modulus`, `mass` — QML's own vocabulary, not Compose's.
**How to avoid:** Use `spring:` for stiffness and `damping:` directly; there is no
`dampingRatio` — `SpringAnimation`'s `spring`/`damping`/`mass` triple is a different
parameterization (physical spring constant + damping coefficient + mass) than Compose's
`stiffness`/`dampingRatio` pair, so a literal 1:1 numeric port is not meaningful — D-27's
human render-and-look gate is the actual arbiter for TOKEN-06's feel, not matching a
borrowed numeric constant.
**Warning signs:** A `SpringAnimation { stiffness: ... }` declaration produces no visible
spring effect at all — the property silently doesn't exist.

### Pitfall 6: A dangling `var(--motion-*)` reference in GTK4 CSS produces **no parse-time
error** — the failure is invisible to any headless test this repo already runs
**What goes wrong:** `[VERIFIED]` this session: loading a stylesheet with
`transition-duration: var(--typo-nonexistent);` through `Gtk.CssProvider` produces **zero**
parsing-error signals and a non-empty provider — the raw, unresolved `var(...)` text is
simply retained as the property's stored value. The actual "does this resolve to a real
value or silently fall back to the CSS-spec initial value" question only gets answered at
*style computation* time, against a live widget with a real display — which
`theme-doctor`'s existing CSS-parse guard deliberately never does (`Never calls
Gtk.init()`).
**Why it happens:** CSS custom properties are resolved lazily, at used-value computation,
per the CSS spec — a parser has no way to know at parse time whether a referenced
custom property will exist in the cascade.
**How to avoid:** The motion-lint's dangling-reference check (D-24) for the GTK4 target
must be a **static regex cross-check** (parse every `--motion-*:` definition, parse every
`var(--motion-*)` usage, diff the two sets) — exactly the `waybar-design-lint` CHECK A
pattern, not a live-widget test. This is consistent with, not a deviation from, D-24's
already-locked design.
**Warning signs:** None visible via the existing headless GTK CSS-parse tooling — this is
precisely why a static lint check is necessary rather than optional.

### Pitfall 7: Websearch claims about Hyprland's config syntax can be stale/wrong even
for the exact installed version
**What goes wrong:** A `[VERIFIED HYPRLAND VERSION]`-scoped websearch this session
returned "For Hyprland 0.55+ (Lua syntax): Animations are declared with the
`hl.animation()` method" — flatly contradicting CONTEXT.md's own already-`[VERIFIED]`
finding (and this session's own re-confirmation) that plain `bezier =`/`animation =`
syntax parses cleanly on the installed Hyprland 0.56.0.
**Why it happens:** Hyprland's Lua config layer is opt-in/additive on top of the classic
`hyprlang` parser, not a hard replacement — web sources conflate "Lua config support was
added" with "the old syntax was removed", which is false on this build.
**How to avoid:** Exactly what CONTEXT.md's `<specifics>` already states: "Verify against
the binary, do not reason about it." This pitfall is recorded here as a second,
independent confirmation of that exact discipline mid-research, not a new finding — a
reminder for the planner that any *further* Hyprland syntax question that comes up during
implementation should be tested with `Hyprland --verify-config -c <throwaway-copy>`
before trusting a web source, exactly as done for the `speed` unit and clamp behavior
above.

## Code Examples

### Verified Hyprland fractional-speed + zero-speed test (reproducible)
```bash
# Non-destructive — never touches the live session
cat > /tmp/test-speed.conf <<'EOF'
animations {
    enabled = true
    bezier = liner, 1, 1, 1, 1
    animation = fadeIn, 1, 4.5, liner
}
EOF
Hyprland --verify-config -c /tmp/test-speed.conf
# => "config ok"

cat > /tmp/test-speed-zero.conf <<'EOF'
animations {
    enabled = true
    bezier = liner, 1, 1, 1, 1
    animation = fadeIn, 1, 0, liner
}
EOF
Hyprland --verify-config -c /tmp/test-speed-zero.conf
# => "Config error ... invalid speed"
```

### Verified `hyprctl animations -j` shape (for the D-02 readback check)
```json
{
    "name": "windowsMove",
    "overridden": true,
    "bezier": "wind",
    "enabled": true,
    "speed": 5.00,
    "style": "slide"
}
```
This is element `[0]` of the top-level array (one entry per animation slot). Element
`[1]` is the registered curve list, each carrying `name, X0, Y0, X1, Y1`. The readback
check for criterion 2 should assert: for every emitted `motion-*` bezier name, an entry
in element `[1]` exists with the exact expected `X0,Y0,X1,Y1`.

### Verified quickshell FileView API surface (from installed qmltypes, cross-checked
against the already-working `Probe.qml`)
```
Property: path (via internal __path), watchChanges (bool), adapter, loaded (bool, readonly)
Method:   reload(), writeAdapter(), waitForJob()
Signal:   loaded, loadFailed(error), saved, fileChanged, adapterUpdated, pathChanged
```
`reload()` is the concrete API to call if D-17's stress test reveals the watch stops
firing after `commit.sh`'s atomic rsync replace (Phase 11's D-13 fallback hook).

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| wleave hand-copying Hyprland's `md3_decel` 4 numbers with a "keep in sync manually" comment | Single `motion.json` source, both surfaces consume the same named token | This phase (D-19) | Eliminates the exact drift class the comment at `style.css:559-560` already flags as a known risk |
| `@define-color`-based colour theming for GTK4 | CSS custom properties (`--x`/`var(--x)`) — `@define-color` is `GTK_CSS_PARSER_WARNING_DEPRECATED` on 4.22.4 | Already true before this phase (CONTEXT.md `<specifics>`) | Motion is the FIRST GTK4 target in this repo to use genuine custom properties instead of `@define-color`; colour migration is explicitly deferred (Deferred Ideas) |
| PROJECT.md's "GTK4 takes sampled `@keyframes`" note (written for spring curves) | `cubic-bezier()` directly, verified to carry overshoot | This session / already noted in CONTEXT.md | PROJECT.md's stated assumption "no longer applies" per CONTEXT.md's own `code_context` — worth the planner double-checking PROJECT.md gets updated if it still says otherwise |

**Deprecated/outdated:**
- `@define-color` for any NEW GTK4 declaration — still fine for the existing colour
  pipeline (unchanged this phase), but the motion pipeline should not introduce a new
  `@define-color` anywhere.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|----------------|
| A1 | Material 3 Expressive's official spring-physics constants (stiffness/damping for the "spatial"/"effects" motion categories) — could not be authoritatively confirmed via any tool available this session; `androidx` `MotionScheme.kt`'s exact spring values were not retrievable through WebFetch (JS-rendered source browser, raw GitHub mirror returned no spring-specific constants for this file) | Standard Stack / TOKEN-06 | LOW — TOKEN-06 is a stretch requirement that "blocks nothing" (standing constraint 5) and is judged by human render-and-look (D-27), not by matching a reference numeric constant. Recommend the planner treat the QML `SpringAnimation` parameters as tunable-by-feel starting points (e.g. `spring: 200-400`, `damping: 15-25` for a "default" feel; lower damping/higher spring for an "expressive" bouncy feel) rather than as verified MD3 values. |
| A2 | The two third-party-sourced "Expressive spatial fast/default" cubic-bezier approximations (`cubic-bezier(0.42, 1.67, 0.21, 0.9)` at 0.35s, `cubic-bezier(0.38, 1.21, 0.22, 1)` at 0.5s) come from a single blog (note.com), not Google's primary source | State of the Art / TOKEN-06 discussion | LOW — not referenced anywhere in the locked `motion.json` schema (D-25 scopes the full scale to the 16 durations + 4 core easings already primary-source-verified); these two extra curves are optional colour for TOKEN-06 exploration only, not required by any locked decision |
| A3 | Quickshell's `FileView` uses an inotify-backed (or Qt `QFileSystemWatcher`-backed) file watch whose behavior on external atomic replace matches the generic "watch detaches from a replaced inode" pattern well-documented for `QFileSystemWatcher` — Quickshell's own docs (DeepWiki mirror) did not confirm this internal implementation detail | Pitfalls (folded into existing D-17 discussion) | LOW — D-17 already treats this as an open question to be answered empirically by `theme-stress-test`'s 10-switch run, not as a design premise. This assumption only informs *why* the risk is plausible, not whether it's true; the stress test is the actual verification mechanism regardless. |

**If this table is empty:** N/A — three items above need no user confirmation to
proceed (all are explicitly non-blocking per locked decisions), but are recorded per the
provenance discipline.

## Open Questions

1. **Exact D-09 collapse-floor value.**
   - What we know: UI-SPEC proposes 40ms (just under `short1`'s 50ms); Hyprland's own
     constraint (verified this session) only requires > 0, no numeric floor of its own.
   - What's unclear: whether 40ms is perceptually right for GTK4/QML too, or whether each
     target needs its own floor.
   - Recommendation: keep UI-SPEC's single 40ms floor for all three targets — it's already
     approved design contract, and D-09 explicitly frames the floor as "collapse at a low
     scale is imperceptible by definition", i.e. floor value precision is not
     safety-critical the way the >0 requirement is.

2. **Whether `theme-parity`'s Layer 3 (`enforce_emptiness`) should apply to the two new
   `css-vars`/`hypr-motion` format tags.**
   - What we know: the existing `enforce_emptiness=1` set (`gtk-css|hypr-vars|kitty-kv|
     css-literal|env-kv`) treats every declared key as "definitionally a color" and
     therefore an empty value is a bug for those formats.
   - What's unclear: whether an empty *value* for a motion key (e.g. a bezier control
     point list that renders empty due to a `jq` bug) should be treated with the same
     severity.
   - Recommendation: yes — add `css-vars`/`hypr-motion` to the `enforce_emptiness` set
     too. An empty motion value is exactly as broken as an empty colour value (same class
     of silent-default-substitution risk D-02/D-09 already worry about).

3. **Where the motion-lint script lives** (explicitly Claude's Discretion) — recommend
   `hypr/.config/hypr/scripts/motion-lint`, matching `waybar-design-lint`'s location and
   the reasoning CONTEXT.md already gives ("keeps it runnable when the gate has failed",
   Phase 11's D-05 precedent) since the Hyprland and GTK4 targets it inspects both live
   under paths this directory already has established conventions for reading.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|--------------|-----------|---------|----------|
| Hyprland | Compositor motion target, `hyprctl animations -j` readback | [VERIFIED] | 0.56.0-2 | — (hard requirement, already the whole repo's compositor) |
| Quickshell | QML motion/colour targets, token inspector | [VERIFIED] | 0.3.0-2 | — (hard requirement, Phase 11 already gated on this) |
| qt6-declarative | `Easing.BezierSpline`, `SpringAnimation`, `Behavior.enabled` | [VERIFIED] | 6.11.1-3 | — |
| GTK4 | CSS custom-property motion target, wleave retrofit | [VERIFIED] | 1:4.22.4-1 | — |
| python3-gi (PyGObject) | Headless `Gtk.CssProvider` motion-lint parse check | [VERIFIED] | present (already a `theme-doctor` dependency) | `theme-doctor`'s existing pattern: degrade to `[SKIP]`, never `[FAIL]`, if absent |
| jq | `contract.sh` JSON extraction, `motion.sh`'s JSON emission | [VERIFIED] | present (repo-wide dependency already) | — |
| matugen | QML palette JSON render target | [VERIFIED] | 4.1.0 | — |

**Missing dependencies with no fallback:** None — every dependency above is already
installed and verified on this machine.

**Missing dependencies with fallback:** None beyond the existing `theme-doctor`
graceful-degradation pattern for `python3-gi` (already established, not new to this
phase).

## Validation Architecture

> Included per this phase's `<research_priorities>` item 6, despite `nyquist_validation`
> being `false` in `.planning/config.json` — the phase explicitly asked for a mapping of
> how each success criterion gets proven. This repo has no pytest/jest-style test
> framework; its established "test framework" is the rerunnable report-only gate script
> family (`theme-doctor`, `theme-parity`, `theme-stress-test`, `keybind-doctor`,
> `waybar-design-lint`, `quickshell-doctor`) — the table below maps onto that convention
> instead of inventing a new one.

### Test Framework (repo convention)

| Property | Value |
|----------|-------|
| Framework | Bash rerunnable gate scripts (`check()` PASS/FAIL accumulator pattern) |
| Config file | None — each gate script is self-contained; `contract.json` is the shared manifest |
| Quick run command | `~/.config/theme-engine/theme-doctor` (report-only, safe anytime) |
| Full suite command | `~/.config/theme-engine/theme-parity && ~/.config/theme-engine/theme-stress-test` (the latter MUTATES the live desktop — 10 real theme switches) |

### Phase Success Criteria → Proof Map

| Criterion | Behavior | Proof Mechanism | Automated? |
|-----------|----------|-------------------|------------|
| 1. Live re-colour, no restart | Theme switch re-colours summoned inspector, daemon PID unchanged | `theme-stress-test`'s 10-switch loop (D-17) + human observation of unchanged PID | Partially — PID/file assertions automated, visual crossfade quality is the D-27 human gate |
| 2. Motion renders to all 3 targets, values hold | `hyprctl animations -j` readback matches emitted control points; GTK4/Hyprland syntax chosen by binary test not assumption | `theme-doctor`'s new readback check (D-02b) | Fully automated |
| 3. `theme-doctor` fails on poisoned surface, passes on compliant | Deliberately-poisoned fixture triggers motion-lint FAIL; compliant fixture PASSes | `motion-lint <poisoned-fixture-path>` / `motion-lint <compliant-fixture-path>` — path-argument self-test, same shape as `keybind-doctor` (D-28) | Fully automated |
| 4. Reduced-motion shortens/disables on QML+GTK+Hyprland in one run | Motion-scale set to `off`/`reduced`, single `theme-apply` run visibly changes all three | Token inspector's replay row (D-16) + wleave visual check — human-observed per D-27's blocking gate | Manual (blocking human gate, by design — D-27) |
| 5. *(stretch)* Spring vs MD3 side-by-side | Human watches both, records verdict | Token inspector's Spring/MD3 toggle (D-26/UI-SPEC) | Manual, explicitly non-blocking (standing constraint 5) |
| 6. QS-03 per-screen fan-out | `quickshell-doctor`'s existing per-screen check goes from 13/1/exit-1 to 14/0/exit-0 (or documented SKIP under D-13/D-14) | `quickshell-doctor`, re-run against the always-on autostart daemon across a real session restart (not just foreground) — D-12's fixed proof protocol | Fully automated (mechanical check), but requires a real session-restart step per the roadmap's explicit non-negotiable |

### Sampling Rate
- **Per task commit:** `theme-doctor` (report-only, safe to run after every motion.sh/contract.json edit)
- **Per wave merge:** `theme-doctor` + `theme-parity` (byte-identity assertion needs a full render of all 22 palettes — not cheap enough for per-task, appropriate for per-wave)
- **Phase gate:** `theme-stress-test` (mutates the live desktop — run once, deliberately, before `/gsd-verify-work`, matching the existing repo convention that this script is the final live-session proof, not a routine check)

### Wave 0 Gaps
- `motion.sh` does not exist yet — no test can run against it until Wave 1 creates it.
- `contract.json`'s two new format branches (`css-vars`, `hypr-motion`) don't exist —
  `theme-parity` will vacuously pass (nothing to check) until the `files` entries are
  added, then must be verified to actually catch a real mismatch (recommend a throwaway
  poisoned-value test during that same task, mirroring D-28's fixture discipline).
- The motion-lint script itself doesn't exist — D-28's poisoned/compliant fixture pairs
  are both new artifacts this phase creates from scratch.

*(No pre-existing test infrastructure gap beyond "the phase's own deliverables don't
exist yet" — this repo's gate-script convention is mature and directly reusable.)*

## Project Constraints (from CLAUDE.md)

- **Tech stack is fixed**: Arch Linux, Hyprland, uwsm, stow, matugen — this phase extends
  the existing theming pipeline, it is explicitly not a rewrite. Confirmed compatible:
  every mechanism proposed above is additive to the existing `theme-engine/` structure.
- **Compatibility**: theme switching must keep supporting both static-preset and matugen
  dynamic modes through one pipeline — D-31's byte-identity assertion directly enforces
  this for motion (both branches must render identical motion output, since motion is
  theme-orthogonal).
- **Reproducibility**: everything must be installable via `install.sh` + `stow.sh` with no
  manual host-only state — D-30 (stow.sh seeding) and D-29 (engine-owned state gate)
  directly serve this constraint; no new package is added to `install.sh` this phase since
  no new external dependency is introduced.
- CLAUDE.md's own `adw-gtk-theme`/GTK3-vs-GTK4 findings are **not** directly relevant to
  this phase's motion work (they concern GTK3's Thunar theming, an unrelated colour-pipeline
  finding from a prior research session) — noted here only to confirm no contradiction
  exists between that document and this phase's GTK4 motion approach.

## Security Domain

`security_enforcement: true`, `security_asvs_level: 1` per `.planning/config.json`.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|----------------|---------|--------------------|
| V2 Authentication | No | No auth surface introduced |
| V3 Session Management | No | N/A |
| V4 Access Control | No | Local single-user desktop, no privilege boundary crossed |
| V5 Input Validation | **Yes** | Motion-scale CLI/state-file value MUST be validated with a closed `case` statement against the 4 named presets (D-21 already mandates this — same pattern as `theme-apply`'s existing palette-name validation at `theme-apply:51-60`, verified this session). `motion.json`'s hand-authored content is trusted (repo-authored, not user/network input) but the **rendered** motion files must never contain unescaped `{{`/`}}` template leftovers (same discipline `theme-parity`'s Layer 3 already enforces for colour files) |
| V6 Cryptography | No | N/A |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|------------------------|
| Shell command/argument injection via a malformed `motion.json` value flowing into `printf`/`jq` filters | Tampering | `motion.json` is repo-authored (not user-writable at runtime by any untrusted actor) — same trust boundary as `palettes/*.json`. `motion.sh` should still prefer `jq`'s `--arg`/`--argjson` parameter injection over string-interpolating `jq` filter text, matching this repo's existing discipline elsewhere (`contract.sh` already does this correctly) |
| Notification content injection (a malformed motion-collapse warning reaching `notify-send` with control characters) | Tampering/DoS | Reuse the exact sanitization already present in `theme-apply`/`theme-stress-test` — `head -c 200 | tr -d '\000-\011\013\014\016-\037'` before any dynamic string reaches `notify-send` |
| A poisoned motion-lint fixture accidentally being sourced by a live theme-apply run | Tampering | D-28's fixtures must live in a location `motion.sh`/`generate.sh` never read from (e.g. alongside the lint script, not under `theme-engine/` proper if that directory is scanned for anything) — same "zero risk to live config" discipline already proven by `keybind-doctor`'s path-argument self-test |

## Sources

### Primary (HIGH confidence)
- Direct binary verification, this machine, this session (2026-07-26): `Hyprland --verify-config` (fractional speed, zero/negative speed, existing syntax re-confirmation); `hyprctl animations -j` (live readback shape); `hyprctl version` (0.56.0-2); `pacman -Q` (all installed versions); `/usr/lib/qt6/qml/**/*.qmltypes` (FileView, JsonAdapter, Singleton, Easing.BezierSpline, SpringAnimation, Behavior.enabled, base Animation type properties); `gsettings get org.gnome.desktop.interface enable-animations`; `python3 -c "import gi; ... Gtk.CssProvider"` (GTK4 `var()`-in-shorthand-vs-longhand behavior, dangling-`var()` parse-time silence); `matugen json ... -p <tmp>` twice into the same path (in-place-write inode test)
- `androidx-main` `MotionTokens.kt` (raw GitHub mirror fetch) — primary Google source for MD3 duration/easing values, cross-verifying the already-approved `12-UI-SPEC.md` numbers
- Codebase files read directly: `theme-engine/.config/theme-engine/{contract.json,theme-doctor,theme-parity,theme-stress-test,lib/{font.sh,generate.sh,commit.sh,gtk.sh,reload.sh,contract.sh},theme-apply}`, `hypr/.config/hypr/{hyprland.conf,config/animations.conf,scripts/{waybar-design-lint,keybind-doctor,quickshell-doctor}}`, `quickshell/.config/quickshell/{shell.qml,modules/Probe.qml}`, `wleave/.config/wleave/style.css`, `matugen/.config/matugen/config.toml`, `stow.sh`

### Secondary (MEDIUM confidence)
- `[CITED: DeepWiki quickshell-mirror/quickshell docs]` — QmlScanner auto-qmldir-synthesis behavior and explicit-qmldir override; Quickshell `[A-Z]*.qml.json` auto-singleton convention
- `[CITED: wiki.hypr.land via WebSearch]` — "speed is deciseconds, 1ds = 100ms" (cross-verified against this session's own `--verify-config` fractional/zero tests, which confirm the behavior even though the exact prose wasn't independently fetchable from the JS-rendered wiki page)
- `[CITED: GitHub issue hyprwm/Hyprland#9008]` — historical float-speed regression (0.46.0, already fixed by the time of PR #9123), corroborating that fractional speed is a supported, intentional feature, not an accident of this specific build

### Tertiary (LOW confidence)
- `[ASSUMED]` MD3 Expressive spring-physics stiffness/damping constants — could not retrieve from a primary source this session (see Assumptions Log A1)
- `[ASSUMED]` note.com blog's "Expressive spatial fast/default" cubic-bezier approximations (Assumptions Log A2)
- `[ASSUMED]` Quickshell `FileView`'s internal watch mechanism (`QFileSystemWatcher`-style inode-detach behavior) — plausible but not confirmed against Quickshell's own source (Assumptions Log A3); D-17's stress test is the actual empirical arbiter regardless

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — every component already installed and directly verified this session, zero new packages
- Architecture: HIGH — every pattern shown is either an already-working repo precedent (`Probe.qml`'s FileView usage) or directly tested this session (GTK4 var() behavior, Hyprland speed semantics)
- Pitfalls: HIGH for Pitfalls 1-4, 6-7 (directly reproduced this session); MEDIUM for Pitfall 5 (qmltypes-confirmed API shape, not a reproduced runtime bug)
- MD3 token data: HIGH (cross-verified against Google's own `androidx` source, matches the already-approved UI-SPEC exactly)
- TOKEN-06 spring constants: LOW (explicitly `[ASSUMED]`, non-blocking per standing constraint 5)

**Research date:** 2026-07-26
**Valid until:** 30 days for the Hyprland/GTK4/Qt6 binary-verified findings (stable, versioned installs, low churn risk); do not trust the MD3 token cross-check beyond a major Material Design revision (unlikely inside this milestone's timeframe).
