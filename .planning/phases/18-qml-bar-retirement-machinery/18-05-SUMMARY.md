---
phase: 18-qml-bar-retirement-machinery
plan: 05
subsystem: ui
tags: [quickshell, qml, wlr-layer-shell, hyprland, panelwindow, orientation, filview, grid-positioner]

# Dependency graph
requires:
  - phase: 18-01
    provides: "Bar.qml PanelWindow root, quickshell-bar namespace, corrected exclusiveZone/margins.top arithmetic (46px horizontal), Design.qml bar tokens"
provides:
  - "BarEntryModel.qml — the single entry list QBAR-02 requires: one ordered six-capsule array, every capsule carrying both a horizontal and a vertical zone (D-18-13)"
  - "BarCapsule.qml — the shared capsule chrome every capsule slot is built from"
  - "Six pre-declared capsule slot types (LauncherCapsule/SystemCapsule/WorkspaceCapsule/MediaConnectivityCapsule/ClockActionsCapsule/TrayCapsule), five empty and one (clock) carrying 18-01's live clock intact"
  - "modules/bar/qmldir — frozen manifest for wave 3 (18-08..18-11)"
  - "Bar.qml orientation-driven root: one BarEntryModel.isVertical value drives anchors/margins/extent/exclusiveZone, three zone containers, two summon seams"
  - "shell.qml bar wiring: five backend handles, guarded summon routing, three permanently-widened backend gates"
  - "~/.local/state/quickshell/bar-orientation — the read-only orientation config contract, write side owned by 18-11"
affects: [18-08, 18-09, 18-10, 18-11, 18-13, 18-14, 18-15, 18-16, 18-17, 18-18, 18-19]

# Actuals (#2632)
actuals:
  tokens: 12987
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "One entry-list singleton (BarEntryModel) carrying a per-entry zone object with BOTH horizontal and vertical keys, rather than two parallel arrangement arrays — orientation becomes a property read by shared rendering code, not a forked layout"
    - "One bound Grid positioner (rows/columns both ternaried on a single boolean) reused at every axis-swap site — the root's three zone containers AND BarCapsule's own internal content grid — so a Row/Column sibling pair (the forked-arrangement failure in miniature) never appears"
    - "PanelWindow's own anchors.{top,left,right,bottom} are plain bool properties, NOT QtQuick's AnchorLine-typed Item.anchors — the undefined-clears-an-anchor idiom does not apply to them; live-verified via a reload warning this task, use a direct boolean ternary instead"
    - "Backend handles threaded through the shared chrome (BarCapsule) rather than per-capsule, so all five (audioBackend/mediaBackend/systemResources/wifiBackend/bluetoothBackend) are bound once at the root and inherited — a wave-3 plan discovering a backend need never edits Bar.qml"

key-files:
  created:
    - quickshell/.config/quickshell/modules/bar/qmldir
    - quickshell/.config/quickshell/modules/bar/BarEntryModel.qml
    - quickshell/.config/quickshell/modules/bar/BarCapsule.qml
    - quickshell/.config/quickshell/modules/bar/LauncherCapsule.qml
    - quickshell/.config/quickshell/modules/bar/SystemCapsule.qml
    - quickshell/.config/quickshell/modules/bar/WorkspaceCapsule.qml
    - quickshell/.config/quickshell/modules/bar/MediaConnectivityCapsule.qml
    - quickshell/.config/quickshell/modules/bar/ClockActionsCapsule.qml
    - quickshell/.config/quickshell/modules/bar/TrayCapsule.qml
  modified:
    - quickshell/.config/quickshell/modules/Bar.qml
    - quickshell/.config/quickshell/modules/dashboard/Design.qml
    - quickshell/.config/quickshell/shell.qml

key-decisions:
  - "exclusiveZone is the surface's own content extent ALONE (Design.barHeight / Design.barColumnWidth), never plus Design.barEdgeMargin — live-measured correction of this plan's own written Task 3 action text, which had reintroduced 18-01's already-fixed double-margin bug verbatim. Corrected before commit; documented in full below."
  - "PanelWindow root anchors (top/left/right/bottom) are bool, not AnchorLine — use a plain boolean ternary, not the undefined-clears-an-anchor idiom this plan's own interface_context describes for the zone containers (which ARE real Item anchors and do use that idiom correctly)."
  - "BarEntryModel.qml needs `import Quickshell.Io` for FileView and ClockActionsCapsule.qml needs `import Quickshell` for SystemClock — both omitted from the plan's own stated import lists; added after a live quickshell reload surfaced the load errors."
  - "The `workspaces` and `tray` capsules each have exactly one entry sharing the capsule's own id (`entries: workspaces` / `entries: tray`, per the plan's own explicit array specification) — the plan's acceptance-criteria text asserting each capsule id string appears exactly once is therefore unsatisfiable for those two ids; implemented per the plan's semantic array spec (which the automated <verify> script does NOT contradict) and documented as a stale/self-contradictory acceptance-criteria text issue, mirroring 18-01-SUMMARY.md's own Deviation #2 precedent."

patterns-established:
  - "Live reload as the correctness oracle for layer-shell geometry: every exclusiveZone/margin formula in this file was proven against hyprctl monitors -j rather than trusted from source text, exactly as 18-01 established — this plan found and fixed a second instance of the identical double-margin bug class using the same method."

requirements-completed: [QBAR-02]

coverage:
  - id: D1
    description: "Exactly one entry list exists (BarEntryModel.capsules): one ordered six-capsule array, every capsule carrying both a horizontal and a vertical zone key (D-18-13) — no second arrangement array anywhere"
    requirement: "QBAR-02"
    verification:
      - kind: other
        ref: "grep -cE '^\\s*readonly property var [A-Za-z]+: \\[' BarEntryModel.qml == 1; grep -c 'horizontal:' == 6; grep -c 'vertical:' == 6"
        status: pass
    human_judgment: false
  - id: D2
    description: "The capsule-to-capsule axis is one Grid positioner whose rows/columns are bound to the one orientation value at every axis-swap site (root's three zones, BarCapsule's own content grid) — no Row/Column sibling pair exists anywhere in modules/bar/ or Bar.qml"
    requirement: "QBAR-02"
    verification:
      - kind: other
        ref: "grep -cE '^\\s*(Row|Column) \\{' Bar.qml BarCapsule.qml == 0 (both files)"
        status: pass
    human_judgment: false
  - id: D3
    description: "Flipping ~/.local/state/quickshell/bar-orientation between horizontal and vertical re-lays the whole bar live, with no shell restart: reservation goes 46px (top) -> 50px (right) -> 46px (top), symmetric, with the quickshell-bar namespace staying registered throughout"
    requirement: "QBAR-02"
    verification:
      - kind: other
        ref: "hyprctl monitors -j | jq -c '[.[].reserved]' at each of three states, hyprctl layers -j namespace check — all four commands run live this session, see 'Live Reserved-Zone Readings' below"
        status: pass
    human_judgment: false
  - id: D4
    description: "All six capsule slots from D-18-10's locked split exist as registered types in modules/bar/qmldir, each rooted on the shared BarCapsule chrome, each naming its single owning wave-3 plan — so 18-08/09/10/11 can run in parallel with zero shared files"
    requirement: "QBAR-02"
    verification:
      - kind: other
        ref: "qmldir registration count == 7 (no singleton keyword on the six slots); each *Capsule.qml rooted on 'BarCapsule {' with no own Rectangle; grep -lE '18-0[89]|18-1[01]' across the five empty slots == 5 files"
        status: pass
    human_judgment: false
  - id: D5
    description: "The live clock survives its extraction into ClockActionsCapsule.qml: still SystemClock at Minutes precision, still HH:mm format, no repeating Timer, and Bar.qml itself carries none of the three"
    requirement: "QBAR-02"
    verification:
      - kind: other
        ref: "grep -c 'precision: SystemClock.Minutes' / 'HH:mm' ClockActionsCapsule.qml == 1 each; grep -cE 'SystemClock|HH:mm|clockCapsule' Bar.qml == 0"
        status: pass
    human_judgment: false
  - id: D6
    description: "The permanent-liveness charge (audio/media/resources) is declared from the one entry list's aggregates and named in source; wifi/bluetooth gates are deliberately untouched (byte-unchanged diff)"
    requirement: "QBAR-02"
    verification:
      - kind: other
        ref: "grep -cE 'barInstance\\.requires(Audio|Media|Resources)' shell.qml == 3; grep -cE 'barInstance\\.requires(Network|Bluetooth|Weather)' == 0; git diff wifiPanelLoader.active/bluetoothPanelLoader.active line count == 0"
        status: pass
    human_judgment: false
  - id: D7
    description: "D-18-31/GATE-02 human render gate: the flip moves the bar to the right edge with no restart, the clock re-stacks into the 44px column with nothing cut off, windows reflow off the right edge, and a live theme switch re-colours the capsule in both orientations with no magenta flash"
    verification: []
    human_judgment: true
    rationale: "Visual/perceptual judgment (pixel-level re-stack fit, window reflow, crossfade smoothness, absence of a magenta flash) requires a human render-gate pass per D-18-31/GATE-02 — deferred to the user per established project preference (identical to 18-01's own precedent). Logged as WINDOWS.md ledger entry 25 (unrun-verify) so it stays visible at ship time. All mechanically-verifiable halves of this same deliverable (reservation numbers, namespace persistence, no load errors) are separately covered and PASS under D3 above."

duration: ~35min
completed: 2026-08-11
status: complete
---

# Phase 18 Plan 05: Bar Orientation Architecture Summary

**One `BarEntryModel` singleton — a single ordered six-capsule array where every capsule carries BOTH a horizontal and a vertical zone — now drives `Bar.qml`'s every geometry binding through one bound `Grid` axis, live-proven on the host to flip the reservation 46px→50px→46px with no shell restart, while six pre-declared capsule slots (five empty, one carrying 18-01's clock intact) let wave 3 run in true parallel.**

## Performance

- **Duration:** ~35 min
- **Started:** 2026-08-11T00:00Z (approx, first task commit)
- **Completed:** 2026-08-11T00:35Z (approx)
- **Tasks:** 3 (all completed)
- **Files modified:** 12 (9 created, 3 modified)

## Accomplishments

- `BarEntryModel.qml` created as `pragma Singleton`: one ordered six-capsule array (`launcher`, `system`, `workspaces`, `mediaConnectivity`, `clockActions`, `tray`) in UI-SPEC's canonical group order, every capsule carrying both a `horizontal` and a `vertical` zone key; an allowlist-validated, live-reloading orientation read from `~/.local/state/quickshell/bar-orientation` (Probe.qml's plain-text `FileView` idiom, verbatim); a three-name zone vocabulary (`start`/`center`/`end`); five pure resolution functions with no sort anywhere; exactly three backend aggregates (`requiresResources`/`requiresMedia`/`requiresAudio`) with the network/bluetooth omission explained in source
- `BarCapsule.qml` created as the one shared chrome: full-pill radius on both axes (`vertical ? width / 2 : height / 2`), `Colours.surfaceVariant` at rest crossfading to `Colours.surface` on hover through `PanelDialog.qml`'s motion-gated `Behavior on color` (verbatim), one axis-bound content `Grid`, a visibility rule that drops an empty capsule and its spacing from the layout with zero extra code, and the five backend handles (`audioBackend`/`mediaBackend`/`systemResources`/`wifiBackend`/`bluetoothBackend`) that keep wave 3 off `Bar.qml`
- All six capsule slots created, registered in `modules/bar/qmldir` (frozen for wave 3, mirroring the 14-03 precedent), five structurally complete but deliberately empty (no fabricated content), `ClockActionsCapsule.qml` carrying 18-01's live `SystemClock`-driven clock intact plus D-18-14's two-stacked-line vertical form
- `Bar.qml` rewritten as the orientation-driven root: `readonly property bool vertical: BarEntryModel.isVertical` drives every anchor, margin, extent and `exclusiveZone` binding; three zone containers (`startZone`/`centerZone`/`endZone`), each a `Repeater` over `BarEntryModel.capsulesForZone(...)`, populate all six capsule slots exactly once with all five backend handles bound; exactly two summon seams (`panelRequested`/`dashboardRequested`), frozen for wave 3 and wave 6
- `shell.qml` wired: five backend instances bound into `barInstance`; `onPanelRequested` routed through the existing guarded `openPanel()` (never reimplemented); `onDashboardRequested` mirrors the dashboard's own summon shape; exactly three gates widened (`audioTruthNeeded`, `MediaBackend.drawerOpen`, `SystemResources.drawerOpen`) off the entry-list aggregates, with the always-on charge named in a comment block; `WifiBackend`/`BluetoothBackend` gates left byte-unchanged
- Live-proven on the real host, four `hyprctl monitors -j` readings (see table below): `[[0,46,0,0]]` horizontal (byte-identical to 18-01's recorded number), `[[0,0,50,0]]` vertical, back to `[[0,46,0,0]]` — the flip is symmetric, the `quickshell-bar` namespace stayed registered throughout, and the retired top bar was left exactly as found (`visible`)
- Found and fixed, live, a genuine re-introduction of 18-01's own already-fixed exclusiveZone double-margin bug — see Deviations

## Task Commits

Each task was committed atomically:

1. **Task 1: The one entry list — per-orientation zones, orientation config value, backend-requirement aggregates** — `2464ba3` (feat)
2. **Task 2: The shared capsule chrome and all six pre-declared slots** — `d5b041a` (feat)
3. **Task 3: One config value swaps the whole bar — orientation-driven root plus frozen shell.qml wiring** — `c3a2ab4` (feat)

**Plan metadata:** pending final commit (this SUMMARY + STATE.md + ROADMAP.md + REQUIREMENTS.md)

## Files Created/Modified

- `quickshell/.config/quickshell/modules/bar/qmldir` — new manifest, `module qs.modules.bar`, eight type declarations, frozen for wave 3
- `quickshell/.config/quickshell/modules/bar/BarEntryModel.qml` — new `singleton`, the one entry list
- `quickshell/.config/quickshell/modules/bar/BarCapsule.qml` — new, the shared capsule chrome
- `quickshell/.config/quickshell/modules/bar/LauncherCapsule.qml` — new, empty slot (owner 18-11)
- `quickshell/.config/quickshell/modules/bar/SystemCapsule.qml` — new, empty slot (owner 18-08)
- `quickshell/.config/quickshell/modules/bar/WorkspaceCapsule.qml` — new, empty slot (owner 18-09)
- `quickshell/.config/quickshell/modules/bar/MediaConnectivityCapsule.qml` — new, empty slot (owner 18-08)
- `quickshell/.config/quickshell/modules/bar/ClockActionsCapsule.qml` — new, carries 18-01's live clock (action entries owned by 18-11)
- `quickshell/.config/quickshell/modules/bar/TrayCapsule.qml` — new, empty slot (owner 18-10)
- `quickshell/.config/quickshell/modules/Bar.qml` — rewritten: orientation-driven root, three zone containers, six capsule slots, two summon seams
- `quickshell/.config/quickshell/modules/dashboard/Design.qml` — append-only, `barColumnWidth: 44`
- `quickshell/.config/quickshell/shell.qml` — bar backend wiring, three widened gates

## Decisions Made

- **exclusiveZone is the content extent alone, never plus the edge margin** — this plan's own Task 3 action text specified `vertical ? Design.barColumnWidth + Design.barEdgeMargin : Design.barHeight + Design.barEdgeMargin`, which reproduces 18-01's own already-fixed double-margin bug verbatim (Hyprland's total reservation is `margins.<edge> + exclusiveZone`; the margin already lives in `margins.top`/`.right`, so folding it into `exclusiveZone` too double-counts it). Live-measured this task (co-existing reading `[[0,98,0,0]]` instead of the expected `[[0,92,0,0]]` — the exact +6 double-margin signature) and corrected to `vertical ? Design.barColumnWidth : Design.barHeight` before committing. See Deviations for the full trail.
- **PanelWindow's root `anchors.{top,left,right,bottom}` are bool, not AnchorLine** — the plan's interface_context describes an "assigning `undefined` clears an anchor" idiom that is real and correct for genuine QtQuick `Item.anchors` (used correctly below for the three zone containers), but does NOT apply to `PanelWindow`'s own layer-shell edge-anchor booleans. Live-verified via a reload warning ("Unable to assign [undefined] to bool"); fixed with a plain boolean ternary.
- **Two missing imports found via live reload, not by inspection**: `Quickshell.Io` for `FileView` in `BarEntryModel.qml`, and `Quickshell` for `SystemClock` in `ClockActionsCapsule.qml`. Both omitted from the plan's own stated import lists for those files; added after the quickshell process's own hot-reload log surfaced "FileView is not a type" / "SystemClock is not a type" load errors.
- **`workspaces`/`tray` capsule entries intentionally share their capsule's own id** — per the plan's explicit array specification (`entries: workspaces` / `entries: tray`). This makes the plan's own acceptance-criteria grep ("`id: \"workspaces\"` appears exactly once") literally return 2 for those two ids; implemented per the semantically-correct array spec (which the plan's actual automated `<verify>` script does not test at this granularity) rather than distort the entry id away from what the plan explicitly names.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Re-corrected the exclusiveZone double-margin bug this plan's own action text reintroduced**

- **Found during:** Task 3, live reservation measurement
- **Issue:** Task 3's `<action>` text specified `exclusiveZone: barWindow.vertical ? Design.barColumnWidth + Design.barEdgeMargin : Design.barHeight + Design.barEdgeMargin`. This is exactly the double-margin bug 18-01's own Task 2 found and fixed (`margins.top` already carries `Design.barEdgeMargin`; Hyprland's own reservation total is `margins.<edge> + exclusiveZone`, so folding the margin into `exclusiveZone` too double-counts it). Live co-existing reading with this formula: `[[0,98,0,0]]` — 52px from this bar alone (46 waybar + 52), the same +6 double-margin signature 18-01 recorded originally.
- **Fix:** Changed `exclusiveZone` to `barWindow.vertical ? Design.barColumnWidth : Design.barHeight` — the surface's own content extent alone, matching 18-01's corrected formula exactly, generalised to the second axis.
- **Files modified:** `quickshell/.config/quickshell/modules/Bar.qml`
- **Verification:** Re-measured live after the fix: `[[0,92,0,0]]` co-existing with the retired bar, `[[0,46,0,0]]` with it hidden-hard (byte-identical to 18-01's recorded number), `[[0,0,50,0]]` vertical, back to `[[0,46,0,0]]` on restoring horizontal.
- **Committed in:** `c3a2ab4`

**2. [Rule 1 - Bug] Added two missing imports found via live quickshell reload**

- **Found during:** Task 3, watching `~/.cache/quickshell.log` after each file save (per the task's own precondition/verification instructions)
- **Issue:** `BarEntryModel.qml` used `FileView` with only `import QtQuick` / `import Quickshell` — missing `import Quickshell.Io`, producing "FileView is not a type" and cascading "Type X unavailable" errors up through `BarCapsule.qml`, `LauncherCapsule.qml` and `Bar.qml`. `ClockActionsCapsule.qml` used `SystemClock` with only `import QtQuick` / `import "../dashboard"` — missing `import Quickshell`, producing "SystemClock is not a type".
- **Fix:** Added `import Quickshell.Io` to `BarEntryModel.qml` and `import Quickshell` to `ClockActionsCapsule.qml`.
- **Files modified:** `quickshell/.config/quickshell/modules/bar/BarEntryModel.qml`, `quickshell/.config/quickshell/modules/bar/ClockActionsCapsule.qml`
- **Verification:** Subsequent reload logged "Configuration Loaded" with no further errors for either file.
- **Committed in:** `c3a2ab4`

**3. [Rule 1 - Bug] PanelWindow root anchors are bool, not AnchorLine — undefined-clearing idiom does not apply**

- **Found during:** Task 3, live reload
- **Issue:** Root `anchors.left`/`anchors.bottom` were written as `condition ? true : undefined`, following the plan's interface_context note on "assigning undefined clears an anchor." `~/.cache/quickshell.log` logged `WARN scene: @modules/Bar.qml[64:9]: Unable to assign [undefined] to bool` — `PanelWindow`'s own layer-shell edge anchors are plain `bool` properties, not the `AnchorLine`-typed `Item.anchors` the undefined-clearing idiom actually applies to (correctly used, unmodified, for the three zone containers' real `Item.anchors` further down the same file).
- **Fix:** Changed to a direct boolean ternary: `left: !barWindow.vertical`, `bottom: barWindow.vertical`.
- **Files modified:** `quickshell/.config/quickshell/modules/Bar.qml`
- **Verification:** Subsequent reload showed no further "Unable to assign" warning; live reservation readings correct in both orientations.
- **Committed in:** `c3a2ab4`

---

**Total deviations:** 3 auto-fixed (all Rule 1 — bugs found via live quickshell reload/measurement, the same method 18-01 established as this file's correctness oracle).
**Impact on plan:** All three fixes were necessary for the surface to load and reserve space correctly at all; none is scope creep. The exclusiveZone fix in particular is load-bearing for every later bar plan, exactly as 18-01's original fix was.

## Issues Encountered

- A one-time, non-recurring QML console warning during the live horizontal→vertical flip: `WARN scene: QML Grid at @modules/Bar.qml[242:9]: Grid contains more visible items (5) than rows*columns (1)`. This did not recur on subsequent reads of the log and both the vertical (`[[0,0,50,0]]`) and horizontal-again (`[[0,46,0,0]]`) live readings came out exactly correct, so this reads as a transient binding-evaluation-order artifact of `Grid`'s `rows`/`columns` both being reactively rebound in the same tick during the axis flip, not a persistent defect. Flagged here for 18-13/18-14/18-19's GATE-02 pass to watch for during their own live orientation-flip testing, since a single-frame layout hiccup during the transition (as opposed to the settled end states, which are correct) is exactly the kind of thing a human render-gate pass would catch and this executor's automated tooling cannot.

## User Setup Required

None — no external service configuration required.

## Known Stubs

Five of the six capsule slots (`LauncherCapsule.qml`, `SystemCapsule.qml`, `WorkspaceCapsule.qml`, `MediaConnectivityCapsule.qml`, `TrayCapsule.qml`) are deliberately empty structural declarations — this is the plan's own stated intent (D-18-10's locked split, filled by wave 3), not an oversight. Each names its single owning plan (18-08/18-09/18-10/18-11) in its own header comment. No fabricated content exists in any of them — an empty `BarCapsule { capsuleId: "..." }` with no children, correctly rendering nothing via the shared chrome's own visibility rule.

## Next Phase Readiness

- `modules/bar/qmldir`, `Bar.qml` and `shell.qml`'s bar wiring are frozen for wave 3: 18-08, 18-09, 18-10 and 18-11 each fill exactly one capsule component file and none of them needs to touch any of these three files — a wave-3 plan that finds it needs an edit here has found an 18-05 scope correction, not a licence.
- The complete `BarEntryModel` public surface (capsule ids, entry ids per capsule, zone values per orientation, the three aggregates) is documented in full below for the four wave-3 executors to read as one authoritative list.
- **Outstanding:** the D-18-31/GATE-02 human render-gate visual pass (orientation flip smoothness, vertical clock re-stack fit, window reflow, theme-switch crossfade with no magenta flash) has NOT been performed by the executor — logged as WINDOWS.md ledger entry 25 (`unrun-verify`, phase 18), identical in kind to 18-01's own entry 24. This should be confirmed by the user before 18-19's GATE-02 parity pass is taken as final, though it does not block continuing to wave 3 (18-08 through 18-11).
- The one-time transient `Grid` warning noted in Issues Encountered is worth a specific look during that same future render-gate pass, though it self-resolved in every live reading taken this session.

## Live Reserved-Zone Readings (for 18-17's QBAR-12 and 18-19's GATE-02 to cite)

| Reading | Command | Result |
|---|---|---|
| Horizontal, retired bar hidden-hard (load-bearing) | `hyprctl monitors -j \| jq -c '[.[].reserved]'` after `~/.config/hypr/scripts/waybar-visibility.sh keybind toggle` | `[[0,46,0,0]]` — byte-identical to 18-01's recorded reading |
| Vertical, after `echo vertical > ~/.local/state/quickshell/bar-orientation` and file-watch settle | same command | `[[0,0,50,0]]` — right edge, 50px, one margin |
| Horizontal again, after `echo horizontal > ~/.local/state/quickshell/bar-orientation` | same command | `[[0,46,0,0]]` — symmetric, not a one-way transition |
| Restored, after a second `waybar-visibility.sh keybind toggle`; `status` prints `visible` | same command | `[[0,92,0,0]]` — co-existing total, matches 18-01's own recorded number |

No `hyprctl reload` and no `hyprctl eval` was run at any point in this plan, per the task's own prohibition (that half of QBAR-12 belongs to 18-17).

## BarEntryModel Public Surface (authoritative reference for wave 3)

**Orientation:** `orientationHorizontal` ("horizontal"), `orientationVertical` ("vertical"), `orientationStatePath` (`~/.local/state/quickshell/bar-orientation`), `orientation` (validated, defaults to horizontal), `isVertical` (bool).

**Zone vocabulary:** `zoneStart` ("start"), `zoneCenter` ("center"), `zoneEnd` ("end").

**Capsule ids, in declaration/render order:** `launcher` → `system` → `workspaces` → `mediaConnectivity` → `clockActions` → `tray`.

**Zone per capsule (horizontal / vertical):**
- `launcher`: start / start
- `system`: start / start
- `workspaces`: center / start
- `mediaConnectivity`: end / start
- `clockActions`: end / start
- `tray`: end / end

**Entry ids per capsule** (each entry: `{ id, backends: [...], textBearing: bool }`):
- `launcher`: `apps`
- `system`: `cpu`, `ram`, `disk`, `updates`
- `workspaces`: `workspaces`
- `mediaConnectivity`: `media`, `audio`, `network`, `bluetooth`, `battery`
- `clockActions`: `clock`, `gaming`, `notifications`, `idleInhibitor`, `settings`, `power`
- `tray`: `tray`

**Functions:** `capsulesForZone(zoneName)`, `zoneFor(capsuleId)`, `capsuleById(capsuleId)`, `entriesFor(capsuleId)`, `requiresBackend(backendName)`.

**Backend aggregates (exactly three):** `requiresResources`, `requiresMedia`, `requiresAudio`. Deliberately absent: any aggregate for network or bluetooth — those two backends' scanning/discovery gates must stay summon-only per D-15-15/D-15-18.

## Always-On Backend Charge (for 18-18's QBAR-11 soak)

Three backend gates widened from summon-gated to permanently-live by this plan, in `shell.qml`:
- `audioTruthNeeded` — was `dashboardLoader.active || audioPanelLoader.active`, now also `|| barInstance.requiresAudio`
- `MediaBackend.drawerOpen` — was `dashboardLoader.active`, now also `|| barInstance.requiresMedia`
- `SystemResources.drawerOpen` — was `dashboardLoader.active`, now also `|| barInstance.requiresResources`

Pre-widening baseline (18-BAR-IDLE-BASELINE.md, captured 18-01): RSS 445104 KiB, one `quickshell` process, zero child processes, zero `Timer` blocks. Since the bar's own entry list is complete as of this plan (even though five capsule bodies are still empty), all three aggregates are already `true` from this plan onward — the deliberate cost of pre-declaring the whole list one wave ahead of wave 3 filling it. `WifiBackend`/`BluetoothBackend` gates are byte-unchanged (git diff confirms zero touched lines on `wifiPanelLoader.active`/`bluetoothPanelLoader.active`).

## Freeze Notice (for every wave-3 executor)

`quickshell/.config/quickshell/modules/Bar.qml`, `quickshell/.config/quickshell/modules/bar/qmldir` and `shell.qml`'s bar wiring (the `Bar { id: barInstance ... }` block, the three widened gates) are **frozen for wave 3**. 18-08, 18-09, 18-10 and 18-11 each fill exactly one capsule component file (`SystemCapsule.qml`/`MediaConnectivityCapsule.qml`, `WorkspaceCapsule.qml`, `TrayCapsule.qml`, `LauncherCapsule.qml`/`ClockActionsCapsule.qml`'s action entries respectively) and none of them should need to touch any of the three frozen files. A wave-3 plan that finds it needs an edit to one of them has found an 18-05 scope correction, not a licence to edit in place.

---
*Phase: 18-qml-bar-retirement-machinery*
*Completed: 2026-08-11*

## Self-Check: PASSED

- FOUND: `quickshell/.config/quickshell/modules/bar/qmldir`
- FOUND: `quickshell/.config/quickshell/modules/bar/BarEntryModel.qml`
- FOUND: `quickshell/.config/quickshell/modules/bar/BarCapsule.qml`
- FOUND: `quickshell/.config/quickshell/modules/bar/LauncherCapsule.qml`
- FOUND: `quickshell/.config/quickshell/modules/bar/SystemCapsule.qml`
- FOUND: `quickshell/.config/quickshell/modules/bar/WorkspaceCapsule.qml`
- FOUND: `quickshell/.config/quickshell/modules/bar/MediaConnectivityCapsule.qml`
- FOUND: `quickshell/.config/quickshell/modules/bar/ClockActionsCapsule.qml`
- FOUND: `quickshell/.config/quickshell/modules/bar/TrayCapsule.qml`
- FOUND: `quickshell/.config/quickshell/modules/Bar.qml`
- FOUND: `quickshell/.config/quickshell/modules/dashboard/Design.qml`
- FOUND: `quickshell/.config/quickshell/shell.qml`
- FOUND commit: `2464ba3`
- FOUND commit: `d5b041a`
- FOUND commit: `c3a2ab4`
