# Phase 12: Unified Design-Token Pipeline - Context

**Gathered:** 2026-07-26
**Status:** Ready for planning

<domain>
## Phase Boundary

One hand-authored token source emits **colour** *and* **MD3 motion** to three render
targets — QML, GTK4 CSS and Hyprland — through `theme-apply`'s existing single
entrypoint, guarded by a motion lint that refuses any surface hand-rolling its own
values. Plus the carried-forward QS-03 per-screen surface fan-out from Phase 11.

**This phase builds a pipeline, not a desktop.** The only visible output is the
existing Quickshell probe upgraded into a token inspector (still summon-only, root
still headless) and one GTK surface — wleave — retrofitted as the GTK-side proof.
The five remaining GTK surfaces and Hyprland's animation assignments stay untouched;
Phase 13 owns that sweep.

Requirements: TOKEN-01, TOKEN-02, TOKEN-03, TOKEN-04, TOKEN-05, TOKEN-06 *(stretch)*,
QS-03 *(carried forward from Phase 11 via a recorded override)*.

</domain>

<decisions>
## Implementation Decisions

### Motion Token Source & Emission

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
  restart, not only a foreground run.

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

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and standing rules
- `.planning/ROADMAP.md` §"Phase 12: Unified Design-Token Pipeline" — the six success
  criteria, the three open questions this phase owns, and what it Owns
- `.planning/ROADMAP.md` §"Standing constraints (apply to every v3.0 phase)" — all five
  apply. Constraint 1 (human render gate — see D-27, which resolves its conflict with
  `config.json`), constraint 2 (verify against the installed binary — heavily exercised
  during this discussion), constraint 4 (additive-only coexistence) and constraint 5
  (TOKEN-06 blocks nothing — see D-26) are directly load-bearing
- `.planning/ROADMAP.md` §"Carried-in maintenance placement" — the QS-03 → Phase 12
  paragraph, whose stated rationale D-10 partially undercuts
- `.planning/REQUIREMENTS.md` §"Design Tokens (TOKEN)" TOKEN-01..06 and the QS-03 row, plus
  §Traceability
- `.planning/PROJECT.md` §"Key Decisions" — specifically the MD3-baseline/spring-stretch row
  and the "One motion source, three render targets, differing by mechanism" row (both marked
  Pending — v3.0 Phase 12), and the human-render-gate row

### Prior phase context that carries forward
- `.planning/phases/11-quickshell-viability-gate/11-CONTEXT.md` — D-02 (headless root),
  D-04 (probe left unstyled *for this phase to decide*), D-05 (`quickshell-doctor`),
  D-13 (record-the-limitation house rule), D-15 (ROADMAP-amendment precedent),
  D-19 (minimal QML structure), D-20 (`~/.local/state/quickshell/`), D-21 (layer convention)
- `.planning/phases/11-quickshell-viability-gate/11-QUICKSHELL-EVIDENCE.md` — **read the
  `Variants` section (~line 574–620) before attempting D-12.** It records the three
  arrangements tried and the two reproducible failure modes verbatim
- `.planning/phases/11-quickshell-viability-gate/11-VERIFICATION.md` — frontmatter
  `overrides`, the recorded QS-03 acceptance

### Code this phase modifies or extends
- `theme-engine/.config/theme-engine/lib/font.sh` — **the pattern D-01 copies.** Read its
  header comment block in full; it states the theme-orthogonal axis contract
- `theme-engine/.config/theme-engine/lib/generate.sh` — `theme_engine_generate` is where
  `motion.sh`'s renderer is called, alongside the two existing non-matugen writers
- `theme-engine/.config/theme-engine/lib/commit.sh` — the `rsync --delete` at line 94 and
  its exclusion comment block at lines 25–60, which documents D-29's five-occurrence bug
  class
- `theme-engine/.config/theme-engine/contract.json` — gains three motion `files` entries
  (D-03) and the `engine_owned_files` array (D-29)
- `theme-engine/.config/theme-engine/theme-parity` — gains D-31's byte-identity assertion
- `theme-engine/.config/theme-engine/theme-doctor` — gains the `hyprctl animations -j`
  readback (D-02) and folds in the motion lint; see its `waybar-design-lint` fold at line 475
  for the integration shape
- `theme-engine/.config/theme-engine/theme-stress-test` — gains D-17's live re-colour
  assertion
- `theme-engine/.config/theme-engine/lib/gtk.sh` — the GSettings block (lines 34–37, 255,
  287–312) that D-20 extends
- `hypr/.config/hypr/config/animations.conf` — `enabled = $motion_enabled` (D-22); the 12
  hand-authored beziers and 14 `animation =` lines stay
- `hypr/.config/hypr/hyprland.conf` — the motion `source =` line goes **before** line 10's
  `animations.conf`, not beside line 16's colours (D-22)
- `hypr/.config/hypr/scripts/waybar-design-lint` — the shape D-23/D-24's lint copies;
  CHECK A is the direct precedent for reference resolution, CHECK D for no-raw-literals
- `hypr/.config/hypr/scripts/keybind-doctor` — its path-argument self-test hook is the
  precedent D-28 reuses
- `hypr/.config/hypr/scripts/quickshell-doctor` — the per-screen check at lines ~394–448 that
  must go green (or become D-14's documented SKIP)
- `quickshell/.config/quickshell/shell.qml` and `modules/Probe.qml` — D-12's fan-out and
  D-15's inspector both modify these; D-32 fixes the order
- `wleave/.config/wleave/style.css` — D-19's retrofit target; read the comment block at
  lines ~470–520 explaining the existing `md3_decel` hand-copy
- `stow.sh` — the seed-when-absent idiom at lines 112–120 that D-30 mirrors; the first-boot
  `theme-apply` seed at line 135
- `matugen/.config/matugen/config.toml` — gains the QML JSON palette render target (D-11)

</canonical_refs>

<code_context>
## Existing Code Insights

### Verified facts (checked against installed binaries during discussion — do not re-derive)

**Hyprland 0.56.0 config semantics** (all via `Hyprland --verify-config`, no session touched):

| Construct | Result |
|---|---|
| `source =` **inside** an `animations { }` block | **FAILS** — "Unclosed category at EOF" then "Stray category close". `source` parses the file as its own document; it is not a lexical include |
| Top-level `source =` of a fragment that wraps its own `animations { }` | **CLEAN** |
| Two `animations { }` blocks | Parses CLEAN — *last-wins at runtime is NOT provable this way* |
| `enabled = $var` (var defined earlier) | **CLEAN** |
| `animation =` referencing a bezier defined in a **later** block | **FAILS** — "no such bezier". **Curves must precede use** |
| `animation =` referencing a nonexistent bezier | **FAILS** — "no such bezier" (loud, not silent) |
| `enabled = $undefined_var` | **FAILS** — "cannot parse as an int" |
| `source =` a missing file | **FAILS** — "globbing error: found no match" |
| `animations { }` with no `enabled` key | **CLEAN** — defaults on |

- **Roadmap open question #3 answered: plain `bezier =` is live and correct on 0.56.0.** All
  12 curves from `animations.conf` are registered. No migration to Lua `hl.curve(...)`.
- **`hyprctl animations -j` is well-formed and `jq`-parses cleanly** — unlike
  `hyprctl binds -j`, which Phase 11's D-14 abandoned as field-misaligned. Record this so
  nobody assumes `-j` is broken across the board on 0.56.0.
- Its element `[1]` carries `name, X0, Y0, X1, Y1` — exactly what D-02's readback needs.
  Element `[0]` lists all 35 animation slots with `overridden`, `bezier` (by name), `speed`,
  `style`, `enabled`.
- **Overshoot survives intact:** `bounce` reads back `Y0: 1.60`, `smoothOut` reads back
  `Y1: -0.56`. Control points outside [0,1] are not clamped, so MD3 Expressive overshoot
  curves render natively.
- Hyprland `speed` is a float that reads back `5.00` where the config says `5` — **the unit
  (apparently deciseconds) still needs binary confirmation** before D-09's conversion is
  written.

**GTK toolkits:**

| | GTK4 4.22.4 | GTK3 3.24.52 |
|---|---|---|
| CSS custom properties (`--x` / `var(--x)`) | **Yes** — `gtk_css_custom_property_pool_unref`, `ruleset->custom_properties` | **No** — no implementation present |
| `cubic-bezier`, `transition-duration`, `transition-timing-function` | Yes | Yes |
| `@define-color` | Present but **deprecated** (`GTK_CSS_PARSER_WARNING_DEPRECATED`) | Present |

- **Roadmap open question #2 is moot, not unresolved.** GTK4 `linear(<stops>)` is never
  needed — `cubic-bezier` works and carries overshoot (`wleave/style.css:230` uses
  `cubic-bezier(0.55, 0, 0.28, 1.68)` live today). PROJECT.md's "GTK4 takes sampled
  `@keyframes`" entry was written for spring curves and no longer applies.
- GTK4 motion tokens can therefore be genuine CSS custom properties, making the lint's
  definition of compliant crisp: no raw duration or timing-function literal; it must come
  through `var(--motion-*)`.

**Quickshell 0.3.0-2:**
- Latest in `extra` and installed — no upstream fix to wait for (D-12).
- `Quickshell/Singleton 0.0` is exported by the installed `quickshell-core.qmltypes` — a
  repo-authored singleton needs no `pragma Singleton` and no `qmldir` (D-11).
- **No `qmldir` file exists on disk** in `quickshell/.config/quickshell/modules/` — quickshell
  synthesises one by scanning, which is precisely where FM1 lives (D-12).

**matugen 4.1.0:**
- `--import-json` / `--import-json-string` exist ("Imports a json file to use as render
  data"), and the config struct carries `import_json_files` and `custom_colors`. So riding
  matugen for motion was genuinely viable — D-01 rejected it on other grounds, not
  capability.

**Motion values currently hand-authored in the repo:** wleave 30, waybar 31, swaync 6,
swayosd 0, walker 0, ags 0. Hyprland: 12 beziers + 14 `animation =` lines.

### Reusable Assets
- **`font.sh`** — the theme-orthogonal axis pattern `motion.sh` copies wholesale (D-01).
- **`waybar-design-lint`** — a separate rerunnable script that `theme-doctor` folds in with a
  SKIP guard (line 475), report-only, non-zero exit on any FAIL. The motion lint takes this
  exact shape. Its CHECK A (reference resolution) and CHECK D (no raw literals) are the two
  direct analogues.
- **`keybind-doctor`'s path-argument self-test hook** — already exists for pointing a gate at
  a poisoned fixture (D-28). No new mechanism needed.
- **`theme-stress-test`'s 10 consecutive switches** — built for the works-once-then-degrades
  failure class; D-17 folds the live re-colour assertion into it.
- **`contract.json`** — the manifest pattern PROJECT.md credits with preventing
  checker/renderer drift; D-29 extends it to engine-owned state.
- **`stow.sh`'s seed-when-absent idiom** (lines 100–120) — D-30 mirrors it.

### Established Patterns
- Generated/runtime output lives under `~/.local/state/`, never in git; `git status` staying
  clean after theme operations is an enforced invariant.
- Every state axis holds a **human-readable name**, never a number (`current-theme`, `mode`,
  `font-choice`) — D-21 follows this.
- Rerunnable gate scripts are the repo's standard "prove it stays true" mechanism;
  `theme-doctor`, `theme-parity`, `theme-stress-test`, `keybind-doctor`,
  `waybar-equivalence-check`, `waybar-design-lint`, `quickshell-doctor`. The motion lint is
  the eighth.
- Every picker in the repo is a walker list picker; there is no slider primitive anywhere in
  the stack (D-21, D-07).
- Zero hex literals in repo-authored stylesheets; every themed surface reads from
  `~/.local/state/theme/`. D-11 extends this to QML.

### Integration Points
- `generate.sh` `theme_engine_generate` ← `motion.sh`'s render call (third sibling writer)
- `contract.json` ← three motion `files` entries + `engine_owned_files` array
- `commit.sh` ← `--exclude` flags built from `engine_owned_files`
- `hyprland.conf` ← motion `source =` line, placed **before** `animations.conf`
- `animations.conf` ← `enabled = $motion_enabled`
- `gtk.sh` ← `enable-animations` in the existing GSettings block
- `matugen/config.toml` ← QML JSON palette render target
- `theme-doctor` ← readback check + motion-lint fold
- `theme-parity` ← byte-identity assertion
- `theme-stress-test` ← live re-colour assertion
- `stow.sh` ← seed-when-absent for motion files
- `quickshell/modules/` ← checked-in `qmldir`, `Colours.qml`, inspector rewrite of `Probe.qml`

</code_context>

<specifics>
## Specific Ideas

- **"The probe never being pretty is a feature"** survives — but through *diagnostic
  content*, not through refusing colour. The token inspector must read unmistakably as an
  instrument (D-15).
- **The lint must not manufacture the failure it cannot see.** A no-raw-values check that
  pushes authors toward token references, without verifying those references resolve, makes
  silent breakage more likely than before (D-24).
- **A gate everyone knows is red is a gate nobody reads** — hence D-14's documented SKIP over
  a standing FAIL.
- **Fidelity was an explicit user concern.** The answer that settled D-11: transport format
  has no effect on colour precision, but it decides whether a theme switch can *animate*.
  In a milestone whose subject is a motion language, an un-animatable theme switch is a real
  fidelity loss.
- **Verify against the binary, do not reason about it.** This discussion resolved two of the
  phase's three open questions and eight Hyprland config semantics empirically, and one test
  (`source =` inside a block) overturned a recommendation that had already been made. Keep
  doing this.

</specifics>

<deferred>
## Deferred Ideas

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

</deferred>

---

*Phase: 12-Unified Design-Token Pipeline*
*Context gathered: 2026-07-26*
