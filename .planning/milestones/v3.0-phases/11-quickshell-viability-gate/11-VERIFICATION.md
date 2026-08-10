---
phase: 11-quickshell-viability-gate
verified: 2026-07-26T18:40:00Z
status: passed
status_note: "Canonicalized human_needed -> passed per the verify-work rule for a phase waiting only on human UAT with zero recorded issues. The two backstop truths that produced human_needed are accepted-as-unverified via overrides[1] and overrides[2] — see `closure` below. behavior_unverified stays 2: this phase passed WITH two disclosed unknowns, it did not verify them."
score: 9/9 must-haves verified
behavior_unverified: 2
overrides_applied: 3
overrides:
  - must_have: "Quickshell surfaces render correctly across all connected monitors and survive monitor hotplug (QS-03 / ROADMAP criterion 2)"
    reason: "D-10: only QS-02 carries STOP authority this phase, so QS-03's per-screen-mounting gap is a disclosed, non-blocking finding rather than a phase-goal blocker. A Variants-based fix was written in 11-04 and reverted after it introduced two independent live-daemon reliability regressions on quickshell 0.3.0 — an intermittent config-load race and a post-hotplug visibility break — and shipping that against the always-on autostart daemon was judged worse than the gap it closed. This host has exactly one physical monitor, so the defect has no present user-visible impact. The requirement is not dropped: ownership moves to Phase 12 (Unified Design-Token Pipeline), the first phase that needs a permanent non-summoned QML surface and therefore has to solve per-screen fan-out anyway — see the Phase 12 Requirements line and success criterion 6 in ROADMAP.md, and the QS-03 row in REQUIREMENTS.md traceability."
    accepted_by: "YahiaEng"
    accepted_at: "2026-07-26T12:07:57Z"
  - must_have: "When two clients bind the same XF86Audio* key, which handler wins is deterministic and stable across sessions rather than racing (11-03 backstop truth)"
    reason: "Accepted as UNVERIFIED, not as verified. Presented to the human as 11-UAT.md test 6 and explicitly skipped: exercising it means deliberately breaking a working keybind config and restarting the session twice. No automated check can reach it. It remains listed in behavior_unverified_items and is NOT graded as evidence of correct behaviour — this override closes phase 11 while carrying the unknown forward, rather than pretending it was tested. Relevant to Phases 14 and 16, which each add a new global keybind; re-open it there if a bind-resolution conflict ever surfaces."
    accepted_by: "YahiaEng"
    accepted_at: "2026-07-26T15:36:35Z"
  - must_have: "With zero connected outputs, the shell process survives and re-creates its surfaces when an output returns (11-04 backstop truth)"
    reason: "Accepted as UNVERIFIED, not as verified. Physically untestable on this host — it has exactly one physical monitor, and removing it kills the graphical session performing the test. Presented as 11-UAT.md test 7 and correctly skipped. Disclosed as deliberately untested since 11-QUICKSHELL-EVIDENCE.md's 'Findings and Caveats'. Remains in behavior_unverified_items and is NOT graded as evidence. Phase 12 needs multi-output test infrastructure for QS-03 criterion 6 anyway — that is the natural place to finally exercise this."
    accepted_by: "YahiaEng"
    accepted_at: "2026-07-26T15:36:35Z"
closure:
  closed_at: "2026-07-26T15:36:35Z"
  closed_by: "YahiaEng"
  basis: "Explicit human closure decision. Zero gaps and zero UAT issues; the residual human_needed status came solely from the two backstop truths above, both now accepted-as-unverified via overrides. Note the mechanical predicate `gsd-tools phase uat-passed 11 --require-verification` still reports the three skipped 11-UAT.md rows (tests 6, 7, 16) as non-passing — its allowlist is {passed, pass} with no accepted-unverified state. Those rows were deliberately NOT rewritten to `pass`, because tests 6 and 7 were never performed and test 16 is the overridden QS-03 gap; falsifying them to satisfy the checker would fabricate human attestation. The phase is closed on this recorded decision instead."
re_verification:
  previous_status: gaps_found
  previous_score: 6/9
  previous_verified_at: "2026-07-26T11:49:32Z"
  gaps_closed:
    - "quickshell-doctor performs no persistent mutation beyond the single documented, trap-protected volume-probe exception (CR-02, CR-03 fixed and independently re-run live)"
    - "No manual host-only state is baked into any repo-authored Quickshell config file (CR-01 fixed and independently re-run live: qmllint clean, FileView still resolves via Quickshell.env(\"HOME\"))"
    - "Quickshell surfaces render correctly across all connected monitors and survive monitor hotplug (QS-03) — NOT fixed, but formally accepted via a recorded human override and ownership reassigned to Phase 12 criterion 6; carried forward from the prior report's frontmatter per the preservation instruction for this re-verification"
  gaps_remaining: []
  regressions: []
behavior_unverified_items:
  - truth: "When two clients bind the same XF86Audio* key, which handler wins is deterministic and stable across sessions rather than racing (11-03 backstop truth)"
    test: "Deliberately register a second handler for an already-bound XF86Audio* key across two session restarts and observe which one consistently fires"
    expected: "The same handler wins every time, not a coin-flip"
    why_human: "Marked verification:backstop in 11-03-PLAN.md; the human presented this in 11-UAT.md test 6 and explicitly chose 'skip' — cost of deliberately breaking a working keybind config and two session restarts. Still unverified, not converted into a gap. Relevant to Phases 14 and 16, which each add a new global keybind."
  - truth: "With zero connected outputs, the shell process survives and re-creates its surfaces when an output returns (11-04 backstop truth)"
    test: "Remove every monitor and confirm the quickshell process stays alive and remounts surfaces when an output returns"
    expected: "quickshell process survives with 0 outputs and re-creates its surface(s) when an output reappears"
    why_human: "Physically untestable on this single-monitor host — removing the only output kills the graphical session running the test itself. Presented in 11-UAT.md test 7 and correctly skipped. Worth revisiting in Phase 12 alongside the QS-03 per-screen fan-out work, which needs multi-output test infrastructure anyway."
human_verification:
  - test: "Deliberately register a second handler for an already-bound XF86Audio* key across two session restarts and observe which one consistently fires"
    expected: "The same handler wins every time, not a coin-flip"
    why_human: "Marked verification:backstop in 11-03-PLAN.md — no automated check exercises resolution order under a deliberately-created conflict"
  - test: "Remove every connected monitor and confirm the quickshell process stays alive and re-mounts its surface(s) when an output returns"
    expected: "Process survives with 0 outputs; surfaces reappear when an output does"
    why_human: "This host has exactly one physical monitor; removing it would kill the graphical session performing the test"
---

# Phase 11: Quickshell Viability Gate Verification Report

**Phase Goal:** Quickshell is proven to work on this exact machine — pointer, keyboard, focus, dismiss, multi-monitor, hot reload, and peaceful coexistence with everything already running — or the milestone stops here.
**Verified:** 2026-07-26T18:40:00Z
**Status:** human_needed
**Re-verification:** Yes — after gap closure. Previous verification: `2026-07-26T11:49:32Z`, status `gaps_found`, score `6/9`.

## What changed since the prior report

The prior report found 3 gaps. This re-verification independently re-confirmed all three claimed
resolutions directly against the live codebase and a live re-run of both doctor scripts — none of
the following is taken on the SUMMARY/REVIEW-FIX narrative's word alone:

1. **CR-01 (hardcoded home path)** — `quickshell/.config/quickshell/modules/Probe.qml:56` read
   directly: now `path: Quickshell.env("HOME") + "/.local/state/quickshell/probe.json"`, no literal
   `/home/aorus` string anywhere in the file (`grep -n '/home/aorus' Probe.qml` — no match).
   `qmllint` run fresh against the file during this verification: clean, exit 0. Commit `74ec933`
   confirmed via `git show --stat`. Human-confirmed live in 11-UAT.md test 3 (hand-edited
   `probe.json` label propagated with zero restart — the exact behavior a bad `Quickshell.env`
   substitution would have silently broken).

2. **CR-02 / CR-03 (unarmed mutation sites in `quickshell-doctor`)** — both read directly in the
   live file. CR-02: the headless-output "remove" step (lines 477-484) now arms
   `PROBE_SUMMONED_FOR_HEADLESS_TEST=1` before the summon dispatch and disarms it to `0` after the
   dismiss dispatch, reusing the same flag `_qsd_cleanup` already checks. CR-03: the reserved-space
   loop (lines 217-222) now sets `RESERVED_CHECK_SUMMONED="${m_appid}:${m_name}"` before dispatch and
   clears it after, with a new matching branch in `_qsd_cleanup` (lines 130-133). `bash -n` and
   `shellcheck -x` both run fresh during this verification: clean. Commits `1945a81` (CR-02) and
   `3ec4661` (CR-03) confirmed via `git show --stat`. Also re-confirmed live: WR-01's volume-arithmetic
   guard (lines 312-316, 327-331) and WR-02's narrowed MPRIS pattern (line 294) are both present in
   the running file, commits `2529894`/`9978851`.

3. **QS-03 per-screen fan-out** — **not fixed**, and this re-verification does not pretend otherwise.
   A fresh live run of `quickshell-doctor` during this verification pass reproduced the identical,
   honest failure: `[FAIL] per-screen surface creation (QS-03): ... under DP-1 (found: 1) and ...
   under HEADLESS-23 (found: 0)`, 13 passed / 1 failed, exit 1 — same shape as every prior run, no
   regression, no silent fix. This gap is **formally accepted, not resolved**, via the human override
   recorded in this file's own frontmatter (carried forward verbatim per this re-verification's
   preservation instruction, `accepted_by: YahiaEng`, `accepted_at: 2026-07-26T12:07:57Z`).
   Independently cross-checked against ROADMAP.md and REQUIREMENTS.md: both were amended on
   2026-07-26 — ROADMAP's Phase 11 criterion 2 now carries the amendment inline, Phase 12 now lists
   QS-03 on its `Requirements` line and as its own success criterion 6, and REQUIREMENTS.md's QS-03
   traceability row now points at Phase 12. Per Step 3b (override handling), an overridden truth is
   scored as `PASSED (override)` and counts toward `verified_truths` — it is not filed as a
   `deferred` item under Step 9b, since Step 9b applies to gaps that have not already gone through an
   accepted override. The override and the later-phase reassignment are two records of the same
   decision, not two separate mitigations.

## Goal Achievement

With CR-01/02/03 (and WR-01/02) fixed and independently re-confirmed, and QS-03 carrying a valid,
roadmap-consistent human override, every one of this phase's 9 must-have truths now resolves to
either VERIFIED or PASSED (override) — a clean improvement from the prior 6/9. Nothing regressed:
the same live re-run of `quickshell-doctor` that reproduces the QS-03 gap also reproduces every
previously-passing check (namespace discipline, reserved-space diff, keybind-doctor cross-check,
single-owner event sources, volume-probe baseline match) with no new failure.

The phase goal's "pointer, keyboard, focus, dismiss" clause continues to hold on QS-02's
human-attested first-attempt pass (the sole STOP-authority gate). The "multi-monitor" clause is now
formally and transparently scoped down by an accepted override rather than left as an unowned,
undecided gap — the project explicitly decided to proceed with a known, disclosed limitation and
recorded who decided it and why. "Hot reload" and "peaceful coexistence" both continue to hold,
re-confirmed live in this pass. The phase's own code-quality debt (the three CRITICAL findings) is no
longer outstanding.

Two truths remain **behavior-unverified**, not verified and not failed: they were deliberately
presented to a human in 11-UAT.md and deliberately skipped (cost/physical-impossibility, not
oversight). They do not block the phase, but they do route this verification to `human_needed`
rather than `passed` — per the decision tree, a clean gap count does not by itself produce `passed`
when unresolved human-verification items exist.

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | QS-01: `install.sh`/`stow.sh`/`quickshell/` package all land in one commit | ✓ VERIFIED | `git show --stat 1aea012` (unchanged since prior verification — regression-checked, still present) |
| 2 | QS-02: human can click a button, type into a field, and dismiss by clicking outside on a Quickshell layer-shell surface | ✓ VERIFIED (human-attested) | Original 11-01 attestation, plus a fresh human re-confirmation in 11-UAT.md test 2 (post-CR-01 fix) — pass, first attempt |
| 3 | QS-03: surfaces render correctly across all connected monitors and survive hotplug | **PASSED (override)** | Live re-run this verification: `quickshell-doctor` still reports `[FAIL] per-screen surface creation (QS-03)` (13 passed, 1 failed, exit 1) — genuinely unfixed. Accepted via the recorded override in this file's frontmatter (D-10, accepted by YahiaEng 2026-07-26T12:07:57Z); ownership reassigned to Phase 12 criterion 6, cross-confirmed in ROADMAP.md and REQUIREMENTS.md. Hotplug add/remove mechanics, reserved-space diff, and suspend/resume independently still PASS |
| 4 | QS-04: editing config hot-reloads the running shell without manual restart | ✓ VERIFIED (human-attested), scope-narrowed | Unchanged since prior verification; re-confirmed indirectly via 11-UAT.md test 3 (FileView/JsonAdapter propagation re-passed post-fix) |
| 5 | QS-05: shell autostarts and coexists with waybar/swaync/SwayOSD/wleave/AGS/walker | ✓ VERIFIED | Live re-run this verification: `quickshell-doctor` namespace discipline, reserved-space diff, and `keybind-doctor` cross-check all PASS |
| 6 | QS-06: no double-handled event source (MPRIS/PipeWire/hardware keys/Notifications) | ✓ VERIFIED | Live re-run this verification: single `org.freedesktop.Notifications` owner (swaync); all 10 XF86Audio*/XF86MonBrightness* keys exactly 1 handler each; 0 MPRIS writers under the new narrowed WR-02 check; volume delta 3277==3277, restored correctly |
| 7 | MAINT-01: `keybind-doctor` correctly parses `hyprctl binds` plain-text output and cross-checks Quickshell chords | ✓ VERIFIED | Live re-run this verification: 13 passed, 0 failed, exit 0 (80 declared binds now vs. 79 at last verification — a bind was added since, unrelated to this phase; parser still tracks correctly) |
| 8 | quickshell-doctor performs no persistent mutation beyond the single documented, trap-protected volume-probe exception | ✓ VERIFIED (fixed) | CR-02/CR-03 confirmed present and correct by direct file read: both new summon sites now arm/disarm a flag with a matching `_qsd_cleanup` branch (lines 105-133, 217-222, 477-484). `bash -n` + `shellcheck -x`: clean |
| 9 | No manual host-only state is baked into any repo-authored Quickshell config file | ✓ VERIFIED (fixed) | CR-01 confirmed by direct file read: `Probe.qml:56` now uses `Quickshell.env("HOME")`, no literal path. `qmllint`: clean, exit 0. Live-confirmed functional via 11-UAT.md test 3 |

**Score:** 9/9 truths verified (1 via accepted override; 2 additional truths tracked separately as behavior-unverified, not counted in this denominator — see below)

### Behavior-Unverified Truths (not counted toward score)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 10 | XF86 duplicate-key handler resolution is deterministic across sessions (11-03 backstop) | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Never exercised; presented and deliberately skipped in 11-UAT.md test 6 |
| 11 | Zero-connected-output survival and re-mount (11-04 backstop) | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Physically untestable on this single-monitor host; presented and correctly skipped in 11-UAT.md test 7 |

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `quickshell/.config/quickshell/shell.qml` | Headless ShellRoot, LazyLoader summon mechanism, two GlobalShortcuts | ✓ VERIFIED, wired | Unchanged since prior verification; `grep -n GlobalShortcut` confirms both `probe` and `screencopy-probe` still declared |
| `quickshell/.config/quickshell/modules/Probe.qml` | QS-02 instrumentation panel | ✓ VERIFIED, fixed | CR-01 resolved: `Quickshell.env("HOME")` in place of the hardcoded path. `qmllint` clean this verification pass |
| `quickshell/.config/quickshell/modules/ScreencopyProbe.qml` | Criterion-5 live capture tiles | ✓ VERIFIED, wired | Unchanged since prior verification; `ScreencopyView`/`ToplevelManager` references still present (6 hits) |
| `quickshell/.config/quickshell/shortcuts.json` | Declared appid/name/chord manifest | ✓ VERIFIED | Unchanged; both manifest entries still cross-check live against `hyprctl globalshortcuts` |
| `hypr/.config/hypr/scripts/keybind-doctor` | Repaired plain-text parser + Quickshell cross-check | ✓ VERIFIED, wired | Live run this verification: 13 passed, 0 failed, exit 0 |
| `hypr/.config/hypr/scripts/quickshell-doctor` | Seventh rerunnable coexistence gate | ✓ VERIFIED, fixed | CR-02/CR-03/WR-01/WR-02 all confirmed present and correct by direct read; `bash -n`/`shellcheck -x` clean. Live run: 13 passed, 1 failed (only the accepted QS-03 gap), exit 1 |
| `hypr/.config/hypr/config/permissions.conf` | Sourced, inert screencopy permission config | ✓ VERIFIED, wired | Unchanged; still sourced from `hyprland.conf:13`, `enforce_permissions = false` confirmed at line 71 |
| `.planning/phases/11-quickshell-viability-gate/11-QUICKSHELL-EVIDENCE.md` | Single verdict, filled gate table, reproduce section | ✓ VERIFIED | Unchanged; all 7 requirement rows and verdict line present |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `autostart.conf` | `quickshell-launch.sh` → `shell.qml` | `exec-once` | ✓ WIRED | Live process confirmed running this verification pass (`pgrep -f 'quickshell -p'` → pid 305128) |
| `stow.sh` PACKAGES `quickshell` | `~/.config/quickshell` symlink tree | stow | ✓ WIRED | Unchanged since prior verification |
| `keybinds.conf` `global` dispatcher | `shortcuts.json` manifest → `hyprctl globalshortcuts` | GlobalShortcut | ✓ WIRED | Live-confirmed this verification: both `quickshell:probe` and `quickshell:screencopy-probe` present in `hyprctl globalshortcuts` |
| `Probe.qml` FileView path | `~/.local/state/quickshell/probe.json` → JsonAdapter → label | FileView/watchChanges | ✓ WIRED, no longer hardcoded | CR-01 fixed; portable `Quickshell.env("HOME")` path confirmed by direct read and human-reconfirmed live in 11-UAT.md test 3 |
| `install.sh` PACMAN_PKGS `quickshell` | pacman dependency closure | pacman | ✓ WIRED | Unchanged since prior verification |
| `quickshell-doctor` | `keybind-doctor` (exit code) | internal invocation | ✓ WIRED | Confirmed via live run this verification pass |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| `keybind-doctor` exits clean against real config | `bash hypr/.config/hypr/scripts/keybind-doctor` | 13 passed, 0 failed, exit 0 | ✓ PASS |
| `quickshell-doctor` full live run (includes summon/dismiss and headless-output hotplug) | `bash hypr/.config/hypr/scripts/quickshell-doctor` | 13 passed, 1 failed, exit 1 — sole failure is the accepted QS-03 gap; volume-probe matched baseline exactly (3277==3277), fully restored | ⚠️ PARTIAL — matches the phase's own accepted, overridden defect, no new regression found |
| `Probe.qml` lints clean after CR-01 | `qmllint quickshell/.config/quickshell/modules/Probe.qml` | exit 0, no output | ✓ PASS |
| `quickshell-doctor` shell syntax + static analysis after CR-02/03/WR-01/02 | `bash -n ...; shellcheck -x ...` | both clean | ✓ PASS |
| Debt-marker scan (TBD/FIXME/XXX/TODO/HACK/PLACEHOLDER) across all phase-modified files | `grep -nE ...` over quickshell-doctor, keybind-doctor, Probe.qml, shell.qml, ScreencopyProbe.qml, quickshell-launch.sh | Only match: `Probe.qml:90 placeholderText: "Type here"` — a legitimate QtQuick `TextField` property, not a stub marker | ✓ PASS |
| Working tree clean (no stray state committed) | `git status --porcelain` | empty | ✓ PASS |
| `hyprctl globalshortcuts` lists both manifest entries | `hyprctl globalshortcuts` | `quickshell:probe`, `quickshell:screencopy-probe` both present | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| QS-01 | 11-01 | install.sh/stow.sh/quickshell package, same commit | ✓ SATISFIED | Commit `1aea012`, unchanged |
| QS-02 | 11-01, 11-05 | Human click/type/click-outside-dismiss gate, STOP authority | ✓ SATISFIED | Human-attested PASS, re-confirmed post-fix in 11-UAT.md |
| QS-03 | 11-04 | Renders correctly on every monitor, survives hotplug | **DEFERRED (accepted override, reassigned to Phase 12)** | Per-screen mounting still fails mechanically; formally accepted, not silently passed. ROADMAP.md, REQUIREMENTS.md, and STATE.md all consistently show this reassignment as of 2026-07-26 |
| QS-04 | 11-04, 11-05 | Hot-reload without manual restart | ✓ SATISFIED (scope-narrowed) | Unchanged, re-confirmed indirectly |
| QS-05 | 11-03, 11-05 | Autostart + coexistence, no collision/shift/duplicate keybind | ✓ SATISFIED | quickshell-doctor + keybind-doctor both green on QS-05's own checks, live re-run |
| QS-06 | 11-03 | Single-owner event sources | ✓ SATISFIED | All checks PASS live, including the narrowed WR-02 MPRIS check |
| MAINT-01 | 11-02 | keybind-doctor plain-text parsing repair | ✓ SATISFIED | 13/0 live this pass |

No orphaned requirements: all 7 IDs declared across the phase's plans match REQUIREMENTS.md's Phase 11 traceability rows, and QS-03's row correctly now points to Phase 12 rather than being silently dropped.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Status this re-verification |
|---|---|---|---|---|
| `quickshell/.config/quickshell/modules/Probe.qml` | 56 (was) | Hardcoded `/home/aorus/...` path (CR-01) | 🛑 Blocker | **RESOLVED** — `Quickshell.env("HOME")` confirmed live, `qmllint` clean |
| `hypr/.config/hypr/scripts/quickshell-doctor` | ~445-451 (was) | Unarmed probe summon/dismiss in headless-remove step (CR-02) | 🛑 Blocker | **RESOLVED** — flag armed/disarmed, confirmed live |
| `hypr/.config/hypr/scripts/quickshell-doctor` | ~198-217 (was) | Unarmed summon/dismiss loop over manifest surfaces (CR-03) | 🛑 Blocker | **RESOLVED** — new `RESERVED_CHECK_SUMMONED` flag + `_qsd_cleanup` branch, confirmed live |
| `hypr/.config/hypr/scripts/quickshell-doctor` | 294-317 (was) | Volume-probe arithmetic on unvalidated regex extraction (WR-01) | ⚠️ Warning | **RESOLVED** — emptiness-guarded before arithmetic and before the restore trap relies on it |
| `hypr/.config/hypr/scripts/quickshell-doctor` | 275-283 (was) | MPRIS-writer check as bare substring match (WR-02) | ⚠️ Warning | **RESOLVED** — narrowed to an actual API-surface pattern |
| `hypr/.config/hypr/config/keybinds.conf` | 209 | Misplaced `windowrule` line (IN-01) | ℹ️ Info | Not in fix scope (info-tier); no functional impact, unchanged |
| `install.sh` | 369 | Inconsistent `$AUR_HELPER` quoting (IN-02) | ℹ️ Info | Not in fix scope (info-tier); harmless, unchanged |

All three Blocker items and both Warning items from the prior code review are now resolved and independently re-confirmed present-as-fixed in the live codebase during this verification pass. The two remaining Info-tier items were explicitly out of the fix scope (`11-REVIEW-FIX.md` frontmatter: `findings_in_scope: 5`, IN-01/IN-02 excluded) and carry no phase-goal weight.

### Human Verification Required

Two backstop-tier must-haves remain deliberately unexercised. Both were formally presented to a
human in 11-UAT.md (tests 6 and 7) after this phase's code fixes landed, and both were explicitly
skipped by the human rather than silently assumed — this is a deliberate, disclosed state, not an
oversight, but it still routes this verification to `human_needed` per the decision tree (a
behavior-unverified truth is never counted as VERIFIED on presence alone).

#### 1. XF86 duplicate-key handler determinism

**Test:** Deliberately register a second handler for an already-bound `XF86Audio*` key across two session restarts and observe which one consistently fires.
**Expected:** The same handler wins every time, not a race.
**Why human:** Marked `verification: backstop` in 11-03-PLAN.md; presented in 11-UAT.md test 6 and skipped by the human (cost of deliberately breaking a working keybind config and restarting twice). Relevant to Phases 14 and 16, which each add a new global keybind.

#### 2. Zero-output survival

**Test:** Remove every connected monitor and confirm the `quickshell` process stays alive and re-mounts its surface(s) when an output returns.
**Expected:** Process survives with 0 outputs; surfaces reappear when an output does.
**Why human:** This host has exactly one physical monitor; removing it would kill the graphical session performing the test. Presented in 11-UAT.md test 7 and correctly skipped. Worth revisiting in Phase 12 alongside the QS-03 per-screen fan-out work, which needs multi-output test infrastructure anyway.

### Gaps Summary

No live, unaccepted gaps remain. All 3 gaps from the prior verification are resolved:

1. **QS-03's per-screen-mounting defect** — genuinely still present in the code (re-confirmed by a
   fresh live `quickshell-doctor` run during this verification), but it is no longer unowned or
   silently blessed. It carries a properly-recorded human override in this file's own frontmatter
   (`accepted_by: YahiaEng`, `accepted_at: 2026-07-26T12:07:57Z`) and formal ownership reassignment to
   Phase 12 (ROADMAP.md success criterion 6, REQUIREMENTS.md traceability, STATE.md blockers list —
   all three independently checked and consistent). Per Step 3b, this truth is scored `PASSED
   (override)` and counts toward the verified total, rather than being filed as a separate `deferred`
   item — the override already is the authoritative record of "this is not a live gap, it is an
   accepted, reassigned one."

2. **CR-01/CR-02/CR-03** — all three CRITICAL code-review findings, plus both WR-01/WR-02 warnings,
   are fixed and independently re-verified against the live files during this pass (not taken from
   `11-REVIEW-FIX.md`'s narrative alone): `qmllint` clean on `Probe.qml`, `bash -n`/`shellcheck -x`
   clean on `quickshell-doctor`, and a fresh live run of both doctor scripts reproduces exactly the
   expected shape (keybind-doctor 13/0 exit 0; quickshell-doctor 13/1 exit 1, sole failure the
   accepted QS-03 gap, volume restored to baseline with zero drift).

The only reason this report is not `passed` is that two backstop-tier truths remain genuinely
unexercised by any test — not because anything is broken, but because they were deliberately,
correctly deferred to a human who has already been asked and declined (for good reason) to exercise
them in this session. This is a `human_needed` status, not a gap.

---

_Verified: 2026-07-26T18:40:00Z_
_Verifier: Claude (gsd-verifier)_
_Previous verification: 2026-07-26T11:49:32Z (status: gaps_found, score: 6/9) — see re_verification block in frontmatter for the full gap-closure trace_
