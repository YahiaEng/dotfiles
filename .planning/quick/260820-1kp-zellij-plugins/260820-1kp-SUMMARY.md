---
phase: quick-260820-1kp
plan: 01
status: complete
completed: 2026-08-20
commits:
  - a6bdf62
files_modified:
  - matugen/.config/matugen/templates/zellij-layout.kdl
  - matugen/.config/matugen/templates/zellij-config.kdl
  - matugen/.config/matugen/config.toml
  - theme-engine/.config/theme-engine/contract.json
  - theme-engine/.config/theme-engine/lib/contract.sh
  - theme-engine/.config/theme-engine/lib/commit.sh
  - install.sh
---

# Summary — zellij plugins (zjstatus bar, autolock, room, monocle)

## What shipped (commit `a6bdf62`)

| Piece | Where |
|---|---|
| zjstatus themed status bar | new template `zellij-layout.kdl` → `~/.local/state/theme/zellij-layout.kdl` → symlinked `~/.config/zellij/layouts/rice.kdl` |
| `default_layout "rice"` | `zellij-config.kdl` (supersedes D-08's deliberately-unset) |
| autolock | `load_plugins` block in `zellij-config.kdl` |
| room (`Ctrl y`), monocle (`Ctrl f`) | `keybinds { shared_except "locked" }` in `zellij-config.kdl` |
| Four pinned `.wasm` fetches | `install.sh`, end of `section_core_rice` |
| Contract 20 → 21 | `contract.json` + new `kdl-plugin` format in `lib/contract.sh` |

Pins (URL + sha256 both recorded in `install.sh`): zjstatus v0.24.0, zellij-autolock 0.2.2, room v1.2.1, monocle v0.100.2. All four verified to carry wasm magic `0061736d` and to match their recorded checksums at pin time.

## Gates

| Gate | Result |
|---|---|
| `theme-doctor` | **609 passed / 0 failed**, exit 0 |
| `theme-parity` | 1897 passed / 0 failed |
| `colour-lint` | 150 passed / 0 failed |
| `retirement-check --self-test` | 5 / 5 |
| `retirement-check tmux` | `failed_classes=0` |
| `zellij setup --check` | `[CONFIG FILE]: Well defined.` |
| `bash -n` on all three edited shell files | clean |

## NOT VERIFIED — the operator must check this

**Whether zjstatus actually renders in a live session is unproven.** This is the single most important line in this summary, because it is exactly the thing that failed last session by a different mechanism (the `plugins{}` alias path parsed clean and rendered nothing).

`zellij setup --check` reporting "Well defined" is **not** evidence — that same message was true last session while the bar rendered nothing. It validates `config.kdl` only, and never opens the layout.

Live probing was attempted and is impossible from the agent shell: it has no usable TTY. The baseline `zellij -s <name>` with no layout at all panics with `could not enable raw mode: Os { code: 6 ... "No such device or address"`, which proves the failure is environmental and not caused by the layout — but it also means nothing about the layout can be concluded from here either way.

**What to check in a real kitty window:** open zellij and confirm (1) the status bar is the zjstatus bar and not zellij's built-in one, (2) the powerline wedges are solid rather than tofu, (3) the mode indicator changes colour with mode, (4) a theme switch re-colours the bar live, (5) `Ctrl y` opens room and `Ctrl f` opens monocle, (6) opening `nvim` flips the session to LOCKED and leaving it restores NORMAL.

If the bar does **not** appear, the first thing to check is whether `default_layout "rice"` resolved — zellij falls back to its built-in bar silently, with no error, when a named layout fails to load.

## Findings worth keeping

**1. matugen parses the whole template, KDL comments included — and a literal doubled opening brace in a comment reports its error somewhere else entirely.**
Writing the doubled-brace delimiter inside backticks in a comment, as prose documenting the rule, opened an expression that never closed. matugen then reported `found '{' expected something else` at **line 63, column 49** — a completely innocent line 16 lines later, which rendered fine in isolation when tested on its own. Chasing the reported location was a dead end; the cause was the comment. The template now describes the delimiter in words and carries a warning not to add an example.

**2. Single braces are safe, which is the whole reason zjstatus is themeable here.**
Tested directly against matugen 4.1.0 rather than assumed: a template containing `{sess}#[fg={{colors.primary.default.hex}}]` renders to `{sess}#[fg=#a8c8ff]`. zjstatus's own `{session}`/`{mode}`/`{tabs}` placeholders survive templating untouched while the colours interpolate.

**3. `file:~/...` works, and an absolute path would have been a fresh-install bug.**
A rendered template cannot expand `$HOME`, so a baked-in `/home/aorus/...` would break every other machine — the same class as the relative-wallpaper-symlink fix. Confirmed from the installed binary, not docs: zellij 0.44.3 links shellexpand 3.0.0 and carries the string `Failed to shell expand plugin path:`.

**4. The blocking retirement tier armed 20 minutes earlier immediately caught this task twice.**
`mode_tmux` (a legitimate zjstatus styling slot) and an `install.sh` comment contrasting the new pinning with the old plugin manager both reintroduced the retired surface's name into scanned files, turning `theme-doctor` red. Both were removed rather than exempted: the compatibility mode exists to ease migration *away from* that surface, so styling it is dead weight, and the comment says the same thing without the name. Worth noting the gate paid for itself within the hour, and that the fix is to stop naming a retired surface, never to widen the allowlist.

**5. The `kdl` format could not be reused, by design.**
Its shared emitter exits non-zero when it finds no pairs — deliberately loud rather than a silent empty pass. A zjstatus layout has no `themes` node, so `kdl` would have failed. Rather than write a second extractor (the mirrored-regex drift that emitter exists to prevent), the emitter's container node became a parameter and `kdl-plugin` passes `plugin`. One emitter still serves both.

**6. zjstatus format strings are not hex, and that is fine — checked, not assumed.**
`theme-parity` only runs `contract_wellformed_color` on values matching `^#?[0-9a-fA-F]{6}$` or `^rgba?\(`, so a value like `#[fg=#a6adc8] {datetime} ` passes through the emptiness check and skips the colour check. The embedded hex is still covered by the raw template-leftover scan. Extractor yields 31 pairs on the rendered file.

## Deviations from the task as scoped

- **`default_layout` was flipped**, which D-08 had explicitly set as "deliberately unset". This was unavoidable — a layout that is never selected does nothing — and the superseding reasoning is recorded inline where D-08's note was.
- **Keybinds were added** to a file whose previous comment said "deliberately NONE". They are additive, clear nothing, and use keys verified unclaimed in zellij 0.44.3's defaults.

## Not done

- No live render verification (see above — blocked on the agent shell's missing TTY).
- The four `.wasm` files were copied into `~/.config/zellij/plugins/` on this host so the config is usable immediately; on any other machine `install.sh` fetches them.
