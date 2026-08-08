---
phase: 16-workspace-overview
plan: 07
subsystem: ui
tags: [quickshell, qml, keyboard-navigation, hyprland, layer-rules, blur, multieffect, qtquick-shapes]

requires:
  - phase: 16-06
    provides: "dispatchWindowMove() — the guarded, address-validated move dispatch that Shift+1..0 reuses rather than re-deriving"
  - phase: 16-05
    provides: "activateWindow() click-to-focus parity, which Enter at window level matches exactly"
  - phase: 16-03
    provides: "WorkspaceTile/WindowThumbnail — the tile and thumbnail types this plan adds selection rendering to"
provides:
  - "Two-level keyboard selection (tile level and window level) over all eleven slots"
  - "Enter to descend/activate, Shift+1..0 to move the selected window, two-stage Esc"
  - "A theme-adaptive animated sweep ring marking the keyboard selection"
  - "Click-outside dismiss for a full-screen layer surface"
  - "Frosted-glass tiles over an untouched desktop — no full-bleed scrim"
affects: [16-08, future-overview-work, any-quickshell-surface-using-layer-blur]

actuals:
  tokens: 47000
  tasks: 3
  commits: 16

tech-stack:
  added:
    - "QtQuick.Shapes (ConicalGradient + PathRectangle annulus) — chosen over Qt5Compat.GraphicalEffects because install.sh does not provision qt6-5compat"
    - "QtQuick.Effects MultiEffect in WindowThumbnail for thumbnail elevation"
  patterns:
    - "Shadow cast by a shape-proxy Rectangle, never by a live ScreencopyView"
    - "Per-namespace Hyprland layer rules declared AFTER the family regex"

key-files:
  created: []
  modified:
    - quickshell/.config/quickshell/modules/Overview.qml
    - quickshell/.config/quickshell/modules/overview/WorkspaceTile.qml
    - quickshell/.config/quickshell/modules/overview/WindowThumbnail.qml
    - hypr/.config/hypr/config/windowrules.lua
    - .planning/phases/16-workspace-overview/16-07-PLAN.md
    - .planning/phases/16-workspace-overview/deferred-items.md

key-decisions:
  - "D-16-17 settled: full keyboard navigation KEPT — the pre-agreed fallback was not taken"
  - "D-16-16 superseded: Down always jumps a row; Enter is the only descent"
  - "Linear wrap superseded by edge-stop — the plan's own pre-authorised one-line fallback"
  - "D-16-06 superseded: no full-bleed scrim; only the tiles carry fill and frost"
  - "T-16-31's proxy grep corrected to count move-dispatch sites, not all dispatches"

patterns-established:
  - "Verify compositor-visual work by screenshot before tuning any value"
  - "Layer-rule edits need `hyprctl eval` or a restart — `hyprctl reload` drops them silently"
  - "An alpha cutoff cannot separate two regions that share an alpha"

requirements-completed: [OVER-02, OVER-03]

coverage:
  - id: D1
    description: "Arrow keys move a selection across all eleven tiles with no pointer click first, with edge-stop at both ends"
    requirement: OVER-02
    verification:
      - kind: manual_procedural
        ref: "16-07 render gate rounds 1-4 — operator confirmed arrows respond immediately after Super+O and edge-stop works"
        status: pass
    human_judgment: false
  - id: D2
    description: "Enter descends into a tile's windows and focuses one; Enter on an empty workspace focuses it and closes"
    requirement: OVER-02
    verification:
      - kind: manual_procedural
        ref: "16-07 render gate round 1 — empty-workspace Enter fixed via dispatchWorkspaceFocus(), operator confirmed"
        status: pass
    human_judgment: false
  - id: D3
    description: "Shift+1..0 moves the window-level selection through 16-06's guarded dispatch, overview stays open"
    requirement: OVER-03
    verification:
      - kind: automated_ui
        ref: "grep -c 'hl.dsp.window.move' Overview.qml == 1 (unchanged from post-16-06)"
        status: pass
      - kind: manual_procedural
        ref: "16-07 render gate round 1 — operator confirmed after the Qt shifted-keysym fix"
        status: pass
    human_judgment: false
  - id: D4
    description: "Two-stage Esc: first press leaves window level, second dismisses"
    requirement: OVER-02
    verification:
      - kind: manual_procedural
        ref: "16-07 render gate — confirmed at first pass, never regressed"
        status: pass
    human_judgment: false
  - id: D5
    description: "Type-to-search boundary: no TextInput/TextField/TextEdit anywhere in the overview module tree"
    verification:
      - kind: automated_ui
        ref: "grep for TextInput|TextField|TextEdit across Overview.qml + modules/overview/*.qml — zero hits"
        status: pass
    human_judgment: false
  - id: D6
    description: "Visual design: theme-adaptive sweep ring, readable slot numbers, frosted tiles over an untouched desktop"
    verification:
      - kind: manual_procedural
        ref: "16-07 render gate rounds 5-13, screenshot-verified on the live surface"
        status: pass
    human_judgment: true
    rationale: "Standing constraint 1 requires human render-and-look sign-off on every visual surface; no automated check can judge whether a surface reads as floating glass rather than as an application window."

duration: 2 sessions
completed: 2026-08-08
status: complete
---

# Phase 16 Plan 07: Keyboard Navigation Summary

**The overview became fully operable without a pointer — and, across thirteen render-gate rounds, stopped looking like an application and became frosted panes floating over an untouched desktop.**

## Performance

- **Duration:** 2 sessions (2026-08-07 implementation, 2026-08-08 render gate)
- **Tasks:** 3 of 3 (2 auto, 1 blocking human-verify)
- **Files modified:** 6 (3 QML, 1 Hyprland config, 2 planning)
- **Render-gate rounds:** 13

## Accomplishments

- **Two-level keyboard selection over all eleven slots.** Arrows move between tiles; Enter descends into a tile's windows; arrows then move between those; Enter focuses one and closes. Two-stage Esc backs out one level before dismissing.
- **`Shift+1..0` moves the selected window** through plan 16-06's existing guarded dispatch. The move-dispatch construction count in `Overview.qml` is still exactly 1 — one mechanism, two input paths.
- **D-16-17 settled in favour of keeping full keyboard navigation.** The gate was empowered to strip window-level selection and the mode indicator back to Escape-plus-number-keys without a new decision; the operator confirmed the two levels earn their keep once `Shift+number` actually worked.
- **The surface was substantially redesigned at the gate** — quiet slot chrome, elevated window thumbnails, and no full-bleed scrim, so only the tiles carry fill and frost.

## Task Commits

1. **Task 1: Tile-level selection — arrows, Enter, two-stage Esc** — `e80d7a5` (feat)
2. **Task 2: Window-level selection, Enter-to-focus, Shift+1..0** — `342e577` (feat)
3. **Task 3: Render gate (blocking)** — 13 rounds, `72d04cd` … `6ffa551`

Gate rounds, in order: `72d04cd` six defects · `b85d5be` deferred item · `79d02e5` sweep ring + slot numbers · `b783e9f` annulus rebuild · `32f0522` edge-stop, slower sweep · `d58205d` blur restored · `e984761` fill removed · `4cb8062` ring widened · `6899e7f` frost regression · `419aed8` cutoff split · `144b9d0` **reload trap found** · `acd4080` floating thumbnails · `7f65dad` scrim removed · `6ffa551` opacity settled

## Files Created/Modified

- `modules/Overview.qml` — selection state, key handling, edge-stop, mode indicator, workspace-focus dispatch, click-outside catch, scrim removed
- `modules/overview/WorkspaceTile.qml` — sweep ring (Shapes annulus), hairline chrome, unified frosted fill, legible identity pill
- `modules/overview/WindowThumbnail.qml` — window-level selection outline, MultiEffect elevation
- `hypr/.config/hypr/config/windowrules.lua` — blur + `ignore_alpha` restored for `quickshell-overview`, declared after the family pair
- `16-07-PLAN.md` — six criteria/truths amended (each with its reason)
- `deferred-items.md` — inherited-opacity defect on the capture-failure catch

## Decisions Made

- **Down no longer descends** (supersedes D-16-16's "Enter or Down"). An overloaded Down changed selection *level* while merely moving through the grid; the mode pill flipping was the only outward sign. Enter is now the sole descent.
- **Edge-stop replaces linear wrap.** The plan pre-authorised this exact one-line fallback. Under the modulo, slot 0 and slot 10 were adjacent, so one Left from workspace 1 threw the selection across the whole grid.
- **No full-bleed scrim** (supersedes D-16-06). A scrim covers the screen by definition; the requirement was that only the tiles get treatment. With nothing painted outside them, those regions sit at alpha 0, below the blur cutoff, and the desktop is left genuinely untouched.
- **Shadows cast by a shape proxy, not by live captures.** `MultiEffect` renders its source, and `liveCapture` defaults true for every grid thumbnail. A shadow depends only on shape, so a plain rect gives an identical silhouette at fixed cost.
- **`QtQuick.Shapes` over `Qt5Compat.GraphicalEffects`.** `OpacityMask` would express the ring more directly, but `install.sh` does not provision `qt6-5compat` and a fresh system must render this surface.

## Deviations from Plan

### Amended criteria (6, each recorded in-plan with its reason)

1. **T-16-31's proxy grep** — `grep -c 'Hyprland.dispatch'` counted *every* dispatch, not every *move* dispatch, so the empty-workspace fix tripped it 1→3 while the mitigation was untouched. Now counts `hl.dsp.window.move`. The mitigation itself is unchanged and still verified.
2. **Mode-indicator grep** — matched comment prose rather than the rendered string; unsound before this plan touched it.
3. **Mode-pill copy** — stable stem plus appended suffix, replacing a full-string swap that read as a glitch.
4. **Down-descends truth** — superseded, see Decisions.
5. **Wrap truths (×2)** — edge-stop, per the plan's own pre-authorised fallback.

### The costly one: five rounds spent on a phantom

`hyprctl reload` **does not apply layer-rule changes** on this build. The Lua parser rejects `hyprctl keyword` outright and drops reload edits silently — no error, clean `hyprctl configerrors`. Blur enabled in round 5 never reached the compositor, so rounds 6, 8 and 9 tuned `scrimOpacity` and tile fills against a cutoff that did not exist, each adjustment making the QML worse to compensate. What was approved as "frost" in round 5 was a colour tint; removing it in round 6 revealed there had never been a frost.

Broken by screenshotting the live surface instead of reasoning about it: `hyprctl eval '<rule>'` → frost appears, `hyprctl reload` → frost gone. Recorded at the rule, cross-referenced from both QML values that depend on it, and saved as a memory. **Config-file rules still apply correctly at startup, so a fresh session needs nothing.**

Secondary lesson, same root: an alpha cutoff cannot separate two regions that share an alpha. Removing the tile fill made a tile's interior alpha-identical to the scrim, after which only "nothing frosts" or "everything frosts" were reachable. Removing the scrim — not retuning it — was the answer.

### Scope beyond this plan

Rounds 11–13 revised grid *visual design* (tile chrome, thumbnail elevation, the scrim), which belongs to plans 16-01/16-02/16-03 and re-opens surfaces their gates approved. Done at the operator's explicit direction and recorded rather than hidden.

---

**Total deviations:** 6 criteria amended, 1 recorded decision superseded (D-16-06), 1 pre-authorised fallback taken (edge-stop), 1 scope extension into earlier plans' surfaces.

## Verification

- `motion-lint` 129/129, `waybar-design-lint` 32/32, `qmllint` clean, no literal hex, lua parses
- `ScreencopyView` count still 1 directory-wide (Task 1 criterion)
- Move-dispatch construction count still 1 (T-16-31)
- Type-to-search boundary: zero hits across the module tree
- Frost, sweep ring, elevation and untouched-desktop behaviour confirmed by screenshots of the live surface
- Render gate **approved** by the operator, D-16-17 fallback explicitly declined
