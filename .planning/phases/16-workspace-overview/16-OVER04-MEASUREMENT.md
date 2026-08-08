# OVER-04 — Live-capture performance measurement

**Taken:** 2026-08-08
**Plan:** 16-08, Task 1 (measurement) and Task 2 (verdict)

## Host and versions (read live)

| | |
|---|---|
| Monitor | `DP-1` — 2560x1440 @ 165.00 Hz, scale 1.0 |
| Hyprland | 0.56.1 (branch v0.56.1, commit 5c9377c15f85c50648f35ca5a213754f95b93ca0, clean) |
| quickshell | 0.3.0-2 |
| CPU metric | `%CPU` from `top` batch mode, quickshell PID only. 100% = one full core. |

Measured against Hyprland 0.56.1 and quickshell 0.3.0-2.

Read via `hyprctl version`, `pacman -Q quickshell`, `hyprctl monitors -j`.

## Load

Asserted from `hyprctl clients -j` before any sample was kept, and **re-asserted at
sample time** inside the Condition B runner rather than trusted from arm time:

```
mapped windows: 12   numbered workspaces: [1, 2, 3, 4, 5]   floor met: True
```

Budget floor is at least 8 windows across at least 3 workspaces. Composition: one
browser playing video (continuously-changing content), one terminal running a 5 Hz
clock, the session terminal, and nine idle terminals.

## Budget (D-16-08)

| Term | Threshold | Measured |
|---|---|---|
| FPS floor | ≥ 60 fps under every condition | **UNMEASURED** — see below |
| FPS target | at or near 165 fps | **UNMEASURED** — see below |
| Shell CPU | under half of one core (< 50%) | **20.9% worst case** ✅ |

### Why the FPS terms are unmeasured, and why they were not retried

16-RESEARCH.md Q4 names the compositor's frame-time/FPS debug overlay as the only
FPS instrument available on this host. Enabling it via the correct
`hyprctl eval` + `hl.config({ debug = { overlay = true } })` form, on top of the
overview with 11 live captures, **froze the machine hard enough to require a
physical restart.** Hyprland's IPC stopped responding to every subsequent request,
including the one that would have turned the overlay back off.

The instrument is therefore not safe to run against this surface at the budget's
own load floor, and it was not retried — a second forced restart is a real cost to
pay for a number. The FPS terms are recorded as unmeasured rather than estimated,
guessed, or quietly dropped.

Qualitative note, offered as exactly that and not as a substitute: Condition B was
a 20-second sustained human-driven drag, performed without the operator reporting
stutter or input lag. That is evidence the surface is usable; it is **not** evidence
that it holds 60 fps, and nothing here should be read as claiming the FPS floor was
verified.

## Results

First `top` iteration is excluded from every statistic: in batch mode it reports an
average since process start, not an instantaneous sample. Including it would bias
every condition toward the same value regardless of load — visible in the raw data,
where three separate runs all open with 14.9%.

| Condition | n | mean | peak | min | vs 50% ceiling |
|---|---|---|---|---|---|
| Baseline — overview closed | 6 | 0.0% | 0.0% | 0.0% | ✅ zero-idle confirmed |
| A — grid at rest | 9 | 13.8% | 16.0% | 13.0% | ✅ 3.1× headroom |
| B — grid during drag (peak load) | 19 | 18.4% | 20.9% | 11.9% | ✅ 2.4× headroom |
| B — drag, sustained portion only | 11 | 19.7% | 20.9% | 18.9% | ✅ 2.4× headroom |
| C — grid over fullscreen client | 9 | 13.7% | 16.0% | 11.0% | ✅ 3.1× headroom |

The overlay-off control the plan asks for is **every row above** — the FPS
instrument was never successfully in play, so no row carries its cost. That is the
one silver lining of the freeze: no measurement here is contaminated by the
instrument.

Condition B's ramp is visible and expected: the drag had not begun when sampling
opened. The sustained-portion row is the honest read of the peak.

## ⚠ A discarded run, recorded because it nearly produced a false verdict

A first attempt used three terminals each running `while :; do date +%s.%N; done` —
a busy loop redrawing flat out. Under that load quickshell measured:

```
263.3  263.6  252.4  272.8  273.7  277.4  284.0  241.9  265.8  261.7
                                        n=9  mean=265.9%  peak=284.0%
```

**265% — a 5.3× budget miss that would have triggered the ladder.** It is an
artifact of the load generator, not of the shell: three terminals redrawing at
maximum rate force constant recapture. The realistic load measures **~14%**, a 19×
difference from the same code on the same host.

The plan's precondition asserts a *minimum* window count, which correctly prevents a
too-easy measurement. Nothing guarded the other end — a load harsh enough to
manufacture a failure. Recorded here so the next reader does not repeat it, and as
the reason the discarded run is preserved rather than deleted.

## Commands (verbatim, rerunnable)

```sh
# Versions / host
hyprctl version | head -1
pacman -Q quickshell
hyprctl monitors -j

# Load floor assertion
hyprctl clients -j | python3 -c "
import json,sys
c=[x for x in json.load(sys.stdin) if x.get('mapped')]
ws=sorted({x['workspace']['id'] for x in c if x['workspace']['id']>0})
print(len(c), ws, len(c)>=8 and len(ws)>=3)"

# CPU sampling (10 x 1s against the shell PID; pidstat is not installed here)
QS=$(pgrep -x quickshell | head -1)
top -b -d 1 -n 10 -p "$QS" | grep -E "^ *$QS" | awk '{print $9}'

# Summon / dismiss and state readback
qs ipc call overview toggle
qs ipc call overview status

# Condition C — true fullscreen. NOTE: hl.dsp.fullscreen() does not exist and
# errors; the working form is the one keybinds.lua line 70 uses.
hyprctl dispatch 'hl.dsp.window.fullscreen(0)'

# The FPS overlay form that IS correct for this Lua-configured compositor.
# The `keyword` sub-command is a silent no-op on this instance (Phase 13.1
# finding) and must never be used for it.
# DO NOT RUN AT THIS LOAD — it froze the host and required a physical restart:
#   hyprctl eval 'hl.config({ debug = { overlay = true } })'
```

Overlay state confirmed `false` after the restart and at the end of this
measurement: `hyprctl getoption debug:overlay` → `bool: false`.
No `over04-load` / `over04-anim` client remains open.

## Raw samples

```
Baseline — overview closed (6 x 1s)
0.0
0.0
0.0
0.0
0.0
0.0

Condition A — grid at rest (10 x 1s; first excluded from stats)
14.9
13.0
13.0
13.0
13.0
15.0
16.0
13.0
14.0
14.0

Condition B — grid during sustained human-driven drag (20 x 1s; first excluded)
5.0
11.9
14.9
15.9
15.9
16.9
17.9
18.9
20.0
18.9
18.9
18.9
19.9
19.9
19.9
19.9
19.9
18.9
20.9
20.9

Condition C — grid over true fullscreen client (10 x 1s; first excluded)
14.9
11.0
14.0
14.0
13.0
16.0
14.0
14.0
14.0
13.0

DISCARDED — pathological load, three busy-loop terminals (10 x 1s; first excluded)
263.3
263.6
252.4
272.8
273.7
277.4
284.0
241.9
265.8
261.7
```

Condition B load floor, re-asserted at sample time by the runner:

```
windows=12 workspaces=5
```

---

## VERDICT — OVER-04

**INSIDE-BUDGET** — on the CPU term, which is the only term this host could measure
safely. The FPS floor and target are recorded above as UNMEASURED, and this verdict
does not claim them.

Shell CPU stays under half of one core under all three conditions, with the worst
observed value — 20.9%, during a sustained drag with twelve windows across five
workspaces — leaving **2.4× headroom** against the 50% ceiling. At rest and over a
fullscreen client it sits near 14%, roughly 3.1× headroom. With the overview
dismissed the shell returns to 0.0%, confirming the zero-idle doctrine holds.

### Ladder rung reached: **none**

No code was changed by Task 2. `git diff --stat` for `WindowThumbnail.qml` and
`windowrules.lua` is empty for this task.

D-16-07's ladder is triggered by a demonstrated miss, and there is none: the
measured term passes with margin, and the unmeasured terms are unmeasured rather
than failed. The plan is explicit that descending on anything less "would trade live
thumbnails for a number rather than for a visible problem", and the same logic
forbids descending for a number that could not be taken. Rung 1 in particular would
have removed the frosted-glass treatment approved at 16-07's render gate, and the
measurement gives no reason to pay that.

Live capture ships for all eleven tiles, baked in at build time per D-16-11. No
runtime capture-mode toggle exists — `qs ipc show` lists only `overview.toggle` and
`overview.status`.

### Standing caveat for a future reader

The ladder's own costing assumed this surface carried a full-screen blur "roughly
five times the blur region of any panel". That is **no longer true**: plan 16-07
removed the full-bleed scrim, so only the eleven tiles are blurred. Rung 1 would
therefore buy considerably less than D-16-07 anticipated, and the dominant cost here
is the concurrent capture streams rather than the blur. Anyone re-running this after
a regression should weigh rung 2 (live only where it is being looked at) ahead of
rung 1, and record the reordering as a deviation — as this measurement would have
done had a rung been needed.

This verdict is valid for the versions recorded at the top of this file. A quickshell
or Hyprland bump, a higher-refresh or higher-resolution monitor, or a materially
larger window count all invalidate it.
