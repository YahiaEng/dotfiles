# Phase 8: Waybar Evolution - Research

**Researched:** 2026-07-14
**Domain:** waybar (GTK3 status bar) OLED behavior, Hyprland IPC, eww (new component), swaync panel widgets, mpris/playerctl
**Confidence:** MEDIUM-HIGH — the three ⚠ mandated verifications are directly evidenced against the installed binaries; the eww-specific claims (a brand-new component with nothing installed locally) lean on cross-checked WebSearch/WebFetch and are flagged accordingly.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**OLED-safe behavior (BAR-01)**
- D-01: The bar hides on TWO independent triggers — idle timeout AND fullscreen. Either condition alone hides it; it returns when both clear.
- D-02: Reveal is "any input + keybind only" — NO edge-hover reveal. Idle-hide clears on any keypress/mouse move. Fullscreen-hide persists, overridden only by an explicit keybind.
- D-03: ONE owner script + state file owns bar visibility. Four actors (idle watcher, fullscreen watcher, gaming-mode, keybind) call a single `waybar-visibility`-style entrypoint with an intent; the owner computes resulting state. Phase 7's `_gaming_waybar_toggle` re-points to this owner. **Explicitly killed:** everyone-sends-SIGUSR1 toggle.
- D-04: Exclusive zone is trigger-dependent. Idle-hide KEEPS reserved space (no window reflow during normal work). Fullscreen-hide and gaming-mode-hide DROP it.
- D-05: Idle signal comes from a hypridle listener (on timeout → hide; on resume → show). Must handle Phase 7 gaming mode SIGSTOPping hypridle.
- D-06: OLED styling only as far as it doesn't fight the theme. Translucency + trim highest-luminance elements (3px solid `@primary` border, filled workspace pills). Every color still from the palette. True-black rejected.
- D-07: Hide/reveal is animated (slide/fade), matched to Hyprland's animation feel. **⚠ Constraint:** waybar has no native hide animation — research must prove a clean GTK-transition/margin approach exists on the installed binary; if not, fall back to instant WITH documented evidence, do NOT build a bespoke animation harness.
- D-08: Overlays are not a visibility intent. Bar stays hidden if hidden when walker/swaync/a picker opens.

**Pixel-shift (BAR-02)**
- D-09: Timeboxed spike, then decide with explicit kill criteria (perceptible twitch / reflows windows / needs to coordinate with the visibility owner). Explicitly best-effort, descope-with-evidence is a valid literal reading.
- D-10: If descoped, evidence lands in `08-VERIFICATION.md`. No silent drop.
- Standing hypothesis: D-01 auto-hide + D-06 low-luminance styling may already remove most exposure — must be demonstrated, not assumed.

**Vertical layout (BAR-03)**
- D-11: ONE vertical layout designed for the column, not a rotated copy.
- D-12: Module set = essentials + system stats, glyph-reduced: workspaces, stacked clock, volume, network, battery, notification button, media trigger, cpu/memory/temperature as stacked readouts, tray, power.
- D-13: Detail that can't fit goes to tooltips (window title, now-playing text).
- D-14: Narrow and unobtrusive — slim column, same rounded/translucent treatment, flush left with margin.
- D-15: Appears on every monitor (no `output` key). No per-monitor config.
- D-16: NOT the default layout. `waybar-launch.sh` gets a 4th valid value.
- D-17: "Full module re-test" discharged by a rerunnable gate (every module class resolves to a real named color) + a human pass on one light/one dark preset. Prefer folding into `theme-doctor`.

**Media center (BAR-04)**
- D-18: A dedicated popup built with eww. Chosen over waybar group drawer, routing to swaync's mpris widget, or bespoke GTK4 popover. Most expensive option, only one adding a new component to the theme pipeline. GTK4 rejected — PROJECT.md records full GTK4/libadwaita palette theming as structurally unsupported upstream.
- D-19: eww adds a NEW matugen template + contract target + parity fixtures across 22 palettes. First-class render target, not an afterthought.
- D-20: eww's scope is the media popup NOW; sanctioned for future widgets. Hard boundary: waybar stays the bar, swaync stays notifications, walker stays the menu. eww does not draw the bar in this phase.
- D-21: Popup is full-fat: album art, artist/title/album, prev/play-pause/next, draggable seek bar, volume slider, AND an explicit player switcher.
- D-22: Inline mpris bar segment STAYS and becomes the popup's trigger. Rethink existing scroll-to-volume / right-click-next bindings so they don't fight the popup.
- D-23: Popup anchors under the bar segment it was launched from, closes on re-click/click-away/Esc. **⚠ Verify feasibility first:** waybar modules are not real windows; true anchoring under Hyprland's layer-shell may not be available. If not, fall back to a fixed position (near where swaync opens) — must work identically from every layout including vertical and hidden-bar.
- D-24: `mpris` REMOVED from swaync's widget list. eww popup is THE media center.
- D-25: No player → no bar segment → no popup. No "nothing playing" placeholder.

**Notification center (BAR-05)**
- D-26: Scope is parity (custom/notification lands in floating + vertical) + a swaync panel rework.
- D-27: Panel keeps sliders + a small toggle grid on top of notifications + dnd + clear-all.
- D-28: Toggle grid = gaming mode + DND + theme. **⛔ HARD CONSTRAINT:** every toggle must call the SAME script and read the SAME state file as the Super-key menu entry (`gaming-mode-toggle.sh`, `~/.cache/gaming-mode`, `theme-switch.sh`). No second copy of logic, no independently-derived state.
- D-29: "Interact" = inline actions + per-notification dismiss (not just clear-all).
- D-30: Panel geometry (today: top-right, 380px, 10px margins) revisited during design.

**Layout config drift (delivery risk)**
- D-31: Refactor to shared module definitions + per-layout composition. **⚠ Verify first:** confirm waybar 0.15.0's `include` semantics (merge order, key-override) against the installed binary before the plan leans on it. If weaker than advertised, refactor as far as it genuinely allows and stop. Do NOT build a preprocessor.
- D-32: Both `waybar-switch.sh` and `waybar-launch.sh` enumerate layouts from disk (glob `config-*.jsonc`) instead of hardcoding.
- D-33: Refactor ships FIRST, standalone, changing NO behavior.
- D-34: Refactor gated by asserting rendered-config equivalence (dump/compare resolved config per layout) + human pass.

**Inherited scope**
- D-35: Gaming-mode waybar indicator IN — reads `~/.cache/gaming-mode`.
- D-36: eww joins `install.sh` under the standard package gate — official repos strongly preferred, AUR gets human legitimacy check at execution time. Container gate must stay green and unattended; eww is a compiled Rust binary (build time is real, not an afterthought).
- D-37: New bar-toggle keybind follows the Phase 7 contract — lands in `keybinds.conf` with trailing `# description`.

### Claude's Discretion
- The idle timeout value (D-05) — a sane default as a single tunable constant.
- Exact module list for the vertical bar within D-12's constraint.
- Pixel-shift jitter magnitude/interval if D-09's spike survives — tunable constants.
- Exact bar-toggle chord and cheat-sheet wording (D-37).
- eww widget internals: yuck/SCSS structure, polling strategy for the seek bar, player switcher presentation.
- Whether D-17's module-color assertion folds into `theme-doctor` or stands alone (fold preferred).
- Panel geometry after D-27/D-28 widgets are designed (D-30).

### Deferred Ideas (OUT OF SCOPE)
- eww widgets beyond the media popup (calendar, dashboard, gaming overlay) — sanctioned in principle, out of scope for Phase 8.
- Vertical as the default layout — rejected (D-16).
- Per-monitor bar configuration — rejected (D-15).
- Edge-hover reveal — explicitly rejected (D-02), not deferred.
- True-black OLED bar background — explicitly rejected (D-06), not deferred.
- A "nothing playing" placeholder in the media popup — rejected (D-25).
- Redesigning the three existing bars' visual identity — out of scope; D-31 is behavior-preserving, D-06 is a luminance trim.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| BAR-01 | OLED-safe behavior — auto-hide when idle/unneeded + translucent minimal styling | Visibility Owner Design (below) resolves D-01..D-05, D-07, D-08 with a verdict; OLED Styling section resolves D-06 |
| BAR-02 | Pixel-shift mitigation, best-effort, descope-with-evidence allowed | Pixel-Shift Spike Guidance section gives the planner concrete jitter mechanics + kill-criteria checklist |
| BAR-03 | Additional vertical (left) layout, full module re-test not copy-paste | `include` Semantics verdict (D-31) + Vertical Layout Module Set section + D-17 gate design |
| BAR-04 | Media center via eww, mpris, form factor per modern-rice research | eww Component Research section (package, SCSS theming, yuck patterns, mpris/playerctl details, anchoring verdict) |
| BAR-05 | Notification center button + swaync panel rework | swaync Widget Schema section (verified against installed 0.12.6 configSchema.json) gives exact widget types for D-27/D-28 |
</phase_requirements>

## Summary

This phase lands on an already-90%-built foundation: the `mpris` module, the `custom/notification` bell, and swaync's own mpris widget all already exist and work. The real work is (1) a **behavior-preserving refactor first** (D-31/D-33) that the installed waybar 0.15.0 binary genuinely supports via its documented `include` directive — verified directly against `waybar(5)`; (2) a **single visibility-owner script** driven by hypridle + a Hyprland fullscreen-event listener, using waybar's configurable `on-sigusr1`/`on-sigusr2` signal actions (not raw toggle) for idempotent set-hidden/set-visible semantics; (3) a **new vertical layout** that is pure JSONC/CSS composition on top of the existing `waybar.css` contract target — zero new render targets; (4) a **brand-new eww component** for the media popup — this is the phase's only genuinely new toolkit, AUR-only, GTK3-based (so it CAN follow this repo's full named-color CSS pipeline, unlike GTK4), and (5) a **swaync panel rework** using widget types (`slider`, `volume`, `backlight`, `buttons-grid`) that are directly confirmed present in the installed swaync 0.12.6 schema, including a live example of exactly the toggle-with-`update-command` pattern D-28 requires.

**Primary recommendation:** Ship the refactor (D-31/D-33/D-34) as its own first plan using the shared-module-definitions shape verified below; build the visibility owner as configurable-signal-based (not toggle-based); treat D-07's animation as a documented instant-fallback (evidence below is strong); treat D-23's anchoring as achievable via `hyprctl cursorpos` at click-time (a real, verifiable mechanism) with the CONTEXT-documented fixed-position fallback as a zero-risk alternative if the planner prefers less surface area.

## Architectural Responsibility Map

This project has no web-tier architecture; the table below substitutes the desktop-rice equivalent tiers (compositor, system daemon, orchestration script, theme pipeline, presentation/CSS).

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Bar visibility (show/hide) | Orchestration Script (`waybar-visibility.sh`, new) | System Daemon (waybar, via configured signal actions) | Single owner computes intent from 4 actors; waybar only executes the resulting map/unmap via a signal it's been told a fixed action for — never decides for itself |
| Idle detection | System Daemon (hypridle, existing) | Orchestration Script | hypridle already owns every other idle-triggered action (dim/lock/dpms/suspend); a new `listener` block is the natural home, calling the owner script on timeout/resume |
| Fullscreen detection | Compositor (Hyprland event socket2) | Orchestration Script (listener process) | Only the compositor knows true fullscreen state; a small long-running listener subscribes to `.socket2.sock` and calls the owner script on `fullscreen>>` transitions |
| Pixel-shift mitigation | Presentation (CSS margin jitter) | Orchestration Script (interval timer) | Purely a rendering trim; the timer driving it must route through the same owner (D-09's kill-criterion #3) to avoid a second uncoordinated bar-mover |
| Vertical layout | Presentation (JSONC config + CSS) | Theme Pipeline (existing `waybar.css` contract target) | New layout is config/CSS composition only; colors still flow from the one existing render target — zero new theme-pipeline surface |
| Media popup UI | Presentation (eww yuck/SCSS, new) | System Daemon (playerctl/mpris D-Bus) | eww owns UI + polling glue scripts; playerctl/mpris remains the actual data source, same pattern waybar's existing `mpris` module already uses |
| Media popup trigger | System Daemon (waybar `on-click`) | Orchestration Script (cursor-pos → `eww open`) | The bar module click fires a thin script that computes an anchor position and calls eww; waybar itself has no coordinate-passing capability |
| Notification panel widgets | System Daemon (swaync `config.json`) | Orchestration Script (`gaming-mode-toggle.sh`/`theme-switch.sh`, REUSED) | swaync natively renders sliders/toggle-grid; D-28 forbids swaync from owning any logic — it only calls out to and reads state from the existing scripts |
| Layout config refactor | Presentation (shared JSONC/CSS includes) | — | Pure config-layer restructuring; no new runtime component |
| Gaming-mode indicator | Presentation (new waybar module) | Orchestration Script (reads existing state file) | Read-only consumer of `~/.cache/gaming-mode`; no new write path introduced |
| eww color theming | Theme Pipeline (new matugen template + `contract.json` entry) | Presentation (eww SCSS `@import`) | Must become a first-class render target exactly like every other themed surface (D-19) |

---

# ⚠ Priority Verdicts (D-07, D-23, D-31)

## VERDICT 1 — D-07: Waybar hide/reveal animation

### **VERDICT: FALLBACK REQUIRED — instant hide/reveal, with documented evidence below.**

**Evidence (HIGH confidence — VERIFIED directly against the installed `waybar.5.gz` man page on this machine, `waybar 0.15.0-2`):**

The full "BAR CONFIGURATION" section of `waybar(5)` was read in full (`zcat /usr/share/man/man5/waybar.5.gz`). There is **no** transition-duration, animation, or easing option anywhere in the bar-level config schema. The only visibility-related mechanisms are:

- `mode` (`dock`/`hide`/`invisible`/`overlay`) — a static, config-time display mode
- `start_hidden` (bool) — initial state only
- `on-sigusr1` / `on-sigusr2` (configurable to `show`/`hide`/`toggle`/`reload`/`noop`) — see Visibility Owner Design below
- `modifier-reset` — timing of modifier-key visibility reset, sway-IPC-flavored, not applicable without Sway IPC

None of these expose a duration, easing curve, or any animation primitive. `show`/`hide` are **binary map/unmap operations** on the underlying wlr-layer-shell surface — there is no "animated unmap" concept in the layer-shell protocol or in `gtk-layer-shell` (the library waybar and eww both use). A surface is either mapped (visible, exclusive-zone-eligible) or unmapped (gone) — nothing in between that GTK CSS can animate, because GTK CSS transitions operate on a *mapped* widget's style properties, not on the map/unmap transition itself.

**Corroborating evidence (MEDIUM confidence — WebFetch, cross-read against 2 GitHub issues):**
- [`Alexays/Waybar#1533`](https://github.com/Alexays/Waybar/issues/1533) ("Margins on `window#waybar`"): a user applying `margin-left: 100px` via CSS on `window#waybar` reports "The border is always glued right to the edge" — i.e. **CSS margin on `window#waybar` does NOT reposition the actual layer-shell surface.** This directly rules out a margin-transition slide animation: the real anchored position is controlled by the bar-config `margin-top`/`margin-left`/etc. options (set once, at layer-shell-surface-creation time), not by CSS.
- [`Alexays/Waybar#3853`](https://github.com/Alexays/Waybar/issues/3853) ("Feature: Auto-Hide") is an **open, unresolved feature request** as of this research — confirming no built-in animated auto-hide ships in this waybar lineage.

**Conclusion:** The "clean GTK-transition / margin approach" the CONTEXT mandate asked us to try to prove does **not** exist on the installed binary. Per D-07's own instruction, fall back to **instant** show/hide — do NOT build a bespoke animation harness (e.g., don't hand-roll a fake-surface compositor animation or a GTK widget that manually interpolates layer-shell margins frame-by-frame; that is exactly the "bespoke animation harness" the decision forbids).

**One zero-risk bonus worth noting, NOT a plan dependency:** the *idle-hide* path (see Visibility Owner Design below) is recommended to use a CSS-driven near-invisible state (to satisfy D-04's "keep exclusive zone" requirement) rather than a true unmap. Because that path keeps the widget mapped and only changes CSS properties (opacity/background) via a style-provider reload, it is *theoretically* possible GTK animates that transition if `window#waybar` carries a `transition: opacity 0.3s ease;` rule (this repo's existing `style-full.css` already proves GTK3 CSS transitions work for other elements, e.g. `#workspaces button { transition: all 0.3s ease; }`). Whether a full CSS-provider hot-reload (via SIGUSR2) triggers that transition, versus snapping instantly, is **unverified** — untestable without a live interactive waybar session. If the planner wants to spend a few minutes on this, it's free to try (same reload machinery is needed regardless); if it doesn't animate, no harm — the design already defaults to instant. Do not make this hypothesis a task dependency or acceptance criterion; treat it as an optional bonus a task MAY note as "attempted, animated: yes/no" but the requirement is satisfied either way by the instant fallback.

---

## VERDICT 2 — D-23: eww popup anchored under the launching bar module

### **VERDICT: A real (not fabricated) anchoring mechanism exists — cursor-position-at-click-time — but it is NOT waybar-native module-coordinate anchoring. Recommend it as primary, with the CONTEXT-documented fixed position as a zero-risk fallback.**

**What does NOT exist (HIGH confidence, VERIFIED against `waybar(5)` "MODULE FORMAT" + `waybar-custom(5)`):** waybar's `on-click` (and all `on-click-*`) actions are plain shell command strings. There is no variable substitution for click coordinates, module screen position, or module dimensions anywhere in the module config schema. Waybar modules are GTK widgets inside one process's window — they are not separate wlr-layer-shell surfaces, so Hyprland/the compositor has no independent handle on "where module X is" either. **True per-module anchoring, as CONTEXT.md's own framing anticipated, is not available.**

**What DOES exist (mixed confidence):**
- `hyprctl cursorpos` — **HIGH confidence, VERIFIED live on this machine** (`hyprctl cursorpos` → `712, 652`). This returns the current pointer position in global compositor coordinates at the instant it's invoked.
- eww's `:geometry`/`:anchor`/`x`/`y` window properties accept **dynamic per-open values via `--arg`** — **MEDIUM confidence, WebFetch of the official eww configuration docs**: "x and y values will be relative to anchor... window arguments are specified during the `eww open` command using `--arg` flags... e.g. `--arg x=value --arg y=value`."
- eww's `--toggle` flag on `eww open` — **MEDIUM confidence, WebSearch cross-referenced by a "SOLVED" community issue** (`elkowar/eww#333`): `eww open --toggle windowname` opens if closed, closes if open. **Exact flag spelling should be re-confirmed with `eww open --help` once the package is actually installed** (a zero-cost first task) — the community reports both `-toggle` and `--toggle` spellings across versions/discussions.

**Recommended mechanism (primary):** the waybar `mpris` module's `on-click` script, instead of calling `playerctl play-pause` directly (see D-22 rework below), calls a small wrapper that:
1. Reads `hyprctl cursorpos` (x, y — this is approximately where the module was clicked, since the cursor is necessarily over the module for the click to register)
2. Clamps the popup's intended top-left corner to stay on-screen (using `hyprctl monitors -j` for the active monitor's resolution)
3. Calls `eww open media-popup --toggle --arg x=$X --arg y=$Y`

This works identically for every layout (top-horizontal, floating-island, vertical-left) and does not care whether the bar is currently "hidden" in the D-01/D-04 sense, because per D-25 the media trigger simply doesn't render when there's no player — there's nothing to click when hidden either way, so no special-casing is needed (consistent with D-08's "overlays are not a visibility intent" philosophy).

**Fallback (zero-risk, CONTEXT-documented):** a fixed position (e.g., top-right corner near where swaync opens, or bottom-right for a vertical/left bar) requires no `hyprctl cursorpos` call and no clamping logic — just a static `:geometry` in the eww window definition. Use this if the planner wants to minimize new moving parts; it satisfies D-23's literal fallback clause and is trivially portable across all four bar states (three layouts × hidden/visible).

**Recommendation:** attempt the cursor-position approach first (it is real engineering, not a fabricated capability — both `hyprctl cursorpos` and eww's `--arg` position injection are independently verified to exist) since it delivers the actual UX D-23 asks for; if a spike shows jitter/inaccuracy (e.g., popups usually spawn slightly off from expectation because `cursorpos` is read a frame after the click), fall back to the fixed position without further debate — this satisfies D-23's own "verify first, fallback is fine" framing.

**Close-on-click-away/Esc:** eww supports `:onlostfocus` and `(keyevent :key "Escape" ...)` window properties (WebSearch, MEDIUM confidence, cross-referenced against `elkowar/eww#472`) — e.g. `(defwindow media-popup :onkeypressed (keyevent :key "Escape" :command "eww close media-popup") :onlostfocus "eww close media-popup" ...)`. Re-click-to-close is naturally handled by `--toggle`.

---

## VERDICT 3 — D-31: waybar `include` semantics

### **VERDICT: PRIMARY APPROACH VIABLE, with one shape constraint the plan must respect.**

**Evidence (HIGH confidence — VERIFIED directly against the installed `waybar.5.gz` man page):**

> `include` — typeof: string|array. Paths to additional configuration files. Each file can contain a single object with any of the bar configuration options. **In case of duplicate options, the first defined value takes precedence, i.e. including file -> first included file -> etc.** Nested includes are permitted, but make sure to avoid circular imports. For a multi-bar config, the include directive affects only current bar configuration object.

**This is whole-key, first-defined-wins override — NOT a deep/recursive merge.** If both the including file (e.g. `config-vertical.jsonc`) and an included file (`modules.jsonc`) define the same top-level key (say, both define `"clock"`), the version that resolves FIRST wins **in its entirety** — the other file's `"clock"` object is discarded wholesale, not merged property-by-property. This matters directly for the refactor's design:

**The clean shape (no preprocessor needed):**
- A shared `waybar/.config/waybar/modules.jsonc` defines ONLY module-definition objects (`"mpris": {...}`, `"clock": {...}`, `"custom/notification": {...}`, `"tray": {...}`, etc.) — and **never** `modules-left`/`modules-center`/`modules-right` or bar-level keys (`layer`, `position`, `height`, `margin-*`).
- Each per-layout `config-{minimal,full,floating,vertical}.jsonc` declares `"include": ["modules.jsonc"]` plus its OWN `modules-left/-center/-right` arrays and bar-level options.
- If a layout needs a variant of a shared module (e.g., vertical's glyph-only `mpris` per D-13, or floating's differently-formatted `clock`), that layout's file simply redefines that key **in full** (not a partial patch) — since it's the *including* file, its definition wins over the included one, exactly per the documented precedence rule.

Because module-definition keys and layout/array keys never overlap between the two file classes under this design, first-wins semantics never actually create a conflict — the refactor is fully expressible with plain `include`, confirming D-31's design intent is achievable on the installed binary as-is. **Do not build a preprocessor or templating layer; the native directive is sufficient.**

**CSS side (favorable asymmetry):** waybar's CSS has no JSON-style `include`, but CSS's native `@import url(...)` (already used in this repo — every `style-X.css` imports `~/.local/state/theme/waybar.css` + `waybar-font.css`) gives the CSS-side refactor a shared `waybar-modules.css` imported first, with each layout's own `style-X.css` free to override **individual properties** afterward via normal CSS cascade (later rule wins, at the *property* level, not whole-selector). This is actually MORE granular than the JSONC side — a layout can tweak one property of a shared module's CSS block without redeclaring the whole selector, unlike the JSONC module-definition case above.

**D-34's equivalence gate — how to mechanically dump/compare resolved config (HIGH confidence, VERIFIED — `waybar --help` shows only `-c/-s/-l/-b/-v/-h`, no dump/print flag exists):**

waybar has **no** `--print-config`/`--dump-config` flag. The equivalence check must be a small hermetic script (Python, using the already-installed `jq`/`python3`) that:
1. Strips `//` line comments and `/* */` block comments from JSONC (waybar's JSONC is a superset of JSON with comments; a simple regex or `json5`/`commentjson`-style strip is sufficient — no waybar-specific parser needed)
2. Recursively resolves `include` arrays per the documented first-wins/nested-include rule above (walk includes depth-first, only set a key if not already set — exactly mirrors "including file -> first included file -> etc.")
3. Emits one normalized (recursively key-sorted) JSON object per layout
4. Diffs that object against a **pre-refactor snapshot** of each original standalone `config-{minimal,full,floating}.jsonc` (same strip + key-sort, captured before D-33's refactor lands)

Zero diff = behavior-preserving. This script is new and hermetic — it belongs alongside `theme-doctor`/`theme-parity` as a rerunnable gate (same precedent), not a one-time checklist. It is an **equivalence checker**, not a preprocessor waybar itself runs — waybar still resolves the real `include` at its own runtime.

**Note for the planner:** `theme-doctor`'s existing GTK CSS-parse guard (D-17's likely home) currently hardcodes its 3-file list (`style-{full,minimal,floating}.css`, verified live at `theme-doctor` lines 196-198). Adding vertical requires a 4th line there too — this is a small, easy-to-miss 4th occurrence of the exact copy-paste-drift class D-31 exists to fix, even though CONTEXT.md's D-32 only names `waybar-switch.sh`/`waybar-launch.sh` explicitly. Flag this to the planner as a related touch-point, not a new locked decision.

---

# Supporting Research

## Visibility Owner Design (D-01..D-05, D-08)

**The core problem CONTEXT.md poses:** waybar's default `on-sigusr1` action is `toggle` — safe only if exactly one thing ever sends it and always knows current state. Four actors (idle watcher, fullscreen watcher, gaming-mode, keybind) want to move the bar. A raw shared toggle desyncs (exactly the bug class this repo has deleted twice already, per PROJECT.md).

**Key discovery (HIGH confidence, VERIFIED against `waybar(5)`):** `on-sigusr1` and `on-sigusr2` are independently **configurable to a FIXED action**, not forced to be `toggle`:

```
on-sigusr1  — default: toggle. Possible values: show, hide, toggle, reload, noop.
on-sigusr2  — default: reload. Possible values: show, hide, toggle, reload, noop.
```

And critically: `reload` is documented as **"basically equivalent to restarting with updated config which sets initial visibility values"** — i.e., since this repo's configs never set `start_hidden: true`, sending the reload-configured signal **always resets the bar to visible**, regardless of its current state. That makes `reload` an idempotent "show" action for free — and it's already the signal the theme pipeline uses for CSS reload after a theme switch, so reusing it costs nothing.

**Recommended design (no preprocessor, no toggle, no raw multi-actor signaling):**

```jsonc
// in every layout's shared bar-level config (via modules.jsonc or each config-X.jsonc):
"on-sigusr1": "hide",     // fixed action — ALWAYS hides, never toggles
"on-sigusr2": "reload"    // fixed action — default, UNCHANGED, already used by theme-switch's post_hook
```

- **`killall -SIGUSR1 waybar`** → idempotent **true hide** (unmap; per the wlr-layer-shell/sway-bar `hide` semantics researched below, this DROPS the exclusive zone) — use for the **fullscreen** and **gaming-mode** triggers (D-04 wants the zone dropped there anyway).
- **`killall -SIGUSR2 waybar`** → idempotent **show/reset** (already wired for theme-switch; reused, not repurposed) — use as the universal "reveal" action for any hidden state.
- **Idle-hide (D-04 wants the exclusive zone KEPT)** cannot use the true-hide signal above, because sway-bar's `hide` mode semantics (which waybar's `mode`/signal-hide options mirror, per `waybar(5)`'s explicit cross-reference — **MEDIUM confidence, WebSearch of `sway-bar(5)`**: "Hide: the bar is hidden unless the modifier key is pressed... Invisible: the bar is permanently hidden" — the entire point of a hidden bar mode is to give the reclaimed screen space back) will drop the exclusive zone same as fullscreen-hide would. Recommend: for idle-hide, do **not** unmap the bar at all — instead have the owner script overwrite a small, owner-owned CSS file (e.g. `~/.local/state/theme/waybar-visibility.css`, imported by every `style-X.css` AFTER the theme import) with either empty content (normal) or a near-invisible override (`window#waybar { opacity: 0.05; }` or similar, tuned during implementation) — then send the SAME `SIGUSR2` reload signal to force waybar to re-read it. The surface stays mapped (exclusive zone intact, no reflow — satisfying D-04's idle case) while going visually dark (satisfying the OLED goal). This is a NEW small state file the owner script owns exclusively — consistent with the existing "runtime-only state overrides, never Hyprland-config rewriting" pattern (P7 D-26), since this rewrites a *CSS render artifact* the owner script itself owns, not a source config or hyprland.conf.

**Owner script intent model (satisfies D-03):**

```
waybar-visibility.sh <intent-source> <hide|show>
```//
Each of the four actors calls this with their OWN name and desired state; the script tracks each source's last-known desire in the state file (e.g. `~/.cache/waybar-visibility` as a small `source=state` map or one file per source under a directory), computes the union per D-01's "hides on EITHER condition" rule, and only sends a signal (SIGUSR1/SIGUSR2) when the COMPUTED result actually changes — never sends redundant signals, which is what makes toggle-based races unnecessary here even though toggle itself is avoided entirely per D-03's explicit kill.

**Gaming-mode SIGSTOP interaction (D-05's flagged risk):** `gaming-mode-toggle.sh` (read directly, confirmed live) already `SIGSTOP`s hypridle on gaming-mode-ON and `SIGCONT`s it on OFF. Since the idle-hide trigger depends entirely on hypridle's listener firing, a frozen hypridle means the idle-hide intent simply freezes in whatever state it was in when gaming mode engaged — it does not un-hide or misbehave, it just stops updating, which is a benign/acceptable interaction (gaming-mode's own hide intent takes over regardless, per D-01's OR-of-two-triggers logic). No special handling needed beyond noting this in the plan; the "gaming-mode-hide" intent and "idle-hide" intent are independent inputs to the same union computation.

## Fullscreen Detection (D-01)

**HIGH confidence, VERIFIED live on this machine:**
- `hyprctl activewindow -j` / `hyprctl clients -j` expose a `"fullscreen"` integer field (currently `0` for non-fullscreen windows on this machine) and a `"fullscreenClient"` field.
- The Hyprland event socket exists at `$XDG_RUNTIME_DIR/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock` (verified: `/run/user/1000/hypr/<sig>/.socket2.sock`, a live Unix socket).

**MEDIUM confidence, WebSearch cross-referenced across the official Hyprland IPC wiki + a GitHub discussion (`hyprwm/Hyprland#13041`):** socket2 emits line-delimited `EVENT>>DATA` events, and a `fullscreen` event is among the documented event names (`workspace`, `activemon`, `activewindow`/`activewindowv2`, `fullscreen`, `monitoradded`/`monitorremoved`, etc.). The GitHub discussion explicitly warns: **"a fullscreen event is not guaranteed to fire on/off once in succession — some windows may fire multiple requests."** The owner script's fullscreen listener must therefore be idempotent (re-asserting "fullscreen: hide" twice is harmless under the intent-union design above) rather than assuming exactly one event per state change.

**Recommended listener mechanism:** a small long-running script (bash `while read` loop, or Python) connects to `.socket2.sock` and greps for `fullscreen>>` lines, calling `waybar-visibility.sh fullscreen hide` / `... show` accordingly. `socat` (the conventional tool for this, e.g. `socat -U - UNIX-CONNECT:$SOCK`) is **NOT currently installed** (`pacman -Q socat` → not found) but IS available in the official `extra` repo (`pacman -Ss socat` → `extra/socat 1.8.1.1-1`) — a one-line `install.sh` addition if the planner chooses the socat route. Alternatively, Python (already present system-wide, `python 3.14.6-1` confirmed installed) can open the Unix socket directly via the stdlib `socket` module with zero new packages — a lower-dependency-cost option worth considering since this script needs to run as a long-lived background process for the life of the session (likely another `exec-once` entry in `autostart.conf`, alongside the existing hypridle/waybar-launch lines).

Do NOT poll `hyprctl activewindow -j | jq .fullscreen` on an interval as the primary mechanism — that's simple but adds latency and constant subprocess spawning; the event socket is the correct, idiomatic Hyprland pattern and is what every other Hyprland automation tool (hyprwhenthen, etc., per WebSearch) uses.

## Exclusive Zone Behavior (D-04)

**MEDIUM confidence (WebSearch, sway-bar(5) semantics — waybar's own man page explicitly says its `mode` option "is an equivalent of the sway-bar(5) mode command and supports the same values"):**

| Waybar state | Exclusive zone | Trigger |
|---|---|---|
| Mapped, normal CSS | Reserved (current behavior, unchanged) | — |
| Mapped, CSS-dimmed via `waybar-visibility.css` override + SIGUSR2 reload | **Reserved (kept)** — surface never unmaps | Idle-hide (D-04 requirement) |
| Unmapped via `on-sigusr1: hide` | **Released (dropped)** — matches sway's "hide" bar-mode rationale of reclaiming the screen space | Fullscreen-hide, gaming-mode-hide (D-04 requirement) |

This distinction (CSS-dim vs. true-unmap) is exactly what makes D-04's differentiated requirement achievable with the signal-action mechanism above, without needing two different waybar processes or config-swapping. **This exclusive-zone-on-hide behavior is not independently confirmed by a live waybar test in this research session (no live GUI test was performed)** — recommend the plan's first vertical-slice task include a quick manual check (`hyprctl clients -j` before/after a real SIGUSR1 hide, checking whether a tiled window's `at`/`size` reflows) before committing further tasks to this exact split.

## OLED Styling (D-06)

Current `style-full.css` (read directly): `window#waybar { background: @background; border-bottom: 3px solid @primary; }` — fully opaque background slab, solid 3px high-luminance primary border. These are exactly the two elements D-06 names as the trim targets. Recommended treatment (Claude's discretion within D-06's bound): reduce `background` to a translucent form of `@background` (e.g. via matugen's alpha-suffix pattern already used elsewhere in this repo, e.g. `swaync`/`fzf-colors.conf`'s documented alpha exemption) and either remove the `border-bottom` or reduce it to a thin (1px) low-opacity line — never a true-black literal (explicitly rejected by D-06), always a palette token.

## Vertical Layout Module Set (D-11..D-17)

D-12 names the module set explicitly (workspaces, stacked clock, volume, network, battery, notification button, media trigger, cpu/memory/temperature stacked, tray, power). All of these already exist as module definitions in the current `full`/`minimal` configs (read directly) — the vertical layout's job under the D-31 refactor is a **new composition file only** (`config-vertical.jsonc`), reusing shared module definitions from `modules.jsonc` with `"rotate"` where useful for text-bearing modules (waybar natively supports `"rotate": 90|180|270` on any module per the man page — verified, though D-13 pushes most text-bearing modules to tooltip-only rather than rotated text, so `rotate` is likely only needed for the (already glyph-only) workspace numbers if at all).

`position: "left"` is a documented, first-class bar-level option (verified in `waybar(5)`: `position — typeof: string — top, bottom, left, right`) — no custom width/orientation hacking needed; setting `"position": "left"` plus a `"width"` (instead of `"height"`) is sufficient for a column bar, and waybar handles the modules-left/-center/-right → top-to-bottom stacking automatically for vertical bars per the man page's general layout rules.

## eww Component Research (D-18..D-24, D-36)

### Package legitimacy (D-36)

**HIGH confidence — directly queried via `paru -Si` on this machine:**

| Field | `eww` (stable) | `eww-git` |
|---|---|---|
| Repository | AUR only — **not in official repos** (`pacman -Ss eww` under `extra`/`core` returns nothing) | AUR only |
| Version | 0.6.0-1 | 0.6.0.r53.g8661abf-1 |
| Votes / Popularity | 42 / 0.51 | 25 / 0.15 |
| Maintainer | eclairevoyant | eclairevoyant |
| Last modified | 2024-08-12 | 2024-09-15 |
| Depends | `libdbusmenu-gtk3`, `gtk3`, `gtk-layer-shell` | `gtk3`, `gtk-layer-shell`, `libdbusmenu-glib`, `libdbusmenu-gtk3` |
| Make deps | `cargo`, `git` | `cargo`, `git` |

**Recommendation: `eww` (stable), not `eww-git`** — higher votes/popularity, and D-36 prefers reproducibility over bleeding-edge. Per D-36, since eww is AUR-only (not official), **this triggers the human legitimacy-check gate at execution time** — the package name `eww` itself is tagged `[ASSUMED]` per this research protocol's provenance rule (recalled from training knowledge, not discovered via an official doc source), though its existence and metadata above ARE directly registry-verified. The planner should insert a `checkpoint:human-verify` task before this install, consistent with D-36's own text.

**Critical positive finding:** eww's AUR dependency list shows `gtk3` + `gtk-layer-shell` (**not** GTK4/libadwaita). `gtk-layer-shell 0.10.1-1` is already installed on this machine (confirmed via `pacman -Q`). This means **eww is GTK3-based**, which is exactly the toolkit tier this project's own `PROJECT.md` documents as fully theme-able via named-color CSS (unlike GTK4, which is the documented Out-of-Scope ceiling). D-18's framing ("GTK4 was rejected... a GTK4 popup would not follow the palette") is validated, and simultaneously eww's GTK3 nature means it genuinely CAN follow the palette fully — no ceiling here, unlike a hypothetical GTK4 popover.

**Build cost (for D-36's "container gate must stay green and unattended" concern):** `cargo`/`rustc` are makedeps pulled automatically by `paru`/`makepkg` if not present (this machine has `rustup` but not a bare `cargo` package — `paru` will pull `extra/cargo` as a makedep regardless of `rustup`, no conflict expected). This machine has 12 cores; a GTK3 Rust widget system of eww's size typically builds in low single-digit minutes on modern hardware — flag as a real, non-trivial addition to container-gate wall-clock time, not a blocking risk (LOW confidence estimate — untested in this session, no local build was attempted).

### SCSS theming (D-19)

**MEDIUM confidence, WebSearch cross-referenced across multiple community eww+matugen/pywal configs** (e.g. `randomboi404/eww`): eww's SCSS supports plain `@import 'path/to/colors.scss';` at the top of the main stylesheet, with generated files typically defining SCSS variables (`$primary: #...;`) consumed by the rest of the sheet — structurally identical to this repo's existing GTK CSS `@import url(...)` pattern already used for every other themed surface. **Recommended implementation:** add a new matugen template `eww-colors.scss` (SCSS variable syntax, not GTK `@primary`-named-color syntax — matugen templates are just text substitution, so this is a new template file, not a reused one) rendered to `~/.local/state/theme/eww.scss`, imported by the repo's own `eww/.config/eww/eww.scss`. New `contract.json` entry (`"name": "eww.scss", "format": "scss-kv"` or similar — the planner should check whether `contract.json`'s existing `format` enum needs a new value or whether `css-literal`/`env-kv`'s existing parsers already cover SCSS variable syntax; this repo's `fzf-colors.conf` already uses an `env-kv` format for a non-CSS non-JSON target, suggesting a precedent for adding a new lightweight format if SCSS `$var: value;` doesn't cleanly fit an existing one).

### Yuck/window basics (D-20..D-23)

Confirmed via WebFetch of the official eww docs (`elkowar.github.io/eww/configuration.html`, MEDIUM confidence):
- `defwindow` blocks define windows with `:monitor`, `:geometry` (`:x`, `:y`, `:width`, `:height` — relative to `:anchor`), `:anchor` (`"top center"`, `"bottom right"`, etc.), `:stacking`, and window-manager-specific hints.
- `defvar`/`defpoll`/`deflisten` are the three variable-update primitives — `defpoll` (interval-based shell script re-run, supports `:initial` to avoid startup blank-state) is the right primitive for the seek bar's position polling; `deflisten` (long-running script, updates on each new stdout line) is the right primitive for reactive state like play/pause or track-changed (e.g. wrapping `playerctl --follow` / `playerctl -F metadata`).
- Window open/close: `eww open <name>`, `eww close <name>`, `eww open --toggle <name>` (spelling to be re-confirmed post-install per Verdict 2 above).

### mpris/playerctl details (D-21)

**HIGH confidence — VERIFIED live on this machine** (a real player, Zen/Firefox's mpris bridge, was running during this research session):

```
$ playerctl -l
firefox.instance_1_159

$ playerctl metadata
firefox mpris:trackid   '/org/mpris/MediaPlayer2/firefox'
firefox xesam:title     I Bought a Cursed Mystery Box from Europe
firefox xesam:album
firefox xesam:artist    ConnorDawg
firefox mpris:artUrl    file:///home/aorus/.config/zen/firefox-mpris/10477_0.png
firefox xesam:url       https://www.youtube.com/watch?v=WR74HiPc_ds
```

This directly confirms: **the browser case's `mpris:artUrl` is already a local `file://` path** (Zen's own mpris bridge pre-caches the thumbnail) — no download step needed for browser/YouTube playback, contrary to a naive assumption that all art needs fetching. **MEDIUM confidence (WebSearch)** for the Spotify case: Spotify's native client typically exposes an `https://i.scdn.co/image/...` URL via `mpris:artUrl`, which DOES require a download step (`curl -sL "$url" -o "$cache_path"`) before an eww `image` widget (which needs a local file path, not a URL) can render it. **Recommended implementation:** a small art-resolution script checks the `artUrl` scheme — `file://` → strip prefix and use directly; `https://`/`http://` → download to a hash-keyed cache directory (e.g. `~/.cache/eww-media-art/<md5-of-url>.png`) once, reuse on repeat. This script is the natural `defpoll`/`deflisten` payload feeding the popup's `image` widget path.

**Player switcher (D-21):** `playerctl -l` (or `--list-all`) lists all currently controllable players by name (e.g. `firefox.instance_1_159`, `spotify`). `playerctl --player=<name> <command>` targets one explicitly, overriding `playerctld`'s "most-recently-active" default (**HIGH confidence for the flag existence, VERIFIED via installed `playerctl --help`**: `-p, --player=NAME` and `-l, --list-all` both confirmed present in the installed 2.4.1 binary's own `--help` output). The popup's player-switcher UI is naturally a `defpoll`-driven list of `playerctl -l` output, with each entry's click handler re-pointing the popup's active-player `defvar` to that name, which all subsequent control commands (`play-pause`, `next`, `position`, `volume`) then include via `--player=$selected`.

### Modern-rice reference (BAR-04's "form factor per modern-rice research")

**LOW confidence (WebSearch only, uncorroborated)** — no single authoritative "eww media popup" reference design surfaced distinctly from generic eww-bar examples. The user has already locked the *form* (D-18: dedicated eww popup, not a waybar drawer or swaync widget), so this research does not need to re-litigate the choice — it needs to inform *content*, which D-21 already fully specifies (art, artist/title/album, transport controls, seek, volume, player switcher). Recommend treating Omarchy (the project's own standing aesthetic reference per `08-CONTEXT.md`) as the visual/layout cue during implementation rather than a separate researched precedent, since no stronger source was found.

## swaync Widget Schema (D-27, D-28, D-30)

**HIGH confidence — VERIFIED directly against the installed `/etc/xdg/swaync/configSchema.json` (swaync 0.12.6-1) and its own shipped default `/etc/xdg/swaync/config.json`.**

Confirmed widget types available in `widgets: [...]`: `inhibitors`, `title`, `dnd`, `notifications`, `label`, `mpris`, `buttons-grid`, `menubar`, `slider`, `volume`, `backlight`.

### `buttons-grid` — directly answers D-28

```json
"buttons-grid": {
  "type": "object",
  "properties": {
    "buttons-per-row": { "type": "number" },
    "actions": {
      "type": "array",
      "items": {
        "properties": {
          "label": { "type": "string" },
          "command": { "type": "string" },
          "type": { "enum": ["normal", "toggle"] },
          "update-command": { "type": "string", "description": "executed on visibility change of cc to update the active state of the toggle button (should echo true or false)" },
          "active": { "type": "boolean" }
        }
      }
    }
  }
}
```

**The installed swaync's own shipped default `config.json` already ships a live worked example of exactly this toggle pattern** (a WiFi toggle, read directly from `/etc/xdg/swaync/config.json`):

```json
{
  "label": "直",
  "type": "toggle",
  "active": true,
  "command": "sh -c '[[ $SWAYNC_TOGGLE_STATE == true ]] && nmcli radio wifi on || nmcli radio wifi off'",
  "update-command": "sh -c '[[ $(nmcli radio wifi) == \"enabled\" ]] && echo true || echo false'"
}
```

This is a direct template for D-28's three toggles:

```json
{
  "label": "󰊴",
  "type": "toggle",
  "command": "~/.config/hypr/scripts/gaming-mode-toggle.sh",
  "update-command": "sh -c '[[ $(cat ~/.cache/gaming-mode) == on ]] && echo true || echo false'"
}
```

`gaming-mode-toggle.sh` (read directly, confirmed) is itself idempotent-toggle-shaped already (`main()` reads current state and flips it) — calling it bare with no args from `command` is correct and matches its existing CLI contract (`status` is the only special arg, otherwise it toggles). This satisfies D-28's hard constraint exactly: the button calls the SAME script and the `update-command` reads the SAME state file (`~/.cache/gaming-mode`) the Super-key menu entry already uses — no new logic, no independently-derived state. The same pattern applies to a DND toggle (`swaync-client -dn`/`-df`/`-D` already exist per `swaync-client --help`, confirmed installed) and a theme toggle (`theme-switch.sh`, existing).

### `slider`, `volume`, `backlight` — directly answer D-27

- `volume`: purpose-built pulse-volume slider widget (`show-per-app`, `show-per-app-icon` options) — no `cmd_setter`/`cmd_getter` needed, it's a native pulse control, likely simpler than the generic slider for the volume case.
- `backlight`: purpose-built brightness slider (`device`, `subsystem: backlight|leds`, `min`) reading `/sys/class/backlight` — again native, no external command needed. **Note:** `brightnessctl` (already installed, already used by `hypridle.conf`'s dim listener) is a CLI wrapper around the same sysfs interface `backlight`'s widget reads directly — using the native widget avoids a redundant CLI-shell-out.
- Generic `slider` (`cmd_setter`/`cmd_getter`, `min`/`max`/`min_limit`/`max_limit`) exists as a fallback if `backlight`'s native sysfs read doesn't suit this machine's hardware, but the purpose-built `backlight` widget is preferred per the "don't hand-roll" spirit — it IS the non-hand-rolled option here.

**Recommended D-27 widget set:** `volume`, `backlight`, `buttons-grid` (3 toggles), on top of the existing `title`/`dnd`/`notifications`. `mpris` is explicitly removed (D-24).

### Geometry (D-30)

Current: `positionX: right`, `positionY: top`, `control-center-width: 380`, margins `10/10/10/0`. All are plain `config.json` keys (verified) — trivial to widen (`control-center-width`) if the sliders/toggle-grid need more room; no schema blocker to revisiting D-30 freely.

## Package Legitimacy Audit

| Package | Registry | Age | Downloads/Votes | Source Repo | Verdict | Disposition |
|---------|----------|-----|------------------|--------------|---------|-------------|
| `eww` | AUR (not official) | First submitted 2022-08-28, last modified 2024-08-12 (~2 yrs old, stable) | 42 votes / 0.51 popularity | github.com/elkowar/eww | Legitimate, mature, non-`-git` variant — but AUR-only | **Flagged — human legitimacy check required per D-36 (AUR package); not a slopsquat risk (long history, well-known maintainer `eclairevoyant`, real upstream repo), but the standard AUR gate still applies** |
| `eww-git` | AUR (not official) | Same upstream, `-git` variant | 25 votes / 0.15 popularity | Same repo | Not recommended — lower adoption than stable, worse reproducibility | **Not selected; do not install** |
| `socat` (optional, only if the fullscreen listener uses it instead of Python) | **Official `extra` repo** | N/A (long-standing core Linux utility) | N/A | N/A (widely-packaged standard tool) | OK | Approved if chosen; not currently installed |

**Packages removed due to [SLOP] verdict:** none.
**Packages flagged as suspicious [SUS]:** none — `eww`'s AUR-only status is a routine D-36 gate trigger, not a legitimacy concern; its metadata (multi-year history, real upstream, non-trivial vote count, well-known maintainer) is consistent with a real, actively-used package, not a hallucinated or squatted one. `eww` and `eww-git` were BOTH discovered from training knowledge (this researcher's prior familiarity with the eww widget system), so per this protocol's provenance rule both package names are tagged `[ASSUMED]` even though `paru -Si` independently confirmed their existence and metadata above — the planner must still gate the install behind `checkpoint:human-verify` per D-36's own text, not skip it because registry lookup succeeded.

## Common Pitfalls

### Pitfall 1: Treating `include`'s first-wins as a deep merge
**What goes wrong:** a layout file defines a module key expecting to only override one property, but the whole module gets silently replaced (or the shared version silently wins if the layout file's key resolves second).
**Why it happens:** JSON-merge intuition from other tools (e.g. Docker Compose, Kustomize) doesn't apply — waybar's `include` is whole-key, first-defined-wins, not property-level deep merge.
**How to avoid:** never partially override a module key; always fully redefine it in the layout file if any change is needed, per the shape in Verdict 3.
**Warning signs:** a module silently reverts to its shared definition after a layout-specific tweak was added "on top of" the include.

### Pitfall 2: Assuming waybar's `hide` always preserves layout (no reflow)
**What goes wrong:** idle-hide implemented via the true `on-sigusr1: hide` signal action causes tiled windows to reflow every idle cycle — exactly the D-04 failure this decision was written to prevent.
**Why it happens:** waybar's `hide`/`mode: hide` mirrors sway-bar semantics, whose entire purpose is reclaiming the exclusive zone while hidden — the opposite of what idle-hide needs.
**How to avoid:** use the CSS-dim (mapped, exclusive-zone-kept) path for idle-hide; reserve the true unmap-hide signal for fullscreen/gaming triggers only, per the Visibility Owner Design above.
**Warning signs:** windows visibly shift/resize a few seconds after the screen goes idle, then shift back on resume.

### Pitfall 3: Building a bespoke slide/fade animation harness for D-07
**What goes wrong:** hours spent building a custom compositor overlay or a hand-rolled interpolation loop to fake a layer-shell slide animation that waybar's architecture cannot natively support.
**Why it happens:** the temptation to "just make it work" once instant-hide feels visually abrupt.
**How to avoid:** D-07's own text forbids this explicitly ("do NOT build a bespoke animation harness"); the evidence in Verdict 1 should be sufficient to close this decision at "instant, documented" without further engineering spend.
**Warning signs:** a task appears in the plan proposing a custom GTK widget, a shader, or a frame-timer loop for the bar's visibility transition.

### Pitfall 4: Assuming `eww open --toggle` behaves identically to the exact spelling/behavior found in a random blog post
**What goes wrong:** the popup fails to open/close correctly because the installed 0.6.0 AUR build's actual CLI flag differs subtly from a WebSearch-sourced example (this whole area is MEDIUM/LOW confidence, not verified against the real binary since eww isn't installed yet).
**Why it happens:** eww is a fast-moving small project; CLI flags and behavior have changed across versions, and most WebSearch results are not version-pinned.
**How to avoid:** the FIRST eww-related task in the plan should be `eww open --help` / `eww --help` (or equivalent) against the actually-installed 0.6.0 binary, confirming exact flag spellings before writing any wrapper scripts that depend on them.
**Warning signs:** a wrapper script silently no-ops or errors because a flag name assumed from research doesn't match the installed version.

## Runtime State Inventory

Not applicable — Phase 8 is additive/config-layer work (new layout, new component, new panel config), not a rename/refactor/migration of existing identifiers. The D-31/D-33/D-34 refactor changes HOW waybar's config files are organized, not any external-facing name, ID, or stored-data key, so the Runtime State Inventory categories (stored data, live service config, OS-registered state, secrets, build artifacts) do not apply. **Nothing found in any category — verified by inspection: no database/collection names, no OS Task Scheduler-equivalent registrations (this is Linux, N/A), no secret/env var renames, and no stale build artifacts are implicated by this phase's scope.**

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| waybar | Entire phase | ✓ | 0.15.0-2 | — |
| hypridle | D-05 idle listener | ✓ | 0.1.7-9 | — |
| swaync | BAR-05 panel | ✓ | 0.12.6-1 | — |
| playerctl | BAR-04 mpris | ✓ | 2.4.1-5 | — |
| gtk-layer-shell | eww runtime dep | ✓ | 0.10.1-1 | — |
| libdbusmenu-gtk3 | eww runtime dep | ✓ | 18.10.20180917-1 | — |
| Hyprland | fullscreen events, cursorpos | ✓ | 0.55.4 | — |
| `eww` (AUR) | BAR-04 media popup | ✗ (not installed) | — | None — this IS the phase's new component; install via `install.sh` AUR_PKGS + `paru`, gated by `checkpoint:human-verify` per D-36 |
| `socat` | Optional fullscreen-listener implementation | ✗ (not installed, but in official `extra` repo) | — | Use Python's stdlib `socket` module instead (already installed, zero new package) |
| `cargo`/`rustc` (eww makedep) | Building eww from AUR | Not directly installed (only `rustup` present) | — | `paru` auto-installs `extra/cargo` as a makedep; no action needed, but adds real build time to the container gate (D-36's own flagged concern) |
| `curl` | Spotify `https://` art download | ✓ | 8.21.0-1 | — |
| `jq` | D-34 equivalence-check tooling | ✓ | 1.8.2-1 | — |
| `python`/`python3` | Equivalence checker, optional fullscreen listener | ✓ | 3.14.6-1 | — |

**Missing dependencies with no fallback:** `eww` itself — this is expected; it is the phase's deliverable, not a pre-existing gap.
**Missing dependencies with fallback:** `socat` (Python stdlib socket is a zero-cost substitute).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `eww` and `eww-git` package names, and eww's general CLI/yuck/SCSS behavior beyond what was WebFetched from official docs | eww Component Research | If the package name or a flag is subtly wrong, the D-36 human legitimacy checkpoint and the "run `--help` first" pitfall guard (Pitfall 4) both catch this before it compounds into wasted implementation work |
| A2 | Spotify's `mpris:artUrl` is an `https://i.scdn.co/...` URL requiring download (not independently verified — no Spotify was running during this research session; only the Firefox/Zen `file://` case was directly observed) | mpris/playerctl details | If Spotify actually also exposes a local cached path, the download-branch code is simply unused/dead rather than broken — low risk either way since the scheme-check (`file://` vs `http(s)://`) branch handles both correctly |
| A3 | GTK3 CSS-provider hot-reload (via SIGUSR2) may or may not animate a `transition: opacity` rule on `window#waybar` for the idle-dim path | Verdict 1 bonus note | Explicitly scoped as a zero-risk optional bonus, not a task dependency — no risk to the phase if wrong, since instant is the committed fallback either way |
| A4 | sway-bar's `hide` mode semantics (exclusive-zone-drop) apply identically to waybar's `on-sigusr1: hide` signal action, since waybar's man page says it mirrors sway-bar's `mode` command but doesn't explicitly restate the exclusive-zone behavior for the signal-driven path | Exclusive Zone Behavior | Recommended first-task live check (`hyprctl clients -j` before/after a real hide) closes this before the plan commits further tasks to the CSS-dim/true-unmap split |
| A5 | `eww open --toggle` (exact flag spelling) works as described, on the specific AUR `eww` 0.6.0 build | Verdict 2 / Pitfall 4 | Explicitly gated behind a first task running `eww open --help` against the real installed binary before any wrapper script is written |
| A6 | Hyprland socket2's `fullscreen` event name/payload format (`fullscreen>>0/1`-style) is exactly as WebSearch-summarized — the official wiki page itself could not be fully fetched in this session (returned truncated/404 content) | Fullscreen Detection | Low risk — the listener script's first implementation task should log raw socket2 lines during a manual fullscreen toggle to confirm the exact event name/format before wiring the hide/show call, cheap to verify empirically |

## Open Questions

1. **Does a real live SIGUSR1-hide actually drop the exclusive zone on this Hyprland/waybar combination, or does Hyprland retain it regardless of waybar's own semantics?**
   - What we know: sway-bar's documented mode semantics strongly suggest zone-drop-on-hide; waybar explicitly mirrors that semantics language.
   - What's unclear: no live interactive test was performed in this research session (would require a running graphical session with tiled windows to observe reflow).
   - Recommendation: first implementation task for the visibility owner should include a manual before/after `hyprctl clients -j` comparison, exactly as flagged in Pitfall 2 / Assumption A4.

2. **What is the actual build time for `eww` (AUR) inside the unattended container gate, and does it introduce a new timeout risk (D-36's own concern)?**
   - What we know: 12-core dev machine should build a GTK3 Rust project in low single-digit minutes; container gate hardware/CPU allocation is unknown.
   - What's unclear: whether the existing container-gate timeout budget (used by prior AUR packages like `walker`/`elephant`/`wlogout`) already accounts for a Rust compile of this size, or whether it needs raising.
   - Recommendation: the planner should check the container gate's current per-package/overall timeout values against a first real `eww` build's wall-clock time, and raise the budget if needed — flagged, not resolved, in this research.

*(Validation Architecture section omitted: `.planning/config.json` sets `workflow.nyquist_validation: false` for this project. The planner should still be aware that this repo's own established rerunnable-gate pattern — `theme-doctor`, `theme-parity`, `keybind-doctor` — is the closest analog and is referenced throughout this document as the natural home for the new D-17/D-34/D-19 assertions; each such gate needed by this phase is called out inline in its relevant section above (Verdict 3's equivalence-diff script, D-17's module-color assertion, D-19's eww parity target).)*

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | Phase has no auth surface |
| V3 Session Management | No | N/A |
| V4 Access Control | No | Single-user desktop, no multi-tenant concern |
| V5 Input Validation | Yes (narrow) | The Spotify album-art download path takes a URL from mpris metadata (untrusted D-Bus data from a third-party app) and writes it to a cache file — must validate the scheme is `http(s)://` or `file://` before acting, and must not pass the URL unsanitized to a shell (`curl -sL -- "$url"` with `--` guard, quoted, never `eval`'d) |
| V6 Cryptography | No | N/A |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Command injection via mpris metadata (artist/title/album strings, or `artUrl`) flowing into a shell command unsanitized (e.g. an eww `deflisten`/`defpoll` script interpolating `$(playerctl metadata xesam:title)` directly into a shell command instead of passing it as a properly quoted argument) | Tampering | Always quote variables from mpris data; never use metadata strings to construct commands — this repo already hit and fixed an analogous class of bug in Phase 6 (`06-04`: "hyprlang cannot parse literal `{{ }}` in a label text value... playerctl now-playing rebuilt as a brace-free `sh -c` concatenation") — apply the same discipline here |
| `buttons-grid` `command`/`update-command` shell strings (D-28) executing with the swaync process's ambient privileges | Elevation of Privilege (bounded) | Commands are user-authored (this repo's own scripts), not attacker-controlled input — low risk, but D-28's constraint (call the SAME script) already forecloses ad-hoc inline shell logic proliferating here |
| Cached album art downloaded from `mpris:artUrl` written to a predictable path | Tampering (low severity) | Hash-key the cache filename from the URL (as recommended above) rather than a fixed/guessable path, and confirm the download target directory is user-owned (`~/.cache/...`, standard XDG cache location, consistent with this repo's existing `~/.cache/`-based state file conventions) |

## Sources

### Primary (HIGH confidence — direct system verification on this machine)
- `zcat /usr/share/man/man5/waybar.5.gz` (waybar 0.15.0-2) — full BAR CONFIGURATION section, `include` semantics, signal actions, module format, MODULE GROUPS/rotate, MULTI OUTPUT
- `waybar --help`, `waybar --version` — confirms no config-dump flag exists
- `hyprctl cursorpos`, `hyprctl activewindow -j`, `hyprctl clients -j`, `hyprctl monitors -j`, `hyprctl version` — live command output
- `/run/user/1000/hypr/<sig>/.socket2.sock` — live socket existence check
- `pacman -Q`/`pacman -Qi`/`pacman -Ss` for waybar, hypridle, swaync, playerctl, gtk-layer-shell, libdbusmenu-gtk3, socat, curl, jq, python
- `paru -Si eww`, `paru -Si eww-git` — live AUR metadata query
- `/etc/xdg/swaync/configSchema.json` — full widget schema (buttons-grid, slider, volume, backlight, menubar)
- `/etc/xdg/swaync/config.json` — shipped default with the live wifi-toggle `buttons-grid` example
- `swaync-client --help` — confirms `-dn`/`-df`/`-D`/`-t`/`-sw` flags
- `playerctl --help`, `playerctl -l`, `playerctl metadata` — confirms flags and live metadata including a real `file://` artUrl
- Direct reads of this repo's own files: `08-CONTEXT.md`, `REQUIREMENTS.md`, `STATE.md`, `PROJECT.md`, `ROADMAP.md`, `waybar/.config/waybar/config-{full,minimal,floating}.jsonc`, `waybar/.config/waybar/style-full.css`, `hypr/.config/hypr/hypridle.conf`, `hypr/.config/hypr/scripts/gaming-mode-toggle.sh`, `hypr/.config/hypr/scripts/waybar-{switch,launch}.sh`, `hypr/.config/hypr/config/{keybinds,autostart}.conf`, `theme-engine/.config/theme-engine/{contract.json,theme-doctor}`, `matugen/.config/matugen/config.toml`, `install.sh`

### Secondary (MEDIUM confidence — WebSearch/WebFetch, cross-referenced by 2+ sources or an official doc page)
- eww official configuration docs (`elkowar.github.io/eww/configuration.html`) — window geometry/anchor/monitor, defpoll/deflisten/defvar
- `Alexays/Waybar#1533` (margins on `window#waybar` don't reposition the surface)
- `Alexays/Waybar#3853` (open Auto-Hide feature request, confirms no native support)
- `elkowar/eww#333` ("SOLVED" — `eww open --toggle` flag)
- `elkowar/eww#472` (`:onlostfocus`/`onkeypressed` close-on-Esc/click-away pattern)
- `sway-bar(5)` mode semantics (dock/hide/invisible/overlay, exclusive-zone rationale)
- Hyprland IPC event names (`workspace`, `activewindow`/`activewindowv2`, `fullscreen`, `monitoradded`/`monitorremoved`) via Hyprland wiki + `hyprwm/Hyprland#13041` discussion
- Community eww+matugen/pywal SCSS `@import` pattern examples

### Tertiary (LOW confidence — single WebSearch pass, not cross-referenced, marked for validation during implementation)
- Spotify's `mpris:artUrl` being an `https://i.scdn.co/...` remote URL (Assumption A2 — no Spotify instance was available to verify directly in this session)
- Modern-rice eww media-popup precedent (no single strong reference surfaced; treated as a non-blocking gap since D-18/D-21 already fully specify content)
- Exact eww build time inside a container (Open Question 2 — no build was attempted)

## Metadata

**Confidence breakdown:**
- Standard stack (waybar/hypridle/swaync/playerctl versions and capabilities): HIGH — every claim VERIFIED directly against the installed binaries/man pages/schemas on this machine
- D-07/D-23/D-31 verdicts: HIGH for the core waybar-native claims (man page, live `hyprctl` commands); MEDIUM for the corroborating GitHub-issue evidence
- eww component (new, nothing installed): MEDIUM/LOW — WebSearch/WebFetch only, no live binary to test against; every eww-specific behavioral claim carries an explicit "verify with `--help` once installed" caveat
- swaync widget schema: HIGH — read directly from the installed package's own JSON schema and shipped default config
- Pitfalls: HIGH — derived directly from the verified evidence above, not speculative

**Research date:** 2026-07-14
**Valid until:** 30 days for the waybar/swaync/Hyprland-native findings (stable, installed, unlikely to change mid-phase); 7 days for the eww-specific findings (nothing installed yet, higher volatility until the package is actually verified in Task 1)
