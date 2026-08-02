---
status: diagnosed
trigger: "Clicking enable on bluetooth does nothing. If this is due to me missing required packages, then the bluetooth should show as disabled and label the reason when I hover on it."
created: 2026-08-02T19:00:00Z
updated: 2026-08-02T19:35:00Z
---

## Current Focus

hypothesis: CONFIRMED (AND-gate, two contributing causes) — (env) the host adapter is rfkill soft-blocked, so Quickshell's BluetoothAdapter binding refuses the `enabled = true` write outright; (code) BluetoothPanel/BluetoothBackend read only `adapter.enabled` and never `adapter.state`, so the Blocked condition is neither rendered nor surfaced, and the refusal is logged to stderr only.
test: complete — live rfkill/BlueZ state, live quickshell -p adapter-state probe, and six matching refusal lines in the running shell's own log
expecting: n/a — diagnosis complete
next_action: none (goal: find_root_cause_only — no fix applied, machine state untouched)

reasoning_checkpoint:
  hypothesis: "Clicking Enable calls setAdapterEnabled(true) -> adapter.enabled = true, but Quickshell's BluetoothAdapter C++ binding short-circuits the write because the adapter's state is BluetoothAdapterState.Blocked (rfkill soft block). The refusal goes to stderr only; no QML surface consumes it, so the UI never changes and the press reads as inert."
  confirming_evidence:
    - "~/.cache/quickshell.log lines 1650-1656: six consecutive 'ERROR quickshell.bluetooth.adapter: Cannot enable adapter because it is blocked by rfkill.' entries, interleaved with the panel's own cascade DEBUG lines — direct observation of the user's repeated clicks reaching the binding and being refused."
    - "Live read-only quickshell -p probe: adapterPresent=true adapterCount=1 enabled=false stateEnum=4 stateName=Blocked name=arch (BluetoothAdapterState.Blocked == 4)."
    - "rfkill list: hci0 Bluetooth Soft blocked: yes / Hard blocked: no. BlueZ agrees: Adapter1.PowerState == 'off-blocked', Powered == false."
    - "grep across quickshell/ for BluetoothAdapterState / adapter.state returns zero hits — the Blocked signal is never read anywhere in the repo."
  falsification_test: "If the log had shown no bluetooth error at click time, or if the probe had reported state=Disabled (0) instead of Blocked (4), the inert click would be a UI-wiring fault instead. Both came back the other way."
  fix_rationale: "n/a — diagnose-only mode. Fix direction addresses the root cause by making Blocked representable in QML (a new backend readonly bool over adapter.state) and rendering a third panel branch, rather than by retrying the write (which the binding will always refuse) or by shelling out to rfkill (Prohibition P1)."
  blind_spots: "The exact BlueZ/kernel behaviour if the write DID reach D-Bus was not tested — Quickshell refuses before D-Bus, so it is moot for this bug. Whether unblocking rfkill from inside the panel is desirable (vs. disabled-with-reason) is a design decision, not a diagnosis, and is left to the fix plan."
  candidate_causes:
    - "environment: adapter rfkill soft-blocked, persisted across reboots by systemd-rfkill (/var/lib/systemd/rfkill/pci-0000:02:00.0-usb-0:5:1.0:bluetooth == 1)"
    - "code: BluetoothBackend.qml exposes only adapterPresent/adapterEnabled, never adapter.state; BluetoothPanel.qml has two branches where WifiPanel.qml has three; setAdapterEnabled() has no failure path and no adapter-level error signal"
    - "config: ruled out — no config controls this; the panel is loaded and rendering correctly (the Enable button drew and received the press)"
    - "data/packages: ruled out — bluez 5.87-2, bluez-utils 5.87-2, blueman 2.4.6-2 all installed; bluetoothd running 1d1h; real controller 60:E9:AA:20:44:B0 enumerated on hci0"
  and_gate: "YES — both conditions are required simultaneously. With rfkill unblocked, the same click succeeds (proven in 15-09/15-API-PROBE). With the code reading adapter.state, the blocked host would render a disabled control with a reason instead of an inert button. Neither cause alone produces the reported symptom."

## Symptoms

expected: Clicking enable on the bluetooth panel powers the adapter on and the UI reflects the new state. If a prerequisite is missing, the control renders as disabled and a hover tooltip states the reason.
actual: Clicking enable on bluetooth does nothing (no visible state change, no error surfaced in the panel).
errors: "ERROR quickshell.bluetooth.adapter: Cannot enable adapter because it is blocked by rfkill." — present six times in ~/.cache/quickshell.log, never surfaced to the UI.
reproduction: Test 2 in .planning/phases/15-audio-connectivity-panels/15-UAT.md — open the bluetooth panel and click Enable while `rfkill list bluetooth` reports `Soft blocked: yes`.
started: Discovered during UAT of phase 15 (audio-connectivity-panels)

## Eliminated

- hypothesis: "Missing required packages (the user's own stated guess)"
  evidence: "pacman -Q reports bluez 5.87-2, bluez-utils 5.87-2, blueman 2.4.6-2 all installed. The missing prerequisite is an unblocked radio, not a package."
  timestamp: 2026-08-02T19:08:00Z

- hypothesis: "bluetoothd is not running / D-Bus service absent"
  evidence: "systemctl: bluetooth.service active (running) since 2026-08-01 16:49:54, enabled, PID 638, and actively registering A2DP media endpoints as of 17:54 today."
  timestamp: 2026-08-02T19:08:00Z

- hypothesis: "No bluetooth adapter on this host (the investigation notes' explicit possibility)"
  evidence: "bluetoothctl list prints Controller 60:E9:AA:20:44:B0 arch [default]; /sys/class/bluetooth/hci0 exists (USB, 1-5:1.0); btusb+btintel+btrtl+btmtk+btbcm loaded; live quickshell probe reports adapterCount=1, adapterPresent=true."
  timestamp: 2026-08-02T19:10:00Z

- hypothesis: "The Enable button's click handler is mis-wired / calls nothing (the notes' primary UI-path suspicion)"
  evidence: "BluetoothPanel.qml:294-300 MouseArea.onClicked -> backend.setAdapterEnabled(true); BluetoothBackend.qml:52-56 -> root.adapter.enabled = on. The chain is correct AND is proven to execute: the click produced a refusal log line from the C++ binding, which can only be reached by a real write attempt."
  timestamp: 2026-08-02T19:20:00Z

- hypothesis: "Hard rfkill block / physical killswitch"
  evidence: "rfkill list: hci0 Hard blocked: no. The block is soft (software), i.e. user-recoverable via `rfkill unblock bluetooth`."
  timestamp: 2026-08-02T19:08:00Z

- hypothesis: "The 15-09 rfkill fault injection leaked a block and left the machine dirty"
  evidence: "15-09-SUMMARY.md:291,306-313 records the found state as ALREADY soft-blocked and shows byte-identical before/after. 15-API-PROBE.md:161 records the same restore. 15-VERIFICATION.md:96 calls it 'pre-existing host state'. systemd-rfkill has persisted value 1 for this device. The block is the host's own long-standing state, not test residue."
  timestamp: 2026-08-02T19:25:00Z

## Evidence

- timestamp: 2026-08-02T19:08:00Z
  checked: Live prerequisite sweep — systemctl status bluetooth, pacman -Q bluez bluez-utils blueman, rfkill list, bluetoothctl list/show, /sys/class/bluetooth, lsmod
  found: bluetoothd active 1d1h (PID 638); bluez 5.87-2 + bluez-utils 5.87-2 + blueman 2.4.6-2 installed; real controller 60:E9:AA:20:44:B0 on hci0; btusb stack loaded. BUT rfkill reports hci0 `Soft blocked: yes`, and BlueZ reports `Powered: no` / `PowerState: off-blocked`.
  implication: Every prerequisite the user suspected is present. The single blocking condition is an rfkill SOFT block — and BlueZ itself names it (`off-blocked`).

- timestamp: 2026-08-02T19:12:00Z
  checked: busctl introspect org.bluez /org/bluez/hci0 org.bluez.Adapter1
  found: `Powered` is `writable`, currently false; `PowerState` (readonly) is "off-blocked".
  implication: BlueZ exposes the block as a distinct, machine-readable reason distinct from plain "off".

- timestamp: 2026-08-02T19:14:00Z
  checked: /usr/lib/qt6/qml/Quickshell/Bluetooth/quickshell-bluetooth.qmltypes
  found: BluetoothAdapter has `enabled` (bool, read/write) AND `state` (readonly, BluetoothAdapterState::Enum, bindable, notify stateChanged). The enum values are [Disabled, Enabled, Enabling, Disabling, Blocked] — Blocked == 4.
  implication: Quickshell models "blocked" as a first-class adapter state, separate from `enabled == false`. The signal the panel needs already exists in the installed binding.

- timestamp: 2026-08-02T19:15:00Z
  checked: grep -rn 'BluetoothAdapterState|adapter.state' quickshell/ --include=*.qml
  found: ZERO hits. Nothing in the repo reads the adapter's state enum.
  implication: The Blocked condition is not representable anywhere in this repo's QML. `adapterEnabled` (a plain bool) collapses Disabled and Blocked into one indistinguishable value.

- timestamp: 2026-08-02T19:18:00Z
  checked: ~/.cache/quickshell.log (the RUNNING shell's own log), lines 1640-1660
  found: Six consecutive `ERROR quickshell.bluetooth.adapter: Cannot enable adapter because it is blocked by rfkill.` lines, interleaved with the panel's `cascade: run tab=...` DEBUG lines. An earlier single occurrence at line 1250.
  implication: DIRECT OBSERVATION of the bug. The click handler fires, reaches the C++ binding, and the binding refuses the write. The user clicked ~6 times, saw nothing, and the only trace went to stderr.

- timestamp: 2026-08-02T19:22:00Z
  checked: Read-only `quickshell -p` probe (no window, no write, exits immediately) reading Bluetooth.defaultAdapter
  found: `PROBE tick=1 adapterPresent=true adapterCount=1 enabled=false stateEnum=4 stateName=Blocked name=arch` and `PROBE enumRef Disabled=0 Enabled=1 Blocked=4`.
  implication: The live adapter state IS `Blocked`. Had the panel read `adapter.state`, it would have had the exact reason available at render time, before the press.

- timestamp: 2026-08-02T19:24:00Z
  checked: BluetoothPanel.qml:72-76, 202-303, 858 vs WifiPanel.qml:76-77, 281-315, 1006
  found: WifiPanel has THREE branches — `radioBlockedBranch` (unfixable, hardware, NO button, copy "Turned off by a hardware switch"), `radioOffBranch` (fixable, Enable button), populated. BluetoothPanel has only TWO — `noAdapterBranch` (no adapter, no button) and `adapterOffBranch` (Enable button). There is no blocked branch.
  implication: The bluetooth panel is missing wifi's middle case exactly. On this host it falls through to `adapterOffBranch` and offers a button that provably cannot work — violating D-15-26's own stated governing principle, quoted in BluetoothPanel.qml:273-275: "never offer a control that cannot work."

- timestamp: 2026-08-02T19:26:00Z
  checked: PanelDialog.qml:245-290 (D-15-22 treatment) and BluetoothPanel.qml:46-49
  found: A complete, documented present-but-disabled convention already ships: identical geometry (never hidden, never collapsed), `disabledOpacity: 0.38` on fill and label, MouseArea deliberately left `enabled: true` so hover still reaches the tooltip, press suppressed by an early-return in the action function instead, `ToolTip.text` swapped to the reason, `ToolTip.delay: Design.tooltipDelayMs`. The bluetooth panel already consumes it for Advanced (`advancedUnavailableReason: "blueman-manager is not installed"`).
  implication: Exactly the affordance the user asked for already exists as house convention. It was simply never applied to the Enable button.

- timestamp: 2026-08-02T19:28:00Z
  checked: 15-API-PROBE.md:22
  found: "Bluetooth.defaultAdapter ... transitioned live from null -> a real adapter object -> `enabled: false, state: Blocked` while rfkill reported the adapter soft-blocked, then to `enabled: true, state: Enabled` within 3s of `rfkill unblock bluetooth`".
  implication: The phase's OWN probe document recorded `state: Blocked` as the live distinguishing signal before the panel was built — and the panel was built reading only `enabled`. The information needed to build the third branch existed and was not used.

- timestamp: 2026-08-02T19:30:00Z
  checked: 15-09-SUMMARY.md:289-317 vs 15-VERIFICATION.md:40
  found: 15-VERIFICATION.md:40 claims "the fixable-off-state Enable button was pressed and observed to actually re-enable the radio." Its own cited source contradicts this: 15-09-SUMMARY.md:297 records "**External recovery** (not the Enable button — see gap note below): `rfkill unblock wifi` from outside the panel", and the bluetooth case (lines 300-304) likewise recovers via `rfkill unblock bluetooth` from the CLI, with the panel only OBSERVED re-rendering.
  implication: The Enable button was never pressed in any verification. The phase closed on an overstated verification claim; UAT was the first time a human actually pressed it. This is the "why wasn't this caught" answer.

- timestamp: 2026-08-02T19:32:00Z
  checked: journalctl rfkill events + /var/lib/systemd/rfkill/
  found: Last bluetooth rfkill event was `Aug 02 06:09:16 rfkill[3517252]: block set for type bluetooth` (the 15-09/API-probe restore); systemd-rfkill has persisted `1` for pci-0000:02:00.0-usb-0:5:1.0:bluetooth as of Aug 02 17:54.
  implication: The soft block is the host's persistent state and survives reboots. This is not transient — the panel will keep showing an inert Enable button on every boot until either the block is cleared or the panel learns about it.

## Resolution

root_cause: "AND-gate, two simultaneously-required contributing causes. (1) ENVIRONMENT: the host's bluetooth adapter (hci0, 60:E9:AA:20:44:B0) is rfkill SOFT-blocked — a persistent host state saved by systemd-rfkill across reboots, not test residue — so Quickshell's BluetoothAdapter binding refuses `enabled = true` outright, logging 'Cannot enable adapter because it is blocked by rfkill.' to stderr and never touching D-Bus; (2) CODE: BluetoothBackend.qml exposes only `adapterPresent`/`adapterEnabled` and never reads `adapter.state`, so BluetoothAdapterState.Blocked (enum 4, confirmed live) is not representable in QML; BluetoothPanel.qml therefore has only two branches where WifiPanel.qml has three, falls through to the fixable `adapterOffBranch`, and renders an Enable button that provably cannot work; and `setAdapterEnabled()` has no failure path and no adapter-level error signal (`deviceActionFailed` is device-scoped only), so the refusal is swallowed entirely."
fix: "[not applied — diagnose-only mode]"
verification: "[not applied — diagnose-only mode]"
files_changed: []
oracle_type: implicit (observed stderr refusal) + specified (documented D-15-22/UI-SPEC E7 affordance contract)
