---
phase: 18-qml-bar-retirement-machinery
plan: 03
subsystem: testing
tags: [lint, qml, quickshell, bash, python3, theme-doctor, colour-tokens]

# Dependency graph
requires:
  - phase: 12-unified-design-token-pipeline
    provides: motion-lint's CHECK A/B/C + EXEMPTIONS/LINE_EXEMPTIONS + --self-test/--no-pending shape, mirrored structurally
  - phase: 14-dashboard-drawer
    provides: Colours.qml singleton (19 role names via readonly property alias), WeatherPalette.qml's own documented exemption header
  - phase: 16-workspace-overview
    provides: DragGhost.qml/WindowThumbnail.qml shadowColor: Qt.rgba() elevation-shadow sites
provides:
  - colour-lint — deny-by-default QML colour gate, folded blocking into theme-doctor
  - Six committed fixtures under tests/colour-fixtures/ proving the gate can fail
  - Forward-coverage proof: any QML file 18-05..18-16 creates is covered with zero lint edits
affects: [18-19-gate-02-close, 18-20-retire-02-waybar-design-lint-deletion, 18-05, 18-08, 18-09, 18-10, 18-11, 18-13, 18-14]

# Actuals (#2632)
actuals:
  tokens: 10109
  tasks: 3
  commits: 2

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "colour-lint mirrors motion-lint's CHECK A/B/C + EXEMPTIONS/LINE_EXEMPTIONS + --self-test/--no-pending shape exactly, extended to a fourth check-B sub-shape vocabulary (B1-B4) rather than a single raw-value check"
    - "Colour-assignment anchoring (not hex-shaped-text scanning) as the deny-by-default hazard-avoidance pattern for any future colour/token lint"
    - "Content-anchored LINE_EXEMPTIONS (never hardcoded line numbers) for single-rule carve-outs inside an otherwise fully compliant file"

key-files:
  created:
    - hypr/.config/hypr/scripts/colour-lint
    - hypr/.config/hypr/scripts/tests/colour-fixtures/compliant-qml.qml
    - hypr/.config/hypr/scripts/tests/colour-fixtures/poisoned-hex-assign-qml.qml
    - hypr/.config/hypr/scripts/tests/colour-fixtures/poisoned-hex-property-qml.qml
    - hypr/.config/hypr/scripts/tests/colour-fixtures/poisoned-rgba-literal-qml.qml
    - hypr/.config/hypr/scripts/tests/colour-fixtures/poisoned-named-colour-qml.qml
    - hypr/.config/hypr/scripts/tests/colour-fixtures/poisoned-dangling-qml.qml
  modified:
    - theme-engine/.config/theme-engine/theme-doctor

key-decisions:
  - "CHECK A's definition source is parsed live from Colours.qml (readonly property alias lines + top-level property declarations at brace-depth 1), never hardcoded and never read from palette.json, so Probe.qml's legitimate Colours.roles reference is never flagged dangling"
  - "CHECK B anchors on colour-ASSIGNMENT context (four shapes B1-B4), never on hex-shaped text, so Colours.qml's 19 property-string JsonAdapter fallback defaults are excluded STRUCTURALLY (the type keyword differs) rather than by exemption"
  - "Three day-one exemptions declared with non-empty, printed-every-run reasons: WeatherPalette.qml (whole-file, EXEMPTIONS), DragGhost.qml and WindowThumbnail.qml shadowColor: lines (content-anchored, LINE_EXEMPTIONS)"
  - "Task 1 shipped --self-test/--no-pending as recognized-but-stubbed CLI flags; Task 2 filled in the real implementations — kept the two commits atomically scoped to what each task's own acceptance criteria required"

patterns-established:
  - "Pattern: colour-assignment anchoring for QML colour lints — anchor on B1 color:-family assignment, B2 property color declaration, B3 fully-literal Qt.rgba/hsla/hsva triple, B4 non-hex/non-transparent quoted literal — never a blanket hex-shaped-string scan"
  - "Pattern: definition-source name sets are always parsed live from the real singleton/token file, never hardcoded and never read from a downstream render artifact that cannot back every live reference"

requirements-completed: [GATE-04]

coverage:
  - id: D1
    description: "colour-lint exists, is executable, scans the live QML tree, and exits 0 with zero [FAIL] lines"
    requirement: "GATE-04"
    verification:
      - kind: other
        ref: "hypr/.config/hypr/scripts/colour-lint (bare invocation against $HOME/.config/quickshell) — 62 passed, 0 failed, 32 surfaces scanned"
        status: pass
    human_judgment: false
  - id: D2
    description: "Colours.qml's 19 property-string JsonAdapter fallback defaults are excluded structurally (not flagged) while a real property-color hex declaration in the same file IS flagged"
    requirement: "GATE-04"
    verification:
      - kind: other
        ref: "colour-lint <isolated-tmp-dir-containing-poisoned-hex-property-qml.qml> — FAILs on the property-color line, output never mentions \"property string\""
        status: pass
    human_judgment: false
  - id: D3
    description: "Gate has provable teeth: --self-test replays six committed fixtures, one per distinguishable failure path plus the compliant control"
    requirement: "GATE-04"
    verification:
      - kind: other
        ref: "colour-lint --self-test — 6 passed, 0 failed; missing-fixture spot-check proven to fail"
        status: pass
    human_judgment: false
  - id: D4
    description: "Three declared exemptions print an [EXEMPT] line every run, are never folded into theme-doctor as a PASS, and --no-pending confirms none is marked temporary"
    requirement: "GATE-04"
    verification:
      - kind: other
        ref: "colour-lint --no-pending — exit 0, 1 passed 0 failed; theme-doctor output contains [EXEMPT] lines not prefixed colour-lint:"
        status: pass
    human_judgment: false
  - id: D5
    description: "colour-lint folded blocking into theme-doctor's tally per D-18-35; fold lines carry zero [FAIL]"
    requirement: "GATE-04"
    verification:
      - kind: other
        ref: "theme-engine/.config/theme-engine/theme-doctor run — colour-lint: prefixed lines present, 0 [FAIL]"
        status: pass
    human_judgment: false
  - id: D6
    description: "Deny-by-default forward coverage: a QML file 18-05..18-16 has not written yet is already covered with zero lint edits, proven against a nested not-yet-existing directory"
    requirement: "GATE-04"
    verification:
      - kind: other
        ref: "colour-lint <throwaway-root>/modules/bar/ForwardProbe.qml — nonzero exit, [FAIL] cites ForwardProbe.qml, \"scanned 1 surface(s)\"; quickshell/.config/quickshell/modules/bar confirmed absent afterward"
        status: pass
    human_judgment: false

# Metrics
duration: ~25min
completed: 2026-08-11
status: complete
---

# Phase 18 Plan 03: GATE-04 colour-lint Summary

**Minted GATE-04: `colour-lint`, a deny-by-default QML colour gate anchored on colour-assignment context (never hex-shaped text), folded blocking into `theme-doctor`, shipping green on day one against the live 32-surface quickshell tree with three reasoned exemptions.**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-08-11T02:37:00Z (approx, per STATE.md session start)
- **Completed:** 2026-08-11T02:49:00Z (approx)
- **Tasks:** 3 completed (2 produced commits; Task 3 was proof-only, no script edit required)
- **Files modified:** 8 (1 new script, 6 new fixtures, 1 modified — theme-doctor)

## Accomplishments

- `hypr/.config/hypr/scripts/colour-lint` created and executable: CHECK A (`Colours.<role>` reference resolution, parsed live from `Colours.qml`), CHECK B (four anchored colour-hardcoding shapes B1-B4), CHECK C (scanned-surface count floor)
- Anchored the match on colour-ASSIGNMENT context, not hex-shaped text — `Colours.qml`'s 19 `property string` JsonAdapter fallback defaults are excluded **structurally** (the type keyword differs from `property color`), never by exemption
- Three day-one exemptions declared with non-empty, printed-every-run reasons: `WeatherPalette.qml` (whole-file), `DragGhost.qml` and `WindowThumbnail.qml` `shadowColor:` lines (content-anchored)
- Six committed fixtures (`tests/colour-fixtures/`) + `--self-test` (6/6 pass, missing-fixture detection proven) + `--no-pending` (opt-in structured-field assertion, exits 0)
- Folded blocking into `theme-doctor` per D-18-35, placed after the `hypr-equivalence-check` fold, deliberately unguarded by any live-session check so it still runs headless in a fresh-install container; `[EXEMPT]` lines pass through unfolded rather than counting as a PASS
- Forward-coverage proven (not asserted): a poisoned QML file two directory levels deep in a throwaway root — mimicking `18-05`'s not-yet-created `modules/bar/` — fails the gate and is cited by path, with zero edits to the lint

## Task Commits

Each task was committed atomically:

1. **Task 1: colour-lint end-to-end — Colours.qml definitions through to a theme-doctor tally line** - `c5d47c4` (feat)
2. **Task 2: Give the gate provable teeth — six fixtures, --self-test, --no-pending** - `7b0dee2` (test)
3. **Task 3: Prove the wave-1 mandate — deny-by-default forward coverage** - no commit (proof-only; the forward-coverage property was already stated in Task 1's header, and the throwaway-root demonstration left no tracked-file changes — see Deviations)

**Plan metadata:** (this commit, following SUMMARY/STATE/ROADMAP)

## Files Created/Modified

- `hypr/.config/hypr/scripts/colour-lint` - the gate itself: CHECK A/B/C, EXEMPTIONS/LINE_EXEMPTIONS, `--self-test`, `--no-pending`, `COLOUR_LINT_COLOURS_QML` override
- `hypr/.config/hypr/scripts/tests/colour-fixtures/compliant-qml.qml` - control fixture (expect exit 0)
- `hypr/.config/hypr/scripts/tests/colour-fixtures/poisoned-hex-assign-qml.qml` - B1 fixture
- `hypr/.config/hypr/scripts/tests/colour-fixtures/poisoned-hex-property-qml.qml` - B2 fixture, carries a co-located `property string` sibling that must NOT be flagged
- `hypr/.config/hypr/scripts/tests/colour-fixtures/poisoned-rgba-literal-qml.qml` - B3 fixture, carries a compliant token-plus-alpha call that must NOT be flagged
- `hypr/.config/hypr/scripts/tests/colour-fixtures/poisoned-named-colour-qml.qml` - B4 fixture
- `hypr/.config/hypr/scripts/tests/colour-fixtures/poisoned-dangling-qml.qml` - CHECK A fixture
- `theme-engine/.config/theme-engine/theme-doctor` - `colour-lint` fold block, placed after `hypr-equivalence-check`, before the CLEAN-02 git check

## Decisions Made

- Split colour-lint's construction across Task 1 (core CHECK A/B/C + fold, with `--self-test`/`--no-pending` recognized in dispatch but stubbed) and Task 2 (real implementations + fixtures), matching each task's own acceptance criteria exactly rather than writing the whole file in Task 1's commit.
- `PROP_NAME_RE`'s last-segment pattern (`color` bare, or any identifier ending in `Color`) combined with the `\s*:\s*"` immediate-colon anchor is sufficient to prevent `backgroundColorish:` from half-matching — verified live rather than assumed, since a naive regex construction could plausibly have required an extra explicit boundary check.
- Brace-depth tracking (string-literal-aware) used to distinguish "top-level" properties in `Colours.qml` from nested `JsonAdapter` properties, as a second independent guard alongside the type-keyword distinction (`property string` vs `property color`) that already does the structural work.

## Deviations from Plan

**1. [Task 3] No commit produced for Task 3 — proof-only, no tracked-file change**

- **Found during:** Task 3 (forward-coverage proof)
- **Issue:** Task 3's action explicitly scopes it as a proof task ("Add nothing to the script in this task beyond, at most, a header sentence recording the forward-coverage property if it is not already stated"). Task 1's header already stated the forward-coverage property verbatim ("every `.qml` file under the quickshell config tree is scanned; there is no per-file opt-in registry, so a QML file that does not exist yet ... is covered the moment its file exists, with zero edits to this script"), so no header edit was needed. The throwaway-root demonstration ran entirely inside a `mktemp -d` and was removed at the end, per the task's own instruction — leaving zero tracked-file changes to commit.
- **Resolution:** No commit for Task 3 itself; its result (the day-one ledger below) is recorded in this SUMMARY as instructed by the plan's `<output>` section. `git status --porcelain` confirmed clean immediately after the throwaway-root run and before this SUMMARY was written.
- **Impact on plan:** None — all of Task 3's acceptance criteria and its automated `<verify>` script passed exactly as written; the deviation is procedural (no commit exists to cite) rather than substantive.

---

**Total deviations:** 1, procedural only (no code change, no auto-fix). No Rule 1/2/3 issues found during execution.
**Impact on plan:** None — plan executed exactly as written, including the deliberate no-op outcome Task 3's own action text anticipates.

## Issues Encountered

None.

## Day-One Ledger (for 18-19's GATE-02 pass and 18-20's RETIRE-02 deletion to cite)

Commands re-run at execution time, not trusted from the plan document (all confirmed live, 2026-08-11):

- **Scanned-surface count at ship time:** `32` (`.qml` files under `$HOME/.config/quickshell`, `colour-lint`'s CHECK C line: `colour-lint scanned 32 surface(s) under /home/aorus/.config/quickshell`). One more than the plan's own interface-context baseline of 31 because 18-01 (same wave) had already added `Bar.qml` by execution time — CHECK C is a floor (`>= 31`), not an equality assertion, exactly to absorb this.
- **Blanket-vs-anchored hit comparison:** `grep -rnoE '"#[0-9a-fA-F]{3,8}"' quickshell/.config/quickshell/modules --include='*.qml' | wc -l` → **28** (blanket quoted-hex-shaped-string scan). Anchored scan (B1 `color:`-family assignment + B2 `property color` declaration + B4 non-hex/non-transparent literal) → **8**, all 8 in `WeatherPalette.qml` (B2 shape; B1 and B4 both `0`). `Colours.qml` contributes `19` to the blanket count and `0` to the anchored count — confirmed via `grep -c '"#FF00FF"' quickshell/.config/quickshell/modules/Colours.qml` → `19`, re-run at execution time, unchanged from the plan's baseline.
- **Confirmation Colours.qml needs no exemption of any kind:** the 19 `property string <name>: "#FF00FF"` JsonAdapter fallback defaults are excluded from CHECK B's surface set structurally (the definition-source path is excluded from CHECK B entirely) AND would not match B1/B2's colour-typed anchors even if scanned (their type keyword is `string`, not `color`) — a double, not single, structural exclusion. `colour-lint`'s live run confirms a `[PASS]` line naming `Colours.qml` for CHECK A and zero `[FAIL]` lines naming it.
- **B3 shape (separate from the hex-string blanket/anchored comparison above, since `Qt.rgba(...)` calls carry no hex-shaped string at all):** `2` fully-literal triples live — `overview/DragGhost.qml:96` (`Qt.rgba(0, 0, 0, 0.35)`) and `overview/WindowThumbnail.qml:158` (`Qt.rgba(0, 0, 0, 0.5)`) — both confirmed via direct grep and both covered by `LINE_EXEMPTIONS` (content-anchored, resolved to lines 96 and 158 respectively at run time).
- **The three exemptions, verbatim reasons:**
  1. `WeatherPalette.qml` (whole-file, `EXEMPTIONS`) — deliberate, human-render-gate-approved exemption (Phase 14 Plan 09 Task 4) to the repo-wide zero-hex invariant: weather-condition glyphs must read apart from each other at icon size, and no `Colours.*` role is guaranteed to stay a fixed hue across a theme switch.
  2. `overview/DragGhost.qml` `shadowColor:` (line 96, `LINE_EXEMPTIONS`) — MD3 elevation shadow, black by specification per `16-UI-SPEC.md` "Drag visuals" (~0.35 opacity black, ~8px blur radius) — not a theme colour.
  3. `overview/WindowThumbnail.qml` `shadowColor:` (line 158, `LINE_EXEMPTIONS`) — MD3 elevation shadow, black by specification; heavier 0.5 alpha than DragGhost's 0.35 because these thumbnails sit on a blurred backdrop rather than sharp desktop — not a theme colour.
- **`theme-doctor` fold confirmed wired:** `colour-lint:`-prefixed lines present in `theme-doctor`'s output, zero of them `[FAIL]`; the three `[EXEMPT]` lines appear unprefixed (passed through the fold's catch-all branch), proving an exemption is never counted as a passing check.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- GATE-04 is live and blocking in `theme-doctor` before any bar capsule plan (18-05 onward) creates a single `.qml` file — every future QML surface is judged by construction, never audited retroactively.
- `18-20`'s `RETIRE-02` can delete `waybar-design-lint`'s CHECK D ("no literal hex") knowing its coverage has a live QML successor already folded into the same tally, citing the day-one ledger above.
- No blockers. `quickshell/.config/quickshell/modules/bar` remains absent, so `18-01`'s own wave-1 acceptance criterion (same wave, no dependency) is undisturbed by this plan's forward-coverage proof.

---
*Phase: 18-qml-bar-retirement-machinery*
*Completed: 2026-08-11*

## Self-Check: PASSED

- FOUND: hypr/.config/hypr/scripts/colour-lint
- FOUND: .planning/phases/18-qml-bar-retirement-machinery/18-03-SUMMARY.md
- FOUND: commit c5d47c4
- FOUND: commit 7b0dee2
