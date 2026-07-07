---
phase: 02-static-dynamic-parity-switch-reliability
plan: 02-02
verified: 2026-07-08T01:34:00+03:00
status: passed
gate: D-41 clean full gate
human_signoff: approved
---

# Phase 2 Plan 02: Repeated-Switch Reliability (PIPE-06) — Verification Report

**Objective proven:** A fresh, uninterrupted 10-switch alternating static↔dynamic run with Thunar and Walker open completes with zero per-switch failures, `theme-parity` is all-green immediately after, and a human visually confirmed switch #10 is correctly themed across every visible app.

## D-41 Clean Full Gate — Evidence

The gate requires BOTH of the following in one uninterrupted sequence (no stitched/resumed runs):

1. A fresh `theme-stress-test` run (default: 10 switches, alternating static↔dynamic, 3–5s settle gap) completes with **zero failures**.
2. `theme-parity` (from Plan 02-01) is **all-green** immediately after.

### 1. Stress run — `~/.local/state/theme/logs/stress-20260707T222706Z.log`

Tail of the passing run (switch #10 + postconditions):

```
PASS	switch=9	theme=rosepine	switch #9: elephant listproviders responds
PASS	switch=10	theme=materialyou	switch #10: theme-apply materialyou succeeded
PASS	switch=10	theme=materialyou	switch #10: theme-doctor passes (no new failures beyond the accepted elephant-provider gap)
PASS	switch=10	theme=materialyou	switch #10: sentinel color extracted for materialyou
PASS	switch=10	theme=materialyou	switch #10: sentinel (cfbdfe) present in hyprland.conf (normalized)
PASS	switch=10	theme=materialyou	switch #10: sentinel (cfbdfe) present in waybar.css (normalized)
PASS	switch=10	theme=materialyou	switch #10: sentinel (cfbdfe) present in swaync.css (normalized)
PASS	switch=10	theme=materialyou	switch #10: sentinel (cfbdfe) present in wlogout.css (normalized)
PASS	switch=10	theme=materialyou	switch #10: sentinel (cfbdfe) present in gtk-4.0-colors.css (normalized)
PASS	switch=10	theme=materialyou	switch #10: sentinel (cfbdfe) present in kitty.conf (normalized)
PASS	switch=10	theme=materialyou	switch #10: walker process running
PASS	switch=10	theme=materialyou	switch #10: walker bus-name (dev.benz.walker) registered
PASS	switch=10	theme=materialyou	switch #10: elephant process running
PASS	switch=10	theme=materialyou	switch #10: elephant listproviders responds
PASS	switch=post	theme=materialyou	postcondition: Thunar window still open
PASS	switch=post	theme=materialyou	postcondition: walker process still running
PASS	switch=post	theme=materialyou	postcondition: walker bus-name (dev.benz.walker) still registered
PASS	switch=post	theme=materialyou	postcondition: elephant process still running
PASS	switch=post	theme=materialyou	postcondition: elephant listproviders still responds
SUMMARY	140 passed, 0 failed
```

**Result: 140 passed, 0 failed.** All 10 switches (alternating static↔dynamic across catppuccin/dracula/gruvbox/nord/rosepine presets interleaved with materialyou) passed every per-switch check: `theme-doctor` exit 0, format-normalized sentinel-color match (including the Pitfall-1 `hyprland.conf` `rgba(RRGGBBAA)` case), and walker+elephant liveness with D-Bus bus-name registration. Pre/postconditions (Thunar window open, walker/elephant healthy before switch 1 and after switch 10) both held.

### 2. Parity run — `~/.local/state/theme/logs/theme-parity-20260707T222832Z.log`

Tail of the passing run (final semantic-value checks + summary):

```
PASS	dracula: walker-style.css semantic values well-formed
PASS	gruvbox: walker-style.css semantic values well-formed
PASS	nord: walker-style.css semantic values well-formed
PASS	rosepine: walker-style.css semantic values well-formed
PASS	tokyonight: walker-style.css semantic values well-formed
PASS	materialyou: yazi.toml semantic values well-formed
PASS	catppuccin: yazi.toml semantic values well-formed
PASS	dracula: yazi.toml semantic values well-formed
PASS	gruvbox: yazi.toml semantic values well-formed
PASS	nord: yazi.toml semantic values well-formed
PASS	rosepine: yazi.toml semantic values well-formed
PASS	tokyonight: yazi.toml semantic values well-formed
PASS	materialyou: vscodium.json semantic values well-formed
PASS	catppuccin: vscodium.json semantic values well-formed
PASS	dracula: vscodium.json semantic values well-formed
PASS	gruvbox: vscodium.json semantic values well-formed
PASS	nord: vscodium.json semantic values well-formed
PASS	rosepine: vscodium.json semantic values well-formed
PASS	tokyonight: vscodium.json semantic values well-formed
SUMMARY	217 passed, 0 failed
```

**Result: 217 passed, 0 failed.** All 6 static presets + materialyou (7 targets) produce an identical structure/variable-name set with well-formed semantic values — no divergence between static and dynamic rendering (PIPE-04 held; confirmed unchanged from 02-01).

**Sequence integrity:** Both logs were produced back-to-back in the same session (stress run 22:27:06Z → parity run immediately after at 22:28:32Z, following the D-40 fix at commit `0d34782`), satisfying the "one clean uninterrupted sequence" requirement — not a stitched combination of separate partial runs.

## D-40 Reliability Bug Found and Fixed

A reliability bug WAS found during the clean-gate loop (Task 2) — not a "no bug found" outcome:

- **Bug:** `lib/commit.sh`'s atomic commit step used `rsync -a --delete` from the temp render dir to the live state dir. Because `logs/` (created by `theme-stress-test` for its own timestamped output) is not part of the matugen render contract and therefore never exists in the temp render dir, `--delete` wiped `~/.local/state/theme/logs/` on every subsequent `theme-apply` commit — i.e., every one of the 10 switches in the stress run destroyed its own prior log output mid-run.
- **Fix:** `lib/commit.sh` rsync invocation now excludes `logs/` (`--exclude=logs/`), so the commit step still atomically syncs every contract file but leaves the non-contract `logs/` subdirectory alone. Fixed minimally, reusing the existing rsync call rather than introducing new sync logic.
- **Commit:** `0d34782` — "fix(02-02): commit.sh rsync --delete was wiping the logs/ directory on every switch"
- **Re-verification:** `theme-parity` re-run all-green after the fix (confirms no regression to the render/commit contract for the 10 tracked state-dir files); the stress run immediately following the fix (`stress-20260707T222706Z.log`) completed 140/140 with its own log surviving all 10 switches, proving the fix.

## Human Visual Sign-Off (D-35 success-criterion bar)

**Status: APPROVED.**

The user ran the fresh default gate, then on switch #10 (materialyou, applied theme at sign-off):

- Opened a **newly-created** Thunar window (not one that had been open since before switch #1) and confirmed it rendered the switch-#10 materialyou palette correctly.
- Summoned Walker (`dev.benz.walker` bus name registered, `--gapplication-service` healthy, elephant `listproviders` responding) and confirmed it rendered themed and returned working search results (D-38).
- Glanced at waybar, swaync (including a test notification), and kitty — all confirmed showing the switch-#10 materialyou palette with no drift, no stuck-white, and no stale mix of two themes.

User's exact confirmation: *"approved" — Thunar, Walker, waybar, swaync, and kitty all render the current materialyou palette correctly after the 10-switch stress run. No issues reported.*

### D-15 / D-37 Caveat — Documented Pass

Per D-15 (established in Phase 1) and D-37 (this phase's explicit re-confirmation), a GTK3 window that was **already open before a theme switch** does NOT live-update its colors — GTK3 has no live CSS reload API, so an existing Thunar window retains the palette it was rendered with until it is closed and reopened. This is an accepted, documented limitation, **not a failure**.

This behavior was directly observed during this plan's stress run: the Thunar window opened as a stress-test precondition (before switch #1) remained on its original palette through the run. The deferred-restart watcher (hardened in Phase 1, `lib/gtk.sh`) detected the daemon process change (PID 778290 → 899510) once that stale window was closed, and confirmed a freshly-opened window rendered correctly on the current theme. The human sign-off above was performed against a **newly-opened** Thunar window specifically to route around this caveat and validate the actual live-rendering contract (D-35's bar), per the how-to-verify instructions in Task 3.

## Pitfall-1 Verification

The stress harness's sentinel check was confirmed to correctly use format-normalized comparison rather than a naive literal grep: a literal grep for a hex sentinel such as `#ebbcba` would fail against `hyprland.conf`'s rendered `rgba(ebbcbaff)` form. The harness's `contract_normalize_color`-based comparison (sourced from `lib/contract.sh`, established in 02-01) correctly matched across both the flat-hex and `rgba(RRGGBBAA)` formats — confirmed directly in the passing stress log line `sentinel (cfbdfe) present in hyprland.conf (normalized)`.

## Summary

| Gate component | Result |
|---|---|
| Fresh 10-switch stress run | 140 passed, 0 failed |
| theme-parity immediately after | 217 passed, 0 failed |
| D-40 reliability bug | Found (logs/ wiped by rsync --delete) and fixed (`0d34782`) |
| D-41 clean full gate | ✓ Achieved in one uninterrupted sequence |
| Human visual sign-off (D-35) | ✓ APPROVED — Thunar, Walker, waybar, swaync, kitty all correct on switch #10 |
| D-15/D-37 caveat | ✓ Documented pass — verified via newly-opened Thunar window |

**PIPE-06 proven:** 10 consecutive switches with Thunar/Walker open, 100% correct on the final switch, human-verified.

---
*Phase: 02-static-dynamic-parity-switch-reliability*
*Plan: 02-02*
*Verified: 2026-07-08*
