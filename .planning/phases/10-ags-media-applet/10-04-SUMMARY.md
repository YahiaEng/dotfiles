---
phase: 10-ags-media-applet
plan: 04
subsystem: ui
tags: [ags, astal, gtk4, gjs, typescript, jsx, cava, sass, hyprland, layer-shell, media]

# Dependency graph
requires:
  - phase: 10-03
    provides: "reactive `media` accessor (incl. media.art), working transport/seek/volume/switcher control tree, pinned AGS 3.1.0 primitives, -i media request form"
  - phase: 10-02
    provides: "AGS scaffold — Astal.Window name='media' namespace='ags-media', click-away/Esc, toggle-media request; sass-on-PATH launch requirement"
provides:
  - "lib/cava.ts — spawns `cava -p config` and exposes a reactive `bars` number[] accessor (0..1 normalized heights)"
  - "widget/Cava.tsx — self-contained widget rendering `bars` as 24 height-scaled boxes, reading `bars` directly (no props)"
  - "cava/config — raw-stdout cava config (24 bars, framerate 60, ascii, ; delimiter)"
  - "MediaWindow.tsx garuda restyle — Gtk.Overlay stack (blurred art bg + scrim -> cava underlay -> centered thumbnail -> centered control panel)"
  - "Hyprland `ags-media` blur + ignore_alpha layerrules (the frosted-card compositor blur)"
  - "Human-confirmed cava animation + garuda frosted look (MEDIA-02)"
affects: [10-05, 10-06]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "cava raw-stdout bridge: subprocess(['cava','-p',CONFIG]) -> split each line on ';' -> Number(v)/100 -> setBars; empty/partial lines ignored so the last good frame is held"
    - "Gtk.Overlay stacking in AGS JSX: main child sizes the card; overlay children added via `$type=\"overlay\"`, positioned by their own halign/valign; overflow={Gtk.Overflow.HIDDEN} clips art/thumbnail to the rounded card"
    - "Ellipsize long labels inside FILL boxes: an un-ellipsized Gtk.Label's MINIMUM width equals its full text and cannot shrink, so it overflows a fixed-width card and de-centers sibling rows; Pango.EllipsizeMode.END + maxWidthChars caps the min width"
    - "Guard Gtk.Image on a real non-empty file path (via a With-bound accessor) — GTK's fallback broken-image icon ignores pixelSize/widthRequest and overflows its allocation; fall back to a neutral rgba placeholder box instead of an empty file"

key-files:
  created:
    - ags/.config/ags/cava/config
    - ags/.config/ags/lib/cava.ts
    - ags/.config/ags/widget/Cava.tsx
  modified:
    - ags/.config/ags/widget/MediaWindow.tsx
    - ags/.config/ags/style.scss
    - hypr/.config/hypr/config/windowrules.conf

key-decisions:
  - "An un-ellipsized Gtk.Label has a minimum width equal to its FULL text; inside a halign=FILL box (which cannot shrink below its widest child's minimum) a long title overflowed the ~360px card and threw off every control row's horizontal position. Fix: ellipsize the title (Pango.EllipsizeMode.END + maxWidthChars) so the box collapses to card width and centered children actually center. Durable GTK4/AGS layout lesson."
  - "Both art renders (background + thumbnail) are gated on a real non-empty art path via a shared With-bound accessor, falling back to a neutral rgba placeholder box — GTK's fallback broken-image icon ignores pixelSize/widthRequest and overflowed the card's rounded top. Side benefit: real album art will render correctly with no further code change once a player exposes it."
  - "cava is confined to a fixed-height upper zone (valign=START) above the bottom controls panel so the bars/thumbnail never overlap the metadata/transport rows."
  - "style.scss uses temporary neutral rgba() values only — ZERO hex literals — because 10-05 replaces them with matugen palette @import vars and enforces zero-hex."
  - "windowrules.conf uses the repo's `layerrule = blur on, match:namespace ags-media` / `ignore_alpha 0.5, match:namespace ags-media` form (Hyprland 0.55.4), mirroring the existing eww-media-popup rules — NOT the approved plan's older `blur, ags-media` shorthand."

patterns-established:
  - "cava raw-stdout -> reactive bars -> height-scaled widget bridge for AGS audio visualizers"
  - "Ellipsize labels that live in FILL/fixed-width containers to prevent min-width overflow de-centering siblings"
  - "Gate Gtk.Image on a real file path; never hand it an empty string (broken-icon overflow)"

requirements-completed: [MEDIA-02]

coverage:
  - id: D1
    description: "cava/config emits 24 raw ascii bars to stdout (; delimiter); lib/cava.ts parses frames into a reactive 0..1 `bars` accessor; Cava.tsx renders them as height-scaled bars"
    requirement: "MEDIA-02"
    verification:
      - kind: manual_procedural
        ref: "timeout 2 cava -p ags/.config/ags/cava/config | head -1 -> printed a 24-value ';'-delimited numeric line; structural greps confirm setBars + reactive bars + Cava mount"
        status: pass
    human_judgment: false
  - id: D2
    description: "cava bars ANIMATE to audio behind/around the centered album-art thumbnail"
    requirement: "MEDIA-02"
    verification:
      - kind: manual_procedural
        ref: "Task 3 human gate — user played audio, opened the applet, watched the bars animate; APPROVED"
        status: pass
    human_judgment: true
    rationale: "A static grim screenshot cannot prove motion over time; only a human watching the bars move to audio can confirm animation. Confirmed by the user."
  - id: D3
    description: "MediaWindow renders the garuda look — Gtk.Overlay stack (blurred art bg + scrim -> cava underlay -> centered thumbnail -> centered control panel); Hyprland blurs the ags-media layer (frosted card)"
    requirement: "MEDIA-02"
    verification:
      - kind: manual_procedural
        ref: "Task 3 human gate — user confirmed frosted blurred-art card, rounded pills, legible overlaid controls, distinct from the athena bar; APPROVED"
        status: pass
    human_judgment: true
    rationale: "Visual/aesthetic adequacy (frosted blur, garuda intent) is a human-judgment call not assertable by automation. Confirmed by the user."
  - id: D4
    description: "All control rows (title/artist, transport, seek, volume, switcher) horizontally centered within the card; long title ellipsized and never clipped"
    requirement: "MEDIA-02"
    verification:
      - kind: automated_ui
        ref: "pixel measurement on /tmp/ags-10-04b.png (card x[1099..1460] center=1279): TITLE Lgap62/Rgap61, ARTIST 170/171, TRANSPORT 127/128, SEEK 63/63, VOLUME 88/92, SWITCHER 145/145 — all delta<=2px; title spans x[1161..1399] fully inside card, ending in an ellipsis"
        status: pass
    human_judgment: false
  - id: D5
    description: "Hyprland ags-media blur + ignore_alpha layerrules added in the repo's match:namespace form; style.scss has zero hex literals; glyphs codepoint-written non-empty; no NUL bytes"
    requirement: "MEDIA-02"
    verification:
      - kind: manual_procedural
        ref: "grep WIRED_OK (overlay+Cava+blur.*ags-media); hex count=0; 5 fromCodePoint glyphs; grep -qaP '\\x00' clean on all 6 files; hyprctl reload -> ok"
        status: pass
    human_judgment: false

# Metrics
duration: multi-session (checkpoint-gated; 1 human re-gate round for centering)
completed: 2026-07-15
status: complete
---

# Phase 10 Plan 04: Garuda Restyle + Cava Underlay Summary

**AGS media card restyled to the garuda/HyprPanel look — a Gtk.Overlay stack with a blurred album-art background, a cava audio-reactive bar underlay bleeding around a centered thumbnail, and centered rounded-pill controls — with a Hyprland `ags-media` blur layerrule frosting the card, human-confirmed animating to audio (MEDIA-02).**

## Performance

- **Duration:** multi-session (checkpoint-gated; the initial human gate rejected control mis-alignment, fixed and re-approved in a second round)
- **Completed:** 2026-07-15
- **Tasks:** 3 (2 auto + 1 human-verify gate)
- **Files:** 3 created, 3 modified

## Accomplishments

- **MEDIA-02 delivered and human-approved.** The user played audio, opened the applet, and confirmed the cava bars animate to the audio and the card matches the garuda frosted intent (blurred-art background, rounded pills, legible centered controls, distinct from the athena bar).
- **cava audio-reactive underlay** wired end-to-end: `cava -p config` raw `;`-delimited stdout -> `lib/cava.ts` parses each frame into a reactive `bars` 0..1 accessor -> `widget/Cava.tsx` renders 24 height-scaled boxes reading `bars` directly.
- **Garuda overlay restyle** of `MediaWindow.tsx`: a `Gtk.Overlay` stack — blurred art background + translucent scrim (main child) -> cava underlay confined to a fixed upper zone -> centered album-art thumbnail -> a bottom control panel (metadata/transport/seek/volume/switcher). The 10-02 window/click-away/Esc and 10-03 control behavior are preserved unchanged.
- **Hyprland `ags-media` blur + ignore_alpha layerrules** added to `windowrules.conf` in the repo's existing `match:namespace` form (mirroring the `eww-media-popup` rules); `hyprctl reload` applied live so the frost was verifiable.
- **All control rows centered** with the long title ellipsized — verified by pixel measurement (all rows ≤2px off card center).

## Task Commits

1. **Task 1: cava pipeline (config + lib/cava.ts + Cava.tsx)** — `d293496` (feat)
2. **Task 2: garuda overlay restyle + style.scss + ags-media blur layerrule** — `1b823be` (feat)
3. **Task 2 follow-up fix (raised at the human gate): center controls + ellipsize title** — `844e9ca` (fix)
4. **Task 3: human-verify animation + garuda look gate** — no commit (verification gate; APPROVED by the user)

## Files Created/Modified

- `ags/.config/ags/cava/config` — raw-stdout cava config (24 bars, framerate 60, ascii, `ascii_max_range=100`, `bar_delimiter=59`)
- `ags/.config/ags/lib/cava.ts` — spawns the cava subprocess, parses `;`-delimited 0..100 frames into a reactive `bars` 0..1 accessor
- `ags/.config/ags/widget/Cava.tsx` — self-contained widget: 24 static boxes with a reactively bound `heightRequest` reading `bars` directly
- `ags/.config/ags/widget/MediaWindow.tsx` — restyled to a `Gtk.Overlay` garuda stack; art gated on a real path; title/artist ellipsized; all rows centered; 10-02/10-03 window+controls preserved
- `ags/.config/ags/style.scss` — garuda styling (rounded pills, circular-ish transport, translucent scrim/controls panel, ~360x480 card) using temporary neutral rgba only (zero hex)
- `hypr/.config/hypr/config/windowrules.conf` — `ags-media` blur + ignore_alpha layerrules (match:namespace form)

## Durable Findings

### Un-ellipsized Gtk.Label min-width de-centers a fixed-width card (load-bearing GTK4/AGS layout lesson)

A `Gtk.Label` without ellipsize/wrap has a **minimum width equal to its full text**. Placed inside a `halign=FILL` box — which cannot shrink below its widest child's minimum — a long track title (~800px) forced the entire bottom control panel far wider than the ~360px card. The overflow threw off the horizontal position of every sibling row (title clipped at the right edge; transport/volume/switcher shoved off-center), while the seek slider — the one child that was FILL and thus already spanning full width — happened to look fine. **Fix:** ellipsize the title (`Pango.EllipsizeMode.END` + `maxWidthChars`), which caps the label's minimum width so the box collapses back to card width and each `halign=CENTER` row centers correctly. Verified by pixel measurement: all rows ≤2px off card center, title fully inside the card ending in an ellipsis.

### Gate Gtk.Image on a real file path — the broken-image fallback overflows

Handing `Gtk.Image` an empty/invalid `file` makes GTK render its fallback "broken image" icon, which **ignores `pixelSize`/`widthRequest`** and overflowed the card's rounded top edge. Gating both the background-art and thumbnail `<image>` on a real non-empty path (via a shared `With`-bound `media.as(m => m.art)` accessor) and falling back to a neutral rgba placeholder box fixes it. Bonus: real album art now renders correctly with no further code change once a player exposes `mpris:art`.

## Decisions Made

See key-decisions frontmatter. The three durable choices: the ellipsize-min-width layout lesson, the art-path gating, and the fixed-upper-zone cava confinement.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `~/.config/ags` was not stowed**
- **Found during:** Task 1 (first live cava render check)
- **Issue:** `lib/cava.ts` resolves its config path via `GLib.get_home_dir()/.config/ags/cava/config` (per the approved plan, verbatim) — which only resolves against the real stowed location, not the `--directory` flag used to run AGS in place. `~/.config/ags` did not yet exist, so `ags run` aborted with `Unable to open file '.../.config/ags/cava/config'`.
- **Fix:** Ran `stow ags` (idempotent standard GNU stow) to create the `~/.config/ags -> dotfiles/ags/.config/ags` symlink — the exact same operation 10-06 performs during integration. **Only a symlink was created; no repository files were modified.**
- **Verification:** `readlink -f ~/.config/ags` resolves to the repo; cava config loads; subsequent `ags run` compiled and rendered clean.
- **Committed in:** n/a (filesystem symlink, not a repo change)

**2. [Rule 1 - Bug] Centered thumbnail overlapped the artist/transport rows**
- **Found during:** Task 2 (first live render)
- **Issue:** With the art+cava+thumbnail centered across the full card height, the thumbnail sat on top of the artist name and transport buttons.
- **Fix:** Confined the cava+thumbnail cluster to a fixed-height upper zone (`valign=START`) above the bottom controls panel; bumped card `min-height` to 480.
- **Files modified:** `ags/.config/ags/widget/MediaWindow.tsx`, `ags/.config/ags/widget/Cava.tsx`, `ags/.config/ags/style.scss`
- **Verification:** Re-render — thumbnail no longer overlaps the controls.
- **Committed in:** `1b823be` (Task 2 commit)

**3. [Rule 1 - Bug] GTK broken-image fallback icon overflowed the card's rounded top**
- **Found during:** Task 2 (live render — no real art resolves for the Firefox/YouTube MPRIS player)
- **Issue:** Passing `Gtk.Image` an empty art path rendered GTK's fallback broken-image icon, which ignored `pixelSize`/`widthRequest`/an `overflow:hidden` wrapper and poked out above the card into the desktop.
- **Fix:** Root-caused with a controlled real-image test (which rendered correctly, fully contained — proving the overlay/clip structure sound), then gated both art `<image>` elements on a real non-empty path via a shared `With`-bound accessor, falling back to a neutral rgba placeholder box.
- **Files modified:** `ags/.config/ags/widget/MediaWindow.tsx`, `ags/.config/ags/style.scss`
- **Verification:** Re-render — clean placeholder box, no overflow; a real file renders correctly within bounds.
- **Committed in:** `1b823be` (Task 2 commit)

**4. [Rule 1 - Bug] Control rows right-shifted / title clipped at the card edge (raised at the human gate)**
- **Found during:** Task 3 human gate (round 1 — rejected)
- **Issue:** The un-ellipsized title's full-text minimum width forced the `halign=FILL` controls box wider than the ~360px card, de-centering the transport/volume/switcher rows and clipping the title at the right border.
- **Fix:** Ellipsized the title (`Pango.EllipsizeMode.END` + `maxWidthChars=26`, `xalign=0.5`, `justify=CENTER`) and artist; set the controls box `halign=FILL` + `hexpand` with every row `halign=CENTER`; gave the seek slider + fallback explicit `halign=CENTER`. Added `import Pango from "gi://Pango"`.
- **Files modified:** `ags/.config/ags/widget/MediaWindow.tsx`
- **Verification:** Pixel measurement on a re-rendered full-window grim (card center 1279): TITLE 62/61, ARTIST 170/171, TRANSPORT 127/128, SEEK 63/63, VOLUME 88/92, SWITCHER 145/145 — all delta ≤2px; title ellipsized, fully inside the card. Human gate round 2 APPROVED.
- **Committed in:** `844e9ca` (fix commit)

---

**Total deviations:** 4 (1 blocking stow symlink — no repo change; 3 Rule-1 bugs, one surfaced at the human gate).
**Impact on plan:** All fixes necessary for correct layout/containment and the approved garuda look. No scope creep — `media.ts`, the MPRIS backend, and the request/window contract are untouched.

## Security

- The cava subprocess is spawned argv-form (`["cava", "-p", CONFIG]`); its stdout is split on `;` and coerced with `Number()` — non-numeric tokens become `NaN` and only non-empty numeric arrays are applied. No cava output ever reaches a command (T-10-04-01 mitigated).
- The album-art path (`media.art`, resolved by the trusted backend) is consumed only as a `Gtk.Image` source path, never passed to a shell (T-10-04-02); a dead/absent cava simply yields no bars (T-10-04-03).
- No MPRIS backend script was modified.

## Issues Encountered

- The control layout required a second human-gate round: the initial render's un-ellipsized title de-centered every row. Root-caused at the layout layer (label min-width vs FILL box) and pixel-measured to confirm the fix, rather than eyeballed — the first "looks clean" crop-only self-check had missed the off-center rows.

## Cosmetic Note (carried forward)

No real album art resolves for the Firefox/YouTube MPRIS player (a backend limitation flagged in 10-03), so the background-art and thumbnail render as neutral placeholder boxes rather than a photo. This now renders **cleanly** (no broken-icon overflow), and real art will appear automatically for any player that exposes `mpris:art` (e.g. Spotify) with no further code change.

## User Setup Required

None — no external service configuration. The `stow ags` symlink is reproducible via the existing stow workflow and is (re-)performed by 10-06 integration.

## Next Phase Readiness

- MEDIA-02 delivered and human-approved. Ready for **10-05** (matugen `ags-colors.scss` template + `[templates.ags]` config entry + CSS hot-reload), which replaces this plan's temporary neutral rgba values in `style.scss` with palette `@import` vars and enforces the zero-hex rule. The zero-hex-literal baseline is already in place, easing that swap.

---
*Phase: 10-ags-media-applet*
*Completed: 2026-07-15*

## Self-Check: PASSED
- `ags/.config/ags/cava/config` — FOUND
- `ags/.config/ags/lib/cava.ts` — FOUND
- `ags/.config/ags/widget/Cava.tsx` — FOUND
- `ags/.config/ags/widget/MediaWindow.tsx` (modified) — FOUND
- `ags/.config/ags/style.scss` (modified) — FOUND
- `hypr/.config/hypr/config/windowrules.conf` (modified) — FOUND
- Commit `d293496` (cava pipeline) — FOUND
- Commit `1b823be` (garuda overlay restyle + blur layerrule) — FOUND
- Commit `844e9ca` (centering + title-ellipsize fix) — FOUND
