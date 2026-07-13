---
phase: 07-super-key-menu
plan: 03
subsystem: infra
tags: [install.sh, pacman, multilib, aur, steam, ollama, container-gate, podman]

# Dependency graph
requires:
  - phase: 07-01
    provides: elephant menus provider wiring, walker -m exclusive-provider fix
  - phase: 07-02
    provides: D-03 kill-bind, Super+R fix, keybind-doctor regression gate
provides:
  - install.sh idempotent [multilib] enablement (new territory — zero prior pacman.conf handling)
  - install.sh PACMAN_PKGS gains steam/lutris/ollama/aichat/gamemode/mangohud/nwg-displays/blueman
  - install.sh AUR_PKGS gains heroic-games-launcher-bin/protonup-qt (D-33 human-verified)
  - ollama.service enabled non-fatally, no model pull, loopback-only bind
  - Documented blocker — container-gate execution (D-34) deferred pending push authorization
affects: [07-06-ai-dashboard-menu, 07-07-game-center-menu, phase-verification]

# Tech tracking
tech-stack:
  added: [steam, lutris, ollama, aichat, gamemode, mangohud, nwg-displays, blueman, heroic-games-launcher-bin, protonup-qt]
  patterns:
    - "Idempotent pacman.conf section enablement: active-check -> sed N-join uncomment (anchored to the two-line stanza, never a blanket #Include uncomment) -> append-if-absent fallback"
    - "Non-fatal systemd service enable (systemctl enable --now X || echo warning >&2) for services the --core-only container gate can't fully exercise (systemd not PID 1), copied from the existing swayosd precedent"

key-files:
  created: []
  modified:
    - install.sh

key-decisions:
  - "Multilib enablement lands in section_core_rice() before the PACMAN_PKGS pacman -Sy line, so the --core-only container gate exercises it (Pitfall 2's explicit mandate) — not section_hardware"
  - "Both AUR packages (heroic-games-launcher-bin, protonup-qt) approved at the D-33 human package-legitimacy checkpoint before this continuation began; user explicitly confirmed both are cleared, neither dropped"
  - "protonup-qt correction landed in the AUR_PKGS comment block: it is AUR-only, correcting CONTEXT.md D-25's assumption it was official-repo — a future reader must not 'fix' it back into PACMAN_PKGS"
  - "Task 3 (container-gate proof, D-34) DEFERRED — origin/main is 202 commits behind local HEAD (predates Phase 5 entirely). Running the gate now would clone stale code lacking this plan's changes and produce meaningless pass/fail evidence, not genuine D-34 proof. This exactly mirrors an established precedent in this repo (Phase 3's 03-04-SUMMARY.md, Phase 4's 04-VERIFICATION.md) — pushing to a public remote is a real external-state change requiring explicit user authorization, not performed autonomously"
  - "Multilib enable-path logic proven against three synthetic pacman.conf copies (fresh-commented, already-active, and absent-entirely) rather than the live /etc/pacman.conf, per explicit orchestrator instruction — the live file already has multilib enabled and would never exercise the uncomment/append branches"

patterns-established:
  - "Idempotent config-file section toggling in install.sh: grep-based active-check first, sed N-join for a commented two-line stanza (anchored to avoid blanket uncommenting sibling commented sections), tee -a append as the last-resort branch"

requirements-completed: [MENU-03, MENU-04]

coverage:
  - id: D1
    description: "Idempotent [multilib] enablement in install.sh, uncomments both the header and Include line together, never blanket-uncomments sibling commented repos, proven against synthetic pacman.conf fixtures (fresh-commented / already-active / absent) and not the live file"
    requirement: MENU-04
    verification:
      - kind: other
        ref: "bash -n install.sh && shellcheck -S error install.sh (both pass); synthetic-fixture test run this session (3 cases: fresh-commented -> 1 active [multilib], idempotent 2nd run -> still 1; already-active -> no-op both runs; absent -> appended, count 1); grep -c '^#\\[testing\\]' and '^#\\[multilib-testing\\]' remain commented after the uncomment"
        status: pass
    human_judgment: false
  - id: D2
    description: "All 10 packages land in the correct install.sh array (8 official-repo in PACMAN_PKGS, 2 AUR in AUR_PKGS), pavucontrol not duplicated, no ollama pull/run, no OLLAMA_HOST override, ollama.service enabled non-fatally"
    requirement: MENU-03
    verification:
      - kind: other
        ref: "bash -n install.sh && shellcheck -S error install.sh (both pass); per-package grep loop (all 10 present); pavucontrol count == 1; grep -c 'ollama (pull|run)' == 0; grep -c 'OLLAMA_HOST' == 0; systemctl enable --now ollama.service || echo fallback present; array-range check confirms each package's line number falls within its correct array's bounds"
        status: pass
    human_judgment: false
  - id: D3
    description: "Container gate (verify/container-run.sh) proves D-34: a fresh, unattended container install succeeds with multilib + all 10 new packages"
    requirement: MENU-04
    verification: []
    human_judgment: true
    rationale: "Deliberately NOT executed this session. origin/main (fae8e0f, 2026-07-11) is 202 commits behind local HEAD and predates Phase 5 entirely — verify/container-run.sh clones the real remote by design (D-56), so running it now would test stale code with none of this plan's changes, producing meaningless pass/fail evidence rather than genuine D-34 proof. Harness readiness is confirmed (podman 6.0.1 installed and working, bash -n + shellcheck -S error both pass on verify/container-run.sh, script is executable) — it is ready to run the moment origin/main reflects current work. A human must: (1) authorize `git push origin main`, (2) re-run `verify/container-run.sh` for real container-tier D-34 evidence."

# Metrics
duration: 11min
completed: 2026-07-13
status: complete
---

# Phase 07 Plan 03: Install.sh Package Reproducibility Summary

**Idempotent multilib enablement plus 10 new packages (8 official-repo, 2 AUR human-verified) wired into install.sh for Steam/Lutris/Heroic/ProtonUp-Qt and ollama/aichat, with the container-gate D-34 proof deferred pending a push authorization the executor is not permitted to grant itself**

## Performance

- **Duration:** 11 min (continuation from D-33 checkpoint approval at 19:30:33 to plan completion)
- **Started:** 2026-07-13T16:30:33Z (checkpoint approval)
- **Completed:** 2026-07-13T16:41:11Z
- **Tasks:** 2 of 3 executed (Task 3 deferred with documented blocker, not skipped silently)
- **Files modified:** 1 (install.sh)

## Accomplishments
- Idempotent `[multilib]` enablement added to `section_core_rice()`, ahead of `PACMAN_PKGS` install line — new territory, zero prior pacman.conf-editing code existed in this repo
- 8 official-repo packages added to `PACMAN_PKGS`: `steam`, `lutris`, `ollama`, `aichat`, `gamemode`, `mangohud`, `nwg-displays`, `blueman`
- 2 human-approved AUR packages added to `AUR_PKGS`: `heroic-games-launcher-bin`, `protonup-qt` (with a correction comment recording that `protonup-qt` is AUR-only, not official-repo as CONTEXT.md D-25 assumed)
- `ollama.service` enabled non-fatally (swayosd precedent shape); no model pull; `OLLAMA_HOST` never set (loopback-only bind, T-07-09)
- Container-gate (D-34) blocker documented rather than faked — origin/main is 202 commits stale

## Task Commits

Each executed task was committed atomically:

1. **Task 1: Enable multilib idempotently in section_core_rice** - `5840340` (feat)
2. **Task 2: Add the 10 packages to PACMAN_PKGS/AUR_PKGS and enable ollama** - `046e351` (feat)

**Task 3 (container-gate proof) was NOT executed** — see Deviations below. No commit for Task 3 since no code changed; the blocker itself is recorded here and in STATE.md.

## Files Created/Modified
- `install.sh` - Idempotent `[multilib]` enablement block (section_core_rice, before the PACMAN_PKGS install line); 8 new PACMAN_PKGS entries; 2 new AUR_PKGS entries; non-fatal `ollama.service` enable

## Decisions Made
- Multilib block placed immediately after the AUR-helper bootstrap, before `echo "Installing pacman packages..."` — satisfies the plan's ordering requirement (after mirror-sync, before the `PACMAN_PKGS` install line) while keeping the AUR-helper bootstrap (which needs only core/extra) unaffected by the new repo section
- Used a sed `N`-join anchored specifically to the two-line `#[multilib]` / `#Include = ...` stanza rather than a blanket `#Include` uncomment, so `[testing]`/`[multilib-testing]` sections stay commented — verified against a synthetic fixture containing both
- Removed the literal string `OLLAMA_HOST` from my own explanatory comment after noticing it would make the plan's own `grep -c 'OLLAMA_HOST' install.sh` acceptance check fail on a mention that was actually documenting the absence — reworded to convey the same intent without the literal token
- Did not push local `main` to `origin` to make Task 3's container-gate run meaningful — treated as requiring explicit user authorization, matching this repo's own established precedent (Phase 3's 03-04-SUMMARY.md, Phase 4's 04-VERIFICATION.md) for the exact same situation

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed a self-defeating literal "OLLAMA_HOST" from my own explanatory comment**
- **Found during:** Task 2, immediately after writing the ollama-enable comment block
- **Issue:** My own comment explaining "OLLAMA_HOST is deliberately left unset" contained the literal string the plan's acceptance criteria checks for absence of (`grep -c 'OLLAMA_HOST' install.sh` must return 0) — the comment would have made the automated check fail even though the underlying intent (never setting the var) was correctly honored
- **Fix:** Reworded the comment to describe the same constraint ("never overrides the daemon's listen-address env var... exposing it to 0.0.0.0 would open an unauthenticated inference API to the LAN") without using the literal token
- **Files modified:** install.sh
- **Verification:** `grep -c 'OLLAMA_HOST' install.sh` returns 0 after the fix
- **Committed in:** 046e351 (Task 2 commit)

---

**1 deferred item (not an auto-fix — a documented blocker, see below), 1 auto-fixed.**

**2. Container-gate execution (Task 3, D-34) deferred — origin/main predates this phase entirely**

- **Found during:** Task 3 (attempting to run the reproduction gate)
- **Issue:** `git log --oneline origin/main..HEAD | wc -l` shows **202 unpushed commits** on local `main` — not just this plan's Tasks 1-2, but the entirety of Phases 5 and 6 and the rest of Phase 7 to date. `origin/main` (`fae8e0f`, 2026-07-11) is a Phase-4-era commit. `verify/container-run.sh` is built exactly per spec — it clones the real remote (D-56), which is the correct design — but running it right now would clone that stale state: no multilib handling, none of the 10 new packages, none of the theme-engine work from Phases 5/6. `steam`, `ollama`, etc. simply would not be present in the cloned `install.sh` at all, so the run could not possibly exercise anything this plan built.
- **Why this isn't a Rule 1-3 auto-fix:** Pushing to a public GitHub remote is a real external-state change, not a reversible local edit — it is explicitly outside the deviation-rule auto-fix scope (Rules 1-3 are for code-level fixes within the working tree). This repo has an exact documented precedent for this same situation: Phase 3's `03-04-SUMMARY.md` deferred its own container-gate Task 3 for the identical reason ("origin/main is dozens of commits behind local HEAD... running now would clone a pre-theme-engine repo state and produce meaningless pass/fail evidence") and explicitly declined to push autonomously ("treated as requiring explicit user authorization per execution safety guidance"). Phase 4's `04-VERIFICATION.md` independently re-hit and re-documented the same blocker one phase later. Deferring here, rather than either (a) running a meaningless test and reporting a false D-34 pass, or (b) pushing 202 commits without being asked, is the established and correct pattern for this project.
- **What was verified instead:** Confirmed the harness's own prerequisites are fully ready: `podman 6.0.1` installed and working (`podman --version` succeeds), `bash -n verify/container-run.sh` and `shellcheck -S error verify/container-run.sh` both pass, `verify/container-run.sh` is executable. The harness is genuinely ready to run and prove D-34 the moment `origin/main` reflects current work — nothing about the gate itself needed fixing or weakening.
- **Resolution path (not performed autonomously):** A human must (1) authorize `git push origin main` (or review/rebase first, at their discretion), then (2) re-run `verify/container-run.sh` from the repo root for genuine container-tier D-34 evidence covering multilib + all 10 new packages.
- **Files modified:** none (no code change — this is a recorded blocker, not a fix)
- **Verification:** `git log --oneline origin/main..HEAD | wc -l` confirms the 202-commit gap; `test -x verify/container-run.sh`, `bash -n`, and `shellcheck -S error` all confirm the gate itself is ready-to-run
- **Committed in:** N/A (no commit — documented here and to be recorded via `state add-blocker`)

---

**Total deviations:** 1 auto-fixed (Rule 1 bug in my own comment text), 1 deferred blocker (documented, not auto-fixed, matches established project precedent).
**Impact on plan:** The install.sh code changes (Tasks 1-2) are complete, verified, and committed. D-34's live-container proof is the one piece of evidence this session could not honestly produce — deferring it (rather than faking a pass against stale code) is the correct call per this repo's own prior handling of the identical situation.

## Issues Encountered
None beyond the two items already covered in Deviations above.

## User Setup Required

None - no external service configuration required. However, **D-34's container-gate proof remains open** pending a manual step:
1. Review and authorize `git push origin main` (202 commits, spanning Phases 5-7 to date)
2. Run `verify/container-run.sh` from the repo root and confirm `overall=PASS` in the resulting `verify/logs/run-<timestamp>/summary.log`, with `steam` and all 9 other new packages showing `[OK]` in `03-install.log`'s `verify_packages()` table

## Next Phase Readiness
- `install.sh` is ready for plans 07-06 (AI dashboard menu) and 07-07 (Game center menu), which invoke `steam`, `lutris`, `heroic`, `protonup-qt`, `ollama`, `aichat`, `blueman`, `nwg-displays` by name — those binaries will exist on any future fresh install
- D-34's container-tier proof is the one open item; it does not block 07-04 through 07-08 from proceeding, since none of those plans depend on the packages actually being installed on THIS dev machine (they only depend on the menu wiring being correct) — but it should be closed before the phase itself is marked complete
- No blocking regressions introduced: Tasks 1-2's `bash -n` / `shellcheck -S error` checks both pass cleanly

---

## Self-Check: PASSED

- FOUND: install.sh
- FOUND: .planning/phases/07-super-key-menu/07-03-SUMMARY.md
- FOUND: commit 5840340 (Task 1)
- FOUND: commit 046e351 (Task 2)
- FOUND: commit bcc6a95 (SUMMARY)

---
*Phase: 07-super-key-menu*
*Completed: 2026-07-13*
