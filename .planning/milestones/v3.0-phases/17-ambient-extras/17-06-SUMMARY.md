---
phase: 17-ambient-extras
plan: 06
subsystem: infra
tags: [bash, audit-tooling, hyprland-lua, dynamic-cursors, mpvpaper, phase-close]

# Dependency graph
requires: ["17-01", "17-02", "17-03", "17-04", "17-05"]
provides:
  - "17-cut-sweep.sh — the criterion-3 consumer-check sweep, report-only, --self-test proven able to fire [DRIFT]"
  - "17-cut-sweep-manifest.tsv — 26-row artifact<->consumer manifest covering all five criterion-3 consumers"
  - "17-SWEEP-REPORT.md — the committed sweep result, coverage reconciliation, success-criteria evidence, accepted-gap restatement"
  - "AMB-01 and AMB-02 marked [x] Complete in REQUIREMENTS.md, on evidence"
  - "Phase 17 closed in ROADMAP.md (6/6 plans, progress row, Totals line)"
affects: []

# Actuals (#2632)
actuals:
  tokens: 16000
  tasks: 4
  commits: 4

tech-stack:
  added: []
  patterns:
    - "Pure verdict function (three explicit string arguments, zero filesystem access) driven by two closed-vocabulary predicate interpreters — the same purity discipline quickshell-doctor's T-16-SELFTEST note already established, reused here for a --self-test that can drive all four verdict states deterministically"
    - "Command-substitution exit-code re-propagation ($(...) forks a subshell; an interpreter's own `exit N` only kills that subshell) — any script that calls `exit` inside a function invoked via `var=$(fn ...)` needs an explicit `_die_on_bad_rc $?` immediately after, or a 'loud unknown-input' guard silently degrades into a swallowed failure"

key-files:
  created:
    - .planning/phases/17-ambient-extras/17-cut-sweep.sh
    - .planning/phases/17-ambient-extras/17-cut-sweep-manifest.tsv
    - .planning/phases/17-ambient-extras/17-SWEEP-REPORT.md
  modified:
    - .planning/REQUIREMENTS.md
    - .planning/ROADMAP.md
    - .planning/STATE.md

key-decisions:
  - "The sweep's phase-17 invariant token set (used by S-22/S-23/E-01/E-02) deliberately excludes bare 'mpv', bare 'wallpaper-picker' and bare 'gaming-mode-toggle.sh'/'quickshell-doctor' filenames, because those predate Phase 17 and windowrules.lua:46/:72-73 carry pre-existing lines that would false-positive under a lazy token — exactly the false-positive class 17-04's own SUMMARY flagged for this plan to avoid inheriting."
  - "AMB-01 and AMB-02 marked [x] Complete on evidence (criterion 1/2 both proven by quoted D-26/D-34 evidence plus their respective blocking render gates), not on the strength of five plans being committed."
  - "AMB-02's marking carries an explicit, permanent caveat in the same REQUIREMENTS.md edit: D-35 (loading the plugin declaratively from Lua config) is NOT delivered, on conclusive evidence, and that is a mechanism finding rather than a criterion-2 shortfall — AMB-02's own wording never mandated a specific load path, and the desktop runs correctly on the hyprpm+hyprpm-complete.sh mechanism 17-04 built instead."
  - "The D-38 accepted gap is restated at its live-remeasured size (5 sites / 8 declaration lines across 4 files) rather than trusting 17-05's own closing note ('seven declarations across five files') — the two disagree by one file, and the report states which is correct and why, rather than silently propagating the older number."
  - "Phase-close checkpoint answer: still accepted (2026-08-10) — the D-38 gap stays open, correctly sized, with no sweep-scope extension and no pin revert. Operator independently re-verified the sweep's clean exit and the corrected declaration count before approving."
  - "Rule 1 fix (found live while proving the sweep's own loud-unknown-prefix acceptance criterion): _artifact_present/_ref_present's exit 2 on an unknown manifest-field prefix only terminated the $(...) subshell it ran in, not the main script, so a poisoned row degraded to a plain [FAIL] instead of halting the sweep. Fixed with _die_on_bad_rc, re-propagating the subshell's real exit code after every interpreter call; proven both by a poisoned-manifest reproduction (exit 2, halted cleanly) and a new --self-test replay."

requirements-completed: [AMB-01, AMB-02]

coverage:
  - id: D1
    description: "17-cut-sweep.sh built: pure verdict function (plan_finished/artifact_present/ref_present -> ok/ok-not-started/incomplete/drift), two closed-vocabulary predicate interpreters (ARTIFACT: exec:/file:/dir:/sym:/none; CONSUMER+SCOPE+REF: file/array:<NAME>/nocomment, fixed-string default, ERE only under re:), --self-test synthesising its own fixtures under mktemp -d, no destructive verb or shell evaluation anywhere in the comment-stripped script"
    requirement: AMB-01
    verification:
      - kind: other
        ref: "bash -n exits 0; test -x succeeds; git ls-files -s shows mode 100755; --self-test exits 0 with 26 passed/0 failed including a real [DRIFT] replay (consumer path + line number located) and a poisoned-row-halts-the-whole-sweep replay; comment-stripped grep for rm/sudo/mv/truncate/pkill/'hyprpm '/eval all return 0 occurrences; find -newer + git status --porcelain both clean after a full run"
        status: pass
    human_judgment: false
  - id: D2
    description: "26-row manifest (S-01..S-23, E-01..E-03) covers every artifact the five siblings produce, transcribed from the shipped repo text; live sweep run: OK=25 FAIL=0 DRIFT=0 WARN=0 INFO=1, exit 0"
    requirement: AMB-01
    verification:
      - kind: other
        ref: "awk field-count check: every non-comment row has exactly 9 tab-separated fields; row count 26 (>=24 required); all five named consumers (stow.sh, install.sh, windowrules, contract.json, QML) carry a verdict; E-01 returns zero without false-positiving on windowrules.lua's pre-existing mpv float rule or wallpaper-picker rule; E-02 covers all 38 *.qml files (find count matches); E-03's video-decoding tripwire holds; S-22/S-23 independently confirm autostart.lua and stow.sh carry no phase-17 tokens beyond S-02's own loop"
        status: pass
    human_judgment: false
  - id: D3
    description: "17-SWEEP-REPORT.md written: full verbatim sweep output including every [OK] line, a 61-item coverage reconciliation (40 covered / 9 runtime-only / 12 internal, arithmetic stated), all three success criteria reconciled against quoted evidence, D-38 hyprpm artifact reported with operator-only remediation text, accepted gap restated at 5 sites/8 lines, all three flagged assumptions reconciled (two still-open, one resolved), no fourth assumption authored"
    requirement: AMB-02
    verification:
      - kind: other
        ref: "grep confirms windowrules/qml/contract.json all present; AMB-01/AMB-02 both grep-match in REQUIREMENTS.md; git diff --name-only shows .planning/ paths only for this plan's three commits"
        status: pass
    human_judgment: false
  - id: D4
    description: "Phase-close checkpoint: human read the report, independently re-verified the clean sweep exit and the corrected 5-site/8-line count, and answered 'still accepted' for the D-38 gap"
    requirement: AMB-02
    verification:
      - kind: manual_procedural
        ref: "Coordinator relay, verbatim: 'CHECKPOINT RESOLVED — user response: approved. Accepted-gap answer: still accepted... I independently verified before presenting: the sweep runs clean... and my own count of the cursor-theme declaration lines matches your re-measurement, not 17-05's seven across five files.'"
        status: pass
    human_judgment: true
    rationale: "Plan-mandated blocking checkpoint (gate=blocking) — standing constraint #1's human render-and-look/sign-off gate is load-bearing for phase closes, not a formality; this executor could not auto-approve it (auto_advance is false in this project's config), and the operator's own independent re-verification before approving is exactly the discipline this gate exists to produce."

duration: ~2h execution (Tasks 1-3) + one blocking phase-close checkpoint round-trip
completed: 2026-08-10
status: complete
---

# Phase 17 Plan 06: Criterion-3 Cut Sweep and Phase Close Summary

**Built a report-only, self-test-proven consumer-check sweep that verdicts all 26 artifacts the five sibling plans produced against all five consumers criterion 3 names; ran it clean (25 OK, 0 FAIL, 0 DRIFT); marked AMB-01 and AMB-02 complete on quoted evidence; and closed Phase 17 with the operator's explicit "still accepted" sign-off on D-38's accepted gap — now correctly sized at 5 sites (8 declaration lines across 4 files, not the 3 sites the decision was originally written against).**

## Performance

- **Duration:** ~2h for Tasks 1-3 (tool-assisted), plus one blocking human-verify checkpoint round-trip for Task 4
- **Started:** 2026-08-10 (orchestrator phase-start marker for this plan)
- **Completed:** 2026-08-10
- **Tasks:** 4 (Task 1 tracer, Task 2 auto, Task 3 auto, Task 4 checkpoint:human-verify gate=blocking)
- **Files modified:** 6 (3 created: `17-cut-sweep.sh`, `17-cut-sweep-manifest.tsv`, `17-SWEEP-REPORT.md`; 3 modified: `REQUIREMENTS.md`, `ROADMAP.md`, `STATE.md`)

## Accomplishments

- `17-cut-sweep.sh` built under `.planning/` (never `hypr/.config/hypr/scripts/` — a stowed audit tool would itself be the additive scaffolding drift Phase 17 Owns): a pure three-argument verdict function, two closed-vocabulary predicate interpreters, a `--self-test` mode that synthesises its own fixtures under `mktemp -d` and proves all four verdict states including a real `[DRIFT]` replay with a located consumer path and line number.
- The manifest grew from Task 1's single tracer row (S-02) to all 26 rows named in the plan's `<sweep_inventory>` — `S-01`..`S-23`, `E-01`..`E-03` — every `ARTIFACT`/`CONSUMER`/`REF` transcribed from the shipped repo text at execution time.
- **The live sweep ran clean: `OK=25 FAIL=0 DRIFT=0 WARN=0 INFO=1`, exit 0.** This is a real, reportable result — it means all five sibling plans' own declared "Explicitly NOT produced by this plan" scope boundaries held, checked by a mechanism proven able to fail before being trusted to pass.
- All five consumers criterion 3 names carry a verdict, including `windowrules` (asserted empty on `windowrules.lua`, with the `windowrules.conf` naming reconciliation stated — that file was replaced by the 13.1 Lua cutover) and QML imports (E-02: zero phase-17 tokens across all 38 `*.qml` files; E-03: zero video-decoding tripwire hits, doing double duty as criterion 1's own "not decoded inside QML" boundary check).
- `17-SWEEP-REPORT.md` reconciles all 61 items across the five siblings' "Artifacts this phase produces" sections into `covered`/`runtime-only`/`internal` buckets (40/9/12, arithmetic stated), reconciles all three success criteria against quoted evidence, and restates D-38's accepted gap at its true, live-remeasured size.
- **AMB-01 and AMB-02 marked `[x]` Complete in `REQUIREMENTS.md`**, on the evidence in the report — not on the strength of five plans having been committed.
- **A Rule 1 bug found in the sweep's own loud-unknown-prefix path**, while proving that acceptance criterion against a real poisoned manifest row rather than a direct function call: `exit 2` inside a command-substituted function only killed the subshell, letting a poisoned row limp on as `[FAIL]` instead of halting the sweep. Fixed with `_die_on_bad_rc`; proven fixed by re-running the poisoned-manifest reproduction (now exits 2, halts cleanly) and a new `--self-test` replay.
- **Phase-close checkpoint approved 2026-08-10.** The operator read the report, independently re-verified the sweep's clean exit and the corrected cursor-pin declaration count, and answered **still accepted** for the D-38 gap — it stays open, now correctly sized, with no sweep-scope extension and no pin revert.

## Task Commits

Each task was committed atomically:

1. **Task 1 (tracer): sweep runner + one real tracer row (S-02)** — `403bec8` (feat)
2. **Task 2: full 26-row manifest, clean live sweep run** — `659b35a` (feat) — includes the Rule 1 `_die_on_bad_rc` fix, found while proving this task's own acceptance criteria
3. **Task 3: sweep report, AMB-01/AMB-02 marked, ROADMAP updated** — `3d6a70f` (docs)
4. **Task 4: phase-close checkpoint** — no file diff by design (evidence-only, matching 17-01/17-04's precedent for a checkpoint task that produces no repo change); the operator's "still accepted" decision is recorded in this SUMMARY and in `17-SWEEP-REPORT.md`

## Files Created/Modified

- `.planning/phases/17-ambient-extras/17-cut-sweep.sh` (new) — the sweep runner, report-only by construction
- `.planning/phases/17-ambient-extras/17-cut-sweep-manifest.tsv` (new) — 26-row artifact↔consumer manifest
- `.planning/phases/17-ambient-extras/17-SWEEP-REPORT.md` (new) — the committed sweep result and full phase-close reconciliation
- `.planning/REQUIREMENTS.md` — AMB-01/AMB-02 checkboxes and status-table cells marked Complete, with evidence quoted inline
- `.planning/ROADMAP.md` — Phase 17 checkbox, the 17-06 plan checkbox, the progress-table row, the Totals line (scoped `Edit`, not `Write` — every other phase entry byte-unchanged)
- `.planning/STATE.md` — position tracking moved from "checkpoint pending" through to "Phase 17 closed"

## Decisions Made

See `key-decisions` in frontmatter for the full list with rationale. Summary: the phase-17 invariant token set deliberately excludes bare filenames that predate this phase (dodging the exact false-positive class 17-04 flagged); AMB-01/AMB-02 marked on evidence with AMB-02 carrying an explicit D-35 caveat; the D-38 gap is restated at its live-remeasured size rather than an inherited stale count; the checkpoint's "still accepted" answer is final for this phase; the `_die_on_bad_rc` Rule 1 fix.

---

## 1. D-35 is NOT delivered — stated plainly, with the crash evidence

**Phase 17 closes with a stated unmet objective, not a buried footnote.** D-35's goal — loading the `dynamic-cursors` plugin declaratively from Hyprland's Lua config (`hl.plugin.load()`) rather than through `hyprpm`'s own orchestration — was tested exhaustively by 17-05 across every reachable permission state on the installed Hyprland build (`0.56.2`, commit `efb50993`, 2026-08-05) and found **conclusively unsafe**, not merely unconfirmed:

- **No matching permission grant** → the request resolves to `ASK`, which is a real user-facing Allow/Deny dialog appearing at **every login and every idle-triggered lock**. User-reported verbatim (quoted in `17-05-SUMMARY.md`): *"An application config is trying to load a plugin /var/cache/hyprpm/aorus/dynamic-cursors/dynamic-cursors.so."*
- **A matching permission grant** → the request resolves `ALLOW`, and loading the plugin from inside a config reload triggers **a fatal compositor crash**: two independently reproduced `SIGSEGV`s, `coredumpctl` backtraces demangling to unbounded recursion in `Config::Lua::CConfigManager::reload() -> handlePluginLoads() -> postConfigReload() -> reload()`.
- Both states were tried live and in a nested `hypr-lua-harness` instance before 17-05 removed the `hl.plugin.load()` call from `dynamic-cursors.lua` entirely, replacing it with a comment recording the full reasoning and the exact recursion chain, specifically so nobody re-adds it.

**This finding is legible here at the phase level, not only inside 17-05's own SUMMARY**, because a future reader auditing "did dynamic cursors ever declaratively load" needs the answer at the phase-close document, not three plans deep in a citation chain: **no, and it cannot, on this Hyprland build, without either a permission dialog on every login/lock or a fatal crash.** The plugin loads correctly today through the mechanism 17-04 built instead — `hyprpm` plus `hyprpm-complete.sh`'s post-login orchestration — which is proven working (`hyprctl plugin list` reports it loaded; `getoption` confirms `mode`/`shake` config applied after a real restart).

## 2. The D-38 gap stays open, at its corrected size, by explicit operator decision

D-38 originally named **one file** (`generate.sh`). RESEARCH.md found a third site at `env.lua`. **17-05 then found five sites**, not three. This sweep re-measured live and states the arithmetic precisely:

| # | File | Line(s) | Value |
|---|------|---------|-------|
| 1 | `theme-engine/.config/theme-engine/lib/generate.sh` | 175 | `gtk-cursor-theme-name=BreezeX-RosePine-Linux` (GTK3) |
| 2 | `theme-engine/.config/theme-engine/lib/generate.sh` | 180 | `gtk-cursor-theme-name=BreezeX-RosePine-Linux` (GTK4) |
| 3 | `hypr/.config/hypr/config/env.lua` | 22, 24 | `XCURSOR_THEME`, `HYPRCURSOR_THEME` |
| 4 | `uwsm/.config/uwsm/env` | 16, 18 | `XCURSOR_THEME`, `HYPRCURSOR_THEME` |
| 5 | `thunar/.config/xfce4/xfconf/xfce-perchannel-xml/xsettings.xml` | 6, 10 | `CursorThemeName` (x2) |

**5 sites, 8 declaration lines, 4 distinct files.** Anti-ghost check (both formats resolve to real installed theme directories today — `/usr/share/icons/BreezeX-RosePine-Linux/cursors/` present, `/usr/share/icons/rose-pine-hyprcursor/manifest.hl` present): `[INFO]`, not a pass/fail gate — the point is that a mid-flight cut removing the cursor-theme package declarations from `install.sh` without also reverting these 8 lines would silently break this exact check on the next fresh install, and every theme render would fall back to a stock pointer — the same failure class as the `adw-gtk3-dark` pin already documented in this repo's `CLAUDE.md`.

**Operator decision, 2026-08-10: still accepted.** The gap stays open, correctly sized, excluded from the sweep's own `[DRIFT]` verdicts per D-38's own locked decision (this plan does not override, close, or silently narrow it). No sweep-scope extension. No pin revert. The operator independently re-verified both the sweep's clean exit and the corrected declaration count before approving — see the checkpoint relay quoted in the frontmatter's `coverage` D4 entry.

## 3. The 17-05 SUMMARY discrepancy — which count is correct

`17-05-SUMMARY.md`'s own closing "Next Phase Readiness" section states the pin is *"now seven declarations across five files."* Live re-measurement at this sweep's authoring time (`grep -rn` against the shipped tree, verbatim output captured in `17-SWEEP-REPORT.md`) finds **4 distinct files** (`generate.sh`, `env.lua`, `uwsm/env`, `xsettings.xml` — 17-05's own list names exactly these four, no fifth), carrying **8** individual declaration lines (2 per file), not 7.

**The measured 4-files/8-lines count is the one to trust.** It was re-derived live, directly from the shipped files, at this sweep's own authoring time — not carried forward from an earlier plan's closing arithmetic. 17-05's "seven across five" appears to be an off-by-one slip made while writing that plan's own closing note (it correctly named only four files in the same sentence, then miscounted the surrounding tally). This discrepancy is recorded here and in `17-SWEEP-REPORT.md`'s accepted-gap section explicitly, rather than silently reconciled in either direction — per T-17-21's own mitigation discipline, a false "all clear" (or, symmetrically, an uncorrected miscount) is worse than an open question.

## 4. Out-of-scope commit `72ce22d` — not Phase 17, not swept, not counted as drift

`72ce22d` (`fix(16): grant hyprlock the screencopy permission it was missing`) is **Phase 16 debt**, fixed by the orchestrator during Phase 17's own render-gate work. It is **not** Phase 17 scope, **not** something Phase 17 started, and is **not** swept, attributed to this phase, or counted as phase-17 drift anywhere in this plan's manifest or report. This is stated per this plan's own inherited fact (see the executor's original briefing) and reaffirmed here for the phase-close record: the sweep's 26-row manifest contains zero rows referencing hyprlock's screencopy permission, and the coverage reconciliation table does not list it as an "unplaced" item, because it was never a Phase 17 artifact to place.

## 5. The requirement-marking correction in `996440b` — a process finding worth recording

Earlier in this phase, AMB-01 and AMB-02 were marked complete in `REQUIREMENTS.md` prematurely — before the plans that actually deliver their evidence (17-03's render gate for AMB-01; 17-05's cursor-theme pin and 17-06's own sweep for AMB-02) had run. This was caught and reverted in commit `996440b`, and every subsequent plan (17-03 through 17-05) was explicitly instructed not to touch those two markings, leaving 17-06 — this plan — as the sole owner of marking them, on proof.

**Worth recording as a process finding, not just a historical footnote:** had the premature marking stood, a milestone-level verification pass (or an audit skill reading `REQUIREMENTS.md` as ground truth) would have seen AMB-01/AMB-02 reading `Complete` while three of their five owning plans (17-03, 17-04, 17-05) had not yet run — meaning the render gates that are these requirements' actual load-bearing proof (standing constraint #1: "a human render-and-look gate is load-bearing, not a formality") would not yet have happened. A green requirements table would have been asserting a fact not yet true. This is exactly the failure class `must_haves.prohibitions`' second statement in this plan's own frontmatter exists to prevent ("A requirement must never be marked complete on the strength of a plan having been committed"), and `996440b`'s revert is the concrete precedent that made this plan's own late-and-evidence-gated marking possible rather than assumed.

---

## Coverage Reconciliation Arithmetic

**40 covered + 9 runtime-only + 12 internal = 61 items**, one bucket each, none left unplaced. Full item-by-item breakdown lives in `17-SWEEP-REPORT.md`'s "Coverage reconciliation" section (collapsible `<details>` block). Per-plan: 17-01 (12: 8/2/2), 17-02 (11: 6/1/4), 17-03 (19: 13/2/4), 17-04 (9: 6/3/0), 17-05 (10: 7/1/2).

## Every Non-`[OK]` Row

**There were none.** The only non-`[OK]` line in the entire 26-row run is `S-19`, which is `[INFO]` by design (`MODE=warn` rows never produce a pass/fail verdict) — the D-38 hyprpm cache-artifact report, present/owner/mtime, with the operator's own remediation (`hyprpm remove dynamic-cursors`) printed as text and never executed. No `[FAIL]`, no `[DRIFT]` — nothing required a `fixed`/`routed`/`accepted` disposition beyond S-19's own D-38-modeled `accepted` status (already the row's designed behavior, not a finding).

## The `windowrules` Reconciliation, Stated Plainly

Criterion 3 names `windowrules.conf`. `test -e hypr/.config/hypr/windowrules.conf` fails — that file does not exist and has not since the 13.1 Lua cutover replaced it with `hypr/.config/hypr/config/windowrules.lua`. `windowrules.lua` was swept in its place (`E-01`), returning zero hits for the full phase-17 token set. The token set deliberately **excludes** bare `mpv` and bare `wallpaper-picker` — line 46's pre-existing float rule (`class = [[^(mpv)$]]`) and lines 72-73's pre-existing `wallpaper-picker` named rule both predate Phase 17 by many milestones, and a lazy token would have false-positived on either.

## Branch Outcomes as Found

- **`wallpaper-fullscreen-watch.sh` (S-04, D-27):** does **not** exist. Matches 17-01's own recorded D-26 verdict (PASS on `-p -a full`, D-27 watcher not built) exactly — symmetric absence confirmed live (the file is absent, and no `fullscreen` source name appears in `wallpaper-visibility.sh`'s real allowlist case statement).
- **Cursor-format option (S-21, 17-05's checkpoint):** resolved **option-c** (unify on rose-pine in both formats). `env.lua` and `uwsm/env` both carry `HYPRCURSOR_THEME`/`XCURSOR_THEME` symmetrically — confirmed live via the branch-mode row's own artifact↔consumer symmetry check.

## The Three Flagged Assumptions

1. **AMB-01's spec-less edge-coverage row** (owner 17-01) — **still open**, restated verbatim. No SPEC.md exists for this phase; per protocol, never auto-resolved.
2. **AMB-02's spec-less edge-coverage row** (owner 17-04) — **still open**, same protocol, same disposition.
3. **D-28's `gaming-mode-toggle.sh` dependency** (owner 17-03) — **resolved**, evidence quoted from `17-03-SUMMARY.md`: the file is confirmed live (not dead), only its header comment was stale, corrected and live-verified across both ON/OFF cycles including the stranded-idle case.

No fourth assumption row authored anywhere in this plan — the no-silent-drop equality (2 probe-surfaced items to 2 surfaced assumptions, plus D-28) holds.

## The Requirement Markings and Their Evidence

- **AMB-01:** `[x]` Complete. Evidence: D-26 fullscreen-pause probe PASS (17-01) + the blocking human render-and-look gate APPROVED across two rounds, all 10 steps (17-03) — a real hover-vs-persisted-state bug found by the gate's own round 1 was root-caused and fixed before round 2 approved.
- **AMB-02:** `[x]` Complete. Evidence: D-34 fault injection (exit 0, verbatim warning under both failure triggers, zero pollution) + the blocking degraded-cursor render gate (working cursor confirmed with the plugin unloaded, `hyprpm reload` restored it) — both 17-04. D-36/D-37's mode/shake config live-verified via `getoption` after a real restart (17-05). **Carries the D-35 caveat** (see point 1 above) in the same `REQUIREMENTS.md` edit — a mechanism finding, not a criterion-2 shortfall.

## Acceptance Criteria Not Executed

None omitted. The one item flagged as "not a live end-to-end proof" in `17-SWEEP-REPORT.md` — re-deriving the accepted-gap arithmetic live rather than trusting 17-05's closing count — was in fact executed (that re-derivation is exactly what produced the 5-sites/8-lines correction in point 3 above); it is named there because it is a deliberate methodological choice (re-derive, don't inherit), not a skipped check.

## Issues Encountered

- **A Rule 1 bug in the sweep's own loud-unknown-prefix path** (see Accomplishments and Decisions above) — found live while proving Task 1's own acceptance criteria against a genuinely poisoned manifest row, fixed with `_die_on_bad_rc`, re-verified both by direct reproduction and a new `--self-test` replay. Committed inside Task 2 (`659b35a`).
- **`mpvpaper` was not running at the time this plan closed.** Checked live: `last-wallpaper/catppuccin` currently records a still (`1-totoro.png`), not a live entry, and `wallpaper-visibility.sh`'s own `.actuated` state correctly reads `stopped` — consistent, not broken. This plan touched no runtime wallpaper state (only `.planning/` files and the read-only sweep script), so this reflects the desktop's state from before this plan's session, not a regression caused by it. `hyprctl monitors`/`hyprctl layers` both responsive throughout.

## User Setup Required

None.

## Next Phase Readiness

- **Phase 17 (Ambient Extras) is closed.** All six plans complete, both requirements (AMB-01, AMB-02) marked on evidence, the phase-close checkpoint approved 2026-08-10.
- **D-38's accepted gap remains open by explicit, informed operator decision** — a future contributor touching the cursor-theme pin, the `rose-pine-hyprcursor`/`rose-pine-cursor` package declarations, or `install.sh`'s guarded hyprpm block should read `17-SWEEP-REPORT.md`'s accepted-gap section first; the 8 pin lines and the two package declarations must move together or not at all.
- **D-35 is a closed, negative finding** — `hl.plugin.load()` must not be re-added to `dynamic-cursors.lua`; the file's own header comment carries the full crash evidence for exactly this reason.
- No blockers. This was the last plan of v3.0's Phase 17; the milestone's remaining open items (`OVER-03`/`OVER-04`, `MAINT-02`'s Logout-wrapping debt) are pre-existing, out of this plan's scope, and unaffected by this close.

---
*Phase: 17-ambient-extras*
*Completed: 2026-08-10*

## Self-Check

**Files:**
```
FOUND: .planning/phases/17-ambient-extras/17-cut-sweep.sh
FOUND: .planning/phases/17-ambient-extras/17-cut-sweep-manifest.tsv
FOUND: .planning/phases/17-ambient-extras/17-SWEEP-REPORT.md
FOUND: .planning/REQUIREMENTS.md (AMB-01/AMB-02 both [x])
FOUND: .planning/ROADMAP.md (Phase 17 [x], 17-06 [x], progress row 6/6 Complete)
FOUND: .planning/STATE.md
```

**Commits:**
```
FOUND: 403bec8 (feat(17-06): criterion-3 sweep runner — four-state verdict, proven drift path)
FOUND: 659b35a (feat(17-06): full 26-row sweep manifest — all five criterion-3 consumers verdicted, clean run)
FOUND: 3d6a70f (docs(17-06): sweep report, AMB-01/AMB-02 marked, ROADMAP updated — phase close pending checkpoint)
```

**Claims spot-checked against live state at close:**
- `bash -n .planning/phases/17-ambient-extras/17-cut-sweep.sh` exits 0.
- `.planning/phases/17-ambient-extras/17-cut-sweep.sh --self-test` exits 0, 26 passed / 0 failed.
- `.planning/phases/17-ambient-extras/17-cut-sweep.sh` (full run) exits 0, `OK=25 FAIL=0 DRIFT=0 WARN=0 INFO=1`.
- `git ls-files -s .planning/phases/17-ambient-extras/17-cut-sweep.sh` shows mode `100755`.
- `grep -qE 'AMB-01'`/`'AMB-02'` on `.planning/REQUIREMENTS.md` both match; both show `[x]`.
- `git diff --stat -- .planning/ROADMAP.md` across this plan's commits touches only the Phase 17 section, the progress-table row, and the Totals line.
- `hyprctl monitors -j` and `hyprctl layers -j` both responsive at close; no orphaned process left by this plan (this plan started and stopped no process — it is a read-only audit tool).

## Self-Check: PASSED

No missing files, no missing commits, no unverified claims. The one discrepancy found during this plan's own work (17-05-SUMMARY.md's "seven declarations across five files" vs. this sweep's live-measured "eight declarations across four files") is documented above rather than silently resolved in either direction.
