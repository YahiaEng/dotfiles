---
phase: 09-wlogout-to-wleave-migration
plan: 01
subsystem: theming
tags: [wleave, wlogout, matugen, gtk4, layer-shell, m3-color-roles, aur]

requires: []
provides:
  - "wleave 0.7.1-1 installed (AUR, human-approved at D-13's blocking gate)"
  - "Installed-artefact config schema facts for wleave 0.7.1 (filename, top-level keys, per-button keys, spacing key, second-text-slot finding)"
  - "Empirical proof that matugen's four new M3 container roles resolve in Material You mode but HARD-FAIL for every static preset (repo-wide, all 20 palette JSON files)"
affects: [09-02-atomic-cutover, 09-03-checkpoint-decision]

tech-stack:
  added: []
  patterns:
    - "AUR package-legitimacy gate discharged by human in their own terminal, orchestrator-verified read-only afterward (no re-attempt of the interactive install)"
    - "Matugen scratch dry-run: a throwaway config.toml with one [templates.*] block pointed at a scratch template/output path, run via `matugen json <palette> -c <scratch>.toml -p <scratch-dir>` / `matugen image <wallpaper> ... -c <scratch>.toml -p <scratch-dir>` — proves template resolution with zero repo file writes"

key-files:
  created: []
  modified: []

key-decisions:
  - "Task 1 (AUR install) discharged by human in their own terminal per the blocking-human gate; NOT re-attempted by this executor. Verified read-only afterward: pacman -Q wleave -> wleave 0.7.1-1, command -v wleave -> /usr/bin/wleave."
  - "wleave 0.7.1's man pages do NOT document the 'wrapped' top-level config keys (buttons-per-row, close-on-lost-focus, show-keybinds, margin, delay-command-ms, protocol) as JSON keys — only as CLI flags. 09-02 should pass these as CLI flags to the wleave invocation in wleave.sh, or empirically validate JSON-key acceptance at the D-14 render gate, rather than assuming RESEARCH Pattern 1's wrapped-JSON-options example works as documented."
  - "D-08 (hover-revealed action name) finding: NO free second text slot exists distinct from `text` in wleave 0.7.1. `label.keybind` is a separate widget but only shows the single keybind character (gated by --show-keybinds), not a free-form action name. This forces 09-03's checkpoint:decision toward CSS/JS-driven reveal (e.g. an always-rendered-but-visually-hidden label made visible on :hover/:focus via CSS opacity, using the existing action-name label itself) rather than a wleave-native second field."
  - "BLOCKING FINDING for 09-02: matugen HARD ERRORS (ResolveError, non-zero exit) on the new template referencing on_tertiary_container/error_container/on_error_container for EVERY static preset, because all 20 palette JSON files in theme-engine/.config/theme-engine/palettes/ contain tertiary_container but are uniformly missing on_tertiary_container, error_container, and on_error_container. The Material You (image) path resolves all four correctly in both dark and light mode. 09-02 cannot commit the 23-key wleave-colors.css template until this gap is closed (add the 3 missing keys to all 20 static palette JSON files, or 09-02 must plan for that data migration as part of its own scope) — do NOT invent literal fallback hex values (repo's zero-literal-hex convention)."

patterns-established:
  - "Scratch matugen dry-run technique for pre-flight template verification (no [config.wallpaper] section, throwaway config.toml, `-p` scratch prefix) — reusable for any future template addition that touches previously-unexercised color-role keys."

requirements-completed: []

coverage: []

duration: ~55min (this session; Task 1 discharged in a prior session)
completed: 2026-07-25
status: complete
---

# Phase 9 Plan 1: wleave Pre-flight Verification Summary

**wleave 0.7.1-1 installed and human-approved; installed-artefact config schema fully probed via man pages/--help/binary strings/shipped defaults; matugen dry-run proves Material You resolves all four new M3 container roles but every static preset (20/20) hard-fails on three of them — a blocking finding for 09-02.**

## Performance

- **Duration:** ~55 min (this continuation session; Task 1's human discharge happened in a prior session)
- **Completed:** 2026-07-25T15:36:27Z
- **Tasks:** 3/3 (Task 1 discharged by human + re-verified; Tasks 2-3 executed this session)
- **Files modified:** 0 (verification-only plan, as designed)

## Accomplishments

- Task 1 (AUR package-legitimacy gate) discharged: human reviewed the PKGBUILD and ran `paru -S wleave` in their own terminal; re-verified read-only by this executor.
- Task 2: probed the INSTALLED wleave 0.7.1 config surface (man pages, `--help`, shipped `/etc/wleave/{layout.json,style.css}` defaults, and `strings`-inspection of the installed binary for corroboration) and re-verified the six refreshed Nerd Font glyph codepoints against the installed FiraCode Nerd Font cmap.
- Task 3: proved (via a scratch matugen dry-run, zero repo file changes) that the four new M3 container roles resolve correctly under Material You (dark AND light) but hard-fail under every static preset — a load-bearing, plan-changing finding for 09-02.

## Task Commits

This plan is verification-only (D-11/success_criteria: "Zero repo files modified"). No task-level commits were made for Tasks 1-3; all findings are recorded here. The only commit from this plan is the final metadata commit (SUMMARY.md, STATE.md, ROADMAP.md).

1. **Task 1: AUR package-legitimacy gate + install wleave 0.7.1-1 (D-13)** — no commit (machine-state only; human ran `paru -S wleave` outside this session). Discharged and re-verified.
2. **Task 2: Probe the INSTALLED wleave 0.7.1 config surface and re-verify the six glyph codepoints** — no commit (read-only probe; findings recorded below).
3. **Task 3: Dry-run the four never-before-rendered M3 container roles (Assumption A1)** — no commit (scratch-only; `git diff --exit-code matugen/` confirmed clean).

**Plan metadata:** committed separately (see `<final_commit>`).

## Files Created/Modified

None — this plan makes zero repo file changes, exactly as designed (`files_modified: []` in frontmatter, and Task 3's `git diff --exit-code matugen/` verification confirms it).

## Task 1: AUR Gate — Discharged by Human

**Status: DISCHARGED. NOT re-attempted by this executor** (per continuation instructions and the package-install exclusion in the deviation rules).

Re-verified read-only this session:
- `pacman -Q wleave` -> `wleave 0.7.1-1`
- `command -v wleave` -> `/usr/bin/wleave`
- `pacman -Q wlogout` -> `wlogout 1.2.2-0` (intentionally still installed; retiring it is a 09-02 repo/config change per D-11, not a machine uninstall — confirmed untouched)

Evidence from the human's own PKGBUILD audit (via `paru -Gp wleave`, recorded in the continuation state): source pinned to `git+https://github.com/AMNatty/wleave#tag=0.7.1`, pkgrel=1; `conflicts=("wleave-git")`; zero `pre_install`/`post_install`/`pre_upgrade`/`.install` hooks; `package()` is `install -Dm` calls only. Deps: librsvg, libadwaita, gtk4-layer-shell — matches `09-RESEARCH.md`'s Package Legitimacy Audit exactly.

## Task 2: Installed Config Surface Probe

**Man-page availability note:** the installed package ships `man1/wleave.1.gz` (CLI options) and `man5/wleave.5.gz` (layout file: per-button properties only — titled "layout file and options" but its `SH LAYOUT`/`SH FILE` sections document ONLY the per-button property list and a legacy bare-object example). **No `wleave.json.5` man page is installed** — the SEE ALSO line in `wleave.5` references `wleave.json(5)` but that page does not exist on this system (`pacman -Ql wleave` lists exactly two man pages). `man-db` is not installed on this machine (`command -v man` fails), so the gzipped roff sources were read directly via `zcat` — semantically identical to what `man` would render, since these are the same files `man` would format. This is recorded as a deviation below (Task 2's second automated `<verify>` line invokes `man`, which doesn't exist here).

### (a) Config filename and search path

- **Config filename:** `layout.json` — confirmed both by the shipped default at `/etc/wleave/layout.json` and by `strings`-inspecting `/usr/bin/wleave`, which contains the literal path-building fragments `~/.config/`, `/etc/wleave/`, `/etc/wlogout/`, `/usr/local/etc/wleave/`, `/usr/local/etc/wlogout/`, `wleave`, `wlogout`, `layout.json`, `style.css` — i.e. the binary's built-in search order tries `~/.config/wleave/layout.json` first, then falls back through `/etc/wleave/`, `/etc/wlogout/`, `/usr/local/etc/wleave/`, `/usr/local/etc/wlogout/`. **09-02's target `~/.config/wleave/layout.json` matches the primary search path exactly.**
- **Stylesheet filename:** `style.css` — confirmed the same way (`/etc/wleave/style.css` shipped default; same search-path fragments apply).
- **Notable side-finding:** the binary's search path ALSO includes `wlogout`-named fallback directories (`/etc/wlogout/`, `/usr/local/etc/wlogout/`) as a backwards-compat convenience. This does not block D-11's retirement (09-02 deletes the `wlogout/` stow package entirely, so no stale wlogout config will exist on this machine to be picked up), but is worth knowing: wleave itself has _some_ wlogout-path awareness baked in independent of this repo's config.

### (b) Top-level config keys and spacing key

**Confirmed as CLI flags (`wleave --help`, man1):**
| Flag | Long form | Accepted value |
|------|-----------|-----------------|
| `-b` | `--buttons-per-row <N>` | integer count, or a fraction like `"1/5"` to spread buttons over 5 rows |
| `-c` | `--column-spacing <N>` | space between button columns |
| `-r` | `--row-spacing <N>` | space between button rows |
| `-m` | `--margin <N>` | overall margin around buttons (plus `-L/-R/-T/-B` per-side overrides) |
| `-A` | `--button-aspect-ratio <N>` | button aspect ratio |
| `-d` | `--delay-command-ms <N>` | integer ms delay between window-hide and command execution (default 100ms per RESEARCH; not independently re-confirmed here since no dedicated default line is printed by `--help`) |
| `-f` | `--close-on-lost-focus[=BOOL]` | optional boolean |
| `-k` | `--show-keybinds[=BOOL]` | optional boolean |
| `-p` | `--protocol <PROTOCOL>` | enum: `layer-shell \| none \| xdg` |

**Inter-button spacing key: YES** — `column-spacing`/`row-spacing` exist natively (confirmed twice: as CLI flags in `--help`, and as GObject widget properties via `strings /usr/bin/wleave | grep "setter for property"` → `column-spacing`, `row-spacing`, `buttons-per-row`, `aspect-ratio` all present as internal layout-manager properties). 09-02 should use this native mechanism for D-02's 24px gap rather than CSS `button { margin: ... }`, to avoid the Phase 6 double-gap bug class.

**IMPORTANT GAP — top-level JSON key acceptance is UNCONFIRMED by installed docs:** `man5/wleave.5.gz`'s `SH LAYOUT`/`SH FILE` sections document ONLY the per-button property list (see (c) below) and show a **bare-object legacy example**, not a wrapped `{"buttons": [...], "buttons-per-row": ...}` object with additional top-level keys. `09-RESEARCH.md`'s Pattern 1 (wrapped-format keys settable in the JSON file) was sourced from reading `src/config.rs` at the pinned tag, not from the installed man pages — and the installed man pages do not corroborate a top-level options schema at all. Corroborating evidence found via `strings` on the binary: the internal Rust config struct's field names (`button_layout`, `margin_top`, `margin_bottom`, `margin_left`, `margin_right`, `column_spacing`, `row_spacing`, `button_aspect_ratio`, `show_keybinds`, `close_on_lost_focus`, `buttons_per_row`, `no_version_info`) do appear as literal strings near JSON-parsing code paths (`config.rs` line markers, "Using the JSON layout format." / "Using the backwards-compatible layout format." messages) — suggestive that they ARE deserializable as JSON keys, but this is inference from binary strings, not a documented/man-page-confirmed fact, and the shipped default `/etc/wleave/layout.json` does not exercise any of them (it only uses the `"buttons"` key).
**Recommendation for 09-02:** pass `buttons-per-row`/`column-spacing`/`row-spacing`/`margin`/`close-on-lost-focus`/`show-keybinds`/`delay-command-ms`/`protocol` as **CLI flags** on the `wleave` invocation in `wleave.sh` (the installed-doc-confirmed mechanism), OR empirically validate the JSON-key form live at the D-14 render gate before relying on it.

### (c) Per-button keys

Confirmed verbatim from the installed `man5/wleave.5.gz` `SH LAYOUT` section — the complete, exhaustive list of accepted per-button properties at 0.7.1 is:
```
label, action, text, keybind, icon, height*, width*, circular*
(* = optional)
```
- `height`/`width`: confirmed "values between 0.0 and 1.0 that control the location of where `text` is displayed the default width 0.5, height 0.9" (verbatim from the man page) — matches RESEARCH Pitfall 1 exactly: **default `height` is 0.9 (near-bottom), not centered.** 09-02 must set `"height": 0.5` explicitly on every button.
- `circular`: a boolean making the button round — not required by this phase's design (rounded-square capsules, not circles) but confirmed available if needed.
- `action` can also be a JSON array of conditional objects keyed by `$DESKTOP_SESSION` with `shell`/`executable` alternatives (seen in the shipped default `/etc/wleave/layout.json`, e.g. the `lock` button tries `loginctl lock-session` under gnome, falling back to `gtklock`/`swaylock`) — not needed for this repo's single fixed-action-per-button design (D-17's byte-identical action strings), but confirmed as an available (unused) feature.
- **`button-defaults` block: CONFIRMED ABSENT.** `zcat /usr/share/man/man5/wleave.5.gz | grep -i button-defaults` returns nothing. This confirms the installed package is genuinely 0.7.1 (pre-`button-defaults`, pre-0.8.0), matching D-13's pin exactly — no halt condition triggered.

### (d) D-08 second-text-slot finding: **NO**

Explicit finding: **wleave 0.7.1 does NOT expose a separate name/description/tooltip field distinct from `text`.** Evidence:
- The man5 per-button property list (above) contains exactly one free-text field: `text`.
- The shipped default `/etc/wleave/style.css` reveals TWO CSS label classes exist on a button: `label.action-name` (renders the `text` field's content) and `label.keybind` (a *separate* widget, styled `font-family: monospace`, `opacity` raised to 1 only on `:hover`/`:focus` via `button:hover label.keybind, button:focus label.keybind { opacity: 1; }`). However, `label.keybind` is populated with the single keybind **character** (e.g. `l`, `s`), gated by the `--show-keybinds` CLI flag — it is not a free-form action-name field, and is not usable as-is to show a full word like "Lock" or "Shutdown".
- An `icon` + `text` split DOES exist and is exercised by the shipped defaults (icon = an SVG file path rendered as a picture; text = a label positioned below/near it) — but this doesn't help this repo's glyph-as-text design, where the Nerd Font glyph itself occupies the `text` slot (no `icon` field used), leaving no second slot free for a hover-revealed action name.
- **Pango markup support in `text`:** not confirmed by any installed documentation source (man pages, `--help`) — no evidence found either way; recorded as undetermined, not assumed.

**Conclusion for 09-03's checkpoint:decision:** the hover-revealed action name (D-08) cannot use a wleave-native second text field. The closest achievable mechanism is CSS-driven: keep the glyph as the always-visible `text`, and either (a) repurpose `label.keybind` (setting each button's `keybind` to something CSS-addressable, accepting the UX/security caveat that this field is also a real functional keybind) — not recommended since D-19 already assigns real single-letter keybinds to each button — or (b) a compositor/JS-side approach is not available (wleave has no scripting hook), so realistically **09-03 should plan a CSS-only affordance using the existing `label.action-name`/button `:hover`/`:focus` pseudo-classes** (e.g., text-shadow/underline/border emphasis on the existing glyph label) rather than a genuine second name string — OR accept that D-08's "action name fades in below the capsule" literally cannot be implemented with a second string and must degrade to a different hover affordance (tint/border/scale changes, all of which ARE natively supported via CSS `:hover`/`:focus` on `button`). This is the single most consequential finding for 09-03 to resolve explicitly.

### Six glyph codepoints — re-verified against installed font

Font resolved via `fc-match -f '%{file}' "FiraCode Nerd Font"` -> `/usr/share/fonts/TTF/FiraCodeNerdFont-Regular.ttf`. Loaded via fontTools `getBestCmap()`:

| Action | Codepoint | Present in cmap | Distinct from Phase 6 set |
|--------|-----------|------------------|---------------------------|
| lock | `U+F023` | yes | yes |
| logout | `U+F08B` | yes | yes |
| suspend | `U+F186` | yes | yes |
| hibernate | `U+F2DC` | yes | yes |
| reboot | `U+F021` | yes | yes |
| shutdown | `U+F011` | yes | yes |

Verified via:
```
python3 -c "import subprocess;from fontTools.ttLib import TTFont;p=subprocess.run(['fc-match','-f','%{file}','FiraCode Nerd Font'],capture_output=True,text=True).stdout.strip();cm=TTFont(p).getBestCmap();new=[0xF023,0xF08B,0xF186,0xF2DC,0xF021,0xF011];old={0xF033E,0xF0343,0xF04B2,0xF02CA,0xF0425,0xF0709};assert len(set(new))==6;assert all(c in cm for c in new),[hex(c) for c in new if c not in cm];assert not (set(new)&old);print('cmap OK',[hex(c) for c in new])"
```
Output: `cmap OK ['0xf023', '0xf08b', '0xf186', '0xf2dc', '0xf021', '0xf011']` — all six present, pairwise distinct, and none overlaps the Phase 6 set (`U+F033E, U+F0343, U+F04B2, U+F02CA, U+F0425, U+F0709`). No substitution needed.

### Version-string side-finding (minor, non-blocking)

`wleave --version` prints **`wleave 0.7.0`** (not `0.7.1`), and a binary-embedded about-dialog string reads `"Wleave 0.7.0. <a href="...releases/tag/0.6.0">Missing or broken icons?</a>"`. This does **not** indicate the wrong package is installed — `pacman -Q wleave` independently confirms `0.7.1-1`, and the PKGBUILD builds from the pinned `#tag=0.7.1` git tag (per Task 1's human audit). This is upstream's own internal version-string/about-dialog metadata lagging its release-tag bump — a cosmetic upstream inconsistency, not a build/install defect. Recorded so a future debugging session isn't confused by `--version` disagreeing with `pacman -Q`.

## Task 3: M3 Container-Role Dry-Run (Assumption A1)

**Method:** Copied `matugen/.config/matugen/templates/wlogout-colors.css` to a scratch path, appended the four new `@define-color` lines (`tertiary_container`, `on_tertiary_container`, `error_container`, `on_error_container`) using the exact existing idiom, then rendered it through a throwaway scratch `config.toml` (single `[templates.wleave-test]` block, `-c`/`-p` flags) — zero writes to the real `matugen/.config/matugen/config.toml` or `templates/` directory. Confirmed after the fact: `git diff --exit-code matugen/` -> exit 0 (clean).

### Result 1: Static preset mode — **FAILS (blocking)**

Rendered against `theme-engine/.config/theme-engine/palettes/tokyonight.json` via `matugen json ... `:
```
Error: ResolveError — on_tertiary_container: Value does not exist in the context
Error: ResolveError — error_container: Value does not exist in the context
Error: ResolveError — on_error_container: Value does not exist in the context
```
matugen hard-fails (non-zero exit, no output file produced) — exactly the failure mode Pitfall 5 warned might occur ("matugen typically fails hard on unknown keys"). `tertiary_container` itself resolved fine (it already exists in the static JSON).

**Root cause confirmed repo-wide, not tokyonight-specific:** grepped all 20 files in `theme-engine/.config/theme-engine/palettes/*.json` for the four key names. **Every single one** (`catppuccin`, `catppuccin-latte`, `dracula`, `ethereal`, `everfrost`, `gruvbox`, `gruvbox-light`, `hackerman`, `kanagawa`, `kanagawa-lotus`, `matte-black`, `miasma`, `nord`, `osaka-jade`, `ristretto`, `rosepine-dawn`, `rosepine`, `tokyonight-day`, `tokyonight`, `vantablack`) has `tertiary_container` but **zero** have `on_tertiary_container`, `error_container`, or `on_error_container`. This is a uniform, 20/20 gap — not an isolated preset bug.

**BLOCKING FINDING for 09-02:** the new `wleave-colors.css` template (23 keys) **cannot render for any static preset** until these 3 missing keys are added to all 20 palette JSON files with real, non-literal-fallback hex values (per the repo's zero-literal-hex convention, these must be genuine M3-derived values, not invented placeholders). Per this task's own instruction ("do NOT improvise a literal fallback hex... record it as a blocking finding and stop"), **no repo file was touched to work around this** — it is recorded here as fact for 09-02 to plan around.

### Result 2: Material You dynamic mode — **PASSES (both dark and light)**

Rendered against the live wallpaper (`~/Pictures/Wallpapers/current.jpg`, resolves to `wallpapers/Pictures/Wallpapers/dracula/Kraken.png`) via `matugen image ... --source-color-index 0 -m dark` and `-m light`:

- **Dark:** 23/23 `@define-color` lines, 0 unresolved `{{` tokens, all 23 match `^@define-color [a-z_]+ #[0-9a-fA-F]{6};$`. Four new roles: `tertiary_container #603b4f`, `on_tertiary_container #ffd8e9`, `error_container #93000a`, `on_error_container #ffdad6`.
- **Light:** 23/23 lines, 0 unresolved tokens, all well-formed. Four new roles: `tertiary_container #ffd8e9`, `on_tertiary_container #2f1123`, `error_container #ffdad6`, `on_error_container #410002`.

(Minor side-note: matugen printed `Format error decoding Jpeg: Error parsing image. Illegal start bytes:8950` for the light-mode run — `current.jpg` is actually a PNG under a `.jpg` name (`8950` = the PNG magic-number bytes `\x89P`); matugen recovered and rendered correctly regardless via its own format auto-detection. Pre-existing repo state, unrelated to this task, not a blocker.)

### Conclusion

Assumption A1 is **half-discharged**: proven TRUE for Material You (both modes) and proven FALSE for every static preset, for a well-understood, fully-diagnosed reason (upstream palette JSON files are simply missing 3 of the 4 keys). This is a necessary and valuable pre-flight catch — exactly what this dry-run task existed to find — and changes 09-02's scope: it must either extend all 20 static palette JSON files with the 3 missing container-role keys before committing the new template, or explicitly descope static-preset support for the four new roles (not recommended, breaks D-03/D-04's per-capsule color pairing on 20/22 themes).

## Decisions Made

See `key-decisions` in frontmatter above (four decisions: Task 1 discharge method, top-level JSON key ambiguity + CLI-flag recommendation, D-08 second-text-slot finding, and the static-preset blocking finding).

## Deviations from Plan

### Auto-fixed / Adapted Issues

**1. [Rule 3 - Blocking, worked around without a package install] `man` command unavailable**
- **Found during:** Task 2
- **Issue:** `man-db` is not installed on this machine; `man 5 wleave.json`/`man 1 wleave` (as used in Task 2's second automated `<verify>` line) both fail with "command not found" (exit 127), which is excluded from Rule 3 auto-fix (package installs require a legitimacy gate, not warranted for a documentation-formatting convenience tool).
- **Fix:** Read the identical gzip'd roff source files directly via `zcat /usr/share/man/man{1,5}/wleave.{1,5}.gz` — semantically equivalent evidence to what `man` would render (same files), with zero new packages installed.
- **Files modified:** none.
- **Verification:** All facts required by Task 2's acceptance criteria were sourced and cross-checked against the actual installed man page content (quoted verbatim above), plus corroborating evidence from `--help`, the shipped `/etc/wleave/{layout.json,style.css}` defaults, and `strings` on the installed binary.
- **Committed in:** n/a (no repo file changed).

**2. [Rule 1-adjacent — honest negative result, not a fix] Static-preset M3 container-role resolution failure**
- **Found during:** Task 3
- **Issue:** Task 3's acceptance criteria assumed all four new M3 container roles would resolve in both modes; they do NOT resolve for any static preset (20/20 fail identically).
- **Fix:** None applied — per the task's own explicit instruction, this is recorded as a blocking finding for 09-02 rather than worked around with an invented literal-hex fallback (which would violate the repo's zero-literal-hex convention).
- **Files modified:** none.
- **Verification:** Reproduced against `tokyonight.json` specifically, then confirmed via full grep across all 20 palette JSON files that the gap is uniform (not preset-specific).
- **Committed in:** n/a (no repo file changed; documented here for 09-02 to consume).

---

**Total deviations:** 2 (1 tooling substitution, 1 honest negative finding — no invented workarounds, no repo files touched). No scope creep; both preserve the plan's "zero repo file changes" constraint.

## Issues Encountered

None beyond the two deviations above (both were anticipated categories of finding this pre-flight plan exists to surface, not unplanned problems).

## User Setup Required

None — Task 1's `user_setup` block was already discharged by the human before this continuation session began (see Task 1 section above). No further external service configuration required for this plan.

## Next Phase Readiness

**Ready for 09-02, with two must-address items:**
1. **Blocking:** 09-02 must add `on_tertiary_container`, `error_container`, `on_error_container` (real M3-derived hex, not literal fallbacks) to all 20 static palette JSON files in `theme-engine/.config/theme-engine/palettes/` before the new `wleave-colors.css` template can render for any static preset. Material You (dark+light) already works with zero changes.
2. **Needs an explicit call at plan time:** the top-level wrapped-JSON config keys (`buttons-per-row`, `margin`, `close-on-lost-focus`, `show-keybinds`, `delay-command-ms`, `protocol`) are confirmed only as CLI flags by the installed docs — 09-02 should invoke `wleave` with these as CLI flags in `wleave.sh` (safe, doc-confirmed path) rather than assuming they also work as JSON keys inside `layout.json`.
3. **D-08 (hover-revealed action name) is NOT achievable via a wleave-native second text field** — 09-03's checkpoint:decision must choose a CSS-only hover affordance (tint/border/scale on the existing single label) instead.
4. wleave 0.7.1-1 is installed and verified; the six refreshed glyph codepoints are cmap-proven; `height: 0.5` must be set on every button (default is 0.9, near-bottom); no `button-defaults` block exists (confirmed 0.7.1, not 0.8.0-dev).

---
*Phase: 09-wlogout-to-wleave-migration*
*Completed: 2026-07-25*
