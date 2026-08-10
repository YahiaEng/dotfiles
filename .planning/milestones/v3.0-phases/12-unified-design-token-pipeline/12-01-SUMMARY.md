---
phase: 12-unified-design-token-pipeline
plan: 01
subsystem: infra
tags: [quickshell, qml, hyprland, layer-shell, wayland, multi-monitor]

# Dependency graph
requires:
  - phase: 11-quickshell-viability-gate
    provides: "11-QUICKSHELL-EVIDENCE.md's FM1/FM2 failure-mode record, quickshell-doctor's per-screen surface creation check, the QS-03 acceptance override in 11-VERIFICATION.md"
provides:
  - "quickshell/.config/quickshell/modules/qmldir — explicit type manifest closing FM1 (scanner race) permanently, verified via -v -v trace and two independent clean 10-restart proof runs"
  - "12-QS03-EVIDENCE.md — full STOP-branch record: two distinct fan-out arrangements attempted, both reproducing an FM2-class failure, further isolated to a general Variants+PanelWindow multiplicity limitation on quickshell 0.3.0-2 (not hotplug-timing-specific)"
  - "Session-restart re-proof against the real autostart daemon, confirming FM1 stays closed and the STOP-branch failure signature is stable across a real login boundary"
  - "A pending todo flagging quickshell-doctor's volume-probe gate brittleness (pre-existing, unrelated, not fixed here)"
affects: [12-02, quickshell-viability, phase-16-workspace-overview]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Explicit qmldir manifest to disable Quickshell's directory-scanner synthesis for a QML module directory (verify the exact synthesised grammar via `-v -v` trace before hand-writing the file, rather than trusting doc-form prose)"
    - "Variants { model: Quickshell.screens } + LazyLoader-per-screen delegate is the correct anti-FM2 shape in principle (never an always-instantiated `visible:` binding) — but is not sufficient on its own on this quickshell 0.3.0-2 build; both the shell.qml-level and Probe.qml-rooted placements of that shape hit the identical multiplicity failure"

key-files:
  created:
    - quickshell/.config/quickshell/modules/qmldir
    - .planning/phases/12-unified-design-token-pipeline/12-QS03-EVIDENCE.md
    - .planning/todos/pending/quickshell-doctor-volume-probe-brittle.md
  modified:
    - quickshell/.config/quickshell/shell.qml
    - quickshell/.config/quickshell/modules/Probe.qml

key-decisions:
  - "modules/qmldir was written matching the verified `-v -v` trace grammar (module header line included), overriding the plan's own unverified prose guess that no module header line was needed — per the task's own instruction to trust the trace over doc-form assumptions"
  - "Left shell.qml/Probe.qml on arrangement B (Variants rooted inside Probe.qml, shell.qml touches Probe exactly once) rather than reverting fully to pre-task state, since it is functionally identical to the original single-screen design for this host's one physical monitor and is the more contained of the two failed arrangements"
  - "QS-03 requirement NOT marked complete — the STOP branch explicitly defers the one-way D-13 accept-as-permanent-limitation decision to Plan 12-02's opening checkpoint; marking the requirement complete here would misrepresent an open decision as closed"
  - "quickshell-doctor's volume-probe gate brittleness (pre-existing, Phase-11-introduced, unrelated to this plan's file changes) filed as a pending todo rather than fixed in-plan, per scope discipline"

patterns-established:
  - "For any future quickshell scanner-affecting change: verify the exact `qmldir` synthesis grammar via `quickshell -p <dir> -v -v` against the unmodified tree before writing the file by hand"
  - "When testing a Quickshell per-screen fan-out fix, isolate hotplug-timing races from general multiplicity failures by also testing with all target screens present since process start (no runtime model-change event at all)"

requirements-completed: []  # QS-03 stays open — D-13 disposition belongs to Plan 12-02

coverage:
  - id: D1
    description: "Explicit modules/qmldir checked in, verified to disable Quickshell's directory-scanner synthesis for modules/ and to close FM1 (intermittent 'Probe is not a type' config-load race) across both in-session and real-session-restart proof runs"
    requirement: QS-03
    verification:
      - kind: manual_procedural
        ref: "10 consecutive pkill+relaunch cycles x2 (one per arrangement), 0/0 'is not a type'/'Failed to load configuration' both runs; real session logout/login re-proof, clean log"
        status: pass
    human_judgment: false
  - id: D2
    description: "Per-screen surface fan-out (QS-03's actual mechanical target): two structurally distinct arrangements attempted, both failed the two-screen hotplug/multi-screen test with an FM2-class signature; STOP branch, full written record with every arrangement named"
    requirement: QS-03
    verification:
      - kind: manual_procedural
        ref: "quickshell-doctor per-screen surface creation check; in-session 13/1, post-session-restart 12/2 (QS-03 + pre-existing unrelated volume-probe brittleness)"
        status: fail
    human_judgment: true
    rationale: "This is the documented STOP branch of a bounded fix budget, not a deliverable expected to pass — the failure itself, and whether the written record correctly captures every arrangement tried and the budget clause hit, requires human/downstream (Plan 12-02) judgment to accept as the basis for the D-13 permanent-limitation decision."
  - id: D3
    description: "Daemon left healthy post-plan: single-screen summon/dismiss (Super+Shift+G) works correctly both in-session and after a real session restart, no crash/abort markers, keybind-doctor clean"
    requirement: QS-03
    verification:
      - kind: manual_procedural
        ref: "hyprctl layers -j before/after toggle (in-session); user-confirmed 'toggle works, approved' post-session-restart"
        status: pass
    human_judgment: false

duration: multi-session (checkpoint pause for real session logout/login)
completed: 2026-07-26
status: complete
---

# Phase 12 Plan 01: QS-03 Per-Screen Fan-Out — STOP

**STOP branch: both bounded arrangements (Variants+LazyLoader in shell.qml; Variants rooted inside Probe.qml) reproduce an FM2-class multi-screen failure on quickshell 0.3.0-2, but the checked-in `modules/qmldir` permanently closes FM1 (the scanner race) — confirmed clean across two 10-restart proof runs and a real session logout/login.**

`quickshell-doctor` in-session: `Summary: 13 passed, 1 failed`, exit 1 (per-screen surface
creation, the expected STOP-branch failure, unchanged from the pre-task baseline).
`quickshell-doctor` post-session-restart: `Summary: 12 passed, 2 failed`, exit 1 — the same
QS-03 failure (with a stronger DP-1-also-vanishes signature) plus one pre-existing,
unrelated volume-probe gate brittleness, not caused by this plan and not fixed here.

## Performance

- **Duration:** multi-session — Task 1 (implementation, two arrangements, evidence write-up)
  completed in one sitting; Task 2 required a real Hyprland session logout/login, performed
  by the orchestrator/user and reported back at a checkpoint.
- **Tasks:** 2 (Task 1: auto; Task 2: checkpoint:human-verify)
- **Files modified:** 5 (3 in quickshell/, 1 evidence doc, 1 pending todo)

## Accomplishments

- **FM1 (the intermittent scanner-race config-load failure) is permanently closed.**
  `quickshell/.config/quickshell/modules/qmldir` was hand-written to byte-match the exact
  grammar Quickshell's own scanner synthesises (verified via `quickshell -p ... -v -v`
  against the unmodified tree), and confirmed via the trace line `Found qmldir file,
  qmldir synthesization will be disabled for directory ".../modules"`. Proven clean across
  two independent 10-restart proof runs (one per arrangement) and a real session restart —
  zero occurrences of `is not a type` or `Failed to load configuration` in every run.
- **QS-03's per-screen fan-out remains open, with a materially stronger evidence record
  than before this plan.** Two structurally distinct arrangements were attempted (not a
  repeat of 11-04's exact combinations, since neither had this plan's `qmldir` fix
  underneath them): arrangement A (`Variants`+`LazyLoader` declared in `shell.qml`) and
  arrangement B (`Variants` rooted inside `Probe.qml`, `shell.qml` touching `Probe` exactly
  once — the plan's specified fallback, and the exact structural shape 11-04's own
  arrangement 3 tried without a checked-in `qmldir`). Both failed identically on the
  two-screen test. A Stage B diagnostic isolated the failure from a hotplug-timing race
  (tested: daemon started fresh with both screens already present, still failed; tested:
  waited 5 seconds for QML incubation to settle, still failed) to a general
  `Variants`+`PanelWindow` multiplicity limitation on this quickshell 0.3.0-2 build.
- **Session-restart re-proof performed and passed for everything this plan owns.** A real
  Hyprland logout/login (confirmed real via a fresh low PID and three distinct launcher
  timestamps in the log) reproduced the exact same STOP signature: FM1 stays closed, QS-03
  stays honestly failing (now with the DP-1-also-vanishes detail visible too), and
  single-screen summon/dismiss (Super+Shift+G) works correctly. `quickshell-doctor` surfaced
  one additional, unrelated, pre-existing failure (a volume-probe gate rounding-brittleness
  bug from Phase 11) — investigated, confirmed out of scope, and filed as a pending todo
  rather than fixed in this plan.
- Daemon left running and healthy throughout: no crash/abort markers in the launcher log at
  any point, `keybind-doctor` clean, single-screen probe summon/dismiss confirmed both
  in-session and post-restart.

## Task Commits

1. **Task 1: Bounded targeted QS-03 fix — explicit qmldir plus Variants and per-screen LazyLoader** - `288e780` (feat)
2. **Task 2: Session-restart re-proof against the autostart daemon** - checkpoint:human-verify, performed by the orchestrator/user; no code changes, evidence folded into this plan's docs commit below.

**Plan metadata:** (this commit, docs: complete plan)

## Files Created/Modified

- `quickshell/.config/quickshell/modules/qmldir` - explicit type manifest (Probe, ScreencopyProbe) disabling Quickshell's directory-scanner synthesis for modules/, closing FM1
- `quickshell/.config/quickshell/shell.qml` - reduced to a single `Probe { id: probeInstance; onDismissRequested: ... }` + `GlobalShortcut` toggling `probeInstance.active` (arrangement B's shape); `screencopyProbeLoader` left structurally untouched as a control
- `quickshell/.config/quickshell/modules/Probe.qml` - root type changed from `PanelWindow` to `Variants` (`model: Quickshell.screens`), delegate is a per-screen `LazyLoader` wrapping the original unstyled `PanelWindow` panel content, unchanged in appearance/behavior
- `.planning/phases/12-unified-design-token-pipeline/12-QS03-EVIDENCE.md` - full record: precondition, qmldir grammar verification, both arrangements' attempts and failure signatures, the Stage B diagnostic, the session-restart re-proof, budget clause hit, final state left behind
- `.planning/todos/pending/quickshell-doctor-volume-probe-brittle.md` - new pending todo, out-of-scope volume-probe gate brittleness surfaced during Task 2's re-proof

## Decisions Made

- **`modules/qmldir`'s exact grammar follows the verified `-v -v` trace, not the plan's own unverified prose guess.** The plan speculated the checked-in file should have "no `module` header line," but the actual synthesised grammar on this build includes one (`module qs.modules`). Per the task's own instruction to match the trace over doc-form assumptions, the file was written with the header line included, and this held up cleanly across all subsequent proof runs.
- **Arrangement B's code was left in place rather than reverting to the pre-task single-`LazyLoader` shape**, since arrangement B is functionally equivalent to the original design for this host's one physical monitor (`shell.qml` still touches `Probe` exactly once) and is the more contained of the two failed arrangements. `git status --porcelain quickshell/` shows only the `qmldir` addition plus these two files' modifications — nothing half-applied.
- **QS-03 was NOT marked as a completed requirement.** The STOP branch explicitly defers the one-way "accept as permanent limitation" decision (D-13) to Plan 12-02's opening `checkpoint:decision`. Marking the requirement complete here, even with a written STOP record, would misrepresent an open, undecided requirement disposition as closed.
- **The volume-probe gate brittleness surfaced during Task 2's re-proof was investigated, confirmed pre-existing/unrelated, and filed as a pending todo (`.planning/todos/pending/quickshell-doctor-volume-probe-brittle.md`) rather than fixed.** Evidence: `quickshell-doctor` was last touched by Phase 11 commits, not this plan's; the check is an over-strict exact-match on rounding-sensitive raw PulseAudio units, not a real one-step-per-press regression.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `shell.qml` missing `QtQml` import for the `Component` type (arrangement A)**
- **Found during:** Task 1, arrangement A's first load attempt
- **Issue:** `shell.qml` only imported `Quickshell` and `Quickshell.Hyprland`; `Component` (used inside `Variants`' delegate) is a `QtQml` type, not a `Quickshell` one. First load failed: `Failed to load configuration ... caused by @shell.qml[44:9]: Component is not a type.`
- **Fix:** Added `import QtQml` to `shell.qml`.
- **Files modified:** `quickshell/.config/quickshell/shell.qml` (superseded by arrangement B's later rewrite, which does not need this import since it has no local `Component` block)
- **Verification:** Subsequent `-v -v` trace loaded cleanly (`INFO: Configuration Loaded`)
- **Committed in:** `288e780`

**2. [Rule 1 - Bug] `Variants` delegate root (`LazyLoader`) needed an explicit `modelData` property declaration**
- **Found during:** Task 1, both arrangements' first clean-load attempts
- **Issue:** Quickshell's `Variants` sets `modelData` as an initial property on the delegate root object for non-`Item` roots like `LazyLoader` (not merely a context property, as `Item`-rooted `Repeater` delegates receive it). Without a declared property, the load logged `WARN: LazyLoader does not have a property called modelData`.
- **Fix:** Declared `required property var modelData` directly on the `LazyLoader` delegate root in both arrangements.
- **Files modified:** `quickshell/.config/quickshell/shell.qml` (arrangement A, superseded), `quickshell/.config/quickshell/modules/Probe.qml` (arrangement B, kept)
- **Verification:** Subsequent `-v -v` traces show clean loads with zero warnings
- **Committed in:** `288e780`

**3. [Rule 4-adjacent, resolved without escalation per task's own instruction] `modules/qmldir`'s line shape deviates from the plan's prose**
- **Found during:** Task 1, before writing `qmldir`
- **Issue:** The plan's action text asserted the checked-in file should carry "type entries only and no `module` header line" — but the verified `-v -v` trace of the unmodified tree's synthesised `qmldir` includes a `module qs.modules` header line.
- **Fix:** Not escalated as an architectural question — the task's own instruction explicitly directs matching the verified trace grammar over the doc-form prose ("Before finalising the line shape, run `quickshell -p ~/.config/quickshell -v -v` ... match that exact grammar rather than trusting the doc form"). Wrote the file with the header line included.
- **Files modified:** `quickshell/.config/quickshell/modules/qmldir`
- **Verification:** `grep -cE '^(Probe|ScreencopyProbe) ' ...` returns `2` (acceptance criterion met); scanner-disable trace line confirmed present
- **Committed in:** `288e780`

---

**Total deviations:** 3 auto-fixed (2 Rule-1/3 blocking-issue fixes, 1 trace-vs-prose resolution per the task's own explicit methodology instruction)
**Impact on plan:** All three were necessary to get either arrangement to load at all or to match the plan's own verification methodology; none expanded scope beyond the plan's declared files.

## Issues Encountered

- **Both bounded fix attempts failed the two-screen fan-out test with an FM2-class signature**, despite the `qmldir` fix (targeting FM1) working perfectly. This was resolved by exhausting the plan's own budget (two arrangements, one 10-restart proof run each, one Stage B escape-hatch diagnostic) and writing a complete STOP record, per the plan's own explicit design for this exact outcome (D-12/D-13). Not treated as an unresolved problem — the plan's success criteria explicitly accept this outcome as a valid, complete plan closure.
- **`quickshell-doctor`'s post-session-restart run surfaced an unrelated, pre-existing failure** (volume-probe gate brittleness). Investigated to confirm it predates this plan and is not a regression from any file this plan touched; filed as a pending todo rather than fixed, per scope discipline.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- **Plan 12-02's opening `checkpoint:decision` is now live and fully informed.** `12-QS03-EVIDENCE.md` gives it a complete record of every arrangement tried, the exact failure signature of each (now strengthened by the DP-1-also-vanishes detail and the hotplug-vs-startup-timing isolation), and the budget clause that ended this task — the decision to accept QS-03 as a permanent limitation (D-13) or defer further is 12-02's to make, not pre-empted here.
- **FM1 is closed for good**, independent of whatever Plan 12-02 decides about QS-03's fan-out — `modules/qmldir` is a net-positive fix that stays regardless.
- **The daemon and single-screen probe usage (the only configuration this host has in daily use) are unaffected and confirmed working** — Plan 12-02 and later Phase-12 plans that build on `shell.qml`/`Probe.qml` (the token inspector, per D-32's sequencing) can proceed without QS-03's fan-out blocking anything.
- **A pending todo (`quickshell-doctor-volume-probe-brittle`) is now visible to whoever next touches `quickshell-doctor`** — not blocking, not this plan's responsibility, but flagged for future cleanup.

---
*Phase: 12-unified-design-token-pipeline*
*Completed: 2026-07-26*
