---
phase: quick
plan: 260709-ciu
subsystem: theme-engine / wallpaper
tags: [reproducibility, symlink, wallpaper-picker, materialyou, INST-03]
dependency-graph:
  requires: []
  provides:
    - relative-tracked-wallpaper-symlink
    - relative-only-wallpaper-picker-links
  affects:
    - theme-engine/lib/generate.sh (materialyou default-wallpaper resolution, unchanged but now unblocked)
tech-stack:
  added: []
  patterns:
    - "ln -sfr (GNU relative symlink) for any symlink created inside a shared/same directory to keep repo state host-portable"
key-files:
  created: []
  modified:
    - wallpapers/Pictures/Wallpapers/current.jpg
    - hypr/.config/hypr/scripts/wallpaper-picker.sh
decisions:
  - "Retargeted the tracked current.jpg symlink to a bare relative filename (shaded-landscape.jpg) instead of relocating/renaming the default wallpaper — matches plan's explicit instruction not to retarget to shaded_landscape.png"
  - "Changed wallpaper-picker.sh's only ln -s call from ln -sf (absolute) to ln -sfr (GNU --relative) so future picks never reintroduce host-absolute paths into the tracked symlink"
metrics:
  duration: 5min
  completed: 2026-07-09
status: complete
---

# Quick Task 260709-ciu: Fix host-absolute wallpaper symlink breaking fresh-install materialyou Summary

Re-created the git-tracked `current.jpg` wallpaper symlink with a relative target and switched the wallpaper picker's link-creation to `ln -sfr`, closing the INST-03 gate finding where a host-absolute symlink dangled on fresh installs and broke materialyou theme-parity.

## What Was Built

**Problem:** `wallpapers/Pictures/Wallpapers/current.jpg` was a git-tracked symlink (mode 120000) whose stored target was the host-absolute path `/home/aorus/Pictures/Wallpapers/shaded-landscape.jpg`. On a fresh Arch install (different `$HOME`/username), that absolute target does not exist, so the symlink dangles. The theme engine's materialyou branch requires a real file behind `current.jpg`, so a fresh install failed the INST-03 gate's materialyou theme-parity case (gate run 20260709T054046Z: 246 passed, 1 failed).

**Fix (one commit, two parts):**

1. **Tracked symlink retargeted relative.** Re-created `current.jpg` with `ln -sfn shaded-landscape.jpg ...` so the stored target is the bare filename `shaded-landscape.jpg` — no leading slash, no host path. Since `shaded-landscape.jpg` is a git-tracked regular file in the same directory, the link resolves correctly for any user after `stow`. Verified: `git diff` shows a clean symlink-target-only change (mode stays 120000, target string changes from the absolute path to `shaded-landscape.jpg`) — no accidental symlink→regular-file conversion.

2. **Wallpaper picker hardened.** In `hypr/.config/hypr/scripts/wallpaper-picker.sh`, the single link-creation site (`ln -sf "$FULL_PATH" "$CURRENT_LINK"`) was changed to `ln -sfr "$FULL_PATH" "$CURRENT_LINK"`. Because both `FULL_PATH` and `CURRENT_LINK` live under the same `$WALLPAPER_DIR`, GNU `ln --relative` collapses the stored target to just the selected filename, matching part 1's relative form. This prevents the picker from ever re-writing the tracked symlink back to a host-absolute path on future wallpaper picks. The cancel/restore path (lines ~110-119) was left untouched per plan — it only replays the previous wallpaper via `awww img` and never recreates the symlink.

No changes were made to `theme-engine/lib/generate.sh`, `theme-apply`, or `REQUIREMENTS.md` — `generate.sh`'s `readlink -f` already resolves relative symlink targets against the symlink's own directory, so no engine-side change was required.

## Verification Evidence

```
$ readlink wallpapers/Pictures/Wallpapers/current.jpg
shaded-landscape.jpg

$ git ls-files -s wallpapers/Pictures/Wallpapers/current.jpg
120000 a36b410... 0	wallpapers/Pictures/Wallpapers/current.jpg   (mode preserved)

$ test -f "$(readlink -f wallpapers/Pictures/Wallpapers/current.jpg)" && echo OK
OK

$ bash -n hypr/.config/hypr/scripts/wallpaper-picker.sh && echo OK
OK

$ shellcheck -S error hypr/.config/hypr/scripts/wallpaper-picker.sh && echo OK
OK

$ grep -cE 'ln -s' hypr/.config/hypr/scripts/wallpaper-picker.sh
1

$ grep -E 'ln -sf?r ' hypr/.config/hypr/scripts/wallpaper-picker.sh
ln -sfr "$FULL_PATH" "$CURRENT_LINK"
```

All plan verification steps passed (single combined command ended with `PASS`).

## Deviations from Plan

None - plan executed exactly as written.

## Commits

- `49536d5` — `fix(03-01): make current.jpg wallpaper symlink relative (host-absolute path broke fresh-install materialyou)`

## Self-Check

- FOUND: wallpapers/Pictures/Wallpapers/current.jpg (relative symlink, mode 120000)
- FOUND: hypr/.config/hypr/scripts/wallpaper-picker.sh (ln -sfr present, exactly one ln -s line)
- FOUND: commit 49536d5 in git log

## Self-Check: PASSED
