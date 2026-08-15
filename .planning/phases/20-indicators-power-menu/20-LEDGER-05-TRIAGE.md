---
phase: 20-indicators-power-menu
plan: 02
requirement: LEDGER-05
generated: 2026-08-15T19:07:00Z
---

# LEDGER-05 — WINDOWS.md Triage (Phase 20 start)

## Working figure

Live `.planning/WINDOWS.md` frontmatter, re-read fresh this session:

```
open_count: 51
waived_count: 0
fixed_count: 24
total_count: 75
last_updated: 2026-08-13T12:43:20.122Z
```

**`open_count` is 51, not 16.** LEDGER-05's own requirement text and ROADMAP.md's SC-6
both cite "16" — that figure is stale (D-20-39). It reflects an earlier ledger state
(the "16 of 23 WINDOWS.md rows still open" line carried in PROJECT.md's Active section,
written before Phase 18 alone added dozens of new unrun-verify rows). The count used for
this triage, and the one this document's own arithmetic is checked against, is the live
51/24/75 split confirmed by re-parsing the table directly (51 rows with `status: open`,
24 `fixed`, 0 `waived`, 75 total — counts independently verified by counting the table
and cross-checked against `gsd-tools windows status`).

## Method

Every `open` row was scanned in ascending `id` order for a `file` or `description` match
against: `swayosd`, `wleave`, `wlogout`, `eww`, `Toast.qml`, the OSD, the power menu,
`windowrules.lua`'s layer rules, or `ClockActionsCapsule.qml`'s power cell (this phase's
own surfaces, per 20-CONTEXT.md and 20-RESEARCH.md § "Priority Research Findings" item 7).
That scan reconfirms the floor RESEARCH.md already established — **ids 3, 4, 5, 6, 10, 74**
— and finds no further row meeting the match criteria. (Two rows, 33 and 36, share a file
basename with `ClockActionsCapsule.qml`, but their content is about the notification-bell
drawer / idle-inhibitor and a pre-existing colour lint on `cellItem.tint` — neither is
about the power cell specifically, so per the phase-surface qualifier they stay in the
batch remainder rather than being pulled into the individual set.)

Every other open row goes into one batch re-defer entry (§ Batch re-defer below).

**Tie-break rule (stated once, applies to both sections of this document and to the
WINDOWS.md edit in Task 2):** if a row both names one of this phase's own surfaces AND
would otherwise fall in the numeric remainder, it is placed in the individual-verdict set
and is NEVER also listed in the batch id list. No id appears in both sections.

## § Individual verdicts (D-20-40 in-scope set)

| id | phase | file | verdict | reason | evidence-or-owner |
|----|-------|------|---------|--------|---------------------|
| 3 | 09 | `wleave/.config/wleave/style.css` | re-deferred | D-10 entrance-vs-hover interaction (hovering during the ~350ms entrance stagger window) was never exercised live. `wleave/style.css` itself is deleted whole in plan 20-10, but the interaction it names is not artefact-specific: D-20-36 deliberately did NOT serialise the new power grid's entrance cascade against input readiness, so the identical hover-during-entrance race exists on the replacement surface. | Re-deferred onto the new power-grid surface (`ClockActionsCapsule.qml`'s power cell / the session dialog built in plan 20-06). Owner: plan 20-08's Gate B, which is where this phase's own render-gate proof of the entrance cascade + hover interaction is captured. |
| 4 | 09 | `.planning/phases/09-wlogout-to-wleave-migration/09-03-SUMMARY.md` | re-deferred | Same disposition family as row 3 — the 09-03 hover evidence was captured via keyboard focus (`wtype` Tab), not a literal mouse-hover event, because `hyprctl dispatch movecursor` does not emit a real `wl_pointer` motion/enter event on this build. The unconfirmed input modality (real mouse hover) is not resolved by anything in Phase 20's own tooling — the same synthetic-pointer gap applies to the new power-menu surface. | Re-deferred onto the new power-grid surface's own hover verification. Owner: plan 20-08's Gate B (same render-gate record as row 3 — both are the same unresolved "real mouse hover cannot be synthesised on this host" gap, now inherited by the replacement). |
| 5 | 09 | `wleave/.config/wleave/layout.json` | re-deferred | Icon glyph size in the old wleave grid was SVG natural/shrink-fit (~27–29px), never pinned to the UI-SPEC's literal 36px Display-role token. The replacement (Phase 20's power grid) pins `Design.sessionTileIconSize` (32) explicitly per 20-UI-SPEC.md — a strong `fixed`-by-construction candidate — but plan 20-06 (which builds that grid) has not executed yet as of this plan (wave 1, before wave 3). Per this plan's own prohibition, a row cannot be marked `fixed` on the strength of a plan that has not yet run. | Re-deferred. Owner: plan 20-06 (Power-menu tracer — builds the pinned-size session tiles). Close this row once 20-06 lands and its own acceptance criteria confirm the pinned icon size renders. |
| 6 | 09 | `hypr/.config/hypr/scripts/wleave.sh` | waived | Fault-injection gap: moving `~/.config/wleave/layout.json` aside does not trigger the wrapper's launch-failure `notify-send`, because wleave falls back to its own packaged `/etc/wleave/layout.json` instead of failing loudly. `wleave.sh` (the subject of this row) is deleted whole in plan 20-10, and D-20-23 deletes the availability-probe concept outright: an in-process QML surface built directly into the shell has no "external binary missing" failure mode to guard against — the entire class of bug this row describes cannot recur once wleave.sh no longer exists. | Waived — the artefact and the failure class it describes both cease to exist once plan 20-10 runs; there is no successor mechanism to re-defer onto because nothing analogous exists in an in-process QML power menu. |
| 10 | 13 | `hypr/.config/hypr/config/windowrules.lua` | waived | D-06 boundary correction: layer-surface exit animations (walker/swaync/wleave) are client-owned, not compositor-owned — confirmed by mechanical proof in 13-01 (Check 3 closed on mechanical evidence after the original render-gate method had no valid instrument). This is a documented architectural finding, not an open defect: the boundary is correctly understood and encoded in the config. This phase (20-03) adds two new layer namespaces to this same file (`quickshell-osd`, the power-menu dialog namespace) — the same client-owned-exit boundary applies to both, and nothing about adding namespaces reopens the original finding. | Waived — the row records a confirmed-correct architectural fact (client-owned exit, proven mechanically in 13-01), not a pending defect. No further action needed; the same boundary is inherited correctly by this phase's two new namespaces. |
| 74 | 19 | `quickshell/.config/quickshell/modules/toast/Toast.qml` | re-deferred | The DND toast's `show()`/timer/self-dismiss path was never exercised interactively in Phase 19 — DND was flipped by directly editing the state file rather than exercising the real `toggleDnd()`/`dndToggled`/`show()` call chain. Phase 20's OSD reuses this exact `Toast` frame type (per ROADMAP.md's own dependency note: "the OSD reuses the transient-toast frame built in 19"), and this phase's own GATE-02 record (plan 20-08) exercises the same show/auto-hide/hover-pause mechanism for real as part of proving the OSD indicators. | Re-deferred. Owner: plan 20-08's Gate A, criteria 3 (auto-hide) and 4 (hover-pause) — closing this row is a byproduct of that gate passing, since it exercises the identical `Toast` mechanism this row flags as unproven. |

## § Batch re-defer (the remainder)

**Ids (ascending, explicit list — 45 rows):**
7, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 33, 34, 35, 36, 38, 39, 40,
41, 42, 43, 44, 45, 46, 47, 50, 53, 54, 55, 56, 57, 63, 67, 68, 69, 70, 71, 72, 73, 75

**Reason (one, covers all 45):** None of these rows name a surface this phase touches
(`swayosd`, `wleave`, `wlogout`, `eww`, `Toast.qml`'s show/hide mechanism, the power menu,
or `windowrules.lua`'s layer-rule ordering). The set is a mix of (a) human-render-gate
checks intentionally skipped per this project's established "skip live verification, ship
fast" preference across Phases 09/13.1/15/18/18.1/19 (the largest share — bar capsules,
popouts, dashboard panels, the notification centre, hyprlock), (b) pre-existing deviations
recorded for later triage and never chased (e.g. row 15's waybar click-dispatch dead end,
rows 16/17's `ai-webapp-launch.sh`/`ai-workspace.sh` gaps, row 63's GPU/network sampler
gating, row 67/69/70's bar monitor-removal defect and its watchdog mitigation), and (c)
long-running measurement/paperwork debt (row 71's `theme-stress-test` structural
incompatibility). Re-triaging all 45 individually here would mean writing 45 one-off
verdicts inside a phase that already carries two new surfaces and three package
deletions — exactly the load LEDGER-05's design (individual set + one owned batch) exists
to avoid.

**Named owning phase:** **Phase 21 (Media Fold-In & Contract Close)**. Phase 21 already
carries LEDGER-06, a mandate to close cross-phase paperwork/verification debt (Phase 16's
missing `16-VERIFICATION.md`, its malformed `coverage:` blocks, and quick task
`260728-51j`) — per ROADMAP.md's own rationale, this keeps ledger triage "from becoming
end-of-milestone filler" by placing it in a migration phase rather than the final Phase 22
gate (which its own notes state explicitly carries "no debt at all"). Phase 21 is the
natural next checkpoint to re-triage this batch: the bulk of these rows are deferred human
render-gate checks that the same `human_verify_mode: end-of-phase` UAT process closes when
their originating surfaces get their next real end-to-end look, and Phase 21's own UAT
pass is that next look for the bar/dashboard/notification surfaces most of these rows
belong to.

**Date:** 2026-08-15

## Ledger arithmetic reconciled

- Individual-verdict set: 6 ids (3, 4, 5, 6, 10, 74) — 4 `re-deferred` (3, 4, 5, 74, stay
  `open` with an updated `reason`), 2 `waived` (6, 10, become `status: waived`).
- Batch remainder: 45 ids, all stay `status: open` with a shared `reason` pointing at the
  batch block.
- 6 + 45 = 51 = the live `open_count`. No id appears in both sets (verified against the
  explicit lists above).
- After Task 2 applies these verdicts: `waived_count` goes from 0 to 2 (rows 6, 10);
  `fixed_count` stays 24 (nothing in this triage is marked `fixed` — no plan producing
  that evidence has executed yet, per this plan's own prohibition); `open_count` goes from
  51 to 49 (51 − 2 waived); `total_count` stays 75.
