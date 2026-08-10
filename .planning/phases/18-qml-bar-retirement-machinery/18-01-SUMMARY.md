---
phase: 18-qml-bar-retirement-machinery
plan: 01
subsystem: ui
tags: [quickshell, qml, wlr-layer-shell, hyprland, panelwindow, systemclock]

# Dependency graph
requires: []
provides:
  - "Bar.qml — the repo's first permanently-mounted PanelWindow with exclusiveZone > 0"
  - "Design.qml bar tokens: barHeight, barEdgeMargin, barSideMargin, barCapsuleRadius"
  - "quickshell-bar layer-shell namespace, inheriting the ^quickshell-.* family blur/ignore_alpha rules"
  - "The corrected exclusiveZone-vs-margins.top arithmetic every later bar plan (18-05..18-20) must follow"
  - "18-BAR-IDLE-BASELINE.md — the pre-expansion idle-cost floor 18-18 (QBAR-11) diffs against"
affects: [18-05, 18-07, 18-08, 18-09, 18-10, 18-11, 18-13, 18-14, 18-15, 18-16, 18-17, 18-18, 18-19, 18-20]

# Actuals (#2632)
actuals:
  tokens: 4300
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Permanent shell-root mount (no LazyLoader, no active property) as the deliberate inversion of every prior summon-on-demand Quickshell surface in this repo"
    - "SystemClock at Minutes precision instead of a repeating Timer, for surfaces with no dismissed state"
    - "exclusiveZone submitted as the surface's own content extent only (Design.barHeight); Hyprland separately adds the anchored margins.top to compute the live reserved total — do NOT fold the margin into the exclusiveZone expression"

key-files:
  created:
    - quickshell/.config/quickshell/modules/Bar.qml
    - .planning/phases/18-qml-bar-retirement-machinery/18-BAR-IDLE-BASELINE.md
  modified:
    - quickshell/.config/quickshell/modules/dashboard/Design.qml
    - quickshell/.config/quickshell/modules/qmldir
    - quickshell/.config/quickshell/shell.qml

key-decisions:
  - "exclusiveZone: Design.barHeight (NOT + Design.barEdgeMargin) — live-measured correction of the plan's own written formula; Hyprland's reservation total is margins.top + exclusiveZone, so the margin must not appear in both terms"
  - "Namespace quickshell-bar on WlrLayer.Top (not Overlay) so always-on chrome sits below transient dialogs and an ext-session-lock surface"
  - "Clock capsule inline in Bar.qml, no bar/ subdirectory pre-created — 18-05 owns the entry-list model and BarCapsule.qml extraction"

patterns-established:
  - "Permanent-liveness discipline: any always-mounted surface's periodic state must use the narrowest event-driven primitive available (SystemClock.Minutes here), never a repeating Timer, because the cost runs for the whole session with no dismissed state to gate it off"

requirements-completed: [QBAR-01]

coverage:
  - id: D1
    description: "A quickshell-bar layer-shell surface is mounted permanently from shell start with no summon path, reserving exactly 46px on the anchored edge (live-measured, not derived)"
    requirement: "QBAR-01"
    verification:
      - kind: other
        ref: "hyprctl layers -j | jq -r '..|.namespace? // empty' | grep -c '^quickshell-bar$' (== 1); hyprctl monitors -j | jq -c '[.[].reserved]' with waybar hidden-hard (== [[0,46,0,0]])"
        status: pass
    human_judgment: false
  - id: D2
    description: "The reservation is byte-identical across a QML hot reload"
    requirement: "QBAR-01"
    verification:
      - kind: other
        ref: "touch Bar.qml; hyprctl monitors -j | jq -c '[.[].reserved]' before/after — both [[0,46,0,0]]"
        status: pass
    human_judgment: false
  - id: D3
    description: "The bar renders one real capsule showing the live system time in the repo's rounded-pill language, fully driven by Colours/Design tokens, floating clear of the screen edge"
    requirement: "QBAR-01"
    verification: []
    human_judgment: true
    rationale: "Visual rendering (pill shape, position, colour crossfade on theme switch, no magenta flash) requires a human render-gate pass per D-18-31/GATE-02 — deferred to the user per established project preference (see Deviations); logged as WINDOWS.md ledger entry 24 (unrun-verify) so it stays visible at ship time."
  - id: D4
    description: "The bar costs zero child processes and zero repeating timers at rest, recorded with commands for 18-18 to diff against"
    requirement: "QBAR-01"
    verification:
      - kind: other
        ref: "18-BAR-IDLE-BASELINE.md — pgrep -P (child count 0), grep -rn Timer Bar.qml (count 0)"
        status: pass
    human_judgment: false

duration: ~20min (incl. a mandatory 5min settle wait for Task 3's precondition)
completed: 2026-08-11
status: complete
---

# Phase 18 Plan 01: QML Bar Tracer Summary

**One permanently-mounted `PanelWindow` (`Bar.qml`) claims a real 46px exclusive zone under namespace `quickshell-bar` and renders a live `HH:MM` clock capsule driven by `SystemClock`, proven against `hyprctl monitors -j` on the live host rather than trusted from arithmetic — and the plan's own exclusiveZone formula was found wrong by that same live measurement and corrected in-flight.**

## Performance

- **Duration:** ~20 min (includes a mandatory 5-minute settle wait before Task 3's baseline capture, per that task's own precondition)
- **Started:** 2026-08-10T23:02Z (approx, first task commit)
- **Completed:** 2026-08-10T23:12Z
- **Tasks:** 3 (all completed)
- **Files modified:** 5 (1 created QML, 1 created doc, 3 modified)

## Accomplishments

- `Bar.qml` created: a single `PanelWindow`, root type only (no `Variants` fan-out per D-13/QS-03), mounted unconditionally as a direct `ShellRoot` child in `shell.qml` — the first surface in this repo with no dismissed state and the first with `exclusiveZone > 0`
- Four new `Design.qml` tokens (`barHeight`, `barEdgeMargin`, `barSideMargin`, `barCapsuleRadius`), append-only, with the 4px-grid exemption documented inline
- `modules/qmldir` declares `Bar 1.0 Bar.qml` (non-singleton), closing the silent-unresolvable-type failure mode the file's own header warns about
- Live-proven on the real compositor: `quickshell-bar` registers in `hyprctl layers -j`; the bar's own reservation measures exactly `[[0,46,0,0]]` with waybar hidden-hard, byte-identical across a QML hot reload; waybar restored to `visible` and the co-existing total reads `[[0,92,0,0]]`
- Found and fixed, live, a genuine arithmetic bug in the plan's own written formula (see Deviations)
- `18-BAR-IDLE-BASELINE.md` captured: RSS 445104 KiB, one `quickshell` process, zero child processes, zero `Timer` blocks in `Bar.qml`, live theme `catppuccin` — the pre-expansion floor 18-18 (QBAR-11) needs to attribute future widening to specific plans (18-08, D-18-05) rather than unexplained creep

## Task Commits

Each task was committed atomically:

1. **Task 1: One PanelWindow, one live capsule, wired end-to-end** — `beab39b` (feat)
2. **Task 2: Prove the reserved-zone arithmetic on the live host** — `071ee01` (fix — the exclusiveZone correction found during this task's own live measurement)
3. **Task 3: Capture the bar's idle cost floor** — `98344da` (docs)

**Plan metadata:** pending final commit (this SUMMARY + STATE.md + ROADMAP.md)

## Files Created/Modified

- `quickshell/.config/quickshell/modules/Bar.qml` — new `Bar` type: `PanelWindow` root, `barWindow`/`barContent`/`clockCapsule`/`clockText`/`barClock` ids, `quickshell-bar` namespace, `SystemClock`-driven clock
- `quickshell/.config/quickshell/modules/dashboard/Design.qml` — four bar tokens appended, nothing removed
- `quickshell/.config/quickshell/modules/qmldir` — `Bar 1.0 Bar.qml` line appended
- `quickshell/.config/quickshell/shell.qml` — `Bar { id: barInstance }` mounted as a direct `ShellRoot` child, sibling of the backend instances
- `.planning/phases/18-qml-bar-retirement-machinery/18-BAR-IDLE-BASELINE.md` — new idle-cost-floor capture document

## Decisions Made

- **exclusiveZone formula corrected to `Design.barHeight` alone** (not `Design.barHeight + Design.barEdgeMargin` as the plan's own `<action>` text specified) — see Deviations below for the full measurement trail. This is the single most load-bearing finding of this plan: every later bar plan inherits this corrected arithmetic.
- **`WlrLayer.Top`, not `Overlay`** — matches the plan's own instruction; recorded here because it is the one layer-posture choice that diverges from `Overview.qml`'s template (`Overlay`), and the reason (always-on chrome sits below transient dialogs and the session lock) is worth restating for 18-05 onward.
- **No `bar/` subdirectory, no `BarCapsule.qml` extraction** — deliberately deferred to 18-05 per the plan's own scope boundary, to avoid two plans holding partial ownership of the same file.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Corrected exclusiveZone double-counting of the anchored margin**

- **Found during:** Task 2 (live reserved-zone measurement)
- **Issue:** The plan's `<action>` text for Task 1 specified `exclusiveZone: Design.barHeight + Design.barEdgeMargin` (46) while ALSO specifying `margins.top: Design.barEdgeMargin` (6). Task 2's live measurement (`hyprctl monitors -j | jq -c '[.[].reserved]'`) with both bars mounted read `[[0,98,0,0]]` instead of the plan's own expected `[[0,92,0,0]]` — the bar was reserving 52px alone, not 46px. This is exactly one of the wrong values (`52`) the plan's own Task 2 text names and instructs the executor to stop and correct rather than adjust the expected number. Root cause: Hyprland computes the total reservation as `margins.top + exclusiveZone`, not `exclusiveZone` alone — the compositor adds the anchored margin on top of whatever `exclusiveZone` value the surface submits. The plan's original formula effectively counted `barEdgeMargin` twice: once inside `exclusiveZone`, once via `margins.top`.
- **Fix:** Changed `exclusiveZone` to `Design.barHeight` alone (the surface's own content extent), leaving `margins.top: Design.barEdgeMargin` unchanged. This mirrors what waybar's own GTK layer-shell binding submits (its own content height; the compositor adds `margin-top` separately) — the exact mechanism `18-RESEARCH.md` Pitfall 1 was describing without stating which side of the sum came from which source.
- **Files modified:** `quickshell/.config/quickshell/modules/Bar.qml`
- **Verification:** Re-measured live after the fix: `[[0,92,0,0]]` co-existing with waybar, `[[0,46,0,0]]` with waybar hidden-hard (the load-bearing reading), byte-identical across a subsequent QML hot reload (`touch Bar.qml`). All four readings below.
- **Committed in:** `071ee01`

**2. [Rule 1 adjacent — documented, not code] Task 1's own acceptance-criteria literal-text check is now stale**

- **Found during:** Task 2, as a direct consequence of fix #1 above
- **Issue:** Task 1's written acceptance criteria included `grep -c 'exclusiveZone: Design.barHeight + Design.barEdgeMargin' quickshell/.config/quickshell/modules/Bar.qml` returning `1`. After the Task 2 correction, this literal string no longer appears in the file (by design — it was the bug).
- **Resolution:** Not re-run as a gate; Task 2's own live-host measurement supersedes Task 1's source-text assertion, per the plan's own explicit instruction ("stop and correct Design.qml/Bar.qml before proceeding, do not adjust the expected number"). The negative criterion (`barEdgeMargin \* 2` count `0`) still holds — the source never literally doubles the token, it was a semantic double-count via two separate properties.
- **Impact:** None on correctness; documented here so a future reader of Task 1's acceptance criteria understands why the literal string is absent.

---

**Total deviations:** 1 auto-fixed (Rule 1 — arithmetic bug found by required live measurement), 1 documented consequence (stale acceptance-criteria text, no code impact).
**Impact on plan:** The fix is exactly what Task 2 was designed to catch and correct; it is the plan's single most important deliverable, since every later bar plan (18-05 through 18-20) inherits the corrected `exclusiveZone` formula rather than the wrong one.

## Live Reserved-Zone Readings (for 18-17's QBAR-12 and 18-19's GATE-02 to cite)

| Reading | Command | Result |
|---|---|---|
| Co-existing (before fix, WRONG) | `hyprctl monitors -j \| jq -c '[.[].reserved]'` | `[[0,98,0,0]]` |
| Co-existing (after fix) | `hyprctl monitors -j \| jq -c '[.[].reserved]'` | `[[0,92,0,0]]` |
| Bar-alone (waybar hidden-hard, load-bearing) | `hyprctl monitors -j \| jq -c '[.[].reserved]'` after `~/.config/hypr/scripts/waybar-visibility.sh keybind toggle` | `[[0,46,0,0]]` |
| Bar-alone after QML hot reload | same command, after `touch Bar.qml` and reload settle | `[[0,46,0,0]]` (byte-identical) |
| Restored | same command, after `waybar-visibility.sh keybind toggle` again; `waybar-visibility.sh status` prints `visible` | `[[0,92,0,0]]` |

No `hyprctl reload` and no `hyprctl eval` (Hyprland debug overlay) was run at any point in this plan, per Pitfall 4's prohibition.

## Issues Encountered

- `pgrep -a -f 'quickshell|elephant|walker'` self-matched the invoking shell wrapper (its own command-line text contains the search pattern), inflating the process count from 3 to 4 in one raw reading. Filtered and documented in `18-BAR-IDLE-BASELINE.md`, a measurement quirk rather than a genuine process-count regression, so 18-18 will not be misled by it.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- The corrected `exclusiveZone`/`margins.top` arithmetic is proven live and documented in `Bar.qml`'s own header comment — every later bar plan (18-05 onward) can copy this pattern directly rather than re-deriving it.
- `18-BAR-IDLE-BASELINE.md` gives 18-18 (QBAR-11) a real, attributable start point.
- **Outstanding:** the D-18-31/GATE-02 human render-gate visual pass (pill shape, position, live clock, theme-switch crossfade with no magenta flash) has NOT been performed by the executor — logged as WINDOWS.md ledger entry 24 (`unrun-verify`, phase 18). This should be confirmed by the user before 18-19's GATE-02 parity pass is taken as final, though it does not block continuing to 18-02 through 18-04 in the same wave.

---
*Phase: 18-qml-bar-retirement-machinery*
*Completed: 2026-08-11*

## Self-Check: PASSED

- FOUND: `quickshell/.config/quickshell/modules/Bar.qml`
- FOUND: `quickshell/.config/quickshell/modules/dashboard/Design.qml`
- FOUND: `quickshell/.config/quickshell/modules/qmldir`
- FOUND: `quickshell/.config/quickshell/shell.qml`
- FOUND: `.planning/phases/18-qml-bar-retirement-machinery/18-BAR-IDLE-BASELINE.md`
- FOUND commit: `beab39b`
- FOUND commit: `071ee01`
- FOUND commit: `98344da`
