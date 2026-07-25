---
phase: 09-wlogout-to-wleave-migration
reviewed: 2026-07-25T00:00:00Z
depth: standard
files_reviewed: 27
files_reviewed_list:
  - hypr/.config/hypr/scripts/wleave.sh
  - hypr/.config/hypr/scripts/ai-workspace.sh
  - install.sh
  - stow.sh
  - theme-engine/.config/theme-engine/theme-doctor
  - theme-engine/.config/theme-engine/theme-stress-test
  - hypr/.config/hypr/config/keybinds.conf
  - hypr/.config/hypr/config/windowrules.conf
  - hypr/.config/hypr/config/autostart.conf
  - elephant/.config/elephant/menus/main.toml
  - matugen/.config/matugen/config.toml
  - waybar/.config/waybar/modules.jsonc
  - waybar/.config/waybar/config-floating.jsonc
  - theme-engine/.config/theme-engine/contract.json
  - wleave/.config/wleave/layout.json
  - wleave/.config/wleave/style.css
  - matugen/.config/matugen/templates/wleave-colors.css
  - theme-engine/.config/theme-engine/palettes/catppuccin.json
  - theme-engine/.config/theme-engine/palettes/catppuccin-latte.json
  - theme-engine/.config/theme-engine/palettes/dracula.json
  - theme-engine/.config/theme-engine/palettes/ethereal.json
  - theme-engine/.config/theme-engine/palettes/everfrost.json
  - theme-engine/.config/theme-engine/palettes/gruvbox.json
  - theme-engine/.config/theme-engine/palettes/gruvbox-light.json
  - theme-engine/.config/theme-engine/palettes/hackerman.json
  - theme-engine/.config/theme-engine/palettes/kanagawa.json
  - theme-engine/.config/theme-engine/palettes/kanagawa-lotus.json
  - theme-engine/.config/theme-engine/palettes/matte-black.json
  - theme-engine/.config/theme-engine/palettes/miasma.json
  - theme-engine/.config/theme-engine/palettes/nord.json
  - theme-engine/.config/theme-engine/palettes/osaka-jade.json
  - theme-engine/.config/theme-engine/palettes/ristretto.json
  - theme-engine/.config/theme-engine/palettes/rosepine-dawn.json
  - theme-engine/.config/theme-engine/palettes/rosepine.json
  - theme-engine/.config/theme-engine/palettes/tokyonight-day.json
  - theme-engine/.config/theme-engine/palettes/tokyonight.json
  - theme-engine/.config/theme-engine/palettes/vantablack.json
  - .claude/CLAUDE.md
  - VERIFICATION.md
findings:
  critical: 0
  warning: 3
  info: 2
  total: 5
status: issues_found
---

# Phase 09: Code Review Report

**Reviewed:** 2026-07-25
**Depth:** standard
**Files Reviewed:** 27 distinct source files (plus 20 palette JSON files enumerated individually above)
**Status:** issues_found

## Summary

Reviewed the wlogout → wleave power-menu cutover: the new `wleave.sh` launcher, `layout.json`/`style.css`, the matugen template, all three UI entry-point wirings (keybind, two waybar layouts, elephant menu), `install.sh`/`stow.sh` reproducibility, the theme-engine gates (`contract.json`, `theme-doctor`, `theme-stress-test`), all 20 static palette JSON edits, and the wlogout retirement completeness.

Overall the migration is solid and unusually well-verified — `shellcheck` is clean on `wleave.sh`, `bash -n` is clean on `install.sh`/`stow.sh`/`theme-doctor`/`theme-stress-test`, both waybar JSONC files parse after comment-stripping, `elephant/menus/main.toml` and `matugen/config.toml` parse as valid TOML, all 20 palette JSON files are well-formed and each carries all 23 required M3 color keys (independently verified, not just trusted from the SUMMARY), the `on_tertiary_container`/`error_container`/`on_error_container` values are plausibly derived and internally consistent across every file, and the rendered `wleave.css` for the currently-active preset resolves all 23 tokens correctly with `primary_container == secondary_container` (confirming the root-cause the 09-04 alpha retune cites). I additionally checked the actual installed `wleave` binary's man page to independently verify that `action` strings are executed as real shell commands (not a bare `execvp` split) — confirmed, so the semicolon-chained `cliphist wipe; ...` actions are not at injection or parsing risk.

No Critical/Blocker findings. Three Warnings and two Info items below, all robustness/completeness gaps rather than functional breakage — none of them contradict the `<known_and_accepted>` list.

## Warnings

### WR-01: `wleave.sh` has no guard against duplicate/stacked invocations

**File:** `hypr/.config/hypr/scripts/wleave.sh:1-25`
**Issue:** The script's own header comment explicitly documents that toggle logic was deliberately dropped (D-18: "no toggle branch, and no liveness scan of any other running instance"). That is a reasonable simplification versus the retired engine's toggle, but it also means nothing prevents two (or more) `wleave` processes from being spawned if the launcher fires twice in quick succession — e.g., a user double-clicking the waybar power button, or triggering the keybind and the elephant "Power" entry moments apart before the first surface is dismissed. `wleave` is invoked bare (`wleave &`), never with its documented `-s`/`--service` single-instance/service flag (confirmed via `wleave --help`), so each invocation is a fully independent process/layer-shell surface. If two surfaces stack, dismissing the topmost with Escape only closes that instance — the other(s) remain, leaving the screen dimmed/blocked, which reads as "the menu won't close" to the user until Escape is pressed again for each stacked instance.
**Fix:** Add a liveness check for an already-running `wleave` before spawning a new one, e.g.:
```bash
if pgrep -x wleave >/dev/null 2>&1; then
    exit 0   # a surface is already open; do nothing (or: pkill -x wleave to toggle)
fi
```
or invoke `wleave -s` in service mode so the binary itself owns single-instance semantics, if that mode fits the "open-only" design intent.

### WR-02: `wleave.sh`'s liveness check uses a fixed, unretried 300ms sleep

**File:** `hypr/.config/hypr/scripts/wleave.sh:20-24`
**Issue:** `sleep 0.3` followed by a single `kill -0` is the only signal used to decide whether to report "wleave failed to launch". Under load (cold page cache after boot, a concurrent `theme-apply` re-render, or a slow disk), a GTK4 binary loading a stylesheet, six SVG icons, and matugen-generated CSS can plausibly take longer than 300ms to become live without actually being broken — the check has no retry/backoff, so a slow-but-successful launch produces a spurious `-u critical` "wleave failed to launch" notification even though the menu is about to (or already did) appear.
**Fix:** Either loosen this to a short retry loop (e.g., check at 100ms/300ms/600ms before giving up) or drop the fixed-delay heuristic in favor of watching for the compositor layer to appear (`hyprctl -j layers`) within a bounded timeout, which is a more direct signal of success than "the process didn't crash yet".

### WR-03: `wleave.sh` does not verify the user's own `layout.json` exists before launching

**File:** `hypr/.config/hypr/scripts/wleave.sh:1-25`
**Issue:** Confirmed via direct testing (removing `~/.config/wleave/layout.json` and re-running the script): `wleave` silently falls back to the packaged `/etc/wleave/layout.json` default (an unstyled 3×2 grid using upstream's own default action set, e.g. `loginctl terminate-user $USER` instead of this repo's `cliphist wipe; uwsm stop`) rather than failing or emitting any notification. `wleave.sh`'s only two failure paths (binary-not-installed, process-died-within-300ms) never fire in this case, so the user gets a completely different, unthemed, and functionally different power menu with no indication anything is wrong. This is already logged in `.planning/WINDOWS.md` (entry 6) and `deferred-items.md` (item 4) as a known-but-unfixed gap from this phase's own fault-injection testing — flagged here again because it is a real defect present in the reviewed file, not merely a hypothetical.
**Fix:** Add an existence check before launching:
```bash
if [[ ! -f "$HOME/.config/wleave/layout.json" ]]; then
    notify-send "Power menu" "wleave layout.json missing — falling back to unstyled default" -u critical
fi
```

## Info

### IN-01: Residual "wlogout" reference contradicts the phase's own retirement-completeness claim

**File:** `wleave/.config/wleave/style.css:219`
**Issue:** `09-02-SUMMARY.md` (D4) records "repo-wide grep for the retired tool's name returns zero matches" as a verification gate this phase passed. That was true at the time Task 3 ran the sweep, but `09-03` subsequently added a rationale comment to `style.css` ("Do NOT copy the retired wlogout sheet's pattern...") that reintroduces the literal string "wlogout". A fresh repo-wide grep today (excluding `.planning/`, `.git/`, `settings.local.json`, per the phase's own methodology) returns this one hit, plus the already-excluded `settings.local.json`. Purely cosmetic — it's a rationale comment, not a functional reference — but it means the "zero matches" claim in the phase record is currently stale/inaccurate, and any future automated regression check that greps for "wlogout" to confirm retirement completeness would fail on this line.
**Fix:** Either reword the comment (as was already done for the analogous case in `theme-doctor`, per 09-02's deviation #5) to describe the retired engine without naming it, or explicitly note in the phase record that this one historical/rationale comment is an intentional exception to the "zero matches" claim.

### IN-02: Inconsistent invocation style for `wleave.sh` across entry points

**File:** `waybar/.config/waybar/config-floating.jsonc:82` vs. `waybar/.config/waybar/modules.jsonc:256`, `hypr/.config/hypr/config/keybinds.conf:26`, `elephant/.config/elephant/menus/main.toml:35`
**Issue:** Three of the four wiring points invoke the launcher as a bare path (`~/.config/hypr/scripts/wleave.sh`), relying on the file's executable bit + shebang; `config-floating.jsonc` instead invokes it as `bash ~/.config/hypr/scripts/wleave.sh`. Functionally both work today (the file is `-rwxr-xr-x` and stow/git preserve the executable bit), so this is low-risk, but it is an unexplained inconsistency: if the executable bit were ever lost (e.g., a checkout on a filesystem that doesn't preserve Unix permissions, or a future edit that recreates the file without `chmod +x`), the bare-path entry points (waybar's other layout, the keybind, and the elephant menu) would silently fail with "Permission denied" while only the floating-waybar-layout button would keep working — an inconsistent single point of failure across otherwise-equivalent entry points.
**Fix:** Standardize on one invocation style across all four wiring points (either all bare-path or all `bash`-prefixed) so a permission-bit regression fails uniformly (loudly) rather than partially (confusingly).

---

_Reviewed: 2026-07-25_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
