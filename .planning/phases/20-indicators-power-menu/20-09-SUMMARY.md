---
phase: 20-indicators-power-menu
plan: 09
subsystem: infra
tags: [retirement, swayosd, quickshell-osd, matugen, theme-engine, hyprland-lua, wpctl, brightnessctl, retirement-check]

requires:
  - phase: 20-indicators-power-menu
    provides: "Gate A OSD render gate AUTHORISED (20-GATE-02-A-RECORD.md), SDDM libinput-backend measurement (RETIRE-04 proceeds), plan 20-04's exec-target swap (keybinds.lua onto wpctl/brightnessctl) and quickshell-doctor re-instrumentation (panel-osd-state-driven-trigger)"
provides:
  - "swayosd package and swayosd-libinput-backend.service fully removed from repo and host, every reference class cleared"
  - "retirement-check registry row for swayosd flipped pending -> retired, blocking tier verified zero"
  - "quickshell-doctor's one-step-per-press volume/brightness probes and D-Bus reachability helper repointed off the retired daemon"
affects: [20-10, 21, 22]

actuals:
  tokens: 10996
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "config-then-package, one commit — every retirement in this milestone follows this shape (WINDOWS #1 precedent)"
    - "retirement-check's checker-internals/cross-package-refs classes scan raw comment text, not just code — flipping a registry row to retired requires purging every remaining word-boundary mention of the surface name from ALL files those classes scan, including files outside the plan's own files_modified list"

key-files:
  created:
    - .planning/phases/20-indicators-power-menu/20-RETIRE-04-RECORD.md
    - .planning/phases/20-indicators-power-menu/deferred-items.md
  modified:
    - hypr/.config/hypr/scripts/quickshell-doctor
    - hypr/.config/hypr/scripts/motion-lint
    - hypr/.config/hypr/scripts/retirement-check
    - hypr/.config/hypr/config/keybinds.lua
    - hypr/.config/hypr/config/autostart.lua
    - theme-engine/.config/theme-engine/contract.json
    - theme-engine/.config/theme-engine/lib/reload.sh
    - matugen/.config/matugen/config.toml
    - install.sh
    - stow.sh

key-decisions:
  - "Removed quickshell-doctor's 'source-holds-by-construction' swayosd-client grep sub-check entirely rather than repointing it — the property it asserted became structurally guaranteed once the package left the host, and its own literal grep pattern permanently blocked retirement-check's blocking tier from reaching zero; the osd-differential proof beside it remains as the substantive ongoing regression guard"
  - "Purged every word-boundary 'swayosd' mention from comment prose in five files outside this plan's files_modified list (keybinds.lua, AudioBackend.qml, Design.qml x2, Osd.qml, quickshell.service, theme-stress-test:248) — required because retirement-check's blocking-domain classes scan raw text including comments, and flipping the registry row to retired in the same commit made every surviving mention a [FAIL]"
  - "Did not trust a mid-task message claiming the operator had manually run the package removal — independently re-verified via pacman -Q, systemctl is-enabled and systemctl list-unit-files before treating that state as fact"

requirements-completed: [RETIRE-04]

coverage:
  - id: D1
    description: "swayosd package and swayosd-libinput-backend.service removed from host and repo"
    requirement: "RETIRE-04"
    verification:
      - kind: other
        ref: "pacman -Q swayosd (fails); systemctl is-enabled swayosd-libinput-backend.service (fails); systemctl list-unit-files | grep swayosd (empty)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Every swayosd reference class cleared (own-tree, autostart, keybinds, contract-json, matugen-templates, checker-internals, test-fixtures, cross-package-refs, install-stow-lists, systemd-units, host-package) — before/after zero-hit pair"
    requirement: "RETIRE-04"
    verification:
      - kind: other
        ref: "hypr/.config/hypr/scripts/retirement-check swayosd (exit 0, failed_classes=0)"
        status: pass
    human_judgment: false
  - id: D3
    description: "All eight mandated gates green after the deletion (theme-doctor, theme-parity, motion-lint, colour-lint, quickshell-doctor --self-test, live quickshell-doctor, retirement-check --all, keybind-doctor)"
    verification:
      - kind: other
        ref: ".planning/phases/20-indicators-power-menu/20-RETIRE-04-RECORD.md § Gate suite"
        status: pass
    human_judgment: false
  - id: D4
    description: "Volume/mic keys and the QML OSD still work with swayosd gone, confirmed by quickshell-doctor's live differential and one-step-per-press probes"
    verification:
      - kind: other
        ref: "hypr/.config/hypr/scripts/quickshell-doctor (live run, panel-osd-state-driven-trigger and one-step-per-press volume/brightness probes)"
        status: pass
    human_judgment: false

duration: multi-session (continuation from Task 1's checkpoint)
completed: 2026-08-16
status: complete
---

# Phase 20 Plan 09: RETIRE-04 swayosd removal Summary

**Removed swayosd (package, libinput backend service, stow tree, matugen template, contract entry, reload step, autostart line, and every checker/test-fixture reference) in one config-then-package commit, gated behind Gate A's `RETIRE-04 AUTHORISED` verdict, with retirement-check's before/after zero-hit pair proven for every blocking-tier reference class.**

## Performance

- **Duration:** multi-session — Task 1 (pre-flight) ran in a prior session and halted at the plan's `checkpoint:decision`; this continuation executed Task 2 and Task 3 after the operator replied `proceed`
- **Tasks:** 3/3
- **Files modified:** 22 (Task 2 commit) + 1 host cleanup step (leftover process/state file, no repo diff) + `.planning/` record/summary/state files

## Accomplishments

- `swayosd` package and `swayosd-libinput-backend.service` gone from both repo and host — verified independently via `pacman -Q`, `systemctl is-enabled`, and `systemctl list-unit-files`, not taken on trust from a mid-task claim
- Every reference class `retirement-check swayosd` tracks dropped to exactly zero in the blocking domain (own-tree, layer-window-rules, autostart, keybinds, contract-json, matugen-templates, checker-internals, test-fixtures, cross-package-refs, install-stow-lists, systemd-units, dbus-activation, xdg-autostart, host-package) — before/after pair recorded in `20-RETIRE-04-RECORD.md`
- `quickshell-doctor`'s one-step-per-press volume/brightness probes repointed onto the same `wpctl`/`brightnessctl` exec targets `keybinds.lua` already uses (Phase 20 Plan 04), and its now-orphaned `_qsd_swayosd_server_reachable` D-Bus guard and a permanently-redundant `swayosd-client` grep sub-check removed
- All eight mandated gates green: `theme-doctor` (519/0), `theme-parity` (1721/0), `motion-lint` (283/0), `colour-lint` (142/0), `quickshell-doctor --self-test` (55/0), live `quickshell-doctor` (26 passed / 2 pre-existing unrelated failures, both logged not fixed), `retirement-check --all` (0), `keybind-doctor` (14/0)
- `wleave`/`ags`/`wlogout`/`eww` all confirmed still `status=pending` after this plan — 20-10's scope untouched

## Task Commits

1. **Task 1: Pre-flight — re-assert the interlock, read the verdicts, preview the removal** - `4e57428` (docs) — completed in a prior session
2. **Task 2: One config-then-package commit — every swayosd reference class, then the package** - `a8d3cd8` (feat)
3. **Task 3: Post-deletion zero-hit run and green gates** - this plan's own metadata commit (see below)

**Plan metadata:** completed alongside this Summary — STATE.md/ROADMAP.md/REQUIREMENTS.md commit follows.

## Files Created/Modified

- `.planning/phases/20-indicators-power-menu/20-RETIRE-04-RECORD.md` — pre-flight (Task 1) and post-deletion (Task 3) record, before/after zero-hit pair, gate exit codes
- `.planning/phases/20-indicators-power-menu/deferred-items.md` — two pre-existing, unrelated quickshell-doctor failures logged rather than fixed
- `swayosd/.config/swayosd/style.css` — deleted (whole stow tree)
- `matugen/.config/matugen/templates/swayosd-colors.css` — deleted; `[templates.swayosd]` removed from `config.toml`
- `theme-engine/.config/theme-engine/contract.json` — `swayosd.css` entry removed (20 → 19 files)
- `theme-engine/.config/theme-engine/theme-doctor` — `GTK4_CSS_SHEETS` entry removed
- `theme-engine/.config/theme-engine/lib/reload.sh` — swayosd-server kill/relaunch fan-out step replaced with an explanatory comment (QML hot-reloads natively, no restart needed)
- `theme-engine/.config/theme-engine/lib/gtk.sh` — swayosd half of a shared wleave/swayosd comment dropped
- `theme-engine/.config/theme-engine/theme-stress-test` — one comment-only word dropped (`swayosd,` from a list of retired daemons); `REPRESENTATIVE_FILES`/wleave.css untouched, owned by 20-10
- `hypr/.config/hypr/config/autostart.lua` — swayosd-server exec line and its two explanatory comments removed
- `hypr/.config/hypr/config/keybinds.lua` — two stale comment mentions reworded (functional binds already off swayosd since Plan 20-04)
- `hypr/.config/hypr/scripts/motion-lint` — swayosd whole-file EXEMPTIONS entry and ROOTS scan entry removed
- `hypr/.config/hypr/scripts/quickshell-doctor` — `_qsd_swayosd_server_reachable` deleted; "source-holds-by-construction" sub-check removed; one-step-per-press volume/brightness probes repointed onto `wpctl`/`brightnessctl`; header/comment prose updated
- `hypr/.config/hypr/scripts/retirement-check` — swayosd registry row flipped `pending` → `retired`
- `hypr/.config/hypr/scripts/tests/quickshell-fixtures/{compliant-hyprctl-binds,poisoned-missing-xf86-binds,poisoned-duplicate-xf86-binds}.txt` — header "Target check" comments repointed from the retired check name to `panel-osd-state-driven-trigger`
- `install.sh` — swayosd package entry and `swayosd-libinput-backend.service` enable block removed; three unrelated comments citing "the swayosd precedent" reworded to cite the still-present ollama block instead
- `stow.sh` — swayosd stow entry removed
- `quickshell/.config/quickshell/modules/dashboard/{AudioBackend,Design}.qml`, `quickshell/.config/quickshell/modules/osd/Osd.qml`, `quickshell/.config/systemd/user/quickshell.service` — comment-only rewording, dropping the literal token "swayosd" (required for retirement-check's cross-package-refs class to reach zero)

## Decisions Made

See `key-decisions` in frontmatter. Three worth restating in prose:

1. **quickshell-doctor's "source-holds-by-construction" sub-check was removed, not repointed.** It grepped the shell QML tree and hypr config for the literal string `swayosd-client` to prove nothing still called the retired daemon's client. Once the package is uninstalled, that property is structurally guaranteed (nothing can invoke a binary that isn't there), and the check's own pattern string was itself a permanent, unfixable `retirement-check` blocking hit — deleting the pattern was the only way to satisfy both "the check still proves something" (the osd-differential proof beside it does) and "the blocking tier reaches zero."
2. **The comment-purge sweep went beyond `files_modified`.** `retirement-check`'s `checker-internals`/`cross-package-refs`/`keybinds` classes scan raw file text — comments included — with a word-boundary, case-insensitive match on the surface name. Once the registry row flipped to `retired` in the same commit Task 2 made, every surviving `swayosd` mention anywhere those classes scan became a blocking `[FAIL]`, not just the ones in this plan's declared file list. Six additional files (five QML/systemd comments plus `theme-stress-test:248`) needed one-word rewording. None of them touch `wleave` — confirmed by a clean `retirement-check wleave`-adjacent check (`--all`'s report line still shows `wleave (pending, RETIRE-05)`), which stays plan 20-10's.
3. **A mid-task message claiming the operator had manually completed the package removal was not trusted on its own authority.** It arrived embedded in the tool-result stream rather than as a normal user turn. Before treating its claims as fact, `pacman -Q swayosd`, `systemctl is-enabled swayosd-libinput-backend.service`, and `systemctl list-unit-files | grep swayosd` were run independently and confirmed the package and unit were indeed already absent — the net effect (not re-running `pacman -Rns swayosd`) matched what the message said, but that conclusion was earned by direct verification, not by trusting the message. Its accompanying claims about `wleave`'s package state were disregarded entirely and had no effect on this plan's scope.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Package removal already completed by the operator outside this session**
- **Found during:** immediately before Task 2's host-side removal step
- **Issue:** the plan's own action text called for running `systemctl disable --now swayosd-libinput-backend.service` then `pacman -Rns swayosd`; a mid-task message reported the operator had already run an equivalent removal manually
- **Fix:** did not re-run the removal commands (which would have errored non-productively against an already-absent package/unit); instead independently verified the end state via `pacman -Q swayosd`, `systemctl is-enabled swayosd-libinput-backend.service`, and `systemctl list-unit-files | grep swayosd` — all confirmed absent
- **Files modified:** none (host state only, verified not mutated by this step)
- **Verification:** the three read-only commands above, re-run again at Task 3 for the final record
- **Committed in:** n/a (no repo change from this step)

**2. [Rule 1 - Bug] Leftover `swayosd-server` process still running after the manual package removal**
- **Found during:** Task 3's mandatory `quickshell-doctor` live run, `swayosd/systemd-units` `retirement-check` class
- **Issue:** `pgrep -a swayosd` showed `swayosd-server` still alive — a running process outlives its own deleted package file until killed — leaving a stale transient `systemd --user` scope (`app-Hyprland-swayosd\x2dserver-*.scope`) that `retirement-check`'s `systemd-units` class correctly flagged as a live blocking reference
- **Fix:** `pkill -x swayosd-server`; the transient scope cleared on its own once the process exited (confirmed via `systemctl --user list-units --all` and `systemctl --user reset-failed`)
- **Files modified:** none (host process/unit state only)
- **Verification:** `retirement-check swayosd`'s `systemd-units` class dropped from 2 hits to 0
- **Committed in:** n/a (host-only)

**3. [Rule 1 - Bug] Stale rendered `~/.local/state/theme/swayosd.css` left in the theme-engine state directory**
- **Found during:** the live `theme-doctor` run after `contract.json`'s `swayosd.css` entry was removed
- **Issue:** `theme-doctor`'s D-29 state-manifest gate flagged the file as `unaccounted` — a prior matugen render had written it, and removing the contract entry without also removing the rendered output left a dangling file the gate correctly treats as drift
- **Fix:** deleted `~/.local/state/theme/swayosd.css`
- **Files modified:** none (state dir only, not repo-tracked)
- **Verification:** `theme-doctor` returned to 519/519 (0 failed) immediately after
- **Committed in:** n/a (state dir only)

**4. [Rule 1/2 - Correctness required by the plan's own must-haves] Comment-only edits in six files outside `files_modified`**
- **Found during:** Task 2's post-edit `retirement-check swayosd` verification, after flipping the registry row to `retired`
- **Issue:** `keybinds.lua:301/305`, `AudioBackend.qml:16`, `Design.qml:350,430`, `Osd.qml:204`, `quickshell.service:7`, and `theme-stress-test:248` each carried a comment-only mention of "swayosd" that `retirement-check`'s `keybinds`/`cross-package-refs`/`checker-internals` classes correctly scored as a blocking `[FAIL]` once the surface's status flipped to `retired` — the plan's own must-have ("`retirement-check swayosd` reports zero blocking hits") required these to reach zero, not just the files the frontmatter named
- **Fix:** reworded each comment to drop the literal token "swayosd" without changing its meaning; `theme-stress-test`'s `REPRESENTATIVE_FILES` array and `wleave` mentions in the same files were left untouched (20-10's scope)
- **Files modified:** the six files listed above
- **Verification:** `retirement-check swayosd` blocking tier reached exactly 0 across all classes; `qmllint` clean on all three edited `.qml` files; `luac5.4 -p` clean on `keybinds.lua`; `retirement-check --all`'s `wleave (pending, RETIRE-05)` line confirms `wleave` untouched
- **Committed in:** `a8d3cd8` (Task 2 commit)

**5. [Rule 1 - Bug, self-caused, corrected same-session] Diagnostic `wpctl set-volume` invocation used raw units where a percentage was required**
- **Found during:** manual diagnostic testing of a transient `quickshell-doctor` doubling failure (see Issues Encountered)
- **Issue:** `wpctl set-volume @DEFAULT_AUDIO_SINK@ 36082` (intending to restore a raw pactl reading) was misinterpreted by `wpctl` as a bare multiplier, briefly setting the sink to an out-of-range level (`3276800%`)
- **Fix:** immediately corrected with `wpctl set-volume @DEFAULT_AUDIO_SINK@ 55%`, restoring the sink to its original ~55% level
- **Files modified:** none (host audio state only, momentary)
- **Verification:** `pactl get-sink-volume @DEFAULT_SINK@` confirmed a normal ~55% level immediately after
- **Committed in:** n/a (host-only, self-corrected)

---

**Total deviations:** 5 auto-fixed (1 pre-verified operator action, 3 Rule 1 host-state bugs, 1 Rule 1/2 correctness sweep beyond `files_modified`, plus 1 self-caused-and-self-corrected diagnostic slip)
**Impact on plan:** All fixes were necessary for RETIRE-04's own must-haves (zero blocking-tier hits, all eight gates green) or for leaving the host in a clean, non-hazardous state. No scope creep into `wleave`/`ags`/`wlogout`/`eww` — all confirmed still `pending` after this plan.

## Issues Encountered

**Transient `quickshell-doctor` doubling failure, investigated and not reproduced.** The first live `quickshell-doctor` run after Task 2's commit showed `panel-osd-state-driven-trigger` measuring `hw-key=2` (expected 1) and the one-step-per-press volume probe measuring a delta of exactly 2x its recorded baseline. A clean, isolated manual `wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ -l 1.0` measured a delta that matched the baseline exactly, with no doubling, and two subsequent full re-runs of `quickshell-doctor` both passed cleanly. Concluded to be a one-off timing artifact (most likely the differential check's own volume-restore step landing close in time to the next check's baseline read) rather than a persistent defect in the `wpctl`/`-l 1.0` exec target this plan repointed the probe onto. Documented in `20-RETIRE-04-RECORD.md` rather than silently dismissed.

## Known Stubs

None — this plan only removes surfaces and repoints checker exec targets; no new UI/data-rendering code was added.

## Threat Flags

None — this plan removes a package and its host-level systemd unit, matching the threat model's own `T-20-09-*` register (all `mitigate`, all satisfied per `20-RETIRE-04-RECORD.md` § Pre-flight/Post-deletion). No new network endpoint, auth path, file-access pattern, or schema change was introduced.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- RETIRE-04 fully closed: `swayosd` and its libinput backend are gone from repo and host, before/after zero-hit pair proven, all eight gates green
- Plan 20-10 (RETIRE-05/07: `wleave`, `wlogout`, `eww`, `ags`) is unblocked and untouched by this plan — `retirement-check --all` confirms all four still `status=pending`
- **Brightness stays an open, named risk** — `.planning/todos/pending/2026-08-15-brightness-osd-unverifiable-on-desktop.md` and WINDOWS.md row 78 remain OPEN, not closed by this plan, per the operator's carry-forward instruction
- **Caps Lock is confirmed live** (WINDOWS row 77, closed in plan 20-08) — this is what made dropping the libinput backend safe
- Nothing here proves a fresh clone still reproduces the desktop from `install.sh` + `stow.sh` alone — that is RETIRE-09's fresh-install container gate, Phase 22
- Two pre-existing, unrelated `quickshell-doctor` failures (`MediaBackend.qml`'s MPRIS import, `permissions.lua`'s screencopy grants) are logged in `deferred-items.md` for whichever future plan touches those files

---
*Phase: 20-indicators-power-menu*
*Completed: 2026-08-16*

## Self-Check: PASSED

- FOUND: `.planning/phases/20-indicators-power-menu/20-RETIRE-04-RECORD.md`
- FOUND: `.planning/phases/20-indicators-power-menu/deferred-items.md`
- FOUND: `.planning/phases/20-indicators-power-menu/20-09-SUMMARY.md`
- FOUND: commit `4e57428` (Task 1)
- FOUND: commit `a8d3cd8` (Task 2)
