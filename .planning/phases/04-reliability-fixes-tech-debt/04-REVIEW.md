---
phase: 04-reliability-fixes-tech-debt
reviewed: 2026-07-11T16:50:00Z
depth: standard
files_reviewed: 12
files_reviewed_list:
  - wlogout/.config/wlogout/layout
  - hypr/.config/hypr/scripts/powermenu.sh
  - hypr/.config/hypr/hyprlock.conf
  - install.sh
  - stow.sh
  - kitty/.config/kitty/kitty.conf
  - fish/.config/fish/config.fish
  - fish/.config/fish/functions/y.fish
  - fish/.config/fish/fish_plugins
  - zshell/.zshrc
  - zshell/.config/oh-my-posh/catppuccin.omp.json
  - fastfetch/.config/fastfetch/config.jsonc
findings:
  critical: 1
  warning: 3
  info: 7
  total: 11
status: issues_found
---

# Phase 04: Code Review Report

**Reviewed:** 2026-07-11T16:50:00Z
**Depth:** standard
**Files Reviewed:** 12
**Status:** issues_found

## Summary

Reviewed all Phase 04 changes (diff base `37411b3..HEAD`): wlogout/powermenu migration to `hyprshutdown --post-cmd`, hyprlock 0.9.5 config migration, zsh startup optimization (vendored oh-my-posh theme, nvm/bun lazy-load), and fish adoption (stow package, kitty `shell fish`, fisher self-bootstrap).

**Verified correct (against the live system, not just by reading):**
- `hyprshutdown` 0.1.1 is in the official `extra` repo and its CLI has `--post-cmd` — `install.sh` placement in `PACMAN_PKGS` is correct.
- The hyprlock migration claims check out against the installed `hyprlock` v0.9.5 binary: `general:immediate_render` and the `fadeIn`/`fadeOut` animation names exist; `grace` and `fail_transition` are gone from the config parser (grace is CLI-only and deprecated even there). No repo invocation passes `--grace`, as the comment asserts.
- `fish -n` and `zsh -n` pass on all shell configs; both JSON configs are valid; the vendored oh-my-posh theme renders successfully (`oh-my-posh print primary` exit 0).
- `stow.sh`'s fish dir pre-creation correctly prevents dir-folding; `y.fish` matches the official yazi fish wrapper.

**However, one Critical defect was proven live:** the fish nvm configuration never activates Node in a fresh shell — the D-10 "1:1 parity" claim is false for the single most important tool the config tries to wire up (see CR-01, reproduced with a clean-environment fish launch on this machine).

## Narrative Findings (AI reviewer)

## Critical Issues

### CR-01: fish never activates the default Node version — `node`/`npm`/`npx` are absent from every fresh fish shell

**File:** `fish/.config/fish/config.fish:24-25`
**Issue:** fish sources `conf.d/*.fish` snippets **before** `config.fish`. The nvm.fish plugin's auto-activation lives in `conf.d/nvm.fish` (verified on this host):

```fish
set --query nvm_data || set --global nvm_data $XDG_DATA_HOME/nvm
...
if status is-interactive && set --query nvm_default_version && ! set --query nvm_current_version
    nvm use --silent $nvm_default_version
end
```

At the moment that runs, `config.fish:24-25` (`set -g nvm_data ...`, `set -g nvm_default_version v24.18.0`) has **not executed yet**, so `set --query nvm_default_version` is false and activation is silently skipped. No universal `nvm_*` variables exist in `~/.config/fish/fish_variables` to compensate (verified). The comment on lines 18-24 claims this is "structurally equivalent to zsh's D-04 lazy-load" — it is not: zsh's wrappers load node on first invocation; fish never loads it at all.

**Proof (this machine, HEAD config stowed):**
```
$ env -i HOME=$HOME USER=$USER TERM=xterm PATH=/usr/bin:/bin \
    fish -i -c 'type -q node; and echo NODE=YES; or echo NODE=NO; echo def=$nvm_default_version'
NODE=NO
def=v24.18.0
```
`nvm_default_version` is set (too late) but `nvm_current_version` is empty and `node` is not found. The bug is masked in casual testing because a kitty/terminal spawned from an nvm-loaded parent shell inherits a PATH that already contains `~/.config/nvm/versions/node/v24.18.0/bin` — a fresh login session does not.

**Fix:** activate explicitly in `config.fish` after the variables are set (inside the existing `status is-interactive` block), mirroring the plugin's own guard:
```fish
# nvm.fish's conf.d auto-activation ran before config.fish set these vars —
# activate the default version ourselves.
if not set -q nvm_current_version; and functions -q nvm
    nvm use --silent $nvm_default_version
end
```
Alternatively, ship the two `set -g nvm_*` lines in a stowed conf.d snippet that sorts before `nvm.fish` (e.g. `fish/.config/fish/conf.d/00-nvm-env.fish`), or use `set -U` per nvm.fish's README (not stow-reproducible). Note also that nothing in `install.sh` installs Node v24.18.0 into `~/.config/nvm/versions/node`, so on a truly fresh machine even the fixed activation is a silent no-op until `nvm install v24.18.0` is run once — worth a line in the install docs.

## Warnings

### WR-01: `hyprshutdown --post-cmd` may be killed by uwsm session teardown before `systemctl poweroff/reboot` runs — unverified survival

**File:** `wlogout/.config/wlogout/layout:27,33`; `hypr/.config/hypr/scripts/powermenu.sh:17-18`
**Issue:** `wlogout` is launched directly from a Hyprland keybind (`wlogout.sh`, exec'd by Hyprland), so `hyprshutdown` runs inside the `wayland-wm@hyprland` unit's cgroup; from `powermenu.sh` it runs inside walker's app scope. `hyprshutdown` forks/daemonizes by default, but forking does **not** escape a cgroup. Its documented sequence is: close apps → exit Hyprland → run post-cmd. Under uwsm, Hyprland exiting stops the session units and systemd kills every remaining process in those cgroups — racing the post-cmd. If the kill wins, the session ends at a TTY without powering off/rebooting (the exact failure class Phase 04's FIX-01 targeted). The repo's #423 diagnosis harness (commit 37c2dd9) suggests this area is already known to be fragile.
**Fix:** Verify end-to-end on hardware that both Shutdown and Reboot actually reach `systemctl poweroff`/`reboot` from a wlogout press (not just that Hyprland exits cleanly). If the race is real, detach hyprshutdown from the session graph, e.g.:
```
"action": "systemd-run --user --collect hyprshutdown --no-fork --post-cmd 'systemctl poweroff'"
```
so it lives in a transient unit outside `wayland-session@`/app slices that `uwsm stop` tears down.

### WR-02: `.zshrc` unconditionally sources uv's env file — errors on every shell start on a fresh install

**File:** `zshell/.zshrc:123`
**Issue:** `. "$HOME/.local/share/../bin/env"` has no existence guard (unlike the `[ -s ... ]`-guarded nvm lines four lines above). `install.sh` does not install uv, so on a fresh system every interactive zsh prints `.zshrc:.:123: no such file or directory` — directly contrary to this phase's shell-startup-polish goal and the reproducibility constraint. The `share/..` indirection also obscures that the target is simply `~/.local/bin/env`. (Pre-existing line, but it sits in a file this phase rewrote for startup quality.)
**Fix:**
```zsh
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"
```

### WR-03: fisher bootstrap pipes an unvalidated `curl` body into `source`

**File:** `fish/.config/fish/config.fish:43-44`
**Issue:** `curl -sL https://raw.githubusercontent.com/... | source` has no `--fail`: if GitHub returns an error body (404 text, rate-limit page, captive-portal HTML), fish `source`s it and spews syntax errors into the first shell's startup. The `and fisher update` guard limits the damage and the check retries next shell, but the failure mode is noisy, and the bootstrap re-runs (with a network round-trip) on **every** interactive shell start while offline/failing, since `fisher.fish` never materializes. It also executes unpinned `main`-branch code — acceptable for a personal rig, but worth acknowledging.
**Fix:**
```fish
curl -sSfL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
and fisher update
```
(`-f` makes HTTP errors produce empty output + nonzero exit, so `and` short-circuits cleanly; `-S` surfaces one concise error line instead of silence.)

## Info

### IN-01: `APP2UNIT_SLICES` is dead config in both shells

**File:** `fish/.config/fish/config.fish:8`; `zshell/.zshrc:2`
**Issue:** Set but never exported in either shell (`set -g`, not `set -gx`; no `export` in zsh), and nothing else in the repo references app2unit. app2unit reads this from the process environment, so as written it has zero effect — the fish port faithfully reproduced a no-op ("unexported there too"). Interactive rc files are also the wrong layer for session env under uwsm.
**Fix:** Either delete from both files, or move to `uwsm/.config/uwsm/env` as a real exported session variable.

### IN-02: `vim`/`zed` aliases point at binaries `install.sh` never installs

**File:** `fish/.config/fish/config.fish:50,53`; `zshell/.zshrc:80,83`; `install.sh:52-152`
**Issue:** `alias vim nvim` — neovim is absent from `PACMAN_PKGS`/`AUR_PKGS`; `zed` points at `~/.local/bin/zed`, which nothing provisions. On a fresh system both aliases are broken (`vim` stops working entirely since the alias shadows any real vim). Reproducibility gap, now duplicated into the new fish package.
**Fix:** Add `neovim` to `PACMAN_PKGS`, or guard/drop the aliases.

### IN-03: fisher rewrites `fish_plugins` through the stow symlink into the repo

**File:** `fish/.config/fish/fish_plugins:1-2`; `stow.sh:55-60`
**Issue:** `fish_plugins` is stowed as a symlink, and fisher rewrites that file on every `fisher install/update/remove` — writes pass through the symlink into the git working tree. Today the content round-trips identically (sorted, matches committed state), so the first-boot tree stays clean, but any interactive fisher operation will silently dirty the repo. This is arguably desired (version-controlled plugin list) but contradicts the absolutist framing of the stow.sh comment ("never inside the repo tree").
**Fix:** None required; adjust the stow.sh comment to state that `fish_plugins` intentionally is repo-backed and fisher writes to it.

### IN-04: zsh lazy-load wrapper for `bun` defeats its own purpose

**File:** `zshell/.zshrc:117-119`
**Issue:** `bun` is already on PATH via `BUN_INSTALL/bin` (line 106); wrapping it means the first `bun` invocation sources all of `nvm.sh` — the exact ~53% startup cost D-04 deferred — just to load bun's tab completions. Node tooling and bun are independent.
**Fix:** Drop `bun` from the wrapper loop; if bun completions matter, source `$BUN_INSTALL/_bun` behind its own tiny wrapper or accept the one-time cost only for node-family commands.

### IN-05: `HISTDUP=erase` is not a zsh option

**File:** `zshell/.zshrc:60`
**Issue:** `HISTDUP` is not a zsh parameter; the line is a no-op inherited from a popular dotfiles tutorial. The actual dedup behavior comes from the `setopt hist_ignore_all_dups`/`hist_save_no_dups` lines below.
**Fix:** Delete the line.

### IN-06: hyprlock placeholder color hardcodes a Catppuccin hex, bypassing the theme engine

**File:** `hypr/.config/hypr/hyprlock.conf:94`
**Issue:** `placeholder_text = <span foreground="##a6adc8">...` hardcodes Catppuccin's overlay1 while every other color in the file uses `$primary`/`$on_surface` theme variables — under a matugen dynamic theme the placeholder stays Catppuccin-tinted. Pre-existing, untouched by this phase's migration.
**Fix:** Use a sourced theme variable (e.g. `foreground="$on_surface"` with reduced alpha) or accept and document the exception.

### IN-07: oh-my-posh palette key `"wight"` is a typo for `"white"`

**File:** `zshell/.config/oh-my-posh/catppuccin.omp.json:8,17`
**Issue:** Self-consistent so it renders, but the misspelled palette key (`p:wight`) is a trap for future edits (adding `p:white` alongside would silently split usages).
**Fix:** Rename the key and its one reference to `white`.

---

_Reviewed: 2026-07-11T16:50:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
