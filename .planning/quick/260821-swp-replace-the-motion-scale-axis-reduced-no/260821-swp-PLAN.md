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
  # ── Compositor ──────────────────────────────────────────────────────
  - hypr/.config/hypr/config/animations.lua
  # ── Shell: token surface + settings ─────────────────────────────────
  - quickshell/.config/quickshell/modules/Motion.qml
  - quickshell/.config/quickshell/modules/dashboard/Design.qml
  - quickshell/.config/quickshell/modules/settings/pages/WindowManagerPage.qml
  - quickshell/.config/quickshell/modules/settings/RowIndex.qml
  # ── Shell: the 48 spatial retargets (exact list generated in Task 1) ─
  - quickshell/.config/quickshell/modules/Bar.qml
  - quickshell/.config/quickshell/modules/Dashboard.qml
  - quickshell/.config/quickshell/modules/Probe.qml
  - quickshell/.config/quickshell/modules/bar/ClockActionsCapsule.qml
  - quickshell/.config/quickshell/modules/bar/LauncherCapsule.qml
  - quickshell/.config/quickshell/modules/bar/MediaConnectivityCapsule.qml
  - quickshell/.config/quickshell/modules/centre/NewsPane.qml
  - quickshell/.config/quickshell/modules/centre/NotifCentre.qml
  - quickshell/.config/quickshell/modules/centre/NotifGroup.qml
  - quickshell/.config/quickshell/modules/notifications/NotifPopupStack.qml
  - quickshell/.config/quickshell/modules/session/PowerMenu.qml
  - quickshell/.config/quickshell/modules/settings/NavRail.qml
  - quickshell/.config/quickshell/modules/settings/common/ToggleRow.qml
  - quickshell/.config/quickshell/modules/settings/pages/NetworkPage.qml
  - quickshell/.config/quickshell/modules/dashboard/AudioPanel.qml
  - quickshell/.config/quickshell/modules/dashboard/BluetoothPanel.qml
  - quickshell/.config/quickshell/modules/dashboard/Cascade.qml
  - quickshell/.config/quickshell/modules/dashboard/DashboardTab.qml
  - quickshell/.config/quickshell/modules/dashboard/Dial.qml
  - quickshell/.config/quickshell/modules/dashboard/MediaTab.qml
  - quickshell/.config/quickshell/modules/dashboard/QuickToggles.qml
  - quickshell/.config/quickshell/modules/dashboard/WifiPanel.qml
  # ── Gates ───────────────────────────────────────────────────────────
  - hypr/.config/hypr/scripts/motion-lint
  - hypr/.config/hypr/scripts/hypr-equivalence-check

estimate:
  tokens: 145000
  raw_tokens: 72000
  tasks: 3
  confidence: low

must_haves:
  truths:
    - "The settings window's Animation section offers five named animation styles, not a speed scale (D-01, D-03)."
    - "Switching style visibly changes window entry shape, workspace transition shape, easing curve and duration on both the compositor and the shell (D-02)."
    - "Reduce-motion and animations-off are reachable from a control that is not the style picker (D-01)."
    - "No animation whose target is a fade or a colour can bind an easing a style may give overshoot to — by construction, not by a maintained list."
    - "An existing install holding a legacy scale value keeps a working, themed desktop across the upgrade with no manual step."
    - "Adding a sixth style requires editing motion.json only — no QML, Lua or shell change (D-04)."
    - "hypr-equivalence-check reports PASS under every style, and reports every value it normalized rather than staying silent."
  artifacts:
    - theme-engine/.config/theme-engine/motion.json          # gains .styles, .accessibility, .hypr_leaves, 3 spatial easings
    - ~/.local/state/theme/motion-style                       # new state file
    - ~/.local/state/theme/motion-accessibility               # new state file
    - hypr/.config/hypr/scripts/motion-lint                   # gains CHECK E
  key_links:
    - "motion.json .styles -> lib/motion.sh effective-merge -> hyprland-tokens.lua motion.curves + motion.hypr_leaves -> animations.lua leaves"
    - "motion.json spatial easings -> Motion.qml spatial aliases -> the 48 spatial QML sites (and nothing else)"
    - "motion-lint CHECK E: effects-target animation -> must never bind a spatial easing"
    - "motion-switch.sh --list -> WindowManagerPage.qml SelectRow parser (format and parser change together)"
    - "active style -> hypr-equivalence-check expected curve set / expected leaf curve+style (gate must track the renderer)"
---

<objective>
Replace the motion **scale** axis (a duration multiplier) with an animation **style** axis
(`md3`, `smooth`, `snappy`, `bouncy`, `wavy`), where each style owns its own easing curves,
durations and Hyprland window/workspace entry shapes — defined as a `styles` data table in
`motion.json`. Move reduced-motion and animations-off onto a separate accessibility axis.

Purpose: today the only user-facing motion control is intensity. Animation *shape* is fixed
MD3 and cannot vary at all. This makes shape the user-facing setting, as a pure data table,
so the slate can grow without touching code.

Output: two new state axes, a five-entry `styles` table, a spatial/effects easing split that
makes a bouncing fade impossible by construction, a style-aware equivalence gate, and a
relabelled settings control.
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

Four decisions were open. All four are settled below. Every number cited is **measured against
this tree**, not inferred — the measurement commands are reproduced so they can be re-run.

## R-1 — The slate is BEZIER-ONLY. No springs.

All five styles are cubic beziers on both targets. Hyprland springs are not used.

**Measured.** The BRIEF proved Hyprland accepts overshoot beziers and reads them back
(`Y1:1.15`). This plan additionally measured the Qt side headlessly on the installed Qt 6.11.2
via PySide6's `QEasingCurve` under `QT_QPA_PLATFORM=offscreen` — no window opened, so the
`qml6`-probe crash hazard does not apply:

```
BezierSpline (0.15, 2.2) (0.6, 0.4) -> peak 1.1295, dips to 0.8702, settles to exactly 1.0
BezierSpline (0.1, 0.9)  (0.4, 1.254) -> peak 1.0801
```

`Easing.BezierSpline` accepts control-point Y outside [0,1] and yields genuine overshoot **and**
undershoot. `wavy` is therefore a real overshoot-then-undershoot curve, not an approximation —
one wave, not a multi-cycle oscillation. `easeOutBounce` stays out of scope per the BRIEF.
Note for tuning: a control-point Y is **not** the overshoot percentage — Y `1.254` gives an ~8%
peak, Y `1.120` gives ~3%.

**What the equivalence gate can see as a result:** `hyprctl animations -j` reports
`X0/Y0/X1/Y1` for every registered curve and a `bezier` + `style` string per leaf. Because the
slate is bezier-only, **100% of what a style changes on the compositor is visible to
`hypr-equivalence-check`.** Nothing hides behind a spring the gate structurally cannot read.
That is the entire reason springs are rejected. What it still cannot see: anything QML-side
(that is `motion-lint`'s surface), and *how the motion feels* — hence Task 3.

## R-2 — Overshoot lives on NEW spatial-only easing names. The 90 effects sites are untouched.

This is the fix for the fade hazard, and it is the **inverse** of adding a dedicated effects
easing that every fade must bind.

**Measured, with a brace-aware scanner that resolves each `easing.bezierCurve` binding to its
target property through all four syntactic forms in use** (`property:`, `properties:`,
`Behavior on X`, `Animation on X`):

```
132 easing.bezierCurve bindings total
  90 effects  (32 opacity + 58 colour: color 43, border.color 9, strokeColor 5, iconFill 1)
  40 spatial  (implicitHeight, x, y, width/height, scale, rotation, radius, offsetScale, value)
   2 unresolvable (Cascade.qml:204 and :239 — property name computed at runtime)

easing bound by effects sites:  standard 73, emphasizedOut 12, emphasizedIn 5, ambient 2
easing bound by spatial sites:  standard 27, emphasizedIn 10, emphasizedOut 7
```

Effects outnumber spatial more than 2:1, and `standard` — the most-reached-for name in the
codebase — is bound by 73 effects sites against 27 spatial ones.

**Therefore:** giving every fade a dedicated effects easing would mean 90 retargets and would
leave the default **unsafe** — a future contributor reaching for the obvious
`Motion.standardEasing` on a fade would get a bouncing fade. Inverting it costs 40 retargets and
leaves the default **safe**: the existing names stay permanently monotonic, and only a site that
*deliberately* opts into a spatial name can ever overshoot.

**The mechanism.** Three new easing names are added **once** to the base `easings` table —
`spatial-in`, `spatial-out`, `spatial-move` — present in every style. Only these three, plus
nothing else, may carry control-point Y above 1.0. `standard`, `standard-decelerate`,
`standard-accelerate`, `emphasized-decelerate`, `emphasized-accelerate`, `legacy*`, `linear`
and `css-linear` are monotonic within [0,1] in every style, forever.

Hyprland's spatial leaves (`windowsIn/Out/Move`, `workspaces`, `specialWorkspace`,
`layers/In/Out`) repoint to the spatial curves. Its fade leaves keep `standard-*`, and
`border`/`borderangle` keep `linear`. `Motion.qml` gains `spatialIn`/`spatialOut`/`spatialMove`
duration and easing aliases, and the 40 spatial QML sites bind those.

**Consequence for R-2 as originally written:** styles may no longer be assumed to leave the
curve-name set invariant, because three names are added. That is a one-time base-table addition,
not a per-style one — the name set is still identical across all five styles, which is what the
gate needs. Styles still may not introduce a name of their own.

## R-2b — The bar drawers were unreachable by the style axis, and are brought in.

The BRIEF's operator verification list names "a bar drawer sliding open". Measured: the four
drawer strips run on `Design.barDrawerEasingType` — `Easing.OutCubic`, a Qt enum with no bezier
array — across **8 call sites** in `ClockActionsCapsule.qml`, `LauncherCapsule.qml` and
`MediaConnectivityCapsule.qml`.

That surface **cannot change with the style axis** as it stands, and being an `easing.type:`
binding rather than an `easing.bezierCurve:` one, it is also invisible to any scan of bezier
bindings — which is precisely how it stayed out of view. Asking the operator to judge a surface
that structurally cannot respond is the "verified the wrong claim" failure this repo has already
hit. So those 8 sites are retargeted onto the spatial easing too, and the now-dead
`barDrawerEasingType` property is removed. Total retarget: **40 spatial + 8 drawer = 48 sites.**

## R-3 — `Motion.qml` gains spatial aliases; the 133-call-site contract is otherwise untouched.

No `easing.type` indirection is introduced — the `Design.barDrawerEasingType` precedent is
deliberately retired rather than followed (R-2b). Every binding stays
`easing.type: Easing.BezierSpline` + `easing.bezierCurve: Motion.<x>Easing`, so the 90 effects
sites are byte-unchanged and the 48 retargeted sites change only which alias they name.

`_pairNames` is read **positionally** by its aliases, so the three new semantic keys are
**APPENDED** (positions 5, 6, 7 after `ambient`) and never inserted.

## R-4 — Reduced-motion lives in a second STATE FILE, and THREE readers must move, not two.

A new `~/.local/state/theme/motion-accessibility` file holding `full` | `reduced` | `off`,
backed by an `accessibility` table in `motion.json` carrying exactly the
`{multiplier, animations_enabled}` shape the removed `scales` table carries today.

Not Prefs: `Prefs` is QML-owned and `watchChanges:false`, but the renderer is shell-side and
must read this at `theme-apply` time. Not a retained scale axis: that leaves `normal`/`lively`
alive as dead keys. A state file is the identical shape the other theme-orthogonal axes already
use, so seeding, `contract.json` ownership, atomic tmp+mv writes and closed-set reader
discipline all carry over — and it preserves the `multiplier` / `animations_enabled` plumbing
*below the read* unchanged, so `Motion.ambientDuration`'s divide-the-multiplier-back-out logic
and the gate's scaled-speed forgiveness need no rewrite.

**There are THREE hardcoded `off|reduced|normal|lively` closed sets, not two.** The BRIEF named
`motion-switch.sh` and `lib/motion.sh`. Measured, there is a third at
`hypr-equivalence-check` ~line 921, reading the legacy state file directly. Miss it and the gate
silently defaults to the removed `normal` key and scores every leaf against the wrong
multiplier. All three move in Task 1.

`lively`'s 1.25x has no home — the multiplier axis is absorbed by per-style durations (D-01).
Migration maps it to `md3` + `full`. That is a deliberate, stated loss.

</decisions_resolved>

<tasks>

<task type="tracer">
  <name>Task 1: Split the axis and the spatial/effects easing set end-to-end, with ONE style</name>
  <files>
    theme-engine/.config/theme-engine/motion.json,
    theme-engine/.config/theme-engine/lib/motion.sh,
    theme-engine/.config/theme-engine/contract.json,
    hypr/.config/hypr/scripts/motion-switch.sh,
    hypr/.config/hypr/config/animations.lua,
    quickshell/.config/quickshell/modules/Motion.qml,
    quickshell/.config/quickshell/modules/dashboard/Design.qml,
    quickshell/.config/quickshell/modules/settings/pages/WindowManagerPage.qml,
    quickshell/.config/quickshell/modules/settings/RowIndex.qml,
    hypr/.config/hypr/scripts/motion-lint,
    hypr/.config/hypr/scripts/hypr-equivalence-check,
    stow.sh,
    (plus the 48 retarget sites enumerated by the scanner — see files_modified)
  </files>
  <precondition>The Quickshell shell process is running and `~/.local/state/theme/current-theme` holds a theme name, so `theme-apply` has something to re-render.</precondition>
  <action>
Restructure everything with exactly ONE style defined — `md3` — whose resolved numbers are
today's numbers. Nothing in this task changes how the desktop looks. It changes what *can*
change, and installs the gate that keeps the next change safe.

**A. motion.json.** Keep `durations`, `semantic`, `indicators`, `floor_ms`. Remove `scales`.
Add to `easings` the three spatial names, seeded with values identical to the curves the
spatial leaves use today so this task moves nothing: `spatial-in` takes
`emphasized-decelerate`'s points, `spatial-out` takes `emphasized-accelerate`'s, `spatial-move`
takes `standard`'s. Add three matching `semantic` entries — `spatial-in`, `spatial-out`,
`spatial-move` — pairing each with the duration name its Hyprland leaf resolves today.

Add three top-level objects:

- `accessibility`: `full` = 1.0 / true, `reduced` = 0.5 / true, `off` = 1.0 / false.
- `hypr_leaves`: one entry per style-varying Hyprland leaf — `windows_in`, `windows_out`,
  `windows_move`, `workspaces`, `special_workspace`, `layers`, `layers_in`, `layers_out` —
  each `{curve, style}`, seeded from `animations.lua`'s current literals but with the spatial
  curve names substituted. Fade, border and borderangle leaves are **not** listed: they keep
  their hardcoded wiring in Lua, and `borderangle`'s loop style is a mechanism, not a look.
- `styles`: a single entry `md3` with `label`, `description`, and empty `easings`, `semantic`
  and `hypr_leaves` override objects.

Record in a comment key that this reinstates, as a user-facing setting, the kind of per-style
curve data plan 13-07 removed as a measuring instrument, and that TOKEN-06's "spring is too
fast" was a tuning verdict rather than a mechanism verdict — so the reversal is intentional and
on the record (BRIEF, "Why this reverses a prior removal").

**Schema invariants**, enforced in validation: a style's `easings` override keys must be a subset
of the base `easings` keys (a style changes points behind a name, never adds a name); its
`semantic` and `hypr_leaves` override keys likewise subsets of the base; every referenced
duration/easing/curve name must resolve; and each `style` string must match a strict pattern of
lowercase letters optionally followed by a space and a one-to-three digit percentage, because
that value reaches Hyprland's parser (ASVS V5, mirroring the existing palette-name posture).

**B. lib/motion.sh.**

1. Add `theme_engine_migrate_motion_state` — idempotent, returns immediately when the style
   state file exists. Otherwise maps a legacy value (the disabled one to accessibility off, the
   halved one to reduced, anything else to full), writes `md3` as the style in every case,
   writes both files with the existing tmp+mv atomic idiom, then removes the legacy file. With
   neither present it seeds the two defaults. Derive every path from module-level variables, not
   inline `$HOME/...`, so the verify below can point it at a scratch directory.
2. Replace the closed-set reader with two: style (valid set derived from `.styles` keys,
   defaulting to `md3`) and accessibility (closed `case` over the three literals, defaulting to
   `full`). Both call the migration first.
3. Build an **effective** motion document once per render — base with `easings`, `semantic` and
   `hypr_leaves` shallow-merged with the active style's overrides — write it to a temp file, and
   repoint every existing `jq ... "$MOTION_JSON"` call in the render, validate and emit paths at
   it. One merge point, so no two writers can disagree. `theme_engine_render_hypr_tokens` and
   `theme_engine_render_motion_scss` read it too via the dynamic scoping they already rely on;
   do not add a second read of the raw document.
4. Emit `motion.hypr_leaves` into `hyprland-tokens.lua` as a nested table of `{curve, style}`,
   every string written through `_hypr_lua_quote_string` — the sole path a string may reach Lua
   source through. In the QML target, replace `motion_scale` with `motion_style` and add
   `motion_accessibility`; `motion_multiplier`, `motion_enabled`, `semantic`, `indicators` and
   `floor_ms` keep their names, shapes and arithmetic.

Extend `theme_engine_validate_motion_values` with the invariants above plus a check that the
active accessibility entry carries both fields — same validate-before-any-write,
diagnose-to-stderr, return-non-zero discipline as the existing checks.

**C. motion-switch.sh.** Delete the hand-duplicated reader and source `lib/motion.sh` instead —
the file's own header already warns that drift between the two copies would be a bug, and the
library defines only constants and functions at top level, so sourcing has no side effects.
Retarget validation to `.styles` keys. Add `--accessibility <value>`, writing the second state
file then triggering the same single `theme-apply` entrypoint — never a second render path.
Change `--list` to emit one style per line as two tab-separated fields, key then label, under a
header line; add `--list-accessibility` and `--get-accessibility`.

**D. animations.lua.** For the eight leaves named in `hypr_leaves`, read both the curve name and
the style string from `tokens.motion.hypr_leaves.<key>`, keeping the existing
`registered_curves` guard and adding an explicit nil test on each field — a nil omits the field
rather than substituting a literal, the same discipline the file already applies to
`motion_enabled` and for the same reason. Fade, border and borderangle leaves are unchanged.

**E. Motion.qml.** Rename the two `JsonAdapter` bindings to the renderer's new key names exactly
— the adapter maps top-level keys by exact name with no case conversion, and this repo has
already shipped the silent-default bug that mismatch causes. **Append** `spatial-in`,
`spatial-out`, `spatial-move` to `_pairNames` (positions 5, 6, 7 — never insert; the existing
aliases read it positionally). Add `spatialInDuration`/`spatialInEasing` and the `Out`/`Move`
counterparts, plus `motionStyle` and `motionAccessibility` aliases, and update the one existing
`Motion.motionScale` reference. Every existing alias, fallback and the `ambientDuration` divisor
logic are unchanged.

**F. Retarget the 48 spatial sites.** Generate the exact list with the scanner (see the verify
block — it is the same code that becomes CHECK E, so the list and the gate can never disagree),
then for each site whose target property is spatial, switch `Motion.standardEasing` to
`Motion.spatialMoveEasing`, `Motion.emphasizedInEasing` to `Motion.spatialInEasing`, and
`Motion.emphasizedOutEasing` to `Motion.spatialOutEasing`, moving the paired `...Duration`
binding with it. Then convert the 8 `Design.barDrawerEasingType` sites (R-2b) to
`easing.type: Easing.BezierSpline` + the matching spatial easing, keeping their current
duration binding, and delete the now-unused `barDrawerEasingType` property from `Design.qml`.

`Cascade.qml:204` and `:239` compute their property name at runtime and cannot be classified
statically. Read what `transformProperty` can hold and bind accordingly, then annotate both
lines with the CHECK E allow-list marker and a one-line reason.

Leave all 90 effects sites alone. Do not write the name of any property the gate greps for into
a QML comment on a retargeted line — comment prose echoing a gated literal makes the gate report
against its own text.

**G. motion-lint.** In `load_qml_defs` (~line 290), derive `motionStyle` and
`motionAccessibility` from the presence of their top-level keys in the rendered file, exactly as
`motionEnabled` and `motionMultiplier` already are — never a hardcoded name that can drift.
The three appended semantic keys generate their `...Duration`/`...Easing` names automatically
through the existing camel-case derivation; confirm that rather than adding them by hand.

Add **CHECK E — spatial easings must never reach an effects animation.** A brace-aware scanner
that, for each `easing.bezierCurve` binding, resolves the target property through the enclosing
block, and fails when a target of `opacity` or any colour-valued property binds a spatial easing.
It must recognise all four syntactic forms — `property:`, `properties:` (plural — a singular-only
regex is blind to real sites), `Behavior on X`, `Animation on X` — and must read every
`Motion.<X>Easing` on the line so both arms of a ternary are covered. Honour an explicit inline
allow-list marker for the two runtime-computed sites and no others. Add one compliant and one
poisoned fixture to the committed set so `--self-test` covers it, matching the existing fixture
discipline.

**State CHECK E's limits in its header comment, plainly.** It CAN see all four syntactic forms,
the enclosing target for each binding, and both arms of a ternary. It CANNOT see: a property
name computed at runtime (exactly two sites, both allow-listed); an animation constructed or
retargeted from JavaScript; `PropertyChanges`/`Transition` machinery that names a property
indirectly; an easing reached through an intermediate alias rather than a literal
`Motion.<X>Easing`; and any `easing.type:`-only binding, which carries no bezier at all — that
last blind spot is exactly how the eight drawer sites stayed out of view until this task.

**H. hypr-equivalence-check.** Move the third closed set (~line 921) onto the two new state
files, each read through a closed-set `case` defaulting to `md3` / `full`, taking the multiplier
from the `accessibility` table. Then extend `_compare_animations`, mirroring the existing
narrow-forgiveness shape rather than widening it into a skip:

- **Curves:** derive the expected set from the effective `easings` table rather than frozen
  baseline tuples, and additionally assert that every curve name present in the baseline is
  still registered — so the three added names pass while a silently dropped name still FAILs.
- **Leaves:** extend the sole-differing-field forgiveness to admit `bezier` and `style`
  alongside `speed`, and only when each live value equals the active style's `hypr_leaves` entry
  for that leaf. Any other differing field, or a value that is merely different, still FAILs and
  still names the leaf.
- Report every normalization to **stderr**, one line each, in the same shape as the existing
  scaled-speed reporting — the caller only echoes stdout on FAIL, so a stdout note would vanish
  on exactly the runs that need explaining.

Carry the existing "this arithmetic mirrors the renderer" warning onto the new code.

**I. stow.sh + contract.json.** Point the seed at `theme_engine_migrate_motion_state` so fresh
and upgrading systems take one path. Replace the axis entry in the engine-owned file list with
the two new names.

Write configs a human will edit: keep the new `motion.json` comments short and plain-English.
  </action>
  <verify>
    <automated>
set -e
bash -n theme-engine/.config/theme-engine/lib/motion.sh
bash -n hypr/.config/hypr/scripts/motion-switch.sh
bash -n stow.sh
jq -e '.easings | has("spatial-in") and has("spatial-out") and has("spatial-move")' theme-engine/.config/theme-engine/motion.json
jq -e '.hypr_leaves | keys | length == 8' theme-engine/.config/theme-engine/motion.json
jq -e '.accessibility | has("full") and has("reduced") and has("off")' theme-engine/.config/theme-engine/motion.json
jq -e 'has("scales") | not' theme-engine/.config/theme-engine/motion.json
lua -e 'assert(loadfile("hypr/.config/hypr/config/animations.lua"))'
# _pairNames must be APPEND-ONLY: the first five entries keep their positions.
grep -q 'readonly property var _pairNames: \["standard", "emphasized-in", "emphasized-out", "stagger-offset", "ambient", "spatial-in", "spatial-out", "spatial-move"\]' quickshell/.config/quickshell/modules/Motion.qml
    </automated>
    <automated>
# All three legacy closed sets are gone. Comment lines are stripped first so the
# scan cannot match its own prose (this repo has shipped that false positive).
for f in theme-engine/.config/theme-engine/lib/motion.sh \
         hypr/.config/hypr/scripts/motion-switch.sh \
         hypr/.config/hypr/scripts/hypr-equivalence-check; do
  n=$(sed 's/#.*//' "$f" | grep -c 'off|reduced|normal|lively' || true)
  test "$n" -eq 0 || { echo "$f still holds a legacy closed set ($n)"; exit 1; }
done
    </automated>
    <automated>
# Migration runs against a scratch state dir, never the live one.
S=$(mktemp -d); mkdir -p "$S/state"; printf 'reduced\n' > "$S/state/motion-scale"
( set -e
  source theme-engine/.config/theme-engine/lib/motion.sh
  MOTION_STATE_DIR="$S/state"; MOTION_STYLE_FILE="$S/state/motion-style"
  MOTION_ACCESS_FILE="$S/state/motion-accessibility"; MOTION_LEGACY_FILE="$S/state/motion-scale"
  theme_engine_migrate_motion_state
  theme_engine_migrate_motion_state )    # second run must be a no-op
test "$(cat "$S/state/motion-style")" = md3
test "$(cat "$S/state/motion-accessibility")" = reduced
test ! -e "$S/state/motion-scale"
rm -rf "$S"
    </automated>
    <automated>
# The point of the tracer: md3 + full must be behaviourally identical to today.
set -e
~/.config/theme-engine/theme-apply "$(cat ~/.local/state/theme/current-theme)"
test "$(cat ~/.local/state/theme/motion-style)" = md3
jq -e '.motion_style == "md3" and .motion_multiplier == 1.0 and .motion_enabled == true' ~/.local/state/theme/motion.json
lua -e 'local t=dofile(os.getenv("HOME").."/.local/state/theme/hyprland-tokens.lua"); assert(t.motion.hypr_leaves.windows_in.style=="popin 60%"); assert(t.motion.hypr_leaves.windows_in.curve=="spatial-in")'
# Spatial curves must be numerically identical to the curves they replaced,
# so this restructure moves nothing on screen.
python3 -c "
import json;m=json.load(open('theme-engine/.config/theme-engine/motion.json'));e=m['easings']
assert e['spatial-in']==e['emphasized-decelerate'], e['spatial-in']
assert e['spatial-out']==e['emphasized-accelerate'], e['spatial-out']
assert e['spatial-move']==e['standard'], e['spatial-move']
print('spatial seeds match their originals')"
hypr/.config/hypr/scripts/hypr-equivalence-check
hypr/.config/hypr/scripts/motion-lint
hypr/.config/hypr/scripts/motion-lint --self-test
    </automated>
    <automated>
# CHECK E is real: it must pass on the tree and FAIL on a deliberately poisoned copy.
set -e
hypr/.config/hypr/scripts/motion-lint 2>&1 | grep -q 'CHECK E'
W=$(mktemp -d); cp -r quickshell "$W/"
python3 - "$W" <<'EOF'
import re, sys, pathlib
# Bind a spatial easing to a fade in the poisoned copy.
p = pathlib.Path(sys.argv[1])/'quickshell/.config/quickshell/modules/toast/Toast.qml'
s = p.read_text()
s = s.replace('Motion.standardEasing', 'Motion.spatialInEasing', 1)
p.write_text(s)
EOF
if ( cd "$W" && "$OLDPWD/hypr/.config/hypr/scripts/motion-lint" ) >/dev/null 2>&1; then
  echo "CHECK E did not catch a spatial easing bound to a fade"; rm -rf "$W"; exit 1
fi
rm -rf "$W"; echo "CHECK E catches the poisoned case"
    </automated>
    <automated>
# The drawer surface is now reachable by the style axis, and its dead property is gone.
test "$(grep -rc 'easing.type: Design.barDrawerEasingType' quickshell/.config/quickshell/ | awk -F: '{s+=$2} END{print s+0}')" -eq 0
sed 's|//.*||' quickshell/.config/quickshell/modules/dashboard/Design.qml | grep -c 'barDrawerEasingType' | grep -qx 0
    </automated>
    <automated>
# The CLI's list format and the QML parser must agree, checked from real output.
hypr/.config/hypr/scripts/motion-switch.sh --list | grep -qP '^  md3\t\S'
hypr/.config/hypr/scripts/motion-switch.sh --get | grep -qx md3
hypr/.config/hypr/scripts/motion-switch.sh --get-accessibility | grep -qxE 'full|reduced|off'
    </automated>
  </verify>
  <done>
`theme-apply` renders cleanly and `hypr-equivalence-check` PASSes, proving the axis split, the
spatial/effects easing split and the 48-site retarget changed nothing observable. `motion-lint`
and its self-test are green, CHECK E is running, and CHECK E fails a poisoned copy that binds a
spatial easing to a fade. All three legacy closed sets are gone. A legacy value migrates
idempotently. The four bar drawers now run on Motion tokens. The settings Animation section
lists one style and offers a separate reduce-motion control.
  </done>
  <reversibility rating="costly">Renaming the state file and dropping `scales` is a one-way data change for existing installs; the migration function makes it recoverable and the values are trivially re-writable by hand.</reversibility>
</task>

<task type="auto">
  <name>Task 2: Add the four remaining styles — JSON only — and prove the gates still see everything</name>
  <files>
    theme-engine/.config/theme-engine/motion.json
  </files>
  <action>
This task edits **one file**. If it needs to touch shell, Lua or QML to add a style, Task 1's
structure is wrong and must be fixed rather than worked around — that is D-04's whole promise,
and this task is its test.

Starting values are **measured**, solved numerically for their target peak against the cubic
with fixed endpoints, with the `wavy` pair additionally confirmed on the installed Qt. They are
a starting point — Task 3's operator pass settles them.

| Style | `spatial-in` override | Peak | `standard` / `emphasized-in` / `emphasized-out` / `spatial-in` duration names | windows | workspaces |
|---|---|---|---|---|---|
| `md3` | (none — base) | 1.000 | short4 / medium2 / short3 / medium2 | `popin 60%` | `slide` |
| `smooth` | `[0.16, 0.85, 0.3, 1.0]` | 1.000 | medium1 / medium4 / short4 / medium4 | `slidefade` | `slidefade` |
| `snappy` | `[0.1, 0.9, 0.4, 1.12]` | 1.030 | short3 / short4 / short2 / short4 | `popin 80%` | `slide` |
| `bouncy` | `[0.1, 0.9, 0.4, 1.254]` | 1.080 | short4 / medium3 / short3 / medium3 | `popin 0%` | `slidevert` |
| `wavy` | `[0.15, 2.2, 0.6, 0.4]` | 1.130, dips to 0.870 | medium1 / long1 / short4 / long1 | `popin 0%` | `slidefadevert` |

`special_workspace` follows the workspace family, not the window family — use the workspace
column's string, except `md3`/`snappy`/`bouncy` which keep `slidevert`. `windows_move` keeps
`slide` in every style: moving an existing window is not an entry animation. The `layers*`
leaves keep `popin 80%` in every style — the BRIEF probed valid style strings for the windows
and workspaces families only, so varying the layers family is unprobed and out of scope.

Every duration is a **name** from the existing `durations` table, never a new number.

Styles may also shape `spatial-out`, `spatial-move`, `standard` and the `emphasized-*` pair, but
only the three spatial names may exceed 1.0 (R-2). `smooth` and `snappy` should use that
freedom: a softer symmetric `standard` for the former, a faster-rising one for the latter.
  </action>
  <verify>
    <automated>
# Curve invariants: well-formed, x-monotonic, and overshoot confined to spatial names.
python3 - <<'EOF'
import json, sys
m = json.load(open('theme-engine/.config/theme-engine/motion.json'))
SPATIAL = {'spatial-in', 'spatial-out', 'spatial-move'}
BANDS = {'md3': (1.0, 1.0), 'smooth': (1.0, 1.0), 'snappy': (1.02, 1.05),
         'bouncy': (1.08, 1.12), 'wavy': (1.06, 1.10)}
# 260822 Task 3, two operator verdicts. Verdict 1 rejected wavy's original
# 1.10-1.25 peak band as motion-sickness-inducing, so the band itself was the
# rejected thing. Verdict 2 rejected the resulting +4% retune as reading like
# smooth -- an overcorrection. What the two verdicts together establish is that
# the SIZE of the crest was never the problem: the snap (peak at 21% of the
# duration) and the depth of the sag were. wavy is back near its original crest
# at +9.7%, reached smoothly at 54%, dipping 4.2%.
#
# 2026-08-22, verdict 3: the operator judged the wavy/bouncy NAMES backwards --
# a curve that overshoots then comes BACK DOWN reads as a bounce, not a wave --
# so the two curves and their durations were swapped. The bands swapped with the
# motion they describe: the dipping curve and its [0.94, 0.97] dip band now live
# under 'bouncy'. Peak bands overlap and cannot identify either style on their
# own; the DIP is the distinguishing assertion, and DIPS is STRICTER than the
# peak band it augments -- it pins every other style to never undershoot at all,
# which is exactly the spatial/effects invariant this task was built around.
DIPS = {'md3': (1.0, 1.0), 'smooth': (1.0, 1.0), 'snappy': (1.0, 1.0),
        'bouncy': (0.94, 0.97), 'wavy': (1.0, 1.0)}
def curve(p):
    x1, y1, x2, y2 = p; n = 2000
    xs = [3*(1-t/n)**2*(t/n)*x1 + 3*(1-t/n)*(t/n)**2*x2 + (t/n)**3 for t in range(n+1)]
    ys = [3*(1-t/n)**2*(t/n)*y1 + 3*(1-t/n)*(t/n)**2*y2 + (t/n)**3 for t in range(n+1)]
    return max(ys), min(ys[ys.index(max(ys)):]), all(xs[i+1] >= xs[i]-1e-9 for i in range(n)), min(xs), max(xs)
base = m['easings']; fail = []
for sname, s in m['styles'].items():
    ov = s.get('easings') or {}
    if set(ov) - set(base):
        fail.append(f'{sname}: introduces an easing name absent from the base table')
    eff = dict(base); eff.update(ov)
    for ename, pts in eff.items():
        if len(pts) != 4:
            fail.append(f'{sname}/{ename}: not four control points'); continue
        peak, dip, mono, xmin, xmax = curve(pts)
        if not mono or xmin < -1e-9 or xmax > 1+1e-9:
            fail.append(f'{sname}/{ename}: x is not monotonic within [0,1]')
        if ename not in SPATIAL and peak > 1.0 + 1e-6:
            fail.append(f'{sname}/{ename}: exceeds 1.0 but is not a spatial name')
    lo, hi = BANDS[sname]; peak, dip = curve(eff['spatial-in'])[0], curve(eff['spatial-in'])[1]
    if not (lo - 1e-6 <= peak <= hi + 1e-6):
        fail.append(f'{sname}: spatial-in peak {peak:.4f} outside its band [{lo}, {hi}]')
    dlo, dhi = DIPS[sname]
    if not (dlo - 1e-6 <= dip <= dhi + 1e-6):
        fail.append(f'{sname}: spatial-in dip {dip:.4f} outside its band [{dlo}, {dhi}]')
    for k, v in (s.get('semantic') or {}).items():
        if k not in m['semantic']: fail.append(f'{sname}: semantic override {k} is not a base key')
        if v.get('duration') and v['duration'] not in m['durations']:
            fail.append(f'{sname}: duration name {v["duration"]} does not resolve')
        if v.get('easing') and v['easing'] not in base:
            fail.append(f'{sname}: easing name {v["easing"]} does not resolve')
    for k, v in (s.get('hypr_leaves') or {}).items():
        if k not in m['hypr_leaves']: fail.append(f'{sname}: hypr_leaves override {k} is not a base key')
        if v.get('curve') and v['curve'] not in base:
            fail.append(f'{sname}: leaf curve {v["curve"]} does not resolve')
print('\n'.join(fail) or 'curve invariants OK')
sys.exit(1 if fail else 0)
EOF
    </automated>
    <automated>
# The dipping curve really dips on the installed Qt, not just on paper.
# Resolved by SHAPE, never by style NAME: verdict 3 swapped which style owns
# this curve, and a name-hardcoded check would have silently started
# validating the wrong style. Offscreen: no window.
QT_QPA_PLATFORM=offscreen python3 - <<'EOF'
import json, sys
from PySide6.QtCore import QEasingCurve, QPointF
m = json.load(open('theme-engine/.config/theme-engine/motion.json'))
def _dip(pts):
    x1, y1, x2, y2 = pts; n = 2000
    ys = [3*(1-t/n)**2*(t/n)*y1 + 3*(1-t/n)*(t/n)**2*y2 + (t/n)**3 for t in range(n+1)]
    return min(ys[ys.index(max(ys)):])
_dipping = [k for k, v in m['styles'].items()
            if _dip((v.get('easings') or {}).get('spatial-in') or m['easings']['spatial-in']) < 0.999]
if len(_dipping) != 1:
    print(f'expected exactly one dipping style, found {_dipping}'); sys.exit(1)
print(f'dipping style is {_dipping[0]!r}')
p = m['styles'][_dipping[0]]['easings']['spatial-in']
c = QEasingCurve(QEasingCurve.BezierSpline)
c.addCubicBezierSegment(QPointF(p[0], p[1]), QPointF(p[2], p[3]), QPointF(1.0, 1.0))
v = [c.valueForProgress(i/200) for i in range(201)]
peak = max(v); dip = min(v[v.index(peak):])
print(f'peak={peak:.4f} dip={dip:.4f} settle={v[-1]:.4f}')
sys.exit(0 if peak > 1.05 and dip < 0.98 and abs(v[-1]-1.0) < 1e-6 else 1)
EOF
    </automated>
    <automated>
# D-04: adding the four styles touched motion.json and nothing else.
test "$(git diff --name-only HEAD | grep -vc '^theme-engine/.config/theme-engine/motion.json$')" -eq 0
    </automated>
    <automated>
# Every style renders; every gate stays green; the compositor really receives the values.
set -e
for s in md3 smooth snappy bouncy wavy; do
  hypr/.config/hypr/scripts/motion-switch.sh "$s"
  test "$(jq -r '.motion_style' ~/.local/state/theme/motion.json)" = "$s"
  wantS=$(jq -r --arg s "$s" '(.styles[$s].hypr_leaves.windows_in.style // .hypr_leaves.windows_in.style)' theme-engine/.config/theme-engine/motion.json)
  gotS=$(hyprctl animations -j | jq -r '.[0][] | select(.name=="windowsIn") | .style')
  test "$gotS" = "$wantS" || { echo "windowsIn style: want '$wantS' got '$gotS'"; exit 1; }
  wantY=$(jq -r --arg s "$s" '(.styles[$s].easings["spatial-in"] // .easings["spatial-in"])[3]' theme-engine/.config/theme-engine/motion.json)
  gotY=$(hyprctl animations -j | jq -r '.[1][] | select(.name=="motion-spatial-in") | .Y1')
  awk -v a="$wantY" -v b="$gotY" 'BEGIN{exit !(a-b<0.005 && b-a<0.005)}' || { echo "spatial-in Y1: want $wantY got $gotY"; exit 1; }
  hypr/.config/hypr/scripts/hypr-equivalence-check
  hypr/.config/hypr/scripts/motion-lint
done
hypr/.config/hypr/scripts/motion-switch.sh md3
    </automated>
    <automated>
# Under md3 + full the gate extension must be a no-op — no normalization lines at all.
hypr/.config/hypr/scripts/motion-switch.sh md3
hypr/.config/hypr/scripts/motion-switch.sh --accessibility full
hypr/.config/hypr/scripts/hypr-equivalence-check 2>&1 | grep -cE 'normalized' | grep -qx 0
    </automated>
  </verify>
  <done>
All five styles exist as pure JSON data and each renders end-to-end. `git diff` for this task
touches `motion.json` and nothing else, proving D-04. For every style,
`hyprctl animations -j` reports the authored control point and the authored leaf style string,
`hypr-equivalence-check` PASSes while naming each value it normalized, and `motion-lint`
including CHECK E stays green. Overshoot exists only on spatial curves, within its authored
band. Under `md3` + `full` the gate emits no normalization lines.
  </done>
  <reversibility rating="reversible">Style values are data; the default style reduces every gate to its original comparison.</reversibility>
</task>

<task type="checkpoint:human-verify" gate="blocking-human">
  <name>Task 3: Operator render-and-judge pass — one per style, on both targets</name>
  <what-built>
The motion **scale** axis is gone. In its place: an animation **style** axis with five entries
(`md3`, `smooth`, `snappy`, `bouncy`, `wavy`), each owning its own easing curves, durations and
Hyprland window/workspace entry shapes, defined purely as data in `motion.json`. Reduce-motion
and animations-off moved to their own control. Overshoot is confined to three spatial-only
easing names, so a fade or a colour can never bounce — enforced by a new `motion-lint` CHECK E
rather than by a maintained list. The four bar drawers, previously on a hardcoded Qt easing
enum and unreachable by any theme token, now run on Motion tokens. An existing install's stored
scale value migrates automatically.
  </what-built>
  <how-to-verify>
Static gates prove the numbers arrived. They cannot prove the motion reads right. This is where
the style values are actually settled — Task 2's table is a starting point.

Restart the shell **after** the last code edit, and record `wc -l ~/.cache/quickshell.log`
**before** the restart so the log is read by offset rather than by tail — stale error blocks
from a previous run otherwise produce false failures. Do not take screenshots: a single capture
SIGSEGVs the compositor into safe mode on this host.

For each of `md3`, `smooth`, `snappy`, `bouncy`, `wavy`, switch the style and judge all four
surfaces:

1. A window opening and closing (Hyprland `windowsIn` / `windowsOut` — the entry shape).
2. A workspace switch (Hyprland `workspaces`).
3. A notification arriving (shell — duration and curve; the fade itself must **not** bounce).
4. A bar drawer sliding open (shell — now reachable by the style axis for the first time).

Watch specifically for a fade or a colour that overshoots. CHECK E proves no *statically
visible* binding can cause one, but it is blind to a runtime-computed property name (two
allow-listed sites in `Cascade.qml`) and to anything driven from JavaScript. The dashboard
cascade is the surface to watch for that.

Then once, with the style on your preference: set reduce-motion to reduced and confirm
everything shortens with no continuous indicator speeding up; set it to off and confirm
animation stops on both targets without leaving anything unthemed or half-drawn; set it back.

Per style, ask plainly: does it match its intended character — `md3` lands exactly with no
overshoot; `smooth` is longest and softest; `snappy` is short with a barely-there overshoot;
`bouncy` overshoots visibly and settles once; `wavy` overshoots then dips back before settling?
Where it does not, tune the numbers in `motion.json`, re-run Task 2's verify block, judge again.
Do not claim a style works from the static gates alone.
  </how-to-verify>
  <resume-signal>
Name each style as matching its intended character, or name the tuning it needs. Confirm all
three accessibility settings behave and that no fade or colour bounced on any style. Say
"styles approved" to finish; name a style and what is wrong with it to send it back for tuning.
Any tuning is committed and Task 2's verify block must be green against the tuned numbers.
  </resume-signal>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| `motion.json` -> Hyprland's config parser | Hand-authored data reaches a compositor parser via `hyprland-tokens.lua`, an executed Lua file |
| state files -> renderer -> Lua/QML/CSS | File contents flow into four generated targets, two of which have no readback |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-swp-01 | Tampering | `hypr_leaves` curve + style strings -> `hl.animation()` | medium | mitigate | Validated against a strict pattern and a resolvable-name check before any write (Task 1), then emitted only through `_hypr_lua_quote_string` — the sole path a string may reach Lua source through |
| T-swp-02 | Tampering | style/accessibility state files -> renderer | medium | mitigate | Both read through closed-set readers whose valid sets derive from `motion.json` keys or a literal three-value `case`; an unrecognised value defaults rather than flowing on raw. All three legacy readers move together |
| T-swp-03 | Denial of Service | malformed style override -> compositor start | high | mitigate | `theme_engine_validate_motion_values` gains the style invariants and runs before a single byte is written; a failed render leaves the live state dir byte-unchanged |
| T-swp-04 | Information disclosure | — | low | accept | No secrets or user data traverse this axis; every value is a public animation number |
| T-swp-SC | Tampering | package installs | low | accept | This task installs no packages — PySide6, jq, lua and python3 are all already present and verified on this host |
</threat_model>

<verification>
Whole-task gates, after Task 2 and again after any Task 3 tuning:

- `hypr/.config/hypr/scripts/motion-lint` and `motion-lint --self-test` both exit 0, with
  CHECK E reporting.
- `hypr/.config/hypr/scripts/hypr-equivalence-check` exits 0 under all five styles.
- `hypr/.config/hypr/scripts/colour-lint` stays green — no colour value is touched, so a
  regression there means something unrelated moved.
- `theme-engine/.config/theme-engine/theme-doctor` exits 0.
- `~/.cache/quickshell.log`, read from the offset recorded before the final restart, carries no
  new error block.
- A hypothetical sixth style is a `motion.json` edit only — demonstrated by Task 2's own
  single-file `git diff`.
</verification>

<success_criteria>
- The Animation section offers five named styles and a separate reduce-motion control.
- Each style visibly changes curve shape, duration and Hyprland entry shape, and the bar drawers
  respond to it.
- No animation targeting a fade or a colour can bind an overshooting easing, enforced by a gate
  that recognises all four syntactic forms and whose two blind spots are named and allow-listed.
- A legacy scale value migrates in one idempotent step with no manual intervention and no
  unthemed intermediate state; a fresh `stow.sh` run seeds the same two files.
- `hypr-equivalence-check` passes under every style and names every value it normalized.
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
- What CHECK E can and cannot see, and which two sites are allow-listed and why (R-2).
- That the bar drawers were structurally unreachable by any theme token before this task (R-2b).
- That there were **three** legacy closed-set readers, not the two the BRIEF named (R-4).
- That `lively`'s 1.25x has no home in the new model and migrates to `md3` + `full`.
</output>
