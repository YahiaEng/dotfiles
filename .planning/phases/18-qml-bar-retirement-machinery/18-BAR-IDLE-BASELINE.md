# 18-01: Bar Idle Cost Floor Baseline

Captured at tracer scope (Phase 18 Plan 01, Task 3) — one `PanelWindow`, one
capsule, one `SystemClock` at minute precision, and zero widened backend
gates. This is a capture document, not an analysis document: numbers and
the commands that produced them, no pass/fail threshold, no conclusion.

**Why taken here, not in 18-18:** after wave 3 the bar carries six capsules
and several permanently-widened backend gates (18-08's readouts, D-18-05's
`MediaBackend` repoint among them), and there is no minimal bar left to
measure at that point. QBAR-11's soak in 18-18 needs a *start* number taken
before any of that widening, or its RSS and process-count deltas cannot be
attributed to a specific widening rather than read as unexplained creep.

Captured 2026-08-11, after the tracer bar (commits `beab39b`, `071ee01`) had
been mounted and settled for over five minutes (precondition satisfied —
see the executor's own wait log; `quickshell`'s own process `etime` below
shows the process itself has been running far longer, since this is a
hot-reloaded config change, not a process restart).

## Resident set size

```
$ ps -o rss=,vsz=,etime= -p "$(pgrep -x quickshell)"
445104 1228812  15:51:12
```

RSS: **445104 KiB** (~435 MiB). VSZ: 1228812 KiB. The process itself has
been up 15h51m12s at capture time — this is the same long-lived `quickshell
-p ~/.config/quickshell` process from the last full launch
(`quickshell-launch.sh: starting 2026-08-10T10:19:46+03:00`, per
`~/.cache/quickshell.log`); the bar's own code has been live in it for just
over 5 minutes via hot reload, not via a fresh process start. RSS at this
point reflects the WHOLE shell (dashboard, panels, overview, probes — every
surface this repo has shipped through Phase 17), not the bar in isolation;
there is no mechanism in this repo to attribute RSS to one QML file. Cited
as the whole-process floor 18-18 diffs against.

## Process count

```
$ pgrep -c -x quickshell
1
```

One `quickshell` process, as expected — `quickshell-launch.sh` execs a
single `quickshell -p` with no wrapper.

```
$ pgrep -a -f 'quickshell|elephant|walker'
58353 quickshell -p /home/aorus/.config/quickshell
58356 /usr/bin/elephant
624333 /usr/bin/walker --gapplication-service
```

Three shell-adjacent processes at capture time: `quickshell` itself,
`elephant` (walker's backend data daemon), and `walker --gapplication-service`
(the launcher's own idle-resident GTK4 frontend). Note on measurement
method: the raw `pgrep -a -f 'quickshell|elephant|walker' | wc -l` command,
run directly inside this executor's own shell tool, returns `4` rather than
`3` — the invoking harness wraps every command in a `zsh -c '...'` snapshot
subshell whose OWN command-line text contains the literal search pattern
(`'quickshell|elephant|walker'`), so `pgrep -f` matches that wrapper
process too. This is a measurement-tool artifact, not a fourth real
process; the three-line list above is the filtered, accurate reading
(`pgrep -a -f 'quickshell|elephant|walker' | grep -vE '/usr/bin/zsh -c'`).
Recorded here explicitly so 18-18 does not misread a future `4` as a real
regression without checking for the same artifact.

## Child processes of quickshell

```
$ pgrep -P "$(pgrep -x quickshell)" | wc -l
0
```

Zero child processes, as expected at tracer scope — the bar shells out to
nothing. `quickshell-launch.sh` confirms this is a single `quickshell -p`
exec with no wrapper, so the process count is expected to be exactly one at
this point in the phase, and it is.

## Declared timer inventory (source-derived, not guessed)

```
$ grep -rn 'Timer\s*{' quickshell/.config/quickshell/modules/ | grep -v '^\s*//' | wc -l
21
```

21 declared `Timer {` blocks across the whole `modules/` tree — these
belong to the pre-existing Phase 14-17 surfaces (Dashboard tabs, panels,
overview), all already gated on their own `LazyLoader.active`/backend
`drawerOpen`/`panelOpen` flags per the zero-idle doctrine (D-32/D-36), so
none of them run while their owning surface is dismissed.

```
$ grep -rn 'Timer\s*{' quickshell/.config/quickshell/modules/Bar.qml | grep -v '^\s*//' | wc -l
0
```

Zero declared `Timer {` blocks in `Bar.qml` itself — the clock is driven
by `SystemClock` at `precision: SystemClock.Minutes`, per the phase's
named permanent-liveness discipline (the bar has no dismissed state, so a
repeating `Timer` would be a permanent per-second/per-minute wake for the
life of the session; `SystemClock` wakes once per minute, event-driven).

## Live theme and orientation state at capture time

```
$ cat ~/.local/state/theme/current-theme
catppuccin
```

Theme state read from `~/.local/state/theme/current-theme` — this is the
authoritative path (see the project's own recorded finding: a same-named
orphan file exists under `~/.cache/` in this repo, looks plausible, and
reports a stale value; it is NOT cited here). Live theme at capture time:
`catppuccin`. Orientation: horizontal only (the bar's only orientation at
tracer scope — the vertical layout and orientation-switch property are
18-05's).

## Still-narrow backend gates at this point (for 18-18 to diff against)

`MediaBackend`, `WeatherBackend`, `SystemResources` and `AudioBackend` are
ALL still gated on a `LazyLoader.active` flag (`dashboardLoader.active` for
the first three, `root.audioTruthNeeded` — itself
`dashboardLoader.active || audioPanelLoader.active` — for the fourth; see
`shell.qml`), so all four are inert while the drawer and audio panel are
closed. The bar mounted in this plan reads none of them; it renders only
its own `SystemClock`-driven wall-clock text.

Two known widenings will move these numbers, named here so 18-18's later
measurement is an attributable charge rather than an unexplained creep:

1. **18-08's readouts** — the bar's media/weather/resource capsules will
   read these backends directly from the always-mounted bar, which (per
   `18-RESEARCH.md` Pitfall 7) will widen at least `MediaBackend`'s and
   `WeatherBackend`'s and `SystemResources`'s gates from
   "some LazyLoader is active" to "the bar is mounted" — i.e. permanently
   on for the session, not merely while the drawer is open.
2. **D-18-05's `MediaBackend` repoint** — a second, phase-scoped structural
   change to the same backend's ownership/gating, named in `18-CONTEXT.md`.

Neither widening has happened yet at this baseline's capture point — the
bar mounted here reads zero backends beyond its own `SystemClock`. No
verdict is asserted on whether either widening is acceptable; that is
18-18's (QBAR-11's) job, using this document as its start reading.
