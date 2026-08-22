---
phase: quick-260821-swp
plan: 01
subsystem: theme-engine
tags: [hyprland, quickshell, motion, animation, lua, qml, jq, motion-lint, hypr-equivalence-check]

requires:
  - phase: 13-hyprland-lua-config-migration
    provides: "hyprland-tokens.lua as the sole Hyprland-side motion output, motion-lint CHECK A/B/C"
provides:
  - "An animation STYLE axis (md3/smooth/snappy/bouncy/wavy) replacing the motion-scale duration multiplier"
  - "A separate ACCESSIBILITY axis (full/reduced/off) for reduce-motion, reachable independent of style"
  - "Three spatial-only easing names (spatial-in/out/move) that are the ONLY names any style may give overshoot"
  - "motion-lint CHECK E: a spatial easing must never bind an effects (opacity/colour) target"
  - "hypr-equivalence-check's animation comparison now derives expected curves/leaf shapes from the active style's own effective document, not a frozen single-style baseline"
affects: [settings-window-animation-section, hypr-scripts-motion-family, quickshell-motion-consumers]

actuals:
  tokens: 38764
  tasks: 2
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Shallow-merge style overrides over base easings/semantic/hypr_leaves tables (jq `+`), one merge point shared by the renderer and the gate"
    - "Spatial/effects easing-name split as a structural (not maintained-list) safety property"

key-files:
  created:
    - hypr/.config/hypr/scripts/tests/motion-fixtures/compliant-check-e-qml.qml
    - hypr/.config/hypr/scripts/tests/motion-fixtures/poisoned-check-e-qml.qml
  modified:
    - theme-engine/.config/theme-engine/motion.json
    - theme-engine/.config/theme-engine/lib/motion.sh
    - theme-engine/.config/theme-engine/lib/gtk.sh
    - theme-engine/.config/theme-engine/lib/wallpaper.sh
    - theme-engine/.config/theme-engine/contract.json
    - hypr/.config/hypr/scripts/motion-switch.sh
    - hypr/.config/hypr/scripts/motion-lint
    - hypr/.config/hypr/scripts/hypr-equivalence-check
    - hypr/.config/hypr/config/animations.lua
    - stow.sh
    - quickshell/.config/quickshell/modules/Motion.qml
    - quickshell/.config/quickshell/modules/dashboard/Design.qml
    - quickshell/.config/quickshell/modules/settings/pages/WindowManagerPage.qml
    - quickshell/.config/quickshell/modules/settings/RowIndex.qml
    - quickshell/.config/quickshell/modules/dashboard/QuickToggles.qml
    - (33 more QML files retargeted onto spatial easings — see git log)

key-decisions:
  - "Bezier-only slate (R-1) — no Hyprland springs. hyprctl animations -j cannot see spring curves at all (structurally blind), so the gate could never verify a spring's shape; bezier keeps 100% of what a style changes visible to hypr-equivalence-check."
  - "Overshoot lives on three NEW spatial-only easing names (spatial-in/out/move), added once to the base table, never per-style. Inverting R-2 (giving fades a dedicated effects easing) would have meant 90 retargets and an unsafe default; this way costs 40 retargets (+8 bar-drawer sites) and the existing names stay permanently monotonic."
  - "Reduced-motion/off moved to its own `accessibility` axis, separate from style, per D-01 — a dashboard quick-toggle row and a Settings > Window manager row both reach it independently of the style picker."
  - "This reinstates, as a genuine user-facing setting, the kind of per-style curve data plan 13-07 removed as a measuring instrument (its own `_comment_260821_swp_reversal` records this on the record in motion.json). TOKEN-06's 'MD3 is better, spring is too fast' verdict was a tuning-parameter rejection, not a mechanism rejection — this task doesn't revisit springs at all, so neither prior decision is overturned."
  - "wavy's spatial-in control points diverge from the plan's own illustrative numbers: Hyprland's hl.curve() hard-rejects any control-point Y above 2.00 (live-verified — 'value 2.20 is more than the maximum of 2.00'), a ceiling the plan's R-1 measurement never actually hit. [0.05, 2.0, 0.3, 0.6] is the closest achievable wave (peak 1.108, dip 0.924) found by numeric search — Task 3 tunes from here."

patterns-established:
  - "Effective-document merge as the sole per-render resolution point (theme_engine_build_effective_motion_json), mirrored (not shared) by the gate — both sides carry an explicit warning that they must change together."
  - "motion-lint CHECK E: brace-aware target-property resolution (property:/properties:/Behavior on X/<T>Animation on X, ternary both arms) with a narrow, explicitly-marked allow-list for the two runtime-computed sites CHECK E cannot statically resolve."

requirements-completed: [D-01, D-02, D-03, D-04]

# Coverage metadata
coverage:
  - id: D1
    description: "Settings Animation section offers five named styles (md3/smooth/snappy/bouncy/wavy) plus a separate reduce-motion control"
    requirement: "D-01"
    verification:
      - kind: unit
        ref: "hypr/.config/hypr/scripts/motion-switch.sh --list / --list-accessibility (verified live)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Overshoot confined to spatial-in/out/move by construction; motion-lint CHECK E catches a spatial easing bound to an effects target"
    requirement: "D-02"
    verification:
      - kind: unit
        ref: "hypr/.config/hypr/scripts/motion-lint --self-test (compliant-check-e-qml.qml / poisoned-check-e-qml.qml, both verified)"
        status: pass
      - kind: integration
        ref: "motion-lint run against a poisoned full-tree copy with the target-dir argument supplied (see Deviations — the plan's own literal snippet omits it)"
        status: pass
    human_judgment: false
  - id: D3
    description: "A legacy motion-scale value migrates to style+accessibility in one idempotent step; hypr-equivalence-check passes under every style"
    requirement: "D-03"
    verification:
      - kind: unit
        ref: "scratch-dir migration test (reduced -> md3/reduced, idempotent second call, legacy file removed) — verified live"
        status: pass
      - kind: integration
        ref: "hypr/.config/hypr/scripts/hypr-equivalence-check run under md3/smooth/snappy/bouncy/wavy — verified live"
        status: pass
    human_judgment: false
  - id: D4
    description: "Adding a sixth style is a motion.json-only edit (D-04)"
    requirement: "D-04"
    verification:
      - kind: unit
        ref: "git diff --name-only HEAD after Task 2's commit — theme-engine/.config/theme-engine/motion.json only"
        status: pass
    human_judgment: false
  - id: D5
    description: "Per-style render-and-judge pass across all five styles and both accessibility settings"
    verification: []
    human_judgment: true
    rationale: "Static gates prove the numbers arrived on the compositor and in QML; they cannot prove the motion READS right, or that no runtime-computed/JavaScript-driven site bounces. This is Task 3, awaiting the operator."

duration: ~3h
completed: 2026-08-21
status: complete
---

# Quick Task 260821-swp: Replace the motion-scale axis with a style + accessibility axis Summary

**Split the single motion-scale duration multiplier into an animation STYLE axis (md3/smooth/snappy/bouncy/wavy, each owning its own curves/durations/Hyprland entry shapes) and a separate ACCESSIBILITY axis (full/reduced/off), with overshoot confined to three new spatial-only easing names enforced by motion-lint's new CHECK E.**

## Accomplishments

- Replaced `motion.json`'s `scales` table (`{multiplier, animations_enabled}`) with two theme-orthogonal axes: `styles` (five entries, each shaping easings/semantic durations/Hyprland window-workspace entry shapes) and `accessibility` (full/reduced/off).
- Added three spatial-only easing names — `spatial-in`, `spatial-out`, `spatial-move` — the ONLY names any style may ever push a control-point Y above 1.0 on. Every other easing name (`standard`, `emphasized-*`, `legacy*`, `linear`) stays monotonic in every style, forever, by construction.
- Retargeted 40 real spatial QML sites (x/y/width/height/scale/rotation/radius/implicitHeight/value) plus the 8 bar-drawer sites (previously hardcoded to `Design.barDrawerEasingType`, a Qt enum unreachable by any theme token) onto the new spatial names. Left `morph`/`litProgress` (custom cross-fade progress properties whose downstream target is a colour/opacity blend, not a literal spatial property name) and `DragGhost.qml`/`Toast.qml` (outside the plan's explicit file list) untouched.
- Added `motion-lint` CHECK E: a brace-aware scanner that resolves each `easing.bezierCurve` binding's target property through all four syntactic forms (`property:`, `properties:`, `Behavior on X`, `<T>Animation on X`) and fails when a spatial easing binds an effects target (`opacity` or any colour-valued property). Two new committed fixtures (compliant + poisoned) cover it in `--self-test`.
- Idempotent migration (`theme_engine_migrate_motion_state`): a legacy `off`/`reduced` value maps to the matching accessibility value; anything else (`normal`, `lively`) maps to `full`. Style always seeds `md3`. Closes all THREE legacy `off|reduced|normal|lively` closed-set readers — the BRIEF named two (`lib/motion.sh`, `motion-switch.sh`); a third was hiding in `hypr-equivalence-check` ~line 921.
- Rebased the dashboard's "Off | Reduced | Normal | Lively" quick-toggle segmented row and the Settings > Window manager page onto the new axes (style picker + separate reduce-motion row) — neither was explicitly named by the plan's own files_modified list, but both directly consumed the axis being removed and would have broken (reading a deleted state file, or offering now-invalid preset values) without this update.
- Fixed two real bugs in `gtk.sh`/`wallpaper.sh` that called the now-removed `theme_engine_read_motion_scale` / read the raw legacy state file directly — both updated to the new `theme_engine_read_motion_accessibility` reader.
- Added `smooth`, `snappy`, `bouncy`, `wavy` as pure JSON data in `motion.json` (Task 2) — proven by a `git diff --name-only` single-file check that adding a sixth style requires editing this file only.

## Task Commits

1. **Task 1: Split the axis and the spatial/effects easing set end-to-end, with ONE style** - `34bd0410` (feat)
   - **Deviation (Rule 1 — bug fix found live, committed separately):** `hypr-equivalence-check`'s mirrored effective-document merge dropped `.semantic`, and its curve-value comparison used a too-strict 1e-6 tolerance against Hyprland's own 2-decimal-place JSON output — `823708e4` (fix)
2. **Task 2: Add the four remaining styles — JSON only** - `545b5b5e` (feat)

**Task 3 (operator render-and-judge pass, `checkpoint:human-verify`, `gate="blocking-human"`): IN PROGRESS — first operator verdict received and acted on, remaining styles still await judgement.**

### Task 3 verdict 1 — `wavy` rejected: "will cause motion sickness" (2026-08-22)

The operator judged `wavy` unusable as shipped. Diagnosis, measured not assumed:

| | shipped | retuned |
|---|---|---|
| `spatial-in` control points | `[0.05, 2.0, 0.3, 0.6]` | `[0.3, 1.45, 0.7, 0.94]` |
| peak | +10.8% at **21%** of the duration (94ms of 450ms) | +4.0% at **62%** |
| dip after peak | **-7.6%** below target, held across the remaining 356ms | -0.5% |
| direction reversals | 2 | 1 crossing, then settles |
| `spatial-in` / `emphasized-in` duration | `long1` (450ms) | `medium2` (300ms) |
| `workspaces` / `special_workspace` | `spatial-in` (the wave) + `slidefadevert` | `spatial-move` (monotonic) + `slidefade` |

Two independent contributors were stacking, and both were removed:

1. **The curve was a different class of motion, not just a stronger one.** `wavy` was the only style in the table that ever travelled *below* its target — `bouncy` peaks +8% and settles monotonically, `snappy` +3%. It snapped its whole overshoot out in the first 94ms and then sagged for 356ms.
2. **That oscillation was wired to the largest surface available.** `workspaces` and `special_workspace` used it with `slidefadevert` — a whole-screen *vertical* slide. Full-field vertical motion that reverses direction is the strongest vestibular trigger in the set; the same curve on a single window is far milder. Per `animations.lua` `register_hypr_leaf()` a leaf's duration follows its *curve* name, so repointing these two at `spatial-move` also moved workspace switching from 450ms to 250ms as a side effect (verified live: `speed 3.0 -> 2.5`).

`smooth` already used horizontal `slidefade` for `special_workspace`, so that leaf choice follows existing precedent rather than inventing one.

**Task 2 verify block re-run against the tuned numbers — checks 1-4 green** (all five styles switch, reach the compositor with matching `windowsIn` style and `spatial-in` Y1, `hypr-equivalence-check` PASS 3 / FAIL 0 and `motion-lint` 489/0 under each). Check 5's literal `grep -cE 'normalized'` form reports 18 — **measured identical (18) with this change stashed at `d79c796e`**, i.e. pre-existing and unrelated; it is the already-recorded mis-scoping documented below in this file, and its narrow curve-section form reports 0 under md3+full as recorded.

**Task 2's wavy band was itself retuned, and deliberately made stricter rather than merely wider.** The plan asserted `wavy` spatial-in peak ∈ [1.10, 1.25] — the band encoding the rejected behaviour, so it could not survive the verdict. After retuning, wavy's *peak* (1.0398) no longer distinguishes it at all: it sits inside `snappy`'s band. Its *dip* does. The band was therefore restated as peak ∈ [1.03, 1.06] **plus a new per-style dip band** pinning every other style to never undershoot (`dip == 1.0`) and `wavy` to 0.98-0.998. That is a stronger assertion than the one it replaces, and it directly encodes the spatial/effects invariant this task was built around.

**Still owed by Task 3 (after verdict 3):** the per-style render-and-judge pass for `md3`, `smooth`, `snappy` and a re-judge of the swapped `bouncy` and `wavy`, plus the reduce-motion `full -> reduced -> off -> full` walk on both the Settings page and the dashboard quick-toggle row.


### Task 3 verdict 3 — the wavy/bouncy names were backwards (2026-08-22)

Judged on the settings window, the operator found each style's animation belonged to the other's name. The reading holds up on inspection: a curve that overshoots and then comes **back down through** the target is the snap-back of a bounce; a single smooth swell settling from above is the wave. Labels stay, motion swaps.

| | now holds | duration | shape |
|---|---|---|---|
| **bouncy** | `[0.4, 1.85, 0.75, 0.74]` | 450ms | +9.7%, dips 4.2% and returns |
| **wavy** | `[0.1, 0.9, 0.4, 1.254]` | 350ms | +8.0%, settles from above |

**The scope is wider than the settings window, and that is a schema limit rather than an oversight.** `Settings.qml` is a plain `FloatingWindow` with no animation of its own — verified, the file contains no `Behavior`, animator, or opacity/scale binding — so it renders through the shared `windowsIn` leaf, whose curve is `spatial-in`. That same curve drives `layersIn` under both styles. A style may only repoint an existing curve *name*, never add one, so there is no way to give one window its own treatment within this model. The three overshoot-capable names are all already spoken for.

**Required safety change, included.** `bouncy` is the style that puts full-screen motion on `spatial-in`, so handing it the dipping curve would have put a reversal back onto a whole-screen **vertical** slide — exactly the combination behind verdict 1. Its `workspaces` and `special_workspace` therefore moved to the monotonic `spatial-move` curve while keeping `slidevert`; `special_workspace` needed an explicit override because the base table points it at `spatial-in`. Duration follows curve name, so bouncy's workspace switch also went **350ms → 200ms** — fast and monotonic, but a real change worth watching during the judging pass.

**The invariant is now universal:** no style puts a reversing curve on whole-screen motion. Convergence is unchanged (`bouncy`/`wavy` still 2/8) and window-open duration stays unique across all five (200/300/350/400/450).

**A gate hardening came out of this.** Task 2's Qt check hardcoded `m['styles']['wavy']` to assert "wavy is a real wave". After the swap that check would have silently validated the wrong style — passing while testing a curve that no longer dips. It now resolves the dipping style **by shape**, and fails if there is not exactly one. Style names are labels; the shape is the thing worth asserting on.


### Task 3 — convergence sweep across all five styles (2026-08-22)

After verdict 2, all five styles were measured against the three failure modes wavy had hit, rather than assuming wavy was the only offender.

**Trap 1, the snap — clean, and unique to the rejected shape.** The discriminator is not front-loading (every style completes 69-78% of its travel by 20% of its duration, normal decelerate behaviour) but whether the curve has already passed the target by then. The rejected `[0.05, 2.0, 0.3, 0.6]` was at **111%**; nothing shipped exceeds 78%.

**Trap 2, reversal on whole-screen motion — clean, one item to watch.** `wavy` is the only style whose curve reverses at all, and the only one whose full-screen leaves sit on a monotonic curve. `bouncy` is the nearest neighbour to the failure: a +8% overshoot on a full-screen **vertical** slide on both `workspaces` and `special_workspace` at 350ms. It never reverses and has not been reported as sickening, but it carries the highest residual risk and should be judged deliberately.

**Trap 3, convergence — wavy/smooth fixed, a new pair found and fixed.** The complaint pair went from 3/8 shared axes (including workspace shape, the most-seen animation) to 1/8. But `bouncy` and `wavy` had come to share **both** window-open axes — `popin 0%` and 350ms — with peaks of 8.0% vs 9.7%, leaving only wavy's 4.2% dip to separate them on that surface. The duration collision was introduced by this task's own previous commit. Measured against the alternatives, 450ms drops the pair to 2/8 with no new collision while 400ms only trades it for a `smooth`/`wavy` clash; window-open duration is now unique across all five styles (200/300/350/400/450).

**Structural note.** `bouncy`'s `standard` easing and duration are byte-identical to `md3`'s, and `wavy` shares md3's curve differing only in duration — only `smooth` and `snappy` override `standard`. So `bouncy` and `wavy` change *spatial* motion only; non-spatial UI motion in the bar and panels is md3's throughout. That follows directly from the spatial/effects split this task is built on, so it is by design rather than a defect, but it means those two styles do not express their character outside windows, panels and workspaces.


### Task 3 verdict 2 — three findings (2026-08-22)

**(a) `wavy` had converged on `smooth` — the first retune overcorrected.** Measuring all five styles side by side showed why:

| style | window-in | dur | workspace style | ws dur | peak |
|---|---|---|---|---|---|
| md3 | popin 60% | 300 | slide | 300 | 1.0000 |
| smooth | slidefade | 400 | slidefade | 400 | 1.0000 |
| snappy | popin 80% | 200 | slide | 200 | 1.0301 |
| bouncy | popin 0% | 350 | slidevert | 350 | 1.0802 |
| **wavy (after retune 1)** | popin 0% | 300 | **slidefade** | 250 | **1.0398** |

The retune had made workspace switching — the animation seen most often — identical in *shape* to smooth's, leaving wavy differentiated only by a +4% crest that is close to invisible and a `popin 0%` it already shares with bouncy.

Taken together the two verdicts establish that **the size of the crest was never the problem**; the snap (peak at 21% of the duration) and the depth of the sag were. So the crest returns and the snap does not: `spatial-in` → `[0.4, 1.85, 0.75, 0.74]` (peak **+9.7%** vs the original +10.8%, but reached at **54%** of the duration rather than 21%, dipping **4.2%** rather than 7.6%, over **350ms** rather than 450ms), and `workspaces`/`special_workspace` go back to **vertical** `slidefadevert` while staying on the **monotonic** `spatial-move` curve at 250ms.

That split is the whole point, and it rests on a measurement rather than a preference: `bouncy` has been running a full-screen vertical `slidevert` at 350ms with a +8% overshoot throughout, and was never reported as sickening. Vertical motion was not the trigger — vertical motion that *reverses direction* over 450ms was. Horizontal was tried in retune 1 and is exactly what made wavy read as smooth.

**(b) The settings animation-style row needed selecting twice.** `applyMotionStyle()` started the apply process and the authoritative `--get` re-read in the *same tick*. `motion-switch.sh` writes the state file and then re-renders; `--get` reads that same file. `--get` won the race, read the **previous** value, and assigned it back over `currentMotionStyle`. Because `SelectRow` is fully controlled (`currentDisplay` derives only from `currentValue`, no internal selection state), the row visibly snapped back — and the second pick appeared to work only because it read the value the *first* pick had by then finished writing. Fixed by chaining the re-read off the apply process's own `onExited`, plus an optimistic assignment so the row responds immediately. The reduce-motion row had the identical race and got the identical fix.

**(c) Changing the animation style claimed a colour-theme switch.** `theme-apply` ends with an unconditional `notify-send "Theme Applied — Switched to <name>"`, and `motion-switch.sh` calls it purely to re-render. It now honours `THEME_APPLY_QUIET=1`, which suppresses that **success** toast only — both error notifications untouched — and `motion-switch.sh` sets it on its single re-render call site. Passed as an env var rather than a flag deliberately: `theme-apply` enforces a strict 1–2 positional arity that `theme-init.sh`, the walker dmenu picker and the wallpaper picker all depend on.

**Verify after verdict 2:** checks 1–4 green across all five styles (`hypr-equivalence-check` PASS 3 / FAIL 0, `motion-lint` 489/0 each); `colour-lint` 305/0, `settings-index-check` 116/0, `quickshell-doctor` 28/0; `bash -n` and `shellcheck -S error` clean on both shell files. The wavy peak band moved to [1.08, 1.12] and its dip band to [0.94, 0.97] — the peak band now overlaps bouncy's and no longer identifies wavy on its own, so **the dip band is the distinguishing assertion**, and it still pins every other style to never undershoot at all.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `gtk.sh` and `wallpaper.sh` called the removed `theme_engine_read_motion_scale` / read the legacy state file directly**
- **Found during:** Task 1, while auditing every consumer of the old axis (not itself in the plan's files_modified list, but a genuine live consumer)
- **Issue:** `gtk.sh`'s GTK `enable-animations` portal signal and `wallpaper.sh`'s reduced-motion wallpaper-visibility check both called a function/read a file this task's migration removes. Left as-is, both would have silently defaulted to "always full" behaviour the moment `motion-scale` was migrated away.
- **Fix:** Both now call `theme_engine_read_motion_accessibility`.
- **Files modified:** `theme-engine/.config/theme-engine/lib/gtk.sh`, `theme-engine/.config/theme-engine/lib/wallpaper.sh`
- **Commit:** `34bd0410`

**2. [Rule 1 - Bug] The dashboard's motion-scale segmented quick-toggle row and the Settings Window Manager page both read/wrote the old single axis directly**
- **Found during:** Task 1, while grepping for every `motion-scale` reference in the repo
- **Issue:** `QuickToggles.qml`'s "Off | Reduced | Normal | Lively" row read `~/.local/state/theme/motion-scale` (deleted by migration) and called `motion-switch.sh <value>` with values (`normal`/`lively`) no longer valid presets. `WindowManagerPage.qml`'s "Animation speed" `SelectRow` parsed the old `--list` format (`  Name (x1.0)`) which no longer matches the new tab-separated format.
- **Fix:** `QuickToggles.qml`'s row now shows Off/Reduced/Full and calls `motion-switch.sh --accessibility <value>` — this is also the concrete answer to D-01's "reachable from a control that is not the style picker" requirement. `WindowManagerPage.qml` now has two independent `SelectRow`s (style + reduce-motion) parsing the new `--list`/`--list-accessibility` format.
- **Files modified:** `quickshell/.config/quickshell/modules/dashboard/QuickToggles.qml`, `quickshell/.config/quickshell/modules/settings/pages/WindowManagerPage.qml`, `quickshell/.config/quickshell/modules/settings/RowIndex.qml`
- **Commit:** `34bd0410`

**3. [Rule 1 - Bug] hypr-equivalence-check's style-aware gate had two real bugs, found during Task 2's live per-style verification**
- **Found during:** Task 2, running the render+hyprctl+gate loop across all five styles
- **Issue:** (a) The gate's own mirror of `theme_engine_build_effective_motion_json` omitted `.semantic` from the shallow merge, so every leaf whose speed traces to a semantic entry a style overrides (13 of 15 leaves — everything except `border`/`borderangle`) computed its expected speed against the BASE duration rather than the active style's, producing false FAILs under every non-md3 style. (b) The curve-value comparison used a 1e-6 tolerance against Hyprland's `-j` output, which rounds to 2 decimal places (an authored `1.254` reads back `1.25`), producing a false FAIL for `bouncy`.
- **Fix:** Added `.semantic` to the merge; widened the curve tolerance to `0.006`.
- **Files modified:** `hypr/.config/hypr/scripts/hypr-equivalence-check`
- **Commit:** `823708e4` (committed separately from Task 2, per D-04's own instruction: "If you find yourself needing a second file in Task 2, that is a signal Task 1's structure is wrong — stop and report it rather than widening Task 2 silently." This is exactly that signal — the fix belongs to Task 1's gate, not Task 2's data-only promise, so it landed as its own commit between the two, keeping Task 2's `git diff --name-only` a true single-file proof.)

**4. [Rule 1 - Bug] wavy's plan-specified spatial-in control points violate a real Hyprland ceiling**
- **Found during:** Task 2, live per-style render loop — `hyprctl configerrors` reported `hl.curve("motion-spatial-in"): point 1[2]: value 2.20 is more than the maximum of 2.00` after switching to `wavy`, and the curve silently kept its PREVIOUS (bouncy's) registration rather than erroring the reload.
- **Issue:** The plan's own Task 2 table specifies `wavy`'s `spatial-in` as `[0.15, 2.2, 0.6, 0.4]` (peak 1.130, dip 0.870) — the BRIEF's R-1 measurement never live-tested a control point this high (it stopped at Y1.15), so this ceiling was never caught before being written into the plan.
- **Fix:** Replaced with `[0.05, 2.0, 0.3, 0.6]` (right at the ceiling), found by numeric search over the achievable overshoot/dip space — peak 1.108, dip 0.924 (still passes both the plan's own band check `[1.10, 1.25]` and the PySide6 wavy-peak/dip assertion). A real overshoot-then-undershoot, just less pronounced than the original illustrative numbers.
- **Files modified:** `theme-engine/.config/theme-engine/motion.json`
- **Commit:** `545b5b5e`

### Plan verify-script issues found (not code defects — documented for the record)

- **CHECK E's own poisoned-copy verify snippet doesn't test what it says.** The plan's literal block (`cd "$W" && "$OLDPWD/.../motion-lint"`, no target-dir argument) scans motion-lint's DEFAULT hardcoded ROOTS (`$HOME/.config/quickshell` etc.) regardless of `cd`, which on this host are real directories whose CONTENTS are individually stow-symlinked back to this same repo — so the poisoned copy in `$W` is never actually read; the real (clean) repo is rescanned instead, and the check reports "did not catch" even though CHECK E genuinely works. Verified two ways instead: (1) `motion-lint --self-test`, which DOES pass the fixture's own temp dir as an explicit target-dir argument, passes 12/12 including the two new CHECK E fixtures; (2) re-running the plan's own snippet with `"$W"` appended as motion-lint's argument reports "CHECK E catches the poisoned case" correctly. CHECK E is real and proven; the plan's own ad-hoc shell snippet has a latent argument-omission bug.
- **The "zero normalization lines under md3+full" check is broader than what Task 2 actually touches.** `grep -cE 'normalized'` over the gate's FULL output also matches ~16 pre-existing, motion-unrelated lines (Hyprland option `bool`/`int` type-key folding, present before this task and unrelated to it) plus ONE motion-related line: Task 1's own permanent leaf-bezier rename (`windowsIn`'s bezier literally changed name from `motion-emphasized-decelerate` to `motion-spatial-in` — true under EVERY style, including md3, since Task 1 renamed these curve references once, not per-style). Neither is something Task 2's four-style addition introduces or could eliminate without contradicting the plan's own "report every normalization, never hide it" mandate. Scoped narrowly to what Task 2 actually changes (the CURVE table's expected-value derivation), zero curve-section normalization lines appear under md3+full — confirmed directly.

### Known pre-existing environmental artifact (not this task's regression)

- `hypr-equivalence-check` reports one FAIL under every style: `+ curve present in live only: ('zztest', 0.05, 0.9, 0.1, 1.15)`. This is a leftover manually-registered probe curve from the BRIEF's own live R-1 measurement session (same exact control-point values the BRIEF documents), still resident in this long-running Hyprland process's curve registry (Hyprland does not clear custom curve registrations on `reload`, only on a full compositor restart). It is not declared anywhere in this repo's config in either era, predates every commit in this task, and would fail this exact gate identically with or without any of this task's changes. Not fixed here — clearing it would require restarting the compositor mid-session, out of scope and risky per this host's own hazards.

## Known Stubs

None — every consumer (renderer, gate, CLI, dashboard row, settings page) is wired to real data; no placeholder values ship.

## Threat Flags

None — this task adds no new network endpoints, auth paths, or trust-boundary-crossing surfaces. The style/accessibility state files and `hypr_leaves` curve/style strings reach Hyprland's own parser exactly as the removed `motion-scale` axis already did, validated the same way (closed-set readers, a strict style-string pattern, resolvable-name checks before any write).

## What Task 3 (the operator) still needs to do

This plan's Task 3 is a `type="checkpoint:human-verify"` with `gate="blocking-human"` — per this execution's instructions, it was **not attempted, simulated, or marked complete**. It requires:

1. Restart the Quickshell shell **after** this task's last edit (already true — no further edits are pending), recording `wc -l ~/.cache/quickshell.log` **before** the restart so the log can be read by offset, not tail.
2. For each of `md3`, `smooth`, `snappy`, `bouncy`, `wavy` (switch via Settings > Window manager > Animation style, or `motion-switch.sh <style>`), judge all four surfaces: a window opening/closing, a workspace switch, a notification arriving (must NOT bounce), and a bar drawer sliding open (now reachable by the style axis for the first time).
3. Set reduce-motion to `reduced` then `off` (Settings > Window manager > Reduce motion, or the dashboard's quick-toggle row) and confirm behaviour on both targets, then set it back to `full`.
4. Name each style as matching its intended character or name what tuning it needs (particularly `wavy`, whose numbers changed from the plan's own illustrative values per Deviation #4 above), watching the dashboard Cascade specifically for the two allow-listed runtime-computed sites CHECK E cannot see.
5. Any tuning lands as an edit to `theme-engine/.config/theme-engine/motion.json` only, then Task 2's verify block re-runs against the tuned numbers.

**Environment left in a clean, default state for the operator:** style `md3`, accessibility `full`, no `hyprctl configerrors`, `~/.cache/quickshell.log` not inspected/consumed by this execution.

## Self-Check: PASSED

All claimed files exist on disk; all three claimed commit hashes (`34bd0410`, `823708e4`, `545b5b5e`) exist in `git log`.
