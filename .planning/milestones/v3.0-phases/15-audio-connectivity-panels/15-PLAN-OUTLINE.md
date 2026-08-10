# Phase 15 — Audio + Connectivity Panels · Plan Outline

**Generated:** 2026-08-01 · **Mode:** chunked / outline-only · **Granularity:** coarse
**Tracer-first:** ON · **Reversibility gates:** ON · **MVP mode:** OFF · **Security enforcement:** ON (ASVS L1, blocking threshold `high`)

**Plans:** 9 · **Waves:** 5

| Plan ID | Objective | Wave | Depends On | Requirements |
|---------|-----------|------|------------|--------------|
| 15-01 | Live API probe: resolve `UntypedObjectModel` accessor shape, PipeWire node property keys, `request*`-vs-plain method path, and `preferredDefaultAudioSink` write semantics against the running build; study end-4/Caelestia source for component-level patterns. Emits `15-API-PROBE.md`. No production files. | 1 | none | PANEL-01, PANEL-02, PANEL-03, PANEL-04 |
| 15-02 | **TRACER** — `Super+A` → shell-root `openPanel()` (DASH-08 fullscreen guard) → `PanelDialog` shared frame → `AudioPanel` master volume + mute wired to PipeWire → `Advanced` launches pavucontrol detached → Esc/click-outside dismisses. One path, every layer, production-quality. | 2 | 15-01 | PANEL-02, PANEL-05, PANEL-06 |
| 15-03 | Mount the wifi and bluetooth panels as `PanelDialog` instances with their real Advanced targets, the D-15-26 off/empty/no-hardware states, and the shell-root `IpcHandler` all remaining entry points call. Three namespaces complete. | 3 | 15-02 | PANEL-03, PANEL-04, PANEL-05, PANEL-06 |
| 15-04 | Audio panel build-out: pinned control block (output + input device pickers as inline expanding rows, input level slider, mic mute) over the scrolling per-app mixer list; four widget states; render gate. | 4 | 15-03 | PANEL-01, PANEL-02 |
| 15-05 | Wifi panel build-out: scan + progress line, grouped stable ordering, inline password row with `connectWithPsk`, `ConnectionFailReason` copy mapping, Forget with inline confirm, two-stage Esc; render gate. | 4 | 15-03 | PANEL-03 |
| 15-06 | Bluetooth panel build-out: adapter toggle, grouped list, contextual-verb rows, chevron expansion (battery / address / separated Forget), pairing spinner with a real Cancel, inferred-failure recipe, opt-in discovery; render gate. | 4 | 15-03 | PANEL-04 |
| 15-07 | Quick-toggle grid becomes one row of six compact split tiles; Volume / Wi-Fi / Bluetooth tiles perform their verb on body press and open their panel on chevron press; render gate carries the "Do Not Disturb" two-line legibility hard constraint. | 4 | 15-03 | PANEL-01, PANEL-03, PANEL-04 |
| 15-08 | waybar click rewiring across all four configs (`network` left → wifi, `bluetooth` left → bluetooth, `group/audio` right → audio), `install.sh` gains `network-manager-applet`, `waybar-equivalence-check` + `waybar-design-lint` re-run. | 4 | 15-03 | PANEL-03, PANEL-04, PANEL-05 |
| 15-09 | Criterion-5 proof: extend `quickshell-doctor` with the four D-15-25 checks plus a poisoned fixture and `rfkill` fault injection; `keybind-doctor` re-run; full gate sweep; phase-close render gate. | 5 | 15-04, 15-05, 15-06, 15-07, 15-08 | PANEL-01, PANEL-02, PANEL-03, PANEL-04, PANEL-05, PANEL-06 |

---

## Multi-Source Coverage Audit

| SOURCE | ID | Item | Plan | Status |
|---|---|---|---|---|
| GOAL | — | Per-app volume, wifi and bluetooth handled by themed in-shell panels displacing pavucontrol / nm-connection-editor / blueman from the daily workflow without pretending to replace them | 15-02..15-08 | COVERED |
| REQ | PANEL-01 | Per-app mixer, per-app slider + click-to-mute | 15-01, 15-04 | COVERED |
| REQ | PANEL-02 | Default output + input device selection, master volume | 15-01, 15-02, 15-04 | COVERED |
| REQ | PANEL-03 | Wifi scan, list, connect, password prompt | 15-01, 15-03, 15-05, 15-07, 15-08 | COVERED |
| REQ | PANEL-04 | Bluetooth adapter toggle, list, connect/disconnect/forget | 15-01, 15-03, 15-06, 15-07, 15-08 | COVERED |
| REQ | PANEL-05 | Advanced button on each panel | 15-02, 15-03, 15-08 | COVERED |
| REQ | PANEL-06 | One shared dialog component | 15-02, 15-03, 15-09 | COVERED |
| CONTEXT | D-15-01 | Three split quick-toggle tiles, chevron opens panel | 15-07 | COVERED |
| CONTEXT | D-15-02 | Independent layer surface per panel, own `HyprlandFocusGrab` | 15-02, 15-03 | COVERED |
| CONTEXT | D-15-03 | Top-center anchor at drawer width, D-03 verbatim | 15-02 | COVERED |
| CONTEXT | D-15-04 | `Super+A` audio only; documented asymmetry sentence | 15-02 | COVERED |
| CONTEXT | D-15-05 | waybar manager-click rewiring | 15-08 | COVERED |
| CONTEXT | D-15-06 | Header band, labeled Advanced, no close button | 15-02 | COVERED |
| CONTEXT | D-15-07 | One fixed height + scrollable body; D-05 exemption widened and recorded | 15-02 | COVERED |
| CONTEXT | D-15-08 | Cascade the frame, render the list whole; reuses D-21 stagger token | 15-02 (frame), 15-04/05/06 (list-whole) | COVERED |
| CONTEXT | D-15-09 | Fourth widget state `failed`, row-scoped | 15-02 (vocabulary), 15-04/05/06 (use) | COVERED |
| CONTEXT | D-15-10 | Pinned control block over scrolling app list | 15-04 | COVERED |
| CONTEXT | D-15-11 | Full input symmetry + pre-agreed declutter fallback | 15-04 | COVERED |
| CONTEXT | D-15-12 | Device pickers = inline expanding rows, `Popup` banned | 15-04 | COVERED |
| CONTEXT | D-15-13 | Per-app row = icon-as-mute + name + slider, muted carried twice | 15-04 | COVERED |
| CONTEXT | D-15-14 | Inline password row, two-stage Esc, `connectWithPsk` | 15-05 | COVERED |
| CONTEXT | D-15-15 | Scan while open, indeterminate progress line, refresh control | 15-05 | COVERED |
| CONTEXT | D-15-16 | Grouped stable ordering; signal strength never sorts | 15-05 | COVERED |
| CONTEXT | D-15-17 | Actions + wifi `forget`, destructive separation | 15-05 | COVERED |
| CONTEXT | D-15-18 | Paired-first, opt-in discovery, recorded asymmetry | 15-06 | COVERED |
| CONTEXT | D-15-19 | Contextual-verb row, chevron expand, real Cancel → `cancelPair` | 15-06 | COVERED |
| CONTEXT | D-15-20 | Dismiss always returns to desktop, never the drawer | 15-02 (frame), 15-07 (tile path) | COVERED |
| CONTEXT | D-15-21 | One row of six compact tiles; "Do Not Disturb" never "DND" | 15-07 | COVERED |
| CONTEXT | D-15-22 | Absent Advanced target renders disabled with the reason | 15-02 (mechanism), 15-03 (wifi/bt instances) | COVERED |
| CONTEXT | D-15-23 | `install.sh` gains `network-manager-applet` | 15-08 | COVERED |
| CONTEXT | D-15-24 | Panel volume writes fire no SwayOSD pill | 15-02 (established), 15-09 (proven) | COVERED |
| CONTEXT | D-15-25 | `quickshell-doctor` extension + poisoned fixture | 15-09 | COVERED |
| CONTEXT | D-15-26 | Off/empty/degraded distinguish fixable from unfixable | 15-03 (wifi/bt), 15-04 (audio), 15-09 (rfkill injection) | COVERED |
| RESEARCH | Pattern 1 | Shared `PanelDialog` wraps Dashboard's proven surface skeleton | 15-02 | COVERED |
| RESEARCH | Pattern 2 | Backend-adapter components mirror `MediaBackend` shape | 15-02, 15-03 | COVERED |
| RESEARCH | Pattern 3 | `startDetached()` for every Advanced button | 15-02, 15-03 | COVERED |
| RESEARCH | Pattern 4 | Truth-driven pending model extended with `failed` | 15-02, 15-04/05/06 | COVERED |
| RESEARCH | Pitfall 1 | Networking class hierarchy is not flat | 15-01, 15-05 | COVERED |
| RESEARCH | Pitfall 2 | Bluetooth failure inference recipe (no native signal) | 15-06 | COVERED |
| RESEARCH | Pitfall 3 / A2 | `preferredDefaultAudioSink` write semantics unverified | 15-01 (probe + decision checkpoint), 15-04 | COVERED |
| RESEARCH | Pitfall 4 / A3 | `UntypedObjectModel` accessor shape unverified — blocks all three panels | 15-01 | COVERED |
| RESEARCH | Pitfall 5 / A1 | PipeWire node `properties` key names assumed | 15-01, 15-04 | COVERED |
| RESEARCH | A4 | `request*` signals vs plain invokable methods | 15-01 | COVERED |
| RESEARCH | A5 | end-4 / Caelestia source-check not performed this session | 15-01 | COVERED |
| RESEARCH | Open Q1 | Live scan cadence, `cancelPair` mid-pairing, `peaks` cost | 15-01 (cadence), 15-05, 15-06 | COVERED |
| RESEARCH | Open Q2 | QtQuick `Popup` viability inside a layer-shell surface | 15-01 (record-only; never consumed this phase) | COVERED |
| RESEARCH | Open Q3 | Six-across tile legibility | 15-07 render gate | COVERED |
| RESEARCH | Pkg audit | `network-manager-applet` — pacman `extra`, verdict OK | 15-08 | COVERED |
| RESEARCH | State of art | `nmtui-launch.sh` confirmed non-overlapping, stays untouched | 15-08 (one-line note) | COVERED |
| RESEARCH | Security | PSK never on a command line; fixed-argv Advanced launches | 15-05, 15-02/15-03 | COVERED |
| UI-SPEC | 32 covered | UI-consideration `covered` rows → `must_haves.truths` | see per-plan ownership below | COVERED |
| UI-SPEC | 8 backstop | UI-consideration `backstop` rows → flat-scalar markers | see per-plan ownership below | COVERED |

**No `⚠ MISSING` rows.** Excluded as not-gaps: all eight CONTEXT `## Deferred Ideas` entries, and the 14 UI-SPEC considerations marked `✋ dismissed` (dismissed at the probe's propose-then-confirm step with a recorded reason — a confirmed dismissal, not the edge probe's forbidden auto-dismissal). QS-03 per-screen fan-out is a recorded permanent platform limitation, not phase scope.

---

## `<assumption_delta_decision>` (carry into 15-09's PLAN.md; secondary note into 15-02's)

The detector fired `kind: pluralization` on the ROADMAP's *Owns* clause: "three new PipeWire / NetworkManager / BlueZ consumers arriving at once **alongside** existing owners."

- **Primary noun (generalized identity): `service participant`.** The current identity model in `quickshell-doctor` knows one noun — **owner** — and asserts cardinality 1 on it (the `org.freedesktop.Notifications` single-owner check, the SwayOSD XF86 key-ownership check). This phase introduces three participants that are emphatically *not* owners: they are unbounded **clients** of PipeWire, NetworkManager and BlueZ. D-15-24's own reasoning already draws this line ("the panels are additional consumers, not ownership claimants") but no instrument encodes it.
- **Decision: `promote`.** Generalize the doctor's D-Bus model to name `service participant` as primary, with two variants demoted to details: `name-owner` (cardinality exactly 1, asserted, poison-provable) and `client-consumer` (cardinality N, never asserted exclusive). Rationale: without the promotion, D-15-25's new checks would be written against the only noun that exists — `owner` — and would either accidentally assert exclusivity over three many-client services, or would be bolted on as unnamed one-off greps that the next phase cannot reuse. **Owner: 15-09.**
- **Secondary observation (`add-alongside`, accepted debt).** The QML shell's surface identity is also pluralizing: `Dashboard.qml` was the only summonable layer surface, and this phase adds three more. The generalized noun is `summonable layer surface` and `PanelDialog` is its promoted representation — but only for **new** surfaces. `Dashboard.qml` is deliberately **not** refolded onto `PanelDialog` this phase: it is Phase-14 render-gate-passed with an open UAT item, the milestone's additive-only constraint 4 forbids the churn, and D-15-02 already rejected drawer restructuring for exactly this reason. Accepted debt. **What would force a later promote:** any change that must land identically on all four surfaces (a shared dismissal-semantics change, a focus-grab model change, or a second surface wanting the drawer's tab chrome). **Owner of the record: 15-02.**

---

## Artifacts this phase produces (canonical names — per-plan runs MUST NOT drift)

**New QML types** (all non-singleton, all registered in `quickshell/.config/quickshell/modules/dashboard/qmldir` in the same commit that creates them):

| Type | File | Created by |
|---|---|---|
| `PanelDialog` | `quickshell/.config/quickshell/modules/dashboard/PanelDialog.qml` | 15-02 |
| `AudioPanel` | `.../dashboard/AudioPanel.qml` | 15-02 |
| `AudioBackend` | `.../dashboard/AudioBackend.qml` | 15-02 |
| `WifiPanel` | `.../dashboard/WifiPanel.qml` | 15-03 |
| `WifiBackend` | `.../dashboard/WifiBackend.qml` | 15-03 |
| `BluetoothPanel` | `.../dashboard/BluetoothPanel.qml` | 15-03 |
| `BluetoothBackend` | `.../dashboard/BluetoothBackend.qml` | 15-03 |

**`PanelDialog` public surface** (the contract all three panels and Phase 16 inherit — 15-02 defines it, later plans consume it and MUST NOT rename):
`signal dismissRequested()` · `property string panelTitle` · `property string panelGlyph` · `property string namespaceSuffix` (→ `WlrLayershell.namespace: "quickshell-" + namespaceSuffix`) · `property string advancedLabel` (default `"Advanced"`) · `property var advancedCommand` (fixed argv array) · `property bool advancedAvailable` · `property string advancedUnavailableReason` · `default property alias body` (scrollable content slot) · `readonly property int panelWidth` / `panelHeight` · `readonly property var panelStates: ["populated","pending","empty","failed"]` · `function stateColour(state)` · `function requestDismiss()`

**`shell.qml` root artifacts** (15-02 creates the first three sets, 15-03 completes them):
`audioPanelLoader` / `wifiPanelLoader` / `bluetoothPanelLoader` · `audioBackendInstance` / `wifiBackendInstance` / `bluetoothBackendInstance` · `audioPanelShortcut` (`GlobalShortcut` name `audio-panel`) · **`function openPanel(name)`** and **`function closeAllPanels()`** — the single guarded summon path (see DASH-08 note below) · `IpcHandler { target: "panel" }` exposing `open(name)` and `toggle(name)` (15-03).

**Backend public surfaces:**
- `AudioBackend` — `panelOpen`, `pipewireReady`, `defaultSink`, `defaultSource`, `sinks`, `sources`, `streams`, `masterVolume`, `masterMuted`, `inputVolume`, `inputMuted`, `function setDefaultSink(node)`, `setDefaultSource(node)`, `streamLabel(node)`
- `WifiBackend` — `panelOpen`, `wifiDevice`, `wifiEnabled`, `wifiHardwareEnabled`, `scanning`, `currentNetwork`, `savedNetworks`, `otherNetworks`, `function connect(network, psk)`, `disconnect(network)`, `forget(network)`, `signal connectFailed(network, reasonText)`
- `BluetoothBackend` — `panelOpen`, `adapter`, `adapterPresent`, `adapterEnabled`, `discovering`, `connectedDevices`, `pairedDevices`, `discoveredDevices`, `function setAdapterEnabled(on)`, `startDiscovery()`, `stopDiscovery()`, `pair(device)`, `cancelPair(device)`, `connect(device)`, `disconnect(device)`, `forget(device)`, `signal deviceActionFailed(device, reasonText)`

**Config keys / keybinds / namespaces:**
- `shortcuts.json` fourth entry: `{ "appid": "quickshell", "name": "audio-panel", "chord": { "mods": "SUPER", "key": "A" } }`
- `hypr/.config/hypr/config/keybinds.lua`: one `SUPER + A` bind (Lua `' + '` multi-modifier joining convention)
- Layer namespaces: `quickshell-audio-panel`, `quickshell-wifi-panel`, `quickshell-bluetooth-panel`
- `hypr/.config/hypr/config/windowrules.lua`: three per-namespace `hl.layer_rule({ match = { namespace = ... }, animation = "slide" })` entries (the family-wide `^quickshell-.*` blur / `ignore_alpha` rules already cover all three — no new blur rule)
- `install.sh` `PACMAN_PKGS` += `network-manager-applet`
- `QuickToggles.qml`: `chipModel` extended to six entries (`gaming`, `dnd`, `dark`, `volume`, `wifi`, `bluetooth`); new `signal panelRequested(string name)`; new `function openPanel(name)`, `pressVolume()`, `pressWifi()`, `pressBluetooth()`
- `quickshell-doctor` new check names: `panel-namespace-conformance`, `panel-shortcut-single-registration`, `panel-notifications-single-owner`, `panel-swayosd-key-ownership`
- New planning artifact: `15-API-PROBE.md`

**No new stow package** — every file lands inside the already-registered `quickshell/`, `hypr/`, `waybar/` packages, so standing constraint 3 has nothing to register. Per-plan runs must not invent a `stow.sh` edit.

---

## Flagged assumptions (surfaced, never silently dropped)

1. **PANEL-02's edge-coverage row is `unclassified` → stays `unresolved`.** The deterministic probe could not classify PANEL-02, and the protocol forbids auto-`backstop`ping an `unclassified` row. The honest open edge in this phase's own domain is **whether writing `preferredDefaultAudioSink` re-routes already-playing streams or only new ones** (RESEARCH A2 / Pitfall 3) — PANEL-02's text ("selects the default output device") implies the audible result. 15-01 measures it; 15-01's `checkpoint:decision` disposes it. **Must appear verbatim as an `unresolved` flagged assumption in 15-04's PLAN.md**, not converted to a truth on the way through.
2. **`15-PATTERNS.md` contradicts DASH-08 and must not be followed on this point.** PATTERNS.md line ~199 says the panels' `GlobalShortcut` copies the dashboard block "minus the fullscreen-refusal guard, which does not apply to panels." That is wrong: REQUIREMENTS DASH-08 reads "Dashboard **and panels** refuse to open over a fullscreen client", and ROADMAP Phase 14 criterion 5 reads "neither the dashboard nor any panel opens over a fullscreen client." **Resolution, binding on every plan:** 15-02 puts the DASH-08 guard inside the single shell-root `function openPanel(name)`, and *every* summon path — `Super+A`, the tile chevron (15-07), the waybar IPC call (15-08) — routes through it. The guard exists exactly once. 14-01's live finding applies unchanged: it blocks both maximize and true fullscreen, because Hyprland 0.56.1 exposes no IPC signal distinguishing them.
3. **CONTEXT.md's decision block is headed "21 decisions" but enumerates 26 IDs (D-15-01 … D-15-26).** The audit above covers all 26. No decision was dropped on the count discrepancy.

---

## Per-plan notes

### 15-01 — Live API probe + reference-shell source study · Wave 1

- **Not the tracer.** A discovery plan precedes it, matching this repo's own precedent (11-01's viability gate, 13.1-01's baseline capture, 14-02's font gate). RESEARCH A3 (`UntypedObjectModel` accessor shape) blocks *all three* panels simultaneously, so it is the very first check.
- Files: `.planning/phases/15-audio-connectivity-panels/15-API-PROBE.md` only. Probe harnesses are throwaway (14-02's `grabToImage` precedent — a throwaway harness, deleted after; do **not** touch `modules/Probe.qml`, which 12-06 owns as the token inspector).
- Tasks: (1) model accessor shape + PipeWire node `properties` key dump for a real playing stream + `request*`-vs-plain-method call path (A1/A3/A4); (2) `preferredDefaultAudioSink`/`Source` live write semantics against a second real output device with audio playing (A2), plus `scannerEnabled` cadence; (3) shallow-clone read of end-4/dots-hyprland + Caelestia current QML for the quick-settings tile grid, wifi/bluetooth panel layouts and empty/off states, per-app volume row shape, and their full-app link treatment (A5) — study real source, not screenshots, per 14-05's established discipline.
- **`checkpoint:decision` (blocking) at the end of task 2**, disposing the A2 finding. Frame it with deep pros/cons **and a named recommendation** (the user's standing instruction) across: (a) accept and document the scope limitation "switches default for new streams; playing streams keep their route", (b) add an explicit per-stream re-route step via `PwNodeLinkTracker`/`PwLinkGroup`. Rate `<reversibility rating="costly">` — it changes PANEL-02's delivered behaviour and `AudioBackend`'s public surface.
- Also record (never consume) the QtQuick `Popup`-inside-layer-shell viability answer — CONTEXT deferred item 2. If it fails, the avoidance becomes a documented family rule; if it works, a future surface gains an option. `Popup` stays banned this phase regardless (D-15-12, D-15-19).
- **Requirement citation for the frontmatter:** this plan de-risks PANEL-01..04; cite them.
- Threat rows: none new beyond the phase register; carry `T-15-05` (accept).

### 15-02 — **TRACER** · Wave 2

- **This is the phase's `type="tracer"` task-leading plan.** One path through every layer, production-quality, committed: `Super+A` → `shell.qml` `openPanel("audio")` (DASH-08 guard) → `audioPanelLoader` → `PanelDialog` (header band, title, labeled Advanced, fixed geometry, `HyprlandFocusGrab`, cascade entrance) → `AudioPanel` rendering **master volume + mute only** → `AudioBackend` reading `Pipewire.defaultAudioSink` → Advanced `startDetached(["pavucontrol"])` → Esc / click-outside dismisses to the desktop.
- Stubs are permitted only where later-fillable without an architectural change: the panel body's scrollable slot is real and empty; the four-state vocabulary is defined and only `populated`/`empty` are exercised. The device pickers and app list are **absent, not faked**.
- Files: `PanelDialog.qml`, `AudioPanel.qml`, `AudioBackend.qml`, `shell.qml`, `modules/dashboard/qmldir`, `shortcuts.json`, `keybinds.lua`, `windowrules.lua`. Expect 4 tasks including the gate; split only if the estimate exceeds `workflow.smart_zone_tokens`.
- `autonomous: false` — carries a `checkpoint:human-verify` blocking render gate (standing constraint 1).
- **Reversibility flags (no checkpoint — both already decided by the human at discuss time, per the anti-pattern "gating a decision already made"):**
  - `<reversibility rating="costly">` on the `PanelDialog`/`HyprlandFocusGrab` standalone-surface lifecycle (D-15-02) — the lifecycle threads through the namespace scheme, the doctor checks, the waybar rewiring and Phase 16's inheritance.
  - `<reversibility rating="costly">` on the fourth widget state (D-15-09) — it enters the QML family's shared vocabulary; removing it later re-opens every widget that renders it.
- Must document, in-plan and in the SUMMARY: D-15-04's one-sentence keybind-asymmetry rationale, and D-15-07's D-05 scroll-exemption widening with its reason (all three panels have unbounded content, unlike the drawer's four audited-bounded tabs).
- **Preconditions:** `quickshell` 0.3.0-2 still installed (re-verify the qmltypes if it moved past 0.3.0-2 — RESEARCH's own validity clause); `15-API-PROBE.md` exists with the A3 accessor verdict.
- **Phase 11 Finding 1:** `GlobalShortcut` registration does **not** hot-reload — `Super+A` needs a Quickshell process restart. **14-06's standing executor rule applies:** every verification restart must be detached — `setsid uwsm app -- ~/.config/hypr/scripts/quickshell-launch.sh` — a shell-child restart dies with the executor session and silently breaks `Super+D`.
- **Owns these `must_haves` predicates:**
  - Edge coverage, PANEL-05: `adjacency` → **covered** ("the Advanced button's hit region does not touch the frame's top-right corner — at least `Design.spacingMd` of non-interactive header band separates them, so a near-miss press does nothing rather than hitting a neighbour" — closes D-15-06's own named mis-click risk); `empty` → **covered** (D-15-22 present-but-disabled with "{App name} is not installed", never hidden); `ordering` → **covered** (exactly one Advanced button per panel, in the identical header-right slot in all three instances — order is specified and stable by construction); `concurrency` → **covered** ("a second Advanced press while the first launch is still starting does not error, does not block the panel, and does not kill the first process — `startDetached()` severs the child from the panel's destroy-on-dismiss lifecycle").
  - UI-SPEC: E7 `error` (covered) and E8's two `dismissed` rows are chrome owned here (dismissed rows are not lifted).
  - **Prohibition P1 (descriptor-less, `must_haves.prohibitions:`):** *No panel may reach a CLI wrapper (`nmcli` / `bluetoothctl` / `wpctl` / `pactl`) for any read or write that a native `Quickshell.Networking` / `Quickshell.Bluetooth` / `Quickshell.Services.Pipewire` member already exposes.* Restated by 15-05 and 15-06.
  - The `add-alongside` half of the assumption-delta record.
- Threat rows: `T-15-02` (Tampering, Advanced-button argv, medium, mitigate — fixed literal argv arrays, zero interpolated elements, T-14-13 discipline).

### 15-03 — Wifi + bluetooth mounts, off-states, IPC · Wave 3

- Delivers a real capability delta: both panels open as themed `PanelDialog` instances, show their honest off / no-hardware state, and their Advanced buttons launch `nm-connection-editor` and `blueman-manager` detached. It is not a scaffolding plan.
- Files: `WifiPanel.qml`, `WifiBackend.qml`, `BluetoothPanel.qml`, `BluetoothBackend.qml`, `shell.qml`, `modules/dashboard/qmldir`, `windowrules.lua`. **Most likely plan to need splitting** at its per-plan run — if the estimate exceeds the smart zone, split wifi-mount from bluetooth-mount and push the second to wave 3b.
- Adds the shell-root `IpcHandler { target: "panel" }` (`open(name)`, `toggle(name)`) that 15-08 consumes. Both IPC verbs route through `openPanel()` so the DASH-08 guard is not bypassed.
- Owns the D-15-26 state grammar for both connectivity panels: wifi soft-off (Enable button present) vs hardware-blocked (no button, names the physical switch); bluetooth adapter-disabled (Enable button) vs `defaultAdapter === null` (no button, states the absence plainly). Every `Bluetooth.defaultAdapter` read is null-guarded.
- `autonomous: false` — blocking render gate on both empty states.
- **Owns these `must_haves` predicates:**
  - Edge coverage, PANEL-06: `adjacency` → **covered** ("summoning panel B while panel A is open tears A down — its `HyprlandFocusGrab.onCleared` fires `dismissRequested` — so at most one `PanelDialog` is ever mounted; two panels never render simultaneously and never collide on the overlay layer"); `empty` → **covered** ("with no panel summoned all three `LazyLoader`s are inactive, `hyprctl layers -j` shows no `quickshell-*-panel` layer, and every backend's `panelOpen` is false — zero scan and zero discovery activity"); `ordering` → **covered** ("panel summon is last-writer-wins by construction: the most recently activated loader holds the sole grab, there is no queue, and re-summoning the already-open panel toggles it closed per D-10"). Mechanical proof of all three is 15-09's job.
  - **Prohibition P2 (descriptor-less):** *No panel may render an enabled-looking control whose backend cannot honour it* — D-15-26's governing principle, "never offer a control that cannot work."
- Threat rows: `T-15-02` (as 15-02), `T-15-05` (Elevation/Tampering — panel writes to NM/BlueZ as an unprivileged session-user D-Bus client, **low**, disposition **accept**: identical trust posture to nm-applet and blueman, which already do this on the same bus as the same user).

### 15-04 — Audio panel build-out · Wave 4 (parallel)

- Files: `AudioPanel.qml`, `AudioBackend.qml`. Second-most-likely split candidate (pinned block vs app list); both live in one file pair, so a split is a serial chain, not a parallel gain — prefer one plan unless the estimate demands otherwise.
- Pinned control block (D-15-10) is the panel's **declared focal point** (UI-SPEC Dimension 2). Device pickers are inline expanding rows (D-15-12) — `QtQuick.Controls.Popup` is banned; whether expansion animates the layout or overlays it is Claude's discretion, decided at the render gate.
- D-15-11 full input symmetry ships as specified (user override of the recommendation). The **pre-agreed, already-authorized fallback** — drop the input level slider, keep device selection + mic mute — may be taken at the render gate **without a new decision**.
- Carries the A2 disposition from 15-01's decision checkpoint.
- `autonomous: false` — blocking render gate.
- **Owns these `must_haves` predicates:**
  - Edge coverage, PANEL-01: `adjacency` → **covered** ("each PipeWire stream node renders its own row and rows never merge — two concurrent streams from one application produce two independently-mutable rows, because row identity is the node id, not the application name"); `empty` → **covered** (D-15-26 case 4 — "Nothing is playing" placeholder confined to the app-list region while the pinned master, device pickers and mic controls stay live and interactive; **not** a degraded panel); `ordering` → **covered** ("app-list order is PipeWire node-id ascending and never re-sorted by volume, name or activity, so changing a stream's volume can never reorder rows").
  - Edge coverage, PANEL-02: **`unresolved`** — see Flagged Assumption 1. Reproduce it verbatim as a flagged assumption; do **not** convert it to a truth.
  - UI-SPEC covered rows for E1 (`empty`, `error`, `populated`, `overflow`, `zero-one-many`, `long-text`) and E2 (`populated`, `partial`, `overflow`, `zero-one-many`, `long-text`) → plain `must_haves.truths` strings. Note E1's `error` row is **NEW locked contract**: PipeWire unreachable renders a *panel-level unfixable* empty state in D-15-26 case 2's grammar (names the cause, **no** Enable button, Advanced stays available) — deliberately **not** the case-4 treatment, because live-looking sliders that silently do nothing are the exact failure this avoids.
  - UI-SPEC **backstop** rows (flat-scalar `{ statement, verification: backstop }`): E1 `partial` (a stream reporting no application name or icon — fall back to the node's binary name and a generic Material Symbol); E2 `empty` (no output device present at all — same unfixable-empty grammar as E1's error row, not a live-but-inert slider); E2 `error` (a set-default call that does not take — D-15-09 row-scoped failed state on the picker row, never panel-wide).
- Threat rows: `T-15-02`, plus `T-15-06` (Tampering/multi-writer — two clients writing PipeWire volume near-simultaneously, **low**, disposition **accept**: PipeWire is designed for concurrent multi-client read/write and D-22's truth-driven rendering means the panel always shows actual backend state regardless of who wrote last).

### 15-05 — Wifi panel build-out · Wave 4 (parallel)

- Files: `WifiPanel.qml`, `WifiBackend.qml`.
- Current-connection row is the **declared focal point**. Grouping is current → saved → rest (D-15-16); signal strength renders per-row and **never** drives the sort.
- Password entry is an inline expanding row (D-15-14). **Esc becomes two-stage** — first press collapses the password field, second dismisses the panel. `connectWithPsk` is the only accepted call path; a `Process`-wrapped `nmcli ... password ...` is forbidden (P1 + P3).
- Connect-in-flight renders a row-scoped spinner **plus a real Cancel** (UI-SPEC E4 `loading`, **NEW locked contract**), matching bluetooth's pairing grammar so both connectivity panels read identically. **Planner note carried forward from UI-SPEC:** this requires a NetworkManager deactivate/abort path the panel does not otherwise need — it is strictly more wiring than a spinner alone, chosen for cross-panel consistency. Budget for it.
- `forget` ships despite criterion 2 not listing it (D-15-17): NetworkManager persists a profile even on a bad-PSK attempt and later connects silently reuse the bad PSK, so without `forget` one typo routes the user straight back to the app this phase exists to displace. Destructive-action treatment: separated placement, `Colours.error` tone, inline confirm ("Forget {network name}?" with confirming Forget + Cancel), never a silent one-press forget.
- Full `ConnectionFailReason` → copy mapping is locked in UI-SPEC's Copywriting Contract; implement it verbatim (`NoSecrets` → "Password required", `WifiAuthTimeout` → "Wrong password", `WifiClientDisconnected`/`WifiClientFailed` → "Couldn't connect", `WifiNetworkLost` → "Network out of range", `Unknown` → "Couldn't connect").
- `autonomous: false` — blocking render gate.
- **Owns these `must_haves` predicates:**
  - Edge coverage, PANEL-03: `adjacency` → **backstop** `{ statement: "Two visible networks sharing one SSID render as two independent rows and neither merges nor collides — acting on one never mutates the other's row state", verification: backstop }` (NetworkManager's own AP aggregation behaviour through this binding is not knowable from the qmltypes; verify against a real duplicate-SSID environment at the render gate); `empty` → **backstop** `{ statement: "A completed scan returning zero networks renders the 'No networks found' copy with the refresh control still visible — the copy actually renders, not merely an empty list", verification: backstop }`; `ordering` → **covered** ("within each of the three groups rows hold insertion order; a rescan that changes only signal strength produces byte-identical row order; newly-seen networks append to the bottom of their group rather than inserting mid-list").
  - UI-SPEC covered rows for E3 (`loading`, `error`, `populated`, `overflow`, `zero-one-many`, `long-text`) and E4 (`loading`, `error`, `populated`) → plain truths. E3's `long-text` row is **NEW locked contract** and exists only because the classifier's `list-collection`-only tagging had suppressed it — do not drop it.
  - UI-SPEC **backstop** rows: E3 `empty` (same "No networks found" case as the edge row above — one predicate, not two), E3 `partial` (a network reporting no signal-strength value — ordinary-absence treatment matching E5's battery case), E4 `empty` (Connect disabled until the field is non-empty, **deliberately no minimum-length check**, since WPA PSK length rules vary and a guessed floor would reject valid input).
  - **Prohibition P3 (descriptor-less):** *The entered PSK must not outlive the `connectWithPsk` call — not retained in a QML property that survives the row, not echoed into the failure `reason` text, not written to the Quickshell log.* (The generic secret-on-argv / injection class is canon security and is carried in the threat register instead — breadcrumb, not a second minted prohibition.)
  - **Prohibition P4 (descriptor-less, shared with 15-06):** *No destructive action commits on a single press — Forget always reveals an inline confirm first.*
  - **Prohibition P1** restated.
- Threat rows: `T-15-01` (Information Disclosure — wifi PSK reaching argv, a log, or a surviving property, **high**, **mitigate**: native `connectWithPsk` over D-Bus, no `Process` command array in this phase ever carries a secret value, P3 enforces the residency half). At blocking threshold `high` this row is the plan's gating threat.

### 15-06 — Bluetooth panel build-out · Wave 4 (parallel)

- Files: `BluetoothPanel.qml`, `BluetoothBackend.qml`.
- Connected-devices group is the **declared focal point**. Grouping is connected → paired → discovered (D-15-18). **The deliberate asymmetry with wifi must be recorded in-plan with its reason** or it reads as inconsistency later: BT inquiry contends with the same radio carrying an A2DP stream, so continuous discovery can stutter the very audio the panel was opened to manage, and the daily case (reconnect known headphones) needs zero discovery. Discovery is opt-in behind an explicit "Add device".
- Row press performs the contextual verb by state (Pair / Connect / Disconnect); the chevron expands to battery, address and a visually separated Forget (D-15-19) — the fourth consistent use of the split-affordance idiom. Overflow menus are rejected specifically because they are popups (the same unverified path D-15-12 avoids).
- Pairing shows a real Cancel wired to `cancelPair()` — a strict improvement on D-22's silent watchdog for the one operation whose wait is long and user-visible.
- Failure is **inferred**, not signalled — implement RESEARCH Pitfall 2's recipe exactly: pairing failure = `pairing` true→false with `bonded` still false **and the row's own Cancel was not the trigger**; connect failure = `Connecting → Disconnected` (no user-cancel path exists for `connect()`, so this needs no cancel caveat). Add a `chipWatchdogTimer`-shaped timeout fallback so a wedged BlueZ never leaves a row spinning forever.
- `autonomous: false` — blocking render gate.
- **Owns these `must_haves` predicates:**
  - Edge coverage, PANEL-04: `adjacency` → **covered** ("device rows are keyed by `BluetoothDevice.address`, never `deviceName` — two devices sharing a name render as two rows and each verb acts only on the addressed device"); `empty` → **backstop** `{ statement: "Zero paired devices with discovery not started renders the 'No paired devices' copy with 'Add device' as the only forward path", verification: backstop }`; `ordering` → **covered** ("grouped connected → paired → discovered; within a group rows hold insertion order; a device that connects changes group without reordering its peers; newly discovered devices append").
  - UI-SPEC covered rows for E5 (`error`, `populated`, `partial`, `overflow`, `zero-one-many`, `long-text`) → plain truths.
  - UI-SPEC **backstop** rows: E5 `empty` (same "No paired devices" case as the edge row above — one predicate), E5 `loading` (the discovery-in-progress treatment after "Add device" is pressed is by analogy to D-15-15's wifi indeterminate line and is **not itself locked** — verify the treatment is actually applied to bluetooth discovery, not only to wifi scan).
  - **Prohibition P4** (shared with 15-05) and **Prohibition P1** restated.
- Threat rows: `T-15-04` (Denial of Service — BT inquiry contending with an active A2DP stream, **low**, **mitigate**: discovery is opt-in and `discovering` is bound to `panelOpen` so it stops on dismiss).

### 15-07 — Six-across quick-toggle grid + split tiles · Wave 4 (parallel)

- Files: `QuickToggles.qml`, `Dashboard.qml`, `shell.qml`. (Disjoint from 15-04/05/06/08 — `shell.qml` was last touched in wave 3.)
- One row of six compact tiles, **zero vertical growth** (D-15-21): D-05's 10-15% slack stays untouched, D-38's Dashboard-tab composition is unchanged, and no other widget's render gate re-opens.
- **HARD CONSTRAINT:** "Do Not Disturb" wraps to two lines inside the shipped `chipHeight` = 72px and **must not** regress to "DND" — Phase 14's render gate explicitly rejected that acronym. Verify against the installed font at the render gate (RESEARCH Open Q3).
- Split affordance is new UI inside the existing `ToggleChip` inline component: a second, smaller chevron-hit `MouseArea` calling `openPanel(name)` rather than `pressChipByName`. Body press performs the one obvious verb (mute / wifi radio / adapter). Tile lit-state follows D-26 verbatim — named for the state that lights it; all three sitting lit most of the time is the intended Material You look.
- The chevron path emits `panelRequested(name)` up through `Dashboard.qml` to `shell.qml`, which calls the single guarded `openPanel()` (Flagged Assumption 2 — the DASH-08 guard is not bypassed by this path).
- D-15-20: dismissing the opened panel returns to the desktop, never to the drawer. The drawer was **destroyed**, not hidden (grab exclusivity), so "returning" could only ever be a fresh re-summon; D-14's tab memory survives at shell root so `Super+D` lands back on the Dashboard tab — the return costs exactly one keypress.
- `autonomous: false` — blocking render gate (the legibility constraint is the gate's headline question).
- **Owns these `must_haves` predicates:**
  - UI-SPEC covered rows for E6 (`loading`, `error`, `populated`, `overflow`, `long-text`) → plain truths. E6's `error` row is **NEW locked contract**: a toggle that does not take (e.g. an rfkill hard-block) reverts the tile to its true state after the existing watchdog window rather than sticking lit, and the *reason* is named in the panel's empty state (D-15-26 case 2), not on the tile — reusing Phase 14's pending/watchdog pattern and deliberately introducing **no fifth widget state**.
  - **Prohibition P5 (descriptor-less):** *No tile label may be abbreviated to an acronym to make it fit the six-across row.*
- Threat rows: none new; carry the phase register's `T-15-05` accept row.

### 15-08 — waybar rewiring + `install.sh` correction · Wave 4 (parallel)

- Files: `waybar/.config/waybar/config-athena.jsonc`, `config-floating.jsonc`, `config-vertical.jsonc`, `modules.jsonc`, `install.sh`.
- Rewiring (D-15-05): `network` left-click → wifi panel, `bluetooth` left-click → bluetooth panel, `group/audio` **right**-click → audio panel, all through 15-03's `IpcHandler`. **Preserve unchanged:** `group/audio`'s left-click mute toggle (real muscle memory) and `bluetooth`'s `rfkill toggle bluetooth` right-click.
- Fixes a latent dead end discovered during discussion: athena deliberately removed `tray` from `modules-right` (its own config comment at lines 34-38), so its `nm-applet --indicator` on-click has nothing to render into — dead on the primary layout, and dead twice over on a fresh install because the package was never installed.
- D-15-23 (**required correction, not a preference**): add `network-manager-applet` to `install.sh`'s `PACMAN_PKGS`. It provides `nm-connection-editor`, PANEL-05's wifi Advanced target. `pavucontrol` (~line 111) and `blueman` (~line 212) are already present; the third is host-only state — exactly what the reproducibility constraint forbids, the same failure class CLAUDE.md documents for `adw-gtk3`. **No separate hard-fail mechanism is needed** — `verify_packages()` (install.sh:611-630) already iterates `PACMAN_PKGS` + `AUR_PKGS` and exits non-zero on any `pacman -Q` miss; array membership *is* the mechanism.
- Re-run `waybar-equivalence-check` and `waybar-design-lint` — both are re-opened by these edits.
- One-line note required: `hypr/.config/hypr/scripts/nmtui-launch.sh` was checked and is non-overlapping (a floating-terminal `nmtui` launcher, a fully separate UI) and stays untouched — additive-only milestone, nothing retired.
- Accepted cost to record: bar clicks now depend on the Quickshell process being alive. Bounded — it autostarts and `quickshell-doctor` asserts it.
- `autonomous: false` — a blocking human check is needed for the click behaviours (they cannot be proven from source alone), across at least the athena and vertical layouts.
- Threat rows: `T-15-SC` (Tampering, package install, **low**, **mitigate**). **No blocking legitimacy checkpoint is required here** and per-plan runs must not insert one: the standard `[ASSUMED]`/`[SUS]` human-verify gate governs npm/pip/cargo registries. `network-manager-applet` is an official Arch `extra`-repo package, audited in RESEARCH's Package Legitimacy Audit via `pacman -Si` (GNOME project, `URL: gitlab.gnome.org/GNOME/network-manager-applet`), verdict **OK**, zero `[SLOP]`, zero `[SUS]`, zero AUR or third-party packages introduced.

### 15-09 — `quickshell-doctor` extension + phase-close gate · Wave 5

- Files: `hypr/.config/hypr/scripts/quickshell-doctor` (+ its fixtures directory).
- Four new checks (D-15-25), reusing the **existing** before/during/after summon-and-diff mechanism Phase 11 already built — do not invent a second verification mechanism: (1) all three panel namespaces conform to the `quickshell-*` prefix; (2) `Super+A` registers exactly once, via `keybind-doctor`; (3) no second `org.freedesktop.Notifications` owner appears while a panel is summoned; (4) SwayOSD key ownership is byte-identical before / during / after a panel summon.
- **House rule, non-negotiable: a gate must be proven able to fail before it is trusted to pass.** Ship a poisoned fixture for the new checks (Phase 11's precedent) and prove D-15-26's off-states by `rfkill block` / `unblock` fault injection (the way 13-06 used cache-backdating). Both proofs are acceptance criteria, not observations.
- **Carries the `<assumption_delta_decision>` `promote`** — generalize the doctor's D-Bus model to `service participant`, with `name-owner` (cardinality 1, asserted, poison-proven) and `client-consumer` (cardinality N, never asserted exclusive) as its two variants. The three new panels are registered as `client-consumer`s of PipeWire / NetworkManager / BlueZ so a future check cannot accidentally assert exclusivity over a many-client service.
- Proves D-15-24 mechanically: SwayOSD remains the sole OSD producer, triggered only by hardware keys, at exactly one step and one pill per press — panel volume writes fire no pill.
- Mechanically closes 15-03's three PANEL-06 edge truths (at-most-one panel mounted, zero layers and zero backend activity when none is summoned, last-writer-wins summon).
- Full gate sweep before close: `theme-doctor`, `theme-parity`, `motion-lint` (every new panel QML file is in scope for the zero-hex / zero-duration-literal invariant), `keybind-doctor`, `waybar-equivalence-check`, `waybar-design-lint`, `hypr-equivalence-check`. **Known pre-existing conditions that are not this phase's regressions:** `quickshell-doctor`'s volume-probe one-step-per-press gate is over-strict on rounding-sensitive raw units (filed in 12-01, never fixed), and `hypr-equivalence-check`'s mouse-field forgiveness is explicitly **provisional** pending a human drag-move/drag-resize compensating check that 14-10 could not run. Report both rather than absorbing them.
- `autonomous: false` — carries the phase-close blocking render gate covering all five ROADMAP success criteria.
- Threat rows: `T-15-03` (Spoofing — a second `org.freedesktop.Notifications` owner appearing while a panel is summoned, **medium**, **mitigate**: extend the existing single-owner check to run in the summoned context; no new mechanism, only a new invocation context).

---

## Phase-wide obligations for every per-plan run

1. **Every task carries `<read_first>` and `<acceptance_criteria>`.** `<read_first>` must always include the file being modified plus the named analog from `15-PATTERNS.md` (`Dashboard.qml` for the surface skeleton, `QuickToggles.qml` for the pending/watchdog/`startDetached`/tooltip patterns, `MediaBackend.qml` for the backend-adapter shape, `shell.qml` for the sibling-mount and `GlobalShortcut` shapes).
2. **No fenced code blocks inside `<action>`.** Name identifiers, signatures, property names, D-Bus members, config keys and behaviour; code excerpts belong in `<read_first>` source files.
3. **Comment-text discipline (hard gate):** a literal that an acceptance criterion negative-greps for must not appear verbatim in any `<action>` body.
4. **Zero hex literals, zero raw duration/easing literals** in every new QML file without exception — `Colours.<role>`, `Motion.<pair>Duration` / `<pair>Easing`, `Design.spacing*`. `motion-lint` enforces and every plan must run it. Watchdog `Timer`s declare `interval:`, never `duration:`, to stay outside motion-lint CHECK B.
5. **Every visual plan carries a `checkpoint:human-verify gate="blocking"` render gate** (standing constraint 1 — Phases 6 and 8 both shipped visibly broken surfaces through fully green mechanical gates). At every gate and checkpoint, present deep pros/cons **and name a recommendation** — the user's standing instruction, never a bare options menu.
6. **Verify options against the installed binary** (standing constraint 2) — re-read the three `.qmltypes` files if `quickshell` has moved past 0.3.0-2 since 2026-08-01.
7. **Restart discipline:** `GlobalShortcut` registration needs a full Quickshell process restart (Phase 11 Finding 1), and every restart must be detached — `setsid uwsm app -- ~/.config/hypr/scripts/quickshell-launch.sh` (14-06 standing rule).
8. **Every new QML type registers in `modules/dashboard/qmldir` in the same commit that creates it**, non-singleton (matching `MediaBackend`/`WeatherBackend`/`SystemResources`/`QuickToggles`, not `Design`/`WeatherPalette`).
9. **Deprecation principle:** swaync, walker and wleave are v4.0 migration targets — spend no engineering attention coordinating with them beyond what falls out of this phase's own mechanisms. waybar is **not** a deprecation target, so 15-08's edits are legitimate work.
10. **QS-03 inheritance:** panels are single-instance, not per-monitor. Do not attempt per-screen fan-out; it is a recorded permanent limitation of quickshell 0.3.0-2.

## OUTLINE COMPLETE
