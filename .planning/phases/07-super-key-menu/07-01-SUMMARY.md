---
phase: 07-super-key-menu
plan: 01
subsystem: launcher
tags: [walker, elephant, hyprland, gtk4, dmenu, stow]

# Dependency graph
requires:
  - phase: 06-themed-surfaces-utility-suite
    provides: CLI-invokable utility scripts, walker-style.css contract target #18
provides:
  - "Empirical proof the elephant `menus` provider (2.21.0) correctly loads TOML menu definitions, registers `menus:<name>` providers, expresses submenus, actions, and Nerd Font glyph-as-text entries"
  - "Empirical proof walker's `menus` drill-down and Esc back-navigation work correctly when invoked via `-m <provider>` (exclusive-provider mode)"
  - "A newly discovered, reproducible walker 2.16.2 defect: `walker -s <name>` (GUI/non-dmenu mode) panics and aborts the ENTIRE walker gapplication-service — including the pre-existing, currently-bound `-s runner` — fixed at the wiring layer by adopting `-m` everywhere"
  - "A stow-managed `elephant/` package (elephant added to stow.sh PACKAGES) creating `~/.config/elephant/menus/` with a working placeholder root menu (`menus:main`, Power entry delegating to wlogout.sh)"
  - "`hypr/.config/hypr/scripts/elephant-restart.sh` — the single owner of the elephant+walker daemon-cycling step every later Phase 7 plan will call, readiness-gated on `elephant listproviders` actually responding"
  - "walker's `[placeholders]` table wired for `menus:main` with 07-UI-SPEC's locked root copy — the exact key form (`menus:main`, NOT the base provider name `menus`) verified by screenshot against the running binary, not assumed"
affects: [07-02-app-launcher-relocation, 07-04-super-tap-bind, 07-05, 07-06, 07-07, 07-08]

tech-stack:
  added: []
  patterns:
    - "elephant-restart.sh: pgrep-guarded kill/relaunch/bounded-poll idiom, readiness gated on the real signal (`elephant listproviders` succeeding) rather than a bare sleep — mirrors theme-engine/lib/reload.sh's house pattern"
    - "walker `[placeholders]` keys must match the FULLY QUALIFIED provider id used by the invocation (`menus:main`), not the bare provider name (`menus`) that appears in `[providers] default` — confirmed empirically, not documented anywhere upstream"

key-files:
  created:
    - elephant/.config/elephant/menus/main.toml
    - hypr/.config/hypr/scripts/elephant-restart.sh
  modified:
    - stow.sh
    - walker/.config/walker/config.toml

key-decisions:
  - "D-05 core question (does the elephant `menus` provider express submenus/actions/glyphs) resolves GO — proven live via `-m menus` GUI invocation with screenshot evidence (Task 1), reconfirmed against the real `menus:main` provider (Task 3)"
  - "D-06 (Esc/Backspace one-level-back) resolves GO via Escape — proven live with screenshot evidence in Task 1 (drill-down in, Escape back to parent, Escape again closes entirely) and reconfirmed in Task 3 (Esc closes the root-level `menus:main` window while the walker service stays alive)"
  - "ARCHITECTURAL DECISION (taken by user between sessions, committed 117edc9/7adc2a2): `walker -s <name>` / any `[sets.*]` TOML table is DEAD on walker 2.16.2 — panics the gapplication-service (`can't find specified set`, src/data.rs:566), reproduced against the pre-existing untouched `[sets.runner]` block too, meaning `Super+R` was already broken in production before this phase touched anything. Replaced everywhere with exclusive-provider mode: `walker -m <provider>` (e.g. `walker -m menus:main`, `walker -m runner`) — verified to render and leave the service alive. No `[sets.menu]` block was ever created; the plan's Task 3 body was rewritten before Task 3 executed, so this repo never shipped the broken mechanism."
  - "walker `[placeholders]` KEY FORM finding (Task 3, this session): the base provider name (`\"menus\"`) does NOT render a placeholder when the window is opened via `-m menus:main` — the input box is empty. Only the fully-qualified `\"menus:main\"` key renders 07-UI-SPEC's locked copy (`Search or select...`). Verified by screenshot before AND after the fix — this is exactly the class of assumption D-05 exists to catch, caught on a second, smaller surface (config key naming) within the same plan."
  - "The dead-`[sets.*]` explanatory comment in walker/config.toml was reworded (Task 3, this session) because its first draft literally contained the substring `[sets.` inside its own prose (`` `[sets.*]` ``), which made the plan's own automated verify gate (`! grep -q '\\[sets\\.' config.toml`) fail against a comment explaining why sets are dead. Reworded to describe the mechanism without ever writing an open-bracket immediately before `sets.`."

patterns-established:
  - "Never trust a config-file key/block's presence as evidence it renders correctly — verify with a screenshot of the actual running window, twice if the first key form fails (menus vs menus:main)."

requirements-completed: []  # MENU-01 (tap-bind + regression sweep) is NOT completed by this plan — that's 07-04. This plan lays the elephant/walker menu-engine foundation only. Checkpoint (human-verify) is still pending — do not mark requirements complete until the human approves.

coverage:
  - id: D1
    description: "elephant `menus` provider proven to express submenus, leaf actions, Nerd Font glyph-as-text, and Esc one-level-back-nav on the installed 2.21.0/2.16.2 binaries (D-05/D-06/D-07 spike, Task 1)"
    verification:
      - kind: manual_procedural
        ref: "Task 1 spike: screenshots /tmp/spike-screenshot-2.png, /tmp/spike-after-enter.png, /tmp/spike-after-escape.png, /tmp/spike-after-escape2.png (not committed, host-local); elephant listproviders showing menus:spike-root/menus:spike-child"
        status: pass
    human_judgment: true
    rationale: "Visual GTK4 rendering (glyph-vs-tofu, drill-down swap, back-nav) requires human/screenshot judgment, not a scriptable assertion."
  - id: D2
    description: "stow-managed elephant/ package creates ~/.config/elephant/menus/ via symlink (D-34); elephant registers menus:main"
    verification:
      - kind: other
        ref: "readlink -f ~/.config/elephant/menus/main.toml resolves into repo; elephant listproviders | grep menus:main"
        status: pass
    human_judgment: false
  - id: D3
    description: "elephant-restart.sh cycles elephant + walker's gapplication-service, readiness-gated on elephant listproviders responding (not a bare sleep), leaves exactly 1 of each process, notify-send + nonzero exit on failure"
    verification:
      - kind: other
        ref: "bash -n + shellcheck (0 findings) + live run: pgrep -c -x elephant == 1, pgrep -c -x walker == 1, elephant listproviders succeeds post-restart"
        status: pass
    human_judgment: false
  - id: D4
    description: "walker -m menus:main renders the themed menu window with 07-UI-SPEC's exact locked placeholder copy (\"Search or select...\") and a real glyph (not tofu); Esc closes the window while the walker service survives; zero new contract targets (D-08, contract.json byte-identical)"
    verification:
      - kind: manual_procedural
        ref: "This session's screenshots (not committed, host-local, deleted after review): confirmed \"menus\" key renders EMPTY placeholder (bug), \"menus:main\" key renders \"Search or select...\" correctly; Power glyph renders as a real power icon; Esc closes window, pgrep -x walker still returns a PID afterward"
        status: pass
    human_judgment: true
    rationale: "Visual theming parity and glyph legibility require human/screenshot judgment — this is also exactly the substance of the plan's own checkpoint task (\"Verify the menu engine renders live\"), which is still PENDING human sign-off as of this SUMMARY. D4's automated pre-checks all pass; the checkpoint is the final human confirmation layer on top of this same evidence."

# Metrics
duration: ~30min (Task 1, prior session) + ~35min (Tasks 2-3, this continuation session)
completed: 2026-07-13
status: blocked
---

# Phase 7 Plan 01: Elephant Menu Engine Foundation Summary

**D-05 spike proved the elephant `menus` provider works end-to-end (submenus/actions/glyphs/back-nav all GO), disproved `walker -s`/`[sets.*]` as a live-service-killing bug on walker 2.16.2, and — after the user's architectural decision to adopt `-m` exclusive-provider mode — Tasks 2-3 shipped a stow-managed `elephant/` menu package, `elephant-restart.sh`, and a `walker -m menus:main` invocation that correctly renders 07-UI-SPEC's locked placeholder copy, with the exact `[placeholders]` key form (`"menus:main"`, not `"menus"`) verified by screenshot rather than assumed. The plan's final task is a blocking human-verify checkpoint, still pending.**

## Performance

- **Duration:** ~30 min (Task 1, session 1, 2026-07-13T14:11–14:41Z) + ~35 min (Tasks 2-3, this continuation session, 2026-07-13T~14:52–15:27Z)
- **Completed:** 2026-07-13 (Tasks 1-3); checkpoint task still pending human sign-off
- **Tasks:** 3 of 4 executed (Task 1 spike, Task 2 stow package, Task 3 restart script + walker wiring); Task 4 (checkpoint) awaiting human
- **Files modified:** 4 total across Tasks 2-3 — `elephant/.config/elephant/menus/main.toml` (new), `stow.sh` (modified), `hypr/.config/hypr/scripts/elephant-restart.sh` (new), `walker/.config/walker/config.toml` (modified). Task 1's spike artifacts were fully cleaned up (net zero diff), as the plan required.

## What Happened

### Session 1 — Task 1 (D-05 spike), then escalation

Per the plan's `<critical_context>` mandate, Task 1 (D-05's mandatory spike) was executed for real against the installed `elephant 2.21.0` + `walker 2.16.2` binaries on the live Hyprland session. Full detail preserved below (see "Task 1 — Full Findings"). In short: the `menus` provider itself works completely (D-05/D-06/D-07 all GO), but the plan's chosen invocation mechanism, `walker -s <set>`, was found to panic and kill the walker gapplication-service — a NEW, unanticipated blocker not caused by the spike's own content, reproduced even against the pre-existing, untouched `[sets.runner]` block already shipped in this repo (meaning `Super+R` was already broken in production). Per Rule 4 (architectural decision), the executor stopped after Task 1 rather than silently substituting a fix, and escalated with three candidate paths.

### Between sessions — the architectural decision

The user decided (commits `117edc9`, `7adc2a2`): adopt `-m`/`--provider` exclusive-provider mode everywhere `walker -s <set>` was planned. `walker -m menus:main` and `walker -m runner` were both independently re-verified by the orchestrator (PID before/after) to render and leave the walker service alive. 07-01-PLAN.md gained a `<spike_correction>` block; Task 3's body was rewritten to drop the `[sets.menu]` deliverable entirely, in favor of a `[placeholders]` table row plus deletion of the now-dead `[sets.runner]` block. 07-02, 07-04, 07-RESEARCH.md, 07-PATTERNS.md, and 07-CONTEXT.md were amended in the same commit series. No locked D-xx decision changed; only the invocation mechanism.

### Session 2 (this continuation) — Tasks 2 and 3

Resumed per the orchestrator's explicit instruction to re-read 07-01-PLAN.md fresh (not from memory) and execute from Task 2.

**Task 2 — elephant stow package:** Found ALREADY committed (`e9c3a24`) at the start of this continuation session — a prior partial run had completed and committed it before this session began. Verified rather than re-done: `elephant/.config/elephant/menus/main.toml` exists (`name = "main"`, single Power entry delegating to `wlogout.sh` per D-19), `elephant` is in `stow.sh`'s `PACKAGES` array in alphabetical position, `readlink -f ~/.config/elephant/menus/main.toml` resolves into the repo working tree (proving the stow symlink, not host-only state — D-34), and `elephant listproviders` prints `menus:main`.

**Task 3 — elephant-restart.sh + walker wiring:** Found PARTIALLY DONE but UNCOMMITTED at the start of this continuation session — `hypr/.config/hypr/scripts/elephant-restart.sh` existed as an untracked, executable file, and `walker/.config/walker/config.toml` had uncommitted changes (dead `[sets.runner]` deleted, replaced with an explanatory comment; a `[placeholders]` row added keyed `"menus"`). This session:

1. Verified `elephant-restart.sh` passes `bash -n` and `shellcheck` (0 findings) and is executable.
2. Ran it live: cycled elephant then walker's gapplication-service, readiness-gated on `elephant listproviders` actually responding (not a bare sleep, per the plan's explicit mandate) — confirmed exactly 1 `elephant` and 1 `walker` process survive, and `elephant listproviders` prints `menus:main` afterward.
3. **Live-verified the `[placeholders]` key form by screenshot** (`grim`), per the plan's explicit "do not assume the key form" mandate: launched `walker -m menus:main` with the uncommitted `"menus"` key present — **the placeholder input box rendered EMPTY**, not `"Search or select..."` as required. This falsified the uncommitted draft. Edited the key to `"menus:main"`, restarted walker's service to pick up the change, relaunched `walker -m menus:main`, and screenshotted again — this time the placeholder rendered correctly (`Search or select...`), and the Power entry's glyph rendered as a real power icon (not tofu). Pressed Esc via `wtype`, confirmed the window closed and `pgrep -x walker` still returned a PID (service survived).
4. **Found and fixed a second, unrelated bug**: the uncommitted `[sets.*]`-is-dead explanatory comment literally contained the substring `[sets.` in its own prose (`` `[sets.*]` ``), which the plan's own automated verify gate (`! grep -q '\[sets\.' config.toml`) would fail against. Reworded the comment to describe the same mechanism without ever writing an open-bracket immediately before `sets.` — re-ran the exact automated verify command from the plan, confirmed it now passes.
5. Confirmed `theme-engine/.config/theme-engine/contract.json` is byte-identical to `HEAD` (`git diff --exit-code`) — D-08's zero-new-render-target mandate holds.
6. Committed Task 3 (`238095a`).

## Task 1 — Full Findings (preserved from prior session for provenance)

### Spike procedure (as specified by the plan)

1. Created throwaway `~/.config/elephant/menus/spike-root.toml` (two entries: one leaf with a Nerd Font glyph U+F0AD `nf-fa-wrench` in `text` + a `notify-send` action, one `submenu = "spike-child"`) and `spike-child.toml` (`parent = "spike-root"`, one leaf entry), directly on the host, NOT in the repo.
2. Restarted elephant (`pkill -x elephant` → `uwsm app -- elephant`). `elephant listproviders` confirmed BOTH `menus:spike-root` and `menus:spike-child` registered.
3. Added a temporary `[sets.spike]` block to `walker/.config/walker/config.toml` (`providers = ["menus:spike-root"]`) to test Open Question 1, mirroring `[sets.runner]`'s exact shape as instructed.
4. Restarted walker and attempted `walker -s spike` (GUI mode) — **this crashed the entire walker service** (see Finding 3 below). Diagnosed and worked around this by using `walker -m menus` (exclusive-provider mode) instead, which does NOT crash and DOES render the spike menu content, allowing the rest of the spike (drill-down, glyph rendering, back-navigation) to be verified visually.
5. Deleted both spike TOML files, removed the `[sets.spike]` block (byte-identical to pre-spike original), restarted elephant + walker to a clean healthy baseline.

### Finding 1 — D-05 core question: GO

`walker -m menus` (GUI, non-dmenu) rendered a real walker window showing both spike-root entries ("Spike Child", "Spike Leaf" — alphabetically sorted since `fixed_order` wasn't set). The wrench glyph (U+F0AD) rendered as an actual glyph character, not a tofu box — D-07 confirmed visually. Pressing `Return` on the "Spike Child" entry swapped the SAME window's list to show "Spike Child Leaf" — confirming the elephant `menus` provider's submenu/drill-down protocol works correctly and swaps content in-place.

### Finding 2 — D-06: Esc navigates back exactly one level (GO)

From the child-menu state, pressing `Escape` swapped the list BACK to spike-root's two entries — confirming Esc performs exactly the one-level-back navigation D-06 requires, not a full close. A second `Escape` from the root level closed the window entirely — matching 07-UI-SPEC.md's exact "Esc from the root level closes the menu entirely" contract.

### Finding 3 — NEW BLOCKER (since resolved): `walker -s <name>` (GUI mode) crashes the walker daemon

Reproduced 5× deterministically, including against the pre-existing, untouched `[sets.runner]` block already shipped in this repo (meaning `Super+R` was already broken in production, independent of this phase). Trace: `thread 'main' (PID) panicked at src/data.rs:566:18: can't find specified set`. Control tests that did NOT crash: `--dmenu` mode with `-s`, and `walker -m menus` (exclusive-provider mode, GUI). **Resolution (this session, downstream of the user's decision): `-m` adopted everywhere; no `[sets.menu]` block was ever created in this repo.**

## Decisions Made

- (Session 1) Did not improvise a fix for the `-s` crash — escalated per Rule 4, architectural decision required.
- (Between sessions) User decided: adopt `-m`/`--provider` exclusive-provider mode throughout the phase. Plans amended before Task 2/3 execution resumed.
- (This session, Task 3) When the uncommitted draft's `[placeholders]` key (`"menus"`) was found to render an empty placeholder, did NOT fall back to improvising different placeholder copy or silently accepting the empty box — retried the qualified `"menus:main"` key exactly as the plan's `<critical_context>` prescribed, confirmed it renders 07-UI-SPEC's exact locked copy, and used it.
- (This session, Task 3) Reworded the dead-`[sets.*]` explanatory comment so its own prose doesn't defeat the plan's automated verify gate — a self-referential edge case not anticipated by the plan author, fixed as a Rule 3 blocking-issue auto-fix (the plan's own acceptance criteria could not otherwise be satisfied).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `[placeholders]` key `"menus"` renders an empty placeholder under `walker -m menus:main`; `"menus:main"` is required**
- **Found during:** Task 3, live screenshot verification (the exact check the plan's `<critical_context>` mandates)
- **Issue:** The uncommitted draft keyed the placeholder row by the bare provider name (`"menus"`, matching `[providers] default`'s entry). When walker is invoked with `-m menus:main` (the qualified provider id `elephant listproviders` actually registers), walker's placeholder lookup evidently keys off the qualified id, not the bare provider name — the input box rendered with no placeholder text at all.
- **Fix:** Changed the key to `"menus:main"`. Restarted walker's gapplication-service to pick up the new config (walker has no live-reload for `config.toml`), relaunched `walker -m menus:main`, and confirmed by screenshot that `Search or select...` now renders correctly.
- **Files modified:** `walker/.config/walker/config.toml`
- **Verification:** Two screenshots, before (empty box) and after (correct placeholder) the fix — see coverage D4.
- **Committed in:** `238095a` (Task 3 commit)

**2. [Rule 3 - Blocking] Dead-`[sets.*]` explanatory comment defeated the plan's own automated verify gate**
- **Found during:** Task 3, running the plan's exact automated verify command (`! grep -q '\[sets\.' walker/.config/walker/config.toml`)
- **Issue:** The uncommitted draft's comment explaining why `[sets.*]` is dead literally wrote `` `[sets.*]` `` inline, which contains the substring the verify gate greps for — making the comment itself trip the very check it exists to satisfy.
- **Fix:** Reworded the comment to describe the mechanism (`walker -s <name>` / the TOML "sets" tables) without ever placing an open-bracket immediately before `sets.`.
- **Files modified:** `walker/.config/walker/config.toml`
- **Verification:** Re-ran the plan's exact automated verify command after the fix — passes.
- **Committed in:** `238095a` (Task 3 commit)

---

**Total deviations:** 2 auto-fixed (1 bug, 1 blocking), 0 escalated this session (Task 1's architectural escalation from the prior session was resolved by the user before this session began)
**Impact on plan:** Both fixes were necessary for the plan's own acceptance criteria to be satisfiable at all — no scope creep. The placeholder key finding is exactly the kind of "verify against the running binary" discovery this whole plan exists to make.

## Issues Encountered

See Finding 3 (Task 1, prior session, resolved) and the two auto-fixed deviations above (Task 3, this session). No unresolved issues remain in Tasks 1-3.

## Task Commits

1. **Task 1: Spike the elephant menus provider** — `4f2becb` (docs: spike proves provider works, escalates on walker -s crash), `6f4e4b2` (docs: record blocker/session state)
   - *(between sessions, user decision)* `117edc9` (docs: amend plans — adopt -m exclusive-provider), `7adc2a2` (docs: resolve blocker, plans amended)
2. **Task 2: Create the elephant stow package** — `e9c3a24` (feat: elephant stow package + stow.sh registration) — found already committed at the start of this continuation session
3. **Task 3: elephant-restart.sh + walker config wiring** — `238095a` (feat: elephant-restart.sh, menus placeholder wired, dead [sets.*] removed) — this session

**Plan metadata:** this commit (docs: extend SUMMARY to cover Tasks 1-3, update STATE/ROADMAP) — see below; plan is NOT yet complete, checkpoint pending.

## Files Created/Modified

- `elephant/.config/elephant/menus/main.toml` - Placeholder root menu TOML: single Power entry delegating to `wlogout.sh` (D-19); full six-entry root menu lands in 07-05
- `stow.sh` - `elephant` added to `PACKAGES` array, alphabetically ordered
- `hypr/.config/hypr/scripts/elephant-restart.sh` - Cycles elephant then walker's gapplication-service; readiness-gated on `elephant listproviders` responding; notify-send + nonzero exit on failure; executable bit committed (mode 100755)
- `walker/.config/walker/config.toml` - `[placeholders]` gains a `"menus:main"` row carrying 07-UI-SPEC's locked copy; dead `[sets.runner]` block deleted and replaced with an explanatory comment (reworded to not self-defeat the verify gate)

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

**Tasks 1-3 are functionally complete and independently verified against the live binaries.** The plan's final task — a `gate="blocking"` human-verify checkpoint — is still pending. Per this plan's `autonomous: false` status and the checkpoint protocol, this executor STOPS here and returns a structured checkpoint message rather than self-approving.

Everything the checkpoint's `<how-to-verify>` steps ask the human to confirm has already been mechanically exercised once this session (restart script, `walker -m menus:main`, glyph rendering, theming parity, Esc-survives-service) — the human pass is a second, independent confirmation layer, not a first look. `theme-engine/.config/theme-engine/contract.json` is confirmed byte-identical to `HEAD` (D-08 holds). `theme-parity` was not re-run this session (no theme-affecting files were touched) but nothing in this plan's diff touches any contract-tracked file, so it is not expected to be affected.

Once the human approves the checkpoint, this plan (07-01) is fully done and 07-02 (which repoints `$app_launcher_drun` to `walker -m runner`, fixing the pre-existing Super+R bug) can proceed — 07-02 already has its Task 1b amendment in place per commit `117edc9`.

---
*Phase: 07-super-key-menu*
*Completed: 2026-07-13 (Tasks 1-3; checkpoint pending)*

## Self-Check: PASSED

All claimed files verified present on disk: `elephant/.config/elephant/menus/main.toml`, `hypr/.config/hypr/scripts/elephant-restart.sh`, `walker/.config/walker/config.toml`, `stow.sh`.
All claimed commits verified present in `git log --oneline --all`: `4f2becb`, `6f4e4b2`, `117edc9`, `7adc2a2`, `e9c3a24`, `238095a`.
