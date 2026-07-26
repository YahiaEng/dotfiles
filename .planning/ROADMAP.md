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

- [ ] **Phase 11: Quickshell Viability Gate** - Prove pointer, keyboard, focus, multi-monitor, hot reload and coexistence on Hyprland 0.56.0 — with authority to stop the milestone
- [ ] **Phase 12: Unified Design-Token Pipeline** - One source emits colour and MD3 motion tokens to QML, GTK4 CSS and Hyprland, guarded by a motion lint gate
- [ ] **Phase 13: Motion Retrofit & Existing-Surface Sweep** - Apply the motion language to every surface that already exists, and close the carried-in debt on those same surfaces
- [ ] **Phase 14: Dashboard Drawer** - The first real QML surface: a four-tab swipeable drawer sharing state with what already ships
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

## Phase Details

### Phase 11: Quickshell Viability Gate

**Goal**: Quickshell is proven to work on this exact machine — pointer, keyboard, focus, dismiss, multi-monitor, hot reload, and peaceful coexistence with everything already running — or the milestone stops here.
**Depends on**: Nothing (first phase of v3.0; builds on shipped v2.0)
**Requirements**: QS-01, QS-02, QS-03, QS-04, QS-05, QS-06, MAINT-01
**Success Criteria** (what must be TRUE):

  1. A human clicks a button, types into a text field, and dismisses by clicking outside on a throwaway Quickshell `PanelWindow` running on Hyprland 0.56.0 — all three verified before any feature is built on the toolkit, with a dated pass/fail record and explicit authority to STOP the milestone if any one fails.
  2. A Quickshell surface renders correctly on every connected monitor, survives a monitor hotplug and one suspend/resume cycle, hot-reloads on a config edit without a manual restart, and picks up a hand-edited JSON change through `FileView`/`JsonAdapter` with zero `reload.sh` involvement.
  3. `install.sh` installs quickshell and its Qt6 dependencies from the official Arch `extra` repo and `stow.sh` deploys the `quickshell/` package on a clean checkout — both registered in the same commit that creates the package.
  4. Quickshell autostarts with the session and runs alongside waybar, swaync, SwayOSD, wleave, AGS and walker with no visible layout shift: `hyprctl layers -j` confirms namespace identity with no unexpected second claimant at a given layer level, `hyprctl monitors -j`'s `reserved` array carries the actual exclusive-zone reservation and shows no unattributed change after Quickshell autostarts (amended in Phase 11 per D-15 — see 11-QUICKSHELL-EVIDENCE.md), `busctl --user list` shows exactly one `org.freedesktop.Notifications` owner (swaync), volume and brightness keys still move exactly one step per press, and a repaired `keybind-doctor` parses `hyprctl binds` plain-text output on 0.56.0 (amended in Phase 11 per D-15 — see 11-QUICKSHELL-EVIDENCE.md) and reports zero duplicate chords across Hyprland config and Quickshell global shortcuts.
  5. The workspace-overview feasibility question is answered on this build before Phases 12-15 build around it: a live multi-window `ScreencopyView` capture is exercised, and the exact `PERMISSION_TYPE_SCREENCOPY` mechanics and `ecosystem.conf` stanza are recorded — so Phase 16's scope is a decision, not a discovery. (OVER-04's measured budget and documented fallback remain Phase 16's requirement; this is the feasibility probe that de-risks it.)

**Open questions owned**: (1) Does `FileView`/`JsonAdapter` property propagation truly need zero `reload.sh` involvement? (5) Hyprland `PERMISSION_TYPE_SCREENCOPY` mechanics and the exact `ecosystem.conf` stanza — investigated here, relied on by Phase 16.
**Owns**: The viability gate itself (the eww failure class in QML clothing) and same-commit stow registration.
**Plans**: 2/5 plans executed
**Wave 1**

- [x] 11-01-PLAN.md — Tracer: install quickshell, ship the `quickshell/` package registered in one commit, prove human click/type/click-outside-dismiss (QS-01, QS-02; STOP authority)

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 11-02-PLAN.md — Repair `keybind-doctor` via plain-text parsing, cross-check Quickshell-claimed chords, prove the collision check fails on a poisoned fixture (MAINT-01)

**Wave 3** *(blocked on Wave 2 completion)*

- [ ] 11-03-PLAN.md — `quickshell-doctor`: the rerunnable layer-shell / D-Bus / single-owner coexistence gate (QS-05, QS-06)

**Wave 4** *(blocked on Wave 3 completion)*

- [ ] 11-04-PLAN.md — Durability: headless-output hotplug, hot reload, `FileView`/`JsonAdapter` propagation, suspend/resume (QS-03, QS-04)

**Wave 5** *(blocked on Wave 4 completion)*

- [ ] 11-05-PLAN.md — Screencopy feasibility probe, criterion-5 amendment, and the phase verdict (QS-02, QS-05)

### Phase 12: Unified Design-Token Pipeline

**Goal**: One token source renders colour and motion to QML, GTK4 CSS and Hyprland without drift, and the gates refuse any surface that hand-rolls its own values.
**Depends on**: Phase 11
**Requirements**: TOKEN-01, TOKEN-02, TOKEN-03, TOKEN-04, TOKEN-05, TOKEN-06
**Success Criteria** (what must be TRUE):

  1. A theme switch re-colours a live Quickshell surface without restarting it, with the palette read from `~/.local/state/theme/` as a `contract.json`-listed matugen render target — no copied palette file, no hex literal in any repo-authored QML.
  2. A single hand-authored motion-token definition (MD3 Expressive named duration + bezier pairs) renders to all three targets — QML, GTK4 CSS and Hyprland — in one `theme-apply` run, with the Hyprland `bezier =` syntax and the GTK4 easing mechanism each chosen by testing the installed binary rather than assumed, and `hyprctl animations -j` afterwards confirming every emitted curve holds its generated values rather than a silently substituted default.
  3. `theme-doctor` fails on a deliberately poisoned surface that hand-rolls a raw duration or easing curve, and passes once that surface consumes a motion token instead — proven to fail, not merely observed to pass.
  4. A reduced-motion setting, driven through `theme-apply`'s existing single entrypoint, visibly shortens or disables animation on a QML surface, a GTK surface and a Hyprland window animation in the same run.
  5. *(Stretch — blocks nothing.)* A human watches native QML spring physics and the MD3 baseline render the same token side by side and records which is adopted; dropping this changes no other phase.

**Open questions owned**: (2) GTK4 CSS `linear(<stops>)` easing support — test empirically, default assumption is unsupported and keyframes are the safe fallback. (3) Hyprland 0.56.0 `bezier =` vs Lua `hl.curve(...)` — verify against the installed binary. (6) Quickshell reduced-motion — no ecosystem precedent exists anywhere; design it from scratch.
**Owns**: Token-schema decisions, the fidelity ceiling, the reduced-motion axis, and the generator safeguards against malformed emitted curves.
**Plans**: TBD
**UI hint**: yes

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
**Plans**: TBD
**UI hint**: yes

### Phase 14: Dashboard Drawer

**Goal**: The first real QML surface — a four-tab swipeable dashboard drawer that reads the state the desktop already owns instead of forking it.
**Depends on**: Phase 12 (independent branch — does **not** depend on Phase 13)
**Requirements**: DASH-01, DASH-02, DASH-03, DASH-04, DASH-05, DASH-06, DASH-07, DASH-08
**Success Criteria** (what must be TRUE):

  1. A keybind opens the dashboard drawer and a click outside dismisses it; the rest of the desktop stays interactive the whole time, and `hyprctl layers -j` shows the drawer holding zero exclusive zone on any edge waybar already reserves.
  2. Four tabs — Dashboard, Media, Performance, Weather — are reachable both by horizontal drag with a threshold commit that springs back below the threshold, and by a direct tap on the header row.
  3. The Dashboard tab shows a calendar, date/time, a compact media widget and system resources at a glance; the Media tab shows a full player with cover art; the Performance tab shows CPU, memory, network, storage and battery; the Weather tab shows current conditions and forecast and stays readable rather than blank or broken when the weather service is unreachable.
  4. The media widget reads the existing MPRIS active-player state — the AGS card, waybar and the dashboard all show the same track and player simultaneously, and no second media backend exists.
  5. Flipping a dashboard quick-toggle changes swaync's existing toggle grid to match and vice versa, with no second source of truth for that state; and neither the dashboard nor any panel opens over a fullscreen client.

**Owns**: The "overlay by default, zero exclusive zone" layer-shell convention that Phases 15 and 16 inherit, and the shared-state pattern for anything the desktop already tracks.
**Plans**: TBD
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
**Plans**: TBD
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
| 11. Quickshell Viability Gate | v3.0 | 2/5 | In Progress|  |
| 12. Unified Design-Token Pipeline | v3.0 | 0/TBD | Not started | - |
| 13. Motion Retrofit & Existing-Surface Sweep | v3.0 | 0/TBD | Not started | - |
| 14. Dashboard Drawer | v3.0 | 0/TBD | Not started | - |
| 15. Audio + Connectivity Panels | v3.0 | 0/TBD | Not started | - |
| 16. Workspace Overview | v3.0 | 0/TBD | Not started | - |
| 17. Ambient Extras | v3.0 | 0/TBD | Not started | - |

**Totals:** 17 phases · 73 plans complete · 2 milestones shipped · v3.0 in progress (38 requirements across 7 phases)
