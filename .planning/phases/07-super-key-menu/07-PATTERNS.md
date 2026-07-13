# Phase 7: Super-Key Menu - Pattern Map

**Mapped:** 2026-07-13
**Files analyzed:** 19 (new + modified, per CONTEXT.md/RESEARCH.md/UI-SPEC.md)
**Analogs found:** 16 / 19

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|--------------------|------|-----------|-----------------|----------------|
| `elephant/.config/elephant/menus/main.toml` (NEW stow pkg) | config (menu tree) | transform | none in-repo — RESEARCH.md's own live-verified README schema is authoritative | no analog |
| `elephant/.config/elephant/menus/{utilities,screenshot,settings,ai-dashboard,game-center}.toml` (NEW) | config (menu tree) | transform | same as `main.toml` | no analog |
| `walker/.config/walker/config.toml` (EDIT — add `[sets.menu]`) | config | transform | itself, `[sets.runner]` block | exact |
| `hypr/.config/hypr/config/keybinds.conf` (EDIT — tap bind, kill-bind, Super+Space, back-filled comments) | config (DSL) | transform | itself (existing bind blocks + comment convention) | exact |
| `hypr/.config/hypr/config/autostart.conf` (EDIT — gaming-mode reset-to-OFF hook) | config | event-driven | itself (existing `exec-once` fan-out lines) | exact |
| `hypr/.config/hypr/config/windowrules.conf` (EDIT — Zen AI web-app title-regex rules, floating picker rules) | config (DSL) | transform | itself (existing `windowrule { name = wallpaper-picker ... }` blocks) | exact |
| `hypr/.config/hypr/scripts/keybind-doctor` (NEW) | test (rerunnable gate) | batch | `theme-engine/.config/theme-engine/theme-doctor` | exact |
| `hypr/.config/hypr/scripts/nmtui-launch.sh` (NEW) | utility (CLI launcher shim) | request-response | `hypr/.config/hypr/scripts/icon-theme-switch.sh` | exact |
| `hypr/.config/hypr/scripts/cheat-sheet-parser.sh` (NEW) | utility (shared parser lib) | transform | `theme-engine/.config/theme-engine/theme-doctor` (`contract_files` sourcing/parsing idiom) | role-match |
| `hypr/.config/hypr/scripts/cheat-sheet-view-all.sh` (NEW) | utility (CLI, kitty table launcher) | request-response | `hypr/.config/hypr/scripts/wallpaper-picker.sh` (fzf-in-floating-kitty shim shape, minus fzf itself) | role-match |
| `hypr/.config/hypr/scripts/gaming-mode-toggle.sh` (NEW) | utility (CLI, state toggle) | event-driven | `hypr/.config/hypr/scripts/theme-switch.sh` (walker-dmenu-free notify/state pattern) + `theme-engine/.config/theme-engine/lib/gtk.sh` (best-effort `hyprctl`/gsettings idiom) | role-match |
| `hypr/.config/hypr/scripts/ai-workspace.sh` (NEW) | utility (CLI, idempotent launcher) | event-driven | `hypr/.config/hypr/scripts/wlogout.sh` (`hyprctl -j` query + guarded fallback idiom) | role-match |
| `hypr/.config/hypr/scripts/powermenu.sh` (DELETE) | — | — | n/a — deletion target, D-20 | n/a |
| `hypr/.config/hypr/scripts/wlogout.sh` (unchanged — Power entry's delegation target) | utility (CLI) | event-driven | itself (read-only reference for the menu's `actions.open`) | exact |
| `install.sh` (EDIT — ~10 PACMAN_PKGS/AUR_PKGS additions + multilib enablement) | config (install script) | batch | itself (existing `PACMAN_PKGS`/`AUR_PKGS` arrays + `section_core_rice`) | exact |
| `stow.sh` (EDIT — gaming-mode state-file seed) | config (install script) | batch | itself (existing `current-waybar-layout` seed-only-when-absent block) | exact |

## Pattern Assignments

### `elephant/.config/elephant/menus/*.toml` (config, transform)

**Analog:** none in-repo (first elephant `menus` provider content in this project) — the authoritative schema is RESEARCH.md's own live-verified extraction from `elephant-menus`' bundled README (`~/.cache/paru/clone/elephant-menus/v2.21.0.tar.gz` → `internal/providers/menus/README.md`), confirmed against the actual installed 2.21.0 binary via a throwaway `~/.config/elephant/menus/test.toml` → `elephant listproviders` → `menus:test` round-trip.

**Schema to use verbatim** (source: 07-RESEARCH.md Pattern 2):
```toml
# ~/.config/elephant/menus/main.toml
name = "main"
name_pretty = "Menu"

[[entries]]
text = " Utilities"          # glyph as plain text (D-07) — no `icon` field
submenu = "utilities"          # auto-gets the `open` action; Enter drills down

[[entries]]
text = " Power"
actions = { "open" = "~/.config/hypr/scripts/wlogout.sh" }  # D-19: leaf, not a submenu
```
```toml
# ~/.config/elephant/menus/utilities.toml
name = "utilities"
name_pretty = "Utilities"
parent = "main"                # enables menus:parent back-navigation
```

**Directory-creation caveat (Pitfall 3, RESEARCH.md):** `elephant`'s `ConfigDirs()` only appends `$XDG_CONFIG_HOME/elephant` to its scan list if the directory already exists via `os.Stat` — an absent directory silently yields zero menu files loaded, no error. The new `elephant/` stow package's tree must itself contain `.config/elephant/menus/` so `stow` creates the directory; do not assume `mkdir -p` elsewhere covers it.

**Restart requirement (Pitfall 3):** `LoadMenus()` runs exactly once, at elephant daemon startup — new/edited `.toml` files are invisible to the already-running daemon. The plan needs an explicit elephant-restart step, mirroring the health-check idiom already used by `theme-doctor` for walker/elephant (see below) rather than assuming `stow.sh` alone is sufficient. There is no existing `walker-restart.sh`/`elephant-relaunch.sh` script in this repo yet (CONTEXT's guidance names one, but `hypr/.config/hypr/scripts/` currently has no such file) — author fresh, following the same `pgrep -x <proc>`-guarded restart idiom used in `theme-engine/.config/theme-engine/lib/reload.sh`'s fan-out block (Phase 6 pattern, reused below).

**Exact leaf-action content for every Utilities/Settings/AI/Game entry** is dictated verbatim by `07-UI-SPEC.md`'s Menu Tree tables (glyph codepoints, action strings) — copy those tables directly into the TOML `text`/`actions` fields, do not re-derive wording.

---

### `walker/.config/walker/config.toml` (EDIT)

**Analog:** itself — the existing `[sets.runner]` block (lines 50-52), already proven live via `walker -s runner` (`$app_launcher_drun` in `keybinds.conf`):
```toml
[sets.runner]
providers = ["runner"]
placeholder = { input = "Run command...", list = "No matches" }
```
**New block to add** (source: RESEARCH.md Code Examples):
```toml
[sets.menu]
providers = ["menus:main"]
placeholder = { input = "Menu", list = "No entries" }
```
**Open Question 1 (RESEARCH.md) not yet resolved:** whether `providers = ["menus:main"]` alone survives a `ProviderUpdated` broadcast to `menus:utilities` after drill-down, or whether every submenu name needs listing (`["menus:main","menus:utilities","menus:screenshot", ...]`). The D-05 spike (two-file test menu) must answer this BEFORE the real six-submenu content is authored — treat the `providers` array's exact contents as unresolved until spiked, not as a copy-paste-and-move-on step.

`menus` is already present in `[providers] default` (line 20) and in `theme-doctor`'s provider-parity exception list (see below) — no change needed there.

---

### `hypr/.config/hypr/config/keybinds.conf` (EDIT — headline risk)

**Analog:** itself, full file (169 lines) read in full. Three surgical edits, all additive/replace-in-place, matching this file's own established conventions:

**1. Kill-bind (D-03) — test FIRST, in isolation, before touching SUPER_L:**
```conf
bind = $mainMod, Escape, exec, pkill walker
```
(copies the exact `bind = $mainMod, <key>, exec, <cmd>` shape used everywhere else in this file, e.g. line 40's `theme-switch.sh` bind, including its trailing `# comment` convention.)

**2. Tap-only Super bind (D-01/D-02) — the file's own existing line to REPLACE:**
```conf
# ── REMOVE (line 33) ──
bind = $mainMod, SUPER_L, exec, $app_launcher

# ── ADD ──
bind = $mainMod, SPACE, exec, $app_launcher              # D-01 relocated launcher
bindr = $mainMod, SUPER_L, exec, uwsm app -- walker -s menu   # D-02 tap-only menu
```
Do NOT write `bindr = , SUPER_L, ...` (empty modifier field) — RESEARCH.md Pitfall 1 documents this as a well-known non-working footgun (GH issue #6946); always the target-modmask form `bindr = $mainMod, SUPER_L, ...`.

**3. Back-filled `# comment` descriptions (D-30) — every bind that lacks one.** The file already has the convention half-applied — compare line 40 (`bind = $mainMod, T, exec, ... # Switch theme`) against line 91 (`bind = $mainMod, left, movefocus, l` — no comment). D-30 requires closing this gap on EVERY line, including movefocus/movewindow/resize/workspace/media-key blocks (lines 91-167) which currently have zero comments. Copy the exact trailing-comment style already used in the Utilities block (lines 79-82, e.g. `# Emoji picker`) — short, present-tense, no period.

**Section-header comment banners** (`# ── Section ──`, e.g. line 19, 32, 44, 50, 70, 84, 87, 90, etc.) are themselves load-bearing for the cheat-sheet's "View all" table grouping (D-29 — mirrors these banners as section headers) — do not remove or reflow them when editing.

---

### `hypr/.config/hypr/scripts/keybind-doctor` (NEW, test/rerunnable gate)

**Analog:** `theme-engine/.config/theme-engine/theme-doctor` (full file, 310 lines) — this is the explicit house pattern D-04 mandates copying.

**Structural skeleton to copy verbatim** (lines 1-30 of `theme-doctor`):
```bash
#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

PASS=0
FAIL=0

check() {
    local desc="$1"
    local ok="$2"
    if [[ "$ok" == "0" ]]; then
        echo "  [PASS] $desc"
        PASS=$((PASS + 1))
    else
        echo "  [FAIL] $desc"
        FAIL=$((FAIL + 1))
    fi
}

echo "keybind-doctor — Hyprland keybind regression gate"
echo ""
```
**Exit-code convention to copy verbatim** (`theme-doctor` lines 306-309):
```bash
echo ""
echo "Summary: ${PASS} passed, ${FAIL} failed"
[[ "$FAIL" -eq 0 ]]
exit $?
```
**Report-only discipline** (`theme-doctor`'s own header comment, line 5: "Report-only — never mutates state") — `keybind-doctor` must be equally read-only: parse `keybinds.conf`, query `hyprctl binds -j`, diff, never write/reload/`hyprctl keyword`.

**Core diff logic** (RESEARCH.md's own worked skeleton, `07-RESEARCH.md` Code Examples section):
```bash
DECLARED=$(grep -oP '^\s*bind[a-z]*\s*=\s*\K.*' hypr/.config/hypr/config/keybinds.conf)
LIVE=$(hyprctl binds -j)
# cross-reference: every declared (modmask,key,release) tuple must appear in LIVE;
# flag any two DIFFERENT dispatcher targets sharing the same tuple as shadowing
```
**Guarded-skip pattern to copy** (`theme-doctor` lines 95-100, `command -v stow` guard) — apply the same shape for a missing `hyprctl`/`jq`:
```bash
if command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    ...
else
    echo "  [SKIP] keybind cross-check (hyprctl or jq not found)"
fi
```

---

### `hypr/.config/hypr/scripts/nmtui-launch.sh` (NEW, utility CLI, request-response)

**Analog:** `hypr/.config/hypr/scripts/icon-theme-switch.sh` (full file, 12 lines) — the exact launcher-shim pattern D-17/07-UI-SPEC's Copywriting Contract explicitly names as the convention to follow:
```bash
#!/usr/bin/env bash
uwsm app -- kitty \
    --class "icon-theme-picker" \
    --title "Icon Theme Picker" \
    -o background_opacity=0.85 \
    -o font_size=11 \
    -- ~/.config/hypr/scripts/icon-theme-picker.sh
```
**Adapt to:**
```bash
#!/usr/bin/env bash
uwsm app -- kitty \
    --class "network-manager" \
    --title "Network" \
    -o background_opacity=0.85 \
    -o font_size=11 \
    -- nmtui
```
(07-UI-SPEC.md Copywriting Contract locks the exact `--title "Network"` / `--class "network-manager"` values.) A matching `windowrule { name = network-manager; match:class = ^(network-manager)$; float = on; size = 75% 70%; center = on; animation = popin }` block should be added to `windowrules.conf` alongside the existing `wallpaper-picker`/`icon-theme-picker`/`font-switcher` blocks (see windowrules.conf pattern below).

---

### `hypr/.config/hypr/scripts/gaming-mode-toggle.sh` (NEW, utility CLI, event-driven)

**Analog (state-file + notification half):** `hypr/.config/hypr/scripts/theme-switch.sh`'s cancel/state-read conventions, plus `theme-engine/.config/theme-engine/lib/commit.sh`'s atomic temp-file+mv idiom (Phase 5 pattern, still the house convention for any state-dir marker):
```bash
printf '%s\n' "$name" > "$STATE_DIR/current-theme.tmp" \
    && mv "$STATE_DIR/current-theme.tmp" "$STATE_DIR/current-theme"
```
**Analog (runtime `hyprctl keyword` half):** no existing script in this repo calls `hyprctl keyword` directly — `theme-engine/.config/theme-engine/lib/gtk.sh`'s best-effort `2>/dev/null || true` idiom is the closest style match to copy for every keyword call:
```bash
hyprctl keyword decoration:blur:enabled 0 2>/dev/null || true
hyprctl keyword animations:enabled 0 2>/dev/null || true
hyprctl keyword decoration:shadow:enabled 0 2>/dev/null || true
hyprctl keyword decoration:rounding 0 2>/dev/null || true
```
(Confirmed live-settable per RESEARCH.md Don't-Hand-Roll table: "confirmed live-settable via `hyprctl getoption`".) Reversal (`gaming mode: OFF`) must restore via the SAME keyword path using the values already rendered into `~/.local/state/theme/hyprland.conf` (read them back, do not hardcode restore literals — avoids drifting from whatever theme is active, consistent with the project's "runtime-only, never config rewrite" D-26 constraint).

**Notification pattern** — copy `notify-send -a "<Label>" "<Title>" "<Body>" -i <icon> -t <ms>` verbatim per 07-UI-SPEC.md Copywriting Contract's exact locked strings (`Gaming Mode: ON` / `Gaming Mode: OFF`).

**Waybar-hide abstraction (D-26)** — RESEARCH.md's Security/State-of-the-Art section confirms `on-sigusr1` default action is `toggle` (Arch man page `waybar.5`); the thin, re-pointable call is `pkill -SIGUSR1 waybar 2>/dev/null || true` — copy the exact `pkill -SIGUSR<n> <proc> 2>/dev/null || true` shape already used in `theme-engine/.config/theme-engine/lib/reload.sh` (`pkill -SIGUSR2 waybar`, Phase 6 pattern) but with SIGUSR1, as a single-call function Phase 8 can later re-point.

---

### `hypr/.config/hypr/scripts/ai-workspace.sh` (NEW, utility CLI, event-driven)

**Analog:** `hypr/.config/hypr/scripts/wlogout.sh`'s `hyprctl -j` query + jq extraction + guarded-fallback idiom (lines 40-49):
```bash
if command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    read -r MON_W MON_H < <(
        hyprctl -j monitors 2>/dev/null |
        jq -r 'first(.[] | select(.focused)) | "\(...) \(...)"' 2>/dev/null
    ) || true
fi
[[ "$MON_W" =~ ^[0-9]+$ ]] || MON_W=1920
```
**Adapt to:** query `hyprctl -j clients` for windows already on the named AI workspace before launching anything (idempotency, D-24) — same `hyprctl -j ... | jq -r ...` + fallback-guard shape. No existing named-workspace idiom exists in this repo (workspaces are numeric 1-10, `keybinds.conf` lines 109-130) — the AI workspace number/name is new territory; author fresh but keep the same guarded-query discipline.

---

### `hypr/.config/hypr/scripts/cheat-sheet-parser.sh` / `cheat-sheet-view-all.sh` (NEW)

**Analog (parser structure):** `theme-engine/.config/theme-engine/theme-doctor`'s `contract_files()` sourcing pattern (`source "$SCRIPT_DIR/lib/contract.sh"` then calling a shared function) — the shared-parser-sourced-by-two-callers shape D-29 requires:
```bash
# shellcheck source=lib/contract.sh
source "$SCRIPT_DIR/lib/contract.sh"
CONTRACT_FILE_LIST="$(contract_files)"
```
Adapt: `cheat-sheet-parser.sh` should expose a function (e.g. `cheat_sheet_parse_binds`) that both the walker menu entry (feeding `menus:keybinds` or a dmenu list) and `cheat-sheet-view-all.sh` (kitty table) source and call — never two independent `grep`/`awk` implementations (Single-owner-per-concern discipline, established Phase 5/6 pattern).

**Analog (parsing regex):** `keybind-doctor`'s own `grep -oP '^\s*bind[a-z]*\s*=\s*\K.*'` line-extraction idiom (RESEARCH.md Code Examples) — extend to also capture the trailing `# comment` via a second capture group, e.g. `grep -oP '^\s*bind[a-z]*\s*=\s*([^#]*)#?\s*(.*)$'`.

**Security constraint (V5, RESEARCH.md Security Domain):** the parser must treat every parsed field as display-only text (`printf`/`echo`, never `eval`/`source` on parsed content) — same discipline `theme-doctor` already follows (it only ever reads and reports, never executes parsed config).

**Analog (kitty table launcher shell):** `hypr/.config/hypr/scripts/icon-theme-switch.sh`'s launcher-shim shape (same `uwsm app -- kitty --class ... --title ... -- <script>` form), minus fzf — `cheat-sheet-view-all.sh` prints a formatted table and waits, it doesn't need fzf's interactive picking.

---

### `hypr/.config/hypr/config/windowrules.conf` (EDIT)

**Analog:** itself — the existing `windowrule { name = wallpaper-picker; match:class = ^(wallpaper-picker)$; float = on; size = 75% 70%; center = on; animation = popin }` block shape (lines 49-65, three near-identical blocks already exist for `wallpaper-picker`/`icon-theme-picker`/`font-switcher`).

**Copy this exact block shape** for the new `network-manager` kitty class (nmtui-launch.sh) and the `cheat-sheet-view-all` kitty class:
```conf
windowrule {
    name = network-manager
    match:class = ^(network-manager)$
    float = on
    size = 75% 70%
    center = on
    animation = popin
}
```

**Zen AI web-app windowrules (D-21) — title-regex, NOT class (Pitfall 4):** confirmed live via `hyprctl clients -j` (RESEARCH.md) that every Zen window reports `class: "zen"` regardless of URL — the existing `windowrule = opacity 0.90 0.88, match:class ^(zen)$` (line 96) already matches ALL Zen windows, which is correct for opacity but proves class-based placement rules cannot discriminate AI web-app windows from the regular browser. Use `match:title` instead (title reflects the loaded page):
```conf
windowrule = float on, match:class ^(zen)$, match:title .*Claude.*
windowrule = float on, match:class ^(zen)$, match:title .*ChatGPT.*
```
Test `MOZ_APP_REMOTINGNAME=<name> zen-browser --new-window <url>` against a live `hyprctl clients -j` check at execution time (Assumption A1, MEDIUM confidence) before committing further to a class-override design — title-regex is the guaranteed-working fallback if it doesn't pan out.

---

### `install.sh` (EDIT — packages + multilib)

**Analog:** itself — the existing `PACMAN_PKGS`/`AUR_PKGS` array shape (lines 52-237) and `section_core_rice()` (line 244 onward), read in full.

**Package placement pattern** — append inside the existing arrays, grouped with a `# comment` header matching the file's own convention (e.g. line 139's `# Screenshots, screen recording, OSD, utilities (D-03/D-16/D-18/D-23 ...)` banner style):
```bash
# ── Game center (D-25/D-33) ──
steam       # requires multilib — see multilib enablement below
lutris
ollama
aichat
gamemode
mangohud
nwg-displays
blueman
```
(`pavucontrol` is ALREADY in `PACMAN_PKGS`, line 97 — do not re-add.) AUR additions go in `AUR_PKGS` next to the existing icon-theme block (lines 231-236) with the same `checkpoint:human-verify` comment convention:
```bash
# Game center (AUR — D-33 human-verify checkpoint required)
heroic-games-launcher-bin
protonup-qt
```

**Multilib enablement (Pitfall 2, no existing analog — new territory):** `install.sh` currently has zero references to `multilib`/`pacman.conf` (confirmed via `grep -n "multilib\|pacman.conf" install.sh` → no matches, RESEARCH.md). Must land inside `section_core_rice()`, BEFORE the `steam` pacman install line and before `sudo pacman -Sy --needed --noconfirm reflector` runs a second sync — idempotent uncomment/append of `/etc/pacman.conf`'s `[multilib]` block followed by `sudo pacman -Sy`. Author fresh; the closest structural precedent for "idempotent pacman.conf-adjacent state check" in this file is the `[[ -f ... ]] ||`-guarded seed pattern used elsewhere in `stow.sh` (see below) — same "check-before-write" discipline, not a literal code copy since no pacman.conf-editing code exists yet anywhere in the repo.

---

### `stow.sh` (EDIT — gaming-mode state-file seed)

**Analog:** itself — the existing seed-only-when-absent pattern (line 90):
```bash
[[ -f "$HOME/.cache/current-waybar-layout" ]] || echo "full" > "$HOME/.cache/current-waybar-layout"
```
**Copy this exact idiom** for the gaming-mode state file (D-27/D-28), landing it beside this line since both are `~/.cache`-class ephemeral UI-state files (not theme-engine state, which lives in `~/.local/state/theme/` and is seeded separately via `theme-apply catppuccin`, lines 105-122):
```bash
[[ -f "$HOME/.cache/gaming-mode" ]] || echo "off" > "$HOME/.cache/gaming-mode"
```
D-28's session-reset-to-OFF requirement is a SEPARATE mechanism (an `autostart.conf` `exec-once` hook, not this stow-time seed) — this stow.sh line only ensures the file exists on a fresh install so `gaming-mode-toggle.sh` never has to handle a missing-file case on first read.

---

### `hypr/.config/hypr/config/autostart.conf` (EDIT — gaming-mode reset hook)

**Analog:** itself — the existing `exec-once` line shape and ordering discipline (full file read, 47 lines). Copy the exact one-liner style used for e.g. the clipboard watchers (lines 41-43):
```conf
# ── Gaming mode (D-28) — always reset to OFF on session start ──
exec-once = echo off > ~/.cache/gaming-mode
```
Place it near the top of the file (before `theme-init.sh`, similar to how the dbus/systemd env-export lines run first) since it's a cheap, order-independent state reset with no dependency on other daemons being ready — unlike `theme-init.sh` (line 47) which deliberately sleeps 2s for daemon readiness.

---

## Shared Patterns

### Rerunnable report-only gate (theme-doctor house pattern)
**Source:** `theme-engine/.config/theme-engine/theme-doctor` (full file)
**Apply to:** `keybind-doctor` (D-04) — same `check()` helper, same `[[ $FAIL -eq 0 ]]; exit $?` closing convention, same "never mutates state" discipline.

### `uwsm app --` for every GUI launch
**Source:** `hypr/.config/hypr/config/keybinds.conf` header comment (lines 1-6) and every `bind = ..., exec, uwsm app -- ...` line in the file
**Apply to:** every menu TOML `actions` entry that launches a GUI app (Steam, Lutris, Heroic, ProtonUp-Qt, blueman, pavucontrol, nwg-displays, Zen web-app windows, Claude Code kitty, ollama-TUI kitty) — shell scripts (Phase 6 utility scripts, `theme-switch.sh`, `wlogout.sh`) are invoked bare, matching this file's existing two-class convention exactly (D-09).

### Best-effort `2>/dev/null || true` for non-critical calls
**Source:** `theme-engine/.config/theme-engine/lib/gtk.sh` (every gsettings/notify-send call) and `hypr/.config/hypr/scripts/wlogout.sh` (`hyprctl -j monitors ... || true`)
**Apply to:** every `hyprctl keyword` call in `gaming-mode-toggle.sh`, every `pkill -SIGUSR*` fan-out call, every `notify-send` invocation across all new scripts.

### Launcher-shim (floating kitty class/title convention)
**Source:** `hypr/.config/hypr/scripts/icon-theme-switch.sh` (full 12-line file) + matching `windowrules.conf` block for the same class name
**Apply to:** `nmtui-launch.sh`, `cheat-sheet-view-all.sh` — always pair a new kitty `--class`/`--title` launcher shim with a matching `windowrule { name = ...; match:class = ^(...)$; float = on; size = 75% 70%; center = on; animation = popin }` block, never one without the other.

### Atomic temp-file + mv for state markers
**Source:** `theme-engine/.config/theme-engine/lib/commit.sh` (`current-theme.tmp` → `mv`)
**Apply to:** the gaming-mode state file, if `gaming-mode-toggle.sh` writes it from a running session context where a reader race is plausible (menu entry reads state while toggle script writes it) — same temp+rename discipline as any other reader-visible state-dir file.

### Seed-only-when-absent for `~/.cache` UI state
**Source:** `stow.sh` line 90 (`[[ -f ... ]] || echo "full" > ...`)
**Apply to:** the new `~/.cache/gaming-mode` seed line — never unconditionally overwrite, since `stow.sh` is re-runnable and must not clobber a user's mid-session toggle state on a re-stow.

### Section-header comment banners as structured data
**Source:** `hypr/.config/hypr/config/keybinds.conf`'s `# ── Section ──` banners (used throughout, e.g. lines 19, 32, 44, 50, 70, 84, 87, 90...)
**Apply to:** `cheat-sheet-parser.sh` must treat these banners as the section-grouping signal for the "View all" kitty table (D-29) — parse them alongside the bind lines, don't hand-roll a separate section list.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `elephant/.config/elephant/menus/*.toml` (all 6 files) | config (menu tree) | transform | First-ever elephant `menus` provider content in this repo — no in-repo TOML menu precedent exists. Use RESEARCH.md's live-verified schema (Pattern 2) plus 07-UI-SPEC.md's exact per-entry wording/glyph/action tables as the sole source of truth. |
| `hypr/.config/hypr/scripts/ai-workspace.sh` (idempotent-launch-if-not-running logic) | utility (CLI) | event-driven | No existing named-workspace / idempotent-relaunch script in this repo (all existing workspace binds are plain numeric `workspace, N` dispatches, keybinds.conf lines 109-130) — the `hyprctl -j clients` query-before-launch idiom is borrowed from `wlogout.sh`'s monitor-query shape, but the idempotency logic itself is new engineering, not a pattern copy. |
| Multilib enablement in `install.sh` | config (install script) | batch | Zero existing `pacman.conf`-editing code anywhere in this repo (confirmed via grep, RESEARCH.md Pitfall 2) — must be authored fresh, following only the general "idempotent check-before-write" discipline evident elsewhere in `stow.sh`/`install.sh`, not a literal analog. |

## Metadata

**Analog search scope:** `hypr/.config/hypr/scripts/`, `hypr/.config/hypr/config/`, `walker/.config/walker/`, `theme-engine/.config/theme-engine/` (theme-doctor + lib/), `install.sh`, `stow.sh`
**Files scanned:** 07-CONTEXT.md, 07-RESEARCH.md (full), 07-UI-SPEC.md (full), keybinds.conf (full), autostart.conf (full), windowrules.conf (full), walker/config.toml (full), theme-doctor (full, 310 lines), wlogout.sh (full), powermenu.sh (full, confirmed zero references), icon-theme-switch.sh (full), install.sh lines 40-260 (PACMAN_PKGS/AUR_PKGS/section_core_rice), stow.sh lines 80-124 (seed patterns), plus 05-PATTERNS.md and 06-PATTERNS.md for house-style reference (atomic-write, best-effort-error, launcher-shim, rerunnable-gate conventions carried forward)
**Pattern extraction date:** 2026-07-13
