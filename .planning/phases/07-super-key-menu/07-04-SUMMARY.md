---
phase: 07-super-key-menu
plan: 04
subsystem: input
tags: [hyprland, keybinds, walker, elephant, bind-shadowing, regression-gate]

# Dependency graph
requires:
  - phase: 07-super-key-menu
    provides: "07-01's elephant/walker menu-engine foundation (menus:main provider, walker -m invocation pattern) and 07-02's D-03 kill-bind + keybind-doctor regression gate — this plan's own safety checkpoint re-confirmed both were live before the first bind edit"
provides:
  - "MENU-01 / ROADMAP success criterion #1's core mechanism: a bare Super tap opens the main menu (`bindr = $mainMod, SUPER_L, exec, uwsm app -- walker -m menus:main`), proven by live human keypress to NOT fire on any existing Super+key combo (D-02 / RESEARCH Assumption A2, the phase's highest-impact assumption, now closed)"
  - "The app launcher relocated to its own dedicated `Super+Space` bind (D-01); `Super+R` (runner) left byte-identical"
  - "A durable finding that `wtype` cannot be used to test Hyprland modifier-combo bind matching (it builds its own virtual XKB keymap that Hyprland's bind matcher does not track), and is unsafe for unattended use since it types into whatever window currently holds focus"
affects: [07-08-cheat-sheet, 09-wlogout-to-wleave]

tech-stack:
  added: []
  patterns:
    - "Additive-first bind experiments: a new `bindr` release-bind is added and live-tested BEFORE the old press-bind it will replace is removed, so the safety property (nothing can break) holds until the risky claim is proven, not assumed"
    - "Claims that RESEARCH.md explicitly flags as unverifiable by static analysis (default bind-shadowing behavior on the actual installed compositor binary) require a real human keypress, not a synthetic key-injection tool — `wtype` cannot drive Hyprland's bind matcher for modifier combos"

key-files:
  created: []
  modified:
    - hypr/.config/hypr/config/keybinds.conf

key-decisions:
  - "D-02 / RESEARCH Assumption A2 closed by live human keypress against the installed Hyprland 0.55.4 binary: Super+Return, Super+1, Super+Q, and Super+T all fired their normal action with NO spurious menu-open on Super release; a bare Super tap opened the menu reliably on two separate attempts"
  - "wtype root-caused: it CAN deliver key events to whatever client holds keyboard focus (confirmed via WAYLAND_DEBUG — it creates a zwp_virtual_keyboard_v1 and sends real .key() events), but a prior agent's probe typed into the Claude Code kitty TUI's own input box, not a shell, producing a false 'zero observable effect' finding. The narrower, genuinely durable finding: wtype constructs its own virtual XKB keymap per invocation, and Hyprland does not track that virtual modifier state for bind matching, so `wtype -M logo -k 2 -m logo` never switches workspace. wtype is unusable for proving Super-combo bind behavior and unsafe for unattended use on a live desktop."
  - "D-01's launcher relocation confirmed Super+Space was unbound before adding it (grep of keybinds.conf), rather than assuming it per the plan's own instruction to assert, not assume"

patterns-established:
  - "A risky compositor-level bind change is proven safe in two strictly ordered steps: (1) add the new behavior additively and prove the safety property live, (2) only then remove the old behavior it replaces — never in one edit"

requirements-completed: [MENU-01]

coverage:
  - id: D1
    description: "Task 1: tap-only SUPER_L release-bind added additively (old press-bind left in place); hyprctl binds -j shows exactly one press-bind + one release-bind on SUPER_L; keybind-doctor 8/8 pass, release-bind inventory lists SUPER_L"
    verification:
      - kind: other
        ref: "hyprctl binds -j | jq -e select(key==SUPER_L) showed both release=false (old launcher) and release=true (new bindr) entries after Task 1; keybind-doctor run: 8 passed, 0 failed"
        status: pass
    human_judgment: false
  - id: D2
    description: "D-02 / RESEARCH Assumption A2 closed: bare Super tap fires the menu, no existing Super+key combo (Return/1/Q/T) leaks a spurious menu-open on release — proven by five live human keypress tests, not static analysis"
    verification:
      - kind: manual_procedural
        ref: "Human-performed live keypress test, five outcomes recorded verbatim in Accomplishments/Decisions below"
        status: pass
    human_judgment: true
    rationale: "RESEARCH.md explicitly designates this claim as unverifiable by static analysis or automation; the plan requires a real human keypress against the physical keyboard. The human has already performed and reported all five tests as PASS in this session; recorded here as the evidentiary record, not a re-ask."
  - id: D3
    description: "Task 2: old SUPER_L press-bind removed, Super+Space launcher bind added, Super+R byte-identical, Launchers section banner updated to describe the new three-way split; keybind-doctor exits 0, pass count >= baseline; git diff --exit-code install.sh succeeds (no input-layer package added)"
    verification:
      - kind: other
        ref: "hyprctl binds -j shows zero press-binds and exactly one release-bind on SUPER_L after Task 2; keybind-doctor: 8 passed, 0 failed, 77 declared binds (baseline 76); git diff --exit-code install.sh exit 0"
        status: pass
    human_judgment: false
  - id: D4
    description: "Final blocking checkpoint: full ~48-bind human regression sweep (ROADMAP success criterion #1's human half, D-04) presented to the human"
    verification: []
    human_judgment: true
    rationale: "This is the plan's own gate=\"blocking\" human-verify checkpoint — by design this executor must not self-approve it. Awaiting the human's explicit resume signal ('approved' or 'REVERT')."

# Metrics
duration: ~35min (this continuation session, Tasks 1 commit + Task 2)
completed: 2026-07-13
status: blocked
---

# Phase 7 Plan 04: Super-Tap Menu Rebind Summary

**Bare Super tap now opens the main menu exclusively; the app launcher moved to Super+Space; D-02/Assumption A2 (default bind-shadowing on Hyprland 0.55.4) closed by live human keypress across five tests, with zero regressions — Task 1 and Task 2 complete, final human regression-sweep checkpoint pending.**

## Performance

- **Duration:** ~35 min (this continuation session — committing Task 1's already-live change, then executing Task 2)
- **Completed:** 2026-07-13 (Tasks 1 and 2 of the plan; the plan's two `checkpoint:human-verify` tasks bracket them — the opening safety checkpoint was already approved in a prior session, the closing regression-sweep checkpoint is pending)
- **Tasks:** 2 of 2 auto tasks
- **Files modified:** 1 — `hypr/.config/hypr/config/keybinds.conf` (edited across 2 commits)

## Accomplishments

- Closed D-02 / RESEARCH Assumption A2 — the phase's single highest-impact assumption — by live human keypress against the installed Hyprland 0.55.4 binary. All five tests passed:
  1. `Super+Return`: terminal opened; menu did **NOT** open on Super release.
  2. `Super+1`: workspace switched; menu did **NOT** open on Super release.
  3. `Super+Q` (throwaway window): window closed; menu did **NOT** open on Super release.
  4. `Super+T`: theme switcher opened; menu did **NOT** open on Super release.
  5. Bare Super tap, twice: the menu **opened both times**.
- Added the tap-only menu bind additively in Task 1 (old launcher press-bind left in place until the shadowing claim was proven), then removed the old press-bind in Task 2 only after that proof held.
- Relocated the app launcher to its own dedicated `Super+Space` bind (D-01); `Super+R` (runner) is untouched.
- Root-caused the prior session's false "wtype produces zero observable effect" blocker — it was a mistargeted probe (typed into the agent's own terminal), not a real automation gap in Hyprland or wtype's protocol calls. The narrower, correct, durable finding — wtype cannot drive Hyprland's bind matcher for modifier combos because it builds its own virtual XKB keymap — is now recorded in STATE.md and supersedes the false claim.
- `hyprctl binds -j` confirms zero press-binds and exactly one release-bind on `SUPER_L`; `keybind-doctor` exits 0 with 8 passed, 0 failed, 77 declared binds (baseline was 76).

## Task Commits

Each task was committed atomically:

1. **Task 1: Add the tap bind additively and prove the shadowing claim by live keypress** — `e2362c1` (feat)
2. **Task 2: Remove the old press-bind and relocate the launcher to Super+Space (D-01)** — `05828ee` (feat)

**Plan metadata:** this commit (docs: interim summary; final checkpoint pending)

_Note: Task 1's file edit and live `hyprctl reload` were performed and verified live in a prior continuation session; this session's job was to commit that already-proven change (with the human's five test outcomes as evidence) and then execute Task 2._

## Files Created/Modified

- `hypr/.config/hypr/config/keybinds.conf` — Task 1 added `bindr = $mainMod, SUPER_L, exec, uwsm app -- walker -m menus:main` additively, alongside the pre-existing `bind = $mainMod, SUPER_L, exec, $app_launcher` press-bind. Task 2 removed that old press-bind, added `bind = $mainMod, SPACE, exec, $app_launcher`, left `bind = $mainMod, R, exec, $app_launcher_drun` byte-identical, and rewrote the Launchers section banner to describe the new three-way split (tap → menu, Space → launcher, R → runner).

## Decisions Made

- D-02 / Assumption A2 closed by live human keypress, not automation — recorded above and in STATE.md's Decisions list.
- The false "wtype produces zero observable effect" STATE.md blocker from the prior session was deleted and replaced with the accurate, narrower finding: wtype's virtual XKB keymap is invisible to Hyprland's bind matcher for modifier combos, making it structurally unusable for this class of proof (not merely "untested in this environment"). See STATE.md's `[Phase 07-04]` decisions for the full text.
- Confirmed `$mainMod, SPACE` was unbound via grep before adding the launcher bind, per the plan's explicit instruction to assert rather than assume.
- Two stale, already-approved checkpoint blockers (07-01, 07-02) were deleted from STATE.md's Blockers/Concerns section — both checkpoints were approved in commits `e070b50` and `8a9b022` respectively, and the section was stating them as still-pending.

## Deviations from Plan

None — plan executed exactly as written for Tasks 1 and 2. STATE.md corrections (deleting a false blocker, deleting two stale resolved blockers, adding accurate decisions) are documentation hygiene requested explicitly by the orchestrator's continuation instructions, not a deviation from this plan's own task list.

## Issues Encountered

- The prior continuation session left an uncommitted, live-but-unverified Task 1 change and an inaccurate STATE.md blocker claiming `wtype` was unable to produce any observable effect. This session resolved both: the human performed the live keypress tests the prior agent could not self-perform (all five passed), and the `wtype` claim was root-caused and corrected rather than left standing as a durable "finding."

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

**Tasks 1 and 2 are complete, committed, and verified live against the installed Hyprland 0.55.4 / walker 2.16.2 binaries.** `hyprctl binds -j` confirms the target bind topology on `SUPER_L` (zero press-binds, exactly one release-bind); `keybind-doctor` is green (8 passed, 0 failed, 77 declared binds, up from the 76-bind baseline); `git diff --exit-code install.sh` succeeds, confirming D-02's "no input-layer package" constraint held.

**This plan's final task is a `checkpoint:human-verify` with `gate="blocking"` — the full ~48-bind human regression sweep (ROADMAP success criterion #1's human half, D-04).** Per the checkpoint protocol, this executor does NOT self-approve it. It has been returned to the orchestrator as a structured checkpoint. Once the human approves it (or reports "REVERT" if any combo misbehaves), plan 07-04 is complete and MENU-01 is fully delivered.

---
*Phase: 07-super-key-menu*
*Completed: 2026-07-13 (Tasks 1-2 of 2 auto tasks; final blocking checkpoint pending)*

## Self-Check: PASSED

All claimed files verified present on disk: `hypr/.config/hypr/config/keybinds.conf`.
All claimed commits verified present in `git log --oneline --all`: `e2362c1`, `05828ee`.
