---
phase: quick-260823-9ak
plan: 01
subsystem: ui
tags: [quickshell, qml, hyprland, layer-shell, wlr-layer-shell, edge-bar, caelestia]

requires:
  - phase: quick-260822-sht
    provides: the native QML launcher (Launcher.qml) this task branches
  - phase: 14
    provides: the dashboard drawer (Dashboard.qml) this task flares
provides:
  - AttachedCorner.qml — a reusable concave-flare component (fill + gradient-rim ribbon, no gradient-stroke property exists on this Qt build) for joining a panel's vertical side to the screen edge it hangs from
  - EdgeBar.qml — the always-on top/bottom strip type, with a static centre bulge and a hover-only reveal, instantiated twice
  - edgeBar.enabled Prefs key (default true) gating both strips and the launcher's direction
affects: [ui, quickshell-shell, launcher, dashboard, settings]

actuals:
  tokens: 13775
  tasks: 6
  commits: 6

tech-stack:
  added: []
  patterns:
    - "Concave (cove) flare geometry via SVG endpoint-to-centre formula (spec F.6.5), verified programmatically against an expected centre rather than hand-trusted sweep flags"
    - "Gradient rim rendered as a filled ribbon (outer+inner offset paths, one closed loop) rather than a stroked path — QtQuick.Shapes ShapePath has no gradient-stroke property on this Qt build"
    - "PendingRegion/Quickshell.Region mask to confine a layer surface's pointer input to a sub-rectangle (first use in this repo)"
    - "Per-instance LazyLoader (not a shared visible:false) so a Prefs-gated permanent surface fully unmounts, including its exclusiveZone, when disabled"

key-files:
  created:
    - quickshell/.config/quickshell/modules/dashboard/AttachedCorner.qml
    - quickshell/.config/quickshell/modules/EdgeBar.qml
    - hypr/.config/hypr/scripts/tests/quickshell-fixtures/compliant-bar-qml-root/EdgeBar.qml
  modified:
    - quickshell/.config/quickshell/modules/launcher/Launcher.qml
    - quickshell/.config/quickshell/modules/Dashboard.qml
    - quickshell/.config/quickshell/modules/Prefs.qml
    - quickshell/.config/quickshell/modules/settings/pages/BarPage.qml
    - quickshell/.config/quickshell/modules/dashboard/Design.qml
    - quickshell/.config/quickshell/modules/qmldir
    - quickshell/.config/quickshell/modules/dashboard/qmldir
    - quickshell/.config/quickshell/shell.qml
    - hypr/.config/hypr/scripts/quickshell-doctor

key-decisions:
  - "P-1 (additive corner, not a GradientBorder rewrite) held exactly as planned — AttachedCorner.qml is a wholly separate component"
  - "P-2 (flush margin in edge-bar mode, 10px untouched off) held, with an emergent detail: Hyprland's own reserved-zone avoidance (not a hardcoded offset) lands the launcher's flush edge exactly at the bottom strip's flat-run boundary"
  - "P-3 (bulge IS the hover target, no second surface) held exactly as planned"
  - "Deviation: moved Dashboard.qml's clip:true from panel down to content — panel's own clip would have silently hidden the new flares, which must paint outside panel's bounds"

patterns-established:
  - "AttachedCorner.qml is the shared concave-flare component for any future panel that needs to visually attach to a screen edge"

requirements-completed: [R1, R2, R3, R4, R5, R6, R7, R8, R9]

coverage:
  - id: D1
    description: "AttachedCorner.qml concave flare, proven on the launcher's top corners then reused unchanged on the dashboard's top corners and the launcher's bottom corners (Task 6)"
    requirement: "R7"
    verification:
      - kind: automated_ui
        ref: "grim region capture, pixel-verified tangent-continuous concave arcs at all four corner sites (launcher top, dashboard top, launcher bottom)"
        status: pass
    human_judgment: true
    rationale: "Geometry correctness was pixel-verified by the executor, but 'reads as smooth and not a hard step' is a taste/quality judgment the plan itself reserves for the operator (Task 7's own how-to-verify)"
  - id: D2
    description: "EdgeBar.qml — two always-on strips with a static centre bulge, correct reservation (flat thickness only, D-4), theme-driven colour (R9)"
    requirement: "R1, R4, R8, R9, D-3, D-4"
    verification:
      - kind: automated_ui
        ref: "hyprctl -j monitors reserved=[0,8,50,8]; pixel-measured region capture confirms 8px flat / 16px bulge depth across the centred ~240px width with smooth shoulder transitions"
        status: pass
      - kind: other
        ref: "quickshell-doctor bar-surface-registry + bar-reserved-zone-stability + --self-test, all 0 failed"
        status: pass
    human_judgment: false
  - id: D3
    description: "edgeBar.enabled settings toggle, default ON, OFF unmounts both strips entirely and reverts the launcher's direction"
    requirement: "R2, R3"
    verification:
      - kind: automated_ui
        ref: "live toggle via prefs IPC: reserved returns to [0,0,50,0] and hyprctl layers -j drops both baredge-* entries entirely (not merely hidden); settings screenshot shows the row with no first-paint flash"
        status: pass
    human_judgment: false
  - id: D4
    description: "Hover reveal on both bulges — dashboard from the top, launcher MENU mode from the bottom, dwelled, click-inert"
    requirement: "R5, R6"
    verification:
      - kind: other
        ref: "static gate: zero TapHandler/MouseArea/WheelHandler/DragHandler in EdgeBar.qml; shell log clean across restarts"
        status: pass
      - kind: manual_procedural
        ref: "actual hover-dwell interaction — no input-injection tool exists on this host and wtype misroutes to the focused window"
        status: unknown
    human_judgment: true
    rationale: "Hover/dwell/click-inert/fullscreen-blocking behavior cannot be exercised without real pointer input; Task 7 hands this to the operator per the plan's own carried caution"
  - id: D5
    description: "Launcher direction branches on edge-bar mode (bottom-anchored ON, top-anchored — byte-identical to pre-task — OFF); Dashboard.qml untouched"
    requirement: "R6, D-2, D-5"
    verification:
      - kind: automated_ui
        ref: "hyprctl layers -j: OFF reads y=10,h=1430 (unchanged from pre-Task-6); ON reads flush bottom edge; region captures show identical corner shape in both modes; git diff confirms zero changes to Dashboard.qml in this task"
        status: pass
    human_judgment: false

duration: multi-session (interrupted once, resumed with full state recovery)
completed: 2026-08-23
status: complete
---

# Quick Task 260823-9ak: Edge Bar Summary

**Caelestia-style always-on top/bottom edge bar with a static centre-bulge hover target, concave attachment flares shared by the dashboard and launcher, and a default-ON settings toggle that fully unmounts on disable — 6/7 tasks landed, Task 7 (operator sign-off) pending.**

## Performance

- **Duration:** multi-session (this session was interrupted mid-run by the parent process exiting after Task 2; resumed cleanly from git + working-tree state, Task 3's uncommitted work was re-verified before committing, per the coordinator's explicit instruction)
- **Tasks:** 6 of 7 completed and committed; Task 7 (`checkpoint:human-verify`, `gate="blocking-human"`) is prepared but NOT self-certified
- **Files modified:** 12 (3 created, 9 modified)
- **Commits:** 6, all pushed to `origin/main`

## Accomplishments

- `AttachedCorner.qml` — a reusable concave-flare component, proven first on the launcher (Task 1, tracer) then reused byte-identical on the dashboard (Task 2) and the launcher's bottom corners (Task 6). Renders as a filled ribbon with a rotating gradient rim that stays in phase with the host panel's own `GradientBorder` (reads its `startAngle + angle`).
- `EdgeBar.qml` — one `PanelWindow` type, instantiated twice (top/bottom) in `shell.qml`. A single continuous `Shape` outline (flat run + two concave shoulder fillets + a static centre bulge), reserving only its flat thickness (`Design.edgeBarThickness = 8`), with the bulge's extra depth (`Design.edgeBarBulgeExtra = 8`) deliberately overhanging unreserved territory.
- A `Quickshell.Region` mask (this repo's first use) confines pointer input to the bulge's own overhang rectangle; a `HoverHandler` + dwell `Timer` (`Design.edgeBarDwellMs = 400`) there — and nothing else, permanently — fires a `bulgeHoverTriggered()` signal the component itself never interprets.
- `edgeBar.enabled` Prefs key (default `true`) drives one `ToggleRow` on the Bar settings page and gates both `EdgeBar` instances behind per-instance `LazyLoader`s, so OFF destroys each `wl_surface` (and its `exclusiveZone`) rather than merely hiding it.
- The launcher's direction now branches on that same flag (threaded in as a property, since `Launcher.qml` cannot see `shell.qml`'s `root` id across files): bottom-anchored and flush when ON, top-anchored at the original 10px margin when OFF — with the corner **shape** never branching, only which edge it attaches to (D-5).

## Task Commits

1. **Task 1: AttachedCorner.qml — the concave flare, proven on the launcher** — `015ca199` (feat)
2. **Task 2: Apply the concave flare to the dashboard** — `bb9805bf` (feat)
3. **Task 3: EdgeBar.qml — the two always-on strips** — `cdbc054a` (feat)
4. **Task 4: The settings toggle** — `6b41ccfb` (feat)
5. **Task 5: Hover triggers on the two bulges** — `fbe5ca9f` (feat)
6. **Task 6: Branch the launcher's direction** — `724a42ef` (feat)

Task 7 (`checkpoint:human-verify`, `gate="blocking-human"`) is unrun by design — see "Task 7: what the operator must do" below. No docs/plan-metadata commit has been made; per this session's explicit instruction the orchestrator handles that commit.

## Files Created/Modified

- `quickshell/.config/quickshell/modules/dashboard/AttachedCorner.qml` — the concave-flare component (new)
- `quickshell/.config/quickshell/modules/EdgeBar.qml` — the edge-bar strip type (new)
- `hypr/.config/hypr/scripts/tests/quickshell-fixtures/compliant-bar-qml-root/EdgeBar.qml` — self-test fixture stub (new)
- `quickshell/.config/quickshell/modules/launcher/Launcher.qml` — flares wired in (Task 1), direction branch (Task 6)
- `quickshell/.config/quickshell/modules/Dashboard.qml` — flares wired in (Task 2); `clip: true` moved from `panel` to `content`
- `quickshell/.config/quickshell/modules/Prefs.qml` — `edgeBar.enabled` key
- `quickshell/.config/quickshell/modules/settings/pages/BarPage.qml` — the toggle row
- `quickshell/.config/quickshell/modules/dashboard/Design.qml` — 5 new tokens (`attachedCornerRadius`, `edgeBarThickness`, `edgeBarBulgeExtra`, `edgeBarBulgeWidth`, `edgeBarDwellMs`)
- `quickshell/.config/quickshell/modules/qmldir` / `modules/dashboard/qmldir` — type registrations
- `quickshell/.config/quickshell/shell.qml` — `root.edgeBarEnabled`, two gated `EdgeBar` instances, `dashboardShortcut.toggle()`, two `Connections` blocks wiring the hover signals
- `hypr/.config/hypr/scripts/quickshell-doctor` — one new `QSD_BAR_SURFACE_ROWS` row

## Decisions Made

- **P-1/P-2/P-3 (the planner's three flagged decisions) all held as planned**, with one emergent refinement to P-2 worth recording: the plan called for "margin 0" in edge-bar mode, and the code does exactly that (`margins.top`/`margins.bottom: 0`) — but the launcher's *actual* landed position is 8px above the true screen edge, because Hyprland's own layer-shell reserved-zone avoidance pushes any zero-margin, edge-anchored surface clear of *other* surfaces' `exclusiveZone` on that edge (the bottom `EdgeBar`'s own 8px reservation). The panel therefore lands flush against the strip's flat-run boundary, not the literal screen pixel — which reads as "flush against the strip" exactly as P-2 intended, achieved by the compositor rather than a hardcoded offset in `Launcher.qml`.
- **Deviation (Rule 1/3): moved `Dashboard.qml`'s `clip: true` from `panel` to `content`.** `panel`'s own clip would have silently hidden Task 2's `AttachedCorner` instances, which must paint outside `panel`'s bounds (R7/GT-7). The clip's original purpose (keeping the `SwipeView` pager's off-screen pages from rendering outside the drawer) is served identically by moving it one level down to `content`, the item that actually owns the pager — zero behavior change to the pager, unblocks the flares.
- **Sweep-flag arithmetic (AttachedCorner + EdgeBar shoulder fillets) is computed programmatically, not hand-trusted.** Both files derive the SVG endpoint-to-centre relation and compare the candidate centre against the geometrically-required one before picking `large-arc-flag`/`sweep-flag`, closing exactly the trap the plan's own header warned about ("the wrong flag produces a convex bulge that will look deliberate and be wrong"). Verified correct via pixel-level region-capture measurement (Task 3) and visual region captures (Tasks 1/2/6), not assumed from the math alone.
- **`launcherMenuShortcut._toggleMenu()` reused verbatim** for the bottom strip's hover signal (Task 5) rather than refactored, since it was already a named function; `dashboardShortcut` gained a matching `toggle()` function (a small, deliberate refactor, not a new code path) so the top strip's signal and the keybind share one path.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1/3] Dashboard.qml `clip: true` relocated from `panel` to `content`**
- **Found during:** Task 2 (applying the flare to the dashboard)
- **Issue:** `panel`'s own `clip: true` (added originally to keep the `SwipeView` pager's off-screen pages from rendering outside the drawer) would have silently clipped away the new `AttachedCorner` instances too, since they are siblings of `background` inside the same `panel` Item and must paint outside its bounds (R7/GT-7 explicitly requires this).
- **Fix:** Moved the `clip: true` line from `panel` down to `content` (the `Item` that actually wraps the header + `SwipeView` pager) — the pager's own clipping behavior is unchanged (still clipped to exactly its own bounds), and the flares are no longer inside the clipped region.
- **Files modified:** `quickshell/.config/quickshell/modules/Dashboard.qml`
- **Verification:** Restarted the shell, region-captured the dashboard's top corners, confirmed the flares render fully (not clipped) and the `SwipeView` pager still shows no off-screen-page bleed on tab switch.
- **Committed in:** `bb9805bf` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1/3, structural — necessary for the flares to render at all, no scope creep).
**Impact on plan:** None beyond the one file. Every other file matches the plan's own action text closely, including the exact geometry derivation the plan asked to be worked out and verified rather than assumed.

## Issues Encountered

- **Session interruption after Task 2.** The parent Claude Code process exited mid-Task-3. Recovery: git status/log were re-verified against the coordinator's own measured report before touching anything; Task 3's already-complete-but-uncommitted work (`EdgeBar.qml` + fixture + doctor row + Design tokens + qmldir + shell.qml mount) was re-verified from scratch (all five gates + a fresh restart + a pixel-level region-capture measurement of the strip geometry) before committing, per the explicit instruction not to assume the interrupted state was good. No rework was needed — Task 3's prior work was correct as found.
- **`hyprctl dispatch global <name>` does not work on this host's hyprctl** — this Hyprland build's dispatch string is itself Lua-evaluated (`hl.dispatch(...)`), and the working invocation is `hyprctl dispatch 'hl.dsp.global("quickshell:<name>")'`. Used throughout for opening the dashboard by keybind-equivalent path during self-verification; documented here since it is a genuinely surprising host quirk, not a repo defect.
- **The live monitor identity changed mid-session** (from a synthetic `FALLBACK` 1920×1080 headless output early in the session to the real `DP-1` 2560×1440 output later) — an initial region capture at stale 1920-wide coordinates produced a confusing, seemingly-wrong screenshot before this was noticed. Re-captured at the correct `DP-1` geometry (read fresh from `hyprctl monitors -j` each time) resolved it; all evidence in this SUMMARY is from the corrected captures.
- **`hyprctl activewindow -j` returns `{}`** for a layer-shell surface (dashboard/launcher have no "active window" in Hyprland's tiling sense), confirming `wtype` has no valid target here — used as direct evidence for why the interactive hover-dwell check (Task 5's own `<human-check>`) cannot be self-verified and must go to the operator.

## User Setup Required

None — no external service configuration required.

## IMPORTANT — live, uncommitted work found in the working tree at handoff

At the very end of this session, immediately before finalizing this SUMMARY, `git status`
revealed an UNCOMMITTED modification to `quickshell/.config/quickshell/modules/EdgeBar.qml`
that this executor did **not** make. Its own header comment identifies it as
"OPERATOR FEEDBACK ROUND 1, 2026-08-23", reporting the strip read as "completely black and
not color shifting" and replacing the flat `Colours.surface`-at-0.55-alpha fill (this
session's Task 3 implementation) with an opaque, scrolling three-stop accent gradient
(`Colours.primary/secondary/tertiary`, `ShapeGradient.RepeatSpread`, locked to the strip's
long axis rather than GradientBorder's rotating-endpoint technique, with a rationale for why
`GradientBorder` itself can't be dropped onto this file's non-rectangular outline).

The file's mtime (12:18:14, ~30 seconds before this SUMMARY's own final checks) and a burst of
live interaction log lines (`bar: visibility=hidden-hard`/`visible`, repeated `cascade: run`
entries for dashboard tabs and the power menu) in `~/.cache/quickshell.log` from the same
window strongly indicate the **human operator was live-editing and live-testing this file
directly, in real time, in parallel with this executor's own automated verification** — very
plausibly from the open `kitty` window titled "Edge bar feature for milestone 5" that was
present in `hyprctl clients -j` output throughout this session.

**This executor left the change completely untouched** — did not commit it, did not revert
it, did not overwrite it, and made no further edits to `EdgeBar.qml` or further shell restarts
after discovering it, per the standing rule that no uncommitted work is ever discarded without
the user's explicit instruction. It is worth noting this out loud: it means R9 ("follows the
shifting colour scheme") may already be getting a live, better-informed treatment than this
session's own Task 3 implementation, direct from the person who will judge it. Whoever reviews
this SUMMARY should check `git status` on `quickshell/.config/quickshell/modules/EdgeBar.qml`
before assuming Task 3's fill (`Colours.surface` at 0.55 alpha, as committed in `cdbc054a` and
described throughout this SUMMARY) is still what's running live.

## Task 7: what the operator must do

Task 7 (`checkpoint:human-verify`, `gate="blocking-human"`) was **not** self-certified, per this session's explicit instruction — no human input was available to the executor. Everything the task's own `<what-built>`/`<how-to-verify>` asked to gather in advance is recorded below.

### 1. Reservation proof (R3) — OFF is byte-identical to the pre-Task-3 baseline

| State | `hyprctl -j monitors` `reserved` (left, top, right, bottom) |
|---|---|
| Pre-Task-3 baseline (measured before EdgeBar existed) | `[0, 0, 50, 0]` |
| ON (default, after all 6 tasks) | `[0, 8, 50, 8]` |
| OFF (toggled live, shell restarted) | `[0, 0, 50, 0]` — **matches the baseline exactly** |
| ON again (restored) | `[0, 8, 50, 8]` |

Toggling live (no restart) via the `prefs` IPC also confirmed the binding updates immediately: `root.edgeBarEnabled` re-evaluates on `Prefs._data` reassignment, so both `LazyLoader`s unmount/remount without a restart. `hyprctl layers -j` with the toggle OFF shows **zero** `baredge-*` namespace entries — the surfaces are destroyed, not hidden.

### 2. D-2 proof — `Bar.qml` appears in no commit

```
git log aeabd482..HEAD --name-only --pretty=format: | grep -v '^$' | sort -u | grep -E '(^|/)Bar\.qml$'
```
returns nothing (exit 1 / no match) across all 6 task commits.

### 3. D-2 proof — both bar orientations verified

| Bar orientation | `reserved` array | EdgeBar layer geometry |
|---|---|---|
| vertical (this host's live default) | `[0, 8, 50, 8]` | top/bottom strips span `x:0..2510` (up to the vertical bar) |
| horizontal (switched via `bar-orientation.sh`, shell restarted) | `[0, 56, 0, 8]` | top/bottom strips span the **full** `x:0..2560` width, top strip sits at `y=48` (right below the horizontal bar's own 48px reservation) |
| back to vertical (restored) | `[0, 8, 50, 8]` | restored |

`quickshell-doctor` (0 failed, `bar-surface-registry` and `bar-reserved-zone-stability` both PASS) was re-run in the horizontal state and passed identically.

### 4. Full gate sweep (verbatim pass counts, run after all 6 tasks, edge bar ON, vertical orientation)

| Gate | Result |
|---|---|
| `quickshell-doctor` (no flags) | **28 passed, 0 failed** — `bar-surface-registry`: `source: rows=11 missing=0 unexpected-reservation=0 unregistered=0`, `live: permanent=1 off-level=0 wrong-pid=0 unmatched=0` |
| `quickshell-doctor --self-test` | **59 passed, 0 failed** |
| `colour-lint` | **359 passed, 0 failed** |
| `motion-lint` | **546 passed, 0 failed** |
| `keybind-doctor` | **13 passed, 0 failed**, exit 0 |
| `~/.cache/quickshell.log` below the last start marker | clean across every restart this session (no import/type/crash markers) |

### What these gates CANNOT see (stated honestly, per the plan's own instruction)

None of the five gates renders a pixel. They cannot confirm: the flare geometry reads as smoothly concave rather than a hard step; the rim gradient is genuinely in phase across the panel/flare seam to the eye; the bulge is centred and reads as a discoverable landmark at the right size; blur is genuinely alive behind the strip; or that the overall result reads like the Caelestia frame the operator asked for. The executor **did** self-verify these via `grim -g` region captures and pixel-level sampling (safe on this host per the carried caution) for every non-interactive surface, and is reasonably confident in the geometry's correctness — but final taste judgment on all four is explicitly the plan's own acceptance criterion, not a gate's.

**Additionally, and this is the part the executor genuinely could not check:** no input-injection tool exists on this host (`hyprctl activewindow -j` returns `{}` for these layer-shell surfaces, and `wtype` has no valid target to route to), so the actual hover-dwell interaction Task 5 built — dwell opens the surface, a fast sweep across the bulge does not, dismissing while still hovering does not immediately re-fire, the bottom edge opens MENU mode specifically, the strip is click-inert, and hovering does nothing while a client is fullscreen — has **never been exercised with a real pointer**. Only the static shape of the code (zero Tap/Mouse/Wheel/DragHandler in `EdgeBar.qml`, the `LauncherState.pendingMode` write present in `shell.qml`) has been verified.

### Present to the operator

The four region captures gathered this session, at `/tmp/claude-1000/-home-aorus-dotfiles/d1d95ea1-efaa-4837-89c4-9f2597551a77/scratchpad/task7-evidence/` (ephemeral — re-capture if this scratchpad has been cleared):
- `dashboard-top.png` — the dashboard's top attachment (edge bar ON)
- `launcher-bottom-on.png` — the launcher's bottom attachment (edge bar ON)
- `launcher-top-off.png` — the launcher's top attachment (edge bar OFF, for comparison — same corner shape, opposite edge)
- `bulge-top.png` — the top strip's centre bulge, close-up

### Ask the operator to confirm, in order

1. **Visual/taste (Task 7's own four):** the flares read as smooth concave flares, not hard steps; the bulge is a discoverable landmark at the right size; the strips re-colour correctly on a theme switch; the overall result reads like the Caelestia frame they asked for. **If any is a "no," it is a Design-token tuning round** (`edgeBarThickness`, `edgeBarBulgeExtra`, `edgeBarBulgeWidth`, `attachedCornerRadius` — all in `dashboard/Design.qml`, all single-line changes), not a redesign — unless the flare geometry itself is reported convex or the rim out-of-phase, which would be a Task 1 defect.
2. **The hover interaction, live, with a real pointer** (the one thing this session could not exercise): rest the pointer on the top-centre bulge and confirm the dashboard opens after a short dwell; sweep quickly across the top edge and confirm nothing opens; rest on the bottom-centre bulge and confirm the launcher opens in **menu mode** (not the app grid); dismiss either surface with the pointer still resting on the bulge and confirm it does not immediately reopen; click the bulge and confirm nothing happens at all; with a fullscreen client focused, confirm neither hover summons anything.

On "approved": R1–R9 and D-1..D-5 are all satisfied per the evidence above, and the phase is done — a docs commit and a push are all that remain (the orchestrator's own job, not this executor's).

On a named "no": treat it as the Design-token tuning round the plan itself anticipates, or — only if the flare geometry itself is wrong — reopen as a Task 1 defect.

---
*Phase: quick-260823-9ak*
*Completed: 2026-08-23*
