---
title: Themed nvim — measured constraints, plugin slate and design decisions
date: 2026-08-20
context: Pre-planning exploration for a full-IDE themed neovim; vscodium stays installed alongside it
status: input to /gsd-new-milestone (v5.0 has no roadmap yet)
---

# Themed nvim — constraints, slate & decisions

Everything under "Measured" was read off this host or out of this repo.
Everything under "Researched" carries its disposition — admitted claims name a
primary source, unresolved ones stay unresolved and must not be restated as
fact downstream.

## Starting state (measured 2026-08-20)

- `nvim` is **absent**. `neovim 0.12.4-1` is in Arch `extra` — pacman, no AUR,
  no build step.
- `vim` is **broken on this host**: both shells alias it to the missing binary.
  `zshell/.zshrc:80` (`alias vim='nvim'`) and
  `fish/.config/fish/config.fish:206` (`alias vim nvim`). Real `vim 9.2.0849-1`
  is installed but shadowed by the alias.
- `EDITOR` and `VISUAL` are both **unset**.
- No `nvim/` stow package, no `~/.config/nvim`, no `~/.local/share/nvim`.
  Entirely greenfield.
- zellij-autolock's trigger list already names `nvim`/`hx`/`helix`, so the
  multiplexer half is pre-wired — no zellij config change needed when nvim
  arrives.

## The two constraints that shape the design

**1. No editor in this repo themes syntax today.**
`matugen/.config/matugen/templates/vscodium-colors.json` contains **zero**
`tokenColors` / `semanticTokenColors` / `scope` entries — it colours only UI
chrome (activity bar, tabs, inputs, lists). vscodium's actual code colours come
from whatever theme extension is active and are untouched by matugen.

So nvim is the **first surface where matugen must drive real syntax colours**
across all 20 palettes. There is no existing pattern to copy here.

**2. The palette has fewer hues than syntax highlighting needs.**
Palettes are Material You *roles*, not a 16-colour ramp. From
`theme-engine/.config/theme-engine/palettes/catppuccin.json`:

```
primary                #cba6f7  purple
secondary              #89b4fa  blue
tertiary               #a6e3a1  green
error                  #f38ba8  red
on_secondary_container #89b4fa  (duplicate of secondary)
on_tertiary_container  #cdd6f4  near-white
on_surface_variant     #a6adc8  grey
outline                #585b70  dim grey
surface_variant        #313244  background
```

Roughly **four real hues plus greys**. Syntax wants 8+ distinguishable
(keyword, string, function, comment, type, constant, operator, variable).

kitty already hit this wall: its 16 ANSI slots are filled from 7 role values,
with bright `color9`–`color14` being **exact duplicates** of `color1`–`color6`
(`matugen/.config/matugen/templates/kitty-colors.conf:35-49`), and the template
header carries a documented WCAG contrast fight over `color6`.

**And matugen templates cannot do colour math** — every `{{...}}` is a literal
role lookup. There is no way to derive a hue inside a template.

## Decision: let Lua derive the ramp

nvim is the first themed surface in this repo whose config language is a real
programming language. Every other surface is a dumb text template.

So: **matugen renders a small Lua palette table** to
`~/.local/state/theme/nvim.lua` (the ~9 role colours, nothing more), and a
**hand-written colorscheme owned by this repo** reads that table and *computes*
the full syntax ramp — hue rotation and lightness steps — at load time.

This solves the four-hues-vs-eight-tokens problem without adding roles to the
palette, and keeps every other surface's contract untouched.

## Decision: lazy.nvim, not the first-party vim.pack

This is a **deliberate exception** to the in-tree/first-party preference
(CLAUDE.md; the monocle revert of 2026-08-20).

That rule says prefer first-party *unless it genuinely cannot do the job*.
nvim 0.12 does ship `vim.pack` in core, but it is self-described experimental
and `vim.pack.add` can drop entries from its lockfile on partial install
failure (neovim/neovim#38702). Reproducibility from `install.sh` is this
project's hardest constraint, and an unreliable lockfile attacks it directly.

lazy.nvim's `lazy-lock.json` + `:Lazy restore` pins another machine to exact
revisions (lazy.folke.io/usage/lockfile). `lazy-lock.json` gets committed.

**Revisit when `vim.pack` leaves experimental** — the first-party answer is the
better one the moment its lockfile is trustworthy.

## Plugin slate (operator-decided 2026-08-20)

Scope chosen: **full IDE, vscodium stays installed.** Two editors, picked per
task. No retirement gate to build.

| Role | Choice |
|---|---|
| plugin manager | lazy.nvim (`lazy-lock.json` committed) |
| LSP | core `vim.lsp.config()`/`vim.lsp.enable()`; nvim-lspconfig for server definitions only |
| completion | blink.cmp |
| treesitter | nvim-treesitter, `main` branch (0.12+) |
| fuzzy find | telescope.nvim |
| file tree | neo-tree.nvim |
| git | gitsigns.nvim |
| statusline | lualine.nvim |
| format/lint | conform.nvim |
| colorscheme | hand-written Lua, in-repo, derives ramp from the matugen palette table |

**Known cost of this slate:** telescope, lualine, neo-tree and blink are the
four heaviest options on theming — each brings its own highlight groups, so
that is four new sets of colours to hold in parity across 20 palettes. lualine
also sits directly above the zellij bar, putting two bars in one terminal.
Accepted deliberately in exchange for a vscodium-like feel.

## How the config should be written (operator instruction, 2026-08-20)

- Follow mainstream nvim practice; take inspiration from the popular
  community configs rather than inventing structure.
- **Separate modules into folders** — not one monolithic init.lua.
- **Lazy-load plugins** properly (event/ft/cmd/key triggers).
- **Short, concise, human-readable comments throughout**, so the operator can
  follow the config and add their own plugins later.
- **No AI-flavoured or GSD-flavoured jargon in the config files.** No plan IDs,
  no requirement codes, no workflow vocabulary. These are dotfiles a human
  reads, not planning artifacts.

## Also in scope for the build

- Fix the broken `vim` alias in both shells (see the separate todo).
- Set `EDITOR`/`VISUAL`.
- `contract.json` entry + theme-parity coverage for the nvim palette file.
- A `reload.sh` fan-out entry for live re-theming.
- `install.sh`: pacman `neovim`, plus a headless plugin restore.

## Blocking unknown

The live-reload path is **not settled** and blocks planning — see the spike
todo. If re-running `:colorscheme` leaves treesitter or `@lsp.*` groups stale,
the "live re-theme" premise collapses and this design changes shape.

## Researched claims — dispositions

**Admitted (primary-sourced):**

- `nvim --server <addr> --remote-send` / `--remote-expr` exist and work —
  neovim `runtime/doc/remote.txt`. The live-drive mechanism is real.
- `$NVIM_LISTEN_ADDRESS` is **deprecated**; use `--listen`/`serverstart()` to
  set and `v:servername` to read — neovim `runtime/doc/deprecated.txt`.
- lazy.nvim writes `lazy-lock.json`; `:Lazy restore` pins exact revisions —
  lazy.folke.io/usage/lockfile.
- nvim 0.12 ships `vim.pack` in core, experimental, lockfile
  `nvim-pack-lock.json` — neovim.io/doc/user/pack.
- `vim.pack.add` can drop lockfile entries on partial install failure —
  neovim/neovim#38702.
- LSP moved into core: `vim.lsp.config()`/`vim.lsp.enable()` replace
  `require('lspconfig').X.setup{}`; the old framework is deprecated with
  removal targeted for lspconfig v3.0 — nvim-lspconfig README.
- gitsigns.nvim, telescope.nvim, lualine.nvim, conform.nvim all actively
  maintained — respective repos.

**Corrected (a primary source disagreed with the common claim):**

- nvim-treesitter is **not archived**. It did a hard incompatible rewrite on
  `main` requiring nvim 0.12+, with `master` frozen for 0.11 —
  github.com/nvim-treesitter/nvim-treesitter. Secondary blog posts claiming
  archival are wrong.

**Unresolved — do not restate as fact:**

- Whether re-running `:colorscheme` fully repaints treesitter `@` and
  `@lsp.*` groups or leaves some stale — *non-authoritative source; only
  blog/gist material found*. This is the blocking unknown.
- nvim's default server socket path, and whether an external script can
  enumerate live sockets — *unverifiable; fetched docs did not state it*.
- The verbatim headless restore incantation
  (`nvim --headless "+Lazy! restore" +qa`) — *widely repeated in blogs, not
  confirmed in lazy.nvim's own docs*.
- Native `vim.lsp.completion`'s specific multi-source limitations —
  *non-authoritative source*.
- neo-tree / nvim-tree / oil.nvim maintenance status — *no repo-level
  archival check was performed*.
