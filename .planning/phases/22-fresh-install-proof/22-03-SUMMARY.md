---
phase: 22-fresh-install-proof
plan: 03
subsystem: docs
tags: [verification, retirement-check, hypr-equivalence-check, install-sh]

# Dependency graph
requires:
  - phase: 22-fresh-install-proof
    plan: 02
    provides: "stow-link-check and its theme-doctor fold, live on origin/main, so this plan's VERIFICATION.md prose about the container/VM checks lands on a repo state where the mechanisms it describes actually exist"
provides:
  - "README.md's feature table and repo-tree diagram no longer claim SwayNC/swaync as the notification surface — both name Quickshell, the actual RETIRE-03 replacement"
  - "env.lua's native-Wayland-client cursor-theming comment rewritten (not scrubbed) to name the clients that currently exist"
  - "VERIFICATION.md's VM tier runs install.sh unflagged instead of --core-only, closing the system/ tree's never-installed gap, with the D-61 reversal recorded in prose"
  - "VERIFICATION.md §6/§8 rewritten to the current QBAR/QNOTIF/QOSD/QPOWER/QMEDIA surface inventory, named by requirement ID"
  - "VERIFICATION.md §7's pass bar amended plus a pre-authored, sourced exemption list (D-22-02) covering hypr-equivalence-check's options.jsonl Hyprland-version-drift gap"
affects: [22-05-fresh-install-proof, 22-06-fresh-install-proof]

actuals:
  tokens: 3187
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Pre-authored, sourced exemption table (check | reason | source | permanent-or-provisional) — same shape as retirement-check's registry, motion-lint's exemption list, and hypr-equivalence-check's own ACCEPTED_ADDITIONS table, extended here to a documentation-level VM pass bar"

key-files:
  created: []
  modified:
    - README.md
    - hypr/.config/hypr/config/env.lua
    - VERIFICATION.md

key-decisions:
  - "README.md's Notifications row and env.lua's client enumeration are the two must_haves.truths items; the plan's must_haves.truths bullet naming these was satisfied verbatim — 'Quickshell' for both the Status Bar and Notifications rows, since one process genuinely now delivers both."
  - "The §7 exemption list ships with exactly one row (hypr-equivalence-check: options.jsonl), verified concretely rather than assumed: this dev host runs Hyprland 0.56.2 against a baseline captured at 0.56.1, and options.jsonl's comparator (_compare_options_normalized, hypr-equivalence-check:347-351) has no ACCEPTED_ADDITIONS-style absorption mechanism the way binds.json does — a genuine gap, not an invented one. binds.json and animations.json were checked and found NOT to need a row (binds.json already self-absorbs via its own table; animations.json's leaf/curve comparator showed no equivalent drift class)."

patterns-established: []

requirements-completed: []  # RETIRE-09 intentionally NOT marked complete here — this plan builds prose/pass-bar prerequisites the VM run still needs; RETIRE-09 only closes when the actual container+VM proof passes end-to-end (matches 22-01/22-02's same non-completion).

coverage:
  - id: D1
    description: "README.md's feature table (Notifications row) and repo-tree diagram (swaync/ block) no longer name a retired package as the current desktop's notification surface"
    requirement: "RETIRE-09"
    verification:
      - kind: manual_procedural
        ref: "grep -in 'swaync|SwayNC' README.md -> only the unrelated matugen/templates/swaync-colors.css line remains (explicitly out of this task's declared scope); grep -in waybar README.md -> 0 hits"
        status: pass
    human_judgment: false
  - id: D2
    description: "env.lua's native-Wayland-client cursor-theming comment rewritten (not scrubbed) to name kitty, walker, the Quickshell shell process, and Thunar-under-Wayland instead of waybar/swaync"
    requirement: "RETIRE-09"
    verification:
      - kind: manual_procedural
        ref: "grep -n 'waybar|swaync' env.lua -> 0 hits; hyprctl reload && hyprctl configerrors -> ok, empty (config still parses clean on this live session)"
        status: pass
    human_judgment: false
  - id: D3
    description: "VERIFICATION.md §5's VM tier runs install.sh unflagged (was --core-only), with the system/-tree gap and the D-61 personal-section reversal both named in prose; container tier's own --core-only invocation is explicitly left alone"
    requirement: "RETIRE-09"
    verification:
      - kind: manual_procedural
        ref: "grep -n core-only VERIFICATION.md -> all 3 remaining hits are inside the container-tier justification paragraph, none in the VM's own install.sh invocation line; grep -c 'D-61\\|D-22-11' VERIFICATION.md -> >=1"
        status: pass
    human_judgment: false
  - id: D4
    description: "VERIFICATION.md §6/§8 rewritten from a package-name list (naming swaync, retired Phase 19) to the current QBAR/QNOTIF/QOSD/QPOWER/QMEDIA inventory, with no instruction to enable a Quickshell systemd unit"
    requirement: "RETIRE-09"
    verification:
      - kind: manual_procedural
        ref: "for id in QBAR QNOTIF QOSD QPOWER QMEDIA; do grep -c \"$id\" VERIFICATION.md; done -> 2 each (>=1 required); grep -in swaync VERIFICATION.md -> 0 hits"
        status: pass
    human_judgment: false
  - id: D5
    description: "VERIFICATION.md §7's pass bar amended (theme-doctor 0 failures minus exemption list, AND theme-parity 0 unqualified, AND human visual confirmation) and mirrored in the top-of-file D-53 blockquote; a fully-populated, sourced pre-authored exemption list (D-22-02) added"
    requirement: "RETIRE-09"
    verification:
      - kind: manual_procedural
        ref: "grep -n 'Summary: N passed' VERIFICATION.md -> 0 hits (old literal sentence gone); awk over the exemption section -> 3 table lines (header+separator+1 data row); every cell populated with a concrete file:line/tool-behaviour source"
        status: pass
    human_judgment: false
  - id: D6
    description: "retirement-check --all stays green (0 [FAIL] lines, failed_classes=0 across all 8 surfaces) after every edit in this plan, and the three named retirement-lineage comments (autostart.lua:186, windowrules.lua, quickshell-doctor:723) are byte-unchanged"
    requirement: "RETIRE-09"
    verification:
      - kind: manual_procedural
        ref: "hypr-scripts/retirement-check --all (run after each task's edits) -> rc=0, 0 [FAIL] lines, 8x failed_classes=0; git diff --quiet -- autostart.lua windowrules.lua quickshell-doctor -> exits 0"
        status: pass
    human_judgment: false
  - id: D7
    description: "RETIRE-02 (waybar) and RETIRE-03 (swaync) repo-prose report counts move in the correct direction after this plan's edits"
    verification: []
    human_judgment: true
    rationale: "swaync's repo-prose count did strictly decrease (13 -> 9, verified via retirement-check --all) as this plan's file edits removed every swaync mention from README.md and VERIFICATION.md. waybar's repo-prose count did NOT decrease (37 -> 37): retirement-check's repo-prose class only scans .md files (README.md, VERIFICATION.md, docs/, .claude/CLAUDE.md) plus non-.planning *.md files repo-wide — env.lua is a .lua file and was never in that scan set, and the pre-existing README.md/VERIFICATION.md text contained zero 'waybar' references before this plan touched them (confirmed by git show HEAD~3:README.md and a repo grep). All 37 waybar/repo-prose hits live in docs/superpowers/specs and docs/superpowers/plans/ — historical design documents outside this plan's declared file scope (README.md, env.lua, VERIFICATION.md) and outside D-22-07's named target list. This is a plan-authoring assumption (that editing env.lua would move the waybar repo-prose count) that did not hold against the actual scanner; recorded here rather than silently claimed as satisfied. Requires an operator/planner read to confirm this is an acceptable scope gap rather than a missed edit."

duration: ~35min
completed: 2026-08-16
status: complete
---

# Phase 22 Plan 03: VERIFICATION.md and Repo-Prose Corrections Summary

**Corrected README.md's and env.lua's stale swaync/waybar prose, reversed VERIFICATION.md's VM install scope to unflagged `install.sh` (closing the never-installed `system/` tree gap), rewrote its surface checklists to the current QBAR/QNOTIF/QOSD/QPOWER/QMEDIA inventory, and authored §7's pre-run exemption list for Hyprland version drift — before any VM exists to run against it.**

## Performance

- **Duration:** ~35 min
- **Tasks:** 3 (README.md + env.lua corrections; VERIFICATION.md §5/§6/§8 rewrite; VERIFICATION.md §7 pass bar + exemption list)
- **Files modified:** 3

## Accomplishments

- **README.md**: the feature table's Notifications row now names Quickshell (not the deleted SwayNC package); the repo-tree diagram's `swaync/.config/swaync/` block (a directory that no longer exists) is removed entirely, not merely renamed — verified the fenced block's tree-drawing characters still line up after the removal.
- **env.lua**: the cursor-theming comment's native-Wayland-client enumeration is rewritten (per D-21-19 — rewritten, never scrubbed) from `kitty, walker, quickshell, waybar, swaync, Thunar-under-Wayland` to name the clients that currently exist: kitty, walker, the Quickshell shell process (explicitly noted as now carrying the bar, notifications, OSD, power menu and dashboard in one process), and Thunar-under-Wayland. The comment's "why" clause survives intact. Confirmed live via `hyprctl reload` + `hyprctl configerrors` on this host's running session (both clean).
- **VERIFICATION.md §5**: the VM tier now runs `install.sh` unflagged instead of `--core-only`, closing the one gap D-22-11 identified — the tracked `system/` tree (`kernel-module-verify` + its pacman hook) has never been installed by either proof tier. The container tier's own `--core-only` invocation is explicitly and separately justified as staying unchanged. The reversal of D-61 (running `section_personal` on the VM, previously skipped everywhere) is named in prose, not silently introduced.
- **VERIFICATION.md §6/§8**: both surface checklists rewritten from a package-name list (that still named `swaync`, retired in Phase 19) to the current inventory — bar (QBAR), notification popups/centre (QNOTIF), dashboard drawer, OSD indicators (QOSD), power menu (QPOWER), workspace overview, Media tab with cava ring (QMEDIA), plus walker/elephant/Thunar by their own names. Added the one-process note (bar/notifications/OSD/power-menu/dashboard/overview are all one Quickshell process) and confirmed no instruction anywhere tells the reader to `systemctl enable` a Quickshell unit.
- **VERIFICATION.md §7**: the literal "`Summary: N passed, 0 failed`" pass-bar sentence is replaced with "zero failures except for entries on the pre-authored exemption list," mirrored in the top-of-file D-53 blockquote so the two statements of the bar cannot drift apart. A new "Pre-authored exemption list (D-22-02)" subsection ships with one sourced, verified row: `hypr-equivalence-check: options.jsonl` may legitimately differ on a fresh machine because its comparator has no `ACCEPTED_ADDITIONS`-style absorption for Hyprland version drift (unlike `binds.json`), concretely verified against this host's live version (0.56.2) vs. the baseline's captured version (0.56.1, `MANIFEST.md:3`). `theme-parity`'s half of the bar stays unqualified.
- `retirement-check --all` stayed green (`rc=0`, 0 `[FAIL]` lines, `failed_classes=0` across all 8 surfaces) after every edit; the three named retirement-lineage comments (`autostart.lua:186`, `windowrules.lua`, `quickshell-doctor:723`) are confirmed byte-unchanged throughout.

## Task Commits

Each task was committed atomically:

1. **Task 1: Correct README.md and env.lua** - `10a774f` (docs)
2. **Task 2: Rewrite VERIFICATION.md §5/§6/§8** - `d180e89` (docs)
3. **Task 3: Amend VERIFICATION.md §7 and author the exemption list** - `17669f0` (docs)

**Plan metadata:** *(pending — this SUMMARY + STATE.md + ROADMAP.md commit, made immediately after this document)*

## Files Created/Modified

- `README.md` - Notifications feature-table row corrected; stale `swaync/` repo-tree block removed
- `hypr/.config/hypr/config/env.lua` - native-Wayland-client cursor comment rewritten to current surfaces
- `VERIFICATION.md` - §5 install scope reversed to unflagged (D-22-11); §6/§8 surface inventories rewritten by requirement ID; §7 pass bar amended and a pre-authored exemption list (D-22-02) added; top-of-file D-53 blockquote synchronized

## Decisions Made

- **"Quickshell" used for both the Status Bar and Notifications rows in README.md's stack table.** The plan required the same short-product-name register the neighbouring rows use (not a requirement ID) — since one Quickshell process genuinely delivers both surfaces today, the identical value in both rows is accurate, not a copy-paste artifact.
- **The §7 exemption list ships with exactly one row.** Verified concretely per the plan's instruction rather than assumed: checked which baseline directory resolves (the archived `13.1-hyprland-lua-config-migration/.hypr-baseline`, since the live path doesn't exist), what it captured (Hyprland 0.56.1, 2026-07-28, per its own `MANIFEST.md`), what this host runs now (0.56.2, via `hyprctl version`), and what the comparator does when it sees a key the baseline lacks (`hypr-equivalence-check:347-351` — an unconditional FAIL, no absorption). Checked `binds.json`'s `ACCEPTED_ADDITIONS` table (exists, already absorbs new binds — no row needed) and `animations.json`'s leaf/curve comparator (no equivalent drift class found) before concluding a one-row list is the honest answer, not an under-researched one.

## Deviations from Plan

### Auto-fixed Issues

None — no bugs or blocking issues encountered; all three tasks executed the prose edits exactly as the plan specified.

### Discrepancy Found (not a defect — reported, not silently absorbed)

**1. The plan's task-1 and plan-level acceptance criteria required the RETIRE-02 (waybar) `repo-prose` report count to strictly decrease alongside RETIRE-03 (swaync)'s — it did not, and could not, within this task's declared file scope.**
- **Found during:** Task 1's verification step, comparing the before/after `retirement-check --all` measurements.
- **What was measured:** `retirement-check`'s `repo-prose` scan class (class 16) only reads `.md` files — `README.md`, `VERIFICATION.md`, `docs/**/*.md`, `.claude/CLAUDE.md`, and any other `*.md` outside `.planning/` (`retirement-check:540-569`). `env.lua` is a `.lua` file and was never in that scan set, so rewriting its `waybar`/`swaync` enumeration cannot move the `repo-prose` count for either surface. Separately, `README.md` and `VERIFICATION.md` contained **zero** `waybar` references before this plan touched them (confirmed via `git show HEAD~3:README.md` and a repo grep) — so there was nothing in either in-scope `.md` file to remove for RETIRE-02 in the first place. All 37 `waybar/repo-prose` hits live entirely in `docs/superpowers/specs/*.md` and `docs/superpowers/plans/*.md`, historical design documents from when waybar was actually in use, outside this plan's `<files>` scope (`README.md`, `env.lua`, `VERIFICATION.md`) and outside D-22-07's named target list.
- **Why not fixed:** Editing `docs/superpowers/specs/2026-07-28-hyprland-lua-config-migration-design.md` and the AGS-applet design docs to scrub their historical `waybar` references would be exactly the kind of "promote a report-tier stale-prose hit" scope creep D-22-07 explicitly rejects for this phase, and those documents are correctly describing the repo's *past* state (when waybar genuinely existed) — not a current factual error the way `README.md`'s notification claim was.
- **What did move:** RETIRE-03 (swaync)'s `repo-prose` count strictly decreased across this plan's edits: 13 (before Task 1) → 11 (after Task 1's README.md edits) → 9 (after Task 2/3's VERIFICATION.md edits) — fully satisfying that half of the plan-level verification requirement.
- **Recorded in:** `coverage: D7` above (`human_judgment: true`), flagged for operator/planner awareness rather than silently marked satisfied.

---

**Total deviations:** 0 auto-fixed; 1 discrepancy reported (a plan acceptance-criterion assumption that did not hold against `retirement-check`'s actual scan scope, not a defect in the edited files).
**Impact on plan:** All must_haves.truths items (the load-bearing requirements) are fully satisfied — README.md and env.lua correctly describe the current desktop, VERIFICATION.md's three prose changes (D-22-11 reversal, D-22-03 surface inventory, D-22-02 exemption list) are all in place, and `retirement-check --all` stayed green throughout. The one unsatisfied sub-criterion (RETIRE-02's repo-prose count) reflects a plan-authoring assumption about scanner scope, not a gap in the actual repo prose this plan was scoped to fix.

## Issues Encountered

None blocking. The repo-prose scope mismatch above was discovered, measured precisely, and reported rather than worked around by touching out-of-scope historical docs.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `README.md`, `env.lua` and `VERIFICATION.md` are all pushed-ready (committed; pending the push step every wave requires) for the plans that run the actual container/VM proof (22-04 onward) — VERIFICATION.md's install scope, surface checklist and pass bar now describe the repo state those runs will actually encounter.
- `VERIFICATION.md §7`'s exemption list is authored and committed *before* any VM run exists — satisfying D-22-02's ordering requirement for whichever plan runs the VM tier.
- The RETIRE-02 repo-prose discrepancy (coverage `D7`) is flagged for the phase-close reviewer/planner: confirm whether the docs/superpowers historical `waybar` mentions are intentionally out of SC-3's scope (this executor's reading, consistent with D-22-07's "do not promote report-tier hits" instruction) or whether a future plan should address them.

---
*Phase: 22-fresh-install-proof*
*Completed: 2026-08-16*

## Self-Check: PASSED

All 4 claimed files verified present on disk; all 3 claimed commits verified present in `git log --oneline --all`.
