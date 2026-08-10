# Feature Research — v4.0 Shell Migration Surfaces

**Domain:** Desktop shell surfaces (status bar, notifications, OSD, power menu, media) for a personal Arch + Hyprland Quickshell (QML) rebuild
**Researched:** 2026-08-10
**Confidence:** HIGH — every claim about what end-4/dots-hyprland and Caelestia actually ship is sourced from a direct read of their real QML source files (via `raw.githubusercontent.com`, i.e. the actual file content, not a summary or blog post), matching this project's own established verification convention ("HIGH confidence — ground truth, not a web claim" per `.claude/CLAUDE.md`). See **Sources** for the exact file paths and links read. Table-stakes/differentiator/anti-feature judgments are this researcher's synthesis against `.planning/PROJECT.md` and `.planning/MILESTONES.md`, confidence HIGH for what the rices ship, MEDIUM for the prioritization calls layered on top.

**Scope:** BAR, NOTIF (popups + control centre), OSD, POWER (session/power menu), MEDIA (dashboard fold-in). Launcher/menu (walker/elephant) is explicitly out of scope per the milestone and not researched here.

---

## What The Reference Rices Actually Ship

### BAR

**Caelestia (`caelestia-dots/shell`) — one bar, vertical, right-edge.**
Source: [`modules/bar/BarWrapper.qml`](https://github.com/caelestia-dots/shell/blob/main/modules/bar/BarWrapper.qml), [`modules/bar/Bar.qml`](https://github.com/caelestia-dots/shell/blob/main/modules/bar/Bar.qml), [`modules/bar/components/workspaces/Workspaces.qml`](https://github.com/caelestia-dots/shell/blob/main/modules/bar/components/workspaces/Workspaces.qml), [`modules/bar/components/Power.qml`](https://github.com/caelestia-dots/shell/blob/main/modules/bar/components/Power.qml).

- **Single bar**, anchored `top+bottom+right` — a vertical column docked to the screen's right edge, not a horizontal top/bottom strip.
- **Auto-hide by width**, not visibility: `implicitWidth` animates between `Config.border.thickness` (a thin sliver, never fully gone) and the full content width, driven by `Config.bar.persistent || screenState.bar || isHovered`. Exclusive zone tracks the same state.
- **Entries are a config-driven ordered list** (`spacer`, `logo`, `workspaces`, `activeWindow`, `tray`, `clock`, `statusIcons`, `power`) rendered via `Repeater` + `DelegateChooser` — directly analogous to this project's `modules.jsonc` module-list pattern.
- **Workspaces render as one pill**: a single `StyledClippingRect` with `radius: Tokens.rounding.full` containing a fixed `Config.bar.workspaces.shown` count of workspace dots (paginated by `groupOffset`, not an ever-growing strip), an `ActiveIndicator` overlay that highlights the current dot, an `OccupiedBg` layer showing which slots have windows, and a separate blurred/scaled-in overlay for the Hyprland "special" (scratchpad) workspace.
- **Click a workspace dot → `hl.dsp.focus`/`workspace <id>` dispatch**; clicking the *active* dot again toggles the special workspace. **Scroll on the workspace pill** cycles workspaces (special-workspace aware).
- **Scroll gesture is bar-region-contextual**: top half of the vertical bar = volume, bottom half = brightness (`Bar.qml handleWheel`).
- **Per-widget contextual popouts**: hovering the tray, status-icons, or active-window entries opens a small flyout anchored to *that entry's* y-position (`checkPopout`), not one shared dropdown.
- **Power** is a small icon button (`power_settings_new`, error-colored) living directly in the bar, toggling `screenState.session`.

**end-4 (`end-4/dots-hyprland`, the "ii" shell) — one bar per monitor, horizontal, top or bottom.**
Source: [`modules/ii/bar/Bar.qml`](https://github.com/end-4/dots-hyprland/blob/main/dots/.config/quickshell/ii/modules/ii/bar/Bar.qml), [`modules/ii/bar/BarContent.qml`](https://github.com/end-4/dots-hyprland/blob/main/dots/.config/quickshell/ii/modules/ii/bar/BarContent.qml), [`modules/ii/bar/BarGroup.qml`](https://github.com/end-4/dots-hyprland/blob/main/dots/.config/quickshell/ii/modules/ii/bar/BarGroup.qml).

- **One bar instance per connected monitor** (`Variants { model: Quickshell.screens filtered by screenList }` + `LazyLoader`) — genuine multi-monitor fan-out. *(Flag: this project's own QS-03 per-screen fan-out was permanently dropped as infeasible on quickshell 0.3.0-2 in v3.0/D-13 — end-4 achieves this on the same toolkit version class, so it may be worth a narrow re-check, but the host has one physical monitor so it is not urgent.)*
- **Top or bottom placement**, config-selectable.
- **Auto-hide with two independent reveal triggers**: hover (a mouse region taller than the bar itself) **and** hold-Super-to-peek (`superShow`, with a configurable delay) — not just one hover mechanism.
- **`cornerStyle` config switch**: `0` = "Hug" (bar flush to the screen edge, `RoundCorner` decorators bridge into the screen's own corner radius) vs `1` = "Float" (bar is inset with its own rounded-rect background + drop shadow). This is the literal "island" vocabulary, and it's a single config flag, not four hand-built layouts.
- **Bar content is split into separate rounded-rect module islands** (`BarGroup`, a shared component with its own background `Rectangle` + `radius: Appearance.rounding.small`) — left group (resources + media), centre group (workspaces), right group (clock/utils/battery) — each its own pill, not one continuous strip.
- **Scroll gesture is side-of-bar-contextual**: left half = brightness, right half = volume, each side also toggling the corresponding sidebar on click, with a `ScrollHint` label that reveals on hover to teach the gesture.
- **Right-side status pill** bundles mute/mic-mute reveal icons, keyboard-layout indicator, unread-notification-count badge, network + bluetooth glyphs — click opens the right sidebar (control centre).
- **System tray with overflow menu**, optional weather module.
- **Consistent IPC + `GlobalShortcut` triple** (`toggle`/`open`/`close`) on every top-level surface (bar, OSD, session, media) — a reusable scriptable-surface pattern.
- *(end-4 also ships an entirely separate alternate shell, "Waffle" — a Windows-11-taskbar clone with a Start button, search, task-view previews, pinned app buttons. This is a different rice, not part of the "ii" reference language this project is redesigning toward, and is called out explicitly under Anti-Features below.)*

### NOTIF (popups + control centre)

**Caelestia.**
Source: [`modules/notifications/Notification.qml`](https://github.com/caelestia-dots/shell/blob/main/modules/notifications/Notification.qml), [`modules/notifications/Content.qml`](https://github.com/caelestia-dots/shell/blob/main/modules/notifications/Content.qml), [`services/Notifs.qml`](https://github.com/caelestia-dots/shell/blob/main/services/Notifs.qml), [`services/NotifData.qml`](https://github.com/caelestia-dots/shell/blob/main/services/NotifData.qml), [`modules/sidebar/NotifGroup.qml`](https://github.com/caelestia-dots/shell/blob/main/modules/sidebar/NotifGroup.qml), [`modules/sidebar/NotifDock.qml`](https://github.com/caelestia-dots/shell/blob/main/modules/sidebar/NotifDock.qml).

- Popups: a top/right-anchored `ListView` with `move`/`displaced` transitions so the stack smoothly reflows as cards enter/leave.
- Each card: **horizontal drag-to-dismiss** past `Config.notifs.clearThreshold` (fraction of width), **vertical drag-to-expand/collapse** past `Config.notifs.expandThreshold` (px), **hover pauses** the auto-dismiss timer (resumes on exit unless still pressed), **middle-click closes immediately**, **left-click invokes the sole action** if there is exactly one (`GlobalConfig.notifs.actionOnClick`), body supports **Markdown + hyperlinks** (link click opens externally and dismisses), a **circular ring progress indicator** overlays the app icon when `hints.value` is present (download/volume-style progress notifications), **critical urgency** swaps the whole card to an error color scheme, and a **copy-body-to-clipboard** action button is always present alongside any app-supplied actions.
- **Inter-surface height coordination**: the popup stack's own height is clamped so it never overlaps the OSD, session screen, or utilities panel if any of those are simultaneously open (`Content.qml` reads their `y` position).
- **Fullscreen-aware expiry**: `hasFullscreen` (checked against the focused monitor's active/special workspace) shortens the auto-dismiss timeout (`fullscreenExpireTimeout`) and can suppress popups entirely depending on `GlobalConfig.notifs.fullscreen`.
- **DND**: a persistent `dnd` property suppresses all future popups and fires a toast confirming the state change (`"Do not disturb enabled/disabled"`); popups are also auto-suppressed whenever any sidebar is already open (`ShellState.anySidebarOpen()`).
- **Persistence**: the full notification list is serialized to `notifs.json` and reloaded on shell restart — notifications outlive a Quickshell reload.
- **Control centre**: notifications grouped by `appName` into `NotifGroup` cards (shared icon/urgency-color chip, count badge, per-app collapse/expand independent of the popup's own expand state), a `NotifDock` header with a live unread count, opening the centre marks all outstanding popups as read.
- **`NotificationServer`** is instantiated directly inside `services/Notifs.qml` (`actionsSupported`, `bodyMarkupSupported`, `imageSupported`, `persistenceSupported` all `true`) — Caelestia's QML shell *is* the DBus notification server, not a client sitting in front of one.

**end-4.**
Source: [`services/Notifications.qml`](https://github.com/end-4/dots-hyprland/blob/main/dots/.config/quickshell/ii/services/Notifications.qml), [`modules/common/widgets/NotificationItem.qml`](https://github.com/end-4/dots-hyprland/blob/main/dots/.config/quickshell/ii/modules/common/widgets/NotificationItem.qml), [`modules/ii/notificationPopup/NotificationPopup.qml`](https://github.com/end-4/dots-hyprland/blob/main/dots/.config/quickshell/ii/modules/ii/notificationPopup/NotificationPopup.qml), [`modules/common/models/quickToggles/NotificationToggle.qml`](https://github.com/end-4/dots-hyprland/blob/main/dots/.config/quickshell/ii/modules/common/models/quickToggles/NotificationToggle.qml).

- Same **swipe-to-dismiss** gesture, independently implemented: horizontal drag past `dragConfirmThreshold`, middle-click to close, and a small polish detail — adjacent cards in the list rubber-band slightly while one is being dragged (`dragIndexDiff`-scaled offset).
- Popups **inhibited** while the right sidebar (control centre) is open OR `Notifications.silent` (DND) is set — same dual-inhibition pattern as Caelestia, arrived at independently.
- Grouped by `appName`, sorted by **most-recent activity per group** (`latestTimeForApp`), not alphabetically; persisted to `Directories.notificationsPath` (same durability-across-restart property as Caelestia).
- **Opening media controls calls `Notifications.timeoutAll()`** — explicitly dismisses all current popups so the media popup isn't visually competing with them (an explicit z-priority rule, same intent as Caelestia's height-avoidance, different mechanism).
- **DND is a first-class quick-toggle** (`NotificationToggle.qml`) living in the same quick-toggle grid as wifi/bluetooth/etc — this project already has an anti-drift quick-toggle grid shared between swaync and the walker menu, so this is a drop-in addition, not a new UI concept.
- Also instantiates its own `NotificationServer` directly — same "the shell owns the DBus server" architecture as Caelestia.

### OSD

**Caelestia.**
Source: [`modules/osd/Content.qml`](https://github.com/caelestia-dots/shell/blob/main/modules/osd/Content.qml), [`modules/osd/Wrapper.qml`](https://github.com/caelestia-dots/shell/blob/main/modules/osd/Wrapper.qml).

- Inline flyout panel in the same right-edge popout region as the session screen and notification popups, sliding via an `offsetScale` behavior (real position animation, not just opacity).
- **Volume, microphone, and brightness are three independently-shown sliders in one vertical column** (`FilledSlider`, animated "wavy" fill), each individually scroll-adjustable, each appearing/disappearing per its own config flag (`enableMicrophone`, `enableBrightness`) — so more than one can be visible simultaneously if more than one changed.
- Auto-hides after `Config.osd.hideDelay`; stays open while hovered; re-triggers its hide timer on every relevant `Connections` signal (volume/mute/source-volume/source-mute/brightness).

**end-4.**
Source: [`modules/ii/onScreenDisplay/OnScreenDisplay.qml`](https://github.com/end-4/dots-hyprland/blob/main/dots/.config/quickshell/ii/modules/ii/onScreenDisplay/OnScreenDisplay.qml), [`modules/ii/onScreenDisplay/OsdValueIndicator.qml`](https://github.com/end-4/dots-hyprland/blob/main/dots/.config/quickshell/ii/modules/ii/onScreenDisplay/OsdValueIndicator.qml).

- **Single floating pill**, **one indicator visible at a time** — `currentIndicator` switches between `volume`/`brightness`/`gamma` (night-light), no simultaneous multi-slider stack.
- Auto-hides after `Config.options.osd.timeout`; **hides immediately the instant the mouse hovers it** (not just pause-the-timer).
- Icon can **rotate or scale proportionally to the value** for extra motion feedback (used for the night-light gamma indicator).
- Has a distinct **"protection" danger-banner state** for an audio-sink hardware-safety trigger (`Audio.onSinkProtectionTriggered`) — a narrow, hardware-specific feature.
- Triggered via `Connections` on the `Brightness`/`Audio`/`Hyprsunset` service singletons, **not** on the keybind that caused the change — the OSD reacts to state regardless of source (media key, scroll gesture, external CLI, dashboard slider).
- **Neither reference has a caps-lock OSD indicator.** This project's SwayOSD already covers caps-lock — that is a requirement this project must preserve on its own, not something inherited from the rices.

### POWER (session/power menu)

**Caelestia — compact, bar-triggered, inline popout.**
Source: [`modules/session/Content.qml`](https://github.com/caelestia-dots/shell/blob/main/modules/session/Content.qml), [`modules/session/Wrapper.qml`](https://github.com/caelestia-dots/shell/blob/main/modules/session/Wrapper.qml), [`modules/bar/components/Power.qml`](https://github.com/caelestia-dots/shell/blob/main/modules/bar/components/Power.qml).

- **Four actions**: Logout, Shutdown, Hibernate, Reboot (plus a decorative `AnimatedImage` GIF between Shutdown and Hibernate) — **no Lock, no Sleep/Suspend, no Task Manager** in this component.
- Opens as an **inline popout** in the same right-edge region as OSD/notifications, not a full-screen overlay.
- **Full keyboard navigation**: arrow-key-equivalent `KeyNavigation` chain between buttons, **plus vim binds** (Ctrl+J/K, Tab/Shift+Tab, gated by `Config.session.vimKeybinds`), Enter/Return activates, Escape closes, first button auto-focuses on open, and the button re-focuses itself whenever the launcher closes (`onLauncherChanged`).
- Triggered from a small power-icon button embedded directly in the bar's own component tree, not a separate tool.

**end-4 — richer, full-screen, own dedicated action set.**
Source: [`modules/ii/sessionScreen/SessionScreen.qml`](https://github.com/end-4/dots-hyprland/blob/main/dots/.config/quickshell/ii/modules/ii/sessionScreen/SessionScreen.qml).

- **True full-screen overlay** (`PanelWindow` spanning the output, `WlrKeyboardFocus.Exclusive`), not an inline popout.
- **Eight actions** in a `GridLayout`: Lock, Sleep, Logout, Task Manager, Hibernate, Shutdown, Reboot, Reboot-to-firmware-settings.
- Same arrow-key `KeyNavigation` grid; **Escape or click-anywhere-outside cancels**; a **live subtitle** shows the currently-focused button's name; **the standout differentiator — in-context safety warnings**: a `SessionWarnings` service is polled and, if a package-manager process or an active download is detected, a red warning banner ("Your package manager is running" / "There might be a download in progress. Check your Downloads folder.") appears under the grid *before* the user can act.

Both keep the "opens in place, doesn't destroy the session until an action fires" shape this project's current wleave already has — the interaction differentiators (full keyboard nav with a visible focus indicator, an in-context safety check) are additive, not a structural rewrite of what wleave already proved.

### MEDIA (dashboard fold-in question)

**Caelestia does not put media on the bar at all.** The bar's entry list (`spacer`/`logo`/`workspaces`/`activeWindow`/`tray`/`clock`/`statusIcons`/`power`, confirmed by reading `Workspaces.qml`'s sibling `DelegateChoice` block in `Bar.qml`) has no media entry, and there is no `bar/popouts/Media.qml`. Media lives exclusively in:

1. **`modules/dashboard/dash/Media.qml`** — the small dashboard-tile widget: cover art ringed by a **wavy `CircularProgress`** showing track position, title/album/artist text, prev/play-pause/next transport buttons, and a **BPM-synced "bongocat" GIF** (`speed: Audio.beatTracker.bpm / …`).
   Source: [`modules/dashboard/dash/Media.qml`](https://github.com/caelestia-dots/shell/blob/main/modules/dashboard/dash/Media.qml).
2. **`modules/dashboard/media/`** — a fuller page: `CoverVisualiser.qml` renders the cover art through a **`MaterialShape.Cookie9Sided` cutout** with a **radial cava-driven bar visualizer** orbiting outward from the shape's own rotated edge (not a flat rectangular underlay); `Details.qml` adds title/artist/album, a `wavy`-animated seek slider (`StyledSlider`, draggable, `canSeek`-gated), and shuffle/loop/skip/play-pause transport; `LyricsAndSelector`/`LyricList` add synced-lyrics display.
   Source: [`modules/dashboard/media/CoverVisualiser.qml`](https://github.com/caelestia-dots/shell/blob/main/modules/dashboard/media/CoverVisualiser.qml), [`modules/dashboard/media/Details.qml`](https://github.com/caelestia-dots/shell/blob/main/modules/dashboard/media/Details.qml).
3. `modules/lock/Media.qml` — now-playing also surfaces on the lock screen (not researched in depth; out of this milestone's scope).

**No per-player volume control exists anywhere in either Media file.** Player selection is a single `Players.active` (`services/Players.qml`) with a `manualActive` override and an auto-dedup heuristic that collapses near-identical MPRIS sources (matching by track-title substring or by position/length proximity — handles the common "browser + embedded player" duplicate-source problem) — not a multi-card carousel.
Source: [`services/Players.qml`](https://github.com/caelestia-dots/shell/blob/main/services/Players.qml).

**end-4 puts media both on the bar AND in a dedicated bar-triggered popout.** A small `Media.qml` entry lives inside the left `BarGroup`; clicking/scrolling it (or a keybind) opens `mediaControls/MediaControls.qml`, which stacks **one `PlayerControl.qml` card per de-duplicated MPRIS player** (own dedup heuristic, near-identical to Caelestia's) — so multi-player handling is literally multiple simultaneous cards, not a switcher control. Each card independently: downloads the cover art locally, extracts a **dominant color via `ColorQuantizer`** and re-tints the whole card through an `AdaptedMaterialScheme`, shows a **live waveform (`WaveVisualizer`) drawn over a blurred cover-art background**, a seek slider, shuffle/loop/skip/play-pause, and a position/length readout. Opening it calls `Notifications.timeoutAll()`. Shows a "No active player — make sure MPRIS support is on" placeholder card when nothing is playing.
Source: [`modules/ii/mediaControls/MediaControls.qml`](https://github.com/end-4/dots-hyprland/blob/main/dots/.config/quickshell/ii/modules/ii/mediaControls/MediaControls.qml), [`modules/ii/mediaControls/PlayerControl.qml`](https://github.com/end-4/dots-hyprland/blob/main/dots/.config/quickshell/ii/modules/ii/mediaControls/PlayerControl.qml).

**What this means for the fold-in decision:** Caelestia's dashboard-only placement (no bar entry, no standalone popup) is the closer structural analog to what this project has already committed to (fold into the dashboard's Media tab, retire the standalone AGS card, no bar popout). The user's decision is validated by the closer reference, not contradicted by the other. The genuinely worth-copying pieces from both are the **visual/audio-reactive techniques** — Caelestia's radial-cava-around-shaped-cover-art is a real upgrade over this project's current flat cava underlay, deliverable entirely inside the existing dashboard Media tab with no new placement decision needed. end-4's per-track dominant-color re-tint is visually nice but is an anti-feature here (see below) — it competes with this project's single-palette-source architecture.

---

## Table Stakes (Users Expect These)

| Surface | Feature | Why Expected | Complexity | Notes |
|---------|---------|---------------|------------|-------|
| BAR | Clicking a workspace number switches to it | Basic bar function; currently dead in this project under waybar 0.15.0's compiled-in dispatch | LOW | Mechanical port of Hyprland IPC dispatch calls this project already uses elsewhere (Lua config) |
| BAR | Scroll over the bar adjusts volume/brightness contextually | Both references independently implement this; users on either rice would notice its absence | LOW | Region can be bar-half (end-4, horizontal) or bar-half-height (Caelestia, vertical) — adapt to this project's four layouts |
| BAR | A toggle/click opens the notification centre | Existing BAR-05 behavior; must survive the port | LOW | Already proven pattern in this project |
| BAR | Bar fully hides and reveals on hover (OLED) | Both refs implement auto-hide-by-size with hover reveal; this project's existing OLED-safe visibility system already requires this | LOW-MEDIUM | Existing single-owner visibility script (hypridle + fullscreen watcher + gaming mode) is the trigger source; port the QML-side hide animation only |
| BAR | System tray renders icons, supports click + right-click menu | Standard bar expectation, both refs ship it | MEDIUM | Needs `SystemTray` Quickshell API + overflow-menu handling |
| BAR | Clock and battery/resource indicators visible | Baseline bar content, both refs and this project's existing waybar layouts have it | LOW | Direct data-source port |
| NOTIF | Popups appear, stack without overlapping, auto-expire | Baseline notification behavior; existing swaync popups already do this | LOW-MEDIUM | Depends on which surface owns the DBus notification server — see Dependencies |
| NOTIF | Each popup dismissible by close button AND swipe | Both references independently implement swipe-to-dismiss — strong signal this is now a baseline expectation, not a nice-to-have | MEDIUM | New drag-axis interaction primitive this project's QML components don't have yet |
| NOTIF | Inline notification actions clickable directly on the popup | Existing swaync capability; both refs preserve it | LOW-MEDIUM | Straightforward once the server/actions plumbing exists |
| NOTIF | Notification centre lists history, grouped, clearable | Existing swaync control-centre capability (BAR-05); both refs group by app | MEDIUM | Grouping logic is cheap once notification data model exists |
| NOTIF | DND/silent toggle suppresses popups | Existing anti-drift quick-toggle grid already has this class of toggle | LOW | Wire into the existing shared-script toggle-grid pattern |
| OSD | Volume/brightness/caps-lock changes trigger a transient visible indicator | Existing SwayOSD behavior; must not regress | LOW | Caps-lock has no reference analog — this project must keep it on its own |
| OSD | OSD auto-hides after a short delay | Existing SwayOSD behavior; both refs do this | LOW | — |
| OSD | OSD shows the actual numeric/graphical value, not just an icon | Existing SwayOSD behavior; both refs show a progress bar/slider | LOW | — |
| POWER | All six current wleave actions preserved (Shutdown/Reboot/Suspend/Hibernate/Logout + Lock) | Established user-facing baseline; the milestone explicitly bars downgrades | LOW-MEDIUM | Mechanical port of existing command list; visual language (hue capsules) can be redesigned per milestone intent |
| POWER | Menu closeable by Escape / click-outside | Both refs do this; expected modal-dismiss behavior | LOW | — |
| MEDIA | Play/pause/next/prev transport | Baseline MPRIS UI; existing AGS card already has this | LOW | Direct port from existing MPRIS bash backend / shared reader |
| MEDIA | Seek bar shows position/duration, draggable to seek | Existing AGS card capability | LOW-MEDIUM | Both refs use a `canSeek`-gated slider; same shape |
| MEDIA | Cover art displayed | Baseline; existing AGS card already has this | LOW | — |
| MEDIA | Player switching when multiple MPRIS sources exist | Existing AGS card capability (player-switcher) | MEDIUM | Both refs solve the "duplicate source" problem with a dedup heuristic — worth porting the heuristic, not just the switcher UI |
| MEDIA | Audio-reactive visual element | Existing AGS card's cava underlay; explicit "don't lose this" per the milestone's fold-in framing | MEDIUM | Reuse existing cava data plumbing; only the rendering technique needs to change (see Differentiators) |

## Differentiators (What The References Do That This Project Doesn't — Yet)

| Surface | Feature | Value Proposition | Complexity | Notes |
|---------|---------|--------------------|------------|-------|
| BAR | Per-widget contextual popouts anchored to the hovered entry (Caelestia) | Richer glanceable info (battery %, tray item name, active-window title) without opening the full notification centre — genuinely faster than today's all-or-nothing swaync overlay | MEDIUM | New interaction pattern; this project's `PanelDialog.qml` is one fixed dialog, not a per-entry-anchored flyout system |
| BAR | Dual auto-hide reveal trigger — hover **and** hold-Super-to-peek (end-4) | Serves the OLED constraint directly: bar can default fully hidden (not just low-luminance) while staying reachable without touching the mouse | LOW-MEDIUM | Wire a `GlobalShortcut` into the existing single-owner visibility script; no redesign of that script needed |
| BAR | Config-selectable "island" `cornerStyle` (hug vs float, end-4) implemented as one shared component | Gives the four existing layouts (full/athena/floating/vertical) one implementation instead of four independently hand-tuned CSS/QML trees — directly reduces the maintenance cost this milestone is trying to pay down | MEDIUM | `BarGroup`-style shared pill component; a real architectural investment, not just visual polish |
| NOTIF | Inter-surface height/z coordination — notification stack shrinks to avoid overlapping OSD/power/dashboard when more than one is open (Caelestia); opening media/notification-centre explicitly dismisses stale popups (both refs) | This project's swaync/AGS/dashboard currently have zero awareness of each other's on-screen geometry — surfaces can visually collide today | MEDIUM | Needs a small shared-state singleton exposing each surface's occupied geometry — new but self-contained, same shape as `GlobalStates` in end-4 |
| NOTIF | Fullscreen-aware notification suppression/shortened-expiry (Caelestia) | Direct hook for this project's existing gaming-mode + Hyprland fullscreen socket2 watcher — swaync cannot use that signal today | LOW | Reuse the existing fullscreen watcher as the suppression trigger instead of writing a new one |
| NOTIF | DND surfaced as a standard quick-toggle-grid entry (both refs) | Drop-in addition to the already-existing anti-drift shared toggle grid; no new UI concept | LOW | — |
| POWER | In-context safety warnings before a destructive action (package-manager-running / download-in-progress banner, end-4) | A genuinely new capability nothing in this project has today, and it maps almost exactly onto the project's own unresolved MAINT-02 Logout teardown-hazard concern (an unkillable-client-during-teardown risk class) | LOW-MEDIUM | One new `Process`/`Timer` polling a pacman lock file / active pacman process; self-contained, no cross-surface dependency |
| POWER | Full keyboard-navigable action grid with visible per-button focus state and vim binds (both refs) | Current wleave's documented interaction is hover/focus name-reveal; a full arrow-key/vim `KeyNavigation` chain with a visible focus ring is a concrete step up in accessibility and speed for a keyboard-first Hyprland user | LOW | Boilerplate `KeyNavigation` chain; similar shape already partly used in this project's dashboard tab navigation |
| OSD | Multiple simultaneous sliders (volume + mic + brightness shown at once if more than one changed recently, Caelestia) | Reduces "which one just changed?" ambiguity that the current single-indicator SwayOSD (and end-4's single-indicator model) both have | LOW-MEDIUM | Column of independently-shown sliders instead of one swapped indicator |
| MEDIA | Radial audio-reactive visualizer wrapped around a shaped (non-rectangular) cover-art cutout (Caelestia's `Cookie9Sided` + orbiting cava bars) | A genuine visual upgrade over the current AGS card's flat blurred-art-plus-underlay cava treatment, deliverable entirely inside the existing dashboard Media tab | MEDIUM | Requires learning Quickshell's `Shape`/`ShapePath`/`PathAngleArc` QML API — new rendering technique for this project; existing cava data plumbing is reusable as-is |
| MEDIA | Cross-source player dedup heuristic (both refs) | Cleanly solves the "same track shown twice from two MPRIS sources" problem neither reference treats as optional | LOW-MEDIUM | Small, well-specified algorithm (match by track-title substring or position/length proximity); cheap to port |

## Anti-Features (Do Not Copy)

| Surface | Feature | Why It's In The Reference | Why It's Wrong Here | Alternative |
|---------|---------|----------------------------|----------------------|-------------|
| (general) | AI chat sidebar (end-4's `sidebarLeft/aiChat/*`) | end-4 ships a built-in LLM chat panel as a shell feature | Explicitly out of scope: "no custom AI assistant widgets" (PROJECT.md) | Keep the existing AI dashboard as launchers + workspace only |
| (general) | Full GUI settings app (end-4's `ContentPage`/`ConfigSlider`/`ConfigSwitch` settings family; end-4's alternate "Waffle" shell entirely) | end-4 ships an in-shell settings UI and a second, Windows-11-styled shell with its own Start menu/search/task-view | Explicitly out of scope: "no full GUI settings app" (PROJECT.md); Waffle is a different rice/interaction model, not the "ii" reference language this milestone targets | Settings menu keeps launching existing external tools, as today |
| POWER | 8-action grid incl. "Reboot to firmware settings" (end-4) | end-4's session screen exposes a UEFI firmware-reboot action | Scope creep beyond the milestone's named requirements; requires UEFI capability detection this project has never touched, for a rarely-used action | Keep the existing six-action wleave set; revisit only if separately requested |
| MEDIA | Per-track dominant-color extraction + card re-tinting (end-4's `ColorQuantizer`/`AdaptedMaterialScheme`) | end-4 downloads cover art and recolors the whole media card to match it per-track | Directly conflicts with this project's Key Decision that every themed surface consumes the palette via `@import` from `~/.local/state/theme/`, never a copied/derived color source — per-track tinting would be a second, competing color source | Keep the Media tab on the theme-engine palette; skip per-track tinting |
| OSD | Audio-sink "protection" danger banner (end-4's `onSinkProtectionTriggered`) | end-4 has a specific hardware/PipeWire safety signal it surfaces as a red OSD banner | This project's audio stack has no known equivalent trigger; building a banner for a signal that never fires is speculative, untestable scope | Skip; revisit only if a real hardware-safety signal is identified |
| MEDIA / POWER | Decorative mascot GIFs (Caelestia's BPM-synced "bongocat", end-4's session-screen animated GIF) | Novelty personalization touches in both rices | Not a themeable/maintainable UI element — needs a new asset-management path outside theme-engine for a purely cosmetic feature | Skip |
| BAR | Waffle-style always-expanded taskbar app buttons + task previews (end-4's `waffle/bar/*`) | A completely different shell (Windows-11 taskbar clone) end-4 also happens to ship | Different interaction model (app-pinning/task-switching) than a top/side status bar; not what "QML bar" means for this project's redesign | N/A — not applicable to this milestone's bar |

---

## Feature Dependencies

```
[Notification-server ownership decision]
    └──gates──> [DND toggle in QML]
    └──gates──> [Notification grouping in QML control centre]
    └──gates──> [Notification persistence across shell restart]
    └──gates──> [Swipe-to-dismiss + inline actions as *first-class* data, not just UI chrome]
    └──gates──> [swaync retirement timing — cannot retire swaync while it's still the DBus server]

[Existing OLED single-owner visibility script (hypridle + fullscreen watcher + gaming mode)]
    └──reused-by──> [BAR auto-hide]
    └──reused-by──> [NOTIF fullscreen-aware suppression]

[Existing shared MPRIS reader (waybar + AGS card today)]
    └──reused-by──> [MEDIA dashboard fold-in]
    └──reused-by──> [Cross-source player dedup heuristic]

[Existing dashboard Media tab (DASH-01..10, shipped Phase 14)]
    └──required-by──> [MEDIA fold-in]

[Existing anti-drift quick-toggle grid (swaync ⇄ walker menu)]
    └──required-by──> [DND quick-toggle]
    └──must-be-repointed-by──> [NOTIF control centre replacing swaync's grid]

[BAR rebuild]
    └──architecturally-anchors──> [Per-widget contextual popouts]
    └──architecturally-anchors──> [NOTIF/OSD/POWER "avoid overlapping the bar" coordination]
```

### Dependency Notes

- **The notification-server ownership question is the single largest gate in this whole research area.** Both reference rices instantiate `NotificationServer` directly inside their own QML singleton (`services/Notifs.qml` in Caelestia, `services/Notifications.qml` in end-4) — their QML shell *is* the DBus `org.freedesktop.Notifications` provider, not a client layered in front of one. Only one process can hold that DBus name at a time. This means:
  - If the QML notification surface becomes the actual server, **swaync must be retired in the same phase**, not split into "popups now, centre later" — there is no valid intermediate state where swaync half-owns notifications.
  - **All of** DND, grouping, persistence-across-restart, and swipe-to-dismiss-as-real-state (not just a UI animation over swaync's own dismiss call) are downstream of this decision. If the QML surface stays a client of swaync instead, most of the Differentiators above (DND toggle, grouping, fullscreen suppression) become swaync-side changes, not QML-side ones — a materially different, and likely much harder, engineering path since swaync's own extension surface is far more limited than a from-scratch QML `NotificationServer`.
  - **Recommendation for the roadmap:** decide server ownership explicitly and early in the NOTIF phase (a dedicated decision gate, not an assumption baked into a plan), given both reference rices independently converged on "the shell owns the server."
- **The existing OLED visibility script and fullscreen watcher are reusable infrastructure, not new work**, for both BAR auto-hide and NOTIF fullscreen-suppression — this lowers the complexity of two differentiators that would otherwise look expensive.
- **MEDIA is the most independent item in this research.** It depends only on infrastructure that already exists (dashboard Media tab, shared MPRIS reader) and does not depend on BAR, NOTIF, OSD, or POWER being rebuilt first, because neither reference actually places media on the bar in the way this project is copying (Caelestia's dashboard-only placement is the validated precedent for the user's fold-in decision). It could be sequenced independently of the rest of the migration if the roadmap benefits from an early low-risk win — its main procedural dependency is the same AGS-retirement consumer-check pattern this project already used successfully for eww's retirement.
- **BAR is correctly first per the milestone's own stated rationale** ("its patterns seed every later surface") — and the source reading confirms this structurally, not just organizationally: Caelestia's OSD/notification/session popouts read the bar's own geometry (`screenState.bar`) to avoid overlapping it, so the "avoid overlapping the bar" differentiator in NOTIF/OSD/POWER is architecturally anchored to BAR existing first.

---

## Recommended Phase-Sequencing Hints (for the roadmapper)

**Low-risk, low-dependency — safe early or parallel:**
- OSD (single-slider port + fullscreen/hover-hide semantics) — no notification-server dependency, reuses existing Audio/Brightness trigger sources
- POWER (six-action keyboard-navigable grid + safety-banner differentiator) — no notification-server dependency, self-contained
- MEDIA fold-in — depends only on already-shipped infrastructure (dashboard tab, shared MPRIS reader); the AGS-retirement consumer-check is the main procedural gate

**Structural prerequisite — must be early:**
- BAR — other surfaces' "avoid overlapping the bar" behavior and the per-widget popout pattern are architecturally anchored to it existing first; also the milestone's own explicit first-phase choice

**Requires an explicit decision gate before planning, not mid-plan discovery:**
- NOTIF — the notification-server ownership question (QML becomes the DBus server vs QML stays a swaync client) determines whether DND/grouping/persistence/swipe-dismiss are QML-native features or swaync-side changes, and determines whether swaync retirement happens in the same phase as popups or is deferred. Recommend resolving this as a named decision at phase-scoping time, given both reference rices independently chose "the shell owns the server."

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| What end-4/Caelestia actually ship (BAR/NOTIF/OSD/POWER/MEDIA) | HIGH | Direct reads of the actual QML source files via GitHub raw content — the real files, not summaries, blog posts, or memory. Every claim above is traceable to a specific file path and, where feasible, a specific property/function name |
| Table stakes classification | MEDIUM-HIGH | Cross-referenced against two independent rices that converged on the same behavior (e.g. swipe-to-dismiss implemented independently in both) — convergence between two unrelated projects is a stronger table-stakes signal than either alone |
| Differentiators | MEDIUM-HIGH | Grounded in a direct diff against this project's documented current capabilities (`PROJECT.md` Validated section, `MILESTONES.md`); complexity estimates are this researcher's judgment, not measured |
| Anti-features | HIGH for the ones tied to explicit PROJECT.md Out-of-Scope constraints (AI widgets, full settings app); MEDIUM for the ones argued from architectural conflict (per-track tinting vs single-palette-source) |
| Notification-server dependency analysis | HIGH that the dependency exists (directly observed in both codebases' `NotificationServer{}` instantiation); MEDIUM on the specific recommendation to decide it early, which is this researcher's judgment call, not a sourced fact |

## Gaps To Address

- **Whether this project's current wleave already has arrow-key/vim keyboard navigation** was not confirmed from `MILESTONES.md`/`PROJECT.md` (which document "hover/focus name reveal" but not explicitly a `KeyNavigation` chain) — worth a quick source check against the actual `wleave/` QML/config before scoping POWER-differentiator work, so the roadmap doesn't credit a capability that doesn't exist or duplicate one that does.
- **Whether Quickshell 0.3.0-2's multi-monitor limitation (QS-03, permanently dropped under D-13) actually blocks end-4's per-screen bar `Variants`+`LazyLoader` pattern** was not re-tested — the host has one physical monitor so this is low-priority, but if a second monitor is ever added, this is the first thing that would need re-validating against the standing D-13 finding.
- **swaync's own extension surface for DND/grouping/fullscreen-awareness** (i.e., what's achievable if NOTIF stays a swaync client rather than replacing the server) was not researched — this is the fallback path if the notification-server decision goes the other way, and isn't covered here since both reference rices chose the opposite path.
- **Exact Quickshell QML APIs for `Shape`/`ShapePath`/`PathAngleArc`** (needed for the radial-cava-around-cover-art differentiator) were observed in use in Caelestia's source but not independently researched against Quickshell/Qt Quick Shapes documentation — flag for phase-specific research when that differentiator is actually planned.

## Sources

- **Primary source — direct repository file reads (HIGH confidence, not a websearch/blog summary):**
  - [`caelestia-dots/shell`](https://github.com/caelestia-dots/shell) — `modules/bar/{Bar,BarWrapper}.qml`, `modules/bar/components/{Power}.qml`, `modules/bar/components/workspaces/{Workspaces,Workspace}.qml`, `modules/notifications/{Content,Notification,Wrapper}.qml`, `modules/osd/{Content,Wrapper}.qml`, `modules/session/{Content,Wrapper}.qml`, `modules/sidebar/{Wrapper,Notif,NotifGroup,NotifDock,NotifDockList,NotifGroupList}.qml`, `modules/dashboard/dash/Media.qml`, `modules/dashboard/media/{CoverVisualiser,Details}.qml`, `services/{Players,Notifs,NotifData}.qml`. Read at commit `main` on 2026-08-10.
  - [`end-4/dots-hyprland`](https://github.com/end-4/dots-hyprland) — `dots/.config/quickshell/ii/modules/ii/bar/{Bar,BarContent,BarGroup,Media,SysTray,UtilButtons}.qml`, `modules/ii/notificationPopup/NotificationPopup.qml`, `modules/ii/onScreenDisplay/{OnScreenDisplay,OsdValueIndicator}.qml`, `modules/ii/sessionScreen/{SessionScreen,SessionActionButton}.qml`, `modules/ii/mediaControls/{MediaControls,PlayerControl}.qml`, `modules/common/widgets/{NotificationItem,NotificationGroup}.qml`, `modules/common/models/quickToggles/NotificationToggle.qml`, `services/{Notifications,MprisController}.qml`. Read at commit `main` on 2026-08-10.
  - This project's own convention (`.claude/CLAUDE.md`) explicitly treats direct-verification-against-the-real-artifact as HIGH confidence even when the generic research-tooling confidence classifier defaults unfamiliar fetch methods to LOW/MEDIUM (confirmed via `gsd-tools query classify-confidence`, which has no distinct bucket for "direct primary-source code read" and returned LOW for both `webfetch`/`github` providers regardless of `--verified`). This document follows that established project precedent rather than the generic classifier default.
- **Project context (HIGH confidence, first-party):** `.planning/PROJECT.md`, `.planning/MILESTONES.md` — used to determine what already exists (table-stakes baseline) and what is explicitly out of scope (anti-features).

---
*Feature research for: v4.0 Shell Migration & Debt Paydown — QML bar, notifications, OSD, power menu, media fold-in*
*Researched: 2026-08-10*
