---
phase: 07-super-key-menu
plan: 01
subsystem: launcher
tags: [walker, elephant, hyprland, gtk4, dmenu]

# Dependency graph
requires:
  - phase: 06-themed-surfaces-utility-suite
    provides: CLI-invokable utility scripts, walker-style.css contract target #18
provides:
  - "Empirical proof the elephant `menus` provider (2.21.0) correctly loads TOML menu definitions, registers `menus:<name>` providers, expresses submenus, actions, and Nerd Font glyph-as-text entries"
  - "Empirical proof walker's `menus` drill-down and Esc back-navigation work correctly when invoked via `-m <provider>` (exclusive-provider mode)"
  - "A newly discovered, reproducible walker 2.16.2 defect: `walker -s <name>` (named 'sets', GUI/non-dmenu mode) panics and aborts the ENTIRE walker gapplication-service — including the pre-existing, currently-bound `-s runner` — blocking the plan's chosen `[sets.menu]` invocation mechanism"
affects: [07-02-elephant-stow-package, 07-03-walker-sets-menu, 07-04-super-tap-bind, 07-05, 07-06, 07-07, 07-08]

tech-stack:
  added: []
  patterns: []

key-files:
  created: []
  modified: []

key-decisions:
  - "D-05 core question (does the elephant `menus` provider express submenus/actions/glyphs) resolves GO — proven live via `-m menus` GUI invocation with screenshot evidence"
  - "D-06 (Esc/Backspace one-level-back) resolves GO via Escape — proven live with screenshot evidence (drill-down in, Escape back to parent, Escape again closes entirely)"
  - "NEW BLOCKER (not anticipated by RESEARCH.md/07-PATTERNS.md): `walker -s <name>` in GUI mode is broken on the installed walker 2.16.2 binary — reproduced 5 times across independent contexts, including on the pre-existing untouched `[sets.runner]` block. This is the exact mechanism Task 3/07-04 and RESEARCH.md's own code example (`bindr = ..., exec, uwsm app -- walker -s menu`) assume works. Plan execution STOPPED per the plan's own explicit escalation mandate rather than silently substituting an alternative invocation mechanism (Rule 4 — architectural decision, requires human/orchestrator input)."

patterns-established: []

requirements-completed: []  # MENU-01 NOT completed — plan escalated after Task 1, Tasks 2-4 not executed

coverage: []

# Metrics
duration: ~30min
completed: 2026-07-13
status: blocked
---

# Phase 7 Plan 01: D-05 Spike — Elephant Menus Provider Summary

**D-05 spike proves the elephant `menus` provider itself works (submenus/actions/glyphs/back-nav all confirmed live via `-m menus`), but surfaces a NEW, unanticipated blocker: `walker -s <name>` (the exact GUI-mode invocation this plan and RESEARCH.md assumed) panics and kills the walker daemon — plan execution stopped after Task 1 for architectural decision, Tasks 2-4 NOT executed.**

## Performance

- **Duration:** ~30 min
- **Completed:** 2026-07-13T14:41:17Z
- **Tasks:** 1 of 4 executed (Task 1 only — investigative, escalated)
- **Files modified:** 0 (all spike artifacts created and then fully cleaned up per Task 1's own instructions; net repo diff is zero)

## What Happened

Per this plan's `<critical_context>` mandate, Task 1 (D-05's mandatory spike) was executed for real against the installed `elephant 2.21.0` + `walker 2.16.2` binaries on the live Hyprland session (not simulated — this machine has a real active graphical session, confirmed via `hyprctl monitors`/`hyprctl clients` showing genuine open windows). Screenshots were captured with `grim` and read visually; synthetic key events were sent with `wtype`.

### Spike procedure (as specified by the plan)

1. Created throwaway `~/.config/elephant/menus/spike-root.toml` (two entries: one leaf with a Nerd Font glyph U+F0AD `nf-fa-wrench` in `text` + a `notify-send` action, one `submenu = "spike-child"`) and `spike-child.toml` (`parent = "spike-root"`, one leaf entry), directly on the host, NOT in the repo.
2. Restarted elephant (`pkill -x elephant` → `uwsm app -- elephant`). `elephant listproviders` confirmed BOTH `menus:spike-root` and `menus:spike-child` registered.
3. Added a temporary `[sets.spike]` block to `walker/.config/walker/config.toml` (`providers = ["menus:spike-root"]`) to test Open Question 1, mirroring `[sets.runner]`'s exact shape as instructed.
4. Restarted walker and attempted `walker -s spike` (GUI mode) — **this crashed the entire walker service** (see Finding 3 below). Diagnosed and worked around this by using `walker -m menus` (exclusive-provider mode) instead, which does NOT crash and DOES render the spike menu content, allowing the rest of the spike (drill-down, glyph rendering, back-navigation) to be verified visually.
5. Deleted both spike TOML files, removed the `[sets.spike]` block (git diff on `walker/.config/walker/config.toml` confirmed byte-identical to the pre-spike original), restarted elephant + walker to a clean healthy baseline (`elephant listproviders` back to the original 8 non-menu providers, `~/.config/elephant` removed entirely).

### Finding 1 — D-05 core question: GO

`walker -m menus` (GUI, non-dmenu) rendered a real walker window showing both spike-root entries ("Spike Child", "Spike Leaf" — alphabetically sorted since `fixed_order` wasn't set). The wrench glyph (U+F0AD) rendered as an actual glyph character, not a tofu box — **D-07 confirmed visually** (screenshot: `/tmp/spike-screenshot-2.png`, captured mid-render).

Pressing `Return` on the highlighted "Spike Child" entry swapped the SAME window's list to show "Spike Child Leaf" — the child menu's only entry, with a visible "back" button in the bottom-left action bar and a "notify" (F1) action-hint pill for the entry's bound action. **This directly confirms Open Question 1's underlying mechanism: the elephant `menus` provider's submenu/drill-down protocol works correctly and swaps content in-place, exactly as RESEARCH.md's `ProviderUpdated` mechanism describes** (screenshot: `/tmp/spike-after-enter.png`).

### Finding 2 — D-06: Esc navigates back exactly one level (GO)

From the child-menu state above, pressing `Escape` (via `wtype -k Escape`) swapped the list BACK to spike-root's two entries (screenshot: `/tmp/spike-after-escape.png`) — confirming **Esc performs exactly the one-level-back navigation D-06 requires**, not a full close. A second `Escape` press from the root level closed the window entirely (layer-shell surface unmapped, confirmed via `hyprctl layers -j` showing zero `walker` namespace entries and a follow-up screenshot showing no overlay) — matching 07-UI-SPEC.md's exact "Esc from the root level closes the menu entirely" contract.

**Definitive answer for the SUMMARY, as the plan requires:** Esc performs one-level-back navigation from any non-root menu, and closes the menu entirely from the root level. No explicit walker keybind config addition is required for this — it is native `menus`-provider behavior.

### Finding 3 — NEW BLOCKER: `walker -s <name>` (GUI mode) crashes the walker daemon

While answering Open Question 1 exactly as instructed (add `[sets.spike]`, invoke `walker -s spike`), the walker gapplication-service **panicked and aborted**:

```
thread 'main' (PID) panicked at src/data.rs:566:18:
can't find specified set
thread 'main' (PID) panicked at .../panicking.rs:225:5:
panic in a function that cannot unwind
thread caused non-unwinding panic. aborting.
```

This is **not** a spike-content problem — it was reproduced identically and deterministically 5 times, including against the **pre-existing, completely untouched** `[sets.runner]` block (the exact set already shipped in `walker/.config/walker/config.toml` and currently bound to `Super+R` in production `keybinds.conf`):

| # | Invocation | Context | Result |
|---|---|---|---|
| 1 | `walker -s spike` | fresh service, backgrounded | Service panics + aborts |
| 2 | `walker -s runner` | fresh service, backgrounded, `--dmenu` NOT used | Service panics + aborts (identical trace) |
| 3 | `walker -s runner` | service given 10s to fully init first (rules out a startup race) | Service panics + aborts |
| 4 | `walker -s runner` | foreground, `timeout 5` | Client exits 0, service still dies |
| 5 | `walker -s runner` | **no pre-existing service at all** (standalone) | Client itself panics, dumps core, exit 134 |

Control tests that do NOT crash: `walker -s spike --dmenu -e` (dmenu mode), `walker -s runner --dmenu -e` (dmenu mode), `walker -m menus` (exclusive-provider mode, GUI), plain `walker` (default set, GUI). The crash is isolated specifically to **GUI-mode (non-`--dmenu`) invocations carrying a `-s`/`--set` argument**, regardless of which provider(s) the set targets.

**Why this blocks the plan as written:** RESEARCH.md's Pattern 1 code example and this plan's own Task 3/07-04 architecture both invoke the menu via `walker -s menu` (`bindr = $mainMod, SUPER_L, exec, uwsm app -- walker -s menu`), and RESEARCH.md asserted `-s runner` "already ships and works in this repo today" as load-bearing prior art for Open Question 1 — an assumption this spike falsifies empirically. Wiring `[sets.menu]` (Task 3) and binding it to the Super-tap key (07-04) would ship a mechanism proven to crash the desktop's launcher daemon on first use.

**What does NOT resolve this cleanly within Task 1's scope:** the plan's own STOP clause is written narrowly ("if the provider CANNOT express submenus or actions at all... fall back to bash + `walker --dmenu`"). That condition is false — the provider works fully. What's broken is walker's own `-s` argument handling, a level up from the provider. Substituting `-m menus:main` (which this spike confirms does NOT crash and DOES render/drill-down correctly) is a plausible fix, but it is an architectural change to the invocation mechanism specified across Task 3, 07-04, and implicitly 07-05..07-08 (all of which assume `[sets.menu]`/`walker -s menu`) — exactly the class of decision Rule 4 reserves for human/orchestrator judgment, not silent executor substitution.

## Decisions Made

- Did not improvise a fix for the `-s` crash (e.g., silently switching Task 3 to `-m menus:main`) — that is an architectural change affecting every remaining Phase 7 plan and is outside this task's authorized scope per the plan's own "do not silently improvise a hybrid" instruction and Rule 4.
- Did not proceed to Task 2 (elephant stow package) or Task 3 (`[sets.menu]` + `elephant-restart.sh`) because Task 3's explicit deliverable (`[sets.menu]` wired for `walker -s menu`) would knowingly ship a mechanism proven broken by Task 1's own evidence — "do not proceed to build on a broken foundation."
- Task 4 (the human-verify checkpoint) was not reached.
- Left the live session in a clean, healthy state: no spike files remain on disk, `walker/.config/walker/config.toml` is byte-identical to its pre-spike state (`git diff` confirms zero changes), and both `elephant` and `walker --gapplication-service` were restarted and verified healthy (`elephant listproviders`, `pgrep`) before finishing, so the desktop's actual launcher (Super key / `$app_launcher`, which does NOT use `-s`) is left fully functional for the user.

## Deviations from Plan

### Escalated (not auto-fixed — Rule 4)

**1. [Rule 4 - Architectural] `walker -s <name>` GUI-mode crash blocks the plan's chosen invocation mechanism**
- **Found during:** Task 1, while answering Open Question 1 exactly as instructed
- **Issue:** `walker -s menu` (the mechanism Task 3/07-04/RESEARCH.md all assume) crashes the walker daemon on the installed 2.16.2 binary — reproduced 5x, including on the pre-existing `-s runner` set
- **Not fixed:** requires a human/orchestrator decision between at least three paths: (a) switch the whole phase's invocation mechanism from `[sets.X]`/`-s` to `-m menus:<name>` (exclusive-provider mode, confirmed working), (b) fall back to the bash + `walker --dmenu` chain per D-05's documented fallback, (c) investigate/report the walker bug upstream and pin/upgrade the binary. None attempted — outside Task 1's authorized scope.
- **Files modified:** none (spike files fully cleaned up)
- **Verification:** 5 independent reproductions, screenshotted evidence for the working `-m menus` alternative path

---

**Total deviations:** 1 escalated (0 auto-fixed)
**Impact on plan:** Plan execution stopped after Task 1. Tasks 2-4 not executed. No code committed (repo diff is zero). MENU-01 requirement NOT completed.

## Issues Encountered

See Finding 3 above — the walker `-s` GUI-mode crash is the central issue of this session.

## Evidence Artifacts (not committed — host-local, referenced for reviewer convenience)

- `/tmp/spike-screenshot-2.png` — spike-root menu open via `-m menus`, wrench glyph visible, no tofu box
- `/tmp/spike-after-enter.png` — drill-down into spike-child after Enter on the submenu entry
- `/tmp/spike-after-escape.png` — Escape navigates back to spike-root (one level, not a full close)
- `/tmp/spike-after-escape2.png` — second Escape closes the menu entirely from root level
- `/tmp/elephant-spike.log`, `/tmp/walker-spike.log`, `/tmp/walker-spike2.log`, `/tmp/walker-spike3.log`, `/tmp/walker-spike4.log`, `/tmp/walker-fg-test.log`, `/tmp/walker-wait-test.log` — full panic traces from each reproduction

## Next Phase Readiness

**NOT ready to proceed to Task 2/3/4 of this plan, nor to plans 07-02 through 07-08, without a decision on Finding 3.** The underlying elephant `menus` provider is proven sound (D-05/D-06/D-07 all GO) — the blocker is narrowly scoped to walker's `-s`/`--set` GUI-mode argument handling. Recommended next step: route this finding back through the orchestrator/human for an architectural decision (most likely candidate: adopt `-m menus:main` in place of `[sets.menu]`/`walker -s menu` throughout Task 3, 07-04, and any later plan that references the `-s menu` invocation — this spike already confirms `-m menus:main`-style exclusive-provider mode works end-to-end for both root rendering and drill-down), then resume this plan from Task 2.

---
*Phase: 07-super-key-menu*
*Completed: 2026-07-13 (escalated after Task 1)*
