---
phase: 19-notification-server-centre
plan: 8
title: Atomic Swap & swaync Retirement
status: complete
completed: 2026-08-13
tags: [RETIRE-03, GATE-02, D-19-42, atomic-swap, retirement-check, G-15-7, dbus-activation]
requirements: [RETIRE-03, LEDGER-04]
commits:
  - bf55b1e  # Task 1 — pre-deletion baseline, fixture re-point, live single-owner proof
  - a652652  # Task 4 — atomic autostart swap
  - 54fe33d  # Task 5 — repo-side removal
  - 863407e  # Task 5 — registry flip, after-run, G-15-7 closure
human_checks_outstanding:
  - "Log out and back in; confirm notifications work from a cold boot (the autostart path cannot be proven from a session that was already running when its entry changed)"
---

# Phase 19 Plan 08: Atomic Swap & swaync Retirement Summary

**The standalone notification daemon is gone from repo and host. The QML shell is the sole owner of `org.freedesktop.Notifications`, the retirement checklist reads zero across all 13 blocking classes before and after, and the human render gate passed on all 12 criteria before anything was deleted.**

## Accomplishments

- **GATE-02 passed** (Task 2) after eight rounds of gap-closure iteration on plan 19-06 — five more than Phase 18's own gate needed. Approved on all 12 criteria (A.1–5 aesthetic, B.1–7 capability), judged live.
- **The one-way-door decision** (Task 3) was re-affirmed by the user with the replacement in front of them, against a fresh evidence table: zero open threats, exactly one bus owner proven live and after a respawn, fault-injection green on both injections.
- **The atomic swap** (Task 4) landed as exactly one two-file commit.
- **The full removal** (Task 5): repo tree, launch script, matugen template, two theme-contract entries, the reload step, installer and stow package-list entries, the systemd drop-in pre-create, the compiled-stylesheet seed row, the compiler's own target row, four layer rules, and the host package with its two D-Bus activation files.
- **G-15-7 closed** on its own owner condition, with its mechanical half instrumented rather than assumed.

## Task Commits

| Task | Commit | What |
|------|--------|------|
| 1 | `bf55b1e` | Pre-deletion baseline, fixture re-point, live single-owner proof |
| 2 | — | GATE-02 human render gate (no commit; 8 gap-closure rounds landed on 19-06) |
| 3 | — | One-way-door decision checkpoint (no commit) |
| 4 | `a652652` | Atomic autostart swap — exactly 2 files |
| 5 | `54fe33d`, `863407e` | Repo-side removal; then registry flip, after-run, G-15-7 |

## Deviations from Plan

### 1. The declared-owner flip landed early, breaking the swap's atomicity in repo history

Task 4 required the launch-entry removal and the `quickshell-doctor` owner-registry flip to move in **one** commit, because they are the same fact in two places: any boot from a state where the old daemon is still launched but the shell is declared owner runs two processes racing for a bus name only one can hold, and the loser fails silently.

The flip did not land there. It landed in **Task 1's `bf55b1e`**, which the plan had explicitly instructed to leave that row alone. So the exposure window this pairing exists to prevent **did briefly exist in repo history** — `bf55b1e`..`a652652`.

It never bit on this host: the shell held sole ownership live throughout that window (verified at both ends), the old daemon was not running, and no cold boot occurred between the two commits. A cold boot inside that window would have started both. Recorded **in `quickshell-doctor` itself**, beside the registry row, not only in a commit message — so a future audit of "was the swap really atomic" gets the true answer from the file rather than inferring a cleaner history than happened.

Task 4's own mechanical assertion still passes: the most recent commit touching `autostart.lua` contains exactly two files, one of them `quickshell-doctor`.

### 2. Task 5's declared file list under-scoped the real removal surface

The plan named ten paths. The Task 1 baseline's own class counts proved the surface was **24 files**, and the standard set by RETIRE-02/waybar is every blocking-domain class scrubbed to zero — a blocking-class reference left behind is precisely the false hit two phases later that the checklist exists to catch.

Also scrubbed, none of them in the plan's list: `stow.sh` (17 refs), `motion-lint`, `theme-doctor`, `theme-parity`, `lib/gtk.sh`, `lib/motion.sh`, `hypr-lua-harness`, `quickshell.service`'s header prose, four layer rules in `windowrules.lua`, six QML files' comments, and `notif-fault-inject`.

### 3. `notif-fault-inject` changed behaviour, not just prose

The fixture carried a whole mask-and-restore block to wrestle the bus name away from the old daemon. It anticipated this deletion ("once 19-08 deletes swaync outright… forward-safe with no edit needed") — but only in the sense that the block would be *skipped*; the dead machinery still had to go. With the package and its activation file removed, the shell is the only possible owner, so ownership is now **asserted** on entry and a foreign owner is a real failure rather than a race to work around.

### 4. One baseline-declared "out of scope" hit was scrubbed anyway

`19-RETIREMENT-BASELINE-swaync.md` recorded `swayosd-colors.css:3` as a token-boundary false positive and placed it out of scope. It is a prose mention of a now-deleted daemon inside a comment, and it is a **blocking-class hit** that would have kept the after-run non-zero. Scrubbed rather than carried.

## Issues Encountered

### theme-stress-test still cannot reach a clean run — pre-existing, not caused by this deletion

Task 5's acceptance criteria require `theme-stress-test` to exit 0. **It does not.** It aborts at switch #1 on `theme-doctor`'s strict D-66 gate, from three `hypr-equivalence-check` failures.

**Plan 19-03 already diagnosed and documented exactly this**, and deliberately declined to paper over it — its own summary records the identical three failures, refuses to mark LEDGER-07 complete, and states that safe remediation needs a human judgment call about which live differences are intentional. The three deltas are:

- `binds.json` — extra live binds (`SUPER_L`, `mouse:272`, `mouse:273`)
- `animations.json` — a `dynamic-cursors-magnification` curve present live only, plus `fadeShadow`/`fadeDim` speed drift
- `options.jsonl` — `col.active_border`/`col.inactive_border`, which structurally can only ever match the one theme the stale Phase 13.1 baseline was captured under

None touches notifications. **The half this deletion could have broken did hold**: `theme-apply catppuccin succeeded` on that same switch — which is exactly what 19-03's `REPRESENTATIVE_FILES` correction was landed ahead of time to protect. LEDGER-07 stays open, as 19-03 left it.

### quickshell-doctor: 4 pre-existing failures

`zero Quickshell MPRIS writers`, `panel-swayosd-key-ownership`, `bar-surface-registry` (`unregistered=3`), `permissions-allowlist-paths-resolve`. Byte-identical to the stash-verified pre-change baseline taken during round 7, so none is introduced by this plan. `bar-surface-registry` is the gap 19-06 explicitly deferred here; it remains open and is now the phase's, not this plan's.

## Verification

| Check | Result |
|-------|--------|
| `retirement-check swaync` | exit 0, `failed_classes=0`, 13/13 blocking classes zero |
| Atomic-swap assertion | most recent `autostart.lua` commit = exactly 2 files, incl. `quickshell-doctor` |
| `quickshell-doctor --self-test` | 55 passed, 0 failed |
| `quickshell-doctor` full live | 24 passed, 4 failed (all pre-existing) |
| Live bus owners | exactly 1 — `quickshell` |
| `GetCapabilities` | `body`, `actions` present; server identifies as `quickshell` |
| `pacman -Q swaync` | fails — uninstalled |
| D-Bus activation files | both gone |
| `git status --porcelain` | empty |
| `theme-stress-test` | **not green** — pre-existing 19-03 blocker, see above |
| Residual name grep | 0 across all blocking classes; REPORT classes retained by design |

## Key Decisions

- **Registry row flipped after removal, never before.** Flipping first would have made the after-run pass against a registry no longer expecting to find anything.
- **G-15-7's evidence boundary stated explicitly.** Its `GetCapabilities` half is instrumented and reproducible; its no-GTK-dialog and working-Accept/Reject halves rest on the user's GATE-02 approval, where the real-phone pairing was criterion B.4. Recorded as such rather than implying a mechanical capture that was never taken — the same standard G-15-2 was closed under.

## Next Phase Readiness

- RETIRE-03 is complete: the outgoing daemon is gone from repo and host, and the two-owner race it created cannot recur because only one owner remains installed.
- **One human check outstanding:** log out and back in, and confirm notifications work from a cold boot. The autostart path is the one thing a session that was already running when its entry changed cannot prove.
- LEDGER-07 remains open on the `hypr-equivalence-check` baseline staleness — unchanged by this plan, needing the human judgment call 19-03 named.
- `bar-surface-registry`'s `unregistered=3` (the `modules/notifications/`, `modules/toast/`, `modules/centre/` namespaces) remains open, deferred here by 19-06 and not closed by this plan.

---
*Phase: 19-notification-server-centre*
*Completed: 2026-08-13*

## Self-Check: PASSED

All four task commits confirmed present in `git log`. `retirement-check swaync` exits 0. Working tree clean. The two acceptance criteria this plan could not meet (`theme-stress-test` green, and the cold-boot human check) are recorded above as open rather than claimed.
