# Deferred Items — Phase 09 (wlogout → wleave migration)

Pre-existing issues discovered during execution that are out of this phase's
scope (Scope Boundary rule: only fix issues directly caused by this task's
changes).

## 1. `keybind-doctor`'s `hyprctl binds -j` JSON parsing is broken on Hyprland 0.56.0

**Found during:** 09-02, Task 2 verification.

**Symptom:** `~/.config/hypr/scripts/keybind-doctor` fails 2 of 8 checks:
- `declared-vs-registered` (reports all 78 declared binds missing)
- `D-03 kill-bind present and registered`

Both failures trace to the same root cause: `jq: parse error: Invalid
numeric literal at line 15, column 22` when parsing `hyprctl binds -j`
output. Inspecting the raw output directly shows Hyprland 0.56.0 emits
malformed JSON for several fields, e.g.:

```
"keycode": Return,
"allow_input_capture": ,
```

(unquoted bareword and an empty value where a JSON value is required —
invalid JSON regardless of jq/keybind-doctor). This reproduces for every
bind uniformly, not just the ones this plan touched, confirming it is a
pre-existing Hyprland version incompatibility (was likely written/tested
against an earlier Hyprland — the RESEARCH doc for this phase cites
"Hyprland 0.55.4" — and the machine now runs 0.56.0-2), not something
introduced by the wlogout → wleave migration.

**Direct evidence the SHIFT,Q bind is nonetheless correct:** `hyprctl binds
-j | grep -A2 -B8 wleave` shows the raw (if malformed) entry for the
Super+Shift+Q bind with `"dispatcher": "exec"`, `"arg":
"~/.config/hypr/scripts/wleave.sh"` — the bind IS registered and points at
the correct script. The 6 other keybind-doctor checks that don't depend on
`hyprctl binds -j` JSON parsing (mainMod resolution, description parity,
static walker-flag grep, binds-j-returned-data, shadowing, release-bind
inventory) all PASS.

**Action taken:** none — fixing `keybind-doctor`'s JSON parsing for a
Hyprland version bump is outside this phase's surface (theming/power-menu
migration) and is not caused by this plan's edits. Logged here and in
`.planning/WINDOWS.md` for future triage.

**Recommendation for whoever picks this up:** `keybind-doctor` likely needs
its `jq` filter updated for whatever schema change Hyprland 0.56.0
introduced to `hyprctl binds -j` (bareword/empty-value fields suggest a
Hyprland-side regression or intentional format change worth checking
against Hyprland's changelog between 0.55.4 and 0.56.0).

## 2. Plan 09-02's own JSONC verify regex doesn't strip `/* */` block comments

**Found during:** 09-02, Task 2 verification.

**Symptom:** The plan's automated verify command (`python3 -c "import
json,re;[json.loads(re.sub(r'(?m)^\s*//.*$','',open(p).read())) for p in
[...]]"`) fails with `JSONDecodeError` on both waybar jsonc files.

**Root cause:** the regex only strips `//` line comments; both files also
contain `/* ... */` block comments (pre-existing, not introduced by this
plan), which the regex leaves in place, breaking `json.loads`.

**Verification the files are actually fine:** stripping both comment
styles (`re.sub(r'/\*.*?\*/', '', text, flags=re.S)` then the `//` regex)
parses both files cleanly as valid JSONC. Waybar's own JSONC-tolerant
parser already handles both comment styles in production. This is a
limitation of the plan's own verify one-liner, not a defect in the repo
files.

**Action taken:** none to the repo files (they are valid); noted here so
09-04 or a future plan-review doesn't mistake this for a real config
break.
