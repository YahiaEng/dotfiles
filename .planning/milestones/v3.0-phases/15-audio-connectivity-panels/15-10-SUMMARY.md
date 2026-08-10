---
phase: 15-audio-connectivity-panels
plan: 10
subsystem: ui
tags: [quickshell, qml, gradientborder, hyprland-parity, gap-closure]

requires:
  - phase: 14-dashboard-drawer
    provides: "GradientBorder.qml (DASH-10) — the animated gradient rim component, previously wired only to Dashboard.qml"
  - phase: 15-audio-connectivity-panels
    provides: "PanelDialog.qml (15-02/15-03) — the shared frame all three panels (audio/wifi/bluetooth) are constructed from"
provides:
  - "Design.borderWidth — the single home for Hyprland's general:border_size parity number, read by both Dashboard.qml and PanelDialog.qml"
  - "GradientBorder instantiated inside PanelDialog.qml, giving all three panels the drawer's animated gradient rim with zero panel call-site changes"
affects: [16-workspace-overview]

actuals:
  tokens: 1560
  tasks: 3
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Shared-frame component reuse: a component consumed by exactly one summonable-layer-surface (Dashboard.qml) is added to the single shared frame (PanelDialog.qml) other surfaces are constructed from, reaching every consumer with one insertion and zero call-site changes"
    - "Cross-file parity constant hoisted to the one directory-level singleton (Design.qml) reachable from every consumer, rather than duplicated per-file"

key-files:
  created: []
  modified:
    - quickshell/.config/quickshell/modules/dashboard/Design.qml
    - quickshell/.config/quickshell/modules/Dashboard.qml
    - quickshell/.config/quickshell/modules/dashboard/PanelDialog.qml

key-decisions:
  - "Design.qml is the single home for Design.borderWidth (Hyprland's general:border_size parity number) — Dashboard.qml repointed onto it, PanelDialog.qml reads the same constant. Not duplicated per-file."
  - "GradientBorder declared in PanelDialog.qml between background and content, byte-for-byte the same child-order position Dashboard.qml:387 already uses, radii mirrored from the same panelWindow.cornerRadius the background Rectangle uses"
  - "Negative control used visible: false, not the plan's literal active: false — GradientBorder.qml's active property only gates the rotation NumberAnimation (GradientBorder.qml:99,197), not the Shape's visibility, so active: false would have left a static (non-rotating) rim rendered rather than producing a genuine bare-surface control"
  - "Saturated-pixel discrimination threshold computed dynamically per active theme (surface HLS-S + half the gap to the palette's least-saturated gradient stop) rather than a fixed constant — a flat 0.35 threshold silently produced a false '0 pixels' reading under Nord's more muted palette (stops at 0.20-0.43 HLS-S vs Dracula's 0.89-1.0), which would have misread a real re-theme as a regression"

patterns-established:
  - "Per-theme dynamic saturation threshold for any future rim/gradient pixel-presence proof — a fixed global threshold breaks across palettes with materially different token saturation"

requirements-completed: [PANEL-06]

coverage:
  - id: D1
    description: "Design.borderWidth exists as the single home for Hyprland's general:border_size parity number; Dashboard.qml reads it instead of a local literal; drawer rim proven visually unchanged"
    requirement: "PANEL-06"
    verification:
      - kind: automated_ui
        ref: "hyprctl getoption general:border_size == Design.borderWidth (3==3); drawer rim before/after crop AE=394.74/45000px, under 400px animation-phase tolerance"
        status: pass
    human_judgment: false
  - id: D2
    description: "GradientBorder instantiated exactly once in PanelDialog.qml, positioned between background and content, reading Design.borderWidth and panelWindow.cornerRadius; zero panel call-site changes (AudioPanel/WifiPanel/BluetoothPanel byte-unchanged); all three panels mount/dismiss cleanly with no new log errors"
    requirement: "PANEL-06"
    verification:
      - kind: automated_ui
        ref: "source-level grep/awk assertions (exactly 1 GradientBorder, correct child order, mirrored radii, zero panel file diffs) + live IPC mount/dismiss of audio/wifi/bluetooth with clean quickshell.log"
        status: pass
    human_judgment: false
  - id: D3
    description: "All three panels render saturated rim pixels at their bottom-left corner (measured, with a working negative control); the rim re-themes on a theme switch (hue measurably changes) and holds still at the off motion scale; theme and motion-scale state restored to baseline"
    requirement: "PANEL-06"
    verification:
      - kind: automated_ui
        ref: "per-panel saturated-pixel counts (audio=1284, wifi=1282, bluetooth=1284 of 45000, dynamic per-theme threshold); negative control (visible:false) = 0; theme switch dracula->nord hue 314.2deg->134.2deg, restored to dracula; motion-scale off two captures ~1s apart AE=23.9/45000 at 5% fuzz (dithering-level noise, not rotation), restored to lively"
        status: pass
      - kind: manual_procedural
        ref: "human-check: open each panel + the drawer (Super+D), confirm by eye the rim reads as the SAME treatment (thickness/colours/rotation speed/corner tracing)"
        status: unknown
    human_judgment: true
    rationale: "The plan's own <verify> block requires a human-check step the automated saturation gate cannot make (it proves a rim exists, not that it visually matches the drawer's treatment) — not yet performed by a human at authoring time"

duration: ~45min
completed: 2026-08-02
status: complete
---

# Phase 15 Plan 10: PanelDialog GradientBorder Summary

**Closed gap G-15-1b by hoisting Hyprland's border-width parity constant into Design.qml and instantiating the existing GradientBorder component inside PanelDialog.qml — one shared-frame insertion gives all three panels (audio, wifi, bluetooth) the dashboard drawer's animated gradient rim with zero panel call-site changes.**

## Performance

- **Duration:** ~45 min
- **Completed:** 2026-08-02
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments
- `Design.borderWidth` is now the single home for Hyprland's `general:border_size` parity number (measured live: 3), read by both `Dashboard.qml` and the new `PanelDialog.qml` consumer
- `GradientBorder` instantiated inside `PanelDialog.qml` between `background` and `content` — all three panels (`AudioPanel.qml`, `WifiPanel.qml`, `BluetoothPanel.qml`) inherit the rim with **zero** call-site changes
- Live-measured proof: the rim renders saturated pixels at all three panels' bottom-left corners (a working negative control proved the check can genuinely fail), re-themes on a live theme switch (rim hue 314.2° → 134.2° across dracula→nord), and holds still at the `off` motion scale
- Drawer's own rim proven visually unchanged before/after the constant hoist (394.74/45000 differing pixels, under the 400px animation-phase tolerance)

## Task Commits

Each task was committed atomically:

1. **Task 1: Hoist the Hyprland border-width parity constant into Design.qml** - `2de0a7f` (feat)
2. **Task 2: Instantiate GradientBorder inside PanelDialog.qml** - `4f48847` (feat)
3. **Task 3: Prove the rim actually renders on all three panels, re-themes, and respects motion scale** - no commit (verification-only task; the negative-control edit used for the proof was reverted before commit, leaving zero net diff)

## Files Created/Modified
- `quickshell/.config/quickshell/modules/dashboard/Design.qml` - added `borderWidth` constant (Hyprland `general:border_size` parity, provenance comment)
- `quickshell/.config/quickshell/modules/Dashboard.qml` - repointed `borderWidth` to read `Design.borderWidth` instead of its own literal
- `quickshell/.config/quickshell/modules/dashboard/PanelDialog.qml` - added `borderWidth: Design.borderWidth` constant and a `GradientBorder` instance between `background` and `content`

## Decisions Made

- **Design.qml as the single home for `borderWidth`.** Resolved the plan's own open judgment call: hoisting into `Design.qml` (not restating a second literal in `PanelDialog.qml`, not relying on `GradientBorder`'s own default) is the only location both `Dashboard.qml` and `PanelDialog.qml` can already read by name.
- **Negative control used `visible: false`, not the plan's literal `active: false`.** Discovered live that `GradientBorder.qml`'s `active` property (lines 99, 197) only gates the rotation `NumberAnimation` — it does not hide the `Shape`. Setting `active: false` would have left a static, non-rotating rim fully visible, which is not a bare-surface control. Substituted `visible: false`, which genuinely hides the rim (0 saturated pixels measured vs. 1282-1284 with the rim visible), then reverted before commit. This is a Rule 1 (bug in the plan's literal instruction, not the code) auto-fix — the underlying claim ("prove the check can fail") is fully honored, just via the property that actually controls visibility.
- **Per-theme dynamic saturation threshold**, not a fixed constant. A flat HLS-saturation threshold of 0.35 (calibrated against Dracula's own highly saturated stops, 0.89-1.0) produced a **false negative** (0 saturated pixels) when the theme was switched to Nord, whose gradient stops are far more muted (0.20-0.43 HLS-S) by design. Replaced with a threshold computed per-theme from `palette.json` (`surface_saturation + (min_stop_saturation - surface_saturation) * 0.5`), which correctly discriminated the Nord-themed rim (1398/45000 saturated pixels) from its own surface. Documented as a reusable pattern for any future rim/gradient pixel-presence proof.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug in plan instruction] Negative control used `visible: false` instead of the plan's literal `active: false`**
- **Found during:** Task 3 (negative-control capture)
- **Issue:** The plan instructed setting `GradientBorder`'s `active` property to `false` to produce a bare-surface negative control. Live inspection of `GradientBorder.qml` (lines 99, 197) showed `active` only gates the `NumberAnimation on angle` — the rim's rotation — not the `Shape`'s visibility. A static, non-rotating rim is still a rim; the negative control would not have proven the check can fail.
- **Fix:** Used `visible: false` instead, which genuinely hides the rim. Captured the negative-control crop (0 saturated pixels, wifi panel), then reverted the change and confirmed `git diff` was empty before proceeding.
- **Files modified:** `quickshell/.config/quickshell/modules/dashboard/PanelDialog.qml` (transient, reverted — zero net diff, no separate commit)
- **Verification:** `git diff` empty after revert; quickshell restarted detached and all three panels re-verified mounting cleanly on the reverted (committed) file
- **Committed in:** N/A (transient edit reverted before commit; no code change persisted)

**2. [Rule 1 - Bug in measurement methodology] Fixed saturation threshold produced a false negative under Nord's palette**
- **Found during:** Task 3 (theme-switch re-theme proof)
- **Issue:** A flat HLS-saturation threshold of 0.35 (which correctly discriminated Dracula's rim from its surface) returned 0 saturated pixels for the same rim rendered under Nord, whose stops (0.20-0.43 HLS-S) are far more muted than Dracula's (0.89-1.0). This would have been misread as the rim failing to re-theme, when in fact the rim was rendering correctly with a lower-saturation palette.
- **Fix:** Computed the threshold dynamically per active theme from live `palette.json` values (`surface_saturation + (min_stop_saturation - surface_saturation) * 0.5`). Re-measured: Dracula rim 1282-1284/45000 across all three panels (threshold 0.522), Nord rim after the switch 1398/45000 (threshold 0.183) — hue measurably shifted 314.2°→134.2°, confirming the re-theme behaves correctly.
- **Files modified:** None (measurement-only; scratchpad Python helper script)
- **Verification:** Both dracula and nord captures show consistent ~2.85-3.1% saturated-pixel fractions relative to each theme's own token saturation, and the negative control (0 pixels) remains a clean floor under both.
- **Committed in:** N/A (verification methodology, no repo file changed)

---

**Total deviations:** 2 auto-fixed (both Rule 1 — the plan's own literal instructions for the verification methodology were technically imprecise; neither affected the shipped code, which matches the plan's `<the_open_judgment_call_resolved>` and task actions exactly)
**Impact on plan:** No scope creep, no shipped-code changes beyond what the plan specified. Both fixes were internal to how Task 3's proof was measured, not to what was built in Tasks 1-2.

## Issues Encountered

- **quickshell detached-restart intermittency.** Several `setsid uwsm app -- quickshell-launch.sh & disown` invocations issued together with other shell commands in the same tool call silently failed to leave a process running (exit code 144, no `quickshell -p` process found afterward), matching the standing 14-06/15-02/15-03 note that a shell-child restart can die with the executor's own session. Worked around by issuing the detached-launch command in its own isolated tool call, then checking `pgrep` in a separate subsequent call — this pattern succeeded every time. Carried forward as a refinement to the standing rule for any future plan's verification restarts: issue the detached launch in isolation, not chained with other commands in the same call.
- **hypr-equivalence-check's pre-existing `binds.json` divergence** surfaced in the final `theme-doctor` gate run (`[FAIL] hypr-equivalence-check: binds.json: differs from baseline`). This is the already-documented, accepted divergence from 13.1-08/13.1-10 (two `bindm` mouse-field records) — pre-existing, unrelated to this plan's changes, and out of this plan's scope per the scope-boundary rule. Not fixed here.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- G-15-1b is closed: all three Phase 15 panels now carry the drawer's animated gradient border, delivered by one shared-frame insertion with zero panel call-site changes, and the drawer's own rim is provably unchanged.
- The final human-check item in the plan's `<verify>` (open each panel plus the drawer via Super+D and confirm by eye the rim reads as the same treatment) has not yet been performed by a human — flagged in the `coverage` block (`D3`, `human_judgment: true`) for `verify-work`/UAT to route to a human rather than auto-pass.
- No blockers for Phase 15's remaining gap-closure plans (15-11..15-14).

---
*Phase: 15-audio-connectivity-panels*
*Completed: 2026-08-02*

## Self-Check: PASSED

- FOUND: `quickshell/.config/quickshell/modules/dashboard/Design.qml`
- FOUND: `quickshell/.config/quickshell/modules/Dashboard.qml`
- FOUND: `quickshell/.config/quickshell/modules/dashboard/PanelDialog.qml`
- FOUND: `.planning/phases/15-audio-connectivity-panels/15-10-SUMMARY.md`
- FOUND commit: `2de0a7f` (Task 1)
- FOUND commit: `4f48847` (Task 2)
