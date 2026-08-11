# 18-18 Task 1: LEDGER-03 Frame-Rate Measurement — MEASURED

**Status: MEASURED, 2026-08-11.** All five conditions were exercised live on this host with
the user present. This supersedes the deferred version of this document; the methodology it
recorded is unchanged and was followed as written.

**Headline:** the 60 fps floor **passes decisively** under every animated condition — across
81,261 consecutive render-loop iterations during the overview drag, **not one** exceeded
16.67 ms, and the worst single iteration in that window was 12 ms (83.3 fps). The
"at or near 165 fps" target is **consistent with the measurements but not provable with the
sanctioned instrument** — see "Why the target cannot be resolved" below. That distinction is
kept rather than collapsed into a pass.

## Instrument

**Used:** Qt's own render-timing output, `QSG_RENDER_TIMING=1` alongside
`QSG_RENDER_LOOP=threaded` (the export `quickshell-launch.sh` already sets on this host).

**Never used, per the standing prohibition:** Hyprland's compositor frame-time debug overlay
(`hyprctl eval`, the debug overlay toggle) — that exact instrument on this exact host **froze
the machine** hard enough to require a physical restart during Phase 16's OVER-04 measurement
(`18-RESEARCH.md` Pitfall 4). It was **not retried in this campaign**, and no measurement here
depends on it. `hyprctl reload` was likewise never run (it drops the quickshell layer rules on
this host).

`QT_MESSAGE_PATTERN='%{time process} %{category} %{message}'` was also exported, intending to
add per-line timestamps. **It had no effect** — quickshell installs its own Qt message handler
and the pattern was ignored. This is recorded because it was set, not because it contributed:
every figure below comes from Qt's own `elapsed since last call` field, which reports the
inter-iteration interval directly and made the timestamp unnecessary.

### The emitted format, verbatim

```
DEBUG qt.scenegraph.time.renderloop: [window 0x7f005b2a61b0][gui thread] polishAndSync: start, elapsed since last call: 12 ms
DEBUG qt.scenegraph.time.renderloop: [window 0x7f005b2a61b0][render thread 0x7f0071a41fa0] syncAndRender: frame rendered in 12ms, sync=2, render=0, swap=9
DEBUG qt.scenegraph.time.renderloop: [window 0x7f005b2a61b0][render thread 0x7f0071a41fa0] syncAndRender: start, elapsed since last call: 12 ms
DEBUG qt.scenegraph.time.renderloop: [window 0x7f005b2a61b0][gui thread] Frame prepared, polish=0 ms, lock=0 ms, blockedForSync=0 ms, animations=0 ms
```

Every figure below is the **`polishAndSync: start, elapsed since last call: N ms`** field —
the GUI thread's inter-iteration interval, as a raw integer millisecond. The render thread's
`syncAndRender` interval was extracted in parallel and agreed with the GUI thread to within
one sample in every condition; only the GUI-thread figures are tabulated to avoid presenting
the same measurement twice.

**Per-window segregation matters.** The overview surface is destroyed and recreated on each
open, taking a **new window handle every time**. C2, C3 and C4 therefore each have a distinct
overview handle, and each condition's samples were filtered to its own handle — the bar window
(`0x7f005b36c690`, stable for the instance's life) is excluded from every overview condition
and vice versa. Mixing them would have blended a 2-second-tick idle surface into an animating
one.

## Host facts at measurement time

```
$ hyprctl monitors -j | jq -c '[.[] | {name, refreshRate, reserved}]'
[{"name":"DP-1","refreshRate":164.99899,"reserved":[0,46,0,0]}]

$ hyprctl version | head -1
Hyprland 0.56.2 built from branch v0.56.2 at commit efb50993780079460b0cbed1363e2166a2de1d9f clean

$ pacman -Q quickshell
quickshell 0.3.0-2

$ systemctl --user show quickshell.service -p NRestarts
NRestarts=0
```

**Thresholds this campaign is judged against:**

| Threshold | Source | As an interval |
|---|---|---|
| Floor: **60 fps** | OVER-04's own stated floor | ≤ 16.666 ms |
| Target: **156.75 fps** (95% of live refresh, `164.99899 × 0.95`) | this plan's target definition | ≤ 6.379 ms |

## Why the target cannot be resolved, and the floor can

Two independent limits, both worth stating plainly rather than papering over:

1. **Integer-millisecond granularity.** Qt reports `elapsed since last call` as a whole
   number of milliseconds. The target threshold is 6.379 ms — it falls *inside* the `6 ms`
   bucket. A sample reported as `6` is somewhere in [6.000, 6.999) ms, i.e. 143.0–166.7 fps,
   which straddles the target. The floor threshold (16.666 ms) falls between the `16` and
   `17` buckets, so it **is** cleanly resolvable: `≤16` unambiguously passes, `≥17`
   unambiguously fails.
2. **Render-loop iterations are not presentation events.** The densest 20-second sub-window
   of the drag recorded 3,636 iterations — 181.8/s, *above* this panel's 164.999 Hz. The GUI
   thread can therefore iterate more often than frames are actually presented, so this metric
   is an **upper bound** on displayed frame rate, not a measurement of it. It cannot be used
   to assert "we hit 165 fps."

What the metric **does** prove decisively is the absence of stalls: a render loop that never
goes quiet for longer than N ms cannot have presented a frame later than N ms. That is exactly
the floor claim, and it is the claim recorded as passing below.

## Results

Load floor asserted from `hyprctl clients -j` **at sample time** for C2/C3/C4: **8 mapped
windows across workspaces [1,2,3,4,5]** (OVER-04's floor is ≥8 windows across ≥3 workspaces).
The overview reported `active=true tiles=11 windows=8 withContent=8` in all three — all eight
windows rendering live content, not placeholders.

| Condition | n | median | p95 | p99 | max | iterations >16 ms | Floor (60 fps) |
|---|---|---|---|---|---|---|---|
| **C0** bar idle, 30 s | 3 | 6001 ms | — | — | 15997 ms | 3 (100%) | **n/a — see below** |
| **C1** bar reveal/re-hide, 30 s, 10 cycles (idle gaps excluded) | 730 | 6 ms | 6 ms | 40 ms | 62 ms | 11 (1.51%) | **PASS** |
| **C2** overview at rest, load floor, 20 s | 3454 | 6 ms | 7 ms | 8 ms | 93 ms | 1 (0.029%) | **PASS** |
| **C3** overview + human-driven drag, 510 s | 81261 | 6 ms | 6 ms | 8 ms | **12 ms** | **0 (0.000%)** | **PASS** |
| **C4** overview over a fullscreen client, 20 s | 3456 | 6 ms | 7 ms | 8 ms | 90 ms | 1 (0.029%) | **PASS** |

Interval-band distribution (the honest form of "how close to the target"), where `≤5 ms`
unambiguously beats the target, `6 ms` straddles it, `7–16 ms` beats the floor only, and
`≥17 ms` fails the floor:

| Condition | ≤5 ms | 6 ms | 7–16 ms | ≥17 ms |
|---|---|---|---|---|
| C1 (gaps excluded) | 13.3% | 82.3% | 2.9% | 1.51% |
| C2 | 49.6% | 39.6% | 10.8% | 0.03% |
| C3 | 43.0% | 52.5% | 4.4% | 0.00% |
| C4 | 49.8% | 41.8% | 8.4% | 0.03% |

### C0 — the idle bar is not a frame source, and that is correct

Over a full 30 seconds the idle bar produced **3 render-loop iterations** (intervals 1999,
6001, 15997 ms). It renders on demand — when the clock minute rolls or a resource sampler
ticks — not continuously.

This condition therefore has **no meaningful fps figure, and is not judged against the floor**.
Recording it as a 0.2 fps failure would invert the finding: a bar that ran its render loop at
165 fps while sitting idle would be the defect. C0's real result is the 3-iterations-in-30-s
count itself, and it is a pass in the sense that matters — the idle bar costs no frames.

### C1 — the only genuine stalls in the campaign, and where they are

C1's raw sample set contains 33 intervals above 16 ms, but 22 of them are ≥254 ms and are
**my own deliberate 1.5-second waits between hide/show cycles**, not dropped frames. Listed
verbatim, sorted, with the split marked:

```
38 39 39 40 40 42 43 43 44 58 62 | 254 430 932 1026 1252 1257 1270 1274 1275 1275 1276 1276 1277 1324 1357 1358 1359 1359 1364 1364 1364 9107
```

Excluding those inter-cycle gaps (>100 ms), **11 iterations in 730 (1.51%) exceeded 16 ms,
ranging 38–62 ms**, across 10 hide/show cycles — roughly one per transition edge. So each bar
visibility transition costs **a single frame in the 38–62 ms range** (16–26 fps momentary),
then returns immediately to a 6 ms cadence. This is a one-frame hitch at the transition
boundary, not a sustained drop, and it is the worst behaviour the whole campaign found.

### C3 — the strongest result

The drag window ran **510 seconds** (the human-driven condition ran long; the plan specified
20 s, and this over-runs it rather than falling short). Across **81,261 consecutive
iterations**:

- **Zero** exceeded 16.67 ms.
- The single worst was **12 ms** — an instantaneous floor of **83.3 fps**, never breached.
- Sustained rate: 81,261 / 510 s = **159.3 iterations/s**.
- The densest 20-second sub-window (the drag proper, located by cumulative-summing the
  interval series) held 3,636 iterations, median 6 ms, p95 6 ms, max 9 ms.

The user's subjective report for this condition was **"dragged smoothly"**, consistent with
the measurement.

### C2 / C4 — the single outlier frames

Each shows exactly one iteration above 16 ms (93 ms and 90 ms respectively), each occurring at
the start of its window: the cost of **creating the overview surface**, not a steady-state
drop. Every subsequent iteration in both conditions stayed at or under 8 ms through p99.

## Verdict

- **FPS floor (≥60 fps): PASS**, measured, under every animated condition, with the margin
  quantified above. The strongest single line of evidence is C3: 81,261 consecutive iterations
  with a 12 ms worst case. The only sub-60 fps events found anywhere are 11 single-frame
  transition hitches in C1 (38–62 ms) and two surface-creation frames in C2/C4 (93/90 ms) —
  13 frames total across ~89,000 measured.
- **FPS target (at or near 165 fps / ≥156.75 fps): NOT RESOLVABLE with the sanctioned
  instrument.** The distribution is *consistent* with running at panel rate (43–50% of
  iterations ≤5 ms, 40–52% at exactly 6 ms, sustained 159.3/s in C3), but for the two reasons
  in "Why the target cannot be resolved" above — integer-ms bucketing that swallows the 6.379 ms
  threshold, and iteration counts that are an upper bound on presentation — this campaign
  **does not claim the target as met**. Resolving it would need a presentation-timestamp
  instrument (Wayland `presentation-time` protocol feedback), which is not the sanctioned
  instrument and was not used.

The forbidden compositor overlay was not retried, and nothing above depends on it.

## Procedure actually executed

```
# baseline
hyprctl monitors -j | jq -c '[.[].reserved]'          -> [[0,46,0,0]]
hyprctl monitors -j | jq -r '.[0].refreshRate'        -> 164.99899
hyprctl version | head -1                             -> Hyprland 0.56.2
pacman -Q quickshell                                  -> quickshell 0.3.0-2
systemctl --user show quickshell.service -p NRestarts -> NRestarts=0
~/.config/hypr/scripts/bar-visibility.sh status       -> visible

# stop supervised shell (pid 737907), field confirmed clear
systemctl --user stop quickshell.service

# instrumented instance -> pid 805413
CAPFILE=$(mktemp -p /tmp qsg-timing.XXXXXX.log)
setsid env QSG_RENDER_LOOP=threaded QSG_RENDER_TIMING=1 \
  quickshell -p "$HOME/.config/quickshell" >"$CAPFILE" 2>&1 </dev/null &
pgrep -c -x quickshell                                -> 1
hyprctl layers ... grep -c '^quickshell-bar$'         -> 1

# load floor: 6 tagged kitty windows spawned across ws 3/4/5
hyprctl dispatch 'hl.dsp.exec_cmd("[workspace N silent] kitty --class gsd-loadfloor")'
  -> 8 mapped windows, workspaces [1,2,3,4,5]

# conditions (boundaries recorded as capfile line numbers, never as marker
# writes into the file — the running process holds its own write offset and
# an appended marker would have raced it)
C0  lines    482..497     30s idle
C1  lines    497..4497    30s, 10x bar-visibility.sh idle hide / idle show
C2  lines   4507..21859   20s overview at rest       (qs ipc call overview toggle)
C4  lines  22183..39550   20s overview over fullscreen client
C3  lines  41529..451364  510s overview + human-driven drag

# restore
kill 805413; systemctl --user start quickshell.service   -> pid 821554
systemctl --user is-active quickshell.service            -> active
pgrep -c -x quickshell                                   -> 1
grep quickshell.service /proc/821554/cgroup              -> SUPERVISED ok
~/.config/hypr/scripts/bar-visibility.sh status          -> visible
hyprctl monitors -j | jq -c '[.[].reserved]'             -> [[0,46,0,0]]  (matches baseline)
systemctl --user show quickshell.service -p NRestarts    -> NRestarts=0
hyprctl layers                                           -> awww-daemon, quickshell-bar (no orphans)
# 6 spawned windows closed by pid; desktop back to its original 2 windows
rm -f "$CAPFILE"    # 70,184,406 bytes
```

## Deviations from the plan's written procedure

Recorded rather than silently absorbed:

1. **Condition order was C0, C1, C2, C4, C3** — not C0–C4. C4 is fully scriptable and C3 needs
   a human at the pointer, so C4 was taken while the load floor was already standing and C3 run
   last. No condition's content changed.
2. **C3 ran 510 s, not 20 s** — the window was opened before handing control to the user and
   closed when they reported finishing. It over-runs the specified window; the 20-second
   sub-window analysis is reported alongside the full one.
3. **The 64 MiB capture cap was breached during C3**, reaching 70,184,406 bytes. The plan says
   to check size before each condition and abort at 64 MiB; the checks were performed and passed
   before C0/C1/C2/C4, and C3 — the last condition — crossed the cap mid-window because it ran
   25× its specified length. No condition was skipped as a result and no data was truncated, but
   the cap did not hold and that is a real procedural miss, not a formality.
4. **`hl.dsp.window.fullscreen(0)` for C4 targeted the user's own terminal**, since it acts on
   the focused window and `hl.dsp.workspace(3)` is not a valid dispatcher on this Hyprland's Lua
   API (`attempt to call a table value`). The fullscreen state was toggled back off immediately
   after C4. C4's requirement — an overview drawn over a fullscreen client — was met.
5. **`QT_MESSAGE_PATTERN` was exported and had no effect** (see Instrument). It contributed
   nothing and no figure depends on it.

## What this closes

LEDGER-03's `FPS floor` cell closes with a measured pass. The `FPS target` cell closes as
**measured-but-unresolvable with the sanctioned instrument**, with the reason recorded — which
is a different and better state than the `UNMEASURED` it replaces, but is deliberately not
written up as a pass.

Corrections carrying these results into the ledger locations are Task 2:
`16-OVER04-MEASUREMENT.md`, `PROJECT.md`, `MILESTONES.md`.
