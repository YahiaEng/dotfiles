---
phase: 02-static-dynamic-parity-switch-reliability
fixed_at: 2026-07-08T02:03:00Z
review_path: .planning/phases/02-static-dynamic-parity-switch-reliability/02-REVIEW.md
iteration: 1
findings_in_scope: 6
fixed: 6
skipped: 0
status: all_fixed
---

# Phase 02: Code Review Fix Report

**Fixed at:** 2026-07-08T02:03:00Z
**Source review:** .planning/phases/02-static-dynamic-parity-switch-reliability/02-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 6 (fix_scope: critical_warning — 1 Critical + 5 Warnings; IN-01..IN-07 excluded)
- Fixed: 6
- Skipped: 0

## Fixed Issues

### CR-01: theme-parity / theme-doctor silently false-pass when extraction produces nothing

**Files modified:** `theme-engine/.config/theme-engine/lib/contract.sh`, `theme-engine/.config/theme-engine/theme-parity`, `theme-engine/.config/theme-engine/theme-doctor`
**Commit:** 46f9361
**Applied fix:** Closed all four silent false-pass paths:
1. `contract.sh`: both `*)` unknown-format branches now print `contract.sh: unknown format '$fmt' for '$name'` to stderr before `return 1` (loud, not silent).
2. `contract.sh`: dropped the blanket `2>/dev/null` on the python3 (toml) and jq (json) extractors in both `contract_extract_names` and `contract_extract_values` — parse errors and missing tools now surface and propagate a non-zero exit.
3. `theme-parity`: added a hard `exit 1` guard when `CONTRACT_FILE_LIST` is empty (jq missing / contract.json unreadable); Layer 2 now captures the extractor exit status (`if ! names="$(...)"` → FAIL + continue) and refuses an empty reference name-set (new "captured as reference (non-empty)" FAIL check); Layer 3 captures the value-extractor exit status the same way and additionally FAILs when an all-color format (`enforce_emptiness=1`) yields zero key/value pairs.
4. `theme-doctor`: the contract.json file loop now captures `contract_files` output first and emits an explicit `[FAIL] contract.json file list readable and non-empty (jq present)` when it is empty, instead of the ten per-file checks silently vanishing.

Empirically verified: unknown format → stderr message + rc=1; empty gtk-css file → rc=1 under pipefail; valid extraction unchanged. Full `theme-parity nord` run: 41 passed, 0 failed, exit 0.

### WR-01: `{{...}}` template leftovers in walker-style.css invisible to the parity check

**Files modified:** `theme-engine/.config/theme-engine/theme-parity`
**Commit:** 0e2abc7
**Applied fix:** Added a direct, format-agnostic `grep -q '{{'` scan on the raw rendered file as its own check ("free of raw {{ template leftovers") inside Layer 3, run for every contract file and every target. Placed BEFORE the extraction-status guard so a leftover is caught even when value extraction fails — this makes the header's "leftovers are always a failure regardless of format" guarantee actually hold for css-literal.

### WR-02: commit.sh deletes `current-theme` (and `.last-render-error.log`) mid-commit

**Files modified:** `theme-engine/.config/theme-engine/lib/commit.sh`
**Commit:** a5af471
**Applied fix:** Added `--exclude=current-theme --exclude=.last-render-error.log` to the rsync so both engine-owned root-level files survive the `--delete` sync (old `current-theme` stays visible to concurrent readers throughout), and replaced the bare `echo > current-theme` with a temp-file + `mv` write (`current-theme.tmp` → `current-theme`) for per-file atomicity. Comments updated to document why.

### WR-03: abort_with_diagnostics re-runs theme-doctor instead of dumping the captured output

**Files modified:** `theme-engine/.config/theme-engine/theme-stress-test`
**Commit:** 94eb876
**Applied fix:** The diagnostics dump now prints the failure-time `THEME_DOCTOR_OUTPUT` (labeled "captured at failure time") when the failed check is the theme-doctor check and the capture is non-empty; it falls back to a fresh `theme-doctor` run for non-doctor failures. Adaptation from the review's literal snippet: gated on `failed_desc == *"theme-doctor"*` in addition to non-emptiness, because after the first successful doctor run the variable is always non-empty and a bare non-empty check would dump a stale PASSING doctor capture for non-doctor failures — the gate implements the review's stated intent ("fall back to a fresh run only for non-doctor failures") precisely. `THEME_DOCTOR_OUTPUT` is no longer dead.

### WR-04: theme-parity mutates live state despite its "never mutates state" banner

**Files modified:** `theme-engine/.config/theme-engine/lib/generate.sh`, `theme-engine/.config/theme-engine/theme-parity`
**Commit:** 56b118a
**Applied fix:** `generate.sh` now honors an environment/shell override: `GENERATE_LOG="${THEME_ENGINE_RENDER_LOG:-$HOME/.local/state/theme/.last-render-error.log}"` (default path unchanged for theme-apply). theme-parity sets `THEME_ENGINE_RENDER_LOG="$LOG_DIR/theme-parity-render-error.log"` before sourcing generate.sh, so its renders never truncate the live error log. Verified empirically: a full `theme-parity nord` run left the live `.last-render-error.log` mtime and size byte-identical.

### WR-05: hypr-vars extraction regexes silently drop variable names containing digits

**Files modified:** `theme-engine/.config/theme-engine/lib/contract.sh`
**Commit:** 31b7cb7
**Applied fix:** Both hypr-vars patterns now use `[A-Za-z_][A-Za-z0-9_]*`: name extractor `grep -oP '^\$\K[A-Za-z_][A-Za-z0-9_]*(?= =)'` and value extractor `sed -nE 's/^\$([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*=[[:space:]]*(.*)$/\1\t\2/p'`, exactly as the review specified. Verified empirically: `$color4` / `$surface2` now appear in both name and value extraction output.

## Verification

- `bash -n` syntax check passed for all five modified scripts after every edit.
- Functional smoke tests: unknown-format loudness, pipefail-driven empty-extraction failure, digit-bearing hypr-vars extraction.
- End-to-end: `theme-parity nord` (report-only, single render) — 41 passed, 0 failed, exit 0, new WR-01 leftover checks present and passing, live error log untouched.

---

_Fixed: 2026-07-08T02:03:00Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
