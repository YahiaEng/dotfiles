# Requirements: Arch + Hyprland Dotfiles — v4.0 Shell Migration & Debt Paydown

**Defined:** 2026-08-10
**Core Value:** One theme switch — static or dynamic — instantly and consistently re-themes the entire desktop, and the whole setup reproduces from scratch with one script.

**Milestone goal:** Rebuild every remaining pre-Quickshell surface in QML — redesigned toward the end-4/Caelestia reference language rather than straight-ported — retire each old package once its replacement is proven better, and clear the full v3.0 debt ledger, so the milestone ends with one shell and a clean backlog.

**REQ-ID note:** v4.0 uses new prefixes (`QBAR`, `QNOTIF`, `QOSD`, `QPOWER`, `QMEDIA`, `RETIRE`, `LEDGER`, `GATE`) rather than continuing v2.0's `BAR-*`/`OSD-*`/`WLOG-*` or v3.0's `MEDIA-*`, so a v4.0 requirement can never be confused with the v2.0/v3.0 requirement for the surface it replaces.

## v4.0 Requirements

### QBAR — Status bar (replaces waybar)

- [x] **QBAR-01**: The bar renders as a permanently-mounted surface that reserves its own screen space, in Athena's rounded-capsule visual language
- [x] **QBAR-02**: One bar component switches between a horizontal top strip and a **right-edge** vertical column from config — orientation is a property of a config-driven entry list, not a forked second layout. Replaces all four current waybar layouts.
- [x] **QBAR-03**: User can click a workspace indicator to switch to that workspace (restores the capability dead under waybar 0.15.0's compiled-in dispatch)
- [x] **QBAR-04**: User can scroll on the bar's audio and brightness sections to adjust them
- [W] **QBAR-05**: The system tray shows running tray applications and their menus open on click — **Withdrawn (superseded by 18.1 D-15):** the tray was deliberately dropped in phase 18.1 to match Athena, whose own config records removing it because nm-applet and blueman icons duplicated the connections group; the connections capsule continues to surface that state, so the capability is superseded rather than lost.
- [x] **QBAR-06**: The bar shows clock, battery, network, bluetooth, audio and CPU/RAM/disk readouts
- [ ] **QBAR-07**: The bar auto-hides **fully** (never a persistent sliver — OLED constraint) driven by idle, fullscreen, gaming mode and a keybind, with exactly one owner of visibility state
- [ ] **QBAR-08**: The hidden bar reveals on pointer hover **and** on holding Super *(named addition)*
- [x] **QBAR-09**: Clicking a bar section opens that section's own detail popout, in place of routing everything through the dashboard *(named addition)*
- [x] **QBAR-10**: The bar returns automatically if its process dies — no manual restart
- [x] **QBAR-11**: The bar's memory and process count stay flat across a multi-hour soak — no RSS creep, no accumulated subprocesses, no idle timers doing nothing
- [x] **QBAR-12**: The bar's reserved screen space survives `hyprctl reload` and a QML hot reload without drift or overlap

### QNOTIF — Notifications and centre (replaces swaync)

- [ ] **QNOTIF-01**: The shell itself is the system's notification receiver — it owns the `org.freedesktop.Notifications` D-Bus name, and applications' notifications reach it directly
- [ ] **QNOTIF-02**: Notifications appear as popups that stack and reflow smoothly as they enter and leave
- [ ] **QNOTIF-03**: User can dismiss a popup by swiping it sideways
- [ ] **QNOTIF-04**: A notification's own action buttons work, and invoking one reaches the sending application
- [ ] **QNOTIF-05**: A progress-style notification (download, volume) updates its existing card in place instead of stacking new ones
- [ ] **QNOTIF-06**: User can open a slide-out centre showing notification history, with clear-all
- [ ] **QNOTIF-07**: The centre carries the quick-toggle grid, sharing state with the Super-key menu with no drift between them
- [ ] **QNOTIF-08**: The centre carries working volume and brightness sliders
- [ ] **QNOTIF-09**: Do-not-disturb is a quick toggle and its state persists across a shell restart
- [ ] **QNOTIF-10**: Popups are suppressed while the centre is open and while a fullscreen client is focused
- [ ] **QNOTIF-11**: A live two-owner check proves no second notification server is registered — `quickshell-doctor`'s existing poisoned-two-owner fixture is pointed at the new owner and run against a real session, not only self-tested

### QOSD — On-screen indicators (replaces SwayOSD)

- [ ] **QOSD-01**: Volume and brightness indicators appear on the media keys, including while the lock screen is up
- [ ] **QOSD-02**: A Caps Lock indicator appears with **no root service** — read from the keyboard LED's sysfs node via a watched file
- [ ] **QOSD-03**: Indicators auto-hide after a delay and stay open while hovered
- [ ] **QOSD-04**: Volume, microphone and brightness show as independent sliders in one column when more than one has changed — each individually adjustable, each appearing only if that control actually moved *(named addition)*

### QPOWER — Power menu (replaces wleave)

- [ ] **QPOWER-01**: Six actions available — Shutdown, Reboot, Suspend, Hibernate, Logout, Lock
- [ ] **QPOWER-02**: Fully keyboard-navigable with visible focus; Enter activates, Escape closes, first action auto-focused on open
- [ ] **QPOWER-03**: The menu warns before a destructive action when a package manager or download is still running *(named addition)*
- [ ] **QPOWER-04**: Shutdown and Reboot keep the graceful compositor exit that closed the FIX-01 hang class

### QMEDIA — Media fold-in (replaces the AGS card)

- [ ] **QMEDIA-01**: The dashboard's Media tab carries transport, seek, cover art, per-player volume and player switching — everything the standalone card did
- [ ] **QMEDIA-02**: An audio-reactive visualiser renders as a ring around shaped cover art, restoring the cava element the Media tab cut in Phase 14
- [ ] **QMEDIA-03**: Exactly one MPRIS reader remains in the whole desktop — the three-consumer duplication v3.0 priced in is ended

### RETIRE — Retirement mechanics

- [x] **RETIRE-01**: A retirement checklist **script** exists covering every reference class (window/layer rules, autostart, keybinds, `contract.json`, matugen templates, doctor registries and fixtures, systemd `--user` units, D-Bus activation files, XDG autostart, `install.sh`/`stow.sh` lists) and is run before *and* after each deletion
- [ ] **RETIRE-02**: `waybar` is removed — package, config, contract entries, matugen template, `waybar-equivalence-check` and `waybar-design-lint` — in the phase that proves its replacement
- [ ] **RETIRE-03**: `swaync` is removed the same way, in the same phase as QNOTIF
- [ ] **RETIRE-04**: `swayosd` is removed the same way, including its libinput backend service
- [ ] **RETIRE-05**: `wleave` is removed the same way
- [ ] **RETIRE-06**: `ags` is removed the same way
- [ ] **RETIRE-07**: The `wlogout` and `eww` packages — repo-retired in earlier milestones but **still installed on this host** — are uninstalled
- [ ] **RETIRE-08**: `contract.json` reaches its post-migration size (29 → ~17 entries) with `theme-doctor` and `theme-parity` green and no orphaned entries
- [ ] **RETIRE-09**: The fresh-install container gate (D-34/D-36) passes after every retirement has landed — the milestone's closing proof that a clean clone still reproduces the desktop

### GATE — Quality gates for a redesign-not-port migration

- [x] **GATE-01**: Before each surface is redesigned, its current behaviour is enumerated from the live config and written down as acceptance criteria — while the implementation being replaced still exists to be read
- [x] **GATE-02**: Every phase passes a human render-and-look gate; no phase closes with its replacement judged worse than what it replaced, and no old package is deleted before that judgment
- [x] **GATE-03**: `quickshell-doctor` gains structural checks for each new surface, replacing the mechanical coverage that dies with `waybar-equivalence-check`
- [x] **GATE-04**: A hex-literal lint refuses any QML surface hard-coding a colour, mirroring `motion-lint`'s deny-by-default discipline

### LEDGER — v3.0 debt paydown

- [ ] **LEDGER-01**: The `GradientBorder` and `quickshell-doctor`-dispatch carry-ins are closed as bookkeeping — both are already fixed in code (`PanelDialog.qml:191`, commit `4f48847`; `hl.dsp.global` throughout). **Visual confirmation TAKEN 2026-08-10: the operator confirmed the audio, wifi and bluetooth panels all render the glowing rim.** Remaining work is documentation only — correct PROJECT.md Active, MILESTONES.md "Known gaps at close", WINDOWS #14, and flip the `panels-missing-animated-border` debug session to resolved. Do NOT re-ask for the visual check.
- [ ] **LEDGER-02**: MAINT-02 is settled by **taking the D-29 teardown measurement** that was waived on 2026-07-28, then wrapping Logout or recording why it needs no wrapping
- [ ] **LEDGER-03**: OVER-04's frame-rate term is measured — the floor and target that were recorded UNMEASURED get real numbers
- [ ] **LEDGER-04**: All 6 open debug sessions in `.planning/debug/` reach `resolved` or an explicitly-reasoned deferral
- [ ] **LEDGER-05**: WINDOWS.md's 16 open rows are each closed or re-deferred with a stated reason — no row left silently open
- [ ] **LEDGER-06**: Phase 16's missing `16-VERIFICATION.md` is written, its two malformed `coverage:` blocks corrected, and the incomplete quick task `260728-51j` resolved
- [ ] **LEDGER-07**: `theme-stress-test` reaches a full clean run — the `lib/wallpaper.sh:65` tracked-symlink repoint that dirties the tree on every static switch is fixed
- [ ] **LEDGER-08**: Phase 15's acknowledged gaps are closed — a security review of the panel family, and the verifier re-run over its gap-closure round

## Future Requirements

Deferred beyond v4.0. Tracked, not scoped.

### Launcher

- **Rebuild walker/elephant in QML** — deliberately excluded from v4.0. The launcher works and is the one surface not carrying double maintenance; Phase 7 invested 8 plans in the menu tree as elephant TOML providers. Whether shell consistency justifies rebuilding fuzzy search, app indexing, clipboard and calc is a v5.0+ question.

### Shell

- **Per-screen surface fan-out (QS-03)** — dropped one-way under D-13 on quickshell 0.3.0-2 with no upstream fix found. Irrelevant while the host has one monitor (`DP-1`); revisit only if a second monitor arrives *and* upstream fixes it.

## Out of Scope

| Feature | Reason |
|---------|--------|
| Rebuilding walker/elephant | Decided at v4.0 scoping — the launcher works and carries no double maintenance; deferred to v5.0+ |
| Pixel-for-pixel ports of migrated surfaces | v4.0 redesigns against the reference language. Consequence accepted knowingly: the old-vs-new equivalence-check shape is unavailable, so GATE-02's human render gate carries the load |
| Features invented mid-phase | Small additions are permitted only as named requirements (QBAR-08, QBAR-09, QPOWER-03, QMEDIA-02). Anything else defers to v5.0 |
| Caelestia's shrink-to-a-sliver auto-hide | Leaves static pixels permanently lit — directly against the OLED constraint QBAR-07 exists to serve |
| Four separate bar layouts | QBAR-02's one switchable bar replaces full/athena/floating/vertical. Maintaining four redesigned layouts is four times the work for a distinction one orientation switch already covers |
| AI chat sidebar | Carried from v2.0/v3.0 Out of Scope — the AI dashboard is launchers and a workspace, not built-in assistant UI |
| Full GUI settings app | Carried from v2.0 — the settings menu launches existing tools |
| Per-track dominant-colour re-tinting | Conflicts with the single-palette-source architecture that is this project's core value |
| Decorative mascot GIFs | Shipped by a reference rice; no place in this desktop |
| Retiring anything not named in RETIRE-02..07 | The launcher, hyprlock, the screenshot suite, the utility pickers and the existing QML surfaces all stay |

## Traceability

Which phases cover which requirements. Filled during roadmap creation (2026-08-10).

Phase numbering continues from v3.0's Phase 17 — v4.0 runs Phases 18-22.

| Requirement | Phase | Status |
|-------------|-------|--------|
| QBAR-01 | Phase 18 | Complete |
| QBAR-02 | Phase 18 | Complete |
| QBAR-03 | Phase 18 | Complete |
| QBAR-04 | Phase 18 | Complete |
| QBAR-05 | Phase 18 | Withdrawn — superseded by 18.1 D-15: tray dropped to match Athena (nm-applet/blueman icons duplicated the connections group); connections capsule surfaces the state instead |
| QBAR-06 | Phase 18 | Complete |
| QBAR-07 | Phase 18 | Pending |
| QBAR-08 | Phase 18 | Pending |
| QBAR-09 | Phase 18 | Complete |
| QBAR-10 | Phase 18 | Complete |
| QBAR-11 | Phase 18 | Complete |
| QBAR-12 | Phase 18 | Complete |
| QNOTIF-01 | Phase 19 | Pending |
| QNOTIF-02 | Phase 19 | Pending |
| QNOTIF-03 | Phase 19 | Pending |
| QNOTIF-04 | Phase 19 | Pending |
| QNOTIF-05 | Phase 19 | Pending |
| QNOTIF-06 | Phase 19 | Pending |
| QNOTIF-07 | Phase 19 | Pending |
| QNOTIF-08 | Phase 19 | Pending |
| QNOTIF-09 | Phase 19 | Pending |
| QNOTIF-10 | Phase 19 | Pending |
| QNOTIF-11 | Phase 19 | Pending |
| QOSD-01 | Phase 20 | Pending |
| QOSD-02 | Phase 20 | Pending |
| QOSD-03 | Phase 20 | Pending |
| QOSD-04 | Phase 20 | Pending |
| QPOWER-01 | Phase 20 | Pending |
| QPOWER-02 | Phase 20 | Pending |
| QPOWER-03 | Phase 20 | Pending |
| QPOWER-04 | Phase 20 | Pending |
| QMEDIA-01 | Phase 21 | Pending |
| QMEDIA-02 | Phase 21 | Pending |
| QMEDIA-03 | Phase 21 | Pending |
| RETIRE-01 | Phase 18 | Complete |
| RETIRE-02 | Phase 18 | Pending |
| RETIRE-03 | Phase 19 | Pending |
| RETIRE-04 | Phase 20 | Pending |
| RETIRE-05 | Phase 20 | Pending |
| RETIRE-06 | Phase 21 | Pending |
| RETIRE-07 | Phase 20 | Pending |
| RETIRE-08 | Phase 21 | Pending |
| RETIRE-09 | Phase 22 | Pending |
| GATE-01 | Phase 18 | Complete |
| GATE-02 | Phase 18 | Complete |
| GATE-03 | Phase 18 | Complete |
| GATE-04 | Phase 18 | Complete |
| LEDGER-01 | Phase 18 | Pending |
| LEDGER-02 | Phase 20 | Pending |
| LEDGER-03 | Phase 18 | Pending |
| LEDGER-04 | Phase 19 | Pending |
| LEDGER-05 | Phase 20 | Pending |
| LEDGER-06 | Phase 21 | Pending |
| LEDGER-07 | Phase 19 | Pending |
| LEDGER-08 | Phase 19 | Pending |

**Coverage:**

- v4.0 requirements: 55 total
- Mapped to phases: 55 ✓
- Unmapped: 0
- Duplicates (a requirement in more than one phase): 0

**Per-phase totals:** Phase 18 → 20 · Phase 19 → 15 · Phase 20 → 13 · Phase 21 → 6 · Phase 22 → 1

### Placement notes

Four requirements are cross-cutting. Each is mapped to the phase that *establishes*
it, and recurs as a standing task in later phases:

- **GATE-01** (enumerate current behaviour before redesigning) → Phase 18. Scheduled
  **per-phase, not as an upfront enumeration phase.** Justification: the enumeration
  must be read off the live implementation *while it still exists*, and nothing is
  deleted before its own migration phase — so every surface's old implementation is
  demonstrably still readable at that surface's phase start. An upfront phase would
  write the AGS enumeration four phases before anything consumed it (stale by the
  time it constrains a design) and would deliver no user-observable outcome of its
  own. Per-phase keeps the read adjacent to the redesign it constrains, and feeds
  each phase's own spec/discuss step as UAT acceptance criteria.

- **GATE-02** (human render gate; no phase closes downgraded) → Phase 18. A per-phase
  *closing* gate, not a phase of its own. Recurs unchanged on Phases 19, 20 and 21.
  No old package is deleted before its judgment.

- **GATE-03** (`quickshell-doctor` structural checks per new surface) and **GATE-04**
  (QML hex-literal lint) → Phase 18, because that is the phase where the mechanical
  coverage they replace (`waybar-equivalence-check`, `waybar-design-lint`) is
  deleted. Minting them there means no later surface is ever born outside them.

**Retirement placement.** RETIRE-01 (the checklist script) is in Phase 18 because
RETIRE-02..06 all depend on it. RETIRE-02..06 each sit in the same phase as the
surface they retire — the package dies in the phase that proves its replacement,
which is the point of the milestone. RETIRE-07 (uninstall the still-installed
`wlogout`/`eww` leftovers) is in Phase 20, the phase already running the checklist
twice for two surfaces and the phase where `wlogout`'s lineage finally closes.
RETIRE-08 is in Phase 21, where the fifth and last contract entry is removed.
RETIRE-09 is Phase 22 alone — it cannot run until every deletion has landed, and
running it earlier would only prove the pre-migration state.

**Debt is interleaved, not trailed.** All eight LEDGER requirements sit inside the
four migration phases; Phase 22 carries none, and no phase is pure-debt.

| Debt item | Phase | Why there |
|---|---|---|
| LEDGER-01 | 18 | Near-zero cost, both carry-ins already fixed in code — one look plus doc corrections |
| LEDGER-03 | 18 | The first always-on surface is the right place to finally measure frame rate |
| LEDGER-04 | 19 | 4 of 6 sessions are wifi/bluetooth from Phase 15; the bluetooth prompt's containment was explicitly deferred *to the notification-server replacement* |
| LEDGER-07 | 19 | Lands early enough that Phases 20-22 all run their gates against a clean `theme-stress-test`, and RETIRE-08's contract check has a trustworthy baseline |
| LEDGER-08 | 19 | The panel-family security review belongs in the phase that extends those same components and takes a system-wide D-Bus role |
| LEDGER-02 | 20 | Logout *is* QPOWER-01's fifth action and shares QPOWER-04's graceful-exit mechanism — measuring it elsewhere means setting up the same teardown twice |
| LEDGER-05 | 20 | Triaged and sized at phase start; a mid-milestone phase, not end-of-milestone filler |
| LEDGER-06 | 21 | Phase 16's paperwork concerns a QML surface, and its coverage-block discipline is what this milestone's own UAT depends on |

If the milestone runs long, **cut migration stretch goals first, never the debt** —
research explicitly warns this is where debt-paydown silently dies, and v3.0's own
closeout names it as the open test of v4.0.

## Scoping Decisions

Recorded at milestone start so later phases do not re-litigate them.

| Decision | Chosen | Rationale |
|----------|--------|-----------|
| Migration and debt in one milestone | Combined | User's call — not worth splitting. Research flags the interference risk: if the milestone runs long, cut migration stretch goals first, never the debt |
| Bar layouts | One switchable bar (QBAR-02) | Four redesigned layouts is four times the work; orientation-as-a-property covers the real distinction. Built switchable from day one because retrofitting means a rewrite |
| Vertical edge | Right | Matches Caelestia; pure preference, no technical difference |
| Media visualiser | Rebuilt as a ring around shaped cover art | Deleting the AGS card without it would be a silent downgrade against GATE-02 |
| Bar crash handling | Automatic restart | The bar is the first always-on surface; it shares a process with the notification server, which is worse to lose silently |
| Caps Lock | sysfs LED + watched file, no root service | Volume/brightness were verified already routing through Hyprland binds with `locked=true`, so only Caps Lock needed the daemon. Residual risk: the LED node name across a reboot or keyboard re-enumeration — worth one check |
| swaync handover | Deleted in the same phase, no soak window | User's call against the research recommendation of a disabled-but-installed soak. Consequence: no fast rollback if the QML server misbehaves, and a dropped notification leaves no trace. QNOTIF-05 and QNOTIF-11 carry more weight because of it |
| MAINT-02 Logout | Measured, not assumed | Reverses the 2026-07-28 waiver. The D-29 teardown measurement gets taken |
| Named additions | QBAR-08, QBAR-09, QPOWER-03, QMEDIA-02, QOSD-04 | The full permitted set. QOSD-04 was declined at first pass and added on reconsideration before roadmapping — the cap is that additions are named here, not that they are decided once |
| GATE-01 scheduling | Per-phase task, not an upfront phase | The enumeration must be read while the implementation still exists; nothing is deleted before its own phase, so every surface is readable at its own phase start. See Placement notes |
| Phase count | 5 phases (18-22) under `coarse` granularity | Five surface migrations with a hard-ordered dependency chain plus a mandated separate closing gate. Compressed where possible: OSD and power menu share Phase 20, since QPOWER is independently schedulable and may overlap the OSD |

---
*Requirements defined: 2026-08-10*
*Last updated: 2026-08-10 — roadmap created, all 55 requirements mapped to Phases 18-22*
