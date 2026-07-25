# Phase 11: Quickshell Viability Gate - Research

**Researched:** 2026-07-26
**Domain:** Quickshell (QtQuick/QML desktop-shell toolkit) on Hyprland 0.56.0; Hyprland layer-shell/keybind/permission internals; bash gate-script repair
**Confidence:** MEDIUM-HIGH (machine-verified facts are HIGH; QML API facts are version-matched official docs, MEDIUM; a few CLI/IPC behaviors could not be confirmed because the binary is not yet installed, LOW — flagged explicitly below)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** The gate probe graduates into the permanent shell root rather than being deleted. `quickshell/` ships a minimal always-on Quickshell instance that autostarts; the interactive test bits stay behind a keybind/CLI as a rerunnable gate, matching how `theme-doctor`, `theme-parity`, `keybind-doctor`, `waybar-equivalence-check` and `waybar-design-lint` already work in this repo. Reversibility: reversible — one QML file and one autostart line.
- **D-02:** The always-on root is headless — it renders nothing in daily use. No visible surface, no liveness widget, no idle test panel. The probe `PanelWindow` is summoned on a keybind only when re-running the proof.
- **D-03:** The probe is one panel carrying all instrumentation — a click-counter button, a focusable text field, a label bound through `FileView`/`JsonAdapter` to a hand-editable JSON file, and the screen name it is rendering on.
- **D-04:** The probe is deliberately unstyled — QtQuick defaults only, no colours authored at all. Explicitly rejected: reading the palette from `~/.local/state/theme/` now.
- **D-05:** A new `quickshell-doctor` script is the home for both the mechanical coexistence assertions and the dated pass/fail record. Runs mechanical checks automatically (`hyprctl layers -j` no second non-zero exclusive-zone claimant, `busctl --user list` exactly one `org.freedesktop.Notifications` owner, one-step-per-press volume/brightness, `keybind-doctor` clean, shell process alive), summons the probe for human checks, appends a dated PASS/FAIL line to an evidence artifact. Explicitly rejected: folding into `theme-doctor`; a one-shot manual record.
- **D-06:** Autostart goes through a thin guarded launcher script, `quickshell-launch.sh`, mirroring `waybar-launch.sh`: verifies binary and config exist, launches under `uwsm app --`, logs startup/exit to `~/.cache`. Explicitly rejected: plain `exec-once`; a systemd user unit.
- **D-07:** Multi-monitor (QS-03) is proven with a Hyprland headless output (`hyprctl output create headless`). Caveat that MUST be recorded in the evidence artifact: this proves event handling, not real DP/HDMI EDID negotiation. This host has exactly one physical monitor (`DP-1`, 2560x1440@165).
- **D-08:** Suspend/resume is a manual, hand-driven gate item — one `systemctl suspend` + wake during the phase, probe summoned before and after, result written as a dated line.
- **D-09:** On gate failure, the milestone stops and v3.0 is rescoped to GTK4/AGS — not a hard total stop. v3.0 rescopes to Phase 12/13 and drops Phases 14-17. Reversibility: one-way.
- **D-10:** QS-02 is the sole stop-trigger (pointer/keyboard/click-outside dismiss). Everything else is record-and-continue: hot-reload gap -> `theme-apply` fan-out hook; exclusive-zone/D-Bus collision -> config fix; screencopy failure -> rescopes Phase 16 only; headless-output quirk -> test-harness artifact, not a defect.
- **D-11:** Registration lands immediately, and a failed gate reverts the whole commit set as one unit. `quickshell/`, `stow.sh` and `install.sh` land together in the first commit, before the human clicks. Explicitly rejected: gating registration behind an `install.sh` flag.
- **D-12:** The screencopy probe is feasibility-only. Exercise one live multi-window `ScreencopyView` capture, confirm real content, record the exact `PERMISSION_TYPE_SCREENCOPY` mechanics and permission stanza verbatim. The frame/CPU budget stays with OVER-04 in Phase 16 — do not pull that measurement forward, do not pre-commit to Phase 16's fallback here.
- **D-13:** If `FileView`/`JsonAdapter` propagation needs reload involvement (open question #1), that is NOT a stop. Record the finding, add a quickshell reload step to `theme-apply`'s existing single reload fan-out. Explicitly rejected: treating it as a Phase 11 FAIL; open-ended QML workaround hunting.
- **D-14:** Parse the plain-text `hyprctl binds` output; drop `-j` entirely. Hyprland 0.56.0's JSON serializer is field-misaligned, not merely malformed. Add a guard that fails loudly if the text format itself ever changes shape; record in the evidence artifact why `-j` was abandoned. Reversibility: reversible, but see D-15.
- **D-15:** The roadmap's Phase 11 success criterion 4 must be amended — it currently reads "a repaired `keybind-doctor` parses `hyprctl binds -j` on 0.56.0". D-14 honors the criterion's intent over its letter; the planner should treat the ROADMAP wording update as in-scope work for this phase.
- **D-16:** Quickshell-claimed shortcuts are discovered by querying the live registration at runtime, not by reading source. The exact query mechanism must be verified against the installed quickshell 0.3.0, not assumed.
- **D-17:** Fallback if quickshell 0.3.0 exposes no runtime query: a declared manifest, with the gap recorded. `quickshell/` ships an explicit list of chords it owns; `keybind-doctor` cross-checks it against Hyprland's registered set. Explicitly rejected: source-grepping the QML; deferring Quickshell-side detection to Phase 14.
- **D-18:** The repaired duplicate-chord detection is proven with a poisoned fixture — feed `keybind-doctor` a throwaway `keybinds.conf` containing a colliding chord, confirm it FAILS, then confirm it passes on the real config.
- **D-19:** Minimal root now; structure is earned per phase. `shell.qml` root plus one `modules/` directory holding the probe. Accepted risk: Phase 14 may do a small reorganization.
- **D-20:** Shell state lives in `~/.local/state/quickshell/` — its own state directory, separate from `~/.local/state/theme/`. Explicitly rejected: `~/.local/state/theme/`; `~/.config/quickshell/` inside the stow package.
- **D-21:** Layer-shell convention, established here and inherited by Phases 14-16: overlay layer, `exclusiveZone: 0`, distinct `quickshell-*` layer namespace that no existing client uses. The `hyprctl layers -j` assertion becomes a standing `quickshell-doctor` check. Explicitly rejected: the `top` layer; deciding per surface. Reversibility: costly — four later phases build on this convention.

### Claude's Discretion

- Exact QML file/module naming within the minimal `shell.qml` + `modules/` structure (D-19).
- Which keybind summons the probe — must not collide with the existing 78 binds, and `keybind-doctor` proves it.
- The evidence artifact's exact filename and internal format, provided it carries dated PASS/FAIL lines per criterion. Precedent to follow: `08-BAR-02-EVIDENCE.md`.
- Log file path and rotation behavior for `quickshell-launch.sh` under `~/.cache`.
- Whether `quickshell-doctor` lives in `hypr/.config/hypr/scripts/` alongside `keybind-doctor` or in the new `quickshell/` package — pick whichever keeps the gate runnable on a machine where the gate has failed.

### Deferred Ideas (OUT OF SCOPE)

- Real second-display hotplug verification — D-07 uses a virtual headless output; a one-time real DP/HDMI hotplug test was considered and set aside; worth a dated line in the evidence artifact if a second display becomes available, not a blocker.
- Frame/CPU budget for live multi-window screencopy — explicitly Phase 16's OVER-04, deliberately not pulled forward (D-12).
- QML palette render target and motion tokens — Phase 12 owns the token schema and the `contract.json` QML entry; D-04 deliberately leaves the probe unstyled.
- A `-j` auto-switch-back probe in `keybind-doctor` — self-healing once upstream Hyprland emits valid aligned JSON. Considered and rejected for now.
- Reorganizing `quickshell/` into an end-4/Caelestia-style tree — D-19 defers structure until surfaces earn it; Phase 14 is the natural point to revisit.
- Any visible Quickshell surface — D-02 ships nothing visible. Phase 14's dashboard drawer is the first real surface.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| QS-01 | `install.sh` installs Quickshell and its Qt6 dependencies from the official Arch `extra` repo, and `stow.sh` deploys the `quickshell/` package — both registered in the same commit that creates the package | Package Legitimacy Audit + Standard Stack: confirmed `extra/quickshell 0.3.0-2` not yet installed, full `Depends On` closure enumerated, only one new `install.sh` line needed (pacman auto-resolves the rest); `stow.sh`'s 20-entry `PACKAGES` array and insertion point identified |
| QS-02 | A human can click a button, type into a text field, and dismiss by clicking outside on a Quickshell layer-shell surface running on Hyprland 0.56.0 — proven on a throwaway `PanelWindow` before any feature is built, with authority to stop the milestone | Architecture Patterns 1 & 2: exact `PanelWindow`/`WlrLayershell`/`WlrKeyboardFocus`/`HyprlandFocusGrab` QML API, version-matched to installed 0.3.0, with worked examples |
| QS-03 | Quickshell surfaces render correctly across all connected monitors and survive monitor hotplug | Environment Availability + Verification: `hyprctl output create/remove headless` confirmed working live on this exact build |
| QS-04 | Editing Quickshell config hot-reloads the running shell without a manual restart | Architecture Pattern 3: `FileView`/`JsonAdapter`/`watchChanges` documented pattern answering open question #1 directly |
| QS-05 | The Quickshell shell autostarts with the session and runs alongside waybar, swaync, SwayOSD, wleave, AGS and walker with no layer-namespace collision, no exclusive-zone layout shift, and no duplicated global keybind | Common Pitfalls 1 & 2 + Repo integration points: corrected `hyprctl layers -j`/`monitors -j` schema for the mechanical check; existing namespace inventory (no collision with `quickshell-*`); 78-bind inventory with a confirmed-free chord (`G`) |
| QS-06 | No two processes double-handle the same event source — MPRIS, PipeWire, hardware media/brightness keys and `org.freedesktop.Notifications` each retain a single owner | Sources (Primary): `busctl --user list` confirmed single `org.freedesktop.Notifications` owner (swaync); `swayosd-client --help` confirmed send-only CLI, informing the mechanical design for one-step-per-press |
| MAINT-01 | `keybind-doctor` correctly parses `hyprctl binds -j` on Hyprland 0.56.0 (amended per D-15 to plain-text parsing) | Common Pitfalls 2 + full `keybind-doctor` source read: exact field-misalignment bug reproduced, plain-text block format and variable header-token finding documented |
</phase_requirements>

## Summary

Quickshell `0.3.0-2` is confirmed **not currently installed** on this machine but is available, unmodified, in the official Arch `extra` repository — QS-01's package-name risk is fully closed. Its own `pacman -Si` dependency closure means `install.sh` needs exactly **one** new `PACMAN_PKGS` line (`quickshell`); pacman's resolver pulls every Qt6/cpptrace/jemalloc/etc. dependency automatically, and `qt6-wayland` + `pipewire` are already present in `install.sh` for unrelated reasons. This is a materially simpler install-side change than QS-01's wording ("installs quickshell and its Qt6 dependencies") implies — there is nothing to hand-enumerate.

The load-bearing QML surface for QS-02 (the sole stop-trigger) is `PanelWindow` + its `WlrLayershell` attached object: `WlrLayershell.keyboardFocus` (an enum: `None` / `OnDemand` / `Exclusive`) is what makes a text field receive typed input on a layer-shell surface, and `focusable: true` on `PanelWindow` is a convenience alias for it. Click-outside dismiss is `HyprlandFocusGrab` (`Quickshell.Hyprland`), not a full-screen catcher — it grants exclusive input to a whitelisted window list and fires a `cleared()` signal when the compositor releases the grab, which is exactly the click-outside-to-dismiss primitive the probe needs. Both are documented, with worked examples, at the exact installed version (`quickshell.org/docs/v0.3.0/...`).

Two findings materially change what the planner should write. First, **`FileView`/`JsonAdapter` can propagate a hand-edited JSON change with zero `reload.sh` involvement** using a fully documented `watchChanges: true` + `onFileChanged: reload()` + `onAdapterUpdated: writeAdapter()` pattern — this answers open question #1 directly and in the affirmative, so D-13's fallback branch is very likely not needed (still worth proving live, not just trusting the doc). Second, **quickshell 0.3.0's `GlobalShortcut` type has no documented runtime-introspection API** (no IPC subcommand, no D-Bus interface, no manager singleton) — this definitively selects D-17's declared-manifest fallback over D-16's live-query preference; the planner should write the manifest branch directly rather than spike the query path first. Third, the roadmap's phrase **"`ecosystem.conf` stanza" does not correspond to any real file** — Hyprland 0.56.0's screencopy permission model is a `permission = <path-regex>, screencopy, <allow|deny|ask>` config keyword plus an `ecosystem { enforce_permissions = ... }` config *category* (both declared in ordinary `.conf` files, most naturally a new sourced module in this repo's existing `hypr/.config/hypr/config/` split), and — critically — **permission grants are NOT hot-reloadable; they require a full Hyprland restart to take effect**, a constraint the plan must budget for explicitly since this repo's compositor is otherwise always live during phase work.

Machine verification also surfaced a schema gap in D-05's own success-criterion wording: `hyprctl layers -j` on 0.56.0 does **not** expose an exclusive-zone field per layer client — it only reports `address/x/y/w/h/alpha/namespace/pid`, grouped by shell-layer level (0-3: background/bottom/top/overlay), not by screen edge. The actual exclusive-zone reservation is visible on `hyprctl monitors -j`'s `reserved` array (`[left, top, right, bottom]`-style pixel counts; this machine currently shows `[0, 46, 0, 0]` for waybar's top reservation). `quickshell-doctor`'s mechanical check needs to combine both commands, not read `layers -j` alone as the roadmap phrasing suggests.

**Primary recommendation:** Build the probe on `PanelWindow` + `WlrLayershell.layer: WlrLayer.Overlay` + `exclusiveZone: 0` + a distinct `namespace` + `WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand` (escalate to `Exclusive` only if `OnDemand` proves insufficient for the text field in the live human test) + `HyprlandFocusGrab` for click-outside dismiss + the documented `FileView`/`JsonAdapter`/`watchChanges` pattern for the hand-edit criterion — all of which are real, version-matched, worked APIs, not assumptions. Repair `keybind-doctor` by parsing `hyprctl binds`' plain-text block format (confirmed correct on this exact build, 78 bind blocks, blank-line-delimited) with a variable header token (`bind`, `bindl`, `bindle`, `bindr`, `bindm`, …verified to vary — do not assume a constant `"bind"` literal). Correct the roadmap's screencopy-permission phrasing before implementing it.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Pointer/keyboard/focus/dismiss probe | Browser-equivalent (Quickshell QML client) | Compositor (Hyprland layer-shell + focus-grab protocol) | The QML client renders and handles input; Hyprland's `zwlr_layer_shell_v1` + `hyprland_focus_grab_v1` protocols are what actually grant/revoke keyboard focus and the click-outside signal — this is a two-tier proof by construction, which is why QS-02 must be tested live, never assumed from docs alone |
| Multi-monitor / hotplug / suspend-resume | Compositor (Hyprland monitor management) | Quickshell (per-`ShellScreen` surface creation) | Hyprland owns the physical/virtual output lifecycle (`hyprctl output create headless`, real hotplug); Quickshell's `Quickshell.screens` model reacts to that lifecycle — the client-side surface creation is what's actually under test, but it cannot be exercised without the compositor event first |
| Config hot-reload / FileView JSON sync | Quickshell (QML client, in-process) | — | Both mechanisms (QML source hot-reload and `FileView.watchChanges`) are entirely internal to the Quickshell process; no compositor or external daemon involvement — this is the one criterion that is purely single-tier |
| GlobalShortcut registration/introspection | Compositor (`hyprland_global_shortcuts_v1` protocol, Hyprland-side registry) | Quickshell (registers, cannot query) | Hyprland is the actual keeper of "what's registered" (`hyprctl globalshortcuts` reads Hyprland's own state); Quickshell 0.3.0 has no read-back API, so `keybind-doctor`'s cross-check is structurally a compositor-side-only proof for the Quickshell half (declared manifest instead) |
| D-Bus service ownership (Notifications) | System/session bus (dbus-broker) | — | `org.freedesktop.Notifications` ownership is arbitrated entirely by the session D-Bus daemon; `busctl --user list` is querying the bus, not any client |
| Screencopy capture + permission | Compositor (Hyprland screencopy/toplevel-export protocols + permission manager) | Quickshell (`ScreencopyView` consumer) | The permission grant, the protocol negotiation, and the actual frame buffer all originate compositor-side; Quickshell is a protocol client only — this is why the permission stanza belongs in Hyprland config, not any Quickshell-side file |
| Autostart / launcher supervision | Session (uwsm scope + `autostart.conf`) | Quickshell (the supervised process) | Matches every other daemon in this repo — `quickshell-launch.sh` is a session-tier concern, mirroring `waybar-launch.sh` |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `quickshell` | 0.3.0-2 (Arch `extra`) [VERIFIED: pacman -Si on this machine] | The shell toolkit itself | Official Arch package, not AUR; confirmed available but **not yet installed** on this machine [VERIFIED: `pacman -Qi quickshell` → "package not found"] |

### Supporting (auto-resolved by pacman — no explicit install.sh entries needed beyond `quickshell` itself)

| Library | Version (on this machine already) | Purpose | Already in install.sh? |
|---------|---------|---------|--------------|
| `qt6-base` | 6.11.1-1 [VERIFIED: pacman -Qi] | Qt6 core | Not explicitly listed, but already present — pulled in transitively today by KDE-family packages (kirigami, sddm, etc.) already on this host. **On a genuinely fresh install these would NOT be present** unless pacman auto-resolves them as a hard dependency of `quickshell` itself — confirmed they are (`pacman -Si quickshell` lists `qt6-base` in `Depends On`) |
| `qt6-declarative` | 6.11.1-3 [VERIFIED] | QML engine | Same — hard dependency of `quickshell`, auto-resolved |
| `qt6-svg` | 6.11.1-1 [VERIFIED] | SVG rendering (icons) | Same — hard dependency, auto-resolved |
| `qt6-wayland` | 6.11.1-1 [VERIFIED] | Qt Wayland platform plugin | **Already explicitly in `install.sh` `PACMAN_PKGS`** (`# Qt Wayland` section) for unrelated reasons — no change needed |
| `cpptrace` | 1.0.4-2 [VERIFIED: pacman -Si, confirmed NOT installed on this host] | Stack-trace library | Hard dependency of `quickshell` (`Depends On: cpptrace libcpptrace.so=1-64 ...`) — pacman resolves it automatically on `pacman -S quickshell`; genuinely the one library on this exact host that quickshell's install will newly pull in, but it needs no explicit `install.sh` line since pacman handles transitive deps |
| `libpipewire` | 1:1.6.8-1 [VERIFIED] | PipeWire client lib (screencopy/audio path) | `pipewire`/`pipewire-pulse`/`wireplumber` already explicit in `install.sh` (`# Audio` section) |
| `jemalloc`, `libdrm`, `mesa`, `polkit`, `wayland`, `hicolor-icon-theme`, `libglvnd` | all already present [VERIFIED] | Runtime deps | Already satisfied by the existing desktop stack; no action needed |

**Installation (the only genuinely new line):**
```bash
# install.sh PACMAN_PKGS — add alongside the existing Qt Wayland section,
# or its own small "# Quickshell" comment block:
quickshell
```
Everything else in the `Depends On` closure (`pacman -Si quickshell`) is resolved automatically by `pacman -S`. **Do not hand-enumerate the Qt6 closure in `install.sh`** — that would be redundant with pacman's own resolver and a source of future drift if quickshell's dependency list changes upstream.

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `HyprlandFocusGrab` for click-outside dismiss | A full-screen transparent `PanelWindow` catching all clicks, closing on any click not inside the content region | `HyprlandFocusGrab` is the documented, purpose-built primitive with a `cleared()` signal — a catcher window is more code, needs its own hit-testing, and still needs to coexist with the real content window's own z-order; no reason to hand-roll this |
| `WlrKeyboardFocus.OnDemand` | `WlrKeyboardFocus.Exclusive` | `Exclusive` guarantees focus but "locks out all other windows" per the docs — acceptable for a modal probe, but Phase 14's drawer (which inherits this convention) should default to `OnDemand` unless a specific reason to lock out all other input arises. The live human test in this phase should try `OnDemand` first and only escalate if text input isn't reliably captured |
| A declared `GlobalShortcut` manifest (D-17) | Live introspection via IPC/D-Bus (D-16's stated preference) | Confirmed no such API exists in quickshell 0.3.0's `GlobalShortcut` documentation — this is not a preference call, it is what's available. Do not spend planning time speccing a D-16 spike; go straight to D-17 |

## Package Legitimacy Audit

This phase's only new package (`quickshell`) is an **Arch Linux official-repository package**, not an npm/PyPI/crates package — the npm-focused legitimacy-check seam does not apply to this ecosystem. Equivalent (and stronger) evidence was gathered directly:

| Package | Registry | Age | Maintainer | Source Repo | Verdict | Disposition |
|---------|----------|-----|------------|--------------|---------|-------------|
| `quickshell` | Arch `extra` (official, not AUR) [VERIFIED: `pacman -Si quickshell`] | Built 2026-06-05 (current `extra` snapshot) | Peter Jung (`ptr1337@archlinux.org`) — an established, trusted Arch Linux package maintainer | `git.outfoxxed.me/quickshell/quickshell` (upstream project's own Forgejo instance, linked directly from the pacman `URL` field) | OK | Approved — no AUR involvement, matches `AUR_PKGS`-is-not-needed per CONTEXT.md's verified facts |

**Packages removed due to `[SLOP]` verdict:** none.
**Packages flagged as suspicious `[SUS]`:** none.

## Architecture Patterns

### System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│ Session start (autostart.conf, exec-once)                           │
│   quickshell-launch.sh  ──guarded──▶  uwsm app -- quickshell -p ~/.config/quickshell
└───────────────────────────────┬───────────────────────────────────────┘
                                 │ process alive, headless (D-02: renders nothing)
                                 ▼
                  ┌──────────────────────────────┐
                  │ Quickshell process (shell.qml root)
                  │   modules/Probe.qml (not shown until summoned)
                  └───────┬──────────────────────┘
                          │ keybind (e.g. Super+Shift+G — unused chord, verified)
                          ▼
        ┌─────────────────────────────────────────────┐
        │ PanelWindow (probe surface)                   │
        │  WlrLayershell.layer: Overlay                 │
        │  WlrLayershell.namespace: "quickshell-probe"  │
        │  exclusiveZone: 0                              │
        │  WlrLayershell.keyboardFocus: OnDemand         │
        └───┬─────────────┬─────────────┬───────────────┘
            │              │             │
   click-counter    focusable       FileView + JsonAdapter
   Button           TextField       watchChanges: true
            │              │        onFileChanged: reload()
            ▼              ▼             ▼
     HyprlandFocusGrab (windows: [probe])
            │
            ▼ compositor clears grab on outside click
       cleared() signal → probe hides
                          │
                          ▼
       quickshell-doctor (rerunnable gate, separate script)
        ├─ hyprctl layers -j     → per-level namespace/pid listing
        ├─ hyprctl monitors -j   → `reserved` (actual exclusive-zone pixels)
        ├─ busctl --user list    → single org.freedesktop.Notifications owner
        ├─ keybind-doctor (repaired) → plain-text hyprctl binds parse + Quickshell manifest cross-check
        └─ process-alive check on quickshell-launch.sh's PID/log
                          │
                          ▼
        dated PASS/FAIL line appended to the evidence artifact
```

### Recommended Project Structure (D-19, minimal — do not seed more)
```
quickshell/
└── .config/quickshell/
    ├── shell.qml           # root — loads modules/Probe.qml behind a keybind, nothing rendered by default
    └── modules/
        └── Probe.qml       # the one instrumentation panel (D-03): button + text field + FileView label + screen-name label
```
`quickshell-doctor` itself is a **Claude's-discretion placement call** (D-05 canonical refs): put it in `hypr/.config/hypr/scripts/` alongside `keybind-doctor`/`theme-doctor` if the gate must be runnable even when the `quickshell/` package itself is the thing under test (recommended — a gate that lives inside the surface it's grading is the weaker design, and this repo's precedent (`keybind-doctor`, `theme-doctor`, `waybar-equivalence-check`) is uniformly `hypr/.config/hypr/scripts/`).

### Pattern 1: PanelWindow as a layer-shell probe surface
**What:** `PanelWindow` (from `Quickshell`) with its `WlrLayershell` attached properties (from `Quickshell.Wayland`) set for overlay layer, zero exclusive zone, a distinct namespace, and on-demand keyboard focus.
**When to use:** Any Quickshell surface this milestone that must not compete with waybar's reserved space (D-21's standing convention).
**Example:**
```qml
// Source: quickshell.org/docs/v0.3.0/types/Quickshell/PanelWindow/
//         quickshell.org/docs/v0.3.0/types/Quickshell.Wayland/WlrLayershell/
//         quickshell.org/docs/v0.3.0/types/Quickshell.Wayland/WlrKeyboardFocus/
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: probe
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "quickshell-probe"       // D-21: distinct namespace, no existing client uses this
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    exclusiveZone: 0                                  // D-21: never reserves space
    // anchors left unset -> centered floating-style panel is achievable via
    // margins/anchors combos; exact sizing is an implementation detail, not
    // a research finding
}
```
**Verification gap (LOW confidence, flag for the plan):** the official docs describe `focusable: true` on `PanelWindow` as "corresponding to" `WlrLayershell.keyboardFocus`, but do not state the exact mapped enum value. Setting `WlrLayershell.keyboardFocus` directly (as above) sidesteps that ambiguity entirely and is the more precise, unambiguous choice — prefer it over `focusable: true` in the probe.

### Pattern 2: HyprlandFocusGrab for click-outside dismiss
**What:** An input-focus grabber scoped to a whitelist of windows; the compositor clears it (and fires `cleared()`) when input activity outside the whitelisted windows dismisses it.
**When to use:** Any dismissible popup/panel this milestone (the probe now; Phase 14's drawer, Phase 15's panels, Phase 16's overview later).
**Example:**
```qml
// Source: quickshell.org/docs/v0.3.0/types/Quickshell.Hyprland/HyprlandFocusGrab/
import Quickshell
import Quickshell.Hyprland

PanelWindow {
    id: probeWindow
    HyprlandFocusGrab {
        id: grab
        windows: [ probeWindow ]
        active: true
        onCleared: probeWindow.visible = false   // click-outside dismiss
    }
}
```
**Note:** this type lives in `Quickshell.Hyprland` — it is Hyprland-specific, not a generic wlroots primitive. That is consistent with this repo's Hyprland-only scope, but worth stating plainly since some Quickshell code found in the wild targets Sway/river and won't have this import available.

### Pattern 3: FileView + JsonAdapter with zero external reload
**What:** A `FileView` watching a JSON file on disk, exposing its keys as QML properties via a nested `JsonAdapter`, propagating both directions without any external script.
**When to use:** The probe's hand-edited-JSON criterion (QS-04/criterion 2) and D-20's `~/.local/state/quickshell/` state pattern for every later phase.
**Example:**
```qml
// Source: quickshell.org/docs/v0.3.0/types/Quickshell.Io/FileView/
//         quickshell.org/docs/v0.3.0/types/Quickshell.Io/JsonAdapter/
import Quickshell.Io

FileView {
    id: probeState
    path: "/home/aorus/.local/state/quickshell/probe.json"  // D-20
    watchChanges: true
    onFileChanged: reload()          // picks up a hand-edit with NO reload.sh call
    onAdapterUpdated: writeAdapter() // if the probe itself ever writes back
    JsonAdapter {
        property string label: "unset"
    }
}
```
**This is the exact mechanism that answers open question #1.** It requires proving live (a human edits the file with a text editor while the probe is visible and confirms the label updates) — the documentation is unambiguous and version-matched, but D-13's own house rule ("record the limitation, take the workable path") means the plan should still execute this as a real test, not skip it because the docs look conclusive.

### Anti-Patterns to Avoid
- **Reading `focusable: true` as sufficient for guaranteed keyboard input:** the docs only say it "corresponds to" `WlrLayershell.keyboardFocus` without stating the exact enum value it maps to — set `WlrLayershell.keyboardFocus` explicitly instead of relying on the shorthand for the one property QS-02 lives or dies on.
- **Assuming `hyprctl layers -j` carries exclusive-zone data:** it does not, on this build (verified directly — see Common Pitfalls). Any mechanical check must read `hyprctl monitors -j`'s `reserved` array for that.
- **Assuming a literal `"bind"` header token in `hyprctl binds` plain-text output:** verified directly that the header token varies by bind-flag combination (`bind`, `bindl`, `bindle` observed on this exact build for a `bindel`-declared line) — a parser must treat the header as a variable "block-type" token, not strip a fixed literal.
- **Writing "ecosystem.conf" as a real file path anywhere in the plan or the evidence artifact:** it does not exist as a distinct file in Hyprland 0.56.0. The permission stanza is an ordinary `permission = ...` config keyword plus an `ecosystem { enforce_permissions = ... }` category, both go in a normal sourced `.conf` file.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Click-outside dismiss | A full-screen invisible catcher window + manual hit-testing | `HyprlandFocusGrab` | Purpose-built, documented, one signal (`cleared()`), no z-order/hit-test bugs to own |
| Live JSON file sync | A file-watcher poll loop + manual JSON.parse on a timer | `FileView.watchChanges` + `JsonAdapter` | Built-in, atomic-write-safe (`atomicWrites: true` by default), no polling |
| Keyboard focus mode | Reinventing focus semantics via visibility toggles | `WlrLayershell.keyboardFocus` (`None`/`OnDemand`/`Exclusive`) | This *is* the wlroots layer-shell keyboard-interactivity protocol surface — there is no lower-level correct alternative in QML |

**Key insight:** every QS-02/QS-03/QS-04 primitive needed for this phase already exists as a first-class, documented Quickshell 0.3.0 QML type. The risk in this phase is not "does the API exist" (it does, cleanly) — it is "does it *actually work end-to-end on this Hyprland build*," which is precisely why QS-02 is a human-clicked live test and not a docs-reading exercise.

## Runtime State Inventory

Not a rename/refactor/migration phase (this phase creates a new `quickshell/` package and adds new state; it does not rename or retire anything) — this section is not required by the trigger condition, but the closest analogous audit (fresh-state creation, not migration) was performed anyway for completeness:

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | None — `~/.local/state/quickshell/` does not yet exist on this host [VERIFIED: not referenced anywhere in this repo before this phase] | Created fresh by the probe's first run; no migration needed |
| Live service config | None — no existing n8n/Datadog/Tailscale/Cloudflare-style out-of-git config references Quickshell | N/A |
| OS-registered state | None — no Windows Task Scheduler equivalent on this Linux host; no pm2/launchd/systemd unit will supervise quickshell (D-06 explicitly rejects a systemd user unit in favor of the `exec-once` pattern) | N/A |
| Secrets/env vars | None — no SOPS/`.env` entry references quickshell | N/A |
| Build artifacts | None — quickshell is a pacman-installed binary, not a repo-built package; no stale egg-info/binary-cache class of risk | N/A |

## Common Pitfalls

### Pitfall 1: `hyprctl layers -j` does not carry exclusive-zone data
**What goes wrong:** A mechanical check written to grep `hyprctl layers -j` for an `"exclusive"` or similar field will find nothing — the field does not exist in this build's output.
**Why it happens:** The roadmap's criterion 4 wording ("`hyprctl layers -j` shows no second non-zero exclusive-zone claimant on any edge") assumes a JSON shape that isn't what 0.56.0 actually emits. Directly verified output on this machine (waybar running, one physical monitor):
```json
{
"DP-1": {
    "levels": {
        "0": [ { "address": "...", "x": 0, "y": 0, "w": 2560, "h": 1440, "alpha": 1, "namespace": "awww-daemon", "pid": 1011 } ],
        "1": [],
        "2": [ { "address": "...", "x": 10, "y": 6, "w": 2540, "h": 40, "alpha": 1, "namespace": "waybar", "pid": 1012 } ],
        "3": []
    }
}
}
```
No `exclusive`/`anchor` key anywhere. `"levels"` keys `0`-`3` are the four wlr-layer-shell layers (background/bottom/top/overlay), not screen edges.
**How to avoid:** `quickshell-doctor`'s mechanical check should (a) use `hyprctl layers -j` only to confirm namespace identity and absence of a second/unexpected claimant at a given layer level, and (b) use `hyprctl monitors -j`'s `reserved` array (`[left, top, right, bottom]` pixel counts — this host currently shows `[0, 46, 0, 0]`, all from waybar) to assert exclusive-zone reservation didn't change after Quickshell starts. Compare `reserved` before-and-after Quickshell autostart, not a single-command read of `layers -j`.
**Warning signs:** A "check" that always reports PASS because it's grepping for a JSON key that never appears in either the pass or fail case.

### Pitfall 2: `hyprctl binds -j`'s field misalignment is not cosmetic — the plain-text header token also varies
**What goes wrong:** Beyond the already-diagnosed JSON field misalignment (D-14: `"modmask": false`, `"submap": "64"` holding modmask's value, unquoted `"keycode": Return`), a plain-text-only repair that assumes every block begins with the literal token `bind` will silently mis-parse `bindl`/`bindle`/`bindr`/`bindm` entries.
**Why it happens:** Verified directly: a `bindel = , XF86AudioRaiseVolume, ...` declaration in `keybinds.conf` shows up in `hyprctl binds` plain-text output with the header token `bindle` (letters reordered relative to the config-file flag string), and a `bindl = , XF86AudioNext, ...` line shows up as `bindl`. The header is not a constant string.
**How to avoid:** Parse blank-line-delimited blocks (`awk 'BEGIN{RS=""}'` or bash equivalent) and treat the first line of each block as a variable "block-type" token whose exact letters encode the bind's flags (verified: `l`, `e`, `r`, `m` letters appear in varying combinations) rather than assuming/stripping a fixed `"bind"` prefix. The remaining 8 lines per block (`modmask:`, `submap:`, `key:`, `keycode:`, `catchall:`, `description:`, `dispatcher:`, `arg:`) were confirmed to have a stable field order and correct values across all 78 bind blocks on this build.
**Warning signs:** A repaired parser that reports 0 XF86-key or mouse-scroll binds registered, because it silently dropped every non-`bind`-prefixed block.

### Pitfall 3: Screencopy permission grants are not hot-reloadable
**What goes wrong:** A plan step that writes the `permission = ...` line and expects `hyprctl reload` to pick it up will silently fail the screencopy probe with a still-denied capture.
**Why it happens:** Hyprland's permission manager reads permission rules once at startup for security reasons — [CITED via WebSearch cross-referencing GitHub PR #9930 discussion and issue #9915, not independently reproduced on this machine since quickshell/the permission itself aren't installed yet] a full Hyprland restart (not just `hyprctl reload`) is required after any `permission = ...` config change.
**How to avoid:** Sequence the screencopy feasibility probe's plan step to write the permission config, then restart the Hyprland session (or budget for it as a manual step in the plan), before attempting the live `ScreencopyView` capture — do not chain it directly after a `hyprctl reload`.
**Warning signs:** A capture that returns blank/black tiles even though the `permission` line is present and syntactically correct — this is often permission-not-applied, not a `ScreencopyView` bug (this exact confusion — "silently-denied screencopy permissions rendering blank tiles instead of erroring" — is explicitly named as Phase 16's residual risk, and this Hyprland restart requirement is very likely why it manifests).

### Pitfall 4: `GlobalShortcut`'s `appid` collision is a crash, not a graceful reject
**What goes wrong:** If a future phase (14 or 16) declares a second `GlobalShortcut` reusing the same `appid`+`name` pair as an existing one, quickshell's own docs indicate this can crash rather than fail cleanly.
**Why it happens:** [CITED: quickshell.org/docs/v0.3.0/types/Quickshell.Hyprland/GlobalShortcut/] "Duplicate appid+name pairs across instances may cause crashes."
**How to avoid:** D-17's declared manifest should record `appid`+`name` (not just the key chord) for every Quickshell-claimed shortcut, so `keybind-doctor`'s cross-check can also catch an internal Quickshell-side duplicate before it ever reaches Hyprland's registry.
**Warning signs:** Quickshell crashing on startup after a new `GlobalShortcut` is added in a later phase, with no clear log message pointing at the actual cause.

## Code Examples

### Autostart launcher (D-06, mirrors `waybar-launch.sh`'s guarded shape)
```bash
#!/usr/bin/env bash
# quickshell-launch.sh — guarded, logged launcher (D-06)
set -uo pipefail

LOG="$HOME/.cache/quickshell.log"
CONFIG_DIR="$HOME/.config/quickshell"

if ! command -v quickshell >/dev/null 2>&1; then
    echo "quickshell-launch.sh: quickshell binary not found — skipping" >>"$LOG"
    exit 0
fi
if [[ ! -f "$CONFIG_DIR/shell.qml" ]]; then
    echo "quickshell-launch.sh: $CONFIG_DIR/shell.qml not found — skipping" >>"$LOG"
    exit 0
fi

echo "quickshell-launch.sh: starting $(date -Is)" >>"$LOG"
exec quickshell -p "$CONFIG_DIR" >>"$LOG" 2>&1
```
Source for `-p`/`--path` flag semantics: [CITED, WebSearch summarizing quickshell.org/docs/v0.3.0/guide/distribution] "The `-p` or `--path` option will launch the shell root at the given path and will accept folders with a shell.qml file in them." This flag was chosen over `-c <name>` because D-19's structure (`shell.qml` directly, no named subfolder) matches `-p`'s "any folder containing shell.qml" model more directly than `-c`'s "named subdirectory of `$XDG_CONFIG_HOME/quickshell`" model, which would require inventing an arbitrary config name for no benefit. **[ASSUMED — LOW confidence]:** this specific flag choice and the exact bare-invocation default behavior (what a plain `quickshell` with no flags does) could not be independently confirmed by running `quickshell --help` on this machine, because the binary is not yet installed. The plan should include an early task step that runs `quickshell --help` and `quickshell -p ~/.config/quickshell` by hand immediately after install, before wiring the autostart line, to confirm this flag choice against the real binary (standing constraint 2).

### Screencopy permission stanza (D-12 — corrected location and syntax)
```
# NOT a file named ecosystem.conf — this repo would add a new sourced
# module, e.g. hypr/.config/hypr/config/permissions.conf, sourced from
# hyprland.conf alongside the existing six `source = ...` lines.

ecosystem {
    enforce_permissions = 1   # default is 0 (disabled/all-allowed) — must be set to 1 for the "ask"/"deny" modes to have any effect
}

# client_identifier is a path (can be a regex); type is currently only
# "screencopy" or "plugin"; mode is one of allow/deny/ask.
permission = /usr/bin/quickshell, screencopy, allow
```
Sources: [CITED, WebSearch cross-referencing Hyprland GitHub PR #9930 (screencopy permission manager) and issue #9915] for the `permission = <path>, <type>, <mode>` syntax and the three mode values; [CITED, WebSearch] for `ecosystem:enforce_permissions` as a `registerConfigVar`-declared internal key defaulting to `0`, which in classic hyprlang config syntax is written as a category block (`ecosystem { enforce_permissions = ... }`), matching this repo's existing `general {}`/`decoration {}`/`misc {}` block convention. **[ASSUMED — LOW confidence, flag for verification]:** the exact quoted binary path for quickshell (`/usr/bin/quickshell`) is the standard Arch packaging convention but was not directly confirmed via `pacman -Fl quickshell` (the `pacman -Fy` file database sync requires root and was not available in this session) — verify with `pacman -Ql quickshell | grep bin/` once the package is actually installed, before writing the final `permission =` line.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| `hyprexpo` plugin for workspace overview | `ScreencopyView` + `hyprland-toplevel-export-v1`, native to Hyprland | Already the case, and already reflected in this repo's REQUIREMENTS.md Out-of-Scope table | No `hyprpm` ABI coupling — this phase's feasibility probe is exercising exactly this path |
| Reading `hyprctl binds -j` for structured data | Parsing plain-text `hyprctl binds` on this 0.56.0 build | Discovered this milestone (D-14) | JSON serializer is field-misaligned on 0.56.0 — a regression, not a feature removal; revisit if a future Hyprland release fixes it (deferred item, already logged in CONTEXT.md) |

**Deprecated/outdated:**
- Hyprland's classic hyprlang config format is not deprecated on 0.56.0 — this repo's existing config (verified: `keybinds.conf`, `hyprland.conf`, all classic `key = value` hyprlang syntax) continues to work, and the new `permission =`/`ecosystem {}` additions in this phase use the same classic syntax, not the newer Lua config path some 0.55+ documentation surfaces (`hl.config({...})`, `hl.permission({...})`) mention as an alternative. **[ASSUMED — MEDIUM confidence]** that classic hyprlang and Lua config remain interchangeable/co-existing on 0.56.0, based on this repo's own working config already using classic syntax exclusively; not independently re-verified this session beyond confirming the existing config loads (it self-evidently does, since the desktop is live).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `quickshell -p <config-dir>` is the correct invocation for `quickshell-launch.sh`, and bare `quickshell` with no flags does not silently do something else | Code Examples / Autostart launcher | Autostart line could silently no-op or error on first login; mitigated by an explicit early manual-verification task in the plan |
| A2 | The quickshell binary installs at `/usr/bin/quickshell` (standard Arch convention) | Code Examples / Screencopy permission stanza | A wrong path in the `permission =` line would silently deny screencopy to the real binary while looking syntactically correct; mitigated by a `pacman -Ql quickshell` check once installed |
| A3 | Permission grants require a full Hyprland restart, not just `hyprctl reload`, to take effect on 0.56.0 | Common Pitfalls / Pitfall 3 | If wrong (i.e., `hyprctl reload` is actually sufficient), the plan would needlessly restart the session; if the plan assumes `reload` is sufficient and it is not, the screencopy probe fails for a reason unrelated to the actual feasibility question, wasting probe time diagnosing a non-issue |
| A4 | Classic hyprlang config syntax (not the newer Lua config path) remains fully supported for new categories like `ecosystem {}` on Hyprland 0.56.0 | State of the Art | If Hyprland 0.56.0 actually requires the Lua path for this specific category, the `permission =`/`ecosystem {}` config addition would silently no-op; low risk since this repo's entire existing config is classic-syntax and demonstrably working |
| A5 | `focusable: true` on `PanelWindow` is a strict subset/alias of setting `WlrLayershell.keyboardFocus` directly, not a materially different code path | Architecture Patterns / Pattern 1 | Low risk since the plan recommends setting `WlrLayershell.keyboardFocus` explicitly rather than relying on `focusable`, sidestepping the ambiguity entirely |

## Open Questions

1. **Does `quickshell --help`/bare invocation confirm `-p` as the right autostart flag, and does `qs` exist as a symlink alias?**
   - What we know: official docs (fetched at the exact installed version, v0.3.0) describe `-p`/`--path` and `-c`/`--config` clearly; a WebSearch snippet references `qs ipc` sub-invocations implying a `qs` alias exists.
   - What's unclear: could not run `quickshell --help` directly, since the binary is not installed on this research machine.
   - Recommendation: first plan task after `install.sh` runs should be `quickshell --help` (or `qs --help`) captured verbatim into the evidence artifact, before writing the final `quickshell-launch.sh` invocation line.

2. **Exact binary install path for the `permission =` client-identifier.**
   - What we know: Arch packaging convention places CLI binaries at `/usr/bin/<name>`.
   - What's unclear: not independently confirmed via the pacman file database (offline/no-root in this research session).
   - Recommendation: `pacman -Ql quickshell | grep '/bin/'` immediately after install, before writing the permission stanza.

3. **Whether `ecosystem { enforce_permissions = 1 }` needs to be paired with any other Hyprland variable to actually surface the "ask" popup UI (vs. silent deny) mentioned in some sources as requiring `hyprland-guiutils`.**
   - What we know: a WebSearch result on the Hyprland wiki Permissions page's partial content mentioned "hyprland-guiutils" being required for the permission system's UI, but the fetch was truncated before explaining the dependency.
   - What's unclear: whether `hyprland-guiutils` needs to be an explicit `install.sh` addition for the "ask"-mode popup to render, or whether this phase can use `allow` mode exclusively (sidestepping the popup entirely, since D-12 only requires a feasibility probe, not the interactive-grant UX).
   - Recommendation: use `allow` mode directly for the phase-11 feasibility probe (skips the popup-UI question entirely, matches D-12's "feasibility-only" framing) and treat `hyprland-guiutils`/`ask`-mode UX as a Phase 16 concern if OVER-04 ever needs a live-grant UX.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `quickshell` | QS-01..06, MAINT-01 (entire phase) | ✗ (confirmed not installed; available in `extra`) | 0.3.0-2 in repo | `install.sh` addition — no fallback needed, this is the phase's own deliverable |
| `qt6-base`/`qt6-declarative`/`qt6-svg` | quickshell runtime | ✓ (already present on this host, for unrelated KDE-family reasons) | 6.11.1 | Auto-resolved by pacman on fresh installs regardless |
| `cpptrace` | quickshell runtime | ✗ (not installed; available in `extra`, auto-resolved) | 1.0.4-2 in repo | None needed — pacman handles it |
| Hyprland | Everything in this phase | ✓ | 0.56.0 (commit `36b2e0cf`) | — |
| `jq` | `keybind-doctor` (existing), `quickshell-doctor` (new) | ✓ (already required by existing scripts) | — | — |
| `busctl` | `quickshell-doctor`'s Notifications-owner check | ✓ | — | — |
| A second physical monitor | Real hotplug/EDID test (deferred per D-07) | ✗ (one physical monitor: `DP-1`) | — | `hyprctl output create/remove headless` — confirmed working on this machine (see Verification below); D-07's accepted proxy |

**Missing dependencies with no fallback:** none — `quickshell` itself is this phase's deliverable, not a blocking external dependency.

**Missing dependencies with fallback:** a second physical display (fallback: Hyprland virtual headless output, already verified to work — see below).

## Security Domain

`security_enforcement` is enabled (ASVS level 1, block-on `high`) per `.planning/config.json`.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | No auth surface in this phase |
| V3 Session Management | No | N/A |
| V4 Access Control | Yes | The screencopy permission stanza (`permission = <path>, screencopy, <mode>`) *is* an access-control decision — the client-identifier regex must be scoped as narrowly as possible (the specific quickshell binary path, not a wildcard/broad regex) so a permission grant intended for quickshell cannot be inherited by an unrelated binary that happens to match a loose pattern |
| V5 Input Validation | Yes | `quickshell-doctor`'s path argument (mirroring `keybind-doctor`'s existing pattern, which already treats its path argument as display/arithmetic-only text, never shell-command-interpreted) must follow the same discipline: never `eval`/`source` a user- or fixture-supplied path, and the hand-edited JSON file consumed by `FileView`/`JsonAdapter` must never be treated as executable content by any QML `Process`-style component |
| V6 Cryptography | No | No cryptographic material in this phase |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Overly broad `permission = <regex>, screencopy, allow` client-identifier | Elevation of Privilege | Scope the regex to the exact verified quickshell binary path (Open Question 2) — never a wildcard or a loose prefix match that could also match an unrelated binary in `/usr/bin` |
| Path-argument injection into a gate script (`quickshell-doctor <path>`) | Tampering | Follow `keybind-doctor`'s existing discipline exactly: the path argument is read and compared as text, never passed through `eval`/`source`/backtick expansion |
| Hand-edited JSON state file treated as more than data | Tampering/Elevation of Privilege | `FileView`/`JsonAdapter` only ever binds JSON keys to typed QML properties (string/int/bool/real) — do not add a QML `Process` component that shells out based on a value read from `~/.local/state/quickshell/*.json`, since that file is explicitly designed to be hand-editable and therefore is an untrusted-input boundary once any phase after this one starts writing richer state there |

## Sources

### Primary (HIGH confidence — direct machine verification, this session)
- `pacman -Si quickshell` / `pacman -Qi quickshell` — package availability, version, full dependency closure, not-yet-installed status
- `pacman -Qi <pkg>` for `qt6-base`, `qt6-declarative`, `qt6-svg`, `qt6-wayland`, `cpptrace`, `libpipewire`, etc. — already-present vs. genuinely-new dependency classification
- `hyprctl version` — confirmed Hyprland 0.56.0, commit `36b2e0cf`
- `hyprctl binds -j` / `hyprctl binds` (plain text) — reproduced the exact JSON field-misalignment bug (`"modmask": false`, `"submap": "64"`, unquoted `keycode: Return`) and confirmed plain-text correctness across all 78 bind blocks, including the variable header-token finding (`bind`/`bindl`/`bindle`)
- `hyprctl layers -j` — confirmed the actual JSON schema (no exclusive-zone field; grouped by shell-layer level 0-3)
- `hyprctl monitors -j` — confirmed `reserved: [0, 46, 0, 0]` is where exclusive-zone reservation actually surfaces
- `hyprctl output create headless` / `hyprctl output remove HEADLESS-1` — confirmed the D-07 virtual-output mechanism works cleanly on this exact build (created and removed `HEADLESS-1` successfully)
- `busctl --user list` — confirmed `org.freedesktop.Notifications` currently owned solely by `swaync` (pid 1014)
- `swayosd-client --help` — confirmed no query/introspection subcommand exists; it is send-only, so "one step per press" is only mechanically provable by measuring `pactl`-visible volume delta before/after an invocation, not by asking swayosd-client itself
- Full read of `hypr/.config/hypr/scripts/keybind-doctor`, `waybar-launch.sh`, `waybar-equivalence-check`, `theme-doctor` (house style: `[PASS]`/`[FAIL]` lines, `PASS`/`FAIL` summary counts, path-argument self-test convention, report-only/never-mutates discipline)
- Full read of `hypr/.config/hypr/config/autostart.conf`, `keybinds.conf` (all 78 binds enumerated, confirmed `G` is unused under any `$mainMod` modifier combination), `windowrules.conf` (confirmed the `eww-media-popup` stale layerrules cited in CONTEXT.md's canonical refs are already removed — no `eww` string remains)
- Full read of `stow.sh` (20-entry `PACKAGES` array) and `install.sh` (`PACMAN_PKGS`/`AUR_PKGS` full contents)
- `08-BAR-02-EVIDENCE.md` (archived at `.planning/milestones/v2.0-phases/08-waybar-evolution/`) — full read, the format precedent for the evidence artifact

### Secondary (MEDIUM confidence — official documentation, version-matched to installed 0.3.0)
- [quickshell.org/docs/v0.3.0/types/Quickshell/PanelWindow/](https://quickshell.org/docs/v0.3.0/types/Quickshell/PanelWindow/) — `exclusiveZone`, `focusable`, `anchors`, `margins`
- [quickshell.org/docs/v0.3.0/types/Quickshell.Wayland/WlrLayershell/](https://quickshell.org/docs/v0.3.0/types/Quickshell.Wayland/WlrLayershell/) — `layer`, `namespace`, `keyboardFocus`
- [quickshell.org/docs/v0.3.0/types/Quickshell.Wayland/WlrKeyboardFocus/](https://quickshell.org/docs/v0.3.0/types/Quickshell.Wayland/WlrKeyboardFocus/) — `None`/`Exclusive`/`OnDemand` enum semantics
- [quickshell.org/docs/v0.3.0/types/Quickshell.Hyprland/HyprlandFocusGrab/](https://quickshell.org/docs/v0.3.0/types/Quickshell.Hyprland/HyprlandFocusGrab/) — click-outside dismiss primitive, worked example
- [quickshell.org/docs/v0.3.0/types/Quickshell.Hyprland/GlobalShortcut/](https://quickshell.org/docs/v0.3.0/types/Quickshell.Hyprland/GlobalShortcut/) — confirmed no runtime-introspection API, `appid`/`name` duplicate-crash risk
- [quickshell.org/docs/v0.3.0/types/Quickshell.Io/FileView/](https://quickshell.org/docs/v0.3.0/types/Quickshell.Io/FileView/) — full property/method/signal surface
- [quickshell.org/docs/v0.3.0/types/Quickshell.Io/JsonAdapter/](https://quickshell.org/docs/v0.3.0/types/Quickshell.Io/JsonAdapter/) — property-mapping and the zero-reload-script live-update pattern
- [quickshell.org/docs/v0.3.0/types/Quickshell.Wayland/ScreencopyView/](https://quickshell.org/docs/v0.3.0/types/Quickshell.Wayland/ScreencopyView/) — capture source requirements, properties, methods
- WebSearch cross-referencing Hyprland GitHub PR #9930 and issue #9915 — `permission = <path>, <type>, <mode>` syntax, `ecosystem:enforce_permissions` internal key name and default value, restart-required (not hot-reload) behavior

### Tertiary (LOW confidence — not independently reproduced, flagged in Assumptions Log)
- Bare `quickshell`/`qs` CLI invocation defaults and the `-p`/`-c` choice's exact runtime behavior (binary not installed in this research session — see Open Question 1)
- Exact installed binary path (`/usr/bin/quickshell` assumed by Arch convention, not confirmed via `pacman -Fl`/`pacman -Ql` — see Open Question 2)
- Whether `hyprland-guiutils` is needed for the permission "ask" popup UI (partial/truncated fetch — see Open Question 3)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — direct `pacman -Si`/`-Qi` verification on this exact machine for every package in the dependency closure
- Architecture (QML API surface): MEDIUM-HIGH — official docs fetched at the exact installed version (v0.3.0), with worked examples, but not independently exercised against a running instance since the binary isn't installed yet
- Pitfalls: HIGH for the `hyprctl`-schema and keybind-doctor findings (directly reproduced on this machine); MEDIUM for the screencopy-restart-requirement pitfall (WebSearch-sourced, not independently reproduced)
- Security domain: MEDIUM — ASVS category mapping is a reasoning exercise against a phase with genuinely small security surface (no auth/crypto), not a vulnerability scan

**Research date:** 2026-07-26
**Valid until:** 30 days for the machine-verified facts (package/binary state can drift with any `pacman -Syu`); 7 days for anything tagged `[ASSUMED]` above, since those specifically need re-verification the moment `quickshell` is actually installed
