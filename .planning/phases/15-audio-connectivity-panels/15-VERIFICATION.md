---
phase: 15-audio-connectivity-panels
verified: 2026-08-02T03:22:17Z
status: human_needed
score: 2/5 must-haves verified
behavior_unverified: 3
overrides_applied: 0
behavior_unverified_items:
  - truth: "The wifi panel scans with a visible in-progress state, lists visible networks, connects to an open network, and prompts for and accepts a password on a secured one."
    test: "Open the wifi panel (Super+A analog is not bound for wifi — use the quick-toggle chevron or `qs ipc call panel toggle wifi`). Confirm the scan progress line appears. Select a real secured network, type its password into the inline row, press Connect, and confirm it connects. Separately, expand a password row and confirm the first Escape collapses the row without dismissing the panel, and the second Escape dismisses it. Start a connect attempt and press Cancel mid-flight to confirm it actually aborts rather than silently continuing to NetworkManager's own timeout."
    expected: "Scan progress renders; a secured network's password row appears inline; Connect succeeds against a real password; Cancel visibly aborts an in-flight attempt; two-stage Escape behaves as specified; a wrong password renders the row-scoped 'Wrong password' copy."
    why_human: "This host has no synthetic pointer-input tool (ydotool/dotool/wlrctl/xdotool absent, wtype keyboard-only) and no saved wifi profile (connectivity is via ethernet) — the click-driven connect/password/cancel/forget paths are source-verified and IPC-proven only, never literally exercised. quickshell-doctor's panel-namespace-conformance check does confirm the wifi panel mounts as a lone PanelDialog instance live, but that proves frame conformance, not the connect flow itself."
  - truth: "The bluetooth panel toggles the adapter, lists devices, and connects, disconnects and forgets them."
    test: "With a real discoverable Bluetooth peer (phone, headset, etc.) near the machine: open the bluetooth panel, press 'Add device', confirm the peer appears in the discovered group, pair it, connect it, disconnect it, then forget it (confirming the inline destructive-confirm row first)."
    expected: "Pairing shows a row-scoped spinner with a working Cancel; a successful pair/connect moves the device between groups without reordering peers; Forget requires the inline confirm and then removes the device; a genuine pairing failure renders 'Couldn't pair' scoped to that row."
    why_human: "This host has zero paired Bluetooth devices and zero discoverable peers (confirmed via an 8-second live scan during this verification's antecedent sessions) and no synthetic pointer tool — every hardware-transition path (pair/connect/disconnect/forget/inferred-failure-watchdog) is source-verified only. The adapter on/off half was proven live via real `rfkill` fault injection in 15-09; the device-list half was not, for lack of a peer. Corrected by G-15-2 (15-12): the rfkill fault injection was real, but recovery was a CLI unblock from outside the panel — the Enable button was never pressed until UAT, where it did nothing. The device-list half remains unreachable on this host even after G-15-2's fix, which unblocks the test without performing it."
  - truth: "Each of the three panels carries an Advanced button that launches pavucontrol, nm-connection-editor or blueman for anything past its deliberately limited scope."
    test: "Click each panel's Advanced button (audio/wifi/bluetooth) and confirm pavucontrol / nm-connection-editor / blueman-manager actually opens as a detached window that survives dismissing the panel."
    expected: "All three launch their target GUI, detached from the panel's own lifecycle (closing the panel does not kill the launched app)."
    why_human: "The audio panel's Advanced button (pavucontrol) WAS live-clicked and approved during 15-02's human render gate (Task 4 check 6 — 'Advanced launch + concurrency', no issues raised). The wifi and bluetooth panels' Advanced buttons reuse the identical shared `PanelDialog.startDetached()` mechanism (grep-confirmed: 3 call sites, one per panel, no lifetime-bound `running: true` anywhere) and their target-binary presence was confirmed via a live `which` probe, but neither nm-connection-editor nor blueman-manager was actually clicked open this session — no synthetic pointer tool available."
gaps: []
deferred: []
---

# Phase 15: Audio + Connectivity Panels Verification Report

**Phase Goal:** Per-app volume, wifi and bluetooth are handled by themed in-shell panels, displacing pavucontrol, nm-connection-editor and blueman from the daily workflow without pretending to replace them.
**Verified:** 2026-08-02T03:22:17Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | The audio panel lists every active audio app with its own volume slider and click-to-mute, and separately selects default output, default input and master volume. | ✓ VERIFIED | `AudioBackend.qml` reads/writes native `Pipewire.defaultAudioSink`/`preferredDefaultAudioSink`/`preferredDefaultAudioSource`/per-node `audio.volume`/`audio.muted` (no subprocess in the read/write path — grep-confirmed). `AudioPanel.qml` renders per-stream rows keyed by node id (`streamNodes`, node-id-ascending, never re-sorted) plus a pinned output/input control block. **Human render gates on this exact behavior were run live and APPROVED**: 15-02 Task 4 (master volume + mute live interaction, no issues) and 15-04 Task 4 (node-identity/ordering proven with real concurrent streams; one focal-point fix applied and re-verified, commit `80039ca`). |
| 2 | The wifi panel scans with a visible in-progress state, lists visible networks, connects to an open network, and prompts for/accepts a password on a secured one. | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | `WifiBackend.qml`/`WifiPanel.qml` exist, are substantive (354/1007 lines), wired into `PanelDialog`, and the connect path (`network.connectWithPsk(psk)`), grouped ordering, and locked `ConnectionFailReason` copy mapping (`Password required` / `Wrong password` / `Couldn't connect` / `Network out of range`) are all present in source with no CLI wrapper in the write path. `scannerEnabled` is bound to `panelOpen` (live-confirmed: zero scan/discovery activity with no panel summoned, per `quickshell-doctor`'s zero-idle check). **Never exercised behaviorally**: this host has no synthetic pointer-input tool and no saved wifi profile (ethernet-connected), so Connect/password-entry/Cancel-abort/Forget-confirm were never literally clicked. See `behavior_unverified_items`. |
| 3 | The bluetooth panel toggles the adapter, lists devices, and connects, disconnects and forgets them. | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | `BluetoothBackend.qml`/`BluetoothPanel.qml` exist, substantive (384/859 lines), device rows keyed by `device.address` (not name), grouped connected→paired→discovered, Forget gated behind an inline confirm, an inferred-failure state machine with a `deviceWatchdogTimer`. The adapter on/off half was **live-proven against real hardware** via `rfkill block`/`unblock` fault injection in 15-09 (recorded in 15-09-SUMMARY.md's "rfkill fault injection" section) — **the fault injection itself was real, but recovery came from a CLI `rfkill unblock` issued from OUTSIDE the panel, with the panel only OBSERVED re-rendering afterwards; the Enable button itself was never pressed in any verification** (`15-09-SUMMARY.md:297` is the cited source and records exactly this). *Correction applied by gap-closure plan 15-12 (G-15-2): the previous wording here claimed the Enable button "was pressed and observed to actually re-enable the radio", which its own cited source contradicts. UAT was the first time a human pressed that button, and it did nothing — which is the defect G-15-2 diagnosed and closed.* The device-list half (pair/connect/disconnect/forget) was **never exercised**: this host has zero paired devices and zero discoverable peers (confirmed via an 8-second live scan) and no synthetic pointer tool. See `behavior_unverified_items`. |
| 4 | Each of the three panels carries an Advanced button that launches pavucontrol / nm-connection-editor / blueman for anything past its deliberately limited scope. | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | All three panels declare `advancedCommand` and `advancedUnavailableReason`, routed through the one shared `PanelDialog.startDetached()` mechanism (grep-confirmed: exactly 3 call sites, no `running: true` anywhere — launches survive panel dismissal by construction). `install.sh` gained `network-manager-applet` in `PACMAN_PKGS`, hard-gated by `verify_packages()`. The audio panel's Advanced button (pavucontrol) **was live-clicked and approved** in 15-02's human render gate (Task 4 check 6, no issues). The wifi/bluetooth panels' Advanced buttons were confirmed present-and-correctly-gated via a live `which nm-connection-editor`/`which blueman-manager` probe, but **neither was actually clicked open** this phase — no synthetic pointer tool. |
| 5 | All three panels are instances of one shared dialog component, not three bespoke implementations — and existing owners are untouched: SwayOSD still owns hardware XF86Audio*/XF86MonBrightness* keys at exactly one step and one pill per press, and `busctl --user list` still shows a single `org.freedesktop.Notifications` owner. | ✓ VERIFIED | **Confirmed twice: by source and live, this session.** Source: only `PanelDialog.qml` declares `PanelWindow`/`WlrLayershell`/`HyprlandFocusGrab`; `AudioPanel.qml`/`WifiPanel.qml`/`BluetoothPanel.qml` contain none of the three (grep-confirmed, zero hits in all three). Live, run directly by this verification (not sourced from SUMMARY): `bash hypr/.config/hypr/scripts/quickshell-doctor` → **18 passed, 0 failed**, including `panel-namespace-conformance` (summons all three panels live, confirms exactly one `quickshell-*-panel` layer mounted at a time, `source[bad=0]`), `single org.freedesktop.Notifications owner, and it is swaync (count: 1, owner: swaync)`, `single handler per hardware key: all 10 XF86Audio*/XF86MonBrightness* keys have exactly one registered handler`, and `panel-swayosd-key-ownership` differential proof (`table-byte-identical=yes`, `osd-differential(pipewire-write=0,hw-key=1)`). `bash hypr/.config/hypr/scripts/quickshell-doctor --self-test` → **17 passed, 0 failed** (all ten poisoned fixtures, incl. `poisoned-two-panel-layers.json` and `poisoned-two-owner-busctl-list.txt`, correctly flip red first). `busctl --user list` re-checked independently by this verification: exactly one `org.freedesktop.Notifications` owner (`swaync`, PID 994). |

**Score:** 2/5 truths verified (3 present + wired, behavior-unverified due to a documented host tooling/hardware gap, not a code defect)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `quickshell/.../PanelDialog.qml` (369 lines) | Shared panel frame | ✓ VERIFIED | `PanelWindow`/`WlrLayershell`/`HyprlandFocusGrab`/Esc/scrollable body/Advanced slot all present; sole owner of layer posture |
| `quickshell/.../AudioPanel.qml` (896 lines) | Audio panel body | ✓ VERIFIED | Per-stream rows, pinned control block, `PanelDialog` instance |
| `quickshell/.../AudioBackend.qml` (334 lines) | PipeWire adapter | ✓ VERIFIED | Native `Pipewire.*` reads/writes, `PwObjectTracker`, no subprocess |
| `quickshell/.../WifiPanel.qml` (1007 lines) | Wifi panel body | ✓ VERIFIED | Present/wired; behavior unverified (see truths table) |
| `quickshell/.../WifiBackend.qml` (354 lines) | NetworkManager adapter | ✓ VERIFIED | `connectWithPsk`, `scannerEnabled`↔`panelOpen`, locked fail-reason map |
| `quickshell/.../BluetoothPanel.qml` (859 lines) | Bluetooth panel body | ✓ VERIFIED | Present/wired; behavior unverified (see truths table) |
| `quickshell/.../BluetoothBackend.qml` (384 lines) | BlueZ adapter | ✓ VERIFIED | Address-keyed rows, watchdog timer, opt-in discovery bound to `panelOpen` |
| `quickshell/.../dashboard/qmldir` (77 lines) | Type registrations | ✓ VERIFIED | All 7 new/extended types registered as non-singleton entries |
| `quickshell/.../QuickToggles.qml` (1029 lines) | Six-tile grid + chevrons | ✓ VERIFIED | `panelRequested` signal, `openPanel()` hoist, three backend-driven tiles |
| `quickshell/.../shell.qml` (399 lines) | Guarded summon path + IpcHandler | ✓ VERIFIED | Single `openPanel(name)` with `fullscreenBlocking` guard; `IpcHandler` target `panel` (`open`/`toggle`) |
| `quickshell/.../shortcuts.json` (26 lines) | 4th manifest entry | ✓ VERIFIED | `audio-panel` entry present, SUPER+A |
| `hypr/.../keybinds.lua` | SUPER+A bind | ✓ VERIFIED | `hl.bind(mainMod .. " + A", hl.dsp.global("quickshell:audio-panel"))` |
| `hypr/.../windowrules.lua` | Per-namespace layer rules | ✓ VERIFIED | `quickshell-audio-panel`/`-wifi-panel`/`-bluetooth-panel` all present |
| `waybar/.../modules.jsonc` | Canonical network/audio clicks | ✓ VERIFIED | `network.on-click` and `pulseaudio.on-click-right` both route through `qs ipc call panel toggle <name>` |
| `waybar/.../config-athena.jsonc` | Athena rewiring | ✓ VERIFIED | wifi left-click, bluetooth left-click (right-click radio toggle preserved byte-identical), audio right-click; applet-killer right-click removed outright |
| `waybar/.../config-floating.jsonc`, `config-vertical.jsonc` | Floating/vertical rewiring | ✓ VERIFIED | Same `qs ipc call panel toggle` pattern present |
| `install.sh` | `network-manager-applet` package | ✓ VERIFIED | Present in `PACMAN_PKGS`, covered by `verify_packages()`'s hard-fail |
| `hypr/.../scripts/quickshell-doctor` (1297 lines) | 4 new checks + self-test | ✓ VERIFIED | Ran live by this verification: 18/18 real checks pass, 17/17 self-test fixtures pass |
| 5 `poisoned-*` fixtures under `tests/quickshell-fixtures/` | Proof-of-failure fixtures | ✓ VERIFIED | All 5 named in must-haves present, plus 11 additional compliant/poisoned fixtures beyond the minimum set — all replayed successfully by `--self-test` |

### Key Link Verification

| From | To | Via | Status |
|------|-----|-----|--------|
| `hypr/config/keybinds.lua` | `shell.qml` | `quickshell:audio-panel` GlobalShortcut match | ✓ WIRED |
| `shell.qml` | `AudioPanel.qml`/`WifiPanel.qml`/`BluetoothPanel.qml` | `openPanel(name)` → `<x>PanelLoader.active` | ✓ WIRED |
| `AudioPanel.qml`/`WifiPanel.qml`/`BluetoothPanel.qml` | `AudioBackend`/`WifiBackend`/`BluetoothBackend` | `backend:` injected from shell root | ✓ WIRED |
| `AudioBackend.qml` | `Quickshell.Services.Pipewire` | `Pipewire.defaultAudioSink` + `PwObjectTracker`, no subprocess | ✓ WIRED |
| `WifiBackend.qml` | `Quickshell.Networking` | `connectWithPsk`, `scannerEnabled` driven off `panelOpen` | ✓ WIRED |
| `BluetoothBackend.qml` | `Quickshell.Bluetooth` | `adapter.discovering`, null-guarded default-adapter seam | ✓ WIRED |
| `QuickToggles.qml` → `DashboardTab.qml` → `Dashboard.qml` → `shell.qml` | relay chain | `panelRequested(name)` re-emitted unchanged at each hop, becomes a summon only in `shell.qml`'s `onPanelRequested: (name) => root.openPanel(name)` | ✓ WIRED (live-confirmed: no intermediate hop reads the fullscreen guard or touches a loader) |
| `waybar/*.jsonc` | `shell.qml` | fixed literal `qs ipc call panel toggle <name>` invoking `IpcHandler{ target: "panel" }` | ✓ WIRED |
| `install.sh` | `WifiPanel.qml`'s Advanced target | `network-manager-applet` package entry resolvable on a fresh install | ✓ WIRED |
| `hypr/.../quickshell-doctor` | `shell.qml` | 4 new checks summon/dismiss through the same `IpcHandler` verbs the bar and chevrons call | ✓ WIRED (live-run confirms exact panel counts during/after each summon) |

### Behavioral Spot-Checks / Probe Execution

This phase's own declared verification mechanism is `quickshell-doctor` (a live-observation gate) plus its `--self-test` fixture-replay mode, rather than a `scripts/*/tests/probe-*.sh` convention. Both were run directly by this verification, not sourced from SUMMARY claims.

| Check | Command | Result | Status |
|-------|---------|--------|--------|
| Fixture replay proves each new check can fail before it's trusted to pass | `bash hypr/.config/hypr/scripts/quickshell-doctor --self-test` | `Self-test summary: 17 passed, 0 failed` (all 10 poisoned shapes correctly flip red) | ✓ PASS |
| Full live gate sweep | `bash hypr/.config/hypr/scripts/quickshell-doctor` | `Summary: 18 passed, 0 failed` (2 expected SKIPs: no backlight device, single-monitor headless-fanout limitation) | ✓ PASS |
| Single Notifications owner (independent re-check, not from the doctor script) | `busctl --user list \| grep -i notifications` | Exactly one row: `org.freedesktop.Notifications ... swaync` | ✓ PASS |
| SwayOSD server reachable (the condition 15-09 found broken and fixed) | `pgrep -fa swayosd` | `swayosd-server` present alongside `swayosd-libinput-backend` | ✓ PASS |
| No leftover panel layer after this verification's live gate run | `hyprctl layers -j` filtered for `quickshell-*` namespaces | none found | ✓ PASS (desktop left clean, per instructions) |
| rfkill state unperturbed by this verification | `rfkill list` | wifi soft/hard unblocked; bluetooth soft-blocked (pre-existing host state, confirmed unrelated to any mutation performed by this verification — `quickshell-doctor`'s default run never touches rfkill; only its Task 2 fault-injection path does, which was not invoked here) | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
|-------------|-----------------|--------------|--------|----------|
| PANEL-01 | 15-01, 15-04, 15-07, 15-09 | Per-app volume mixer, per-app slider, click-to-mute | ✓ SATISFIED | `AudioPanel.qml` per-stream rows, node-id keyed, human render-gate approved |
| PANEL-02 | 15-01, 15-02, 15-04, 15-09 | Default output/input device selection + master volume | ✓ SATISFIED | `AudioBackend.qml` native preferred-default writes, human render-gate approved |
| PANEL-03 | 15-01, 15-03, 15-05, 15-07, 15-08, 15-09 | Wifi scan/list/connect/password prompt | ? NEEDS HUMAN | Source/wiring complete; connect/password behavior unexercised (host limitation) |
| PANEL-04 | 15-01, 15-03, 15-06, 15-07, 15-08, 15-09 | Bluetooth toggle/list/connect/disconnect/forget | ? NEEDS HUMAN | Source/wiring complete, adapter-toggle proven live via rfkill; device transitions unexercised (no hardware) |
| PANEL-05 | 15-02, 15-03, 15-08 | Advanced button per panel | ? NEEDS HUMAN | Audio's Advanced live-verified; wifi/bluetooth Advanced present + gated but not clicked |
| PANEL-06 | 15-02, 15-03, 15-09 | One shared dialog component | ✓ SATISFIED | Live-confirmed this session via source inspection + `quickshell-doctor` mechanical proof |

No orphaned requirements — REQUIREMENTS.md's PANEL-01..06 all appear in at least one plan's `requirements:` field, and every plan's declared requirements trace to REQUIREMENTS.md text.

### Anti-Patterns Found

None. Scanned all 9 primary QML/script artifacts plus 4 waybar configs and `install.sh` for `TBD`/`FIXME`/`XXX`/`TODO`/`HACK` debt markers and empty-implementation patterns (`return null`, hardcoded empty props, console.log-only handlers). All "placeholder" string hits are legitimate named empty-state UI components (`emptyStatePlaceholder`, `nothingPlayingPlaceholder`, `panelUnreachablePlaceholder`), not stub markers. The single "xxx" hit in `keybinds.lua` is a comment illustrating an API-shape naming convention (`hl.dsp.xxx(...)`), not a debt marker.

### Human Verification Required

See `behavior_unverified_items` in frontmatter for full test/expected/why-human detail. Summarized:

1. **Wifi panel click-driven flow** — connect to a real network, type a password on a secured one, confirm the row-scoped failure copy on a wrong password, confirm two-stage Escape, confirm Cancel actually aborts an in-flight attempt, confirm Forget's inline confirm. Estimated a few minutes with real hands on a real network.
2. **Bluetooth panel device transitions** — pair, connect, disconnect and forget a real discoverable peer (phone/headset). Requires hardware this host does not have; the adapter on/off half is already proven live via `rfkill` fault injection.
3. **Wifi and bluetooth Advanced buttons** — click both and confirm nm-connection-editor and blueman-manager actually open, detached from the panel's own lifecycle. The audio panel's Advanced button (pavucontrol) is already live-verified.

Additionally, per this task's explicit context: the human's individual render gates for plans 15-05 through 15-08 were deliberately batched into one consolidated review at the human's own request (see "## Batched human review — Phase 15" in `15-09-SUMMARY.md`) — this is a pending sign-off, not a missing gate. Plans 15-02, 15-03 and 15-04 each already passed their own individual human render gate live, with real issues found and fixed (15-04's focal-point hierarchy, commit `80039ca`).

### Gaps Summary

No gaps found. Every artifact required by the phase's plans exists, is substantive, and is wired end to end — confirmed both by source inspection and by live execution of the phase's own verification mechanism (`quickshell-doctor` plus `--self-test`), run directly by this verification rather than taken from SUMMARY claims. ROADMAP criterion 5 (one shared dialog component; SwayOSD and swaync ownership untouched) is fully machine-verified live, this session, with zero deviation. The three panels' click-driven end-user interactions (wifi connect/password, bluetooth pair/connect/forget, two of three Advanced-button launches) are the only items not behaviorally proven — a documented, honestly-recorded host limitation (no synthetic pointer-input tool; no bluetooth hardware in range) rather than a code or wiring defect. Known pre-existing, non-phase-15 conditions (QS-03 headless hotplug limitation, `waybar-equivalence-check`'s orphaned baseline, `hypr-equivalence-check`'s expected `binds.json` divergence from the new Super+A bind) were confirmed to be exactly that — pre-existing and correctly reported, not silently absorbed — and do not affect this phase's status.

---

_Verified: 2026-08-02T03:22:17Z_
_Verifier: Claude (gsd-verifier)_
