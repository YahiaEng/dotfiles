# Phase 15: Audio + Connectivity Panels - Research

**Researched:** 2026-08-01
**Domain:** Quickshell/QML native service bindings (Networking, Bluetooth, PipeWire) for three in-shell control panels, layered onto the Phase 14 dashboard's surface-lifecycle and D-Bus-coexistence patterns
**Confidence:** HIGH — the three native API surfaces were read directly from the installed `.qmltypes` files on this machine (not from docs or training data), and every reused pattern (layer posture, pending model, tooltip mechanism, namespace scheme) was read from the actual committed QML/Lua/JSON source this phase builds on.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

21 decisions across 8 areas, gathered 2026-08-01. Full text lives in
`15-CONTEXT.md`; the load-bearing ones for planning are restated here.

**Entry points & placement**
- D-15-01: Three new quick-toggle split tiles (Volume, Wi-Fi, Bluetooth) — tile body performs the one obvious verb, chevron opens the full panel. D-26 naming convention: tile named for the state that lights it.
- D-15-02: Each panel is an independent layer surface with its own `LazyLoader` + `HyprlandFocusGrab`; opening one dismisses the drawer (grab exclusivity is a verified platform constraint, not a preference).
- D-15-03: Panels anchor top-center at the drawer's ~850px width, inheriting D-03's geometry verbatim.
- D-15-04: `Super+A` summons the audio panel only. Wifi/bluetooth get no dedicated keybind (all single free letters A/G/H/J/K/M/O/U are already spoken for or reserved; W/B/V are taken). One documented sentence required to explain the asymmetry.
- D-15-05: waybar rewiring — `network` left-click → wifi panel, `bluetooth` left-click → bluetooth panel, `group/audio` right-click → audio panel. `group/audio` left-click mute toggle and `bluetooth` right-click `rfkill toggle bluetooth` are preserved unchanged.

**Shared panel frame (PANEL-06)**
- D-15-06: One header band (icon+title left, labeled "Advanced" button right), no close button — dismissal inherits D-10's set (Esc/click-outside/re-press).
- D-15-07: One fixed height shared by all three panels, scrollable body. Wider D-05 scroll exemption than Phase 14 predicted — all three panels have unbounded content, not just the mixer.
- D-15-08: Entrance motion — cascade the frame (3-5 elements), render the list whole (not staggered). Reuses D-21's existing stagger token.
- D-15-09: Failures render inline on the affected row — a new FOURTH widget state (populated/pending/empty/**failed**). Verified: `Quickshell.Networking`'s `Network.connectionFailed(reason)` signal exists (see Networking API section below).

**Audio panel composition**
- D-15-10: Pinned control block (master volume + both device pickers) over a scrolling app list.
- D-15-11: Full input symmetry — input device picker + input level slider + mic mute (USER OVERRODE the recommendation of device+mute-only). Pre-agreed fallback: drop the input level slider if the render gate finds it cluttered, no new decision needed.
- D-15-12: Device pickers are expandable inline rows — QtQuick `Popup` deliberately avoided (unverified inside a Wayland layer-shell surface on this build).
- D-15-13: Per-app row = icon-as-mute + app name + slider. Muted state carried twice (icon dims+slash, slider track shifts) plus tooltip. Peak meters declined for now (available via a separate `PwNodePeakMonitor` component, not on `PwNode` itself — see Pipewire API section).

**Wifi flows**
- D-15-14: Password entry is an inline expanding row on the selected network. Esc is two-stage (collapse field, then dismiss panel). `connectWithPsk` passes the PSK over D-Bus, never touching a command line — this is the deciding security argument for the native binding over an `nmcli` wrapper.
- D-15-15: `scannerEnabled` true for the panel's lifetime, off on dismiss (zero-idle doctrine). Visible in-progress state = indeterminate progress line pinned under the header.
- D-15-16: List ordering is grouped and stable (current → saved → rest); signal strength never drives sort.
- D-15-17: Wifi exposes connect/disconnect/**forget** beyond criterion 2's literal text — NetworkManager persists a connection profile even on a bad-PSK attempt, so `forget` is the escape hatch from that failure mode. `forget` requires destructive-action-separated placement.

**Bluetooth flows**
- D-15-18: Paired devices listed immediately with zero radio activity; discovery is opt-in behind "Add device". Grouping: connected → paired → discovered (deliberate asymmetry from wifi's grammar, reasoned in CONTEXT.md — BT inquiry contends with an active A2DP stream's radio).
- D-15-19: Device row press = contextual verb (Pair/Connect/Disconnect) by state; chevron expands to battery/address/separated Forget. Pairing pending shows a real Cancel wired to `cancelPair`.

**Dismissal, fit, robustness, coexistence**
- D-15-20: Dismissing a panel always returns to the desktop, never to the drawer (grab exclusivity makes the drawer's destruction, not hiding, mechanically forced).
- D-15-21: Quick-toggle grid becomes ONE row of six compact tiles (end-4/Caelestia scaling convention). Hard constraint: "Do Not Disturb" must still wrap to two lines legibly, never regress to "DND".
- D-15-22: An Advanced button whose target app is absent renders disabled with the reason, never hidden.
- D-15-23 (REQUIRED CORRECTION): `install.sh` must add `network-manager-applet` to `PACMAN_PKGS` (official `extra` repo) — it provides `nm-connection-editor`. Verified missing from `install.sh` this research session (see Package Legitimacy Audit).
- D-15-24: Panel volume writes do NOT fire a SwayOSD pill — SwayOSD stays the sole OSD producer, triggered only by hardware keys.
- D-15-25: Criterion 5 proven by extending `quickshell-doctor` with a poisoned fixture (new checks: panel namespace conformance, `Super+A` registers exactly once, no second `org.freedesktop.Notifications` owner while a panel is summoned, SwayOSD key ownership byte-identical before/during/after).
- D-15-26: Off/empty/degraded states distinguish fixable (wifi soft-off, has an Enable button) from unfixable (wifi hardware-blocked, bluetooth adapter absent — no button, names the cause).

**Inherited constraints (recorded, not decided)**
- QS-03: no per-screen fan-out — panels are single-instance, not per-monitor (permanent quickshell 0.3.0-2 limitation).
- Phase 11 Finding 1: `GlobalShortcut` registration does not hot-reload — `Super+A` needs a Quickshell process restart to register.
- D-43 layer posture: overlay layer, `exclusiveZone: 0`, `WlrKeyboardFocus.OnDemand` baseline, `quickshell-<surface>` namespace.

### Claude's Discretion

- Exact panel height, tile width/height at six-across, corner radius token, internal margins, whether the ~850px frame uses a centered content column.
- Material Symbol picks per panel/tile/row; exact "Advanced" label wording; tooltip copy.
- Whether expanding a device picker (D-15-12) animates the layout or overlays it.
- Insert treatment (or none) for list items arriving from a live scan after the frame cascade has settled.
- Exact scan cadence within "while open", progress-line styling, refresh control placement.
- Peak-meter deferral is a decision (D-15-13); re-adding meters later is discretion within the row's existing structure.
- Bluetooth failure inference strategy once research settles it (**settled below** — see Common Pitfalls, Bluetooth failure inference).
- Plan/wave decomposition and sequencing; granularity is `coarse`. Building the shared frame before the three panels is the obvious ordering but not mandated.

### Deferred Ideas (OUT OF SCOPE)

- Per-app peak level meters in the mixer rows (addable later without changing row structure).
- `Super+Shift+W` / `Super+Shift+B` panel keybinds (revisit only if tile/waybar paths measure slow).
- Autoconnect toggle, trusted-device policy, per-network options in-panel (Advanced's job).
- A SwayOSD pill on panel volume writes.
- Android-style back-to-drawer navigation from a panel.
- Number-key or per-tile direct panel jumps from the drawer.
- Bar-anchored (top-right) panel placement (needs the waybar-layout state read D-03 deferred).
- Per-screen panel instances (blocked by QS-03, permanent).
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| PANEL-01 | Per-app volume mixer lists active audio apps with per-app slider + click-to-mute | `Quickshell.Services.Pipewire` `Pipewire.nodes` filtered by `PwNodeType.AudioOutStream`/`Stream` flag; `PwNodeAudioIface.volume`/`muted` per node. See Pipewire API section. |
| PANEL-02 | Audio panel selects default output/input device and adjusts master volume | `Pipewire.preferredDefaultAudioSink`/`preferredDefaultAudioSource` (read/write) for device selection; `Pipewire.defaultAudioSink.audio.volume`/`muted` for master. See Pipewire API section and Pitfall "preferred vs actual default". |
| PANEL-03 | Wifi panel scans, lists networks, connects, prompts for password on secured networks | `Quickshell.Networking` — `WifiDevice.scannerEnabled`, `NetworkDevice.networks`, `WifiNetwork.connectWithPsk(psk)`, `Network.connectionFailed(reason)`. See Networking API section. |
| PANEL-04 | Bluetooth panel toggles adapter, lists devices, connects/disconnects/forgets | `Quickshell.Bluetooth` — `BluetoothAdapter.enabled`, `BluetoothAdapter.devices`, `BluetoothDevice.connect()/disconnect()/pair()/cancelPair()/forget()`. See Bluetooth API section. |
| PANEL-05 | Each panel carries an Advanced button launching pavucontrol/nm-connection-editor/blueman | All three binaries verified present on this host; `network-manager-applet` (provides `nm-connection-editor`) verified ABSENT from `install.sh` — see Package Legitimacy Audit. `startDetached()` required (QuickToggles.qml precedent) or the launched app dies when the panel's `LazyLoader` destroys the surface. |
| PANEL-06 | All panels built from one shared dialog component | Dashboard.qml's `PanelWindow`+`WlrLayershell`+`HyprlandFocusGrab` skeleton is the copy-from source; D-15-02's grab-exclusivity finding is what makes "one shared component, three summon sites" structurally sound rather than aspirational. |
</phase_requirements>

## Summary

This phase adds three Quickshell panels that are **read/write consumers of already-running system services** (PipeWire via wireplumber, NetworkManager, BlueZ) — it introduces zero new daemons and zero new D-Bus-owned names. All three target APIs (`Quickshell.Networking`, `Quickshell.Bluetooth`, `Quickshell.Services.Pipewire`) ship as native QML modules inside the already-installed `quickshell 0.3.0-2` package — no new package installs are needed for the panel logic itself. I read the installed `.qmltypes` files directly (`/usr/lib/qt6/qml/Quickshell/{Networking,Bluetooth,Services/Pipewire}/*.qmltypes`) rather than relying on upstream docs or training memory, which resolves the phase's own open question definitively: **native D-Bus bindings are the correct and only sensible choice** for all three panels, not `nmcli`/`bluetoothctl`/`wpctl` wrappers — the C++-backed QML types expose exactly the invokable methods and signals the five success criteria need, including the specific ones CONTEXT.md flagged as unverified (`connectWithPsk`, `cancelPair`, `preferredDefaultAudioSink`).

The one genuine gap the qmltypes files cannot resolve is Bluetooth failure detection (deferred research item 1): `BluetoothDevice` exposes no `connectionFailed`-equivalent signal. This research settles it with a concrete inference recipe (below) built from the verified `pairing`/`bonded`/`state` properties. A second gap — the exact PipeWire `properties` `QVariantMap` keys available per stream node (needed for per-app name/icon) — cannot be resolved from `.qmltypes` alone since it's an untyped map; this is flagged as an `[ASSUMED]` (PipeWire's own standard property-key convention) requiring a live `quickshell -p` probe as a Wave 0 task, exactly the precedent 12-06/14-06 already established for verifying live QML behavior on this build.

The class hierarchy in `Quickshell.Networking` is not flat the way CONTEXT.md's summary list implied: `Networking.devices` (a list of `NetworkDevice`, of which `WifiDevice` is a subtype) must be filtered for the Wi-Fi device before `scannerEnabled` or `.networks` become reachable — there is no top-level `Networking.networks` or `Networking.scannerEnabled`. The planner must build the wifi panel around "find the `WifiDevice` among `Networking.devices`" as an explicit first step, not skip straight to a flat network list.

**Primary recommendation:** Build the shared `PanelDialog` component first (wraps Dashboard.qml's proven `PanelWindow`+`HyprlandFocusGrab`+`WlrLayershell` skeleton, adds the D-15-06 header/Advanced-button chrome and D-15-09's fourth widget state), then implement the three panels as three thin QML files that each provide only their body content plus a small "backend adapter" component per service (WifiBackend/BluetoothBackend/AudioBackend, mirroring the Phase 14 MediaBackend/WeatherBackend/SystemResources pattern of mounting shared-state readers at `shell.qml` sibling level). Extend `quickshell-doctor` last, once all three panels exist to summon-and-diff against.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Panel UI rendering, layout, animation | Quickshell/QML (client) | — | Same tier as the Phase 14 drawer; all three panels are `PanelWindow` layer-shell surfaces owned by the Quickshell process. |
| Audio state (volume, mute, default device) | PipeWire/wireplumber daemon (system service, user session) | Quickshell.Services.Pipewire (client binding) | The daemon is the sole source of truth; the panel is a reader+writer client exactly like `wpctl`/`pactl`/waybar's pulseaudio module/SwayOSD already are. Multiple simultaneous clients is PipeWire's designed operating mode. |
| Wifi state (scan results, connection, saved profiles) | NetworkManager daemon (system D-Bus service) | Quickshell.Networking (client binding, native D-Bus) | NetworkManager already serves nm-applet, nmcli, and now the panel simultaneously — a standard many-reader/many-writer D-Bus service, not a single-owner name like `org.freedesktop.Notifications`. |
| Bluetooth state (adapter, pairing, connections) | BlueZ daemon (system D-Bus service) | Quickshell.Bluetooth (client binding, native D-Bus) | Same many-client model as NetworkManager; `bluetoothctl`/blueman/the panel are all simultaneous BlueZ clients. |
| Advanced-button launch targets (pavucontrol/nm-connection-editor/blueman) | Desktop app tier (separate process, `startDetached()`) | — | Explicitly NOT owned by the panel process — must survive the panel's own destroy-on-dismiss lifecycle (QuickToggles.qml's `darkProcess` precedent, D-15-02's grab exclusivity makes this even more certain to fire on every Advanced click). |
| Hardware key → OSD pill (`XF86Audio*`/`XF86MonBrightness*`) | Hyprland compositor bind → SwayOSD (existing, untouched) | — | D-15-24 explicitly keeps this tier unchanged; the panel is never in this path. Verified: `keybinds.lua:248-259` routes all six audio/brightness XF86 keys through `swayosd-client`, none through Quickshell `GlobalShortcut`. |
| Shell-root shared-state backends (if any panel needs cross-summon memory) | Quickshell shell.qml siblings | — | Phase 14 precedent (`MediaBackend`/`WeatherBackend`/`SystemResources` mounted at shell.qml, gated by a `drawerOpen`-style boolean) — likely NOT needed here since D-15-02 makes every panel single-instance-per-summon with no cross-summon memory requirement recorded in CONTEXT.md, unlike Dashboard's tab-memory. |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `quickshell` | 0.3.0-2 (already installed — `[VERIFIED: pacman -Q quickshell]`) | Ships the three native QML modules this phase needs | Already the project's chosen shell toolkit (Phase 11 gate); no new package required for panel logic. |
| `Quickshell.Networking` | ships inside quickshell 0.3.0-2 (`[VERIFIED: /usr/lib/qt6/qml/Quickshell/Networking/qmldir + quickshell-network.qmltypes, read directly this session]`) | Native NetworkManager D-Bus binding — devices, wifi scan/connect/forget, connection-failure signal | Confirmed installed and exposes every method PANEL-03 needs (`connectWithPsk`, `forget`, `connectionFailed`). No `nmcli` wrapper needed. |
| `Quickshell.Bluetooth` | ships inside quickshell 0.3.0-2 (`[VERIFIED: /usr/lib/qt6/qml/Quickshell/Bluetooth/qmldir + quickshell-bluetooth.qmltypes, read directly this session]`) | Native BlueZ D-Bus binding — adapter, devices, pair/connect/disconnect/forget | Confirmed installed; exposes `cancelPair` directly (D-15-19's requirement). No `bluetoothctl` wrapper needed. |
| `Quickshell.Services.Pipewire` | ships inside quickshell 0.3.0-2 (`[VERIFIED: /usr/lib/qt6/qml/Quickshell/Services/Pipewire/qmldir + quickshell-service-pipewire.qmltypes, read directly this session]`) | Native PipeWire client binding — node graph, per-node audio (volume/mute), default sink/source | Confirmed installed; exposes `preferredDefaultAudioSink`/`Source` (read+write) and per-node `PwNodeAudioIface`. No `wpctl`/`pactl` wrapper needed for reads or writes. |
| `network-manager-applet` | 1.36.0-2, official `extra` repo (`[VERIFIED: pacman -Si network-manager-applet]`) | Provides `nm-connection-editor`, PANEL-05's wifi Advanced target | D-15-23's required correction. Confirmed present on this host but **absent from `install.sh`'s `PACMAN_PKGS`** (`[VERIFIED: grep network-manager-applet install.sh` returns zero matches`]`) — host-only state per the reproducibility constraint. `pacman -Si` confirms `Depends On` includes `nm-connection-editor` directly, so adding this one package name is sufficient. |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `pavucontrol` | already in `install.sh` `PACMAN_PKGS` (line 111, `[VERIFIED: grep -n pavucontrol install.sh]`) | Audio panel's Advanced target | Already installed and registered — no change needed for this binary. |
| `blueman` | already in `install.sh` `PACMAN_PKGS` (line 212, `[VERIFIED]`) | Bluetooth panel's Advanced target (`blueman-manager`) | Already installed and registered — no change needed. |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Native `Quickshell.Networking`/`Bluetooth`/`Pipewire` bindings | `nmcli`/`bluetoothctl`/`wpctl` CLI wrappers via `Quickshell.Io.Process` | Rejected outright per the phase's own open question and D-15-14's security rationale — a PSK passed as a wrapper's argv is visible in `/proc/<pid>/cmdline` to every process on the machine for the call's duration; `connectWithPsk` sends it over D-Bus instead. The native bindings also give reactive property bindings (no polling needed) where a CLI wrapper would need `Process`+`SplitParser`+manual state tracking for every property. |
| PANEL-02 device selection via `preferredDefaultAudioSink`/`Source` | `wpctl set-default <id>` via `Process` | The property is documented read/write on `Pipewire` itself (`qml.hpp:114/121` in the qmltypes) — a direct write should be equivalent to wpctl's own mechanism (wireplumber's default-nodes metadata) but this is UNVERIFIED live on this build; see Common Pitfalls. |

**Installation:**
```bash
# No new npm/pip/cargo/AUR packages needed for panel logic — quickshell 0.3.0-2
# already ships Networking/Bluetooth/Services.Pipewire.
# The one required install.sh change (D-15-23):
```
Add to `install.sh`'s `PACMAN_PKGS` array (alongside `pavucontrol` and other official-repo audio/desktop packages, e.g. near line 111):
```bash
network-manager-applet
```
This automatically joins the existing hard-fail verification class — `[VERIFIED: install.sh:611-630]` `verify_packages()` iterates every entry in `VERIFY_PKGS` (= `PACMAN_PKGS` + `AUR_PKGS`, `install.sh:651`) and exits non-zero on any `pacman -Q` miss; no separate "hard-fail class" mechanism needs to be built, the array membership itself is the mechanism.

**Version verification:** All three Quickshell service modules were verified present by reading their `qmldir`+`.qmltypes` files directly under `/usr/lib/qt6/qml/Quickshell/` on this machine (not `npm view`/`pip index` — there is no separate ecosystem registry for Quickshell QML modules; they are compiled into the `quickshell` Arch package itself). `pacman -Q quickshell` confirms `0.3.0-2`, matching Phase 11/12's already-established version.

## Package Legitimacy Audit

This phase's only new *package* is `network-manager-applet`, a pacman official-repo package, not an npm/pip/crates dependency — the standard SLOP/SUS/OK typosquatting gate (built for language-ecosystem registries) does not directly apply. Verified instead via the Arch-appropriate equivalent: `pacman -Si`.

| Package | Registry | Age/Provenance | Downloads | Source Repo | Verdict | Disposition |
|---------|----------|-----------------|-----------|--------------|---------|-------------|
| `network-manager-applet` | pacman `extra` (official Arch repo, not AUR) | GNOME project package, actively maintained | N/A (official repo, not npm-style download-counted) | `[VERIFIED: pacman -Si network-manager-applet` → `URL: https://gitlab.gnome.org/GNOME/network-manager-applet]` | OK | Approved — add to `install.sh` `PACMAN_PKGS` per D-15-23 |

**Packages removed due to [SLOP] verdict:** none.
**Packages flagged as suspicious [SUS]:** none.

No AUR or third-party packages are introduced by this phase. All three QML service modules (`Quickshell.Networking`/`Bluetooth`/`Services.Pipewire`) ship inside the already-vetted `quickshell` package (Phase 11's own AUR/legitimacy review covered this).

## Architecture Patterns

### System Architecture Diagram

```
Hardware keys (XF86Audio*/XF86MonBrightness*)
        │  (Hyprland bind, UNCHANGED — D-15-24)
        ▼
  swayosd-client  ──▶  SwayOSD daemon  ──▶  themed OSD pill
        │
        │ (writes volume via its own PipeWire client — independent of panel)
        ▼
┌─────────────────────────── PipeWire / wireplumber daemon ───────────────────────────┐
│   readers/writers: waybar(pulseaudio module, wpctl) · SwayOSD · pavucontrol ·        │
│   NEW: Quickshell AudioPanel (via Quickshell.Services.Pipewire, native client)       │
└────────────────────────────────────────────────────────────────────────────────────┘

┌────────────────────────── NetworkManager daemon (system D-Bus) ─────────────────────┐
│   readers/writers: nm-applet · nmcli · nm-connection-editor ·                        │
│   NEW: Quickshell WifiPanel (via Quickshell.Networking, native D-Bus client)         │
└────────────────────────────────────────────────────────────────────────────────────┘

┌───────────────────────────── BlueZ daemon (system D-Bus) ───────────────────────────┐
│   readers/writers: bluetoothctl · blueman-manager · blueman-applet ·                 │
│   NEW: Quickshell BluetoothPanel (via Quickshell.Bluetooth, native D-Bus client)     │
└────────────────────────────────────────────────────────────────────────────────────┘

Dashboard quick-toggle tile press ──▶ HyprlandFocusGrab clears drawer's grab
                                       (verified per-compositor exclusive, D-15-02)
                                              │
                                              ▼
                          shell.qml's per-panel LazyLoader { active: true }
                                              │
                                              ▼
                    PanelDialog (shared component) mounts, its own
                    HyprlandFocusGrab becomes the sole active grab
                                              │
                          ┌───────────────────┼───────────────────┐
                          ▼                   ▼                   ▼
                     AudioPanel          WifiPanel          BluetoothPanel
                  (Pipewire client)   (Networking client)  (Bluetooth client)
                          │                   │                   │
                    Advanced button    Advanced button      Advanced button
                    startDetached()    startDetached()      startDetached()
                          │                   │                   │
                          ▼                   ▼                   ▼
                     pavucontrol      nm-connection-editor      blueman-manager
                 (survives panel's own dismiss-destroy, D-15-02 makes this certain)
```

### Recommended Project Structure
```
quickshell/.config/quickshell/modules/dashboard/
├── PanelDialog.qml       # NEW — shared frame: header/title/Advanced button,
│                          #       fixed height + scrollable body, D-15-09's
│                          #       4-state vocabulary, cascade entrance motion
├── AudioPanel.qml         # NEW — body content only, mounted inside PanelDialog
├── AudioBackend.qml       # NEW — thin Pipewire-reading component, mirrors
│                          #       MediaBackend.qml's shared-instance shape
├── WifiPanel.qml           # NEW — body content only
├── WifiBackend.qml         # NEW — thin Networking-reading component
├── BluetoothPanel.qml       # NEW — body content only
├── BluetoothBackend.qml     # NEW — thin Bluetooth-reading component
└── QuickToggles.qml        # MODIFIED — extends chipModel to 6, splits tile
                             #            press (body verb) vs chevron (open panel)
```

### Pattern 1: Shared PanelDialog wraps Dashboard.qml's proven surface skeleton
**What:** A single QML component reproduces `Dashboard.qml`'s `PanelWindow` + `WlrLayershell` + `HyprlandFocusGrab` + `anchors.top`/margin geometry, parameterized by namespace suffix, title, icon, and Advanced-button target/availability. The three panels instantiate it with different `Loader`-mounted body content.
**When to use:** For all three panels — this IS what makes PANEL-06 ("shared dialog component") structurally true.
**Example (skeleton copied from the verified source, not re-derived):**
```qml
// Source: quickshell/.config/quickshell/modules/Dashboard.qml:53-198 (read directly this session)
PanelWindow {
    id: panelWindow
    signal dismissRequested()
    anchors.top: true
    margins.top: <same drawerTopMargin pattern, Dashboard.qml:92-93>
    exclusiveZone: 0
    exclusionMode: ExclusionMode.Normal
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-<panel-name>"   // D-42/D-43 family prefix
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    color: "transparent"

    HyprlandFocusGrab {
        windows: [ panelWindow ]
        active: true
        onCleared: panelWindow.dismissRequested()
    }
    // D-15-02: this grab implicitly clears the drawer's own grab if the
    // drawer is still open — verified exclusive-per-compositor, both orders.
}
```
**Verified fact this pattern depends on:** `[VERIFIED: hyprland_focus_grab_v1 is exclusive per-compositor on this build, verified in both orders — recorded in 15-CONTEXT.md, sourced from 11-QUICKSHELL-EVIDENCE.md Finding 2]`.

### Pattern 2: Backend-adapter components mirror Phase 14's MediaBackend/WeatherBackend shape
**What:** A small QML component (`AudioBackend.qml` etc.) that binds directly to the Quickshell service singleton (`Pipewire`, `Networking`, `Bluetooth`) and re-exposes only the filtered/derived properties the panel body actually needs (e.g., `wifiDevice: Networking.devices found where type===Wifi`), rather than every panel file reaching into the raw singleton independently.
**When to use:** All three panels — keeps the "find the WifiDevice among Networking.devices" filtering logic in one place instead of three copies.
**Example:**
```qml
// Pattern only — no upstream source for this exact shape; modeled on
// Dashboard.qml's own mediaBackend/weatherBackend passed-in-instance
// convention (Dashboard.qml:324-334, read directly this session).
import Quickshell.Networking

Item {
    id: root
    readonly property var wifiDevice: {
        for (var i = 0; i < Networking.devices.count; i++) {
            var d = Networking.devices.get(i);  // UntypedObjectModel access pattern — verify exact accessor live
            if (d.type === DeviceType.Wifi) return d;
        }
        return null;
    }
    readonly property bool wifiEnabled: Networking.wifiEnabled
    readonly property bool wifiHardwareEnabled: Networking.wifiHardwareEnabled
}
```
**Caveat (flag for Wave 0 live verification):** `UntypedObjectModel`'s exact QML-side iteration/accessor API (`.count`/`.get(i)` vs direct array-like indexing vs a `Repeater`-only consumption model) is NOT resolved by the qmltypes file — `UntypedObjectModel` is a Quickshell core type, not part of these three plugin modules, and its accessor shape needs a live `quickshell -p` check (same class of gap `12-06`/`14-06` resolved by writing a throwaway probe before relying on it in a real component).

### Pattern 3: `startDetached()` for every Advanced button
**What:** Every Advanced-button launch must use `Process.startDetached()`, never `running: true`, exactly like `QuickToggles.qml`'s `darkProcess`.
**When to use:** All three panels' Advanced buttons.
**Why (verified precedent, not assumption):** `[VERIFIED: quickshell/.config/quickshell/modules/dashboard/QuickToggles.qml:292-316]` — a lifetime-bound `running: true` `Process` is killed when its QML object is destroyed; the comment there documents this was reproduced directly (SIGTERM at ~0.6s mimicking the drawer's destroy timing) and the fix (`startDetached()`) proven live. D-15-02 makes this scenario MORE certain to occur for the panels than it was for the dashboard's Dark chip, since every Advanced-button click is expected to open a focus-stealing GUI app while the panel that launched it is a `LazyLoader`-destroyed-on-dismiss surface exactly like the drawer.
```qml
// Source: QuickToggles.qml:317-320 (exact pattern to reuse, path adapted)
Process {
    id: advancedProcess
    command: [ "pavucontrol" ]   // or nm-connection-editor / blueman-manager
}
// on click:
advancedProcess.startDetached()
```

### Pattern 4: Truth-driven pending model (D-22) extended with a fourth "failed" state
**What:** Same shape as `QuickToggles.qml`'s `pendingChip`/watchdog `Timer`/backend-truth-read pattern, but a row-scoped action (connect/pair/forget) that can now settle into an explicit `failed` state carrying `reason` text, rather than only ever silently reverting to idle.
**When to use:** Wifi connect-with-password rows, bluetooth pair/connect rows.
**Example — wifi connection failure, using the verified signal:**
```qml
// Networking.Network.connectionFailed(reason) — verified this session,
// quickshell-network.qmltypes lines 170-174 (Network) and enum at lines 8-38
// (ConnectionFailReason). Quote of the verbatim enum values:
//   "Unknown", "NoSecrets", "WifiClientDisconnected", "WifiClientFailed",
//   "WifiAuthTimeout", "WifiNetworkLost"
Connections {
    target: selectedNetwork   // a WifiNetwork instance
    function onConnectionFailed(reason) {
        row.state = "failed";
        row.failureText = ConnectionFailReason.toString(reason);  // built-in enum->string method, verified present
    }
}
```

### Anti-Patterns to Avoid
- **Flat `Networking.networks` access:** does not exist. `Networking` (the singleton) exposes only `devices` (a list of `NetworkDevice`); `.networks` lives on `NetworkDevice`/`WifiDevice` instances, and only `WifiDevice` (not the base `NetworkDevice`, not `WiredDevice`) has `scannerEnabled`. Always filter `Networking.devices` for `type === DeviceType.Wifi` first.
- **Calling `forget()` reactively off the `requestForget` signal:** `requestForget` is a signal ON `Network`, not a method to call — the invokable method is `forget()` (`[VERIFIED: quickshell-network.qmltypes:196]` `Method { name: "forget" ... }`). The `request*`-prefixed signals (`requestConnect`, `requestConnectWithSettings`, `requestDisconnect`, `requestForget` on `Network`; `requestDisconnect`, `requestSetAutoconnect`, `requestSetNmManaged` on `NetworkDevice`) appear to be an alternate declarative-binding convention (something elsewhere connects a UI control directly to firing them) — but the panel's own code should call the plain-named invokable methods (`connect()`, `disconnect()`, `forget()`, `connectWithSettings()`, `connectWithPsk()` on `WifiNetwork`) directly, which is both simpler and matches how `QuickToggles.qml`'s existing `Process`/method-call style works. This distinction is UNVERIFIED beyond the qmltypes signature list — a Wave 0 live check (call `.forget()` on a real `Network` object, confirm it does what's expected) is warranted per standing constraint 2.
- **A second `QtQuick.Controls` `Popup` for device pickers or the bluetooth overflow menu:** explicitly avoided by D-15-12/D-15-19 — unverified inside a Wayland layer-shell surface on this Qt/quickshell build. Use the inline expanding-row idiom instead (already the CONTEXT.md-mandated pattern).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Wifi scanning, connecting, secured-network auth | An `nmcli`-wrapping `Process`+`SplitParser` state machine | `Quickshell.Networking`'s native bindings (`WifiDevice.scannerEnabled`, `WifiNetwork.connectWithPsk`) | Confirmed present and reactive (property bindings, no polling); avoids the PSK-on-cmdline security hole D-15-14 already reasoned about. |
| Bluetooth pairing/connection state machine | A `bluetoothctl`-wrapping `Process`+regex-parsed stdout | `Quickshell.Bluetooth`'s native bindings (`pair()`, `cancelPair()`, `connect()`, `disconnect()`, `forget()`, and the `pairing`/`bonded`/`connected` properties) | All five verbs are direct Q_INVOKABLE methods; state is reactive properties, not stdout-scraped. |
| Per-app volume / mute / default-device selection | A `wpctl`/`pactl`-wrapping `Process` per action | `Quickshell.Services.Pipewire`'s `PwNodeAudioIface` (`volume`, `muted`, `volumes` — all read+write) and `Pipewire.preferredDefaultAudioSink`/`Source` | Direct property writes are reactive and avoid a `Process` per slider-drag frame (which would be both slow and would spam-launch subprocesses on every drag tick). |
| Bluetooth pairing/connection failure detection | Regex-scraping `bluetoothctl` output for "Failed to..." lines | Property-transition inference off `pairing`/`bonded`/`state` (see Common Pitfalls below) | The native binding has no failure signal, but its properties are sufficient to infer failure without any subprocess at all. |

**Key insight:** Every one of the three target services already has a native, reactive, D-Bus-backed Quickshell binding installed on this machine. The temptation to fall back to CLI wrappers (`nmcli`/`bluetoothctl`/`wpctl`) should be resisted everywhere except the specific gaps this research flags as unverified (device-model iteration shape, `preferred*` write semantics) — and even those should be closed with a live Wave-0 QML probe, not a permanent CLI-wrapper fallback.

## Common Pitfalls

### Pitfall 1: Flat property-list confusion (Networking class hierarchy)
**What goes wrong:** Treating `wifiEnabled`, `networks`, `scannerEnabled`, `connect`, `known`, `nmSettings` etc. as if they all live on one flat `Networking` object (as CONTEXT.md's summary list — sourced from an earlier live exploration — presents them).
**Why it happens:** The properties are spread across four classes in a prototype chain: `NetworkingQml` (singleton) → `NetworkDevice` → `WifiDevice`/`WiredDevice` → `Network` → `WifiNetwork`. A flat mental model looks plausible until you try to call `Networking.connect()` and it doesn't exist.
**How to avoid:** Always resolve the object graph explicitly: `Networking.devices` (list of `NetworkDevice`) → filter `type === DeviceType.Wifi` → that device's `.networks` (list of `Network`, dynamically `WifiNetwork` instances for a wifi device) → each network has `connect()`/`connectWithPsk()`/`forget()`/`state`/`signalStrength`/`security`.
**Warning signs:** `TypeError: Networking.connect is not a function` or `Networking.networks is undefined` in the Quickshell log at panel-mount time.

### Pitfall 2: Bluetooth failure inference (resolves CONTEXT.md's open research item 1)
**What goes wrong:** Assuming `BluetoothDevice` has a `connectionFailed`/`pairFailed` signal analogous to Networking's — it does not (`[VERIFIED: quickshell-bluetooth.qmltypes`, `BluetoothDevice` component, lines 158-339 — the full signal list is `addressChanged, deviceNameChanged, nameChanged, connectedChanged, stateChanged, pairedChanged, bondedChanged, pairingChanged, trustedChanged, blockedChanged, wakeAllowedChanged, iconChanged, batteryAvailableChanged, batteryChanged, adapterChanged` — no failure signal among them]`).
**Why it happens:** BlueZ's own D-Bus API is thinner here than NetworkManager's; Quickshell's binding follows suit.
**How to avoid — the concrete inference recipe:** Watch the specific verb's own boolean property transition back to false WITHOUT the expected end-state property ever becoming true:
- **Pairing failure:** call `device.pair()` → `pairing` becomes `true` (`[VERIFIED: quickshell-bluetooth.qmltypes:245-252]`, `Property { name: "pairing" ... isReadonly: true }`) → on completion, `pairing` returns to `false`. If `bonded` (`[VERIFIED: lines 235-244]`) is `true` at that point, it succeeded; if `bonded` is still `false`, it failed or was cancelled. `cancelPair()` is a distinct user action the panel itself triggers, so a panel-initiated cancel is already known and should be excluded from the "failed" UI state (only an externally-terminated pairing, i.e. `pairing: true→false` with `bonded` still `false` where the row's own Cancel button was NOT the trigger, should render as "failed").
- **Connect failure:** call `device.connect()` → `state` (`[VERIFIED: lines 206-215]`, enum `BluetoothDeviceState`: `Disconnected, Connected, Disconnecting, Connecting` — `[VERIFIED: lines 350-360]`) transitions to `Connecting` → on completion either `Connected` (success) or reverts to `Disconnected` (failure — there is no user-cancel path for `connect()`, unlike `pair()`/`cancelPair()`, so any `Connecting→Disconnected` transition can be read as failure without the pairing caveat above).
- Recommend a short timeout-based fallback identical in shape to `QuickToggles.qml`'s `chipWatchdogTimer` (D-22 pattern) in case a transition silently never fires — the panel should not hang forever in "pending" if BlueZ itself wedges.
**Warning signs:** A pairing/connect attempt that never resolves visually — the panel row stuck on a spinner — is the signal this inference is missing a case; add the watchdog before shipping.

### Pitfall 3: `preferredDefaultAudioSink`/`Source` write semantics are UNVERIFIED live (CONTEXT.md's open research item 4)
**What goes wrong:** Assuming a write to `Pipewire.preferredDefaultAudioSink = someNode` immediately and audibly re-routes currently-playing streams to the new device, matching what PANEL-02's "selects the default output device" implies to a user (the audible result, not just an internal preference flag).
**Why it happens:** The qmltypes file confirms the property is genuinely read/write (`[VERIFIED: quickshell-service-pipewire.qmltypes:69-78]`, `write: "setDefaultConfiguredAudioSink"`) and is separate from the read-only `defaultAudioSink` (`[VERIFIED: lines 49-58]`, no `write` key) — the naming (`preferred...` vs plain `default...`) hints that `preferred` is a *request* wireplumber may or may not honor immediately for already-open streams, but the qmltypes file cannot prove wireplumber's actual routing behavior.
**How to avoid:** Add a Wave 0 or early-plan live verification task: set `preferredDefaultAudioSink` to a second real output device while audio is playing, and confirm via `pactl list sink-inputs` or by ear that the live stream actually moves. If it does not move existing streams (only new ones), the panel needs either an additional explicit re-route step per stream (`PwNodeLinkTracker`/`PwLinkGroup` manipulation — both present in the qmltypes, `[VERIFIED: lines 199-237, 318-... region]`) or an accepted, documented scope limitation ("switches default for new streams; playing streams keep their current route") — this is exactly the kind of finding standing constraint 2 exists to catch before it becomes a render-gate surprise.
**Warning signs:** User selects a new output device in the panel, master volume slider still visibly controls the OLD device's stream.

### Pitfall 4: `UntypedObjectModel` accessor shape is unverified
**What goes wrong:** `Pipewire.nodes`, `Networking.devices`, `Bluetooth.devices`, `BluetoothAdapter.devices` are all typed `UntypedObjectModel` (a Quickshell core type, not one of the three plugin modules read this session) — the exact QML-side consumption pattern (direct `Repeater { model: Pipewire.nodes }` vs needing `.values`/`.count`+`.get(i)`) was not verified this session because `UntypedObjectModel`'s own type definition lives in Quickshell's core module, outside the three plugin `.qmltypes` files read.
**Why it happens:** Quickshell's model types have historically had a few different consumption idioms across versions; guessing wrong produces either a silent empty list or a runtime binding error.
**How to avoid:** A one-line Wave 0 QML probe (`Repeater { model: Quickshell.Services.Pipewire.Pipewire.nodes; delegate: Text { text: modelData.name } }` inside a throwaway window, following the exact `Probe.qml`/12-06 precedent already established in this repo) resolves this in minutes and should gate the first real panel task.
**Warning signs:** A `Repeater`/`ListView` bound to `.nodes`/`.devices` renders zero items even though the underlying service clearly has state (e.g., audio is audibly playing, or a paired bluetooth device exists).

### Pitfall 5: PipeWire node `properties` QVariantMap key names are ASSUMED, not verified
**What goes wrong:** Building the per-app row's app name/icon lookup around a specific key like `properties["application.name"]` or `properties["application.icon-name"]` without confirming those exact keys are populated on THIS PipeWire/wireplumber build for the applications actually in daily use (browsers, Spotify, Discord — all AUR-installed per this repo's `install.sh`).
**Why it happens:** `properties` is declared as a generic `QVariantMap` in the qmltypes (`[VERIFIED: quickshell-service-pipewire.qmltypes:442-449]`) — Quickshell passes through PipeWire's own property dictionary verbatim, so the key names are PipeWire's standard convention (`application.name`, `application.icon-name`, `media.name`, `node.name` are the widely-documented PipeWire property keys) `[ASSUMED — PipeWire's own metadata convention, not Quickshell-specific, not verified live against a real running node this session]`.
**How to avoid:** A live probe (same mechanism as Pitfall 4) dumping `JSON.stringify(node.properties)` for a real playing stream (e.g., a browser tab playing audio) before building the per-app row's name/icon binding.
**Warning signs:** Per-app rows all show a blank or fallback name/icon despite streams clearly being present in `nodes`.

## Code Examples

### Wifi device resolution (from the verified class hierarchy)
```qml
// Source: derived from quickshell-network.qmltypes read directly this
// session (Networking singleton lines 349-432, NetworkDevice lines
// 244-348, WifiDevice lines 433-468, DeviceType enum lines 68-90)
import Quickshell.Networking

property var wifiDevice: null
Component.onCompleted: {
    // Exact UntypedObjectModel iteration shape needs Wave 0 live
    // verification (Pitfall 4) — Repeater-based consumption is the
    // safest starting assumption, shown here as a function-style
    // resolution for use inside a backend adapter.
}
```

### Wifi connect-with-password flow (D-15-14's security-driven native call)
```qml
// Source: WifiNetwork.connectWithPsk verified at
// quickshell-network.qmltypes:528-532; Network.forget at line 196;
// ConnectionFailReason enum values verified at lines 19-31
function attemptConnect(network, psk) {
    if (psk !== "")
        network.connectWithPsk(psk);   // PSK travels over D-Bus, never a command line
    else
        network.connect();
}
```

### Bluetooth adapter toggle (D-15-01's Bluetooth tile verb)
```qml
// Source: BluetoothAdapter.enabled verified read/write at
// quickshell-bluetooth.qmltypes:28-36; Bluetooth.defaultAdapter at
// lines 378-388
import Quickshell.Bluetooth
Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
// D-15-26 case 3's null check: Bluetooth.defaultAdapter can be null
// (property is a nullable pointer per the qmltypes isPointer:true with
// no isPropertyConstant guarantee against null) — guard every read.
```

### Master volume + mute (PANEL-02)
```qml
// Source: Pipewire.defaultAudioSink verified at
// quickshell-service-pipewire.qmltypes:49-58; PwNodeAudioIface.volume/
// muted verified at lines 327-344 (volume: read="averageVolume",
// write="setAverageVolume"; muted: read="isMuted", write="setMuted")
import Quickshell.Services.Pipewire
property var sink: Pipewire.defaultAudioSink
// slider:
onMoved: if (sink && sink.audio) sink.audio.volume = sliderValue
// mute icon:
onClicked: if (sink && sink.audio) sink.audio.muted = !sink.audio.muted
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| CLI-wrapper shell scripts for network/bluetooth/audio control surfaces (this repo's own `nmtui-launch.sh` — `[VERIFIED: hypr/.config/hypr/scripts/nmtui-launch.sh, read directly this session]` — a kitty+nmtui launcher shim, D-17 from an earlier phase) | Native Quickshell D-Bus service bindings, reactive properties, no subprocess per interaction | This phase | `nmtui-launch.sh` stays as an existing, untouched fallback path (not retired — additive-only milestone) but the new panel does not reuse or extend it; worth a one-line note in the plan that this script's existence was checked and found non-overlapping (it opens a floating terminal running `nmtui`, a fully separate UI, not a component the panel can share). |

**Deprecated/outdated:** none specific to this phase — the Quickshell service bindings used here are themselves the current state of the art for this exact use case in the Quickshell ecosystem as of the installed 0.3.0-2 version.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | PipeWire node `properties` QVariantMap uses standard keys (`application.name`, `application.icon-name`, `media.name`) for per-app identification | Common Pitfalls / Pitfall 5 | Per-app mixer rows show blank names/icons; needs a live probe fallback (e.g. `node.name` or `nickname`, both of which ARE typed/verified properties) |
| A2 | `preferredDefaultAudioSink`/`Source` writes actually re-route already-open streams, not just new ones | Common Pitfalls / Pitfall 3 | PANEL-02's device picker would silently fail to move audible playback, discovered only at a render/UAT gate rather than in planning |
| A3 | `UntypedObjectModel` (nodes/devices lists) is consumable via a plain `Repeater { model: ... }` binding without an intermediate `.values`/`.get()` accessor | Common Pitfalls / Pitfall 4 | Every list in all three panels renders empty; blocks all three panels simultaneously if wrong, so this should be the very first Wave 0 check |
| A4 | The `request*`-prefixed signals on `Network`/`NetworkDevice` (`requestConnect`, `requestForget`, etc.) are NOT meant to be called as the primary action path — the plain-named invokable methods (`connect()`, `forget()`, etc.) are | Architecture Patterns / Anti-Patterns | If backwards, calling `.forget()` directly might be a no-op and the panel needs to emit `requestForget()` instead — a quick live test resolves this in one line |
| A5 | end-4/dots-hyprland and Caelestia shell's actual QML source for quick-settings tiles, wifi/bluetooth panel layouts, and per-app volume rows was NOT re-fetched this research session (no network fetch of their live repos was performed) | User Constraints / External references | Component-level visual conventions the CONTEXT.md explicitly asked to be source-checked (D-15-01's six-tile-row, D-15-13's per-app row shape) are only corroborated by CONTEXT.md's own prior citation, not independently re-verified here — recommend the planner or a render-gate task do a fresh shallow-clone read of both repos' current QML source, following the exact discipline `14-05`'s SUMMARY already established (study real source, not a screenshot) |

**If this table is empty:** N/A — see entries above; all five should be resolved as cheap Wave 0 checks before the bulk of panel-body implementation, following the exact precedent this repo already used for `12-06`'s singleton-resolution proof and `14-02`'s FILL-axis `grabToImage` proof.

## Open Questions

1. **Live scan cadence, `cancelPair` mid-pairing, `peaks` cost** — deferred research items 3 from CONTEXT.md remain genuinely open; qmltypes files confirm the methods/properties EXIST (`scannerEnabled`, `cancelPair`, `PwNodePeakMonitor`) but not their live runtime behavior/cost on this exact build. Recommendation: fold into the same Wave 0 live-probe pass as the Assumptions above rather than a separate research round.
2. **QtQuick `Popup` viability inside a Wayland layer-shell surface** — CONTEXT.md's deferred item 2, explicitly non-blocking (both D-15-12 and D-15-19 already route around it). Recommendation: leave genuinely deferred; do not spend planning time on it unless a future surface needs it.
3. **Six-across tile legibility for "Do Not Disturb"** — CONTEXT.md's deferred item 5, a font-rendering measurement question, not an API question; belongs at the render gate, not in this research.
4. **end-4/Caelestia source-check** — see Assumption A5. Recommendation: the planner should schedule a short, explicit "read the real QML source" step (mirroring `14-05`'s Media tab redesign precedent) before or during the first panel-body plan, rather than relying on this research's secondhand citation of the CONTEXT.md summary.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-------------------|
| V2 Authentication | No | This phase manages device/network credentials (wifi PSK), not user authentication to the shell itself. |
| V3 Session Management | No | Not applicable — no session/token concept introduced. |
| V4 Access Control | No | Single-user desktop, no privilege boundary crossed by this phase's own code (D-Bus calls run as the existing user session, same as nm-applet/blueman already do). |
| V5 Input Validation | Yes | The wifi password field is the one user-text-input surface this phase adds. `Quickshell.Networking`'s `connectWithPsk(psk: QString)` is a typed Q_INVOKABLE method — no string concatenation into a shell command occurs (this is the whole point of the native-binding choice), so classic injection is structurally not possible via this path. The one input-validation obligation is UI-level: don't attempt to pre-validate PSK length/charset client-side beyond what NetworkManager itself will reject (D-Bus call failure + `connectionFailed(NoSecrets)` is the correct failure surface, not a hand-rolled regex gate). |
| V6 Cryptography | No — delegated | Wifi PSK handling (WPA2/WPA3 key derivation, secret storage) is entirely NetworkManager's responsibility via its own D-Bus secrets agent; the panel never touches raw cryptographic material beyond passing the plaintext PSK string to `connectWithPsk`, which is the standard, minimal-exposure integration point. |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|----------------------|
| PSK exposure via process argv (`/proc/<pid>/cmdline` readable by any co-resident process) | Information Disclosure | Already the deciding rationale for D-15-14's native-binding choice — `connectWithPsk` sends the PSK over D-Bus, never as a command-line argument. Verified structurally sound: no `Process`/`Quickshell.Io` command array in this phase's design ever carries a secret value, matching the repo's existing T-14-13 fixed-argv discipline. |
| Fixed-argv discipline for Advanced-button launches | Tampering (command injection) | All three Advanced-button `Process` commands (`pavucontrol`, `nm-connection-editor`, `blueman-manager`) must be literal fixed argv arrays with zero interpolated/state-derived elements — matches `QuickToggles.qml`'s established T-14-13 pattern exactly (`[VERIFIED: QuickToggles.qml:277-320]`). |
| D-Bus multi-writer race (two clients writing PipeWire volume/NM connection state near-simultaneously) | Tampering / (not a real threat here) | Explicitly assessed and dismissed as a genuine security threat in D-15-24's own reasoning — PipeWire/NetworkManager/BlueZ are all designed for concurrent multi-client read/write, and D-22's truth-driven rendering model means the panel always displays actual backend state regardless of which client wrote it last. This is a UX-consistency question (does the panel refresh live?), not a security boundary. |
| Second `org.freedesktop.Notifications` owner appearing while a panel is open | Spoofing (of the single legitimate owner) | Already the exact thing `quickshell-doctor`'s existing check enforces (`[VERIFIED: hypr/.config/hypr/scripts/quickshell-doctor:295-304]`); D-15-25 extends the same check to run "while a panel is summoned" rather than only at idle. No new mechanism needed, only a new invocation context for the existing one. |

## Sources

### Primary (HIGH confidence — read directly on this machine this session)
- `/usr/lib/qt6/qml/Quickshell/Networking/quickshell-network.qmltypes` — full class/method/signal/enum surface for `Quickshell.Networking`
- `/usr/lib/qt6/qml/Quickshell/Bluetooth/quickshell-bluetooth.qmltypes` — full class/method/signal/enum surface for `Quickshell.Bluetooth`
- `/usr/lib/qt6/qml/Quickshell/Services/Pipewire/quickshell-service-pipewire.qmltypes` — full class/method/signal/enum surface for `Quickshell.Services.Pipewire`
- `/usr/lib/qt6/qml/Quickshell/{Networking,Bluetooth,Services/Pipewire}/qmldir` — module names, plugin/typeinfo declarations
- `quickshell/.config/quickshell/shell.qml` — shell-root mounting pattern, `GlobalShortcut` registration shape, backend-instance sibling pattern
- `quickshell/.config/quickshell/modules/Dashboard.qml` — `PanelWindow`/`WlrLayershell`/`HyprlandFocusGrab` skeleton, layer posture, dismiss wiring
- `quickshell/.config/quickshell/modules/dashboard/QuickToggles.qml` — D-22 pending model, `startDetached()` precedent, tooltip mechanism, fixed-argv `Process` discipline
- `quickshell/.config/quickshell/modules/dashboard/Design.qml` — token singleton exact values (spacing/font/icon/tooltip-delay)
- `quickshell/.config/quickshell/modules/Colours.qml`, `Motion.qml` — role/token names available to panel QML
- `quickshell/.config/quickshell/shortcuts.json`, `hypr/.config/hypr/config/keybinds.lua:155-181` — declared-manifest keybind pattern for `Super+A`
- `hypr/.config/hypr/config/windowrules.lua:290-345` — `^quickshell-.*` family layerrule + per-namespace exact-match pattern
- `hypr/.config/hypr/scripts/quickshell-doctor` (namespace-discipline check lines 221-241, single-Notifications-owner check lines 295-304, XF86 key single-handler check line 313-328, swayosd one-step-per-press probes lines 353-426)
- `waybar/.config/waybar/config-athena.jsonc:28-364` — exact current `group/audio`/`network`/`bluetooth` module definitions and click handlers
- `install.sh:59-330,611-658` — `PACMAN_PKGS`/`AUR_PKGS` arrays, `verify_packages()` hard-fail mechanism
- `hypr/.config/hypr/scripts/nmtui-launch.sh` — existing NM entry point, confirmed non-overlapping
- Live shell commands this session: `pacman -Q quickshell`, `pacman -Si network-manager-applet`, `busctl --user list` (confirms current D-Bus owners incl. `org.freedesktop.Notifications`→swaync, `org.freedesktop.network-manager-applet`→nm-applet), `which bluetoothctl rfkill nmcli wpctl pactl`, `systemctl --user status swayosd-libinput-backend.service`

### Secondary (MEDIUM confidence)
- `15-CONTEXT.md`'s own recorded verified facts (grab exclusivity, free keybind letters, waybar layout details) — treated as corroborated since the underlying source files were independently re-read this session and found consistent.

### Tertiary (LOW confidence / not verified this session)
- end-4/dots-hyprland and Caelestia shell's actual current QML source for quick-settings tiles, wifi/bluetooth layouts, per-app volume rows — NOT fetched this session (see Assumption A5); CONTEXT.md's summary of prior discussion is the only source, itself sourced from user recollection/prior research passes rather than a fresh clone read in THIS session.

## Metadata

**Confidence breakdown:**
- Standard stack (native API surfaces): HIGH — read directly from installed `.qmltypes` files, cross-checked against `pacman -Q`.
- Architecture (panel lifecycle, D-Bus coexistence): HIGH — every reused pattern read from actual committed source with line citations; the one open item (`UntypedObjectModel` accessor shape) is explicitly flagged, not silently assumed.
- Pitfalls: HIGH for the ones grounded in qmltypes signatures (Bluetooth failure inference, Networking hierarchy); MEDIUM/flagged-ASSUMED for the two genuinely unverifiable-without-a-running-instance items (PipeWire property keys, `preferredDefaultAudioSink` write semantics).
- Security: HIGH — the phase's own design (native D-Bus bindings) already structurally avoids the one concrete threat pattern (PSK-on-cmdline) that applies here.

**Research date:** 2026-08-01
**Valid until:** Tied to `quickshell` package version — re-verify the qmltypes files if `quickshell` is upgraded past `0.3.0-2` before this phase executes (30-day estimate otherwise, matching Arch's own rolling-release cadence for this package).
