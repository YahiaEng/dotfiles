# Deferred Items — Phase 12

Out-of-scope discoveries logged during plan execution per the executor's scope-boundary
rule (fix only what the current task's changes directly caused; log everything else here
without touching it).

## 12-03

- **Untracked stray file makes `theme-doctor`'s CLEAN-02 git-clean check FAIL, unrelated to
  this plan.** `vscodium/.local/share/applications/Vampire Survivors.desktop` is untracked
  in the dotfiles repo and was already present (per `git status --porcelain`) before this
  plan's execution began — confirmed via `git log --diff-filter=A` returning no commit that
  ever added it. It is not created, modified, or referenced by any of plan 12-03's three
  tasks. Its presence means `theme-doctor`'s `git status --porcelain is empty` check reports
  `[FAIL]` (140 passed / 1 failed) even though every check this plan is responsible for is
  green. Not fixed here per the scope-boundary rule — a desktop-entry file for an unrelated
  application is out of scope for a design-token-pipeline plan. Whoever owns this file
  should either commit it (if intentional) or delete it (if accidental) to restore
  `theme-doctor`'s git-clean invariant to a genuine PASS.

## 12-02

- **`quickshell-doctor` still exits 1 (`12 passed, 1 failed`) after Task 3's D-14 SKIP fix,
  not the `13 passed, 0 failed` the plan's acceptance criteria expected.** The remaining
  `[FAIL]` is the pre-existing `one-step-per-press volume probe` gate brittleness — an
  over-strict exact-match on rounding-sensitive raw PulseAudio units, first surfaced during
  12-01's Task 2 session-restart re-proof, confirmed there as unrelated to any file 12-01 or
  12-02 modified (`quickshell-doctor` was last content-changed by Phase 11 commits before
  12-02's Task 3 diff), and already filed as
  `.planning/todos/pending/quickshell-doctor-volume-probe-brittle.md`. Task 3's own scope —
  the per-screen surface creation check — is verified working exactly as designed: it now
  prints a `[SKIP]` line carrying both the reason and the evidence pointer, contributes
  neither to `PASS` nor `FAIL`, and toggling `QS03_ACCEPTED_PERMANENT` back to `0` restores
  the original failing check verbatim (confirmed and reverted during this task). Not
  re-fixed here per scope discipline — the plan's `files_modified` list is
  `hypr/.config/hypr/scripts/quickshell-doctor` for the per-screen SKIP only, and the
  volume-probe brittleness is a separate, already-tracked, pre-existing bug.
