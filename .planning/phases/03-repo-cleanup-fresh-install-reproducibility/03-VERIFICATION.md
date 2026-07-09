---
phase: 03-repo-cleanup-fresh-install-reproducibility
verified: 2026-07-09T09:40:00Z
status: passed
score: 5/5 roadmap success criteria verified; 5/5 requirements satisfied
behavior_unverified: 0
overrides_applied: 0
human_signoff: approved (VM tier, recorded 2026-07-09 in REQUIREMENTS.md INST-03 entry and STATE.md — user confirmed fully themed desktop, no issues)
gate: container-tier PASS, verify/logs/run-20260709T060703Z/summary.log (overall=PASS)
---

# Phase 3: Repo Cleanup & Fresh-Install Reproducibility — Verification Report

**Phase Goal:** The repo is clean of dead configs and generated artifacts, and the entire themed desktop reproduces unattended on a genuinely fresh Arch system via install.sh + stow.
**Verified:** 2026-07-09T09:40:00Z
**Status:** passed
**Re-verification:** No — this is the initial phase-level goal-backward verification (no prior 03-VERIFICATION.md existed).

## Goal Achievement

### Observable Truths (Roadmap Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Dead configs are gone — the wofi package, debug.txt, and stray screenshots no longer exist in the repo, and stow applies cleanly with no conflicts. | ✓ VERIFIED | Direct filesystem check this session: `test -e wofi` and `test -e debug.txt` both absent. `git ls-files \| grep -i screenshot` returns only `hypr/.config/hypr/scripts/screenshot.sh` (the capture script itself, not any tracked PNG) — the 22 previously-tracked screenshots are gone from git. `.stow-local-ignore` contains `^Pictures/Screenshots$` and `.gitignore` contains `wallpapers/Pictures/Screenshots/` (both confirmed present by direct read). The container gate's `04-stow.log` shows all 17 packages stowing with zero conflict/error output, and `theme-doctor`'s `stow -n theme-engine reports no conflicts` check PASSed in the same run. |
| 2 | After any theme switch, `git status` stays clean — no generated color files tracked in the repo. | ✓ VERIFIED | `theme-doctor` (theme-engine/.config/theme-engine/theme-doctor:157-166) contains a permanent "CLEAN-02 permanent invariant (D-50)" block asserting `git status --porcelain` is empty, guard-skipped only when git/.git is absent. This check ran and PASSed inside the container gate (`05-theme-doctor.log:25`: `[PASS] git status --porcelain is empty (/home/builder/dotfiles stays clean)`) — evidence from inside a container that had just run `install.sh --core-only`, `stow.sh` (which seeds a first-boot theme via `theme-apply catppuccin`), confirming a real theme-generation cycle happened and left the tree clean. Dev-machine `git status --porcelain` is also empty (0 lines) at verification time. |
| 3 | On a genuinely fresh Arch VM/container, `install.sh` installs all theming-critical packages (adw-gtk-theme, not the nonexistent adw-gtk3) and reports post-install verification of critical packages. | ✓ VERIFIED | `install.sh:132` lists `adw-gtk-theme` in `PACMAN_PKGS`; `grep -n "adw-gtk3\b" install.sh` finds no package-list reference to the nonexistent name (only an explanatory comment at line 356 about the historical bug). `install.sh:352-402` defines `verify_packages()` — a hard-fail post-install table, called once at the end of `main` against a combined `PACMAN_PKGS`+`AUR_PKGS` array. The container gate's `03-install.log` ends with `[OK] adw-gtk-theme` among 89 `[OK]` lines and the closing line `All 89 packages verified installed.` — this is the live output of `verify_packages()` actually running and passing in a fresh container, not a static read. |
| 4 | On that same fresh system, `stow.sh` completes without aborting — no unguarded operations that assume pre-existing state. | ✓ VERIFIED | `stow.sh:48-51` guards the `hyprland.conf` mv with `[[ -e "$HYPR_CONF" && ! -L "$HYPR_CONF" ]]` (existence+non-symlink check, so a fresh system with no pre-existing config doesn't abort). `stow.sh:79` uses `sudo chsh` (non-interactive, no PAM password prompt) rather than a bare `chsh`. The `PACKAGES` array (17 entries) contains neither the phantom `scripts` entry nor the retired `wofi` entry (directly enumerated this session). The container gate's `04-stow.log` shows a full, uninterrupted run through all 17 packages, `chsh` succeeding ("Shell changed."), and the first-boot theme seed degrading harmlessly with a headless-guard message (`theme_engine_reload: no graphical session detected — skipping reload fan-out`) rather than hanging or aborting — `summary.log` records `step=stow status=ok`. |
| 5 | A full `install.sh` + `stow.sh` run in a disposable VM/container produces the fully themed desktop unattended — a real reproduction, not a re-stow on the dev machine. | ✓ VERIFIED | Container tier: `verify/logs/run-20260709T060703Z/summary.log` read directly this session — `step=pull status=ok`, `step=bootstrap status=ok`, `step=clone status=ok` (real `git clone` of the pushed remote, confirmed `git log --oneline origin/main..HEAD` is now 0 — origin is current), `step=install status=ok`, `step=stow status=ok`, `step=theme-doctor status=informational rc=1` (expected/non-gating in a headless container — see Anti-Patterns note below), `step=theme-parity status=ok`, `overall=PASS`. `06-theme-parity.log` confirms `Summary: 287 passed, 0 failed` — an actual render-and-check pass inside the fresh container, not carried over from the dev machine. VM tier: human visual sign-off recorded 2026-07-09 in `.planning/REQUIREMENTS.md` (INST-03 entry: "VM tier: human visual sign-off recorded 2026-07-09 — desktop themes correctly on first login, no issues") and `.planning/STATE.md` (blockers section: "graphical VM tier human visual sign-off recorded per VERIFICATION.md — user confirmed the fully themed desktop works with no issues"). Per the task brief, this recorded human evidence is treated as valid — it is not something a verifier can or should reproduce. |

**Score:** 5/5 roadmap truths verified (0 present-but-behavior-unverified).

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `install.sh` | `adw-gtk-theme` (not `adw-gtk3`), `verify_packages()` hard-fail table, flagged sections, hardware guards | ✓ VERIFIED | Confirmed via direct read: line 132 (`adw-gtk-theme`), lines 352-402 (`verify_packages`), `--noconfirm` on every mutating pacman/paru call (12 occurrences checked), no debt markers. |
| `stow.sh` | Guarded hyprland.conf mv, non-interactive chsh, clean PACKAGES array, first-boot theme seed | ✓ VERIFIED | Confirmed via direct read: guard at line 50, `sudo chsh` at line 79, 17-entry PACKAGES array with no `scripts`/`wofi`. |
| `theme-engine/.config/theme-engine/theme-doctor` | Permanent git-clean invariant (CLEAN-02/D-50), no accepted-gap carve-out | ✓ VERIFIED | Lines 157-166 contain the invariant; container gate log shows it PASSing. |
| `verify/container-run.sh` | Rerunnable container harness, hard-gates on theme-parity, false-pass-immune | ✓ VERIFIED | Executable present; `exec </dev/null` (line 112) and the `overall=` verdict cross-check (lines 261-278) confirmed present, closing the documented stdin-eating false-pass hole from the first genuine run. |
| `VERIFICATION.md` (repo root) | Documented graphical VM reproduction procedure with D-53 pass condition | ✓ VERIFIED | 249 lines, contains explicit "Pass condition (unambiguous, D-53)" section (lines 22-28) and a "Human visual confirmation" section (line 209). |
| `wofi/`, `debug.txt`, tracked screenshot PNGs | Absent from repo | ✓ VERIFIED | All three confirmed absent by direct filesystem/git check. |
| `.planning/REQUIREMENTS.md`, `.planning/STATE.md` | CLEAN-01/CLEAN-02/INST-01/INST-02/INST-03 marked Complete with evidence | ✓ VERIFIED | All 5 requirement rows read directly, marked `[x]` Complete with concrete evidence references. |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| `install.sh` main body | `verify_packages()` | `VERIFY_PKGS=("${PACMAN_PKGS[@]}" "${AUR_PKGS[@]}")` then call at line 402 | ✓ WIRED | Confirmed by direct read and by live container-gate output (89/89 `[OK]`). |
| `stow.sh` | `theme-apply catppuccin` | Post-stow-loop seed call, guarded for missing entrypoint/no-session | ✓ WIRED | Confirmed in `04-stow.log`: seed step ran and degraded harmlessly under the headless guard rather than hanging (this is the fix from Quick Task 260709-buf, confirmed live in the most recent gate run). |
| `verify/container-run.sh` | `install.sh --core-only` + `stow.sh` + `theme-parity` (hard gate) | `container-script.sh` executed via bind-mounted file, not stdin | ✓ WIRED | `container-script.sh` present in the run's log dir as a preserved artifact; `summary.log`'s `overall=` line is cross-checked against container exit code per the harness's own verdict logic (lines 268-278 of `verify/container-run.sh`). |
| `theme-doctor` | git-clean invariant | `git status --porcelain` check with guarded skip | ✓ WIRED | Live-executed and PASSed inside the container in the same run that also ran `install.sh`+`stow.sh`, proving the check exercises a real post-install/post-stow tree, not a mocked one. |

### Behavioral Spot-Checks / Probe Execution

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| Container-tier reproduction gate (the phase's actual acceptance probe) | `verify/container-run.sh` (already executed; log inspected, not re-run to avoid a ~15-25 min podman rebuild cycle and re-pulling the base image) | `verify/logs/run-20260709T060703Z/summary.log`: all steps `status=ok` except theme-doctor `status=informational rc=1`; `overall=PASS` | ✓ PASS |
| theme-parity inside the fresh container | grep `Summary:` in `06-theme-parity.log` | `Summary: 287 passed, 0 failed` | ✓ PASS |
| install.sh package verification inside the fresh container | tail of `03-install.log` | `All 89 packages verified installed.` including `[OK] adw-gtk-theme` | ✓ PASS |
| No debt markers in phase-modified files | `grep -n -E "TBD|FIXME|XXX|TODO|HACK|PLACEHOLDER"` across install.sh, stow.sh, theme-doctor, theme-stress-test, verify/container-run.sh, VERIFICATION.md | No matches in any file | ✓ PASS |
| git tree clean on dev machine at verification time | `git status --porcelain` | 0 lines | ✓ PASS |
| origin/main is current (container gate clones real, up-to-date state) | `git log --oneline origin/main..HEAD \| wc -l` | `0` | ✓ PASS |

Note: `verify/container-run.sh` was not re-executed live in this verification pass — its most recent recorded run (`run-20260709T060703Z`, ~3.5 hours before this verification) is the fourth iteration after three prior runs caught and fixed real bugs (D-59 zero-prompt violation, a stdin-eating false-pass in the harness itself, a headless reload hang, and a host-absolute wallpaper symlink — all confirmed fixed by commits present in `git log`). Re-running was judged unnecessary: the log evidence is fresh (same session), machine-readable, and the fix commits it depends on are all present in the current `HEAD`. This mirrors the precedent set by 02-VERIFICATION.md declining to re-run `theme-stress-test` live for the same reasoning (mutates state / long-running, recent clean log already exists).

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| CLEAN-01 | 03-01-PLAN.md, 03-02-PLAN.md | Dead configs removed — wofi package, debug.txt, stray screenshots, other unused files | ✓ SATISFIED | wofi/, debug.txt confirmed absent; stow.sh PACKAGES array has no wofi/scripts entries; install.sh PACMAN_PKGS has no wofi entry. |
| CLEAN-02 | 03-01-PLAN.md, 03-03-PLAN.md | `git status` stays clean after a theme switch | ✓ SATISFIED | theme-doctor's permanent git-clean invariant (D-50) live-PASSed in the container gate after a real stow+seed cycle. |
| INST-01 | 03-02-PLAN.md, 03-03-PLAN.md | install.sh installs correct theming-critical packages and verifies post-install | ✓ SATISFIED | adw-gtk-theme present, adw-gtk3 absent, verify_packages() live-confirmed 89/89 OK in container gate. |
| INST-02 | 03-02-PLAN.md | stow.sh completes on a genuinely fresh system, no unguarded state-assuming operations | ✓ SATISFIED | Guarded hyprland.conf mv, non-interactive chsh, live-confirmed clean completion in container gate (`step=stow status=ok`). |
| INST-03 | 03-04-PLAN.md | Full install.sh + stow.sh verified in a disposable VM/container, producing the fully themed desktop | ✓ SATISFIED | Container tier: `overall=PASS`, theme-parity 287/0. VM tier: human visual sign-off recorded 2026-07-09 (REQUIREMENTS.md, STATE.md). |

No orphaned requirements: REQUIREMENTS.md's "Phase 3" rows are exactly {CLEAN-01, CLEAN-02, INST-01, INST-02, INST-03}, matching the union of all four plans' `requirements:` frontmatter (03-01: CLEAN-01/CLEAN-02; 03-02: INST-01/INST-02/CLEAN-01; 03-03: INST-01/CLEAN-02; 03-04: INST-03).

### Anti-Patterns Found

No debt markers (`TBD`/`FIXME`/`XXX`/`TODO`/`HACK`/`PLACEHOLDER`) found in any file modified by this phase (`install.sh`, `stow.sh`, `theme-engine/.config/theme-engine/theme-doctor`, `theme-engine/.config/theme-engine/theme-stress-test`, `verify/container-run.sh`, `VERIFICATION.md`) — confirmed by direct grep this session.

One item worth flagging as a disclosed, non-blocking observation rather than a gap:

| File | Finding | Severity | Impact on this verification |
|------|---------|----------|------------------------------|
| `verify/logs/run-20260709T060703Z/05-theme-doctor.log` | Inside the headless container, `theme-doctor` reports 3 `[FAIL]` lines: `gsettings gtk-theme = adw-gtk3-dark (got: Adwaita)`, `walker process running`, `elephant process running`. | ℹ️ Info (expected, not a defect) | These three checks are session-dependent (gsettings/D-Bus, live process presence) and cannot legitimately pass in a headless, no-session container — this was an explicit, documented design decision in 03-04-PLAN.md and 03-04-SUMMARY.md ("theme-doctor is invoked informationally inside the container... because its session-dependent checks cannot legitimately pass in a headless container"). `container-run.sh`'s exit code is gated on `theme-parity` alone, never on `theme-doctor` — confirmed structurally (summary.log shows `step=theme-doctor status=informational rc=1` as a distinct, non-fatal status value, and `overall=PASS` despite it). The git-clean invariant (the one theme-doctor check load-bearing for CLEAN-02) DID pass in this same run. Not a gap. |

### Human Verification Required

None. All 5 roadmap success criteria have direct codebase/log evidence. The one item requiring human judgment (VM-tier graphical visual confirmation, D-53) was already performed and recorded by the user on 2026-07-09, per the task brief's instruction to treat this as valid recorded evidence rather than something for this verifier to reproduce.

## Gaps Summary

No gaps found. All 5 roadmap success criteria are backed by concrete, freshly-inspected evidence: direct filesystem/git checks for dead-file removal (SC1), a live-executed permanent invariant check inside a genuinely fresh container for the git-clean guarantee (SC2), a live 89/89 package-verification table from the same container run (SC3), a live uninterrupted stow completion in that run (SC4), and the container gate's `overall=PASS` + `theme-parity 287/0` combined with the recorded human VM sign-off (SC5). All 5 phase requirements (CLEAN-01, CLEAN-02, INST-01, INST-02, INST-03) are satisfied with matching evidence, and REQUIREMENTS.md's traceability table has no orphaned Phase-3 rows. The five post-phase hardening commits referenced in the task brief (606b417, 0ffa5d9, 1e747eb, 50ad696, 49536d5) are all present in `git log` and their fixes are directly visible in the current file contents (wlogout in AUR_PKGS not PACMAN_PKGS; alpm_octopi_utils absent; headless reload guard present; container-run timeout present; container gate summary.log itself is downstream proof all of these landed correctly, since the gate could not have reached `overall=PASS` without them).

The one ambiguous-file batch left open from 03-01 (`powermenu.sh`, `.vscode/settings.json`, 4 fastfetch art files) is an explicitly deferred, non-blocking human-confirmation item per D-47 — it does not map to any of the 5 roadmap success criteria or 5 phase requirements, so it does not affect this phase's pass/fail determination.

---

_Verified: 2026-07-09T09:40:00Z_
_Verifier: Claude (gsd-verifier)_
