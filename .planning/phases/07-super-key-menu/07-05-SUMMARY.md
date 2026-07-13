---
phase: 07-super-key-menu
plan: 05
subsystem: ui
tags: [elephant, walker, stow, hyprland, menus, toml]

# Dependency graph
requires:
  - phase: 07-01
    provides: elephant/ stow package skeleton, elephant-restart.sh, walker menus:main placeholder wiring
provides:
  - Six-entry root menu (Utilities, Settings, AI Dashboard, Game Center, Keybinds, Power)
  - Utilities submenu (Screenshot ›, Emoji, Colour picker, Clipboard)
  - Screenshot sub-submenu (Region, Window, Full screen, Record toggle)
  - Settings submenu (Theme, Wallpaper, Icon theme, Font, Waybar layout, Network, Bluetooth, Audio, Display)
  - nmtui-launch.sh floating-kitty shim + network-manager windowrule
  - Deletion of dead powermenu.sh (D-20)
  - Stow-parity guard in elephant-restart.sh (self-healing, proven live)
affects: [07-06-ai-dashboard, 07-07-game-center, 07-08-cheat-sheet, phase-09-wleave-migration]

tech-stack:
  added: []
  patterns:
    - "elephant menus provider TOML schema (name/name_pretty/parent/[[entries]])"
    - "Launcher-shim pattern (uwsm app -- kitty --class/--title, paired 1:1 with a windowrule)"
    - "D-09 two-class launch convention: shell scripts invoked bare, GUI binaries via uwsm app --"
    - "Stow-parity guard: verify repo-file <-> live-symlink parity before any daemon relies on directory contents, self-heal via stow --restow, name what it healed, refuse to proceed if healing fails"

key-files:
  created:
    - elephant/.config/elephant/menus/utilities.toml
    - elephant/.config/elephant/menus/screenshot.toml
    - elephant/.config/elephant/menus/settings.toml
    - hypr/.config/hypr/scripts/nmtui-launch.sh
  modified:
    - elephant/.config/elephant/menus/main.toml
    - hypr/.config/hypr/config/windowrules.conf
    - hypr/.config/hypr/scripts/elephant-restart.sh
    - README.md
  deleted:
    - hypr/.config/hypr/scripts/powermenu.sh

key-decisions:
  - "D-10/D-11/D-12/D-13/D-16/D-17/D-19/D-20/D-09 all executed as locked in the plan — no deviation from the design decisions."
  - "STOW-PARITY FINDING (durable, applies beyond this phase): adding a file to an already-stowed stow package is a silent no-op until stow is re-run. ~/.config/elephant/menus/ holds file-level symlinks (stow folded to file level because the directory pre-existed when 07-01 stowed main.toml), so utilities.toml/screenshot.toml/settings.toml existed in the repo and were completely invisible to elephant. Every repo-side automated gate (TOML parse, file-exists checks, shellcheck) passed green while the live menu tree was dead — the failure was purely in the stow-sync step between repo and $HOME, a layer none of those gates touch. Applies to ANY stow package gaining a new file, not just elephant. Closed durably by a self-healing parity guard added to elephant-restart.sh (proven live: see below)."
  - "CORRECTION of a false interim finding: an earlier theory claimed 'only parentless (top-level) menus register as independently-listed providers; menus with a parent key are children reached via drill-down, not top-level providers.' That theory is FALSE and was never committed to any tracked file (verified via repo-wide grep) — it was conversational speculation invented to explain what was actually the missing-symlink bug above. Once the three TOMLs were genuinely stowed, ALL FOUR registered as top-level providers: elephant listproviders now lists menus:main, menus:utilities, menus:screenshot, AND menus:settings. The plan's original acceptance criterion (all four must list) was correct all along; the deployment was wrong, not the design."
  - "Bluetooth/Display re-verification: the checkpoint's rejection round included a human note that Bluetooth and Display entries 'do nothing' because blueman/nwg-displays are not installed. Direct verification during this closeout found both ARE installed on this dev machine (blueman 2.4.6-2, nwg-displays 0.4.3-1) and BOTH launch successfully via the exact `uwsm app -- <binary>` action string used in settings.toml (confirmed live: hyprctl clients showed blueman-manager and nwg-displays classes appear in turn). The human's note likely reflects the machine's state at the moment they tested, before or independent of these packages being present; as of this closeout the entries are fully functional. No code change was needed under either reading — install.sh already declares both packages for fresh-install reproducibility (07-03, D-33), and settings.toml's action strings are correct regardless of local package presence."

requirements-completed: [MENU-02, MENU-05, MENU-06]

coverage:
  - id: D1
    description: "Six-entry root menu (Utilities, Settings, AI Dashboard, Game Center, Keybinds, Power), Power last"
    requirement: "MENU-05"
    verification:
      - kind: manual_procedural
        ref: "Human checkpoint re-test: root opens with six entries, Power last, all glyphs render"
        status: pass
    human_judgment: true
    rationale: "Visual glyph rendering and menu-tree correctness require a human looking at the live desktop."
  - id: D2
    description: "Utilities submenu (Screenshot sub-submenu, Emoji, Colour picker, Clipboard) and Screenshot sub-submenu (Region/Window/Full/Record) both drill down and launch their Phase 6 scripts"
    requirement: "MENU-02"
    verification:
      - kind: manual_procedural
        ref: "Human checkpoint re-test: drilled into Utilities and Screenshot, launched Emoji/Colour picker/Clipboard/Region"
        status: pass
    human_judgment: true
    rationale: "Launch correctness of interactive pickers (satty, cliphist, hyprpicker) requires visual/functional human confirmation."
  - id: D3
    description: "Settings submenu (9 entries) launches Theme/Wallpaper/Icon theme/Font/Waybar layout/Network/Bluetooth/Audio/Display via correct D-09 launch class"
    requirement: "MENU-06"
    verification:
      - kind: manual_procedural
        ref: "Human checkpoint re-test: Network opened floating nmtui kitty, Wallpaper/Theme opened pickers"
        status: pass
      - kind: other
        ref: "This closeout: uwsm app -- blueman-manager and uwsm app -- nwg-displays each verified live via hyprctl clients showing the expected window class appear"
        status: pass
    human_judgment: false
  - id: D4
    description: "Stow-parity guard added to elephant-restart.sh: detects missing menu symlinks before cycling elephant, auto-heals via stow --restow, logs what it healed, re-verifies, refuses to proceed if still broken"
    verification:
      - kind: other
        ref: "Live fault injection: rm ~/.config/elephant/menus/settings.toml, ran elephant-restart.sh, confirmed log line 'PARITY FAILED — missing from .../menus: settings.toml', confirmed auto-heal log, confirmed 'parity restored', confirmed post-run elephant listproviders shows all four menus:* providers, confirmed exactly 1 elephant + 1 walker process alive"
        status: pass
      - kind: other
        ref: "shellcheck hypr/.config/hypr/scripts/elephant-restart.sh — zero findings"
        status: pass
    human_judgment: false
  - id: D5
    description: "Dead powermenu.sh deleted (D-20) and delisted from README.md; Power entry delegates to the single wlogout.sh surface"
    verification:
      - kind: other
        ref: "test ! -e hypr/.config/hypr/scripts/powermenu.sh; grep -c powermenu README.md == 0"
        status: pass
    human_judgment: false

duration: 55min (across interim, rejected checkpoint, root-cause, re-test, and closeout)
completed: 2026-07-13
status: complete
---

# Phase 07 Plan 05: Menu Tree (Root/Utilities/Screenshot/Settings) Summary

**Root/Utilities/Screenshot/Settings menu tree shipped as elephant TOML providers; a stow-parity gap that left three menus invisible to elephant (despite every repo-side gate passing) is now root-caused, fixed live, and permanently closed with a self-healing guard.**

## Performance

- **Duration:** ~55 min total (Tasks 1-2 execution, rejected checkpoint, orchestrator root-cause + live fix, human re-test/approval, this closeout)
- **Completed:** 2026-07-13
- **Tasks:** 2 automated tasks + 1 blocking human checkpoint (rejected once, then approved)
- **Files modified:** 8 (4 new/modified menu TOMLs, 1 new launcher shim, windowrules.conf, elephant-restart.sh, README.md) + 1 deleted (powermenu.sh)

## Accomplishments

- Six-entry root menu authored exactly per D-10/D-11: Utilities, Settings, AI Dashboard, Game Center, Keybinds, Power — Power last, no pinned quick-actions.
- Utilities (4 entries, D-12) and its nested Screenshot sub-submenu (4 entries) authored; icon-theme and font pickers deliberately excluded per D-13's "do vs configure" split.
- Settings (9 entries, D-14/D-15) authored, mixing bare shell-script launches and `uwsm app --`-wrapped GUI launches per the D-09 two-class convention, verified in both directions.
- `nmtui-launch.sh` added as the one genuinely new surface (D-17): copies `icon-theme-switch.sh`'s launcher-shim shape, paired 1:1 with a new `network-manager` windowrule block (no duplicate rules added for pavucontrol/blueman-manager, which already had float rules).
- Dead `powermenu.sh` deleted (D-20) and its README.md reference removed; Power now delegates solely to `wlogout.sh`, the same surface Super+Shift+Q opens.
- **Root-caused and permanently closed a stow-parity gap** that made the entire menu tree appear broken at first checkpoint despite every repo-side gate (TOML parse, file-exists, shellcheck) being green.
- **Corrected a false interim theory** about elephant's provider-registration behavior — see Decisions below.
- Live-verified graceful degradation of the two not-yet-authored submenus (AI Dashboard, Game Center): drilling in renders a themed "No Results" empty list, no crash of walker or elephant (screenshot captured during this closeout, not committed — host-local verification artifact).
- Live-verified Bluetooth/Display entries actually launch successfully on this dev machine, correcting a stale checkpoint note.

## The Headline Finding: Stow-Parity Gap

At the first checkpoint pass the human reported the entire drill-down menu tree as broken — only the root rendered; Utilities/Settings/Screenshot did nothing.

**Root cause:** `~/.config/elephant/menus/` is a real directory that already existed before this plan ran (07-01 stowed `main.toml` into it, and stow folds a package to file-level symlinks when the target directory pre-exists rather than symlinking the whole directory). Task 1 and Task 2 of this plan wrote `utilities.toml`, `screenshot.toml`, and `settings.toml` into the repo's `elephant/` stow package — but **never re-ran `stow`** on that package. Adding a new file to an already-stowed package is a silent no-op: the new file sits in the repo, fully valid, fully passing every acceptance criterion that checks the repo tree — and is completely invisible to elephant, which only scans `~/.config/elephant/menus/` at its own startup. `elephant listproviders` after that first restart still showed only `menus:main`.

**The fix (already applied live before this closeout began):**
```
stow --restow elephant --target="$HOME"
~/.config/hypr/scripts/elephant-restart.sh
```
After the restow, `elephant listproviders` immediately showed all four providers. The human re-tested and approved: root renders with six entries, drill-down into Utilities/Screenshot/Settings all work, Esc back-nav works one level at a time, and every leaf launches its target tool.

**Why every automated gate stayed green:** Task 1/2's acceptance criteria (`tomllib.load`, `test -f`, `shellcheck`, `elephant listproviders` run manually by the executing agent immediately after a restart it *did* perform) were all checking the repo tree and a *freshly-run* restart in the same session — they never re-tested after the *next* session's `stow` state, so the specific failure mode (repo file present, live symlink absent) fell entirely outside their coverage. This is the same failure class STATE.md already flags from Phase 6 ("every automated gate passed while wlogout was visibly broken") — a parse/existence check is not a render/registration check.

**Durable closure — this plan adds a permanent guard, not just a one-time fix:** `hypr/.config/hypr/scripts/elephant-restart.sh` now runs a stow-parity check BEFORE cycling elephant. It enumerates every `<repo>/elephant/.config/elephant/menus/*.toml` and confirms a live counterpart exists at `~/.config/elephant/menus/`. On a mismatch it logs the missing menu name(s), auto-heals with `stow --restow elephant --target="$HOME"`, re-verifies, and only then proceeds to cycle elephant+walker. If parity still fails after the restow, it `notify-send`s + logs + exits 1 rather than restarting elephant into a state it knows is broken. This closes the trap for **plans 07-06 (`ai-dashboard.toml`) and 07-07 (`game-center.toml`)**, which will each add exactly the file this bug class targets.

**Proof the guard actually fires (not just written, verified):** during this closeout, `~/.config/elephant/menus/settings.toml`'s live symlink was deliberately removed and the script run:
```
elephant-restart: PARITY FAILED — missing from /home/aorus/.config/elephant/menus: settings.toml
elephant-restart: auto-healing — re-stowing elephant package to restore missing menu symlink(s)
elephant-restart: parity restored — all repo menu TOMLs now have live symlinks
elephant-restart: elephant + walker cycled successfully
```
Post-run: `elephant listproviders` showed all four `menus:*` providers again, and exactly one `elephant` + one `walker` process were alive. Full parity was confirmed restored before moving on.

## Correcting a False Interim Finding

During the investigation before the true root cause was found, an interim theory was floated (in conversation only, never written to a tracked file — confirmed by a repo-wide grep for "parentless"/"top-level" during this closeout, which found no trace of it in STATE.md, any SUMMARY, or any commit message): that only parentless (top-level) menus register as independently-listed elephant providers, and menus with a `parent` key are children reachable only via drill-down, not directly.

**This is false.** It was a plausible-sounding but unverified explanation for what was actually the missing-symlink bug above. The moment the three TOMLs were genuinely stowed onto disk, `elephant listproviders` listed ALL FOUR as top-level providers — `menus:main`, `menus:utilities`, `menus:screenshot`, `menus:settings` — despite `utilities`, `screenshot`, and `settings` all declaring a `parent` key. The plan's original acceptance criterion (`elephant listproviders` must list all four) was correct all along; the code and stow state were what was wrong, not the design. This is the second confabulated root-cause theory this phase (07-04's "wtype has zero effect" was the first) — both were caught only by insisting on live re-verification rather than accepting a tidy-sounding explanation.

## Task Commits

1. **Task 1: Author main.toml, utilities.toml, screenshot.toml — and delete powermenu.sh** - `5b5064f` (feat)
2. **Task 2: Author settings.toml, the nmtui launcher shim, and its windowrule** - `497de75` (feat)
3. **Stow-parity guard added to elephant-restart.sh** - `9180e2f` (fix) — this closeout's durable fix, not an original plan task, added per Rule 2 (missing critical functionality — see Deviations)

**Plan metadata:** (this commit)

## Files Created/Modified

- `elephant/.config/elephant/menus/main.toml` - completed to six entries, root menu
- `elephant/.config/elephant/menus/utilities.toml` - Utilities submenu (4 entries)
- `elephant/.config/elephant/menus/screenshot.toml` - Screenshot sub-submenu (4 entries)
- `elephant/.config/elephant/menus/settings.toml` - Settings submenu (9 entries)
- `hypr/.config/hypr/scripts/nmtui-launch.sh` - new launcher shim, floating kitty running nmtui
- `hypr/.config/hypr/config/windowrules.conf` - added `network-manager` floating-kitty block
- `hypr/.config/hypr/scripts/elephant-restart.sh` - added stow-parity guard (this closeout)
- `README.md` - removed stale `powermenu.sh` reference
- `hypr/.config/hypr/scripts/powermenu.sh` - DELETED (D-20)

## Decisions Made

See frontmatter `key-decisions` for the full text of: the stow-parity finding (durable, carries to Phase 8/9 planning), the correction of the false "parentless menus only" theory, and the Bluetooth/Display re-verification.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical Functionality] Stow-parity guard added to elephant-restart.sh**
- **Found during:** Blocking checkpoint (rejected on first pass)
- **Issue:** The plan's checkpoint instructed the human to run `elephant-restart.sh` before verifying, but the script had no way to detect that the repo's menu TOMLs and the live `~/.config/elephant/menus/` symlinks had fallen out of sync — a silent no-op after `stow` folds a pre-existing directory to file-level symlinks. Without a guard, plans 07-06 and 07-07 (each adding one more menu TOML to the same package) would hit the identical trap.
- **Fix:** Added a parity check to `elephant-restart.sh`, run before cycling elephant: enumerate repo menu TOMLs, confirm each has a live symlink, auto-heal via `stow --restow elephant --target="$HOME"` while logging which menus it linked, re-verify, and refuse to proceed (notify-send + exit 1) if parity still fails after healing.
- **Files modified:** `hypr/.config/hypr/scripts/elephant-restart.sh`
- **Verification:** shellcheck clean; live fault injection (removed `settings.toml`'s live symlink, ran the script, confirmed detection/naming/healing/re-verification/final green state — all four providers registered, 1 elephant + 1 walker process alive).
- **Committed in:** `9180e2f`

---

**Total deviations:** 1 auto-fixed (1 missing-critical-functionality)
**Impact on plan:** Necessary for correctness and to prevent the identical failure recurring in 07-06/07-07. No scope creep — directly required by the checkpoint's rejection and the phase's own explicit instruction to close this class of gap now.

## Issues Encountered

The checkpoint was REJECTED on its first pass (menu tree appeared entirely broken beyond the root). Root-caused and fixed as described above (stow-parity gap); the human re-tested and APPROVED on the second pass. See "The Headline Finding" section above for the full account — this is not a code bug in the menu TOMLs themselves, but a deployment-sync gap between the repo and the live `$HOME` tree.

## User Setup Required

None - no external service configuration required. (`blueman` and `nwg-displays`, declared in `install.sh` per 07-03/D-33, are already installed on this dev machine and verified functional during this closeout.)

## Next Phase Readiness

- MENU-02, MENU-05, MENU-06 all delivered and human-approved live.
- 07-06 (AI Dashboard) and 07-07 (Game Center) can now add their menu TOMLs to the same `elephant/` stow package without risk of silently repeating this plan's checkpoint-rejection failure — `elephant-restart.sh`'s new guard will catch and self-heal a missed `stow --restow` automatically, and refuse to proceed (loudly) if it can't.
- 07-08 (cheat-sheet.sh) has a pre-wired forward reference from `main.toml`'s Keybinds entry — no action needed until that plan lands the script.
- The stow-parity failure class (repo file present, live symlink absent, every repo-side gate green) is worth carrying into Phase 8/9 planning discussions as a general "stow package gains a new file" risk, not an elephant-specific one.

---
*Phase: 07-super-key-menu*
*Completed: 2026-07-13*

## Self-Check: PASSED

All created/modified files found on disk (main.toml, utilities.toml, screenshot.toml, settings.toml, nmtui-launch.sh, elephant-restart.sh); powermenu.sh confirmed deleted. All three commits (5b5064f, 497de75, 9180e2f) found in git log.
