# Phase 4 Plan 4: Shell Benchmark (zsh vs fish) — IN PROGRESS

> Benchmark record for the Task 3 decision checkpoint. This file is finalized
> (frontmatter, decision, wiring) by Task 4 after the user's D-08 selection.

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

Both shells are comfortably under the ~400ms D-21 budget. The zsh warm mean (95.5ms) reproduces 04-03's recorded 96.1ms ± 2.2ms baseline within noise.

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

**Decision: pending** — awaiting the Task 3 checkpoint selection (fish or zsh).
