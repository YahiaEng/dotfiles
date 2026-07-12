---
phase: 06-themed-surfaces-utility-suite
reviewed: 2026-07-12T20:00:00Z
depth: standard
files_reviewed: 36
files_reviewed_list:
  - hypr/.config/hypr/config/autostart.conf
  - hypr/.config/hypr/config/keybinds.conf
  - hypr/.config/hypr/config/windowrules.conf
  - hypr/.config/hypr/hyprlock.conf
  - hypr/.config/hypr/scripts/capture-full.sh
  - hypr/.config/hypr/scripts/capture-region.sh
  - hypr/.config/hypr/scripts/capture-window.sh
  - hypr/.config/hypr/scripts/clipboard-wipe.sh
  - hypr/.config/hypr/scripts/color-picker.sh
  - hypr/.config/hypr/scripts/emoji-picker.sh
  - hypr/.config/hypr/scripts/font-switcher.sh
  - hypr/.config/hypr/scripts/font-switch.sh
  - hypr/.config/hypr/scripts/gif-export.sh
  - hypr/.config/hypr/scripts/icon-theme-picker.sh
  - hypr/.config/hypr/scripts/icon-theme-switch.sh
  - hypr/.config/hypr/scripts/record-toggle.sh
  - kitty/.config/kitty/kitty.conf
  - matugen/.config/matugen/config.toml
  - matugen/.config/matugen/templates/hyprlock-colors.conf
  - matugen/.config/matugen/templates/satty-colors.toml
  - matugen/.config/matugen/templates/swayosd-colors.css
  - matugen/.config/matugen/templates/zen-userchrome.css
  - swayosd/.config/swayosd/style.css
  - theme-engine/.config/theme-engine/contract.json
  - theme-engine/.config/theme-engine/lib/commit.sh
  - theme-engine/.config/theme-engine/lib/contract.sh
  - theme-engine/.config/theme-engine/lib/font.sh
  - theme-engine/.config/theme-engine/lib/generate.sh
  - theme-engine/.config/theme-engine/lib/gtk.sh
  - theme-engine/.config/theme-engine/lib/reload.sh
  - waybar/.config/waybar/style-floating.css
  - waybar/.config/waybar/style-full.css
  - waybar/.config/waybar/style-minimal.css
  - wlogout/.config/wlogout/style.css
  - install.sh
  - stow.sh
findings:
  critical: 2
  warning: 6
  info: 8
  total: 16
status: issues_found
---

# Phase 6: Code Review Report (re-review after gap plans 06-10..06-12)

**Reviewed:** 2026-07-12T20:00:00Z
**Depth:** standard
**Files Reviewed:** 36
**Status:** issues_found

## Narrative Findings (AI reviewer)

## Summary

Fresh adversarial review of all 36 phase files after gap-closure plans 06-10..06-12. The prior round's fixes verified as properly landed: contract.sh's unknown-format branch is now loud (old CR-01), digit-bearing hypr-vars extract correctly (old WR-05), presence-only files are contract-tracked (old WR-07), and commit.sh's rsync excludes cover `icon-theme`/`font-choice` (old WR-02/CR-01 class).

However, the SwayOSD integration (OSD-01/D-23/D-24) contains two new Critical defects that make the entire OSD feature — and, worse, the volume/mute hardware keys themselves — nonfunctional on a fresh install. This phase's keybinds.conf replaced the previously working `wpctl` volume binds with `swayosd-client` calls, but **nothing in the repo ever launches `swayosd-server`**, and the caps-lock backend is enabled on the wrong systemd bus. Both failures are silenced by `2>/dev/null || true`, so they will never surface as errors.

Also verified clean this pass: all 13 new official-repo packages in install.sh exist under those exact names (checked against archlinux.org); the wlogout session-end `cliphist wipe` actions referenced by autostart.conf's mitigation comment do exist in the wlogout layout; satty/hyprlock/swayosd/zen matugen templates use valid color-context keys consistent with the sibling templates; theme-apply defines `STATE_DIR`/`PALETTES_DIR`/`LIB_DIR` before sourcing the lib files that reference them; the emoji list's invisible-unicode content is legitimate variation-selector/ZWJ emoji sequences.

## Critical Issues

### CR-01: `swayosd-server` is never launched — volume/mic keybinds are dead and no OSD ever appears

**File:** `hypr/.config/hypr/config/autostart.conf` (missing entry); `hypr/.config/hypr/config/keybinds.conf:138-141`
**Issue:** This phase rebinds all four audio keys from working `wpctl` commands to `swayosd-client`:

```
bindel = , XF86AudioRaiseVolume, exec, swayosd-client --output-volume raise
```

`swayosd-client` is a thin D-Bus client; the volume change and the OSD pill are both performed by `swayosd-server`. Grepping the whole repo, `swayosd-server` appears nowhere except reload.sh's `pgrep` gate — it is not in autostart.conf, there is no user service, and the Arch `swayosd` package (verified against the archlinux.org file list for `extra/swayosd`) ships **no session-bus D-Bus activation file** for the server (only a *system*-bus service for the libinput backend). So on a fresh install: pressing any volume/mute key does nothing at all — a functional regression from the wpctl binds this phase removed — and OSD-01/D-24 (the themed pill, styled by `swayosd/.config/swayosd/style.css` and the new `swayosd-colors.css` template) can never render.
**Fix:** Add the server to autostart:
```
# ── OSD daemon (OSD-01/D-23) ─────────────────────────
exec-once = uwsm app -- swayosd-server
```

### CR-02: install.sh enables `swayosd-libinput-backend.service` on the user bus, but it is a system unit — caps-lock OSD silently never enabled

**File:** `install.sh:329`
**Issue:**
```bash
systemctl --user enable --now swayosd-libinput-backend.service 2>/dev/null || true
```
The Arch `swayosd` package installs this unit **only** at `/usr/lib/systemd/system/swayosd-libinput-backend.service` (verified via the archlinux.org package file list — it is a root/system D-Bus service with polkit policy and udev rules; there is no user unit). `systemctl --user` therefore fails with "Unit ... does not exist", and the `2>/dev/null || true` swallows it, so the D-63/D-64 "no silent ghost installs" posture this same script enforces for packages is defeated for this service. Result: the keyless caps-lock OSD that keybinds.conf:136-137 explicitly documents as "handled by swayosd-libinput-backend.service (enabled in install.sh, D-23)" never works.
**Fix:**
```bash
sudo systemctl enable --now swayosd-libinput-backend.service || echo "  ⚠ swayosd-libinput-backend enable failed" >&2
```
(system bus, needs sudo; and don't fully silence the failure).

## Warnings

### WR-01: reload.sh restarts the wrong SwayOSD component, on the wrong bus

**File:** `theme-engine/.config/theme-engine/lib/reload.sh:73-75`
**Issue:**
```bash
if pgrep -x swayosd-server >/dev/null 2>&1; then
    timeout 5 systemctl --user restart swayosd-libinput-backend.service >/dev/null 2>&1 || true
fi
```
Two defects: (1) same wrong-bus problem as CR-02 — the backend is a system unit, so this `systemctl --user restart` is always a silent no-op; (2) even on the correct bus, the libinput backend is the *input listener*, not the process that renders CSS — restarting it cannot re-theme the pill. The comment's claim that style.css "is re-read at the next OSD trigger" is the only thing carrying theme propagation here and is unverified against swayosd 0.3.x behavior (GTK apps generally load CSS at startup). If that claim is wrong, SwayOSD keeps stale colors until logout on every theme switch.
**Fix:** Restart the server (the component that both renders CSS and is user-owned): `pkill -x swayosd-server` + detached `setsid uwsm app -- swayosd-server` relaunch (mirroring the walker relaunch idiom), or empirically verify per-trigger CSS re-read and delete the backend restart entirely.

### WR-02: Icon-theme variant fallback silently replaces the user's explicit pick with an arbitrary installed variant

**File:** `theme-engine/.config/theme-engine/lib/gtk.sh:389-416` (used at 294-307)
**Issue:** `theme_engine_nearest_icon_variant` only ever exact-matches `${base}-${ideal}` (e.g. `Tela-green`). Multi-segment variant names — `Tela-circle`, `Tela-circle-dark`, `Colloid-purple-dark` — can never match that single-segment pattern, so the function falls through to `installed[0]`, which is unsorted `find` output. The caller then does `gsettings set ... icon-theme "$nearest"`, so a user who explicitly picked `Tela-circle-dark` in the picker gets silently switched to whatever `Tela*` directory `find` happened to list first, on every theme switch. This directly violates the D-19 "never silently revert a user's pick" discipline the surrounding comments cite.
**Fix:** Change the no-match fallback to keep the user's own `$icon_theme` (emit nothing and let the caller's `nearest="$icon_theme"` default stand) instead of `installed[0]`, and match the hue color against the last hyphen segment so circle/variant families participate:
```bash
[[ "$candidate" == "${base}-${ideal}" || "$candidate" == "${base}-"*"-${ideal}" ]] && { printf '%s\n' "$candidate"; return 0; }
```

### WR-03: Emoji picker notification lies when wtype is missing

**File:** `hypr/.config/hypr/scripts/emoji-picker.sh:229-240`
**Issue:** When `wtype` is not installed the script deliberately degrades to copy-only (the `:` no-op branch), but the unconditional notification still reports `"Emoji Inserted" "$EMOJI typed and copied to clipboard"`. The user is told the glyph was typed into the focused app when it was not.
**Fix:**
```bash
if command -v wtype >/dev/null 2>&1; then
    wtype "$EMOJI"
    MSG="$EMOJI typed and copied to clipboard"
else
    MSG="$EMOJI copied to clipboard (wtype not installed — not typed)"
fi
printf '%s' "$EMOJI" | wl-copy
notify-send -a "Emoji Picker" "Emoji Inserted" "$MSG" -i face-smile -t 2000 2>/dev/null || true
```

### WR-04: Symbols-font tofu filter misses "Symbols Nerd Font Mono"

**File:** `hypr/.config/hypr/scripts/font-switcher.sh:49-50`
**Issue:** The enumeration filter `grep -vx 'Symbols Nerd Font'` excludes only that exact family. `ttf-nerd-fonts-symbols`/`-mono` ship the family **"Symbols Nerd Font Mono"** as a separate fc-list line, which passes the `-vx` exact-match filter and remains selectable — the precise "every surface renders as tofu" outcome the filter's own comment says it exists to prevent.
**Fix:** `grep -vE '^Symbols Nerd Font'` (or `grep -viE '^Symbols Nerd Font( Mono)?$'`).

### WR-05: stow.sh prints wrong keybindings in its "Next steps" output

**File:** `stow.sh:132-134`; cross-ref `hypr/.config/hypr/config/keybinds.conf:40-42`
**Issue:** The final instructions tell the user "Super+Shift+T to switch themes", "Super+Shift+W to switch waybar layouts", "Super+Shift+B to pick wallpapers". The actual binds are **Super+T** (theme), **Super+B** (waybar), **Super+W** (wallpaper) — every one of the three printed chords is wrong (Shift added, and B/W swapped). A fresh-install user following the script's own onboarding presses dead chords.
**Fix:**
```bash
echo "  3. Use Super+T to switch themes"
echo "  4. Use Super+B to switch waybar layouts"
echo "  5. Use Super+W to pick wallpapers"
```

### WR-06: clipboard-wipe.sh dies silently when cliphist is missing or its db errors

**File:** `hypr/.config/hypr/scripts/clipboard-wipe.sh:12,31`
**Issue:** Two `set -euo pipefail` traps: (1) at line 12, if `cliphist list` exits non-zero (corrupt/locked db), pipefail makes the `COUNT=$(...)` assignment fail and the script aborts before any UI appears — the keybind just does nothing. (2) The `command -v cliphist` guard only protects the *count*; if cliphist is absent, the script still shows the confirm dialog ("This clears all 0 saved clipboard entries"), and after the user picks Yes, `cliphist wipe` at line 31 fails (127) and set -e kills the script with no notification — the user believes the wipe happened.
**Fix:** Bail out early with an error notification when cliphist is not installed; make the count failure-tolerant (`COUNT=$(cliphist list 2>/dev/null | wc -l | tr -d '[:space:]' || echo 0)`); and wrap the wipe:
```bash
if ! cliphist wipe; then
    notify-send -a "Clipboard" "Error" "cliphist wipe failed" -i dialog-error 2>/dev/null || true
    exit 1
fi
```

## Info

### IN-01: `walker-relaunch.log` missing from commit.sh's rsync --delete excludes

**File:** `theme-engine/.config/theme-engine/lib/commit.sh:70-73`; cross-ref `theme-engine/.config/theme-engine/lib/reload.sh:170`
**Issue:** reload.sh writes `$STATE_DIR/walker-relaunch.log`, a fifth engine-owned root-level state file that is never part of the rendered tree. It is not excluded, so every commit's `--delete` removes it. Currently benign (reload truncates/recreates it after each commit), but it is the exact bug class this file documents four times over, and any future consumer reading the log between switches would find it deleted.
**Fix:** Add `--exclude=walker-relaunch.log` to the rsync invocation.

### IN-02: Stale contract.sh documentation

**File:** `theme-engine/.config/theme-engine/lib/contract.sh:20,40`
**Issue:** `contract_files`' doc says "the 10 matugen-rendered state-dir files" — contract.json now lists 17 entries. `contract_format`'s doc enumerates the format tags but omits `ini-kv` and `env-kv`, both implemented below.
**Fix:** Update both comments to match contract.json.

### IN-03: Picker temp scripts/cache leak on abnormal exit (no trap)

**File:** `hypr/.config/hypr/scripts/font-switcher.sh:45,85-86`; `hypr/.config/hypr/scripts/icon-theme-picker.sh:39,86-87`
**Issue:** ENUM_SCRIPT/PREVIEW_SCRIPT/CACHE_DIR are removed only on the happy path after fzf returns. A `set -e` failure mid-script or SIGHUP from closing the floating kitty window leaks executable scripts and a cache dir in /tmp. color-picker.sh and gif-export.sh already use the `trap ... EXIT` idiom.
**Fix:** `trap 'rm -f "$ENUM_SCRIPT" "$PREVIEW_SCRIPT"; rm -rf "$CACHE_DIR"' EXIT` right after creation.

### IN-04: `grep -c ... || echo 0` yields a two-line value in zen profile resolution

**File:** `theme-engine/.config/theme-engine/lib/reload.sh:102`
**Issue:** `grep -c` prints `0` *and* exits 1 on zero matches, so `$(grep -c '^\[' ... || echo 0)` captures `"0\n0"` for a section-less installs.ini; the later `[[ "$install_sections" -eq 1 ]]` then emits a bash arithmetic syntax error to stderr (outcome still degrades correctly to the profiles.ini fallback).
**Fix:** `install_sections=$(grep -c '^\[' "$zen_root/installs.ini" 2>/dev/null || true)` — grep already printed the 0.

### IN-05: Unitless `border-radius: 10` dropped by GTK CSS parser

**File:** `waybar/.config/waybar/style-floating.css:8`
**Issue:** GTK CSS requires units on non-zero lengths; `border-radius: 10;` in the `*` rule is discarded with a parse warning (visual impact is nil today because every module rule re-sets `10px`).
**Fix:** `border-radius: 10px;`

### IN-06: `zsh` listed under AUR_PKGS

**File:** `install.sh:204`
**Issue:** zsh is an official `extra` repo package, not AUR. paru resolves it anyway, so this works, but the section labeling ("AUR packages") misinforms the package-legitimacy audit trail (D-16) this file otherwise maintains carefully.
**Fix:** Move `zsh` to PACMAN_PKGS.

### IN-07: commit.sh satty guard message references a stow.sh unfold that doesn't exist

**File:** `theme-engine/.config/theme-engine/lib/commit.sh:104-105`
**Issue:** The folded-symlink warning says "re-run stow.sh to unfold it", but there is no `satty` stow package and stow.sh has no satty `mkdir -p` pre-create (unlike gtk-3.0/gtk-4.0 at stow.sh:67). The suggested remedy can never fix the condition it warns about (the condition is also currently unreachable, since nothing stows ~/.config/satty).
**Fix:** Either drop the guard or change the message to "remove the symlink manually"; optionally add `mkdir -p "$HOME/.config/satty"` to stow.sh alongside the gtk dirs for symmetry.

### IN-08: `pgrep/pkill -f "^gpu-screen-recorder"` over-matches foreign recorder processes

**File:** `hypr/.config/hypr/scripts/record-toggle.sh:36,46,56`
**Issue:** The prefix pattern also matches any process whose cmdline starts with `gpu-screen-recorder` that this script did not start (e.g. `gpu-screen-recorder-gtk`, or a user-run replay-mode instance). `recording_active()` would then report active and the toggle would SIGINT/SIGKILL a recording it doesn't own.
**Fix:** Persist the child PID (already captured as `$pid` in `start_recording`) into `$RUNTIME_DIR` and target it directly, falling back to `pgrep -x gpu-screen-recorder` (exact process-name match) only for orphan cleanup.

---

_Reviewed: 2026-07-12T20:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
