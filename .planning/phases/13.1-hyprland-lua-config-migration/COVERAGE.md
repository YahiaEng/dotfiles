No external API integration: this phase touches only the local Hyprland compositor's own Lua configuration API, shipped inside the already-installed `hyprland` package (type stub at `/usr/share/hypr/stubs/hl.meta.lua`), and the `hyprctl` IPC socket already present on this machine — no network service, external API, SDK, or credential is added or contacted.

## Why this phase trips the detector

The ROADMAP sentence "The actual Lua **API** is unverified" contains the noun `api`, which is what fires the deterministic api-coverage detector for this phase. That phrase refers to Hyprland's own local, in-process configuration API (the Lua config manager Hyprland 0.57 ships in place of hyprlang `.conf` parsing) — not an integration with any external, third-party, or network-reachable API.

## What this phase actually touches

- **Hyprland's Lua configuration API** — a local compositor-internal API exposed to `hyprland.lua` and the files it `require()`s, documented (partially) by the vendor-shipped type stub at `/usr/share/hypr/stubs/hl.meta.lua`. Verified empirically against the installed binary per D-15/13.1-CONTEXT.md, not assumed from documentation.
- **The `hyprctl` IPC socket** — a Unix domain socket already present on this machine, used read-only by `hypr-equivalence-check` (`-j getoption`, `-j binds`, `-j animations`, `version`) to prove pre/post-migration behavioural equivalence.

## What this phase does not add

- No new network endpoint, remote service, or third-party API client.
- No new credential, API key, or secret.
- No new package-manager dependency for API access — `hyprland` (already installed) already ships `lua`, the Lua config manager, the example config, and the type stub (`13.1-RESEARCH.md` §"Package Legitimacy Audit").

## Documented gate limits (13.1-03 Task 3 — normalized equivalence comparison)

`hypr-equivalence-check`'s `options.jsonl` comparison was changed from a
byte-exact `diff -u` to a normalized comparison keyed on `(option,
normalized_value)` — see `hypr/.config/hypr/scripts/hypr-equivalence-check`'s
`_compare_options_normalized` function for the implementation and its
header comment for the full rationale. This section records the gate's
resulting limits, honestly, alongside the pre-existing D-16
permission-grant limit already in `.hypr-baseline/MANIFEST.md`.

### Why: the problem this closes

`hyprctl -j getoption` reports a DIFFERENT JSON type-key NAME — and for
booleans, a different JSON TYPE — depending on whether the value was set
by the hyprlang parser or the Lua config manager, for the exact same
semantic value. Found live during 13.1-02's Task 1 end-to-end proof and
measured against the committed baseline in 13.1-02/13.1-03:

| hyprlang | Lua | Semantically equal? |
|---|---|---|
| `{"custom": "5 5 5 5"}` | `{"css": "5 5 5 5"}` | Yes — value string identical, only the JSON field NAME differs |
| `{"custom": "ffff79c6 ... 45deg"}` | `{"gradient": "ffff79c6 ... 45deg"}` | Yes — value string identical, only the JSON field NAME differs |
| `{"int": 0}` | `{"bool": false}` | Yes — same disabled state, but JSON field NAME **and type** both differ |

A plain `diff -u` over `options.jsonl` would report a spurious FAIL for
every record of these three shapes once the full config is Lua — measured
against the committed 46-record baseline: the 5 `custom` records all flip
to `css`/`gradient`, and most of the 22 `int` records holding 0/1 are
genuine booleans that will flip to `bool` — roughly 25-27 of 46 records
would FAIL with zero behavioural divergence behind them, at the Wave 7
flip (plan 13.1-08), turning the gate into noise an operator either
hand-audits every time or waves through.

### What the normalization does — and its one named assumption

`_compare_options_normalized` discards the type-key NAME entirely and
compares only `(option, normalized_value)`, folding booleans against
integers (`false ≡ 0`, `true ≡ 1`) so `{"int": 0}` and `{"bool": false}`
compare EQUAL while `{"int": 0}` vs `{"bool": true}` still FAILS. `set`
semantics are preserved exactly as before — compared by direct equality,
never normalized. A genuine value difference still FAILs and still names
the diverged key; a record whose shape is ambiguous (not exactly one
type-key besides `option`/`set`) is a hard FAIL (`sys.exit(2)`, never a
silent pass) — proven live (see 13.1-LUA-FINDINGS.md's "13.1-03 Task 3"
section for the exact fault-injection commands and output; unit-tested
directly against `{"int":0}` vs `{"bool":false}` [PASS], `{"int":0}` vs
`{"bool":true}` [FAIL], and a two-type-key malformed record [hard FAIL,
exit 2]).

**Named assumption, not a proof:** discarding the type-key and comparing
only the value string asserts that *the value string fully determines
compositor behaviour* — i.e. that `"ff6272a4 0deg"` rendered via the
`custom` backend and the same string rendered via the `gradient` backend
produce an identical composited border, and that hyprlang's `int 0/1`
convention and Lua's native `bool` are always interchangeable at every
consumption site. This is very likely true (both backends are the same
compositor's own internal representation, and the byte-identical value
strings observed during 13.1-02's Task 1 end-to-end proof support it) but
it is **not independently proven** — `custom` → `gradient` could in
principle mean Hyprland's rendering pipeline parses/consumes the value
differently internally despite an identical stringification, in a way
this JSON-level equivalence check cannot see. This is a named limit of
the gate, held alongside the pre-existing D-16 uncovered-permission-grants
limit: the Wave 7 operator should know the green light on `options.jsonl`
means "the reported values are string-identical after folding a known
cosmetic representation difference," not "the compositor's internal state
is bit-identical."

### binds.json and animations.json — checked, NOT the same class

Per this task's own instruction, `binds.json` and `animations.json` were
checked empirically (via `hypr-lua-harness`) for the same divergence
class before deciding whether to normalize them too.

**`animations.json`: NO divergence found.** Both the animation-leaf
records (`name`/`overridden`/`bezier`/`enabled`/`speed`/`style`) and the
bezier-curve records (`name`/`X0`/`Y0`/`X1`/`Y1`) have identical field
names and directly comparable values between a hyprlang-sourced and a
Lua-sourced capture — confirmed live by tuning a real `hl.animation()`/
`hl.curve()` pair through the harness and reading the leaf back
byte-comparable to a hand-authored equivalent (`"windows"` leaf:
`overridden: true, bezier: "motion-recheck", speed: 4.79`, exactly the
shape and value fidelity a hyprlang `animation =` line would produce).
**Left byte-exact** (`diff -u`, unchanged) — normalizing something that
isn't divergent would only hide a real future regression.

**`binds.json`: a DIFFERENT and MORE SEVERE divergence — not the same
class, so NOT normalized the same way.** Field NAMES are identical to the
hyprlang baseline (`locked`, `mouse`, `release`, `repeat`, `longPress`,
`non_consuming`, `auto_consuming`, `has_description`, `modmask`, `submap`,
`submap_universal`, `key`, `keycode`, `catch_all`, `description`,
`allow_input_capture`, `dispatcher`, `arg`) — no cosmetic type-key rename
of the kind `options.jsonl` had. But **every** Lua-registered bind's
`dispatcher` field reads back the fixed literal `"__lua"` (never `"exec"`,
`"movetoworkspace"`, etc.) and its `arg` field reads back an **opaque,
small-integer-string internal index** (`"5"`, `"7"`, ...) instead of the
actual command/argument text — confirmed live:

```
baseline (hyprlang): {"key": "Return", ..., "dispatcher": "exec", "arg": "uwsm app -- kitty.desktop"}
live (Lua):           {"key": "Return", ..., "dispatcher": "__lua", "arg": "5"}
```

This is not a discoverable-and-foldable cosmetic difference like
`custom`→`css` — there is no computable mapping from the opaque index
`"5"` back to the true command string through `hyprctl -j binds` alone (a
Lua dispatcher is a closure/dispatcher-object reference, not a
string-serializable value the C++ layer can introspect). **Per this
task's own instruction ("if they do not [suffer the same class], leave
them byte-exact and say so explicitly"), `binds.json` comparison is left
byte-exact — unchanged code.** This is flagged here prominently because
the consequence is more severe than what `options.jsonl` faced: **after
the Wave 7 cutover (plan 13.1-08), `hypr-equivalence-check`'s
`binds.json` section will FAIL on the `dispatcher`/`arg` line for
literally every one of this repo's ~80 binds — a 100% false-positive
rate on those two fields, not a 25-27/46 fraction.** This makes a raw
`binds.json` FAIL, by itself, **uninformative** post-cutover: it will
fire regardless of whether the port is correct. The Wave 7 operator MUST
NOT treat a `binds.json` FAIL as a real regression signal at that point
without manually diffing to confirm every differing line is confined to
the expected `dispatcher: "__lua"` / opaque-`arg` substitution on an
otherwise-identical `key`/`keycode`/`modmask`/flag set, with no other
field changed. **This is a genuine, newly-discovered gap this task did
not have the authorized scope to close** (closing it would mean either
inventing an unproven stable-index-to-command mapping, or adding a
functional test that actually invokes representative binds and observes
their effects rather than relying on JSON introspection) — assigned to
plan `13.1-08` (the live cutover plan), which already owns the equivalence
gate's final pre-flip run and is the natural place to decide how to
handle it (e.g. exempting `dispatcher`/`arg` into `uncovered.txt` with a
compensating functional smoke-test, mirroring the D-16 permission-grant
pattern already established in this file).
