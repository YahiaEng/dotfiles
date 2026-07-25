# Research Summary: v3.0 Quickshell Foundation & Motion Language

**Project:** Personal Arch + Hyprland dotfiles — adding a Quickshell/QML shell layer and a spring-physics motion pipeline
**Domain:** Cross-toolkit motion system + QML shell composition on an existing, mature Hyprland 0.56.0 rice
**Researched:** 2026-07-26
**Confidence:** HIGH for stack (verified against this machine via `pacman -Si`, direct repo inspection); MEDIUM for features (source-read two flagship rices, end-4 and Caelestia); MEDIUM-HIGH for architecture (direct precedent in existing AGS pattern + deepwiki of reference rices); MEDIUM for pitfalls (mostly local verification, some web-sourced behavioral claims flagged for local testing)

## Executive Summary

This milestone adds a native QML/Quickshell shell layer to an existing Hyprland desktop that keeps every existing surface (waybar, swaync, SwayOSD, wleave, walker/elephant, AGS) running throughout. **The single most impactful correction from research: Quickshell 0.3.0 is now in Arch's official `extra` repo (not AUR-only), eliminating the reproducibility risk that would have been the biggest blocker; simply `pacman -S quickshell` and its Qt6 dependencies, both of which are already installed on this machine from AGS.**

The recommended approach is **additive-only coexistence**: build new QML surfaces (dashboard drawer, audio/wifi/bluetooth panels, workspace overview, ambient wallpaper) alongside existing GTK/Hyprland/bash surfaces, reusing their backing data (MPRIS, PipeWire, NetworkManager, BlueZ) rather than reimplementing. The motion system departs from both reference rices (which use Material Design 3 Expressive tokens, duration+bezier, not literal spring physics) — this project pursues spring-mass-stiffness-damping as the source of truth, compiled to fitted cubic-beziers for Hyprland and sampled keyframes for GTK4 CSS, with full native physics passthrough to QML. This is a step *beyond* the flagship references, not parity with them, and requires explicit validation that the fitted-curve approach delivers perceptual gains over the proven MD3-token baseline.

**Key risk:** the hyprexpo plugin (a source-compiled Hyprland plugin with version-coupling fragility) is rejected in favor of Quickshell's native `ScreencopyView` + Hyprland's built-in `hyprland-toplevel-export-v1` protocol for the workspace overview — zero additional packages, no compiler toolchain, no rebuild-on-upgrade debt. Three researchers independently converged on this finding. The motion pipeline's fitting step (spring to cubic-bezier) is lossy by design — single-point overshoot can be captured, but multi-oscillation/ring-down behavior cannot — requiring a human side-by-side render gate per retrofitted surface to validate the fidelity loss is acceptable.

---

## Key Findings

### Recommended Stack

**Core:** Quickshell 0.3.0-2 from Arch `extra` (official package, not AUR), Qt6 base/declarative/svg/wayland (all already installed), plus existing services already running on this machine: PipeWire/WirePlumber (audio), NetworkManager 1.58 (wifi), BlueZ 5.87 (bluetooth), hyprland-protocols (built into Hyprland 0.56.0). **No hyprexpo plugin.** Instead, `hyprland-toplevel-export-v1` (a Wayland protocol the compositor natively implements) + Quickshell's `ScreencopyView`/`ToplevelManager` built-in types, confirmed working in end-4 and a third-party quickshell-overview reference implementation.

**Supporting:** matugen (already deployed for color theming) extends with new QML/GTK4 motion templates. A new `theme-engine/lib/motion.sh` Python-backed build step samples spring curves and fits beziers (Hyprland-target only) — one render target per surface, consumed live from `~/.local/state/theme/`, never copied, matching this repo's existing contract-and-render pattern. This is mechanically identical to color rendering (all three targets consume from the same source manifest) but differs in frequency (motion tokens are hand-authored, theme-invariant; colors are wallpaper-driven, re-rendered per theme switch).

**Confidence:** HIGH for Quickshell's official-repo status and Qt6 deps (verified locally). MEDIUM for the exact matugen template shapes and motion.sh implementation (confirmed as the right architectural pattern, but Python-based fitting algo is new code this repo hasn't written yet). LOW for whether Quickshell's `JsonAdapter` auto-propagates property changes through bindings with zero explicit reload code (Quickshell docs claim it does; must verify empirically in Phase 11).

### Expected Features

**Must have (v3.0 launch):**
- Dashboard drawer: calendar + quick-toggle grid (reusing BAR-05) + compact media widget (AGS backend) + system resources
- Bluetooth panel: device list + connect/disconnect + "Details" escape hatch to blueman
- Wifi panel: scan/list/connect + password prompt + "Details" escape hatch to nm-connection-editor
- Per-app volume mixer: native Pipewire service + icon lookup from walker/elephant
- Motion language: MD3-Expressive tokens (proven fallback) + spring-physics source of truth (differentiator)

**Should have (v3.0 stretch):**
- Workspace overview: click-to-focus grid with live thumbnails via `ScreencopyView`
- Drag-to-move windows between workspaces
- Weather widget (isolate as own vertical slice due to external API dependency)

**Defer / cut candidate (Phase 17):**
- Animated/video wallpaper
- Dynamic cursor (hyprpm plugin)
- Overview type-to-search
- Caelestia-style 4-tab swipeable dashboard

### Architecture Approach

Extend the existing theme-engine pattern to include motion tokens. One `quickshell/` stow package with `shell.qml` (entry point), `services/{Colors,Motion,Config,GlobalStates}.qml` (singletons), `modules/{Dashboard,AudioMixer,Connectivity,Overview}/`, and `components/`. Colors flow: matugen → `quickshell-colors.json` → `Colors.qml` singleton watching `~/.local/state/theme/` via `FileView`. Motion flow: hand-authored `motion-tokens.json` → `motion.sh` renders to three targets (QML passthrough, GTK4 keyframes, Hyprland bezier fit). QML surfaces bind from singletons; GTK/Hyprland consume compiled targets. New surfaces claim disjoint `WlrLayershell.namespace` entries, default to `exclusiveZone: 0` (overlay-only). D-Bus readers are read-only (multiple safe); writers coordinate with SwayOSD (hardware keys), swaync (notifications), playerctld (MPRIS).

### Critical Pitfalls & Prevention

1. **Quickshell input/focus failure (Pitfall 1, eww recurrence):** Phase 11 viability gate with human-clickable button, text field, outside-click dismiss. Must work on 0.56.0 before Phase 11 passes. Gate has STOP authority.

2. **Layer-shell exclusive-zone conflicts (Pitfall 2):** New surfaces default to `exclusiveZone: 0`. Check `hyprctl layers -j` before adding any non-zero zones. Add `layer-doctor` assertion.

3. **D-Bus double-handling (Pitfall 3):** MPRIS readers use same `playerctld` proxy; swaync stays sole notification daemon; SwayOSD owns hardware keys; QML panels call same APIs on click. Pre-flight: `busctl --user list | grep -c freedesktop.Notifications` must equal 1.

4. **Spring-to-bezier fidelity loss (Pitfall 6):** Single cubic-bezier cannot express multi-oscillation. QML gets native physics; GTK4 gets sampled keyframes or bezier fit; Hyprland gets bezier fit only. **Human side-by-side render gate per surface is mandatory.**

5. **Hyprexpo plugin ABI + install fragility (Pitfall 4):** Treat hyprexpo as optional. If built, make `install.sh` step non-fatal (warn), pin tested-compatible commit, provide `hyprland-toplevel-export-v1` fallback. No compiler toolchain requirement.

---

## Implications for Roadmap

Sketched order is directionally correct (11 → 12 → 13 → 14 → 15 → 16 → 17). Two corrections:

**Correction 1:** Phases 13 and 14 are independent branches (both depend only on 12); could be parallelized if schedule demands, but keeping 13 before 14 is the right default (cheaper to validate motion-fitting on existing surfaces before building new QML UI).

**Correction 2:** Phase 16's **research question** (hyprexpo vs. protocol) should be investigated during/after Phase 11 (feasibility gate, not execution complexity). Keep the build at position 16, but resolve research early so roadmap can decide Phase 16's scope while Phases 12-15 are in flight.

### Phase Structure

**Phase 11: Quickshell Viability Gate** — Throwaway `PanelWindow` with pointer/keyboard/focus/dismiss test. Human must click button, type field, dismiss via click-outside. Must pass on 0.56.0 before anything else. **Authority to STOP.**

**Phase 12: Token Pipeline (Colour + Motion)** — Extend matugen with `quickshell-colors.json`. Create hand-authored `motion-tokens.json` (mass/stiffness/damping). Implement `motion.sh` render to three targets. Wire `Colors.qml` and `Motion.qml` singletons. Add `motion-lint` gate. Decide and document fidelity ceiling, reduced-motion knob.

**Phase 13: Motion Retrofit** — Apply tokens to waybar/swaync/wleave/walker/AGS/Hyprland. Human side-by-side render gate per surface (QML vs. fitted-curve). Multi-day dogfooding check for high-frequency surfaces.

**Phase 14: Dashboard Drawer** — Calendar + toggle-grid (reusing BAR-05) + media widget (reusing AGS/MPRIS) + system resources. Establish single-scalar entrance/exit pattern. Register `quickshell` in `stow.sh`.

**Phase 15: Audio + Connectivity Panels** — Bluetooth (LOW-MEDIUM), Wifi (MEDIUM-HIGH), per-app mixer (MEDIUM). One reusable dialog pattern. "Details" escape hatches to blueman/nm-connection-editor/pavucontrol.

**Phase 16: Workspace Overview** — Click-to-focus grid with live thumbnails via `ScreencopyView`. Research `hyprland-toplevel-export-v1` permission system. If performance/permissions block, becomes next cut-candidate after 17.

**Phase 17: Ambient Extras** — Video wallpaper (`mpvpaper` + thumbnails, low effort) and dynamic cursor (hyprpm plugin, lowest effort, plugin-ABI risk). **First thing cut if milestone runs long.** Can defer to v4.0.

### Phase Ordering Rationale

- Phase 11 is hard gate: everything depends on Quickshell working; cheap to retry if it fails, expensive to discover failure later
- Phase 12 blocks 13-17: all require color/motion render targets
- Phase 13 before 14: cheaper to validate motion-fitting on existing surfaces before building new QML UI
- Phase 14/15/16 sequence: toggle grid before panels (panels expand toggles); coordinate D-Bus access before most complex panel
- Phase 17 last: independent, correct place for cut-candidate

### Research Flags

**Phases needing deeper research during planning:**
- **Phase 11:** `JsonAdapter` property-binding propagation; exact `WlrLayershell.keyboardFocus` + `mask` mechanics on 0.56.0
- **Phase 12:** GTK4 CSS `linear(<stops>)` support (must test empirically; default: unsupported, single-bezier fallback)
- **Phase 15:** `Quickshell.Networking` API completeness (D-Bus calls vs. `nmcli` wrapper)
- **Phase 16:** Hyprland `PERMISSION_TYPE_SCREENCOPY` requirement and `noscreenshare` window-rule semantics

**Phases with standard patterns (research-phase not needed):**
- **Phase 13:** Motion retrofit is mechanical application of Phase 12 tokens
- **Phase 14/15:** Dialog/panel patterns established in end-4/Caelestia, directly copyable
- **Phase 17:** Both features use well-documented existing tools

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | Quickshell 0.3.0-2 verified in Arch `extra` via `pacman -Si`; Qt6 deps all installed; supporting services confirmed; no hyprexpo needed |
| Features | HIGH (flagship), MEDIUM (execution) | Both flagships source-read; complexity flagged where native bindings absent (wifi D-Bus) |
| Architecture | MEDIUM-HIGH | Extends proven AGS pattern; Quickshell behavioral details are single-source, need empirical validation Phase 11 |
| Pitfalls | MEDIUM | Hyprland 0.56.0 verified locally; plugin-ABI/D-Bus/fitting pitfalls web-sourced, need local testing |

**Overall: MEDIUM-HIGH**

Stack and feature-shape solid; architecture extends proven patterns; main uncertainty is Quickshell behavioral details (Phase 11 settles) and GTK4 CSS `linear()` support (Phase 12 tests).

### Gaps to Address

1. **Quickshell's `JsonAdapter` auto-propagation:** Must verify empirically Phase 11 that file changes trigger property re-evaluation with zero explicit reload code
2. **GTK4 CSS `linear()` easing:** Test empirically Phase 12 with throwaway CSS; default assumption: unsupported
3. **NetworkManager D-Bus API in Quickshell:** Confirm `Quickshell.Networking` covers "list + connect + password" before Phase 15 commits to in-QML vs. `nmcli`
4. **Hyprland screencopy permission system:** Verify permission grant + `noscreenshare` window-rule behavior before Phase 16
5. **Spring-to-bezier fidelity perception:** Validate empirically Phase 13 during side-by-side render gate
6. **Quickshell reduced-motion accessibility:** No precedent found; design knob Phase 12, validate Phase 13+

---

## Sources

**PRIMARY (HIGH — direct system verification):**
- This machine: `pacman -Si quickshell`, `pacman -Qi qt6-*`, `hyprctl version`
- Repo inspection: `theme-engine/contract.json`, `ags/.config/ags/app.tsx`, `hypr/.config/hypr/config/animations.conf`, `stow.sh`

**SECONDARY (MEDIUM — source-read reference projects):**
- `end-4/dots-hyprland` (GitHub API + raw file fetch): QML dashboard/panels/overview implementation
- `caelestia-dots/shell` (GitHub API + raw file fetch): QML animation system, singleton pattern
- Quickshell official docs (`quickshell.org/docs`): config model, `FileView`/`JsonAdapter`, `PanelWindow`/`WlrLayershell`, native service modules

**TERTIARY (MEDIUM, cross-checked 2+ sources):**
- Hyprland wiki + standards: `hyprland-toplevel-export-v1` protocol, native support
- `hyprwm/hyprland-plugins` repo + GitHub issues + forum reports: hyprexpo plugin-ABI coupling, reproducibility risk
- CSS Easing + GTK docs + spring-physics articles: fidelity limits, CSS capabilities

**TERTIARY (LOW, single source or inference):**
- Quickshell GitHub issues, end-4 issues: behavioral details (hot-reload, multi-monitor, memory)
- Hyprland permissions wiki + `hyprctl`: screencopy permission system
- playerctl/bluez/NetworkManager D-Bus docs: multi-client behavior

---

*Research completed: 2026-07-26*
*Ready for roadmap: yes*
*Synthesized from: STACK.md, FEATURES.md, ARCHITECTURE.md, PITFALLS.md*
