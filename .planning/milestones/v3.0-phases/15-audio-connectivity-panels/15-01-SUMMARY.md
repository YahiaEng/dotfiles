---
phase: 15-audio-connectivity-panels
plan: 01
subsystem: quickshell-research
tags: [quickshell, qml, pipewire, networkmanager, bluez, dbus, caelestia, end-4]

# Dependency graph
requires: []
provides:
  - "15-API-PROBE.md — the measured API shape for Pipewire.nodes/Networking.devices/Bluetooth.devices iteration, PwObjectTracker requirement, real PipeWire node property keys and name/icon fallback chains, NetworkManager call-path semantics, default-sink/source write semantics (with a disclosed input-side gap), wifi scan cadence, a six-surface Caelestia/end-4 adaptation table, and the Popup-in-layer-shell record-only measurement"
  - "Corrections to 15-RESEARCH.md/15-PATTERNS.md's documented accessor snippet and default-sink assumption"
affects: ["15-02", "15-03", "15-04", "15-05", "15-06", "15-07", "15-08", "15-09"]

actuals:
  tokens: 11400
  tasks: 4
  commits: 4

tech-stack:
  added: []
  patterns:
    - "Live-probe-then-checkpoint-then-close: measure against the real running build with throwaway qs -p harnesses under a mktemp -d scratch dir, dispose any genuinely ambiguous finding at an explicit checkpoint, only then close the plan"
    - "Restoration ledger, arm-before-mutate: every live system mutation (rfkill, wifi scanner, wifi connection profile, default audio sink/source) gets one `- RESTORED <name>: <pre> -> <post>` ledger line, re-verified true at commit time"
    - "Bounded re-probe on ambiguous checkpoint findings: when a measurement result is ambiguous enough to need a human decision, a follow-up targeted re-probe (not a full re-investigation) discriminates the specific open question before the disposition is written, so 'unexplained gap' is never shipped to a downstream plan"

key-files:
  created:
    - .planning/phases/15-audio-connectivity-panels/15-API-PROBE.md
  modified: []

key-decisions:
  - "A2 checkpoint (Task 3): human selected a third disposition — bounded re-probe of the input-side default-source gap, then accept-and-document per side (not either of the plan's two pre-written options). Re-probe discriminated 'write accepted and ignored' (a real platform gap) from 'write rejected at the binding layer' (a harness fault) by reading Pipewire.preferredDefaultAudioSource back after the write, not just the read-only defaultAudioSource. Output ships claiming full live re-route (the measured, stronger reading); input ships with a disclosed, understood residual carried forward explicitly to 15-04's render gate."

requirements-completed: []

coverage: []

duration: multi-session
completed: 2026-08-02
status: complete
---

# Phase 15 Plan 01: API Probe Summary

**Live-measured (not inferred) the four API unknowns blocking all three audio/wifi/bluetooth panels — model accessor shape, tracker requirement, real PipeWire property keys, NetworkManager call path, default-device write semantics, wifi scan cadence — plus a real source study of both reference shells and a Popup-in-layer-shell viability check, closing with a human-disposed checkpoint on the one genuinely ambiguous finding.**

## Performance

- **Duration:** multi-session
- **Tasks:** 4 completed (Task 3 was a blocking checkpoint that paused for a human decision mid-session)
- **Files modified:** 1 (`15-API-PROBE.md`, created)

## Accomplishments

- **A3 (model accessor):** `UntypedObjectModel` has no `count`/`get()` (contradicting 15-RESEARCH.md Pattern 2's example) — the real shape is `.values` (array-like: length/index/`.map`/`.filter`, but `Array.isArray()` is false) for JS iteration, and `Repeater { model: <the model itself> }` for one-delegate-per-object lists. Reactivity proven live on both `Pipewire.nodes` and `Bluetooth.defaultAdapter`.
- **A6 (tracker requirement):** confirmed live — `ready`, `audio.volume`/`muted`, and `properties` are all inert stub values on any `PwNode` until it is inside a mounted `PwObjectTracker.objects` list; with one mounted, real values populate (28 and 53 real property keys observed on two live nodes).
- **A1 (property keys):** verbatim key dump from two real playing streams; settled the display-name fallback chain (`application.name` → `application.process.binary` → `node.name`) and confirmed no stream node ever carries an icon-name key (icon is always a generic fallback). Found and corrected a `PwNodeType` flag-membership pitfall: the named "convenience" flags are pre-combined composites sharing bits, so bitwise-AND membership tests give false positives — exact equality is required.
- **A4 (call path):** plain invokable methods (`connect()`/`forget()`) reach NetworkManager and produce observable profile creation/removal; the `request*` signals are inert without an external listener. Found that a `WifiNetwork` object can be invalidated by its own `forget()` call — code must re-resolve from the model, not hold a reference across it.
- **A2 (default-sink semantics) + checkpoint disposition:** output-side write re-routes an already-playing stream live, not just new ones (stronger than the pessimistic reading in RESEARCH.md). Input-side write showed no observed live effect within two independent 10s windows. At the plan's one blocking checkpoint, the human selected a bounded re-probe over either pre-written option — the re-probe discriminated "accepted and ignored" (a real, disclosed platform gap) from a harness/binding fault, by reading the write-target property back rather than only the live-effect property. Disposition: output ships claiming full re-route; input ships with the residual named explicitly and carried to 15-04's render gate.
- **Open Q1 (scan cadence):** rescan interval widens over a session (NM-style backoff, not fixed) rather than one constant number; network list order and object identity do NOT survive a rescan (objects appear/disappear rather than mutate in place) — corrects 15-05's stable-ordering assumption to a react-to-diff design. Disabling `scannerEnabled` clears the list immediately; a 62s post-stop window confirmed zero further scan activity.
- **A5 (reference-shell source study):** shallow-cloned both `end-4/dots-hyprland` and `caelestia-dots/shell` and read real QML across all six named surfaces. Found the quick-toggle two-word-label wrap requirement (D-15-21) has **no precedent in either reference** — Caelestia shows no label at all, end-4 elides to one line. Independently cross-validated A1's display-name fallback chain against Caelestia's own shipping `Audio.getStreamName()` implementation (identical order). Adopted end-4's `available`/`enabled` hardware-vs-software split for empty/off states (D-15-26).
- **Open Q2 (Popup, record only):** end-4 ships a bare `Popup` inside a real `PanelWindow` layer surface; Caelestia avoids it entirely. Direct harness measurement confirmed render (via `grim`, since `grabToImage` does not work on a `PanelWindow` root — a new correction beyond 14-02's Window-root rule) and inline placement (one layer entry, no separate toplevel). Pointer input left honestly `unresolved` — no synthetic-input tool available on this host, recorded as an absent test rather than a false negative. Popup stays banned per D-15-12/D-15-19 regardless.

## Task Commits

Each task was committed atomically:

1. **Task 1: Settle A3, A6, A1, A4 against the running build** — `9bbcb5b` (feat)
2. **Task 2: Measure A2 and Open Q1** — `e20969e` (feat)
3. **Task 3: Dispose the A2 checkpoint (bounded re-probe, then accept per-side)** — `61331c1` (docs)
4. **Task 4: A5 reference-shell source study, Open Q2 Popup viability** — `7af5d76` (docs)

_Note: Task 3 was this plan's one blocking checkpoint (`type="checkpoint:decision"`, `gate="blocking"`). Auto mode was not active in this session (`workflow.auto_advance: false`), so the executor stopped and returned a structured checkpoint after Tasks 1-2; the human selected a third disposition (bounded re-probe, then accept-and-document per side) rather than either pre-written option, and a continuation agent completed the bounded re-probe, recorded the disposition, and ran Task 4 to close the plan._

## Files Created/Modified

- `.planning/phases/15-audio-connectivity-panels/15-API-PROBE.md` — the sole artifact this plan produces; ten canonical sections (A1-A6, Open Q1, Open Q2, Live mutations ledger, Corrections), each of the eight question sections carrying a `measured` verdict with named evidence.

## Decisions Made

- **A2 disposition (Task 3 checkpoint):** bounded re-probe of the input-side gap, then accept-and-document per side — see `key-decisions` in frontmatter and the `### Disposition` subsection under `## A2` in `15-API-PROBE.md` for full reasoning. Option (b) (`PwNodeLinkTracker`/`PwLinkGroup` per-stream re-route) was explicitly rejected: it is the standard remedy for a "new streams only" gap, and the output side provably has no such gap; the input side's failure mode ("no observed effect") had no evidence link-tracking was its remedy.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Task 3 edit accidentally dropped the `## Open Q1 — scannerEnabled cadence` heading line**
- **Found during:** Task 4, final verification pass (`grep -cE '^## (A1|A2|...)'` returned 9 instead of the required 10)
- **Issue:** The Task 3 disposition Edit's `old_string`/`new_string` boundary swallowed the `## Open Q1` heading itself along with the paragraph it was replacing, leaving Open Q1's `**Verdict:**`/`**Evidence:**` content orphaned under no heading.
- **Fix:** Re-inserted the `## Open Q1 — scannerEnabled cadence` heading immediately before its `**Verdict:**` line.
- **Files modified:** `.planning/phases/15-audio-connectivity-panels/15-API-PROBE.md`
- **Verification:** Re-ran the full plan verification block — all 8 verdicts, 8 evidence lines, and 10 canonical headings present in the required order.
- **Committed in:** `7af5d76` (part of the Task 4 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 — self-inflicted editing bug, caught by the plan's own verification gate before commit)
**Impact on plan:** No scope creep; the fix restored exactly the content that had already been measured and written, with no new measurement needed.

## Issues Encountered

- **A4's `harness_a4.qml` threw a `TypeError` on `requestForget()` after `forget()` had already invalidated the network object** (documented in A4's own findings as a real, load-bearing corrective finding, not a bug to silently absorb) — the harness's remaining cleanup timer chain (including the final `scannerEnabled = false` step) never ran because the exception aborted that timer's handler. Compensating restoration: the process was bounded by its own `timeout` and terminated with no persistent effect (scannerEnabled is client-side, not NM state), and a later, independent Open Q1 harness run (`harness_openq1.qml`) cleanly set and restored `scannerEnabled` with a verified 62s quiet window — recorded as the compensating clean restoration in the ledger.
- **No synthetic-pointer-input tool (`ydotool`/`wlrctl`/`dotool`) is installed on this host**, blocking a direct test of Open Q2's third sub-question (does a layer-shell `Popup` accept pointer input). Recorded as `unresolved` for that sub-question specifically, with the reason stated plainly, rather than inferring an answer from the other two (render, placement) that were measured.

## User Setup Required

None — no external service configuration required. (No package install occurred; the reference-shell clones and probe harnesses were read-only/throwaway and are already deleted.)

## Next Phase Readiness

`15-API-PROBE.md` is the durable artifact 15-02 through 15-09 cite instead of re-measuring. In particular:

- **15-02** (tracer) can build `AudioBackend`/`WifiBackend`/`BluetoothBackend` directly against A3's accessor and A6's tracker-mount answer — both unblock all three panels simultaneously, as the plan intended.
- **15-04** inherits A2's disposition verbatim, including the explicit obligation to re-verify input-device selection at its own render gate against a real recording app, since 15-01's own re-probe could not (and did not try to) confirm live effect beyond a multi-second observation window.
- **15-05** inherits both A4's call-path answer and Open Q1's corrected (non-stable, diff-based) list-identity model — its "stable ordering" truth needs updating from an unconditional guarantee to a design constraint the accessor code must satisfy explicitly.
- **15-07** inherits A5's finding that the two-word quick-toggle label wrap requirement has no reference precedent and must be designed from scratch, plus end-4's split-hit-region mechanism as the concrete pattern to adapt for the toggle-vs-open-panel split.
- No blockers. No production file was touched by this plan (`git status --porcelain -- quickshell hypr waybar matugen gtk install.sh` empty throughout); the live Quickshell shell (PID unchanged across the whole session) was never restarted or disturbed.

---
*Phase: 15-audio-connectivity-panels*
*Completed: 2026-08-02*

## Self-Check: PASSED

- FOUND: `.planning/phases/15-audio-connectivity-panels/15-API-PROBE.md`
- FOUND: `.planning/phases/15-audio-connectivity-panels/15-01-SUMMARY.md`
- FOUND commit: `9bbcb5b` (Task 1)
- FOUND commit: `e20969e` (Task 2)
- FOUND commit: `61331c1` (Task 3)
- FOUND commit: `7af5d76` (Task 4)
