---
phase: 08-waybar-evolution
plan: 05
subsystem: infra
tags: [waybar, jsonc, gtk3-css, nerd-font, bash, python3, shellcheck, hyprland]

# Dependency graph
requires:
  - phase: 08-waybar-evolution
    provides: "08-01's shared-include composition (modules.jsonc, waybar-modules.css, include/@import mechanism), 08-02's disk-glob layout enumeration (waybar-switch.sh/waybar-launch.sh), 08-03's bar-common.jsonc signal contract + visibility owner"
provides:
  - "waybar/.config/waybar/config-vertical.jsonc + style-vertical.css — the 4th (left column) waybar layout, D-11..D-16"
  - "custom/gaming-mode module (modules.jsonc + waybar-modules.css) — D-35, reaching all four layouts from one definition"
  - "custom/notification finally present in config-floating.jsonc by reference — D-26 parity fix"
  - "theme-doctor's D-17 per-module CSS-reachability + colour-resolution gate, waybar sheets discovered by glob (4th hardcoded list killed)"
affects: [08-08, 08-09, 08-10]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Programmatic glyph-exact file authoring: build JSONC content as a Python template with unique §TOKEN§ placeholders, replace with chr(codepoint) at the end, write via file I/O — avoids the 08-01-class transcription-error risk entirely for any file carrying >1 supplementary-plane glyph"
    - "GTK3 CssProvider.to_string() as a full @import-chain flattening primitive, reused by both the CSS-parse guard and the new colour-resolution gate — one live-verified mechanism, not two"

key-files:
  created:
    - waybar/.config/waybar/config-vertical.jsonc
    - waybar/.config/waybar/style-vertical.css
  modified:
    - waybar/.config/waybar/modules.jsonc
    - waybar/.config/waybar/waybar-modules.css
    - waybar/.config/waybar/config-full.jsonc
    - waybar/.config/waybar/config-minimal.jsonc
    - waybar/.config/waybar/config-floating.jsonc
    - theme-engine/.config/theme-engine/theme-doctor
    - .planning/phases/08-waybar-evolution/.waybar-config-baseline/full.json
    - .planning/phases/08-waybar-evolution/.waybar-config-baseline/minimal.json
    - .planning/phases/08-waybar-evolution/.waybar-config-baseline/floating.json

key-decisions:
  - "UI-SPEC's gaming-mode glyph candidates (U+F04FE/U+F04FF) are PRESENT in the installed FiraCodeNerdFont-Regular.ttf at 1.00-cell width but resolve to md-target/md-taxi, not a controller icon at all — substituted the pre-checked same-family fallback pair U+F02B4/U+F02B5 (nf-md-google_controller / _off), both cmap+advance-verified"
  - "Discovered (not introduced by this plan) that modules.jsonc's mpris player-icons/status-icons, pulseaudio format-icons/format-muted, and cpu/memory/temperature format-icons are empty/broken placeholders repo-wide, predating this phase (present in the very first commit). Left the shared canonical definitions untouched (out of scope, affects only full/minimal which already degrade to visible text) but supplied real cmap-verified glyphs in config-vertical.jsonc's own redefinitions, since a glyph-only column format would otherwise render those widgets completely invisible"
  - "custom/notification's 'tooltip' flipped false->true in the vertical redefinition: it is a return-type:json custom module and swaync-client -swb already emits a real 'tooltip' field (live-verified: {\"tooltip\":\"16 Notifications\",...}) — that is D-13's dropped-detail channel here, not a static tooltip-format, which return-type:json custom modules don't consume for this purpose"
  - "custom/gaming-mode's exec is a two-branch literal compare-and-map (never echoes the state file's bytes into the JSON payload) — closes T-08-20/T-08-21 and fails safe to OFF on any unexpected state-file content, matching gaming-mode-toggle.sh's own _read_state default"
  - "style-vertical.css's glyph-box/module-gap grouped selector deliberately excludes #custom-gaming-mode — it inherits its already-compact shared pill from waybar-modules.css untouched, per the plan's own explicit 'zero occurrences of custom-gaming-mode in this file' acceptance criterion"

patterns-established:
  - "theme-doctor's D-17 gate: resolve a layout's real module list via waybar-equivalence-check --resolve, flatten its stylesheet via Gtk.CssProvider.to_string(), assert every module has a reachable CSS rule AND every @token referenced is @define-color'd in that same flattened output — reusable verbatim for any future layout or any future themed-CSS surface"

requirements-completed: [BAR-03, BAR-05]

coverage:
  - id: D1
    description: "custom/gaming-mode defined once in modules.jsonc (D-35, D-31), reaches full/minimal/floating/vertical from one place, is a read-only compare-and-map consumer of ~/.cache/gaming-mode with zero echo of untrusted bytes"
    verification:
      - kind: manual_procedural
        ref: "grep -c 'custom/gaming-mode' modules.jsonc == 1; exec string inspected for literal 'Gaming Mode: ON'/'Gaming Mode: OFF' tokens with the state-file read appearing only on the comparison's left-hand side; python json.loads round-trip confirms the exact codepoints U+F02B4/U+F02B5"
        status: pass
    human_judgment: false
  - id: D2
    description: "custom/notification finally present in config-floating.jsonc's modules-right, by reference not by copy (D-26 parity fix)"
    verification:
      - kind: manual_procedural
        ref: "jq -e '.[\"modules-right\"] | index(\"custom/notification\") != null' on the re-snapshotted floating.json exits 0; grep -c '\"custom/notification\"[[:space:]]*:' config-floating.jsonc == 0 (not redefined)"
        status: pass
    human_judgment: false
  - id: D3
    description: "waybar-equivalence-check re-baselined only after the printed diff was read and confirmed to contain exactly the gaming-mode key + 3 array insertions + floating's bell, nothing else"
    verification:
      - kind: manual_procedural
        ref: "diff captured verbatim before re-snapshot (see Reviewed Equivalence Diff below); gate green 3/3 after re-snapshot"
        status: pass
    human_judgment: false
  - id: D4
    description: "config-vertical.jsonc composes purely through 08-01/08-03's include mechanism: position=left, width=48, no output key, margins 8/8/8, signal contract inherited not redeclared, module set exactly D-12+D-35, zero script edits to waybar-switch.sh/waybar-launch.sh"
    verification:
      - kind: manual_procedural
        ref: "waybar-equivalence-check --resolve + jq assertions on position/width/height/output/margins/on-sigusr1/on-sigusr2/module-set; grep -c 'vertical' across both switcher scripts == 0"
        status: pass
    human_judgment: false
  - id: D5
    description: "style-vertical.css is a thin per-layout sheet: correct @import order (theme -> font -> waybar-modules.css -> waybar-visibility.css LAST), OLED trim with accent edge rotated border-bottom->border-right, zero hex/black/new-colour, no font-family, confirmed parsing via a live GTK3 CssProvider"
    verification:
      - kind: manual_procedural
        ref: "python @import-order assertion script; grep sweeps for font-family/hex-literal/custom-gaming-mode all return 0; standalone GTK3 CssProvider parse of the deployed sheet: 20940 bytes, non-empty, @define-color present, shared-module selector present"
        status: pass
    human_judgment: false
  - id: D6
    description: "theme-doctor's D-17 gate discovers waybar sheets by glob (4th hardcoded list killed), reuses waybar-equivalence-check --resolve (no second JSONC parser), and hard-fails on an unresolved colour token — proven capable of failing via a self-test, then proven to return to green"
    verification:
      - kind: manual_procedural
        ref: "bash -n + shellcheck -S error clean; self-test with config-zzztest.jsonc/style-zzztest.css referencing @not_a_real_palette_token: theme-doctor exited nonzero naming 'zzztest' and the token, while the pre-existing CSS-parse guard still PASSed on the same file (proving the gap it closes); throwaway files removed, re-verified green (95 passed / 2 pre-existing unrelated failures)"
        status: pass
    human_judgment: false
  - id: D7
    description: "Vertical layout launches cleanly on the real, live waybar process via the exact disk-truth launcher (waybar-launch.sh), not a synthetic test — config/style resolve with zero parse errors, includes load correctly"
    verification:
      - kind: manual_procedural
        ref: "Killed the running floating bar, wrote 'vertical' to ~/.cache/current-waybar-layout, relaunched via uwsm app -- waybar-launch.sh (the exact autostart.conf invocation): log shows clean include of modules.jsonc + bar-common.jsonc, 'dark' appearance discovered, zero parse errors, process stayed alive; user's original 'floating' layout restored afterward via the same mechanism"
        status: true
      - kind: human_visual
        ref: "grim/hyprctl monitors were unavailable from this tool's exec context (hyprctl clients showed real live windows, proving genuine compositor connection, but hyprctl monitors/layers/grim screencopy queries returned empty/failed) — full pixel-level visual confirmation (glyph rendering, spacing, no tofu boxes, hover tooltips, gaming-mode toggle live, light/dark re-theme) is OUTSTANDING and must be done by the user via Super+B per the plan's own human-check block"
        status: pending
    human_judgment: true
    rationale: "This plan's own <verify><human-check> block explicitly frames the visual pass (colour correctness, glyph rendering, hover tooltips, gaming-mode toggle) as human judgment, not something the autonomous executor completes unassisted — consistent with 08-01/08-03's precedent of leaving the Super+B visual pass as an outstanding phase-level checkpoint."

# Metrics
duration: ~30min
completed: 2026-07-14
status: complete
---

# Phase 8 Plan 5: Vertical Waybar Layout + Gaming-Mode Indicator + D-17 Colour-Resolution Gate Summary

**Authored the 4th (left-column) waybar layout entirely through 08-01/08-03's shared-include mechanism, added a `custom/gaming-mode` indicator (D-35) that reads Phase 7's state file read-only, closed the live `custom/notification`-missing-from-floating parity bug (D-26), and folded a rerunnable per-module colour-resolution gate into `theme-doctor` that hard-fails on an unresolved `@token` — proven capable of failing via a self-test before being trusted.**

## Performance

- **Duration:** ~30 min
- **Started:** 2026-07-14T15:52:00+03:00 (approx, first file reads)
- **Completed:** 2026-07-14T16:20:50+03:00 (last verification, layout restored)
- **Tasks:** 4 completed
- **Files modified:** 9 (2 created, 7 modified) + 3 re-snapshotted baseline JSONs

## Accomplishments

- **Gaming-mode indicator (D-35).** Defined `custom/gaming-mode` exactly once in `modules.jsonc`: `return-type: json`, `interval: 2`, a two-branch literal compare-and-map `exec` that reads `~/.cache/gaming-mode`, compares it against the literal `on`, and emits one of exactly two hardcoded JSON payloads — the state file's bytes never appear inside an emitted string, closing T-08-20/T-08-21's Pango-markup-injection surface. Fails safe to OFF on any unexpected value, matching `gaming-mode-toggle.sh`'s own `_read_state` default. Added the `#custom-gaming-mode`/`.on` CSS rules to `waybar-modules.css` (`@outline` base, `@primary` when ON, no filled background — D-06 stays intact). Composed into `modules-right` in full/minimal/floating, always immediately before `custom/notification`.
- **Glyph verification, and a real substitution.** The fontTools cmap+advance check for the UI-SPEC's candidate codepoints (`U+F04FE`/`U+F04FF`) technically passes (both present, both 1.00-cell) — but a deeper check revealed they resolve to `md-target`/`md-taxi` glyphs on the installed `FiraCodeNerdFont-Regular.ttf`, not a controller icon at all. Per the plan's own fallback instruction, substituted the pre-checked same-family replacement pair `U+F02B4`/`U+F02B5` (`nf-md-google_controller` / `_off`) — both cmap+advance-verified (1200 == `M`'s 1200, 1.00 cells). See Deviations for the full glyph audit trail, including several more substitutions discovered necessary while authoring the vertical layout.
- **D-26 parity fix, cashed as one line.** `custom/notification` added to `config-floating.jsonc`'s `modules-right` by reference (not redefined) — the bell has existed in `modules.jsonc` since 08-01 and was simply never copy-pasted into the fourth file. `jq -e '.["modules-right"] | index("custom/notification") != null'` on the re-snapshotted `floating.json` now exits 0, inverting the exact assertion 08-01 used to prove the bug existed.
- **Equivalence gate re-baselined deliberately.** Ran `waybar-equivalence-check`, read the printed diff (recorded verbatim below), confirmed it contained ONLY the new `custom/gaming-mode` key + 3 `modules-right` insertions + floating's bell, then re-snapshotted. Gate green 3/3 (vertical correctly reports SKIP — no baseline yet, by design).
- **`config-vertical.jsonc` authored purely through the include mechanism.** `position: left`, `width: 48`, no `output` key (D-15, draws on every monitor), `margin-{left,top,bottom}: 8` (D-14), zero redeclaration of the `on-sigusr1`/`on-sigusr2` signal contract (inherited from `bar-common.jsonc`). Module set exactly D-12 + D-35: `hyprland/workspaces` · stacked `clock`+`mpris` · `cpu`/`memory`/`temperature`/`pulseaudio`/`network`/`battery` · `custom/gaming-mode` · `custom/notification` · `tray` · `custom/power`. `hyprland/window` deliberately absent (no glanceable column form). Full redefinitions only where the column genuinely diverges (glyph-only formats + stacked readouts); `hyprland/workspaces`/`custom/gaming-mode`/`custom/power`/`tray` referenced by name, never redefined. Built the file programmatically (Python template + `chr(codepoint)` substitution, never hand-typed multi-byte glyphs) to eliminate the exact transcription-error class 08-01 hit.
- **Discovered and fixed a second, larger pre-existing glyph gap.** `modules.jsonc`'s `mpris` (`player-icons`/`status-icons`), `pulseaudio` (`format-icons`/`format-muted`), and `cpu`/`memory`/`temperature` (`format-icons`) are empty or textual placeholders — verified via direct byte inspection, present since the very first commit (`a1a0575`), unrelated to any Phase 8 plan. Copying them verbatim into a glyph-ONLY column format (as the plan's literal text instructed) would have rendered those widgets completely invisible for the majority of real-world use (e.g. every mpris player except mpv). Substituted real, cmap+advance-verified glyphs — reusing already-live codepoints where they exist in the repo (custom/media's music/spotify icons, config-floating.jsonc's cpu/memory/network/pulseaudio icons, this same phase's `eww.yuck` pause icon) and newly cmap-verifying the rest (firefox, chromium, a 5-level thermometer family) against the installed font with the identical discipline Task 1 established. Left the shared canonical `modules.jsonc` definitions untouched (out of scope — full/minimal already degrade gracefully to visible text, unlike the glyph-only column).
- **`style-vertical.css` authored as a thin per-layout sheet.** Correct `@import` order (theme → font → `waybar-modules.css` → `waybar-visibility.css` last, verified by a python order-assertion script). 20px base `font-size` (the column's glyph-emphasis size vs. the horizontal bars' 13px). OLED trim (D-06) carried over with the accent edge rotated: `border-right` replaces `border-bottom` for the left-anchored column's outward-facing edge, same `@primary` token, same 1px/0.4 alpha weight. Workspaces-active and cpu/memory/temperature accent indicators rotated the same way (border-bottom → border-left), no filled pill reintroduced. 24px glyph box + 12px padding + 8px inter-module gap applied as one grouped selector — deliberately excluding `#custom-gaming-mode`, which inherits its already-compact shared pill untouched (D-31's CSS payoff). Zero hex/black literals, zero new named colours, no `font-family` declaration.
- **`theme-doctor`'s 4th hardcoded list killed.** `GTK3_CSS_SHEETS` used to name `style-{full,minimal,floating}.css` one by one — the same copy-paste-drift class D-32 already killed in the two switcher scripts, found hiding in a third place exactly as 08-RESEARCH predicted. Replaced with a `nullglob`-guarded `style-*.css` glob over the deployed waybar directory, appended to the explicit non-waybar sheets (which stay explicit — they have no enumeration to derive).
- **D-17's colour-resolution gate, folded in and self-tested.** For every deployed `config-*.jsonc`, resolves the real module list via `waybar-equivalence-check --resolve` (reusing 08-01's one JSONC/include parser — no second one written), flattens that layout's stylesheet through a live `Gtk.CssProvider`, and asserts (1) every module has a reachable CSS rule (word-boundary matched) and (2) every `@token` referenced is `@define-color`'d in the same flattened output. Assertion 2 is the load-bearing half: **proven live** that GTK 3.24.52 raises no `parsing-error` and yields a non-empty provider for an undefined named colour — the existing CSS-parse guard's two signals (fatal error, empty provider) are both blind to it. **Self-tested for real:** injected a throwaway `config-zzztest.jsonc` + `style-zzztest.css` referencing `@not_a_real_palette_token`; `theme-doctor` exited nonzero naming `zzztest` and the exact token, while the pre-existing CSS-parse guard reported PASS on the very same file — a direct, reproduced demonstration of the gap this gate closes. Removed the throwaway files and confirmed green again (95 passed / 2 pre-existing, unrelated failures — see Known Issues).
- **Live-verified on the real running bar.** Recorded the user's original layout (`floating`) before starting. Killed the running waybar, switched `~/.cache/current-waybar-layout` to `vertical`, relaunched via the exact `uwsm app -- waybar-launch.sh` invocation `autostart.conf` uses (not a synthetic test) — log confirmed clean `modules.jsonc`/`bar-common.jsonc` include resolution, `dark` appearance discovery, zero parse errors, and the process stayed alive. Restored `floating` via the identical mechanism afterward.

## Task Commits

1. **Task 1: Verify the glyph set, define custom/gaming-mode once, land the bell in floating, re-baseline the drift gate** - `ccb69af` (feat)
2. **Task 2: Author config-vertical.jsonc — the column composition** - `9502c85` (feat)
3. **Task 3: Author style-vertical.css — the column stylesheet** - `d551f93` (feat)
4. **Task 4: Fold D-17's "full module re-test" into theme-doctor as a rerunnable gate** - `38dbd4c` (feat)

## Files Created/Modified

- `waybar/.config/waybar/config-vertical.jsonc` - New. The 4th layout, include-composed, D-12+D-35 module set.
- `waybar/.config/waybar/style-vertical.css` - New. Thin per-layout sheet, OLED trim rotated, 20px base font-size.
- `waybar/.config/waybar/modules.jsonc` - Gains `custom/gaming-mode` (defined once).
- `waybar/.config/waybar/waybar-modules.css` - Gains `#custom-gaming-mode`/`.on` rules.
- `waybar/.config/waybar/config-{full,minimal,floating}.jsonc` - `custom/gaming-mode` composed into `modules-right`; floating also gains `custom/notification` (D-26).
- `theme-engine/.config/theme-engine/theme-doctor` - Waybar CSS sheets discovered by glob (4th hardcoded list killed); new D-17 module-colour-resolution gate.
- `.planning/phases/08-waybar-evolution/.waybar-config-baseline/{full,minimal,floating}.json` - Re-snapshotted after a reviewed, intentional diff.

## Glyph Verification (Task 1's required record)

fontTools cmap + `hmtx` advance check against `/usr/share/fonts/TTF/FiraCodeNerdFont-Regular.ttf`, `M`'s advance = 1200:

```
U+F04FE present adv=1200 (1.00x M)
U+F04FF present adv=1200 (1.00x M)
```

Both pass the plan's literal automated check (presence + advance-width equality). **However**, a deeper semantic check (resolving the cmap glyph name, not just presence) showed:

```
U+F04FE -> glyph name "md-target"  (NOT a controller icon)
U+F04FF -> glyph name "md-taxi"    (NOT a controller icon)
```

Per the plan's own fallback instruction ("pick a present 1.00-cell replacement from the same MDI controller/gamepad family"), substituted:

```
U+F02B4 md-google_controller      adv=1200 (1.00x M)  -- ON
U+F02B5 md-google_controller_off  adv=1200 (1.00x M)  -- OFF
```

These are what actually shipped in `modules.jsonc`'s `custom/gaming-mode.format-icons`.

## Reviewed Equivalence Diff (verbatim, before re-snapshot — T-08-24 audit trail)

Captured immediately after Task 1's config/CSS edits landed, before running `--snapshot`:

```
  [FAIL] floating: differs from baseline
+  "custom/gaming-mode": { ...new module, appended into modules-right... }
+  "custom/notification": { ...full definition, now reachable since floating references it... }
+  modules-right gains: "custom/gaming-mode", "custom/notification" (before "custom/power")

  [FAIL] full: differs from baseline
+  "custom/gaming-mode": { ...new module... }
+  modules-right gains: "custom/gaming-mode" (before "custom/notification")

  [FAIL] minimal: differs from baseline
+  "custom/gaming-mode": { ...new module... }
+  modules-right gains: "custom/gaming-mode" (before "custom/notification")

PASS: 0  FAIL: 3
```

Confirmed this contained ONLY the gaming-mode key (appearing in all three layouts' effective config since it's a shared `modules.jsonc` key), the three `modules-right` array insertions, and floating's `custom/notification` full definition becoming reachable (since floating now references it by name for the first time). Nothing else. Re-snapshotted; gate returned to `PASS: 3 FAIL: 0` (vertical correctly `SKIP`'d — no baseline yet).

## GTK3 `CssProvider.to_string()` Flattening (Task's required record)

Confirmed live, exactly as planning predicted: `to_string()` on the deployed `style-vertical.css` returns the fully flattened `@import` chain (theme colours + `waybar-modules.css` inlined) — no manual `@import`-walk fallback was needed. Standalone verification:

```
PASS: 20940 bytes, non-empty provider
has @define-color (theme import inlined): True
has shared-module selector inlined: True
```

## D-17 Gate Self-Test — Watched Failing On Purpose (Task 4's required record)

Injected a throwaway 5th layout under the deployed `~/.config/waybar/`:

- `config-zzztest.jsonc`: `include: ["modules.jsonc"]`, `modules-left: ["custom/power"]`
- `style-zzztest.css`: `@import` the theme sheet, then `#custom-power { color: @not_a_real_palette_token; }`

```
  [PASS] CSS-parse: waybar/style-zzztest.css (881 bytes)
  [PASS] D-17 module-gate: zzztest (reachable: custom/power -> #custom-power)
  [FAIL] D-17 module-gate: zzztest (unresolved colour token(s): not_a_real_palette_token)

Summary: 97 passed, 3 failed
```

Note the pre-existing CSS-parse guard **still reports PASS** on the exact same poisoned stylesheet — a direct, reproduced demonstration of the blind spot D-17's new assertion closes (GTK3 raises no `parsing-error` and yields a non-empty provider for an undefined colour). Removed both throwaway files and re-ran:

```
Summary: 95 passed, 2 failed   (same 2 pre-existing, unrelated failures as before self-test)
```

## Resolved Spec Conflicts (Task's required record)

1. **cpu/memory/temperature keep a stacked numeric value.** UI-SPEC's Typography section says every column module is "a bare Nerd Font glyph at 20px — no text label, ever." D-12 is a locked user decision naming cpu/memory/temperature explicitly as "stacked readouts." A readout with no value is not a readout — D-12 (locked) outranks the spec's blanket rule, and every *other* module in the column stays bare-glyph, honouring the spec everywhere it doesn't collide.
2. **`hyprland/window` is absent from the column.** Not in D-12's named module set, and the UI-SPEC's own 24×24 glyph-box list omits it. A window title has no glanceable column form and no natural glyph — a `hyprland/window` module here would be an invisible hover target, worse than nothing.

## Accent-Edge Rotation + Base Font-Size (Task's required record, for 08-08)

- The horizontal bars' `border-bottom: 1px solid alpha(@primary, 0.4)` (the edge facing the desktop) becomes `border-right: 1px solid alpha(@primary, 0.4)` for the left-anchored column — same token, same weight, same alpha, only the geometry rotates. `#workspaces button.active` and the cpu/memory/temperature accent indicators rotate the same way (border-bottom → border-left).
- Base `font-size` is **20px** in `style-vertical.css`'s `*` reset, vs. the horizontal bars' 13px — every module in this column is a glyph, so 20px IS the body size here. The `<small>`-wrapped stacked values in cpu/memory/temperature scale down automatically via Pango.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Gaming-mode glyph codepoints substituted after a deeper semantic check the plan's own literal automated check does not perform**
- **Found during:** Task 1, glyph verification
- **Issue:** UI-SPEC/plan candidates `U+F04FE`/`U+F04FF` pass the plan's literal `fontTools` check (present, 1.00-cell advance) but resolve to `md-target`/`md-taxi` glyph names — not a controller icon at all.
- **Fix:** Substituted the plan's own pre-checked fallback pair `U+F02B4`/`U+F02B5` (`nf-md-google_controller`/`_off`), cmap+advance-verified.
- **Files modified:** `waybar/.config/waybar/modules.jsonc`
- **Verification:** `python3 -c "from fontTools..."` codepoint+glyph-name check; JSON round-trip of the emitted `format-icons` confirms exact codepoints.
- **Committed in:** `ccb69af` (Task 1 commit)

**2. [Rule 1 - Bug] Substituted real glyphs for mpris/pulseaudio/cpu/memory/temperature in config-vertical.jsonc, discovered pre-existing broken glyph fields in the shared canonical definitions**
- **Found during:** Task 2, authoring the column's full redefinitions
- **Issue:** `modules.jsonc`'s `mpris.player-icons`/`status-icons` are empty for every entry but `mpv`; `pulseaudio.format-icons`/`format-muted` are empty/textual; `cpu`/`memory`/`temperature.format`/`format-icons` carry no icon at all. Verified via direct byte inspection (zero non-ASCII bytes in the relevant JSON string literals) and via `git show a1a0575:...` — present since the very first commit, unrelated to any Phase 8 plan. Copying these verbatim into a glyph-ONLY column format (as the plan's literal instruction said, assuming they were valid) would render those widgets completely invisible for the majority of real-world use.
- **Fix:** Substituted cmap+advance-verified glyphs in `config-vertical.jsonc`'s own full redefinitions only — reused already-live codepoints from `custom/media` (music/spotify), `config-floating.jsonc` (cpu/memory/network/pulseaudio), and this same phase's `eww.yuck` (pause), plus newly cmap-verified firefox/chromium/thermometer-family codepoints (same discipline as Task 1). Left the shared `modules.jsonc` canonical definitions untouched — out of scope (full/minimal already degrade to visible text, unlike the glyph-only column).
- **Files modified:** `waybar/.config/waybar/config-vertical.jsonc` only
- **Verification:** Full cmap+advance table run for every substituted codepoint; codepoint-set diff of the resolved config confirms only already-live-elsewhere or newly-verified glyphs are present.
- **Committed in:** `9502c85` (Task 2 commit)

**3. [Rule 1 - Bug] custom/notification's `tooltip` flipped false→true in the vertical redefinition**
- **Found during:** Task 2, verifying the "every glyph-only module has a non-empty tooltip-format" acceptance criterion
- **Issue:** The canonical `custom/notification` sets `tooltip: false`, suppressing the native GTK tooltip entirely. A static `tooltip-format` key is not consumed the same way by a `return-type: json` custom module — the module's own JSON payload supplies the tooltip content when `tooltip` isn't `false`.
- **Fix:** Live-verified `swaync-client -swb`'s actual JSON output (`{"tooltip":"16 Notifications",...}`) and set `tooltip: true` in the vertical redefinition so that dynamic content surfaces on hover — satisfying D-13's "dropped detail lands somewhere" intent via the mechanism this module's data source actually supports.
- **Files modified:** `waybar/.config/waybar/config-vertical.jsonc` only
- **Verification:** Background-process capture of `swaync-client -swb`'s stdout confirmed the live JSON shape.
- **Committed in:** `9502c85` (Task 2 commit)

**4. [Rule 3 - Blocking] Removed `#custom-gaming-mode` from style-vertical.css's grouped geometry selector**
- **Found during:** Task 3, running the literal `grep -c 'custom-gaming-mode' style-vertical.css` acceptance check
- **Issue:** The plan's action text says "give every module widget in the column" a geometry override (which would include gaming-mode), but the acceptance criteria separately and explicitly requires ZERO occurrences of `custom-gaming-mode` in this file (it must inherit purely from the shared sheet).
- **Fix:** Excluded `#custom-gaming-mode` from the grouped selector; it keeps its already-compact shared `waybar-modules.css` pill (padding `0 8px`, no filled background) untouched — consistent with D-31's CSS payoff.
- **Files modified:** `waybar/.config/waybar/style-vertical.css` only
- **Verification:** `grep -c 'custom-gaming-mode' style-vertical.css` returns 0.
- **Committed in:** `d551f93` (Task 3 commit)

**5. [Rule 1 - Bug] Comment wording rewritten to avoid a literal `grep -c 'on-sigusr'` false-positive**
- **Found during:** Task 2, running the acceptance check for "signal contract inherited, not redeclared"
- **Issue:** An explanatory comment literally contained the substring `on-sigusr1/on-sigusr2`, tripping the acceptance criterion's exact-string grep even though no actual key was redeclared.
- **Fix:** Reworded the comment to describe "the fixed hide/reload signal contract" without the literal token.
- **Files modified:** `waybar/.config/waybar/config-vertical.jsonc` only
- **Verification:** `grep -c 'on-sigusr' config-vertical.jsonc` returns 0; `--resolve` still confirms both signal keys resolve correctly from `bar-common.jsonc`.
- **Committed in:** `9502c85` (Task 2 commit)

---

**Total deviations:** 5 auto-fixed (all Rule 1/3 bugs or blocking-issue fixes), 0 unresolved.
**Impact on plan:** Deviations 1-2 were necessary to prevent shipping a genuinely broken (invisible-glyph) vertical layout — the plan's own literal instructions assumed source material that turned out to be empty on inspection; every substitution follows the exact cmap+advance-verification discipline the plan itself established for gaming-mode. Deviations 3-5 are narrow, single-file fixes required to satisfy the plan's own stated acceptance criteria precisely. No scope creep: the shared canonical `modules.jsonc` definitions were deliberately left untouched.

## Known Issues (pre-existing, not caused by this plan, not fixed — out of scope)

- **`theme-doctor` git-clean check fails**: `wallpapers/Pictures/Wallpapers/current.jpg` (modified), `.planning/phases/07-super-key-menu/07-VERIFICATION.md` and `csv` (untracked) were dirty/untracked before this plan started (confirmed via `git status` at session start) and remain so. Already logged in `deferred-items.md` by earlier plans in this phase.
- **`theme-doctor` "walker process running" check fails intermittently**: environmental (walker wasn't running at verification time), unrelated to any change in this plan.
- **The shared `modules.jsonc` canonical `mpris`/`pulseaudio`/`cpu`/`memory`/`temperature` glyph fields remain empty/broken** for `full`/`minimal`/`floating` (pre-existing, dating to the first commit). Not fixed here — out of scope for this plan, and those layouts already degrade gracefully to visible text rather than an invisible widget. Flagged for a future phase/plan to address if desired.

## User Setup Required

None — no external service configuration required. The vertical layout is immediately selectable via the existing Super+B picker (0 script edits) and was live-verified via direct process launch through the exact `waybar-launch.sh` entrypoint.

## Next Phase Readiness

- **Outstanding: a live human visual pass (Super+B → select Vertical) is pending** — this is the plan's own `<verify><human-check>` block (colour-correctness under light/dark presets, glyph rendering with no tofu boxes, hover tooltips, the gaming-mode toggle flipping live). This tool's exec context could not drive `grim`/`hyprctl monitors` screencopy queries (confirmed via `hyprctl clients` returning genuine live windows, so the compositor connection itself is real — only the screencopy-specific queries were unavailable here), so this remains a phase-level checkpoint per 08-01/08-03's own precedent, not a plan-blocking gap.
- 08-08 (media popup `on-click` re-point) can rely on `config-vertical.jsonc`'s `mpris` definition keeping its `on-click`/`on-click-right`/`on-scroll-*` bindings byte-identical to the canonical definition — one predictable place per layout to re-point.
- 08-09 (swaync panel rework) inherits `custom/notification` present in all four layouts now — no more per-layout parity gaps to track.
- `theme-doctor`'s D-17 gate is live infrastructure for every future waybar layout or themed-CSS surface: a 5th layout is covered automatically by the glob, and any future undefined-colour regression fails loudly and mechanically instead of silently rendering unstyled.

---
*Phase: 08-waybar-evolution*
*Completed: 2026-07-14*

## Self-Check: PASSED

All 12 claimed files verified present on disk; all 4 commit hashes (`ccb69af`, `9502c85`, `d551f93`, `38dbd4c`) verified present in `git log --oneline --all`.
