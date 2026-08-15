# Phase 20: Indicators & Power Menu - Pattern Map

**Mapped:** 2026-08-15
**Files analyzed:** 9 (2 extended, 1 new QML surface + its two backends' new consumers, 3 repoint sites, 1 config file, 1 new sysfs backend)
**Analogs found:** 9 / 9

This phase is almost entirely reuse (per RESEARCH.md's own framing). There is very little "new file, find an analog" work in the classic sense — the dominant pattern is "extend this exact file with N properties" or "add a new file that composes these exact existing files." Analogs below are chosen accordingly: where a file is *extended*, the analog is the file itself (showing what shape its extension points already take); where a file is *new*, the analog is the closest sibling this repo already ships.

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `quickshell/.config/quickshell/modules/toast/Toast.qml` (extended: `edge`, `interactive`, `namespace` properties) | component (layer-shell surface) | event-driven | itself (extension in place) | exact |
| `quickshell/.config/quickshell/modules/session/PowerMenu.qml` (new) | component (modal dialog) | request-response | `quickshell/.config/quickshell/modules/dashboard/PanelDialog.qml` | role-match (pattern reused, geometry diverges — see notes) |
| `quickshell/.config/quickshell/modules/bar/CapsLockBackend.qml` or inline `FileView` (new sysfs watcher) | service/backend (file-I/O) | event-driven | `ClockActionsCapsule.qml`'s `gamingStateFile` FileView (lines ~586-592) | exact (same watched-`FileView` idiom; glob-resolution logic is new, no precedent) |
| OSD slider rows inside the `Toast` instance's `body` (new QML, no new file — content composed inline or as a small `OsdSliderRow.qml`) | component (slider row) | CRUD (reads+writes backend value) | `quickshell/.config/quickshell/modules/bar/AudioPopout.qml` (slider `background`/`handle` delegates, lines ~130-165) | exact |
| `quickshell/.config/quickshell/modules/session/PowerMenuBackend.qml` or inline detectors (QPOWER-03 pgrep/downloads/toplevel-count) | service (Timer-polled `Process` wrapper) | event-driven (poll while visible) | `ClockActionsCapsule.qml`'s `powerAvailabilityProbe` `Process` (lines ~570-575) for the `Process`-wrapping idiom; `BrightnessBackend.qml`'s single-flight discipline for the coalescing shape | role-match |
| `hypr/.config/hypr/config/keybinds.lua:68` (repoint `Super+Shift+Q`) | config (keybind) | event-driven | itself — the line being edited; sibling binds on the same file (e.g. line 67 `mainMod + Q`) show the `hl.bind(...)` call shape | exact |
| `elephant/.config/elephant/menus/main.toml:35` (repoint walker menu `actions.open`) | config | request-response | itself — the entry being edited | exact |
| `quickshell/.config/quickshell/modules/bar/ClockActionsCapsule.qml:567-580` (repoint `powerLaunchProcess`, delete `powerAvailabilityProbe`/`powerAvailable`) | component (bar capsule, launcher glue) | event-driven | itself — the block being edited | exact |
| `hypr/.config/hypr/config/windowrules.lua` (append `quickshell-osd` / `quickshell-session` layer rules) | config (layer rules) | event-driven | the three `quickshell-notif-*` exact-match rows (lines ~524-526, 560-565) | exact |

## Pattern Assignments

### `quickshell/.config/quickshell/modules/toast/Toast.qml` (extend in place)

**Analog:** itself — current hardcoded points that must become properties.

**Current state to change** (verified this session, exact lines):
```qml
// Line 96 — hardcoded anchor, must become conditional on a new `edge` property
anchors.top: true

// Line 101 — hardcoded namespace literal, must become a per-instance property
WlrLayershell.namespace: "quickshell-notif-toast"

// Lines 103-104 — hardcoded non-interactive, must become conditional on `interactive`
WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
focusable: false

// Line 82 — hardcoded interval, must become a per-instance property
Timer {
    id: toastDismissTimer
    interval: Design.notifToastDurationMs
    repeat: false
    onTriggered: toastWindow.hide()
}
```

**Show()/hide() contract to preserve unchanged** (lines ~52-77):
```qml
default property alias body: bodyRow.data
property bool toastActive: false

function show() {
    var wasActive = toastWindow.toastActive;
    toastWindow.toastActive = true;
    toastDismissTimer.restart();
    if (wasActive)
        return;
    exitAnim.start();   // NB: verify this is the entrance anim in full file — only restarts timer if already active
}
```

**Defaults required for byte-identical DND behaviour:** every new property (`edge: "top"`, `interactive: false`, `namespace: "quickshell-notif-toast"`) must default to the current literal so `shell.qml`'s existing DND `Toast` instance (lines 103-147) needs zero changes.

**Header comment discipline:** the file's own header states "never dismissible by click… feedback, not content" (D-20-03) — update in the same commit to note this narrows (still true for non-interactive default) rather than breaks.

---

### `quickshell/.config/quickshell/modules/session/PowerMenu.qml` (new)

**Analog:** `quickshell/.config/quickshell/modules/dashboard/PanelDialog.qml` — pattern reused (rim/cascade/focus-grab/background), geometry diverges (full-screen-anchored scrim window + centred card, uniform corner radius, `WlrKeyboardFocus.Exclusive` not `OnDemand`).

**Layer posture pattern to copy, then diverge on** (lines ~122-133):
```qml
anchors.top: true                      // PowerMenu: anchors all 4 edges (full-screen scrim window) instead
implicitWidth: panelWindow.panelWidth  // PowerMenu: full output width/height for the scrim window;
implicitHeight: panelWindow.panelHeight//   card itself is a child Item, sessionDialogWidth (488px), centerIn: parent
exclusiveZone: 0
exclusionMode: ExclusionMode.Normal
WlrLayershell.layer: WlrLayer.Overlay
WlrLayershell.namespace: "quickshell-" + panelWindow.namespaceSuffix   // → "quickshell-session" (D-20-33)
WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand   // PowerMenu: WlrKeyboardFocus.Exclusive (D-20-24, deliberate divergence)
color: "transparent"
```

**Background + rim to copy verbatim** (lines ~139-172), only the corner-radius call sites change (uniform `popoutCornerRadius` on all 4 corners, not bottom-only):
```qml
Rectangle {
    id: background
    anchors.fill: parent
    // PanelDialog: bottom-only rounding (topLeftRadius:0, topRightRadius:0, bottomLeft/Right: cornerRadius)
    // PowerMenu:  uniform — all four corners at Design.popoutCornerRadius (floats clear of every edge)
    color: Qt.rgba(panelWindow.surfaceBase.r, panelWindow.surfaceBase.g, panelWindow.surfaceBase.b, panelWindow.panelSurfaceOpacity)
    Behavior on color {
        enabled: Motion.motionEnabled
        ColorAnimation {
            duration: Motion.standardDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Motion.standardEasing
        }
    }
}

GradientBorder {
    anchors.fill: parent
    borderWidth: panelWindow.borderWidth
    // same radius correction as background above
}
```

**Focus-grab dismissal — copy verbatim, coexists with Exclusive focus per RESEARCH.md finding:**
```qml
HyprlandFocusGrab {
    id: grab
    windows: [ panelWindow ]
    active: true
    onCleared: panelWindow.requestDismiss()
}
```

**Cascade entrance — copy pattern, extend band list from 2 to 7 (header + 6 tiles):**
```qml
readonly property Cascade entranceCascade: Cascade {}

Component.onCompleted: {
    panelWindow.entranceCascade.bands = [headerIdentity, advancedButton].concat(panelWindow.bodyCascadeBands);
    // PowerMenu: bands = [header, tile1, tile2, tile3, tile4, tile5, tile6]
    panelWindow.entranceCascade.armed = true;
    panelWindow.entranceCascade.run();
}
```

**Design-derived constants block** (lines ~136-158) — copy the whole re-declaration idiom (reading tokens off `panelWindow` rather than `Design`/`Colours` directly in the body), including the two locally-declared (not `Design.qml`) line-height tokens `lineHeightTight: 1.2` / `lineHeightNormal: 1.5` — per UI-SPEC's Step-9.5 correction, pick declaring these locally (this analog's own convention) rather than promoting them to `Design.qml`.

---

### Caps Lock sysfs watcher (new — inline `FileView` in the OSD content, or a small `CapsLockBackend.qml`)

**Analog:** `quickshell/.config/quickshell/modules/bar/ClockActionsCapsule.qml:586-592` (verified this session) — the exact `FileView{watchChanges:true}` idiom, already production-proven in this repo for a different watched file.

```qml
// Source: ClockActionsCapsule.qml:586-592 — copy this shape verbatim for the fixed-path part
FileView {
    id: gamingStateFile
    path: clockActionsCapsule.homeDir + "/.cache/gaming-mode"
    watchChanges: true
    onFileChanged: reload()
}
readonly property string gamingRaw: (gamingStateFile.text() || "").trim()
readonly property bool gamingOn: (gamingRaw.length > 0 ? gamingRaw : "off") === "on"
```

**What's genuinely new (no precedent to copy):** the glob-at-startup / re-glob-on-read-failure resolver for `/sys/class/leds/*::capslock/brightness` (D-20-14) — the node name (`inputNN`) is not stable across boots. `FileView.path` must be set from a resolved glob result, and on read failure the resolver must re-glob rather than treating the failure as terminal. No existing file in this repo globs a sysfs path; this logic must be written fresh, following only the `watchChanges: true` / `onFileChanged` half of the pattern above.

**Live-verify requirement (RESEARCH.md Priority Finding 2 / Pitfall 3):** confirm `onFileChanged` actually fires on a real physical Caps Lock press before treating QOSD-02 as done — the kernel mechanism is documented (`led_notify_brightness_change` → `kernfs_notify` → inotify) but not exercised live this session. If it does not fire, the fallback is a `Timer`-based poll, which costs the phase its zero-idle claim for this one indicator and must be flagged back as a scope conversation, not silently substituted.

---

### OSD slider rows (volume/mic/brightness — new content inside the `Toast` instance's `body`)

**Analog:** `quickshell/.config/quickshell/modules/bar/AudioPopout.qml` slider geometry — reused **verbatim**, not a lighter variant (UI-SPEC's own resolved Claude's-Discretion item).

```qml
// Source: AudioPopout.qml ~lines 130-165 (verified via grep this session)
onMoved: {
    // setMasterVolume() carries no range clamp of its own — clamp here
    root.audioBackend.setMasterVolume(Math.max(0, Math.min(1, audioVolumeSlider.value)));
}
// track:
height: 8
radius: 4
// handle:
width: 20
height: 20
radius: 10   // per UI-SPEC's stated geometry (implicit from 20x20 + "radius: 10")
```

**Write-path functions to call directly — already exist, do not re-derive:**
```qml
// AudioBackend.qml:35  import Quickshell.Services.Pipewire
// AudioBackend.qml:73  function setMasterVolume(v) { ... }
// AudioBackend.qml:77  function setMasterMuted(on) { ... }
// AudioBackend.qml:81  function setInputVolume(v) { ... }
// AudioBackend.qml:85  function setInputMuted(on) { ... }

// BrightnessBackend.qml:234-244 — already shipped, single-flighted:
function setPercent(percent) {
    if (!root.present || root.deviceName === "")
        return;
    const clamped = Math.max(0, Math.min(100, Math.round(percent)));
    if (adjustProcess.running) {
        root.pendingDelta = 0;
        root.pendingAbsolutePercent = clamped;
        return;
    }
    root._startAbsolute(clamped);
}
```
**Do not write a second `brightnessctl` `Process` or `wpctl` subprocess call** — both write paths already exist and are single-flighted/coalesced; a duplicate would race the existing writer (RESEARCH.md Pitfall 4, Don't Hand-Roll table).

---

### QPOWER-03 detectors (pgrep / downloads-heuristic / toplevel-count — new `Process`-wrapping code)

**Analog for the `Process`-wrapping idiom:** `ClockActionsCapsule.qml:570-575` (`powerAvailabilityProbe`):
```qml
Process {
    id: powerAvailabilityProbe
    command: ["test", "-x", clockActionsCapsule.powerScriptPath]
    onExited: function (exitCode, exitStatus) {
        clockActionsCapsule.powerAvailable = exitCode === 0;
    }
}
```
Copy this `Process { command: [...]; onExited: function(exitCode, exitStatus) { ... } }` shape for each of the three detectors (`pgrep -x pacman`/`paru`/`yay`, the downloads-mtime `find`, the `hyprctl` toplevel-count-by-class check), gated behind a `Timer` that only runs while the power menu `visible` (D-20-30, zero-idle).

**Analog for the single-flight/coalescing discipline** (do not fire a second `Process` while one is already running): `BrightnessBackend.qml`'s `adjustProcess.running` guard shown above — same discipline applies to the low-frequency poll Timer: skip a tick if the previous detector round hasn't exited yet.

---

### Repoint: `hypr/.config/hypr/config/keybinds.lua:68`

**Analog:** the line itself + its sibling bind at line 67 for the `hl.bind(...)` call shape.
```lua
-- Current (line 68):
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exec_cmd("~/.config/hypr/scripts/wleave.sh")) -- Open power menu
-- Sibling shape (line 67), for reference on the exec_cmd idiom:
hl.bind(mainMod .. " + Q", hl.dsp.window.kill()) -- Close active window
```
Repoint target: whatever mechanism triggers the in-process `PowerMenu.qml` (e.g. an IPC/global-shortcut handler already used elsewhere for other QML-surface toggles — check `Dashboard.qml`'s own toggle bind for the exact idiom of invoking a QML singleton's toggle function from Hyprland, since this is no longer `exec_cmd` against a script but an in-process show()).

---

### Repoint: `elephant/.config/elephant/menus/main.toml:35`

**Analog:** the entry itself.
```toml
[[entries]]
text = "  Power"
# D-19: delegates to the ONE existing power surface (same as Super+Shift+Q).
# D-09: shell script, invoked bare — never uwsm app --.
actions = { "open" = "~/.config/hypr/scripts/wleave.sh" }
```
Repoint `actions.open` to whatever the keybind above now calls (same target both places, per the file's own comment "delegates to the ONE existing power surface").

---

### Repoint + delete: `quickshell/.config/quickshell/modules/bar/ClockActionsCapsule.qml:567-580`

**Current block (verified, lines 567-580):**
```qml
readonly property string powerScriptPath: clockActionsCapsule.homeDir + "/.config/hypr/scripts/wleave.sh"
property bool powerAvailable: true

Process {
    id: powerAvailabilityProbe
    command: ["test", "-x", clockActionsCapsule.powerScriptPath]
    onExited: function (exitCode, exitStatus) {
        clockActionsCapsule.powerAvailable = exitCode === 0;
    }
}
Process {
    id: powerLaunchProcess
    command: [clockActionsCapsule.powerScriptPath]
}
```
**Change:** delete `powerScriptPath`, `powerAvailable`, `powerAvailabilityProbe` entirely (D-20-23 — no "missing surface" state possible for an in-process QML dialog). `powerLaunchProcess`'s `onClicked` handler is repointed to call the `PowerMenu` singleton's show/toggle function directly (in-process, no `Process` launch at all) — the `powerCell`'s own rendering (glyph `power_settings_new`, permanent accent tint, tooltip) is unchanged per UI-SPEC's explicit "repoint internals, leave rendering untouched" instruction (same discipline Phase 19 applied to the bell/`NotificationSource`, same file).

---

### `hypr/.config/hypr/config/windowrules.lua` — new `quickshell-osd` / `quickshell-session` namespace rows

**Analog:** the three `quickshell-notif-*` exact-match rows (verified, lines ~524-526 and ~560-565), which are the worked example of "declared after the family regex, restated blur, explicit `ignore_alpha` override matching the surface's actual fill alpha."

```lua
-- Family regex + floor already exist (no change needed) — verified at:
hl.layer_rule({ match = { namespace = "^quickshell-.*" }, blur = true })          -- ~line 396
hl.layer_rule({ match = { namespace = "^quickshell-.*" }, ignore_alpha = 0.5 })   -- ~line 445

-- Worked precedent to copy the SHAPE of (notif family, lines ~524-526, ~560-565):
hl.layer_rule({ match = { namespace = "quickshell-notif-popups" }, animation = "slide" })
hl.layer_rule({ match = { namespace = "quickshell-notif-centre" }, animation = "slide" })
hl.layer_rule({ match = { namespace = "quickshell-notif-toast" }, animation = "slide" })
-- ... (blur restated for each, ~line 559-562) ...
hl.layer_rule({ match = { namespace = "quickshell-notif-popups" }, ignore_alpha = 0.2 })
hl.layer_rule({ match = { namespace = "quickshell-notif-centre" }, ignore_alpha = 0.2 })
hl.layer_rule({ match = { namespace = "quickshell-notif-toast" }, ignore_alpha = 0.2 })

-- NEW rows this phase adds, in the file's LAST block (after line 565):
hl.layer_rule({ match = { namespace = "quickshell-osd" }, animation = "slide" })
hl.layer_rule({ match = { namespace = "quickshell-osd" }, blur = true })
hl.layer_rule({ match = { namespace = "quickshell-osd" }, ignore_alpha = 0.2 }) -- matches Toast.qml's reused 0.38 fill (BarRoles.notifSurface), same as the notif-toast row above
hl.layer_rule({ match = { namespace = "quickshell-session" }, animation = "slide" })
-- quickshell-session's card fill (Colours.surface @ panelSurfaceOpacity 0.78) is comfortably
-- above the family's own 0.5 floor — no override row predicted needed, verify once rendered.
```

**Critical trap (RESEARCH.md Pitfall 1, concrete numbers):** `quickshell-osd` does NOT inherit `quickshell-notif-toast`'s 0.2 override just because it reuses the same `Toast.qml` fill (`BarRoles.notifSurface`, alpha 0.38). A fresh namespace only gets the family's 0.5 floor. 0.38 < 0.5 — without the explicit `quickshell-osd` `ignore_alpha = 0.2` row above, blur silently turns off, reading exactly like "the alpha is wrong."

**Apply with `hyprctl eval`, never `hyprctl reload`** — this file's own already-documented finding (also in project memory: `hyprctl reload drops layer rules`) is that `reload` silently no-ops layer-rule edits; only `hyprctl eval '<rule>'` or a full Hyprland restart tests them live.

## Shared Patterns

### Zero-idle backends (governs QOSD-02 sysfs watch and QPOWER-03 detectors)
**Source:** the standing project rule, worked example `ClockActionsCapsule.qml`'s `gamingStateFile` (event-driven `FileView`, no polling) and `BrightnessBackend.qml`'s single-flight `Process` guard (no overlapping subprocess spawns).
**Apply to:** the Caps Lock `FileView`/glob resolver (must not fall back to a `Timer` poll unless the live-verify task proves `onFileChanged` never fires) and the QPOWER-03 `Timer` (must only run while the power menu is `visible`, per D-20-30 — no timer while dismissed).

### `hl.bind(...)` / `exec_cmd` idiom for Hyprland-side dispatch
**Source:** `hypr/.config/hypr/config/keybinds.lua` (surrounding lines 65-70).
**Apply to:** any Hyprland-side repoint of the three power-menu entry points — but note the target is changing shape from "exec an external script" to "invoke an in-process QML singleton," so the exact mechanism (likely an existing `hyprctl`/socket-based toggle already used for `Dashboard.qml` or `Overview.qml`, not a literal `exec_cmd` string) should be confirmed against how this repo already toggles another in-process QML surface from a Hyprland keybind before assuming `exec_cmd` still applies.

### Layer-rule ordering + `ignore_alpha` override discipline
**Source:** `hypr/.config/hypr/config/windowrules.lua`'s three worked notif-family rows (see above) — every exact-match namespace row is declared after the family regex, in the file's last block, and any surface whose fill alpha sits below the active floor gets its own explicit override row in the same commit as its `animation` row.
**Apply to:** both `quickshell-osd` and `quickshell-session` namespace registrations (D-20-33/34).

### "Repoint internals, leave rendering untouched" for existing consumers
**Source:** Phase 19's own precedent on the bell (`NotificationSource`) inside `ClockActionsCapsule.qml` — cited explicitly in UI-SPEC.
**Apply to:** the bar's `powerCell` (glyph/tint/tooltip stay identical, only `onClicked`'s target and the deleted probe change) and the walker menu entry (label/icon unchanged, only `actions.open` changes).

## No Analog Found

None — every file this phase touches has a concrete existing analog in the codebase (either itself, in the extend-in-place cases, or a named sibling file). The two places RESEARCH.md flags as genuinely new logic with no in-repo precedent are noted inline above rather than listed here as "no analog," since they are sub-portions of files that do have analogs for their surrounding shape:
- The sysfs glob-at-startup / re-glob-on-failure resolver (inside the Caps Lock `FileView` file) — no existing file in this repo globs a sysfs path.
- The three QPOWER-03 detector `Process` bodies' actual shell commands (`pgrep`, `find`, `hyprctl` toplevel count) — the `Process`-wrapping idiom has a strong analog (`powerAvailabilityProbe`), but no existing file in this repo runs these specific commands.

## Metadata

**Analog search scope:** `quickshell/.config/quickshell/modules/{toast,dashboard,bar,session}/`, `hypr/.config/hypr/config/{keybinds,windowrules}.lua`, `elephant/.config/elephant/menus/main.toml` — scoped directly from CONTEXT.md's canonical_refs and RESEARCH.md's verified file/line citations rather than a fresh repo-wide search, per the task's own instruction to use RESEARCH.md's exact paths as the starting point.
**Files scanned:** 7 read/grepped directly this session (`Toast.qml`, `PanelDialog.qml`, `ClockActionsCapsule.qml`, `AudioBackend.qml`, `BrightnessBackend.qml`, `windowrules.lua`, `keybinds.lua`, `main.toml`, `AudioPopout.qml`) plus CONTEXT.md/RESEARCH.md/UI-SPEC.md's own prior verified reads (`Cascade.qml`, `Design.qml`, `BarRoles.qml`, `Colours.qml`, `Motion.qml`) cited but not re-read this session (no re-read discipline).
**Pattern extraction date:** 2026-08-15
