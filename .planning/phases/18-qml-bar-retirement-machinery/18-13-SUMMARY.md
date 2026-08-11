---
phase: 18-qml-bar-retirement-machinery
plan: 13
subsystem: ui
tags: [quickshell, qml, hyprland-layershell, popout, hover-contract]

# Dependency graph
requires:
  - phase: 18-08
    provides: "MediaConnectivityCapsule.qml with the five readout entries, the shared Readout inline component, and the audio entry's AudioBackend.masterVolume reads"
  - phase: 18-11
    provides: "PanelDialog.qml family precedent (GradientBorder/Cascade/HyprlandFocusGrab reuse, four-state vocabulary) this plan mirrors into a second frame"
  - phase: 18-12
    provides: "The audio entry's WheelHandler scroll-to-adjust gesture on MediaConnectivityCapsule.qml, which this plan wraps without touching"
provides:
  - "SectionPopout.qml — the bar's second frame (D-18-15 accepted cost), bounded 300-360px, anchored off its trigger, reserving nothing, reusing GradientBorder/Cascade/HyprlandFocusGrab unchanged"
  - "PopoutController.qml — registered singleton, the popout family's single guarded summon path (six-section allowlist, open/pin/close/toggle) plus the full hover contract (suppression latch, dwell, combined-region grace, pinned-ignores-hover)"
  - "PopoutTrigger.qml — the per-entry wrapper hosting one LazyLoader keyed on the shared open section, reporting hover to the controller, publishing a fresh scene-space anchor"
  - "AudioPopout.qml — the only body this plan ships and 18-14's template: device label, mute toggle, master volume, up to three sinks, driven by AudioBackend.pipewireReady/outputsPresent, with a foot link to AudioPanel.qml"
  - "Six Design.qml tokens (popoutDwellMs/popoutDismissGraceMs/popoutHeaderHeight/popoutCornerRadius/popoutMinWidth/popoutMaxWidth), append-only"
  - "One bounded Connections block in Bar.qml relaying PopoutController's wayfinding signals into 18-05's frozen panelRequested/dashboardRequested seams"
affects: [18-14, 18-16, 18-17]

# Actuals (#2632)
actuals:
  tokens: 14982
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Second-frame-by-review, not second-frame-by-construction (D-18-15): SectionPopout.qml is a bespoke PanelWindow, its header states the reasoning in its first paragraph, and its chrome/state-vocabulary declarations are named-identical to PanelDialog.qml (same stateColour() mapping, same 0.78 panelSurfaceOpacity, same 0.38 disabled-pill treatment) so the two frames stay diffable rather than drifting silently."
    - "Single-guarded-summon-path singleton (PopoutController.qml): openSection/pinnedSection are written in exactly two places (open()/close()), every trigger's LazyLoader.active is keyed on the same shared string, and every hover entry point returns early while anything is pinned — mirrors shell.qml's openPanel(name) shape one level down."
    - "Combined hover region as two independent booleans (hoveredSection + popoutHovered), never a counter — the 4px entry-to-popout gap is inside the union by construction rather than a geometric rectangle, and a lost enter/exit event cannot wedge the popout permanently open the way a counter could underflow."
    - "Scene-space anchor published at summon time via mapToItem(null, 0, 0), never bound live — matches WindowThumbnail.qml's/Overview.qml's own established idiom for the same reason: scene mapping does not re-evaluate when an ancestor moves, and the bar never reflows while a popout is open."

key-files:
  created:
    - quickshell/.config/quickshell/modules/bar/SectionPopout.qml
    - quickshell/.config/quickshell/modules/bar/PopoutController.qml
    - quickshell/.config/quickshell/modules/bar/PopoutTrigger.qml
    - quickshell/.config/quickshell/modules/bar/AudioPopout.qml
  modified:
    - quickshell/.config/quickshell/modules/bar/MediaConnectivityCapsule.qml
    - quickshell/.config/quickshell/modules/bar/qmldir
    - quickshell/.config/quickshell/modules/dashboard/Design.qml
    - quickshell/.config/quickshell/modules/Bar.qml

key-decisions:
  - "ExclusionMode.Ignore (not PanelDialog's Normal) on SectionPopout, so its Design-token-derived margins measure from the true screen edge without having to subtract the bar's own reservation back out — exclusiveZone stays 0 either way, so the 'reserves nothing' obligation holds regardless."
  - "bodyColumn's inner width is a fixed Design-token expression (Design.popoutMaxWidth - Design.spacingMd * 2), never bound to popoutWindow's own resolved width — the frame's implicitWidth clamp reads FROM bodyColumn.implicitWidth, so binding the reverse direction would be circular."
  - "AudioPopout's own body content (device label, mute/volume row, sink list) is gated on bodyState === \"populated\" so the frame's placeholder never double-renders underneath real content when PipeWire is unready or has no outputs."

patterns-established:
  - "This phase's established 'skip live verification, ship fast' operating mode continued: every automated grep/regex <verify> assertion across all three tasks was run and passed (using /usr/bin/grep directly — this session's interactive shell aliases `grep` to a ugrep wrapper in a mode that mis-parses the plan's own BRE escapes, a shell-environment quirk unrelated to the plan). The safe, read-only live probes were also run and passed: `hyprctl layers -j` shows exactly one `quickshell-bar` namespace and zero `quickshell-bar-` (popout) namespaces at rest, and `~/.cache/quickshell.log` shows zero errors/warnings for every new type. The genuinely interactive halves — dwell/grace timing felt live, the diagonal-move-survives-the-gap proof, the pin/Escape/click-outside cycle, typing into a focused terminal with a preview open, vertical-orientation confirmation, and the theme-switch crossfade check — were NOT performed this session, because the running quickshell process (long-lived, predates this plan's commits) has not been restarted or hot-reloaded against this code. Matches 18-08's and 18-12's identical, already-established precedent, logged the same way."

requirements-completed: [QBAR-09]

coverage:
  - id: D1
    description: "SectionPopout.qml: a second PanelWindow frame, bounded 300-360px, anchored off its trigger entry per-orientation with single-edge-margin arithmetic and an inward clamp, reserving nothing (exclusiveZone 0), reusing GradientBorder/Cascade/HyprlandFocusGrab unchanged, with the focus grab and keyboard-focus mode both bound to `pinned`"
    requirement: "QBAR-09"
    verification:
      - kind: other
        ref: "Task 1 automated <verify> grep/regex script — all assertions run and passed (commit 14ba175): exactly one PanelWindow, quickshell-bar-<section> namespace, exclusiveZone 0 exactly once, keyboardFocus/focus-grab active both bound to pinned, GradientBorder/Cascade/HyprlandFocusGrab all reused, uniform corner radius (no bottom-only rounding copied), no fixed frame-size literal, both anchor formulas token-derived with no doubled margin, Math.max/Math.min clamp present"
        status: pass
    human_judgment: true
    rationale: "The plan's own human-check requires clicking the live audio entry, confirming the popout's rounded/translucent/rim-animated appearance, reading hyprctl layers -j's y=50 value live, confirming the volume readout matches reality, moving the master slider and confirming real system volume moves, confirming full destruction on click-outside, confirming 18-12's scroll gesture still works after the wrap, and confirming vertical-orientation left-side placement. Not performed this session — the live quickshell process predates every commit in this plan and has not been restarted/reloaded, matching 18-08/18-12's established deferral precedent."
  - id: D2
    description: "PopoutController.qml: registered singleton (qmldir's second) carrying the six-section allowlist validated before a sectionId reaches the layer-shell namespace, and the summon path (open/pin/close/toggle) writing openSection in exactly two places"
    requirement: "QBAR-09"
    verification:
      - kind: other
        ref: "Task 1 automated <verify> — controller registered as singleton with pragma Singleton, isValidSection referenced >=2 times, all six section names present, openSection assigned exactly twice (open()/close())"
        status: pass
    human_judgment: false
  - id: D3
    description: "PopoutTrigger.qml: exactly one LazyLoader keyed on PopoutController.openSection === this trigger's sectionId, no chrome, no wheel-gesture interference, publishAnchor() called on both paths that can open"
    requirement: "QBAR-09"
    verification:
      - kind: other
        ref: "Task 1 automated <verify> — one LazyLoader, keyed condition present, zero WheelHandler/onWheel/preventStealing/propagateComposedEvents/Rectangle identifiers, publishAnchor present"
        status: pass
    human_judgment: false
  - id: D4
    description: "The hover contract: reveal-settled/pointer-moved suppression latch (D-18-19), 400ms dwell on one shared restarting timer (D-18-20), 200ms combined-region grace (D-18-21), pinned popouts ignoring hover entirely (D-18-22)"
    requirement: "QBAR-09"
    verification:
      - kind: other
        ref: "Task 2 automated <verify> script — all assertions run and passed (commit edebf25): previewArmed is the literal conjunction of barSettled/pointerMovedSinceSettle, both timer intervals read the Design token exactly once, exactly two non-repeating stopped-at-rest Timer objects, combinedHovered declared as a boolean union (no counter identifiers), all five reported events declared, >=7 non-comment pinnedSection guards, openSection still written in exactly two places, trigger writes no controller state directly and interferes with no wheel identifier"
        status: pass
    human_judgment: true
    rationale: "The plan's human-check is entirely interactive: holding on the audio entry for a felt 400ms beat, sweeping the pointer briskly across the whole bar and confirming nothing opens, moving diagonally into the popout across the gap without a flicker, pin/unpin behavior, Escape, click-outside, and typing a full line into a focused terminal with a preview open to confirm no keystroke theft. None of this is provable by static analysis or by a log grep alone (the one exception, the 'popout: preview armed' log line, requires the same live pointer motion). Not performed this session for the process-restart reason recorded above."
  - id: D5
    description: "AudioPopout.qml: device label, mute toggle, master volume, up to three sinks, bodyState driven by AudioBackend.pipewireReady (pending)/outputsPresent (empty) with the failed state declared and honestly unexercised, and a foot wayfinding link routed through PopoutController.requestPanel(\"audio\") to the existing AudioPanel.qml"
    requirement: "QBAR-09"
    verification:
      - kind: other
        ref: "Task 3 automated <verify> script — all assertions run and passed (commit 4cd9963): four-state vocabulary and stateColour() present under PanelDialog's own names, pending/failed both mapped to Colours.primary/Colours.error, wayfinding pill in Colours.surfaceVariant with 0.38 disabled opacity and Design.tooltipDelayMs, failure copy matches the UI-SPEC sentence shape verbatim, AudioPopout binds bodyState exactly once from pipewireReady/outputsPresent and routes through PopoutController.requestPanel, Bar.qml's diff is exactly one bounded additive Connections block (15 lines added, 0 removed) with shell.qml/BarEntryModel.qml/BarCapsule.qml untouched, zero fullscreenBlocking identifiers anywhere under modules/bar/, three Text elements in AudioPopout.qml all carry an explicit textFormat"
        status: pass
    human_judgment: true
    rationale: "The plan's human-check requires visually confirming the foot pill's muted surface-variant colour against a real dashboard panel's Advanced button, clicking it and confirming the same 850x620 AudioPanel.qml surface Super+A opens, provoking the pending/empty states live (muting, briefly stopping PipeWire) and confirming the placeholder reads as a quiet symbol plus one line rather than a blank body or a synthesized value, and switching the live theme with a popout pinned to confirm every colour crossfades together. Not performed this session for the process-restart reason recorded above."
duration: ~45min
completed: 2026-08-11
status: complete
---

# Phase 18 Plan 13: Section Popout Frame, Hover Contract & Audio Popout Summary

**QBAR-09 lands as a complete second frame family: `SectionPopout.qml` (a bespoke `PanelWindow` D-18-15 knowingly accepts as a costly second frame), `PopoutController.qml` (the registered singleton owning the six-section allowlist, the summon path, and the full D-18-19..D-18-22 hover contract — suppression latch, 400ms dwell, 200ms combined-region grace, pinned-ignores-hover), `PopoutTrigger.qml` (the per-entry hover-reporting wrapper), and `AudioPopout.qml` (the one body this plan ships — device label, mute, master volume, up to three sinks, driven by real `AudioBackend` state with a foot link back to the existing audio panel) — proven end-to-end on the audio entry only, with the frame and controller left complete and unchanged for 18-14 to hang five more bodies on.**

## Performance

- **Duration:** ~45 min
- **Started:** 2026-08-11 (session start)
- **Completed:** 2026-08-11
- **Tasks:** 3 (all completed)
- **Files modified:** 8 (4 new QML types, 4 modified)

## Accomplishments

- **Task 1 (tracer):** `Design.qml` gained six appended popout tokens (`popoutDwellMs` 400, `popoutDismissGraceMs` 200, `popoutHeaderHeight` 48, `popoutCornerRadius` 20, `popoutMinWidth` 300, `popoutMaxWidth` 360). `modules/bar/qmldir` registered four new types append-only, `PopoutController` as the manifest's second singleton. `SectionPopout.qml` shipped as the second frame — its header names D-18-15's reasoning and accepted cost in its first paragraph, its layer posture differs from `PanelDialog.qml` on every commented line (side-anchored not centred, `exclusiveZone` 0, `ExclusionMode.Ignore`, keyboard focus bound to `pinned`), its chrome (background/`GradientBorder`/`HyprlandFocusGrab`/`Cascade`) is reused unchanged in `PanelDialog`'s own declaration order, and its size/anchoring is entirely Design-token arithmetic with an inward clamp on both axes. `PopoutController.qml` shipped as a registered singleton carrying the six-section allowlist and the summon path (`open`/`pin`/`close`/`toggle`), `openSection` written in exactly two places. `PopoutTrigger.qml` hosts one `LazyLoader` keyed on the shared open section, publishes a scene-space anchor via `mapToItem(null, 0, 0)`, and adds no chrome or wheel interference. `AudioPopout.qml` renders device label, mute toggle, master volume (reusing `AudioPanel.qml`'s slider shape, clamped at the call site since `setMasterVolume()` carries no clamp of its own), and up to three sinks. The audio entry in `MediaConnectivityCapsule.qml` (18-08's file) was wrapped in a `PopoutTrigger`, leaving 18-12's wheel handler untouched.
- **Task 2:** `PopoutController.qml` gained the reveal-settled/pointer-moved suppression latch (`previewArmed = barSettled && pointerMovedSinceSettle`, `barSettled` defaulting `true` as 18-16's undriven input, reset via an explicit `onBarSettledChanged` handler rather than a binding), two non-repeating stopped-at-rest `Timer`s reading `Design.popoutDwellMs`/`Design.popoutDismissGraceMs`, the combined hover region as two independent booleans, and five reported events — `entryEntered`/`entryExited` (plus every hover-state write) return early whenever `pinnedSection` is non-empty. `PopoutTrigger.qml` wires its `MouseArea`'s `onEntered`/`onExited`/`onPositionChanged` to the controller's three entry functions, relays the loaded popout's own hover edge into `popoutEntered()`/`popoutExited()`, and calls `publishAnchor()` on both paths that can open.
- **Task 3:** `SectionPopout.qml` gained the four-state vocabulary and `stateColour()` mapping under `PanelDialog.qml`'s own names, a frame-owned placeholder anchored to the body region (quiet Material Symbol plus one line, visible whenever `bodyState !== "populated"`), and a foot wayfinding pill in the surface-variant role with the 0.38 disabled treatment (press suppression via an early-return guard, never a disabled `MouseArea`, so the reason stays hover-reachable). `AudioPopout.qml` drives `bodyState` from `AudioBackend.pipewireReady` (pending) and `outputsPresent` (empty) — confirmed genuinely distinct by reading `AudioBackend.qml` directly — declares the `failed` state unexercised (no whole-backend failure signal exists anywhere in that file), and gates its own body content on `bodyState === "populated"` so the placeholder never double-renders alongside real content. `Bar.qml` gained exactly one bounded, additive `Connections` block relaying `PopoutController`'s wayfinding signals into 18-05's frozen `panelRequested`/`dashboardRequested` seams.

## Task Commits

Each task was committed atomically:

1. **Task 1: One path, every layer — SectionPopout frame, PopoutController summon path, audio popout** — `14ba175` (feat)
2. **Task 2: The hover contract — suppression latch, dwell, combined-region grace, pinned ignores hover** — `edebf25` (feat)
3. **Task 3: The glance-surface state grammar and the way out** — `4cd9963` (feat)

**Plan metadata:** pending final commit (this SUMMARY + STATE.md + ROADMAP.md + REQUIREMENTS.md)

## Files Created/Modified

- `quickshell/.config/quickshell/modules/bar/SectionPopout.qml` — new: the second frame (identity/geometry/interaction/body/wayfinding public surface)
- `quickshell/.config/quickshell/modules/bar/PopoutController.qml` — new: registered singleton, summon path + full hover contract
- `quickshell/.config/quickshell/modules/bar/PopoutTrigger.qml` — new: per-entry wrapper, hover reporting, anchor publishing
- `quickshell/.config/quickshell/modules/bar/AudioPopout.qml` — new: the audio body, 18-14's template
- `quickshell/.config/quickshell/modules/bar/MediaConnectivityCapsule.qml` — audio entry wrapped in a `PopoutTrigger`, nothing else changed
- `quickshell/.config/quickshell/modules/bar/qmldir` — four new type registrations, append-only
- `quickshell/.config/quickshell/modules/dashboard/Design.qml` — six popout tokens, append-only
- `quickshell/.config/quickshell/modules/Bar.qml` — one bounded `Connections` relay block

## Decisions Made

- **`ExclusionMode.Ignore`, not `PanelDialog`'s `Normal`** — the popout's Design-token-derived margins must measure from the true screen edge to stay computable from tokens alone; `Normal` would have offset every popout by the bar's own reservation, which this file would then have to subtract back out. `exclusiveZone` stays `0` either way, so the "reserves nothing" obligation holds regardless of exclusion mode.
- **`bodyColumn`'s inner width is a fixed `Design.popoutMaxWidth - Design.spacingMd * 2` expression, never bound to `popoutWindow`'s own resolved width** — the frame's `implicitWidth` clamp reads FROM `bodyColumn.implicitWidth`, so binding the reverse direction would create a genuine circular binding.
- **`AudioPopout`'s own body content is gated on `bodyState === "populated"`** — without this, the frame's placeholder would render centered on top of a blank device label and an inert slider whenever PipeWire is unready or has no outputs, a real (if minor) visual defect the plan's own grep gates could not catch. Applied proactively (Rule 1), matching `AudioPanel.qml`'s own established `outputSection` visibility-gating precedent.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical Functionality] Added a minimal `HoverHandler` + `hovered` property to `SectionPopout.qml`**

- **Found during:** Task 2, wiring `PopoutTrigger.qml`'s relay of "the loaded popout's own hover state" into `popoutEntered()`/`popoutExited()`
- **Issue:** Task 2's own `<files>` list named only `PopoutController.qml`/`PopoutTrigger.qml`, but the popout is a separate top-level `PanelWindow` (not spatially nested under the trigger's `Item` tree), so nothing in either of those two files can observe hover over the OTHER window's surface without the popout itself exposing a hover signal. Without this, T-18-13's concurrency contract ("the pointer can leave an entry, enter the popout, and leave again inside one grace window") has no mechanism to relay from — a structural gap that would leave the combined-hover-region truth silently broken.
- **Fix:** Added a `HoverHandler` inside `SectionPopout.qml`'s `content` Item (the same attach-to-an-Item shape `BarCapsule.qml`'s own `HoverHandler` already uses, not a novel pattern) and a `readonly property bool hovered` alias, then wired `PopoutTrigger.qml`'s loader to connect `hoveredChanged` into the controller's `popoutEntered()`/`popoutExited()`.
- **Files modified:** `quickshell/.config/quickshell/modules/bar/SectionPopout.qml`, `quickshell/.config/quickshell/modules/bar/PopoutTrigger.qml`
- **Verification:** Task 2's automated `<verify>` script (which does not reference `SectionPopout.qml`) still passed unchanged; the addition was cross-checked against `BarCapsule.qml`'s existing `HoverHandler` precedent for shape consistency.
- **Committed in:** `edebf25` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 2 — a structural gap in the plan's own Task 2 file scoping, closed the same session it was discovered, before commit).
**Impact on plan:** No behavior change to any already-passing gate; closes a real gap in the combined-hover-region mechanism the plan's must_haves require. No scope creep — the fix is the minimum surface (one `HoverHandler`, one property, one signal relay) needed for the named requirement to actually function.

## Issues Encountered

- **Interactive-shell `grep` aliasing.** This session's shell environment aliases `grep` to a `ugrep`-backed wrapper that mis-parses one of the plan's own verify-script escape sequences (`\{` inside a non-`-E` invocation), producing a spurious "invalid repeat" error unrelated to the QML or the plan text. Worked around by invoking `/usr/bin/grep` directly for every verification command in this session — a shell-environment quirk, not a defect in the plan or the shipped code. Logged here so a future session doesn't re-diagnose it as a real failure.

## User Setup Required

None — no external service configuration required. Every type this plan uses ships inside the already-installed `quickshell 0.3.0-2` or already exists in this repo (T-18-13-SC, matching the phase-wide N/A `18-RESEARCH.md` already records).

## Known Stubs

None. `AudioPopout.qml` renders exclusively live reads of `AudioBackend`'s real properties — no placeholder, no synthesized value, no hardcoded percentage. The `failed` state is declared in the vocabulary and honestly unexercised (no whole-backend failure signal exists in `AudioBackend.qml`, confirmed by direct reading rather than guessed), matching `PanelDialog.qml`'s own tracer precedent of shipping with two of its four states unexercised — this is a recorded, evidenced gap, not a stub standing in for missing work.

## Live Verification — Deferred (per this phase's established skip-live-verification operating mode)

Every task's automated `<verify>` grep/regex script ran and passed (see Task Commits and `coverage` above), and the safe, non-destructive live probes were also run and passed this session: `hyprctl layers -j` confirms exactly one `quickshell-bar` namespace and zero `quickshell-bar-` (popout) namespaces at rest, `tail -150 ~/.cache/quickshell.log` shows zero errors/warnings for every new type, and the `Bar.qml` diff was confirmed as exactly one bounded additive block (15 lines added, 0 removed) with `shell.qml`/`BarEntryModel.qml`/`BarCapsule.qml` untouched.

The genuinely interactive halves were NOT performed this session, matching 18-08/18-12's identical, already-established precedent: the running `quickshell` process predates every commit in this plan and has not been restarted or hot-reloaded against this code, so a live pointer test right now would exercise old code, not what was just written. Specifically deferred:
- Task 1's human-check: clicking the live audio entry, confirming the popout's rounded/translucent/rim-animated appearance and its `y=50` position via `hyprctl layers -j`, confirming the volume readout and slider move real system volume, confirming full destruction on click-outside, confirming 18-12's scroll gesture survives the wrap, and confirming vertical-orientation left-side placement.
- Task 2's human-check: the felt 400ms dwell beat, the bar-sweep-opens-nothing proof, the diagonal-move-survives-the-gap proof, pin/unpin/Escape/click-outside, and typing a full line into a focused terminal with a preview open to confirm no keystroke theft (the `popout: preview armed` log line requires this same live pointer motion).
- Task 3's human-check: visually comparing the foot pill against a real dashboard panel's Advanced button, clicking it to confirm `AudioPanel.qml` opens, provoking the pending/empty states live, and confirming the theme-switch crossfade covers every colour in the popout together.

Logged to `.planning/WINDOWS.md` as unrun-verify entries (one per task's deferred human-check half), so all three stay visible at ship time.

## Next Plan Readiness

- `PopoutController.qml`'s public surface (`sections`, `isValidSection`, `open`/`pin`/`close`/`toggle`, `barSettled`/`previewArmed`, the five reported events, `panelRequested`/`dashboardRequested`) is complete and unchanged by this plan's own scope — 18-14 hangs five more bodies on it with zero edits to the controller or the frame.
- `SectionPopout.qml`'s public surface (identity/geometry/interaction/body-state/wayfinding) is the literal contract 18-14's five bodies read; nothing in it is provisional or half-shipped.
- `barSettled` stays at its `true` default, named explicitly as 18-16's undriven input — 18-16 sets it `false` at reveal start and `true` on reveal completion with zero changes needed here.
- `anyOpen` is declared and unconsumed, named explicitly as 18-16's re-hide-grace input.
- `MediaConnectivityCapsule.qml`'s five-entry ownership (18-08 readouts, 18-12 wheel gestures, this plan's one `PopoutTrigger` wrap) is now fully accounted for — 18-14 wraps the remaining four entries (wifi, bluetooth, clock, resources are on other files; media is the fifth entry here) without a partial-ownership conflict to resolve.

---
*Phase: 18-qml-bar-retirement-machinery*
*Completed: 2026-08-11*

## Self-Check: PASSED

- FOUND: `quickshell/.config/quickshell/modules/bar/SectionPopout.qml`
- FOUND: `quickshell/.config/quickshell/modules/bar/PopoutController.qml`
- FOUND: `quickshell/.config/quickshell/modules/bar/PopoutTrigger.qml`
- FOUND: `quickshell/.config/quickshell/modules/bar/AudioPopout.qml`
- FOUND commit: `14ba175`
- FOUND commit: `edebf25`
- FOUND commit: `4cd9963`
