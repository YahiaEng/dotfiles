---
spike: 001
idea: themed-nvim
name: highlight-repaint-completeness
type: standard
validates: "Given nvim with treesitter active and an LSP attached, when the colorscheme is re-applied, then plain, treesitter and @lsp.* groups all repaint with none left stale"
verdict: VALIDATED
related: []
tags: [nvim, theming, highlight, treesitter, lsp, live-reload]
---

# Spike 001: Highlight Repaint Completeness

## What This Validates

**Given** nvim with treesitter active and a real LSP attached to a buffer,
**when** the colorscheme is re-applied,
**then** plain groups, treesitter `@...` groups and LSP `@lsp.*` semantic-token
groups all take the new colours, with none left holding the old ones.

This was the blocking unknown for the whole themed-nvim design. Research could
confirm the transport (`--remote-send` exists) but found no authoritative source
on the repaint semantics — only blog/gist material.

## Research

Carried in from the exploration research pass (2026-08-20):

- **Admitted:** `nvim --server <addr> --remote-send` / `--remote-expr` exist and
  work — neovim `runtime/doc/remote.txt`.
- **Unresolved, and the reason this spike exists:** whether `:colorscheme` fully
  clears and re-applies treesitter and `@lsp.*` groups. *Non-authoritative
  source — only blog/gist material found.*

No further doc research was needed. The question is directly measurable on this
host now that nvim is installed.

## Environment

Measured, not assumed:

- `neovim 0.12.4-1` (Arch `extra`), `NVIM v0.12.4`, LuaJIT 2.1.1785763465
- `clangd` **already installed** — gives real LSP semantic tokens with no extra
  install
- `c.so` treesitter parser **ships bundled** with nvim
  (`/usr/share/nvim/runtime/parser/c.so`) along with its highlight queries

A single C file therefore exercises treesitter and LSP semantic tokens together.

## How to Run

```
nvim -l probe.lua          # two-scheme test  -> results.json
nvim -l probe-live.lua     # same-name reload -> results-live.json
nvim -l probe-render.lua   # render binding   -> results-render.json
```

Each writes JSON next to itself. All three run headless; none opens a window.

## Probe Calibration

`probe.lua` asserts that `Normal` changed in **both** transitions before any
"stale" result is trusted. A probe that reports "nothing changed" may be blind
rather than correct.

Result: `probe_trustworthy: true` — `normal_moved_naive: true`,
`normal_moved_cleared: true`. The LSP half is separately controlled:
`lsp_attached: true` and `tokens_seen: true`, so the `@lsp.*` findings describe
a buffer that genuinely had semantic tokens on it.

## Investigation Trail

**1. Two schemes, one clearing and one not.** Scheme A defines plain,
treesitter and `@lsp.*` groups. Scheme B redefines plain + treesitter only, and
exists in two variants: one that calls `highlight clear` first and one that
does not.

Result — `A -> B (no clear)`:

```
MOVED   Normal, Comment, String, @keyword, @function, @type
STALE   @lsp.mod.readonly     #0000ff
        @lsp.type.function    #00ff00
        @lsp.type.variable    #00cccc
```

Result — `A -> B (highlight clear)`: **zero stale groups.**

Staleness is real, and `highlight clear` is a complete fix.

Note *why* treesitter groups did not go stale in the naive run: Scheme B
happened to redefine them explicitly. They are not immune — anything Scheme A
sets that Scheme B does not, and that is not cleared, persists.

The cleared run also shows the mechanism. `@lsp.type.function` landed on
`#aa66ff`, which is `@function`'s **new** colour. These groups default-*link* to
treesitter groups; setting one explicitly converts it into a concrete definition
that outlives the next scheme load until something clears it.

**2. The production scenario — same scheme name, new palette.** The first test
used two different scheme names. A live re-theme does not: it re-applies *the
same* scheme with a rewritten palette file underneath. `:colorscheme` might
reasonably no-op when `g:colors_name` already matches.

`colors/spikelive.lua` reads `palette.lua` from disk and paints from it,
mirroring how the real scheme will read `~/.local/state/theme/nvim.lua`.

Result — palette v1 -> v2 via `:colorscheme spikelive` (same name):

```
MOVED   Normal  #aaaaaa/#111111 -> #dddddd/#222222
        Comment            #555555 -> #999999
        String             #ff0000 -> #00ccff
        @keyword           #ff0000 -> #00ccff
        @function          #aaaaaa -> #dddddd
        @lsp.type.function #ff0000 -> #00ccff
STALE   (none)
```

Result — v2 -> v3 via `:runtime colors/spikelive.lua`: identical, zero stale.

It does **not** short-circuit on a matching name, and both routes re-read the
file from disk.

**3. Do definitions changing actually change the render?** Group definitions
moving is not the same as the buffer looking different — this repo has shipped a
"verified" fix that checked the wrong axis before.

`vim.inspect_pos` plus a sweep of every extmark: **107 extmarks carry an
`hl_group`, and every one names a group rather than a resolved colour.**

```
@lsp.type.property.          @lsp.type.class.
@lsp.typemod.property.declaration.   @lsp.type.variable.
@lsp.mod.declaration.        @lsp.typemod.variable.readonly.
@lsp.typemod.property.classScope.    @lsp.mod.readonly.
@lsp.mod.classScope.         @lsp.type.function.
```

Because the binding is by name, redefining a group necessarily repaints
everything marked with it. No cached colours to go stale.

**Surprise worth carrying forward:** the groups on the extmarks are the
**client-suffixed** variants — note the trailing dot, `@lsp.type.function.` —
which default-link to the plain `@lsp.type.function`. A colorscheme should
define the **base** groups and let the links carry it. `highlight clear` is what
restores those default links after a scheme has overwritten them.

## Results

**VALIDATED — with one non-negotiable condition.**

A running nvim fully repaints on a live theme switch, including treesitter and
LSP semantic-token groups, **provided the colorscheme calls `highlight clear`
before painting.**

Established by measurement on this host:

1. Staleness is real. Without `highlight clear`, `@lsp.*` groups keep the
   previous scheme's colours.
2. `highlight clear` fixes it completely — zero stale groups in every run
   that used it.
3. Re-applying the **same** scheme name works and re-reads the palette from
   disk. `:colorscheme <name>` does not no-op on a matching `g:colors_name`.
   `:runtime colors/<name>.lua` works identically.
4. The render follows, because all 107 semantic-token extmarks bind by group
   name, not by resolved colour.
5. `@lsp.*` groups default-link to treesitter groups. Define the base groups;
   let the client-suffixed variants link.

**Impact on the design:** the live re-theme premise holds. The colorscheme this
repo writes must open with `highlight clear` — that single line is what stands
between a correct live re-theme and a half-recoloured buffer.

**Not tested here:** whether an *external* process can reach a running nvim to
trigger this. That is spike 002.
