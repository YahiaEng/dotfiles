---
phase: 04-reliability-fixes-tech-debt
reviewed: 2026-07-11T18:50:00Z
depth: standard
files_reviewed: 8
files_reviewed_list:
  - fastfetch/.config/fastfetch/config.jsonc
  - fish/.config/fish/config.fish
  - fish/.config/fish/functions/y.fish
  - hypr/.config/hypr/hyprlock.conf
  - hypr/.config/hypr/scripts/powermenu.sh
  - kitty/.config/kitty/kitty.conf
  - zshell/.config/oh-my-posh/catppuccin.omp.json
  - zshell/.zshrc
findings:
  critical: 0
  warning: 4
  info: 7
  total: 11
status: issues_found
---

# Phase 4: Code Review Report

**Reviewed:** 2026-07-11T18:50:00Z
**Depth:** standard
**Files Reviewed:** 8
**Status:** issues_found

## Summary

Fresh review of all 8 files after gap-closure plans 04-05 (fish nvm activation, closing prior CR-01) and 04-06 (hyprlock `ignore_empty_input`). This review supersedes the previous 04-REVIEW.md.

Core fixes verified sound against the live system, not just by reading:

- **hyprlock.conf (FIX-02):** all options used exist in the installed hyprlock 0.9.5 binary — `general:ignore_empty_input`, `general:immediate_render`, `check_text`, `invert_numlock`, and the `fadeIn` animation name were confirmed via binary string inspection. Removed options (`grace`, `no_fade_in/out`, `fail_transition`) are correctly absent. `animation = fadeIn, 0` is valid disable syntax.
- **Prior CR-01 (fish nvm activation) is genuinely closed:** fish sources `conf.d/nvm.fish` before `config.fish`, so the plugin's own guard no-ops (verified in the installed plugin: `if status is-interactive && set --query nvm_default_version && ! set --query nvm_current_version`). The explicit `nvm use` in `config.fish` fills that gap, and its `not set -q nvm_current_version` guard is correct — `_nvm_version_activate` sets `nvm_current_version` with `--global --export`, so nested shells inherit both the variable and PATH and correctly skip re-activation.
- **oh-my-posh vendored theme (FIX-03/D-03):** `oh-my-posh print primary --config zshell/.config/oh-my-posh/catppuccin.omp.json --shell zsh` renders successfully (exit 0) with the installed omp 29.25.1 — the old remote GitHub *blob HTML* URL bug is fixed.
- **zshrc lazy-load wrappers (FIX-03/D-04):** the `eval "function $cmd() { lazy_load_nvm; $cmd \"\$@\" }"` pattern was executed under zsh and works (zsh permits `}` without a preceding terminator; self-`unset -f` during execution is safe in zsh; no recursion path when `nvm.sh` is absent because wrappers are unset before dispatch).
- **Syntax:** `bash -n`, `fish -n` (both files), and `zsh -n` all pass.
- **fastfetch/config.jsonc** is unchanged since the diff base (`121cd1f`); reviewed anyway, no issues.

Remaining findings are robustness gaps on the fresh-install path (the project's stated reproducibility constraint) and consistency/quality items. No security or data-loss issues.

## Narrative Findings (AI reviewer)

## Warnings

### WR-01: Fisher bootstrap pipes curl output to `source` without `--fail`

**File:** `fish/.config/fish/config.fish:46`
**Issue:** `curl -sL https://raw.githubusercontent.com/.../fisher.fish | source` does not use `-f/--fail`. If GitHub returns a non-200 body (rate limiting, captive portal, 404 after upstream rename), curl still emits the error page on stdout and `source` attempts to execute HTML — the first interactive shell on a fresh install spews parse errors instead of skipping cleanly. With `-f`, curl outputs nothing and returns non-zero, so the `and fisher update` chain short-circuits and the bootstrap silently retries on the next shell (the `not test -e ...fisher.fish` guard already gives retry semantics).
**Fix:**
```fish
curl -fsSL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
and fisher update
```

### WR-02: `nvm use --silent` prints an error on every shell start until Node is provisioned

**File:** `fish/.config/fish/config.fish:58-59`
**Issue:** On a fresh system, `install.sh` explicitly instructs the user to open a fish shell first and *then* run `nvm install v24.18.0`. But the installed nvm.fish's `use` branch errors unconditionally when the version isn't installed — `--silent` only suppresses the "Now using Node ..." success message, not the error path (verified in `~/.config/fish/functions/nvm.fish`: `echo "nvm: Can't use Node \"$their_version\", version must be installed first" >&2; return 1`). Result: every interactive fish shell between first launch and `nvm install` prints `nvm: Can't use Node "v24.18.0", version must be installed first` — exactly the documented first-run flow.
**Fix:** Guard on the version directory existing (matches the nvm_data layout this config already relies on):
```fish
if not set -q nvm_current_version; and functions -q nvm
    and test -d $nvm_data/$nvm_default_version
    nvm use --silent $nvm_default_version
end
```

### WR-03: Unguarded `source` of uv env file breaks fresh-install zsh startup

**File:** `zshell/.zshrc:123`
**Issue:** `. "$HOME/.local/share/../bin/env"` has no existence guard. `install.sh` does not install uv (grep confirms no uv package), so on a fresh system every zsh start ends with `no such file or directory: /home/.../.local/share/../bin/env` and a non-zero final status. This violates the project's reproducibility constraint (install.sh + stow must produce a working setup). The `.local/share/../bin` indirection is also needlessly obfuscated — it resolves to `.local/bin`.
**Fix:**
```zsh
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"
```

### WR-04: Logout path not given the FIX-01 graceful-teardown treatment

**File:** `hypr/.config/hypr/scripts/powermenu.sh:16` (same pattern in `wlogout/.config/wlogout/layout` logout entry)
**Issue:** FIX-01 wrapped Reboot/Shutdown in `hyprshutdown --post-cmd '...'` so clients close gracefully before session teardown. Logout still runs bare `uwsm stop`, which tears down the graphical session scope with apps live — the same class of hazard (apps ignoring SIGTERM stall unit teardown on systemd stop timeouts) that motivated FIX-01 for shutdown/reboot. If the FIX-01 diagnosis was "session units hang waiting on unclosed clients," logout retains that hang window; if logout was deliberately excluded, that decision is undocumented in the script.
**Fix:** Either apply the same wrapper —
```bash
*"Logout"*)   hyprshutdown --post-cmd 'uwsm stop' ;;
```
— (and mirror it in the wlogout layout) or add a comment recording why `uwsm stop` is exempt from the graceful-close treatment.

## Info

### IN-01: powermenu.sh has no call sites — FIX-01 change is unreachable via normal use

**File:** `hypr/.config/hypr/scripts/powermenu.sh`
**Issue:** Nothing in the repo invokes this script: `keybinds.conf` binds `$mainMod SHIFT+Q` to `wlogout.sh`, waybar configs don't reference it, and the only mention is a README tree listing. The phase's hyprshutdown fix here is correct but only exercisable by running the script manually — the live power-menu path is wlogout. Either wire it to a bind/waybar action or remove it to avoid maintaining two divergent power menus.
**Fix:** Add a keybind (e.g. `bind = $mainMod, Escape, exec, ~/.config/hypr/scripts/powermenu.sh`) or delete the script and its README entry.

### IN-02: APP2UNIT_SLICES is dead configuration in both shells

**File:** `fish/.config/fish/config.fish:8`, `zshell/.zshrc:2`
**Issue:** `app2unit` reads `APP2UNIT_SLICES` from its process environment. In zsh it's assigned unexported; the fish port faithfully reproduces this with `set -g` (comment even notes "unexported there too"). Unexported, it reaches no child process — and even exported from an interactive rc it would never reach app2unit invocations spawned by Hyprland's process tree. As written the variable has no effect anywhere. Parity with a bug is still a bug.
**Fix:** Export it (`set -gx` / `export`) if terminal-launched `app2unit` calls should honor it, or configure slices where app2unit actually runs (uwsm env / `~/.config/uwsm/env`) and delete these lines.

### IN-03: `HISTDUP=erase` is not a zsh option

**File:** `zshell/.zshrc:60`
**Issue:** zsh has no `HISTDUP` parameter — this is a no-op assignment (dedup is already handled by the `setopt hist_ignore_all_dups`/`hist_save_no_dups` lines below). Dead config carried from a tutorial.
**Fix:** Delete the line.

### IN-04: `bun` wrapper forces a full nvm load for a binary already on PATH

**File:** `zshell/.zshrc:117-119` (with `zshell/.zshrc:105-106`)
**Issue:** `$BUN_INSTALL/bin` is prepended to PATH at line 106, so `bun` works without nvm. The lazy-load wrapper shadows it anyway, making the first `bun` call pay the full ~50%-of-shell-init nvm sourcing cost just to load bun completions — the exact cost D-04 set out to avoid.
**Fix:** Drop `bun` from the wrapper loop, or give it its own lightweight loader that sources only `$BUN_INSTALL/_bun`.

### IN-05: Palette key "wight" is a typo for "white"

**File:** `zshell/.config/oh-my-posh/catppuccin.omp.json:8` (referenced at line 17)
**Issue:** Internally consistent so it renders correctly, but the misspelled key will trip up future edits (a "white" reference would silently fail to resolve).
**Fix:** Rename the palette key and its `p:wight` reference to `white`.

### IN-06: hyprlock placeholder text hardcodes a catppuccin hex color

**File:** `hypr/.config/hypr/hyprlock.conf:100`
**Issue:** `placeholder_text = <span foreground="##a6adc8">...` bakes in a catppuccin gray while every other color in the file uses theme variables (`$primary`, `$on_surface`, ...) sourced from `~/.local/state/theme/hyprland.conf`. Switching to a non-catppuccin static theme or a matugen palette leaves the placeholder stale — against the project's "one switch re-themes everything" core value.
**Fix:** Use a theme variable, e.g. `<span foreground="##$on_surface_variant">` (adjust to whichever named color the theme file exports).

### IN-07: `ctrl+c` remapped to unconditional copy removes SIGINT from its conventional key

**File:** `kitty/.config/kitty/kitty.conf:60-65`
**Issue:** `map ctrl+c copy_to_clipboard` means Ctrl+C never interrupts a running process (interrupt is relocated to `ctrl+shift+c` sending `\x03`). With no selection, Ctrl+C does nothing at all. The commented-out alternatives show this was a deliberate choice, but `copy_or_interrupt` preserves both behaviors with no downside.
**Fix:** `map ctrl+c copy_or_interrupt` (copies when a selection exists, interrupts otherwise).

---

_Reviewed: 2026-07-11T18:50:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
