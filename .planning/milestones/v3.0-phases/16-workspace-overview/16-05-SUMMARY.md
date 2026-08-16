---
phase: 16-workspace-overview
plan: 05
subsystem: ui
tags: [quickshell, qml, hyprland, wlr-layer-shell, screencopy, fault-injection]

# Dependency graph
requires:
  - phase: 16-workspace-overview
    provides: "16-02's mandatory patterns (Hyprland.refreshToplevels() on Component.onCompleted, constraintSize on every ScreencopyView) and 16-03's WindowThumbnail.qml as the single ScreencopyView instantiation seam this plan extends rather than duplicates"
  - phase: 16-workspace-overview
    provides: "16-04's honest finding that quickshell-doctor's overview-content-check (check 6) catches only the whole-grid blank-tile case, not per-delegate geometry collapse — carried forward as the reason this plan still leans on live IPC + screenshot evidence rather than the doctor check alone"
  - phase: 15-audio-connectivity-panels
    provides: "PanelDialog.qml's four-state (populated/pending/empty/failed) vocabulary and stateColour() role mapping, reused verbatim (not imported) as this plan's own state-to-colour source of truth"
provides:
  - "WindowThumbnail.qml's three-state capture machine (captureState: populated/pending/failed, readonly settled) — the general representation every later plan (16-06's drag ghost, 16-07's keyboard selection) observes without needing a second state mechanism"
  - "Overview.qml's allSettled aggregation and settleCeilingReached ceiling timer — the pattern any future whole-surface degraded-state catch in this shell should copy rather than re-derive"
  - "D-16-20's click parity fully closed: window-level click target (WorkspaceTile.qml's per-delegate MouseArea + windowActivated signal) wired to Overview.qml's activateWindow(), the exact mechanism plan 16-07's Enter-on-selected-window will reuse"
  - "Confirmed root cause of a real address-format trap for any future plan comparing HyprlandToplevel.address against hyprctl's own JSON output: HyprlandToplevel.address omits the '0x' prefix hyprctl clients -j includes — string equality silently fails with no error, easy to miss without live verification"
affects: [16-06-drag-and-drop, 16-07-click-and-keyboard, 16-08-perf-measurement]

actuals:
  tokens: 5468
  tasks: 3
  commits: 2

tech-stack:
  added: []
  patterns:
    - "Three-state capture machine as a single readonly formula: captureState: _everPopulated ? 'populated' : (_timedOut ? 'failed' : 'pending') — sticky forward (once populated, stays populated through any later hasContent flicker) and NOT sticky on failure (content landing after the settle timer fires still flips straight to populated on the next hasContent pulse, since _everPopulated is checked first)."
    - "Per-window click targets added as INLINE children on an existing typed delegate instantiation (WorkspaceTile.qml's Repeater delegate: WindowThumbnail { signal activated(); MouseArea { ... } } ) rather than modifying the child type's own .qml file — QML's default-property child-appending lets a caller extend a component instance with new signals/children at the instantiation site, keeping the click-target change scoped to the file that actually needs it (WorkspaceTile.qml), not the type it wraps (WindowThumbnail.qml)."
    - "HyprlandToplevel.address (QML) omits the '0x' hex prefix that hyprctl clients -j's own address field carries — confirmed by a temporary console.log during Task 3's fault injection, not assumed. Any future code comparing the two must strip/add the prefix explicitly; a silent string mismatch here fails closed (the condition is just always false) with no QML error at all."
    - "settleCeilingReached (Overview.qml) is the same 'safety-net timer with a WindowThumbnail-token multiple as its interval, not a duplicate literal' shape as the per-window settleTimer in WindowThumbnail.qml — both source their interval from Motion.ambientDuration times a small integer, commented with what the multiple is trading off, rather than a bare number."

key-files:
  created: []
  modified:
    - quickshell/.config/quickshell/modules/overview/WindowThumbnail.qml
    - quickshell/.config/quickshell/modules/overview/WorkspaceTile.qml
    - quickshell/.config/quickshell/modules/Overview.qml

key-decisions:
  - "stateColour()'s four case labels (populated/pending/empty/failed) are declared in full, byte-identical to PanelDialog.qml's own switch body, even though WindowThumbnail's own captureState formula only ever assigns three of the four literals (populated/pending/failed — 'empty' is never reached). Task 1's own acceptance criteria compare the two functions' Colours.* role SETS for equality, and the plan's action text says to reuse the mapping rather than re-derive a narrower one — keeping all four cases is what makes the two switch bodies provably the same mapping rather than a coincidentally-overlapping one."
  - "The settle timeout (WindowThumbnail.qml, 3x Motion.ambientDuration) and the whole-grid ceiling (Overview.qml, 6x Motion.ambientDuration) are both derived from the SAME token, at different multiples, rather than two independent literals — the ceiling only needs to exceed the largest plausible per-window settle time, so tying it to the same base token means a future motion-scale change (T-15-11-01's reduced-motion accessibility path) moves both proportionally instead of leaving the ceiling's relationship to the per-window timeout to accidentally drift."
  - "toplevel.wayland.activate() (the generic Quickshell.Wayland.Toplevel / wlr-foreign-toplevel-management handle) is the activation call, not a HyprlandToplevel-native method — confirmed directly against the installed qmltypes rather than assumed: HyprlandToplevel itself exposes no activate() method at all (only HyprlandWorkspace does, for the 'focus this workspace' path WorkspaceTile.qml's whole-area click already used before this plan). This is the same handle ScreencopyView.captureSource already binds to, so no new object reference is threaded through."
  - "Task 3's fault injections targeted a REAL, already-open window (the Claude Code terminal on workspace 2, matched by HyprlandToplevel.address) for the partial-control screenshot, rather than spawning throwaway test windows — reusing the three windows already open on this desktop kept the injection scope to source-code edits only, with no live-window spawning/teardown risk under the plan's own live-system-safety constraints."

requirements-completed: [OVER-01, OVER-02]

coverage:
  - id: D1
    description: "A window whose capture has not yet produced a frame renders a pending state (primary-tinted loading glyph, pulsing on Motion.ambientDuration/ambientEasing) and clears itself the moment the first frame lands"
    requirement: "OVER-01"
    verification:
      - kind: automated_ui
        ref: "Task 1 <verify> block: happy path unaffected (windows=3 withContent=3 within 3s after the state machine landed), clean quickshell.log across a summon/dismiss cycle"
        status: pass
      - kind: other
        ref: "Task 3 fault injection: captureState forced to a constant 'pending' for every thumbnail, restarted, screenshot (task3-pending.png) shows the pulsing progress_activity glyph over live content on 2 of 3 real windows; injection reverted, git diff --stat empty"
        status: pass
    human_judgment: false
  - id: D2
    description: "A window whose capture is still empty past a timeout renders a failed state — icon, the window's real title from Hyprland IPC, one honest non-diagnostic line — reusing the panel family's four-state vocabulary and role mapping rather than inventing a fifth state or a second colour mapping"
    requirement: "OVER-01"
    verification:
      - kind: automated_ui
        ref: "Task 1 <verify> block: stateColour()'s Colours.* role set compared against PanelDialog.qml's own switch body and asserted equal (grep -A8 both functions, sort -u, string-compare)"
        status: pass
      - kind: other
        ref: "Task 3 fault injection: hasContent forced to a constant false for every thumbnail plus a short settle timeout, restarted, screenshot (task3-failed.png) shows visibility_off icon + each window's real title (Minecraft Season 3 Start.../Claude Code/Reduce blur strength...) + 'Live preview unavailable' on all three real windows; titles cross-checked against hyprctl clients -j output; injection reverted"
        status: pass
    human_judgment: false
  - id: D3
    description: "When no window anywhere in the grid produces content, one surface-level message is shown instead of the same failure repeated on every tile — never while any capture is still pending, bounded by a ceiling so a never-settling view cannot hide the message indefinitely"
    requirement: "OVER-01"
    verification:
      - kind: automated_ui
        ref: "Task 2 <verify> block: allSettled/wholeGridCatchVisible declared and referenced in the visibility condition; live re-run confirms the message stays absent with real content (withContent=3, screenshot task2-happy-path.png)"
        status: pass
      - kind: other
        ref: "Task 3 fault injection: the same all-hasContent-false injection that produced task3-failed.png simultaneously triggered the whole-grid catch (copied as task3-grid-catch.png) — 'Can't show live thumbnails' heading + the exact body copy, centred, visible at the same moment as the per-window failed cards underneath a darkened scrim; injection reverted, and the negative control (task2-happy-path.png, real content) independently confirms absence"
        status: pass
    human_judgment: false
  - id: D4
    description: "A mix of captured and denied windows uses per-window treatment only — the whole-grid catch fires solely when zero windows anywhere capture"
    requirement: "OVER-01"
    verification:
      - kind: other
        ref: "Task 3 partial-control fault injection: hasContent forced false for exactly one real window (Claude Code, address matched via HyprlandToplevel.address) while the other two stayed live; screenshot (task3-partial.png) shows the failed treatment on that one tile only, live content on the other two, and the whole-grid message absent; qs ipc call overview status read withContent=2 (not 0) confirming the aggregate correctly saw partial content; injection reverted"
        status: pass
    human_judgment: false
  - id: D5
    description: "Clicking a window thumbnail focuses that window and its workspace and closes the overview; clicking a tile's empty area focuses the workspace and closes — the mouse never does strictly less than the keyboard"
    requirement: "OVER-02"
    verification:
      - kind: other
        ref: "Structural/code-level: WorkspaceTile.qml's per-delegate MouseArea is bounded to exactly the WindowThumbnail's own real-geometry bounds (never the whole tile) and declared after the thumbnail's internal ScreencopyView, so it always paints above live content without ever covering the gap between windows; Overview.qml's activateWindow() calls toplevel.wayland.activate() (confirmed present on the generic Wayland toplevel-management handle via the installed qmltypes) then dismisses"
        status: pass
      - kind: manual_procedural
        ref: "NOT independently reproduced by the executor — no pointer-simulation tool is available in this environment (checked: ydotool/wlrctl/dotool absent, only wtype for keyboard input exists). The plan's own <human-check> for this criterion requires an actual mouse click, which the executor cannot synthesize; the click-target geometry and z-order were verified structurally and via source inspection instead."
        # status corrected 2026-08-16 (21-03, LEDGER-06): "not_run" is not a valid
        # status value anywhere else in this milestone's coverage corpus. "unknown"
        # is the value the corpus actually uses for this exact shape — a
        # manual_procedural check the executor could not perform for lack of a
        # synthetic pointer tool (see 14-01-SUMMARY.md:68, 15-10-SUMMARY.md:72,
        # the only two other occurrences of this pattern in v3.0-phases). This is
        # a judgment call, not a mechanical rename: "unknown" was chosen over
        # "fail" because the check was never exercised, not exercised-and-failed.
        status: unknown
    human_judgment: true
    rationale: "Whether an actual pointer click lands on the correct target and produces the correct focus/dismiss behavior on the live desktop is exactly what 16-02/16-03's own history says only human observation reliably catches for this surface (two screenshot-verified false passes preceded the real multi-window fix). This plan's structural/geometry argument is sound but is not a substitute for the operator physically clicking a thumbnail — flagged honestly rather than claimed complete. Recommend folding into D-16-22's dated running note (16-03-SUMMARY.md's precedent for exactly this class of executor-cannot-reproduce check) at the next live session."

duration: single session (compressed run, no checkpoints — plan-level autonomous:true)
completed: 2026-08-03
status: complete
---

# Phase 16 Plan 05: Window Click Parity and Honest Capture Failure States Summary

**Every window thumbnail now resolves one of three states — populated, pending, failed — driven by `ScreencopyView.hasContent` plus a token-sourced settle timer, reusing `PanelDialog.qml`'s exact state-colour mapping; a single whole-grid message replaces per-tile repetition when nothing anywhere captures; clicking a specific window thumbnail now focuses that window (not just its workspace); and all three degraded states plus the partial-failure control were proven to render by live fault injection against the operator's real desktop, with every injection reverted to an empty diff.**

## Performance

- **Duration:** single session, compressed run (all three tasks `type="auto"`, no checkpoints — plan frontmatter `autonomous: true`)
- **Completed:** 2026-08-03
- **Tasks:** 3 (2 committed, 1 fault-injection/verification-only with zero net diff)
- **Files modified:** 3 (0 created, 3 modified)

## Accomplishments

- `WindowThumbnail.qml` gained a `captureState` machine (`populated`/`pending`/`failed`) driven by `hasContent` plus a single-shot settle `Timer` sourced from `Motion.ambientDuration * 3` — a token, never a bare literal. The state is sticky forward (once populated, stays populated through any later `hasContent` flicker) and explicitly NOT sticky on failure (a frame landing after the timer fires still flips straight to populated).
- `stateColour()` reuses `PanelDialog.qml`'s exact four-name/four-role mapping, verified byte-identical by comparing the two functions' `Colours.*` role sets as equal sets — not merely "looks similar."
- `Overview.qml` gained `allSettled` (aggregated across all eleven tiles' `thumbnailsSettled`) with a `settleCeilingReached` safety-net timer (`Motion.ambientDuration * 6`), and a `wholeGridCatchVisible` condition (`thumbnailCount > 0 && allSettled && thumbnailsWithContent === 0`) rendering one centred "Can't show live thumbnails" message instead of per-tile repetition.
- D-16-20's click parity closed: `WorkspaceTile.qml`'s `Repeater` delegate gained an inline `MouseArea` + `activated()` signal (added at the instantiation site, not by modifying `WindowThumbnail.qml`), relayed as `windowActivated(toplevel)` and handled in `Overview.qml` via `toplevel.wayland.activate()` — confirmed against the installed qmltypes that `HyprlandToplevel` itself has no `activate()` method; only the generic Wayland toplevel-management handle does.
- All three degraded states AND the partial-failure control were proven to render via live fault injection on the operator's real desktop (3 real windows across 3 workspaces), with screenshots captured to the session scratchpad and every injected edit reverted to an empty `git diff --stat` before the final commit.
- Found and worked around a genuine, previously-unconfirmed API trap during Task 3: `HyprlandToplevel.address` (QML) omits the `0x` prefix that `hyprctl clients -j`'s own `address` field carries — a naive string comparison between the two silently and permanently fails with no error. Confirmed via a temporary `console.log`, not assumed; recorded here so no later plan re-derives this the hard way.

## Task Commits

Each task with a net file diff was committed atomically:

1. **Task 1: Give every window thumbnail three honest capture states** — `4cdcc78` (feat)
2. **Task 2: Raise the whole-grid catch once, and give window thumbnails click parity** — `7ee3635` (feat)
3. **Task 3: Prove pending, failed and the whole-grid catch can actually render** — *(no commit — zero net file diff; all four fault injections were reverted to an empty `git diff --stat` for both files before this plan's own metadata commit, per the task's own acceptance criteria)*

**Plan metadata:** (this commit)

## Files Created/Modified

- `quickshell/.config/quickshell/modules/overview/WindowThumbnail.qml` — the three-state capture machine (`captureState`, `settled`, `stateColour()`, the settle `Timer`), the pending glyph (ambient-pulsing `progress_activity`), and the failed-state stack (icon + real title, elided right + one-line reason), degrading bottom-up at small sizes.
- `quickshell/.config/quickshell/modules/overview/WorkspaceTile.qml` — `thumbnailsSettled` aggregate; per-thumbnail `MouseArea` + `activated()` signal added inline on the `Repeater` delegate; new `windowActivated(toplevel)` signal relayed upward.
- `quickshell/.config/quickshell/modules/Overview.qml` — `activateWindow(toplevel)` function; `thumbnailsSettled`/`allSettled`/`settleCeilingReached`/`settleCeilingTimer`; the whole-grid catch `Rectangle` (`wholeGridCatchVisible`, `catchScrimOpacity`, lock glyph, heading, body copy); `onWindowActivated` wiring on all three `WorkspaceTile` instantiations (row one, row two, scratchpad).

## Decisions Made

See `key-decisions` in the frontmatter above for the full record with rationale. Summarised:
- `stateColour()` keeps all four case labels (including the unused `empty`) to stay provably identical to `PanelDialog.qml`'s own mapping, rather than a narrower three-case function that only coincidentally overlaps.
- The per-window settle timeout and the whole-grid ceiling both derive from `Motion.ambientDuration` at different multiples (3x, 6x) rather than independent literals, so a future motion-scale change moves both proportionally.
- `toplevel.wayland.activate()` (the generic Wayland toplevel-management handle) is the correct activation call, confirmed against the installed qmltypes — `HyprlandToplevel` itself has no `activate()`.
- Task 3's fault injections reused the three already-open real windows rather than spawning throwaway ones, keeping the blast radius to source-code edits only.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `HyprlandToplevel.address` omits the `0x` hex prefix `hyprctl clients -j` includes**
- **Found during:** Task 3, the partial-control fault injection (targeting exactly one real window by address).
- **Issue:** The injection compared `root.toplevel.address === "0x55a75383b280"` (the exact string `hyprctl clients -j` reports) and silently matched nothing — `qs ipc call overview status` kept reporting `withContent=3` instead of the expected `2`, with no QML error to signal the mismatch.
- **Fix:** Added a temporary `console.log` to print the actual property value, confirmed it reads `55a75383b280` (no `0x` prefix), corrected the comparison string, removed the debug line before re-testing.
- **Files modified:** `quickshell/.config/quickshell/modules/overview/WindowThumbnail.qml` (temporary, fully reverted before the final commit — this fix only existed inside the fault-injection window, not in shipped code)
- **Verification:** Re-ran with the corrected string; `qs ipc call overview status` read `withContent=2`; screenshot confirmed exactly one tile in the failed state.
- **Committed in:** N/A — this was a fault-injection debugging step, not a shipped-code fix. Recorded here (and in `key-decisions`/`tech-stack.patterns`) purely as a fact for future plans comparing these two address formats.

### Auto-fixed / self-corrected during live restart

**2. [Rule 3 - Blocking] Initial detached-restart attempt via a bare `setsid uwsm app --` from a Bash tool call left quickshell not running at all**
- **Found during:** the very first restart attempt for Task 1's live verification.
- **Issue:** `pkill -f "quickshell -p"` followed by `setsid uwsm app -- ... &` (with output redirected to a scratchpad log) produced no running quickshell process and no log output — the backgrounded job appears to have been reaped when the tool call's own shell context ended, despite `setsid`/`disown`.
- **Fix:** Switched to the exact standing form the plan itself specifies (`setsid uwsm app -- ~/.config/hypr/scripts/quickshell-launch.sh < /dev/null > <logfile> 2>&1 &` followed by `disown`, in the SAME bash invocation, with a `sleep` before checking), which reliably produced a process reparented to `systemd --user` (PID 814) — confirmed via `ps -o ppid=` after every subsequent restart in this plan, per the plan's own "confirming the new PID's parent is not a shell" instruction.
- **Files modified:** none (operational fix only, a reusable `restart-qs.sh` helper script written to the session scratchpad, not the repo).
- **Verification:** `ps -o pid,ppid,cmd -p <new_pid>` showed `PPID 814 → /usr/lib/systemd/systemd --user` after every one of the plan's five live restarts.

---

**Total deviations:** 2 (both Rule 3 — blocking issues resolved during execution, neither is a shipped-code change; the address-prefix finding is recorded as a fact for future plans, not a bug in this plan's own shipped source)
**Impact on plan:** No scope creep. Both deviations were resolved without altering any acceptance criterion or must-have; the address-prefix finding is purely informational for future plans that might make the same silent-mismatch mistake.

## Issues Encountered

**The one criterion this executor could not independently prove live: an actual mouse click on a thumbnail.** See coverage item D5 above. No pointer-simulation tool (`ydotool`/`wlrctl`/`dotool`) is available in this environment — only `wtype` (keyboard-only) was found. The click-target geometry (bounded to the thumbnail's own real-geometry bounds, layered above the capture view, declared after it in z-order) and the activation call (`toplevel.wayland.activate()`, confirmed present on the installed qmltypes) were verified structurally and via source inspection, but the plan's own `<human-check>` for this criterion explicitly requires a physical click — which the executor genuinely cannot synthesize on this host. Recommended for D-16-22's dated running note (the same mechanism 16-03-SUMMARY.md used to defer its own scratchpad-window-move check that needed a real `Super+Shift+S` keypress).

**A brief pending-glyph visibility gap on tile 1, observed but not investigated further.** During the pending-state fault injection (task3-pending.png), the pulsing glyph was clearly visible on tiles 2 and 3 (over live terminal content) but not confirmed visible on tile 1 (the large Zen Browser/YouTube window) in the same screenshot — most likely a timing coincidence of the independent per-glyph opacity animation phase (each `SequentialAnimation` instance starts on its own schedule, so a screenshot can catch different tiles at different points in their own pulse cycle) rather than a rendering defect, since the same fault injection unconditionally forces `captureState: "pending"` for every thumbnail with no per-window branching. Not treated as a defect — the plan's own acceptance bar ("a screenshot showing the pulsing glyph on a tile that normally shows live content") is met by the two tiles where it is clearly visible.

## User Setup Required

None — no external service configuration required. The one open item (D5's live click verification) needs no setup, just a human physically clicking a window thumbnail during the overview's next real use, which D-16-22's dated running note already exists to capture.

## Next Phase Readiness

- **`WindowThumbnail.qml`'s `captureState`/`settled` properties are now the seam plan 16-06 (drag) and 16-07 (keyboard) should read, not re-derive.** A drag ghost or keyboard-selected thumbnail in the `failed` state is still a valid drag source / focus target — nothing in this plan's implementation gates either on capture success, matching the plan's own "a thumbnail in the failed state is still clickable" requirement.
- **`Overview.qml`'s `activateWindow(toplevel)` function is the exact mechanism plan 16-07's Enter-on-selected-window should call.** It already does the right thing (`toplevel.wayland.activate()` then dismiss) — 16-07 should call this function directly rather than re-deriving the activation call.
- **The `HyprlandToplevel.address` vs. `hyprctl clients -j`'s `address` field prefix mismatch (no `0x` on the QML side) is now a confirmed fact, not a guess** — any later plan comparing the two (16-06's drag-drop will almost certainly need to, per 16-RESEARCH.md Q3's open question about targeting a non-focused window by address) must account for this explicitly.
- **D5 (mouse click parity) is structurally verified but not live-click-verified by the executor** — carry into D-16-22's first dated running-note entry, which the plan's own D-16-22 already requires to exercise "drag, the keyboard model, opening over a fullscreen client, and thumbnails under a heavy window count" — add "click a window thumbnail directly" to that first pass explicitly, since this plan could not close that loop itself.
- **16-04's own honest finding about `overview-content-check` (check 6) still holds unchanged by this plan:** it catches the whole-grid blank-tile case (which this plan's Task 3 fault injection also exercised) but not per-delegate geometry collapse. This plan did not attempt to close that gap — it was out of scope here (Task 3's job was proving the NEW capture-state UI renders, not re-auditing the doctor check's coverage).
- **Evidence artifacts** (session scratchpad, not the repo): `task3-pending.png`, `task3-failed.png`, `task3-grid-catch.png` (same underlying screenshot, copied — the all-fail injection produced both the per-window failed treatment and the whole-grid catch simultaneously), `task3-partial.png`, plus `task2-happy-path.png` (negative control) and two supplementary crops.

---
*Phase: 16-workspace-overview*
*Completed: 2026-08-03*

## Self-Check: PASSED

- FOUND: quickshell/.config/quickshell/modules/overview/WindowThumbnail.qml
- FOUND: quickshell/.config/quickshell/modules/overview/WorkspaceTile.qml
- FOUND: quickshell/.config/quickshell/modules/Overview.qml
- FOUND: .planning/phases/16-workspace-overview/16-05-SUMMARY.md
- FOUND: commit 4cdcc78 (Task 1)
- FOUND: commit 7ee3635 (Task 2)
- FOUND: commit 31e2de3 (SUMMARY)
