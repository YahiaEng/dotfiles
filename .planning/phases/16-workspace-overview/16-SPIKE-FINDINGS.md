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

## VERDICT — DECISION context for Task 3

SELECTOR-CONFIRMED is on record above; Task 3 (checkpoint) makes this
finding's `selector-confirmed` option available.
