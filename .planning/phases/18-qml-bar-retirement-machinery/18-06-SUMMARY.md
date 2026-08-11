---
phase: 18-qml-bar-retirement-machinery
plan: 06
subsystem: infra
tags: [retirement-check, theme-doctor, bash, python, deny-by-default, self-test, waybar]

requires:
  - phase: 18-qml-bar-retirement-machinery (plan 03)
    provides: colour-lint's fold shape and EXEMPTIONS/--self-test/--no-pending precedent, mirrored here
provides:
  - "hypr/.config/hypr/scripts/retirement-check — generic, sixteen-class retirement checklist (RETIRE-01), argv-validated before any path/pattern construction, registry-driven tier dispatch (pending -> [REPORT], retired -> [PASS]/[FAIL]), --all/--list/--self-test/--root"
  - "Five committed self-test fixture trees proving the blocking tier can fail (three poisoned-stray-* fixtures) and proving the .planning/-only reference stays in the report tier (poisoned-planning-only)"
  - "retirement-check fold in theme-doctor (D-18-35) — tally unchanged while every real surface is pending, blocking tier continuously exercised via the retirement-fixture registry row"
  - "18-RETIREMENT-BASELINE-waybar.md — the committed pre-deletion waybar baseline, byte-identical to a fresh run, that 18-20 diffs against post-deletion"
affects: [18-20, 19, 20, 21]

actuals:
  tokens: 26584
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Two-guard argv validation (syntactic regex, then registry-membership allowlist) before ANY path or grep pattern is constructed from user input — waybar-visibility.sh's T-08-05 reject-before-use discipline applied to a sixteen-class scanner"
    - "Status-driven tier dispatch: one shared emitter maps (blocking|report domain) x (pending|retired status) x (hit count) to [PASS]/[FAIL]/[REPORT]/[SKIP], called identically by all sixteen classes"
    - "Deny-by-default cross-package-refs: enumerate top-level stow package dirs at runtime, subtract own-tree + already-attributed files, so a package added later is covered with zero registry edits (motion-lint's D-23 discipline applied to packages)"
    - "Fixed-point baseline capture: a report-domain count that includes the baseline document's own committed footprint (e.g. planning-archive) is captured by iterating run -> embed -> re-run -> confirm unchanged, not a pre-commit snapshot that goes stale the instant it's committed"

key-files:
  created:
    - hypr/.config/hypr/scripts/retirement-check
    - hypr/.config/hypr/scripts/tests/retirement-fixtures/compliant-clean-surface/ (10 files)
    - hypr/.config/hypr/scripts/tests/retirement-fixtures/poisoned-stray-layer-rule/ (10 files)
    - hypr/.config/hypr/scripts/tests/retirement-fixtures/poisoned-stray-contract-entry/ (10 files)
    - hypr/.config/hypr/scripts/tests/retirement-fixtures/poisoned-stray-cross-script-ref/ (10 files)
    - hypr/.config/hypr/scripts/tests/retirement-fixtures/poisoned-planning-only/ (11 files)
    - .planning/phases/18-qml-bar-retirement-machinery/18-RETIREMENT-BASELINE-waybar.md
  modified:
    - theme-engine/.config/theme-engine/theme-doctor

key-decisions:
  - "layer-window-rules/autostart classes filter to the actual hl.layer_rule/hl.window_rule/hl.exec_cmd dispatcher lines, not any line mentioning the surface name — a whole-line grep over-counts by 2x (comment/prose lines like '-- Layer rules (walker, waybar, swaync, wleave)' also contain the token), and the plan's own measured ground truth (2 layer rules, 2 autostart hits) only holds under dispatcher-line filtering"
  - "The committed self-test fixture trees live inside the real hypr config tree that own-tree/test-fixtures/cross-package-refs recurse through, and the poisoned fixtures deliberately carry their test surface's literal token text — excluded from every normal-root scan (motion-lint/colour-lint's exclude-own-fixtures-unless-pointed-at precedent), otherwise a real-repo run permanently arms retirement-fixture's blocking tier red against its own test fixtures"
  - "RETIREMENT_CHECK honours an env override in the theme-doctor fold (unlike the three hardcoded-path sibling folds) — required because the plan's own acceptance criteria assert the guarded-skip degradation path via RETIREMENT_CHECK=/nonexistent, which is unprovable against a hardcoded path"
  - "theme-doctor's own fold comment cannot spell out the literal self-test surface token in prose — theme-doctor is itself a checker-internals scan target, so doing so is a guaranteed self-inflicted [FAIL] on first run"

patterns-established:
  - "Fixed-point document capture for any future report-domain baseline artifact that lives under .planning/ and quotes its own scanned paths — same convergence technique applies wherever a captured count would otherwise include the capturing document's own future footprint"

requirements-completed: [RETIRE-01]

coverage:
  - id: D1
    description: "retirement-check validates <surface-name> via a syntactic regex guard then a registry-membership allowlist BEFORE constructing any path or grep pattern; rejected input exits 2 (distinct from a dirty-surface 1) and constructs no path"
    requirement: "RETIRE-01"
    verification:
      - kind: other
        ref: "retirement-check notarealsurface / '../../etc' / 'way.ar' / (no arg) all exit 2 with usage/allowed-surfaces to stderr — run live during execution"
        status: pass
    human_judgment: false
  - id: D2
    description: "All sixteen reference classes (14 blocking + 2 report) implemented per the Reference Class Registry; waybar reports the measured ground truth exactly (2 layer rules, 2 autostart, 9 contract entries, 4554 planning-archive after fixed-point convergence); swaync's systemd-units names the real in-repo override.conf drop-in, proving genericity"
    requirement: "RETIRE-01"
    verification:
      - kind: other
        ref: "retirement-check waybar / swaync / swayosd / wleave / ags / wlogout / eww all exit 0 with a full 16-class report — run live during execution"
        status: pass
    human_judgment: false
  - id: D3
    description: "--self-test passes five committed fixtures — three drive the blocking tier to a genuine [FAIL] (stray layer rule, stray contract.json entry, stray cross-script reference), poisoned-planning-only proves a .planning/-only reference stays in the report tier with zero [FAIL] lines and exit 0"
    requirement: "RETIRE-01"
    verification:
      - kind: other
        ref: "retirement-check --self-test — 5 passed, 0 failed, exit 0 — run live during execution"
        status: pass
    human_judgment: false
  - id: D4
    description: "theme-doctor folds retirement-check --all: zero [FAIL] retirement-check lines while every real surface stays pending, [PASS] lines for retirement-fixture prove the blocking tier is armed and green (not dormant), tally (failed count) unchanged between a normal run and RETIREMENT_CHECK=/nonexistent"
    requirement: "RETIRE-01"
    verification:
      - kind: other
        ref: "bash theme-engine/.config/theme-engine/theme-doctor — 0 [FAIL] retirement-check lines, 14 [PASS] retirement-fixture lines, failed=2 (pre-existing, unrelated) in both normal and guarded-skip runs — run live during execution"
        status: pass
    human_judgment: false
  - id: D5
    description: "18-RETIREMENT-BASELINE-waybar.md committed, byte-identical to a fresh retirement-check waybar run, ready for 18-20's post-deletion diff"
    requirement: "RETIRE-01"
    verification:
      - kind: other
        ref: "diff <(retirement-check waybar) <(sed -n baseline fenced block) — exit 0 — run live during execution"
        status: pass
    human_judgment: false

duration: ~50min
completed: 2026-08-11
status: complete
---

# Phase 18 Plan 06: RETIRE-01 Retirement Checklist Machinery Summary

**Built `retirement-check` — a generic, sixteen-reference-class retirement checklist scanning window/layer rules, autostart, keybinds, contract.json, matugen templates, doctor internals/fixtures, cross-package refs, install/stow lists, systemd units (live + in-repo), D-Bus activation, XDG autostart and host packages — argv-validated before any path is built, proven against waybar AND swaync (genericity), folded into theme-doctor with the tally unchanged, and used to capture the committed pre-deletion waybar baseline 18-20 will diff against.**

## Performance

- **Duration:** ~50 min
- **Completed:** 2026-08-11
- **Tasks:** 3
- **Files modified:** 54 (52 created, 2 modified)

## Accomplishments

- `retirement-check` built end-to-end: two-stage argv guard (syntactic regex, then registry-membership allowlist) rejects malicious/invalid input with exit 2 before any filesystem path or grep pattern is ever constructed from it (T-18-06-01/02/03 all mitigated); an eight-row registry (waybar/swaync/swayosd/wleave/ags/wlogout/eww/retirement-fixture) drives status-based tier dispatch through one shared emitter.
- All sixteen reference classes implemented exactly per the plan's Reference Class Registry: fourteen blocking-domain classes (own-tree, layer-window-rules, autostart, keybinds, contract-json, matugen-templates, checker-internals, test-fixtures, cross-package-refs [deny-by-default, D-18-36], install-stow-lists, systemd-units [live + in-repo halves], dbus-activation, xdg-autostart, host-package) plus two report-domain count-only classes (planning-archive, repo-prose) that never influence the exit code (D-18-37).
- `--self-test` passes five committed fixture trees under `tests/retirement-fixtures/`: `compliant-clean-surface` (all-PASS), three poisoned-stray-* fixtures each driving exactly one blocking class to a real `[FAIL]`, and `poisoned-planning-only` — the load-bearing fixture proving a `.planning/`-only reference stays a `[REPORT]` line with zero `[FAIL]`s, mechanically enforcing the tier split rather than merely documenting it.
- Genericity proven live, not just against waybar: `swaync`'s `systemd-units` class correctly names the real in-repo `swaync/.config/systemd/user/swaync.service.d/override.conf` drop-in — a file class waybar has no instance of — and all seven real registry surfaces produce complete 16-class reports.
- Folded into `theme-doctor` (D-18-35): `[PASS]`/`[FAIL]` lines fold into the pass/fail tally, `[REPORT]`/`[SKIP]` pass through unfolded (matching motion-lint's fold shape), and the tally is provably unchanged (`failed=2`, both pre-existing and unrelated to this plan) between a normal run and `RETIREMENT_CHECK=/nonexistent`.
- Waybar's pre-deletion baseline (`18-RETIREMENT-BASELINE-waybar.md`) captured via a converged fixed-point run and committed, proven byte-identical to a fresh `retirement-check waybar` invocation — the exact property 18-20's post-deletion diff depends on.

## Task Commits

1. **Task 1: End-to-end tracer — argv validation, registry, contract-json class, tier dispatch** — `3284248` (feat)
2. **Task 2: Expand to sixteen classes, --all, --self-test with five fixtures** — `77393f8` (test)
3. **Task 3: Fold into theme-doctor, capture waybar baseline** — `5234e70` (feat)

**Plan metadata:** committed as part of this session's final metadata commit (see below).

## Files Created/Modified

- `hypr/.config/hypr/scripts/retirement-check` — the RETIRE-01 deliverable: bash argv/registry/dispatch wrapper around a single embedded python scan pass (motion-lint/colour-lint's "one process, comment-free regex logic defined once" idiom)
- `hypr/.config/hypr/scripts/tests/retirement-fixtures/{compliant-clean-surface,poisoned-stray-layer-rule,poisoned-stray-contract-entry,poisoned-stray-cross-script-ref,poisoned-planning-only}/` — five miniature repo roots, 51 files total, backing `--self-test`
- `theme-engine/.config/theme-engine/theme-doctor` — new fold block (`# ── retirement-check fold (18-06, RETIRE-01/D-18-35) ───`, guard `RETIREMENT_CHECK`) inserted after the colour-lint fold, before the CLEAN-02 git-clean check
- `.planning/phases/18-qml-bar-retirement-machinery/18-RETIREMENT-BASELINE-waybar.md` — committed pre-deletion baseline: front matter (capture date, commit SHA, exact command), a per-class summary table, and the verbatim `retirement-check waybar` output, byte-identical to a fresh run

## For 18-20's benefit

- **Waybar's registry row as shipped:** `waybar|pending|waybar/:hypr/.config/hypr/scripts/waybar-*|RETIRE-02`. 18-20 flips `pending` -> `retired` in the same commit as the deletion — that single-field edit is what arms the blocking tier.
- **The exact command 18-20 must re-run:** `retirement-check waybar` (no `--root`) from the repo root, after `RETIREMENT_CHECK`'s target resolves to the post-deletion tree.
- **Blocking-domain class totals that must all reach zero post-deletion** (from the committed baseline, captured at commit `77393f8`... see the baseline document's own front matter for the exact captured SHA — commit `5234e70`, one commit after the fold, since the baseline's fixed-point capture ran after both the script and the fold existed): own-tree 204, layer-window-rules 2, autostart 2, keybinds 2, contract-json 9, matugen-templates 5, checker-internals 59, test-fixtures 18, cross-package-refs 217, install-stow-lists 22, systemd-units 5, dbus-activation 0, xdg-autostart 0, host-package 1. (planning-archive 4554 and repo-prose 46 are report-domain and never gate 18-20's pass/fail verdict.)

## Decisions Made

- **Dispatcher-line filtering for layer-window-rules/autostart, not whole-line grep:** measuring the real repo showed a plain word-boundary grep over `windowrules.lua`/`autostart.lua` returns 4/6 hits respectively (comment/prose lines like `-- Layer rules (walker, waybar, swaync, wleave)` also contain the token) against the plan's measured ground truth of exactly 2/2. Both classes now require the line to ALSO match `hl\.(layer_rule|window_rule)\(` or `hl\.exec_cmd\(` respectively before counting it — the registry table's own "Catches `hl.layer_rule`/`hl.window_rule` rows" / "Catches `hl.exec_cmd` launch lines" phrasing, taken literally rather than as a loose description. Verified against the measured ground truth table before committing.
- **Exclude the fixtures directory from every non-self-test scan (found live, fixed before Task 2's commit):** the committed fixture trees live inside `hypr/.config/hypr/scripts/tests/retirement-fixtures/`, which sits directly inside three of `retirement-fixture`'s own scan targets (own-tree, test-fixtures, and — via cross-package-refs's deny-by-default walk — the hypr package generally). The poisoned fixtures deliberately carry the literal token they test, so a normal (non-`--root`) run against the real repo was finding its own poisoned fixtures as if they were surviving stray references, permanently failing `retirement-fixture`'s blocking tier and breaking the phase's own "continuously green" requirement. Fixed with the exact motion-lint/colour-lint precedent: exclude the fixtures directory from every scan UNLESS `--root` itself points at (or inside) it — same code path, context-aware exclusion.
- **`RETIREMENT_CHECK` honours an env override, unlike its three sibling folds:** `WAYBAR_DESIGN_LINT`/`MOTION_LINT`/`COLOUR_LINT` are all hardcoded paths in their theme-doctor folds. This plan's own Task 3 acceptance criteria require proving the guarded-skip degradation path via `RETIREMENT_CHECK=/nonexistent bash theme-doctor`, which is impossible against a hardcoded path — so this one fold deliberately deviates from the sibling pattern with `RETIREMENT_CHECK="${RETIREMENT_CHECK:-$HOME/.config/hypr/scripts/retirement-check}"`.
- **Fixed-point baseline capture:** `18-RETIREMENT-BASELINE-waybar.md`'s own committed content (hundreds of quoted `waybar`-containing file paths) inflates `planning-archive`'s own count the instant it's committed under `.planning/`. A naive pre-commit capture would go stale on first re-run. Resolved by iterating "run, embed, re-run, compare" until the embedded count matches a fresh run exactly (converged after two iterations, 4195 → 4553 → 4554 → stable) — proven via the committed `diff` command exiting 0.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] layer-window-rules/autostart whole-line grep over-counted against measured ground truth**
- **Found during:** Task 1, verifying against the plan's Measured ground truth table before committing
- **Issue:** A plain word-boundary grep for the surface token across `windowrules.lua`/`autostart.lua` matches comment/prose lines mentioning the surface alongside dispatcher lines, producing 4/6 hits where the plan's measured ground truth requires exactly 2/2.
- **Fix:** Added `DISPATCH_LAYER_RE`/`DISPATCH_EXEC_RE` line pre-filters (`hl\.(layer_rule|window_rule)\(`, `hl\.exec_cmd\(`) so only actual dispatcher-call lines are counted, matching the registry table's own class description.
- **Files modified:** `hypr/.config/hypr/scripts/retirement-check`
- **Verification:** `retirement-check waybar` reports exactly 2/2/9 for layer-window-rules/autostart/contract-json, matching the plan's table.
- **Committed in:** `3284248` (Task 1 commit)

**2. [Rule 1 - Bug] Fixtures directory self-contamination against the real repo**
- **Found during:** Task 2, running `--all` against the real repo after fixtures existed
- **Issue:** The committed `retirement-fixtures/` tree sits inside three of `retirement-fixture`'s own scan targets; poisoned fixtures deliberately contain the literal test token, so a normal real-repo run found its own fixtures as stray references, permanently red.
- **Fix:** Added a fixtures-directory exclusion to the shared `iter_files()` choke point, active unless `--root` points at/inside the fixtures directory — the motion-lint/colour-lint precedent.
- **Files modified:** `hypr/.config/hypr/scripts/retirement-check`
- **Verification:** `retirement-check --all` exits 0 with `[PASS]` lines for `retirement-fixture`; `--self-test` still passes 5/5.
- **Committed in:** `77393f8` (Task 2 commit)

**3. [Rule 1 - Bug] theme-doctor fold's own prose self-poisoned checker-internals**
- **Found during:** Task 3, first run of the theme-doctor fold after adding it
- **Issue:** theme-doctor is itself a `checker-internals` scan target; the fold's own explanatory comment spelled out the literal self-test surface token, so `checker-internals` found the fold describing itself and failed.
- **Fix:** Rewrote the fold comment to describe the mechanism without the literal token, and added a standing note for future editors.
- **Files modified:** `theme-engine/.config/theme-engine/theme-doctor`
- **Verification:** `bash theme-engine/.config/theme-engine/theme-doctor` shows zero `[FAIL] retirement-check` lines.
- **Committed in:** `5234e70` (Task 3 commit)

---

**Total deviations:** 3 auto-fixed (all Rule 1 — bugs found and fixed before their task's commit, none out of scope)
**Impact on plan:** All three are correctness fixes directly required by this plan's own acceptance criteria (exact measured counts, a continuously-green blocking tier, a clean fold). No scope creep — no file outside this plan's declared `files_modified` was touched.

## Issues Encountered

None beyond the three self-inflicted bugs documented above as deviations — all found and fixed via each task's own `<verify>`/acceptance criteria before committing, per `superpowers:verification-before-completion`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `retirement-check` is live and generic (`~/.config/hypr/scripts` is a symlink into this repo, so no re-stow was needed) and ready for RETIRE-03..06 to consume unmodified in Phases 19-21.
- The waybar pre-deletion baseline is committed and byte-identical to a fresh run — 18-20 can diff its post-deletion run against it directly.
- No blockers for the rest of wave 2 or downstream phases. `theme-doctor`'s two remaining `[FAIL]` lines (`hypr-equivalence-check`'s missing 13.1 baseline directory, and the mid-execution dirty-tree CLEAN-02 check) are both pre-existing and unrelated to this plan — the plan's own acceptance criteria explicitly instruct not to gate on theme-doctor's overall exit code for this reason.

## Self-Check: PASSED

All 54 claimed files found on disk (retirement-check, 51 fixture files, the baseline doc, theme-doctor); all 3 task commit hashes (`3284248`, `77393f8`, `5234e70`) found in git log.

---
*Phase: 18-qml-bar-retirement-machinery*
*Completed: 2026-08-11*
