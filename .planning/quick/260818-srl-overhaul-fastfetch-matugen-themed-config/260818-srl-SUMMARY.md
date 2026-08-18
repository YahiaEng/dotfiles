---
quick_id: 260818-srl
date: 2026-08-18
mode: quick
status: complete
one_liner: fastfetch folded into the matugen theme pipeline — closed box, 6 palette-drawn animated logo sprites, 13-entry fzf picker on a keybind and a command
key_files:
  created:
    - matugen/.config/matugen/templates/fastfetch.jsonc
    - fastfetch/.config/fastfetch/art/arch.txt
    - fastfetch/.config/fastfetch/box-close.awk
    - theme-engine/.config/theme-engine/lib/fastfetch-sprites.py
    - theme-engine/.config/theme-engine/lib/fastfetch.sh
    - hypr/.config/hypr/scripts/fastfetch-logo-picker.sh
    - hypr/.config/hypr/scripts/fastfetch-logo-switch.sh
    - fish/.config/fish/functions/fastfetch-logo.fish
  modified:
    - matugen/.config/matugen/config.toml
    - theme-engine/.config/theme-engine/contract.json
    - theme-engine/.config/theme-engine/theme-apply
    - fish/.config/fish/config.fish
    - install.sh
    - hypr/.config/hypr/config/keybinds.lua
    - hypr/.config/hypr/scripts/hypr-equivalence-check
  deleted:
    - fastfetch/.config/fastfetch/config.jsonc
decisions:
  - "display.color roles: keys=tertiary, title=primary, output=on_surface, separator=outline (all >=5.85:1 vs surface, measured live)"
  - "logo.color: all nine slots defined regardless of active art (1=primary default, 2-9 cycle through secondary/tertiary/on_*_container/on_surface/outline)"
  - "Box width fixed at 54 display columns by measuring the widest rendered content row on this host (49) plus a 5-column margin, replacing the retired config.jsonc's hardcoded-38 guess"
  - "box-close.awk captures border colour from the row's own SGR, never a hardcoded constant, so template and filter cannot drift apart"
  - "Sprite regen on theme switch is bounded to the single active sprite only (T-srl-03) — the picker's own cache-warm-on-open is the only place all six are ever generated together"
  - "3d: picker does NOT re-run theme-apply on selection — fastfetch-logo is a theme-orthogonal axis, colours did not change"
metrics:
  duration: "~2h 45min (single session)"
  completed: 2026-08-18
actuals:
  tasks: 3
  commits: 3
---

# Quick Task 260818-srl: Fastfetch Overhaul Summary

fastfetch — the one stowed surface still outside this repo's theme pipeline — now renders a matugen-themed, fully closed box; every module in the shipped config actually emits a row; six palette-drawn animated logo sprites regenerate in the live palette on theme switch; and a 13-entry fzf picker (keybind + command) switches between them, five ASCII arts, `random`, and `none`.

## What Was Built

**Task 1 — Themed, closed, reworked box (the tracer).** `matugen/templates/fastfetch.jsonc` is the 14th matugen template, rendering `display.color` (keys/title/output/separator, every role foreground-intent, measured 5.85:1–14.42:1 against `surface`) and all nine `logo.color` slots. The box rule lives in `display.constants[0]` once, referenced via `{$1}` in every rule row (verified live this session that fastfetch supports this). Since the rendered file must pass `jq -e .` (both this task's own verification and theme-parity's own `format: json` extractor use `jq`), the template itself carries zero `//` comments — all rationale and measurements moved into `config.toml`'s `[templates.fastfetch]` header instead, unlike the heavily-commented `[templates.fish]`/`[templates.hyprland_lua]` (fish/Lua tolerate comments; `jq` does not).

`fastfetch/art/arch.txt` is fastfetch's own builtin arch logo, extracted from a live render (`fastfetch -c <logo-only config> --pipe false`, ANSI-stripped, re-marked with `$1` since the whole logo turned out to render in a single colour — confirmed by inspecting the actual escape sequences, not assumed). Zero `│` (M-7 held).

`fastfetch/box-close.awk` self-calibrates off the box's own top rule (measured from the first `┌` onward, not the whole raw line — a real bug found and fixed live, see Deviations) and appends a border captured from each row's own leading SGR sequence. A second real bug (also fixed live): the first working version stripped ALL internal SGR from content rows before printing, flattening a two-colour "key: value" row to one colour — fixed by printing the original (SGR-intact) substring and using the stripped copy only to measure the pad amount.

`fish/config.fish`'s bare `fastfetch` became a selector that validates the `fastfetch-logo` state value against the enumerated set before any path interpolation (T-srl-01), degrades to plain `fastfetch` when `fastfetch.jsonc` doesn't exist yet (fresh install), and pipes through `box-close.awk` with `--pipe false` (M-4, load-bearing — confirmed live that a pipe silently strips colour without it).

**Task 2 — Palette-drawn animated sprites.** `theme-engine/lib/fastfetch-sprites.py` ports the six effects (pulse, sweep, glitch, scan, assemble, orbit) from the operator-reviewed prototype verbatim, with exactly the three specified production changes: palette read from `palette.json`, mask rasterised from `/usr/share/pixmaps/archlinux-logo.svg` via ImageMagick instead of a committed PNG, and an atomic-write + palette-hash-sidecar output contract. `theme-engine/lib/fastfetch.sh` regenerates only the active sprite on every `theme-apply`, hooked after `theme_engine_commit` and before `theme_engine_reload`, `|| true` throughout.

**Task 3 — The picker.** `hypr/scripts/fastfetch-logo-picker.sh` mirrors `icon-theme-picker.sh`'s discipline: the signal-vs-EXIT-trap fix, one mktemp'd script under one EXIT trap, fzf-colors.conf with graceful fallback, T-srl-02 re-validation before any state write, atomic write, cache-warm-on-open in the background. `keybinds.lua` binds `SUPER+SHIFT+T` beside `SUPER+T`. `fish/functions/fastfetch-logo.fish` is the command entrypoint (`stow -R fish` run and the resulting symlink verified — the one path in this whole task where the whole-dir-symlink shortcut doesn't apply, M-9).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] box-close.awk measured the box width off the WHOLE raw line, not from the box's own left border**
- **Found during:** Task 1, first live width-consistency check (`sort -u | wc -l` returned 2, not 1)
- **Issue:** `W = length(strip_sgr($0))` on the top-rule line included the leading logo-column padding blanks fastfetch prepends before the box (the logo sits left of the box), inflating `W` from the intended 54 to 93+ columns.
- **Fix:** Measure from the first `┌` onward (`substr($0, index($0,"┌"))`), matching the content-row logic (which already measured from the first `│`) and matching what the box-close.awk header comment had already described as the intended design.
- **Files modified:** `fastfetch/box-close.awk`
- **Commit:** 5eb6f7c

**2. [Rule 1 - Bug] box-close.awk flattened multi-colour content rows to one colour**
- **Found during:** Task 1, live colour-inventory check on the rendered box (grep for distinct `38;2;R;G;B` sequences found only 3, missing `on_surface` entirely)
- **Issue:** The content-row print statement used the SGR-stripped copy of the line (`stripped`), destroying every internal colour transition (keys in `tertiary`, values in `on_surface`) — the whole row rendered in whatever colour preceded the `│`.
- **Fix:** Print the original SGR-intact substring (`from_bar`); use the stripped copy only to compute the pad width.
- **Files modified:** `fastfetch/box-close.awk`
- **Commit:** 5eb6f7c

**3. [Rule 1 - Bug] The `.jsonc` template's constants string was 50 dashes, not the intended 52**
- **Found during:** Task 1, immediately after fixing deviation 1 (the width-consistency check still failed once, off by 2)
- **Issue:** A manual dash-count typo when writing the `display.constants` array.
- **Fix:** Regenerated the exact-length dash string with `python3 -c "print('─'*52)"` and re-verified the total rule width (54) programmatically before moving on.
- **Files modified:** `matugen/templates/fastfetch.jsonc`
- **Commit:** 5eb6f7c

**4. [Rule 1 - Bug] `hypr-equivalence-check` FAILed after adding the new keybind**
- **Found during:** Task 3, running the plan's own verify block
- **Issue:** `binds.json`'s structural comparator diffs the live bind set against a frozen pre-migration baseline; a genuinely new bind reads as an unrecognised addition unless registered in the existing `ACCEPTED_ADDITIONS` allowlist (the same LEDGER-07 mechanism two prior phases already used for their own new binds).
- **Fix:** Added `("", 65, "T", False): "Quick task 260818-srl fastfetch logo picker (keybinds.lua:106)"` to `ACCEPTED_ADDITIONS`, with the modmask confirmed live via `hyprctl -j binds` rather than computed from the SUPER=64/SHIFT=1 bitmask assumption.
- **Files modified:** `hypr/scripts/hypr-equivalence-check`
- **Commit:** 3dc577b

**5. [Rule 1 - Bug] `fastfetch-sprites.py`'s `load_palette()` returned a dict keyed inconsistently with how it was read**
- **Found during:** Task 2, first `--all` run (`KeyError: 'onSurface'`)
- **Issue:** An early draft mapped raw palette.json keys to differently-cased local names, then read the result back under the original camelCase names.
- **Fix:** Simplified to an identity key set (`PALETTE_KEYS` is just the six camelCase names used throughout, both to read from `palette.json` and to read back from the loaded dict).
- **Files modified:** `theme-engine/lib/fastfetch-sprites.py`
- **Commit:** e2e7cc1

**6. [Rule 1 - Bug] `fastfetch-sprites.py`'s GIF save failed on the `.tmp` atomic-write suffix**
- **Found during:** Task 2, first `--all` run (`ValueError: unknown file extension: .tmp`)
- **Issue:** Pillow infers the save format from the file extension by default; the atomic-write temp path ends in `.gif.tmp`, which Pillow doesn't recognise.
- **Fix:** Pass `format="GIF"` explicitly to `Image.save()`.
- **Files modified:** `theme-engine/lib/fastfetch-sprites.py`
- **Commit:** e2e7cc1

None of the six required an architectural decision or user input — all were caught and closed by the plan's own live-measurement verification steps within the same task.

## Measured, Not Assumed

- **terminalfont was NOT the "known offender" the plan flagged.** Measured inside a real kitty window (spawned via `kitty -e fish -c '...'`, output captured to a file — not the nested probe shell this session's own tool wrapper runs under): `font: FiraCodeNF-Reg (12pt)`, term correctly detected as `kitty 0.48.2`. The "Unknown terminal: claude" symptom seen when probing directly from this session's own Bash tool was an artifact of fastfetch's process-tree climbing hitting this session's own wrapper process before reaching kitty — confirmed by testing the SAME config both ways side by side. No module was dropped; the shipped set already covered identity/system/session/hardware/colours honestly.
- **Sprite frame counts are 18/10/24/24/24/21, not a flat 24 across all six.** Verified this is Pillow's `optimize=True` legitimately merging runs of identical consecutive frames (glitch and assemble hold long static stretches), NOT a defect in the port — confirmed byte-for-byte identical frame counts against the operator-reviewed prototype's own already-generated gallery files in the scratchpad.
- **Box width: 54 display columns** (`┌` + 52 `─` + `┐`), set by measuring the actual widest rendered content row on this host (`display` module, 49 SGR-stripped columns) plus a 5-column margin — not the retired config.jsonc's hardcoded 38, which was already 9 columns too narrow for that same row.
- **`fish -ic exit`: 39.3–47.0ms across two separate 5-run measurements** (both taken inside a real kitty window), against the 31.1–32.2ms bare-fastfetch baseline — the themed pipeline (rendered-JSON read + logo-color substitution) plus the `box-close.awk` hop adds roughly 8–15ms.
- **Single-sprite forced regen: 242ms** (measured, not the plan's ~207ms estimate — same order of magnitude, recorded as measured). All-six: 772ms. Same-palette re-run (hash-sidecar hit): ~100ms.
- **`fastfetch-logo` state and all sprite GIFs survive a real theme switch** — verified live: `theme-apply gruvbox` after setting the state to `pulse` left `fastfetch-logo` and all 6 `.gif` files untouched (rsync `--delete` automatically excludes every `engine_owned_files` entry, confirmed by reading `commit.sh`'s exclude-flag construction directly, not assumed).

## Gates

All run live, current state (materialyou, `fastfetch-logo=arch`):

| Gate | Result |
|---|---|
| `theme-doctor` | 581/582 (only failure: pre-commit dirty tree, expected) |
| `theme-parity` | 1721/1721 — `fastfetch.jsonc` free of `{{` leftovers and well-formed across all 22 static presets + materialyou/-light |
| `stow-link-check` | 48 symlinks, none dangling (was 47 before `fastfetch-logo.fish`) |
| `keybind-doctor` | 14/14 — new `SUPER+SHIFT+T` bind confirmed live in `hyprctl binds` |
| `hypr-equivalence-check` | 3/3 (was 1 FAIL until the `ACCEPTED_ADDITIONS` entry — see Deviation 4) |
| `colour-lint` | 144/144 — confirmed QML-only scope (M-12), untouched by this task, still passes |

## Self-Check: PASSED

All 8 created files confirmed present on disk; `config.jsonc` confirmed deleted; all 3 commit hashes (`5eb6f7c`, `e2e7cc1`, `3dc577b`) confirmed present in `git log`.

## Known Stubs

None.

## Threat Flags

None — the threat model's five entries (T-srl-01 through T-srl-05) were all mitigated exactly as specified: state-value validation before path interpolation (fish selector and `theme-apply`'s own pre-existing pattern), fzf-return re-validation before any state write (the picker), sprite regen bounded and best-effort (`lib/fastfetch.sh`), `python-pillow` confirmed official-repo via `pacman -Si` before adding to `install.sh`, and `box-close.awk`'s read-only scope accepted as-is (low severity, no mitigation needed).
