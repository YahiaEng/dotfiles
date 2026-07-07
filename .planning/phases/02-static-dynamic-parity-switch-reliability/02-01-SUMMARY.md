---
phase: 02-static-dynamic-parity-switch-reliability
plan: 01
subsystem: theming
tags: [matugen, bash, jq, tomllib, theme-engine, parity, verification-tooling]

requires:
  - phase: 01-root-cause-fix-consolidated-theme-engine
    provides: theme-engine (theme-apply/theme-doctor/lib/generate.sh/lib/commit.sh), the 10-file state-dir output contract, the 6 static palettes
provides:
  - "contract.json — canonical output-contract manifest (10 rendered files, per-file format tag, exempt_keys), single source of truth for theme-doctor and theme-parity"
  - "lib/contract.sh — shared extraction/normalization helper library (contract_files, contract_format, contract_exempt_keys, contract_extract_names, contract_extract_values, contract_normalize_color, contract_wellformed_color)"
  - "theme-parity — rerunnable, render-only CLI proving structure + name-set + semantic-value parity across all 7 render targets (6 static presets + materialyou)"
  - "theme-doctor refactored to read its state-dir file list from contract.json instead of a hardcoded loop"
  - "Empirical proof: static and dynamic modes already produce an identical output contract — zero divergence found"
affects: [02-02, 03-INST-01]

tech-stack:
  added: []
  patterns:
    - "Manifest-driven per-file extraction strategy (contract.json + lib/contract.sh) — one JSON manifest is the single source of truth consumed by two independent tools"
    - "Report-only strict-mode + check() accumulator (set -uo pipefail, no -e) for verification CLIs, vs set -euo pipefail for mutating CLIs — theme-parity copies theme-doctor's shape, not theme-apply's"
    - "Format-normalized color comparison — never compare raw literal color strings across heterogeneous files; always reduce to bare lowercase 6-hex first"

key-files:
  created:
    - theme-engine/.config/theme-engine/contract.json
    - theme-engine/.config/theme-engine/lib/contract.sh
    - theme-engine/.config/theme-engine/theme-parity
  modified:
    - theme-engine/.config/theme-engine/theme-doctor

key-decisions:
  - "contract.json models the output contract as files[] with name/format/exempt_keys, not a flat variable-name list, because the 10 files fall into 6 genuinely different formats (D-30)"
  - "Semantic-value 'no empty slot' rule is only enforced for formats where every declared key is definitionally a color (gtk-css/hypr-vars/kitty-kv/css-literal); toml/json are mixed formats with legitimate non-color string leaves (yazi.toml icon/separator glyphs), so those two formats only validate color-shaped values — template {{...}} leftovers still fail unconditionally in every format"
  - "theme-parity's report-only behavior was verified empirically, not just by strict-mode inspection: corrupting one palette's color value/deleting a referenced key makes matugen hard-fail that single target's render (ResolveError, matching Phase-1's documented matugen behavior), and theme-parity still completes structure/name-set/semantic-value checks for the remaining 6 targets and prints the full summary instead of aborting"
  - "Task 3 gate reached zero divergence on the first genuine run — no palette or template file needed modification; this is recorded as a valid pass per the plan's explicit fallback, not a skipped task"

requirements-completed: [PIPE-04]

coverage:
  - id: D1
    description: "contract.json + lib/contract.sh: canonical output-contract manifest and shared extraction/normalization helpers, consumed by both theme-doctor and theme-parity"
    requirement: "PIPE-04"
    verification:
      - kind: manual_procedural
        ref: "jq -e '.files | length == 10' contract.json; jq -e per-format-set check; contract_files/contract_normalize_color assertions — all run and passed during execution"
        status: pass
    human_judgment: false
  - id: D2
    description: "theme-doctor refactored to source its state-dir file list from contract.json; every other check preserved unchanged"
    requirement: "PIPE-04"
    verification:
      - kind: manual_procedural
        ref: "theme-doctor run before/after refactor compared byte-for-byte: 21 passed/1 failed both times (the 1 FAIL is Phase-1's pre-existing, accepted elephant-provider-parity gap, deferred to Phase 3 INST-01 — confirmed via git stash baseline comparison)"
        status: pass
    human_judgment: false
  - id: D3
    description: "theme-parity — render-only CLI proving structure + name-set + semantic-value parity across all 7 targets (6 static presets + materialyou)"
    requirement: "PIPE-04"
    verification:
      - kind: manual_procedural
        ref: "theme-engine/.config/theme-engine/theme-parity run, all-green: Summary: 217 passed, 0 failed, exit 0; timestamped log at ~/.local/state/theme/logs/theme-parity-20260707T221239Z.log"
        status: pass
      - kind: manual_procedural
        ref: "Report-only behavioral proof: corrupted nord.json's primary color (matugen hard-failed nord's render) and separately deleted nord.json's tertiary_container key (same hard-fail) — in both cases theme-parity still completed all checks for the other 6 targets and printed the full summary (186 passed / 1 failed) instead of aborting early; nord.json restored and confirmed byte-identical to git HEAD afterward"
        status: pass
    human_judgment: false
  - id: D4
    description: "PIPE-04 parity gate: zero divergence found between static presets and matugen dynamic mode across all 7 targets — no Phase-1 palette/template file required a fix"
    requirement: "PIPE-04"
    verification:
      - kind: manual_procedural
        ref: "theme-engine/.config/theme-engine/theme-parity 2>&1 | tail -3 | grep -q '0 failed' — passed"
        status: pass
    human_judgment: false

duration: 25min
completed: 2026-07-07
status: complete
---

# Phase 2 Plan 1: Output-Contract Parity Proof (PIPE-04) Summary

**Built `contract.json` + `lib/contract.sh` as the single source of truth for the 10-file theme output contract, wired `theme-doctor` to read it, and shipped `theme-parity` — a render-only checker that proved all 7 targets (6 static presets + materialyou) already produce byte-for-byte structural, name-set, and semantic-value parity with zero fixes needed.**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-07-07T21:48:00Z (approx.)
- **Completed:** 2026-07-07T22:13:11Z
- **Tasks:** 3 (2 produced commits; Task 3 was a zero-divergence gate run, no files modified)
- **Files modified:** 4 (3 created, 1 modified)

## Accomplishments
- `contract.json`: canonical manifest for the 10 matugen-rendered contract files, each tagged with one of 6 format families (`gtk-css`, `hypr-vars`, `kitty-kv`, `toml`, `json`, `css-literal`) and `hyprland.conf`'s intentional `image` blank exemption
- `lib/contract.sh`: source-only helper library — `contract_files`, `contract_format`, `contract_exempt_keys`, `contract_extract_names`, `contract_extract_values`, `contract_normalize_color`, `contract_wellformed_color` — shared by theme-doctor and theme-parity so the two tools can never drift on the file list (D-30)
- `theme-doctor` refactored: state-dir file-list check now iterates `contract_files()` instead of a hardcoded 10-line loop; every other check (adw-gtk-theme, gsettings, symlinks, stow, walker/elephant health, provider parity) verified byte-identical before/after
- `theme-parity`: new render-only, report-only CLI. Renders all 7 targets to temp dirs (reusing `lib/generate.sh` and `commit.sh`'s exact `$tmp$STATE_DIR` prefix-join), then runs three independent layers per target — structure parity, name-set parity, semantic-value parity — writing a timestamped TSV pass/fail log to `~/.local/state/theme/logs/`
- Empirically proved PIPE-04's parity claim: **zero divergence** between static presets and matugen dynamic mode across all 10 contract files × 7 targets (217 checks, 0 failures) — no Phase-1 palette or template file needed a fix

## Task Commits

Each task was committed atomically:

1. **Task 1: Canonical output-contract manifest + shared extraction/normalization library, consumed by theme-doctor** - `3557f23` (feat)
2. **Task 2: theme-parity — render all 7 targets to temp and prove structure + name-set + semantic-value parity** - `23f15e5` (feat)
3. **Task 3: Run theme-parity, fix any divergence in Phase-1 templates/palettes it surfaces (D-40), reach all-green** - no commit (zero divergence found; see below)

**Plan metadata:** (this SUMMARY's commit)

## Files Created/Modified
- `theme-engine/.config/theme-engine/contract.json` - canonical output-contract manifest (10 files, format tags, exempt_keys)
- `theme-engine/.config/theme-engine/lib/contract.sh` - shared extraction/normalization helper library
- `theme-engine/.config/theme-engine/theme-parity` - render-only structure/name-set/semantic-value parity checker
- `theme-engine/.config/theme-engine/theme-doctor` - state-dir file-list check now reads from contract.json

## Decisions Made
- contract.json models the contract as a `files[]` array with per-file `format`/`exempt_keys`, not a flat variable-name list — the 10 files span 6 genuinely different syntaxes (Pattern 1), so a manifest without a format field couldn't drive correct extraction.
- The "no empty slot" semantic rule is format-conditional: enforced for `gtk-css`/`hypr-vars`/`kitty-kv`/`css-literal` (every declared key in those formats IS a color by the template's own convention), but for `toml`/`json` (mixed formats) only color-shaped values are validated — `yazi.toml` legitimately has empty icon/separator glyph fields (`icon_file = ""`, `separator_open = ""`) that are not part of the color contract at all. This was discovered as a false-positive during Task 2's first run (8 spurious FAILs on identical, non-divergent yazi.toml fields across all 7 targets) and fixed in the tool before Task 2 was committed — see Deviations.
- `{{...}}` template-leftover detection runs unconditionally in every format, regardless of the emptiness-rule's format gating, since a literal double-brace leftover is unambiguously a defect in any context.
- Task 3's gate run found zero divergence on the very first genuine (non-corrupted) run — no palette/template fix was needed. Recorded as a valid pass per the plan's explicit "if theme-parity reports zero failures on the first run... that is a valid, expected outcome" clause, not a skipped task.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed a false-positive in theme-parity's own semantic-value emptiness check**
- **Found during:** Task 2 (first theme-parity run against real, uncorrupted palette data)
- **Issue:** The initial semantic-value layer flagged 8 keys per target (`status.separator_open`, `status.separator_close`, `cmp.icon_file`, `cmp.icon_folder`, `cmp.icon_command`, `notify.icon_info`, `notify.icon_warn`, `notify.icon_error` in `yazi.toml`) as "empty non-exempt value" failures on every single one of the 7 targets — a blanket rule treating every empty string leaf in mixed toml/json formats as a violated color slot, when these are legitimate non-color icon/separator glyph fields that are empty by design in the source template (`matugen/.config/matugen/templates/yazi-theme.toml`), identical and non-divergent across all 7 renders.
- **Fix:** Made the "no empty slot" rule format-conditional: enforced only for formats where every declared key is definitionally a color (`gtk-css`/`hypr-vars`/`kitty-kv`/`css-literal`); for `toml`/`json` (mixed formats), only values that already look like a color (hex/rgba pattern) are validated for well-formedness, and the "empty" check is skipped for those two formats. `{{...}}` template-leftover detection still runs unconditionally for all formats.
- **Files modified:** theme-engine/.config/theme-engine/theme-parity (before its first commit — no separate fix commit needed)
- **Verification:** Re-ran theme-parity: 217 passed, 0 failed (previously 210 passed, 7 failed). Confirmed the fix does not mask real defects — matugen's actual failure mode for a broken/missing color reference is a hard `ResolveError` (whole-render failure, caught by the structure layer), not a silently-emitted empty string, per Phase-1's documented matugen 4.1.0 behavior and this plan's own behavioral corruption test.
- **Committed in:** 23f15e5 (Task 2 commit — fix was applied before commit, so no separate fix commit exists)

---

**Total deviations:** 1 auto-fixed (1 bug in the new tool itself, not in Phase-1 code).
**Impact on plan:** No scope creep — the fix corrected the new verification tool's own logic so it accurately distinguishes real color-contract violations from legitimate non-color string fields. No Phase-1 palette or template file was touched.

## Issues Encountered
- theme-doctor's overall exit code is 1, not 0, both before and after this plan's refactor — the single FAIL is a pre-existing, already-accepted gap (`elephant listproviders` missing `files`/`menus`/`providerlist`/`runner`/`websearch` providers), explicitly deferred to Phase 3's INST-01 verification loop per user sign-off (documented in `.planning/STATE.md`'s decision log from Phase 1). Confirmed via `git stash` that this is byte-identical before and after this plan's changes (same 21 passed / 1 failed both times) — not a regression introduced here, and out of this phase's scope to fix (phase boundary explicitly excludes install.sh/elephant-provider work, owned by Phase 3 INST-01). The plan's Task 1 acceptance criterion wording ("theme-doctor exits 0") describes the intended clean-baseline case; this note documents the one already-known exception.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- PIPE-04's parity half is fully proven: `contract.json` + `lib/contract.sh` + `theme-parity` are all-green, keeper scripts stowed in `theme-engine/.config/theme-engine/` alongside `theme-doctor`, ready for Phase 3's fresh-VM verification reuse (D-42).
- Plan 02-02 (PIPE-06, the switch-reliability stress test) can now build the stress-test script's per-switch sentinel-color check directly on top of `lib/contract.sh`'s `contract_normalize_color`/`contract_wellformed_color` helpers, avoiding a second, potentially-drifting implementation of the same format-normalization logic (RESEARCH Open Question 2's recommendation).
- No blockers. The one known gap (elephant provider parity, theme-doctor's persistent single FAIL) remains explicitly deferred to Phase 3 INST-01 and does not block Plan 02-02.

---
*Phase: 02-static-dynamic-parity-switch-reliability*
*Completed: 2026-07-07*

## Self-Check: PASSED

- All 4 key files verified present on disk (contract.json, lib/contract.sh, theme-parity, theme-doctor).
- All 3 commit hashes verified present in git log (3557f23, 23f15e5, 9159fef).
- theme-parity re-run at self-check time: 217 passed, 0 failed, exit 0.
