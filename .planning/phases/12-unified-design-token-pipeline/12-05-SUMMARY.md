---
phase: 12-unified-design-token-pipeline
plan: 05
subsystem: theming
tags: [bash, python, css, hyprland, qml, lint, motion, theme-doctor]

# Dependency graph
requires:
  - phase: 12-03
    provides: "motion.json, lib/motion.sh, the three rendered motion targets under ~/.local/state/theme/ that this lint reads its definition sets from"
  - phase: 12-04
    provides: "motion-scale CLI, Hyprland D-22 wiring, theme-doctor's hyprctl readback and theme-parity's D-31 byte-identity gate — the baseline (theme-doctor 141/1, theme-parity 1897/0) this plan builds on"
provides:
  - "hypr/.config/hypr/scripts/motion-lint: deny-by-default motion-token gate (CHECK A reference resolution, CHECK B no-raw-values, CHECK C scanned-count floor), a 7-entry exemption list, and a --self-test mode"
  - "Nine committed compliant/poisoned fixture pairs under hypr/.config/hypr/scripts/tests/motion-fixtures/ proving the lint fails before it is trusted to pass, for all three targets"
  - "theme-doctor motion-lint fold: TOKEN-04's requirement (theme-doctor itself fails on a hand-rolled value) demonstrated end-to-end, with [EXEMPT] lines passed through but excluded from the pass tally"
affects: [12-06, 12-07, 12-08, 13-motion-retrofit]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "motion-lint copies waybar-design-lint's exact shape (banner, check() helper, single-python-subprocess TAB-line protocol) and keybind-doctor's D-18 path-argument self-test precedent — the eighth rerunnable gate in this repo's family"
    - "Deny-by-default surface discovery: a fixed list of known repo-authored directory families (hypr, quickshell, waybar, swaync, swayosd, walker, wleave, gtk-4.0, ags), globbed recursively by extension (.css/.scss, .conf, .qml) — new files inside those directories are covered automatically, with zero per-file registration"
    - "Same code path serves the real multi-root run and a single throwaway/fixture-directory run: the collection function always takes a LIST of base directories, just a different list depending on whether a target-dir argument was given"
    - "Exemption entries are printed once per declared entry (not once per matched file), so the debt list is a fixed, auditable set independent of which files currently exist"

key-files:
  created:
    - hypr/.config/hypr/scripts/motion-lint
    - hypr/.config/hypr/scripts/tests/motion-fixtures/compliant-gtk4.css
    - hypr/.config/hypr/scripts/tests/motion-fixtures/poisoned-raw-gtk4.css
    - hypr/.config/hypr/scripts/tests/motion-fixtures/poisoned-dangling-gtk4.css
    - hypr/.config/hypr/scripts/tests/motion-fixtures/compliant-hypr.conf
    - hypr/.config/hypr/scripts/tests/motion-fixtures/poisoned-raw-hypr.conf
    - hypr/.config/hypr/scripts/tests/motion-fixtures/poisoned-dangling-hypr.conf
    - hypr/.config/hypr/scripts/tests/motion-fixtures/compliant-qml.qml
    - hypr/.config/hypr/scripts/tests/motion-fixtures/poisoned-raw-qml.qml
    - hypr/.config/hypr/scripts/tests/motion-fixtures/poisoned-dangling-qml.qml
  modified:
    - theme-engine/.config/theme-engine/theme-doctor

key-decisions:
  - "The seven exemption entries: waybar/swaync/swayosd get 'GTK3, no variable mechanism exists' (permanent — no var() mechanism exists on GTK3 at all); walker, ags, wleave and animations.conf's 13 hand-authored animation= lines get 'pending Phase 13 retrofit' (temporary — wleave's entry is removed by plan 12-07, the rest by Phase 13)"
  - "The 'five GTK surfaces' pending retrofit = all six live GTK surfaces (ROADMAP Phase 13 criterion 1: waybar, swaync, walker, SwayOSD, wleave, AGS) minus wleave, which 12-07 retrofits within this same phase"
  - "QML compliant/poisoned fixtures use a Motion.<property> naming scheme derived directly from motion.json's semantic keys (camelCase + Duration/Easing, plus a top-level motionEnabled) since 12-06 has not yet built the real Motion.qml singleton — self-consistent between the lint's own definition-set derivation and the fixtures it validates against"
  - "Fixture pairs use a byte-identical header comment across the compliant/poisoned trio, with the corruption documented as a trailing inline comment on the one changed line, so diff reports exactly one changed line per pair as literally required by Task 2's acceptance criteria"

requirements-completed: [TOKEN-04]

coverage:
  - id: D1
    description: "motion-lint's CHECK A (reference resolution) and CHECK B (no raw values) run against the real deployed tree, both clean"
    requirement: "TOKEN-04"
    verification:
      - kind: integration
        ref: "~/.config/hypr/scripts/motion-lint (no args) -> 31 passed, 0 checks failed, exit 0, 27 surfaces scanned"
        status: pass
    human_judgment: false
  - id: D2
    description: "The lint is proven to fail on a deliberately poisoned surface for all three targets (GTK4 CSS, Hyprland conf, QML), both the raw-value and dangling-reference halves, before being trusted to pass"
    requirement: "TOKEN-04"
    verification:
      - kind: integration
        ref: "~/.config/hypr/scripts/motion-lint --self-test -> 9 passed, 0 failed (3 compliant fixtures exit 0, 6 poisoned fixtures exit non-zero with the FAIL line naming the corrupted construct)"
        status: pass
    human_judgment: false
  - id: D3
    description: "The gate refuses to run vacuously: an empty target directory FAILs with the zero-surfaces message; an empty definition-set base directory refuses to proceed rather than reporting every reference as dangling"
    requirement: "TOKEN-04"
    verification:
      - kind: integration
        ref: "motion-lint <empty-throwaway-dir> -> [FAIL] motion-lint scanned 0 surfaces; check the surface glob. (exit 1); MOTION_LINT_STATE_DIR=<empty-dir> motion-lint ~/.config/waybar -> [FAIL] zero motion definitions loaded... refusing to run (exit 1)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Abort reporting: an unreadable file inside the scanned set stops the run and names the file, rather than reporting success on the readable subset"
    requirement: "TOKEN-04"
    verification:
      - kind: integration
        ref: "chmod 000 one of two .css files in a throwaway dir -> motion-lint names the unreadable file and exits non-zero; the second (readable) file is never checked (proven by its absence from output)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Singular/plural correctness in the summary line, and every exemption entry prints on every run with a non-empty reason, excluded from the pass/fail tally"
    requirement: "TOKEN-04"
    verification:
      - kind: integration
        ref: "throwaway one-failure dir -> 'Summary: 2 passed, 1 check failed'; throwaway three-failure dir -> 'Summary: 3 passed, 3 checks failed'; real-tree run -> exactly 7 [EXEMPT] lines, all with a reason, theme-doctor's pass delta unaffected by them"
        status: pass
    human_judgment: false
  - id: D6
    description: "theme-doctor folds motion-lint on every invocation (not only when the standalone script is run), proven to fail through the fold before being trusted to pass, with EXEMPT/SKIP lines excluded from the tally"
    requirement: "TOKEN-04"
    verification:
      - kind: integration
        ref: "MOTION_LINT temporarily pointed at a wrapper scanning an isolated poisoned-fixture copy -> theme-doctor exits non-zero with the lint's FAIL line folded in; restored -> theme-doctor's motion-lint section reads 31 passed / 0 failed; chmod -x motion-lint -> theme-doctor prints a named [SKIP] and still exits on other checks alone"
        status: pass
    human_judgment: false

duration: 20min
completed: 2026-07-26
status: complete
---

# Phase 12 Plan 05: Unified Design-Token Pipeline — Motion Lint Summary

**A deny-by-default `motion-lint` (CHECK A reference resolution, CHECK B no-raw-values, CHECK C scanned-count floor) folded into `theme-doctor`, proven to fail against nine committed compliant/poisoned fixture pairs across GTK4 CSS, Hyprland conf and QML before being trusted to pass.**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-07-26T20:33:00Z (approx.)
- **Completed:** 2026-07-26T20:54:00Z
- **Tasks:** 3
- **Files modified:** 11 (10 new, 1 modified)

## Accomplishments

- `motion-lint` created at `hypr/.config/hypr/scripts/motion-lint`, copying `waybar-design-lint`'s exact shape (header banner, `check()` helper, single-python-subprocess TAB-line protocol) and `keybind-doctor`'s path-argument self-test precedent. CHECK A resolves every `var(--motion-*)`/`Motion.<property>`/Hyprland animation-curve reference against the names the pipeline actually emitted; CHECK B refuses a raw duration/easing literal in CSS/QML and a hand-authored (non `motion-`-prefixed) bezier curve in Hyprland conf; CHECK C asserts a `> 0` scanned-count floor with a hard refuse-to-proceed guard on an empty definition set.
- Deny-by-default surface discovery across nine known repo-authored directory families (hypr, quickshell, waybar, swaync, swayosd, walker, wleave, gtk-4.0, ags), with a 7-entry exemption list (waybar/swaync/swayosd: GTK3 has no `var()` mechanism at all; walker/ags/wleave/animations.conf: pending Phase 13 retrofit) printing one `[EXEMPT]` line per entry on every run, excluded from the pass/fail tally.
- Nine committed fixtures under `hypr/.config/hypr/scripts/tests/motion-fixtures/` — one compliant + two poisoned (raw-value, dangling-reference) per target — each poisoned fixture differing from its compliant sibling by exactly one changed line (verified with `diff`). A `--self-test` mode replays all nine in isolation and asserts the expected verdict, making criterion 3's "proven to fail" property a permanent rerunnable command rather than a one-time demonstration.
- `theme-doctor` gained a motion-lint fold immediately after the `waybar-design-lint` fold, demonstrated failing through a temporarily-substituted wrapper pointed at an isolated poisoned fixture before being restored to green, and demonstrated degrading to a named `[SKIP]` (not a hard FAIL) when the lint is not executable.
- New baselines: `theme-doctor` **172 passed / 1 failed** (up from 141/1 at 12-04's close — the 1 failure remains the pre-existing, out-of-scope untracked `vscodium/.local/share/applications/Vampire Survivors.desktop`); `theme-parity` unchanged at **1897 passed / 0 failed**.

## Task Commits

1. **Task 1: motion-lint — reference resolution, raw-value refusal, and a scanned-count floor** - `0cdebc3` (feat)
2. **Task 2: Committed poisoned and compliant fixture pairs, reached by path argument** - `a94572f` (test)
3. **Task 3: Fold motion-lint into theme-doctor** - `edd5ec2` (feat)

**Plan metadata:** committed alongside this SUMMARY (see final-commit step)

## Files Created/Modified

- `hypr/.config/hypr/scripts/motion-lint` - the deny-by-default motion-token gate (CHECK A/B/C, exemption list, `--self-test`)
- `hypr/.config/hypr/scripts/tests/motion-fixtures/compliant-gtk4.css` - longhand `transition-*`/`animation-*` GTK4 rules, all values token-driven
- `hypr/.config/hypr/scripts/tests/motion-fixtures/poisoned-raw-gtk4.css` - one `var()` reference replaced by a bare `150ms` literal
- `hypr/.config/hypr/scripts/tests/motion-fixtures/poisoned-dangling-gtk4.css` - one `var()` reference pointed at a name that is never emitted
- `hypr/.config/hypr/scripts/tests/motion-fixtures/compliant-hypr.conf` - `animations {}` block using only emitted `motion-*` curve names
- `hypr/.config/hypr/scripts/tests/motion-fixtures/poisoned-raw-hypr.conf` - one `bezier =` line replaced by a hand-authored non-`motion-`-prefixed curve
- `hypr/.config/hypr/scripts/tests/motion-fixtures/poisoned-dangling-hypr.conf` - `animation =` line referencing a curve name backed by no definition
- `hypr/.config/hypr/scripts/tests/motion-fixtures/compliant-qml.qml` - `Behavior` reading `duration`/`easing.bezierCurve`/`enabled` from `Motion.*`
- `hypr/.config/hypr/scripts/tests/motion-fixtures/poisoned-raw-qml.qml` - `duration` replaced by a bare integer literal
- `hypr/.config/hypr/scripts/tests/motion-fixtures/poisoned-dangling-qml.qml` - `easing.bezierCurve` pointed at an undefined `Motion.*` property
- `theme-engine/.config/theme-engine/theme-doctor` - new motion-lint fold (PASS/FAIL folded, EXEMPT/SKIP passed through uncounted)

## Decisions Made

- Exemption reasons follow the plan's two literal categories verbatim: "GTK3, no variable mechanism exists" for waybar/swaync/swayosd (permanent — no `var()` mechanism exists on GTK3 at all, confirmed against the plan's own RESEARCH finding even though `theme-doctor`'s own CSS-parse guard happens to run swayosd's stylesheet through a GTK4 `CssProvider` for a structurally-unrelated reason); "pending Phase 13 retrofit" for walker, ags, wleave and `animations.conf`'s 13 hand-authored `animation =` lines (temporary — wleave's entry is removed by plan 12-07, the rest by Phase 13's designated sweep).
- Corrected "14" to "13" for `animations.conf`'s hand-authored `animation =` line count in this plan's own comments — 12-04's SUMMARY already binary-verified the real count as 13 (`grep -c '^\s*animation = '`), so this plan's exemption comment cites the verified number rather than repeating the plan text's miscount.
- GTK4/QML compliant fixtures are 100% token-driven (every duration/easing value in the fixture is a `var(--motion-*)`/`Motion.*` reference), rather than a literal copy of wleave's real not-yet-retrofitted mixed raw+token rule (12-RESEARCH Pattern 3's illustrative snippet has three raw `150ms` values alongside one token) — a fixture whose job is to demonstrate "the lint PASSES on a fully compliant surface" must itself have zero raw values under CHECK B's strict deny-by-default reading, so the shape (longhand comma-aligned form) is derived from wleave/RESEARCH while every value is deliberately fully token-driven.
- QML's `Motion.<property>` definition set is derived by camel-casing motion.json's semantic keys (`emphasized-in` -> `emphasizedIn` + `Duration`/`Easing` suffixes) plus a top-level `motionEnabled` from `motion_enabled` — this is forward-looking since plan 12-06 (a later plan, out of this plan's scope) has not yet built the real `Motion.qml` singleton; the naming scheme is self-consistent between the lint's own derivation and the QML fixtures it checks, and documented here for 12-06 to either adopt or reconcile against.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `os.walk()` silently dropped every file under a stow-symlinked subdirectory**
- **Found during:** Task 1, first real-tree run of the finished script
- **Issue:** This repo is deployed via GNU stow, which symlinks whole subdirectories as often as individual files (`~/.config/hypr/config -> ../../dotfiles/hypr/.config/hypr/config`, `~/.config/quickshell/modules -> ...`). Python's `os.walk()` defaults to `followlinks=False`, treating a symlinked directory as a leaf and never descending into it — silently dropping `hypr/config/animations.conf`, `hypr/config/keybinds.conf`, `quickshell/modules/Probe.qml`, `quickshell/modules/ScreencopyProbe.qml` and others from the surface set entirely (18 surfaces found instead of the real 27).
- **Fix:** `os.walk(root, followlinks=True)`. Safe here since this whole tree is a single trusted repo checkout with no untrusted-input traversal-attack surface.
- **Files modified:** `hypr/.config/hypr/scripts/motion-lint`
- **Verification:** Re-run against the real tree: scanned count rose from 18 to the correct 27 surfaces (css/scss=12, conf=12, qml=3), all previously-invisible files now checked and passing.
- **Committed in:** `0cdebc3` (Task 1 commit)

**2. [Rule 1 - Bug] QML definition set omitted `motionEnabled`, the property Pitfall 4 requires**
- **Found during:** Task 2, while constructing the compliant QML fixture per 12-RESEARCH.md Pitfall 4 (`Behavior.enabled: Motion.motionEnabled` bound directly, not via a wrapped animation type)
- **Issue:** `load_qml_defs()` only derived per-semantic-pair `<key>Duration`/`<key>Easing` names from `motion.json`'s `semantic` object, omitting the top-level `motion_enabled` boolean — so the compliant QML fixture's legitimate `enabled: Motion.motionEnabled` reference would have registered as a CHECK A dangling reference in the very fixture meant to demonstrate compliance.
- **Fix:** Added a `motionEnabled` definition to the QML set whenever `motion.json` declares `motion_enabled`.
- **Files modified:** `hypr/.config/hypr/scripts/motion-lint`
- **Verification:** `compliant-qml.qml` (which uses `Motion.motionEnabled`) exits 0 through both a direct isolated run and `--self-test`.
- **Committed in:** `a94572f` (Task 2 commit)

**3. [Rule 1 - Bug] Default run's own hypr-tree glob picked up the lint's own fixtures**
- **Found during:** Task 3, first `theme-doctor` run after the fold
- **Issue:** `hypr/.config/hypr/scripts/tests/motion-fixtures/` lives physically inside the hypr config tree, which the default (argument-less) run recursively scans. The nine deliberately-poisoned fixtures were therefore scored as real surface violations, folding 6 spurious FAILs into `theme-doctor`'s tally.
- **Fix:** A context-aware exclusion: the fixtures directory is skipped during collection only when none of the roots the caller passed is itself inside it — so the default multi-root run excludes it, while `--self-test` and a direct fixtures-dir invocation (which explicitly target it) are unaffected.
- **Files modified:** `hypr/.config/hypr/scripts/motion-lint`
- **Verification:** Real-tree run returned to 31 passed / 0 failed with the fixtures directory excluded; `--self-test` (which targets the fixtures directly) still passed 9/9 afterward.
- **Committed in:** `edd5ec2` (Task 3 commit)

---

**Total deviations:** 3 auto-fixed (all Rule 1 bugs, all caught by directly exercising the plan's own acceptance criteria against the live tree, not by code review)
**Impact on plan:** All three were necessary for the lint to correctly measure the real tree at all — without fix 1 the lint was blind to more than a third of the real surface set; without fix 2 the lint's own compliant fixture would have failed; without fix 3 the lint would have permanently broken `theme-doctor` the moment its fixtures were committed. No scope creep — all three are corrections to this plan's own deliverable, not new functionality.

## Issues Encountered

- `theme-doctor`'s own `swayosd/style.css` CSS-parse guard runs it through a GTK4 `CssProvider` (structural-validity check, unrelated to motion tokens), while this plan's motion-lint — following the plan text and 12-RESEARCH.md's explicit finding verbatim — classifies SwayOSD as a GTK3 surface with no `var()` mechanism for the "GTK3, no variable mechanism exists" exemption reason. Both statements can be true simultaneously (a stylesheet can parse cleanly through a GTK4 `CssProvider` while the actual running toolkit lacks live custom-property support at style-computation time); this plan did not attempt to resolve the discrepancy, since SwayOSD currently hand-rolls zero motion values either way and the exemption is a documented, reversible placeholder that Phase 13 (its designated owner) can correct with better evidence.

## Known Stubs

None — `motion-lint` is fully wired end-to-end: it reads real emitted definition files, scans the real deployed surface tree, is folded into `theme-doctor` on every invocation, and its "proven to fail" property is a committed, rerunnable `--self-test` command rather than a one-time demonstration. The QML `Motion.<property>` naming scheme it validates against is explicitly documented as forward-looking (12-06 has not yet built the real `Motion.qml` singleton) in "Decisions Made" above, not hidden.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `theme-doctor`: **172 passed / 1 failed** (up from 141/1 at 12-04's close) — the 1 failure remains the pre-existing, out-of-scope untracked `vscodium/.local/share/applications/Vampire Survivors.desktop` file. New baseline for later plans: **172** (173/0 once that stray file is resolved by its owner).
- `theme-parity`: unchanged at **1897 passed / 0 failed** — this plan does not touch `theme-parity`.
- `motion-lint` is proven end-to-end and folded into `theme-doctor`; plan 12-06 (QML `Motion.qml` singleton + `qml-palette.json`/`config.toml`/`contract.json` changes) should reconcile its real property naming against this plan's forward-looking `<key>Duration`/`<key>Easing`/`motionEnabled` scheme documented in "Decisions Made" — either adopt it or update motion-lint's `load_qml_defs()` to match whatever 12-06 actually ships.
- Plan 12-07 (wleave motion retrofit) removes the `wleave/style.css` exemption entry from motion-lint once it retrofits wleave's stylesheet to consume `var(--motion-*)` tokens — that is the one exemption entry this phase itself is expected to close, not defer to Phase 13.
- Phase 13's designated existing-surface sweep inherits five open exemption entries (waybar, swaync, swayosd: permanent GTK3 debt; walker, ags: temporary GTK4-capable debt) plus `animations.conf`'s 13-line debt — all visible on every `motion-lint`/`theme-doctor` run via `[EXEMPT]` lines, per this plan's prohibition against silencing them.

---
*Phase: 12-unified-design-token-pipeline*
*Completed: 2026-07-26*

## Self-Check: PASSED

- FOUND: hypr/.config/hypr/scripts/motion-lint
- FOUND: hypr/.config/hypr/scripts/tests/motion-fixtures/compliant-gtk4.css
- FOUND: hypr/.config/hypr/scripts/tests/motion-fixtures/poisoned-raw-gtk4.css
- FOUND: hypr/.config/hypr/scripts/tests/motion-fixtures/poisoned-dangling-gtk4.css
- FOUND: hypr/.config/hypr/scripts/tests/motion-fixtures/compliant-hypr.conf
- FOUND: hypr/.config/hypr/scripts/tests/motion-fixtures/poisoned-raw-hypr.conf
- FOUND: hypr/.config/hypr/scripts/tests/motion-fixtures/poisoned-dangling-hypr.conf
- FOUND: hypr/.config/hypr/scripts/tests/motion-fixtures/compliant-qml.qml
- FOUND: hypr/.config/hypr/scripts/tests/motion-fixtures/poisoned-raw-qml.qml
- FOUND: hypr/.config/hypr/scripts/tests/motion-fixtures/poisoned-dangling-qml.qml
- FOUND: theme-engine/.config/theme-engine/theme-doctor
- FOUND commit: 0cdebc3 (Task 1)
- FOUND commit: a94572f (Task 2)
- FOUND commit: edd5ec2 (Task 3)
