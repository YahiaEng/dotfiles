# Roadmap: Arch + Hyprland Dotfiles

## Milestones

- ✅ **v1.0 Theme Pipeline Repair** — Phases 1-3 (shipped 2026-07-09) — [archive](milestones/v1.0-ROADMAP.md)
- ✅ **v2.0 Desktop Expansion** — Phases 4-10 (shipped 2026-07-25) — [archive](milestones/v2.0-ROADMAP.md)
- ✅ **v3.0 Quickshell Foundation & Motion Language** — Phases 11-17 (shipped 2026-08-10) — [archive](milestones/v3.0-ROADMAP.md)
- 🔨 **v4.0 Shell Migration & Debt Paydown** — Phases 18-22 (active, roadmapped 2026-08-10)

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

<details>
<summary>✅ v3.0 Quickshell Foundation & Motion Language (Phases 11-17) — SHIPPED 2026-08-10</summary>

- [x] Phase 11: Quickshell Viability Gate (5/5 plans) — completed 2026-07-26
- [x] Phase 12: Unified Design-Token Pipeline (8/8 plans) — completed 2026-07-27
- [x] Phase 13: Motion Retrofit & Existing-Surface Sweep (7/7 plans) — completed 2026-07-28
- [x] Phase 13.1: Hyprland Lua Config Migration (10/10 plans) — completed 2026-07-28 (INSERTED — urgent, upstream deadline)
- [x] Phase 14: Dashboard Drawer (10/10 plans) — completed 2026-08-01
- [x] Phase 15: Audio + Connectivity Panels (14/14 plans) — completed 2026-08-02
- [x] Phase 16: Workspace Overview (8/8 plans) — completed 2026-08-08 (UAT 30/30, 2026-08-10)
- [x] Phase 17: Ambient Extras (6/6 plans) — completed 2026-08-10

Phase 13.1 was inserted mid-milestone against a real upstream deadline —
Hyprland 0.57 removes hyprlang `.conf` support — and was not discretionary.
Phase 17 was scoped as the first thing to cut if the milestone ran long; it
shipped in full.

Closed as an **override closeout**: Phase 16 has no VERIFICATION.md (its
evidence is `16-UAT.md`, 30/30 passed), and 53 open artifacts were acknowledged
as carried debt. See `milestones/v3.0-MILESTONE-AUDIT.md` and STATE.md
`## Deferred Items`.

Full details: [milestones/v3.0-ROADMAP.md](milestones/v3.0-ROADMAP.md)

</details>

### 🔨 v4.0 Shell Migration & Debt Paydown (Phases 18-22) — ACTIVE

- [ ] **Phase 18: QML Bar & Retirement Machinery** - The always-on bar replaces waybar, and every gate and script the later retirements depend on is built and proven once
- [ ] **Phase 19: Notification Server & Centre** - The shell itself owns `org.freedesktop.Notifications`; popups, slide-out centre and swaync's deletion land together with no rollback
- [ ] **Phase 20: Indicators & Power Menu** - QML volume/brightness/caps-lock indicators and the six-action power menu; SwayOSD, wleave and the leftover wlogout/eww packages leave the host
- [ ] **Phase 21: Media Fold-In & Contract Close** - The AGS card folds into the dashboard's Media tab behind a cava go/no-go, ending the MPRIS duplication and closing `contract.json` at its post-migration size
- [ ] **Phase 22: Fresh-Install Proof** - The D-34/D-36 container gate proves a clean clone still reproduces the whole desktop after all five packages are gone

## Phase Details

### Phase 18: QML Bar & Retirement Machinery
**Goal**: The bar the user looks at all day is a Quickshell surface, and every piece of machinery the other four retirements depend on exists and has been exercised once for real.
**Depends on**: Nothing (first v4.0 phase; builds on the Quickshell root v3.0 shipped)
**Requirements**: QBAR-01, QBAR-02, QBAR-03, QBAR-04, QBAR-05, QBAR-06, QBAR-07, QBAR-08, QBAR-09, QBAR-10, QBAR-11, QBAR-12, RETIRE-01, RETIRE-02, GATE-01, GATE-02, GATE-03, GATE-04, LEDGER-01, LEDGER-03
**Success Criteria** (what must be TRUE):
  1. One QML bar renders permanently in Athena's rounded-capsule language, reserves its own screen space, and flips between a horizontal top strip and a right-edge vertical column from one config value — carrying clock, battery, network, bluetooth, audio, CPU/RAM/disk and a working system tray in both orientations.
  2. Clicking a workspace switches to it, scrolling the audio and brightness sections adjusts them, tray menus open on click, and clicking a section opens that section's own detail popout instead of routing through the dashboard.
  3. The bar hides completely — never a lit sliver — under idle, fullscreen, gaming mode and the keybind with exactly one owner of visibility state, and reveals on pointer hover or on holding Super.
  4. Killing the bar's process brings it back with no manual step; after a multi-hour session its RSS, process count and idle-timer inventory are where they started; and its reserved zone is byte-identical after `hyprctl reload` and after a QML hot reload.
  5. `waybar` is gone from repo and host — package, config, 7 contract entries, `[templates.waybar]`, its `reload.sh` fan-out, `waybar-equivalence-check` and `waybar-design-lint` — with the new retirement checklist script run before *and* after the deletion reporting zero remaining hits, and the human render gate judging the bar at least as good as the four layouts it replaced.
**Notes**:
- **GATE-01 is scheduled per-phase, not as an upfront enumeration phase.** Justification: the enumeration must be read off the live implementation *while it still exists*, and nothing is deleted before its own migration phase — so every surface's old implementation is demonstrably still readable at that surface's phase start. An upfront phase would write the AGS enumeration four phases before anyone uses it (stale by the time it constrains a design) and would deliver no user-observable outcome of its own. GATE-01 is mapped here because this is where the enumeration discipline is established and its per-phase recurrence becomes a standing opening task for Phases 19-21.
- **GATE-02 is a per-phase closing gate, not a phase.** Mapped here because it is established here; it recurs unchanged as the blocking close condition on Phases 19, 20 and 21. No old package is deleted before its judgment.
- **GATE-03 and GATE-04 are established here because this is where the coverage they replace dies.** `waybar-equivalence-check` and `waybar-design-lint` are deleted in this phase; the `quickshell-doctor` structural checks and the QML hex-literal lint are minted in the same phase so no surface is ever born outside them.
- **LEDGER-01 is near-zero cost and attaches here** — both carry-ins are already fixed in code (`PanelDialog.qml:191`, commit `4f48847`; `quickshell-doctor` already on `hl.dsp.global`). It needs one visual confirmation that the panel rim renders, then PROJECT.md / MILESTONES.md / WINDOWS #14 / the debug-session status corrected. No QML work.
- **LEDGER-03 attaches here** because the always-on bar is the first and right place to finally measure OVER-04's frame-rate term (`QSG_RENDER_LOOP=threaded`, 165Hz panel).
- **No per-screen fan-out.** QS-03 is permanently dropped under D-13; the bar copies `Overview.qml`'s single-`PanelWindow` pattern and must not re-attempt `Variants`.
- **New hazard, name it in the plan:** this is the first surface with `exclusiveZone > 0`, the first with no dismissed state (so it inherits none of the zero-idle discipline), and it shares a process with the notification server built in Phase 19 — QBAR-10's restart wrapper is the mitigation, since `quickshell-launch.sh` has none today.
**Plans**: 20 plans across 10 waves

**Wave 1** — tracer + the three no-dependency openers
- 18-01 TRACER: one `Bar.qml` `PanelWindow`, bar tokens, `exclusiveZone: 46`, one live clock capsule (QBAR-01)
- 18-02 GATE-01 behaviour enumeration, read off the live waybar while it still exists (GATE-01)
- 18-03 GATE-04 hex-literal lint, `color:`-anchored, folded blocking into `theme-doctor` (GATE-04)
- 18-04 LEDGER-01 documentation close — no QML work (LEDGER-01)

**Wave 2** *(blocked on Wave 1 completion)*
- 18-05 QBAR-02 the one entry list, capsule chrome, six pre-declared slots (QBAR-02)
- 18-06 RETIRE-01 generic `retirement-check <surface>` script, two tiers (RETIRE-01)
- 18-07 QBAR-10 systemd `--user` restart unit (QBAR-10)

**Wave 3** *(blocked on Wave 2 completion — four-wide parallel by construction)*
- 18-08 QBAR-06 system + media/connectivity readouts, `MediaBackend` → native Mpris (QBAR-06)
- 18-09 QBAR-03 workspace capsule, click-to-switch (QBAR-03)
- 18-10 QBAR-05 tray capsule, first `SystemTray`/`DBusMenu` consumer (QBAR-05)
- 18-11 both athena drawers + actions capsule + orientation toggle (QBAR-01, QBAR-02)

**Wave 4** *(blocked on Wave 3 completion)*
- 18-12 QBAR-04 scroll-to-adjust; brightness present-but-inert per D-18-39 (QBAR-04)

**Wave 5** *(blocked on Wave 4 completion)*
- 18-13 QBAR-09 popout frame + hover contract, proven on audio only (QBAR-09)

**Wave 6** *(blocked on Wave 5 completion)*
- 18-14 the remaining five popout bodies (QBAR-09)
- 18-15 QBAR-07 full auto-hide, `bar-visibility.sh` sole owner, dim state deleted (QBAR-07)

**Wave 7** *(blocked on Wave 6 completion)*
- 18-16 QBAR-08 hot zone + Super-hold reveal (QBAR-08)

**Wave 8** *(blocked on Wave 7 completion)*
- 18-17 GATE-03 doctor checks — inverts the reserved-space invariant — + QBAR-12 zone stability (GATE-03, QBAR-12)
- 18-18 QBAR-11 soak + LEDGER-03 frame rate via `QSG_RENDER_TIMING=1` (QBAR-11, LEDGER-03)

**Wave 9** *(blocked on Wave 8 completion)*
- 18-19 GATE-02 blocking human render gate — authorises or blocks the deletion (GATE-02)

**Wave 10** *(blocked on Wave 9 completion)*
- 18-20 RETIRE-02 waybar deletion, config-then-package in one commit (RETIRE-01, RETIRE-02)

Cross-cutting constraints:
- GATE-01 (18-02, wave 1) reads the live waybar config eight waves before 18-20 deletes it.
- GATE-02 (18-19, wave 9) is a blocking close condition: no old package is deleted before it passes.
- `retirement-check` runs **twice** — 18-06 captures the pre-deletion baseline, 18-20 re-runs it after.
- GATE-04 is minted in wave 1 so no bar surface is ever born outside the hex-literal lint.
- 18-05's stub pre-declaration is what makes wave 3 four-wide; each wave-3 plan owns one component file.

**UI hint**: yes

### Phase 19: Notification Server & Centre
**Goal**: The shell itself is the desktop's notification receiver, with the full popup + slide-out-centre experience, and swaync is deleted in the same phase with no fallback path.
**Depends on**: Phase 18 (reuses the bar's proven button/IPC summon path and its process; the centre button lives on the bar)
**Requirements**: QNOTIF-01, QNOTIF-02, QNOTIF-03, QNOTIF-04, QNOTIF-05, QNOTIF-06, QNOTIF-07, QNOTIF-08, QNOTIF-09, QNOTIF-10, QNOTIF-11, RETIRE-03, LEDGER-04, LEDGER-07, LEDGER-08
**Success Criteria** (what must be TRUE):
  1. Applications' notifications reach the shell directly and appear as popups that stack and reflow smoothly, dismiss on a sideways swipe, whose own action buttons work and reach the sending application, and where a progress-style notification (download, volume) updates its existing card in place instead of stacking new ones.
  2. A slide-out centre opens showing notification history with clear-all, carrying the quick-toggle grid and working volume/brightness sliders, with no drift between its toggle state and the Super-key menu's.
  3. Do-not-disturb is a quick toggle whose state survives a shell restart, and popups stay suppressed while the centre is open and while a fullscreen client is focused.
  4. A live bus check against the running session — the existing poisoned-two-owner fixture re-pointed and run for real, not self-tested — shows exactly one owner of `org.freedesktop.Notifications`, and still exactly one after the server is deliberately killed and respawned.
  5. `swaync` is gone from repo and host (package, config, 2 contract entries, `[templates.swaync]`, its `reload.sh` step, its `swaync-launch.sh` autostart line, its doctor fixtures re-pointed), the checklist script reports zero hits before and after, and the human render gate judges the replacement at least as good as swaync was.
  6. The six open debug sessions each reach `resolved` or an explicitly-reasoned deferral — including the bluetooth pairing prompt, whose containment Phase 15 deferred *to this very surface* — the panel family carries a completed security review with the verifier re-run over its gap-closure round, and `theme-stress-test` reaches a full clean run with the tree still clean afterwards.
**Notes**:
- **swaync is deleted in this phase, no soak window.** This overrides the research's disabled-but-installed recommendation and is the user's explicit call at scoping. Consequence to carry into planning: there is no fast rollback and a dropped notification leaves no trace, so **QNOTIF-05 and QNOTIF-11 carry extra verification weight** — fault-injection fixtures for `replaces_id` and `ActionInvoked` must exist and be green *before* the human render gate, and QNOTIF-11's live two-owner check is blocking, not advisory.
- **The autostart swap must be one atomic edit.** Removing `swaync-launch.sh`'s line and adding the new owner's must never be two commits — every boot in between silently runs the two-owner race.
- **DND ownership moves into QML here.** Today it is a `swaync-client -dn/-df` CLI call from both grids; once swaync is gone there is no external CLI to shell out to.
- **Promote the toggle grid, do not copy it.** `QuickToggles.qml` becomes a shared type instantiated by both the drawer and the centre. Rendering the same grid twice against the same scripts would carry today's swaync/drawer duplication forward under a new name — the exact thing this milestone exists to end.
- **Debt interleave rationale:** LEDGER-04's six sessions are 4/6 wifi-bluetooth from Phase 15 and one is the GradientBorder session LEDGER-01 already closes in Phase 18 — this phase is where the bluetooth one becomes structurally resolvable. LEDGER-08's security review covers the same panel family whose components this phase extends, and is the right pass to run alongside taking a system-wide D-Bus role. LEDGER-07 lands here rather than later so that Phases 20-22 all run against a fully clean `theme-stress-test`, and so RETIRE-08's contract check in Phase 21 has a trustworthy baseline.
**Plans**: TBD
**UI hint**: yes

### Phase 20: Indicators & Power Menu
**Goal**: Volume, brightness and caps-lock feedback and the session power menu are QML surfaces, and three more packages plus two host-level leftovers are gone.
**Depends on**: Phase 19 (the OSD reuses the transient-toast frame type built there). The power-menu half has no shared backend and may be built in parallel with the OSD half inside this phase.
**Requirements**: QOSD-01, QOSD-02, QOSD-03, QOSD-04, QPOWER-01, QPOWER-02, QPOWER-03, QPOWER-04, RETIRE-04, RETIRE-05, RETIRE-07, LEDGER-02, LEDGER-05
**Success Criteria** (what must be TRUE):
  1. Pressing volume or brightness keys shows a QML indicator, including while the lock screen is up, and Caps Lock shows one with no root service anywhere in the path — read from the keyboard LED's sysfs node via a watched file. Indicators auto-hide after a delay and stay open while hovered.
  2. When more than one control has moved, volume, microphone and brightness appear as independent sliders in one column, each individually adjustable — and a control that did not actually move does not appear at all.
  3. The power menu offers Shutdown, Reboot, Suspend, Hibernate, Logout and Lock, is fully keyboard-navigable with visible focus (first action auto-focused on open, Enter activates, Escape closes), and warns before a destructive action while a package manager or download is still running.
  4. Shutdown and Reboot still take the graceful compositor exit that closed the FIX-01 hang class, and Logout is settled by the D-29 teardown measurement being *taken* — then wrapped, or recorded with evidence as needing no wrapping.
  5. `swayosd` (with its libinput backend's fate decided explicitly, not by omission), `wleave`, and the still-installed `wlogout` and `eww` packages are all gone from repo and host, checklist-verified zero-hits before and after each deletion, with the human render gate judging both replacements at least as good as what they replaced.
  6. Every open WINDOWS.md row is closed or re-deferred with a stated reason — none left silently open.
**Notes**:
- **Two surfaces, one phase, deliberately.** Granularity is `coarse` and the milestone brief marks QPOWER as independently schedulable with the lowest risk and closest existing precedent (Phase 9's six-capsule wleave). Combining avoids a thin phase without creating a dependency that does not exist.
- **QOSD's real gap is Caps Lock only.** Volume/brightness/media keys were verified already routing through Hyprland binds with `locked=true`, so retiring SwayOSD's *renderer* is an exec-target swap, not a lock-screen regression. The `swayosd-libinput-backend.service` decision is a named scope call needing explicit sign-off — it reaches contexts a compositor bind cannot (TTY, pre-session) — and must be recorded either way, BAR-02-style, not defaulted into.
- **Residual risk to check once:** the sysfs LED node name across a reboot or keyboard re-enumeration.
- **RETIRE-07 lands here** because this is the phase running the checklist script twice for two surfaces already, and because `wlogout` is the direct lineage of the power menu being replaced. One `pacman -Rns` covering both leftovers, through the same checklist.
- **Debt interleave rationale:** LEDGER-02 is Logout, which *is* QPOWER-01's fifth action and shares QPOWER-04's graceful-exit mechanism — measuring it anywhere else would mean setting up the same teardown twice. LEDGER-05's WINDOWS rows should be triaged and sized at phase start, not closed in a rush at phase end.
- **Security carry-over from Phase 15:** re-run the "who owns the prompt" check against the new power menu — a layer-shell overlay is unconditionally above every XDG toplevel, so any confirm dialog another app raises would land behind it.
**Plans**: TBD
**UI hint**: yes

### Phase 21: Media Fold-In & Contract Close
**Goal**: One now-playing surface remains in the whole desktop, and the theme contract reaches its post-migration shape with every gate green.
**Depends on**: Phase 18 (waybar's own mpris reader must already be gone before the reader count can be closed). Opens with a blocking cava go/no-go spike before any design work.
**Requirements**: QMEDIA-01, QMEDIA-02, QMEDIA-03, RETIRE-06, RETIRE-08, LEDGER-06
**Success Criteria** (what must be TRUE):
  1. The dashboard's Media tab does everything the standalone AGS card did — transport, seek, cover art, per-player volume and player switching.
  2. An audio-reactive visualiser renders as a ring around shaped cover art while audio plays, restoring the cava element Phase 14 cut — or the phase carries a recorded human go/no-go verdict saying explicitly why it does not. Deleting the AGS card without settling this either way would be a silent downgrade against GATE-02.
  3. Exactly one MPRIS reader runs anywhere in the desktop, and `ags/` is gone from repo and host with its contract entry, `[templates.ags]`, its `reload.sh` step and its layer rules, checklist-verified zero-hits before and after.
  4. `theme-doctor` and `theme-parity` are green with `contract.json` at its post-migration size (29 → ~17) and no orphaned entries.
  5. Phase 16's `16-VERIFICATION.md` exists, its two malformed `coverage:` blocks are corrected, and quick task `260728-51j` is resolved.
**Notes**:
- **The cava spike is the phase's opening gate, not a mid-phase discovery.** `MediaTab.qml`'s own header already records the static dashed ring as a deliberate Phase 14 scope cut ("this repo has no cava/audio-analysis service anywhere in its QML toolkit"). Option (a) is a new `Process` streaming cava's raw-bar output into a QML visualiser — architecturally the same shape as `MediaBackend`'s existing streaming reader, so not unprecedented. Option (b) is explicit human sign-off on losing it. Do not let this default silently.
- **Frame the reader count honestly:** waybar's mpris module already died in Phase 18, so this phase removes the *second* of three, not the third. The underlying scripts were never duplicated — only the client wrappers.
- **RETIRE-08 lands here** because this is where the fifth and final contract entry and matugen template are removed; Phase 22 then proves it on a genuinely fresh install.
- **Debt interleave rationale:** LEDGER-06 is the Phase 16 paperwork — that phase's missing VERIFICATION.md concerns the workspace overview, a QML surface, and its malformed coverage blocks are the same classifier discipline this milestone's own UAT depends on. Placing it in a migration phase rather than the closing phase keeps it from becoming end-of-milestone filler.
**Plans**: TBD
**UI hint**: yes

### Phase 22: Fresh-Install Proof
**Goal**: A clean clone of the post-migration repo still reproduces the whole themed desktop — the milestone's closing regression gate for five package deletions.
**Depends on**: Phases 18, 19, 20, 21 (all five retirements must have landed)
**Requirements**: RETIRE-09
**Success Criteria** (what must be TRUE):
  1. The D-34/D-36 container gate runs green against a genuine fresh remote clone through `install.sh` + `stow.sh`, with `theme-parity` passing inside that fresh install.
  2. No waybar, swaync, swayosd, wleave or ags package, config, symlink, contract entry or dangling reference exists anywhere in the reproduced system.
  3. The retirement checklist script reports zero hits for all five retired surface names plus `wlogout` and `eww` across the whole repo.
**Notes**:
- **Single-requirement phase, and deliberately so.** RETIRE-09 structurally cannot run until every deletion has landed: running it earlier would only prove the *pre-migration* install still reproduces, which is already known. It is the milestone's exit criterion, not bookkeeping — PROJECT.md's own framing is "this milestone deletes stow packages, so a fresh-install proof is a regression gate."
- **Not a pure-debt phase.** Every LEDGER item is interleaved into Phases 18-21; nothing debt-shaped is parked here. This phase carries one retirement-mechanics requirement and nothing else.
- **The dev host will lie to you.** It still has the old packages installed even after `stow.sh`/`install.sh` were edited — this gate is the only thing that surfaces a dead symlink or missing package that daily-driver testing never would.
**Plans**: TBD

## Progress

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
| 11. Quickshell Viability Gate | v3.0 | 5/5 | Complete | 2026-07-26 |
| 12. Unified Design-Token Pipeline | v3.0 | 8/8 | Complete | 2026-07-27 |
| 13. Motion Retrofit & Existing-Surface Sweep | v3.0 | 7/7 | Complete | 2026-07-28 |
| 13.1. Hyprland Lua Config Migration | v3.0 | 10/10 | Complete | 2026-07-28 |
| 14. Dashboard Drawer | v3.0 | 10/10 | Complete | 2026-08-01 |
| 15. Audio + Connectivity Panels | v3.0 | 14/14 | Complete | 2026-08-02 |
| 16. Workspace Overview | v3.0 | 8/8 | Complete | 2026-08-08 |
| 17. Ambient Extras | v3.0 | 6/6 | Complete | 2026-08-10 |
| 18. QML Bar & Retirement Machinery | v4.0 | 0/? | Not started | - |
| 19. Notification Server & Centre | v4.0 | 0/? | Not started | - |
| 20. Indicators & Power Menu | v4.0 | 0/? | Not started | - |
| 21. Media Fold-In & Contract Close | v4.0 | 0/? | Not started | - |
| 22. Fresh-Install Proof | v4.0 | 0/? | Not started | - |

**Totals:** 23 phases (18 complete) · 141 plans complete · 3 milestones shipped

## Requirement Coverage

All 55 v4.0 requirements map to exactly one phase. No orphans, no duplicates.

| Phase | Requirements | Count |
|-------|--------------|-------|
| 18 | QBAR-01..12, RETIRE-01, RETIRE-02, GATE-01..04, LEDGER-01, LEDGER-03 | 20 |
| 19 | QNOTIF-01..11, RETIRE-03, LEDGER-04, LEDGER-07, LEDGER-08 | 15 |
| 20 | QOSD-01..04, QPOWER-01..04, RETIRE-04, RETIRE-05, RETIRE-07, LEDGER-02, LEDGER-05 | 13 |
| 21 | QMEDIA-01..03, RETIRE-06, RETIRE-08, LEDGER-06 | 6 |
| 22 | RETIRE-09 | 1 |
| **Total** | | **55** |

Per-requirement mapping lives in `REQUIREMENTS.md` § Traceability.

## Sequencing Rationale

**Build order is bar → notifications → OSD**, per the research's dependency
analysis. The bar is first because it has the highest daily contact and because
its patterns — always-on `PanelWindow`, `exclusiveZone > 0`, the config-driven
entry list, the restart wrapper, the retirement checklist — seed every later
surface. Notifications follow because the centre needs a bar button to open it,
and the OSD follows notifications because it reuses the transient-toast frame
type built there rather than becoming a third frame.

**The power menu is independently schedulable** — no shared backend, lowest
risk, closest existing precedent — so it shares Phase 20 with the OSD rather
than occupying a thin phase of its own.

**Media is last of the migrations** and opens with a blocking cava go/no-go
spike before design, because retiring the AGS card without settling the
visualiser would be a silent downgrade.

**The fresh-install gate is the milestone's final phase**, after all five
retirements land — not threaded through individual phases, where it could only
ever prove the pre-migration state.

**Each RETIRE-02..06 sits in the same phase as the surface it retires.** The
package dies in the phase that proves its replacement; that is the point of the
milestone, and WINDOWS #1 (an orphaned `eww.scss` contract entry that blocked
`theme-doctor` for a full milestone) is the standing precedent for why the
package deletion, the contract entry, the matugen template, the reload step and
any checker script must land in the *same commit*, config-then-package.
RETIRE-01's checklist script lands in Phase 18 because every later retirement
depends on it.

**Debt does not trail.** All eight LEDGER requirements are interleaved into the
four migration phases — none is parked in a cleanup phase, and Phase 22 carries
no debt at all. Research explicitly warns that debt-paydown gets silently
dropped when migration runs long, and v3.0's own closeout names this as the open
test of v4.0. If the milestone runs long, cut migration stretch goals first,
never the debt.

## Next Milestone

v5.0 is unscoped. Standing candidates:

- **Rebuild walker/elephant in QML** — deliberately excluded from v4.0. Whether
  shell consistency justifies rebuilding fuzzy search, app indexing, clipboard
  and calc providers is the open question.
- **Per-screen surface fan-out (QS-03)** — dropped one-way under D-13; revisit
  only if a second monitor arrives *and* upstream fixes it.
- **ICON-BROWSE** — browse/install *new* icon themes from the picker (repo/AUR
  discovery); v2.0 shipped apply-only.
