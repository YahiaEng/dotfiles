---
phase: 11-quickshell-viability-gate
reviewed: 2026-07-26T14:40:00Z
depth: standard
files_reviewed: 13
files_reviewed_list:
  - hypr/.config/hypr/config/autostart.conf
  - hypr/.config/hypr/config/keybinds.conf
  - hypr/.config/hypr/config/permissions.conf
  - hypr/.config/hypr/hyprland.conf
  - hypr/.config/hypr/scripts/keybind-doctor
  - hypr/.config/hypr/scripts/quickshell-doctor
  - hypr/.config/hypr/scripts/quickshell-launch.sh
  - install.sh
  - quickshell/.config/quickshell/modules/Probe.qml
  - quickshell/.config/quickshell/modules/ScreencopyProbe.qml
  - quickshell/.config/quickshell/shell.qml
  - quickshell/.config/quickshell/shortcuts.json
  - stow.sh
findings:
  critical: 3
  warning: 2
  info: 2
  total: 7
status: issues_found
---

# Phase 11: Code Review Report

**Reviewed:** 2026-07-26T14:40:00Z
**Depth:** standard
**Files Reviewed:** 13
**Status:** issues_found

## Summary

Reviewed the Quickshell viability-gate phase: the new `quickshell` stow package (shell root + two throwaway probe surfaces), the two rerunnable doctor scripts (`keybind-doctor`, `quickshell-doctor`), the launcher, and the Hyprland/install/stow wiring around them. `keybind-doctor` is careful and internally consistent — the bind-block parsing, modmask resolution, and manifest cross-checks all trace through correctly and I could not find a new defect in it beyond what the phase already documented. `quickshell-doctor` is where the real problems are: it explicitly recognizes and fixes a "stranded surface on interrupt" risk in one place (the headless-output per-screen-surface-creation step) but leaves the structurally identical risk unprotected in two other places in the same file, directly undercutting the script's own stated "report-only, always restores what it changes" contract. Separately, `Probe.qml` hardcodes the reviewing developer's home directory as a literal absolute path, which will silently degrade (not crash, but silently mismatch state) on any other username — a direct hit against this repo's stated reproducibility requirement. Everything in `install.sh`/`stow.sh`/`autostart.conf`/`permissions.conf`/`hyprland.conf` checked out against a fresh-machine reading; no new defects found there beyond two minor style nits.

Per instructions, the following already-recorded issues are **not** re-litigated here: QS-03 monitor-hotplug/`Variants` revert, the volume probe's false-positive rounding FAIL, GlobalShortcut requiring a restart to re-register, and `HyprlandFocusGrab` mutual exclusivity.

## Critical Issues

### CR-01: Probe.qml hardcodes the developer's home directory as a literal path

**File:** `quickshell/.config/quickshell/modules/Probe.qml:56`
**Issue:** The probe's `FileView` state path is a literal absolute string tied to one specific user:
```qml
FileView {
    id: probeState
    path: "/home/aorus/.local/state/quickshell/probe.json"
    ...
```
This directly contradicts the project's stated Core Value ("the whole setup reproduces from scratch with one script — no manual host-only state") and the repo-wide convention (used correctly elsewhere, e.g. `quickshell-doctor`'s `STATE_DIR="$HOME/.local/state/quickshell"`) of never baking a username into a config path. On any machine/account other than `aorus`, this path simply won't exist for that user, so `probeState`/`probeAdapter` silently falls back to its declared default (`"unset"`) forever — a quiet, hard-to-diagnose degradation rather than a crash, which is worse for a "viability gate" whose entire job is to prove this mechanism works.
**Fix:**
```qml
path: Quickshell.env("HOME") + "/.local/state/quickshell/probe.json"
```
(or the equivalent Quickshell `Directories`/`StandardPaths` helper, whichever this Quickshell version exposes) — never a literal `/home/<user>/...` string.

### CR-02: `quickshell-doctor`'s headless-output "remove" step can strand a mounted probe on interrupt

**File:** `hypr/.config/hypr/scripts/quickshell-doctor:440-456`
**Issue:** The file's own header and inline comments (lines 88-105, 356-361) establish a strict discipline: any mutation this script makes must be armed via a flag *before* it happens, so the `EXIT`/`INT`/`TERM` trap can always undo it — and that discipline is correctly followed a few lines earlier, in the "per-screen surface creation" step (lines 405-406 and 421-422 arm/disarm `PROBE_SUMMONED_FOR_HEADLESS_TEST` around the summon/dismiss pair). But the very next block — the "remove" step — repeats the exact same summon/dismiss pattern without arming anything:
```bash
hyprctl dispatch global quickshell:probe >/dev/null 2>&1   # line 447: mounts the probe
sleep 0.3
QSD_DP1_STILL_WORKS=$(...)
hyprctl dispatch global quickshell:probe >/dev/null 2>&1   # line 451: dismisses it
sleep 0.2
```
`_qsd_cleanup` only dismisses the probe when `PROBE_SUMMONED_FOR_HEADLESS_TEST` is `1` (line 116-119). Since this second occurrence never sets that flag, a `SIGINT`/`SIGTERM` (or a crash) landing between lines 447 and 451 leaves the probe surface mounted on the user's screen with no cleanup path — the same "trap-based cleanup fails to restore state" failure class the file explicitly designed against elsewhere in the same function.
**Fix:** Reuse the existing flag exactly as the earlier step does:
```bash
hyprctl dispatch global quickshell:probe >/dev/null 2>&1
PROBE_SUMMONED_FOR_HEADLESS_TEST=1
sleep 0.3
QSD_DP1_STILL_WORKS=$(...)
hyprctl dispatch global quickshell:probe >/dev/null 2>&1
PROBE_SUMMONED_FOR_HEADLESS_TEST=0
sleep 0.2
```

### CR-03: `quickshell-doctor`'s reserved-space check has no restore path at all for the surfaces it summons

**File:** `hypr/.config/hypr/scripts/quickshell-doctor:198-217`
**Issue:** The "reserved-space stays unclaimed" loop summons every manifest surface and dismisses it again:
```bash
hyprctl dispatch global "${m_appid}:${m_name}" >/dev/null 2>&1   # line 207: mount
sleep 0.3
POST=$(hyprctl monitors -j | jq -c '[.[].reserved]')
hyprctl dispatch global "${m_appid}:${m_name}" >/dev/null 2>&1   # line 210: dismiss
sleep 0.3
```
Unlike the two probe-summon sites discussed in CR-02, there is no flag at all here and no corresponding branch in `_qsd_cleanup` — this loop iterates over every entry in `shortcuts.json` (currently 2, but manifest-driven, so this grows automatically as more surfaces are added) with zero interrupt protection. An interrupt between the mount and dismiss dispatch leaves whichever manifest surface was mid-test mounted indefinitely, contradicting the file's header claim of being "report-only apart from one documented transient exception" — this mutation isn't in that documented exception list at all, and isn't restored on interrupt.
**Fix:** Track the currently-summoned target and add a dismiss branch to `_qsd_cleanup`, e.g.:
```bash
RESERVED_CHECK_SUMMONED=""
...
RESERVED_CHECK_SUMMONED="${m_appid}:${m_name}"
hyprctl dispatch global "${m_appid}:${m_name}" >/dev/null 2>&1
...
hyprctl dispatch global "${m_appid}:${m_name}" >/dev/null 2>&1
RESERVED_CHECK_SUMMONED=""
```
and in `_qsd_cleanup`:
```bash
if [[ -n "$RESERVED_CHECK_SUMMONED" ]]; then
    hyprctl dispatch global "$RESERVED_CHECK_SUMMONED" >/dev/null 2>&1
    RESERVED_CHECK_SUMMONED=""
fi
```

## Warnings

### WR-01: Volume probe does arithmetic on unvalidated regex-extracted values

**File:** `hypr/.config/hypr/scripts/quickshell-doctor:294-317`
**Issue:** `VOL_ORIG_RAW`/`VOL_NEW_RAW` are populated by `mapfile -t ... < <(printf '%s' "$LINE" | grep -oP '(?<=: )\d+(?=\s*/)')` with no check that the regex actually matched anything before either (a) the delta arithmetic at line 305 (`VOL_NEW_RAW[0] - VOL_ORIG_RAW[0]`), or (b) the restore trap's `pactl set-sink-volume @DEFAULT_SINK@ "${VOL_ORIG_RAW[@]}"` (line 111). The prior guard (line 291) only proves `pactl get-sink-volume` *succeeds*, not that its output matches this specific regex shape. If a future `pactl`/locale/sink-type change alters that output shape, this either aborts the whole script under `set -uo pipefail` (silently truncating the report — no `Summary:` line, checks 11-12 never run) or silently computes a delta against an empty/zero value, depending on the running bash version's nounset-vs-array-element behavior — neither of which is exercised by anything in this repo today, and both of which defeat the "rerunnable, always emits Summary" contract the script exists to provide.
**Fix:** After each `mapfile`, validate before use:
```bash
if [[ "${#VOL_ORIG_RAW[@]}" -eq 0 ]]; then
    check "one-step-per-press volume probe: pactl output did not match expected shape" "1"
else
    ...
fi
```

### WR-02: "Zero Quickshell MPRIS writer" check is a bare substring match on prose, not code

**File:** `hypr/.config/hypr/scripts/quickshell-doctor:275-283`
**Issue:** `grep -qi 'mpris'` is run against every file under `~/.config/quickshell` with no distinction between an actual MPRIS-writing construct and a comment or string that merely mentions the word "MPRIS" (e.g. a future doc comment reading "this shell has no MPRIS support" would itself flip this check to `[FAIL]`). This is the same class of over-broad-pattern risk the review scope calls out; it's a check that can fail on prose alone rather than on an actual capability.
**Fix:** Narrow the pattern to an actual API surface, e.g. a QML `Mpris\w*\s*\{` type instantiation or a known Quickshell MPRIS import line, rather than the bare case-insensitive word.

## Info

### IN-01: Misplaced `windowrule` inside `keybinds.conf`

**File:** `hypr/.config/hypr/config/keybinds.conf:209`
**Issue:** `hyprland.conf` sources a dedicated `windowrules.conf` (line 12) specifically so window-rule concerns live in one place — but `keybinds.conf` ends with a bare `windowrule = match:class kitty, scroll_touchpad 1.5` line, which is unrelated to key binding and will be missed by anyone auditing "all window rules" via `windowrules.conf`.
**Fix:** Move the line into `windowrules.conf`.

### IN-02: Inconsistent quoting of `$AUR_HELPER` in install.sh

**File:** `install.sh:369` (compare with lines 380, 384)
**Issue:** `$AUR_HELPER -Sy --needed --noconfirm "${AUR_PKGS[@]}"` leaves `$AUR_HELPER` unquoted, while the two later invocations in the same function (`"$AUR_HELPER" -R --noconfirm ...`, `"$AUR_HELPER" -Sc --noconfirm`) quote it. Harmless today since the variable is always one of two fixed literals (`paru`/`yay`), but the inconsistency is a latent trap if this assignment is ever loosened.
**Fix:** Quote consistently: `"$AUR_HELPER" -Sy --needed --noconfirm "${AUR_PKGS[@]}"`.

---

_Reviewed: 2026-07-26T14:40:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
