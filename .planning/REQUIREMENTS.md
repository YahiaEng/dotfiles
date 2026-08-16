# Requirements: Arch + Hyprland Dotfiles — v4.0 Shell Migration & Debt Paydown

**Defined:** 2026-08-10
**Core Value:** One theme switch — static or dynamic — instantly and consistently re-themes the entire desktop, and the whole setup reproduces from scratch with one script.

**Milestone goal:** Rebuild every remaining pre-Quickshell surface in QML — redesigned toward the end-4/Caelestia reference language rather than straight-ported — retire each old package once its replacement is proven better, and clear the full v3.0 debt ledger, so the milestone ends with one shell and a clean backlog.

**Status markers:** `[ ]` open · `[x]` complete and evidenced · `[~]` partial, with the shipped and unshipped halves named on the row · `[W]` **withdrawn** — deliberately dropped with a written rationale, capability superseded rather than lost · `[A]` **accepted unmeasured** — the operator closed the phase knowing the requirement was never verified. `[A]` is an accepted risk carrying a named decision and date; it is **not** a pass and must never be summarised as one. Any row other than `[x]` states its own evidence gap inline, so no reader has to infer why it is not ticked.

**REQ-ID note:** v4.0 uses new prefixes (`QBAR`, `QNOTIF`, `QOSD`, `QPOWER`, `QMEDIA`, `RETIRE`, `LEDGER`, `GATE`) rather than continuing v2.0's `BAR-*`/`OSD-*`/`WLOG-*` or v3.0's `MEDIA-*`, so a v4.0 requirement can never be confused with the v2.0/v3.0 requirement for the surface it replaces.

## v4.0 Requirements

### QBAR — Status bar (replaces waybar)

- [x] **QBAR-01**: The bar renders as a permanently-mounted surface that reserves its own screen space, in Athena's rounded-capsule visual language
- [x] **QBAR-02**: One bar component switches between a horizontal top strip and a **right-edge** vertical column from config — orientation is a property of a config-driven entry list, not a forked second layout. Replaces all four current waybar layouts.
- [x] **QBAR-03**: User can click a workspace indicator to switch to that workspace (restores the capability dead under waybar 0.15.0's compiled-in dispatch)
- [x] **QBAR-04**: User can scroll on the bar's audio and brightness sections to adjust them
- [W] **QBAR-05**: The system tray shows running tray applications and their menus open on click — **Withdrawn (superseded by 18.1 D-15):** the tray was deliberately dropped in phase 18.1 to match Athena, whose own config records removing it because nm-applet and blueman icons duplicated the connections group; the connections capsule continues to surface that state, so the capability is superseded rather than lost.
- [x] **QBAR-06**: The bar shows clock, battery, network, bluetooth, audio and CPU/RAM/disk readouts
- [x] **QBAR-07**: The bar auto-hides **fully** (never a persistent sliver — OLED constraint) driven by idle, fullscreen, gaming mode and a keybind, with exactly one owner of visibility state
- [x] **QBAR-08**: The hidden bar reveals on pointer hover **and** on holding Super *(named addition)* — **Both halves shipped (2026-08-13).** Hover via `HotZone.qml` → `BarReveal.reportHover()`. Held-Super via a press-edge `hl.dsp.global("quickshell:bar-reveal")` bind in `keybinds.lua`, a `bar-reveal` entry in `shortcuts.json` declaring `"release": false`, and a `GlobalShortcut` in `shell.qml` whose `onPressed`/`onReleased` are the sole writers of `BarReveal.setSuperHeld()`. **The 18-16 blocker was a checker defect, not a real conflict:** `keybind-doctor`'s chord-collision check compared `(modmask, key)` while its own shadow check compared `(modmask, key, keycode, release)` — the two disagreed, and the press bind was read as colliding with the pre-existing Super-tap *release* bind. The collision check now compares the edge as well, so both checks agree these are two distinct claims on one chord. Evidence: `keybind-doctor` 14/14 (was 13/1 with the collision FAIL); `quickshell:bar-reveal` registered in `hyprctl globalshortcuts`; firing it live logs `reveal: shown`; zero binding loops; `colour-lint` 112/0, `quickshell-doctor` and `theme-doctor` both unchanged at their pre-existing failure counts. *Superseded record — the text below is retained because it documents why the revert was correct at the time:* **Partial: hover shipped, held-Super blocked.** `HotZone.qml` + `BarReveal.qml` deliver the hover half live. The held-Super half is built but unreachable: `BarReveal.setSuperHeld()` exists and Hyprland's `GlobalShortcut` type does expose both press and release edges (correcting RESEARCH.md's Open Question 2), but no bind calls it. 18-16 drafted a press-edge `hl.dsp.global("quickshell:bar-reveal")` on `SUPER + SUPER_L` and reverted it before commit: `keybind-doctor`'s shadow check (which distinguishes by release flag) passed, but its quickshell-manifest chord-collision check (which compares `(modmask, key)` *without* the release flag) flagged the chord as claimed by two binds — the existing tap-to-menu release bind and the drafted press bind. Landing it requires either teaching that collision check to distinguish edges, or live-proving Hyprland dispatches both edges independently. Reverted rather than ship a bind that works most of the time. Records: `BarReveal.qml` header, `keybinds.lua` at the would-be bind site, `18-16-SUMMARY.md`.
- [x] **QBAR-09**: Clicking a bar section opens that section's own detail popout, in place of routing everything through the dashboard *(named addition)*
- [x] **QBAR-10**: The bar returns automatically if its process dies — no manual restart
- [A] **QBAR-11**: The bar's memory and process count stay flat across a multi-hour soak — no RSS creep, no accumulated subprocesses, no idle timers doing nothing — **ACCEPTED UNMEASURED by explicit operator decision, 2026-08-13.** The operator was shown that this requirement was never measured on a clean window and chose to close Phase 18 without it: *"I am not waiting for 4 hours. Accept my approval for this phase."* This is an accepted risk, deliberately taken with the evidence in hand — **not** a passing measurement, and it must never be cited as one. What is actually known: no leak is suspected and none was observed; what is missing is four uninterrupted hours of evidence. Two conditions must be met before any future re-run is meaningful — the window needs no hot reloads and no development activity, and the soak's own "exactly one permanent process" premise needs updating for `quickshell-bar-watchdog.service`, which landed after the soak was designed. `WINDOWS.md` rows 68 and 69 stay open to carry it. Original status text follows: **OPEN.** `18-BAR-SOAK.md` states it verbatim: *"Therefore: QBAR-11 stays OPEN. No leak is claimed and no pass is claimed."* Four soak-window anchors were attempted; only one ran the full 4+ hours and it was contaminated by live development (hot reloads, a lost bar surface mid-window). The difficulty is holding four uninterrupted hours, not taking the measurement. **The premise has also moved:** `quickshell-bar-watchdog.service` landed after the soak was designed, so a re-run must first update the soak's own "exactly one permanent process" assumption. `WINDOWS.md` rows 68 and 69 both remain open. No leak is suspected — this is an unmeasured requirement, not a failing one.
- [x] **QBAR-12**: The bar's reserved screen space survives `hyprctl reload` and a QML hot reload without drift or overlap

### QNOTIF — Notifications and centre (replaces swaync)

- [x] **QNOTIF-01**: The shell itself is the system's notification receiver — it owns the `org.freedesktop.Notifications` D-Bus name, and applications' notifications reach it directly
- [x] **QNOTIF-02**: Notifications appear as popups that stack and reflow smoothly as they enter and leave
- [x] **QNOTIF-03**: User can dismiss a popup by swiping it sideways
- [x] **QNOTIF-04**: A notification's own action buttons work, and invoking one reaches the sending application
- [x] **QNOTIF-05**: A progress-style notification (download, volume) updates its existing card in place instead of stacking new ones
- [x] **QNOTIF-06**: User can open a slide-out centre showing notification history, with clear-all
- [x] **QNOTIF-07**: The centre carries the quick-toggle grid, sharing state with the Super-key menu with no drift between them
- [x] **QNOTIF-08**: The centre carries working volume and brightness sliders
- [x] **QNOTIF-09**: Do-not-disturb is a quick toggle and its state persists across a shell restart
- [x] **QNOTIF-10**: Popups are suppressed while the centre is open and while a fullscreen client is focused
- [x] **QNOTIF-11**: A live two-owner check proves no second notification server is registered — `quickshell-doctor`'s existing poisoned-two-owner fixture is pointed at the new owner and run against a real session, not only self-tested

### QOSD — On-screen indicators (replaces SwayOSD)

- [x] **QOSD-01**: Volume and brightness indicators appear on the media keys, including while the lock screen is up
- [x] **QOSD-02**: A Caps Lock indicator appears with **no root service** — read from the keyboard LED's sysfs node via a watched file
- [x] **QOSD-03**: Indicators auto-hide after a delay and stay open while hovered
- [x] **QOSD-04**: Volume, microphone and brightness show as independent sliders in one column when more than one has changed — each individually adjustable, each appearing only if that control actually moved *(named addition)*

### QPOWER — Power menu (replaces wleave)

- [x] **QPOWER-01**: Six actions available — Shutdown, Reboot, Suspend, Hibernate, Logout, Lock
- [x] **QPOWER-02**: Fully keyboard-navigable with visible focus; Enter activates, Escape closes, first action auto-focused on open
- [x] **QPOWER-03**: The menu warns before a destructive action when a package manager or download is still running *(named addition)*
- [x] **QPOWER-04**: Shutdown and Reboot keep the graceful compositor exit that closed the FIX-01 hang class

### QMEDIA — Media fold-in (replaces the AGS card)

- [ ] **QMEDIA-01**: The dashboard's Media tab carries transport, seek, cover art, per-player volume and player switching — everything the standalone card did
- [x] **QMEDIA-02**: An audio-reactive visualiser renders as a ring around shaped cover art, restoring the cava element the Media tab cut in Phase 14
- [ ] **QMEDIA-03**: Exactly one MPRIS reader remains in the whole desktop — the three-consumer duplication v3.0 priced in is ended

### RETIRE — Retirement mechanics

- [x] **RETIRE-01**: A retirement checklist **script** exists covering every reference class (window/layer rules, autostart, keybinds, `contract.json`, matugen templates, doctor registries and fixtures, systemd `--user` units, D-Bus activation files, XDG autostart, `install.sh`/`stow.sh` lists) and is run before *and* after each deletion
- [x] **RETIRE-02**: `waybar` is removed — package, config, contract entries, matugen template, `waybar-equivalence-check` and `waybar-design-lint` — in the phase that proves its replacement
- [x] **RETIRE-03**: `swaync` is removed the same way, in the same phase as QNOTIF
- [x] **RETIRE-04**: `swayosd` is removed the same way, including its libinput backend service
- [x] **RETIRE-05**: `wleave` is removed the same way
- [ ] **RETIRE-06**: `ags` is removed the same way
- [x] **RETIRE-07**: The `wlogout` and `eww` packages — repo-retired in earlier milestones but **still installed on this host** — are uninstalled
- [ ] **RETIRE-08**: `contract.json` reaches its post-migration size (29 → ~17 entries) with `theme-doctor` and `theme-parity` green and no orphaned entries
- [ ] **RETIRE-09**: The fresh-install container gate (D-34/D-36) passes after every retirement has landed — the milestone's closing proof that a clean clone still reproduces the desktop

### GATE — Quality gates for a redesign-not-port migration

- [x] **GATE-01**: Before each surface is redesigned, its current behaviour is enumerated from the live config and written down as acceptance criteria — while the implementation being replaced still exists to be read
- [x] **GATE-02**: Every phase passes a human render-and-look gate; no phase closes with its replacement judged worse than what it replaced, and no old package is deleted before that judgment — **PASSED at 18-19 Iteration 3 (sha `2644ae0`, 2026-08-12).** The operator performed all fifteen gestures live on the shipped bar: **14 PASS, 1 NOT-DEMONSTRABLE** (B.3's brightness half — no backlight device on this host; D-18-39 authorises that token on this row alone), **0 FAIL, 0 OVERRIDDEN**. Three iterations were needed. Iteration 1 (sha `8c5d280`) was suspended on four operator-reported defects: clock pill riding high, tooltips landing on top of the glyph they explain, idle-bulb click giving no feedback, media transport row not centred. Iteration 2 (sha `13de40f`) was suspended on a fifth — popout cards sitting 52px low from a double-counted bar extent, the same root cause as the tooltip fix in a file that never got the correction. All five were fixed before Iteration 3. The record's `## Deletion Authorisation` then authorised RETIRE-02, and its interlock (`git diff --quiet 2644ae0 -- quickshell/.config/quickshell/`) still held when the deletion ran. Evidence: `18-GATE-02-RECORD.md`, `18-19-SUMMARY.md`. **Phase 18.1's earlier informal approval (2026-08-12) unblocked 18-19 but was not the blocking pass, and is superseded by this record** — an earlier revision of this row cited it, which would have pointed a reader at the wrong evidence.
- [x] **GATE-03**: `quickshell-doctor` gains structural checks for each new surface, replacing the mechanical coverage that dies with `waybar-equivalence-check`
- [x] **GATE-04**: A hex-literal lint refuses any QML surface hard-coding a colour, mirroring `motion-lint`'s deny-by-default discipline

### LEDGER — v3.0 debt paydown

- [x] **LEDGER-01**: The `GradientBorder` and `quickshell-doctor`-dispatch carry-ins are closed as bookkeeping — both are already fixed in code (`PanelDialog.qml:191`, commit `4f48847`; `hl.dsp.global` throughout). **Visual confirmation TAKEN 2026-08-10: the operator confirmed the audio, wifi and bluetooth panels all render the glowing rim.** Remaining work is documentation only — correct PROJECT.md Active, MILESTONES.md "Known gaps at close", WINDOWS #14, and flip the `panels-missing-animated-border` debug session to resolved. Do NOT re-ask for the visual check.
- [x] **LEDGER-02**: MAINT-02 is settled by **taking the D-29 teardown measurement** that was waived on 2026-07-28, then wrapping Logout or recording why it needs no wrapping
- [x] **LEDGER-03**: OVER-04's frame-rate term is measured — the floor and target that were recorded UNMEASURED get real numbers. **MEASURED 2026-08-11 in Phase 18 (`18-FRAME-RATE.md`, commit `eae9001`)** with Qt's `QSG_RENDER_TIMING=1`; the compositor overlay that froze the host in Phase 16 was never retried. **60 fps floor PASSES** — 0 of 81,261 render-loop iterations exceeded 16.67 ms during a human-driven overview drag at OVER-04's own load floor, worst case 12 ms (83.3 fps); the only sub-60 fps events across ~89,000 measured frames were 11 single-frame bar-transition hitches (38–62 ms) and 2 overview surface-creation frames (90/93 ms). **165 fps target recorded NOT RESOLVABLE** with the sanctioned instrument (integer-ms bucketing swallows the 156.75 fps threshold; iteration counts are an upper bound on presentation) and deliberately not claimed as a pass. Ledger corrections carried into `16-OVER04-MEASUREMENT.md`, `PROJECT.md` and `MILESTONES.md`.
- [x] **LEDGER-04**: All 6 open debug sessions in `.planning/debug/` reach `resolved` or an explicitly-reasoned deferral
- [x] **LEDGER-05**: WINDOWS.md's 16 open rows are each closed or re-deferred with a stated reason — no row left silently open
- [x] **LEDGER-06**: Phase 16's missing `16-VERIFICATION.md` is written, its two malformed `coverage:` blocks corrected, and the incomplete quick task `260728-51j` resolved
- [x] **LEDGER-07**: `theme-stress-test` reaches a full clean run — the `lib/wallpaper.sh:65` tracked-symlink repoint that dirties the tree on every static switch is fixed
- [x] **LEDGER-08**: Phase 15's acknowledged gaps are closed — a security review of the panel family, and the verifier re-run over its gap-closure round

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
| QBAR-07 | Phase 18 | Complete |
| QBAR-08 | Phase 18 | Complete — both halves shipped 2026-08-13. Held-Super unblocked by fixing `keybind-doctor`'s chord-collision check to compare the release edge, matching its own shadow check; the 18-16 blocker was the two checks disagreeing, not a real bind conflict. `keybind-doctor` 14/14, shortcut registered, reveal fires live |
| QBAR-09 | Phase 18 | Complete |
| QBAR-10 | Phase 18 | Complete |
| QBAR-11 | Phase 18 | Accepted unmeasured — explicit operator decision 2026-08-13 to close Phase 18 without the soak. Accepted risk, NOT a passing measurement; never cite as one. Never measured on a clean window. Four soak anchors attempted; the only full 4h+ window was contaminated by live development. `quickshell-bar-watchdog.service` landing afterward invalidates the soak's "exactly one permanent process" premise, so a re-run needs that assumption updated first. No leak suspected; unmeasured, not failing. See `18-BAR-SOAK.md`, `WINDOWS.md` rows 68-69 |
| QBAR-12 | Phase 18 | Complete |
| QNOTIF-01 | Phase 19 | Complete |
| QNOTIF-02 | Phase 19 | Complete |
| QNOTIF-03 | Phase 19 | Complete |
| QNOTIF-04 | Phase 19 | Complete |
| QNOTIF-05 | Phase 19 | Complete |
| QNOTIF-06 | Phase 19 | Complete |
| QNOTIF-07 | Phase 19 | Complete |
| QNOTIF-08 | Phase 19 | Complete |
| QNOTIF-09 | Phase 19 | Complete |
| QNOTIF-10 | Phase 19 | Complete |
| QNOTIF-11 | Phase 19 | Complete |
| QOSD-01 | Phase 20 | Complete |
| QOSD-02 | Phase 20 | Complete |
| QOSD-03 | Phase 20 | Complete |
| QOSD-04 | Phase 20 | Complete |
| QPOWER-01 | Phase 20 | Complete |
| QPOWER-02 | Phase 20 | Complete |
| QPOWER-03 | Phase 20 | Complete |
| QPOWER-04 | Phase 20 | Complete |
| QMEDIA-01 | Phase 21 | Pending |
| QMEDIA-02 | Phase 21 | Complete |
| QMEDIA-03 | Phase 21 | Pending |
| RETIRE-01 | Phase 18 | Complete |
| RETIRE-02 | Phase 18 | Complete |
| RETIRE-03 | Phase 19 | Complete |
| RETIRE-04 | Phase 20 | Complete |
| RETIRE-05 | Phase 20 | Complete |
| RETIRE-06 | Phase 21 | Pending |
| RETIRE-07 | Phase 20 | Complete |
| RETIRE-08 | Phase 21 | Pending |
| RETIRE-09 | Phase 22 | Pending |
| GATE-01 | Phase 18 | Complete |
| GATE-02 | Phase 18 | Complete — PASSED at 18-19 Iteration 3, sha `2644ae0`, 2026-08-12. Operator performed all fifteen gestures live: 14 PASS, 1 NOT-DEMONSTRABLE (B.3 brightness half, authorised by D-18-39), 0 FAIL, 0 OVERRIDDEN. Iterations 1 and 2 were suspended on five operator-reported defects (F1-F5), all fixed before Iteration 3. Authorised RETIRE-02, which then executed. Evidence: `18-GATE-02-RECORD.md` § Deletion Authorisation. Phase 18.1's earlier informal approval (2026-08-12) is superseded — it unblocked 18-19 but was not the blocking pass. |
| GATE-03 | Phase 18 | Complete |
| GATE-04 | Phase 18 | Complete |
| LEDGER-01 | Phase 18 | Complete — all four bookkeeping targets corrected: `PROJECT.md`, `MILESTONES.md` (both gaps gained dated SUPERSEDED clauses), WINDOWS #14 marked fixed, and the `panels-missing-animated-border` debug session moved to `.planning/debug/resolved/` with `status: resolved` |
| LEDGER-02 | Phase 20 | Complete |
| LEDGER-03 | Phase 18 | Complete — measured 2026-08-11, `18-FRAME-RATE.md`; 60 fps floor passes, 165 fps target recorded not-resolvable with the sanctioned instrument |
| LEDGER-04 | Phase 19 | Complete |
| LEDGER-05 | Phase 20 | Complete |
| LEDGER-06 | Phase 21 | Complete |
| LEDGER-07 | Phase 19 | Complete — closed 2026-08-14, one day after Phase 19's own close, on a real full run: `theme-stress-test` 142 passed / 0 failed across all ten switches with `git status --porcelain` empty afterwards, `theme-doctor` exit 0, `hypr-equivalence-check` PASS 3 / FAIL 0. The blocker was never the wallpaper pointer (D-19-45 landed in 19-03) but `hypr-equivalence-check` itself: 3 of its 46 tracked options carry theme-rendered colours, so comparing them by value asserted "the desktop is on the same theme as the capture day" — unsatisfiable for a harness that switches themes ten times by design, which is why this sat UNREACHABLE rather than merely stale. Fixed by comparing theme-driven options for presence rather than value, forgiving the hyprpm plugin curve, and giving bind identity the `release` field plus an enumerated accepted-additions table. The pre-migration baseline was deliberately NOT regenerated — under Lua every bind reports dispatcher `__lua`, so re-snapshotting would have made the gate compare Lua against Lua and assert nothing. |
| LEDGER-08 | Phase 19 | Complete |

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
