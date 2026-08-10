---
phase: 14-dashboard-drawer
plan: 10
subsystem: ui
tags: [quickshell, qml, weather-glyph, gpu-dial, nvidia-smi, hyprland-lua, regression-gate, render-gate, phase-close]

# Dependency graph
requires:
  - phase: 14-09
    provides: "Phase-close gate sweep, Design.qml/WeatherPalette.qml singletons, and the two carried-forward render-gate requests this plan promotes (deferred-items.md Items A and B)"
  - phase: 14-07
    provides: "WeatherTab.qml's three composed condition-glyph sites (hero, hour strip, day row) and the WMO condition table"
  - phase: 14-06
    provides: "SystemResources.qml's zero-idle polling architecture and Dial.qml, which the fifth dial extends"
  - phase: 13.1
    provides: "The Hyprland Lua migration, its .hypr-baseline capture, and the two open uncovered.txt divergences (binds.json:mouse, binds.json:keycode) this plan closes one of"
provides:
  - "ConditionGlyph.qml — a layered two-tone composite weather glyph for exactly two conditions, behind a one-property revert (layeringEnabled)"
  - "A fifth Performance dial — GPU utilisation and VRAM via nvidia-smi, at its own slower subprocess cadence, always present with a designed no-GPU state (DASH-09)"
  - "hypr-equivalence-check repaired from 65 difference lines to green: surgical one-record re-baseline, a narrow named mouse-field forgiveness, and a count-mismatch readability diagnostic"
  - "hypr-equivalence-check folded into theme-doctor behind a live-session guard, making the Hyprland Lua regression gate part of the standard rerunnable sweep"
  - "Closure of the binds.json:mouse divergence open since Phase 13.1 — confirmed cosmetic by the human compensating check, not a functional regression"
affects: [phase-15, phase-16, phase-17]

tech-stack:
  added: []
  patterns:
    - "Layered two-glyph composite icon (base glyph + differently-coloured overlay glyph) as the route to per-element colour in a monochrome icon font, scoped to a named composite map and gated behind a single boolean revert"
    - "Subprocess-backed metric in a zero-idle reader: its own named poll interval, deliberately slower than the /proc-read metrics, with in-flight-sample skipping rather than queueing"
    - "Narrow, named, poison-tested field forgiveness (MOUSE_FORGIVEN_KEYS) as the resolution shape for a documented serialization divergence — held PROVISIONAL in source until a human compensating check runs, then promoted"
    - "Surgical single-record baseline amendment (insert the one genuinely-new record, prove all pre-existing records byte-identical) instead of a wholesale re-capture that would silently bless unrelated divergences"

key-files:
  created:
    - quickshell/.config/quickshell/modules/dashboard/ConditionGlyph.qml
  modified:
    - quickshell/.config/quickshell/modules/dashboard/WeatherTab.qml
    - quickshell/.config/quickshell/modules/dashboard/WeatherPalette.qml
    - quickshell/.config/quickshell/modules/dashboard/qmldir
    - quickshell/.config/quickshell/modules/dashboard/PerformanceTab.qml
    - quickshell/.config/quickshell/modules/dashboard/SystemResources.qml
    - hypr/.config/hypr/scripts/hypr-equivalence-check
    - theme-engine/.config/theme-engine/theme-doctor
    - .planning/phases/13.1-hyprland-lua-config-migration/.hypr-baseline/binds.json
    - .planning/phases/13.1-hyprland-lua-config-migration/.hypr-baseline/MANIFEST.md
    - .planning/phases/13.1-hyprland-lua-config-migration/.hypr-baseline/uncovered.txt
    - .planning/phases/14-dashboard-drawer/deferred-items.md
    - .planning/PROJECT.md

key-decisions:
  - "Layered two-tone glyph KEPT — the human's comparative verdict at the render gate was that it reads better than Material's single purpose-drawn composite, so the built revert was not taken"
  - "GPU dial ring colour revised TWICE: primaryContainer proved byte-identical to the dials' own unfilled track (#44475a, invisible), so Task 2 fell back to sharing primary with CPU; the gate's dial reorder then made those two adjacent and identically pink, so it moved again to Colours.outline"
  - "Dial order set by the human at the gate: GPU, CPU, Memory, Storage, Battery"
  - "Network rate row widened from two flush-left minimum-width cells to two equal halves spanning the full dial-grid width, each readout anchor-centred, with the fixed inner text width preserved so the anti-reflow guarantee still holds"
  - "The baseline was amended surgically (one inserted record) rather than re-captured wholesale, specifically so the mouse-field divergence could NOT be silently blessed before a human settled it"
  - "The mouse-field forgiveness was held PROVISIONAL in source until the human drag check ran, then promoted to CONFIRMED — the check passed, so the divergence is cosmetic"

patterns-established:
  - "Composite-glyph map: a two-entry named map keyed on ligature name, so a layered treatment can never silently spread to conditions it was not designed for"
  - "Gate forgiveness lifecycle: add narrow rule -> poison-test it two ways -> mark PROVISIONAL with the compensating check named in uncovered.txt -> promote or revert in the session the check runs"

requirements-completed: [DASH-05, DASH-06, DASH-09, MAINT-04]

coverage:
  - id: D1
    description: "The two composite weather conditions render as two layered glyphs in two colours, at all three composed sites; every other condition byte-unchanged"
    requirement: "DASH-06"
    verification:
      - kind: manual_procedural
        ref: "14-10 Task 4 render gate, check 1 — comparative verdict against the single designed composite glyph"
        status: pass
    human_judgment: true
    rationale: "The plan states the deciding criterion as a comparative aesthetic judgement ('reads BETTER than the single purpose-drawn glyph'), which no script can settle. Recorded as a backstop truth in the plan itself."
  - id: D2
    description: "The layered stack occupies the same box as the glyph it replaces — Weather tab frame unchanged"
    requirement: "DASH-06"
    verification:
      - kind: integration
        ref: "hyprctl -j layers live frame read on the Weather tab (prior session, commit 5fe30c6)"
        status: pass
    human_judgment: false
  - id: D3
    description: "A fifth GPU dial on the Performance tab — utilisation ring plus VRAM detail — with the panel width unchanged"
    requirement: "DASH-09"
    verification:
      - kind: integration
        ref: "hyprctl -j layers frame read (1040 width held) + live screenshot of the five-dial row"
        status: pass
    human_judgment: false
  - id: D4
    description: "GPU sampling is zero-idle and never overlaps: no query processes while the drawer is dismissed, in-flight ticks skipped not queued"
    requirement: "DASH-09"
    verification:
      - kind: integration
        ref: "sustained process-count watch with drawer dismissed + deliberate skip-path exercise (prior session, commit 14d4044)"
        status: pass
    human_judgment: false
  - id: D5
    description: "The GPU dial is always present with a designed no-GPU state, proven three ways at the reader's binary seam"
    requirement: "DASH-09"
    verification:
      - kind: integration
        ref: "scratch-copy fault injection: binary absent / no devices / non-zero exit (prior session, commit 14d4044)"
        status: pass
    human_judgment: false
  - id: D6
    description: "Five dials at d=176 / ring 17 read comfortably rather than crammed, and the detail lines stay legible"
    requirement: "DASH-09"
    verification:
      - kind: manual_procedural
        ref: "14-10 Task 4 render gate, check 2 — human verdict 'just right'"
        status: pass
    human_judgment: true
    rationale: "Legibility-at-size is the exact judgement the gate exists for; the plan names no mechanical threshold for 'crammed'."
  - id: D7
    description: "hypr-equivalence-check is green and folded into theme-doctor behind a live-session guard"
    requirement: "MAINT-04"
    verification:
      - kind: integration
        ref: "hypr-equivalence-check: PASS 3 FAIL 0 exit 0; theme-doctor: 236 passed, 0 real failures"
        status: pass
    human_judgment: false
  - id: D8
    description: "The binds.json:mouse divergence open since Phase 13.1 is settled — drag-move and drag-resize confirmed working, forgiveness promoted from PROVISIONAL to CONFIRMED"
    requirement: "MAINT-04"
    verification:
      - kind: manual_procedural
        ref: "14-10 Task 4 render gate, check 5 — Super+left-drag MOVES, Super+right-drag RESIZES, on a floating window"
        status: pass
    human_judgment: true
    rationale: "No evdev/uinput mouse-button injection tool exists in this environment, and hyprctl keyword is refused under a Lua config manager — a physical drag by a human is the only available oracle. This is recorded in uncovered.txt as the named compensating check."
---

# Plan 14-10 Summary

Two carried-forward render-gate requests from 14-09, one newly-minted requirement
(DASH-09), and a regression gate that was missing from the phase sweep entirely and
red for two independent reasons.

## Provenance note — read this before trusting the evidence below

Tasks 1–3 executed in a **prior session** and are recorded here from their commits
and from `STATE.md`'s checkpoint record; their live evidence (frame reads, process
counts, fault injections) is as those commits recorded it, not re-observed here.
Task 4 — the blocking human render gate and everything it produced — ran in **this**
session and its evidence is first-hand. Each section below says which it is. The
prior session ended at Task 4's gate with the desktop idle-locked; nothing was
self-approved.

## Performance

| Task | Commit | Session |
|------|--------|---------|
| 1 — two-tone composite weather glyphs | `5fe30c6` | prior |
| 2 — fifth GPU dial (DASH-09) | `14d4044` | prior |
| 3 — hypr-equivalence-check repair + fold | `b541783` | prior |
| 4 — render gate, round 1 changes | `be6f19e` | this |
| 4 — forgiveness promotion + outcomes | `cc28fb1` | this |

## Accomplishments

- The two "sun with clouds" conditions — day and night, and only those two — render
  as a sun/moon glyph in the palette's own colour with a lit-cloud glyph layered on
  top. Every other condition is untouched.
- The Performance tab gained a fifth dial: GPU utilisation with VRAM used/total,
  sampled only while the drawer is open, on its own slower cadence because it is a
  subprocess spawn rather than a pseudo-file read.
- `hypr-equivalence-check` went from 65 difference lines to green, and is now part
  of `theme-doctor`'s standard sweep.
- A divergence open since Phase 13.1 — whether the Lua migration silently broke
  window drag-move and drag-resize — was finally settled. It did not.

## Task 4 — the render gate (this session)

### What the gate returned

| Check | Verdict |
|-------|---------|
| 1 — layered glyph, comparatively | **Better.** Keep it. No tuning requested. |
| 2 — five dials at d=176 | **"Just right."** Not crammed; knobs untouched. |
| 3 — GPU ring colour | Revised (see below), separation approved. |
| 4 — nothing else moved | Folded into approval. |
| 5 — drag-move / drag-resize | **Both work.** Divergence is cosmetic. |
| 6 — gate repair sanity | Folded into approval. |

### Two changes the gate asked for

**Dial order.** The human set the sequence explicitly: GPU, CPU, Memory, Storage,
Battery. `Grid` lays out in declaration order, so this was a block move — no layout
arithmetic changed, and the five-across geometry and 1040px frame are untouched.

**Network rate row centred and widened.** It had been sitting flush-left at its
measured minimum: two ~150px cells in a 944px row, leaving roughly half the row
dead. It now splits into two equal halves spanning the full dial-grid width, each
readout anchor-centred in its own half. Each cell became an `Item` wrapping its
`Column` precisely so the content *can* be anchor-centred — anchoring inside a
positioner is the conflict this file's own `contentColumn` note already documents.
The inner value `Text` keeps its fixed `rateCellWidth`-derived width, so round 2's
anti-reflow guarantee is preserved: the readout is re-centred, never re-measured.

### The adjacency defect the reorder exposed

This was not requested — it was found by rendering the result and looking at it.

Task 2 had already revised the GPU ring colour once: the plan's default choice,
`primaryContainer`, reads `#44475a` under dracula, **byte-identical to
`surfaceVariant`** — the unfilled track colour every dial's arc sits on. The value
arc was not subdued, it was invisible. Task 2 fell back to the recorded alternative,
sharing `primary` with CPU as "the two compute dials".

The reorder then placed GPU first and CPU second, making those two identically-pink
rings adjacent, where they read as a duplicate rather than as a pair. Rendered both
ways and compared live; the human chose the separation. GPU is now
`Colours.outline` (#6272a4) — the one remaining contract role neither taken by
another dial nor colliding with the track.

**Carry forward:** this token set defines only four vivid non-neutral roles
(`primary`/`secondary`/`tertiary`/`error`) for a now five-dial row. A sixth dial
would have no distinct role left at all.

### Check 5 — the question open since Phase 13.1, now closed

Phase 13.1 recorded that the two `bindm` mouse-drag binds read back `mouse:false`
under the Lua config where the pre-migration baseline recorded `true`, could not
determine whether that was cosmetic or a real break, deliberately left the gate
FAILING on it rather than loosening, and named a human drag as the way to settle it.
Nobody had run it since. Task 3 added a narrow forgiveness and marked it
**PROVISIONAL**, staked entirely on this check.

**The check ran and passed.** On a floating window, Super+left-drag moves and
Super+right-drag resizes. The divergence is cosmetic; the forgiveness is promoted to
CONFIRMED in both the gate source and `uncovered.txt`.

Corroborating evidence gathered this session and recorded in both places so it is
never re-derived:

- `SKeybind` (hyprland 0.56.1, `KeybindManager.hpp`) carries **three** distinct
  fields — `mouse`, `click`, `drag` — while `hyprctl -j binds` serializes only
  `mouse`. `hl.dsp.window.drag()` setting `drag` instead would produce exactly this
  false reading, which is why the field was never a sound proxy for the behaviour.
- `keybinds.lua`'s two `bindm` lines are **byte-identical to hyprland 0.56.1's own
  bundled example config**; `hyprctl configerrors` is empty.
- All 81 live binds report `dispatcher="__lua"`, so that field is not a
  discriminator either.
- `hyprctl keyword` is refused under a Lua config manager (*"keyword can't work with
  non-legacy parsers. Use eval."*), so a classic `bindm` cannot be injected at
  runtime as a cross-check, and no evdev/uinput injection tool is installed. Recorded
  for any future attempt.

## Verification run this session

| Check | Result |
|-------|--------|
| `hypr-equivalence-check` | PASS 3, FAIL 0, exit 0 |
| `theme-doctor` (full sweep) | 236 passed, 0 real failures |
| `qmllint` on `PerformanceTab.qml` | clean |
| Material Symbols font resolves | confirmed (gate precondition) |
| Five-dial row + centred rate row | screenshotted live, both colour states |
| quickshell health | running, hot-reloaded cleanly |

`theme-doctor`'s single FAIL during the run was its own `git status --porcelain is
empty` check, tripped by the then-uncommitted work; `cc28fb1` resolves it.

## Deviations from Plan

1. **GPU ring colour is `Colours.outline`, not the planned `primaryContainer` nor
   the recorded fallback `primary`.** Two successive revisions, both evidence-driven
   and both recorded above. The plan's own text still describes the fifth ring as
   taking "the one unused non-neutral theme role" — that description was stale by
   Task 2 and is superseded by this summary and by `PerformanceTab.qml`'s in-source
   note.
2. **Dial order and the network-row widening are new scope**, minted at Task 4's
   gate in the same way DASH-09 itself was minted at 14-09's gate. Both are recorded
   in `deferred-items.md` Item B's outcome section.
3. **No tuning of the layered glyph.** The plan anticipated possible retuning (sun
   size, cloud size, offset, outlined-vs-filled) or a revert; the gate asked for
   none, so `layeringEnabled` stays `true` and the built revert stays in place as
   the documented fallback.

## Known Stubs

None.

## Threat Flags

None. The `nvidia-smi` invocation added in Task 2 is a fixed-argument query with no
interpolated input.

## User Setup Required

None. The GPU dial degrades to a designed "No GPU" state on machines without an
NVIDIA adapter, so nothing host-specific is required for reproduction.

## Next Phase Readiness

Phase 14's plans are all complete. Two items are worth carrying forward:

- The four-vivid-role ceiling on the dial row (above) — relevant to any future
  Performance-tab metric.
- `deferred-items.md`'s 14-03 item (`quickshell-doctor` headless-output-remove
  FAIL, QS-03 territory) remains open and untouched by this plan.

## Self-Check: PASSED
