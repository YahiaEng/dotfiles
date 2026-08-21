---
phase: quick-260821-swp
plan: 01
type: execute
wave: 1
depends_on: []
autonomous: false
requirements: [D-01, D-02, D-03, D-04]

files_modified:
  # ── Data ────────────────────────────────────────────────────────────
  - theme-engine/.config/theme-engine/motion.json
  - theme-engine/.config/theme-engine/contract.json
  # ── Renderer + CLI ──────────────────────────────────────────────────
  - theme-engine/.config/theme-engine/lib/motion.sh
  - hypr/.config/hypr/scripts/motion-switch.sh
  - stow.sh
  # ── Consumers ───────────────────────────────────────────────────────
  - hypr/.config/hypr/config/animations.lua
  - quickshell/.config/quickshell/modules/Motion.qml
  - quickshell/.config/quickshell/modules/settings/pages/WindowManagerPage.qml
  - quickshell/.config/quickshell/modules/settings/RowIndex.qml
  - quickshell/.config/quickshell/modules/dashboard/Cascade.qml
  - quickshell/.config/quickshell/modules/dashboard/WifiPanel.qml
  - quickshell/.config/quickshell/modules/dashboard/AudioPanel.qml
  - quickshell/.config/quickshell/modules/dashboard/QuickToggles.qml
  - quickshell/.config/quickshell/modules/Dashboard.qml
  # ── Gates ───────────────────────────────────────────────────────────
  - hypr/.config/hypr/scripts/motion-lint
  - hypr/.config/hypr/scripts/hypr-equivalence-check

estimate:
  tokens: 110000
  raw_tokens: 55000
  tasks: 3
  confidence: low

must_haves:
  truths:
    - "The settings window's Animation section offers five named animation styles, not a speed scale (D-01, D-03)."
    - "Switching style visibly changes window entry shape, workspace transition shape, easing curve and duration on both the compositor and the shell (D-02)."
    - "Reduce-motion and animations-off are reachable from a control that is not the style picker (D-01)."
    - "An existing install holding a legacy scale value keeps a working, themed desktop across the upgrade with no manual step."
    - "Adding a sixth style requires editing motion.json only — no QML, Lua or shell change (D-04)."
    - "hypr-equivalence-check reports PASS under every style, and reports which values it normalized rather than staying silent."
  artifacts:
    - theme-engine/.config/theme-engine/motion.json          # gains .styles + .accessibility
    - ~/.local/state/theme/motion-style                       # new state file
    - ~/.local/state/theme/motion-accessibility               # new state file
    - hypr/.config/hypr/scripts/motion-switch.sh              # style + accessibility CLI
  key_links:
    - "motion.json .styles -> lib/motion.sh effective-merge -> hyprland-tokens.lua motion.curves + motion.hypr_style -> animations.lua leaves"
    - "motion.json .styles -> lib/motion.sh -> ~/.local/state/theme/motion.json -> Motion.qml aliases -> 133 unchanged easing.bezierCurve call sites"
    - "motion-switch.sh --list -> WindowManagerPage.qml SelectRow parser (format and parser change together)"
    - "active style -> hypr-equivalence-check expected-curve/expected-leaf derivation (gate must track the renderer)"
---

<objective>
Replace the motion **scale** axis (a duration multiplier) with an animation **style** axis
(`md3`, `smooth`, `snappy`, `bouncy`, `wavy`), where each style owns its own easing curves,
durations and Hyprland window/workspace entry shapes — defined as a `styles` data table in
`motion.json`. Move reduced-motion and animations-off onto a separate accessibility axis.

Purpose: today the only user-facing motion control is intensity. Animation *shape* is fixed
MD3 and cannot vary at all. This makes shape the user-facing setting, as a pure data table,
so the slate can grow without touching code.

Output: two new state axes, a five-entry `styles` table, a style-aware renderer, a
style-aware equivalence gate, and a relabelled settings control.
</objective>

<execution_context>
@$HOME/.claude/gsd-core/workflows/execute-plan.md
@$HOME/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/quick/260821-swp-replace-the-motion-scale-axis-reduced-no/260821-swp-BRIEF.md
@.claude/CLAUDE.md

Read only the ranges you need — these are large files:
@theme-engine/.config/theme-engine/lib/motion.sh
@hypr/.config/hypr/scripts/motion-switch.sh
@hypr/.config/hypr/config/animations.lua
@quickshell/.config/quickshell/modules/Motion.qml
</context>

<decisions_resolved>

These three were left open for the plan. They are now settled. Do not re-open them.

## R-1 — The slate is BEZIER-ONLY. No springs.

**Decision:** all five styles are expressed as cubic beziers on both targets. Hyprland springs
are not used.

**Why — measured, not assumed.** The BRIEF proved Hyprland accepts overshoot beziers and reads
them back (`Y1:1.15`). This plan additionally measured the Qt side headlessly on the installed
Qt 6.11.2 via PySide6's `QEasingCurve` under `QT_QPA_PLATFORM=offscreen` (no window opened, no
compositor involved — the `qml6` probe hazard does not apply):

```
BezierSpline, control points (0.15, 2.2) and (0.6, 0.4), endpoint (1.0, 1.0)
  -> peak 1.1295, dips to 0.8702 after the peak, settles to exactly 1.0
BezierSpline, control points (0.1, 0.9) and (0.4, 1.254)
  -> peak 1.0801
```

So `Easing.BezierSpline` accepts control-point Y outside [0,1] and produces genuine
overshoot **and** undershoot. `wavy` is therefore a real overshoot-then-undershoot curve, not
an approximation — one wave, not a multi-cycle oscillation. `easeOutBounce` stays out of scope
exactly as the BRIEF says.

**What the gate can see afterwards — stated plainly:**

- `hyprctl animations -j` reports `X0/Y0/X1/Y1` for every registered curve. Because the slate
  is bezier-only, **100% of the curve change a style makes is visible to
  `hypr-equivalence-check`.** Nothing is hidden behind a spring the gate structurally cannot
  read. This is the whole reason springs are rejected.
- Each leaf record also carries a `style` string, which the gate already reads. Under this
  design a leaf's `bezier` **name** never changes (only the control points behind the name do),
  so the gate sees the full picture through two channels it already has.
- **What it still cannot see:** anything QML-side (that is `motion-lint`'s surface, unchanged),
  and *how the motion feels*. Curve identity is not character. Hence Task 3's operator pass —
  which is a gate, not a formality.

**Critical finding this plan adds to the BRIEF.** `hypr-equivalence-check`'s `_compare_animations`
compares leaf records **byte-exact positionally**, forgiving only the case where `speed` is the
**sole** differing field (`speed_is_scaled_equivalent`, ~line 965). Curves are compared as a set
of `(name, X0, Y0, X1, Y1)` tuples against the committed baseline. Both were captured under
today's MD3 values. **Any non-`md3` style therefore hard-FAILs this gate today** — on the
changed `style` string *and* on the changed control points. Task 2 extends the gate; leaving it
to fail or scoping it to `md3` only is not an option.

## R-2 — `Motion.qml` does NOT gain an easing-type indirection. All 133 call sites stay untouched.

**Decision:** because R-1 keeps every style a bezier, `Motion.<x>Easing` keeps returning the
same six-element control-point array it returns today, and the 133
`easing.type: Easing.BezierSpline` + `easing.bezierCurve: Motion.<x>Easing` sites are
**byte-unchanged**. No `Motion.standardEasingType` property is introduced; the
`Design.barDrawerEasingType` precedent is deliberately **not** followed here.

Consequence that makes this work: a style overrides the **control points behind an existing
easing name**. It may never introduce a new easing name. Names are invariant across styles —
which is also what keeps the curve-name set stable for R-1's gate story and keeps `animations.lua`'s
`bezier =` arguments unchanged.

**Spatial-vs-effects split (MD3 Expressive, per the BRIEF).** Overshoot must never land on a
fade. Only these two easing names may carry control-point Y above 1.0:

- `emphasized-decelerate` — Hyprland: `windowsIn`, `layersIn`, `workspaces`, `specialWorkspace`
  (all spatial entry). QML: `Motion.emphasizedInEasing`.
- `emphasized-accelerate` — Hyprland: `windowsOut`, `layersOut` (spatial exit). Overshoot on an
  exit is allowed by the schema but no shipped style uses it.

Every other easing name — `standard`, `standard-decelerate`, `standard-accelerate`, `legacy*`,
`linear`, `css-linear` — stays monotonic within [0,1] in every style. `standard-decelerate` and
`standard-accelerate` drive Hyprland's `fadeIn`/`fadeOut`; `linear` drives `border`/`borderangle`.

This leaves one real hazard: `Motion.emphasizedInEasing` is currently used at a handful of QML
sites that animate a fade rather than a position. Those sites are enumerated and retargeted in
Task 2.

## R-3 — Reduced-motion lives in a second STATE FILE, not in Prefs and not in a retained scale.

**Decision:** a new `~/.local/state/theme/motion-accessibility` file holding one of
`full` | `reduced` | `off`, backed by a new `accessibility` table in `motion.json` carrying
exactly the `{multiplier, animations_enabled}` shape `scales` carries today.

**Why not Prefs:** `Prefs` is QML-owned and `watchChanges:false`. The renderer is shell-side and
must read this value at `theme-apply` time; routing it through Prefs would put a shell reader
inside a QML-owned file and force a shell restart for a value the compositor consumes.

**Why not a retained scale axis:** keeping a four-value scale the UI no longer surfaces leaves
`normal`/`lively` alive as dead keys and invites drift.

**Why a state file wins:** it is the identical shape the three existing theme-orthogonal axes
already use (`font-choice`, `icon-theme`, and the axis being replaced), so `stow.sh` seeding,
`contract.json` ownership, atomic tmp+mv writes and the closed-set reader discipline all carry
over verbatim. Crucially it preserves the existing `multiplier` / `animations_enabled` plumbing
**below the read** with zero change: `motion_multiplier` keeps its meaning, `Motion.ambientDuration`'s
divide-the-multiplier-back-out logic is untouched, and the equivalence gate's scaled-speed
forgiveness needs a one-line retarget rather than a rewrite.

`lively` (1.25x) has no home in the new model — the multiplier axis is absorbed by per-style
durations (D-01). Migration maps it to `md3` + `full`; that is a deliberate, stated loss.

</decisions_resolved>

<tasks>

<task type="tracer">
  <name>Task 1: Split the axis end-to-end with ONE style whose numbers are today's numbers</name>
  <files>
    theme-engine/.config/theme-engine/motion.json,
    theme-engine/.config/theme-engine/lib/motion.sh,
    theme-engine/.config/theme-engine/contract.json,
    hypr/.config/hypr/scripts/motion-switch.sh,
    hypr/.config/hypr/config/animations.lua,
    quickshell/.config/quickshell/modules/Motion.qml,
    quickshell/.config/quickshell/modules/settings/pages/WindowManagerPage.qml,
    quickshell/.config/quickshell/modules/settings/RowIndex.qml,
    hypr/.config/hypr/scripts/motion-lint,
    stow.sh
  </files>
  <precondition>The Quickshell shell process is running and `~/.local/state/theme/current-theme` holds a theme name, so `theme-apply` has something to re-render.</precondition>
  <action>
Wire the whole new axis through every layer with exactly ONE style defined — `md3` — whose
resolved output is byte-identical to today's. This is the thin slice that proves the rename,
the split and the migration are behaviour-preserving before any new curve value exists.

**motion.json.** Add two top-level objects. Keep `durations`, `easings`, `semantic`,
`indicators`, `floor_ms` exactly as they are. Remove `scales`.

- `accessibility`: `full` = multiplier 1.0 / enabled true; `reduced` = 0.5 / true;
  `off` = 1.0 / false. Same two-field shape the removed table used, so every downstream
  arithmetic path is unchanged.
- `styles`: a single entry `md3` with `label` (a human display string), `description`,
  an empty `easings` override object, an empty `semantic` override object, and a `hypr_style`
  object with the five keys `windows_in`, `windows_out`, `windows_move`, `workspaces`,
  `special_workspace` carrying today's literals from `animations.lua` verbatim.

Record in a JSON comment key that this reinstates, as a user-facing setting, the kind of
per-style curve data plan 13-07 removed as a measuring instrument, and that TOKEN-06's
"spring is too fast" was a tuning verdict rather than a mechanism verdict — so the reversal is
intentional and on the record (BRIEF, "Why this reverses a prior removal").

**Schema invariants (enforce in validation, below).** A style's `easings` override keys must be
a subset of the base `easings` keys — a style may change control points behind a name, never
introduce a name (R-2). A style's `semantic` override keys must be a subset of base `semantic`
keys, and each override's duration/easing must resolve against the base tables. `hypr_style`
values reach Hyprland's parser, so each must match a strict pattern of lowercase letters
optionally followed by a space and a one-to-three digit percentage — ASVS V5, mirroring the
existing palette-name validation posture.

**lib/motion.sh.** Four changes, in this order:

1. Add `theme_engine_migrate_motion_state`. Idempotent: returns immediately when the style state
   file already exists. Otherwise, if the legacy scale file exists, map its value —
   the disabled value to accessibility off, the halved value to accessibility reduced,
   everything else to accessibility full — writes `md3` as the style in every case, writes both
   new files with the existing tmp+mv atomic idiom, then removes the legacy file. With neither
   file present it seeds the two defaults. Derive every path from the module-level path
   variables (never a hardcoded `$HOME/...` inside the function body) so the verify below can
   point it at a scratch directory.
2. Replace the closed-set reader with two readers: one for style (valid set derived from the
   keys of `.styles`, defaulting to `md3`) and one for accessibility (closed `case` over the
   three literal values, defaulting to full). Both call the migration first.
3. Build an **effective** motion document once per render: base document with `easings` and
   `semantic` shallow-merged with the active style's override objects. Write it to a temp file
   and repoint every existing `jq ... "$MOTION_JSON"` call in the render/validate/emit paths at
   that effective file. One merge point, so no two writers can disagree. `theme_engine_render_hypr_tokens`
   and `theme_engine_render_motion_scss` read it too (they already inherit the caller's locals
   by dynamic scoping — extend that, do not add a second read of the raw document).
4. Emit two additions. In `hyprland-tokens.lua`, a `motion.hypr_style` sub-table with the five
   keys, values written through `_hypr_lua_quote_string` — that quoting writer is the only path
   any string may reach Lua source through. In the QML `motion.json` target, replace the
   `motion_scale` top-level key with `motion_style` and add `motion_accessibility`.
   `motion_multiplier`, `motion_enabled`, `semantic`, `indicators` and `floor_ms` keep their
   current names, shapes and arithmetic.

Extend `theme_engine_validate_motion_values` with the four `styles` invariants above plus a
check that the active accessibility entry carries both fields. Same validate-before-any-write,
diagnose-to-stderr, return-non-zero discipline as the existing checks.

**motion-switch.sh.** Delete the hand-duplicated reader and instead source `lib/motion.sh` for
its readers and its migration — the file's own header already warns that drift between the two
copies would be a bug, and sourcing removes that hazard permanently (the library defines only
constants and functions at top level, so sourcing has no side effects). Retarget preset
validation from the removed table to `.styles` keys. Add an `--accessibility <value>` flag taking
one of the three values and writing the second state file, then triggering the same single
`theme-apply` entrypoint — never a second render path. Change `--list` to emit one style per
line as two tab-separated fields, key then label, under a header line, and add
`--list-accessibility` for the parallel axis. `--get` returns the style; `--get-accessibility`
returns the accessibility value.

**animations.lua.** Replace the five hardcoded window/workspace `style =` literals with reads
from `tokens.motion.hypr_style.<key>`, each guarded so a nil token omits the field entirely
rather than substituting a literal — the same explicit-nil-test discipline the file already
applies to `motion_enabled`, and the same reason: a boolean-or default silently re-enables what
a token deliberately turned off. Leave `borderangle`'s loop style hardcoded — it is a mechanism,
not a look. Leave all three `layers*` leaf styles hardcoded: the BRIEF probed valid style strings
for the windows and workspaces families only, so the layers family is out of scope for variation.
Every `bezier =` argument stays exactly as it is.

**Motion.qml.** Rename the two `JsonAdapter` bindings to match the renderer's new key names
exactly — `JsonAdapter` maps top-level keys by exact name with no case conversion, and this repo
has already shipped the silent-default bug that mismatch causes. Add `motionStyle` and
`motionAccessibility` read-only aliases and update the one existing `Motion.motionScale`
reference. `_pairNames` is untouched — no new semantic key is added, so its positional read
stays valid. Every alias, fallback and the `ambientDuration` divisor logic are unchanged.

**motion-lint.** In `load_qml_defs` (~line 290), derive `motionStyle` and `motionAccessibility`
from the presence of their top-level keys in the rendered file, exactly as `motionEnabled` and
`motionMultiplier` are already derived — never a hardcoded name that can drift from the data.

**WindowManagerPage.qml + RowIndex.qml.** The `--list` format and its parser change together.
Retarget the parser regex to the new tab-separated shape, using field one as the value and
field two as the display label. Relabel the row to name a style rather than a speed, and rewrite
its subtext accordingly. Replace the InfoRow — which exists only to explain the absent second
speed knob — with the reduce-motion control on the accessibility axis. Update the two search-index
rows to track the new labels.

**stow.sh + contract.json.** Point the seed at `theme_engine_migrate_motion_state` instead of the
literal default write, so a fresh system and an upgrading system take the identical path.
Replace the axis entry in `contract.json`'s engine-owned file list with the two new names.

Write configs a human will edit: keep the new `motion.json` comments short and plain-English.
Do not paste any of the literal identifiers the verify commands grep for into a source-file
comment — comment prose that echoes a gated literal makes the gate report against its own text.
  </action>
  <verify>
    <automated>
set -e
bash -n theme-engine/.config/theme-engine/lib/motion.sh
bash -n hypr/.config/hypr/scripts/motion-switch.sh
bash -n stow.sh
jq -e '.styles.md3.hypr_style | keys == ["special_workspace","windows_in","windows_move","windows_out","workspaces"]' theme-engine/.config/theme-engine/motion.json
jq -e '.accessibility | has("full") and has("reduced") and has("off")' theme-engine/.config/theme-engine/motion.json
jq -e 'has("scales") | not' theme-engine/.config/theme-engine/motion.json
lua -e 'assert(loadfile("hypr/.config/hypr/config/animations.lua"))'
    </automated>
    <automated>
# Migration is exercised against a scratch state dir, never the live one.
S=$(mktemp -d); mkdir -p "$S/state"
printf 'reduced\n' > "$S/state/motion-scale"
( set -e
  source theme-engine/.config/theme-engine/lib/motion.sh
  MOTION_STATE_DIR="$S/state"; MOTION_STYLE_FILE="$S/state/motion-style"
  MOTION_ACCESS_FILE="$S/state/motion-accessibility"; MOTION_LEGACY_FILE="$S/state/motion-scale"
  theme_engine_migrate_motion_state
  theme_engine_migrate_motion_state )   # idempotent: second run must be a no-op
test "$(cat "$S/state/motion-style")" = md3
test "$(cat "$S/state/motion-accessibility")" = reduced
test ! -e "$S/state/motion-scale"
rm -rf "$S"
    </automated>
    <automated>
# The whole point of the tracer: md3 + full must be byte-identical to today.
~/.config/theme-engine/theme-apply "$(cat ~/.local/state/theme/current-theme)"
test "$(cat ~/.local/state/theme/motion-style)" = md3
jq -e '.motion_style == "md3" and .motion_multiplier == 1.0 and .motion_enabled == true' ~/.local/state/theme/motion.json
lua -e 'local t=dofile(os.getenv("HOME").."/.local/state/theme/hyprland-tokens.lua"); assert(type(t.motion.hypr_style)=="table"); assert(t.motion.hypr_style.windows_in=="popin 60%")'
hypr/.config/hypr/scripts/motion-lint
hypr/.config/hypr/scripts/motion-lint --self-test
hypr/.config/hypr/scripts/hypr-equivalence-check
    </automated>
    <automated>
# The CLI's list format and the QML parser must agree. Assert the emitted shape
# matches the regex the page now uses, from the CLI's real output.
hypr/.config/hypr/scripts/motion-switch.sh --list | grep -qP '^  md3\t\S'
hypr/.config/hypr/scripts/motion-switch.sh --get | grep -qx md3
    </automated>
  </verify>
  <done>
`theme-apply` renders cleanly; `hypr-equivalence-check` and `motion-lint` (plus its self-test)
all pass, proving the axis split changed no observable compositor state. A legacy scale value
migrates to `md3` + the matching accessibility value in one idempotent step, and the legacy file
is gone. The settings Animation section lists one style and offers a separate reduce-motion
control. `hyprland-tokens.lua` carries a `hypr_style` table and `animations.lua` reads its five
leaf styles from it.
  </done>
  <reversibility rating="costly">Renaming the state file and dropping `scales` is a one-way data change for existing installs, but the migration function makes it recoverable in one direction and the values are trivially re-writable by hand.</reversibility>
</task>

<task type="auto">
  <name>Task 2: Add the four remaining styles as data, and make the equivalence gate style-aware</name>
  <files>
    theme-engine/.config/theme-engine/motion.json,
    hypr/.config/hypr/scripts/hypr-equivalence-check,
    quickshell/.config/quickshell/modules/dashboard/Cascade.qml,
    quickshell/.config/quickshell/modules/dashboard/WifiPanel.qml,
    quickshell/.config/quickshell/modules/dashboard/AudioPanel.qml,
    quickshell/.config/quickshell/modules/dashboard/QuickToggles.qml,
    quickshell/.config/quickshell/modules/Dashboard.qml
  </files>
  <action>
**A. Author the four remaining styles — JSON only.** If this task needs to touch shell, Lua or
QML to add a style, Task 1's structure is wrong and must be fixed rather than worked around
(D-04). The only non-JSON edits permitted in this task are the gate extension (B) and the
fade-site retarget (C), neither of which is per-style work.

Starting values below are **measured**, not invented: each was solved numerically for its target
peak against the cubic with fixed endpoints, and the `wavy` pair was additionally confirmed on
the installed Qt via `QEasingCurve`. They are tunable — the operator pass in Task 3 is what
settles them. Note that a control-point Y is **not** the overshoot percentage: Y `1.254` yields
an ~8% peak, Y `1.120` yields ~3%.

| Style | `emphasized-decelerate` override | Peak | `standard` / `emphasized-in` / `emphasized-out` duration names | windows | workspaces |
|---|---|---|---|---|---|
| `md3` | (none — base) | 1.000 | short4 / medium2 / short3 | `popin 60%` | `slide` |
| `smooth` | `[0.16, 0.85, 0.3, 1.0]` | 1.000 | medium1 / medium4 / short4 | `slidefade` | `slidefade` |
| `snappy` | `[0.1, 0.9, 0.4, 1.12]` | 1.030 | short3 / short4 / short2 | `popin 80%` | `slide` |
| `bouncy` | `[0.1, 0.9, 0.4, 1.254]` | 1.080 | short4 / medium3 / short3 | `popin 0%` | `slidevert` |
| `wavy` | `[0.15, 2.2, 0.6, 0.4]` | 1.130, dips to 0.870 | medium1 / long1 / short4 | `popin 0%` | `slidefadevert` |

`special_workspace` follows its family, not the window family — use the workspace column's
string for it, except `snappy`/`bouncy`/`md3` which keep `slidevert`. `windows_move` stays
`slide` in every style: moving an existing window is not an entry animation. Every duration is
a **name** from the existing `durations` table, never a new number — the base table already
carries every step these styles need.

Styles may also override `standard`, `standard-decelerate` and `standard-accelerate` control
points to shape their character, but those three must stay monotonic within [0,1] (R-2).
`smooth` and `snappy` should use that: a softer symmetric `standard` for the former, a
faster-rising one for the latter.

Add a static check to the repo's verify path (see below) that asserts these invariants
numerically, so an authored curve can never quietly violate the split.

**B. Extend `hypr-equivalence-check`'s `_compare_animations` to be style-aware.** Mirror the
existing narrow-forgiveness shape exactly — this is the same normalization the file already does
for a scaled `speed`, extended to the two other fields a style legitimately moves. Never widen it
into a blanket skip.

- Read the active style and accessibility from the two new state files, each through a closed-set
  `case` defaulting to `md3` / `full`, replacing the current read of the removed axis. Take the
  multiplier from the accessibility table.
- **Curves:** the baseline set is the `md3` set. Derive the *expected* tuple set by applying the
  active style's `easings` override onto the baseline's control points by curve name, then
  compare the live set against that expectation. A curve whose name is absent from the override
  must still match the baseline byte-exact.
- **Leaves:** extend the sole-differing-field forgiveness to admit `style` alongside `speed`, and
  only when the live value equals the active style's `hypr_style` entry for that leaf. Any other
  differing field, or a `style` that is merely different, still FAILs and still names the leaf.
  A leaf's `bezier` field must never differ — styles change control points behind stable names,
  so a changed `bezier` name means the renderer drifted from this design and is a real failure.
- Report every style-derived normalization to **stderr**, one line each, in the same shape as
  the existing scaled-speed reporting — the caller only echoes stdout on FAIL, so a stdout note
  would vanish on exactly the runs that need explaining. Silence here is the failure mode this
  project has already shipped twice.
- Under `md3` + `full` the whole extension must reduce to the original byte-exact comparison.

Add the arithmetic-mirrors-the-renderer warning to the new code, matching the note already above
`_compare_animations`: if the renderer's merge rule changes, this mirror changes with it.

**C. Retarget the fade sites that read the spatial-entry easing.** With overshoot now live on
`emphasized-decelerate`, any QML site using `Motion.emphasizedInEasing` to animate a fade would
overshoot a fade — the exact "reads as broken" case the BRIEF warns about. These sites were
enumerated by inspecting the animated property nearest each reference:

- `Dashboard.qml:595` (a `Behavior` on the fade property)
- `WifiPanel.qml:896`
- `AudioPanel.qml:248`
- `QuickToggles.qml:250`
- `Cascade.qml:196`

Switch each to `Motion.standardEasing`, which stays monotonic in every style. Re-run the same
enumeration afterwards and retarget any further site the sweep finds — treat the list above as a
starting point, not as complete; a miss in one file proves nothing about the others.

Leave every spatial site alone: `Dashboard.qml:587` (position), `NotifCentre.qml:120` (scale),
`WifiPanel.qml:1201`, `BluetoothPanel.qml:965`, `Cascade.qml:204`, `MediaTab.qml:1922`,
`Probe.qml:557`. Those are exactly the surfaces that should carry the style's character.

Do not write the name of any property these checks grep for into a QML comment on a retargeted
line — a comment echoing the gated literal makes the check report against its own prose.
  </action>
  <verify>
    <automated>
# Every authored curve is well-formed, and overshoot is confined to the two spatial names.
python3 - <<'EOF'
import json, sys
m = json.load(open('theme-engine/.config/theme-engine/motion.json'))
SPATIAL = {'emphasized-decelerate', 'emphasized-accelerate'}
BANDS = {'md3': (1.0, 1.0), 'smooth': (1.0, 1.0), 'snappy': (1.02, 1.05),
         'bouncy': (1.06, 1.10), 'wavy': (1.10, 1.25)}
def curve(p):
    x1, y1, x2, y2 = p
    n = 2000
    xs = [3*(1-t/n)**2*(t/n)*x1 + 3*(1-t/n)*(t/n)**2*x2 + (t/n)**3 for t in range(n+1)]
    ys = [3*(1-t/n)**2*(t/n)*y1 + 3*(1-t/n)*(t/n)**2*y2 + (t/n)**3 for t in range(n+1)]
    mono = all(xs[i+1] >= xs[i] - 1e-9 for i in range(n))
    return max(ys), min(ys[ys.index(max(ys)):]), mono, min(xs), max(xs)
base = m['easings']
fail = []
for sname, s in m['styles'].items():
    eff = dict(base); eff.update(s.get('easings') or {})
    if set((s.get('easings') or {})) - set(base):
        fail.append(f'{sname}: introduces an easing name absent from the base table')
    for ename, pts in eff.items():
        if len(pts) != 4:
            fail.append(f'{sname}/{ename}: not four control points'); continue
        peak, dip, mono, xmin, xmax = curve(pts)
        if not mono or xmin < -1e-9 or xmax > 1 + 1e-9:
            fail.append(f'{sname}/{ename}: x is not monotonic within [0,1]')
        if ename not in SPATIAL and peak > 1.0 + 1e-6:
            fail.append(f'{sname}/{ename}: exceeds 1.0 but is not a spatial-entry name')
    lo, hi = BANDS[sname]
    peak = curve(eff['emphasized-decelerate'])[0]
    if not (lo - 1e-6 <= peak <= hi + 1e-6):
        fail.append(f'{sname}: spatial-entry peak {peak:.4f} outside its band [{lo}, {hi}]')
    for k, v in (s.get('semantic') or {}).items():
        if k not in m['semantic']:
            fail.append(f'{sname}: semantic override {k} is not a base key')
        if v.get('duration') and v['duration'] not in m['durations']:
            fail.append(f'{sname}: duration name {v["duration"]} does not resolve')
        if v.get('easing') and v['easing'] not in base:
            fail.append(f'{sname}: easing name {v["easing"]} does not resolve')
print('\n'.join(fail) or 'curve invariants OK')
sys.exit(1 if fail else 0)
EOF
    </automated>
    <automated>
# wavy is a real wave on the installed Qt, not just on paper.
QT_QPA_PLATFORM=offscreen python3 - <<'EOF'
import json, sys
from PySide6.QtCore import QEasingCurve, QPointF
m = json.load(open('theme-engine/.config/theme-engine/motion.json'))
p = m['styles']['wavy']['easings']['emphasized-decelerate']
c = QEasingCurve(QEasingCurve.BezierSpline)
c.addCubicBezierSegment(QPointF(p[0], p[1]), QPointF(p[2], p[3]), QPointF(1.0, 1.0))
v = [c.valueForProgress(i/200) for i in range(201)]
peak = max(v); dip = min(v[v.index(peak):])
print(f'wavy peak={peak:.4f} dip={dip:.4f} settle={v[-1]:.4f}')
sys.exit(0 if peak > 1.05 and dip < 0.97 and abs(v[-1] - 1.0) < 1e-6 else 1)
EOF
    </automated>
    <automated>
# Every style renders, and the gate passes under each one.
set -e
for s in md3 smooth snappy bouncy wavy; do
  hypr/.config/hypr/scripts/motion-switch.sh "$s"
  test "$(jq -r '.motion_style' ~/.local/state/theme/motion.json)" = "$s"
  want=$(jq -r --arg s "$s" '.styles[$s].hypr_style.windows_in' theme-engine/.config/theme-engine/motion.json)
  got=$(hyprctl animations -j | jq -r '.[0][] | select(.name=="windowsIn") | .style')
  test "$got" = "$want" || { echo "windowsIn style: want '$want' got '$got'"; exit 1; }
  wantY=$(jq -r --arg s "$s" '(.styles[$s].easings["emphasized-decelerate"] // .easings["emphasized-decelerate"])[3]' theme-engine/.config/theme-engine/motion.json)
  gotY=$(hyprctl animations -j | jq -r '.[1][] | select(.name=="motion-emphasized-decelerate") | .Y1')
  awk -v a="$wantY" -v b="$gotY" 'BEGIN{exit !(a-b<0.001 && b-a<0.001)}' || { echo "curve Y1: want $wantY got $gotY"; exit 1; }
  hypr/.config/hypr/scripts/hypr-equivalence-check
  hypr/.config/hypr/scripts/motion-lint
done
hypr/.config/hypr/scripts/motion-switch.sh md3
    </automated>
    <automated>
# Under md3 + full the gate extension must be a no-op: no normalization lines.
hypr/.config/hypr/scripts/motion-switch.sh md3
hypr/.config/hypr/scripts/motion-switch.sh --accessibility full
hypr/.config/hypr/scripts/hypr-equivalence-check 2>&1 | grep -c 'style .* normalized' | grep -qx 0
    </automated>
    <automated>
# No remaining QML site pairs the spatial-entry easing with a fade property.
# Comment lines are stripped first so the scan cannot match its own prose.
OUT=$(mktemp)
for f in $(grep -rl 'Motion.emphasizedInEasing' quickshell/.config/quickshell/); do
  sed 's://.*::' "$f" | awk -v F="$f" '
    /emphasizedInEasing/ { for (i=NR-8; i<NR; i++) if (ctx[i] ~ /(property:[[:space:]]*"opac|Behavior on opac|ColorAnimation)/) print F":"NR }
    { ctx[NR] = $0 }'
done > "$OUT"
cat "$OUT"
test ! -s "$OUT"; rc=$?; rm -f "$OUT"; exit $rc
    </automated>
  </verify>
  <done>
All five styles exist as pure JSON data and each renders end-to-end. For every style,
`hyprctl animations -j` reports the authored control point and the authored leaf style string,
`hypr-equivalence-check` PASSes while naming each value it normalized, and `motion-lint` stays
green. Overshoot is present only on the spatial-entry curve, within its authored band, and no
QML fade site reads it. Under `md3` + `full` the gate emits no normalization lines at all.
  </done>
  <reversibility rating="reversible">Style values are data; the gate extension reduces to the original comparison under the default style.</reversibility>
</task>

<task type="checkpoint:human-verify" gate="blocking-human">
  <name>Task 3: Operator render-and-judge pass — one per style, on both targets</name>
  <what-built>
The motion **scale** axis is gone. In its place: an animation **style** axis with five entries
(`md3`, `smooth`, `snappy`, `bouncy`, `wavy`), each owning its own easing curves, durations and
Hyprland window/workspace entry shapes, defined purely as data in `motion.json`. Reduce-motion
and animations-off moved to their own accessibility control. The settings window's Animation
section now offers a style picker plus a separate reduce-motion control. An existing install's
stored scale value migrates automatically.
  </what-built>
  <how-to-verify>
Static gates prove the numbers arrived. They cannot prove the motion reads right. This checkpoint
is where the style values are actually settled — the table in Task 2 is a starting point.

Restart the shell **after** the last code edit, and record `wc -l ~/.cache/quickshell.log`
**before** the restart so the log is read by offset rather than by tail — stale error blocks from
a previous run otherwise produce false failures. Do not take screenshots: a single capture
SIGSEGVs the compositor into safe mode on this host.

For each of `md3`, `smooth`, `snappy`, `bouncy`, `wavy`, switch the style and have the operator
judge all four surfaces:

1. A window opening and closing (Hyprland `windowsIn` / `windowsOut` — the entry shape).
2. A workspace switch (Hyprland `workspaces`).
3. A notification arriving (shell — durations and curve, no overshoot on the fade).
4. A bar drawer sliding open (shell — spatial).

Then, once, with the style left on the operator's preference: set reduce-motion to reduced and
confirm everything shortens without any continuous indicator speeding up; set it to off and
confirm animation stops on both targets without leaving anything unthemed or half-drawn; set it
back to full.

For each style, ask plainly: does it match its intended character —
`md3` lands exactly with no overshoot; `smooth` is the longest and softest; `snappy` is short
with a barely-there overshoot; `bouncy` overshoots visibly and settles once; `wavy` overshoots
then dips back before settling? Where it does not, tune the numbers in `motion.json`, re-run
Task 2's verify block, and judge again. Do not claim a style works from the static gates alone.
  </how-to-verify>
  <resume-signal>
The operator names each style as matching its intended character (or names the tuning it needs),
and confirms all three accessibility settings behave. Say "styles approved" to finish; name a
style and what is wrong with it to send it back for tuning. Any tuning the pass produces is
committed and Task 2's verify block must be green against the tuned numbers before finishing.
  </resume-signal>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| `motion.json` -> Hyprland's config parser | Hand-authored data reaches a compositor parser via `hyprland-tokens.lua` (an executed Lua file) |
| state files -> renderer -> Lua/QML/CSS | Untrusted-by-position file contents flow into four generated targets with no readback on two of them |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-swp-01 | Tampering | `hypr_style` string -> `hl.animation({style=...})` | medium | mitigate | Validated against a strict lowercase-plus-optional-percentage pattern before any write (Task 1), then emitted only through `_hypr_lua_quote_string` — the sole path a string may reach Lua source through |
| T-swp-02 | Tampering | style/accessibility state files -> renderer | medium | mitigate | Both read through closed-set readers whose valid sets derive from `motion.json` keys or a literal three-value `case`; an unrecognised value defaults rather than flowing on raw |
| T-swp-03 | Denial of Service | malformed style override -> compositor start | high | mitigate | `theme_engine_validate_motion_values` gains the four `styles` invariants and runs before a single byte is written; a failed render leaves the live state dir byte-unchanged |
| T-swp-04 | Information disclosure | — | low | accept | No secrets or user data traverse this axis; every value is a public animation number |
| T-swp-SC | Tampering | package installs | low | accept | This task installs no packages — PySide6, jq, lua and python3 are all already present and verified on this host |
</threat_model>

<verification>
Whole-task gates, after Task 2 and again after any Task 3 tuning:

- `hypr/.config/hypr/scripts/motion-lint` and `motion-lint --self-test` both exit 0.
- `hypr/.config/hypr/scripts/hypr-equivalence-check` exits 0 under all five styles.
- `hypr/.config/hypr/scripts/colour-lint` stays green (no colour value is touched, so a
  regression here means something unrelated moved).
- `theme-engine/.config/theme-engine/theme-doctor` exits 0.
- `~/.cache/quickshell.log`, read from the offset recorded before the final restart, carries no
  new error block.
- Adding a hypothetical sixth style is a `motion.json` edit only: `git diff --stat` for the
  four-style commit in Task 2 touches no `.qml`, `.lua` or `.sh` file except the gate.
</verification>

<success_criteria>
- The Animation section offers five named styles and a separate reduce-motion control.
- Each style visibly changes curve shape, duration and Hyprland entry shape.
- A legacy scale value migrates in one idempotent step with no manual intervention and no
  unthemed or broken intermediate state; a fresh `stow.sh` run seeds the same two files.
- `hypr-equivalence-check` passes under every style and names every value it normalized.
- The 133 `easing.bezierCurve` call sites are byte-unchanged; only the five enumerated fade
  sites moved, and they moved off the spatial-entry easing.
- The operator has signed off on all five styles across all four surfaces.
</success_criteria>

<output>
Create `.planning/quick/260821-swp-replace-the-motion-scale-axis-reduced-no/260821-swp-SUMMARY.md` when done.

State in the SUMMARY, explicitly:
- That this reinstates as a user-facing setting the kind of per-style curve data plan **13-07**
  removed as a measuring instrument, and that **TOKEN-06**'s spring verdict was a tuning
  rejection rather than a mechanism rejection — so the reversal is coherent and intentional.
- That the slate is bezier-only, and precisely what `hypr-equivalence-check` can and cannot see
  as a result (R-1).
- That `lively`'s 1.25x has no home in the new model and migrates to `md3` + `full`.
</output>
