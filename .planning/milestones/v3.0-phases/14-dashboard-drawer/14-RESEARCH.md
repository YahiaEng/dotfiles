# Phase 14: Dashboard Drawer - Research

**Researched:** 2026-07-29
**Domain:** Quickshell/QML layer-shell surface (first real feature-bearing QML client), MD3-style swipeable tab UI, read-only integration with existing bash-owned backends (MPRIS, swaync, gaming mode, motion), one new external HTTP dependency (Open-Meteo)
**Confidence:** MEDIUM-HIGH — the mechanical building blocks (SwipeView, TabBar, Process, FileView/JsonAdapter, UPower, Open-Meteo) are all confirmed present/working on this exact machine; a handful of items (regex namespace matching on this Hyprland build, FILL-axis rendering with the specific Material Symbols font, live focus-grab coexistence) remain named research items carried over from discussion, now narrowed rather than closed.

## Summary

Phase 14 builds the first QML surface with real user-facing content, on top of infrastructure Phases 11-13.1 already proved: `shell.qml`'s `LazyLoader` summon/dismiss pattern, the `Colours`/`Motion` singleton tokens, the Lua-based Hyprland config, and a working `GlobalShortcut` + `shortcuts.json` manifest contract. Nothing about the *mechanism* of showing/dismissing a layer-shell surface is new — `modules/Probe.qml` already does exactly the `WlrKeyboardFocus.OnDemand` + `HyprlandFocusGrab` combination this phase needs, and it already passed QS-02 (a human clicked a button, typed into a `TextField`, and dismissed by click-outside) on this exact Hyprland 0.56.1 / quickshell 0.3.0-2 build. That finding directly answers D-12's named research item: reuse the proven combination verbatim rather than treating it as unknown.

What is genuinely new is (1) a four-pane `SwipeView`+`TabBar` pager — confirmed installed and available in `qt6-declarative` 6.11.1 (both `Basic` and `Material` styles ship `SwipeView.qml`, `TabBar.qml`, `TabButton.qml`) — and (2) content widgets that read three different kinds of existing state: a line-oriented JSON stream (`media-status.sh watch`), a set of shell-script-owned toggle backends (gaming/DND/dark mode), and `/proc`+`/sys` system counters, plus one brand-new network fetch (Open-Meteo). None of these need a new backend; DASH-04 and D-35's two hard fences (no `Quickshell.Services.Mpris`, no `media-status.sh` payload changes) are enforceable exactly as written using `Quickshell.Io.Process` to consume the existing script's stdout stream. `Quickshell.Services.UPower` is a real, already-installed Quickshell module and the better choice for the battery dial than parsing `/sys/class/power_supply` by hand — except this specific machine has **no battery hardware at all** (`upower -e` returns only `DisplayDevice`; `/sys/class/power_supply/` is empty), which is a load-bearing fact for how the Performance/Dashboard battery widgets get verified.

Direct source-checking of Caelestia's own dashboard (`caelestia-dots/shell`, fetched live this session) confirms the four-tab shape (`Dash`/`Media`/`Performance`/`WeatherTab`), the compact→full deep-link convention, and the Performance tab's hero-card dial pattern — but it also reveals two divergences worth flagging: Caelestia's own pager is a **hand-rolled `Flickable`+`TabBar` sync**, not `SwipeView` (the user's locked D-17/D-18 explicitly want `SwipeView`-class physics, so this is a "don't blindly copy the reference's mechanism" finding, not a course change), and Caelestia's *actual* weather service still falls back to `ip-api.com` GeoIP by default — precisely the failure class D-30 already rejected. Both findings *validate* the user's discretion calls rather than contradict them.

**Primary recommendation:** Build the drawer as a sibling `LazyLoader`-wrapped `PanelWindow` in `shell.qml` (Probe.qml's own pattern, not reinvented), namespace `quickshell-dashboard`, containing a `QtQuick.Controls.SwipeView` (Material style, to get MD3-flavored controls for free) synced one-way to a header `TabBar`; drive all four tabs' data through `Quickshell.Io` primitives (`FileView`/`JsonAdapter` for state files, `Process`+`StdioCollector`/streaming reads for the media JSON stream) rather than any new backend; use `Quickshell.Services.UPower` for the battery source and accept that its "populated" state cannot be visually verified on this hardware — plan a fault-injection proof instead, matching the discipline already established for weather's stale-cache path.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Drawer summon/dismiss/focus | Browser/Client (QML surface, layer-shell) | Backend (Hyprland compositor via GlobalShortcut/FocusGrab protocols) | The drawer is a client-rendered layer-shell surface; focus/dismiss mechanics are compositor protocol calls the QML client issues, not server logic |
| Tab navigation (swipe/tap/arrows) | Browser/Client | — | Pure UI state (`SwipeView.currentIndex`), no backend involvement |
| Media widget content | Browser/Client (render) | Backend (`media-status.sh`/`media-players.sh`, existing) | The drawer is a THIRD READER of an existing single-writer backend — it must not become a second media source (DASH-04) |
| Quick-toggle grid (gaming/DND/dark) | Browser/Client (render + press) | Backend (existing toggle scripts + swaync's own state) | Same shared-state discipline as media: the drawer writes through the SAME exec commands swaync already uses (D-27), never a new state file |
| System resource dials (CPU/mem/net/storage) | Browser/Client (poll while open) | Backend (`/proc`, `/sys`, kernel — read-only) | No daemon exists or is needed; QML polls kernel-exposed pseudo-files directly, matching D-36 |
| Battery | Browser/Client (consume) | Backend (`Quickshell.Services.UPower` → system `upowerd` via D-Bus) | UPower is a real system service already present; Quickshell ships a typed wrapper — prefer it over hand-parsing `/sys/class/power_supply` |
| Weather fetch/cache | Browser/Client (QML `XMLHttpRequest` or a helper `Process`) | External (Open-Meteo HTTP API) | The only tier this phase adds a genuinely new external dependency to; isolated per D-29's "one-file change" fence |
| Design tokens (colour/motion) consumed by every widget | Browser/Client (read via `Colours`/`Motion` singletons) | Backend (matugen/theme-engine renders `~/.local/state/theme/*.json`, unchanged) | Existing Phase 12 pipeline, read-only consumer, no new writer |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Quickshell | 0.3.0-2 (installed) `[VERIFIED: pacman -Q]` | Layer-shell shell toolkit hosting the drawer | Already the project's chosen foundation (QS-01..06 complete); this phase adds no new Quickshell version dependency |
| qt6-declarative (QtQuick.Controls SwipeView/TabBar/TabButton) | 6.11.1-3 (installed) `[VERIFIED: pacman -Ql qt6-declarative — confirmed SwipeView.qml, TabBar.qml, TabButton.qml present in both Basic and Material styles]` | Four-tab pager + header row | Ships in the base Qt6 install already present on this machine — zero new packages for D-17/D-18's "framework-default pager physics" |
| Quickshell.Io (`Process`, `FileView`, `JsonAdapter`, `StdioCollector`) | ships with quickshell 0.3.0-2 `[VERIFIED: pacman -Ql quickshell shows these qmltypes]` | Reading `media-status.sh watch`, toggle state files, `/proc`+`/sys` counters | Already the exact mechanism Colours.qml/Motion.qml/Probe.qml use; zero new pattern to learn |
| Quickshell.Services.UPower | ships with quickshell 0.3.0-2 `[VERIFIED: pacman -Ql shows quickshell-service-upower.qmltypes; systemctl shows upowerd active on this machine]` | Battery dial data source | Real Quickshell-typed wrapper around the system's own `upowerd`; strictly better than hand-parsing `/sys/class/power_supply/*` |
| Material Symbols Rounded (variable font) | AUR `ttf-material-symbols-variable-git`, latest seen `4.0.0.r119.gc51274e9-1` `[ASSUMED — discovered via WebSearch, not yet confirmed via an authoritative registry check; AUR page itself blocked this session by anti-bot (Anubis)]` | Icon system for the whole QML family, starting here (D-28) | The exact AUR package the reference-lens shells (end-4/Caelestia) package Material Symbols as; variable-font FILL axis needed for the lit/unlit chip language |
| Open-Meteo forecast + geocoding API | keyless, current API surface `[VERIFIED: live HTTP fetch this session returned current/hourly/daily JSON with the expected shape]` | Weather tab data | Keyless, no registration, no committed secret — matches D-29's reproducibility requirement exactly; confirmed live and working this session |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| QML `XMLHttpRequest` (built into the QtQml JS engine, no import needed) | n/a (language feature, Qt 6.11.1) | Weather HTTP GET + JSON parse | Simplest path for D-30's discretion item; Caelestia's own `Requests.qml` wraps exactly this (confirmed via source-check, see Sources) |
| `font.variableAxes` (QML `font` value type property) | Qt 6.7+ (this build: 6.11.1) `[VERIFIED: WebSearch of Qt 6.x changelog/docs corroborated against installed qmake6 -query QT_VERSION == 6.11.1]` | Driving Material Symbols' FILL axis (outlined↔filled chip state) | Any icon that needs the lit/unlit interpolation D-25/D-26 describe; syntax `font.variableAxes: { "FILL": value }` |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `QtQuick.Controls.SwipeView` for the pager | Hand-rolled `Flickable` + `TabBar` sync (Caelestia's actual, source-checked implementation) | Caelestia's Flickable gives finer control over drag-threshold percentage (they use 10%, not SwipeView's ~1/3 `StrictlyEnforceRange` snap) and per-pane lazy-loading via `visibleArea` math — but it is materially more custom code for a first QML feature surface, and D-17/D-18 already lock in "framework-default pager physics (SwipeView-class)." Recommend SwipeView; borrow only Caelestia's lazy-pane-`Loader` idea (see Pattern 4 below), not its pager mechanism. |
| `Quickshell.Services.UPower` for battery | Hand-parse `/sys/class/power_supply/BAT*/capacity` and `/status` | UPower is a real, already-running system service with a typed Quickshell wrapper — avoids re-deriving charge/discharge semantics from raw sysfs files and gets a device model that already correctly returns "no battery" (`DisplayDevice` only, verified live) rather than requiring bespoke absence-detection code |
| QML `XMLHttpRequest` for the weather fetch | A helper bash script (e.g. `curl` via `Quickshell.Io.Process`) | A script keeps the fetch fully shell-scriptable/testable in isolation (matches this repo's general bash-first convention) and can be fault-injected the same way `media-status.sh`/`motion-switch.sh` are, at the cost of one more file; `XMLHttpRequest` keeps everything in one QML file and matches the reference shell's own pattern exactly. Either is legitimate; D-30 leaves this to researcher/planner discretion — lean `XMLHttpRequest` for locality unless the plan wants the fetch independently testable from a terminal. |
| AUR `ttf-material-symbols-variable-git` | Vendor the static/variable TTF file directly into the repo | AUR keeps the install fully reproducible via `install.sh`'s existing `AUR_PKGS` + `verify_packages` hard-fail loop (D-28's stated class) with zero repo bloat; vendoring removes all AUR/PKGBUILD trust surface at the cost of a binary asset living in git and manual update discipline. Given every other font in this repo is package-installed (`ttf-firacode-nerd`, `noto-fonts`, etc. — none vendored), AUR is the consistent choice; keep vendoring as the documented fallback if the AUR package is ever found unmaintained. |

**Installation:**
```bash
# install.sh AUR_PKGS array — one new entry, same hard-fail verify_packages() loop
# as every other font/package in this repo (pacman -Q check, exit 1 if missing)
ttf-material-symbols-variable-git
```

**Version verification:** `pacman -Q quickshell qt6-declarative qt6-base qt6-svg` confirmed `quickshell 0.3.0-2`, `qt6-declarative 6.11.1-3`, `qt6-base 6.11.1-1`, `qt6-svg 6.11.1-1` on the target machine directly — these are the versions every code example below targets. The Material Symbols AUR package version (`4.0.0.r119.gc51274e9-1` at WebSearch time) is a `-git` package and will drift; `install.sh`'s hard-fail `pacman -Q` check only confirms *presence*, not a pinned version — acceptable, matching this repo's existing AUR convention (e.g. `walker`, `elephant` are also unpinned AUR entries).

## Package Legitimacy Audit

> This phase's only new external package is an AUR font package, not an npm/PyPI/crates dependency — the automated `package-legitimacy check` seam only supports those three ecosystems (`gsd-tools query package-legitimacy check --ecosystem <npm|pypi|crates>` rejected `--ecosystem aur` this session). The audit below was performed manually per the ecosystem-appropriate verification the protocol calls for when the automated tool doesn't cover the ecosystem.

| Package | Registry | Age/Activity | Downloads/Popularity | Source Repo | Verdict | Disposition |
|---------|----------|-----|-----------|-------------|---------|-------------|
| `ttf-material-symbols-variable-git` | AUR | Package exists on AUR at version `4.0.0.r119.gc51274e9-1` per WebSearch results `[ASSUMED]`; AUR page itself returned an anti-bot (Anubis) block when fetched directly this session, so votes/popularity/maintainer/last-updated fields could not be confirmed | Not confirmed this session | A companion project (`github.com/Shiphan/ttf-material-symbols-variable`, "Arch package for Google Material Symbols icon set") surfaced independently in the same WebSearch — the package is a thin PKGBUILD wrapper around Google's own official Material Symbols font repo, not a novel/obscure project | `[SUS — unverified]` | **Flagged.** Planner must add a `checkpoint:human-verify` task before this package is installed: manually confirm the AUR page (votes, maintainer, last-updated date, PKGBUILD contents) rather than relying on this session's WebSearch alone, since the AUR site itself could not be fetched directly. |

**Packages removed due to `[SLOP]` verdict:** none.
**Packages flagged as suspicious `[SUS]`:** `ttf-material-symbols-variable-git` — planner must insert `checkpoint:human-verify` before this install task, per the disposition above. Fallback if the checkpoint fails or the package looks abandoned/compromised: vendor the TTF directly (see Alternatives Considered).

## Architecture Patterns

### System Architecture Diagram

```
 Super+D (Hyprland Lua keybind)
        │
        ▼
 hl.dsp.global("quickshell:dashboard")  ──►  Quickshell GlobalShortcut.onPressed
        │                                          │
        │                                          ▼
        │                              drawerLoader.active = !drawerLoader.active
        │                                          │
        │                    ┌─────────────────────┘
        │                    ▼
        │        LazyLoader (active:false ⇄ true)   ── destroy-on-dismiss (D-14)
        │                    │
        │                    ▼
        │        PanelWindow  "quickshell-dashboard"
        │        (overlay layer, exclusiveZone:0, WlrKeyboardFocus.OnDemand)
        │                    │
        │        ┌───────────┼─────────────────────────────┐
        │        ▼           ▼                             ▼
        │  HyprlandFocusGrab  TabBar (header, D-16)   SwipeView (D-17/D-18)
        │  (click-outside          │                        │
        │   + focus-loss                                    │
        │   dismiss, D-13)   TabBar.currentIndex ──────► SwipeView.currentIndex
        │                                                    │
        │                          ┌─────────────┬───────────┼────────────┐
        │                          ▼             ▼            ▼            ▼
        │                     DashboardTab   MediaTab   PerformanceTab  WeatherTab
        │                          │             │            │            │
        │                          │             │            │            └─► Open-Meteo
        │                          │             │            │                HTTP fetch
        │                          │             │            │                (XMLHttpRequest
        │                          │             │            │                 or Process+curl)
        │                          │             │            │                 → 15-min TTL
        │                          │             │            │                   cache file
        │                          │             │            └─► /proc, /sys
        │                          │             │                (FileView poll,
        │                          │             │                 1-2s/30s cadence)
        │                          │             │            └─► Quickshell.Services.UPower
        │                          │             │                (battery — no hardware
        │                          │             │                 on THIS machine)
        │                          │             └─► Process reading
        │                          │                 `media-status.sh watch`
        │                          │                 (one JSON line/change) +
        │                          │                 `media-players.sh cmd`
        │                          │                 (transport actions — the
        │                          │                  ONLY sanctioned writer)
        │                          └─► Calendar (pure QML date math)
        │                              + compact media (deep-links to MediaTab)
        │                              + resources strip (deep-links to PerformanceTab)
        │                              + quick-toggle grid (D-23..27, below)
        │
        ▼
 Quick-toggle grid (Gaming / DND / Dark / Motion-scale row)
        │
        ├─ Gaming  → exec gaming-mode-toggle.sh   ⇄ watch ~/.cache/gaming-mode
        ├─ DND     → exec swaync-client -dn/-df   ⇄ read swaync-client -D
        │                                              (subscribe verb — NAMED
        │                                               RESEARCH ITEM, unresolved)
        ├─ Dark    → exec theme-switch.sh         ⇄ watch ~/.local/state/theme/mode
        └─ Motion  → exec motion-switch.sh <preset> (no swaync counterpart, D-23)

 Colours.qml / Motion.qml singletons ── consumed by every widget above, unchanged from Phase 12
```

### Recommended Project Structure

```
quickshell/.config/quickshell/
├── shell.qml                       # existing — add one sibling LazyLoader block
├── shortcuts.json                  # existing — add {"appid":"quickshell","name":"dashboard",...}
└── modules/
    ├── qmldir                      # existing — MUST list every new type below (FM1 lesson)
    ├── Colours.qml / Motion.qml    # existing singletons — unchanged, read-only
    ├── Probe.qml                   # existing — unchanged, reused as the summon/dismiss template
    ├── Dashboard.qml               # new — the PanelWindow + SwipeView + TabBar host (Probe.qml's shape)
    └── dashboard/                  # new subdirectory (needs ITS OWN qmldir if used as a QML module,
        │                          # or plain relative imports if kept as a flat sibling set —
        │                          # PLANNER DISCRETION per Claude's Discretion in CONTEXT.md)
        ├── DashboardTab.qml        # calendar + date/time + compact media + resources strip + toggles
        ├── MediaTab.qml            # full player (reads media-status.sh watch via a shared Process)
        ├── PerformanceTab.qml      # 4 dials + network rate row
        ├── WeatherTab.qml          # hero + 8-col hour strip + 5-day row
        ├── MediaBackend.qml        # (recommended) ONE Process wrapping `media-status.sh watch`,
        │                          # shared by DashboardTab's compact widget AND MediaTab — avoids
        │                          # two independent Process instances polling the same script
        ├── WeatherBackend.qml      # (recommended) fetch + 15-min TTL cache + disk persistence,
        │                          # isolated per D-29's "one-file change" fence
        └── QuickToggles.qml        # the 3 mirrored chips + motion-scale segmented row (D-23..27)
```

### Pattern 1: LazyLoader summon/dismiss (reuse verbatim)

**What:** A `LazyLoader` with `active: false` wraps the `PanelWindow`; toggling `active` on `GlobalShortcut.onPressed` both creates and destroys the `wl_surface` — `hyprctl layers -j` shows nothing when dismissed (D-14, DASH-01's zero-idle-footprint half).
**When to use:** Exactly this phase's drawer — it's the same mechanism `modules/Probe.qml` already proved live under QS-02.
**Example:**
```qml
// Source: quickshell/.config/quickshell/shell.qml (this repo, verified live)
LazyLoader {
    id: dashboardLoader
    active: false
    Dashboard {
        onDismissRequested: dashboardLoader.active = false
    }
}
GlobalShortcut {
    id: dashboardShortcut
    appid: "quickshell"
    name: "dashboard"
    onPressed: dashboardLoader.active = !dashboardLoader.active
}
```

### Pattern 2: OnDemand focus + FocusGrab for click-outside dismiss AND keyboard input (D-12's answer)

**What:** `WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand` plus a `HyprlandFocusGrab` bound to the drawer's own window.
**When to use:** This is not a new pattern to prototype — it is Probe.qml's EXISTING, QS-02-proven combination. Reuse it verbatim rather than treating D-12 as fully open.
**Example:**
```qml
// Source: quickshell/.config/quickshell/modules/Probe.qml (this repo, QS-02-proven live)
WlrLayershell.layer: WlrLayer.Overlay
WlrLayershell.namespace: "quickshell-dashboard"
WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
exclusiveZone: 0

HyprlandFocusGrab {
    id: grab
    windows: [ dashboardWindow ]
    active: true
    onCleared: dashboardRoot.dismissRequested()   // click-outside AND focus-loss (D-13) both land here
}
```
**Caveat (D-13/coexistence):** `HyprlandFocusGrab` is compositor-exclusive on this build — only one grab can be active desktop-wide (Phase 11 finding, re-confirmed relevant here). If the token-inspector Probe and the dashboard are ever summoned "simultaneously," the second grab wins and the first surface's dismiss wiring goes stale. D-13's focus-loss-dismiss rule should make this self-correcting (the losing surface's grab clears, its `onCleared` fires, it dismisses) — but this specific interaction should be exercised live during execution, not assumed from the general finding alone.

### Pattern 3: SwipeView + TabBar, motion-token-driven

**What:** `QtQuick.Controls.SwipeView` (Material style) as the pager, `TabBar` as the header, synced one-way per Qt's own documented convention (avoid a true two-way binding — it creates circular-dependency bugs per Qt's own guidance).
**When to use:** D-16/D-17/D-18's tab mechanism.
**Example:**
```qml
// Pattern confirmed via Qt 6 docs (TabBar/SwipeView pairing) + this machine's installed
// qt6-declarative 6.11.1 SwipeView.qml source (ListView-backed, SnapOneItem,
// StrictlyEnforceRange, hardcoded highlightMoveDuration: 250 — MUST be
// overridden to consume Motion.standardDuration, see Pitfall 1 below)
import QtQuick.Controls
import QtQuick.Controls.Material

TabBar {
    id: tabBar
    currentIndex: pager.currentIndex   // one-way FROM the pager
    TabButton { text: "Dashboard" }
    TabButton { text: "Media" }
    TabButton { text: "Performance" }
    TabButton { text: "Weather" }
}

SwipeView {
    id: pager
    currentIndex: tabBar.currentIndex  // Qt's documented pattern accepts this
    onCurrentIndexChanged: tabBar.setCurrentIndex(currentIndex) // avoid raw two-way assignment loops
    Keys.onLeftPressed: pager.currentIndex = Math.max(0, pager.currentIndex - 1)   // D-18 clamp
    Keys.onRightPressed: pager.currentIndex = Math.min(3, pager.currentIndex + 1) // D-18 clamp
    DashboardTab {}
    MediaTab {}
    PerformanceTab {}
    WeatherTab {}
}
```

### Pattern 4: Lazy per-tab content loading (borrowed idea, not the pager mechanism, from Caelestia)

**What:** Caelestia's `Content.qml` (source-checked this session) wraps each tab's real content in a `Loader` whose `active` binding checks whether the tab is the current one OR within the pager's visible/adjacent range, so off-screen tabs don't run their timers/fetches.
**When to use:** Directly useful for D-36's "polling only while the drawer is open" AND for keeping Performance/Weather's timers from running for tabs the user never swipes to.
**Example:**
```qml
// Source: caelestia-dots/shell modules/dashboard/Content.qml (fetched live this session,
// idea only — the surrounding Flickable-based pager is NOT reused, see Alternatives Considered)
Loader {
    required property int index
    sourceComponent: tabComponent
    active: index === pager.currentIndex  // simplest form: only the active tab polls
}
```

### Anti-Patterns to Avoid

- **`Quickshell.Services.Mpris`:** This module is real, installed, and importable on this machine (`Quickshell/Services/Mpris/quickshell-service-mpris.qmltypes` confirmed present) — and it is EXACTLY the second media backend D-35/DASH-04 forbid. Its mere availability makes it a tempting default; do not import it anywhere in the drawer. Read `media-status.sh watch` instead.
- **Raw duration/easing literals in the pager:** `SwipeView`'s stock `contentItem` hardcodes `highlightMoveDuration: 250` and Qt's default easing — a literal `motion-lint` (TOKEN-04) will flag once this file is in scope of its scan. Override the contentItem (or wrap the transition in a custom `Behavior` bound to `Motion.standardDuration`/`Motion.standardEasing`) rather than shipping the Qt default untouched.
- **`PathView` for the pager:** Explicitly rejected by D-18 (wraparound rejected) — do not reach for it even though it's also available in the same Qt install.
- **A second Process per tab reading the same `media-status.sh watch` stream:** Both the Dashboard tab's compact widget and the Media tab need the SAME live data; running two independent `Process` instances doubles the subprocess and risks visible desync between the two views. Share one backend singleton/component (see project structure's `MediaBackend.qml`).
- **Hand-parsing `/sys/class/power_supply/*` for battery when `Quickshell.Services.UPower` is already installed and running:** Redundant and more error-prone (UPower already resolves the "no battery present" case cleanly as an empty device list; hand-parsing sysfs needs its own absence-detection).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Reading MPRIS/media state | A second D-Bus MPRIS client, or a raw `playerctl` subprocess wrapper | `Quickshell.Io.Process` streaming `media-status.sh watch`'s existing JSON-per-line contract | `media-status.sh` already sanitizes/validates every field (`_sanitize`, `_valid_id`); duplicating that logic in QML reopens a security surface this repo already closed once (T-08-07-*) |
| Sending transport commands (play/pause/seek/volume) | Direct `playerctl` invocation from QML with interpolated player IDs | `media-players.sh cmd <id> <verb> [arg]` (exec via `Process`) | `media-players.sh` is the repo's ONLY sanctioned mutator — it validates the D-Bus-derived player id via `_valid_id` before ever touching a shell command; bypassing it reopens the exact injection vector that script exists to close |
| Battery status | Manual `/sys/class/power_supply/BAT*/{capacity,status}` parsing + charge/discharge state machine | `Quickshell.Services.UPower` (`UPower.devices`, `displayDevice`, `onBattery`) | UPower is a real running system service (`systemctl is-active upower` → `active`, verified) with a typed Quickshell wrapper; it already handles "no battery" (this machine: `upower -e` returns only `DisplayDevice`) as a clean empty case rather than requiring bespoke sysfs absence-detection |
| Weather icon mapping (WMO code → symbol) | A hand-maintained giant if/else or lookup nobody double-checks against the spec | The WMO weather-code table (well-documented, ~30 codes) mapped once to Material Symbol names in one place, following the reference shells' own `getWeatherIcon()` pattern (source-checked, small pure function) | Small, stable, well-specified mapping — not worth a library, but worth writing once and reusing across current/hourly/daily renders rather than three separate copies |
| Circular percent dials (CPU/mem/storage/battery) | (No ready-made Qt/Quickshell circular-gauge component exists) | Hand-built `QtQuick.Shapes`/`Canvas` arc, following the reference shells' `HeroCard`-style dial as a visual/structural precedent (source-checked) | This is genuinely custom QML — flagging here only so the planner knows NOT to go hunting for a nonexistent built-in gauge component; budget it as real work, reference the shape from Caelestia's `HeroCard.qml` |

**Key insight:** Every "backend" this phase touches already has exactly one sanctioned reader/writer script (`media-status.sh`/`media-players.sh` for media, the toggle scripts for the quick-toggle grid, matugen/theme-engine for colour/motion tokens). The drawer's entire job is to be an additional, read-mostly consumer of those contracts — the moment any drawer code starts re-deriving player state, re-implementing toggle logic, or talking to D-Bus/sysfs directly where a sanctioned script already exists, it has silently created a second source of truth, which is the exact failure class DASH-04/DASH-07 and this repo's Phase 8 history (a real prior toggle-state-drift bug) both exist to prevent.

## Common Pitfalls

### Pitfall 1: SwipeView's default transition duration is a raw literal
**What goes wrong:** `motion-lint` (TOKEN-04) fails the drawer once its QML file is scanned, because Qt's stock `SwipeView` `contentItem` (`ListView` with `highlightMoveDuration: 250`) never reads from `Motion.*`.
**Why it happens:** `SwipeView`'s built-in styling ships as a normal Qt Quick Controls asset, not a token-aware component this repo authored.
**How to avoid:** Provide a custom `contentItem`/`Behavior` for the pager transition (or the tab-switch fade if the design calls for one) that explicitly binds to `Motion.standardDuration`/`Motion.standardEasing`, exactly like every other Behavior in `Probe.qml`.
**Warning signs:** `motion-lint`'s CHECK B failing specifically on the new dashboard QML file, or a visually "snappier than everything else" tab-switch that doesn't respond to the motion-scale control.

### Pitfall 2: `Quickshell.Services.Mpris` is real, installed, and forbidden
**What goes wrong:** A developer (or an autocomplete suggestion) reaches for `import Quickshell.Services.Mpris` because it's the "obvious" Quickshell-native way to read media state — and it exists and works on this machine.
**Why it happens:** Quickshell genuinely ships this module; nothing in the toolkit itself warns that this repo has a standing rule against it.
**How to avoid:** Route every media read through `media-status.sh watch`/`media-players.sh` per D-35's two hard fences; treat any `Quickshell.Services.Mpris` import in a diff as an automatic review flag.
**Warning signs:** A second "now playing" desync between AGS/waybar and the dashboard — the exact symptom DASH-04 says must never happen.

### Pitfall 3: No battery hardware exists on this machine
**What goes wrong:** The battery dial's "populated" (has-a-battery) rendering can never be verified by simply looking at the running desktop, because `upower -e` returns only `/org/freedesktop/UPower/devices/DisplayDevice` and `/sys/class/power_supply/` is empty `[VERIFIED: direct command on this machine]`.
**Why it happens:** This is a desktop rig, not a laptop.
**How to avoid:** Plan a fault-injection/mock proof for the populated state (e.g., a throwaway `UPowerDevice`-shaped stub or a documented "verified only via code review, not live rendering" acceptance) — mirroring the same discipline D-33 already applies to weather's cache-backdating fault injection. Do NOT silently let the battery widget's populated path go completely unverified without recording that decision.
**Warning signs:** A verification writeup that claims the battery dial "works" with only the empty-state screenshot as evidence.

### Pitfall 4: `motion.json`'s `semantic` bucket is the ONLY one motion-lint scans for QML tokens
**What goes wrong:** Adding D-21's new stagger-offset value under `motion.json`'s existing `indicators` bucket (which already holds bare `duration_ms` values, structurally closer to what a stagger offset is) makes it invisible to `motion-lint`'s `load_qml_defs()` — that function only reads keys under `semantic`.
**Why it happens:** `indicators` and `semantic` look similar in the JSON but only `semantic` keys get promoted to `<camelKey>Duration`/`<camelKey>Easing` allowed QML references (verified by reading `motion-lint`'s source directly this session).
**How to avoid:** Add the stagger token as a new entry under `motion.json`'s `semantic` object (e.g. `"stagger-offset": {"duration": "short1", "easing": "standard"}`, following the exact shape of the existing `standard`/`emphasized-in`/`emphasized-out` entries), then extend `Motion.qml`'s hardcoded `_pairNames` array (currently `["standard", "emphasized-in", "emphasized-out"]`) to include it — the singleton does not auto-discover new semantic keys; it lists them by name, per its own committed source.
**Warning signs:** `Motion.staggerOffsetDuration` resolving to `undefined`/`0` at runtime despite the JSON key existing, or `motion-lint` reporting the new property as a CHECK-A dangling reference.

### Pitfall 5: `JsonAdapter` only maps TOP-LEVEL JSON keys
**What goes wrong:** A naive weather state-file `JsonAdapter` with nested `{location: {lat, lon}, units: {...}}` structure silently fails to bind `location.lat`-style properties.
**Why it happens:** Verified directly against the installed `Quickshell.Io` behavior via `Motion.qml`'s own comment and implementation — `JsonAdapter` maps only top-level keys; nested data must be received into a single `property var` and destructured manually, exactly as `Motion.qml` already does for its `semantic` sub-object.
**How to avoid:** For D-31's multi-key weather state file, either flatten the schema to top-level keys (e.g. `lat`, `lon`, `units_temp`, `units_wind`) or follow `Motion.qml`'s `property var` + manual-read pattern for any nested structure.
**Warning signs:** A weather widget that always shows the default/fallback values regardless of what's in the state file.

### Pitfall 6: New `GlobalShortcut` entries need a Quickshell process restart to register
**What goes wrong:** Super+D is added to `shortcuts.json` + `keybinds.lua`, QML hot-reloads fine, but the bind silently does nothing.
**Why it happens:** Documented Phase 11 finding, reconfirmed relevant here: hot-reload propagates QML/logic changes but NOT new `GlobalShortcut` registrations — those need quickshell itself to restart.
**How to avoid:** Budget an explicit `pkill quickshell` (session will auto-relaunch it per autostart) or a full session restart as a required step after adding the new shortcut, not an afterthought if the bind "doesn't seem to work."
**Warning signs:** `keybind-doctor`'s cross-check of the Quickshell `GlobalShortcut` manifest against `hyprctl globalshortcuts` showing the manifest entry present but the live registration missing.

### Pitfall 7: Reference shells' actual weather implementation uses rate-limited GeoIP
**What goes wrong:** Copying Caelestia's `Weather.qml` wholesale (source-checked this session) would reintroduce `ip-api.com` GeoIP lookups as the no-location-configured default — exactly the "VPN shows the exit node's weather with no cue" failure D-30 already rejected, plus a documented rate-limit failure mode (429s) in Caelestia's own issue tracker for a near-identical service (`ipinfo.io`).
**Why it happens:** The reference shell's own implementation trades this specific fragility for zero-config convenience.
**How to avoid:** Follow D-30 as decided — city-level coordinates seeded into a state file by `stow.sh`, never a live GeoIP call. Only reuse Caelestia's Open-Meteo *forecast/geocoding* calls (`api.open-meteo.com/v1/forecast`, `geocoding-api.open-meteo.com/v1/search`), not its `ip-api.com` fallback path.
**Warning signs:** None expected if D-30 is followed — this pitfall exists purely to stop a "just copy the reference" instinct from reintroducing a rejected mechanism.

## Code Examples

### Reading the media JSON stream (Process + line-by-line handling)
```qml
// Pattern per Quickshell.Io.Process docs (fetched this session) — media-status.sh watch
// prints exactly one JSON object per line on change (verified: this repo's own contract,
// media-status.sh header comment)
Process {
    id: mediaWatcher
    running: true
    command: [Quickshell.env("HOME") + "/.config/hypr/scripts/media-status.sh", "watch"]
    stdout: SplitParser {
        onRead: (line) => {
            try {
                const payload = JSON.parse(line);
                mediaBackend.current = payload;
            } catch (e) {
                // malformed line — keep last-good payload, never crash (mirrors
                // Colours.qml/Motion.qml's existing fallback discipline)
            }
        }
    }
}
```

### Sending a transport command (through the sanctioned mutator only)
```qml
// media-players.sh is this repo's ONLY sanctioned mutator (T-08-07-* discipline) —
// never construct a raw playerctl invocation with an interpolated player id in QML
Process {
    command: [Quickshell.env("HOME") + "/.config/hypr/scripts/media-players.sh",
              "cmd", mediaBackend.current.player, "play-pause"]
    running: true
}
```

### Open-Meteo fetch (XMLHttpRequest, unit-aware per D-31)
```qml
// Source pattern: Requests.get() in caelestia-dots/shell services/Weather.qml (source-checked
// this session); Open-Meteo endpoint shape confirmed via a live fetch this session
function fetchWeather(lat, lon, unitsTemp, unitsWind) {
    const url = `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}` +
        `&current=temperature_2m,relative_humidity_2m,apparent_temperature,weather_code,wind_speed_10m,is_day` +
        `&hourly=temperature_2m,weather_code&daily=weather_code,temperature_2m_max,temperature_2m_min,sunrise,sunset` +
        `&timezone=auto&forecast_days=5` +
        `&temperature_unit=${unitsTemp === "imperial" ? "fahrenheit" : "celsius"}` +
        `&wind_speed_unit=${unitsWind === "imperial" ? "mph" : "kmh"}`;
    const xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function () {
        if (xhr.readyState !== XMLHttpRequest.DONE) return;
        if (xhr.status !== 200) { weatherBackend.markStale(); return; }
        try {
            const json = JSON.parse(xhr.responseText);
            weatherBackend.applyFresh(json);
        } catch (e) {
            weatherBackend.markStale();
        }
    };
    xhr.open("GET", url);
    xhr.send();
}
```

### Battery via Quickshell.Services.UPower
```qml
// Source: Quickshell.Services.UPower module (installed, this machine) — displayDevice is
// the aggregate device; on this machine `upower -e` returns ONLY DisplayDevice (no real
// battery), so `displayDevice.isLaptopBattery` (or an equivalent presence check) is expected
// to read false here — the empty state IS the only state locally testable
import Quickshell.Services.UPower

readonly property bool hasBattery: UPower.displayDevice something-like-isLaptopBattery
readonly property real batteryPercent: hasBattery ? UPower.displayDevice.percentage : 0
```
*(Exact UPowerDevice property names for percentage/state/isLaptopBattery should be confirmed against the installed `quickshell-service-upower.qmltypes` at implementation time — this session's fetch of Quickshell's UPower docs only enumerated the top-level `UPower` singleton's three properties, not the full `UPowerDevice` surface.)*

### Layer rule (windowrules.lua) — per-surface exact match, following wleave's precedent
```lua
-- Source: hypr/.config/hypr/config/windowrules.lua (this repo, existing wleave precedent,
-- lines ~221-232/293/345) — exact-match fallback if D-42's family-wide regex rule is not
-- proven live on this Hyprland 0.56.1 build before the plan needs it
hl.layer_rule({ match = { namespace = "quickshell-dashboard" }, blur = true })
hl.layer_rule({ match = { namespace = "quickshell-dashboard" }, ignore_alpha = 0.5 })
hl.layer_rule({ match = { namespace = "quickshell-dashboard" }, animation = "slide" })

-- D-42's preferred family-wide alternative (RE2 regex, per Hyprland Lua docs — confirmed
-- as a documented capability, NOT yet live-verified on THIS build against hyprctl layers -j):
-- hl.layer_rule({ match = { namespace = "^quickshell-.*" }, blur = true })
```

### shortcuts.json + keybinds.lua entries (D-09, following the probe's own precedent exactly)
```json
{
  "appid": "quickshell",
  "name": "dashboard",
  "chord": { "mods": "SUPER", "key": "D" },
  "description": "Summon the dashboard drawer (DASH-01)"
}
```
```lua
-- hypr/.config/hypr/config/keybinds.lua — same section as the existing probe binds
hl.bind(mainMod .. " + D", hl.dsp.global("quickshell:dashboard")) -- Summon dashboard drawer
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| Icon-swap (two separate image assets for outlined/filled icon states) | A single variable-font glyph interpolated live via `font.variableAxes: {"FILL": value}` | Qt 6.7 (this build: 6.11.1) `[VERIFIED: WebSearch corroborated against installed Qt version]` | The lit/unlit chip language (D-25/D-26) can be a `Behavior`-animated property on ONE glyph rather than a cross-fade between two image assets — simpler QML, matches the reference shells' own `fill:` property convention (source-checked in Caelestia's `MaterialIcon` usage) |
| Bespoke bash+CSS desktop widget (this repo's pre-Phase-11 pattern: waybar modules, swaync widgets) | Native QML component library (`SwipeView`, `TabBar`, `Process`, `FileView`/`JsonAdapter`, typed service singletons like `UPower`) | Phases 11-13.1 (this milestone) | This phase is the first to actually exercise the "real feature" half of that shift — everything before it (Probe.qml) was instrumentation, not a shipped surface |

**Deprecated/outdated:** Nothing in this phase's own scope is deprecated; the milestone's stated deprecation targets (swaync/walker/wleave) are explicitly out of engineering-attention scope per the phase boundary's own "deprecation principle."

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `ttf-material-symbols-variable-git` is a legitimate, actively-maintained AUR packaging of Google's official Material Symbols font, not a slopsquat/abandoned package | Package Legitimacy Audit, Standard Stack | Installing a malicious/abandoned AUR package via `install.sh`'s `AUR_PKGS` — mitigated by the `checkpoint:human-verify` task the audit already requires before this install |
| A2 | Hyprland Lua's `hl.layer_rule` regex namespace matching (RE2, `^quickshell-.*`) works identically on THIS installed Hyprland 0.56.1 build, not just in general docs/community reference | Standard Stack, Code Examples, Common Pitfalls | D-42's family-wide rule silently matches zero surfaces (fails open, not closed) — the per-surface exact-match fallback (already documented) is the safe default until live-verified |
| A3 | `font.variableAxes: {"FILL": value}` renders correctly specifically with the Material Symbols Rounded variable font on this Qt 6.11.1/qt6-declarative build | Standard Stack, State of the Art | The lit/unlit chip language falls back to a static appearance or a rendering glitch — general Qt feature confirmed present, but the specific font+axis pairing is unverified visually on this machine |
| A4 | The exact `UPowerDevice` property names for percentage/charging-state/`isLaptopBattery` match what this code-example sketch assumes | Code Examples (Battery snippet) | A compile-time/binding error against the real `quickshell-service-upower.qmltypes` — low risk (mechanical fix), flagged so the planner budgets a "confirm exact property names" step rather than treating the sketch as final |
| A5 | SwipeView's default `StrictlyEnforceRange`/`SnapOneItem` drag physics will read, to a human, as "≈1/3 distance or quick flick" per D-17, without additional threshold tuning | Alternatives Considered, Standard Stack | The default may feel "too sticky" or "too loose" against the user's stated expectation — recoverable via a render-gate check and, if needed, a custom drag-threshold override on the pager's `contentItem` |

## Open Questions

1. **`swaync-client --subscribe` DND change-events on this swaync 0.12.x build**
   - What we know: `swaync-client -D` (poll) and `-dn`/`-df` (mutate) are already used by the existing swaync toggle grid (verified from `swaync/config.json`); `--subscribe` is documented swaync CLI surface generally.
   - What's unclear: Whether `--subscribe` actually emits on THIS installed swaync 0.12.6 build specifically for DND toggles — not exercised this research session (would require a live swaync process interaction, deferred to execution).
   - Recommendation: Plan for the polling fallback (`swaync-client -D` on a timer while the drawer is open) as the default-safe implementation; attempt `--subscribe` first and fall back live if it doesn't fire, per D-27's own phrasing ("named research-verify item").

2. **Regex namespace matching for `hl.layer_rule` on Hyprland 0.56.1 Lua specifically**
   - What we know: RE2-based regex matching on `match.namespace` is documented Hyprland Lua capability (confirmed via WebSearch of hyprland-lua-docs/DeepWiki sources).
   - What's unclear: Live proof against `hyprctl layers -j` on this exact installed build, with the exact `^quickshell-.*` pattern this repo wants.
   - Recommendation: Ship the family-wide regex rule as the primary design, but write the per-surface exact-match fallback (already in Code Examples) in the same commit as an immediately-available Plan B if the live check fails.

3. **`UPowerDevice`'s exact property surface (percentage/state/isLaptopBattery names)**
   - What we know: The `UPower` singleton itself exposes `onBattery`, `displayDevice`, `devices` (confirmed via Quickshell docs fetch).
   - What's unclear: The individual `UPowerDevice` type's property names weren't enumerated in the fetched doc excerpt.
   - Recommendation: Read `/usr/lib/qt6/qml/Quickshell/Services/UPower/quickshell-service-upower.qmltypes` directly at implementation time (same technique used elsewhere in this research) before writing the battery widget's bindings.

4. **Battery widget's "populated" state cannot be visually verified on this hardware**
   - What we know: This machine has zero battery devices (`upower -e`, `/sys/class/power_supply/` both confirm this directly).
   - What's unclear: Whether the plan should (a) accept populated-state verification as code-review-only, (b) build a throwaway fault-injection stub, or (c) defer full verification to a future laptop-equipped session.
   - Recommendation: Decide explicitly at planning time rather than let this slide silently — mirrors D-33's own "a gate must be proven able to fail before it is trusted to pass" standing pattern applied to the inverse (prove the populated path CAN render, even without real hardware).

5. **Exact drag-commit threshold feel of stock `SwipeView` vs. the user's "~1/3 distance or quick flick" expectation (D-17)**
   - What we know: `SwipeView`'s `ListView`-backed `contentItem` uses `StrictlyEnforceRange`/`SnapOneItem`, which snaps to the nearest item on release rather than exposing an explicit percentage threshold property.
   - What's unclear: Whether the default feel needs a custom drag-threshold override to match "≈1/3" specifically, or whether the render gate will accept the stock behavior.
   - Recommendation: Build with the stock `SwipeView` first; judge at the human render-and-look gate (standing constraint 1) before investing in a custom threshold override.

6. **Weather cache file format/location and exact TTL/badge thresholds**
   - What we know: D-32/D-33 specify the behavior (~15-min TTL, refresh-on-summon-if-stale, last-good persists to disk, ~1h/~6h badge thresholds as starting points) but leave the exact file format/location and precise thresholds to researcher/planner discretion.
   - What's unclear: Nothing blocking — this is intentionally open per CONTEXT.md's Claude's Discretion section.
   - Recommendation: A flat JSON file under `~/.local/state/theme/` (registered in `contract.json`'s `engine_owned_files`, same seed-only-if-absent idiom as `motion-scale`) containing `{fetched_at, lat, lon, units, payload}` is consistent with every other state-axis file in this repo and needs no new pattern.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Quickshell | Drawer host | ✓ `[VERIFIED: pacman -Q]` | 0.3.0-2 | — |
| qt6-declarative (SwipeView/TabBar/TabButton) | Pager + header (D-17/D-18) | ✓ `[VERIFIED: pacman -Ql]` | 6.11.1-3 | — |
| Quickshell.Services.UPower | Battery widget | ✓ module installed; `[VERIFIED: systemctl is-active upower → active]` daemon running | ships with quickshell 0.3.0-2 | If UPower ever stops being available, fall back to hand-parsed `/sys/class/power_supply/` (documented in Don't Hand-Roll as the inferior default, kept only as a last resort) |
| Battery hardware | Battery widget's "populated" render state | ✗ `[VERIFIED: upower -e / /sys/class/power_supply/ both empty on this machine]` | — | Empty-state rendering only, locally; see Open Question 4 |
| `ttf-material-symbols-variable-git` (AUR) | Icon system (D-28) | ✗ not yet installed | latest `-git` (unpinned) | Vendor the TTF directly if the AUR package is found unmaintained at the human-verify checkpoint |
| Open-Meteo API (network) | Weather tab | Assumed ✓ (generic internet access) `[VERIFIED: live HTTP fetch succeeded this session]` | keyless, current API surface | D-33's stale-cache degradation IS the designed fallback for any future outage |
| `curl`/`jq` (if the weather fetch is implemented as a helper script rather than `XMLHttpRequest`) | Optional weather-fetch alternative | ✓ both already used extensively elsewhere in this repo | — | — |

**Missing dependencies with no fallback:** none — every missing/absent item above has a documented fallback or is an accepted local-hardware limitation.
**Missing dependencies with fallback:** `ttf-material-symbols-variable-git` (vendor-the-font fallback); battery hardware (empty-state-only local verification, real hardware needed for full populated-state proof).

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-------------------|
| V2 Authentication | No | Drawer has no auth surface |
| V3 Session Management | No | No session concept in this phase |
| V4 Access Control | No | Single-user desktop, no privilege boundary crossed |
| V5 Input Validation | Yes | (1) Every field from `media-status.sh watch` is ALREADY sanitized upstream (`_sanitize`, `_valid_id`) — the drawer's job is to consume it defensively (never `eval`/re-parse as code) and degrade to the empty-state placeholder on malformed JSON, exactly like `Colours.qml`/`Motion.qml`'s existing `try/catch` + fallback-default convention. (2) The Open-Meteo JSON response is third-party network data — wrap every parse in `try/catch`, never trust field presence, and treat an unrecognized WMO weather code as the empty-state icon rather than crashing. |
| V6 Cryptography | No | No secrets/crypto in this phase — the weather API is deliberately keyless per D-29 |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|----------------------|
| Command injection via an interpolated player id/verb in a `Process` command array | Tampering | Never build a raw `playerctl ...` command in QML; route every mutating media action through `media-players.sh cmd <id> <verb>`, which already validates `id` against `_valid_id`'s regex before touching a shell command (existing, proven — T-08-07-02) |
| Malformed/hostile third-party JSON (Open-Meteo response, or a corrupted local cache file) crashing the QML engine or rendering garbage | Denial of Service (local) | `try/catch` around every `JSON.parse`, default-safe empty-state rendering on failure — the exact pattern `Colours.qml`/`Motion.qml` already use for `palette.json`/`motion.json` |
| A locally-writable weather state/cache file being hand-edited into an invalid shape (e.g., non-numeric `lat`/`lon`) | Tampering (low severity — local-user-owned dotfile, not a remote attack surface) | Validate the numeric shape before using coordinates in the fetch URL, falling back to the empty/never-configured state (same class of defensive parsing as V5 above) rather than sending a malformed request or crashing |

## Sources

### Primary (HIGH confidence — direct verification on this machine)
- `pacman -Q quickshell qt6-declarative qt6-base qt6-svg` — exact installed versions
- `pacman -Ql qt6-declarative` — confirmed `SwipeView.qml`/`TabBar.qml`/`TabButton.qml` present in Basic and Material styles
- `pacman -Ql quickshell` — confirmed `Quickshell.Services.{UPower,Mpris,Pipewire,Notifications,Polkit,Pam,SystemTray,Greetd}` qmltypes present
- `systemctl is-active upower` / `upower -e` / `ls /sys/class/power_supply/` — UPower daemon active; this machine has zero battery devices
- Live HTTP fetch of `api.open-meteo.com/v1/forecast` this session — confirmed working, keyless, expected JSON shape
- Direct reads of this repo's own `shell.qml`, `Probe.qml`, `Colours.qml`, `Motion.qml`, `qmldir`, `shortcuts.json`, `keybinds.lua`, `windowrules.lua`, `media-status.sh`, `media-players.sh`, `swaync/config.json`, `gaming-mode-toggle.sh`, `motion-switch.sh`, `motion.json`, `contract.json`, `stow.sh`, `install.sh` — exact existing patterns and contracts this phase must fit into
- `motion-lint`'s own source (`load_qml_defs()`) — confirmed only `motion.json`'s `semantic` bucket (not `indicators`) is scanned for allowed `Motion.*` QML references

### Secondary (MEDIUM confidence — WebSearch/WebFetch cross-checked against docs or corroborated by a second source)
- Qt 6 docs (TabBar/SwipeView QML type pages) via WebSearch — synchronization pattern, `highlightMoveDuration` default
- Hyprland Lua `hl.layer_rule` RE2 regex namespace matching — hyprland-lua-docs reference site + DeepWiki, cross-referenced
- Qt `font.variableAxes` — WebSearch of Qt 6.7+ documentation/blog, cross-checked against this machine's installed Qt 6.11.1
- `caelestia-dots/shell` GitHub repository, fetched live via `gh api` this session — `services/Weather.qml`, `modules/dashboard/{Tabs,Wrapper,Content,Performance}.qml` — confirmed four-tab structure, Flickable-based pager (not SwipeView), Open-Meteo forecast/geocoding usage, `ip-api.com` GeoIP fallback, `Quickshell.Services.UPower`/custom `Caelestia.Services` split for hardware stats
- Quickshell official docs (`quickshell.org/docs`) via WebFetch — `WlrKeyboardFocus`, `HyprlandFocusGrab`, `Process` type semantics

### Tertiary (LOW confidence — WebSearch only, not cross-checked, marked for validation)
- `ttf-material-symbols-variable-git` AUR package existence/version — WebSearch only; the AUR page itself was blocked by an anti-bot challenge (Anubis) when fetched directly this session. **Flagged for human verification per the Package Legitimacy Audit.**

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — every core mechanism (SwipeView/TabBar, Process, FileView/JsonAdapter, UPower) was directly verified present and working on this exact machine, not merely assumed from docs
- Architecture: MEDIUM-HIGH — the summon/dismiss/focus pattern is a direct reuse of a QS-02-proven existing surface (HIGH); the pager/tab/backend patterns are well-supported by both Qt docs and a live source-check of the reference shells (MEDIUM)
- Pitfalls: MEDIUM-HIGH — several pitfalls (SwipeView literal duration, Mpris temptation, no-battery-hardware, motion.json's semantic-only scan, JsonAdapter top-level-only mapping, GlobalShortcut restart requirement) are all directly verified facts about this machine/codebase, not inferred; the swaync `--subscribe` and live regex-namespace-matching items remain genuinely open

**Research date:** 2026-07-29
**Valid until:** 30 days for the stable/verified findings (installed package versions, this repo's own contracts); the AUR package's `[SUS]`-flagged legitimacy and the unresolved live-verification items (regex namespace matching, `swaync-client --subscribe`, exact `UPowerDevice` properties) should be re-checked at the start of plan execution regardless of elapsed time, since they were never fully closed this session
