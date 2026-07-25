# Architecture Research: v3.0 Quickshell Foundation & Motion Language

**Domain:** Personal Arch + Hyprland dotfiles — theme-engine-centered rice, GNU stow package-per-app
**Researched:** 2026-07-26
**Confidence:** HIGH for everything sourced from direct repo inspection (contract.json, contract.sh, reload.sh, matugen/config.toml, stow.sh, autostart.conf, windowrules.conf, keybinds.conf, ags/app.tsx, ags/style.scss, ags-colors.scss). MEDIUM for Quickshell's own official-docs behavior (quickshell.org — a small, single-maintainer project's own docs, cross-checked across three pages, no second independent source). LOW for end-4/dots-hyprland and Caelestia internals — sourced via DeepWiki (an AI-generated index of those repos' actual source, not the source itself) and web search; treat as directionally correct, not verbatim.

This document supersedes the 2026-07-09 v2.0 ARCHITECTURE.md (that research answered "how do six GTK/CSS-era feature groups plug into theme-engine" — a solved problem now folded into "Validated" in PROJECT.md). It answers a different question: **how does a QML/Quickshell shell layer, and a new spring-physics motion pipeline, plug into the SAME theme-engine architecture without disturbing it**, for the v3.0 milestone (Phases 11-17). The existing pipeline (`theme-apply` → generate → commit → reload; `contract.json` as single source of truth; one stow package per app; `~/.local/state/theme/` as the only render target apps ever consume) is treated as fixed per PROJECT.md constraints — v3.0 extends it, not replaces it.

## Standard Architecture (as it exists today, verified against the repo)

### System Overview — today

```
┌────────────────────────────────────────────────────────────────────────┐
│  SOURCE (git-tracked)                                                  │
│  matugen/templates/*.{css,conf,scss,json,toml}  ← one per render target│
│  theme-engine/contract.json                     ← the 10-file manifest│
├────────────────────────────────────────────────────────────────────────┤
│  RENDER (theme-apply → matugen -p <state_dir>)                         │
├────────────────────────────────────────────────────────────────────────┤
│  STATE (never git-tracked): ~/.local/state/theme/*.{css,conf,scss,...} │
│  — the ONLY thing any surface may @import/read. Never copied.          │
├────────────────────────────────────────────────────────────────────────┤
│  RELOAD FAN-OUT (theme-engine/lib/reload.sh, sole owner, D-04)         │
│  hyprctl reload · SIGUSR2 waybar · swaync-client -rs · GTK gsettings   │
│  · walker kill+relaunch+health-gate · swayosd-server restart ·         │
│  · AGS `ags request reload-css` (live, GTK4 CssProvider) ·             │
│  · Zen notify-only                                                     │
└────────────────────────────────────────────────────────────────────────┘
```

The **closest existing analogue to a QML consumer is the AGS media applet** (Phase 10). Its pattern, ground-truthed from `ags/.config/ags/app.tsx` and `ags-colors.scss`:

1. `matugen` renders `~/.local/state/theme/ags.scss` — Sass `$variable` declarations, no hex literals elsewhere.
2. `ags/.config/ags/style.scss` (the git-tracked, stowed entry point) `@import`s that state-dir file by an absolute 4-level-up path (a **documented fragility**: it only works because AGS's Go bundler resolves symlinks to the real repo path at compile time — this exact trick will not transfer to Quickshell, which has its own, different path-resolution model; see Q1/Q2 below).
3. On first launch, `style` (the compiled CSS string) is applied once via `app.start({ css: style })`.
4. Live re-theme is done by `monitorFile(PALETTE_STATE, () => reloadCss())` — AGS's own file-watch primitive — which on change shells out to `sass` again (recompiling SCSS→CSS at runtime) and calls `app.apply_css(css, true)`. **No process restart.** This is the one surface in the whole repo that already proves "watch the state dir, recompile, hot-swap" is possible without the GTK3 restart-required class.

This AGS pattern is the direct architectural precedent for how Quickshell should consume tokens — the mechanism differs (QML doesn't need a compile step at all for JSON-backed properties), but the shape ("a long-lived process watches the exact same state-dir file everything else reads, and re-applies without restarting") is identical and should be treated as this repo's own precedent, not just an external rice's idea.

---

## Q1 — Quickshell shell structure, and stow-package boundary

**HIGH confidence (Quickshell's own docs, quickshell.org):** Quickshell resolves configs from `~/.config/quickshell/` (`QS_BASE_PATH` overridable). A **named config** is a subfolder of that base path containing a `shell.qml`; if `shell.qml` exists directly in the base folder, no subfolder scanning happens at all. `manifest.conf` (default `~/.config/quickshell/manifest.conf`) is an optional `name = path` list letting one base path serve multiple named shells, selected at launch via `qs -c <name>`. **Live-reload is a genuine, built-in engine feature** — quickshell's own intro docs state plainly that editing and saving a `.qml` file live-reloads the running shell; this is not restart-based like Walker/SwayOSD, and not a manual recompile-then-swap step like AGS's SCSS story — it is closer to true hot module reload.

**MEDIUM confidence (DeepWiki index of end-4/dots-hyprland and Caelestia source):** Both reference rices converge on the same module shape:
- One `shell.qml` (or `ShellRoot`-rooted entry file) that does almost nothing but lazily instantiate top-level UI "families"/panels behind `Loader`s — it is an orchestrator, not where logic lives.
- A `Config` singleton (user-facing options, JSON, debounced writes) kept **separate** from a `Persistent`/state singleton (runtime state, different JSON file) kept **separate** from the color/theme singleton (Caelestia: `services/Colours.qml`, reading `~/.local/state/caelestia/scheme.json`). Three concerns, three files, never merged — directly mirrors this repo's existing separation of `theme-engine` (renders) vs `~/.cache/*` (small pieces of session state like `current-waybar-layout`, `gaming-mode`) vs `~/.local/state/theme/` (the palette).
- Every panel/widget is its own `.qml` file under a `modules/`-style directory, one file per surface, matching this repo's own "one template + one contract entry per surface" instinct.
- Caelestia additionally documents an `AppearanceTokens`-style class for spacing/rounding/fonts — i.e. reference rices already generalize "singleton exposing named design constants" beyond just color, which is direct precedent for adding a sibling `Motion` singleton in Q3 rather than inventing a new pattern.

**Recommendation — one stow package, `quickshell/`.** Quickshell's own config model is single-base-path (`~/.config/quickshell/`), the same way AGS's config model is single-directory (`~/.config/ags/`) — and `ags/` is already exactly one stow package in this repo, not one package per widget (media card, cava underlay, and future AGS widgets all live under the one `ags/` package). Splitting Quickshell into several stow packages (e.g. `quickshell-dashboard/`, `quickshell-mixer/`) would fight Quickshell's own base-path/manifest model for no benefit — every named config still resolves from the same `~/.config/quickshell/` root, so stow's per-package symlink-forest would have to interleave multiple packages into one directory tree, which is exactly the kind of drift stow is bad at. Recommend:

```
quickshell/.config/quickshell/
├── shell.qml                 # entry point, lazy-loads panels via Loader
├── manifest.conf             # (only if >1 named config ever needed — start without it)
├── services/
│   ├── Colors.qml            # Singleton; FileView+JsonAdapter over state-dir JSON (Q2)
│   ├── Motion.qml            # Singleton; FileView+JsonAdapter over motion JSON (Q3)
│   ├── Config.qml            # user-facing shell options (unrelated to theme-engine)
│   └── GlobalStates.qml      # open/closed flags per panel, mirrors end-4's pattern
├── modules/
│   ├── Dashboard/            # Phase 14
│   ├── AudioMixer/           # Phase 15
│   ├── Connectivity/         # Phase 15
│   └── Overview/             # Phase 16 (research-gated, see Q5)
└── components/                # shared small QML building blocks
```

Register `quickshell` in `stow.sh`'s `PACKAGES` array **in the same commit that creates the directory** — this repo has already paid for this exact lesson once (Key Decision: "New stow packages must register in `stow.sh` in the same commit," caught post-hoc for `ags/` in Phase 10).

---

## Q2 — Colour token flow into QML: the `@import`-from-state-dir analogue

**The literal rule ("every themed surface `@import`s from `~/.local/state/theme/`, never a copied file") cannot transfer verbatim** — QML has no `@import` for arbitrary text/CSS, and Quickshell's own docs (MEDIUM confidence) show the idiomatic mechanism is structurally different but **preserves the same intent** (one render target, consumed live, never copied):

- **`FileView`** (`Quickshell.Io`) watches a file (`watchChanges: true`) and emits `fileChanged()`; the idiomatic pattern connects `onFileChanged: reload()`.
- **`JsonAdapter`**, layered on a `FileView`, exposes a JSON file's top-level keys as real QML properties on the adapter object — not a one-time parse, an actual property that participates in QML's ordinary binding graph.
- Caelestia's actual shipped implementation (MEDIUM confidence, DeepWiki) is exactly this: `services/Colours.qml` is a `Singleton` wrapping a `FileView`+adapter over `~/.local/state/caelestia/scheme.json`, exposing a `current` palette; every panel binds colors from `Colours.current.*` the same way this repo's CSS binds `@define-color`-derived names.

**Recommendation:** add a new matugen template, `quickshell-colors.json`, rendered to `~/.local/state/theme/quickshell-colors.json` (flat JSON: role name → hex, same role set as the existing GTK/AGS templates so `contract.sh`'s json-format extractor works unmodified). A new stowed singleton, `services/Colors.qml`, wraps a `FileView { path: "~/.local/state/theme/quickshell-colors.json"; watchChanges: true; onFileChanged: reload() }` + `JsonAdapter`. Every QML surface binds `color: Colors.primary` etc. — **zero hex literals in repo-authored QML**, identical spirit to zero hex literals in repo-authored CSS today.

**Why this is the correct analogue, not a workaround:** it satisfies "one render target per surface" (one JSON file, one contract entry, exactly like every other surface), "consumed live" (JsonAdapter properties are real QML properties — every binding depending on them re-evaluates automatically, no polling, no manual re-render call needed once `reload()` has updated the adapter), and "never copied" (nothing duplicates the JSON; the singleton is the sole reader).

**Reload behavior — this is a genuine improvement over every other surface in the fan-out, not a new limitation:**
- GTK3 surfaces (Thunar, previously Walker) need a **process restart** — no live CSS reload API exists.
- AGS (GTK4) needs an **explicit nudge** (`ags request reload-css`) that recompiles SCSS→CSS and calls `apply_css` — live, but not automatic; something has to tell it to re-run.
- **Quickshell needs neither.** Once `Colors.qml`'s `FileView` has `watchChanges: true` and its own `onFileChanged: reload()` wired (a few lines, written once, inside the singleton — not per-surface), the shell notices `commit.sh`'s write to `~/.local/state/theme/quickshell-colors.json` on the filesystem directly and updates every bound property automatically. **`theme-engine/lib/reload.sh` needs NO new case for Quickshell colors at all** — it is the one surface in the whole fan-out that self-heals without being told. (Verify this experimentally in Phase 11/12 rather than trusting it blind — MEDIUM confidence only, since Quickshell's own docs don't spell out whether adapter-property changes propagate through bindings with zero extra code, though this is how QML property bindings work in general and there is no documented exception for JsonAdapter.)
- The one thing reload.sh *does* need, defensively, mirroring the `style.css missing` notify-send guard already present for Walker: a presence check that `quickshell-colors.json` exists post-commit, surfaced the same way (non-fatal `notify-send` warning), since a missing/malformed file would otherwise fail silently inside the QML engine rather than loudly like a shell script's `set -e`.

---

## Q3 — Motion token pipeline: where fitting happens, contract extension, `motion-lint`

**The core design tension (confirmed by web research, MEDIUM confidence):** a damped-harmonic-oscillator spring (mass/stiffness/damping) is not a cubic curve. A single `cubic-bezier(x0,y0,x1,y1)` is, at best, a lossy visual approximation of one — it cannot reproduce overshoot/settle behavior exactly, only approximate it. The higher-fidelity alternative found in current CSS motion tooling (e.g. the `EaseMaster` tool, and CSS's newer `linear()` easing function) is to **sample** the closed-form spring position function at N points and emit either a many-point `linear(0, ...)` easing function or literal `@keyframes` — not to curve-fit a 4-point bezier. Hyprland's `bezier =` directive, by contrast, is hard-coded to exactly 4 numbers — sampling is not an option there; a genuine least-squares bezier fit is unavoidable for that one target.

This means **the pipeline needs different fitting strategies per target**, not one universal fit:

| Target | Native/best mechanism | Fitting needed? |
|---|---|---|
| QML (Quickshell) | `SpringAnimation`/`Behavior` take mass/stiffness/damping **directly** | None — raw values pass through unchanged |
| GTK4 CSS (waybar, swaync, walker, wleave, SwayOSD, AGS) | `@keyframes` (verified supported by GTK's CSS engine today, since GTK3/4 already support keyframe animations) sampled from the spring at N steps | Sampling only, no bezier fit (higher fidelity than a bezier approximation) — **use bezier as fallback only** if keyframe verbosity/perf becomes a real problem, which the human render-gate should judge, not assume up front |
| Hyprland `bezier =` | Exactly 4 control points | Genuine least-squares curve fit is unavoidable here — this is the one lossy target |

**Where the fitting happens — a new theme-engine build step, not a matugen template.** Matugen is a wallpaper→color extraction+templating tool; motion tokens are wallpaper-independent, hand-authored physics constants (mass/stiffness/damping), so there is nothing for matugen's color-extraction engine to do here — its templating *could* mechanically substitute static numbers, but the actual math (closed-form spring sampling, least-squares bezier fit for the Hyprland target) is real numerical work matugen has no facility for. Recommend a new `theme-engine/lib/motion.sh` (following the exact shape of `lib/contract.sh` / `lib/gtk.sh` — one function per concern, sourced not executed) that shells out to a small dedicated fitting helper (Python is the natural choice — closed-form damped-oscillator sampling and a least-squares 4-point bezier fit are a handful of lines with no exotic dependency beyond what's already needed for the repo's existing `python3 tomllib` usage in `contract.sh`).

**Source of truth:** a new, hand-authored, git-tracked `theme-engine/.config/theme-engine/motion-tokens.json` — the motion equivalent of `matugen/palettes/*.json` being the hand-authored color input. Example shape:

```json
{
  "springs": {
    "standard":   { "mass": 1, "stiffness": 300, "damping": 30 },
    "emphasized": { "mass": 1, "stiffness": 200, "damping": 20 },
    "decel":      { "mass": 1, "stiffness": 400, "damping": 40 }
  }
}
```

(Naming should absorb the "md3_decel"-style naming already used informally in wleave's entrance-cascade work — Phase 9's motion language should become one of these named springs, not a second parallel naming scheme.)

**Render targets, all landing in `~/.local/state/theme/` alongside the color renders (never copied, never git-tracked):**
- `quickshell-motion.json` — raw mass/stiffness/damping, passthrough (Colors.qml's sibling: `Motion.qml`, same FileView+JsonAdapter shape)
- `gtk-motion.css` — one `@keyframes spring-<name>` block per spring, sampled at N steps, plus a matching `--motion-<name>-duration` custom property, `@import`ed by every GTK4/GTK3 stylesheet the same way `gtk-colors.css` is today
- `hyprland-motion.conf` — one `bezier = <name>, x0, y0, x1, y1` line per spring, least-squares fit, `source`d by `hyprland.conf` the same way `hyprland-colors.conf`'s `$color*` variables are today

**Frequency mismatch with the existing pipeline — an explicit, deliberate deviation worth flagging:** color rendering is wallpaper-driven and re-runs on every `theme-apply` invocation (every theme switch); motion tokens are theme-invariant and only need to re-render when a human hand-edits `motion-tokens.json`. Recommend `motion.sh`'s render step still runs inside `theme-apply`'s pipeline (preserving the single-entrypoint principle — no second command a user must remember) but is **content-hash-gated** (skip the sampling/fitting work if `motion-tokens.json`'s hash matches the last-rendered hash, stored alongside the state dir) so it doesn't burn CPU on every ordinary theme switch. This is an implementation optimization, not a hard architectural requirement — flag it for the Phase 12 plan, not a blocking decision.

**`contract.json` extension:** add a sibling top-level array, e.g. `"motion_files"`, structurally identical to the existing `"files"` array (`{"name", "format"}` pairs), so `contract.sh`'s existing per-format dispatch (`gtk-css`, `hypr-vars`, `json`) is reused unmodified rather than inventing a second parallel schema:

```json
"motion_files": [
  { "name": "quickshell-motion.json", "format": "json" },
  { "name": "gtk-motion.css", "format": "gtk-css" },
  { "name": "hyprland-motion.conf", "format": "hypr-vars" }
]
```

**What a `motion-lint` gate should assert** (same shape as `theme-doctor`'s zero-hex-literal philosophy, applied to durations/curves instead of colors):
1. **GTK CSS surfaces** (waybar, swaync, walker, wleave, SwayOSD, AGS stylesheets): grep every repo-authored stylesheet (excluding the generated `gtk-motion.css` itself) for a raw `transition-duration`/`animation-duration`/inline `cubic-bezier(` literal — zero matches allowed; every animated rule must reference `var(--motion-*)` or `spring-<name>` from the generated file.
2. **Hyprland**: grep `windowrules.conf`/`hyprland.conf` for an inline 4-number bezier definition or an `animation = ...` line naming a curve that isn't one of the names emitted into `hyprland-motion.conf` — catches both "someone hand-rolled a curve" and "someone referenced a curve that no longer exists" (the same class of drift `theme-parity`'s name-set check already catches for colors).
3. **QML**: grep every `.qml` file outside `services/Motion.qml` for a raw numeric `duration:` or `easing.type: Easing.*` inside a `Behavior`/`SpringAnimation`/`NumberAnimation` block — every animated property must bind through `Motion.<name>`.

This is the same "single manifest, one shared extraction library, both checkers consume it" pattern `contract.json`/`contract.sh` already use for colors (`D-30`) — extend that library, don't build a fourth parallel one.

---

## Q4 — Coexistence: concrete conflict points and how to avoid each

v3.0 retires nothing (PROJECT.md, explicit scope boundary). Every conflict below is therefore a **must-avoid**, not a "decide later":

### Layer-shell namespaces (HIGH confidence — verified against `windowrules.conf`)

Existing namespaces with live layerrules today: `walker`, `wofi` (dead, inert), `waybar`, `swaync-control-center`, `swaync-notification-window`, `wleave`, `ags-media`. **No `quickshell*` namespace exists yet — zero collision risk today, but the new surfaces must each claim their own distinct namespace up front**, following the exact same per-surface-namespace convention already established (not one shared "quickshell" namespace for every panel, which would make per-panel blur/`ignore_alpha` targeting impossible — `ags-media`'s own namespace is exactly why its blur/alpha rules can be scoped independently of `walker`'s). Recommend: `quickshell-dashboard` (Phase 14), `quickshell-mixer` / `quickshell-connectivity` (Phase 15), `quickshell-overview` (Phase 16). Each new namespace needs its own `layerrule = blur on, match:namespace <name>` and `layerrule = ignore_alpha <threshold>, match:namespace <name>` pair added to `windowrules.conf`, following the exact pattern already used for `ags-media` — including the same alpha-budget math discipline documented there (composited scrim+card alpha must land above whatever `ignore_alpha` threshold is chosen, or the surface renders as raw unblurred transparency instead of frosted glass — this is a real, previously-hit bug in this repo, not theoretical).

QML's `WlrLayershell.namespace` (MEDIUM confidence, quickshell.org docs) is settable per-`PanelWindow` and **must be set before the window connects to the compositor** (cannot be changed after `windowConnected`) — meaning namespace choice is a startup-time constant per panel, not something toggled at runtime, which fits cleanly with static `layerrule` entries.

### Global keybinds (HIGH confidence — verified against `keybinds.conf`)

Already-claimed binds relevant to new QML surfaces: `$mainMod SUPER_L` (bare tap) → walker menu tree; `$mainMod, SPACE` → app launcher; `$mainMod, N` → swaync toggle; `$mainMod, C` / `$mainMod SHIFT, C` → clipboard history/wipe; `$mainMod, L` → lock; `XF86Audio*`/`XF86MonBrightness*` → `swayosd-client`; `XF86AudioNext/Pause/Play/Prev` → `playerctl`. **Any new dashboard/mixer/wifi/bluetooth/overview keybind must pick genuinely unclaimed chords** — Phase 7's own regression-sweep precedent (the ~48-bind sweep that caught zero regressions when walker's bind moved) is the right verification method to reuse here, not a fresh ad hoc check. Concretely avoid re-treading $mainMod+N (swaync), $mainMod+SPACE (launcher), and the bare-tap SUPER_L (walker menu) — none of these should be silently shadowed by a new Quickshell global shortcut. Quickshell's own docs note it can register global shortcuts Hyprland's dispatcher calls directly (MEDIUM confidence, DeepWiki on end-4) rather than only reacting to spawned processes — meaning a Quickshell global-shortcut registration is a **second, parallel keybind-registration mechanism** alongside Hyprland's own `bind =` lines; a bind defined in both places for the same chord is a real double-handling risk distinct from a simple duplicate-chord typo, and should be checked for explicitly (grep Quickshell's shortcut registrations against `keybinds.conf`'s full bind list, not just visually skim one file).

### MPRIS / media transport (HIGH confidence for what exists today; the QML addition is the new risk)

**MPRIS is already double-consumed today** — waybar's built-in `mpris` module (backed by `libplayerctl`) and the AGS media applet's `lib/media.ts` (backed by a bash `playerctl`-polling script) both independently read the same MPRIS player state right now. This is not a new problem v3.0 introduces; it is a precedent that multiple simultaneous MPRIS *readers* are already fine (MPRIS is a broadcast-style D-Bus interface — multiple listeners are normal and supported). The actual risk is **concurrent writers**: if a QML dashboard media widget (Phase 14) also issues `Play`/`Pause`/`Next` transport commands, it becomes a *third* transport-command sender alongside AGS and (if enabled) waybar's own click handlers. Recommend the same discipline already implicit in AGS's `cmd()`/`seek()`/`setVolume()` functions in `lib/media.ts` — issue a transport command **only on explicit user click on the currently-visible widget**, never a polling loop that re-issues state, so two open surfaces controlling the same player don't fight over redundant commands.

### PipeWire / volume (HIGH confidence for existing ownership; concrete rule for the new surface)

`swayosd-server` (autostarted, `hypr/.config/hypr/config/autostart.conf`) is the sole owner of hardware-key-triggered volume/brightness/mic-mute changes today, reached exclusively via `swayosd-client` bound to `XF86Audio*`/`XF86MonBrightness*` in `keybinds.conf`. Phase 15's per-app volume mixer is a **read+control UI over PipeWire/WirePlumber state**, not a hardware-key handler — it must not rebind `XF86Audio*` keys (that stays SwayOSD's job) and must not spawn its own competing OSD popup on every volume change; it should only render its own in-panel sliders when the panel itself is open. Concretely: the QML mixer talks to PipeWire directly (Quickshell ships a `Pipewire`/`Quickshell.Services.Pipewire` type per its own docs, not independently verified here — flag as a Phase 15 spike item) for its own UI state, while SwayOSD keeps owning the hardware-key → themed-pill path untouched.

### Product-boundary collision, not a technical one, but worth stating explicitly (HIGH confidence, both sides verified in-repo)

Three different surfaces already implement "a grid of quick toggles" independently: swaync's control-center toggle grid and the Super-key walker menu's toggle grid explicitly **share state** already (Phase 8, BAR-05: "sharing state with the Super-key menu"). Phase 14's dashboard drawer adding a *third*, unsynced toggle-grid implementation would reintroduce exactly the state-drift class Phase 8 deliberately closed. **Recommend the QML dashboard's quick-toggle grid read/write the same backing scripts/state files BAR-05 already established**, not a fourth reimplementation of toggle logic. Similarly, the existing $SUPER-tap walker menu already contains an "AI dashboard" (launchers + workspace) and other dashboard-flavored menu entries (Phase 7) — the product boundary between "walker menu = keyboard-driven ephemeral command palette" and "QML dashboard drawer = glanceable persistent panel" should be stated explicitly in the roadmap so scope doesn't silently duplicate (e.g. weather/calendar should not also get added to the walker menu tree).

### Autostart & install (HIGH confidence pattern, LOW confidence on the exact package name)

A new `exec-once = uwsm app -- qs -c <config-name>` (or equivalent) line belongs in `autostart.conf`, following the exact `uwsm app --` convention every other daemon already uses — but only from Phase 12 onward, **not Phase 11** (the viability gate is explicitly a manual, human-clicked proof "before anything is built," implying Phase 11's test harness is throwaway/manual `qs` invocation, not yet stowed or autostarted). `install.sh` needs a new package entry for Quickshell itself — verify the exact AUR/official-repo package name against the installed system (`pacman -Si`/AUR search) before writing it into `install.sh`, exactly the lesson this repo already paid for once with `adw-gtk3` vs `adw-gtk-theme` (Key Decision, v2.0 STACK.md). Do not assume the package name from a rice's own install script without verifying it against this machine.

---

## Q5 — Suggested build order: validated, with two corrections

The sketched order (11 viability gate → 12 token pipeline → 13 motion retrofit → 14 dashboard drawer → 15 audio+connectivity → 16 workspace overview → 17 ambient extras) is **directionally correct and should stand as the default**, for these hard-dependency reasons:

- **11 must be first, unconditionally.** It is a go/no-go gate on the toolkit itself (layer-shell, pointer input, focus, multi-monitor, hot reload on Hyprland 0.56.0). Every other phase assumes Quickshell works on this machine; building anything on an unproven toolkit is the exact eww failure this repo already lived through once (Phase 10's own fail-fast-viability-gate Key Decision exists precisely because of that history).
- **12 blocks 13, 14, 15, 16, and 17 — all of them.** Every later phase consumes either the color render targets, the motion render targets, or both (13 needs the fitted GTK-CSS/Hyprland motion targets; 14/15/16 need the QML `Colors.qml`/`Motion.qml` singletons; 17's ambient extras — animated wallpaper, dynamic cursors — plausibly need at least the color tokens, and cursor scaling motion plausibly needs the motion tokens too). Nothing after 12 can start meaningfully before it lands.
- **17 last is correct and already explicitly a cut-candidate** in PROJECT.md — it has no other phase depending on it, and only depends on 12.

**Correction 1 — 13 and 14 are not actually serially dependent on each other; they are two independent branches that both depend only on 12.** Phase 13 (motion retrofit) touches only *existing* GTK4/GTK3/Hyprland surfaces already covered by `theme-doctor`/`theme-parity`/`theme-stress-test` — it needs zero QML surface to exist. Phase 14 (dashboard drawer, the first real QML surface) needs the `Colors.qml`/`Motion.qml` singletons from 12, not anything from 13. Keeping 13 before 14 (as sketched) is still the right default — for two reasons that aren't hard blockers but are good risk management: (a) this repo's own established Key Decision ("a human render-and-look gate is load-bearing, not a formality" — twice burned, Phase 6 and Phase 8) means proving the spring→curve fitting reads correctly on *already-working, already-gated* surfaces is cheap and low-risk before spending phase budget on brand-new QML UI; (b) if the fitting quality needs rework after a human looks at it, it's far cheaper to fix before Phase 14 builds a QML surface on assumptions about how the motion should feel. But a roadmapper should know these two phases could be reordered or partially parallelized without breaking a dependency, if schedule pressure demands it — the sketched order is a risk-reduction choice, not a technical requirement.

**Correction 2 — Phase 16's *research question* should be pulled forward to run adjacent to Phase 11, even though its *build* work correctly stays at position 16.** PROJECT.md already flags workspace overview as "research-gated on the hyprexpo / `hyprland-toplevel-export-v1` plugin question" — this is a feasibility question (does the underlying Wayland protocol/plugin exist and work on this Hyprland build), structurally identical in kind to Phase 11's own viability gate, not an execution-complexity question like Phases 14/15. Leaving that research until Phase 16 arrives risks discovering a hard NO only after four other phases' worth of QML mileage and roadmap assumptions have been built around workspace overview being in scope. Recommend: **investigate the hyprexpo/toplevel-export question during or immediately after Phase 11**, record the verdict, and let the roadmap decide then whether Phase 16 stays scoped as originally sketched, shrinks, or gets marked as the next cut-candidate after 17 — while the actual *build* effort (if green-lit) still executes in its current position 16, after the dashboard/mixer/connectivity groundwork from 14/15 has proven the panel-lifecycle patterns out.

**Final validated order:** 11 → 12 → 13 → 14 → 15 → 16(build) → 17, with Phase 16's feasibility research executed early (alongside/after 11) rather than deferred to when Phase 16 starts.

---

## Anti-Patterns to Avoid (v3.0-specific)

### Anti-Pattern 1: Treating Quickshell's config directory like a per-widget stow package

**What people do:** create `quickshell-dashboard/`, `quickshell-mixer/`, etc. as separate stow packages, mirroring the "one package per feature" instinct.
**Why it's wrong:** Quickshell's own config model is single-base-path (`~/.config/quickshell/`); splitting it across stow packages means multiple packages folding into the same target directory, which is precisely the class of drift this repo's stow conventions exist to prevent, and contradicts the `ags/`-as-one-package precedent already set for the other JS/QML-adjacent toolkit in this repo.
**Instead:** one `quickshell/` package; separate concerns via subfolders (`services/`, `modules/`) inside it, matching Quickshell's own internal module convention.

### Anti-Pattern 2: Fitting a single cubic-bezier for every motion target because Hyprland needs one

**What people do:** compute one bezier-fit per spring and reuse it everywhere (QML, CSS, Hyprland) for consistency of implementation.
**Why it's wrong:** QML natively takes mass/stiffness/damping (no fitting needed, and fitting *loses* fidelity versus passing the real physics through); GTK CSS can do multi-point sampling for much higher fidelity than a 4-point bezier. Using the lossiest target's constraint (Hyprland's 4-point bezier) as the universal format throws away accuracy the other two renderers don't need to sacrifice.
**Instead:** per-target rendering as described in Q3 — raw passthrough for QML, sampled keyframes for CSS, fitted bezier only where the format hard-requires it (Hyprland).

### Anti-Pattern 3: Wiring Quickshell's color/motion reload into `theme-engine/lib/reload.sh`'s fan-out by default

**What people do:** add a new `if command -v qs; then qs ipc call ...; fi` block to `reload.sh`, treating every new surface as needing an explicit reload nudge, following the AGS/Walker/SwayOSD precedent reflexively.
**Why it's wrong:** unlike every other surface in the fan-out, Quickshell's `FileView`+`JsonAdapter` pattern is designed to self-heal by watching the filesystem directly — adding an explicit reload call is redundant work solving a problem that (per Q2) doesn't exist for this surface, and risks masking a real bug (if the file-watch wiring is broken, an extra "nudge" from reload.sh would paper over that instead of surfacing it).
**Instead:** verify the file-watch mechanism works unassisted in Phase 11/12's viability testing; only add a reload.sh case if that verification fails.

## Integration Points

### Internal Boundaries (new, v3.0)

| Boundary | Communication | Notes |
|----------|---------------|-------|
| matugen → `quickshell-colors.json` | matugen template render, same as every other target | New template, new `contract.json` entry, no new mechanism |
| `theme-engine/motion-tokens.json` → 3 motion render targets | new `lib/motion.sh` build step (Python-backed sampling/fitting) | Runs inside `theme-apply`, content-hash-gated; NOT a matugen template |
| `~/.local/state/theme/*` → Quickshell `Colors.qml`/`Motion.qml` | `FileView.watchChanges` + `JsonAdapter`, self-triggered | No `reload.sh` involvement expected (verify in Phase 11/12) |
| Hyprland global shortcuts ↔ Quickshell global shortcuts | two independent registration mechanisms, same physical keyboard | Must be cross-checked for double-registration, not just visual chord-uniqueness |
| SwayOSD ↔ QML audio mixer | disjoint: hardware-key path vs in-panel PipeWire control | Mixer must not rebind `XF86Audio*` or spawn a second OSD |
| swaync/walker-menu toggle grid ↔ QML dashboard toggle grid | shared backing state (Phase 8 BAR-05 precedent) | Do not reimplement a third toggle-state owner |

### External Services

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| Quickshell (`quickshell.org`) | AUR/pacman package, config at `~/.config/quickshell/` | Verify exact package name against `pacman -Si`/AUR before writing into `install.sh` — LOW confidence on the name itself |
| MPRIS (via PipeWire/WirePlumber or playerctl) | Quickshell likely ships a native service type (unverified — Phase 15 spike item) | Already double-consumed today (waybar + AGS); a third reader is safe, a third uncoordinated writer is the risk |
| hyprland-toplevel-export-v1 / hyprexpo | Wayland protocol / Hyprland plugin, existence and stability unverified on 0.56.0 | Research-gate this early (Q5, Correction 2), not at Phase 16 |

## Sources

- Direct repo inspection (HIGH confidence): `.planning/PROJECT.md`, `theme-engine/.config/theme-engine/contract.json`, `theme-engine/.config/theme-engine/lib/contract.sh`, `theme-engine/.config/theme-engine/lib/reload.sh`, `matugen/.config/matugen/config.toml`, `matugen/.config/matugen/templates/ags-colors.scss`, `stow.sh`, `hypr/.config/hypr/config/autostart.conf`, `hypr/.config/hypr/config/keybinds.conf`, `hypr/.config/hypr/config/windowrules.conf`, `ags/.config/ags/app.tsx`, `ags/.config/ags/style.scss`, `ags/.config/ags/lib/media.ts`, `waybar/.config/waybar/modules.jsonc`
- `quickshell.org` official docs (MEDIUM confidence, cross-checked across `/docs/configuration/intro/`, `/docs/types/Quickshell/PanelWindow/`, `/docs/types/Quickshell.Wayland/WlrLayershell/`, `/docs/types/Quickshell.Io/FileView/`) — config directory/manifest model, live-reload claim, `PanelWindow`/`WlrLayershell` namespace and exclusive-zone properties, `FileView`/`JsonAdapter` behavior
- DeepWiki index of `end-4/dots-hyprland` (LOW-MEDIUM confidence, AI-generated summary of real source, not the source itself) — `shell.qml`/`Config`/`Persistent`/`GlobalStates` singleton separation, Hyprland↔Quickshell IPC/global-shortcut integration, lazy-loaded UI "families"
- DeepWiki index of `caelestia-dots/shell` (LOW-MEDIUM confidence, same caveat) — `services/Colours.qml` reading `~/.local/state/caelestia/scheme.json` via watched JSON, `AppearanceTokens`-style design-constant singleton precedent
- Web search (LOW confidence, general web, not rice-specific): spring-to-cubic-bezier fitting techniques, CSS `linear()` easing / keyframe-sampling as a higher-fidelity alternative to bezier-fitting, Hyprland `bezier =` config syntax (and a note that Hyprland's config format may be migrating toward Lua `hl.curve(...)` in some version range — **verify against the actual installed 0.56.0 binary/schema before committing the Hyprland motion template**, following this repo's own established "verify against installed binary schema" lesson from the Phase 4 hyprlock incident)

---
*Architecture research for: v3.0 Quickshell Foundation & Motion Language*
*Researched: 2026-07-26*
