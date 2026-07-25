---
phase: 10-ags-media-applet
plan: 06
subsystem: ui
tags: [ags, astal, gtk4, gjs, waybar, eww, hyprland, mpris, matugen, layer-shell]

# Dependency graph
requires:
  - phase: 10-02
    provides: "AGS scaffold — Astal.Window name='media', instance 'media'; `ags request -i media toggle-media` pinned as the working request form"
  - phase: 10-03
    provides: "Live MPRIS transport/seek/volume/switcher bindings, backend contract (_valid_id-validated ids, argv-form calls)"
  - phase: 10-04
    provides: "Garuda visual restyle + cava audio-reactive underlay + ags-media Hyprland blur layerrule"
  - phase: 10-05
    provides: "matugen [templates.ags] palette + zero-hex style.scss + CSS hot-reload via reload.sh"
provides:
  - "Live switchover: all 3 waybar media on-click sites now run `ags request -i media toggle-media` instead of the dead eww opener"
  - "AGS daemon autostart (`uwsm app -- ags run --directory ~/.config/ags`) in autostart.conf"
  - "eww FULLY retired: media-popup/media-backdrop defwindows, media-popup-open.sh, media-popup-close.sh, eww daemon autostart line, and [templates.eww] matugen block all removed after a consumer check found no remaining eww user"
  - "Top-anchored waybar popup geometry (not full-screen-centered) — a live human-directed design change from the approved spec"
  - "GTK4 transparent-window fix + palette-driven Gtk.Scale styling so blur and slider recolor both actually work"
  - "Human-approved end-to-end gate: waybar click -> AGS applet -> controls/cava/theming all function, old eww popup gone"
affects: [11, future-eww-cleanup]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "GTK4 windows paint an OPAQUE default background (libadwaita @window_bg_color) — any Hyprland layer-shell blur requires an explicit `window { background-color: transparent; }` in the app's own stylesheet before the compositor blur has anything translucent to frost."
    - "GTK4 Gtk.Scale internals (`trough`, `trough highlight`, `slider` nodes) do NOT inherit a custom theme automatically — they fall back to libadwaita's system accent color unless explicitly styled with the app's own palette vars, per slider selector."
    - "Retiring a secondary UI toolkit (eww) is a 3-step consumer-check pattern: grep every other script/config for invocations minus the target's own references, confirm the toolkit's config has no other windows, then remove daemon autostart + matugen template + dead scripts together in one commit."

key-files:
  created: []
  modified:
    - waybar/.config/waybar/modules.jsonc
    - waybar/.config/waybar/config-vertical.jsonc
    - hypr/.config/hypr/config/autostart.conf
    - hypr/.config/hypr/config/windowrules.conf
    - eww/.config/eww/eww.yuck
    - matugen/.config/matugen/config.toml
    - ags/.config/ags/widget/MediaWindow.tsx
    - ags/.config/ags/style.scss
  deleted:
    - hypr/.config/hypr/scripts/media-popup-open.sh
    - hypr/.config/hypr/scripts/media-popup-close.sh

key-decisions:
  - "eww fully retired (not just its media windows): consumer check (`grep -rn 'eww ' hypr/ waybar/ --include=*.sh --include=*.jsonc --include=*.conf | grep -v media-popup` plus `grep -c defwindow eww.yuck`) found media-popup/media-backdrop were eww's only 2 defwindows and the only remaining `eww` references repo-wide were harmless (install.sh package listing, stow.sh dir pre-create, a guarded `pgrep -x eww && eww reload` no-op in theme-engine/lib/reload.sh). Removed eww daemon exec-once from autostart.conf and the `[templates.eww]` block from matugen/config.toml. The eww package itself is left installed (harmless) — dropping it from install.sh is explicitly out of scope for this plan and deferred to a future cleanup."
  - "DESIGN CHANGE (live human direction, not the original spec): the applet moved from a full-screen-centered overlay to a TOP-anchored waybar popup — Astal.WindowAnchor.TOP only, marginTop=54, card-sized (~462x362) instead of a full-viewport container. Verified via grim that the ags-media layer is a small card positioned just under the bar, not full-screen."
  - "GTK4 windows default to an OPAQUE background (libadwaita @window_bg_color) — this silently defeated ALL card translucency and made the Hyprland `blur match:namespace ags-media` layerrule a no-op until `window { background-color: transparent; }` was added to style.scss. Only then did the compositor blur actually frost the desktop behind the card."
  - "Blur strength deliberately weakened per user taste after the transparency fix made it too strong: card composite alpha raised to ~0.44 and the ags-media layerrule's ignore_alpha lowered 0.5->0.25, so the background stays recognizable through a gentle blur rather than fully obscured."
  - "GTK4 Gtk.Scale fill/knob were NOT palette-driven — `.media-seek`/`.media-volume`'s `trough`, `trough highlight`, and `slider` nodes fell back to libadwaita's system accent color instead of the matugen palette, so sliders silently ignored theme switches. Fixed by explicitly styling those three selectors with $surface_variant/$primary palette vars."
  - "Volume icon changed from the 0x1F50A emoji codepoint to the Nerd Font glyph 0xf028 (nf-fa-volume_up) for visual consistency with the rest of the card's iconography; transport prev/next buttons resized to equal 46px circles (were previously mismatched)."

patterns-established:
  - "Toolkit retirement checklist: consumer-check grep -> confirm target windows are the toolkit's only windows -> remove daemon autostart + matugen template + dead scripts atomically -> leave the package installed (reversible) -> document the future install.sh cleanup as explicitly out of scope."
  - "Any GTK4 Astal.Window intended to sit over a Hyprland layer-shell blur rule MUST set `window { background-color: transparent; }` — libadwaita's opaque default silently defeats the blur with no error or warning."

requirements-completed: [MEDIA-01, MEDIA-04]

coverage:
  - id: D1
    description: "All 3 waybar media on-click sites (modules.jsonc mpris + custom/media, config-vertical.jsonc mpris) repointed from the dead eww opener to `ags request -i media toggle-media`"
    requirement: "MEDIA-01"
    verification:
      - kind: manual_procedural
        ref: "structural grep: zero `media-popup-open.sh` references remain in waybar/; `ags request -i media toggle-media` present at modules.jsonc:59, modules.jsonc:278, config-vertical.jsonc:91"
        status: pass
      - kind: e2e
        ref: "human live click test: waybar media segment opens the working AGS applet (Task 3 gate)"
        status: pass
    human_judgment: false
  - id: D2
    description: "AGS daemon autostarts on login via `uwsm app -- ags run --directory ~/.config/ags` in autostart.conf"
    requirement: "MEDIA-04"
    verification:
      - kind: manual_procedural
        ref: "grep confirms exec-once line present at autostart.conf:49, following the file's existing uwsm app -- convention"
        status: pass
    human_judgment: false
  - id: D3
    description: "eww media popup fully retired: media-popup-open.sh/media-popup-close.sh deleted, media-popup/media-backdrop defwindows removed from eww.yuck, eww daemon autostart and [templates.eww] matugen block removed after consumer check found no other eww user"
    requirement: "MEDIA-01"
    verification:
      - kind: manual_procedural
        ref: "consumer-check grep (documented in key-decisions) + structural grep: both scripts absent, both defwindows absent, eww daemon line absent from autostart.conf, [templates.eww] absent from config.toml"
        status: pass
    human_judgment: false
  - id: D4
    description: "Full end-to-end live flow via stow: waybar click opens the AGS applet (top-anchored, not full-screen), transport/seek/volume/switcher work, cava animates, click-away (focus-loss) + Esc + toggle all dismiss, theme switches recolor the applet including the sliders, and the old eww popup never appears"
    verification:
      - kind: e2e
        ref: "Task 3 human-verify checkpoint — user typed 'approved' after exercising the full flow post-`stow ags` + waybar SIGUSR2 reload"
        status: pass
    human_judgment: true
    rationale: "No agent-side pointer injection exists for this live desktop surface (per plan's own Task 3 note) — waybar click, layer-shell popup appearance, cava animation, and theme recolor can only be judged by a human watching the real compositor."

# Metrics
duration: multi-session (Task 3 gate spanned several UI refinement rounds)
completed: 2026-07-15
status: complete
---

# Phase 10 Plan 06: Live Integration + eww Retirement Summary

**Waybar media segment repointed to `ags request -i media toggle-media`, AGS daemon autostarted, and the dead eww media popup fully retired (defwindows, scripts, daemon autostart, matugen template) after a clean consumer check — closing MEDIA-01 and MEDIA-04 with a human-approved live end-to-end gate.**

## Performance

- **Duration:** multi-session (Task 3's human gate spanned several live UI refinement rounds: geometry, icon, transport sizing, frost strength, slider recolor)
- **Completed:** 2026-07-15
- **Tasks:** 3 (2 auto + 1 checkpoint:human-verify, gate APPROVED)
- **Files modified:** 8 modified, 2 deleted (0 created)

## Accomplishments

- **The switchover**: all 3 waybar media `on-click` sites (`modules.jsonc` mpris module, `modules.jsonc` `custom/media`, `config-vertical.jsonc` mpris module) now run `ags request -i media toggle-media` — the exact `-i media` request form pinned in 10-02, since the bare `ags request toggle-media` targets the wrong default AGS instance and fails.
- **AGS autostart**: `exec-once = uwsm app -- ags run --directory ~/.config/ags` added to `autostart.conf`, following the file's existing `uwsm app --` convention, so the applet daemon is present after a fresh login.
- **eww fully retired**: consumer check found media-popup/media-backdrop were eww's only 2 defwindows and nothing else in `hypr/` or `waybar/` invokes the `eww` binary (remaining hits were an install.sh package listing, a stow.sh dir pre-create, and a guarded `pgrep -x eww && eww reload` no-op in `theme-engine/lib/reload.sh`). Removed: `defwindow media-popup` + `defwindow media-backdrop` and their now-orphaned supporting declarations from `eww.yuck` (file still parses cleanly — verified via a transient `eww daemon --no-daemonize` init/shutdown with zero errors); the two `media-popup-*.sh` scripts (`git rm`); the eww daemon `exec-once` line from `autostart.conf`; the `[templates.eww]` block from `matugen/config.toml`. The `eww` package itself stays installed (harmless, trivially reversible) — dropping it from `install.sh` is explicitly out of scope here and deferred.
- **Human-approved live gate (Task 3)**: after `stow ags` + AGS daemon restart + `pkill -SIGUSR2 waybar`, the user exercised the full real flow — waybar click opens the AGS applet (top-anchored under the bar, not the old eww popup), transport/seek/volume/switcher all work, cava bars animate, click-away (focus-loss) + Esc + re-toggle all dismiss the card, static and dynamic theme switches recolor the applet including the sliders, and the old eww popup never appears again. Approved.
- **Design deviation, human-directed**: the applet's on-screen form changed from the originally-approved full-screen-centered overlay to a **top-anchored waybar popup** (`Astal.WindowAnchor.TOP` only, `marginTop=54`, card-sized ~462x362) — a live UX call made during the gate, not a silent scope change.
- **Two durable GTK4 findings that unblocked the visual gate**:
  1. GTK4 windows paint an **opaque default background** (libadwaita `@window_bg_color`) — this silently defeated all card translucency and made the Hyprland `blur match:namespace ags-media` layerrule a complete no-op until `window { background-color: transparent; }` was added to `style.scss`. Only then did the compositor blur actually frost the desktop behind the card.
  2. GTK4 `Gtk.Scale` fill/knob (`trough`, `trough highlight`, `slider` nodes) are **not palette-driven by default** — `.media-seek`/`.media-volume` silently fell back to libadwaita's system accent color instead of the matugen palette, so sliders never recolored on theme switch. Fixed by explicitly styling those three selectors with `$surface_variant`/`$primary` palette vars.

## Task Commits

Each task was committed atomically (Task 3's human-directed UI refinement produced multiple follow-up commits during the live gate, all still scoped to Task 3's flow):

1. **Task 1: Repoint waybar media on-click to AGS + autostart AGS daemon** - `abe252c` (feat)
2. **Task 2: Retire the eww media popup** - `a4c8c91` (feat)
3. **Task 3: End-to-end live gate — UI refinement rounds directed by the human during verification:**
   - `9911f9e` (fix) — convert media window to top-anchored waybar popup; fix volume icon + transport button sizing
   - `cdcb02c` (fix) — stronger frosted-glass card + wider/shorter proportions
   - `cf1bea4` (fix) — frostier translucent card, wider+shorter layout
   - `eb8563d` (fix) — make MediaWindow transparent so the ags-media blur layerrule has something to frost (KEY FINDING)
   - `bf6d90c` (fix) — weaken ags-media blur so background stays visible through the card (user taste)
   - `372e466` (fix) — drive media slider fill/knob from palette vars so sliders recolor on theme switch (KEY FINDING)

**Plan metadata:** (this commit) `docs(10-06): complete live integration + eww retirement (human-approved)`

_Note: Task 3 is a `checkpoint:human-verify` gate — its multiple fix commits reflect live, human-directed UI iteration during verification, not scope creep. All were approved as part of the same end-to-end gate._

## Files Created/Modified

- `waybar/.config/waybar/modules.jsonc` - mpris + `custom/media` on-click repointed to `ags request -i media toggle-media`
- `waybar/.config/waybar/config-vertical.jsonc` - mpris on-click repointed to `ags request -i media toggle-media`
- `hypr/.config/hypr/config/autostart.conf` - AGS daemon exec-once added; eww daemon exec-once removed
- `hypr/.config/hypr/config/windowrules.conf` - ags-media layerrule blur alpha tuning
- `eww/.config/eww/eww.yuck` - media-popup + media-backdrop defwindows and orphaned supporting declarations removed (178 lines net removed); file still parses
- `matugen/.config/matugen/config.toml` - `[templates.eww]` block removed
- `ags/.config/ags/widget/MediaWindow.tsx` - top-anchor geometry, transparent window, volume icon, transport button sizing, palette-driven slider styling
- `ags/.config/ags/style.scss` - transparent window rule, frosted-card alpha tuning, slider trough/slider palette styling (still zero literal hex — verified)
- `hypr/.config/hypr/scripts/media-popup-open.sh` - deleted (git rm)
- `hypr/.config/hypr/scripts/media-popup-close.sh` - deleted (git rm)

## Decisions Made

See `key-decisions` in frontmatter for the full list. Highlights: eww fully retired (package left installed, install.sh cleanup deferred); design changed from full-screen-centered to top-anchored waybar popup per live human direction; blur strength deliberately weakened after the transparency fix per user taste; two durable GTK4 findings (opaque default window background, non-palette-driven Gtk.Scale internals) fixed and documented as reusable lessons.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] GTK4 opaque default window background defeated the Hyprland blur layerrule**
- **Found during:** Task 3 (live human gate — card had no visible frost/translucency despite the layerrule being correctly configured in 10-04)
- **Issue:** libadwaita's `@window_bg_color` paints every GTK4 `Astal.Window` with an opaque background by default; the `blur match:namespace ags-media` layerrule from 10-04 had nothing translucent to frost.
- **Fix:** Added `window { background-color: transparent; }` to `style.scss`.
- **Files modified:** `ags/.config/ags/style.scss`
- **Verification:** Live visual confirmation — desktop behind the card became visibly frosted after the fix.
- **Committed in:** `eb8563d`

**2. [Rule 1 - Bug] Gtk.Scale sliders did not recolor on theme switch**
- **Found during:** Task 3 (live human gate — theme switch test)
- **Issue:** `.media-seek`/`.media-volume`'s `trough`/`trough highlight`/`slider` CSS nodes fell back to libadwaita's system accent color instead of the matugen palette, since GTK4's Scale internals are not palette-driven by default.
- **Fix:** Explicitly styled `trough`, `trough highlight`, and `slider` with `$surface_variant`/`$primary` palette vars for both `.media-seek` and `.media-volume`.
- **Files modified:** `ags/.config/ags/style.scss`
- **Verification:** Live theme switch (static + dynamic) confirmed sliders now recolor.
- **Committed in:** `372e466`

**3. [Rule 4 - Architectural, human-directed] Applet geometry changed from full-screen-centered overlay to top-anchored waybar popup**
- **Found during:** Task 3 (live human gate — the human directed a different UX than the originally-approved spec)
- **Issue:** The approved spec called for a full-screen-centered overlay; live testing revealed the human preferred a compact popup anchored under the waybar, matching a more conventional "click bar segment -> popup drops down" pattern.
- **Change:** `Astal.WindowAnchor.TOP` only (was `TOP|BOTTOM|LEFT|RIGHT`), `marginTop=54`, card-sized window (~462x362) instead of a full-viewport container.
- **Files modified:** `ags/.config/ags/widget/MediaWindow.tsx`, `ags/.config/ags/style.scss`, `hypr/.config/hypr/config/windowrules.conf`
- **Verification:** Live human approval of the new geometry as part of the Task 3 gate; confirmed via `grim` that the ags-media layer is a small card positioned just under the bar (xywh ~1099,54,362,482 on a 2560x1440 screen), not full-screen.
- **Committed in:** `9911f9e` (initial conversion), refined in `cdcb02c`, `cf1bea4`

---

**Total deviations:** 3 (2 Rule 1 bug fixes, 1 Rule 4 human-directed design change — all discovered and resolved live during the Task 3 human-verify gate, not silently).
**Impact on plan:** All three were necessary to reach a genuinely working, human-approved applet. The Rule 4 geometry change was explicitly authorized live by the human during the gate itself (not a unilateral agent decision) — documented here per Rule 4's requirement to record architectural changes even when approved in-session rather than via a separate checkpoint round-trip.

## Issues Encountered

None beyond the deviations documented above — all were surfaced and resolved within the Task 3 live gate itself.

## User Setup Required

None - no external service configuration required. `stow ags` (already run in 10-02) plus the new AGS autostart line and repointed waybar on-clicks are all that's needed; a fresh install picks these up automatically via `install.sh` + `stow.sh`.

## Known Stubs

None. No hardcoded empty values, placeholder text, or unwired data sources were introduced by this plan — the applet is fully live-wired to the real MPRIS backend (inherited from 10-03) and the real matugen palette (inherited from 10-05).

## Threat Flags

None. Both threats registered in this plan's `<threat_model>` (T-10-06-01 waybar on-click tampering, T-10-06-02 MPRIS backend command injection) were mitigated exactly as planned — the on-click is a fixed literal verb with nothing interpolated, and the MPRIS backend inherits the 08-07 validated-id/argv-form contract unchanged. T-10-06-03 (eww daemon removal DoS) was accepted per the plan's own disposition — the consumer check confirmed eww had no other user before removal, and the package remains installed for trivial reversibility. No new security-relevant surface (network endpoints, auth paths, file access patterns, schema changes) was introduced beyond what the plan's threat model already covers.

## Next Phase Readiness

- Phase 10 (AGS Media Applet) has now executed all 6 of its planned plans; MEDIA-01, MEDIA-02, MEDIA-03, and MEDIA-04 are all delivered across 10-02 through 10-06.
- This plan (10-06) is marked complete; the phase itself is NOT yet marked complete/verified — that happens via the orchestrator's phase-level verification step, which runs next.
- No `ags` process is currently running on this machine (confirmed via `pgrep -fa ags` at SUMMARY time) — the applet autostarts on login per the new `autostart.conf` entry and is otherwise started on demand by the user, consistent with how the rest of this desktop's daemons behave.
- No blockers carried forward specific to this plan. Dropping the now-unused `eww` package from `install.sh`'s package arrays is an explicitly deferred, out-of-scope cleanup for a future plan/quick-task.

---
*Phase: 10-ags-media-applet*
*Completed: 2026-07-15*
