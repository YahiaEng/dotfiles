---
phase: quick-260820-1kp
plan: 01
status: complete
completed: 2026-08-20
commits:
  - a6bdf62
  - 3e7a21a
  - e18e7bb
  - 0bf5608
  - ec25a02
  - 6e6705b
files_modified:
  - matugen/.config/matugen/templates/zellij-layout.kdl
  - matugen/.config/matugen/templates/zellij-config.kdl
  - matugen/.config/matugen/config.toml
  - theme-engine/.config/theme-engine/contract.json
  - theme-engine/.config/theme-engine/lib/contract.sh
  - theme-engine/.config/theme-engine/lib/commit.sh
  - install.sh
---

# Summary — zellij plugins (zjstatus bar + autolock)

**Operator-verified live:** wedged status bar renders, theme switch re-colours it
**live with no restart**, `Ctrl+f` (filepicker) and `Ctrl+y` (session-manager) both work,
bottom keybind-hint bar present.

## What shipped

| Piece | Where |
|---|---|
| zjstatus themed bar, top | `zellij-layout.kdl` → state dir → `~/.config/zellij/layouts/rice.kdl` |
| Built-in keybind-hint bar, bottom | `pane { plugin location="status-bar" }` in the same layout |
| `default_layout "rice"` | `zellij-config.kdl` (supersedes D-08's deliberately-unset) |
| autolock | `load_plugins` block (no pane, so it costs no row) |
| `Ctrl+y` session-manager, `Ctrl+f` filepicker | `keybinds { shared_except "locked" }` |
| 2 pinned `.wasm` + seeded permissions | `install.sh` |
| Contract 20 → 21, new `kdl-plugin` format | `contract.json`, `lib/contract.sh` |

Final gates: **theme-doctor 609/0 exit 0**, theme-parity 1897/0, colour-lint 150/0.

## How this actually went — the honest version

The first commit was declared shippable with "live render unverified." It took
**four more commits** to become the thing described. Each defect was real, each was
mine, and none would have been caught without the operator putting it on screen.

**a6bdf62 → the bar didn't appear.** Cause: a zellij plugin renders nothing until
granted permissions, and zellij asks by drawing `Allow?(y/n)` **inside the plugin's own
pane** — which is one row tall and physically cannot show it. The plugin loaded fine, the
layout applied fine, nothing rendered, no error anywhere a user would look. `install.sh`
now seeds the grants (`e18e7bb`).

**Then I misdiagnosed it.** I reported the plugin was "rendering zero bytes," based on
`zellij action dump-screen`. That command returns **1 byte for any plugin pane** — the
probe was blind and I treated it as evidence. A region-limited `grim` of the live window
showed the bar had been rendering the whole time. *Check that a probe can observe a
positive control before believing its negative.*

**0bf5608 → no powerline wedges.** The format strings set up the colour transition for a
wedge — switching bg/fg at each boundary — but never emitted the wedge **character**.
Flat blocks, not wedges.

**ec25a02 → the bottom keybind bar vanished.** zellij's stock layout is tab-bar (top) +
status-bar (bottom), and a `default_tab_template` replaces **both**. zjstatus took the top
role; nothing was put back at the bottom. This also silently falsified a claim added in
the *same commit*: the keybinds comment argued the new binds were safe because defaults
"are discoverable from the status bar itself."

**6e6705b → the bar couldn't live-re-theme, plus monocle panicked.** Below.

## The design reversal (operator decision)

zjstatus's colours were baked into the **layout**, and zellij reads a layout only at pane
creation. Measured rather than assumed: switching catppuccin → nord and then running
`zellij action start-or-reload-plugin` left the bar emitting **24 catppuccin-purple SGR
codes and zero nord**. A plugin reload does not re-read layout config.

That directly breaks the project's core value, so the bar moved from matugen hex to
**named** colours. zjstatus resolves those to ANSI-16 SGR (verified: `#[bg=blue,fg=black]`
emits `ESC[30m ESC[44m`), which the terminal resolves from its palette at **draw** time.
Both resolvers on that path — zellij's `themes` block and kitty's ANSI palette — are
already matugen-rendered and already hot-reload.

**The trade, operator-chosen:** the bar can use only the theme's 8 named slots, not the
full Material You role set. Mapping lives in `zellij-config.kdl`'s themes block
(blue=primary, yellow=secondary, green=tertiary, red=error, black=surface_variant,
white=on_surface_variant). Change a bar colour by changing *that mapping*, never by
pasting hex back into the layout — hex silently reverts to the non-reloading behaviour.

## Plugins dropped, and why

Shipped with four; **two were removed**.

**monocle** panicked at `src/main.rs:16` on the live desktop — 223 times in two minutes, a
render loop. Released **2025-01-03, seventeen months before this zellij**. It could not be
reproduced across four probes (repo cwd, home cwd, isolated session, direct load), and a
third-party Rust panic is not patchable from here. **room** never failed but carried the
same rot risk from the same cause: an out-of-tree plugin pinned against a moving API.

Both replaced by `filepicker` and `session-manager`, which ship **inside the zellij
binary** and are version-matched by construction. Only plugins with no in-tree equivalent
are still fetched: zjstatus (theming) and autolock. **Standing rule: prefer an in-tree
plugin unless it genuinely cannot do the job.**

## Findings worth keeping

**1. matugen parses the whole template, KDL comments included.** A literal doubled opening
brace written in a comment — as prose documenting the rule — opened an unclosed expression
and reported its error **16 lines later**, at a line that rendered fine in isolation.

**2. Powerline glyphs are silently stripped through a shell heredoc.** They must be written
by codepoint (`chr(0xE0B0)`) and verified by codepoint. Grepping for the literal character
inside a double-quoted shell string reports a **false zero** — that cost a cycle here.

**3. Pre-seeding permissions removes the prompt, so an incomplete grant fails silently.**
The seeding is minimum-privilege per plugin and skips any plugin whose fetch or checksum
failed. Worth re-checking whenever a plugin gains a feature.

**4. `zellij setup --check` saying "Well defined" is not evidence of anything visual.** It
validates `config.kdl` and never opens the layout. It reported success in every single one
of the failure states above.

**5. The `kdl` format could not be reused for the layout.** Its shared emitter exits
non-zero on zero pairs — deliberately loud. The layout has no `themes` node, so the
emitter's container node became a parameter and `kdl-plugin` passes `plugin`. One emitter
still serves both, which is the point: a second extractor would reintroduce exactly the
mirrored-regex drift that emitter exists to prevent.

**6. The layout stays a matugen template despite no longer interpolating.** Since the
named-colour switch its output is byte-identical for every palette. Kept as a contract
target anyway so theme-doctor and theme-parity verify it exists, is non-empty and is
well-formed across all 22 themes (1897/0 with it static).

## Comments this task made false and then corrected

Both were authored by this task and falsified by this task:

- The `default_layout` note claimed the bar follows "all 20 palettes instead of the
  terminal's 8 ANSI slots" — the named-colour switch makes that exactly backwards.
- The layout header claimed every colour was a matugen keyword, after the plugin block
  stopped interpolating entirely.

## Not verified

**autolock's lock/unlock cycle.** `nvim` is not installed on this host. `vim`, `git`,
`fzf`, `yazi` and `claude` **are**, and all are in the trigger list, so it is testable
today with `vim` — that check simply has not been run. `nvim`/`hx` are already in the
trigger list, so the themed-editor task queued next needs no autolock config change.
