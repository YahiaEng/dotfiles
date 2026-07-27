# Phase 13: Motion Retrofit & Existing-Surface Sweep - Research

**Researched:** 2026-07-27
**Domain:** Cross-toolkit motion-token retrofit (Hyprland `bezier=`/`animation=` DSL, GTK3 CSS via a
new dart-sass precompile step, GTK4 CSS custom properties already wired in Phase 12) plus three
carried-in maintenance items (Phase 4 advisory fixes, icon-theme browse/install, `current.jpg`
untracking).
**Confidence:** HIGH for everything binary-verified on this machine this session (`[VERIFIED]`
below); MEDIUM for primary-source-cited MD3/Hyprland-wiki claims (`[CITED]`); LOW only where
flagged `[ASSUMED]` in the Assumptions Log.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

38 decisions (D-01..D-38) are locked in `13-CONTEXT.md`. This research does not re-litigate any
of them; it fills the specific gaps `<research_priorities>` and the D-10/D-11 blocking item
flagged. The full decision text is long (13-CONTEXT.md, `<decisions>` section, ~480 lines) — the
planner MUST read `13-CONTEXT.md` in full, not just this excerpt. Decisions this research
directly informs or corrects are quoted/summarized below; every other decision (D-02, D-06, D-08,
D-14..D-27 non-motion items, D-30..D-38) stands as written in `13-CONTEXT.md` unchanged by
anything found this session.

**D-01 (GTK3 sass precompile mechanism):** Repo authors `.scss`; `motion.sh` emits a
`_motion.scss` partial; `theme-apply` compiles into `~/.local/state/theme/`; surfaces launch
pointed there via existing style-path flags. **This research adds a load-bearing correction
CONTEXT.md did not anticipate: the repo's existing waybar/swaync `.css` files also require a
non-trivial content rewrite (the `#{"@name"}` interpolation escape, Pitfall 1) before they will
compile at all — this is not merely a rename.**

**D-03/D-04 (colour stays a live `@import url()`; file-for-file compile, import graph
survives):** Confirmed mechanically sound — `dart-sass` passes `@import url()` through
byte-for-byte untouched (Pitfall 3) — but the relative paths inside those imports must be
authored correct for the OUTPUT location, since sass does not rewrite them itself. D-04's phrase
"rewritten sibling-relative" is achieved by the human editing the `.scss` source, not by any
sass feature.

**D-07 (`layersIn`/`layersOut` split):** Verified CLEAN via `Hyprland --verify-config`
(unchanged, per CONTEXT.md). This research adds a primary citation for the tree-inheritance
model (Open Question 2) and confirms `motion.json`'s `emphasized-in`/`emphasized-out` semantic
pairs are the correct consumers.

**D-09 (MD3 purity — 5 character curves REPLACED, not promoted; D-11's namespaced non-MD3
extension is pre-authorized but not default; D-12: soak rejection re-tunes WITHIN MD3, never
reverts):** Stands. This research's primary-sourced MD3 table (State of the Art) is the
evidence base D-09/D-11/D-12 were written to require.

**D-10 (BLOCKING — easing scale grows to the full MD3 set, primary-sourced, cited in
13-RESEARCH.md):** **Satisfied by this document.** See State of the Art for the full table with
per-token primary citations.

**D-11 (namespaced non-MD3 extension pre-authorized; MD3 Expressive overshoot is spring physics,
not beziers):** **Resolved — confirmed by primary source, not just corroborated.** Every MD3
bezier control point retrieved this session is within `[0,1]`; no overshoot exists in the bezier
vocabulary. D-11's extension is the correct, and only, sanctioned home for D-09's deleted
overshoot character.

**D-13 (Hyprland `speed` unit confirmed by extreme-value observation before the duration
conversion is written):** Stands as the required instrument. This research adds a primary
citation (`wiki.hypr.land`: "`speed` is the amount of ds (1ds = 100ms)") that gives the observer
a documented value to falsify against, rather than a total unknown.

**D-15 (token mapping — swaync trivial; waybar's real vocabulary; blink pulses excluded):**
Stands unchanged. Note swaync's stylesheet also carries the same `@name`-interpolation
requirement as waybar (Pitfall 1) — its 6 literals are simple, but the file as a whole still
needs the escape treatment wherever it references colour by `@name` (at least 19 such
references found this session).

**D-23 (`current.jpg` untracked, gitignored, seeded at install):** Stands unchanged; not
touched by this research beyond confirming `wallpaper.sh:65`'s `ln -sfr` mechanism via direct
file read.

**D-29 (WR-04 verified empirically before being wrapped or documented):** This research supplies
the required test design (Pitfall 5) but explicitly does NOT run it — it is destructive to the
live session and must execute as a human-supervised checkpoint task inside the plan, not during
research.

**D-37 (fixed ordering spine — MD3 sourcing BEFORE the Hyprland retrofit, Hyprland retrofit +
A/B toggle FIRST, sass mechanism before waybar/swaync conversions, `current.jpg` untrack before
the 10/10 stress test, stress test + `motion-lint --no-pending` + soak verdict as closing
gates):** Stands unchanged and is now unblocked — D-10's prerequisite MD3 sourcing is satisfied
by this document, so the plan may proceed to the Hyprland retrofit as D-37's first step.

### Claude's Discretion

(Verbatim from `13-CONTEXT.md`)

- Filenames and state-dir layout for the compiled stylesheets and the `_motion.scss` partial.
- How `waybar-design-lint`'s CHECK A (`@name` colour-reference resolution) is taught to parse
  `.scss` sources. **Research note: CHECK A's regex (`@([A-Za-z_][A-Za-z0-9_-]*)`) will
  misidentify Sass directives (`@use`, `@forward`, `@mixin`, etc.) as unresolved colour tokens if
  run against raw `.scss` source — either extend its `AT_RULE_KEYWORDS` set with the Sass
  directives actually used in the partial-consumption pattern (`@use`, at minimum), or run CHECK
  A against the COMPILED `.css` output instead of the `.scss` source (simpler, and the compiled
  output is what actually reaches GTK3 — arguably the more correct target regardless).**
- Exact semantic token names added under D-15, and how the blink pulses are represented outside
  the semantic layer.
- Plan and wave decomposition within D-37's stated ordering constraints; granularity is
  `coarse` in `.planning/config.json`.
- The concrete session/interaction count that constitutes D-19's soak floor.
- Cache layout and "fetching…" presentation for D-28's preview extraction.
- Whether `motion-lint --no-pending`'s pending-detection is a reason-string pattern or a
  structured field on each exemption entry.

### Deferred Ideas (OUT OF SCOPE)

(Verbatim from `13-CONTEXT.md`)

- In-surface client-side motion for walker (selection highlight), SwayOSD (fill bar) and the
  AGS media card (transport state) — deferred to Phase 14.
- Per-namespace `layerrule` style vocabulary (notifications `slide`, OSD `fade`, menus `popin`)
  — available on demand, added only if a render gate says a surface reads wrong (D-07).
- Graphical motion-scale picker (`font-switcher.sh` shape) plus its Super-key settings menu
  entry — carried from Phase 12's D-07. Still not taken up here.
- `@define-color` is deprecated in GTK4 4.22.4 — migrating the colour pipeline to CSS custom
  properties is real tech debt, still out of scope (carried from Phase 12).
- The container-tier D-34/D-36 reproducibility rerun — explicitly NOT folded into MAINT-02's
  proof (D-30). Deferred a third time.
- Wholesale segregation of engine-owned state into its own subdirectory — carried from Phase
  12's D-29; belongs in a maintenance pass.
- A real second-display hotplug test — carried from Phases 11 and 12.
- Restoring the pre-retrofit character curves — foreclosed by D-12 within this phase, but the
  numbers exist in git history (`animations.conf` before this phase's first commit) should the
  MD3 result prove unsatisfying long after the soak.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| MOTION-01 | Hyprland window, workspace and layer animations use the shared curve set rather than hand-tuned one-off beziers | Primary-sourced full MD3 easing table (State of the Art) unblocks D-10; Hyprland `speed`-unit citation and tree-inheritance citation support D-13/D-07; `layerrule` field-grammar facts already verified in CONTEXT.md are unchanged |
| MOTION-02 | waybar, swaync, walker, SwayOSD, wleave and the AGS media card all animate from the shared motion tokens | Pitfalls 1-4 give the concrete, verified mechanics (and the real per-file rewrite cost) for the sass precompile step D-01 specifies; walker/SwayOSD/AGS already covered per D-06 (compositor-owned, zero client change) |
| MOTION-03 | Every retrofitted surface passes a blocking human render-and-look gate before its plan closes | Not directly researched (D-17 already fully specifies the gate mechanism/instrument); this document's Pitfall findings inform what a fidelity gate should specifically look for (e.g. a compiled sheet GTK3 silently rejected due to `@charset`, Pitfall 2, would visibly fail the render gate as "surface looks unstyled") |
| MAINT-02 | Phase 4 advisory items closed — fisher bootstrap `curl` gains `-f`, nvm first-run error noise silenced, uv env source guarded in `.zshrc`, Logout wrapped like Shutdown/Reboot | WR-01/02/03's exact current-file line content re-confirmed via direct read this session (fish/config.fish, .zshrc); WR-04/D-29's required empirical test is fully designed (Pitfall 5) — mechanism facts (`uwsm stop` vs `hyprshutdown`) primary-cited from installed package docs |
| MAINT-03 | The icon-theme picker browses and installs new icon themes from the repos/AUR, not only applying already-installed ones | `pacman -Sp`/`curl`/`bsdtar` fetch-and-extract path verified working end-to-end against a real, non-installed package; AUR fallback verified via `paru -Si`; icon-theme directory-convention divergence discovered and documented (Pitfall 6); existing live-apply mechanism (`lib/gtk.sh theme_engine_apply_icon_theme`) confirmed already shipped, meaning MAINT-03 only needs to feed a newly-installed name into it |
</phase_requirements>

## Summary

CONTEXT.md already locked 38 decisions (D-01..D-38) with rationale. This research does not
re-litigate any of them — it answers the specific open questions `<research_priorities>` and
the phase-blocking `<phase_critical_research_blocker>` flagged, using the repo's own house rule
("verify against the installed binary, do not reason about it") wherever a tool existed to do
so on this machine, and a primary web source (Flutter/`material-components-android`, both
Google-maintained implementations of the Material 3 spec, per D-10's allowed source list) for
everything that could not be verified locally.

**D-10's blocking deliverable is satisfied: a primary-sourced full MD3 easing table is below,
every one of the four base easings currently in `motion.json` is confirmed byte-identical to
the primary source, and `motion.json`'s existing 16-entry duration scale is independently
confirmed to already be the complete MD3 duration set (Flutter's own `Durations` class matches
it number-for-number) — D-10 only required growing the *easing* layer.**

**D-11 is resolved: every MD3 easing curve retrieved from primary source data — Standard,
Standard Decelerate, Standard Accelerate, Emphasized (a two-segment `ThreePointCubic`, not a
single 4-number bezier), Emphasized Decelerate, Emphasized Accelerate, Legacy, Legacy
Decelerate, Legacy Accelerate, Linear — has every control-point coordinate inside `[0, 1]` on
both axes. None contain overshoot or undershoot. This corroborates D-11's working hypothesis
with a primary source rather than a guess: MD3's *bezier* easing vocabulary is overshoot-free by
construction; the overshoot D-09's five deleted character curves carried is a Material 3
Expressive *spring-physics* concept (secondary-sourced below, `[CITED]`, not independently
primary-confirmed — consistent with `12-MOTION-VERDICT.md`'s own finding that the Compose
`MotionScheme.kt` spring constants were unreachable through any tool available last phase
either). D-11's pre-authorized namespaced non-MD3 extension is therefore the only place D-09's
overshoot/undershoot character can legally live going forward.**

Five findings materially change what the planner must write, beyond what CONTEXT.md already
decided:

1. **`dart-sass` hard-fails on compile — not silently, a nonzero exit with `Error: Expected
   expression.` — every time it hits GTK-CSS's `@name` colour-value-reference syntax**
   (`color: @capsule-fg;`, `alpha(@primary, 0.25)`), because in Sass grammar `@` at the start of
   an expression is always parsed as a directive keyword, never a plain token. **waybar's six
   files carry roughly 289 of these references** (`theme.css` alone: 116; `style-athena.css`:
   45; `style-floating.css`: 53; `style-vertical.css`: 38; `waybar-modules.css`: 34;
   `style-full.css`: 3) and swaync's `style.css` carries at least 19. D-04's framing — "the only
   thing that changes is *where the files live*" — undersells this: **every `@name` value
   reference in all six waybar files and swaync's stylesheet must be rewritten to
   `#{"@name"}` interpolation syntax** (verified working, see Pitfall 1) before `dart-sass` will
   compile them at all. This is real, mechanical, per-file work the plan must size and task
   explicitly — it was not identified during discussion.
2. **`dart-sass`'s default output breaks GTK3 outright: a leading `@charset "UTF-8";` causes
   GTK3's `CssProvider` to discard the ENTIRE stylesheet**, not just that line — directly
   reproduced with `Gtk.CssProvider` on this machine (Pitfall 2, with a same-methodology control
   proving cause/effect). This is exactly the WLOG-01 "whole-stylesheet-discard failure class"
   this repo already has a name for. The fix is one flag: invoke `sass` with `--no-charset`
   (and `--no-source-map`, for a second, independent reason below).
3. **`dart-sass` does NOT rewrite relative paths inside `@import url(...)`** — verified by
   compiling a real waybar-shaped source into a different output directory and diffing;
   the three lines came through byte-for-byte unchanged. D-04's "`@import url()` links
   rewritten sibling-relative" is not something sass provides — **the `.scss` source content
   itself must already be written with paths correct for the eventual state-dir output
   location**, which differs from today's stowed-symlink-relative paths (e.g.
   `../../.local/state/theme/waybar-font.css` must become the bare filename `waybar-font.css`
   once the compiled output itself lives inside that same state directory as a sibling).
4. **Legacy `@import "partial";` (bare, no `url()`) triggers a Sass 3.0 deprecation warning on
   every compile; `@import url("...")` never does.** Verified: the colour-import lines (D-03)
   stay silent; a bare partial import is not. **The `_motion.scss` partial must be consumed via
   `@use "motion" as m;`**, not `@import "motion";` — verified clean (zero warnings, correct
   values resolved) with a `--load-path` pointed at the partial's directory.
5. **Hyprland's `speed` unit IS documented as deciseconds by a primary source** — the current
   Lua-config wiki page states verbatim: *"`speed` is the amount of ds (1ds = 100ms) the
   animation will take. For example `speed = 1` = 100ms."* This is a **primary citation
   D-13 did not have** (CONTEXT.md's own finding was "no string in the Hyprland binary states
   the unit"). D-13's extreme-value observation is still required as the *falsifiability*
   instrument (a doc claim is not the same class of proof as a stopwatch), but the planner now
   has a documented value to falsify against rather than a total unknown — see the D-13 test
   design below.

**Primary recommendation:** source the full MD3 easing table from the citations below and add it
to `motion.json` verbatim (Task 1 of the first plan, ahead of the Hyprland retrofit per D-37);
budget explicit, separately-tracked effort for the `@name`-interpolation rewrite across all six
waybar files and swaync's stylesheet before believing D-04's "file-for-file, nothing else
changes" framing; invoke every `sass` compile with `--no-charset --no-source-map`; and treat the
`uwsm stop` empirical test (D-29) and the Hyprland extreme-speed observation (D-13) as
human-supervised checkpoint tasks — both are destructive-if-wrong to the live session and must
not be run outside a task the user is watching.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Hyprland window/workspace/layer animation curves | Compositor (Hyprland) | — | `animation =`/`bezier =` lines are parsed and executed entirely inside the compositor process; no client participates |
| GTK3 surface motion (waybar, swaync) | Build-time precompile (dart-sass) → GTK3 client runtime | Theme engine (render orchestration) | GTK3 has no CSS custom-property mechanism (Phase 12 binary-verified), so the token→literal resolution must happen at compile time, not client runtime |
| GTK4 surface motion (walker, SwayOSD's stylesheet if ever retrofitted, quickshell) | GTK4 client runtime (`:root` custom properties) | Theme engine (render) | Already wired in Phase 12; GTK4 natively resolves `var(--motion-*)` at paint time, live-reloadable |
| Layer-shell surfaces with zero CSS motion (walker, SwayOSD, AGS media card) | Compositor (Hyprland `layerrule`/`animation = layers`) | — | D-06: these surfaces have never owned their own motion; the compositor's layer animation is already their sole motion source |
| Motion token single source of truth | Theme engine (`motion.json` + `motion.sh`) | — | Unchanged from Phase 12; this phase adds a fourth render target (sass partial) to the same generator, never a second source |
| Icon-theme package install (MAINT-03) | Install-time (`pacman`/`paru`, user-invoked from a live picker) | GSettings/theme-engine apply (existing, live) | Installing is a one-shot filesystem/package-database mutation; applying live already exists in `lib/gtk.sh`'s `theme_engine_apply_icon_theme` (Phase 5/6 era) — MAINT-03 only needs to feed a newly-installed name into that existing pipeline |
| Session teardown grace (MAINT-02/WR-04) | Session manager (`uwsm`) + optional pre-close UI (`hyprshutdown`) | Hyprland (actual client disconnect) | `uwsm stop` only stops the systemd unit hosting the compositor; any "ask clients to close first" behaviour is `hyprshutdown`'s job, not `uwsm`'s — see Pitfall 5 |
| `current.jpg` tracked-file elimination (D-23) | Filesystem / git (`.gitignore` + `stow.sh` seed) | `wallpaper.sh` (unchanged writer) | Pure repo-hygiene fix; no runtime component changes behaviour, only where the symlink target's git status lives |

## Standard Stack

### Core (already installed, verified on this machine)

| Tool | Version (installed) | Purpose | Confidence |
|------|---------|---------|--------------|
| dart-sass | 1.102.0 (`/usr/bin/sass`) | Motion-token precompile for GTK3 surfaces (D-01) | `[VERIFIED: sass --version]` |
| Hyprland | 0.56.0 | Compositor; legacy `hyprlang` `animation =`/`bezier =` syntax still accepted (deprecated but functional per the wiki's own note) | `[VERIFIED: Hyprland --verify-config, prior phases]` |
| uwsm | 0.26.6 (`/usr/bin/uwsm`) | Session manager; `uwsm stop` is the live Logout action | `[VERIFIED: uwsm --version]` |
| hyprshutdown | 0.1.1-4 (official `extra`, optional-for `hyprland`) | Graceful pre-close UI + `--post-cmd`, currently wired to Reboot/Shutdown only | `[VERIFIED: pacman -Qi hyprshutdown]` |
| bsdtar (libarchive) | 3.8.8 | Extract fetched-not-installed icon-theme packages for MAINT-03 previews | `[VERIFIED: bsdtar --version]` |
| paru | (installed, path resolved) | AUR helper for icon themes not in official repos | `[VERIFIED: which paru; paru -Si <pkg>]` |
| jq | (already a hard dependency throughout theme-engine) | Every `motion.sh`/`contract.sh` JSON operation | pre-existing, unchanged |
| python3 + PyGObject (`gi`) | system python3, `Gtk 3.0` importable | Used THIS SESSION to empirically prove the `@charset` whole-stylesheet-discard failure (Pitfall 2) — not itself part of the shipped pipeline, but confirms `motion-lint`'s Python implementation has a working GTK3 test harness available if the planner wants a repeatable regression check | `[VERIFIED: python3 -c "import gi; ..."]` |

No new packages are introduced by this phase's own mechanism (D-01's sass step reuses an
already-hard `install.sh` dependency; MAINT-03 installs icon themes chosen at **runtime** by
the user, not pinned at plan time — see Package Legitimacy Audit below for how that dynamic
install path should be gated instead).

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `#{"@name"}` interpolation escape for GTK-CSS `@name` value refs | Rewriting waybar/swaync to stop using `@name` value syntax, switching to CSS custom properties (`var(--name)`) fed by the *already-existing* Phase 12 GTK4 pipeline | Not available: waybar/swaync are GTK3, which has no `var()` support at all (the exact reason D-01 exists). The interpolation escape is the only option that does not also require rebuilding the colour pipeline this phase explicitly keeps unchanged (D-03) |
| `sass --no-charset --no-source-map` | Post-processing the compiled `.css` with `sed` to strip `@charset`/sourcemap comment after the fact | Strictly worse: adds a second tool/step for something the compiler already does natively via two flags; more surface for `theme_engine_generate` to fail on |
| `@use "motion" as m;` for the partial | `@import "motion";` (legacy) | Legacy `@import` of a bare partial triggers a Sass 3.0 deprecation warning on every `theme-apply` run — noisy stderr the plan explicitly wants to avoid polluting `GENERATE_LOG`/notifications with |

## Package Legitimacy Audit

This phase does not pin any new package name into a manifest, install script, or lockfile —
`dart-sass` is already an existing, in-use, verified-installed hard dependency (`install.sh:206`,
unchanged), and MAINT-03's icon-theme packages are chosen interactively at **runtime** from the
live `pacman -Ss`/AUR catalogue, not enumerated here. The correct gate for MAINT-03 is therefore
not a static audit table but a **behavioural** one the plan must implement in the picker itself:

| Requirement for the picker (not a static package list) | Why |
|---|---|
| Official-repo entries (`pacman -Ss`) need no extra vetting — they are Arch's own signed, mirrored packages | Same trust boundary `install.sh` already extends to every other official-repo package in this repo |
| AUR entries must go through the already-resolved `paru`/`yay` helper (`install.sh:304-317`), never a raw `git clone && makepkg` the picker invents itself | Reuses the one AUR trust/build path this repo already has; a second bespoke AUR-fetch path would be a second attack surface with no offsetting benefit |
| `paru`'s build/install prompts must be allowed to surface in the real terminal the picker launches from (a floating kitty, per D-27) — never `--noconfirm`'d away for an install the user did not review | D-27: "Build failures surface loudly by construction — the floating kitty is a real terminal, so `paru` prompts and streams output normally." A silent AUR install of arbitrary user-chosen PKGBUILDs would be the actual security regression here, not a missing static audit table |
| Preview fetches (`pacman -Sp` + `curl` + `bsdtar`) must extract into a throwaway temp dir, never `/` or a path outside the cache, and must not execute anything from the package (`.INSTALL` hooks, `post_install` scripts) — extraction only, no install | ASVS V12 (File and Resources) / this repo's Security Domain V5 discipline, extended to a new fetch-and-extract code path |

**Packages removed due to `[SLOP]` verdict:** none (no packages were statically proposed this
session for `package-legitimacy check` — the install targets are runtime-chosen).
**Packages flagged as suspicious `[SUS]`:** none pinned; the picker itself is the ongoing
verification mechanism, and the plan should add a `checkpoint:human-verify` before the FIRST
live AUR install exercised during this phase's own execution (a real AUR icon theme, e.g.
`tela-icon-theme-git`, confirmed resolvable via `paru -Si` this session).

## Architecture Patterns

### System Architecture Diagram

```
                    ┌─────────────────────────┐
                    │      motion.json          │   <- SOLE source of every
                    │ (durations + easings +    │      duration/control-point
                    │  semantic pairs + scales) │      number (D-05, unchanged)
                    └────────────┬───────────────┘
                                 │  theme_engine_render_motion_files()
                    ┌────────────┼───────────────┬────────────────────┐
                    ▼            ▼               ▼                    ▼
          hyprland-motion.conf  gtk-4.0-motion.css  motion.json   [NEW] _motion.scss
          (bezier= lines,       (:root custom       (QML target,  partial (D-01) —
           motion-* prefixed)    properties)          unchanged)   sass variables,
                    │            │                                 same numbers
                    │            │                                       │
   ┌────────────────┘            │                          ┌────────────┘
   ▼                             ▼                          ▼
animations.conf            walker/SwayOSD/AGS         waybar/*.scss, swaync/style.scss
(D-09 tokenized             (already GTK4, live        (repo-authored; @use the partial;
 curves; layersIn/          var() resolution,           GTK-CSS @name refs wrapped in
 layersOut split, D-07)     zero client change)         #{"..."} interpolation, Pitfall 1)
                                                                    │
                                                          sass --no-charset --no-source-map
                                                          (Pitfall 2/inside theme_engine_generate,
                                                           D-34 — tmp tree, atomic commit)
                                                                    ▼
                                                    ~/.local/state/theme/{waybar,swaync}/*.css
                                                    (flat siblings; @import url() to colour +
                                                     waybar-font.css/waybar-visibility.css now
                                                     BARE filenames, not ../../-relative — Pitfall 3)
                                                                    │
                                                          waybar -s / swaync -s <path>
                                                          (existing flags, D-05 stow-seed
                                                           required or first boot ships unstyled)
```

### Recommended precompile invocation shape (D-01, D-34)

```bash
# Inside theme_engine_generate(), a fourth sibling writer alongside
# theme_engine_render_{font_files,gtk_settings} and motion.sh's own renderer.
# Renders into the tmp tree so a failed compile commits nothing (D-34).
sass --no-charset --no-source-map \
     --load-path="$tmp$STATE_DIR" \
     "$WAYBAR_SRC_DIR/style-athena.scss" "$tmp$STATE_DIR/waybar/style-athena.css" \
  || return 1   # propagate failure exactly like motion.sh's render step does today
```

### Pattern 1: GTK-CSS `@name` value references must be interpolation-escaped for sass
**What:** Every `color: @name;`, `background: @name;`, `alpha(@name, N)` value in waybar's
six files and swaync's stylesheet is invalid standalone SassScript (`@` starts a directive in
Sass's grammar, and none exist in expression position). Wrap the ENTIRE value string:
```scss
/* before (valid GTK3 CSS, invalid Sass): */
color: @capsule-fg;
border: 1px solid alpha(@primary, 0.25);

/* after (compiles cleanly, byte-identical output): */
color: #{"@capsule-fg"};
border: 1px solid #{"alpha(@primary, 0.25)"};
```
**When to use:** Any repo-authored `.scss` file that still references a GTK-CSS `@name` (this
phase deliberately keeps colour on the `@name`/`@import url()` mechanism per D-03 — this pattern
is what lets that mechanism coexist with a sass compile step, not a replacement for it).
**Verified:** `[VERIFIED: sass --no-charset --no-source-map, this session]` — direct compile
of both forms; the escaped form produces output byte-identical to the original GTK-CSS.

### Pattern 2: `@use`, never `@import`, for the `_motion.scss` partial
```scss
// _motion.scss (engine-emitted into the state dir, D-01)
$motion-duration-standard: 200ms;
$motion-easing-standard: cubic-bezier(0.2, 0, 0, 1);

// style-athena.scss (repo-authored)
@use "motion" as m;
.foo {
  transition: opacity #{m.$motion-duration-standard} #{m.$motion-easing-standard};
}
```
Compile with `--load-path` pointed at the partial's directory (verified: without it, sass fails
with `Error: Can't find stylesheet to import.`; with it, resolves and emits literal values with
zero deprecation warnings).
**Verified:** `[VERIFIED, this session]` — clean compile, zero stderr output, both against a
throwaway `--load-path` and against the legacy bare `@import` form (which DID emit a Sass 3.0
deprecation warning on the identical partial).

### Anti-Patterns to Avoid
- **Renaming `.css` → `.scss` without content changes and expecting it to compile:** waybar's
  and swaync's real stylesheets are NOT valid Sass as they stand today (Pattern 1's `@name`
  syntax). A bare rename will fail loudly at `theme_engine_generate` time on the very first
  affected line — budget the interpolation rewrite as real work, not a rename.
- **Trusting `dart-sass` to fix up relative `@import url()` paths across the repo→state-dir
  move:** it will not (verified, Pitfall 3). Write the compiled-output-relative path directly
  in the `.scss` source.
- **Reaching for a spring-physics escape hatch to recover D-09's deleted overshoot curves
  inside the *default* MD3 set:** primary-sourced data below shows the MD3 bezier vocabulary
  has no overshoot at all — D-11's pre-authorized *namespaced, non-default* extension is the
  only legitimate landing spot, not a re-interpretation of "full MD3 set."

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| GTK3 icon-theme install verification | A bespoke "is this a real package" heuristic for the picker | `pacman -Si <pkg>` / `paru -Si <pkg>` exit codes, exactly as the picker's existing enumeration already does for other lookups | Both commands already give an authoritative yes/no against the real package databases; a second heuristic on top adds a place to be wrong |
| Icon-theme icon path discovery for previews | A single hardcoded `SIZExSIZE/category/` glob (what the shipped picker's preview script currently assumes) | A two-pattern search — see Pitfall 6, some themes (Papirus) use `SIZExSIZE/category/`, others (elementary, confirmed this session) use `category/SIZE/` | Confirmed empirically on two real, currently-fetchable packages; a single-pattern glob silently produces zero preview icons for the second convention |
| Session-teardown grace for Logout | A bespoke client-enumeration/close loop inside `wleave.sh` or `layout.json` | `hyprshutdown --post-cmd 'uwsm stop'` — the exact mechanism Shutdown/Reboot already use, verified installed and already the FIX-01 precedent | Reinventing "ask clients to close, wait, then proceed" duplicates a maintained, already-adopted tool for no functional gain, and produces a THIRD app-close code path alongside Shutdown/Reboot's |

**Key insight:** Every "don't hand-roll" item in this phase already has a shipped, working
precedent elsewhere in the same repo (the AUR helper, the picker's enumeration discipline, the
hyprshutdown wrapper) — the debt this phase closes is under-application of an existing pattern,
not a missing capability.

## Common Pitfalls

### Pitfall 1: GTK-CSS `@name` value syntax is invalid Sass and fails the WHOLE compile
**What goes wrong:** `sass style-athena.scss out.css` on the file as it exists today (merely
renamed) exits nonzero on the first `color: @capsule-fg;`-shaped line with `Error: Expected
expression.` — the entire compile aborts, not just that rule.
**Why it happens:** In Sass's grammar, `@` beginning a token in expression position is always
parsed as an at-rule keyword; GTK's own CSS dialect overloads `@name` as a value-position colour
reference, a syntax Sass has no concept of.
**How to avoid:** Wrap every such value in `#{"..."}` string interpolation (Pattern 1) — the
entire literal string passes through untouched. Do this as a distinct, budgeted task per file
before attempting the first real compile, not discovered mid-compile.
**Warning signs:** Any `sass` invocation failing with `Error: Expected expression.` pointing at
a line starting with `@` inside a property value (not at the top of a statement).

### Pitfall 2: `dart-sass`'s default `@charset` output makes GTK3 silently discard the WHOLE stylesheet
**What goes wrong:** `sass` emits `@charset "UTF-8";` as line 1 by default. GTK3's `CssProvider`
does not recognise `@charset` as a valid at-rule and — verified directly on this machine with a
controlled A/B test — discards the **entire** stylesheet, not just that line, when it is present.
**Direct verification (this session, `python3` + PyGObject):**
```
control (no @charset, valid rule only): rgb(18,52,86)     # matches the literal #123456 written
with leading @charset + same rule:      rgb(205,214,244)  # falls back to inherited theme colour
                                                            # — the whole sheet was rejected
```
**Why it happens:** GTK3's CSS engine is not a browser engine; it has a narrow, hand-rolled
at-rule vocabulary and does not treat an unrecognised at-rule as ignorable/skippable — matching
this repo's own already-documented WLOG-01 "whole-stylesheet-discard failure class."
**How to avoid:** Always invoke `sass --no-charset` for any GTK3-consumed output (verified clean
with this flag). Pair with `--no-source-map` (a harmless-but-unnecessary `sourceMappingURL`
comment and a stray `.map` file otherwise land in the state dir on every compile).
**Warning signs:** A compiled sheet that "does nothing" with zero errors anywhere in the
pipeline — GTK3 fails this silently (a `parsing-error` signal fires internally, but nothing
propagates to `waybar`/`swaync`'s own stderr by default).

### Pitfall 3: `dart-sass` does not rewrite relative `@import url()` paths for the new output location
**What goes wrong:** A `.scss` source authored in `waybar/.config/waybar/` (today's stowed
location) with `@import url("../../.local/state/theme/waybar-font.css")` compiles to a `.css`
in the state dir with that exact string unchanged — but from the state dir, `../../` now points
somewhere else entirely (or nowhere), because sass treats `@import url(...)` as an opaque,
unresolved string, never touching it.
**Why it happens:** Verified directly: compiled a real waybar-shaped `.scss` into a *different*
directory than its source and diffed — all three `@import url()` lines were byte-identical to
the input, path segments untouched.
**How to avoid:** Author the `.scss` source content with paths already correct for the eventual
**output** location, not the source location. Since D-04 puts every compiled sheet as a flat
sibling inside the same state-dir output directory as `waybar-font.css`/`waybar-visibility.css`
(both already state-dir-resident per `contract.json`), the fix is usually a *simplification*:
`@import url("../../.local/state/theme/waybar-font.css")` becomes the bare
`@import url("waybar-font.css")` once compiled output and those two files are siblings.
**Warning signs:** A compiled sheet that GTK3 rejects with "Failed to import: Error opening
file ..." (verified reproducible: an unresolvable `@import url()` throws a `GLib.Error` from
`Gtk.CssProvider`, matching the repo's own existing comment "an unresolvable @import is not a
soft warning here").

### Pitfall 4: Legacy `@import "partial";` (no `url()`) emits a Sass 3.0 deprecation warning; `@import url(...)` never does
**What goes wrong:** If the `_motion.scss` partial is consumed via `@import "motion";`
(bare, no `url()`), every single `theme-apply` run emits: `DEPRECATION WARNING [import]: Sass
@import rules are deprecated and will be removed in Dart Sass 3.0.0.` to stderr — noise the
render-time `GENERATE_LOG` channel was never designed to filter.
**Why it happens:** Dart Sass distinguishes its OWN `@import` directive (deprecated, slated for
removal in 3.0) from CSS-native `@import url(...)` (always passed through untouched, never
deprecated — verified: the three colour `@import url()` lines in the same test file produced
zero stderr output).
**How to avoid:** Consume the partial via `@use "motion" as m;` with an appropriate
`--load-path`. Verified clean (zero warnings, correct resolved values) this session.
**Warning signs:** `theme-apply`'s render log gaining a repeating deprecation block on every
run, easy to miss since it does not fail the render (Sass treats it as a warning, not an error).

### Pitfall 5: `uwsm stop` and `hyprshutdown` are structurally different mechanisms — bare `uwsm stop` does not "ask clients to close" at all
**What goes wrong (hypothesis to test, not yet empirically confirmed — see D-29 test design
below):** `uwsm`'s own documentation states its `stop` subcommand's job is narrowly "stop the
`wayland-wm@*.service` unit" — systemd then tears down all dependent units in reverse, with
its own (default ~90s) `TimeoutStopSec` before a hard `SIGKILL`. Nothing in that path
specifically asks each Wayland *client* (browser, editor, etc.) to close first. `hyprshutdown`,
by contrast, is documented as showing a dedicated "Shutting down..." UI and explicitly closing
apps *before* exiting Hyprland, then running `--post-cmd`.
**Why it matters for WR-04/D-29:** Reboot/Shutdown already wrap `hyprshutdown --post-cmd
'systemctl reboot|poweroff'`; Logout runs bare `uwsm stop`. If bare `uwsm stop` genuinely leaves
unclosed clients (a text editor with an unsaved-changes dialog, say) hanging inside systemd's
stop-timeout window, Logout has a real hazard Shutdown/Reboot do not. If Hyprland's own
Wayland-server teardown already disconnects every client near-instantly regardless (clients lose
their display connection the moment Hyprland's socket closes, with no opportunity to show a
"save changes?" dialog either way), the practical difference between the two paths may be much
smaller than WR-04 assumed.
**D-29's required test design (do NOT run outside a human-supervised checkpoint — this
terminates the live session):**
1. Launch a disposable, trap-guarded client in a floating window:
   `kitty -e bash -c 'trap "" TERM; echo BLOCKING; sleep 300'`
2. Time `uwsm stop` from a SEPARATE tty/session (e.g. a TTY login, not inside the graphical
   session about to be torn down) and observe: (a) elapsed wall-clock time to return, (b) whether
   the trapped process is still alive afterward (`ps` from the TTY), (c) whether it returns
   quickly (near-instant socket teardown, orphaning the client) or stalls for the full systemd
   stop timeout.
3. Repeat wrapped in `hyprshutdown --dry-run` first (shows the UI, closes nothing, safe) to
   observe whether its own app-close step visibly waits on/force-closes the SAME trapped client
   differently than bare `uwsm stop` did.
This is "the smallest test that can actually fail" per D-29/the D-18/D-28 house rule — a test
that always returns near-instantly regardless of trapped clients would falsify the WR-04 hazard
model outright and justify documenting Logout's exemption instead of wrapping it.
**Confidence:** `[CITED: /usr/share/doc/uwsm/README.md, this session]` for the mechanism
description; the actual empirical stall/no-stall behaviour is explicitly **unverified** —
this is the open question the plan's D-29 task must close.

### Pitfall 6: Icon-theme directory-naming convention is NOT uniform across packages
**What goes wrong:** The shipped `icon-theme-picker.sh`'s preview montage script assumes a
`*/48x48/*` (or generically `SIZExSIZE/category/`) path pattern. Verified this session by
fetching two real, currently-installable packages without installing them:
- `papirus-icon-theme` (already installed): `Papirus/48x48/places/folder.svg` —
  `SIZExSIZE/category/` convention, matches the picker's existing assumption.
- `elementary-icon-theme` (fetched fresh via `pacman -Sp` + `curl` + `bsdtar`, not installed):
  `elementary/apps/48/accessories-calculator.svg` — **`category/SIZE/` convention, inverted.**
**Why it happens:** freedesktop.org's icon theme spec permits either directory ordering; themes
choose independently and there is no universal convention.
**How to avoid:** MAINT-03's fetch-and-preview code must try both glob shapes (or a general
recursive filename-based search bounded by a reasonable size hint) rather than assuming one.
**Warning signs:** A "fetching…" preview that silently renders an empty montage for some but not
all browsed themes.

## Code Examples

### D-13's extreme-value speed observation (design, not yet run — human-supervised checkpoint)
```bash
# Primary source states 1ds = 100ms. An extreme, easily-distinguished value:
# speed = 500 -> if the doc is right, ~50s; if the unit were actually
# centiseconds (10ms), ~5s; if raw milliseconds, ~0.5s. Pick ONE animation
# (e.g. `layers`) via motion-switch's existing preset mechanism or a scratch
# edit, trigger it once (open any layer-shell surface), and time it with a
# stopwatch/phone — not a script, since the point is a HUMAN watching a
# single observable event, per the D-13/D-18 "gate that can fail" discipline.
```

### Full render-target shape after this phase (motion.sh's fourth writer, D-01/D-34)
```bash
# Inside theme_engine_generate(), after the existing three motion.sh writes:
theme_engine_render_motion_scss "$tmp"   # NEW: emits _motion.scss partial
theme_engine_compile_gtk3_stylesheets "$tmp" || return 1  # NEW: sass compile,
                                                             # propagated like
                                                             # motion.sh's own
                                                             # return already is
```

## State of the Art

### The full MD3 easing set (D-10's blocking deliverable) — primary-sourced

Sourced from Flutter's `material` library `Easing` class (`api.flutter.dev/flutter/material/
Easing-class.html`, individual constant pages fetched and quoted verbatim this session) and
cross-checked against `material-components-android`'s own `docs/theming/Motion.md`
(`github.com/material-components/material-components-android`) — both are Google-maintained
reference implementations of the Material 3 specification, matching D-10's allowed source list
("m3.material.io / Material Design spec / Material Components source"). `m3.material.io/styles/
motion/easing-and-duration/tokens-specs` itself is a client-rendered SPA that returned no
extractable data via `WebFetch` this session — the two source-code references below were used
instead, and independently agree with each other everywhere they overlap.

| Token | Cubic-bezier control points | Matches `motion.json` today? | Source |
|---|---|---|---|
| `standard` | `cubic-bezier(0.2, 0, 0, 1)` | **Yes** — `motion.json.easings.standard` | `[VERIFIED: api.flutter.dev/flutter/material/Easing/standard-constant.html — Cubic(0.2, 0.0, 0.0, 1.0)]`, corroborated by `material-components-android` Motion.md |
| `standardDecelerate` | `cubic-bezier(0, 0, 0, 1)` | No — not yet in `motion.json` | `[VERIFIED: Easing/standardDecelerate-constant.html — Cubic(0.0, 0.0, 0.0, 1.0)]` |
| `standardAccelerate` | `cubic-bezier(0.3, 0, 1, 1)` | No — not yet in `motion.json` | `[VERIFIED: Easing/standardAccelerate-constant.html — Cubic(0.3, 0.0, 1.0, 1.0)]` |
| `emphasized` | **NOT a single cubic-bezier** — a two-segment `ThreePointCubic`: segment 1 `(0,0)→(0.05,0)/(0.133333,0.06)→(0.166666,0.4)`, segment 2 `(0.166666,0.4)→(0.208333,0.82)/(0.25,1)→(1,1)` | No — and cannot be represented in `motion.json`'s current 4-number-per-easing schema without a schema extension (see Open Questions) | `[VERIFIED: raw.githubusercontent.com/flutter/flutter — packages/flutter/lib/src/animation/curves.dart, easeInOutCubicEmphasized]`, matching `material-components-android` Motion.md's `M 0,0 C 0.05,0,0.133333,0.06,0.166666,0.4 C 0.208333,0.82,0.25,1,1,1` path exactly |
| `emphasizedDecelerate` | `cubic-bezier(0.05, 0.7, 0.1, 1)` | **Yes** — `motion.json.easings.emphasized-decelerate`, and matches `animations.conf`'s `md3_decel` bezier | `[VERIFIED: Easing/emphasizedDecelerate-constant.html — Cubic(0.05, 0.7, 0.1, 1.0)]` |
| `emphasizedAccelerate` | `cubic-bezier(0.3, 0, 0.8, 0.15)` | **Yes** — `motion.json.easings.emphasized-accelerate`, and matches `animations.conf`'s `md3_accel` bezier | `[VERIFIED: Easing/emphasizedAccelerate-constant.html — Cubic(0.3, 0.0, 0.8, 0.15)]` |
| `legacy` | `cubic-bezier(0.4, 0, 0.2, 1)` | No — not yet in `motion.json` (this is Material 2's "fast-out-slow-in", kept for back-compat) | `[VERIFIED: Easing/legacy-constant.html — Cubic(0.4, 0.0, 0.2, 1.0)]` |
| `legacyDecelerate` | `cubic-bezier(0, 0, 0.2, 1)` | No | `[VERIFIED: Easing/legacyDecelerate-constant.html — Cubic(0.0, 0.0, 0.2, 1.0)]` |
| `legacyAccelerate` | `cubic-bezier(0.4, 0, 1, 1)` | No | `[VERIFIED: Easing/legacyAccelerate-constant.html — Cubic(0.4, 0.0, 1.0, 1.0)]` |
| `linear` | `cubic-bezier(0, 0, 1, 1)` | **No — `motion.json`'s current `linear` is `[1,1,1,1]`, which is Hyprland's OWN `liner` convention, NOT CSS/MD3 linear.** D-11 already flagged this as a corroborating finding; this table confirms it with a primary source. | `[VERIFIED: Easing/linear-constant.html — Cubic(0.0, 0.0, 1.0, 1.0)]` |

**D-11's answer, stated plainly:** every control-point number retrieved above is inside
`[0, 1]`. No MD3 bezier easing — base, legacy, or emphasized-decelerate/accelerate — contains
overshoot or undershoot. The only place overshoot appears in the Material 3 ecosystem is
Material 3 **Expressive**'s *spring* system (mass/stiffness/damping physics, not beziers),
which is `[CITED]` only (see below) — this repo already has direct, first-hand evidence
(`12-MOTION-VERDICT.md`) that even Google's own reference spring constants (`androidx`'s
`MotionScheme.kt`) were unreachable through any tool available last phase, so the same caveat
applies here: D-11's non-MD3 namespaced escape hatch is confirmed as the only sanctioned home
for D-09's deleted overshoot character, and should not be second-guessed as "maybe still
findable in the base MD3 set" — the primary source data says no.

**MD3 Expressive spring physics** (context for D-11, not itself part of the base easing set):
`[CITED: web search summarizing m3.material.io/blog/m3-expressive-motion-theming and
secondary design-system write-ups — the blog's own page content could not be directly fetched
this session (client-rendered), so this is MEDIUM confidence, not HIGH]` — MD3 Expressive's
"Spatial" motion tokens (position/size/shape changes) are spring-driven (stiffness, damping,
initial velocity) and are the documented mechanism for "noticeable overshoot and bounce" in the
newer Expressive scheme; "Effect" tokens (opacity/colour) remain simple, non-overshooting
transitions. This is consistent with, and does not contradict, the primary bezier-table finding
above.

### The full MD3 duration set — already complete, confirmed against a primary source

`motion.json`'s existing 16-entry `durations` table (`short1`=50ms … `extra-long4`=1000ms) is
**already the complete MD3 duration scale** — no change needed. Confirmed against Flutter's own
`Durations` class (`api.flutter.dev/flutter/material/Durations-class.html`), which lists the
identical 16 names and millisecond values, digit-for-digit:
`[VERIFIED: api.flutter.dev/flutter/material/Durations-class.html]`. D-10 only required growing
the *easing* layer — this table confirms the duration layer needs no corresponding change.

### Hyprland's animation `speed` unit — a primary citation now exists

`[CITED: wiki.hypr.land / hyprwm/hyprland-wiki repo, "content/Configuring/Advanced and Cool/
Animations.md", fetched raw this session]` — verbatim: *"`speed` is the amount of ds (1ds =
100ms) the animation will take. For example `speed = 1` = 100ms."* This is the CURRENT wiki page,
which documents Hyprland 0.55+'s newer Lua `hl.animation()` config surface — this repo's
`animations.conf` still uses the older `hyprlang` `animation = NAME, ONOFF, SPEED, CURVE[,
STYLE]` syntax, which the same page notes is "deprecated in favor of lua" (not removed; already
binary-verified functional on 0.56.0 via `Hyprland --verify-config` in Phase 12/13 discussion).
Both syntaxes drive the same underlying `AnimationManager`, so the unit almost certainly applies
identically to both — but D-13 correctly still requires the extreme-value observation as the
falsifiability instrument, since a wiki page describing the newer syntax is a citation, not a
readback of what THIS build's legacy-syntax parser actually does with the number.

The same wiki page also directly answers a corollary of D-07: *"The animations are a tree. If an
animation is unset, it will inherit its parent's values."* — `layersIn`/`layersOut` inherit from
their parent `layers` entry when left unset; they do not require `layers` to be declared first
in file order for the inheritance relationship itself (tree structure, not declaration order) —
`[CITED: same source]`.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | MD3 Expressive's overshoot/bounce motion is expressed via spring physics (stiffness/damping/velocity), not bezier curves | State of the Art, D-11 | If wrong, a primary-sourced bezier-based overshoot token might exist somewhere in the M3 spec this research did not reach, and D-11's namespaced-extension escape hatch might be unnecessary — low practical risk either way since D-11's extension is pre-authorized regardless and costs nothing if unused |
| A2 | `layersIn`/`layersOut` inheriting from a parent `layers` entry (tree-based, not declaration-order-based) applies identically to the legacy `hyprlang` `animation =` syntax this repo actually uses, not only the newer Lua `hl.animation()` syntax the cited wiki page documents | State of the Art / D-07 | If wrong, declaration order inside `animations.conf` could matter for the legacy parser in a way the newer docs don't capture — low-cost to de-risk: `Hyprland --verify-config` plus a live `hyprctl animations -j` readback (both already an established verification pattern in this repo) would surface it immediately once `layersIn`/`layersOut` are actually added |
| A3 | Bare `uwsm stop` does not itself attempt to gracefully close individual Wayland clients before the compositor's socket tears down (Pitfall 5) | Pitfall 5 / D-29 | This is the entire premise WR-04 is built on; if wrong (i.e. Hyprland's own shutdown path already handles this gracefully regardless of which command triggers it), D-29's proposed test would return a clean "no hazard" result and the correct fix becomes documenting Logout's exemption rather than wrapping it — either outcome is a valid D-29 close, not a plan-breaking risk |

**All three flagged assumptions have a cheap, already-designed verification path spelled out in
this document (D-11's extension costs nothing if unused; A2 is caught by the exact same
verify-config/readback pattern this repo already runs for every other Hyprland config change; A3
IS D-29's own required test).**

## Open Questions

1. **Does `motion.json`'s two-layer schema need a structural extension to carry the full
   `emphasized` (non-accelerate/decelerate) curve, given it is a two-segment `ThreePointCubic`,
   not a 4-number bezier?**
   - What we know: the base `standard`/`emphasized-decelerate`/`emphasized-accelerate`/`linear`
     four (plus the 6 new base/legacy easings this table adds) are all single 4-number beziers
     and fit `motion.json`'s existing `[x1,y1,x2,y2]` array shape unchanged. Only the standalone
     `emphasized` curve does not.
   - What's unclear: whether the phase actually NEEDS the standalone `emphasized` token at all —
     CONTEXT.md's D-15 token-mapping work only references `emphasized-in`/`emphasized-out`
     (the accelerate/decelerate halves), which already exist and already fit. No decision in
     CONTEXT.md calls for the compound `emphasized` curve by name.
   - Recommendation: grow `motion.json`'s easing layer with the 6 new single-bezier tokens
     (`standardDecelerate`, `standardAccelerate`, `legacy`, `legacyDecelerate`,
     `legacyAccelerate`, and a corrected/renamed `linear` if the Hyprland-convention `[1,1,1,1]`
     needs to coexist with true CSS linear) using the existing schema unchanged; treat the
     compound `emphasized` as **out of scope for this phase** unless a specific consumer for it
     surfaces during planning, since Hyprland's `bezier =` primitive is itself a single 4-point
     curve and cannot express a two-segment curve without chaining two `bezier =` entries and a
     style hook Hyprland does not obviously expose for that purpose either.

2. **Does Hyprland's legacy `hyprlang` `animation =` parser accept a `layersIn`/`layersOut`
   pair with NO `layers` entry declared at all, or does the tree-inheritance model require the
   parent key to exist (even blank) for the child keys to resolve?**
   - What we know: CONTEXT.md already verified `layersIn`/`layersOut` as separate slots is
     CLEAN via `Hyprland --verify-config`; the current file already has a bare `layers` entry
     (`animation = layers, 1, 4, md3_decel, popin 80%`) that would need to stay or be split.
   - What's unclear: whether the plan should split `layers` entirely into `layersIn`/`layersOut`
     (removing the bare parent) or keep `layers` as a fallback default and add the two children
     alongside it.
   - Recommendation: keep the parent `layers` entry declared (even if never directly exercised
     once `layersIn`/`layersOut` cover every real case) — matches the tree model's own stated
     inheritance semantics literally, and costs nothing.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| dart-sass | D-01 GTK3 precompile | ✓ | 1.102.0 | none needed — already a hard `install.sh` dependency |
| hyprshutdown | MAINT-02/D-29 Logout wrap | ✓ | 0.1.1-4 | none needed — already installed, already used by Shutdown/Reboot |
| uwsm | MAINT-02/D-29 | ✓ | 0.26.6 | none needed |
| bsdtar | MAINT-03 preview extraction | ✓ | 3.8.8 | none needed |
| paru | MAINT-03 AUR install | ✓ | resolved via `which paru` | `install.sh:304-317` already bootstraps `paru` if absent on a fresh machine — same fallback this repo already relies on elsewhere |
| python3 + PyGObject (`Gtk 3.0`) | Not part of the shipped pipeline — used only to empirically verify Pitfall 2 this session | ✓ | system python3 | N/A (research-only tool, not a runtime dependency) |
| `paru -Si` for AUR-only entries (no prebuilt binary) | MAINT-03 preview fallback when `pacman -Sp` has nothing to fetch | ✓ | verified against `tela-icon-theme-git` | falls back to package-metadata-only preview (no icon grid), per D-28 |

No missing dependencies with no fallback. No missing dependencies at all, in fact — every tool
this phase's design calls for was already present and version-checked on this machine.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V5 Input Validation | Yes | Icon-theme selection already validates the fzf return against the real enumerated set before any `gsettings`/state write (existing pattern, `icon-theme-picker.sh`); the NEW browse-and-install path must apply the same discipline to package names resolved via `pacman -Ss`/`paru -Si` before ever interpolating one into a shell command |
| V12 File and Resources | Yes (new this phase) | MAINT-03's fetch-and-extract preview path (`pacman -Sp` URL → `curl` → `bsdtar`) must extract into a throwaway temp dir under the picker's own cache convention, never execute anything from the archive (no `.INSTALL` hooks), and must not follow the archive's own paths outside that temp dir (`bsdtar`'s default behaviour already refuses `../`-escaping paths, but this should be a documented assumption, not an implicit one) |
| V10 Malicious Code / Supply Chain | Yes (elevated for this phase) | AUR installs are user-interactive through the existing `paru` path in a real terminal (D-27) — never silent, never `--noconfirm`'d for a package the picker chose on the user's behalf. This is the correct control; a static package allowlist would be actively wrong here since MAINT-03's entire point is browsing packages not yet known to the picker |
| V5 (secondary) | Yes | The `#{"@name"}` sass interpolation pattern (Pitfall 1) takes a literal, repo-authored string and re-emits it verbatim into CSS output — no user-controlled or theme-generated data ever flows through that interpolation, so it is not an injection vector, but the plan should keep it that way (no dynamic/templated content inside a `#{"..."}` block) |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| A crafted/compromised AUR PKGBUILD executing arbitrary code during `paru -S` | Elevation of Privilege | Already mitigated by this repo's existing pattern: real interactive terminal, user reviews `paru`'s own prompts, no auto-confirm — MAINT-03 must not weaken this for convenience |
| A malicious icon-theme package's `post_install`/`.INSTALL` script running during a PREVIEW-ONLY fetch (before the user has decided to install) | Elevation of Privilege | D-28 already specifies fetch-and-EXTRACT, not fetch-and-install, for previews — `bsdtar -tf`/`bsdtar -xf` on a `.pkg.tar.zst` extracts files only; pacman-level install scripts never run outside an actual `pacman -U`/`paru -S` |
| A theme-orthogonal state file (icon-theme, motion-scale) holding an unvalidated value that later gets shell-interpolated | Tampering | Already mitigated by the existing closed-`case` pattern (`theme_engine_read_motion_scale`) and the picker's enumerated-set validation; MAINT-03 must extend the same discipline to any newly-installed theme name before it's written to `~/.local/state/theme/icon-theme` |

## Sources

### Primary (HIGH confidence)
- `api.flutter.dev/flutter/material/Easing-class.html` and every individual constant page
  (`standard`, `standardAccelerate`, `standardDecelerate`, `emphasizedAccelerate`,
  `emphasizedDecelerate`, `legacy`, `legacyAccelerate`, `legacyDecelerate`, `linear`) — fetched
  and quoted verbatim this session
- `raw.githubusercontent.com/flutter/flutter/master/packages/flutter/lib/src/animation/curves.dart`
  — `easeInOutCubicEmphasized` `ThreePointCubic` definition, fetched and quoted verbatim
- `api.flutter.dev/flutter/material/Durations-class.html` — full 16-entry duration scale
- `github.com/material-components/material-components-android` `docs/theming/Motion.md` —
  cross-check corroborating every bezier value above and the Emphasized path definition
- `raw.githubusercontent.com/hyprwm/hyprland-wiki/main/content/Configuring/Advanced and
  Cool/Animations.md` — `speed`/ds unit statement, animation-tree inheritance statement, both
  fetched and quoted verbatim
- `dart-sass` 1.102.0 itself (`/usr/bin/sass`), exercised directly this session: `@import url()`
  passthrough, relative-path non-rewriting, `@charset`/`--no-charset` behaviour,
  `@import`-vs-`@use` deprecation-warning behaviour, `#{"..."}"` GTK-`@name` escape, run-to-run
  byte-determinism with `--no-charset --no-source-map`
- `Gtk.CssProvider` (GTK3, via PyGObject) exercised directly this session: the `@charset`
  whole-stylesheet-discard reproduction, with a same-methodology control
- `/usr/share/doc/uwsm/README.md` (installed uwsm 0.26.6 package docs) and `uwsm stop --help` —
  `uwsm stop`'s documented scope ("stop graphical session and compositor")
- `hyprshutdown --help` (installed 0.1.1-4) — documented flags, confirming `--post-cmd` and the
  app-close-before-exit behaviour description
- Direct filesystem/package inspection this session: `pacman -Sp`/`curl`/`bsdtar -tf` against
  `elementary-icon-theme` (fetched, not installed) and `/usr/share/icons/Papirus` (installed) —
  the two divergent icon-theme directory-naming conventions
- Repo source inspection this session: `theme-engine/lib/motion.sh`, `generate.sh`,
  `contract.json`, `theme-parity`, `motion-lint`, `waybar-design-lint`, `icon-theme-picker.sh`,
  `stow.sh`, `install.sh`, `animations.conf`, `windowrules.conf`, `wleave/layout.json`,
  `waybar/*.css`, `swaync/style.css`, `.zshrc`, `fish/config.fish`,
  `04-REVIEW.md`, `WINDOWS.md`

### Secondary (MEDIUM confidence)
- WebSearch summaries of `m3.material.io/blog/m3-expressive-motion-theming` and secondary
  design-system write-ups on MD3 Expressive spring/spatial-vs-effect token behaviour (the
  primary blog page itself is client-rendered and could not be fetched directly)

### Tertiary (LOW confidence)
- None used without a corroborating primary/secondary source in this document.

## Metadata

**Confidence breakdown:**
- MD3 easing/duration table (D-10 blocking deliverable): HIGH — two independent
  Google-maintained primary sources agree number-for-number
- D-11 (no overshoot in MD3 bezier vocabulary): HIGH for the bezier-table claim (primary,
  exhaustive); MEDIUM for "Expressive overshoot = springs" (secondary, uncorroborated by a
  primary M3 doc this session, consistent with the same gap `12-MOTION-VERDICT.md` already hit)
- dart-sass/GTK3 mechanics (`@name` escape, `@charset` discard, path non-rewriting, `@use` vs
  `@import`): HIGH — every claim independently reproduced on this machine this session
- Hyprland `speed` unit: MEDIUM (primary citation exists, but for the newer Lua syntax
  documentation page, not a readback of the legacy parser this repo actually runs) — D-13's
  extreme-value observation remains the authoritative instrument
- `uwsm stop` vs `hyprshutdown` teardown-hazard hypothesis (WR-04/D-29): MEDIUM — mechanism
  descriptions are primary-cited from installed package docs; the actual stall/no-stall
  behaviour is explicitly unverified and is D-29's own required task
- Icon-theme directory-convention divergence (Pitfall 6): HIGH — reproduced against two real
  packages this session

**Research date:** 2026-07-27
**Valid until:** ~30 days for the Hyprland/dart-sass/GTK3 mechanics (stable, locally-verified
tool behaviour, unlikely to change); effectively indefinite for the MD3 bezier table itself
(a published, versioned design-token spec) but re-check if `dart-sass` or `Hyprland` get a major
version bump before this phase executes.
