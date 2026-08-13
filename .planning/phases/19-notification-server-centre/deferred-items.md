# Phase 19 — Deferred Items

## 1. `hypr-equivalence-check` blocks a full `theme-stress-test` clean run — pre-existing, from Phase 15 (compounded since)

**STATUS: OPEN, not caused by 19-03.**

**Found during:** 19-03 Task 3's live full run of `theme-stress-test` (the harness
LEDGER-07 asks this plan to get to a clean exit).

**Symptom:** `theme-stress-test` aborts at switch #1 with `[FAIL] switch #1:
theme-doctor passes (strict exit 0, D-66)`. `theme-doctor` itself reports
`443 passed, 3 failed` — all three failures are `hypr-equivalence-check`'s three
sub-checks (`binds.json`, `animations.json`, `options.jsonl`), nothing else.

**Root cause, part A (fixed by 19-03 as a Rule 3 deviation):** the committed
`.hypr-baseline/` moved from `.planning/phases/13.1-hyprland-lua-config-migration/`
to `.planning/milestones/v3.0-phases/13.1-hyprland-lua-config-migration/` when the
v3.0 milestone was archived (commit `cf26332`). `hypr-equivalence-check`'s
`DEFAULT_BASELINE_DIR` never tracked that move, so every check-mode run since the
archive hit D-10's "absent baseline is a FAIL, never a SKIP" path — reporting
FAIL for a reason that had nothing to do with whatever the live config actually
diverges on. **Fixed** (commit `37249ea`): the script now prefers the live
`phases/` location and falls back to the archived `milestones/` location.

**Root cause, part B (NOT fixed — out of scope for 19-03):** once the path
pointed at real baseline data, the check reveals genuine content divergence
already tracked as long-standing debt:

- This exact issue (baseline drift from accumulated keybind/animation changes)
  was first documented in `.planning/milestones/v3.0-phases/15-audio-connectivity-panels/deferred-items.md`
  item 1 (Phase 15, Super+A keybind) and partially remediated twice via a
  **surgical single-record baseline insertion** (never a wholesale re-snapshot —
  see 14-10-SUMMARY.md and STATE.md's 16-04 entry) — the established, low-risk
  precedent for this exact class of fix.
- Three more phases (16, 17, 18) of legitimate Hyprland keybind/animation work
  have landed since the last surgical update, so `binds.json` now shows a
  `SUPER_L`/`mouse:272`/`mouse:273` ordering + `release` field divergence the
  comparator itself cannot cleanly resolve ("duplicate bind identity in live...
  cannot pair records unambiguously"), and `animations.json` shows one new
  legitimate curve (`dynamic-cursors-magnification`, Phase 17/AMB-02).
- **New structural finding this session:** `options.jsonl`'s
  `general:col.active_border`/`col.inactive_border` checks fail because the
  committed baseline was captured under one specific theme's border-gradient
  colors, and the live session was running a different theme at compare time.
  Border colors are theme-dependent by design (they change on every switch) —
  this means the comparison can **only ever pass for the one theme the
  baseline happened to be captured under**, so `theme-stress-test`'s own
  10-switch multi-theme rotation can never pass this sub-check even after a
  fresh, fully-in-sync re-baseline, unless the comparator gains a theme-aware
  exemption/normalization for these two fields (mirroring the existing
  bool-vs-int type-normalization it already does for other options).

**Why not fixed in 19-03:** the safe fix pattern for part B is a field-by-field
surgical baseline amendment requiring domain judgment about which of the
`binds.json` differences are intentional (the `release` field looks directly
tied to Phase 7's "bare SUPER-tap opens the menu" behavior — getting this wrong
risks silently blessing a real regression in a load-bearing UX feature), plus
an architectural decision about the border-color comparator (whether to exempt,
normalize, or restrict `hypr-equivalence-check` to running only when the live
theme matches the baseline's). Both are Rule 4 (architectural) territory, well
outside a wallpaper-pointer-relocation plan's remit, and the border-color
finding specifically needs its own scoped investigation.

**Suggested fix (future plan):** (1) surgical single-record/field
`binds.json`/`animations.json` amendment following the 14-10/16-04 precedent,
with the `SUPER_L` release-field divergence specifically checked against
Phase 7's tap-menu keybind before being blessed; (2) a theme-aware exemption or
normalization for `col.active_border`/`col.inactive_border` in the
`options.jsonl` comparator, or an explicit decision to run
`hypr-equivalence-check` only under one canonical theme.

**Evidence D-19-45/D-19-46 are correct independent of this blocker:** see
`19-03-SUMMARY.md` — five consecutive direct `theme-apply` invocations
(dracula, materialyou, gruvbox, materialyou again, catppuccin) all left
`git status --porcelain` empty, the pointer resolved to a real file at
`~/.local/state/theme/current.jpg` every time, and the pointer specifically
survived a materialyou-to-materialyou re-apply's `commit.sh` `rsync --delete`
(the exact scenario the `contract.json` `engine_owned_files` fix protects
against).

**Tracked in:** WINDOWS.md ledger entry #71.
