# Phase 16 Plan 01 — Spike Findings

Live-verified answers to the four mechanisms Phase 16 depends on, gathered
against the running Hyprland 0.56.1 / quickshell 0.3.0-2 session on this host
(single monitor `DP-1`, 2560x1440@165Hz). No production QML or Hyprland
config was touched — everything here was run through `hyprctl dispatch`
against real throwaway/real clients, and through a throwaway `qs -p` harness
that never entered `quickshell/.config/quickshell/`.

## VERDICT — OVER-03 dispatch selector

**SELECTOR-CONFIRMED**

```
hl.dsp.window.move({workspace=<N>, window="address:<0x...>", follow=false})
```

- `window` is the correct field name (not `address`, `target`, or
  `selector`).
- The address value must carry the classic `address:` prefix — a bare
  `0x...` string is silently accepted (no error) but does nothing.
- `follow=false` is the correct field to keep the compositor's focused
  workspace unchanged — this is what makes the move genuinely **silent**
  per D-16-13. Without `follow=false` (or with `silent=true`, an incorrect
  guess that also silently no-ops), the move succeeds but the compositor's
  focused workspace follows the moved window, exactly the behaviour D-16-13
  forbids.

### Method

A throwaway client (`kitty --class spike-throwaway`) was spawned, then
compositor focus was moved to an empty workspace (5) so the throwaway was
neither the focused workspace nor the active window before every probe
(`reset_state()` below, run before each isolated probe). Target address:
`0x55a754f3e940`.

```bash
reset_state() {
  hyprctl dispatch "hl.dsp.window.move({workspace=1, window=\"address:$TARGET\"})"
  hyprctl dispatch "hl.dsp.focus({workspace=5})"
}
```

### Isolated field-name probes (each preceded by `reset_state`, dest workspace alternated 2/3 to avoid a stale-state false positive)

| # | Dispatched string | pre target_ws | pre active_ws | post target_ws | post active_ws | configerrors | Result |
|---|---|---|---|---|---|---|---|
| 1 | `hl.dsp.window.move({workspace=2, window="0x55a754f3e940"})` | 1 | 5 | 1 | 5 | (empty) | DID NOT MOVE |
| 2 | `hl.dsp.window.move({workspace=3, window="address:0x55a754f3e940"})` | 1 | 5 | 3 | 3 | (empty) | MOVED, but focus followed |
| 3 | `hl.dsp.window.move({workspace=2, address="0x55a754f3e940"})` | 1 | 5 | 1 | 5 | (empty) | DID NOT MOVE |
| 4 | `hl.dsp.window.move({workspace=3, address="address:0x55a754f3e940"})` | 1 | 5 | 1 | 5 | (empty) | DID NOT MOVE |
| 5 | `hl.dsp.window.move({workspace=2, target="0x55a754f3e940"})` | 1 | 5 | 1 | 5 | (empty) | DID NOT MOVE |
| 6 | `hl.dsp.window.move({workspace=3, target="address:0x55a754f3e940"})` | 1 | 5 | 1 | 5 | (empty) | DID NOT MOVE |
| 7 | `hl.dsp.window.move({workspace=2, selector="0x55a754f3e940"})` | 1 | 5 | 1 | 5 | (empty) | DID NOT MOVE |
| 8 | `hl.dsp.window.move({workspace=3, selector="address:0x55a754f3e940"})` | 1 | 5 | 1 | 5 | (empty) | DID NOT MOVE |

Only `window="address:0x..."` (probe 2) moves the target. Every other field
name, and the bare-address form of `window` itself, produces `ok` with empty
`configerrors` and **no observable effect** — an unrecognized/mis-shaped
field is silently ignored at `hyprctl dispatch` runtime, it does not error.
(This differs from — and does not contradict — 13.1-03's field-validator
discovery: that discovery covers dispatcher tables declared **inside the Lua
config file**, validated at config-load time. `hyprctl dispatch '<lua expr>'`
evaluates an ad-hoc Lua chunk at runtime and never passes through that
config-load validator. Recorded here since the plan's `<action>` explicitly
asked whether the loud-error expectation held — it does not, for this entry
point.)

### `follow`/`silent` field probe (isolated, same `reset_state` pattern)

| Dispatched string | pre target_ws | pre active_ws | post target_ws | post active_ws | Result |
|---|---|---|---|---|---|
| `hl.dsp.window.move({workspace=2, window="address:$TARGET", silent=true})` | 1 | 5 | 2 | 2 | MOVED, focus followed (silent=true has no effect) |
| `hl.dsp.window.move({workspace=3, window="address:$TARGET", follow=false})` | 1 | 5 | 3 | 5 | **MOVED SILENTLY** — target workspace changed, focused workspace stayed 5 |
| `hl.dsp.window.move({workspace=2, window="address:$TARGET", noFollow=true})` | 1 | 5 | 2 | 2 | MOVED, focus followed (noFollow has no effect) |

`follow=false` was then **re-confirmed** in a second independent run
(different destination workspace, 4): pre `target_ws=1 active_ws=5`, post
`target_ws=4 active_ws=5` — reproduced.

### Control (distinguishes "the selector worked" from "the dispatcher acted on the right window anyway")

With the target on workspace 1, focus moved to the empty workspace 5 (no
active window — `hyprctl activewindow -j` returns null), a **plain move with
no selector at all** was dispatched:

```
hl.dsp.window.move({workspace=6})
```

Result: `ok`, `configerrors` empty, but **the target did not move** (stayed
on workspace 1) and `hyprctl clients -j` afterward shows all three real
clients unchanged in place. This proves the field-name/`follow` results
above are not an artifact of the dispatcher defaulting to "the last active
window" — there was no active window to default to, and nothing moved
without an explicit `window="address:..."` selector.

### Final confirmed dispatch string (the literal form 16-06's drop handler consumes)

```
hl.dsp.window.move({workspace=<targetWorkspaceId>, window="address:" + draggedWindow.address, follow=false})
```

### Incident during this task, disclosed in full

While cleaning up, `hyprctl dispatch "hl.dsp.window.kill()"` was run intending
to close the throwaway `spike-throwaway` client. **It did not target the
throwaway** — the compositor's "last active window" pointer at that moment
was still the real Zen browser window (`0x55a754ea02d0`, the tab open before
this task started), even though the focused workspace was the empty
workspace 5 and `hyprctl activewindow -j` had reported `null` moments
earlier. `kill()` with no explicit selector closed that Zen process
entirely.

**Recovery performed:** Zen (`zen-browser`) was relaunched
(`uwsm app -- zen-browser`); its session restore brought back the exact same
tab (title byte-identical: "Minecraft Season 3 Start (Part 1) - YouTube —
Zen Browser"). The restored window was then moved back to workspace 1 using
the now-confirmed silent-move dispatch
(`window="address:<new-addr>", follow=false`) and workspace 1 was
refocused, matching the original layout functionally (same tab, same
workspace, same focus) though not by literal PID/window address.  The
throwaway client was then closed by sending `kill` directly to its PID
(`hyprctl clients -j`'s `.pid` field), not via `hl.dsp.window.kill()`,
avoiding a repeat.

**This is a load-bearing finding for plan 16-06 and any future dispatch
work, not just an incident report:** `hl.dsp.window.kill()` (and by
extension any dispatcher relying on the implicit "active window" with no
explicit selector) can act on a window that is not visibly focused and not
reported as the active window by `hyprctl activewindow -j` at the moment of
dispatch — Hyprland retains an internal last-focused pointer across a
focus-to-empty-workspace transition. **Any dispatcher call from Phase 16 QML
that does not explicitly pass a `window="address:..."` selector must not be
assumed to be a no-op just because no window is visibly active.**

## VERDICT — keyboard focus posture

**ONDEMAND-SUFFICIENT**

A throwaway `qs -p` harness (scratchpad only, never
`quickshell/.config/quickshell/`) reproduced `ScreencopyProbe.qml`'s D-43
layer posture verbatim (`WlrLayershell.layer: WlrLayer.Overlay`,
`WlrLayershell.namespace: "quickshell-spike"`,
`WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand`,
`exclusiveZone: 0`), with an `Item { focus: true }` content root and
`Component.onCompleted: content.forceActiveFocus()` — the exact mechanism
`Dashboard.qml` already ships in production (`modules/Dashboard.qml:462-464`,
comment: "`forceActiveFocus()` is required for the key handlers above to
actually receive events under `WlrKeyboardFocus.OnDemand`").

The harness was launched with `qs -p spike.qml` and **no click was ever
made** — `wtype -k Left`, `wtype -k Up` and `wtype -k Escape` were sent
immediately from the same terminal that launched it. `qs`'s stderr:

```
DEBUG qml: SPIKE forceActiveFocus called, activeFocus=false
INFO: Configuration Loaded
... (later, after wtype -k Left)
DEBUG qml: SPIKE key=Left
... (after wtype -k Up)
DEBUG qml: SPIKE key=Up
... (after wtype -k Escape)
DEBUG qml: SPIKE key=Escape
```

All three arrow/Escape presses reached the surface's key handlers with zero
prior pointer interaction, under `WlrKeyboardFocus.OnDemand`. **No escalation
to `WlrKeyboardFocus.Exclusive` was needed or attempted.**

### Click-outside dismiss result

**Not mechanically reproducible in this spike** — this host has no pointer
synthesizer (`ydotool`, `wlrctl`, `dotool` all absent; `wtype` is
keyboard-only via the virtual-keyboard protocol, confirmed by `command -v`
returning nothing for all three). A synthetic proxy was tried
(`hyprctl dispatch "hl.dsp.focus({workspace=2})"` while the harness was
open, to move compositor focus elsewhere programmatically) and it did
**not** trigger `HyprlandFocusGrab.onCleared` — the layer surface stayed
alive (`hyprctl layers -j` still listed `quickshell-spike` afterward). This
confirms the grab is watching for an actual pointer click, not a
programmatic focus change, so the proxy cannot stand in for the real
test.

**Recorded as inherited, previously-verified evidence instead:** this exact
combination (`WlrKeyboardFocus.OnDemand` + `HyprlandFocusGrab` bound to the
surface, `onCleared` → dismiss) is not new to this phase — it is the
identical mechanism Phase 11's QS-02 gate human-verified live
(`11-QUICKSHELL-EVIDENCE.md`), and it is what `Dashboard.qml` and
`ScreencopyProbe.qml` both already ship and exercise in daily use via
`Super+D` / `Super+Shift+K` on this exact build. No fresh regression is
plausible from reusing the identical pattern a third time. This is recorded
as **inherited-verified, not freshly reproduced in this spike** — flagged
explicitly rather than silently assumed, per the acceptance criterion.

## VERDICT — Qt drag on layer-shell

**DECLARATIVE-LOADS**

The same throwaway harness added a source `Rectangle` with `DragHandler`
plus the `Drag` attached property (`Drag.active`, `Drag.hotSpot`,
`Drag.keys`) and a target `DropArea` with `onEntered`/`onExited`/`onDropped`
logging, both as children of the `Item{focus:true}` content root inside the
`PanelWindow` (D-43 layer posture, same as above).

`qs`'s stderr across the full run (from launch through both live-reload
iterations while fixing an unrelated capture-probe bug, to final shutdown),
grepped for any error/warning mentioning drag, DropArea, or any QML
error/warning of any kind:

```
$ grep -in "drag\|droparea\|warn\|error" spike-stderr.log
(no output)
```

Zero QML errors or warnings of any kind were produced by declaring
`DragHandler` + `Drag` attached property + `DropArea` inside a
`WlrLayer.Overlay` / `WlrKeyboardFocus.OnDemand` `PanelWindow`. The layer
surface itself (`hyprctl layers -j` → `quickshell-spike`) stayed live and
correctly posted the whole time. This is the mechanical evidence the task
requires; per the task's own scope, live drag-gesture behaviour (actually
dragging the rectangle into the DropArea and observing `onEntered`/
`onDropped` fire) is **not exercised here** — this host has no pointer
synthesizer (see above), so that half is deferred to a human exercising it
directly, as the plan's own `<action>` anticipates ("exercised by hand at
Task 3's checkpoint if it cannot be driven any other way").

## VERDICT — inactive-workspace capture

**CAPTURES-OFFSCREEN**

A real client (a pre-existing `kitty` window, address `0x55a7538e49d0`,
parked on workspace 2) was targeted while the compositor's visible/active
workspace on the only monitor (`DP-1`) stayed workspace 1
(`hyprctl monitors -j` → `activeWorkspace.id: 1` for the whole test — workspace
2 was never brought into view). The harness located it via
`Hyprland.workspaces`/`Hyprland.toplevels` (grouping by `t.workspace.id`,
matching class read from `t.lastIpcObject["class"]` — see the API-surface
note below) and bound `ScreencopyView.captureSource: <toplevel>.wayland`
with `live: true`. A 1s-repeating `Timer` logged `hasContent` and
`sourceSize`:

```
DEBUG qml: SPIKE capture hasContent=true sourceSize=QSize(2534, 1368) captureSource=qs::wayland::toplevel_management::Toplevel(0x7f255f2e6490) at 2026-08-03T15:08:51.559Z
DEBUG qml: SPIKE capture hasContent=true sourceSize=QSize(2534, 1368) captureSource=qs::wayland::toplevel_management::Toplevel(0x7f255f2e6490) at 2026-08-03T15:08:52.560Z
DEBUG qml: SPIKE capture hasContent=true sourceSize=QSize(2534, 1368) captureSource=qs::wayland::toplevel_management::Toplevel(0x7f255f2e6490) at 2026-08-03T15:08:53.560Z
```

(and continuously for the remainder of the run — `hasContent` never
reverted to `false` once content arrived). `hyprctl monitors -j` re-checked
immediately after: `DP-1 active=1` — workspace 2 was confirmed never visible
during capture. This answers 16-RESEARCH.md's Open Question 2 and A3
affirmatively: `hyprland-toplevel-export-v1` captures a toplevel parked on
an inactive workspace with no special handling required, confirming D-16-01's
"all 10 slots always rendered" needs no additional inactive-workspace
fallback beyond D-16-10's existing pending/denied states.

**API-surface correction found while building the harness (recorded since
it affects how plan 16-02+ must read window identity):**
`HyprlandToplevel` (`qs::hyprland::ipc::HyprlandToplevel`, read directly from
`/usr/lib/qt6/qml/Quickshell/Hyprland/_Ipc/quickshell-hyprland-ipc.qmltypes`)
has **no `class`/`appId` property of its own** — only `address`, `handle`,
`wayland`, `title`, `activated`, `urgent`, `lastIpcObject`, `workspace`,
`monitor`. The window's class must be read from
`toplevel.lastIpcObject["class"]` (the raw `hyprctl clients` JSON map;
`class` is a reserved word in QML/JS so bracket notation is required, not
`t.class`). This corrects an implicit assumption nothing in 16-CONTEXT.md or
16-RESEARCH.md called out explicitly — both only listed `HyprlandToplevel`'s
real properties without noting `class`/`appId` are absent from that list on
this qmltypes build, and a first draft of this harness silently read
`undefined` for every window's class before this was caught.

## Harness cleanup confirmation

```
$ pgrep -fa "qs -p.*spike"        # (no output — process stopped)
$ git status --porcelain quickshell/   # (no output — shipped tree untouched)
$ find quickshell/.config/quickshell -iname 'spike*'   # (no output)
```

## DECISION context for Task 3

Task 1 recorded **SELECTOR-CONFIRMED** — the `selector-confirmed` option is
available per Task 3's own option list.

## DECISION — OVER-03 move mechanism

**Selected: `selector-confirmed`.**

The dispatch string plan 16-06's drop handler implements verbatim:

```
hl.dsp.window.move({workspace=<targetWorkspaceId>, window="address:" + draggedWindow.address, follow=false})
```

**Rationale:** live-verified with an isolated before/after probe matrix plus
a control that proves the selector was necessary (not incidental — see
"VERDICT — OVER-03 dispatch selector" above). One dispatch, no focus change,
no restore step — D-16-13's "silent" requirement is honoured exactly as
written, not approximated. The two fallback options (`activate-move-restore`,
`record-divergence`) existed only for the case where no working selector was
found on this build; that case did not occur, so neither is needed.
