---
phase: quick-260820-nua
plan: 01
type: execute
wave: 1
depends_on: []
autonomous: false
requirements: [SPIKE-001, SPIKE-002, SPIKE-003, MAN-01, MAN-02, MAN-03, MAN-04, MAN-05, MAN-06, MAN-07, MAN-08, MAN-09, MAN-10, STYLE-01, STYLE-02, STYLE-03, STYLE-04]

files_modified:
  - nvim/.config/nvim/init.lua
  - nvim/.config/nvim/colors/rice.lua
  - nvim/.config/nvim/lua/theme/palette.lua
  - nvim/.config/nvim/lua/theme/ramp.lua
  - nvim/.config/nvim/lua/config/options.lua
  - nvim/.config/nvim/lua/config/keymaps.lua
  - nvim/.config/nvim/lua/config/autocmds.lua
  - nvim/.config/nvim/lua/config/lazy.lua
  - nvim/.config/nvim/lua/plugins/lsp.lua
  - nvim/.config/nvim/lua/plugins/completion.lua
  - nvim/.config/nvim/lua/plugins/treesitter.lua
  - nvim/.config/nvim/lua/plugins/telescope.lua
  - nvim/.config/nvim/lua/plugins/neo-tree.lua
  - nvim/.config/nvim/lua/plugins/gitsigns.lua
  - nvim/.config/nvim/lua/plugins/lualine.lua
  - nvim/.config/nvim/lua/plugins/format.lua
  - nvim/.config/nvim/lazy-lock.json
  - matugen/.config/matugen/templates/nvim-palette.lua
  - matugen/.config/matugen/config.toml
  - theme-engine/.config/theme-engine/contract.json
  - theme-engine/.config/theme-engine/lib/reload.sh
  - hypr/.config/hypr/scripts/stow-link-check
  - stow.sh
  - install.sh
  - zshell/.zshrc
  - fish/.config/fish/config.fish

estimate:
  tokens: 210000
  raw_tokens: 210000
  tasks: 8
  confidence: low

must_haves:
  truths:
    - "Typing `nvim` opens a working IDE — LSP, completion, treesitter highlighting, fuzzy find, file tree, git signs, statusline and format-on-save all present."
    - "Switching themes re-colours an ALREADY-RUNNING nvim with no restart and no manual action, syntax colours included (SPIKE-001 + SPIKE-002)."
    - "The colorscheme derives ten distinguishable syntax slots in Lua from the role colours matugen writes — matugen never learns what a syntax slot is (SPIKE-003)."
    - "Monochrome palettes (vantablack, matte-black) stay monochrome: tokens separate by brightness tier plus bold/italic, never by injected hue."
    - "Comments render italic in every one of the 20 palettes."
    - "nvim is usable on a machine where the theme engine has never run — the colorscheme falls back rather than erroring."
    - "A fresh machine reproduces the whole editor from install.sh + stow.sh, with plugins pinned to the committed lockfile."
    - "`vim` resolves to a real binary in both zsh and fish, and EDITOR/VISUAL are set in both."
    - "theme-doctor, theme-parity, colour-lint, motion-lint and stow-link-check all still pass, with nvim.lua covered as the 22nd contract file across all 20 palettes."
    - "No file under nvim/ contains planning, workflow or AI-assistant vocabulary — these read as hand-written dotfiles."
  artifacts:
    - "nvim/ stow package with a modular lua/ tree (config/, theme/, plugins/) and colors/rice.lua"
    - "matugen/.config/matugen/templates/nvim-palette.lua (role table, no syntax slots)"
    - "~/.local/state/theme/nvim.lua (rendered output, 22nd contract file, format lua-table)"
    - "config.toml [templates.nvim] entry"
    - "contract.json entry { name: nvim.lua, format: lua-table } — files array goes 21 -> 22"
    - "reload.sh fan-out block globbing $XDG_RUNTIME_DIR/nvim.*"
    - "nvim/.config/nvim/lua/theme/ramp.lua ported from .planning/spikes/003-lua-ramp-from-four-hues/ramp.lua"
    - "nvim/.config/nvim/lazy-lock.json committed"
    - "stow.sh: nvim in PACKAGES, mkdir -p ~/.config/nvim before the loop, headless plugin restore after the theme seed"
    - "install.sh: neovim + tree-sitter-cli in PACMAN_PKGS"
    - "stow-link-check OWNED_CONFIG_TOP gains 'nvim'"
    - "EDITOR/VISUAL exports in zshell/.zshrc and fish/.config/fish/config.fish"
  key_links:
    - "colors/rice.lua MUST call `highlight clear` before painting. MEASURED (SPIKE-001): without it, @lsp.* groups keep the previous theme's colours and a live switch leaves a half-recoloured buffer. This one line is the whole difference between a correct live re-theme and a broken one."
    - "The colorscheme MUST define the BASE @lsp.* groups (@lsp.type.function), not the client-suffixed variants (@lsp.type.function.). MEASURED (SPIKE-001): all 107 semantic-token extmarks carry the suffixed names, which default-link to the base ones — and `highlight clear` is what restores those default links."
    - "lua/theme/palette.lua MUST re-read the state file on EVERY call, never cache the roles at module level. `:colorscheme rice` re-executes colors/rice.lua from disk (SPIKE-001), but `require()` returns the cached module — a module-level palette table would freeze the colours at first load and the live re-theme would silently do nothing."
    - "output_path MUST be ~/.local/state/theme/nvim.lua. MEASURED IN CODE: commit.sh promotes ONLY $tmp$STATE_DIR via rsync, and both theme-doctor (theme-doctor:68) and theme-parity resolve every contract file under $STATE_DIR. A template writing anywhere else renders into a throwaway tmp tree and is silently discarded."
    - "reload.sh MUST tolerate a per-socket failure. MEASURED (SPIKE-002): a crashed instance leaves its socket behind and connecting to it exits 2 after ~4ms. This repo has a scar from a reload hook that blocked 45+ minutes on a dead endpoint, so the block is both `|| true`-guarded AND timeout-bounded."
    - "reload.sh MUST NOT add a --listen flag and the config MUST NOT call serverstart(). MEASURED (SPIKE-002): the DEFAULT socket path is already $XDG_RUNTIME_DIR/nvim.<pid>.<n> and a plain glob enumerates every live instance."
    - "The separation threshold is 70, calibrated against gruvbox's tightest real pair at 87 (SPIKE-003). An earlier invented bar of 40 passed palettes that were not legible. Do not lower it to make a palette pass."
    - "stow.sh's mkdir -p ~/.config/nvim MUST run BEFORE the PACKAGES loop — after it, stow has already folded the directory into the repo and anything nvim writes there lands in the git checkout."
    - "stow-link-check descends into ~/.config/<name> only for names in OWNED_CONFIG_TOP. Because ~/.config/nvim is pre-created as a real directory, the depth-1 pass never descends — without the OWNED_CONFIG_TOP entry the new package's per-file symlinks are swept by nothing."
    - "No file under nvim/ may carry a plan id, task id, requirement code or workflow vocabulary. Traceability lives in the commit message and .planning/, never in a .lua file the operator reads and extends by hand."
---

<objective>
Build a full-IDE neovim that lives alongside vscodium and is wired into this
repo's matugen/theme-engine pipeline, so a theme switch re-colours a RUNNING
nvim with no restart.

Purpose: the project's core value is "one theme switch instantly re-themes the
entire desktop." nvim is the FIRST surface in this repo where matugen must drive
real SYNTAX colours across all 20 palettes — the existing vscodium template
carries zero tokenColors, so there is no precedent to copy for the colour half.
It is also the first themed surface whose config language is a real programming
language rather than a dumb text template, which is exactly what makes the
four-hues-vs-ten-tokens problem solvable.

Three validated spikes settled every unknown that blocked this. Do not re-derive
any of them; their findings are cited inline as hard constraints.

Output: a new `nvim/` stow package with a modular Lua config, a repo-owned
colorscheme that derives its syntax ramp in Lua at load time, a matugen template
writing role colours to the state dir, the 22nd contract entry, a reload fan-out
block, install/stow wiring and the shell fixes that make `vim` and `$EDITOR`
resolve.

DECIDED, and the reason it differs from zellij: zellij ships NO stow package,
because matugen renders its ENTIRE config and commit.sh symlinks it in — there is
no hand-written config left to stow. nvim is the opposite case. Its config is a
hand-written Lua tree the operator reads and extends, and only the ~12 role
COLOURS come from matugen. So nvim gets a stow package for the config tree, and
the generated half stays in ~/.local/state/theme/ where the colorscheme reads it
with dofile — no symlink into ~/.config/nvim is needed at all, which is one less
moving part than any other themed surface here.
</objective>

<execution_context>
@$HOME/.claude/gsd-core/workflows/execute-plan.md
@$HOME/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.claude/CLAUDE.md

# THE REQUIREMENTS. Every bullet under the themed-nvim idea is locked.
@.planning/spikes/MANIFEST.md

# Measured constraints, the locked plugin slate, and the operator's config-style
# instruction. Read the "How the config should be written" section twice.
@.planning/notes/themed-nvim-design-constraints.md

# The three spikes. Read the Results section of each; they are the evidence
# base for the key_links above.
@.planning/spikes/001-highlight-repaint-completeness/README.md
@.planning/spikes/002-external-drive-and-socket/README.md
@.planning/spikes/003-lua-ramp-from-four-hues/README.md

# WORKING, PROVEN colour code. Port it. Do not rewrite the colour maths.
@.planning/spikes/003-lua-ramp-from-four-hues/ramp.lua

# Probe hygiene — never use `ls` to capture a path, never spawn a GUI probe.
@.planning/spikes/CONVENTIONS.md

# The pipeline this plugs into.
@matugen/.config/matugen/config.toml
@matugen/.config/matugen/templates/hyprland-colors.lua
@theme-engine/.config/theme-engine/contract.json
@theme-engine/.config/theme-engine/lib/reload.sh

@stow.sh
</context>

<requirements_map>
There is no CONTEXT.md for this task — the requirements are the bullets under
the `themed-nvim` idea in `.planning/spikes/MANIFEST.md`, plus the three spike
verdicts. The frontmatter ids map as follows, in MANIFEST order:

| id | Requirement |
|----|-------------|
| MAN-01 | colorscheme must call `highlight clear` before painting |
| MAN-02 | define the BASE `@lsp.*` groups; let the suffixed variants link |
| MAN-03 | colours must re-theme live, with no nvim restart |
| MAN-04 | the colorscheme reads its palette from a file the pipeline writes |
| MAN-05 | plugin manager is lazy.nvim, not `vim.pack` |
| MAN-06 | reload.sh globs `$XDG_RUNTIME_DIR/nvim.*` and drives `--remote-expr` |
| MAN-07 | the ramp is derived in Lua at load time; matugen writes roles only |
| MAN-08 | monochrome themes stay monochrome — tier plus bold/italic, never hue |
| MAN-09 | comments render italic in every palette |
| MAN-10 | separation thresholds calibrated against a real scheme, never guessed |
| STYLE-01 | modular folders, never one monolithic init.lua |
| STYLE-02 | real lazy-loading via event/ft/cmd/key triggers |
| STYLE-03 | short, concise, human-readable comments throughout |
| STYLE-04 | no planning, workflow or assistant vocabulary in any config file |
| SPIKE-001/002/003 | the three validated spike findings cited in key_links |
</requirements_map>

<measured_facts>
Verified on this host during planning — do not re-measure, and do not contradict.

- `neovim 0.12.4-1` from Arch `extra`, INSTALLED. `lua 5.5.1-1` INSTALLED.
- `tree-sitter-cli 0.26.9-1` is in Arch `extra` and is NOT installed. `tree-sitter`
  (the library) IS installed. The CLI is what nvim-treesitter's `main` branch needs
  to compile a parser from source.
- Already in install.sh PACMAN_PKGS or pulled in by the paru bootstrap at
  install.sh:495: `lua`, `git`, `ripgrep`, `fd`, `base-devel` (gcc), `unzip`, `curl`.
  Nothing else needs adding beyond `neovim` and `tree-sitter-cli`.
- contract.sh ALREADY has a `lua-table` format in BOTH `contract_extract_names`
  and `contract_extract_values`, added for hyprland-tokens.lua. It `dofile`s the
  file and walks every key. `nvim.lua` reuses it verbatim — **no new format
  handler, and no contract.sh edit at all.**
- theme-doctor's D-29 state-manifest gate FAILS on any file under
  ~/.local/state/theme/ that is not named in contract.json. A rendered nvim.lua
  with no contract entry breaks a currently-green gate.
- `colour-lint` (GATE-04) scans `.qml` files under ~/.config/quickshell only —
  it does NOT apply to Lua. `motion-lint` scans ~/.config/hypr and
  ~/.config/quickshell only — also does not apply. So the baked-in fallback
  palette in lua/theme/palette.lua trips no colour gate.
- `stow-link-check` sweeps ~/.config at depth 1 and only RECURSES into names
  listed in its OWNED_CONFIG_TOP set (stow-link-check:223).
- install.sh runs BEFORE stow.sh (install.sh:1000 prints "Run './stow.sh'" as
  next step 1). A headless plugin restore therefore cannot live in install.sh —
  ~/.config/nvim does not exist yet at that point. stow.sh already ends with a
  first-boot `theme-apply catppuccin` seed; the restore belongs directly after
  it, where both the config tree AND ~/.local/state/theme/nvim.lua exist.
  This is the same self-bootstrap posture fish already uses for fisher.
- `${XDG_RUNTIME_DIR:-/run/user/$(id -u)}` is this repo's established idiom
  (theme-engine/lib/gtk.sh:115).
- The broken aliases: `zshell/.zshrc:80` (`alias vim='nvim'`),
  `fish/.config/fish/config.fish:206` (`alias vim nvim`). `EDITOR`/`VISUAL` are
  unset in both. zsh's idiom is `export NAME=value`; fish's is `set -gx NAME value`.
- Palette role names available to a matugen template (from any file in
  theme-engine/.config/theme-engine/palettes/): primary, on_primary,
  primary_container, on_primary_container, secondary, on_secondary,
  secondary_container, on_secondary_container, tertiary, on_tertiary,
  tertiary_container, on_tertiary_container, surface, on_surface,
  surface_variant, on_surface_variant, background, on_background, outline,
  error, on_error, error_container, on_error_container.
- `{{colors.<role>.default.hex}}` renders `#rrggbb` (qml-palette.json uses this
  form throughout). `hex_stripped` drops the `#` — nvim highlight groups want
  the `#`, so use `.hex`.
</measured_facts>

<tasks>

<task type="tracer">
  <name>Task 1: End-to-end colour path — one theme switch re-colours a live nvim</name>
  <files>matugen/.config/matugen/templates/nvim-palette.lua, matugen/.config/matugen/config.toml, theme-engine/.config/theme-engine/contract.json, theme-engine/.config/theme-engine/lib/reload.sh, nvim/.config/nvim/init.lua, nvim/.config/nvim/lua/theme/palette.lua, nvim/.config/nvim/colors/rice.lua, stow.sh</files>
  <precondition>`nvim`, `lua`, `jq` and `matugen` are all on PATH (all four verified installed on this host during planning).</precondition>
  <action>
Wire ONE thin path through every layer this task will ever touch: matugen
template -> state file -> Lua colorscheme -> live external re-theme. No ramp
yet, no plugins yet, no full highlight set yet — just enough that a theme
switch provably moves the colours of a RUNNING nvim.

Create `matugen/.config/matugen/templates/nvim-palette.lua` as a Lua table
literal (`return { ... }`) carrying exactly twelve role colours, each as a
`#rrggbb` string via `{{colors.<role>.default.hex}}`: surface, on_surface,
surface_variant, on_surface_variant, outline, primary, on_primary,
primary_container, on_primary_container, secondary, tertiary, error. Eight of
those are what the ramp consumes; the other four (surface_variant,
on_primary, primary_container, on_primary_container) are what the UI chrome
needs for cursorline, selection and statusline backgrounds. Model the file's
header on `hyprland-colors.lua` — Lua accepts comments, so explain in the
header what consumes it and state plainly that it carries ROLES ONLY and must
never learn what a syntax slot is, because the consumer derives those itself.

Add `[templates.nvim]` to `matugen/.config/matugen/config.toml` with
input_path `~/.config/matugen/templates/nvim-palette.lua` and output_path
`~/.local/state/theme/nvim.lua`. Follow the block-comment style of the
neighbouring entries. State in that comment that there is no post_hook here
(lib/reload.sh is the sole fan-out owner) and that unlike zellij, nvim DOES
need a reload entry because a running nvim never re-reads the file on its own.

Add the 22nd entry to `theme-engine/.config/theme-engine/contract.json`:
`{ "name": "nvim.lua", "format": "lua-table" }`. Do NOT touch contract.sh —
the lua-table extractors already exist for hyprland-tokens.lua and work on any
`return {...}` table.

Create the `nvim/` stow package with three files for now:

  `nvim/.config/nvim/lua/theme/palette.lua` — reads the role table the theme
  engine writes. Expose a single function that does a fresh `pcall(dofile,
  ...)` of `~/.local/state/theme/nvim.lua` on EVERY call and returns a
  baked-in fallback table when the read fails or comes back malformed. The
  fallback values are catppuccin's, matching the theme stow.sh seeds on first
  boot. There must be NO module-level cached copy of the roles — see the
  key_link; a cached table silently kills the live re-theme.

  `nvim/.config/nvim/colors/rice.lua` — the colorscheme, named `rice` to match
  this repo's existing walker `themes/rice` naming. Order matters:
  (1) derive the wanted `background` value from the surface colour's relative
  luminance and assign it ONLY when it differs from the current value —
  assigning `background` reloads the active colorscheme, so an unguarded
  assignment recurses; (2) `vim.cmd('highlight clear')`, then
  `syntax reset` when `syntax_on` is set; (3) set `termguicolors` and
  `g.colors_name = 'rice'`; (4) read the roles fresh and paint a SMALL tracer
  set — Normal, NormalFloat, Comment, String, Function, Keyword, Type,
  CursorLine, Visual, StatusLine, LineNr — plus the two base groups the spike
  proved go stale, `@keyword` and `@lsp.type.function`. Task 2 expands this to
  the full set; leave the structure ready for that.

  `nvim/.config/nvim/init.lua` — minimal for now: set the leader keys, then
  `vim.cmd.colorscheme('rice')`. Tasks 3-5 grow it.

Add a reload fan-out block to `theme-engine/lib/reload.sh` inside
`theme_engine_reload`, grouped with the other terminal-surface reloads next to
the kitty signal. Glob `${XDG_RUNTIME_DIR:-/run/user/$(id -u)}/nvim.*`, skip
non-sockets, and drive each with
`nvim --server "$sock" --remote-expr "execute('colorscheme rice')"`, wrapped in
both a short `timeout` and `|| true`. Write a comment block in the voice of the
neighbouring ones explaining WHY this surface needs a hook when zellij does not
(zellij watches its own config; a running nvim never re-reads anything), and
record the two measured facts that make the block safe: the default socket path
needs no `--listen`, and a dead socket fails in ~4ms rather than hanging.

In `stow.sh`: add `nvim` to the PACKAGES array (alphabetical position), and add
`mkdir -p "$HOME/.config/nvim"` alongside the existing fold guards BEFORE the
PACKAGES loop, with a comment matching the zellij/quickshell guards above it —
note that unlike those, this one is not a forward guard: a package claiming this
path ships in this same change.

Then run `./stow.sh` so the package is live, and apply a theme so the state file
renders.
  </action>
  <verify>
    <automated>
# Template renders and the contract sees it, for a dark and a light palette.
~/.config/theme-engine/theme-parity catppuccin 2>&1 | tail -20
~/.config/theme-engine/theme-parity rosepine-dawn 2>&1 | tail -20
# The state file exists, is a real Lua table, and the extractor reads it.
lua -e 'local t=dofile(os.getenv("HOME").."/.local/state/theme/nvim.lua"); assert(type(t)=="table" and t.surface and t.primary, "nvim.lua is not a role table"); print("roles:", (function() local n=0 for _ in pairs(t) do n=n+1 end return n end)())'
# No template leftovers.
! grep -q '{{' "$HOME/.local/state/theme/nvim.lua"
# END-TO-END: a live nvim re-themes when driven from outside, with no restart.
# Write this as a FILE under the scratchpad and run it — never as a one-liner
# typed into the shell (spikes/CONVENTIONS.md probe hygiene). Steps, in order:
#   1. setsid nohup a headless nvim with `-c colorscheme rice`, detached, and
#      give it a moment to come up.
#   2. Discover its socket with `find "$RT" -maxdepth 1 -name 'nvim.*'` where
#      RT is ${XDG_RUNTIME_DIR:-/run/user/$(id -u)}. NEVER use `ls` to capture
#      a path — it is aliased to colourised output here and the escapes
#      silently corrupt the value (this cost a full false-negative run in
#      SPIKE-002).
#   3. POSITIVE CONTROL FIRST: `--remote-expr '1+1'` must return 2. Abort if
#      not. A probe that reports "nothing changed" may be blind rather than
#      correct.
#   4. Read Normal's foreground through nvim_get_hl via luaeval — NOT
#      synIDattr, which returns empty under headless because no UI is attached.
#   5. Run theme-apply against a visibly different palette, wait, re-read.
#   6. Assert both reads are non-empty AND differ. Quit the instance.
bash "$SCRATCH/probe-live-retheme.sh"
    </automated>
    <human-check>None — this task is fully machine-checkable.</human-check>
  </verify>
  <done>~/.local/state/theme/nvim.lua renders for every palette, carries only role colours, is the 22nd contract file, and a theme switch measurably moves the Normal foreground of an already-running nvim with no restart.</done>
  <reversibility rating="reversible">A template, a config entry, a contract line and a reload block — all removable in one revert, and the state file disappears with them.</reversibility>
</task>

<task type="auto">
  <name>Task 2: Port the ramp and paint the full highlight set</name>
  <files>nvim/.config/nvim/lua/theme/ramp.lua, nvim/.config/nvim/colors/rice.lua</files>
  <action>
Port `.planning/spikes/003-lua-ramp-from-four-hues/ramp.lua` to
`nvim/.config/nvim/lua/theme/ramp.lua`. This is PROVEN working code that scored
19/20 palettes at the calibrated threshold — copy it, do not rewrite the colour
maths. Keep its existing comments; they already read as human prose and explain
the two mechanisms (hue spin, lightness walk) and the monochrome branch. Adjust
only what the move requires: the module shape and any path assumption. Do not
change SLOTS, the 0.20 monochrome cutoff, the 70 separation threshold, the
(tier, attribute) plan, or the pinned slots in the repair pass.

Then expand `colors/rice.lua` from the tracer set to the full set. Build the
ramp once from the freshly-read roles, then paint:

  - Editor chrome from the role colours: Normal, NormalFloat, FloatBorder,
    FloatTitle, CursorLine, CursorLineNr, LineNr, SignColumn, ColorColumn,
    Visual, Search, IncSearch, CurSearch, MatchParen, Pmenu, PmenuSel,
    PmenuSbar, PmenuThumb, StatusLine, StatusLineNC, WinSeparator, TabLine,
    TabLineSel, TabLineFill, Folded, FoldColumn, Directory, Title, Question,
    MoreMsg, ModeMsg, ErrorMsg, WarningMsg, NonText, Whitespace, SpecialKey,
    EndOfBuffer, Conceal, QuickFixLine, WinBar, WinBarNC.
  - Legacy syntax groups from the ramp slots: Comment, Constant, String,
    Character, Number, Boolean, Float, Identifier, Function, Statement,
    Conditional, Repeat, Label, Operator, Keyword, Exception, PreProc, Include,
    Define, Macro, PreCondit, Type, StorageClass, Structure, Typedef, Special,
    SpecialChar, Tag, Delimiter, SpecialComment, Debug, Underlined, Ignore,
    Error, Todo.
  - Treesitter capture groups, linked to the legacy groups wherever the mapping
    is exact and set explicitly where it is not: the @variable.*, @constant.*,
    @module, @label, @string.*, @character, @boolean, @number.*, @type.*,
    @attribute, @property, @function.*, @constructor, @operator, @keyword.*,
    @punctuation.*, @comment.*, @markup.*, @tag.* and @diff.* families.
  - The BASE @lsp.type.* groups — class, comment, decorator, enum, enumMember,
    event, function, interface, keyword, macro, method, modifier, namespace,
    number, operator, parameter, property, regexp, string, struct, type,
    typeParameter, variable — plus the @lsp.mod.* and @lsp.typemod.* variants
    worth distinguishing (deprecated, readonly, defaultLibrary). Define the
    BASE names only. Do NOT define the client-suffixed variants; they
    default-link to these and `highlight clear` is what restores those links.
  - Diagnostics (DiagnosticError/Warn/Info/Hint plus their Virtual*, Underline*
    and Sign* variants), diff (DiffAdd/Change/Delete/Text, Added/Changed/
    Removed) and spell (SpellBad/Cap/Local/Rare).

Apply the ramp's `attrs` table so bold/italic land where it computed them, and
make comments italic unconditionally — that is the stated convention in every
palette, not only the monochrome ones.

Keep the file readable: group the assignments under short section comments a
human can scan, and use a small local helper for setting a group rather than
forty repetitions of the same long API call.

Then write a headless checker that runs the ported ramp over every palette in
`theme-engine/.config/theme-engine/palettes/` and reports contrast and worst-pair
separation per palette — the same shape as the spike's `check.lua`. Put it under
the scratchpad, not in the repo; it is a gate for this task, not a shipped tool.
  </action>
  <verify>
    <automated>
# Ramp over all 20 palettes: contrast floors met everywhere, separation >= 70
# for 19 of 20 (nord is the known-soft palette, per SPIKE-003 — it must be the
# ONLY one below the bar, and it must not have regressed below its measured 60).
nvim -l "$SCRATCH/check-ramp.lua"   # writes results.json + prints a table
# The colorscheme loads clean on every palette, and the groups the spike proved
# go stale are actually defined:
for p in catppuccin vantablack matte-black nord rosepine-dawn gruvbox-light; do
  ~/.config/theme-engine/theme-apply "$p" >/dev/null 2>&1
  out=$(nvim --headless -c 'colorscheme rice' \
    -c 'lua local g=vim.api.nvim_get_hl(0,{name="@lsp.type.function"}); assert(g.fg, "@lsp.type.function undefined")' \
    -c 'lua local c=vim.api.nvim_get_hl(0,{name="Comment"}); assert(c.italic, "Comment not italic")' \
    -c 'qa!' 2>&1)
  [ -z "$out" ] || { echo "FAIL $p: $out"; exit 1; }
  echo "ok: $p"
done
# highlight clear is present and is the FIRST paint-side statement.
grep -n 'highlight clear' nvim/.config/nvim/colors/rice.lua
# The client-suffixed variants are NOT defined (they must stay default-linked).
! grep -nE '@lsp\.(type|mod|typemod)\.[A-Za-z.]+\.["'"'"']' nvim/.config/nvim/colors/rice.lua
    </automated>
  </verify>
  <done>Ten syntax slots are derived in Lua from the role colours; 19/20 palettes clear separation 70 with nord the known exception at no worse than its measured 60; vantablack and matte-black stay grey and separate by tier plus bold/italic; comments are italic everywhere; the base @lsp.* groups are defined and the suffixed ones are not.</done>
</task>

<task type="auto">
  <name>Task 3: Editor skeleton — options, keymaps, autocmds, lazy bootstrap</name>
  <files>nvim/.config/nvim/init.lua, nvim/.config/nvim/lua/config/options.lua, nvim/.config/nvim/lua/config/keymaps.lua, nvim/.config/nvim/lua/config/autocmds.lua, nvim/.config/nvim/lua/config/lazy.lua</files>
  <action>
Turn the tracer's stub init.lua into the modular skeleton the operator asked
for. Follow the layout mainstream community configs use, so it is recognisable
to anyone who has read one: `init.lua` sets the leader keys FIRST (before any
plugin loads, or lazy-loaded keymaps bind to the wrong leader), then requires
`config.options`, `config.keymaps`, `config.autocmds`, `config.lazy`, then
applies the colorscheme.

`config/options.lua` — the sane-defaults block: line numbers (absolute plus
relative), indentation, search behaviour, splits, undofile, signcolumn,
scrolloff, updatetime, clipboard wired to the Wayland selection, mouse,
termguicolors, cursorline, wrap off, timeoutlen. One short comment per cluster
explaining WHY, not what.

`config/keymaps.lua` — non-plugin keymaps only. Window navigation, buffer
navigation, clearing search highlight, moving selected lines, keeping the
cursor centred on half-page jumps, and writing/quitting. Plugin keymaps belong
in the plugin's own spec as lazy `keys` triggers, never here — say so in a
comment so the operator knows where to add theirs.

`config/autocmds.lua` — highlight-on-yank, restore last cursor position, strip
trailing whitespace on write, and auto-create missing parent directories on
write. Nothing that duplicates a plugin's job.

`config/lazy.lua` — the standard lazy.nvim bootstrap: clone the pinned lazy.nvim
repo into `vim.fn.stdpath('data') .. '/lazy/lazy.nvim'` when absent, prepend it
to the runtimepath, then `require('lazy').setup{}` with `import = 'plugins'` so
every file under `lua/plugins/` is picked up automatically. Configure it to
check for updates but never install them automatically, and to disable the
change-detection notification (it fires on every theme switch otherwise —
noise, not signal). Leave the lockfile at lazy's default location for now;
Task 6 measures whether that survives stowing and decides.

BEFORE writing the bootstrap, fetch lazy.nvim's own current documentation (via
Context7, or its README at the tag you are pinning) and copy the bootstrap
snippet it actually publishes. Do not write it from memory — the snippet
changed shape across versions.

Comment density: short, plain English, one line per decision. The operator must
be able to open any of these files and add a plugin or a keymap without reading
another file first.
  </action>
  <verify>
    <automated>
# Config loads with zero output on a clean start — any stderr is a failure.
out=$(nvim --headless -c 'qa!' 2>&1); [ -z "$out" ] || { echo "FAIL: $out"; exit 1; }
# Leader is set before anything else can bind to it.
nvim --headless -c 'lua assert(vim.g.mapleader and vim.g.mapleader ~= "", "leader unset")' -c 'qa!'
# lazy.nvim bootstrapped itself and the plugins/ import resolves.
nvim --headless -c 'lua assert(pcall(require,"lazy"), "lazy.nvim not on runtimepath")' -c 'qa!'
# Every module is reachable by name (a typo in a require is otherwise silent
# until the file is first touched).
for m in config.options config.keymaps config.autocmds config.lazy theme.palette theme.ramp; do
  nvim --headless -c "lua assert(pcall(require,'$m'), '$m failed to load')" -c 'qa!' || exit 1
done
# Every file is valid Lua on its own. Compile-check through nvim's OWN runtime
# (LuaJIT/5.1) — the system `luac` is 5.5 and would report false errors on
# syntax nvim accepts.
out=$(nvim --headless -c "lua for _,f in ipairs(vim.fn.glob('nvim/.config/nvim/**/*.lua', false, true)) do local ok,err = loadfile(f); if not ok then error(f..': '..tostring(err)) end end" -c 'qa!' 2>&1)
[ -z "$out" ] || { echo "FAIL: $out"; exit 1; }
    </automated>
  </verify>
  <done>init.lua is a five-line entry point; options, keymaps, autocmds and the lazy bootstrap each live in their own file under lua/config/; nvim starts clean and lazy.nvim is bootstrapped and importing lua/plugins/.</done>
</task>

<task type="auto">
  <name>Task 4: LSP, completion and treesitter</name>
  <files>nvim/.config/nvim/lua/plugins/lsp.lua, nvim/.config/nvim/lua/plugins/completion.lua, nvim/.config/nvim/lua/plugins/treesitter.lua</files>
  <precondition>Network access is available — lazy.nvim clones each plugin from GitHub on first load.</precondition>
  <action>
Three plugin specs, one file each, all lazy-triggered.

BEFORE writing any spec, fetch each plugin's CURRENT upstream documentation
(Context7 first, otherwise the repo README at the tag being pinned). Two of
these three have had incompatible API changes recently and a spec written from
memory will be wrong:
  - nvim-lspconfig now only SHIPS server definitions; configuration goes through
    core's `vim.lsp.config()` / `vim.lsp.enable()`, and the old
    `require('lspconfig').X.setup{}` framework is deprecated.
  - nvim-treesitter's `main` branch is a hard incompatible rewrite requiring
    nvim 0.12+. Its setup call, its parser-install API and the way highlighting
    is enabled all differ from the `master` branch that most circulating
    examples still use. Pin the branch explicitly.

`lua/plugins/lsp.lua` — nvim-lspconfig for server definitions only, with the
actual wiring done through core `vim.lsp.config()`/`vim.lsp.enable()`. Lazy-load
on the buffer-read/new-file events. Configure a small starting set of servers
that make sense on this machine — `lua_ls` (this whole config is Lua) and
`clangd` (already installed on this host per the spike environment) — and leave
an obvious, commented spot for the operator to add more. Set up LspAttach
keymaps (go-to-definition, references, hover, rename, code action, diagnostics
navigation) inside an autocmd so they only exist in buffers with a server
attached. Configure diagnostics display (signs, virtual text, float) once.

`lua/plugins/completion.lua` — blink.cmp, pinned to a release tag rather than
tracking a branch, so the prebuilt fuzzy binary matches the source. Lazy-load on
InsertEnter and command-line events. Wire it to the LSP source and to snippets
and buffer/path sources. Check what the docs say about the fuzzy matcher
implementation before choosing: the prebuilt binary avoids adding a Rust
toolchain to install.sh, and there is a pure-Lua fallback if it is unavailable —
pick the option that keeps `install.sh` free of a Rust dependency and say why in
a comment.

`lua/plugins/treesitter.lua` — nvim-treesitter on `main`, lazy-loaded on the
buffer-read event. Install parsers for the languages actually used in this repo
plus the obvious general set: lua, bash, fish, python, json, jsonc, toml, yaml,
markdown, markdown_inline, c, kdl, qmljs, vim, vimdoc, diff, git_config,
gitcommit, regex. Enable highlighting the way the `main` branch documents it.
Add indentation and incremental selection if the branch still supports them; if
it does not, say so in a comment rather than leaving a silently dead option.

Every spec gets a one-line comment saying what the plugin is for and what
triggers it, so the operator can see the lazy-loading strategy at a glance.
  </action>
  <verify>
    <automated>
# All three install cleanly and the lockfile records them.
nvim --headless "+Lazy! sync" +qa 2>&1 | tail -30
test -f nvim/.config/nvim/lazy-lock.json || test -f "$HOME/.config/nvim/lazy-lock.json"
# No plugin is eagerly loaded at startup — the whole point of the lazy triggers.
nvim --headless -c 'lua local l=require("lazy").stats(); print(("loaded %d of %d at startup"):format(l.loaded, l.count)); assert(l.loaded <= 2, "too many plugins load eagerly")' -c 'qa!'
# LSP wiring uses the core API, not the deprecated framework.
grep -q 'vim.lsp.enable' nvim/.config/nvim/lua/plugins/lsp.lua
! grep -qE "require\(['\"]lspconfig['\"]\)\." nvim/.config/nvim/lua/plugins/lsp.lua
# Treesitter is pinned to the branch that supports 0.12+.
grep -q "branch" nvim/.config/nvim/lua/plugins/treesitter.lua
# A real buffer actually gets treesitter highlighting and a server attaches.
nvim --headless "+edit nvim/.config/nvim/init.lua" \
  -c 'lua vim.wait(8000, function() return #vim.lsp.get_clients({bufnr=0}) > 0 end)' \
  -c 'lua assert(#vim.lsp.get_clients({bufnr=0}) > 0, "no LSP client attached to a lua buffer")' \
  -c 'lua assert(vim.treesitter.highlighter.active[vim.api.nvim_get_current_buf()], "no treesitter highlighter on this buffer")' \
  -c 'qa!'
# Startup cost stays sane.
nvim --headless --startuptime "$SCRATCH/startup.log" -c 'qa!' && tail -1 "$SCRATCH/startup.log"
    </automated>
  </verify>
  <done>LSP attaches to a Lua buffer through the core vim.lsp API, blink.cmp installs without adding a Rust toolchain to install.sh, treesitter highlights on the main branch, and at most a couple of plugins load at startup.</done>
</task>

<task type="auto">
  <name>Task 5: Telescope, neo-tree, gitsigns, lualine, conform</name>
  <files>nvim/.config/nvim/lua/plugins/telescope.lua, nvim/.config/nvim/lua/plugins/neo-tree.lua, nvim/.config/nvim/lua/plugins/gitsigns.lua, nvim/.config/nvim/lua/plugins/lualine.lua, nvim/.config/nvim/lua/plugins/format.lua</files>
  <precondition>Network access is available — lazy.nvim clones each plugin from GitHub on first load.</precondition>
  <action>
Five plugin specs, one file each, all lazy-triggered by the thing that actually
needs them. Fetch each plugin's current README before writing its options.

`telescope.lua` — telescope.nvim triggered by `keys` (find files, live grep,
buffers, help tags, recent files) and by `cmd`. It needs plenary as a
dependency and picks up ripgrep and fd, both already installed. Do not add the
fzf-native extension: it needs a compile step, and this repo's hardest
constraint is reproducing from one script.

`neo-tree.lua` — neo-tree.nvim triggered by a toggle key and its command. Wire
git status and filesystem-follow. Keep the window narrow enough to sit beside a
zellij pane.

`gitsigns.lua` — gitsigns.nvim on the buffer-read event, with hunk navigation
and stage/reset/preview keymaps set in its on_attach so they only exist in a
tracked buffer.

`lualine.lua` — lualine.nvim on VeryLazy. THIS ONE HAS A THEME PROBLEM WORTH
SOLVING PROPERLY: it builds its own highlight groups at setup time from a theme
table, so it does not necessarily follow a live `:colorscheme` re-apply. Do not
guess whether it does — measure it (drive a theme switch at a running instance
and read a `lualine_*` group back through nvim_get_hl before and after). If it
follows, say so in a comment and leave it alone. If it does not, build the
lualine theme table from the same ramp the colorscheme uses and re-run lualine's
setup from a `ColorScheme` autocmd, so the statusline moves with everything
else. Either way the comment must record which of the two it is and that it was
measured.

`format.lua` — conform.nvim triggered by the write event and a format keymap.
Configure format-on-save with a short timeout and a fallback to the LSP
formatter, and map formatters for the languages this repo actually contains
(lua, sh/bash, fish, json, yaml, markdown, python). Only reference a formatter
binary if it is present or trivially installable — conform no-ops on a missing
one, so note that in a comment rather than adding installs to install.sh.

Four of these five bring their own highlight groups. Task 2 defined the base
groups they link to; where a plugin defines something that does NOT link to a
standard group and therefore looks wrong after `highlight clear`, add the
explicit definition to `colors/rice.lua` rather than to the plugin spec — the
colorscheme stays the single place colours are decided.
  </action>
  <verify>
    <automated>
nvim --headless "+Lazy! sync" +qa 2>&1 | tail -30
# Still lazy: the five new plugins must not load at startup.
nvim --headless -c 'lua local l=require("lazy").stats(); print(("loaded %d of %d"):format(l.loaded,l.count)); assert(l.loaded <= 4, "plugins loading eagerly")' -c 'qa!'
# Each one loads on demand and its command exists.
nvim --headless -c 'Telescope find_files' -c 'qa!' 2>&1 | grep -qi 'error' && exit 1 || true
nvim --headless -c 'Neotree show' -c 'qa!' 2>&1 | grep -qi 'error' && exit 1 || true
nvim --headless -c 'lua require("lazy").load({plugins={"gitsigns.nvim","lualine.nvim","conform.nvim"}})' -c 'qa!'
# The statusline follows a live theme switch (this is the measured question).
# Run the same live-socket probe shape as Task 1, reading a lualine_* group
# before and after theme-apply. Write it as a file under the scratchpad.
bash "$SCRATCH/probe-lualine-retheme.sh"
# The whole surface still starts clean.
out=$(nvim --headless -c 'qa!' 2>&1); [ -z "$out" ] || { echo "FAIL: $out"; exit 1; }
    </automated>
  </verify>
  <done>All nine plugins of the locked slate are installed and lazy-triggered, each command works on demand, and a live theme switch measurably moves the statusline's colours as well as the buffer's.</done>
</task>

<task type="auto">
  <name>Task 6: Reproducibility — install.sh, stow bootstrap, link coverage, shells</name>
  <files>install.sh, stow.sh, hypr/.config/hypr/scripts/stow-link-check, nvim/.config/nvim/lazy-lock.json, zshell/.zshrc, fish/.config/fish/config.fish</files>
  <action>
Make the whole editor reproduce from install.sh + stow.sh, and fix the two
shell aliases that have been pointing at a missing binary.

`install.sh` — add two entries to PACMAN_PKGS with a comment block in the voice
of the zellij entry above them: `neovim` (extra 0.12.4-1, measured, no AUR) and
`tree-sitter-cli` (extra 0.26.9-1, measured, NOT installed on this host, and
required by nvim-treesitter's main branch to compile a parser from source —
without it parser installation fails silently at first launch). State explicitly
that git, ripgrep, fd, gcc via base-devel, curl and unzip are already covered by
existing entries or the paru bootstrap, so nothing else is needed. Do NOT put a
plugin bootstrap here — install.sh runs before stow.sh, so ~/.config/nvim does
not exist yet at that point; say that in the comment so nobody later "fixes" it
by moving the restore up.

`stow.sh` — after the existing first-boot `theme-apply catppuccin` seed (so both
the config tree AND ~/.local/state/theme/nvim.lua exist), add a headless plugin
restore. Guard it on the `nvim` binary being present, bound it with `timeout`,
and make it non-fatal with a warning — stow.sh runs under `set -euo pipefail`
and a network hiccup must not abort the script after everything else succeeded,
the same posture the zellij plugin fetch already takes. VERIFY THE ACTUAL
INCANTATION against lazy.nvim's own documentation before writing it: the widely
repeated `nvim --headless "+Lazy! restore" +qa` form is blog material, not a
confirmed upstream instruction, and this repo does not ship unverified commands.
Add a Next-steps line at the end of stow.sh mentioning nvim if it earns one.

THE LOCKFILE QUESTION, to be MEASURED not assumed. `nvim/.config/nvim/lazy-lock.json`
ships in the stow package, so after stowing, `~/.config/nvim/lazy-lock.json` is a
symlink into the repo. Run a plugin sync and then check whether that path is
STILL a symlink resolving into the repo. If it is, keep lazy's default lockfile
location and note the measured result in a comment. If lazy replaced the symlink
with a regular file, set lazy's explicit lockfile option to the repo-side path
instead (this repo already hardcodes `$HOME/dotfiles` in stow.sh, install.sh and
theme-doctor, so that is consistent) and record why in a comment in
`lua/config/lazy.lua`. Either way, commit the resulting lockfile.

`hypr/.config/hypr/scripts/stow-link-check` — add `'nvim'` to OWNED_CONFIG_TOP.
This is not cosmetic: because stow.sh pre-creates ~/.config/nvim as a real
directory, the depth-1 sweep never descends into it, so without this entry every
per-file symlink the new package creates is covered by nothing. Extend the
comment block above the set to name nvim alongside the others.

`zshell/.zshrc` — the `vim` alias at line 80 now resolves to a real binary;
leave it. Add `export EDITOR=nvim` and `export VISUAL=nvim` using the file's own
`export NAME=value` idiom, placed with the other exports rather than in the
alias block.

`fish/.config/fish/config.fish` — same, using fish's `set -gx NAME value` idiom,
placed near the alias block that already claims parity with .zshrc. Keep the two
files in parity, as that block's own comment demands.
  </action>
  <verify>
    <automated>
bash -n install.sh && bash -n stow.sh
grep -nE '^\s+neovim$|^\s+tree-sitter-cli$' install.sh
grep -n "'nvim'" hypr/.config/hypr/scripts/stow-link-check
grep -n 'nvim' stow.sh
# stow-link-check still self-tests green and now covers the new tree.
"$HOME/.config/hypr/scripts/stow-link-check" --self-test
"$HOME/.config/hypr/scripts/stow-link-check" | tail -20
# Both shells: vim resolves, EDITOR/VISUAL set.
zsh -ic 'echo "zsh vim -> $(whence -p nvim)"; echo "EDITOR=$EDITOR VISUAL=$VISUAL"' 2>/dev/null | tail -2
fish -c 'echo "fish EDITOR=$EDITOR VISUAL=$VISUAL"; type -a vim' 2>&1 | tail -3
# The lockfile question, answered by measurement not assumption.
ls -l "$HOME/.config/nvim/lazy-lock.json"
readlink -f "$HOME/.config/nvim/lazy-lock.json"
test -s nvim/.config/nvim/lazy-lock.json || { echo "FAIL: lockfile not committed"; exit 1; }
# A re-run of stow.sh is idempotent and does not dirty the repo beyond the lockfile.
./stow.sh >/dev/null 2>&1; git status --porcelain
    </automated>
  </verify>
  <done>install.sh declares neovim and tree-sitter-cli; stow.sh stows the package, guards the fold and restores plugins headlessly from the committed lockfile; stow-link-check recurses into the new tree; `vim` and $EDITOR resolve in both shells.</done>
  <reversibility rating="reversible">Package list entries, one stow step and two shell exports — all revertible without touching host state beyond an uninstall.</reversibility>
</task>

<task type="auto">
  <name>Task 7: Gate sweep, 20-palette parity, and the no-jargon check</name>
  <files>theme-engine/.config/theme-engine/contract.json, nvim/.config/nvim/</files>
  <action>
Prove nothing regressed and that the new surface is covered everywhere the
existing ones are.

Run the full gate set and record the counts in the summary: theme-doctor
(expect the pass count to rise by the new contract-file existence check, with
failures still zero — the criterion is failed=0, never the pass count),
theme-parity across all 20 palettes plus both materialyou modes, colour-lint,
motion-lint, retirement-check --self-test and stow-link-check --self-test.

Then sweep every palette explicitly: for each file in
`theme-engine/.config/theme-engine/palettes/`, apply it, assert
`~/.local/state/theme/nvim.lua` renders as a valid Lua role table with the same
key set every time, and assert the colorscheme loads clean against it. A key set
that differs between palettes is exactly what theme-parity's name-set layer
exists to catch — confirm it is catching this file, not skipping it.

Finally, the operator's hard style requirement. Grep the whole `nvim/` tree for
planning, workflow and AI-assistant vocabulary — the pattern is spelled out in
the verify block below, not here, deliberately, so this plan's own prose can
never leak into a config file and then satisfy its own check. Zero matches is
the bar. While you are in there, confirm every file carries short plain-English
comments and that no file is a monolith: init.lua stays an entry point, and no
single Lua file under nvim/ should be doing three unrelated jobs.

Fix anything the sweep turns up, then re-run the gates.
  </action>
  <verify>
    <automated>
~/.config/theme-engine/theme-doctor 2>&1 | tail -8
~/.config/theme-engine/theme-parity 2>&1 | tail -12
~/.config/hypr/scripts/colour-lint 2>&1 | tail -5
~/.config/hypr/scripts/motion-lint 2>&1 | tail -5
~/.config/hypr/scripts/stow-link-check --self-test 2>&1 | tail -5
# Every palette renders the same key set and loads clean.
for f in theme-engine/.config/theme-engine/palettes/*.json; do
  p=$(basename "$f" .json)
  ~/.config/theme-engine/theme-apply "$p" >/dev/null 2>&1
  lua -e 'local t=dofile(os.getenv("HOME").."/.local/state/theme/nvim.lua"); local k={} for n in pairs(t) do k[#k+1]=n end table.sort(k) print(table.concat(k,","))' || exit 1
  out=$(nvim --headless -c 'colorscheme rice' -c 'qa!' 2>&1)
  [ -z "$out" ] || { echo "FAIL $p: $out"; exit 1; }
done | sort -u | tee /dev/stderr | wc -l   # must print exactly 1 distinct key set
# No planning/AI/workflow vocabulary anywhere in the shipped config. Scoped to
# .lua files: lazy-lock.json is machine-written and carries no prose.
! grep -rniE --include='*.lua' 'D-[0-9]{2}|T-[0-9a-z]{3}-[0-9]{2}|GATE-[0-9]|SPIKE-[0-9]|quick task|PLAN\.md|SUMMARY\.md|must_have|acceptance criteri|orchestrat|subagent|Claude|GSD|phase [0-9]+ plan' nvim/
# Repo is clean apart from what this task intends to commit.
git status --porcelain
    </automated>
  </verify>
  <done>theme-doctor reports zero failures, theme-parity is green across all 20 palettes plus both materialyou modes, colour-lint and motion-lint are unchanged, nvim.lua renders one identical key set for every palette, and the nvim/ tree contains no planning or assistant vocabulary.</done>
</task>

<task type="checkpoint:human-verify" gate="blocking-human">
  <name>Task 8: Operator checkpoint — look at it and switch a theme</name>
  <what-built>
A complete themed nvim: a `nvim/` stow package with a modular Lua config
(options, keymaps, autocmds, lazy bootstrap, nine lazy-loaded plugins), a
repo-owned `rice` colorscheme that derives ten syntax slots in Lua from the
role colours matugen writes to ~/.local/state/theme/nvim.lua, a reload fan-out
that re-themes every live instance, and install/stow/shell wiring.

Everything machine-checkable has already been checked: gates green, ramp
measured across all 20 palettes, live re-theme proven on a headless socket.
What is left needs eyes — this repo has shipped a "verified" fix before that
checked a true criterion on the wrong axis.

Everything is already deployed. `./stow.sh` has been run, plugins are restored,
and a theme is applied. There is nothing for the operator to install or start.
  </what-built>
  <how-to-verify>
Do this in a REAL kitty window, not through an agent shell — this host's agent
shell misreports the terminal, and screenshots SIGSEGV the compositor here, so
this genuinely has to be looked at directly.

  1. Open `nvim` on a real source file — one of this repo's own .lua files, or
     a C file to exercise clangd. Confirm syntax colours look right and that
     comments render italic.
  2. With that nvim STILL OPEN, switch themes (Super+Shift+T). Confirm the
     buffer re-colours immediately, with no restart and nothing left in the old
     palette — statusline, line numbers, git signs and the completion popup
     included.
  3. Switch to a MONOCHROME palette (vantablack or matte-black). Confirm it
     stays genuinely black-and-white, and that tokens are still told apart by
     weight and slant rather than by an injected colour.
  4. Switch to a LIGHT palette (catppuccin-latte, rosepine-dawn or
     gruvbox-light). Confirm it reads as a light theme, not a dark theme on a
     light background.
  5. Exercise the slate: find-files, live grep, the file tree, a hunk stage, a
     format-on-save, and completion in insert mode.
  6. Confirm zellij's autolock locks when nvim takes focus. This is the one item
     the multiplexer work never got to test, because nvim did not exist then. It
     needs no config change — it only needed nvim installed.
  </how-to-verify>
  <resume-signal>Reply "approved" if all six pass. Otherwise describe what looks wrong — fixes land as follow-up commits under this same task before it closes.</resume-signal>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| palette data → matugen template → rendered nvim.lua | Colour data crosses into a file nvim EXECUTES as Lua via dofile |
| ~/.local/state/theme/nvim.lua → running nvim process | A generated file is executed inside the editor's Lua state on every colorscheme load |
| reload.sh → $XDG_RUNTIME_DIR/nvim.* sockets | An external process sends an expression to every live editor instance |
| GitHub → lazy.nvim → ~/.local/share/nvim/lazy | Nine third-party plugin repositories are cloned and their Lua executed on load |
| repo tree ↔ ~/.config/nvim (stow) | A fold would let editor-written state land in the git checkout |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-nua-01 | Elevation of Privilege | nvim.lua is `dofile`d, so any content matugen renders becomes executed Lua | medium | mitigate | The template emits ONLY quoted `#rrggbb` strings inside a flat `return {...}` table — no function values, no concatenation, no interpolation into a code position. Task 1's verify asserts the loaded value is a table of role strings and that no `{{` leftover survives. The same execute-what-matugen-renders shape is already accepted for hyprland-tokens.lua, which this reuses rather than widens. |
| T-nua-02 | Elevation of Privilege | `--remote-expr "execute('colorscheme rice')"` sends a vimscript expression into every live editor | medium | mitigate | The expression is a STATIC literal in reload.sh — no palette value, theme name or user input is ever interpolated into it. The colorscheme name is fixed at `rice`. A palette-derived string reaching this call site would turn colour data into an executed editor command; keeping the literal static makes that structurally impossible. |
| T-nua-03 | Denial of Service | A stale socket from a crashed nvim blocks the theme-switch fan-out | medium | mitigate | MEASURED (SPIKE-002): a dead socket errors in ~4ms rather than hanging. Belt-and-braces anyway, because this repo has a 45+ minute reload-hang scar: the call is `timeout`-bounded AND `|| true`-guarded, and sits inside reload.sh's existing headless early-return. |
| T-nua-04 | Tampering | Nine third-party plugin repositories cloned from GitHub and executed | medium | mitigate | The slate is operator-locked, and every repo is the canonical upstream for its name — verify the org/name against the plugin's own documentation before writing each spec, never a lookalike. `lazy-lock.json` is committed, so a fresh machine restores the exact revisions rather than whatever HEAD happens to be, which is strictly more reproducible than an unpinned clone. Updates are never automatic. No npm/pip/cargo install occurs, so no Package Legitimacy Audit table applies; the two pacman packages (`neovim`, `tree-sitter-cli`) are both from the official `extra` repo, measured present with `pacman -Si`, no AUR. |
| T-nua-05 | Tampering | stow fold writing editor state into the git checkout | medium | mitigate | stow.sh pre-creates `~/.config/nvim` as a real directory BEFORE the PACKAGES loop, matching the fish/gtk/quickshell/zellij guards. Task 6 additionally MEASURES whether lazy's lockfile write preserves the stow symlink and re-points the lockfile at the repo path if it does not, so the one file that is meant to be repo content is the only one that ever becomes it. |
| T-nua-06 | Information Disclosure | Generated colours committed to a public repo | low | accept | Nothing generated is committed: nvim.lua lives in `~/.local/state/theme/`, never git-tracked, and the template in the repo holds only role placeholders. No key, token or credential belongs in either file. |
| T-nua-SC | Tampering | package installs | low | mitigate | No npm/pip/cargo install occurs. Both pacman packages are official-repo, version-measured during planning. The plugin clones are covered by T-nua-04. |
</threat_model>

<verification>
- theme-doctor: zero failures (pass count rises by the new contract-file check).
- theme-parity: green across all 20 palettes plus materialyou and materialyou-light.
- colour-lint, motion-lint: unchanged from their current green state.
- stow-link-check --self-test: green, with `nvim` now in OWNED_CONFIG_TOP.
- `git status --porcelain` empty after a theme switch (CLEAN-02 invariant).
- The live re-theme probe from Task 1 moves Normal's foreground on a running instance.
- The ramp checker reports 19/20 palettes clearing separation 70, nord the known exception.
- Zero matches for the jargon pattern anywhere under `nvim/`.
</verification>

<success_criteria>
A theme switch re-colours a running nvim — buffer, statusline, signs and popups —
with no restart; the syntax ramp is derived in Lua from role colours across all
20 palettes with monochrome themes staying monochrome; the whole editor
reproduces from install.sh + stow.sh with plugins pinned to a committed
lockfile; `vim` and `$EDITOR` resolve in both shells; every existing gate is
still green; and the config reads as hand-written dotfiles a human can extend.
</success_criteria>

<output>
Create `.planning/quick/260820-nua-build-the-themed-neovim-config-wired-int/260820-nua-SUMMARY.md` when done.
</output>
