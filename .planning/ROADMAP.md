# Roadmap: Arch + Hyprland Dotfiles

## Milestones

- ✅ **v1.0 Theme Pipeline Repair** — Phases 1-3 (shipped 2026-07-09) — [archive](milestones/v1.0-ROADMAP.md)
- ✅ **v2.0 Desktop Expansion** — Phases 4-10 (shipped 2026-07-25) — [archive](milestones/v2.0-ROADMAP.md)
- 🚧 **v3.0 Quickshell Foundation & Motion Language** — Phases 11-17 (in progress)

## Phases

<details>
<summary>✅ v1.0 Theme Pipeline Repair (Phases 1-3) — SHIPPED 2026-07-09</summary>

- [x] Phase 1: Root-Cause Fix & Consolidated Theme Engine (3/3 plans) — completed 2026-07-07
- [x] Phase 2: Static ↔ Dynamic Parity & Switch Reliability (2/2 plans) — completed 2026-07-07
- [x] Phase 3: Repo Cleanup & Fresh-Install Reproducibility (4/4 plans) — completed 2026-07-08

Full details: [milestones/v1.0-ROADMAP.md](milestones/v1.0-ROADMAP.md)

</details>

<details>
<summary>✅ v2.0 Desktop Expansion (Phases 4-10) — SHIPPED 2026-07-25</summary>

- [x] Phase 4: Reliability Fixes & Tech Debt (6/6 plans) — completed 2026-07-11
- [x] Phase 5: Light Mode Pipeline & Theme Presets (5/5 plans) — completed 2026-07-11
- [x] Phase 6: Themed Surfaces & Utility Suite (19/19 plans) — completed 2026-07-13
- [x] Phase 7: Super-Key Menu (8/8 plans) — completed 2026-07-13
- [x] Phase 8: Waybar Evolution (16/16 plans) — completed 2026-07-15
- [x] Phase 9: wlogout to wleave Migration (4/4 plans) — completed 2026-07-25
- [x] Phase 10: AGS Media Applet (6/6 plans) — completed 2026-07-15

Originally scoped as Phases 4-8; Phases 9 and 10 were added mid-milestone in
response to findings (GTK3 stylesheet-discard failure class; eww pointer-input
dead end).

Full details: [milestones/v2.0-ROADMAP.md](milestones/v2.0-ROADMAP.md)

</details>

### 🚧 v3.0 Quickshell Foundation & Motion Language (Phases 11-17)

**Milestone goal:** Establish Quickshell as the shell toolkit and a shared motion language across every surface, then ship the net-new widgets a top-tier rice has and this one does not — without retiring anything that works today.

**Phase numbering continues from v2.0.** v2.0 ended at Phase 10; v3.0 starts at Phase 11.

- [x] **Phase 11: Quickshell Viability Gate** - Prove pointer, keyboard, focus, multi-monitor, hot reload and coexistence on Hyprland 0.56.0 — with authority to stop the milestone (completed 2026-07-26)
- [x] **Phase 12: Unified Design-Token Pipeline** - One source emits colour and MD3 motion tokens to QML, GTK4 CSS and Hyprland, guarded by a motion lint gate (completed 2026-07-27)
- [x] **Phase 13: Motion Retrofit & Existing-Surface Sweep** - Apply the motion language to every surface that already exists, and close the carried-in debt on those same surfaces (completed 2026-07-28)
- [x] **Phase 14: Dashboard Drawer** - The first real QML surface: a four-tab swipeable drawer sharing state with what already ships (completed 2026-08-01)
- [ ] **Phase 15: Audio + Connectivity Panels** - Per-app mixer, wifi picker and bluetooth manager from one shared dialog component
- [ ] **Phase 16: Workspace Overview** - Full-screen live-thumbnail workspace grid with click-to-focus and drag-between-workspaces
- [ ] **Phase 17: Ambient Extras** - Video wallpaper and dynamic cursors — explicitly the first phase to cut if the milestone runs long

#### Standing constraints (apply to every v3.0 phase, not one phase's task)

These are the project's own rules, each written after it cost rework. They are gates, not aspirations.

1. **Human render-and-look gate.** Every visual surface needs a blocking human sign-off before its plan closes. Phase 6 and Phase 8 both shipped visibly broken surfaces through fully green mechanical gates.
2. **Verify options against the installed binary.** hyprlock 0.9.5 silently ignored unknown options. Applies this milestone to Hyprland 0.56.0's `bezier =` syntax (research could not confirm it has not moved to Lua `hl.curve(...)`), to GTK4's `linear(<stops>)` easing support, and to the exact `quickshell` package name.
3. **Same-commit stow registration.** A new stow package registers in `stow.sh` in the commit that creates it. `ags/` was populated but unregistered and only worked on this host.
4. **Additive-only coexistence, all milestone long.** v3.0 retires nothing, so QML and the six live GTK surfaces run simultaneously throughout. Named collision risks to check on every new surface: layer namespaces; `$mainMod SUPER_L` (bare tap), `$mainMod SPACE`, `$mainMod N`, `$mainMod C`, `$mainMod L`, `XF86Audio*`/`XF86MonBrightness*`; and `org.freedesktop.Notifications` ownership. MPRIS is already double-consumed (waybar `mpris` + AGS `lib/media.ts`) — a QML media widget makes it three readers, which is safe; a third uncoordinated *writer* is not.
5. **TOKEN-06 blocks nothing.** Spring physics is a stretch on QML surfaces only. No phase and no requirement may depend on it. Any spring-sampling or least-squares-fitting work is optional and additive.

#### Carried-in maintenance placement

MAINT-01..03 are small, thematically unrelated carry-ins. They are folded into phases rather than given a standalone maintenance phase, because a standalone phase of three unrelated single-item fixes is exactly the thin-phase shape the coarse granularity setting exists to prevent.

- **MAINT-01 → Phase 11.** Not filler. QS-05 requires proving no duplicated global keybind across two independent registration mechanisms (Hyprland `bind =` lines and Quickshell `GlobalShortcut`). `keybind-doctor` is the instrument for that proof and is currently broken on Hyprland 0.56.0. Bind-collision risk rises exactly when Quickshell arrives, and Phases 14 and 16 each add a new global keybind — so the detector must work before then, not after.
- **MAINT-02 → Phase 13.** The four items are one review artifact (`04-REVIEW.md` WR-01..04) and should close in one pass rather than scatter across phases. Phase 13 is the milestone's designated existing-surface sweep and already opens wleave, which is WR-04's target (Logout wrapping). The other three are single-line install/shell guards with no phase affinity.
- **MAINT-03 → Phase 13.** The icon-theme picker is an existing surface, and Phase 13 is the only phase this milestone that opens the existing GTK/utility surface family. Putting it in Phase 17 would place twice-deferred debt inside the designated cut candidate.
- **QS-03 → Phase 12 (carried forward from Phase 11, 2026-07-26).** The shell root mounts one `LazyLoader` per `GlobalShortcut`, not one surface per `Quickshell.screens` entry, so an output hotplugged after shell startup gets no surface at all. A `Variants`-based fix was written in 11-04 and reverted after it introduced two independent live-daemon reliability regressions on quickshell 0.3.0. Phase 11 accepted the gap under D-10 via a recorded override in `11-VERIFICATION.md` frontmatter rather than dropping the requirement. Placement rationale (D-B): Phase 12 is the first phase that needs a permanent, non-summoned QML surface — its criterion 1 re-colours a live surface on theme switch — so it has to solve per-screen fan-out anyway; Phases 14 and 16 both build on that same root, so QS-03 closes before either of them regardless. *(Amended in Phase 12, 2026-07-26, per D-13: Phase 12 re-attempted the fan-out under a bounded budget — a checked-in `qmldir` plus two structurally distinct `Variants`+per-screen-`LazyLoader` arrangements, one as the escape-hatch spike — and both reproduced an FM2-class multi-screen failure on quickshell 0.3.0-2, re-proven across a real session restart. QS-03 is accepted as a permanent limitation rather than solved and is now Out of Scope in `REQUIREMENTS.md` and `PROJECT.md`; see `12-QS03-EVIDENCE.md` and `12-CONTEXT.md` D-13. Phases 14 and 16 inherit a shell root that cannot fan out.)*

## Phase Details

### Phase 11: Quickshell Viability Gate

**Goal**: Quickshell is proven to work on this exact machine — pointer, keyboard, focus, dismiss, multi-monitor, hot reload, and peaceful coexistence with everything already running — or the milestone stops here.
**Depends on**: Nothing (first phase of v3.0; builds on shipped v2.0)
**Requirements**: QS-01, QS-02, QS-03 *(deferred — accepted for Phase 11 via a recorded override, ownership reassigned to Phase 12; see 11-VERIFICATION.md)*, QS-04, QS-05, QS-06, MAINT-01
**Success Criteria** (what must be TRUE):

  1. A human clicks a button, types into a text field, and dismisses by clicking outside on a throwaway Quickshell `PanelWindow` running on Hyprland 0.56.0 — all three verified before any feature is built on the toolkit, with a dated pass/fail record and explicit authority to STOP the milestone if any one fails.
  2. A Quickshell surface renders correctly on every connected monitor, survives a monitor hotplug and one suspend/resume cycle, hot-reloads on a config edit without a manual restart, and picks up a hand-edited JSON change through `FileView`/`JsonAdapter` with zero `reload.sh` involvement. *(Amended in Phase 11: the multi-monitor render sub-clause was not met — a single-`LazyLoader` shell root does not fan out over `Quickshell.screens`, so a monitor hotplugged after startup gets no surface. Accepted for Phase 11 via a recorded override under D-10 — see 11-VERIFICATION.md frontmatter `overrides` — and reassigned to Phase 12 as QS-03. Hotplug survival, the suspend/resume cycle, hot reload, and `FileView`/`JsonAdapter` propagation all independently passed.)*
  3. `install.sh` installs quickshell and its Qt6 dependencies from the official Arch `extra` repo and `stow.sh` deploys the `quickshell/` package on a clean checkout — both registered in the same commit that creates the package.
  4. Quickshell autostarts with the session and runs alongside waybar, swaync, SwayOSD, wleave, AGS and walker with no visible layout shift: `hyprctl layers -j` confirms namespace identity with no unexpected second claimant at a given layer level, `hyprctl monitors -j`'s `reserved` array carries the actual exclusive-zone reservation and shows no unattributed change after Quickshell autostarts (amended in Phase 11 per D-15 — see 11-QUICKSHELL-EVIDENCE.md), `busctl --user list` shows exactly one `org.freedesktop.Notifications` owner (swaync), volume and brightness keys still move exactly one step per press, and a repaired `keybind-doctor` parses `hyprctl binds` plain-text output on 0.56.0 (amended in Phase 11 per D-15 — see 11-QUICKSHELL-EVIDENCE.md) and reports zero duplicate chords across Hyprland config and Quickshell global shortcuts.
  5. The workspace-overview feasibility question is answered on this build before Phases 12-15 build around it: a live multi-window `ScreencopyView` capture renders real window content (human-attested, four concurrent windows), and Hyprland's screencopy permission mechanism — a `permission = <path>, screencopy, allow` keyword plus an `ecosystem { enforce_permissions = ... }` category block, both plain sourced-`.conf` syntax, verified directly against the installed Hyprland 0.56.0 binary rather than documentation — is recorded as verified fact (see 11-QUICKSHELL-EVIDENCE.md, amended in Phase 11 per D-15). Phase 16's scope is now a decision, not a discovery. (OVER-04's measured budget, its documented fallback, and the live-enforcement proof itself all remain Phase 16's own requirement — this plan verified the mechanism and every consumer path, not live enforcement.)

**Open questions owned**: (1) Does `FileView`/`JsonAdapter` property propagation truly need zero `reload.sh` involvement? (5) Hyprland's screencopy permission mechanism (the `permission =`/`ecosystem {}` syntax, binary-verified) — investigated and answered here (see 11-QUICKSHELL-EVIDENCE.md); Phase 16 still owns the live-enforcement proof.
**Owns**: The viability gate itself (the eww failure class in QML clothing) and same-commit stow registration.
**Plans**: 5/5 plans executed
**Wave 1**

- [x] 11-01-PLAN.md — Tracer: install quickshell, ship the `quickshell/` package registered in one commit, prove human click/type/click-outside-dismiss (QS-01, QS-02; STOP authority)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 11-02-PLAN.md — Repair `keybind-doctor` via plain-text parsing, cross-check Quickshell-claimed chords, prove the collision check fails on a poisoned fixture (MAINT-01)

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 11-03-PLAN.md — `quickshell-doctor`: the rerunnable layer-shell / D-Bus / single-owner coexistence gate (QS-05, QS-06)

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 11-04-PLAN.md — Durability: headless-output hotplug, hot reload, `FileView`/`JsonAdapter` propagation, suspend/resume (QS-03, QS-04)

**Wave 5** *(blocked on Wave 4 completion)*

- [x] 11-05-PLAN.md — Screencopy feasibility probe, criterion-5 amendment, and the phase verdict (QS-02, QS-05)

### Phase 12: Unified Design-Token Pipeline

**Goal**: One token source renders colour and motion to QML, GTK4 CSS and Hyprland without drift, and the gates refuse any surface that hand-rolls its own values.
**Depends on**: Phase 11
**Requirements**: TOKEN-01, TOKEN-02, TOKEN-03, TOKEN-04, TOKEN-05, TOKEN-06, QS-03 *(carried forward from Phase 11 — see 11-VERIFICATION.md)*
**Success Criteria** (what must be TRUE):

  1. A theme switch re-colours a live Quickshell surface without restarting it, with the palette read from `~/.local/state/theme/` as a `contract.json`-listed matugen render target — no copied palette file, no hex literal in any repo-authored QML.
  2. A single hand-authored motion-token definition (MD3 Expressive named duration + bezier pairs) renders to all three targets — QML, GTK4 CSS and Hyprland — in one `theme-apply` run, with the Hyprland `bezier =` syntax and the GTK4 easing mechanism each chosen by testing the installed binary rather than assumed, and `hyprctl animations -j` afterwards confirming every emitted curve holds its generated values rather than a silently substituted default.
  3. `theme-doctor` fails on a deliberately poisoned surface that hand-rolls a raw duration or easing curve, and passes once that surface consumes a motion token instead — proven to fail, not merely observed to pass.
  4. A reduced-motion setting, driven through `theme-apply`'s existing single entrypoint, visibly shortens or disables animation on a QML surface, a GTK surface and a Hyprland window animation in the same run.
  5. *(Stretch — blocks nothing.)* A human watches native QML spring physics and the MD3 baseline render the same token side by side and records which is adopted; dropping this changes no other phase.
  6. *(Carried forward from Phase 11 as QS-03, accepted there via a recorded override — see 11-VERIFICATION.md frontmatter `overrides`.)* The permanent Quickshell shell root mounts a surface on **every** entry in `Quickshell.screens`, including an output hotplugged after shell startup, and `quickshell-doctor`'s per-screen surface-creation check reports PASS with the script exiting cleanly (exit 0) — it currently reports 13 passed / 1 failed, exit 1, on exactly this one check, so this criterion is proven by that number going green, not by inspection. The 11-04 `Variants`-based attempt was reverted for two independent live-daemon reliability regressions on quickshell 0.3.0 (an intermittent config-load race and a post-hotplug visibility break), so the replacement must be re-proven against the always-on autostart daemon across a real session restart, not only in a foreground test run. *(Amended in Phase 12, 2026-07-26, per D-13: this criterion is not met and is not being pursued further — QS-03 is accepted as a permanent limitation rather than solved. A bounded, targeted re-attempt (a checked-in `qmldir` closing the FM1 scanner race, plus two structurally distinct `Variants`+per-screen-`LazyLoader` arrangements, one of them the escape-hatch spike) reproduced an FM2-class multi-screen surface-creation failure on quickshell 0.3.0-2 in both arrangements, re-proven across a real session restart — see `12-QS03-EVIDENCE.md`. QS-03 is now Out of Scope in `REQUIREMENTS.md` and `PROJECT.md` (see `12-CONTEXT.md` D-13); `quickshell-doctor`'s per-screen check is a documented SKIP under D-14 rather than a standing FAIL, so the script exits 0 again. Consequence: Phase 16's full-screen per-monitor overview inherits a shell root that cannot fan out and must solve this itself.)*

**Open questions owned**: (2) GTK4 CSS `linear(<stops>)` easing support — test empirically, default assumption is unsupported and keyframes are the safe fallback. (3) Hyprland 0.56.0 `bezier =` vs Lua `hl.curve(...)` — verify against the installed binary. (6) Quickshell reduced-motion — no ecosystem precedent exists anywhere; design it from scratch.
**Owns**: Token-schema decisions, the fidelity ceiling, the reduced-motion axis, and the generator safeguards against malformed emitted curves. Also owns the carried-forward QS-03 per-screen surface fan-out.
**Plans**: 8/8 plans executed
**UI hint**: yes

Plan ordering is fixed by 12-CONTEXT.md D-32: QS-03 first (it and the inspector both modify `shell.qml` and `modules/Probe.qml`), then the token foundation, then the Hyprland target and readback, then the lint (which needs targets to exist), then wleave's retrofit with its own human gate, and TOKEN-06's verdict last.

**Wave 1**

- [x] 12-01-PLAN.md — Bounded QS-03 targeted fix: checked-in `modules/qmldir` plus `Variants` and a per-screen `LazyLoader`, re-proven across a real session restart (QS-03)

**Wave 2** *(blocked on Wave 1)*

- [x] 12-02-PLAN.md — D-13 one-way decision gate and, on acceptance, the QS-03 Out-of-Scope amendment plus `quickshell-doctor`'s documented SKIP — conditional, no-ops if QS-03 closed green (QS-03)
- [x] 12-03-PLAN.md — Tracer: `motion.json` source, `lib/motion.sh` emitter, three render targets, two new `contract.sh` extractors, and `engine_owned_files` driving both the rsync exclusions and a state-manifest gate (TOKEN-03)

**Wave 3** *(blocked on Wave 2)*

- [x] 12-04-PLAN.md — Motion-scale axis with CLI and the `enable-animations` signal, Hyprland source-order wiring, fresh-install seeding, `hyprctl animations -j` readback, and byte-identity parity (TOKEN-03, TOKEN-05)

**Wave 4** *(blocked on Wave 3)*

- [x] 12-05-PLAN.md — `motion-lint`: deny-by-default reference-resolution and raw-value checks, nine committed poisoned/compliant fixtures, folded into `theme-doctor` (TOKEN-04)
- [x] 12-06-PLAN.md — matugen QML palette target, `Colours`/`Motion` singletons, the token-inspector rewrite, live re-colour across 10 stress-test switches — blocking human render gate (TOKEN-01, TOKEN-02, TOKEN-05)

**Wave 5** *(blocked on Wave 4)*

- [x] 12-07-PLAN.md — wleave GTK4 retrofit onto emitted tokens with longhand transitions, exemption removed — blocking human render gate (TOKEN-03, TOKEN-05)

**Wave 6** *(blocked on Wave 5)*

- [x] 12-08-PLAN.md — TOKEN-06 spring-versus-MD3 side-by-side and recorded verdict; droppable, blocks nothing (TOKEN-06)

### Phase 13: Motion Retrofit & Existing-Surface Sweep

**Goal**: Every surface that already exists moves with the shared motion language, and the carried-in debt sitting on those same surfaces is closed in the same sweep.
**Depends on**: Phase 12 (independent branch — Phase 14 does **not** depend on this phase, and the two could be reordered or partially parallelized without breaking a dependency; running 13 first is a deliberate risk-reduction choice, since validating the fitted curves on already-gated surfaces is cheaper than discovering fitting problems after a QML surface has been built on assumptions about how motion should feel)
**Requirements**: MOTION-01, MOTION-02, MOTION-03, MAINT-02, MAINT-03
**Success Criteria** (what must be TRUE):

  1. Hyprland window, workspace and layer animations plus all six live GTK surfaces — waybar, swaync, walker, SwayOSD, wleave and the AGS media card — animate from the shared tokens, with no hand-tuned one-off bezier and no raw duration left in any repo-authored config or stylesheet.
  2. Every retrofitted surface passes a blocking human render-and-look gate before its plan closes — a side-by-side of the token as QML renders it against its fitted GTK4/Hyprland rendering — and no surface closes on a green mechanical gate alone.
  3. Motions on high-frequency interactions (workspace switch, drawer and notification appearance) carry a recorded multi-day use note, not a single click-and-look; the 09-04 "looked fine at review, wrong in daily use" pattern does not recur.
  4. The four Phase 4 advisory items are closed and observable: the fisher bootstrap `curl` fails loudly on an HTTP error, a fresh install produces no nvm first-run error noise, `.zshrc`'s uv env source is guarded, and Logout exits the compositor gracefully the way Shutdown and Reboot already do.
  5. The icon-theme picker lists icon themes that are not yet installed, installs the chosen one from the repos or AUR, and applies it live to Thunar and GTK apps.

**Owns**: Retrofit-time regression (a curve reverting to a Hyprland default without an error) and the perceptual gates that mechanical checks cannot replace.
**Plans**: 7/7 plans executed
**UI hint**: yes

Plan ordering is fixed by 13-CONTEXT.md D-37: MD3 sourcing (delivered in 13-RESEARCH.md) before the Hyprland retrofit, the Hyprland retrofit + A/B toggle FIRST so D-18's soak clock starts in plan 1 and accrues while the rest proceeds on files it does not touch, the sass mechanism before the waybar/swaync conversions, the wallpaper-pointer untrack before the 10/10 stress test, and the stress test + `motion-lint --no-pending` + the soak verdict as closing gates. D-17's three per-plan render gates (Hyprland, waybar, swaync) override `config.json`'s end-of-phase human-verify mode.

**Wave 1**

- [x] 13-01-PLAN.md — Tracer: full MD3 easing scale, tokenized `animations.conf` with `layersIn`/`layersOut`, dead-curve and dead-layerrule removal, and the temporary A/B toggle — starts the soak (MOTION-01, MOTION-03)

**Wave 2** *(blocked on Wave 1)*

- [x] 13-02-PLAN.md — The sass precompile mechanism proven end-to-end on swaync: `_motion.scss` partial, compile inside `theme_engine_generate`, contract/parity/seed wiring — blocking human render gate (MOTION-02, MOTION-03)
- [x] 13-03-PLAN.md — MAINT-02 (partial): WR-01/02/03 closed, each proven by fault injection; WR-04's logout teardown measurement was **NOT PERFORMED** — explicitly waived by operator 2026-07-28, remains open debt (see PROJECT.md Key Decisions, 13-03-SUMMARY.md) (MAINT-02)
- [x] 13-04-PLAN.md — MAINT-03: Ctrl-A browse inside the existing icon picker, fetch-and-extract previews, repo/AUR install feeding the existing apply pipeline (MAINT-03)

**Wave 3** *(blocked on Wave 2)*

- [x] 13-05-PLAN.md — All six waybar stylesheets converted to sass and launched from their compiled sheets; launcher, contract, parity and lint wiring — blocking human render gate (MOTION-02, MOTION-03)

**Wave 4** *(blocked on Wave 3)*

- [x] 13-06-PLAN.md — Untrack, ignore and seed the wallpaper pointer; the D-32 exemption end state; `motion-lint --no-pending`; ledger reconciliation (MOTION-01, MOTION-02)

**Wave 5** *(blocked on Wave 4)*

- [x] 13-07-PLAN.md — D-19/D-20 soak gate reached and **explicitly WAIVED by the operator, not passed** (measured session count 1 of floor 3, zero A/B flips, all 13 motions recorded NOT ASSESSED — see 13-MOTION-SOAK-VERDICT.md); the A/B toggle removal and all three closing gates (theme-stress-test 10/10, `motion-lint --no-pending`, full 8-script sweep) were unconditional and are genuinely green (MOTION-01, MOTION-02, MOTION-03)

### Phase 13.1: Hyprland Lua Config Migration (INSERTED — urgent, upstream deadline)

**Goal**: Move the Hyprland config off hyprlang to Lua before 0.57 removes `.conf` support, and convert the theme-engine's two Hyprland-format outputs from generated config *syntax* into generated *data* — while proving the resulting config is behaviourally identical.
**Depends on**: Phase 12 (owns the design-token pipeline this rewrites the output contract of)
**Requirements**: MAINT-04
**Design spec**: `docs/superpowers/specs/2026-07-28-hyprland-lua-config-migration-design.md` (approved 2026-07-28)

**Why inserted here** (not appended): Phases 14–17 all consume the design tokens this phase re-shapes. Migrating first avoids retrofitting four phases of surface. The deadline is on an upstream clock we do not control, and 0.56 is the last release where both formats load — meaning this is the last window in which the migration has a working fallback to roll back to.

**Success Criteria** (what must be TRUE):

  1. Hyprland starts from `hyprland.lua` with no `.conf` present in the load path, and the startup deprecation warning is gone.
  2. `hypr-equivalence-check` reports an exact match between the pre-migration baseline (captured on `.conf` via `hyprctl -j getoption` / `binds` / `animations`) and the running Lua config — or every divergence is individually recorded as intended, with a reason.
  3. Theme switching still re-themes the whole desktop in both static-preset and matugen dynamic modes, with the two Hyprland-format contract entries (`hyprland.conf` `hypr-vars` + `hyprland-motion.conf` `hypr-motion`) replaced by one `lua-table` entry.
  4. `hyprlock` still themes correctly from its own hyprlang fragment — the two-emitter split is deliberate and stays.
  5. The load-order hazard is gone: no config file depends on another being sourced first for a variable to exist, and a missing token degrades to a default rather than preventing the compositor from starting.
  6. `motion-lint` has a Lua-aware path with fixtures, and its hyprlang path still guards the hyprlock output.
  7. A fresh machine reproduces the Lua config through `install.sh` + `stow.sh`.

**Owns**: The `lua-table` generated-token format and the "generated files are data, not executable config" convention that Phases 14–18 inherit.
**Plans**: 10/10 plans executed
**Rollback**: The legacy `.conf` tree stays on disk untouched until criterion 2 passes and the Lua config has soaked under normal use. Hyprland selects a format once at startup, so rollback at any point is renaming `hyprland.lua` plus a restart.

**Known unknown carried into planning**: The actual Lua API is **unverified**. Wiki pages consulted during design confirmed the migration and the config location but not how options, keybinds, window rules, or nested blocks are expressed. Establishing it from the current wiki and `hl.meta.lua` stubs is the phase's research step, not an assumption to build on. *(Closed by research: the installed `hyprland` 0.56.1-2 package ships `/usr/share/hypr/hyprland.lua` and `/usr/share/hypr/stubs/hl.meta.lua`, which are authoritative for the whole `hl.*` surface. Three items remain unverifiable offline — the `hl.window_rule` property vocabulary, the `hl.permission` calling convention, and `hyprctl` config-re-read semantics — and are planned as explicit empirical spikes in `13.1-03`.)*

Plans:
**Wave 1**

- [x] 13.1-01-PLAN.md — Build `hypr-equivalence-check` and capture the pre-migration `hyprctl` baseline (D-09: strictly before any config edit)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 13.1-02-PLAN.md — TRACER: end-to-end Lua slice — merged `lua-table` token emitter, stowed symlink, `require()`, booting compositor, proven rollback and degradation

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 13.1-03-PLAN.md — Empirical Lua API spikes against a nested instance; port monitors and autostart; entry point requires all seven modules

**Wave 4** *(blocked on Wave 3 completion)*

- [x] 13.1-04-PLAN.md — Port the remaining `hl.config` blocks and all 80 keybinds, diffed against the committed baseline
- [x] 13.1-05-PLAN.md — `lua-table` validation in `lib/contract.sh`; reconcile `lib/reload.sh` with measured re-read semantics

**Wave 5** *(blocked on Wave 4 completion)*

- [x] 13.1-06-PLAN.md — Port animations onto the token table; give `motion-lint` a Lua-aware path with three fixtures

**Wave 6** *(blocked on Wave 5 completion)*

- [x] 13.1-07-PLAN.md — Port 30 window rules, 13 layer rules and the 4 permission grants; record the permission review

**Wave 7** *(blocked on Wave 6 completion)*

- [x] 13.1-08-PLAN.md — Cut the live session over to Lua and run the equivalence gate, reasoning about every divergence

**Wave 8** *(blocked on Wave 7 completion)*

- [x] 13.1-09-PLAN.md — Retarget every consumer of the retiring hyprlang surfaces before deleting them

**Wave 9** *(blocked on Wave 8 completion)*

- [x] 13.1-10-PLAN.md — Soak evidence, the one-way retirement decision, legacy removal and fresh-machine reproduction

### Phase 14: Dashboard Drawer

**Goal**: The first real QML surface — a four-tab swipeable dashboard drawer that reads the state the desktop already owns instead of forking it.
**Depends on**: Phase 12 (independent branch — does **not** depend on Phase 13)
**Requirements**: DASH-01, DASH-02, DASH-03, DASH-04, DASH-05, DASH-06, DASH-07, DASH-08, **DASH-09**, **DASH-10** *(DASH-09 minted 2026-07-30 — the Performance tab's GPU dial, new scope from 14-09's render gate at the human's explicit direction; built in 14-10 and its render gate approved. DASH-10 minted 2026-08-01 — the drawer's animated gradient border matching Hyprland's own window border, new scope raised during this phase's UAT at the human's explicit direction; built, render gate outstanding as 14-UAT.md item 8. Plan 14-10 additionally repairs and folds in `hypr-equivalence-check`, which is **MAINT-04**'s proof instrument — ownership of MAINT-04 stays with Phase 13.1; the gate work is recorded here because that is where it lands)*
**Success Criteria** (what must be TRUE):

  1. A keybind opens the dashboard drawer and a click outside dismisses it; the rest of the desktop stays interactive the whole time, and `hyprctl layers -j` shows the drawer holding zero exclusive zone on any edge waybar already reserves.
  2. Four tabs — Dashboard, Media, Performance, Weather — are reachable both by horizontal drag with a threshold commit that springs back below the threshold, and by a direct tap on the header row.
  3. The Dashboard tab shows a calendar, date/time, a compact media widget and system resources at a glance; the Media tab shows a full player with cover art; the Performance tab shows CPU, memory, network, storage and battery; the Weather tab shows current conditions and forecast and stays readable rather than blank or broken when the weather service is unreachable.
  4. The media widget reads the existing MPRIS active-player state — the AGS card, waybar and the dashboard all show the same track and player simultaneously, and no second media backend exists.
  5. Flipping a dashboard quick-toggle changes swaync's existing toggle grid to match and vice versa, with no second source of truth for that state; and neither the dashboard nor any panel opens over a fullscreen client.

**Owns**: The "overlay by default, zero exclusive zone" layer-shell convention that Phases 15 and 16 inherit, and the shared-state pattern for anything the desktop already tracks.
**Plans**: 10/10 plans executed

- [x] 14-01-PLAN.md
- [x] 14-02-PLAN.md
- [x] 14-03-PLAN.md
- [x] 14-04-PLAN.md
- [x] 14-05-PLAN.md
- [x] 14-06-PLAN.md
- [x] 14-07-PLAN.md
- [x] 14-08-PLAN.md
- [x] 14-09-PLAN.md
- [x] 14-10-PLAN.md — Two-tone composite weather glyphs (experiment, revert defined) + a fifth GPU dial at no cost in panel width + the `hypr-equivalence-check` coverage gap

**Wave 1** (parallel):

- 14-01: TRACER — Super+D summons/dismisses the `quickshell-dashboard` overlay end-to-end (DASH-01, DASH-08)
- 14-02: Foundations — Material Symbols font gate, stagger token, weather state seed (DASH-06)

**Wave 2** *(blocked on Wave 1)*:

- 14-03: Four-tab pager — TabBar + SwipeView, nine dashboard stubs, owns `modules/dashboard/qmldir` (DASH-02)

**Wave 3** *(blocked on Wave 2; file-disjoint, parallel)*:

- 14-04: Quick-toggle grid + motion-scale row + swaync flip (DASH-07)
- 14-05: Media tab + shared MediaBackend (DASH-04)
- 14-06: Performance tab + Dial component + resource reader (DASH-05)
- 14-07: Weather tab + Open-Meteo backend + degradation (DASH-06)

**Wave 4** *(blocked on 14-04/05/06)*:

- 14-08: Dashboard tab composition + deep-link convention (DASH-03)

**Wave 5** *(blocked on 14-08, 14-07)*:

- 14-09: Entrance cascade + full gate sweep + phase-close render gate (all 8)

**Wave 6** *(blocked on 14-09; added 2026-07-30 after 14-09's render-gate approval)*:

- 14-10: Two features the human raised at 14-09's approval, plus one gate-coverage gap the phase's own regression sweep exposed — placed in Phase 14 by explicit human direction rather than deferred (DASH-05 *extension*, DASH-06, MAINT-04's proof instrument). Phase-level verification is held until this plan closes.
  1. **Two-tone the two composite weather glyphs** — the installed icon font has no colour tables at all (verified with fontTools), so per-path colouring inside one glyph is structurally impossible; the approved route layers two glyphs. Planned as an **experiment** with a defined one-property revert to the single designed glyph and a **comparative** render-gate question.
  2. **A fifth Performance dial: GPU usage** — five dials at 176 with a 17px ring reproduce the same 944px row content the four 224px dials produced, so the 1040px frame does not move. Two design questions settled in the plan rather than mid-edit: one-shot subprocess sampling on its own named slower cadence under the reader's zero-idle contract, and an always-present dial with a designed no-GPU placeholder (D-41), because omitting it would make panel width a function of graphics hardware.
  3. **`hypr-equivalence-check` was absent from the phase's own sweep and is red** — diagnosed as *not* a regression (the one added bind is DASH-01's own Super+D chord; the baseline predates the phase). Bounded re-baseline behind an order-insensitive delta proof, folded into `theme-doctor` with a live-session guard so the headless fresh-install gate still passes, and the phantom-diff readability problem given a named disposition.

**UI hint**: yes

### Phase 15: Audio + Connectivity Panels

**Goal**: Per-app volume, wifi and bluetooth are handled by themed in-shell panels, displacing pavucontrol, nm-connection-editor and blueman from the daily workflow without pretending to replace them.
**Depends on**: Phase 14 (the panels are the expand targets of the dashboard's quick-toggle entries and reuse its shared-state and panel-lifecycle patterns)
**Requirements**: PANEL-01, PANEL-02, PANEL-03, PANEL-04, PANEL-05, PANEL-06
**Success Criteria** (what must be TRUE):

  1. The audio panel lists every currently active audio application with its own volume slider and click-to-mute, and separately selects the default output device, the default input device and master volume.
  2. The wifi panel scans with a visible in-progress state, lists visible networks, connects to an open network, and prompts for and accepts a password on a secured one.
  3. The bluetooth panel toggles the adapter, lists devices, and connects, disconnects and forgets them.
  4. Each of the three panels carries an Advanced button that launches pavucontrol, nm-connection-editor or blueman for anything past its deliberately limited scope.
  5. All three panels are instances of one shared dialog component rather than three bespoke implementations — and the existing owners are untouched: SwayOSD still owns the hardware `XF86Audio*`/`XF86MonBrightness*` keys at exactly one step and one OSD pill per press, and `busctl --user list` still shows a single `org.freedesktop.Notifications` owner.

**Open questions owned**: (4) `Quickshell.Networking` API completeness — decide native D-Bus binding vs an `nmcli` wrapper before committing the wifi panel's implementation.
**Owns**: The milestone's highest D-Bus conflict risk — three new PipeWire / NetworkManager / BlueZ consumers arriving at once alongside existing owners.
**Plans**: 7/9 plans executed

Plans:
**Wave 1**

- [x] 15-01-PLAN.md — Live API probe: `UntypedObjectModel` accessor shape, PipeWire node property keys, `request*`-vs-plain call path, `preferredDefaultAudioSink` write semantics; end-4/Caelestia source study. Emits `15-API-PROBE.md`, no production files

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 15-02-PLAN.md — TRACER: `Super+A` → guarded `openPanel()` → `PanelDialog` frame → `AudioPanel` master volume/mute on live PipeWire → Advanced launches pavucontrol detached → Esc/click-outside dismisses. Fixes the `PanelDialog` public surface all later plans inherit

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 15-03-PLAN.md — Wifi + bluetooth mounts as `PanelDialog` instances with real Advanced targets, the D-15-26 off/empty/no-hardware states, and the shell-root `IpcHandler` every remaining entry point calls

**Wave 4** *(blocked on Wave 3; file-disjoint, parallel)*

- [x] 15-04-PLAN.md — Audio build-out: pinned control block (device pickers as inline expanding rows, input level, mic mute) over the scrolling per-app mixer list; four widget states
- [x] 15-05-PLAN.md — Wifi build-out: scan + progress line, grouped stable ordering, inline PSK row, `ConnectionFailReason` copy mapping, Forget with inline confirm, two-stage Esc
- [x] 15-06-PLAN.md — Bluetooth build-out: adapter toggle, grouped list, contextual-verb rows, chevron expansion, pairing spinner with a real Cancel, inferred-failure recipe, opt-in discovery
- [x] 15-07-PLAN.md — Quick-toggle grid becomes one row of six compact split tiles; body press performs the verb, chevron opens the panel
- [ ] 15-08-PLAN.md — waybar click rewiring across all four configs; `install.sh` gains `network-manager-applet`

**Wave 5** *(blocked on Wave 4 completion)*

- [ ] 15-09-PLAN.md — Criterion-5 proof: four new `quickshell-doctor` checks with a poisoned fixture and `rfkill` fault injection; full gate sweep; phase-close render gate

Cross-cutting constraints:

- **No CLI wrapper where a native binding exists** — no panel reaches `nmcli` / `bluetoothctl` / `wpctl` / `pactl` for any read or write already exposed by `Quickshell.Networking` / `Quickshell.Bluetooth` / `Quickshell.Services.Pipewire` (15-02, restated 15-05, 15-06)
- **No destructive action on a single press** — Forget always reveals an inline confirm first (15-05, 15-06)
- **The DASH-08 fullscreen guard exists exactly once**, inside shell root's `openPanel()`; every summon path — `Super+A`, tile chevron, waybar IPC — routes through it (15-02, consumed 15-07, 15-08)

**UI hint**: yes

### Phase 16: Workspace Overview

**Goal**: A full-screen workspace grid with live window thumbnails that can be clicked into and dragged between.
**Depends on**: Phase 12 for tokens; Phase 11 for the screencopy feasibility verdict; sequenced after Phase 15 so the panel-lifecycle patterns are already proven
**Requirements**: OVER-01, OVER-02, OVER-03, OVER-04
**Success Criteria** (what must be TRUE):

  1. A keybind opens a full-screen grid of workspaces in which every open window appears as a live thumbnail, and a human confirms by eye that at least three real windows across two or more workspaces show live content rather than blank or placeholder tiles.
  2. Clicking a workspace tile focuses that workspace and closes the overview.
  3. Dragging a window thumbnail onto another workspace tile moves that window there, with the drop target visibly highlighted while the drag is in flight.
  4. Live multi-window thumbnail performance is measured on Hyprland 0.56.0 against an agreed frame and CPU budget, and either stays inside it or ships the documented fallback instead — the measurement and the verdict are both recorded.
  5. The overview carries a multi-day use note before it closes; the highest-frequency new surface in the milestone does not close on a single click-and-look.

**Owns**: Live multi-window screencopy performance (the genuine open risk — the protocol question is settled: `ScreencopyView` + `hyprland-toplevel-export-v1`, native to Hyprland, no plugin, no `hyprpm`), and silently-denied screencopy permissions rendering blank tiles instead of erroring.
**Plans**: TBD
**UI hint**: yes

### Phase 17: Ambient Extras

**Goal**: Video wallpaper and dynamic cursors — explicitly the first phase to cut if the milestone runs long.
**Depends on**: Phase 12 (colour tokens only; no other phase depends on this one)
**Requirements**: AMB-01, AMB-02
**Success Criteria** (what must be TRUE):

  1. A video wallpaper plays beneath the desktop and hides itself when a fullscreen client takes focus, with playback owned by an external player rather than decoded inside QML.
  2. Dynamic cursors install as an optional guarded dependency: with the plugin build forced to fail, `install.sh` warns and completes rather than failing, and the desktop keeps a working cursor.
  3. If this phase is cut mid-flight, a consumer-check sweep runs at its close rather than being deferred to milestone close — `stow.sh`, `install.sh`, `windowrules.conf`, `contract.json` and QML imports carry no references to anything it started and did not finish.

**Owns**: Additive scaffolding drift — the eww cleanup cost in the opposite direction, from an addition abandoned rather than a toolkit retired.
**Plans**: TBD

## Progress

**Execution order:** 11 → 12 → {13, 14} → 15 → 16 → 17. Phases 13 and 14 are independent branches that both gate only on Phase 12; 13 runs first by default as risk reduction, not because 14 depends on it.

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Root-Cause Fix & Consolidated Theme Engine | v1.0 | 3/3 | Complete | 2026-07-07 |
| 2. Static ↔ Dynamic Parity & Switch Reliability | v1.0 | 2/2 | Complete | 2026-07-07 |
| 3. Repo Cleanup & Fresh-Install Reproducibility | v1.0 | 4/4 | Complete | 2026-07-08 |
| 4. Reliability Fixes & Tech Debt | v2.0 | 6/6 | Complete | 2026-07-11 |
| 5. Light Mode Pipeline & Theme Presets | v2.0 | 5/5 | Complete | 2026-07-11 |
| 6. Themed Surfaces & Utility Suite | v2.0 | 19/19 | Complete | 2026-07-13 |
| 7. Super-Key Menu | v2.0 | 8/8 | Complete | 2026-07-13 |
| 8. Waybar Evolution | v2.0 | 16/16 | Complete | 2026-07-15 |
| 9. wlogout to wleave Migration | v2.0 | 4/4 | Complete | 2026-07-25 |
| 10. AGS Media Applet | v2.0 | 6/6 | Complete | 2026-07-15 |
| 11. Quickshell Viability Gate | v3.0 | 5/5 | Complete    | 2026-07-26 |
| 12. Unified Design-Token Pipeline | v3.0 | 8/8 | Complete    | 2026-07-27 |
| 13. Motion Retrofit & Existing-Surface Sweep | v3.0 | 7/7 | Complete    | 2026-07-28 |
| 14. Dashboard Drawer | v3.0 | 10/10 | Complete    | 2026-08-01 |
| 15. Audio + Connectivity Panels | v3.0 | 7/9 | In Progress|  |
| 16. Workspace Overview | v3.0 | 0/TBD | Not started | - |
| 17. Ambient Extras | v3.0 | 0/TBD | Not started | - |

**Totals:** 17 phases · 73 plans complete · 2 milestones shipped · v3.0 in progress (38 requirements across 7 phases)
