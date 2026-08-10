---
status: resolved
phase: 12-unified-design-token-pipeline
source: [12-VERIFICATION.md]
started: 2026-07-27T02:35:00Z
updated: 2026-07-27T02:45:00Z
---

## Current Test

number: 1
name: Run the committed theme-stress-test end to end (10 consecutive theme switches)
expected: |
  10/10 switches pass with zero failures, matching the scratch-copy proof already
  recorded in 12-06-SUMMARY.md (162 passed / 0 failed, quickshell PID unchanged
  across all 10 switches).
awaiting: none — run and resolved

## Tests

### 1. Committed theme-stress-test, end to end

expected: 10/10 switches pass with zero failures; 162 passed / 0 failed; quickshell PID unchanged across all 10 switches
result: **partial — 4/10 switches passed, aborted at switch #5; root cause identified as pre-existing Phase 03 debt, not a Phase 12 defect**

command: `theme-engine/.config/theme-engine/theme-stress-test`
run_at: 2026-07-27T02:39Z
log: `~/.local/state/theme/logs/stress-20260726T233920Z.log`

**What passed (real script, not the scratch copy):** switches 1-4 completed in full —
`catppuccin`, `materialyou`, `catppuccin-latte`, `materialyou-light`. Every per-switch
assertion held, including the D-17 live re-colour check (quickshell's `Colours.primary`
matched the freshly-rendered `palette.json` on each switch), the quickshell daemon PID
remaining unchanged (1218846 throughout), sentinel-colour propagation into all six render
targets, and walker/elephant health.

**What failed:** switch #5 (`dracula`) failed the D-66 strict `theme-doctor` gate.

**Root cause — pre-existing, not Phase 12.** Three pieces collide:
1. `theme-engine/.config/theme-engine/lib/wallpaper.sh:65` repoints
   `wallpapers/Pictures/Wallpapers/current.jpg` with `ln -sfr` on every *static* theme switch.
2. That symlink is *tracked* in git, committed pointing at `catppuccin/5-alien-planet.jpg`.
3. `theme-doctor` asserts `git status --porcelain` is empty (added 90f73c2, phase 03-03) and
   `theme-stress-test` requires a strict `theme-doctor` pass after every switch (1a4ce30,
   phase 03-03).

Any switch to a static theme whose wallpaper differs from the committed target therefore
dirties a tracked file and fails the gate. Confirmed by mechanism rather than inference:
switching back to `catppuccin` repointed the symlink to its committed target and the tree
went clean again. Phase 12 never touched `wallpaper.sh`.

**Correction to the prior record.** WINDOWS.md #9 previously predicted the real script would
"pass identically" once the untracked vscodium file was resolved. That prediction was wrong,
and the earlier scratch-copy 10/10 was weaker evidence than it appeared — it passed precisely
because it bypassed this check. WINDOWS.md #9 has been rewritten with the real root cause and
two concrete fix options, deferred to Phase 13 (the designated existing-surface sweep) by
user decision at Phase 12 close.

**Why this does not block Phase 12.** Criterion 1's live re-colour claim is independently
confirmed twice: by the 12-06 D-27 human render gate (a real `theme-apply catppuccin-latte`
crossfade observed live with the panel staying open) and now by switches 1-4 of this run
against the *real* committed script — which is stronger evidence than the phase previously
had, not weaker.

**State restored:** theme returned to `catppuccin`, working tree clean, `theme-doctor` 180/0.

## Summary

total: 1
passed: 0
issues: 1
pending: 0
skipped: 0
blocked: 0

## Gaps

### 1. theme-stress-test cannot reach 10/10 while current.jpg is a tracked symlink
status: deferred
owner: Phase 13 (existing-surface sweep)
severity: low — does not affect Phase 12's delivered functionality; affects only the
  reachability of one pre-existing reliability harness's full-run assertion
detail: see WINDOWS.md #9 for root cause and the two fix options (untrack current.jpg plus
  add fresh-install seeding to stow.sh, since it is not currently seeded there; or narrowly
  exempt that one path from theme-doctor's clean-tree invariant as runtime state)
