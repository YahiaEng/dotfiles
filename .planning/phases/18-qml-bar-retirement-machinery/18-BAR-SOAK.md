# 18-18 Tasks 3-4: QBAR-11 Permanent-Liveness Soak

**Status: Task 3 (inventory, tolerances, start capture) COMPLETE and real. Task 4 (soak
end capture, 200-cycle exercise, verdict) OPEN — the window is now RUNNING.** Task 4's
precondition is at least 14400 seconds of continuous single-pid uptime with an unchanged
`NRestarts`, which cannot elapse inside one execution session. No verdict is asserted
anywhere in this document.

**Window state, 2026-08-12:** the original start capture (Section four, pid `737907`) is
**void** — `quickshell` restarted during Phase 18.1's bar rebuild, and Section three
declares a restart mid-window fatal. Two further anchors followed, and the
first of them is void as well: Section four-bis (pid `262631`) was killed by a host reboot at
01:09. **Section four-ter is the live anchor** (pid `1626`), and its "Live thresholds" table
carries the absolute bands the end capture is judged against. Section three's tolerance
*percentages* are unchanged throughout — they were pre-declared before any result existed and
were never re-opened; only the absolute values move, because they are defined relative to a
start rate that had to be re-taken.

**Earliest valid end capture: ≈ 05:09:39 EEST on 2026-08-12** (unit start 01:09:39 +
14400 s). Until then, use the machine normally — normal use is what exercises the popout
create-and-destroy path, and is what the requirement's own phrase "multi-hour session"
means.

**The window has now voided three times** (18.1's rebuild, then a reboot, with a discarded
two-bar attempt between them). Each void needed a fresh capture from a new pid. The recurring
obstacle is not the measurement — every capture took 5 minutes and worked first time — it is
holding four hours of uninterrupted uptime. If `quickshell` restarts or the host reboots
before 05:09:39, Section four-ter must be re-taken and the clock restarts.

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

| Metric | Pre-expansion floor (18-01) | Void start, pre-18.1 (Section four) | **Live anchor, post-18.1 (Section four-bis)** |
|---|---|---|---|
| RSS | 445104 KiB (~435 MiB) | 450424 KiB | **477016 KiB** |
| Process count | 1 | 1 | **1** |
| Child process count | 0 | 1 (the `swaync-client -swb` subscription — did not exist at 18-01's tracer scope; added by 18-11) | **1, by command** (pid re-spawned mid-session — see the methodology correction in Section four-bis) |
| Declared `Timer {}` in `Bar.qml` | 0 | 0 (unchanged — the clock is still `SystemClock`-driven; the 26 repo-wide count below covers pre-existing gated surfaces, not `Bar.qml` itself) | **0** (repo-wide count now **34**, up from 26 — Phase 18.1's rework, still none in `Bar.qml`) |
| Reserved array | — | `[[0,46,0,0]]` | **`[[0,48,0,0]]`** (`barHeight` 40 → 42, upstream Athena) |

The RSS column crosses a build boundary and is **not** a leak series: 18.1 rebuilt the bar
between the second and third columns. Only the third column anchors the running soak.

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

## Section four — the start capture (2026-08-11) — **VOID, retained as the historical record**

> **This window never opened.** Section three requires 14400 s of continuous uptime on a
> single pid with `NRestarts` unchanged, and states that if the process restarts before the
> window elapses "the window is void — a fresh start capture must be taken and this section
> re-run from a new pid." `quickshell` restarted during Phase 18.1's bar rebuild: pid
> `737907` is gone and the supervised unit now runs pid `262631`
> (`ExecMainStartTimestamp` = 2026-08-12 00:32:15 EEST). Every reading below is real and was
> honestly taken; none of it anchors the live soak. The live anchor is **Section four-bis**.
>
> Two further facts invalidate this section as a comparison basis even setting the pid aside:
> the build changed underneath it (module `Timer {}` count 26 → 34 across 18.1's rework), and
> the reserved array moved from `[[0,46,0,0]]` to `[[0,48,0,0]]` when 18.1 raised
> `Design.barHeight` from 40 to upstream Athena's 42.

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

## Section four-bis — the re-taken start capture (2026-08-12) — **THE LIVE ANCHOR**

Taken after the desktop was settled, and deliberately re-taken once: a first attempt at
`00:45` was discarded because **waybar was still running** from Phase 18.1's GATE-02
comparison, stacked above the QML bar (`waybar` y=6 h=40, `quickshell-bar` y=52 h=42) and
holding a second exclusive zone — `hyprctl monitors` read `[[0,94,0,0]]`. Anchoring a
4-hour window to a two-bar state that was about to change would have guaranteed a
start/end mismatch on the reserved-array check. waybar (pid `3840410`,
`-c config-athena.jsonc`) was stopped by operator decision; waybar remains **installed and
relaunchable** via `waybar-launch.sh` until 18-20 actually retires it. The discarded
reading is recorded below for completeness rather than dropped.

```
$ pgrep -x quickshell
262631

$ ps -o rss=,vsz=,etimes= -p 262631
481364 1021416  1701

$ pgrep -c -x quickshell
1

$ pgrep -P 262631          # sample 1
262662
$ sleep 10 && pgrep -P 262631   # sample 2, 10s later
424020

$ ps -o pid=,cmd= -p 424020
 424020 /usr/bin/swaync-client -swb
```

**Methodology correction, forced by live evidence — the long-lived-child gate must
intersect on COMMAND, not pid.** Section four's procedure intersects the two `pgrep -P`
samples by pid. That is wrong, and this session proved it: the child's pid changed between
sample 1 and sample 2 (`262662` → `424020`) while the command stayed
`/usr/bin/swaync-client -swb`. A pid intersection yields the empty set and would report
"zero long-lived children" — i.e. "the subscription died", which Section three calls a
finding — when the subscription is in fact alive and healthy. Confirmed by direct
observation: 12 samples at 5-second spacing held `424020` steady with no further respawn,
so this was a single re-spawn (concurrent with waybar's exit), not a loop. **The end
capture must compare the child *command set*, and report any pid change as an observation
rather than as a death.**

```
$ for i in $(seq 1 12); do date +%H:%M:%S; pgrep -P 262631; ps -o rss= -p 262631; sleep 5; done
01:01:20  424020  477024      01:01:50  424020  476976
01:01:25  424020  477048      01:01:55  424020  477044
01:01:30  424020  477068      01:02:00  424020  477044
01:01:35  424020  476984      01:02:05  424020  477044
01:01:40  424020  476984      01:02:10  424020  476992
01:01:45  424020  477044      01:02:15  424020  477000
```

RSS oscillates in a ~92 KiB band with no trend across that minute — recorded as the
short-horizon shape observation, not as evidence about the 4-hour window.

**300-second wake/CPU observation (start-of-window figures):**

```
T0 = 1786485646 (epoch)
  voluntary_ctxt_switches = 30136, nonvoluntary_ctxt_switches = 1792
  utime = 352, stime = 366
T1 = 1786485946 (epoch, 300s later)
  voluntary_ctxt_switches = 32006, nonvoluntary_ctxt_switches = 2008
  utime = 375, stime = 378

elapsed = 300s
wake_delta = (32006-30136) + (2008-1792) = 1870 + 216 = 2086
cpu_ticks_delta = (375-352) + (378-366) = 23 + 12 = 35 ticks = 0.35s CPU

$ awk -v w=2086 -v t=300 'BEGIN{printf "%.4f\n", w/t}'
6.9533   # wakes/sec — THE ANCHOR RATE

$ awk -v c=35 -v t=300 'BEGIN{printf "%.6f\n", (c/100)/t}'
0.001167 # cpu-seconds per wall-second — THE ANCHOR RATE
```

**The discarded two-bar reading (00:45, waybar up, reserved `[[0,94,0,0]]`), for contrast
only:** 13.7567 wakes/sec, 0.001967 cpu-sec/sec, RSS 453284 KiB. It is not the anchor and
no gate is computed against it.

**Three wake rates now exist and they are not interchangeable** — 19.3429/sec (2026-08-11,
void, pre-18.1 build), 13.7567/sec (two-bar transient), 6.9533/sec (settled anchor). The
drop is *not* claimed here as an improvement: the build, the bar geometry and the number of
compositor surfaces all differ between them, and no differential measurement was run to
attribute it. It is recorded as three separate observations under three separate
conditions, which is what they are.

```
$ getconf CLK_TCK
100

$ ps -o rss=,etimes= -p 262631   # RSS sample 1 of >=5
477016   2011

$ systemctl --user show quickshell.service -p NRestarts -p MainPID -p ExecMainStartTimestamp
MainPID=262631
NRestarts=0
ExecMainStartTimestamp=Wed 2026-08-12 00:32:15 EEST

$ cat /proc/262631/cgroup
0::/user.slice/user-1000.slice/user@1000.service/app.slice/app-graphical.slice/quickshell.service

$ hyprctl layers -j | jq -r '..|.namespace? // empty' | sort | uniq -c
      1 awww-daemon
      1 quickshell-bar

$ hyprctl monitors -j | jq -c '[.[].reserved]'
[[0,48,0,0]]

$ ~/.config/hypr/scripts/bar-visibility.sh status
visible

$ cat ~/.local/state/theme/current-theme
catppuccin

$ grep -rn 'Timer\s*{' quickshell/.config/quickshell/modules/ | grep -v '^\s*//' | wc -l
34
```

**The reserved array is `[[0,48,0,0]]`, not the `[[0,46,0,0]]` every earlier phase-18
artifact records.** This is a real, intended change, not drift: `Design.barHeight` is `42`
and `Design.barEdgeMargin` is `6`, and Phase 18.1 raised `barHeight` from 40 to upstream
Athena's own `"height": 42` (`ATHENA-UPSTREAM-SPEC.md`). `Bar.qml`'s own arithmetic comment
still claimed 46 and was corrected against this live reading. **18-19's fingerprint and
18-20's parity statement both name `[0,46,0,0]` and are stale by 2px** — both were written
before 18.1 existed. Neither should be "made to pass"; both should record the live 48 with
this reason.

**Start-capture summary (the anchor):** pid `262631`, `NRestarts=0`, unit start
2026-08-12 00:32:15 EEST, RSS `477016` KiB, etimes `2011` s at window open (well past the
10-minute settle precondition), one `quickshell` process, one long-lived child by command
(`swaync-client -swb`), wake rate `6.9533`/sec and CPU rate `0.001167` cpu-sec/sec over a
real 300 s observation, `quickshell-bar` the sole quickshell layer namespace, reserved
`[[0,48,0,0]]`, bar visible, theme `catppuccin`, 34 module `Timer {}` declarations.

### Re-anchored thresholds

Section three's tolerance *percentages* were pre-declared before any result existed and are
unchanged. Only the absolute values are recomputed, because they are defined relative to a
start rate and the start rate was re-taken:

| Gate | Anchor (start) | Pre-declared tolerance | Absolute band for the end capture |
|---|---|---|---|
| Wake rate | `6.9533`/sec | ±20% | `5.5626` – `8.3440`/sec inclusive |
| CPU-time rate | `0.001167` cpu-s/s | ±25% | `0.00087525` – `0.00145875` inclusive |
| RSS magnitude | `477016` KiB | ≤32 MiB total AND ≤5 MiB/hour | ceiling `509784` KiB; rate ≤`5120` KiB/hour |
| RSS shape | — | final-third growth ≤ 2× first-third growth | ≥5 samples spaced through the window |
| Process count | 1 process, 1 child | exact equality | `pgrep -c -x quickshell` == 1; child **command** set == {`/usr/bin/swaync-client -swb`} |
| Hot-zone namespaces | — | exactly 0, no tolerance | 0 `quickshell-bar-hotzone` after the 200-cycle exercise |
| Window | etimes `2011` s at open | ≥14400 s, `NRestarts` unchanged | earliest valid end capture ≈ **04:32:15 EEST** |

## Section four-ter — **THE LIVE ANCHOR** (2026-08-12 01:21, post-reboot)

Section four-bis is **also void**: the host rebooted at 01:09 (`who -b`), taking `quickshell`
from pid `262631` to `1626`. That is the third void in this plan's history and it is the
finding, not a footnote — **a valid QBAR-11 window needs four hours with no reboot and no
`quickshell` restart, and that constraint, not the measurement, is what makes this task
hard.** waybar was stopped again before this capture (it autostarts; see below) and the
mandatory 10-minute settle was waited out (`etimes` 612 s at capture start).

```
$ systemctl --user show quickshell.service -p NRestarts -p MainPID -p ExecMainStartTimestamp
MainPID=1626
NRestarts=0
ExecMainStartTimestamp=Wed 2026-08-12 01:09:39 EEST

$ ps -o rss=,etimes= -p 1626      # RSS sample 1 of >=5
221928   1010

T0 = 1786486890   vol=8957   nonvol=544    utime=109  stime=65
T1 = 1786487190   vol=12015  nonvol=659    utime=136  stime=80
elapsed = 300s
wake_delta      = (12015-8957) + (659-544) = 3058 + 115 = 3173
cpu_ticks_delta = (136-109)    + (80-65)   =   27 +  15 =   42 ticks

$ awk -v w=3173 -v t=300 'BEGIN{printf "%.4f\n", w/t}'
10.5767   # wakes/sec — THE ANCHOR RATE
$ awk -v c=42 -v t=300 'BEGIN{printf "%.6f\n", (c/100)/t}'
0.001400  # cpu-sec/sec — THE ANCHOR RATE

$ hyprctl layers -j | jq -r '..|.namespace? // empty' | sort | uniq -c
      1 awww-daemon
      1 quickshell-bar
$ hyprctl monitors -j | jq -c '[.[].reserved]'
[[0,48,0,0]]
$ pgrep -c -x waybar
0
$ ~/.config/hypr/scripts/bar-visibility.sh status
visible
$ cat ~/.local/state/theme/current-theme
catppuccin
$ grep -rn 'Timer\s*{' quickshell/.config/quickshell/modules/ | grep -v '^\s*//' | wc -l
34
```

**RSS is 221928 KiB here against 477016 KiB in Section four-bis — do not read that as a
28 MiB-per-hour leak.** The two numbers are from different process lifetimes: four-bis
measured a process that had been up through an entire 18.1 rebuild session, this one is
10 minutes past a cold boot. **The RSS series across sections four / four-bis / four-ter is
not a series at all** and no growth figure may be derived from it. Only samples taken
*within* this window, against pid `1626`, are comparable — which is exactly why Section
three demands at least five spaced samples rather than two endpoints.

### Live thresholds — judge the end capture against THESE

| Gate | Anchor (start) | Pre-declared tolerance | Absolute band for the end capture |
|---|---|---|---|
| Wake rate | `10.5767`/sec | ±20% | `8.4614` – `12.6920`/sec inclusive |
| CPU-time rate | `0.001400` cpu-s/s | ±25% | `0.00105000` – `0.00175000` inclusive |
| RSS magnitude | `221928` KiB | ≤32 MiB total AND ≤5 MiB/hour | ceiling `254696` KiB; rate ≤`5120` KiB/hour |
| RSS shape | — | final-third growth ≤ 2× first-third growth | ≥5 samples spaced through the window |
| Process count | 1 process, 1 child | exact equality | `pgrep -c -x quickshell` == 1; child **command** set == {`/usr/bin/swaync-client -swb`} |
| Hot-zone namespaces | — | exactly 0, no tolerance | 0 `quickshell-bar-hotzone` after the 200-cycle exercise |
| Window | unit start 01:09:39 | ≥14400 s, `NRestarts` unchanged | earliest valid end capture ≈ **05:09:39 EEST** |

**Resume with `PID=1626`.** Section five's command set is otherwise correct as written; ignore
its `737907` and the four-bis `262631`, and intersect the child set by **command**, not pid.

**waybar must be off for the end capture too.** It autostarts from
`hypr/.config/hypr/config/autostart.lua:62` (`waybar-launch.sh`), so it will be running again
after any reboot. If it is up, the reserved array reads `[[0,94,0,0]]` and the start/end
comparison breaks. Stop it before the end capture, or the window is unusable.

## Section five — the soak protocol (instructions for the deferred Task 4)

> **Re-anchored 2026-08-12.** Every `737907` below is superseded by **`262631`**, and the
> two comparison rates by **`6.9533`** wakes/sec and **`0.001167`** cpu-sec/sec — see
> Section four-bis, which is the live anchor. The child intersection must be taken on
> **command**, not pid. The original text is left intact so the procedure it describes is
> still readable end-to-end.

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
PID=262631   # re-anchored 2026-08-12; must still be the SAME pid, else the window is void
             # (NRestarts must also still read 0 — check BOTH, a restart can reuse neither)
ps -o etimes= -p "$PID"                                   # must be >= 14400
systemctl --user show quickshell.service -p NRestarts     # must still read 0

# End capture — identical command set to Section four, same pid, same order
ps -o rss=,vsz=,etimes= -p "$PID"
pgrep -c -x quickshell
pgrep -P "$PID"; sleep 10; pgrep -P "$PID"                # intersect by COMMAND, not pid:
  # ps -o cmd= -p <each>  and compare the command SETS. A pid that changed while the
  # command persisted is a re-spawn to note, NOT a dead subscription. Proven live
  # 2026-08-12: 262662 -> 424020, same swaync-client -swb. See Section four-bis.
awk '/^voluntary_ctxt_switches:/{print $2}' /proc/"$PID"/status
awk '/^nonvoluntary_ctxt_switches:/{print $2}' /proc/"$PID"/status
awk '{print $14, $15}' /proc/"$PID"/stat
# ...repeat the 300s observation exactly as Section four-bis did, then diff both rates
# against 6.9533 wakes/sec (band 5.5626-8.3440) and 0.001167 cpu-sec/sec
# (band 0.00087525-0.00145875) — see "Re-anchored thresholds" in Section four-bis.
# The 19.3429 / 0.002476 pair belongs to the VOID pre-18.1 window; do not use it.
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
