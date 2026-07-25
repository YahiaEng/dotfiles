# Feature Research

**Domain:** Quickshell/QML desktop-shell surfaces for a mature Arch + Hyprland rice (dashboard, audio/network/bluetooth panels, workspace overview, ambient wallpaper/cursor, spring-based motion language)
**Researched:** 2026-07-26
**Confidence:** HIGH for end-4/dots-hyprland and Caelestia (soramanew) — read directly from source: GitHub API directory listings + raw `.qml` file contents, not just README/blog summaries. MEDIUM for HyDE/ML4W/Omarchy/Aylur (websearch only, not source-read). LOW/uncorroborated claims are flagged inline.

## Method note (read this before the tables)

For end-4/dots-hyprland and Caelestia I did not rely on DeepWiki summaries alone — I walked the actual repo trees via the GitHub API and read the raw QML source of the specific files that answer this milestone's questions (sidebar/dashboard composition, overview implementation, volume/wifi/bluetooth dialogs, and the animation token files). Every claim below tagged **[source-read]** was verified this way and is HIGH confidence. Claims tagged **[websearch]** came from search snippets/DeepWiki only and are MEDIUM or LOW confidence as noted.

Repos read directly:
- `end-4/dots-hyprland`, path `dots/.config/quickshell/ii/` — the "ii" (Illogical Impulse) family, the default/flagship experience
- `caelestia-dots/shell` — Caelestia's standalone Quickshell shell

---

## Feature Area 1: Dashboard Drawer

### What it actually contains

**end-4/dots-hyprland ("right sidebar")** — this project's closest analog to "dashboard drawer" **[source-read: `SidebarRightContent.qml`, `CenterWidgetGroup.qml`, `BottomWidgetGroup.qml`]**:

Top-to-bottom column layout inside one panel:
1. `SystemButtonRow` — a row of system buttons (settings launcher, etc.) at the very top
2. `QuickSliders` — mic/volume/brightness sliders, conditionally shown per-slider from config (`sidebar.quickSliders.{showMic,showVolume,showBrightness}`)
3. **Quick-toggle grid** — pluggable between two visual styles (`ClassicQuickPanel` or `AndroidQuickPanel`, user-configurable "panel family"); toggle grid entries include Wi-Fi, Bluetooth, Night Light — each toggle taps to flip state instantly, and has an expand affordance that opens a **dedicated dialog** (see Feature Area 2) rather than cramming detail into the grid itself
4. `CenterWidgetGroup` — **is literally a `NotificationList`** (the notification center's list lives inside this dashboard, not a separate surface)
5. `BottomWidgetGroup` — a **tabbed, collapsible** card: Calendar / To-Do / Timer(Pomodoro), navigated via a vertical "navigation rail" of icon buttons, Ctrl+PageUp/PageDown to cycle tabs, collapses to a one-line "date • N tasks" summary row

Separately, a **second, independent sidebar** (`sidebarLeft`) holds AI chat, an "Anime" easter-egg widget, and a screen translator — this is end-4's analog to this project's existing AI-dashboard walker menu, not part of the "dashboard" proper.

**Caelestia (soramanew)** — genuinely swipeable tabs, not a single scroll **[source-read: `modules/dashboard/Content.qml`, `modules/dashboard/dash/*.qml`]**:

A horizontally-flickable `Flickable` with **4 tabs**, each independently toggleable in config (`Config.dashboard.show{Dashboard,Media,Performance,Weather}`):
1. **Dashboard tab** — `Calendar`, `DateTime`, a small `Media` mini-player, `Resources` (CPU/mem/etc at a glance), `SmallWeather`, `User` (profile picture/name — has a `FileDialog` "face picker" to set your own avatar)
2. **Media tab** — full media player: `CoverVisualiser`, `LyricList`/`LyricsAndSelector`/`LyricsInfo`, `BackgroundShapes` (ambient cover-art-derived shapes), `Details`
3. **Performance tab** — `HeroCard`, `BatteryTank`, `MemoryCard`, `NetworkCard`, `StorageCard`
4. **Weather tab** — full weather view (separate from the small dashboard-tab weather widget)

Navigation: drag/flick horizontally between tabs (threshold-based — drag past 1/10 of a page width commits to the next/prev tab, else it springs back), plus a `Tabs.qml` header row of icon buttons for direct tap-to-jump.

The **quick-toggle grid is NOT on Caelestia's dashboard** — it lives in a separate "Utilities" drawer (`modules/utilities/cards/Toggles.qml`) alongside idle-inhibit and screen-recording cards. **[source-read]** Toggle IDs confirmed in source: `wifi`, `bluetooth`, `mic`, `settings` (closes utilities, opens dashboard/settings), `gameMode`, `dnd`, `vpn` (conditionally hidden unless a VPN provider is configured). Toggles auto-split into two rows once there are more than 6.

Caelestia's `Shortcuts.qml` also has a `showall` shortcut that toggles **launcher + dashboard + osd + utilities together** as one bundle, and every panel-toggle shortcut is guarded by `if (hasFullscreen) return;` — panels refuse to open over a fullscreen client (games, video). **[source-read]**

### How it's invoked and dismissed

- **end-4**: `SUPER+N` toggles the right sidebar (dashboard), `SUPER+A`/`SUPER+B`/`SUPER+O` all toggle the left (AI) sidebar — redundant binds exist because of prior bind-shadowing history, a pattern this project has already lived through (Phase 7's Super-tap resolution). Bound via Hyprland's own `dispatch global quickshell:<name>` mechanism — Quickshell registers named "global shortcuts" that Hyprland's built-in dispatcher calls directly; **no custom IPC socket script is needed for this**. **[source-read: `hypr/hyprland/keybinds.lua`]**
- **Caelestia**: bound the same way, one `CustomShortcut` per panel name, resolved through a per-screen `ShellState`/`ScreenState` boolean (`screenState.dashboard = !screenState.dashboard`). **[source-read]**
- **Modality**: both are **non-modal overlays** on `wlr-layer-shell`, not modal dialogs — they render on top of everything via layer-shell but do not block input to the rest of the desktop. Keyboard focus is grabbed **on-demand** only while open (end-4: `WlrKeyboardFocus.OnDemand`; Caelestia: `HyprlandFocusGrab` on interactive panels like launcher/session). Click-outside-to-dismiss is implemented via a focus-grab-dismissed callback (`GlobalFocusGrab.dismissed → close panel`), not a raw click listener. **[source-read]**
- Neither flagship rice uses an edge-swipe/hover gesture as the *primary* way to open the dashboard — keybind is primary. Caelestia's bar config has a documented `showOnHover`/`dragThreshold: 20` pair for edge-based reveal, but this is corroborated only via a config-file grep, not a fully-traced code path — treat "hover-to-reveal" as a secondary, optional interaction (MEDIUM confidence), not the way most users open it day to day.

### Table stakes vs differentiators vs anti-features

| Category | Feature | Notes |
|---|---|---|
| Table stakes | Calendar widget | Present in both flagships; trivial complexity (QML `Calendar` bindable to date) |
| Table stakes | Media mini-controls on the dashboard | Both flagships surface *some* media widget on the dashboard's landing view even though a full player exists elsewhere — this project already has an AGS media card (Phase 10, MEDIA-01..04); the QML dashboard should embed a **compact** version of the same MPRIS data, not rebuild a second media backend |
| Table stakes | System resources at a glance | Both flagships show it (`Resources`/`Performance` tab); LOW complexity if you already have a stats-polling script |
| Table stakes | Quick-toggle grid | Every serious rice has one; end-4 nests it in the dashboard, Caelestia keeps it in a separate "Utilities" drawer — **either placement is defensible**, this project already has a toggle grid in swaync (BAR-05) that should be the model to extend, not replace |
| Differentiator | Weather widget | Both flagships have it, but it's the one dashboard widget that requires an external dependency (a weather API/service, network calls, API-key or geo-IP handling) — MEDIUM complexity, and the only dashboard widget with an ongoing external-service dependency risk |
| Differentiator | Tabbed/swipeable multi-view dashboard (Caelestia's 4-tab model) | Materially richer than a single scrolling column; higher QML complexity (gesture-driven `Flickable` + threshold commit logic) but the flagship-tier UX differentiator |
| Differentiator | Collapsible bottom card with nav-rail (end-4's Calendar/Todo/Timer tabs) | Good middle ground — tabbed richness without full swipe-gesture complexity |
| Differentiator | Profile picture / "face" widget (Caelestia's `User.qml`) | Cosmetic personalization touch; trivial complexity, low priority |
| Anti-feature | Duplicating the notification center inside the dashboard | end-4 does embed a `NotificationList` in its dashboard's `CenterWidgetGroup` — but this project already has a fully-shipped, themed swaync notification center (BAR-05, Phase 8) with its own toggle grid and sliders. Building a second notification list in QML creates two sources of truth for "what did I miss" and doubles the maintenance surface for zero net new capability. **Do not replicate this end-4 pattern here** — the dashboard drawer should link/defer to the existing swaync surface, not re-implement it |
| Anti-feature | A second independent quick-toggle grid that duplicates swaync's existing toggle grid (BAR-05) | Two toggle grids with two states to keep in sync is exactly the "anti-drift toggle grid" problem BAR-05 already solved once — if the QML dashboard needs toggles, it should read/write the *same* backing state BAR-05 already established, not own a second copy |

### Complexity and dependencies

- Depends on: Phase 11 (Quickshell viability gate) and Phase 12 (token pipeline) as hard prerequisites — nothing here is buildable before those land, per the milestone's own phase ordering.
- Calendar, quick-toggle grid, media mini-controls, system resources: **LOW-MEDIUM** each, mostly QML plumbing over data this project already has (MPRIS backend, existing toggle state, theming tokens).
- Weather: **MEDIUM**, the only widget introducing a new external-service dependency (API key/network/rate-limit handling) — scope this as its own vertical slice so a flaky weather API can't block the rest of the drawer.
- Full 4-tab swipeable model (Caelestia-style): **MEDIUM-HIGH** — worth deferring to "if time remains" rather than the MVP cut, given the milestone's own cut-candidate framing for ambient extras; a single-column dashboard (end-4-style) delivers most of the value at lower risk.

---

## Feature Area 2: Audio + Connectivity Panels (volume mixer, wifi, bluetooth)

### What each surface actually contains

**Per-app volume mixer — only end-4 has a real one. [source-read: `sidebarRight/volumeMixer/VolumeDialogContent.qml`, `VolumeMixerEntry.qml`]**

- Built on **`Quickshell.Services.Pipewire`** — a Quickshell built-in QML module wrapping PipeWire directly; no custom D-Bus/PulseAudio binding needs to be hand-rolled.
- Dialog layout: a scrollable list of `VolumeMixerEntry`, one per active PipeWire app-node (`Audio.outputAppNodes` / `Audio.inputAppNodes`), each entry = app icon (looked up by `application.icon-name` / `node.name` via the same icon-guessing logic as the app launcher) + click-icon-to-mute (desaturates the icon while muted) + (implied, cut off in the portion read) a per-app volume slider — plus a device-selector combobox at the bottom to change the **default** sink/source. Two identical dialogs exist: one for output apps (`isSink: true`), one for input/mic apps.
- **Caelestia has no per-app mixer at all.** `[source-read: modules/bar/popouts/Audio.qml]` — its Audio popout is only: output-device radio list, input-device radio list, a master-volume slider (scroll-wheel adjustable), and an "Open settings" button that hands off to an external app. This is a deliberate, confirmed scope decision by a flagship rice, not an oversight — **strong signal that a minimal in-shell mixer commonly stops at "pick device + master volume" and per-app sliders are the differentiator, not table stakes.**

**Wifi picker — both flagships converge on the same shape. [source-read: `wifiNetworks/WifiDialog.qml` (end-4), `bar/popouts/Network.qml` (Caelestia)]**

- Scanning-in-progress indicator (indeterminate progress bar) while a scan runs
- A list of visible networks (end-4: `Network.friendlyWifiNetworks`; Caelestia: `Nmcli.networks`, with a wireless/ethernet view toggle)
- Tap a network → password dialog if secured (Caelestia has a dedicated `WirelessPassword.qml`; end-4's `WifiNetworkItem` presumably does the same, not fully read)
- **Both have an explicit "Details"/"Open settings" button that shells out to an external app** (`Config.options.apps.network`) rather than reimplementing advanced settings in-shell — this is the load-bearing finding for scoping (see below)

**Bluetooth manager — same shape again. [source-read: `bluetoothDevices/BluetoothDialog.qml` (end-4), `bar/popouts/Bluetooth.qml` (Caelestia)]**

- Adapter enable/discovering toggles
- Discovering-in-progress indicator
- Device list (`BluetoothStatus.friendlyDeviceList` / `Bluetooth.defaultAdapter`)
- Same **"Details" → external app (`Config.options.apps.bluetooth`)** escape hatch in end-4 for anything beyond connect/disconnect

### What pavucontrol / nm-connection-editor / blueman provide that a minimal in-shell panel typically does NOT

This is the single most important finding for honest scoping, and it is corroborated by the fact that **both reference flagship rices themselves keep an explicit escape hatch to these exact external tools** rather than trying to reach full parity in QML:

- **pavucontrol** provides: per-**stream** port/profile switching (e.g. route one app to headphones while another stays on speakers), full device **profile** switching (analog stereo vs. surround/5.1, HDMI vs analog), per-device latency/loopback controls, and configuration-tab hardware controls beyond simple mute/volume. A minimal panel (as built by end-4) gets you per-app mute + presumably a volume slider + default-device selection — it does **not** get you per-stream output routing or hardware profile switching without extra work.
- **nm-connection-editor** provides: full connection **editing** — static IP/gateway/DNS, VPN profiles (plugin-based, many VPN types), 802.1X enterprise authentication, hidden-SSID manual entry, connection priority/metric, proxy configuration, IPv6 settings. A minimal wifi picker (as built by both flagships) gets you "see networks, tap one, type a password" — it does **not** get you enterprise auth, static IP, or VPN profile management without falling back to the external tool.
- **blueman-manager** provides: OBEX file-transfer send/receive, PIN-code/passkey pairing dialogs for devices requiring manual pairing confirmation, per-device **service** browsing (which Bluetooth profiles a device advertises), trust management, and audio-profile switching for Bluetooth audio devices. A minimal panel gets you scan/connect/disconnect/forget — it does **not** get you file transfer, PIN-pairing flows, or per-device service/profile inspection.

**Recommendation for this project, following the flagship precedent exactly:** build the in-shell panels to the same intentionally-limited scope both references chose (device pick + basic list/toggle actions), and wire an explicit "Details"/"Advanced" button on each panel that launches the existing GUI app (pavucontrol / nm-connection-editor / blueman-manager) for anything beyond that. This is not a compromise invented for this project — it is the pattern the two best-regarded rices in the ecosystem both independently converged on.

### Table stakes vs differentiators vs anti-features

| Category | Feature | Notes |
|---|---|---|
| Table stakes | Wifi list + connect + password prompt | Both flagships; MEDIUM complexity — Quickshell has no confirmed built-in NetworkManager QML module the way it has one for Pipewire/Bluetooth, so this likely means D-Bus calls to NetworkManager directly or shelling out to `nmcli` (Caelestia's approach — its service is literally named `Nmcli`) |
| Table stakes | Bluetooth device list + connect/pair/forget | Both flagships; **Quickshell does ship a built-in `Quickshell.Bluetooth` module** (`Bluetooth.defaultAdapter`, `BluetoothDevice`) confirmed in both codebases — LOW-MEDIUM complexity, most of the plumbing exists already |
| Table stakes | Master volume + output/input device switch | Caelestia's floor-level scope; do at minimum |
| Table stakes | Escape-hatch "Advanced" button to the real GUI app | Confirmed present in every panel of both flagships — treat as non-negotiable, not optional polish |
| Differentiator | Per-app volume mixer with per-app mute/slider | Only end-4 has this; genuinely differentiating and directly named in this milestone's scope. Built on Quickshell's native Pipewire service — **complexity is lower than it sounds** because the hard integration work (Quickshell↔PipeWire binding) is already solved upstream |
| Anti-feature | Full connection-editing (static IP, VPN profiles, 802.1X) in-shell | Neither flagship attempts this; both defer to nm-connection-editor. Building it would mean re-implementing a large fraction of NetworkManager's own GUI for a feature almost never used day-to-day |
| Anti-feature | OBEX file transfer / PIN-pairing flows in-shell | Neither flagship attempts this; low-frequency use case, high implementation cost (file picker, transfer progress, PIN entry state machine) for rare payoff |
| Anti-feature | Per-app audio **routing** (assign app X to output Y) beyond default-device switching | Not present in either flagship's per-app mixer (end-4's mixer controls mute + presumably volume, not per-app output routing) — resist scope creep toward pavucontrol's full per-stream-port matrix |

### Complexity and dependencies

- Bluetooth panel: **LOW-MEDIUM** — Quickshell ships `Quickshell.Bluetooth` natively (confirmed in both codebases), most binding work is already done upstream.
- Per-app volume mixer: **MEDIUM** — Quickshell ships `Quickshell.Services.Pipewire` natively; the remaining work is UI + reusing this project's existing icon-lookup logic (walker/elephant already do app/icon indexing — reuse that instead of reinventing `AppSearch.guessIcon`).
- Wifi panel: **MEDIUM-HIGH**, the one panel of the three without a confirmed Quickshell-native binding — expect either raw D-Bus-to-NetworkManager calls or `nmcli` shelling, both of which need scan-state polling and password-prompt state-machine work regardless of approach.
- All three panels depend on the toggle-grid state model from Feature Area 1 (wifi/bluetooth toggles live in the quick-toggle grid; the panels are the "expand" targets of those same toggles) — build the toggle grid first, panels second.
- All three should share one `WindowDialog`/`ToggleDialog` component pattern (end-4's approach: a generic dialog wrapper reused for Wifi/Bluetooth/NightLight/Volume) rather than four bespoke popup implementations — this is a reusability finding worth carrying into the requirements as an architectural constraint, not just a feature list item.

---

## Feature Area 3: Workspace Overview

### What the surface actually contains

**[source-read: `end-4/dots-hyprland`, `modules/ii/overview/{Overview,OverviewWidget,OverviewWindow,SearchBar}.qml`]** — this is the only one of the two flagships with a full-screen Exposé-style overview; **Caelestia does not have one** (see below).

- **Layout**: a grid of workspace tiles, `rows` × `columns` configurable (`Config.options.overview.rows/columns`), grouped into pages of `rows*columns` workspaces at a time (`workspaceGroup`), each workspace tile shows its number and contains live thumbnails of every window on it, scaled by a single `Config.options.overview.scale` factor. Order can be bottom-up or right-to-left (`orderBottomUp`/`orderRightLeft` config flags).
- **Live thumbnails**: each window is a `ScreencopyView` (Quickshell's built-in Wayland screencopy component) with `live: true`, `captureSource` bound to the Hyprland `toplevel` — i.e. genuinely live video-like previews, not periodically-refreshed screenshots. Compact windows below a size threshold switch to a smaller icon-only "compact mode" instead of trying to render a tiny live thumbnail.
- **Interactions confirmed in source**:
  - **Click a workspace tile** → `Hyprland.dispatch("hl.dsp.focus(...)")` + closes the overview (jump-to-workspace)
  - **Drag a window thumbnail onto a different workspace tile** → implemented via Qt `DropArea`/drag machinery on both the window (drag source) and workspace tile (drop target), with a hover-highlight state (`hoveredWhileDragging`) on the target tile while dragging
  - **Type while the overview is open** → live fuzzy-search over open windows (`SearchBar`/`SearchWidget`), auto-focuses the first match — the overview doubles as an Alt-Tab-style window switcher, not just a workspace grid
  - Windows on a workspace other than the currently-focused monitor's are rendered at reduced opacity (0.4) as a visual "elsewhere" cue
- **Invocation/dismissal**: `SUPER+Tab` toggles it (Hyprland global-dispatch mechanism, same as the dashboard). Runs on a dedicated `wlr-layer-shell` surface (`namespace: "quickshell:overview"`) with `keyboardFocus: OnDemand` while open, and uses the same `GlobalFocusGrab`/click-outside-dismiss pattern as the dashboard — **non-modal overlay, but keyboard-focus-grabbing while open**, consistent with the rest of the shell.

**Caelestia does not implement a full-screen overview.** Its closest analog is `modules/windowinfo/WindowInfo.qml` **[source-read]** — a small hover-triggered preview popup anchored to a single window's taskbar icon (shows one window's live preview + details on hover), not an Exposé-style all-workspaces grid. Caelestia's bar instead shows small per-workspace window icons inline (`bar.workspaces.showWindows`, `maxWindowIcons: 5`) rather than a dedicated overview surface. **This means end-4 is the primary and effectively only flagship reference for this feature area** — treat Caelestia's absence of it as a data point that a full overview is a genuinely large, optional investment, not something every top-tier rice ships.

### The research-gate question is answerable now, and the risk is lower than PROJECT.md assumes

PROJECT.md frames this feature as **"research-gated on the hyprexpo / `hyprland-toplevel-export-v1` plugin question."** Source-reading end-4's actual implementation resolves this:

- end-4's overview uses **`Quickshell.Wayland.ScreencopyView`** with a `Toplevel` capture source, and **`Quickshell.Wayland.ToplevelManager`** for window enumeration — both are Quickshell's own built-in QML types, confirmed against Quickshell's official docs (`quickshell.org/docs/.../Quickshell.Wayland/{ScreencopyView,ToplevelManager,Toplevel}`).
- `ToplevelManager` uses the standard, cross-compositor **`zwlr-foreign-toplevel-management-v1`** Wayland protocol.
- Live per-window screencopy (`ScreencopyView` with a `Toplevel` source) requires the compositor to support **`hyprland-toplevel-export-v1`** — but this is a **protocol Hyprland implements natively in the compositor itself**, not a separate plugin that needs `hyprpm` to install. It is architecturally unrelated to `hyprexpo` (which is a *different*, unrelated compositor-side Exposé effect plugin that end-4 does not use here at all).
- Net effect: **building this feature in Quickshell needs zero extra Hyprland plugins and zero `hyprpm` dependency** — it is pure QML/Quickshell application code calling Wayland protocols Hyprland already ships. A standalone third-party repo (`Shanu-Kumawat/quickshell-overview`) exists purely to package this exact pattern as a reusable module, corroborating that this is a known, repeatable technique, not an end-4-only trick.
- **This substantially de-risks the milestone's most uncertain feature.** The real remaining risk is not "does the protocol exist" (it does, confirmed) but ordinary QML/Quickshell implementation effort: drag-and-drop between workspace tiles, grid layout math, and the live-thumbnail performance characteristics under this project's actual Hyprland 0.56.0 build — which is exactly what the Phase 11 viability gate should be validating with a real `ScreencopyView` test, not a paper read of whether the protocol exists.

### Table stakes vs differentiators vs anti-features

| Category | Feature | Notes |
|---|---|---|
| Differentiator (not table stakes) | Full-screen live-thumbnail overview at all | Only one of the two flagships (end-4) has this; Caelestia deliberately doesn't. This is a genuine differentiator to build, not an assumed baseline — its absence in a rice does not read as "incomplete" the way a missing dashboard would |
| Differentiator | Drag window between workspaces from the overview | Confirmed in end-4; meaningfully increases implementation complexity (drag source + drop target + hover state) over a click-only grid |
| Differentiator | Type-to-search-and-jump while overview is open | Confirmed in end-4; turns the overview into a second app-switcher, arguably overlapping with this project's existing walker launcher — worth an explicit requirements decision on whether this duplication is wanted or should be left out to avoid two "type to find a window/app" surfaces |
| Anti-feature (candidate) | Reduced-opacity cross-monitor windows, xwayland indicators, compact-mode icon fallback, per-corner-radius masking | All present in end-4's implementation as visual polish on top of the core grid; genuinely nice but each is separately-cuttable detail work, not part of a minimal viable overview |

### Complexity and dependencies

- Depends on: Phase 11 viability gate (must prove `ScreencopyView`/`ToplevelManager` actually deliver live frames performantly on this exact Hyprland 0.56.0 build — this is the concrete thing "research-gated" should mean now, not "does the Wayland protocol exist") and Phase 12 motion tokens (entrance/exit choreography, see Feature Area 5).
- Grid layout + click-to-focus: **MEDIUM** — mostly layout math and Hyprland IPC calls this project already has experience with (existing `hyprctl`-based scripts).
- Live thumbnails via `ScreencopyView`: **MEDIUM**, contingent entirely on the Phase 11 gate's performance findings (multiple simultaneous live Wayland screencopy streams is the one part of this feature with real unknowns left).
- Drag-to-move-workspace: **MEDIUM-HIGH**, additive on top of the grid — sequence this as a follow-up slice after click-to-focus ships, not bundled into the first cut.
- Type-to-search: **LOW-MEDIUM** technically, but see the anti-feature note above on overlap with walker — this is a scope decision, not just an effort estimate.

---

## Feature Area 4: Ambient Extras (animated wallpaper, dynamic cursors)

### Animated/video wallpaper

**[source-read: `end-4/dots-hyprland`, `modules/ii/background/Background.qml`]** and **[source-read: `caelestia-dots/shell`, `modules/background/Wallpaper.qml`]**

- **end-4 supports video wallpapers** (`.mp4/.webm/.mkv/.avi/.mov` detected by extension), but the Quickshell layer itself does **not** render the live video frame-by-frame — it renders a **pre-generated static thumbnail** of the video (`Config.options.background.thumbnailPath`) as the actual QML background image, while a companion script directory (`scripts/videos/`, `scripts/thumbnails/`) exists for generating that thumbnail. The strong implication (consistent with community `mpvpaper` usage patterns confirmed via websearch — MEDIUM confidence, not directly source-read for the playback half) is that the *actual playing video* is rendered by a separate process (`mpvpaper`, layered beneath everything as the real Wayland-level wallpaper), and Quickshell's own background layer only needs a still frame for things like color-extraction, workspace-thumbnail backdrops, and parallax math — not for painting the moving picture itself.
- end-4's background layer additionally implements: **parallax** (wallpaper shifts based on which workspace is focused, `parallax.workspaceZoom`/`autoVertical`/`vertical` config), and **hide-on-fullscreen** (`hideWhenFullscreen` — the background layer's `visible` binding checks for a fullscreen client on that monitor and hides itself), plus an opt-in "work safety" content-sensitivity check that blurs/hides the wallpaper based on filename keywords + network SSID keywords (a NSFW-wallpaper-at-work safeguard — cute but almost certainly out of scope for a personal single-user rig).
- **Caelestia's wallpaper module only supports static images** (`CachingImage`, with a "wallpaper missing" empty-state and a file-picker to select one) — **no video/animated wallpaper support confirmed in source**. This is a second data point (alongside the missing overview) that Caelestia is the more conservative/minimal of the two flagships on ambient-extras-style features; end-4 is the reference for this specific feature.
- `mpvpaper` itself (the actual video-wallpaper player, **[websearch, MEDIUM confidence]**) is a standalone wlroots-compatible tool (`mpvpaper OUTPUT /path/to/video`, or `'*'` for all outputs), commonly wrapped in a small systemd user service so it survives logout/login and can be paused (`mpvpaper-stop`) to save power/CPU when not visible — this project's existing pattern of dedicated systemd `--user` services (SwayOSD, cava) is a good precedent to follow rather than a raw exec.

### Dynamic cursors

**[websearch, MEDIUM-HIGH confidence — corroborated across the Hyprland wiki, hyprcursor standards doc, and the plugin's own repo]**

- "Dynamic cursors" in the Hyprland ecosystem is not a Quickshell/QML feature at all — it is **`VirtCode/hypr-dynamic-cursors`**, a **Hyprland compositor plugin** (installed via `hyprpm`) that works on top of `hyprcursor` (Hyprland's own modern cursor-theme format, which itself supports true multi-frame animated cursors via per-size delayed image sequences — distinct from and more capable than legacy XCursor).
- The plugin's actual effect: stretches/squishes the cursor shape based on movement velocity (a cartoon-style "squash and stretch" cue), plus a "shake to find" cursor-enlarge gesture similar to Windows/macOS.
- **This is architecturally independent of everything else in this milestone** — it is rendered by the Hyprland compositor itself, not by Quickshell/QML, and has zero interaction with the token pipeline's QML/GTK4/Hyprland-bezier render targets. It is thematically on-brand ("physics-flavored motion") but mechanically unrelated work.
- **Pitfall carried over from this project's own STACK research**: Hyprland plugins installed via `hyprpm` are ABI-coupled to the exact compositor build and can silently break on a Hyprland version bump, requiring a `hyprpm update`/rebuild. Treat this exactly like any other `hyprpm` plugin dependency this project already has to reason about — not free of the version-coupling risk just because it's visually minor.

### Table stakes vs differentiators vs anti-features

| Category | Feature | Notes |
|---|---|---|
| Differentiator | Video/animated wallpaper | Only end-4 confirmed to support it; genuinely visually striking but the actual video playback almost certainly lives outside Quickshell (a separate `mpvpaper` process) — the QML-side work is thumbnail generation + hide-on-fullscreen + optional parallax, not a video decoder |
| Differentiator | Wallpaper parallax on workspace switch | A nice, comparatively cheap add-on once static/video wallpaper rendering exists — reuses workspace-change events this project's Hyprland config already fires |
| Differentiator | Dynamic/squash-stretch cursor | Genuinely differentiating and visually distinctive, but note it is a **compositor plugin, not a shell feature** — lowest QML effort in the entire milestone (a hyprpm install + a few config lines), at the cost of a plugin-ABI coupling risk independent of everything else built this milestone |
| Anti-feature | "Work safety" NSFW-wallpaper auto-blur | end-4 has this; there is no plausible reason for a personal single-user rig to need it, and it adds a keyword-matching content-sensitivity system for zero benefit here |
| Anti-feature (scope discipline, not "bad idea") | Building video-wallpaper *playback* itself inside Quickshell/QML | Neither flagship renders live video through QML — both treat video wallpaper as an external-process concern and only touch a static derived thumbnail from QML. Attempting true in-QML video playback would be reinventing what `mpvpaper` already solves |

### Complexity and dependencies

- This entire feature area is explicitly the milestone's own designated first cut if time runs short (per PROJECT.md) — the research supports that framing: both sub-features are legitimately separable from the token pipeline and can be dropped without leaving anything half-built elsewhere.
- Video wallpaper: **MEDIUM** (thumbnail-generation script + hide-on-fullscreen binding + systemd service wrapper for `mpvpaper`), independent of Quickshell's dashboard/overview work.
- Dynamic cursor: **LOW** (hyprpm plugin install + config), fully independent of the Quickshell/motion-language track — could ship in any phase, or be cut entirely, without touching anything else.
- Neither ambient extra depends on the token pipeline (Phase 12) the way the dashboard/overview/panels do — they're the most decoupled feature area in the milestone, which is exactly why they're the correct cut candidate.

---

## Feature Area 5: Spring-Based Motion Language

### The central, milestone-relevant finding

**Neither flagship reference rice actually uses QML's native `SpringAnimation` type or literal mass/stiffness/damping physics anywhere in their shared animation infrastructure. [source-read, HIGH confidence — verified independently in both codebases' core animation-token files]**

- **end-4/dots-hyprland** (`modules/common/Appearance.qml`): defines a fixed table of **Material Design 3 Expressive motion tokens** — named duration+bezier-curve pairs such as `expressiveFastSpatial` (350ms), `expressiveDefaultSpatial` (500ms), `expressiveSlowSpatial` (650ms), `expressiveEffects` (200ms), plus MD3's standard `emphasized`/`emphasizedAccel`/`emphasizedDecel`/`standard`/`standardAccel`/`standardDecel` curves — each a literal cubic/multi-segment Bézier control-point array. Every animated property in the codebase (`Behavior on x/y/width/height/opacity`) uses `easing.type: Easing.BezierSpline` with `easing.bezierCurve: Appearance.animationCurves.<name>` — this is **fitted-curve, duration-based animation with named semantic tokens**, not physics simulation.
- **Caelestia** (`components/Anim.qml`, `CAnim.qml`, `AnchorAnim.qml`): an independent implementation of the **exact same Material Design 3 Expressive Motion System** — a `NumberAnimation` subclass with an enum of named types (`FastSpatial`/`DefaultSpatial`/`SlowSpatial`/`FastEffects`/`DefaultEffects`/`SlowEffects`/`Standard*`/`Emphasized*`) mapping to the same category of duration+bezier-curve token pairs, pulled from a `Tokens.anim` config singleton. Also duration-based bezier curves, not `SpringAnimation`.
- Both projects independently arrived at the **same underlying motion system (Google's Material Design 3 Expressive)** rather than at literal spring physics, despite one (Caelestia) explicitly branding itself as a "fluid, morphing shell." This is strong, cross-corroborated evidence that **"spring-like feel" in this ecosystem is achieved via carefully fitted Bézier duration tokens, not runtime mass/stiffness/damping simulation.**

**Implication for this milestone's own stated design decision** ("spring physics is the source of truth; CSS/Hyprland curves are a compile target" — see PROJECT.md Key Decisions): this project is choosing to be **more ambitious than either flagship reference**, not merely catching up to them. That is a legitimate, deliberate choice — QML's `SpringAnimation` type does exist and is a real, usable primitive — but the roadmap should not assume "match the reference rices' motion quality" implies "they used springs, so we're just doing the same thing." The actual bar both flagships hit was: a small, curated set of named duration+curve tokens applied *consistently* everywhere, not the specific physics model. **The requirements should treat "spring source of truth, fitted-curve compile targets" as this project's own differentiator to validate on its own merits (does it look/feel better than MD3 Expressive tokens in practice?), not as replicating an already-proven pattern.** This is also a natural fallback: if the mass/stiffness/damping-to-bezier fitting pipeline proves harder than expected, landing on a hand-curated MD3-Expressive-style token set (duration + bezier per semantic category) is a proven, lower-risk substitute that both flagship rices demonstrate is sufficient to reach flagship-tier perceived quality.

### How the reference rices actually choreograph entrance/exit and stagger

**[source-read across multiple files in both codebases]**

- **Single-scalar-drives-everything pattern (Caelestia, `modules/dashboard/Wrapper.qml`)**: the dashboard's entire entrance/exit is driven by **one** `offsetScale` property (0 = open, 1 = closed) with a single `Behavior on offsetScale { Anim {} }`. That one animated scalar simultaneously derives the panel's `anchors.topMargin` (slide off-screen above the top edge), `opacity` (fade), and `visible` (via `offsetScale < 1`). There is no separate slide animation and fade animation running independently and needing to be kept in sync — one curve, multiple derived properties, mathematically guaranteed to stay synchronized. This single-property technique, more than any specific curve shape, is very plausibly *the* actual source of the "polished, cohesive" feel — desynchronized slide/fade timings are a classic tell of amateur motion work, and this pattern makes that class of bug structurally impossible.
- **Neighbor-panel reflow (Caelestia, `modules/drawers/Panels.qml`)**: panels don't just animate themselves — opening one panel (e.g. the session/power menu) reactively pushes a *neighboring* panel (e.g. the OSD) out of the way, because the neighbor's anchor margin is bound to `otherPanel.width * (1 - otherPanel.offsetScale)`. The whole drawer stack behaves like a connected physical system even though no single animation spans multiple panels — this is composition of independently-simple animated scalars into an emergent choreography.
- **Asymmetric entrance vs exit curves (end-4, `Appearance.qml` `elementMoveEnter`/`elementMoveExit`)**: entrance uses `emphasizedDecel` (400ms, decelerating into place — a "settling" feel) while exit uses `emphasizedAccel` (200ms, faster and accelerating away). Exits are deliberately shorter and more linear/urgent; entrances are longer and more cushioned. This asymmetry (not a shared duration/curve for both directions) is a second concrete, source-verified technique behind "feels expensive."
- **Sequential fade-out → swap → fade-in for content replacement (both codebases: end-4's `BottomWidgetGroup` tab switch `SequentialAnimation`; Caelestia's `AnimLoader`)**: switching tab content is never a hard cut or a simultaneous cross-fade — it's fade-current-out (fast), swap the underlying `Loader.source`/`sourceComponent`, fade-new-in (with a small position offset in end-4's version — the new tab content enters from a ±10px vertical offset with the entrance curve, compounding a slide+fade rather than a pure fade). This "exit, swap, entrance" sequencing (not a cross-fade) is the specific technique for tab/content switches, distinct from the panel-level open/close technique above.
- **No literal per-item staggered-list-reveal animation was found in either codebase** in the files read (e.g. no `delay: index * N` pattern turned up in the dashboard/toggle-grid files examined). The "stagger" the milestone is asking about should probably be scoped as new/differentiating work rather than assumed present in the reference rices — if it's wanted (e.g. quick-toggle grid items cascading in one after another), that is going beyond what either flagship demonstrably does, which is worth flagging explicitly rather than assuming it's already a solved, copyable pattern.

### Table stakes vs differentiators vs anti-features

| Category | Feature | Notes |
|---|---|---|
| Table stakes | One consistent named-token set (duration+curve per semantic category) applied to every surface | Confirmed as the actual baseline both flagships hit — non-negotiable if the goal is "feels as good as end-4/Caelestia" |
| Table stakes | Single-scalar entrance/exit driving position+opacity+visibility together | The concrete, source-confirmed technique behind "no desync" — should be an explicit architectural requirement (one `Behavior`, multiple bound derived properties), not left to each surface's author to reinvent per-panel |
| Table stakes | Asymmetric entrance (slower, decelerating) vs exit (faster, accelerating) curves | Confirmed in end-4; a cheap, high-leverage rule to bake into the token pipeline from day one |
| Differentiator | True spring physics (mass/stiffness/damping) as the actual source of truth, compiled to fitted Bézier curves for CSS/Hyprland targets | This project's own stated ambition — genuinely goes beyond what either flagship rice does; real, not yet proven, complexity — validate perceived-quality gain empirically rather than assuming it's a strict improvement over hand-tuned MD3-style tokens |
| Differentiator | Reactive neighbor-panel reflow (opening one drawer visually displaces another) | A nice emergent-choreography touch confirmed in Caelestia; meaningfully increases coupling between panels' layout code, so scope this only once individual panels are stable |
| Anti-feature (risk to flag, not "don't build") | Staggered per-item list-reveal animations | Not found as an established pattern in either flagship's actual source in the files examined — if the roadmap wants this, treat it as new ground, budget accordingly, and don't assume "the reference rices already solved this, just copy it" |
| Anti-feature | Reinventing per-surface bespoke animation code instead of one shared token library | Both flagships centralize every duration/curve into one `Appearance`/`Tokens` singleton consumed everywhere — the anti-pattern to avoid is exactly what this milestone's "one token source" goal already guards against; reinforces that the existing Phase 12 plan is aimed at the right target |

### Complexity and dependencies

- This is squarely Phase 12's subject matter (token pipeline) and Phase 13's (motion retrofit across existing surfaces), and every other feature area in this document depends on it for its entrance/exit/stagger behavior — sequence it first, as the milestone plan already does.
- Implementing the MD3-Expressive-style fallback (named duration+bezier tokens, no physics) is **LOW-MEDIUM** complexity and a proven, de-risked target — both flagship codebases are a working reference implementation of exactly this.
- Implementing true mass/stiffness/damping-to-bezier-fitting as the source of truth is **MEDIUM-HIGH** complexity and unproven in this ecosystem specifically — no reference rice does this — treat it as this project's own R&D, with the MD3-token approach as an explicit, cheap fallback if the spring-fitting pipeline proves too costly relative to the payoff.
- The single-scalar entrance/exit pattern and asymmetric entrance/exit curves are **near-zero marginal cost** architectural rules to adopt regardless of the spring-vs-bezier decision — bake them into whatever component library Phase 12 produces from the start, since retrofitting them onto already-built panels later is exactly the kind of rework this project has learned (via BAR-01/BAR-03's shared-module lesson) to avoid.

---

## Feature Dependencies

```
Phase 11 (Quickshell viability gate)
    └──requires──> [everything below]

Phase 12 (token pipeline: colour + motion)
    └──requires──> Dashboard Drawer (entrance/exit/tab-switch motion)
    └──requires──> Audio/Connectivity Panels (dialog open/close motion)
    └──requires──> Workspace Overview (window-move, panel open/close motion)
    └──requires──> Ambient Extras (parallax easing, if built)

Quick-toggle grid (Dashboard Drawer, Feature Area 1)
    └──requires──> Per-app volume mixer / Wifi picker / Bluetooth manager (Feature Area 2)
                       (panels are the "expand" targets of toggle-grid entries in both flagships)

Existing swaync toggle grid + notification center (BAR-05, already shipped)
    └──conflicts with──> Re-implementing a second toggle grid / notification list inside the new QML dashboard
                       (two sources of truth for the same state — extend BAR-05's state, don't fork it)

Existing AGS v3 media card (MEDIA-01..04, already shipped)
    └──enhances──> Dashboard Drawer's media mini-widget
                       (QML dashboard should read the same MPRIS backend, not build a second one)

Workspace Overview: live thumbnails (ScreencopyView + ToplevelManager)
    └──requires──> Phase 11 viability gate proving multi-window live screencopy performance on this Hyprland 0.56.0 build
                       (NOT a hyprexpo/hyprpm-plugin dependency — resolved by this research to be a Quickshell-native, zero-plugin capability)

Workspace Overview: drag window between workspaces
    └──enhances──> Workspace Overview: click-to-focus grid
                       (build click-to-focus first, drag as a follow-up slice)

Workspace Overview: type-to-search-and-jump
    └──conflicts with (potentially)──> existing walker/elephant app+window search
                       (explicit scope decision needed: is a second "type to find a window" surface wanted, or should this be left out)

Video/animated wallpaper (Ambient Extras)
    └──requires──> external mpvpaper process + thumbnail-generation script
                       (Quickshell/QML side only needs the derived static thumbnail, not video decoding)

Dynamic cursor (Ambient Extras)
    └──independent of──> everything else in this milestone
                       (a Hyprland/hyprpm compositor plugin, not a Quickshell/QML feature; zero coupling to the token pipeline)
```

### Dependency notes

- **Everything requires Phase 11 and (for motion) Phase 12**: no feature area in this document is buildable in isolation from the milestone's own foundational phases — this matches PROJECT.md's stated phase ordering and this research finds no reason to deviate from it.
- **Toggle grid before panels**: in both flagship rices, the wifi/bluetooth quick-toggle is the entry point into the fuller wifi/bluetooth dialog (tap toggles state, "expand"/long-press opens the dialog) — building the panels before the toggle grid exists means building UI with no natural entry point yet.
- **Overview's real dependency is a performance question, not a plugin question**: this research changes the shape of the Phase-11-gate work for this specific feature — the gate should include an actual `ScreencopyView`-based multi-window live-thumbnail test, since that's the part with genuine remaining uncertainty, not a hyprexpo/hyprpm compatibility check.
- **Ambient extras are the correctly-chosen cut candidate**: both sub-features here are the most architecturally decoupled from the rest of the milestone (no token-pipeline dependency the way panels/dashboard/overview have), which independently supports PROJECT.md's own framing of this area as "first thing cut if the milestone runs long."

## MVP Definition

### Launch With (v3.0 minimum, matches PROJECT.md's Active scope)

- [ ] Quickshell viability gate (layer-shell, pointer input, focus, multi-monitor, hot reload) — nothing else is buildable without this proof
- [ ] Token pipeline emitting colour + a *first* motion system (start with MD3-Expressive-style named duration+bezier tokens as the proven baseline; treat spring-physics-as-source-of-truth as an enhancement layered on top once the baseline ships, not a blocking prerequisite for every other feature)
- [ ] Motion retrofit of existing surfaces using that first motion system
- [ ] Dashboard drawer: calendar + quick-toggle grid (reusing BAR-05's existing toggle state) + compact media widget (reusing the existing AGS/MPRIS backend) + system resources — the four widgets both flagships treat as baseline, explicitly *excluding* a second notification list
- [ ] Bluetooth panel (device list + connect/disconnect/forget + "Details" escape hatch to blueman) — lowest-risk of the three connectivity panels given Quickshell's native `Quickshell.Bluetooth` module
- [ ] Wifi panel (scan/list/connect/password prompt + "Details" escape hatch to nm-connection-editor)
- [ ] Per-app volume mixer (leveraging Quickshell's native `Quickshell.Services.Pipewire`) + master volume/device switch

### Add After Validation (v3.0 stretch, still in scope but sequence-able second)

- [ ] Workspace overview: click-to-focus grid with live thumbnails (contingent on the Phase 11 gate's screencopy-performance findings)
- [ ] Weather widget (isolate as its own vertical slice given the external-API dependency)
- [ ] Workspace overview: drag-window-between-workspaces (additive on top of click-to-focus)
- [ ] Spring-physics-to-fitted-curve compile pipeline as the eventual motion source of truth, superseding the v1 MD3-style token baseline once validated

### Future/Cut Candidate (explicitly named in PROJECT.md as first to cut)

- [ ] Animated/video wallpaper
- [ ] Dynamic cursor (hypr-dynamic-cursors plugin)
- [ ] Overview type-to-search-and-jump (pending an explicit decision on overlap with walker)
- [ ] Caelestia-style 4-tab swipeable dashboard (single-column dashboard delivers most value at lower risk)
- [ ] Wallpaper parallax-on-workspace-switch, "work safety" content-sensitivity blur (the latter recommended as a permanent anti-feature, not just deferred)

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Dashboard: calendar + toggle grid + media + resources | HIGH | LOW-MEDIUM | P1 |
| Bluetooth panel | HIGH | LOW-MEDIUM | P1 |
| Wifi panel | HIGH | MEDIUM-HIGH | P1 |
| Per-app volume mixer | HIGH | MEDIUM | P1 |
| Motion language (MD3-style token baseline) | HIGH | LOW-MEDIUM | P1 |
| Workspace overview (click-to-focus + live thumbnails) | HIGH | MEDIUM (contingent on Phase 11 gate) | P1-P2 |
| Weather widget | MEDIUM | MEDIUM | P2 |
| Overview drag-to-move | MEDIUM | MEDIUM-HIGH | P2 |
| Spring-physics-as-source-of-truth compile pipeline | MEDIUM (unproven differentiator) | MEDIUM-HIGH | P2 |
| Caelestia-style swipeable multi-tab dashboard | MEDIUM | MEDIUM-HIGH | P3 |
| Overview type-to-search | LOW-MEDIUM (overlaps walker) | LOW-MEDIUM | P3 |
| Animated/video wallpaper | MEDIUM (visually striking, low usage impact) | MEDIUM | P3 (explicit cut candidate) |
| Dynamic cursor | LOW-MEDIUM (novelty) | LOW | P3 (explicit cut candidate) |

**Priority key:**
- P1: Must have for v3.0 to meet its stated goal of shipping "the net-new widgets a top-tier rice has"
- P2: Should have, sequence after P1 lands and Phase 11 gate findings are in
- P3: Nice to have, matches PROJECT.md's own designated cut candidates

## Competitor (Reference Rice) Feature Analysis

| Feature | end-4/dots-hyprland | Caelestia (soramanew) | This project's plan |
|---------|---------------------|------------------------|----------------------|
| Dashboard structure | Single-column sidebar: sliders → toggle grid → notifications → tabbed calendar/todo/timer | 4-tab swipeable: Dashboard/Media/Performance/Weather | Start single-column (end-4 model, lower risk), defer swipeable multi-tab |
| Quick-toggle grid location | Inside the dashboard sidebar | Separate "Utilities" drawer | Either is defensible; reuse this project's existing BAR-05 toggle state either way |
| Per-app volume mixer | Yes, full per-app list + mute + device switch | No — device switch + master volume only | Build it (differentiator), on Quickshell's native Pipewire service |
| Wifi/Bluetooth panels | Yes, both with explicit "Details" escape hatch to external GUI apps | Yes, both, similar shape | Match this scope exactly — device pick/connect + escape hatch, not full parity with pavucontrol/nm-connection-editor/blueman |
| Full-screen workspace overview | Yes — grid, live thumbnails, click-focus, drag-to-move, type-to-search | No — only a per-window hover-preview popup | Build it (end-4 is the only usable reference); de-risked by confirming it needs zero extra Hyprland plugins |
| Video/animated wallpaper | Yes (thumbnail-in-QML + external mpvpaper process) | No — static images only | Build if time allows; explicit cut candidate per PROJECT.md |
| Dynamic cursor | Not found in either shell's own source (this is a separate Hyprland/hyprpm plugin, not part of either shell) | Not found | Independent hyprpm plugin install; near-zero QML cost, explicit cut candidate |
| Motion system | Material Design 3 Expressive tokens (fitted Bézier + duration, NOT literal spring physics) | Same MD3 Expressive system, independently implemented | This project is choosing to go further (spring-physics source of truth) — treat as its own differentiator to validate, with the MD3-token approach as a proven fallback |

## Sources

- **[source-read, HIGH]** `github.com/end-4/dots-hyprland` — repository tree walked via GitHub REST API (`/contents/...`) and raw file contents fetched directly from `raw.githubusercontent.com/end-4/dots-hyprland/master/...` for: `modules/common/Appearance.qml`, `modules/ii/{sidebarRight,sidebarLeft,overview,mediaControls,onScreenDisplay,dock,cheatsheet,background}/**`, `hypr/hyprland/keybinds.lua`
- **[source-read, HIGH]** `github.com/caelestia-dots/shell` — repository tree walked via GitHub REST API and raw file contents fetched directly from `raw.githubusercontent.com/caelestia-dots/shell/main/...` for: `components/{Anim,CAnim,AnchorAnim,AnimLoader}.qml`, `modules/dashboard/**`, `modules/drawers/{Drawers,Panels}.qml`, `modules/Shortcuts.qml`, `modules/utilities/cards/Toggles.qml`, `modules/bar/popouts/{Audio,Network,Bluetooth}.qml`, `modules/windowinfo/WindowInfo.qml`, `modules/background/Wallpaper.qml`
- **[websearch, MEDIUM]** Quickshell official docs (`quickshell.org/docs/.../types/Quickshell.Wayland/{ScreencopyView,ToplevelManager,Toplevel}`) — confirms `ScreencopyView`+`Toplevel` requires `hyprland-toplevel-export-v1`, `ToplevelManager` requires `zwlr-foreign-toplevel-management-v1`; corroborated by finding `Shanu-Kumawat/quickshell-overview` as an independent standalone implementation of the same pattern
- **[websearch, LOW-MEDIUM]** `mpvpaper` (GhostNaN/mpvpaper) usage patterns, systemd-service wrapping conventions for video wallpaper
- **[websearch, MEDIUM-HIGH]** Hyprland Wiki (`wiki.hypr.land/Hypr-Ecosystem/hyprcursor/`), Hyprland Standards (`standards.hyprland.org/hyprcursor/`), `VirtCode/hypr-dynamic-cursors` repo — confirms hyprcursor native animated-cursor support and the dynamic-cursors plugin's squash/stretch + shake-to-find behavior, and that it is a `hyprpm` compositor plugin independent of any Quickshell shell
- **[websearch, LOW]** pavucontrol, nm-connection-editor, blueman-manager feature summaries (ArchWiki, DeepWiki, manpages, project docs) used to build the "what a minimal panel typically lacks" comparison — corroborated qualitatively by the fact that both flagship shells' own source code independently defers to these exact tools via a "Details"/"Open settings" button
- **[websearch, LOW-MEDIUM]** HyDE, ML4W, Omarchy, Aylur/AGS mentions — surface-level only (DeepWiki/blog snippets, no source-read); one search result attributed an end-4-style "Overview" description to Omarchy that conflicts with this project's own existing STACK.md research (which characterizes Omarchy as Waybar-based) — treated as likely search-synthesis cross-contamination and given no weight; Omarchy, HyDE, ML4W and Aylur/AGS are noted here only as breadth context, not as sources for any specific claim above

---
*Feature research for: Quickshell/QML shell surfaces + motion language, v3.0 milestone*
*Researched: 2026-07-26*
