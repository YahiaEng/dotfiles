---
phase: 18-qml-bar-retirement-machinery
plan: 02
subsystem: infra
tags: [waybar, jsonc, gate-01, documentation, roadmap]

requires:
  - phase: 18-qml-bar-retirement-machinery (plan 01)
    provides: the QML bar tracer this document's criteria will eventually be judged against (18-19)
provides:
  - "18-BEHAVIOUR-BASELINE.md — the complete GATE-01 enumeration of all four retired waybar layouts, machine-derived, gesture-and-observation criteria, mechanically closed"
  - "Four committed resolved-config snapshots (18-waybar-resolved/*.json), the surviving evidence after 18-20 deletes every source and the resolver itself"
  - "GATE-01 Recurrence Protocol — the surface-agnostic discipline Phases 19, 20, 21 execute as their own opening task"
  - "Three ROADMAP.md Notes bullets (Phases 19, 20, 21) wiring the recurrence discipline into the phases that need it"
affects: [18-19, 18-20, 19, 20, 21]

actuals:
  tokens: 25976
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Gesture-and-observation criterion grammar (ID · Zone·Index · Module · criterion · Layouts · GATE-02 B), with a byte-identical-merge rule compared against jq -S resolved snapshots, never raw .jsonc"
    - "Dead-definition vs stated-absence vs unaccounted-key three-way classification, closing a document's completeness mechanically rather than by claim"

key-files:
  created:
    - .planning/phases/18-qml-bar-retirement-machinery/18-BEHAVIOUR-BASELINE.md
    - .planning/phases/18-qml-bar-retirement-machinery/18-waybar-resolved/athena.json
    - .planning/phases/18-qml-bar-retirement-machinery/18-waybar-resolved/full.json
    - .planning/phases/18-qml-bar-retirement-machinery/18-waybar-resolved/floating.json
    - .planning/phases/18-qml-bar-retirement-machinery/18-waybar-resolved/vertical.json
  modified:
    - .planning/ROADMAP.md

key-decisions:
  - "Criterion IDs referenced anywhere outside their own row-definition (the GATE-02 B Index, the Shared Module Definitions table, cross-layout asides) are cited by module name + layout, never by repeating the literal WB-ID token — Task 1's own acceptance criteria enforces zero duplicate WB-ID tokens across the whole document, which is stricter than 'no duplicate row IDs' and forbids ID-token cross-references entirely"
  - "Five of athena's group/settings members (custom/theme, custom/waybar-layout, custom/font, custom/icon-theme, custom/wallpaper) are absent from waybar-equivalence-check --resolve's own output for athena.json, because the tool's 'used' computation only walks modules-left/-center/-right, never a group's own modules array — worked around via a verified-equivalent re-resolution probe against modules.jsonc directly, documented in Provenance rather than silently patched"
  - "hyprland/workspaces' dead on-click:\"activate\" dispatch (compiled into waybar's C++ Workspace::handleClicked, documented only in config-floating.jsonc's own comment) applies to every layout identically, not just full/vertical as an early draft of this document assumed — corrected before commit"

patterns-established:
  - "Pattern: byte-identical cross-layout merge via jq -S comparison of resolved snapshots, with the merged row physically placed under the first layout (fixed sequence athena→full→floating→vertical) that references it, and every other layout's section citing it by description rather than repeating the row"

requirements-completed: [GATE-01]

coverage:
  - id: D1
    description: "Four machine-resolved waybar config snapshots committed, each byte-identical to a fresh waybar-equivalence-check --resolve run, scanned clean for credential-shaped strings"
    requirement: "GATE-01"
    verification:
      - kind: other
        ref: "diff <(waybar-equivalence-check --resolve config-{L}.jsonc) 18-waybar-resolved/{L}.json — zero output for all four layouts, run live during execution"
        status: pass
    human_judgment: false
  - id: D2
    description: "18-BEHAVIOUR-BASELINE.md enumerates all four layouts as gesture-and-observation criteria (66 unique WB-* IDs), mechanically closed — every top-level key of every resolved snapshot is a criterion, a Dead Definition, or Bar-Level Chrome, with zero unaccounted keys across all four layouts"
    requirement: "GATE-01"
    verification:
      - kind: other
        ref: "closure loop over jq -r keys[] / zone-array / group-modules[] for all four snapshots against the document text — zero misses, run live during execution"
        status: pass
    human_judgment: false
  - id: D3
    description: "GATE-01 Recurrence Protocol authored and wired into ROADMAP.md as one Notes bullet on each of Phases 19, 20, 21 (insert-only diff, zero existing lines removed)"
    requirement: "GATE-01"
    verification:
      - kind: other
        ref: "git diff ROADMAP.md | grep -cE '^-[^-]' == 0; grep -c '**GATE-01 opening task.**' ROADMAP.md == 3 — run live during execution"
        status: pass
    human_judgment: false

duration: ~20min
completed: 2026-08-11
status: complete
---

# Phase 18 Plan 02: GATE-01 Behaviour Baseline Summary

**Enumerated all 66 distinct behaviours across athena/full/floating/vertical waybar layouts as gesture-and-observation acceptance criteria, machine-derived from `waybar-equivalence-check --resolve`, mechanically proven complete (zero unaccounted keys across all four layouts) and indexed against GATE-02's six B-criteria — with the recurrence discipline wired into Phases 19-21 before the source files it read are deleted eight waves from now.**

## Performance

- **Duration:** ~20 min
- **Completed:** 2026-08-11
- **Tasks:** 3
- **Files modified:** 6 (5 created, 1 modified)

## Accomplishments

- Four resolved-config snapshots (`18-waybar-resolved/{athena,full,floating,vertical}.json`) committed, each proven byte-identical to a fresh `--resolve` run and scanned clean for credential-shaped strings — the surviving evidence after `18-20` deletes every source and the resolver itself in one commit, eight waves from now.
- `18-BEHAVIOUR-BASELINE.md` written end-to-end: Provenance, Not a Port Specification, Criterion Grammar (ID namespace/merge/ordering/dead-definition/absence rules), Bar-Level Chrome, all four `## Layout Criteria` sections (35 athena rows, 9 full rows, 11 floating rows, 11 vertical rows, plus 10 cross-layout `WB-ALL` merges — 66 unique criterion IDs total, zero duplicates), Shared Module Definitions (23 `modules.jsonc` entries), Dead Definitions (2: athena's orphaned `tray`, floating's hardware-dead `backlight`), Unaccounted Keys (four explicitly-empty closure lists), and a GATE-02 Criterion B Index mapping B.1-B.6 to substantiating rows.
- Three named high-value findings recorded verbatim before their source is deleted: `config-floating`'s live scroll-to-switch-workspace binding (`hl.dsp.focus`, flagged as an unassigned capability no plan currently owns), the already-dead `light -A 5`/`-U 5` brightness scroll (the evidence D-18-39's verdict rests on), and the vertical layout's 44px stacked-text column shape.
- `## GATE-01 Recurrence Protocol` authored surface-agnostic (six standing rules plus a per-phase surface table) and wired into `ROADMAP.md` as one insert-only `**GATE-01 opening task.**` Notes bullet on each of Phases 19, 20 and 21 — the diff removed zero existing lines and all five v4.0 phase headings survive.

## Task Commits

1. **Task 1: Capture the four machine-resolved configs, then author the criterion grammar and the athena section end-to-end** — `cee0970` (docs)
2. **Task 2: Extend to full, floating and vertical, close the document mechanically, and index it against GATE-02 criterion B** — `a420da4` (docs)
3. **Task 3: Record the GATE-01 recurrence protocol and wire it into Phases 19, 20 and 21** — `f39b613` (docs)

**Plan metadata:** committed as part of this session's final metadata commit (see below).

## Files Created/Modified

- `.planning/phases/18-qml-bar-retirement-machinery/18-BEHAVIOUR-BASELINE.md` — the GATE-01 deliverable; 66 criterion rows, complete closure proof, GATE-02 B index, recurrence protocol
- `.planning/phases/18-qml-bar-retirement-machinery/18-waybar-resolved/athena.json` — resolved `config-athena.jsonc`, 45 top-level keys
- `.planning/phases/18-qml-bar-retirement-machinery/18-waybar-resolved/full.json` — resolved `config-full.jsonc`, 27 top-level keys
- `.planning/phases/18-qml-bar-retirement-machinery/18-waybar-resolved/floating.json` — resolved `config-floating.jsonc`, 24 top-level keys
- `.planning/phases/18-qml-bar-retirement-machinery/18-waybar-resolved/vertical.json` — resolved `config-vertical.jsonc`, 27 top-level keys
- `.planning/ROADMAP.md` — three insert-only Notes bullets (Phases 19, 20, 21)

## Per-Layout Criterion Counts (for 18-19's and 18-20's citation)

| Layout | Zone-array entries | Expanded criteria rows (own prefix) | Cross-layout merges it participates in | Unaccounted keys |
|---|---|---|---|---|
| athena | 14 | 27 (`WB-ATH-01`..`27`) | 8 (`WB-ALL-01`..`08`) | 0 |
| full | 15 | 7 (`WB-FULL-01`..`07`) | 8 (2 new: `WB-ALL-09`,`WB-ALL-10`; 6 shared with athena) | 0 |
| floating | 16 | 11 (`WB-FLOAT-01`..`11`) | 2 (shared with athena: `custom/media`, `custom/wallpaper`, `custom/gaming-mode`, `custom/notification` = 4 total) | 0 |
| vertical | 13 | 11 (`WB-VERT-01`..`11`) | 4 (shared: `hyprland/workspaces`+`tray` with full, `custom/gaming-mode`+`custom/power` with athena) | 0 |

**Totals:** 66 unique `WB-*` criterion IDs (27 ATH + 7 FULL + 11 FLOAT + 11 VERT + 10 ALL), 2 Dead Definitions, 6 GATE-02 B Index rows, 23 Shared Module Definitions.

## GATE-02 Criterion B → Criterion ID mapping (summary; full text in the document)

- **B.1** (readouts) → clock/battery/network/audio/cpu/ram rows across full, floating, vertical, plus the correction that `bluetooth` is athena-exclusive, not full/floating/vertical-sourced as B.1's own text implies.
- **B.2** (click-to-switch workspace) → the athena, full+vertical-merged, and floating `hyprland/workspaces` rows — all four carry the identical dead `on-click: "activate"` dispatch.
- **B.3** (scroll audio/brightness) → floating's `scroll-step: 5` pulseaudio row and vertical's drawer-slider row for audio; the `backlight` Dead Definition for brightness (not demonstrable on this hardware, D-18-39). Flags floating's `hl.dsp.focus` workspace-scroll as a live capability B.3 as written does not cover and no plan currently owns.
- **B.4** (vertical orientation, no truncation) → every `WB-VERT-*` row plus the vertical instances of the merged `hyprland/workspaces` and `tray` rows.
- **B.5** (tray renders + menus) → the full+vertical merged `tray` row and floating's own `tray` row. Athena's `tray` is explicitly **not** evidence — it is a Dead Definition.
- **B.6** (deliberate cuts don't count as regressions) → `## Dead Definitions` in full (athena's `tray`, floating's `backlight`).

## Decisions Made

- **ID-citation constraint discovered and worked around:** Task 1's acceptance criteria requires zero duplicate `WB-[A-Z]+-[0-9]+` tokens across the *entire* document — stricter than "no duplicate row IDs." This forbids citing an already-defined ID anywhere else in prose (cross-references, the GATE-02 Index, the Shared Module Definitions table). Resolved by citing rows everywhere outside their own definition line by module name + layout description instead of by literal ID token. This was caught by running Task 1's own `<verify>` block before committing (per `superpowers:verification-before-completion`), not assumed to pass.
- **Tool-completeness finding, not a plan-scope fix:** `waybar-equivalence-check --resolve`'s "used" computation only walks `modules-left`/`-center`/`-right`, never a group's own `modules` array, so five of athena's `group/settings` members are silently absent from `athena.json` despite being genuinely instantiated by waybar. Documented in Provenance as Rule 1 (bug, found and worked around — not fixed, since this plan touches no code per its own scope boundary), with the substitute values verified byte-identical via a forced re-resolve probe against `modules.jsonc` before being used.
- **Corrected an in-progress draft error before committing:** an early pass of the athena `hyprland/workspaces` row implied the dead click-to-switch dispatch was specific to full/vertical. Re-reading `config-floating.jsonc`'s own comment (the only file that documents the mechanism) showed it applies to every layout identically via the same compiled-in waybar C++ path — corrected in the committed text.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug, worked around not code-fixed] `waybar-equivalence-check --resolve`'s group-member blind spot**
- **Found during:** Task 1, while resolving athena's `group/settings` members
- **Issue:** The tool's "used" set only counts a module referenced directly by a zone array or redefined by the layout itself — it never walks a group's own `modules` array. Athena's `group/settings` lists `custom/theme`, `custom/waybar-layout`, `custom/font`, `custom/icon-theme`, `custom/wallpaper`, none of which `config-athena.jsonc` redefines directly, so all five are silently absent from `athena.json` even though waybar genuinely instantiates them.
- **Fix:** Sourced those five entries from a verified-equivalent re-resolution — probed `modules.jsonc` directly with a synthetic `{"include": ["modules.jsonc"], "modules-left": [<name>]}` file through the same `--resolve` mechanism, forcing each module into the tool's own "used" set, then cross-checked every value byte-identical (`jq -S`, zero diff) against the values actually used in the document.
- **Files modified:** None — the script itself was not touched (out of this plan's scope, which touches no code). Only `18-BEHAVIOUR-BASELINE.md`'s Provenance section documents the finding and the workaround.
- **Verification:** `jq -S` diff between the probe's output and the values written into the document, zero output, for all five affected entries.
- **Committed in:** `cee0970` (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 — tool-completeness bug, documented and worked around, not code-fixed since out of scope)
**Impact on plan:** Necessary for correctness — omitting the five group/settings members would have violated the plan's own "MUST NOT omit a behaviour" prohibition. No scope creep — the underlying script was not modified.

## Issues Encountered

- The document's own acceptance criteria (zero duplicate `WB-*` ID tokens across the whole file) is stricter than a naive first draft assumed — an early draft cited already-defined IDs in cross-reference asides (e.g. "contrast `WB-VERT-09`") and in the GATE-02 Criterion B Index (which by its own action-item text needs to map B.1-B.6 to "the criterion IDs" that substantiate them). Resolved by running the Task 1 and Task 2 `<verify>` blocks *before* committing each task (catching this immediately rather than discovering it downstream in `18-19`), and rewriting every cross-reference and the entire B Index to cite rows by module name + layout instead of by repeating the literal ID token. The B Index still fully discharges its purpose — every B.1-B.6 row names exactly which rows substantiate it — just not via literal token repetition.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `18-BEHAVIOUR-BASELINE.md` and its four resolved snapshots are committed and ready for `18-19`'s blocking GATE-02 criterion-B pass to walk directly.
- The GATE-01 Recurrence Protocol is live in `ROADMAP.md` — Phases 19, 20 and 21 will each see their opening-task bullet at phase start without anyone needing to remember it.
- No blockers for `18-03` (GATE-04 hex-literal lint) or the rest of wave 1 — this plan touched no waybar file and no QML code, per its own explicit scope boundary.

## Self-Check: PASSED

All 6 claimed files found on disk; all 3 task commit hashes (`cee0970`, `a420da4`, `f39b613`) found in git log.

---
*Phase: 18-qml-bar-retirement-machinery*
*Completed: 2026-08-11*
