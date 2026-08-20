---
created: 2026-08-20T15:40:00.000Z
title: `vim` is broken on this host — aliased to a binary that isn't installed
area: shell
severity: major
files:
  - zshell/.zshrc
  - fish/.config/fish/config.fish
---

## Problem

Both shells alias `vim` to `nvim`, and `nvim` is not installed. Typing `vim`
gets `command not found`.

Measured on this host 2026-08-20:

- `zshell/.zshrc:80` — `alias vim='nvim'`
- `fish/.config/fish/config.fish:206` — `alias vim nvim`
- `command -v nvim` → absent; `pacman -Q neovim` → not found
- `pacman -Q vim` → **`vim 9.2.0849-1` is installed** — a working vim exists on
  this machine, it is just shadowed by the alias

Both files are stowed, so the live `~/.zshrc` and `~/.config/fish/config.fish`
carry the same broken alias. This ships to any fresh install too.

`EDITOR` and `VISUAL` are also both unset, so anything that shells out to an
editor (git commit, `sudoedit`, etc.) falls back to whatever default it
compiles in rather than a chosen editor.

## Solution

Two ways, depending on timing:

1. **If the themed-nvim work lands first** — install `neovim` as part of it and
   the alias becomes correct on its own. Set `EDITOR`/`VISUAL` to `nvim` in the
   same change.

2. **If fixing this standalone first** — either point the alias at the vim that
   is actually installed, or drop the alias and set `EDITOR`/`VISUAL` to `vim`
   until nvim arrives.

Do not leave it aliased to a missing binary either way.

## Note

This is independent of the themed-nvim project and fixable in minutes. It was
found while measuring the ground state for that work, not as part of it.

## Resolution (2026-08-20)

Resolved by the themed-nvim work (quick tasks 260820-nua + 260820-r44) via
solution path 1: `neovim 0.12.4-1` is installed (`command -v nvim` →
`/usr/bin/nvim`), so both aliases now point at a real binary, and
`EDITOR`/`VISUAL` are exported as `nvim` in both shells
(`zshell/.zshrc:100-101`, `fish/.config/fish/config.fish:172-173`) and
confirmed set in the live environment.
