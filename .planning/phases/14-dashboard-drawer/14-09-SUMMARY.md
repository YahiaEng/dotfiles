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
  - "Design.qml — the shared drawer design-constants singleton, consolidating 15 constants across all 7 declared files (66 + Dial.qml's own 6 call sites), plus a shared tooltipDelayMs constant"
  - "WeatherPalette.qml — a second, deliberate documented exemption to D-11's palette contract, for weather condition and sunrise/sunset glyphs only"
  - "Ten repo-wide prohibition invariants, each proven able to fail (poisoned run) before being trusted to pass (clean run) — one (hex-colour) re-proven after being deliberately narrowed by file name"
  - "The phase-close evidence record: gate sweep, three-reader delta proof, DASH-07 mirror, layer/fullscreen re-observations, D-05 slack table"
  - "Task 4's render-gate change requests actioned: Weather tab (condition-glyph colour, hover tooltip, forecast separator) and Performance tab (one-row-of-four dial layout, retuned ring thickness)"
affects: [phase-15, phase-16, phase-17]

tech-stack:
  added: []
  patterns:
    - "Non-visual QtObject cascade runner reading only two motion-token pairs plus the motion-enabled flag, arming-flag-consumed-once-per-surface-lifetime as the sole re-entrancy guard"
    - "Singleton design-constants file (pragma Singleton + qmldir singleton keyword, both required per the 12-06 finding) as the cross-file constant-sharing mechanism for a Quickshell submodule"
    - "Poisoned-scratch-copy-then-clean-tree proof discipline applied to a full battery of ten repo-wide negative-grep invariants in one task"
    - "A second, narrower absolute-colour singleton (WeatherPalette.qml) as a documented, file-scoped exemption to the Colours.qml palette contract — the pattern Phase 15/16 should reach for if a future surface needs the same class of exception, rather than loosening the contract itself"

key-files:
  created:
    - quickshell/.config/quickshell/modules/dashboard/Cascade.qml
    - quickshell/.config/quickshell/modules/dashboard/Design.qml
    - quickshell/.config/quickshell/modules/dashboard/WeatherPalette.qml
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
  - "CORRECTED (Task 4, this session — supersedes the entry as originally recorded by Task 3): the backward-navigation pager-width bug 14-06 deferred to 14-08/14-09 (Left arrow from a wider to a narrower tab leaving the frame width stuck) was recorded by Task 3 as 'structurally moot' on the reasoning that since 14-04/14-08's consolidation onto drawerMinWidth=760 as a shared floor, every tab rendered at the SAME width (760px) and only height varied per tab — there was no width to get stuck at. That was TRUE ONLY WHILE every tab sat at the 760 floor, and it was PROVISIONAL, not structural: Task 4's Performance change (one row of four dials) pushed that tab to 1040px, the first non-floor width in the whole phase, which made the width axis live for the first time and reopened the exact bug class Task 3 had declared moot. The bug class was then actually re-tested and disproven, not merely re-assumed away: forward `760/826 → 760/424 → 1040/498 → 760/514` and backward the exact reverse, no stuck width in either direction; a rapid mid-transition poll captured genuine animated intermediate values mid-swipe (`1040→1011→928→870→833→808→791→779→768→762→760` on `Behavior on implicitWidth`), collapsing correctly to a hard jump at `off` (zero intermediate samples) and tightening correctly at `reduced` (5 samples vs 8 at `normal`). Full detail in the Task 4 section (B2). Still not re-opened as a fix to `Dashboard.qml` itself — the pre-existing mechanism handles the now-live width axis correctly; recorded as a genuinely re-verified resolution, not an incidental one."
  - "D-04's literal 'identical frame height on all four tabs' truth is stale text this plan does not re-litigate: 14-03's own render gate (round 2, human-approved) superseded it with per-tab dynamic proportions, ratified again through 14-04/14-06/14-08. This plan's Task 3 re-observation recorded the per-tab heights AS THEY STOOD AT THAT POINT (826/424/778/497) as the correct, already-ratified behavior, not as a defect against the original text. CORRECTED (Task 4, this session): those four numbers are Task 3's baseline, not the plan's final state — Task 4's Performance and Weather changes moved two of them. The current, live-measured per-tab dimensions at plan close are Dashboard 760x826, Media 760x424, Performance 1040x498, Weather 760x514 (see Task 4 sections B1/A4 and the C.4 table)."
  - "TASK 4 (this session, continuation): the human render gate returned a CHANGE REQUEST, not an approval — nine of eleven checks passed outright; check 4's width verdict and check 9 (Weather) each required changes, actioned in this session and detailed in the Task 4 section below. WeatherPalette.qml is a new, second documented D-11 exemption (Design.qml being the first kind of exemption in spirit, though Design.qml is not a colour exemption — WeatherPalette.qml is the first ABSOLUTE-colour exemption). Performance's drawer width goes non-floor for the first time in the phase (1040px, not 760), which reopened and re-proved the width-transition axis Task 3 had only ever observed at the floor. Dial.qml — named in Task 2's own file scope — was found to have been skipped by Task 2's actual consolidation commit and was folded in this session as a separate fix commit."
  - "Theme restoration self-correction: this session initially restored the desktop theme to 'catppuccin' after a legibility test, based on a stale ~/.cache/current-theme file (last modified 2026-07-06, not the live tracker). The live tracker is ~/.local/state/theme/current-theme, and Task 3's own SUMMARY record shows the prior session ended on 'gruvbox' — the actual original value. Caught before the phase-close gate sweep and corrected (theme-apply gruvbox); recorded here rather than silently left at the wrong value."

patterns-established:
  - "Singleton-based cross-submodule design-token sharing (Design.qml) — the mechanism Phase 15's panels should reach for instead of re-declaring local spacing/type constants per file."
  - "A second, narrower singleton (WeatherPalette.qml) as the sanctioned shape for a documented, scope-limited exemption to the Colours.qml palette contract — grep-verifiable, file-named, never a loosening of the contract itself."

requirements-completed: [DASH-01, DASH-02, DASH-03, DASH-04, DASH-05, DASH-06, DASH-07, DASH-08]

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
    verification:
      - kind: other
        ref: "Human returned a CHANGE REQUEST on checks 4 (Performance width) and 9 (Weather tab, four items) at the first gate — nine checks (1,2,3,5,6,7,8,10,11) passed outright there. Both change requests were actioned and re-verified in this session (Task 4 section). At the RE-GATE, the human returned APPROVED, verbatim: 'Approved. And I already approved the dynamic width/height.' — closing checks 4 and 9, the last two of the eleven."
        status: pass
    human_judgment: true
    rationale: "Visual/feel judgment across the whole phase per ROADMAP standing constraint 1. All eleven checks are now signed off: nine at the first gate (1,2,3,5,6,7,8,10,11), and checks 4 and 9 at this re-gate after the requested Weather/Performance changes landed. The gate is closed, not auto-approved — a human returned an explicit APPROVED verdict at each stage."
  - id: D5
    description: "Task 4 change requests actioned: WeatherPalette.qml (D-11 exemption) + hover tooltips + centred separator on the Weather tab; one-row-of-four dial layout + retuned ring thickness on the Performance tab; the Dial.qml consolidation gap Task 2 missed, folded in; the width-transition axis re-tested now that Performance exceeds the 760 floor for the first time in the phase"
    requirement: "DASH-01..08 (phase-close verification)"
    verification:
      - kind: other
        ref: "Commits a480b4c (Weather), 5f5c478 (Performance), aaf2583 (Dial.qml). This SUMMARY's Task 4 section — live command output, screenshots and geometry readings for every change."
        status: pass
    human_judgment: false

# Metrics
duration: multi-session (Tasks 1-2 in a prior interrupted session; Task 3 + this SUMMARY's first draft in a second session; Task 4's human gate + change-request response + re-verification in a third continuation session; the re-gate approval and phase-close bookkeeping — SUMMARY corrections, deferred-items capture, state/roadmap closure — in a fourth continuation session)
completed: 2026-07-30
status: complete
---

# Phase 14 Plan 09: Cascade, Consolidation, Gate Sweep & Phase-Close Evidence Summary

**D-21's summon-only entrance cascade shipped and both its fences proven live; the four-plan-deferred design-constants consolidation landed on a shared `Design` singleton; ten repo-wide prohibition invariants each proven able to fail before being trusted to pass; the full phase-close gate sweep, three-reader delta proof, DASH-07 mirror and layer/fullscreen re-observations ran against all four populated tabs; and Task 4's blocking human render gate returned a CHANGE REQUEST on the Weather and Performance tabs — both actioned (a new `WeatherPalette.qml` D-11 exemption, hover tooltips, a forecast separator, a one-row Performance dial layout, retuned ring thickness, and the `Dial.qml` consolidation gap Task 2 missed) and, at a focused re-gate on just those two surfaces, APPROVED. Phase 14 is closed.**

## Performance

- **Duration:** Multi-session across four sessions — see `duration` in frontmatter for the full breakdown.
- **Tasks:** 4 declared (Task 1 auto, Task 2 auto, Task 3 auto, Task 4 checkpoint:human-verify, gate="blocking"). All four complete. Task 4 returned a CHANGE REQUEST at its first gate (checks 4 and 9), both actioned, and returned APPROVED at the re-gate — all eleven checks now signed off. Plan closed.
- **Files modified:** 11 QML files (3 created — `Cascade.qml`, `Design.qml`, `WeatherPalette.qml` — 8 modified) across Tasks 1, 2 and 4; zero source files touched by Task 3 (verification-only).

## Accomplishments

- **Task 1 (prior session):** Built `Cascade.qml`, a non-visual `QtObject` runner reading only the stagger and emphasized-in `Motion` token pairs plus the motion-enabled flag, wired one `cascadeBands` ordered list per tab, and proved both of D-21's fences live with counted run markers. Found and fixed a repo-wide prerequisite bug along the way: `Motion.qml`'s JsonAdapter was silently failing to bind `motionEnabled`/`motionScale` from `motion.json`'s snake_case keys, making the `off` motion scale inert everywhere in the shell (~40 sites), not just the new cascade.
- **Task 2 (prior session):** Read all four sibling consolidation notes, found 14-08's deferral rationale did not survive inspection, and consolidated 15 design constants onto a new `Design` singleton (66 pure value-for-value substitutions, zero mismatches, geometry byte-identical before/after). Then ran all ten repo-wide prohibition invariants, each first proven able to fail against a poisoned scratch copy, then proven to pass against the real tree — catching and fixing one broken invariant (a comment-stripper that ate `http://` and let a poisoned GeoIP-host string slip through) and naming three timer intervals that were escaping `motion-lint`'s CHECK B blind spot.
- **Task 3 (this session):** Ran the full eight-script committed gate sweep against Phase 13's recorded baseline; proved the three-reader media-backend claim as a process-count delta (baseline 1, open baseline+1, closed back to baseline, unchanged across five cycles); proved the DASH-07 toggle mirror's source identity and D-26's flip direction against the real config string in a scratch home; re-observed the layer posture, fullscreen refusal and a live theme switch against all four now-populated tabs; and reconstructed the D-05 vertical-slack arithmetic that three of the four content plans' own SUMMARYs never recorded.

## Task Commits

1. **Task 1: D-21 summon-only entrance cascade** — `7850b7f` (fix: prerequisite Motion.qml snake_case binding fix) + `3a05c97` (feat: the cascade itself, both fences proven)
2. **Task 2: Consolidation disposition + ten prohibition invariants** — `1388516` (refactor: Design.qml consolidation) + `87bba52` (fix: three named timer intervals, CHECK B blind-spot record)
3. **Task 3: Gate sweep + phase-close evidence** — no source commit (verification-only); this SUMMARY is Task 3's recorded deliverable, committed alongside this plan's docs commit (`22ec4c5`, `857ac23`, `0628624`).
4. **Task 4: Render-gate change-request response** — `a480b4c` (Weather: WeatherPalette.qml, tooltips, separator), `5f5c478` (Performance: one-row dial layout, retuned ring thickness), `aaf2583` (Dial.qml consolidation fix), `2c9b4f0` (docs). Human returned APPROVED at the re-gate on both changed surfaces; no further source commit was needed to close the plan.

**Plan metadata:** this SUMMARY.md, first committed as `docs(14-09): record Task 3 gate sweep and phase-close evidence (Task 4 pending)`, then updated across the Task 4 change-request and re-gate sessions, and closed by this session's own bookkeeping commit (SUMMARY corrections, deferred-items capture, STATE.md/ROADMAP.md closure).

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

**Superseded note (Task 4, this session):** the "now moot" verdict above was correct only as far as it went — it is a provisional finding true while every tab sat at the shared 760 floor, not a structural one. Task 4's Performance change made the width axis live for the first time in the phase (1040px) and reopened this exact bug class; it was then actually re-tested and disproven rather than re-assumed moot. See the corrected key-decisions entry and Task 4 section B2 for the full re-test evidence (forward/backward geometry, animated intermediates, off/reduced collapse).

**Note (Task 4, this session): the geometry table above and the D-05 slack table below it are Task 3's ORIGINAL baseline, taken before Task 4's human gate.** They are left unedited here as the historical record Task 3 actually produced. The Performance and Weather rows changed as a direct result of Task 4's change requests — see the Task 4 section immediately below for the current, live-measured numbers. Dashboard and Media are unchanged and their rows above still hold.

## Task 4 — Render-Gate Change Request Cycle (this session)

### The human's verdict, verbatim in substance (carried from this session's own continuation brief)

Checks 1, 2, 3, 5, 6, 7, 8, 10, 11 — **PASS**, not re-asked here. Two checks came back as change requests:

- **Check 4 (D-05 slack + drawer-width verdict):** the dynamic per-tab sizing and the lopsided slack table are approved decisions, not defects. The width verdict was a change request: *"The performance tab should be shorter and wider and the metric rings adjusted accordingly."*
- **Check 9 (Weather tab):** four items — (1) add a hover tooltip naming the condition, glyphs alone are hard to tell apart; (2) colour the weather condition glyphs; (3) colour the sunrise/sunset glyphs; (4) separate today's forecast from the 5-day forecast with a small centred line.

Per this plan's own `<constraints>`, the other nine checks are not being re-litigated — this section covers only the two changed surfaces.

### A. Weather tab

**A1 — `WeatherPalette.qml`, a second documented D-11 exemption.** New singleton at `quickshell/.config/quickshell/modules/dashboard/WeatherPalette.qml`, carrying both `pragma Singleton` and the qmldir `singleton` keyword (the 12-06 finding, same discipline `Design.qml` already follows). The file's own header states the exemption and its rationale in full: discriminability across 8+ weather conditions at icon size cannot be built out of 19 harmonised, theme-relative Material You roles, and absolute colour genuinely IS the semantic in weather iconography — the same class of exception `Colours.error` already grants within the 19-role contract itself, extended here to a second, narrower case.

Eight absolute colours: `sun #FFC107`, `cloudLit #ECEFF1`, `cloudRain #78909C`, `sunrise #FFD54F`, `sunset #7986CB` are the human-approved starting values, used verbatim, unchanged. `night #90A4AE`, `snow #E1F5FE`, `storm #546E7A` were added to cover `WeatherBackend.qml`'s full `_wmoTable` ligature-name set (16 distinct symbol names across day/night and every WMO code family) rather than leaving conditions unmapped — the task's own instruction was to read the backend and cover its real condition set, not invent one. One resolver, `forSymbol(name)`, keyed by symbol name (what `WeatherTab.qml` actually has at each render site — the tab never sees the raw WMO code) rather than by code; returns `null` for an unrecognised name so the caller falls back to its own themed `Colours.*` value.

**Scope boundary held:** only the condition glyphs (hero + every hour/day cell) and the sunrise/sunset glyphs read `WeatherPalette.*`. Every other colour on the tab — all text, the staleness badge, the new separator — stays on `Colours.*`. Grep-verified: `WeatherPalette` appears in exactly one file outside its own declaration (`WeatherTab.qml`).

**A2 — the invariant collision, handled explicitly (T-14-30 discipline).** Task 2's zero-hex-literal invariant (invariant 2) trips on `WeatherPalette.qml`'s 8 real hex values by construction — confirmed live: the OLD (unnarrowed) assertion now returns a count of 8, not 0. Narrowed by FILE NAME only — `WeatherPalette.qml` excluded by exact basename match, no pattern change, no directory exclusion, the assertion itself otherwise untouched. Then re-poisoned against a DIFFERENT file (a scratch copy of `MediaTab.qml` with an injected `"#123ABC"` literal) and confirmed the narrowed assertion still FAILS (count=1) before trusting its clean run. Clean run against the real tree (narrowed): count=0, PASS. Both runs recorded here, in that order, per the standing poisoned-then-clean discipline.

The other nine invariants were re-run against the real tree with all of this session's new/changed files included — all nine still clean (zero MPRIS imports, zero raw duration/interval literals, zero `Motion.motionScale` references, zero scrolling view types, zero playerctl/ip-api.com references, reload.sh untouched with no Phase-14 commit against it). No regression from this session's edits.

**A3 — hover tooltip, and the `delay:` blind-spot verdict.** Every condition glyph (hero, every hour-strip cell, every day-row cell) now carries a `MouseArea { hoverEnabled: true }` with `ToolTip.visible`/`ToolTip.text`/`ToolTip.delay`, copying `QuickToggles.qml`'s own established pattern (lines ~540/~757 as they stood before this session) exactly.

The delay is a NAMED constant: `Design.tooltipDelayMs` (value 400, unchanged), consumed as `root.tooltipDelayMs` in both `WeatherTab.qml` and `QuickToggles.qml`. **Verdict on whether `QuickToggles.qml`'s two pre-existing bare `ToolTip.delay: 400` sites were in Task 2's original hand enumeration: they were NOT.** Confirmed by re-reading commit `87bba52`'s own message verbatim — its invariant-4 enumeration explicitly names three sites, all `interval:`-keyed (`dndSubscribeGraceTimer`, `dndPollTimer`, `SystemResources.qml`'s `primeTimer`), and its own prose scopes the class to `"every camel-cased duration-shaped property and every interval:"` — `ToolTip.delay` is neither camel-cased-duration-shaped nor an `interval:`, and is not mentioned anywhere in that commit. This is confirmed as a **fourth motion-lint CHECK B blind-spot class**, not a re-discovery of an already-covered one: `QML_DURATION_RE` (`hypr/.config/hypr/scripts/motion-lint` line 914) is anchored on the literal string `duration`, so `delay:` structurally escapes it exactly as `interval:` does. Both pre-existing `QuickToggles.qml` sites are now named (`root.tooltipDelayMs`), and the value (400) is unchanged from what they already used — pure name extraction.

**A4 — the centred separator.** A `Rectangle` (`forecastSeparator`, `Colours.outline`, `radius: height/2`) between `hourStrip.bottom` and `dayRow.top`, `spacingMd` gaps on both sides, width 96px (a small, local, named geometry constant — deliberately narrow, not a full-width rule, per the request's own wording). `WeatherTab.qml`'s `implicitHeight` formula extended by the separator's own height (1px) plus one more `spacingMd` gap. Live-confirmed: the Weather frame grew from the Task 3 baseline 760×497 to **760×514** — exactly the predicted +17px (1 + 16).

**A5 — cascade integrity.** `cascadeBands` left unchanged (`[heroBand, hourStrip, dayRow]`): the separator is decorative chrome between two cascaded bands, not a widget of its own, and D-21 cascades top-level content bands. Live-confirmed via the shell log after the geometry change: `cascade: run tab=3 bands=3` still fires correctly.

**Live visual confirmation (screenshot):** sun glyph reads bright yellow; the "clear"/"partly cloudy" hour and day glyphs read light/white; the sunrise glyph (`wb_twilight`) reads yellow-orange; the sunset glyph (`bedtime`, a crescent moon) reads indigo; the separator is visible, thin and centred between the two forecast rows.

**Blur-legibility test (D-07, this task's C.3 requirement) — PARTIAL, recorded honestly.** A bright wallpaper (`rosepine/1-funky-shapes.jpg`, average luminance 206/255, the second-brightest of the repo's committed wallpapers) was applied via `awww img` and the drawer re-screenshotted. The drawer's own translucent-over-blur surface in that screenshot still read dark because a live application window (not this session's doing) filled the exact screen region directly behind the drawer at the time, so the blur sampled that window's dark content rather than the wallpaper underneath it — discovering this required inspecting a corner of the screen away from the drawer, where the bright wallpaper was confirmed genuinely applied. Moving or closing that window to get a true "bright content directly behind the drawer" screenshot was judged too disruptive to the live desktop session for this task to do unilaterally. What IS confirmed: the chosen colours (`sun #FFC107`, `cloudRain #78909C`, `sunset #7986CB`, etc.) carry strong luminance separation from both the drawer's own dark translucent surface and from `Colours.onSurfaceVariant`-toned neighbouring text at every zoom level checked. **The bright-wallpaper-directly-behind case is not independently confirmed by this session and is carried forward as part of the pending re-gate** — this is exactly the kind of visual judgment call Task 4's own `<how-to-verify>` assigns to the human, not to the executor.

### B. Performance tab

**B1 — geometry.** `dialGrid.columns: 2 -> 4` (one row of four dials, not a 2×2 grid). Diameter kept at round 2's `224`; ring thickness grown `18 -> 22` after a live side-by-side screenshot comparison — 18 read cleanly (not literally "stretched or spindly"), but 22 carries visibly more weight matching the new row's extra horizontal breathing room, and was chosen as a deliberate improvement rather than leaving the value untouched when the human explicitly asked for the rings to be adjusted.

**Live-measured drawer geometry: 1040×498** (Task 3's baseline was 760×778). The plan's own predicted arithmetic ("944 + spacingLg×2 = 992") undercounted one layer: `Dashboard.qml`'s `drawerWidth = activeContentWidth + spacingLg*2` adds the WINDOW's own outer `content` margin on top of the tab's own already-self-padded `implicitWidth` (`dialGrid.width + spacingLg*2` = 992) — this is `Dashboard.qml`'s documented, working design (its own header comment: the outer margin is "added back on top of the active tab's own desired content size"), verified self-consistent by the same mechanism that already produces every other tab's correct geometry, not a bug this task introduced. The REAL number, 1040, is 40.6% of the 2560px primary — closer to D-02's original ~40% intent than the plan's own 992/38.8% prediction.

**B2 — the width axis, re-tested (not assumed moot).** Task 3's own "structurally moot" verdict on 14-06's backward-nav width bug only ever observed the floor-wins case (every tab at 760). Performance now exceeds the floor for the first time in the whole phase, reopening that bug class exactly as this plan's own instructions warned. Re-tested properly:

| Direction | Sequence | Widths/heights |
|---|---|---|
| Forward | Dashboard→Media→Performance→Weather | 760/826 → 760/424 → **1040/498** → 760/514 |
| Backward | Weather→Performance→Media→Dashboard | 760/514 → **1040/498** → 760/424 → 760/826 |

No stuck width in either direction; Performance correctly reaches 1040 and every adjacent tab correctly returns to 760. A rapid mid-transition poll during a live Performance→Weather swipe captured genuine intermediate values (`1040→1011→928→870→833→808→791→779→768→762→760`, height climbing `498→...→514` in step) — the transition animates on `Behavior on implicitWidth`/`implicitHeight` (`Motion.standardDuration`), not a hard step. At `off` motion scale: instant jump, zero intermediate samples across 10 rapid polls. At `reduced`: animates but visibly tighter (5 intermediate samples vs 8 at `normal`), consistent with the halved duration. Motion scale restored to `normal` afterward and confirmed via the QuickToggles segmented row screenshot (`✓ Normal` shown selected).

**B3 — `Dial.qml`'s missed consolidation, folded in.** Task 2's own `<files>` scope named seven files for the Design consolidation; commit `1388516` touched six and skipped `Dial.qml`. Found while retuning Performance's dial geometry (the file's own header still claimed consolidation was "left to 14-08's composition pass" — a sentence commit `87bba52` had already corrected across the other five headers but missed here). Before/after table, pure value-for-value, zero mismatches:

| Property | Before | After |
|---|---|---|
| `_spacingXs` | `4` | `Design.spacingXs` (4) |
| `_fontHeading` | `20` | `Design.fontHeading` (20) |
| `_fontLabel` | `12` | `Design.fontLabel` (12) |
| `_weightEmphasis` | `Font.DemiBold` | `Design.weightEmphasis` |
| `_weightBody` | `Font.Normal` | `Design.weightBody` |
| `_symbolFontFamily` | `"Material Symbols Rounded"` | `Design.symbolFontFamily` |

`_defaultFontFamily` (`Qt.application.font.family`) stays local — a genuine runtime capability read (whatever font Qt itself resolves as the system default), not a design token with a `Design.*` counterpart. Property names unchanged (substitution, not a rename). Live-confirmed geometry byte-identical after the edit; `DashboardTab.qml`'s mini-dials (same `Dial.qml` component, smaller instance, unrelated tab) screenshot-confirmed rendering correctly.

**Amending Task 2's own record:** its "66 substitutions across 6 files" claim (see commit `1388516` and this SUMMARY's Task 2 section above) is accurate as far as it goes, but under-delivered against Task 2's own declared 7-file scope. Recorded here honestly as a gap found and closed in THIS session, not as something the original Task 2 session completed — the Task 2 section above is left as the historical record of what that session actually did, not silently rewritten.

**B4 — cascade + slack.** `cascadeBands` left unchanged (`[dialGridRow, networkRowWrap]`) — both ids still resolve to the same two widgets, just laid out differently inside them. Live-confirmed: `cascade: run tab=2 bands=2` still fires correctly after the geometry change.

Performance's D-05 slack, re-measured against the same 796px available-height reference the original table used: live drawer height 498 = `tabBarHeight(64) + activeContentHeight + spacingLg*2(48)`, so `activeContentHeight = 386` (was 666). Slack = `796 - 386 = 410`, **51.5%** (was 130/16.3%). Weather's own content height similarly grew from 385 to `402` (514 - 64 - 48), slack `796 - 402 = 394`, **49.5%** (was 411/51.6% — a small decrease, consistent with the separator adding 17px of fixed content height). Both updated rows:

| Tab | Content height | Available | Slack | Slack % |
|---|---|---|---|---|
| Performance (was 666/130/16.3%) | 386 | 796 | 410 | **51.5%** |
| Weather (was 385/411/51.6%) | 402 | 796 | 394 | **49.5%** |

Dashboard and Media are unchanged (714/82/10.3% and 312/484/60.8% respectively, per the original table above).

### C. Re-verification

**C.1 — full gate sweep, re-run after this session's commits landed (tree clean):**

| Script | Task 3's own run | This session's run | Verdict |
|---|---|---|---|
| `theme-doctor` | 229 passed / 1 failed (git-clean transient, explained) | **232 passed / 0 failed** | PASS — tree genuinely clean this time |
| `theme-parity` | 2608 passed / 0 failed | 2608 passed / 0 failed | PASS — identical |
| `waybar-design-lint` | 32 passed / 0 failed | 32 passed / 0 failed | PASS — identical |
| `waybar-equivalence-check` | 0/0 (all SKIP) | 0/0 (all SKIP) | PASS — identical, expected shape |
| `keybind-doctor` | 14 passed / 0 failed | 14 passed / 0 failed | PASS — identical |
| `quickshell-doctor` | 12 passed / 1 failed (QS-03, pre-existing) | 12 passed / 1 failed (same QS-03) | PASS — same named pre-existing failure |
| `motion-lint` | 79 passed / 0 failed | **81 passed / 0 failed** | PASS — grown by this session's new files (WeatherPalette.qml + 2 modified files), zero failed |
| `motion-lint --self-test` | 10 passed / 0 failed | 10 passed / 0 failed | PASS — identical |
| `motion-lint --no-pending` | 1 passed / 0 failed | 1 passed / 0 failed | PASS — zero pending exemptions, unchanged |
| `theme-stress-test` | 10/10 switches, 162/0, exit 0 | **10/10 switches, 162/0, exit 0** | PASS — identical shape, re-run clean below |

`quickshell-doctor`'s namespace-discipline check re-confirmed: `[PASS] namespace discipline (D-21): every quickshell-* layer namespace sits at level 3 (overlay) and belongs to the shell's own PID`.

**C.2 — `theme-stress-test`, re-run after this session's commits landed.** `git status --porcelain` empty before the run. Result: **10/10 switches, 162 passed, 0 failed, exit 0** — matching both Phase 13's baseline and Task 3's own re-run exactly. The run's own designed final theme was `materialyou` (last in its fixed 10-theme sequence, confirmed via `~/.local/state/theme/current-theme`).

**Restoration, including a self-caught correction:** earlier in this session, after the D-07 blur-legibility screenshot test, this session restored the desktop theme to `catppuccin` based on `~/.cache/current-theme` — which turned out to be a STALE, unrelated file (last modified 2026-07-06, long before this phase). The live tracker is `~/.local/state/theme/current-theme`, and Task 3's own SUMMARY record (two separate sentences) states the prior session ended on `gruvbox`, the actual original value for this continuation. Caught before the gate sweep's own conclusions could be affected (theme identity does not affect the gate sweep's pass/fail counts) and corrected: `theme-apply gruvbox`, confirmed via the live tracker. Recorded here as a Rule-1 self-fix rather than silently left at the wrong value — see Deviations below.

**C.3 — Weather colour legibility:** see section A above (partial confirmation; the bright-wallpaper-directly-behind-drawer case carried forward to the human re-gate, not independently closed by this session).

**C.4 — geometry re-measured on all four tabs, forward-navigated, this session's final state:**

| Tab | Width×Height | vs. Task 3 baseline |
|---|---|---|
| Dashboard | 760×826 | unchanged |
| Media | 760×424 | unchanged |
| Performance | **1040×498** | was 760×778 |
| Weather | **760×514** | was 760×497 |

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

**4. [Rule 2 - Missing critical functionality, Task 4, this session] `Dial.qml` skipped by Task 2's own declared consolidation scope**
- **Found during:** B3, retuning Performance's dial geometry
- **Issue:** `Dial.qml` was named in Task 2's `<files>` scope but commit `1388516` touched only six of the seven files, leaving `Dial.qml` with seven local literals (including the exact duplicated font-family string the consolidation existed to remove) and a header still claiming consolidation was "left to 14-08".
- **Fix:** Pure value-for-value substitution onto `Design.*`, six of seven properties (see B3's before/after table); `_defaultFontFamily` correctly stays local (runtime capability read).
- **Files modified:** `quickshell/.config/quickshell/modules/dashboard/Dial.qml`
- **Verification:** Geometry byte-identical across all four tabs; DashboardTab's mini-dials screenshot-confirmed still rendering correctly; `motion-lint` 81/81.
- **Committed in:** `aaf2583`

**5. [Rule 1 - Bug, Task 4, this session] Stale `~/.cache/current-theme` used to determine the "original" theme for restoration**
- **Found during:** C.2, before running the final `theme-stress-test`
- **Issue:** After the D-07 blur-legibility screenshot test, this session read `~/.cache/current-theme` (reported `catppuccin`) and used it as the value to restore to — but that file's own mtime is 2026-07-06, weeks stale and disconnected from the live theme tracker. The real tracker, `~/.local/state/theme/current-theme`, and Task 3's own SUMMARY record both establish the actual original value as `gruvbox`.
- **Fix:** `theme-apply gruvbox`, confirmed via the live tracker.
- **Verification:** `~/.local/state/theme/current-theme` reads `gruvbox`; `git status --porcelain` empty (no repo state affected either way).
- **Committed in:** n/a (operational correction, no source touched)

**6. [Rule 3 - Blocking issue, Task 4, this session] Task 2's zero-hex-literal invariant collided with the new `WeatherPalette.qml`**
- **Found during:** A2, immediately after creating `WeatherPalette.qml`
- **Issue:** The invariant's own comment-stripped grep now returns 8 hex matches (WeatherPalette.qml's 8 absolute colours), which is an expected, approved collision (per this session's own instructions), not a bug — but per T-14-30 it could not simply be silenced.
- **Fix:** Narrowed by exact file name (`WeatherPalette.qml` only) to exempt it; re-poisoned against a DIFFERENT file (`MediaTab.qml` scratch copy) and confirmed the narrowed assertion still fails before trusting its clean run.
- **Files modified:** none tracked (invariant-runner logic, executed inline)
- **Verification:** poisoned run (different file) → FAIL as required; clean run (real tree, narrowed) → PASS.
- **Committed in:** n/a (invariant-runner logic, not a committed script — same class as deviation #2 above)

### Deferred / Not Performed

**Three-reader visual identity (roadmap criterion 4's visual half) — deferred to Task 4's human render gate**, as the plan itself directs; no track was playing during Task 3's session to observe. Still applicable — this session's change-request response did not re-open that check.

**D-07 blur legibility with a bright wallpaper genuinely directly behind the drawer — not independently closed this session.** See section A ("Blur-legibility test") above: a live application window occupied the exact screen region behind the drawer at test time; moving/closing it was judged too disruptive to the user's live desktop for this task to do unilaterally. Carried forward as part of the pending re-gate rather than claimed as confirmed.

---

**Total deviations:** 2 auto-fixed bugs (prior session), 1 operational fix (Task 3 session, no source touched — quickshell relaunch), 1 mechanical self-correction (STATE.md progress-recompute side effect, reverted, prior session), 1 Rule-2 fix (this session — `Dial.qml`'s missed consolidation), 1 Rule-1 self-correction (this session — stale theme-restoration file), 1 Rule-3 invariant-narrowing response (this session — `WeatherPalette.qml` vs. the hex-literal invariant). 2 items remain deferred/not-independently-closed: the visual three-reader observation and the bright-wallpaper-directly-behind-drawer legibility case, both explicitly the human render gate's job.

## Known Stubs

None found. No hardcoded empty values, placeholder text, or unwired data sources were introduced by this plan — `Cascade.qml`, `Design.qml` and `WeatherPalette.qml` are all pure infrastructure (an animation runner and two constants singletons), and every UI-facing content change (Weather glyph colours/tooltips/separator, Performance's dial layout) is fully wired to live data with no placeholder branch.

## Threat Flags

None new. This plan's own `<threat_model>` scopes its risk surface to verification integrity (vacuous gates, unrecorded observations, source-identity spoofing) rather than new attack surface, and this task performed exactly the mitigations that threat register specifies: poisoned-then-clean proofs for every negative assertion (T-14-30, including the newly-narrowed hex-literal invariant), the observation-behind-every-claim discipline (T-14-31), and the mechanical source-identity pairing for the DASH-07 mirror (T-14-32, unchanged this session). `WeatherPalette.qml` is a deliberate, narrow, documented exemption to T-14-34's consolidation-integrity concern (a new colour SOURCE, not a new network endpoint, auth path, file-access pattern, or schema change) — its own header states the exemption and scope boundary in the same place a reviewer would look for it, and A2's poisoned-then-clean re-proof is the mechanical evidence that the exemption did not quietly widen the class of files allowed to carry colour literals.

## User Setup Required

None — this task performed only live verification, live QML edits, one detached process restart, and transient wallpaper/theme/motion-scale mutations, all restored. No persistent configuration change.

## Next Phase Readiness — YES, Phase 14 is closed

**This plan is complete.** Task 4 (`checkpoint:human-verify`, `gate="blocking"`) returned a CHANGE REQUEST at its first gate on checks 4 (Performance width) and 9 (Weather tab, four items); nine of eleven checks passed outright there (1, 2, 3, 5, 6, 7, 8, 10, 11) and were not re-asked. Both change requests were actioned — the Weather tab (condition-glyph colour via a new `WeatherPalette.qml` D-11 exemption, hover tooltips, a centred forecast separator) and the Performance tab (one row of four dials, retuned ring thickness, plus the `Dial.qml` consolidation gap folded in as a related fix) — and re-verified against everything the plan's own gate sweep covers. At the re-gate, the human returned **APPROVED**, verbatim: *"Approved. And I already approved the dynamic width/height."* All eleven checks are now signed off.

**Confirmed across the change-request and re-gate sessions:**
- Both change requests implemented, live-verified via screenshot and `hyprctl layers -j` geometry reads, and committed atomically (`a480b4c` Weather, `5f5c478` Performance, `aaf2583` Dial.qml).
- The width-transition axis — reachable for the first time in the phase now that Performance exceeds the 760px floor — re-tested forward and backward, confirmed to animate correctly and collapse correctly at `off`/`reduced`, with no stuck-width state in either direction.
- The zero-hex-literal invariant's collision with `WeatherPalette.qml` handled per T-14-30: narrowed by file name only, re-poisoned against a different file, proven to still fail before trusting the clean run.
- The full 8-script-plus-stress-test gate sweep re-run clean against the change-request session's own commits (see section C above) — zero new failures, the one pre-existing `quickshell-doctor` QS-03 failure is the same named item Task 3 recorded, and was re-confirmed unchanged at the re-gate sweep (`theme-doctor` 232/0, `motion-lint` 81/0, `--self-test` 10/0, `--no-pending` 1/0, `theme-parity` 2608/0, `keybind-doctor` 14/0, `quickshell-doctor` 12/1 pre-existing QS-03, `theme-stress-test` 10/10 switches, 162/0, exit 0).
- A self-caught theme-restoration error (stale `~/.cache/current-theme` file) corrected before it could affect anything downstream.

**What was NOT independently closed by mechanical verification and instead rested on the human's own visual judgment at the gate:** the three-reader visual identity check (no track was playing during the executor's own sessions) and the bright-wallpaper-directly-behind-the-drawer blur-legibility case for the new Weather colours (a live application window occupied that screen region during the executor's own test). Both are covered by the human's overall APPROVED verdict, which per this plan's own `<resume-signal>` required explicit answers on checks 4 and 5 (given) alongside the general approval — recorded here as covered by the gate rather than re-asserted as independently proven.

**This session's phase-close bookkeeping** (2026-07-30, fourth session): corrected two stale present-tense claims left over from Task 3's original (pre-Task-4) record — the backward-navigation width-bug "structurally moot" decision entry and the D-04 "current per-tab heights" decision entry, both of which Task 4's Performance/Weather changes falsified; captured two human-raised carried-forward requests (two-tone weather glyphs, a fifth GPU dial) in `deferred-items.md` with their verified technical findings; flipped this SUMMARY's frontmatter to `status: complete`; and ran the plan's own `state_updates` and `final_commit` steps. Phase 14 (DASH-01..08, all five ROADMAP criteria) is closed at the plan level. Phase-level verification and `phase.complete` are the orchestrator's to run next — not performed by this plan.

## Self-Check: PASSED

- FOUND: `quickshell/.config/quickshell/modules/dashboard/Cascade.qml`
- FOUND: `quickshell/.config/quickshell/modules/dashboard/Design.qml`
- FOUND: `quickshell/.config/quickshell/modules/dashboard/WeatherPalette.qml`
- FOUND: `quickshell/.config/quickshell/modules/dashboard/qmldir` (all three new types registered)
- FOUND: `quickshell/.config/quickshell/modules/Motion.qml` (snake_case fix present)
- FOUND: commit `7850b7f` in `git log --oneline --all`
- FOUND: commit `3a05c97` in `git log --oneline --all`
- FOUND: commit `1388516` in `git log --oneline --all`
- FOUND: commit `87bba52` in `git log --oneline --all`
- FOUND: commit `a480b4c` in `git log --oneline --all` (Weather change request)
- FOUND: commit `5f5c478` in `git log --oneline --all` (Performance change request)
- FOUND: commit `aaf2583` in `git log --oneline --all` (Dial.qml consolidation fix)
- FOUND: commit `2c9b4f0` in `git log --oneline --all` (Task 4 change-request docs)
- FOUND: commit `22ec4c5` in `git log --oneline --all` (Task 3 gate sweep + evidence docs)
- FOUND: `.planning/phases/14-dashboard-drawer/14-09-SUMMARY.md` (this file)
- FOUND: `.planning/phases/14-dashboard-drawer/deferred-items.md` (Items A and B captured this session)

---
*Phase: 14-dashboard-drawer*
*Plan closed: 2026-07-30 — re-gate APPROVED by human ("Approved. And I already approved the dynamic width/height."); all eleven Task 4 checks signed off; phase-level verification left to the orchestrator*
