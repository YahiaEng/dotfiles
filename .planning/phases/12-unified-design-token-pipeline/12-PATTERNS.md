# Phase 12: Unified Design-Token Pipeline - Pattern Map

**Mapped:** 2026-07-26
**Files analyzed:** 21 (10 new, 11 modified)
**Analogs found:** 21 / 21

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `theme-engine/.config/theme-engine/lib/motion.sh` (NEW) | service/utility (theme-orthogonal axis writer) | transform (state-file read → clamp/scale transform → multi-format write) | `theme-engine/.config/theme-engine/lib/font.sh` | exact |
| `theme-engine/.config/theme-engine/motion.json` (NEW) | config/data (hand-authored token source) | — (static data) | `theme-engine/.config/theme-engine/contract.json` (shape/structure only, not content) | role-match |
| `~/.local/state/theme/motion.json` (rendered, QML target) | rendered output | transform | existing `~/.local/state/theme/vscodium.json` (json format, `contract.sh`'s `json` branch) | exact |
| `~/.local/state/theme/gtk-4.0-motion.css` (rendered, GTK4 target) | rendered output | transform | existing `~/.local/state/theme/gtk-4.0-colors.css` (gtk-css format) — but see Gap below, custom-property shape differs | role-match |
| `~/.local/state/theme/hyprland-motion.conf` (rendered, Hyprland target) | rendered output | transform | existing `~/.local/state/theme/hyprland.conf` (hypr-vars format) — but see Gap below, native `bezier=`/`animations{}` shape differs | role-match |
| `~/.local/state/theme/motion-scale` (NEW engine-owned state file) | state/config | CRUD (read/write single value) | `~/.local/state/theme/font-choice` / `current-theme` / `mode` | exact |
| motion lint script (NEW, e.g. `hypr/.config/hypr/scripts/motion-lint`) | test/gate (rerunnable static-analysis gate) | batch (scan files, report) | `hypr/.config/hypr/scripts/waybar-design-lint` | exact |
| poisoned/compliant fixture pairs (NEW, per target) | test fixture | file-I/O (static committed files) | `theme-doctor`'s poisoned stylesheet fixture + `keybind-doctor`'s path-argument self-test hook | exact |
| `quickshell/.config/quickshell/modules/qmldir` (NEW) | config (module manifest) | — (static declaration) | none in-repo (does not exist yet) — pattern from Quickshell docs, not a repo analog | no analog |
| `quickshell/.config/quickshell/modules/Colours.qml` (NEW) | provider/store (QML Singleton) | streaming (FileView watch → JsonAdapter in-place property update) | `quickshell/.config/quickshell/modules/Probe.qml`'s existing `FileView`/`JsonAdapter` block (lines 54-65) | role-match (same mechanism, different root type — `Singleton` vs `PanelWindow`) |
| `quickshell/.config/quickshell/modules/Motion.qml` (NEW) | provider/store (QML Singleton) | streaming | same as `Colours.qml` above — sibling file, identical pattern | role-match |
| `theme-engine/.config/theme-engine/lib/generate.sh` (MODIFIED) | service (orchestration) | transform | itself — `theme_engine_render_font_files`/`theme_engine_render_gtk_settings` call sites | exact |
| `theme-engine/.config/theme-engine/lib/commit.sh` (MODIFIED) | service (atomic commit) | file-I/O (rsync) | itself — existing `--exclude` list + comment block | exact |
| `theme-engine/.config/theme-engine/contract.json` (MODIFIED) | config/manifest | — | itself | exact |
| `theme-engine/.config/theme-engine/lib/contract.sh` (MODIFIED — new format branches) | utility (format dispatch) | transform (extract names/values per format) | itself — `gtk-css`/`hypr-vars`/`json` `case` branches in `contract_extract_names`/`contract_extract_values` | exact |
| `theme-engine/.config/theme-engine/theme-parity` (MODIFIED) | test/gate | batch (hash/structural compare) | itself — existing byte-identity/parity assertions | exact |
| `theme-engine/.config/theme-engine/theme-doctor` (MODIFIED) | test/gate | batch | itself — `waybar-design-lint` fold (lines 475-494) is the direct precedent for folding in the motion lint; readback check is new (`hyprctl animations -j`) | exact |
| `theme-engine/.config/theme-engine/theme-stress-test` (MODIFIED) | test/gate | batch (N consecutive switches) | itself — existing 10-switch loop | exact |
| `theme-engine/.config/theme-engine/lib/gtk.sh` (MODIFIED — GSettings block) | service | request-response (gsettings set calls) | itself — existing `gsettings set org.gnome.desktop.interface ...` lines | exact |
| `hypr/.config/hypr/config/animations.conf` (MODIFIED) | config | — | itself | exact |
| `hypr/.config/hypr/hyprland.conf` (MODIFIED — new `source =` line) | config | — | itself — existing `source =` list + theme-colors `source =` line | exact |
| `hypr/.config/hypr/scripts/quickshell-doctor` (MODIFIED, D-14 SKIP branch) | test/gate | batch | itself — existing `--no-headless-output`/missing-tool SKIP branches (lines 392-406) | exact |
| `quickshell/.config/quickshell/shell.qml` (MODIFIED) | provider (shell root / fan-out) | event-driven (GlobalShortcut → LazyLoader) | itself | exact |
| `quickshell/.config/quickshell/modules/Probe.qml` (REWRITE → inspector) | component (QML panel) | event-driven + streaming | itself (current probe) | exact |
| `wleave/.config/wleave/style.css` (MODIFIED, D-19 retrofit) | stylesheet | transform (CSS custom properties) | itself — `md3_decel` hand-copy comment block (~470-520) and hover-transition shorthand (~226-230) | exact |
| `stow.sh` (MODIFIED, seed motion files) | install script | file-I/O (seed-when-absent) | itself — `waybar-visibility.css` seed (lines 112-120) | exact |
| `matugen/.config/matugen/config.toml` (MODIFIED, +QML JSON palette target) | config | — | itself — `[templates.vscodium]` entry (json output, closest existing json target) | exact |

## Pattern Assignments

### `theme-engine/.config/theme-engine/lib/motion.sh` (NEW)

**Analog:** `theme-engine/.config/theme-engine/lib/font.sh` (54 lines, read in full)

**Header comment convention** (font.sh lines 1-16) — copy this shape exactly, substituting motion's specifics:
```bash
#!/usr/bin/env bash
# theme-engine/lib/font.sh — nerd-font theme-orthogonal state axis (UTIL-05, D-18/D-19)
#
# Font choice is independent of theme identity (D-19): its own state file
# under $STATE_DIR, excluded from commit.sh's rsync --delete (same pattern
# as last-wallpaper/), read here and re-rendered on EVERY theme-apply run
# regardless of which theme/mode is active.
```
`motion.sh`'s header must state the same four guarantees for motion: own state file (`motion-scale`), excluded from `commit.sh --delete`, re-rendered every run regardless of theme, and (new) a render-time clamp/transform per D-09.

**State-file constant + reader function** (font.sh lines 18-26):
```bash
FONT_STATE_FILE="$HOME/.local/state/theme/font-choice"
FONT_DEFAULT="FiraCode Nerd Font"

theme_engine_read_font() {
    cat "$FONT_STATE_FILE" 2>/dev/null || echo "$FONT_DEFAULT"
}
```
`motion.sh` copies this shape but the reader must validate against the closed D-21 name set with a `case` statement (`off|reduced|normal|lively`), not accept an arbitrary string like `theme_engine_read_font` does — see D-21's explicit "validates itself with a `case` statement" requirement. Example:
```bash
MOTION_STATE_FILE="$HOME/.local/state/theme/motion-scale"
MOTION_DEFAULT="normal"
theme_engine_read_motion_scale() {
    local v
    v="$(cat "$MOTION_STATE_FILE" 2>/dev/null || echo "$MOTION_DEFAULT")"
    case "$v" in
        off|reduced|normal|lively) echo "$v" ;;
        *) echo "$MOTION_DEFAULT" ;;
    esac
}
```

**Render function signature + call shape** (font.sh lines 28-53) — takes `<tmp_dir>`, writes into `$tmp$STATE_DIR`, called from `generate.sh`:
```bash
theme_engine_render_font_files() {
    local tmp="$1"
    local font_name
    font_name="$(theme_engine_read_font)"
    local out_dir="$tmp$STATE_DIR"
    mkdir -p "$out_dir"
    printf '...' "$font_name" > "$out_dir/kitty-font.conf"
    printf '...' "$font_name" > "$out_dir/waybar-font.css"
}
```
`motion.sh`'s `theme_engine_render_motion_files "$tmp"` follows this exact signature/shape, writing three files (`motion.json`, `gtk-4.0-motion.css`, `hyprland-motion.conf`) into the same `out_dir`, using `printf`/heredoc, not matugen. RESEARCH.md's Pattern 1 code sketch (motion.sh section, lines ~612-692 of 12-RESEARCH.md) is the illustrative implementation shape — treat it as a sketch, not a locked implementation; the planner owns exact `jq` filter correctness and must add D-09's **warning** surfaced to `GENERATE_LOG` on every clamp event (the sketch clamps silently, which the locked decision forbids).

---

### `theme-engine/.config/theme-engine/lib/generate.sh` (MODIFIED)

**Analog:** itself — existing non-matugen writer call sites

**Integration point** (generate.sh lines 84-91):
```bash
    theme_engine_render_gtk_settings "$mode" "$tmp"

    # UTIL-05/D-19: font-choice is re-rendered on EVERY run regardless of
    # which theme/mode is active (independent axis, same call-site shape as
    # the gtk-settings render right above it).
    theme_engine_render_font_files "$tmp"

    return 0
}
```
Add `theme_engine_render_motion_files "$tmp"` as a third call here, with a comment matching the font-files comment's shape ("re-rendered on EVERY run regardless of theme/mode — third theme-orthogonal axis"). Also add `source "$LIB_DIR/motion.sh"` near the top (generate.sh line 29 sources `lib/font.sh` the same way):
```bash
# shellcheck source=lib/font.sh
source "$LIB_DIR/font.sh"
```

---

### `theme-engine/.config/theme-engine/lib/commit.sh` (MODIFIED)

**Analog:** itself — the `--exclude` flag list and its comment block

**Current exclude list** (commit.sh lines 94-99):
```bash
    rsync -a --delete --exclude=logs/ --exclude=last-wallpaper/ \
        --exclude=current-theme --exclude=.last-render-error.log \
        --exclude=icon-theme --exclude=font-choice \
        --exclude=walker-relaunch.log \
        --exclude=waybar-visibility.css \
        "$rendered_dir"/ "$STATE_DIR"/
```
Every prior addition (lines 31-93) documents WHY as a numbered occurrence of the same bug class ("CR-01 (same bug class, third occurrence)", "WR-02", "UTIL-04/D-19", "WR-06 (sixth occurrence)", "08-12 (seventh occurrence)"). D-29 changes the mechanism: instead of an 8th hardcoded `--exclude=motion-scale`, build the `--exclude` flags from `contract.json`'s new `engine_owned_files` array (a loop generating `--exclude=$f` per entry) so the excludes and D-29's gate read one source of truth. Comment block must record this as occurrence #8 in the same numbered style before switching mechanisms, per D-29's own reasoning ("adding a file fixes both at once").

---

### `theme-engine/.config/theme-engine/contract.json` (MODIFIED)

**Analog:** itself (23-line file, full structure below)

```json
{
  "files": [
    { "name": "hyprland.conf", "format": "hypr-vars", "exempt_keys": ["image"] },
    { "name": "waybar.css", "format": "gtk-css" },
    ...
  ],
  "state_metadata_files": ["current-theme", "mode"],
  "presence_only_files": ["kitty-font.conf", "waybar-font.css"]
}
```
Per D-03, add three new **full** `files` entries (not `presence_only_files`):
```json
{ "name": "motion.json", "format": "json" },
{ "name": "gtk-4.0-motion.css", "format": "motion-gtk-css" },
{ "name": "hyprland-motion.conf", "format": "motion-hypr" }
```
(format tag names are Claude's Discretion — `motion-gtk-css`/`motion-hypr` proposed so `contract.sh`'s `case` dispatch can add dedicated branches without touching the existing `gtk-css`/`hypr-vars` branches used by colour files — see Gap below for why reuse is unsafe.)

Per D-29, add a new top-level array:
```json
"engine_owned_files": [
  "logs", "last-wallpaper", "current-theme", ".last-render-error.log",
  "icon-theme", "font-choice", "walker-relaunch.log", "waybar-visibility.css",
  "motion-scale"
]
```
This array is consumed by `commit.sh`'s exclude-flag builder AND by a new gate (in `theme-doctor` or `theme-parity`) asserting every file under `$STATE_DIR` is either a `files[].name` or an `engine_owned_files` entry.

---

### `theme-engine/.config/theme-engine/lib/contract.sh` (MODIFIED — new format branches)

**Analog:** itself — `contract_extract_names`/`contract_extract_values` `case` dispatch (full file read, 256 lines)

**GAP CONFIRMED (RESEARCH.md finding 3):** the existing `gtk-css` branch only matches `@define-color` —
```bash
gtk-css)
    grep -oP '@define-color \K\S+' "$path" 2>/dev/null | sort -u
    ;;
```
— and `hypr-vars` only matches `^\$name = value`:
```bash
hypr-vars)
    grep -oP '^\$\K[A-Za-z_][A-Za-z0-9_]*(?= =)' "$path" 2>/dev/null | sort -u
    ;;
```
Neither pattern exists in a `--motion-*:` CSS custom-property file or a native `bezier =`/`animations {}` Hyprland fragment — both would silently extract zero names, and `theme-parity`'s own "Refuse an empty reference name-set" design turns that into a guaranteed FAIL, not a silent pass, but it's the WRONG failure (structural mismatch reported as "empty" rather than validated content). Two new `case` branches are needed in **both** `contract_extract_names` and `contract_extract_values`, added alongside the existing branches (same `case ... esac` structure, same `2>/dev/null | sort -u` error-handling discipline, same CR-01 "unknown format must be loud" fallback at the bottom):

```bash
motion-gtk-css)
    # --motion-duration-*/--motion-easing-* custom properties inside :root {}
    grep -oP -- '--motion-[a-z-]+(?=:)' "$path" 2>/dev/null | sort -u
    ;;
```
```bash
motion-hypr)
    # native bezier = name, ... lines inside animations {} (D-05/D-22 shape)
    grep -oP '^\s*bezier\s*=\s*\K[A-Za-z0-9_-]+(?=,)' "$path" 2>/dev/null | sort -u
    ;;
```
Matching `contract_extract_values` branches follow the same `sed -nE` capture-group idiom used by `gtk-css`'s value extractor (line 157: `s/@define-color[[:space:]]+([A-Za-z0-9_]+)[[:space:]]+(.*);.*/\1\t\2/p`) and `hypr-vars`'s (line 162), producing `name<TAB>value` pairs for the motion custom-property/bezier lines respectively. The `json` format (used by the QML target, `motion.json`) needs no new branch — D-03 confirms `contract.sh` already handles `json` via `jq -r '.. | objects | keys[]'` (line 112) / the `paths(scalars)` walk (line 205).

---

### `theme-engine/.config/theme-engine/theme-doctor` (MODIFIED)

**Analog:** itself — `waybar-design-lint` fold (lines 475-494)

```bash
WAYBAR_DESIGN_LINT="$HOME/.config/hypr/scripts/waybar-design-lint"
if [[ -x "$WAYBAR_DESIGN_LINT" ]]; then
    while IFS= read -r _dl_line; do
        case "$_dl_line" in
            *"[PASS]"*) check "design-lint: ${_dl_line#*\[PASS\] }" "0" ;;
            *"[FAIL]"*) check "design-lint: ${_dl_line#*\[FAIL\] }" "1" ;;
        esac
    done < <("$WAYBAR_DESIGN_LINT" 2>/dev/null)
else
    echo "  [SKIP] waybar-design-lint ($WAYBAR_DESIGN_LINT not found or not executable)"
fi
```
The motion-lint fold copies this exact shape verbatim (same variable-naming convention `MOTION_LINT="$HOME/.config/hypr/scripts/motion-lint"`, same `[[ -x ]]` guard, same PASS/FAIL line-prefix parsing into `check()`). Add alongside it a NEW readback check (D-02b) using `hyprctl animations -j` (verified well-formed, `jq`-parses cleanly per RESEARCH — element `[1]` carries `name, X0, Y0, X1, Y1`):
```bash
if command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    _readback=$(hyprctl animations -j 2>/dev/null | jq -e '.[1][] | select(.name=="motion-standard")')
    check "hyprctl animations readback: motion-standard control points match emitted values" "$?"
else
    echo "  [SKIP] hyprctl animations readback (hyprctl or jq not found)"
fi
```

**`check()` helper convention** (shared across `theme-doctor`/`waybar-design-lint`/`keybind-doctor` — identical in all three):
```bash
check() {
    local desc="$1"
    local ok="$2"
    if [[ "$ok" == "0" ]]; then
        echo "  [PASS] $desc"; PASS=$((PASS + 1))
    else
        echo "  [FAIL] $desc"; FAIL=$((FAIL + 1))
    fi
}
```
Any new script (the motion lint itself) must define this exact function.

---

### Motion lint script (NEW)

**Analog:** `hypr/.config/hypr/scripts/waybar-design-lint` (353 lines, header + CHECK A/D read in full) — CHECK A is the reference-resolution precedent (D-24), CHECK D is the no-raw-literals precedent (D-23).

**Header/usage block convention** (lines 1-40):
```bash
#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║           WAYBAR-DESIGN-LINT (08-11 CORRECTION)       ║
# ║  Rerunnable design/token gate for the waybar redesign  ║
# ║  (plans 08-12..08-15). Report-only — never mutates any ║
# ║  file. Exits nonzero if ANY check FAILs.               ║
# ╚══════════════════════════════════════════════════════╝
...
# Usage:
#   waybar-design-lint [waybar-dir]
#       Defaults to ~/.config/waybar. Never runs waybar, never edits
#       anything — pure read-only analysis.

set -uo pipefail
WAYBAR_DIR="${1:-$HOME/.config/waybar}"
RENDERED_WAYBAR_CSS="$HOME/.local/state/theme/waybar.css"
PASS=0
FAIL=0
```
Copy exactly, substituting a `TARGET_DIR="${1:-...}"` path argument per D-28's fixture-pointing precedent (see keybind-doctor below).

**CHECK A — reference resolution** (lines 184-192, the exact D-24 precedent):
```bash
for f in css_files:
    body = strip_css_comments(open(f, encoding='utf-8').read())
    refs = set(re.findall(r'@([A-Za-z_][A-Za-z0-9_-]*)', body)) - AT_RULE_KEYWORDS
    unresolved = sorted(refs - defined_all)
    if unresolved:
        emit('A', 'FAIL', f'{rel(f)}: unresolved colour token(s): {", ".join(unresolved)}')
    else:
        emit('A', 'PASS', f'{rel(f)}: all referenced token(s) resolve ({len(refs)} ref(s))')
```
(This file is a hybrid bash-header/python-body script — `waybar-design-lint` shells out to an embedded Python block for its regex/CSS-parsing checks; the motion lint should follow the same hybrid shape if raw bash regex proves awkward for parsing `var(--motion-*)` refs across three dialects.) The motion lint's reference-resolution check must build `defined_all` from the emitted `--motion-*`/bezier-name/JSON-key set per target and flag any `var(--motion-x)` / `Motion.x` / `bezier=...,x` reference not in that set — this is D-24's "every token reference resolves" half.

**CHECK D — no raw literals** (lines 228-238, the exact D-23 precedent):
```bash
hex_re = re.compile(r'#[0-9a-fA-F]{6}\b|#[0-9a-fA-F]{3}\b')
d_targets = sorted(glob.glob(...)) + sorted(glob.glob(...))
for f in d_targets:
    raw = open(f, encoding='utf-8').read()
    body = strip_css_comments(raw) if f.endswith('.css') else strip_jsonc_comments(raw)
    hits = hex_re.findall(body)
    if hits:
        emit('D', 'FAIL', f'{rel(f)}: literal hex colour(s) found: {", ".join(sorted(set(hits)))}')
```
Motion lint's raw-value check swaps the regex for a duration/easing-literal pattern (e.g. `\d+m?s\b` outside a `var(--motion-` context, or a bare `cubic-bezier(...)` not sourced from a token) — same comment-stripping discipline, same FAIL-message shape citing the exact file and matched literal(s).

**Exemption list (D-23):** format/location is Claude's Discretion — model it on `waybar-design-lint`'s own `AT_RULE_KEYWORDS` exclusion set (a simple set literal near the top of the script) but each entry must carry an inline reason string, since D-23 requires "each exemption records its reason."

---

### Poisoned/compliant fixture pairs (NEW, per target)

**Analog 1 — path-argument self-test hook:** `hypr/.config/hypr/scripts/keybind-doctor` (lines 1-33 read in full)
```bash
# Usage: keybind-doctor [path-to-keybinds.conf]
#   Defaults to ~/.config/hypr/config/keybinds.conf. An explicit path is
#   accepted so this gate can be pointed at a throwaway copy for a
#   regression self-test (a gate that cannot fail is not a gate).
set -uo pipefail
KEYBINDS_CONF="${1:-$HOME/.config/hypr/config/keybinds.conf}"
```
The motion lint (and any per-target readback check) must accept an optional path argument the exact same way, so `motion-lint /path/to/fixtures/poisoned-gtk.css` is a first-class, committed, rerunnable self-test rather than a one-time manual poisoning of a real file (D-28's explicit reasoning: "Zero risk to live config and rerunnable forever").

**Analog 2 — poisoned stylesheet precedent:** `theme-doctor`'s existing poisoned-fixture usage (referenced in CONTEXT.md D-28; confirm exact fixture path/name via `grep -rn poison theme-engine/.config/theme-engine/` at implementation time — not directly read this pass, budget-bounded). Fixture pairs should be committed under a `fixtures/` (or similarly named, Claude's-Discretion per CONTEXT.md) subdirectory alongside the lint script, one poisoned + one compliant file per target (GTK4 CSS, Hyprland conf, QML JSON), each poisoned fixture derived from the real compliant rules with exactly one value corrupted, per D-28's "derived from the real compliant rules" requirement.

---

### `quickshell/.config/quickshell/modules/Colours.qml` and `Motion.qml` (NEW)

**Analog:** `quickshell/.config/quickshell/modules/Probe.qml` lines 54-65 (existing working `FileView`/`JsonAdapter` precedent in this exact repo, already proven live in Phase 11)

```qml
FileView {
    id: probeState
    path: Quickshell.env("HOME") + "/.local/state/quickshell/probe.json"
    watchChanges: true
    onFileChanged: reload()
    onAdapterUpdated: writeAdapter()

    JsonAdapter {
        id: probeAdapter
        property string label: "unset"
    }
}
```
`Colours.qml`/`Motion.qml` reuse `watchChanges: true` + `onFileChanged: reload()` but must OMIT `onAdapterUpdated: writeAdapter()` — the new singletons are read-only consumers of matugen/`motion.sh`-rendered state (`~/.local/state/theme/{palette,motion}.json`), never writers; `writeAdapter()` in `Probe.qml` exists only because that file is the hand-editable QS-02 instrument. Root type changes from `PanelWindow` (Probe.qml) to `Singleton` (exported `Quickshell/Singleton 0.0`, verified no `pragma Singleton`/`qmldir` singleton declaration needed — RESEARCH.md `[VERIFIED]`).

**RESEARCH.md's proposed code** (already drafted, treat as the concrete starting shape, not a locked file):
```qml
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    readonly property FileView paletteFile: FileView {
        path: Quickshell.env("HOME") + "/.local/state/theme/palette.json"
        watchChanges: true
        onFileChanged: reload()
        JsonAdapter {
            id: palette
            property string primary: "#FF00FF"
            // ... one property per matugen key, full 17-role set per UI-SPEC
        }
    }
    readonly property alias primary: palette.primary
    // ... one readonly alias per role
}
```
Same pattern for `Motion.qml`, sourcing `motion.json` instead, exposing `motionEnabled`, semantic duration/bezier properties. UI-SPEC's D-11 fallback contract applies: missing/malformed key → `#FF00FF` (debug magenta), never black/white.

---

### `quickshell/.config/quickshell/modules/qmldir` (NEW)

**No repo analog** — this file does not exist anywhere in the repo today (RESEARCH.md confirms: "No `qmldir` file exists on disk in `quickshell/.config/quickshell/modules/`"). D-12 targets this as the FM1 fix; RESEARCH.md finding 4 cites `[CITED: DeepWiki]` that an explicit `qmldir` disables Quickshell's scanner for that directory entirely, replacing racy synthesis with static resolution. Content is a standard Quickshell/QML module manifest listing every `.qml` file in `modules/` (`Probe 1.0 Probe.qml`, `Colours 1.0 Colours.qml`, `Motion 1.0 Motion.qml`, plus `ScreencopyProbe` per `shell.qml`'s existing import) — no in-repo precedent to copy line-shape from; follow Quickshell's documented `qmldir` grammar (`module <name>` header line + `<Type> <version> <File.qml>` entries).

---

### `wleave/.config/wleave/style.css` (MODIFIED, D-19 retrofit)

**Analog:** itself — three retrofit points already located

**Retrofit point 1 — hover transition, currently uses the shorthand** (lines ~226-230):
```css
button:hover,
button:focus {
    transform: scale(1.06);
    transform-origin: center;
    transition:
        background-color 150ms ease,
        border-color 150ms ease,
        box-shadow 150ms ease,
        transform 200ms cubic-bezier(0.55, 0, 0.28, 1.68);
}
```
**GAP CONFIRMED (RESEARCH.md finding 2):** the `transition:` shorthand silently mis-parses when ANY comma-separated item uses `var(--x)` on this exact GTK 4.22.4 build — every item collapses into one raw string duplicated across all four longhand properties. This retrofit MUST switch to four explicit longhand `transition-property`/`transition-duration`/`transition-timing-function`/`transition-delay` declarations with comma-aligned value lists, e.g.:
```css
transition-property: background-color, border-color, box-shadow, transform;
transition-duration: var(--motion-duration-standard), var(--motion-duration-standard), var(--motion-duration-standard), var(--motion-duration-standard);
transition-timing-function: ease, ease, ease, var(--motion-easing-standard);
```
(the hover-overshoot curve on `transform` itself stays a hand-authored literal per D-19/UI-SPEC — "out of scope this phase.")

**Retrofit point 2 — `capsule-entrance` hand-copy comment block** (lines ~559-562, exact drift D-19 targets):
```css
button {
    animation-name: capsule-entrance;
    animation-duration: 300ms;
    animation-timing-function: cubic-bezier(0.05, 0.7, 0.1, 1); /* md3_decel */
    animation-fill-mode: backwards;
}
```
Retrofit to `animation-duration: var(--motion-duration-emphasized-in); animation-timing-function: var(--motion-easing-emphasized-decelerate);` per UI-SPEC's semantic-pair mapping table.

**Retrofit point 3 — 150ms opacity/transform exit transition** (referenced near line 455 in UI-SPEC, not directly located this pass — grep `transition.*150ms` at implementation time) maps to `var(--motion-duration-emphasized-out)` / `var(--motion-easing-emphasized-accelerate)`.

**`:root {}` custom-property block** must be `@import`ed the same way `wleave.css`'s existing colour target is wired — confirm the exact `@import` mechanism by reading `wleave/.config/wleave/style.css`'s top-of-file imports at implementation time (not captured in this pass).

---

### `stow.sh` (MODIFIED, seed motion files when absent)

**Analog:** itself — `waybar-visibility.css` seed (lines 112-120)

```bash
# BAR-01/D-03/D-06: seed the visibility owner's exclusive CSS override
# file empty, same seed-only-when-absent idiom as above — every
# style-{full,athena,floating,vertical}.css @imports this file LAST, and an
# unresolvable @import makes GTK3 discard the WHOLE stylesheet. Never
# unconditional: waybar-visibility.sh (the sole writer) may have a live
# idle-dim rule in here already on a stow.sh re-run, and clobbering it
# would desync the owner's actuated state from what's on screen.
mkdir -p "$HOME/.local/state/theme"
[[ -f "$HOME/.local/state/theme/waybar-visibility.css" ]] || : > "$HOME/.local/state/theme/waybar-visibility.css"
```
D-30's motion seed differs in one respect: instead of seeding an empty stub, it must **invoke `motion.sh`** to generate real content (a missing sourced Hyprland file or undefined `$motion_enabled` is a hard config-parse error, unlike an empty CSS `@import` target which merely no-ops). Follow the same `[[ -f ... ]] ||` guard shape, but the seed body becomes a call into the sourced `motion.sh` functions rather than a bare `: >`. Also mirror the simpler pattern at lines 100-108 (`current-waybar-layout`, `gaming-mode` — plain single-value seeds) for the `motion-scale` state file itself:
```bash
[[ -f "$HOME/.cache/gaming-mode" ]] || echo "off" > "$HOME/.cache/gaming-mode"
```
→ `[[ -f "$HOME/.local/state/theme/motion-scale" ]] || echo "normal" > "$HOME/.local/state/theme/motion-scale"`.

---

### `matugen/.config/matugen/config.toml` (MODIFIED — QML JSON palette target)

**Analog:** itself — `[templates.vscodium]` entry (closest existing JSON-format target)

```toml
# ── VSCodium colors ─────────────────────────────────
[templates.vscodium]
input_path = "~/.config/matugen/templates/vscodium-colors.json"
output_path = "~/.local/state/theme/vscodium.json"
```
New entry follows the exact same two-line shape plus the file's established comment-banner convention (`# ── <Name> colors ──...`):
```toml
# ── QML palette (Quickshell Colours.qml singleton, D-11) ────
[templates.qml]
input_path = "~/.config/matugen/templates/qml-palette.json"
output_path = "~/.local/state/theme/palette.json"
```
Note: motion targets are NOT added here — `motion.sh` (not matugen) renders `motion.json`/`gtk-4.0-motion.css`/`hyprland-motion.conf` per D-01's explicit rejection of the matugen `--import-json` route.

---

### `hypr/.config/hypr/hyprland.conf` (MODIFIED — motion `source =` line placement)

**Analog:** itself — existing `source =` list (lines 6-16)

```
source = ~/.config/hypr/config/env.conf
source = ~/.config/hypr/config/monitors.conf
source = ~/.config/hypr/config/autostart.conf
source = ~/.config/hypr/config/animations.conf
source = ~/.config/hypr/config/keybinds.conf
source = ~/.config/hypr/config/windowrules.conf
source = ~/.config/hypr/config/permissions.conf

# Source theme colors (theme-engine state-dir contract, D-06)
source = ~/.local/state/theme/hyprland.conf
```
Per D-22, the motion `source =` line for `~/.local/state/theme/hyprland-motion.conf` goes **BEFORE** the `animations.conf` line (line 9 above), not beside the colour `source =` line at 16, because curves must be defined before `animation =` lines reference them and `animations.conf`'s own block will read `enabled = $motion_enabled` (which the motion file must define first).

### `hypr/.config/hypr/config/animations.conf` (MODIFIED)

**Analog:** itself (45 lines, full file read)

Current top:
```
animations {
    enabled = true
    bezier = wind, 0.05, 0.9, 0.1, 1.05
    ...
```
Per D-22, `enabled = true` becomes `enabled = $motion_enabled` (variable substitution, same mechanism already used for `$primary`/`$secondary`/`$outline` colour variables elsewhere in `hyprland.conf`'s `general { }` block — e.g. `col.active_border = $primary $secondary $tertiary 45deg`). The 12 hand-authored `bezier =` lines and 14 `animation =` lines are UNCHANGED this phase (D-04).

---

## Shared Patterns

### Rerunnable gate `check()` helper
**Source:** `hypr/.config/hypr/scripts/waybar-design-lint` lines 46-56 / `hypr/.config/hypr/scripts/keybind-doctor` lines 23-33 (byte-identical convention in both)
**Apply to:** motion-lint (new), any readback additions to theme-doctor
```bash
check() {
    local desc="$1"
    local ok="$2"
    if [[ "$ok" == "0" ]]; then
        echo "  [PASS] $desc"
        PASS=$((PASS + 1))
    else
        echo "  [FAIL] $desc"
        FAIL=$((FAIL + 1))
    fi
}
```

### Guarded-SKIP degrade pattern
**Source:** `hypr/.config/hypr/scripts/quickshell-doctor` lines 392-406, `theme-doctor` lines 484-494
**Apply to:** `quickshell-doctor`'s D-14 documented-SKIP branch for QS-03 acceptance; theme-doctor's motion-lint fold
```bash
if [[ <precondition-false> ]]; then
    echo "  [SKIP] <check name>: <reason>"
else
    ... run check, call check() ...
fi
```
D-14 requires this SKIP print its reason AND an evidence pointer (e.g. `SKIP — per-screen surface fan-out accepted as a permanent limitation ... See 11-VERIFICATION.md overrides[0] and 12-CONTEXT.md D-13.` — exact copy given in UI-SPEC's Copywriting Contract).

### Theme-orthogonal state-axis triad (state file + reader + render function)
**Source:** `theme-engine/.config/theme-engine/lib/font.sh` (whole file)
**Apply to:** `motion.sh`'s `motion-scale` axis — constant + default + `theme_engine_read_X` + `theme_engine_render_X_files <tmp>` called from `generate.sh`, excluded from `commit.sh`'s rsync via `engine_owned_files`, seeded-when-absent in `stow.sh`.

### `contract.sh` format-dispatch `case` branch
**Source:** `theme-engine/.config/theme-engine/lib/contract.sh` lines 64-141 (`contract_extract_names`) and 155-217 (`contract_extract_values`)
**Apply to:** the two new `motion-gtk-css`/`motion-hypr` format branches — same `grep -oP`/`sed -nE` idiom, same `2>/dev/null | sort -u` suppression, same CR-01 loud-fallback `*)` branch at the end (never silently `return 1` with no diagnostic).

### Seed-when-absent idiom
**Source:** `stow.sh` lines 100-120 (three examples: `current-waybar-layout`, `gaming-mode`, `waybar-visibility.css`)
**Apply to:** `motion-scale` state-file seed and the three rendered motion files' first-boot seed (D-30), both via `[[ -f ... ]] || <write>` — never unconditional, to avoid clobbering a live user pick on `stow.sh` re-run.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `quickshell/.config/quickshell/modules/qmldir` | config (module manifest) | — | No `qmldir` file exists anywhere in the repo today (verified in RESEARCH.md) — follow Quickshell's documented grammar directly; this is greenfield within the repo, not a copy-from-analog task. |

## Metadata

**Analog search scope:** `theme-engine/.config/theme-engine/` (lib/, contract.json, doctor/parity/stress-test scripts), `hypr/.config/hypr/` (scripts/, config/, hyprland.conf), `quickshell/.config/quickshell/` (shell.qml, modules/Probe.qml), `wleave/.config/wleave/style.css`, `stow.sh`, `matugen/.config/matugen/config.toml`
**Files scanned:** 21 (all named explicitly in CONTEXT.md's canonical_refs and code_context)
**Pattern extraction date:** 2026-07-26
