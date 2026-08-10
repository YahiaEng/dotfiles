# Phase 13: Motion Retrofit & Existing-Surface Sweep - Pattern Map

**Mapped:** 2026-07-27
**Files analyzed:** 24
**Analogs found:** 22 / 24

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `theme-engine/.config/theme-engine/lib/motion.sh` (`theme_engine_render_motion_scss`, new function) | service/renderer | transform (JSON → text emit) | same file, `theme_engine_render_motion_files` (existing 3-target renderer) | exact — same file, sibling function |
| `theme-engine/.config/theme-engine/motion.json` (grow easings) | config/data | CRUD (data table growth) | itself (existing `.easings`/`.durations`/`.semantic` schema) | exact |
| `theme-engine/.config/theme-engine/lib/generate.sh` (`theme_engine_generate`, add sass-compile call) | service/orchestrator | batch (sequential sibling writers) | same file's own `theme_engine_render_font_files` / `theme_engine_render_motion_files` call sites | exact |
| `theme-engine/.config/theme-engine/lib/commit.sh` (rsync excludes) | service/orchestrator | file-I/O (atomic sync) | itself — `engine_owned_files`-driven exclude loop | exact |
| `theme-engine/.config/theme-engine/contract.json` (new `files` entries) | config | CRUD | itself — `ags.scss` (`scss-vars` format) entry | exact |
| `theme-engine/.config/theme-engine/theme-parity` (extend byte-identity walk) | test/gate | batch (hash compare) | itself — "Layer 4: motion byte-identity (D-31)" block, line ~320 | exact |
| `theme-engine/.config/theme-engine/theme-doctor` | test/gate | request-response (CLI check) | unchanged per CONTEXT — `git status --porcelain` clean-tree check, line ~639 | exact (no new code needed) |
| `theme-engine/.config/theme-engine/theme-stress-test` (D-24 blocking gate) | test/gate | batch (N consecutive switches) | itself — existing 10-switch loop | exact |
| `theme-engine/.config/theme-engine/lib/wallpaper.sh` (`current.jpg` untrack, D-23) | service | file-I/O | itself — line 65 `ln -sfr` | exact |
| `hypr/.config/hypr/config/animations.conf` (bezier retire, `layersIn`/`layersOut`) | config | CRUD (hand-authored → tokenized) | itself, plus `hyprland-motion.conf`'s generated `bezier = motion-*` block as the token-reference target | exact |
| `hypr/.config/hypr/config/windowrules.conf` (dead wofi layerrule removal) | config | CRUD (deletion) | itself — `layerrule = animation fade, match:namespace wleave` (line 254) as the per-namespace precedent | exact |
| `hypr/.config/hypr/scripts/motion-lint` (`--no-pending`, `.scss` parsing, exemption rewrites) | utility/lint | request-response (CLI, exit code) | itself — `--self-test` flag (line ~152) and `EXEMPTIONS`/`LINE_EXEMPTIONS` (lines 355/394) | exact |
| `hypr/.config/hypr/scripts/keybind-doctor` (reference only, no change) | utility/lint | request-response | n/a — cited only as second flag-gated-self-test precedent | n/a |
| `hypr/.config/hypr/scripts/waybar-design-lint` (CHECK A learns `.scss`) | utility/lint | request-response | itself — CHECK A's `@name` regex resolution logic | exact |
| `hypr/.config/hypr/scripts/waybar-launch.sh` (state-dir `.css` path) | utility/launcher | request-response (exec) | itself — line 32 disk-truth validation, line 39 `waybar -c … -s …` | exact |
| `hypr/.config/hypr/scripts/icon-theme-picker.sh` (Ctrl-A browse, D-26; fetch-extract preview, D-28) | utility/picker | request-response (interactive fzf) | `wallpaper-picker.sh` — Ctrl-A `reload()` binding (line 258-267) | exact |
| `hypr/.config/hypr/scripts/wallpaper-picker.sh` (unchanged; source of the Ctrl-A pattern) | utility/picker | request-response | n/a — this IS the analog | n/a |
| `waybar/.config/waybar/style-full.scss` (was `.css`) | component/stylesheet | transform (sass → css) | `theme-engine/.../ags.scss` for the `scss-vars` consumption shape; itself (`style-full.css`) for content | exact (structure) / new (compile step) |
| `waybar/.config/waybar/style-athena.scss` | component/stylesheet | transform | itself (`style-athena.css`) — also the one non-MD3 `easeOutQuad` curve to replace | exact |
| `waybar/.config/waybar/style-floating.scss` | component/stylesheet | transform | itself (`style-floating.css`) | exact |
| `waybar/.config/waybar/style-vertical.scss` | component/stylesheet | transform | itself (`style-vertical.css`) | exact |
| `waybar/.config/waybar/theme.scss` | component/stylesheet | transform | itself (`theme.css`) | exact |
| `waybar/.config/waybar/waybar-modules.scss` | component/stylesheet | transform | itself (`waybar-modules.css`) | exact |
| `swaync/.config/swaync/style.scss` (was `.css`) | component/stylesheet | transform | itself (`style.css`) — all 6 literals are the identical rule | exact |
| `stow.sh` (compiled-sheet seed, D-05; `current.jpg` seed, D-23) | config/installer | file-I/O (seed-when-absent) | itself — motion-file seed block (lines ~145-178) invoking `motion.sh`'s real renderer | exact |
| `fish/.config/fish/config.fish` (WR-01/WR-02) | config | CRUD (one-line edits) | itself, lines ~46/58-59 | exact |
| `zshell/.zshrc` (WR-03) | config | CRUD | itself, line ~123 | exact |
| `wleave/.config/wleave/layout.json` (WR-04 logout wrap) | config | event-driven (action dispatch) | itself — the `Shutdown`/`Reboot` entries already wrapped with `hyprshutdown --post-cmd` | exact |
| `install.sh` (no functional change expected; dart-sass already hard dep) | config/installer | batch | itself, line 206 | exact (verify only) |

## Pattern Assignments

### `theme-engine/.config/theme-engine/lib/motion.sh` — new `_motion.scss` partial writer (motion.sh, service/renderer)

**Analog:** same file, `theme_engine_render_motion_files` (lines 129-262), specifically writer #2 (GTK4 `:root` block, lines 214-235) as the shape for the new sass writer, and `font.sh`'s theme-orthogonal axis pattern for the overall module contract.

**Imports/sourcing pattern** (`generate.sh` lines 24-37):
```bash
# UTIL-05/D-19: font is a theme-orthogonal state axis (same shape as
# wallpaper.sh's last-wallpaper/ precedent) — lib/font.sh owns its own
# render path
source "$LIB_DIR/font.sh"

# TOKEN-03/D-01: motion is the THIRD theme-orthogonal state axis
source "$LIB_DIR/motion.sh"
```
The new sass compile does NOT get its own `lib/*.sh` module per D-34 — it is called from inside `theme_engine_generate` directly, or as a fourth function inside `motion.sh` (Claude's Discretion). Either way, mirror this `source` + call-site shape.

**Core writer-shape pattern to copy** (motion.sh lines 224-235, the GTK4 `:root` writer — closest structural sibling to a `_motion.scss` partial, since both are declaration blocks of `token: value;` pairs resolved from the same `$resolved` TSV):
```bash
{
    echo ":root {"
    while IFS=$'\t' read -r token _easing ms _clamped; do
        [[ -z "$token" ]] && continue
        printf '  --motion-duration-%s: %sms;\n' "$token" "$ms"
    done <<< "$resolved"
    jq -r '
        .easings | to_entries[] |
        "  --motion-easing-\(.key): cubic-bezier(\(.value | join(", ")));"
    ' "$MOTION_JSON"
    echo "}"
} > "$out_dir/gtk-4.0-motion.css"
```
The `_motion.scss` partial should follow the identical `$resolved`-TSV-driven loop but emit `$motion-duration-<token>: <ms>ms;` / `$motion-easing-<name>: cubic-bezier(...);` SCSS variable assignments instead of CSS custom properties (per RESEARCH Pattern 2, `_motion.scss` example — these are `$name:` sass variables, not `--name:` CSS vars, precisely because GTK3 cannot resolve `var()`).

**Validation-before-write pattern** (motion.sh lines 41-127, `theme_engine_validate_motion_values`): same guard MUST run before the new partial is written too — it already runs once per `theme_engine_render_motion_files` call, so if the new writer is folded into that same function (as a 4th block after line 235), no new validation call is needed; if it becomes a separate function, call `theme_engine_validate_motion_values` first, matching the existing discipline ("validated BEFORE any write").

**Error handling pattern:** every writer in this file is bare `printf`/`jq` redirected to a file; failure propagation happens one level up — `theme_engine_render_motion_files` returns 1 on any pre-write validation failure (lines 165-167) and 0 otherwise; the caller (`generate.sh`) does `theme_engine_render_motion_files "$tmp" || return 1` (generate.sh line 106). The new sass-compile step must follow the exact same `|| return 1` propagation shape — see generate.sh pattern below.

---

### `theme-engine/.config/theme-engine/lib/generate.sh` — `theme_engine_generate`, sass compile as 4th sibling writer (service/orchestrator, batch)

**Analog:** same file — the font.sh/motion.sh call sites are the exact pattern to replicate (lines 94-106):
```bash
theme_engine_render_gtk_settings "$mode" "$tmp"

# UTIL-05/D-19: font-choice is re-rendered on EVERY run regardless of
# which theme/mode is active (independent axis, same call-site shape as
# the gtk-settings render right above it).
theme_engine_render_font_files "$tmp"

# TOKEN-03/D-01: motion is the third theme-orthogonal axis, re-rendered
# on EVERY run regardless of which theme/mode is active — same shape as
# the font-choice render right above it. Its return is propagated (not
# swallowed): a failed motion render must fail the whole generate step
theme_engine_render_motion_files "$tmp" || return 1

return 0
```
**The sass-compile call (D-34, 4th sibling) belongs immediately after this block**, propagated identically:
```bash
theme_engine_compile_gtk3_stylesheets "$tmp" || return 1
```
(RESEARCH's own "Full render-target shape after this phase" code example gives this exact call, plus `theme_engine_render_motion_scss "$tmp"` immediately before it — both non-swallowed, matching the house style of every other writer in this function.)

**Invocation shape for the sass compile itself** (from RESEARCH "Recommended precompile invocation shape", verified this session):
```bash
sass --no-charset --no-source-map \
     --load-path="$tmp$STATE_DIR" \
     "$WAYBAR_SRC_DIR/style-athena.scss" "$tmp$STATE_DIR/waybar/style-athena.css" \
  || return 1   # propagate failure exactly like motion.sh's render step does today
```
Copy the `GENERATE_LOG` stderr-capture discipline used for matugen calls (generate.sh lines 67-70, 78-80) — do not let raw sass stderr reach a notification unsanitized (Security Domain).

---

### `theme-engine/.config/theme-engine/lib/commit.sh` — exclude/manifest awareness (service/orchestrator, file-I/O)

**Analog:** same file, `engine_owned_files`-driven exclude loop (lines 109-131). **No new exclude entries are needed for the compiled stylesheets** — they ARE part of the rendered tree (D-34 renders them into `$tmp$STATE_DIR`), same as `hyprland-motion.conf`/`gtk-4.0-motion.css` today, which are also rendered-tree members and carry NO `engine_owned_files` entry. Contrast with `waybar-visibility.css`, which IS excluded because it's written by a separate runtime script outside `theme-apply` (comment block lines 83-96) — the compiled sheets are the opposite case.

```bash
local engine_owned
engine_owned="$(contract_engine_owned_files)"
...
local -a exclude_flags=()
while IFS= read -r entry; do
    [[ -z "$entry" ]] && continue
    exclude_flags+=(--exclude="$entry")
done <<< "$engine_owned"

rsync -a --delete "${exclude_flags[@]}" "$rendered_dir"/ "$STATE_DIR"/
```
**Read this file's giant comment block (lines 34-108) before touching it** — it documents 8 prior instances of exactly the "forgot to exclude an engine-owned file" bug class; the compiled sheets are NOT that case (they're renderer output, not runtime-mutated state), so resist the urge to add them to `engine_owned_files`.

---

### `theme-engine/.config/theme-engine/contract.json` — compiled-stylesheet `files` entries (config, CRUD)

**Analog:** the existing `ags.scss` entry (`{ "name": "ags.scss", "format": "scss-vars" }`, line 23) is the closest prior art for a sass-sourced file, though it's the pre-compile `.scss` source itself, not a compiled `.css` output. For the compiled waybar/swaync sheets — full format-validated (D-35), not `presence_only_files` — new entries follow the existing `gtk-css` format used by every other GTK3-consumed sheet:
```json
{ "name": "waybar.css", "format": "gtk-css" },
{ "name": "swaync.css", "format": "gtk-css" },
```
i.e. `{ "name": "waybar/style-full.css", "format": "gtk-css" }` (or whatever flat state-dir layout is chosen, Claude's Discretion) for each of the 6 waybar outputs plus swaync's one output. Do NOT add them to `presence_only_files` (that array currently holds only `kitty-font.conf`/`waybar-font.css`, line 27) — D-35 explicitly requires full validation.

Existing full-object shape to copy verbatim (`hyprland-motion.conf` and `gtk-4.0-motion.css` entries, lines 20-22):
```json
{ "name": "motion.json", "format": "json" },
{ "name": "gtk-4.0-motion.css", "format": "css-vars" },
{ "name": "hyprland-motion.conf", "format": "hypr-motion" },
```
These are the precedent for "a new render target gets its own named format string" — the compiled GTK3 sheets should reuse `gtk-css` (already exists, matches their actual content) rather than inventing a new format string.

---

### `theme-engine/.config/theme-engine/theme-parity` — extend byte-identity to compiled sheets (test/gate, batch)

**Analog:** same file, "Layer 4: motion byte-identity (D-31)" block (~line 320-367):
```bash
echo "-- Motion byte-identity (D-31) --"
...
        h="$(sha256sum "$mpath" | awk '{print $1}')"
...
    check "motion byte-identity: $mfile identical across $DIRS_COMPARED render dir(s) (diverged: ${diverged:-none})" "$?"
```
D-35 requires this SAME sha256-across-all-render-dirs walk extended to the 7 compiled sheets (6 waybar + swaync), on the theory that they're theme-independent (motion baked in, colour still `@import url()`). Copy the loop structure, iterate the new filenames instead of `motion.json`/`gtk-4.0-motion.css`/`hyprland-motion.conf`.

---

### `hypr/.config/hypr/config/animations.conf` — MD3 purity retrofit + `layersIn`/`layersOut` (config, CRUD)

**Analog:** itself. Current full state (24 lines total) — this is the literal content the plan edits, not a separate analog file:
```
animations {
    enabled = $motion_enabled

    bezier = wind, 0.05, 0.9, 0.1, 1.05
    bezier = winIn, 0.1, 1.1, 0.1, 1.1
    bezier = winOut, 0.3, -0.3, 0, 1
    bezier = liner, 1, 1, 1, 1
    bezier = md3_standard, 0.2, 0, 0, 1
    bezier = md3_decel, 0.05, 0.7, 0.1, 1
    bezier = md3_accel, 0.3, 0, 0.8, 0.15
    bezier = overshot, 0.05, 0.9, 0.1, 1.1
    bezier = crazyshot, 0.1, 1.5, 0.76, 0.92
    bezier = smoothOut, 0.36, 0, 0.66, -0.56
    bezier = smoothIn, 0.25, 1, 0.5, 1
    bezier = bounce, 1, 1.6, 0.1, 0.85

    animation = windowsIn, 1, 5, winIn, popin 60%
    animation = windowsOut, 1, 5, winOut, popin 60%
    animation = windowsMove, 1, 5, wind, slide
    animation = fadeIn, 1, 4, smoothIn
    animation = fadeOut, 1, 4, smoothOut
    animation = fadeSwitch, 1, 5, md3_decel
    animation = fadeShadow, 1, 5, md3_decel
    animation = fadeDim, 1, 5, md3_decel
    animation = border, 1, 10, liner
    animation = borderangle, 1, 100, liner, loop
    animation = workspaces, 1, 5, wind, slide
    animation = specialWorkspace, 1, 5, md3_decel, slidevert
    animation = layers, 1, 4, md3_decel, popin 80%
}
```
D-09/D-22 keep `enabled = $motion_enabled` here (owned by this file, not the generated block, since whichever `animations {}` block loads last would clobber it — comment lines 7-12). D-07 splits the final `layers` line into `layersIn`/`layersOut`, consuming `motion.json`'s `emphasized-in`/`emphasized-out` semantic pairs. Token-reference syntax for beziers should mirror how `hyprland-motion.conf` already emits them (motion.sh lines 204-212):
```bash
echo "animations {"
jq -r '.easings | to_entries[] |
    "    bezier = motion-\(.key), \(.value[0]), \(.value[1]), \(.value[2]), \(.value[3])"' \
    "$MOTION_JSON"
echo "}"
```
i.e. the tokenized `animation =` lines in `animations.conf` will reference `motion-<name>` bezier IDs sourced from `hyprland-motion.conf` (sourced immediately before this file, per the comment at line 7-8), not the hand-authored `md3_standard`/`liner`/etc. names being deleted.

---

### `hypr/.config/hypr/config/windowrules.conf` — dead `wofi` layerrule removal (config, CRUD/deletion)

**Analog:** itself. Lines to delete: 187 (`layerrule = blur on, match:namespace wofi`) and 263 (`layerrule = ignore_alpha 0.5, match:namespace wofi`). Precedent for a namespace-scoped `layerrule` staying (NOT deleted, it's the D-07 per-namespace override precedent):
```
layerrule = animation fade, match:namespace wleave    # line 254
```

---

### `hypr/.config/hypr/scripts/motion-lint` — `--no-pending`, `.scss` parsing, exemption rewrites (utility/lint, request-response)

**Analog:** itself. The `--self-test` flag is the exact shape `--no-pending` should copy (lines 152-155):
```python
if [[ "${1:-}" == "--self-test" ]]; then
    run_self_test
    exit $?
fi
```
`--no-pending` should follow this identical "check `sys.argv`/`$1`, branch into a separate assertion pass, `exit $?`" shape, gated the same way (opt-in, not default — D-33).

**EXEMPTIONS list to edit** (lines 355-369), current full-file entries:
```python
EXEMPTIONS = [
    {'glob': 'waybar/*.css', 'regex': re.compile(r'(^|/)waybar/[^/]+\.css$'),
     'reason': 'GTK3, no variable mechanism exists'},
    {'glob': 'swaync/style.css', 'regex': re.compile(r'(^|/)swaync/style\.css$'),
     'reason': 'GTK3, no variable mechanism exists'},
    {'glob': 'swayosd/style.css', 'regex': re.compile(r'(^|/)swayosd/style\.css$'), ...
```
Per D-32's end-state table: `waybar/*.css` and `swaync/style.css` entries are REMOVED (converted+tokenized); `swayosd/style.css` entry's `reason` string changes from "GTK3, no variable mechanism exists" to the D-02 permanent reason ("no motion literals — motion is compositor-delivered via `animation = layers`"); `walker/**/style.css` and `ags/*.scss` entries get the same reason-string rewrite (0 literals, compositor-delivered, permanent).

**LINE_EXEMPTIONS entry to rewrite** (lines 394-417) — the wleave hover-rule entry's `reason` changes to "permanent" per D-31, following the exact same dict shape:
```python
LINE_EXEMPTIONS = [
    {'label': 'wleave/style.css button:hover,button:focus rule',
     'regex': re.compile(r'(^|/)wleave/style\.css$'),
     ...
```

**`.scss` parsing:** wherever this script's path-glob/regex matches `.css` files under `waybar/`/`swaync/`, extend the pattern to also match `.scss`. Since the exemption entries for those two paths are being REMOVED (they're no longer exempt, they're now compliant/tokenized), the script's core surface-scanning logic (not shown in the excerpts above — the file's main body before line 355) is what needs `.scss` added to its file-discovery glob.

---

### `hypr/.config/hypr/scripts/waybar-design-lint` — CHECK A learns `.scss` (utility/lint)

**Research-flagged correction (not in CONTEXT.md):** CHECK A's regex `@([A-Za-z_][A-Za-z0-9_-]*)` will misidentify Sass directives (`@use`, `@forward`, `@mixin`) as unresolved colour tokens if run against raw `.scss` source. Two options (RESEARCH, Claude's Discretion section):
1. Extend `AT_RULE_KEYWORDS` with the Sass directives actually used (`@use`, minimum).
2. Run CHECK A against the COMPILED `.css` output instead of `.scss` source — simpler, and it's what actually reaches GTK3 (recommended by research as "arguably the more correct target regardless").

---

### `hypr/.config/hypr/scripts/waybar-launch.sh` — state-dir stylesheet path (utility/launcher, request-response)

**Analog:** itself, full file (39 lines). Line 32 disk-truth validation:
```bash
if [[ -f "$WAYBAR_DIR/config-${LAYOUT}.jsonc" && -f "$WAYBAR_DIR/style-${LAYOUT}.css" ]]; then
    : # $LAYOUT resolves to a real, styled layout — keep it
else
    LAYOUT="full"
fi
```
Line 39 invocation:
```bash
exec waybar -c "$WAYBAR_DIR/config-${LAYOUT}.jsonc" \
       -s "$WAYBAR_DIR/style-${LAYOUT}.css"
```
Both `-c` (config, unchanged, stays repo-authored `.jsonc`) and `-s` (style) paths must be updated: `-s` now points into the compiled state-dir output (e.g. `~/.local/state/theme/waybar/style-${LAYOUT}.css`) rather than `$WAYBAR_DIR/style-${LAYOUT}.css`. The disk-truth check at line 32 must ALSO validate the compiled sheet exists (D-05: "waybar-launch.sh:32's disk-truth validation only picks a layout; it falls back to full, whose sheet would be equally missing" — so the fallback-to-`full` path needs the compiled-sheet existence check too, not just the source `.jsonc`).

---

### `hypr/.config/hypr/scripts/icon-theme-picker.sh` — Ctrl-A browse (D-26) + fetch-extract preview (D-28)

**Analog for Ctrl-A browse:** `wallpaper-picker.sh` lines 258-267:
```bash
# ── Ctrl-A browse-all binding (THM-03/D-16) ──────────
...
    CTRL_A_BIND=(--bind "ctrl-a:reload(\"$ENUM_SCRIPT\" full)+change-header($STANDARD_HEADER)")
...
# ── Run fzf ──────────────────────────────────────────
SELECTED=$(echo "$IMAGES" | fzf \
```
Copy this exact `--bind ctrl-a:reload(...)+change-header(...)` idiom, re-pointing `reload()` at an icon-theme-catalogue enumeration script (repo-installed + `pacman -Ss`/AUR-browsable) instead of the wallpaper-full-library enumeration.

**Analog for montage preview + cache pipeline:** `icon-theme-picker.sh`'s own existing `ENUM_SCRIPT`/`kitten icat` pipeline (lines 34-60+), specifically the `mktemp` + trap idiom:
```bash
ENUM_SCRIPT=""
PREVIEW_SCRIPT=""
CACHE_DIR=""
ENUM_SCRIPT=$(mktemp /tmp/icon-enum-XXXXXX.sh)
trap 'rm -f "$ENUM_SCRIPT" "$PREVIEW_SCRIPT"; rm -rf "$CACHE_DIR"' EXIT
```
D-28's fetch-extract preview extends this SAME cache/trap discipline — extract into `$CACHE_DIR` (already trap-cleaned), never `/` or outside cache (Security Domain V12). The two-glob-shape search Pitfall 6 requires (`SIZExSIZE/category/` AND `category/SIZE/`) is new logic with no direct in-repo analog — write it as a small glob-or-recursive-find helper inside the existing preview pipeline.

---

### GTK-CSS → SCSS conversion (all 7 files: 6 waybar + swaync) — the `@name` interpolation rewrite

**This is the single largest per-file mechanical task the planner must size.** Concrete before/after (verified working this session, RESEARCH Pattern 1):

Before (`waybar/.config/waybar/style-full.css`, current, invalid Sass):
```css
color: @fg;
background: @bar-surface;
```
(from swaync/style.css, same pattern, `alpha()` wrapped form):
```css
background: alpha(@background, 0.72);
border: 1px solid alpha(@primary, 0.25);
color: @on_secondary;
```

After (`.scss`, compiles cleanly, byte-identical CSS output):
```scss
color: #{"@fg"};
background: #{"@bar-surface"};
background: #{"alpha(@background, 0.72)"};
border: 1px solid #{"alpha(@primary, 0.25)"};
color: #{"@on_secondary"};
```

**Reference counts per file** (RESEARCH, verified this session — size the task against these):
- `theme.css`/`theme.scss`: 116 references
- `style-athena.css`/`.scss`: 45
- `style-floating.css`/`.scss`: 53
- `style-vertical.css`/`.scss`: 38
- `waybar-modules.css`/`.scss`: 34
- `style-full.css`/`.scss`: 3
- `swaync/style.css`/`.scss`: at least 19

**Import-rewrite pattern (D-04/Pitfall 3)** — current `@import` lines (waybar `style-full.css` lines 1-9):
```css
@import url("theme.css");
@import url("../../.local/state/theme/waybar-font.css");
@import url("waybar-modules.css");
@import url("../../.local/state/theme/waybar-visibility.css");
```
Once compiled output lives as a flat sibling inside the SAME state-dir output directory as `waybar-font.css`/`waybar-visibility.css` (both already state-dir-resident per `contract.json`), rewrite to bare filenames:
```scss
@import url("theme.css");
@import url("waybar-font.css");
@import url("waybar-modules.css");
@import url("waybar-visibility.css");
```
sass does NOT rewrite these itself — the `.scss` SOURCE must already be authored with output-relative paths (Pitfall 3, verified).

**Motion-token consumption pattern (D-15/D-03)** — the existing hand-authored transitions:
```css
/* swaync/style.css — all 6 identical */
transition: all 0.2s ease;

/* waybar/style-athena.css */
transition: opacity 0.3s ease;      /* line 37 */
transition: all 0.3s ease;          /* lines 90, 301, 324, 351 */
transition: all 0.3s cubic-bezier(0.25, 0.46, 0.45, 0.94);  /* line 155 — non-MD3, replaced per D-09/D-16 */
```
become (per Pattern 2, `@use "motion" as m;`):
```scss
@use "motion" as m;
...
transition: all #{m.$motion-duration-standard} #{m.$motion-easing-standard};
```
using the `standard` token (200ms + MD3 standard) for swaync's 6 identical rules (D-15: "the only change is `ease` → MD3 `standard`") and the appropriate semantic token (new 300ms neutral pair, per D-15) for waybar's dominant `0.3s` value.

**Compile flags (Pitfall 2/4, mandatory on every invocation):**
```bash
sass --no-charset --no-source-map --load-path="$tmp$STATE_DIR" <in>.scss <out>.css
```
`--no-charset` is non-optional — a bare `sass` compile emits `@charset "UTF-8";` as line 1, which GTK3's `CssProvider` discards the ENTIRE stylesheet over (verified, reproduced with PyGObject this session).

---

### `hypr/.config/hypr/scripts/motion-switch.sh` — one-entrypoint contract (unchanged, reference only)

**Analog:** itself, line 118's documented contract:
> "One entrypoint, per TOKEN-05's 'driven through theme-apply's existing single entrypoint' — this script never writes a rendered file itself"

No new writer should be added here — D-36 requires the sass compile to ride the SAME single `theme-apply` re-render this script already triggers on a motion-scale change, never a second recompile-only fast path.

---

### `wleave/.config/wleave/layout.json` — WR-04 Logout wrap (config, event-driven)

**Analog:** the existing Shutdown/Reboot entries in the same file, which already wrap with `hyprshutdown --post-cmd`. Read the file directly to get the exact key structure before editing — `logout -> cliphist wipe; uwsm stop` is the current bare action (per CONTEXT D-29); this is a CONDITIONAL edit pending the D-29 empirical test (Pitfall 5) — do not wrap unconditionally.

## Shared Patterns

### Atomic render-then-commit (D-14, applies to ALL new theme-engine writers)
**Source:** `theme-engine/.config/theme-engine/lib/generate.sh` (all writers render into `$tmp$STATE_DIR`) + `commit.sh` (only invoked after `theme_engine_generate` returns 0)
**Apply to:** the sass compile step, the `_motion.scss` partial writer — both MUST render into the tmp tree and propagate failure via `|| return 1`, never write directly to the live `$STATE_DIR`.

### Theme-orthogonal axis contract (D-01/D-03, three prior instances: icon-theme, font, motion)
**Source:** `theme-engine/.config/theme-engine/lib/font.sh` (full file, 55 lines) — the canonical minimal shape: one state file under `$STATE_DIR`, one `theme_engine_read_*` function with a plain/closed-set read, one `theme_engine_render_*_files` function called every run regardless of theme/mode.
```bash
FONT_STATE_FILE="$HOME/.local/state/theme/font-choice"
FONT_DEFAULT="FiraCode Nerd Font"

theme_engine_read_font() {
    cat "$FONT_STATE_FILE" 2>/dev/null || echo "$FONT_DEFAULT"
}
```
**Apply to:** motion.sh's new sass-writer function does NOT need a new axis (motion-scale already exists) — this pattern is cited because `motion.sh` itself already follows it faithfully (line 32-39's closed-`case` read is STRICTER than font.sh's free-text read, deliberately, since motion values flow into a Hyprland config parser — ASVS V5). Any new state (none identified for this phase beyond what exists) must use this same shape.

### Engine-owned-files single-array-of-truth (commit.sh, contract.json)
**Source:** `theme-engine/.config/theme-engine/contract.json` `engine_owned_files` array (lines 28-38) + `commit.sh`'s `contract_engine_owned_files` consumption (lines 109-131)
**Apply to:** decide explicitly, per new file, whether it's rendered-tree content (→ `contract.json` `files` entry, format-validated) or runtime-mutated state outside `theme-apply` (→ `engine_owned_files`, excluded from rsync). The compiled stylesheets are the FORMER (D-34/D-35) — do not add them to `engine_owned_files`.

### Seed-when-absent idiom (stow.sh)
**Source:** `stow.sh` motion-file seed block, lines ~145-178 — invokes the REAL renderer (`theme_engine_render_motion_files`) in a subshell against a throwaway `mktemp -d`, never a hand-written stub:
```bash
if [[ ! -f "$HOME/.local/state/theme/hyprland-motion.conf" ]] || ...; then
    MOTION_LIB="$DOTFILES_DIR/theme-engine/.config/theme-engine/lib/motion.sh"
    if [[ -f "$MOTION_LIB" ]]; then
        (
            set -uo pipefail
            STATE_DIR="$HOME/.local/state/theme"
            source "$MOTION_LIB"
            SEED_TMP="$(mktemp -d)"
            trap 'rm -rf "$SEED_TMP"' EXIT
            if theme_engine_render_motion_files "$SEED_TMP"; then
                mkdir -p "$STATE_DIR"
                for mf in motion.json gtk-4.0-motion.css hyprland-motion.conf; do
                    [[ -f "$SEED_TMP$STATE_DIR/$mf" ]] && cp "$SEED_TMP$STATE_DIR/$mf" "$STATE_DIR/$mf"
                done
            else
                echo "  ⚠ motion.sh seed render failed — a fresh install's first Hyprland start WILL fail until theme-apply runs successfully first" >&2
                exit 1
            fi
        ) || echo "  ⚠ motion-file seed did not complete..." >&2
    fi
fi
```
**Apply to:** D-05's compiled-sheet seed (mirror exactly, invoking the sass-compile function instead) and D-23's `current.jpg` seed (simpler — same `[[ -f ... ]] || ...` idiom, seeding a symlink to the committed default target, `catppuccin/5-alien-planet.jpg`). **Do NOT wrap the compiled-sheet seed in `stow.sh:135`'s `|| true` tolerance** — D-05 explicitly requires this to fail loudly, matching the motion-file seed's own loud-failure precedent above (not the `|| true`-guarded waybar-layout/gaming-mode seeds earlier in the file).

### Flag-gated extra-assertion shape (self-test / path-argument precedent)
**Source:** `motion-lint --self-test` (lines 111-154) and `keybind-doctor`'s path-argument self-test
```bash
if [[ "${1:-}" == "--self-test" ]]; then
    run_self_test
    exit $?
fi
```
**Apply to:** `motion-lint --no-pending` (D-33) — same `if [[ "${1:-}" == "--flag" ]]; then ...; exit $?; fi` shape, opt-in only, never default behavior.

## No Analog Found

| File | Role | Data Flow | Reason |
|---|---|---|---|
| Icon-theme fetch-extract preview two-glob-shape search (Pitfall 6: `SIZExSIZE/category/` vs `category/SIZE/`) | utility | file-I/O | No existing script in this repo tries multiple directory-convention shapes when globbing for preview assets — new logic, though it slots inside the existing `icon-theme-picker.sh` cache/trap pipeline |
| `motion.json`'s 6 new single-bezier MD3 easings (`standardDecelerate`, `standardAccelerate`, `legacy`, `legacyDecelerate`, `legacyAccelerate`, corrected `linear`) | config/data | CRUD | Pure data addition into the existing `.easings` object shape — no code pattern needed, just the primary-sourced values from 13-RESEARCH.md's "State of the Art" table |

## Metadata

**Analog search scope:** `theme-engine/.config/theme-engine/` (lib/, contract.json, theme-parity, theme-doctor, theme-stress-test), `hypr/.config/hypr/config/` (animations.conf, windowrules.conf), `hypr/.config/hypr/scripts/` (motion-lint, motion-switch.sh, waybar-launch.sh, waybar-design-lint, icon-theme-picker.sh, wallpaper-picker.sh, keybind-doctor), `waybar/.config/waybar/*.css`, `swaync/.config/swaync/style.css`, `wleave/.config/wleave/{layout.json,style.css}`, `stow.sh`, `install.sh`, `fish/.config/fish/config.fish`, `zshell/.zshrc`
**Files scanned:** ~20 read directly this session (motion.sh, font.sh, generate.sh, commit.sh, contract.json, animations.conf, windowrules.conf excerpt, motion-lint excerpt, keybind-doctor excerpt, wallpaper-picker.sh excerpt, icon-theme-picker.sh excerpt, waybar-launch.sh, stow.sh excerpt, theme-parity excerpt, style-full.css, style-athena.css, swaync/style.css)
**Pattern extraction date:** 2026-07-27
