# Architecture Research: Shell Migration & Debt Paydown (v4.0)

**Domain:** QML shell migration replacing waybar/swaync/SwayOSD/wleave/AGS inside an existing Quickshell package
**Researched:** 2026-08-10
**Confidence:** HIGH — every claim below is sourced from reading the actual repo (file paths and line-level evidence cited throughout), not general Quickshell knowledge. Two claims are flagged LOW/needs-decision explicitly where the repo itself hasn't resolved them yet.

---

## 0. Two load-bearing corrections to the milestone brief

Before anything else: two claims in `PROJECT.md`/`MILESTONES.md`/the milestone context are **contradicted by the code currently on disk**. Both change roadmap scope and both are worth the roadmapper knowing before Phase 18 is planned.

### 0.1 WINDOWS #14 ("~8 legacy `hyprctl dispatch global` sites in quickshell-doctor") is stale — already fixed

`hypr/.config/hypr/scripts/quickshell-doctor` was inspected directly. Every call site that summons a GlobalShortcut goes through one helper:

```bash
_qsd_dispatch_global() {
    hyprctl dispatch "hl.dsp.global(\"$1\")" >/dev/null 2>&1
}
```

This is already the **correct** post-Lua-migration form (`hl.dsp.global(...)`), not the withdrawn bare-string form (`hyprctl dispatch global <name>`) WINDOWS #14 describes. The script's own header comment (line 226-235) explicitly documents that the bare form was replaced. `grep -c "hyprctl dispatch global"` over the file returns exactly **1** hit, and that hit is a comment explaining the old (no-longer-used) form, not a live call site.

**Conclusion:** WINDOWS #14 is closeable as `fixed` with no code change — it was resolved by a commit after 2026-07-28 (when the ledger row was recorded) without the ledger being updated. The roadmapper should not schedule work against it; it needs a `gsd-tools windows fixed 14` bookkeeping pass, not a phase.

### 0.2 "GradientBorder has exactly one consumer" is stale — already fixed in Phase 15

`PROJECT.md`'s Active v4.0 requirement ("Reuse `GradientBorder` across the panel family") and `MILESTONES.md`'s v3.0 "known gap at close" both assert `GradientBorder` is only consumed by `Dashboard.qml:387`. Reading `quickshell/.config/quickshell/modules/dashboard/PanelDialog.qml` directly (lines 180-198) shows it already instantiates `GradientBorder`:

```qml
GradientBorder {
    anchors.fill: parent
    borderWidth: panelWindow.borderWidth
    topLeftRadius: 0
    topRightRadius: 0
    bottomLeftRadius: panelWindow.cornerRadius
    bottomRightRadius: panelWindow.cornerRadius
}
```

`git log` confirms: commit `4f48847`, **2026-08-02 19:35:30**, `feat(15-10): instantiate GradientBorder inside PanelDialog.qml`. Since `PanelDialog` is the one shared frame all three Phase 15 panels (audio/wifi/bluetooth) are built from, all three already inherit the rim — same-day as the diagnosis in `.planning/debug/panels-missing-animated-border.md` (created 08:00, diagnose-only, `status: diagnosed`, never updated). The fix landed the same day as a normal Phase 15 plan (15-10); only the debug-session frontmatter and the milestone docs were never updated to reflect it.

**Conclusion:** this requirement is functionally **done**. The only remaining work is bookkeeping: flip `panels-missing-animated-border.md`'s `status` to `resolved` and drop the bullet from `PROJECT.md`'s Active list. No QML work needed for this line item — the roadmapper should not mint a phase or even a task for it.

---

## 1. Current QML layout (as it exists today)

### Package boundary and stow registration

`quickshell/` is one stow package, folded whole into `~/.config/quickshell` (`stow.sh` pre-creates `~/.config/quickshell` as a real directory before stowing — see `stow.sh:72-79` — so the package can whole-directory-fold rather than symlink individual files; this convention must be repeated for any new top-level directory the bar/notifications/OSD/power-menu work adds). It also ships one file outside its own namespace: `quickshell/.config/autostart/nm-applet.desktop` (stow.sh:190-198) — a precedent that a stow package legitimately owns files outside its literal `.config/<name>/` tree when the app needs it (relevant if a QML OSD ever needs its own autostart entry once swayosd-server is gone).

### File tree

```
quickshell/.config/quickshell/
├── shell.qml                          # the ONE ShellRoot — everything mounts here
├── shortcuts.json                     # GlobalShortcut manifest (appid/name/chord/description)
└── modules/
    ├── qmldir                         # explicit manifest — directory-scanner is DISABLED (D-12/FM1)
    ├── Colours.qml   (singleton)      # live palette.json reader
    ├── Motion.qml    (singleton)      # live motion.json reader
    ├── Probe.qml                      # QS-02 viability instrument, kept permanently (D-01)
    ├── ScreencopyProbe.qml            # criterion-5 screencopy feasibility probe
    ├── Dashboard.qml                  # Super+D drawer (4 tabs)
    ├── Overview.qml                   # Super+O full-screen workspace overview
    ├── dashboard/
    │   ├── qmldir                     # 20-entry manifest, 2 singletons (Design, WeatherPalette)
    │   ├── GradientBorder.qml         # animated gradient rim — 2 consumers now (0.1 above)
    │   ├── PanelDialog.qml            # shared frame for Audio/Wifi/Bluetooth panels
    │   ├── {Audio,Wifi,Bluetooth}{Panel,Backend}.qml
    │   ├── MediaBackend.qml / MediaTab.qml
    │   ├── QuickToggles.qml           # the drawer's toggle grid (swaync-mirrored)
    │   ├── Cascade.qml                # entrance-cascade runner, reused everywhere
    │   ├── Design.qml (singleton)     # spacing/type constants
    │   └── …
    └── overview/
        ├── qmldir
        ├── WorkspaceTile.qml / WindowThumbnail.qml / DragGhost.qml
```

### Shell root structure (`shell.qml`) — the actual summon mechanism

There is **one process** (`quickshell -p ~/.config/quickshell`, launched by `hypr/.config/hypr/scripts/quickshell-launch.sh`, autostarted from `autostart.lua`). Inside it, `ShellRoot` mounts every surface as a **sibling**:

- **Summonable, destroy-on-dismiss surfaces** (`Probe`, `ScreencopyProbe`, `Dashboard`, `AudioPanel`, `WifiPanel`, `BluetoothPanel`, `Overview`): each is wrapped in its own `LazyLoader { active: false }`. Setting `active = true` constructs the `wl_surface`; setting it back to `false` **destroys** it (not just hides it) — confirmed by `hyprctl layers -j` going empty on dismiss. This is the deliberate zero-idle-footprint pattern (D-02/D-14/D-32/D-36): nothing renders, nothing polls, no process runs while a surface isn't summoned.
- **Shared backend Scopes** (`MediaBackend`, `WeatherBackend`, `SystemResources`, `AudioBackend`, `WifiBackend`, `BluetoothBackend`): mounted once as **plain siblings of the loaders**, not inside them, specifically so their state (last-known media payload, weather cache) survives a dismiss/resummon cycle. Each carries a `panelOpen`/`drawerOpen` gate bound to the relevant loader's `active`, so their own `Process`/`Timer` children only run while something is actually summoned reading them.
- **Summon paths, three of them, all converging on the same functions:**
  1. **`GlobalShortcut`** (Wayland global-shortcuts protocol) — `probeShortcut`, `dashboardShortcut`, `audioPanelShortcut`, `overviewShortcut`. Registered in `shortcuts.json` + bound from Hyprland via `hl.dsp.global("quickshell:<name>")` in `keybinds.lua` (e.g. `keybinds.lua:188`: `hl.bind(mainMod .. " + A", hl.dsp.global("quickshell:audio-panel"))`).
  2. **`IpcHandler`** (`qs ipc call <target> <verb>`) — `panelIpc` (target `"panel"`, verbs `open(name)`/`toggle(name)`) and `overviewIpc` (target `"overview"`, verbs `toggle()`/`status()`). This is how **waybar's own button click** currently summons the audio/wifi/bluetooth panels (Phase 15 wired a waybar `on-click` to `qs ipc call panel toggle wifi`, not a raw dispatch string) — confirmed pattern, and the exact mechanism a future QML bar's own click handler will call into instead, once waybar itself is gone.
  3. **Direct function call from another surface** (`Dashboard.qml`'s `onPanelRequested: (name) => root.openPanel(name)`) — the drawer's own quick-toggle chevrons summon a panel by calling straight into the shell root, not through IPC.
- **Single guarded resolution point:** `panelLoaderFor(name)` maps a string name to a loader exactly once; `openPanel(name)`/`closeAllPanels()` are the only functions that ever write a loader's `active` property. Every summon path (shortcut, IPC, drawer-internal call) funnels through this one function, which also owns the DASH-08 fullscreen-refusal guard (`fullscreenBlocking`). **This is the pattern any new summonable surface (notifications, power menu) should extend, not re-invent.**

### `qmldir` discipline (binding constraint for every new file)

Both `modules/qmldir` and `modules/dashboard/qmldir` are **checked-in, explicit manifests** that disable Quickshell's directory-scanner synthesis (closes a race called FM1). Any `.qml` type added to either directory that is **not** listed in its `qmldir` is unresolvable to importers. The standing rule, stated in both files' own headers and enforced every phase since: **register a new type in the same commit that creates it.** A `singleton` type additionally needs the `singleton` keyword in `qmldir` **and** `pragma Singleton` in the file itself — omitting either yields a type that constructs to `undefined` forever with no error (binary-verified, Phase 12). This applies unchanged to whatever `Bar.qml`, `NotificationCenter.qml`, `Osd.qml`, `PowerMenu.qml` and their new subdirectories look like.

---

## 2. Where new surfaces belong

### Recommendation: one process, new `PanelWindow`s as siblings in the same `shell.qml`, following the exact `LazyLoader`-sibling pattern already used for the panel family — with one structural exception for the bar.

**Why one process, not separate Quickshell instances:**
- Colour/motion consumption is already zero-cost and singleton-based (`Colours`/`Motion`, `pragma Singleton`). A second `quickshell` instance would need its own `qs -p <dir>` invocation, its own `qmldir`, and would **not** share these singletons in-process — every surface would still read the same files, but you'd pay a second file-watch + JSON-parse + object-graph per instance for identical data, and you'd lose the shared `IpcHandler`/`GlobalShortcut` registration namespace that already exists and that waybar's own button already calls into.
- State sharing patterns are already proven cross-surface in one process: `MediaBackend`, `AudioBackend`, `WifiBackend`, `BluetoothBackend` are each mounted once and consumed by multiple surfaces (drawer + panel). Splitting into separate processes would force either IPC-based state sharing (adding a new mechanism this repo doesn't have) or duplicating each backend per process — reproducing the exact "N readers of the same script" duplication cost v3.0 already priced for MPRIS and that v4.0's own scope explicitly wants to retire.
- The summon-arbitration pattern (`openPanel`/`closeAllPanels`, one panel open at a time via `HyprlandFocusGrab`) only works because everything lives in one root that can see every loader's state. A notification popup that needs to know "is a panel currently grabbing focus" (so it doesn't steal it, or so it queues) is a one-line read of a sibling property in-process; across processes it would need new IPC just to ask.

**The real cost, and why it matters more for a bar than for anything built so far:** every summonable surface today is **destroy-on-dismiss** — if the `quickshell` process crashes, the *symptom* is "nothing happens when I press Super+D," which is silent and easy to miss for a while. `quickshell-launch.sh` execs `quickshell` directly with no restart wrapper (`exec quickshell -p "$CONFIG_DIR" >>"$LOG" 2>&1` — confirmed, no `systemd --user` unit with `Restart=`, no bash retry loop). **A bar is different: it must be visibly, permanently mounted, not summoned.** The instant this same process crashes, the bar — the one surface the user looks at continuously — disappears immediately and visibly, and takes the entire panel family, the notification center, the OSD and the power menu down with it in the same instant, because they're all one process. This is the direct cost of the one-process recommendation and it should be named explicitly in the bar phase's plan, with one of two mitigations decided before or during that phase:
1. Add a restart-on-crash wrapper around `quickshell-launch.sh` (a bounded retry loop, or a `systemd --user` service with `Restart=on-failure` — this repo already uses `uwsm app --` wrapping for process launches but has no existing systemd **service** unit for quickshell to extend, unlike `swaync.service` and `swayosd-libinput-backend.service`, both of which already have real units). This is new infrastructure, not a config tweak.
2. Accept the risk as-is (matches the "one shell, no more shell-of-shells" spirit of the milestone) and document it as a known trade-off, same as every other accepted-risk decision this project records explicitly (D-13/QS-03 being the template for how to do that).

Given the milestone's own framing ("ends with one shell") and that a crash-visible bar is strictly more noticeable (hence more likely to get fixed fast) than a silently-dead summon path, recommend **documenting the risk explicitly in the bar phase and deferring the restart-wrapper decision to that phase's own scoping** rather than pre-building infrastructure nothing has asked for yet — but flag it as a live open question, not a settled one.

### The QS-03 single-screen limitation, applied specifically to an always-on bar

QS-03 (per-screen surface fan-out) was formally dropped one-way under D-13 after Phase 12 reproduced an FM2-class multi-screen creation failure twice, on the latest available `quickshell` (0.3.0-2). The host has exactly one physical monitor (`DP-1`), so every surface shipped since — including the full-screen `Overview.qml` — is a **single, non-`Variants`-wrapped `PanelWindow`** with no per-screen fan-out logic at all (confirmed by reading `Overview.qml`: `anchors { top: true; bottom: true; left: true; right: true }` on one `PanelWindow`, no `Variants`, no `LazyLoader` per-screen). Overview did not "solve" per-screen fan-out — it simply never needed to, because it (like everything else) only has one screen to render to.

**The safe pattern for the bar is identical: a single top-level `PanelWindow` with no `Variants`/per-screen wrapper, mounted unconditionally (not behind a `LazyLoader`) as a sibling in `shell.qml`.** This is not new engineering — it is the same "don't fan out" posture every other surface already uses, just switched from summon-on-demand to always-mounted. The risk is explicit and already named at the project level (Out of Scope entry for QS-03): **if a second monitor is ever connected to this host, the bar (like every other Quickshell surface today) will only ever render on one of them.** This is an accepted, already-recorded limitation, not a new one the bar introduces — the bar phase should reference D-13 rather than re-litigate it, and should NOT attempt a `Variants`-based per-screen bar (Phase 12 already spent a bounded budget proving that approach fails on this `quickshell` version).

### What is structurally new about the bar specifically

Every summonable surface built so far uses `exclusiveZone: 0` (overlay posture — panels, drawer, overview all float above content and reserve no screen space; confirmed in `PanelDialog.qml:127` and `Overview.qml:55`). **A bar needs a nonzero exclusive zone** (to reserve its strip of screen so windows tile around it, replacing waybar's own reserved-space behavior) — this is a first for the QML package and has no existing precedent to copy in this repo. The bar phase needs to prove `exclusiveZone` behaves correctly (space reserved, other clients tile around it, `hyprctl monitors -j`'s `reserved` array reflects it) as its own small viability check, mirroring how QS-02 proved pointer/keyboard/dismiss before Phase 14 built on it.

---

## 3. Shared component extraction

| Component | Current state | Reuse target |
|---|---|---|
| `GradientBorder.qml` | **Already 2 consumers** (Dashboard, PanelDialog — see §0.2). Fully generic: takes only `width`/`height` (via `anchors.fill`) and four independent corner radii; reads colour from `Colours.primary/secondary/tertiary` and period from `Motion.borderRotateDuration`. | Bar (if it wants a rim at all — a full-width bar strip has no "corners" in the panel sense, so this may not apply as-is; notification popups and the power menu are much closer geometric matches to the existing panels and should reuse it exactly the way `PanelDialog` does). |
| `PanelDialog.qml` | Shared frame for Audio/Wifi/Bluetooth. Owns: layer posture (`anchors.top`, `exclusiveZone: 0`, `WlrKeyboardFocus.OnDemand`), header band + Advanced button, `HyprlandFocusGrab`-based dismissal, `Cascade`-based entrance, fixed-size + scrollable body slot, 4-state `panelStates` vocabulary (`populated`/`pending`/`empty`/`failed`), `stateColour()`. | **Power menu is the closest fit** — it's summon-on-demand, single-shot, no persistent backend, exactly like the three existing panels. Notification center (the "slide-out centre" surface, not the transient popups) is also a strong fit — it is explicitly the same shape (toggle grid + sliders) as the existing panels' body content. **Transient notification popups and the OSD are a worse fit** — `PanelDialog` assumes `HyprlandFocusGrab`-exclusive, single-panel-at-a-time dismissal, which is wrong for a notification toast (must not steal focus, must not exclude other panels, must auto-dismiss on a timer) or an OSD pill (same: no focus grab, auto-dismiss, potentially multiple/replacing). These two need a **new**, lighter frame type — not a `PanelDialog` instance, but ideally sharing `PanelDialog`'s color/motion-token discipline and its `Cascade` entrance pattern. |
| `MediaBackend.qml` | The **one** streaming reader of `media-status.sh`/`media-players.sh`, D-35's hard fence: "never a second reader." Already consumed by `Dashboard.qml`'s Media tab. | This is already the reuse target for AGS retirement — no new backend needed, only a new/extended consumer view if AGS's cava/blur visual needs replicating (see §4/§7 below — this is **not** solved yet). |
| Quick-toggle scripts (`gaming-mode-toggle.sh`, `theme-switch.sh`) | Called **byte-identically** by both `swaync/.config/swaync/config.json`'s `buttons-grid.actions[].command` and `QuickToggles.qml`'s `Process { command: [...] }` blocks (confirmed: both invoke the literal same script paths with the same argv shape; DND instead calls `swaync-client -dn/-df` directly from both, since that's swaync's own native toggle API). | The new notification-center toggle grid should call the **same three scripts** the drawer's `QuickToggles.qml` already calls — this is a mechanical copy of an already-proven pattern, not new design. DND itself becomes interesting: today it's a `swaync-client` CLI call because swaync owns DND state; once swaync is retired, DND state ownership must move **into** the QML notification surface itself (no more external CLI to shell out to) — this is a real design decision the notifications phase must make, not a reuse. |
| `Colours`/`Motion` singletons | Read-only, live, zero-write-back, already used by every existing QML surface. | Every new surface consumes these identically — **no new work, no new contract entries** (see §5). |
| Overview's 4-state capture vocabulary | `WorkspaceTile`/`WindowThumbnail` render a defined 4-state set (matches `PanelDialog`'s own `panelStates` shape: populated/pending/empty/failed, generalized). | Directly reusable as the vocabulary for OSD state (e.g. muted/at-limit/adjusting/unavailable) and notification-item state — this is a naming/design convention, cheap to carry forward, not a code dependency. |
| `Cascade.qml` | Summon-only entrance-cascade runner, reused by `PanelDialog` (header + Advanced button + per-panel `bodyCascadeBands`) and `Overview` (row-level cascade). | Reuse directly for the power menu's own capsule entrance and the notification center's toggle-grid entrance. |

**GradientBorder reuse across the "panel family" is functionally already satisfied (§0.2).** The genuinely open extraction work for v4.0 is: (a) deciding whether the bar wants a rim treatment at all (geometrically different from the drawer/panels), and (b) building the **new** lightweight transient-popup frame type that neither `PanelDialog` nor `GradientBorder` currently provide, needed by both notification toasts and the OSD.

---

## 4. State sharing and the double-read problem — end-state ownership

| State | v3.0 (today) | v4.0 end-state (after all 5 retirements) |
|---|---|---|
| **MPRIS / now-playing** | **3 consumers** of `media-status.sh`/`media-players.sh`: waybar's built-in `mpris` module (direct `playerctl` calls, confirmed in `waybar/.config/waybar/modules.jsonc:43-68`), AGS's `lib/media.ts` (confirmed: `exec(["bash", STATUS_SH/PLAYERS_SH, ...])`), and QML's `MediaBackend.qml` (the same two scripts, one streaming `watch` reader + one one-shot `list` reader, D-35's "third reader, never a second backend" framing). | **1 consumer**: `MediaBackend.qml`, already built, already the sole owner inside the QML process. Waybar's mpris module dies with waybar (Phase 18-ish). AGS's `lib/media.ts` dies with `ags/`. **Important nuance:** the underlying *scripts* (`media-status.sh`/`media-players.sh`) were never duplicated — only the *client readers* were. So "ending the three-consumer duplication" is really "deleting two of three client wrappers," not a backend rewrite — low risk, mechanical. |
| **Quick-toggle grid state** | Shared via **byte-identical script invocation**, not a shared state object — swaync's `buttons-grid` and `QuickToggles.qml` each independently shell out to the same scripts and each independently poll/derive their own `update-command`/reactive state. Two owners of the *rendering*, one owner of the *mutation* (the scripts themselves, which are idempotent and stateless-safe). | Once swaync is retired, `QuickToggles.qml`'s existing pattern becomes the **only** grid renderer — but a **new** grid (in the notification center's slide-out) is also being built per the Active requirements list ("swaync → QML notifications: popups plus the slide-out centre, its toggle grid"). If both the drawer's grid and the notification center's grid render independently against the same scripts (mirroring today's swaync/drawer split), that is the **exact same duplication pattern being carried forward under a new name**, not eliminated. Recommend: extract the grid's tile logic into one shared component (`QuickToggles.qml` promoted to a reusable type instantiated from both `Dashboard.qml` and the new notification center, the same "promote to shared type" move `PanelDialog` already modeled for the panel family) rather than building a second copy. This is a concrete decision the notifications phase needs to make explicitly, not default into. |
| **Volume/brightness** | swaync's `slider` widget (`cmd_setter`/`cmd_getter` shelling to `brightnessctl`) + SwayOSD's own volume/brightness pipeline (separate, its own daemon) + `AudioBackend.qml`'s PipeWire adapter (used by the drawer's Volume tile and the Audio panel) — **3 independent code paths for the same two knobs today**, not yet unified even before v4.0 starts. | v4.0's SwayOSD retirement is the forcing function to finally unify this: the QML OSD needs a volume/brightness *write* path, and `AudioBackend.qml` already owns a *read* path (PipeWire). Recommend the OSD phase route brightness through the same `brightnessctl` invocation swaync's slider already uses (simple, proven) and volume through `AudioBackend.qml`'s existing PipeWire plumbing rather than re-implementing a third pipeline — collapsing swaync's slider + SwayOSD's pipeline + `AudioBackend` down to one QML-owned read/write path is realistic in-scope work for that phase, not a stretch goal. |
| **Bar visibility** | Single-owner script (`waybar-visibility.sh`), explicitly documented as the answer to "two prior desync bugs already deleted twice" (its own header, D-01..05/08). Fed by 4 declared-intent actors: hypridle timeout, a Hyprland fullscreen socket2 watcher, gaming-mode-toggle, and a keybind override. Computes a `base_union` of hide/show, actuates by writing a CSS override file + `pkill -SIGUSR2 waybar`. | The **ownership model must be preserved exactly** (this is precisely the kind of "two owners racing" bug class this repo has already hit twice per the script's own comment) but the **actuation mechanism changes structurally**: no more CSS file, no more `SIGUSR2`. The four actors instead need to call an `IpcHandler` verb on the bar (e.g. `qs ipc call bar show|hide|reassert`), and the bar surface reads a plain QML property rather than watching a CSS file. Recommend keeping `waybar-visibility.sh` (renamed, e.g. `bar-visibility.sh`) as the **single-owner arbitration script** — it already correctly serializes concurrent actors under `flock` and computes `base_union`/override precedence; only its **actuation** function body needs to change from "write CSS + pkill" to "call the bar's IPC verb." This is a much smaller, lower-risk change than it sounds — the hard part (four-actor arbitration, override precedence, race-free computation) is already solved and does not need to be re-derived, only re-plumbed. |

---

## 5. theme-engine integration

### `contract.json` — concrete before/after count

Current: **29 entries** (post-13.1's Hyprland-output collapse, confirmed live: `theme-engine/.config/theme-engine/contract.json`).

Entries owned by the five retiring surfaces (all deleted in the same phase that retires the owning package, per the milestone's own "retirement is part of the deliverable" rule):

| Package | Contract entries to delete |
|---|---|
| waybar | `waybar.css`, `waybar-theme.css`, `waybar-modules.css`, `waybar-style-full.css`, `waybar-style-athena.css`, `waybar-style-floating.css`, `waybar-style-vertical.css` (7) |
| swaync | `swaync.css`, `swaync-style.css` (2) |
| swayosd | `swayosd.css` (1) |
| wleave | `wleave.css` (1) |
| ags | `ags.scss` (1) |

**12 entries removed. 29 → 17.** No entries are added for the QML replacements, because of an already-established, binary-verified precedent: **QML surfaces never appear in `contract.json` at all.** `Colours.qml`'s own header states this explicitly (D-18): "no quickshell step exists anywhere in theme-apply's reload fan-out (grep `lib/reload.sh` — zero hits), and none should ever be added here for symmetry with the other nine themed surfaces." QML surfaces re-colour themselves in-place by watching `palette.json`/`motion.json` directly via `FileView { watchChanges: true }` — there is no render target to add to the contract and no reload-fan-out step to add, because a `Behavior on color` animates the live property change instead of anything being regenerated or re-read from a rendered CSS file. **This same reasoning applies unchanged to the bar, notifications, OSD and power menu** — none of them needs a `contract.json` entry, ever, by design, not because the roadmapper forgot to ask for one.

Also note (secondary, `engine_owned_files` list, not the `files` contract): `waybar-visibility.css` is listed there as engine-owned runtime state. Once the bar's visibility actuation moves to an IPC verb (§4), this generated file becomes dead and should be removed from `engine_owned_files` too, in the bar retirement phase.

### `theme-doctor` / `theme-parity` changes required

Both tools are driven by `contract.json` (confirmed: `lib/contract.sh` is the single source both consume). Shrinking the `files` array from 29 to 17 mechanically shrinks what both tools check — **no bespoke per-tool code change needed for the colour/motion parity checks themselves**, only the contract-file edit plus deletion of the corresponding matugen templates (`matugen/.config/matugen/config.toml` has one `[templates.<name>]` block per surface — confirmed `[templates.waybar]`, `[templates.swaync]`, `[templates.wleave]`, `[templates.swayosd]`, `[templates.ags]` at lines 34/44/59/89/121 — these five blocks must be deleted in lockstep with the contract entries and the stow packages, in the **same** commit/phase, per the WINDOWS #1 precedent below).

**`lib/reload.sh` also shrinks.** It currently contains explicit per-surface fan-out steps for exactly the five things being retired: `pkill -SIGUSR2 waybar` + the `waybar-visibility.sh reassert` call (line 71-82), the AGS `ags request -i media reload-css` block (line 150-152), the SwayOSD kill/relaunch block (line 108-134). swaync's `swaync-client -rs` call (line 89-91) and wleave (which has no reload.sh entry at all — it's summon-on-demand and re-reads its stylesheet fresh on every launch) round out the list. **All of these become dead code once their target package is deleted and must be removed from `reload.sh` in the same phase**, or `theme-doctor`'s process-liveness checks will start failing against processes that no longer exist by design.

### The WINDOWS #1 precedent — why "delete the package" must be atomic with "delete the contract entry and the checker code"

This is not hypothetical: `WINDOWS.md` row #1 (`phase: 09`) records that Phase 08/10's incomplete eww retirement left an **orphaned `eww.scss` contract entry**, which then **blocked `theme-doctor`/`theme-stress-test`** for the entire span between Phase 8 and Phase 9's fix. This is direct, in-repo evidence that a partial retirement (delete the package, forget the contract entry or the checker) breaks the regression gates for everyone downstream until someone notices and fixes it — exactly the failure mode the milestone's "retirement is part of the deliverable" rule already exists to prevent. Cite this precedent directly in each retirement phase's plan as the reason the package deletion, the `contract.json` edit, the matugen template deletion, and (where relevant) the checker-script deletion must land in the **same commit**, not staggered across phases.

---

## 6. Regression-gate consequences — what replaces `waybar-equivalence-check` / `waybar-design-lint`

Both scripts exist **solely** for waybar and have no generic logic reusable as-is:
- `waybar-equivalence-check` resolves waybar's own `config-*.jsonc` include-chain (first-defined-wins, depth-first, per `waybar(5)` semantics) and diffs the resolved config against a committed pre-refactor baseline. This is inherently comparing **waybar's own config format** against **itself** — there is no "old config" to diff a from-scratch QML bar against, because the whole point of the redesign (per `PROJECT.md`'s explicit call-out) is that it is *not* a port.
- `waybar-design-lint` runs 5 checks (token resolution, alias-boundary discipline, transparent-window rule, zero-literal-hex, non-empty glyph fields) that are specific to **waybar's CSS/JSONC surface**. Some of these checks' *intent* generalizes; none of their *implementation* does (QML has no `.jsonc` includes, no GTK-CSS `@color` aliasing, no glyph-format-string convention).

**Both scripts die with waybar, in the same phase, per §5's atomicity rule.** They must be deleted, not merely left unreferenced (see WINDOWS #1 precedent above for why an orphaned reference, not just an orphaned file, is the actual risk).

**What can mechanically replace them, and what genuinely cannot:**

1. **Structural/wiring checks — `quickshell-doctor` already has the extensible pattern, extend it.** The panel family and the overview both added their own checks to this one script rather than inventing new tools: `panel-namespace-conformance`, `panel-shortcut-single-registration`, `panel-swayosd-key-ownership`, `overview-namespace-conformance`, `overview-shortcut-single-registration`, `reserved-array-manifest-coverage`. The bar, notifications, OSD and power menu should each add their own analogous checks to this same script (e.g. `bar-exclusive-zone-nonzero`, `notification-namespace-conformance`, `osd-single-instance`) — this is a direct, proven, low-risk extension of existing machinery, not new tooling.
2. **Token-discipline checks — extend `motion-lint`'s pattern to colour, or build a sibling "quickshell-design-lint."** `motion-lint` already refuses any surface hand-rolling a raw or dangling motion value (deny-by-default, folded into `theme-doctor`). There is currently **no equivalent check for hardcoded hex literals in `.qml` files** — `waybar-design-lint`'s CHECK D (zero literal hex) has no QML-side counterpart today. Building one (grep every new `.qml` file for `#[0-9a-fA-F]{3,8}` outside `Colours.*` token usage, mirroring CHECK D's regex-based approach) is realistic, cheap, mechanical work and directly closes the gap `waybar-design-lint` leaves behind for the *token-resolution* half of its job.
3. **Appearance/quality judgment — cannot be mechanized, was never fully mechanizable even for waybar.** `waybar-design-lint`'s own header is blunt about why it exists: "Phase 08 shipped a bar the user called 'a complete failure' while every prior automated gate passed green." No lint can check "does this look right" — CHECK C (transparent window) and CHECK E (non-empty glyphs) were reactive patches for two *specific* failure modes already seen once, not a general solution. **This is exactly why `PROJECT.md` already made the human render-and-look gate mandatory per phase for v4.0** — the milestone document is correct that this is the actual replacement for the appearance-judgment half of what these two scripts did, and the project's own history (Phase 8's bar, Phase 16's thumbnails, both green-gated and visibly broken) is the evidence base for why that's not a downgrade in rigor, just an honest one.

**Bottom line for the roadmapper:** budget one small task per retirement phase to (a) delete the waybar-specific scripts when waybar itself dies, (b) add 2-4 structural checks to `quickshell-doctor` per new surface, and (c) treat the mandatory human render gate as the load-bearing replacement for appearance judgment — not as a formality to schedule around.

---

## 7. Suggested build order

### Ordering constraints, stated explicitly

- **Bar first** — user-directed (`PROJECT.md`: "First phase: highest daily contact, and its patterns seed every later surface") and structurally justified: the bar is the only surface needing an always-mounted `PanelWindow` with a nonzero `exclusiveZone` — genuinely new territory this repo hasn't proven yet (§2). Every later phase (notifications, OSD, power menu) reuses `LazyLoader`-summon patterns already proven since Phase 14; only the bar needs a new pattern proven first.
- **Every phase must delete the package it replaces in the same phase** (§5/§6, WINDOWS #1 precedent) — contract entries, matugen templates, and any package-specific checker script all move together with the stow package.
- **No phase may leave the desktop unusable** — carried forward from v3.0's own additive-only discipline, now inverted: each retirement phase's human render gate must confirm the *replacement* is at least as good **before** the old package is deleted within that same phase (not two nights later).

### Recommended sequence

1. **Bar** (waybar → QML bar). Sequential-first, no dependencies. Proves the always-mounted-`PanelWindow` + nonzero-`exclusiveZone` pattern; re-homes `waybar-visibility.sh`'s ownership model onto an IPC verb (§4); closes WINDOWS #15 (workspace-click, dead by design once waybar's compiled-in dispatch strings are gone). Deletes `waybar/`, `waybar-equivalence-check`, `waybar-design-lint`, 7 contract entries, `[templates.waybar]`.

2. **Notifications** (swaync → QML notification popups + slide-out centre). Depends on Phase 1 only loosely — needs a bar-side button to open the notification center (mirroring today's waybar → swaync button wiring, retargeted to the new bar's own click handler calling `panelIpc`-style summon), so scheduling it directly after the bar lets it reuse an already-proven button pattern rather than inventing one. Builds the **new** transient-toast frame type (§3 — genuinely new, not a `PanelDialog` reuse) and resolves DND-ownership migration (§4 — moves from `swaync-client` CLI ownership into the QML surface itself). The toggle-grid duplication risk flagged in §4 (drawer's grid vs. notification-center's grid) should be resolved here by promoting `QuickToggles.qml`'s tile logic to a shared type, not copied a second time. Deletes `swaync/`, 2 contract entries, `[templates.swaync]`.

3. **SwayOSD → QML indicators.** Can run independently of Phase 2's *notification* content, but should schedule **after** Phase 2 so it can reuse the new transient-toast frame type built there (§3) rather than building a third one. Carries a real, named risk not to skip: `swayosd-libinput-backend.service` catches raw hardware volume/brightness keys **even with no keybind configured**; retiring `swayosd-server` orphans this system-level backend's only consumer, and a QML replacement that falls back to Hyprland-keybind-only capture (`XF86Audio*`/`XF86MonBrightness*` binds) is a real regression against "works even without a keybind" unless deliberately accepted. This phase should also finally collapse the 3-way volume/brightness pipeline split (swaync slider / SwayOSD / `AudioBackend`) down to one QML-owned path (§4) — realistic in-scope work here, not a stretch. Deletes `swayosd/`, 1 contract entry, `[templates.swayosd]`, and needs an explicit decision about `swayosd-libinput-backend.service`'s fate (keep it running and have QML subscribe to whatever it emits over D-Bus, if that's viable — or accept the keybind-only fallback and record it as a named, evidence-backed descope the way BAR-02 was).

4. **wleave → QML power menu.** **Independently schedulable at any point** — no shared backend, no bar/notification/OSD coupling, reuses `PanelDialog` almost as-is (§3), and is one of the lowest-risk phases in the whole milestone (closest precedent: the six-capsule GTK4 wleave build in Phase 9 already proved the visual/interaction language this QML version inherits). Could run in parallel with Phase 3 if the team wants overlap, since neither touches the other's files or backends. Deletes `wleave/`, 1 contract entry, `[templates.wleave]`.

5. **AGS media card → Dashboard Media tab.** Schedule **last**, and start it with a small spike/decision task, not straight into build: `MediaTab.qml`'s own header (lines 71-116) already documents, as a **deliberate Phase 14 scope cut**, that it ships a static dashed ring instead of AGS's live cava audio-reactive visualizer, explicitly because "this repo has no cava/audio-analysis service anywhere in its [QML] toolkit." Under v4.0's own "no phase closes downgraded" rule, retiring `ags/` without resolving this gap **is** a downgrade relative to what v2.0/v3.0 shipped (the AGS card's cava underlay was a named, delivered MEDIA-01..04 requirement). The phase needs one explicit human decision up front: either (a) build a QML cava reader (a new `Process` piping `cava`'s own raw-bar text output into a QML visualizer, architecturally similar to `MediaBackend`'s existing streaming-`Process` pattern, so not unprecedented — just not yet built), or (b) get explicit sign-off that losing the live-reactive visualizer is acceptable for v4.0. Do not let this decision default silently. The destination (`MediaTab.qml`) already exists and already reads the correct shared `MediaBackend` — this phase's real work is narrower than "port AGS," it's "close the cava gap, then delete `ags/`." Once done, MPRIS drops from the historical 3 readers to the true single owner (`MediaBackend.qml`) — note waybar's own mpris-module reader is already gone by Phase 1, so this phase is really only removing the *second* of three, not the third; frame it that way rather than claiming 3→1 happens here alone. Deletes `ags/`, 1 contract entry, `[templates.ags]`.

6. **Debt paydown items — mostly orthogonal, sequence independently:**
   - GradientBorder reuse: **already done** (§0.2) — a bookkeeping-only pass (flip debug-session status, update `PROJECT.md`), schedulable immediately, zero QML dependency.
   - WINDOWS #14: **already fixed** (§0.1) — same, bookkeeping-only.
   - MAINT-02 (Logout), OVER-04 (FPS floor measurement), debug-session backlog curation: independent of the migration sequence, schedulable any time, ideally swept into one dedicated closing phase rather than threaded through the migration phases (keeps each migration phase's scope narrow and its human render gate focused on one surface).
   - **D-34/D-36 container reproducibility rerun: schedule last, after Phase 5.** `PROJECT.md` itself already states why: "this milestone deletes stow packages, so a fresh-install proof is a regression gate, not bookkeeping." Running it before all five retirements land would only prove the *current* (pre-migration) install still reproduces — which is already known to work — not that the *post-migration* `install.sh`/`stow.sh` (with five packages and their `AUR_PKGS`/`PACMAN_PKGS` entries removed) reproduces cleanly on a fresh system. This is the correct **closing gate for the whole milestone**, not a per-phase task.

### Dependency summary

```
Phase 1 (Bar)  ──────────────┐
                              ├─→ Phase 2 (Notifications) ─→ Phase 3 (SwayOSD)
                              │
Phase 4 (wleave) ── independent, any time, can overlap Phase 3
Phase 5 (AGS)    ── independent of 1-4's internals, but should run after Phase 1
                     (for the "MPRIS consumer count" narrative) and needs its own
                     cava go/no-go decision before build starts
Debt bookkeeping (GradientBorder, WINDOWS #14) ── zero dependency, do first, costs ~nothing
Debt measurement (MAINT-02, OVER-04, debug curation) ── independent, sweep anytime
D-34/D-36 container rerun ── LAST, after Phases 1-5 all land, as the milestone's closing gate
```

---

## Sources

All findings are sourced from direct repo inspection on 2026-08-10, not external documentation:

- `.planning/PROJECT.md`, `.planning/MILESTONES.md`, `.planning/WINDOWS.md` — milestone scope, requirements, ledger state
- `quickshell/.config/quickshell/shell.qml`, `modules/qmldir`, `modules/dashboard/qmldir`, `modules/overview/qmldir`, `shortcuts.json` — shell root structure, summon mechanism, manifest discipline
- `quickshell/.config/quickshell/modules/Colours.qml`, `modules/Motion.qml` — singleton pattern, D-18 no-contract-entry precedent, binary-verified `pragma Singleton` requirements
- `quickshell/.config/quickshell/modules/dashboard/GradientBorder.qml`, `PanelDialog.qml`, `MediaBackend.qml` — component reuse surface, live consumer count (git-verified)
- `quickshell/.config/quickshell/modules/Overview.qml` — single-screen `PanelWindow` pattern (QS-03 non-solution)
- `hypr/.config/hypr/scripts/waybar-visibility.sh`, `quickshell-doctor`, `waybar-equivalence-check`, `waybar-design-lint`, `quickshell-launch.sh` — visibility ownership, regression-gate mechanics, process-launch/crash-recovery posture
- `hypr/.config/hypr/config/keybinds.lua`, `autostart.lua` — summon-path wiring, current process launch
- `theme-engine/.config/theme-engine/contract.json`, `lib/reload.sh` — render-target contract and reload fan-out, before/after counts
- `matugen/.config/matugen/config.toml` — per-surface template block locations
- `swaync/.config/swaync/config.json`, `ags/.config/ags/lib/media.ts`, `waybar/.config/waybar/modules.jsonc` — confirmed byte-identical script invocation (quick-toggles) and confirmed 3-reader MPRIS duplication
- `install.sh` — package registration lines for waybar/swaync/swayosd/wleave, swayosd-libinput-backend.service enablement
- `.planning/debug/panels-missing-animated-border.md` + `git log -p` on `PanelDialog.qml` — stale-debt verification (§0.2)
- `stow.sh` — package registration conventions (pre-create-before-fold idiom, out-of-namespace file precedent)

---
*Architecture research for: QML shell migration (waybar/swaync/SwayOSD/wleave/AGS → Quickshell)*
*Researched: 2026-08-10*
