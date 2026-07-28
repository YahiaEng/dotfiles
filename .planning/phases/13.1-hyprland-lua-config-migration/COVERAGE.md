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
string-serializable value the C++ layer can introspect). At the time
13.1-03 wrote this section, `binds.json` comparison was left byte-exact
(unchanged code) and the gap was handed to plan `13.1-08`. **13.1-04
Task 3 (a second authorized scope addition, reassigned from 13.1-08 by
the orchestrator — see the section immediately below) closes this gap
early, before the Wave 7 flip inherits a 100%-false-positive-rate binds
gate.**

## Binds equivalence: two-half proof (13.1-04 Task 3 — authorized scope
## addition)

**Why reassigned here, not left for 13.1-08:** (a) 13.1-04 is the plan
that ports all 80 binds, and the plan that ports them should carry the
proof they are right; (b) 13.1-08 is the live-cutover plan — designing
verification machinery mid-flip is the wrong time; (c) 13.1-09 (which
retargets `keybind-doctor`) runs AFTER the flip and so cannot serve as
pre-flip verification. Full rationale in `13.1-04-PLAN.md`'s authorized
scope addition.

Because `hyprctl -j binds` cannot introspect a Lua bind's `dispatcher`/
`arg` (the finding above), the binds equivalence proof is split into two
independently-provable halves:

### Half 1 — structural (compositor-level, all 80 binds, byte-exact)

`hypr-equivalence-check`'s `binds.json` comparison now runs
`_compare_binds_structural` (not a raw `diff -u`): every field EXCEPT
`dispatcher`/`arg` is compared byte-exact, per-record, in order. A
dropped bind, a wrong modmask, a wrong key, a changed flag, or a changed
submap still FAILs and still names the offending bind by index + key.
The only narrow, explicitly-named tolerance is `keycode` for the four
`code:NNN` physical-keycode binds (baseline `107`, live `0` — the
separate, already-documented 13.1-03/13.1-04 serialization gap; every
OTHER bind's `keycode` must still match exactly, including the 76
symbolic binds whose baseline `keycode` is `0`).

**Proven live against a real Lua-booted binds.json** (not just the
trivial live-hyprlang-vs-baseline case, which would never exercise the
new code path): `_compare_binds_structural` run directly against the
committed baseline and a `hypr-lua-harness`-captured Lua `binds.json`
produced exactly **two** FAILs, both on the SAME already-tracked field:

```
! record 68 (key='mouse:272' keycode=0 arg='movewindow'): field 'mouse' baseline=True live=False
! record 69 (key='mouse:273' keycode=0 arg='resizewindow'): field 'mouse' baseline=True live=False
```

Every other structural field on all 80 records matched exactly.

**D-10 fault-injection proof (the check can fail, and names the offending
bind):** run directly against two deliberately corrupted copies of the
committed baseline itself:

```
# modmask altered on one record
! record 0 (key='Return' keycode=0 arg='uwsm app -- kitty.desktop'): field 'modmask' baseline=64 live=999
exit=1

# a bind dropped (shifts every subsequent record by one — the check
# correctly reports the count mismatch AND names every resulting
# positional field disagreement, rather than silently passing)
! bind count mismatch: baseline=80 live=79
... (79 further named field disagreements)
exit=1

# control: baseline vs itself (unaltered)
exit=0
```

This `mouse` divergence (documented below) is deliberately **NOT** given a
`keycode`-style carve-out — the task's own instruction was explicit ("no
loosening"), and unlike `keycode` (a well-understood, narrowly-scoped
serialization artifact confirmed not to indicate a functional problem),
whether `{mouse=true}` actually has any runtime effect is **NOT
MECHANICALLY VERIFIABLE** with tooling available in this environment (see
below). A real, currently-failing check on an unresolved question is the
correct, honest outcome here — silently tolerating it would defeat the
"no loosening" instruction's purpose.

### Half 2 — command-attachment (source-level, deterministic)

`hypr/.config/hypr/scripts/keybind-source-equivalence` statically parses
`(mods, key, dispatcher, arg)` out of BOTH `keybinds.conf` (hyprlang) and
`keybinds.lua` (the port), using the same parsing APPROACH `keybind-doctor`
already established (regex over declaration lines, `$variable`
resolution before mod/key extraction) — never retargeting
`keybind-doctor` itself. The Lua side resolves `local` string variables,
`..`-concatenated key-string expressions, and a mapping table from every
`hl.dsp.*` dispatcher-factory call shape this repo uses back to the
`(dispatcher, arg)` pair `hyprctl -j binds` shows for the hyprlang
equivalent — including `bindm`'s own internal transformation (hyprlang
registers a `bindm = ..., movewindow` line as `dispatcher: "mouse", arg:
"movewindow"`, confirmed against the committed baseline; the Lua side's
`hl.dsp.window.drag()` is mapped to the same `("mouse", "movewindow")`
pair for a fair comparison). An unrecognised dispatcher-call shape is a
**hard failure**, never a silent pass — this gate cannot vouch for a bind
shape it does not recognise.

**Proven live:**

```
$ hypr/.config/hypr/scripts/keybind-source-equivalence
PASS: all 80 binds match on (mods, key, dispatcher, arg) between keybinds.conf and keybinds.lua
```

**Proven able to fail (self-test, per this task's own instruction — "a
gate that cannot fail is not a gate"):** run three times against a
deliberately corrupted copy of `keybinds.lua`, each time confirming the
gate FAILs and names the exact offending bind:

1. **Changed `exec` arg** (`theme-switch.sh` → `CORRUPTED.sh`): FAIL,
   correctly reports the `T` bind present-with-different-arg on both
   sides.
2. **Dropped bind** (the `N` / notification-toggle bind deleted
   entirely): FAIL, correctly reports both a bind-count mismatch
   (80 vs 79) and the missing `N` bind by name.
3. **Dropped modifier** (`SUPER + SHIFT + Q` → `SUPER + Q`): FAIL,
   correctly reports the `modmask=65` tuple missing and a spurious
   `modmask=64` tuple present instead.

All three runs used explicit path arguments (`keybind-source-equivalence
<conf-path> <corrupted-lua-path>`), mirroring `keybind-doctor`'s own
explicit-path self-test convention — the real repo files were never
mutated during this proof.

### What a green `hypr-equivalence-check` binds result DOES and DOES NOT
### prove — read this before trusting it (Wave 7 operator)

| Claim | Proven by | Proven how |
|---|---|---|
| All 80 binds are present, none dropped, none added | Half 1 (structural) + Half 2 (source-level, bind-count check) | Both independently assert count == 80 |
| Every bind's modmask/key/submap/flags match the pre-migration original | Half 1 (structural) | Byte-exact `hyprctl -j binds` comparison, live |
| Every bind's dispatcher+argument TEXT matches the pre-migration original | Half 2 (source-level) | Static parse + tuple diff, proven able to fail |
| The four `code:NNN` binds' `keycode` field will read `0`, not `107`, post-cutover — this is expected, not a regression | Documented tolerance in Half 1 | 13.1-03 finding, narrowly carved out |
| The two `bindm` binds' `mouse` field will read `false`, not `true`, post-cutover — Half 1 legitimately FAILs on this | Documented, NOT resolved | See "Open item" below |
| A Lua-registered dispatcher call ACTUALLY FIRES THE SAME RUNTIME BEHAVIOUR as the hyprlang original (not just the same source text) | **NOT proven by either half** | Half 2 proves source-level intent, not runtime execution. 13.1-04 Task 2 separately proved several dispatcher shapes behaviourally via `hyprctl dispatch` against a real client (fullscreen, resize, float, kill, move-focus) — see `13.1-LUA-FINDINGS.md`. This coverage is real but partial, and does not extend to every one of the 80 binds. |
| Destructive/irreversible binds behave identically | **NOT proven by any automated check** | See "Irreversible/destructive binds" below — requires manual confirmation |

**Open item — `{mouse=true}` bind option:** the vendor-example shape
(`/usr/share/hypr/hyprland.lua` lines 290-291) is used verbatim for both
`bindm` ports, but `HL.BindOptions` does not list `mouse` as a member,
`hl.bind`'s opts table has no field validator, and no evdev/uinput
mouse-button injection tool was available in this environment to
behaviourally confirm drag-move/drag-resize actually work. This is a
real, currently-failing structural-check outcome on exactly two records
(`mouse:272`/`mouse:273`) — the Wave 7 operator should expect
`hypr-equivalence-check` to report this specific FAIL and should NOT
treat it as a new regression; it is the same open item this task itself
could not close, carried forward with a physical compensating check
below.

### Irreversible/destructive binds requiring manual functional
### confirmation (not provable by source-level equality)

Source-level equality proves the bind's TEXT matches; it does not prove
the command still BEHAVES identically once dispatched through the Lua
closure mechanism. The following binds are not trivially undoable if
something is subtly wrong, and MUST be physically exercised by the Wave 7
operator before trusting the cutover, beyond what any automated gate
checks:

- **`Super+Shift+Q`** → `wleave.sh` — opens the power menu, the gateway
  to shutdown/reboot/logout. The bind itself is reversible (closing the
  menu), but a malfunction here is the path to an actually irreversible
  session-ending action.
- **`Super+Q`** → `killactive` — closes the focused window immediately,
  with no confirmation; potential data loss in an application with
  unsaved state.
- **`Super+L`** → `hyprlock` — locks the screen. Reversible via password
  entry under normal operation, but this repo has prior incident history
  with hyprlock option regressions (`04-REVIEW.md` FIX-02) — a
  misconfigured lock screen is a session lockout risk, not merely a
  cosmetic bug.
- **`Super+Shift+C`** → `clipboard-wipe.sh` — destructively wipes
  clipboard history (the script itself carries a default-No confirmation
  per D-15, but the confirmation prompt firing correctly through a
  Lua-dispatched `exec` call has not been independently verified here).

None of these are exempted from any automated check above — they are
covered by both halves of the binds proof like every other bind. This
list exists because, for these four specifically, a subtle runtime
divergence that both halves miss (source-text-correct but
behaviourally-wrong) has a materially worse worst case than for the other
76 binds, so they warrant deliberate manual confirmation rather than
being folded silently into the general "press every bind once" sweep.

## Window-rule `size` field: percentage form does not apply (13.1-07 Task 1
## — genuine functional gap, not a verification-channel limitation)

Every prior "NOT MECHANICALLY VERIFIABLE" entry in this document and in
`13.1-LUA-FINDINGS.md` is a case where the underlying feature is believed
to work but no `hyprctl` JSON surface exists to observe it. This entry is
different in kind: the runtime channel DOES exist (`hyprctl clients -j`'s
`.size` field), it WAS observed, and it shows the feature does not take
effect.

**Finding:** `hl.window_rule({..., size = "<N>% <N>%"})` registers with
zero `configerrors` on this installed Hyprland 0.56.1 Lua config manager,
but has **no runtime effect** — a matching window opens at its own
client-preferred size (e.g. plain kitty's built-in default, or whatever
`initial_window_width`/`height` the launch script sets) instead of the
requested percentage of the monitor. Six variant spellings were tried live
against a nested `hypr-lua-harness` instance, isolating the cause to the
literal `%` character: `"70% 65%"`, `"70%,65%"`, `{ "70%", "65%" }`,
`{ w = "70%", h = "65%" }`, `"70%w 65%h"`, and a mixed token
`"70% 333"` — **all six** fell back to the client's own size with zero
`configerrors`. By contrast, the plain-pixel string form
(`size = "444 333"`) and even a malformed non-percent string
(`size = "0.7 0.65"`, which the parser silently truncated to `[1, 0]` via
naive integer conversion rather than treating as a fraction) both
**visibly changed** the client's reported size — proving the `size` field
mechanism itself is live and that the pixel-string path works correctly;
only the `%`-suffixed token is rejected outright, with the whole field
silently ignored rather than partially applied or erroring.

**Affected rules (6 of 30 in `windowrules.lua`):** `wallpaper-picker`,
`icon-theme-picker`, `font-switcher`, `network-manager`, `cheat-sheet`
(all `"85% 85%"`), and `yazi-fm` (`"70% 65%"`). Checked: none of these six
rules' launcher scripts (`wallpaper-switch.sh`, `icon-theme-switch.sh`,
the equivalent font/network/cheat-sheet launchers, and the `yazi-fm`
keybind in `keybinds.lua`) pass an explicit `-o initial_window_width`/
`initial_window_height` kitty override — every one of them relies
entirely on the windowrule's `size` property, so this is not a
lower-severity redundant safety net; it is the only sizing mechanism these
six windows have.

**Disposition (fix-attempt limit reached, Rule 3 exclusion does not
apply, Rule 1 auto-fix scope does not cover an event-driven mechanism
change):** the literal `"85% 85%"`/`"70% 65%"` strings are kept
byte-identical to `windowrules.conf` in `windowrules.lua` — not rewritten
into pixel values or an `hl.on("window.open", ...)` event-driven
workaround, both of which would be a materially different implementation
mechanism than the plan's declarative-rule scope authorizes without a
human decision. This is a genuine, previously-undocumented regression
relative to the currently-live hyprlang session (where this repo's own
`.conf` comments and years of production use imply the percentage form
does work) — **not** a cosmetic verification-channel gap like the
`opacity`/`no_blur`/animation-style entries above.

**Handoff to 13.1-08 (cutover plan):** before or immediately after
flipping `hyprland.lua.disabled` live, the Wave 7 operator MUST visually
confirm whether these six windows open at the intended
85%/70%-of-monitor size. If the gap reproduces on the real session (not
just the nested harness), 13.1-08 needs to either (a) implement a working
compensating mechanism (most likely an `hl.on("window.open", ...)`
listener that queries the matched window's monitor and issues an absolute
resize, replacing the inert declarative `size` string for these six rules
only), or (b) accept the regression as a known, documented cosmetic
issue and file it for a later Hyprland-Lua-version bump to reassess. Not
silently declaring green either way — this is now a named, tracked gap,
not an assumption.

**Correction (post-commit, caught by orchestrator spot-check, fixed in
`fe73aa3`):** the "Disposition" paragraph above states the percentage
strings were "kept byte-identical to `windowrules.conf`" as the plan's
intent — that intent was correct, but the FIRST commit of this file
(`46396de`) did not actually match it: the `yazi-fm` rule's `size` field
was accidentally left set to `"70%w 65%h"`, one of the six experimental
spellings tried during this very investigation, instead of the intended
byte-identical `"70% 65%"`. This was not caught by this plan's own
verification, because that verification compared regex patterns and
property names/counts, never property VALUES. An orchestrator spot-check
caught it; it is now fixed and a genuine property-value-level comparison
(all 43 rules, 68 property-value pairs, parsed from both `.conf` and
`.lua` and diffed positionally) confirms 0 remaining mismatches. The
functional conclusion in this section — the `%` form is inert either
way, on both the wrong and the corrected spelling — is unchanged by this
fix; only the earlier "byte-identical" claim needed correcting, and it
now genuinely holds. See `13.1-07-SUMMARY.md`'s "Correction" section for
the full writeup.
