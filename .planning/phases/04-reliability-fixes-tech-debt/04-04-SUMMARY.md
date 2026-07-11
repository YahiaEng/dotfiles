---
phase: 04-reliability-fixes-tech-debt
plan: 04
subsystem: shell-startup
tags: [fish, zsh, hyperfine, benchmark, kitty, stow, fisher, nvm.fish, oh-my-posh]

requires:
  - phase: 04-reliability-fixes-tech-debt
    provides: "Plan 03's optimized zsh (vendored oh-my-posh theme, lazy nvm/bun) as the benchmark baseline"
provides:
  - "Data-backed shell decision (D-08): fish adopted — 32.7ms vs 95.5ms warm (~2.9x)"
  - "fish stow package at day-one D-10 parity (prompt, fzf, zoxide, fastfetch, node tooling, y function)"
  - "Declarative shell switch: kitty.conf `shell fish` + install.sh PACMAN_PKGS + stow.sh PACKAGES — no chsh, login shell stays zsh"
  - "zshell stow package retained as installable fallback (D-11)"
affects: [phase-06-redesigns, fresh-install-container-gate]

tech-stack:
  added: [fish 4.8.0 (official extra repo), fisher + nvm.fish (fisher plugins, human-approved at package-legitimacy gate)]
  patterns: ["fisher self-bootstrap on first interactive shell (analog of .zshrc's zinit self-clone)", "pre-create real dirs before stow to prevent dir-folding of host-generated plugin files"]

key-files:
  created:
    - fish/.config/fish/config.fish
    - fish/.config/fish/functions/y.fish
    - fish/.config/fish/fish_plugins
  modified:
    - kitty/.config/kitty/kitty.conf
    - install.sh
    - stow.sh

key-decisions:
  - "fish adopted (D-08, user decision): warm mean 32.7ms ± 0.8 vs optimized zsh 95.5ms ± 2.0 (~2.9x faster) with full D-10 parity verified live"
  - "Switch is kitty.conf-only (D-12): `shell fish` directive; no chsh anywhere — system login shell stays zsh as the TTY recovery path"
  - "nvm.fish approved by user at the non-auto-approvable package-legitimacy gate; configured to reuse existing ~/.config/nvm/versions/node installs"
  - "fisher self-bootstrap added to config.fish (reproducibility constraint): fresh systems install fisher + pinned fish_plugins on first interactive shell"

requirements-completed: [FIX-03]

coverage:
  - id: D1
    description: "Optimized zsh and fish benchmarked side-by-side (cold + warm via hyperfine) with documented trade-off note (D-07/D-08)"
    requirement: "FIX-03"
    verification:
      - kind: other
        ref: "hyperfine --warmup 3 --min-runs 10 '<shell> -i -c exit' both shells + no-warmup cold series; comparison table + trade-off note in this SUMMARY"
        status: pass
    human_judgment: false
  - id: D2
    description: "User selects the winning shell at a decision checkpoint on speed + feel (D-08)"
    requirement: "FIX-03"
    verification:
      - kind: other
        ref: "Task 3 checkpoint: user selected fish; deciding numbers recorded below"
        status: pass
    human_judgment: true
  - id: D3
    description: "fish wired via kitty.conf shell directive (no chsh), install.sh PACMAN_PKGS, stow.sh PACKAGES (D-09/D-12)"
    requirement: "FIX-03"
    verification:
      - kind: other
        ref: "grep '^shell fish' kitty.conf; grep '^    fish$' install.sh PACMAN_PKGS + stow.sh PACKAGES; git grep chsh shows only stow.sh's pre-existing zsh line"
        status: pass
    human_judgment: false
  - id: D4
    description: "Day-one parity (D-10): vendored oh-my-posh prompt, fzf, zoxide, trimmed fastfetch greeting, working node tooling"
    requirement: "FIX-03"
    verification:
      - kind: other
        ref: "fish -i live checks: fish_prompt defined (oh-my-posh), fzf bindings bound, zoxide cd, node v24.18.0/npm 11.16.0/nvm 2.2.18/bun 1.3.14 all resolve, y function loads"
        status: pass
    human_judgment: false
  - id: D5
    description: "zshell stow package retained as installable fallback (D-11); no nushell evaluated (D-07)"
    requirement: "FIX-03"
    verification:
      - kind: other
        ref: "zshell still in stow.sh PACKAGES, zshell/ directory intact; benchmark compared only zsh and fish"
        status: pass
    human_judgment: false

metrics:
  duration: ~25min active (excl. human checkpoint waits)
  completed: 2026-07-11
status: complete
---

# Phase 4 Plan 4: Shell Benchmark & Fish Adoption Summary

**Benchmarked Plan 03's optimized zsh (95.5ms warm) against a full-parity fish 4.8.0 config (32.7ms warm, ~2.9x faster), the user picked fish at the D-08 checkpoint, and the switch was wired declaratively — `shell fish` in kitty.conf (no chsh, login shell stays zsh), fish in install.sh PACMAN_PKGS and stow.sh PACKAGES, zshell retained as fallback.**

## Performance

- **Duration:** ~25 min active (started 2026-07-11T13:51:23Z; wall time includes three human checkpoint waits)
- **Tasks:** 4 (2 auto, 2 human checkpoints)
- **Files:** 3 created (fish stow package), 3 modified (kitty.conf, install.sh, stow.sh)

## Benchmark: optimized zsh vs fish (D-07)

**Methodology (identical for both shells, same as 04-03):** `hyperfine --warmup 3 --min-runs 10 '<shell> -i -c exit'` for warm; a separate no-warmup `hyperfine --runs 10` series for the cold approximation (true cold-cache measurement requires root `drop_caches`, unavailable here — both shells got identical treatment, so the comparison is fair). fastfetch (~6.1ms, prints in both shells' interactive init) is included in both numbers. hyperfine 1.20.0 at `~/.cargo/bin/hyperfine`. Both shells measured on the same machine, same session, back-to-back. Measured 2026-07-11.

### Comparison table

| Measure | optimized zsh (Plan 03) | fish 4.8.0 (parity config) | Delta |
|---|---|---|---|
| Warm mean | 95.5 ms ± 2.0 ms | **32.7 ms ± 0.8 ms** | **−62.8 ms (−65.8%, ~2.9x faster)** |
| Warm min … max | 93.1 … 100.9 ms (30 runs) | 30.0 … 34.5 ms (86 runs) | |
| Cold (first run, no warmup) | 92.0 ms | 33.3 ms | −58.7 ms |
| Cold series mean (10 runs, no warmup) | 96.0 ms | 32.9 ms | −63.1 ms |
| + fastfetch (constant in both) | 6.1 ms ± 0.4 ms | 6.1 ms ± 0.4 ms | 0 |
| **Combined time-to-usable-prompt (warm)** | **~101.6 ms** | **~38.8 ms** | **−62.8 ms** |

Both shells are comfortably under the ~400ms D-21 budget. The zsh warm mean (95.5ms) reproduces 04-03's recorded 96.1ms ± 2.2ms baseline within noise. After adding the fisher self-bootstrap no-op guard, fish re-measured at 33.3ms ± 0.8 — within noise of the decision number.

### Where the difference comes from

04-03 predicted this: after the nvm/oh-my-posh fixes, zsh's dominant residual cost is `compinit`/`compdump`/`compdef` (zsh's completion machinery, ~33% cumulative in the original zprof) plus zinit plugin sourcing. Fish's completion system is built in and lazy — it pays none of that at startup. nvm.fish activation is a PATH-prepend only (structurally equivalent to the zsh lazy shim, but with `node` on PATH immediately rather than after a first-call shim).

### Trade-off note (feel / parity completeness) for the D-08 decision

**Parity achieved (verified working in `fish -i`):**
- oh-my-posh prompt from the SAME vendored `~/.config/oh-my-posh/catppuccin.omp.json` (Plan 03) — identical prompt look
- `fzf --fish` keybindings (Ctrl-R history, Ctrl-T files) — verified bound
- `zoxide init --cmd cd fish` — `cd` is zoxide-backed, same as zsh
- fastfetch greeting under `status is-interactive`
- Node tooling via nvm.fish 2.2.18 (fisher plugin, human-approved): `node` v24.18.0 / `npm` 11.16.0 / `bun` 1.3.14 all resolve; reuses the existing `~/.config/nvm/versions/node` installs (no re-download)
- `y` yazi cwd-follow function ported (`functions/y.fish`)
- Aliases (ls/vim/c/codium/zed), PATH (cargo/local/bun/spicetify), APP2UNIT_SLICES

**What fish does NOT carry over (honest gaps vs. the zinit setup):**
- zsh-specific zinit plugins/snippets (OMZ git aliases like `gst`/`gco`, `sudo` Esc-Esc, archlinux/kubectl/aws snippets) — fish has its own built-ins (autosuggestions and syntax highlighting are native, better than the zsh plugins), but the OMZ alias packs are simply absent
- fzf-tab (fzf-driven TAB completion menu) — fish's native TAB pager replaces it; different feel, not fzf-driven
- Syntax: fish is not POSIX — pasted `$(...)`/`export FOO=bar` one-liners from the web need fish syntax (`(...)`, `set -gx FOO bar`)

**Feel:** fish gives native autosuggestions + highlighting with zero plugins, and a noticeably snappier open (~39ms vs ~102ms to usable prompt). The login shell stays zsh either way (D-12), and the zshell package remains stowed as the fallback (D-11).

## Decision (D-08)

**Decision: fish** — selected by the user at the Task 3 checkpoint. Deciding numbers: fish warm mean **32.7 ms ± 0.8 ms** vs optimized zsh **95.5 ms ± 2.0 ms** (~2.9x faster, −62.8 ms), with full D-10 parity verified live.

### Applied wiring (Task 4)

- `kitty/.config/kitty/kitty.conf`: new `# ── Shell ─` banner section with `shell fish` — the ONLY switch point (D-12). No chsh anywhere; `stow.sh`'s existing `sudo chsh -s "$(which zsh)"` line is unchanged, so the system login shell stays zsh (TTY recovery path keeps the proven zshell setup). kitty's `repaint_delay`/`input_delay`/`sync_to_monitor` untouched (Pitfall 3).
- `install.sh`: `fish` added to PACMAN_PKGS under a new `# Shell` group (official `extra` repo — NOT AUR_PKGS). 04-01's additions (`rsync`, `hyprshutdown`) preserved. Flows through the existing `verify_packages` hard-fail gate automatically.
- `stow.sh`: `fish` added to PACKAGES alphabetically (fastfetch → fish → gtk); pre-creates `~/.config/fish/{functions,conf.d,completions}` as real dirs before stowing (fold-prevention, see Deviations). `zshell` remains in PACKAGES — the fallback shell is retained (D-11).

### Prohibitions confirmed

- **No chsh for fish** — the only chsh in the repo is stow.sh's pre-existing zsh line (D-12). ✓
- **zshell stow package retained** — still in stow.sh PACKAGES, `zshell/` directory intact (D-11). ✓
- **No nushell evaluated** — benchmark compared only optimized zsh and fish (D-07). ✓
- **kitty rendering knobs untouched** — git diff shows no change to repaint_delay/input_delay/sync_to_monitor. ✓

## Authentication / Privilege Gates (normal flow, not deviations)

1. **Task 1 package-legitimacy gate (blocking, non-auto-approvable):** user verified and approved `fisher` + `nvm.fish` (both github.com/jorgebucaran projects) before any install — resolves RESEARCH.md's [ASSUMED] flag (A1) and threat T-04-SC's mitigation.
2. **fish install (sudo password-gated):** the executor cannot run `sudo pacman` in this environment (no passwordless sudo — same blocker as 04-01/04-03). Returned a human-action checkpoint; the user ran `sudo pacman -S --needed fish` (fish 4.8.0-1 verified installed). No repo impact — fish is correctly declared in install.sh for fresh systems.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Reproducibility] fisher self-bootstrap added to config.fish**
- **Found during:** Task 4 wrap-up
- **Issue:** fisher + nvm.fish were installed manually this session; on a fresh `install.sh` + `stow.sh` system they would be absent — no `nvm`/node-on-PATH, breaking D-10 parity and the project's "no manual host-only state" constraint.
- **Fix:** Ported `.zshrc`'s zinit self-clone pattern: first interactive fish shell installs fisher and runs `fisher update` against the vendored `fish_plugins` list. No-op guard (`test -e fisher.fish`) adds no measurable startup cost (33.3ms ± 0.8 re-benchmark, within noise).
- **Files modified:** fish/.config/fish/config.fish
- **Commit:** 0ce8d02

**2. [Rule 2 - Git-clean invariant] stow dir-folding prevention for fish plugin dirs**
- **Found during:** Task 4 wrap-up
- **Issue:** On a fresh system `~/.config/fish` doesn't exist, so stow would fold the whole dir into a repo symlink — fisher's generated plugin files (fisher.fish, nvm.fish functions/conf.d/completions) would then be written INSIDE the git tree, dirtying `git status` (violates the v1.0-validated git-clean invariant).
- **Fix:** stow.sh pre-creates `~/.config/fish/{functions,conf.d,completions}` as real dirs before the stow loop, so only the repo's own files are symlinked and fisher output stays host-side (mirroring how zinit plugins live in `~/.local/share/zinit`).
- **Files modified:** stow.sh
- **Commit:** 51f769b

**3. [Minor addition] fish_plugins vendored in the stow package**
- **Found during:** Task 2
- **Issue:** Plan's artifact list named only config.fish and y.fish; fisher needs a plugin manifest for reproducible installs.
- **Fix:** `fish/.config/fish/fish_plugins` (jorgebucaran/fisher + jorgebucaran/nvm.fish) vendored declaratively — the self-bootstrap and `fisher update` install exactly this pinned list.
- **Commit:** 186afb6

---

**Total deviations:** 3 auto-fixed (2 reproducibility/invariant guards, 1 minor manifest addition). No architectural changes; no Rule 4 escalations beyond the plan's own checkpoints.

## Known Stubs

None — no placeholder values or unwired components. All parity items are live-verified.

## Task Commits

1. **Task 1: Package-legitimacy gate (nvm.fish)** — checkpoint, no code; user approved nvm.fish
2. **Task 2: fish parity config + benchmark** — `186afb6` (feat: fish stow package), `b6f7cae` (docs: benchmark record)
3. **Task 3: Shell decision checkpoint** — user selected fish
4. **Task 4: Apply the fish switch** — `3e77c0c` (feat: kitty.conf/install.sh/stow.sh wiring), `0ce8d02` (fix: fisher self-bootstrap), `51f769b` (fix: stow fold-prevention)

**Plan metadata:** (final docs commit)

## Files Created/Modified

- `fish/.config/fish/config.fish` — fish init: D-10 parity items + fisher self-bootstrap (new)
- `fish/.config/fish/functions/y.fish` — yazi cwd-follow port (new)
- `fish/.config/fish/fish_plugins` — pinned fisher plugin manifest (new)
- `kitty/.config/kitty/kitty.conf` — `shell fish` directive in a new banner section
- `install.sh` — `fish` in PACMAN_PKGS under `# Shell` group (rsync/hyprshutdown from 04-01 intact)
- `stow.sh` — `fish` in PACKAGES + fold-prevention mkdir; zshell + chsh-to-zsh untouched

## Next Phase Readiness

- FIX-03 fully closed: shell startup went 641ms (pre-04-03) → 96ms (optimized zsh) → 33ms (fish); D-21's ~400ms budget beaten ~10x
- End-of-phase UAT should include: open a new kitty window → fish greets with fastfetch + oh-my-posh prompt (~39ms to usable prompt); the container gate rerun (already pending for 04-01's DEBT-01) now also covers the fish PACMAN_PKGS/stow additions
- Phase 6+ scripts remain POSIX/bash (all repo scripts have bash shebangs) — unaffected by the interactive-shell switch
- zshell fallback: TTY login and `stow.sh`'s chsh still give zsh; any fish issue is recoverable without a rescue disk

---
*Phase: 04-reliability-fixes-tech-debt*
*Completed: 2026-07-11*

## Self-Check: PASSED

- FOUND: fish/.config/fish/{config.fish, functions/y.fish, fish_plugins}
- FOUND: kitty/.config/kitty/kitty.conf, install.sh, stow.sh (modified)
- FOUND commits: 186afb6, b6f7cae, 3e77c0c, 0ce8d02, 51f769b
