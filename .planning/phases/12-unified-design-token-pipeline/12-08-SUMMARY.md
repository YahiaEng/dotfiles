---
phase: 12-unified-design-token-pipeline
plan: 08
subsystem: theming
tags: [quickshell, qml, motion, spring-physics, token-inspector, verdict]

# Dependency graph
requires:
  - phase: 12-06
    provides: "the token inspector (Probe.qml), its Replay row and the three bezier NumberAnimation-on-x replay swatches this plan adds a SpringAnimation variant beside"
  - phase: 12-07
    provides: "confirmation that the motion pipeline (motion.json, motion-lint, the three render targets) needed no further change for this plan — TOKEN-06 is QML-only and touches no other target"
provides:
  - "Probe.qml: a Spring / MD3 toggle on the Replay row, a SpringAnimation variant beside each of the three bezier replay swatches, kept as a permanent comparison instrument"
  - "12-MOTION-VERDICT.md: the recorded TOKEN-06 verdict — MD3 bezier retained, spring physics NOT adopted, framed as a tuning-parameter rejection rather than a mechanism rejection"
  - "PROJECT.md's two 'Pending — v3.0 Phase 12' motion rows resolved"
  - "TOKEN-06 marked Complete in REQUIREMENTS.md (satisfied by a comparison that returned 'no', not left unmet)"
affects: [14-dashboard-drawer]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Two mutually-exclusive replay variants on the same QML element use standalone `SpringAnimation { target: ...; property: \"x\" }` objects, not grouped `SpringAnimation on x` syntax, alongside the existing `NumberAnimation on x` — avoids declaring two grouped-property value sources for the same property on the same object; safe because the trigger code guarantees only one of the six animation objects is ever running at a time"
    - "A mechanical acceptance grep that forbids specific literal substrings in a file (here: Compose's `stiffness`/`dampingRatio` property names) applies to comments as much as code — the explanatory comment beside `SpringAnimation` uses paraphrases (\"spring rate\", \"damping ratio\" with a space) instead of the exact camelCase tokens, so the safety rationale is preserved in prose without tripping the same grep it exists to satisfy"

key-files:
  created:
    - .planning/phases/12-unified-design-token-pipeline/12-MOTION-VERDICT.md
  modified:
    - quickshell/.config/quickshell/modules/Probe.qml
    - .planning/PROJECT.md
    - .planning/REQUIREMENTS.md

key-decisions:
  - "Verdict: MD3 bezier baseline retained, spring physics NOT adopted. User's verbatim reason ('MD3 is better. Spring is too fast') is recorded as a tuning-parameter symptom against unsourced feel-tuned values (spring:300/damping:20/mass:1), not a rejection of spring physics as a mechanism — 12-MOTION-VERDICT.md explicitly leaves a future revisit open if a primary source for MD3 Expressive's spring constants ever surfaces, while barring re-rolling the same unsourced guess."
  - "The Spring / MD3 toggle is KEPT in Probe.qml as a permanent comparison instrument, not removed post-verdict. Rationale: it is fully self-contained (droppability was proven live during Task 1 via a scratch quickshell copy with the toggle/spring code removed, which still loaded cleanly), it is lint-clean (motion-lint 37/0 and theme-doctor 180/0 both hold with it present), and keeping it makes a future re-attempt — contingent on a sourced spring target — cheap rather than requiring the comparison harness to be rebuilt from scratch."
  - "TOKEN-06 closed as Complete, not left Pending or moved to Out of Scope: the requirement's own wording ('adopted only if a human side-by-side comparison judges it better than the MD3 baseline') is satisfied by running the comparison and recording a 'no' — the comparison itself is the deliverable, and it happened."
  - "REQUIREMENTS.md was edited directly (not via the `requirements mark-complete` CLI verb) so the traceability table's Status cell could carry the required nuance ('Complete (not adopted, by human judgement — see 12-MOTION-VERDICT.md)') rather than a bare 'Complete' — the CLI verb's `/^complete$/i` exact-match check would not have recognised this annotated cell as fully reconciled on a later run, so the richer text is deliberately preferred over the generic tool output here."

requirements-completed: [TOKEN-06]

coverage:
  - id: D1
    description: "A Spring / MD3 toggle switches the Replay row between the existing MD3 bezier variant and a new SpringAnimation variant on the identical three swatches (same element, same property, same 0->80 range, same trigger) — no curve fitting, no other render target touched"
    requirement: "TOKEN-06"
    verification:
      - kind: integration
        ref: "grep -c 'SpringAnimation' quickshell/.config/quickshell/modules/Probe.qml -> 8 (>=1 required); grep -c 'stiffness\\|dampingRatio' -> 0"
        status: pass
      - kind: integration
        ref: "5 consecutive pkill+quickshell-launch.sh cycles: 0 occurrences of 'is not a type' / 'Failed to load configuration' / 'Cannot assign to non-existent property' in ~/.cache/quickshell.log"
        status: pass
      - kind: integration
        ref: "live summon via hyprctl dispatch global quickshell:probe; ~/.cache/quickshell.log scanned for warning/cannot assign/unknown property after summon -> none found (SpringAnimation's spring/damping/mass property names accepted, not silently dropped)"
        status: pass
      - kind: integration
        ref: "droppability: scratch copy of quickshell/.config/quickshell with the toggle Button, springMode property and all three SpringAnimation blocks removed via script -> qmllint clean, live quickshell -p <scratch> daemon loads with 'Configuration Loaded' and zero errors"
        status: pass
      - kind: integration
        ref: "motion-lint (real tree): 37 passed / 0 failed, incl. Probe.qml CHECK A/B; theme-doctor: 180 passed / 0 failed (fully clean, no untracked files, git status --porcelain empty)"
        status: pass
    human_judgment: false
  - id: D2
    description: "A human watches both variants side by side and records a verdict — the actual criterion 5 deliverable"
    requirement: "TOKEN-06"
    verification:
      - kind: manual_procedural
        ref: "checkpoint:human-verify (Task 2, gate=blocking) — user response verbatim: 'MD3 is better. Spring is too fast.' Adoption call: MD3 bezier baseline retained, spring physics NOT adopted."
        status: pass
    human_judgment: true
    rationale: "Whether native spring physics reads as more alive, settles cleanly, or fits a surface opened dozens of times a day is exactly the class of subjective judgment no mechanical check can substitute for — this is the entire point of TOKEN-06's own wording ('adopted only if a human ... judges it better'). Judged; verdict recorded."
  - id: D3
    description: "The verdict is recorded in 12-MOTION-VERDICT.md with the tuning-vs-mechanism framing, and PROJECT.md's two pending motion rows plus REQUIREMENTS.md's TOKEN-06 row are all resolved to reflect it"
    requirement: "TOKEN-06"
    verification:
      - kind: integration
        ref: "test -f 12-MOTION-VERDICT.md; grep -c 'Pending (v3.0 Phase 12)' .planning/PROJECT.md -> 0; grep -ci 'sampled.*keyframes' .planning/PROJECT.md -> 0; grep -c '12-MOTION-VERDICT' .planning/PROJECT.md -> 1; git diff --stat .planning/PROJECT.md shows only the two targeted row edits, no other row/heading removed"
        status: pass
      - kind: integration
        ref: "REQUIREMENTS.md TOKEN-06 checkbox flipped to [x] and traceability Status cell reads 'Complete (not adopted, by human judgement — see 12-MOTION-VERDICT.md)', both pointing at the verdict document"
        status: pass
    human_judgment: false

duration: single session (~40 min active work across Task 1 + the Task 2 checkpoint pause + Task 3, resumed inline on the coordinator's relayed verdict rather than a separate spawned continuation)
completed: 2026-07-27
status: complete
---

# Phase 12 Plan 08: Unified Design-Token Pipeline — TOKEN-06 Spring-vs-MD3 Verdict Summary

**Verdict: MD3 bezier baseline retained, spring physics NOT adopted — "MD3 is better. Spring is too fast" (a tuning-parameter symptom against unsourced feel-tuned values, not a rejection of spring physics as a mechanism; a future revisit is not barred if a primary source for MD3 Expressive's spring constants ever surfaces). The comparison instrument (Spring / MD3 toggle in the token inspector) is kept as a permanent, lint-clean fixture for that future revisit. Adopting springs anywhere remains later-phase work — nothing else in Phase 12 or the milestone changed because of this outcome.**

## Performance

- **Duration:** single session — Task 1 (autonomous) committed, Task 2's blocking `checkpoint:human-verify` gate then paused execution normally (D-26/D-27 discipline), resumed inline on the coordinator's relayed verdict (no separate continuation-agent spawn was needed), Task 3 completed the close
- **Started:** 2026-07-27 (approx, Task 1)
- **Completed:** 2026-07-27 (Task 3, verdict recorded)
- **Tasks:** 3 of 3 — Task 1 (auto), Task 2 (blocking human-verify, **RESOLVED: not adopted**), Task 3 (auto)
- **Files modified:** 4 (1 new, 3 modified)

## Accomplishments

- `Probe.qml`'s token inspector gained a **Spring / MD3** toggle on the Replay row (12-UI-SPEC.md item 6), plus a "Playing: MD3/Spring" label naming the active variant. All three semantic-pair swatches (`standard`, `emphasized-in`, `emphasized-out`) gained a standalone `SpringAnimation` beside their existing `NumberAnimation on x` — identical element, property and `0->80` range, differing only in interpolation, so the comparison the human judged was honest by construction.
- Used the correct QML property names throughout (`spring`/`damping`/`mass`), verified live: summoning the panel and reading `~/.cache/quickshell.log` showed zero unknown-property warnings, confirming the spring was genuinely parameterised rather than silently running on defaults (Pitfall 5). The explanatory comment beside the declarations deliberately paraphrases the forbidden Compose-style names ("spring rate", "damping ratio" with a space) so the mechanical `grep -c 'stiffness\|dampingRatio'` acceptance check — which applies to comments as much as code — stays at 0 while the safety rationale is still fully spelled out in prose.
- Droppability proven live, not just asserted: a scratch copy of the whole `quickshell/.config/quickshell` directory with the toggle button, `springMode` property and all three `SpringAnimation` blocks mechanically stripped out still passed `qmllint` and loaded cleanly under a real `quickshell -p <scratch>` daemon run, alongside (not replacing) the production daemon.
- The human side-by-side comparison ran (Task 2): toggled back and forth several times against the three swatches, motion axis confirmed at `normal`. **Verdict, verbatim: "MD3 is better. Spring is too fast."** Adoption call: MD3 bezier baseline retained, spring physics NOT adopted.
- `12-MOTION-VERDICT.md` records the full comparison (what was tested, the actual `spring:300/damping:20/mass:1` parameters and why they were tuned by feel rather than to a spec, the verbatim verdict) and the tuning-vs-mechanism reasoning explicitly requested by the coordinator: this is a recorded rejection of *this unsourced guess*, not a general verdict against spring physics as a mechanism — a future revisit stays open if a primary source for MD3 Expressive's spring constants ever surfaces, while re-rolling the same unsourced guess is explicitly discouraged.
- `PROJECT.md`'s two "Pending — v3.0 Phase 12" motion rows are both resolved: the spring-vs-baseline row now states the verdict and points at `12-MOTION-VERDICT.md`; the three-render-targets row is corrected from the pre-research "GTK4 takes sampled keyframes" assumption to what Phase 12 actually shipped (QML bezier control points via `easing.bezierCurve`, GTK4 `cubic-bezier()` via CSS custom properties, Hyprland native `bezier =` entries), settling ROADMAP open questions 2 and 3 as moot/resolved respectively.
- `TOKEN-06` marked **Complete** in `REQUIREMENTS.md` (both the checkbox and the traceability table), annotated "not adopted, by human judgement" — per the requirement's own wording, a comparison that returns "no" satisfies it rather than leaving it unmet.

## Task Commits

1. **Task 1: Spring variant beside the bezier one, on the same token** - `1895d21` (feat)
2. **Task 2: Side-by-side judgement — spring versus MD3 baseline (criterion 5)** - **RESOLVED** (blocking human-verify checkpoint; no code change — verdict: "MD3 is better. Spring is too fast", not adopted)
3. **Task 3: Record the verdict and resolve PROJECT.md's two pending motion rows** - `dc595b4` (docs)

**Plan metadata:** committed alongside this SUMMARY (see final-commit step)

## Files Created/Modified

- `quickshell/.config/quickshell/modules/Probe.qml` - Spring / MD3 toggle, springMode property, three SpringAnimation replay variants, kept permanently post-verdict
- `.planning/phases/12-unified-design-token-pipeline/12-MOTION-VERDICT.md` - the recorded verdict, verbatim user response, and tuning-vs-mechanism reasoning
- `.planning/PROJECT.md` - both pending v3.0 Phase 12 motion rows resolved
- `.planning/REQUIREMENTS.md` - TOKEN-06 marked Complete (checkbox + traceability row), annotated with the verdict

## Decisions Made

See frontmatter `key-decisions` — summarized: (1) verdict is MD3 retained/spring not adopted, framed as a tuning-parameter rejection with a future revisit explicitly left open, not a general verdict against spring physics; (2) the Spring/MD3 toggle is kept permanently in `Probe.qml` rather than removed, since it is self-contained, lint-clean, and makes a future sourced-parameter re-attempt cheap; (3) TOKEN-06 closes Complete, not Pending or Out of Scope, since the requirement's own wording is satisfied by a comparison that ran and returned "no"; (4) REQUIREMENTS.md was hand-edited rather than run through the generic `requirements mark-complete` CLI verb, so the traceability Status cell could carry the required nuance text rather than a bare "Complete" the verb's exact-match regex would otherwise have produced.

## Deviations from Plan

None — plan executed as written, with the verdict itself supplied by the coordinator relaying the human's checkpoint response (Task 2's own designed pause-and-resume flow), not a deviation from it.

## Issues Encountered

- During live verification, `hyprctl dispatch global quickshell:probe` toggle state proved unreliable to poll across separate Bash tool invocations (the panel appeared to close between checks with no explicit dismiss issued) — most likely each new Bash tool invocation briefly shifts window focus in a way that trips the panel's `HyprlandFocusGrab` click-outside dismiss. Not a defect in `Probe.qml` or this plan's code: resolved pragmatically by doing a full `pkill -x quickshell` + relaunch before each check that needed a known-closed baseline, and confirming the final state was closed (`probe panel: closed (clean)`) before finishing verification. No stray state was left on the user's desktop.

## Known Stubs

None — the toggle, the label, and all three `SpringAnimation` variants are fully wired to real animations on real swatches; nothing is a placeholder. The verdict document states plainly, per its own text, that it is a recording bounded by standing constraint 5 (no phase or requirement depends on the outcome) — this is a deliberate scope fence, not a stub.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- **This closes Phase 12.** All six TOKEN requirements now resolve: TOKEN-01 through TOKEN-05 Complete (12-03 through 12-07), TOKEN-06 Complete (this plan, not-adopted verdict). QS-03 was separately dropped to Out of Scope by 12-01/12-02 (D-13). No open requirement remains in Phase 12.
- **Gate baselines, confirmed clean at this plan's close** (independently re-verified by the orchestrator per its checkpoint-resolution message, cited not re-run): `theme-doctor` 180 passed / 0 failed (fully clean); `motion-lint` real tree 37 passed / 0 failed; `quickshell-doctor` 13 passed / 0 failed, exit 0; `theme-parity` unchanged at 1985 passed / 0 failed (this plan touches no parity-checked render target). Motion axis confirmed `normal`; working tree confirmed clean; commits `1895d21` and `dc595b4` both present.
- **Phase 14's dashboard drawer inherits a settled motion answer**: build on the MD3 bezier baseline like every other surface in this pipeline. The Spring / MD3 comparison instrument in `Probe.qml` remains available if a sourced spring target ever surfaces later, but nothing about Phase 14 (or any other phase) depends on, or is blocked by, this plan's outcome (D-26, standing constraint 5).
- **PROJECT.md's Key Decisions table now carries zero "Pending — v3.0 Phase 12" entries** — both motion-related decisions from scoping are fully resolved with evidence pointers.
- No blockers carried forward from this plan. Phase 12's own remaining open items (e.g. `.planning/WINDOWS.md` entry #9, the unrun real `theme-stress-test` 10/10 confirmation) predate this plan and are unaffected by it — see 12-06/12-07's own "Next Phase Readiness" sections for their status.

---
*Phase: 12-unified-design-token-pipeline*
*Completed: 2026-07-27*
