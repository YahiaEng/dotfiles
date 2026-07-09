# Phase 4: Reliability Fixes & Tech Debt - Pattern Map

**Mapped:** 2026-07-09
**Files analyzed:** 8 (existing, all modified-in-place — no new source files except a conditional `fish/` stow package)
**Analogs found:** 8 / 8 (this phase edits existing config files directly; each file's "analog" is its own established convention elsewhere in the same file or a structurally identical sibling file)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|--------------------|------|-----------|-----------------|---------------|
| `wlogout/.config/wlogout/layout` | config (declarative action list) | event-driven (menu action → shell exec) | `hypr/.config/hypr/scripts/powermenu.sh` (same uwsm-vs-bare inconsistency, same action set) | exact (same domain, twin defect) |
| `hypr/.config/hypr/scripts/wlogout.sh` | script (toggle launcher) | event-driven | `hypr/.config/hypr/scripts/waybar-switch.sh` (toggle-style script pattern) | role-match |
| `hypr/.config/hypr/hyprlock.conf` | config | request-response (auth) | itself — internal convention (`general {}` block, sourced theme vars) | exact (self-consistent, single file) |
| `hypr/.config/hypr/hypridle.conf` | config | event-driven (idle listeners) | itself; `hyprlock.conf`'s `lock_cmd`/`before_sleep_cmd` cross-reference | role-match |
| `hypr/.config/hypr/config/keybinds.conf` | config (bind table) | event-driven | itself — existing `bind = $mainMod ..., exec, ~/.config/hypr/scripts/*.sh` convention | exact (only touched if the script path changes, e.g. wleave) |
| `kitty/.config/kitty/kitty.conf` | config | request-response (terminal init) | itself; only touched if `shell` directive added (D-12) | exact |
| `zshell/.zshrc` | config/script (shell init) | batch (sequential startup steps) | itself — existing lazy/eager pattern split already present (fastfetch eager, fzf/zoxide eager, nvm/bun eager — target of the lazy-load refactor) | exact (internal refactor, no external analog needed) |
| `install.sh` (`PACMAN_PKGS` array) | config | batch | itself — existing array + `verify_packages` pattern | exact |
| `fish/.config/fish/config.fish` (NEW, conditional on D-09) | config | batch | `zshell/.zshrc` (shell init script being ported) | role-match (cross-shell port) |

## Pattern Assignments

### `wlogout/.config/wlogout/layout` (config, event-driven)

**Analog:** `hypr/.config/hypr/scripts/powermenu.sh` (lines 14-20) — the walker-based power menu already exhibits the identical uwsm-correct vs. bare-`systemctl` split that needs fixing in wlogout's layout:

```bash
case "$SELECTED" in
    *"Lock"*)     uwsm app -- hyprlock       ;;
    *"Logout"*)   uwsm stop                  ;;
    *"Reboot"*)   systemctl reboot           ;;
    *"Shutdown"*) systemctl poweroff         ;;
    *"Suspend"*)  systemctl suspend          ;;
esac
```

**Current wlogout layout** (`wlogout/.config/wlogout/layout`, full file, 36 lines) — same 6-action, same bare/wrapped inconsistency:
```jsonc
{ "label": "lock",      "action": "uwsm app -- hyprlock" }   // already uwsm-correct
{ "label": "logout",    "action": "uwsm stop" }               // already uwsm-correct
{ "label": "suspend",   "action": "systemctl suspend" }        // bare — audit target (D-14)
{ "label": "hibernate", "action": "systemctl hibernate" }      // bare — audit target (D-14)
{ "label": "shutdown",  "action": "systemctl poweroff" }       // bare — FIX-01 root-cause target
{ "label": "reboot",    "action": "systemctl reboot" }         // bare — FIX-01 root-cause target
```

**Pattern to apply:** Per RESEARCH.md Pattern 1 (uwsm-correct session action, citing `hyprwm/Hyprland#12174`), rewrite all four bare `systemctl` actions to route through uwsm's session-teardown-safe form — e.g. `uwsm stop && systemctl poweroff` (or whatever exact command diagnosis confirms), keeping the JSON structure and `keybind` fields byte-identical to today. If diagnosis instead selects `hyprshutdown --vt N --post-cmd 'systemctl poweroff'` for shutdown/reboot specifically, that string replaces only those two `action` values — do not change `label`/`text`/`keybind` keys, which are load-bearing for wlogout's icon/CSS class matching in `wlogout/.config/wlogout/style.css` (not read this pass, but referenced by `label` value — do not rename labels).

**If D-15's replacement branch fires (wleave):** wleave consumes the same `layout` JSON format directly (per RESEARCH.md), so this same file, same fix, is simply picked up by the new binary — `powermenu.sh`'s inline `case` pattern is the fallback reference if wleave needs a different action-invocation convention than wlogout.

---

### `hypr/.config/hypr/scripts/wlogout.sh` (script, event-driven toggle)

**Analog:** `hypr/.config/hypr/scripts/waybar-switch.sh` for the toggle-launcher convention (pgrep/pkill guard around a background launch) — same shape already used in this file itself:

**Current file** (full, 8 lines):
```bash
#!/usr/bin/env bash
# Toggle wlogout — kill if running, launch if not

if pgrep -x "wlogout" > /dev/null; then
    pkill -x "wlogout"
else
    wlogout --protocol layer-shell -b 6 -T 400 -B 400 &
fi
```

**Pattern to apply:** If D-15's wleave replacement fires, this script's binary name (`wlogout` → `wleave`) and any wleave-specific CLI flags change, but the pgrep/pkill toggle skeleton stays identical — this is the correct minimal-diff shape to preserve. No uwsm-wrapping needed here (it only toggles a UI, doesn't itself execute a session-teardown action — that's inside the `layout` file above).

---

### `hypr/.config/hypr/hyprlock.conf` (config, request-response)

**Analog:** self — the `general {}` block (lines 7-12) is the mitigation target, matching RESEARCH.md Pattern 2 exactly:

```
general {
    grace = 5
    hide_cursor = true
    no_fade_in = false
    no_fade_out = false
}
```

**Pattern to apply (only after log-signature confirmation per D-19/Pitfall 2):**
```
general {
    grace = 0          # was: grace = 5 — eliminates the grace-period
                        # double-unlock race (hyprwm/hyprlock#423)
    hide_cursor = true
    no_fade_in = false
    no_fade_out = false
}
```
Diagnostic command (RESEARCH.md Code Examples): `uwsm app -- hyprlock -v`, grep for `"In grace and cursor moved more than 5px, unlocking!"` followed by `"Unlock already happend?"`. Do not touch `input-field { fade_on_empty ... }` (lines 68-97) unless diagnosis specifically implicates fade timing — D-19 scopes the fix to the `grace` knob first.

---

### `hypr/.config/hypr/hypridle.conf` (config, event-driven)

**Analog:** self — `general { lock_cmd = pidof hyprlock || hyprlock; before_sleep_cmd = loginctl lock-session }` (lines 5-9) is the idle-triggered lock path, structurally separate from the manual-lock path (`keybinds.conf` → `wlogout.sh`/layout `"lock"` action). Per D-17's symptom fingerprint (manual lock only), this file is audited for completeness (D-14's "all six actions" + idle path) but is NOT expected to need a code change — the `600s` listener (lines 19-22) already calls `loginctl lock-session` consistently with `hyprlock.conf`'s grace fix, no divergent pattern to reconcile.

---

### `hypr/.config/hypr/config/keybinds.conf` (config, event-driven)

**Analog:** self — existing bind convention (line 25):
```
bind = $mainMod SHIFT, Q, exec, ~/.config/hypr/scripts/wlogout.sh
```

**Pattern to apply:** Only touched if D-15's wleave replacement changes the invoked script's filename (e.g. `wleave.sh`) — keep the exact `bind = $mainMod SHIFT, Q, exec, ~/.config/hypr/scripts/<script>.sh` shape, same modifier/key, matching every other `bind = $mainMod, X, exec, ~/.config/hypr/scripts/*.sh` line already in this file (lines 40-49: `theme-switch.sh`, `waybar-switch.sh`, `wallpaper-switch.sh`, `screenshot.sh` — all same `exec, ~/.config/hypr/scripts/NAME.sh` convention).

---

### `kitty/.config/kitty/kitty.conf` (config, request-response)

**Analog:** self — file is small (63 lines), sectioned with `# ── SECTION ─` banner comments (matches every other stow package's config style, e.g. `hyprlock.conf`, `hypridle.conf`).

**Pattern to apply (only if D-12's fish switch lands and profiling doesn't point here otherwise):** Add a `shell` directive in the existing banner-comment style, near the top (after `# ── Font ─` or as a new `# ── Shell ─` section):
```
# ── Shell ────────────────────────────────────────────
shell fish
```
Per D-12, do NOT touch `chsh`/system login shell — this is a kitty-only override. Per RESEARCH.md Pitfall 3, do not touch `repaint_delay`/`input_delay`/`sync_to_monitor` (lines 42-44) — those are rendering-latency knobs, not shell-startup knobs, and are out of scope for FIX-03 unless profiling specifically implicates them (unlikely per research).

---

### `zshell/.zshrc` (config/script, batch)

**Analog:** self — the file already has an explicit eager/lazy split precedent worth preserving as the model: the `if [ -t 0 ]; then fastfetch; fi` guard (lines 5-7) is an existing conditional-execution pattern; the new lazy shims for nvm/bun should follow the same "guard function around the real cost" shape.

**Current cost centers (verbatim, exact line refs):**

Fastfetch (lines 4-7) — stays, but trim modules per D-02/profiling in `fastfetch/.config/fastfetch/config.jsonc` (not shown here — separate stow package file):
```zsh
if [ -t 0 ]; then
    fastfetch
fi
```

oh-my-posh remote fetch (line 46):
```zsh
eval "$(oh-my-posh init zsh --config 'https://github.com/JanDeDobbeleer/oh-my-posh/blob/main/themes/catppuccin.omp.json')"
```
**Pattern to apply (D-03):** vendor the JSON into `zshell/.config/...` (new file inside the zshell stow package, e.g. `zshell/.config/oh-my-posh/catppuccin.omp.json`) and change to a local path:
```zsh
eval "$(oh-my-posh init zsh --config "$HOME/.config/oh-my-posh/catppuccin.omp.json")"
```

zinit plugin loading (lines 24-37) — synchronous `zinit light`/`zinit snippet` calls:
```zsh
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab
zinit snippet OMZL::git.zsh
zinit snippet OMZP::git
...
```
**Pattern to apply (D-05, if zprof implicates zinit):** wrap in `zinit wait lucid for \` turbo blocks per RESEARCH.md Pattern 4 — exact code example already provided there, copy directly.

nvm/bun sync sourcing (lines 102-111):
```zsh
export NVM_DIR="$HOME/.config/nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
[ -s "/home/aorus/.bun/_bun" ] && source "/home/aorus/.bun/_bun"
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
```
**Pattern to apply (D-04):** RESEARCH.md Pattern 5's lazy shim, copy directly:
```zsh
export NVM_DIR="$HOME/.config/nvm"
lazy_load_nvm() {
    unset -f nvm node npm npx bun 2>/dev/null
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
}
for cmd in nvm node npm npx bun; do
    eval "function $cmd() { lazy_load_nvm; $cmd \"\$@\" }"
done
```

**Untouched lines (do not modify unless profiling says otherwise):** fzf/zoxide evals (lines 93-94), history/completion styling (lines 56-75), aliases/functions (lines 78-90), PATH exports (lines 96-98, 113), the trailing `source $HOME/.local/share/../bin/env` (line 115) — none are named cost centers in CONTEXT.md/RESEARCH.md.

---

### `install.sh` `PACMAN_PKGS` array (config, batch)

**Analog:** self — the array (lines 52-147) is a flat, commented, grouped list (`# Hyprland ecosystem`, `# Utilities`, `# Audio`, etc.); `verify_packages()` (lines 358-384) already hard-fails on any listed-but-missing package, so any addition here is automatically covered by the existing gate — no new verification code needed.

**Pattern to apply (DEBT-01):** add `rsync` under the `# Utilities` group (lines 73-86, alongside `grep`-adjacent tools like `jq`, `psmisc`, `stow`), matching the one-package-per-line, no-trailing-comma style already used throughout:
```bash
    # Utilities
    grim
    slurp
    wl-clipboard
    cliphist
    brightnessctl
    playerctl
    fastfetch
    fzf
    chafa
    imagemagick
    jq
    psmisc
    stow
    rsync
```

**If D-09's fish branch is taken**, add `fish` to the same array (official `extra` repo per RESEARCH.md, confirmed via `pacman -Si` — goes in `PACMAN_PKGS`, NOT `AUR_PKGS`), e.g. under a new `# Shell` group or alongside `zsh`'s `AUR_PKGS` entry's sibling section. Note `zsh`/`oh-my-posh` currently live in `AUR_PKGS` (lines 181-183) — `fish` does NOT belong there, it's official-repo.

**Do not touch:** `NVIDIA_PKGS`, `AUR_PKGS`'s `wlogout` entry (unless D-15's wleave replacement fires — then `wlogout` → `wleave` swap in `AUR_PKGS`, gated behind `checkpoint:human-verify` per RESEARCH.md's Package Legitimacy Audit, since `wleave` is AUR/unofficial-tier trust), `verify_packages()` function body, or the `section_core_rice`/`section_hardware` control flow.

---

### `fish/.config/fish/config.fish` (NEW file, conditional on D-09)

**Analog:** `zshell/.zshrc` — this is a cross-shell port, not a fresh design. Every parity item in D-10's checklist maps 1:1 to an existing `.zshrc` line:

| D-10 parity item | `.zshrc` source (line) | fish equivalent pattern |
|---|---|---|
| oh-my-posh prompt (local vendored config) | line 46 (post D-03 fix) | `oh-my-posh init fish --config ~/.config/oh-my-posh/catppuccin.omp.json \| source` |
| fzf | line 93 | `fzf --fish \| source` (fish-native flag, not `--zsh`) |
| zoxide | line 94 | `zoxide init --cmd cd fish \| source` |
| trimmed fastfetch greeting | lines 4-7 | fish's `status is-interactive` guard replaces `[ -t 0 ]` |
| node tooling | lines 102-111 (post D-04 fix) | `nvm.fish` (fisher plugin, per RESEARCH.md A1 — re-verify at execution time) |

**New stow package structure** (per RESEARCH.md's Recommended Project Structure and this repo's existing one-package-per-app convention, e.g. `zshell/.zshrc` sitting directly at package root mapping to `~/.zshrc`):
```
fish/.config/fish/config.fish       # analog: zshell/.zshrc
fish/.config/fish/functions/        # only if fish-native functions needed (y() port, etc.)
```
Add `fish` to `stow.sh`'s `PACKAGES` array (alongside existing `fastfetch, gtk, hypr, kitty, ...` list) — same pattern as any existing package entry there.

---

## Shared Patterns

### uwsm-correct session actions
**Source:** `hypr/.config/hypr/scripts/powermenu.sh` lines 15-16 (`uwsm app -- hyprlock`, `uwsm stop`) — the only two already-correct examples in the codebase.
**Apply to:** `wlogout/.config/wlogout/layout` (4 of 6 actions), and `powermenu.sh` itself should get the same fix applied to its own `Reboot`/`Shutdown`/`Suspend` case branches (lines 17-19) since it has the identical bare-`systemctl` defect — RESEARCH.md's "fix the class of bug" mandate (D-13) implies this walker-based menu is an in-scope secondary defect surface even though CONTEXT.md's canonical_refs list doesn't name it explicitly. Flag this to the planner as a possible scope question.

### Sectioned banner-comment config style
**Source:** every `hypr/.config/hypr/*.conf` and `kitty/.config/kitty/kitty.conf` file — `# ╔══...╗` header + `# ── Section ─` subsection banners.
**Apply to:** any new content added to `hyprlock.conf`, `kitty.conf` — match this exact banner style, don't introduce a different comment convention.

### Guard-before-cost shell pattern
**Source:** `zshell/.zshrc` line 5 (`if [ -t 0 ]; then fastfetch; fi`).
**Apply to:** all new lazy-load shims in `.zshrc` (nvm/bun) and the fish port — wrap expensive calls in a cheap guard, consistent with the one guard pattern already in this file.

### Flat grouped array + hard-fail verify
**Source:** `install.sh` `PACMAN_PKGS`/`AUR_PKGS` arrays + `verify_packages()` (lines 358-384).
**Apply to:** `rsync` addition (DEBT-01) and `fish` addition (if D-09 fires) — no new verification code needed, just add to the correct array; the existing gate covers it automatically (D-24).

## No Analog Found

None — every file in scope is an existing file being edited in place, or (for the conditional `fish/` package) has a direct structural analog in `zshell/.zshrc`. No greenfield pattern gaps.

## Metadata

**Analog search scope:** `wlogout/`, `hypr/.config/hypr/` (scripts + top-level confs + config/keybinds.conf), `kitty/.config/kitty/`, `zshell/`, `install.sh`, `stow.sh`
**Files scanned:** 8 target files + `powermenu.sh`, `waybar-switch.sh`, `stow.sh` (cross-reference), `fastfetch/.config/fastfetch/config.jsonc` (referenced, not opened this pass — already characterized in RESEARCH.md Pattern 3)
**Pattern extraction date:** 2026-07-09
