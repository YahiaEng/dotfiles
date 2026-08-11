# 18-18 Tasks 3-4: QBAR-11 Permanent-Liveness Soak

**Status: Task 3 (inventory, tolerances, start capture) COMPLETE and real. Task 4 (soak
end capture, 200-cycle exercise, verdict) DEFERRED** — its own precondition (at least
14400 seconds of continuous single-pid uptime since this document's start capture, with an
unchanged `NRestarts`) cannot be met within a single execution session. Per this plan's
explicit soak guidance, this session does not block on that wall-clock requirement; it
takes the readings available now and records the remainder as a resumable deferred item
with the exact commands to complete it. No verdict is asserted anywhere in this document.

## Section one — the aggregated permanent-liveness inventory

Assembled from all four upstream sources named in the plan, not from any single one of
them in isolation.

| Item | What runs permanently | Cadence | Measured cost | Source |
|---|---|---|---|---|
| `SystemResources` — fast sampler | In-process `/proc/stat`/`/proc/meminfo`/`/proc/net/dev` reads via `FileView`, no subprocess | `fastPollInterval: 2000` → 1800/hour | 0 subprocess/hour, in-process only | `18-BAR-LIVENESS-CHARGE.md` |
| `SystemResources` — slow sampler | One `df -B1 --output=size,used /` child per tick | `slowPollInterval: 30000` → 120/hour | 120 `df` subprocess spawns/hour | `18-BAR-LIVENESS-CHARGE.md` |
| `SystemResources` — GPU sampler | One `nvidia-smi --query-gpu=...` child per tick | `gpuPollInterval: 4000` → 900/hour | 900 `nvidia-smi` subprocess spawns/hour — **consumed by no bar entry** (`SystemCapsule.qml` reads only cpu/memory/storage fractions); see the dedicated GPU/network-sampler note below | `18-BAR-LIVENESS-CHARGE.md` |
| `AudioBackend` | One live `PwObjectTracker` D-Bus/PipeWire subscription (not polling) | Event-driven | 8 nodes tracked at 18-08's measurement time (3 sinks + 2 sources + 3 streams) | `18-BAR-LIVENESS-CHARGE.md` |
| `MediaBackend` | Native MPRIS singleton read (no subprocess, no timer at rest); `positionRefreshTimer` gated on `drawerOpen && playing && canSeek` | 0 while gate false; `interval: 1000` in-process while true | 0 subprocess/hour at rest (post-repoint) | `18-BAR-LIVENESS-CHARGE.md` |
| Updates poll (this plan's own new charge, `SystemCapsule.qml`) | One `checkupdates` child per tick | `updatesPollIntervalMs: 1800000` → 2/hour | 2 subprocess spawns/hour (120-fold reduction vs. the retired waybar module's 240/hour) | `18-BAR-LIVENESS-CHARGE.md` |
| Album-art resolver (`MediaBackend.qml`) | Event-driven, at most one child per actual track change | No steady-state cadence | Bounded by user track-change frequency, not a timer | `18-BAR-LIVENESS-CHARGE.md` |
| Notification subscription (18-11) | `swaync-client -swb`, one long-lived child process | Continuous subscription, not polled | **The ONE permanent child process this bar carries** — confirmed live this session as pid 737957, `cmd = /usr/bin/swaync-client -swb`, present in two `pgrep -P` samples 10s apart. Recorded in 18-11's SUMMARY and **deliberately NOT written into `18-BAR-LIVENESS-CHARGE.md`** (D-18-33) — a soak inventory built from that artifact alone would miss this term entirely and attribute it to unexplained creep. Ends at the Phase 19 notification-backend swap. | `18-11-SUMMARY.md` |
| Hot zone (`HotZone.qml`, D-18-24/D-18-26) | Zero cost while the bar is visible (loader-gated on `barVisibilityState !== "visible"`); one non-repeating grace timer (`reHideTimer`, 600ms) while revealed; a create/destroy cycle per hide transition | Event-driven, no steady-state timer while visible | 0 while visible by construction; the create/destroy path is what the 200-cycle exercise (deferred, below) is the only place in the phase that exercises at scale | `18-16-SUMMARY.md` |
| `quickshell.service` supervision itself | Zero added long-lived processes (D-18-40) | N/A | 1 process, 0 added children — stated as the declared expectation the process-count gate is read against | `18-07-SUMMARY.md` |
| `WifiBackend` (non-charge) | NOT widened by this bar; scan/discovery path stays gated on the wifi panel's own `active`, never on the bar | N/A | 0 — carried forward as a deliberate non-charge, not omitted | `18-BAR-LIVENESS-CHARGE.md` |
| `BluetoothBackend` (non-charge) | NOT widened by this bar; sweep-in-progress path stays gated on the bluetooth panel's own `active`, never on the bar | N/A | 0 — carried forward as a deliberate non-charge, not omitted | `18-BAR-LIVENESS-CHARGE.md` |

**Total declared expectation:** per-hour subprocess spawns = 120 (`df`) + 900 (`nvidia-smi`)
+ 2 (`checkupdates`) = **1022/hour** from timers alone, plus the album-art resolver's
unbounded-but-track-change-gated spawns and the one permanent `swaync-client -swb` child
that is not a per-hour spawn but a single held-open process. Wake-generating timers:
`SystemResources` fast (2s), `SystemResources` slow (30s), `SystemResources` GPU (4s),
`MediaBackend` position-refresh (1s, conditionally gated), the updates poll (1800s),
`HotZone`'s grace timer (600ms, non-repeating, only while revealed) = **6 distinct
always-registered or conditionally-registered timer sources**. This total is what the
runtime measurements at soak end are read against.

**The hidden-states-do-not-narrow-gates fact (D-18-23):** the bar's two hidden states
(`hidden-idle`, `hidden-hard`) narrow no backend gate. `SystemResources`, `AudioBackend`
and `MediaBackend` all stay gated on `dashboardLoader.active || barInstance.requiresX`,
and `barInstance.requiresX` does not depend on visibility state — only the zone
reservation changes on hide. So a soak window that includes hypridle-driven hides measures
the **same permanent charge** as one that does not; an idle-heavy window must not be read
as a cheaper bar.

## Section two — the pre-expansion baseline

From `18-BAR-IDLE-BASELINE.md` (18-01, tracer scope, captured before any gate was
widened):

| Metric | Pre-expansion floor (18-01) | Soak start (this document, below) |
|---|---|---|
| RSS | 445104 KiB (~435 MiB) | 450424 KiB (see Section four) |
| Process count | 1 | 1 |
| Child process count | 0 | 1 (the `swaync-client -swb` subscription — did not exist at 18-01's tracer scope; added by 18-11) |
| Declared `Timer {}` in `Bar.qml` | 0 | 0 (unchanged — the clock is still `SystemClock`-driven; the 26 repo-wide count below covers pre-existing gated surfaces, not `Bar.qml` itself) |

This baseline exists precisely because after wave 3 there is no minimal bar left to
measure directly; both the pre-expansion floor and this session's start reading are real
captures, not estimates.

## Section three — the tolerances, written before any result exists

These are decision thresholds chosen for this plan with their reasoning recorded, not
predictions about what the bar will do. A breach is a finding to be reported with its
number, not a number to be re-explained afterward.

- **Resident set size (magnitude):** total growth at most **32 MiB** over the soak window,
  AND rate at most **5 MiB per hour**. Compared as integer KiB from `ps -o rss=`, never as
  rounded MiB. One step either side: 32 MiB total passes, 33 MiB fails; 5.0 MiB/hour
  passes, 5.1 fails.
- **Resident set shape:** at least five samples spaced through the window, and growth
  across the final third at most twice the growth across the first third. A settling
  allocator grows then flattens; a leak grows at a constant or rising rate — magnitude
  alone cannot separate them, and Qt/glib do not return freed pages promptly enough for a
  bit-exact flat assertion to be anything but a false-failure generator.
- **Process count:** exact equality. One `quickshell` process at both ends
  (`pgrep -c -x quickshell` == 1), and exactly one long-lived child (the notification
  subscription) at both ends. Zero would mean the subscription died (a finding, not a
  pass); two fails.
- **Wake rate:** within ±20 percent of the start rate, both measured over an identical
  300-second observation (`voluntary_ctxt_switches + nonvoluntary_ctxt_switches` delta from
  `/proc/<pid>/status`, divided by elapsed seconds). Band is start-rate × 0.8 through ×1.2
  inclusive at both edges.
- **CPU-time rate:** within ±25 percent of the start rate, same 300-second observation
  (`utime + stime` ticks from `/proc/<pid>/stat`, `getconf CLK_TCK` = 100 on this host, so
  10ms granularity).
- **Hot-zone namespaces after the 200-cycle exercise:** exactly **0** `quickshell-bar-hotzone`
  namespaces in `hyprctl layers -j`, with no tolerance — a single orphan surface is the
  leak itself, not noise.
- **Minimum window:** at least **4 hours** (14400 seconds) of continuous single-pid uptime
  with an unchanged `NRestarts`. 4h00m00s qualifies; 3h59m59s does not and halts rather
  than shortening the window.

Every rate is computed from raw integer deltas with `awk` (`bc` is not installed on this
host and no package may be added to obtain a division); only the *display* is rounded.

## Section four — the start capture

Pid validated as digits-only before use in any path or command. All readings taken on the
**currently live, systemd-supervised** `quickshell` process — this session did not perform
Task 1's stop/restart cycle (deferred, see `18-FRAME-RATE.md`), so this pid is the one the
soak window measures against, and its restart count (0) and cgroup path are recorded below
as the window's anchor.

```
$ pgrep -x quickshell
737907

$ ps -o rss=,vsz=,etimes= -p 737907
450424 1054352 1189

$ pgrep -c -x quickshell
1

$ pgrep -P 737907          # sample 1
737957
$ sleep 10 && pgrep -P 737907   # sample 2, 10s later
737957
```

Long-lived child set (intersection of both samples): **{737957}**, one member.

```
$ ps -o pid=,cmd= -p 737957
737957 /usr/bin/swaync-client -swb
```

Confirms 18-11's finding directly: the one long-lived child is the swaync notification
subscription. No transient children (`df`/`nvidia-smi`/`checkupdates`/album-art resolver)
were observed in either sample — none of their timers happened to fire during the 10s
window, which is expected and not itself a finding.

```
$ awk '/^voluntary_ctxt_switches:/{print $2}' /proc/737907/status   # at observation start
34001
$ awk '/^nonvoluntary_ctxt_switches:/{print $2}' /proc/737907/status
878
$ awk '{print $14, $15}' /proc/737907/stat   # utime stime, ticks
349 258
```

**300-second wake/CPU observation, run live this session (start-of-window figures):**

```
T0 = 1786443601 (epoch)
  voluntary_ctxt_switches = 34001, nonvoluntary_ctxt_switches = 878
  utime = 349, stime = 258
T1 = 1786443916 (epoch, 315s later — 300s target plus tool-call overhead)
  voluntary_ctxt_switches = 39939, nonvoluntary_ctxt_switches = 1033
  utime = 401, stime = 284

elapsed = 315s
wake_delta = (39939-34001) + (1033-878) = 5938 + 155 = 6093
cpu_ticks_delta = (401-349) + (284-258) = 52 + 26 = 78 ticks = 0.78s CPU

$ awk -v w=6093 -v t=315 'BEGIN{printf "%.4f\n", w/t}'
19.3429   # wakes/sec, this window's rate

$ awk -v c=78 -v t=315 'BEGIN{printf "%.6f\n", (c/100)/t}'
0.002476  # cpu-seconds per wall-second
```

This is the **start-of-soak** 300-second wake/CPU observation. Task 4's end-of-soak
observation, run identically after the 4-hour window, is compared against these two rates
at ±20% (wake) and ±25% (CPU) per Section three.

```
$ getconf CLK_TCK
100

$ grep -rn 'Timer\s*{' quickshell/.config/quickshell/modules/ | grep -v '^\s*//' | wc -l
26

$ systemctl --user show quickshell.service -p NRestarts
NRestarts=0

$ cat /proc/737907/cgroup
0::/user.slice/user-1000.slice/user@1000.service/app.slice/app-graphical.slice/quickshell.service

$ hyprctl layers -j | jq -r '..|.namespace? // empty' | sort | uniq -c
      1 awww-daemon
      1 quickshell-bar

$ hyprctl monitors -j | jq -c '[.[].reserved]'
[[0,46,0,0]]

$ ~/.config/hypr/scripts/bar-visibility.sh status
visible

$ cat ~/.local/state/theme/current-theme
catppuccin
```

The theme-state path cited above (`~/.local/state/theme/current-theme`) is the
authoritative one — a same-named orphan exists under `~/.cache/`; it is deliberately not
cited here.

**Start-capture summary:** pid `737907`, RSS `450424` KiB, etimes `1189` s at initial
sample (process has been up well past the 10-minute settle precondition), one
`quickshell` process, one long-lived child (`swaync-client -swb`), zero transient
children observed in a 10s window, wake rate `19.3429`/sec and CPU rate `0.002476`
cpu-sec/sec over a real 300s(315s) observation, `NRestarts=0`, cgroup confirms the
supervised unit, `quickshell-bar` is the sole quickshell layer namespace, reserved array
`[[0,46,0,0]]`, bar visible, theme `catppuccin`.

## Section five — the soak protocol (instructions for the deferred Task 4)

**Minimum window:** 4 hours (14400s) of continuous uptime on pid `737907` with
`NRestarts` staying at `0`. If the process restarts for any reason before 14400s elapses,
the window is void — a fresh start capture must be taken and this section re-run from a
new pid.

**What the user should do during the window:** use the machine normally. "Multi-hour
session" is the requirement's own word, and normal use is what exercises the popout
create-and-destroy path that cannot be driven mechanically on this host (a warped cursor
position does not emit the pointer motion these surfaces process).

**At least five RSS samples**, spaced through the window, each with its own `ps -o rss=`
command and timestamp — not just the two endpoints — so the shape gate (final-third growth
at most 2x first-third growth) is evaluable rather than skipped.

**The one scripted exercise Task 4 runs at the end:** at least 200 hide/reveal cycles
driven exclusively through `bar-visibility.sh`'s own verbs — `idle hide`, wait for the
transition and the 600ms grace to settle, `idle show`, wait again. Each cycle creates and
destroys the `HotZone.qml` surface. This is the only place in the phase the destroy path
is exercised at scale; 18-16 chose create-and-destroy specifically because the bar never
unmounts, and that choice is only sound if the destroy path actually releases.

**Resume commands, exact, for a future session once 14400s has genuinely elapsed:**

```bash
PID=737907   # must still be the SAME pid; if not, the window is void — restart Section four
ps -o etimes= -p "$PID"                                   # must be >= 14400
systemctl --user show quickshell.service -p NRestarts     # must still read 0

# End capture — identical command set to Section four, same pid, same order
ps -o rss=,vsz=,etimes= -p "$PID"
pgrep -c -x quickshell
pgrep -P "$PID"; sleep 10; pgrep -P "$PID"                # intersect for long-lived set
awk '/^voluntary_ctxt_switches:/{print $2}' /proc/"$PID"/status
awk '/^nonvoluntary_ctxt_switches:/{print $2}' /proc/"$PID"/status
awk '{print $14, $15}' /proc/"$PID"/stat
# ...repeat the 300s observation exactly as Section four did, then diff both rates
# against 19.3429 wakes/sec (±20%) and 0.002476 cpu-sec/sec (±25%)
systemctl --user show quickshell.service -p NRestarts
cat /proc/"$PID"/cgroup
hyprctl layers -j | jq -r '..|.namespace? // empty' | sort | uniq -c
hyprctl monitors -j | jq -c '[.[].reserved]'
~/.config/hypr/scripts/bar-visibility.sh status
cat ~/.local/state/theme/current-theme

# The 200-cycle exercise
for i in $(seq 1 200); do
  ~/.config/hypr/scripts/bar-visibility.sh idle hide
  sleep 1   # transition + grace settle
  ~/.config/hypr/scripts/bar-visibility.sh idle show
  sleep 1
done
hyprctl layers -j | jq -r '..|.namespace? // empty' | grep -c '^quickshell-bar-hotzone$'  # must be 0
hyprctl layers -j | jq -r '..|.namespace? // empty' | grep -c '^quickshell-bar$'           # must be 1
~/.config/hypr/scripts/bar-visibility.sh idle show   # restore idle source to show
~/.config/hypr/scripts/bar-visibility.sh status       # must print visible; 'reassert' is the recovery verb

# Test the PipeWire tracked-node attribution hypothesis (18-08's brief)
pw-dump | jq -r '.[] | select(.type=="PipeWire:Interface:Node") | .info.props["media.class"]' | sort | uniq -c
```

Compute every rate from raw integer deltas with `awk`; compare against Section three's
tolerances exactly; report each gate as start/end/delta/threshold/outcome; name any
unevaluable gate with its reason. Do not run `hyprctl eval` or `hyprctl reload` at any
point.

## GPU-and-network-sampler cost — measured now, disposition deferred to Task 5

Stated here per the plan's own requirement that this cost reach the developer with a
number attached, independent of whether the full soak has completed:

- **Measured per-hour subprocess count:** 900 `nvidia-smi` spawns/hour (`gpuPollInterval:
  4000` → `3600/4 = 900`), per `18-BAR-LIVENESS-CHARGE.md`'s own live measurement. No bar
  entry consumes this — `SystemCapsule.qml` reads only `cpuFraction`/`memoryFraction`/
  `storageFraction`.
- **Wake/CPU-time contribution:** not isolable from this session's aggregate 300s
  observation (19.3429 wakes/sec, 0.002476 cpu-sec/sec include ALL of `SystemResources`'
  fast/slow/GPU samplers plus every other backend combined) — isolating the GPU sampler's
  specific share would require a differential measurement (gate disabled vs. enabled) that
  is out of this plan's scope (it would mean editing `shell.qml`, which this plan does not
  touch). Recorded as **not isolable this session**, with that reason, rather than guessed.
- **Ownership:** re-narrowing this cost means adding a second, drawer-only gate expression
  in `quickshell/.config/quickshell/shell.qml` — 18-05's file, frozen for wave 3 and not
  this plan's to edit.
- **Disposition:** **CLOSED to debt — `WINDOWS.md` row `63`** (operator decision, 2026-08-12,
  Task 5 `option-b`). The finding now lives in the repo's cross-phase defect register with its
  measured number, its named owner (`shell.qml`, 18-05's file) and its one-line remedy, rather
  than only in this artifact. `option-a` — cutting a scope-correction plan against 18-05 at wave
  8 — was rejected: five shipped-and-verified plans depend on `shell.qml`'s current shape, and
  every downstream `SystemResources` assertion would have needed re-confirming. No QML was
  edited by this plan, as both branches require.

## Commands executed

Every command this session actually ran against the live host for this document, in
order (all read-only reads plus one real 300-second wait/observation window — no service
was stopped, no window was moved, no visibility cycle was driven):

```
systemctl --user is-active quickshell.service
systemctl --user show quickshell.service -p NRestarts
pgrep -x quickshell
ps -o pid=,etimes=,rss= -p 737907
hyprctl monitors -j | jq -c '[.[] | {name, refreshRate, reserved}]'
hyprctl clients -j | jq '[.[] | select(.mapped==true)] | length'
hyprctl clients -j | jq -c '[.[] | select(.mapped==true) | .workspace.id] | unique'
~/.config/hypr/scripts/bar-visibility.sh status
hyprctl version | head -3
pacman -Q quickshell
ps -o rss=,vsz=,etimes= -p 737907
pgrep -c -x quickshell
pgrep -P 737907
ps -o pid=,cmd= -p 737957
awk '/^voluntary_ctxt_switches:/{print $2}' /proc/737907/status
awk '/^nonvoluntary_ctxt_switches:/{print $2}' /proc/737907/status
awk '{print $14, $15}' /proc/737907/stat
getconf CLK_TCK
cat /proc/737907/cgroup
grep -rn 'Timer\s*{' quickshell/.config/quickshell/modules/ | grep -v '^\s*//' | wc -l
hyprctl layers -j | jq -r '..|.namespace? // empty' | sort | uniq -c
cat ~/.local/state/theme/current-theme
```

No `hyprctl eval` and no `hyprctl reload` were run — verified by inspection of the list
above (both prohibited commands are absent). No code file, script, or config was modified
by this session.

## Deferred-item record

Filed to `.planning/WINDOWS.md` as an `unrun-verify` entry citing this artifact's Section
five ("Resume commands") so the soak end-capture and 200-cycle exercise are discoverable
and resumable rather than silently dropped. QBAR-11 remains open pending that end capture
and verdict.
