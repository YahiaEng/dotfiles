---
phase: 05-light-mode-pipeline-theme-presets
reviewed: 2026-07-12T09:19:07Z
depth: standard
files_reviewed: 3
files_reviewed_list:
  - hypr/.config/hypr/scripts/tests/test-walker-dmenu-cancel.sh
  - hypr/.config/hypr/scripts/theme-switch.sh
  - hypr/.config/hypr/scripts/waybar-switch.sh
findings:
  critical: 0
  warning: 3
  info: 4
  total: 7
status: issues_found
---

# Phase 5: Code Review Report (gap-closure re-review, plan 05-05)

**Reviewed:** 2026-07-12T09:19:07Z
**Depth:** standard
**Files Reviewed:** 3
**Status:** issues_found

## Summary

Gap-closure re-review of the WR-04 walker Esc-cancel fix (UAT Test 4): the three-way exit-code branch in `theme-switch.sh` and `waybar-switch.sh`, plus the new hermetic checker `tests/test-walker-dmenu-cancel.sh`. This supersedes the previous full-phase 05-REVIEW.md (findings there were fixed in 05-REVIEW-FIX.md; the full report is preserved in git history at commit 8779ccf and earlier).

No structural pre-pass was provided for this review; all findings below are narrative findings from direct code review.

**The core fix is correct.** The `rc=0; SELECTED=$(... | walker ...) || rc=$?` capture pattern is `set -euo pipefail`-safe (assignment failure is absorbed by the `||` list; `(( ))` tests sit in `if` conditions and are errexit-exempt). The 130/other-nonzero/0 branching matches the debug session's source-verified walker 2.16.2 cancel semantics, the error toast is itself guarded with `2>/dev/null || true`, and the `[[ -z "$SELECTED" ]] && exit 0` guards are non-final commands in AND lists (errexit-exempt). The parallel-array display-to-basename mapping in `theme-switch.sh` is index-matched, never a reverse string transform. I executed the checker on this machine: 10/10 assertions pass, checker exits 0, and the notify-send shim (not the real daemon) received the toasts.

Remaining issues are at the edges: a silent no-feedback `exit 1` path in `theme-switch.sh` that contradicts the WR-04 loud-failure ethos, and two error-handling gaps in `waybar-switch.sh`'s apply path (receiving its first review here — it was not in the previous review's file list).

## Warnings

### WR-01: theme-switch.sh no-match selection exits 1 with zero user feedback, contradicting the WR-04 loud-failure pattern

**File:** `hypr/.config/hypr/scripts/theme-switch.sh:69`
**Issue:** After the three-way branch, a walker exit-0 selection that matches no `DISPLAYS[]` entry falls through the mapping loop and hits `[[ -z "$THEME" ]] && exit 1` — exit code 1 (the same code the script now documents as "hard failure"), but no toast and no visible effect. WR-04's whole point is that every nonzero exit is loud and every silent exit is a deliberate cancel; this path is silent AND nonzero. It is reachable if walker's dmenu mode ever returns the typed query text on Return with no matching item (unverified for walker 2.16.2 — the debug session only source-verified the cancel path), or if display-name generation drifts in a future edit. Today it is a defensive branch, but its failure mode is exactly the "keybind press does nothing, no notification" symptom the previous review's WR-04 flagged.
**Fix:**
```bash
if [[ -z "$THEME" ]]; then
    notify-send -a "Theme Switcher" "Error" "Unrecognized selection: $SELECTED" -i dialog-error 2>/dev/null || true
    exit 1
fi
```
(Note: `theme-apply` already sanitizes/validates names downstream, and `$SELECTED` here is walker output, not palette-file content — but keep the toast body away from format-string position, as done above with the literal string argument.)

### WR-02: waybar-switch.sh success-path notify-send is unguarded under `set -e` — script exits nonzero after a successful layout switch

**File:** `hypr/.config/hypr/scripts/waybar-switch.sh:55-57`
**Issue:** The final `notify-send -a "Waybar Switcher" "Layout Changed" ...` has no `2>/dev/null || true` guard, unlike the error-path toast at line 29 in the same file. Under `set -euo pipefail`, if notify-send fails — notification daemon unreachable over D-Bus, which is a live scenario in this repo because the theming pipeline restarts swaync (`swaync-client -rs`) — the script exits with notify-send's nonzero status even though the layout switch fully succeeded (waybar relaunched, state file written). Any caller or checker treating nonzero as "hard failure" (the convention this very phase just established, and the convention the new test suite asserts on) gets a false failure. The inconsistency between line 29 (guarded) and line 55 (unguarded) in the same file after this change is the tell.
**Fix:**
```bash
notify-send -a "Waybar Switcher" "Layout Changed" \
    "Switched to ${LAYOUT} layout" \
    -i preferences-desktop-display -t 2000 2>/dev/null || true
```

### WR-03: waybar-switch.sh kills the running bar and fires the success toast without verifying the target config/style files exist

**File:** `hypr/.config/hypr/scripts/waybar-switch.sh:44-57`
**Issue:** The apply path is: `pkill waybar` → backgrounded `uwsm app -- waybar -c config-${LAYOUT}.jsonc -s style-${LAYOUT}.css &` → write state file → "Layout Changed" toast. Because the launch is backgrounded, its failure is invisible: if `config-${LAYOUT}.jsonc` or `style-${LAYOUT}.css` is missing (unstowed machine, partial stow, future layout rename), the script kills the working bar, records the new layout in `~/.cache/current-waybar-layout`, and toasts success — leaving the user with no bar and a state file asserting the broken layout is active. The one cheap, deterministic check (file existence) is skipped before the destructive `pkill`.
**Fix:**
```bash
CONFIG="$WAYBAR_DIR/config-${LAYOUT}.jsonc"
STYLE="$WAYBAR_DIR/style-${LAYOUT}.css"
if [[ ! -f "$CONFIG" || ! -f "$STYLE" ]]; then
    notify-send -a "Waybar Switcher" "Error" "Missing files for ${LAYOUT} layout" -i dialog-error 2>/dev/null || true
    exit 1
fi
pkill waybar || true
...
uwsm app -- waybar -c "$CONFIG" -s "$STYLE" &
```

## Info

### IN-01: prettify() word loop is subject to glob expansion and can produce colliding display names

**File:** `hypr/.config/hypr/scripts/theme-switch.sh:20-29`
**Issue:** Two edges in `prettify`: (1) the unquoted `for word in $spaced` performs pathname expansion per word, so a palette basename containing a glob metacharacter (e.g. `neo-*.json`) would expand `*` against the script's CWD and inject arbitrary filenames into the display name; (2) `${raw//-/ }` plus word-splitting collapses runs of hyphens, so `foo--bar.json` and `foo-bar.json` both prettify to "Foo Bar" — the index-matched loop then always resolves the first, silently making the second palette unselectable. Both require self-inflicted palette names, hence Info.
**Fix:** `set -f`/`set +f` around the loop (or `read -ra words <<< "$spaced"`), and consider warning on duplicate display names when building `DISPLAYS[]`.

### IN-02: walker shim never reads stdin — theoretical SIGPIPE flake in the success case under pipefail

**File:** `hypr/.config/hypr/scripts/tests/test-walker-dmenu-cancel.sh:58-67` (shim), interacting with `theme-switch.sh:52`
**Issue:** The shim's comment argues safety from the input being "<1 KB so it never blocks", which addresses pipe-buffer blocking but not SIGPIPE: the shim exits without ever reading stdin, so if the shim's exit wins the race against `printf`'s first write, printf dies with SIGPIPE (141) and — under `pipefail` — the success case (WALKER_RC=0) would report rc=141, sending `theme-switch.sh` down the hard-failure branch and flaking the test. In the cancel/failure cases pipefail returns walker's own status (rightmost nonzero) so only Case 3 is exposed. The window is microscopic (builtin printf write vs. bash shim startup), but the comment's safety claim is incomplete.
**Fix:** Add `cat > /dev/null` (or `read -r -d '' _ || true`) before `exit` in the walker shim so stdin is always drained.

### IN-03: waybar-switch success path (walker exit 0 → selection flow) has no test coverage

**File:** `hypr/.config/hypr/scripts/tests/test-walker-dmenu-cancel.sh:144-175`
**Issue:** The stated three-way contract is 0 → selection flow, 130 → silent cancel, other → toast + exit 1. For `theme-switch.sh` all three branches are asserted (Case 3 runs under an isolated HOME with a stubbed theme-apply). For `waybar-switch.sh` only the 130 and 1 branches are asserted; the exit-0 flow (case-mapping, state file write, relaunch) is untested — understandable since it would need `pkill`/`sleep`/`uwsm` shims plus a HOME override, but the same shim technique already used for theme-apply would work. As written, a regression in the waybar selection mapping (e.g. the `case` patterns vs. the emoji list entries) would pass this checker.
**Fix:** Add a Case 3 to `run_waybar_suite` with `HOME="$tmphome"`, `WALKER_OUT="📊 Full — System stats, media, tray"`, and `pkill`/`sleep`/`uwsm`/`notify-send` shims; assert exit 0 and `$tmphome/.cache/current-waybar-layout` contains `full`.

### IN-04: fixed `sleep 0.3` between pkill and relaunch is a timing assumption, not a synchronization

**File:** `hypr/.config/hypr/scripts/waybar-switch.sh:45-50`
**Issue:** Pre-existing pattern: if the old waybar takes longer than 300 ms to exit (busy system, slow module teardown), the new instance launches alongside it — transiently two bars, or layer-shell contention. Conversely the sleep adds fixed latency when waybar dies instantly.
**Fix:** Poll for exit instead of sleeping blind:
```bash
pkill waybar || true
for _ in {1..20}; do pgrep -x waybar >/dev/null || break; sleep 0.05; done
```

---

_Reviewed: 2026-07-12T09:19:07Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
