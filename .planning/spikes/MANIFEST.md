# Spike Manifest

## Ideas

### themed-nvim

A full-IDE neovim wired into this repo's existing matugen/theme-engine pipeline,
so a theme switch re-colours a running nvim the way it already re-colours the
bar, terminal and everything else. vscodium stays installed alongside it — two
editors, chosen per task, no retirement gate. nvim is the first surface in this
repo that must generate real syntax colours across all 20 palettes, and the
first whose config language is a real programming language rather than a text
template. Exploration and constraints:
`.planning/notes/themed-nvim-design-constraints.md`.

**Requirements:**

- The colorscheme **must call `highlight clear` before painting** (spike 001).
  Without it, `@lsp.*` groups keep the previous theme's colours and a theme
  switch leaves a half-recoloured buffer.
- Define the **base** `@lsp.*` groups and let the client-suffixed variants
  (`@lsp.type.function.`) link to them — that is what the extmarks actually
  reference (spike 001).
- Colours must re-theme **live**, with no nvim restart — this is the project's
  core value, not a nice-to-have.
- The colorscheme reads its palette from a file the theme pipeline writes; it
  does not hardcode colours.
- Plugin manager is **lazy.nvim**, not the first-party `vim.pack` — a
  deliberate exception, because `vim.pack`'s lockfile can drop entries on
  partial install failure (neovim/neovim#38702) and reproducibility from
  `install.sh` is this project's hardest constraint. Revisit when `vim.pack`
  leaves experimental.
- `reload.sh` finds live instances by globbing `$XDG_RUNTIME_DIR/nvim.*` and
  drives each with `--remote-expr "execute('colorscheme <name>')"` (spike 002).
  No `--listen` flag and no `serverstart()` in the config — that path is the
  default. Tolerate a non-zero exit per socket: sockets from crashed instances
  linger but fail in ~4ms, so they cannot hang the switch.
- The colorscheme derives its syntax ramp **in Lua at load time** (spike 003).
  matugen writes only the ~9 role colours and never needs to know about syntax
  slots — templates cannot do colour math, Lua can.
- **Monochrome themes stay monochrome** (operator decision, 2026-08-20).
  Palettes with max role saturation < 0.20 are separated by brightness tiers
  plus **bold/italic**, never by injected hue — forcing saturation into
  vantablack would destroy the reason someone picks it. Every slot gets a
  unique (tier, attribute) pair, and slots sharing an attribute sit at least a
  tier apart.
- Comments render **italic** in every palette, by convention.
- Any colour-separation threshold must be **calibrated against a real scheme**,
  never guessed (spike 003). The bar of 70 comes from gruvbox's tightest real
  pair scoring 87; an earlier invented bar of 40 passed palettes that were not
  actually legible.
- Config style: modular folders, real lazy-loading, short plain-English
  comments. No plan IDs, requirement codes or workflow jargon in config files —
  the operator reads and extends these by hand.

## Spikes

| # | Idea | Name | Type | Validates | Verdict | Tags |
|---|------|------|------|-----------|---------|------|
| 001 | themed-nvim | highlight-repaint-completeness | standard | Re-applying a colorscheme repaints plain, treesitter and `@lsp.*` groups with none stale | ✓ VALIDATED (requires `highlight clear`) | nvim, theming, highlight, treesitter, lsp, live-reload |
| 002 | themed-nvim | external-drive-and-socket | standard | An external script can find a running nvim and make it re-apply its colorscheme | ✓ VALIDATED | nvim, ipc, socket, reload |
| 003 | themed-nvim | lua-ramp-from-four-hues | standard | Lua can derive 8+ distinguishable syntax colours from the 9-role matugen palette | ✓ VALIDATED (19/20; nord soft) | nvim, theming, palette, colour, contrast |
