---
status: diagnosed
trigger: "Scan progress line is moving too fast. Pressing on \"rescan\" needs to show feedback that the rescan action is underway."
created: 2026-08-02T08:00:00Z
updated: 2026-08-02T08:40:00Z
---

## Current Focus
<!-- OVERWRITE on each update - reflects NOW -->

hypothesis: CONFIRMED (two independent root causes, see Resolution)
test: complete — both causes proven by direct source trace + live token read + two qml6 harness measurements
expecting: n/a
next_action: Diagnosis complete (goal: find_root_cause_only). Hand off to plan-phase --gaps for G-15-1. Do NOT fix here.

bug_class: Bohrbug (deterministic — reproduces on every press, no timing/concurrency component)

reasoning_checkpoint:
  hypothesis: |
    Two independent causes. RC1: the progress line's sweep duration binds to
    Motion.emphasizedInDuration/emphasizedOutDuration — MD3 ONE-SHOT TRANSITION
    tokens (375ms/187ms live) — used as the period of an INFINITE LOOP, giving a
    562ms round trip. RC2: `backend.scanning` is a LEVEL (scannerEnabled, true for
    the panel's whole open lifetime) not an EDGE, and rescan() writes
    false-then-true synchronously, so no observable state differs across the press.
  confirming_evidence:
    - "Live ~/.local/state/theme/motion.json at scale=lively: emphasized-in=375ms, emphasized-out=187ms -> 562ms full sweep cycle"
    - "qml6 harness t2.qml: scanning/trackOpacity/animRunning all byte-identical before and after rescan(); 2 notifications fire inside one synchronous JS frame, net observable change NONE"
    - "WifiBackend.qml:98-101 comment states the level-not-edge behaviour outright: 'scanning is true for the panel's whole open lifetime rather than pulsing per sweep'"
    - "quickshell-network.qmltypes: WifiDevice exposes ONLY scannerEnabled + scannerEnabledChanged; no scanning/scanStarted/scanCompleted/lastScan member exists"
    - "Motion.qml exposes no alias for the three loop-period tokens (ambient/blink-slow/blink-fast) that exist in the rendered motion.json"
  falsification_test: |
    RC1 would be false if the SequentialAnimation's duration resolved to a
    loop-period token (>=1000ms) — it does not, it resolves to 375/187ms.
    RC2 would be false if any UI-bound property changed value across the press —
    measured directly, none does.
  fix_rationale: n/a (diagnose-only mode — no fix applied)
  blind_spots:
    - "Not visually confirmed on the live panel (no synthetic pointer tool on this host — the same why_human constraint that produced this UAT gap). Both causes are proven by source trace + live token values + harness measurement, not by watching pixels."
    - "The harness models scannerEnabled as a plain QtObject bool. If Quickshell's real C++ WifiDevice coalesces the false/true writes before notifying, the notification count differs — but the NET observable state is identical either way, which is what RC2 rests on."
  candidate_causes:
    - "code: one-shot transition token used as an infinite-loop period (RC1)"
    - "code: rescan() produces no observable state edge (RC2a)"
    - "code: the refresh control has no pressed/active visual state of its own (RC2b)"
    - "config/data: motion.json's loop-period tokens (ambient, blink-slow, blink-fast) have no Motion.qml alias, so no loop period was reachable from QML"
    - "design/spec: 15-UI-SPEC.md:177 LOCKED the level behaviour ('for the panel's whole open lifetime while scannerEnabled is true') — the implementation matches spec; the spec is what failed UAT"
    - "environment/API: Quickshell.Networking exposes no per-scan-cycle property or signal at all (constrains, does not cause)"
  and_gate: |
    YES for symptom 2 — it needs BOTH (a) `scanning` being a level not an edge AND
    (b) the refresh control carrying no press-state of its own. Either one alone
    would still have produced some visible acknowledgement of the press. Both are
    absent, so the press is completely silent.
    NO for symptom 1 — RC1 is a single sufficient cause (the token choice), with the
    missing-alias finding as its enabling condition rather than a second cause.

## Symptoms
<!-- Written during gathering, then IMMUTABLE -->

expected: The scan progress indicator animates at a readable pace, and pressing "Rescan" produces immediate visible feedback that a scan has started (and that it is still running until results land).
actual: "Scan progress line is moving too fast. Pressing on 'rescan' needs to show feedback that the rescan action is underway."
errors: None reported
reproduction: Test 1 in .planning/phases/15-audio-connectivity-panels/15-UAT.md — open the wifi panel (`qs ipc call panel toggle wifi` or the Wi-Fi tile chevron) and press Rescan.
started: Discovered during UAT of phase 15 (audio-connectivity-panels)

## Eliminated
<!-- APPEND only - prevents re-investigating -->

- hypothesis: "rescan()'s imperative `scannerEnabled = false/true` write breaks the declarative lifecycle Binding in WifiBackend.qml:90-95, so the scanner stays armed after the panel closes"
  evidence: |
    DISPROVEN by qml6 harness (scratchpad/bindtest/t.qml), which reproduces the exact
    Binding + imperative-write shape. Qt logs `qt.qml.binding.removal: ... was changed
    from elsewhere. This does not overwrite the binding. The target property will still
    be updated when the value of the Binding element changes.` Step E confirms
    behaviourally: setting panelOpen=false AFTER a rescan() still drives
    scannerEnabled to false. The Binding survives. This is a non-issue and any fix
    may keep the false/true toggle without inheriting a lifecycle bug.
  timestamp: 2026-08-02T08:30:00Z

- hypothesis: "The animation is fast because the motion scale is set to a fast preset"
  evidence: |
    DISPROVEN — inverted. Live scale is `lively` (multiplier 1.25), which MULTIPLIES
    durations, making it the SLOWEST available setting for this animation (562ms).
    `normal` (1.0) gives 450ms and `reduced` (0.5) gives 225ms. The scale cannot fix
    this, and the reduced-motion preset makes it ~2.5x worse — see Evidence entry 6.
  timestamp: 2026-08-02T08:35:00Z

## Evidence
<!-- APPEND only - facts discovered -->

- timestamp: 2026-08-02T08:10:00Z
  checked: WifiPanel.qml:829-916 (the `progressLine` Item — the scan progress line and refresh control)
  found: |
    The sweeping segment is animated by a `SequentialAnimation` with
    `loops: Animation.Infinite` (line 865-886). Its two legs use
    `duration: Motion.emphasizedInDuration` (line 873) and
    `duration: Motion.emphasizedOutDuration` (line 883). The segment is 30% of the
    track width (line 862) and travels 0 -> (track - segment) -> 0.
  implication: |
    The loop period is entirely determined by two MD3 semantic tokens whose declared
    purpose is one-shot enter/exit transitions, not continuous loop periods. Nothing
    here is decoupled from real scan state by accident — it is decoupled by design,
    because the token it binds to is a level (see evidence 3).

- timestamp: 2026-08-02T08:12:00Z
  checked: Live rendered ~/.local/state/theme/motion.json + ~/.local/state/theme/motion-scale
  found: |
    motion_scale = "lively" (multiplier 1.25). Live resolved values:
      emphasized-in  = 375ms (easing emphasized-decelerate)
      emphasized-out = 187ms (easing emphasized-accelerate)
    Full round trip = 375 + 187 = 562ms, i.e. ~1.78 complete sweeps per second on a
    3px-tall bar. Authored base (motion.json semantic): emphasized-in = medium2 = 300,
    emphasized-out = short3 = 150.
  implication: |
    Confirms "moving too fast" numerically. MD3's own indeterminate linear progress
    indicator specifies a ~2000ms cycle; this runs 3.5x faster than that reference at
    the SLOWEST configured motion scale.

- timestamp: 2026-08-02T08:15:00Z
  checked: WifiBackend.qml:85-113 (the scan lifecycle gate, `scanning`, and `rescan()`)
  found: |
    A declarative `Binding` sets `wifiDevice.scannerEnabled = panelOpen && wifiEnabled`
    (lines 90-95). `scanning` is a straight read-back of that same flag
    (line 101: `readonly property bool scanning: root.wifiDevice ? root.wifiDevice.scannerEnabled : false`).
    The file's own comment on lines 98-101 states it plainly:
      "There is no per-scan-cycle signal anywhere in this binding, so `scanning` is
       true for the panel's whole open lifetime rather than pulsing per sweep"
    `rescan()` (lines 108-113) is the refresh control's only effect:
      root.wifiDevice.scannerEnabled = false;
      root.wifiDevice.scannerEnabled = true;
    Both writes are synchronous, in one JS call frame.
  implication: |
    `scanning` is a LEVEL ("the scanner is armed"), never an EDGE ("a scan cycle just
    started"). Because the panel being open already forces it true, it is true before
    the press, during the press, and after the press. The progress line therefore
    indicates "the panel is open", not "a scan is underway".

- timestamp: 2026-08-02T08:32:00Z
  checked: qml6 harness (scratchpad/bindtest/t2.qml) reproducing WifiBackend.qml:101 + WifiPanel.qml:841,866 verbatim, then calling rescan()'s exact two-line body
  found: |
    PRE-PRESS : scanning = true | trackOpacity = 1 | animRunning = true
    POST-PRESS: scanning = true | trackOpacity = 1 | animRunning = true
    notifications fired during rescan() = 2 | values observed = [false,true]
    NET OBSERVABLE CHANGE across the press: NONE (identical before and after)
  implication: |
    Direct measurement, not inference: pressing Rescan changes NOTHING the UI is bound
    to. Both notifications land inside a single synchronous frame with no repaint
    between them, so even the momentary `false` is never rendered. The only physical
    consequence is that the infinite SequentialAnimation restarts from x=0 — which,
    at a 562ms cycle, is indistinguishable from the ordinary loop. This is the whole
    of root cause 2a.

- timestamp: 2026-08-02T08:20:00Z
  checked: /usr/lib/qt6/qml/Quickshell/Networking/quickshell-network.qmltypes — full member enumeration of WifiDevice, NetworkDevice, Network, WifiNetwork
  found: |
    WifiDevice (scan-related surface, COMPLETE):
      - Property scannerEnabled : bool          (read/write)
      - Signal   scannerEnabledChanged(bool enabled)
      - Property mode : WifiDeviceMode::Enum    (readonly, unrelated)
    NetworkDevice (inherited):
      - Property networks : UntypedObjectModel  (readonly) -> carries valuesChanged
    There is NO `scanning`, NO `scanStarted`/`scanCompleted`/`scanFinished`, NO
    `lastScanTime`, NO scan-request method anywhere on the type graph.
    Per-network (Network): `state`, `stateChanging`, `connected`, `known` + their
    changed signals — connection state only, nothing scan-related.
  implication: |
    Confirms the backend's recorded finding: the API genuinely offers no per-scan-cycle
    truth. A fix cannot read a real "scan in flight" flag off the platform — it must
    SYNTHESISE the in-flight window client-side. The one real observable of "results
    landed" that already exists is `wifiDevice.networks`'s `valuesChanged`, which
    WifiBackend.qml ALREADY subscribes to (lines 167-172) purely for `_syncSeenOrder()`
    and derives no scan state from.

- timestamp: 2026-08-02T08:36:00Z
  checked: Motion.qml alias surface (lines 110-183) vs the rendered motion.json bucket contents
  found: |
    Motion.qml exposes exactly five duration aliases:
      standardDuration      250ms   (one-shot transition)
      emphasizedInDuration  375ms   (one-shot transition)
      emphasizedOutDuration 187ms   (one-shot transition)
      staggerOffsetDuration  62ms   (one-shot offset)
      borderRotateDuration 10000ms  (loop period)
    The rendered motion.json ALSO carries three further loop/long-period tokens with
    NO Motion.qml alias at all:
      semantic.ambient        1250ms  easing `linear`
      indicators.blink-slow   1250ms  easing `css-linear`
      indicators.blink-fast    625ms  easing `css-linear`
    Motion.qml's own header (lines 163-179) names the distinction explicitly:
    "These are continuous/looping animations rather than one-shot transitions, which
    is why they carry only a period."
    Cause: `_pairNames` (line 56) is a fixed 4-entry positional list, so `ambient` and
    `standard-slow` never reach `pairs`; and only `border-rotate` got a hand-written
    accessor out of the `indicators` bucket.
  implication: |
    The enabling condition for RC1. The token system already distinguishes loop periods
    from transition durations and already ships three suitable values, but only ONE
    loop period (borderRotate, 10000ms — far too slow for a progress sweep) was
    reachable from QML. The panel author had no correctly-scaled loop token available
    and reached for the nearest reachable durations, which are transition tokens.
    A fix that just hardcodes a number would violate motion-lint CHECK B (raw-value
    refusal); the correct move is to expose an alias for an existing token.

- timestamp: 2026-08-02T08:38:00Z
  checked: motion.json `scales` block against the animation's duration bindings
  found: |
    scales: off 1.0 (animations_enabled false) / reduced 0.5 / normal 1.0 / lively 1.25.
    The multiplier MULTIPLIES duration, so a smaller multiplier = faster animation.
    Resulting full sweep cycle per preset:
      reduced 0.5  -> 150 + 75  = 225ms   (~4.4 sweeps/sec)
      normal  1.0  -> 300 + 150 = 450ms   (~2.2 sweeps/sec)
      lively  1.25 -> 375 + 187 = 562ms   (~1.8 sweeps/sec)
      off          -> static full-width bar (line 862 fallback, correct)
    floor_ms is 40, so none of these clamp.
  implication: |
    Perverse consequence worth flagging to whoever plans the fix: the `reduced` motion
    preset — the accessibility setting — makes this indicator the MOST frenetic, at
    ~4.4 sweeps/sec. Any fix must keep the loop period from shrinking under `reduced`,
    which a plain duration token multiplied by 0.5 will always do.

- timestamp: 2026-08-02T08:18:00Z
  checked: WifiPanel.qml:897-915 (`refreshControl`) for any press/active state
  found: |
    A plain `Text` glyph ("refresh") with a fixed `color: Colours.onSurfaceVariant`.
    Its MouseArea sets `hoverEnabled: true` solely to drive a "Rescan" ToolTip. There
    is NO `onPressed`/`pressed` binding, no colour change, no rotation, no scale, no
    disabled/busy state, no opacity change — the control's appearance is a constant.
  implication: |
    Root cause 2b, and the second half of the AND-gate. Even setting aside the missing
    backend state, the control itself never acknowledges the click. A pressed-state or
    a spin-while-scanning on this glyph alone would have satisfied the user's request.

- timestamp: 2026-08-02T08:22:00Z
  checked: .planning/phases/15-audio-connectivity-panels/15-UI-SPEC.md lines 117 and 177
  found: |
    Line 177 (E3 `loading` state table) locked the behaviour as shipped:
      "Indeterminate progress line pinned under the header for the panel's whole open
       lifetime while `scannerEnabled` is true — see Copywriting Contract 'Wifi scan
       in-progress' (D-15-15)"
    Line 117 (Copywriting Contract): "Indeterminate progress line pinned under the
    header, no text needed beyond the line itself (D-15-15); an explicit refresh
    control stays available with its own tooltip, e.g. 'Rescan'".
    Neither line specifies a cycle period.
  implication: |
    IMPORTANT for scoping the fix: the implementation is FAITHFUL to the spec. This is
    not an implementation defect against D-15-15 — the "whole open lifetime" level
    semantics were specified. Closing G-15-1 therefore requires amending 15-UI-SPEC.md
    (D-15-15), not just editing QML, or the next verification pass will flag the fix as
    a spec deviation. The cycle period, by contrast, was never specified and is a free
    implementation choice.

## Resolution
<!-- OVERWRITE as understanding evolves -->

root_cause: |
  Two independent causes, one per reported symptom.

  RC1 (progress line too fast) — the indeterminate sweep is an infinite
  SequentialAnimation whose two legs bind to `Motion.emphasizedInDuration` (375ms) and
  `Motion.emphasizedOutDuration` (187ms), which are MD3 ONE-SHOT ENTER/EXIT TRANSITION
  tokens being used as a continuous LOOP PERIOD. Full cycle = 562ms at the current
  `lively` scale (450ms at `normal`, 225ms at `reduced`) against MD3's ~2000ms
  reference for an indeterminate linear indicator. Enabling condition: motion.json
  already carries three loop-period tokens (`ambient` 1250ms, `blink-slow` 1250ms,
  `blink-fast` 625ms) but Motion.qml exposes an alias for none of them — the only
  reachable loop token is `borderRotateDuration` (10000ms), far too slow — so no
  correctly-scaled loop period was reachable from QML at all.

  RC2 (Rescan gives no feedback) — AND-gated, both conditions present:
    (a) `WifiBackend.scanning` is a LEVEL, not an EDGE. It reads back
        `wifiDevice.scannerEnabled`, which the panel-lifecycle `Binding` already forces
        true whenever the panel is open. `rescan()` writes false-then-true synchronously
        in one JS frame, so every UI-bound property is byte-identical before and after
        the press (measured: trackOpacity 1 -> 1, animRunning true -> true). The
        progress line indicates "the panel is open", never "a scan is underway", and
        the press is invisible.
    (b) The `refreshControl` glyph carries no pressed/active/busy visual state
        whatsoever — a constant-coloured Text whose only interactive affordance is a
        hover tooltip.
  Platform constraint (not a cause): `Quickshell.Networking`'s `WifiDevice` exposes
  only `scannerEnabled` + `scannerEnabledChanged` and no per-scan-cycle member at all,
  so an in-flight window must be synthesised client-side. The one already-available
  "results landed" observable is `wifiDevice.networks.valuesChanged`, to which
  WifiBackend already subscribes for ordering only.

  Spec note: RC2's level semantics were LOCKED by 15-UI-SPEC.md:177 — the code matches
  the spec, so the spec must be amended alongside any fix.

fix: [not applied — diagnose-only mode, goal: find_root_cause_only]
verification: [n/a]
files_changed: []
