# Spike Conventions

Patterns established across spike sessions. New spikes follow these unless the
question requires otherwise.

## Stack

This is a dotfiles repo — no package.json, no build step. Spikes use what the
real surfaces use:

- **Lua run through `nvim -l script.lua`** for anything measuring nvim. Headless,
  no window, exits cleanly.
- **bash** for orchestration and anything involving processes or sockets.
  Always `#!/usr/bin/env bash` in a file, never typed into the interactive shell
  (see *Probe hygiene*).
- **python3** for analysing results. Reads the JSON the probe wrote and prints a
  table.
- **A plain HTML file** when the finding needs to be *seen*, published as an
  Artifact. No framework, no CDN.

## Structure

```
.planning/spikes/NNN-descriptive-name/
  README.md          frontmatter, research, investigation trail, results
  <probe>.lua|.sh    the measurement, one file per question
  results*.json      raw output, committed -- it is the evidence
  preview.html       only when there is something to look at
```

Probes write JSON next to themselves; analysis is a separate step. Keeping them
apart means a re-analysis never needs a re-run.

## Patterns

**Every probe gets a positive control.** A probe returning "nothing changed" may
be blind rather than correct. Prove it can see a change you deliberately caused
before believing a negative. Spike 001 asserts `Normal` moved before trusting any
"stale" result; spike 002 asserts `--remote-expr '1+1'` returns `2` and aborts if
not. This has already caught two false negatives in one session.

**Calibrate thresholds against something known-good.** A pass mark invented from
intuition can be true, measured and meaningless. Spike 003's separation bar came
from measuring a hand-tuned scheme (gruvbox's tightest pair scores 87) after an
invented bar of 40 passed palettes that were not legible.

**Report what was achieved, not what was hoped.** Repair and retry loops stop
honestly and let the checker report the real number. A spike that says
"VALIDATED, it works" with no nuance is incomplete.

**Follow the surprise.** Every one of these spikes changed shape after its first
result. Budget for the second and third iteration.

## Probe hygiene

Learned the hard way in this repo:

- **Never use `ls` to capture a path.** It is aliased to long colourised output
  in the interactive shell, and the ANSI escapes silently corrupt the value.
  Use `find`. This cost a full false-negative run in spike 002.
- **Never spawn GUI probe processes.** `qml6` probe scripts and repeated `grim`
  captures have taken this compositor down. Terminal-only, headless-only.
- **Headless nvim has no UI**, so `&termguicolors` is 0 and
  `synIDattr(...,'fg#')` returns empty. Read colours with `nvim_get_hl` through
  `luaeval`, which is UI-independent.
- **Detach background processes properly** with `setsid nohup ... &`, or they die
  with the tool call that started them.

## Tools & Libraries

| Thing | Version | Note |
|---|---|---|
| neovim | 0.12.4-1 (Arch `extra`) | `nvim -l` runs a Lua script headless |
| clangd | installed | real LSP semantic tokens, no extra install needed |
| treesitter `c`/`lua` parsers | bundled with nvim | `/usr/share/nvim/runtime/parser/` |

`clangd` plus the bundled `c` parser means a single C file exercises treesitter
and LSP semantic tokens together — the cheapest way to test highlight behaviour
properly.
