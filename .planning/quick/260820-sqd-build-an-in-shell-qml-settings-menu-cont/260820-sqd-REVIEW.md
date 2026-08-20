---
phase: quick-260820-sqd
reviewed: 2026-08-20T23:20:00+03:00
depth: quick (executed as standard — traced the highest-stakes paths named in the review request)
files_reviewed: 32
files_reviewed_list:
  - elephant/.config/elephant/menus/settings.toml
  - hypr/.config/hypr/config/keybinds.lua
  - hypr/.config/hypr/config/monitors.lua
  - hypr/.config/hypr/config/windowrules.lua
  - hypr/.config/hypr/hypridle.conf
  - hypr/.config/hypr/hyprland.lua
  - hypr/.config/hypr/lib/overrides.lua
  - hypr/.config/hypr/scripts/hypr-equivalence-check
  - hypr/.config/hypr/scripts/hypr-overrides.sh
  - hypr/.config/hypr/scripts/idle-overrides.sh
  - quickshell/.config/quickshell/modules/settings/Settings.qml
  - quickshell/.config/quickshell/modules/settings/SettingsState.qml
  - quickshell/.config/quickshell/modules/settings/NavRail.qml
  - quickshell/.config/quickshell/modules/settings/PageRegistry.qml
  - quickshell/.config/quickshell/modules/settings/PageCompRegistry.qml
  - quickshell/.config/quickshell/modules/settings/Pages.qml
  - quickshell/.config/quickshell/modules/settings/qmldir
  - quickshell/.config/quickshell/modules/settings/common/PageBase.qml
  - quickshell/.config/quickshell/modules/settings/common/SettingsSection.qml
  - quickshell/.config/quickshell/modules/settings/common/SelectRow.qml
  - quickshell/.config/quickshell/modules/settings/common/ToggleRow.qml
  - quickshell/.config/quickshell/modules/settings/common/SliderRow.qml
  - quickshell/.config/quickshell/modules/settings/common/NavRow.qml
  - quickshell/.config/quickshell/modules/settings/common/InfoRow.qml
  - quickshell/.config/quickshell/modules/settings/common/qmldir
  - quickshell/.config/quickshell/modules/settings/pages/AppearancePage.qml
  - quickshell/.config/quickshell/modules/settings/pages/ConnectivityPage.qml
  - quickshell/.config/quickshell/modules/settings/pages/DisplayInputPage.qml
  - quickshell/.config/quickshell/modules/settings/pages/ShellBehaviourPage.qml
  - quickshell/.config/quickshell/modules/settings/pages/qmldir
  - quickshell/.config/quickshell/shell.qml
  - quickshell/.config/quickshell/shortcuts.json
  - stow.sh
findings:
  critical: 3
  warning: 4
  total: 7
status: issues_found
---

# Quick Task 260820-sqd: Code Review Report

**Reviewed:** 2026-08-20T23:20:00+03:00
**Depth:** quick, escalated to standard on the four highest-stakes paths the reviewer was pointed at (UI→`hyprctl eval`, idle/lock overrides, `lib/overrides.lua` fallback discipline, and hardcoded-color/pipefail conventions)
**Files Reviewed:** 32
**Status:** issues_found

## Summary

This reviewed the in-shell QML settings window (Tasks 1–4 of quick task 260820-sqd), which is fully built and committed. The `or`-fallback discipline in `lib/overrides.lua`/`monitors.lua`/`hyprland.lua` is genuinely sound — every consumed key degrades to today's literal default, confirmed by direct reading, not by trusting the plan's own claim. The idle/lock persistence pair (`idle-overrides.sh` + the restructured `hypridle.conf` + `stow.sh`'s seed block) is careful: floor + ordering validation, atomic writes, backup-before-write, and a post-restart rule-count rollback are all present and match what the plan promised. `keybind-doctor`'s three-way contract (`keybinds.lua` ↔ `shortcuts.json` ↔ `shell.qml` GlobalShortcut) byte-matches. The QQC2 `Control.contentItem` anchoring trap is avoided consistently across every row type. `Colours.*`/`Motion.*` discipline holds throughout — no hardcoded colors were found.

However, `hypr-overrides.sh` — the script the plan itself names as "the single highest-risk new file" — has a verification bug that defeats its own headline safety claim (validate → apply live → **verify** → persist). The verify step for both `monitor` and `input` subcommands checks only ONE field (`scale` / `sensitivity` respectively) regardless of which field the caller actually changed. For a `--mode`-only or `--kb-layout`-only call, the check is a tautology against an unchanged value and can never detect a failed live apply — meaning an unverified mode/position/kb_layout/follow_mouse/natural_scroll change can still be persisted into `~/.local/state/hypr/overrides.lua`, the exact file the compositor `require`s at every boot and `hyprctl reload`. This directly contradicts T-SQD-03's stated mitigation ("a mode never proven live cannot reach the file the compositor reads at boot") and the plan's own SUMMARY confirms its round-trip test (Task 3 verify check J) only ever exercised `scale`, so the gap was never exercised by the plan's own gates. There is also a genuine Lua-injection gap on the `hyprctl eval` sink for monitor names, and a silent full-file-clobber risk in the persist step. These are listed below as Critical.

## Critical Issues

### CR-01: `hypr-overrides.sh` verify step does not check the field it just changed (monitor)

**File:** `hypr/.config/hypr/scripts/hypr-overrides.sh:171-178`
**Issue:** After `hyprctl eval` applies a monitor change, the only oracle check performed is:
```bash
hyprctl monitors -j 2>/dev/null | jq -e --arg o "$output" --argjson s "$final_scale" '
    .[] | select(.name == $o) | (.scale == $s)
' >/dev/null 2>&1 && verify_ok=0
```
`final_scale` falls back to the monitor's *own current* live scale whenever `--scale` was not passed (line 160). So when the QML page calls `hypr-overrides.sh monitor <output> --mode <mode>` (which `DisplayInputPage.qml:92` does — no `--scale` argument), `final_scale` is set to the value the monitor *already had before this call*, and the check `.scale == $s` compares that value against itself. It is true whether or not the mode change actually applied. Width/height/refreshRate are never checked at all. The same is true in reverse for a scale-only call with respect to mode/position — but since mode/position are not checked by *any* code path, a `--mode`-only or `--position`-only call is **never actually verified**, regardless of whether it succeeds or silently fails live (bad EDID timing, driver refusal, etc.).

This defeats the design's own stated purpose (script header, lines 11-17): *"A value never proven live cannot reach the file the compositor `require`s at boot (T-SQD-03)."* An unverified, silently-failed mode change is persisted anyway on the next line (`_persist "$json"`), and — because it *was* on the closed allowlist (a valid `availableModes` entry) — it will be re-applied at every future `hyprctl reload` and every boot, exactly the class of failure T-SQD-03 was written to prevent. The plan's own SUMMARY.md (`id: D5` verification) confirms the only live round-trip test performed (Task 3 verify check J) exercised `--scale` only, so this gap was never exercised.

**Fix:** Verify the specific field(s) that were actually supplied, e.g.:
```bash
local verify_ok=0
if [[ -n "$mode" ]]; then
    hyprctl monitors -j | jq -e --arg o "$output" --arg w "${sw}" --arg h "${sh}" \
        '.[] | select(.name==$o) | (.width|tostring)==$w and (.height|tostring)==$h' >/dev/null 2>&1 \
        || verify_ok=1
fi
if [[ -n "$position" ]]; then
    hyprctl monitors -j | jq -e --arg o "$output" --arg pos "$position" \
        '.[] | select(.name==$o) | (.x|tostring)+"x"+(.y|tostring) == $pos' >/dev/null 2>&1 \
        || verify_ok=1
fi
if [[ -n "$scale" ]]; then
    hyprctl monitors -j | jq -e --arg o "$output" --argjson s "$final_scale" \
        '.[] | select(.name==$o) | .scale == $s' >/dev/null 2>&1 || verify_ok=1
fi
```
Reject and exit non-zero if any requested field fails to verify, before ever calling `_persist`.

### CR-02: `hypr-overrides.sh` verify step for `input` only checks sensitivity

**File:** `hypr/.config/hypr/scripts/hypr-overrides.sh:234-242`
**Issue:** The exact same bug as CR-01, on the `input` subcommand:
```bash
if [[ "$(hyprctl getoption input:sensitivity -j 2>/dev/null | jq -r '.float')" == "$final_sens" ]]; then
    verify_ok=0
fi
```
`kb_layout`, `follow_mouse`, and `natural_scroll` are never verified against `hyprctl getoption -j` at all — only `sensitivity` is checked, and (as in CR-01) that check is a tautology whenever `--sensitivity` wasn't the flag being changed, since `final_sens` falls back to the pre-existing live value. `DisplayInputPage.qml`'s keyboard-layout, follow-mouse, and natural-scroll rows all call `hypr-overrides.sh input --kb-layout ...` / `--follow-mouse ...` / `--natural-scroll ...` without `--sensitivity`, so none of those three writes is ever actually confirmed live before being persisted.
**Fix:** Same pattern as CR-01 — verify only the field(s) supplied on this invocation, checking each against its own `hyprctl getoption <key> -j` oracle, and fail closed (no persist) if any check fails.

### CR-03: Monitor output name is interpolated unescaped into a compositor-privileged `hyprctl eval` string

**File:** `hypr/.config/hypr/scripts/hypr-overrides.sh:165`
**Issue:**
```bash
hyprctl eval "return hl.monitor({ output = \"$output\", mode = \"$final_mode\", position = \"$final_position\", scale = $final_scale })" >/dev/null 2>&1
```
`$output` is validated only by **membership** in `hyprctl monitors -j`'s live `.name` set (line 117) — never by character content. `mode`/`position`/`scale` are content-restricted by regex before use, but `output` is not. The threat model (T-SQD-01, rated `high`) explicitly requires a "closed allowlist BEFORE any eval," and `DisplayInputPage.qml`'s own header comment (lines 70-79) asserts that device-supplied strings are "never interpolated into the generated Lua — only the normalised, allowlist-matched mode/scale values are" — but `output` *is* interpolated into the eval string, raw, with no quote/backslash escaping. `_persist()` (line 60) *does* escape the same value via its `luastr` jq function before writing it into `overrides.lua`, so the codebase clearly knows this value needs escaping in a Lua-string context — the `hyprctl eval` call site was simply missed. A monitor/output name containing a `"` character (a compositor-reported string this repo does not control, per the threat model's own T-SQD-04 entry) would break out of the Lua string literal inside a call evaluated with full compositor privilege.
**Fix:** Apply the same escaping `_persist()` already uses before interpolating into the eval string, e.g. extract a small `_luastr()` helper and use it for `output`/`final_mode`/`final_position` at both call sites:
```bash
_luastr() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'; }
hyprctl eval "return hl.monitor({ output = \"$(_luastr "$output")\", mode = \"$(_luastr "$final_mode")\", position = \"$(_luastr "$final_position")\", scale = $final_scale })"
```

## Warnings

### WR-01: `_persist()` can silently clobber the entire overrides file on a transient upstream read failure

**File:** `hypr/.config/hypr/scripts/hypr-overrides.sh:52-76, 244-247`
**Issue:** `cmd_input`'s fallback reads (e.g. `final_sens=$(hyprctl getoption input:sensitivity -j 2>/dev/null | jq -r '.float')`) are not checked for success. If `hyprctl`/`jq` transiently fail here, `final_sens` (or `final_kb`/`final_fm`/`final_ns`) can end up empty. `--argjson sens "$final_sens"` on an empty string is invalid JSON and makes the `jq` invocation that builds `json` fail, leaving `json` empty. `_persist ""` is then called, and its internal `jq -r` on empty input produces an empty `lua_body`, which is written via the atomic tmp+mv path over the top of `overrides.lua` — replacing the *entire* previously-good overrides table (including any persisted monitor settings from a prior, unrelated write) with an empty file. `lib/overrides.lua`'s type-check (`type(overrides) ~= "table"`) does catch the resulting `require()` return value gracefully, so the compositor itself is not endangered — but the operator's previously-saved Display+input adjustments are silently lost. `idle-overrides.sh` has an explicit backup+rollback for the equivalent risk; `hypr-overrides.sh` has none.
**Fix:** Validate that each field-fallback read succeeded (non-empty, well-formed) before constructing `--argjson` arguments; and/or back up `overrides.lua`/`overrides.json` before `_persist()` overwrites them, restoring on a detected empty/malformed render.

### WR-02: `_mode_matches_available` aborts on any unexpectedly-formatted `availableModes` entry, rejecting all mode changes for that monitor

**File:** `hypr/.config/hypr/scripts/hypr-overrides.sh:90-95`
**Issue:**
```jq
map(
    capture("^(?<w>[0-9]+)x(?<h>[0-9]+)@(?<r>[0-9]+(\\.[0-9]+)?)Hz$") |
    select(...)
) | length > 0
```
`capture()` without a `?` throws a jq error on any string that does not exactly match the pattern. If a single entry in a monitor's `availableModes` array has an unexpected shape (interlaced/stereo suffix, different case, etc.), the whole `map()` expression errors out and `jq -e` exits non-zero for the *entire* validation — rejecting even modes that *do* match the expected pattern elsewhere in the same array. This fails closed (safe), but it is a real availability bug: one odd entry silently blocks every legitimate mode change for that output.
**Fix:** Wrap the capture in `try ... catch empty` (or filter to matching entries first with `select(test(...))` before capturing) so one malformed entry doesn't poison the whole list:
```jq
map(select(test("^[0-9]+x[0-9]+@[0-9]+(\\.[0-9]+)?Hz$")) | capture(...) | select(...))
```

### WR-03: Dropdown "current" marker never matches for non-integer refresh rates

**File:** `quickshell/.config/quickshell/modules/settings/pages/DisplayInputPage.qml:61-68, 135`
**Issue:** `_currentModeString()` rounds `refreshRate` to the nearest whole number (`Math.round(mon.refreshRate)`), while `resolutionOptions` (built via `_normaliseMode`) preserves whatever decimal precision `availableModes` reports (e.g. `"59.94"`, `"143.86"`). `SelectRow.currentValue` (line 135) is set from `_currentModeString()`, and `SelectRow.currentDisplay` (`common/SelectRow.qml:25-31`) does an exact string match against `model[i].value` to find which option is "current." For any monitor whose live refresh rate is not close to a whole number, no option will ever match, so the dropdown will show no mode as selected even though the monitor is running one of the listed modes. Human-check item 6 in the plan explicitly asks the operator to confirm "the current one marked" — this will silently fail on hardware with a fractional native refresh rate.
**Fix:** Round consistently — either normalise `_currentModeString()` through the same `_normaliseMode()` rounding rules used to build `resolutionOptions`, or compare numerically (extract width/height/refresh and compare with tolerance) rather than by exact string equality.

### WR-04: `common/InfoRow.qml` is fully built and registered but never used

**File:** `quickshell/.config/quickshell/modules/settings/common/InfoRow.qml`, `quickshell/.config/quickshell/modules/settings/common/qmldir:13`
**Issue:** `InfoRow` was declared in Task 2 with a comment saying it would be consumed "not until Task 3/Task 4." Both of those tasks are now committed, and a repo-wide search confirms no page references `InfoRow` anywhere. It remains dead code — declared in `qmldir`, fully implemented, never instantiated.
**Fix:** Either wire it into one of the pages it was intended for (e.g. a read-only "current mode" fact on `DisplayInputPage.qml`, which would also help close WR-03) or remove the unused component and its `qmldir` entry.

---

_Reviewed: 2026-08-20T23:20:00+03:00_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: quick (escalated on the four flagged high-stakes paths)_
