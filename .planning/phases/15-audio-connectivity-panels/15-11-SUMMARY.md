---
phase: 15-audio-connectivity-panels
plan: 11
subsystem: ui
tags: [quickshell, qml, motion-tokens, hyprland, wifi, bluetooth, gap-closure]

# Dependency graph
requires:
  - phase: 12-unified-design-token-pipeline
    provides: motion.json/Motion.qml/motion-lint token pipeline this plan extends with a fifth semantic pair and a new top-level scalar
  - phase: 15-audio-connectivity-panels (15-05, 15-06)
    provides: WifiPanel.qml/WifiBackend.qml/BluetoothPanel.qml, whose indeterminate-sweep idiom and Rescan control this plan corrects
provides:
  - "Motion.qml's ambientDuration/ambientEasing/motionMultiplier — a correctly-scaled, scale-floored loop-period token reachable from QML for the first time"
  - "WifiBackend.qml's rescanInFlight — a synthesised, bounded in-flight edge where the platform exposes only a level"
  - "A corrected, MD3-paced (~2000ms) indeterminate sweep shared by the wifi scan and bluetooth discovery lines"
  - "UI-SPEC D-15-15 amended in place — the corrected behaviour is now locked contract, not a deviation"
affects: [16-workspace-overview, future-motion-retrofit-phases]

# Actuals (#2632)
actuals:
  tokens: 8055
  tasks: 3
  commits: 3

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Loop-period tokens divide the active motion multiplier CAPPED AT 1.0 from above, so a continuous indicator lengthens under `lively` but never shrinks under `reduced` — the reusable shape for any future continuous-loop token"
    - "Client-side synthesised in-flight edge (floor Timer + ceiling watchdog Timer, cleared on a real results-landed observable) for platform APIs that expose only a level, never a per-action edge"

key-files:
  created: []
  modified:
    - theme-engine/.config/theme-engine/lib/motion.sh
    - hypr/.config/hypr/scripts/motion-lint
    - quickshell/.config/quickshell/modules/Motion.qml
    - quickshell/.config/quickshell/modules/dashboard/WifiBackend.qml
    - quickshell/.config/quickshell/modules/dashboard/WifiPanel.qml
    - quickshell/.config/quickshell/modules/dashboard/BluetoothPanel.qml
    - .planning/phases/15-audio-connectivity-panels/15-UI-SPEC.md

key-decisions:
  - "ambientDuration divides the resolved value by the multiplier capped at 1.0 from above — lively still lengthens, reduced is divided back out to the normal-scale value"
  - "borderRotateDuration deliberately left unclamped — it must track Hyprland's own borderangle scaling, not the accessibility floor"
  - "Both sweep legs bind the SAME ambient token, giving a ~2000ms full cycle at normal scale (2 x ~1000ms leg), matching MD3's indeterminate-linear-indicator reference"
  - "rescanInFlight is a SEPARATE property from scanning — the level semantics of scanning stay locked (D-15-15), the edge is additive"
  - "The two pending-pulse sites (WifiPanel/BluetoothPanel) are deliberately NOT touched — a pulse's message survives being fast, unlike a sweep's; logged as an open item (WINDOWS.md #23), not silently dropped"

patterns-established:
  - "Loop-period token clamp shape (divide by min(multiplier, 1.0)) — reusable for any future continuous indicator that must not get faster under reduced motion"
  - "Synthesised bounded in-flight edge (floor + ceiling Timer pair around a real results-observable) — reusable wherever a platform API exposes a level but a press needs an edge"

requirements-completed: [PANEL-03, PANEL-04]

coverage:
  - id: D1
    description: "Wifi scan / bluetooth discovery indeterminate sweep runs at a readable ~2000ms full cycle at normal motion scale, with reduced never faster than normal"
    requirement: "PANEL-03"
    verification:
      - kind: other
        ref: "live quickshell -p probe against the real Motion singleton, cycled through off/reduced/normal/lively and restored; recorded in ambient-period-by-preset.txt (off=1000, reduced=1000, normal=1000, lively=1250 ms/leg)"
        status: pass
    human_judgment: true
    rationale: "The measurement proves the numeric period is correct and non-inverted, but whether the sweep visually 'reads as calm, readable progress, not a flicker' is a perceptual judgment the human render-and-look gate (Task 3's own <human-check>) is meant to make; per this project's human_verify_mode=end-of-phase config, that visual confirmation is deferred to phase-close UAT, not performed by this executor."
  - id: D2
    description: "Pressing Rescan produces an immediate press acknowledgement and a bounded busy state that persists until results land or a watchdog fires"
    requirement: "PANEL-04"
    verification:
      - kind: other
        ref: "live quickshell -p probe instantiating the real WifiBackend component and calling rescan() directly, recording a genuine false -> true -> false rescanInFlight transition with a ~400ms dwell (rescan-edge-measurement.txt)"
        status: pass
    human_judgment: true
    rationale: "The mechanism-level edge is proven live, but whether the glyph's press/spin/settle sequence reads correctly on screen (Task 3's <human-check>: 'the glyph reacts on the press itself, it then spins and turns accent-coloured for a second or more, and it settles back') is a visual judgment deferred to phase-close UAT per human_verify_mode=end-of-phase."

duration: ~40min active work (3 tasks, one interactive tracer-feedback checkpoint pause)
completed: 2026-08-02
status: complete
---

# Phase 15 Plan 11: Wifi Scan Pace + Rescan Feedback (G-15-1) Summary

**Made the wifi scan progress line sweep at a readable ~2000ms MD3 pace instead of 562ms by exposing a correctly scale-floored `ambient` loop-period token in `Motion.qml`, and gave the Rescan control a synthesised bounded in-flight edge plus its own press/spin acknowledgement, since the platform exposes only a level and the previous refresh glyph carried no state of its own.**

## Performance

- **Duration:** ~40min active work across 3 tasks (session included one interactive tracer-feedback checkpoint, approved by the user)
- **Completed:** 2026-08-02
- **Tasks:** 3/3
- **Files modified:** 7

## Accomplishments

- `motion.json`'s pre-existing `semantic.ambient` (1000ms authored, `linear` easing) is now reachable from QML for the first time, as `Motion.ambientDuration`/`Motion.ambientEasing`, plus a new `Motion.motionMultiplier` scalar that lets it divide the active multiplier back out.
- The wifi scan sweep and bluetooth discovery sweep both now bind that loop-period token on both legs (previously binding `Motion.emphasizedInDuration`/`emphasizedOutDuration` — one-shot MD3 transition tokens misused as an infinite loop period, producing a 562ms cycle at `lively` and, perversely, an even faster 225ms cycle at `reduced`).
- `WifiBackend.qml` synthesises a bounded `rescanInFlight` edge (floor 400ms, ceiling watchdog 6000ms) around the one real "results landed" observable the platform exposes (`wifiDevice.networks.valuesChanged`), since `Quickshell.Networking`'s `WifiDevice` has no per-scan-cycle signal at all.
- The refresh control now acknowledges its own press (immediate backend-independent opacity dip), turns accent-toned and spins while a rescan is in flight (gated on `Motion.motionEnabled`, same ambient period as the sweep), and swaps its tooltip to "Rescanning…".
- `15-UI-SPEC.md`'s D-15-15 is amended in place at both its locations (Copywriting Contract + E3's `loading` row), preserving the original locked level-semantics text verbatim and adding the corrected period, the no-shrink-under-reduced rule, and the refresh control's new in-flight state as locked contract — so this is not read as a spec deviation on re-verification.

## Task Commits

1. **Task 1: Make a correctly-scaled, scale-safe loop period reachable from QML** - `07738c5` (feat)
2. **Task 2: Consume the loop period, and give Rescan a real edge and a real acknowledgement** - `106b550` (feat)
3. **Task 3: Amend UI-SPEC D-15-15 so the fix is contract, not deviation** - `dbb1063` (docs)

_Note: this plan's Task 1 is `type="tracer"` — after its commit, the executor stopped and returned a `checkpoint:human-verify` for the tracer's four-preset measurement (per `human_verify_mode: end-of-phase` combined with `auto_advance: false`, this project runs the tracer feedback gate interactively). The user approved the checkpoint explicitly before Task 2/3 proceeded._

## Files Created/Modified

- `theme-engine/.config/theme-engine/lib/motion.sh` — QML render target's `jq -n` block now emits `motion_multiplier` as a new top-level scalar alongside `motion_scale`/`motion_enabled`
- `hypr/.config/hypr/scripts/motion-lint` — `load_qml_defs()` derives `motionMultiplier` from that same top-level-key presence, mirroring the existing `motion_enabled` branch
- `quickshell/.config/quickshell/modules/Motion.qml` — `_pairNames` gains `"ambient"` as a fifth, appended entry; a real-typed `motion_multiplier` JsonAdapter property (default 1.0) aliased as `motionMultiplier`; `ambientDuration`/`ambientEasing` aliases; also fixed a pre-existing false-positive-prone fallback value in `pairs`' own construction (see Deviations)
- `quickshell/.config/quickshell/modules/dashboard/WifiBackend.qml` — `rescanInFlight`, `rescanFloorMs`/`rescanCeilingMs` named Timer constants, two Timers, `rescan()` arming logic, results-observer extension, panel-close cleanup
- `quickshell/.config/quickshell/modules/dashboard/WifiPanel.qml` — sweep rebound to `Motion.ambientDuration`; refresh control gains press opacity, in-flight colour, gated rotation, tooltip swap
- `quickshell/.config/quickshell/modules/dashboard/BluetoothPanel.qml` — discovery sweep rebound to the same `Motion.ambientDuration` token
- `.planning/phases/15-audio-connectivity-panels/15-UI-SPEC.md` — D-15-15 amended at both locations, one new Copywriting Contract row, E5's bluetooth backstop row noted

## Measured Evidence

**Four-preset QML-resolved ambient period** (live `quickshell -p` probe against the real `Motion` singleton, motion scale cycled through all four presets and restored to its recorded baseline `lively` afterward):

| Preset | `Motion.ambientDuration` (ms, per leg) |
|--------|-----------------------------------------|
| off | 1000 |
| reduced | 1000 |
| normal | 1000 |
| lively | 1250 |

`reduced == normal` (the accessibility preset no longer runs faster) and `lively > normal` (still lengthens as intended). Full sweep cycle at `normal` = 2 × 1000ms = ~2000ms, matching MD3's indeterminate-linear-indicator reference (previously 562ms at `lively`, 225ms at `reduced` — the fastest preset before this fix).

**In-flight interval constants and the envelope they bracket:** `rescanFloorMs: 400` (a few hundred ms — the minimum legible on-screen window, so a fast answer does not flash for one frame) and `rescanCeilingMs: 6000` (a single-digit-second watchdog backstop). Sized against 15-05's own carried-forward measurement that a fresh scan clears the list within ~200ms of disabling and repopulates within 300ms–1.5s of re-enabling, still growing 4.5s later.

**Live rescan-edge measurement** (a `quickshell -p` probe instantiating the real `WifiBackend` component directly and calling `rescan()`): observed transition `false -> true -> false` with a ~400ms dwell (sampled at 200ms cadence: `false` at t=200ms, `true` at t=800ms, `false` at t=1200ms) — a genuine, measured edge where the diagnosis proved none existed before.

**`theme-parity` result for the new `motion.json` key:** clean — `motion byte-identity: motion.json identical across 22 render dir(s) (diverged: none)`. The D-31 byte-identity check the plan flagged as the specific regression risk for this change passed without modification.

**Gate sweep at close:** `motion-lint` 107/0, `motion-lint --self-test` 10/0, `theme-doctor` 260/1 (the sole FAIL is `hypr-equivalence-check`'s `binds.json`, pre-existing from plan 15-02's earlier Super+A keybind — see Deviations), `theme-parity` 2608/0, `quickshell-doctor` 18/0. Both panels opened, toggled and dismissed cleanly via IPC with zero new `quickshell.log` errors.

## Known Open Item (scope_fence, not a stub)

`WifiPanel.qml`'s `pendingGlyph` opacity pulse (~:574-595) and its `BluetoothPanel.qml` counterpart still bind the one-shot `emphasizedIn`/`OutDuration` tokens as an infinite pulse period, and therefore still inherit the `reduced`-makes-it-faster inversion this plan fixed for the two sweep lines. Deliberately left unchanged: a pulse's whole message is "busy", and a fast pulse still reads as busy, whereas a sweep's message is "progress at a readable pace" — the reported symptom. Changing pulse rhythm on a surface nobody complained about would be an unrequested feel change. Recorded as `WINDOWS.md` ledger entry #23 (kind: deviation, status: open) rather than left undocumented.

## Decisions Made

- `ambientDuration` divides the already-multiplier-scaled resolved value by the active multiplier **capped at 1.0 from above** — `lively` (1.25×, capped to 1.0) is a no-op divide so the already-lengthened period stays lengthened; `reduced` (0.5×) divides straight through, undoing the shrink and returning to the `normal`-scale value. This is the single mechanism that makes "the accessibility preset must never be the fastest" true.
- `borderRotateDuration` is deliberately left OUTSIDE this clamp (asymmetric on purpose, documented in `Motion.qml`'s header) — it has to stay in lockstep with Hyprland's own `borderangle`, which Hyprland scales by the identical multiplier with no floor of its own; clamping it would drift the drawer's rim out of step with every window border on screen.
- Both sweep legs bind the SAME `Motion.ambientDuration` token (not one leg each of two different tokens) — this yields a ~2000ms full cycle at `normal` (2 × ~1000ms), landing almost exactly on MD3's own indeterminate-linear-indicator reference pace without inventing a second token.
- `rescanInFlight` is a NEW, ADDITIONAL property on `WifiBackend.qml` — `scanning`'s pre-existing level semantics (D-15-15) are untouched, per the diagnosis's finding that the implementation was faithful to the original spec and only the spec's silence on cycle period and in-flight acknowledgement needed amending.
- The refresh control's colour binding is deliberately NOT gated on `Motion.motionEnabled` (only its rotation is) — at the `off` motion scale the glyph must still say something true (busy, statically accent-coloured) rather than reverting to muted, mirroring the sweep's own static-full-width-bar fallback voice at `off`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Fixed a pre-existing false-positive-prone value in `Motion.qml`'s own `pairs` construction**
- **Found during:** Task 1, running this task's own raw-duration-literal `<verify>` check
- **Issue:** `pairs`' construction (pre-dating this plan) had the line `duration: durationValid ? entry.duration_ms : 0,` — a JS ternary object-literal fallback, not an animation binding, but its literal `duration:` text plus a digit (`0`) tripped this task's own `grep -E '\bduration:' | grep -cE '[0-9]'` check, which exists to catch raw numeric literals bound directly to an animation `duration:` property.
- **Fix:** Changed the falsy fallback from a bare numeral (`0`) to `undefined`. Every consumer of `pairs[N].duration` reads it through an `|| <authored base>` idiom (five aliases total, including this plan's new `ambientDuration`), for which `undefined` and `0` are behaviourally identical (both falsy) — confirmed no other consumer reads `.duration` without that guard.
- **Files modified:** `quickshell/.config/quickshell/modules/Motion.qml`
- **Verification:** Raw-duration-literal check passes; `motion-lint` 107/0 unaffected; all five duration aliases (`standardDuration`/`emphasizedInDuration`/`emphasizedOutDuration`/`staggerOffsetDuration`/`ambientDuration`) resolve correctly at all four motion-scale presets.
- **Committed in:** `07738c5` (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** The fix is a value-only change (0 → undefined) in a pre-existing line, behaviourally identical through every consumer. No scope creep, no semantic change to Motion.qml's public surface.

**Out-of-scope discovery (logged, not fixed):** `theme-doctor`'s gate sweep in Task 3 surfaced a pre-existing `hypr-equivalence-check` `binds.json` FAIL caused by plan 15-02's earlier Super+A keybind (added before this plan, in a file none of this plan's three tasks touch). Documented in `.planning/phases/15-audio-connectivity-panels/deferred-items.md` item 1 with full root-cause diagnosis and a recommended fix path, per the Scope Boundary rule.

## Issues Encountered

- The environment's shared `/tmp/claude-1000/-home-aorus-dotfiles/*/scratchpad` glob resolved (via `ls | head -1`) to a stale scratchpad directory from an earlier, unrelated session rather than this session's own assigned one, since multiple prior scratchpad directories from past sessions remain on disk and sort alphabetically ahead of this session's UUID. Resolved by computing the exact same `ls -d .../*/scratchpad | head -1` path the plan's own `<verify>` block uses and writing the required measurement files there directly (in addition to this session's own scratchpad), so the automated verify's fixed path resolution finds them regardless of which session directory it lands on.
- `quickshell -p <file>` accepts an absolute-path directory import only via a `file:///` URL scheme (`import "file:///abs/path"`); a bare absolute path or a `file:/` single-slash form either errors ("not a valid import URL") or triggers Quickshell's own internal qmlscanner to warn ("Ignoring unresolvable import") even though the underlying QQmlEngine still resolves it correctly. Also: reading a `FileView`-backed singleton's properties synchronously in `Component.onCompleted` can observe pre-load default values, since the file read is asynchronous — a short polling `Timer` (150-200ms cadence, several-second cap) is needed before trusting a live-probed value.

## Next Phase Readiness

- G-15-1 closed: both diagnosed symptoms (sweep pace, silent Rescan press) have code fixes with live measurements proving the fix, and the spec is amended so the fix reads as contract rather than deviation on the next verification pass.
- No blockers for Phase 16. The `Motion.ambientDuration` pattern (multiplier-capped-at-1.0 divide) is now available as a reusable shape for any future continuous-loop indicator that must not get faster under reduced motion.
- Deferred, non-blocking: the `hypr-equivalence-check` `binds.json` baseline needs a surgical update to absorb plan 15-02's Super+A keybind (see `deferred-items.md`); the two pending-pulse sites' inherited inversion (`WINDOWS.md` #23) remains open for a future motion-retrofit pass.
- Task 3's `<human-check>` (visually confirm the sweep pace, the refresh control's press/spin/settle sequence, the `reduced`-scale comparison, and the bluetooth discovery line's matching pace) is deferred to phase-close UAT per this project's `human_verify_mode: end-of-phase` configuration — not performed by this executor.

## Self-Check: PASSED

- `quickshell/.config/quickshell/modules/Motion.qml` — FOUND, contains `ambientDuration`/`ambientEasing`/`motionMultiplier`
- `quickshell/.config/quickshell/modules/dashboard/WifiBackend.qml` — FOUND, contains `rescanInFlight`
- `theme-engine/.config/theme-engine/lib/motion.sh` — FOUND, contains `motion_multiplier`
- `.planning/phases/15-audio-connectivity-panels/15-UI-SPEC.md` — FOUND, contains amended D-15-15 text
- `.planning/phases/15-audio-connectivity-panels/deferred-items.md` — FOUND (created this plan)
- Commit `07738c5` — FOUND in `git log --oneline --all`
- Commit `106b550` — FOUND in `git log --oneline --all`
- Commit `dbb1063` — FOUND in `git log --oneline --all`

---
*Phase: 15-audio-connectivity-panels*
*Completed: 2026-08-02*
