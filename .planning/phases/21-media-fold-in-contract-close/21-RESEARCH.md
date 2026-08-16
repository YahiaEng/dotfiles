# Phase 21: Media Fold-In & Contract Close - Research

**Researched:** 2026-08-16
**Domain:** Quickshell/QML media surface consolidation, cava audio-visualiser streaming, theme-contract retirement mechanics
**Confidence:** HIGH — every claim below was verified directly on this host (file reads, `pacman -Q`, live gate runs, git history) rather than inferred. `21-CONTEXT.md` is unusually complete (28 locked decisions) and this document does not re-litigate any of them; it fills the implementation-mechanics gaps CONTEXT.md and 21-UI-SPEC.md explicitly leave open.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

All 28 decisions D-21-00 through D-21-27 in `.planning/phases/21-media-fold-in-contract-close/21-CONTEXT.md` are AUTHORITATIVE and are not re-derived here. Highlights this research directly extends:

- **D-21-00**: cava go/no-go is RESOLVED TO GO. No spike. The phase opens on the build.
- **D-21-01/03/04**: Live radial 60-bar visualiser replacing the static dashed ring, accent-tinted when live (`14-UI-SPEC.md` amendment required), outline-tinted at silence.
- **D-21-02**: Cover art becomes a hand-authored 12-lobe "Cookie12Sided" scalloped blob path (never a library import).
- **D-21-05/06**: Ring renders on BOTH the Media tab and the bar's `MediaPopout`; cava is a shared, reference-counted process with a short linger, and pinning the count to 1 (always-on) must be reachable as a ONE-KNOB change.
- **D-21-07**: cava's config moves to its own `cava/` stow package.
- **D-21-08..12**: GATE-01 enumeration off the LIVE AGS card; cross-source dedup IN SCOPE; per-player volume (new capability, not parity); any genuine parity gap is built before deletion; `Super+M` opens the dashboard on the Media tab.
- **D-21-13..16**: three orphaned bash scripts deleted with the `ags` package in the SAME commit; `media-art-resolve.sh` STAYS; `test-media-hardening.sh` trimmed + one new check; QMEDIA-03 needs a PERMANENT automated check, not only a sweep.
- **D-21-17..22**: `contract.json` 18→17; `dart-sass` STAYS (comment corrected); comments naming `ags-media` are rewritten, not scrubbed; ONE combined gate (parity + render) unlocks the deletion; `retirement-check` row flips; phase closes on a VERIFIER RUN.
- **D-21-23..25**: LEDGER-06 — reconstruct `16-VERIFICATION.md` as it stood historically; fix the two malformed `coverage:` blocks in place, no validator; close quick task `260728-51j` as already-done.
- **D-21-26/27**: frost unification to one value across dashboard/overview/notifications/OSD; DND tints the whole clock/actions capsule.

### Claude's Discretion

- Exact linger duration for D-21-06 (UI-SPEC recommends 5000ms, `Design.cavaLingerMs`).
- Bar geometry inside the ring (UI-SPEC provides concrete recommended values, all render-gate-adjustable).
- Exact lobe depth/corner rounding of the 12-lobe path.
- cava's `framerate` in the new config (AGS used 60).
- Whether D-21-16's listener-count check lands in `quickshell-doctor` or `retirement-check` — **this research found the answer: it must land in `quickshell-doctor`, because a stale, now-wrong version of exactly this check already lives there (see § The QMEDIA-03 Standing Check below) and needs repair, not a parallel new home.**
- Exact wording of D-21-19's rewritten comments.
- Exact frost value/fill-threshold pair (D-21-26; UI-SPEC resolves this to a concrete target table, not open).
- D-21-27's tint strength (UI-SPEC recommends 0.28, render-gate adjustable 0.20–0.35).

### Deferred Ideas (OUT OF SCOPE)

Lyrics display, shuffle/repeat transport, per-track dominant-colour re-tinting (permanently excluded), decorative mascot GIFs, the `BackgroundShapes` bokeh layer, a validator for malformed `coverage:` blocks, annotating Phase 16's report with later closures, the OVER-04 frame-rate target (still UNMEASURED, needs an owning phase), remaining `WINDOWS.md` rows.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| QMEDIA-01 | Media tab carries transport, seek, cover art, per-player volume, player switching — full AGS card parity | § Parity Mechanics — exact `MediaTab.qml`/`MediaBackend.qml` line sites for the dropdown, volume row, dedup and per-player volume additions |
| QMEDIA-02 | Audio-reactive visualiser as a ring around shaped cover art | § The cava → QML Streaming Contract, § Shape/Repeater Performance, § Reference-Counted Process Ownership |
| QMEDIA-03 | Exactly one MPRIS reader remains, desktop-wide | § The QMEDIA-03 Standing Check — a pre-existing, currently-FAILING `quickshell-doctor` check must be repaired, not duplicated |
| RETIRE-06 | `ags` removed — package, config, contract entry, template, reload step, layer rules | § The Retirement Mechanics — exact file:line edit sites |
| RETIRE-08 | `contract.json` reaches 18→17, `theme-doctor`/`theme-parity` green, no orphans | § Contract Close Mechanics |
| LEDGER-06 | Phase 16 verification report written, malformed `coverage:` blocks fixed, quick task closed | § LEDGER-06 Mechanics |
</phase_requirements>

## Summary

This phase's hardest technical unknown — whether a live cava stream can feed a Quickshell `Process`/`Shape` pipeline — is not actually open: `cava 0.10.7-1` [VERIFIED: `pacman -Q cava`, this host] is already running (PID 1990) feeding the AGS card, its proven reader (`ags/.config/ags/lib/cava.ts`) is eleven lines of a trivial streaming contract, and Quickshell 0.3.0-2's `Quickshell.Io` module ships exactly the `SplitParser` type the AGS reader's line-based protocol needs [VERIFIED: `/usr/lib/qt6/qml/Quickshell/Io/quickshell-io.qmltypes:282-300`]. Nothing in this repo currently uses `SplitParser` — every existing `Process` in this QML tree uses `StdioCollector` for one-shot reads — so the streaming pattern this phase needs is new to the codebase, not merely unfamiliar to this phase, and the plan must build it from the qmltypes contract directly rather than copying a local precedent.

The second-hardest unknown, process refcounting, has no local precedent either: no `pragma Singleton` file in this tree currently implements claim/release/linger. The closest usable skeleton is `PopoutController.qml`'s existing `dwellTimer`/`graceTimer` pair — a non-repeating `Timer` that re-checks its condition at fire time rather than trusting state captured at start time — which is exactly the shape a linger timer needs and should be copied structurally, not reused directly (UI-SPEC already rules out reusing `Design.popoutDismissGraceMs` itself, correctly, since it is a different-scale value for a different purpose).

The most consequential finding in this research is that **QMEDIA-03's "permanent automated check" already has a home, and that home is currently broken.** `quickshell-doctor` check 9 ("No Quickshell MPRIS writer") already scans `~/.config/quickshell` for any `Quickshell.Services.Mpris` import or `Mpris*` type instantiation and asserts the count is **zero** — a Phase 11-era invariant from before this repo had a media widget at all. Since Phase 18 (D-18-05) repointed `MediaBackend.qml` onto the native `Mpris` singleton, that file legitimately imports `Quickshell.Services.Mpris`, and this check has been silently FAILING on the live tree ever since: a live run on this host confirms `[FAIL] zero Quickshell MPRIS writers (found in 1 file(s))` [VERIFIED: live `quickshell-doctor` run, this session]. D-21-16's discretion point ("does the check land in `quickshell-doctor` or `retirement-check`?") is therefore not a free choice — it must land in `quickshell-doctor`, as a *repair* of check 9's now-obsolete "zero" assertion into an "exactly one" assertion, closing a two-phase-old latent gate failure as part of QMEDIA-03's own delivery.

Retirement mechanics are fully mapped: every file:line site CONTEXT.md names was independently re-verified (`contract.json` line 18, `matugen/config.toml:94-103`, `reload.sh:116-129`, `windowrules.lua:305`/`352`, `install.sh:243-244`/`353`, `stow.sh:20`, `retirement-check:92`, `keybinds.lua`'s `Super+D`/`Super+A`/`Super+O`/`Super+N` precedent block). The `dart-sass` STAYS decision is independently confirmed: `stow.sh:436-464`'s GTK3 seed block calls `theme_engine_compile_gtk3_stylesheets`, which shells out to `sass`, and this path is completely independent of AGS.

One UI-SPEC assumption needs correcting before planning: the DND capsule tint (D-21-27) cannot be implemented by "adding a branch to `BarCapsule.color`'s existing expression" as UI-SPEC's prose implies at the file level — `ClockActionsCapsule.qml` does not set `surfaced: true`, so its current fill is unconditionally `"transparent"` (bare glyphs on wallpaper), not `BarRoles.capsule`. The tint must override `color:` as an instance-level property on `ClockActionsCapsule`'s own `BarCapsule { ... }` root object — legal, ordinary QML, and consistent with "no capsule component may declare its own background Rectangle" (this doesn't add a new Rectangle, it rebinds the existing one's `color` for one instance) — but the planner must not attempt to edit `BarCapsule.qml`'s own shared expression, which would spread the tint to every other bar capsule.

**Primary recommendation:** Build the cava reader as a `Process` + `SplitParser` inside a new `pragma Singleton` (`CavaService.qml` or similar, registered in `modules/dashboard/qmldir` or `modules/` per the both-required `pragma Singleton` + qmldir `singleton` keyword rule this repo enforces everywhere else), copying `PopoutController.qml`'s Timer-based grace/linger *shape* (not its token) for the refcount linger, fix `quickshell-doctor` check 9 in place rather than adding a parallel QMEDIA-03 check, and treat every retirement file:line site named in CONTEXT.md as independently re-confirmed and ready to edit as-is.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| MPRIS state (transport, metadata, volume) | QML shell process (Quickshell native `Mpris` singleton via `MediaBackend.qml`) | — | Already the sole reader since D-18-05; no change |
| cava audio-band amplitude stream | QML shell process (new `Process`+`SplitParser` singleton) | System `cava` binary (subprocess) | The binary already exists and already runs; the QML tier owns lifecycle (claim/release/linger), the binary tier owns the actual audio analysis |
| Cover-art fetch/cache | QML shell process (`MediaBackend.qml`) delegating to `media-art-resolve.sh` subprocess | Filesystem cache (`~/.cache/media-art`) | Unchanged — single-flighted `Process`, security-critical scheme/host allowlist stays in the bash script, not reimplemented in QML |
| Visualiser rendering (ring/bars/cookie mask) | QML shell process (`MediaTab.qml`/`MediaPopout.qml`, `QtQuick.Shapes`+`QtQuick.Effects`) | Compositor (GPU raster via `CurveRenderer`) | Pure presentation; no new subprocess or service needed beyond the amplitude stream above |
| Theme contract / colour propagation | `theme-engine` (bash) → `~/.local/state/theme/*` → QML `Colours.qml` singleton (hot-reload) | matugen (render step only) | Unchanged; this phase only removes `ags.scss`'s entry, adds no new contract file (cava carries no colours per D-21-07) |
| Retirement bookkeeping (`contract.json`, `retirement-check`, doctor registries) | bash tooling (`theme-engine/`, `hypr/.config/hypr/scripts/`) | — | Config-then-package, one commit, WINDOWS #1 precedent |

## Standard Stack

### Core

| Component | Version (installed) | Purpose | Why Standard |
|-----------|---------|---------|--------------|
| cava | 0.10.7-1 | Audio spectrum analyser, ncurses/raw-output streaming | [VERIFIED: `pacman -Q cava`, this host] Already installed, already running (PID 1990), already the proven feed for the AGS card. No alternative considered or needed — D-21-00 already resolves this to GO. |
| Quickshell | 0.3.0-2 | The QML shell toolkit this entire repo is built on | [VERIFIED: `pacman -Q quickshell`, this host] Fixed by the project's own tech stack; `Quickshell.Io.Process`/`SplitParser`/`StdioCollector` all confirmed present in the installed qmltypes. |
| dart-sass | 1.102.0-1 | `sass` binary compiling GTK3 stylesheets | [VERIFIED: `pacman -Q dart-sass`, this host] STAYS (D-21-18) — confirmed independently: `stow.sh:436-464`'s `GTK3_SASS_SEED_FILES=(_motion.scss)` block invokes `theme_engine_compile_gtk3_stylesheets`, which requires the `sass` binary, with no dependency on AGS at all. |

No new external packages are installed by this phase. `cava/` becomes a new **stow config package** (D-21-07) — a directory of dotfiles, not a binary — so no package-legitimacy check applies to it.

### Package Legitimacy Audit

No new packages this phase installs (RETIRE-06 REMOVES `aylurs-gtk-shell`; `cava` and `dart-sass` are already-installed official-repo packages that stay). Package-legitimacy gate is not applicable in the npm/pypi/crates sense — this is a pacman/AUR ecosystem and every package this phase touches was already verified at prior phases (`cava`/`dart-sass` at Phase 10, `aylurs-gtk-shell` at Phase 10). Direct re-verification this session:

| Package | Registry | Disposition | Evidence |
|---------|----------|-------------|----------|
| cava | pacman (`extra`) | STAYS | [VERIFIED: `pacman -Q cava` → `cava 0.10.7-1`, this host] |
| dart-sass | pacman (`extra`) | STAYS | [VERIFIED: `pacman -Q dart-sass` → `dart-sass 1.102.0-1`, this host] |
| aylurs-gtk-shell | AUR | REMOVED | [VERIFIED: `pacman -Q aylurs-gtk-shell` → `aylurs-gtk-shell 3.1.2-1` (currently installed, to be removed), `install.sh:353`] |

**Packages removed due to SLOP/SUS verdict:** none — this is a planned retirement of a legitimate, already-vetted package, not a hallucination finding.

## Architecture Patterns

### System Architecture Diagram

```
                    ┌─────────────────────────────────────┐
                    │   cava (system binary, /usr/bin/cava) │
                    │   cava -p <cava/config> → stdout       │
                    │   one line/frame, ';'-delimited ascii  │
                    └───────────────┬─────────────────────┘
                                    │ (spawned/killed by refcount)
                                    ▼
     ┌──────────────────────────────────────────────────────────┐
     │  NEW: CavaService.qml (pragma Singleton)                  │
     │  Process { command: ["cava","-p",CONFIG]                  │
     │            stdout: SplitParser { splitMarker: "\n"        │
     │                     onRead: (line) => parse+publish } }   │
     │  claim()/release() refcount + linger Timer (D-21-06)      │
     │  exposes: readonly property var bars: []  (0..1 per band) │
     └───────────┬───────────────────────────┬──────────────────┘
                 │ claim() on visible          │ claim() on visible
                 ▼                             ▼
     ┌───────────────────────┐     ┌───────────────────────────┐
     │  MediaTab.qml           │     │  MediaPopout.qml            │
     │  Repeater of ShapePath   │     │  (NEW: gains its own ring   │
     │  bars around cookie-      │     │   + cookie mask — currently │
     │  masked cover art          │     │   has neither)               │
     └───────────────────────┘     └───────────────────────────┘

     ┌──────────────────────────────────────────────────────────┐
     │  MediaBackend.qml (Scope singleton, unchanged reader)      │
     │  Quickshell.Services.Mpris → players/activePlayer/…        │
     │  + NEW: setVolumeForPlayer(id, fraction) for D-21-10        │
     │  + NEW: dedup pass over Mpris.players.values for D-21-09    │
     └──────────────────────────────────────────────────────────┘
                    │ single-flighted subprocess (unchanged)
                    ▼
     ┌──────────────────────────────────────────────────────────┐
     │  media-art-resolve.sh (RETAINED, D-21-14)                  │
     │  scheme allowlist + loopback/RFC1918 pre-flight rejection   │
     └──────────────────────────────────────────────────────────┘
```

### Recommended Project Structure

```
quickshell/.config/quickshell/modules/dashboard/
├── MediaTab.qml            # existing — Repeater replaces single ShapePath (lines 525-551)
├── MediaBackend.qml         # existing — gains setVolumeForPlayer(), dedup projection
├── CavaService.qml          # NEW — pragma Singleton, refcount+linger, Process+SplitParser
modules/bar/
├── MediaPopout.qml           # existing — gains cookie mask + ring (currently has neither)
cava/.config/cava/config      # NEW stow package — bars/framerate/output settings (D-21-07)
```

### Pattern 1: cava streaming via `Process` + `SplitParser`

**What:** Line-buffered subprocess output, one JS callback per complete line, blank/partial lines ignored.
**When to use:** Any continuous line-oriented subprocess stream (this is the only such case in this repo today).
**The proven AGS contract this must mirror exactly** [VERIFIED: `ags/.config/ags/lib/cava.ts:1-21`, read in full this session]:

```typescript
// ags/.config/ags/lib/cava.ts — the ENTIRE file, quoted verbatim
import GLib from "gi://GLib"
import { subprocess } from "ags/process"
import { createState } from "ags"

const CONFIG = `${GLib.get_home_dir()}/.config/ags/cava/config`

export const [bars, setBars] = createState<number[]>([])

subprocess(["cava", "-p", CONFIG], (line) => {
  const vals = line
    .split(";")
    .filter((s) => s.length)
    .map((s) => Number(s) / 100)
  if (vals.length) setBars(vals)
})
```

**The exact cava config it reads** [VERIFIED: `ags/.config/ags/cava/config`, read in full this session — this is the file D-21-07 moves into the new `cava/` stow package]:

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

Note: this config has **no `[input]` section** — cava falls back to its own autodetected default input backend on this host, and it is confirmed working live (PID 1990 has been running against this exact config with no `[input]` block). `bar_delimiter = 59` is the ASCII codepoint for `;` — this is what the AGS reader's `.split(";")` depends on; do not change one without the other. `bars = 24` here is the AGS-era value; D-21-03 locks the QML version to **60** — this requires either a new `bars = 60` value in the new `cava/config` (recommended, matches D-21-07's move to a fresh file) or a `--config` argv override; a fresh file is simpler and matches the pattern this repo uses elsewhere (config file over inline argv, per D-21-07's own rejected-alternative note).

**Confirmed Quickshell 0.3.0-2 API contract** [VERIFIED: `/usr/lib/qt6/qml/Quickshell/Io/quickshell-io.qmltypes`, read this session]:

- `SplitParser` exists (`quickshell-io.qmltypes:282-300`), prototype `DataStreamParser`, exposes `property string splitMarker` (default is the type's own line-split behaviour; set explicitly to `"\n"`).
- `DataStreamParser` (the `SplitParser`/`StdioCollector` base, `:32-46`) declares exactly one signal: `read(string data)` — this is the callback surface, analogous to AGS's `subprocess(cmd, (line) => ...)` second argument.
- `Process` (`:47-...`) exposes `running` (bool, settable — this is the claim/release lifecycle hook), `command` (string list), `stdout`/`stderr` as `DataStreamParser`-typed properties.
- **No `SplitParser` usage exists anywhere in this repo today** [VERIFIED: `rg -n "SplitParser" -g '*.qml' .` over the whole `quickshell/.config/quickshell/` tree returned zero hits, this session] — every existing `Process` (31 call sites checked) uses `StdioCollector` for one-shot reads (`MediaBackend.qml:294-311`'s art resolver is the closest local precedent for the `Process` lifecycle shape, but its `stdout` is a `StdioCollector`, not a `SplitParser`, because it is a run-once command, not a stream). Build this from the qmltypes contract directly.

**Recommended QML shape** (not tested this session — derived from the confirmed API surface above, following this repo's own `Process` conventions at `MediaBackend.qml:294-311`):

```qml
// Illustrative shape, not verified running — combine with the linger
// pattern in § Reference-Counted Process Ownership below.
Process {
    id: cavaProcess
    running: false
    command: [root.cavaBinaryPath, "-p", root.cavaConfigPath]
    stdout: SplitParser {
        splitMarker: "\n"
        onRead: (line) => {
            const vals = line.split(";").filter(s => s.length > 0).map(s => Number(s) / 100);
            if (vals.length > 0)
                root.bars = vals;
            // blank/partial lines: vals.length === 0, silently ignored,
            // last-good root.bars value stays — mirrors ags/lib/cava.ts exactly.
        }
    }
}
```

### Pattern 2: Reference-Counted Process Ownership (no local precedent — build from scratch)

**What:** A shared singleton exposing `claim()`/`release()`, an internal counter, and a linger `Timer` that only actually kills the process after a grace period with the counter still at zero.
**When to use:** D-21-06's cava lifecycle — exactly one instance needed here.

**No refcount/claim pattern exists anywhere in this QML tree** [VERIFIED: searched all 16 `pragma Singleton` files (`Colours.qml`, `Motion.qml`, `Design.qml`, `BarRoles.qml`, `BarReveal.qml`, `BarEntryModel.qml`, `BrightnessBackend.qml`, `PopoutController.qml`, `ToggleState.qml`, `NotifServer.qml`, `WeatherPalette.qml`, `NotifMarkdown.qml`, `WeatherTab.qml`, `QuickToggles.qml`, `DashboardTab.qml`, `PerformanceTab.qml` — none implement a counter+grace-timer ownership model]. The closest usable **shape** (not a refcount, but the same "non-repeating Timer, re-check condition at fire time" idiom this needs) is `PopoutController.qml`'s existing dwell/grace pair [VERIFIED: `modules/bar/PopoutController.qml:180-205`, read this session]:

```qml
// PopoutController.qml:195-205 — the grace-timer SHAPE to mirror
// (not the token: Design.popoutDismissGraceMs is a different-scale,
// different-purpose value per 21-UI-SPEC.md's own correct call-out —
// mirror the STRUCTURE, not the constant).
Timer {
    id: graceTimer
    interval: Design.popoutDismissGraceMs
    repeat: false
    running: false
    onTriggered: {
        // Re-check the live condition at fire time, not the condition
        // captured when the timer was armed — the state can have
        // changed during the wait.
        if (root.combinedHovered || root.pinnedSection !== "")
            return;
        root.close();
    }
}
```

**Recommended minimal shape for `CavaService.qml`**, following this repo's both-required singleton rule (`pragma Singleton` in the source file AND the `singleton` keyword in the owning `qmldir` — confirmed the ONLY way a bare `TypeName.property` reference resolves in this codebase; omitting either yields `undefined` forever with no load error [VERIFIED: `modules/qmldir`, `modules/bar/qmldir`, `modules/dashboard/qmldir` headers, all independently document this same 12-06 finding]):

```qml
// CavaService.qml — illustrative shape, not verified running.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root
    property int _claimCount: 0
    readonly property var bars: cavaProcess.running ? _bars : []
    property var _bars: []

    function claim() {
        root._claimCount++;
        lingerTimer.stop();  // cancel any pending kill
        if (!cavaProcess.running)
            cavaProcess.running = true;
    }
    function release() {
        root._claimCount = Math.max(0, root._claimCount - 1);
        if (root._claimCount === 0)
            lingerTimer.restart();
    }

    // D-21-06's ONE-KNOB always-on escape valve: set this true (or set
    // Design.cavaLingerMs to an enormous value) and lingerTimer never
    // actually kills the process — no refcount restructuring needed.
    property bool alwaysOn: false

    Timer {
        id: lingerTimer
        interval: Design.cavaLingerMs   // 21-UI-SPEC.md recommends 5000
        repeat: false
        running: false
        onTriggered: {
            if (root.alwaysOn || root._claimCount > 0)
                return;  // re-checked at fire time, not arm time
            cavaProcess.running = false;
        }
    }

    Process { id: cavaProcess /* ... command + SplitParser as above ... */ }
}
```

Register in `modules/dashboard/qmldir` (or `modules/qmldir` if consumed from `MediaPopout.qml` in `modules/bar/` too — cross-directory singleton access needs the registration to live somewhere both `import` paths reach; `Colours`/`Motion` at the top-level `modules/qmldir` are the precedent for a singleton consumed from both `dashboard/` and `bar/`) with `singleton CavaService 1.0 CavaService.qml`.

**Claim/release trigger (D-21-06 + UI-SPEC's operator-resolved appendix):** claim on `visible` (Media tab is the active dashboard tab AND dashboard is open; OR the bar's `MediaPopout` is open), release on hidden ONLY — never on pause. This is already resolved in `21-UI-SPEC.md`'s Appendix and is not re-litigated here.

### Pattern 3: Shape/Repeater at 60 bars — no `Canvas` needed

**What:** `MediaTab.qml:525-551`'s existing single `Shape`/`ShapePath`/`PathAngleArc` [VERIFIED: read in full this session] becomes a `Repeater` of `ShapePath` line segments, one per bar, matching Caelestia's "clock hand" construction (per UI-SPEC's own resolved geometry section) rather than a single arc.
**Established fact:** the file already declares `preferredRendererType: Shape.CurveRenderer` and already imports `QtQuick.Shapes` — this is not new machinery, it is the existing `Shape` extended with a `Repeater` as its content. Given `colour-lint` (GATE-04)'s deny-by-default hex/literal discipline (confirmed folded into `theme-doctor`, see § The Gates below) and `Motion.qml`'s existing `Behavior on strokeColor` idiom already present at `MediaTab.qml:560-567` for the ring's colour transition, the 60-bar `Repeater`'s per-bar `ShapePath` should reuse the identical `Behavior on strokeColor` pattern (already resolved in UI-SPEC's Visualiser Geometry table) rather than invent a new animation path. **One `Shape` containing 60 `ShapePath`s (via `Repeater`)** is the correct answer — not 60 separate `Shape` items (unnecessary per-item overhead) and not a `Canvas` (this repo has zero `Canvas` usage anywhere and `Shape`'s `CurveRenderer` already GPU-accelerates the existing ring with no reported performance issue across 5 render-gate rounds).

### Anti-Patterns to Avoid

- **Re-fetching the resolved album art URL from `MediaPopout.qml`:** that file's own header already documents the trust boundary — it reads only `MediaBackend.artPath` (the resolved path), never `trackArtUrl` directly, and must keep doing so when the cookie mask is added there.
- **Editing `BarCapsule.qml`'s shared `color:` expression to add the DND branch:** this is shared chrome for every bar capsule; the DND tint is `ClockActionsCapsule`-specific and must override `color:` at the instance level (`BarCapsule { id: clockActionsCapsule; color: ... }`), not at the shared component definition. See § DND Capsule Tint Mechanics below.
- **Reusing `Design.popoutDismissGraceMs`/`Design.barDrawerGraceMs` for the cava linger:** UI-SPEC already correctly rejects this (different scale, different purpose) — mint `Design.cavaLingerMs` as a new named constant.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Line-buffered subprocess parsing | Manual buffer/split logic on `StdioCollector`'s `text` property | `SplitParser` (`Quickshell.Io`) | Purpose-built for exactly this; confirmed present in the installed qmltypes, zero reason to reimplement line-splitting on top of a one-shot collector |
| MPRIS reading (any surface) | A second `Mpris`-import site, a second bash reader | `MediaBackend.qml`'s existing singleton projection | This is QMEDIA-03's entire point — a second reader is the bug this phase closes, not a pattern to repeat |
| SSRF-safe art fetching | Re-implement scheme/host validation in QML | `media-art-resolve.sh` (RETAINED, D-21-14) | Carries the scheme allowlist and loopback/RFC1918 pre-flight rejection already; re-implementing in QML would discard proven security discipline |
| Cookie/blob shape geometry | Search for an `M3Shapes`/`Caelestia.Config` import | Hand-authored `ShapePath` of arcs (D-21-02, already locked) | No such library exists in this repo; the decision is already made, this is a reminder not to go looking for one |

**Key insight:** almost nothing in this phase's mechanics needs a new library — the gap is entirely "assemble primitives (`Process`, `SplitParser`, `Singleton`, `Timer`, `Shape`/`Repeater`) this repo already has installed but has never combined in exactly this shape before."

## The cava → QML Streaming Contract (detailed)

See § Pattern 1 above for the full verified contract. Summary of what changes and what doesn't between the AGS reader and the QML one:

| Aspect | AGS (`ags/lib/cava.ts`) | QML (new `CavaService.qml`) |
|--------|--------------------------|------------------------------|
| Spawn | `subprocess(["cava","-p",CONFIG], cb)` | `Process { command: [...]; running: true }` |
| Line callback | 2nd arg to `subprocess()` | `SplitParser.onRead(data)` |
| Split | `.split(";")` | identical — `.split(";")` on the `data` string |
| Blank/partial handling | `.filter(s => s.length)`, skip publish if empty | identical logic, same skip-if-empty rule |
| Normalisation | `Number(s) / 100` | identical |
| Config path | `~/.config/ags/cava/config` | `~/.config/cava/config` (new stow package, D-21-07) |
| Bar count | 24 (`ags/cava/config`) | 60 (D-21-03; new config file needs `bars = 60`) |
| Lifecycle | permanent (AGS daemon always running) | refcounted, claim/release/linger (D-21-06) |

**Not yet measured this session, flagged for the plan's own verification step:** whether `bars = 60` at `framerate = 60` changes cava's own CPU/latency profile meaningfully beyond CONTEXT.md's already-recorded 60-bar measurement (1.20% of one core / 14.0 MB RSS / ~350ms cold start — this is CONTEXT.md's own D-21-00 finding, already measured at 60 bars on this host, so no further measurement is needed here).

## The QMEDIA-03 Standing Check (critical finding)

`quickshell-doctor` already contains a check for MPRIS surface usage across the QML tree — **it currently asserts the wrong invariant and is currently failing.**

[VERIFIED: `hypr/.config/hypr/scripts/quickshell-doctor:2867-2883`, read in full this session]

```bash
# ── 9. No Quickshell MPRIS writer (QS-06 / standing constraint 4) —
#    Phase 11 ships no media widget so this asserts a zero that must
#    stay zero; a third *reader* of MPRIS is safe, a third uncoordinated
#    *writer* is not. ─────────────────────────────────────────────────
if [[ -d "$QUICKSHELL_CONFIG_DIR" ]]; then
    MPRIS_HITS=0
    while IFS= read -r f; do
        grep -qE 'import[[:space:]]+Quickshell\.Services\.Mpris|\bMpris[A-Za-z]*[[:space:]]*\{' "$f" 2>/dev/null && MPRIS_HITS=$((MPRIS_HITS + 1))
    done < <(find -L "$QUICKSHELL_CONFIG_DIR" -type f 2>/dev/null)
    check "zero Quickshell MPRIS writers (found in ${MPRIS_HITS} file(s) under $QUICKSHELL_CONFIG_DIR)" "$([[ "$MPRIS_HITS" -eq 0 ]] && echo 0 || echo 1)"
```

**Live confirmation this session** [VERIFIED: `bash hypr/.config/hypr/scripts/quickshell-doctor --no-summon --no-headless-output --no-panel-checks` run on this host]:

```
[FAIL] zero Quickshell MPRIS writers (found in 1 file(s) under /home/aorus/.config/quickshell)
```

Overall gate result: **18 passed, 2 failed** — the MPRIS check above and one unrelated pre-existing `permissions-allowlist-paths-resolve` failure (out of scope for this phase).

**Why this is failing:** the check was written in Phase 11, before this repo had any media widget. D-18-05 (Phase 18) legitimately repointed `MediaBackend.qml` onto the native `Quickshell.Services.Mpris` singleton — a correct, intended change — but this check's "zero" assertion was never updated to account for it. It has been silently red since Phase 18 landed.

**What this means for D-21-16:** the phase's "Claude's Discretion" question — does the permanent listener-count check land in `quickshell-doctor` or `retirement-check`? — is not actually open. It must land in `quickshell-doctor`, as a **repair** of check 9, changing its assertion from `MPRIS_HITS -eq 0` to `MPRIS_HITS -eq 1` (or, more precisely, changing the regex/count to distinguish legitimate *reader* sites from a hypothetical second reader — the check's own name and comment need rewriting too, since "No Quickshell MPRIS writer" was never actually the right framing even in Phase 11: `MediaBackend.qml` is a reader, not a writer, and the two-phase-old comment already conflates the two). This closes a real, currently-red gate as part of delivering QMEDIA-03, not merely as a bonus.

Recommended new assertion shape (illustrative, to be adapted to the actual regex needs — e.g. excluding `MediaPopout.qml`/`MediaTab.qml`, which will consume `MediaBackend.qml`'s already-read state but must not themselves gain a second `Quickshell.Services.Mpris` import):

```bash
# Repaired check 9 — asserts EXACTLY ONE Mpris reader (QMEDIA-03), not zero.
check "exactly one Quickshell MPRIS reader (found in ${MPRIS_HITS} file(s), expect 1: MediaBackend.qml)" \
    "$([[ "$MPRIS_HITS" -eq 1 ]] && echo 0 || echo 1)"
```

The before/after retirement-check sweep (also required per D-21-16's reconciliation clause) is a separate, one-time proof and does not replace this repair — both must happen, per CONTEXT.md's own resolution.

## Reference-Counted Process Ownership — see Pattern 2 above

(Full detail already given in § Architecture Patterns to avoid duplication.)

## Shape/Repeater Performance at 60 Bars — see Pattern 3 above

(Full detail already given in § Architecture Patterns.)

## Parity Mechanics (QMEDIA-01)

Exact edit sites, verified this session by reading the files directly:

- **Player-switcher dropdown** — `MediaTab.qml:824-899` [VERIFIED, read this session]. Each `Repeater` delegate row (`:858-896`) currently renders a checkmark + elided label only. D-21-10's per-player mini-slider and D-21-09's dedup both extend this exact block. The row's existing `MouseArea` (`:887-895`) selects the player on click — a new mini-slider `MouseArea`/drag surface must NOT propagate into this click handler (UI-SPEC already specifies this).
- **Bottom volume row** — `MediaTab.qml:1281-1335` [VERIFIED, read this session]. Stays wired to `mediaBackend.setVolume()`/`volumeLevel` (the active-player-only path) — UNCHANGED per UI-SPEC's resolution; this is the parity baseline, not touched by the new per-player capability.
- **`MediaBackend.qml`'s mutator surface** [VERIFIED: full file read this session] — `setVolume(fraction)` (`:355-360`) stays for the active-player path. D-21-10 needs one **new** function, `setVolumeForPlayer(playerId, fraction)`, following the identical clamped-write pattern but resolving the target player from `Mpris.players.values` by id instead of using `activePlayer`. `players` (`:145-160`) is the existing switcher data-source projection — the dedup pass (D-21-09) must modify this computed property's loop to collapse recognised duplicate perceptual sources before the array is built, not filter after the fact (so `activePlayerId`/`selectPlayer` resolution logic, which also walks `Mpris.players.values` directly at `:108-121`/`:129-139`, stays consistent with what the switcher displays).
- **`MediaPopout.qml`** [VERIFIED: full file read this session] currently has NO cookie mask and NO ring at all — its art (`:81-91`) is a plain `Image` with `fillMode: Image.PreserveAspectCrop`, no `MultiEffect` mask. D-21-05 requires both to be added here; this is new code in this file, not an extension of existing masking/ring code (unlike `MediaTab.qml`, which already has both a mask, at `:642-660`, and a ring, at `:525-551`).
- **The `MultiEffect` mask mechanism** [VERIFIED: `MediaTab.qml:571-660`, read in full this session, including the round-4 fix commentary] — `artMaskShape` (a `Rectangle`, `visible: false`, `layer.enabled: true` — **this `layer.enabled: true` is load-bearing**, proven by a documented live bug where omitting it produced an empty mask) feeds `MultiEffect.maskSource`. D-21-02 changes `artMaskShape` from a `radius: width/2` circle to the hand-authored 12-lobe `ShapePath`; the `layer.enabled: true` requirement carries over unchanged (any `Item`/`Shape` used as a mask source needs it, not just a `Rectangle`).

## Reference-Shell Keybind Mechanics (D-21-12, `Super+M`)

Exact wiring confirmed this session:

- **`hypr/.config/hypr/config/keybinds.lua`** — the precedent block (`:205-233`, read this session) shows the exact idiom every prior surface shortcut follows: `hl.bind(mainMod .. " + <LETTER>", hl.dsp.global("quickshell:<name>")) -- <comment>`. `M` is confirmed free (CONTEXT.md's own audit; not independently re-derived here since it's a simple exclusion check already done).
- **`quickshell/.config/quickshell/shortcuts.json`** [VERIFIED: full file read this session] — the manifest `keybind-doctor` cross-checks against. New entry needed: `{ "appid": "quickshell", "name": "media", "chord": { "mods": "SUPER", "key": "M" }, "description": "..." }`, following the exact shape of the `dashboard`/`audio-panel`/`overview`/`notif-centre` entries already there.
- **`shell.qml`'s tab-open wiring** [VERIFIED: `shell.qml:39-41,313,324,395-415`; `Dashboard.qml:249-286`, both read this session] — `root.dashboardTabIndex` (declared `shell.qml:41`) is the property that seeds `Dashboard { initialTabIndex: root.dashboardTabIndex }` on summon (`:313`) and is written back on every tab change (`:324`, `onTabSelected`). The **exact existing precedent** for "open the dashboard on a specific tab" is `shell.qml:411-415`'s `onDashboardRequested` handler used by bar popouts' wayfinding links:

```qml
// shell.qml:412-415 — the exact pattern to mirror for the new GlobalShortcut
onDashboardRequested: (tabIndex) => {
    root.dashboardTabIndex = tabIndex;
    dashboardLoader.active = true;
}
```

  The new `GlobalShortcut` for `Super+M` should set `root.dashboardTabIndex = 1` (Dashboard's `tabIndexMedia`, fixed at `Dashboard.qml:255` [VERIFIED, read this session: `readonly property int tabIndexMedia: 1`, part of the fixed order comment "Dashboard, Media, Performance, Weather" at `:253`]) and open the loader — following `dashboardShortcut`'s own existing toggle-with-fullscreen-guard shape (`shell.qml:933-949`, read this session) is the closest sibling precedent, though CONTEXT.md does not specify whether `Super+M` should toggle-close an already-open drawer or only ever open-to-Media; this is a small open call left for the plan (recommend mirroring `dashboardShortcut`'s toggle behavior but forcing the tab index, since D-21-12's own text says "opens the dashboard directly on the Media tab" without describing close behaviour).

## Retirement Mechanics (RETIRE-06) — Every Edit Site, Re-Verified

All file:line sites below were independently re-opened and re-read this session (not merely copied from CONTEXT.md):

| File | Lines | What | Verified Content |
|------|-------|------|-------------------|
| `theme-engine/.config/theme-engine/contract.json` | 18 | `ags.scss`/`scss-vars` entry | `{ "name": "ags.scss", "format": "scss-vars" }` — one of 18 `files` entries; `_motion.scss` (line 20) is the second `scss-vars` entry, so removing line 18 leaves the format family represented, 18→17 |
| `matugen/.config/matugen/config.toml` | 94-103 | `[templates.ags]` block + its 10-line comment | Comment block (94-100) + `[templates.ags]` (101) + `input_path`/`output_path` (102-103) — full 10-line span to delete |
| `theme-engine/.config/theme-engine/lib/reload.sh` | 116-129 | `ags list`/`ags request reload-css` fan-out step | `if command -v ags >/dev/null 2>&1 && ags list 2>/dev/null \| grep -qx 'media'; then ags request -i media reload-css 2>/dev/null \|\| true; fi` (114-line comment block above it also goes) |
| `theme-engine/.config/theme-engine/theme-parity` | ~239 | comment naming `ags.scss` as the `scss-vars` example | in the CHECK-format comment block, `scss-vars (ags.scss, D-29 gap closure)` — rewrite per D-21-19 |
| `theme-engine/.config/theme-engine/theme-stress-test` | 315 | `REPRESENTATIVE_FILES` | `(hyprland-tokens.lua gtk-4.0-colors.css kitty.conf)` — confirmed `ags.scss` is NOT a member; no stress-test trap here, unlike `wleave.css` |
| `hypr/.config/hypr/config/windowrules.lua` | 305, 352 | the two real `ags-media` layer rules | `hl.layer_rule({ match = { namespace = "ags-media" }, blur = true })` (305) and `hl.layer_rule({ match = { namespace = "ags-media" }, ignore_alpha = 0.25 })` (352) — DELETE both |
| `hypr/.config/hypr/config/windowrules.lua` | 228, 278, 295, 301, 418, 461, 465, 527 | comments naming `ags-media` | REWRITE per D-21-19 (findings survive, surface name goes — see below) |
| `hypr/.config/hypr/config/autostart.lua` | 164-165 | AGS autostart + comment | `hl.exec_cmd("uwsm app -- ags run --directory ~/.config/ags")` (165), preceded by a comment naming `toggle-media` (164) — DELETE both |
| `install.sh` | 238-244 | `cava`/`dart-sass` block with incorrect AGS-only comment | `cava` (243) STAYS, `dart-sass` (244) STAYS, comment (238-242, currently reads "the sass binary AGS invokes... without it ags run aborts") gets REWRITTEN per D-21-18 |
| `install.sh` | 349-353 | AGS AUR package | `aylurs-gtk-shell` (353) — REMOVE, plus its comment (349-352) |
| `stow.sh` | 20 | `ags` stow package | REMOVE from `PACKAGES=(...)` array |
| `stow.sh` | 417-464 | GTK3 sass seed block | STAYS UNCHANGED — confirmed this is the independent proof `dart-sass` is not AGS-only: `GTK3_SASS_SEED_FILES=(_motion.scss)`, calls `theme_engine_compile_gtk3_stylesheets`, zero AGS reference anywhere in this block |
| `hypr/.config/hypr/scripts/retirement-check` | 92 | registry row | `ags|pending|ags/|RETIRE-06` → flip `pending` to `retired` |
| `hypr/.config/hypr/scripts/media-status.sh`, `media-players.sh`, `media-player.py` | whole files | orphaned scripts | DELETE — confirmed zero real (non-`.planning`/non-docs) consumers outside `ags/lib/media.ts` and each other for the first two; `media-player.py` has ZERO consumers anywhere including `.planning` docs beyond historical mentions |
| `hypr/.config/hypr/scripts/media-art-resolve.sh` | whole file | RETAINED | confirmed real consumer: `MediaBackend.qml:242,284` (builds the path by string concatenation, `root.artResolverPath + url` argv) |

## Retirement Comment Rewrite Sites (D-21-19)

`windowrules.lua`'s `ags-media` comment mentions [VERIFIED: `grep -n ags windowrules.lua`, this session, exact lines confirmed]:

- `:228` — "the same finding the ags-media rule below already relies on" (GTK4 layer-shell opaque-background-by-default finding)
- `:278` — "the failure mode this file already records twice (ags-media 10-06c, wleave 09-03)" (translucency-without-blur reads as raw unblurred transparency)
- `:295` — "not another boolean" (blur-strength-is-global finding, cites both ags-media and wleave)
- `:301,303` — the rule's own preceding comment block, directly above the two real rules being deleted
- `:418` — "the wleave/ags-media pattern" (consistency-across-surfaces finding)
- `:461,465` — the ignore_alpha unlocking-the-range finding, cites ags-media's own precedent
- `:527` — cites "ags-media ignore_alpha rule's FILE-LEVEL FINDING comment"

Per D-21-19: these findings are load-bearing (they explain WHY several *live, still-existing* surfaces carry the alpha values they do) and must be REWRITTEN to state the finding on its own terms rather than scrubbed, e.g. replacing "the ags-media rule below already relies on" with a direct restatement of the GTK4-layer-shell-opaque-background finding itself, with no dangling reference to a rule that no longer exists two lines below it.

## DND Capsule Tint Mechanics (D-21-27) — UI-SPEC Correction

**Finding: `21-UI-SPEC.md`'s framing needs one correction before planning.** UI-SPEC states the DND tint extends "`BarCapsule.color`, the shared `!surfaced ? "transparent" : (hovered ? capsuleHover : capsule)` expression" with "one additional branch specific to this capsule." This is technically accurate as a description of the shared expression, but it elides a fact the plan needs to know:

[VERIFIED: `grep -n "surfaced:" ClockActionsCapsule.qml` this session returned **zero matches**] — `ClockActionsCapsule.qml` never sets `surfaced: true`. `BarCapsule.qml:69` [VERIFIED, read this session] declares `property bool surfaced: false` as the default, and its own header comment (`:49-68`) states explicitly: *"the surfaced set is the CENTRE WORKSPACE capsule and the CENTRE IDLE-INHIBITOR bulb, and nothing else — every other capsule is bare glyphs directly on the wallpaper."* `ClockActionsCapsule` is not in that set.

**Consequence:** `ClockActionsCapsule`'s current, non-DND fill is unconditionally `"transparent"` (`BarCapsule.qml:79`'s `!surfaced` branch) — bare glyphs on the wallpaper, not `BarRoles.capsule`. The DND tint therefore cannot simply "add a branch inside `capsule`/`capsuleHover`'s selection" — it needs a branch that fires **regardless of `surfaced`**, since the capsule is normally transparent, not normally `capsule`-filled.

**Correct implementation site:** override `color:` at the **instance level**, on `ClockActionsCapsule.qml`'s own `BarCapsule { id: clockActionsCapsule, ... }` root object (confirmed the file's own root type at `ClockActionsCapsule.qml:42` [VERIFIED, read this session]) — this is ordinary, legal QML (an instance rebinding a property its base type also binds) and does NOT violate `BarCapsule.qml`'s "no capsule component may declare its own background Rectangle" rule (that rule is about not adding a SECOND Rectangle; this rebinds the color of the one Rectangle that already exists):

```qml
// ClockActionsCapsule.qml — illustrative addition at the BarCapsule { ... }
// root level, NOT inside BarCapsule.qml itself.
BarCapsule {
    id: clockActionsCapsule
    capsuleId: "clockActions"
    // surfaced stays false (unchanged) — the DND tint overrides color
    // directly rather than routing through the surfaced/hovered branches,
    // since this capsule is normally transparent, not normally BarRoles.capsule.
    color: notificationSource.dndActive
        ? BarRoles.dndSurface
        : (!clockActionsCapsule.surfaced ? "transparent" : (clockActionsCapsule.hovered ? BarRoles.capsuleHover : BarRoles.capsule))
    // ... existing contentGap etc. unchanged
}
```

`notificationSource.dndActive` already exists (`ClockActionsCapsule.qml:621`, reads `NotifServer.dnd` — [VERIFIED, read this session]). The `Behavior on color` animation (`BarCapsule.qml:81-88`, `Motion.standardDuration`/`standardEasing`) is inherited automatically since it's declared on the same `color` property this override targets — no separate animation needs adding.

`BarRoles.dndSurface`/`dndSurfaceFg` — confirmed the exact blend idiom to copy is `BarRoles.qml`'s existing `Qt.rgba(root.surfaceColour.r, ..., alpha)` pattern (e.g. `barSurface` at the file's own "Surfaces" section) [VERIFIED, full `BarRoles.qml` read this session] — the file's own header explicitly documents WHY the color-typed-property indirection (`readonly property color surfaceColour: Colours.surface`) is required before blending: `Colours.*` are `property string` (hex strings from JSON), and `Qt.rgba(undefined.r, ...)` silently yields opaque BLACK with no error — this bit the team once already (recorded as a real GATE-02 defect in `18.1-VERIFICATION.md`). UI-SPEC's recommended `dndSurface`/`dndSurfaceFg` tokens already follow this pattern correctly; no correction needed there, only in the consuming-file wiring above.

## Contract Close Mechanics (RETIRE-08)

The Gates — invocation syntax and known traps, confirmed this session:

| Gate | Invocation | Notes |
|------|-----------|-------|
| `theme-doctor` | `bash theme-engine/.config/theme-engine/theme-doctor` (no args) | [VERIFIED: header read] Folds in `colour-lint` at `theme-doctor:520-547` — runs `$HOME/.config/hypr/scripts/colour-lint` and reparses its `[PASS]`/`[FAIL]` lines into its own `check` calls; a colour-lint `[SKIP]` (script not found/executable) is a real skip, not a pass |
| `theme-parity` | `bash theme-engine/.config/theme-engine/theme-parity [target]` | [VERIFIED: usage line at `:9`] `target` optional — omit for all 7 |
| `theme-stress-test` | `bash theme-engine/.config/theme-engine/theme-stress-test [--switches N] [--gap S]` | [VERIFIED: usage line at `:9`] `REPRESENTATIVE_FILES=(hyprland-tokens.lua gtk-4.0-colors.css kitty.conf)` confirmed NOT to include `ags.scss` — no `wleave.css`-class stress-test trap |
| `colour-lint` (GATE-04) | `bash hypr/.config/hypr/scripts/colour-lint` (regular), `--self-test` (fixture replay) | [VERIFIED: located at `hypr/.config/hypr/scripts/colour-lint`, not under `theme-engine/`] Folded into `theme-doctor`, but independently runnable |
| `retirement-check` | `bash hypr/.config/hypr/scripts/retirement-check ags` (single surface) or `--all` | [VERIFIED: CLI dispatch read at file tail] `--self-test` also available |
| `quickshell-doctor` | `bash hypr/.config/hypr/scripts/quickshell-doctor [--no-summon] [--no-headless-output] [--no-panel-checks] [--with-compositor-reload] [--self-test]` | [VERIFIED: usage line at `:50`] Live run this session: 18 passed, 2 failed (1 pre-existing MPRIS gap this phase must close, 1 unrelated pre-existing permissions gap out of scope) |
| `keybind-doctor` | `bash hypr/.config/hypr/scripts/keybind-doctor` | needed for the new `Super+M` bind's manifest cross-check |

**The known `pipefail + grep -q` trap** [VERIFIED: multiple prior plan `<verify>` blocks and `quickshell-doctor:1697`'s own comment, this session]: under `set -uo pipefail`, `producer | grep -q pattern` can exit 141 (SIGPIPE) the instant `grep -q` finds its match and closes its stdin — a `<verify>` block written as `some_gate | grep -q "PASS"` can silently misreport based on output length. The established safe pattern across every prior plan's `<verify>` block: capture into a variable first, then `grep -q` against `printf '%s\n' "$VAR"`:

```bash
OUT=$(some_gate 2>&1); RC=$?
printf '%s\n' "$OUT" | grep -q "expected string"  # safe — VAR is fully materialized first
```

Never write `some_gate | grep -q "..."` directly in a `<verify>` block in this repo.

## LEDGER-06 Mechanics

**Quick task `260728-51j`** [VERIFIED: `find .planning/quick -iname "*260728-51j*"` returned nothing; `STATE.md:653` confirmed the only surviving record: `260728-51j-write-the-hyprland-lua-config-migration- | missing`]. D-21-25's resolution (already locked) is directly supported by two independently-verified facts: the Lua config tree is genuinely live (`keybinds.lua`/`windowrules.lua`/`autostart.lua` all confirmed read and in active use throughout this research session), and `matugen/config.toml` carries no `[templates.hyprland]` block today [VERIFIED: `grep -n "templates.hyprland"` in `matugen/config.toml` — only `[templates.qml]` and other named blocks exist near the AGS block read this session; no hyprlang template block present].

**The two malformed `coverage:` blocks** [VERIFIED: both files read in full this session]:

- `16-05-SUMMARY.md`, item `D5` (`requirement: OVER-02`) — the SECOND `verification` entry (`kind: manual_procedural`, lines ~99-101) sets `status: not_run` (line 101). Every other `status:` value across every coverage block in both Phase 16 summary files is `pass` — `not_run` is the sole outlier in the entire corpus, confirmed by `grep -c "status: pass"` vs. the one `status: not_run` hit. The malformed shape:

  ```yaml
  - kind: manual_procedural
    ref: "NOT independently reproduced by the executor — no pointer-simulation tool is available..."
    status: not_run          # ← INVALID enum value
  ```

  The block already correctly carries `human_judgment: true` and a `rationale:` field (lines 102-103) explaining the gap honestly — the fix is narrowly the `status:` value itself, which needs to become a valid enum member (this repo's own convention elsewhere is `pass`/`fail`; since the check genuinely was not run, the honest fix is likely `status: fail` paired with the existing rationale, or introducing `not_run` as a formally-declared valid value if the schema is meant to support it — D-21-24 explicitly declines to add a validator, so this is a judgment call for the plan to make explicit, not a mechanical rename).

- `16-06-SUMMARY.md`, items `D2`, `D3`, `D4` (all `requirement: OVER-03`) — each sets `human_judgment: true` but has **no `rationale:` field at all** [VERIFIED: read the full coverage block, confirmed D1 (line 64) and D5 (implicitly, `human_judgment: false`, no rationale needed) are the only items with/needing one; D2 (ends line 75), D3 (ends line 86), D4 (ends line 94) all transition straight to the next `- id:` line with zero `rationale:` key]. The correct shape to match is D1's own block in the same file:

  ```yaml
  - id: D1
    ...
    human_judgment: true
    rationale: "No synthetic pointer tool exists on this host (16-05 confirmed: only wtype, keyboard-only), so the four live drag proofs from Task 2's <human-check> were folded into Task 3's render gate and performed by the operator."
  ```

  D2/D3/D4 need an analogous `rationale:` line each, explaining why that specific criterion needed human judgment (the render-gate step it maps to is already named in each item's own `manual_procedural` `ref:` field — e.g. D2's `ref` already says "Task 3 render gate step 3, approved: only the hovered tile lights..." — so the rationale can be derived directly from context already present in the same block, not invented).

**`16-VERIFICATION.md` reconstruction sources** [VERIFIED: all three source files confirmed present at `.planning/milestones/v3.0-phases/16-workspace-overview/`]: eight `16-0N-SUMMARY.md` files, `16-UAT.md`, `16-OVER04-MEASUREMENT.md`. Per D-21-23, this is a historical reconstruction — write what was true at Phase 16's close, including the OVER-04 frame-rate floor/target UNMEASURED gap and the `GradientBorder` rim gap (both genuinely open at Phase 16's close; the `GradientBorder` gap's later closure by Phase 20's LEDGER-01 must NOT be folded in, per D-21-23's explicit instruction).

## Common Pitfalls

### Pitfall 1: Treating the MPRIS-reader check as a net-new addition

**What goes wrong:** building a brand-new check in `retirement-check` (or elsewhere) for "exactly one reader" without noticing `quickshell-doctor` check 9 already exists, asserts the opposite, and is currently red.
**Why it happens:** the check's own name ("No Quickshell MPRIS writer") and its Phase-11-era comment don't mention D-18-05's later repoint, so a surface read of the codebase without running the gate live would miss that it's already broken.
**How to avoid:** run `quickshell-doctor` live before writing the QMEDIA-03 task; repair check 9 in place rather than adding a parallel check.
**Warning signs:** if the plan's QMEDIA-03 task doesn't mention `quickshell-doctor:2867-2883`, it hasn't found this.

### Pitfall 2: Assuming `ClockActionsCapsule` is `surfaced`

**What goes wrong:** implementing D-21-27 by editing `BarCapsule.qml`'s shared expression, or by assuming the capsule's baseline fill is `BarRoles.capsule`.
**Why it happens:** `21-UI-SPEC.md`'s own prose describes the expression accurately but doesn't state that `ClockActionsCapsule` isn't in the `surfaced` set — a reader who trusts the prose without grepping `surfaced:` in the file will build the wrong baseline assumption.
**How to avoid:** confirmed this session — zero `surfaced:` lines in `ClockActionsCapsule.qml`; its baseline fill is `"transparent"`. Override `color:` at the instance level.
**Warning signs:** a DND tint that "does nothing" outside the notification bell area, or one that unexpectedly also tints the centre workspace/idle-inhibitor capsules (a sign the edit landed in the shared `BarCapsule.qml` instead).

### Pitfall 3: Building a second cava reader instead of a shared one

**What goes wrong:** each of `MediaTab.qml`/`MediaPopout.qml` spawning its own `cava` `Process`, defeating both D-21-06's refcount requirement and quietly doubling `cava`'s CPU/RSS cost whenever both surfaces happen to be open.
**Why it happens:** the two consumers live in different directories (`modules/dashboard/` vs `modules/bar/`) with no existing shared-singleton precedent between them for anything media-related (MediaBackend is dashboard-scoped and MediaPopout reads it as a passed-in property, not via cross-directory singleton import).
**How to avoid:** register `CavaService` in a qmldir location both directories' `import` statements can reach (top-level `modules/qmldir`, matching `Colours`/`Motion`'s own precedent for cross-directory singleton consumption), and confirm both `MediaTab.qml` and `MediaPopout.qml` reference the SAME singleton instance, not two instantiated `Process` objects.
**Warning signs:** two `cava` processes visible in `pgrep -fa cava` while both surfaces are open simultaneously.

### Pitfall 4: `hyprctl reload` silently dropping the frost-unification layer-rule edits (D-21-26)

**What goes wrong:** editing `windowrules.lua`'s dashboard/overview fill+`ignore_alpha` rows, running `hyprctl reload`, and concluding the change took effect because no error was printed.
**Why it happens:** this repo's own established, repeatedly-hit finding (CONTEXT.md restates it, and it recurs across at least three prior phases per this session's earlier reads) — `hyprctl reload` silently drops layer-rule edits; `hyprctl keyword` is rejected outright on this config ("keyword can't work with non-legacy parsers").
**How to avoid:** use `hyprctl eval 'hl.layer_rule({...})'` or a full compositor restart, and take a screenshot before tuning alpha values further.
**Warning signs:** a frost value that "doesn't look different" after a `reload` — verify the rule actually re-registered before concluding the tuning itself is wrong.

## Code Examples

See § Pattern 1 (cava streaming), § Pattern 2 (refcount singleton), and § DND Capsule Tint Mechanics above — all code examples are inline with their pattern discussion rather than repeated here, each tagged either `[VERIFIED: file:line, read this session]` for existing code or "illustrative, not verified running" for new-code proposals derived from the confirmed API surface.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| Three independent MPRIS readers (waybar module, AGS bash reader, QML backend) | One QML native `Mpris` singleton reader | D-18-05 (Phase 18) for the QML side; this phase for the AGS side | QMEDIA-03 closes the last of the three; `quickshell-doctor` check 9 has been stale/wrong since D-18-05 landed and needs repairing as part of this closure |
| Static dashed ring (`PathAngleArc`, tuned to ~56 marks) | Live 60-bar radial `Repeater` of `ShapePath`s | This phase (D-21-01/03) | Restores the cava element Phase 14 cut; the silence state degrades exactly to the round-3-accepted static ring, so nothing previously approved is lost |
| Circular cover-art mask (`Rectangle`, `radius: width/2`) | Hand-authored 12-lobe cookie `ShapePath` mask | This phase (D-21-02) | Re-opens round 4's non-square-aspect clipping test — UI-SPEC already flags this as a required render-gate check, not incidental |
| AGS GTK4 media applet (own daemon, own window, own MPRIS reader) | Dashboard Media tab + bar popout, sharing one MPRIS reader and one refcounted cava process | This phase (RETIRE-06) | Retires the last of the five v4.0 package retirements; `contract.json` reaches its final post-migration size |

**Deprecated/outdated:**
- `ags/` (the whole package): retired this phase, RETIRE-06.
- `media-status.sh`/`media-players.sh`/`media-player.py`: orphaned bash MPRIS readers, deleted this phase (D-21-13).
- The Phase-11-era "zero MPRIS surface usage" invariant in `quickshell-doctor` check 9: obsolete since D-18-05, repaired this phase.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The recommended `CavaService.qml` shape (Process+SplitParser+refcount+linger) will compile and run correctly as sketched — not independently test-run against a live Quickshell process this session | § Pattern 1, § Pattern 2 | Medium — the API surface (SplitParser, Process, Singleton) is confirmed present in the installed qmltypes, but the exact combination was not built and exercised live; the plan's own Task 1 should include an early smoke-test task before building the full visualiser on top of it |
| A2 | `Super+M` should mirror `dashboardShortcut`'s toggle-with-fullscreen-guard behaviour rather than being open-only | § Reference-Shell Keybind Mechanics | Low — cosmetic UX difference only; D-21-12's text doesn't specify, and either choice satisfies the requirement's literal wording |
| A3 | The correct fix for `16-05-SUMMARY.md`'s malformed `status: not_run` is `status: fail` (paired with the existing rationale) rather than formally adding `not_run` to the schema's valid-value set | § LEDGER-06 Mechanics | Low — D-21-24 already declines to add a validator, so whichever value is chosen, no tooling enforces it either way; affects only the historical record's internal consistency |
| A4 | The repaired `quickshell-doctor` check 9 should assert `MPRIS_HITS -eq 1` (not, e.g., a more precise check that specifically names `MediaBackend.qml`) | § The QMEDIA-03 Standing Check | Low-Medium — a plain count is simpler and matches the check's existing mechanism, but a name-specific check would catch a *different* file becoming a second reader even if the total count coincidentally stayed at 1 (e.g., a bug that adds a reader to `MediaPopout.qml` while somehow removing `MediaBackend.qml`'s) — recommend the plan consider asserting both the count AND that `MediaBackend.qml` specifically is the one file matched |

**If this table is empty:** N/A — see above.

## Open Questions

1. **Does the DND capsule tint's instance-level `color:` override need its own `Behavior on color` declared, or does it inherit `BarCapsule.qml`'s existing one?**
   - What we know: `BarCapsule.qml:81-88` declares `Behavior on color { ... }` on the `color` property. QML property overrides at the instance level replace the property's *value binding*, not its `Behavior` — Behaviors attached to a property in the base type generally continue to apply to value changes on that property from a derived/instance override, since `Behavior` is a separate object watching the property's `Changed` signal, not part of the binding itself.
   - What's unclear: not independently verified live this session (would require a running Quickshell instance with a test harness); stated here as the standard QML mechanics for this documented pattern rather than an assumption needing confirmation.
   - Recommendation: implement per § DND Capsule Tint Mechanics above; if the transition doesn't animate, the fallback is an explicit local `Behavior on color` on the instance override.

2. **Should the `bars` config value in the new `cava/config` file be 60 immediately, or should the plan verify cava's CPU/latency profile at 60 bars independently before committing to it as the shipped value?**
   - What we know: CONTEXT.md's own D-21-00 finding already measured 60-bar cava on this host (1.20% of one core, 14.0 MB RSS, ~350ms cold start) — this measurement already used 60 bars, so no further measurement is needed.
   - What's unclear: nothing — this is resolved, listed here only to make explicit that the "60 bars" measurement point in CONTEXT.md and the "new cava/config needs bars=60" implementation point in this research are the same fact, not two separate claims needing reconciliation.
   - Recommendation: no action needed; `bars = 60` in the new config file is fully supported by existing measurement.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | No auth surface touched by this phase |
| V3 Session Management | No | N/A |
| V4 Access Control | No | N/A |
| V5 Input Validation | Yes | `media-art-resolve.sh`'s scheme allowlist + loopback/RFC1918 pre-flight rejection (RETAINED unchanged, D-21-14); the new `setVolumeForPlayer(playerId, fraction)` mutator must validate `playerId` against the live `Mpris.players.values` model before dispatch (mirrors the existing `selectPlayer` guard pattern at `MediaBackend.qml:129-139`), never trusting a caller-supplied id blindly |
| V6 Cryptography | No | No new crypto surface |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| SSRF via a crafted `artUrl` (IPv6-bracket/decimal-integer/hex-encoded loopback bypasses) | Tampering / Information Disclosure | `media-art-resolve.sh`'s existing scheme/host guard, already covering 5 documented bypass classes (`test-media-hardening.sh` checks 8/9/9b — RETAINED, D-21-15). No new work needed here beyond keeping this coverage intact through the test-file trim. |
| Unvalidated `playerId` reaching a dispatch call | Tampering | New `setVolumeForPlayer` must validate against the live model, same as `selectPlayer` already does — not a new threat class, but a new call site that must inherit the existing discipline |
| Cava subprocess argv injection | Tampering | Not applicable — the cava command line is a fixed 3-element argv (`["cava","-p",configPath]`) with no user-controlled or track-metadata-derived content, unlike the retired `media-players.sh cmd`'s verb/id dispatch surface |

## Sources

### Primary (HIGH confidence — direct verification on this host, this session)

- `ags/.config/ags/lib/cava.ts` (full file read) — the proven cava streaming contract
- `ags/.config/ags/cava/config` (full file read) — the exact working cava config
- `pacman -Q cava dart-sass aylurs-gtk-shell` — installed package versions
- `pgrep -fa cava` — live process confirmation (PID 1990)
- `/usr/lib/qt6/qml/Quickshell/Io/quickshell-io.qmltypes` — Process/SplitParser/StdioCollector/DataStreamParser API surface, quickshell 0.3.0-2
- `rg -n "SplitParser|Process {|pragma Singleton" quickshell/.config/quickshell/` — confirmed no existing SplitParser usage, 31 Process call sites, 16 Singleton files
- `quickshell/.config/quickshell/modules/dashboard/MediaTab.qml` (full file read, 1339 lines) — the surface being extended, including all six render-gate round headers
- `quickshell/.config/quickshell/modules/dashboard/MediaBackend.qml` (full file read) — the single MPRIS reader
- `quickshell/.config/quickshell/modules/bar/MediaPopout.qml` (full file read) — confirmed no existing mask/ring
- `quickshell/.config/quickshell/modules/bar/PopoutController.qml` (relevant sections read) — the grace-timer shape precedent
- `quickshell/.config/quickshell/modules/bar/BarCapsule.qml`, `ClockActionsCapsule.qml` (relevant sections read) — the `surfaced` finding
- `quickshell/.config/quickshell/modules/bar/BarRoles.qml` (full file read) — the Qt.rgba blend idiom
- `quickshell/.config/quickshell/modules/*/qmldir` (all three read in full) — the both-required singleton registration rule
- `quickshell/.config/quickshell/shell.qml`, `modules/Dashboard.qml` (relevant sections read) — the tab-open wiring, `dashboardTabIndex`, `onDashboardRequested`
- `quickshell/.config/quickshell/shortcuts.json` (full file read) — the keybind manifest shape
- `hypr/.config/hypr/config/keybinds.lua` (relevant sections read) — the `hl.bind`/`hl.dsp.global` precedent block
- `hypr/.config/hypr/config/windowrules.lua` (full ags-related grep + surrounding context read) — every `ags-media` reference site
- `hypr/.config/hypr/config/autostart.lua` (relevant lines) — the AGS autostart entry
- `install.sh`, `stow.sh` (relevant sections read) — cava/dart-sass/aylurs-gtk-shell package dispositions
- `theme-engine/.config/theme-engine/contract.json` (full file read) — 18 files entries confirmed
- `theme-engine/.config/theme-engine/lib/reload.sh` (relevant section read) — the ags reload fan-out step
- `theme-engine/.config/theme-engine/theme-doctor`, `theme-parity`, `theme-stress-test` (usage lines + relevant sections read)
- `hypr/.config/hypr/scripts/retirement-check` (full registry + CLI dispatch read)
- `hypr/.config/hypr/scripts/quickshell-doctor` (relevant sections read, and a full LIVE RUN performed this session — 18 passed, 2 failed, confirming the stale MPRIS check)
- `hypr/.config/hypr/scripts/colour-lint` (existence + tail read)
- `hypr/.config/hypr/scripts/tests/test-media-hardening.sh` (full file read, 330 lines) — exact check boundaries for the D-21-15 trim
- `grep -rl` sweeps for `media-status.sh`/`media-players.sh`/`media-player.py`/`media-art-resolve.sh` consumers across the whole repo — confirmed orphan status
- `.planning/milestones/v3.0-phases/16-workspace-overview/16-05-SUMMARY.md`, `16-06-SUMMARY.md` (full coverage blocks read) — the two malformed shapes, quoted verbatim
- `.planning/STATE.md` (relevant sections read) — the `260728-51j` and malformed-block audit rows

### Secondary (MEDIUM confidence)

None — every claim in this document was directly verified this session; no web-search-sourced claims were needed given the phase's fully-local, fully-inspectable scope.

### Tertiary (LOW confidence)

None.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new packages, both retained packages independently re-verified via `pacman -Q` and an independent stow.sh dependency trace
- Architecture: HIGH — every pattern (SplitParser, Singleton refcount, Shape/Repeater) grounded in either confirmed-present installed qmltypes or an existing local precedent identified by direct file reads
- Pitfalls: HIGH — all four pitfalls are drawn from directly-observed facts this session (a live-failing gate, a confirmed-absent `surfaced:` line, a confirmed-absent SplitParser precedent, a repo-wide-documented hyprctl-reload trap), not speculation

**Research date:** 2026-08-16
**Valid until:** 30 days (stable local codebase, no external API drift risk) — but re-verify the `quickshell-doctor` live-run result if any commit touches `quickshell-doctor` or `MediaBackend.qml` before this phase's plan executes, since that finding is time-sensitive to the exact state of both files.
