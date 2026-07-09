# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v1.0 — Theme Pipeline Repair

**Shipped:** 2026-07-09
**Phases:** 3 | **Plans:** 9 | **Tasks:** 25

### What Was Built
- Consolidated `theme-engine` stow package: one `theme-apply` entrypoint rendering static presets and matugen Material You through the same templates into `~/.local/state/theme/`, with a single reload owner fanning out to all ten desktop surfaces live (no relogin).
- The stuck-white root cause fixed: `adw-gtk-theme` installed and the nonexistent `adw-gtk3` install.sh entry replaced, backed by a 23-finding full-repo AUDIT.md.
- Proof tooling as rerunnable regression gates: `contract.json` + `theme-parity` (structural/name-set/semantic parity across all 7 render targets), `theme-stress-test` (10-switch static↔dynamic gate), `theme-doctor` (strict, zero carve-outs).
- Fresh-install reproducibility: hardened `install.sh`/`stow.sh` plus a podman container gate (`verify/container-run.sh`) and a documented graphical-VM procedure — both tiers passed with human sign-off.
- Repo cleanup: wofi tree, debug.txt, retired scripts, orphaned templates gone; screenshots un-folded from stow; git stays clean after every switch.

### What Worked
- **Root-cause-first sequencing.** The full-repo audit in Phase 1 found the missing-package root cause immediately and broke a loop of 8+ prior failed spot-fixes.
- **The acceptance gate earned its keep.** Seven container-gate runs peeled off six real fresh-install defects (stdin-eating heredoc, missing --noconfirm, wlogout repo mismatch, dead AUR entry, headless swaync hang, host-absolute symlink) before the first genuine PASS — none would have surfaced on the dev machine.
- **Single-source-of-truth manifests.** `contract.json` consumed by both checkers eliminated checker/renderer drift; parity passed 217/0 with zero fixes needed, proving the Phase 1 consolidation was already correct.
- **Human sign-off checkpoints at phase ends** caught what automation can't (visual correctness on real desktop and in the VM).

### What Was Inefficient
- INST-03 gate execution stalled on an unpushed origin (~80 commits behind) — the harness clones from the remote, so the gate was blocked until the user authorized a push. Sequencing the push authorization earlier would have saved a deferral cycle.
- The elephant provider gap was misdiagnosed in planning as "packages never installed"; the real cause was a Go plugin/host build-invocation mismatch requiring a human-run `paru --rebuild`. Cost a 55min+ continuation plan.
- Two `set -e` shell footguns (`(( counter++ ))` at zero; rsync `--delete` wiping its own logs) each cost a debugging round — both were self-inflicted by the new tooling, caught by the gates.

### Patterns Established
- All theme output renders to `~/.local/state/theme/` — the repo holds templates, never generated artifacts; a git-clean invariant enforces it.
- Reload strategy per app class: signal-based where supported (waybar SIGUSR2, swaync-client -rs), hardened restart with health gates where not (Walker + elephant, Thunar daemon watcher).
- Every reliability claim gets a rerunnable harness (`theme-parity`, `theme-stress-test`, `container-run.sh`) rather than one-off manual verification.
- Headless guard convention: session-dependent code early-returns when WAYLAND_DISPLAY/DBUS_SESSION_BUS_ADDRESS are absent, keeping unattended installs alive.

### Key Lessons
1. When repeated fixes fail, audit before patching — the v1.0 root cause was a package name that never existed, invisible to symptom-level fixes.
2. A reproduction gate must run from the same path a real fresh install takes (real remote clone, unattended, timeout-bounded) — every one of the six gate defects was invisible to dev-machine re-stows.
3. Verify assumed APIs empirically before planning around them: walker's `hotreload_theme` did not exist, GTK3 has no live CSS reload — plans built on those would have failed.
4. Tracked symlinks must be relative; host-absolute paths are silent fresh-install breakers.

### Cost Observations
- Model mix: adaptive profile (not instrumented per-model this milestone)
- Timeline: 3 days, 98 commits
- Notable: 9 plans averaged ~25 min each; the two longest overruns were both misdiagnosis-driven (elephant rebuild, container gate debugging), not scope-driven.

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Phases | Plans | Key Change |
|-----------|--------|-------|------------|
| v1.0 | 3 | 9 | Established root-cause-first auditing and rerunnable verification gates (parity/stress/container) |

### Top Lessons (Verified Across Milestones)

1. Audit before patching when fixes loop (v1.0 — single data point, watch in v2).
2. Acceptance gates must reproduce the real environment, not approximate it (v1.0).
