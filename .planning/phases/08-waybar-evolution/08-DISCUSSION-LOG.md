# Phase 8: Waybar Evolution - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-14
**Phase:** 8-Waybar Evolution
**Areas discussed:** OLED auto-hide behavior, Vertical layout scope, Media center form factor, Pixel-shift mitigation, Notification button scope, Layout config drift, Inherited scope & reproducibility

---

## OLED auto-hide behavior (BAR-01)

### Hide trigger

| Option | Description | Selected |
|--------|-------------|----------|
| Idle timeout | Hides after N seconds of no input, regardless of what's on screen | |
| Fullscreen/maximized window | Hides only for fullscreen apps; does nothing for the real burn-in case | |
| Both, independently | Either condition alone hides it; returns when both clear | ✓ |
| Always hidden, reveal on demand | Hidden by default; big daily-feel change | |

**User's choice:** Both, independently
**Notes:** Covers the actual OLED risk (a static bar lit for hours while reading/coding) *and* the immersion case. Creates a state-ownership problem addressed below.

### Reveal

| Option | Description | Selected |
|--------|-------------|----------|
| Any input + edge hover | Idle clears on input; fullscreen revealed by mouse-to-edge | |
| Any input + keybind only | Idle clears on input; fullscreen overridden only by explicit keybind | ✓ |
| Any input reveals, period | Bar flashes back over fullscreen video on any mouse move | |

**User's choice:** Any input + keybind only
**Notes:** Explicitly rejected edge-hover so nothing pops out mid-game or while scrubbing a video timeline.

### Visibility ownership

| Option | Description | Selected |
|--------|-------------|----------|
| One owner script + state file | Idle/fullscreen/gaming/keybind send intents; owner computes state | ✓ |
| Everyone sends SIGUSR1 | Today's mechanism; SIGUSR1 is a toggle, so state desyncs | |
| You decide | Let research pick the mechanism | |

**User's choice:** One owner script + state file
**Notes:** Phase 7's `_gaming_waybar_toggle` re-points to this owner — exactly what its footnote anticipated. Kills the toggle-desync bug class.

### OLED styling

| Option | Description | Selected |
|--------|-------------|----------|
| Translucency on all layouts | Alpha over wallpaper, toned-down accents | |
| Translucency + true-black option | Pixels physically off; opts the bar out of the palette | |
| Only where it doesn't fight the theme | Translucency + trim high-luminance elements; all colors from the palette | ✓ |

**User's choice:** Only where it doesn't fight the theme
**Notes:** True-black rejected — it would cut against the project's core value and break the 5 light presets.

### Idle source

| Option | Description | Selected |
|--------|-------------|----------|
| hypridle listener | One idle daemon for the session; already governs lock/dpms | ✓ |
| Waybar's own idle handling | Fewest parts, but can't coordinate with gaming-mode/fullscreen | |
| Dedicated idle watcher | Decoupled from gaming-mode's SIGSTOP, but a duplicate mechanism | |

**User's choice:** hypridle listener
**Notes:** Flagged: gaming mode SIGSTOPs hypridle — the owner script must handle that.

### Idle timeout

| Option | Description | Selected |
|--------|-------------|----------|
| ~30 seconds | Aggressive; bar feels transient | |
| ~2 minutes | Middle ground | |
| ~5 minutes | Conservative; most burn-in exposure remains | |
| You decide | Sane default as a tunable constant | ✓ |

**User's choice:** You decide

### Reflow / exclusive zone

| Option | Description | Selected |
|--------|-------------|----------|
| No — keep the reserved space | Nothing shifts, ever | |
| Yes — windows reclaim the strip | Full tiled reflow every idle timeout | |
| Depends on the trigger | Idle keeps the zone; fullscreen/gaming drop it | ✓ |

**User's choice:** Depends on the trigger
**Notes:** The owner script already knows *why* it's hiding, so this is architecturally free.

### Animation

| Option | Description | Selected |
|--------|-------------|----------|
| Instant | Nothing to tune or desync | |
| Slide/fade | Matches Hyprland's feel; waybar has no native hide animation | ✓ |
| You decide | Cheap transition if free, else instant | |

**User's choice:** Slide/fade
**Notes:** Constrained on the spot — research must prove a clean GTK/margin approach exists on the installed binary; fall back to instant *with evidence* rather than build a bespoke animation harness.

### Overlays

| Option | Description | Selected |
|--------|-------------|----------|
| Bar stays hidden | Overlays are not a visibility intent | ✓ |
| Bar reveals with any overlay | Anchors the notification button, but adds a 5th actor | |

**User's choice:** Bar stays hidden

---

## Vertical layout scope (BAR-03)

### Form

| Option | Description | Selected |
|--------|-------------|----------|
| A 4th coexisting layout | Literal reading; means a 4th copy-pasted config | |
| A vertical variant of each | Position as an axis; doubles the re-test surface | |
| One vertical layout, its own thing | Designed for the column, not a rotated copy | ✓ |

**User's choice:** One vertical layout, its own thing

### Module set

| Option | Description | Selected |
|--------|-------------|----------|
| Glyph-only essentials | Workspaces, clock, volume, network, battery, notification, media, tray, power | |
| Essentials + system stats | The above plus cpu/memory/temperature as stacked readouts | ✓ |
| You decide | Anything needing a text label is out | |

**User's choice:** Essentials + system stats
**Notes:** Acknowledged tension — system stats are the most always-lit elements, which pulls against the OLED goal. Auto-hide is what makes it acceptable.

### Detail handling

| Option | Description | Selected |
|--------|-------------|----------|
| Tooltips only | Hover a glyph for detail | ✓ |
| Drop it entirely | No window title or track text at all | |

**User's choice:** Tooltips only

### Re-test gate

| Option | Description | Selected |
|--------|-------------|----------|
| Rerunnable gate + human pass | Assert every module class resolves to a real named color; human look under light + dark | ✓ |
| Human visual pass only | Cheapest; misses silently-unstyled modules | |
| Extend theme-doctor | Fold into the existing CSS-parse guard | |

**User's choice:** Rerunnable gate + human pass
**Notes:** Folding into theme-doctor is the preferred implementation of this (one gate, one place to look).

### Monitors

| Option | Description | Selected |
|--------|-------------|----------|
| Same as today | No `output` key; draws on every monitor | ✓ |
| Primary only | Introduces per-monitor config that exists nowhere else | |
| You decide | | |

**User's choice:** Same as today

### Default layout

| Option | Description | Selected |
|--------|-------------|----------|
| No — last-used wins | Vertical is just a 4th valid value in the state file | ✓ |
| Vertical becomes the default | Would re-baseline fresh installs and the gates | |

**User's choice:** No — last-used wins

### Column look

| Option | Description | Selected |
|--------|-------------|----------|
| Narrow and unobtrusive | Slim column, same treatment as the horizontal bars | ✓ |
| Island/floating style | Distinctive, but more CSS to keep in sync across 22 palettes | |
| You decide | | |

**User's choice:** Narrow and unobtrusive

---

## Media center form factor (BAR-04)

### Form

| Option | Description | Selected |
|--------|-------------|----------|
| Waybar drawer (group) | Native, free, but a strip of buttons — no art, doesn't work in the column | |
| Route to the swaync panel | Near-zero code; swaync's mpris widget already has art + transport | |
| Dedicated popup | A true "center"; new component, new theme target, new parity fixtures | ✓ |
| Drawer + swaync for depth | Two existing surfaces, no new component | |

**User's choice:** Dedicated popup
**Notes:** Knowingly the most expensive option — the only one that adds a component to the theme pipeline.

### Popup technology

| Option | Description | Selected |
|--------|-------------|----------|
| Floating kitty + TUI | Reuses the Phase 5/6 kitty-graphics picker stack; zero new contract targets | |
| eww widget | Real GTK desktop widget; new package, new template + contract target + 22 parity fixtures | ✓ |
| Bespoke GTK4 popover | Rejected on prior evidence — GTK4 palette theming is structurally unsupported | |
| You decide | | |

**User's choice:** eww widget
**Notes:** Accepted the new toolkit and the new render target deliberately.

### eww scope

| Option | Description | Selected |
|--------|-------------|----------|
| Media popup only — hard boundary | eww exists for one widget, period | |
| Media popup now, open to more later | eww sanctioned for future widgets | ✓ |

**User's choice:** Media popup now, open to more later
**Notes:** Hard boundary retained *for this phase*: waybar stays the bar. eww's pull toward becoming the bar must not be indulged in Phase 8.

### Popup content

| Option | Description | Selected |
|--------|-------------|----------|
| Art + track + transport | Smallest surface that justifies the widget | |
| Add a seek bar + volume | Needs a polling loop; the fiddly part | |
| Add a player switcher | Requirement names Spotify AND browser/YouTube by name | |
| You decide | | |

**User's choice:** All of it — art, track, transport, seek bar, volume, player switcher
**Notes:** Free-text answer selecting the full stack rather than one tier.

### Trigger & anchoring

| Option | Description | Selected |
|--------|-------------|----------|
| Click bar segment, anchored under it | Feels attached to the bar; anchoring may not be possible under layer-shell | ✓ |
| Click bar segment, fixed position | Works identically from every layout, incl. hidden bar | |
| You decide | | |

**User's choice:** Click bar segment, anchored under it
**Notes:** Flagged as needing feasibility verification — waybar modules aren't real windows. Fixed position is the fallback.

### Inline mpris segment

| Option | Description | Selected |
|--------|-------------|----------|
| Stays, becomes the trigger | Keeps glanceable now-playing AND gets the center | ✓ |
| Reduces to a glyph button | Cleaner, less always-lit text, but loses at-a-glance now-playing | |

**User's choice:** Stays, becomes the trigger
**Notes:** Existing scroll-to-volume / right-click-next bindings on that segment need rethinking so they don't fight the popup.

### swaync's existing mpris widget

| Option | Description | Selected |
|--------|-------------|----------|
| Remove it from swaync | One surface per job; a one-line config change | ✓ |
| Keep both | Two differently-styled media UIs a click apart | |

**User's choice:** Remove it from swaync

### Empty state

| Option | Description | Selected |
|--------|-------------|----------|
| Bar segment hides, popup won't open | Already the current behavior (`format-stopped: ""`) | ✓ |
| Placeholder state | Discoverable, but a UI you see for two seconds ever | |

**User's choice:** Bar segment hides, popup won't open

---

## Pixel-shift mitigation (BAR-02)

The user paused here and asked for a recommendation before choosing. Recommendation given: timebox a spike and expect it to land on descope — the auto-hide and low-luminance decisions already remove most of the exposure pixel-shift targets, while jitter would add a *second* actor moving the bar right after an entire area was spent establishing that exactly one thing should. Kill criteria matter more than the attempt.

| Option | Description | Selected |
|--------|-------------|----------|
| Timebox a spike, then decide *(recommended)* | Bounded attempt with explicit kill criteria; descope with a written record if it fails | ✓ |
| Descope now, argue from auto-hide | Saves effort; risks looking dodged rather than evaluated | |
| Commit to margin jitter | Most faithful to the letter; adds a second actor moving the bar | |

**User's choice:** Timebox a spike, then decide
**Notes:** Kill criteria: perceptible twitch, any window reflow, or any need to coordinate with the visibility owner.

### Shift budget (if the spike survives)

| Option | Description | Selected |
|--------|-------------|----------|
| A few px, every few minutes | Standard TV pixel-shift behavior | ✓ |
| You decide | | |

**User's choice:** A few px, every few minutes

### Descope evidence

| Option | Description | Selected |
|--------|-------------|----------|
| Phase verification doc | Recorded in 08-VERIFICATION.md alongside other requirement verdicts | ✓ |
| A dedicated finding doc | Outlives the phase | |
| You decide | | |

**User's choice:** Phase verification doc

---

## Notification button scope (BAR-05)

### Scope

| Option | Description | Selected |
|--------|-------------|----------|
| Parity only | Add the existing module to floating + vertical, verify, done | |
| Parity + swaync panel rework | Also design the surface the button actually opens | ✓ |
| You decide | | |

**User's choice:** Parity + swaync panel rework

### Panel content

| Option | Description | Selected |
|--------|-------------|----------|
| Notifications + dnd + clear-all | Strip it to its job | |
| Add useful widgets | Sliders / quick toggles — but SwayOSD and the Super-key menu already own those jobs | ✓ |
| You decide | | |

**User's choice:** Add useful widgets
**Notes:** This is the one answer that cuts against "one surface per job", so it was bounded deliberately rather than by accident (see below).

### Which widgets

| Option | Description | Selected |
|--------|-------------|----------|
| Sliders only — they're complementary | SwayOSD is feedback, not a draggable control | |
| Sliders + a small toggle grid | A true control center; risks two places toggling gaming mode | ✓ |
| You decide | A widget earns its place only if no existing surface does it | |

**User's choice:** Sliders + a small toggle grid
**Notes:** **Hard constraint imposed:** every toggle must call the same script and read the same state file as the Super-key menu entry. No second copy of the logic, no independently-derived state.

### Toggles

| Option | Description | Selected |
|--------|-------------|----------|
| Gaming mode + DND + theme | All three already have scripts the grid calls directly | ✓ |
| Just DND + gaming mode | Launching a launcher from inside a panel is a strange transition | |
| You decide | | |

**User's choice:** Gaming mode + DND + theme

### Interaction

| Option | Description | Selected |
|--------|-------------|----------|
| Inline actions + per-notification dismiss | The meaningful reading of "interact" | ✓ |
| Click-to-activate only | Loses the interactivity the requirement names | |

**User's choice:** Inline actions + per-notification dismiss

### Panel geometry

| Option | Description | Selected |
|--------|-------------|----------|
| Keep today's geometry | Top-right, 380px, 10px margins | |
| Revisit during design | Sliders + a grid may want more room | ✓ |

**User's choice:** Revisit during design

---

## Layout config drift

The user paused here and asked for a recommendation before choosing. Recommendation given: do both refactors, but verify waybar's `include` semantics against the installed binary first. The decisive evidence was that the copy-paste failure mode has *already happened* — the notification button is missing from `config-floating.jsonc` right now — and this phase was about to paste six new decisions into four files. The enumeration fix is the same one Phase 5 applied to palettes and recorded as closing that pitfall permanently.

### Config structure

| Option | Description | Selected |
|--------|-------------|----------|
| Shared definitions + per-layout composition *(recommended)* | Modules defined once; layouts compose. Verify `include` semantics first; don't build a preprocessor | ✓ |
| Accept the copies | Readable in isolation; six decisions pasted four times | |
| You decide | | |

**User's choice:** Shared definitions + per-layout composition
**Notes:** Scope guard stated: make *this phase's* changes land once — not a redesign of the three existing bars.

### Enumeration

| Option | Description | Selected |
|--------|-------------|----------|
| Enumerate from disk *(recommended)* | Glob `config-*.jsonc`; adding a layout becomes one file | ✓ |
| Just add the fourth entry | Two-line edit; drifts again next time | |

**User's choice:** Enumerate from disk

### Sequencing

| Option | Description | Selected |
|--------|-------------|----------|
| Refactor first, as its own plan | Behavior-preserving no-op; features build on a clean base | ✓ |
| Refactor as part of the vertical work | Fewer plans; can't tell which change broke the bar | |

**User's choice:** Refactor first, as its own plan

### Refactor gate

| Option | Description | Selected |
|--------|-------------|----------|
| Assert rendered config equivalence | Mechanically prove the same effective config per layout, plus a human pass | ✓ |
| Human pass per layout | Eyes miss a dropped on-click or a vanished tooltip | |
| You decide | | |

**User's choice:** Assert rendered config equivalence

---

## Inherited scope & reproducibility

### Gaming-mode indicator (deferred to Phase 8 by Phase 7)

| Option | Description | Selected |
|--------|-------------|----------|
| In — add the indicator | Reads the `~/.cache/gaming-mode` state file Phase 7 left as its probe | ✓ |
| Out — stays deferred | Not named by BAR-01..05 | |

**User's choice:** In — add the indicator

### eww packaging

| Option | Description | Selected |
|--------|-------------|----------|
| Standard package gate | Official repos preferred; AUR gets a human legitimacy check; container gate stays green | ✓ |
| You decide | | |

**User's choice:** Standard package gate
**Notes:** eww is a compiled Rust binary — its build/install time in the container gate is a real thing to watch.

### Bar-toggle keybind

| Option | Description | Selected |
|--------|-------------|----------|
| Follow the Phase 7 contract | Lands in keybinds.conf with a `# description`; cheat-sheet picks it up automatically | ✓ |
| You decide | | |

**User's choice:** Follow the Phase 7 contract

---

## Claude's Discretion

- Idle timeout value (single tunable constant at the top of the visibility script)
- Exact vertical module list, within "anything needing a text label doesn't belong in the column"
- Pixel-shift jitter magnitude and interval, if the spike survives
- The bar-toggle chord and its cheat-sheet wording
- eww widget internals: yuck/SCSS structure, seek-bar polling strategy, player-switcher presentation
- Whether the module-color assertion folds into theme-doctor or stands alone (fold preferred)
- swaync panel geometry after the widgets are designed

## Deferred Ideas

- eww widgets beyond the media popup (calendar, dashboard, gaming overlay) — sanctioned in principle, out of scope for Phase 8
- Vertical as the default layout — would re-baseline fresh installs and the gates
- Per-monitor bar configuration
- Edge-hover reveal — *rejected*, not deferred
- True-black OLED bar background — *rejected*, not deferred
- A "nothing playing" placeholder in the media popup — *rejected*
- Redesigning the three existing bars' visual identity — out of scope
