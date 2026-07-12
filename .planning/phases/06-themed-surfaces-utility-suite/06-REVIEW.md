---
phase: 06-themed-surfaces-utility-suite
reviewed: 2026-07-12T23:15:28Z
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
  - install.sh
  - kitty/.config/kitty/kitty.conf
  - matugen/.config/matugen/config.toml
  - matugen/.config/matugen/templates/hyprlock-colors.conf
  - matugen/.config/matugen/templates/satty-colors.toml
  - matugen/.config/matugen/templates/swayosd-colors.css
  - matugen/.config/matugen/templates/zen-userchrome.css
  - stow.sh
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
findings:
  critical: 0
  warning: 10
  info: 10
  total: 20
status: issues_found
---

# Phase 6: Code Review Report (re-review after gap plan 06-13)

**Reviewed:** 2026-07-12T23:15:28Z
**Depth:** standard
**Files Reviewed:** 36
**Status:** issues_found

## Narrative Findings (AI reviewer)

## Summary

Fresh adversarial re-review of all 36 phase files after gap-closure plan 06-13 (OSD-01). **All three findings 06-13 targeted verify as properly resolved:**

- **Prior CR-01 (swayosd-server never launched) — RESOLVED.** `autostart.conf:36` now carries `exec-once = uwsm app -- swayosd-server`, placed before theme-init so the pill is themed at first paint; the volume/mic `swayosd-client` binds at `keybinds.conf:138-141` now have a server to talk to.
- **Prior CR-02 (libinput backend enabled on the wrong bus) — RESOLVED.** `install.sh:334` now runs `sudo systemctl enable --now swayosd-libinput-backend.service` on the system bus, with a visible `⚠` warning on failure instead of a swallowed error — exactly the suggested fix.
- **Prior WR-01 (reload.sh restarted the wrong SwayOSD component) — RESOLVED.** `reload.sh:78-92` now restarts `swayosd-server` itself (pkill + set-e-safe bounded poll + detached `setsid uwsm app --` relaunch), guarded by `pgrep -x swayosd-server` so headless/container runs stay a no-op. One residual robustness gap in this new block is flagged below as WR-07.

The remaining findings from the 2026-07-12T20:00Z review (WR-02..WR-06, IN-01..IN-08) were outside 06-13's scope and **all remain open** — re-verified individually against current file state and carried forward below under new IDs. This pass also surfaced four new findings (WR-03, WR-07, WR-08, WR-09/WR-10 group) not caught previously.

Verified clean this pass: all 14 questionable official-repo package names in install.sh (`hyprshutdown`, `awww`, `aws-cli-v2`, `vault`, `gpu-screen-recorder`, `swayosd`, `hyprshot`, `satty`, `hyprpicker`, `wtype`, `ddcutil`, `resvg`, `7zip`, `adw-gtk-theme`) exist in the sync db under those exact names (checked with `pacman -Si` on this machine); contract.json's 17 entries exactly cover the 15 matugen render targets in config.toml plus the two engine-rendered settings.ini files; the swayosd/zen/satty/hyprlock templates use color-context keys consistent with the proven sibling templates; `pkill -x swayosd-server` fits the 15-char comm limit (14 chars); commit.sh's rsync excludes correctly cover `icon-theme` and `font-choice`; reload.sh's `(( x < N ))` poll counters all use the documented set-e-safe assignment form; the hyprlock `##$on_surface_variant_hex` Pango escape pairs correctly with the template's bare-hex `$on_surface_variant_hex` variable.

## Warnings

### WR-01: Icon-theme variant fallback silently replaces the user's explicit pick with an arbitrary installed variant (carried, still open)

**File:** `theme-engine/.config/theme-engine/lib/gtk.sh:389-416` (used at 294-307)
**Issue:** `theme_engine_nearest_icon_variant` only exact-matches `${base}-${ideal}` (e.g. `Tela-green`). Multi-segment variant names — `Tela-circle`, `Tela-circle-dark`, `Colloid-purple-dark` — can never match, so the function falls through to `installed[0]`, unsorted `find` output. The caller then `gsettings set`s that name, so a user who explicitly picked `Tela-circle-dark` gets silently switched to whatever `Tela*` directory `find` listed first, on every theme switch — directly violating the D-19 "never silently revert a user's pick" discipline the surrounding comments cite.
**Fix:** On no-match, emit nothing (let the caller's `nearest="$icon_theme"` default keep the user's pick), and widen matching so variant families participate:
```bash
[[ "$candidate" == "${base}-${ideal}" || "$candidate" == "${base}-"*"-${ideal}" ]] && { printf '%s\n' "$candidate"; return 0; }
```

### WR-02: Emoji picker notification lies when wtype is missing (carried, still open)

**File:** `hypr/.config/hypr/scripts/emoji-picker.sh:229-240`
**Issue:** When `wtype` is absent the script deliberately degrades to copy-only (the `:` no-op branch), but the unconditional notification still reports `"$EMOJI typed and copied to clipboard"`. The user is told the glyph was typed into the focused app when it was not.
**Fix:** Branch the message:
```bash
if command -v wtype >/dev/null 2>&1; then
    wtype "$EMOJI" || true
    MSG="$EMOJI typed and copied to clipboard"
else
    MSG="$EMOJI copied to clipboard (wtype not installed — not typed)"
fi
```

### WR-03: A failed `wtype` aborts emoji-picker before the wl-copy "backup" ever runs (new)

**File:** `hypr/.config/hypr/scripts/emoji-picker.sh:230,238`
**Issue:** The script runs under `set -euo pipefail` and `wtype "$EMOJI"` is unguarded. If wtype exits non-zero at runtime (virtual-keyboard protocol denied, no focused surface to type into — e.g. picker invoked from an empty workspace), `set -e` kills the script *before* line 238's `wl-copy`. D-21's entire design is "typed via wtype AND copied via wl-copy as backup" — but the backup is sequenced after the fallible step with no guard, so the exact failure mode the backup exists for prevents the backup from happening. No notification fires either, so the failure is fully silent.
**Fix:** `wtype "$EMOJI" || true` (or capture the status to adjust the WR-02 message: `typed=1; wtype "$EMOJI" || typed=0`), keeping `wl-copy` unconditionally reachable.

### WR-04: Symbols-font tofu filter misses "Symbols Nerd Font Mono" (carried, still open)

**File:** `hypr/.config/hypr/scripts/font-switcher.sh:49-50`
**Issue:** The enumeration filter `grep -vx 'Symbols Nerd Font'` excludes only that exact family. `ttf-nerd-fonts-symbols-mono` ships the family **"Symbols Nerd Font Mono"** as a separate fc-list line, which passes the `-vx` exact-match filter and remains selectable — the precise "every surface renders as tofu" outcome the filter's own comment says it exists to prevent.
**Fix:** `grep -vE '^Symbols Nerd Font( Mono)?$'`

### WR-05: stow.sh prints wrong keybindings in its "Next steps" output (carried, still open)

**File:** `stow.sh:132-134`; cross-ref `hypr/.config/hypr/config/keybinds.conf:40-42`
**Issue:** The final onboarding instructions say "Super+Shift+T to switch themes", "Super+Shift+W to switch waybar layouts", "Super+Shift+B to pick wallpapers". The actual binds are **Super+T** (theme), **Super+B** (waybar), **Super+W** (wallpaper) — all three printed chords are wrong (spurious Shift, and B/W swapped). A fresh-install user following the script's own instructions presses dead chords.
**Fix:**
```bash
echo "  3. Use Super+T to switch themes"
echo "  4. Use Super+B to switch waybar layouts"
echo "  5. Use Super+W to pick wallpapers"
```

### WR-06: clipboard-wipe.sh dies silently when cliphist is missing or its db errors (carried, still open)

**File:** `hypr/.config/hypr/scripts/clipboard-wipe.sh:12,31`
**Issue:** Two `set -euo pipefail` traps: (1) at line 12, if `cliphist list` exits non-zero (corrupt/locked db), pipefail fails the `COUNT=$(...)` assignment and the script aborts before any UI appears — the keybind just does nothing. (2) The `command -v cliphist` guard only protects the *count*: with cliphist absent, the confirm dialog still shows ("clears all 0 saved clipboard entries"), and after the user picks Yes, `cliphist wipe` fails (127) and set -e kills the script with no notification — the user believes the wipe happened.
**Fix:** Bail out early with an error notification when cliphist is not installed; make the count failure-tolerant; wrap the wipe:
```bash
if ! cliphist wipe; then
    notify-send -a "Clipboard" "Error" "cliphist wipe failed" -i dialog-error 2>/dev/null || true
    exit 1
fi
```

### WR-07: SwayOSD relaunch has no forced-kill fallback — can race a surviving old server and leave zero servers running (new)

**File:** `theme-engine/.config/theme-engine/lib/reload.sh:78-92`
**Issue:** The new 06-13 restart block sends `pkill -x swayosd-server`, polls up to 2s for exit, then **relaunches unconditionally** — with no `killall -9` fallback when the poll exhausts. Every other bounded-poll kill in this engine (walker at reload.sh:218-222, thunar at gtk.sh:126-134 and 189-198) force-kills after the cap for exactly this reason. If the old server survives SIGTERM past 2s, the new instance is spawned while the old one still owns swayosd's D-Bus name; the newcomer fails name acquisition and exits, and when the old server finally dies, *no* server remains — every volume/mute key is dead until the next theme switch or login, silently.
**Fix:** Mirror the walker idiom before the relaunch:
```bash
if pgrep -x swayosd-server >/dev/null 2>&1; then
    killall -q -9 swayosd-server 2>/dev/null || true
fi
```

### WR-08: color-picker.sh depends on unverified `hyprpicker -a` stdout behavior; the flag is redundant at best (new)

**File:** `hypr/.config/hypr/scripts/color-picker.sh:25,37`
**Issue:** The script captures `HEX=$(hyprpicker -a -f hex ...)` and then does its own `wl-copy` at line 37. `-a`/`--autocopy` makes hyprpicker itself copy the result to the clipboard — duplicating the script's copy. More importantly, whether `-a` *also* prints the color to stdout is version-dependent and unverified: hyprpicker is not installed on this machine (confirmed `pacman -Q hyprpicker` fails), and unlike capture-region.sh's header this script carries no upstream-source verification note. If `-a` suppresses stdout, `HEX` is empty and line 35's `[[ -z "$HEX" ]] && exit 0` silently exits — the swatch notification (D-22, this script's entire purpose beyond a bare copy) never fires, on every single use, with no error.
**Fix:** Drop `-a` entirely — the script already owns the copy via `wl-copy`, making behavior unambiguous: `HEX=$(hyprpicker -f hex 2>"$ERR_FILE")`. Alternatively, verify the installed hyprpicker's `-a` stdout behavior and document it in the header like the capture scripts do.

### WR-09: satty's #RRGGBBAA palette colors are invisible to the parity gate — contract.sh recognizes no 8-digit hex form (new)

**File:** `theme-engine/.config/theme-engine/lib/contract.sh:226-255`; cross-ref `theme-engine/.config/theme-engine/theme-parity:300`, `matugen/.config/matugen/templates/satty-colors.toml:23-31`
**Issue:** satty.toml is a contract file (contract.json:19) whose palette values render as 8-digit `#RRGGBBAA` hex (`"{{colors.primary.default.hex}}ff"` → `#aabbccff`). Neither `contract_normalize_color` (6-hex or `rgba(RRGGBBAA)` only) nor `contract_wellformed_color` recognizes that form, and theme-parity's Layer 3 gate regex (`^\#?[0-9a-fA-F]{6}$ || ^rgba?\(`) skips these values entirely — so satty palette colors are never semantically validated. A truncated render (`#aabbcff`), a stray non-hex alpha suffix, or any malformed satty color that isn't a literal `{{` leftover passes theme-parity silently. This is the same false-pass class old CR-01 (silent unknown-format) fixed, reintroduced for the one contract format added this phase.
**Fix:** Teach `contract_normalize_color` the `#RRGGBBAA` form (strip `#`, accept `^([0-9a-f]{6})[0-9a-f]{2}$`) and widen theme-parity's gate to `^\#?[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$` so satty values participate in Layer 3.

### WR-10: papirus-folders accent tracking silently no-ops for the system-installed Papirus (new)

**File:** `theme-engine/.config/theme-engine/lib/gtk.sh:288-292`; cross-ref `install.sh:149`
**Issue:** install.sh installs `papirus-icon-theme` from the official repo, which lands in root-owned `/usr/share/icons/`. `papirus-folders -C <color> -t <theme>` rewrites folder symlinks *inside the theme directory* and therefore needs write access to it; run as the regular user (as gtk.sh does, no sudo path) it fails on the system-installed theme, and the `2>/dev/null || true` swallows the error. Result: the D-17 palette-tracked folder recoloring — the whole reason Papirus gets a dedicated branch here — never works on a stock install, and never surfaces as an error. (The `gsettings set` on line 287 still applies, so the theme itself switches; only the accent tracking is dead.)
**Fix:** Either copy Papirus into `~/.local/share/icons/` at install time (papirus-folders operates on the user copy without privileges), or detect the unwritable case and emit a one-time notify/log line instead of `2>/dev/null` so the degradation is visible.

## Info

### IN-01: `walker-relaunch.log` missing from commit.sh's rsync --delete excludes (carried, still open)

**File:** `theme-engine/.config/theme-engine/lib/commit.sh:70-73`; cross-ref `theme-engine/.config/theme-engine/lib/reload.sh:187,290`
**Issue:** reload.sh writes `$STATE_DIR/walker-relaunch.log`, a fifth engine-owned root-level state file never part of the rendered tree. Not excluded, so every commit's `--delete` removes it. Currently benign (reload truncates/recreates it after each commit), but it is the exact bug class this file documents four times over, and the "see walker-relaunch.log" error notification (reload.sh:314) points at a file the very next theme switch deletes.
**Fix:** Add `--exclude=walker-relaunch.log`.

### IN-02: Stale contract.sh documentation (carried, still open)

**File:** `theme-engine/.config/theme-engine/lib/contract.sh:20-21,39-40`
**Issue:** `contract_files`' doc says "the 10 matugen-rendered state-dir files" — contract.json now lists 17 entries. `contract_format`'s doc enumerates format tags but omits `ini-kv` and `env-kv`, both implemented below.
**Fix:** Update both comments to match contract.json.

### IN-03: Picker temp scripts/cache leak on abnormal exit — no trap (carried, still open)

**File:** `hypr/.config/hypr/scripts/font-switcher.sh:45,85-86`; `hypr/.config/hypr/scripts/icon-theme-picker.sh:39,86-87`
**Issue:** ENUM_SCRIPT/PREVIEW_SCRIPT/CACHE_DIR are removed only on the happy path after fzf returns. A `set -e` failure mid-script or SIGHUP from closing the floating kitty window leaks executable scripts and a cache dir in /tmp. color-picker.sh and gif-export.sh already use the `trap ... EXIT` idiom.
**Fix:** `trap 'rm -f "$ENUM_SCRIPT" "$PREVIEW_SCRIPT"; rm -rf "$CACHE_DIR"' EXIT` right after creation.

### IN-04: `grep -c ... || echo 0` yields a two-line value in zen profile resolution (carried, still open)

**File:** `theme-engine/.config/theme-engine/lib/reload.sh:119`
**Issue:** `grep -c` prints `0` *and* exits 1 on zero matches, so `$(grep -c '^\[' ... || echo 0)` captures `"0\n0"` for a section-less installs.ini; `[[ "$install_sections" -eq 1 ]]` then emits a bash arithmetic syntax error to stderr (outcome still degrades correctly to the profiles.ini fallback).
**Fix:** `install_sections=$(grep -c '^\[' "$zen_root/installs.ini" 2>/dev/null || true)` — grep already printed the 0.

### IN-05: Unitless `border-radius: 10` dropped by GTK CSS parser (carried, still open)

**File:** `waybar/.config/waybar/style-floating.css:8`
**Issue:** GTK CSS requires units on non-zero lengths; `border-radius: 10;` in the `*` rule is discarded with a parse warning (visual impact nil today because every module rule re-sets `10px`).
**Fix:** `border-radius: 10px;`

### IN-06: `zsh` listed under AUR_PKGS (carried, still open)

**File:** `install.sh:204`
**Issue:** zsh is an official `extra` repo package, not AUR. paru resolves it anyway, but the section labeling misinforms the package-legitimacy audit trail (D-16) this file otherwise maintains carefully.
**Fix:** Move `zsh` to PACMAN_PKGS.

### IN-07: commit.sh satty guard message references a stow.sh unfold that doesn't exist (carried, still open)

**File:** `theme-engine/.config/theme-engine/lib/commit.sh:104-105`; cross-ref `stow.sh:19-38,67`
**Issue:** The folded-symlink warning says "re-run stow.sh to unfold it", but there is no `satty` stow package and stow.sh has no satty `mkdir -p` pre-create (unlike gtk-3.0/gtk-4.0 at stow.sh:67). The suggested remedy can never fix the condition it warns about.
**Fix:** Change the message to "remove the symlink manually", or add `mkdir -p "$HOME/.config/satty"` to stow.sh for symmetry.

### IN-08: `pgrep/pkill -f "^gpu-screen-recorder"` over-matches foreign recorder processes (carried, still open)

**File:** `hypr/.config/hypr/scripts/record-toggle.sh:36,46,51,55-56`
**Issue:** The prefix pattern also matches any process whose cmdline starts with `gpu-screen-recorder` that this script did not start (e.g. `gpu-screen-recorder-gtk`, a user-run replay-mode instance). `recording_active()` then reports active and the toggle SIGINT/SIGKILLs a recording it doesn't own.
**Fix:** Persist the child PID (already captured as `$pid` in `start_recording`) into `$RUNTIME_DIR` and target it directly, falling back to `pgrep -x gpu-screen-recorder` only for orphan cleanup.

### IN-09: Stray windowrule embedded in keybinds.conf with inverted field order (new)

**File:** `hypr/.config/hypr/config/keybinds.conf:159`
**Issue:** `windowrule = match:class kitty, scroll_touchpad 1.5` lives at the bottom of the *keybindings* file, not windowrules.conf where every other rule resides — anyone auditing window rules will miss it. It also inverts the field order every rule in windowrules.conf uses (`<rule>, match:...`), and its match pattern is unanchored (`kitty` matches any class containing the substring, e.g. the `yazi-fm` kitty instances are matched only because their class was overridden — but a hypothetical `kitty-panel` class would also match).
**Fix:** Move to windowrules.conf as `windowrule = scroll_touchpad 1.5, match:class ^(kitty)$`.

### IN-10: Capture notifications claim "Copied to clipboard" based only on file existence (new)

**File:** `hypr/.config/hypr/scripts/capture-region.sh:51-55` (same block in capture-window.sh:29-33, capture-full.sh:32-36)
**Issue:** The `[ -f "$FILENAME" ]` gate correctly suppresses the notification on Escape, but satty also has a save-to-file-only action (Ctrl+S) distinct from the configured Enter combo — that path writes the file without copying, and the notification then falsely reports "Copied to clipboard". Cosmetic overclaim on a secondary path; the primary Enter flow (actions-on-enter = save-to-clipboard,save-to-file) is accurate.
**Fix:** Soften the copy claim ("Saved to $FILENAME") or accept and document the overclaim for the Ctrl+S path.

---

_Reviewed: 2026-07-12T23:15:28Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
