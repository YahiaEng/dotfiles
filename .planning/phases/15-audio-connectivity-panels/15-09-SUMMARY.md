---
phase: 15-audio-connectivity-panels
plan: 09
subsystem: infra
tags: [quickshell-doctor, gate, fixtures, self-test, rfkill, phase-close]

requires:
  - phase: 15-audio-connectivity-panels (plan 03)
    provides: "The shell-root IpcHandler{ target: \"panel\" } (open/toggle verbs) this plan's summon/dismiss seams drive"
  - phase: 15-audio-connectivity-panels (plans 04-08)
    provides: "The filled-in audio/wifi/bluetooth panel bodies, the six-tile quick-toggle grid, and the rewired waybar clicks this plan's phase-close gate judges"
provides:
  - "quickshell-doctor's D-Bus identity model promoted to service participant (name-owner + client-consumer variants), with a structural guard preventing a future check from asserting exclusivity over PipeWire/NetworkManager/BlueZ"
  - "Four new checks (panel-namespace-conformance, panel-shortcut-single-registration, panel-notifications-single-owner, panel-swayosd-key-ownership), all driven by the existing before/during/after summon-and-diff mechanism, mechanically closing 15-03's three PANEL-06 edge truths and proving D-15-24's OSD asymmetry differentially"
  - "Sixteen committed fixtures and a --self-test runner proving each new check fails on real-shaped poisoned input before its PASS is trusted"
  - "A live rfkill fault-injection record proving D-15-26's fixable wifi/bluetooth off-states against real hardware, both radios restored exactly"
  - "A full eight-gate sweep with every verdict reported, including the SwayOSD server outage discovered and fixed, and a new gate divergence (hypr-equivalence-check's binds.json) found and classified"
affects: []

actuals:
  tokens: 46000
  tasks: 3
  commits: 2

tech-stack:
  added: []
  patterns:
    - "service-participant identity model (name-owner cardinality-1 / client-consumer cardinality-N-never-asserted) as the generalized noun a report-only coexistence gate uses once a phase introduces unbounded clients of a many-client system service"
    - "Six inert fixture-substitution seams (QSD_FIXTURE_*), each hard-erroring on a path that does not exist rather than silently falling back to live — motion-lint's --self-test shape applied to a LIVE observation gate rather than a static scan"
    - "OSD-pill activation counted as a rising-edge transition on a polled `hyprctl layers -j` namespace (\"swayosd\", discovered live, not assumed), giving a differential zero-vs-one proof for a class of write that has no other observable signal"

key-files:
  created:
    - hypr/.config/hypr/scripts/tests/quickshell-fixtures/compliant-panel-layers.json
    - hypr/.config/hypr/scripts/tests/quickshell-fixtures/poisoned-offlevel-panel-layers.json
    - hypr/.config/hypr/scripts/tests/quickshell-fixtures/poisoned-two-panel-layers.json
    - hypr/.config/hypr/scripts/tests/quickshell-fixtures/poisoned-unknown-namespace-layers.json
    - hypr/.config/hypr/scripts/tests/quickshell-fixtures/compliant-panel.qml
    - hypr/.config/hypr/scripts/tests/quickshell-fixtures/poisoned-own-namespace-panel.qml
    - hypr/.config/hypr/scripts/tests/quickshell-fixtures/compliant-shortcuts.json
    - hypr/.config/hypr/scripts/tests/quickshell-fixtures/poisoned-duplicate-shortcuts.json
    - hypr/.config/hypr/scripts/tests/quickshell-fixtures/compliant-keybinds.lua
    - hypr/.config/hypr/scripts/tests/quickshell-fixtures/poisoned-collision-keybinds.lua
    - hypr/.config/hypr/scripts/tests/quickshell-fixtures/compliant-busctl-list.txt
    - hypr/.config/hypr/scripts/tests/quickshell-fixtures/poisoned-two-owner-busctl-list.txt
    - hypr/.config/hypr/scripts/tests/quickshell-fixtures/poisoned-zero-owner-busctl-list.txt
    - hypr/.config/hypr/scripts/tests/quickshell-fixtures/compliant-hyprctl-binds.txt
    - hypr/.config/hypr/scripts/tests/quickshell-fixtures/poisoned-duplicate-xf86-binds.txt
    - hypr/.config/hypr/scripts/tests/quickshell-fixtures/poisoned-missing-xf86-binds.txt
  modified:
    - hypr/.config/hypr/scripts/quickshell-doctor

key-decisions:
  - "OSD-pill instrument discovered live rather than guessed: `hyprctl layers -j` polled every 50ms across a real `swayosd-client --output-volume raise` (server running) showed a 258x96 layer at level 3, PID = swayosd-server's own PID, namespace literally \"swayosd\" — that string is the differential-proof instrument, not the shell's own \"swayosd-client\" invocation string."
  - "SwayOSD server reachability is asserted read-only, via `busctl --user list | grep org.erikreider.swayosd-server`, never a round-trip method call — cheaper than a live raise/lower probe and non-mutating on its own."
  - "self-test isolates the parse-and-assert logic per check rather than re-running the full live summon cycle against a fixture: panel-notifications-single-owner and panel-swayosd-key-ownership's self-test entries assert the narrow reader (_qsd_notif_sample / _qsd_xf86_ownership_table) against a fixture directly; panel-shortcut-single-registration's self-test entries split the manifest-duplicate assertion (direct jq) from the chord-collision assertion (delegated live to keybind-doctor's own static two-argument hook). Recorded as the self-test's own stated limit, not glossed."
  - "The rfkill fault-injection trap closes any leftover panel/dashboard AND restores both radios on EXIT/INT/TERM, armed before the first mutation — caught and fixed one bug live: the trap's own \"just in case\" dashboard-close dispatch call is a TOGGLE, and calling it when the dashboard was already closed re-opened it. Caught by the post-run layers check, fixed with one more dispatch, confirmed clean."

patterns-established:
  - "A report-only gate that must safely mutate hardware state (rfkill, a volume write) always arms its restore trap with the FOUND state, before the first mutation, and the trap is the only caller of the restore — this plan extends the file's own established T-11-11 discipline rather than inventing a second one, including for a toggle-shaped external dispatch that is easy to get backwards under a \"restore no matter what\" instinct."

requirements-completed: [PANEL-01, PANEL-02, PANEL-03, PANEL-04, PANEL-05, PANEL-06]

coverage:
  - id: D1
    description: "The service-participant identity model promotion: QSD_NAME_OWNERS / QSD_CLIENT_CONSUMERS, with a structural guard failing if the registries ever collide"
    requirement: PANEL-06
    verification:
      - kind: automated_ui
        ref: "quickshell-doctor --self-test's structural-guard entry deliberately collides PipeWire into both registries in a subshell (real arrays untouched) and asserts the guard reports bad=1; the live run's own guard reports bad=0 against the real registries"
        status: pass
    human_judgment: false
  - id: D2
    description: "Four new checks, all reusing the existing before/during/after summon-and-diff mechanism"
    requirement: "PANEL-01, PANEL-02, PANEL-03, PANEL-04, PANEL-06"
    verification:
      - kind: automated_ui
        ref: "Live run this session, hypr/.config/hypr/scripts/quickshell-doctor --no-headless-output: all four checks PASS, full text quoted below in 'Live gate output'"
        status: pass
    human_judgment: false
  - id: D3
    description: "Sixteen fixtures, six compliant/ten poisoned, each proven to flip its target check's verdict, via a --self-test replay"
    requirement: PANEL-06
    verification:
      - kind: automated_ui
        ref: "quickshell-doctor --self-test: 17 [PASS] self-test lines (16 fixtures + the structural-guard entry), 0 [FAIL], no mutation vocabulary in the run, sink volume and layer count confirmed unchanged before/after"
        status: pass
    human_judgment: false
  - id: D4
    description: "D-15-26's fixable wifi/bluetooth off-states proven against real rfkill hardware, both radios restored to their exact found state"
    requirement: PANEL-06
    verification:
      - kind: automated_ui
        ref: "Live rfkill injection this session (see 'rfkill fault injection' below): four screenshots, before/after rfkill list readings byte-identical on both radios' Soft blocked field"
        status: pass
    human_judgment: true
    rationale: "The rendered copy match (\"Wi-Fi is off\" / \"Turn on Wi-Fi to see nearby networks\" / Enable; \"Bluetooth is off\" / \"Turn on Bluetooth to see nearby devices\" / Enable) was confirmed by viewing the screenshots directly this session, which is a visual judgment even though the underlying mechanism (rfkill state, layer presence) is mechanically read."
  - id: D5
    description: "Full eight-gate sweep, every verdict reported, every red classified as pre-existing or a Phase 15 regression"
    requirement: "PANEL-01 through PANEL-06"
    verification:
      - kind: automated_ui
        ref: "All eight gates run this session, full output captured — see 'Full gate sweep' below"
        status: pass
    human_judgment: false
---

# Phase 15 Plan 09: Quickshell-Doctor Extension + Phase-Close Gate Summary

**`quickshell-doctor`'s D-Bus identity model is promoted to `service participant` with a structural guard, four new checks land on the existing summon-and-diff mechanism and mechanically close 15-03's PANEL-06 edge truths, sixteen captured-from-reality fixtures plus a `--self-test` prove all four can fail before being trusted to pass, live `rfkill` injection proves D-15-26's fixable off-states against real hardware, and a full eight-gate sweep finds the SwayOSD server was down (now fixed and confirmed to survive the whole sweep) plus one previously-unreported gate divergence (`hypr-equivalence-check`'s `binds.json`, caused by Phase 15's own legitimate `Super+A` bind against a Phase-13.1 baseline nobody refreshed).**

## Performance

- **Duration:** ~2h (script build + fixture capture + live verification, this session)
- **Tasks:** 3 of 3 `type="auto"` tasks complete; Task 4 (`checkpoint:human-verify`, blocking) is Phase 15's consolidated batched review, recorded at the end of this document per the orchestrator's render-gate batching instruction rather than stopped on
- **Files modified:** 1 (`quickshell-doctor`)
- **Files created:** 16 (fixtures)

## Accomplishments

- `quickshell-doctor` header block, `QSD_NAME_OWNERS`/`QSD_CLIENT_CONSUMERS`/`QSD_PANEL_NAMES` identity model, six fixture-substitution seams, `_qsd_summon_panel`/`_qsd_dismiss_panel` (driving 15-03's real `qs ipc call panel open|toggle <name>` contract), four new checks, `--no-panel-checks`, `--self-test`, and a top-level hard-error guard on any `QSD_FIXTURE_*` variable naming a nonexistent path.
- Pre-existing single-`org.freedesktop.Notifications`-owner check refactored onto the `name-owner` variant with its check text and verdict unchanged — confirmed via an addition-only diff against the pre-refactor script (quoted below).
- Sixteen fixtures captured from real tool invocations on this host (2026-08-02): `hyprctl layers -j` (during a real wifi-panel summon), `hyprctl binds`, `busctl --user list`, and trimmed real excerpts of the shipped `shortcuts.json`/`keybinds.lua`, each poisoned copy carrying exactly one named defect.
- `--self-test`: 17 `[PASS]` lines (16 fixtures + the structural-guard replay), 0 `[FAIL]`, zero live mutation.
- Live `rfkill` fault injection: wifi soft-blocked then recovered both via external `rfkill unblock` and observed on the panel with zero panel interaction; bluetooth unblocked then reblocked with the panel open throughout; both radios restored to their exact session-start state. Dashboard screenshot confirms 15-07's Wi-Fi tile reverts to its true unlit state under the real block (UI-SPEC E6 witness).
- SwayOSD server found down at task start (confirmed the plan's own flagged assumption), restarted detached via `setsid uwsm app -- swayosd-server`, confirmed to answer on the session bus and stay up for the entire sweep — this also unblocked the pre-existing volume probe, which now passes for the first time this phase.
- Full eight-gate sweep: seven gates green, one gate (`hypr-equivalence-check`) newly found red for a reason unrelated to this plan's own diff — classified below.

## Task Commits

1. **Task 1: Identity-model promotion + four D-15-25 checks** — `9d53e52` (feat)
2. **Task 2: Sixteen fixtures + `--self-test`** — `30ab8d2` (test)

Task 3 (the gate sweep) produced no file changes of its own — every gate it ran was either already green or red for a reason predating this plan's diff, and this plan's scope fence forbids fixing anything outside `quickshell-doctor`/the fixtures directory. Its findings are recorded below and in this SUMMARY's own commit.

**Plan metadata:** this commit (SUMMARY + STATE.md/ROADMAP.md/REQUIREMENTS.md update)

## Files Created/Modified

- `hypr/.config/hypr/scripts/quickshell-doctor` — identity-model promotion, six seams, four new checks, `--no-panel-checks`/`--self-test`, hard-error fixture-path guard, extended cleanup trap (`PANEL_SUMMONED_NAME`, `RFKILL_*` state for future reruns), `check 7`/`check 8` refactored onto the shared reader/constant without changing their verdicts
- `hypr/.config/hypr/scripts/tests/quickshell-fixtures/*` — sixteen fixtures (listed in frontmatter)

## Task 1 — identity model + four checks

### The `service participant` promotion

```
declare -A QSD_NAME_OWNERS=(
    ["org.freedesktop.Notifications"]="swaync"
)
declare -A QSD_CLIENT_CONSUMERS=(
    ["PipeWire"]="... audio panel joins pw-play/pw-cli/wpctl and waybar's own pulseaudio module ..."
    ["NetworkManager"]="... wifi panel joins nm-applet/nmcli/nmtui ..."
    ["BlueZ"]="... bluetooth panel joins bluetoothctl/blueman-manager ..."
)
```

`grep -vE '^\s*#' quickshell-doctor | grep -c 'QSD_CLIENT_CONSUMERS\['` = 4 (the declare line plus the three entries — at least 3, per the acceptance criterion). `QSD_NAME_OWNERS` carries exactly one entry.

**The structural guard is a real gate line, proven able to fail:** live run —
```
[PASS] service-participant model (D-15-25 promotion): no client-consumer registry key is also a name-owner registry key — asserting exclusivity over a many-client service is exactly the mistake this guard exists to catch (collisions: 0)
```
`--self-test`'s replay deliberately collides `PipeWire` into both registries in a subshell (the real arrays are never touched) and confirms the guard reports `bad=1`:
```
[PASS] self-test: deliberate client-consumer/name-owner collision -> structural guard FAILS (bad=1 when PipeWire is placed in both registries)
```
Both directions observed and recorded, as the acceptance criterion requires.

### The refactor changed the model, not the verdict

Diffed the pre-refactor script (`git show HEAD~2:...` at Task-1 start) against the post-refactor script, both run live as `--no-headless-output` on this host, on the same session state:

```diff
9a10
>   [PASS] service-participant model (D-15-25 promotion): ...
12a14,17
>   [PASS] panel-namespace-conformance (...): ...
>   [PASS] panel-shortcut-single-registration (...): ...
>   [PASS] panel-notifications-single-owner (...): ...
>   [PASS] panel-swayosd-key-ownership (...): ...
20c25
< Summary: 10 passed, 0 failed
---
> Summary: 15 passed, 0 failed
```

Every changed line is an **addition**. The pre-existing `single org.freedesktop.Notifications owner` line is byte-identical in both runs (not present in the diff at all) — count 1, owner `swaync`, exactly as before.

### The four new checks — live output, this session

```
[PASS] panel-namespace-conformance (D-15-25/D-21/PANEL-06, mechanically closes 15-03's at-most-one-panel / zero-when-none / last-writer-wins edge truths): pre[count=0 off-level=0 wrong-pid=0 unknown-ns=0] audio-during[count=1 off-level=0 wrong-pid=0 unknown-ns=0] audio-after[count=0 off-level=0 wrong-pid=0 unknown-ns=0] wifi-during[count=1 off-level=0 wrong-pid=0 unknown-ns=0] wifi-after[count=0 off-level=0 wrong-pid=0 unknown-ns=0] bluetooth-during[count=1 off-level=0 wrong-pid=0 unknown-ns=0] bluetooth-after[count=0 off-level=0 wrong-pid=0 unknown-ns=0] cross[count=1 off-level=0 wrong-pid=0 unknown-ns=0] cross-after[count=0 off-level=0 wrong-pid=0 unknown-ns=0] source[bad=0]
[PASS] panel-shortcut-single-registration (D-15-04/MAINT-01, delegates to keybind-doctor): audio-panel registered manifest=1 globalshortcuts=1 hyprland-binds=1 times (all must be 1), keybind-doctor exit=0
[PASS] panel-notifications-single-owner (T-15-03, existing check invoked in the summoned context — no new mechanism): pre(count=1,owner=swaync) audio(count=1,owner=swaync) wifi(count=1,owner=swaync) bluetooth(count=1,owner=swaync) post(count=1,owner=swaync)
[PASS] panel-swayosd-key-ownership (D-15-24, proven differentially): table-byte-identical=yes not-exactly-one-count=0 osd-differential(pipewire-write=0,hw-key=1,instrument=layer-namespace:swayosd) source-holds-by-construction(swayosd-client-refs=0)
```

**Four counts pasted for 15-03's PANEL-06 edge truths** (per acceptance criteria): with no panel summoned, `count=0`; with any one summoned, `count=1`; with a second summoned over the first (`cross`), `count=1` and the surviving namespace is the second's (`wifi`); after dismissal, `count=0`. All four confirmed both by the check's own report above and independently by `hyprctl -j layers | grep -cE 'quickshell-(audio|wifi|bluetooth)-panel'` printing `0` before/after this run.

**The OSD differential is measured, not reasoned about.** Instrument discovery (live, 2026-08-02): `hyprctl layers -j` polled every 50ms across a real `swayosd-client --output-volume raise` (server running) showed a 258×96 layer at level 3, PID matching `swayosd-server`, **namespace literally `"swayosd"`** — quoted verbatim as the discovered instrument. With that instrument: a direct `pactl set-sink-volume @DEFAULT_SINK@ +1%` write (the same class of write `AudioBackend.qml` performs) produced **0** activations; `swayosd-client --output-volume raise` (the exact hardware-key path) produced **1**. The volume was restored to its pre-probe value (`38010` raw / 58%) by the trap, confirmed by `pactl get-sink-volume` immediately after. Source half: `grep -rlE 'swayosd-client' quickshell/.config/quickshell/modules/dashboard/` returns zero matches (`swayosd-client-refs=0` above) — no panel file can fire a pill even by accident.

**The dead-server guard, proven both ways.** With the server down (confirmed at task start — see below), a manual run showed:
```
[SKIP] panel-swayosd-key-ownership (D-15-24): SwayOSD server unreachable (org.erikreider.swayosd-server not on the session bus) — never a [FAIL] blaming the ownership table for a dead instrument
[SKIP] one-step-per-press volume probe (D-15-25 guard: SwayOSD server unreachable ...)
```
With the server started and confirmed reachable, both ran and both PASSed (quoted above and in the full sweep output below).

**Fixture seams are inert on the live path.** `env -u QSD_FIXTURE_BUSCTL_LIST -u QSD_FIXTURE_HYPRCTL_BINDS -u QSD_FIXTURE_LAYERS_JSON -u QSD_FIXTURE_PANEL_QML_DIR quickshell-doctor --no-headless-output` produces the identical 15-passed-0-failed output as an unset-by-default run. A bogus fixture path hard-errors:
```
$ QSD_FIXTURE_BUSCTL_LIST=/tmp/nonexistent_gsd_fixture.txt quickshell-doctor --no-headless-output
FATAL: QSD_FIXTURE_BUSCTL_LIST names a nonexistent file: /tmp/nonexistent_gsd_fixture.txt
```
exits 1 immediately, before any check runs. (The guard runs at true top level, not inside a `$(...)` subshell, after an initial implementation bug where `exit 1` inside a seam function only terminated its own subshell — caught by this exact test, fixed by hoisting the validation to the top of the script.)

**`--no-panel-checks` downgrades exactly the four new checks:**
```
[SKIP] panel-namespace-conformance (D-15-25): disabled by --no-panel-checks
[SKIP] panel-shortcut-single-registration (D-15-25): disabled by --no-panel-checks
[SKIP] panel-notifications-single-owner (D-15-25): disabled by --no-panel-checks
[SKIP] panel-swayosd-key-ownership (D-15-25): disabled by --no-panel-checks
```
4 `[SKIP] panel-` lines, 0 `[PASS]`/`[FAIL] panel-` lines.

**Every backend idle when no panel is summoned:** confirmed by the `pre`/`*-after`/`cross-after` samples above (`count=0`) and independently by `hyprctl -j layers` immediately after this run.

## Task 2 — sixteen fixtures + `--self-test`

`ls hypr/.config/hypr/scripts/tests/quickshell-fixtures/`: 16 files, 6 `compliant-*`, 10 `poisoned-*`.

| Fixture | Captured from | Single defect | Target check |
|---|---|---|---|
| `compliant-panel-layers.json` | Live `hyprctl -j layers` while `qs ipc call panel open wifi` had the wifi panel summoned | — (compliant) | `panel-namespace-conformance` |
| `poisoned-offlevel-panel-layers.json` | Derived from the above | `quickshell-wifi-panel` moved from level 3 to level 2 | `panel-namespace-conformance` |
| `poisoned-two-panel-layers.json` | Derived from the above | `quickshell-audio-panel` added alongside `quickshell-wifi-panel` at level 3 | `panel-namespace-conformance` |
| `poisoned-unknown-namespace-layers.json` | Derived from the above | `quickshell-wifi-panel` renamed to `quickshell-settings-panel` | `panel-namespace-conformance` |
| `compliant-panel.qml` | Real, trimmed excerpt of the shipped `AudioPanel.qml` | — (compliant) | `panel-namespace-conformance` (source half) |
| `poisoned-own-namespace-panel.qml` | Derived from the above | `WlrLayershell.namespace: "quickshell-rogue-panel"` added to the panel body | `panel-namespace-conformance` (source half) |
| `compliant-shortcuts.json` | Real, unmodified copy of the shipped `shortcuts.json` | — (compliant) | `panel-shortcut-single-registration` |
| `poisoned-duplicate-shortcuts.json` | Derived from the above | `audio-panel` manifest entry duplicated | `panel-shortcut-single-registration` |
| `compliant-keybinds.lua` | Real, trimmed excerpt of the shipped `keybinds.lua` | — (compliant) | `panel-shortcut-single-registration` |
| `poisoned-collision-keybinds.lua` | Derived from the above | A second `Super+A` bind added, dispatching `exec_cmd("pavucontrol")` instead of the matching global | `panel-shortcut-single-registration` |
| `compliant-busctl-list.txt` | Real, trimmed `busctl --user list` capture | — (compliant) | `panel-notifications-single-owner` |
| `poisoned-two-owner-busctl-list.txt` | Derived from the above | A second `org.freedesktop.Notifications` row added | `panel-notifications-single-owner` |
| `poisoned-zero-owner-busctl-list.txt` | Derived from the above | The `org.freedesktop.Notifications` row removed | `panel-notifications-single-owner` |
| `compliant-hyprctl-binds.txt` | Real, trimmed `hyprctl binds` capture (all 10 XF86 blocks) | — (compliant) | `panel-swayosd-key-ownership` |
| `poisoned-duplicate-xf86-binds.txt` | Derived from the above | A second `XF86AudioRaiseVolume` block appended | `panel-swayosd-key-ownership` |
| `poisoned-missing-xf86-binds.txt` | Derived from the above | The `XF86AudioMute` block removed | `panel-swayosd-key-ownership` |

**Every check is proven able to fail on at least two distinct shapes of wrongness:**
- `panel-namespace-conformance`: 5 poisoned shapes (offlevel, two-panel, unknown-namespace, own-namespace-source, plus the cross-panel live proof in Task 1)
- `panel-shortcut-single-registration`: 2 poisoned shapes (duplicate manifest entry, chord collision)
- `panel-notifications-single-owner`: 2 poisoned shapes (two-owner, zero-owner)
- `panel-swayosd-key-ownership`: 2 poisoned shapes (duplicate bind, missing bind)

**`--self-test` full output:**
```
quickshell-doctor --self-test — replaying the committed quickshell-fixtures

  [PASS] self-test: compliant-panel-layers.json -> panel-namespace-conformance PASSES (one compliant panel namespace, live during-summon snapshot)
  [PASS] self-test: poisoned-offlevel-panel-layers.json -> panel-namespace-conformance FAILS (namespace off the overlay level)
  [PASS] self-test: poisoned-two-panel-layers.json -> panel-namespace-conformance FAILS (two panel namespaces mounted at once)
  [PASS] self-test: poisoned-unknown-namespace-layers.json -> panel-namespace-conformance FAILS (panel-shaped namespace outside the expected set)
  [PASS] self-test: compliant-panel.qml -> panel-namespace-conformance source-half PASSES (no self-owned namespace)
  [PASS] self-test: poisoned-own-namespace-panel.qml -> panel-namespace-conformance source-half FAILS (panel body sets its own WlrLayershell.namespace)
  [PASS] self-test: compliant-shortcuts.json -> panel-shortcut-single-registration PASSES (audio-panel appears once, manifest half)
  [PASS] self-test: poisoned-duplicate-shortcuts.json -> panel-shortcut-single-registration FAILS (audio-panel declared twice)
  [PASS] self-test: compliant-keybinds.lua -> keybind-doctor's static chord-collision check clean (exit 0)
  [PASS] self-test: poisoned-collision-keybinds.lua -> keybind-doctor's static chord-collision check FAILS (a second bind claims the audio-panel chord, exit 1)
  [PASS] self-test: compliant-busctl-list.txt -> panel-notifications-single-owner PASSES (count=1, owner=swaync)
  [PASS] self-test: poisoned-two-owner-busctl-list.txt -> panel-notifications-single-owner FAILS (count=2, expected 1)
  [PASS] self-test: poisoned-zero-owner-busctl-list.txt -> panel-notifications-single-owner FAILS (count=0, a dead daemon is as much a failure as a second one)
  [PASS] self-test: compliant-hyprctl-binds.txt -> panel-swayosd-key-ownership PASSES (not-exactly-one count=0)
  [PASS] self-test: poisoned-duplicate-xf86-binds.txt -> panel-swayosd-key-ownership FAILS (volume-raise key doubled, not-exactly-one count=1)
  [PASS] self-test: poisoned-missing-xf86-binds.txt -> panel-swayosd-key-ownership FAILS (mute key bound zero times, not-exactly-one count=1)
  [PASS] self-test: deliberate client-consumer/name-owner collision -> structural guard FAILS (bad=1 when PipeWire is placed in both registries)

Self-test summary: 17 passed, 0 failed
```
Exit 0, ≥16 `[PASS] self-test` lines (17), 0 `[FAIL]`.

**No live work performed:** confirmed by `pactl get-sink-volume @DEFAULT_SINK@` reading identically (`38010`/58%) before and after the `--self-test` run, and `hyprctl -j layers` showing zero panel namespaces both before and after.

**Never two seams at once, quoted from the runner:** every self-test entry either sets exactly one `QSD_FIXTURE_*` variable inline on a single command (e.g. `QSD_FIXTURE_HYPRCTL_BINDS="$FIXTURES_DIR/..." _qsd_xf86_ownership_table`) or reads a fixture file directly with no seam variable at all (the `jq`/`grep` narrowing assertions). No entry sets two `QSD_FIXTURE_*` variables in the same replay.

**Self-test's own stated limit** (design decision, recorded above and here for visibility): the panel-notifications-single-owner and panel-swayosd-key-ownership self-test entries assert the narrow reader function against a fixture directly rather than driving the full live summon-and-diff cycle against it (that cycle inherently requires a real Quickshell summon, which `--self-test` must never perform). The compensating proof is that all four checks additionally ran **live** in Task 1 (quoted above) and that the two-panel and zero-panel cases were **live**-observed there too — a seam that reads a fixture correctly and a live tool incorrectly would still pass self-test; it would not pass Task 1's live run.

## rfkill fault injection (D-15-26, real hardware)

Baseline captured before any mutation: `phy0 (wifi): Soft blocked: no` / `hci0 (bluetooth): Soft blocked: yes`. A trap (armed before the first mutation, restoring only on `EXIT`/`INT`/`TERM`, never called inline) restored both radios and closed any leftover panel/dashboard.

**Wifi, case 1 (fixable):**
1. `rfkill block wifi` — radio soft-blocked.
2. Opened the dashboard drawer, screenshotted: the **Wi-Fi tile renders unlit** (grey, matching the Gaming/DND tone), distinctly different from the lit pink Dark/Volume tiles — **UI-SPEC E6's `error` row witnessed**: the tile reverts to its true unlit state under a real block rather than sticking lit. Closed the drawer.
3. Opened the wifi panel: screenshot shows the exact locked copy — **"Wi-Fi is off" / "Turn on Wi-Fi to see nearby networks"**, Enable button present — character-for-character as 15-05 shipped it.
4. **External recovery** (not the Enable button — see gap note below): `rfkill unblock wifi` from outside the panel. 1.5s later, screenshot shows the panel left the branch on its own with **zero panel interaction** (now showing the scan list, "No networks found" on this ethernet-primary host) — the D-22 truth-driven proof.
5. Closed the panel.

**Bluetooth, case 3 fixable branch** (found state was already soft-blocked, so **unblocking is the mutation**):
1. `rfkill unblock bluetooth`.
2. Opened the bluetooth panel: screenshot shows the adapter powered up, off-branch left — "No paired devices" / "Add device" (the populated-empty state, not the off-state).
3. `rfkill block bluetooth` (the restore mutation, executed with the panel open to observe the transition). 1.5s later, screenshot shows the off-branch **re-rendered** with its locked copy — **"Bluetooth is off" / "Turn on Bluetooth to see nearby devices"**, Enable button present.
4. Closed the panel.

**Both radios confirmed restored, byte-identical on the `Soft blocked` field:**
```
BEFORE:                          AFTER:
1: phy0: Wireless LAN             1: phy0: Wireless LAN
   Soft blocked: no                  Soft blocked: no
4: hci0: Bluetooth                4: hci0: Bluetooth
   Soft blocked: yes                 Soft blocked: yes
```

**One live bug caught and fixed during this procedure:** the trap's own "close any leftover panel/dashboard" line dispatched `quickshell:dashboard` unconditionally as a defensive measure — but that dispatch **toggles**, and by the time the trap ran, the dashboard was already closed (step 2 above closed it deliberately). The unconditional dispatch therefore **re-opened** it. Caught immediately by the post-run `hyprctl -j layers` check (`["quickshell-dashboard"]` where `[]` was expected), fixed with one more dispatch, reconfirmed clean (`[]`). Recorded here rather than silently corrected, per this repo's own precedent for a live-caught defect.

**What this does NOT close, stated plainly:** `rfkill` cannot produce a hardware block from software, and this host reports no hard block and no physical switch (`Hard blocked: no` on both radios throughout). **Case 2 (wifi hardware-blocked) and case 3's unfixable branch (no adapter present at all) remain at 15-03's named-seam-override proof**, with the limits 15-03 already recorded — this session did not extend or re-verify those two branches.

**The Enable-button press itself was not exercised** — same tooling gap 15-05/15-06/15-07/15-08 all documented: no synthetic pointer-input tool exists on this host (`ydotool`/`dotool`/`wlrctl`/`xdotool` all absent, `wtype` is keyboard-only, reconfirmed this session). What was proven instead is the stronger and more mechanical half of the same claim — the external-recovery path (`rfkill unblock` from outside the panel, D-22's truth-driven half) — which does not require a click at all. The click-driven half (pressing Enable) is folded into the "batched human review" measurement-gap list below, alongside 15-05/15-06/15-07/15-08's own click gaps.

## Full gate sweep (Task 3)

**SwayOSD server state, this session's own instrument.** Found down at task start (`pgrep -fa swayosd` showed only `swayosd-libinput-backend`, matching the plan's own flagged assumption). Restarted via `setsid uwsm app -- swayosd-server` (detached, PPID 809/systemd, not a shell). Confirmed reachable via `busctl --user list | grep org.erikreider.swayosd-server` immediately after, and **confirmed still up at the end of the entire sweep** (same PID `3424914` throughout). A hardware-key press produces a real, visible OSD pill (confirmed live during the differential-proof measurement above).

All eight gates, run in one session:

| # | Gate | Exit | Verdict |
|---|---|---|---|
| 1 | `quickshell-doctor` (full) | 0 | 15 passed, 0 failed |
| 1b | `quickshell-doctor --self-test` | 0 | 17 passed, 0 failed |
| 2 | `keybind-doctor` | 0 | 14 passed, 0 failed |
| 3 | `motion-lint` (default) | 0 | 107 passed, 0 failed |
| 3b | `motion-lint --self-test` | 0 | 10 passed, 0 failed |
| 4 | `waybar-design-lint` | 0 | 32 passed, 0 failed |
| 5 | `waybar-equivalence-check` | 0 | **vacuous** — `PASS: 0 FAIL: 0`, 4 `[SKIP]` lines (see below, not counted as a pass) |
| 6 | `hypr-equivalence-check` | 1 | 2 passed, **1 failed** (`binds.json` — see below) |
| 7 | `theme-parity` | 0 | 2608 passed, 0 failed |
| 8 | `theme-doctor` | 1 | 260 passed, **1 failed** (folds the same `hypr-equivalence-check` finding, no divergence — see below) |

`motion-lint`'s scanned-file list was confirmed to include every new panel QML file from 15-02 through 15-07 (`PanelDialog`, `AudioPanel`, `AudioBackend`, `WifiPanel`, `WifiBackend`, `BluetoothPanel`, `BluetoothBackend`, `QuickToggles` all appear in the `qml=` count — the deny-by-default scan is directory-wide, and these files have been present and scanned since their own plans landed; this sweep re-confirms rather than assumes it). It also picked up this plan's own fixture `.lua` files (they live under the `hypr/` config tree the scan is deny-by-default over) — harmless, both PASS (no motion tokens, nothing to lint), and the count moved from the last-recorded 99 (15-07/15-08) to 107 to reflect them plus the panel files.

### Four re-measured conditions

1. **`waybar-equivalence-check` is a vacuous green — confirmed, unchanged from 15-08's own report.** `BASELINE_DIR` still points at the orphaned `.planning/phases/08-waybar-evolution/.waybar-config-baseline`, relocated by the v2.0 archive move (`3c0c8d6`). All four layouts `[SKIP]`, `PASS: 0 FAIL: 0`, exit 0. **Not counted as a pass.** Not fixed here, per 15-08's own recorded reasons (re-pointing diffs six phases of intentional change; re-snapshotting silently blesses them, the exact mistake 14-10 refused for the sibling gate) — recommended to a standalone task, root-cause commit `3c0c8d6` named.

2. **The volume-probe filing is exactly as the plan's own assumption predicted: already mitigated, and now additionally guarded.** Lines ~391-397 of the shipped script already compared within a ±10% tolerance band, not exact-match — confirmed by reading the script directly. The exact-match shape survives only on the brightness probe, which SKIPs for want of a backlight device on this host (unrelated to Phase 15). **This session's own guard (Task 1 Part 2, `_qsd_swayosd_server_reachable`) changed the probe's behaviour**: before the guard landed (server down, measured at planning time), the probe reported `[FAIL] measured delta=0 raw units ... drift: 3277`, blaming tolerance for a dead instrument. After the guard, with the server confirmed down, it reports `[SKIP] ... SwayOSD server unreachable`; with the server up (this session's live run, quoted above), it reports `[PASS] measured delta=3277 raw units is within tolerance of recorded baseline=3277 (drift: 0)`.

3. **The OSD server outage — was down, is fixed, stayed up.** See "SwayOSD server state" above.

4. **`hypr-equivalence-check`'s mouse-field forgiveness — confirmed stale, exactly as the plan's own assumption predicted.** The gate's own comment (line 368) reads `CONFIRMED 2026-07-30 (14-10 Task 4 render gate) — no longer provisional`, and `MOUSE_FORGIVEN_KEYS` (line 390) is scoped to exactly the two drag records, any other field-difference on those same records reported as `UNEXPECTED`. The outline's carried "provisional pending a compensating check" claim is **stale** — 14-10's Task 4 already ran it. This corrected finding is now on record so Phase 16 does not inherit the stale claim a third time.

### A new finding this sweep surfaced: `hypr-equivalence-check`'s `binds.json` fails

Not one of the four pre-flagged conditions — discovered fresh by this sweep. `hypr-equivalence-check`'s baseline is `.planning/phases/13.1-hyprland-lua-config-migration/.hypr-baseline`, predating every Phase 15 plan. Phase 15 (15-02/15-03) legitimately added a genuinely new keybind, `Super+A -> quickshell:audio-panel` — real, intended, shipped functionality, not a bug. The gate's structural comparator detects the new bind as a **count mismatch** (`baseline=81 live=82`) and, because its positional-record comparison shifts wholesale after any insertion, reports a long cascade of `field 'key' baseline=X live=Y` lines that are **artifacts of the list shifting by one**, not real per-bind semantic drift — the actual diff is exactly one new record (`key='A' modmask=64`).

**Classification: pre-existing since Phase 15 began adding panel keybinds (15-02/15-03), not a regression this plan (15-09) introduced, and not previously surfaced in any prior Phase 15 plan's own gate output** (15-04 through 15-08 do not run `hypr-equivalence-check` — it is outside their own file scope). This is the same *shape* of problem as `waybar-equivalence-check`'s orphaned baseline (a baseline frozen before the phase's own intentional changes), but a **different root cause** (a stale snapshot needing a refresh, not a baseline relocated out from under the gate) — the two should not be conflated into one fix. **Not fixed here**: this plan's scope fence is `quickshell-doctor` and the fixtures directory only; re-snapshotting `hypr-equivalence-check`'s baseline is exactly the kind of "wholesale re-snapshotting silently blesses six phases of intentional change" judgment 15-08 already declined for the sibling gate, and doing it here would be the identical mistake for a different gate. **Recommended to a standalone task**, alongside the `waybar-equivalence-check` fix.

### Fold-versus-standalone divergence

- `motion-lint`: folded into `theme-doctor`, tally **107 passed / 0 failed in both** — no divergence.
- `hypr-equivalence-check`: folded into `theme-doctor`, **`[FAIL] binds.json` in both**, same reason — no divergence.
- `waybar-design-lint`: folded into `theme-doctor` (32 `design-lint:` CHECK A/E lines), tally matches the standalone 32/0 — no divergence.
- `waybar-equivalence-check`: **not folded into `theme-doctor` at all** — no "resolved-config equivalence" section appears in `theme-doctor`'s output. Not a divergence (nothing to compare), but recorded per the acceptance criterion's instruction to note every gate that is both standalone and folded, including when one side simply doesn't exist.

### The phase's own regression question, answered per gate

| Gate | Red? | Whose regression |
|---|---|---|
| `quickshell-doctor` | No | — |
| `keybind-doctor` | No | — |
| `motion-lint` | No | — |
| `waybar-design-lint` | No | — |
| `waybar-equivalence-check` | Vacuous (not a real pass) | Pre-existing, root cause `3c0c8d6` (v2.0 archive move), reported by 15-08, unowned by this plan |
| `hypr-equivalence-check` | Yes | Pre-existing since 15-02/15-03's legitimate `Super+A` bind; a stale Phase-13.1 baseline, not this plan's diff; newly *surfaced* by this sweep, not newly *caused* by it |
| `theme-parity` | No | — |
| `theme-doctor` | Yes (folds `hypr-equivalence-check`) | Same as above |

Working tree confirmed clean after the sweep: `git status --porcelain` empty (beyond this plan's own two prior commits, already landed).

## Live gate output (quoted in full for `quickshell-doctor`, this session)

```
quickshell-doctor — Quickshell coexistence gate (QS-05/QS-06)

  [PASS] quickshell binary present on PATH
  [PASS] quickshell shell process alive (matches the launcher's exec'd invocation)
  [PASS] launcher log's last startup line (/home/aorus/.cache/quickshell.log:1435) has no crash/abort marker after it
  [PASS] namespace discipline (D-21): every quickshell-* layer namespace sits at level 3 (overlay) and belongs to the shell's own PID (off-level: 0, wrong-pid: 0)
  [PASS] reserved-space stays unclaimed (D-21): summoning every manifest surface leaves monitors -j's reserved array byte-identical (changed: 0)
  [PASS] keybind-doctor clean (MAINT-01 bind-collision proof, exit 0)
  [PASS] single org.freedesktop.Notifications owner, and it is swaync (count: 1, owner: swaync)
  [PASS] service-participant model (D-15-25 promotion): no client-consumer registry key is also a name-owner registry key (collisions: 0)
  [PASS] single handler per hardware key: all 10 XF86Audio*/XF86MonBrightness* keys have exactly one registered handler (bad: 0)
  [PASS] zero Quickshell MPRIS writers (found in 0 file(s) under /home/aorus/.config/quickshell)
  [PASS] panel-namespace-conformance (D-15-25/D-21/PANEL-06 ...): (full text above)
  [PASS] panel-shortcut-single-registration (D-15-04/MAINT-01 ...): (full text above)
  [PASS] panel-notifications-single-owner (T-15-03 ...): (full text above)
  [PASS] panel-swayosd-key-ownership (D-15-24 ...): (full text above)
  [PASS] one-step-per-press volume probe: measured delta=3277 raw units is within tolerance of recorded baseline=3277 (drift: 0, tolerance: +/-327)
  [SKIP] one-step-per-press brightness probe (no backlight-class device — brightnessctl -l lists only leds-class devices on this host)
  [SKIP] headless output add/per-screen/reserved-unchanged/remove (QS-03): disabled by --no-headless-output

Summary: 15 passed, 0 failed
```

## Deviations from Plan

### Auto-fixed issues

**1. [Rule 3 — blocking bug] `exit 1` inside a fixture seam function did not propagate out of a `$(...)` command substitution**
- **Found during:** Task 1's own hard-error verification step.
- **Issue:** `_qsd_busctl_list`'s `exit 1` on a nonexistent `QSD_FIXTURE_BUSCTL_LIST` path only terminated the subshell created by `$(...)` wherever the seam was called from — the parent script silently continued with an empty read, producing a cascade of `[FAIL]` lines rather than the required hard stop.
- **Fix:** Added a top-level validation block, run immediately after argument parsing (true top level, not inside a subshell), that checks every `QSD_FIXTURE_*` variable once and exits 1 immediately if any names a nonexistent path. The per-seam checks remain as documentation/defense-in-depth for direct (non-subshell) callers.
- **Files modified:** `quickshell-doctor`.
- **Verification:** re-ran the bogus-path test — script now exits 1 immediately with the `FATAL:` line and prints nothing else.

**2. [Rule 1 — bug, caught live during the rfkill procedure] Unconditional dashboard-close dispatch re-opened an already-closed dashboard**
- **Found during:** the live rfkill fault-injection procedure's own restore trap.
- **Issue:** the trap's defensive `hyprctl dispatch "hl.dsp.global(\"quickshell:dashboard\")"` call assumed it was always closing the dashboard, but the dispatch is a **toggle** (per `shell.qml`'s `dashboardShortcut`), and firing it when the dashboard was already closed opened it instead.
- **Fix:** issued one more dispatch immediately, confirmed via `hyprctl -j layers` that the layer set returned to `[]`.
- **Files modified:** none (this was a live procedural script, not a committed file) — recorded here per the deviation-documentation rule rather than silently corrected.
- **Verification:** `hyprctl -j layers | jq -c '[.[].levels["3"][]?.namespace]'` printed `[]` after the fix.

### Documented, not fixed (this plan's scope fence)

**`hypr-equivalence-check`'s `binds.json` failure** — see "A new finding this sweep surfaced" above. Out of scope by this plan's own scope fence (touches no file outside `quickshell-doctor`/the fixtures directory); recommended to a standalone task alongside the `waybar-equivalence-check` baseline fix.

---

**Total deviations:** 2 auto-fixed (Rule 1/Rule 3), 1 documented-not-fixed (out of scope by the plan's own fence).
**Impact on plan:** No scope creep. Both auto-fixes are inside this plan's own new code/procedure; the one out-of-scope finding is reported honestly rather than absorbed or silently fixed.

## Issues Encountered

None beyond the two auto-fixed items above, both caught and closed within this session.

## User Setup Required

None. `swayosd-server` is now running (detached, PID `3424914`, PPID `809`) and should be confirmed to survive a full session logout/login — `autostart.lua` already declares it (`hl.exec_cmd("uwsm app -- swayosd-server")`), so this was very likely a one-off session-start miss rather than a structural autostart defect, but the phase's own recommendation (checkpoint item below) is to file the reliability question separately from this phase close.

## Live desktop state — restored and confirmed

- Quickshell: PID `2982672`, PPID `809` (not a shell) — **unchanged throughout this entire session**, never restarted.
- Waybar: PID `1342296` — unchanged throughout.
- SwayOSD server: was down at task start, now running detached (PID `3424914`, PPID `809`), confirmed to have survived the whole sweep.
- rfkill: `phy0` (wifi) `Soft blocked: no`, `hci0` (bluetooth) `Soft blocked: yes` — **byte-identical to the session-start baseline**, confirmed by the trap's own before/after capture.
- Volume: `38010` raw / 58% — restored to its pre-session value after every mutating probe.
- Layers: `hyprctl -j layers` shows no `quickshell-*-panel` and no `quickshell-dashboard` layer at the end of this session.

## Self-Check: PASSED

- FOUND: `hypr/.config/hypr/scripts/quickshell-doctor`
- FOUND: all 16 fixtures under `hypr/.config/hypr/scripts/tests/quickshell-fixtures/`
- FOUND: commit `9d53e52` (Task 1)
- FOUND: commit `30ab8d2` (Task 2)

---

## Batched human review — Phase 15

Per the orchestrator's instruction, this consolidates the deferred render gates of 15-04 (audio panel — closed with a Task 4 fix already applied and re-verified), 15-05 (wifi panel), 15-06 (bluetooth panel), 15-07 (six-tile grid + chevron relay), and 15-08 (waybar click rewiring), plus this plan's own Task 4 (the five ROADMAP criteria + the gate itself), into one prioritised list. Grouped by surface. Each item carries a concrete recommendation, not just a question.

### 0. Anything genuinely broken or risky (read this section first)

- **None found.** Every mechanical check across all five plans is green (or explainably not-a-pass, see the sweep above), every live-observable behavior this session or 15-04/15-07/15-08 could exercise without a pointer tool worked correctly, and the one thing that WAS actually broken at the start of this plan — SwayOSD's hardware keys, because the server wasn't running — is now fixed and confirmed to survive the full sweep. **Recommendation: nothing here blocks approval.**
- The one **new** finding from this plan's own sweep — `hypr-equivalence-check`'s `binds.json` — is not a panel defect; it is a stale gate baseline reacting correctly to a real, intended new keybind. **Recommendation: file it alongside the `waybar-equivalence-check` baseline fix as a standalone quick task**, not a phase-close blocker.

### 1. The measurement gap, stated once, in one place

**Every one of 15-05, 15-06, 15-07, 15-08, and this plan's own `rfkill` procedure hit the identical root cause: this host has no synthetic pointer-input tool** (`ydotool`/`dotool`/`wlrctl`/`xdotool` all confirmed absent, repeatedly, across five separate sessions; `wtype` exists but is keyboard-only). Every click-driven interaction below is therefore **source-verified and IPC-proven where an equivalent non-click path exists, but never literally clicked**:

| Surface | What's unclicked | Can you settle it in a few minutes? |
|---|---|---|
| Audio panel | (none outstanding — 15-04 already closed with a human render-gate pass and a fix) | — |
| Wifi panel | PSK entry into a real password field; in-flight Cancel's actual abort effect; Forget's confirm; a produced connect failure | **Yes** — a few minutes of real clicking on your own network. The one item that isn't purely "click it": Cancel's abort effect needs a connection attempt slow enough to catch mid-flight, which may take a couple of tries. |
| Bluetooth panel | Pairing, connect, forget, the inferred-failure watchdog | **Needs hardware this host lacks** — zero paired devices and zero discoverable peers were found in a live 8-second scan. You'll need a real discoverable Bluetooth peer (a phone, headset, etc.) nearby to exercise any of this. Not a "few minutes" item unless you already have a peer on hand. |
| Six-tile grid / chevrons | Chevron hit-target feel; tile-body click paths; the E6 refused-toggle-reverts-visually claim | **Yes** — a few minutes. The underlying guard/loader/dismiss machinery is already IPC-proven end-to-end; what's left is purely "does it feel right under your actual finger." |
| Waybar (athena/vertical/floating) | Pointer-through-hover-drawer clicks; live bluetooth-radio-toggle and mute toggles (deliberately not exercised, to avoid touching your live radio/audio state); second-click behavior; the dead-shell failure mode | **Yes, mostly** — a few minutes for the click-through-hover-drawer paths on all three layouts. The live radio/mute toggles and the dead-shell test are lower priority (mechanism unchanged from already-proven code) and can be skipped unless you specifically want to touch your live session state to confirm them. |
| This plan's own `rfkill` proof | Pressing the Enable button itself (the external-recovery half — arguably the *stronger* proof — was exercised) | **Yes** — 30 seconds: block wifi (`rfkill block wifi`), open the wifi panel, press Enable, confirm the radio comes back and the panel updates. |

**Bottom line on the gap:** everything in the "Yes" rows is answerable in one short sitting with your own hands. The one "Needs hardware" row (bluetooth) is a genuine blocker on tooling this host doesn't have — not a code concern, since every mechanism it would exercise is architecturally identical to the already-proven wifi/audio paths and is fully source-verified.

### 2. Audio panel (15-04) — closed, no action needed

Already went through its own render gate this session (see 15-04-SUMMARY.md): focal-point hierarchy fix applied and re-verified, density fallback explicitly declined and kept, node-identity/ordering proven with real concurrent streams. **Recommendation: no further action — this one is done.** The one open, non-blocking item carried forward: long device names were never observed to actually overflow the elision mechanism on this host's real device names (mechanism present and grep-verified, just never genuinely tested against overflow) — not worth chasing on this hardware.

### 3. Wifi panel (15-05)

- **Focal point / current-connection emphasis:** unverified visually (no active wifi connection existed on this host to render it). **Recommendation: connect to a real network and confirm the connected row reads as visually primary** (`Colours.surfaceVariant` fill, mirroring the audio panel's own approved pattern).
- **Two-stage Escape:** only the trivial case (nothing expanded, one press dismisses) was proven; the two-stage case (row expanded, first Escape collapses without dismissing) needs a click first. **Recommendation: expand a password row, press Escape once (expect: row collapses, panel stays open), press again (expect: panel closes).**
- **Cancel's real effect:** implemented and wired to a real teardown call, but whether that teardown actually aborts an in-flight WPA handshake (versus silently no-op'ing until NetworkManager's own timeout) is **completely unmeasured**. **Recommendation: start a connect attempt against a real secured network, press Cancel while it's still spinning, and watch whether it stops immediately or keeps going.**
- **Forget's confirm friction:** implemented (separated placement, error tone, two-press confirm) but never pressed. **Recommendation: forget a real saved network and confirm the two-step feels like enough friction without being annoying.**
- **A produced failure:** never seen live. **Recommendation: type a wrong password on purpose once and read the failure copy that appears on the row.**

### 4. Bluetooth panel (15-06)

- **Everything hardware-transition-shaped** (pair, connect, disconnect, forget, the inferred-failure watchdog, the press-guard) is source-verified only — this host had zero paired devices and zero discoverable peers in an 8-second live scan. **Recommendation: this is the one item on this whole list that genuinely needs hardware you have and this host doesn't** — bring a real discoverable Bluetooth peer near the machine and run through pair -> connect -> disconnect -> forget once.
- **The chevron's tap-target feel** and the **four fixed-width row states seen back to back** (idle/pending/failed/confirming) are both flagged by the implementing session itself as "structurally sound but never watched happen." **Recommendation: once you have a peer to test with, this falls out of the same pairing/connect session above — no separate pass needed.**
- **The disconnect-produces-no-failure-text asymmetry** (a failed pair/connect shows "Couldn't pair"/"Couldn't connect"; a failed disconnect shows nothing, matching the UI-SPEC's locked copy contract) — **Recommendation: accept as built.** This is a deliberate, contract-driven choice, not an oversight; minting new locked copy the contract doesn't provide would be scope creep.

### 5. Quick-toggle grid + chevrons (15-07)

- **"Do Not Disturb" legibility at six-across:** live-verified this session with a zoomed screenshot — renders on one line with margin to spare, no clipping. **Recommendation: approve, no action.**
- **Chevron discoverability/hit-target:** glyph and visibility gating are correct (screenshot-confirmed), but the actual click landing on the 32×32 region was never tried. **Recommendation: click each of the three chevrons (Volume/Wi-Fi/Bluetooth) once and confirm the matching panel opens** — the underlying `openPanel()` function is already IPC-proven identical to what the click would call, so this is really testing "does my finger find the right spot," not "does the code work."
- **E6 (a refused toggle reverts, doesn't stick lit):** this plan's own `rfkill` procedure gives you the concrete instrument — with wifi blocked, the dashboard screenshot **already confirms** the Wi-Fi tile renders unlit rather than sticking lit (see "rfkill fault injection" above). **Recommendation: treat this as settled** by this plan's own live evidence; no further click needed unless you want to watch the transition happen in real time rather than see a before/after screenshot.

### 6. Waybar click rewiring (15-08)

- **Pointer-through-hover-drawer clicks** on athena's network/bluetooth/audio pills, plus a layout switch to vertical/floating with real pointer interaction: never tried (IPC-level proof is a strong proxy — identical command string, live shell — but doesn't confirm the hover-drawer capsule is clickable at its actual screen position). **Recommendation: click through each bar layout once**, a few minutes total.
- **Live radio/mute toggles via the bar** (bluetooth right-click, audio left-click mute): deliberately not exercised to avoid disrupting your live session state. **Recommendation: low priority — the resolved-config string is byte-identical to what shipped before this phase touched nothing about those two clicks' underlying commands, only the panel-opening clicks are new.**
- **Second-click behavior** (does clicking an already-open panel's bar pill close it, close-then-reopen, or nothing): explicitly flagged as genuinely unknowable from source. **Recommendation: click a bar pill twice in a row once and see what happens — takes ten seconds, and settles a real open question rather than a formality.**
- **Dead-shell failure mode:** not tested (killing the live Quickshell process was correctly out of scope for an unattended session). **Recommendation: skip — the mechanism is unchanged from 15-03's own already-verified `qs ipc call panel open notarealpanel` behavior (silent no-op), and testing it means killing your running shell for no new information.**

### 7. This plan's own gate (Task 4, item 6 — do you trust the checks?)

Run `quickshell-doctor` yourself and read the output (not just the tally) — the full text is quoted above. Then run `quickshell-doctor --self-test` and watch the sixteen poisoned fixtures fail on purpose (also quoted above, all 17 self-test entries pass, meaning all ten poison shapes really did flip red). **Recommendation: approve** — every new check's positive claim was watched to fail on a real-shaped defect before being trusted to pass, which is the exact house rule this plan exists to prove was followed, not merely asserted.

### 8. The three reported-condition decisions (answer even when approving, per Task 4's resume-signal)

1. **`waybar-equivalence-check` is a vacuous green** (orphaned baseline). **Recommendation: standalone quick task, not this phase** — re-pointing diffs six phases of intentional change, re-snapshotting silently blesses them (14-10's own refused mistake for the sibling gate).
2. **The SwayOSD server was found down.** **Recommendation: accept this plan's guard fix now** (a dead server SKIPs with a named reason instead of a misleading FAIL) **and file the autostart reliability question separately** — `autostart.lua` already declares the server, so this reads as a one-off session-start miss rather than a structural defect, but confirming that needs a debugging session across a real logout/login, not a phase-close edit.
3. **Two carried claims were stale** (the volume-probe filing, the mouse-field forgiveness). **Recommendation: accept the corrections into the record** (both already reflected in this SUMMARY's "Four re-measured conditions" above) — plus a fourth, newly-found one this sweep surfaced (`hypr-equivalence-check`'s `binds.json`), which the standing instruction to "report anything wrong even if every mechanical check passed" applies to as well.

### Criterion 5's second half, answered directly

**One step, one pill, per press, confirmed live this session** with the server freshly started: `swayosd-client --output-volume raise` moved the sink by exactly the recorded baseline delta (`3277` raw units, drift `0`) and the OSD pill (`namespace: "swayosd"`) mounted exactly once, confirmed by 50ms-interval polling across the press. **Whether it survives a fresh session (full logout/login) is NOT confirmed** — this session only proved it survives from a mid-session manual restart through the rest of this plan's own sweep, not across an actual session boundary. **Recommendation: the next time you log out and back in, run `quickshell-doctor` once and confirm the volume probe still PASSes** (if it FAILs or SKIPs again, `autostart.lua` genuinely isn't reliably starting the server, and that's the debugging session mentioned in item 8.2 above). With a panel open, changing volume from the panel produces **zero** pills (confirmed differentially above, `pipewire-write=0`) — the asymmetry is real and measured, not merely asserted; whether it *feels* right rather than merely defensible is the one genuinely subjective question left for you.
