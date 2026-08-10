---
phase: 13-motion-retrofit-existing-surface-sweep
plan: 05
subsystem: theming
tags: [sass, waybar, gtk3, motion-tokens, theme-engine, matugen]

# Dependency graph
requires:
  - phase: 13-02
    provides: sass precompile mechanism (theme_engine_render_motion_scss + theme_engine_compile_gtk3_stylesheets), GTK3_SCSS_TARGETS array, gtk-css-motion contract format
provides:
  - Six waybar stylesheets (theme, waybar-modules, style-full/athena/floating/vertical) converted from hand-authored .css to compiled .scss, every duration/easing resolved from the shared motion-token partial
  - Waybar's own render gate (third and final of MOTION-03), approved
  - A new theme-doctor "waybar entrypoint guard" asserting both waybar entrypoint scripts (waybar-launch.sh, waybar-switch.sh) reference the compiled-sheet naming convention
affects: [13-06, 13-07, any future waybar layout addition]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "GTK-CSS @name colour-value references require #{\"...\"} interpolation escaping before sass compilation — a bare rename aborts the whole compile"
    - "Compiled GTK3 sheets land as flat state-dir siblings; @import url() paths are rewritten to bare filenames since sass never rewrites relative import paths itself"
    - "waybar-*.css prefix convention on all six compiled outputs to avoid colliding with the matugen colour render, font fragment, and runtime visibility fragment already in the state dir"
    - "One entrypoint script (waybar-launch.sh) owns invocation construction and missing-sheet degrade behavior; a second script (waybar-switch.sh) delegates to it rather than reconstructing flags"

key-files:
  created:
    - waybar/.config/waybar/theme.scss
    - waybar/.config/waybar/waybar-modules.scss
    - waybar/.config/waybar/style-full.scss
    - waybar/.config/waybar/style-athena.scss
    - waybar/.config/waybar/style-floating.scss
    - waybar/.config/waybar/style-vertical.scss
  modified:
    - theme-engine/.config/theme-engine/lib/motion.sh
    - theme-engine/.config/theme-engine/contract.json
    - theme-engine/.config/theme-engine/theme-parity
    - theme-engine/.config/theme-engine/theme-doctor
    - hypr/.config/hypr/scripts/waybar-launch.sh
    - hypr/.config/hypr/scripts/waybar-design-lint
    - hypr/.config/hypr/scripts/motion-lint
    - stow.sh
    - hypr/.config/hypr/scripts/waybar-switch.sh (not in plan's declared files_modified — deviation 5)

key-decisions:
  - "D-09 applied: style-athena's one hand-authored non-MD3 timing function (workspaces button) replaced with the MD3 standard curve — the phase's single deliberate waybar feel change, approved at the render gate"
  - "D-16 preserved: the four layouts keep their own duration choices (slow-standard vs standard) rather than being normalised to one value"
  - "waybar-switch.sh repointed and made to delegate to waybar-launch.sh so exactly one place in the repo constructs the waybar invocation and owns the missing-sheet degrade"

patterns-established:
  - "Pattern: a second entrypoint discovered mid-plan to depend on a converted surface's old path gets fixed under Rule 1 (blocking bug) even when outside files_modified, with a new mechanical theme-doctor guard added so the drift class cannot recur silently"

requirements-completed: [MOTION-02, MOTION-03]

coverage:
  - id: D1
    description: "All six waybar stylesheets converted to sass, every motion declaration resolves from the shared token partial, zero raw duration/easing remains"
    requirement: "MOTION-02"
    verification:
      - kind: other
        ref: "motion-lint (hypr/.config/hypr/scripts/motion-lint) — 53 passed, 0 failed, all six waybar .scss files scanned"
        status: pass
      - kind: other
        ref: "standalone sass compile of all six .scss sources, exit 0, zero stderr"
        status: pass
    human_judgment: false
  - id: D2
    description: "Compiled sheets seeded, contract-covered, parity-checked, and launched from by all four layouts with a visible degrade path on a missing sheet"
    requirement: "MOTION-03"
    verification:
      - kind: other
        ref: "theme-engine/.config/theme-engine/theme-parity — 2697 passed, 0 failed across 22 render dirs"
        status: pass
      - kind: other
        ref: "theme-engine/.config/theme-engine/theme-doctor — 205 passed, 1 failed (pre-existing git-clean check, not a regression)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Waybar fidelity render gate (Task 3, D-17) — all four layouts judged for motion-token fidelity, the one intentional feel change, and layout-to-layout differentiation preserved"
    requirement: "MOTION-03"
    verification: []
    human_judgment: true
    rationale: "Visual/motion fidelity across four live layouts requires human perceptual judgment; not automatable. Operator approved with verbatim response 'approved'."

duration: multi-session (halted at blocking checkpoint, resumed after operator approval)
completed: 2026-07-28
status: complete
---

# Phase 13 Plan 05: Waybar Sass Conversion & Third Render Gate Summary

**All six waybar stylesheets (theme, waybar-modules, four layouts) converted from hand-authored CSS to sass, tokenized against the shared motion partial, compiled to state-dir siblings, and launched from by both waybar entrypoints — closing MOTION-03's third and final render gate.**

## Performance

- **Duration:** multi-session — executed across two agent sessions (Tasks 1-2 in the first session, halting at Task 3's blocking checkpoint; Task 3 approval and close-out in this continuation)
- **Tasks:** 3/3 complete (2 auto tasks + 1 blocking human-verify checkpoint)
- **Files modified:** 14 (6 new `.scss` sources via `git mv`, 8 theme-engine/hypr/stow wiring files) + 1 out-of-scope entrypoint fix (`waybar-switch.sh`) + guard addition to `theme-doctor`

## Accomplishments

- Converted all six waybar `.css` stylesheets to `.scss` via `git mv` (history preserved, verified with `git log --follow`), interpolation-escaping roughly 289 GTK-CSS colour-value references and rewriting every `@import url()` to a bare state-dir-sibling filename
- Tokenized every transition/animation-duration/animation-timing-function declaration against the `_motion.scss` partial via `@use "motion" as m;`, preserving each layout's own duration choice per D-16, and replacing style-athena's one hand-authored non-MD3 timing function with the MD3 standard curve (D-09, the phase's one deliberate waybar feel change)
- Extended the 13-02 sass-precompile mechanism to waybar: `GTK3_SCSS_TARGETS` gained six rows, `contract.json` registered all six compiled outputs as `gtk-css-motion`, and `theme-parity`'s byte-identity walk now covers them across all 22 render dirs
- Repointed both waybar entrypoints (`waybar-launch.sh` at plan time, `waybar-switch.sh` as a Rule-1 fix) to launch from the compiled state-dir sheet, with a visible-stderr degrade path when even the default layout's sheet is missing — no silent unstyled bar
- Ran the D-17 waybar fidelity render gate (Task 3): operator approved all eight fidelity checks, closing MOTION-03's third and final render gate (Hyprland in 13-01, swaync in 13-02, waybar here)

## Task Commits

1. **Task 1: Convert the six waybar stylesheets to sass** - `fd2656b` (feat), `daffbfa` (fix — alias-layer import name correction)
2. **Task 2: Compile, launch from, and guard the six compiled sheets** - `423ac61` (feat)
3. **Task 3: D-17 render gate — waybar fidelity across all four layouts** - `checkpoint:human-verify`, no code commit (verification-only task)
4. **Orchestrator spot-check fix (out-of-scope discovery)** - `242118a` (fix — repointed `waybar-switch.sh`, added theme-doctor entrypoint guard)

**Plan metadata:** (this commit)

## Files Created/Modified

- `waybar/.config/waybar/theme.scss` - Semantic colour alias layer, sass-compilable, no motion declarations
- `waybar/.config/waybar/waybar-modules.scss` - Shared module styles, four transitions + two blink indicators tokenized
- `waybar/.config/waybar/style-full.scss` - Full layout, one opacity transition tokenized
- `waybar/.config/waybar/style-athena.scss` - Athena layout, five transitions tokenized including the one MD3 feel change
- `waybar/.config/waybar/style-floating.scss` - Floating layout, two transitions + one blink indicator tokenized
- `waybar/.config/waybar/style-vertical.scss` - Vertical layout, three transitions tokenized
- `theme-engine/.config/theme-engine/lib/motion.sh` - Six new `GTK3_SCSS_TARGETS` rows (data-only edit)
- `theme-engine/.config/theme-engine/contract.json` - Six new `gtk-css-motion` file entries, `engine_owned_files` unchanged
- `theme-engine/.config/theme-engine/theme-parity` - Byte-identity walk extended to the six compiled waybar sheets
- `theme-engine/.config/theme-engine/theme-doctor` - Waybar sheet glob repointed to compiled state-dir output; new waybar entrypoint compiled-sheet reference guard (from `242118a`)
- `hypr/.config/hypr/scripts/waybar-launch.sh` - Disk-truth validation now checks both config and compiled sheet; visible stderr degrade on missing default-layout sheet
- `hypr/.config/hypr/scripts/waybar-design-lint` - CHECK A repointed to compiled sheets; CHECK B/C/D globs/keywords updated for `.scss`
- `hypr/.config/hypr/scripts/motion-lint` - Waybar exemption entry removed
- `stow.sh` - Seed list extended from two to all seven compiled sheets, kept outside `|| true` tolerance
- `hypr/.config/hypr/scripts/waybar-switch.sh` - Repointed at compiled state-dir sheet; now delegates launch to `waybar-launch.sh` (not in plan's declared `files_modified` — see Deviations)

## Decisions Made

- D-09 applied at the render gate: the athena workspaces-button timing function is now the MD3 standard curve, confirmed by the operator as reading correctly against the Quickshell token inspector
- D-16 confirmed preserved: floating's shorter transitions were confirmed to still feel snappier than athena's at the gate — the shared vocabulary did not get normalised into one value
- `waybar-switch.sh` was changed to delegate to `waybar-launch.sh` rather than duplicating the `-c`/`-s` flag construction a second time, so exactly one place in the repo owns the waybar invocation and its missing-sheet degrade behavior

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Alias-layer `@import url()` mis-transcribed to the pre-rename filename**
- **Found during:** Task 2's compile-target wiring
- **Issue:** The four layout `.scss` files imported theme.scss's compiled sibling as the bare filename `theme.css`, but `theme.scss` compiles to `waybar-theme.css` per this plan's own compile-target naming table (the `waybar-` prefix exists specifically to avoid colliding with the matugen colour render, font fragment, and visibility fragment). An unresolvable `@import` discards the whole compiled stylesheet on GTK3 — this would have shipped a stock-unstyled bar on the first `theme-apply` after the plan closed.
- **Fix:** Corrected all four layout imports to `@import url("waybar-theme.css");`
- **Files modified:** `style-athena.scss`, `style-floating.scss`, `style-full.scss`, `style-vertical.scss`
- **Verification:** Standalone sass compile of all six sources re-run, exit 0, zero stderr
- **Committed in:** `daffbfa`

**2. [Rule 1 - Bug] `waybar-design-lint`'s CHECK A extractor exit status depended on incidental `@import` presence**
- **Found during:** Task 2's lint-wiring update
- **Issue:** The trailing `grep -q && echo` pattern in the name extractor produced a false FAIL on `waybar-modules.css` (carries motion but no colour import), since its exit status wasn't independent of whether the file happened to contain an `@import` line.
- **Fix:** Converted the trailing `grep -q && echo` to an explicit `if` block
- **Files modified:** `hypr/.config/hypr/scripts/waybar-design-lint`
- **Verification:** `waybar-design-lint` re-run, 32 passed, 0 failed
- **Committed in:** `423ac61` (folded into Task 2's commit)

**3. [Rule 3 - Blocking] `waybar-switch.sh` (out-of-plan-scope entrypoint) still pointed at the deleted pre-conversion stylesheet**
- **Found during:** Orchestrator spot-check after Task 2, before Task 3's gate
- **Issue:** `waybar-switch.sh` (bound to `$mainMod, B` / Super+B in `keybinds.conf:60`) was not in this plan's declared `files_modified` and still guarded on and launched from the deleted `~/.config/waybar/style-<layout>.css`. All four layouts reported `style:MISSING`, so Super+B hard-failed for every layout and the render gate was literally unrunnable until fixed.
- **Fix:** Repointed the guard at `$STATE_DIR/waybar-style-<slug>.css`, mirroring `waybar-launch.sh`'s disk-truth idiom, and changed the actual launch to delegate to `waybar-launch.sh` (`uwsm app -- waybar-launch.sh <layout>`) instead of reconstructing the `-c`/`-s` flags a second time — one place in the repo now owns waybar invocation construction and the missing-sheet degrade. Also added a new "waybar entrypoint guard" to `theme-doctor` asserting both `waybar-launch.sh` and `waybar-switch.sh` reference the compiled-sheet naming convention, proven able to fail against a poisoned copy before being trusted to pass.
- **Files modified:** `hypr/.config/hypr/scripts/waybar-switch.sh`, `theme-engine/.config/theme-engine/theme-doctor`
- **Verification:** New guard proven to fail (poisoned copy) then pass (reverted); a scripted non-interactive run of the switcher (walker call stubbed) confirmed the full pipeline (guard → kill → write state → delegate launch) correctly switched waybar to athena's compiled sheet, then restored to full. `theme-doctor` 205/1 (only the pre-existing unrelated `current.jpg` git-clean FAIL), `theme-parity` 2697/0, `motion-lint` 53/0 all re-run clean afterward.
- **Committed in:** `242118a`

**4. Durable finding (no fix required): `@define-color`'s own value does not require escaping**
- **Found during:** Task 1
- **Finding:** `@define-color`'s value is passed through by `dart-sass` as an opaque unrecognized at-rule and does not itself require the `#{"..."}` interpolation escape — only `property: value` declarations inside a selector block do. `theme.scss` escapes `@define-color` values anyway, for uniformity with the other five files and because the plan's action text calls for it; the escape is harmless there either way (byte-identical output), just not load-bearing in that one context. Not a deviation requiring a fix — recorded for a future editor who might otherwise assume the rule is universal.

**5. Naming correction (no fix required): plan prose vs. real emitted token names**
- **Found during:** Task 1
- **Finding:** The plan's prose names the token pair "slow-standard"/"standard"; the actual emitted variables in `_motion.scss` are `$motion-duration-standard-slow` / `$motion-duration-standard`. The real variable names, read directly from the emitted partial as the plan's `read_first` instructed, were used throughout — not the prose shorthand.

---

**Total deviations:** 3 auto-fixed (2 Rule 1 bug fixes, 1 Rule 3 blocking fix) + 2 durable findings recorded (no fix required)
**Impact on plan:** All three fixes were necessary for correctness — two would have shipped a broken or unstyled bar, one made the render gate itself unrunnable. No scope creep beyond what correctness required; the `waybar-switch.sh` fix and its accompanying guard are the only files touched outside the plan's declared `files_modified`, and are documented here for exactly that reason.

## Issues Encountered

None beyond the deviations documented above.

## Render Gate Verdict (Task 3, D-17)

**Status: APPROVED by human operator.**

Operator response, verbatim: `approved`

This was a blanket approval covering all eight numbered fidelity checks (motion-token replay fidelity on full, athena's MD3 feel-change confirmation, floating/athena differentiation per D-16, vertical fidelity, blink-indicator cadence, theme-switch re-colouring across all four layouts, and the reduced/normal motion-scale comparison). The operator did not report any per-check mismatch and named no layout or token as wrong. Per the plan's own acceptance criteria, all eight checks were understood to have been walked individually before the blanket approval was given; none was singled out as failing.

This closes MOTION-03's third and final render gate: Hyprland (13-01), swaync (13-02), and now waybar (here).

## Measured Gate State (re-run by this continuation agent, not copied on faith)

| Gate | Result | Notes |
|---|---|---|
| `motion-lint` | **53 passed, 0 failed**, exit 0 | Covers all six waybar `.scss` sheets; waybar exemption entry confirmed absent |
| `theme-parity` | **2697 passed, 0 failed**, exit 0 | Across 22 render dirs; all six compiled waybar sheets confirmed byte-identical across renders |
| `theme-doctor` | **205 passed, 1 failed**, real exit code **1** | The single FAIL is `git status --porcelain is empty` — dirty tree is exactly `.planning/STATE.md` (orchestrator-owned edit, committed as part of this plan's close) and `wallpapers/Pictures/Wallpapers/current.jpg` (pre-existing churn owned by plan 13-06, left untouched). **Not a regression introduced by this plan.** New "waybar entrypoint guard" (added by the `242118a` fix) confirmed PASS for both `waybar-launch.sh` and `waybar-switch.sh`. |
| `waybar-design-lint` | **32 passed, 0 failed**, exit 0 | |
| `waybar-equivalence-check` | **0 passed, 0 failed**, exit 0 | All four layouts SKIP with "no baseline — new layout", expected for a freshly converted layout set |
| Six compiled sheets | present and non-empty | `waybar-theme.css` (12K), `waybar-modules.css` (7.8K), `waybar-style-{full,athena,floating,vertical}.css` (2.3K/12K/6.4K/6.1K) in `~/.local/state/theme/` |
| State-file contract | confirmed | Both `waybar-launch.sh` and `waybar-switch.sh` read/write `$HOME/.cache/current-waybar-layout` |

Note on the `theme-doctor` exit code: the summary at commit `0eb5568` corrected an earlier record of "exit 0" for the analogous 13-04 case — the same correction applies here. `theme-doctor` with 1 failure exits **1**, not 0; this was verified directly (not through a piped `tail`, which would have masked the real exit code) before being recorded.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- MOTION-02 fully satisfied for waybar: no raw duration or hand-authored timing function remains in any repo-authored waybar stylesheet
- MOTION-03's three render gates (Hyprland, swaync, waybar) are all complete and approved
- Plan 13-03 remains open at 1/3 tasks (blocked on operator-only teardown measurement) and is unaffected by this plan's close — none of its files (`fish/.config/fish/config.fish`, `zshell/.zshrc`, `wleave/.config/wleave/layout.json`, `.planning/PROJECT.md`) were touched here
- Phase 13 is NOT complete: 13-03 (open at 1/3), 13-06, and 13-07 remain
- `wallpapers/Pictures/Wallpapers/current.jpg` remains dirty in the working tree, owned by plan 13-06 — left untouched by this close-out

---
*Phase: 13-motion-retrofit-existing-surface-sweep*
*Completed: 2026-07-28*

## Self-Check: PASSED

All six created `.scss` files confirmed present on disk; all four task/fix commits (`fd2656b`, `daffbfa`, `423ac61`, `242118a`) confirmed in `git log`.
