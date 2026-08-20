---
phase: quick-260820-nua
plan: 01
subsystem: editor
tags: [neovim, lazy.nvim, treesitter, lsp, blink.cmp, matugen, theme-engine, lua]

requires:
  - phase: 22 (fresh-install-proof)
    provides: the matugen/theme-engine pipeline this plugs into (contract.json, reload.sh, stow.sh conventions)
provides:
  - a full-IDE nvim/ stow package with modular Lua config and a repo-owned colorscheme
  - the 22nd theme-engine contract file (nvim.lua), a matugen template, and a reload.sh fan-out entry
  - install.sh/stow.sh wiring so the whole editor reproduces from one script
  - EDITOR/VISUAL fixed in both shells
affects: [any future phase touching the theme-engine contract, matugen templates, or stow.sh PACKAGES]

actuals:
  tokens: 16646
  tasks: 7
  commits: 7

tech-stack:
  added: [neovim 0.12.4, lazy.nvim, nvim-lspconfig, blink.cmp v1, nvim-treesitter (main), telescope.nvim, neo-tree.nvim, gitsigns.nvim, lualine.nvim, conform.nvim, lua-language-server, tree-sitter-cli]
  patterns:
    - "matugen renders ROLE colours only into a Lua table; the consumer derives its own syntax ramp at load time (first surface in this repo where a template's consumer does colour math, rather than the template itself)"
    - "live re-theme of a running terminal-UI process via nvim --server --remote-expr, the same reload.sh fan-out shape as the kitty/hyprctl entries"
    - "measure-before-build: three of five plugin decisions (treesitter lazy-loading, lualine's theme='auto' follow behaviour, the lazy-lock.json symlink question) were settled by reading source/running a live probe rather than assumed from the plan text"

key-files:
  created:
    - nvim/.config/nvim/init.lua
    - nvim/.config/nvim/colors/rice.lua
    - nvim/.config/nvim/lua/theme/palette.lua
    - nvim/.config/nvim/lua/theme/ramp.lua
    - nvim/.config/nvim/lua/config/{options,keymaps,autocmds,lazy}.lua
    - nvim/.config/nvim/lua/plugins/{lsp,completion,treesitter,telescope,neo-tree,gitsigns,lualine,format,init}.lua
    - nvim/.config/nvim/lazy-lock.json
    - matugen/.config/matugen/templates/nvim-palette.lua
  modified:
    - matugen/.config/matugen/config.toml
    - theme-engine/.config/theme-engine/contract.json
    - theme-engine/.config/theme-engine/lib/reload.sh
    - stow.sh
    - install.sh
    - hypr/.config/hypr/scripts/stow-link-check
    - zshell/.zshrc
    - fish/.config/fish/config.fish

key-decisions:
  - "nvim-treesitter set lazy=false (not event-triggered) — its own current docs explicitly say it does not support lazy-loading; per-buffer highlighting is still lazy in effect via a FileType autocmd"
  - "lualine's theme='auto' needed no re-theme wiring — reading its installed source showed it already registers its own ColorScheme autocommand that re-runs setup(); confirmed live before believing it, per this repo's own measure-don't-guess convention"
  - "lazy-lock.json kept at its default location — measured that the stow symlink survives a real lockfile write (:Lazy update rewrote content straight through the symlink into the repo, confirmed by diff)"
  - "jsonc has no grammar of its own on nvim-treesitter's main branch — registered onto the json parser instead of listing a non-existent language"
  - "@lsp.type.* base groups are set directly rather than linked to their legacy-group equivalents, since nvim_get_hl returns an unresolved {link=...} table by default"

requirements-completed: [SPIKE-001, SPIKE-002, SPIKE-003, MAN-01, MAN-02, MAN-03, MAN-04, MAN-05, MAN-06, MAN-07, MAN-08, MAN-09, MAN-10, STYLE-01, STYLE-02, STYLE-03, STYLE-04]

coverage:
  - id: D1
    description: "Live re-theme: a theme switch re-colours an already-running nvim (buffer, statusline, treesitter, LSP semantic tokens) with no restart"
    requirement: "MAN-03/MAN-06"
    verification:
      - kind: integration
        ref: "scratchpad probe-live-retheme.sh — headless nvim driven externally via --remote-expr, Normal.fg measured 13489908 -> 15527924 across a theme switch, positive control passed first"
        status: pass
      - kind: integration
        ref: "scratchpad probe-lualine-retheme.sh — lualine_a_normal.bg measured 4935267 -> 4212826 across a theme switch"
        status: pass
    human_judgment: false
  - id: D2
    description: "Syntax ramp derived in Lua from role colours, 19/20 palettes clearing separation 70, monochrome palettes stay monochrome, comments italic everywhere"
    requirement: "MAN-07/MAN-08/MAN-09/MAN-10"
    verification:
      - kind: unit
        ref: "scratchpad check-ramp.lua — 19/20 pass, nord at 60.2 (the documented known exception, unregressed from its measured 60)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Full IDE: LSP attaches, treesitter highlights, completion/fuzzy-find/file-tree/git-signs/statusline/format-on-save all present, plugins lazy-triggered"
    requirement: "MAN-05"
    verification:
      - kind: integration
        ref: "nvim --headless +edit init.lua, LSP client attach + treesitter highlighter assertions — pass; lazy stats 2/12 loaded at startup"
        status: pass
    human_judgment: false
  - id: D4
    description: "Whole editor reproduces from install.sh + stow.sh with plugins pinned to the committed lockfile"
    requirement: "MAN-01..10 (reproducibility invariant)"
    verification:
      - kind: integration
        ref: "wiped ~/.local/share/nvim/lazy entirely, ran the two-step nvim --headless \"+Lazy! install\" \"+Lazy! restore\" +qa, diffed every plugin's resolved HEAD before/after — 11/11 plugin commits identical (lazy.nvim's own self-managed bootstrap commit is the one line that legitimately differs, since the lockfile does not pin it)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Visual/interactive confirmation: syntax colours look right in a real terminal, monochrome and light palettes read correctly, the plugin slate works end to end, zellij autolock triggers on nvim focus"
    verification: []
    human_judgment: true
    rationale: "Requires a real kitty window and human eyes — this host's agent shell misreports the terminal (cannot be probed from here) and a single grim/screenshot capture has previously SIGSEGV'd this host's compositor into safe mode. This is Task 8 of the plan, a gate=\"blocking-human\" checkpoint that cannot be auto-approved even under an active auto-mode policy (none is active in this session). Not yet performed."

duration: 45min
completed: 2026-08-20
status: complete
---

# Quick Task 260820-nua: Themed Neovim Summary

**A full-IDE nvim (lazy.nvim, LSP, blink.cmp, treesitter, telescope, neo-tree, gitsigns, lualine, conform) whose ten-slot syntax ramp is derived in Lua from twelve matugen role colours at load time, re-theming a running instance live with no restart.**

## Performance

- **Duration:** ~45 min
- **Started:** 2026-08-20T17:26:00+03:00 (approx, first Read call)
- **Completed:** 2026-08-20T17:57:25+03:00
- **Tasks:** 7 of 8 code/gate tasks complete; Task 8 (operator checkpoint) pending
- **Files modified:** 27

## Accomplishments

- End-to-end colour path: matugen template -> `~/.local/state/theme/nvim.lua` (22nd contract file) -> `theme/palette.lua` (uncached re-read) -> `colors/rice.lua` (`highlight clear` then paint) -> `reload.sh` fan-out via `nvim --server --remote-expr`. Measured live: a headless instance's `Normal` foreground moved when driven externally, with no restart, positive control passed first.
- Ten-slot syntax ramp ported verbatim from the validated spike and wired into a full highlight set: editor chrome, legacy syntax groups, treesitter captures, base `@lsp.*` semantic-token groups, diagnostics, diff, spell. 19/20 palettes clear the calibrated separation-70 bar; `nord` sits at its documented 60 (unregressed); monochrome palettes stay monochrome via brightness tier + bold/italic; comments are italic everywhere.
- Modular editor skeleton (`init.lua` + `config/{options,keymaps,autocmds,lazy}.lua`) and nine lazy-triggered plugins covering LSP, completion, treesitter, fuzzy-find, file tree, git signs, statusline and format-on-save — every plugin API shape fetched from its own current docs at write time, not written from memory.
- Whole editor reproduces from `install.sh` + `stow.sh`: `neovim`/`tree-sitter-cli`/`lua-language-server` pacman packages, a headless two-step plugin restore (`install` then `restore` — the single-command form the plan flagged as unverified blog material turned out to be genuinely incomplete for a from-scratch machine), and `lazy-lock.json` committed and confirmed to survive being written-through its stow symlink.
- `vim`/`$EDITOR`/`$VISUAL` fixed in both shells; `stow-link-check` covers the new tree.

## Task Commits

Each task was committed atomically:

1. **Task 1: End-to-end colour path** - `e7ef4ba` (feat)
2. **Task 2: Port the ramp and paint the full highlight set** - `e48d030` (feat)
3. **Task 3: Editor skeleton** - `fa832b2` (feat)
4. **Task 4: LSP, completion and treesitter** - `ebf7c8d` (feat)
5. **Task 5: Telescope, neo-tree, gitsigns, lualine, conform** - `a907e43` (feat)
6. **Task 6: Reproducibility — install.sh, stow bootstrap, link coverage, shells** - `ba5347f` (feat)
7. **Task 7: Gate sweep, 20-palette parity, no-jargon check** - `a29da80` (fix — the sweep itself found and fixed two leftover jargon references)

**Plan metadata:** not committed by this executor — orchestrator commits `.planning/` docs artifacts separately, per this quick task's own protocol.

## Files Created/Modified

- `matugen/.config/matugen/templates/nvim-palette.lua` - 12-role Lua table template, roles only, no syntax slots
- `matugen/.config/matugen/config.toml` - `[templates.nvim]` entry
- `theme-engine/.config/theme-engine/contract.json` - 22nd entry, `nvim.lua`/`lua-table` (reused the existing extractor)
- `theme-engine/.config/theme-engine/lib/reload.sh` - nvim fan-out block, timeout-bounded + `|| true`-guarded
- `nvim/.config/nvim/init.lua` - five-line entry point
- `nvim/.config/nvim/colors/rice.lua` - the colorscheme: luminance-derived background, `highlight clear`, full highlight set from the ramp
- `nvim/.config/nvim/lua/theme/palette.lua` - uncached state-file reader with a catppuccin fallback
- `nvim/.config/nvim/lua/theme/ramp.lua` - the ported ten-slot ramp (spike code, unmodified maths)
- `nvim/.config/nvim/lua/config/{options,keymaps,autocmds,lazy}.lua` - sane defaults, non-plugin keymaps, small autocmds, lazy.nvim bootstrap
- `nvim/.config/nvim/lua/plugins/{lsp,completion,treesitter,telescope,neo-tree,gitsigns,lualine,format,init}.lua` - the nine-plugin slate
- `nvim/.config/nvim/lazy-lock.json` - committed, pinned revisions
- `stow.sh` - `nvim` package + pre-create guard + headless plugin restore
- `install.sh` - `neovim`, `tree-sitter-cli`, `lua-language-server` in `PACMAN_PKGS`
- `hypr/.config/hypr/scripts/stow-link-check` - `'nvim'` added to `OWNED_CONFIG_TOP`
- `zshell/.zshrc` - `EDITOR`/`VISUAL` exports
- `fish/.config/fish/config.fish` - `EDITOR`/`VISUAL` exports (unconditional, outside the interactive-only block)

## Decisions Made

- **Treesitter lazy-loading dropped, not built:** the plan asked for an event-triggered spec, but nvim-treesitter's own current README is explicit that the `main` branch does not support lazy-loading. Set `lazy = false` per its own recommendation; per-buffer highlighting stays effectively lazy via a `FileType` autocmd. Documented in a comment so nobody "fixes" it back to an event trigger later.
- **lualine's live re-theme needed nothing built:** read the installed plugin's own source (`setup_theme()` in `lualine.lua`) before writing a fix — it already registers its own `ColorScheme`/`OptionSet background` autocommand. Confirmed live (statusline colour moved with no extra code), then shipped the simplest possible spec instead of the originally-planned manual re-setup autocmd.
- **jsonc has no grammar on nvim-treesitter's `main` branch:** registered the filetype onto the `json` parser (`vim.treesitter.language.register`) instead of listing a language name that does not exist there.
- **`@lsp.type.*` set directly, not linked:** `nvim_get_hl` returns an unresolved `{link=...}` table by default; a semantic-token consumer (or this task's own automated verify) should not have to ask for `link=false` to see a real colour.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] lua-language-server was not installed on this host**
- **Found during:** Task 4 (LSP verification — the LSP-attach assertion failed after 8s with no error, because `lua_ls`'s binary simply did not exist)
- **Issue:** The plan enables `lua_ls` in `lua/plugins/lsp.lua` but nothing in the plan or `install.sh` provides its binary. Without it, LSP silently never attaches to a Lua buffer on a fresh install — most of this config's own source tree is Lua.
- **Fix:** Verified `lua-language-server` directly against this host's pacman database (`pacman -Si`, official `extra` repo, not AUR) before installing, matching the plan's own measured-fact precedent for `tree-sitter-cli`. Installed it, then added it to `install.sh`'s `PACMAN_PKGS` in Task 6 alongside the two planned entries.
- **Files modified:** `install.sh`
- **Verification:** LSP client attaches to a Lua buffer within 8s; `checkhealth vim.lsp` clean.
- **Committed in:** `ba5347f` (Task 6 commit)

**2. [Rule 1 - Bug] `jsonc` listed as a treesitter language, but no such grammar exists on `main`**
- **Found during:** Task 4 (`Lazy! sync` logged `warning: skipping unsupported language: jsonc`)
- **Issue:** The plan's language list named `jsonc` directly; nvim-treesitter's `main` branch has no grammar under that name (confirmed against its own `SUPPORTED_LANGUAGES.md`).
- **Fix:** Removed `jsonc` from the install list, added `vim.treesitter.language.register("json", "jsonc")` so the filetype uses the `json` parser instead.
- **Files modified:** `nvim/.config/nvim/lua/plugins/treesitter.lua`
- **Verification:** `Lazy! sync` runs with no unsupported-language warning; a `.jsonc` buffer highlights.
- **Committed in:** `ebf7c8d` (Task 4 commit)

**3. [Rule 1 - Bug] `@lsp.type.function`'s automated verify failed against a `link`-based definition**
- **Found during:** Task 2 (the plan's own verify: `nvim_get_hl(0,{name="@lsp.type.function"}).fg` was `nil`)
- **Issue:** `link("@lsp.type.function", "Function")` is a correct definition, but `nvim_get_hl` returns an unresolved `{link=...}` table by default — `.fg` is only populated with `link=false` in the call, which the verify script does not pass.
- **Fix:** Set every `@lsp.type.*` base group directly with `hi(slot(...))` instead of `link(...)`, so a plain `nvim_get_hl(0,{name=...})` call resolves a real colour without extra arguments.
- **Files modified:** `nvim/.config/nvim/colors/rice.lua`
- **Verification:** the plan's own exact verify snippet passes across catppuccin/vantablack/matte-black/nord/rosepine-dawn/gruvbox-light.
- **Committed in:** `e48d030` (Task 2 commit)

**4. [Rule 1 - Bug] Two leftover jargon references survived the plan's own grep pattern**
- **Found during:** Task 7 (a broader manual sweep beyond the plan's literal regex, run because the plan's own comment says the pattern is deliberately hidden from the executor "so this plan's own prose can never leak into a config file and then satisfy its own check" — worth checking beyond the letter of that pattern)
- **Issue:** `colors/rice.lua`'s header carried a bare `SPIKE-001` reference and two `.planning/spikes/...` path references — planning-artifact vocabulary in a file the operator reads and extends by hand.
- **Fix:** Rewrote both comments to describe the measured findings in plain English with no path or ID references.
- **Files modified:** `nvim/.config/nvim/colors/rice.lua`
- **Verification:** both the plan's exact grep and a broader manual sweep (`260820|nua\b|MAN-[0-9]|STYLE-[0-9]|planning|workflow|gsd-|plan\.md|checkpoint|deviation`) now return zero matches.
- **Committed in:** `a29da80` (Task 7 commit)

---

**Total deviations:** 4 auto-fixed (1 missing-critical, 3 bugs)
**Impact on plan:** All four were required for the plan's own stated must-haves (a working IDE, correct treesitter/LSP behaviour, and zero-jargon dotfiles) to actually hold. No scope creep beyond what those must-haves already demanded.

## Issues Encountered

None beyond the four deviations above — each was found by the plan's own verify steps or a deliberately broader sweep, not by an unrelated failure.

## Operator Checkpoint (Task 8 — not yet performed)

Everything machine-checkable is done and green. What remains is Task 8 of the plan: a `gate="blocking-human"` checkpoint that genuinely needs a human looking at a real kitty window — this host's agent shell misreports the terminal, and a screenshot capture has previously taken this compositor down, so it cannot be verified from here. No auto-mode policy is active in this session, so it was not auto-approved.

Everything is already deployed: `./stow.sh` has been run (idempotent, confirmed with a second run producing no diff), plugins are restored, and the catppuccin theme is applied. There is nothing to install or start.

To close this out:

1. Open `nvim` on a real source file in a real kitty window — one of this repo's own `.lua` files, or a C file to exercise `clangd`. Confirm syntax colours look right and comments render italic.
2. With that `nvim` still open, switch themes (Super+Shift+T). Confirm the buffer re-colours immediately, statusline/line-numbers/git-signs/completion popup included, with no restart and nothing left in the old palette.
3. Switch to a monochrome palette (`vantablack` or `matte-black`). Confirm it stays genuinely black-and-white, tokens told apart by weight/slant rather than an injected colour.
4. Switch to a light palette (`catppuccin-latte`, `rosepine-dawn` or `gruvbox-light`). Confirm it reads as a light theme, not a dark theme on a light background.
5. Exercise the slate: find-files, live grep, the file tree, a hunk stage, a format-on-save, completion in insert mode.
6. Confirm zellij's autolock locks when nvim takes focus — the one item the multiplexer work never got to test, since nvim did not exist yet at that point. No config change needed; it only needed nvim installed.

If all six pass, this quick task is fully done. If anything looks wrong, it lands as a follow-up commit under this same task.

## Next Phase Readiness

- nvim is a fully wired themed surface; any future phase touching the theme-engine contract or matugen templates now has a 22nd file and a working `lua-table` precedent to follow (the second, after `hyprland-tokens.lua`).
- `stow.sh`'s headless-restore pattern (guarded on a binary, timeout-bounded, non-fatal, positioned after the first-boot seed) is now precedent for any future plugin-manager-backed surface this repo adds.
- No blockers for other work. The only open item is the Task 8 operator checkpoint above, tracked in `.planning/WINDOWS.md` as an `unrun-verify` entry so it stays visible at ship time.

---
*Phase: quick-260820-nua*
*Completed: 2026-08-20*

## Self-Check: PASSED

All 18 files listed under Files Created/Modified plus this SUMMARY.md were confirmed present on disk. All 7 task commit hashes (`e7ef4ba`, `e48d030`, `fa832b2`, `ebf7c8d`, `a907e43`, `ba5347f`, `a29da80`) were confirmed present in `git log --all`.
