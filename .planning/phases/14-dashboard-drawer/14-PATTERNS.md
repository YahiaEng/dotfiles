# Phase 14: Dashboard Drawer - Pattern Map

**Mapped:** 2026-07-29
**Files analyzed:** 14 (new/modified)
**Analogs found:** 12 / 14

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `quickshell/.config/quickshell/modules/Dashboard.qml` | component (layer-shell surface host) | event-driven | `quickshell/.config/quickshell/modules/Probe.qml` | exact |
| `quickshell/.config/quickshell/modules/dashboard/DashboardTab.qml` | component | request-response | `modules/Probe.qml` (panelColumn content section) | role-match |
| `quickshell/.config/quickshell/modules/dashboard/MediaTab.qml` | component | streaming (stdout line stream) | none in QML (script side: `hypr/.config/hypr/scripts/media-status.sh`) | partial |
| `quickshell/.config/quickshell/modules/dashboard/PerformanceTab.qml` | component | streaming/poll | none in QML; `modules/Probe.qml`'s `FileView` polling pattern | partial |
| `quickshell/.config/quickshell/modules/dashboard/WeatherTab.qml` | component | request-response (HTTP) + file-I/O (cache) | none in QML; `Colours.qml`/`Motion.qml` FileView/JsonAdapter pattern for the cache half | partial |
| `quickshell/.config/quickshell/modules/dashboard/MediaBackend.qml` | service (shared Process singleton/component) | streaming | `modules/Probe.qml`'s `FileView` reactive read pattern (closest reactive-data-source shape in repo, though Probe reads files not process stdout) | partial |
| `quickshell/.config/quickshell/modules/dashboard/WeatherBackend.qml` | service | file-I/O + request-response | `Colours.qml` (FileView/JsonAdapter read-only singleton pattern) | role-match |
| `quickshell/.config/quickshell/modules/dashboard/QuickToggles.qml` | component | event-driven (exec + file-watch) | `swaync/.config/swaync/config.json` `buttons-grid.actions` (command/update-command pairs) — cross-language analog | role-match |
| `quickshell/.config/quickshell/modules/qmldir` (edit) | config (module manifest) | n/a | itself, existing | exact |
| `quickshell/.config/quickshell/shell.qml` (edit) | provider (shell root, mounts LazyLoader+GlobalShortcut) | event-driven | itself, existing (Probe/ScreencopyProbe blocks) | exact |
| `quickshell/.config/quickshell/shortcuts.json` (edit) | config (declared-manifest) | n/a | itself, existing entries | exact |
| `hypr/.config/hypr/config/keybinds.lua` (edit) | config | n/a | existing probe bind lines ~160-177 | exact |
| `hypr/.config/hypr/config/windowrules.lua` (edit) | config | n/a | existing wleave/walker/swaync layer-rule blocks ~216-345 | exact |
| `theme-engine/.config/theme-engine/motion.json` (edit) | config | n/a | itself — `semantic` object, existing four entries | exact |
| `stow.sh` (edit — weather state seed) | config/utility (seed-only-if-absent) | file-I/O | itself — motion-scale / waybar-visibility seed blocks ~215-237 | exact |
| `theme-engine/.config/theme-engine/contract.json` (edit — `engine_owned_files`) | config | n/a | itself — existing array | exact |
| `install.sh` (edit — Material Symbols AUR pkg) | config | n/a | itself — `AUR_PKGS` array + `verify_packages` hard-fail loop | exact |

## Pattern Assignments

### `quickshell/.config/quickshell/modules/Dashboard.qml` (component, event-driven)

**Analog:** `quickshell/.config/quickshell/modules/Probe.qml` (whole file, 658 lines — this repo's ONLY prior full layer-shell surface)

**Imports pattern** (Probe.qml lines 30-36):
```qml
import QtQml
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Io
```
Dashboard.qml additionally needs `import QtQuick.Controls.Material` (for `SwipeView`/`TabBar`, per RESEARCH.md Pattern 3) and `import Quickshell.Services.UPower` (battery).

**Surface/layer-shell scaffold pattern** (Probe.qml lines 61-98):
```qml
PanelWindow {
    id: probeWindow
    implicitWidth: panelColumn.implicitWidth + spacingLg * 2
    implicitHeight: panelColumn.implicitHeight + spacingLg * 2
    screen: modelData   // NOTE: Dashboard is single-instance (no per-screen Variants fan-out per D-42/D-14 — simpler than Probe's QS-03 multi-screen fan-out; do not copy the `Variants`/`modelData` wrapper unless multi-monitor summon is required)

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-probe"   // becomes "quickshell-dashboard" per D-42
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusiveZone: 0
}
```

**Click-outside + focus-loss dismiss pattern** (Probe.qml lines 100-106) — this is D-12/D-13's answer, reuse verbatim:
```qml
HyprlandFocusGrab {
    id: grab
    windows: [ probeWindow ]
    active: true
    onCleared: probeVariants.dismissRequested()   // -> dashboardRoot.dismissRequested() for Dashboard.qml
}
```

**FileView reactive-state-read pattern** (Probe.qml lines 112-125, and Colours.qml/Motion.qml wholesale) — the standard shape for every state-file consumer in this repo (theme mode, gaming-mode cache, motion.json, and by extension the drawer's weather cache / QuickToggles watch targets):
```qml
FileView {
    id: modeFile
    path: Quickshell.env("HOME") + "/.local/state/theme/mode"
    watchChanges: true
    onFileChanged: reload()
}
readonly property string currentModeName: (modeFile.text() || "").trim() || "unknown"
```

**Token consumption pattern (color + motion, with Behavior-driven transitions)** (Probe.qml lines 229-240):
```qml
Rectangle {
    anchors.fill: parent
    color: Colours.surface
    Behavior on color {
        enabled: Motion.motionEnabled
        ColorAnimation {
            duration: Motion.standardDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Motion.standardEasing
        }
    }
}
```

**Empty/error-state row pattern** (Probe.qml lines 335-342) — the direct ancestor of D-41's "populated/pending/empty" vocabulary; every dashboard widget's empty state should follow this shape (explicit visible row, never a silent gap):
```qml
Label {
    visible: !probeWindow.hasMotionTokensLocal
    text: "no motion tokens loaded — check motion.json"
    font.pixelSize: 14
    color: Colours.onSurface
}
```

**JSON state read+write pattern (only if a widget needs to write, e.g. tab-memory persistence if made disk-backed)** (Probe.qml lines 192-227) — imperative re-assignment, NOT declarative `Binding`, is required to keep a JsonAdapter property in lock-step with a live singleton value (documented pitfall, binary-verified in this repo).

---

### `quickshell/.config/quickshell/modules/dashboard/MediaBackend.qml` (service, streaming)

**Analog:** No direct QML analog exists (first `Process`-stdout consumer in this repo's QML layer) — RESEARCH.md's own Code Examples section is authoritative here; combine with Probe.qml's FileView reactive-property idiom for exposing the result.

**Core pattern** (from RESEARCH.md, confirmed against `media-status.sh`'s actual payload contract read at `/home/aorus/dotfiles/hypr/.config/hypr/scripts/media-status.sh` lines 1-40):
```qml
Process {
    id: mediaWatcher
    running: true
    command: [Quickshell.env("HOME") + "/.config/hypr/scripts/media-status.sh", "watch"]
    stdout: SplitParser {
        onRead: (line) => {
            try {
                const payload = JSON.parse(line);
                mediaBackend.current = payload;
            } catch (e) { /* keep last-good payload */ }
        }
    }
}
```
Payload contract fields (verified from script header): `player, label, status, title, artist, album, art, position, length, volume, can_seek`.

**Mutation pattern — the ONLY sanctioned writer** (`media-players.sh`, referenced but not to be reimplemented):
```qml
Process {
    command: [Quickshell.env("HOME") + "/.config/hypr/scripts/media-players.sh",
              "cmd", mediaBackend.current.player, "play-pause"]
    running: true
}
```
**Hard fence (D-35/DASH-04):** never `import Quickshell.Services.Mpris` anywhere in the drawer, even though the module is installed and importable — this is the repo's number-one anti-pattern for this phase.

---

### `quickshell/.config/quickshell/modules/dashboard/QuickToggles.qml` (component, event-driven)

**Analog:** `swaync/.config/swaync/config.json` `buttons-grid.actions` (lines ~55-80) — the cross-language source of truth for command/update-command pairs the drawer's chips must exec/watch instead of duplicating:
```json
{
  "label": "󰊴",
  "type": "toggle",
  "command": "~/.config/hypr/scripts/gaming-mode-toggle.sh",
  "update-command": "v=$(cat ~/.cache/gaming-mode 2>/dev/null || echo off); case $v in on) echo true ;; *) echo false ;; esac"
},
{
  "label": "󰂛",
  "type": "toggle",
  "command": "case $SWAYNC_TOGGLE_STATE in true) swaync-client -dn ;; *) swaync-client -df ;; esac",
  "update-command": "swaync-client -D"
},
{
  "label": "󰔎",
  "type": "toggle",
  "command": "~/.config/hypr/scripts/theme-switch.sh",
  "update-command": "v=$(cat ~/.local/state/theme/mode 2>/dev/null || echo dark); case $v in light) echo true ;; *) echo false ;; esac"
}
```
The dashboard chips must exec the exact same three commands (`gaming-mode-toggle.sh`, `swaync-client -dn/-df`, `theme-switch.sh`) and watch the exact same three state sources (`~/.cache/gaming-mode`, `swaync-client -D`, `~/.local/state/theme/mode`) — per D-26, editing this file's DND-adjacent theme toggle direction is itself an in-scope one-line diff (flip `light) echo true` semantics to match D-26's dark-lit convention).

**Motion-scale row exec target:** `hypr/.config/hypr/scripts/motion-switch.sh <preset>` (no swaync counterpart, D-23) — same `Process`-exec pattern as the three chips above, no watch/read needed since the QML-side segmented control's own click state is authoritative alongside `Motion.motionScale`.

**QML exec pattern to use (component-level), reuse from MediaBackend's mutation shape:**
```qml
Process {
    command: [Quickshell.env("HOME") + "/.config/hypr/scripts/gaming-mode-toggle.sh"]
    running: true
}
```

---

### `quickshell/.config/quickshell/modules/dashboard/WeatherBackend.qml` (service, file-I/O + request-response)

**Analog:** `Colours.qml`/`Motion.qml` — FileView/JsonAdapter singleton-of-state pattern, extended with an `XMLHttpRequest` fetch (RESEARCH.md Code Examples, confirmed live this session against `api.open-meteo.com`).

**Read-only fallback-default discipline pattern** (Colours.qml lines 66-111, applies directly to the weather cache/state file):
```qml
FileView {
    id: baseFile
    path: Quickshell.env("HOME") + "/.local/state/theme/palette.json"  // -> weather cache path
    watchChanges: true
    printErrors: true
    onFileChanged: { root.loadHealthy = true; reload(); }
    onLoadFailed: (error) => { root.loadHealthy = false; }

    JsonAdapter {
        property string primary: "#FF00FF"   // -> every weather field needs an explicit, loud default
    }
}
```

**Nested-JSON pitfall pattern** (Motion.qml lines 66-79) — D-31's multi-key weather state file (location + units) must follow this `property var` + manual-destructure shape since `JsonAdapter` only maps TOP-LEVEL keys:
```qml
property var semantic: ({})   // -> e.g. property var location: ({}) for {lat, lon}
```

**Fetch pattern** (RESEARCH.md, confirmed live):
```qml
function fetchWeather(lat, lon, unitsTemp, unitsWind) {
    const url = `https://api.open-meteo.com/v1/forecast?latitude=${lat}&longitude=${lon}` + /* ... */;
    const xhr = new XMLHttpRequest();
    xhr.onreadystatechange = function () {
        if (xhr.readyState !== XMLHttpRequest.DONE) return;
        if (xhr.status !== 200) { weatherBackend.markStale(); return; }
        try { weatherBackend.applyFresh(JSON.parse(xhr.responseText)); }
        catch (e) { weatherBackend.markStale(); }
    };
    xhr.open("GET", url);
    xhr.send();
}
```

---

### `quickshell/.config/quickshell/modules/qmldir` (edit)

**Analog:** itself, lines 20-24 — the standing instruction is explicit and must be followed exactly:
```
module qs.modules
singleton Colours 1.0 Colours.qml
singleton Motion 1.0 Motion.qml
Probe 1.0 Probe.qml
ScreencopyProbe 1.0 ScreencopyProbe.qml
```
Add `Dashboard 1.0 Dashboard.qml` in the SAME commit that creates `Dashboard.qml`. If `modules/dashboard/` subcomponents are exposed as their own QML module (planner discretion per RESEARCH.md's project-structure note), that subdirectory needs its OWN `qmldir` following this identical shape — every unlisted type in a directory with a checked-in `qmldir` is unresolvable (FM1 lesson, documented at the top of this file).

---

### `quickshell/.config/quickshell/shell.qml` (edit)

**Analog:** itself, lines 46-67 (`screencopyProbeLoader` + its `GlobalShortcut` block) — this is the exact, minimal, three-part pattern to replicate for the dashboard: `LazyLoader` (active:false) → sibling `GlobalShortcut` → `onPressed` toggles `.active`:
```qml
LazyLoader {
    id: screencopyProbeLoader
    active: false
    ScreencopyProbe {
        onDismissRequested: screencopyProbeLoader.active = false
    }
}
GlobalShortcut {
    id: screencopyProbeShortcut
    appid: "quickshell"
    name: "screencopy-probe"
    onPressed: screencopyProbeLoader.active = !screencopyProbeLoader.active
}
```
For the dashboard: `id: dashboardLoader`, `Dashboard { onDismissRequested: dashboardLoader.active = false }`, `GlobalShortcut { appid: "quickshell", name: "dashboard", onPressed: dashboardLoader.active = !dashboardLoader.active }`. Per D-14, this single-instance LazyLoader (not a per-screen `Variants` fan-out like `Probe`) is correct — the drawer is not multi-screen-summoned.

---

### `quickshell/.config/quickshell/shortcuts.json` (edit)

**Analog:** itself, existing two entries (lines 1-14) — append a third entry in the identical shape:
```json
{
  "appid": "quickshell",
  "name": "dashboard",
  "chord": { "mods": "SUPER", "key": "D" },
  "description": "Summon the dashboard drawer (DASH-01)"
}
```

---

### `hypr/.config/hypr/config/keybinds.lua` (edit)

**Analog:** itself, line 171 (probe bind) — same section, same `hl.dsp.global("quickshell:<name>")` convention, same `mainMod .. " + <mods> + <key>"` join idiom:
```lua
hl.bind(mainMod .. " + SHIFT + G", hl.dsp.global("quickshell:probe")) -- Summon Quickshell probe (QS-02 gate)
```
New line for D-09: `hl.bind(mainMod .. " + D", hl.dsp.global("quickshell:dashboard")) -- Summon dashboard drawer (DASH-01)`. The `"quickshell:<name>"` identifier MUST byte-match `shortcuts.json`'s `"name"` field.

---

### `hypr/.config/hypr/config/windowrules.lua` (edit)

**Analog:** itself, lines 221-224 (blur block), 301-304 (ignore_alpha block), 293 (wleave animation precedent) — three near-identical per-namespace rule additions follow this shape exactly:
```lua
hl.layer_rule({ match = { namespace = "swaync-control-center" }, blur = true })
-- ...
hl.layer_rule({ match = { namespace = "swaync-control-center" }, ignore_alpha = 0.5 })
-- ...
hl.layer_rule({ match = { namespace = "wleave" }, animation = "fade" })
```
For D-42 (primary) plus the D-42 fallback documented in RESEARCH.md:
```lua
-- Primary (family-wide, UNVERIFIED on this build — named research item):
hl.layer_rule({ match = { namespace = "^quickshell-.*" }, blur = true })
-- Fallback (per-surface exact match, same idiom as the wleave/walker/swaync rules above):
hl.layer_rule({ match = { namespace = "quickshell-dashboard" }, blur = true })
hl.layer_rule({ match = { namespace = "quickshell-dashboard" }, ignore_alpha = 0.5 })
hl.layer_rule({ match = { namespace = "quickshell-dashboard" }, animation = "slide" })
```

---

### `theme-engine/.config/theme-engine/motion.json` (edit)

**Analog:** itself — the `semantic` object (existing four entries), NOT the `indicators` bucket (motion-lint pitfall, verified against the linter's own source):
```json
"semantic": {
    "standard": { "duration": "short4", "easing": "standard" },
    "emphasized-in": { "duration": "medium2", "easing": "emphasized-decelerate" },
    "emphasized-out": { "duration": "short3", "easing": "emphasized-accelerate" },
    "standard-slow": { "duration": "medium2", "easing": "standard" },
    "ambient": { "duration": "extra-long4", "easing": "linear" }
}
```
D-21's new stagger-offset token must be added as a NEW key in this exact object, e.g. `"stagger-offset": { "duration": "short1", "easing": "standard" }`, referencing existing named `durations`/`easings` keys (never a new literal number). Follow-through requires extending `Motion.qml`'s `_pairNames` array (line 49) to include the new key name — the singleton does not auto-discover new semantic entries.

---

### `stow.sh` (edit — weather location/units state seed)

**Analog:** itself — the seed-only-when-absent idiom (~lines 215-237), e.g.:
```bash
mkdir -p "$HOME/.local/state/theme"
[[ -f "$HOME/.local/state/theme/waybar-visibility.css" ]] || : > "$HOME/.local/state/theme/waybar-visibility.css"
```
The weather state file follows this identical `mkdir -p` + `[[ -f ... ]] || <seed>` shape, seeding city-level coordinates (D-30) and metric units (D-31) as its default content — never GeoIP, never a live-populated value.

---

### `theme-engine/.config/theme-engine/contract.json` (edit)

**Analog:** itself, `engine_owned_files` array (lines 35-45) — append the weather location/units state filename and the weather cache filename as new array entries, following the existing flat-string-list shape (e.g. alongside `"motion-scale"`).

---

### `install.sh` (edit — Material Symbols font)

**Analog:** itself — `AUR_PKGS` array (~line 256) plus the existing hard-fail `verify_packages()` loop (~lines 595-648), already exercised by `walker`/`elephant`-class unpinned AUR entries:
```bash
AUR_PKGS=(
    # ... existing entries ...
    ttf-material-symbols-variable-git
)
```
No separate verify step needed — `VERIFY_PKGS=("${PACMAN_PKGS[@]}" "${AUR_PKGS[@]}")` (line 641) and `verify_packages VERIFY_PKGS` (line 648) already cover any new `AUR_PKGS` entry automatically. Per the Package Legitimacy Audit in RESEARCH.md, this specific addition needs a `checkpoint:human-verify` task before install (flagged `[SUS — unverified]`).

## Shared Patterns

### Layer-shell surface scaffold (summon/dismiss/focus)
**Source:** `quickshell/.config/quickshell/modules/Probe.qml` lines 61-106; `quickshell/.config/quickshell/shell.qml` lines 46-67
**Apply to:** `Dashboard.qml` in full — this is the single most load-bearing analog in the whole phase. Reuse `LazyLoader` + `GlobalShortcut` + `WlrLayershell` (Overlay/OnDemand/exclusiveZone:0) + `HyprlandFocusGrab` verbatim; only the namespace string (`quickshell-dashboard`), the `Variants`-vs-single-instance choice (single instance, no per-screen fan-out per D-14), and the content inside the window are new.

### Token consumption (color + motion, no literals)
**Source:** `quickshell/.config/quickshell/modules/Colours.qml`, `Motion.qml`, and their usage throughout `Probe.qml` (e.g. lines 229-240, 259-263)
**Apply to:** Every dashboard tab/widget file. Zero hex/duration literals — read `Colours.<role>` and `Motion.<pair>Duration`/`Motion.<pair>Easing`/`Motion.motionEnabled` exclusively; wrap every animated property in a `Behavior` gated on `Motion.motionEnabled`, matching Probe.qml's convention exactly. `motion-lint` (TOKEN-04) will scan every new QML file in scope.

### FileView/JsonAdapter reactive state read, with loud-not-silent fallback defaults
**Source:** `Colours.qml` lines 85-141, `Motion.qml` lines 53-80, `Probe.qml` lines 112-125, 192-227
**Apply to:** Every backend that reads a state file (theme mode, gaming-mode cache, motion-scale, weather cache/location). Pattern: `FileView { watchChanges: true; printErrors: true; onFileChanged: reload(); onLoadFailed: ... }` wrapping a `JsonAdapter` whose every property has an explicit, visibly-wrong default (never silent null/0/black) — Colours.qml uses `#FF00FF` magenta as its sentinel; the dashboard's own widgets should follow the SAME "loud sentinel, not black/white" discipline for any newly-read numeric/string field.

### Sanctioned script-exec, never re-implement the mutation logic
**Source:** `swaync/.config/swaync/config.json` `buttons-grid.actions`; `hypr/.config/hypr/scripts/media-status.sh` header comment (lines 1-25); `hypr/.config/hypr/scripts/media-players.sh` (referenced, not modified)
**Apply to:** `MediaBackend.qml`, `QuickToggles.qml`, `WeatherBackend.qml`'s cache-writer half if scripted. Every write/mutate action in the drawer routes through an EXISTING sanctioned script (`media-players.sh`, `gaming-mode-toggle.sh`, `swaync-client -dn/-df`, `theme-switch.sh`, `motion-switch.sh`) via `Quickshell.Io.Process` — never a raw `playerctl`/D-Bus call constructed in QML, never a second state-writer for anything swaync/media/gaming/theme/motion already own.

### Module manifest discipline
**Source:** `quickshell/.config/quickshell/modules/qmldir` (whole file, especially its own header comment lines 1-19)
**Apply to:** Every new `.qml` file added under `modules/` or `modules/dashboard/`. The qmldir disables directory-scanning; any type not explicitly listed becomes unresolvable. Add each new type to `qmldir` in the SAME commit that creates it — this file's own header states this as a standing instruction, not a suggestion.

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `PerformanceTab.qml`'s circular dial rendering (CPU/mem/storage/battery arcs) | component | poll/transform | No `QtQuick.Shapes`/`Canvas` gauge component exists anywhere in this repo yet — genuinely new custom QML; RESEARCH.md's "Don't Hand-Roll" table flags this explicitly and points to Caelestia's `HeroCard.qml` as an EXTERNAL (not in-repo) structural reference only |
| `SwipeView`/`TabBar` pager wiring (D-16/D-17/D-18) | component | event-driven | First multi-pane pager in this repo; no in-repo QML analog exists — RESEARCH.md's Pattern 3 (Qt docs + this machine's installed `qt6-declarative` source) is the only available reference, not a codebase file |

## Metadata

**Analog search scope:** `quickshell/.config/quickshell/` (all `.qml`/`.json` files), `hypr/.config/hypr/config/` (`keybinds.lua`, `windowrules.lua`), `hypr/.config/hypr/scripts/` (`media-status.sh` header only), `swaync/.config/swaync/config.json`, `theme-engine/.config/theme-engine/` (`motion.json`, `contract.json`), `stow.sh`, `install.sh`
**Files scanned:** 17 (full or targeted reads)
**Pattern extraction date:** 2026-07-29
