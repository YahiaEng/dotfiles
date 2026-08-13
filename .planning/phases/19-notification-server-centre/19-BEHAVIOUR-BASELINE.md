# Phase 19 GATE-01 Behaviour Baseline — the outgoing swaync notification daemon & centre

This document is this phase's one irreversible read: every behaviour of swaync's
`config.json`, `style.scss` and CLI surface, enumerated while the implementation still
exists to be read, written down as gesture-and-observation acceptance criteria a human
can execute against the QML replacement. Plan `19-08` (RETIRE-03) deletes the `swaync`
stow package, `swaync-launch.sh` and every reference to it in one wave — after that
commit nothing here can be re-derived; it can only be read. Follows the structure Phase
18's own `18-BEHAVIOUR-BASELINE.md` established (§ "GATE-01 Recurrence Protocol") and
its per-phase surface table, which named this phase's inputs in advance: `config.json`,
`style.css`(`.scss`), swaync's two-key contract entries, and its `swaync-client` CLI
surface (`-swb`, `-t -sw`, `-d -sw`, `-rs`, `--subscribe`).

## Provenance

Source files (repo-relative, as they stood on 2026-08-13, the day this plan was
authored and the day this baseline was taken):

- `swaync/.config/swaync/config.json` — the live behaviour source.
- `swaync/.config/swaync/style.scss` — its themed surface (imports `swaync.css`, the
  matugen-rendered palette, via `@import url("swaync.css")`, and `motion` tokens via
  `@use "motion" as m`).
- `hypr/.config/hypr/scripts/swaync-launch.sh` — the launch wrapper and its state-dir
  stylesheet indirection.
- `hypr/.config/hypr/config/keybinds.lua:227` — the toggle verb's bind site.
- `theme-engine/.config/theme-engine/lib/reload.sh:82-89` — the reload verb's call site.
- `quickshell/.config/quickshell/modules/dashboard/QuickToggles.qml` — one of the two
  toggle grids invoking the DND enable/disable verbs (the Super-key menu's quick-toggle
  grid, BAR-05's promoted singleton).
- `quickshell/.config/quickshell/modules/bar/ClockActionsCapsule.qml` — the bar's own
  bell/notification-centre surface, a second live consumer of the CLI surface (unread
  count + DND read via `-swb`, toggle-open via `-t -sw`, toggle-DND via `-d -sw`).
- `swaync/.config/swaync/config.json`'s own `widget-config.buttons-grid.actions` DND
  entry — swaync's **own native toggle grid**, rendered inside the control centre
  itself, distinct from the two QML consumers above. "Both toggle grids" in this
  document's DND rows means this native grid and the QML dashboard's grid.

There is no dedicated resolver for swaync's JSON/CSS format (per Phase 18's own
per-phase surface table) — every row below is a direct read of the source files named
above, cross-checked against their repo-verified call sites rather than assumed from
memory.

## Not a Port Specification

This document records what the outgoing swaync surface does, so that nothing already
built is lost by accident when its sources are deleted (`19-08`, RETIRE-03). It neither
licenses nor mandates reproducing *how* the centre looked or *where* its widgets sat.
`REQUIREMENTS.md` § Out of Scope rules out pixel-for-pixel ports of the migrated
surfaces, and `PROJECT.md` frames v4.0 as a redesign against the end-4/Caelestia
reference language, not a port — a later executor reading this document as a compliance
checklist would silently invert both.

**The concrete trap is the widget order.** swaync's own `widgets` array is, top to
bottom: `title, dnd, volume, slider, buttons-grid, notifications` — the live control
panel (title bar, DND switch, volume slider, brightness slider, the three-button
toggle grid) sits above the notification list. `19-CONTEXT.md`'s **D-19-17** deliberately
**inverts** this: the QML centre's content order is header (live count + clear-all) →
grouped history → toggle grid + volume/brightness/mic sliders pinned as a bottom
footer — controls move to a fixed bottom target and history gets the top and the space,
because "in a *notification* centre, history gets the top and the space." A reader who
takes swaync's `widgets` ordering below (`title, dnd, volume, slider, buttons-grid,
notifications`) as a target to reproduce would build the wrong centre — the ordering is
recorded here as the *retired* arrangement for the record, exactly as D-19-17's own
text already states, not as a requirement for what replaces it. Likewise
`control-center-width: 420` and `control-center-margin-*` below are retired pixel
values, not targets — `19-RESEARCH.md`'s own D-19-15 already supersedes the width with
Caelestia's 430px, citing this 420 figure "for the record."

## Criterion Grammar

Every row below obeys these rules, matching Phase 18's own grammar scaled to a
single-surface document (no multi-layout merge/ordering machinery is needed — swaync
has exactly one live configuration, not four):

- **ID namespace.** `SWC-NN` for every row. IDs are stable once written and are cited by
  `19-08`'s post-deletion verification — a row is never renumbered.
- **Row shape.** ID · Source key(s) · Checkable criterion · Call site / verified location.
  The criterion column is a gesture-and-observation sentence — what a human does, and
  what they then observe, matching Phase 18's own discipline ("a notification arrives
  and clears itself after N seconds unless it is critical," not "config key `timeout`
  is 5").
- **Dead-definition rule.** A key or widget present in `config.json`/`style.scss` but
  never actually reachable by any live call path is a dead definition — recorded in
  `## Dead Definitions`, never in a criteria row.
- **Absence rule.** No live capability on this surface is absent in the sense Phase
  18's `floating.jsonc`/`vertical.jsonc` bar-level chrome omitted keys — swaync's
  `config.json` is one file, not four layouts, so this rule has no live instance here
  and is stated for completeness only, matching Phase 18's own precedent for a rule
  with zero live occurrences.

## Capability Surface — Notification Popups

| ID | Source key(s) | Checkable criterion | Call site / verified location |
|---|---|---|---|
| SWC-01 | `timeout`, `timeout-low`, `timeout-critical` | Send a normal-urgency notification (`notify-send "test"`) — it self-clears after 5 seconds. Send a low-urgency one (`notify-send -u low "test"`) — it self-clears after 3 seconds. Send a critical one (`notify-send -u critical "test"`) — it does **not** self-dismiss; it stays until the user closes it or clears it from the centre. | `config.json`: `"timeout": 5`, `"timeout-low": 3`, `"timeout-critical": 0` (0 disables the auto-timeout). `19-RESEARCH.md` D-19-04 already cites these three exact values as the migration's own "match swaync exactly" baseline. |
| SWC-02 | `notification-icon-size` | A notification carrying an app icon renders it at a fixed 48px square — consistently sized regardless of the source app's own icon resolution. | `config.json`: `"notification-icon-size": 48`. |
| SWC-03 | `notification-body-image-height`, `notification-body-image-width` | A notification carrying an inline image (e.g. a screenshot-tool "saved" notification, or an image-hint-bearing notification) renders that image capped at 120px tall by 200px wide — never larger, regardless of the source image's own dimensions. | `config.json`: `"notification-body-image-height": 120`, `"notification-body-image-width": 200`. |
| SWC-04 | `image-visibility` | An image only renders `when-available` — i.e. swaync does not reserve blank image space for a notification that never supplied one; the card's height is determined by whether an image hint is actually present. | `config.json`: `"image-visibility": "when-available"`. |
| SWC-05 | `notification-window-width` | Each floating popup card is 380px wide, distinct from the control centre's own 420px width (SWC-13) — the popup and the centre are not the same width on the outgoing surface. | `config.json`: `"notification-window-width": 380`. `19-RESEARCH.md` D-19-02 already records this exact 380 figure as the value the replacement's 430px (equal to the centre) supersedes. |
| SWC-06 | `relative-timestamps` | A notification's age renders as a relative, live-updating label ("now", "3m", "2h") rather than a fixed clock time — both on the popup and inside the centre's history. | `config.json`: `"relative-timestamps": true`. `19-CONTEXT.md` D-19-32 names this exact key as the precedent for the replacement's own relative-timestamp behaviour. |
| SWC-07 | `fit-to-screen` | Popups are geometrically constrained to never render off the visible screen edge — a very tall or many-stacked notification stack clips/repositions to stay fully on-screen rather than overflowing past the display boundary. | `config.json`: `"fit-to-screen": true`. |
| SWC-08 | `hide-on-clear` | Clearing a notification (dismiss gesture) does **not** also close the whole control centre panel if it happens to be open — `hide-on-clear` is `false`, so clearing a notification and having the centre itself close are two independent actions. | `config.json`: `"hide-on-clear": false`. |
| SWC-09 | `hide-on-action` | Clicking a notification's action button (where the notification has one) **does** close/hide the control centre if it is open — distinct behaviour from SWC-08's clear-vs-hide split. | `config.json`: `"hide-on-action": true`. |
| SWC-10 | `script-fail-notify` | If a widget's own backing script fails (e.g. the brightness slider's `cmd_getter`/`cmd_setter` — SWC-19 — exits non-zero), swaync surfaces that failure as a visible notification rather than failing silently. | `config.json`: `"script-fail-notify": true`. |

## Capability Surface — Control Centre Chrome

| ID | Source key(s) | Checkable criterion | Call site / verified location |
|---|---|---|---|
| SWC-11 | `positionX`, `positionY` | The control centre (and popups) anchor to the **top-right** of the screen — opening it with `Super+N` or the bar bell always summons it in that corner, never any other edge. | `config.json`: `"positionX": "right"`, `"positionY": "top"`. `19-CONTEXT.md` D-19-01 already records "always top-right" as the replacement's own locked decision, citing this as the unchanged baseline. |
| SWC-12 | `layer`, `control-center-layer` | Both the notification popups and the control centre render as Wayland layer-shell surfaces at the `overlay`/`top` layers respectively — they sit above ordinary application windows unconditionally, the same layer-shell posture the wifi/bluetooth panel z-order lesson (PROJECT.md Key Decisions) already documents for this codebase's other overlay surfaces. | `config.json`: `"layer": "overlay"`, `"control-center-layer": "top"`. |
| SWC-13 | `control-center-width` | The control centre panel is 420px wide when open. | `config.json`: `"control-center-width": 420`. Retired value for the record only — `19-RESEARCH.md` D-19-15 already supersedes it with Caelestia's 430px; see `## Not a Port Specification` above. |
| SWC-14 | `control-center-margin-top`, `control-center-margin-bottom`, `control-center-margin-right`, `control-center-margin-left` | The centre panel sits 10px from the top edge, 10px from the bottom edge, 10px from the right edge, and flush (0px) against the left edge of its own anchored corner — i.e. it does not float free of the screen edge it's anchored to. | `config.json`: `"control-center-margin-top": 10`, `"control-center-margin-bottom": 10`, `"control-center-margin-right": 10`, `"control-center-margin-left": 0`. |
| SWC-15 | `keyboard-shortcuts` | While the control centre is open, its own internal keyboard shortcuts are active (e.g. Escape to close) — this is the flag that gates swaync's own keybinding layer inside the centre, independent of any Hyprland-level bind. | `config.json`: `"keyboard-shortcuts": true`. |
| SWC-16 | `transition-time` | The centre's open/close slide-and-fade animation runs over 130ms. | `config.json`: `"transition-time": 130`. Retired duration for the record — the replacement reads all its own durations from `Motion.qml` tokens per `19-CONTEXT.md` D-19-13, not this literal value. |
| SWC-17 | `cssPriority` | swaync's own stylesheet rules are loaded at `"application"` CSS priority — a GTK-internal cascade-priority setting with no separate user-facing gesture; recorded here purely so the key is accounted for (see `## Unaccounted Keys`), not because it has an observable behaviour distinct from "the theme applies." | `config.json`: `"cssPriority": "application"`. |
| SWC-18 | `$schema` | The config file validates against swaync's own JSON schema at `/etc/xdg/swaync/configSchema.json` — an editor/tooling convenience with no runtime user-facing behaviour, recorded here purely so the key is accounted for. | `config.json`: `"$schema": "/etc/xdg/swaync/configSchema.json"`. |

## Capability Surface — Widgets (`widgets`, `widget-config`)

| ID | Source key(s) | Checkable criterion | Call site / verified location |
|---|---|---|---|
| SWC-19 | `widgets` (array), `widget-config.title` | Opening the centre shows a "Notifications" header row with a visible "Clear All" button that clears every notification in one press. | `config.json`: `"widgets": [..., "title", ...]`, `"widget-config": {"title": {"text": "Notifications", "clear-all-button": true, "button-text": "Clear All"}}`. `19-CONTEXT.md` D-19-28 already names this exact clear-all affordance as the capability the replacement's header-mounted clear-all button carries forward (relocated, per D-19-28's own reasoning, because D-19-17's pinned footer occupies Caelestia's usual floating-bottom-right position). |
| SWC-20 | `widget-config.dnd` | The centre shows a "Do not disturb" switch row; toggling it suppresses new popup notifications while the switch is on. | `config.json`: `"widget-config": {"dnd": {"text": "Do not disturb"}}`. |
| SWC-21 | `widget-config.volume` | The centre shows a "Volume" labeled slider controlling output volume, backed by swaync's own PipeWire/PulseAudio integration (no `cmd_setter`/`cmd_getter` override — this is the one slider using swaync's built-in audio binding, distinct from SWC-22's shell-scripted brightness slider). | `config.json`: `"widget-config": {"volume": {"label": "Volume"}}`. `19-CONTEXT.md` D-19-20 explicitly supersedes this with a reused `AudioBackend.qml` view — recorded here as the capability being carried forward via a different implementation, not a literal config port. |
| SWC-22 | `widget-config.slider` | The centre shows a "Brightness" labeled slider, range 5-100, that reads the current backlight level via `brightnessctl -c backlight -m` (parsed for the percent field, defaulting to `0` on any non-numeric/empty read) and sets it via `brightnessctl -c backlight set $value% -q` on drag. | `config.json`: `"widget-config": {"slider": {"label": "Brightness", "cmd_setter": "brightnessctl -c backlight set $value% -q", "cmd_getter": "v=$(brightnessctl -c backlight -m 2>/dev/null \| cut -d, -f4 \| tr -d %); case $v in ''\|*[!0-9]*) echo 0 ;; *) echo $v ;; esac", "min": 5, "max": 100}}`. `19-CONTEXT.md` D-19-20 explicitly kills this exact shell-out pair outright, replacing it with `BrightnessBackend.qml` — recorded here as the capability (a working brightness slider) the replacement must still deliver, by a different mechanism. |
| SWC-23 | `widget-config.buttons-grid` (Gaming) | The centre shows a 3-per-row toggle button grid; its first button (glyph `` U+F0BA4) toggles gaming mode via `~/.config/hypr/scripts/gaming-mode-toggle.sh` and reads its lit/unlit state from `~/.cache/gaming-mode` (`on` → lit, anything else/missing → unlit). | `config.json`: `"widget-config": {"buttons-grid": {"buttons-per-row": 3, "actions": [{"label": "󰊴", "type": "toggle", "command": "~/.config/hypr/scripts/gaming-mode-toggle.sh", "update-command": "v=$(cat ~/.cache/gaming-mode 2>/dev/null \|\| echo off); case $v in on) echo true ;; *) echo false ;; esac"}, ...]}}`. Byte-identical script/path/default to the QML dashboard's own Gaming chip (`QuickToggles.qml` `gamingProcess`/`gamingFile`), confirmed by direct cross-read — this is one of the three chips D-19-19's "one singleton backend" promotion is reconciling into a single source of truth. |
| SWC-24 | `widget-config.buttons-grid` (DND) | The grid's second button (glyph `` U+F02DB) is swaync's **own native DND toggle** — its `command` reads the current toggle state from the shell environment variable `$SWAYNC_TOGGLE_STATE` (swaync's own convention for a `type: toggle` button, not to be confused with `swaync-client -D`) and runs `swaync-client -dn` when currently on or `swaync-client -df` when currently off; its `update-command` polls `swaync-client -D` to report the switch's own current lit state. This is the **first of "both toggle grids"** referenced throughout this document. | `config.json`: `"widget-config": {"buttons-grid": {"actions": [..., {"label": "󰂛", "type": "toggle", "command": "case $SWAYNC_TOGGLE_STATE in true) swaync-client -dn ;; *) swaync-client -df ;; esac", "update-command": "swaync-client -D"}, ...]}}`. |
| SWC-25 | `widget-config.buttons-grid` (Dark) | The grid's third button (glyph `` U+F0616) opens the theme picker via `~/.config/hypr/scripts/theme-switch.sh` and reads its lit/unlit state from `~/.local/state/theme/mode` (`dark` → lit, anything else/missing → unlit). | `config.json`: `"widget-config": {"buttons-grid": {"actions": [..., {"label": "󰖔", "type": "toggle", "command": "~/.config/hypr/scripts/theme-switch.sh", "update-command": "v=$(cat ~/.local/state/theme/mode 2>/dev/null \|\| echo dark); case $v in dark) echo true ;; *) echo false ;; esac"}]}}`. Byte-identical script/path/default to the QML dashboard's own Dark chip. |
| SWC-26 | `widget-config.notifications` | The notification list fills all remaining vertical space in the centre (`vexpand: true`) rather than being a fixed-height scrollable region with dead space below it. | `config.json`: `"widget-config": {"notifications": {"vexpand": true}}`. |

## CLI Surface — the four verbs and their call sites

| ID | Verb | Checkable criterion | Call site(s) |
|---|---|---|---|
| SWC-27 | Toggle (`swaync-client -t -sw`) | Pressing `Super+N` opens the control centre if closed, or closes it if already open; the bar's own bell/notification-centre glyph does the identical toggle on click. | `hypr/.config/hypr/config/keybinds.lua:227` — `hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("swaync-client -t -sw"))`. `quickshell/.config/quickshell/modules/bar/ClockActionsCapsule.qml:685` — `openCentreProcess` `command: ["swaync-client", "-t", "-sw"]`. |
| SWC-28 | Reload (`swaync-client -rs`) | Running a theme switch (`theme-apply <name>`) re-applies the freshly-rendered stylesheet to the **already-running** swaync process — no restart, the daemon stays up and its notification history/DND state is preserved across the reload. Guarded: only fires if `pgrep -x swaync` finds the process, and is bounded by a 5-second `timeout` so a hung call cannot block the rest of the reload fan-out (Quick 260709-buf's own headless-hang precedent). | `theme-engine/.config/theme-engine/lib/reload.sh:87-89` — `if pgrep -x swaync >/dev/null 2>&1; then timeout 5 swaync-client -rs >/dev/null 2>&1 \|\| true; fi`. |
| SWC-29 | DND enable (`swaync-client -dn`) | Pressing swaync's own native DND button (SWC-24) while DND is currently off turns it on — no new popups appear until it is turned back off. Pressing the QML dashboard's Dark-adjacent DND chip while DND reads off does the identical thing. | `config.json`'s `buttons-grid` DND action (SWC-24, via the `$SWAYNC_TOGGLE_STATE` case statement). `quickshell/.config/quickshell/modules/dashboard/QuickToggles.qml:344,392` — `dndProcess` `command: ["swaync-client", "-dn"]`, selected in `pressDnd()` when `root.dndState` is currently false. This is the **second of "both toggle grids."** |
| SWC-30 | DND disable (`swaync-client -df`) | The same two toggle grids' DND action, in the opposite direction — pressing either one while DND currently reads on turns it back off. | `config.json`'s `buttons-grid` DND action (SWC-24, the `-df` case-statement branch). `quickshell/.config/quickshell/modules/dashboard/QuickToggles.qml:392` — `dndProcess.command = root.dndState ? ["swaync-client", "-df"] : [...]`. |
| SWC-31 | DND toggle, single-verb form (`swaync-client -d -sw`) | The bar's own bell capsule flips DND with one unconditional toggle call (not an explicit on/off pair like SWC-29/30) — a right-click (or equivalent bound gesture) on the bell flips whatever DND's current state is. | `quickshell/.config/quickshell/modules/bar/ClockActionsCapsule.qml:689` — `toggleDndProcess` `command: ["swaync-client", "-d", "-sw"]`. |
| SWC-32 | Live unread/DND subscribe, streaming form (`swaync-client --subscribe`) | While the QML dashboard's quick-toggle grid is mounted, its DND chip's lit state updates the instant DND is flipped from *anywhere* (the bar bell, swaync's own grid, or the dashboard's own press) — no polling delay, proven live this repo's own Phase 14 verification by flipping DND from outside any drawer instance and observing the subscribe stream emit a fresh line with no polling involved. | `quickshell/.config/quickshell/modules/dashboard/QuickToggles.qml:217` — `dndSubscribeProcess` `command: ["swaync-client", "--subscribe"]`, one JSON object per line (`{"count","dnd","visible","inhibited"}`). |
| SWC-33 | Live unread/DND subscribe, short-flag form (`swaync-client -swb`) | While the bar's bell capsule is mounted, its unread-count badge and DND-lit state update live from the same subscription mechanism as SWC-32, using the short-flag spelling instead of the long one — both spellings are the same underlying swaync subscribe stream. | `quickshell/.config/quickshell/modules/bar/ClockActionsCapsule.qml:654` — `notificationSubscription` `command: ["swaync-client", "-swb"]`, parsing a `text` (unread count) and `class` (one of 8 states, e.g. `dnd-notification`/`none`) field per line. |
| SWC-34 | DND one-shot poll (`swaync-client -D`) | If the streaming subscribe (SWC-32) hasn't produced a single valid line within 4 seconds of the dashboard grid mounting, a one-shot poll fallback arms and reads DND's current boolean state directly, then polls again every 2 seconds until the stream catches up — a resilience path, not the primary read mechanism. | `quickshell/.config/quickshell/modules/dashboard/QuickToggles.qml:251` — `dndPollProcess` `command: ["swaync-client", "-D"]`, gated by `dndSubscribeGraceTimer`/`dndSubscribeSeen`. Also the `update-command` for swaync's own native DND button (SWC-24). |

## Styling Surface (`style.scss`)

| ID | Checkable criterion | Source |
|---|---|---|
| SWC-35 | The control centre background is translucent (72% opacity), not opaque — the desktop blurs through it via the compositor's own `blur, swaync-control-center` layerrule, because the alpha is above the 0.5 `ignore_alpha` threshold. A hairline 1px border (25% opacity) traces its edge, not a thick chroma slab. | `style.scss:6-15` — `.control-center { background: alpha(@background, 0.72); border: 1px solid alpha(@primary, 0.25); ... }`, with the file's own comment naming the prior "intrusive, no blur" bug this fixed. |
| SWC-36 | Each notification renders as exactly **one** visible box — a single background/border pair — not two stacked, offset boxes. | `style.scss:119-146` — the file's own comment documents an "08-15 fix": the box lives on `.notification` only, with `.notification-row`/`.notification-background`/`.notification-group` deliberately kept inert (`background: transparent; border: none; box-shadow: none;`) so nothing paints a second box behind it. |
| SWC-37 | A critical-urgency notification's card renders with a visibly thicker (3px vs. the ordinary 1px), error-coloured border — distinguishing it at a glance from a normal notification even before reading its text. A low-priority notification's border instead reads in a muted surface-variant colour. | `style.scss:189-198` — `.critical .notification { border-color: @error; border-width: 3px; }`, `.low .notification { border-color: @surface_variant; }`. |
| SWC-38 | Every interactive element on this surface (title's Clear-All button, close button, notification action buttons, slider handles, toggle-grid buttons) animates its hover/press colour transition using the shared theme-engine motion tokens, not a hardcoded duration. | `style.scss:1` — `@use "motion" as m;`, referenced throughout as `#{m.$motion-duration-standard} #{m.$motion-easing-standard}` on `.widget-title > button`, `.widget-buttons-grid flowboxchild > button`, `.notification`, `.close-button`, `.notification-action`, and the volume/slider scale handles. |
| SWC-39 | Every colour on this surface (background, borders, text, button states) comes from the live palette (`@background`, `@primary`, `@on_primary`, `@surface_variant`, `@outline`, `@error`, `@tertiary`, etc.) via the compiled `swaync.css` import — a theme switch re-colours the entire centre and every popup with no swaync restart, only the belt-and-suspenders reload (SWC-28). | `style.scss:2` — `@import url("swaync.css");`, the matugen-rendered palette file every named colour token above resolves against. |

## Launch/Fallback Surface

| ID | Checkable criterion | Source |
|---|---|---|
| SWC-40 | On session start, swaync launches pointed at the theme-compiled stylesheet (`~/.local/state/theme/swaync-style.css`) if it exists. If that compiled file is ever missing (a fresh install before the first `theme-apply`, or a corrupted state dir), swaync still starts — **unstyled but running** — rather than the session having no notification daemon at all; a visible stderr line names the missing file and what to run to fix it. This mirrors the retired bar's own launcher's documented fallback discipline (D-05): "a themed daemon is better than none, an unstyled daemon is better than none, 'none' is the only real failure." | `hypr/.config/hypr/scripts/swaync-launch.sh` — `if [[ -f "$COMPILED_STYLE" ]]; then exec swaync -s "$COMPILED_STYLE"; else echo "... starting swaync unstyled ..." >&2; exec swaync; fi`, no `-e` at the top of the script specifically so a transient early-session condition never aborts before reaching the fallback `exec`. |

## Dead Definitions

**None.** Unlike Phase 18's four waybar layouts — which accumulated dead module
definitions and one hardware-inert scroll binding across multiple design iterations
(the athena `tray` removal, the floating `backlight` scroll) — swaync's `config.json`
carries no key, widget, or `widget-config` entry that is defined but unreachable by any
live call path. Every top-level key enumerated in `## Unaccounted Keys` below maps to a
live, currently-reachable capability recorded in one of the tables above. This is
stated as a one-line fact per the Criterion Grammar's dead-definition rule, not left
implicit.

## Unaccounted Keys

Closure proof: every top-level key of `swaync/.config/swaync/config.json`, checked
against every `SWC-*` row above. The list is explicitly empty.

Verbatim, the loop this section's closure claim rests on (identical in spirit to Phase
18's own `python3 -c "import json,sys; d=json.load(...); m=[k for k in d if k not in
b]; ..."` mechanical check — this document's own `<verify>` block in `19-02-PLAN.md`
runs exactly that loop against this file):

```
python3 -c "import json,sys; d=json.load(open('swaync/.config/swaync/config.json')); b=open('19-BEHAVIOUR-BASELINE.md').read(); m=[k for k in d if k not in b]; print('UNACCOUNTED', m); sys.exit(1 if m else 0)"
```

**28 top-level keys in `config.json`. Zero unaccounted:**

`$schema` (SWC-18) · `positionX` (SWC-11) · `positionY` (SWC-11) · `layer` (SWC-12) ·
`control-center-layer` (SWC-12) · `cssPriority` (SWC-17) · `notification-icon-size`
(SWC-02) · `notification-body-image-height` (SWC-03) · `notification-body-image-width`
(SWC-03) · `timeout` (SWC-01) · `timeout-low` (SWC-01) · `timeout-critical` (SWC-01) ·
`fit-to-screen` (SWC-07) · `relative-timestamps` (SWC-06) · `control-center-margin-top`
(SWC-14) · `control-center-margin-bottom` (SWC-14) · `control-center-margin-right`
(SWC-14) · `control-center-margin-left` (SWC-14) · `notification-window-width`
(SWC-05) · `control-center-width` (SWC-13) · `keyboard-shortcuts` (SWC-15) ·
`image-visibility` (SWC-04) · `transition-time` (SWC-16) · `hide-on-clear` (SWC-08) ·
`hide-on-action` (SWC-09) · `script-fail-notify` (SWC-10) · `widgets` (SWC-19 through
SWC-26 each name a member of this array) · `widget-config` (SWC-19 through SWC-26 each
name a nested block of this object). **(none unaccounted)**

## Feeds

This document's capability rows (SWC-01 through SWC-40) are the exclusion-aware input
plan `19-08`'s GATE-02 render gate checks the QML replacement against — a criterion
there is only checkable because a capability was written down here first, matching
Phase 18's own `18-BEHAVIOUR-BASELINE.md` → `18-19` relationship. The `## Dead
Definitions` section above (empty) is that gate's exclusion list: since it is empty,
every one of the 40 rows above is a live capability the replacement is expected to
carry forward — by a different mechanism where `19-CONTEXT.md`'s locked decisions
(D-19-01 through D-19-46) already say so, never silently.
