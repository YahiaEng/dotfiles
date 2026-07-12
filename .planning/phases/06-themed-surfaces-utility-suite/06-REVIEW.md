---
phase: 06-themed-surfaces-utility-suite
reviewed: 2026-07-12T21:15:00Z
depth: standard
files_reviewed: 34
files_reviewed_list:
  - hypr/.config/hypr/config/autostart.conf
  - hypr/.config/hypr/config/keybinds.conf
  - hypr/.config/hypr/hyprlock.conf
  - hypr/.config/hypr/scripts/capture-full.sh
  - hypr/.config/hypr/scripts/capture-region.sh
  - hypr/.config/hypr/scripts/capture-window.sh
  - hypr/.config/hypr/scripts/clipboard-wipe.sh
  - hypr/.config/hypr/scripts/color-picker.sh
  - hypr/.config/hypr/scripts/emoji-picker.sh
  - hypr/.config/hypr/scripts/font-switcher.sh
  - hypr/.config/hypr/scripts/gif-export.sh
  - hypr/.config/hypr/scripts/icon-theme-picker.sh
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
  - theme-engine/.config/theme-engine/lib/font.sh
  - theme-engine/.config/theme-engine/lib/generate.sh
  - theme-engine/.config/theme-engine/lib/gtk.sh
  - theme-engine/.config/theme-engine/lib/reload.sh
  - vscodium/.config/VSCodium/User/settings.json
  - waybar/.config/waybar/style-floating.css
  - waybar/.config/waybar/style-full.css
  - waybar/.config/waybar/style-minimal.css
  - wlogout/.config/wlogout/layout
  - wlogout/.config/wlogout/style.css
findings:
  critical: 4
  warning: 7
  info: 7
  total: 18
status: issues_found
---

# Phase 6: Code Review Report

**Reviewed:** 2026-07-12T21:15:00Z
**Depth:** standard
**Files Reviewed:** 34
**Status:** issues_found

## Summary

Reviewed the Phase 6 themed-surfaces/utility-suite work: 10 new utility scripts, hyprlock/matugen/theme-engine wiring, waybar/wlogout/swayosd CSS, install.sh/stow.sh changes, and templates. Cross-file verification included the keybind → script → terminal-context chain, the CSS `@import` cascade for the new font axis, the commit.sh rsync exclude contract, and package-name existence checks against the live pacman database (hyprshutdown, awww, swayosd all confirmed in `extra`; the gtk template's `accent_color` key confirmed present).

Four Critical findings: two ship broken features end-to-end (waybar font switching is cascade-dead; the font/icon picker keybinds launch TTY-dependent fzf scripts with no terminal), one breaks region screen-recording (wrong gpu-screen-recorder flag shape), and one crashes install.sh on yay-based systems. Seven Warnings cover silent-failure paths, a hardcoded theme color on the lock screen, and a set -e exit-status bug the repo has already documented and fixed elsewhere.

## Critical Issues

### CR-01: Waybar font override is dead CSS — the hardcoded `* { font-family }` always wins over the imported waybar-font.css

**File:** `waybar/.config/waybar/style-full.css:2` (also `style-minimal.css:2`, `style-floating.css:2`; root cause reasoning in `theme-engine/.config/theme-engine/lib/font.sh:47-53`)
**Issue:** All three waybar stylesheets import the rendered font fragment at the top of the file, then declare their own `* { font-family: "FiraCode Nerd Font", ... }` immediately after:

```css
@import url("../../.local/state/theme/waybar.css");
@import url("../../.local/state/theme/waybar-font.css");

* {
    font-family: "FiraCode Nerd Font", "Font Awesome 6 Free";
    ...
}
```

In CSS (GTK included), `@import`ed rules behave as if inserted **at the import position** — i.e., *before* the file's own rules. Both the imported rule and the local rule are `* { font-family }` (equal specificity), so the **later** local rule wins on every load. The comment in `font.sh:50-51` ("placed after the colors @import, so this rule's font-family wins over each stylesheet's own hardcoded `* { }` literal") has the cascade backwards: being after the *other import* does not put it after the file's own literal rule. Net effect: UTIL-05 font switching never changes waybar's font, on any of the three layouts, ever. kitty is unaffected (kitty's `include` at end-of-file genuinely wins), so a switch will appear to "half work," which makes this easy to misdiagnose.
**Fix:** Remove the `font-family:` declaration from the local `* {}` block in all three `style-*.css` files and let the imported `waybar-font.css` be the sole owner (stow.sh already seeds `theme-apply catppuccin` before first login, so the fragment exists before waybar ever starts — the "fresh-install fallback" rationale doesn't hold for waybar). Alternatively render the font rule into `waybar.css` itself with a more specific selector, but single-owner removal is the minimal fix:

```css
/* style-full.css */
* {
    font-size: 13px;
    min-height: 0;
    border: none;
    border-radius: 0;
}
```

### CR-02: Font-switcher and icon-theme-picker keybinds run TTY-dependent fzf scripts with no terminal — Super+Shift+X / Super+Shift+Z silently do nothing

**File:** `hypr/.config/hypr/config/keybinds.conf:69,71` (scripts: `font-switcher.sh:150`, `icon-theme-picker.sh:157`)
**Issue:** Both scripts are fzf pickers ("fzf-in-floating-kitty" per their own headers, D-20 — "the SAME pattern as wallpaper-picker.sh"). But the wallpaper pattern has a **wrapper**: `wallpaper-switch.sh` launches `uwsm app -- kitty --class "wallpaper-picker" ... -- wallpaper-picker.sh`, with a matching floating windowrule (`windowrules.conf:47-56`). The new keybinds exec the picker scripts **directly**:

```
bind = $mainMod SHIFT, Z, exec, ~/.config/hypr/scripts/icon-theme-picker.sh
bind = $mainMod SHIFT, X, exec, ~/.config/hypr/scripts/font-switcher.sh
```

Launched from a Hyprland `exec` there is no controlling terminal: fzf cannot open `/dev/tty` and exits with an error, which the scripts swallow (`... | fzf ...) || true`), leaving `SELECTED` empty and exiting 0 — a completely silent no-op. The empty-state paths (`read -rn1` at `font-switcher.sh:72`, `icon-theme-picker.sh:76`) also hang/fail without a TTY. `kitten icat` previews additionally require running inside kitty. No windowrule exists for either picker (verified: `windowrules.conf` only covers `wallpaper-picker` and yazi). Both UTIL-04 and UTIL-05 keybinds are non-functional as wired.
**Fix:** Wrap both in a floating kitty exactly like `wallpaper-switch.sh`, and add matching windowrules:

```
bind = $mainMod SHIFT, Z, exec, uwsm app -- kitty --class icon-theme-picker --title "Icon Theme Picker" -o background_opacity=0.85 -- ~/.config/hypr/scripts/icon-theme-picker.sh
bind = $mainMod SHIFT, X, exec, uwsm app -- kitty --class font-switcher --title "Font Switcher" -o background_opacity=0.85 -- ~/.config/hypr/scripts/font-switcher.sh
```

### CR-03: record-toggle.sh passes region geometry directly to `-w` — region recordings fail to start

**File:** `hypr/.config/hypr/scripts/record-toggle.sh:177`
**Issue:** The capture-args branch treats a region exactly like a monitor name:

```bash
case "$target" in
    monitor:*) capture_args=(-w "${target#monitor:}") ;;
    region:*) capture_args=(-w "${target#region:}") ;;
esac
```

Per gpu-screen-recorder's CLI contract, `-w` accepts a window id, a display/monitor name, `screen`, `focused`, `portal`, or the literal `region` — a geometry string like `800x600+100+100` is not a valid `-w` value; region capture requires `-w region -region WxH+X+Y`. The Omarchy reference this script is adapted from uses the `-w region -region "$region"` form. As written, any drag-selected region (i.e., anything that isn't a full-monitor click) makes gpu-screen-recorder reject the target and die; the start loop then falls into the error branch, so the user gets "Recording failed to start" for every region recording. Monitor capture is unaffected. Note: gpu-screen-recorder is not installed on this machine (`pacman -Q` fails), so this could not be smoke-tested — verify against the installed binary, but the flag shape as written contradicts the documented interface.
**Fix:**

```bash
region:*) capture_args=(-w region -region "${target#region:}") ;;
```

### CR-04: install.sh hardcodes `paru` for orphan removal and cache clean — crashes under `set -e` on yay-based systems

**File:** `install.sh:292,296`
**Issue:** The script explicitly supports either AUR helper (`AUR_HELPER="paru"` or `"yay"`, lines 254-270) and uses `$AUR_HELPER` for the package install (line 281) — but the cleanup step reverts to a literal `paru`:

```bash
paru -R --noconfirm "${ORPHANS[@]}"
...
paru -Sc --noconfirm
```

On a machine where only yay is present (the exact case the `elif command -v yay` branch exists for), `paru` is not installed, the command fails, and `set -euo pipefail` aborts the entire script at line 296 — after packages install but **before** audio/dbus/swayosd services are enabled, VSCodium extensions install, and `verify_packages` runs. The install exits nonzero mid-way with no indication of which step died.
**Fix:**

```bash
"$AUR_HELPER" -R --noconfirm "${ORPHANS[@]}"
...
"$AUR_HELPER" -Sc --noconfirm
```

## Warnings

### WR-01: hyprlock placeholder_text hardcodes a Catppuccin hex, breaking the themed-lock contract

**File:** `hypr/.config/hypr/hyprlock.conf:177`
**Issue:** `placeholder_text = <span foreground="##a6adc8">  Enter Password...</span>` hardcodes Catppuccin Mocha's subtext color while every other color in the file goes through the matugen-rendered `$primary`/`$on_surface`/etc. variables (LOCK-01/D-30's whole point). On light themes (`materialyou-light`, light presets) this pale grey placeholder sits on a light `$surface` input field — poor-to-illegible contrast, and a stale-palette leak on every non-Catppuccin dark theme too.
**Fix:** Add an `$on_surface_variant` (or reuse `$outline`) definition to `matugen/templates/hyprlock-colors.conf` in hex form and reference it: `placeholder_text = <span foreground="##{{...hex_stripped}}">...` — the template already renders per-theme, so a themed variable is available at zero extra cost. (Note hyprlock span colors need the `##` escape with a hex value, so render a dedicated stripped-hex variable for it.)

### WR-02: Recording-saved notification actions expire after 3 seconds

**File:** `hypr/.config/hypr/scripts/record-toggle.sh:68-70`
**Issue:** `notify-send ... -t 3000 -A "open=Open" -A "gif=Export GIF"` gives the user a 3-second window to click "Export GIF" before the notification expires and `notify-send` returns with no action. The GIF-export entry point (D-04's designated UX) is practically unreachable unless the user is already hovering the notification. Compare `capture-*.sh` which uses `-t 3000` only for a passive, action-less toast.
**Fix:** Drop `-t 3000` (use the daemon default / a longer timeout) on this actionable notification, e.g. `-t 15000`, or omit `-t` entirely so swaync keeps it open while actions are pending.

### WR-03: papirus-folders accent tracking silently no-ops for the system-installed Papirus theme

**File:** `theme-engine/.config/theme-engine/lib/gtk.sh:291`
**Issue:** `papirus-folders -C "$color" -t "$icon_theme" 2>/dev/null || true` — `install.sh` installs `papirus-icon-theme` system-wide under `/usr/share/icons`, which an unprivileged user cannot modify; `papirus-folders` fails with a permission error that is discarded by `2>/dev/null || true`. The D-17 folder-accent-tracking feature is therefore very likely an inert code path on the exact configuration this repo installs, with zero diagnostic signal (not even a log line).
**Fix:** At minimum, log the failure instead of discarding it (`papirus-folders ... 2>>"$STATE_DIR/.last-render-error.log"`), and either (a) copy Papirus into `~/.local/share/icons` once so it is user-writable, or (b) document/verify a privilege path. Verify on the live machine — if it does work unprivileged, downgrade this to Info.

### WR-04: Unguarded `systemctl --user enable --now pipewire...` can abort the --core-only container gate

**File:** `install.sh:319`
**Issue:** Under `set -euo pipefail`, `systemctl --user enable --now pipewire.service wireplumber.service pipewire-pulse.service` has no `|| true` guard, unlike the immediately following dbus-broker (line 323) and swayosd (line 329) calls which are both guarded. In the container/VM verification context that `--core-only` exists for (D-52/D-57), a missing/limited user systemd instance makes this line fail and abort the script before the swayosd enable and before `verify_packages` — the gate then fails for a reason unrelated to what it verifies.
**Fix:** Match the adjacent pattern: `systemctl --user enable --now pipewire.service wireplumber.service pipewire-pulse.service 2>/dev/null || true` (or guard only under `--core-only` if a hard failure is desired on real installs).

### WR-05: color-picker.sh exits 1 on its success path when no swatch was generated

**File:** `hypr/.config/hypr/scripts/color-picker.sh:57`
**Issue:** The final line `[[ "$ICON" != "color-picker" ]] && rm -f "$ICON"` evaluates to exit status 1 whenever ImageMagick is unavailable or swatch generation failed (`ICON` still `"color-picker"`), so the script's exit code is 1 despite the color having been successfully picked, copied, and notified. This is the exact `set -e` / trailing-AND-list failure class this repo already diagnosed and fixed in `reload.sh:300-307` ("always return 0 once the notify decision has been made").
**Fix:**

```bash
if [[ "$ICON" != "color-picker" ]]; then
    rm -f "$ICON"
fi
```

### WR-06: capture-*.sh fail completely silently when hyprshot/satty are missing or the pipeline errors

**File:** `hypr/.config/hypr/scripts/capture-region.sh:40` (same in `capture-full.sh:21`, `capture-window.sh:18`)
**Issue:** Neither hyprshot nor satty is installed on this machine yet (both scripts' own headers say so), and the scripts have no `command -v` guard and no failure notification: under `set -euo pipefail`, a missing binary or any pipeline failure aborts before the `[ -f "$FILENAME" ]` check, so the Print-key family just appears dead. This is inconsistent with the phase's own convention — `color-picker.sh:16-19` checks `command -v hyprpicker` and notifies; `gif-export.sh` notifies on every failure branch. Cancellation (Esc) must stay silent, but "tool not installed" must not look identical to "user cancelled."
**Fix:** Add the same guard used by color-picker.sh at the top of each capture script:

```bash
for tool in hyprshot satty; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        notify-send -a "Screenshot" "Error" "$tool not installed" -i dialog-error -t 6000 2>/dev/null || true
        exit 1
    fi
done
```

### WR-07: contract.json not updated for the two new font render targets

**File:** `theme-engine/.config/theme-engine/contract.json:2-20`
**Issue:** `lib/font.sh` renders `kitty-font.conf` and `waybar-font.css` into the rendered tree on every `theme_engine_generate` run — they are part of the committed output (commit.sh deliberately does NOT exclude them, per its own D-19/UTIL-05 comment). But `contract.json`'s `files` array, consumed by `theme-doctor` and `theme-parity` (verified consumers: `lib/contract.sh`, `theme-doctor`, `theme-parity`), lists neither. The doctor's presence/format verification is blind to the new targets: a broken/absent font render would pass every health check.
**Fix:** Add entries: `{ "name": "kitty-font.conf", "format": "kitty-kv" }` and `{ "name": "waybar-font.css", "format": "gtk-css" }` (or a dedicated exemption note if parity-across-themes intentionally excludes theme-invariant files — but doctor presence checks should still cover them).

## Info

### IN-01: stow.sh "Next steps" lists wrong keybinds

**File:** `stow.sh:132-134`
**Issue:** The closing help text says Super+Shift+T (themes), Super+Shift+W (waybar layouts), Super+Shift+B (wallpapers); `keybinds.conf:40-42` binds Super+T, Super+B, and Super+W respectively.
**Fix:** Update the three echo lines to match the actual binds.

### IN-02: emoji-picker notification claims "typed and copied" even when wtype is absent

**File:** `hypr/.config/hypr/scripts/emoji-picker.sh:240`
**Issue:** The wtype-missing branch (lines 229-236) deliberately degrades to copy-only, but the notification unconditionally says "typed and copied to clipboard" — overpromising per the repo's own UI-SPEC copywriting discipline (compare font-switcher.sh's carefully hedged wording).
**Fix:** Set a `VERB="typed and copied"` / `VERB="copied (wtype not installed)"` variable in the branch and use it in the notification body.

### IN-03: Picker temp scripts/caches leak on abnormal exit (no trap cleanup)

**File:** `hypr/.config/hypr/scripts/font-switcher.sh:45,85-86` (same pattern `icon-theme-picker.sh:39,86-87`)
**Issue:** `ENUM_SCRIPT`, `PREVIEW_SCRIPT`, and `CACHE_DIR` are cleaned up inline after fzf; if the floating kitty window is closed (script killed) or any `set -e` failure fires between mktemp and cleanup, they leak into /tmp. `color-picker.sh` and `gif-export.sh` both use `trap ... EXIT` correctly.
**Fix:** `trap 'rm -f "$ENUM_SCRIPT" "$PREVIEW_SCRIPT"; rm -rf "$CACHE_DIR"' EXIT` right after creation.

### IN-04: reload.sh path inconsistencies around the walker relaunch

**File:** `theme-engine/.config/theme-engine/lib/reload.sh:168,170`
**Issue:** (a) `elephant_sock="/run/user/$(id -u)/..."` hardcodes the runtime dir while `record-toggle.sh:28` and `gtk.sh:92` use the `${XDG_RUNTIME_DIR:-/run/user/$(id -u)}` fallback. (b) `walker-relaunch.log` lives at the STATE_DIR root but is not in commit.sh's rsync `--exclude` list — the same engine-owned-root-file class commit.sh documents four times (WR-02/CR-01/D-19). Impact is negligible only because the log is truncated on every relaunch anyway, but the next occupant of this pattern won't be so lucky.
**Fix:** Use the XDG fallback idiom; add `--exclude=walker-relaunch.log` to commit.sh (or move the log to `$STATE_DIR/logs/`, which is already excluded).

### IN-05: icon-theme-picker empty-state check conflates "only Adwaita" with "exactly one theme"

**File:** `hypr/.config/hypr/scripts/icon-theme-picker.sh:70`
**Issue:** `[[ "$THEME_COUNT" -le 1 ]]` assumes the single enumerated theme is Adwaita. If Adwaita's `index.theme` were absent/filtered and exactly one third-party theme (e.g. Papirus) is installed, the picker refuses to run with a misleading "No extra icon themes installed" message.
**Fix:** Show the empty state only when the enumeration is empty or contains solely Adwaita: check the actual content, not the count.

### IN-06: style-floating.css unitless border-radius and quoted generic font family

**File:** `waybar/.config/waybar/style-floating.css:5,9`
**Issue:** `border-radius: 10;` (no unit — invalid in GTK CSS, the declaration is dropped with a parser warning) and `"monospace"` (quoting a generic family makes it a literal font name lookup, not the generic fallback). Pre-existing lines, surfaced because the file was touched this phase.
**Fix:** `border-radius: 10px;` and unquoted `monospace`.

### IN-07: Super+C clipboard flow clobbers the current clipboard on cancel

**File:** `hypr/.config/hypr/config/keybinds.conf:45`
**Issue:** `cliphist list | walker --dmenu | cliphist decode | wl-copy` — when walker is cancelled (Esc), the downstream `cliphist decode | wl-copy` still runs on empty input, replacing the user's current clipboard selection with empty content. Pre-existing bind, but it now sits adjacent to the new UTIL-03 wipe flow whose whole design is "never destructive without confirm."
**Fix:** Route through a small script (or inline guard) that only pipes to `wl-copy` when the walker selection is non-empty, e.g. `sel=$(cliphist list | walker --dmenu) && [ -n "$sel" ] && printf '%s' "$sel" | cliphist decode | wl-copy`.

---

_Reviewed: 2026-07-12T21:15:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
