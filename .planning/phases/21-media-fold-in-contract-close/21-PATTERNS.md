# Phase 21: Media Fold-In & Contract Close - Pattern Map

**Mapped:** 2026-08-16
**Files analyzed:** 20 (created + modified)
**Analogs found:** 18 / 20 (2 have NO local structural precedent — flagged explicitly, not papered over)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|---|---|---|---|---|
| `quickshell/.config/quickshell/modules/dashboard/CavaService.qml` (NEW) | service (singleton) | streaming (subprocess line-stream) | `MediaBackend.qml`'s `artResolveProcess` (Process/`StdioCollector`, lines 294-311) — structural only | **NO STREAMING ANALOG** — nearest is a one-shot `Process`, not a streaming one |
| `quickshell/.config/quickshell/modules/dashboard/CavaService.qml` (refcount/linger half) | service (singleton, ownership) | event-driven (claim/release) | `PopoutController.qml`'s `dwellTimer`/`graceTimer` pair (lines 180-205) — structural only | **NO REFCOUNT ANALOG** — nearest is a non-repeating grace Timer, not a counter |
| `quickshell/.config/quickshell/modules/dashboard/MediaTab.qml` (Repeater ring edit, ~525-567) | component | transform (audio amplitude → geometry) | itself, lines 525-567 (the `Shape`/`ShapePath`/`PathAngleArc` it replaces) | exact (direct ancestor) |
| `quickshell/.config/quickshell/modules/dashboard/MediaTab.qml` (cookie mask edit, ~571-660) | component | transform | itself, lines 571-660 (existing `MultiEffect` mask block) | exact (mask mechanism unchanged, source path changes) |
| `quickshell/.config/quickshell/modules/dashboard/MediaTab.qml` (player-switcher rows, 824-899) | component | CRUD (per-row read/write volume) | itself, lines 858-896 (existing row `MouseArea`) | exact |
| `quickshell/.config/quickshell/modules/dashboard/MediaBackend.qml` (`setVolumeForPlayer` add, near :355-360) | service | CRUD | itself, `setVolume()` at :355-360 and `selectPlayer` id-validation at :129-139 | exact |
| `quickshell/.config/quickshell/modules/dashboard/MediaBackend.qml` (dedup pass, `players` projection ~:145-160) | service | transform | itself, existing `players` computed projection | exact |
| `quickshell/.config/quickshell/modules/bar/MediaPopout.qml` (ring + cookie mask, NEW to this file) | component | transform | `MediaTab.qml:525-660` (both ring and mask blocks) | role-match (same technique, different host file) |
| `cava/.config/cava/config` (NEW file) | config | file-I/O | `ags/.config/ags/cava/config` (being retired) | exact (content/shape mirror, D-21-07) |
| `quickshell/.config/quickshell/modules/dashboard/Design.qml` (`cavaLingerMs` add) | config | — | itself, existing constant declarations (`popoutDwellMs`, `popoutDismissGraceMs` in `Design.qml`/`PopoutController.qml`) | exact |
| `quickshell/.config/quickshell/modules/bar/BarRoles.qml` (`dndSurface`/`dndSurfaceFg` add) | config/service | transform (colour blend) | itself, existing `Qt.rgba(root.*.r/.g/.b, alpha)` blend tokens (e.g. `barSurface`) | exact |
| `quickshell/.config/quickshell/modules/bar/ClockActionsCapsule.qml` (DND tint wiring) | component | event-driven | itself, `notificationSource.dndActive` read at :621; `BarCapsule.qml`'s shared `color:` expression | exact |
| `quickshell/.config/quickshell/modules/dashboard/Dashboard.qml` / `shell.qml` (`Super+M` wiring) | controller (shortcut dispatch) | event-driven | `shell.qml:412-415` `onDashboardRequested`, `shell.qml:933-949` `dashboardShortcut` | exact |
| `hypr/.config/hypr/config/keybinds.lua` (`Super+M` bind add) | config | — | `keybinds.lua:205-233` existing surface-shortcut block | exact |
| `quickshell/.config/quickshell/shortcuts.json` (manifest row add) | config | — | existing `dashboard`/`audio-panel`/`overview`/`notif-centre` entries | exact |
| `theme-engine/.config/theme-engine/contract.json` (remove `ags.scss` entry) | config | — | Phase 20's `wleave.css` removal commit `f30a671` | exact (prior retirement, same file) |
| `matugen/.config/matugen/config.toml` (remove `[templates.ags]`, :94-103) | config | — | Phase 20/19 equivalent template-block removals in prior retirement commits | role-match |
| `theme-engine/.config/theme-engine/lib/reload.sh` (remove ags fan-out, :116-129) | script | event-driven | prior retirement commits' reload.sh trims (Phase 20/19) | role-match |
| `hypr/.config/hypr/config/windowrules.lua` (remove 2 rules, rewrite 8 comments) | config | — | Phase 20 `f30a671` wleave layer-rule removal + comment rewrite precedent | exact |
| `hypr/.config/hypr/scripts/quickshell-doctor` (repair check 9, :2867-2883) | test/utility | batch (gate check) | itself — the check being repaired in place | exact |
| `hypr/.config/hypr/scripts/retirement-check` (flip row :92) | test/utility | — | Phase 20 `ada405a` "flip wlogout/eww registry rows" | exact |
| `hypr/.config/hypr/scripts/tests/test-media-hardening.sh` (trim + 1 new check) | test | — | itself, existing checks 8/9/9b/10 structure | exact |
| `install.sh` (:238-244 comment rewrite, :349-353 removal) | config | — | Phase 20 `a8d3cd8`/`f30a671` install.sh package-removal + comment-correction precedent | exact |
| `stow.sh` (:20 remove `ags` row) | config | — | Phase 20 `f30a671` stow.sh package-array removal | exact |
| `hypr/.config/hypr/scripts/media-status.sh`, `media-players.sh`, `media-player.py` (DELETE) | utility | file-I/O | Phase 20's swayosd/wleave orphan-script deletions (`a8d3cd8`, `f30a671`) | exact |
| `.planning/milestones/v3.0-phases/16-workspace-overview/16-VERIFICATION.md` (NEW, reconstructed) | doc | batch | any prior phase's own `NN-VERIFICATION.md` in the same milestone tree, written contemporaneously | role-match (retroactive authoring, not a live template) |

## Pattern Assignments

### `CavaService.qml` (service singleton, streaming + refcount) — NO LOCAL PRECEDENT, build from primitives

**RESEARCH.md is explicit: zero files in this repo use `SplitParser`; zero files implement claim/release refcounting.** Do not treat either half as "copy this file" — assemble from the qmltypes contract and the two structural analogs below, and say so in the plan.

**Streaming half — structural analog only, `MediaBackend.qml:294-311`:**
```qml
// MediaBackend.qml:294-311 — the Process LIFECYCLE shape (running toggle,
// onExited handling) transfers. The stdout type does NOT — this is a
// StdioCollector (one-shot), not a SplitParser (streaming).
Process {
    id: artResolveProcess
    running: false
    stdout: StdioCollector {
        id: artResolveCollector
    }
    onExited: (exitCode, exitStatus) => {
        root._resolvedArtPath = (exitCode === 0) ? (artResolveCollector.text || "").trim() : "";
        ...
    }
}
```
**What transfers:** the `running: false` default + explicit toggle-to-start lifecycle; single-flighted "one in-flight request at a time" discipline (adapted to refcount instead of URL-keying).
**What does NOT transfer:** `stdout` must be `SplitParser { splitMarker: "\n"; onRead: (line) => {...} }` (confirmed present in `/usr/lib/qt6/qml/Quickshell/Io/quickshell-io.qmltypes:282-300`, `DataStreamParser` base at `:32-46` with signal `read(string data)`) — there is no local file to copy this from.

**The proven line-parsing contract to mirror exactly** (`ags/.config/ags/lib/cava.ts`, full file, verbatim):
```typescript
subprocess(["cava", "-p", CONFIG], (line) => {
  const vals = line.split(";").filter((s) => s.length).map((s) => Number(s) / 100)
  if (vals.length) setBars(vals)
})
```
Port to QML as (illustrative, RESEARCH.md's own recommended shape):
```qml
stdout: SplitParser {
    splitMarker: "\n"
    onRead: (line) => {
        const vals = line.split(";").filter(s => s.length > 0).map(s => Number(s) / 100);
        if (vals.length > 0) root.bars = vals;
        // blank/partial lines: vals.length === 0 → silently ignored, last-good
        // root.bars value stays. Mirrors ags/lib/cava.ts exactly.
    }
}
```

**Refcount/linger half — structural analog only, `PopoutController.qml:195-205`:**
```qml
// PopoutController.qml:195-205 — the SHAPE to mirror: non-repeating Timer,
// condition re-checked at FIRE time, not at arm time. The token
// (Design.popoutDismissGraceMs) does NOT transfer — mint a new
// Design.cavaLingerMs constant (different scale, different purpose).
Timer {
    id: graceTimer
    interval: Design.popoutDismissGraceMs
    repeat: false
    running: false
    onTriggered: {
        if (root.combinedHovered || root.pinnedSection !== "")
            return;
        root.close();
    }
}
```
Adapted shape for `CavaService.qml` (illustrative — no counter exists anywhere in this tree to copy the counter itself from):
```qml
property int _claimCount: 0
function claim() { root._claimCount++; lingerTimer.stop(); if (!cavaProcess.running) cavaProcess.running = true; }
function release() { root._claimCount = Math.max(0, root._claimCount - 1); if (root._claimCount === 0) lingerTimer.restart(); }
Timer {
    id: lingerTimer
    interval: Design.cavaLingerMs   // new constant, recommend 5000
    repeat: false
    running: false
    onTriggered: {
        if (root.alwaysOn || root._claimCount > 0) return;  // re-checked at fire time
        cavaProcess.running = false;
    }
}
```

**Singleton registration convention** — confirmed BOTH `pragma Singleton` in the source file AND the `singleton` keyword in the owning `qmldir` are required (12-06 finding, restated in every `qmldir` header). Exact precedent, `modules/bar/qmldir:60`:
```
singleton PopoutController 1.0 PopoutController.qml
```
and `:83`, `:93` (`BarReveal`, `BarRoles`) — same pattern. `CavaService` needs an equivalent row. Since it must be consumed from BOTH `modules/dashboard/` (`MediaTab.qml`) and `modules/bar/` (`MediaPopout.qml`), register it in the top-level `modules/qmldir` — the same location `Colours`/`Motion` (the only other cross-directory singletons) are registered, per RESEARCH.md Pitfall 3.

---

### `MediaTab.qml` ring → Repeater (component, transform) — DIRECT ANCESTOR, verbatim excerpt

**Analog:** itself, `MediaTab.qml:525-567` [read verbatim this session]

```qml
// MediaTab.qml:525-567 — the block a Repeater of ShapePaths replaces.
// preferredRendererType: Shape.CurveRenderer, DashLine/RoundCap, and the
// Behavior on strokeColor idiom all carry forward unchanged; only the single
// ShapePath/PathAngleArc pair becomes N per-bar ShapePaths inside a Repeater.
Shape {
    id: artRing
    anchors.fill: parent
    asynchronous: true
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        id: artRingPath
        fillColor: "transparent"
        strokeColor: Colours.outline
        strokeWidth: root.ringStrokeWidth
        capStyle: ShapePath.RoundCap
        strokeStyle: ShapePath.DashLine
        dashPattern: [1, 3]

        startX: artSlot.width / 2 + root.ringRadius
        startY: artSlot.height / 2

        PathAngleArc {
            centerX: artSlot.width / 2
            centerY: artSlot.height / 2
            radiusX: root.ringRadius
            radiusY: root.ringRadius
            startAngle: 0
            sweepAngle: 360
        }

        Behavior on strokeColor {
            enabled: Motion.motionEnabled
            ColorAnimation {
                duration: Motion.standardDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Motion.standardEasing
            }
        }
    }
}
```

**Colour token change required by this same edit (D-21-04):** `strokeColor: Colours.outline` becomes a `Behavior`-animated transition between `Colours.outline` (silence) and `Colours.primary` (accent, when `amplitude > 0`) — `Colours.primary` is now a locked-legal use here per the required `14-UI-SPEC.md` amendment (see Shared Patterns below); do not leave it on `outline` only, and do not hardcode a hex.

**Cookie mask block (D-21-02), same file, :571-660** — the `MultiEffect.maskEnabled`/`maskSource` mechanism is unchanged; only the `artMaskShape` source changes from a `radius: width/2` circle to a hand-authored 12-lobe `ShapePath`. **`layer.enabled: true` on the mask source is load-bearing** (documented round-4 bug: omitting it silently produces an empty mask) — carries to the new shape unchanged.

---

### `MediaBackend.qml` — `setVolumeForPlayer` + dedup (service, CRUD/transform)

**Analog:** itself. Mutator pattern to clone, `setVolume()` (:355-360, referenced) plus the id-validation guard already used at `selectPlayer` (:129-139):
```
// Existing pattern: selectPlayer validates a caller-supplied id against
// Mpris.players.values before dispatch — setVolumeForPlayer(playerId, fraction)
// must apply the identical guard (RESEARCH.md § Security Domain, V5).
```
Dedup pass extends the existing `players` computed projection (~:145-160) — modify the loop that builds this array to collapse recognised duplicate sources BEFORE the array is returned, not filter after.

---

### `MediaPopout.qml` — ring + cookie mask (component, transform) — role-match, port from MediaTab.qml

**Analog:** `MediaTab.qml:525-660` (both blocks above). Confirmed this session: `MediaPopout.qml`'s current art block (:81-91) is a plain `Image` with `fillMode: Image.PreserveAspectCrop` — **no mask, no ring exist here today.** This is new code in this file, ported wholesale from `MediaTab.qml`, not an extension of anything already present in `MediaPopout.qml` itself.

---

### `cava/.config/cava/config` (NEW stow package, config, file-I/O)

**Analog:** `ags/.config/ags/cava/config` (being retired same phase) — full file, verbatim:
```ini
[general]
bars = 24
framerate = 60

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 100
bar_delimiter = 59
```
Copy verbatim except `bars = 24` → `bars = 60` (D-21-03, locked). No `[input]` section needed — confirmed cava autodetects on this host. `bar_delimiter = 59` (ASCII `;`) must stay paired with the reader's `.split(";")` — do not change one without the other.

---

### `Design.qml` — `cavaLingerMs` (config)

**Analog:** itself, existing sibling constants (`popoutDwellMs`, referenced via `PopoutController.qml:182`). Add:
```qml
readonly property int cavaLingerMs: 5000
```

---

### `BarRoles.qml` — `dndSurface`/`dndSurfaceFg` (config/service, transform)

**Analog:** itself, existing `Qt.rgba(roleColour.r/.g/.b, alpha)` blend idiom (`barSurface`, `capsuleHover`, etc. — full file read this session). Exact pattern to extend:
```qml
readonly property color dndSurface: Qt.rgba(root.accent.r, root.accent.g, root.accent.b, 0.28)
readonly property color dndSurfaceFg: Colours.onSurface
```
**Critical pre-existing trap this file's own header documents:** `Colours.*` are `property string` (hex strings from JSON) — `Qt.rgba(Colours.primary.r, ...)` on the raw string silently yields opaque BLACK with no error (a real GATE-02 defect recorded in `18.1-VERIFICATION.md`). Always blend through a `property color` indirection (`root.accent`, already typed `color` in `BarRoles.qml`), never `Colours.*` directly.

---

### `ClockActionsCapsule.qml` — DND tint (component, event-driven)

**Analog:** itself. Confirmed this session: `grep -n "surfaced:" ClockActionsCapsule.qml` → zero matches, so the baseline fill is unconditionally `"transparent"` (`BarCapsule.qml:79`'s `!surfaced` branch), NOT `BarRoles.capsule`. **Do not edit `BarCapsule.qml`'s shared expression** — override `color:` at the instance level on this file's own root `BarCapsule { ... }` object:
```qml
BarCapsule {
    id: clockActionsCapsule
    capsuleId: "clockActions"
    color: notificationSource.dndActive
        ? BarRoles.dndSurface
        : (!clockActionsCapsule.surfaced ? "transparent" : (clockActionsCapsule.hovered ? BarRoles.capsuleHover : BarRoles.capsule))
}
```
`notificationSource.dndActive` already exists at `ClockActionsCapsule.qml:621`, reading `NotifServer.dnd`. `Behavior on color` is inherited from `BarCapsule.qml:81-88` automatically (same property, base-type Behavior applies to instance-level overrides) — no separate animation to add unless testing shows otherwise (RESEARCH.md Open Question 1).

---

### `Super+M` keybind wiring (controller, event-driven)

**Analog:** `shell.qml:412-415` (`onDashboardRequested`) — exact pattern:
```qml
// shell.qml:412-415 — the exact pattern to mirror for the new GlobalShortcut
onDashboardRequested: (tabIndex) => {
    root.dashboardTabIndex = tabIndex;
    dashboardLoader.active = true;
}
```
`dashboardShortcut`'s own toggle-with-fullscreen-guard shape at `shell.qml:933-949` is the closest sibling for open/close behaviour (open-only vs toggle is an open call per RESEARCH.md A2 — recommend mirroring `dashboardShortcut`'s toggle but forcing `tabIndexMedia`).

`keybinds.lua:205-233` — the exact idiom every prior surface shortcut follows:
```lua
hl.bind(mainMod .. " + <LETTER>", hl.dsp.global("quickshell:<name>")) -- <comment>
```

`shortcuts.json` manifest — mirror the existing `dashboard`/`audio-panel`/`overview`/`notif-centre` entry shape (keybind-doctor cross-check requires a matching row).

---

### Retirement edit sites (config/script) — precedent is Phase 20's `f30a671` (RETIRE-05, wleave) and `a8d3cd8` (RETIRE-04, swayosd)

Every retirement edit site named in CONTEXT.md/RESEARCH.md mirrors the shape of a PRIOR retirement in this same milestone. Concrete precedent commits, in edit order per WINDOWS #1 (config-then-package, one commit):

| Edit site (this phase) | Precedent commit | What to mirror |
|---|---|---|
| `contract.json` remove `ags.scss` entry | `f30a671` (RETIRE-05, wleave) | remove-one-`files`-entry diff shape; verify `REPRESENTATIVE_FILES` doesn't name it first (the `wleave.css` trap this repo already hit once) |
| `matugen/config.toml` remove `[templates.ags]` (:94-103) | `f30a671` / `2ed3b5f` (RETIRE-04/05 template removals) | delete the named `[templates.X]` block + its header comment as one contiguous span |
| `theme-engine/lib/reload.sh` remove ags fan-out (:116-129) | prior retirements' reload.sh trims (same commits) | delete the guarded `command -v X && X list ... reload` step; leave the fan-out order of remaining steps untouched |
| `windowrules.lua` remove 2 real rules, rewrite 8 comments | `f30a671` (wleave layer-rule removal + comment rewrite) | delete `hl.layer_rule({ match = { namespace = "..." }, ... })` calls; REWRITE (never scrub) comments that record load-bearing findings, per D-21-19 — same discipline this repo's own Phase 20 final plan stalled on once already |
| `install.sh` comment correction (:238-244) + package removal (:349-353) | `a8d3cd8` (RETIRE-04 comment correction), `f30a671` (RETIRE-05 package removal) | correct a wrong attribution comment in place; delete one `AUR_PKGS`/equivalent array entry + its preceding comment |
| `stow.sh` remove `ags` row (:20) | `f30a671` (RETIRE-05 `PACKAGES=(...)` removal) | delete one array entry only — the GTK3 sass seed block (:417-464) is confirmed independent and stays untouched |
| `retirement-check` flip row :92 | `ada405a` ("flip wlogout/eww registry rows") — exact title match for this edit type | flip `pending` → `retired` in the pipe-delimited registry row, same commit as the package deletion |
| orphaned scripts deletion (`media-status.sh`, `media-players.sh`, `media-player.py`) | `a8d3cd8`/`f30a671` orphan-script deletions | delete whole files in the SAME commit as the package they were orphaned by, per the eww-leftovers lesson (quick task `260725-vu6`) this repo already paid for once |

---

### `quickshell-doctor` check 9 repair (test/utility, batch)

**Analog:** itself — this is an in-place repair, not a new check. Current (broken) code, verbatim [`quickshell-doctor:2867-2883`]:
```bash
if [[ -d "$QUICKSHELL_CONFIG_DIR" ]]; then
    MPRIS_HITS=0
    while IFS= read -r f; do
        grep -qE 'import[[:space:]]+Quickshell\.Services\.Mpris|\bMpris[A-Za-z]*[[:space:]]*\{' "$f" 2>/dev/null && MPRIS_HITS=$((MPRIS_HITS + 1))
    done < <(find -L "$QUICKSHELL_CONFIG_DIR" -type f 2>/dev/null)
    check "zero Quickshell MPRIS writers (found in ${MPRIS_HITS} file(s) under $QUICKSHELL_CONFIG_DIR)" "$([[ "$MPRIS_HITS" -eq 0 ]] && echo 0 || echo 1)"
```
Confirmed live-failing this session (`[FAIL] zero Quickshell MPRIS writers (found in 1 file(s))`). Change the assertion from `-eq 0` to `-eq 1`, rename the check/comment (it was never "writer", `MediaBackend.qml` is a reader), do NOT add a parallel check elsewhere — this repairs QMEDIA-03's own standing check.

## Shared Patterns

### Colour tokens — `colour-lint` (GATE-04) discipline
**Source:** `quickshell/.config/quickshell/modules/Colours.qml` (19 Material You roles) + `quickshell/.config/quickshell/modules/bar/BarRoles.qml` (blended bar-scoped tokens)
**Apply to:** every new/edited QML file in this phase (`CavaService.qml`, `MediaTab.qml`, `MediaPopout.qml`, `ClockActionsCapsule.qml`, `BarRoles.qml` itself)
Correct usage example (already live, `MediaTab.qml:534`, `:560-567`):
```qml
strokeColor: Colours.outline
Behavior on strokeColor {
    enabled: Motion.motionEnabled
    ColorAnimation { duration: Motion.standardDuration; easing.type: Easing.BezierSpline; easing.bezierCurve: Motion.standardEasing }
}
```
No hex literal, no raw number, anywhere in a `.qml` file outside `Colours.qml`/`Motion.qml`/`Design.qml`/`BarRoles.qml` — `colour-lint`/`motion-lint` reject both.

**Required non-code deliverable riding on this same token rule:** `14-UI-SPEC.md` lines 86/89 must be amended (D-21-04) to add the visualiser ring to the enumerated accent-reserved list — this is itself a plan task, not an implied side effect of building the ring.

### Singleton registration — both-required rule
**Source:** every `qmldir` header in this tree (`modules/qmldir`, `modules/bar/qmldir`, `modules/dashboard/qmldir`), each independently restating the same 12-06 finding.
**Apply to:** `CavaService.qml`
```
pragma Singleton   // in the .qml source file itself
```
```
singleton CavaService 1.0 CavaService.qml   // in the qmldir that owns it
```
Omitting either yields `undefined` forever with NO load error — this has bitten the codebase before and is why every qmldir header repeats the warning verbatim.

### Timer "re-check at fire time, not arm time" idiom
**Source:** `PopoutController.qml:180-205` (both `dwellTimer` and `graceTimer`)
**Apply to:** `CavaService.qml`'s `lingerTimer`
Every non-repeating Timer in this codebase re-evaluates its close/kill condition inside `onTriggered`, never trusts a captured boolean from arm time — mandatory for the linger timer since claim state can change during the 5s window.

### Config-then-package, one commit (retirement sequencing)
**Source:** WINDOWS #1 precedent, applied identically across commits `a8d3cd8`, `f30a671`, `54fe33d`, `3c8e3ce`
**Apply to:** the entire RETIRE-06 edit set — `contract.json`, `matugen/config.toml`, `reload.sh`, `windowrules.lua`, `retirement-check`, then the `ags` package/stow-row/script deletions, all in the SAME commit.

### Comment rewrite, never scrub, at a deletion site
**Source:** Phase 20's `f30a671` wleave retirement (the exact precedent for D-21-19's 8-site rewrite in `windowrules.lua`)
**Apply to:** all 8 `ags-media` comment sites — restate the underlying finding (e.g. "a fill alpha at or below the threshold silently discards blur") on its own terms, remove only the dead surface's name, never delete the explanatory content itself.

## No Analog Found

| File/Concern | Role | Data Flow | Reason |
|---|---|---|---|
| `CavaService.qml` streaming half (`Process`+`SplitParser`) | service | streaming | Zero `SplitParser` usage anywhere in this repo (31 existing `Process` call sites all use `StdioCollector`, one-shot). Must be built directly from the installed Quickshell 0.3.0-2 qmltypes contract (`/usr/lib/qt6/qml/Quickshell/Io/quickshell-io.qmltypes:32-46,282-300`), not copied from a local file. RESEARCH.md flags this as its own smoke-test task (Assumption A1) before the full visualiser is built on top. |
| `CavaService.qml` refcount half (claim/release counter) | service | event-driven | No `pragma Singleton` file in this tree implements claim/release/counter ownership (16 singleton files checked, none). `PopoutController.qml`'s grace-Timer pair transfers only its Timer *shape* (non-repeating, re-check-at-fire), never a counter — the `_claimCount` mechanism itself has to be authored fresh. |

## Metadata

**Analog search scope:** `quickshell/.config/quickshell/modules/` (dashboard, bar, top-level), `ags/.config/ags/` (retiring source), `theme-engine/.config/theme-engine/`, `hypr/.config/hypr/{config,scripts}/`, `install.sh`, `stow.sh`, git log across Phase 18-20 retirement commits.
**Files scanned:** ~30 read directly this session plus RESEARCH.md's own prior 40+ file verification pass (reused, not re-read).
**Pattern extraction date:** 2026-08-16
