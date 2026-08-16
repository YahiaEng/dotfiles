---
phase: 22-fresh-install-proof
plan: 04
subsystem: infra
tags: [podman, container-run, theme-doctor, allowlist, retirement-check, stow-link-check, fail-closed]

# Dependency graph
requires:
  - phase: 22-fresh-install-proof
    plan: 07
    provides: "run-20260816T222431Z's theme-doctor failure inventory (571 passed / 3 failed), the sole admissible D-22-09 input, and the repaired podman lifecycle this plan's run reused unmodified"
  - phase: 22-fresh-install-proof
    plan: 02
    provides: "hypr/.config/hypr/scripts/stow-link-check — the dangling-symlink checker this plan calls as a new blocking container step"
provides:
  - "verify/theme-doctor-session-allowlist.txt: 3 entries (gsettings gtk-theme, walker process running, elephant process running), each with a source-justified reason_class (no-session-bus / no-compositor / no-compositor) and a resolvable theme-doctor source_ref"
  - "verify/container-run.sh: five gating steps instead of three — retirement-check --all and stow-link-check newly blocking INSIDE the container (D-22-05/06), theme-doctor converted from informational to BLOCKING against the allowlist (D-22-08), byte-exact/prefix-anchored/LC_ALL=C matching, fail-closed on a missing/unreadable/malformed allowlist (T-22-04-FAILOPEN)"
  - "First real evidence that the modified harness itself works: overall=PASS in run-20260816T230409Z, all nine step tokens present and ok, theme-doctor allowed=3 blocking=0"
affects: [22-05-fresh-install-proof, 22-06-fresh-install-proof]

actuals:
  tokens: 4750
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Committed pipe-delimited allowlist file (match_prefix|reason_class|source_ref|reason), read and validated by pure bash inside the container heredoc — no jq/python3 dependency, mirroring retirement-check's inline REGISTRY_RAW parsing idiom but as a real committed file per D-22-10"
    - "Fail-closed data-file gate: missing/unreadable/malformed allowlist sets status=fail and GATE_FAIL=1 rather than silently degrading to the old informational behaviour — validated by three local dry-runs (deleted file, bad reason_class, wrong field count), all exiting nonzero with a named line"

key-files:
  created:
    - verify/theme-doctor-session-allowlist.txt
  modified:
    - verify/container-run.sh
    - .planning/phases/22-fresh-install-proof/22-REBASELINE.md

key-decisions:
  - "Filled the theme-doctor structural-reason column in 22-REBASELINE.md, not 22-BASELINE.md. The plan text (authored before 22-07 landed) named 22-BASELINE.md, but that document's own inventory table is explicitly empty ('no data — theme-doctor did not run') because the unmodified harness died before install.sh finished in that run. 22-REBASELINE.md is the document that actually carries the measured D-22-09 input (per 22-07's own handoff and this plan's task notes, which name it explicitly as 'THE source of your allowlist input — the only admissible one'). Filling the column in the document with real data, rather than leaving 22-BASELINE.md's honest 'no data' note unedited, keeps the traceability chain intact without fabricating content in a document whose whole point was recording that theme-doctor never ran."
  - "gsettings gtk-theme classified no-session-bus, walker/elephant process checks classified no-compositor — not no-user-session as an initial reading of the check descriptions might suggest. Traced past theme-doctor's own check code to the actual mechanism: reload.sh:48's headless guard (WAYLAND_DISPLAY/DBUS_SESSION_BUS_ADDRESS) is what skips the gsettings write, and autostart.lua:163-164's hl.exec_cmd() calls are Hyprland's own autostart list, which only ever executes when the compositor itself starts — a headless container never starts Hyprland, so nothing ever spawns walker/elephant. Read the check, not just its description string, per the plan's own instruction."

patterns-established:
  - "Byte-exact prefix matching under a single `export LC_ALL=C` set once near the top of a script, rather than scattered per-comparison — bash's `${var:0:n}` substring slicing is character-based (not byte-based) under a multi-byte locale, so the locale must be pinned before any such slice runs, not just at the comparison site."

requirements-completed: []  # RETIRE-09 intentionally NOT marked complete — container tier only. Plan 22-05's fix loop and plan 22-06's graphical VM tier (with its human verdict) are still outstanding, matching every prior plan in this phase's declared precedent (22-01, 22-07, 22-08, 22-09) of declining to close it early.

coverage:
  - id: D1
    description: "theme-doctor gates the container harness's exit code instead of running informationally — ~575 headless-safe checks now count"
    requirement: "RETIRE-09"
    verification:
      - kind: automated
        ref: "verify/container-run.sh theme-doctor step; grep -c 'status=informational' verify/container-run.sh -> 0"
        status: pass
      - kind: manual_procedural
        ref: "run-20260816T230409Z summary.log: step=theme-doctor status=ok allowed=3 blocking=0 (verbatim copy: baseline-evidence/22-04-summary.log)"
        status: pass
    human_judgment: false
  - id: D2
    description: "A theme-doctor failure is admitted only if it appears in a committed allowlist entry carrying a structural reason read from theme-doctor's own source; every other failure fails the gate"
    requirement: "RETIRE-09"
    verification:
      - kind: automated
        ref: "verify/theme-doctor-session-allowlist.txt (3 entries, all source_refs resolve via sed -n); local dry-run against a poisoned log with one extra unrelated [FAIL] line correctly reports [BLOCKING] and exits 1 (allowed=3 blocking=1)"
        status: pass
    human_judgment: false
  - id: D3
    description: "retirement-check --all runs as a blocking step INSIDE the container, asserting its host-package pacman -Q class against the reproduced system rather than the developer host"
    requirement: "RETIRE-09"
    verification:
      - kind: manual_procedural
        ref: "run-20260816T230409Z summary.log: step=retirement-check status=ok; full output baseline-evidence/22-04-04a-retirement-check.log (failed_classes=0 for every registered surface)"
        status: pass
    human_judgment: false
  - id: D4
    description: "stow-link-check runs as a blocking step INSIDE the container against the freshly-stowed builder home"
    requirement: "RETIRE-09"
    verification:
      - kind: manual_procedural
        ref: "run-20260816T230409Z summary.log: step=stow-link-check status=ok; full output baseline-evidence/22-04-04b-stow-link-check.log (3 passed, 0 failed across .config, Pictures/Wallpapers, . roots)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Allowlist matching is byte-exact and prefix-anchored under LC_ALL=C — no case folding, Unicode normalisation or whitespace collapsing"
    requirement: "RETIRE-09"
    verification:
      - kind: automated
        ref: "verify/container-run.sh: export LC_ALL=C set once near script top; match uses quoted string-literal comparison on a character-sliced substring (${desc:0:${#prefix}} == \"$prefix\"), never a glob/regex-interpreted [[ == $prefix* ]]"
        status: pass
    human_judgment: false
  - id: D6
    description: "The new/changed blocking steps run in a defined order (retirement-check, stow-link-check, theme-doctor, theme-parity), each guarded by the existing GATE_FAIL short-circuit; verdict logic and both heredoc safety constraints unchanged"
    requirement: "RETIRE-09"
    verification:
      - kind: automated
        ref: "diff against origin/main: byte-identical from the in-container verdict emission through the outer host-side 'never trust the exit code alone' block and timeout wrapper (everything past the theme-doctor block's own line 359/530 boundary); heredoc delimiter still single-quoted, script still delivered via bash /logs/container-script.sh, not stdin"
        status: pass
    human_judgment: false
  - id: D7
    description: "A missing, unreadable or malformed allowlist fails the gate closed, never open"
    requirement: "RETIRE-09"
    verification:
      - kind: automated
        ref: "three local dry-runs against the extracted allowlist-evaluation logic: deleted file, bad reason_class, wrong field count — all exit 1 with status=fail and a named line number (see 'Deviations/Verification detail' below)"
        status: pass
    human_judgment: false
  - id: D8
    description: "Every allowlist entry that matched nothing on a run is reported as [UNUSED] rather than silently discarded"
    requirement: "RETIRE-09"
    verification:
      - kind: automated
        ref: "verify/container-run.sh: [UNUSED] loop over AL_MATCHED after the [FAIL]-line scan, unconditional (not gated on any failure)"
        status: unknown
    human_judgment: true
    rationale: "The code path exists and was read/reasoned through, but was never exercised live: all 3 allowlist entries matched a real failure on both the local dry-run and the real container run, so [UNUSED] never had a chance to print in this plan's evidence. Confirming it fires correctly needs either a run where a session-dependent check starts passing (removing its need for an entry) or a deliberate scratch test — recorded honestly as unverified-live rather than claimed passing on inference."
    tags: []

duration: ~50min
completed: 2026-08-17
status: complete
---

# Phase 22 Plan 04: Session-Failure Allowlist + Blocking Container Gate Summary

**theme-doctor stopped being informational in the container gate — it now blocks on everything except three source-justified, byte-exact allowlisted session-dependent failures — and two new blocking steps (`retirement-check --all`, `stow-link-check`) run inside the same container, so SC-2's "does any retired surface survive in the reproduced system" question is now answerable there instead of on a dev host that still has the old packages installed. First run of the modified harness: `overall=PASS`, `allowed=3 blocking=0`.**

## Performance

- **Duration:** ~50 min (Task 1 authoring ~15min, Task 2 harness wiring + dry-run proofs ~20min, Task 3 push + one ~9min container run + evidence write ~15min)
- **Tasks:** 3
- **Files modified:** 4 (`verify/theme-doctor-session-allowlist.txt` created, `verify/container-run.sh`, `22-REBASELINE.md`, plus 4 evidence-copy files under `baseline-evidence/`)

## Accomplishments

- **Task 1 — allowlist authored, one entry per measured failure, each justified from source.** All 3 `[FAIL]` lines from `run-20260816T222431Z` (22-07's admissible D-22-09 input) are admitted, zero left as defects — every recorded failure is accounted for in either direction. Traced past theme-doctor's own check code to the actual mechanism producing each failure: `gsettings gtk-theme` fails `no-session-bus` because `theme_engine_reload()`'s headless guard (`lib/reload.sh:48`) skips the whole reload fan-out — including `gtk.sh`'s `gsettings set gtk-theme` call — whenever both `WAYLAND_DISPLAY` and `DBUS_SESSION_BUS_ADDRESS` are unset; `walker`/`elephant process running` both fail `no-compositor` because both are launched only by Hyprland's own autostart list (`autostart.lua:163-164`), which runs only when the compositor itself starts. Filled the structural-reason column in `22-REBASELINE.md` (the document that actually carries the measured data — see Deviations) rather than the empty `22-BASELINE.md`.
- **Task 2 — five gating steps, theme-doctor converted from informational to blocking.** Added `retirement-check --all` (D-22-05, log `04a-`) and `stow-link-check` (D-22-06, log `04b-`) as new blocking steps between `stow` and `theme-doctor`, both invoked through `su - builder -c` against the STOWED paths so `$HOME` and `retirement-check`'s own `DOTFILES_DIR` default resolve correctly. Converted the `theme-doctor` call site: it now runs unconditionally, reads `verify/theme-doctor-session-allowlist.txt` from an explicit `CLONE_DIR=/home/builder/dotfiles` path (the in-container script runs as root, so a bare `$HOME` there resolves to `/root`), validates every record (exactly 4 pipe-delimited fields, `match_prefix` ≥12 bytes, `reason_class` in the closed four-token set, non-empty `source_ref`/`reason`) and fails CLOSED — `status=fail`, `GATE_FAIL=1` — on any missing, unreadable or malformed record, naming the offending line. Matching is byte-exact and prefix-anchored: `export LC_ALL=C` set once near the script's top (so `${var:0:n}` substring slicing is byte-based, not locale-dependent character-based) plus a quoted string-literal comparison, never a glob/regex `[[ == $prefix* ]]`. Prints `[ALLOWED]`/`[BLOCKING]`/`[UNUSED]` per the plan's spec. Confirmed the verdict machinery, the host-side "never trust the exit code alone" block, and the outer timeout wrapper are byte-identical to `origin/main` past the theme-doctor block's own boundary — the only deleted lines anywhere in the diff are header-comment prose and the old informational status line, exactly what the plan's own action instructed rewriting.
- **Task 3 — pushed, ran the modified harness once, recorded the result.** Precondition confirmed (`HEAD == origin/main`, both new files resolve via `git show origin/main:...`) before launching. `verify/container-run.sh` ran once, unmodified beyond this plan's own commits, completing in run `run-20260816T230409Z`: **all nine step tokens present, all `ok`**, `theme-doctor status=ok allowed=3 blocking=0`, `overall=PASS`. Harness exit code 0, no orphaned container (`podman ps -a` empty afterward — T-22-07-DOS's cleanup mechanism from 22-07 held under the new step count with no changes needed). Evidence copied out of the gitignored `verify/logs/` into the phase directory (`22-04-summary.log`, `22-04-05-theme-doctor.log`, `22-04-04a-retirement-check.log`, `22-04-04b-stow-link-check.log`) since it is not otherwise durable.

## Task Commits

Each task was committed atomically:

1. **Task 1: Author the committed session-failure allowlist** — `4662571` (feat)
2. **Task 2: Wire three blocking steps into container-run.sh** — `56a9bd5` (feat)
3. **Task 3: Push and run the modified harness once** — `5657fda` (docs)

**Plan metadata:** *(pending — this SUMMARY + STATE.md + ROADMAP.md commit, made immediately after this document)*

## Files Created/Modified

- `verify/theme-doctor-session-allowlist.txt` — new, 3 entries, header comment documenting format/four-token set/derivation rule/fail-closed rule
- `verify/container-run.sh` — `CLONE_DIR` + `export LC_ALL=C` added near top; two new blocking steps (`retirement-check --all`, `stow-link-check`); `theme-doctor` step converted informational → blocking against the allowlist; header comment rewritten to describe the five-gate reality
- `.planning/phases/22-fresh-install-proof/22-REBASELINE.md` — structural-reason column filled in the `theme-doctor` failure inventory table
- `.planning/phases/22-fresh-install-proof/baseline-evidence/22-04-{summary,05-theme-doctor,04a-retirement-check,04b-stow-link-check}.log` — verbatim copies of this plan's run evidence

## Decisions Made

- **Filled the structural-reason column in `22-REBASELINE.md`, not `22-BASELINE.md`** — see `key-decisions` in frontmatter. `22-BASELINE.md`'s own table is correctly empty because theme-doctor never ran in that document's run; editing it to add data would misattribute the measurement to the wrong run.
- **`gsettings gtk-theme` classified `no-session-bus`; `walker`/`elephant process running` both classified `no-compositor`** rather than a blanket `no-user-session` — see `key-decisions`. Each traces to a specific line in a specific file (`lib/reload.sh:48`, `autostart.lua:163-164`), not to the check's description string alone.
- **`match_prefix` truncated before the variable portion of each description.** `"gsettings gtk-theme = "` stops before the expected-theme-name/mode/observed-value text, since `EXPECTED_GTK_THEME` and `DOCTOR_MODE` can both vary (light vs. dark presets) even though this container always seeds `catppuccin`/dark. `"walker process running"` and `"elephant process running"` are used in full since neither embeds a runtime value.

## Allowlist strictness — what this run does and does not demonstrate

The coordinator asked this be recorded explicitly, plainly: **the live container run itself never exercised the rejection path.** `run-20260816T230409Z`'s real `theme-doctor` output produced exactly the three known, allowlisted failures and nothing else, so the live harness only ever walked the "everything admitted, `blocking=0`" branch of its own logic — nothing in this run proves that a *new*, non-admitted failure would actually make the real, containerized harness exit nonzero end-to-end.

What *does* demonstrate rejection is a **local, out-of-container dry-run** of the identical parsing/matching bash extracted from `container-run.sh` (Task 2's own verification step, re-confirmed here): pointed at the real committed allowlist plus a copy of the real baseline log with one extra, deliberately unrelated `[FAIL]` line appended, it correctly printed `[BLOCKING] some brand new unrelated check`, reported `allowed=3 blocking=1`, and exited 1. Three further local dry-runs (a deleted allowlist file, a record with an invalid `reason_class`, a record with the wrong field count) all exited 1 with a named line, proving the fail-closed path. These are strong evidence the logic itself rejects correctly — but they were run as a standalone script, not inside a real podman container via the real `su - builder -c` invocation chain. No run in this plan deliberately broke something inside a live container to watch the real harness reject it end-to-end (doing so would mean either shipping a real regression or a throwaway harness modification outside this plan's scope). **Net position: the mechanism is proven correct by direct code inspection and an out-of-container replica of its exact logic; the live containerized harness has been proven to correctly ADMIT the three expected failures, but has not itself been observed REJECTING one.**

## Deviations from Plan

### Auto-fixed Issues

None — plan executed as written for both `Task` blocks. The document-target substitution described above (22-REBASELINE.md vs. 22-BASELINE.md) is not a Rule 1-4 deviation in the bug/blocking-issue sense; it is a scope clarification the plan's own task notes explicitly pointed at (22-REBASELINE.md named as "THE source of your allowlist input — the only admissible one under D-22-09"), applied to keep the traceability requirement truthful rather than fabricating data in a document whose own text correctly states theme-doctor never ran there.

## Issues Encountered

- **`bash /logs/container-script.sh` grep count.** The plan's Task 2 acceptance criterion expected `grep -c 'bash /logs/container-script.sh' verify/container-run.sh` to return 1; it returns 2, both before and after this plan's edit (confirmed against `origin/main` directly) — the phrase already appears twice in the pristine file (once in a comment, once in the actual invocation). Not a regression; the criterion's expected count was stale against the file's actual pre-existing state.
- **`git diff origin/main -- verify/container-run.sh | grep -c '^-.*overall='` returning 1, not 0.** The one matching deleted line is inside the header-comment prose this plan's own Task 2 action explicitly instructs rewriting ("Update the exit-code contract paragraph..."), not inside the verdict-logic code. Confirmed by direct byte-range diff that everything from the in-container `overall=PASS`/`overall=FAIL` emission through the host-side verdict block and outer `timeout` wrapper is unchanged from `origin/main`.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- **Plan 22-05's fix-and-re-run loop has nothing to fix.** This run's `overall=PASS` with `allowed=3 blocking=0` means the modified harness itself works correctly and the repository currently has zero defects the new blocking steps caught — `retirement-check --all` and `stow-link-check` both report clean inside the container, and every theme-doctor failure is exactly the three expected, allowlisted ones. Plan 22-05's scope, per its own charter, narrows accordingly.
- **RETIRE-09 remains open by design.** Container tier only — plan 22-06's graphical VM tier and its human verdict are still required before the requirement can close, matching every prior plan in this phase.
- **Push discipline held.** `HEAD == origin/main` was confirmed both before and after the run; `verify/container-run.sh`'s shallow clone genuinely reproduced from the pushed state, not local working-tree state.

---
*Phase: 22-fresh-install-proof*
*Completed: 2026-08-17*

## Self-Check: PASSED

All 8 claimed files verified present on disk; all 3 task commits (`4662571`, `56a9bd5`, `5657fda`) verified present in `git log --oneline --all`.
