# QS-03 Evidence — Phase 12 Plan 01 (D-12 bounded targeted fix)

**Branch reached: STOP.** Budget clause hit: Stage A exhausted (both permitted arrangements
tried, one 10-restart proof run each, both failed the per-screen surface creation check on
the identical failure signature) plus one Stage B escape-hatch diagnostic, which confirmed
rather than resolved the failure. `quickshell-doctor` summary line, unchanged from the
pre-task baseline: **`Summary: 13 passed, 1 failed`**, exit 1, with the single failure being
`per-screen surface creation (QS-03)`. No other check regressed.

This plan deliberately does not cross the D-13 one-way door — that decision belongs to
Plan 12-02's opening `checkpoint:decision`, which reads this record.

## Precondition confirmed

Before any change: `pgrep -x quickshell` returned a PID (305128), and
`quickshell-doctor` reported exactly `13 passed, 1 failed`, exit 1, with the per-screen
surface creation check as the sole failure — matching the baseline this task is required to
measure against (11-VERIFICATION.md's recorded override).

## Part 1 — `modules/qmldir` (kept; the fix that worked)

Ran `quickshell -p ~/.config/quickshell -v -v` against the CURRENT unmodified tree before
writing anything, and read the synthesised registration lines back out of the trace, per the
task's own instruction to match the exact grammar rather than trust the doc form:

```
DEBUG quickshell.qmlscanner: Scanning directory ".../modules"
DEBUG quickshell.qmlscanner: Scanning qml file ".../modules/Probe.qml"
DEBUG quickshell.qmlscanner: Scanning qml file ".../modules/ScreencopyProbe.qml"
DEBUG quickshell.qmlscanner: Synthesizing qmldir for directory ".../modules"
DEBUG quickshell.qmlscanner: Synthesized qmldir for ".../modules"
module qs.modules
Probe 1.0 Probe.qml
ScreencopyProbe 1.0 ScreencopyProbe.qml
```

**Deviation from the plan's prose, resolved in favour of the verified trace (the plan's own
methodology):** the plan's action text speculated the checked-in file should carry "type
entries only and no `module` header line," but the actual synthesised grammar from this
build includes a `module qs.modules` header line. Per the task's own instruction ("match
that exact grammar rather than trusting the doc form"), `modules/qmldir` was written
byte-matching the verified synthesis, header line included. `git status --porcelain` +
`grep -cE '^(Probe|ScreencopyProbe) ' quickshell/.config/quickshell/modules/qmldir` → `2`.

**RESEARCH.md finding 4 — `[CITED: DeepWiki quickshell-mirror docs]` — CONFIRMED true on
this build**, resolving the plan's own `flagged_assumptions` note. Re-running the trace
after the qmldir was checked in shows:

```
DEBUG quickshell.qmlscanner: Scanning directory ".../modules"
DEBUG quickshell.qmlscanner: Scanning qml file ".../modules/Probe.qml"
DEBUG quickshell.qmlscanner: Found qmldir file, qmldir synthesization will be disabled
  for directory ".../modules"
DEBUG quickshell.qmlscanner: Scanning qml file ".../modules/ScreencopyProbe.qml"
```

The scanner still *walks* the directory (it must, to find the qmldir file itself) but
explicitly disables synthesis once it finds one — a structural fix for FM1's exact
failure mode. This was independently confirmed by the clean 10-restart proof below: **zero**
occurrences of `is not a type` or `Failed to load configuration` across 10 consecutive
`pkill -x quickshell` + `quickshell-launch.sh` cycles, for both arrangement A and
arrangement B. FM1 is closed by this file alone, regardless of which per-screen fan-out
arrangement sits on top of it.

## Part 2 — Per-screen fan-out (both arrangements failed identically)

### Arrangement A — `Variants` + per-screen `LazyLoader` declared in `shell.qml`

Exact shape specified in the plan: `root.probeActive` property, `Variants { model:
Quickshell.screens }` wrapping a `Component { LazyLoader { active: root.probeActive;
Probe { screen: modelData; onDismissRequested: ... } } }`, `probeShortcut.onPressed`
toggling `root.probeActive`. `Probe.qml` itself unchanged except no source edit was needed
(`screen` is a plain writable `PanelWindow` property, confirmed directly against
`/usr/lib/qt6/qml/Quickshell/_Window/quickshell-window.qmltypes`: `write: "setScreen"`).

One incidental fix needed beyond the plan's literal text: `shell.qml` had no `QtQml`
import, and `Component` is a `QtQml` type, not a `Quickshell` one — the first load attempt
failed with `Component is not a type` at `shell.qml[44:9]`. Added `import QtQml`
(Rule 3 — blocking issue for this task, not an architectural change). A second, separate
fix: Quickshell's `Variants` sets `modelData` as an **initial property** on the delegate
root object for non-`Item` roots like `LazyLoader` (not merely a context property, as
`Item`-rooted `Repeater` delegates get) — the first clean load logged `WARN: LazyLoader
does not have a property called modelData`. Declaring `required property var modelData`
directly on the `LazyLoader` root removed the warning.

**10-restart proof (arrangement A, one run, as budgeted):** 10 consecutive
`pkill -x quickshell` (awaited to a clean `pgrep` miss) + `quickshell-launch.sh` relaunches.
`grep -c "is not a type"` → `0`. `grep -c "Failed to load configuration"` → `0`. Clean.

**Single-screen summon/dismiss (arrangement A):** `hyprctl dispatch global
quickshell:probe` created exactly one `quickshell-probe` surface on `DP-1`
(`{"address":"0x55e12227e680", ..., "namespace":"quickshell-probe"}`); a second dispatch
destroyed it (`hyprctl layers -j` → `[]`). Correct.

**Two-screen hotplug test (arrangement A) — FAILED, reproducing FM2 verbatim.** With the
probe already active and visible on `DP-1`, creating a headless output
(`hyprctl output create headless`) caused the existing `DP-1` surface to disappear
immediately — before any shortcut was pressed — and no surface appeared on the new output
either. Four further shortcut dispatches (on/off/on/off) with the second screen present
produced zero surfaces on either screen every time, while still generating a fresh
`FileView`/`JsonAdapter` "File does not exist" warning per screen per toggle — i.e. new
`Probe` instances were genuinely being constructed internally, but no wl_surface from any
of them ever mapped, on any output, at any point after the second screen existed. This
matches 11-QUICKSHELL-EVIDENCE.md's FM2 description exactly: *"once a second screen
existed, the shortcut stopped toggling any screen's visibility at all, including the
previously-working instance."* `quickshell-doctor`'s per-screen check on this arrangement:
`exactly one quickshell-probe surface under DP-1 (found: 0) and exactly one under
HEADLESS-27 (found: 0)` — worse than a one-sided miss, both sides empty.

Arrangement A was reverted (moved to arrangement B) after this one budgeted proof run, per
the "each arrangement gets exactly ONE 10-restart proof run" clause — the two-screen
failure itself was caught well within that one run's follow-on checks, no iteration
attempted on arrangement A itself.

### Arrangement B — `Variants` rooted inside `Probe.qml`, `shell.qml` touches `Probe` once

Per the plan's specified fallback: `Probe.qml`'s root type changed from `PanelWindow` to
`Variants` (`model: Quickshell.screens`, `delegate: Component { LazyLoader { ... PanelWindow
{ screen: modelData; ... } } }`), with a root-level `property bool active` and `signal
dismissRequested()` that every per-screen delegate binds to / emits. `shell.qml` was
reduced to a single `Probe { id: probeInstance; onDismissRequested: probeInstance.active =
false }` plus `GlobalShortcut.onPressed: probeInstance.active = !probeInstance.active` —
touching the local `Probe` type exactly once, as specified. This is the combination
11-QUICKSHELL-EVIDENCE.md's own arrangement 3 did NOT have available: that record's
attempt at this exact structural shape (`Variants` rooted inside `Probe.qml`) predates
this plan's checked-in `qmldir`.

**Foreground `-v -v` load trace (arrangement B, clean tree, before daemon restart):** no
warnings, `INFO: Configuration Loaded`. The `modelData` warning did not recur because the
`required property var modelData` declaration was included on the `LazyLoader` from the
first version of this arrangement.

**10-restart proof (arrangement B, one run, as budgeted):** 10 consecutive
`pkill -x quickshell` + `quickshell-launch.sh` relaunches. `grep -c "is not a type"` → `0`.
`grep -c "Failed to load configuration"` → `0`. Clean — confirms the qmldir fix (Part 1)
holds independent of which file owns the `Variants` fan-out.

**Single-screen summon/dismiss (arrangement B):** exactly one surface created then
destroyed on `DP-1`, same as arrangement A. Correct.

**Two-screen test (arrangement B) — FAILED, same signature as arrangement A, and
additionally isolated to NOT be a hotplug-timing race:**
- With headless created while the probe was inactive, then toggled on: zero surfaces on
  either `DP-1` or the new output, though two fresh `FileView` "File does not exist"
  warnings confirmed two `Probe` instances were constructed.
- **Isolating hotplug timing as a variable:** the daemon was fully restarted with the
  headless output already present *before* the process started (both screens exist from
  `t=0`, no hotplug transition occurs at all during the daemon's lifetime) — toggling the
  probe on still produced zero surfaces on either screen. This rules out a hotplug-specific
  race as the mechanism; the failure is present in general multi-screen fan-out, not
  specifically triggered by a screen appearing after startup.
- **Isolating an incubation/timing delay as a variable (the Stage B escape-hatch
  attempt):** re-ran the same test waiting 5 seconds after the dispatch before checking
  `hyprctl layers -j` (versus the usual 0.3-0.6s). Still zero surfaces on both screens.
  Traced with `-v -v` down to `DEBUG quickshell.incubator: Incubation mode changed: event
  loop driven` as the last relevant line after both `FileView` async loads complete — no
  further layer-shell surface-creation debug output follows, no crash, no QML exception
  printed, nothing in `hyprctl layers -j` on any monitor at all
  (`[{"monitor":null,"layers":[]},{"monitor":null,"layers":[]}]`).
- `quickshell-doctor`'s per-screen check on the final, restored-to-baseline state:
  `exactly one quickshell-probe surface under DP-1 (found: 0) and exactly one under
  HEADLESS-31 (found: 0)`.

**Conclusion on the failure mechanism:** both arrangements — differing only in which file
owns the `Variants` block — hit an identical symptom (zero surfaces created on any screen
once ≥2 `PanelWindow` instances descend from the same `Variants` fan-out, confirmed
independent of hotplug-vs-startup timing and independent of a 5-second incubation delay).
This points at a deeper limitation in this quickshell 0.3.0-2 build's `Variants` +
`PanelWindow` interaction for `wl_surface` creation under multiplicity, not at either
arrangement's specific code shape, and not at a scanner/config-load race (Part 1's qmldir
fix is confirmed working and orthogonal — FM1 is closed in both arrangements' 10-restart
proofs). A namespace-collision hypothesis (two simultaneous `"quickshell-probe"`-namespaced
surfaces) was considered but not spiked as a code change, since `quickshell-doctor`'s
per-screen check (out of this plan's file scope) hardcodes the literal string
`"quickshell-probe"` for both monitors' entries — any fix requiring a per-screen namespace
would also require modifying the doctor script, which is not in this plan's declared
`files_modified` list and would be an undisclosed scope expansion.

## Budget clause hit

Stage A budget: "at most TWO arrangements... each arrangement gets exactly ONE 10-restart
proof run." Both arrangement A and arrangement B were attempted, each given its one
10-restart proof run (both clean on FM1) plus the mandatory two-screen verification test
(both failed on the fan-out itself). Stage B's "ONE further escape-hatch spike hypothesis"
was spent isolating the failure from a hotplug-timing race to a general multiplicity issue
(the 5-second incubation-delay wait) — this is diagnostic value, not a resolving fix, and
the STOP condition applies: **do not try a third arrangement, do not iterate, do not
open-endedly hunt a workaround.**

## Final state left behind

- `quickshell/.config/quickshell/modules/qmldir` — new, tracked, closes FM1 permanently
  regardless of arrangement (confirmed via two independent clean 10-restart runs).
- `quickshell/.config/quickshell/shell.qml` and `quickshell/.config/quickshell/modules/Probe.qml`
  — left on arrangement B (the `Variants`-rooted-in-`Probe.qml` shape), since it is
  functionally equivalent to the pre-existing single-screen design for the one physical
  monitor this host has in daily use, and is the more contained of the two failed
  arrangements (shell.qml touches `Probe` exactly once, matching the pre-Phase-12 design's
  shape).
- `quickshell-doctor` final state: **`Summary: 13 passed, 1 failed`, exit 1** — identical
  to the pre-task baseline, with the sole failure still `per-screen surface creation
  (QS-03)`. No other check regressed. `git status --porcelain quickshell/` shows only the
  intended `qmldir` addition plus the arrangement-B modifications to `shell.qml` and
  `Probe.qml` — nothing half-applied.
- Daemon left running and healthy: `pgrep -x quickshell` returns a PID, `hyprctl dispatch
  global quickshell:probe` on `DP-1` alone still creates exactly one surface and a second
  press destroys it, launcher log has no crash/abort marker.

## Consequence for Plan 12-02

Plan 12-02's opening blocking `checkpoint:decision` reads this record. QS-03's per-screen
fan-out was re-attempted with two structurally distinct, targeted hypotheses (not a repeat
of either of 11-04's two failure modes verbatim, though arrangement A's two-screen failure
signature matches FM2's description very closely) and both failed identically, with the
failure now further isolated to a general `Variants`/`PanelWindow` multiplicity limitation
on this quickshell 0.3.0-2 build rather than a hotplug-specific race. The bounded fix and
the escape-hatch spike are both exhausted; D-13's permanent-limitation branch is now the
live decision for Plan 12-02 to make or defer.
