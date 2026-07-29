---
phase: 14-dashboard-drawer
plan: 02
subsystem: theme-engine
tags: [material-symbols, fonttools, qml6, quickshell, motion-tokens, weather, json-adapter, aur, install-sh]

requires:
  - phase: 12-unified-design-token-pipeline
    provides: "motion.json single-source pipeline (lib/motion.sh), Motion.qml singleton, motion-lint, contract.json engine_owned_files array"
  - phase: 13.1-hyprland-lua-config-migration
    provides: "Lua-rendered hyprland-tokens.lua as the sole Hyprland motion render target"
provides:
  - "ttf-material-symbols-variable-git registered in install.sh's AUR_PKGS, installed, and covered by the existing hard-fail verify_packages loop"
  - "Live-measured verdict (fill-axis-renders) that Qt 6.11.1 drives this font's FILL variable axis, closing 14-RESEARCH.md assumption A3"
  - "The stagger-offset semantic motion token, resolving as Motion.staggerOffsetDuration/staggerOffsetEasing in a live Quickshell process, riding the shared motion-scale axis"
  - "A seeded, flat, city-level, metric ~/.local/state/theme/weather.json state file, plus both weather filenames registered in contract.json's engine_owned_files"
affects: [14-04-icon-chips, 14-07-weather-widget, 14-09-cascade-render-gate, 15-audio-connectivity-panels, 16-workspace-overview]

tech-stack:
  added: []
  patterns:
    - "AUR package-legitimacy human checkpoint comment block (D-16/D-33/D-28 lineage) — name the decision, the checkpoint approval and its date, directly above the array entry"
    - "Throwaway mktemp -d QML proof scenes (qml6 grabToImage, quickshell -p singleton probe) for settling a live-rendering question without committing a fixture"
    - "Seed-only-when-absent flat-JSON state file idiom (stow.sh), reused unchanged from motion-scale/waybar-visibility.css/gaming-mode"

key-files:
  created: []
  modified:
    - install.sh
    - theme-engine/.config/theme-engine/motion.json
    - quickshell/.config/quickshell/modules/Motion.qml
    - stow.sh
    - theme-engine/.config/theme-engine/contract.json

key-decisions:
  - "T-14-SC / 14-RESEARCH.md A1 closed: human read the live AUR page and selected approve-aur (2026-07-29) — package base material-symbols-git checks out on all five criteria (votes/popularity, maintainer, out-of-date flag, PKGBUILD source=, package() scope)"
  - "A3 closed live: fill-axis-renders — Qt 6.11.1 actually drives font.variableAxes' FILL value on Material Symbols Rounded, proven with a non-zero-alpha-guarded, negative-control-carrying pixel comparison"
  - "D-21's stagger-offset token appended as _pairNames' FOURTH entry (never inserted) to avoid re-pointing the three pre-existing positional pairs[0..2] aliases — verified unchanged live"
  - "Weather state schema is five flat top-level scalars (D-31, Pitfall 5) — no nested location/units object, because JsonAdapter binds top-level keys only"
  - "Seeded coordinates (30.04/31.24) are the Cairo city centroid at two decimal places, derived from this host's Africa/Cairo timezone — deliberately NOT home coordinates (D-30)"

requirements-completed: [DASH-06]

coverage:
  - id: D1
    description: "Material Symbols Rounded AUR package installed and registered in install.sh behind an attested human legitimacy checkpoint"
    requirement: DASH-06
    verification:
      - kind: other
        ref: "pacman -Q ttf-material-symbols-variable-git; grep -vE '^\\s*#' install.sh | grep -c ttf-material-symbols-variable-git"
        status: pass
    human_judgment: false
  - id: D2
    description: "FILL variable-font axis proven to render on this Qt 6.11.1 build via a pixel comparison carrying its own negative control"
    requirement: DASH-06
    verification:
      - kind: other
        ref: "compare -metric AE between throwaway qml6 grabToImage FILL-0/FILL-1 PNGs (2255.77, non-zero) and FILL-0/FILL-0 PNGs (0, identical); both PNGs asserted non-zero mean alpha first"
        status: pass
    human_judgment: true
    rationale: "Acceptance criteria require a human-eye confirmation that the FILL-1 PNG reads as a solid filled glyph and FILL-0 as the outlined form, not merely that the pixel metric differs — recorded visually in this SUMMARY, but the judgment of 'looks like the intended lit/unlit language' is inherently a look, not a metric."
  - id: D3
    description: "stagger-offset semantic motion token defined, lint-visible, and resolving live in Quickshell without disturbing the three pre-existing aliases"
    requirement: DASH-06
    verification:
      - kind: other
        ref: "jq assertions against motion.json/rendered motion.json; motion-lint (57/0); throwaway quickshell -p singleton probe printing all 8 alias values"
        status: pass
    human_judgment: false
  - id: D4
    description: "Weather location/units state axis seeded flat and metric, both weather filenames registered so a theme-apply cannot destroy them"
    requirement: DASH-06
    verification:
      - kind: other
        ref: "jq schema assertions on weather.json; theme-doctor state-manifest gate (pass, then proven to fail on an unregistered file, then pass again); hand-edited lat survived a real theme-apply and a full stow.sh re-run"
        status: pass
    human_judgment: false

duration: multi-session (continuation, checkpoint-gated)
completed: 2026-07-29
status: complete
---

# Phase 14 Plan 02: Icon Font, Stagger Token & Weather State Axis Summary

**Material Symbols Rounded installed behind an attested AUR legitimacy checkpoint with its FILL axis measured live, a new `stagger-offset` motion token wired end-to-end through `Motion.qml`, and a flat, city-level, metric weather state file seeded and contract-registered.**

## Performance

- **Duration:** multi-session — Task 1's blocking human-verify checkpoint (`approve-aur`) and Task 2's install-step human-action checkpoint (`paru` run by the operator, agent sudo had no TTY) were both resolved before this continuation began; this session executed Task 2's remaining implementation plus Tasks 3-4.
- **Completed:** 2026-07-29T12:39:52Z
- **Tasks:** 4 (1 approved via checkpoint with no artifact/commit; 2-4 executed and committed)
- **Files modified:** 5

## Accomplishments

- `ttf-material-symbols-variable-git` registered in `install.sh`'s `AUR_PKGS` behind a D-28 comment naming the checkpoint approval and its evidence; no new verify step needed since `VERIFY_PKGS` already splats `AUR_PKGS` wholesale into the hard-fail loop.
- 14-RESEARCH.md assumption A3 closed live: Qt 6.11.1 genuinely drives Material Symbols Rounded's `FILL` variable axis, proven with a throwaway `qml6`/`grabToImage` pixel comparison that carries its own negative control.
- D-21's `stagger-offset` semantic motion token defined in `motion.json`, wired through `Motion.qml`'s `_pairNames` as a fourth, appended entry, and proven to resolve in a live `quickshell -p` process without re-pointing the three pre-existing positional aliases.
- `~/.local/state/theme/weather.json` seeded with five flat top-level scalars (Cairo city centroid, metric units) and both weather filenames registered in `contract.json`'s `engine_owned_files`, closing the exact "seeded but unregistered" bug class Phase 12's D-29 comment records recurring eight times.

## Task Commits

1. **Task 1: Package-legitimacy gate — `ttf-material-symbols-variable-git` (T-14-SC)** — resolved via checkpoint (`approve-aur`, 2026-07-29). No commit — this is a gate, not an edit. See Checkpoint Resolutions below for the recorded evidence.
2. **Task 2: Install Material Symbols Rounded, register it in `install.sh`, settle the FILL-axis question (D-28, A3)** — `0243b28` (feat)
3. **Task 3: The `stagger-offset` semantic token, wired through `Motion.qml` (D-21)** — `aa52b87` (feat)
4. **Task 4: Seed the weather location/units state axis and register both weather files (D-30/D-31)** — `34ca60a` (feat)

**Plan metadata:** committed alongside this SUMMARY (see final commit below).

## Checkpoint Resolutions

### Task 1 — `checkpoint:human-verify`, `gate="blocking-human"` — resolved `approve-aur`

The human read the live AUR page for `ttf-material-symbols-variable-git` (package base `material-symbols-git`) directly in a browser and confirmed all five reject criteria did not apply:

1. **Votes/popularity** — 7 votes, 1.34 popularity. Non-trivial for a font-wrapper package.
2. **Maintainer/last-updated** — maintainer `moetayuko`, co-maintainer `xiota`; not orphaned.
3. **Out-of-date flag** — not set.
4. **PKGBUILD `source=`** — pulls TTFs directly from Google's own `github.com/google/material-design-icons` repository (raw master).
5. **`package()` function** — only runs `install -Dm644` of `.ttf` files into `/usr/share/fonts/ttf-material-symbols-variable/`. No `curl`, `chmod +x`, systemd unit, hook, or out-of-tree write. The only `curl` anywhere in the PKGBUILD is `_update_version()` hitting `api.github.com` read-only — the standard `-git` autoupdate pattern. `sha256sums=('SKIP')` is expected for a `-git` package tracking master.

License Apache-2.0. Package `Provides`/`Conflicts` `ttf-material-symbols-variable` (this is a split package of base `material-symbols-git`). Approval date: **2026-07-29**. This replaces 14-RESEARCH.md's `[SUS — unverified]` verdict with an attested one — no automated AUR registry check exists (`gsd-tools query package-legitimacy check` covers npm/PyPI/crates only), so this attestation is human-only per T-14-SC's threat-register disposition.

### Task 2 install step — `checkpoint:human-action` — resolved by operator running the install directly

The AUR helper install (`paru -Sy --needed --noconfirm ttf-material-symbols-variable-git`) was run by the human operator because agent sudo had no interactive TTY in this session (the exact failure mode STATE.md's Phase 11 blocker already documents). Verified before this continuation began:

- `pacman -Q ttf-material-symbols-variable-git` → `4.0.0.r166.g528cb964-1`
- `fc-list` showed `Material Symbols Rounded` faces at `/usr/share/fonts/ttf-material-symbols-variable/MaterialSymbolsRounded[FILL,GRAD,opsz,wght].ttf`

This continuation did not re-run the install — it proceeded directly to registering the package in `install.sh` and settling the FILL-axis question.

## Files Created/Modified

- `install.sh` — added `ttf-material-symbols-variable-git` to `AUR_PKGS`, in its own labelled group directly after the AGS media-applet entry, with a comment naming D-28, the checkpoint approval date, and the evidence summary (votes, maintainer, source, package scope).
- `theme-engine/.config/theme-engine/motion.json` — added `semantic["stagger-offset"]` referencing existing `short1`/`standard` names; no literal.
- `quickshell/.config/quickshell/modules/Motion.qml` — appended `"stagger-offset"` as `_pairNames`' fourth entry (with a comment recording why append order is load-bearing) and added `staggerOffsetDuration`/`staggerOffsetEasing` aliases reading `pairs[3]`.
- `stow.sh` — added a seed-only-when-absent block for `~/.local/state/theme/weather.json`, directly after the motion-scale seed, with a comment explaining the flat-schema (Pitfall 5), city-centroid (D-30), and metric (D-31) choices.
- `theme-engine/.config/theme-engine/contract.json` — appended `weather.json` and `weather-cache.json` to `engine_owned_files`.

## Decisions Made

- **A3 verdict: `fill-axis-renders`.** A throwaway `Window`-rooted QML scene (root must be a `Window`, not a bare `Item` — a bare-`Item` root's `grabToImage` silently never fires with "item is not attached to a window" and hangs forever; this was found live during this task, see Deviations) rendered the `favorite` glyph at FILL 0 and FILL 1 under `qml6 --platform offscreen`. Mean alpha: FILL-0 = 0.159578, FILL-1 = 0.364275 (both non-zero, ruling out a vacuous empty-grab pass before any comparison). `compare -metric AE`: FILL-0 vs FILL-1 = 2255.77 (differ, axis renders); FILL-0 vs a second FILL-0 = 0 (identical, the negative control holds — the comparison is sensitive to the axis, not render nondeterminism). A visual check (enlarged, black-flattened PNGs) confirms FILL-0 renders an outlined heart and FILL-1 a solid filled heart — the exact D-25/D-26 lit/unlit language, not an unrelated artefact.
- **`stagger-offset` placed in `semantic`, never `indicators`** — `motion-lint`'s `load_qml_defs()` reads allowed `Motion.*` names from `semantic` only; an `indicators`-housed token would be a dangling CHECK-A reference the moment `Motion.qml` referenced it.
- **`_pairNames` entry appended, not inserted** — the three pre-existing aliases (`standardDuration`/`emphasizedInDuration`/`emphasizedOutDuration`) read `pairs` positionally at indices 0/1/2; inserting anywhere but the end would silently re-point them. Verified unchanged (200/300/150 and their curves) via a live `quickshell -p` probe before and would-be after.
- **Weather coordinates are the Cairo city centroid (30.04/31.24), not home coordinates** — derived from the host's `Africa/Cairo` system timezone, at two decimal places (city-level, not street-level), per D-30. Refinement is a hand-edit to the never-git-tracked state file, not a code change.
- **`weather-cache.json` registered pre-emptively** — nothing creates it yet (14-07 will, at its first successful fetch), but registering it now means that future write does not turn `theme-doctor` red mid-plan.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Bare `Item` root scene hangs forever on `grabToImage` under `qml6`**
- **Found during:** Task 2 (A3 FILL-axis proof)
- **Issue:** The plan's literal instruction was a `128x128 root Item containing one Text`. Running that under `qml6 --platform offscreen` produced no output and hung until the `timeout` killed it (exit 124), with no error printed to stdout/stderr — only `journalctl --user` revealed the real diagnostic: `QML Text: grabToImage: item is not attached to a window`. `grabToImage`'s callback silently never fires when the target item has no window ancestor, so `Qt.quit()` inside that callback never runs.
- **Fix:** Rewrote the scene with `Window { visible: true; ... }` as the root (via `import QtQuick.Window`), containing the same `Text` item, deferring the `grabToImage` call to `Qt.callLater()` inside `Component.onCompleted` (so the window has a chance to actually attach before the grab is requested). All three renders (FILL 0, FILL 1, FILL 0 again) then completed and exited 0 with valid PNGs.
- **Files modified:** none in the repo — this was a throwaway `mktemp -d` proof scene, never committed, per the plan's own instruction.
- **Verification:** All three PNGs produced, non-zero mean alpha confirmed on both distinct renders, `compare -metric AE` gave the expected differ/identical pair.
- **Committed in:** N/A (not a repo change) — recorded here as a durable finding for any future `qml6 grabToImage` proof in this project: **the root must be a `Window`, never a bare `Item`, or the grab silently never completes.**

---

**Total deviations:** 1 auto-fixed (1 Rule-1 bug in a throwaway proof harness, not a repo file)
**Impact on plan:** No scope creep — the fix was entirely inside the disposable `mktemp -d` scene the plan itself specifies must not be committed. No repo file was affected by this deviation.

## Issues Encountered

- `stow.sh`'s full re-run (required by Task 4's idempotency proof) surfaced two pre-existing, unrelated conditions: a VSCodium `settings.json` stow conflict (host already has a non-symlinked file at that path — pre-existing, unrelated to this plan's scope) and a `chsh` failure from a missing sudo TTY (same class of condition as Task 2's install-step checkpoint, pre-existing and out of this plan's scope). Neither affected the weather-seed proof; both are logged here per the scope-boundary rule (out-of-scope discoveries noted, not fixed) rather than silently ignored.

## User Setup Required

None — no external service configuration required. (The AUR install step's human-action checkpoint was already resolved before this continuation began; see Checkpoint Resolutions above.)

## Next Phase Readiness

- 14-04 (icon chips) has an exact `font.family` string (`Material Symbols Rounded`) and a live-measured FILL-axis verdict (`fill-axis-renders`) to design its lit/unlit chip language against, rather than a hope.
- 14-09 (cascade render gate) can consume `Motion.staggerOffsetDuration`/`staggerOffsetEasing` directly — the token is defined, lint-visible, resolves live, and already collapses under `reduced`/`off` through the existing motion-scale plumbing (no new QML branching needed).
- 14-07 (weather widget) finds a seeded, flat, city-level, metric `weather.json` and a registered (but not yet created) `weather-cache.json` filename — it does not need to invent either the schema or the contract registration.
- All core regression gates are green: `theme-doctor` 208/0, `theme-parity` 2608/0, `motion-lint` 57/0.
- No blockers carried forward from this plan.

---
*Phase: 14-dashboard-drawer*
*Completed: 2026-07-29*

## Self-Check: PASSED

All 5 modified files and the SUMMARY.md itself confirmed present on disk; all 3 task commit hashes (`0243b28`, `aa52b87`, `34ca60a`) confirmed present in `git log --oneline --all`.
