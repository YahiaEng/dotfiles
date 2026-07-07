---
phase: 02-static-dynamic-parity-switch-reliability
reviewed: 2026-07-07T22:45:00Z
depth: standard
files_reviewed: 6
files_reviewed_list:
  - theme-engine/.config/theme-engine/contract.json
  - theme-engine/.config/theme-engine/lib/commit.sh
  - theme-engine/.config/theme-engine/lib/contract.sh
  - theme-engine/.config/theme-engine/theme-doctor
  - theme-engine/.config/theme-engine/theme-parity
  - theme-engine/.config/theme-engine/theme-stress-test
findings:
  critical: 1
  warning: 5
  info: 7
  total: 13
status: issues_found
---

# Phase 02: Code Review Report

**Reviewed:** 2026-07-07T22:45:00Z
**Depth:** standard
**Files Reviewed:** 6
**Status:** issues_found

## Summary

Reviewed the phase-02 verification layer (contract.json manifest, lib/contract.sh extraction library, theme-parity, theme-stress-test) plus the two modified files (theme-doctor, lib/commit.sh). Cross-referenced against lib/generate.sh, theme-apply, the matugen templates (hyprland-colors.conf, kitty-colors.conf, gtk-colors.css, walker-style.css, swaync/wlogout/waybar templates), palettes/nord.json, walker/config.toml, install.sh, and live `elephant listproviders` output to validate every extraction regex and sentinel path against the real data it parses.

The happy path is sound: extraction regexes match the actual template output formats (verified line-by-line against rendered-template shapes), the sentinel `primary` value exists in every representative file, the palette JSON schema matches `.colors.primary.default.color`, the accepted theme-doctor gap logic (`unexpected <= accepted`) is arithmetically correct in all branches, and the `rsync --exclude=logs/` fix genuinely closes the log-deletion data-loss bug.

The dominant defect class is **silent false-pass paths in the verification tools themselves**: theme-parity can report overall PASS while executing zero (or vacuous) parity comparisons, and its documented "`{{...}}` leftovers are always a failure" guarantee does not hold for the css-literal format. A verifier whose failure mode is a false green light is the highest-impact defect this phase can ship.

## Critical Issues

### CR-01: theme-parity / theme-doctor silently false-pass when extraction produces nothing

**File:** `theme-engine/.config/theme-engine/lib/contract.sh:48-172`, `theme-engine/.config/theme-engine/theme-parity:89,135-153,210-212`, `theme-engine/.config/theme-engine/theme-doctor:50-53`
**Issue:** Every extraction path treats "no output" as success, so entire verification layers can vanish while the tool still exits 0:

1. **Unknown/typo format tag → vacuous PASS on all three layers.** `contract_extract_names`/`contract_extract_values` hit the `*)` branch, `return 1` with no output. In theme-parity Layer 2, `names="$(...)"` swallows the exit code; all targets extract the empty string, empty == empty, and every "name-set matches" check PASSES. In Layer 3, the `while ... < <(contract_extract_values ...)` loop iterates zero times, `bad=0`, and "semantic values well-formed" PASSES. Adding a contract.json entry with a misspelled `format` (the exact drift this file exists to prevent) yields all-green output.
2. **Extraction tool failure → same vacuous PASS.** Both `python3 ... 2>/dev/null` (toml) and `jq ... 2>/dev/null` (json) discard all errors. If python3/jq is missing or the file is unparseable, yazi.toml and vscodium.json pass every parity layer with zero data examined. Note a *corrupt* yazi.toml (broken TOML syntax) is precisely a failure this tool should catch — instead tomllib's parse error is discarded and the file passes.
3. **Empty reference name-set is accepted.** theme-parity:146 (`check "$fname: $target name-set captured as reference" "0"`) passes unconditionally, even when the captured reference is empty — there is no "reference set is non-empty" guard analogous to the render-layer's Pitfall-4 zero-file guard.
4. **`contract_files` failure erases the checks entirely.** If jq is absent or contract.json is missing/unreadable, `CONTRACT_FILE_LIST` is empty: theme-parity Layers 1–3 loop zero times and the script **exits 0** on render checks alone; theme-doctor's ten per-state-file existence checks silently disappear from its output (PASS/FAIL counts just shrink), weakening every downstream consumer including theme-stress-test's `check_theme_doctor`.

The script's own header states Pitfall-4 discipline ("a zero-file render is a FAIL, never a silent skip/false-pass") — the same discipline is not applied to zero-key extraction or zero-file contracts.

**Fix:**
```bash
# theme-parity, after CONTRACT_FILE_LIST="$(contract_files)":
if [[ -z "$CONTRACT_FILE_LIST" ]]; then
    echo "theme-parity: contract_files produced no entries (jq missing or contract.json unreadable)" >&2
    exit 1
fi

# Layer 2 — refuse an empty reference for formats that must have keys:
if [[ -z "$reference_target" ]]; then
    if [[ -z "$names" ]]; then
        check "$fname: $target name-set captured as reference (non-empty)" "1"
        continue
    fi
    ...
fi

# lib/contract.sh — make an unknown format loud:
*)
    echo "contract.sh: unknown format '$fmt' for '$name'" >&2
    return 1
    ;;
# and in theme-parity, capture the extractor's exit status:
if ! names="$(contract_extract_names "$fname" "$path")"; then
    check "$fname: $target name extraction succeeded" "1"; continue
fi
```
Apply the same non-empty guard to `contract_files` inside theme-doctor (FAIL, don't skip, when it emits nothing), and drop the blanket `2>/dev/null` on the python3/jq extractors (or convert their failure into an explicit FAIL).

## Warnings

### WR-01: `{{...}}` template leftovers in walker-style.css are invisible to the parity check, contradicting the documented guarantee

**File:** `theme-engine/.config/theme-engine/lib/contract.sh:165-167`, `theme-engine/.config/theme-engine/theme-parity:169,189-193`
**Issue:** theme-parity's Layer-3 comment promises "`{{...}}` template leftovers are always a failure regardless of format (Pitfall 2/3)". For css-literal, that is false: `contract_extract_values` only emits tokens matching `#[0-9a-fA-F]{6}|rgba\([^)]*\)`. A leftover like `background-color: {{colors.background.default.hex}};` contains neither pattern, so it is never emitted, the `*'{{'*` check at theme-parity:189 never sees it, and the file PASSES all three layers (Layer-2 selector/property pairs are unchanged by a value-position leftover, and all targets render from the same template so cross-target comparison also matches). walker-style.css is precisely the file with the worst regression history in this repo (the fix(01-03) silent-unstyled bug documented in its own template header).
**Fix:** Add a direct leftover scan per rendered file, independent of format extraction:
```bash
if grep -q '{{' "$path"; then bad=1; echo "    -> $target/$fname: raw {{ template leftover present"; fi
```
Run it for every contract file (cheap, format-agnostic), not just css-literal.

### WR-02: commit.sh deletes `current-theme` (and `.last-render-error.log`) mid-commit — the "atomic replace" claim does not hold

**File:** `theme-engine/.config/theme-engine/lib/commit.sh:45-54`
**Issue:** `$STATE_DIR/current-theme` is not in the rendered tree, so `rsync -a --delete` removes it during the sync; it is only recreated at line 54. Two consequences: (1) a concurrent reader (theme-init.sh at login, the picker showing the active theme) can observe a state dir with rendered files but no `current-theme`; (2) if the process dies between rsync and line 54 (crash, power loss, rsync error under the caller's `set -e`), `current-theme` is permanently lost while the state files have already changed — D-14's atomicity claim is violated exactly where it matters. The same `--delete` also removes `$STATE_DIR/.last-render-error.log` (written by generate.sh even on success via `2>"$GENERATE_LOG"`) — harmless today but accidental, and the comment's claim that logs/ is the only engine-owned path needing protection overlooks these two root-level engine-owned files. contract.json even declares `"state_metadata_files": ["current-theme"]` yet commit.sh does not consult or protect it.
**Fix:** Minimal: add `--exclude=current-theme --exclude=.last-render-error.log` to the rsync (line 54's rewrite makes the exclusion safe), and write `current-theme` via temp-file + `mv` for per-file atomicity:
```bash
rsync -a --delete --exclude=logs/ --exclude=current-theme --exclude=.last-render-error.log \
    "$rendered_dir"/ "$STATE_DIR"/
printf '%s\n' "$name" > "$STATE_DIR/current-theme.tmp" && mv "$STATE_DIR/current-theme.tmp" "$STATE_DIR/current-theme"
```

### WR-03: abort_with_diagnostics re-runs theme-doctor instead of dumping the captured output — `THEME_DOCTOR_OUTPUT` is dead

**File:** `theme-engine/.config/theme-engine/theme-stress-test:134,207-209`
**Issue:** `check_theme_doctor` captures the failing run into the global `THEME_DOCTOR_OUTPUT` (line 209), but `abort_with_diagnostics` ignores it and re-executes `"$ENGINE_DIR/theme-doctor"` (line 134). The variable is assigned and never read anywhere — dead code that signals intended-but-unwired behavior. In a *stress* harness whose purpose is catching transient/flaky states, the re-run can observe a recovered system (e.g., walker briefly dead during reload but respawned seconds later), so the diagnostics dump shows a healthy doctor run for a failure that D-39 exists to evidence.
**Fix:** In the dump, print the captured output when present and fall back to a fresh run only for non-doctor failures:
```bash
echo "-- theme-doctor output (captured at failure time) --"
if [[ -n "$THEME_DOCTOR_OUTPUT" ]]; then
    printf '%s\n' "$THEME_DOCTOR_OUTPUT"
else
    "$ENGINE_DIR/theme-doctor" 2>&1
fi
```

### WR-04: theme-parity mutates live state despite its "never mutates state" banner

**File:** `theme-engine/.config/theme-engine/theme-parity:5,97` (via `lib/generate.sh:12,24,31,36,42`)
**Issue:** The header declares "Report-only — never mutates state, never fires a reload", but every `theme_engine_generate` call theme-parity makes truncates/overwrites the **live** `$STATE_DIR/.last-render-error.log` (generate.sh redirects matugen stderr there unconditionally, even on success) and `mkdir -p`s the live state dir. Concretely: if a real `theme-apply` just failed and the user's error log holds the diagnosis, running theme-parity destroys that evidence (7 successive truncations). theme-parity also creates `$STATE_DIR/logs/` — acceptable and intended, but the error-log clobber is not.
**Fix:** Let the caller redirect the render log: parameterize `GENERATE_LOG` (e.g., honor an existing environment override in generate.sh — `GENERATE_LOG="${THEME_ENGINE_RENDER_LOG:-$HOME/.local/state/theme/.last-render-error.log}"`) and have theme-parity point it into its temp dir or `$LOG_DIR`.

### WR-05: hypr-vars extraction regexes silently drop variable names containing digits

**File:** `theme-engine/.config/theme-engine/lib/contract.sh:59,132`
**Issue:** Both the name extractor (`^\$\K[A-Za-z_]+(?= =)`) and the value extractor (`^\$([A-Za-z_]+)[[:space:]]*=`) exclude digits. Today's hyprland-colors.conf template uses only lowercase/underscore names, so this is latent — but the kitty-kv extractor (`^[A-Za-z0-9_]+`) does allow digits, so the inconsistency is unintentional. If a `$color4`- or `$surface2`-style Hyprland variable is ever added, the line matches neither regex: it disappears from the name-set (all targets equally, so Layer 2 still passes) *and* from value extraction, meaning the sentinel check in theme-stress-test would never see it and semantic-value validation never inspects it. In a parity tool, silent exclusion is a false-pass generator.
**Fix:** Use `[A-Za-z_][A-Za-z0-9_]*` in both patterns:
```bash
grep -oP '^\$\K[A-Za-z_][A-Za-z0-9_]*(?= =)' "$path"
sed -nE 's/^\$([A-Za-z_][A-Za-z0-9_]*)[[:space:]]*=[[:space:]]*(.*)$/\1\t\2/p' "$path"
```

## Info

### IN-01: css-literal name extractor emits garbage pairs from the template's own comment block

**File:** `theme-engine/.config/theme-engine/lib/contract.sh:94-108`
**Issue:** The awk has no `/* ... */` comment handling. In the rendered walker-style.css, the header comment line containing `resources/themes/default/{layout,item}.xml)` matches `/\{/` and sets `sel` to comment text (the `next` also prevents the same line's `}` from clearing it); the later comment line containing `src/theme/mod.rs:` then emits a garbage "selector property" pair into the name-set. Today all targets render the identical comment so parity still agrees, but the extracted set is polluted and any format-conditional divergence in comments would false-fail.
**Fix:** Strip comments first, e.g. pipe the file through `sed 's://.*::' | awk 'BEGIN{RS="*/"} {gsub(/\/\*.*/,"")} 1'` (or a small state flag in the existing awk) before block parsing.

### IN-02: theme-doctor writes to a predictable world-shared /tmp path

**File:** `theme-engine/.config/theme-engine/theme-doctor:67`
**Issue:** `2>/tmp/theme-doctor-stow.log` is a fixed, predictable filename in shared /tmp opened with a truncating redirect — the classic insecure-temp-file pattern (mitigated on default Arch by `fs.protected_symlinks`, and this is a single-user machine, hence Info not Warning). The captured stow output is also never surfaced on failure, so it serves no diagnostic purpose.
**Fix:** Use `mktemp` (and print the path on FAIL), or drop the redirect entirely: `stow -n theme-engine >/dev/null 2>&1`.

### IN-03: contract.json's `state_metadata_files` key has no consumer

**File:** `theme-engine/.config/theme-engine/contract.json:14`, `theme-engine/.config/theme-engine/theme-doctor:45`
**Issue:** Nothing reads `state_metadata_files` (verified by repo-wide grep). theme-doctor hardcodes its `current-theme` check and commit.sh does not use it for rsync protection (see WR-02), so the "single source of truth" claim only covers `.files`. Dead manifest keys invite drift — the exact failure mode contract.json was created to prevent.
**Fix:** Either wire it (theme-doctor iterates it; commit.sh derives `--exclude` flags from it) or remove the key.

### IN-04: stress-test's accepted-gap match masks growth of the provider gap and is coupled to theme-doctor's exact wording

**File:** `theme-engine/.config/theme-engine/theme-stress-test:210-218`, `theme-engine/.config/theme-engine/theme-doctor:135`
**Issue:** The acceptance treats *any* provider-parity FAIL as the known gap — if elephant additionally lost `desktopapplications` or `calc` mid-run (a real regression this harness should catch), the FAIL line is identical in shape and still accepted. Separately, the acceptance greps a literal description prefix; any future rewording of that check description in theme-doctor makes every stress switch abort (fail-loud, at least, but confusingly).
**Fix:** Have theme-doctor include the missing set in a stable machine-readable form and let the stress-test compare it against a pinned baseline (e.g., `menus runner websearch files providerlist`), aborting if the set grows.

### IN-05: stress-test does not restore the pre-run theme

**File:** `theme-engine/.config/theme-engine/theme-stress-test:330-407`
**Issue:** A bare run overwrites the user's `current-theme` and leaves the desktop on `materialyou` (last even switch) with no restoration. Mutation is documented, but restoration is cheap and would make the harness rerunnable without side effects.
**Fix:** Read `$STATE_DIR/current-theme` before the preconditions and re-apply it after the postconditions (best-effort, outside the abort path).

### IN-06: minor color-parsing gaps in contract.sh

**File:** `theme-engine/.config/theme-engine/lib/contract.sh:166,199-208`
**Issue:** (a) The css-literal value grep `#[0-9a-fA-F]{6}` would match only the first 6 digits of an 8-digit `#RRGGBBAA` token (truncated color) and misses `rgb()`/3-digit hex forms — none are used in current templates, latent only. (b) `contract_wellformed_color` accepts out-of-range components (`rgb(999, 0, 0)`) and malformed alphas (`[0-9.]+` accepts `0..3`).
**Fix:** Use `#[0-9a-fA-F]{8}|#[0-9a-fA-F]{6}` alternation ordering (longest first) and tighten the alpha to `(0|1|0?\.[0-9]+)`.

### IN-07: materialyou sentinel is self-referential for waybar.css

**File:** `theme-engine/.config/theme-engine/theme-stress-test:233-243,273`
**Issue:** For materialyou the expected sentinel is read *from* the just-committed `$STATE_DIR/waybar.css`, then asserted present in `waybar.css` — that one check is a tautology (it validates only extraction+normalization round-trip). The other five representative files carry the real cross-file signal, and the code comment acknowledges the deviation, so this is informational: the per-switch coverage for materialyou is 5 meaningful files, not 6.
**Fix:** For materialyou, derive the expected value from matugen's own render in the temp tree before commit, or simply exclude waybar.css from the representative loop when it is the sentinel source.

---

_Reviewed: 2026-07-07T22:45:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
