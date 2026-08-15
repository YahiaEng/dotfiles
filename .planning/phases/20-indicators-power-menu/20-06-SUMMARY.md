---
phase: 20-indicators-power-menu
plan: 06
subsystem: ui
tags: [quickshell, qml, hyprland, power-menu, layer-shell, wayland]

requires:
  - phase: 20-01
    provides: "Phase 20 groundwork/probe infrastructure"
  - phase: 20-03
    provides: "quickshell-session namespace declaration and the original (grid) power-menu tracer this plan rebuilds"
provides:
  - "PowerMenu.qml rebuilt from a rejected 3x2 grid dialog to the locked radial-ring design (D-20-21 revised)"
  - "Two live-verification bugs fixed: click-outside dismissal, and the post-action flash/unmap-ordering defect"
  - "quickshell-session-specific ignore_alpha layer rule (Route B), applied live"
  - "All three power-menu entry points (keybind, walker menu, bar glyph) repointed off wleave.sh to the in-process QML surface"
  - "LEDGER-02 settled: Logout wrapped without the D-29 teardown measurement, recorded honestly"
affects: [20-07, 20-08]

actuals:
  tokens: 13060
  tasks: 3
  commits: 4

tech-stack:
  added: []
  patterns:
    - "PopoutController wayfinding signal extended to a third seam (powerMenuRequested) so a bar-capsule cell can reach shell.qml's root without an ambient parent-chain lookup — the same pattern panelRequested/dashboardRequested already established"
    - "closeAndRun(): unmap (visible = false) before launching the action Process, tear down the LazyLoader item last — the general shape for any future summon-and-act surface on this shell"
    - "Route B ignore_alpha override for a namespace carrying two alpha values that straddle the family floor, mirroring the notification family's own precedent"

key-files:
  created:
    - .planning/phases/20-indicators-power-menu/20-LEDGER-02-RECORD.md
    - hypr/.config/hypr/scripts/tests/quickshell-fixtures/compliant-bar-qml-root/session/PowerMenu.qml
  modified:
    - quickshell/.config/quickshell/modules/session/PowerMenu.qml
    - hypr/.config/hypr/config/windowrules.lua
    - quickshell/.config/quickshell/modules/bar/ClockActionsCapsule.qml
    - quickshell/.config/quickshell/modules/bar/PopoutController.qml
    - quickshell/.config/quickshell/modules/Bar.qml
    - quickshell/.config/quickshell/shell.qml
    - elephant/.config/elephant/menus/main.toml
    - hypr/.config/hypr/scripts/quickshell-doctor

key-decisions:
  - "Rebuilt PowerMenu.qml to the user-locked radial ring per D-20-21 revised / f3406d7, not a reinterpretation — six pills at 60 degree increments, severity-tinted via BarRoles, rotation-based (wrapping) focus navigation"
  - "Bug 1 fix: explicit MouseArea on the scrim for click-outside dismissal, since WlrKeyboardFocus.Exclusive + HyprlandFocusGrab never sees a same-window click as a focus change"
  - "Bug 2 fix: closeAndRun() sets visible = false before starting the action Process, for all six actions, and destroys the LazyLoader item last"
  - "Extended PopoutController's wayfinding-signal pattern to a third seam (powerMenuRequested) rather than inventing a new mechanism, even though this touched Bar.qml and PopoutController.qml, neither listed in the plan's files_modified"
  - "Walker menu dispatches the identical GlobalShortcut via `hyprctl dispatch 'hl.dsp.global(\"quickshell:power-menu\")'` (the Lua-expression form this Lua-config-managed hyprctl requires), verified live against quickshell:probe before landing in main.toml"
  - "LEDGER-02 recorded as wrapped-without-measurement per D-20-37/D-20-38, with the permitted summary phrasing written into the record itself"

requirements-completed: [QPOWER-01, QPOWER-02, QPOWER-04, LEDGER-02]

coverage:
  - id: D1
    description: "PowerMenu.qml rewritten to the radial ring design (six pills, centre label, severity colours, rotation focus, no retired grid tokens)"
    requirement: "QPOWER-01"
    verification:
      - kind: other
        ref: "qmllint quickshell/.config/quickshell/modules/session/PowerMenu.qml (exit 0); grep for sessionDialogWidth/sessionTileWidth/sessionTileHeight/sessionTileRadius returns nothing; colour-lint and motion-lint both exit 0 against this file"
        status: pass
    human_judgment: true
    rationale: "The visual/interaction result (ring geometry, colours, rotation feel, frosted look) requires a human to look at the rendered surface — this was explicitly out of scope for this continuation agent to verify live per its own instructions (no key presses / restarts)."
  - id: D2
    description: "Bug 1 fix: clicking outside the ring dismisses the menu; pills remain clickable"
    requirement: "QPOWER-02"
    verification: []
    human_judgment: true
    rationale: "Requires a live click on the running compositor to confirm the scrim MouseArea actually receives the event and the pill MouseAreas are not swallowed — cannot be proven by static analysis alone."
  - id: D3
    description: "Bug 2 fix: the menu is fully unmapped before its action process starts, for all six actions (not just Lock)"
    requirement: "QPOWER-04"
    verification: []
    human_judgment: true
    rationale: "The original defect was a visible one-frame flash on unlock; confirming it is gone requires a live Lock->unlock cycle (and ideally Suspend/Hibernate resume), which this continuation agent was instructed not to run."
  - id: D4
    description: "quickshell-session ignore_alpha = 0.2 layer rule added and applied live via hyprctl eval"
    requirement: "QPOWER-01"
    verification:
      - kind: other
        ref: "hyprctl eval 'hl.layer_rule({ match = { namespace = \"quickshell-session\" }, ignore_alpha = 0.2 })' -> ok; lua5.4 syntax check on windowrules.lua"
        status: pass
    human_judgment: false
  - id: D5
    description: "All three entry points (keybind, walker menu, bar glyph) repointed off wleave.sh"
    requirement: "QPOWER-01"
    verification:
      - kind: other
        ref: "grep -vE '^\\s*--' keybinds.lua | grep -c wleave.sh -> 0; grep -vE '^\\s*#' main.toml | grep -c wleave.sh -> 0; keybind-doctor exit 0"
        status: pass
    human_judgment: false
  - id: D6
    description: "powerAvailabilityProbe and friends deleted outright; powerCell rendering unchanged"
    requirement: "QPOWER-01"
    verification:
      - kind: other
        ref: "grep for powerScriptPath/powerAvailable/powerAvailabilityProbe in ClockActionsCapsule.qml source lines -> 0 matches; power_settings_new glyph still present"
        status: pass
    human_judgment: false
  - id: D7
    description: "quickshell-session registered in quickshell-doctor's bar-surface registry"
    requirement: "QPOWER-01"
    verification:
      - kind: other
        ref: "hypr/.config/hypr/scripts/quickshell-doctor --self-test -> 55 passed, 0 failed"
        status: pass
    human_judgment: false
  - id: D8
    description: "LEDGER-02 recorded: Logout wrapped without the D-29 measurement, honesty constraints enforced"
    requirement: "LEDGER-02"
    verification:
      - kind: other
        ref: "20-LEDGER-02-RECORD.md's own verify block (grep for 'not taken', both action strings, D-20-37/D-20-38, 'neither confirmed nor falsified', rejection of closure-claim phrasing, no uwsm stop -r in PowerMenu.qml) — all pass"
        status: pass
    human_judgment: false

duration: "~35min (continuation agent — commits span 20:41-20:55 local; extensive context reading preceded the first commit)"
completed: 2026-08-15
status: complete
---

# Phase 20 Plan 06: Power Menu (Task 1 Redesign + Tasks 2-3) Summary

**PowerMenu.qml rebuilt from a live-rejected 3x2 grid dialog to the user-locked radial-ring design (six severity-tinted pills on a 96px ring, rotation-based focus navigation), with two live-verification bugs fixed (click-outside dismissal, post-action flash) and all three power-menu entry points repointed off `wleave.sh`.**

## Performance

- **Duration:** ~35 min (continuation session; commits span 20:41-20:55 local)
- **Tasks:** 3 (plus the design-rejection rebuild, folded into Task 1's own scope)
- **Files modified:** 10 (2 new, 8 modified)
- **Commits:** 4

## Design rejection and rebuild — read this first

**Task 1's original 3x2-grid power-menu design was built, shown to the user live, and
explicitly rejected**, before this continuation agent was spawned. The user's verbatim
rejection: *"It overtakes the entire screen and does not behave like a popup that slightly
dims the screen. I want a floating cards design, circular pills arranged in a circular
motion each one is colored according to the theme with a frosted look."* Presented with
three sketched radial options, the user locked a ring-with-centre-label shape. This is
recorded as **D-20-21 (revised)** in `20-CONTEXT.md` and rendered in full in
`20-UI-SPEC.md`, both rewritten in commit `f3406d7` (a separate, prior spec-revision task,
not part of this plan's own scope) **before** this continuation agent's own work began.

This continuation agent's Task 1 work is therefore **not** "Task 1 as originally planned" —
it is a rebuild against the revised contract, plus two bug fixes the live rejection session
also surfaced. `20-06-PLAN.md`'s own Task 1 `<action>` text (3x2 grid, `sessionDialogWidth`,
`sessionTileWidth`/`Height`/`Radius`, no-wrap navigation) describes the **retired** design
and does not govern what was actually built. The original grid's commit (`b00eb02`) is
superseded by `0a8dd78` in this plan's history — both remain in git history, but only the
ring is live.

## Accomplishments

- `PowerMenu.qml` rewritten: six pure-circle pills at 60° increments (`sessionRingRadius`
  96px), icon-only, individually frosted (`sessionPillFillOpacity` 0.72) and severity-tinted
  via `BarRoles` (Lock/Suspend -> `fillClock`, Log Out/Reboot -> `fillUpdates`,
  Hibernate/Shut Down -> `danger`), with the focused action's name in the ring's centre
  (`sessionCentreLabelWidth` 112px). Arrow-key navigation is now rotation (wrapping), a
  deliberate reversal of the retired grid's no-wrap rule. All six action command strings
  (including D-20-37's Logout wrapper addition) carry over byte-identical.
- **Bug 1 (click-outside dismissal) fixed**: an explicit `MouseArea` on the scrim closes the
  menu deterministically. Root cause: a click on the scrim never changes window focus (same
  window), so `HyprlandFocusGrab`'s `onCleared` — which fires on focus moving to *another*
  window — never saw it, worsened by `WlrKeyboardFocus.Exclusive` guaranteeing no other
  window can ever take focus while the menu is open. `HyprlandFocusGrab` is kept for the
  genuinely-different case of focus moving elsewhere; both routes call the same idempotent
  `requestDismiss()`.
- **Bug 2 (post-action flash) fixed**: `closeAndRun()` sets `powerWindow.visible = false`
  (unmapping the wlr layer surface synchronously) *before* starting the action `Process`, for
  all six actions — Lock merely being the case where the user survives to see the defect;
  Suspend and Hibernate had the identical defect on resume. The `LazyLoader` teardown
  (`requestDismiss()`) runs last, after the process has already launched.
- `quickshell-session` gets its own `ignore_alpha = 0.2` layer rule (Route B), since the ring
  carries two alpha values on one namespace straddling the `^quickshell-.*` family's 0.5
  floor (scrim 0.32 below it, pill fill 0.72 above it) — a single namespace-wide floor cannot
  serve both. Applied live via `hyprctl eval` (never `hyprctl reload`, which silently drops
  layer-rule edits on this config).
- All three entry points now open the identical in-process surface: the keybind (already
  repointed in the original Task 1 commit), the walker menu's Power entry (now dispatches
  `hyprctl dispatch 'hl.dsp.global("quickshell:power-menu")'`), and the bar's `powerCell`
  (now calls `PopoutController.requestPowerMenu()` in-process, via a new third wayfinding
  seam on `PopoutController`/`Bar.qml`). `powerScriptPath`, `powerAvailable`,
  `powerAvailabilityProbe` and `powerLaunchProcess` are all deleted outright, with the
  `powerCell`'s own rendering (glyph, permanent accent tint, tooltip) unchanged.
- LEDGER-02 recorded: the D-29 teardown measurement was **not** taken; Logout is wrapped
  anyway (`cliphist wipe; hyprshutdown --post-cmd 'uwsm stop'`, a genuine addition of the
  wrapper). Satisfies ROADMAP SC-4's outcome, not its letter. D-20-38's resolution is
  recorded as evidence from live systemd unit-topology inspection, not as a measurement.

## Task Commits

1. **Task 1 (rebuild): PowerMenu.qml grid -> radial ring + Bug 1 + Bug 2 fixes** - `0a8dd78` (feat)
2. **Layer rule: quickshell-session ignore_alpha (Route B)** - `345f6bc` (feat)
3. **Task 2: repoint walker menu + bar glyph, delete availability probe** - `11f9f31` (feat)
4. **Task 3: LEDGER-02 record** - `4607647` (docs)

_Superseded, not part of this plan's live surface: `b00eb02` (the original rejected grid
build), `f3406d7` (the prior spec-revision task that rewrote the design contract this plan
implements against — not authored by this continuation agent)._

## Files Created/Modified

- `quickshell/.config/quickshell/modules/session/PowerMenu.qml` - rewritten grid -> radial ring, both bug fixes
- `hypr/.config/hypr/config/windowrules.lua` - `quickshell-session` `ignore_alpha = 0.2` row added, stale comment corrected
- `quickshell/.config/quickshell/modules/bar/ClockActionsCapsule.qml` - deleted the power availability probe; `powerCell.onClicked` now calls `PopoutController.requestPowerMenu()`
- `quickshell/.config/quickshell/modules/bar/PopoutController.qml` - new `powerMenuRequested` signal + `requestPowerMenu()`, third wayfinding seam
- `quickshell/.config/quickshell/modules/Bar.qml` - relays `PopoutController.powerMenuRequested` as a third summon seam
- `quickshell/.config/quickshell/shell.qml` - `Bar { onPowerMenuRequested: root.togglePowerMenu() }`
- `elephant/.config/elephant/menus/main.toml` - walker's Power entry dispatches the GlobalShortcut instead of `wleave.sh`
- `hypr/.config/hypr/scripts/quickshell-doctor` - `quickshell-session` registered in the bar-surface registry
- `hypr/.config/hypr/scripts/tests/quickshell-fixtures/compliant-bar-qml-root/session/PowerMenu.qml` - new self-test fixture for the registry row above
- `.planning/phases/20-indicators-power-menu/20-LEDGER-02-RECORD.md` - new, Task 3's record

## Decisions Made

- Implemented the ring exactly as specified in `20-UI-SPEC.md`/`20-CONTEXT.md` D-20-21
  (revised) — no reinterpretation. Ring order, colour-tier mapping, wrap-on-rotate,
  icon-only pills, and the single centre label all match the contract's ASCII previews.
- Kept the QPOWER-03 warning-chip and Cascade.qml staggered entrance out of scope, per the
  plan's own Task 1 action text ("The QPOWER-03 warning banner and its detectors are plan
  20-07; the cascade entrance is plan 20-07") — the retired grid build also had neither, so
  this is not a new gap introduced by the rewrite.
- Chose a direct scrim `MouseArea` over trying to make `HyprlandFocusGrab` alone work for
  Bug 1, since the root cause (same-window clicks never firing a focus-change signal) is
  structural, not a configuration mistake `HyprlandFocusGrab` could be tuned to catch.
- For Bug 2, ordered `visible = false` -> `Process.startDetached()` -> `requestDismiss()`
  rather than dismissing first, specifically so `actionProcess` (a child of the window being
  torn down) is never referenced after its owning object begins destruction.
- Reused `PopoutController`'s existing wayfinding-signal pattern for the bar-glyph repoint
  rather than inventing a new mechanism — both `PopoutController.qml` and `Bar.qml`'s own
  prior comments explicitly anticipated this exact extension ("a later plan needing a third
  seam has found an 18-05 scope correction").
- Walker's Power entry dispatches the GlobalShortcut via `hyprctl dispatch 'hl.dsp.global(...)'`
  rather than a raw `hyprctl dispatch global,...` string, because this host's Lua-config-managed
  hyprctl requires a Lua expression, not the classic `dispatcher,args` string (an existing,
  independently-recorded finding in `keybinds.lua`'s own comments) — verified live against the
  harmless `quickshell:probe` shortcut before landing the real one in `main.toml`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Bar glyph repoint required editing Bar.qml and PopoutController.qml, neither in the plan's `files_modified`**
- **Found during:** Task 2 (repointing `powerCell.onClicked`)
- **Issue:** `ClockActionsCapsule.qml` is instantiated deep inside `Bar.qml`'s own component
  tree with no declarative path to `shell.qml`'s window root, where `togglePowerMenu()`
  actually lives — a plain `root.togglePowerMenu()` call, as the plan's own comment in
  `shell.qml` implies, is not literally possible from that file (QML id scoping is per-file).
  The task cannot complete without a wayfinding route.
- **Fix:** Extended `PopoutController`'s existing `panelRequested`/`dashboardRequested`
  wayfinding-signal pattern with a third signal, `powerMenuRequested`, relayed through
  `Bar.qml`'s existing `Connections { target: PopoutController }` block and consumed by
  `shell.qml`'s `Bar { onPowerMenuRequested: root.togglePowerMenu() }`.
- **Files modified:** `quickshell/.config/quickshell/modules/bar/PopoutController.qml`,
  `quickshell/.config/quickshell/modules/Bar.qml`, `quickshell/.config/quickshell/shell.qml`
- **Verification:** full shell smoke test clean (`quickshell -p shell.qml`, only the known
  pre-existing portal warning); `colour-lint`/`motion-lint` both exit 0.
- **Committed in:** `11f9f31` (Task 2 commit)

**2. [Rule 3 - Blocking] quickshell-doctor self-test regressed after adding the registry row**
- **Found during:** Task 2 (c) — registering `quickshell-session` in the bar-surface registry
- **Issue:** Adding a new registered row without a matching file in the
  `compliant-bar-qml-root/` self-test fixture tree made the `bar-surface-registry source
  half` self-test go from `missing=0` to `missing=1` (a false failure of a fixture, not a
  real regression).
- **Fix:** Added `hypr/.config/hypr/scripts/tests/quickshell-fixtures/compliant-bar-qml-root/session/PowerMenu.qml`,
  a synthetic minimal stand-in declaring the same direct `WlrLayershell.namespace` literal
  and `exclusiveZone: 0` the real file carries, mirroring `toast/Toast.qml`'s fixture shape
  in the same directory.
- **Files modified:** `hypr/.config/hypr/scripts/tests/quickshell-fixtures/compliant-bar-qml-root/session/PowerMenu.qml` (new)
- **Verification:** `quickshell-doctor --self-test` → 55 passed, 0 failed (was 54 passed, 1 failed before the fixture).
- **Committed in:** `11f9f31` (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (both Rule 3 - blocking issues, both necessary to complete
Task 2; no scope creep beyond what the task required).
**Impact on plan:** Both auto-fixes were structurally required to finish the declared task —
neither is optional polish.

## Issues Encountered

None beyond the deviations above and the pre-planned design rebuild (documented in its own
section — that rebuild was already decided and locked before this continuation agent was
spawned, not an issue this agent discovered and resolved).

## Human Verification Pending

This continuation agent was explicitly instructed not to run live restarts or press keys —
the operator verifies the ring visually. The following items from the (now-superseded)
Task 1 human-check need a **fresh** live pass against the ring, not the retired grid, and
have been recorded as an open `unrun-verify` entry in `.planning/WINDOWS.md`:

1. Ring renders as a floating frosted cluster over a light 0.32 scrim (not the grid's "overtakes the screen" look).
2. `hyprctl layers -j` shows `quickshell-session` at level 3 while open; the frost reads correctly now that the `ignore_alpha = 0.2` override is live.
3. Lock is focused on open with a visible accent ring, no fill-colour change.
4. Right/Down rotate clockwise, Left/Up rotate counter-clockwise, and rotation **wraps** past either end.
5. Clicking outside the ring (on the scrim) dismisses the menu (Bug 1 fix); pills remain clickable.
6. Selecting Lock, unlocking, and confirming the menu does **not** flash on screen afterward (Bug 2 fix) — ideally also checked on Suspend/Hibernate resume, since those share the identical defect class.
7. Mnemonics (`l/e/u/h/r/s`) still fire their action from any focus state, undisplayed.
8. All three entry points (keybind, walker menu, bar glyph) open the one identical surface.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 20-07 can proceed: it owns the QPOWER-03 warning-chip detectors and the Cascade.qml
  staggered entrance, both deliberately out of this plan's scope and both compatible with
  the ring shape already built (the ring's `ring` `Item` and its `Repeater` delegates are
  the natural cascade bands; the warning-chip's own geometry is specified in
  `20-UI-SPEC.md` § "Power Menu — Safety Warning").
- Plan 20-08 (GATE-02 Gate B, unlocking `wleave` retirement) is blocked on the live
  human-verification pass listed above — none of Gate B's criteria have been confirmed live
  against the ring yet, only against the retired grid (which failed criterion 1 outright).
- The `WINDOWS.md` ledger carries one new open entry for this pending live verification.

---
*Phase: 20-indicators-power-menu*
*Completed: 2026-08-15*

## Self-Check: PASSED

All 11 claimed files verified present on disk; all 4 claimed commit hashes (`0a8dd78`,
`345f6bc`, `11f9f31`, `4607647`) verified present in `git log --oneline --all`.
