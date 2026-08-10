---
phase: 11-quickshell-viability-gate
fixed_at: 2026-07-26T12:02:52Z
review_path: .planning/phases/11-quickshell-viability-gate/11-REVIEW.md
iteration: 1
findings_in_scope: 5
fixed: 5
skipped: 0
status: all_fixed
---

# Phase 11: Code Review Fix Report

**Fixed at:** 2026-07-26T12:02:52Z
**Source review:** .planning/phases/11-quickshell-viability-gate/11-REVIEW.md
**Iteration:** 1

**Summary:**
- Findings in scope: 5 (critical_warning scope — CR-01, CR-02, CR-03, WR-01, WR-02; IN-01 and IN-02 excluded by scope)
- Fixed: 5
- Skipped: 0

## Fixed Issues

### CR-01: Probe.qml hardcodes the developer's home directory as a literal path

**Files modified:** `quickshell/.config/quickshell/modules/Probe.qml`
**Commit:** 74ec933
**Applied fix:** Replaced the literal `path: "/home/aorus/.local/state/quickshell/probe.json"` with `path: Quickshell.env("HOME") + "/.local/state/quickshell/probe.json"`, matching the same portable-path convention already used in `quickshell-doctor`'s `STATE_DIR="$HOME/.local/state/quickshell"`. Verified with `qmllint` (clean, exit 0).

### CR-02: `quickshell-doctor`'s headless-output "remove" step can strand a mounted probe on interrupt

**Files modified:** `hypr/.config/hypr/scripts/quickshell-doctor`
**Commit:** 1945a81
**Applied fix:** Armed `PROBE_SUMMONED_FOR_HEADLESS_TEST=1` immediately after the probe-summon dispatch in the "remove" step and disarmed it back to `0` immediately after the dismiss dispatch — reusing the exact flag `_qsd_cleanup` already checks, so an interrupt between the two dispatches now triggers automatic dismissal via the existing EXIT/INT/TERM trap. Verified with `bash -n` and `shellcheck -x` (clean).

### CR-03: `quickshell-doctor`'s reserved-space check has no restore path at all for the surfaces it summons

**Files modified:** `hypr/.config/hypr/scripts/quickshell-doctor`
**Commit:** 3ec4661
**Applied fix:** Introduced a new `RESERVED_CHECK_SUMMONED` global (initialized empty alongside the other trap-guard flags), set it to `"${m_appid}:${m_name}"` immediately before each manifest-surface summon dispatch in the reserved-space loop and cleared it immediately after the dismiss dispatch, and added a corresponding branch to `_qsd_cleanup` that dismisses `$RESERVED_CHECK_SUMMONED` if non-empty when the trap fires. Verified with `bash -n` and `shellcheck -x` (clean).

### WR-01: Volume probe does arithmetic on unvalidated regex-extracted values

**Files modified:** `hypr/.config/hypr/scripts/quickshell-doctor`
**Commit:** 2529894
**Applied fix:** Wrapped the volume probe in explicit emptiness checks on both `mapfile` extractions. If `VOL_ORIG_RAW` comes back empty, the check now reports `[FAIL]` and skips the mutation entirely (no unsafe raise with no validated baseline to restore to). If `VOL_NEW_RAW` comes back empty after the raise, the check reports `[FAIL]` but skips only the delta arithmetic — `VOL_RESTORE_NEEDED` is still armed at that point, so the trap still restores the original volume from the validated `VOL_ORIG_RAW`. This guarantees the `Summary:` line is always reached, satisfying the "always emits Summary" contract even if `pactl`'s output shape changes in the future. Verified with `bash -n` and `shellcheck -x` (clean).

### WR-02: "Zero Quickshell MPRIS writer" check is a bare substring match on prose, not code

**Files modified:** `hypr/.config/hypr/scripts/quickshell-doctor`
**Commit:** 9978851
**Applied fix:** Replaced the bare case-insensitive `grep -qi 'mpris'` with a targeted `grep -qE` pattern matching either the `Quickshell.Services.Mpris` import line or a QML `Mpris*` type instantiation (`\bMpris[A-Za-z]*[[:space:]]*\{`). Manually verified the new pattern matches an import line and a `MprisPlayer {` instantiation, but does not match a prose sentence merely containing the word "MPRIS". Verified with `bash -n` and `shellcheck -x` (clean).

## Skipped Issues

None — all in-scope findings were fixed.

---

_Fixed: 2026-07-26T12:02:52Z_
_Fixer: Claude (gsd-code-fixer)_
_Iteration: 1_
