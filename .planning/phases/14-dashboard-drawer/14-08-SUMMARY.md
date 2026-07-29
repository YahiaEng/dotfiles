---
phase: 14-dashboard-drawer
plan: 08
subsystem: ui
tags: [quickshell, qml, calendar, systemclock, mpris, material-design-3, caelestia, deep-link]

# Dependency graph
requires:
  - phase: 14-03
    provides: "Dashboard.qml pager, per-tab dynamic sizing convention, DashboardTab.qml stub with mediaBackend/systemResources/mediaTabIndex/performanceTabIndex/tabRequested property contract, widgetState D-41 register"
  - phase: 14-04
    provides: "QuickToggles.qml footer mounted at the tab's base line (three swaync-mirrored chips + motion-scale segmented row)"
  - phase: 14-05
    provides: "MediaBackend.qml shared instance and its derived display fields; MediaTab.qml's Caelestia-look circular-cover-with-dotted-ring art treatment (rounds 3/4) reused here at compact scale"
  - phase: 14-06
    provides: "SystemResources.qml shared instance (including storageFraction/storageUsedBytes/storageTotalBytes/storageState); Dial.qml reusable circular dial; PerformanceTab.qml's per-ring theme-role convention (CPU=primary, Memory=secondary, Storage=tertiary, Battery=error)"
provides:
  - "DashboardTab.qml composed: locale-derived clock/date hero (SystemClock, minute precision) with a tertiary-accented day-of-month number, a display-only six-row calendar month grid with Friday (this locale's weekend day) tertiary-accented and today circled in primary, chevron+wheel navigation, a compact media widget (circular dotted-ring art, title/artist stack, a grown right-anchored prev/play-pause/next transport cluster), and a four-dial CPU/Memory/Storage/Battery resources strip — all above 14-04's quick-toggle footer"
  - "DeepLinkSurface — one reusable inline component (ripple + tap-to-jump via the tabRequested signal) that both the compact media widget and the resources strip instantiate — the mechanical form of the compact-widget-to-its-full-tab convention Phase 15 inherits"
  - "formatCompactUsedTotal() — a caller-side used/total byte-string compactor (drops a repeated unit suffix) that works around Dial.qml's own unconstrained detail-text width when two populated detail lines sit side by side in a narrow mini-dial strip"
affects: [14-09, 15]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Compact-widget-to-its-full-tab deep-link convention (DeepLinkSurface): a rounded MD3 ripple surface wrapping a compact glance widget, emitting the tab's own tabRequested(index) signal with a named index property — never a bare integer — established here for Phase 15's panels to reuse"
    - "Locale-format substring splitting for partial text coloring: rather than hardcoding a date/string format's structure, find a known sub-value (a day number) as a standalone token inside the already-locale-formatted string and split prefix/match/suffix around it, degrading quietly to one color if the token isn't found — used for the hero's day-number accent"
    - "Caller-side text-width workaround for a frozen sibling component: when a shared component (Dial.qml) has no width constraint on a text sub-element and two instances' populated values collide, shorten the STRING passed in from the caller rather than editing the frozen file"
    - "Render-gate-driven fence reversal: when a human's live render-gate instruction directly contradicts a plan's own must_haves/fenced-out list, the render gate is authoritative — implement per instruction, record explicitly as a deviation in the file header, commit message, and SUMMARY, carried forward for the NEXT gate round's explicit re-confirmation before treating it as settled"

key-files:
  created: []
  modified:
    - quickshell/.config/quickshell/modules/dashboard/DashboardTab.qml
    - quickshell/.config/quickshell/modules/dashboard/QuickToggles.qml

key-decisions:
  - "Design-constants consolidation verdict: consolidation-deferred-to-14-09 (Task 1). Read all four sibling consolidation notes (14-03 through 14-07); no shared mechanism exists — a QML id is lexically scoped to its declaring file, and every tab type here is a separate registered component instantiated inside dashboardWindow's object tree, not textually nested inside it. This file declares its own local constants sourced from 14-UI-SPEC.md, same precedent as every sibling tab. No sibling file touched to build a shared mechanism."
  - "D-04/D-05 frame deviation carried forward, not re-litigated: this tab keeps implicitWidth/implicitHeight (per-tab dynamic sizing, superseded D-02/D-04's original fixed 850x860 frame at 14-03's own render gate) rather than omitting them per this plan's own now-stale Task-1 instruction. Renders at 760x826 (unchanged across all three render-gate rounds)."
  - "Render-gate round 1 (BLOCKED, not approved): four concrete fixes requested — calendar side-margin waste, media-card art look, media-card transport/layout, quick-toggle footer affordance."
  - "Render-gate round 2 (commits 4ef00d0, e1c63d7 — APPROVED, including item 3's scope reversal): (1) calendar per-cell width now derives from the card's own real width / 7 instead of a fixed cell size with large side margins; (2) compact media art redrawn as a genuine circle with a static dashed ring + MultiEffect alpha-mask crop, reusing MediaTab.qml's own round-3/4 treatment at compact scale; (3) previousTrack()/nextTrack() added alongside play/pause, grouped as one cluster — a DELIBERATE REVERSAL of this plan's own must_haves ('play/pause control and nothing else') and its explicit fence against adding transport verbs, on the human's direct instruction; (4) QuickToggles.qml (outside this plan's files_modified, a cross-file deviation) got 'DND' spelled out to 'Do Not Disturb' plus hover ToolTips on every chip and motion-scale segment explaining what a press does."
  - "Render-gate round 3 (commit 6ff2c21 — APPROVED, no further fixes): (1) Friday (this locale's own weekend day per the human's direct statement, matched on Date.getDay()===5, never a hardcoded Saturday/Sunday assumption) takes Colours.tertiary in both the weekday header and every day-number cell — today's primary highlight still wins when the two coincide; (2) the hero's date line splits into three text runs (prefix/day-number/suffix) so only the day-of-month number takes the tertiary accent, found by searching the locale-formatted string for the day number as a standalone digit token rather than assuming a fixed format position; (3) the transport cluster moved back to a right-edge anchor (round 2 moved it to hug the text stack; this round's feedback asked for the opposite direction) with every button grown (prev/next 32->40px, play/pause 40->56px, gap spacingXs->spacingMd); (4) a Storage mini-dial joined CPU/Memory/Battery — a DELIBERATE REVERSAL of this plan's own explicit fence ('storage and network stay Performance-only... paying glance-rent for two more is exactly what D-39 rejected'), reusing SystemResources' existing storage fields and PerformanceTab.qml's own icon/tertiary-accent convention verbatim, on the human's direct instruction."
  - "Bug caught and fixed mid-round-3 (Rule 1, auto-fixed): adding Storage's populated detail line collided/overlapped with Memory's own populated detail line, because Dial.qml's detailLine Text (frozen sibling file, not this plan's to edit) publishes no width constraint of its own and just centers at natural content width. Fixed from the caller side with a new formatCompactUsedTotal() helper (drops the repeated unit suffix, e.g. '4.6/31.3 GiB' instead of '4.6 GiB / 31.3 GiB') plus a further dialSpacing increase — verified via a live screenshot crop before and after."
  - "Three round-1 open judgments were asked at every one of the three render-gate rounds and were NEVER explicitly answered by the human: (a) fit/width at the live 2560x1440 monitor (D-02 assumed 2160x1440); (b) the calendar's month-reset-on-tab-switch/summon acceptability (a locked lifecycle consequence, not a bug, per D-14/14-03's lazy Loader); (c) the compact media widget's and resources strip's deep-link discoverability (no visual hint either card is tappable beyond the cursor). These are recorded here as OPEN, deferred to 14-09/Phase 15 — NOT approved, NOT resolved, and must not be read as settled by this plan's overall approval."

patterns-established:
  - "DeepLinkSurface (compact-widget-to-its-full-tab convention): one reusable inline component, instantiated twice in this file, that Phase 15's panels are the expand targets of — the mechanical form D-39/D-40 named as a phase-owned convention."
  - "Render-gate-driven fence reversal protocol: a human's direct, explicit render-gate instruction can override a plan's own frozen must_haves/fenced-out list; the executor implements it, documents the reversal in the file header (with the exact plan wording it contradicts), the commit message, and the SUMMARY, and treats it as provisional until the NEXT round's explicit re-confirmation (not silently absorbed as if the plan always said this)."
  - "Locale-format substring splitting for partial-run text coloring — reusable anywhere a single locale-formatted string needs one embedded value styled differently without assuming the format's own structure."

requirements-completed: [DASH-03]

coverage:
  - id: D1
    description: "Dashboard tab composed as D-38's identity-first single column: clock/date hero, display-only calendar month grid, compact media widget, resources strip, above 14-04's quick-toggle footer — DASH-03's four named things all present at a glance"
    requirement: "DASH-03"
    verification:
      - kind: manual_procedural
        ref: "Task 1/2 acceptance checks (motion-lint CHECK A/B, qmllint, git diff --numstat against sibling-owned files, hyprctl -j layers frame reading) plus the Task 3 blocking human render gate across three rounds, final verdict 2026-07-30: round 3 APPROVED with no further fixes"
        status: pass
    human_judgment: true
    rationale: "Visual composition, color life, spacing, and control layout are aesthetic judgments requiring human sign-off per ROADMAP's standing constraint — performed across three render-gate rounds, the last explicitly approved."
  - id: D2
    description: "Two scope-fence reversals landed on direct human render-gate instruction: compact media transport grows beyond play/pause (previousTrack/nextTrack), and the resources strip grows beyond CPU/Memory/Battery (Storage mini-dial) — both contradicting this plan's own frozen must_haves/fenced-out text"
    verification: []
    human_judgment: true
    rationale: "These are plan-scope reversals, not code-correctness questions — the human's own direct instruction is the only authority that can settle whether a frozen must_have should be overridden; recorded as approved through round 3's final verdict but flagged here for visibility since they are NOT what the original plan specified."
  - id: D3
    description: "Three round-1 open judgments (2560x1440 fit/width, month-reset-on-rebuild acceptability, deep-link discoverability) remain unanswered across all three render-gate rounds"
    verification: []
    human_judgment: true
    rationale: "These require an explicit human answer that was never given despite being re-listed at every gate; deferred to 14-09/Phase 15 rather than assumed resolved by the overall plan approval — a fail-safe, not a pass."

# Metrics
duration: multi-session (3 render-gate rounds, ~46 min of task/fix commits across the day)
completed: 2026-07-30
status: complete
---

# Phase 14 Plan 08: Dashboard Tab Composition Summary

**Composed the Dashboard tab as D-38's identity-first single column — a SystemClock-driven hero with a tertiary-accented day number, a full-width six-row calendar with Friday tertiary-accented, a compact media widget with Caelestia-look circular dotted-ring art and a grown prev/play-pause/next transport cluster, and a four-dial CPU/Memory/Storage/Battery resources strip — closing three render-gate rounds, two of which reversed the plan's own frozen scope fences on direct human instruction.**

## Performance

- **Duration:** multi-session, three render-gate rounds across one day (~46 min of commits, first task commit to final approval)
- **Started:** 2026-07-30T00:54:59+03:00 (commit `7321eb8`)
- **Completed:** 2026-07-30T01:41:05+03:00 (commit `6ff2c21`; human APPROVED round 3 with no further fixes)
- **Tasks:** 2 declared tasks (Task 1 hero+calendar, Task 2 compact media+resources strip) plus Task 3's blocking render gate, re-entered twice on feedback (rounds 2 and 3)
- **Files modified:** 2 (`DashboardTab.qml` — this plan's one declared file; `QuickToggles.qml` — a recorded cross-file deviation)

## Accomplishments

- **Column + hero + calendar (7321eb8):** the tab's placeholder column replaced with D-38's top half — a `SystemClock` (minute precision, `enabled: root.visible`) hero rendering locale-derived time/date formats, and a display-only six-row (42-cell) calendar month grid with locale-derived weekday order and today circled in primary, navigated by chevrons and a wheel-notch accumulator, installing no key handler so Left/Right still cycle tabs.
- **Compact media + resources strip + deep-link convention (8747e6e):** `DeepLinkSurface` (one reusable ripple-plus-tap-to-jump inline component) instantiated twice — the compact media widget (art slot, title/artist stack, play/pause reading `mediaBackend`'s truth-driven `playing` predicate) and a three-dial CPU/Memory/Battery strip reading the shared `systemResources` instance and 14-06's `Dial` type at a smaller diameter.
- **Render-gate round 2 (4ef00d0, e1c63d7):** calendar grid widened to fill the card's real width; media art redrawn as a genuine circle with a static dashed ring + `MultiEffect` alpha-mask crop (MediaTab.qml's own round-3/4 treatment, scaled down); `previousTrack()`/`nextTrack()` added alongside play/pause (a scope-fence reversal); `QuickToggles.qml`'s chip labels and motion-scale segments got hover tooltips plus "DND" spelled out to "Do Not Disturb" (a cross-file deviation).
- **Render-gate round 3 (6ff2c21):** Friday (this locale's weekend day) and the hero's day-of-month number both took the tertiary accent; the transport cluster moved to a right-edge anchor and grew (40/56px buttons, wider gaps); a Storage mini-dial joined the resources strip (a second scope-fence reversal), reusing `SystemResources`' existing fields and `PerformanceTab.qml`'s own per-ring color convention verbatim; a live-caught detail-text collision (Storage's new detail line overlapping Memory's) was fixed with a caller-side `formatCompactUsedTotal()` helper.

## Task Commits

Each task/round was committed atomically:

1. **Task 1: Column, clock/date hero, calendar month grid** - `7321eb8` (feat)
2. **Task 2: Compact media widget, resources strip, deep-link convention** - `8747e6e` (feat)
3. **Render-gate round 2, main fixes** - `4ef00d0` (fix)
4. **Render-gate round 2, QuickToggles deviation** - `e1c63d7` (fix)
5. **Render-gate round 3, all four punch-list items** - `6ff2c21` (fix)

**Plan metadata:** this commit (docs: complete plan)

## Files Created/Modified

- `quickshell/.config/quickshell/modules/dashboard/DashboardTab.qml` - the composed Dashboard tab: hero, calendar, compact media widget, resources strip, `DeepLinkSurface`
- `quickshell/.config/quickshell/modules/dashboard/QuickToggles.qml` - round-2 cross-file deviation: spelled-out "Do Not Disturb" label and hover `ToolTip` affordance on every chip and motion-scale segment

## Decisions Made

See `key-decisions` in frontmatter for the full render-gate history across all three rounds. Summary:

- Design-constants consolidation: deferred to 14-09 (no shared mechanism exists across sibling tab files; this file follows the same local-constants precedent every sibling already established).
- D-04/D-05 frame instructions in this plan's own Task 1 text are stale (superseded by 14-03's own round-2 render gate); this tab keeps `implicitWidth`/`implicitHeight` for the per-tab dynamic sizing convention every sibling tab already uses.
- Two scope-fence reversals (transport next/prev; Storage mini-dial) were made on the human's direct render-gate instruction, contradicting this plan's own frozen must_haves/fenced-out text — recorded, not silently absorbed.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Storage/Memory detail-text collision in the resources strip**
- **Found during:** Render-gate round 3, after adding the Storage mini-dial
- **Issue:** `Dial.qml`'s `detailLine` `Text` (a frozen sibling file, not this plan's to edit) has no width constraint of its own — it centers at natural content width under the dial's diameter. Storage's newly-populated detail text visually collided/overlapped with Memory's own populated detail text at this strip's small dial pitch.
- **Fix:** Added `formatCompactUsedTotal()` on `resourcesStrip` (caller-side, in `DashboardTab.qml`) that drops the repeated unit suffix when used/total share one unit (e.g. "4.6/31.3 GiB" instead of "4.6 GiB / 31.3 GiB"), plus widened `dialSpacing` further.
- **Files modified:** `quickshell/.config/quickshell/modules/dashboard/DashboardTab.qml`
- **Verification:** Live screenshot crop before (visible overlap: "31.3 GiB82.6 GiB") and after (clean gap) fixing.
- **Committed in:** `6ff2c21` (round 3 commit)

### Human-directed Scope Reversals (not Rule 1-4 deviations — direct render-gate instruction)

**2. [Render-gate override] previousTrack()/nextTrack() added to the compact media widget**
- **Found during:** Render-gate round 2
- **Plan text contradicted:** must_haves — "shows art, a title/artist stack and a play/pause control and nothing else"; fenced-out — "any transport verb on the compact widget beyond play/pause... adding them here deletes the reason the deep-link exists"
- **Instruction:** "The play/pause button ... looks awkward ... add the next/prev buttons as well" (round 2), reconfirmed via round 3 ("stretch them")
- **Outcome:** Approved through round 2 and round 3 with no rollback request; this is now a permanent widening of the compact widget's scope.

**3. [Render-gate override] Storage mini-dial added to the resources strip**
- **Found during:** Render-gate round 3
- **Plan text contradicted:** fenced-out — "storage and network stay Performance-only (D-39 keeps them Performance-only — the strip carries three glance-timescale metrics and paying glance-rent for two more is exactly what D-39 rejected)"
- **Instruction:** "The resources card looks clustered, space the dials more and add the storage as a dial as well"
- **Outcome:** Approved with no further fixes in round 3's final verdict. Network was NOT added — the human asked only for storage.

**4. [Cross-file deviation, render-gate driven] QuickToggles.qml label/tooltip affordance**
- **Found during:** Render-gate round 2
- **Files this plan may not touch (per its own ownership fence):** `QuickToggles.qml` (14-04's file)
- **Instruction:** the footer's icon+label chips and motion-scale segments needed clearer function affordance for "a fresh user"
- **Fix:** "DND" spelled out to "Do Not Disturb" in the visible label; hover `ToolTip` (QtQuick.Controls, same module `MediaTab.qml` already uses for its `Slider`s) added to every chip and motion-scale segment stating what a press does.
- **Files modified:** `quickshell/.config/quickshell/modules/dashboard/QuickToggles.qml`
- **Verification:** qmllint clean, motion-lint CHECK A/B pass, live screenshot confirms the spelled-out label.
- **Committed in:** `e1c63d7`

---

**Total deviations:** 1 auto-fixed bug (Rule 1), 2 human-directed scope-fence reversals, 1 cross-file deviation.
**Impact on plan:** The auto-fix is a pure correctness fix (no scope change). The two scope reversals meaningfully widen this plan's original DASH-03 scope beyond what was planned, on explicit, repeated human instruction across two separate render-gate rounds — recorded prominently rather than absorbed quietly. The cross-file deviation is additive-only (a new import, new hover affordance) with no change to `QuickToggles.qml`'s existing layout, sizing, or D-22 pending model.

## Issues Encountered

- **Config-reload resets `dashboardLoader.active`:** every quickshell hot-reload (triggered automatically on file save) destroys and rebuilds the whole object tree, closing the drawer if it was open. Each render-gate verification pass had to re-summon the drawer (`hyprctl dispatch 'hl.dsp.global("quickshell:dashboard")'`) after every edit batch before screenshotting — not a bug, just a verification-workflow note for future rounds.
- **`hyprctl dispatch` syntax on this Lua-config-managed Hyprland instance:** the plan's own `<verify>` blocks use the classic `hyprctl dispatch global quickshell:dashboard` form, which fails with a Lua parse error on this machine's `hyprlang`-Lua-cutover config (`hypr/.config/hypr/config/keybinds.lua`'s own header comment documents this: "on a Lua-config-managed instance, `hyprctl dispatch` takes a Lua expression... not the classic `dispatcher,args` string"). The working form used throughout this plan's verification was `hyprctl dispatch 'hl.dsp.global("quickshell:dashboard")'`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `DeepLinkSurface` and the `tabRequested(index)` signal convention are ready for Phase 15's panels to reuse as their own compact-widget-to-full-tab expand target.
- **Three round-1 open judgments were never explicitly answered across all three render-gate rounds** and must be carried forward, not assumed settled:
  1. Fit/width at the live 2560x1440 monitor (D-02 assumed 2160x1440; the drawer renders at 760x826 for this tab, roughly a third of the screen rather than D-02's ~40%).
  2. The calendar's month-reset-on-tab-switch/summon acceptability (a locked lifecycle consequence of D-14/14-03's lazy Loader, not a bug — but never explicitly signed off as acceptable).
  3. The compact media widget's and resources strip's deep-link discoverability (no visual hint either card is tappable beyond the cursor changing).
- These three should be explicitly raised and resolved at 14-09's gate sweep (which also owns the design-constants consolidation this plan deferred) before Phase 15 builds further on the deep-link convention.
