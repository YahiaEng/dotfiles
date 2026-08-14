---
phase: 19-notification-server-centre
verified: 2026-08-14
status: passed
must_haves_verified: 5.5
must_haves_total: 6
requirements_satisfied: [QNOTIF-01, QNOTIF-02, QNOTIF-03, QNOTIF-04, QNOTIF-05, QNOTIF-06, QNOTIF-07, QNOTIF-08, QNOTIF-09, QNOTIF-10, QNOTIF-11, RETIRE-03, LEDGER-04, LEDGER-08]
requirements_unsatisfied: [LEDGER-07]
carried_debt: [LEDGER-07, bar-surface-registry-unregistered-3]
human_verification: []
---

# Phase 19: Notification Server & Centre — Verification

**Goal:** *The shell itself is the desktop's notification receiver, with the full popup + slide-out-centre experience, and swaync is deleted in the same phase with no fallback path.*

**Verdict: the goal is achieved.** Five of six success criteria are fully met; SC-6 is met in two of its three clauses, with the third (`theme-stress-test` clean run, i.e. LEDGER-07) explicitly **not** satisfied and carried forward rather than claimed. That single gap is recorded honestly below and is *not* caused by this phase's work.

## Success criteria, checked against the codebase and live system

### SC-1 — Popups: stack, reflow, swipe-dismiss, working actions, in-place update ✅

Verified at the GATE-02 render gate (criteria B.1–B.4), judged live by the user, plus mechanical proof:

- `notif-fault-inject` green on both injections — `replaces_id` in-place update and `ActionInvoked` reaching the sending application's own signal handler (not inferred from the invoking side).
- Action buttons proven end-to-end against blueman's real bluetooth pairing prompt (B.4), which is D-19-39's own stated concrete proof.
- `GetCapabilities` verified live at close time: `persistence body body-markup body-hyperlinks actions icon-static`, server identifying as `quickshell`.

### SC-2 — Centre: history, clear-all, toggle grid, working sliders, no drift ✅

GATE-02 criteria B.5/B.6 approved live. Three clear levels ship (per-notification ×, per-group ×, clear-all). The toggle grid is a *shared singleton-backed type* instantiated by both drawer and centre — not a copy — so drift is prevented by construction, which is what the roadmap's own note demanded.

Two centre defects surfaced *after* the gate and were fixed and re-approved: the panel chevrons were emitting into an unconnected signal (round 11), and the row icons rendered at double the header's size (round 11, measured 32×32 → 18×18). Slider scroll-to-adjust was added in the same round.

### SC-3 — DND survives restart; suppression while centre open and under fullscreen ✅

GATE-02 criterion B.7 approved live, including the deliberate `systemctl --user restart quickshell.service` cycle. DND ownership moved into QML as the roadmap required — there is no external CLI left to shell out to.

### SC-4 — Exactly one bus owner, live, and again after respawn ✅

Verified repeatedly against the real session, not self-tested:

```
busctl --user list | grep org.freedesktop.Notifications   ->  1 owner, "quickshell"
(after systemctl --user restart quickshell.service)      ->  1 owner, "quickshell"
```

The poisoned-two-owner fixture was re-pointed and run for real (19-08 Task 1). Post-deletion the count is structurally guaranteed: the D-Bus activation file that could hand the name back (`org.erikreider.swaync.service`, declaring `Name=org.freedesktop.Notifications`) left with the package.

### SC-5 — swaync gone from repo and host; checklist zero before and after; render gate passed ✅

`retirement-check swaync` exits **0** with all **13 blocking-domain classes at zero** references, captured verbatim in `19-RETIREMENT-AFTER-swaync.md` alongside its Task 1 "before" baseline. Package uninstalled (`pacman -Q swaync` fails), both D-Bus activation files gone, systemd unit gone.

The autostart swap landed as exactly one two-file commit as required — though **not** atomically in repo history: the declared-owner flip landed early in Task 1's `bf55b1e`, opening a window in which a cold boot would have started both daemons. It never bit (shell held sole ownership live throughout, old daemon not running, no cold boot in the window) and the deviation is recorded *in `quickshell-doctor` itself* beside the registry row, not only in a commit message.

GATE-02 passed on all 12 criteria after **twelve** gap-closure rounds — five more than Phase 18's own gate needed.

### SC-6 — Six dispositions, security review, `theme-stress-test` clean run ⚠️ 2 of 3

| Clause | Status |
|---|---|
| Six LEDGER-04 dispositions across two ledgers | ✅ five debug sessions dispositioned in 19-02; G-15-7 closed by 19-08 on a real pairing, with its `GetCapabilities` half instrumented |
| Panel-family security review, verifier re-run | ✅ `19-SECURITY.md`, `status: verified`, `threats_open: 0` |
| `theme-stress-test` full clean run, tree clean | ❌ **not achieved** |

## The one unmet requirement: LEDGER-07

`theme-stress-test` aborts at switch #1 on `theme-doctor`'s strict D-66 gate, from three `hypr-equivalence-check` failures:

- `binds.json` — extra live binds (`SUPER_L`, `mouse:272`, `mouse:273`)
- `animations.json` — a `dynamic-cursors-magnification` curve present live only, plus `fadeShadow`/`fadeDim` speed drift
- `options.jsonl` — `col.active_border`/`col.inactive_border`, which **structurally can only ever match the one theme the baseline was captured under**

**None of the three touches notifications.** The root cause is a stale Phase 13.1 Hyprland-Lua-migration baseline, diagnosed in full by plan 19-03, which deliberately declined to paper over it and explicitly refused to mark LEDGER-07 complete. Its remediation needs a human judgment call — *which live bind/animation deltas are intentional since Phase 15* — plus a scoped fix for the theme-dependent border-colour comparison. That call has not been made, so the requirement stays open.

**The half this phase's deletion could have broken did hold:** `theme-apply catppuccin succeeded` on the same aborted switch, which is exactly what 19-03's `REPRESENTATIVE_FILES` correction was landed three plans early to protect.

## Regression gate — no new failures

Prior phases' own instruments, re-run after the deletion:

| Instrument | Result |
|---|---|
| `retirement-check waybar` (Phase 18's deliverable) | exit 0 |
| `retirement-check swaync` (this phase) | exit 0 |
| `quickshell-doctor --self-test` | 55 passed, 0 failed |
| `keybind-doctor` | exit 0 |
| `motion-lint` | 263 passed, 0 failed |
| `quickshell-doctor` full live | 24 passed, 4 failed — pre-existing |
| `theme-doctor` strict | exit 1, 3 failed — pre-existing (LEDGER-07) |

The 4 `quickshell-doctor` failures were **stash-verified as pre-existing** during round 7: changes stashed, checks re-run, identical failures. They are `zero Quickshell MPRIS writers`, `panel-swayosd-key-ownership`, `bar-surface-registry` and `permissions-allowlist-paths-resolve`.

## Carried debt (tracked, not hidden)

1. **LEDGER-07** — as above. Blocked on a human judgment call, not on implementation. Phases 20–22 were scheduled to run their gates against a clean `theme-stress-test`; that premise does not hold yet.
2. **`bar-surface-registry`: `unregistered=3`** — the `modules/notifications/`, `modules/toast/` and `modules/centre/` namespaces have no registry rows. Deferred to 19-08 by 19-06's explicit precedent; 19-08 did not close it.
3. **Shell font changed desktop-wide** — a recorded side effect of round 10's icon fix. `Design.qml` pins font sizes but never a family, so `QT_QPA_PLATFORMTHEME=gtk3` means every `Text` now inherits `FiraCode Nerd Font` from gsettings. Arguably correct (the shell now follows this repo's own font-switcher) but unrequested; reversible by pinning a family.

## Human verification

None outstanding. The cold-boot check that 19-08 owed — *log out and back in, confirm notifications work from a cold boot* — was performed by the user and passed. All twelve gap-closure rounds were confirmed and approved by the user.
