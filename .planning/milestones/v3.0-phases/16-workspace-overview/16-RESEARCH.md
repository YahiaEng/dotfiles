# Phase 16: Workspace Overview - Research

**Researched:** 2026-08-03
**Domain:** Quickshell live-thumbnail workspace grid on Hyprland
**Confidence:** MEDIUM (mostly HIGH on installed API surface; MEDIUM/LOW on one load-bearing dispatch gap — see Q3)

## Summary

CONTEXT.md's "Installed API surface" and "Existing Code Insights" sections already verified the core Quickshell/Hyprland data model directly on this machine — this research does not re-derive those. What it adds: (1) the exact `ScreencopyView`/`Toplevel` qmltypes property/method list read from disk, cross-checked against the working `ScreencopyProbe.qml` pattern; (2) a critical, previously-undocumented-for-this-phase finding that this repo's Hyprland instance runs the **Lua config** (Phase 13.1 cutover), which changes what string `Hyprland.dispatch()` must send over the IPC socket; (3) a concrete, run-on-this-machine perf measurement recipe for OVER-04; (4) the blank-tile predicate, which is exactly `hasContent === false` — no separate error/denied signal exists.

**Primary recommendation:** Build the overview as `ScreencopyProbe.qml`'s pattern (`Repeater` over `Toplevel`s, keyed by `HyprlandToplevel.workspace`), but before writing the drag-drop task, run a Wave 0 spike to confirm the exact Lua dispatch string that moves a **specific, non-focused** window by address — this is unverified and gates OVER-03.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Workspace/window enumeration | Compositor (Hyprland, via Quickshell's native `Hyprland` singleton) | Quickshell QML (consumer) | Data is native Hyprland IPC state; Quickshell exposes it as bound QML properties, no parsing needed |
| Live thumbnail rendering | Quickshell QML (`ScreencopyView` + `wlr-screencopy`/toplevel-export protocol) | Compositor (grants the capture) | Rendering happens client-side in the Quickshell surface; the compositor only gates permission |
| Window move (drag-drop) | Compositor (Hyprland dispatcher) | Quickshell QML (issues the dispatch string) | Only the compositor can actually reparent a window to a workspace; Quickshell just sends the command |
| Overview surface lifecycle | Quickshell QML (`PanelWindow` + `LazyLoader`) | — | Established pattern from Phase 14/15, reused verbatim |

## Q1 — ScreencopyView API surface

`Quickshell.Wayland.ScreencopyView` (`view.hpp`, `qs::wayland::screencopy::ScreencopyView`), read directly from `/usr/lib/qt6/qml/Quickshell/Wayland/_Screencopy/quickshell-wayland-screencopy.qmltypes` on this machine `[VERIFIED: /usr/lib/qt6/qml/Quickshell/Wayland/_Screencopy/quickshell-wayland-screencopy.qmltypes:19-88]`:

- `captureSource: QObject*` — settable/readable, `captureSourceChanged` signal
- `paintCursor: bool` — settable
- `live: bool` — settable; `false` presumably takes a single frame rather than a continuous stream (matches D-16-07's "static → live" fallback ladder using this same property)
- `hasContent: bool` — **readonly**, bindable, `hasContentChanged` signal — the blank-tile detector (see Q5)
- `sourceSize: QSize` — readonly, bindable
- `constraintSize: QSizeF` — settable, for scaling the capture into a tile
- `captureFrame()` — method, single-shot capture (used for D-16-12's drag snapshot and the "static" fallback rung)
- `stopped` — signal, no documented payload

Binding to a toplevel: `captureSource` accepts the `Quickshell.Wayland.Toplevel` object directly — confirmed working in the repo's own `ScreencopyProbe.qml`: `captureSource: modelData` where `modelData` comes from `Repeater { model: ToplevelManager.toplevels }` `[VERIFIED: /home/aorus/dotfiles/quickshell/.config/quickshell/modules/ScreencopyProbe.qml:79-87]`. CONTEXT.md additionally confirms the Hyprland-side handle needed for the workspace-grouped case: `HyprlandToplevel.wayland` is "exactly the object type `ScreencopyView.captureSource` accepts" `[VERIFIED: 16-CONTEXT.md:635-637, quoted verbatim above]` — so for the overview (grouped by workspace, not a flat list) bind `captureSource: modelData.wayland` where `modelData` is a `HyprlandToplevel` from `HyprlandWorkspace.toplevels`.

**Denied / inactive-workspace behavior:** no property or signal in the qmltypes distinguishes "denied" from "not yet captured" — both present as `hasContent: false`. Nothing in the qmltypes suggests capture is blocked for toplevels on inactive/non-visible workspaces; `hyprland-toplevel-export-v1` (unlike plain `wlr-screencopy` output-based capture) targets the **toplevel handle**, not a visible screen region, so off-screen/inactive-workspace windows should still be capturable in principle `[CITED: wayland-protocols hyprland-toplevel-export-v1 — training knowledge, not fetched this session]`. Not empirically confirmed on this machine with a window on an inactive workspace — **flag as a Wave 0 verification item**, since D-16-01 requires all 10 slots always rendered including occupied-but-inactive ones.

## Q2 — Enumerating windows per workspace

No separate research needed — fully answered and verbatim-quoted in CONTEXT.md's "Installed API surface" section, read directly from `/usr/lib/qt6/qml/Quickshell/Hyprland/_Ipc/quickshell-hyprland-ipc.qmltypes` this session:

> `HyprlandWorkspace` — `id`, `name`, `active`, `focused`, `urgent`, `hasFullscreen`, `lastIpcObject`, `monitor`, **`toplevels` (UntypedObjectModel)**, **`activate()`**
> `HyprlandToplevel` — `address`, **`wayland`** (the `qs::wayland::toplevel_management::Toplevel` that `ScreencopyView.captureSource` accepts), `title`, `activated`, `urgent`, **`lastIpcObject`** (carries `at`/`size` for D-16-02), **`workspace`**, **`monitor`**

`[VERIFIED: 16-CONTEXT.md:626-642]` — read this session, quotes verbatim. Additionally confirmed method presence directly from the qmltypes file: `Hyprland.dispatch(request: QString)`, `refreshWorkspaces()`, `refreshToplevels()` all exist as methods on the `Hyprland` singleton `[VERIFIED: /usr/lib/qt6/qml/Quickshell/Hyprland/_Ipc/quickshell-hyprland-ipc.qmltypes:155-169]`.

**Practical grouping pattern:** iterate `Hyprland.workspaces` (fixed 10 slots per D-16-01 — pad/synthesize slots for IDs 1-10 that don't exist yet, since `Hyprland.workspaces` only lists workspaces Hyprland already knows about), then `Repeater { model: workspace.toplevels }` per tile, binding `captureSource: modelData.wayland`.

## Q3 — Moving a window to a workspace

**Locked API shape, empirically confirmed by this repo's Phase 13.1 work (not re-verified live this session, but sourced from the repo's own test evidence):** the dispatcher is invoked as `hl.dsp.window.move({ workspace = N })`, and the classic-dispatcher-equivalence script maps this table's `workspace` field to `movetoworkspace` `[VERIFIED: /home/aorus/dotfiles/hypr/.config/hypr/scripts/keybind-source-equivalence:331-338]`, and `/home/aorus/dotfiles/hypr/.config/hypr/config/keybinds.lua:227-236` uses exactly this shape for the existing `Super+Shift+<num>` binds `[VERIFIED: keybinds.lua:227-236]`.

**Critical, previously-undocumented-for-Phase-16 finding — the Lua config cutover changes what string must be sent over the dispatch socket.** This repo's Hyprland instance uses the Lua config (Phase 13.1). Direct quote from the repo's own findings, read this session:

> "on a Lua-config-managed instance, `hyprctl dispatch` takes a Lua expression (`hl.dsp.xxx(...)`), not the classic `dispatcher,args` string." `[VERIFIED: /home/aorus/dotfiles/hypr/.config/hypr/config/keybinds.lua:44-47]`

and from `hypridle.conf`, confirming the exact wrapping mechanism: `hyprctl dispatch dpms off` is textually wrapped into `return hl.dispatch(dpms off)` and evaluated as Lua source `[VERIFIED: /home/aorus/dotfiles/hypr/.config/hypr/hypridle.conf:5-8]`. Quickshell's `Hyprland.dispatch(request: QString)` sends its argument over the same Hyprland IPC socket `hyprctl dispatch` uses — there is no reason to expect Quickshell has special-cased Lua-vs-hyprlang detection. **This means the plan must issue `Hyprland.dispatch("hl.dsp.window.move({workspace=N, ...})")` as a literal string, not the classic comma-separated `"movetoworkspacesilent N,address:0x..."` form.** This is an inference from repo evidence, not independently re-verified against Quickshell this session — tag `[ASSUMED, high-confidence-inference]`.

**Genuine open gap (recommend Wave 0 spike):** all confirmed usages of `hl.dsp.window.move({workspace=...})` are keybind-triggered, which implicitly targets the **active/focused window** — matching classic Hyprland's `movetoworkspace` dispatcher behavior when no window selector is given. The overview needs to move an arbitrary, possibly-unfocused window by address (dragged tile ≠ focused window). No stub, comment, or prior-phase finding in this repo documents a `window`/`address` selector field on `hl.dsp.window.move`'s table `[VERIFIED: absence checked in /usr/share/hypr/stubs/hl.meta.lua — no `window` or `address` field appears near the Dispatcher class, lines 855-930]`. This repo's own convention is to test dispatcher argument shapes live before writing them into config (T-13.1-10, "never inferred from the hyprlang keyword") — the plan should add a **Wave 0 spike task**: dispatch `hl.dsp.window.move({workspace=N, window="address:0x..."})` (or `window=<address string>`) against a real non-focused window and read back `hyprctl clients -j` to confirm it moved without focus following. If that field doesn't exist, the fallback is to focus the window first (`Hyprland.dispatch("hl.dsp.window.move_window..." )` — no, simpler: activate via `HyprlandToplevel.activate()` then dispatch the plain move) — but D-16-13 requires the move be **silent** (focused workspace must not jump), so a focus-first approach may violate that decision and needs explicit user/plan attention if the selector field doesn't exist.

**Confidence:** MEDIUM on the Lua-wrapping requirement (repo-evidence inference), LOW on the specific-window-targeting field name — this is the single highest-risk unknown for OVER-03 and should not be planned as a one-line task.

Installed Hyprland version, confirmed this session: `hyprctl version` → `Hyprland 0.56.1` `[VERIFIED: hyprctl version output]` — CONTEXT.md/roadmap says "0.56.0"; the running instance is 0.56.1, a patch ahead. Not expected to matter for this API, noting for the record.

## Q4 — Perf measurement + fallback

No built-in single command exists; recommend a two-part measurement, both nameable/runnable by a plan task:

1. **Compositor-side frame time/FPS:** Hyprland ships a built-in debug overlay. Confirmed the config key exists and is currently off: `hyprctl getoption debug:overlay` → `bool: false` `[VERIFIED: hyprctl getoption debug:overlay output, this session]`. Toggle for a measurement run with `hyprctl keyword debug:overlay true` (draws an on-screen frame-time/FPS readout while the overview is open), read the readout, then `hyprctl keyword debug:overlay false` to revert (this is a one-shot config keyword, not persisted to the Lua config file).
2. **Quickshell-side CPU:** `pidstat` is **not installed** on this machine (`sysstat` package absent) `[VERIFIED: pidstat/mpstat "not found", pacman -Q sysstat error, this session]` — fallback to the always-available `top -b -n 10 -d 1 -p $(pgrep -f 'qs ')` (10 one-second samples, batch mode, greppable `%CPU` column), or `ps -o %cpu,rss -p $(pgrep -f 'qs ')` for a single snapshot.

**Fallback recommendation (answers "what happens when the budget is blown"):** pause `live` on offscreen/off-monitor tiles is not applicable here (single-monitor host, D-16-04/16 confirms only one monitor `[VERIFIED: 16-CONTEXT.md:650]`) — but pausing `live` on tiles **not currently visible in the grid's viewport is moot too, since all 10 tiles render simultaneously by design (D-16-01)**. Given that, the correct fallback is exactly the one CONTEXT.md's D-16-07 ladder already specifies (do not re-derive; quoting for the planner's convenience): the ladder drops in this order — (1) drop the full-screen blur, (2) then further rungs downgrade `live: true` toward single-frame `captureFrame()` snapshots. Recommend the plan implement the **`live` → static-snapshot-via-`captureFrame()`** step as the actual fallback mechanism (not a tile count cap, since D-16-01 fixes the tile count at 10 and won't reduce it) — this reuses the same `ScreencopyView.live`/`captureFrame()` properties already verified in Q1, so no new API surface is introduced by the fallback.

## Q5 — Blank-tile failure mode

`hasContent: bool` (readonly, bindable) is the **only** documented signal — confirmed by direct read of the qmltypes file, no separate `error`, `denied`, or `state` property exists on `ScreencopyView` `[VERIFIED: /usr/lib/qt6/qml/Quickshell/Wayland/_Screencopy/quickshell-wayland-screencopy.qmltypes:47-56, full property/signal list reproduced in Q1]`. A denied or not-yet-arrived capture both present identically as `hasContent === false`; there is no way to distinguish "compositor said no" from "first frame hasn't landed yet" from the property alone — this is exactly why CONTEXT.md's D-16-10 requires a **timeout** to distinguish momentary-pending from genuine denial (pending state, then icon+title+reason after some delay) rather than trusting a single boolean transition `[VERIFIED: 16-CONTEXT.md:204-218, quoted above]`. The detectable predicate for a plan to assert on: `screencopyView.hasContent === false` sustained past a chosen timeout window = failed/denied; `hasContent === true` = live content. `sourceSize` going to `QSize(0,0)` is a plausible secondary tell but not independently confirmed on this machine this session — treat as `[ASSUMED]` corroborating signal only, `hasContent` is the primary, verified predicate.

## Existing code analogs (one line each, per additional_context)

- **Panel lifecycle / keybind-to-open:** `/home/aorus/dotfiles/quickshell/.config/quickshell/modules/ScreencopyProbe.qml` — `PanelWindow` + `WlrLayershell.layer: Overlay` + `HyprlandFocusGrab` click-outside dismiss, the closest existing analog (it already does per-window `ScreencopyView` + `Repeater` over `ToplevelManager.toplevels`) `[VERIFIED: file read this session]`.
- **Drag interaction:** none exists in the repo yet — `grep -rl "DragHandler"` over `quickshell/.config/quickshell/modules/` returned no hits `[VERIFIED: grep this session]`. OVER-03's drag-drop must be built from QtQuick's stock `DragHandler`/`Drag` attached property with no in-repo precedent to reuse.
- **Hyprland IPC dispatch:** no prior QML file in this repo calls `Hyprland.dispatch()` — `grep -rl "dispatch("` over the quickshell config tree found only unrelated `_dispatch()` helper calls in `MediaBackend.qml` (MPRIS script wrapper, not Hyprland IPC) `[VERIFIED: grep this session]`. This phase is the first to exercise `Hyprland.dispatch()` from QML in this repo — reinforces why Q3's Wave 0 spike matters, there's no working in-repo example to copy.

## Package Legitimacy Audit

Not applicable — this phase adds no new external packages. `quickshell` (0.3.0-2) is already installed and pinned per PROJECT.md/D-13 `[VERIFIED: pacman -Q quickshell, this session]`.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| quickshell | entire phase | Yes | 0.3.0-2 | — |
| Hyprland | dispatch/workspace API | Yes | 0.56.1 | — |
| `debug:overlay` compositor keyword | OVER-04 frame-time measurement | Yes | n/a (config key) | — |
| `pidstat`/`sysstat` | OVER-04 CPU measurement | No | — | `top -b -n <N> -d 1 -p <pid>` |

## Open Questions

1. **Does `hl.dsp.window.move` accept a window/address selector to target a non-focused window?**
   What we know: the table accepts `workspace` and `direction` fields, empirically confirmed via keybind use (always acts on the active window in that context).
   What's unclear: whether a third field lets it target an arbitrary window by address when called outside a keybind context — no stub or prior-phase finding documents this.
   Recommendation: Wave 0 spike task, dispatch against a real non-focused window, read back `hyprctl clients -j` to confirm — follow this repo's own T-13.1-10 convention of never inferring dispatcher argument shapes from anything but a live test.

2. **Does `hyprland-toplevel-export-v1` capture succeed for a toplevel on a currently-inactive (non-visible) workspace?**
   What we know: the protocol targets toplevel handles, not screen regions, so it should work in principle.
   What's unclear: not empirically tested on this machine with a window parked on an inactive workspace.
   Recommendation: fold into the Phase 11-style screencopy feasibility check, or verify directly during OVER-01's first render pass — if it fails, D-16-01's "all 10 slots always rendered" criterion needs the pending-state fallback (D-16-10) to also cover "workspace not currently visible," not just "denied."

## Sources

### Primary (HIGH confidence — read directly this session)
- `/usr/lib/qt6/qml/Quickshell/Wayland/_Screencopy/quickshell-wayland-screencopy.qmltypes`
- `/usr/lib/qt6/qml/Quickshell/Wayland/_ToplevelManagement/quickshell-wayland-toplevel-management.qmltypes`
- `/usr/lib/qt6/qml/Quickshell/Hyprland/_Ipc/quickshell-hyprland-ipc.qmltypes`
- `/home/aorus/dotfiles/quickshell/.config/quickshell/modules/ScreencopyProbe.qml`
- `/home/aorus/dotfiles/hypr/.config/hypr/config/keybinds.lua`
- `/home/aorus/dotfiles/hypr/.config/hypr/scripts/keybind-source-equivalence`
- `/home/aorus/dotfiles/hypr/.config/hypr/hypridle.conf`
- `/usr/share/hypr/stubs/hl.meta.lua`
- `/usr/share/hypr/hyprland.lua`
- `hyprctl version`, `hyprctl getoption debug:overlay`, `pacman -Q quickshell sysstat` (live machine commands)

### Secondary (MEDIUM confidence)
- `.planning/phases/16-workspace-overview/16-CONTEXT.md` — user decisions, read selectively this session (verified pre-existing findings, not re-derived)
- `.planning/phases/13.1-hyprland-lua-config-migration/13.1-LUA-FINDINGS.md` — cited for the T-13.1-10 empirical-verification convention

### Tertiary (LOW confidence)
- `hyprland-toplevel-export-v1` protocol behavior on inactive workspaces — training knowledge, not fetched this session

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Quickshell's `Hyprland.dispatch()` requires the Lua-wrapped `hl.dsp.xxx(...)` string form on this instance, not the classic dispatcher,args string | Q3 | If wrong, every dispatch call in the plan silently fails to parse or errors — high blast radius, must be the first thing a Wave 0 spike confirms |
| A2 | `hl.dsp.window.move` table has no window/address targeting field | Q3 | If a field does exist under a different name, the plan may invent an unnecessary workaround (focus-then-move) that violates D-16-13's "silent" requirement |
| A3 | `hyprland-toplevel-export-v1` captures windows on inactive workspaces without issue | Q1, Open Question 2 | If capture fails for off-workspace windows, D-16-01's "all 10 slots always populated" needs a different fallback than the denial-only pending state D-16-10 currently covers |
| A4 | `sourceSize == 0x0` is a secondary corroborating blank-capture signal alongside `hasContent` | Q5 | Low risk — `hasContent` alone is sufficient and already verified; this is a nice-to-have, not load-bearing |

## Metadata

**Confidence breakdown:**
- ScreencopyView/Toplevel API (Q1, Q2): HIGH — read directly from installed qmltypes and working repo code this session
- Dispatch mechanics (Q3): MEDIUM/LOW — the Lua-wrapping requirement is a strong repo-evidence inference; the window-targeting field is a genuine unverified gap
- Perf measurement (Q4): HIGH on tool availability (checked directly), MEDIUM on the recommended fallback strategy (derived from D-16-07, not independently re-tested)
- Blank-tile predicate (Q5): HIGH — qmltypes read directly, no ambiguity in the property list

**Research date:** 2026-08-03
**Valid until:** re-check if `quickshell` or `hyprland` package versions change (30 days or next upgrade, whichever first)
