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
