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
