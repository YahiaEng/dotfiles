# Phase 2: Static ↔ Dynamic Parity & Switch Reliability - Pattern Map

**Mapped:** 2026-07-08
**Files analyzed:** 5 new/modified files
**Analogs found:** 5 / 5

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|--------------------|------|-----------|-----------------|----------------|
| `theme-engine/.config/theme-engine/theme-parity` (new) | test/utility (report-only CLI) | batch / transform (render 7 targets → diff) | `theme-engine/.config/theme-engine/theme-doctor` | exact (same "rerunnable report-only check script" role) |
| `theme-engine/.config/theme-engine/theme-stress-test` (new, name Claude's discretion) | test/utility (mutating CLI harness) | event-driven / batch (drives real switches, asserts per-switch) | `theme-engine/.config/theme-engine/theme-apply` (as the driven entrypoint) + `theme-doctor` (as the per-switch check pattern) | role-match (orchestration wraps theme-apply calls, borrows theme-doctor's check() reporting style) |
| `theme-engine/.config/theme-engine/contract.json` (new manifest) | config | CRUD (static config, read by 2 consumers) | none (new concept) — closest precedent is `theme-doctor`'s hardcoded `for f in hyprland.conf waybar.css ...` file list (theme-doctor lines 45-50) | partial (this literal list is exactly what becomes the manifest) |
| `theme-engine/.config/theme-engine/lib/contract.sh` (optional, new shared helper) | utility (shared bash functions) | transform (extraction/normalization) | `theme-engine/.config/theme-engine/lib/gtk.sh` / `lib/reload.sh` (existing `lib/*.sh` function-library convention) | role-match (same "sourced shell function library, no direct execution" pattern) |
| `theme-engine/.config/theme-engine/theme-doctor` (modified — read contract manifest) | test/utility (report-only CLI) | CRUD (read-only checks) | itself (existing file, in-place refactor) | exact |

## Pattern Assignments

### `theme-engine/.config/theme-engine/theme-parity` (new)

**Analog:** `theme-engine/.config/theme-engine/theme-doctor` (140 lines, full file read)

**Header / strict-mode pattern** (theme-doctor lines 1-16):
```bash
#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║              THEME-DOCTOR (D-25)                     ║
# ║  Rerunnable health check for the theme-engine's core  ║
# ║  invariants. Report-only — never mutates state.       ║
# ╚══════════════════════════════════════════════════════╝

set -uo pipefail   # NOTE: no -e — see Anti-Pattern below, this is deliberate

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
STATE_DIR="$HOME/.local/state/theme"
DOTFILES_DIR="$HOME/dotfiles"

PASS=0
FAIL=0
```
`theme-parity` MUST copy this exact strict-mode choice (`set -uo pipefail`, no `-e`) — it is a report tool that must run every check across all 7 targets and report every failure, never abort on the first `diff`/`grep`/`[[ ]]` non-zero.

**check() accumulator pattern** (theme-doctor lines 17-27):
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
Reuse verbatim as the accumulator for structure/name-set/semantic-value checks across all 7 render targets. Note the `$((PASS + 1))` form, not `((PASS++))` — see the `set -e` counter pitfall below (applies even though theme-parity itself has no `-e`, keep the convention consistent across all engine scripts).

**Final summary + exit code pattern** (theme-doctor lines 137-140):
```bash
echo ""
echo "Summary: ${PASS} passed, ${FAIL} failed"
[[ "$FAIL" -eq 0 ]]
exit $?
```
Reuse verbatim as theme-parity's closing block — this is what makes the tool CI/stress-test-consumable (non-zero exit on any failure) while still printing every check.

**Render-only snapshot pattern** (from `lib/generate.sh`, full file, 48 lines, and `lib/commit.sh` lines 16-19):
```bash
source "$LIB_DIR/generate.sh"

for target in materialyou catppuccin dracula gruvbox nord rosepine tokyonight; do
    tmp="$(mktemp -d)"
    if theme_engine_generate "$target" "$tmp"; then
        rendered_dir="$tmp$STATE_DIR"   # matugen -p prefix-join behavior — see commit.sh:16-19
        # ...structure/name/value checks against $rendered_dir...
    fi
    rm -rf "$tmp"
done
```
`theme_engine_generate` (lib/generate.sh lines 20-48) is the exact function `theme-apply` calls (theme-apply line 63: `theme_engine_generate "$NAME" "$TMP_DIR"`) — source and call it identically; never re-invoke `matugen` directly. Critical: `commit.sh` line 19 documents the prefix-join fact `local rendered_dir="$tmp$STATE_DIR"` — this must be copied exactly or file-discovery silently finds zero files.

**Per-file state-dir list to source from the new manifest** (theme-doctor lines 45-50 — this is the literal list `contract.json` must supersede):
```bash
for f in hyprland.conf waybar.css kitty.conf swaync.css wlogout.css \
         gtk-3.0-colors.css gtk-4.0-colors.css walker-style.css \
         yazi.toml vscodium.json; do
    [[ -f "$STATE_DIR/$f" ]]
    check "$STATE_DIR/$f exists" "$?"
done
```

---

### `theme-engine/.config/theme-engine/theme-stress-test` (new)

**Analog A (driven entrypoint call convention):** `theme-engine/.config/theme-engine/theme-apply` (86 lines, full file read)

**Argument validation pattern to reuse for the stress test's own args (Security Domain V5)** (theme-apply lines 43-58):
```bash
NAME="$1"

# Security Domain V5 — validate the argument against the ACTUAL palette
# filenames before it is ever interpolated into a filesystem path.
if [[ "$NAME" != "materialyou" ]]; then
    if [[ ! -f "$PALETTES_DIR/$NAME.json" ]]; then
        notify-send -a "Theme Switcher" "Error" \
            "Unknown theme: ${NAME}. Desktop left unchanged." \
            -i dialog-error -t 5000 2>/dev/null || true
        echo "theme-apply: unknown theme '$NAME'" >&2
        usage
        exit 1
    fi
fi
```
The stress test drives `theme-apply <name>` directly (no reimplementation) — this is the exact call the picker/init scripts make: `theme-apply "$NAME"` (see comment theme-apply lines 10-11). Do not re-derive path construction; call the existing binary.

**Notification truncation/sanitization pattern (reuse for any stress-test user-facing notification)** (theme-apply lines 63-77):
```bash
if ! theme_engine_generate "$NAME" "$TMP_DIR"; then
    ERROR_LOG="$STATE_DIR/.last-render-error.log"
    ERROR_SUMMARY="Theme render failed. Desktop left unchanged."
    if [[ -f "$ERROR_LOG" ]]; then
        ERROR_SUMMARY=$(head -c 200 "$ERROR_LOG" | tr -d '\000-\011\013\014\016-\037')
    fi
    notify-send -a "Theme Switcher" "Error" "${ERROR_SUMMARY}" \
        -i dialog-error -t 5000 2>/dev/null || true
    ...
fi
```

**Analog B (per-switch process-health check style):** `theme-engine/.config/theme-engine/theme-doctor` walker/elephant section (lines 70-135) — reuse verbatim as the stress test's per-switch health assertion:
```bash
if command -v elephant >/dev/null 2>&1; then
    ELEPHANT_VERSION=$(elephant version 2>/dev/null)
    [[ -n "$ELEPHANT_VERSION" ]]
    check "elephant version responds (got: ${ELEPHANT_VERSION:-<empty>})" "$?"
    elephant listproviders >/dev/null 2>&1
    check "elephant listproviders responds" "$?"
fi
...
pgrep -x walker >/dev/null 2>&1
check "walker process running" "$?"
pgrep -x elephant >/dev/null 2>&1
check "elephant process running" "$?"
```

**Analog C (bounded-poll pattern — MUST reuse, not reimplement):** `theme-engine/.config/theme-engine/lib/reload.sh` lines 67-71 and `lib/gtk.sh` lines 108-115, 171-175:
```bash
local waited=0
while pgrep -x walker >/dev/null 2>&1 && (( waited < 20 )); do
    sleep 0.1
    waited=$(( waited + 1 ))
done
```
**CRITICAL gotcha, documented in-repo (reload.sh lines 53-66):** never use `(( counter++ ))` — under `set -e` this evaluates to the PRE-increment value, so at `counter=0` it returns exit status 1 and aborts the script silently. Always use `counter=$((counter + 1))`. This exact bug was reproduced and fixed in Phase 1 round "01-03" — any new bounded-poll loop in the stress test must follow the `$((x+1))` form.

**Analog D (Thunar-window-open detection via hyprctl+jq, reuse verbatim):** `lib/gtk.sh` lines 51-59:
```bash
if pgrep -x thunar >/dev/null 2>&1; then
    local thunar_has_window=0
    if command -v hyprctl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
        if hyprctl clients -j 2>/dev/null \
            | jq -e '[.[] | select(.class | ascii_downcase == "thunar")] | length > 0' \
            >/dev/null 2>&1; then
            thunar_has_window=1
        fi
    fi
fi
```
Use this exact `hyprctl clients -j | jq -e '... ascii_downcase == "thunar" ...'` idiom for the stress test's precondition (open a Thunar window) and postcondition checks (D-34).

**Analog E (walker D-Bus bus-name health check via busctl, reuse verbatim):** `lib/reload.sh` lines 97-103, 157-166:
```bash
if command -v busctl >/dev/null 2>&1; then
    local bwaited=0
    while busctl --user status "$bus_name" >/dev/null 2>&1 && (( bwaited < 20 )); do
        sleep 0.1
        bwaited=$(( bwaited + 1 ))
    done
fi
...
if pgrep -x walker >/dev/null 2>&1 \
    && { ! command -v busctl >/dev/null 2>&1 || busctl --user status "$bus_name" >/dev/null 2>&1; }; then
    walker_up=1
fi
```
`bus_name="dev.benz.walker"` — the stress test's D-38 "walker service health" assertion should check both `pgrep -x walker` AND this busctl bus-name registration, not process-existence alone (a registration-failed walker instance can still show up in `pgrep`).

**Sentinel-color extraction + FORMAT-NORMALIZED comparison (D-36) — critical, do not literal-grep:**
```bash
# Strip to bare 6 lowercase hex digits regardless of source format
# (handles bare hex, #-prefixed hex, and Hyprland's rgba(RRGGBBAA) no-comma form).
normalize_color() {
    local raw="$1"
    raw="${raw,,}"
    raw="${raw#\#}"
    if [[ "$raw" =~ ^rgba\(([0-9a-f]{6})[0-9a-f]{2}\)$ ]]; then
        echo "${BASH_REMATCH[1]}"
    elif [[ "$raw" =~ ^([0-9a-f]{6})$ ]]; then
        echo "${BASH_REMATCH[1]}"
    else
        return 1
    fi
}
```
Source: RESEARCH.md Pattern 2, verified against live `gtk-4.0-colors.css` (`@define-color primary #ebbcba;`) vs. live `hyprland.conf` (`$primary = rgba(ebbcbaff)`) for the same underlying color. A naive literal-string grep will silently never match `hyprland.conf`'s format — this is the single most important correctness pitfall for both `theme-parity` and the stress test's sentinel check.

---

### `theme-engine/.config/theme-engine/contract.json` (new manifest)

**No direct code analog** — this is a new concept. The literal content it must generalize/replace is `theme-doctor`'s hardcoded file list (lines 45-50, reproduced above) plus the 4-way format inventory from RESEARCH.md Pattern 1:

| File | Format family | Variable syntax | Extraction approach |
|------|---------------|------------------|----------------------|
| `waybar.css`, `swaync.css`, `wlogout.css`, `gtk-3.0-colors.css`, `gtk-4.0-colors.css` | GTK-CSS named color | `@define-color <name> <value>;` | `grep -oP '@define-color \K\S+'` |
| `hyprland.conf` | Shell-style variable | `$<name> = <value>` | `grep -oP '^\$\K[A-Za-z_]+(?= =)'` |
| `kitty.conf` | Bare key-value | `<name>  <value>` | `grep -oP '^[A-Za-z0-9_]+(?=\s)'` |
| `yazi.toml` | Nested TOML | `key = { fg = ..., bg = ... }` | `python3 -c "import tomllib..."` recursive key-walk |
| `vscodium.json` | Nested JSON | standard JSON | `jq -r '.. | objects | keys[]'` |
| `walker-style.css` | Raw CSS, no named vars | hex/rgba interpolated directly | distinct `format: "css-literal"` entry — check selector/line-count shape + well-formed values only, no name-set diff |

**Known intentional exemption to encode in the manifest** (from `hyprland-colors.conf` template, confirmed by Phase 1 STATE.md): `hyprland.conf`'s `$image =` key is deliberately blank in every mode (matugen 4.1.0 has no `colors.image` context) — the manifest needs a per-file, per-key exemption list or every single run will report a permanent false-positive.

---

### `theme-engine/.config/theme-engine/lib/contract.sh` (optional shared helper, Claude's discretion)

**Analog:** `theme-engine/.config/theme-engine/lib/gtk.sh` (236 lines) and `lib/reload.sh` (193 lines) — both are `source`-only function libraries with no `#!/usr/bin/env bash` execution guard expectation, following the same header-comment + function-per-concern convention:
```bash
#!/usr/bin/env bash
# theme-engine/lib/gtk.sh — gsettings toggle + GTK theme env propagation
# (D-13/PIPE-05)
#
# [purpose paragraph explaining ownership/invariant this file protects]

# theme_engine_gtk_reload
theme_engine_gtk_reload() {
    ...
}
```
`lib/contract.sh` should follow this exact shape: one purpose-comment block, then one function per extraction-format (`contract_extract_gtkcss`, `contract_extract_hyprvars`, `contract_extract_kitty`, `contract_extract_toml`, `contract_extract_json`, `contract_normalize_color`), sourced by both `theme-parity` and `theme-stress-test` — mirroring how `theme-apply` sources `lib/generate.sh` + `lib/commit.sh` + `lib/gtk.sh` + `lib/reload.sh` (theme-apply lines 21-28).

---

### `theme-engine/.config/theme-engine/theme-doctor` (modified in place)

**Analog:** itself — refactor lines 45-50's hardcoded `for f in ... ; do` loop to read the same file list (and future per-file check metadata) from `contract.json` instead of the inline literal, per D-30. Preserve every other check in the file unchanged (adw-gtk-theme check lines 32-34, gsettings check lines 36-39, symlink checks lines 52-59, stow check lines 61-68, walker/elephant/provider-parity checks lines 70-135) — those are out of this phase's scope to alter beyond the file-list source.

---

## Shared Patterns

### Report-only strict-mode + accumulator (theme-parity, and theme-doctor unchanged)
**Source:** `theme-doctor` lines 8, 17-27, 137-140
**Apply to:** `theme-parity` in full. Do NOT apply `theme-apply`'s `set -euo pipefail` to any report-only tool — that mutating-tool strict mode aborts on the first failed check and hides every subsequent one (see theme-apply line 13 vs theme-doctor line 8 for the contrast).

### Bounded-poll (never a fixed sleep, never `((x++))`)
**Source:** `lib/reload.sh` lines 53-71, 97-103, 148-166; `lib/gtk.sh` lines 108-115, 171-175
**Apply to:** `theme-stress-test`'s every process-liveness/wait check (Thunar quit, walker relaunch, elephant health, D-Bus bus-name release). Copy the exact `while <cond> && (( waited < 20 )); do sleep 0.1; waited=$(( waited + 1 )); done` shape and the `$((x+1))` increment form — this exact bug (`(( counter++ ))` silently aborting under `set -e`) was already found and fixed once in this codebase (Phase 1, round "01-03"); do not reintroduce it in new scripts.

### Render-only temp-dir snapshot + prefix-join
**Source:** `lib/generate.sh` (full file), `lib/commit.sh` lines 16-19
**Apply to:** `theme-parity`'s 7-target render loop. `theme_engine_generate "$name" "$tmp"` is called identically to how `theme-apply` calls it (theme-apply line 63); the rendered tree always lands at `"$tmp$STATE_DIR"`, never `"$tmp"` directly.

### Argument validation against real filenames (Security V5)
**Source:** `theme-apply` lines 45-58
**Apply to:** Any new script (`theme-parity`, `theme-stress-test`) that accepts a theme-name argument — validate against `$PALETTES_DIR/$NAME.json` existing on disk before ever interpolating into a path; reject unknown names outright.

### Notification content sanitization
**Source:** `theme-apply` lines 66-74 (`head -c 200 ... | tr -d '\000-\011\013\014\016-\037'`)
**Apply to:** Any raw command stderr the stress test surfaces via `notify-send` — truncate and strip control chars first; full detail goes to the log file only.

### Format-normalized color comparison (critical, applies to both new tools)
**Source:** RESEARCH.md Pattern 2, verified against live `gtk-4.0-colors.css` vs live `hyprland.conf`
**Apply to:** `theme-parity`'s semantic-value checks (D-28) and `theme-stress-test`'s sentinel-color check (D-36). Never compare raw literal color strings across files — normalize both sides to bare lowercase 6-hex-digit form first (see `normalize_color()` above).

### hyprctl+jq Thunar-window detection
**Source:** `lib/gtk.sh` lines 51-59, 160-166 (duplicated identically in the deferred watcher)
**Apply to:** `theme-stress-test`'s precondition ("open a Thunar window") and postcondition checks (D-34).

### busctl D-Bus bus-name health check
**Source:** `lib/reload.sh` lines 97-103, 157-166 (`bus_name="dev.benz.walker"`)
**Apply to:** `theme-stress-test`'s walker service-health assertion (D-38) — process existence alone is insufficient; check bus-name registration too.

## No Analog Found

None — all 5 files have at least a role-match analog in the existing codebase; `contract.json` is a genuinely new artifact but its content is directly derivable from `theme-doctor`'s existing hardcoded file list plus RESEARCH.md's already-verified per-file format inventory (no invention needed).

## Metadata

**Analog search scope:** `theme-engine/.config/theme-engine/` (theme-apply, theme-doctor, lib/generate.sh, lib/commit.sh, lib/reload.sh, lib/gtk.sh) — the entire theme-engine stow package; no other directories in the repo contain comparable shell-script CLI/library patterns for this phase's scope.
**Files scanned:** 6 (all files under `theme-engine/.config/theme-engine/`, 754 total lines, all read in full — no file exceeded the 2,000-line large-file threshold)
**Pattern extraction date:** 2026-07-08
