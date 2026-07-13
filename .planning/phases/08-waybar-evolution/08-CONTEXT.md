# Phase 8: Waybar Evolution - Context

**Gathered:** 2026-07-14
**Status:** Ready for planning

<domain>
## Phase Boundary

Waybar gains OLED-safe behavior (auto-hide + low-luminance styling + a best-effort pixel-shift attempt), an additional **vertical (left)** layout, an **eww-based media center popup** driven by mpris, and **one-click swaync notification-center access from every layout** — all still driven by the shared theme pipeline (BAR-01..05).

**Critical framing — much of this phase is finishing, not starting:**
- The `mpris` module is **already in** the full and minimal bars (inline text, click=play/pause, scroll=volume).
- A `custom/notification` button (`swaync-client -t -sw`) is **already in** full and minimal — and **missing from floating**. BAR-05 is already half-true; this phase makes it true everywhere and reworks the panel it opens.
- swaync's control center **already has an mpris widget** (96px album art, 12px radius) — which this phase deliberately **removes**, because the eww popup becomes the single media surface.
- Phase 7 left `_gaming_waybar_toggle()` in `gaming-mode-toggle.sh` as a deliberate one-line `pkill -SIGUSR1 waybar` **for this phase to re-point** (P7 D-26).

**Also in scope (inherited/forced, not scope creep):**
- The **gaming-mode waybar indicator** Phase 7 explicitly deferred to Phase 8 (P7 deferred list; the `~/.cache/gaming-mode` state file is its probe).
- A **behavior-preserving refactor** of the layout configs/stylesheets to shared module definitions + per-layout composition, and **dynamic layout enumeration** — because this phase lands six cross-cutting changes into what are currently four copy-pasted files.

**Not in scope:** replacing waybar as the bar (eww draws the media popup only, not the bar); the wlogout→wleave migration (Phase 9); a redesign of the three existing bars' visual identity beyond the OLED styling pass.

</domain>

<decisions>
## Implementation Decisions

### OLED-safe behavior (BAR-01)

- **D-01: The bar hides on TWO independent triggers — idle timeout AND fullscreen.** Either condition alone hides it; it returns when both clear. Fullscreen-only hiding (the common rice behavior) was rejected because it does nothing for the actual burn-in scenario: a static bar lit for hours while you read or code.
- **D-02: Reveal is "any input + keybind only" — NO edge-hover reveal.** Idle-hide clears naturally on any keypress/mouse move (the idle condition simply ended). Fullscreen-hide persists and is overridden **only** by an explicit keybind. Rationale: nothing may pop out of the screen edge while you're aiming in a game or scrubbing a video timeline.
- **D-03: ONE owner script + state file owns bar visibility.** Four actors now want to move the bar (idle watcher, fullscreen watcher, gaming-mode, keybind). They all call a single `waybar-visibility`-style entrypoint with an **intent** ("gaming wants it hidden", "idle ended"); the owner computes the resulting state. **Phase 7's `_gaming_waybar_toggle` re-points to this owner** — exactly what its footnote anticipated.
  - **Explicitly killed:** the current everyone-sends-`SIGUSR1` approach. SIGUSR1 is a *toggle*, not set-visible/set-hidden — if idle hides the bar and gaming-mode then toggles, the bar comes back mid-game and the state desyncs. This is the exact bug class this repo keeps deleting.
- **D-04: The exclusive zone is trigger-dependent.** Idle-hide **keeps** the reserved space (tiled windows must NOT reflow every couple of minutes during normal work). Fullscreen-hide and gaming-mode-hide **drop** it (there you genuinely want the pixels). The owner script already knows *why* it's hiding, so this costs nothing architecturally.
- **D-05: Idle signal comes from a hypridle listener** (on timeout → hide; on resume → show). One idle daemon for the session; it already governs lock/dpms. **Planning must handle the interaction:** Phase 7's gaming mode `SIGSTOP`s hypridle, so the bar would otherwise freeze in whatever state it was in.
- **D-06: OLED styling goes only as far as it doesn't fight the theme.** Add translucency; trim the highest-luminance elements (the 3px solid `@primary` border, the filled workspace pills). **Every color still comes from the palette.** A true-black override was explicitly **rejected** — it would opt the bar out of the pipeline's look, which cuts directly against this project's core value, and would break the 5 light presets from Phase 5.
- **D-07: Hide/reveal is animated (slide/fade), matched to Hyprland's animation feel.** **⚠ Constraint:** waybar has no native hide animation. Research must prove a clean GTK-transition / margin approach exists on the installed binary. If it doesn't, **fall back to instant WITH documented evidence** — do NOT build a bespoke animation harness.
- **D-08: Overlays are not a visibility intent.** If the bar is hidden and you open walker / the swaync panel / a picker, the bar **stays hidden**. No special-casing, no fifth actor poking the owner. (Opening a menu is input, so the idle case resolves itself anyway.)

### Pixel-shift (BAR-02)

- **D-09: Timeboxed spike, then decide — with explicit kill criteria.** Attempt margin-jitter (a few px, every few minutes) against the real bar. **Kill it if any of:** the movement is perceptible as a twitch; it reflows any window; or it needs to coordinate with the visibility owner (D-03 exists specifically so only ONE thing moves the bar). The requirement is explicitly best-effort with a "descope with evidence" clause — this is its literal reading.
- **D-10: If descoped, the evidence lands in `08-VERIFICATION.md`** alongside the other requirement verdicts — what was attempted, what broke, why BAR-02 is closed as descoped. A silent drop is not acceptable.
- **Standing hypothesis (state it, don't assume it):** D-01's auto-hide plus D-06's low-luminance styling may already remove most of the exposure pixel-shift targets. That's the likely descope argument — but it must be *demonstrated*, not asserted.

### Vertical layout (BAR-03)

- **D-11: ONE vertical layout, designed for the column — not a rotated copy of anything.** Rejected: making position an axis (minimal-vertical / full-vertical / …), which doubles the re-test surface and makes no sense for "full" in a narrow column. The roadmap's "full module re-test, not copy-paste" pushes directly here.
- **D-12: Module set = essentials + system stats**, all glyph-reduced: workspaces, stacked clock, volume, network, battery, notification button, media trigger, cpu/memory/temperature as stacked readouts, tray, power. **Acknowledged tension:** system stats are the most always-lit elements on the bar, which pulls against D-06's OLED goal — D-01's auto-hide is what makes this acceptable.
- **D-13: Detail that can't fit goes to tooltips.** Window title and now-playing text are not glanceable in the column; you hover, or you open the media center. Nothing gets a text label it can't render.
- **D-14: The vertical bar is narrow and unobtrusive** — slim column (icon-width + padding), same rounded/translucent treatment as the horizontal bars, flush left with a margin. Not an island/floating aesthetic.
- **D-15: It appears on every monitor, same as today** (no `output` key is set anywhere; waybar draws on all displays). No per-monitor config is introduced.
- **D-16: It does NOT become the default layout.** `waybar-launch.sh` already restores the last-used layout (defaulting to `full`); vertical just becomes a 4th valid value in that state file. Fresh installs and the container/VM gate keep their current baseline.
- **D-17: Success criterion 2's "full module re-test" is discharged by a rerunnable gate + a human pass.** The gate asserts every module class used by every layout resolves to a real named color in the rendered `waybar.css` — this is the exact bug class Phase 1 hit with battery/backlight silently rendering unstyled. Human pass = look at the vertical bar under one light and one dark preset. **Prefer folding this into the existing `theme-doctor` CSS-parse guard** (Phase 6 already asserts non-empty providers + zero fatal errors across 9 surfaces) rather than writing a standalone checker — one gate, one place to look.

### Media center (BAR-04)

- **D-18: A dedicated popup — built with eww.** Chosen over (a) a waybar `group` drawer, (b) routing to swaync's existing mpris widget, and (c) a bespoke GTK4 popover. This is knowingly the **most expensive option on the board** and the only one that adds a new component to the theme pipeline. GTK4 was rejected on hard prior evidence: PROJECT.md's Out-of-Scope records full GTK4/libadwaita palette theming as *structurally unsupported upstream* — a GTK4 popup would not follow the palette.
- **D-19: eww adds a NEW matugen template + contract target + parity fixtures across 22 palettes.** This is accepted, deliberate cost. Planning must treat it as a first-class render target (light + dark parity, `theme-parity` green), not an afterthought.
- **D-20: eww's scope is the media popup now, but it is sanctioned for future widgets** (calendar, dashboards, gaming overlay). **Hard boundary for THIS phase:** waybar stays the bar, swaync stays notifications, walker stays the menu. eww does not draw the bar. Do not relitigate what draws the bar in Phase 8.
- **D-21: The popup is full-fat.** Album art, artist/title/album, prev / play-pause / next, a draggable seek bar, a volume slider, **and an explicit player switcher**. The switcher is arguably literal scope — the requirement names Spotify *and* browser/YouTube by name, and both are commonly alive at once, so trusting playerctld's "most recent" guess is not good enough.
- **D-22: The inline mpris bar segment STAYS and becomes the popup's trigger.** You keep glanceable "▶ artist — title" in the horizontal bars (glyph-only in the vertical column) and clicking it opens the popup. **Planning must rethink the existing scroll-to-change-volume / right-click-next bindings** on that segment so they don't fight the popup.
- **D-23: The popup anchors under the bar segment it was launched from**, and closes on re-click / click-away / Esc. **⚠ Verify feasibility first:** waybar modules are not real windows, so true anchoring under Hyprland's layer-shell may not be available. If it isn't, fall back to a fixed position (near where swaync opens) — which works identically from every layout including vertical and hidden-bar.
- **D-24: `mpris` is REMOVED from swaync's widget list.** The eww popup is THE media center; swaync goes back to being notifications + controls. One surface per job — this repo deletes duplicate surfaces on principle (powermenu.sh, wofi, `themes/`). It's a one-line config change.
- **D-25: No player → no bar segment → no popup.** waybar's mpris already does this (`format-stopped: ""`). There is no "nothing playing" placeholder state; the media center simply isn't there when there's no media.

### Notification center (BAR-05)

- **D-26: Scope is parity + a swaync panel rework.** Parity: the `custom/notification` module lands in floating (where it is **currently missing** — a live bug, and proof of the copy-paste drift D-31 fixes) and in the new vertical layout. Rework: the panel is the surface you actually land on, and nobody has designed it.
- **D-27: The panel keeps useful widgets — sliders + a small toggle grid** — on top of notifications + dnd + clear-all. Rationale for the sliders: SwayOSD (Phase 6) is *feedback* when you press a key, not a *control* you can drag; a panel slider is the only pointer-driven volume/brightness control on this desktop outside pavucontrol. Genuine gap, not duplication.
- **D-28: Toggle grid = gaming mode + DND + theme.** **⛔ HARD CONSTRAINT — this is the one decision that cuts against "one surface per job", so it is bounded explicitly:** every toggle **must call the same script and read the same state file** as the Super-key menu entry (`gaming-mode-toggle.sh`, `~/.cache/gaming-mode`, `theme-switch.sh`). **No second copy of the logic, no independently-derived state.** A toggle that can display a stale ON/OFF is the exact drift pattern this project has deleted twice.
- **D-29: "Interact" means inline actions + per-notification dismiss** — notification action buttons work from the panel (e.g. a browser notification's "Open"), and each notification dismisses individually, not just clear-all. Mostly verifying swaync's behavior and styling the action buttons through the pipeline.
- **D-30: Panel geometry (today — top-right, 380px, 10px margins) is revisited during design** — a control center with sliders and a toggle grid may want more room than a notification list.

### Layout config drift (delivery risk, not a requirement)

- **D-31: Refactor to shared module definitions + per-layout composition.** Module *definitions* (mpris, notification, clock, workspaces…) live once in a shared jsonc include; each layout config declares only which modules it shows and where. Same shape for CSS: shared module rules + a thin per-layout sheet.
  - **Why this is not optional:** this phase lands six cross-cutting changes (notification module, eww trigger, OLED translucency, visibility behavior, gaming indicator, glyph reductions) into what are currently **four copy-pasted files** — 16+ edits where the failure mode is "three layouts got it, one didn't, nobody notices for two months." **That has already happened**: the notification button is missing from floating *right now*, for exactly this reason.
  - **⚠ Verify first (Phase 4 lesson):** confirm what waybar 0.15.0's `include` actually does — merge order, key-override semantics — against the installed binary before the plan leans on it. If it's weaker than advertised, refactor as far as it genuinely allows and stop. **Do not build a preprocessor.**
  - **Scope guard:** the refactor's job is to make *this phase's* decisions land once instead of four times. It is **not** an invitation to redesign the three existing bars.
- **D-32: Both `waybar-switch.sh` and `waybar-launch.sh` enumerate layouts from disk** (glob `config-*.jsonc`) instead of hardcoding the list. Adding a layout becomes one file with no script edits. This is the **identical fix Phase 5 applied to palettes** (`palettes/*.json` dynamic enumeration) — PROJECT.md records it as closing that pitfall *permanently*, and the same hardcoded list is sitting here with vertical about to prove it.
- **D-33: The refactor ships FIRST, as its own standalone plan, changing NO behavior.** The three existing bars must look and work identically afterward; then vertical / OLED / media / notifications build on the clean base. A no-op refactor either regressed something or it didn't — easy to verify, easy to revert if `include` semantics disappoint.
- **D-34: The refactor is gated by asserting rendered-config equivalence** — prove the refactored includes produce the same effective config per layout as today's standalone files (dump/compare waybar's resolved config), plus a human pass on each bar. Eyes miss a dropped `on-click` or a vanished tooltip; a mechanical comparison doesn't. This is the theme-parity posture applied to waybar.

### Inherited scope & reproducibility

- **D-35: The gaming-mode waybar indicator is IN** (Phase 7 explicitly deferred it here). A module reading the `~/.cache/gaming-mode` state file Phase 7 left as its probe, showing ON/OFF. Cheap now that D-31 means defining it once.
- **D-36: eww goes into `install.sh` under the standard package gate** (P7 D-33): official repos strongly preferred; any AUR package gets a human legitimacy check at execution time. **The container gate must stay green and unattended** (P7 D-34) — eww is a compiled Rust binary, so its build/install time in the gate is a real thing to watch, not an afterthought.
- **D-37: The new bar-toggle keybind follows the Phase 7 contract** — it lands in `keybinds.conf` with a trailing `# description`, so the MENU-07 cheat-sheet picks it up automatically (P7 D-30/D-31/D-32) and P7 D-04's keybind regression gate covers it. Nothing new to design; just don't break the contract.

### Claude's Discretion

- The idle timeout value (D-05) — a sane default as a **single tunable constant** at the top of the visibility script.
- The exact module list for the vertical bar within D-12's constraint: *anything that needs a text label to be useful doesn't belong in the column*.
- The pixel-shift jitter magnitude and interval if the D-09 spike survives — the largest shift that's still imperceptible, the slowest interval that still helps; both as tunable constants.
- The exact bar-toggle chord and its cheat-sheet wording (D-37).
- eww widget internals: yuck/SCSS structure, polling strategy for the seek bar, how the player switcher presents itself.
- Whether D-17's module-color assertion is folded into `theme-doctor` or stands alone (fold preferred).
- Panel geometry after the D-27/D-28 widgets are designed (D-30).

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & roadmap
- `.planning/REQUIREMENTS.md` — BAR-01..05 definitions (note BAR-02's explicit "best-effort; descope with evidence if infeasible")
- `.planning/ROADMAP.md` — Phase 8 goal + 4 success criteria (note criterion 2's explicit "full module re-test, not copy-paste")
- `.planning/PROJECT.md` — Key Decisions table. Load-bearing for this phase: **"Verify options against the installed binary schema before relying on them"** (drives D-07, D-23, D-31's verification mandates); **"Dynamic `palettes/*.json` enumeration everywhere (no hardcoded theme lists)"** (drives D-32); and the Out-of-Scope line **"Full GTK4/libadwaita palette theming — structurally unsupported upstream"** (the reason a GTK4 media popup was rejected in D-18)

### Prior phase context (binding decisions carried forward)
- `.planning/phases/07-super-key-menu/07-CONTEXT.md` — **D-26** (the `_gaming_waybar_toggle` thin abstraction left explicitly for Phase 8 to re-point), **D-27** (gaming-mode state file as the indicator's probe), **D-33/D-34** (package gate + container gate must stay green), **D-30/D-31/D-32** (keybinds.conf is the cheat-sheet's single source of truth — every new bind needs a trailing `# description`), **D-04** (the rerunnable keybind regression gate this phase inherits), and its **deferred list** ("Waybar gaming-mode indicator — Phase 8")
- `.planning/phases/06-themed-surfaces-utility-suite/06-CONTEXT.md` — D-10 (Nerd Font glyphs, not SVG assets); the theme-doctor CSS-parse regression guard this phase should extend (D-17)
- `.planning/phases/05-light-mode-pipeline-theme-presets/05-CONTEXT.md` — dynamic enumeration over hardcoded lists (the direct precedent for D-32); the walker-dmenu exit-code-130 cancel pattern used by `waybar-switch.sh`

### The surfaces under change
- `waybar/.config/waybar/config-{minimal,full,floating}.jsonc` — the three current layouts. **`custom/notification` is present in full + minimal and MISSING from floating** (D-26). `mpris` is present in full + minimal. All four copies get consolidated by D-31.
- `waybar/.config/waybar/style-{minimal,full,floating}.css` — three stylesheets, each `@import`ing `~/.local/state/theme/waybar.css` + `waybar-font.css`. `window#waybar` is currently a fully-opaque `@background` slab with a `3px solid @primary` border-bottom — the primary target of D-06's luminance trim.
- `hypr/.config/hypr/scripts/waybar-switch.sh` — **hardcodes the three-item layout list** (D-32); uses the exit-code-130 walker-dmenu cancel pattern
- `hypr/.config/hypr/scripts/waybar-launch.sh` — **hardcodes the valid layout values** and restores last-used from `~/.cache/current-waybar-layout`, defaulting to `full` (D-16, D-32)
- `hypr/.config/hypr/scripts/gaming-mode-toggle.sh` — **`_gaming_waybar_toggle()` at line ~38 is a deliberate one-line `pkill -SIGUSR1 waybar`, commented "Phase 8 … must be able to RE-POINT this one call."** D-03 is that re-point. It also `SIGSTOP`s hypridle (line ~85), which D-05 must account for.
- `swaync/.config/swaync/config.json` — `widgets: ["dnd", "mpris", "title", "notifications"]`; **`mpris` comes out (D-24)**, sliders + toggle grid go in (D-27/D-28). Geometry: top-right, 380px, 10px margins (D-30).
- `hypr/.config/hypr/config/keybinds.conf` — the new bar-toggle bind lands here with a `# description` (D-37). `$mainMod, B` = waybar-switch; `$mainMod, N` = swaync toggle.
- `hypr/.config/hypr/config/autostart.conf` — line 31 `exec-once = uwsm app -- waybar-launch.sh`; line 34 `exec-once = uwsm app -- swaync`. The visibility owner and hypridle listener hook in around here.

### Theming pipeline (eww adds the first new target since Phase 6)
- `theme-engine/.config/theme-engine/contract.json` — the render-target manifest. Today's waybar entries: `waybar.css` (gtk-css) + `waybar-font.css` (presence-only). **eww adds a new target (D-19).**
- `matugen/.config/matugen/templates/waybar-colors.css` — the named-color source the bars consume
- `matugen/.config/matugen/templates/swaync-colors.css` — the panel's colors; the D-27/D-28 widgets must theme through this
- `matugen/.config/matugen/config.toml` — where the new eww `[templates.*]` entry lands
- `theme-engine/.config/theme-engine/theme-parity` — the light+dark parity gate across 22 palettes; **must go green with the new eww target** (D-19)
- `theme-engine/.config/theme-engine/theme-doctor` — the CSS-parse regression guard; **D-17's module-color assertion should fold in here**

### Reproducibility
- `install.sh` — eww joins PACMAN_PKGS/AUR_PKGS under the standard package gate (D-36)
- `verify/` — the container gate; must stay green and unattended, and eww is a compiled Rust binary (D-36)

### External reference
- **Modern-rice research is explicitly called for by BAR-04** ("form factor per modern-rice research"). The user has already chosen the *form* (a dedicated eww popup) — research informs the *content and construction*, not whether to build it.
- Omarchy (github.com/basecamp/omarchy) — the standing aesthetic reference for this project.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`waybar.css` is already a contract target** — the bars, the vertical layout, and the gaming indicator are all pipeline-themed with **zero new render targets**. Only eww adds one (D-19).
- **The `mpris` module already exists and works** in full/minimal — D-22 keeps it and repurposes it as the popup trigger rather than replacing it.
- **The `custom/notification` module already exists and works** (`swaync-client -t -sw` / `-d -sw`) — BAR-05's "button" is already built; the work is parity + the panel behind it.
- **swaync's mpris widget already renders album art** — worth reading before building eww's, then **deleting** (D-24).
- **`waybar-launch.sh`'s last-used-layout state file** (`~/.cache/current-waybar-layout`) is the seam vertical slots into (D-16).
- **Phase 7's `~/.cache/gaming-mode` state file** is the gaming indicator's data source, left deliberately as a probe (D-35).
- **Phase 6's theme-doctor CSS-parse guard** is where D-17's module-color assertion belongs.

### Established Patterns
- **One owner, one entrypoint** (theme-engine consolidation) — directly drives D-03's visibility owner over the current everyone-sends-SIGUSR1 free-for-all.
- **Dynamic enumeration, never hardcoded lists** (Phase 5 palettes) — directly drives D-32.
- **Verify against the installed binary before relying on it** (Phase 4 hyprlock) — drives D-07 (waybar has no native hide animation), D-23 (layer-shell anchoring may not exist), D-31 (waybar `include` semantics).
- **Rerunnable gates, not one-time checklists** (theme-doctor / theme-parity / P7 D-04) — drives D-17 and D-34.
- **One surface per job; delete duplicates** (powermenu.sh, wofi, `themes/`) — drives D-24 (mpris out of swaync) and bounds D-28 (the toggle grid must reuse, never re-implement).
- **Runtime-only state overrides, never config rewriting** (P7 D-26) — the visibility owner must not rewrite waybar's config files to hide the bar.
- **Nerd Font glyphs, not assets** (P6 D-10) — the vertical bar's glyph-reduced modules (D-12).

### Integration Points
- `gaming-mode-toggle.sh::_gaming_waybar_toggle()` → re-points to the D-03 visibility owner. **Phase 7 wrote this line specifically so Phase 8 would not have to tear out a bespoke hide mechanism — honor that.**
- `hypridle` config → gains the D-05 listener. Note gaming mode `SIGSTOP`s hypridle.
- `keybinds.conf` → the bar-toggle bind (D-37), auto-consumed by the MENU-07 cheat-sheet.
- `swaync/config.json` → mpris out (D-24), sliders + toggle grid in (D-27/D-28), calling the SAME scripts the Super-key menu calls (D-28).
- `contract.json` + `matugen/config.toml` + `theme-parity` → the new eww render target (D-19).
- `install.sh` + `verify/` → eww package + container gate (D-36).
- **Phase 9 (wleave)** — untouched by this phase; the bar's power button delegates to `wlogout.sh` as before.

</code_context>

<specifics>
## Specific Ideas

- **The user chose the most expensive media option knowingly.** A waybar drawer or routing to swaync's existing mpris widget would have been near-free; a dedicated eww popup with art, seek bar, volume, and a player switcher is what a media *center* actually means to them, and they accepted a new toolkit + a new render target + 22 new parity fixtures to get it.
- **eww is sanctioned beyond this phase** (D-20) — the user is open to future eww widgets. But the bar stays waybar in Phase 8. Do not let eww's gravitational pull turn this into a bar rewrite.
- **The OLED work is treated as a real hardware concern, not a rice aesthetic** — two independent hide triggers, and a deliberate refusal to let the bar pop out of the screen edge mid-game.
- **The user consistently chose the anti-drift option** even when it wasn't asked for: one visibility owner over SIGUSR1 toggles, shared includes over four copies, disk enumeration over hardcoded lists, mpris deleted from swaync, refactor-first as its own no-op plan with a mechanical equivalence gate. The one place they went the other way (widgets in the swaync panel, D-27/D-28) is bounded by an explicit reuse-the-same-script-and-state constraint.
- **BAR-02 is the one requirement allowed to fail** — but only loudly, with evidence, in `08-VERIFICATION.md`.

</specifics>

<deferred>
## Deferred Ideas

- **eww widgets beyond the media popup** (calendar, system dashboard, gaming overlay) — sanctioned in principle (D-20), out of scope for Phase 8. The bar stays waybar.
- **Vertical as the default layout** — rejected for now (D-16); it would re-baseline the fresh-install experience and the container/VM gate.
- **Per-monitor bar configuration** (vertical on one display, horizontal on another) — rejected (D-15); no `output` key exists anywhere today and a bar that vanishes on replug is a support burden.
- **Edge-hover reveal** — explicitly rejected (D-02), not deferred. It would pop the bar out mid-game.
- **True-black OLED bar background** — explicitly rejected (D-06), not deferred. It opts the bar out of the palette.
- **A "nothing playing" placeholder in the media popup** — rejected (D-25); no player means no trigger.
- **Redesigning the three existing bars' visual identity** — out of scope. D-31's refactor is behavior-preserving (D-33), and D-06's styling pass is a luminance trim, not a redesign.

</deferred>

---

*Phase: 8-Waybar Evolution*
*Context gathered: 2026-07-14*
