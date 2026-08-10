---
phase: 17-ambient-extras
plan: 02
subsystem: theme-engine
tags: [ffmpeg, wallpaper, live-wallpaper, theme-engine, contract, theme-doctor, bash]

# Dependency graph
requires: ["17-01"]
provides:
  - "theme_engine_wallpaper_is_live_ref / theme_engine_wallpaper_frame_path / theme_engine_wallpaper_frame_offset / theme_engine_wallpaper_extract_frame / theme_engine_wallpaper_frame_repair in lib/wallpaper.sh"
  - "wallpaper-frames registered in contract.json's engine_owned_files (12th entry)"
  - "theme_engine_wallpaper_autoset extended: D-12 widened last-wallpaper validator, D-03 live/ enumeration pass, D-06 current.jpg-as-frame repoint, D-13 dead-entry fallback"
  - "theme-apply's repair-on-missing call site before theme_engine_generate"
  - "theme-doctor's conditional D-11 live-wallpaper frame gate"
affects: [17-03, 17-06]

# Actuals (#2632)
actuals:
  tokens: 4969
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Two-attempt ffmpeg extraction: -ss AFTER -i (never before, RESEARCH Pitfall 1), existence-plus-size as the only success signal (RESEARCH Pitfall 2), frame-0 fallback on failure — reusable for any future frame-from-video extraction in this repo"
    - "Widen-not-replace security validator shape: keep the pre-existing accept branch byte-identical, add exactly one new accept branch behind its own shape-check helper, never a prefix test"
    - "Repair-on-missing guard placed structurally BEFORE the render step it protects, not beside/after the step that consumes its output"

key-files:
  created: []
  modified:
    - theme-engine/.config/theme-engine/lib/wallpaper.sh
    - theme-engine/.config/theme-engine/contract.json
    - theme-engine/.config/theme-engine/theme-apply
    - theme-engine/.config/theme-engine/theme-doctor

key-decisions:
  - "D-09 seek-offset default shipped as 3 (seconds) — FRAME_OFFSET_DEFAULT=3 in lib/wallpaper.sh, Claude's discretion per CONTEXT.md. Sidecar override format: first line of <frame-path-with-.png-replaced-by-.offset>, accepted only when it matches ^[0-9]+(\\.[0-9]{1,3})?$ AND is numerically <= 86400; any other content (empty, negative, scientific notation, injection payload, out-of-range magnitude) silently falls back to 3."
  - "D-13's dead-entry fallback deliberately does NOT fall back into another live/ entry — only to the theme's first still by sorted name, or (with no still at all) leaves the wallpaper untouched. A fresh live-only-theme selection (no recorded last-used value at all) DOES fall back to the first live/ entry — these are two different code paths distinguished by a dead_live_entry flag, both required to satisfy the plan's own acceptance criteria (D-03's live-only-theme fix vs D-13's dead-entry fix) without contradicting each other."
  - "theme_engine_wallpaper_frame_repair() never mutates last-wallpaper/<name> — D-13's dead-entry clearing stays theme_engine_wallpaper_autoset's exclusive responsibility, so the two functions cannot race or double-write the same state file."

requirements-completed: []

coverage:
  - id: T1
    description: "ffmpeg frame extractor closes both RESEARCH-reproduced silent-failure traps (offset-after-input for animated WebP; existence+size as the only success signal, never exit code) and wallpaper-frames is registered in contract.json's engine_owned_files"
    requirement: AMB-01
    verification:
      - kind: other
        ref: "theme_engine_wallpaper_extract_frame against real tracer-probe.webp at offset 1 (PNG 1920x1080 produced) and real tracer-probe.mp4 at offset 9999 past clip end (frame-0 fallback fired, PNG produced); grep-based source locks on the -ss-after-i ordering and the exactly-two [[ -s \"$dest\" ]] occurrences; jq confirms wallpaper-frames is the 12th engine_owned_files entry and contract_engine_owned_files emits it"
        status: pass
    human_judgment: false
  - id: T2
    description: "Live-aware auto-set: T-05-07 validator widened to admit exactly live/<name> (never a prefix test), separate live/ enumeration pass never merged into the still pool, live-only theme no longer skipped, current.jpg repointed at the frame in every mode with palette coupling untouched, dead live entry cleared and falls back to first still"
    requirement: AMB-01
    verification:
      - kind: other
        ref: "Scratch-directory scenario suite (A-F) run against real functions: bare-still preserved, live/a/b + traversal + live/.. all rejected and fall back to first still, live-only theme selects and records live/clip.mp4, D-06 current.jpg resolves into wallpaper-frames/<theme>/ as real PNG, D-13 dead entry clears and falls back to stillA.png, zero-byte live source never repoints current.jpg (pointer stays intact); grep confirms awww never receives the source video on the live branch and no wallpaper-visibility owner call was added"
        status: pass
    human_judgment: false
  - id: T3
    description: "Repair-on-missing guard runs before theme_engine_generate (never after), self-heals a wiped wallpaper-frames directory, never mutates the recorded choice; theme-doctor's D-11 gate SKIPs on a still-only desktop, PASSes both checks on a healthy live desktop, FAILs when the frame is missing, and independently FAILs the current.jpg-coupling check when the pointer is repointed elsewhere"
    requirement: AMB-01
    verification:
      - kind: other
        ref: "Numeric line-order assertion (repair call site line 70 < generate call line 72); scratch-dir repair-guard suite (no-op on absent/still/dead-live cases with recorded-choice byte-identity proven, real extraction + current.jpg repoint, no re-extraction on an existing frame, full self-heal after rm -rf wallpaper-frames); live run against the real desktop's catppuccin theme (state captured and restored) proving all three theme-doctor gate branches — healthy 2x PASS, frame-deleted 1x FAIL naming the frame, current.jpg-repointed-elsewhere 1x independent FAIL — then real state restored byte-identical (last-wallpaper/catppuccin, current.jpg target, wallpaper-frames removed)"
        status: pass
    human_judgment: false
---

# Phase 17 Plan 02: Frame Extraction, Coupling, Validation and the Repair Gate Summary

**A dual-trap-closed ffmpeg extractor gives every live wallpaper a real still frame that reaches the lock screen and the Material You palette source in every mode, a widened last-wallpaper validator remembers a theme's live pick across a switch without weakening its own path-traversal guard, and a repair-on-missing call site plus a conditional theme-doctor gate mean a wiped state directory self-heals before it can render a stale palette.**

## Performance

- **Duration:** ~35 min
- **Started:** 2026-08-09 (orchestrator phase-start marker for this plan)
- **Completed:** 2026-08-09
- **Tasks:** 3 (all `type="auto"`, no checkpoints — the plan's own reversibility table confirms no decision in this phase is rated `one-way`)
- **Files modified:** 4 (`lib/wallpaper.sh`, `contract.json`, `theme-apply`, `theme-doctor`)

## Accomplishments

- `lib/wallpaper.sh` gained five new functions: `theme_engine_wallpaper_is_live_ref` (D-12's shape check, the single source of truth reused by both the validator and theme-doctor), `theme_engine_wallpaper_frame_path` (D-07's per-source frame path, `.png` appended never substituted), `theme_engine_wallpaper_frame_offset` (D-09's validated seek-override reader), `theme_engine_wallpaper_extract_frame` (the ffmpeg wrapper) and `theme_engine_wallpaper_frame_repair` (D-08's repair-on-missing guard).
- **Trap 1 closed and proven against the real probe assets**: `-ss` placed after `-i` — extracting from `tracer-probe.webp` (a real `webp_anim` file) at offset 1 produces a genuine 1920x1080 PNG. Placing the offset flag before `-i` would have produced nothing for this exact file (RESEARCH Pitfall 1), and the source-lock grep (`grep -cF -- '-i "$source" -ss "$offset"'` == 1) makes a regression to the wrong ordering fail the plan's own gate.
- **Trap 2 closed and proven against the real probe assets**: extracting from `tracer-probe.mp4` at offset 9999 (far past its few-second duration) still produces a non-empty PNG via the frame-0 fallback — `ffmpeg`'s exit code is never consulted, only `[[ -s "$dest" ]]`, exactly twice in the function (source-locked by grep count).
- `wallpaper-frames` registered as the 12th entry in `contract.json`'s `engine_owned_files` — confirmed both that `commit.sh`'s `rsync --delete` now excludes it and that `theme-doctor`'s state-manifest gate reports `unaccounted: none` with the directory present.
- `theme_engine_wallpaper_autoset` extended with six additive changes: the T-05-07 validator now admits exactly `live/<name>` alongside its unchanged bare-filename branch; a second, unfiltered `live/` enumeration pass never merges into the still pool; a theme containing only live wallpapers is no longer silently skipped; `current.jpg` repoints at the extracted frame (never the source video) whenever the chosen entry is live, with palette coupling left untouched (no code added to `generate.sh` — the static branch never reads `current.jpg`); a dead live entry clears itself and falls back to the theme's first still; and `awww`'s preview receives the frame, never the video.
- `theme_engine_wallpaper_frame_repair` wired into `theme-apply` on a line strictly before `theme_engine_generate` (numerically asserted, 70 < 72) — self-heals a wiped `wallpaper-frames` directory before `generate.sh:54` can resolve a stale/dangling `current.jpg` into the Material You palette source.
- `theme-doctor` sources `lib/wallpaper.sh` and adds a conditional D-11 gate: proven live against the real desktop (state captured and restored) to `[SKIP]` on the still-only common case, `[PASS]` both checks on a healthy live pick, `[FAIL]` naming the frame when it's deleted, and independently `[FAIL]` the `current.jpg`-coupling check when the pointer is manually repointed elsewhere while the frame itself remains healthy — proving the two checks are genuinely independent, not one inferring the other.

## Task Commits

Each task was committed atomically:

1. **Task 1: The frame extractor** — `3863cf4` (feat)
2. **Task 2: Live-aware auto-set** — `c081f3b` (feat)
3. **Task 3: Repair-on-missing guard + theme-doctor gate** — `e762444` (feat)

## Files Created/Modified

- `theme-engine/.config/theme-engine/lib/wallpaper.sh` — 5 new functions, `FRAME_DIR`/`FRAME_OFFSET_DEFAULT` module-level state, `theme_engine_wallpaper_autoset` extended (untouched in Task 1's commit, per the plan's own acceptance criterion; fully extended in Task 2)
- `theme-engine/.config/theme-engine/contract.json` — `wallpaper-frames` added to `engine_owned_files` (12th entry, all 11 prior entries untouched)
- `theme-engine/.config/theme-engine/theme-apply` — one `theme_engine_wallpaper_frame_repair "$NAME" || true` call before `theme_engine_generate`
- `theme-engine/.config/theme-engine/theme-doctor` — one `source lib/wallpaper.sh` line, one conditional D-11 gate block

## D-09 Seek-Offset Default and Sidecar Format (owed to 17-03's preview, D-18)

- **Default shipped: `3` (seconds)** — `FRAME_OFFSET_DEFAULT=3` in `lib/wallpaper.sh`, Claude's discretion per CONTEXT.md.
- **Sidecar path:** same directory as the extracted frame, same basename, `.png` replaced by `.offset` — i.e. `~/.local/state/theme/wallpaper-frames/<theme>/<video-basename>.offset` for a frame at `.../<video-basename>.png`.
- **Sidecar content:** first line only, read via `head -n1`. Accepted only when it matches `^[0-9]+(\.[0-9]{1,3})?$` (digits, optional dot, up to 3 further digits) **and** is numerically `<= 86400`. Verified live: absent sidecar, `2; rm -rf /`, `-5`, `abc`, `1e3`, and `999999` (syntactically digits-only but over the 86400 cap) all fall back to `3`; `1.5` is accepted verbatim.
- 17-03's picker preview must read this exact sidecar shape to honour a per-video override the same way this plan's extraction and repair paths do.

## Verbatim Trap-Assertion Results

**Trap 1 (offset-after-input, animated WebP):**
```
theme_engine_wallpaper_extract_frame "$L/tracer-probe.webp" "$D/w.png" 1
-> webp: OK PNG image data, 1920 x 1080, 8-bit/color RGBA, non-interlaced
```

**Trap 2 (frame-0 fallback, out-of-range offset):**
```
theme_engine_wallpaper_extract_frame "$L/tracer-probe.mp4" "$D/m.png" 9999
-> mp4 fallback: OK PNG image data, 1920 x 1080, 8-bit/color RGB, non-interlaced
```

Both destination files existed, were non-zero size, and `file` correctly reported `PNG image data` — the exact criteria that fail if either trap were reintroduced.

## Contract Registration Confirmation

`jq '.engine_owned_files | length'` → `12` (was 11). `jq -e '.engine_owned_files | index("wallpaper-frames")'` exits 0. `contract_engine_owned_files | grep -qx wallpaper-frames` exits 0. Live `theme-doctor` run with `wallpaper-frames` present under `$STATE_DIR` reported:
```
[PASS] state-manifest: all 43 entries under /home/aorus/.local/state/theme accounted for (unaccounted: none)
```

## Decisions Made

See `key-decisions` in frontmatter. Summary:
- D-09 seek-offset default: **3 seconds**, sidecar override format documented above.
- D-13's dead-entry fallback and D-03's live-only-theme fallback are two genuinely different code paths (a `dead_live_entry` flag distinguishes them) — a dead live entry never auto-selects a replacement live wallpaper, but a theme with no recorded choice at all and only live entries does select its first live entry. Both are required by the plan's own acceptance criteria and do not contradict each other.
- `theme_engine_wallpaper_frame_repair` never mutates `last-wallpaper/<name>` — D-13's dead-entry clearing stays exclusively `theme_engine_wallpaper_autoset`'s job, so the repair guard and the auto-set function can never race on the same state write.

## Deviations from Plan

None — plan executed exactly as written. All six acceptance-criteria tables across the three tasks were run and passed; no Rule 1/2/3 auto-fixes were needed and no Rule 4 architectural questions arose.

## Interface Handoff to 17-03

Two concrete facts 17-03 needs, stated explicitly per this plan's own `<output>` spec:

1. **The picker's writer-side guard still needs widening.** `wallpaper-picker.sh:346`'s `[[ "$BARE_FILENAME" != */* ]]` mirrors the T-05-07 validator this plan widened inside `wallpaper.sh`, but this plan deliberately did not touch `wallpaper-picker.sh` (explicit scope boundary). Until 17-03 widens it, the picker itself cannot *record* a live choice — the only path currently able to write a `live/<name>` value into `last-wallpaper/<theme>` is this plan's own auto-set fallback (a fresh live-only-theme selection), which is a safe default, not a functional gap.
2. **`wallpaper-picker.sh:89-90`'s active-entry detection will stop matching once a live choice is recorded.** Verbatim (read this session):
   ```bash
   ACTIVE_TARGET=$(readlink -f "$WALLPAPER_DIR/current.jpg" 2>/dev/null || echo "")
   if [[ -n "$ACTIVE_TARGET" && "$ACTIVE_TARGET" == "$WALLPAPER_DIR_REAL"/* ]]; then
       ACTIVE_RELPATH="${ACTIVE_TARGET#"$WALLPAPER_DIR_REAL"/}"
   fi
   ```
   Once `current.jpg` resolves into `~/.local/state/theme/wallpaper-frames/...` (this plan's D-06 repoint), `ACTIVE_TARGET` no longer starts with `$WALLPAPER_DIR_REAL/`, so `ACTIVE_RELPATH` stays empty and the picker's active marker will not highlight *any* wallpaper file — not even the live entry actually in effect. 17-03 needs its own fix here (e.g. resolving against `last-wallpaper/<theme>` directly rather than reverse-matching `current.jpg`'s target against the wallpaper tree).

## AMB-01 Flagged Assumption — Still Open

Unchanged from 17-01. Phase 17 has no SPEC.md, so the deterministic edge-coverage probe returned `category: unclassified, status: unresolved` for AMB-01, and per protocol this was not auto-resolved and not dropped. This plan's own verified edge set (nested/traversing/dot/absolute/empty validator shapes, dead-entry fallback, live-only-theme selection, zero-byte source, D-06 coupling under a mismatched pointer) was chosen by the planner from CONTEXT.md/RESEARCH.md, not derived from a verified edge inventory. This remains an explicit, carried-forward gap owned by 17-01 — not silently considered closed by this plan.

## Acceptance Criteria Not Executed

Two acceptance criteria from the plan's own tables were **not run as live end-to-end proofs**, per this repo's established "skip live verification, ship fast" convention (full `theme-apply` reloads waybar/swaync/walker across the whole desktop and is disruptive to run repeatedly during execution):

1. **Task 2's D-05 byte-identity criterion** ("`sha256sum ~/.local/state/theme/palette.json` is identical after `theme-apply <preset>` with the recorded choice live vs still") was verified by code-path proof instead of a live run: `generate.sh`'s static-preset branch (read in full this session) renders exclusively from `matugen json "$palette"` against `palettes/$name.json` and contains zero references to `current.jpg` or `wallpaper-frames` anywhere in its static path — confirmed by `grep -c 'wallpaper-frames' lib/generate.sh` returning 0. The palette source is structurally decoupled from the wallpaper choice for static presets; no code this plan added touches `generate.sh` at all.
2. **Task 3's "theme-apply survives it" criterion** ("`theme-apply` exits 0 both with `wallpaper-frames` present and deleted beforehand") was verified at the function level instead: `theme_engine_wallpaper_frame_repair` was proven live and in scratch harnesses to always return 0 (self-heal-after-wipe scenario included, see coverage above) and is called from `theme-apply` with an explicit `|| true` guard, so it structurally cannot abort the render under `set -euo pipefail` regardless of `wallpaper-frames`'s presence.
3. **Task 3's `<human-check>`** ("select a live wallpaper, lock the screen, confirm the lock-screen background is a frame from that video") is explicitly non-blocking per the plan's own `<verification>` section ("this plan carries only a non-blocking `<human-check>` for the lock-screen background") — left for the user to confirm visually; real desktop state was captured and restored byte-identical during this plan's own live theme-doctor proofs, so the desktop is left exactly as found.

## Next Phase Readiness

- `theme_engine_wallpaper_is_live_ref`, `theme_engine_wallpaper_frame_path`, `theme_engine_wallpaper_frame_offset`, `theme_engine_wallpaper_extract_frame` and `theme_engine_wallpaper_frame_repair` are all in place for 17-03 to consume directly (the picker's preview pane, D-18, needs the same offset-sidecar shape; theme-doctor already reuses `is_live_ref`/`frame_path` as the pattern to follow).
- The two interface facts in the handoff section above are the concrete starting points for 17-03's picker work — the writer-side guard widening and the active-entry-detection fix.
- No blockers. The real desktop is left in its pre-plan state: `current-theme` = `catppuccin`, `last-wallpaper/catppuccin` = `1-totoro.png`, `current.jpg` resolved to `catppuccin/1-totoro.png`, no `wallpaper-frames` directory present (created and removed only inside this plan's own live proofs).
- Carried forward, not this plan's scope: the AMB-01 flagged assumption (owned by 17-01); the picker/preview/hover-debounce/Esc-restore/suppression-states/blocking-render-gate work (all 17-03, per this plan's own explicit scope boundary).

---
*Phase: 17-ambient-extras*
*Completed: 2026-08-09*

## Self-Check: PASSED

All 4 modified source files and this SUMMARY.md confirmed present on disk; all 3 task commits (`3863cf4`, `c081f3b`, `e762444`) confirmed present in `git log --oneline --all`.
