---
phase: 20-indicators-power-menu
plan: 07
subsystem: ui
tags: [quickshell, qml, hyprland, power-menu, safety-warning, motion, notifications]

requires:
  - phase: 20-05
    provides: "Toast.qml parameterisation (edge/interactive/layerNamespace/dismissDurationMs) and the OSD instance (Osd.qml) this plan's suppression gate extends"
  - phase: 20-06
    provides: "The radial-ring PowerMenu.qml (six severity-tinted pills, centre label, scrim, LazyLoader summon) this plan adds the warning chip and cascade entrance onto"
provides:
  - "PowerMenuBackend.qml: three single-flighted QPOWER-03 detectors (package-manager-busy, active-downloads heuristic, deny-list toplevel count), polled only while the menu is visible"
  - "The QPOWER-03 warning chip on PowerMenu.qml — informational, scoped to Shutdown/Reboot/Hibernate/Logout, warn-only"
  - "PowerMenu.qml's entrance cascade (reuses Cascade.qml, six pills + centre label + optional chip as bands), non-serialised against input readiness (D-20-36)"
  - "OSD suppression while the power menu is open (Toast.qml's new `suppressed` property, Osd.qml's `powerMenuOpen`)"
  - "Opening the power menu dismisses live notification popups (NotifServer.dismissAllPopups(), called once from shell.qml's togglePowerMenu())"
  - "Rule 1 fix: PowerMenu.qml's scrim (and now the warning chip) read Colours.surface through a property-color intermediate instead of the undefined-.r/.g/.b trap"
affects: [20-08, 20-02]

actuals:
  tokens: 9030
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Scope-rooted, non-singleton backend bound to a surface's own `visible` (PowerMenuBackend.qml) — CapsLockBackend.qml/AudioBackend.qml's own precedent, applied to a three-Process single-flighted round instead of one probe/writer"
    - "Toast.qml gains a fourth opt-in parameter (`suppressed`) alongside edge/interactive/layerNamespace/dismissDurationMs — one gate at the frame's own show() entry, consumed by exactly one of its two instances"
    - "All three of a summonable surface's entry points already converge on one shell.qml toggle function — cross-surface side effects on 'open' belong there, not scattered per entry point or reached into from the surface's own file"

key-files:
  created:
    - quickshell/.config/quickshell/modules/session/PowerMenuBackend.qml
  modified:
    - quickshell/.config/quickshell/modules/session/PowerMenu.qml
    - quickshell/.config/quickshell/modules/session/qmldir
    - quickshell/.config/quickshell/modules/toast/Toast.qml
    - quickshell/.config/quickshell/modules/osd/Osd.qml
    - quickshell/.config/quickshell/shell.qml
    - quickshell/.config/quickshell/modules/notifications/NotifServer.qml

key-decisions:
  - "Detector 1 (package-manager-busy) uses one Process with a fixed sh -c literal chaining three pgrep -x checks, rather than three separate Process objects — keeps the single-flight round guard to three Process references total, still a fixed literal command array (no concatenation)"
  - "Deny-list starting contents (Claude's Discretion, 20-CONTEXT.md): [\"steam\", \"gimp\"] — no live reproduction of an unkillable client was available this session; both are widely-known to hold local transactional state and stall/prompt rather than exit cleanly. Documented as a defensible starting point, not a mandatory minimum; empty is equally valid."
  - "Fixed a Rule 1 bug in 20-06's own scrim: Colours.surface.r/g/b read directly off a property-string singleton role resolves undefined and silently renders opaque black (BarRoles.qml's own documented GATE-02 failure mode) — added a property-color intermediate (surfaceColour), mirroring PanelDialog.qml's surfaceBase, and routed the new warning chip's fill through the same property"
  - "OSD suppression gate lives on Toast.qml (a new `suppressed` property, checked first in show()) rather than purely inside Osd.qml, because Toast.qml's internal ids (content, entranceAnim, toastDismissTimer) are scoped to that file and inaccessible from Osd.qml's own document — an override function in Osd.qml could not have reimplemented show()'s logic. Toast.qml was not in files_modified; touched anyway as a Rule 3 blocking necessity (mirrors 20-06's own Bar.qml/PopoutController.qml precedent)."
  - "Notification popup dismissal (D-20-32) and OSD suppression (D-20-31) are both wired through shell.qml's togglePowerMenu() / the Osd instantiation, since all three of the power menu's entry points (GlobalShortcut, walker dispatch, bar glyph) already converge on togglePowerMenu() — one place, not three call sites"
  - "dismissAllPopups() added to NotifServer.qml (not NotifPopupStack.qml, which is view-only and owns no verbs) — the third named instance of the existing `root.popups = []` idiom openCentre()/toggleDnd() already establish"

requirements-completed: [QPOWER-03]

coverage:
  - id: D1
    description: "Three single-flighted QPOWER-03 detectors (package-manager pgrep, downloads heuristic, deny-list toplevel count) polled only while the menu is visible, never overlapping"
    requirement: "QPOWER-03"
    verification:
      - kind: other
        ref: "task 1 automated verify block (exactly one Timer, pgrep/.part-crdownload/hyprctl present, db.lck absent, single-flight .running guard present, no command concatenation); colour-lint and motion-lint both exit 0"
        status: pass
    human_judgment: true
    rationale: "Live behaviour (zero child processes while dismissed, first-open result with no poll delay, clearing within one interval, every pill staying interactive) requires watching real subprocess activity against the running compositor — this executor was instructed not to run live restarts or press keys."
  - id: D2
    description: "The warning chip renders as a standalone frosted chip below the ring, absent entirely when clear, scoped to Shutdown/Reboot/Hibernate/Logout, warn-only (no pill disabled, no confirmation copy, no new danger/onDanger consumer)"
    requirement: "QPOWER-03"
    verification:
      - kind: other
        ref: "task 2 automated verify block (all three copy strings present verbatim, warn/onWarn consumed, danger/onDanger consumer count unchanged at one each, zero enabled:false, zero 'are you sure', panelSurfaceOpacity declared locally not as Design.panelSurfaceOpacity); colour-lint exits 0; qmllint clean"
        status: pass
    human_judgment: true
    rationale: "Visual placement/appearance (chip position under the ring, byte-identical warned-pill appearance, chip appearing/disappearing outright vs. reserving space) requires a human to look at the rendered surface."
  - id: D3
    description: "Entrance cascade reuses Cascade.qml across the six pills + centre label + optional chip, non-serialised against input readiness; OSD suppressed while the menu is open but not by the notification centre; opening the menu dismisses live popups losslessly"
    requirement: "QPOWER-03"
    verification:
      - kind: other
        ref: "task 3 automated verify block (Cascade/staggerOffsetDuration/Motion.motionEnabled present in PowerMenu.qml, suppress/powerMenuOpen present in Osd.qml); colour-lint, motion-lint, quickshell-doctor --self-test all exit 0 (142/283/55 passed respectively); full shell -p smoke test clean (only the three pre-existing ignorable warnings)"
        status: pass
    human_judgment: true
    rationale: "The stagger's visible feel, mid-entrance input registering, OSD non-appearance while the menu is open, and the popup-clears-but-history-keeps behaviour all require live key presses/notification triggers this executor was instructed not to perform."

duration: "~30min (heavy up-front context reading against three prior SUMMARYs/the UI-SPEC/CONTEXT.md; three atomic commits once implementation began)"
completed: 2026-08-15
status: complete
---

# Phase 20 Plan 07: QPOWER-03 Warning Chip, Entrance Cascade, Cross-Surface Behaviours Summary

**PowerMenuBackend.qml's three single-flighted safety detectors feed a standalone warning chip below the power-menu ring; the ring now enters on a token-timed per-pill cascade; opening it suppresses the OSD and clears live notification popups without losing history.**

## Performance

- **Duration:** ~30 min (implementation once commits began spanned 21:43–21:47 local)
- **Tasks:** 3
- **Files modified:** 7 (1 created, 6 modified)

## Accomplishments

- `PowerMenuBackend.qml` (new): three independent boolean detectors — a chained `pgrep -x pacman/paru/yay` package-manager check, a `.part`/`.crdownload` Downloads-directory heuristic, and a `hyprctl -j clients`-driven deny-list toplevel count (seeded `["steam", "gimp"]`, Claude's Discretion) — checked once on open and then on a single low-frequency `Timer` (3000ms, named not literal) whose `running` is bound to `PowerMenu.qml`'s own `visible`. A single-flight guard skips a whole poll tick (never queues it) if any of the previous round's three `Process` objects is still running.
- `PowerMenu.qml`: a standalone frosted warning chip, positioned `Design.spacingLg` below the ring's own outer edge, gated on `warningActive` (any detector firing) — absent entirely when clear, no reserved gap. Consumes `BarRoles.warn`/`onWarn` exclusively; the six pills' existing (20-06) static severity tint via `danger`/`onDanger` is untouched and no NEW consumer of either role was added. All three Copywriting-Contract strings present verbatim, including the dynamic `{n} app(s) may not close cleanly` count.
- Entrance cascade: `Cascade.qml` reused verbatim (no second stagger mechanism), bands are the six ring pills in ring order, then the centre label, then the warning chip as an eighth band when already present at open time. Ring entrance and input readiness are deliberately not serialised (D-20-36) — `ring.forceActiveFocus()` and arming the cascade happen in the same synchronous `Component.onCompleted`, with no key handler or pill `MouseArea` gated on the cascade's own run state.
- Cross-surface behaviours, both wired from shell.qml's `togglePowerMenu()` — the one function all three of the power menu's entry points (GlobalShortcut, walker dispatch, bar glyph) already converge on: (a) `Osd.qml` gets a new `powerMenuOpen` property bound to `powerMenuLoader.active`, threaded into a new `Toast.qml` `suppressed` property checked first inside `show()`; the notification centre deliberately does NOT get the same treatment (documented asymmetry, QNOTIF-10 is a dedup rule that does not apply to an OSD). (b) `NotifServer.dismissAllPopups()` (new, the third instance of the existing `root.popups = []` idiom `openCentre()`/`toggleDnd()` already establish) is called once on the menu's opening transition only.
- **Rule 1 bug fix, found while implementing the warning chip:** 20-06's scrim read `Colours.surface.r/g/b` directly — `Colours.surface` is a `property string` (Colours.qml's own JsonAdapter-backed role), so `.r`/`.g`/`.b` resolve `undefined` and `Qt.rgba(undefined, undefined, undefined, 0.32)` silently renders **opaque black**, exactly the failure mode `BarRoles.qml`'s own header names as the GATE-02 regression this repo already hit once. Fixed via a `property color surfaceColour: Colours.surface` intermediate (mirroring `PanelDialog.qml`'s own `surfaceBase`), used by both the scrim and the new warning chip's fill.

## Task Commits

1. **Task 1: Three single-flighted detectors, polled only while the menu is visible** - `e60ec7d` (feat)
2. **Task 2: The warning chip — informational, scoped to four actions, never blocking** - `4f186bf` (feat)
3. **Task 3: Cascade entrance and the two cross-surface behaviours** - `a633f70` (feat)

## Files Created/Modified

- `quickshell/.config/quickshell/modules/session/PowerMenuBackend.qml` - new, the three detectors + single-flight polling
- `quickshell/.config/quickshell/modules/session/qmldir` - registers `PowerMenuBackend`
- `quickshell/.config/quickshell/modules/session/PowerMenu.qml` - warning chip, `surfaceColour` fix, entrance cascade, `PowerMenuBackend` instance
- `quickshell/.config/quickshell/modules/toast/Toast.qml` - new `suppressed` property, checked in `show()`
- `quickshell/.config/quickshell/modules/osd/Osd.qml` - new `powerMenuOpen` property, threaded to `suppressed`
- `quickshell/.config/quickshell/shell.qml` - `Osd { powerMenuOpen: powerMenuLoader.active }`; `togglePowerMenu()` calls `NotifServer.dismissAllPopups()` on open
- `quickshell/.config/quickshell/modules/notifications/NotifServer.qml` - new `dismissAllPopups()` verb

## Decisions Made

See `key-decisions` in frontmatter — all five recorded there with rationale (single-Process pkg-manager detector, deny-list seed, the scrim bug fix, why the suppression gate lives on Toast.qml, and why both cross-surface effects are wired from shell.qml's `togglePowerMenu()`).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] PowerMenu.qml's scrim (and by extension the new warning chip) read `Colours.surface.r/g/b` directly, silently rendering opaque black instead of a themed dim**
- **Found during:** Task 2 (building the warning chip, which needed the identical `Colours.surface`-blended fill)
- **Issue:** `Colours.surface` is declared `property string` (Colours.qml's alias chain to a JsonAdapter-backed hex-string role); reading `.r`/`.g`/`.b` on it in JS returns `undefined`, and `Qt.rgba(undefined, undefined, undefined, alpha)` silently returns opaque black with no error — `BarRoles.qml`'s own header names this exact failure mode as a GATE-02 regression already hit once in this repo. As written by plan 20-06, the scrim would have rendered as a solid black overlay rather than the light 0.32 themed dim Gate B criterion 1 requires ("only lightly dims the desktop").
- **Fix:** Added `readonly property color surfaceColour: Colours.surface` on `powerWindow` (the `property color`-typed assignment is what triggers QML's string→colour conversion), mirroring `PanelDialog.qml:153`'s own `surfaceBase` indirection. Both the scrim and the new warning chip's fill now read `powerWindow.surfaceColour.r/g/b` instead of `Colours.surface.r/g/b` directly.
- **Files modified:** `quickshell/.config/quickshell/modules/session/PowerMenu.qml`
- **Verification:** `colour-lint` exits 0; `qmllint` clean; visual confirmation is part of the still-open Gate B human-verification pass (see Next Phase Readiness) — this fix could not be visually re-verified live per this executor's own no-live-restart instruction, but the mechanism is now byte-identical to `BarRoles.qml`'s own documented-correct pattern.
- **Committed in:** `4f186bf` (Task 2 commit)

**2. [Rule 3 - Blocking] The OSD suppression gate required touching `Toast.qml`, not listed in the plan's `files_modified`**
- **Found during:** Task 3 ((b), OSD suppression)
- **Issue:** The plan's acceptance criteria require the gate to live functionally in `Osd.qml`'s own `show()` entry point, but `Osd.qml`'s root object (`Toast { id: osd; ... }`) inherits `show()` from `Toast.qml`, whose own logic references ids (`content`, `contentTranslate`, `entranceAnim`, `toastDismissTimer`) that are scoped to `Toast.qml`'s own document and are not visible from `Osd.qml` (QML id scoping is per-file — the same fact `PowerMenu.qml`'s own header already records). An override function declared directly in `Osd.qml` could not have reimplemented `show()`'s logic without those ids.
- **Fix:** Added a new opt-in `suppressed` property to `Toast.qml` (default `false`, so the DND toast instance is byte-unchanged), checked first inside `Toast.qml`'s own `show()`. `Osd.qml` binds `suppressed: osd.powerMenuOpen` — the same parameterisation pattern `edge`/`interactive`/`layerNamespace`/`dismissDurationMs` already establish on this exact file.
- **Files modified:** `quickshell/.config/quickshell/modules/toast/Toast.qml`
- **Verification:** `qmllint` clean on both files; full `quickshell -p shell.qml` smoke test clean (only the three pre-existing ignorable warnings); task 3's automated verify block passes (Osd.qml contains `suppress`/`powerMenuOpen`).
- **Committed in:** `a633f70` (Task 3 commit)

**3. [Rule 3 - Blocking] `NotifPopupStack.qml` (listed in `files_modified`) did not need changing; the dismiss-all verb landed on `NotifServer.qml` instead**
- **Found during:** Task 3 ((c), notification popup dismissal)
- **Issue:** `NotifPopupStack.qml` is a view-only `PanelWindow`/`ListView` with no verbs of its own — it reactively binds to `NotifServer.popups`. `NotifServer.qml` is the sole owner of that data and already establishes the exact `root.popups = []` idiom twice (`openCentre()`, `toggleDnd()` on). Adding a third, named instance of that idiom anywhere but `NotifServer.qml` would create a second dismissal path reaching into the stack's internals — exactly what the plan's own action text forbids ("never a second [dismissal path] reaching into the stack's internals from PowerMenu.qml").
- **Fix:** Added `dismissAllPopups()` to `NotifServer.qml`; `NotifPopupStack.qml` was not touched (it needed no change — its `ListView` already reacts to `NotifServer.popups` reassignment automatically).
- **Files modified:** `quickshell/.config/quickshell/modules/notifications/NotifServer.qml` (not `NotifPopupStack.qml`)
- **Verification:** `qmllint` clean; task 3's verify block does not check either notification file directly (only `PowerMenu.qml`/`Osd.qml`), but `PowerMenu.qml` contains zero `NotifServer` references, satisfying "PowerMenu.qml contains no direct manipulation of the stack's internal model."
- **Committed in:** `a633f70` (Task 3 commit)

---

**Total deviations:** 3 auto-fixed (1 Rule 1 - bug, 2 Rule 3 - blocking).
**Impact on plan:** The scrim fix is a visual-correctness fix directly bearing on this plan's own Gate B criterion 1; both Rule 3 deviations were structurally required to satisfy the plan's own acceptance criteria (a functioning suppression gate, a single dismissal path) rather than merely their literal file list. No scope creep beyond what the tasks required.

## Issues Encountered

None beyond the deviations above.

## Known Stubs

None. The deny-list (`["steam", "gimp"]`) is a deliberately hand-maintained, Claude's-Discretion starting seed per D-20-27 item 3 and 20-CONTEXT.md's own "Claude's Discretion" list — not a stub; an empty list would have been equally valid, and this is documented in-source as expected to grow.

## Human Verification Pending

This executor was explicitly instructed not to run live restarts or press keys. The following need a live pass (recorded as `unrun-verify` in `.planning/WINDOWS.md`):

1. Task 1's human-check: zero detector child processes while the menu is dismissed; a live pacman run shows the warning on first open (no poll delay) and clears within one interval; every pill stays interactive throughout.
2. Task 2's human-check: exactly one warning line inside the standalone chip below the ring (not inside any frame, not painted on the scrim); the chip appears/disappears outright with no reserved gap; a warned Shut Down pill is visually identical to its non-warned appearance and still fires on Enter.
3. Task 3's human-check: the six pills then the centre label arrive on a visible per-band stagger; a key press or click mid-entrance registers immediately; no OSD appears while the menu is open; the OSD resumes normally after dismissal; a live notification's popup clears when the menu opens but remains in history; the notification centre does NOT suppress the OSD.
4. **The scrim colour fix (this plan's own Rule 1 deviation) has not been visually re-confirmed live** — the mechanism now matches `BarRoles.qml`'s own documented-correct pattern, but the actual on-screen scrim tint was not re-screenshotted this session.
5. This carries forward the still-open Gate B human-verification items from 20-06 (ring renders as a floating frosted cluster over a 0.32 scrim; `ignore_alpha = 0.2` frost reads correctly; rotation/wrap; click-outside dismissal; no post-action flash; mnemonics; all three entry points) — none of Gate B's criteria have been confirmed live against the ring yet.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Plan 20-07 completes QPOWER-03 and both cross-surface behaviours (D-20-31/D-20-32) — the power-menu half of Phase 20 now has every planned surface built (ring, warning chip, cascade, suppression, popup dismissal).
- Plan 20-08 (GATE-02 Gate B, unlocking `wleave` retirement) remains blocked on a full live human-verification pass against everything built across 20-06 and 20-07 — none of Gate B's criteria have been confirmed live yet, including this plan's own scrim-colour fix.
- The `WINDOWS.md` ledger gains new open `unrun-verify` entries for this plan's own five human-check items (see above), on top of the pre-existing open entry from 20-06.

---
*Phase: 20-indicators-power-menu*
*Completed: 2026-08-15*

## Self-Check: PASSED

All 7 claimed files verified present on disk; all 3 claimed commit hashes (`e60ec7d`, `4f186bf`, `a633f70`) verified present in `git log --oneline --all`.
