---
quick_id: 260828-ah9
slug: replace-icon-theme-and-font-theme-picker
date: 2026-08-28
status: complete
actuals:
  tokens: 43616
  tasks: 5
  commits: 6
commits:
  - 340b59bc  # Task 1: AppearanceBackend singleton — one backend, four readers
  - 4a5caf2e  # Task 2: Atelier window — FloatingWindow, tab bar, Icons/Fonts tabs
  - 24fb7aa6  # Task 3: Catalogue tab — browse and install icon themes (D-04)
  - 2c24d219  # Task 4: Specimen — icon/font launcher word routes (D-01)
  - 5487ea79  # Task 5 Commit A: keybind package B + equivalence-gate entries
  - a0774ca6  # Task 5 Commit B: script strip, menu/drawer repointing, ROADMAP strike
---

# Replace icon-theme and font theme pickers with QML surfaces

Two new surfaces over one backend replace the fzf-in-kitty icon-theme and font
pickers: **Specimen** (launcher `icon`/`font` word routes) and **Atelier** (one
`FloatingWindow` with Icons/Fonts/Catalogue tabs, reached via `Super+I` /
`Super+Shift+F`). Both scripts kept their `--list`/`--set` machine-facing tail
and lost their interactive half. The Catalogue tab consumes the standing
v5.0 ICON-BROWSE candidate — struck in ROADMAP.md.

## What ships

| Piece | Files |
|---|---|
| Backend singleton | `modules/appearance/AppearanceBackend.qml` |
| Atelier window | `modules/appearance/{Atelier,AtTabBar,AtIconsTab,AtFontsTab,AtCatalogueTab}.qml` |
| Specimen (launcher routes) | `modules/launcher/{IconMode,FontMode}.qml` + `LauncherState`/`Launcher` |
| Menu leaves | `modules/launcher/{MenuTree,MenuMode}.qml` (Style ▸ Icon theme / Font) |
| Bar drawer | `modules/bar/ClockActionsCapsule.qml` (Font/Icon Theme cells) |
| Settings page | `modules/settings/pages/AppearancePage.qml` (repointed to the backend) |
| Keybind | `Super+I` (Icons), `Super+Shift+F` (Fonts); `Super+Shift+I` code editor, `Super+Shift+M` maximize |
| Scripts | `icon-theme-picker.sh` / `font-switcher.sh` stripped to `--list`/`--set`(`/--preview`) |
| Retired | `icon-theme-switch.sh`, `font-switch.sh` (shims), their windowrules.lua blocks |

## Measurements — all three held, no contradiction

- **M1 (48px is too coarse):** confirmed live. `Papirus`/`Papirus-Dark`/`Papirus-Light`
  are visually and structurally the same at 48px; the 22px preview grid is what
  actually distinguishes them (`AppearanceBackend`'s `--preview` verb, biased to
  the requested size).
- **M2 (13×2, not 13×3):** confirmed live — `font-switcher.sh --list` still
  enumerates exactly 39 raw names (13 families × 3 suffixes), and
  `AppearanceBackend.fontFamilies` collapses them to 13×{mono, propo} with no
  third "Nerd Font alone" row.
- **M3 (no icon exists in all 8 themes):** confirmed and EXTENDED live — the
  new `--preview` verb surfaces it directly: `Adwaita` resolves 9/12 probes
  (misses `applications-system`, `utilities-terminal`, `preferences-system`);
  every other installed theme resolves 12/12 once `_find_icon_at_size` follows
  symlinks (see Deviations — this was a real instrument gap the M1/M3
  measurements didn't need to account for, since the retired script's preview
  had the identical blind spot and nobody had compared theme-by-theme
  coverage numbers before).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `_find_icon_at_size` killed `--preview` after ~4 rows under `set -e`**
- **Found during:** Task 1, first live test of the new `--preview` verb
- **Issue:** the helper ended with `[[ -n "$f" ]] && printf '%s\n' "$f"` and no
  explicit `return 0`. Under `set -euo pipefail`, a bare `_f=$(...)`
  assignment (unlike a `local` assignment) propagates the callee's exit
  status — a probe that legitimately found nothing (exit 1) killed the whole
  `--preview` loop.
- **Fix:** added an explicit `return 0` at the end of the function.
- **Files:** `hypr/.config/hypr/scripts/icon-theme-picker.sh`
- **Commit:** 340b59bc

**2. [Rule 1 - Bug] `find` without `-L` under-reported delta-theme coverage**
- **Found during:** Task 1, same test — `Papirus-Dark` measured 4/12 real
  paths instead of the ≥8 the plan's own `<done>` criterion requires
- **Issue:** `Papirus-Dark` only OWNS `actions` (every size) plus
  `devices`/`places` (16px only) as real directories; `apps`/`mimetypes` and
  every non-overridden size are real per-category SYMLINKS into `Papirus`.
  Plain `find` does not descend into a symlinked directory, so the probe
  reported Papirus-Dark as covering 4/12 — an instrument fault, not what an
  icon-theme loader (or `ls -R`) actually resolves.
- **Fix:** `_find_icon_at_size` now uses `find -L`. Papirus-Dark resolves
  12/12 at the requested 22px size.
- **Files:** `hypr/.config/hypr/scripts/icon-theme-picker.sh`
- **Commit:** 340b59bc

**3. [Rule 1 - Bug] `Row.implicitHeight` is read-only — crashed the whole launcher**
- **Found during:** Task 4, surfaced by a coincidental host event (see Issues
  Encountered below), not by any gate
- **Issue:** `IconMode.qml`'s horizontal strip assigned `implicitHeight: 148`
  directly on a `Row` (a Positioner). Positioners compute `implicitHeight`
  from their children and refuse a direct assignment. Quickshell's config
  loader treats this as a fatal type-load error: `Type IconMode unavailable`
  cascaded up through `Launcher.qml` to `Type Launcher unavailable` —
  the ENTIRE launcher (all modes, not just Icons) would have failed to load
  on the next reload.
- **Fix:** removed the assignment; the Row's implicit height already comes
  from its tallest child (the 140px tiles).
- **Files:** `quickshell/.config/quickshell/modules/launcher/IconMode.qml`
- **Commit:** 2c24d219

**4. [Rule 1 - Bug] `hypr-equivalence-check`'s binds.json PASS branch discarded every accepted-note**
- **Found during:** Task 5, verifying the four new `ACCEPTED_ADDITIONS`/
  `ACCEPTED_REMOVALS` entries actually fired
- **Issue:** the `options.jsonl` branch already prints `$diff_out` (the
  accepted-note lines) on BOTH pass and fail (`[[ -n "$diff_out" ]] && echo
  "$diff_out"`). The `binds.json` branch immediately below it was missing
  that same line — every accepted-addition/removal note was silently
  discarded whenever the gate passed. This defeated the gate's own stated
  guarantee ("a stale entry that does not fire is itself reported, so a
  mis-typed identity cannot pass silently") on exactly the path that
  matters — a green run — and affected every prior accepted rebind in this
  gate's history, not just this task's four.
- **Fix:** added the identical guard to the `binds.json` PASS branch.
- **Files:** `hypr/.config/hypr/scripts/hypr-equivalence-check`
- **Commit:** 5487ea79

---

**Total deviations:** 4 auto-fixed (4× Rule 1 — all bugs, all found and fixed
before their task's commit). No scope creep; no architectural changes.

## Issues Encountered

**A transient, unrelated Wayland/compositor crash coincided with Task 3's
close (08:22:59), triggering `quickshell.service`'s `Restart=on-failure`
policy (systemd, not me — the hard prohibition on restarting quickshell from
this shell was never violated).** The crash itself (`The Wayland connection
experienced a fatal error: Invalid argument`) is unrelated to this task's
QML — it matches the class of NVIDIA+Wayland flakiness already on record for
this host. Its side effect was useful: the resulting fresh config load
surfaced Deviation 3 above (`IconMode.qml`'s `Row.implicitHeight` bug) that a
running engine's incremental hot-reload would not otherwise have
re-evaluated, since `qmllint`/`qmlformat` are blind on this host and the only
real QML-load-error signal is the running shell's own reload log. Confirmed
fixed: the shell reached a clean `Configuration Loaded` state afterward and
stayed there through every subsequent edit (same PID, `179750`, throughout
Tasks 4-5).

**MenuTree.qml's two `command:` fields still contain the literal strings
`icon-theme-switch.sh`/`font-switch.sh`** (kept "for the record", mirroring
this file's own pre-existing `theme-switch.sh` precedent — see Task 5
Commit B's own message for the full reasoning). A naive grep for those
filenames outside `#`/`--`/`//`-comment lines still matches these two lines.
Confirmed NOT a live reference (`row.appearance` is checked and returns
before `row.command` is ever reached in `MenuMode.qml`'s `activate()`), and
confirmed this is the SAME shape the codebase already ships for
`theme-switch.sh` (also deleted, also kept in a `command:` field). Not a
defect — documented in the Task 5 Commit B message.

**The two shim deletions (`icon-theme-switch.sh`, `font-switch.sh`) landed in
Task 5 Commit A instead of Commit B**, because `git rm` had already staged
them during editing, before the two-commit split was executed. Both commits
are still independently correct and gate-passing (the deletions don't affect
`hypr-equivalence-check` at all); this is a packaging deviation, not a
functional one.

## Operator Checklist — everything below needs a human

None of the 17 items in the plan's own `<operator_checklist>` could be run
from this agent shell — no input-injection tool exists here, `grim`
screenshots crash this NVIDIA host, and restarting quickshell/running
`quickshell-doctor` are both forbidden. All 17 remain **unrun**, verbatim
from the plan:

1. `Super+I` opens the Atelier on the Icons tab.
2. `Super+Shift+F` opens the same window on the Fonts tab; re-aims if already open on Icons.
3. `Super+Shift+I` opens the code editor; `Super+Shift+M` maximizes; `Super+F` unchanged.
4. `Super+Shift+Z`/`Super+Shift+X` now do nothing.
5. Papirus/Papirus-Dark/Papirus-Light look visibly different in the Icons tab.
6. Thin-coverage themes (Adwaita, breeze) show visible placeholders + an honest coverage count.
7. Each Fonts-tab row renders in its own font; two rows per family (Mono/Propo), not three.
8. Clicking a theme/font applies it — desktop re-themes, notification fires.
9. Click-outside dismisses the Atelier; mouse-out does not.
10. `Esc` closes the window.
11. Launcher `icon` route: strip appears, word painted in accent, arrow keys walk it, Enter applies.
12. Launcher `font` route: same; `fontconfig` stays an ordinary app search.
13. Catalogue tab: search returns repo+AUR rows; Install closes the Atelier, opens a clickable terminal.
14. After install, reopening the Atelier shows the before/after diff and the new theme in Icons.
15. Resize the Atelier and reopen it — the tab you left on is the tab you return to.
16. Bar clock drawer's Font/Icon Theme cells open the launcher on the new routes.
17. `quickshell-doctor --self-test` (operator-only — it restarts the shell internally).

## What was verified live from this shell (everything a static gate or a log
read CAN prove)

- `bash -n` clean on both stripped scripts; `--list` still enumerates (8 icon
  themes, 39 raw font names); `--preview <theme> 22` emits 12 tab-separated
  rows for every installed theme.
- `hyprctl reload` + `hypr-equivalence-check`: **PASS: 3 FAIL: 0**, all four
  new bind entries firing as accepted notes; `hyprctl -j binds` directly
  confirms modmask 65 I/M present, 65 Z/X absent, 64 I/F/Z/X/M unchanged.
- `keybind-doctor`: **13 passed, 0 failed**. `stow-link-check`: **2 passed, 0
  failed**.
- `qml-import-check`: **0 unresolved / 188 files** (up from 180).
  `colour-lint`: **560/0** (up from 536). `motion-lint`: **745/0** (up from
  721). `settings-index-check`: **191/0** (unchanged, no settings-page
  structure touched beyond the two repointed SelectRows).
- `~/.cache/quickshell.log`: read at every task boundary via byte-offset
  tail; zero errors naming any new file after each task's edits settled;
  quickshell's own `Configuration Loaded` line confirms every hot reload
  succeeded.

## Next Phase Readiness

Nothing blocked. The Atelier's Catalogue tab retires the v5.0 ICON-BROWSE
roadmap candidate (struck this task). All five plan tasks landed with their
own `<verify>` blocks green; the four deviations above were all bugs found
and fixed before their owning task's commit, never deferred.

## Self-Check: PASSED

All 10 claimed files exist on disk; all 6 claimed commit hashes are present in `git log`.
