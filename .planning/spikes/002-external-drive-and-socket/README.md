---
spike: 002
idea: themed-nvim
name: external-drive-and-socket
type: standard
validates: "Given a running nvim, when an external script enumerates server sockets and sends a colorscheme change, then the change lands in that live instance with no restart"
verdict: VALIDATED
related: [001]
tags: [nvim, ipc, socket, reload, theme-engine]
---

# Spike 002: External Drive and Socket Discovery

## What This Validates

**Given** a running nvim, **when** an external script enumerates server sockets
and sends it a colorscheme change, **then** the change lands in that live
instance with no restart.

Spike 001 proved a running nvim *can* fully repaint. This proves something
outside the process can *make* it — which is what `reload.sh` has to do on
every theme switch.

## Research

Carried in from the exploration research pass:

- **Admitted:** `nvim --server <addr> --remote-send` / `--remote-expr` exist —
  neovim `runtime/doc/remote.txt`.
- **Admitted:** `$NVIM_LISTEN_ADDRESS` is deprecated; `--listen`/`serverstart()`
  set the address and `v:servername` reads it — neovim
  `runtime/doc/deprecated.txt`.
- **Was unresolved:** the default socket path, and whether instances are
  externally enumerable. *Now answered by measurement below.*

## How to Run

```
./drive.sh        # main test      -> results.txt
./calibrate.sh    # probe control  -> stdout
./edge-cases.sh   # multi-instance + stale socket -> results-edge.txt
```

## Investigation Trail

**1. The default socket path — the open research question.**

An nvim started with **no `--listen` flag at all** reports:

```
v:servername = /run/user/1000/nvim.809051.0
```

So the default is `$XDG_RUNTIME_DIR/nvim.<pid>.<n>`, and every live instance is
externally discoverable with a plain glob:

```
$XDG_RUNTIME_DIR/nvim.*
```

No `serverstart()` call is needed in the config. Research question 2 is closed.

**2. First run returned all-empty reads — and it was the probe, twice.**

The first `drive.sh` reported `NO` on all three verdicts. Both causes were
probe defects, not feature failures. A positive control (`calibrate.sh`) found
them:

- **`ls` is aliased** to long colourised output in the interactive shell, so
  `SOCK=$(ls ...)` captured a whole `ls -la` line with ANSI escapes. Every
  connection then failed with `E247: failed to lookup host or port`. Fix: use
  `find`, never `ls`, when capturing a path.
- **`synIDattr(synIDtrans(hlID('X')),'fg#')` returns empty under headless.**
  The instance reports `len(nvim_list_uis()) = 0` and `&termguicolors = 0` — no
  UI attached means no GUI colour to report. Fix: read with
  `nvim_get_hl` through `luaeval`, which is UI-independent.

The positive control that exposed it: `--remote-expr '1+1'` → `2`, and
`v:servername` returned the correct socket, proving the transport was fine while
the *reads* were blind. `g:colors_name` also already read back `spikelive`,
meaning the external drive had been working the whole time.

`drive.sh` now runs that calibration inline and aborts if it fails, so this
cannot silently recur.

**3. The real run.**

```
palette v1, driven via --remote-expr
  Normal=#aaaaaa  @keyword=#ff0000  @lsp.type.function=#ff0000

palette rewritten on disk, re-driven via --remote-expr
  Normal=#dddddd  @keyword=#00ccff  @lsp.type.function=#00ccff

palette rewritten again, driven via --remote-send keystrokes
  Normal=#eeeeee  @keyword=#ffcc00

remote-expr drove a change:  YES  (#aaaaaa -> #dddddd)
remote-send drove a change:  YES  (#dddddd -> #eeeeee)
@lsp.* followed externally:  YES  (#ff0000 -> #00ccff)
```

Both routes work. `--remote-expr "execute('colorscheme ...')"` is the better one
for `reload.sh`: it needs no mode juggling, unlike `--remote-send`, which has to
prefix `<C-\><C-N>` to escape whatever mode the user is in.

**4. Edge cases `reload.sh` will actually meet.**

*Several instances open at once* — three started concurrently, all three
discovered by the glob and all three re-themed: **3 / 3**.

*A socket left by a crashed nvim* — after `kill -9`, the socket file
**lingers**. `reload.sh` will meet dead sockets in the wild. Connecting to one:

```
exit=2 after 4ms  <-- failed fast, safe
```

It errors immediately rather than hanging. This matters specifically here: this
repo has a scar from a reload hook that blocked for 45+ minutes on a dead
endpoint (the INST-03 gate hang), and `|| true` guards an exit code but not a
hang. A dead nvim socket is safe on both counts.

## Results

**VALIDATED.**

1. Default socket is `$XDG_RUNTIME_DIR/nvim.<pid>.<n>` — no `--listen` needed,
   no `serverstart()` in the config.
2. `$XDG_RUNTIME_DIR/nvim.*` enumerates every live instance.
3. `--remote-expr "execute('colorscheme <name>')"` re-themes a live instance
   from outside, `@lsp.*` groups included. Preferred over `--remote-send`.
4. Multiple instances all get reached — 3/3.
5. Stale sockets from crashed instances linger, but fail in ~4ms rather than
   hanging. Tolerate a non-zero exit per socket and move on.

**For `reload.sh`:** glob `$XDG_RUNTIME_DIR/nvim.*`, fire
`--remote-expr "execute('colorscheme <name>')"` at each, ignore per-socket
failures. Same shape as the existing fan-out entries, and headless-safe because
the whole block already sits behind the session guard.
