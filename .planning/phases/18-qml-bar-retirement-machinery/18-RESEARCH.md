# Phase 18: QML Bar & Retirement Machinery - Research

**Researched:** 2026-08-10
**Domain:** Quickshell/QML always-on wlr-layer-shell bar, native Quickshell service modules (SystemTray/DBusMenu/Mpris/UPower), process-restart supervision, bash-based retirement/lint tooling
**Confidence:** HIGH — every load-bearing claim below was checked directly against the installed `quickshell 0.3.0-2` package's `.qmltypes` files, this repo's own QML surfaces, and live `hyprctl`/`systemctl`/`pacman` output on this machine, not from training memory or web search.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Bar contents**
- D-18-01: Both athena drawers carry forward, redesigned (8-icon launcher drawer + 5-axis settings drawer).
- D-18-02: Workspace indicators render live per-window app icons, athena's `{icon} {windows}` shape.
- D-18-03: All four extras get permanent slots — power button, gaming-mode toggle, notification bell, updates count + idle inhibitor.
- D-18-04: System tray always visible at end of bar — no chevron, no threshold collapse. Backed by native `Quickshell.Services.SystemTray` + `Quickshell.DBusMenu`.
- D-18-05: Now-playing rides native `Quickshell.Services.Mpris`; `MediaBackend.qml` is repointed onto the same singleton this phase. MPRIS reader count goes 3 → 1.
- D-18-06: Battery entry exists in the list but renders nothing when absent, via native `Quickshell.Services.UPower`.
- D-18-07: No focused-window-title entry.

**Bar shape and grouping**
- D-18-08: Floating detached capsule (athena's posture — height ~40, ~6px edge margin, ~10px side margins), not flush to the screen edge.
- D-18-09: Discrete section capsules with gaps, not one continuous pill.
- D-18-10: Roughly 5–6 capsules grouped by concern.

**Vertical orientation (right edge)**
- D-18-11: Drawers expand inward, horizontally — floating strip growing leftward.
- D-18-12: Workspace slots fixed-height with a `+N` overflow count.
- D-18-13: Zones re-map per orientation — one entry list where each entry carries a zone per orientation (`horizontal: right`, `vertical: top`), never two arrangements.
- D-18-14: Text-bearing entries use stacked/abbreviated text at the same column width (~44px).

**Section popouts (QBAR-09)**
- D-18-15: A new lightweight popout type, separate from `PanelDialog.qml`.
- D-18-16: Six sections get popouts: audio, wifi, bluetooth, clock→calendar, cpu/ram/disk→resources, now-playing→media.
- D-18-17: The dashboard drawer keeps its full four-tab role; popouts are the fast path.
- D-18-18: Interaction is hover-to-preview, click-to-pin.

**Popout hover mechanics**
- D-18-19: Hover-preview suppressed until the reveal animation has settled AND the pointer has moved at least once on the settled bar.
- D-18-20: Dwell before preview ~400ms.
- D-18-21: Unpinned popout closes when the pointer leaves both the section and the popout, with a short grace period.
- D-18-22: A pinned popout ignores hover entirely and dismisses on click-outside.

**Auto-hide and reserved space**
- D-18-23: Per-driver exclusive-zone policy. Idle keeps the reserved zone; fullscreen, gaming mode and the keybind release it.
- D-18-24: Reveal uses an invisible input-only hot zone present only while hidden.
- D-18-25: The hot zone sits on the physical screen edge, ~3–5px deep.
- D-18-26: Re-hide is on a grace timer.

**Visibility ownership**
- D-18-27: The script stays sole owner, renamed `bar-visibility.sh`. Actuation changes from SIGUSR1/SIGUSR2 to `qs ipc call`.
- D-18-28: `waybar-fullscreen-watch.sh` is retired; the shell reports fullscreen intent to the owner instead.
- D-18-29: Super+Shift+B stays a Hyprland bind to the owner script, not a QML `GlobalShortcut`.
- D-18-30: `waybar-switch.sh`'s four-layout picker becomes a horizontal/vertical orientation toggle in the settings drawer and Super-key menu.

**GATE-02 human render gate**
- D-18-31: The gate runs at checkpoints during the phase plus one blocking final pass before the deletion commit.
- D-18-32: Comparison baseline is athena for the aesthetic judgment, plus a named-capability check against full/floating/vertical.

**Notification bell**
- D-18-33: The bell is wired to swaync for this phase (temporary, Phase 19 swaps the backend without touching the layout).

**Retirement checklist (RETIRE-01)**
- D-18-34: Generic from day one — `retirement-check <surface-name>`, not waybar-shaped.
- D-18-35: Blocking, folded into `theme-doctor`, following the `waybar-design-lint`/`motion-lint` fold pattern.
- D-18-36: Coverage extends to all four: theme-doctor internals, test fixtures/doctor registries, cross-script references, planning docs/prose.
- D-18-37: Two tiers in one script — blocking tier over live code/config/fixtures/checker internals, reported (non-failing) tier over `.planning/`/repo prose.

### Claude's Discretion
- Exact capsule split within D-18-10's 5–6 by-concern shape (UI-SPEC already resolved this to 6: `[launcher]` `[system]` `[workspaces]` `[media + connectivity]` `[clock + actions]` `[tray]`).
- Grace-period and dwell tuning around D-18-20/21/26's stated values, as long as D-18-19's suppression rule holds (UI-SPEC resolved: `popoutDwellMs 400`, `popoutDismissGraceMs 200`, `barReHideGraceMs 600`, `hotZoneDepth 4`).
- Per-app glyph map contents for D-18-02 (seed from athena's existing `window-rewrite` table in `waybar/.config/waybar/config-athena.jsonc`).
- All of GATE-03's `quickshell-doctor` structural checks, GATE-04's hex-literal lint shape, LEDGER-01's documentation corrections, and LEDGER-03's frame-rate measurement method.

### Deferred Ideas (OUT OF SCOPE)
- Caelestia's shrink-to-a-sliver auto-hide — leaves static pixels lit, against the OLED constraint.
- Popouts replacing dashboard tabs — a v5.0 question if duplication proves annoying.
- Orientation toggle as a keybind — free plain-Super letters are scarce.
- Generalising `bar-visibility.sh` into one owner shared with `wallpaper-visibility.sh` — worth revisiting only once a third owner appears.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| QBAR-01 | Permanently-mounted bar, reserves screen space, Athena rounded-capsule language | `PanelWindow`/`WlrLayershell` property surface verified (exclusiveZone/margins/anchors); live `hyprctl monitors -j` baseline captured; exclusiveZone-formula pitfall documented below |
| QBAR-02 | One component, horizontal↔vertical from config, entry-list-driven | UI-SPEC's per-orientation zone-list already locked (D-18-13); `Overview.qml`'s single-`PanelWindow` pattern is the copy target |
| QBAR-03 | Click workspace to switch | `Quickshell.Hyprland` dispatch pattern already proven in `shell.qml`/`Overview.qml` (`Hyprland.dispatch`, `HyprlandToplevel`) |
| QBAR-04 | Scroll on audio/brightness sections to adjust | Audio: `AudioBackend.qml` already exposes `setMasterVolume()` — reuse directly. Brightness: **no functioning backend or hardware target exists on this host** — flagged as a Common Pitfall / Open Question below |
| QBAR-05 | Tray shows apps, menus open on click | `Quickshell.Services.SystemTray` + `Quickshell.DBusMenu` + `QsMenuOpener` verified present with full property/method surface |
| QBAR-06 | Clock/battery/network/bluetooth/audio/CPU-RAM-disk readouts | `UPower`, existing `WifiBackend`/`BluetoothBackend`/`AudioBackend`/`SystemResources` all reusable; battery hides per D-18-06 |
| QBAR-07 | Full auto-hide, one visibility owner | `bar-visibility.sh` (renamed `waybar-visibility.sh`) state machine fully read; actuation swap to `qs ipc call` documented |
| QBAR-08 | Reveal on hover or holding Super | Hot-zone-as-separate-surface pattern; Super-hold requires a `GlobalShortcut`-adjacent mechanism — see Open Questions (no native "modifier held" signal found in the verified API surface) |
| QBAR-09 | Section popouts, not routed through dashboard | New popout frame fully specified in UI-SPEC; `PanelDialog.qml` read in full for contrast |
| QBAR-10 | Auto-restart on process death | `quickshell-launch.sh` read in full — confirmed no restart wrapper today; `waybar.service`'s upstream-shipped `Restart=on-failure` unit found unused as a live precedent; two viable mechanisms compared below |
| QBAR-11 | Flat RSS/process/timer count over a multi-hour soak | Zero-idle doctrine documented; the bar's own permanent-liveness hazard (first surface with no dismissed state) named explicitly; `AudioBackend`'s `PwObjectTracker` gating consequence flagged |
| QBAR-12 | Reserved zone survives `hyprctl reload` + QML hot reload | `ProxyWindowBase`'s `Reloadable` prototype confirms Quickshell's own hot-reload mechanism exists structurally; live baseline captured for a regression check |
| RETIRE-01 | Generic retirement checklist script | `theme-doctor`'s existing fold pattern (`waybar-design-lint`, `motion-lint`) read in full and is the direct template |
| RETIRE-02 | waybar removed — package, config, contract entries, template, checks | Full file inventory enumerated below (12 config files, 6 scripts, 7 contract entries + 2 adjacent state files, 2 `windowrules.lua` rules, 6 quickshell-doctor test fixtures) |
| GATE-01 | Enumerate current behaviour before redesign, per-phase | Waybar's live `config-*.jsonc`/`modules.jsonc` read; GATE-02's B-criteria in UI-SPEC already operationalize this |
| GATE-02 | Human render-and-look gate, no downgrade, blocks deletion | UI-SPEC's criteria A/B tables are the checkable artifact; D-18-31/32 already locked |
| GATE-03 | `quickshell-doctor` structural checks for the bar | Existing check-registration pattern (`_qsd_check_*`, `check()` helper, self-test fixture harness) read in full; the specific "reserved-space stays unclaimed" check's assumption-breaking consequence documented |
| GATE-04 | QML hex-literal lint, deny-by-default | `motion-lint`'s CHECK A/B/C + EXEMPTIONS shape read in full; a concrete Colours.qml exemption/scope pitfall documented |
| LEDGER-01 | Doc-only bookkeeping close | No new research needed — visual confirmation already taken per CONTEXT.md/REQUIREMENTS.md |
| LEDGER-03 | OVER-04 frame-rate term measured | Prior FPS-measurement attempt **froze the host** — documented in full below with the safe alternative already proven in this repo |
</phase_requirements>

## Summary

This phase builds the first Quickshell surface in this repo that is permanently mounted (no dismissed state), the first that claims `exclusiveZone > 0`, and the first that must survive process death automatically. All three of those properties are structurally new — every prior Quickshell surface (`Dashboard`, the three panels, `Overview`) is LazyLoader-summoned, `exclusiveZone: 0`, and disposable. The bar inherits none of the zero-idle discipline those surfaces rely on, which is precisely the hazard the phase notes name.

The good news: quickshell 0.3.0-2, installed on this machine, ships every native service module the bar needs — `SystemTray`, `DBusMenu` (with `QsMenuOpener`), `Mpris`, `UPower` — each verified directly against its `.qmltypes` file rather than assumed from documentation or training data. `WlrLayershell`'s `exclusiveZone`/`margins`/`anchors`/`layer`/`namespace` properties are the same ones `PanelDialog.qml` and `Overview.qml` already use at `exclusiveZone: 0`; the bar is simply the first to set it non-zero. `Overview.qml`'s single-`PanelWindow` pattern (no `Variants`, per the permanently-dropped QS-03) is the direct structural template.

Three findings from this session materially change what the planner needs to account for, beyond what CONTEXT.md/UI-SPEC.md already lock down:

1. **The exclusiveZone formula in 18-UI-SPEC.md's "Auto-Hide & Reveal Motion Contract" section (`barHeight + barEdgeMargin*2` = 52px) does not match this host's live, currently-working waybar reservation** (`hyprctl monitors -j` reports `reserved: [0, 46, 0, 0]` right now — i.e. `barHeight(40) + barEdgeMargin(6)` = 46, a single margin, not doubled). If the bar is built to the UI-SPEC's literal formula it will reserve 6px more than the live baseline it's meant to match pixel-for-pixel at GATE-02.
2. **QBAR-04's "scroll on brightness sections" has no live target on this host.** `/sys/class/backlight/` is empty (desktop board, no laptop panel), the `light` binary waybar's own `config-floating.jsonc` backlight module shells out to is not installed, and there is no QML brightness backend anywhere in the repo today. This capability has been a dead no-op in the *existing* waybar config too — it is not a phase-18 regression, but it means GATE-02 criterion B.3 cannot be demonstrated live on this machine and the planner needs an explicit, named decision about what "exists but inert" looks like here (mirroring D-18-06's battery precedent).
3. **CONTEXT.md D-18-27's stated rationale — "Quickshell 0.3.0-2 cannot detect idle... there is no ext-idle-notify consumer" — is factually incorrect.** `Quickshell.Wayland._IdleNotify` ships an `IdleMonitor` type (`enabled`, `timeout`, `respectInhibitors`, `isIdle`) that IS a genuine `ext-idle-notify-v1` consumer, verified directly in the installed `.qmltypes`. This does not change the locked decision (the script stays the sole owner for good independent reasons — restart survival, on-disk state, and the six existing callers) but the reasoning recorded for the decision is wrong and should not be repeated as fact in the plan or in a future phase's research.

Also load-bearing: LEDGER-03's frame-rate measurement must **not** repeat Phase 16's FPS-overlay attempt (`hyprctl eval 'hl.config({ debug = { overlay = true } })'`), which froze this exact host hard enough to require a physical restart. This repo already has a safe, previously-used alternative (`QSG_RENDER_TIMING=1`, Qt's own render-timing instrumentation, already exercised in `quickshell-launch.sh`'s own header comment for the render-loop decision) — use that, not Hyprland's debug overlay.

**Primary recommendation:** Build the bar as a single `PanelWindow` (no `Variants`) that copies `Overview.qml`'s layer-posture idiom but sets `exclusiveZone` to the single-margin formula matching the live baseline; wire every readout through the existing panel-family backends already mounted at `shell.qml`'s root; drive tray + menu through `SystemTray`/`QsMenuOpener` natively; keep `bar-visibility.sh` (renamed) as sole visibility owner, actuating via `qs ipc call` instead of signals; and measure LEDGER-03 with `QSG_RENDER_TIMING=1`, never the Hyprland debug overlay.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Bar rendering/layout (capsules, orientation, popouts) | Quickshell/QML shell (client) | — | Wayland client surface, layer-shell rendered; no server tier in this desktop-shell architecture |
| Workspace switching (QBAR-03) | Quickshell/QML shell | Hyprland compositor (IPC target) | QML dispatches `hyprctl`-equivalent commands via `Quickshell.Hyprland`; compositor executes the actual workspace change |
| Audio/network/bluetooth/tray/mpris/upower state | Quickshell native service singletons (`Pipewire`, `SystemTray`, `Mpris`, `UPower`) + this repo's existing `*Backend.qml` wrappers | System D-Bus services (PipeWire, NetworkManager, BlueZ, StatusNotifierWatcher, upowerd) | Backends already exist and are mounted at `shell.qml` root; the bar is a new *consumer* of state these already own, not a new owner |
| Visibility state (show/hidden-idle/hidden-hard) | `bar-visibility.sh` (bash, single owner) | Quickshell (actuation target via `qs ipc call`) | Deliberately kept out of the QML process per D-18-27 — survives QBAR-10 restarts, matches the two-instance precedent (`wallpaper-visibility.sh`) |
| Process supervision/restart (QBAR-10) | systemd `--user` or a shell respawn wrapper (OS/init tier) | Quickshell process itself | The bar cannot supervise its own death; must be external to the process |
| Retirement verification (RETIRE-01, GATE-03/04) | Bash tooling (`theme-doctor`, `quickshell-doctor`, new `retirement-check`) | — | Report-only, mechanical, fold into existing doctor tally — matches every prior gate in this repo |
| Idle detection | hypridle (external daemon) | Quickshell `_IdleNotify.IdleMonitor` (available but unused by design, D-18-27) | Locked decision keeps hypridle as the sole idle source despite a native alternative existing |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| quickshell | 0.3.0-2 (installed) [VERIFIED: `pacman -Q quickshell`] | QML shell runtime, layer-shell windows, native service modules | Already the chosen stack (PROJECT.md); this phase is a consumer of the same binary Phases 11-17 already built against |
| `Quickshell.Wayland` → `WlrLayershell`/`WlrLayer`/`WlrKeyboardFocus` | ships with quickshell 0.3.0-2 [VERIFIED: `/usr/lib/qt6/qml/Quickshell/Wayland/_WlrLayerShell/quickshell-wayland-layershell.qmltypes`] | Layer-shell surface control: `layer`, `namespace`, `keyboardFocus`, `anchors`, `exclusiveZone`, `exclusionMode`, `margins`, `aboveWindows`, `focusable` | Exact API `PanelDialog.qml`/`Overview.qml`/`Dashboard.qml` already use at `exclusiveZone: 0` — the bar is the same API at a non-zero value |
| `Quickshell._Window` → `PanelWindow` | ships with quickshell 0.3.0-2 [VERIFIED: `/usr/lib/qt6/qml/Quickshell/_Window/quickshell-window.qmltypes:131-201`, exports `Quickshell._Window/PanelWindow 0.0`] | Cross-platform panel surface base: `anchors`, `margins`, `exclusiveZone`, `exclusionMode`, `aboveWindows`, `focusable` | Same type every existing summonable surface roots on; `PanelWindow`'s generic properties are re-exposed per-platform via the attached `WlrLayershell.*` properties on wlroots |
| `Quickshell.Services.SystemTray` | ships with quickshell 0.3.0-2 [VERIFIED: `/usr/lib/qt6/qml/Quickshell/Services/SystemTray/quickshell-service-statusnotifier.qmltypes`] | `SystemTray.items` (list of `StatusNotifierItem`: id/title/status/category/icon/tooltipTitle/tooltipDescription/hasMenu/menu/onlyMenu; methods `activate()`/`secondaryActivate()`/`scroll()`/`display()`) | Confirmed already the D-18-04 choice; full property surface verified directly, not assumed |
| `Quickshell.DBusMenu` + core `QsMenuOpener`/`QsMenuAnchor` | ships with quickshell 0.3.0-2 [VERIFIED: `/usr/lib/qt6/qml/Quickshell/DBusMenu/quickshell-dbusmenu.qmltypes`, `/usr/lib/qt6/qml/Quickshell/quickshell-core.qmltypes:1685-1900`] | `StatusNotifierItem.menu` returns a `DBusMenuHandle` (`qs::dbus::dbusmenu::DBusMenu`); feed it into a `QsMenuOpener{ menu: item.menu }` to get `.children` (list of `QsMenuEntry`: text/icon/enabled/isSeparator/buttonType/checkState/hasChildren, `triggered`/`opened`/`closed` signals) | This is the standard tray-menu-opening idiom for Quickshell; verified end-to-end (`StatusNotifierItem.menu` → `DBusMenuHandle` → `QsMenuOpener.children` → `QsMenuEntry`) rather than assumed from a reference shell |
| `Quickshell.Services.Mpris` | ships with quickshell 0.3.0-2 [VERIFIED: `/usr/lib/qt6/qml/Quickshell/Services/Mpris/quickshell-service-mpris.qmltypes`] | `Mpris.players` (list of `MprisPlayer`: identity/position/length/volume/trackTitle/trackArtist/trackArtists/trackAlbum/trackAlbumArtist/trackArtUrl/playbackState/loopState/shuffle + `*Supported` flags + `play`/`pause`/`stop`/`togglePlaying`/seek methods) | D-18-05's "full property surface" claim confirmed directly — this is the repoint target for `MediaBackend.qml` |
| `Quickshell.Services.UPower` | ships with quickshell 0.3.0-2 [VERIFIED: `/usr/lib/qt6/qml/Quickshell/Services/UPower/quickshell-service-upower.qmltypes`] | `UPower.displayDevice`/`UPower.devices`/`UPower.onBattery`; `UPowerDevice`: type/powerSupply/energy/energyCapacity/changeRate/timeToEmpty/timeToFull/percentage/isPresent/state/healthPercentage/iconName/isLaptopBattery/nativePath/model/ready | D-18-06's chosen backend; `isPresent`/`isLaptopBattery` are the exact fields to gate the "renders nothing when absent" behaviour on |
| `Quickshell.Hyprland` | ships with quickshell 0.3.0-2, already imported in `shell.qml`/`Overview.qml` | Workspace dispatch (QBAR-03), `Hyprland.activeToplevel`, `Hyprland.refreshToplevels()`, `onRawEvent` for fullscreen intent reporting (QBAR-28... D-18-28) | Already proven live in this repo — `shell.qml`'s `fullscreenBlocking` guard and `Connections{ target: Hyprland; onRawEvent }` are the direct pattern QBAR-28's fullscreen-intent reporter should copy |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `Quickshell.Wayland._IdleNotify` (`IdleMonitor`) | ships with quickshell 0.3.0-2 [VERIFIED: `/usr/lib/qt6/qml/Quickshell/Wayland/_IdleNotify/quickshell-wayland-idle-notify.qmltypes`] | Native `ext-idle-notify-v1` consumer: `enabled`/`timeout`/`respectInhibitors`/`isIdle` | **Exists but is NOT to be used this phase** — D-18-27 deliberately keeps hypridle as the idle source. Documented here only to correct the record: this type's existence contradicts D-18-27's stated rationale ("cannot detect idle"), though not its conclusion |
| `Quickshell.Io.Process` / `Quickshell.Io.FileView` | ships with quickshell 0.3.0-2, already used throughout `modules/dashboard/*.qml` | Shelling out to `brightnessctl` if a brightness backend is built; reading `qs ipc` state | Same idiom `AudioBackend.qml`/`WifiBackend.qml` already use for their own backends |
| `env QSG_RENDER_TIMING=1` | Qt 6 built-in (not a package — an env var honored by Qt Quick's scene graph) [VERIFIED: comment header of `hypr/.config/hypr/scripts/quickshell-launch.sh`, already used in this repo for the `QSG_RENDER_LOOP=threaded` decision] | Per-frame sync/render/swap timing without touching the compositor | **This is LEDGER-03's measurement tool — see Common Pitfalls for why the Hyprland debug overlay must not be used instead** |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `qs ipc call` actuation (D-18-27, locked) | Raw `hyprctl`/signal-based actuation (SIGUSR1/SIGUSR2, waybar's old model) | Not applicable to Quickshell — Quickshell has no signal-based visibility toggle; `qs ipc call <target> <verb>` (already proven via `panelIpc`/`overviewIpc` in `shell.qml`) is the only mechanism |
| systemd `--user` unit for QBAR-10 restart | Shell respawn loop inside `quickshell-launch.sh` | See "Restart mechanism" in Common Pitfalls — both are viable, this repo's own `uwsm app --` convention is a real deviation-cost against the systemd-unit option |
| Native `Quickshell.Services.UPower` for battery | Continue shelling to `acpi`/`upower` CLI | No reason to — UPower module is already the D-18-06 choice and avoids a subprocess per poll |

**Installation:**
No new packages are installed by this phase's bar work — every module used (`SystemTray`, `DBusMenu`, `Mpris`, `UPower`, `Hyprland`, `Wayland`) ships inside the already-installed `quickshell` package. `brightnessctl` (if a brightness backend is built) is already installed [VERIFIED: `which brightnessctl` → `/usr/bin/brightnessctl`]. RETIRE-02 *removes* the `waybar` package; no `npm view`/`pip index`-equivalent version-verification step applies (this is a pacman package already resolved in `install.sh`, being deleted, not added).

## Package Legitimacy Audit

Not applicable — this phase installs no new external packages. It ships zero new third-party dependencies (every QML module consumed is already inside the installed `quickshell` binary) and *removes* one existing package (`waybar`, already vetted at the phase it was first installed). The Package Legitimacy Gate protocol is skipped per its own trigger condition ("phase that installs external packages").

## Architecture Patterns

### System Architecture Diagram

```
 Hardware/compositor events                  User interaction
 (idle timeout, fullscreen enter/exit,        (hover bar edge, click
  gaming-mode toggle, Super+Shift+B)           workspace/tray/section)
        │                                             │
        ▼                                             ▼
 ┌─────────────────────────┐                 ┌──────────────────────┐
 │  bar-visibility.sh       │  qs ipc call    │   QML Bar (PanelWindow)│
 │  (bash, sole owner,      │────────────────▶│   - always mounted,    │
 │  flock'd RMW, per-source │  visibility.*   │     exclusiveZone > 0  │
 │  intent files)           │  verb           │   - hot-zone surface   │
 └─────────────────────────┘                 │     (present only      │
        ▲                                     │     while hidden)      │
        │ intent writes                       └──────────┬────────────┘
 ┌──────┴───────────────────────────┐                    │ reads
 │ hypridle (idle) · shell.qml       │                    ▼
 │ fullscreen-intent reporter        │        ┌─────────────────────────┐
 │ (replaces waybar-fullscreen-      │        │ Existing panel-family    │
 │ watch.sh) · gaming-mode-toggle.sh │        │ backends (already mounted│
 │ · keybinds.lua Super+Shift+B      │        │ at shell.qml root):      │
 └────────────────────────────────────┘       │ AudioBackend, WifiBackend,│
                                               │ BluetoothBackend,         │
                                               │ SystemResources, native   │
                                               │ Mpris/UPower/SystemTray   │
                                               └───────────┬───────────────┘
                                                            │ D-Bus / PipeWire /
                                                            │ NetworkManager / BlueZ /
                                                            │ upowerd / StatusNotifierWatcher
                                                            ▼
                                               ┌─────────────────────────┐
                                               │ System services (already │
                                               │ running, unmodified)     │
                                               └─────────────────────────┘

 Click workspace ──▶ Quickshell.Hyprland dispatch ──▶ Hyprland compositor
 Click tray icon ──▶ StatusNotifierItem.activate() ──▶ tray app
 Click tray menu  ──▶ QsMenuOpener{menu: item.menu} ──▶ DBusMenuItem.triggered ──▶ tray app
 Click section    ──▶ new popout PanelWindow (hover-preview/click-pin) ──▶ same backend as dashboard tab
```

### Recommended Project Structure
```
quickshell/.config/quickshell/modules/
├── Bar.qml                  # new — PanelWindow root, mounted unconditionally in shell.qml (not a LazyLoader)
├── bar/
│   ├── BarCapsule.qml       # reusable discrete-capsule chrome (D-18-09)
│   ├── BarEntryModel.qml    # the one entry-list (D-18-13): per-orientation zone, capsule membership, glyph
│   ├── WorkspaceCapsule.qml # live per-app icons, fixed-height slots + overflow (D-18-02/D-18-12)
│   ├── TrayCapsule.qml      # SystemTray.items iteration, QsMenuOpener wiring (QBAR-05)
│   ├── HotZone.qml          # input-only surface, created/destroyed with hidden state (D-18-24)
│   └── SectionPopout.qml    # the new lightweight popout type (D-18-15), parameterized like PanelDialog.qml
├── dashboard/
│   ├── MediaBackend.qml     # MODIFIED — repointed onto Quickshell.Services.Mpris (D-18-05)
│   └── Design.qml           # MODIFIED — new bar-specific tokens appended (barHeight, barEdgeMargin, ...)
hypr/.config/hypr/scripts/
├── bar-visibility.sh        # RENAMED from waybar-visibility.sh (D-18-27); actuation swapped to `qs ipc call`
├── retirement-check         # NEW — RETIRE-01's generic checklist script
└── (waybar-fullscreen-watch.sh, waybar-design-lint, waybar-equivalence-check — DELETED)
```

### Pattern 1: Copy `Overview.qml`'s single-`PanelWindow` posture, not `Variants`
**What:** Root the bar on exactly one `PanelWindow`, imported via `import Quickshell` / `import Quickshell.Wayland`, with `WlrLayershell.layer`/`.namespace`/`.keyboardFocus` set as attached properties, exactly as `Overview.qml:26-56` does.
**When to use:** Always, for this phase — QS-03 (per-screen fan-out) is a permanently-accepted limitation on this quickshell build (D-13, PROJECT.md); a `Variants`-rooted bar reproduces the same FM2-class failure `Overview.qml`'s header comment (line 36-44) already documents as reverted twice.
**Example:**
```qml
// Source: verified against quickshell/.config/quickshell/modules/Overview.qml:26-56 (this repo, Read tool)
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import "dashboard"

PanelWindow {
    id: barWindow

    anchors { top: true; left: true; right: true }   // horizontal orientation
    // anchors { top: true; bottom: true; right: true } // vertical orientation (D-02 "right")

    WlrLayershell.layer: WlrLayer.Top          // NOT Overlay — the bar is always-on chrome, not a transient dialog
    WlrLayershell.namespace: "quickshell-bar"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None  // the bar itself never wants keyboard focus
    // exclusiveZone: verify against the live baseline formula — see Common Pitfalls "exclusiveZone arithmetic"
    exclusiveZone: Design.barHeight + Design.barEdgeMargin   // 46, NOT barHeight + barEdgeMargin*2
    exclusionMode: ExclusionMode.Normal
    color: "transparent"
}
```

### Pattern 2: Tray + menu via native SystemTray/DBusMenu (QBAR-05)
**What:** Iterate `SystemTray.items`, render each `StatusNotifierItem`'s icon, and open its menu through a `QsMenuOpener`.
**When to use:** For the always-visible tray capsule (D-18-04).
**Example:**
```qml
// Source: verified against quickshell-core.qmltypes:1685-1900 and
// quickshell-service-statusnotifier.qmltypes / quickshell-dbusmenu.qmltypes (installed 0.3.0-2, this session)
import Quickshell.Services.SystemTray
import Quickshell.DBusMenu
import Quickshell

Repeater {
    model: SystemTray.items   // UntypedObjectModel of StatusNotifierItem

    delegate: Item {
        required property var modelData   // the StatusNotifierItem
        // modelData.icon, modelData.tooltipTitle, modelData.hasMenu

        MouseArea {
            anchors.fill: parent
            onClicked: modelData.activate()          // left-click action
            onSecondaryClicked: menuOpener.open()     // opens the DBusMenu, see below
        }

        QsMenuOpener {
            id: menuOpener
            menu: modelData.menu   // DBusMenuHandle, present when modelData.hasMenu
        }
        // menuOpener.children is an UntypedObjectModel of QsMenuEntry — render as a
        // list, wire each entry's click to whatever mechanism actually triggers a
        // QsMenuEntry (verify exact trigger call against Quickshell's own example
        // shell during implementation — the .qmltypes file exposes text/icon/
        // enabled/isSeparator/buttonType/checkState/hasChildren and a `triggered`
        // SIGNAL but no explicitly-named `trigger()` INVOKABLE was found in this
        // scan; see Open Questions).
    }
}
```

### Pattern 3: Fullscreen-intent reporting replaces `waybar-fullscreen-watch.sh` (D-18-28)
**What:** Reuse `shell.qml`'s already-proven `Hyprland.activeToplevel`/`onRawEvent` combination instead of a standalone bash socket2 listener.
**When to use:** The bar (or a shell-root `Connections` block) must call `bar-visibility.sh fullscreen hide|show` on the same "fullscreen" socket2 event `shell.qml:350-357` already subscribes to.
**Example:**
```qml
// Source: verified against quickshell/.config/quickshell/shell.qml:343-357 (this repo, Read tool)
readonly property bool isFullscreen: (Hyprland.activeToplevel?.lastIpcObject?.fullscreen ?? 0) === 2

Connections {
    target: Hyprland
    function onRawEvent(event) {
        if (event.name === "fullscreen") {
            Hyprland.refreshToplevels();
            // then re-derive isFullscreen and Process.startDetached(["bar-visibility.sh","fullscreen", isFullscreen ? "hide" : "show"])
        }
    }
}
```
Note the same live-verified caveat `shell.qml:314-335` already records: on this Hyprland 0.56.1 build, `fullscreen:2` is reported identically for both "true fullscreen" and "maximized" — there is no IPC signal to distinguish them. Whatever the bar does with this value inherits that same ambiguity; it is not a new problem this phase introduces.

### Anti-Patterns to Avoid
- **A second `Variants`/per-screen fan-out attempt:** Explicitly forbidden by CONTEXT.md's Notes block and PROJECT.md's D-13 — reproduces a proven-twice FM2-class failure.
- **Reusing `PanelDialog.qml` directly for section popouts:** D-18-15 already rejected this; `PanelDialog` is `anchors.top`-only (compositor-centred), fixed 850×620, `exclusiveZone: 0` — reusing it reopens the exact same surface `Super+A` already opens, delivering nothing new for QBAR-09.
- **Signaling waybar-style SIGUSR1/SIGUSR2 to the QML process:** Quickshell has no such mechanism; the only actuation path proven in this repo is `qs ipc call <target> <verb>` (`shell.qml`'s `panelIpc`/`overviewIpc`).
- **Trusting the Hyprland debug overlay for FPS measurement:** proven to hard-freeze this exact host (16-OVER04-MEASUREMENT.md) — see Common Pitfalls.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| System tray protocol (StatusNotifierItem/Watcher) | A custom D-Bus StatusNotifierWatcher client | `Quickshell.Services.SystemTray` | Already fully implemented and verified present with the exact property surface QBAR-05 needs |
| Tray context menus (DBusMenu protocol) | A custom `com.canonical.dbusmenu` parser | `Quickshell.DBusMenu` + `QsMenuOpener` | Protocol parsing, layout updates and item-property tracking are already handled natively |
| MPRIS polling | Another `playerctl`/`media-status.sh`-style subprocess-forking watcher | `Quickshell.Services.Mpris` | This is literally what D-18-05 chooses, and it eliminates the ~10-forks/sec loop `MediaBackend.qml:90`'s `media-status.sh watch` currently runs |
| Battery/power state | `acpi`/`upower` CLI polling on a timer | `Quickshell.Services.UPower` | Native, reactive properties (`percentage`, `state`, `isPresent`) — no subprocess, no poll interval to tune |
| Retirement-completeness checking | A one-off waybar-specific grep script | `retirement-check <surface-name>` (RETIRE-01, generic from day one) | This exact tool is reused unmodified by Phases 19-21 for swaync/swayosd/wleave/ags — building it waybar-shaped here means rebuilding it under time pressure in Phase 19 with no soak window |
| Hex-literal detection | A single broad regex over every `.qml` file | `motion-lint`'s narrow, context-anchored regex pattern (property-context, not "any hex-shaped string") | A broad scan will false-positive on `Colours.qml`'s own 19 `"#FF00FF"` JsonAdapter fallback defaults — see Common Pitfalls |

**Key insight:** Every native module this phase needs (tray, menu, mpris, upower) already ships inside the installed `quickshell` binary and was individually confirmed present with the exact properties CONTEXT.md's decisions assume — there is no reason for this phase to write any subprocess-polling backend for these four domains. The one domain that genuinely has no existing backend and no live hardware target on this host is brightness (see Open Questions) — that is the one place "don't hand-roll" doesn't resolve cleanly, because there is nothing native OR existing to reuse.

## Runtime State Inventory

> Required — this phase retires waybar (RETIRE-02) and renames a live-owner script (D-18-27).

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | **None** — verified: waybar has no database/keyed-collection backing store anywhere in this stack (no ChromaDB/Mem0-style user_id, no SQLite). All persistent waybar-adjacent state is flat files under `~/.cache/` and `~/.local/state/theme/`, fully enumerated below | None — the flat-file state is covered under "Build artifacts" and "Secrets/env vars" rows |
| Live service config | `/usr/lib/systemd/user/waybar.service` — a **packaged, upstream-shipped** unit (`Restart=on-failure`, `ExecStart=/usr/bin/waybar`) [VERIFIED: `systemctl --user cat waybar.service`, this session] — but this repo's `autostart.lua:42` launches waybar via `uwsm app -- ~/.config/hypr/scripts/waybar-launch.sh`, **never** via `systemctl --user start waybar.service`. The unit shows as `disabled` in `systemctl --user list-unit-files` | No live systemd state to migrate — the unit is dormant, never enabled/started by this repo. Uninstalling the `waybar` package removes the unit file automatically. Nothing to unregister |
| OS-registered state | Transient systemd `--user` scopes created by `uwsm app --` at each launch (e.g. `app-Hyprland-waybar-launch.sh-*.scope`, `app-Hyprland-waybar-fullscreen-watch.sh-*.scope`) [VERIFIED: `systemctl --user list-unit-files`, this session] | These are ephemeral (`transient`, no `[Install]` section, vanish on process exit) — nothing survives a reboot or needs explicit cleanup |
| Secrets/env vars | None — waybar uses no secrets, no SOPS-managed keys, no CI/CD env vars | None |
| Build artifacts / installed packages | (1) `waybar` pacman package itself, listed in `install.sh:73` [VERIFIED: `install.sh` line grep, this session]. (2) `~/.cache/current-waybar-layout` state file (`stow.sh:260` seeds it) — becomes the orientation-toggle's state file per D-18-30, needs a rename/repurpose decision, not deletion, since the toggle mechanism is reused. (3) `~/.cache/waybar-visibility.d/` intent-file directory (per-source hide/show files, `.override`, `.actuated`, `.owner.lock`) — the exact mechanism D-18-27 keeps, only renamed | (1) remove from `install.sh`'s pacman package list. (2)/(3) are **code edits** (rename paths in the renamed script), not data migrations — no existing intent-file *content* needs transformation, only the directory/script name |

**Additional two files not among RETIRE-02's "7 contract entries" but directly adjacent, easy to miss:**
- `waybar-font.css` — listed separately in `contract.json`'s `presence_only_files` array [VERIFIED: `theme-engine/.config/theme-engine/contract.json:34`, quoted: `"presence_only_files": ["kitty-font.conf", "waybar-font.css"]`]
- `waybar-visibility.css` — listed in `contract.json`'s `engine_owned_files` array [VERIFIED: `theme-engine/.config/theme-engine/contract.json:43`, quoted: `"waybar-visibility.css",`] — this is the file `bar-visibility.sh` writes the idle-dim CSS rule into; it is retired outright (the "hidden-idle" state is no longer a CSS opacity rule, it's a QML property), not renamed

## Common Pitfalls

### Pitfall 1: exclusiveZone arithmetic — UI-SPEC's stated formula does not match the live baseline
**What goes wrong:** 18-UI-SPEC.md's "Auto-Hide & Reveal Motion Contract" section states the `visible` state reserves `barHeight + barEdgeMargin*2` = 52px (horizontal) / `barColumnWidth + barEdgeMargin*2` = 56px (vertical) — doubling the edge margin.
**Why it happens:** The doubled-margin reading treats the margin as "gap on both the outer screen-edge side and the inner window-facing side." But `hyprctl monitors -j`'s live `reserved` array on this exact host right now reports `[0, 46, 0, 0]` [VERIFIED: `hyprctl monitors -j` output, this session] — i.e. today's real waybar (height 40, `margin-top: 6`) reserves exactly `40 + 6 = 46`, a *single* margin, not 52. wlr-layer-shell's `exclusiveZone` convention (and this is what waybar's own GTK layer-shell binding already computes) is "distance from the anchored edge to the far edge of the reserved region," which for a top-anchored, top-margined surface is `height + margin.top` — the margin is only added once, on the side between the screen edge and the surface.
**How to avoid:** Set `exclusiveZone: Design.barHeight + Design.barEdgeMargin` (46), matching the live baseline, unless there is a deliberate reason (recorded, not silent) to reserve additional space beyond the capsule's own footprint for the *inner* gap too. Confirm the final number against `hyprctl monitors -j`'s `reserved` array before GATE-02's parity pass — this is exactly the artifact the "byte-identical" language in QBAR-12 and the phase's `hyprctl reload`/hot-reload regression check should be diffed against.
**Warning signs:** Windows sitting 6px further from the bar than they do today under the currently-shipped waybar; a GATE-02 aesthetic-parity failure that looks like "extra dead space under the bar."

### Pitfall 2: QBAR-04's brightness clause has no live target on this host
**What goes wrong:** Building (or trying to demo) a brightness-scroll interaction and finding nothing happens, with no obvious root cause.
**Why it happens:** `/sys/class/backlight/` is empty on this machine [VERIFIED: `ls /sys/class/backlight/`, this session — zero entries; desktop board, no laptop panel]. The `light` binary waybar's own `config-floating.jsonc` "backlight" module already shells out to (`on-scroll-up: "light -A 5"`) is **not installed** [VERIFIED: `which light` → not found]. `keybinds.lua:270-275` routes the hardware brightness keys through `swayosd-client --brightness raise/lower`, and its own comment explicitly states DDC/external-monitor brightness is out of scope (D-25) — so even the existing hardware-key path has no functioning backend on a desktop with no backlight device. This means the *existing* waybar backlight module has been silently dead on this specific host all along — it is not a regression introduced by this phase.
**How to avoid:** Treat brightness identically to D-18-06's battery pattern: build the scroll-adjust wiring against `brightnessctl` (installed) so the code is correct and portable to a future laptop deployment, but expect it to be a no-op here, and say so explicitly in the plan rather than leaving it ambiguous. GATE-02 criterion B.3 ("scrolling on the brightness-bearing section adjusts brightness") should be scoped as **not independently verifiable on this host** and not treated as a blocking parity failure, since the capability it compares against was never live in the baseline either.
**Warning signs:** A GATE-02 checkpoint blocked on an unverifiable brightness demo; time spent debugging a "broken" scroll handler that is actually a correctly-wired no-op.

### Pitfall 3: D-18-27's stated "no idle-notify consumer" rationale is factually wrong (decision itself is unaffected)
**What goes wrong:** A future reader (planner, later-phase researcher) takes CONTEXT.md's claim "the only idle-related type in the entire install is `qs::wayland::idle_inhibit::IdleInhibitor`... there is no `ext-idle-notify` consumer" as verified fact and repeats it, or uses it to justify a different decision elsewhere (e.g. in Phase 19-21) without re-checking.
**Why it happens:** `Quickshell.Wayland._IdleNotify` ships an `IdleMonitor` type with `enabled`/`timeout`/`respectInhibitors`/`isIdle` properties [VERIFIED: `/usr/lib/qt6/qml/Quickshell/Wayland/_IdleNotify/quickshell-wayland-idle-notify.qmltypes`, quoted: `name: "qs::wayland::idle_notify::IdleMonitor"` with properties `enabled` (bool), `timeout` (double), `respectInhibitors` (bool), `isIdle` (bool, readonly)] — this is a genuine `ext-idle-notify-v1` protocol consumer, present in the same `Quickshell.Wayland` module tree as `_IdleInhibitor`, and exported by the module's own `qmldir` (`import Quickshell.Wayland._IdleNotify`).
**How to avoid:** Do not repeat the "cannot detect idle" claim as fact in the PLAN.md or any later research. The locked decision (script stays sole owner) is unaffected and still correct for its stated independent reasons (restart survival across QBAR-10, on-disk state, six existing external callers) — only the given rationale is wrong. If the plan documents D-18-27's rationale, correct it to: "hypridle stays the idle source by deliberate choice, not because no in-process alternative exists."
**Warning signs:** None operational — this is a documentation-accuracy risk, not a functional one.

### Pitfall 4: LEDGER-03's frame-rate measurement — do not repeat the Hyprland debug-overlay approach
**What goes wrong:** Enabling Hyprland's FPS debug overlay (`hyprctl eval 'hl.config({ debug = { overlay = true } })'`) while the bar (or any live-capture-heavy Quickshell surface) is active.
**Why it happens:** This exact instrument, on this exact host, already froze the machine hard enough to require a physical restart during Phase 16's OVER-04 measurement [VERIFIED: `.planning/milestones/v3.0-phases/16-workspace-overview/16-OVER04-MEASUREMENT.md:40-52`, quoted: "Enabling it via the correct `hyprctl eval` + `hl.config({ debug = { overlay = true } })` form, on top of the overview with 11 live captures, **froze the machine hard enough to require a physical restart.** Hyprland's IPC stopped responding to every subsequent request... The instrument is therefore not safe to run against this surface... and it was not retried."]. LEDGER-03 explicitly asks for the numbers OVER-04 left unmeasured for exactly this reason.
**How to avoid:** Use `QSG_RENDER_TIMING=1` instead — Qt's own scene-graph render-timing instrumentation, already used in this repo to justify `QSG_RENDER_LOOP=threaded` [VERIFIED: `hypr/.config/hypr/scripts/quickshell-launch.sh` header comment, this session, quoted: "Measured with QSG_RENDER_TIMING=1 on this host (DP-1, 2560x1440@165Hz)... basic (Qt's own default): ~16ms between frames -> ~60fps / threaded (this setting): ~6ms between frames -> ~165fps"]. This gives real per-frame sync/render times with zero compositor-side risk, and this repo has already proven it safe to run.
**Warning signs:** Any plan task that proposes re-enabling `debug.overlay` — should be caught and redirected at plan-check time.

### Pitfall 5: GATE-04's hex-literal lint will false-positive on `Colours.qml` unless scoped to actual `color:`-context usage
**What goes wrong:** A naive "no `#[0-9a-fA-F]{3,8}` string literal anywhere in a `.qml` file" scan immediately fails on `Colours.qml` itself.
**Why it happens:** `Colours.qml` deliberately contains 19 literal hex-string fallback defaults — its own `JsonAdapter` blocks declare `property string primary: "#FF00FF"` and 18 siblings [VERIFIED: `quickshell/.config/quickshell/modules/Colours.qml:98-139`, quoted: `property string primary: "#FF00FF"` (and 18 further identically-shaped lines for `primaryContainer`, `secondary`, ... `onError`)] — these are the intentional debug-magenta "unloaded palette" fallback the file's own header documents (line 40: "every property below defaults to debug magenta... never a production colour"). This is the exact definition-source file the lint's whole purpose is to point *other* files at.
**How to avoid:** Mirror `motion-lint`'s own precedent exactly: `motion-lint`'s CHECK B is a **narrow, context-anchored regex** (`QML_DURATION_RE`/`QML_LITERAL_BEZIER_RE` matching specific property-assignment shapes), not a blanket string scan — and tellingly, `Motion.qml` (the analogous definition-source file for motion tokens) does **not** appear in `motion-lint`'s own `EXEMPTIONS` list [VERIFIED: `hypr/.config/hypr/scripts/motion-lint:409-421`, full `EXEMPTIONS` array read — three entries, none naming `Motion.qml`], implying its own literal defaults don't match the narrow property-context regex used. GATE-04's hex-literal lint should anchor CHECK B on actual `color:`/`border.color:`/`Qt.rgba(`/similarly color-typed property-assignment contexts, not "any hex-shaped string anywhere" — this sidesteps `Colours.qml`'s plain `property string X: "..."` JsonAdapter defaults (which are not `color:`-typed property assignments) without needing a whole-file exemption at all.
**Warning signs:** GATE-04 permanently red the moment it's turned on, or a whole-file exemption for `Colours.qml` that then has to be explained away as "the source of truth is exempt from its own lint," which is a weaker invariant than a correctly-scoped regex.

### Pitfall 6: `quickshell-doctor`'s existing "reserved-space stays unclaimed" check assumes zero exclusive zone — the bar breaks that assumption by design
**What goes wrong:** GATE-03's structural checks are added without noticing that an *existing* `quickshell-doctor` check's invariant is inverted by this phase.
**Why it happens:** The current check (`hypr/.config/hypr/scripts/quickshell-doctor`, around the `_qsd_check` block near line 1518-1551) asserts that summoning every manifest surface leaves `hyprctl monitors -j`'s `reserved` array **byte-identical** — i.e. that no Quickshell surface claims any exclusive zone at all [VERIFIED: `hypr/.config/hypr/scripts/quickshell-doctor`, quoted check description: `"reserved-space stays unclaimed (D-21): summoning every manifest surface leaves monitors -j's reserved array byte-identical (changed: ${ZONE_DIFF_BAD})"`]. QBAR-01 is, by explicit design (the phase's own "new hazard" note), the first surface that *should* claim a non-zero zone, permanently. The existing check's title and assertion ("stays unclaimed") become false the moment the bar exists — not a bug to fix, but an invariant that must be **rewritten**, not merely extended: the new invariant is "the *bar's own* reservation exists and is stable across `hyprctl reload`/hot reload (QBAR-12)," which is different from "no reservation exists at all."
**How to avoid:** GATE-03 should replace (not additively wrap) this check's assertion — bake in an expected non-zero baseline for the bar's own namespace/reservation, then assert stability of that baseline across the two named events (`hyprctl reload`, QML hot reload), matching QBAR-12's literal text.
**Warning signs:** `quickshell-doctor` regressing to a permanent, unfixable FAIL the moment the bar ships, because the D-21 check still asserts the pre-bar invariant.

### Pitfall 7: mounting `AudioBackend`/`WifiBackend`/`BluetoothBackend` permanently defeats their existing zero-idle gating
**What goes wrong:** QBAR-11's soak assertion ("no idle timers doing nothing") silently fails because a backend's polling/tracking mechanism, previously gated to "only while some panel is open," is now gated to "the bar is mounted" — which is always true.
**Why it happens:** `AudioBackend`'s `PwObjectTracker` is currently gated by `panelOpen`, itself derived from `audioTruthNeeded: dashboardLoader.active || audioPanelLoader.active` [VERIFIED: `quickshell/.config/quickshell/shell.qml:162-167`, quoted: `readonly property bool audioTruthNeeded: dashboardLoader.active || audioPanelLoader.active` then `AudioBackend { id: audioBackendInstance; panelOpen: root.audioTruthNeeded }`] — both existing gate sources are LazyLoader `.active` flags that go false on dismiss. If the bar's own audio readout widens this gate to include "the bar is mounted" (which never becomes false), `AudioBackend`'s PipeWire object tracking runs permanently, for the entire session, not merely "while some UI is open." The same shape applies to `WifiBackend`/`BluetoothBackend` if the bar reads their live state directly, though those two already expose enable-state as "plain, ungated bindings" per `shell.qml`'s own comment (line 154-159), so they may already be closer to always-on than `AudioBackend`.
**How to avoid:** This is not necessarily wrong — the phase's own notes call this the expected, named hazard — but it must be a **deliberate, recorded** cost (which backend, what the permanent resource cost is) rather than an incidental side-effect of wiring the bar's readouts the easy way. QBAR-11's soak measurement should explicitly account for whichever backends the bar's readouts widen to permanent-on.
**Warning signs:** A soak-test RSS/process-count creep that traces back to `PwObjectTracker` node count, not to the bar's own QML objects.

### Pitfall 8: QBAR-10's restart wrapper has two structurally different options in this repo, with a real precedent gap
**What goes wrong:** Choosing a mechanism without accounting for this repo's own established convention.
**Why it happens:** Every autostart entry in this repo — waybar, quickshell itself today, swaync, the AGS applet, elephant, walker — launches via `uwsm app -- <script>` [VERIFIED: `hypr/.config/hypr/config/autostart.lua`, lines 42/48/55/60/65, all matching the pattern `hl.exec_cmd("uwsm app -- ...")`], producing a transient systemd scope with no `Restart=` directive. A proper systemd `--user` unit **does** exist for waybar upstream, shipped by the package itself, with `Restart=on-failure` already configured [VERIFIED: `systemctl --user cat waybar.service`, this session, quoted: `Restart=on-failure` under `[Service]`] — but this repo has never used it; `waybar.service` sits `disabled` in `systemctl --user list-unit-files` while the bar has actually been running via the `uwsm app --` scope this whole time. There is currently **zero precedent** in this repo for a custom systemd `--user` unit — every restart-needing daemon has instead relied on either (a) not crashing, or (b) hypridle-style pause/resume via SIGSTOP/SIGCONT (gaming-mode-toggle.sh), neither of which is auto-restart-on-death.
**How to avoid:** Two real options, each with a real cost:
  1. **Shell respawn loop inside `quickshell-launch.sh`** (`while true; do quickshell -p "$CONFIG_DIR"; rc=$?; ...backoff...; done`) — zero change to the `uwsm app --` launch convention, but needs a hand-rolled backoff (see Pitfall 9) and the loop itself becomes a second long-lived process wrapping the real one, which QBAR-11's process-count soak must then also account for.
  2. **A new systemd `--user` unit** (`quickshell.service`, `Restart=on-failure`, `RestartSec=`), launched via `systemctl --user start`/`enable` instead of `uwsm app --` — gets OS-level backoff/rate-limiting (`StartLimitIntervalSec`/`StartLimitBurst`) for free, and there's already a shipped, if unused, precedent shape in `waybar.service` to copy from, but it is a genuine, first-of-its-kind deviation from this repo's `uwsm app --`-everywhere convention for autostart and needs an explicit decision, not a silent pick.
  Given the repo has zero existing shell-respawn-loop precedent either, this is a genuinely open architecture call — flagged for the plan to make explicitly, not infer silently.
**Warning signs:** A restart mechanism that respawns in a tight loop with no backoff (crash-loop CPU burn) — this is also a Security Domain concern, see below.

### Pitfall 9: A naive restart loop with no backoff is a local denial-of-service vector
**What goes wrong:** If the bar crashes repeatedly (e.g. a bad QML hot-reload edit, or a backend throwing on every start), an unthrottled respawn loop consumes CPU and (via repeated PipeWire/D-Bus connection attempts) can affect unrelated services, effectively self-inflicted DoS.
**Why it happens:** Neither of QBAR-10's two candidate mechanisms defends against this by default: a bare `while true; do quickshell ...; done` respawns instantly on every exit; a systemd unit with `Restart=on-failure` alone (no `RestartSec`/`StartLimitBurst`) also retries immediately, though systemd's default `StartLimitIntervalSec`/`StartLimitBurst` (5 starts / 10s) will eventually mark the unit failed and stop retrying, whereas a hand-rolled bash loop has no such backstop unless one is explicitly written in.
**How to avoid:** If a shell loop is chosen, add an explicit `sleep` with backoff (e.g. exponential, capped) between respawns, and a maximum-restarts-per-window guard. If a systemd unit is chosen, set `RestartSec` explicitly (do not rely on the systemd default alone) and consider `StartLimitIntervalSec`/`StartLimitBurst` so a genuinely broken build fails loudly (surfacing in `systemctl --user status`) rather than looping forever.
**Warning signs:** `top`/`htop` showing repeated short-lived `quickshell` processes; a flat CPU floor that never drops during what should be an idle session.

## Code Examples

### PanelWindow + WlrLayershell skeleton for an always-on, non-zero-exclusiveZone surface
```qml
// Source: property names verified against
// /usr/lib/qt6/qml/Quickshell/_Window/quickshell-window.qmltypes:131-201 and
// /usr/lib/qt6/qml/Quickshell/Wayland/_WlrLayerShell/quickshell-wayland-layershell.qmltypes
// (installed quickshell 0.3.0-2, this session). Pattern shape copied from
// quickshell/.config/quickshell/modules/Overview.qml:26-56 (this repo, Read tool).
import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: barWindow
    anchors { top: true; left: true; right: true }
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell-bar"
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusiveZone: 46          // barHeight(40) + barEdgeMargin(6) — verify against live `hyprctl monitors -j`
    exclusionMode: ExclusionMode.Normal
    aboveWindows: false
    focusable: false
    color: "transparent"
}
```

### Battery entry that renders nothing when absent (D-18-06)
```qml
// Source: property names verified against
// /usr/lib/qt6/qml/Quickshell/Services/UPower/quickshell-service-upower.qmltypes
// (installed quickshell 0.3.0-2, this session)
import Quickshell.Services.UPower

Item {
    visible: UPower.displayDevice && UPower.displayDevice.isPresent
    width: visible ? implicitWidth : 0   // capsule shrinks to zero, no placeholder — matches D-18-06 literal text
    // UPower.displayDevice.percentage, .state, .isLaptopBattery available when isPresent
}
```

### MediaBackend repoint target (D-18-05)
```qml
// Source: Mpris property names verified against
// /usr/lib/qt6/qml/Quickshell/Services/Mpris/quickshell-service-mpris.qmltypes
// (installed quickshell 0.3.0-2, this session)
import Quickshell.Services.Mpris

// Mpris.players is an UntypedObjectModel of MprisPlayer.
// Each MprisPlayer exposes: identity, position, length, volume, trackTitle,
// trackArtist, trackArtists, trackAlbum, trackAlbumArtist, trackArtUrl,
// playbackState (MprisPlaybackState.Enum: Stopped/Playing/Paused),
// loopState, shuffle, plus *Supported flags and play()/pause()/stop()/
// togglePlaying() methods and position-seeking support.
// This replaces MediaBackend.qml's media-status.sh watch (POLL_INTERVAL=1,
// ~10 subprocess forks/sec) entirely — zero subprocess cost.
```

### Retirement-check fold pattern for `theme-doctor` (RETIRE-01/D-18-35)
```bash
# Source: verified against theme-engine/.config/theme-engine/theme-doctor
# (this repo, Read/grep this session) — waybar-design-lint fold, ~line 660,
# and motion-lint fold, ~line 681. RETIRE-01's retirement-check should be
# folded in identically.
RETIREMENT_CHECK="$HOME/.config/hypr/scripts/retirement-check"
if [[ -x "$RETIREMENT_CHECK" ]]; then
    while IFS= read -r _rc_line; do
        case "$_rc_line" in
            *"[PASS]"*) check "retirement-check: ${_rc_line#*\[PASS\] }" "0" ;;
            *"[FAIL]"*) check "retirement-check: ${_rc_line#*\[FAIL\] }" "1" ;;
            *)          echo "  $_rc_line" ;;   # [REPORT]-tier lines pass through unfolded, per D-18-37
        esac
    done < <("$RETIREMENT_CHECK" --all 2>/dev/null)
else
    echo "  [SKIP] retirement-check ($RETIREMENT_CHECK not found or not executable)"
fi
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| waybar (GTK3, JSONC config, compiled-in dispatch — workspace click dead under 0.15.0) | Quickshell/QML `PanelWindow` with native service modules | This phase (Phase 18) | Restores workspace-click (QBAR-03), removes the ~10-forks/sec MPRIS poll loop, adds true per-orientation config-driven layout |
| `media-status.sh watch` (1 Hz poll, `playerctl`/`jq`/`media-players.sh` subprocess forking) | `Quickshell.Services.Mpris` native singleton | This phase (D-18-05) | MPRIS reader count 3 → 1 (QMEDIA-03 partially satisfied early); zero subprocess cost per tick |
| `waybar-visibility.sh` signaling waybar via SIGUSR1/SIGUSR2 | Same script (renamed `bar-visibility.sh`), actuating via `qs ipc call` | This phase (D-18-27) | State-machine logic (flock'd RMW, per-source intent files, override model) is untouched — only the actuation mechanism at the very end changes |
| `IDLE_DIM_OPACITY="0.05"` CSS opacity dim on idle (a lit sliver) | Fully invisible `hidden-idle` state, zone still reserved (no reflow) | This phase (D-18-23, QBAR-07) | Kills the OLED-static-pixel concern that motivated QBAR-07 in the first place |

**Deprecated/outdated:**
- `waybar-fullscreen-watch.sh` (standalone socket2 listener process) — replaced by `shell.qml`'s already-proven `Hyprland.activeToplevel`/`onRawEvent` pattern; deletes one long-running process (D-18-28).
- `waybar-equivalence-check`/`waybar-design-lint` — the mechanical coverage they provided is replaced by `quickshell-doctor` structural checks (GATE-03) and the QML hex-literal lint (GATE-04), minted in this same phase so no future surface is ever born outside them.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|----------------|
| A1 | `QsMenuEntry`'s exact click-trigger invokable method name was not found in the scanned `.qmltypes` (only a `triggered` signal and a `display()` method for submenus were confirmed) — the plan should verify the exact trigger call against Quickshell's own upstream example configs during implementation | Code Examples "Tray + menu", Open Questions | A tray menu that renders correctly but whose items don't actually activate on click; caught immediately at manual QA, low blast radius |
| A2 | QBAR-08's "reveal on holding Super" has no verified native Quickshell mechanism for "modifier key held" (as opposed to a discrete `GlobalShortcut` press) in the scanned API surface | Open Questions | May require a Hyprland-side signal (a bind on Super's press+release pair dispatching `qs ipc call`) rather than a pure-QML solution; if unaccounted for, QBAR-08's Super-hold reveal could be silently unimplementable as a pure-QML feature |
| A3 | The exact backoff/rate-limit numbers for QBAR-10's restart wrapper (whichever mechanism is chosen) are not specified anywhere in CONTEXT.md/UI-SPEC.md — recommended values in Pitfall 9 are engineering judgment, not a locked decision | Common Pitfalls 8/9 | A too-aggressive respawn could crash-loop; a too-conservative one could leave the bar down longer than necessary after a real crash |
| A4 | Whether `swayosd-client`'s brightness path (used for the hardware keys) has any functioning target on THIS host was inferred from the absence of `/sys/class/backlight/` entries and `light`/`ddcutil` binaries — swayosd itself was not traced further (e.g. whether it silently no-ops or logs an error) | Common Pitfalls 2 | Low risk — either way, no live brightness signal exists for the bar to read or drive; the conclusion (treat as D-18-06-style dead-but-present) holds regardless |

**If this table is empty:** N/A — see rows above.

## Open Questions

1. **Exact QsMenuEntry click-activation call.**
   - What we know: `QsMenuEntry` (verified in `quickshell-core.qmltypes:1754-1843`) exposes `text`/`icon`/`enabled`/`isSeparator`/`buttonType`/`checkState`/`hasChildren`, a `triggered` signal, and a `display(parentWindow, relativeX, relativeY)` method (which appears to be for opening a *submenu*, not for activating a leaf item).
   - What's unclear: whether a leaf `QsMenuEntry` is activated by simply emitting/connecting to its own `triggered` signal from QML (i.e. it's fired by the backend once some other trigger call is made) or whether there's an invokable `trigger()`/`activate()` method not captured in this scan pass.
   - Recommendation: during implementation, cross-check against Quickshell's own upstream example shells (not this repo) or the Quickshell source tree directly (`qsmenu.hpp`, referenced at `quickshell-core.qmltypes:1836`) before wiring the tray menu's click handler — this is a 10-minute verification, not a research blocker.

2. **QBAR-08's "reveal on holding Super" mechanism.**
   - What we know: `GlobalShortcut` (already used throughout `shell.qml`) fires on a discrete press, not a held-state. No "modifier held" signal was found in the scanned `Quickshell.Hyprland`/`Quickshell.Wayland`/core API surface during this pass.
   - What's unclear: whether Quickshell exposes any live modifier-state property (e.g. via `Quickshell.Hyprland` or a lower-level Wayland seat API) that a QML `Behavior`/binding could watch continuously, or whether this needs a Hyprland-side `bindm`/submap mechanism dispatching `qs ipc call` on Super press and a paired release bind.
   - Recommendation: the plan should budget a short spike task to confirm whether a "Super held" signal exists nativel, or design the fallback (Hyprland submap/bindm pair driving IPC) explicitly rather than assuming QML alone can observe a held modifier.

3. **`waybar.service`'s disposition.**
   - What we know: it's a packaged, unused, `disabled` unit that will be removed automatically when the `waybar` package is uninstalled (RETIRE-02).
   - What's unclear: whether any residual `/usr/lib/systemd/user/waybar.service` symlink or drop-in exists elsewhere that pacman's removal wouldn't clean up (unlikely, but not independently re-verified beyond the single `systemctl --user cat`/`list-unit-files` pass in this session).
   - Recommendation: RETIRE-01's checklist run (before and after) should include a `systemctl --user list-unit-files | grep -i waybar` line as one of its blocking checks — cheap, mechanical, closes this question definitively at execution time.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| quickshell | Entire phase (bar surface) | ✓ | 0.3.0-2 | — |
| `Quickshell.Services.SystemTray` | QBAR-05 | ✓ (ships with quickshell) | 0.3.0-2 | — |
| `Quickshell.DBusMenu` / `QsMenuOpener` | QBAR-05 tray menus | ✓ (ships with quickshell) | 0.3.0-2 | — |
| `Quickshell.Services.Mpris` | D-18-05, QBAR-06 media | ✓ (ships with quickshell) | 0.3.0-2 | — |
| `Quickshell.Services.UPower` | D-18-06, QBAR-06 battery | ✓ (ships with quickshell) | 0.3.0-2 | — |
| `brightnessctl` | QBAR-04 brightness scroll (code path only) | ✓ | installed | No fallback needed — no functioning brightness hardware on this host regardless (see Pitfall 2) |
| `light` (waybar's existing backlight scroll target) | Nothing in this phase; historical baseline reference only | ✗ | — | N/A — not used by the QML bar |
| `/sys/class/backlight/*` | QBAR-04 brightness live value | ✗ (empty on this host) | — | Brightness entry renders nothing / is a documented no-op, mirroring D-18-06's battery pattern |
| `/sys/class/power_supply/*` | QBAR-06/D-18-06 battery | ✗ (empty on this host) | — | Battery entry renders nothing (D-18-06, already the locked design) |
| systemd `--user` | QBAR-10 restart wrapper (if that mechanism is chosen) | ✓ | present, already used for pipewire/portal units | Shell respawn loop is the alternative if a systemd-unit deviation from `uwsm app --` convention is rejected |
| `qs` CLI (`qs ipc call`) | D-18-27 actuation | ✓ | ships with quickshell 0.3.0-2 | — |

**Missing dependencies with no fallback:**
- None that block the phase — the two "✗" hardware-absence rows (backlight, power_supply) are pre-existing host conditions the design already accounts for (D-18-06's pattern generalizes to both).

**Missing dependencies with fallback:**
- Brightness hardware absence — code path built for portability, inert on this host by design, not a blocker.

## Security Domain

> `security_enforcement: true`, `security_asvs_level: 1` in `.planning/config.json` — included per protocol.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-------------------|
| V2 Authentication | No | No login/auth surface introduced by this phase |
| V3 Session Management | No | No session concept — the bar is a persistent desktop chrome element |
| V4 Access Control | No | Single-user desktop; no privilege boundary crossed by the bar itself |
| V5 Input Validation | Yes | (1) `retirement-check`'s `<surface-name>` argument must be validated against a strict allowlist before any path construction, mirroring `bar-visibility.sh`'s own established `<source>` validation (T-08-05 precedent, already read in full — `waybar-visibility.sh`'s `main()` case statement rejects unknown verbs before any path is built from them). (2) Tray/DBusMenu text (`StatusNotifierItem.title`/`tooltipTitle`, `QsMenuEntry.text`) originates from untrusted third-party applications over D-Bus — must be rendered as plain `Text` (QML's `Text` element does not interpret its `text` property as markup unless `textFormat: Text.RichText`/`Text.MarkdownText` is explicitly set), never concatenated into a shell command or a `Process.command` array element |
| V6 Cryptography | No | No cryptographic operation in this phase |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|----------------------|
| Malicious/buggy tray application supplies an oversized or control-character-laden `title`/`tooltipTitle`/menu-item `text` | Tampering / Denial of Service (layout) | Bound the rendered width (matching `mediaTitleMaxChars`'s precedent already in UI-SPEC) and use `Text.ElideRight`; never interpret tray-supplied strings as QML `RichText`/`MarkdownText` |
| Unbounded restart-respawn loop (QBAR-10) triggered by a crashing bar process | Denial of Service (local CPU/D-Bus connection storm) | Explicit backoff + max-attempts guard (shell loop) or `RestartSec`/`StartLimitBurst` (systemd unit) — see Common Pitfall 9 |
| `retirement-check`/`quickshell-doctor` new checks shelling out with attacker-influenced input (e.g. a crafted namespace string reaching a `hyprctl`/`jq` pipeline) | Tampering (command injection) | Follow the established `_qsd_valid_token()` allowlist pattern already in `quickshell-doctor` (`^[A-Za-z0-9_-]+$`) for any new manifest-derived token reaching a dispatch argv, exactly as GATE-03's new checks must |
| `qs ipc call` actuation path (`bar-visibility.sh` → bar) | Tampering (unauthorized local IPC caller) | Quickshell's IPC socket is user-scoped (same trust boundary as the existing `panelIpc`/`overviewIpc` handlers already in production) — no new trust boundary is crossed; do not widen the target's IPC verb surface beyond what `bar-visibility.sh` itself needs to call |

## Sources

### Primary (HIGH confidence — direct verification this session)
- Installed `quickshell 0.3.0-2` `.qmltypes` files under `/usr/lib/qt6/qml/Quickshell/` — `Wayland/_WlrLayerShell`, `Wayland/_IdleNotify`, `_Window`, `quickshell-core.qmltypes`, `Services/SystemTray`, `DBusMenu`, `Services/Mpris`, `Services/UPower` — read directly via Bash/Read this session, not from documentation or training memory
- This repo's own QML surfaces: `shell.qml`, `modules/Overview.qml`, `modules/dashboard/PanelDialog.qml`, `modules/Dashboard.qml`, `modules/dashboard/Design.qml`, `modules/Colours.qml`, `modules/dashboard/AudioBackend.qml` — read via the Read tool this session
- This repo's own bash tooling: `hypr/.config/hypr/scripts/waybar-visibility.sh`, `quickshell-launch.sh`, `quickshell-doctor`, `motion-lint`, `waybar-fullscreen-watch.sh`, `gaming-mode-toggle.sh`, `waybar-switch.sh`; `theme-engine/.config/theme-engine/theme-doctor`, `contract.json`; `hypr/.config/hypr/hypridle.conf`, `config/keybinds.lua`, `config/windowrules.lua`, `config/autostart.lua`; `install.sh`, `stow.sh` — read directly this session
- Live host state: `hyprctl monitors -j` (`reserved: [0, 46, 0, 0]`), `systemctl --user list-unit-files`/`cat waybar.service`, `pacman -Q quickshell`, `ls /sys/class/backlight`/`/sys/class/power_supply`, `which light`/`brightnessctl`/`ddcutil` — all run this session
- `.planning/milestones/v3.0-phases/16-workspace-overview/16-OVER04-MEASUREMENT.md` — the FPS-overlay-froze-the-host finding, read in full this session

### Secondary (MEDIUM confidence)
- None — every claim in this document was traced to a primary source above.

### Tertiary (LOW confidence)
- None used. Where a claim could not be verified directly this session (QsMenuEntry's exact trigger call; whether Quickshell exposes a "modifier held" signal), it is recorded in Open Questions rather than asserted, per this repo's standing research discipline.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — every Quickshell module/property cited was read directly from the installed `.qmltypes` files this session, not assumed from documentation or training data
- Architecture: HIGH — every pattern cited was read from this repo's own existing, shipped QML surfaces (`Overview.qml`, `PanelDialog.qml`, `shell.qml`), not from a reference shell or external example
- Pitfalls: HIGH — all nine pitfalls trace to either a live command run this session (`hyprctl monitors -j`, `ls /sys/class/backlight`, `which light`) or a verbatim-quoted line from a file read this session
- Restart mechanism (QBAR-10) and Super-hold reveal (QBAR-08): MEDIUM — the tradeoffs are grounded in verified facts (existing `uwsm app --` convention, `waybar.service`'s unused `Restart=on-failure`), but the final mechanism choice is not locked by CONTEXT.md and is flagged as an open architecture decision for the plan, not asserted as fact

**Research date:** 2026-08-10
**Valid until:** 30 days (stable local API surface — quickshell version is pinned in this repo and does not move without an explicit upgrade decision elsewhere in the project)
