# Phase 11: Quickshell Viability Gate - Pattern Map

**Mapped:** 2026-07-26
**Files analyzed:** 8 (new/modified)
**Analogs found:** 7 / 8 (1 has no direct repo analog — new QML ecosystem)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `quickshell/.config/quickshell/shell.qml` | component (shell root) | event-driven | *(none — no existing QML in repo)* | no analog — follow conventions below |
| `quickshell/.config/quickshell/modules/Probe.qml` | component (probe panel) | event-driven | *(none — no existing QML)* | no analog — follow conventions below |
| `hypr/.config/hypr/scripts/quickshell-launch.sh` | utility (guarded launcher) | request-response (process spawn) | `hypr/.config/hypr/scripts/waybar-launch.sh` | exact (role+flow) |
| `hypr/.config/hypr/scripts/quickshell-doctor` | test (rerunnable gate) | batch/CRUD-check | `hypr/.config/hypr/scripts/keybind-doctor`, `theme-engine/.config/theme-engine/theme-doctor` | exact (role+flow) |
| `hypr/.config/hypr/scripts/keybind-doctor` (MODIFIED) | test (rerunnable gate) | batch/CRUD-check | itself (in-place repair) | exact — same file, targeted edit |
| `stow.sh` (MODIFIED — `PACKAGES` array) | config | batch | itself | exact — same file, array append |
| `install.sh` (MODIFIED — `PACMAN_PKGS`) | config | batch | itself | exact — same file, array append |
| `hypr/.config/hypr/config/autostart.conf` (MODIFIED) | config | event-driven (session start) | itself | exact — same file, line append |
| `hypr/.config/hypr/config/permissions.conf` (NEW, D-12) | config | request-response (compositor permission grant) | `hypr/.config/hypr/config/keybinds.conf`/`windowrules.conf` (sourced `.conf` module pattern) | role-match |
| `.planning/phases/11-quickshell-viability-gate/*-EVIDENCE.md` (NEW) | test (evidence artifact) | batch (dated record) | `.planning/milestones/v2.0-phases/08-waybar-evolution/08-BAR-02-EVIDENCE.md` | exact (format precedent) |

## Pattern Assignments

### `quickshell/.config/quickshell/shell.qml` + `modules/Probe.qml` (component, event-driven)

**No existing QML analog in this repo** — this is the first QML file. Do NOT invent a codebase pattern; instead the plan must lock these repo-wide conventions, all sourced from CONTEXT.md/RESEARCH.md (already version-matched to installed quickshell 0.3.0), not from any existing file:

- Zero hex literals / zero authored colours anywhere in this QML (D-04) — mirrors this repo's existing "zero hex literals in stylesheets, always `@import` from `~/.local/state/theme/`" rule (RESEARCH.md "Established Patterns"), deliberately NOT applied yet for QML (Phase 12 owns the QML render-target format).
- Directory layout is exactly D-19's minimal shape — do not seed `services/`, `widgets/`, `config/` subdirs:
```
quickshell/
└── .config/quickshell/
    ├── shell.qml           # root — loads modules/Probe.qml behind a keybind, nothing rendered by default
    └── modules/
        └── Probe.qml       # one instrumentation panel: button + text field + FileView label + screen-name label
```
- Layer-shell surface pattern (D-21, RESEARCH.md Pattern 1), verbatim QML to copy:
```qml
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: probe
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-probe"       // distinct namespace, no existing client uses this
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusiveZone: 0                                  // never reserves space
}
```
- Click-outside dismiss (RESEARCH.md Pattern 2), verbatim QML to copy:
```qml
import Quickshell
import Quickshell.Hyprland

PanelWindow {
    id: probeWindow
    HyprlandFocusGrab {
        id: grab
        windows: [ probeWindow ]
        active: true
        onCleared: probeWindow.visible = false   // click-outside dismiss
    }
}
```
- Hand-edit JSON state (D-03/D-20/QS-04), verbatim QML to copy:
```qml
import Quickshell.Io

FileView {
    id: probeState
    path: "/home/aorus/.local/state/quickshell/probe.json"  // D-20 — own state dir, never ~/.local/state/theme/
    watchChanges: true
    onFileChanged: reload()          // picks up a hand-edit with NO reload.sh call
    onAdapterUpdated: writeAdapter()
    JsonAdapter {
        property string label: "unset"
    }
}
```
- **Anti-pattern to flag in the plan:** do not rely on `PanelWindow.focusable: true` as a substitute for the explicit `WlrLayershell.keyboardFocus` line above — the docs don't state the exact enum it maps to (RESEARCH.md Anti-Patterns).

---

### `hypr/.config/hypr/scripts/quickshell-launch.sh` (utility, request-response/process-spawn)

**Analog:** `hypr/.config/hypr/scripts/waybar-launch.sh` (full file, 41 lines — reproduced in full above under Read; **no re-read needed**)

**Shape to copy:**
- Shebang + `set -uo pipefail` (NOT `-e` — waybar-launch.sh's own comment explains: a script that `exec`s at the end must never abort under `-e` on a transient failure and leave the session with nothing running). Same discipline applies here: a guarded launcher's job is to degrade to "skip, logged" not "crash silently."
- Guard-then-`exec` structure: resolve paths as local vars at top, run existence/validity checks, only ever `exec` the final real binary once guards pass.

**Concrete adaptation for `quickshell-launch.sh` (D-06)** — RESEARCH.md already drafted this exact file; copy verbatim as the starting point:
```bash
#!/usr/bin/env bash
# quickshell-launch.sh — guarded, logged launcher (D-06)
set -uo pipefail

LOG="$HOME/.cache/quickshell.log"
CONFIG_DIR="$HOME/.config/quickshell"

if ! command -v quickshell >/dev/null 2>&1; then
    echo "quickshell-launch.sh: quickshell binary not found — skipping" >>"$LOG"
    exit 0
fi
if [[ ! -f "$CONFIG_DIR/shell.qml" ]]; then
    echo "quickshell-launch.sh: $CONFIG_DIR/shell.qml not found — skipping" >>"$LOG"
    exit 0
fi

echo "quickshell-launch.sh: starting $(date -Is)" >>"$LOG"
exec quickshell -p "$CONFIG_DIR" >>"$LOG" 2>&1
```
**Flag before finalizing:** RESEARCH.md Open Question 1 — the `-p` flag and bare-invocation defaults are unverified because the binary wasn't installed during research. Plan must include a manual `quickshell --help` verification task before this exact invocation line is locked (standing constraint 2).

**Difference from waybar-launch.sh to note in the plan:** waybar-launch.sh has no logging (`>>"$LOG"`) at all and no binary-existence guard — it assumes waybar is installed and only guards the *layout* choice. `quickshell-launch.sh` is a stricter analog: D-06 explicitly requires binary + config existence guards AND startup/exit logging to `~/.cache`, because a headless root (D-02) that dies leaves zero other visible evidence.

---

### `hypr/.config/hypr/scripts/quickshell-doctor` (test, batch/CRUD-check gate)

**Analogs:** `hypr/.config/hypr/scripts/keybind-doctor` (full file, 200 lines, reproduced in full above) and `theme-engine/.config/theme-engine/theme-doctor` (same `check()` house style confirmed at lines 17-20).

**Shared house style to copy verbatim (from keybind-doctor lines 1-44):**
```bash
#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║              KEYBIND-DOCTOR (D-04)                    ║
# ║  Rerunnable regression gate: ...                       ║
# ╚══════════════════════════════════════════════════════╝
#
# Usage: keybind-doctor [path-to-keybinds.conf]
#   Defaults to ~/.config/hypr/config/keybinds.conf. An explicit path is
#   accepted so this gate can be pointed at a throwaway copy for a
#   regression self-test (a gate that cannot fail is not a gate).

set -uo pipefail

KEYBINDS_CONF="${1:-$HOME/.config/hypr/config/keybinds.conf}"

PASS=0
FAIL=0

check() {
    local desc="$1"
    local ok="$2"
    if [[ "$ok" == "0" ]]; then
        printf '  [PASS] %s\n' "$desc"
        PASS=$((PASS + 1))
    else
        printf '  [FAIL] %s\n' "$desc"
        FAIL=$((FAIL + 1))
    fi
}

echo "keybind-doctor — Hyprland keybind regression gate"
echo ""
```
And the closing summary (lines 196-199):
```bash
echo ""
echo "Summary: ${PASS} passed, ${FAIL} failed"
[[ "$FAIL" -eq 0 ]]
exit $?
```

**Elements `quickshell-doctor` must reproduce exactly:**
1. **Header comment block** stating: report-only where applicable, and (per D-14) *why* `hyprctl binds -j` is not used, so a future reader doesn't "helpfully restore" it — same discipline as keybind-doctor's own header stating it cross-checks compositor state, never the file alone.
2. **Path-argument self-test hook** (`${1:-<default-path>}`) — D-18 reuses this exact mechanism to point `keybind-doctor` at a poisoned fixture; `quickshell-doctor` should offer the analogous hook if it ever needs a poisoned `hyprctl`-output fixture, though its primary checks are live-system queries, not file-based, so this is lower priority than for keybind-doctor itself.
3. **`check()` helper** reused verbatim — every mechanical assertion (layer namespace, `reserved` array diff, D-Bus owner count, process-alive) becomes one `check "description" "$([[ cond ]] && echo 0 || echo 1)"` call.
4. **PASS/FAIL summary + exit code** — `[[ "$FAIL" -eq 0 ]]; exit $?` at the very end, identical to keybind-doctor.

**Mechanical checks this file must implement (RESEARCH.md, corrected schema — do NOT trust ROADMAP wording verbatim):**
```bash
# hyprctl layers -j — namespace/pid identity only, NOT exclusive-zone (no such field exists):
hyprctl layers -j | jq -r '.[].levels["3"][]? | select(.namespace=="quickshell-probe")'

# hyprctl monitors -j — THIS is where exclusive-zone reservation actually lives:
hyprctl monitors -j | jq -r '.[].reserved'   # e.g. [0, 46, 0, 0] — compare before/after quickshell autostart, not a single read

# busctl --user list — single Notifications owner:
busctl --user list | grep org.freedesktop.Notifications   # must show exactly one owner (swaync, confirmed pid 1014)
```
**Pitfall to avoid (RESEARCH.md Pitfall 1):** a check that greps `hyprctl layers -j` for an `"exclusive"` key will always silently pass — that field doesn't exist in this build's output. Diff `monitors -j`'s `reserved` array before/after instead.

**Placement (Claude's Discretion, D-05 canonical refs):** put in `hypr/.config/hypr/scripts/` alongside `keybind-doctor`/`theme-doctor`, NOT inside `quickshell/` — RESEARCH.md's own recommendation: "a gate that lives inside the surface it's grading is the weaker design," matching this repo's uniform precedent (`keybind-doctor`, `theme-doctor`, `waybar-equivalence-check` all live in `hypr/.config/hypr/scripts/`, not inside the packages they grade).

---

### `hypr/.config/hypr/scripts/keybind-doctor` (MODIFIED — MAINT-01, D-14/D-16/D-17/D-18)

**This is a targeted in-place repair, not a rewrite.** Exact block to replace is lines 137-194 (the "Cross-check against the compositor's ACTUAL registered state" section) — everything above it (lines 1-136: header, `check()`, mainMod resolution, tuple parsing, description parity, static `walker -s` grep) **already passes and must be left untouched.**

**Current broken block (lines 138-146) — the part that must be dropped:**
```bash
if command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    LIVE_JSON=$(hyprctl binds -j 2>/dev/null)
    ...
    LIVE_TUPLES=$(printf '%s' "$LIVE_JSON" | jq -r '.[] | "\(.modmask)|\(.key)|\(.keycode)|\(.release)"')
```
Replace `hyprctl binds -j` + `jq` parsing with plain-text `hyprctl binds` parsing (D-14). Per RESEARCH.md Pitfall 2, the plain-text block header token is NOT a constant `"bind"` string — it varies (`bind`, `bindl`, `bindle`, `bindr`, `bindm`, confirmed `bindel`→`bindle` reordering on this build). Parse blank-line-delimited blocks (`awk 'BEGIN{RS=""}'`) and treat the first line's token as a variable "block-type" whose letters encode flags, not a fixed prefix to strip. The remaining 8 fields per block (`modmask:`, `submap:`, `key:`, `keycode:`, `catchall:`, `description:`, `dispatcher:`, `arg:`) have a stable, correct field order — confirmed across all 78 blocks.

**Checks that must be preserved with equivalent semantics** (same `check "description" "..."` calls, same tuple-comparison logic, just fed from the new plain-text parse instead of the broken JSON):
1. `declared-vs-registered` (lines 149-158)
2. `no shadowing` (lines 160-174) — the `jq group_by` shadow-detection logic needs re-expressing against plain-text-derived tuples (bash associative array grouping, or feed the plain-text-parsed tuples back through `jq -R`/`jq -n` if that's simpler)
3. `release-bind inventory` (lines 176-185)
4. `D-03 kill-bind present` (lines 187-190) — `Super+Escape -> pkill walker`

**New addition (D-16/D-17):** cross-check Quickshell-claimed shortcuts against a declared manifest (fallback selected — quickshell 0.3.0 has no runtime `GlobalShortcut` introspection API per RESEARCH.md). The manifest lives in `quickshell/` per D-17 ("`quickshell/` ships an explicit list of the chords it owns") and should record `appid`+`name`, not just the key chord (RESEARCH.md Pitfall 4 — duplicate `appid`+`name` pairs can crash Quickshell).

**Record-why comment (D-14 requirement):** add a comment block at the top of the replaced section explaining field-misalignment was the root cause (not malformed JSON) so a future reader does not "restore" `-j` parsing — mirror the existing header comment's tone (lines 2-9) and the D-30/D-05 inline comments' style (e.g. lines 122, 125-130) already present in this file.

**Poisoned-fixture proof (D-18):** reuses the file's own existing path-argument hook (`KEYBINDS_CONF="${1:-...}"`, line 18) unchanged — no new mechanism needed. The plan's task is to author a throwaway fixture file with a colliding chord, run `keybind-doctor <fixture-path>`, confirm FAIL, then run against the real config and confirm PASS — same shape as `theme-doctor`'s poisoned-stylesheet precedent (confirmed present at `theme-engine/.config/theme-engine/theme-doctor` lines 17-20, same `check()`/`PASS`/`FAIL` house style).

---

### `stow.sh` (MODIFIED — `PACKAGES` array)

**Analog:** itself, lines 19-40 (already read in full).

**Exact insertion:** add `quickshell` to the alphabetically-ish-ordered `PACKAGES` array (lines 19-40). Current array:
```bash
PACKAGES=(
    ags
    elephant
    fastfetch
    fish
    gtk
    hypr
    kitty
    matugen
    swaync
    swayosd
    theme-engine
    thunar
    uwsm
    vscodium
    walker
    wallpapers
    waybar
    wleave
    yazi
    zshell
)
```
Insert `quickshell` between `matugen` and `swaync` (alphabetical position). No other stow.sh change is required — the generic `for pkg in "${PACKAGES[@]}"` loop (lines 71-78) and the `chmod +x "$HOME/.config/hypr/scripts/"*.sh` line (line 83) already cover any new package with the standard `.config/<pkg>/` layout; `quickshell-doctor` (no `.sh` extension, like `keybind-doctor`/`theme-doctor`) will need to be verified it's covered by the executable-bit step or made executable in the same commit (`keybind-doctor` itself has no `.sh` suffix and is `-rwxr-xr-x` in git — confirm mode bit is committed, not chmod'd by stow.sh, since stow.sh's chmod glob is `*.sh` only).

---

### `install.sh` (MODIFIED — `PACMAN_PKGS`)

**Analog:** itself, lines 52-134 (already read in full — `PACMAN_PKGS` array, `# Hyprland ecosystem` through `# Qt Wayland`/`# Misc` sections).

**Exact insertion:** add a new one-line entry, either its own `# Quickshell` comment block or folded into the existing `# Qt Wayland` section (lines 129-131, currently `qt5-wayland` + `qt6-wayland`):
```bash
    # Quickshell
    quickshell
```
Per RESEARCH.md: this is the **only** new line — do not hand-enumerate `qt6-base`/`qt6-declarative`/`qt6-svg`/`cpptrace` etc.; pacman's own dependency resolver (`sudo pacman -Sy --needed --noconfirm "${PACMAN_PKGS[@]}"`, line 359) pulls the full closure automatically. `AUR_PKGS` is untouched — not needed (RESEARCH.md, verified `pacman -Si quickshell` shows official `extra` repo).

---

### `hypr/.config/hypr/config/autostart.conf` (MODIFIED)

**Analog:** itself, full file (already read, 82 lines).

**Pattern to copy exactly** — every daemon follows `exec-once = uwsm app -- <cmd>` with a preceding comment block explaining ordering (e.g. lines 27-28, 39-40, 55-63):
```
# ── Quickshell (headless shell root, D-01/D-02) ──────
# Ships nothing visible in daily use — see quickshell-launch.sh's own
# guard comments. quickshell-doctor asserts this process stays alive.
exec-once = uwsm app -- ~/.config/hypr/scripts/quickshell-launch.sh
```
**Placement guidance:** insert after the status bar / fullscreen watcher block (after line 37) and before swaync (line 40) — matches D-21's "no exclusive-zone, no visible surface" positioning (order among headless/non-competing daemons is low-stakes, unlike the gaming-mode reset which the file's own comment (lines 12-24) explains must be early for state-correctness reasons). Do not place before the `exec-once = echo off > ~/.cache/gaming-mode` line (lines 12-25) — that placement is deliberately load-bearing per its own comment and must stay first.

---

### `hypr/.config/hypr/config/permissions.conf` (NEW, D-12 screencopy stanza)

**Analog:** the existing sourced-`.conf`-module convention already used by `keybinds.conf`/`windowrules.conf`/`autostart.conf` (all separately sourced from `hyprland.conf`, per RESEARCH.md's note: "most naturally a new sourced module in this repo's existing `hypr/.config/hypr/config/` split").

**Exact content (RESEARCH.md Code Examples, corrected — NOT a file named `ecosystem.conf`, which does not exist as a concept in 0.56.0):**
```
ecosystem {
    enforce_permissions = 1   # default is 0 (disabled/all-allowed) — must be set to 1 for allow/deny/ask modes to have any effect
}

# client_identifier is a path (can be a regex); type is currently only
# "screencopy" or "plugin"; mode is one of allow/deny/ask.
permission = /usr/bin/quickshell, screencopy, allow
```
**MUST verify before finalizing** (RESEARCH.md Open Question 2 / Assumption A2): confirm the exact binary path via `pacman -Ql quickshell | grep '/bin/'` once installed — do not assume `/usr/bin/quickshell` unverified. Use `allow` mode only (not `ask`) — sidesteps the unresolved `hyprland-guiutils` dependency question (Open Question 3), matches D-12's "feasibility-only" framing.
**Pitfall to flag in the plan (RESEARCH.md Pitfall 3):** this permission grant is NOT hot-reloadable — `hyprctl reload` will not pick it up; a full Hyprland session restart is required. Sequence this as an explicit manual plan step, not chained after a `reload` call.

---

### Evidence artifact — `.planning/phases/11-quickshell-viability-gate/*-EVIDENCE.md` (test, dated record)

**Analog:** `.planning/milestones/v2.0-phases/08-waybar-evolution/08-BAR-02-EVIDENCE.md` (full file read, 167 lines).

**Structural elements to copy:**
1. **Provenance header comment** (lines 1-5) — an HTML comment stating what plan/decision produced this file and what it's meant to be pasted into verbatim.
2. **Verdict line up top**, one of a small fixed vocabulary (that file uses `DESCOPED`; Phase 11's vocabulary per D-09/D-10 should be `PASS` / `STOP` for QS-02, and `record-and-continue` findings for everything else — do not invent new verdict words beyond what CONTEXT.md's decisions already name).
3. **Gate table** (lines 52-60) — one row per criterion, columns: `Gate | criterion (verbatim) | Method | Instrument | Raw result | PASS/FAIL`. Directly reusable shape for Phase 11's per-QS-requirement rows (QS-01..06, MAINT-01).
4. **"Which gate fired" narrative section** (lines 62-75) — prose explaining the decisive finding, distinguishing genuinely-decisive results from moot/skipped ones.
5. **"Reproduce" section at the end** (lines 149-166) — exact commands + raw-data file references, so any finding can be independently re-run. Phase 11's equivalent should cite the exact `hyprctl`/`busctl`/`quickshell-doctor` invocations.
6. **Dated PASS/FAIL lines accumulate over time** (per D-05/D-08: suspend/resume and screencopy are manual, hand-driven, appended-to-over-time entries) — this is the specific shape D-05 asks for beyond BAR-02's one-shot precedent: BAR-02 was a single dated verdict, Phase 11's evidence artifact must support *repeated* dated appends as `quickshell-doctor` reruns across Phases 14-16.

**Filename/format:** left to Claude's Discretion per CONTEXT.md — follow the `NN-SLUG-EVIDENCE.md` naming convention (`08-BAR-02-EVIDENCE.md` → e.g. `11-QUICKSHELL-EVIDENCE.md` or per-requirement files), provided every entry carries a dated PASS/FAIL line per criterion.

## Shared Patterns

### Rerunnable gate script house style
**Source:** `hypr/.config/hypr/scripts/keybind-doctor` (lines 1-44, 196-199), confirmed also in `theme-engine/.config/theme-engine/theme-doctor` (lines 17-20)
**Apply to:** `quickshell-doctor` (new), `keybind-doctor` (modified)
```bash
set -uo pipefail
PASS=0
FAIL=0
check() {
    local desc="$1" ok="$2"
    if [[ "$ok" == "0" ]]; then
        printf '  [PASS] %s\n' "$desc"; PASS=$((PASS + 1))
    else
        printf '  [FAIL] %s\n' "$desc"; FAIL=$((FAIL + 1))
    fi
}
# ... individual check "..." "$([[ cond ]] && echo 0 || echo 1)" calls ...
echo ""
echo "Summary: ${PASS} passed, ${FAIL} failed"
[[ "$FAIL" -eq 0 ]]
exit $?
```

### Guarded launcher shape
**Source:** `hypr/.config/hypr/scripts/waybar-launch.sh` (full file)
**Apply to:** `quickshell-launch.sh`
```bash
set -uo pipefail   # never -e — the script ends in exec; a transient failure must not abort silently
# ... resolve state/paths as local vars ...
# ... guard checks (existence, validity) — fall back or skip-and-log, never hard-crash ...
exec <real-binary> <args>
```

### Uniform autostart registration
**Source:** `hypr/.config/hypr/config/autostart.conf` (all 11 existing `exec-once` lines)
**Apply to:** the new `quickshell-launch.sh` autostart line
```
exec-once = uwsm app -- <script-or-binary>
```
Always preceded by a comment block naming the daemon and any ordering rationale.

### Path-argument-as-text discipline (security control, V5 Input Validation)
**Source:** `hypr/.config/hypr/scripts/keybind-doctor` line 18 (`KEYBINDS_CONF="${1:-$HOME/.config/hypr/config/keybinds.conf}"`) and its comment (lines 69-71: "every parsed field here is handled as display/arithmetic-only text, never fed to a shell-command-interpretation builtin")
**Apply to:** `quickshell-doctor`'s own path-argument handling if added, and any QML `FileView` consuming `~/.local/state/quickshell/*.json` — never `eval`/`source` a fixture- or user-supplied path/value.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| `quickshell/.config/quickshell/shell.qml` | component | event-driven | No existing QML anywhere in this repo (first Quickshell surface). Plan must follow the version-matched official-docs conventions extracted above (RESEARCH.md Patterns 1-3), not a codebase analog. |
| `quickshell/.config/quickshell/modules/Probe.qml` | component | event-driven | Same reason as `shell.qml` above. |

## Metadata

**Analog search scope:** `hypr/.config/hypr/scripts/`, `hypr/.config/hypr/config/`, `theme-engine/.config/theme-engine/`, `stow.sh`, `install.sh`, `.planning/milestones/v2.0-phases/08-waybar-evolution/`
**Files scanned:** `waybar-launch.sh`, `keybind-doctor` (full), `theme-doctor` (partial — house-style confirmation only), `theme-parity` (located, not deep-read — same family), `waybar-equivalence-check`, `waybar-design-lint` (located, not deep-read — precedent for D-05's "seventh gate script" framing), `autostart.conf` (full), `stow.sh` (full), `install.sh` (lines 45-135), `08-BAR-02-EVIDENCE.md` (full)
**Pattern extraction date:** 2026-07-26
