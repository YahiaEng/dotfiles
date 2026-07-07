# Phase 1: Root-Cause Fix & Consolidated Theme Engine - Pattern Map

**Mapped:** 2026-07-07
**Files analyzed:** 12 (new + modified)
**Analogs found:** 12 / 12 (all have an existing in-repo analog — this phase is a consolidation/refactor, not new-domain code)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|--------------------|------|-----------|-----------------|----------------|
| `theme-engine/.config/theme-engine/theme-apply` | script/controller (CLI entrypoint) | request-response (name → rendered+reloaded desktop) | `hypr/.config/hypr/scripts/theme-switch.sh` | exact (same responsibility, becomes its callee) |
| `theme-engine/.config/theme-engine/lib/generate.sh` | service (render step) | transform (name/wallpaper → matugen output) | `hypr/.config/hypr/scripts/theme-switch.sh` (`apply_static_theme`/`apply_material_you` bodies) + matugen `json`/`image` invocations in same file | exact |
| `theme-engine/.config/theme-engine/lib/commit.sh` | utility (atomic move) | file-I/O | none existing (new atomic pattern) — closest precedent is the `cp`/`cat` sequence in `theme-switch.sh` lines 52-77 | role-match (no atomic precedent in repo; build from matugen `-p` primitive per RESEARCH.md Pattern 2) |
| `theme-engine/.config/theme-engine/lib/reload.sh` | service (fan-out) | event-driven (signals/restarts) | `theme-switch.sh` `reload_all()` (lines 43-50) | exact |
| `theme-engine/.config/theme-engine/lib/gtk.sh` | utility (gsettings + GTK_THEME propagation) | request-response | `hypr/.config/hypr/scripts/gtk-reload.sh` | exact |
| `theme-engine/.config/theme-engine/theme-doctor` | utility (health check / new capability) | request-response (check → pass/fail report) | `hypr/.config/hypr/scripts/walker-restart.sh` (verify-before-declare-success pattern, lines 12-16) — nearest existing "check state, warn, act" script | partial (new capability; no direct analog for a report-only diagnostic) |
| `theme-engine/.config/theme-engine/palettes/<name>.json` (6 files) | config/data | transform (static CSS → matugen JSON input) | `themes/.config/themes/css/<name>.css` (source data to convert) | role-match (config-to-config transform, not code) |
| `hypr/.config/hypr/scripts/theme-switch.sh` (rewritten to thin caller) | controller (picker) | request-response | itself (current version, being slimmed) — see lines 1-41 (theme list + selection) which is KEPT, lines 43-120 (apply logic) which is REMOVED/delegated | exact (self-analog for what to keep) |
| `hypr/.config/hypr/scripts/theme-init.sh` (rewritten to thin caller) | controller (login init) | request-response | itself (current version) — keep lines 19 (`STATE_FILE` read) pattern, drop lines 22-89 (duplicated apply/reload) | exact (self-analog for what to keep) |
| `hypr/.config/hypr/scripts/wallpaper-picker.sh` (theme-apply call added, lines 132-157 gutted) | controller (picker) | request-response | itself — lines 132-157 (`Material You regeneration` block) is the exact duplication to replace with a single `theme-apply materialyou` call per D-20 | exact |
| `matugen/.config/matugen/config.toml` (post_hooks stripped, `[config.wallpaper]` removed/set=false, output_path → state dir) | config | transform | itself (current version, lines 8-15 `[config.wallpaper]`, and each `post_hook =` line) | exact |
| `gtk/.config/gtk-3.0/gtk.css`, `gtk/.config/gtk-4.0/gtk.css` (become static `@import`-only files) | config | file-I/O | themselves (current versions — currently overwritten by `cat colors.css gtk-base.css >`; become static stowed files) | exact |
| `install.sh` (AUR_PKGS → PACMAN_PKGS split for `adw-gtk3`→`adw-gtk-theme`) | config | batch | itself, `install.sh:146-185` (`AUR_PKGS` array) and `:41` (`PACMAN_PKGS` array) | exact |

## Pattern Assignments

### `theme-engine/.config/theme-engine/theme-apply` (script, request-response)

**Analog:** `hypr/.config/hypr/scripts/theme-switch.sh` (full file, 120 lines) + login-time variant `theme-init.sh`

**Shebang + strict mode** (theme-switch.sh has none; RESEARCH.md's illustrative skeleton uses strict mode — adopt it, it's the improvement this phase makes):
```bash
#!/usr/bin/env bash
set -euo pipefail
```

**Argument dispatch pattern** (theme-switch.sh lines 32-41, 116-120 — case/dispatch on theme name):
```bash
case "$SELECTED" in
    *"Material You"*)  THEME="materialyou" ;;
    *"Catppuccin"*)    THEME="catppuccin"  ;;
    ...
esac
...
if [[ "$THEME" == "materialyou" ]]; then
    apply_material_you
else
    apply_static_theme "$THEME"
fi
```
`theme-apply <name>` keeps this exact `materialyou` vs static-name branch shape, just driven by `$1` instead of a walker selection (walker selection logic moves OUT to the picker, which becomes a thin caller invoking `theme-apply "$THEME"`).

**Feedback/notify pattern** (theme-switch.sh lines 76-77, 111-113 — KEEP per D-18):
```bash
notify-send -a "Theme Switcher" "Theme Applied" "Switched to ${name}" \
    -i preferences-desktop-theme -t 3000
```
Error variant (lines 86-90, 96-100) — KEEP, update message to state "desktop was left unchanged" per D-18:
```bash
notify-send -a "Theme Switcher" "Error" \
    "No wallpaper found. Use Super+Shift+B to pick one first." \
    -i dialog-error -t 5000
exit 1
```

**State file write pattern** (theme-switch.sh line 75, theme-init.sh line 91 — same shape, now points at `~/.local/state/theme/current-theme` per D-05):
```bash
echo "$name" > "$STATE_FILE"
```

---

### `theme-engine/.config/theme-engine/lib/generate.sh` (service, transform)

**Analog:** `theme-switch.sh` `apply_static_theme()`/`apply_material_you()` (lines 52-114), reworked using RESEARCH.md's verified matugen primitives (NOT the old `cp`/`cat` static path — matugen `json` replaces it per D-03).

**Old static-copy pattern being REPLACED** (theme-switch.sh lines 55-72 — do not copy this shape into the new engine, it's the pre-D-03 approach):
```bash
cp "$THEMES_DIR/static/${name}.conf" "$HYPR_COLORS"
cp "$THEMES_DIR/css/${name}.css" "$WAYBAR_COLORS"
...
```

**New pattern to use instead** (RESEARCH.md "Atomic apply skeleton", verified against installed matugen 4.1.0 this session):
```bash
set -euo pipefail
tmp="$(mktemp -d)"
if [[ "$1" == "materialyou" ]]; then
    matugen image "$WALLPAPER" --source-color-index 0 -c "$MATUGEN_CFG" -p "$tmp"
else
    matugen json "$PALETTES_DIR/$1.json" -c "$MATUGEN_CFG" -p "$tmp"
fi
```

**Error-capture pattern to keep** (theme-switch.sh lines 95-100 — matugen stderr → notify):
```bash
if ! matugen image "$wallpaper" --source-color-index 0 2>/tmp/matugen-error.log; then
    notify-send -a "Theme Switcher" "Matugen Error" \
        "$(cat /tmp/matugen-error.log 2>/dev/null || echo 'Unknown error')" \
        -i dialog-error -t 5000
    exit 1
fi
```

**Wallpaper resolution pattern to keep** (theme-switch.sh lines 81-83):
```bash
wallpaper=$(readlink -f ~/Pictures/Wallpapers/current.jpg 2>/dev/null \
            || echo "$HOME/Pictures/Wallpapers/current.jpg")
```

---

### `theme-engine/.config/theme-engine/lib/commit.sh` (utility, file-I/O)

**No direct analog exists** — this is new atomicity logic. Nearest precedent is the unconditional-overwrite `cp`/`cat` calls in `theme-switch.sh` (lines 62-65) which this REPLACES, not extends.

**Pattern to use** (RESEARCH.md "Atomic apply skeleton" — verified `matugen -p` + move-on-success):
```bash
# matugen exits non-zero on real render errors (ResolveError, panic) — set -e catches it.
mkdir -p "$STATE_DIR"
rsync -a --delete "$tmp"/ "$STATE_DIR"/   # or: rm -rf "$STATE_DIR" && mv "$tmp" "$STATE_DIR"
echo "$1" > "$STATE_DIR/current-theme"
rm -rf "$tmp"
```

---

### `theme-engine/.config/theme-engine/lib/reload.sh` (service, event-driven)

**Analog:** `theme-switch.sh` `reload_all()` (lines 43-50) — this function is the exact pattern, becomes the single owner per D-04 (called once, only after commit.sh succeeds, never from matugen `post_hook`s).

```bash
reload_all() {
    hyprctl reload
    pkill -SIGUSR2 waybar || true
    pkill -SIGUSR1 kitty || true
    swaync-client -rs || true
    ~/.config/hypr/scripts/gtk-reload.sh
    ~/.config/hypr/scripts/walker-restart.sh
}
```
Update the two script-path calls to point at the new engine's `lib/gtk.sh` and a hardened walker-restart (see next sections); add `vscodium-theme.sh` call (currently invoked separately at each call site — theme-switch.sh line 72/108, theme-init.sh line 53/81, wallpaper-picker.sh line 153) and fold it into this single fan-out per D-01's "engine owns ALL reload fan-out."

**GTK_THEME propagation excerpt to keep, but relocate to a single owner per D-13/PIPE-05** (currently duplicated in `theme-init.sh` lines 22-25 AND `gtk-reload.sh` lines 10-14):
```bash
export GTK_THEME=adw-gtk3-dark
systemctl --user import-environment GTK_THEME 2>/dev/null
dbus-update-activation-environment --systemd GTK_THEME 2>/dev/null
```

---

### `theme-engine/.config/theme-engine/lib/gtk.sh` (utility, request-response)

**Analog:** `hypr/.config/hypr/scripts/gtk-reload.sh` (full file, 29 lines) — nearly the whole file carries over, minus the `cat colors.css gtk-base.css > gtk.css` concatenation (lines 4-8), which D-08 removes since `gtk.css` becomes a static `@import` file.

**gsettings toggle pattern to keep exactly** (lines 16-20):
```bash
gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" 2>/dev/null
gsettings set org.gnome.desktop.interface gtk-theme "" 2>/dev/null
sleep 0.1
gsettings set org.gnome.desktop.interface gtk-theme "adw-gtk3-dark" 2>/dev/null
```

**Thunar daemon-only restart pattern to keep, per D-15 (never kill visible windows — this script already only restarts the daemon, confirm no windowed-Thunar kill exists)** (lines 22-29):
```bash
if pgrep -x thunar >/dev/null 2>&1; then
    thunar --quit 2>/dev/null
    sleep 0.5
    GTK_THEME=adw-gtk3-dark uwsm app -- thunar --daemon &
    disown
fi
```
Note: `thunar --quit` terminates the whole Thunar session including open windows in some configurations — Plan 01-03 should verify this only kills the daemon, not windowed instances, per D-15; if it does kill windows, replace with a bounded pgrep/kill targeting only the daemon PID (no windows), per the "bounded poll loop" Don't-Hand-Roll pattern in RESEARCH.md.

**Sleep-based wait to replace with bounded poll** (line 26, `sleep 0.5` — RESEARCH.md's "Don't Hand-Roll" table explicitly flags fixed sleeps here):
```bash
# REPLACE:
sleep 0.5
# WITH (pattern from RESEARCH.md Don't-Hand-Roll table):
until ! pgrep -x thunar >/dev/null 2>&1; do sleep 0.1; done  # capped iteration count
```

---

### `theme-engine/.config/theme-engine/theme-doctor` (utility, request-response — new capability)

**Nearest analog:** `hypr/.config/hypr/scripts/walker-restart.sh` (lines 12-16 — the "verify state before declaring success" fragment is the only existing precedent for a check-then-report shape):
```bash
if [[ ! -f "$WALKER_DIR/style.css" ]]; then
    notify-send -a "Walker" "Warning" "style.css missing — generating default" -t 2000
    ~/.config/hypr/scripts/walker-theme-gen.sh
fi
```

**Invariants to check, sourced directly from D-25 and this phase's verified findings (RESEARCH.md):**
- `pacman -Q adw-gtk-theme` (Package Legitimacy Audit / root cause)
- `gsettings get org.gnome.desktop.interface gtk-theme` == `adw-gtk3-dark`
- `elephant listproviders` output vs `walker/.config/walker/config.toml`'s configured `[providers]` list (Pitfall W2 — this session found 3 configured providers with no installed elephant package)
- Presence of `~/.local/state/theme/current-theme` and per-app output files (D-05/D-06 contract)
- No stow conflicts (`stow -n` dry-run pattern, see `stow.sh`)

No code excerpt to copy for the check logic itself (new); use `elephant version`/`elephant listproviders` CLI per RESEARCH.md "Don't Hand-Roll" table (verified this session as the correct primitive, not an ad-hoc `sleep`+socket check).

---

### `theme-engine/.config/theme-engine/palettes/<name>.json` (6 files: catppuccin, dracula, gruvbox, nord, rosepine, tokyonight)

**Analog/source data:** `themes/.config/themes/css/<name>.css` (e.g. `themes/.config/themes/css/catppuccin.css` — read for role-name → hex mapping; NOT the GTK-specific `gtk/<name>.css` files, which are a color subset for the GTK4 named-color spec, verified above).

**Verified matugen JSON schema (RESEARCH.md, empirically tested against installed matugen 4.1.0):**
```json
{
  "colors": {
    "image": "",
    "primary": { "default": { "color": "#cba6f7" } },
    "on_primary": { "default": { "color": "#1e1e2e" } },
    "background": { "default": { "color": "#1e1e2e" } }
  }
}
```

**Conversion pattern (illustrative, RESEARCH.md Code Examples):**
```bash
awk -F'[ ;]' '/@define-color/{printf "  \"%s\": {\"default\": {\"color\": \"%s\"}},\n", $2, $3}' \
    themes/.config/themes/css/catppuccin.css
```
**Must add manually per preset (not present in source CSS):** `tertiary_container` role (Pitfall G2 — missing role breaks kitty template render for ALL 6 presets if omitted) and `image` (empty string, avoids `ResolveError` on `hyprland-colors.conf`'s `{{colors.image}}` reference).

---

### `matugen/.config/matugen/config.toml` (config, transform)

**Analog:** itself, current version (86 lines read in full above).

**Remove entirely** (lines 8-15 — mandatory per Pitfall G1, crashes `matugen json` otherwise):
```toml
[config.wallpaper]
command = "awww"
arguments = [ ... ]
set = true
```

**Strip every `post_hook =` line** (10 occurrences across `[templates.hyprland]`, `[templates.waybar]`, `[templates.kitty]`, `[templates.swaync]`, `[templates.vscodium]`, `[templates.gtk4]`, `[templates.walker]`) per D-04 — reload becomes `lib/reload.sh`'s sole responsibility.

**Update every `output_path`** from `~/.config/<app>/...` to the state-dir contract (D-05/D-06) — actual redirection happens via the `-p/--prefix` CLI flag at invocation time (verified primitive, RESEARCH.md Pattern 2), so `output_path` values can stay relative-shaped but must be reviewed to match the intended `~/.local/state/theme/<app-file>` layout when NOT using `-p` (e.g. for `theme-doctor`'s introspection).

---

### `gtk/.config/gtk-3.0/gtk.css`, `gtk/.config/gtk-4.0/gtk.css` (config, file-I/O)

**Analog:** themselves, current versions (both read in full above — currently end with `/* Colors are prepended automatically by theme-switch / matugen */` after being overwritten by `cat colors.css gtk-base.css >` on every switch).

**New static pattern (RESEARCH.md Pattern 3, verified GTK `@import` relative-path semantics):**
```css
/* File: gtk/.config/gtk-3.0/gtk.css, resolved live path after stow:
   ~/.config/gtk-3.0/gtk.css → relative to ~/.local/state/theme/ is ../../.local/state/theme/ */
@import url('../../.local/state/theme/gtk-3.0-colors.css');

/* hand-written overrides below, unchanged from today's gtk-base.css content */
```
This file becomes git-tracked and STOWED (no longer regenerated) — the current `@define-color` block (lines 1-33 in both files) is dropped entirely; only the trailing custom-overrides comment/content survives, now sourced from `gtk-base.css` unchanged.

---

### `install.sh` (config, batch)

**Analog:** itself — `PACMAN_PKGS` array declaration (line 41 onward) and `AUR_PKGS` array (lines 146-185, `adw-gtk3` at line 150).

**Fix pattern:**
```bash
# REMOVE from AUR_PKGS (line 150):
    adw-gtk3

# ADD to PACMAN_PKGS array (official `extra` repo, no AUR helper needed):
    adw-gtk-theme
```
Same file/pattern shape applies to the elephant-provider gap (Pitfall W2, disposition per audit) if Plan 01-01 assigns it `fix-in-phase-1`: add `elephant-runner elephant-websearch elephant-files` to `AUR_PKGS` alongside the existing `elephant-*` block (lines 154-160).

---

## Shared Patterns

### Reload fan-out (single owner)
**Source:** `hypr/.config/hypr/scripts/theme-switch.sh:43-50` (`reload_all()`)
**Apply to:** `theme-engine/lib/reload.sh` only — every other call site (theme-init.sh, wallpaper-picker.sh, matugen post_hooks) must stop calling reload steps directly and instead call `theme-apply` or nothing at all.
```bash
reload_all() {
    hyprctl reload
    pkill -SIGUSR2 waybar || true
    pkill -SIGUSR1 kitty || true
    swaync-client -rs || true
    ~/.config/hypr/scripts/gtk-reload.sh
    ~/.config/hypr/scripts/walker-restart.sh
}
```

### Notify-send feedback (success + error)
**Source:** `hypr/.config/hypr/scripts/theme-switch.sh:76-77, 86-90, 96-100, 111-113`
**Apply to:** `theme-apply` (all code paths), keep icon/app-name conventions (`-a "Theme Switcher"`, `preferences-desktop-theme`/`dialog-error` icons, 3000/5000ms timeouts).

### GTK_THEME single source of truth
**Source (current, triplicated):** `uwsm/.config/uwsm/env:16` (`export GTK_THEME=adw-gtk3-dark`), `hypr/.config/hypr/config/env.conf:14` (`env = GTK_THEME,adw-gtk3-dark`), `hypr/.config/hypr/scripts/gtk-reload.sh:12` (runtime `export`)
**Apply to:** Consolidate to `uwsm/.config/uwsm/env` only (D-13); `theme-engine/lib/gtk.sh` keeps ONLY the propagation commands, not a redundant hardcoded `export`:
```bash
systemctl --user import-environment GTK_THEME 2>/dev/null
dbus-update-activation-environment --systemd GTK_THEME 2>/dev/null
```

### State file read/write
**Source:** `hypr/.config/hypr/scripts/theme-init.sh:19` (read, with fallback) and `theme-switch.sh:75` (write)
```bash
THEME=$(cat "$STATE_FILE" 2>/dev/null || echo "catppuccin")
...
echo "$name" > "$STATE_FILE"
```
**Apply to:** `theme-apply` (write) and `theme-init.sh` thin caller (read) — `STATE_FILE` moves to `~/.local/state/theme/current-theme` per D-05/D-10.

### Bounded process-exit poll (replacing fixed sleeps)
**Source:** RESEARCH.md "Don't Hand-Roll" table, no in-repo precedent exists (current code uses `sleep 0.5`/`sleep 0.3` at `gtk-reload.sh:26`, `walker-restart.sh:20,26`)
**Apply to:** `lib/gtk.sh` (Thunar restart) and hardened walker restart — replace every `sleep N` used as a wait-for-exit with:
```bash
until ! pgrep -x <procname> >/dev/null 2>&1; do sleep 0.1; done  # cap iterations
```

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `theme-engine/.config/theme-engine/lib/commit.sh` | utility | file-I/O | No atomic render-then-commit precedent exists anywhere in the repo; must be built fresh from RESEARCH.md's verified `matugen -p/--prefix` primitive, not copied from any existing script. |
| `theme-engine/.config/theme-engine/theme-doctor` | utility | request-response | New capability (D-25); nearest precedent (`walker-restart.sh`'s inline verify-fragment) covers only one of five required checks — build the rest from `elephant`/`pacman`/`gsettings`/`stow -n` CLI primitives per RESEARCH.md "Don't Hand-Roll." |
| Hardened Walker restart (replacing `walker-restart.sh`'s `hotreload_theme` assumption) | utility | request-response | D-16's premise (`hotreload_theme` config key) does not exist in walker 2.16.2 source (Pitfall W1) — no reload-avoidance path to pattern-match; only the existing kill/relaunch shape in `walker-restart.sh` applies, hardened with the bounded-poll + `elephant listproviders` health check pattern above. |

## Metadata

**Analog search scope:** `hypr/.config/hypr/scripts/`, `matugen/.config/matugen/`, `themes/.config/themes/`, `gtk/.config/gtk-{3,4}.0/`, `uwsm/.config/uwsm/`, `install.sh`, `stow.sh`
**Files scanned:** 16 scripts/configs read in full (theme-switch.sh, theme-init.sh, gtk-reload.sh, walker-restart.sh, walker-theme-gen.sh, wallpaper-picker.sh, vscodium-theme.sh, matugen/config.toml, gtk-3.0/gtk.css, gtk-4.0/gtk.css, uwsm/env, hypr/config/env.conf, install.sh, stow.sh, .stow-local-ignore, hypr/config/keybinds.conf + autostart.conf grep)
**Pattern extraction date:** 2026-07-07
