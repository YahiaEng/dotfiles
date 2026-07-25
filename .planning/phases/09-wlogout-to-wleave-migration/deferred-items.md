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

## 3. `theme-doctor` / `theme-stress-test` blocked by an orphaned `eww.scss` contract entry (pre-existing, unrelated phase)

**Found during:** 09-02, Task 3 full gate sweep.

**Symptom:** `theme-doctor` exits 1 (not 0) with exactly 2 failures:
`[FAIL] /home/aorus/.local/state/theme/eww.scss exists` and `[FAIL] git
status --porcelain is empty`. `theme-stress-test` then aborts on switch
#1 because it strictly requires `theme-doctor` to pass (D-66) before
continuing.

**Root cause — `eww.scss`:** `theme-engine/.config/theme-engine/contract.json`
still lists an `eww.scss` / `scss-kv` render target, added in phase 08-06
(`feat(08-06): make eww a first-class theme-pipeline render target`). Per
this repo's own comment in `matugen/.config/matugen/config.toml` ("The eww
media-popup colors template (BAR-04/D-19) was removed 10-06: the eww media
popup was retired... so its matugen template is no longer generated"),
phase 10-06 retired eww and stopped generating `eww.scss`, but never
removed the now-dead `contract.json` entry (nor the corresponding
`theme-doctor` presence check / `theme-stress-test` awareness of it) —
an incomplete retirement from a different, already-completed phase, wholly
unrelated to this phase's wlogout → wleave migration. `git log` confirms
`contract.json`'s `eww.scss` entry predates this phase.

**Root cause — `git status --porcelain is empty`:** the repo working tree
carries a large volume of pre-existing, unrelated pending changes (new
wallpaper files, a modified `hypr/.config/hypr/config/monitors.conf` this
plan's own constraints explicitly forbid touching, deleted
`.planning/HANDOFF.json` etc.) that predate this session and are out of
this phase's scope to stage or resolve.

**Why not fixed here:** `contract.json` IS one of Task 3's declared files,
but retiring eww's dead entry is a distinct architectural decision (a
different tool's incomplete retirement from phase 08-06/10-06) that this
plan's touch-point ledger (18 items, all wlogout/wleave-specific) does not
cover — fixing it would be scope creep into another phase's unfinished
cleanup, not a byproduct of this plan's own changes. Per the deviation
rules' Scope Boundary, this is logged rather than fixed.

**Verification that wleave itself is unaffected:** every wleave-specific
line in `theme-doctor`'s output passed — `CSS-parse: wleave/style.css
(2343 bytes)`, the `wleave` GTK4-sheet is listed (not SKIP), and every
`custom/power` module-gate check resolved. `theme-parity`'s 22 failures
are 100% `eww.scss`-scoped (`grep -c eww.scss` on its FAIL lines == 22 ==
total FAIL count) and it still exits 0. `keybind-doctor` still exits 0
despite its own unrelated pre-existing jq/JSON issue (see item 1 above).
`theme-stress-test`'s precondition block and switch #1's `theme-apply`
step both passed before the abort; the abort itself is `theme-doctor`'s
non-zero exit, not any wleave-specific failure.

**Action taken:** none to `eww.scss`/`contract.json`'s eww entry or to
the unrelated dirty-tree files; logged here and in `.planning/WINDOWS.md`
for future triage as a distinct, separate cleanup (retiring eww fully out
of `contract.json`/`theme-doctor`/`theme-stress-test`).
