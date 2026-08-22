# Open Research Questions

Questions raised during exploration that need a real answer before they can be
relied on. Anything here is **unresolved** — never restate one of these as a
settled fact in a plan, spec or config comment.

---

## Themed nvim (raised 2026-08-20)

Context: `.planning/notes/themed-nvim-design-constraints.md`

A research pass on 2026-08-20 admitted several claims with primary sources, but
these could not be stood behind. Each carries the reason it failed.

### 1. Does a live `:colorscheme` fully repaint treesitter and LSP groups?

Whether re-running `:colorscheme` clears and re-applies **treesitter (`@...`)**
and **LSP semantic-token (`@lsp.*`)** highlight groups, or leaves some stale.

*Failed as:* non-authoritative source — only blog/gist material found, no
primary neovim documentation on the clearing semantics.

**This is the blocking one.** Owned by the spike todo
`2026-08-20-spike-nvim-live-colorscheme-reload.md`. If the answer is "leaves
stale groups", the live re-theme design changes shape.

### 2. Where does nvim put its server socket, and can it be enumerated?

The default socket path, and whether an external script (`reload.sh`) can
discover every live nvim instance to signal it.

*Failed as:* unverifiable — the fetched docs did not state the default path
string.

Known and admitted: `$NVIM_LISTEN_ADDRESS` is deprecated; `--listen` /
`serverstart()` set it and `v:servername` reads it (neovim
`runtime/doc/deprecated.txt`). Calling `serverstart()` at a path this repo
chooses may sidestep the question entirely — worth testing in the same spike.

### 3. What is the verbatim headless plugin-restore command?

`nvim --headless "+Lazy! restore" +qa` is widely repeated for unattended
bootstrap in `install.sh`.

*Failed as:* unverifiable from primary text — not confirmed in lazy.nvim's own
documentation this session. `:Lazy restore` itself **is** admitted
(lazy.folke.io/usage/lockfile); it is the headless invocation that is unproven.

Must be confirmed before `install.sh` depends on it, since a fresh-install
bootstrap that silently does nothing is exactly the failure this repo's
reproducibility constraint exists to prevent.

### 4. What are native `vim.lsp.completion`'s actual limitations?

nvim 0.12 added native completion. The claim that it lacks multi-source merging
— and is therefore inadequate for a full IDE — drove the decision to use
blink.cmp instead.

*Failed as:* non-authoritative source.

Low urgency: blink.cmp is a fine choice regardless. Worth revisiting if the
plugin count ever needs cutting.

### 5. Are neo-tree / nvim-tree / oil.nvim actively maintained?

*Failed as:* no repo-level archival check was performed.

neo-tree.nvim is the chosen file tree, so its maintenance status specifically
should be verified at plan time. Cheap to check — look at the repo directly.

**RESOLVED 2026-08-20 — verified against the GitHub API (primary source), both
chosen plugins actively maintained.** blink.cmp was checked in the same pass
since it carried the same "never primary-source verified" caveat.

**neo-tree.nvim** (`nvim-neo-tree/neo-tree.nvim`): not archived; last push
2026-08-19 (the day before this check); 28 commits on `main` since 2026-06-01,
substantive fixes not just CI (git discovery, job stdio flushing); steady
release cadence — 3.39.0 (Feb), 3.40.0 (Mar), 3.41.0 (2026-05-15). Our
lazy-lock pin `ebd66767` on branch `v3.x` **is** the 3.41.0 release commit —
the current release, not a stale ref. `v3.x` has zero commits since then
because releases are cut onto it from `main`; quiet `v3.x` + active `main` is
the repo's normal shape, not abandonment. Caveat worth carrying: 22 of the 28
recent commits are one maintainer (`pynappo`) — a real bus-factor, though the
project accepts outside PRs (5 distinct other authors since June).

**blink.cmp** (`Saghen/blink.cmp`): not archived; last push 2026-08-15; 93
commits on `main` since 2026-06-01; release cadence roughly monthly through
v1.10.2 (2026-04-04). Our pin `78336bc` is exactly the v1.10.2 version-bump
commit — the latest release. Releases lag `main` by a few months but
development is unambiguously active.

nvim-tree and oil.nvim were not checked — neither is installed, and the
question only mattered for the chosen tree.

---

## Launcher QML migration (raised 2026-08-22)

Context: `.planning/notes/launcher-qml-migration-design.md`

A two-agent research pass on 2026-08-22 (Omarchy's menu; Caelestia + end-4
launcher QML) admitted most claims against primary source. These two could not
be stood behind. Researcher tier resolved to `sonnet`, above the budget tier, so
the tier floor did not arm — these are genuine abstains, not suppressed admits.

### 1. How do end-4's clipboard and emoji providers actually work?

Whether end-4's `Cliphist.qml` / `Emojis.qml` shell out to `cliphist` and a
system emoji source, or bundle their own data (a vendored emoji JSON, an
in-QML model).

*Failed as:* unverifiable — the researcher routed clipboard/emoji through the
prefix system in `LauncherSearch.qml` but did not open the two provider files
themselves.

**This is the one that matters.** Both surfaces have to be built natively here
(Tools ▸ Emoji, Tools ▸ Clipboard, plus the Super+C bind), and the answer
decides whether emoji data ships in-repo or is read from the system. Resolve
before planning those two surfaces, not during.

### 2. Does `walker --dmenu` return a distinct exit code on Escape?

Whether walker distinguishes "user pressed Escape" from "no match / empty pick"
by exit code, or only by empty stdout.

*Failed as:* unverifiable — inferred from how `omarchy-menu` consumes it (it
string-matches stdout and falls through to a `*)` default arm, never checking
an exit code), with walker's own source not fetched.

**Largely moot** — walker is being retired, and this repo already answers the
question operationally: `hypr/.config/hypr/scripts/tests/test-walker-dmenu-cancel.sh`
exists specifically to check exit-130 cancel handling across the picker scripts.
Recorded because that test file is evidence this repo *did* rely on the
distinction, which is worth knowing when the QML surfaces define their own
cancel semantics.
