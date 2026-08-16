---
phase: 21-media-fold-in-contract-close
plan: 02
subsystem: infra
tags: [gate-01, behaviour-baseline, parity-checklist, ags, media, retirement, quickshell]

# Dependency graph
requires: []
provides:
  - "21-BEHAVIOUR-BASELINE.md — the GATE-01 behavioural enumeration of the retiring AGS media card, read off the LIVE running implementation (PIDs 1705/1796/1990), plus the Parity Checklist half of D-21-20's combined deletion gate"
  - "A named, unwaived parity gap (C-11, the per-track seekability latch) that Plans 21-05 through 21-09 must close or explicitly re-verify before deletion"
affects: [21-05-media-parity, 21-06-visualiser-expansion, 21-07-retirement, 21-08-contract-close, 21-09-verification]

actuals:
  tokens: 8053
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "GATE-01 Recurrence Protocol, second application (after Phase 18's waybar baseline) — six-step behavioural enumeration off a live, still-running surface, never source alone, closed by a mechanical Unaccounted Keys loop"
    - "Parity Checklist as a machine-readable verdict line (`Parity: N/N SATISFIED, M GAP`) a combined deletion gate reads rather than re-derives"

key-files:
  created:
    - .planning/phases/21-media-fold-in-contract-close/21-BEHAVIOUR-BASELINE.md
  modified: []

key-decisions:
  - "Live-summoned the AGS card twice this session (ags request -i media toggle-media, open then close) and cross-confirmed its ags-media layer-shell surface via hyprctl layers -j (DP-1, x=1049 y=54 w=462 h=422) rather than relying on source alone — the plan's own prohibition against a source-only read"
  - "Found a genuine, previously-unrecorded parity gap: MediaBackend.qml has no per-track seekability latch analogous to lib/media.ts's trackKeyOf/updateSeekLatch pair — canSeek/lengthSeconds are recomputed fresh on every reactive read with no mechanism to survive a transient zero-length MPRIS report mid-track. Marked GAP (C-11), not waived, per D-21-11's build-before-delete rule; the live Firefox/YouTube track playing during this session genuinely exhibited the exact transient condition (length:0, can_seek:false) the old latch existed to survive"
  - "Split the single behaviour-baseline file into two atomic commits along the task boundary (Provenance/Capabilities/Dead-Definitions/Unaccounted-Keys/Not-a-Port-Spec for Task 1; Parity Checklist for Task 2) by truncating and restoring the file, since both tasks' <files> declare the same single artifact"
  - "Marked the volume row's visibility-gating divergence (QML hides it for hasVolume:false, AGS always rendered it) as SATISFIED rather than GAP — the underlying capability (adjust volume where supported) is fully present, and hiding a non-functional control matches this project's own standing precedent (\"a panel must never offer a control that cannot work\")"
  - "Per-player volume (D-21-10) explicitly labelled as an addition beyond parity in its own checklist paragraph, kept out of the Parity: N/N verdict, so its current absence from MediaBackend.qml is never mistaken for an unaccounted parity gap"

patterns-established:
  - "Symbol-to-capability mechanical closure loop (bash associative array, VALID_IDS allowlist) as the Unaccounted Keys proof shape for a TS/TSX source surface, mirroring Phase 18's JSON-key closure shape for a JSONC surface"

requirements-completed: [QMEDIA-01, RETIRE-06]

coverage:
  - id: D1
    description: "GATE-01 behavioural enumeration of the retiring AGS media card, taken off the live running implementation with all five required sections (Provenance, Capabilities, Dead Definitions, Unaccounted Keys, Not a Port Specification)"
    requirement: "RETIRE-06"
    verification:
      - kind: other
        ref: "bash -c 'grep -qF \"## Provenance\" ... for each of the five required sections' — all present"
        status: pass
      - kind: other
        ref: "bash -c 'wc -l 21-BEHAVIOUR-BASELINE.md' -ge 120 (actual: 267)"
        status: pass
      - kind: other
        ref: "bash -c 'pgrep -f \"ags run\"' — live surface confirmed running throughout"
        status: pass
    human_judgment: false
  - id: D2
    description: "Parity Checklist mapping every capability to a named MediaTab.qml/MediaPopout.qml affordance or an explicit GAP, closed with a machine-readable Parity: N/N verdict line"
    requirement: "QMEDIA-01"
    verification:
      - kind: other
        ref: "bash -c 'grep -qE \"^Parity: [0-9]+/[0-9]+ SATISFIED, [0-9]+ GAP\"' — matched \"Parity: 15/16 SATISFIED, 1 GAP\""
        status: pass
      - kind: other
        ref: "bash -c 'grep -icE \"accepted loss|waived|will not be (built|ported)|not worth\"' — 0 hits after one wording fix"
        status: pass
      - kind: other
        ref: "bash -c 'grep -cE \"MediaTab\\.qml|MediaPopout\\.qml\"' -ge 5 (actual: 15)"
        status: pass
    human_judgment: false

duration: ~11min
completed: 2026-08-16
status: complete
---

# Phase 21 Plan 02: GATE-01 Behaviour Baseline and Parity Checklist Summary

**Enumerated the live AGS media card's full behaviour (16 capabilities, 2 dead definitions) off the running daemon and derived a parity checklist that found one real, unwaived gap — no per-track seekability latch in the QML replacement — before any deletion work can proceed.**

## Performance

- **Duration:** ~11 min
- **Started:** 2026-08-16T05:00:34Z
- **Completed:** 2026-08-16T05:11:36Z
- **Tasks:** 2
- **Files modified:** 1 (created)

## Accomplishments

- Summoned the live AGS daemon (PID 1705, gjs PID 1796, cava PID 1990) twice via `ags request -i media toggle-media`, cross-confirming the `ags-media` layer-shell surface's live appearance/disappearance through `hyprctl layers -j` (DP-1, x=1049 y=54 w=462 h=422) rather than reading source alone
- Enumerated 16 gesture-and-observation capability rows (open/close, click-away, Escape, metadata, cover art, cava underlay, transport x3, seek, seekability latch, volume, player switcher, live re-color, layer-rule frost, safe no-op empty state) and 2 dead definitions (dead reachability since Phase 18's waybar retirement; an unused `can_seek` payload field)
- Closed `## Unaccounted Keys` with a real, run bash loop over all 40 top-level symbols across the card's five source files (`MediaWindow.tsx`, `Cava.tsx`, `lib/cava.ts`, `lib/media.ts`, `app.tsx`) — output mechanically confirmed empty (`unaccounted: 0`)
- Derived the `## Parity Checklist`: 14 SATISFIED, 2 SATISFIED-BY-SUPERSESSION (cava underlay superseded by Plans 01/06's radial visualiser; live re-color superseded by QML's native `Colours.qml` hot-reload), 1 GAP — verdict `Parity: 15/16 SATISFIED, 1 GAP`
- Found and recorded a genuine parity gap live: `MediaBackend.qml` has no equivalent of `lib/media.ts`'s per-track seekability latch, and the session's own live Firefox/YouTube track was actively exhibiting the exact transient `length:0`/`can_seek:false` condition that latch exists to survive
- Explicitly separated per-player volume (D-21-10) as an addition beyond parity so its current absence isn't mistaken for an unaccounted gap

## Task Commits

Each task was committed atomically:

1. **Task 1: Enumerate the live media card's behaviour, off the running surface** - `023940f` (docs)
2. **Task 2: Derive the parity checklist and name every open gap** - `4d0f7c6` (docs)

_Both tasks share a single `<files>` declaration (`21-BEHAVIOUR-BASELINE.md`); the commit was split along the exact task/section boundary (Not a Port Specification vs. Parity Checklist) by truncating then restoring the file, so each commit's diff maps 1:1 to its task's own `<verify>` block passing against that commit's content alone._

## Files Created/Modified

- `.planning/phases/21-media-fold-in-contract-close/21-BEHAVIOUR-BASELINE.md` - The GATE-01 behavioural enumeration (267 lines): Provenance, Capabilities, Dead Definitions, Unaccounted Keys, Not a Port Specification, Parity Checklist

## Decisions Made

- Live-summoned the card twice and cross-confirmed via `hyprctl layers -j` rather than trusting the TSX source's declared `anchor`/`marginTop` alone — the observed `y=54` independently matched the declared `marginTop={54}`, closing the one gap between what a live observation can show (rendered geometry) and what only source shows (declared window properties)
- The volume row's AGS-vs-QML visibility-gating divergence is recorded as a disclosed difference under a SATISFIED status, not a GAP — the actual capability (volume control where supported) is intact, and matching AGS's own "show a slider that does nothing" behaviour would contradict this project's own standing PROJECT.md precedent against non-functional controls
- C-11 (seekability latch) is left as an open, unwaived GAP rather than assumed harmless — Quickshell's native `lengthSupported`/`canSeek` bindings' actual robustness against the same MPRIS transient-drop behaviour is not established by this session (the installed `qmltypes` carries no behavioural documentation beyond property names), so the honest call is to flag it for the build-or-reverify step D-21-11 requires, not to guess it away

## Deviations from Plan

None - plan executed exactly as written. The file-split-into-two-commits mechanic (truncate, verify, commit, restore, verify, commit) was a delivery-mechanics choice to honor the atomic-per-task-commit contract given both tasks declare the same single `<files>` target — not a deviation from the plan's own content requirements.

## Issues Encountered

One `<verify>` failure and fix during Task 2: the initial draft's honest disclosure language ("This is NOT recorded as an accepted loss", "No row is waived, no row is marked as an accepted loss") tripped the plan's own zero-waiver-language grep (`accepted loss|waived|...`) despite being negations, not waivers. Reworded both passages to convey the same meaning (nothing is silently dropped) without the trigger phrases, re-ran the verify block, confirmed `waiver-language hits: 0`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `21-BEHAVIOUR-BASELINE.md` is committed and ready for Plans 21-05 through 21-09 to consume as the parity checklist their own work must satisfy before D-21-20's combined deletion gate can pass
- One concrete, named build-or-reverify item is now on record for whichever plan builds the remaining Media-tab work: C-11's seekability latch. Nothing else in the checklist blocks forward progress — 15 of 16 rows are already SATISFIED against the current tree
- No blockers to this phase's next wave

---
*Phase: 21-media-fold-in-contract-close*
*Completed: 2026-08-16*

## Self-Check: PASSED

- `21-BEHAVIOUR-BASELINE.md` exists on disk: FOUND
- `21-02-SUMMARY.md` exists on disk: FOUND
- Commit `023940f` (Task 1): FOUND in `git log --oneline --all`
- Commit `4d0f7c6` (Task 2): FOUND in `git log --oneline --all`
