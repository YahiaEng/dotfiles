---
phase: 04-reliability-fixes-tech-debt
reviewed: 2026-07-11T17:45:00Z
depth: standard
files_reviewed: 10
files_reviewed_list:
  - fastfetch/.config/fastfetch/config.jsonc
  - fish/.config/fish/config.fish
  - fish/.config/fish/functions/y.fish
  - hypr/.config/hypr/hyprlock.conf
  - hypr/.config/hypr/scripts/powermenu.sh
  - install.sh
  - kitty/.config/kitty/kitty.conf
  - stow.sh
  - zshell/.config/oh-my-posh/catppuccin.omp.json
  - zshell/.zshrc
findings:
  critical: 0
  warning: 4
  info: 8
  total: 12
status: issues_found
---

# Phase 04: Code Review Report (Re-review after gap-closure plan 04-05)

**Reviewed:** 2026-07-11T17:45:00Z
**Depth:** standard
**Files Reviewed:** 10
**Status:** issues_found

## Summary

Re-review of the full Phase 04 change surface (diff base `2e34f4d^..HEAD`) after gap-closure plan 04-05 executed. The prior review's single Critical (CR-01: fish never activated the default Node version because `conf.d/nvm.fish`'s auto-activation guard runs before `config.fish` sets `nvm_default_version`) was the sole target of 04-05.

**CR-01 fix verified sound — proven live, not just by reading:**

- Clean-environment reproduction of the original failing test now passes on this machine with the stowed HEAD config (`readlink` + `diff` confirmed the stowed `~/.config/fish/config.fish` is byte-identical to the repo file):
  ```
  $ env -i HOME=$HOME USER=$USER TERM=xterm PATH=/usr/bin:/bin \
      fish -i -c 'type -q node; and echo NODE=YES; or echo NODE=NO; ...'
  NODE=YES
  def=v24.18.0
  cur=v24.18.0
  v24.18.0
  ```
  Previously this printed `NODE=NO`.
- The guard logic was checked against the installed nvm.fish 2.2.18 source: `_nvm_version_activate` does `set --global --export nvm_current_version`, so the `not set -q nvm_current_version` inherited-from-parent no-op claim in the config.fish comment is accurate; `functions -q nvm` correctly resolves the autoloadable (not-yet-loaded) function; `nvm use` reads only `$nvm_data` directories (no network at shell start).
- `install.sh:409-415` now documents the one-time `nvm install v24.18.0` provisioning step in the correct order (stow first, then open fish, then install).
- `fish -n`, `zsh -n`, `bash -n` pass on all shell files; both JSON configs validated (`jq`, and `fastfetch --config ... ` exits 0).

**However**, verifying the fix surfaced one new defect in the fresh-machine path (WR-04: the "silent" activation is not silent before Node is provisioned — proven live), and the prior review's three Warnings and seven Info items are all still present in the tree — plan 04-05 scoped only CR-01, so they carry forward unaddressed and are restated below with current line numbers.

## Narrative Findings (AI reviewer)

### Resolved since prior review

- **CR-01 (fish node activation)** — RESOLVED. `fish/.config/fish/config.fish:58-60` adds the guarded `nvm use --silent $nvm_default_version` inside the `status is-interactive` block; `install.sh:411-413` documents the one-time `nvm install v24.18.0`. Verified live as described in the Summary.

## Warnings

### WR-01: `hyprshutdown --post-cmd` may be killed by uwsm session teardown before `systemctl poweroff/reboot` runs — still unverified on hardware (carried forward)

**File:** `hypr/.config/hypr/scripts/powermenu.sh:17-18` (also `wlogout/.config/wlogout/layout:27,33`)
**Issue:** Unchanged since the prior review. `hyprshutdown` runs inside walker's app scope (from powermenu) or the `wayland-wm@hyprland` unit (from the wlogout keybind); forking does not escape a cgroup. Its sequence is close apps → exit Hyprland → run post-cmd; under uwsm, Hyprland exiting stops the session units and systemd kills every remaining process in those cgroups — racing the post-cmd. If the kill wins, the session ends at a TTY without powering off/rebooting (the exact failure class FIX-01 targeted). No end-to-end hardware verification of a wlogout/powermenu Shutdown and Reboot press reaching `systemctl poweroff`/`reboot` is recorded in the phase artifacts.
**Fix:** Verify on hardware. If the race is real, detach into a transient unit outside the session graph:
```
uwsm app -- systemd-run --user --collect hyprshutdown --no-fork --post-cmd 'systemctl poweroff'
```
(or `systemd-run --user --collect hyprshutdown ...` directly from the script).

### WR-02: `.zshrc` unconditionally sources uv's env file — errors on every shell start on a fresh install (carried forward)

**File:** `zshell/.zshrc:123`
**Issue:** Unchanged. `. "$HOME/.local/share/../bin/env"` has no existence guard, and `install.sh` does not install uv — on a fresh system every interactive zsh prints `.zshrc:.:123: no such file or directory`, contrary to this phase's shell-startup-polish goal and the reproducibility constraint. The `share/..` indirection obscures that the target is `~/.local/bin/env`.
**Fix:**
```zsh
[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"
```

### WR-03: fisher bootstrap pipes an unvalidated `curl` body into `source` (carried forward)

**File:** `fish/.config/fish/config.fish:46`
**Issue:** Unchanged. `curl -sL ... | source` has no `--fail`: an HTTP error body (404 page, rate-limit HTML) gets `source`d and spews syntax errors into shell startup, and the bootstrap re-runs with a network round-trip on every interactive shell start while offline/failing, since `fisher.fish` never materializes. It also executes unpinned `main`-branch code.
**Fix:**
```fish
curl -sSfL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
and fisher update
```

### WR-04: `nvm use --silent` is not silent when Node isn't installed — fresh installs print an error on every fish shell start until `nvm install` is run (new; found while verifying the CR-01 fix)

**File:** `fish/.config/fish/config.fish:58-60`; `install.sh:411-413`
**Issue:** In nvm.fish 2.2.18, `--silent` suppresses only the stdout "Now using Node ..." line (`nvm.fish:158`); the not-installed error path is unguarded stderr (`nvm.fish:149-150`). Proven live:
```
$ fish -c 'set -g nvm_data <empty-dir>; nvm use --silent v24.18.0; echo exit-status=$status'
nvm: Can't use Node "v24.18.0", version must be installed first
exit-status=1
```
On a truly fresh machine (install.sh + stow.sh done, `nvm install v24.18.0` not yet run — exactly the window between Next steps 1 and 2), every interactive fish shell prints this error. On the very first shell it can appear twice: fisher sources the plugin's `conf.d/nvm.fish` during `fisher update` at a point where `nvm_default_version` is already set (line 28 runs before the bootstrap block at 45-48), so the plugin's own auto-activation also fires and fails, then config.fish's explicit call fails again. Transient and self-resolving after provisioning, but it degrades the fresh-install first impression this phase targeted, and it reads like a broken config rather than a pending provisioning step.
**Fix:** Skip activation cleanly until the pinned version exists on disk (nvm.fish stores versions at `$nvm_data/<ver>` exactly):
```fish
if not set -q nvm_current_version
    and functions -q nvm
    and test -d $nvm_data/$nvm_default_version
    nvm use --silent $nvm_default_version
end
```
Optionally emit a one-line "run 'nvm install v24.18.0' to finish Node provisioning" hint in the else branch instead of nvm's raw error.

## Info

### IN-01: `APP2UNIT_SLICES` is dead config in both shells (carried forward)

**File:** `fish/.config/fish/config.fish:8`; `zshell/.zshrc:2`
**Issue:** Set but never exported in either shell (`set -g`, not `set -gx`; no `export` in zsh) and nothing in the repo references app2unit — zero runtime effect. Interactive rc files are also the wrong layer for session env under uwsm.
**Fix:** Delete from both files, or move to `uwsm/.config/uwsm/env` as a real exported session variable.

### IN-02: `vim`/`zed` aliases point at binaries `install.sh` never installs (carried forward)

**File:** `fish/.config/fish/config.fish:64,67`; `zshell/.zshrc:80,83`; `install.sh:52-152`
**Issue:** `alias vim nvim` — neovim is absent from `PACMAN_PKGS`/`AUR_PKGS`; `zed` points at `~/.local/bin/zed`, which nothing provisions. On a fresh system both aliases are broken (`vim` stops working entirely since the alias shadows any real vim).
**Fix:** Add `neovim` to `PACMAN_PKGS`, or guard/drop the aliases.

### IN-03: fisher rewrites `fish_plugins` through the stow symlink into the repo — stow.sh comment overstates the invariant (carried forward)

**File:** `fish/.config/fish/fish_plugins:1-2`; `stow.sh:55-60`
**Issue:** `fish_plugins` is stowed as a symlink and fisher rewrites it on every `fisher install/update/remove` — writes land in the git working tree. Today the content round-trips identically, but any interactive fisher operation will silently dirty the repo, contradicting the comment's "never inside the repo tree" framing.
**Fix:** Adjust the stow.sh comment to state `fish_plugins` is intentionally repo-backed and fisher writes to it.

### IN-04: zsh lazy-load wrapper for `bun` defeats its own purpose (carried forward)

**File:** `zshell/.zshrc:117-119`
**Issue:** `bun` is already on PATH via `BUN_INSTALL/bin` (line 106); wrapping it means the first `bun` invocation sources all of `nvm.sh` — the exact ~53% startup cost D-04 deferred — just to load bun's tab completions.
**Fix:** Drop `bun` from the wrapper loop; source `$BUN_INSTALL/_bun` behind its own tiny wrapper if completions matter.

### IN-05: `HISTDUP=erase` is not a zsh option (carried forward)

**File:** `zshell/.zshrc:60`
**Issue:** `HISTDUP` is not a zsh parameter; the line is a no-op. Dedup actually comes from the `setopt hist_*` lines below.
**Fix:** Delete the line.

### IN-06: hyprlock placeholder color hardcodes a Catppuccin hex, bypassing the theme engine (carried forward)

**File:** `hypr/.config/hypr/hyprlock.conf:94`
**Issue:** `placeholder_text = <span foreground="##a6adc8">...` hardcodes Catppuccin's overlay1 while every other color uses `$primary`/`$on_surface` theme variables — under a matugen dynamic theme the placeholder stays Catppuccin-tinted.
**Fix:** Use a sourced theme variable, or document the exception.

### IN-07: oh-my-posh palette key `"wight"` is a typo for `"white"` (carried forward)

**File:** `zshell/.config/oh-my-posh/catppuccin.omp.json:8,17`
**Issue:** Self-consistent so it renders, but the misspelled palette key (`p:wight`) is a trap for future edits.
**Fix:** Rename the key and its one reference to `white`.

### IN-08: zsh's nvm lazy-load references `$NVM_DIR/nvm.sh`, which nothing installs — Node remains absent in zsh on a fresh system (new)

**File:** `zshell/.zshrc:102,111-119`; `install.sh:52-205`
**Issue:** The 04-05 provisioning doc closes the Node gap for fish only. `lazy_load_nvm` sources `$NVM_DIR/nvm.sh` (`~/.config/nvm/nvm.sh`) behind an `[ -s ... ]` guard, but no package in `install.sh` provides bash nvm (line 101's `/usr/share/nvm/init-nvm.sh` source is commented out and the `nvm` package isn't in any list). On a fresh machine the guard silently skips, the wrappers unset themselves, and `node`/`npm` fall through to a bare PATH lookup — command not found, forever, with no error hinting why. Even after fish's `nvm install v24.18.0` populates `~/.config/nvm/versions/node/v24.18.0`, zsh gains nothing because activation requires `nvm.sh`. Impact is limited — fish is the interactive shell (D-08/D-12) and zsh is the TTY-recovery path — but the same fresh-install reasoning that justified CR-01 applies in miniature here.
**Fix:** Either add the `nvm` package to `PACMAN_PKGS` and restore the `/usr/share/nvm/init-nvm.sh`-based lazy-load, or as a zero-package alternative have the zsh wrappers prepend `~/.config/nvm/versions/node/v24.18.0/bin` (the fish-provisioned install) to PATH, or document that Node tooling is fish-only.

---

_Reviewed: 2026-07-11T17:45:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
