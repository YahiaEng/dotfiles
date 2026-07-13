---
phase: 06-themed-surfaces-utility-suite
reviewed: 2026-07-13T01:02:23Z
depth: standard
files_reviewed: 37
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
  critical: 1
  warning: 6
  info: 9
  total: 16
status: issues_found
---

# Phase 6: Code Review Report

**Reviewed:** 2026-07-13T01:02:23Z
**Depth:** standard
**Files Reviewed:** 37
**Status:** issues_found

## Summary

Fresh complete re-review of the phase 06 surface after gap-closure plans 06-14
(Print-key `code:107` binds, `hyprshot --raw` long form) and 06-15 (vlc,
vlc-plugins-all, xdg-user-dirs in PACMAN_PKGS). The 06-14/06-15 fixes themselves
verify clean: `hyprshot --raw` matches the installed 1.3.0 getopt table
(`r:` short form is genuinely broken, long form required — confirmed against
`/usr/bin/hyprshot`), the `code:107` binds parse (`hyprctl configerrors` is
empty on the live 0.55.4 session), and `vlc-plugins-all` / `xdg-user-dirs` /
`hyprshutdown` all exist in `extra` (confirmed via `pacman -Si`).

Several previously suspicious constructs were verified NOT to be bugs and are
deliberately not flagged: satty's `early-exit = ["all"]` is valid list syntax
in the installed satty 0.21.1 (confirmed against its shipped README — the
0.21.0 changelog changed it from bool to list); the `[color-palette]`
`palette = [...]` schema matches the upstream example; GTK4 accepts
`-gtk-icon-transform` without a parsing error (verified against the installed
GTK 4.22 parser via the `parsing-error` signal), so swayosd's CSS is clean;
and hyprpicker disables fancy ANSI output when stdout is not a TTY (verified
upstream `main.cpp` isatty check), so `color-picker.sh`'s captured hex is
clean on the success path.

However, one Critical defect was found and empirically proven on this machine:
the wlogout stylesheet's `::after`/`content` hover-label rules are not merely
inert — they cause GTK 3.24.52 to discard the ENTIRE stylesheet, leaving
wlogout completely unthemed. Six Warnings cover error-stream misclassification
in color-picker, a `set -e` abort in clipboard-wipe on an empty cliphist db,
a latent arithmetic-error path in the Zen reload, temp-file cleanup gaps in
both fzf pickers, an over-broad `pgrep -f` prefix in record-toggle, and a
missing rsync exclusion in commit.sh for an engine-owned state file.

## Critical Issues

### CR-01: wlogout `::after`/`content` rules cause GTK3 to discard the ENTIRE stylesheet — wlogout renders unthemed

**File:** `wlogout/.config/wlogout/style.css:42-77` (all `::after` rulesets)
**Issue:** GTK3 CSS has no `::after` pseudo-element and no `content` property.
The file contains 8 rulesets using them (`button::after`,
`button:hover::after, button:focus::after`, and `#lock`/`#logout`/`#suspend`/
`#hibernate`/`#shutdown`/`#reboot` `::after`). This was verified empirically on
this machine's GTK 3.24.52 using the exact API wlogout 1.2.2 uses
(`gtk_css_provider_load_from_path` — confirmed in upstream `main.c`, which
merely `g_warning`s the error and proceeds):

- Parsing the repo stylesheet produces 8 × `Invalid name of pseudo-class`.
- Critically, on this GTK version a single parse error discards the **whole
  provider stylesheet**, not just the offending ruleset. A controlled
  `load_from_path` test with a unique selector before AND after a
  `button::after` rule showed **neither** rule applied when the error is
  present, while both applied in the error-free control.

Net effect: none of this file's styling applies — no dim scrim, no themed
buttons, no per-action accent borders, no Nerd Font glyph sizing, no hover
colors. wlogout falls back to stock GTK widget styling. Any impression that
"the rest still applies" is an artifact of the user's global
`~/.config/gtk-3.0/gtk.css` palette bleeding into probes — the wlogout
provider itself contributes nothing. The hover-label reveal feature (lines
41-77) is structurally unimplementable via CSS generated content in GTK3.

**Fix:**
```css
/* Delete ALL ::after rulesets (lines ~41-77: button::after,
   button:hover::after/button:focus::after, and the six #id::after
   content rules). GTK3 cannot express generated content. */
```
Then, if per-action labels are still wanted, use wlogout's native label
mechanism instead — set `"text": "Lock"` etc. in
`wlogout/.config/wlogout/layout` (wlogout renders `text` as the button label;
a permanent caption, not hover-reveal) and style it via `button label { }`.
Verify after the fix expecting zero parse errors, e.g.:
`python3 -c "import gi; gi.require_version('Gtk','3.0'); from gi.repository import Gtk; Gtk.CssProvider().load_from_path('$HOME/.config/wlogout/style.css')"`

## Warnings

### WR-01: color-picker.sh misclassifies real hyprpicker failures as user-cancel (hyprpicker logs only to stdout)

**File:** `hypr/.config/hypr/scripts/color-picker.sh:25-32`
**Issue:** The failure branch reads `$ERR_FILE` (hyprpicker's **stderr**) and
treats "empty stderr" as Esc-cancel (`exit 0`, silent). But hyprpicker never
writes diagnostics to stderr: upstream `src/debug/Log.cpp` states
"hyprpicker only logs to stdout" — every ERR/CRIT message
("zwlr_screencopy_v1 not supported, can't proceed", "No wayland compositor
running!", xkb failures) goes to **stdout**, which the failed command
substitution captures into `$HEX` and discards. So every genuine failure mode
takes the silent-cancel path and the user gets no error notification —
exactly the failure class T-06-18's sanitize-and-notify was built for.
Secondary: on compositors that emit WARN lines during a successful pick,
those stdout lines concatenate into `$HEX` after `tr -d '[:space:]'`,
corrupting the copied value (not triggered on Hyprland today, where the
guarded protocols are all supported).
**Fix:** classify by stdout content instead of stderr:
```bash
OUT=$(hyprpicker -a -f hex 2>"$ERR_FILE") || {
    ERR=$(printf '%s\n%s' "$(cat "$ERR_FILE")" "$OUT" | sanitize)
    [[ -z "$ERR" ]] && exit 0   # true silent cancel
    notify-send -a "Color Picker" "Error" "$ERR" -i dialog-error -t 6000 2>/dev/null || true
    exit 1
}
HEX=$(printf '%s\n' "$OUT" | tail -n1 | tr -d '[:space:]')
[[ "$HEX" =~ ^#?[0-9a-fA-F]{6}$ ]] || exit 1
```

### WR-02: clipboard-wipe.sh silently aborts under `set -e` when the cliphist db is empty/missing

**File:** `hypr/.config/hypr/scripts/clipboard-wipe.sh:12`
**Issue:** Verified on this machine: `cliphist list` exits **1** with
"opening db: please store something first" when nothing has ever been stored
(and after a wipe leaves the db empty). Under `set -euo pipefail`, the
pipeline `cliphist list 2>/dev/null | wc -l | tr -d '[:space:]'` then makes
the `COUNT=$(...)` assignment fail, and `set -e` kills the script **before
the confirm dialog ever appears** — Super+Shift+C becomes a silent no-op on a
fresh install and immediately after any successful wipe. The `2>/dev/null`
only hides the message, not the exit code.
**Fix:**
```bash
COUNT=$(cliphist list 2>/dev/null | wc -l | tr -d '[:space:]' || true)
COUNT=${COUNT:-0}
```
(pipefail makes the whole pipeline non-zero; `|| true` neutralizes it while
`wc`'s output is still captured.)

### WR-03: reload.sh Zen profile counter can become "0\n0" and blow up the `-eq` test

**File:** `theme-engine/.config/theme-engine/lib/reload.sh:119`
**Issue:** `install_sections=$(grep -c '^\[' "$zen_root/installs.ini" 2>/dev/null || echo 0)`
— `grep -c` **always prints a count** ("0") even when it exits 1 for zero
matches, so for an installs.ini that exists but contains no `[` lines the
substitution captures `0` from grep AND `0` from the `|| echo`, yielding the
two-line string `0\n0`. The subsequent `[[ "$install_sections" -eq 1 ]]` is
then an arithmetic syntax error (exit 2) — under theme-apply's `set -e` this
aborts the reload fan-out mid-run (Zen step onward is skipped). Narrow
trigger (malformed/empty installs.ini), but the same `|| echo 0` anti-pattern
is a false-safety idiom worth removing.
**Fix:**
```bash
install_sections=$(grep -c '^\[' "$zen_root/installs.ini" 2>/dev/null) || true
install_sections=${install_sections:-0}
```

### WR-04: font-switcher.sh and icon-theme-picker.sh leak temp scripts/cache dirs on abnormal exit (no trap)

**Files:** `hypr/.config/hypr/scripts/font-switcher.sh:45,85,86` ·
`hypr/.config/hypr/scripts/icon-theme-picker.sh:39,86,87`
**Issue:** Both pickers create `mktemp` artifacts (ENUM_SCRIPT,
PREVIEW_SCRIPT, CACHE_DIR) and rely on inline `rm -f`/`rm -rf` lines placed
after the fzf call. Any `set -e` abort between creation and those lines
(e.g. `FONTS=$("$ENUM_SCRIPT" ...)` failing, `mktemp -d` for CACHE_DIR
failing after PREVIEW_SCRIPT exists, SIGTERM/SIGHUP from the floating kitty
window being closed) skips cleanup and leaves executable scripts and cache
PNGs in /tmp. The sibling scripts in this same phase (`color-picker.sh`,
`gif-export.sh`) already use the correct `trap ... EXIT` idiom — these two
are inconsistent with it.
**Fix:** immediately after the mktemp calls:
```bash
trap 'rm -f "$ENUM_SCRIPT" "$PREVIEW_SCRIPT"; rm -rf "$CACHE_DIR"' EXIT
```
(initialize `PREVIEW_SCRIPT=""`/`CACHE_DIR=""` before first mktemp so the
trap is safe on early exits; drop the inline rm lines or keep them as no-ops.)

### WR-05: record-toggle.sh `pgrep/pkill -f "^gpu-screen-recorder"` prefix also matches sibling GSR binaries

**File:** `hypr/.config/hypr/scripts/record-toggle.sh:36,46,51,55-56`
**Issue:** `-f` matches the full command line, and the `^gpu-screen-recorder`
anchor is an unbounded prefix: it also matches `gpu-screen-recorder-ui`,
`gpu-screen-recorder-gtk`, and `gpu-screen-recorder-notification` (the
companion packages of the same upstream). If any of those is running:
(a) `recording_active()` returns true with no actual recording, so Alt+Print
inverts — it "stops" instead of starting; (b) `pkill -SIGINT`/`-9` kills the
user's GSR UI app outright. On the current machine only the CLI package is
installed, but nothing prevents installing the UI later.
**Fix:**
```bash
pgrep -f '^gpu-screen-recorder ' >/dev/null 2>&1   # trailing space bounds argv[0]
```
(the script always invokes it with arguments, so the trailing space is safe;
apply the same pattern to both pkill calls and both pgrep sites.)

### WR-06: commit.sh rsync --delete does not exclude engine-owned `walker-relaunch.log`

**File:** `theme-engine/.config/theme-engine/lib/commit.sh:70-73` (with
`theme-engine/.config/theme-engine/lib/reload.sh:187,290-291`)
**Issue:** `reload.sh` writes `$STATE_DIR/walker-relaunch.log` — a root-level
engine-owned state file that is never part of the rendered tree. It is the
same bug class this file itself documents five times over (logs/,
last-wallpaper/, current-theme, .last-render-error.log, icon-theme,
font-choice), yet it is missing from the exclusion list, so every commit
deletes it. Impact is bounded because the same theme-apply run recreates it
seconds later in `theme_engine_reload_walker` — but (a) the previous run's
diagnostics are destroyed on every switch even when the new run never reaches
the walker step (render/commit crash, headless-guard early return), and
(b) the failure notification points the user at a log that a subsequent
switch may have just wiped. The file's own documented invariant ("engine-owned
root-level files must survive --delete") is violated.
**Fix:** add `--exclude=walker-relaunch.log` to the rsync invocation at line 70.

## Info

### IN-01: emoji-picker.sh notification overstates behavior when wtype is missing

**File:** `hypr/.config/hypr/scripts/emoji-picker.sh:229-240`
**Issue:** The degrade path (no wtype → copy-only, `:` no-op) still shows
"Emoji Inserted — $EMOJI typed and copied to clipboard", contradicting the
file's own UI-SPEC Copywriting Contract ("never overpromise").
**Fix:** branch the message: "copied to clipboard (wtype not installed —
paste manually)" when `command -v wtype` fails.

### IN-02: style-floating.css unitless `border-radius: 10`

**File:** `waybar/.config/waybar/style-floating.css:8`
**Issue:** GTK3 emits "Not using units is deprecated. Assuming 'px'." —
verified non-fatal on GTK 3.24.52 (stylesheet retained), so cosmetic only,
but it is the one deprecation warning waybar logs on every style load.
**Fix:** `border-radius: 10px;`

### IN-03: contract.sh stale "10 files" comment

**File:** `theme-engine/.config/theme-engine/lib/contract.sh:20-21` (also
`theme-doctor:48-49` "ten per-file checks")
**Issue:** contract.json now lists 17 files; the "the 10 matugen-rendered
state-dir files" comments are stale and will mislead the next reader.
**Fix:** say "every contract-listed state-dir file" instead of a count.

### IN-04: windowrule embedded in keybinds.conf

**File:** `hypr/.config/hypr/config/keybinds.conf:169-170`
**Issue:** `windowrule = match:class kitty, scroll_touchpad 1.5` lives in the
keybinds file while every other rule is in windowrules.conf. It parses
(`hyprctl configerrors` is empty live), but it breaks the one-home-per-concern
organization and is easy to miss when auditing window rules. Its bare
`kitty` matcher also diverges from the anchored `^(kitty)$` convention used
everywhere else.
**Fix:** move to windowrules.conf as
`windowrule = scroll_touchpad 1.5, match:class ^(kitty)$`.

### IN-05: install.sh never runs `xdg-user-dirs-update`; comment overstates

**File:** `install.sh:160-162`
**Issue:** The comment claims xdg-user-dirs "creates ~/Pictures so
screenshot-dir resolution is deterministic", but installing the package only
ships a user systemd unit that runs at the first graphical login — install.sh
itself never creates the dirs, and nothing in the reviewed scripts calls
`xdg-user-dir` (capture scripts `mkdir -p` their own path anyway). No
functional gap, but the stated rationale doesn't match what the script does.
**Fix:** either run `xdg-user-dirs-update || true` in section_core_rice or
soften the comment to "dirs are created by its user unit at first login".

### IN-06: install.sh installs reflector via `-Sy` before the full `-Syu`

**File:** `install.sh:256-259`
**Issue:** `pacman -Sy --needed --noconfirm reflector` refreshes the db and
installs against it before the system upgrade — the classic partial-upgrade
window (reflector's python deps can be pulled at new versions against old
system libs). Low practical risk on the fresh-install target scenario, but
trivially avoidable.
**Fix:** run `sudo pacman -Syu --noconfirm` first, then
`sudo pacman -S --needed --noconfirm reflector`, then re-sort mirrors and
continue.

### IN-07: theme-doctor coverage lags commit.sh's new wiring

**File:** `theme-engine/.config/theme-engine/theme-doctor:76-83`
**Issue:** The doctor checks walker/yazi symlinks but not the three newer
wiring targets commit.sh owns since this phase: `~/.config/satty/config.toml`,
`~/.config/gtk-3.0/settings.ini`, `~/.config/gtk-4.0/settings.ini` (and
reload.sh's Zen `chrome/userChrome.css`). A broken satty symlink would pass
the doctor while the screenshot pipeline loses its annotate config.
**Fix:** add the same `[[ -L ... ]] && readlink -f == $STATE_DIR/...` checks
for satty and the two settings.ini links.

### IN-08: reload.sh swayosd restart has no SIGKILL fallback; elephant socket path hardcodes /run/user

**File:** `theme-engine/.config/theme-engine/lib/reload.sh:78-92,185`
**Issue:** (a) The swayosd-server restart polls 2s for exit but, unlike the
walker/thunar paths, never falls through to `-9` — a hung server yields two
concurrent swayosd-server processes after relaunch. (b) `elephant_sock`
hardcodes `/run/user/$(id -u)` while the rest of the codebase uses
`${XDG_RUNTIME_DIR:-/run/user/$(id -u)}`.
**Fix:** add the same `pkill -9 -x swayosd-server` fallback after the poll;
use the XDG_RUNTIME_DIR idiom for the socket path.

### IN-09: `zsh` listed under AUR_PKGS

**File:** `install.sh:212-213`
**Issue:** zsh is an official `extra` package but is bucketed in AUR_PKGS
(oh-my-posh beside it is genuinely AUR). paru resolves repo packages fine, so
this works, but it defeats the file's own repo-vs-AUR legitimacy-audit
organization.
**Fix:** move `zsh` into PACMAN_PKGS.

---

## Verification notes (non-findings)

Constructs checked and confirmed correct, to prevent future re-flagging:

- `hyprshot --raw` long form: installed 1.3.0 optstring `hf:o:m:dszr:t:`
  confirms `-r` demands an argument while `--raw` is boolean — 06-14's fix is
  right, and `-m output -m active` is valid repeated-mode usage.
- satty 0.21.1: `early-exit = ["all"]` and `[color-palette] palette=[...]`
  both match the shipped README schema; `#RRGGBBAA` palette entries are
  accepted (hex_color crate).
- GTK4 (swayosd 0.3.1 links libgtk-4): `-gtk-icon-transform: scale(1.2)`
  parses with zero `parsing-error` emissions on the installed GTK 4.22 —
  not a defect.
- hyprpicker fancy ANSI output is auto-disabled when stdout is not a TTY
  (upstream main.cpp `isatty` check), so the captured hex is clean on
  success.
- `cliphist -max-items 100 store` flag-before-subcommand ordering is correct
  for cliphist 0.7's Go flag parsing.
- `hyprctl configerrors` is empty on the live Hyprland 0.55.4 session — the
  `code:107` binds, windowrules (including `scroll_touchpad`), and layerrules
  all parse.
- `hyprshutdown`, `vlc-plugins-all`, `awww`, `xdg-user-dirs` all verified
  present in official repos via `pacman -Si`.
- hyprlock `$TIME12`, `$ATTEMPTS[]`, `##`-escaped span foreground, and the
  brace-free playerctl one-liner are consistent with the template's rendered
  variables (`$on_surface_variant_hex` etc. all defined in
  hyprlock-colors.conf).
- wlogout executes layout actions via `system()` after teardown, so the
  `cliphist wipe; uwsm stop` compound actions in `wlogout/.config/wlogout/layout`
  work as written.

---

_Reviewed: 2026-07-13T01:02:23Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
