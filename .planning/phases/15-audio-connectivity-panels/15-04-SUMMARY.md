---
phase: 15-audio-connectivity-panels
plan: 04
subsystem: ui
tags: [quickshell, qml, pipewire, audio, material-you, panel]

requires:
  - phase: 15-audio-connectivity-panels (plan 02)
    provides: "AudioPanel/AudioBackend tracer — PanelDialog frame, master volume + mute, panelOpen wiring, 850x620 approved geometry"
provides:
  - "Complete audio panel: pinned control block (master volume+mute, output/input device pickers, input level slider, mic mute) over a scrolling per-app mixer list, with populated/pending/empty/failed states plus the two audio-only states (nothing-playing, PipeWire-unreachable)"
  - "AudioBackend's completed public surface: streamNodes (node-id ordered), per-stream/per-device writers, label/icon fallback chains, device-presence predicates, device-switch pending/failed model"
  - "The pinned-block/list visual-hierarchy pattern (boundary divider+label, primary-control weight differentiation) for 15-05/15-06 to mirror"
affects: [15-05-wifi-panel, 15-06-bluetooth-panel, 15-09-quickshell-doctor-phase-close]

actuals:
  tokens: 15799
  tasks: 4
  commits: 4

tech-stack:
  added: []
  patterns:
    - "Row-scoped device-switch pending/failed model: property string pendingDevice/failedDevice + a 3s interval: Timer watchdog, cleared on OBSERVED backend truth (defaultSink/Source actually becoming the requested node), never on the write returning — reuses QuickToggles.qml's chip-timeout shape"
    - "Locally-composed body-state regions when PanelDialog.bodyState ships readonly: nothingPlaying/panelUnreachable computed as readonly bool properties inside the panel file itself, calling the frame's stateColour(state) for palette mapping only"
    - "Pinned-block/list hierarchy fix (Task 4): a Colours.outline divider + fontLabel section heading marks the pinned/list boundary explicitly; the block's own primary control (master volume) is drawn with heavier track/handle geometry than every other slider in the panel, independent of its current value"

key-files:
  created: []
  modified:
    - quickshell/.config/quickshell/modules/dashboard/AudioBackend.qml
    - quickshell/.config/quickshell/modules/dashboard/AudioPanel.qml

key-decisions:
  - "D-15-10 (focal point): the pinned control block is the panel's declared focal point, not just its first element — landed verbatim in AudioPanel.qml's header."
  - "D-15-11 (input symmetry + pre-authorized fallback): full input symmetry shipped per the user's override; the fallback (drop the input level slider) was explicitly DECLINED at the Task 4 gate — panel judged not cluttered, so the fallback would cost PANEL-01 capability for no readability gain."
  - "A2 disposition (carried from 15-01's blocking checkpoint): branch (a) accept-and-document shipped — streamRouteNote exists, rerouteToDefault does not. Output has no residual (re-routes already-playing streams live); input's accepted-and-ignored residual is disclosed via streamRouteNote rendered under the INPUT picker (a placement divergence from the plan's generic template, since the measured residual is input-only)."
  - "State-composition path: PanelDialog.bodyState shipped readonly (confirmed by reading the file) — this panel composes nothingPlaying/panelUnreachable locally rather than binding the frame's placeholder. 15-05/15-06 should copy this path."
  - "Task 4 render-gate hierarchy fix: a boundary divider+label plus master-slider weight differentiation, landed instead of the D-15-11 fallback, and recorded as the pattern 15-05/15-06 must mirror against their own primary control and list."

patterns-established:
  - "Node identity/ordering: sort by the typed PwNodeIface.id (uint), never the untyped object.id map entry, never lexicographically — string-sorted ids reorder across digit boundaries"
  - "Muted state carried 3+ ways (glyph + colour + track fill) plus a tooltip on every per-row mute affordance, exceeding the 'carried twice' floor"
  - "E2 error/empty backstops (row-scoped device-switch failure, no-output-device) proven via reverted in-tree fault injection + screenshot before being trusted to render correctly"

requirements-completed: [PANEL-01, PANEL-02]

coverage:
  - id: D1
    description: "Per-app mixer list: one row per live PipeWire stream (icon-as-mute, elided name+tooltip, slider), independently mutable, node-id-ordered, never re-sorted by volume/name/activity — PANEL-01"
    requirement: "PANEL-01"
    verification:
      - kind: manual_procedural
        ref: "Task 3 commit 8f4f8b5: 3 concurrent real streams (two same-app pw-play instances + Zen) rendered as 3 independently-mutable rows in ascending node-id order (34, 65, 116); per-app mute via a temporary debug-IPC harness affected exactly the targeted row, sibling same-app stream and Zen unaffected; screenshot evidence at nothing-playing/list-overflow/unreachable fault injections."
        status: pass
    human_judgment: true
    rationale: "Closed via Task 4's blocking checkpoint:human-verify render gate — real-audio behavioural facts (checks 3/5/6/8) plus judgment calls (checks 1/2/4/9) require a human render-and-look pass per this repo's standing gate discipline."
  - id: D2
    description: "Pinned control block: master volume+mute, output/input device pickers as inline expanding rows, input level slider, mic mute — declared focal point, never scrolls, reads as primary over the per-app list — PANEL-02 plus the Task 4 hierarchy fix"
    requirement: "PANEL-02"
    verification:
      - kind: manual_procedural
        ref: "Task 2 commit 03d09f2 (device switch 84->54->84 cross-checked against wpctl, D-22 truth-driven readback) + this session's fix screenshots (audio-panel-fixed.png, audio-panel-unreachable2.png, audio-panel-nothingplaying.png, audio-panel-final.png) showing the sectionDivider boundary and the heavier master slider post-fix"
        status: pass
    human_judgment: true
    rationale: "Check 1 (focal point) was the gate's explicit FAIL-as-shipped finding; the fix and its re-verification in this session close it, but the underlying render-gate disposition (CONDITIONALLY APPROVED — one scoped fix, then closed) was itself a human judgment call, not a mechanical pass."

duration: multi-session (4 tasks across original session + this fix-and-close continuation)
completed: 2026-08-02
status: complete
---

# Phase 15 Plan 04: Audio Panel Build-Out Summary

**The audio panel's pinned control block (master volume+mute, output/input device pickers, input level slider, mic mute) over a scrolling per-app PipeWire mixer list, closed after a Task 4 render-gate hierarchy fix — a boundary divider/label plus master-slider weight differentiation — that 15-05/15-06 now inherit as the pattern to mirror.**

## Performance

- **Duration:** multi-session (Tasks 1-3 in the original session; Task 4's gate fix and close in this continuation)
- **Tasks:** 4/4 complete
- **Files modified:** 2 (`AudioBackend.qml`, `AudioPanel.qml`)

## Accomplishments

- `AudioBackend.qml` completed: `streamNodes` (node-id-ascending, typed `PwNodeIface.id` accessor), per-stream/per-device writers, exhaustive label/icon fallback chains, `outputsPresent`/`inputsPresent` predicates, a row-scoped device-switch pending/failed model with a 3s watchdog cleared on observed truth.
- `AudioPanel.qml` built out: the pinned control block (master row, `DevicePickerRow` inline-expanding component instantiated for output and input, input level slider behind `inputLevelSliderEnabled`, mic mute), the scrolling per-app `StreamRow` list, the `nothingPlaying` and `panelUnreachable` states.
- Task 4's blocking render gate: **CONDITIONALLY APPROVED — one scoped fix, then closed.** Check 1 (focal point, D-15-10) failed as shipped; check 2 (density, D-15-11's fallback) passed and the fallback was explicitly declined. The fix (this session): a `Colours.outline` divider + "Applications" section label between the pinned block and the list, and a heavier master-volume track/handle (8px/20px vs. the shared 4px/16px every other slider uses). Applied, re-verified live via IPC summon + screenshots, committed (`80039ca`).
- Plan closed 4/4. PANEL-01 and PANEL-02 both delivered.

## Task Commits

1. **Task 1: Complete AudioBackend** — `343650c` (feat) — ordered streams, per-stream/device writes, label/icon fallbacks, device-switch pending/failed model, A2 branch (a) implemented
2. **Task 2: The pinned control block** — `03d09f2` (feat) — master row promoted, `DevicePickerRow` component, both picker instances, D-15-11 input symmetry landed, E2 empty backstop
3. **Task 3: The scrolling per-app mixer list + states** — `8f4f8b5` (feat) — `StreamRow`, `ListView` over `streamNodes`, `nothingPlaying` and `panelUnreachable`
4. **Task 4: Render-gate fix and close** — `80039ca` (fix) — `sectionDivider` boundary marker + master-slider weight differentiation, per the gate's scoped fix instructions

**Plan metadata:** this commit (docs: complete plan)

## Files Created/Modified

- `quickshell/.config/quickshell/modules/dashboard/AudioBackend.qml` — the completed PipeWire adapter: `streamNodes`, `streamNodeKey`, `setStreamVolume`/`setStreamMuted`, `streamIcon`/`deviceLabel`, `outputsPresent`/`inputsPresent`, `pendingDevice`/`failedDevice`/`deviceSwitchTimeoutMs` watchdog, `clearDeviceFailure`, `streamRouteNote` (A2 branch (a))
- `quickshell/.config/quickshell/modules/dashboard/AudioPanel.qml` — the full panel body: `pinnedBlock`, `DevicePickerRow`, `outputPicker`/`inputPicker`, `micRow`, `inputLevelSliderEnabled`, `sectionDivider` (Task 4 fix), `appListRegion`, `StreamRow`, `nothingPlaying`, `panelUnreachable`

## Decisions Made

**D-15-10 — the focal point**, landed verbatim in `AudioPanel.qml`'s header:

> The pinned control block is this panel's declared focal point (UI-SPEC Dimension 2), not just its first element: it carries the highest-frequency controls, so it is what the eye must land on before the app list. It is pinned rather than scrolled because D-15-10's rule is "scroll exactly what is unbounded and nothing else" — the app list is unbounded, the master and device controls are not. Its accepted cost, recorded rather than discovered later, is that the pinned block shortens the app list's viewport.

**D-15-11 — the user override and its pre-authorized fallback**, landed verbatim above the input block. At the Task 4 gate, **the fallback was declined**: the human's explicit answer — "PASS. Do NOT take the D-15-11 fallback — KEEP the input level slider. The panel is not cluttered; there is significant empty space below the per-app list. Removing a working control would cost PANEL-01 capability for no readability gain." The fallback stays pre-authorized and untaken, recorded as considered-and-declined rather than silently dropped.

**A2 disposition** — branch (a) accept-and-document shipped (carried from 15-01's blocking `checkpoint:decision`, not re-decided here). `streamRouteNote` exists; `rerouteToDefault` does not. Output has no residual (re-routes already-playing streams live). Input's accepted-and-ignored residual is disclosed via `streamRouteNote`, rendered under the **input** picker — a placement divergence from the plan's generic template text, because 15-API-PROBE.md's bounded re-probe measured the residual on the input side only.

**State-composition path** — `PanelDialog.bodyState` shipped `readonly` (confirmed by reading `PanelDialog.qml` directly). This panel composes `nothingPlaying` and `panelUnreachable` locally as `readonly bool` properties, calling the frame's `stateColour(state)` for palette mapping only. Not dead code on the frame per se — the frame's `bodyState`/`emptyStatePlaceholder` mechanism is simply unused by this panel; 15-09 should note whether any panel in the phase ever binds it.

**Task 4 hierarchy fix — the pattern for 15-05/15-06 to mirror.** Two presentation-only moves, `AudioPanel.qml` only, no `AudioBackend.qml` change:
1. `sectionDivider` — a `Colours.outline` hairline + an "Applications" `Design.fontLabel` heading — renders between `pinnedBlock` and `appListRegion`, naming the boundary explicitly instead of leaving it to the mic caption text to imply.
2. `masterVolumeSlider`'s track/handle drawn heavier (8px/20px) than every other slider in the panel (the shared 4px/16px the input-level slider and every per-app row slider use), so the pinned block's own primary control reads as primary regardless of its current value.

This generalizes as: **an explicit pinned/list boundary marker, plus extra weight on the pinned block's own primary control** — not an audio-specific fix. 15-05's wifi network list and 15-06's bluetooth device list should apply the same two moves against their own primary control (radio toggle / adapter toggle) and their own scrolling list.

## Node-id accessor (PANEL-01 ordering/identity truth)

The typed `PwNodeIface.id` property (`uint`, `isReadonly: true`, `isPropertyConstant: true`), **not** the untyped `object.id` properties-map entry. Decided by `15-API-PROBE.md`'s A1(c) line: *"The node's own top-level `id` property (e.g. `93`, `87`) is the only guaranteed-unique per-stream identity... the node id property name is `id` (`PwNodeIface.id`, a `uint`, `isReadonly: true`, `isPropertyConstant: true`)."* Sorted by numeric comparison, never lexicographic.

## Live evidence captured (Tasks 1-3, per their commit messages — this continuation did not re-run these)

- **streamNodes ordering, genuinely observed:** 3 concurrent real streams (two `pw-play` instances sharing application identity + Zen) produced `streamNodes` ids `34, 65, 116`, strictly ascending — exceeds the "2 or more" floor the acceptance criteria required.
- **Same-application-two-streams case, genuinely observed:** two `pw-play` instances (both labeled `pw-play`, the A1 display-name fallback chain working correctly — see "Known limitation" below) rendered as two independently-mutable rows; muting one via a temporary debug-IPC harness (no synthetic pointer-input tool on this host) affected exactly that row, leaving the sibling `pw-play` stream and Zen unaffected.
- **`sinks`/`sources` exact counts:** not captured verbatim in Task 1's commit message (the required temporary log line was added, read, then removed per the acceptance criteria — its output is not preserved in this continuation's context). The ordering and per-stream-identity evidence above stands on its own per the acceptance criteria's own wording ("if only one stream can be produced... say so explicitly" — three were produced, so this is not the degraded case). Flagged here rather than silently assumed complete.
- **Device-switch truth-driven proof:** a real output-device switch (sink `84 -> 54 -> 84`) took effect system-wide, cross-checked against `wpctl status`; the panel's collapsed label and master volume/mute followed backend truth with zero panel-side optimistic copy (D-22).
- **Fault injections proven and reverted (Tasks 2-3):** row-scoped device-switch failure, no-output-device backstop, list-overflow-does-not-move-pinned-block, nothing-playing, PipeWire-unreachable — each via a temporary in-tree seam override, hot-reloaded, screenshotted, reverted, with `git diff` confirmed clean before that task's commit.

## Body-slot inset arithmetic

Matched this plan's own assumption exactly — `PanelDialog.qml`'s `bodyFlick` applies `panelWindow.panelPadding` as one inset value on all four sides (ONE constant, two applications: top + bottom). No correction was needed; `bodyViewportHeight: root.panelHeight - root.headerHeight - root.panelPadding * 2` is unchanged from the plan's arithmetic. The Task 4 fix altered only the **remainder** expression inside that budget — `appListRegion.height` now subtracts `sectionDivider.height` and `root.spacingMd * 2` (was `root.spacingMd` alone), because `sectionDivider` is a third visible sibling in the shared `bodyContent` `Column`, adding a second Column-spacing gap.

## Render-gate disposition (Task 4)

**Round 1 — CONDITIONALLY APPROVED, one scoped fix, then closed** (not a full second render-gate round; the human's disposition was final and pre-authorized the fix without requiring a further human pass).

- **Check 1 (focal point, D-15-10): FAILS as shipped.** Master volume, mic level and every per-app row used an identical pink track/handle at identical weight; no divider, no section label, no marker showing where the pinned block ends. **Fixed** this session (`sectionDivider` + master-slider weight differentiation) and **re-verified as passing** via IPC summon + screenshot (`audio-panel-fixed.png`, `audio-panel-final.png`): the master slider now reads visibly heavier than the mic slider and the per-app row slider, and the "Applications" divider explicitly marks the boundary.
- **Check 2 (density, D-15-11 fallback): PASSES as shipped.** The fallback (drop the input level slider) was considered and **explicitly declined** — the panel was judged not cluttered (significant empty space below the per-app list), so removing a working control would cost PANEL-01 capability for no readability gain. Input level slider stays.
- **Check 4 (long device names): not independently re-tested in this continuation.** Task 2's original evidence (commit `03d09f2`) proved the `Text.ElideRight` + `ToolTip` mechanism functions on the device-picker rows, but no real device name observed on this host (e.g. `ALCS1200A Analog`) was long enough to actually overflow one line. The mechanism is present and grep-verified; a genuinely overflowing real name was not observed. **Carried forward as an open item**, not silently closed, consistent with this project's standing "no unanswered judgment call is silently closed" rule (see 14-08's three carried-forward judgments for precedent).
- **Check 9 (entrance motion): re-verified, not regressed.** `bodyCascadeBands` is unchanged (`[pinnedBlock]`, still 3 total bands with the frame's header/Advanced — confirmed via `quickshell.log`'s `cascade: run tab=-1 bands=3` line, identical to pre-fix). `sectionDivider` was deliberately **not** added to the cascade — it renders whole alongside `appListRegion` (which is also not a cascade band), so the fix cannot have altered the previously-approved cascade timing or feel.
- **Checks 3, 5, 6, 7, 8 (behavioural facts):** all previously proven true in Tasks 1-3 (device switch takes effect, per-app mute is row-scoped, pinned block structurally cannot scroll — it is a sibling `Item` to `appListRegion`, not inside its `ListView` — nothing-playing vs. unreachable are visibly different treatments, no second OSD pill). Re-confirmed in this session: **check 7** re-verified live (see below) and found unaffected by the fix; **check 6** confirmed structurally unaffected (the fix does not touch `pinnedBlock`'s own layout or `appListRegion`'s `ListView`, only the sibling item between them and `appListRegion`'s height budget).

## Fault-injection re-verification for the fix (this session)

Two temporary in-tree overrides, each hot-reloaded, screenshotted, then reverted with `git diff` confirmed clean before the fix commit:

- **PipeWire unreachable** (`panelUnreachable: true` override) — screenshot `audio-panel-unreachable2.png`: whole body replaced by the unfixable-empty grammar ("Audio isn't available — PipeWire isn't running"), no button anywhere in the body, header's Advanced button still present and enabled.
- **Nothing playing** (`nothingPlaying: true` override) — screenshot `audio-panel-nothingplaying.png`: placeholder ("Nothing is playing") confined to the app-list region; the pinned block (master slider, both device pickers, mic row) and the new `sectionDivider`/"Applications" label all stay fully visible and live above it.

The two screenshots read as visibly different treatments — confirming check 7 was not regressed by the fix. Both overrides were reverted; `git diff` was empty before the fix's own edits were staged.

Populated-panel screenshot (`audio-panel-fixed.png`, `audio-panel-final.png`): pinned block (master row, output picker "ALCS1200A Analog", input picker "PRO X", mic level slider) — divider — "Applications" label — one stream row ("Zen"). List-overflow-with-pinned-block-visible and row-scoped-device-switch-failure screenshots were not re-captured in this continuation (Task 2's original evidence stands; the fix does not touch that code path).

## Known limitation (for a future phase)

Two per-app rows both displayed the label `pw-play` (two test streams launched from the same binary during Task 3's verification). This is the A1 display-name fallback chain working **correctly** — each row is still independently mutable by node id. Real duplicate application names currently get **no visual differentiation** beyond their independent rows (no PID/stream-index suffix, no secondary identifying line). Noted here as a known limitation, not a defect — a future phase may want to disambiguate same-named streams further.

## `motion-lint` / `quickshell-doctor`

- `motion-lint`: exit 0, **52 surfaces scanned** — unchanged from both 15-03's close and Task 3's own count (`css/scss=12, conf=4, qml=27, lua=9`), re-run after the Task 4 fix and confirmed still 52 (no new file created by this plan, including the fix).
- `quickshell-doctor`: not re-run in this continuation (the fix touches no namespace/summon-path code). Task 3's original result stands: namespace-discipline check PASS with the panel summoned; the one remaining FAIL is the pre-existing 12-01 volume-probe over-strictness (rounding-sensitive raw-unit exact-match gate, unrelated to this plan).

## Deviations from Plan

### Auto-fixed Issues

**1. [Task 4 gate — scoped fix, pre-authorized by the gate's own disposition] Pinned-block/list visual hierarchy**
- **Found during:** Task 4's blocking render gate (check 1, D-15-10)
- **Issue:** No visual marker between the pinned control block and the per-app list; every slider in the panel (master, mic, per-app) shared identical track/handle weight, so the eye did not land on the pinned block first.
- **Fix:** Added `sectionDivider` (a `Colours.outline` hairline + "Applications" `Design.fontLabel` heading) between `pinnedBlock` and `appListRegion`; increased `masterVolumeSlider`'s track/handle to 8px/20px against the shared 4px/16px every other slider uses. `appListRegion`'s height expression updated for the new Column-spacing gap.
- **Files modified:** `AudioPanel.qml`
- **Verification:** IPC-summoned screenshots before/after; PipeWire-unreachable and nothing-playing states re-verified via reverted fault injection to confirm no regression; `motion-lint` re-run (52/52, unchanged); `quickshell.log` confirmed free of `TypeError`/QML errors throughout.
- **Committed in:** `80039ca`

---

**Total deviations:** 1 (the gate's own pre-authorized scoped fix — not a Rule 1-4 auto-fix in the usual sense, since it was explicitly instructed by the human's gate disposition rather than discovered independently)
**Impact on plan:** No scope creep — presentation-only, `AudioBackend.qml` untouched, 850x620 frame and header chrome untouched, no behavioural or binding change.

## Issues Encountered

None beyond the render-gate's named check-1 finding, resolved as documented above.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- PANEL-01 and PANEL-02 both delivered and marked complete.
- The pinned-block/list hierarchy pattern (boundary divider+label, primary-control weight differentiation) is the explicit precedent 15-05 (wifi network list) and 15-06 (bluetooth device list) should mirror against their own primary control and scrolling list.
- Check 4 (long device names on this host) is carried forward as an open, non-blocking judgment — no real device name observed long enough to test the elision mechanism under genuine overflow.
- The `sinks`/`sources` exact-count log-line evidence from Task 1 was not preserved in this continuation's context (only `streamNodes` counts/ids survived via the commit message) — flagged for 15-09's phase-close review rather than silently treated as fully captured.
- Live desktop state fully restored: quickshell PID 2736484/PPID 809 unchanged throughout, no panel left open, no real audio device/volume/mute state was mutated by this session's fault injections (both overrides were QML source-property overrides, reverted before any screenshot's underlying state could be mistaken for a real write).

## Self-Check: PASSED

- `quickshell/.config/quickshell/modules/dashboard/AudioBackend.qml` — FOUND
- `quickshell/.config/quickshell/modules/dashboard/AudioPanel.qml` — FOUND
- `.planning/phases/15-audio-connectivity-panels/15-04-SUMMARY.md` — FOUND
- Commits `343650c`, `03d09f2`, `8f4f8b5`, `80039ca` — all FOUND in `git log --oneline --all`

---
*Phase: 15-audio-connectivity-panels*
*Completed: 2026-08-02*
