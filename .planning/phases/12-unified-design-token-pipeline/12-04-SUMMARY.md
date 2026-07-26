---
phase: 12-unified-design-token-pipeline
plan: 04
subsystem: theming
tags: [hyprland, gsettings, jq, bash, motion, bezier, hyprctl]

# Dependency graph
requires:
  - phase: 12-03
    provides: "motion.json, lib/motion.sh (reader/validator/renderer), three rendered motion targets under ~/.local/state/theme/, contract.json engine_owned_files array"
provides:
  - "motion-switch.sh: validated CLI over the motion-scale state file (off/reduced/normal/lively, --get, --list)"
  - "org.gnome.desktop.interface enable-animations wired into gtk.sh's single GSettings block — the system-wide reduced-motion signal beyond this repo's own surfaces"
  - "Corrected lib/motion.sh animations_enabled extraction — fixes a jq `// empty` bug that silently broke the entire 'off' preset"
  - "hyprland.conf source order: hyprland-motion.conf sourced before config/animations.conf (D-22)"
  - "animations.conf: enabled = $motion_enabled, D-04 fence (12 beziers, animation= lines) untouched"
  - "stow.sh: two new seed-when-absent blocks — motion-scale default, and the three rendered motion files seeded by invoking motion.sh's own renderer"
  - "theme-doctor D-02b hyprctl animations -j readback gate, motion-scale-aware, degrades to SKIP without a compositor"
  - "theme-parity Layer 4: D-31 motion byte-identity assertion across all 22 render dirs"
affects: [12-05, 12-06, 12-07, 12-08, 13-motion-retrofit]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "motion-scale is a fourth theme-orthogonal-axis CLI (after theme-apply, font-switch, icon-theme-switch), but deliberately state-file+CLI only — no fzf picker, no Super-key entry (D-07, deferred to Phase 13)"
    - "hyprctl -j readback proven trustworthy for `animations` (unlike `binds -j`, which Phase 11 abandoned) — used as a gate confirming emitted values survive into the live compositor, not merely that files exist"
    - "jq's `//` alternative operator treats JSON `false` identically to `null`/absent — any jq extraction of a boolean-valued key must use `has()` or an explicit `if/then/else`, never `// empty`"

key-files:
  created:
    - hypr/.config/hypr/scripts/motion-switch.sh
  modified:
    - theme-engine/.config/theme-engine/lib/gtk.sh
    - theme-engine/.config/theme-engine/lib/motion.sh
    - hypr/.config/hypr/hyprland.conf
    - hypr/.config/hypr/config/animations.conf
    - stow.sh
    - theme-engine/.config/theme-engine/theme-doctor
    - theme-engine/.config/theme-engine/theme-parity

key-decisions:
  - "motion-switch.sh duplicates theme_engine_read_motion_scale's closed-set case in miniature rather than sourcing lib/motion.sh, since this script runs standalone from a keybind/terminal (not from inside theme-apply's already-sourced process) — both read the exact same state file and default"
  - "The D-02b readback check's bezier-line regex uses loose ([^,]+) value groups, not a numeric class — a corrupted non-numeric control point must still reach the jq comparison and be reported as a mismatch, not silently skipped by a regex that only matches well-formed floats"
  - "D-31's byte-identity assertion is its own Layer 4 in theme-parity, placed after the existing three layers, rather than folded into Layer 2's name-set comparison — name-set equality says nothing about value identity"

requirements-completed: [TOKEN-03, TOKEN-05]

coverage:
  - id: D1
    description: "A named motion-scale preset is selectable via motion-switch.sh and drives all three emitted targets through one theme-apply run"
    requirement: "TOKEN-05"
    verification:
      - kind: integration
        ref: "motion-switch.sh reduced && one theme-apply run -> emphasized-in duration_ms is exactly half the normal-preset value (300ms -> 150ms)"
        status: pass
      - kind: integration
        ref: "motion-switch.sh bogus -> usage error, exit 1, motion-scale byte-unchanged (cmp before/after)"
        status: pass
    human_judgment: false
  - id: D2
    description: "off disables at the toolkit level (Hyprland animations.enabled + GNOME enable-animations), not by shrinking durations"
    requirement: "TOKEN-05"
    verification:
      - kind: integration
        ref: "motion-switch.sh off -> gsettings get org.gnome.desktop.interface enable-animations == false; jq -e '.motion_enabled==false' motion.json; grep -c '^$motion_enabled = false' hyprland-motion.conf == 1"
        status: pass
      - kind: integration
        ref: "motion-switch.sh normal -> gsettings get enable-animations == true"
        status: pass
    human_judgment: false
  - id: D3
    description: "Hyprland sources the generated motion fragment before config/animations.conf (D-22); a missing fragment is proven load-bearing"
    requirement: "TOKEN-03"
    verification:
      - kind: integration
        ref: "Hyprland --verify-config against the live tree: config ok"
        status: pass
      - kind: integration
        ref: "throwaway tree with the source= line pointed at a nonexistent path -> Hyprland --verify-config fails with 'source= globbing error: found no match'"
        status: pass
    human_judgment: false
  - id: D4
    description: "stow.sh seeds motion-scale and the three rendered motion files by invoking motion.sh's own renderer (never a hand-authored stub), proven idempotent and proven to fire"
    requirement: "TOKEN-03"
    verification:
      - kind: integration
        ref: "sentinel written to motion-scale, seed logic re-run -> sentinel survives (idempotent)"
        status: pass
      - kind: integration
        ref: "all three rendered files + motion-scale moved aside, seed logic re-run -> all four recreated, byte-identical to the originals"
        status: pass
    human_judgment: false
  - id: D5
    description: "theme-doctor's hyprctl animations -j readback confirms emitted motion-* curves hold their generated control points, proven to fail before being trusted to pass"
    requirement: "TOKEN-03"
    verification:
      - kind: integration
        ref: "theme-doctor readback line: [PASS] 4 curve(s) confirmed matching emitted control points"
        status: pass
      - kind: integration
        ref: "hyprland-motion.conf corrupted with a non-numeric control point (bezier = motion-standard, abc, 0, 0, 1), hyprctl reload, theme-doctor -> [FAIL] naming motion-standard(not-found-in-readback); restored -> theme-doctor readback returns to [PASS]"
        status: pass
      - kind: integration
        ref: "PATH stripped of hyprctl -> theme-doctor prints named [SKIP], still exits without that check counted as FAIL"
        status: pass
    human_judgment: false
  - id: D6
    description: "theme-parity's D-31 byte-identity assertion proves the three motion targets are identical across all 22 render dirs, proven to fail on a throwaway divergence"
    requirement: "TOKEN-03"
    verification:
      - kind: integration
        ref: "theme-parity: [PASS] motion byte-identity for all 3 files across 22 render dir(s), diverged: none"
        status: pass
      - kind: integration
        ref: "throwaway two-target render (catppuccin + dracula, /tmp only) with one-character corruption in dracula's gtk-4.0-motion.css, exact Layer-4 hash-compare logic run standalone -> reports dracula diverged from catppuccin, naming both hashes"
        status: pass
    human_judgment: false

duration: 45min
completed: 2026-07-26
status: complete
---

# Phase 12 Plan 04: Unified Design-Token Pipeline — Motion Runtime Axis & Hyprland Wiring Summary

**A validated `motion-switch.sh` CLI drives a four-preset motion-scale axis through `theme-apply`'s existing entrypoint and a portal-wide GNOME `enable-animations` signal; `hyprland.conf`/`animations.conf` are wired in the D-22 source order with fresh-install seeding in `stow.sh`; and `theme-doctor`/`theme-parity` gained a `hyprctl` readback gate and a D-31 byte-identity assertion, both demonstrated failing before being trusted to pass.**

## Performance

- **Duration:** ~45 min
- **Started:** 2026-07-26T20:11:00Z (approx.)
- **Completed:** 2026-07-26T20:27:39Z
- **Tasks:** 3
- **Files modified:** 8 (1 new, 7 modified)

## Accomplishments

- `motion-switch.sh` created: a validated CLI (`off|reduced|normal|lively`, `--get`, `--list`) over the `motion-scale` state file, writing via the temp-file-plus-`mv` idiom and triggering exactly one `theme-apply` re-render — no second render entrypoint, no fzf picker or Super-key menu entry (D-07, deferred to Phase 13).
- `gtk.sh` extended with `org.gnome.desktop.interface enable-animations`, wired to the same closed preset set — the system-wide GSettings signal that makes reduced-motion honoured by third-party GTK/libadwaita apps through the portal, closing the "false accessibility claim" gap TOKEN-05 explicitly warns against.
- **Rule 1 bug fix, discovered live:** `lib/motion.sh`'s `animations_enabled` extraction used jq's `// empty`, which silently treats a legitimate JSON `false` the same as `null`/absent — this completely broke the `off` preset (its entire purpose is `animations_enabled == false`). Fixed with a `has()`-based extraction that distinguishes "present and false" from "genuinely missing." Caught by directly exercising Task 1's own `off` acceptance criterion against the live desktop, not by code review.
- `hyprland.conf` now sources the generated motion fragment immediately before `config/animations.conf` (D-22); `animations.conf`'s `enabled = true` became `enabled = $motion_enabled`, with the 12 hand-authored beziers and the file's `animation =` assignment lines untouched (D-04 fence). Verified with a real `Hyprland --verify-config` failure against a throwaway tree missing the fragment: `source= globbing error: found no match`.
- `stow.sh` gained two fresh-install seeds: `motion-scale` defaults to `normal`; the three rendered motion files are seeded by **invoking `motion.sh`'s own renderer** into a tmp tree and copying the output across — never a hand-authored stub — so a fresh install cannot reach first login with an undefined `$motion_enabled` or a missing sourced fragment (both hard Hyprland parse errors). Proven idempotent and proven to fire against the live state dir.
- `theme-doctor` gained the D-02b `hyprctl animations -j` readback gate, confirming every emitted `motion-*` curve's control points survive unchanged into the live compositor. Demonstrated failing first: a corrupted non-numeric control point made Hyprland **silently drop the entire curve** (no parse error, `hyprctl reload` reports "ok") — exactly the silent-substitution risk this gate exists to catch — and the check correctly named it. Motion-scale-aware: `off` still PASSes on curve values.
- `theme-parity` gained Layer 4, the D-31 motion byte-identity assertion, hashing the three motion targets across all 22 render dirs (20 static presets + materialyou + materialyou-light) and asserting one hash per file across the whole set. Demonstrated failing on a throwaway two-target render with a one-character corruption, naming the diverged target — never touching live state.

## Task Commits

1. **Task 1: motion-scale axis — CLI, state file, and the GSettings signal that makes reduced-motion real** - `5f7d03f` (feat)
2. **Task 2: Hyprland source-order wiring and fresh-install seeding** - `51231bc` (feat)
3. **Task 3: hyprctl readback, the speed-unit reconciliation, and D-31's byte-identity assertion** - `5a676e6` (feat)

**Plan metadata:** committed alongside this SUMMARY (see final-commit step)

## Files Created/Modified

- `hypr/.config/hypr/scripts/motion-switch.sh` - validated CLI over the motion-scale state file
- `theme-engine/.config/theme-engine/lib/gtk.sh` - `enable-animations` joins the existing GSettings block
- `theme-engine/.config/theme-engine/lib/motion.sh` - Rule 1 fix: `has()`-based `animations_enabled` extraction, replacing the `// empty` idiom that silently swallowed `false`
- `hypr/.config/hypr/hyprland.conf` - sources `hyprland-motion.conf` before `config/animations.conf` (D-22)
- `hypr/.config/hypr/config/animations.conf` - `enabled = $motion_enabled` (12 beziers + animation= lines untouched)
- `stow.sh` - two new seed-when-absent blocks (motion-scale default, motion.sh-invoked file seeding)
- `theme-engine/.config/theme-engine/theme-doctor` - new D-02b hyprctl readback gate
- `theme-engine/.config/theme-engine/theme-parity` - new Layer 4 (D-31 byte-identity assertion)

## Decisions Made

- `motion-switch.sh` re-implements `theme_engine_read_motion_scale`'s closed-set `case` in miniature rather than sourcing `lib/motion.sh` — this script is invoked standalone from a keybind/terminal, not from inside `theme-apply`'s already-sourced process, and both copies read the exact same state file and default value so there is no drift risk.
- The D-02b readback check's bezier-line-parsing regex intentionally uses loose `([^,]+)` value groups rather than a numeric character class, discovered necessary during the fail-first demonstration: a numeric-only regex silently skips a non-numeric corrupted value instead of routing it to the readback comparison, which would have made the very corruption scenario the gate exists for invisible to the gate itself.
- D-31's byte-identity assertion is placed as its own distinct Layer 4 after the existing three layers in `theme-parity`, not folded into Layer 2's name-set comparison — name-set equality proves nothing about value identity, which is D-31's actual claim.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `lib/motion.sh`'s `animations_enabled` extraction silently broke the `off` preset**
- **Found during:** Task 1, running the exact `off`-preset acceptance criterion against the live desktop
- **Issue:** `jq -r --arg s "$scale" '.scales[$s].animations_enabled // empty'` — jq's `//` alternative operator treats JSON `false` identically to `null`/absent, so for the `off` preset (whose `animations_enabled` is legitimately `false`), the extraction always fell through to `empty`. `theme_engine_render_motion_files` then reported "motion.json is missing scales.'off' or floor_ms" and aborted the whole render — the `off` preset was completely non-functional the moment Task 1 tried to exercise it, even though 12-03's own render pipeline never triggers this path (it only ever ran at the `normal` default until this plan added a way to actually select `off`).
- **Fix:** Replaced the extraction with a `has()`-based check that distinguishes "key present and `false`" from "key genuinely missing": `if (.scales[$s] // {} | has("animations_enabled")) then (.scales[$s].animations_enabled | tostring) else empty end`.
- **Files modified:** `theme-engine/.config/theme-engine/lib/motion.sh`
- **Verification:** `motion-switch.sh off` followed by one `theme-apply` run now correctly sets `motion_enabled: false` in the rendered JSON, `$motion_enabled = false` in the Hyprland fragment, and `enable-animations` to `false` via gsettings — all three targets confirmed live.
- **Committed in:** `5f7d03f` (Task 1 commit)

**2. [Documentation drift, not a bug] Task 2's acceptance criterion cites `animation = ` count as 14; the live file has 13**
- **Found during:** Task 2, running the exact `grep -c '^\s*animation = '` acceptance-criterion command
- **Issue:** The plan's read_first section and acceptance criteria both state the file's `animation =` line count as 14. The actual file (`hypr/.config/hypr/config/animations.conf`, both before and after this plan's edit) has exactly 13 such lines (windowsIn/Out/Move, fadeIn/Out/Switch/Shadow/Dim, border, borderangle, workspaces, specialWorkspace, layers). This is a miscount in the plan text, not a regression — the count is provably identical pre- and post-edit (I only touched the `enabled =` line), which is what the criterion is actually protecting (the D-04 fence staying intact).
- **Fix:** None applied — fabricating a 14th `animation =` line to match a wrong expected count would be worse than leaving the accurate count. Documented here instead.
- **Files modified:** none (no code change; documentation-only finding)
- **Verification:** `grep -c '^\s*animation = ' hypr/.config/hypr/config/animations.conf` returns `13` both before and after this plan's commit.
- **Committed in:** n/a (no code change)

---

**Total deviations:** 1 auto-fixed (Rule 1 bug), 1 documentation-only finding (no fix needed)
**Impact on plan:** The Rule 1 fix was necessary for TOKEN-05's `off` preset to function at all — without it, the axis's most safety-relevant state (full toolkit-level disable) was silently unreachable. The documentation finding required no code change and does not affect D-04's fence, which is proven intact by the unchanged count.

## Issues Encountered

- This plan's verification runs against the live, currently-running Hyprland session on the actual development machine (not a container or headless fixture) — `hyprctl reload` was invoked multiple times during Task 3's fail-first demonstrations, each restoring the live config immediately afterward. `theme-doctor`/`theme-parity`/`Hyprland --verify-config` were re-run after each restoration to confirm no residual drift. The motion-scale axis and `enable-animations` were left at `normal`/`true` before this plan closed.
- Hyprland's actual silent-failure behavior for a malformed bezier control point turned out to be a full curve **drop** (curve absent from `hyprctl animations -j` entirely, no parse error) rather than a value clamp/substitution — neither wildly out-of-range X/Y values nor negative X triggered any clamping in live testing on this Hyprland build. The readback check's design (name-based lookup, "not-found-in-readback" as a distinct failure mode) already covers this correctly; no design change was needed, but this is worth carrying forward as the concretely-observed failure mode rather than the more general "substitution" framing in the plan text.

## Known Stubs

None — every target this plan delivers is fully wired and exercised end-to-end against the live desktop: the CLI writes and is read back by the render pipeline, the GSettings key is confirmed via `gsettings get`, the Hyprland source order is confirmed via both a passing and a deliberately-failing `--verify-config` run, the fresh-install seeds are confirmed to fire and to be idempotent, and both new gates are demonstrated failing before being trusted to pass.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- **Speed-unit reconciliation, carried forward explicitly for Phase 13:** `hyprctl`'s readback reports `speed` as a float with two decimals where the Hyprland config source writes an integer; `speed = 0` and `speed = -1` are hard "invalid speed" parse errors and fractional values parse cleanly (both binary-verified this phase, recorded in a `theme-doctor` comment). The commonly cited decisecond interpretation (1 unit = 100ms) is `[CITED: wiki.hypr.land]` and was **not** independently binary-verified. This is not a gap Phase 12 could close: D-04 fences this phase to emitting curves only — no `speed` value is emitted anywhere in this codebase yet. **Phase 13 owns the 14 `animation =` assignment lines these curves get wired into, and must confirm the ms-to-speed conversion against the actual binary before emitting any `speed` value.**
- `motion-switch.sh` and the GSettings `enable-animations` signal are the mechanism Phase 13's graphical picker (deferred by D-07) will eventually sit on top of — the state file, validation, and one-entrypoint-render invariant are all already in place; a picker only needs to call this same CLI, never write the state file directly.
- `theme-doctor`: **141 passed / 1 failed** (up from 140/1 at 12-03's close) — the 1 failure remains the pre-existing, unrelated untracked-file git-clean finding (`vscodium/.local/share/applications/Vampire Survivors.desktop`), explicitly out of scope for this plan per its scope boundary. New baseline for later plans: **141** (142/0 once that stray file is resolved by its owner).
- `theme-parity`: **1897 passed / 0 failed** (up from 1894/0 at 12-03's close) — the 3 new PASS lines are the D-31 byte-identity assertion across the three motion targets.
- Both new gates (`theme-doctor`'s hyprctl readback, `theme-parity`'s byte-identity Layer 4) are proven to fail before being trusted to pass, per this phase's own discipline — neither is a green gate that has never actually been red.
- The live desktop's motion-scale axis and Hyprland source order are proven end-to-end on the real, running compositor — this is the shape (CLI -> state file -> one render entrypoint -> compositor readback) every later plan touching motion in this phase inherits.

---
*Phase: 12-unified-design-token-pipeline*
*Completed: 2026-07-26*

## Self-Check: PASSED

- FOUND: hypr/.config/hypr/scripts/motion-switch.sh
- FOUND: theme-engine/.config/theme-engine/lib/gtk.sh
- FOUND: theme-engine/.config/theme-engine/lib/motion.sh
- FOUND: hypr/.config/hypr/hyprland.conf
- FOUND: hypr/.config/hypr/config/animations.conf
- FOUND: stow.sh
- FOUND: theme-engine/.config/theme-engine/theme-doctor
- FOUND: theme-engine/.config/theme-engine/theme-parity
- FOUND commit: 5f7d03f (Task 1)
- FOUND commit: 51231bc (Task 2)
- FOUND commit: 5a676e6 (Task 3)
