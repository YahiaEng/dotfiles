---
phase: 20-indicators-power-menu
plan: 03
subsystem: ui
tags: [qml, quickshell, hyprland, design-tokens, colour-roles, layer-rules, matugen]

# Dependency graph
requires:
  - phase: 19-notification-server-centre
    provides: "Toast.qml transient-toast frame (Phase 19 Plan 01) that the OSD reuses unchanged"
provides:
  - "Design.qml: osdWidth (380), osdHideDelayMs (1200), osdRecencyWindowMs (1500) — OSD half tokens"
  - "Design.qml: sessionDialogWidth (488), sessionTileWidth (136), sessionTileHeight (104), sessionTileRadius (16), sessionTileIconSize (32), sessionScrimOpacity (0.55) — power-menu half tokens"
  - "BarRoles.qml: onWarn (= Colours.onTertiary), completing the warn/onWarn pair"
  - "windowrules.lua: quickshell-osd (animation=slide, blur=true, ignore_alpha=0.2) and quickshell-session (animation=slide) layer namespaces, declared after the family regex"
affects: [20-04, 20-05, 20-06, 20-07, 20-08]

actuals:
  tokens: 1988
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Shared-contention-removal plan: declare the full cross-cutting token/role/namespace surface in one commit before either dependent half starts building, keeping the halves file-disjoint (same move as Phase 19 Plan 01)."

key-files:
  created: []
  modified:
    - quickshell/.config/quickshell/modules/dashboard/Design.qml
    - quickshell/.config/quickshell/modules/bar/BarRoles.qml
    - hypr/.config/hypr/config/windowrules.lua

key-decisions:
  - "osdWidth (380) deliberately narrower than notifSurfaceWidth (430) — D-20-10."
  - "osdHideDelayMs (1200) kept independent of notifToastDurationMs (2000) and set longer than SwayOSD's own 1000ms because interactive:true drag must complete inside the dwell window — D-20-06."
  - "sessionTileRadius (16) matches QuickToggles.chipRadius, deliberately NOT popoutCornerRadius (20) — D-20-21."
  - "onWarn completes the existing warn pair (mirrors danger/onDanger) rather than opening a new colour family."
  - "quickshell-osd gets its OWN ignore_alpha=0.2 override — it does NOT inherit quickshell-notif-toast's override despite reusing Toast.qml's frame, because a brand-new namespace only inherits the family's 0.5 floor, and Toast.qml's fill (BarRoles.notifSurface, 0.38) sits below that floor — D-20-34."
  - "quickshell-session gets no ignore_alpha override; its 0.78/0.55 fill/scrim already clear the family's 0.5 floor by prediction, verified later at plan 20-08 Gate B rather than assumed here."
  - "All new layer rules declared in the file's LAST-declared block, strictly after the ^quickshell-.* family regex rows (lines 396/445) — a namespace rule contradicting the family regex loses if declared before it on this build."

patterns-established:
  - "OSD/session token groups placed adjacent to their deliberate siblings in Design.qml (notifSurfaceWidth/notifToastDurationMs), each carrying a provenance comment citing 20-UI-SPEC.md and its decision id — never appended at file end."

requirements-completed: [QOSD-01, QOSD-04, QPOWER-01]

coverage:
  - id: D1
    description: "Nine new Design.qml tokens declared (osdWidth, osdHideDelayMs, osdRecencyWindowMs, sessionDialogWidth, sessionTileWidth, sessionTileHeight, sessionTileRadius, sessionTileIconSize, sessionScrimOpacity), each with a provenance comment, none of them lineHeight, all grid-conformant integers divisible by 4"
    requirement: QOSD-01
    verification:
      - kind: other
        ref: "grep -qF token literals in Design.qml + colour-lint exit 0 (task 1 automated verify)"
        status: pass
    human_judgment: false
  - id: D2
    description: "BarRoles.onWarn added, bound to Colours.onTertiary, adjacent to the existing warn declaration, no other role added"
    requirement: QOSD-04
    verification:
      - kind: other
        ref: "grep -qE onWarn declaration in BarRoles.qml + numstat diff (6 added lines) + colour-lint exit 0 (task 2 automated verify)"
        status: pass
    human_judgment: false
  - id: D3
    description: "quickshell-osd and quickshell-session layer-rule rows registered in windowrules.lua, declared after the family regex, with quickshell-osd's ignore_alpha=0.2 override sized against Toast.qml's 0.38 fill alpha"
    requirement: QPOWER-01
    verification:
      - kind: other
        ref: "grep-based row/ordering assertions (task 3 automated verify) + live nested hypr-lua-harness boot (start/stop), confirming the edited windowrules.lua parses without error"
        status: pass
    human_judgment: false

duration: ~5min
completed: 2026-08-15
status: complete
---

# Phase 20 Plan 03: Shared Token, Colour-Role and Layer-Namespace Surface Summary

**Declared nine Design.qml tokens, one BarRoles.qml colour role (onWarn), and the quickshell-osd/quickshell-session layer-rule rows — including the ignore_alpha=0.2 override the OSD's reused Toast.qml fill (alpha 0.38) requires below the family's 0.5 floor — in three atomic commits, unblocking both the OSD half (20-04/20-05) and the power-menu half (20-06/20-07) to build in parallel against a shared, already-declared surface.**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-08-15T16:17:22Z
- **Completed:** 2026-08-15T16:20:48Z
- **Tasks:** 3/3 completed
- **Files modified:** 3

## Accomplishments
- Added all nine OSD/session `Design.qml` tokens with provenance comments citing `20-UI-SPEC.md` and their decision IDs, placed adjacent to their deliberate siblings (`notifSurfaceWidth`/`notifToastDurationMs`) rather than appended at file end; deliberately did NOT promote `lineHeightTight`/`lineHeightNormal` per the UI-SPEC's own Step-9.5 correction.
- Completed the `warn`/`onWarn` colour-role pair in `BarRoles.qml`, mirroring the existing `danger`/`onDanger` pairing — no new colour family opened.
- Registered `quickshell-osd` (animation/blur/ignore_alpha=0.2) and `quickshell-session` (animation) layer namespaces in `windowrules.lua`'s last-declared block, strictly after the `^quickshell-.*` family regex rows, with the OSD's alpha override sized against the real 0.38 fill it will carry.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add the nine new Design.qml tokens** - `61e330a` (feat)
2. **Task 2: Add BarRoles.onWarn** - `d3bc732` (feat)
3. **Task 3: Register quickshell-osd and quickshell-session layer rules** - `f56aad7` (feat)

**Plan metadata:** committed separately after this summary.

## Files Created/Modified
- `quickshell/.config/quickshell/modules/dashboard/Design.qml` - nine new tokens (OSD group + session group)
- `quickshell/.config/quickshell/modules/bar/BarRoles.qml` - one new colour role (`onWarn`)
- `hypr/.config/hypr/config/windowrules.lua` - four new layer-rule rows across two new namespaces

## Decisions Made
See `key-decisions` in frontmatter — all decisions were pre-resolved by the plan/UI-SPEC (D-20-06, D-20-08, D-20-10, D-20-21, D-20-33, D-20-34); no new decisions were made during execution.

## Deviations from Plan

None - plan executed exactly as written.

One verification note: the plan's literal Task 3 automated verify command (`hypr-lua-harness 2>&1 | tail -5` with no subcommand) only prints usage text and does not, by itself, exercise the harness's parse-checking `start` path — its exit status is masked by the trailing `tail` in the pipe. To get real signal beyond the grep/ordering assertions (which did run and pass as written), this execution additionally ran `hypr-lua-harness start` against the live edited `hyprland.lua`/`windowrules.lua` tree, confirmed the nested Hyprland instance booted successfully (no Lua parse error), then `hypr-lua-harness stop`. This is additional verification, not a plan change — no deviation rule applies since nothing was fixed or added to the codebase.

## Issues Encountered
None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Both halves of Phase 20 can now proceed file-disjoint: plans 20-04/20-05 (OSD) read `Design.osdWidth`/`osdHideDelayMs`/`osdRecencyWindowMs` and the `quickshell-osd` namespace by name; plans 20-06/20-07 (power menu) read `Design.sessionDialogWidth`/`sessionTileWidth`/`sessionTileHeight`/`sessionTileRadius`/`sessionTileIconSize`/`sessionScrimOpacity`, `BarRoles.onWarn`, and the `quickshell-session` namespace by name. No later plan in this phase needs to reopen `Design.qml`, `BarRoles.qml`, or `windowrules.lua` for a declaration. The `quickshell-session` no-override prediction (0.78/0.55 both above the family's 0.5 floor) remains open for confirmation at plan 20-08's Gate B criterion 1.

## Self-Check: PASSED

All three modified files exist on disk; all three task commit hashes (`61e330a`, `d3bc732`, `f56aad7`) are present in git history.

---
*Phase: 20-indicators-power-menu*
*Completed: 2026-08-15*
