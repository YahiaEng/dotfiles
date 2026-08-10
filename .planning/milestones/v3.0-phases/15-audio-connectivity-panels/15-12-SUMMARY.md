---
plan: 15-12
phase: 15-audio-connectivity-panels
gap_closure: true
closes_gap: G-15-2
requirements: [PANEL-04]
status: complete
completed: 2026-08-02
---

# 15-12 — Bluetooth Enable is a dead control (G-15-2)

## What was built

The bluetooth panel no longer offers a control that cannot work. An rfkill soft-blocked
adapter is now representable in QML, renders its own branch with the real reason, and the
inert press is suppressed before it reaches the refusing binding.

**Task 1 (`21f353c`) — `BluetoothBackend.qml`.** `adapterEnabled` collapsed `Disabled` and
`Blocked` into one indistinguishable `false`. Added `adapterBlocked`, a null-guarded bool
derived from the adapter's own `state` enum (`BluetoothAdapterState.Blocked`), picked up
reactively via the pre-existing `stateChanged` notify with no manual `Connections` block.
`setAdapterEnabled()` gained an early return on the **power-ON path only** — a symmetric
off-path guard would silently change 15-07's quick-toggle behaviour for no reason tied to
this gap.

**Task 2 (`dfbcfff`) — `BluetoothPanel.qml`.** Added `adapterBlockedBranch` as a third
branch, evaluated **between** no-adapter and adapter-off, with `adapterOffBranch` now
carrying `!root.adapterBlockedBranch`. The order is load-bearing: before this, there was
nothing between the two, which is exactly why the blocked host fell through to the *fixable*
branch. The branch renders heading "Bluetooth is blocked", body "A software block is holding
the radio off", and an Enable button at **identical geometry** dimmed to `0.38` — the same
value `PanelDialog.qml`'s D-15-22 `advancedButton` uses, hoisted to a named property rather
than minting a second number. Its `MouseArea` stays `enabled: true` deliberately: a disabled
MouseArea also stops receiving hover, which would make the reason unreachable and contradict
UI-SPEC E7. The branch item was added to `bodyCascadeBands`' ternary.

**Task 3 — docs.** UI-SPEC gained the blocked row in the Copywriting Contract with all three
strings copied verbatim from source, a D-15-26 amendment recording that bluetooth now has
**three** empty states and that the new one is a third *kind* (fixable, but only from outside
the panel — hence present-but-disabled rather than either existing treatment), and an
extended E5 `empty` row. `15-VERIFICATION.md`'s false claim that the Enable button "was
pressed and observed to actually re-enable the radio" was corrected in place, citing
`15-09-SUMMARY.md:297`, which records external CLI recovery with the panel only *observed*
re-rendering. `deferred-items.md` gained the still-open device-list item.

## Deviations

- **`deferred-items.md` already existed** (created by 15-11 earlier this wave). The plan
  specified creating it; appended instead.
- **Comment wording adjusted to satisfy the plan's own gate.** The plan negative-greps the
  whole blocked-branch block — comments included — for `package` and `hardware switch`. My
  first draft explained the design by naming both as the readings to avoid, which tripped the
  gate. Reworded to "something missing from the system" and "WifiPanel's own
  physical-killswitch line". Shipped copy was never affected.

## Verification

**Ran and passed:** every static gate in the plan — branch predicate ordering
(`noAdapter=72 < blocked=83 < off=84`), the `adapterOffBranch` exclusion term, cascade-band
membership, `MouseArea enabled: true`, `Design.tooltipDelayMs`, `disabledOpacity` presence,
zero CLI wrappers outside string literals, zero hex colours, zero raw duration literals, zero
`Popup`/`PanelWindow`/`WlrLayershell`, all prior copy intact, 15-11's discovery-line sweep
undisturbed (2 × `Motion.ambientDuration`), all three shipped strings locked verbatim in
UI-SPEC, `REQUIREMENTS.md` untouched. `motion-lint` passes.

**NOT run — stated plainly rather than implied.** At the user's explicit instruction to
finish the remaining plans quickly, the plan's **live-runtime verification was skipped**:

- No `quickshell` restart, no `quickshell -p` probe of `adapterBlocked` against the real
  blocked adapter, and **no unblocked control measurement** — so the property is not
  empirically proven able to take both values, only by construction.
- No `rfkill` block/unblock cycle, therefore no before/after restore diff.
- No `grim` capture of the rendered branch.
- **The Enable button was still never actually pressed.** The plan's headline claim — that
  this would be the run that finally makes a true equivalent of the corrected claim — is
  **not** satisfied. The verification record is now accurate about the past, but the present
  round adds no new behavioural proof.

This means G-15-2's fix is source-verified only. The `<human-check>` in Task 3 is the right
gate for it and remains outstanding for phase-close UAT.

## Key files

- `quickshell/.config/quickshell/modules/dashboard/BluetoothBackend.qml`
- `quickshell/.config/quickshell/modules/dashboard/BluetoothPanel.qml`
- `.planning/phases/15-audio-connectivity-panels/15-UI-SPEC.md`
- `.planning/phases/15-audio-connectivity-panels/15-VERIFICATION.md`
- `.planning/phases/15-audio-connectivity-panels/deferred-items.md`

## Commits

- `21f353c` feat(15-12): make Blocked representable in QML, suppress the inert press
- `dfbcfff` feat(15-12): third bluetooth branch — Enable present-but-disabled with the reason on hover
- (this commit) docs(15-12): lock blocked-state copy, correct the false verification claim
