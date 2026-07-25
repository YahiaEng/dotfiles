---
phase: 06-themed-surfaces-utility-suite
reviewed: 2026-07-13T04:35:00Z
depth: standard
files_reviewed: 38
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
  - hypr/.config/hypr/scripts/font-switch.sh
  - hypr/.config/hypr/scripts/font-switcher.sh
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
  - theme-engine/.config/theme-engine/theme-doctor
  - waybar/.config/waybar/style-floating.css
  - waybar/.config/waybar/style-full.css
  - waybar/.config/waybar/style-minimal.css
  - wlogout/.config/wlogout/layout
  - wlogout/.config/wlogout/style.css
findings:
  critical: 2
  warning: 12
  info: 10
  total: 24
status: issues_found
---

# Phase 06: Code Review Report

**Reviewed:** 2026-07-13T04:35:00Z
**Depth:** standard
**Files Reviewed:** 38
**Status:** issues_found

## Summary

Re-review of Phase 06 at current HEAD after gap-closure plans 06-16..06-19.

**Regression sanity-check of the claimed fixes — all four verified present and correct:**

| Claim | Verdict | Evidence |
|---|---|---|
| 06-16: wlogout `::after`/`content` rulesets removed | **CONFIRMED FIXED** | Live GTK 3 `CssProvider.load_from_path("~/.config/wlogout/style.css")` now yields **4589 bytes, 0 parse errors** (was 0 bytes / whole sheet discarded). |
| 06-16: wlogout `layout` button glyphs populated | **CONFIRMED FIXED** | All six `text` fields carry Nerd Font glyphs. |
| 06-17: color-picker stdout misclassification / clipboard-wipe empty-db / trap-based mktemp cleanup / pgrep argv[0] bounding | **CONFIRMED FIXED** | `color-picker.sh:30` classifies on combined stderr+stdout; `clipboard-wipe.sh:18` uses `\|\| true` + `${COUNT:-0}`; single EXIT trap at `font-switcher.sh:55` / `icon-theme-picker.sh:49`; `record-toggle.sh` uses `"^gpu-screen-recorder "` (trailing space) at all four pgrep/pkill sites. |
| 06-18: `reload.sh` `\|\| echo 0` idiom removed; `commit.sh` excludes `walker-relaunch.log` | **CONFIRMED FIXED** | `reload.sh:119-121` now `$(grep -c ...) \|\| true` + `${var:-0}`; `commit.sh:82` carries `--exclude=walker-relaunch.log`. |
| 06-19: theme-doctor GTK CSS-parse guard | **PRESENT but PARTIALLY INEFFECTIVE** | GTK3 half works (verified live). GTK4 half is a **no-op** (WR-02), and a not-deployed sheet still yields a green run (WR-04). |

Nothing regressed. The review surfaces **2 new Critical defects** the gap-closure work did not touch — both at the seam between Phase 05's light-mode pipeline and Phase 06's utility surfaces — plus warnings concentrated in `theme-doctor`'s new guard (which is weaker than its own comments claim) and `swayosd/style.css` (which omits selectors the installed swayosd 0.3.1 actually renders).

---

## Critical Issues

### CR-01: Icon-theme variant fallback silently discards the user's pick and desyncs GTK3 from GTK4

**File:** `theme-engine/.config/theme-engine/lib/gtk.sh:389-416` (call site `:294-307`)

**Issue:** `theme_engine_nearest_icon_variant` computes an "ideal" variant suffix via `theme_engine_nearest_papirus_color`, whose enum is **papirus-folders'** 23-name vocabulary (`carmine-red`, `deeporange`, `paleorange`, `palebrown`, `oxidgreen`, `breeze`, `nordic`, `indigo`, `violet`, …). Tela/Colloid variants are **not** named from that vocabulary (they are `Tela-blue`, `Tela-nord`, `Tela-dracula`, `Colloid-teal`, …). The exact-match branch at `:409-410` therefore almost never hits, and control reaches the fallback at `:415`:

```bash
printf '%s\n' "${installed[0]}"
```

Three defects follow:

1. **The user's explicit pick is silently replaced.** The call site treats *any* non-empty return as authoritative:
   ```bash
   local nearest="$icon_theme"
   found="$(theme_engine_nearest_icon_variant "$base" "$hex")"
   [[ -n "$found" ]] && nearest="$found"          # gtk.sh:303-305
   gsettings set org.gnome.desktop.interface icon-theme "$nearest"
   ```
   A user who picks `Tela-circle` gets `installed[0]` applied instead — on *every* theme switch, defeating the point of `icon-theme-picker.sh` persisting the axis at all.

2. **`installed[0]` is nondeterministic.** It comes from `find ... -print0` (`:398-400`) with no `sort`, i.e. directory order — the applied theme can differ run to run and machine to machine.

3. **GTK3 and GTK4 end up on different icon themes.** `generate.sh:119,137-143` writes `gtk-icon-theme-name=<state-file value>` into both `settings.ini` files, while `gtk.sh:306` writes the *substituted* `$nearest` into gsettings. GTK3 apps (Thunar) read `settings.ini`; GTK4/portal apps read gsettings — they now disagree.

**Fix:** the fallback must mean "no substitution", not "an arbitrary installed variant". Return nothing so the caller keeps the user's own pick, and sort for determinism:

```bash
    mapfile -t installed < <(printf '%s\n' "${installed[@]}" | sort -u)
    [[ ${#installed[@]} -gt 0 ]] || return 0

    local ideal
    ideal="$(theme_engine_nearest_papirus_color "$hex")"

    local candidate
    for candidate in "${installed[@]}"; do
        [[ "$candidate" == "${base}-${ideal}" ]] && { printf '%s\n' "$candidate"; return 0; }
    done

    # No exact color match among installed variants — emit NOTHING so the
    # caller keeps the user's own explicitly-picked theme name (CR-01).
    return 0
```

Also keep the two writers in lockstep: whatever name reaches `gsettings` must be the name `generate.sh` writes into `settings.ini`. The simplest correct shape is to drop hue-tracking for Tela/Colloid entirely (the state file *is* the pick) and keep it only for Papirus, where `papirus-folders` recolors folders **without changing the theme name** — which is exactly why that branch is safe and this one is not.

---

### CR-02: `theme-doctor` hardcodes `adw-gtk3-dark`, so it fails (exit 1) on every light-mode preset shipped in Phase 05

**File:** `theme-engine/.config/theme-engine/theme-doctor:40-42`

**Issue:**

```bash
GTK_THEME_VALUE=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | tr -d "'")
[[ "$GTK_THEME_VALUE" == "adw-gtk3-dark" ]]
check "gsettings gtk-theme = adw-gtk3-dark (got: ${GTK_THEME_VALUE:-<unset>})" "$?"
```

`lib/gtk.sh:22-25` deliberately sets `gtk-theme` to **`adw-gtk3`** (no `-dark`) whenever the committed mode marker is `light`, and `lib/generate.sh:107-110` does the same for `settings.ini`. Phase 05 shipped six light presets (`catppuccin-latte`, `gruvbox-light`, `tokyonight-day`, `rosepine-dawn`, `kanagawa-lotus`, `materialyou-light`).

Consequence: on a **fully correct** light-mode desktop `theme-doctor` prints `[FAIL] gsettings gtk-theme = adw-gtk3-dark (got: adw-gtk3)` and exits non-zero (`:300-301`). The project's own health gate — the tool every verification round runs — is guaranteed to red-flag a valid state. That is worse than a missing check: it trains the operator to ignore the gate.

**Fix:** read the committed mode marker (the same source of truth `gtk.sh` uses) and assert the mode-correct value:

```bash
DOCTOR_MODE=$(cat "$STATE_DIR/mode" 2>/dev/null || echo "dark")
EXPECTED_GTK_THEME="adw-gtk3-dark"
[[ "$DOCTOR_MODE" == "light" ]] && EXPECTED_GTK_THEME="adw-gtk3"

GTK_THEME_VALUE=$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null | tr -d "'")
[[ "$GTK_THEME_VALUE" == "$EXPECTED_GTK_THEME" ]]
check "gsettings gtk-theme = $EXPECTED_GTK_THEME (mode=$DOCTOR_MODE, got: ${GTK_THEME_VALUE:-<unset>})" "$?"
```

---

## Warnings

### WR-01: Headless guard in `reload.sh` uses `&&` where the intent is "not a graphical session"

**File:** `theme-engine/.config/theme-engine/lib/reload.sh:33`

**Issue:**

```bash
if [[ -z "${WAYLAND_DISPLAY:-}" && -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
```

The guard only trips when **both** are empty. On a real Arch TTY login — the exact context `stow.sh:119` seeds the first-boot theme from (`"$THEME_APPLY" catppuccin`) — `DBUS_SESSION_BUS_ADDRESS` is normally set (`unix:path=/run/user/$UID/bus`, exported by pam_systemd) while `WAYLAND_DISPLAY` is not. The guard is therefore **defeated in the very scenario it was added for** (the INST-03 hang), and the full fan-out runs with no compositor: `hyprctl reload` fails, `killall -q walker` runs, `setsid uwsm app -- walker --gapplication-service` spawns a walker that cannot reach a display, the 2s liveness poll (`:305-313`) exhausts, and a "persistent" error notification is raised into a session with no notification daemon.

The container gate (neither var set) passes only because it happens to lack D-Bus — so the bug is invisible there and live on real hardware.

**Fix:** `WAYLAND_DISPLAY` alone is the graphical-session signal for this stack:

```bash
    if [[ -z "${WAYLAND_DISPLAY:-}" ]]; then
        echo "theme_engine_reload: no graphical session detected — skipping reload fan-out (committed state applies at next login)"
        return 0
    fi
```

### WR-02: The GTK4 half of the new CSS-parse guard is a no-op, and its justifying comment is factually wrong

**File:** `theme-engine/.config/theme-engine/theme-doctor:233-258`

**Issue:** The guard's comment asserts:

> "GTK4's CssProvider exposes no equivalent 'parsing-error' signal in this binding (verified: zero signals on the GType), so GTK4 relies on the non-empty-provider check alone below, which still catches a fully-discarded sheet."

Both halves of that claim are false — verified directly on this machine:

- `Gtk.CssProvider().connect("parsing-error", cb)` under `gi.require_version("Gtk", "4.0")` **succeeds**; the signal exists.
- GTK4 **never discards a whole stylesheet** on a rule error (unlike GTK3, which is precisely the WLOG-01 signature). It skips the offending rule and retains the rest, so `if not css:` can essentially never fire for GTK4.

Net effect: for the three sheets in `GTK4_CSS_SHEETS` (`gtk-4.0/gtk.css`, `swayosd/style.css`, `walker/themes/rice/style.css`) the guard performs **no detection at all** — it can only ever print PASS. A GTK4-invalid rule in walker's or swayosd's stylesheet ships silently: the same class of blind spot WLOG-01 was.

**Fix:** connect `parsing-error` in both branches — the code is already written for GTK3; just drop the `if major == "3":` gate:

```python
    provider = Gtk.CssProvider()
    fatal = []

    def _on_error(_provider, _section, error, _fatal=fatal):
        # gtk-css-provider-error-quark code 4 == deprecation (non-fatal)
        if error.code != 4:
            _fatal.append(error.message)

    provider.connect("parsing-error", _on_error)
```

### WR-03: CSS-parse guard silently vanishes if the Gtk typelib is missing — no PASS, no FAIL, still exit 0

**File:** `theme-engine/.config/theme-engine/theme-doctor:262, 207`

**Issue:** The gate is `python3 -c "import gi"`, but the inner script's real failure mode is `gi.require_version("Gtk", "3.0")` / `from gi.repository import Gtk` raising when the **typelib** (not the `gi` module) is absent. `_theme_doctor_css_parse` sends all stderr to `/dev/null` (`:207`), so that exception yields **zero stdout lines**; the two `while IFS=$'\t' read ...` loops (`:263-281`) iterate zero times, every CSS check disappears from the report, and `theme-doctor` still exits 0.

This is exactly the failure mode the file explicitly guards against 200 lines earlier for the contract file list ("An empty list … must surface as a loud FAIL — not ten per-file checks silently vanishing from the output", `:50-54`). The new guard does not apply its own rule to itself.

**Fix:** count emitted lines and FAIL when a run produced none (this also de-duplicates the two copy-pasted loops):

```bash
    run_css_guard() {
        local major="$1"; shift
        local emitted=0 status frag detail desc
        while IFS=$'\t' read -r status frag detail; do
            [[ -z "$status" ]] && continue
            emitted=$(( emitted + 1 ))
            desc="CSS-parse: $frag ($detail)"
            case "$status" in
                SKIP) echo "  [SKIP] $desc" ;;
                PASS) check "$desc" "0" ;;
                *)    check "$desc" "1" ;;
            esac
        done < <(_theme_doctor_css_parse "$major" "$@")
        if (( emitted == 0 )); then
            check "GTK${major} CSS-parse guard produced output (Gtk-${major}.0 typelib present)" "1"
        fi
    }
    run_css_guard 3 "${GTK3_CSS_SHEETS[@]}"
    run_css_guard 4 "${GTK4_CSS_SHEETS[@]}"
```

### WR-04: `SKIP` on a not-deployed stylesheet lets a completely unthemed surface pass as green

**File:** `theme-engine/.config/theme-engine/theme-doctor:226-228`

**Issue:** Reproduced live on this machine right now:

```
  [SKIP] CSS-parse: swayosd/style.css (not deployed under ~/.config — run stow.sh)
  ...
  Summary: 39 passed, 1 failed        # the single failure is the unrelated git-clean check
```

`~/.config/swayosd/style.css` does not exist (`swayosd` *is* listed in `stow.sh`'s `PACKAGES` and *is* tracked in git, but was never restowed here), yet `autostart.conf:36` unconditionally launches `swayosd-server`. The OSD pill is therefore rendering with **zero** of this phase's theming — and the phase's own new regression guard reports SKIP, a non-failure. The guard exists because "four prior verification rounds all reported PASS while wlogout's stylesheet was silently discarded"; SKIP-on-absent reintroduces the same blind spot in a new coat.

**Fix:** a stylesheet the pipeline *owns* being absent from `~/.config` is a deployment failure, not a skip. Emit `check "$desc" "1"` for the not-deployed case (or add an explicit "all stow packages deployed" check). If a genuinely optional sheet is added later, mark it optional via an explicit allowlist rather than blanket-SKIPping every missing path.

### WR-05: `swayosd/style.css` omits the selectors the installed swayosd 0.3.1 actually renders

**File:** `swayosd/.config/swayosd/style.css:35-47`

**Issue:** SwayOSD's user stylesheet **replaces** the shipped default rather than layering on top of it. The default for the installed `swayosd 0.3.1` (`/etc/xdg/swayosd/style.css`, read directly) defines:

```css
  window#osd progressbar, window#osd segmentedprogress { ... }
  window#osd trough,      window#osd segment           { ... }
  window#osd progress,    window#osd segment.active    { ... }
  window#osd segment { margin-left: 8px; }
  window#osd segment:first-child { margin-left: 0; }
  window#osd progressbar:disabled, window#osd image:disabled { opacity: 0.5; }
```

The repo's stylesheet styles only `progressbar`, `progressbar > trough`, and `progressbar > trough > progress`. It has **no** `segmentedprogress` / `segment` / `segment.active` rules and **no** `:disabled` rule. On the installed version that means:

- The **segmented** volume indicator (which this swayosd version ships selectors for) falls back to raw GTK4 defaults — the pipeline's `@primary` accent never reaches it.
- The **muted-state cue** (upstream's `opacity: 0.5` on `progressbar:disabled` / `image:disabled`) is gone entirely, so mute and unmute look identical.

**Fix:** mirror the upstream selector set with the pipeline's named colors:

```css
progressbar,
progressbar > trough,
segmentedprogress,
segment {
    min-height: 6px;
    border-radius: 999px;
    background-color: alpha(@surface_variant, 0.6);
}

progressbar > trough > progress,
segment.active {
    min-height: 6px;
    border-radius: 999px;
    background-color: @primary;
}

segment { margin-left: 8px; }
segment:first-child { margin-left: 0; }

/* Muted/disabled cue — upstream default, lost when the user sheet replaces it */
progressbar:disabled,
image:disabled {
    opacity: 0.5;
}
```

### WR-06: `clipboard-wipe.sh` confirms a destructive action then dies at exit 127 if `cliphist` is absent

**File:** `hypr/.config/hypr/scripts/clipboard-wipe.sh:11-20, 38`

**Issue:** `command -v cliphist` guards only the *count* (`:11`). The actual destructive call at `:38` is unguarded:

```bash
cliphist wipe
```

With `cliphist` missing, `COUNT` stays `0`, the confirm dialog renders ("This clears all **0** saved clipboard entries"), the user selects Yes, and the script dies at `set -e` / exit 127 with **no notification at all** — the user is left believing the wipe happened. Secondarily, the `0`-entry wording is a defect in its own right: no destructive confirm should be offered for an empty history.

**Fix:**

```bash
if ! command -v cliphist >/dev/null 2>&1; then
    notify-send -a "Clipboard" "Error" "cliphist not installed" -i dialog-error -t 6000 2>/dev/null || true
    exit 1
fi

COUNT=$(cliphist list 2>/dev/null | wc -l | tr -d '[:space:]' || true)
COUNT=${COUNT:-0}

if [[ "$COUNT" -eq 0 ]]; then
    notify-send -a "Clipboard" "Nothing to Wipe" "Clipboard history is already empty" -i edit-clear -t 2000 2>/dev/null || true
    exit 0
fi
```

…then keep the existing default-No confirm for the non-empty case.

### WR-07: Brightness keys bypass SwayOSD entirely — no OSD pill on brightness change

**File:** `hypr/.config/hypr/config/keybinds.conf:160-161`

**Issue:**

```
bindel = , XF86MonBrightnessUp,   exec, brightnessctl -e4 -n2 set 5%+
bindel = , XF86MonBrightnessDown, exec, brightnessctl -e4 -n2 set 5%-
```

Volume/mic route through `swayosd-client` (`:149-152`) and get the themed pill; brightness calls `brightnessctl` directly and gets nothing. `swayosd-libinput-backend.service` does **not** cover this — the file's own comment at `:147-148` correctly notes it only handles the keyless caps-lock path. OSD-01's "volume **and brightness** OSD" is therefore half-delivered, and the two key families behave inconsistently.

**Fix:**

```
bindel = , XF86MonBrightnessUp,   exec, swayosd-client --brightness raise
bindel = , XF86MonBrightnessDown, exec, swayosd-client --brightness lower
```

(swayosd-server owns the backlight write and the pill; the `min_brightness = 5` floor is already set in `/etc/xdg/swayosd/config.toml`.)

### WR-08: Zen self-heal destroys a pre-existing real `userChrome.css` with no backup

**File:** `theme-engine/.config/theme-engine/lib/reload.sh:167`

**Issue:**

```bash
ln -sf "$STATE_DIR/zen-userchrome.css" "$profile_dir/chrome/userChrome.css"
```

`ln -sf` unlinks whatever is at the destination first. If the user already has a hand-written `userChrome.css` in their Zen profile — common for anyone who runs Zen — the **first theme switch after this ships silently deletes it**, unrecoverably. `-f` also removes any "already correct, skip" fast path.

**Fix:** back up a real (non-symlink) file before replacing, and no-op when the link is already correct:

```bash
    local chrome_css="$profile_dir/chrome/userChrome.css"
    if [[ -e "$chrome_css" && ! -L "$chrome_css" ]]; then
        mv -n "$chrome_css" "$chrome_css.pre-theme-engine.bak" 2>/dev/null || true
        echo "theme_engine_reload_zen: backed up existing userChrome.css to $chrome_css.pre-theme-engine.bak"
    fi
    ln -sfn "$STATE_DIR/zen-userchrome.css" "$chrome_css"
```

### WR-09: `emoji-picker.sh` claims "typed and copied" on the copy-only degraded path

**File:** `hypr/.config/hypr/scripts/emoji-picker.sh:229-240`

**Issue:** When `wtype` is absent the script deliberately degrades to copy-only (`:231-236`, an explicit `:` no-op), but the notification is unconditional:

```bash
notify-send -a "Emoji Picker" "Emoji Inserted" "$EMOJI typed and copied to clipboard" ...
```

The user is told the glyph was typed into the focused app when it was not — they will not paste, and the emoji lands nowhere. Additionally `wl-copy` at `:238` has no `command -v` guard, so on a machine without `wl-clipboard` the script dies at 127 with no message at all.

**Fix:**

```bash
TYPED=0
if command -v wtype >/dev/null 2>&1; then
    wtype "$EMOJI" && TYPED=1
fi

if command -v wl-copy >/dev/null 2>&1; then
    printf '%s' "$EMOJI" | wl-copy
fi

if (( TYPED == 1 )); then
    MSG="$EMOJI typed and copied to clipboard"
else
    MSG="$EMOJI copied to clipboard (install wtype to type directly)"
fi
notify-send -a "Emoji Picker" "Emoji Inserted" "$MSG" -i face-smile -t 2000 2>/dev/null || true
```

### WR-10: `theme-doctor` writes to a predictable, world-writable temp path

**File:** `theme-engine/.config/theme-engine/theme-doctor:88`

**Issue:**

```bash
(cd "$DOTFILES_DIR" && stow -n theme-engine >/dev/null 2>/tmp/theme-doctor-stow.log)
```

`/tmp/theme-doctor-stow.log` is a fixed name in a shared, world-writable directory. Another local uid can pre-create it as a symlink to an arbitrary file the invoking user can write; the redirect then truncates that target. Low likelihood on a single-user desktop, but it is a textbook insecure-temp-file pattern and every other script in this phase already uses `mktemp` correctly.

**Fix:**

```bash
STOW_LOG=$(mktemp -t theme-doctor-stow-XXXXXX.log)
trap 'rm -f "$STOW_LOG"' EXIT
...
(cd "$DOTFILES_DIR" && stow -n theme-engine >/dev/null 2>"$STOW_LOG")
```

### WR-11: `ffmpeg` is a direct dependency of `gif-export.sh` but is absent from `PACMAN_PKGS`, so `verify_packages` cannot catch it

**File:** `install.sh:52-177` (package list), `hypr/.config/hypr/scripts/gif-export.sh:26,33`

**Issue:** `gif-export.sh` invokes `ffmpeg` twice with no `command -v` guard. `ffmpeg` reaches the target only *transitively* (pulled by `ffmpegthumbnailer` / `vlc`). `verify_packages` (`install.sh:406-432`) — the explicit "no more ghost packages like adw-gtk3" hard-fail gate — only checks names present in the arrays, so a future dependency-graph change that drops that transitive edge produces a fresh install where GIF export dies at 127 while the installer still reports success. Given `install.sh` is the project's reproducibility guarantee, an undeclared direct dependency defeats the gate's whole purpose. (`ffmpeg` is confirmed present in official `extra`.)

Same file, related: `xdg-user-dirs` is installed with the comment "creates ~/Pictures so screenshot-dir resolution is deterministic" (`:160-162`), but `xdg-user-dirs-update` is **never invoked**, so the stated guarantee does not hold. (In practice the capture scripts `mkdir -p` their own dir, so this is an overpromising comment rather than a live failure.)

**Fix:** add `ffmpeg` to `PACMAN_PKGS` so `verify_packages` covers it, and either invoke `xdg-user-dirs-update` in `section_core_rice` or correct the comment.

### WR-12: `generate.sh` and `font.sh` depend on an undeclared `$STATE_DIR` under `set -u`

**File:** `theme-engine/.config/theme-engine/lib/generate.sh:81,131`, `theme-engine/.config/theme-engine/lib/font.sh:37`

**Issue:** Both files build output paths from `$STATE_DIR`:

```bash
mkdir -p "$tmp$STATE_DIR"                     # generate.sh:81
local out_dir="$tmp$STATE_DIR"                # generate.sh:131, font.sh:37
```

Neither file defines it. `STATE_DIR` is defined only in `commit.sh:9` and `reload.sh:11`. Under `set -euo pipefail`, any consumer that sources `generate.sh` *without first* sourcing `commit.sh` — e.g. a report-only tool like `theme-parity`, which by design must not pull in commit logic — aborts with `STATE_DIR: unbound variable`. The coupling is invisible: nothing in `generate.sh` declares it.

**Fix:** declare it locally in each file that reads it, exactly as `commit.sh` / `reload.sh` already do:

```bash
STATE_DIR="${STATE_DIR:-$HOME/.local/state/theme}"
```

---

## Info

### IN-01: Unitless `border-radius` in `style-floating.css` (confirmed GTK deprecation)

**File:** `waybar/.config/waybar/style-floating.css:8`
**Issue:** `border-radius: 10;` — verified live: GTK3 emits `gtk-css-provider-error-quark` code 4 ("Not using units is deprecated. Assuming 'px'."). Non-fatal today; a future GTK could promote it to fatal, at which point it becomes another whole-sheet discard.
**Fix:** `border-radius: 10px;`

### IN-02: EXIT trap runs `rm -rf ""` on early-abort paths

**File:** `hypr/.config/hypr/scripts/font-switcher.sh:55`, `hypr/.config/hypr/scripts/icon-theme-picker.sh:49`
**Issue:** `trap 'rm -f "$ENUM_SCRIPT" "$PREVIEW_SCRIPT"; rm -rf "$CACHE_DIR"' EXIT` is installed before `CACHE_DIR` is assigned. On the empty-state early exit (`font-switcher.sh:77-83`, `icon-theme-picker.sh:80-87`) the trap runs `rm -rf ""`, printing `rm: cannot remove '': No such file or directory` into the user's floating-kitty window.
**Fix:** `[[ -n "$CACHE_DIR" ]] && rm -rf "$CACHE_DIR"`.

### IN-03: Screenshot filenames collide at one-second resolution

**File:** `hypr/.config/hypr/scripts/capture-region.sh:53-54` (same in `capture-full.sh:28-29`, `capture-window.sh:25-26`)
**Issue:** `screenshot_$(date +%Y%m%d_%H%M%S).png` — two captures completing in the same second silently overwrite each other, and the `[ -f "$FILENAME" ]` "did a file land?" check at `:60` cannot distinguish a fresh save from a leftover from the previous capture.
**Fix:** add sub-second precision (`date +%Y%m%d_%H%M%S_%3N`).

### IN-04: `color-picker.sh` swatch PNG is not covered by the EXIT trap

**File:** `hypr/.config/hypr/scripts/color-picker.sh:22, 53`
**Issue:** The trap covers only `ERR_FILE`. `SWATCH` is created at `:53` and removed manually at `:66`; a SIGTERM/SIGHUP in between leaks a PNG in `/tmp`. The sibling scripts already use the one-trap-covers-all idiom this file introduced.
**Fix:** initialize `SWATCH=""` before the trap and extend it — `trap 'rm -f "$ERR_FILE" "$SWATCH"' EXIT`.

### IN-05: `record-toggle.sh` notification lacks the `|| true` guard used everywhere else

**File:** `hypr/.config/hypr/scripts/record-toggle.sh:209-210`
**Issue:** Every other `notify-send` in this phase ends `2>/dev/null || true`. This one does not, so under `set -e` a notification-daemon failure exits the script with status 1 *after* the recording has already started — a confusing non-zero exit on the success path.
**Fix:** append `2>/dev/null || true`.

### IN-06: `install.sh` clobbers its own mirrorlist backup and leaks CWD

**File:** `install.sh:257, 276`
**Issue:** (a) `sudo cp /etc/pacman.d/mirrorlist /etc/pacman.d/mirrorlist.bak` is unconditional — a second run overwrites the pristine backup with the reflector-generated list, destroying the restore path. (b) `cd /tmp/paru && makepkg -si --noconfirm` leaves the shell's CWD at `/tmp/paru` for the rest of the script; harmless only because every later path happens to be absolute.
**Fix:** guard the backup (`[[ -f /etc/pacman.d/mirrorlist.bak ]] || sudo cp ...`) and run makepkg in a subshell: `( cd /tmp/paru && makepkg -si --noconfirm )`.

### IN-07: `stow.sh` "Next steps" advertises keybinds that do not exist

**File:** `stow.sh:132-134`
**Issue:** Prints `Super+Shift+T` (theme), `Super+Shift+W` (waybar), `Super+Shift+B` (wallpaper). `keybinds.conf:40-42` actually binds `Super+T` (theme), `Super+B` (waybar), `Super+W` (wallpaper) — wrong modifier *and* B/W transposed. This is the first thing a fresh-install user reads.
**Fix:** correct the three lines to `Super+T`, `Super+B`, `Super+W`.

### IN-08: `theme-doctor` provider-parity regex silently drops provider names with digits or hyphens

**File:** `theme-engine/.config/theme-engine/theme-doctor:150`
**Issue:** `grep -oE '"[a-zA-Z_]+"'` cannot match a provider named e.g. `web-search` or `elephant2`. Such a provider is dropped from `CONFIGURED_PROVIDERS` entirely, so it is never checked and the parity check false-passes — the same "silently vanishing check" class as WR-03.
**Fix:** widen to `'"[a-zA-Z0-9_-]+"'`.

### IN-09: `gif-export.sh` overwrites an existing `.gif` without warning

**File:** `hypr/.config/hypr/scripts/gif-export.sh:14, 26, 33`
**Issue:** `OUTPUT="${INPUT%.*}.gif"` combined with `ffmpeg -y` — re-triggering the "Export GIF" notification action on the same recording silently replaces the previous GIF.
**Fix:** either document it as intentionally idempotent, or suffix a counter when `$OUTPUT` already exists.

### IN-10: Hardcoded magic color in the themed satty palette

**File:** `matugen/.config/matugen/templates/satty-colors.toml:29`
**Issue:** `"#E53935ff"` is a literal red among six pipeline-derived swatches. Presumably a deliberate always-available annotation red, but nothing states so, and `theme-parity`'s semantic-value layer will see a color that never varies across themes.
**Fix:** add a one-line comment declaring it a deliberate theme-invariant annotation red, and confirm it is exempted in `contract.json` if parity flags it.

---

_Reviewed: 2026-07-13T04:35:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
