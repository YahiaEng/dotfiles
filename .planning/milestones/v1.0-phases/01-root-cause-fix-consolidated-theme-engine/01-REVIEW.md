---
phase: 01-root-cause-fix-consolidated-theme-engine
reviewed: 2026-07-07T19:45:00Z
depth: standard
files_reviewed: 34
files_reviewed_list:
  - gtk/.config/gtk-3.0/gtk.css
  - gtk/.config/gtk-4.0/gtk.css
  - hypr/.config/hypr/config/autostart.conf
  - hypr/.config/hypr/config/env.conf
  - hypr/.config/hypr/config/keybinds.conf
  - hypr/.config/hypr/hyprland.conf
  - hypr/.config/hypr/hyprlock.conf
  - hypr/.config/hypr/scripts/theme-init.sh
  - hypr/.config/hypr/scripts/theme-switch.sh
  - hypr/.config/hypr/scripts/wallpaper-picker.sh
  - install.sh
  - kitty/.config/kitty/kitty.conf
  - matugen/.config/matugen/config.toml
  - matugen/.config/matugen/templates/hyprland-colors.conf
  - matugen/.config/matugen/templates/walker-style.css
  - matugen/.config/matugen/templates/yazi-theme.toml
  - swaync/.config/swaync/style.css
  - theme-engine/.config/theme-engine/theme-apply
  - theme-engine/.config/theme-engine/theme-doctor
  - theme-engine/.config/theme-engine/lib/commit.sh
  - theme-engine/.config/theme-engine/lib/generate.sh
  - theme-engine/.config/theme-engine/lib/gtk.sh
  - theme-engine/.config/theme-engine/lib/reload.sh
  - theme-engine/.config/theme-engine/palettes/catppuccin.json
  - theme-engine/.config/theme-engine/palettes/dracula.json
  - theme-engine/.config/theme-engine/palettes/gruvbox.json
  - theme-engine/.config/theme-engine/palettes/nord.json
  - theme-engine/.config/theme-engine/palettes/rosepine.json
  - theme-engine/.config/theme-engine/palettes/tokyonight.json
  - waybar/.config/waybar/style-floating.css
  - waybar/.config/waybar/style-full.css
  - waybar/.config/waybar/style-minimal.css
  - wlogout/.config/wlogout/style.css
  - yazi/.config/yazi/yazi.toml
findings:
  critical: 2
  warning: 10
  info: 11
  total: 23
status: issues_found
---

# Phase 01: Code Review Report

**Reviewed:** 2026-07-07T19:45:00Z
**Depth:** standard
**Files Reviewed:** 34
**Status:** issues_found

## Summary

Reviewed the consolidated theme-engine (entrypoint + 4 libs + 6 palettes), its thin callers (theme-init, theme-switch, wallpaper-picker), all consumer configs (hyprland, hyprlock, kitty, waybar x3, swaync, wlogout, yazi, GTK3/4), matugen config + templates, and install.sh. Several claims in code comments were verified against the live system: `awww` is a real official-repo package (0.12.1-1), `matugen json` is a real subcommand, `elephant version`/`elephant listproviders` respond in the format theme-doctor parses, walker's config selects `theme = "rice"`, stow.sh covers the `theme-engine` package, `accent_color` exists in the gtk-colors.css template that gtk.sh greps, and all matugen `input_path` templates exist in-repo. The waybar/swaync/wlogout/GTK `@import`/`include`/`source` relative paths all correctly resolve to `~/.local/state/theme/`. The `set -e` arithmetic-increment footgun called out in the phase context is correctly avoided everywhere (`x=$((x+1))` used consistently).

The engine core is well-reasoned, but the review found two Critical defects in `install.sh` that break the project's stated reproducibility constraint (a missing runtime dependency for the engine's commit step, and a cleanup line that aborts the installer on the common zero-orphans path), plus a cluster of race/robustness gaps in the process-lifecycle code: the Thunar relaunch lacks the exact D-Bus name-release gate that was diagnosed and fixed for walker, the deferred-watcher lock has a pid-file publication race, and `theme-apply` itself has no concurrency guard despite having multiple independent triggers.

## Critical Issues

### CR-01: `install.sh` does not install `rsync`, which the engine's atomic commit hard-requires

**File:** `install.sh:41-141` (package lists) / `theme-engine/.config/theme-engine/lib/commit.sh:30`
**Issue:** `theme_engine_commit` performs the entire state-dir replace with `rsync -a --delete` (commit.sh:30). `rsync` appears nowhere in `PACMAN_PKGS` or `AUR_PKGS` (verified: `grep rsync install.sh` matches nothing), and rsync is not part of an Arch base install nor a dependency of any listed package. On a fresh system installed via `install.sh` + `stow.sh`, the very first login runs `theme-init.sh` → `theme-apply catppuccin`, which renders successfully, then dies at commit with `rsync: command not found` under `set -euo pipefail`. Result: the state dir is never populated, so hyprland/kitty/waybar/swaync/wlogout/GTK all reference nonexistent color files and the desktop comes up permanently unthemed — the exact "one script reproduces everything" core constraint is broken.
**Fix:**
```bash
# install.sh — add to PACMAN_PKGS under "Utilities"
    rsync
```

### CR-02: Orphan-cleanup line aborts the installer on the common case and can never remove multiple orphans

**File:** `install.sh:196`
**Issue:** `paru -R "$(pacman -Qtdq)"` has three independent bugs:
1. On a system with **zero orphans** (the normal case for a fresh install), `pacman -Qtdq` prints nothing, so this executes `paru -R ""`, which fails — and under `set -euo pipefail` the whole script aborts here, **skipping every post-install task below** (VSCodium extensions, audio service enablement, git config, dbus-broker enablement, the entire limine bootloader update, timezone).
2. With **more than one orphan**, the quoted command substitution joins all package names into a single argument (`paru -R "pkg1 pkg2"`), which fails as "package not found".
3. It hardcodes `paru` even though the script detects and supports `yay` via `$AUR_HELPER` (install.sh:22-34).
**Fix:**
```bash
mapfile -t ORPHANS < <(pacman -Qtdq || true)
if (( ${#ORPHANS[@]} > 0 )); then
    "$AUR_HELPER" -R --noconfirm "${ORPHANS[@]}"
fi
"$AUR_HELPER" -Sc
```

## Warnings

### WR-01: `theme-apply` has no concurrency guard — concurrent applies interleave destructively

**File:** `theme-engine/.config/theme-engine/theme-apply:60-83` / `lib/commit.sh:30`
**Issue:** `theme-apply` can be triggered concurrently from at least three independent paths: the Super+T picker (`theme-switch.sh`), the wallpaper picker's auto-regeneration (`wallpaper-picker.sh:140`), and login init (`theme-init.sh`). Two overlapping runs interleave `rsync -a --delete` from different palettes into the same `$STATE_DIR` (mixed-theme state), double-fire the walker kill/poll/relaunch (re-creating the very bus-name race reload.sh works so hard to avoid), and race on `current-theme`. Nothing serializes them. Also note the "atomic replace" claim in commit.sh is per-file at best — `rsync --delete` is not atomic across the file set, and `current-theme` is deleted by `--delete` and only rewritten afterwards (commit.sh:39), leaving a crash window where the saved theme is lost (theme-init then silently falls back to catppuccin).
**Fix:** Wrap the whole apply in an exclusive lock near the top of `theme-apply`:
```bash
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/theme-apply.lock"
flock -w 30 9 || { echo "theme-apply: another apply in progress" >&2; exit 1; }
```

### WR-02: Thunar relaunch lacks the D-Bus name-release gate that walker required

**File:** `theme-engine/.config/theme-engine/lib/gtk.sh:106-121` (immediate path) and `gtk.sh:169-181` (watcher path)
**Issue:** reload.sh:78-103 documents, with an empirical reproduction, that killing a D-Bus single-instance app and relaunching the moment `pgrep` stops seeing the PID races the session bus's name-release bookkeeping — producing an unregistered/absent instance. Thunar is exactly such an app (`org.xfce.FileManager`, single-instance — gtk.sh's own comments at lines 42-50 establish this), yet both Thunar relaunch sites go straight from the pgrep-gone poll (or `killall -9`, which gets **no** exit wait at all before relaunch) to `thunar --daemon`. If the old name registration is still draining, the new `thunar --daemon` hands off to the dying owner and exits — no daemon is left running, and the next theme switch's `pgrep -x thunar` gate (gtk.sh:51) then skips the restart logic entirely, so the stale-CSS problem this phase set out to fix can silently reappear.
**Fix:** Mirror the walker gate before each `setsid uwsm app -- thunar --daemon`:
```bash
if command -v busctl >/dev/null 2>&1; then
    local twaited=0
    while busctl --user status org.xfce.FileManager >/dev/null 2>&1 && (( twaited < 20 )); do
        sleep 0.1
        twaited=$(( twaited + 1 ))
    done
fi
```

### WR-03: Deferred-watcher lock pid file is published by the child — stale-lock self-heal can nuke a live lock and stack watchers

**File:** `theme-engine/.config/theme-engine/lib/gtk.sh:78-99, 147, 189`
**Issue:** The parent `mkdir`s the lock (line 96), then detaches the watcher, and only the **watcher itself** writes `$lock_dir/pid` (line 147). A second `theme-apply` arriving before the watcher has been scheduled and written its pid sees a lock dir with no pid file, concludes it is stale (line 81: empty `existing_pid` → `rm -rf`), deletes the live lock, and spawns a second watcher. Worse, when the first watcher finishes it runs `rm -rf "$lock_dir"` (line 189) on a lock dir that now belongs to the second watcher, re-opening the door for a third — the dedupe guarantee the mkdir lock exists to provide is void exactly under the rapid-consecutive-switch scenario it was built for. Secondary nit: `kill -0 "$existing_pid"` treats any recycled PID as a live watcher.
**Fix:** Publish the pid from the parent, immediately after spawning, so the lock is never observable without it:
```bash
if mkdir "$lock_dir" 2>/dev/null; then
    export -f theme_engine_thunar_deferred_watcher 2>/dev/null || true
    setsid bash -c "theme_engine_thunar_deferred_watcher '$lock_dir'" >/dev/null 2>&1 </dev/null &
    echo $! > "$lock_dir/pid"
    disown
fi
```
(and drop the `echo $$ > pid` in the watcher, or keep it as a redundant refresh).

### WR-04: VSCodium merge silently no-ops forever if settings.json is JSONC

**File:** `theme-engine/.config/theme-engine/lib/reload.sh:181-193`
**Issue:** VSCodium's `settings.json` is JSONC — the editor itself accepts comments and trailing commas, and hand-edited settings files very commonly contain them. `jq -s '.[0] * .[1]'` fails on any such file; the failure path (`|| rm -f "${settings}.tmp"`) discards the merge with stderr sent to `/dev/null`, so VSCodium simply never follows theme switches again with zero signal — contravening this phase's own loud-failure pattern (theme-apply notifies on render failure; reload.sh notifies on walker failure). The user-visible symptom is indistinguishable from the original bug class this phase fixes.
**Fix:** Notify on merge failure so it's diagnosable:
```bash
if ! jq -s '.[0] * .[1]' "$settings" "$theme_data" > "${settings}.tmp" 2>/dev/null; then
    rm -f "${settings}.tmp"
    notify-send -a "Theme Switcher" "Warning" \
        "VSCodium settings.json could not be parsed (comments/trailing commas?) — editor theme not updated" \
        -t 4000 2>/dev/null || true
    return 0
fi
mv "${settings}.tmp" "$settings"
```

### WR-05: Theme-name validation permits path traversal, contradicting its own security comment

**File:** `theme-engine/.config/theme-engine/theme-apply:45-58`
**Issue:** The comment claims the argument is validated "against the ACTUAL palette filenames before it is ever interpolated into a filesystem path", but the check is the opposite: it interpolates first (`$PALETTES_DIR/$NAME.json`) and only tests existence. `theme-apply '../../../home/aorus/anything'` passes validation whenever the traversed `.json` file exists, and that arbitrary JSON is then fed to `matugen json` and its name written to `current-theme` (and echoed into notify-send). Exposure is low (local trusted callers only), but the implementation does not do what the Security Domain V5 comment asserts, and `current-theme` re-feeds the value at every login via theme-init.
**Fix:** Validate the shape before building the path:
```bash
if [[ "$NAME" != "materialyou" ]]; then
    if [[ ! "$NAME" =~ ^[a-z0-9_-]+$ ]] || [[ ! -f "$PALETTES_DIR/$NAME.json" ]]; then
        ... reject ...
    fi
fi
```

### WR-06: hyprlock background references `$image`, which the template deliberately renders empty

**File:** `hypr/.config/hypr/hyprlock.conf:17` / `matugen/.config/matugen/templates/hyprland-colors.conf:31`
**Issue:** The template intentionally emits `$image =` (blank) because matugen 4.1.0 cannot populate it, but `hyprlock.conf` still consumes it as `path = $image`. Every lock therefore parses an empty background path — hyprlock logs a config error and falls back to a solid fill, so the lock screen background is broken by construction on every theme, static or dynamic. The template comment declares hyprlock theming out of scope, but leaving a consumer wired to a knowingly-empty variable is a live defect, not a deferral.
**Fix:** Point the background at a value that exists:
```
path = screenshot
```
or `path = $HOME/Pictures/Wallpapers/current.jpg` (the engine-owned wallpaper symlink), and drop the dead `$image =` line from the template once nothing references it.

### WR-07: Fresh-install first boot references a nonexistent state dir — no seeded baseline

**File:** `hypr/.config/hypr/hyprland.conf:15`, `kitty/.config/kitty/kitty.conf:63`, `waybar/.config/waybar/style-*.css:1`, `install.sh` / `stow.sh` (no seeding step)
**Issue:** Every consumer sources/includes/imports `~/.local/state/theme/*`, but nothing in the install flow creates that dir — it first exists ~2 seconds after first login when `theme-init.sh` fires (autostart.conf:40). During that window Hyprland parses `source = ~/.local/state/theme/hyprland.conf` against a missing file, leaving `$primary/$secondary/$tertiary/$outline` undefined → `col.active_border`/`col.inactive_border` config errors and the red error banner on the user's very first impression of the rice; kitty windows opened early get no colors until restart. This is transient only if theme-apply succeeds (see CR-01 for the case where it doesn't, making this state permanent).
**Fix:** Seed the baseline once at install time, after stow:
```bash
# stow.sh / install.sh post-step
~/.config/theme-engine/theme-apply catppuccin || true
```
(or ship a pre-rendered default state dir). This also removes the reliance on the `sleep 2` heuristic being long enough on slow boots.

### WR-08: Installer deletes the bootloader config with no backup and breaks re-runs

**File:** `install.sh:236-239`
**Issue:** `sudo rm /boot/limine/limine.conf` (a) has no `-f`, so on a re-run after a previous pass already removed/regenerated differently, a missing file aborts the whole script under `set -e`; (b) destroys the boot menu config *before* `limine-install`/`limine-update` have succeeded — if either fails (or the script is interrupted between), the machine is left with no limine.conf and no backup. This is the one line in the repo with real data-loss/unbootable-system potential.
**Fix:**
```bash
[[ -f /boot/limine/limine.conf ]] && sudo cp /boot/limine/limine.conf /boot/limine/limine.conf.bak
sudo rm -f /boot/limine/limine.conf
```

### WR-09: paru bootstrap is not idempotent (`/tmp/paru` clone)

**File:** `install.sh:31-32`
**Issue:** `git clone https://aur.archlinux.org/paru.git /tmp/paru` fails if `/tmp/paru` exists from a prior aborted run (a likely state, given CR-02 makes aborts common), killing the script under `set -e` at the very first step of a retry. Fixed predictable `/tmp` paths are also mildly unsafe on shared machines.
**Fix:**
```bash
PARU_BUILD=$(mktemp -d)
git clone https://aur.archlinux.org/paru.git "$PARU_BUILD/paru"
(cd "$PARU_BUILD/paru" && makepkg -si --noconfirm)
```

### WR-10: `style-floating.css` hardcodes Catppuccin hexes — those modules never follow a theme switch

**File:** `waybar/.config/waybar/style-floating.css:189-233`
**Issue:** `#backlight`, `#battery`, `#battery.charging`, `#battery.critical`, and the `blink` keyframes use literal `#161320`/`#F8BD96`/`#B5E8E0`/`#BF616A` instead of the `@`-named colors used by every other rule in the same file. Switching to Gruvbox/Nord/Material You leaves these segments in Catppuccin colors — a direct violation of the project's core value ("one theme switch … consistently re-themes the entire desktop") inside a file that was already migrated to the state-dir contract on line 1.
**Fix:** Replace with palette names, e.g. `#backlight { color: @on_secondary; background: @secondary; }`, `#battery { color: @on_tertiary; background: @tertiary; }`, `@keyframes blink { to { background-color: @error; color: @on_error; } }`.

## Info

### IN-01: Dead diagnostic variables in the elephant health gate

**File:** `theme-engine/.config/theme-engine/lib/reload.sh:129-132`
**Issue:** `elephant_v`/`walker_v` are computed and defaulted (`: "${elephant_v:=unknown}"`) under a comment saying "log both for diagnostics", but nothing ever logs or uses them — two subprocess spawns per theme switch for nothing.
**Fix:** Either append them to `$log_file` (`echo "elephant=$elephant_v walker=$walker_v" >> "$log_file"`) or delete the block.

### IN-02: Orphaned template `wofi-colors.css`

**File:** `matugen/.config/matugen/templates/wofi-colors.css`
**Issue:** No `[templates.*]` entry in matugen config.toml and no other reference in the repo (verified by grep); wofi itself survives only as commented-out keybinds. Dead file inviting confusion about the state-dir contract.
**Fix:** Delete it (and consider dropping `wofi` from PACMAN_PKGS if it is truly retired).

### IN-03: gtk.sh hardcodes `adw-gtk3-dark` despite its "never hardcodes a theme name" header

**File:** `theme-engine/.config/theme-engine/lib/gtk.sh:24` (vs. header claim at lines 5-8)
**Issue:** The file's contract says GTK_THEME's single source of truth is `uwsm/env` and that this script "never hardcodes/re-exports a literal theme name itself", yet line 24 writes the literal `adw-gtk3-dark` into gsettings. Two sources of truth (uwsm/env:17 and this line) that can silently drift.
**Fix:** `gsettings set org.gnome.desktop.interface gtk-theme "${GTK_THEME:-adw-gtk3-dark}"`.

### IN-04: Error notification body can be empty when the render log is empty

**File:** `theme-engine/.config/theme-engine/theme-apply:66-71`
**Issue:** The `[[ -f "$ERROR_LOG" ]]` guard replaces the default summary even when matugen failed with empty stderr (the redirection in generate.sh always creates/truncates the log), producing an "Error" toast with a blank body.
**Fix:** Use `[[ -s "$ERROR_LOG" ]]` so the default message survives an empty log. Consider also escaping `&`, `<`, `>` in `ERROR_SUMMARY` since some notification daemons (including swaync) parse the body as Pango markup.

### IN-05: `STATE_DIR` defined independently in three files

**File:** `theme-apply:19`, `lib/commit.sh:9`, `lib/reload.sh:11` (plus the literal path in `lib/gtk.sh:199` and `lib/generate.sh:12`)
**Issue:** Five places encode `~/.local/state/theme`; changing the contract requires touching all of them in lockstep. The libs are only ever sourced by theme-apply, which already defines it.
**Fix:** Define once in `theme-apply` (respecting `${XDG_STATE_HOME:-$HOME/.local/state}` while at it) and let the sourced libs use it; guard with `: "${STATE_DIR:?}"` in each lib.

### IN-06: Fixed predictable /tmp log path in theme-doctor

**File:** `theme-engine/.config/theme-engine/theme-doctor:64`
**Issue:** `2>/tmp/theme-doctor-stow.log` is a fixed world-writable-directory path (symlink-clobber risk on multi-user systems) and the log is never surfaced to the user on failure anyway.
**Fix:** `stow_log=$(mktemp)` and print its path in the FAIL line, or drop the redirect and let stderr show inline.

### IN-07: Residual hardcoded Catppuccin colors in wallpaper-picker fzf UI and hyprlock placeholder

**File:** `hypr/.config/hypr/scripts/wallpaper-picker.sh:96-98`, `hypr/.config/hypr/hyprlock.conf:81`
**Issue:** fzf `--color` values and the hyprlock `placeholder_text` foreground (`##a6adc8`) are literal Catppuccin hexes — cosmetic theme drift on non-Catppuccin themes. Same class as WR-10 but lower-visibility surfaces.
**Fix:** Acceptable to leave; if desired, render an fzf color string via a small state-dir template and use `$on_surface_variant` for the hyprlock placeholder.

### IN-08: `PREVIOUS_FILE` is persisted to disk but never read across runs

**File:** `hypr/.config/hypr/scripts/wallpaper-picker.sh:19, 26, 118, 147`
**Issue:** `~/.cache/wallpaper-picker-previous` is written at start and removed at both exits; the restore path uses the in-memory `$PREVIOUS_WALLPAPER`, never the file. If the picker is SIGKILLed, the file lingers unused. Dead persistence.
**Fix:** Drop the file entirely, or use it to implement crash-restore.

### IN-09: `generate.sh` depends on the caller's `$PALETTES_DIR` global

**File:** `theme-engine/.config/theme-engine/lib/generate.sh:40`
**Issue:** `$PALETTES_DIR` is defined only in `theme-apply`; sourcing generate.sh anywhere else and calling `theme_engine_generate` with a preset name explodes under `set -u`. Implicit cross-file coupling with no guard.
**Fix:** Add `: "${PALETTES_DIR:?generate.sh requires PALETTES_DIR}"` at the top of the function, or pass it as a parameter.

### IN-10: `killall -q walker` also kills in-flight `walker --dmenu` clients; relaunch is unconditional

**File:** `theme-engine/.config/theme-engine/lib/reload.sh:51, 145`
**Issue:** A theme switch fired while a `walker --dmenu` pipeline is open (e.g. the clipboard picker, keybinds.conf:45, or a theme-switch on another seat/trigger) kills that client mid-selection, and the relaunch starts the gapplication service even if the user had intentionally stopped walker. Narrow, single-user impact — noting for awareness.
**Fix:** Acceptable as-is for this desktop; a stricter kill would target only the `--gapplication-service` instance (e.g. `pkill -f 'walker --gapplication-service'`), at the cost of leaving dmenu clients on the old CSS.

### IN-11: `swaync` listed under AUR packages but lives in the official `extra` repo

**File:** `install.sh:149`
**Issue:** `pacman -Si swaync` resolves to `extra/swaync 0.12.6-1`; installing it via the AUR helper works (helpers resolve repo packages first) but misfiles it and slows the AUR pass.
**Fix:** Move `swaync` to `PACMAN_PKGS`.

---

_Reviewed: 2026-07-07T19:45:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
