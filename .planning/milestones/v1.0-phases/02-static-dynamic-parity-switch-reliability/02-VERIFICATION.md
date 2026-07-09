---
phase: 02-static-dynamic-parity-switch-reliability
verified: 2026-07-07T22:54:24Z
status: passed
score: 3/3 roadmap success criteria verified; 8/8 plan-level must-haves verified
behavior_unverified: 0
overrides_applied: 0
human_signoff: approved (recorded 2026-07-08, this session — preserved from prior 02-02 Task 3 checkpoint)
gate: D-41 clean full gate (preserved from prior verification pass)
---

# Phase 2: Static ↔ Dynamic Parity & Switch Reliability — Verification Report

**Phase Goal:** Static presets and matugen dynamic themes are proven to be one pipeline producing an identical output contract, and switching stays correct under repeated real-world use.
**Verified:** 2026-07-07T22:54:24Z (this pass; supersedes/extends the prior 02-02-Task-3-generated VERIFICATION.md, whose D-41 gate evidence and human sign-off are preserved below, not discarded)
**Status:** passed
**Re-verification:** No — this is the phase-level goal-backward verification (the prior 02-VERIFICATION.md was plan-scoped, produced by 02-02's Task 3 checkpoint to record D-41 evidence + human sign-off).

## Goal Achievement

### Observable Truths (Roadmap Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Switching to a static preset and to a matugen dynamic theme both produce the same canonical color files — identical paths and variable names — verifiable by diffing the generated output structure. | ✓ VERIFIED | Fresh re-run this session: `theme-parity` exit 0, `Summary: 217 passed, 0 failed` (independently reproduced, not just read from SUMMARY). Layer 1 (structure) diffs the file-path set across all 7 targets against `contract.json`'s 10-file manifest; Layer 2 (name-set) diffs extracted variable/key names per file across all 7 targets. Spot-checked the extraction path directly (bypassing the tool) against a fresh `rosepine` render: `waybar.css` 19 names, `hyprland.conf` 21 names, `yazi.toml` 66 names, `vscodium.json` 73 names, `walker-style.css` 64 selector/property pairs — all non-empty and substantive, confirming Layer 1/2 are exercising real data, not a vacuous pass. |
| 2 | Every app re-themes identically regardless of whether the source was a static preset or a dynamic wallpaper theme (no mode-only divergence). | ✓ VERIFIED | `theme-parity` Layer 3 (semantic-value parity, all 7 targets, all 10 files) is part of the same 217/0 passing run. `theme-doctor` fresh re-run this session: 21 passed / 1 failed (the single FAIL is the pre-existing, explicitly-accepted elephant-provider-parity gap deferred to Phase 3 INST-01 — confirmed unchanged from 02-01's baseline, not a Phase 2 regression). Human sign-off (recorded in the prior 02-VERIFICATION.md content, preserved below) directly confirmed Thunar, Walker, waybar, swaync, and kitty all rendered the same materialyou (dynamic) palette correctly on switch #10 — the human-observable half of "no mode-only divergence" that grep/diff cannot see. |
| 3 | Running 10 consecutive theme switches with Thunar and Walker open leaves every app correctly themed on the final switch — no drift, no stuck-white, no stale caches (100% correct). | ✓ VERIFIED | `~/.local/state/theme/logs/stress-20260707T222706Z.log` inspected directly this session: `SUMMARY 140 passed, 0 failed`, a fresh uninterrupted 10-switch run with all pre/postconditions and all 10 per-switch check blocks (theme-apply success, theme-doctor pass, per-file sentinel match across `hyprland.conf`/`waybar.css`/`swaync.css`/`wlogout.css`/`gtk-4.0-colors.css`/`kitty.conf`, walker+elephant liveness+bus-name) present and PASS. Human sign-off (D-35 bar) confirmed switch #10's palette on a newly-opened Thunar window + summoned Walker + waybar/swaync/kitty, with the D-15/D-37 already-open-GTK3-window caveat explicitly documented as an accepted non-failure. |

**Score:** 3/3 roadmap truths verified (0 present-but-behavior-unverified).

### Plan-Level Must-Haves (02-01 / PIPE-04)

| # | Must-have | Status | Evidence |
|---|-----------|--------|----------|
| 1 | `theme-parity` renders all 7 targets and reports structural parity (identical file-path structure) | ✓ VERIFIED | Fresh run, Layer 1 all-PASS; Pitfall-4 zero-file guard present in code (`file_count -eq 0` → FAIL, not skip). |
| 2 | `theme-parity` reports identical variable/key-name set per contract file across all 7 renders (name-set parity) | ✓ VERIFIED | Fresh run, Layer 2 all-PASS; extraction spot-checked non-vacuous (see truth 1 evidence). |
| 3 | `theme-parity` reports every color value well-formed, no empty non-exempt slot, no `{{...}}` leftovers | ✓ VERIFIED (with a documented tooling gap, see Anti-Patterns) | Fresh run, Layer 3 all-PASS. Live rendered `walker-style.css` independently checked for literal `{{` — none present (`grep -c '{{'` exit 1 / zero matches). |
| 4 | `theme-doctor` sources its state-dir file list from `contract.json` and still exits 0 with every prior check passing | ✓ VERIFIED (one pre-existing, accepted exception) | `theme-doctor` sources `lib/contract.sh`, iterates `contract_files()` (confirmed by reading the script — line "while IFS= read -r f; do ... done < <(contract_files)"). Fresh run: 21/22 checks pass; the 1 FAIL is the pre-existing elephant-provider gap, explicitly out of Phase 2 scope (deferred to Phase 3 INST-01), unchanged before/after this phase's refactor per 02-01-SUMMARY's git-stash comparison. |
| 5 | `theme-parity` writes a timestamped machine-readable log under `~/.local/state/theme/logs/` | ✓ VERIFIED | `theme-parity-20260707T225041Z.log` (this session's fresh run) and 3 prior logs present, each with `PASS`/`FAIL`/`SUMMARY` TSV lines. |

### Plan-Level Must-Haves (02-02 / PIPE-06)

| # | Must-have | Status | Evidence |
|---|-----------|--------|----------|
| 6 | `theme-stress-test` performs 10 consecutive alternating static↔dynamic switches with a 3–5s gap by default | ✓ VERIFIED | `SWITCHES=10`, `GAP=4` defaults confirmed in code; `STATIC_PRESETS` rotation + `i % 2` alternation confirmed; `--switches`/`--gap` flags present and validated. |
| 7 | Preconditions open Thunar + confirm walker/elephant health before switch 1; postconditions re-assert after switch 10 | ✓ VERIFIED | Precondition block (lines 278–307) and postcondition block (lines 378–397) both present in code; stress log confirms both blocks executed and passed (`postcondition: Thunar window still open`, etc.). |
| 8 | Each switch's checks (theme-doctor, format-normalized sentinel incl. `hyprland.conf`, walker+elephant liveness+bus-name) pass, abort-on-first-failure with diagnostics dump | ✓ VERIFIED | `check_or_abort` → `abort_with_diagnostics` structurally confirmed (dumps failed check, switch, theme name, theme-doctor output, representative file contents, sanitized notify-send). Stress log shows every per-switch line for switches 1–10 present and PASS, using `contract_normalize_color`; `hyprland.conf` explicitly included in `REPRESENTATIVE_FILES`. |
| 9 | Both `theme-parity` and `theme-stress-test` exist as executable keeper scripts alongside `theme-doctor` | ✓ VERIFIED | All three present, executable (`-rwxr-xr-x`), stowed at `theme-engine/.config/theme-engine/`. |

**Combined plan-level score:** 8/8 (with one documented, non-blocking tooling gap noted below).

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `theme-engine/.config/theme-engine/contract.json` | 10-file manifest, 6 format tags, `hyprland.conf` `image` exemption | ✓ VERIFIED | `jq -e '.files\|length==10'` passes; format set is exactly `{gtk-css,hypr-vars,kitty-kv,toml,json,css-literal}`; `image` is the only `exempt_keys` entry. |
| `theme-engine/.config/theme-engine/lib/contract.sh` | Shared extraction/normalization library | ✓ VERIFIED | All 7 documented functions present and confirmed working with real data (`contract_files`, `contract_format`, `contract_exempt_keys`, `contract_extract_names`, `contract_extract_values`, `contract_normalize_color`, `contract_wellformed_color`). |
| `theme-engine/.config/theme-engine/theme-parity` | Render-only 3-layer parity checker | ✓ VERIFIED | Executable, `bash -n` clean, fresh run exit 0, 217/0. |
| `theme-engine/.config/theme-engine/theme-doctor` | Refactored to read contract.json | ✓ VERIFIED | Sources `lib/contract.sh`, iterates `contract_files()`, all other checks preserved. |
| `theme-engine/.config/theme-engine/theme-stress-test` | 10-switch alternating harness | ✓ VERIFIED | Executable, `bash -n` clean, drives real `theme-apply`, structurally matches all acceptance criteria (grep-confirmed `$((waited+1))` form, no unscoped `killall`, `dev.benz.walker` bus check). |
| `theme-engine/.config/theme-engine/lib/commit.sh` | D-40 fix: exclude `logs/` from rsync `--delete` | ✓ VERIFIED | `rsync -a --delete --exclude=logs/ "$rendered_dir"/ "$STATE_DIR"/` present in code with an explanatory comment tying it to the D-40 finding. |
| `.planning/phases/02-.../02-VERIFICATION.md` | Evidence record with human sign-off | ✓ VERIFIED | This file (supersedes the prior plan-scoped version while preserving its evidence, see below). |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| `theme-doctor` | `contract.json` | `source lib/contract.sh` + `contract_files()` loop | ✓ WIRED | Confirmed by direct code read and fresh execution (10 state-dir file checks present in output, sourced from the manifest, not hardcoded). |
| `theme-parity` | `lib/generate.sh` (`theme_engine_generate`) | Render loop, `$tmp$STATE_DIR` prefix-join | ✓ WIRED | Confirmed in code; independently reproduced the exact prefix-join behavior in a standalone spot-check (`$tmp$STATE_DIR` correctly resolved to the rendered tree). |
| `theme-stress-test` | `theme-apply` | `"$ENGINE_DIR/theme-apply" "$current_theme_name"` | ✓ WIRED | Drives the real entrypoint, not a reimplementation (D-44) — confirmed by direct code read. |
| `theme-stress-test` | `lib/contract.sh` (`contract_normalize_color`) | `sentinel_present_in_file` | ✓ WIRED | Confirmed in code and in the stress log (`sentinel (cfbdfe) present in hyprland.conf (normalized)` — proves the Pitfall-1 rgba-vs-hex normalization path is actually exercised, not just declared). |
| `commit.sh` | `theme-parity`/`theme-stress-test` logs | `rsync --exclude=logs/` | ✓ WIRED | Fix present; corroborated by the stress log itself surviving all 10 switches in the same run that produced it (self-referential proof — the log could not exist intact if the exclude were missing). |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| theme-parity all-green, fresh | `theme-engine/.config/theme-engine/theme-parity` | `Summary: 217 passed, 0 failed`, exit 0 | ✓ PASS |
| theme-doctor exits with only the known-accepted gap | `theme-engine/.config/theme-engine/theme-doctor` | `Summary: 21 passed, 1 failed` (elephant-provider gap, pre-existing) | ✓ PASS |
| Extraction produces real, non-empty data (not vacuous) | Standalone `bash -c` sourcing `lib/contract.sh` + `lib/generate.sh`, rendering `rosepine`, calling `contract_extract_names` per file | 19/21/66/73/64 names extracted across 5 representative files | ✓ PASS |
| No literal `{{` template leftover in live `walker-style.css` | `grep -c '{{' ~/.local/state/theme/walker-style.css` | No match (exit 1) | ✓ PASS |
| theme-stress-test structural gate | `bash -n theme-stress-test`; grep for `contract_normalize_color`, `theme-apply`, `dev.benz.walker`, `$((waited+1))`, absence of unscoped `killall` | All present/absent as required | ✓ PASS |
| Stress log evidence for a fresh, uninterrupted 10-switch run | Read `~/.local/state/theme/logs/stress-20260707T222706Z.log` directly | `SUMMARY 140 passed, 0 failed`; all pre/post-conditions present | ✓ PASS |

Note: `theme-stress-test` itself was **not** re-executed during this verification pass — it mutates the live desktop theme (by design) and a fresh 10-switch run would take several minutes and change the user's currently-applied theme without cause, since a fresh, uninterrupted, zero-failure run plus human sign-off already exists from this same working session (see Human Sign-Off below). Its correctness was instead verified structurally (code read + `bash -n` + grep-confirmed acceptance-criteria patterns) and via direct inspection of its most recent real output log.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|-------------|-------------|--------|----------|
| PIPE-04 | 02-01-PLAN.md | Static presets and matugen dynamic themes produce an identical output contract | ✓ SATISFIED | `theme-parity` 217/0; REQUIREMENTS.md marks PIPE-04 `[x]` Complete, traced to Phase 2. |
| PIPE-06 | 02-02-PLAN.md | Repeated theme switching is reliable (10-switch stress test, 100% correct) | ✓ SATISFIED | `theme-stress-test` log 140/0 + human sign-off; REQUIREMENTS.md marks PIPE-06 `[x]` Complete, traced to Phase 2. |

No orphaned requirements: REQUIREMENTS.md's "Phase 2" rows are exactly {PIPE-04, PIPE-06}, matching the union of both plans' `requirements:` frontmatter.

### Anti-Patterns Found

No debt markers (`TBD`/`FIXME`/`XXX`/`TODO`/`HACK`/`PLACEHOLDER`) in any file this phase created or modified (`contract.json`, `lib/contract.sh`, `theme-parity`, `theme-doctor`, `theme-stress-test`, `lib/commit.sh`) — confirmed by direct grep this session.

The phase's own code review (`02-REVIEW.md`, 1 Critical + 5 Warning + 7 Info) surfaced two findings worth carrying forward as non-blocking, disclosed gaps rather than silently dropping them:

| File | Finding | Severity | Impact on this verification |
|------|---------|----------|------------------------------|
| `lib/contract.sh`, `theme-parity`, `theme-doctor` | CR-01: unknown/typo'd `format` tag, or a missing `jq`/`python3`, causes an extraction layer to silently emit nothing and the affected checks vacuously PASS instead of FAILing loud. | Critical (review), ⚠️ WARNING (this verification) | **Does not currently invalidate the 217/0 result.** Independently spot-checked this session: extraction against a fresh real render produces substantive non-empty output (19–73 names per file) — the checks are exercising real data today, not a vacuous path. This is a real robustness gap for *future* drift protection (a mistyped format tag or missing tool would go undetected), not evidence that today's parity claim is false. Recommend a follow-up hardening pass before relying on this tool as a long-term regression gate (e.g., Phase 3 or a dedicated fix plan). |
| `lib/contract.sh:165-167`, `theme-parity:169` | WR-01: the documented "`{{...}}` leftovers are always a failure regardless of format" guarantee does not hold for `css-literal` (`walker-style.css`) — its value extractor only emits hex/rgba-shaped tokens, so a leftover in that file would never be seen by the leftover check. | Warning (review), ⚠️ WARNING (this verification) | **Does not currently invalidate the "no mode-only divergence" truth.** Directly confirmed the live rendered `walker-style.css` has zero literal `{{` occurrences today, and the human sign-off separately, visually confirmed Walker renders correctly. This is a coverage gap in the *safety net* for the one file with this project's worst regression history (the original stuck-white Walker bug), not a present defect. Recommend adding the format-agnostic `grep -q '{{' "$path"` scan the review proposes, as a low-cost follow-up. |

Neither finding is a stub, a missing artifact, or an unwired link — both are judgment calls about the verification tooling's defense-in-depth for *future* runs, and both are already fully documented with proposed fixes in `02-REVIEW.md`. Given this phase's goal is to *prove* parity/reliability (which it does, backed by fresh, independently-reproduced evidence in this session) rather than to ship a permanently bulletproof regression harness, these are tracked as recommended hardening follow-ups, not phase-blocking gaps.

## Human Sign-Off (preserved from prior 02-VERIFICATION.md / 02-02 Task 3)

**Status: APPROVED.** (Recorded in this same working session, per the orchestrator's briefing and confirmed by the project's session log.)

The user ran the fresh default gate, then on switch #10 (materialyou, the applied theme at sign-off):

- Opened a **newly-created** Thunar window (not one open since before switch #1) and confirmed it rendered the switch-#10 materialyou palette correctly.
- Summoned Walker (`dev.benz.walker` bus name registered, `--gapplication-service` healthy, elephant `listproviders` responding) and confirmed it rendered themed and returned working search results (D-38).
- Glanced at waybar, swaync (including a test notification), and kitty — all confirmed showing the switch-#10 materialyou palette with no drift, no stuck-white, and no stale mix of two themes.

User's exact confirmation (as recorded by the 02-02 Task 3 checkpoint): *"approved" — Thunar, Walker, waybar, swaync, and kitty all render the current materialyou palette correctly after the 10-switch stress run. No issues reported.*

### D-15 / D-37 Caveat — Documented Pass

Per D-15 (established in Phase 1) and D-37 (this phase's explicit re-confirmation), a GTK3 window that was **already open before a theme switch** does NOT live-update its colors — GTK3 has no live CSS reload API, so an existing Thunar window retains the palette it was rendered with until it is closed and reopened. This is an accepted, documented limitation, **not a failure**. It was directly observed during the stress run (a precondition-opened Thunar window stayed on its original palette through the run), and the human sign-off above was deliberately performed against a **newly-opened** Thunar window to validate the actual live-rendering contract, routing around this documented caveat.

## D-41 Clean Full Gate — Evidence (preserved)

1. **Stress run** — `~/.local/state/theme/logs/stress-20260707T222706Z.log`: **140 passed, 0 failed.** Fresh, uninterrupted 10-switch run (independently re-confirmed present and intact this session).
2. **Parity run** — `~/.local/state/theme/logs/theme-parity-20260707T222832Z.log`: **217 passed, 0 failed.** Immediately following the stress run in the same session.
3. **D-40 reliability bug found and fixed**: `lib/commit.sh`'s `rsync -a --delete` was wiping `~/.local/state/theme/logs/` on every `theme-apply` commit; fixed with `--exclude=logs/` (commit `0d34782`), independently confirmed present in the current code this session.

## Gaps Summary

No gaps block phase completion. Two tooling-robustness findings from the phase's own code review (CR-01, WR-01) are carried forward as disclosed, non-blocking recommendations for a future hardening pass — both were independently investigated this session and confirmed to **not** currently produce a false result for PIPE-04/PIPE-06 (extraction is substantive on real data; the live `walker-style.css` has no leftover artifacts today). The phase's three roadmap success criteria and both plans' full must-haves are all verified with fresh, independently-reproduced evidence, not solely SUMMARY.md claims.

---

_Verified: 2026-07-07T22:54:24Z_
_Verifier: Claude (gsd-verifier)_
