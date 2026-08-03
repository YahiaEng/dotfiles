---
phase: 16-workspace-overview
plan: 04
subsystem: infra
tags: [hyprland, quickshell, screencopy-permissions, gate, bash, self-test]

# Dependency graph
requires:
  - phase: 16-workspace-overview
    provides: "16-02's overview IPC status verb (toggle/status) exact output shape (`active=.. tiles=.. windows=.. withContent=..`), reused verbatim by check 6's parser rather than re-derived; 16-02's own verification-methodology lesson (model-level counts do not prove pixels are painted) that this plan was asked to close and, per the honest finding below, only partially closes"
  - phase: 11-quickshell-viability-gate
    provides: "permissions.lua's mechanism-verified, deliberately-inert screencopy allow list (four consumer grants, T-11-20 exact-path discipline) and the explicit deferral of live-enforcement proof to this phase"
provides:
  - "Seven new quickshell-doctor checks (D-16-23), each proven able to FAIL via a committed poisoned fixture replayed by --self-test before being trusted to pass — doctor check count rises 15 -> 22"
  - "enforce_permissions = true committed in permissions.lua, with the recovery procedure written into the file's own header, but functional live enforcement is NOT proven end-to-end — see the prominent deferral below"
  - "The authoritative, run-cold-weeks-later procedure for closing D-16-09's live-enforcement proof, recorded in deferred-items.md item 0"
  - "An honest, explicit statement of what check 6 (overview-content-check) can and cannot catch, for 16-05/16-08 to read before leaning on it"
affects: [16-05-window-click-parity, 16-06-drag-and-drop, 16-07-click-and-keyboard, 16-08-perf-measurement]

actuals:
  tokens: 17500
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "quickshell-doctor check functions take an explicit expected-state parameter (shell_pids, etc.) rather than deriving live state internally, so --self-test's replay never depends on which process happens to be running when the fixture was authored vs. replayed — fixed a pre-existing bug in the D-15-25 panel-namespace-conformance self-test using this same pattern"
    - "hypr-equivalence-check baseline amendments for legitimate, intentional config changes are surgical single-record edits (14-10's precedent, reused here for ecosystem:enforce_permissions), never a wholesale re-snapshot"
    - "deferred-items.md item 0 is the authoritative, context-free record for a deferred checkpoint:human-action task — written so a future session (or future person) can execute it cold without having read this plan's own conversation"

key-files:
  created:
    - hypr/.config/hypr/scripts/tests/quickshell-fixtures/compliant-overview-layers.json
    - hypr/.config/hypr/scripts/tests/quickshell-fixtures/poisoned-offlevel-overview-layers.json
    - hypr/.config/hypr/scripts/tests/quickshell-fixtures/poisoned-two-claimant-overview-layers.json
    - hypr/.config/hypr/scripts/tests/quickshell-fixtures/poisoned-wrongpid-overview-layers.json
    - hypr/.config/hypr/scripts/tests/quickshell-fixtures/compliant-overview-shortcuts.json
    - hypr/.config/hypr/scripts/tests/quickshell-fixtures/poisoned-duplicate-overview-shortcuts.json
    - hypr/.config/hypr/scripts/tests/quickshell-fixtures/compliant-overview-keybinds.lua
    - hypr/.config/hypr/scripts/tests/quickshell-fixtures/poisoned-collision-overview-keybinds.lua
    - hypr/.config/hypr/scripts/tests/quickshell-fixtures/poisoned-invalid-token-shortcuts.json
    - hypr/.config/hypr/scripts/tests/quickshell-fixtures/compliant-hyprctl-getoption-enforce.txt
    - hypr/.config/hypr/scripts/tests/quickshell-fixtures/poisoned-hyprctl-getoption-enforce.txt
    - hypr/.config/hypr/scripts/tests/quickshell-fixtures/compliant-permissions.lua
    - hypr/.config/hypr/scripts/tests/quickshell-fixtures/poisoned-missing-binary-permissions.lua
    - hypr/.config/hypr/scripts/tests/quickshell-fixtures/poisoned-pattern-binary-permissions.lua
    - hypr/.config/hypr/scripts/tests/quickshell-fixtures/compliant-overview-status.txt
    - hypr/.config/hypr/scripts/tests/quickshell-fixtures/poisoned-blank-tiles-overview-status.txt
    - hypr/.config/hypr/scripts/tests/quickshell-fixtures/compliant-window-thumbnail.qml
    - hypr/.config/hypr/scripts/tests/quickshell-fixtures/poisoned-second-screencopyview.qml
    - .planning/phases/16-workspace-overview/deferred-items.md
  modified:
    - hypr/.config/hypr/scripts/quickshell-doctor
    - hypr/.config/hypr/config/permissions.lua
    - .planning/phases/13.1-hyprland-lua-config-migration/.hypr-baseline/options.jsonl

key-decisions:
  - "Task 3 (the real session logout/login and five-consumer proof) is DEFERRED by explicit operator decision (2026-08-03), not completed and not skipped. Reason: screen-capture permission grants are read once at Hyprland compositor startup; this executor's own terminal runs as a child process of the compositor, so performing the restart would kill the executing session mid-plan — exactly the risk Phase 11 originally declined. Operator instruction: 'Defer the logout/verification to the end of the phase; keep building. Leave enforce_permissions = true.'"
  - "enforce_permissions = true ships committed regardless of the deferral (operator's explicit choice) — the config edit, recovery procedure, and gate infrastructure are all real and correct; only the functional live-restart proof is outstanding."
  - "Honest finding on check 6 (overview-content-check), stated plainly per the operator's request: it achieves D-16-10's whole-grid permission-denial catch (aggregate withContent > 0 whenever windows > 0, parsed from the overview IPC status verb) but does NOT perform per-delegate geometry cross-checking against `hyprctl clients -j`. It would catch a genuinely blank/denied capture (every delegate's hasContent false) but would NOT independently catch the exact defect class 16-02 actually hit twice — delegates rendering at collapsed/overlapping/wrong positions while hasContent stays true for all of them (capture succeeds, geometry is wrong). This is a faithful implementation of D-16-23's own literal check-6 text (reuse the existing IPC verb, assert withContent > 0 whenever windows > 0) and of this plan's Task 1 action text verbatim — but it is a narrower instrument than the inherited 16-02/16-03 finding asked for (per-delegate geometry + hasContent cross-checked against hyprctl clients -j). Extending the IPC surface to expose per-delegate geometry aggregates without leaking window titles/addresses (a real constraint — 16-02's own diagnostic verb was removed specifically because it leaked titles, conflicting with T-16-06) is a genuine design question this plan did not attempt to resolve. 16-05/16-08, which lean on this check, should treat it as covering the blank-tile/permission-denial failure mode only, and continue to rely on the human render gate for the geometry-collapse failure mode until/unless a future plan closes this gap."
  - "Rule 3 fix, found while proving this plan's own --self-test acceptance criterion: a pre-existing bug in the D-15-25 panel-namespace-conformance self-test (compliant-panel-layers.json spuriously failed because its baked-in pid never matches whatever quickshell process happens to be running). Fixed by threading an explicit shell-pid override through _qsd_assert_panel_layers, used only by --self-test's own replay; live behaviour unchanged."
  - "Rule 1 fix: this plan's own enforce_permissions flip diverged hypr-equivalence-check's options.jsonl comparison from the 13.1 pre-migration baseline. Surgically amended the one affected baseline record (14-10's established precedent for legitimate config changes), proven via git diff to be a single-line change."

requirements-completed: []

coverage:
  - id: D1
    description: "quickshell-doctor gains seven new checks (overview-namespace-conformance, overview-shortcut-single-registration, reserved-array-manifest-coverage, permissions-enforce-readback, permissions-allowlist-paths-resolve, overview-content-check, single-capture-path), each with a committed poisoned fixture proven to FAIL and a clean counterpart proven to PASS via --self-test"
    verification:
      - kind: automated_ui
        ref: "hypr/.config/hypr/scripts/quickshell-doctor --self-test (36 passed, 0 failed after this plan's own fixes; 17 of those entries are this plan's new checks); live run --no-headless-output shows check count risen 15 -> 22 (21 passed, 1 failed — the runtime-enforcement check itself, observed FAILING before Task 2's edit, exactly the required live proof-of-fallibility)"
        status: pass
    human_judgment: false
  - id: D2
    description: "permissions.lua ships with enforce_permissions = true, no grant added or removed, no grant broadened to a pattern, recovery procedure written into the file's own header, hyprctl configerrors clean, and the observed (non-)effect of hyprctl reload on the runtime readback recorded honestly"
    verification:
      - kind: other
        ref: "Task 2's own <verify> block, re-run clean after the header edit: enforce_permissions=true present and no false assignment; grep -c hl.permission = 4; no glob/alternation metacharacter; recovery text present; hyprctl configerrors empty; hyprctl getoption ecosystem:enforce_permissions byte-identical before/after hyprctl reload (both 'bool: true' — the flag's own readback updates fast on file-save/reload, which does not itself prove functional grant enforcement)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Live enforcement functionally proven end-to-end: a real session restart, all five screencopy consumer paths (overview thumbnails, screenshots, colour picker, browser screen-share, screen recording) exercised and passing under enforcement"
    verification: []
    human_judgment: true
    rationale: "DEFERRED by explicit operator decision — not performed, not skipped. This executor's terminal is a child process of the compositor; performing the restart would terminate the executing session. The full, run-cold procedure is recorded in deferred-items.md item 0. No requirement or must-have contingent on this proof is marked complete."

duration: single session (compressed run, deferred at the one genuine human-action checkpoint)
completed: 2026-08-03
status: complete
---

# Phase 16 Plan 04: Doctor Checks and Permissions Summary — Task 3 DEFERRED

**Seven new quickshell-doctor gates (D-16-23) land, fixture-proven able to fail; `enforce_permissions = true` ships committed in `permissions.lua`; but the real session-restart proof that live enforcement actually works end-to-end is explicitly DEFERRED by operator decision, not performed — record and revert procedure live in `deferred-items.md`.**

## Performance

- **Duration:** single session, compressed run (Tasks 1-2 auto-executed with live self-test/verify checks after each; Task 3's human-action checkpoint reached and, per operator instruction, deferred rather than executed)
- **Completed:** 2026-08-03
- **Tasks:** 2 of 3 complete (Task 3 deferred, see below)
- **Files modified:** 22 (19 created, 3 modified)

## Accomplishments

- Added seven `quickshell-doctor` checks (D-16-23) closing this phase's two owned failure modes on the gate side: `overview-namespace-conformance`, `overview-shortcut-single-registration`, `reserved-array-manifest-coverage`, `permissions-enforce-readback`, `permissions-allowlist-paths-resolve`, `overview-content-check`, and `single-capture-path` (a deliberate seventh check beyond D-16-23's own six, recorded as such). Every check has a committed poisoned fixture proven to FAIL and a clean counterpart proven to PASS via `--self-test` — the doctor's check count rises from 15 to 22, self-test from 19 to 36 entries, all clean.
- Live-proved the runtime-enforcement check can genuinely fail before anything makes it pass: before Task 2's edit, a live run reported `permissions-enforce-readback` FAILED (compositor still had enforcement off) — the required falsification-before-trust evidence.
- Enabled `enforce_permissions = true` in `permissions.lua` (D-16-09), touching no grant (still exactly 4, all exact absolute paths, no pattern broadened), with the recovery procedure and enablement provenance rewritten into the file's own header, and `gpu-screen-recorder`'s outstanding Phase-11 flag updated to point at where its live-under-enforcement proof will be recorded.
- **Task 3 — the real logout/login and five-consumer live proof — is explicitly DEFERRED, not completed.** The operator's own instruction, verbatim: *"Defer the logout/verification to the end of the phase; keep building. Leave enforce_permissions = true."* `deferred-items.md` item 0 is now the authoritative, run-cold procedure for whoever closes this out later — it was written so it can be executed correctly weeks from now without any memory of this session.
- Found and honestly reported a real gap between what this plan's `overview-content-check` (check 6) can catch and what 16-02/16-03's own inherited finding asked for: it catches the whole-grid permission-denial blank-tile failure (D-16-10), but not the collapsed/wrong-geometry failure class 16-02 actually hit twice. See Key Decisions and Next Phase Readiness.
- Fixed one pre-existing, unrelated self-test bug (Rule 3) and one self-caused baseline divergence (Rule 1) along the way — both documented below.

## Task Commits

Each completed task was committed atomically:

1. **Task 1: Extend quickshell-doctor with seven checks, each with a poisoned fixture** - `d02707d` (feat)
2. **Task 2: Enable enforcement and write the recovery procedure before the session restart** - `257a9e0` (feat)
3. **Task 3: Restart the session and exercise the five screencopy consumers under live enforcement** - **DEFERRED, not executed, not committed.** See "Deviations from Plan" and `deferred-items.md` item 0.

**Plan metadata:** (this commit)

## Files Created/Modified

- `hypr/.config/hypr/scripts/quickshell-doctor` — seven new checks, four new fixture seams (`QSD_FIXTURE_HYPRCTL_GETOPTION`/`PERMISSIONS_LUA`/`OVERVIEW_STATUS`/`OVERVIEW_QML_DIR`), the corresponding `--self-test` wiring, an `OVERVIEW_SUMMONED` trap variable for check 6's summon/dismiss cycle, and the Rule 3 pid-override fix to `_qsd_assert_panel_layers`.
- `hypr/.config/hypr/scripts/tests/quickshell-fixtures/*` — 18 new committed fixtures (compliant/poisoned pairs, and a few extra poison variants) backing the seven new checks.
- `hypr/.config/hypr/config/permissions.lua` — `enforce_permissions` flipped `false` -> `true`; header rewritten with enablement provenance and the recovery procedure; `gpu-screen-recorder` note updated to point at this plan's own (deferred) proof.
- `.planning/phases/13.1-hyprland-lua-config-migration/.hypr-baseline/options.jsonl` — one surgically-amended record (`ecosystem:enforce_permissions`, `int: 0` -> `int: 1`) so `hypr-equivalence-check` reflects the new intended value rather than flagging an intentional change as drift.
- `.planning/phases/16-workspace-overview/deferred-items.md` — created; item 0 is the authoritative Task 3 closeout procedure (readback command, doctor invocation, all five consumer paths with the `gpu-screen-recorder` flag, full revert steps); item 1 (pre-existing) documents the unrelated `binds.json` baseline drift found while establishing `theme-doctor` before/after counts.

## Decisions Made

See `key-decisions` in the frontmatter above for the full record. Summarised:
- Task 3 deferred by explicit operator decision — reason, evidence, and full closeout procedure recorded in `deferred-items.md` item 0, not just in this SUMMARY.
- `enforce_permissions = true` ships regardless of the deferral — this was an explicit operator choice, not an executor judgment call.
- Check 6 (`overview-content-check`) honestly assessed: covers D-16-10's whole-grid blank-tile/permission-denial failure mode; does NOT cover the per-delegate geometry-collapse failure mode 16-02 actually encountered twice. Flagged plainly for 16-05/16-08.
- Two auto-fixes (Rule 1, Rule 3) documented below rather than silently folded in.

## Deviations from Plan

### Deferred (not an auto-fix — an explicit operator decision, recorded per instruction)

**Task 3: Restart the session and exercise the five screencopy consumers under live enforcement**
- **Status:** DEFERRED, not completed, not skipped.
- **Reason:** Screen-capture permission grants are read once at Hyprland compositor startup (verified against the installed binary's own embedded string). Applying the enforcement flip requires a full logout/login, never `hyprctl reload`. This executor's own terminal runs as a child process of the compositor; performing the restart would terminate the executing session mid-plan — the exact risk Phase 11 originally declined to take, and why this plan wrote Task 3 as a `checkpoint:human-action gate="blocking"` in the first place.
- **What happened:** the checkpoint was reached correctly (see the prior turn's structured checkpoint message). The coordinator relayed the operator's explicit decision: *"Defer the logout/verification to the end of the phase; keep building. Leave enforce_permissions = true."*
- **What is NOT claimed:** no requirement or must-have that depends on live enforcement being functionally proven is marked complete. `requirements-completed: []` in this SUMMARY's frontmatter reflects that honestly — `OVER-01` remains correctly marked complete from Phase 16 Plan 02 (unrelated to Task 3), and this plan adds nothing new to REQUIREMENTS.md's checked list.
- **Authoritative record:** `deferred-items.md` item 0 — written to be executable cold, without this conversation, containing the exact `hyprctl getoption` command, the `quickshell-doctor` invocation, all five consumer paths (with `gpu-screen-recorder` explicitly flagged as Phase 11's unconfirmed consumer), and the full revert procedure.

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Pre-existing self-test bug blocked this plan's own `--self-test` exit-0 acceptance criterion**
- **Found during:** Task 1, first `--self-test` run after adding the seven new checks.
- **Issue:** `compliant-panel-layers.json` (a D-15-25 fixture, pre-existing, untouched by this plan) spuriously FAILED `panel-namespace-conformance` self-test because `_qsd_assert_panel_layers` compared the fixture's baked-in pid (`2982672`, captured 2026-08-02) against whatever `quickshell -p` process happens to be running live via `pgrep` — a mismatch on any host/session other than the one the fixture was captured on. This blocked Task 1's own literal acceptance criterion (`--self-test` must exit 0).
- **Fix:** Added an optional 4th parameter (`shell_pids_override`) to `_qsd_assert_panel_layers`; live call sites are unchanged (still real `pgrep`), and `--self-test`'s own replay now passes the fixture's own baked-in pid explicitly instead of comparing against live process state.
- **Files modified:** `hypr/.config/hypr/scripts/quickshell-doctor`
- **Verification:** `--self-test` now exits 0 (36 passed, 0 failed, up from a pre-existing 35 passed/1 failed baseline confirmed via `git stash` before this plan touched the file).
- **Committed in:** `d02707d` (Task 1 commit)

**2. [Rule 1 - Bug] This plan's own config change diverged `hypr-equivalence-check`'s baseline**
- **Found during:** Task 2, establishing `theme-doctor` before/after counts per its own acceptance criterion.
- **Issue:** Flipping `enforce_permissions` to `true` correctly caused `hypr-equivalence-check`'s `options.jsonl` comparison to diverge from the 13.1 pre-migration baseline (which recorded the old, unrestricted value) — a real, intended divergence being (correctly) flagged as drift.
- **Fix:** Surgically amended the one affected baseline record (`ecosystem:enforce_permissions`: `int: 0` -> `int: 1`), following 14-10's own established precedent for legitimate config changes. Proven surgical via `git diff` (exactly one line changed).
- **Files modified:** `.planning/phases/13.1-hyprland-lua-config-migration/.hypr-baseline/options.jsonl`
- **Verification:** `theme-doctor` before (permissions.lua unchanged, clean tree): 280 passed/1 failed. After (this plan's full diff, clean tree): 280 passed/1 failed — the same single pre-existing, unrelated failure (`binds.json`, see below), zero new failures attributable to `permissions.lua`.
- **Committed in:** `257a9e0` (Task 2 commit)

---

**Total deviations:** 1 explicit deferral (operator decision, not an auto-fix) + 2 auto-fixed (1 Rule 1, 1 Rule 3)
**Impact on plan:** Tasks 1 and 2 shipped exactly as written, both auto-fixes were necessary for correctness (a broken self-test gate, a false-positive equivalence-check drift) and are narrowly scoped. Task 3 is genuinely incomplete — this is stated plainly, not minimized.

## Issues Encountered

**A pre-existing, unrelated `hypr-equivalence-check` failure was found and left unfixed (correctly out of scope).** `binds.json` diverges from the 13.1 baseline — almost certainly because Phase 16 Plans 01-03 registered the `Super+O` global bind without amending the committed baseline snapshot, the same drift class 14-10 already fixed once for `Super+D`. Confirmed pre-existing and unrelated to this plan's own changes via `git stash`/re-run (the failure is byte-identical present in both the before-edit and after-edit `theme-doctor` runs). Logged to `deferred-items.md` item 1 with a recommended fix procedure; not fixed here per the Scope Boundary rule.

**Honest limitation of check 6, stated per explicit request (carry forward for 16-05/16-08):** `overview-content-check` parses the existing `overview` IPC status verb's aggregate `windows=N withContent=M` counts and asserts `M > 0` whenever `N > 0`. This is a real, fixture-proven-fallible gate for the whole-grid permission-denial blank-tile failure (D-16-10) — but it is NOT a per-delegate geometry/position cross-check against `hyprctl clients -j`, and would NOT independently catch a defect where delegates render at collapsed or overlapping positions while `hasContent` stays `true` for every one of them (screencopy capture succeeds; only the geometry is wrong) — the EXACT defect class 16-02 hit twice and that only a temporary per-delegate measurement verb and the human render gate ultimately caught. This is a faithful, literal implementation of D-16-23's own check-6 wording and of this plan's Task 1 action text — extending the shipped IPC surface to expose per-delegate geometry aggregates without leaking window titles/addresses (16-02's own removed diagnostic verb was pulled specifically for that leak, against T-16-06) is a genuine, unresolved design question this plan did not attempt. **16-05 and 16-08, which lean on this check, should treat it as covering the blank-tile/permission-denial failure mode only** and continue to rely on the human render gate (or a future, carefully-scoped IPC extension) for the geometry-collapse failure mode.

## User Setup Required

**Yes — this plan cannot fully close without a human action.** See `.planning/phases/16-workspace-overview/deferred-items.md` item 0 for the complete, self-contained procedure: log out and back in, run the `hyprctl getoption` readback, run `quickshell-doctor`, and exercise all five screencopy consumer paths (overview thumbnails, screenshots, colour picker, browser screen-share, and `gpu-screen-recorder` screen recording — Phase 11's flagged, unconfirmed consumer). Until that item is marked RESOLVED, D-16-09's live-enforcement proof and this plan's Task 3 remain open.

## Next Phase Readiness

- **`enforce_permissions = true` is live in the committed config but functionally unproven end-to-end.** Every later plan in this phase (16-05 through 16-08) that relies on screencopy working under enforcement should be aware the underlying grant mechanism has not yet survived a real restart — if a fresh session eventually surfaces a broken consumer, the fix is a fifth grant (most likely `gpu-screen-recorder`) per `deferred-items.md` item 0, not a revert of this plan's work.
- **`quickshell-doctor`'s `permissions-enforce-readback` check (D-16-23 check 4) will read PASS right now**, even though functional enforcement is unproven — its readback reflects the flag's fast-updating value, not the restart-only grant mechanism. Do not treat a green check 4 as equivalent to Task 3 being done.
- **Check 6 (`overview-content-check`) covers blank-tile/permission-denial only, not geometry-collapse** — see Issues Encountered above. 16-05 (click parity) and 16-08 (perf measurement) both instantiate/observe many thumbnails at once and should keep the human render gate as their real defense against a geometry regression, not lean on check 6 alone.
- **`deferred-items.md` now carries two items**, both self-contained: item 0 (this plan's Task 3, DEFERRED) and item 1 (pre-existing `binds.json` baseline drift, unrelated). Whoever closes item 0 should also consider closing item 1 in the same sitting (both touch the same 13.1 baseline directory).
- The seven new `quickshell-doctor` checks and their fixtures are fully shipped and self-test-clean — no follow-up needed there.

---
*Phase: 16-workspace-overview*
*Completed: 2026-08-03 (Tasks 1-2 of 3; Task 3 deferred by operator decision)*

## Self-Check: PASSED

- FOUND: .planning/phases/16-workspace-overview/16-04-SUMMARY.md
- FOUND: .planning/phases/16-workspace-overview/deferred-items.md
- FOUND: commit d02707d (Task 1)
- FOUND: commit 257a9e0 (Task 2)
- Task 3 correctly NOT claimed as a commit — deferred per operator decision
