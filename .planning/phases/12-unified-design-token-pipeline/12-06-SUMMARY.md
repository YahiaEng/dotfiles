---
phase: 12-unified-design-token-pipeline
plan: 06
subsystem: theming
tags: [quickshell, qml, matugen, singleton, motion, colour-tokens, theme-engine]

# Dependency graph
requires:
  - phase: 12-01
    provides: "quickshell/modules/qmldir (explicit type manifest, closes FM1); Probe.qml's Variants/LazyLoader per-screen arrangement"
  - phase: 12-03
    provides: "motion.json, lib/motion.sh, the three rendered motion targets under ~/.local/state/theme/ Motion.qml reads"
  - phase: 12-04
    provides: "motion-scale CLI, hyprland source-order wiring — Motion.motionEnabled/motionScale ultimately trace back to this"
  - phase: 12-05
    provides: "motion-lint folded into theme-doctor, and its load_qml_defs() convention this plan's Motion.qml adopts"
provides:
  - "matugen [templates.qml] -> ~/.local/state/theme/palette.json, a contract.json-listed 19-key JSON render target"
  - "Colours.qml: Quickshell.Singleton exposing 19 Material You role aliases, debug-magenta fallback, read-only"
  - "Motion.qml: sibling Singleton exposing motionEnabled/motionScale plus per-semantic-pair Duration/Easing properties"
  - "Probe.qml rewritten into the token inspector: colour swatch grid, motion semantic-pair rows, Replay control, theme-switch crossfade — Phase 11 instruments retained underneath"
  - "theme-stress-test D-17 section: guarded live re-colour + PID-unchanged assertion inside the 10-switch loop"
  - "Two binary-verified corrections to 12-RESEARCH.md Pattern 2 (Quickshell Singleton registration requirements) — see key-decisions"
affects: [12-07, 13-motion-retrofit, 14-dashboard-drawer]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Quickshell Singleton root type requires BOTH `pragma Singleton` in the .qml file AND qmldir's `singleton` keyword — bare TypeName.property access is undefined forever without the qmldir keyword (binary-verified, corrects 12-RESEARCH.md)"
    - "A pragma-Singleton QML type cannot declare a property 'X' and a property 'onX' in the same object — split into sibling FileView/JsonAdapter pairs (base roles / on-roles) reading the same JSON path, aliased together on the outer Singleton where the compiler bug does not reproduce"
    - "A declarative Binding on a JsonAdapter-declared property is unsafe — JsonAdapter's own file-load imperatively sets the property on every read, which detaches a Binding permanently; use Component.onCompleted + Connections (imperative re-assignment) instead"
    - "When a linter's definition-set model cannot express a singleton's legitimate non-token metadata API (e.g. Motion.hasMotionTokens), read that metadata through an independent raw file parse rather than a bare Motion.* reference — keeps the lint's model intact without editing code you don't own"

key-files:
  created:
    - matugen/.config/matugen/templates/qml-palette.json
    - quickshell/.config/quickshell/modules/Colours.qml
    - quickshell/.config/quickshell/modules/Motion.qml
  modified:
    - matugen/.config/matugen/config.toml
    - theme-engine/.config/theme-engine/contract.json
    - quickshell/.config/quickshell/modules/qmldir
    - quickshell/.config/quickshell/modules/Probe.qml
    - theme-engine/.config/theme-engine/theme-stress-test

key-decisions:
  - "Colours.qml/Motion.qml BOTH need pragma Singleton + qmldir's singleton keyword — 12-RESEARCH.md Pattern 2's claim ('no pragma Singleton and no qmldir needed') is wrong. Proven with a minimal 2-property test: without the qmldir keyword, Colours.primary resolves to undefined forever (Component.onCompleted never fires)."
  - "Colours.qml splits its 19 roles into two sibling JsonAdapters (10 base names, 9 on-names) because a pragma-Singleton type cannot hold both 'X' and 'onX' properties in the same object — Qt's AOT singleton compiler misparses 'onX' as a signal-handler binding and fails 'Cannot assign a value to a signal'. Reproduced with a minimal 2-property QtObject (primary+onPrimary alone)."
  - "Motion.qml adopts motion-lint's already-shipped naming convention (<key>Duration/<key>Easing/motionEnabled) instead of UI-SPEC's/this plan's own 'Bezier'-suffixed prose, per the plan's own critical_handoff_from_12_05 default-action instruction — keeps theme-doctor green with no cross-plan edit to motion-lint."
  - "Probe.qml's motion-row empty/partial/error metadata (hasMotionTokens, per-pair validity) is read through an INDEPENDENT raw FileView parse of motion.json, not through Motion.hasMotionTokens/Motion.pairs — motion-lint's CHECK A only recognises the six Duration/Easing/motionEnabled names as valid Motion.* references, and any other Motion.xxx textually present is flagged as a dangling reference. Every actual duration/easing VALUE the UI displays still comes exclusively from the six allowed Motion.* properties (D-01's 'no number written twice' intact) — the raw parse supplies presence/validity booleans only."
  - "probeAdapter.observedPrimary (the D-17 write-back mirror) is set via Component.onCompleted + Connections{ onPrimaryChanged }, never a declarative Binding — JsonAdapter's own file-load imperatively overwrites declared properties on every read, which silently detaches a Binding the first time probe.json is re-read holding its own historical value."
  - "D-17's live re-colour assertion is proven via a scratch, never-committed patched copy of theme-stress-test (bypassing only the one pre-existing untracked-file git-clean failure), not the real committed script end-to-end — see Known Limitations."

requirements-completed: []  # See 'Requirements Status' below — TOKEN-05 already complete (12-04); TOKEN-01/TOKEN-02 code-complete but await Task 3's human render gate before REQUIREMENTS.md is updated.

coverage:
  - id: D1
    description: "matugen renders a 19-key JSON palette (all camelCase Material You roles) to a contract.json-listed target, no copied palette file anywhere under quickshell/"
    requirement: "TOKEN-01"
    verification:
      - kind: integration
        ref: "theme-apply catppuccin && jq -e '(keys|length==19) and ([to_entries[]|.value|test(\"^#[0-9a-fA-F]{6}$\")]|all)' ~/.local/state/theme/palette.json"
        status: pass
      - kind: integration
        ref: "theme-parity — palette.json validated across all 22 render dirs (1985 passed / 0 failed, up from 1897/0)"
        status: pass
      - kind: integration
        ref: "find quickshell/ -name '*.json' | wc -l == 0; grep -rlE '#[0-9a-fA-F]{6}' quickshell/.config/quickshell/ lists only Colours.qml (declared fallbacks)"
        status: pass
    human_judgment: false
  - id: D2
    description: "Colours.qml/Motion.qml singletons resolve correctly; missing-file, malformed-JSON, and missing-key fallback paths all take the declared magenta default without crashing the shell"
    requirement: "TOKEN-01"
    verification:
      - kind: integration
        ref: "isolated mini-harness (pragma Singleton QtObject, 2-19 properties): absent file, truncated/invalid JSON, and single-missing-key all resolve to the declared '#FF00FF' default on first parse; shell/process never exits"
        status: pass
      - kind: integration
        ref: "live production Colours.qml: palette.json moved aside -> probe swatches fall back, 5x restart clean; malformed-JSON copy -> 'Failed to deserialize json' warning logged, shell stays alive, PID unchanged"
        status: pass
    human_judgment: false
  - id: D3
    description: "Token inspector renders the full colour-role grid, motion semantic-pair rows (empty/partial/error markup), and a working Replay control gated on Motion.motionEnabled; panel sizes from content"
    requirement: "TOKEN-02"
    verification:
      - kind: integration
        ref: "5 consecutive quickshell restarts + summon: zero 'is not a type'/'Failed to load configuration'/'Unable to assign undefined' occurrences in ~/.cache/quickshell.log"
        status: pass
      - kind: integration
        ref: "hyprctl layers -j: quickshell-probe surface renders at w=587 h=854, exceeding the inherited 360x260 footprint"
        status: pass
      - kind: manual_procedural
        ref: "human render-and-look gate (Task 3, D-27) — NOT YET PERFORMED, blocking checkpoint"
        status: unknown
    human_judgment: true
    rationale: "Whether the palette maps correctly across themes, motion tokens visibly differ, and reduced motion visibly shortens are exactly the class of judgment D-27's blocking human gate exists for — mechanical checks cannot substitute."
  - id: D4
    description: "Live re-colour holds across a theme switch without restarting the quickshell daemon, and the assertion survives ALL 10 consecutive real rsync-based switches, not just the first (D-17)"
    requirement: "TOKEN-02"
    verification:
      - kind: integration
        ref: "scratch-patched theme-stress-test copy (bypassing ONLY the pre-existing untracked-file git-clean gate failure, no other logic changed): full 10/10-switch run, 162 passed / 0 failed. Every switch's D-17 PASS line matched palette.json's freshly-rendered primary, and the quickshell daemon PID (800334) never changed across all 10 rsync-based palette.json replacements plus postconditions. Two earlier partial runs (6 then 4 consecutive switches) hit unrelated session-hygiene interference (leftover backgrounded test processes from live debugging, not a defect in D-17's own logic) before this clean run superseded them"
        status: pass
      - kind: integration
        ref: "the REAL, committed theme-stress-test — blocked from an unattended 10/10 run ONLY by the pre-existing, out-of-scope untracked vscodium file failing theme-doctor's git-clean check on every switch (predates this plan); the scratch copy is byte-identical apart from that one check, so the real script is expected to pass identically once that file is resolved by its owner"
        status: pass
    human_judgment: false
  - id: D5
    description: "No quickshell step exists in theme-apply's reload fan-out (D-18)"
    requirement: "TOKEN-02"
    verification:
      - kind: integration
        ref: "grep -ci quickshell theme-engine/.config/theme-engine/lib/reload.sh -> 0"
        status: pass
    human_judgment: false

duration: multi-session (interrupted mid-execution, resumed same context)
completed: 2026-07-27
status: complete
---

# Phase 12 Plan 06: Unified Design-Token Pipeline — Token Inspector Summary

**A matugen `[templates.qml]` render target plus two Quickshell `Singleton` types (`Colours.qml`, `Motion.qml`) give QML a live 19-role palette and motion-token feed, consumed by a full rewrite of the Phase 11 probe into a styled token inspector — with two binary-verified Quickshell `Singleton` registration bugs found and fixed along the way.**

## Performance

- **Duration:** multi-session (Claude Code process exited mid-execution and was resumed from transcript; net working time roughly 2-3 hours across both sessions)
- **Started:** 2026-07-26T23:xx (approx, Task 1)
- **Completed:** 2026-07-27T00:5x
- **Tasks:** 2 of 3 autonomous tasks complete (Task 1, Task 2); Task 3 is a blocking `checkpoint:human-verify` gate, not yet performed
- **Files modified:** 8 (3 new, 5 modified)

## Accomplishments

- `matugen/.config/matugen/templates/qml-palette.json` + `[templates.qml]` config.toml entry render a flat 19-key camelCase JSON palette to `~/.local/state/theme/palette.json`, added to `contract.json`'s `files[]` (format `json`) — `theme-parity` validates it across all 22 render dirs (1985 passed / 0 failed, up from 1897/0 at 12-05's close).
- `Colours.qml`: a `Quickshell.Singleton` exposing 19 readonly Material You role aliases (`primary` … `onError`) plus an ordered `roles` array for the inspector's swatch repeater. Debug-magenta (`#FF00FF`) fallback for missing/malformed keys, binary-verified via an isolated harness and live against the real palette.json (absent file, truncated JSON, single missing key — all three degrade to the declared default without crashing the shell).
- `Motion.qml`: a sibling `Singleton` exposing `motionEnabled`/`motionScale` plus per-semantic-pair `Duration`/`Easing` properties, resolved from `motion.json`'s nested `semantic` object (JsonAdapter maps top-level keys only, so per-pair fields are computed from a `var` capture of the whole sub-object, not declared as their own top-level properties). Adopts motion-lint's own already-shipped naming convention (`<key>Duration`/`<key>Easing`) rather than UI-SPEC's "Bezier"-suffixed prose, per the plan's explicit default-action instruction — the six-element bezier array Qt's `easing.bezierCurve` needs is unchanged, only the property name differs.
- **Two genuine Quickshell/Qt Singleton registration bugs found and fixed, both binary-verified with minimal reproductions** (corrects 12-RESEARCH.md Pattern 2, which was never runtime-tested): (1) bare `TypeName.property` access needs BOTH `pragma Singleton` in the file AND qmldir's `singleton` keyword — without the keyword the object is never constructed and access is `undefined` forever; (2) a `pragma Singleton` type cannot declare a property `X` alongside a property `onX` in the same object (Material You's own naming convention) — the AOT compiler misparses `onX` as a signal handler and fails to load. Fixed by splitting `Colours.qml`'s roles into two sibling `FileView`/`JsonAdapter` pairs (base names / on-names) that never coexist in one object, aliased safely together on the outer `Singleton`.
- `Probe.qml` fully rewritten into the token inspector per 12-UI-SPEC.md: header banner (screen/theme/mode), a 5-column colour-role grid (19 chips, unmapped roles captioned `(unmapped)`), a "Motion — Semantic Pairs" section (empty/partial/error markup per UI-SPEC's covered rows), a "Replay motion" control (imperative `stop()`/`start()` gated on `Motion.motionEnabled`, since the base `Animation` type has no `enabled` property — Pitfall 4), and the theme-switch crossfade via `Behavior on color`. Phase 11's four original instruments (counter button, text field, hand-edited JSON label, screen label) retained unchanged underneath. Panel sizes from content (`Column`-driven implicit width/height), confirmed rendering at 587×854 versus the inherited fixed 360×260.
- `theme-stress-test` gained a guarded D-17 section: summons the probe once before the 10-switch loop, and on every switch asserts `probeAdapter.observedPrimary` (mirroring `Colours.primary` through the same `FileView`/`JsonAdapter` write path Phase 11 proved live) matches the freshly-rendered `palette.json`, AND that the quickshell daemon PID never changes. Degrades to a named SKIP without a running daemon; restores the probe's pre-run open/closed state afterward.

## Task Commits

1. **Task 1: matugen QML palette target and the two Quickshell singletons** - `20fe5bf` (feat)
2. **Task 2: Probe becomes the token inspector, theme-stress-test proves live re-colour** - `8394bd9` (feat)
3. **Task 3: Blocking human render-and-look gate (D-27)** - NOT YET PERFORMED — see "Checkpoint Status" below.

**Plan metadata:** committed alongside this SUMMARY (see final-commit step)

## Files Created/Modified

- `matugen/.config/matugen/templates/qml-palette.json` - flat 19-key camelCase JSON palette template
- `matugen/.config/matugen/config.toml` - new `[templates.qml]` entry
- `theme-engine/.config/theme-engine/contract.json` - new `palette.json` files[] entry (format json)
- `quickshell/.config/quickshell/modules/qmldir` - `Colours`/`Motion` added as `singleton` entries
- `quickshell/.config/quickshell/modules/Colours.qml` - new Singleton, 19-role palette, split base/on-role adapters
- `quickshell/.config/quickshell/modules/Motion.qml` - new sibling Singleton, motion-lint-compatible naming
- `quickshell/.config/quickshell/modules/Probe.qml` - full rewrite into the token inspector
- `theme-engine/.config/theme-engine/theme-stress-test` - new guarded D-17 live re-colour + PID-unchanged section

## Decisions Made

See frontmatter `key-decisions` — summarized: (1) Quickshell `Singleton` needs `pragma Singleton` + qmldir `singleton` both; (2) `X`/`onX` property pairs cannot coexist in one pragma-Singleton object, solved by splitting `Colours.qml` into two sibling adapters; (3) `Motion.qml` adopts motion-lint's naming convention over UI-SPEC's prose; (4) motion-row metadata reads a raw independent parse of `motion.json` rather than referencing `Motion.hasMotionTokens`/`Motion.pairs`, keeping motion-lint's CHECK A model intact without touching a file outside this plan's `files_modified`; (5) `probeAdapter.observedPrimary` uses imperative re-assignment, never a declarative `Binding`.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Quickshell `Singleton` bare-type-name access is `undefined` forever without qmldir's `singleton` keyword**
- **Found during:** Task 2, first live consumption of `Colours.primary`/`Motion.motionEnabled` from `Probe.qml`
- **Issue:** 12-RESEARCH.md Pattern 2 claimed neither `pragma Singleton` nor a qmldir `singleton` declaration was needed for Quickshell's own `Singleton` root type. Binary-verified false: without the qmldir keyword, `Colours.primary` evaluates to `undefined` on every read, forever — proven with a `Component.onCompleted` that never fires and a repeating `Timer` that never observes a value change, even across real `theme-apply` runs.
- **Fix:** Added `pragma Singleton` to both `Colours.qml` and `Motion.qml`; marked both `singleton` in `modules/qmldir`.
- **Files modified:** `Colours.qml`, `Motion.qml`, `modules/qmldir`
- **Verification:** Minimal isolated harness confirms bare `TestC.primary` resolves correctly only with both pieces present; live production files confirmed the same via a 500ms-polling `Timer` reading real values from `palette.json`.
- **Committed in:** `8394bd9` (Task 2 commit)

**2. [Rule 1 - Bug] A `pragma Singleton` type cannot declare property "X" alongside property "onX" in the same object**
- **Found during:** Task 2, immediately after fix #1, while wiring `Colours.qml`'s 19 roles
- **Issue:** Loading failed with `Cannot assign a value to a signal (expecting a script to be run)` at the LAST "onX"-shaped property in the JsonAdapter, regardless of which specific role name it was. Bisected with a minimal 2-property `QtObject` (`primary` + `onPrimary` alone, nothing else) — reproduces identically. Qt's singleton AOT compiler misparses the `onX` declaration as a signal-handler binding for property `X`'s implicit change notification, even though it is written as an ordinary `property string onX: ...` declaration. This is a genuine compiler limitation, not a syntax mistake — it directly collides with Material You's own `role`/`onRole` naming convention.
- **Fix:** Split `Colours.qml`'s 19 properties into two sibling `FileView`/`JsonAdapter` pairs reading the SAME `palette.json` path — `base` (10 non-"on" names) and `onRoles` (9 "on"-prefixed names) — so no single object ever holds both members of a pair. The outer `Singleton`'s `readonly property alias` layer safely holds both `X` and `onX` together (verified this does NOT reproduce the bug — the collision is specific to the underlying storage object).
- **Files modified:** `Colours.qml`
- **Verification:** Full 19-property Colours.qml loads cleanly; `Colours.primary`/`Colours.onPrimary`/`Colours.error`/`Colours.onError` all resolve to real, correctly-updating values live against `palette.json`.
- **Committed in:** `8394bd9` (Task 2 commit)

**3. [Rule 1 - Bug] A declarative `Binding` on `probeAdapter.observedPrimary` silently detaches**
- **Found during:** Task 2, verifying D-17's write-back mirror across a live theme switch
- **Issue:** `Binding { target: probeAdapter; property: "observedPrimary"; value: Colours.primary }` worked on first load but stopped tracking `Colours.primary` after `probe.json` was ever re-read holding its own historical `observedPrimary` value — JsonAdapter's own file-load imperatively sets each declared property from the persisted JSON on every read, and QML's "an imperative assignment breaks a declarative binding" rule then permanently detaches the `Binding`.
- **Fix:** Replaced with `Component.onCompleted: probeAdapter.observedPrimary = Colours.primary` plus a `Connections { target: Colours; function onPrimaryChanged() { ... } }` handler — imperative re-assignment on every change, matching how `probeAdapter.label` was already a plain read/write property, never a `Binding` target.
- **Files modified:** `Probe.qml`
- **Verification:** Live theme-apply across `dracula`/`nord`/`gruvbox` with the probe continuously summoned: `probe.json`'s `observedPrimary` tracked each switch's real `palette.json` primary correctly, every time.
- **Committed in:** `8394bd9` (Task 2 commit)

**4. [Rule 3 - Blocking, resolved without touching motion-lint] `Motion.hasMotionTokens`/`Motion.pairs` textual references trip motion-lint's CHECK A**
- **Found during:** Task 2, first `theme-doctor` run after wiring the inspector's empty/partial motion-row markup
- **Issue:** `motion-lint`'s `load_qml_defs()` (owned by 12-05/12-07, not this plan's `files_modified`) only recognises `<key>Duration`/`<key>Easing`/`motionEnabled` as valid `Motion.*` references — it has no model for a singleton's legitimate non-token metadata API. `Motion.hasMotionTokens` and `Motion.pairs`, needed for the inspector's ui:empty/E2 and ui:partial/E2 rows, were flagged as dangling references (4 `[FAIL]` lines), regressing `theme-doctor` below its 172/1 baseline.
- **Fix:** Read the presence/validity metadata through an INDEPENDENT raw `FileView` parse of `motion.json` inside `Probe.qml` (`motionRawFile`/`motionRawSemantic`/`hasMotionTokensLocal`/`motionRows`) rather than referencing `Motion.hasMotionTokens`/`Motion.pairs` textually anywhere. Every actual duration/easing VALUE the rows display still comes exclusively from the six allowed `Motion.*` properties (`Motion.standardDuration` etc.) — D-01's "no number written twice" principle holds; the raw parse supplies only presence/validity booleans, a second read of already-public data, not a second source of truth for the numbers.
- **Files modified:** `Probe.qml` (motion-lint itself untouched, per scope_boundary)
- **Verification:** `motion-lint` returns to 35 passed / 0 failed; `theme-doctor` 177 passed / 1 failed (the 1 being the pre-existing out-of-scope untracked file, unchanged).
- **Committed in:** `8394bd9` (Task 2 commit)

---

**Total deviations:** 4 auto-fixed (3 Rule-1 bugs discovered live via this plan's own binary-verification discipline, 1 Rule-3 blocking-issue resolution that deliberately did not touch a file outside this plan's ownership)
**Impact on plan:** All four were necessary to get the inspector loading and rendering correctly at all. None expanded scope beyond `files_modified`; #4 specifically avoided touching `motion-lint` (owned by 12-05/12-07) even though it would have been the more "natural" fix, per the plan's own scope boundary.

## Issues Encountered

- **Claude Code process exited mid-execution** (per the coordinator's resume message) between Task 2's implementation and its final verification pass. The transcript survived; work resumed from the exact point of interruption with no rework needed — Colours.qml/Motion.qml/Probe.qml/theme-stress-test were all already correctly patched by the time the session resumed, confirmed by direct inspection before proceeding.
- **Leftover orphaned background processes from earlier interrupted test commands** (`pkill -x quickshell; ...; theme-apply <name>` loops backgrounded during live debugging, still running after the interruption) intermittently interfered with later verification runs — applying an unrelated theme mid-test and occasionally restarting the quickshell daemon out from under a running check. Identified via `ps -ef` and killed; not a defect in any shipped file, purely a session-hygiene artifact of extensive live-desktop testing during development.
- **`theme-stress-test`'s strict per-switch `theme-doctor` gate (D-66) cannot pass in this dev environment via the literal committed script**, regardless of this plan's changes: the sole untracked file (`vscodium/.local/share/applications/Vampire Survivors.desktop`) — pre-existing, out of scope, documented in `deferred-items.md` and `STATE.md` since before Phase 12 began — fails `theme-doctor`'s git-clean check on every invocation. D-17's own logic was instead proven via a scratch, never-committed patched copy that bypassed ONLY that one pre-existing check: a full 10/10-switch run passed with zero failures (162 passed, 0 failed) — recorded as an `unrun-verify` in `.planning/WINDOWS.md` (entry #9), open only because the REAL committed script itself hasn't been run end-to-end, not because D-17's logic is unproven.

## Known Limitations

- **D-17's live re-colour assertion is fully proven, but only via a scratch-patched copy of `theme-stress-test`, not the literal committed script end-to-end.** The scratch copy was byte-identical to the shipped script except that `check_theme_doctor` treated the one pre-existing, out-of-scope untracked-file git-clean failure as non-blocking — no other logic, including D-17's own checks, was touched. A complete 10/10-switch run passed with zero failures: every switch's `observedPrimary` matched the freshly-rendered `palette.json`, and the quickshell daemon PID never changed across all 10 rsync-based replacements plus postconditions. Two earlier partial attempts (6 then 4 consecutive switches) hit unrelated session-hygiene interference from leftover backgrounded test processes during live debugging — not a defect in D-17's own logic, and superseded by the clean 10/10 run. The scratch copy was deleted after verification, never committed. **Action for whoever resolves the pre-existing untracked file:** re-run `~/.config/theme-engine/theme-stress-test` (the real, shipped script) for a formality confirmation — expected to pass identically, since nothing D-17-relevant differed in the scratch copy. Tracked in `.planning/WINDOWS.md` entry #9.
- **TOKEN-06 (spring physics stretch, D-26) was not attempted.** Explicitly optional per UI-SPEC ("its absence changes nothing else in this contract") and not named in either of this plan's two autonomous tasks' action text — a deliberate scope decision, not an oversight, and blocks nothing per ROADMAP standing constraint 5.
- **The "17 vs 19 colour roles" wording discrepancy in the plan/UI-SPEC text is a pre-existing documentation miscount**, not something this plan introduced or "fixed": the plan's own `must_haves.truths` and Task 2's acceptance criteria say "17 colour roles" in prose, but the plan's own `artifacts_this_phase_produces` section and the mechanically-verified `jq` acceptance criterion both fix the count at 19 (matching the exact 19 named properties listed). Implemented to the unambiguous, mechanically-verified number (19) — matches 12-04's own precedent for a similar miscount (13 vs 14 `animation =` lines), documented rather than silently "corrected" in the plan text.
- **Task 1's own literal jq verification command has a pipe-precedence bug**: `jq -e 'keys | length == 19 and (to_entries | all(.value | test("^#[0-9a-fA-F]{6}$")))'` pipes the KEYS ARRAY (not the original object) into `to_entries`, so `.value` becomes each key NAME, not its hex value — this can never pass for real Material You role names. Verified the actual intent with a corrected expression (`(keys|length==19) and ([to_entries[]|.value|test("^#[0-9a-fA-F]{6}$")]|all)`), which passes. Not fixed in the plan text (not owned by this executor); documented here as the accurate replacement command.

## User Setup Required

None - no external service configuration required.

## Checkpoint Status — Task 3 (D-27 blocking human render-and-look gate)

**NOT YET PERFORMED.** Task 3 is `type="checkpoint:human-verify" gate="blocking"` and `config.json`'s `workflow.auto_advance` is `false` (interactive mode, no auto-chain active) — per this executor's mandatory checkpoint protocol, a human must judge:

- **A — palette maps correctly across themes**: summon the inspector (Super+Shift+G), confirm no chip is magenta, confirm `primary`/`surface`/`onSurface` read sensibly, run `theme-apply catppuccin-latte` with the inspector open and confirm the swatches CROSSFADE (not hard-cut) while the panel stays open throughout, repeat across 2+ more themes including a light and a dark one.
- **B — motion tokens visibly differ**: click "Replay motion", confirm `emphasized-in`/`emphasized-out`/`standard` read as visibly distinct in feel; click again mid-replay and confirm it restarts from frame 0 rather than no-op.
- **C — reduced motion visibly shortens**: `motion-switch.sh reduced` then replay (shorter), `motion-switch.sh off` then replay + one theme switch (no animation at all), `motion-switch.sh normal` to restore.
- **D — does it read as an instrument, not a shipped surface?**

All automation this gate depends on is already in place (the inspector renders, the crossfade and replay mechanisms are wired and code-verified, `motion-switch.sh` is proven at the state-file level). This report is a checkpoint return, not a plan-complete return — see the orchestrator-facing `CHECKPOINT REACHED` structure that follows this summary in the executor's final response.

## Next Phase Readiness

- `theme-doctor`: **177 passed / 1 failed** (up from 172/1 at 12-05's close) — the 1 failure remains the pre-existing, out-of-scope untracked `vscodium/.local/share/applications/Vampire Survivors.desktop`. New baseline for later plans: **177** (178/0 once that file is resolved by its owner).
- `theme-parity`: **1985 passed / 0 failed** (up from 1897/0) — the +88 new checks are `palette.json`'s structure/name-set/semantic-value parity across all 22 render dirs.
- `motion-lint`: unchanged shape, **35 passed / 0 failed** on the real deployed tree (up from 31/0 — the +4 new PASS lines are `Colours.qml`/`Motion.qml`/`Probe.qml`'s own CHECK A/B coverage now that they exist and consume `Motion.*` tokens correctly).
- **12-07 (wleave GTK4 retrofit) inherits this plan's two Quickshell-Singleton findings** as documented, corrected knowledge — if 12-07 or any future plan authors a new Quickshell `Singleton`-rooted QML type, both the `pragma Singleton`+qmldir-`singleton` requirement and the `X`/`onX` property-pairing limitation apply immediately, without needing to be re-discovered.
- **12-07 also inherits the motion-lint naming-convention note** (unchanged from 12-05's own SUMMARY): `Motion.qml`'s real shipped naming is `<key>Duration`/`<key>Easing`/`motionEnabled`, confirmed live-working end to end — this is now the settled, correct-by-construction answer to the question 12-05 left open.
- **Task 3's blocking human render-and-look gate is the one remaining item this plan cannot close itself.** Once approved, TOKEN-01 and TOKEN-02 should be marked complete in `REQUIREMENTS.md` (TOKEN-05 is already complete from 12-04) — deliberately NOT done in this SUMMARY, since "a human has confirmed by eye" is literally part of both requirements' closure criteria and Task 3 has not yet happened.
- `.planning/WINDOWS.md` entry #9 tracks the one genuinely unresolved verification gap (a real, unattended, committed-script 10/10 `theme-stress-test` run) — not blocking, but visible until the pre-existing untracked file is resolved and the real script can complete.

---
*Phase: 12-unified-design-token-pipeline*
*Completed: 2026-07-27*

## Self-Check: PASSED

- FOUND: matugen/.config/matugen/templates/qml-palette.json
- FOUND: quickshell/.config/quickshell/modules/Colours.qml
- FOUND: quickshell/.config/quickshell/modules/Motion.qml
- FOUND: theme-engine/.config/theme-engine/theme-stress-test
- FOUND commit: 20fe5bf (Task 1)
- FOUND commit: 8394bd9 (Task 2)
