---
created: 2026-08-20T15:40:00.000Z
title: SPIKE — can a running nvim be driven to fully repaint on theme switch?
area: theming
severity: blocking
files:
  - theme-engine/.config/theme-engine/lib/reload.sh
  - theme-engine/.config/theme-engine/contract.json
  - matugen/.config/matugen/config.toml
---

## Why this blocks planning

The whole "themed nvim" premise is that a theme switch re-colours a **running**
nvim with no restart — the project's core value, and the exact thing the zellij
bar task spent five fix commits earning.

Research could confirm the transport but **not** the repaint:

- **Admitted:** `nvim --server <addr> --remote-send` / `--remote-expr` exist and
  work (neovim `runtime/doc/remote.txt`). Driving a live instance externally is
  real.
- **Unresolved:** whether re-running `:colorscheme` fully clears and re-applies
  **treesitter (`@...`) and LSP semantic-token (`@lsp.*`) groups**, or leaves
  some stale. Only blog/gist material was found — no authoritative source.

If those groups go stale, a theme switch produces a *partially* recoloured
buffer, which is worse than not live-reloading at all. The design changes shape
in that case, so this must be answered before anything is planned.

## What to measure

nvim is not installed yet, so this spike starts by installing it
(`pacman -S neovim`, 0.12.4-1 in `extra`).

1. **Socket enumeration.** Where does nvim put its server socket by default,
   and can an external script discover every live instance? Note
   `$NVIM_LISTEN_ADDRESS` is deprecated — `--listen`/`serverstart()` to set,
   `v:servername` to read (neovim `runtime/doc/deprecated.txt`). Decide whether
   the config should call `serverstart()` at a predictable path rather than
   relying on a default.

2. **The repaint itself.** Open a real nvim on a file with treesitter active
   *and* an attached LSP. From outside the process, drive a colorscheme change.
   Then check whether these actually changed:
   - plain syntax groups (`Normal`, `Comment`, `String`, `Function`)
   - treesitter groups (`@keyword`, `@function`, `@variable`, `@type`)
   - LSP semantic tokens (`@lsp.type.*`, `@lsp.mod.*`)

   Read the resolved values back (`nvim_get_hl`) rather than judging by eye —
   and confirm the probe itself can see a change it *should* see before
   trusting a "no change" result.

3. **If groups do go stale**, test whether an explicit clear-then-reapply, or a
   `ColorScheme` autocmd that re-patches after the scheme loads, fixes it.

## Calibrate the probe first

A probe that returns "nothing changed" may be blind rather than correct. Prove
it can detect a change you deliberately cause before believing a negative
result. This repo has been burned twice by uncalibrated probes — `dump-screen`
returning 1 byte for *any* zellij plugin pane, and a shell-quoted glyph
grepping to a false zero.

## Do not use qml6-style throwaway GUI probes

Spawning repeated GUI probe processes has taken this session's compositor down
before. nvim in a terminal is fine; do not build a loop that opens windows.

## Done when

The answer to "does a live nvim fully repaint from an external signal, yes or
no" is written down with the measurement that produced it — and if the answer
is no, the working alternative is written down too.

Run it with `/gsd-spike`.
