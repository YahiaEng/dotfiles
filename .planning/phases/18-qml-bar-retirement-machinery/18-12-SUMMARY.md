---
phase: 18-qml-bar-retirement-machinery
plan: 12
subsystem: ui
tags: [quickshell, qml, pipewire, brightnessctl, wheel-scroll]

# Dependency graph
requires:
  - phase: 18-08
    provides: "MediaConnectivityCapsule.qml filled with five readout entries (media/audio/network/bluetooth/battery), the shared Readout inline component, and the audio entry AudioBackend.masterVolume reads"
provides:
  - "Audio wheel-to-adjust: a WheelHandler on the audio entry, clamped 0..1, writing only through AudioBackend.setMasterVolume() (the pre-existing single writer)"
  - "BrightnessBackend.qml — a new bar-local singleton: hardware-presence probe (brightnessctl -m -l --class backlight), single-flighted coalescing adjust() writer, zero timers"
  - "A sixth mediaConnectivity entry (brightness), present-but-inert on this host, gated on real hardware presence"
  - "Design.qml + barScrollStepPercent (5)"
  - "18-SCROLL-GATE-RECORD.md — GATE-02 B.3's brightness verdict, the workspace-scroll cut with its pre-specified remedy, and both UI-SPEC deltas this plan creates"
affects: [18-13, 18-14, 18-19]

actuals:
  tokens: 8270
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Notch-accumulated WheelHandler idiom: target null, no property attribute, angleDelta.y summed into a signed running total with one step emitted per whole 120 units and the remainder carried forward — used identically for both scroll targets in this file (audio and brightness) so a later reader (18-13, or a future workspace-scroll remedy) has one shape to copy."
    - "A bar-local backend singleton (BrightnessBackend.qml) rather than a shell.qml-mounted instance, specifically to keep MediaConnectivityCapsule.qml's own no-process/no-timer gate true while still shipping a real subprocess-backed capability — the process lives in the singleton, not the capsule."
    - "brightnessctl's long-form --class flag used deliberately instead of -c: the short form, written as a QML array element with its trailing comma, is textually indistinguishable from a shell interpreter's own -c flag and would trip the file's own no-interpreter security gate."

key-files:
  created:
    - quickshell/.config/quickshell/modules/bar/BrightnessBackend.qml
    - .planning/phases/18-qml-bar-retirement-machinery/18-SCROLL-GATE-RECORD.md
  modified:
    - quickshell/.config/quickshell/modules/bar/MediaConnectivityCapsule.qml
    - quickshell/.config/quickshell/modules/bar/BarEntryModel.qml
    - quickshell/.config/quickshell/modules/bar/qmldir
    - quickshell/.config/quickshell/modules/dashboard/Design.qml

key-decisions:
  - "brightnessctl's --class/--device long-form flags used instead of -c/-d specifically to avoid the short -c form colliding textually with a shell interpreter's own -c flag in the file's own no-interpreter grep gate (T-18-12-01) — not a stylistic choice, a gate-driven one."
  - "BrightnessBackend's deviceClass property stays readonly, changed only by editing source and letting quickshell hot-reload — matching the plan's own presence-positive proof method (repoint to the leds class, confirm, revert) rather than adding a runtime override knob that would itself need justifying."
  - "GATE-02 criterion B.3's brightness half recorded as 'not demonstrable on this hardware — structurally present', never as a pass — the wording D-18-39 requires, with the already-dead baseline (18-BEHAVIOUR-BASELINE.md's Dead Definitions row for floating's backlight module) cited as the reason it cannot be a regression."

patterns-established:
  - "This phase's established 'skip live verification, ship fast' operating mode continued here: all automated grep/regex <verify> assertions in both tasks' acceptance_criteria were run and passed (plus the safe read-only live probes — hyprctl layers namespace check, quickshell log tail, brightnessctl -c backlight/-c leds live probes, the -p pretend-mode argv proof, pgrep stray-child check). The genuinely interactive halves — scrolling the bar with a real pointer while reading wpctl/the bar's own percent, and the human render-gate comparing before/after with the device class temporarily repointed — were NOT performed this session (the running quickshell process is a long-lived instance that predates this plan's changes and has not hot-reloaded against them). Matches 18-08's identical precedent, logged the same way."

requirements-completed: [QBAR-04]

coverage:
  - id: D1
    description: "Scrolling the bar's audio entry adjusts real system volume through AudioBackend.setMasterVolume(), clamped to 0..1 at the call site, with one notch (120 angleDelta.y units) mapping to one Design.barScrollStepPercent (5) step"
    requirement: "QBAR-04"
    verification:
      - kind: other
        ref: "Task 1 automated <verify> grep/regex script — all assertions run and passed (commit 2a92ece): exactly one WheelHandler, target null, no property attribute, writes only through audioBackend.setMasterVolume(), no raw PipeWire node reference, clamp present, step read from Design.barScrollStepPercent, angleDelta/120 notch accumulator present, narrowed 18-08 gate holds, all other 18-08 file invariants intact"
        status: pass
    human_judgment: true
    rationale: "The plan's own <verify> requires live confirmation on the running bar: three wheel-up notches raising wpctl get-volume by 15 points with the bar's own percent agreeing, and the unity/zero bound holding under sustained scrolling at both ends. Not performed this session — the live quickshell process predates this plan's code and was not restarted/reloaded, matching this phase's established render-gate deferral pattern (18-08-SUMMARY's identical precedent). Deferred to the user per D-18-31/GATE-02."
  - id: D2
    description: "BrightnessBackend.qml singleton: hardware-presence probe (brightnessctl -m -l --class backlight, parsed once at construction, present/deviceName/percent set only from real probe output), single-flighted coalescing adjust(steps) writer using brightnessctl's own delta forms, zero timers"
    requirement: "QBAR-04"
    verification:
      - kind: other
        ref: "Task 2 automated <verify> grep/regex script — all assertions run and passed (commit 3bb654b): pragma Singleton + qmldir registration in the same commit, present never a hardcoded constant, deviceClass readonly at its 'backlight' default, both Process argv arrays fixed literals headed by 'brightnessctl', no interpreter/-c-flag collision, single-flight guard + pending accumulator present, zero Timer/interval/repeat, exactly two Process blocks"
        status: pass
      - kind: other
        ref: "Live, both directions, this session: `brightnessctl -m -l -c backlight` prints 0 device lines (presence-negative, the real state of this host); `brightnessctl -m -l -c leds` prints 8 real device lines (presence-positive class); the exact argv shape adjust() builds, run via brightnessctl's own -p (pretend/no-write) mode against a real leds device, exits 0 and prints a well-formed five-field machine-readable line; `pgrep -c brightnessctl` returns 0 with no gesture in flight"
        status: pass
    human_judgment: true
    rationale: "The plan's human-check requires editing the running backend's deviceClass property, confirming quickshell hot-reloads a real glyph+percentage from the leds class, scrolling it and watching the percentage move, then reverting and confirming the entry vanishes with no gap — plus confirming the entry renders correctly in vertical orientation. Not performed this session for the same reason as D1 (the live process predates this plan's code). The automated grep sweep and the safe read-only live probes above were all run and passed; only the pointer-driven and hot-reload-dependent halves are deferred. Per D-18-31/GATE-02, this human-check explicitly does NOT establish B.3's brightness half as demonstrable — see 18-SCROLL-GATE-RECORD.md § 1, which records that verdict independently of this deferral."
  - id: D3
    description: "18-SCROLL-GATE-RECORD.md — GATE-02 B.3's brightness verdict recorded verbatim as 'not demonstrable on this hardware — structurally present' with re-runnable evidence, the workspace-scroll cut recorded as a routing decision with a complete pre-specified remedy, both UI-SPEC deltas (E3 zero-one-many, missing barScrollStepPercent token row), and the narrowed 18-08 pointer-handler gate with its operational consequence"
    requirement: "QBAR-04"
    verification:
      - kind: other
        ref: "Task 3 automated <verify> grep/regex script — all assertions run and passed (commit 60160e9): all five section topics present, verdict wording present verbatim, no affirmative status marker on any B.3 line, all required evidence strings present (brightnessctl -m -l -c backlight, /sys/class/backlight/, Dead Definitions, keybinds.lua, e+1, e-1, zero-one-many, barScrollStepPercent, superseded), remedy names WorkspaceCapsule.qml, cut is justified by routing not difficulty, no implementation code smuggled in"
        status: pass
    human_judgment: false
duration: ~35min
completed: 2026-08-11
status: complete
---

# Phase 18 Plan 12: Scroll-to-Adjust (Audio Live, Brightness Present-but-Inert) Summary

**QBAR-04's scroll gesture lands on the bar: one WheelHandler adjusts real PipeWire volume through the pre-existing `AudioBackend.setMasterVolume()` writer with a call-site unity clamp, and a second WheelHandler drives a brand-new `BrightnessBackend.qml` singleton — hardware-presence-gated, single-flighted, zero-timer — that renders nothing on this desktop board and a real percentage on any host with a backlight, proven in both directions against the real `brightnessctl` binary.**

## Performance

- **Duration:** ~35 min
- **Started:** 2026-08-11 (session start)
- **Completed:** 2026-08-11
- **Tasks:** 3 (all completed)
- **Files modified:** 6 (1 new QML singleton, 1 new planning artifact, 4 modified)

## Accomplishments

- **Task 1 (tracer):** `Design.qml` gained `barScrollStepPercent: 5` (append-only, three-source provenance comment). `MediaConnectivityCapsule.qml`'s audio entry gained a `WheelHandler` (`target: null`, no `property:` attribute) that accumulates `angleDelta.y` into signed 120-unit notches, reads `AudioBackend.masterVolume` fresh on every step (never a locally accumulated total), clamps the computed target to `0..1` at the call site, and writes only through `AudioBackend.setMasterVolume()` — no raw PipeWire node, no `Pipewire.*`, no `PwNode*` reference anywhere in the file. The file header was extended to record the 18-08/18-12 ownership split and the narrowed wave-3 pointer-handler freeze.
- **Task 2:** `BrightnessBackend.qml` (new singleton, both `pragma Singleton` and the `qmldir` `singleton` keyword, registered in the same commit) probes `brightnessctl -m -l --class backlight` once at `Component.onCompleted`, setting `present`/`deviceName`/`percent` only from parsed stdout — zero lines is a normal absence (brightnessctl writes its "no devices" message to stderr and exits non-zero on an empty class), never a failure. `adjust(steps)` is single-flighted with a signed `pendingDelta` accumulator (extending `MediaBackend.qml`'s own early-return-if-running idiom) and writes via `brightnessctl`'s own `+N%`/`N%-` delta forms, so the device's own min/max are enforced by the tool and this file never has to know a device's maximum. No timer anywhere. `BarEntryModel.qml` gained one `brightness` entry immediately after `audio` (six capsules, both zones, three aggregates all unchanged — re-verified by grep). `MediaConnectivityCapsule.qml` renders the entry gated on `BrightnessBackend.present` (zero extent/spacing when absent, matching the battery precedent), tints its glyph `Colours.error` on `BrightnessBackend.failed`, and carries a second `WheelHandler` calling `BrightnessBackend.adjust()` with a signed notch count — brightness itself never clamps a percent locally.
- **Task 3:** `18-SCROLL-GATE-RECORD.md` written: GATE-02 criterion B.3's brightness half recorded verbatim as **not demonstrable on this hardware — structurally present**, with re-runnable evidence (empty `/sys/class/backlight/`, `brightnessctl`'s own negative/positive probe output measured live this session, the argv proven via `-p` pretend mode) and the citation to `18-BEHAVIOUR-BASELINE.md`'s Dead Definitions row proving the baseline had nothing to regress from. The scroll-to-switch-workspaces cut is recorded as a routing decision (not difficulty), with `keybinds.lua`'s existing global Super+wheel binds quoted verbatim as the non-loss evidence and a complete mechanical remedy pre-specified (file, handler shape, both dispatch expressions). Both UI-SPEC deltas this plan creates (E3 zero-one-many's now-false exclusivity claim, the missing `barScrollStepPercent` New Tokens row) and the narrowed 18-08 gate with its operational consequence are recorded.

## Task Commits

Each task was committed atomically:

1. **Task 1: TRACER — one wheel gesture, end to end, from the bar to the system sink** — `2a92ece` (feat)
2. **Task 2: The brightness entry — present, portable, and rendering nothing on this host** — `3bb654b` (feat)
3. **Task 3: The record — what 18-19 must be told about scroll on this bar, in words it can use** — `60160e9` (docs)

**Plan metadata:** pending final commit (this SUMMARY + STATE.md + ROADMAP.md + REQUIREMENTS.md)

## Files Created/Modified

- `quickshell/.config/quickshell/modules/bar/BrightnessBackend.qml` — new singleton: presence probe, percent readout, single-flighted coalescing writer
- `quickshell/.config/quickshell/modules/bar/MediaConnectivityCapsule.qml` — audio + brightness `WheelHandler`s, one new brightness `Readout`, extended header
- `quickshell/.config/quickshell/modules/bar/BarEntryModel.qml` — one new `brightness` entry beside `audio`
- `quickshell/.config/quickshell/modules/bar/qmldir` — `BrightnessBackend` singleton registration
- `quickshell/.config/quickshell/modules/dashboard/Design.qml` — append-only, `barScrollStepPercent: 5`
- `.planning/phases/18-qml-bar-retirement-machinery/18-SCROLL-GATE-RECORD.md` — new, the GATE-02 B.3 record and workspace-scroll remedy

## Decisions Made

- **`--class`/`--device` long-form `brightnessctl` flags used instead of `-c`/`-d`** — the short `-c` form, written as a QML array element ending in a comma, is textually indistinguishable from a shell interpreter's own `-c` flag and would have tripped the file's own no-interpreter security gate (T-18-12-01). Not a style preference; the gate's own regex forced this choice.
- **`BrightnessBackend.deviceClass` stays `readonly`, repointed only by editing source** — matches the plan's own presence-positive proof method (change the property, let quickshell hot-reload, confirm, revert) rather than adding a runtime override property that would need its own justification and its own gate.
- **GATE-02 B.3's brightness half recorded as "not demonstrable — structurally present", never as a pass** — per D-18-39's required wording, cited against `18-BEHAVIOUR-BASELINE.md`'s own Dead Definitions row so the verdict is evidenced rather than asserted.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] `command:` literal-text collision in a header comment tripped the plan's own fixed-argv acceptance check**

- **Found during:** Task 2, running the acceptance-criteria grep sweep before commit
- **Issue:** The plan's own criterion asserts that every occurrence of the literal text `command:` in `BrightnessBackend.qml` must be immediately followed by `["brightnessctl"` (proving every argv is a fixed array headed by the tool name). A prose comment explaining the `_adjustDeltaForm` property used the phrase "the Process's own `command:` declaration", which itself contains the literal substring `command:` — tripping the same grep that's meant to catch a real un-prefixed invocation.
- **Fix:** Reworded the comment to say "argv declaration" instead of "`command:` declaration", describing the mechanism without repeating the gated identifier.
- **Files modified:** `quickshell/.config/quickshell/modules/bar/BrightnessBackend.qml`
- **Verification:** Re-ran the grep; count of `command:` occurrences now equals the count beginning with `"brightnessctl"` (2 and 2).
- **Committed in:** `3bb654b` (fixed before commit, not a separate correction commit)

---

**Total deviations:** 1 auto-fixed (Rule 3 — a self-inflicted drafting collision between a prose comment and the plan's own literal-text acceptance grep, caught and fixed before the task's commit).
**Impact on plan:** No behavior change. Comment-only correction.

## Issues Encountered

- **Pre-existing, out-of-scope colour-token gate hits.** Task 2's file-wide untokened-colour check (`grep -nE '(^|[^A-Za-z.])color:' quickshell/.config/quickshell/modules/bar/*.qml | grep -vE 'Colours\.|contentColour|capsuleRoot\.'`) scans every file in `modules/bar/`, not just this plan's own files. It surfaces two pre-existing hits — `ClockActionsCapsule.qml:117` (`color: cellItem.tint`) and `TrayCapsule.qml:241` (`color: "transparent"`) — both from 18-10/18-11, confirmed via `git log` to predate this plan and untouched by any commit in this plan. Per the scope boundary rule (only auto-fix issues directly caused by the current task's changes), these were left alone rather than fixed. Logged to `.planning/WINDOWS.md` below rather than silently patched.

## User Setup Required

None — no external service configuration required. `brightnessctl` (package `brightnessctl 0.5.1-3`, official `extra` repo) is already installed on this host and was not newly introduced by this plan; no package-manager install of any kind occurred (T-18-12-SC).

## Known Stubs

None. `BrightnessBackend.qml`'s `present`/`percent`/`deviceName` are all live reads of a real probe's parsed output — there is no placeholder or hardcoded value. The entry rendering nothing on this host is the plan's own deliberate, evidenced design (D-18-39), not a stub standing in for missing work.

## Live Verification — Deferred (per this phase's established skip-live-verification operating mode)

Every task's automated `<verify>` grep/regex script ran and passed (see Task Commits and `coverage` above), and the SAFE, non-destructive live probes were also run and passed this session: `hyprctl layers -j` confirms the `quickshell-bar` namespace registered (1 match), `tail -80 ~/.cache/quickshell.log` shows zero errors/warnings for the touched files, `brightnessctl -m -l -c backlight` confirms 0 device lines (presence-negative, the real state of this host), `brightnessctl -m -l -c leds` confirms 8 real device lines (presence-positive class), the exact argv shape `adjust()` builds was proven via `brightnessctl`'s own `-p` (pretend, no-write) mode against a real `leds` device and produced a well-formed machine-readable line, and `pgrep -c brightnessctl` confirms zero stray children.

The genuinely interactive halves were NOT performed this session, matching 18-08-SUMMARY's identical, already-established precedent: the running `quickshell` process (pid 58353, ~19h uptime) predates every commit in this plan and has not been restarted or hot-reloaded against this code, so a live pointer-scroll test right now would exercise 19-hour-old code, not what was just written. Specifically deferred:
- Task 1's human-check: three wheel-up notches on the audio entry raising `wpctl get-volume @DEFAULT_AUDIO_SINK@` by 15 percentage points with the bar's own percent agreeing, and the unity/zero bound holding under sustained scrolling at both ends.
- Task 2's human-check: repointing `BrightnessBackend.deviceClass` to `leds`, confirming a real glyph+percentage renders after quickshell hot-reloads, scrolling it, then reverting and confirming the entry vanishes with no gap, plus vertical-orientation confirmation.

Logged to `.planning/WINDOWS.md` as unrun-verify entries (one per task's deferred live/human-check half), plus one entry for the pre-existing out-of-scope colour-token hits noted above, so all three stay visible at ship time.

## Next Plan Readiness

- `MediaConnectivityCapsule.qml`'s scroll contract is now fully owned by this plan (both `WheelHandler`s) — 18-13's hover dwell, pin latch and one-open-at-a-time popout summon inherit a file with zero `HoverHandler`/`MouseArea`/`TapHandler`/popout identifiers (re-verified by this plan's own acceptance criteria), so there is no partial-ownership conflict to resolve.
- `BrightnessBackend.qml`'s public surface (`present`, `deviceName`, `percent`, `failed`, `adjust(steps)`) is available for 18-14's brightness popout body to consume without needing a new probe or a new writer.
- `18-SCROLL-GATE-RECORD.md` is ready for 18-19 to read directly: it answers GATE-02 B.3's brightness half without re-deriving it, hands over a complete mechanical remedy if the workspace-scroll cut is judged a loss, and lists both UI-SPEC deltas and the narrowed 18-08 gate for the phase's own errata.
- `Design.qml`'s `barScrollStepPercent` append is a single, independent one-line `readonly property` — no collision expected with any sibling wave-4 plan's own token append.

---
*Phase: 18-qml-bar-retirement-machinery*
*Completed: 2026-08-11*

## Self-Check: PASSED

- FOUND: `quickshell/.config/quickshell/modules/bar/BrightnessBackend.qml`
- FOUND: `.planning/phases/18-qml-bar-retirement-machinery/18-SCROLL-GATE-RECORD.md`
- FOUND: `quickshell/.config/quickshell/modules/bar/MediaConnectivityCapsule.qml`
- FOUND: `quickshell/.config/quickshell/modules/bar/BarEntryModel.qml`
- FOUND: `quickshell/.config/quickshell/modules/bar/qmldir`
- FOUND: `quickshell/.config/quickshell/modules/dashboard/Design.qml`
- FOUND commit: `2a92ece`
- FOUND commit: `3bb654b`
- FOUND commit: `60160e9`
