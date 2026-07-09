---
phase: 01-root-cause-fix-consolidated-theme-engine
plan: 02
subsystem: theming-pipeline
tags: [matugen, theme-engine, gtk, hyprland, waybar, swaync, walker, kitty, vscodium, yazi, stow]

requires:
  - phase: 01-root-cause-fix-consolidated-theme-engine
    provides: AUDIT.md findings 1/2/4/5/6/8/11/12/17, adw-gtk-theme installed
provides:
  - "theme-engine/ stow package: theme-apply (single entrypoint), theme-doctor (health check), lib/{generate,commit,reload,gtk}.sh"
  - "6 static-preset palettes (catppuccin/dracula/gruvbox/nord/rosepine/tokyonight) as matugen-json input, parity-by-construction with Material You"
  - "matugen config.toml with zero post_hooks, no wallpaper-setting panic risk, no wofi block, all output_path on the ~/.local/state/theme/ contract"
  - "atomic render-then-commit-then-reload pipeline: a failed render never touches the live desktop"
  - "every app consumer (hyprland, kitty, waybar x3, swaync, wlogout, gtk-3/4.0, walker, yazi, vscodium) reads from ~/.local/state/theme/ via native import/symlink, no more cp/cat"
  - "theme-switch.sh, theme-init.sh, wallpaper-picker.sh reduced to thin callers of theme-apply — the three-way duplication from AUDIT finding #1 is gone"
  - "GTK_THEME single source of truth (uwsm/env only); 8 orphaned generated color files untracked from git"
affects:
  - 01-03 (per-app hardening — Thunar restart already bounded-poll'd here but needs re-verification; walker-restart.sh/walker-theme-gen.sh/gtk-reload.sh are explicitly retired-but-not-yet-deleted, left in place for 01-03's own retirement task)
  - phase-03 (wofi/colors.css and wofi's matugen removal cleanup remain out of scope, D-11/finding #10)

tech-stack:
  added: []
  patterns:
    - "atomic render-then-commit: matugen -p <tmp> then rsync --delete into the real state dir only on exit 0"
    - "single reload owner: lib/reload.sh is the only file in the repo invoking hyprctl reload / pkill -SIGUSR* / swaync-client -rs / walker restart / the vscodium merge"
    - "no-import consumers get idempotent symlink wiring (walker, yazi) instead of a per-login mkdir/rm dance"
    - "fully-detached background relaunches (setsid + /dev/null redirects) so a long-running daemon never holds a caller's pipe open"

key-files:
  created:
    - theme-engine/.config/theme-engine/theme-apply
    - theme-engine/.config/theme-engine/theme-doctor
    - theme-engine/.config/theme-engine/lib/generate.sh
    - theme-engine/.config/theme-engine/lib/commit.sh
    - theme-engine/.config/theme-engine/lib/reload.sh
    - theme-engine/.config/theme-engine/lib/gtk.sh
    - theme-engine/.config/theme-engine/palettes/{catppuccin,dracula,gruvbox,nord,rosepine,tokyonight}.json
  modified:
    - matugen/.config/matugen/config.toml
    - matugen/.config/matugen/templates/hyprland-colors.conf
    - gtk/.config/gtk-3.0/gtk.css
    - gtk/.config/gtk-4.0/gtk.css
    - hypr/.config/hypr/hyprland.conf
    - hypr/.config/hypr/hyprlock.conf
    - hypr/.config/hypr/config/env.conf
    - hypr/.config/hypr/config/keybinds.conf
    - hypr/.config/hypr/config/autostart.conf
    - hypr/.config/hypr/scripts/theme-switch.sh
    - hypr/.config/hypr/scripts/theme-init.sh
    - hypr/.config/hypr/scripts/wallpaper-picker.sh
    - kitty/.config/kitty/kitty.conf
    - waybar/.config/waybar/style-full.css
    - waybar/.config/waybar/style-minimal.css
    - waybar/.config/waybar/style-floating.css
    - swaync/.config/swaync/style.css
    - wlogout/.config/wlogout/style.css
    - .stow-local-ignore
    - stow.sh
    - .gitignore

decisions:
  - "Fixed hyprland-colors.conf's $image = {{colors.image}} line: matugen 4.1.0 does not populate the image color context in EITHER json or image render mode (empirically verified — corrects 01-RESEARCH.md's narrower claim that only the json path needed a blank colors.image key). Hardcoded a blank value; hyprlock theming is out of scope this milestone."
  - "Deleted (not just untracked) gtk-{3,4}.0/gtk-base.css: its two comment lines are now inlined directly into the new static gtk.css, making the separate file fully redundant."
  - "walker/themes/rice/style.css and yazi/theme.toml untracked + gitignored rather than excluded via .stow-local-ignore alone: both paths are physically inside whole-package stow symlinks back into this repo, so theme-apply's idempotent symlink wiring (D-07) would otherwise write directly into git-tracked repo paths on every switch."
  - "Left walker-restart.sh, walker-theme-gen.sh, gtk-reload.sh, vscodium-theme.sh on disk, unreferenced, rather than deleting them — Plan 01-03's own task list explicitly claims retiring walker-restart.sh/walker-theme-gen.sh/gtk-reload.sh as its scope; deleting them now would make 01-03's <files> references stale."
  - "Added theme-engine to stow.sh's PACKAGES array and removed the dead ~/.cache/current-theme pre-seed — without the former a fresh install never wires theme-apply at all."
  - "Fully detached the walker and thunar --daemon background relaunches (setsid + redirected stdio) after discovering the original unredirected `&`/`disown` pattern hangs any caller that pipes theme-apply's own output (e.g. `theme-apply ... | tail`)."

requirements-completed: [PIPE-01, PIPE-02, PIPE-03, PIPE-05, THEME-04, THEME-05, THEME-06]

coverage:
  - id: D1
    description: "theme-apply <name> single entrypoint: validates the theme name, renders atomically to a temp prefix, commits only on success, reloads once"
    requirement: "PIPE-01"
    verification:
      - kind: manual_procedural
        ref: "theme-apply catppuccin && theme-apply materialyou — both exit 0, populate ~/.local/state/theme/ with all 10 contract files + current-theme (live run, this session)"
        status: pass
      - kind: manual_procedural
        ref: "theme-apply nonexistenttheme123 — rejected before any path is built, exit 1, state unchanged"
        status: pass
      - kind: manual_procedural
        ref: "forced-failure test: corrupted dracula.json, theme-apply dracula exits 1, current-theme md5 unchanged before/after"
        status: pass
    human_judgment: false
  - id: D2
    description: "matugen config.toml: zero post_hooks, no wallpaper-panic table, no wofi block, output_path on the state-dir contract"
    requirement: "PIPE-02"
    verification:
      - kind: manual_procedural
        ref: "grep -vE '^\\s*#' matugen/config.toml | grep -c post_hook -> 0; grep -c 'set = true' -> 0; matugen json/image both render 10/10 files"
        status: pass
    human_judgment: false
  - id: D3
    description: "lib/reload.sh is the single reload fan-out owner (hyprctl, waybar/kitty signals, swaync, GTK, hardened walker restart, vscodium merge)"
    requirement: "PIPE-02"
    verification:
      - kind: manual_procedural
        ref: "hyprctl reload / pkill -SIGUSR2 waybar / swaync-client -rs all exercised live via theme-apply catppuccin, no errors; walker process relaunched and elephant listproviders responded post-restart"
        status: pass
    human_judgment: false
  - id: D4
    description: "Generated per-app color files removed from git tracking; theme switches leave git status clean for those paths"
    requirement: "PIPE-03"
    verification:
      - kind: manual_procedural
        ref: "git ls-files | grep -E '(gtk-[34]\\.0/colors\\.css|walker/themes/rice/style\\.css|waybar/colors\\.css|swaync/colors\\.css)' -> empty; git status --short clean after live theme-apply run"
        status: pass
    human_judgment: false
  - id: D5
    description: "GTK_THEME single source of truth (uwsm/env only); lib/gtk.sh only propagates, never hardcodes"
    requirement: "PIPE-05"
    verification:
      - kind: manual_procedural
        ref: "grep GTK_THEME across uwsm/env, hypr/config/env.conf, lib/gtk.sh — only uwsm/env has an assignment"
        status: pass
    human_judgment: false
  - id: D6
    description: "Every consumer (hyprland, kitty, waybar x3, swaync, wlogout, gtk-3/4.0, walker, yazi, vscodium) imports/sources/includes from the state dir; no runtime concatenation remains"
    requirement: "THEME-04, THEME-05, THEME-06"
    verification:
      - kind: manual_procedural
        ref: "live reload of waybar (pkill -SIGUSR2), swaync (swaync-client -rs, reported CSS reload success: true), kitty (kitty -e true, clean stderr), hyprctl reload (ok) — all against the new @import/source/include paths"
        status: pass
    human_judgment: true
    rationale: "Visual confirmation that colors actually render correctly on screen (vs. just 'file parses without error') needs a human looking at the live desktop — automated checks here only prove the config loads cleanly, not that it looks right."

duration: 40min
completed: 2026-07-07
status: complete
---

# Phase 1 Plan 02: Consolidated Theme Engine Summary

**One shared `theme-apply <name>` entrypoint atomically renders static presets and Material You through the same matugen templates into `~/.local/state/theme/`, owns the entire reload fan-out, and every app config now imports from that state dir instead of the old triplicated cp/cat pipeline.**

## Performance

- **Duration:** ~40 min
- **Completed:** 2026-07-07
- **Tasks:** 3
- **Files modified:** 27 tracked changes across the final commit + palette/engine files created earlier (33 total files touched across the plan)

## Accomplishments
- Built `theme-engine/` as a new stow package: `theme-apply` (validated single entrypoint), `theme-doctor` (17-point health check), and 4 lib scripts (`generate.sh`, `commit.sh`, `reload.sh`, `gtk.sh`) implementing atomic render-then-commit-then-reload
- 6 static presets now render through the exact same matugen templates as Material You (parity by construction, D-03) — proved live with both `matugen json` and `matugen image`
- Collapsed the 3-way apply+reload duplication (theme-switch.sh, theme-init.sh, wallpaper-picker.sh) AUDIT flagged into thin callers of one entrypoint
- Every consumer app (hyprland, kitty, 3 waybar layouts, swaync, wlogout, gtk-3/4.0, walker, yazi, vscodium) now reads live from `~/.local/state/theme/` — no more generated files tracked in git, no more runtime `cat`/`cp` concatenation
- GTK_THEME consolidated to one source (`uwsm/env`); state dir created with user-only 0700 perms

## Task Commits

1. **Task 1: Static-preset palettes + single-rendering-path matugen config** - `df4a750` (feat)
2. **Task 2: theme-engine core — atomic apply + single reload owner** - `11e16ef` (feat)
3. **Task 3: Wire consumers + move generated output out of the git tree** - `9b448fe` (feat)

_Note: Task 2's commit also folds in the walker/yazi untrack+gitignore prep that Task 2's own live verification required (see Deviations)._

## Files Created/Modified

**Created:**
- `theme-engine/.config/theme-engine/theme-apply` - single entrypoint, argument validation, atomic orchestration
- `theme-engine/.config/theme-engine/theme-doctor` - 17-invariant health check
- `theme-engine/.config/theme-engine/lib/generate.sh` - matugen json|image into a temp prefix
- `theme-engine/.config/theme-engine/lib/commit.sh` - atomic move + walker/yazi symlink wiring
- `theme-engine/.config/theme-engine/lib/reload.sh` - the only reload fan-out owner
- `theme-engine/.config/theme-engine/lib/gtk.sh` - gsettings toggle + GTK_THEME propagation + Thunar daemon restart
- `theme-engine/.config/theme-engine/palettes/*.json` - 6 static presets as matugen-json input

**Modified (key):**
- `matugen/.config/matugen/config.toml` - hooks/wallpaper-table/wofi stripped, output_path on state-dir contract
- `matugen/.config/matugen/templates/hyprland-colors.conf` - fixed the colors.image ResolveError blocker
- `gtk/.config/gtk-{3,4}.0/gtk.css` - static @import files, gtk-base.css retired
- `hypr/.config/hypr/{hyprland.conf,hyprlock.conf,config/env.conf}` - state-dir source, GTK_THEME dedup
- `hypr/.config/hypr/scripts/{theme-switch,theme-init,wallpaper-picker}.sh` - thin callers
- `kitty/.config/kitty/kitty.conf`, `waybar/.config/waybar/style-*.css`, `swaync/.config/swaync/style.css`, `wlogout/.config/wlogout/style.css` - state-dir imports
- `.stow-local-ignore`, `stow.sh`, `.gitignore` - package registration + wiring hygiene

## Decisions Made

See frontmatter `decisions` — highlights: hardcoded a blank `$image` in the hyprland template after discovering matugen 4.1.0 never populates `colors.image` in either render mode (a correction to 01-RESEARCH.md); left the 4 now-dead legacy scripts (walker-restart.sh, walker-theme-gen.sh, gtk-reload.sh, vscodium-theme.sh) in place since Plan 01-03 explicitly owns retiring 3 of them; added `theme-engine` to `stow.sh` since a fresh install would otherwise never wire the new package.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] matugen's `{{colors.image}}` throws ResolveError in both render modes, not just `matugen json`**
- **Found during:** Task 1, live verification of the dynamic (`matugen image`) render path
- **Issue:** 01-RESEARCH.md's Pitfall documented that a blank `colors.image` JSON key was sufficient for the static path; empirical testing this session showed `matugen image` ALSO never populates `colors.image` in its context, even with the original `[config.wallpaper]` block present — this is a previously-undocumented finding that blocked the dynamic mode from rendering at all.
- **Fix:** Hardcoded `$image =` (blank, no template interpolation) in `hyprland-colors.conf`; `$image` is only consumed by `hyprlock.conf` which is explicitly out of scope this milestone (PROJECT.md).
- **Files modified:** `matugen/.config/matugen/templates/hyprland-colors.conf`
- **Verification:** Both `matugen json <preset>` and `matugen image <wallpaper>` render all 10 contract files with exit 0 after the fix.
- **Committed in:** df4a750 (Task 1 commit)

**2. [Rule 3 - Blocking] Untracking walker/yazi generated files had to land inside Task 2, not Task 3**
- **Found during:** Task 2, first live `theme-apply catppuccin` run
- **Issue:** `~/.config/walker` and `~/.config/yazi` are whole-package stow symlinks directly into this repo. `theme-apply`'s own `lib/commit.sh` (a Task 2 deliverable) creates symlinks at `walker/themes/rice/style.css` and `yazi/theme.toml` for apps with no import mechanism (D-07) — running it against the still-tracked files from Task 2's own verification would have corrupted git-tracked repo content.
- **Fix:** `git rm` (untrack + delete) `walker/.config/walker/themes/rice/style.css` and `yazi/.config/yazi/theme.toml`, and added matching `.gitignore` entries, before running Task 2's live verification. This work is PIPE-03/D-07 scope that the plan assigned to Task 3, but was an unavoidable prerequisite for Task 2's own verification to run safely.
- **Files modified:** `.gitignore`, `walker/.config/walker/themes/rice/style.css` (deleted), `yazi/.config/yazi/theme.toml` (deleted)
- **Verification:** `theme-apply catppuccin` runs clean, `git status --short` shows no untracked clutter at those paths afterward.
- **Committed in:** 11e16ef (Task 2 commit)

**3. [Rule 1 - Bug] Background daemon relaunches held the caller's stdio pipe open**
- **Found during:** Task 2, live verification (`bash -x theme-apply catppuccin | tail` hung indefinitely)
- **Issue:** The original walker-restart.sh/gtk-reload.sh pattern (`uwsm app -- walker --gapplication-service & disown`) doesn't redirect stdio. A long-running daemon backgrounded this way inherits the caller's file descriptors; any caller that pipes theme-apply's output (e.g. a wrapper capturing logs) hangs forever waiting for EOF that never comes.
- **Fix:** Added `setsid ... >/dev/null 2>&1 </dev/null &` to both the walker relaunch (`lib/reload.sh`) and the Thunar daemon relaunch (`lib/gtk.sh`).
- **Files modified:** `theme-engine/.config/theme-engine/lib/reload.sh`, `theme-engine/.config/theme-engine/lib/gtk.sh`
- **Verification:** `theme-apply catppuccin > file 2>&1` completes and returns promptly; walker process confirmed running afterward via `pgrep`.
- **Committed in:** 11e16ef (Task 2 commit)

**4. [Rule 3 - Blocking] `rsync -a` silently reverted the state dir's 0700 permission to 0755**
- **Found during:** Task 2, live verification
- **Issue:** `commit.sh` chmod'd the state dir to 0700 BEFORE `rsync -a --delete`; rsync's archive mode syncs the destination directory's own mode from the (0755, umask-created) source, silently undoing the chmod (T-02-03 threat mitigation would have been violated).
- **Fix:** Moved the `chmod 700` call to AFTER the rsync step.
- **Files modified:** `theme-engine/.config/theme-engine/lib/commit.sh`
- **Verification:** `stat -c "%a %n" ~/.local/state/theme` reports `700` after a live `theme-apply` run.
- **Committed in:** 11e16ef (Task 2 commit)

**5. [Rule 2 - Missing Critical] `stow.sh` never wired the new `theme-engine` package**
- **Found during:** Task 3, final review
- **Issue:** Without `theme-engine` in `stow.sh`'s `PACKAGES` array, a fresh install would never symlink `~/.config/theme-engine`, and every caller (`theme-switch.sh`, `theme-init.sh`, `wallpaper-picker.sh`) would fail to find `theme-apply` on a clean system — breaking the project's explicit "reproduces from scratch with one script" constraint.
- **Fix:** Added `theme-engine` to `PACKAGES`; also removed the now-dead `~/.cache/current-theme` pre-seed line (theme-init.sh's D-10 fallback makes it redundant, and it referenced the retired state-file location).
- **Files modified:** `stow.sh`
- **Verification:** `stow -n theme-engine` reports no conflicts; package now actually stowed live on this machine.
- **Committed in:** 9b448fe (Task 3 commit)

---

**Total deviations:** 5 auto-fixed (2 Rule 1 bug fixes, 2 Rule 3 blocking-issue fixes, 1 Rule 2 missing-critical-functionality fix)
**Impact on plan:** All five were necessary for the engine to function correctly or safely on this specific machine's stow topology; none changed the plan's architecture or scope. Deviation #2 pulled a small, unavoidable slice of Task 3's PIPE-03 scope earlier than planned.

## Issues Encountered

- Kitty's `include ~/.local/state/theme/kitty.conf` (tilde-expanded, non-relative include path) could not be exhaustively verified against kitty's own config-validation tooling (no `--debug-config`-equivalent flag in this kitty version) — verified indirectly via a clean `kitty -e true` run (no stderr) and kitty's documented tilde-expansion behavior for `include`. Recommend a visual spot-check during Plan 01-03 or the phase's UAT pass.
- `awww img` failed in this non-interactive execution session ("none of the requested outputs are valid") when `theme-init.sh` ran — this is an environment limitation of the exec context (no attached Wayland output), not a script bug; `theme-init.sh` has no `set -e` so it degrades gracefully and still calls `theme-apply`, which succeeded. Worth a normal-session recheck but not blocking.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Plan 01-03 (per-app hardening) can proceed. Specifically ready for it:
- `theme-engine/lib/reload.sh`'s walker restart is already bounded-poll'd + elephant-health-checked, but 01-03's task 1 plans further hardening — it will find `lib/reload.sh` already inlines the logic (no longer calls the legacy `walker-restart.sh`), which should make that task mostly a "confirm + retire the dead file" pass rather than new implementation.
- `lib/gtk.sh`'s Thunar restart is already bounded-poll (no `sleep 0.5`); 01-03's task 2 should similarly find this already done and focus on the "retire gtk-reload.sh" half of its scope.
- The 4 legacy scripts (`walker-restart.sh`, `walker-theme-gen.sh`, `gtk-reload.sh`, `vscodium-theme.sh`) are unreferenced anywhere but intentionally left on disk for Plan 01-03 to formally retire (its own `<files>` list names 3 of them).
- Live desktop is in a clean resting state on this machine (`current-theme` = catppuccin, `theme-doctor` reports 17/17 pass).

No blockers.

## Known Stubs

None — every deliverable in this plan is wired to real data (the state-dir contract), no placeholder/mock paths were introduced.

## Threat Flags

None beyond what the plan's own threat model already covered (T-02-01/02/03, all mitigated as specified — argument validation, notification sanitization, and state-dir permissions were each implemented and live-verified this session).

---
*Phase: 01-root-cause-fix-consolidated-theme-engine*
*Completed: 2026-07-07*

## Self-Check: PASSED

- theme-engine/.config/theme-engine/theme-apply — FOUND
- theme-engine/.config/theme-engine/theme-doctor — FOUND
- theme-engine/.config/theme-engine/lib/generate.sh — FOUND
- theme-engine/.config/theme-engine/lib/commit.sh — FOUND
- theme-engine/.config/theme-engine/lib/reload.sh — FOUND
- theme-engine/.config/theme-engine/lib/gtk.sh — FOUND
- theme-engine/.config/theme-engine/palettes/catppuccin.json — FOUND
- theme-engine/.config/theme-engine/palettes/tokyonight.json — FOUND
- Commit df4a750 — FOUND
- Commit 11e16ef — FOUND
- Commit 9b448fe — FOUND
