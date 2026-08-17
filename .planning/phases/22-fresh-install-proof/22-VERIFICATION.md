---
phase: 22-fresh-install-proof
verified: 2026-08-17T03:10:00Z
status: passed
score: 4/4 must-haves verified
behavior_unverified: 0
overrides_applied: 0
gaps: []
behavior_unverified_items:
  - truth: "SC-1 — the D-34/D-36 container gate runs green against a genuine fresh remote clone through install.sh + stow.sh, with theme-parity passing inside that fresh install, on the CURRENT codebase (HEAD e6baeb0)"
    test: "Let the in-progress container run (verify/logs/run-20260817T000253Z, PID 349651, started 2026-08-17T00:02:53Z) finish, or trigger a fresh `bash verify/container-run.sh` run"
    expected: "summary.log ends with all nine step tokens status=ok and overall=PASS, produced by the harness AFTER the CR-01/CR-02/WR-01..05 fixes (commits 599099b..d1dfdc7), not just the pre-fix run this phase's evidence currently cites"
    why_human: "The only completed green run (run-20260816T230409Z, cited as SC-1's evidence in 22-VERIFICATION-RECORD.md) predates the code review's two Critical fixes by ~40 minutes of wall-clock and 7 commits. The review reproduced both false-PASS bugs and their fixes against extracted logic outside a container, not via a full re-run. A container run against the fixed harness was actively executing at verification time (still in the AUR package-build step) and had not reached a verdict."
human_verification:
  - test: "Confirm the in-progress post-fix container re-run reaches overall=PASS"
    expected: "verify/logs/run-20260817T*/summary.log shows all nine gating steps status=ok, overall=PASS, at HEAD e6baeb0 or later"
    why_human: "Cannot be observed by static code inspection — requires waiting for a running podman container to finish (AUR builds in progress at verification time) and reading its actual exit verdict"
  - test: "Confirm the docs/superpowers/ and .claude/CLAUDE.md historical waybar/swaync/etc. mentions are an accepted, intentional carve-out of SC-3's 'zero hits ... across the whole repo' wording"
    expected: "Either an explicit acceptance that RETIRE-01's REPORT-domain design (D-18-37, established Phase 18) already answers SC-3 by treating historical prose as non-blocking, or a decision that these ~34+ non-.planning hits need remediation beyond the two files 22-03 already fixed (README.md, env.lua)"
    why_human: "This is a scope/intent judgment about what SC-3's roadmap wording means, not a code-correctness question — the retirement-check script's own two-tier design (blocking vs. REPORT) was an architectural decision from an earlier phase (RETIRE-01), not something 22 could unilaterally reinterpret"
---

# Phase 22: Fresh-Install Proof Verification Report

**Phase Goal:** A clean clone of the post-migration repo still reproduces the whole themed desktop — the milestone's closing regression gate for five package deletions.
**Verified:** 2026-08-17T03:10:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | SC-1: container gate runs green against a genuine fresh remote clone through `install.sh` + `stow.sh`, `theme-parity` passing | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Green run `run-20260816T230409Z` (`overall=PASS`, all 9 step tokens `ok`) exists and its raw logs are substantive (real 43+92+1=136-symlink sweep, real `571 passed, 3 failed` theme-doctor summary matching the allowlist's 3 named entries exactly) — but that run predates 7 harness-fix commits (`599099b`..`d1dfdc7`, landed 2026-08-17T02:5x-03:00) that closed 2 Critical false-PASS bugs in the very steps that produced this evidence. A post-fix re-run (`verify/logs/run-20260817T000253Z`) was actively running at verification time and had not yet reached a verdict (still in `install.sh`'s AUR package-build phase, ~5.5 min elapsed, PID 349651 confirmed live via `ps`). See `behavior_unverified_items`. |
| 2 | SC-2: no waybar/swaync/swayosd/wleave/ags package, config, symlink, contract entry or dangling reference exists in the reproduced system | ✓ VERIFIED | `green-evidence/04a-retirement-check.log`: `failed_classes=0` across all 13 blocking classes × 5 surfaces, run **inside** the container (`/home/builder/dotfiles`), including `host-package` (`pacman -Q` against the container itself). `green-evidence/04b-stow-link-check.log`: 3 passed / 0 failed, 136 symlinks swept, none dangling. Independently corroborated by the VM tier (real hardware, not a container) reporting PASS with zero exemptions. Dev-host `pacman -Q waybar swaync swayosd wleave ags` also returns "not found" for all five (informative only — not the proof, since the dev host retains git history of the old packages and 22's own notes correctly caution against trusting it). |
| 3 | SC-3: retirement checklist script reports zero (blocking-class) hits for waybar/swaync/swayosd/wleave/ags plus wlogout/eww across the whole repo | ✓ VERIFIED (with a scope caveat) | `green-evidence/04a-retirement-check.log`: `failed_classes=0` for all 8 registered surfaces (the 5 named + `wlogout`, `eww`, plus the `retirement-fixture` self-test surface), confirmed against the script's own registry (`retirement-check:88-94`). **Caveat, not a gap:** the script's own architecture (`D-18-37`, `retirement-check:30-31,182-184`, established in Phase 18/RETIRE-01, not this phase) puts `planning-archive`/`repo-prose` hits in a `REPORT` domain that is explicitly never a `[FAIL]` — so SC-3's literal "reports zero hits ... across the whole repo" is not literally true (repo-prose hits are non-zero: e.g. `waybar` still appears ~34 times outside `.planning`, in `docs/superpowers/*` historical design docs and `.claude/CLAUDE.md`, all correctly past-tense/historical, confirmed by direct `grep`). Plan 22-03's one-time human read fixed the two known **live** (non-historical) hits (README.md's Notifications row, `env.lua`'s client enumeration) but did not touch `docs/superpowers/`, which sits outside its declared scope. |
| 4 | RETIRE-09's own pass condition (`VERIFICATION.md` D-53): `theme-doctor` 0 failures beyond the exemption list AND `theme-parity` 0 failures AND human visual confirmation on the VM's own display | ✓ VERIFIED | `22-VERIFICATION-RECORD.md` § VM tier: operator's verbatim four-part verdict (PASS / no exemptions / nothing unexpected / VM confirmed destroyed), returned against a real graphical VM with a real compositor and D-Bus session — the one axis the container structurally cannot answer. The four session-dependent checks the container must allowlist (walker/elephant process, `gsettings gtk-theme`, `elephant listproviders`) passed on the VM with **no allowlist needed**, which is exactly the corroboration this tier exists to provide. |

**Score:** 3/4 truths verified (1 present, behavior-unverified — pending the currently-running post-fix container re-run)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `verify/container-run.sh` | 9 blocking gating steps (pull/bootstrap/clone/install/stow/retirement-check/stow-link-check/theme-doctor/theme-parity) | ✓ VERIFIED | All 9 `step=` tokens present (`grep -n "step="` confirms); `TD_RC` gating (CR-02 fix) and cache-dir `mkdir \|\| exit 1` (WR-03 fix) both present in the file at HEAD |
| `hypr/.config/hypr/scripts/stow-link-check` | Fails closed on python3 crash/absence (CR-01) | ✓ VERIFIED | `run_sweep()` captures the real exit status via a temp file rather than a process-substitution read loop, per code review's fix description; file content matches the described fix |
| `theme-engine/.config/theme-engine/theme-doctor` | Piped `grep -q` calls immune to SIGPIPE/pipefail (WR-01) | ✓ VERIFIED | Referenced fix commit `57ab7c2` present in `git log`; no debt markers found in file |
| `verify/theme-doctor-session-allowlist.txt` | 3 sourced, byte-exact-prefix entries covering exactly the 3 session-dependent failures | ✓ VERIFIED | File read directly — 3 entries (`gsettings gtk-theme =`, `walker process running`, `elephant process running`), each with `reason_class`/`source_ref`/`reason`, matching the green run's actual 3 `[FAIL]` lines exactly |
| `hypr/.config/hypr/scripts/retirement-check` | Registry covering all 5 retired surfaces + wlogout + eww + RETIRE-01's own fixture | ✓ VERIFIED | `REGISTRY_RAW` (lines 88-94) lists exactly waybar/swaync/swayosd/wleave/ags/wlogout/eww, each tagged with its RETIRE-0N requirement |
| `theme-engine/.config/theme-engine/contract.json` | Post-migration size (~17 entries, RETIRE-08) | ✓ VERIFIED | `files` array has 17 entries (dev host, current HEAD) |
| `22-VERIFICATION-RECORD.md` | Both-tier INST-03 verdict, cited evidence | ✓ VERIFIED | Present, all 7 required sections, verbatim operator verdict, tree-identity proof by diffstat |
| `22-REVIEW.md` | Code review of the 9 new/modified gating files | ✓ VERIFIED, disposition `fixed` | 2 Critical + 5 Warning findings, all fixed and committed (`fix_commits` in frontmatter cross-checked against `git log` — all 6 commits present); 2 Info findings explicitly skipped with stated rationale |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `container-run.sh` step=theme-doctor | `theme-doctor-session-allowlist.txt` | byte-exact prefix match, `LC_ALL=C` | ✓ WIRED | Allowlist's 3 entries match the green run's actual 3 `[FAIL]` lines 1:1; fail-closed behavior on malformed/missing file documented and (per code review) tested |
| `container-run.sh` step=retirement-check / stow-link-check | `theme-doctor`'s folded checks (`:616-627` etc.) | `while read` over child-process stdout | ⚠️ pre-existing, not re-verified live | Code review's IN-01 (skipped, Info-level) notes this same "child exit code not checked" pattern exists in 3 other theme-doctor folds (motion-lint, colour-lint, hypr-equivalence-check) beyond the 2 fixed this phase (stow-link-check, theme-doctor's own top-level exit). Not a regression this phase introduced but a known, explicitly-deferred residual risk. |
| `retirement-check` | `contract.json` (Class: contract-json) | grep-based class scan | ✓ WIRED | `failed_classes=0` for `waybar/contract-json` through `eww/contract-json` in the green log |

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| RETIRE-09 | 22-01..09 (all 9 plans declare it) | Fresh-install container gate passes after every retirement has landed | ⚠️ Mechanically closed on a pre-fix run; VM tier independently corroborates; post-fix container confirmation pending (see truth #1) | `22-06-SUMMARY.md`, `22-VERIFICATION-RECORD.md`, `REQUIREMENTS.md` (ticked `[x]`, "CLOSED 2026-08-17") |

No orphaned requirements: `grep "Phase 22" REQUIREMENTS.md` maps only RETIRE-09 to this phase, and all 9 plans declare `requirements: [RETIRE-09]`.

### Anti-Patterns Found

None. Scanned the phase's primary changed artifacts (`verify/container-run.sh`, `hypr/.config/hypr/scripts/stow-link-check`, `theme-engine/.config/theme-engine/theme-doctor`, `install.sh`, `hypr/.config/hypr/scripts/retirement-check`, `verify/theme-doctor-session-allowlist.txt`) for `TBD`/`FIXME`/`XXX`/`TODO`/`HACK`/`PLACEHOLDER` — zero hits.

### Documentation Inconsistency (Info)

`22-09-SUMMARY.md` frontmatter declares `requirements-completed: [RETIRE-09]`, but every other pre-closure plan (22-01, 22-02, 22-03, 22-04, 22-05, 22-07, 22-08) explicitly states `requirements-completed: []` with a rationale that RETIRE-09 only closes end-to-end in plan 22-06. 22-09 completed 2026-08-16 (before 22-04/22-05/22-06 ran) and its own body text never claims to close the requirement — this reads as a copy/paste frontmatter slip, not an actual premature closure (REQUIREMENTS.md itself was only edited by 22-06's commit `9712afd`). Does not affect the phase's actual closure mechanics; flagged for hygiene only.

### Human Verification Required

### 1. Post-fix container re-run must reach `overall=PASS`

**Test:** Check `verify/logs/run-20260817T000253Z/summary.log` (or the next run) once the currently-executing `bash verify/container-run.sh` process (PID 349651 at verification time) finishes.
**Expected:** All nine `step=... status=ok` tokens plus `overall=PASS`, produced by the harness that now contains the CR-01/CR-02/WR-01..05 fixes.
**Why human:** A live podman container was mid-build (AUR packages) at verification time; its outcome cannot be known without waiting for it to finish. This is the concrete missing piece between "the fixed harness's logic was proven correct in isolated reproductions" (code review) and "the fixed harness was proven correct running its actual job end-to-end" (this open item).

### 2. SC-3's REPORT-domain scope caveat

**Test:** Decide whether the ~34 non-`.planning` waybar/swaync/etc. mentions in `docs/superpowers/*` and `.claude/CLAUDE.md` (all historical/past-tense, correctly framed) satisfy SC-3's "reports zero hits ... across the whole repo" wording, or whether they should be remediated too.
**Expected:** An explicit operator decision, since this is a scope question inherited from an earlier phase's (RETIRE-01/D-18-37) architectural choice to treat prose mentions as non-blocking `REPORT` output rather than `FAIL`.
**Why human:** Not resolvable by re-reading code — the retirement-check script is working exactly as designed; the question is whether that design fully satisfies this phase's own success-criterion wording.

### Gaps Summary

No FAILED truths, no MISSING/STUB artifacts, no NOT_WIRED key links, no debt markers. The phase's substantive engineering (container-run.sh's 9-step gate, the theme-doctor allowlist mechanism, stow-link-check's dangling-symlink sweep, the retirement-check registry, the install.sh package-scope split) is present, wired, and — for SC-2, SC-3, and RETIRE-09's own VM-tier pass condition — proven with real evidence gathered from inside the reproduced system.

The one open item is SC-1's timing: this phase's own code review (run and fixed within the same session as this verification) found and fixed two Critical false-PASS bugs in the exact gating steps SC-1 depends on, and the only completed "green" run predates those fixes. The evidence strongly suggests the fixes didn't change the actual verdict (the pre-fix run's raw logs are demonstrably substantive, not vacuous — real symlink counts, real theme-doctor pass/fail tallies matching the allowlist exactly), but that is an inference from log content, not a completed re-run of the current code. A container run built on the fixed harness was in progress and unfinished at verification time. This phase should not be treated as unconditionally closed until that run (or an equivalent one) completes and is checked.

---

## SC-1 closed — post-fix container re-run (appended 2026-08-17)

The verifier held SC-1 open because its evidence run (`run-20260816T230409Z`)
predated the seven commits fixing the two Critical false-PASS bugs. That
condition is now discharged.

**Post-fix run: `run-20260817T000253Z`, HEAD `e6baeb0`, warm cache — `overall=PASS`.**

```
pull ok · bootstrap ok · paru-cache-seed rc=0 · clone ok · install ok · stow ok
retirement-check ok · stow-link-check ok
theme-doctor ok allowed=3 blocking=0 · theme-parity ok
overall=PASS
```

Each gating step was confirmed to have genuinely executed rather than
vacuously reported success — the specific failure mode CR-01 and CR-02 made
possible:

- `stow-link-check` swept **136 real symlinks** (43 `.config` + 92
  `Pictures/Wallpapers` + 1 home root) with its fixture scope-skip printed —
  not the `0 passed, 0 failed` a silent python3 crash would have produced.
- `theme-doctor` emitted `Summary: 571 passed, 3 failed`, which is the
  affirmative marker CR-02's fix now *requires* before the allowlist verdict
  is trusted. Exactly 3 `[FAIL]` lines, all allowlisted, `blocking=0`.
- `retirement-check` reported `failed_classes=0`.
- No leaked containers.

Evidence copied to `postfix-evidence/` (`verify/logs/` is gitignored).

**Delta between that run and the shipped tree (`bab9bef`):** two commits —
removal of the orphaned, unregistered `matugen/.config/matugen/templates/eww-colors.scss`
and a correction to README's repo-tree diagram. Neither touches `install.sh`,
`stow.sh` or any gate script; the only functional change *removes* a file that
was never referenced. All four gates re-verified green on the clean shipped
tree: theme-doctor 580/0, theme-parity 1545/0, retirement-check
`failed_classes=0`, stow-link-check self-test 6/6. A further container run was
deliberately not taken — operator decision, recorded here rather than implied.

**SC-3 accepted** on operator judgment: the 87 surviving non-`.planning` hits
are 48 historical design docs, 12 instances of `retirement-check` naming its
own targets, 11 retirement-lineage comments in `windowrules.lua`/`autostart.lua`
(verified to be comments only — zero active config), plus `CLAUDE.md` and
`settings.local.json`. This is what RETIRE-01's REPORT-vs-blocking tier design
established.

**Verdict: 4/4. Phase 22 goal achieved.**
