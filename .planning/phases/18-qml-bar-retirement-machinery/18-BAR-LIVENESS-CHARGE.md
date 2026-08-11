# 18-08: The Bar's Permanent-Liveness Charge

The number this document turns into something diffable: what does the bar
cost, every second of every session, purely because it exists — before
anyone opens a drawer, a panel or a popout?

## What changed and why it is structurally new

Every Quickshell surface this repo has shipped through Phase 17 is
summon-on-demand and disposable: a `LazyLoader` mounts it on `active` and
tears it down on dismiss, and every backend's gate (`drawerOpen`/
`panelOpen`) tracks that same `active` flag, so the backend's timers,
subprocesses and trackers all go idle the instant the surface closes. The
bar is the first surface in this repo's history with no dismissed state —
it is a `PanelWindow` reserving space on an edge for the life of the
session. 18-05 widened three backend gates (`SystemResources`,
`AudioBackend`, `MediaBackend`) so this plan's two capsules would have live
data, which means those three gates are now the first in this repo that
never go false. This is a deliberate, decided cost (D-18-10's locked
capsule split, 18-05's own comment block beside the widened gates), not a
defect — and it is written down here, per-backend and with real numbers,
because an always-on subscription that only appears as a side effect of
wiring is unattributable afterwards. 18-18's QBAR-11 soak needs a number to
subtract from; this is that number.

## Pre-widening baseline (for scale)

From `18-BAR-IDLE-BASELINE.md` (captured 18-01, tracer scope, before any
gate was widened): RSS **445104 KiB** (~435 MiB), **1** `quickshell`
process, **0** child processes, **0** `Timer {` blocks in `Bar.qml` itself.
`$ ps -o rss=,vsz=,etime= -p "$(pgrep -x quickshell)"` and
`$ pgrep -c -x quickshell` / `$ pgrep -P "$(pgrep -x quickshell)" | wc -l`
are the exact commands that produced those four numbers; 18-18 diffs
against them, not against this document's own snapshot below (which is a
mid-phase reading, not a controlled before/after pair — see the
Measurement Brief).

## Per-backend charge — the three gates 18-05 widened

| Backend | Gate expression (`shell.qml`, 18-05) | What now runs permanently | Measured idle cost |
|---|---|---|---|
| `SystemResources` | `dashboardLoader.active \|\| barInstance.requiresResources` — `requiresResources` is `true` from this plan onward since the bar's entry list is complete | Fast sampler (`fastTimer`, `interval: root.fastPollInterval`): CPU/memory/network parsed from `/proc/stat`/`/proc/meminfo`/`/proc/net/dev` via blocking `FileView` reads — no subprocess. Slow sampler (`slowTimer`, `interval: root.slowPollInterval`): one `df -B1 --output=size,used /` child per tick. GPU sampler (`gpuSampleTimer`, `interval: root.gpuPollInterval`): one `nvidia-smi --query-gpu=... ` child per tick — **this host has a real NVIDIA GPU** (`lspci`: `NVIDIA Corporation GA104 [GeForce RTX 3070]`, `nvidia-smi` present at `/usr/bin/nvidia-smi`), so `gpuAvailable` resolves `true` and this sampler is live, not the empty-state fallback. Two one-shot discovery probes (`hwmonDiscoveryProcess`, `gpuProbeProcess`) fire once per session each. | `fastPollInterval: 2000` → **1800/hour, 43200/day**, in-process, zero subprocess. `slowPollInterval: 30000` → `$ echo $((3600/30))` → **120 `df` calls/hour, 2880/day**. `gpuPollInterval: 4000` → `$ echo $((3600/4))` → **900 `nvidia-smi` calls/hour, 21600/day**. **This plan's `SystemCapsule.qml` consumes only `cpuFraction`/`memoryFraction`/`storageFraction`/their D-41 registers — it reads neither `gpuFraction` nor `netRxRate`/`netTxRate`.** The 900/hour `nvidia-smi` spawns and the in-process network parse are charge the bar pays for and does not use — see the re-narrowing question below. |
| `AudioBackend` | `root.audioTruthNeeded` = `dashboardLoader.active \|\| audioPanelLoader.active \|\| barInstance.requiresAudio` — `requiresAudio` is `true` from this plan onward | `trackedNodes` (`root.sinks.concat(root.sources).concat(root.streams)`) feeds one `PwObjectTracker` — a live D-Bus/PipeWire object subscription, not a polling loop. The quantity that matters is how many nodes it holds tracked, not a per-tick cost. | Measured this session via `$ pw-dump \| jq -r '.[] \| select(.type=="PipeWire:Interface:Node") \| .info.props["media.class"]' \| sort \| uniq -c`: **3 `Audio/Sink` + 2 `Audio/Source` + 3 `Stream/Output/Audio` = 8 nodes tracked continuously** on this host right now (also present: 2 `Midi/Bridge`, 1 `Stream/Input/Audio`, 2 unclassified — none of those three match `sinks`/`sources`/`streams`' `PwNodeType` filters, so they are not tracked). Why the widening was not optional: 15-07 measured that with the tracker off, `defaultSink.audio` stays `null` and `masterMuted` freezes at its `false` fallback — the bar's audio readout would be silently wrong, not merely stale, without this gate. |
| `MediaBackend` | `dashboardLoader.active \|\| barInstance.requiresMedia` — `requiresMedia` is `true` from this plan onward | **After this same plan's Task 3 repoint, the widened gate now costs nothing while no player is running** — no subprocess and no timer start at all, because the backend reads the always-resident native MPRIS singleton rather than launching a shell-script reader. The ONE remaining timer (`positionRefreshTimer`) is additionally gated on `root.drawerOpen && root.playing && root.canSeek`, `interval: 1000`, in-process — no fork. | The reader this repoint replaced would have forked roughly **ten processes a second** under this SAME widened gate — that comparison is the whole point of pairing D-18-05's repoint with this widening in one plan. A real MPRIS player IS active on this host at measurement time (`$ playerctl status` → `Playing`, Firefox/YouTube), so the position timer's gate condition is live right now; this session did not reload the running `quickshell` process to observe it directly (see Measurement Brief) — 18-18's soak is where that gets confirmed against a running instance of this exact code. |

## What the bar deliberately does not charge for

`WifiBackend` and `BluetoothBackend` are **NOT** among the widened gates —
`shell.qml`'s `wifiPanelLoader.active`/`bluetoothPanelLoader.active`
bindings are byte-unchanged by this plan, exactly as 18-05 left them.
D-15-15 (wifi scan lifecycle) and D-15-18 (bluetooth discovery/device
ordering) both forbid running either backend's scan/discovery path
always-on, and this plan's `MediaConnectivityCapsule.qml` reads only the
ungated half of each:

- **wifi**: `wifiHardwareEnabled`, `wifiEnabled` (both plain bindings onto
  the `Networking` singleton, live with no scan) and the resolved
  `wifiDevice`'s own `connected` boolean (live on the device object
  itself, not the scan-populated `currentNetwork`). `currentNetwork` IS
  read, but only to grade an already-connected glyph's opacity, and only
  when it happens to already be non-null from a scan the WIFI PANEL
  triggered on its own gate — this file never causes that scan.
- **bluetooth**: `adapterPresent`, `adapterBlocked`, `adapterEnabled` and
  `connectedDevices.length` — all derived from `Bluetooth.defaultAdapter`
  and its device list by plain filtering, none of them requiring the
  adapter's sweep-in-progress flag.

Neither backend gains a bar-side aggregate (`BarEntryModel.qml` mints
exactly three — `requiresResources`/`requiresMedia`/`requiresAudio` —
deliberately not five), so there is no code path in this plan through
which the bar could widen either gate even by mistake.

The native power singleton (`Quickshell.Services.UPower`) and the native
MPRIS singleton (`Quickshell.Services.Mpris`) introduce **no new service
connection**: `SystemResources.qml` already imports `UPower` and (as of
this plan's Task 3) `MediaBackend.qml` already imports `Mpris` — this
plan's capsules read the same already-open connections, not a second one.

`WeatherBackend`'s gate is untouched because no bar entry in
`BarEntryModel.qml`'s six capsules declares a `weather` backend at all.

## New charge introduced by this plan itself

Separate from 18-05's three gate widenings above — this is what
`SystemCapsule.qml` and `MediaBackend.qml` add on their own:

- **The updates poll** (`SystemCapsule.qml`, `updatesPollIntervalMs:
  1800000`, a genuinely new one-shot reader with no prior backend
  anywhere in this repo): one `checkupdates` child every 30 minutes —
  `$ echo $((3600/1800))` → **2 runs/hour, 48/day**. Compared against the
  retired bar's own updates module (`waybar/.config/waybar/modules.jsonc`:
  `"interval": 15`, i.e. `$ echo $((3600/15))` → **240 runs/hour,
  roughly 5,700/day**): this plan's interval is a **120-fold** reduction
  in sync frequency against the same public package-mirror
  infrastructure, from a surface that (unlike the retired bar) never
  dismisses.
- **The album-art resolver** (`MediaBackend.qml`, `artResolveProcess`):
  event-driven, not polled — it launches only on a track/player change
  whose art URL carries a non-`file://` scheme, single-flighted, and
  produces at most one child per actual track change. No steady-state
  cadence to name; its frequency is bounded by how often the user changes
  tracks, not by a timer.
- **The position-refresh timer** (`MediaBackend.qml`,
  `positionRefreshTimer`, `interval: 1000`) — already tabulated in the
  `MediaBackend` row above; restated here because it is this plan's own
  addition, not something 18-05 introduced. Gated on
  `drawerOpen && playing && canSeek`, so it is silent whenever nothing is
  playing or the active player cannot report a seekable position.

## Measurement brief for 18-18's QBAR-11 soak

At soak **start** and soak **end**, capture and diff against the numbers
in this document:

1. **Resident set size** of the shell process:
   `$ ps -o rss=,vsz=,etime= -p "$(pgrep -x quickshell)"` — diff the `rss=`
   field against `18-BAR-IDLE-BASELINE.md`'s **445104 KiB** floor, not
   against this document's own mid-phase reading (`$ ps -o
   pid,rss,etime,cmd -p "$(pgrep -x quickshell)"` → `460284` KiB at
   capture time this session — taken from the SAME long-lived process the
   baseline measured, hot-reloaded through Phases 18-01..18-07's changes
   but **not yet this plan's Task 1-4 changes**, since no reload/restart
   was performed while writing this document; it is context, not a
   controlled before/after pair for this plan specifically).
2. **Child process count**: `$ pgrep -c -P "$(pgrep -x quickshell)"` —
   diff against the baseline's **0**. Expect transient non-zero readings
   (the `df`/`nvidia-smi`/`checkupdates` one-shot children are bursts, not
   held-open processes) — a SUSTAINED non-zero count across repeated
   samples, not a single non-zero sample, is the signal to chase.
3. **Running-timer inventory by backend**, cross-checked against the
   per-backend table above: `SystemResources` (fast/slow/GPU),
   `MediaBackend` (position-refresh, conditional), `SystemCapsule.qml`
   (the updates poll). `WifiBackend`/`BluetoothBackend` should show ZERO
   backend-side timers running with every panel closed — if either
   backend's scan or discovery state is observed live during the soak
   with no wifi/bluetooth panel open, that is a regression against this
   document's own "what the bar does not charge for" section and against
   D-15-15/D-15-18, not an expected reading.

**Hypothesis to test, not a conclusion** (18-RESEARCH.md Pitfall 7): any
RSS creep the soak observes is predicted to trace to `AudioBackend`'s
PipeWire tracked-node count (new sinks/sources/streams appearing over the
session — e.g. a browser tab opening a new audio stream) rather than to
bar QML objects, since the bar's own QML surface is a small, fixed set of
`Text`/`Grid` elements with no per-session growth. 18-18 should check the
tracked-node count (`$ pw-dump | jq ...` as used in the `AudioBackend` row
above) alongside RSS specifically to confirm or falsify this before
attributing any observed creep to the bar's own code.

**The one re-narrowing question this document raises**: `SystemResources`'
GPU sampler (900 `nvidia-smi` calls/hour) and its network-rate sampling
(in-process, every 2s) are both charge the bar pays for via the widened
`requiresResources` gate but does not consume — `SystemCapsule.qml` reads
only `cpuFraction`/`memoryFraction`/`storageFraction`. If 18-18's soak
finds this material, the fix is a SECOND, narrower gate on
`SystemResources` (e.g. a `gpuNetworkTruthNeeded`-shaped property bound to
`dashboardLoader.active` alone, leaving `requiresResources` covering only
the three metrics the bar actually reads) — but that edit lands in
`shell.qml`, which is **frozen for wave 3 by 18-05**. Acting on this
finding is therefore an **18-05 scope correction** for 18-18 (or whichever
phase owns the soak's follow-up) to raise explicitly, not something a
wave-3 plan may take unilaterally.

## Measurement instrument — required and forbidden

**Forbidden, unconditionally**: any measurement in this document, and any
measurement 18-18 takes from this brief, must NOT use Hyprland's debug
overlay. That exact instrument, on this exact host, froze the machine hard
enough to require a physical restart during Phase 16's OVER-04
measurement (18-RESEARCH.md Pitfall 4). There is no safe partial use of it
for this soak.

**Required for any frame-rate work**: Qt's own render-timing environment
variable, `QSG_RENDER_TIMING=1`, which this repo has already exercised
safely (Phase 14's render-loop finding, `QSG_RENDER_LOOP=threaded`) and
which produces log-line timing data rather than an interactive overlay
process.

## Commands, for reproducibility

Every measured quantity above traces to one of these:

```
$ ps -o rss=,vsz=,etime= -p "$(pgrep -x quickshell)"
$ pgrep -c -P "$(pgrep -x quickshell)"
$ pw-dump | jq -r '.[] | select(.type=="PipeWire:Interface:Node") | .info.props["media.class"]' | sort | uniq -c
$ lspci | grep -i vga
$ command -v nvidia-smi
$ playerctl status
$ checkupdates | wc -l
$ grep -n 'interval' quickshell/.config/quickshell/modules/dashboard/SystemResources.qml
```
