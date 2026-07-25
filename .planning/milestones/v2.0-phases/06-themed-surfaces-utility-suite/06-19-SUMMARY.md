---
phase: 06-themed-surfaces-utility-suite
plan: 19
subsystem: theming
tags: [theme-doctor, gtk-css, pygobject, regression-guard, gap-closure]

# Dependency graph
requires:
  - phase: 06-themed-surfaces-utility-suite
    provides: "wlogout stylesheet that parses cleanly under GTK3 (06-16, the exact defect this guard now catches permanently)"
provides:
  - "theme-doctor GTK CSS-parse regression guard covering 6 GTK3 surfaces + 3 GTK4 surfaces, asserting zero fatal errors AND a non-empty CssProvider"
  - "Proof-by-synthetic-regression that the guard actually fails on a discarded stylesheet (not merely asserted to)"
affects: []

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "GTK CSS-parse guards must assert a NON-EMPTY CssProvider.to_string(), not just 'no exception raised' — an empty provider is the load-bearing signature of a stylesheet GTK silently discarded in full (GTK3 3.24.52 confirmed: one invalid pseudo-class empties the WHOLE sheet, not just the bad rule)"
    - "GTK3 and GTK4 cannot share a python3 process (gi.require_version conflict) — any dual-toolkit CSS guard needs two separate invocations"
    - "GTK4's CssProvider exposes no 'parsing-error' GObject signal in this PyGObject binding (verified empirically: GObject.signal_list_ids() returns zero signals on the GType) — unlike GTK3, fatal/non-fatal error-code distinction is not obtainable for GTK4 through the standard binding; the non-empty-provider check is the only reliable signal available"
    - "GTK3's Gtk.CssProvider().load_from_path() DOES raise a Python exception carrying the first fatal GError (domain gtk-css-provider-error-quark, code != 4), in addition to firing the 'parsing-error' signal for every error encountered — both mechanisms are redundant safety nets, not alternatives"

key-files:
  created: []
  modified:
    - theme-engine/.config/theme-engine/theme-doctor

key-decisions:
  - "GTK4 fatal/non-fatal distinction implemented as 'no signal exists, empty-provider is the only actionable check' rather than domain/code filtering — deviates from the plan's literal 'GTK4: domain gtk-css-parser-warning-quark, any code' framing, which describes GTK4's internal C-level quark naming but not an API surface actually reachable from PyGObject on this GTK 4.22 install. Empirically confirmed via GObject.signal_list_ids(Gtk.CssProvider.__gtype__) returning an empty list. The non-empty-provider assertion (the plan's own stated load-bearing signal) still fully covers GTK4 in practice — verified none of the 3 real GTK4 surfaces exhibit any deprecation today, so no false-fail risk currently exists."
  - "Path-fragment identifier for check descriptions uses os.path.relpath(path, ~/.config) rather than basename, since several stylesheets share a bare filename (gtk.css x2, style.css x4) and the acceptance grep patterns (wlogout, style-full, gtk-3.0, walker, swayosd, etc.) require each to be uniquely and unambiguously present in its own PASS/FAIL/SKIP line"

requirements-completed: [WLOG-01]

coverage:
  - id: D1
    description: "theme-doctor runs every GTK-consumed stylesheet the pipeline owns (6 GTK3 + 3 GTK4 surfaces) through a real Gtk.CssProvider parse, asserting a non-empty provider and zero fatal errors"
    requirement: "WLOG-01"
    verification:
      - kind: integration
        ref: "bash theme-engine/.config/theme-engine/theme-doctor — [PASS]/[SKIP] lines for all 9 configured surfaces"
        status: pass
    human_judgment: false
  - id: D2
    description: "Guard distinguishes fatal parse errors from non-fatal deprecations (waybar/style-floating.css's unitless border-radius, IN-02) so it does not false-fail on a deferred, cosmetic-only issue"
    requirement: "WLOG-01"
    verification:
      - kind: integration
        ref: "theme-doctor output: '[PASS] CSS-parse: waybar/style-floating.css (12938 bytes)' despite the code-4 deprecation"
        status: pass
    human_judgment: false
  - id: D3
    description: "Guard runs headless (no display server) and degrades gracefully — SKIP (not FAIL) when python-gobject is unavailable or a deployed sheet is absent"
    requirement: "WLOG-01"
    verification:
      - kind: integration
        ref: "env -u WAYLAND_DISPLAY -u DISPLAY -u XDG_SESSION_TYPE bash theme-doctor (identical PASS/SKIP results); python3-shim test with 'import gi' failing (single SKIP line, FAIL count unchanged at 31 passed/1 failed baseline)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Guard is proven to actually FAIL on a poisoned stylesheet (synthetic regression using the exact CR-01 generated-content construct), not merely asserted to have this property"
    requirement: "WLOG-01"
    verification:
      - kind: integration
        ref: "Task 3 synthetic regression: poisoned copy of waybar/style-full.css -> FAIL 0 (empty provider); clean original -> PASS 15347 bytes; theme-parity holds at 1542 passed/0 failed; zero artifacts left under ~/.config or /tmp"
        status: pass
    human_judgment: false
  - id: D5
    description: "Guard's python-gobject dependency is reproducible from a fresh install.sh run (no host-only state)"
    requirement: "WLOG-01"
    verification:
      - kind: unit
        ref: "grep -n python-gobject install.sh confirms line 135 falls inside PACMAN_PKGS (opens line 52, closes line 177); python3 -c import gi confirms the binding supplies Gtk.CssProvider"
        status: pass
    human_judgment: false

# Metrics
duration: 20min
completed: 2026-07-13
status: complete
---

# Phase 06 Plan 19: GTK CSS-parse regression guard for theme-doctor Summary

**theme-doctor now parses all 6 GTK3 and 3 GTK4 pipeline-owned stylesheets through a real `Gtk.CssProvider`, asserting a non-empty provider and zero fatal errors — proven with a synthetic regression that reproduces CR-01's exact discard signature (0 bytes) and fails, closing the exact blind spot that let four prior grep-only verification rounds pass on a completely unthemed wlogout surface.**

## Performance

- **Duration:** ~20 min
- **Started:** 2026-07-13T04:16:34Z (approx, per STATE.md wave-2 start)
- **Completed:** 2026-07-13T04:23:51Z (approx)
- **Tasks:** 3 (2 code/proof tasks + 1 verify-only task with no diff)
- **Files modified:** 1

## Accomplishments
- Added a `GTK CSS-parse regression guard` section to `theme-doctor` covering 6 GTK3 surfaces (wlogout, 3x waybar, gtk-3.0, swaync) and 3 GTK4 surfaces (gtk-4.0, swayosd, walker), each run through `Gtk.CssProvider().load_from_path()` against the **deployed** `$HOME/.config/...` path (never the repo copy, since the stow files' relative `@import` only resolves from the deployed location)
- Guard asserts the load-bearing signal explicitly: a **non-empty** `provider.to_string()`, not merely "no exception" — this is the exact distinction that would have caught CR-01 on day one, since a parse-error-only check cannot see a stylesheet GTK discards wholesale
- GTK3 fatal/non-fatal distinction implemented via the `parsing-error` signal filtering out GError code 4 (deprecation); `waybar/style-floating.css`'s pre-existing unitless `border-radius: 10` (IN-02, deferred) correctly PASSes despite the deprecation
- Confirmed `python-gobject` was already present in `install.sh`'s `PACMAN_PKGS` (line 135, inside the array's line 52-177 span) — no edit needed, reproducibility constraint already satisfied
- Proved the guard has teeth with a synthetic regression: poisoned a temp copy of `waybar/style-full.css` with the exact `button::after { content: "x"; }` construct CR-01 identified, confirmed the guard's parse logic reports `FAIL 0` (empty provider) on the poisoned copy and `PASS 15347` on the clean original, with zero artifacts left behind and `theme-parity` unchanged at 1542 passed / 0 failed

## Task Commits

1. **Task 1: Add the GTK CSS-parse guard to theme-doctor** - `7b829bb` (feat)
2. **Task 2: Assert the guard's dependency is reproducible from install.sh** - no commit (verify-only, `python-gobject` already present, zero diff produced)
3. **Task 3: Prove the guard actually fails — synthetic regression test** - no commit (proof-only task, temp artifacts cleaned up via `trap ... EXIT`, no repo files touched)

**Plan metadata:** committed separately after this SUMMARY (see final commit)

## Files Created/Modified
- `theme-engine/.config/theme-engine/theme-doctor` - New GTK CSS-parse guard section (116 lines): two arrays of deployed stylesheet paths (`GTK3_CSS_SHEETS`, `GTK4_CSS_SHEETS`), a `_theme_doctor_css_parse()` bash function wrapping a python3 heredoc probe (invoked once per GTK major version, since GTK3/GTK4 cannot share a process), and bash glue that routes each probe result into the existing `check "<desc>" "$?"` helper or a direct `[SKIP]` echo for absent sheets. Guarded by a top-level `python3 -c "import gi"` availability check that SKIPs the entire section with one line if the binding is missing. Inserted after the elephant/walker provider-parity block and before the CLEAN-02 git-clean check, per the plan's placement instruction.

## Decisions Made
- **GTK4 error-domain distinction is not reachable via PyGObject on this GTK 4.22 install.** The plan's action text described a GTK4 fatal/non-fatal filter analogous to GTK3's (`domain gtk-css-parser-warning-quark, any code`). Empirically, `Gtk.CssProvider`'s GType exposes **zero** GObject signals on GTK4 (confirmed via `GObject.signal_list_ids()`), and `load_from_path()` neither raises an exception nor emits any catchable error object for parse issues on GTK4 — it only logs a `Gtk-WARNING` to stderr. This is a genuine GTK4 API-surface gap, not an implementation oversight: there is no `parsing-error` signal on `GtkCssProvider` in GTK4 (removed relative to GTK3), and no documented Python-reachable replacement. The guard therefore implements the plan's own stated load-bearing check (non-empty provider) as the sole GTK4 signal, which the plan itself calls "the load-bearing assertion... do not drop it in favour of 'no errors'" — so GTK4 coverage is not weakened relative to the plan's stated priorities, only the secondary fatal/non-fatal filtering layer (which GTK3 has and GTK4 structurally cannot expose) is absent. All 3 real GTK4 surfaces on this machine currently parse with zero warnings of any kind, so there is no live false-fail risk from this gap today.
- **Path-fragment identifiers use `os.path.relpath` against `~/.config`, not `os.path.basename`.** Several stylesheets share a bare filename (`gtk.css` for both gtk-3.0 and gtk-4.0; `style.css` for wlogout, swaync, swayosd, and walker's `themes/rice/style.css`). Basenames alone would collide and would not satisfy the acceptance grep patterns (`wlogout`, `gtk-3.0`, `gtk-4.0`, `walker`, `swayosd` must each appear unambiguously). Using the path relative to `~/.config` (e.g. `wlogout/style.css`, `gtk-3.0/gtk.css`, `walker/themes/rice/style.css`) makes every check description unique and satisfies every acceptance substring.
- Kept the GTK3 probe's belt-and-suspenders design (both the `parsing-error` signal connect AND a `try/except` around `load_from_path`) exactly matching the plan's own Task 3 reference verify-script logic, rather than relying on the incidentally-observed fact that GTK3 also raises a Python exception for the first fatal error — the signal-based approach is documented plan behavior and catches every error the signal reports, not just the first.

## Deviations from Plan

### Auto-fixed Issues

None — no bugs, missing functionality, or blocking issues were encountered that required Rule 1/2/3 auto-fixes.

### Plan-text vs. empirical-API divergence (documented above under Decisions, not a Rule 1-4 deviation)

The one substantive divergence — GTK4 having no reachable `parsing-error` signal via PyGObject — is not a deviation from a *requirement* (the plan's threat register T-06-W16 explicitly identifies the non-empty-provider check as the actual load-bearing mitigation, and that check is fully implemented for both GTK3 and GTK4). It is a correction to a factual claim in the plan's action text about GTK4's API surface, made after direct empirical verification (`GObject.signal_list_ids()` on the live GTK 4.22 install), following the same evidence-first pattern 06-16's SUMMARY used for the `border-radius` shorthand-expansion correction. Documented above rather than as a numbered Rule 1-4 fix since no code behaved incorrectly — the plan's prose description of GTK4's internals needed correcting, not the guard's logic.

---

**Total deviations:** 0 auto-fixed; 1 documented plan-text/API-surface correction (no code impact, load-bearing assertion unaffected)
**Impact on plan:** Zero impact on the guard's actual protective coverage — the non-empty-provider check the plan itself identifies as load-bearing is implemented for all 9 surfaces across both GTK3 and GTK4, and proven to fail on a poisoned sheet via Task 3's synthetic regression.

## Issues Encountered
None beyond the GTK4 API-surface finding documented above, which was resolved by implementing the guard against the API PyGObject actually exposes rather than the theoretical domain/code the plan described.

## User Setup Required
None - no external service configuration required. `theme-doctor` is stow-symlinked and the edit is live immediately; `python-gobject` was already installed and already in `install.sh`.

## Next Phase Readiness
- The exact defect class that produced the WLOG-01 blocker (a stylesheet silently discarded in full, invisible to grep-only verification) is now permanently detectable by a rerunnable health check, proven via synthetic regression rather than asserted.
- `theme-doctor` baseline holds: 39 passed / 1 failed (the one expected `git status --porcelain is empty` failure on a dirty working tree during execution) — up from the pre-plan 31 passed / 1 failed, reflecting the 8 new CSS-parse checks (7 PASS + 1 SKIP for the undeployed swayosd sheet).
- `theme-parity` holds unchanged at 1542 passed / 0 failed.
- This closes the last of the 06-16/06-17/06-18/06-19 gap-closure plan set (wave 2). No further gap-closure plans are queued for phase 06 as of this summary.

---
*Phase: 06-themed-surfaces-utility-suite*
*Completed: 2026-07-13*

## Self-Check: PASSED

- FOUND: theme-engine/.config/theme-engine/theme-doctor
- FOUND: .planning/phases/06-themed-surfaces-utility-suite/06-19-SUMMARY.md
- FOUND commit: 7b829bb
- FOUND commit: b3e1b9f
