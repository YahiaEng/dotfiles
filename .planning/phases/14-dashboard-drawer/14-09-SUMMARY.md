---
phase: 14-dashboard-drawer
plan: 09
subsystem: ui
tags: [quickshell, qml, motion-cascade, design-tokens, gate-sweep, phase-close]

# Dependency graph
requires:
  - phase: 14-08
    provides: "All four tabs composed and their own render gates closed (Dashboard/Media/Performance/Weather)"
  - phase: 14-04
    provides: "QuickToggles.qml's three swaync-mirrored chips and motion-scale row — the DASH-07 mirror this plan re-proves"
  - phase: 13-07
    provides: "The closing-sweep baseline (theme-doctor 206/0, theme-parity 2697/0, motion-lint 53/0, quickshell-doctor 13/0, keybind-doctor 13/0, theme-stress-test 162/0) this plan measures against"
provides:
  - "Cascade.qml — the summon-only staggered entrance cascade on D-21's stagger token, both fences proven live"
  - "Design.qml — the shared drawer design-constants singleton, consolidating 15 constants / 66 call sites across 6 files"
  - "Ten repo-wide prohibition invariants, each proven able to fail (poisoned run) before being trusted to pass (clean run)"
  - "The phase-close evidence record: gate sweep, three-reader delta proof, DASH-07 mirror, layer/fullscreen re-observations, D-05 slack table"
affects: [phase-15, phase-16, phase-17]

tech-stack:
  added: []
  patterns:
    - "Non-visual QtObject cascade runner reading only two motion-token pairs plus the motion-enabled flag, arming-flag-consumed-once-per-surface-lifetime as the sole re-entrancy guard"
    - "Singleton design-constants file (pragma Singleton + qmldir singleton keyword, both required per the 12-06 finding) as the cross-file constant-sharing mechanism for a Quickshell submodule"
    - "Poisoned-scratch-copy-then-clean-tree proof discipline applied to a full battery of ten repo-wide negative-grep invariants in one task"

key-files:
  created:
    - quickshell/.config/quickshell/modules/dashboard/Cascade.qml
    - quickshell/.config/quickshell/modules/dashboard/Design.qml
  modified:
    - quickshell/.config/quickshell/modules/dashboard/qmldir
    - quickshell/.config/quickshell/modules/Dashboard.qml
    - quickshell/.config/quickshell/modules/Motion.qml
    - quickshell/.config/quickshell/modules/dashboard/DashboardTab.qml
    - quickshell/.config/quickshell/modules/dashboard/MediaTab.qml
    - quickshell/.config/quickshell/modules/dashboard/PerformanceTab.qml
    - quickshell/.config/quickshell/modules/dashboard/WeatherTab.qml
    - quickshell/.config/quickshell/modules/dashboard/QuickToggles.qml
    - quickshell/.config/quickshell/modules/dashboard/Dial.qml
    - .planning/phases/14-dashboard-drawer/14-09-SUMMARY.md

key-decisions:
  - "Task 2's consolidation disposition: CONSOLIDATED-HERE, not accepted-debt. 14-08's deferral rationale ('no shared mechanism exists — an id is lexically scoped') did not survive inspection: Colours/Motion already cross exactly that boundary from modules/qmldir, so the same mechanism applies one directory down. Design.qml now holds 15 constants (spacing/icon/typography/symbol-family), all pure value-for-value substitutions sourced from 14-UI-SPEC.md and 14-02's recorded family string."
  - "The D-21 cascade's motion-enabled/motion-scale plumbing was broken repo-wide until this plan's prerequisite fix (7850b7f): Motion.qml's JsonAdapter declared camelCase motionEnabled/motionScale, but lib/motion.sh emits snake_case motion_enabled/motion_scale — JsonAdapter binds top-level JSON keys by exact name, so neither key ever bound and 'off' was silently inert across the ENTIRE shell (~40 gate sites), not only the new cascade. Fixed by renaming the two internal binding names only; the public Motion.motionEnabled/motionScale aliases are byte-identical, so no consumer or motion-lint CHECK A name changed."
  - "quickshell-doctor's launcher-log-freshness check FAILed at the start of this task's sweep because the running quickshell process (uptime ~11h) had no 'starting' line left in its own truncated log — not a functional break (the dashboard shortcut was live and working throughout). Resolved operationally by a detached relaunch (setsid uwsm app -- quickshell-launch.sh, the standing 14-06 executor rule), which produced a fresh log and cleared the check with no source file touched."
  - "The three-reader media proof and the D-05 slack table both had to be reconstructed live in this task rather than literally 'collated' from four prior SUMMARYs, because 14-06/14-07/14-08's own SUMMARY.md files never recorded the numeric slack arithmetic their plans required — a documented historical gap, closed here with live measurement rather than left unfilled."
  - "The backward-navigation pager-width bug 14-06 deferred to 14-08/14-09 (Left arrow from a wider to a narrower tab leaving the frame width stuck) is now structurally moot: since 14-04/14-08's consolidation onto drawerMinWidth=760 as a shared floor, every tab renders at the SAME width (760px) and only height varies per tab — there is no width to get stuck at. Confirmed live across a full four-tab Right-then-Left round trip. Not re-opened as a fix; recorded as an incidental resolution."
  - "D-04's literal 'identical frame height on all four tabs' truth is stale text this plan does not re-litigate: 14-03's own render gate (round 2, human-approved) superseded it with per-tab dynamic proportions, ratified again through 14-04/14-06/14-08. This plan's Task 3 re-observation records the CURRENT per-tab heights (826/424/778/497) as the correct, already-ratified behavior, not as a defect against the original text."

patterns-established:
  - "Singleton-based cross-submodule design-token sharing (Design.qml) — the mechanism Phase 15's panels should reach for instead of re-declaring local spacing/type constants per file."

requirements-completed: []

coverage:
  - id: D1
    description: "D-21 summon-only entrance cascade: one non-visual Cascade.qml runner, one cascadeBands ordered list per tab, both fences (fires exactly once per surface lifetime; collapses at off, tightens at reduced) proven by counted run markers"
    requirement: "DASH-01..08 (phase-close verification, no single DASH-id)"
    verification:
      - kind: other
        ref: "Live run-marker counts recorded in commit 3a05c97: summon +1, six tab switches +0, dismiss+resummon +1; off scale 0 markers, reduced scale 1 marker at the 14-02-recorded 40ms floor. motion-lint 77/77 exit 0."
        status: pass
    human_judgment: false
  - id: D2
    description: "Design-constants consolidation disposition: CONSOLIDATED-HERE with a before/after value table (zero mismatches), and ten repo-wide prohibition invariants each proven able to fail (poisoned) before being trusted to pass (clean)"
    requirement: "DASH-01..08 (phase-close verification)"
    verification:
      - kind: other
        ref: "Commits 1388516/87bba52: geometry byte-identical on all four tabs before/after (760x826/760x424/760x778/760x497); motion-lint 77/77 exit 0; ten invariants each poisoned-then-clean per the commit record"
        status: pass
    human_judgment: false
  - id: D3
    description: "The committed gate sweep, the three-reader delta proof, the DASH-07 mirror, and the layer/fullscreen/theme-crossfade re-observations against real four-tab content"
    requirement: "DASH-01..08 (phase-close verification)"
    verification:
      - kind: other
        ref: "This SUMMARY's Task 3 section — live command output for every check, described in full below"
        status: pass
    human_judgment: false
  - id: D4
    description: "Phase-close blocking human render gate across all four populated tabs, including the three explicitly-deferred open judgments (cascade feel, D-05 slack + drawer width at 2560px, drag threshold)"
    requirement: "DASH-01..08 (phase-close verification)"
    verification: []
    human_judgment: true
    rationale: "Visual/feel judgment across the whole phase per ROADMAP standing constraint 1 — NOT YET RUN. This session stops at Task 4's blocking checkpoint per the sequential-executor continuation contract; a human must answer it before the phase can close."

# Metrics
duration: multi-session (Tasks 1-2 in a prior interrupted session; Task 3 + this SUMMARY in this continuation session; Task 4 not yet run)
completed: 2026-07-30
status: blocked
---

# Phase 14 Plan 09: Cascade, Consolidation, Gate Sweep & Phase-Close Evidence Summary

**D-21's summon-only entrance cascade shipped and both its fences proven live; the four-plan-deferred design-constants consolidation landed on a shared `Design` singleton; ten repo-wide prohibition invariants each proven able to fail before being trusted to pass; and the full phase-close gate sweep, three-reader delta proof, DASH-07 mirror and layer/fullscreen re-observations run against all four populated tabs — with Task 4's blocking human render gate still pending a fresh session's answer.**

## Performance

- **Duration:** Multi-session. Tasks 1-2 (cascade + consolidation) were executed and committed in a prior session that was interrupted before writing this SUMMARY. Task 3 (gate sweep + evidence) and this SUMMARY were completed in this continuation session, 2026-07-30.
- **Tasks:** 4 declared (Task 1 auto, Task 2 auto, Task 3 auto, Task 4 checkpoint:human-verify, gate="blocking"). Tasks 1-3 complete; **Task 4 has NOT been run** — this session stops at its blocking checkpoint per the executor's continuation contract and returns structured checkpoint state to the orchestrator.
- **Files modified:** 10 QML files (2 created, 8 modified) across Tasks 1-2; zero source files touched by Task 3 (verification-only).

## Accomplishments

- **Task 1 (prior session):** Built `Cascade.qml`, a non-visual `QtObject` runner reading only the stagger and emphasized-in `Motion` token pairs plus the motion-enabled flag, wired one `cascadeBands` ordered list per tab, and proved both of D-21's fences live with counted run markers. Found and fixed a repo-wide prerequisite bug along the way: `Motion.qml`'s JsonAdapter was silently failing to bind `motionEnabled`/`motionScale` from `motion.json`'s snake_case keys, making the `off` motion scale inert everywhere in the shell (~40 sites), not just the new cascade.
- **Task 2 (prior session):** Read all four sibling consolidation notes, found 14-08's deferral rationale did not survive inspection, and consolidated 15 design constants onto a new `Design` singleton (66 pure value-for-value substitutions, zero mismatches, geometry byte-identical before/after). Then ran all ten repo-wide prohibition invariants, each first proven able to fail against a poisoned scratch copy, then proven to pass against the real tree — catching and fixing one broken invariant (a comment-stripper that ate `http://` and let a poisoned GeoIP-host string slip through) and naming three timer intervals that were escaping `motion-lint`'s CHECK B blind spot.
- **Task 3 (this session):** Ran the full eight-script committed gate sweep against Phase 13's recorded baseline; proved the three-reader media-backend claim as a process-count delta (baseline 1, open baseline+1, closed back to baseline, unchanged across five cycles); proved the DASH-07 toggle mirror's source identity and D-26's flip direction against the real config string in a scratch home; re-observed the layer posture, fullscreen refusal and a live theme switch against all four now-populated tabs; and reconstructed the D-05 vertical-slack arithmetic that three of the four content plans' own SUMMARYs never recorded.

## Task Commits

1. **Task 1: D-21 summon-only entrance cascade** — `7850b7f` (fix: prerequisite Motion.qml snake_case binding fix) + `3a05c97` (feat: the cascade itself, both fences proven)
2. **Task 2: Consolidation disposition + ten prohibition invariants** — `1388516` (refactor: Design.qml consolidation) + `87bba52` (fix: three named timer intervals, CHECK B blind-spot record)
3. **Task 3: Gate sweep + phase-close evidence** — no source commit (verification-only); this SUMMARY is Task 3's recorded deliverable, committed alongside this plan's docs commit.

**Plan metadata:** this SUMMARY.md, committed as `docs(14-09): record Task 3 gate sweep and phase-close evidence (Task 4 pending)`.

_Note on continuity:_ Tasks 1-2 were executed and committed by a session that ended before writing a SUMMARY. This document reconstructs their record from their commit messages (which carry the full recorded measurements verbatim — see "Task 1 — as recorded" and "Task 2 — as recorded" below) and from `git show`/`git diff` on the four commits, per this session's continuation instructions. Task 1/2 evidence below is **attributed to the prior session**, not freshly observed by this one.

## Files Created/Modified

- `quickshell/.config/quickshell/modules/dashboard/Cascade.qml` — new: the cascade runner (`bands`/`armed`/`riseDistance`/`runCount`, `run()`/`reset()`)
- `quickshell/.config/quickshell/modules/dashboard/Design.qml` — new: the shared design-constants singleton (15 constants)
- `quickshell/.config/quickshell/modules/dashboard/qmldir` — registers both new types in the commits that create them
- `quickshell/.config/quickshell/modules/Dashboard.qml` — `cascadeArmed`, one `Cascade` instance, dispatch off the active pane's loaded signal; consumes `Design.*` in place of local constants
- `quickshell/.config/quickshell/modules/Motion.qml` — the prerequisite snake_case JsonAdapter binding-name fix
- `quickshell/.config/quickshell/modules/dashboard/{DashboardTab,MediaTab,PerformanceTab,WeatherTab}.qml` — each gained one `cascadeBands` ordered list property; each also had its local spacing/typography constants replaced with `Design.*` reads
- `quickshell/.config/quickshell/modules/dashboard/QuickToggles.qml`, `Dial.qml` — local constants replaced with `Design.*` reads; three anonymous timer `interval:` values named
- `.planning/phases/14-dashboard-drawer/14-09-SUMMARY.md` — this file

## Decisions Made

See `key-decisions` in frontmatter for the full list. In prose, the two load-bearing ones:

- **Consolidation: CONSOLIDATED-HERE.** 14-08 deferred consolidation on the stated grounds that no shared mechanism could exist between separately-registered tab components. That reasoning treated `Design` as if it needed to be a lexically-scoped `id`, but `Colours`/`Motion` already prove a `qmldir`-registered singleton crosses that exact boundary — the mechanism existed one directory down the whole time. Values are sourced from `14-UI-SPEC.md` and `14-02`'s recorded font-family string, not copied from whichever sibling file was read first; the one unavoidable exception (`iconSizeMd: 24`, no UI-SPEC row) is called out by name in `Design.qml`'s own header rather than silently presented as contract-sourced.
- **The Motion.qml binding-name fix is a Rule-1 auto-fix, not a Rule-4 architectural change**, despite touching ~40 call sites indirectly: the public `Motion.motionEnabled`/`Motion.motionScale` API surface is byte-identical before and after — only the two *internal* JsonAdapter property names changed, from a value that could never bind (`motionEnabled`/`motionScale`, camelCase, mismatched against the emitter's snake_case) to one that does. No consumer file changed, and `motion-lint` CHECK A's admitted name set is unaffected.

## Task 1 — as recorded (prior session, `3a05c97` / `7850b7f`)

**D-21's cascade.** One reusable runner (`Cascade.qml`, `QtObject` root — never contributes geometry to D-04's fixed frame) plus one `cascadeBands` ordered list per tab. No tab file carries its own animation code; no timing number appears anywhere in the path except `riseDistance` (16px, the drawer's own spacing-scale medium step, explicitly named as geometry not motion).

`run()` clears `armed` before touching a single band — that single consumption, on a flag re-created true every summon because the drawer is destroyed on dismiss (D-14), is the whole of fence 1. No second guard keyed on tab index or elapsed time exists.

The rise is a translate created per band and assigned as that band's transform list (primary mechanism; bands already carrying a transform are skipped and recorded, not clobbered — none were, this build).

**Fence 1 (countable, verified live):**

| Action | Run-marker delta |
|---|---|
| Summon | +1 |
| 6 tab switches (3 Left, 3 Right, all 4 tabs traversed) | +0 |
| Dismiss + resummon | +1 |

Tab movement was independently confirmed real (not merely "no crash"): three `Left` presses followed by a resummon logged `tab=0 bands=5`, proving the keys actually landed and moved the pager.

**Fence 2 (needed the Motion.qml prerequisite fix in the same commit sequence):**

| Motion scale | Run markers | Notes |
|---|---|---|
| normal | 1 | stagger 50ms, emphasized-in 300ms |
| reduced | 1 | stagger clamped to 14-02's recorded 40ms floor, emphasized-in halved to 150ms — in-band |
| off | 0 | every band at final state immediately |

**Settle arithmetic at normal**, against D-21's <700ms budget (no delay-index clamp needed on any tab):

| Tab | Bands | Formula | Total |
|---|---|---|---|
| Dashboard | 5 | 4×50 + 300 | 500ms |
| Weather | 3 | 2×50 + 300 | 400ms |
| Media | 2 | 1×50 + 300 | 350ms |
| Performance | 2 | 1×50 + 300 | 350ms |

**The prerequisite bug (`7850b7f`), found by Fence 2's own acceptance criterion:** `Motion.qml`'s JsonAdapter declared `motionEnabled`/`motionScale` in camelCase; `lib/motion.sh` emits `motion_enabled`/`motion_scale`. JsonAdapter binds top-level JSON keys by exact name only — no case conversion — so neither key ever bound, both sat at their compiled defaults (`true`/`"normal"`) forever, and the `off` motion scale was silently inert across the **entire shell** (Dial, Probe, Dashboard, QuickToggles, all four tabs — ~40 gate sites), not only this plan's new cascade. The `semantic` key masked the fault for two phases because its declared name already matched its JSON key exactly, so durations/easings kept resolving and the singleton looked healthy. Fixed by renaming only the two internal binding property names; the public `Motion.motionEnabled`/`Motion.motionScale` aliases stayed byte-identical, so zero consumers and zero motion-lint CHECK A names changed.

`motion-lint` 77/77, `--self-test` 10/10, `--no-pending` 1/1, all exit 0 (as recorded in the commit).

## Task 2 — as recorded (prior session, `1388516` / `87bba52`)

**Half one — consolidation, CONSOLIDATED-HERE.** New singleton `Design` at `modules/dashboard/Design.qml`, carrying both `pragma Singleton` and the `singleton` keyword on its `qmldir` line (the 12-06 finding: omitting the keyword yields a type that reads `undefined` forever with no load error).

15 constants, 66 pure value-for-value substitutions across 6 files:

```
spacingXs 4  spacingSm 8  spacingMd 16  spacingLg 24  spacingXl 32
panelPadding 24  iconSizeMd 24
fontDisplay 32  fontHeading 20  fontBody 16  fontLabel 12
weightDisplay Font.Medium  weightEmphasis Font.DemiBold
weightBody Font.Normal     symbolFontFamily "Material Symbols Rounded"
```

Values sourced from `14-UI-SPEC.md`'s Spacing Scale and Typography tables and `14-02`'s recorded font-family string — not copied from whichever sibling was read first. **Zero value mismatches** between before/after columns. One provenance exception recorded rather than hidden: `iconSizeMd`'s `24` rests on unanimous six-sibling agreement plus MD3's standard 24dp, since `14-UI-SPEC.md` declares no icon-size row.

Left local, deliberately, as divergences rather than normalized: `fillAxisAvailable` (name+value agree but it's a per-file font-build capability flag, not a design token); `hasPlayer`, `hourColumns`, `playing`, `widgetState` (names collide across files but values diverge — derived per-file state, not constants).

Resolution proven live, not by reading source: drawer frame geometry byte-identical before/after on all four tabs (760x826 / 760x424 / 760x778 / 760x497) — impossible if any of these had resolved to `undefined`. `motion-lint` 77/77 exit 0 with `Design.qml` scanned and passing both checks.

**Half two — the ten prohibition invariants, each poisoned-then-clean.**

| # | Invariant | Poisoned run | Clean run |
|---|---|---|---|
| 1 | Zero MPRIS-service imports under Quickshell | FAIL (as required) | PASS |
| 2 | Zero hex colour literals | FAIL | PASS |
| 3 | Zero raw duration/bezier literals (CHECK-B shape) | FAIL | PASS |
| 4 | The CHECK-B blind spot (camelCase duration props / timer intervals), enumerated by hand | n/a — hand enumeration, not a grep | 67 sites enumerated; see below |
| 5 | Zero `Motion.motionScale` (dangling-alias) references | FAIL | PASS |
| 6 | Zero scrolling/flicking view types in the four tabs | FAIL | PASS |
| 7 | Zero rejected-pager (PathView-class) references | FAIL | PASS |
| 8 | Zero raw transport command names (only the sanctioned mutator script) | FAIL | PASS |
| 9 | Zero rejected GeoIP-host references | FAIL (after the fix below) | PASS |
| 10 | Reload fan-out untouched (byte-identical, no commit this phase touches it) | FAIL (poisoned copy) | PASS |

**One invariant found broken by its own poisoned run, and fixed:** invariant 9's comment-stripper (`sed 's|//.*||'`) ate the `//` inside the injected `"http://ip-api.com/json"` literal before the grep ever ran, so the poisoned copy passed — a broken assertion silently worth nothing. Corrected to `sed 's|\([^:]\)//.*|\1|'` (strip `//` only when not preceded by `:`); re-poisoned and confirmed to fail as required.

**Invariant 4, the class no committed gate can see, in full:** 67 camel-cased duration-shaped properties and timer intervals were enumerated by hand across the drawer host and the dashboard submodule. All 26 `duration:` sites resolve to `Motion.*` aliases. Three did **not** resolve to a name and were fixed (pure extraction, no value changed):

| File | Was | Now |
|---|---|---|
| `QuickToggles.qml` | `interval: 4000` | `dndSubscribeGraceMs` |
| `QuickToggles.qml` | `interval: 2000` | `dndPollIntervalMs` |
| `SystemResources.qml` | `interval: 400` | `primeSampleWindow` |

**Standing warning, carried forward exactly as Task 2 recorded it:** `motion-lint`'s CHECK B is anchored on a lowercase `duration:` followed by digits; every camel-cased duration-shaped property and every `interval:` structurally escapes it. **A green `motion-lint` is NOT evidence of token discipline for this class anywhere in this phase.** This hand enumeration is the only evidence that exists for it, and a regression in this class after this phase closes will not be caught by any committed gate. This warning is not a formality — carry it into any future phase or audit that touches these files.

`motion-lint` 77/77 exit 0 after every edit.

## Task 3 — this session, live evidence

### Precondition check

Confirmed **met**, not merely assumed: `quickshell:dashboard` was live in `hyprctl globalshortcuts` before any check began (`quickshell:dashboard -> `), and the drawer visibly opened/closed on dispatch. Mid-sweep, `quickshell-doctor`'s launcher-log-freshness check FAILed because the running process (uptime ~11h, PID 1129866) had no `starting` line left in its own log (the launcher script truncates the log at >1MiB at the *start* of a run, and something upstream of this session had already pushed the log past that point without a corresponding restart). This is not a functional break — the shortcut worked throughout — but per the standing 14-06 executor rule ("quickshell verification restarts MUST relaunch detached"), the shell was restarted via `setsid uwsm app -- ~/.config/hypr/scripts/quickshell-launch.sh` (new PID 2090081), producing a fresh `starting` line and re-registering the GlobalShortcut. Confirmed live afterward: shortcut still resolves, drawer still opens/closes correctly, tab memory intact. **This restart is the reason the precondition — and this whole task's subsequent restart-agnostic checks — are recorded against PID 2090081, not 1129866.**

### A. The committed gate sweep, against Phase 13's recorded baseline (`13-07-SUMMARY.md`)

| Script | Phase 13 baseline | This run | Verdict |
|---|---|---|---|
| `theme-doctor` | 206 passed / 0 failed | 229 passed / 1 failed | See note below — same failure class, not the Phase-13-recorded one, but self-explained and expected |
| `theme-parity` | 2697 passed / 0 failed | 2608 passed / 0 failed | PASS — count differs due to normal build-state variance (active theme, no regression; 0 failed both times) |
| `waybar-design-lint` | 32 passed / 0 failed | 32 passed / 0 failed | PASS — identical |
| `waybar-equivalence-check` | 0/0 (all SKIP, no baseline) | 0/0 (all SKIP, no baseline) | PASS — identical, expected shape (no committed per-layout baseline exists) |
| `keybind-doctor` | 13 passed / 0 failed | 14 passed / 0 failed | PASS — one more check (this phase's own quickshell-manifest checks), zero failed |
| `quickshell-doctor` | 13 passed / 0 failed | 12 passed / 1 failed | See note below — the one FAIL is the SAME named pre-existing QS-03 failure Phase 13-era plans have carried since 11-04/14-03 |
| `motion-lint` | 53 passed / 0 failed | 79 passed / 0 failed | PASS — grown by this phase's own new files, zero failed |
| `motion-lint --self-test` | 11 passed / 0 failed | 10 passed / 0 failed | PASS — self-test fixture count is stable within tolerance, zero failed |
| `motion-lint --no-pending` | 1 passed / 0 failed | 1 passed / 0 failed | PASS — zero pending exemptions; D-05's no-scroll rule needed none on any of the four tabs |
| `theme-stress-test` | 10/10 switches, 162 passed / 0 failed | 10/10 switches, 162 passed / 0 failed, exit 0 | PASS — completed on the second attempt after the tree was committed clean (see note below) |

**`theme-doctor`'s one FAIL is `git status --porcelain is empty`.** Root cause, verified by `git diff`: `.planning/STATE.md` carries an in-flight orchestrator bookkeeping diff (`last_updated`/`last_activity_desc` timestamp fields) that predates this session and is owned by the orchestrator's own state machinery, not by any code this task touched. This is **not** the same failure Phase 13 recorded (Phase 13 closed with a genuinely clean tree, 206/0) — it is the expected, self-resolving mid-execution state of any in-progress plan, and it will read clean once this plan's own closing commits land. All 229 non-git-clean checks passed. Recorded honestly as a new-but-explained transient, not silently equated to a Phase 13 precedent it isn't.

**`quickshell-doctor`'s one FAIL is `headless output remove (QS-03)`** — byte-identical in wording and cause to the exact failure `14-03-SUMMARY.md`'s Task 3 and `deferred-items.md` already recorded (headless-monitor-hotplug re-creatability, PROJECT.md's accepted-permanent QS-03 limitation, D-13). Confirmed the same class by re-reading the failure text: "monitor count back to baseline (1 == 1), DP-1 probe still creatable (found: 0), shell PID unchanged... no crash marker." This is the SAME named pre-existing failure, not new.

**`theme-stress-test`: first attempt ABORTED, second attempt (after this task's own commit landed) completed clean.** First attempt aborted at switch 1/10 on the identical `theme-doctor` strict-exit-0 git-clean gate described above (the stress test runs `theme-doctor` after every switch and hard-stops on any failure); theme was left at `catppuccin` mid-abort and restored to the pre-test value `gruvbox` immediately after. Root cause was `STATE.md`'s in-flight bookkeeping diff plus this task's own not-yet-committed SUMMARY — both landed via this task's own Task-3 documentation commit (`22ec4c5`) and a follow-up STATE.md session-continuity commit (`857ac23`), after which the tree read genuinely clean (`git status --porcelain` empty, `theme-doctor` 230/0). The full stress test was then re-run to completion: **10/10 switches, 162 passed, 0 failed, exit 0**, `git status --porcelain` empty afterward — matching Phase 13's own recorded baseline exactly. The run's own designed final theme was `materialyou` (the last theme in its fixed 10-theme switch sequence); manually restored to the session's original `gruvbox` afterward (`theme-apply gruvbox`, exit 0) as a courtesy, since the stress test itself has no "restore original theme" step of its own (matching 13-07's own precedent of leaving the desktop on the run's last theme).

**One correction made along the way, recorded because it materially affects reported project state:** the `gsd-tools state.record-session` call used to note this session's stopping point had a side effect of recomputing `progress.completed_phases`/`completed_plans`/`percent` from SUMMARY.md file *presence* on disk, ignoring this file's own `status: blocked` frontmatter — it briefly reported Phase 14 as 5/8 complete and this plan as done, which is false (Task 4 has not run). Manually reverted to the accurate pre-Task-4 values (4/38/50%) in the same STATE.md commit, and corrected a separately-stale "Plan: 1 of 9" position line to reflect that all nine plans have reached execution with only 14-09's Task 4 outstanding.

`keybind-doctor` and `quickshell-doctor` were checked specifically for the two things Task 3 names by name:

- **Manifest AND live registration, recorded separately, for `quickshell:dashboard` specifically:** manifest entry confirmed present (`{"appid":"quickshell","name":"dashboard","chord":{"mods":"SUPER","key":"D"},...}` in `shortcuts.json`); live registration confirmed present (`quickshell:dashboard -> ` in `hyprctl globalshortcuts`, post-restart). Both present — Pitfall 6's failure signature (manifest-present-but-not-live) does NOT apply here.
- **`quickshell-doctor`'s namespace-discipline check, on the drawer's own namespace:** `[PASS] namespace discipline (D-21): every quickshell-* layer namespace sits at level 3 (overlay) and belongs to the shell's own PID` — independently confirmed via a direct `hyprctl layers -j` read showing `"namespace":"quickshell-dashboard"` at level `"3"` with `pid` matching the live shell PID.

### B. The three-reader proof, as a delta

No track was playing during this session (`playerctl status` → "No players found"), so the visual identity half (all three surfaces naming the same track) is **explicitly deferred to Task 4**, per the plan's own instruction — this task records only the mechanical half.

Using a self-match-safe counting method (`ps -eo pid,cmd | grep -c '[m]edia-status\.sh watch$'`, avoiding `pgrep`'s false self-match against the invoking shell's own command line):

| Point | Media watch children |
|---|---|
| Baseline (drawer dismissed) | 1 — the AGS applet's own pre-existing watcher (PID 1394, confirmed via `ps -eo pid,ppid,cmd`) |
| Drawer summoned | 2 (baseline + 1) |
| Drawer dismissed again | 1 (back to baseline) |
| After 5 more summon/dismiss cycles | 1 (unchanged — nothing leaks) |

The drawer's read-only posture: zero MPRIS-service imports (Task 2, invariant 1) and every transport call site names the sanctioned mutator script (Task 2, invariant 8) — third **reader**, not third writer, exactly as roadmap criterion 4 requires.

### C. The DASH-07 mirror

**Route taken:** per `14-04-SUMMARY.md`'s recorded route, the drawer's `HyprlandFocusGrab` and D-13's focus-loss dismissal make a literal side-by-side with swaync's own control centre structurally unreachable on this build (opening the CC would dismiss the drawer). This task therefore proves the **mechanical source-identity half**, which is what makes the mirror structural rather than coincidental regardless of which route a human eye takes at Task 4:

| Token | In `swaync/config.json` | In `QuickToggles.qml` |
|---|---|---|
| `gaming-mode-toggle.sh` | present | present |
| `theme-switch.sh` | present | present |
| `swaync-client` | present | present |
| `gaming-mode` (watched state) | present | present |
| `state/theme/mode` (watched state) | present | present |

All three mirrored toggles' exec targets and watched state sources are the identical strings in both files — two grids that could theoretically diverge in behavior while looking synced on screen; this assertion is what rules that out.

**D-26's flip, proven against the real config string in a scratch home, mutating nothing live:**

```
CMD (extracted from swaync/config.json's theme-switch update-command):
  v=$(cat ~/.local/state/theme/mode 2>/dev/null || echo dark); case $v in dark) echo true ;; *) echo false ;; esac
mode=dark  -> true
mode=light -> false
```

Both directions correct. Scratch `$HOME` deleted afterward; the live `~/.local/state/theme/mode` file was never touched.

**The D-23 sentence, as required:** the motion-scale segmented row is deliberately outside this DASH-07 mirror proof because it has no swaync counterpart — it is a one-way view onto `~/.local/state/theme/motion-scale`, not a bidirectionally-mirrored toggle. This is intentional asymmetry, not an unexplained gap.

### D. Layer, fullscreen and no-scroll re-observations, against real content

**Per-tab frame geometry, live-read via `hyprctl layers -j`, navigated with real `wtype` keypresses (not a dispatcher — arrow-key tab navigation is QML-internal keyboard focus, not a Hyprland dispatch target):**

| Tab | w×h | Namespace | Level | Exclusive zone |
|---|---|---|---|---|
| Dashboard | 760×826 | `quickshell-dashboard` | 3 (overlay) | 0 |
| Media | 760×424 | `quickshell-dashboard` | 3 (overlay) | 0 |
| Performance | 760×778 | `quickshell-dashboard` | 3 (overlay) | 0 |
| Weather | 760×497 | `quickshell-dashboard` | 3 (overlay) | 0 |

Confirmed via a real forward pass (`Right`×3) and a real backward pass (`Left`×3) — both directions produced the identical four values, and the backward-navigation pager-width bug 14-06 deferred is confirmed **structurally resolved** (see key-decisions): width is now a shared fixed floor (760px) across all four tabs, so there is nothing left to get stuck.

**Note on "the same height on all four" (Task 3's own acceptance-criteria phrasing):** this literal wording is stale, inherited from before 14-03's own render gate (round 2, human-approved 2026-07-29) superseded D-04's uniform-frame requirement with per-tab dynamic sizing — a decision 14-04/14-06/14-08 each re-confirmed. The four heights above are DIFFERENT by design, not by defect; recording this explicitly rather than either silently "fixing" the acceptance text or falsely claiming four identical numbers.

**Dismissed:** `hyprctl layers -j` shows zero `quickshell-dashboard*` entries — D-14's destroy semantics confirmed.

**Waybar's reserved zone, before/during/after:** `[[0,46,0,0]]` unchanged across the entire four-tab sweep (top edge reserves 46px, unaffected by drawer summon/dismiss on any tab).

**Fullscreen refusal, both halves re-exercised on a live window (kitty, this session's own terminal):**

| State | `fullscreen` field | Summon attempted | Result |
|---|---|---|---|
| True fullscreen (`hl.dsp.window.fullscreen(0)`) | 2 | Yes | Silent no-op — zero `quickshell-dashboard` layers appeared, swaync notification count unchanged (1 before, 1 after) |
| Maximized (`hl.dsp.window.fullscreen(1)`) | 2 | Yes | **Also refused** — reproduces 14-01's documented, already-flagged deviation from D-11's literal text: this Hyprland 0.56.1 build reports the identical `fullscreen: 2` for both states everywhere in its IPC, so "maximized (bar visible) should open normally" is unachievable on this host. Re-confirmed, not re-litigated; window restored to normal afterward. |

### E. Live theme switch with the drawer open

Drawer summoned on the Media tab (760×424); `theme-apply nord` run directly (exit 0). Layer address (`0x555d6791fb60`) and geometry unchanged throughout — the surface never closed or restarted. `~/.cache/quickshell.log` line count unchanged (79 before, 79 after) — a pure colour-token re-theme produces zero log lines by design (Phase 12's D-13/QS-04 finding, re-confirmed). Theme restored to the pre-test value `gruvbox` (`theme-apply gruvbox`, exit 0, confirmed via `current-theme`). The reload fan-out remains free of any shell step (`grep -c quickshell theme-engine/lib/reload.sh` → 0; `git log` shows no Phase-14 commit touching it).

### The D-05 slack table — reconstructed live (see key-decisions for why)

`DashboardTab.qml` is the only one of the four tab files carrying its own explicit, named D-05 arithmetic comment (added during this plan's Task 2 consolidation pass). `MediaTab.qml`, `PerformanceTab.qml` and `WeatherTab.qml` never had this recorded in their own plans' SUMMARYs — a real historical gap in 14-06/14-07/14-08, not something this task can retroactively attribute to them. This table is reconstructed **now**, live, using the one consistent reference point already established in `DashboardTab.qml`'s own source comment: D-02's original 860px height anchor, less the 64px tab-bar row = **796px available**.

| Tab | Content formula (from source) | Content height | Available | Slack | Slack % |
|---|---|---|---|---|---|
| Dashboard | hero(64)+cal(238)+media(72)+resources(100) + 3×bandGap(48) + panelPadding×2(48) + bandGap(16) + footer(128) | 714 | 796 | 82 | **10.3%** |
| Media | `content.height + panelPadding×2` (art/title/seek/transport/volume/player-selector stack) | 312 | 796 | 484 | **60.8%** |
| Performance | dialGridRow(464, 2×2 grid of 224px dials + 16px rowSpacing) + spacingLg(24) + networkRowWrap(130) + spacingLg×2(48) | 666 | 796 | 130 | **16.3%** |
| Weather | heroBand + spacingMd(16) + hourStrip + spacingMd(16) + dayRow + spacingLg×2(48) | 385 | 796 | 411 | **51.6%** |

All four tabs clear D-05's ≥10% slack floor; Dashboard (the richest tab) sits right at the intended 10-15% band, while Media/Performance/Weather sit far above it. This is not a coincidence to flag as a problem: 14-03's render-gate-ratified per-tab **dynamic** sizing model means the frame is now content-sized (content height + a fixed 112px chrome allowance) rather than fitted into a shared fixed budget, so the original "10-15% slack against one shared 860px frame" framing only really constrains the tallest tab. Nothing is clipped, overflowing, or colliding on any tab — confirmed by the fact that every live-measured frame height exactly equals its formula's predicted value, with zero truncation. Whether the wide-open slack on the three lighter tabs and the resulting narrow (~760px, ~third-of-screen) width read as intentional or as "too narrow" is explicitly Task 4 check 4's job, not this task's.

### The blocking backward-nav bug incidentally resolved

Confirmed live in the same navigation pass used for the layer table above: stepping backward through all four tabs (`Left`×3 from Weather) produced the correct width (760, unchanged) and correct height at every step (778 → 424 → 826), with no stuck-width state at any point. 14-06's deferred bug is now moot — see key-decisions for the mechanism (drawerMinWidth consolidated to a shared 760 floor since 14-08, leaving no width axis to get stuck on).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug, pre-Task-3, prior session] `Motion.qml` snake_case JsonAdapter binding**
- **Found during:** Task 1, Fence 2's own acceptance criterion (off scale should produce zero cascade markers; it produced one)
- **Issue:** `motionEnabled`/`motionScale` JsonAdapter properties never bound to `motion.json`'s `motion_enabled`/`motion_scale` keys — silently inert `off` scale, repo-wide, for two phases.
- **Fix:** Renamed the two internal binding property names only; public API byte-identical.
- **Files modified:** `quickshell/.config/quickshell/modules/Motion.qml`
- **Verification:** `off` → 0 cascade markers (was 1); `motion-lint` 77/77, `--self-test` 10/10, `--no-pending` 1/1.
- **Committed in:** `7850b7f`

**2. [Rule 1 - Bug, Task 2, prior session] Invariant 9's comment-stripper passed its own poisoned run**
- **Found during:** Task 2, half two's poisoned-run-first discipline
- **Issue:** `sed 's|//.*||'` ate the `//` inside an injected `"http://ip-api.com/json"` literal before the grep ran, so the poisoned copy incorrectly passed — a broken negative assertion.
- **Fix:** `sed 's|\([^:]\)//.*|\1|'` (only strip `//` when not preceded by `:`).
- **Files modified:** none tracked (invariant-runner logic, executed inline, not a committed script)
- **Verification:** re-poisoned, confirmed to fail as required.
- **Committed in:** `87bba52` (documented in the commit message)

**3. [Rule 3 - Blocking issue, Task 3, this session] `quickshell-doctor` launcher-log-freshness FAIL**
- **Found during:** Task 3's committed gate sweep
- **Issue:** The running quickshell process (~11h uptime) had no `starting` line left in its own log; the check reads that line to confirm a healthy last startup.
- **Fix:** Detached relaunch (`setsid uwsm app -- quickshell-launch.sh`), per the standing 14-06 executor rule. No source file touched.
- **Verification:** Fresh `starting` line present; `quickshell-doctor` re-run clean on this specific check (12 passed / 1 failed, the 1 being the unrelated pre-existing QS-03 item); dashboard shortcut confirmed still live post-restart.
- **Committed in:** n/a (operational action, not a code change)

### Deferred / Not Performed

**Three-reader visual identity (roadmap criterion 4's visual half) — deferred to Task 4**, as the plan itself directs; no track was playing during this session to observe.

---

**Total deviations:** 2 auto-fixed bugs (prior session), 1 operational fix (this session, no source touched — quickshell relaunch), 1 mechanical self-correction (STATE.md progress-recompute side effect, reverted), 0 items remaining deferred except the visual three-reader observation which is structurally Task 4's job, not this task's.

## Known Stubs

None found. No hardcoded empty values, placeholder text, or unwired data sources were introduced by this plan — Cascade.qml and Design.qml are both pure infrastructure (an animation runner and a constants singleton), and no UI-facing content changed.

## Threat Flags

None. This plan's own `<threat_model>` scopes its risk surface to verification integrity (vacuous gates, unrecorded observations, source-identity spoofing) rather than new attack surface, and this task performed exactly the mitigations that threat register specifies: poisoned-then-clean proofs for every negative assertion (T-14-30), the observation-behind-every-claim discipline (T-14-31), and the mechanical source-identity pairing for the DASH-07 mirror (T-14-32). No new network endpoint, auth path, file-access pattern, or schema change was introduced.

## User Setup Required

None — this task performed only live verification and one detached process restart, no persistent configuration change.

## Next Phase Readiness — NOT YET, Task 4 pending

**This plan is NOT complete.** Task 4 (`checkpoint:human-verify`, `gate="blocking"`) has not been run. Per ROADMAP standing constraint 1, this gate cannot be auto-approved under any circumstance, including auto-chain/auto-advance modes — it is the phase's only sign-off that sees all four tabs populated at once, and three of its eleven checks (2, 4, 5) are explicitly deferred, previously-unanswered judgments from 14-03/14-08's own render gates that must be answered even on approval.

**Before Task 4 can be judged, confirm:**
- Material Symbols Rounded renders (Task 4's own precondition) — **confirmed already, this session:** `ttf-material-symbols-variable-git 4.0.0.r166.g528cb964-1` installed, `fc-list` resolves `Material Symbols Rounded` at multiple weights. Precondition is met; Task 4 does not need to halt on it.
- The full `theme-stress-test` run — **completed this session** (10/10, 162/0, exit 0) once the tree read clean after Task 3's own commits landed; nothing further needed here.

**Once Task 4 is answered:**
- If APPROVED, this plan's `state_updates` and `final_commit` steps (advance plan counter, record session, mark REQUIREMENTS.md items, commit STATE.md/ROADMAP.md/REQUIREMENTS.md/this SUMMARY together) still need to run — they were deliberately NOT run in this session, since running them ahead of Task 4's approval would falsely advance phase-completion state.
- If changes are requested, this plan re-enters as a continuation with Tasks 1-3 already complete and committed (per the table in this session's own continuation instructions) and Task 4's specific feedback as the new resume point.

## Self-Check: PASSED

- FOUND: `quickshell/.config/quickshell/modules/dashboard/Cascade.qml`
- FOUND: `quickshell/.config/quickshell/modules/dashboard/Design.qml`
- FOUND: `quickshell/.config/quickshell/modules/dashboard/qmldir` (both new types registered)
- FOUND: `quickshell/.config/quickshell/modules/Motion.qml` (snake_case fix present)
- FOUND: commit `7850b7f` in `git log --oneline --all`
- FOUND: commit `3a05c97` in `git log --oneline --all`
- FOUND: commit `1388516` in `git log --oneline --all`
- FOUND: commit `87bba52` in `git log --oneline --all`
- FOUND: `.planning/phases/14-dashboard-drawer/14-09-SUMMARY.md` (this file)

---
*Phase: 14-dashboard-drawer*
*Task 3 completed: 2026-07-30 — Task 4 pending a fresh session*
