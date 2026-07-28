# Deferred Items — Phase 13.1 (Hyprland Lua config migration)

Pre-existing issues discovered during 13.1-09's execution that are out of
this plan's scope (Scope Boundary rule: only fix issues directly caused by
this task's changes).

## 1. `hyprctl keyword` is a silent no-op on the Lua-config-managed compositor

**Found during:** 13.1-09, Task 2 live verification of `gaming-mode-toggle.sh`
("exercise the gaming-mode toggle both on and off" — the task's own
instruction).

**Symptom:** `gaming_mode_on()`'s four eye-candy-disable calls
(`hyprctl keyword decoration:blur:enabled 0`, `animations:enabled 0`,
`decoration:shadow:enabled 0`, `decoration:rounding 0`) each print `keyword
can't work with non-legacy parsers. Use eval.` and — critically — still
**exit 0**, so the script's own `2>/dev/null || true` guard never even
triggers (the message is not being suppressed; the command simply reports
success while doing nothing). Confirmed directly on the CLI, independent of
this script entirely:

```
$ hyprctl keyword decoration:blur:enabled 0
keyword can't work with non-legacy parsers. Use eval.
$ echo $?
0
```

Toggling gaming mode ON, reading the four options back via `hyprctl
getoption`, and toggling it OFF again shows the values never actually
changed (`decoration:blur:enabled` stayed `true`, `decoration:rounding`
stayed `12` throughout) — gaming mode's core eye-candy-disable function is
non-functional on this Lua-cutover session. The idle-inhibit
(`pkill -STOP hypridle`), waybar-hide, and state-file mechanisms are
unaffected and still work; only the four `hyprctl keyword` calls are dead.

**Root cause — confirmed independent of this plan's own changes:** this is
a global consequence of 13.1-08's cutover to `hyprland.lua`, not something
13.1-09 introduced. `hyprctl keyword` is Hyprland's classic runtime-option
mutator, built for the hyprlang ("legacy") config parser; a Lua-config
session rejects it outright ("Use eval") regardless of which script issues
it or which file that script reads its restore-values from — reproduced
from a bare, unrelated CLI invocation with zero connection to
`gaming-mode-toggle.sh`'s own retargeted `_restore_keyword` function (the
actual scope of 13.1-09's Task 2 edit).

**Why not fixed here:** 13.1-09's Task 2 scope is retargeting
`gaming-mode-toggle.sh`'s COLOUR/VALUE READ-BACK source (from
`~/.local/state/theme/hyprland.conf` to `hyprland-tokens.lua` via
`lib/contract.sh`'s `lua-table` extractor) — a file-format swap. The
`hyprctl keyword` calls in `gaming_mode_on()`/`gaming_mode_off()` are a
DIFFERENT mechanism (the compositor IPC verb used to apply/restore values),
untouched by this plan's `<files>` list and unrelated to which file the
restore read-back parses. Fixing the compositor-IPC mechanism (likely:
replacing every `hyprctl keyword <key> <value>` with the Lua-config `eval`
verb the error message itself names, or an `hl.set(...)`-shaped call) is a
distinct architectural question — which verb, what argument shape, whether
it needs a source-level `keybinds.lua`-style Lua expression per key — that
this plan was not scoped to research or decide. Per the deviation rules'
Scope Boundary, this is logged rather than fixed.

**Verification this plan's own acceptance criteria still hold despite the
gap:** the toggle script itself completes without a nonzero exit or a
crash (`gaming_mode_on`/`gaming_mode_off` both exit 0 throughout, matching
"completes without error" read at the script level), and the actual scope
of this task — the colour/value READ-BACK from `hyprland-tokens.lua` via
`_restore_keyword`/`contract_extract_values` — is proven correct and
unchanged from the pre-migration behaviour: it still finds nothing (by
design — none of the four `decoration:*`/`animations:*` keys exist in
either the retiring `hyprland.conf` fragment or the new merged token
table), and the OFF path still correctly falls through to `hyprctl
reload` (which DOES work under a Lua session, confirmed: prints `ok`,
exit 0, and correctly re-establishes the compositor's actual on-disk
config state).

**Recommendation for whoever picks this up:** update `gaming_mode_on()`/
`gaming_mode_off()`'s four `hyprctl keyword` calls to whatever verb
Hyprland's Lua config manager accepts for a one-off runtime mutation
(the error text names `eval` — needs its own research pass into the exact
CLI/IPC shape, since this repo's own `keybinds.lua` header comment
documents that `hyprctl dispatch` under Lua expects a Lua *expression*
argument rather than the classic `dispatcher,args` string, and `eval` may
carry an analogous, undocumented shape requirement). Likely candidates for
research: `hyprctl keyword --eval ...`, `hyprctl eval '<lua>'`, or a
config-reload-based alternative that doesn't depend on a raw keyword verb
at all.
