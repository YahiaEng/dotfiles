---
phase: 14-dashboard-drawer
plan: 01
subsystem: ui
tags: [quickshell, qml, hyprland, layer-shell, wayland, dashboard]

requires:
  - phase: 12-unified-design-token-pipeline
    provides: "Colours.qml/Motion.qml singletons the drawer reads for color and motion"
  - phase: 13.1-hyprland-lua-config-migration
    provides: "hl.dsp.* Lua dispatcher API and hl.layer_rule/hl.bind conventions the drawer's keybind/layer rules follow"
provides:
  - "quickshell-dashboard PanelWindow: locked 850x860 geometry, overlay layer, zero exclusive zone, bottom-rounded translucent surface"
  - "Super+D summon/dismiss path: shortcuts.json manifest, keybinds.lua bind, shell.qml LazyLoader+GlobalShortcut"
  - "quickshell-* family layer treatment (blur+ignore_alpha) plus quickshell-dashboard's own slide character rule"
  - "DASH-08 fullscreen refusal guard on ShellRoot (fullscreenBlocking property)"
  - "Drawer-family design constants (8dp spacing scale, four-role type scale) declared once on Dashboard.qml's root for 14-03..14-08 to read"
affects: [14-02, 14-03, 14-04, 14-05, 14-06, 14-07, 14-08, 14-09, phase-15, phase-16]

tech-stack:
  added: []
  patterns:
    - "quickshell-<surface> layer-shell namespace family, matched by an hl.layer_rule regex plus a per-surface exact-match fallback shipped in the same commit"
    - "LazyLoader (destroy-on-dismiss) + sibling GlobalShortcut, appid/name byte-matching a shortcuts.json manifest entry"
    - "HyprlandFocusGrab bound to the surface's own PanelWindow for click-outside + focus-loss dismiss"

key-files:
  created:
    - quickshell/.config/quickshell/modules/Dashboard.qml
  modified:
    - quickshell/.config/quickshell/modules/qmldir
    - quickshell/.config/quickshell/shell.qml
    - quickshell/.config/quickshell/shortcuts.json
    - hypr/.config/hypr/config/keybinds.lua
    - hypr/.config/hypr/config/windowrules.lua

key-decisions:
  - "A2 verdict (RESEARCH.md Open Question 2): regex-matches. hl.layer_rule's ^quickshell-.* regex namespace match DOES work on this Hyprland 0.56.1 build, proven via a live grim-captured A/B (family-arm-only shows blur; neither-arm shows no blur). Both the regex and the per-surface exact-match rules are kept as intentional redundancy."
  - "DASH-08 guard blocks BOTH maximize and true fullscreen, not just true fullscreen as D-11 literally specifies. Live-proven on this build: Hyprland exposes no signal anywhere in its IPC (client JSON fields, monitors reserved array, or raw socket2 events) to distinguish the two states — both report fullscreen:2 and both hide the bar identically. This is the closest achievable reading of D-11's own cited rationale (parity with waybar's existing fullscreen-withdraw behavior, which was independently proven this session to treat both states identically too)."
  - "Click-outside dismiss and dispatcher-driven focus-loss dismiss were proven only indirectly (no ydotool/wlrctl on this host, no passwordless sudo to install one). Esc dismiss and toggle dismiss were verified with real live input (wtype, dispatch toggling). A control test against the pre-existing quickshell-probe surface confirmed Dashboard.qml's HyprlandFocusGrab wiring is behaviorally identical to the already-shipped, human-verified-working pattern."

patterns-established:
  - "Drawer-root constants (spacingXs..Xl, fontDisplay/Heading/Body/Label, weightDisplay/Emphasis/Body, lineHeightTight/Normal, cornerRadius, drawerSurfaceOpacity, surfaceBase) declared once on Dashboard.qml's PanelWindow root — 14-03..14-08 read dashboardWindow.<constant> rather than re-declaring their own."

requirements-completed: [DASH-01, DASH-08]

coverage:
  - id: D1
    description: "Super+D summons a quickshell-dashboard overlay surface at locked 850x860 geometry, horizontally centred, flush below waybar, zero exclusive zone"
    requirement: "DASH-01"
    verification:
      - kind: automated_ui
        ref: "hyprctl -j layers after hyprctl dispatch 'hl.dsp.global(\"quickshell:dashboard\")' — w=850 h=860 y=46 x-center=1280 (monitor center), single entry at level 3"
        status: pass
      - kind: automated_ui
        ref: "hyprctl -j monitors reserved array byte-identical [[0,46,0,0]] before/during/after summon"
        status: pass
    human_judgment: false
  - id: D2
    description: "All four dismissal paths destroy the surface: Super+D toggle, Esc, click-outside, focus-loss"
    requirement: "DASH-01"
    verification:
      - kind: automated_ui
        ref: "toggle dismiss + Esc dismiss (via wtype -k Escape) both verified live, hyprctl -j layers length 0 after each"
        status: pass
      - kind: manual_procedural
        ref: "click-outside and dispatcher-driven focus-loss dismiss: no synthetic pointer-click tool available this session (no ydotool/wlrctl, no passwordless sudo); verified only by mechanical control-test parity against the pre-existing quickshell-probe surface, not a literal click"
        status: unknown
    human_judgment: true
    rationale: "A real pointer click outside the drawer, and the 'activates the window underneath in the same gesture' claim specifically, need genuine synthetic pointer input or a human hand — neither was available this session. Flag for end-of-phase human verification."
  - id: D3
    description: "Drawer surface is translucent over compositor blur, bottom-only rounded corners, no background scrim"
    requirement: "DASH-01"
    verification:
      - kind: automated_ui
        ref: "grim screenshot captures (family-arm-only vs neither-arm A/B) show blur present/absent as expected; no hex literal in Dashboard.qml"
        status: pass
    human_judgment: true
    rationale: "Corner rounding and 'reads correctly, nothing dimmed' are visual judgments — plan defers this to human_verify_mode end-of-phase, consistent with the phase's own render-gate convention."
  - id: D4
    description: "DASH-08: Super+D over a true-fullscreen client is a silent no-op; over a maximized window the plan specifies it should open normally, but this build cannot distinguish the two states"
    requirement: "DASH-08"
    verification:
      - kind: automated_ui
        ref: "hyprctl -j activewindow fullscreen/fullscreenClient recorded for normal(0)/maximized(2)/true-fullscreen(2); dashboard blocked in both maximized and true-fullscreen cases; swaync-client -c count unchanged across a blocked press; an already-open drawer dismisses even with fullscreen active behind it"
        status: pass
    human_judgment: true
    rationale: "The maximized-carve-out cannot be honored as literally specified (documented live finding); operator should confirm this tradeoff is acceptable at end-of-phase review."

duration: 35min
completed: 2026-07-29
status: complete
---

# Phase 14 Plan 01: Dashboard Drawer Tracer Summary

**Super+D end-to-end tracer: `quickshell-dashboard` layer-shell surface with locked 850x860 geometry, house blur/translucency treatment (A2 verdict: regex-matches), and a DASH-08 fullscreen guard that blocks on the only signal this Hyprland 0.56.1 build actually exposes.**

## Performance

- **Duration:** ~35 min
- **Started:** 2026-07-29T13:14:00+03:00 (approx)
- **Completed:** 2026-07-29T13:41:05+03:00
- **Tasks:** 3
- **Files modified:** 6 (1 created, 5 modified)

## Accomplishments
- Wired the whole DASH-01 path live on the real desktop: `shortcuts.json` → `keybinds.lua` → `shell.qml`'s `dashboardLoader`/`dashboardShortcut` → `Dashboard.qml`'s `PanelWindow` → `HyprlandFocusGrab` dismiss → destroy-on-dismiss, proven with `hyprctl -j layers`/`monitors` before every dismissal path and a grim screenshot.
- Settled 14-RESEARCH.md's Assumption A2 from a live observation (not a guess): the `^quickshell-.*` family regex layer rule DOES match on this Hyprland 0.56.1 build.
- Discovered and worked around a genuine build-specific limitation: "maximize" and "true fullscreen" are indistinguishable anywhere in Hyprland's IPC surface on this host, and implemented DASH-08's guard on the only achievable behavior, documented in full below.
- Live-caught and fixed a real bug (missing `import QtQml`) that took Quickshell down entirely for one restart cycle — caught and repaired within the same task before any acceptance check ran against it.

## Task Commits

Each task was committed atomically:

1. **Task 1: End-to-end "Super+D summons the drawer"** - `5a29e66` (feat)
2. **Task 2: House layer treatment — family rules, drawer slide, A2 verdict** - `80a1a51` (feat)
3. **Task 3: DASH-08 — silent refusal over TRUE fullscreen** - `9338470` (feat)

**Plan metadata:** (this commit, following)

## Files Created/Modified
- `quickshell/.config/quickshell/modules/Dashboard.qml` - New `PanelWindow` surface: locked geometry, `quickshell-dashboard` namespace, bottom-rounded translucent background, Esc dismiss, drawer-family spacing/typography constants, placeholder pane
- `quickshell/.config/quickshell/modules/qmldir` - `Dashboard 1.0 Dashboard.qml` registration
- `quickshell/.config/quickshell/shell.qml` - `dashboardLoader`/`dashboardShortcut`, `fullscreenBlocking` guard, `Connections` on `Hyprland.rawEvent`
- `quickshell/.config/quickshell/shortcuts.json` - Third manifest entry, `quickshell:dashboard` on SUPER+D
- `hypr/.config/hypr/config/keybinds.lua` - Super+D bind dispatching `quickshell:dashboard`
- `hypr/.config/hypr/config/windowrules.lua` - `quickshell-*` family blur/ignore_alpha rules, `quickshell-dashboard` exact-match fallback, `slide` character rule

## Decisions Made

1. **A2 verdict: regex-matches.** Live A/B (grim screenshots, three states: both arms / family-only / neither-arm) proves the `^quickshell-.*` family regex works on this build. Both arms kept — the exact-match rules are now documented redundancy, not a required fallback.

2. **DASH-08 guard blocks maximize AND true fullscreen (deviation from D-11's literal carve-out — see Deviations below for full evidence).** No implementation could honor "maximize does not block" as written, because Hyprland genuinely does not expose a distinguishing signal on this build.

3. **Placeholder-pane content stays exactly as the plan specifies** (`"Dashboard"` heading + tracer-slice caption, both `Colours.onSurface`) — Plan 14-03 replaces it wholesale.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Plan's `<automated>` verify commands use a broken dispatch syntax on this Lua-config Hyprland build**
- **Found during:** Task 1, first verification attempt
- **Issue:** The plan's verify blocks literally read `hyprctl dispatch global quickshell:dashboard`. On this Hyprland 0.56.1 Lua-config build, `hyprctl dispatch` treats everything after `dispatch` as a Lua expression fed to `hl.dispatch(...)` — this exact string form was already found broken and fixed in Phase 13.1 (`13.1-09-SUMMARY.md`: "`hyprctl dispatch global quickshell:probe` is rejected outright by the Lua-config compositor... Fixed to the Lua expression form"), but that fix was never propagated back into Phase 14's plan authoring, so all nine 14-0X-PLAN.md `<automated>` blocks still carry the stale, non-working form.
- **Fix:** Used the correct, already-established form throughout this session's live verification: `hyprctl dispatch 'hl.dsp.global("quickshell:dashboard")'` (same idiom `theme-stress-test` already uses). Same fix applies to `hyprctl dispatch fullscreen 0`-style calls in Task 3's verify block — used `hl.dsp.window.fullscreen(N)`.
- **Files modified:** none (verification-only; no plan file was edited as part of this plan's execution — flagging here for whoever picks up 14-02..14-09, whose verify blocks carry the same stale syntax)
- **Verification:** Every automated check in this SUMMARY was run with the corrected syntax and confirmed passing.
- **Committed in:** n/a (verification technique, not a code change)

**2. [Rule 1 - Bug] `shell.qml` missing `import QtQml` for `Connections`**
- **Found during:** Task 3, first restart after adding the `fullscreenBlocking` guard's `Connections` block
- **Issue:** `Connections is not a type` — Quickshell failed to load the entire shell config, taking down Quickshell (all three surfaces: probe, screencopy-probe, dashboard) for roughly one restart cycle on the live desktop.
- **Fix:** Added `import QtQml` (matching `Probe.qml`'s own import list, which already carries this for the same reason).
- **Files modified:** `quickshell/.config/quickshell/shell.qml`
- **Verification:** Restarted Quickshell, confirmed `Configuration Loaded` with no error, re-ran the full DASH-08 test sequence successfully afterward.
- **Committed in:** `9338470` (Task 3 commit — the fix landed in the same commit as the feature, since it was caught before the task's first successful test run)

---

**Total deviations:** 2 auto-fixed (2 bugs), plus 1 major documented finding (below) that changes DASH-08's real-world behavior from the locked decision's literal text.
**Impact on plan:** Both auto-fixes were necessary to reach a working, testable state; neither changed scope. The maximize/fullscreen finding below is the substantive one and needs operator awareness — it is not silently absorbed.

## Issues Encountered — Load-Bearing Live Finding

**"Maximize" and "true fullscreen" are indistinguishable anywhere in Hyprland's IPC on this build.** Exhaustively proven (three independent windows: a tiled Zen browser window, a tiled kitty window, and a genuinely floating kitty window; three independent signal sources) during Task 3:

1. **`hyprctl -j clients`/`activewindow` fields**: `hl.dsp.window.fullscreen(1)` ("maximize" per this repo's own `keybinds.lua` comment) and `hl.dsp.window.fullscreen(0)` ("true fullscreen") both resolve to `fullscreen: 2, fullscreenClient: 2` — the exact same values, on every window tested. A dedicated diff of the two full JSON client objects (`fs-max.json` vs `fs-full.json`) came back byte-identical.
2. **`hyprctl -j monitors`'s `reserved` array**: both dispatcher calls clear it to `[0,0,0,0]` (waybar's exclusive zone drops identically in both cases).
3. **Raw `socket2` IPC event stream** (captured live via a Python socket read, not assumed from docs): both dispatches emit the byte-identical `fullscreen>>1` / `closelayer>>waybar` / `openlayer>>waybar` sequence.

This directly falsifies `14-CONTEXT.md` D-11's premise ("maximized windows (bar visible) do not block") for this specific host/build — a maximized window on this desktop is not, in fact, bar-visible; it behaves identically to true fullscreen in every way Hyprland exposes. The three-state enum this plan's Task 3 was designed to record turned out to have only two distinguishable values, not three:

| State | `fullscreen` | `fullscreenClient` |
|---|---|---|
| Normal | 0 | 0 |
| Maximized (`fullscreen(1)`) | 2 | 2 |
| True fullscreen (`fullscreen(0)`) | 2 | 2 |

`fullscreenBlocking` was implemented as `(Hyprland.activeToplevel?.lastIpcObject?.fullscreen ?? 0) === 2` — the only value Hyprland ever reports for either "disturbing" state. This means Super+D is now silently refused whenever ANY window is maximized, not only when one is genuinely fullscreen. This is a deviation from D-11's literal text, evidenced above rather than assumed, and matches D-11's own cited rationale ("matches waybar's existing fullscreen-withdraw behavior") more faithfully than the literal text would — that existing waybar mechanism was independently proven this session (same socket2 capture) to treat maximize and fullscreen identically too, so this guard is not introducing a new asymmetry, it is inheriting an existing one.

**13.1-LUA-FINDINGS.md already flagged this exact ambiguity** (`hl.dsp.window.fullscreen(N)` entry): "NOT MECHANICALLY VERIFIABLE: distinguishing 'fullscreen' (arg 0) from 'maximize' (arg 1) requires more than one tiled window or a floating window to show a visible size difference... Compensating check: physically press Super+F and Super+Shift+F at the end-of-phase human verification." This plan's live testing (including a genuinely floating window, which that finding's own caveat suggested might show a difference) closes that open question with a definitive "no difference exists" — not merely "not yet verified."

**Recommended follow-up (not performed here, out of this plan's scope):** if a future Hyprland version or a different maximize invocation path ever produces a genuinely distinguishable state, `fullscreenBlocking`'s comparison is the single place to revisit.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- The phase's architectural spine (namespace scheme, layer posture, focus mechanics, lifecycle, geometry, drawer-family design constants) is committed and live-proven. Plans 14-03..14-09 can build tab content on `Dashboard.qml` without touching its surface scaffold.
- **Flag for operator review at end-of-phase human verification:** the DASH-08 maximize/fullscreen finding above changes real desktop behavior from what D-11 states — confirm this tradeoff is acceptable, or scope a future revisit if Hyprland ever exposes a distinguishing signal.
- **Flag for whoever plans/executes 14-02..14-09:** their `<automated>` verify blocks carry the same stale `hyprctl dispatch global quickshell:<name>` / `hyprctl dispatch fullscreen N` syntax already known-broken since Phase 13.1 (`13.1-09-SUMMARY.md`) — use `hyprctl dispatch 'hl.dsp.global("quickshell:<name>")'` / `hl.dsp.window.fullscreen(N)` instead.
- Click-outside dismiss with a genuine synthetic pointer click, and the "activates the window underneath in the same gesture" claim, were not independently re-provable this session (no `ydotool`/`wlrctl` installed, no passwordless `sudo` to install one). Esc and toggle dismiss are fully live-verified; click-outside is verified only by mechanical parity against the pre-existing, human-verified-working `quickshell-probe` surface. Recommend a real physical click test at the phase's end-of-phase human verification.

---
*Phase: 14-dashboard-drawer*
*Completed: 2026-07-29*

## Self-Check: PASSED

All 7 created/modified files confirmed present on disk; all 3 task commits (`5a29e66`, `80a1a51`, `9338470`) confirmed present in git history.
