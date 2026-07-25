# Stack Research: v3.0 Quickshell Foundation & Motion Language

**Domain:** Personal Arch + Hyprland rice — adding a QML/Quickshell shell layer and a spring-physics motion token pipeline alongside an existing, working GTK/matugen/waybar/AGS desktop
**Researched:** 2026-07-26
**Confidence:** HIGH for everything verified directly against this machine (`pacman`, `hyprctl version`); MEDIUM for cross-checked web findings (2+ independent sources agreeing); LOW for single-source web claims — flagged explicitly below, treat as needing a phase-specific spike, not roadmap-level trust.

**Target compositor:** Hyprland 0.56.0 (confirmed: `hyprctl version` → `Hyprland 0.56.0 built from branch v0.56.0`, package `hyprland 0.56.0-2`).

---

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| **quickshell** | **0.3.0-2** (Arch official `extra` repo — verified `pacman -Si quickshell`, packager Peter Jung, built 2026-06-05) | QtQuick-based desktop shell toolkit; renders the new QML surfaces (dashboard drawer, audio/wifi/bluetooth panels, workspace overview) | **This is the single most important correction to make before roadmap creation: Quickshell is NOT AUR-only.** It has been in Arch's official `extra` repo since mid-2025 and is a plain `pacman -S quickshell` install — no AUR, no build-from-source cost, no `paru`/`yay` dependency for `install.sh`. Confidence: HIGH (direct system verification: `pacman -Si quickshell` returns `Repository: extra`). This single fact removes what would otherwise be the biggest reproducibility risk in this milestone. |
| **qt6-base** | 6.11.1-1 (installed, hard dep of quickshell) | Qt6 core (widgets/gui/dbus/network foundations) | Required by quickshell's `Depends On` list (verified `pacman -Si quickshell`). Already present on this machine from other Qt6 consumers. |
| **qt6-declarative** | 6.11.1-3 (installed, hard dep of quickshell) | QML engine (`QtQuick`, `QtQml`) — the actual language/runtime Quickshell surfaces are written in | Required by quickshell's `Depends On`. Upstream `BUILD.md` states Quickshell "relies on private Qt APIs and MUST be rebuilt against each Qt release or crashes via ABI mismatches will occur" (MEDIUM confidence, single upstream doc, not independently cross-checked) — this is exactly why installing the **distro-packaged** `quickshell` (which the Arch maintainer rebuilds in lockstep with `qt6-declarative` bumps) is materially safer for `install.sh` than an AUR/source build that a user would have to remember to rebuild after every Qt update. |
| **qt6-svg** | 6.11.1-1 (installed, hard dep of quickshell) | SVG image/icon rendering | Required by quickshell's `Depends On`; upstream calls this "recommended — without it, SVG images and system SVG icons will not work." Arch's package correctly hardens it to a mandatory dependency rather than optional. |
| **qt6-wayland** | 6.11.1-1 (installed, hard dep of quickshell) | Wayland platform integration, `wlr-layer-shell-unstable-v1`, `qtwaylandscanner` protocol bindings | Required by quickshell's `Depends On`. Upstream notes it's specifically required for Qt versions prior to 6.10 for private-header access; this system runs Qt 6.11.1 and it is still a hard runtime dep in the distro package, so treat it as always-required regardless of the upstream nuance. |
| **cmake, cpio, glaze, hyprland-protocols, meson** | latest `extra` versions (cmake/cpio/meson already installed; glaze/hyprland-protocols not yet) | Build toolchain **only if** `hyprpm`-based plugins (e.g. `hyprexpo`) are added | Confirmed as the exact optional-dependency list of the *installed* `hyprland 0.56.0-2` package itself (`pacman -Qi hyprland`) captioned "to build and install plugins using hyprpm" — i.e., Hyprland plugins are compiled **locally, from source, at install/enable time**, against the exact installed compositor build. See Pitfall/Risk section below — this is the single biggest reproducibility risk in the whole milestone if hyprexpo is chosen. |

### Supporting Libraries / Quickshell Built-in Modules

All of the following are compiled into the single `quickshell` package already installed above — no extra packages needed, confirmed via Quickshell's own module documentation (websearch, cross-checked across quickshell.org docs pages + DeepWiki mirrors → MEDIUM confidence for API surface details, but package boundary itself is HIGH since it's one binary already on disk):

| Module | Purpose | When to Use |
|--------|---------|-------------|
| `Quickshell.Services.Pipewire` | Native PipeWire graph binding — `Pipewire` singleton exposes `nodes` (ObjectModel of all audio nodes), `links`/`linkGroups`, `defaultAudioSink`/`defaultAudioSource`; `PwNode`/`PwNodeAudio` expose per-channel `volumes`, an averaged settable volume, and per-node application metadata | **Use this directly for the per-app volume mixer** — it talks to PipeWire's graph over its native protocol, not by shelling out to `wpctl`/`pw-dump`. No bridge script needed. |
| `Quickshell.Networking` (root namespace) | Native NetworkManager D-Bus binding — device types, connection states, WiFi network list, wired devices | **Use this directly for the wifi picker panel.** No `nmcli` subprocess parsing needed; NetworkManager 1.58.0-1 is already installed and running on this machine. |
| `Quickshell.Bluetooth` | Native BlueZ D-Bus binding — `Bluetooth` singleton (all devices across adapters, default adapter), `BluetoothDevice` (connection/pairing state, battery level, naming) | **Use this directly for the bluetooth manager panel.** `bluez 5.87-2` is already installed on this machine; both D-Bus and bluez must be running (already true here). |
| `Quickshell.Services.Mpris` | Native MPRIS binding | Available if the dashboard drawer's media-controls tile is rebuilt in QML instead of reusing the AGS v3 media card. **Recommendation: do not use this in v3.0** — the AGS media card is explicitly staying live this milestone (PROJECT.md scope boundary); only reach for this module in v4.0 if/when AGS is retired. |
| `Quickshell.Services.UPower` | Battery/power management | Useful for the dashboard drawer's system-resources tile (battery %, charging state) alongside `/sys` or existing waybar battery logic. |
| `Quickshell.Services.Notifications` | Notification-daemon implementation types | **Do not use** — swaync stays the notification daemon this milestone (scope boundary: "no retirements in v3.0"). Documented here only so it isn't mistakenly reached for. |
| `Quickshell.Wayland.ScreencopyView` (`Quickshell.Wayland` module) | Live or still capture of a Wayland surface — `captureSource` can be a `Toplevel` (via `hyprland-toplevel-export-v1`) or a `ShellScreen`/monitor (via `wlr-screencopy-unstable-v1` or `ext-image-copy-capture-v1`); `live: true` gives a continuously-updating video feed | **This is the recommended mechanism for the workspace overview's live window thumbnails** — see the dedicated comparison below. Zero extra packages, zero hyprpm/plugin-ABI coupling. |
| `Quickshell.Hyprland` (`Quickshell.Ipc`/Hyprland-specific types) | `Hyprland` singleton + `HyprlandToplevel` — reactive workspace/monitor/window state over Hyprland's two Unix-domain IPC sockets (request socket + read-only event-stream socket) | Backing data source for workspace enumeration feeding the overview grid, and for any Hyprland-state-driven UI (active workspace indicator, window list). Confirmed HIGH-confidence architecturally (single credible source, DeepWiki mirror of quickshell-mirror/quickshell, MEDIUM confidence on exact socket count/naming detail). |

### Development / Diagnostic Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| `quickshell -c <config> -p` / IPC reload | Hot-reload during development | Confirmed architecturally: Quickshell watches config files via `QFileSystemWatcher` or an IPC reload signal and spins up a new "EngineGeneration" of QML components loading in parallel with the old one — this is exactly the "hot reload" leg of the Phase-11 viability gate. MEDIUM confidence (single web source, not directly tested on this machine yet — the viability gate phase must confirm this empirically on Hyprland 0.56.0 before anything is built on top). |
| `WlrLayershell.namespace` convention (`quickshell:<moduleName>`) | Lets Hyprland layer-rules target specific Quickshell surfaces (blur, opacity, animation) the same way existing `windowrules.conf` targets waybar/swaync/wleave today | Confirmed pattern from end-4/dots-hyprland integration docs (MEDIUM confidence, cross-checked across 2 DeepWiki mirrors). Directly reusable with this repo's existing layer-rule authoring style. |
| `hyprpm` | Hyprland's plugin manager (already installed, `/usr/bin/hyprpm`) | **Only needed if hyprexpo is chosen over `ScreencopyView`+`hyprland-toplevel-export-v1` for the overview** — see risk section. Confirmed present on this system but its state store requires root/superuser setup on first run (`hyprpm list` failed with `Failed to run a superuser cmd` when tested unprivileged here) — factor this into any `install.sh` automation. |

---

## Motion Token Pipeline — Fidelity Assessment (Question 4)

This is the core design bet of the milestone: **store spring physics (mass/stiffness/damping) once, emit a native spring for QML and a fitted approximation for GTK4 CSS and Hyprland bezier.** Assessed per-target below.

### QML target — full fidelity (native)

QML/QtQuick ships genuine damped-harmonic-oscillator springs natively:

- **`SpringAnimation`** (a `QtQuick` animation type) — takes `spring` (stiffness), `damping`, `mass`, `epsilon` (settle threshold), and `modulus` (for wraparound values like hue/rotation) directly. This is a literal physics simulation, not a curve approximation — it is the actual source-of-truth representation.
- **`Behavior { SpringAnimation { ... } }`** — the standard idiom for "whenever this property changes, animate it with a spring" declaratively, without imperative trigger code.
- **`NumberAnimation`** / `ColorAnimation` / `PropertyAnimation` with an `easing` property (type `Easing.OutBack`, `Easing.OutElastic`, `Easing.Bezier`, etc.) — QML's `Easing` enum already includes bezier and elastic/back curve families for the *non*-spring animations elsewhere in the UI (e.g. simple fades) so the same design system can mix true springs and named easing curves without inventing a second syntax.

**Verdict: full fidelity achievable, zero compromise on the QML side.** This part of the design intent is not a research risk — it's standard QtQuick usage. (High confidence — this is stable, long-documented core Qt/QML API; not independently web-verified this session but not in dispute.)

### GTK4 CSS target — single-cubic-bezier ceiling, verify empirically before relying on it

GTK4's CSS engine is a frozen subset of early-2010s web CSS (its own docs describe it as "a subset of the CSS3 specification... with some GTK-specific extensions"), confirmed timing-function values (cross-checked across MDN + GTK docs, MEDIUM confidence):

- `ease`, `linear`, `ease-in`, `ease-out`, `ease-in-out` (named shorthands, each itself defined as *one* `cubic-bezier(...)`)
- `cubic-bezier(x1, y1, x2, y2)` — a single 4-control-point curve, exactly matching what Hyprland's `bezier =` line takes (see below)
- `steps(n, <position>)`, `step-start`, `step-end`
- `@keyframes` blocks driven by `animation-name`/`animation-duration`/`animation-timing-function` — usable for multi-stage sequences, but each segment between keyframes is still a `cubic-bezier`/named/`steps()` easing, not a spring

**Not found/not confirmed:** the modern CSS Easing Level 2 `linear(<stop-list>)` function (the multi-point-list easing that browsers added specifically to let web CSS *approximate* springs with many linear segments). No source in this research confirmed GTK4 supports it, and given GTK4's CSS engine is a deliberately small, long-stable subset (not evergreen web CSS), the default assumption should be **it does not** — **this must be verified empirically** (e.g., a throwaway GTK4 CSS test file with `transition-timing-function: linear(0, 0.5 25%, 1)`) at the start of the motion-token-pipeline phase, not assumed either way. If unsupported, the pipeline must fit a **single best-match `cubic-bezier()`** per named spring token (an approximation of a damped oscillator's overall "shape," losing any bounce/overshoot beyond one control point pair — a real fidelity loss vs. QML, not a bug to "fix" later).

**Verdict: single-bezier fit is achievable and matches Hyprland's own ceiling (see next); genuine springy bounce/overshoot is NOT reproducible in GTK4 CSS with confirmed features — plan for a curve-fitting step (least-squares fit of a `cubic-bezier` to the spring's response curve, e.g. sampling the QML spring's position-over-time and fitting 2 control points) and accept the fidelity loss as a documented, intentional compile-target limitation, not a defect.**

### Hyprland `bezier =` / `animation =` target — same single-cubic-bezier ceiling

Confirmed syntax (MEDIUM confidence, cross-checked across Hyprland wiki mirrors):

```
bezier = myBezier, 0.05, 0.9, 0.1, 1.05
animation = windows, 1, 7, myBezier
```

- `bezier = <name>, X0, Y0, X1, Y1` — defines a named cubic Bézier curve from two control points (exactly 4 numbers, same shape as CSS `cubic-bezier()`).
- `animation = <NAME>, <ONOFF>, <SPEED>, <CURVE>, [STYLE]` — `SPEED` is in centiseconds (1 `ds` = 100 ms), `CURVE` references a named bezier, optional `STYLE` (e.g. `popin`, `slide`) changes the animation's spatial behavior but not its timing curve. Animations form an inheritance tree (unset settings fall back to parent).

**Verdict: identical ceiling to GTK4 CSS — a single fitted `cubic-bezier` per spring token.** Because both non-QML targets share the exact same 4-parameter curve representation, **the fitting step only needs to be implemented once** (fit spring → 4 bezier control points) and the same fitted numbers can feed both the Hyprland `bezier =` line and the GTK4 `cubic-bezier()` value — this is good news for the pipeline's implementation cost, even though the fidelity ceiling itself is real.

### Design implication for the token pipeline

Store per motion token: `{ mass, stiffness, damping, epsilon? }` as the single source of truth (mirrors how `contract.json` already treats colour tokens as the single source rendered to N targets). Compile step produces:
1. QML: pass mass/stiffness/damping straight through to `SpringAnimation` — no lossy transform.
2. A **shared bezier-fit routine** (sample the spring's step-response curve, least-squares-fit one `cubic-bezier(x1,y1,x2,y2)`) — emit the same 4 numbers into both the GTK4 CSS template and the Hyprland `bezier =` template.

This is a genuinely coherent "one source, many targets" design matching the project's existing colour-pipeline pattern — but the roadmap should budget an explicit research/prototype spike for the bezier-fitting algorithm itself (curve-fitting a damped oscillator to a single cubic Bézier is a solved but non-trivial numerical problem, not a config-file lookup) and should NOT assume `linear()` multi-stop support in GTK4 without the empirical test above.

---

## Workspace Overview — hyprexpo vs. hyprland-toplevel-export-v1 (Question 3, flagged risk)

This is the most consequential comparison in this research and should directly gate a roadmap decision.

### Option A: `hyprexpo` (Hyprland compositor plugin)

- **What it is:** An official plugin in `hyprwm/hyprland-plugins` (confirmed — cross-checked GitHub repo + DeepWiki + Hyprland's own plugins listing at hypr.land/plugins). Intercepts Hyprland's rendering pipeline to capture workspace snapshots into off-screen framebuffers and composites a grid with its own entrance/exit animations.
- **Installation:** `hyprpm add https://github.com/hyprwm/hyprland-plugins` then `hyprpm enable hyprexpo` (MEDIUM confidence, cross-checked wiki + community sources).
- **The coupling problem (confirmed directly on this machine + cross-checked web reports):**
  - `hyprpm` **compiles the plugin from source, locally, at enable-time**, against the *exact* installed Hyprland build. The optional-deps list of the locally installed `hyprland 0.56.0-2` package itself lists `cmake`, `cpio`, `glaze`, `hyprland-protocols`, `meson` captioned **"to build and install plugins using hyprpm"** — this is not a rumor, it's what the distro package manifest says about its own plugin system.
  - Community reports (cross-checked: a Fedora 43→44 upgrade post, an openSUSE forum thread, GitHub issue #9101, a Garuda forum thread) consistently describe plugins failing to load or failing to build after a Hyprland version bump, requiring `hyprpm update && hyprpm enable <plugin>` (a rebuild) — or in worse cases, waiting for the upstream plugin repo to publish a pinned-compatible commit for the new Hyprland release before the rebuild can even succeed.
  - `hyprpm`'s state store required a superuser operation that failed non-interactively when tested on this machine (`hyprpm list` → `Failed to run a superuser cmd`) — this alone is a red flag for unattended `install.sh` automation, independent of the ABI question.
  - **What this does to reproducible installs:** a container/VM fresh-install gate that pins package versions (the exact model this repo's `install.sh` + `verify/` already uses) cannot simply `pacman -S` its way to a working hyprexpo — it needs network access to a git repo, a full C++ build toolchain, and a rebuild step that is **silently invalidated by every future Hyprland point release**. This directly conflicts with this project's own reproducibility constraint ("no manual host-only state") and its own container-gate pattern proven in prior milestones.

### Option B: `hyprland-toplevel-export-v1` via Quickshell's native `ScreencopyView`

- **What it is:** A Wayland protocol **built into the Hyprland compositor itself** — confirmed directly on this machine: `pacman -Qo /usr/include/hyprland/protocols/hyprland-toplevel-export-v1.hpp` → owned by the `hyprland 0.56.0-2` package, not a separate plugin or add-on package.
- **Consumption path:** Quickshell ships a first-class QML type, `Quickshell.Wayland.ScreencopyView`, whose `captureSource` accepts a `Toplevel` object (backed by this exact protocol) and whose `live: true` property gives a continuously updating video feed of that single window — cleanly avoiding the "overlap problem" that plain `wlr-screencopy` has (capturing a covered window just returns whatever's on top of it, since screencopy captures the *output*, not the window buffer). Cross-checked across quickshell.org docs pages and multiple community QML overview implementations (`qs-hyprview`, `quickshell-overview`) that already use exactly this mechanism for exposé-style overviews — MEDIUM confidence, 3+ independent corroborating sources.
- **Reproducibility profile:** **Zero extra packages beyond `quickshell` itself** (already required for the whole milestone). No compiler toolchain, no hyprpm, no version-pinned plugin repo, no rebuild-on-upgrade problem — the protocol is compositor-native and ships with whatever Hyprland version is installed via the normal `pacman -S hyprland` path this repo already depends on.

### Recommendation

**Use `hyprland-toplevel-export-v1` via Quickshell's `ScreencopyView`, not `hyprexpo`.** This is not a close call on reproducibility grounds: hyprexpo reintroduces exactly the class of fragility (compositor-version-coupled local compilation, silent breakage on upgrade, root-requiring state store) that this project's own `install.sh`/container-gate discipline exists to prevent, while the toplevel-export path costs nothing beyond the `quickshell` package this milestone already requires, and is the mechanism the reference rices (Caelestia-adjacent projects, `qs-hyprview`) already converged on for the same feature. The milestone's own "research-gated" flag on this question should resolve to: **build the overview on `ScreencopyView`/`hyprland-toplevel-export-v1`; do not add hyprexpo or any `hyprpm` plugin as an `install.sh` target.** If a future need for compositor-level effects genuinely requires a plugin, treat that as its own explicitly-scoped, explicitly-risk-accepted decision — not a default.

---

## matugen → QML Integration (Question 6)

**Reference-rice pattern (Caelestia-dots/shell, built on Quickshell):** matugen renders directly to a **`.qml` file**, not a JSON intermediate. Caelestia's config points matugen's template output at a path like `~/.config/quickshell/overview/common/Appearance.colors.qml`; the shell then loads it as a `pragma Singleton` QML object (commonly wrapped with a `FileView` watching the file for hot-reload, or simply re-read on Quickshell's config-reload cycle) exposing named colour-role properties (Caelestia's own `Colours.qml` singleton documents 80+ Material 3 color roles). Cross-checked: DeepWiki mirror of `caelestia-dots/shell` (2 pages) — MEDIUM confidence, single project studied in depth but the "matugen renders a template, template happens to be QML syntax" mechanism is exactly consistent with how matugen already works in *this* repo (arbitrary text templates, not a fixed output format) — HIGH confidence for the mechanism itself, since it requires zero new matugen capability.

**Recommendation for this repo:** add one more matugen template target — `theme-engine`'s existing `contract.json` + template pattern already treats "render arbitrary text to N targets from one palette" as a solved, regression-gated problem (`theme-parity`, `theme-doctor`). Adding a QML target is mechanically identical to adding any other render target this repo already has 22 of:

```qml
pragma Singleton
import QtQuick

QtObject {
    readonly property color background: "{{colors.background.default.hex}}"
    readonly property color primary: "{{colors.primary.default.hex}}"
    // ...
}
```

placed at (e.g.) `~/.local/state/theme/quickshell-colors.qml`, registered in `contract.json` as a 23rd render target, and loaded by Quickshell's QML `import` mechanism (Quickshell singletons are typically resolved via a `qmldir` file in the same directory declaring `singleton Colours 1.0 quickshell-colors.qml`). **Do not build a separate JSON-reading bridge layer** — that would be new surface area duplicating what a direct `.qml` template already gives for free, and would diverge from this repo's own established "no copied files, one render target per surface" convention (see PROJECT.md Key Decisions: "Every themed surface consumes the palette via `@import`... never a copied file").

---

## Installation

```bash
# Core — all from Arch official 'extra' repo, no AUR needed for the shell toolkit itself
pacman -S quickshell qt6-base qt6-declarative qt6-svg qt6-wayland

# ONLY if hyprexpo (NOT recommended — see risk section) is chosen over ScreencopyView:
# pacman -S cmake cpio meson glaze hyprland-protocols
# hyprpm add https://github.com/hyprwm/hyprland-plugins
# hyprpm enable hyprexpo
# hyprpm reload
# NOTE: this build step must be re-run after every Hyprland version bump; install.sh
# would need to treat it as a non-idempotent, network-and-compiler-dependent step,
# unlike every other package in this repo's install path.
```

No `install.sh` changes are needed for PipeWire, NetworkManager, or BlueZ — `pipewire`/`wireplumber`, `networkmanager` (1.58.0-1), and `bluez`/`bluez-utils` (5.87-2) are already installed and running on this machine and are consumed by Quickshell's native service modules, not by new shell-script bridges.

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|--------------------------|
| `quickshell` (Arch `extra`, 0.3.0-2) | `quickshell-git` (AUR, tracks `main`) | Only if a specific unreleased fix/feature is needed before the next `extra` package bump. Building from AUR trades the distro maintainer's Qt-ABI-rebuild discipline (see Core Technologies note on private-API rebuilds) for a `makepkg`-time build that a fresh install months later would repeat against whatever Qt is current then — plausibly fine, but adds a compile step and a second package identity (`Conflicts With: quickshell`) that `install.sh` would need to special-case. Not recommended for this milestone; no known need for `main`-only fixes has been identified. |
| Single fitted `cubic-bezier()` per spring token for GTK4/Hyprland | Multi-stop `linear()` CSS easing (if GTK4 turns out to support it) | If the empirical test (recommended above, run early in the motion-pipeline phase) shows GTK4's CSS parser does accept `linear(<stop-list>)`, switch the GTK4 compile target to a multi-point sampled approximation of the spring curve instead of a single bezier — meaningfully closer to true spring fidelity (visible bounce/overshoot) than one bezier can express. Do not build this as the default plan without that empirical confirmation. |
| `hyprland-toplevel-export-v1` + `ScreencopyView` for workspace overview | `hyprexpo` plugin | Only if a future requirement needs compositor-level render-pipeline effects that a client-side (Quickshell) capture cannot provide (e.g. a genuinely compositor-integrated transition during the overview's own entrance animation). Given this milestone's own reproducibility constraint and prior BAR-02-style evidence-first precedent, this should require its own explicit risk-accepted decision, not be a default choice. |
| Quickshell's native `Quickshell.Networking`/`Quickshell.Bluetooth`/`Quickshell.Services.Pipewire` modules | Shelling out to `nmcli`/`wpctl`/`bluetoothctl` from a Quickshell `Process`/`Io` type | Only if a specific data point turns out to be missing from the native module's exposed API surface (not identified in this research) — shelling out reintroduces parsing fragility this repo has spent multiple phases eliminating elsewhere (e.g. the walker exit-code decision, the `contract.json` schema decision). Prefer the native binding as default; treat a shell-out as a documented fallback for a specific gap, not a starting design. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|--------------|
| `hyprexpo` (or any `hyprpm`-managed plugin) as an `install.sh` target for the workspace overview | Compiled from source locally against the exact installed Hyprland ABI; confirmed to break across compositor version bumps (multiple cross-checked community reports); `hyprpm`'s own state store required a superuser op that failed non-interactively when tested on this machine. Directly conflicts with this project's "no manual host-only state" constraint and its container-gate reproducibility model | `hyprland-toplevel-export-v1` via Quickshell's native `Quickshell.Wayland.ScreencopyView` — zero extra packages, compositor-native protocol, no rebuild-on-upgrade risk |
| `quickshell-git` (AUR) as the default install target | Adds a compile step and a `Conflicts With: quickshell` alternate package identity for no identified concrete benefit this milestone | `quickshell` from official `extra` (0.3.0-2) |
| A shell-script/JSON bridge for audio, wifi, or bluetooth data | Quickshell already ships native D-Bus/PipeWire-protocol bindings for all three (`Quickshell.Services.Pipewire`, `Quickshell.Networking`, `Quickshell.Bluetooth`); a bridge script would duplicate functionality and reintroduce output-parsing fragility this repo has already worked to eliminate elsewhere | The native Quickshell service modules directly |
| Assuming GTK4 CSS supports modern web-CSS `linear(<stops>)` easing without testing it first | GTK4's CSS engine is a frozen, long-stable subset of an early CSS3-era spec, not evergreen browser CSS; no source found in this research confirms support, and the default assumption for a frozen engine should be "unsupported until proven otherwise" | A single fitted `cubic-bezier()` per spring token (matches Hyprland's own `bezier =` ceiling, so one fitting routine serves both non-QML targets) |
| Rebuilding walker/elephant, waybar, swaync, SwayOSD, wleave, or the AGS media card in QML this milestone | Explicit v3.0 scope boundary (PROJECT.md: "no retirements in v3.0") — this is additive-only | Keep all existing surfaces live; QML only adds new surfaces (dashboard drawer, audio/wifi/bluetooth panels, workspace overview, ambient extras) |

## Stack Patterns by Variant

**If the Phase-11 Quickshell viability gate fails (layer-shell, pointer input, focus, multi-monitor, or hot-reload doesn't work cleanly on Hyprland 0.56.0):**
- Stop before building anything further on the toolkit — this is explicitly a gate with authority to halt the phase, matching the precedent set by Phase 10's eww pointer-input gate.
- Because `quickshell` is a plain distro package (not an AUR/source build), a failed gate is cheap to retry against a future Hyprland/Qt point release without any build-toolchain cleanup.

**If GTK4's CSS parser is confirmed NOT to support `linear(<stops>)` (the expected/default outcome):**
- Use single-`cubic-bezier()` fitting for both the GTK4 CSS and Hyprland bezier compile targets from one shared fitting routine.
- Document the fidelity ceiling explicitly in the design-token spec so it isn't mistaken for a bug later (matches this project's own precedent of writing an explicit evidence artifact for a descoped/limited capability, e.g. Phase 8's BAR-02).

**If a future milestone (v4.0+) revisits retiring waybar/swaync/wleave/AGS for QML equivalents:**
- Re-survey `Quickshell.Services.Mpris`, `Quickshell.Services.Notifications`, and `Quickshell.Services.UPower` at that time — they exist today but are explicitly out of scope for v3.0 per the additive-only constraint.

## Version Compatibility

| Package A | Compatible With | Notes |
|-----------|------------------|-------|
| `quickshell` 0.3.0-2 | `qt6-declarative` 6.11.1-3, `qt6-base` 6.11.1-1, `qt6-svg` 6.11.1-1, `qt6-wayland` 6.11.1-1 | Confirmed as the exact installed, mutually-resolving dependency set on this machine right now (`pacman -Si quickshell`). Upstream states Quickshell must be rebuilt per Qt release (private-API usage) — since this is consumed as a distro binary, that rebuild discipline is the Arch package maintainer's responsibility, not `install.sh`'s; `pacman -Syu` will naturally pull matching versions of both together as long as both stay sourced from `extra`. |
| `quickshell` 0.3.0 | Hyprland 0.56.0 | Not a versioned dependency relationship in pacman (Quickshell talks to Hyprland only via its IPC sockets and standard `wlr-layer-shell`/Hyprland-native Wayland protocols, not a compiled ABI link) — confirmed no `hyprland` entry in quickshell's `Depends On` list. This is a meaningfully looser coupling than the `hyprexpo`/hyprpm case and should be the reassuring baseline expectation for the rest of this milestone's Quickshell work. |
| `hyprland` 0.56.0-2 | `hyprland-plugins` (hyprexpo etc.) | **Tightly and fragile-ly coupled** — `hyprpm` pins a matching plugin-repo commit per Hyprland version and rebuilds locally; a Hyprland version bump without a corresponding plugin-repo update is a confirmed real-world breakage pattern (cross-checked multiple community reports). This is the one piece of the whole stack that does NOT get the "pacman resolves it" treatment the rest of this table enjoys. |
| GTK4 CSS `cubic-bezier()` | Hyprland `bezier = name, X0, Y0, X1, Y1` | Both take the identical 4-control-point representation — confirmed by comparing the two syntaxes directly (cross-checked GTK CSS docs + Hyprland wiki mirrors). One shared spring-to-bezier fitting routine can emit both. |

## Sources

- **Direct system verification on target machine (HIGH confidence — ground truth):** `hyprctl version`; `pacman -Q/-Qi/-Si` for `hyprland`, `quickshell`, `qt6-base`, `qt6-declarative`, `qt6-svg`, `qt6-wayland`, `qt6-multimedia`, `qt6-shadertools`; `pacman -Qo` ownership check for `hyprland-toplevel-export-v1.hpp`; `pacman -Sl extra | grep quickshell` (confirms official-repo membership, not a third-party repo); `paru -Si quickshell-git` (AUR comparison); `pacman -Ss hyprexpo` / `paru -Ss hyprexpo` (confirms no such standalone AUR package; only the unrelated `hyprexpose-git`); `hyprpm list` (confirms superuser-state-store friction); `wpctl`/`pw-dump --version`, `nmcli --version`, `bluetoothctl --version`, `pacman -Q networkmanager bluez` (confirm all three backend services already installed/running).
- websearch (MEDIUM, cross-checked): "Quickshell Hyprland IPC layer-shell integration hot reload" → DeepWiki mirrors of `end-4/dots-hyprland` and `quickshell-mirror/quickshell`, corroborating the two-Unix-socket IPC model, `WlrLayershell.namespace` convention, and generation-based hot reload.
- websearch (MEDIUM, cross-checked): "Hyprland hyprexpo plugin hyprpm workspace overview" + "hyprexpo official plugin hyprwm/hyprland-plugins repo hyprpm add" → hypr.land/plugins listing, `hyprwm/hyprland-plugins` GitHub repo, DeepWiki mirror, confirming official status and install command sequence.
- websearch (MEDIUM, cross-checked): "hyprpm plugin ABI version mismatch Hyprland compositor upgrade" → GitHub issue #9101, Garuda Linux forum, openSUSE forum, a Fedora 43→44 personal blog post, all independently describing the same breakage pattern.
- websearch (MEDIUM, cross-checked 3+ sources): "Quickshell hyprland toplevel export screencopy live window preview" → quickshell.org docs (`ScreencopyView`, `Toplevel`), `dom0/qs-hyprview` and `Shanu-Kumawat/quickshell-overview` GitHub repos independently using this exact mechanism.
- websearch (MEDIUM): "GTK CSS keyframes / timing-function values" cross-checked against `docs.gtk.org/gtk4/css-properties.html` (WebFetch, LOW-per-tool-confidence but content matched independent websearch summary) confirming `ease/linear/ease-in/ease-out/ease-in-out/step-start/step-end/steps()/cubic-bezier()`; no source confirms `linear(<stops>)` support — treated as an open empirical question, not a negative claim asserted as fact.
- websearch (MEDIUM, cross-checked): "Hyprland wiki bezier animation config syntax" → Hyprland wiki animation pages (multiple version-pinned mirrors) confirming `bezier =`/`animation =` syntax.
- WebFetch (LOW, single source but internally consistent with the local `pacman -Si quickshell` dependency list): `git.outfoxxed.me/quickshell/quickshell` BUILD.md summary — required (`qt6base`, `qt6declarative`, `qtshadertools`), recommended (`qt6svg`), Qt-version-conditional (`qt6wayland` pre-6.10), and the private-API/must-rebuild-per-Qt-release caveat.
- websearch (MEDIUM, cross-checked): "Caelestia dots quickshell matugen colors.json Colours.qml singleton" → DeepWiki mirror of `caelestia-dots/shell` (2 pages: theming system, wallpaper/color management) describing the `.qml`-singleton matugen-output pattern.
- websearch (MEDIUM, cross-checked): "Quickshell Pipewire/NetworkManager/Bluetooth QML bindings" → quickshell.org module-listing and per-type doc pages (`Quickshell.Services.Pipewire`, `Quickshell.Networking`, `Quickshell.Bluetooth`) confirming native binding existence and rough API shape.
- Existing repo context (HIGH confidence, primary source): `/home/aorus/dotfiles/.planning/PROJECT.md` — v3.0 milestone scope, constraints, out-of-scope boundary, and prior Key Decisions (BAR-02 evidence-first precedent, contract.json single-source-of-truth pattern, per-surface `@import`-not-copy convention) all directly informed the recommendations above.

---
*Stack research for: v3.0 Quickshell Foundation & Motion Language milestone*
*Researched: 2026-07-26*
