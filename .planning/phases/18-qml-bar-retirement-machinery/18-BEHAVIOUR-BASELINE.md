# Phase 18 GATE-01 Behaviour Baseline — the four retired waybar layouts

This document is the phase's one irreversible read: every behaviour of `config-athena.jsonc`,
`config-full.jsonc`, `config-floating.jsonc`, `config-vertical.jsonc`, `modules.jsonc` and
`bar-common.jsonc`, enumerated while the implementation still exists to be read, and written
down as gesture-and-observation acceptance criteria a human can execute against the QML
replacement. `18-20` (RETIRE-02) deletes every one of those six files **and**
`waybar-equivalence-check` — the only tool in this repo that resolves waybar's `include` chain
correctly — in a single commit, eight waves from now. After that commit nothing here can be
re-derived; it can only be read.

## Provenance

Source files (repo-relative, as they stood on 2026-08-10, the day this plan was authored and
the day this baseline was taken):

- `waybar/.config/waybar/config-athena.jsonc`
- `waybar/.config/waybar/config-full.jsonc`
- `waybar/.config/waybar/config-floating.jsonc`
- `waybar/.config/waybar/config-vertical.jsonc`
- `waybar/.config/waybar/modules.jsonc` (shared module definitions, included by all four)
- `waybar/.config/waybar/bar-common.jsonc` (shared bar-level signal contract, included by all four)

Each of the four `18-waybar-resolved/*.json` snapshots was produced by running, from the repo
root, exactly:

```
bash hypr/.config/hypr/scripts/waybar-equivalence-check --resolve waybar/.config/waybar/config-athena.jsonc   > .planning/phases/18-qml-bar-retirement-machinery/18-waybar-resolved/athena.json
bash hypr/.config/hypr/scripts/waybar-equivalence-check --resolve waybar/.config/waybar/config-full.jsonc     > .planning/phases/18-qml-bar-retirement-machinery/18-waybar-resolved/full.json
bash hypr/.config/hypr/scripts/waybar-equivalence-check --resolve waybar/.config/waybar/config-floating.jsonc > .planning/phases/18-qml-bar-retirement-machinery/18-waybar-resolved/floating.json
bash hypr/.config/hypr/scripts/waybar-equivalence-check --resolve waybar/.config/waybar/config-vertical.jsonc > .planning/phases/18-qml-bar-retirement-machinery/18-waybar-resolved/vertical.json
```

Date taken: 2026-08-11. `hypr/.config/hypr/scripts/waybar-equivalence-check` and the six source
files above are all deleted by `18-20` (RETIRE-02) in one commit — after that commit, the four
`18-waybar-resolved/*.json` snapshots committed alongside this document are the only surviving,
independently-checkable evidence of what every criterion below was derived from. They must not
be cleared, reformatted or removed by any later retirement sweep. `retirement-check`'s two-tier
design (D-18-37) reports files under `.planning/` in its **non-blocking** tier — that is expected
for these four files, not a hit to clear; `18-06`'s and `18-20`'s executors must not treat them
as retirement debris.

**A tool-completeness finding, recorded here because it changes how one section of this document
was derived (Rule 1 — bug, found and worked around, not fixed in this plan, which touches no
code per its own scope boundary):** `waybar-equivalence-check --resolve`'s definition of
"effective config" only counts a module as *used* — and therefore keeps its definition in the
resolved output — when that module's name appears directly in `modules-left`/`modules-center`/
`modules-right`, or when the layout file redefines it itself (see the script's own comment at
lines 174-210). It does **not** walk a group's own `modules` array. Athena's `group/settings`
lists `custom/theme`, `custom/waybar-layout`, `custom/font`, `custom/icon-theme` and
`custom/wallpaper` — none of which `config-athena.jsonc` redefines directly — so all five are
silently absent from `18-waybar-resolved/athena.json`, even though waybar genuinely instantiates
them (waybar looks up a group member's definition by name through the same `include` chain as
any other module reference). This is *not* a hard-stop under the dead-definition rule below
(that rule fires on a zone-referenced name missing from the resolved snapshot; this is a
group-referenced name), and it is not evidence the resolver is broken for its stated purpose
(equivalence-diffing full effective configs against a baseline) — it is a narrower gap in what
counts as "used" for group members specifically. Where this document needed one of those five
entries' resolved content, it was sourced instead from a **verified-equivalent** re-resolution:
`modules.jsonc` was probed directly (`{"include": ["modules.jsonc"], "modules-left": [<name>]}`,
run through the same `--resolve` mechanism) to force the module into the tool's own `used` set,
and every value used here was cross-checked byte-identical (`jq -S` diff, zero output) against
that probe. The document marks each such row `(source: modules.jsonc canonical, not present in
athena.json — see this note)` so the substitution is auditable, not silent.

## Not a Port Specification

This document records what the four retired layouts did, so that nothing already built is lost
by accident when their sources are deleted. It neither licenses nor mandates reproducing *how*
the bar looked or *where* it sat. `REQUIREMENTS.md` § Out of Scope rules out pixel-for-pixel
ports of the migrated surfaces, and `PROJECT.md` frames v4.0 as a redesign against the
end-4/Caelestia reference language, not a port — a later executor reading this document as a
compliance checklist would silently invert both.

**The concrete trap is `config-vertical.jsonc`'s anchor.** Its bar-level chrome is
`"position": "left"` with `"width": 44` and every margin at `0` — a column flush to the
**left** screen edge. The replacement's vertical orientation is deliberately the **right**
screen edge, with drawers expanding inward over the desktop (D-18-11). A reader who takes the
`WB-VERT-*` rows below as licence to anchor the new vertical column on the left would build the
wrong bar. Every criterion in this document describes a **capability** the user had — a
readout existing, a click doing something, a drawer revealing on hover — never the **position,
pixel, colour, or transition duration** they had it at. Where a row's own content happens to be
a number (a drawer's `transition-duration`, a column's `width`), that number is the *retired*
value for the record, not a target the replacement must hit.

## Criterion Grammar

Every row in every `## Layout Criteria — *` table below obeys these rules, so that a second
author working from the same source files would produce the same rows.

- **ID namespace.** `WB-<LAYOUT>-NN`, with `LAYOUT` one of `ATH`, `FULL`, `FLOAT`, `VERT`, or
  `ALL` for a row shared by every layout that references the module. IDs are stable once
  written and are cited by `18-19` (GATE-02's blocking pass) and `18-20` (post-deletion
  verification) — a row is never renumbered; a row later found to be wrong is struck with its ID
  retained, not reassigned.
- **Row shape.** Columns: ID · Zone·Index · Module · Checkable criterion · Layouts · GATE-02 B.
  The criterion column is a gesture-and-observation sentence — what a human does, and what they
  then observe. A restatement of a config key ("format is X") is not a criterion. Where a
  behaviour has no gesture (a polling interval, a tooltip's exact text), it is expressed as a
  timing or hover observation a human can still take ("wait N seconds, the value updates" /
  "hover, the tooltip reads X").
- **Merge rule.** Two or more layouts collapse into **one row**, `LAYOUT = ALL`, if and only if
  their resolved entries for that module are byte-identical (`jq -S`, zero diff) across the
  committed snapshots. Any difference in any resolved key — however small — yields **separate**
  rows, one per differing layout, and the separated rows' criterion text names the differing
  key. Comparison is always against `18-waybar-resolved/*.json`, never the raw `.jsonc` — the
  first-defined-wins `include` chain lets a layout override one nested key without restating the
  whole object, and only the resolved output shows the true result. A merged row is written
  **once**, physically placed under the first layout section (in the fixed layout sequence
  below) that references it, and is not repeated verbatim in the later layout's own section —
  its `Layouts` column names every layout it covers, and that is what a downstream reader greps
  for the module name to find it regardless of which section it physically sits in.
- **Ordering rule.** Rows are ordered: layout in the fixed sequence athena → full → floating →
  vertical → shared; then zone in the fixed sequence left → center → right; then the entry's
  index within that zone array as it appears in the resolved snapshot; then, for a member inside
  a group, the group's own `modules` array index. A merged (`ALL`) row is placed at the position
  of the first layout in the fixed sequence that references it. Every tiebreak resolves to a
  source-declared index, so re-deriving this document from the same inputs produces the same row
  order.
- **Dead-definition rule.** A module present in a layout's resolved snapshot but referenced by
  **zero** zone arrays and **zero** group `modules` arrays is a dead definition — it is recorded
  in `## Dead Definitions`, never in a criteria table. A module referenced by a zone array but
  **absent** from the resolved snapshot is a hard stop: it means the resolution is wrong and
  every criterion derived from that snapshot is untrustworthy (this did not occur — see the
  Provenance tool-completeness note above for the one related, non-hard-stop gap that did).
- **Absence rule.** An empty zone array is written down as a stated absence for that layout, not
  omitted. A group with exactly one member still earns a criterion row, because a one-member
  drawer still has a transition duration and a direction (no layout in this document actually has
  a single-member group — every group here has 2 or more members — so this rule is stated for
  completeness and has no live instance below).

## Bar-Level Chrome

Non-module top-level keys, per layout. Two rows carry behaviour that outlives waybar itself and
are written as criteria, not trivia: the fixed-signal contract from `bar-common.jsonc`, and
`config-vertical.jsonc`'s deliberately absent `output` key.

| Key | athena | full | floating | vertical |
|---|---|---|---|---|
| `layer` | `top` | `top` | `top` | `top` |
| `position` | `top` | `top` | `top` | `left` |
| `height` / `width` | height `40` | height `40` | *(absent — waybar default)* | width `44` |
| `margin-top` | `6` | `6` | *(absent — waybar default, i.e. `0`)* | `0` |
| `margin-left` | `10` | `10` | *(absent)* | `0` |
| `margin-right` | `10` | `10` | *(absent)* | *(absent — no `margin-right` key at all)* |
| `margin-bottom` | *(absent)* | *(absent)* | *(absent)* | `0` |
| `spacing` | `0` | `0` | `"4"` (string, not numeric — preserved verbatim) | `0` |
| `on-sigusr1` | `hide` | `hide` | `hide` | `hide` |
| `on-sigusr2` | `reload` | `reload` | `reload` | `reload` |
| `output` | *(absent — draws on every monitor)* | *(absent)* | *(absent)* | *(absent — see row below)* |

- **BLC-01 — fixed signal contract.** *Criterion:* send `SIGUSR1` to the running
  waybar process (any layout) — the bar hides and stays hidden (never toggling back visible on
  a second `SIGUSR1`, since the action is fixed to `hide`, not waybar's default alternating
  behaviour). Send `SIGUSR2` — the bar reloads and returns to its config-time visible state.
  Source: `bar-common.jsonc`, included by all four layouts, D-03's fixed-signal contract. This
  is the actuation seam D-18-27 replaces with `qs ipc call` in the new bar. **Layouts: athena,
  full, floating, vertical. GATE-02 B: not directly a B row (infrastructure, not a user-visible
  readout) — carried forward by D-18-27/D-18-38, not re-verified here.**
- **BLC-02 — no per-output restriction.** *Criterion:* with two or more monitors
  connected, `config-vertical.jsonc` draws its column on **every** connected monitor, not just
  one — there is no `output` key anywhere in the file to restrict it. Source: the file's own
  comment at lines 15-16, citing D-15. **Layouts: vertical. GATE-02 B: not a B row (bar-level
  chrome, not a readout); relevant context for any future multi-monitor criterion, out of this
  plan's scope per D-13 (QS-03 permanently dropped).**
- **`floating`'s missing height/margin keys** are not a finding requiring its own row — they are
  the bar-level-chrome equivalent of an absence rule instance: `config-floating.jsonc` declares
  no `height`, `margin-top`, `margin-left` or `margin-right` at all, so waybar's own compiled-in
  defaults apply. Recorded here as the explicit stated absence the grammar's absence rule
  requires; not a criterion because there is no observable user behaviour distinct from "waybar's
  default," which this document does not own.

## Layout Criteria — athena

Athena is the design lineage (`config-athena.jsonc`'s own header cites
`github.com/haikal-hakim/athena`) and, per D-18-32, the GATE-02 **aesthetic** comparison
baseline. Its capabilities are enumerated in full below regardless of aesthetic-vs-capability
split, because this document's completeness is asserted per-layout, not per-GATE-02-half.

### Zone: modules-left — `["group/apps", "group/storage", "group/system", "custom/updates"]`

| ID | Zone·Index | Module | Checkable criterion | Layouts | GATE-02 B |
|---|---|---|---|---|---|
| WB-ATH-01 | left·0 (drawer) | `group/apps` | Hover the collapsed apps-drawer glyph — within ~500ms the drawer expands **left-to-right**, revealing 8 launcher icons in a row; move the pointer away — it collapses back over the same ~500ms. `transition-duration: 500`, `transition-left-to-right: true`. | athena | not a B row (D-18-01 carries the drawer forward; capability, not a full/floating/vertical parity item) |
| WB-ATH-02 | left·0.0 | `custom/app-launcher` | With the drawer open, click the leftmost (collapsed-state) icon — the app-launcher drawer itself toggles open/closed (`tooltip: false`, no distinct tooltip text). | athena | not a B row |
| WB-ATH-03 | left·0.1 | `custom/app-zen` | With the drawer open, hover the second icon — tooltip reads "Zen Browser"; click it — `uwsm app -- zen.desktop` launches Zen. | athena | not a B row |
| WB-ATH-04 | left·0.2 | `custom/app-spotify` | Hover the third icon — tooltip reads "Spotify"; click it — `uwsm app -- spotify.desktop` launches Spotify. | athena | not a B row |
| WB-ATH-05 | left·0.3 | `custom/app-discord` | Hover the fourth icon — tooltip reads "Discord"; click it — `uwsm app -- discord.desktop` launches Discord. | athena | not a B row |
| WB-ATH-06 | left·0.4 | `custom/app-steam` | Hover the fifth icon — tooltip reads "Steam"; click it — `uwsm app -- steam.desktop` launches Steam. | athena | not a B row |
| WB-ATH-07 | left·0.5 | `custom/app-lutris` | Hover the sixth icon — tooltip reads "Lutris"; click it — `uwsm app -- net.lutris.Lutris.desktop` launches Lutris. | athena | not a B row |
| WB-ATH-08 | left·0.6 | `custom/app-obsidian` | Hover the seventh icon — tooltip reads "Obsidian"; click it — `uwsm app -- obsidian.desktop` launches Obsidian. | athena | not a B row |
| WB-ATH-09 | left·0.7 | `custom/app-codium` | Hover the eighth (rightmost) icon — tooltip reads "VSCodium"; click it — `uwsm app -- codium.desktop` launches VSCodium. | athena | not a B row |
| — | left·1 | `group/storage` | No `drawer` object exists for this group — both members render simultaneously, always visible, with no hover-reveal/collapse animation. Named explicitly so its absence is a stated fact, not an omission. | athena | not a B row |
| WB-ATH-10 | left·1.0 | `disk` | At rest the disk pill shows only a glyph (no text); click it — the pill switches to `format-alt`, showing the used-space value inline (`<span size='11pt'>{used}</span>`); click again — it reverts to glyph-only. | athena | B.1 (`cpu/ram/disk` readout) |
| WB-ATH-11 | left·1.1 | `memory` | At rest the memory pill shows only a glyph; click it — it switches to `format-alt`, showing `{used:.1f}G` inline; click again — it reverts. This is athena's own redefinition, distinct from every other layout's `memory` module (all four differ). | athena | B.1 |
| — | left·2 | `group/system` | No `drawer` object exists for this group either — both members always visible, no reveal animation. | athena | not a B row |
| WB-ATH-12 | left·2.0 | `temperature` | At rest the temperature pill shows only a 3-step thermometer glyph (`format-icons` has 3 entries, not 5); click it — `format-alt` shows `{temperatureC}°C` inline; click again — it reverts. Distinct from `full`'s and `vertical`'s own `temperature` (all three differ; `floating` has no `temperature` module at all). | athena | B.1 |
| WB-ATH-13 | left·2.1 | `cpu` | At rest the CPU pill shows only a glyph; click it — `format-alt` shows `{usage}%` inline; click again — it reverts. Distinct from every other layout's `cpu` (all four differ). | athena | B.1 |
| WB-ATH-14 | left·3 | `custom/updates` | With `checkupdates` reporting 0 pending packages, this pill renders **nothing** (`exec-if: "[ $(checkupdates 2>/dev/null \| wc -l) -gt 0 ]"`) — it is not present on the bar at all. With 1+ pending, it shows `󰚰 {count}`; hover — tooltip reads "`{count}` update(s) available"; click it — `kitty -e paru -Syu` opens an update terminal. Polls every 900s. Verbatim: `exec`: `checkupdates \| wc -l`. | athena | not a B row (athena-only extra, D-18-03) |

### Zone: modules-center — `["hyprland/workspaces", "idle_inhibitor"]`

| ID | Zone·Index | Module | Checkable criterion | Layouts | GATE-02 B |
|---|---|---|---|---|---|
| WB-ATH-15 | center·0 | `hyprland/workspaces` | Each occupied workspace renders as `{icon} {windows}` — a workspace glyph (active/default/urgent/empty state icons) followed by one live per-app window icon per open window on that workspace, drawn from a 12-entry `window-rewrite` map (kitty, firefox, zen, codium, discord, spotify, obsidian, lutris, steam, thunar, yazi all have named glyphs; anything unmapped falls back to `window-rewrite-default` — a ghost glyph, `󰊠`). The config carries `"on-click": "activate"`, but clicking a workspace does **not** switch to it — this dispatch is compiled into waybar 0.15.0's own C++ (`Workspace::handleClicked`) as the legacy string `dispatch workspace <id>`, which a Lua-config-managed Hyprland rejects at parse time; waybar discards the failed IPC reply and the click is silently dead (documented verbatim in `config-floating.jsonc`'s own comment, which further states this cannot be fixed from config and needs upstream waybar PR #5013, postdating 0.15.0). This same C++ code path renders every layout's `hyprland/workspaces` click identically, so the dead click applies to athena too, not just to full/floating/vertical. `persistent-workspaces: {"*": 5}` — workspaces 1-5 always render even with zero windows. Distinct from every other layout's `hyprland/workspaces` (all four differ; `full` and `vertical` are the only pair that merge). | athena | B.2 (click-to-switch is exactly the dead capability QBAR-03 exists to fix) |
| WB-ATH-16 | center·1 | `idle_inhibitor` | Click the idle-inhibitor glyph — it toggles between `󰛨` (activated, tooltip "System Focused") and `󰛩` (deactivated, tooltip "Normal Mode"). Present **only** in athena — no other layout references `idle_inhibitor` at all. | athena | not a B row (athena-only extra) |

### Zone: modules-right — `["custom/media", "group/audio", "group/connections", "clock", "custom/gaming-mode", "custom/notification", "group/settings", "custom/power"]`

| ID | Zone·Index | Module | Checkable criterion | Layouts | GATE-02 B |
|---|---|---|---|---|---|
| WB-ALL-01 | right·0 | `custom/media` | Shows the current MPRIS track title (`{icon} {}`, spotify gets its own glyph, everything else the default note glyph); click it — `ags request -i media toggle-media` opens the AGS media card (Phase 21 retires this binding — folded into the dashboard Media tab, D-18-05). Scroll up/down — `playerctl next`/`playerctl previous`. Polls every 30s via `media-player.py`. Verbatim `exec`: `python ~/.config/hypr/scripts/media-player.py 2> /dev/null`. Byte-identical between athena and floating. | athena, floating | B.1 (now-playing readout) |
| WB-ATH-17 | right·1 (drawer) | `group/audio` | Hover the collapsed audio glyph — within ~650ms the drawer expands, growing **right-to-left** (`transition-left-to-right: false`), revealing the mute toggle, a volume slider, and a mic-mute toggle. `transition-duration: 650`. Distinct direction and duration from `group/apps` (500ms, left-to-right) and from vertical's own `group/audio` (400ms, vertical orientation, left-to-right — covered in the vertical section below). | athena | not a B row (drawer mechanics; the audio capability itself is B.1/B.3) |
| WB-ATH-18 | right·1.0 | `pulseaudio` | Click the speaker glyph — `wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle` mutes/unmutes; right-click — `qs ipc call panel toggle audio` opens the shell-root audio panel (15-08 rewiring). Hover — tooltip reads "Output: `{volume}`%". Distinct from every other layout's `pulseaudio` (all four differ). | athena | B.1 (audio readout) |
| WB-ATH-19 | right·1.1 | `pulseaudio/slider` | Drag the horizontal slider revealed by the drawer — output volume changes live, range 0-100. `orientation: horizontal` (contrast vertical's own vertically-oriented slider, covered in the vertical section below). | athena | B.3 (scroll/adjust audio — this is drag, not scroll, but the same capability class) |
| WB-ATH-20 | right·1.2 | `pulseaudio#microphone` | Renders the microphone's mute-state icon only (`{format_source}`, no numeric value) — present **only** in athena; no other layout has a `pulseaudio#microphone` entry anywhere. | athena | not a B row (athena-only extra) |
| WB-ATH-21 | right·2 (drawer) | `group/connections` | Hover the collapsed connections glyph — within ~500ms the drawer expands right-to-left, revealing network and bluetooth icons. `transition-duration: 500`, `transition-left-to-right: false`. | athena | not a B row (drawer mechanics) |
| WB-ATH-22 | right·2.0 | `network` | Wifi connected: shows a 5-step signal-strength glyph (`format-icons`, weakest to strongest); ethernet: shows a distinct ethernet glyph (`󰈀`); disconnected: shows `󰤮`; disabled: shows `󰖪`. Hover while on wifi — tooltip reads `{essid}` + signal % + frequency + up/down bandwidth. Click — `qs ipc call panel toggle wifi` opens the shell-root wifi panel (15-08 rewiring; the old tray-applet click this replaced had been dead since athena's tray removal). Distinct from every other layout's `network` (all four differ). | athena | B.1 (network readout) |
| WB-ATH-23 | right·2.1 | `bluetooth` | Disconnected: shows `󰂯`; connected: shows `󰂱`; radio disabled: shows `󰂲`. Hover while connected — tooltip lists each connected device and, where the device reports one, its battery %. Click — `qs ipc call panel toggle bluetooth` opens the shell-root bluetooth panel; right-click — `rfkill toggle bluetooth` toggles the radio. **Present only in athena — `full`, `floating` and `vertical` never reference `bluetooth` at all**, despite UI-SPEC's B.1 listing bluetooth among "the three retired layouts collectively exposed" (see the GATE-02 Criterion B Index's B.1 note in the extension of this document for the correction). | athena | B.1 (see correction note — bluetooth is athena-sourced, not full/floating/vertical-sourced) |
| WB-ALL-02 | right·3 | `clock` | Shows `{:%H:%M}` inline (e.g. "14:32" with a clock glyph); click — switches to `format-alt`, the full date (`{:%A, %B %d, %Y}`); click again — reverts. Right-click — `mode` (same alt-toggle via the `actions` block). Scroll up/down over the clock — `shift_up`/`shift_down` the calendar month shown in the hover tooltip. Hover — tooltip shows a full month calendar (`{calendar}`) for the current month. Byte-identical between athena and full — both use the shared `modules.jsonc` definition unmodified. | athena, full | B.1 (clock readout) |
| WB-ALL-03 | right·4 | `custom/gaming-mode` | With `~/.cache/gaming-mode` containing `on`, shows the "controller-on" glyph (`󰊴`, tooltip "Gaming Mode: ON"); with any other content (including missing), shows the "controller-off" glyph (`󰊵`, tooltip "Gaming Mode: OFF") — fails safe to OFF. Click — `~/.config/hypr/scripts/gaming-mode-toggle.sh` toggles the state file. Polls the file every 2s. Byte-identical across **all four** layouts — none of them override this module. | athena, full, floating, vertical | not a B row (not one of B.1's named readouts, but present everywhere so its parity is de facto load-bearing) |
| WB-ALL-04 | right·5 | `custom/notification` | Unread notifications present: shows a bell-with-badge glyph (`format-icons`, 8 states crossing notification/none × dnd/normal × inhibited/normal) plus the unread count (`{icon} {text}`); no unread: shows a plain bell. Click — `swaync-client -t -sw` toggles swaync's control centre open/closed. Right-click — `swaync-client -d -sw` toggles do-not-disturb. Reads live via `swaync-client -swb` (`exec-if: "which swaync-client"` — module renders nothing if swaync isn't installed). Byte-identical across athena, full and floating (vertical's own version differs — glyph-only, no count text — covered in the vertical section below). Verbatim `exec`: `swaync-client -swb`. Phase 19 rewires what is behind this click without touching the layout (D-18-33). | athena, full, floating | not a B row (bell readout isn't one of B.1's named six, but the swaync-wiring capability is what D-18-33 explicitly carries forward) |
| WB-ATH-24 | right·6 (drawer) | `group/settings` | Hover the collapsed gear glyph (`custom/settings`, `` U+F013) — within ~500ms the drawer expands right-to-left, revealing 5 switcher icons (theme, waybar-layout, font, icon-theme, wallpaper) plus the gear itself. `transition-duration: 500`, `transition-left-to-right: false`. This is the 08-16-checkpoint settings drawer that replaced the original tray-folded settings buttons (see the file's own header comment). | athena | not a B row (drawer mechanics; D-18-01 carries this drawer forward by name) |
| WB-ATH-25 | right·6.0 | `custom/settings` | Click the collapsed gear glyph itself — toggles the `group/settings` drawer open/closed (`tooltip: false`). Athena's own definition (not in `modules.jsonc`; no other layout references it). | athena | not a B row |
| WB-ALL-05 | right·6.1 | `custom/theme` *(source: `modules.jsonc` canonical, not present in `athena.json` — see the Provenance tool-completeness note)* | With the drawer open, hover the half-filled-circle icon — tooltip reads "Switch Theme"; click it — `~/.config/hypr/scripts/theme-switch.sh` opens the theme picker. Byte-identical (verified via a forced re-resolve probe, `jq -S` zero-diff) between athena's group-referenced use and full's direct `modules-right` use. | athena, full | not a B row (theme-switch capability, not one of B.1-6's named items — carried forward structurally by D-18-30's settings-drawer redesign) |
| WB-ALL-06 | right·6.2 | `custom/waybar-layout` *(source: `modules.jsonc` canonical, not present in `athena.json` — see the Provenance tool-completeness note)* | With the drawer open, hover the grid icon — tooltip reads "Switch Waybar Layout"; click it — `~/.config/hypr/scripts/waybar-switch.sh` opens the four-layout picker. Byte-identical between athena's group-referenced use and full's direct use. **D-18-30 explicitly repurposes this exact discoverable path into the new bar's horizontal/vertical orientation toggle** — this criterion is what that decision is preserving continuity with. | athena, full | not a B row (D-18-30 names this specific UX path as the one being repurposed, not dropped) |
| WB-ATH-26 | right·6.3 | `custom/font` *(source: `modules.jsonc` canonical, not present in `athena.json`)* | With the drawer open, hover the font icon — tooltip reads "Change Font"; click it — `~/.config/hypr/scripts/font-switch.sh` opens the font picker. Referenced only by athena (no other layout lists `custom/font` in any zone or group). | athena | not a B row (athena-only extra) |
| WB-ATH-27 | right·6.4 | `custom/icon-theme` *(source: `modules.jsonc` canonical, not present in `athena.json`)* | With the drawer open, hover the paintbrush icon — tooltip reads "Change Icons"; click it — `~/.config/hypr/scripts/icon-theme-switch.sh` opens the icon-theme picker. Referenced only by athena. | athena | not a B row (athena-only extra) |
| WB-ALL-07 | right·6.5 | `custom/wallpaper` | With the drawer open, hover the picture-frame icon — click it — `bash ~/.config/hypr/scripts/wallpaper-switch.sh` opens the wallpaper picker. Byte-identical between athena's group-referenced canonical use and floating's own (redundant but matching) direct redefinition. | athena, floating | not a B row |
| WB-ALL-08 | right·7 | `custom/power` | Click the power glyph — `~/.config/hypr/scripts/wleave.sh` opens the wleave power menu. Hover — tooltip reads "Power Menu". Byte-identical across athena, full and vertical (floating's own version differs — no tooltip-format, a `bash ` prefix on the same script path, and a different glyph escape — covered in the floating section below). Phase 20 replaces what `wleave.sh` opens with the new QML power menu, unaffected by this layout binding. | athena, full, vertical | B.1 is silent on power specifically, but the click-opens-power-menu capability is carried forward structurally by QPOWER-01..04 |

Athena zone-entry count: 14 (4 left + 2 center + 8 right, matching the interface context's
recorded count exactly). Expanded row count (every group member as its own row): 35.

## Layout Criteria — full

`config-full.jsonc` is the plainest of the four — 15 zone-array entries, no groups, almost every
module inherited unmodified from `modules.jsonc`. Rows already merged into the athena section
above (`clock`, `custom/gaming-mode`, `custom/notification`, `custom/theme`,
`custom/waybar-layout`, `custom/power`) are not repeated here — see that section for their text;
their `Layouts` column already names `full`.

### Zone: modules-left — `["hyprland/workspaces", "hyprland/window"]`

| ID | Zone·Index | Module | Checkable criterion | Layouts | GATE-02 B |
|---|---|---|---|---|---|
| WB-ALL-09 | left·0 | `hyprland/workspaces` | Each workspace renders as a bare numeral 1-9 (`format-icons`: `"1"`..`"9"` plus distinct `active`/`urgent` glyphs, `default` empty) — no per-app window icons, unlike athena. `persistent-workspaces: {"*": 5}`. The config carries `"on-click": "activate"`, but the click is dead for the same compiled-in-C++ reason documented on athena's own entry above — full's own comment does not repeat the explanation, but the same waybar binary renders this click identically. Byte-identical between full and vertical (both use the unmodified `modules.jsonc` definition). | full, vertical | B.2 (dead click, same as every other layout's) |
| WB-FULL-01 | left·1 | `hyprland/window` | Shows the focused window's title inline (`{}`, capped at 40 chars), independently per output (`separate-outputs: true`). Referenced **only** by `full` — no other layout lists `hyprland/window` in any zone. D-18-07 explicitly drops a focused-window-title entry from the replacement bar, citing this exact module as the capability being deliberately not carried forward (variable-width text is "the worst element for a bar that must not reflow"). | full | not a B row (D-18-07 names this the one capability deliberately not ported) |

### Zone: modules-center — `["mpris", "clock"]`

| ID | Zone·Index | Module | Checkable criterion | Layouts | GATE-02 B |
|---|---|---|---|---|---|
| WB-FULL-02 | center·0 | `mpris` | Shows `{player_icon}  {artist} — {title}` for the active MPRIS player (paused shows a pause glyph in the same position); no player: renders nothing (`format-stopped: ""`). Click — `ags request -i media toggle-media` opens the AGS media card. Right-click — `playerctl next`. Scroll up/down — `playerctl volume 0.05+`/`0.05-`. Hover — tooltip shows player/status/position/length only (no attacker-controlled metadata, WR-03). Distinct from vertical's own `mpris` (glyph-only, no track text) — the two do not merge. Note: waybar's built-in `mpris` module (this one) is a *different* now-playing surface from `custom/media` (the athena+floating merged row above, a Python-script-backed module) — the four layouts are split 2-and-2 between the two mechanisms, both pointing at the same `ags request -i media toggle-media` click. | full | not literally named in B.1's readout list (B.1 lists clock/battery/network/bluetooth/audio/cpu·ram·disk — media/now-playing is a real, universally-present capability across all four layouts under one of two mechanisms, but is not one of B.1's six named items; see the GATE-02 Criterion B Index note below) |
| — | center·1 | `clock` | Covered above — merged into the athena section's entry (`Layouts: athena, full`). | full | B.1 |

### Zone: modules-right — `["cpu", "memory", "temperature", "pulseaudio", "network", "custom/theme", "custom/waybar-layout", "tray", "custom/gaming-mode", "custom/notification", "custom/power"]`

| ID | Zone·Index | Module | Checkable criterion | Layouts | GATE-02 B |
|---|---|---|---|---|---|
| WB-FULL-03 | right·0 | `cpu` | Shows a microchip glyph + `{usage}%` inline; polls every 2s; hover shows a tooltip (`tooltip: true`, default numeric tooltip). Distinct from every other layout's `cpu`. | full | B.1 |
| WB-FULL-04 | right·1 | `memory` | Shows a glyph + `{percentage}%` inline; polls every 5s; hover — tooltip reads `{used:.1f}G / {total:.1f}G`. Distinct from every other layout's `memory`. | full | B.1 |
| WB-FULL-05 | right·2 | `temperature` | Shows `{icon} {temperatureC}°C` inline (icon + numeric value together, unlike athena's click-to-reveal split); 5-step thermometer ramp; `critical-threshold: 80`; hover enabled (`tooltip: true`). Distinct from athena's and vertical's own `temperature`; absent entirely from `floating`. | full | B.1 (arguable — B.1 literally names "cpu/ram/disk", not a thermal sensor; recorded present regardless since the capability exists) |
| WB-FULL-06 | right·3 | `pulseaudio` | Shows `{icon}  {volume}%` inline; muted shows " muted" text appended. Click — `wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle`. Right-click — `qs ipc call panel toggle audio`. No scroll handler and no `scroll-step` key — scrolling over this module does **not** adjust volume on `full` (contrast `floating`'s `scroll-step: 5`, below). Distinct from every other layout's `pulseaudio`. | full | B.1 (readout); **not** B.3 (no scroll-to-adjust on this layout) |
| WB-FULL-07 | right·4 | `network` | Wifi: `{icon} {signalStrength}%`; ethernet: `9 {ifname}` (glyph escape); disconnected: `e offline` (glyph escape). Hover — tooltip shows `{ifname}: {ipaddr}/{cidr}` + `{essid}`. Click — `qs ipc call panel toggle wifi`. Distinct from every other layout's `network`. | full | B.1 |
| — | right·5 | `custom/theme` | Covered above — merged into the athena section's entry (`Layouts: athena, full`). | full | not a B row |
| — | right·6 | `custom/waybar-layout` | Covered above — merged into the athena section's entry (`Layouts: athena, full`). | full | not a B row |
| WB-ALL-10 | right·7 | `tray` | Renders every registered `StatusNotifierItem` icon at `icon-size: 18` with `spacing: 8` between icons; click an icon — its own context menu opens (native waybar/DBusMenu behaviour, no config override). Byte-identical between full and vertical (both use the unmodified `modules.jsonc` definition, `icon-size: 18`/`spacing: 8`). Distinct from athena's own `tray` (icon-size 16 — and, per the Dead Definitions table below, athena's `tray` is a dead definition never actually placed on the bar) and from floating's own `tray` (`icon-theme: Papirus-Dark` override, `spacing: 10`). | full, vertical | B.5 (tray icons render, menus open on click) |
| — | right·8 | `custom/gaming-mode` | Covered above — merged into the athena section's entry (`Layouts: athena, full, floating, vertical`). | full | not a B row |
| — | right·9 | `custom/notification` | Covered above — merged into the athena section's entry (`Layouts: athena, full, floating`). | full | not a B row |
| — | right·10 | `custom/power` | Covered above — merged into the athena section's entry (`Layouts: athena, full, vertical`). | full | not literally a B item |

Full zone-entry count: 15 (2 left + 2 center + 11 right, matching the interface context's
recorded count exactly).

## Layout Criteria — floating

`config-floating.jsonc` is the layout carrying the two highest-value findings surfaced during
this enumeration: a live scroll-to-switch-workspace binding QBAR-03 does not mention, and a
brightness-scroll binding that is already dead today for want of installed hardware/software
(the evidence D-18-39's verdict rests on). Rows already merged into the athena section above
(`custom/media`, `custom/gaming-mode`, `custom/notification`, `custom/wallpaper`) are not
repeated here.

### Zone: modules-left — `["custom/launcher", "cpu", "memory", "custom/media", "tray"]`

| ID | Zone·Index | Module | Checkable criterion | Layouts | GATE-02 B |
|---|---|---|---|---|---|
| WB-FLOAT-01 | left·0 | `custom/launcher` | Click the rocket glyph — `walker` launches the app launcher. Right-click — `killall walker` force-kills it. Referenced **only** by `floating`. | floating | not a B row (launcher opener, not one of B.1-6) |
| WB-FLOAT-02 | left·1 | `cpu` | Shows a glyph + `{}%` inline (no explicit `format-icons`, just the bare glyph in `format`); polls every 15s (the slowest CPU poll of any layout); `max-length: 10`. Distinct from every other layout's `cpu`. | floating | B.1 |
| WB-FLOAT-03 | left·2 | `memory` | Shows a glyph + `{}%` inline; polls every 30s (the slowest memory poll of any layout); `max-length: 10`. Distinct from every other layout's `memory`. | floating | B.1 |
| — | left·3 | `custom/media` | Covered above — merged into the athena section's entry (`Layouts: athena, floating`). | floating | not literally a B.1 item (see the GATE-02 Criterion B Index note) |
| WB-FLOAT-04 | left·4 | `tray` | Renders every tray icon at `icon-size: 18`, `icon-theme: Papirus-Dark` (the only layout that pins an explicit icon theme for tray icons), `spacing: 10`. Distinct from every other layout's `tray`. | floating | B.5 |

### Zone: modules-center — `["hyprland/workspaces"]`

| ID | Zone·Index | Module | Checkable criterion | Layouts | GATE-02 B |
|---|---|---|---|---|---|
| WB-FLOAT-05 | center·0 | `hyprland/workspaces` | Bare numerals 1-9 (`format-icons`: `"1"`..`"9"`, no active/urgent override); `persistent-workspaces: {"*": 6}` (six persistent slots, not five). Click — `activate` — dead, same compiled-in-C++ reason as every other layout (this file's own comment, lines 109-125, is the source of that finding, cited on the athena and full/vertical entries above). **The scroll handlers are different: they are shell-command strings, not a compiled dispatch, so they work.** Scroll up over the workspace row — `hyprctl dispatch 'hl.dsp.focus({workspace="e+1"})'` switches to the next workspace. Scroll down — the `e-1` equivalent switches to the previous one. **This is a live capability QBAR-03's own text does not mention** (QBAR-03 is framed as click-to-switch); UI-SPEC's GATE-02 B.3 only names audio/brightness scroll, not workspace scroll. No plan in this phase currently names a replacement owner for scroll-to-switch-workspace on the new bar — flagged explicitly in the GATE-02 Criterion B Index below as an unassigned capability. Verbatim: `hyprctl dispatch 'hl.dsp.focus({workspace="e+1"})'`. | floating | B.2 (click is dead, same as everywhere) — **and** an unassigned scroll capability not covered by any B row as written |

### Zone: modules-right — `["custom/updates", "custom/wallpaper", "network", "pulseaudio", "clock", "backlight", "battery", "custom/gaming-mode", "custom/notification", "custom/power"]`

| ID | Zone·Index | Module | Checkable criterion | Layouts | GATE-02 B |
|---|---|---|---|---|---|
| WB-FLOAT-06 | right·0 | `custom/updates` | With 0 pending packages, this pill renders nothing (`exec-if: "[[ $(checkupdates \| wc -l) != 0 ]]"`). With 1+, shows `{count} Update(s)` (verbose text form, unlike athena's glyph-first form). Polls every 15s (athena polls every 900s — a 60x faster poll on this layout). Click — `kitty -e paru -Syu && notify-send 'The system has been updated'` (this layout also fires a completion notification; athena's does not). Distinct from athena's own `custom/updates`. Verbatim: `checkupdates \| wc -l`. | floating | not a B row |
| — | right·1 | `custom/wallpaper` | Covered above — merged into the athena section's entry (`Layouts: athena, floating`). | floating | not a B row |
| WB-FLOAT-07 | right·2 | `network` | Shows `{essid} ({signalStrength}%) {icon}` on wifi (text-first, glyph last — the only layout ordering it this way); ethernet: `{bandwidthTotalBytes} 󰍹`; disconnected: `󰤮`. Hover — tooltip reads `{ifname}` inline, `{bandwidthUpBytes}`/`{bandwidthDownBytes}` on wifi/ethernet, "Disconnected!" when down. Click — `qs ipc call panel toggle wifi`. Distinct from every other layout's `network`. | floating | B.1 |
| WB-FLOAT-08 | right·3 | `pulseaudio` | Shows `{icon} {volume}%` inline (muted keeps the same format string — no distinct muted glyph). Click — `pactl set-sink-mute @DEFAULT_SINK@ toggle` (this layout's own divergent `pactl` spelling, not `wpctl` like every other layout). Right-click — `qs ipc call panel toggle audio`. **`scroll-step: 5` — scrolling up/down over this module raises/lowers output volume by 5 percentage points per notch**, waybar's native pulseaudio scroll-to-adjust behaviour. This is `config-floating.jsonc`'s own scroll-audio parity for GATE-02 B.3. Distinct from every other layout's `pulseaudio`. | floating | B.1 **and** B.3 (scroll-to-adjust volume, the direct precedent B.3 is checked against) |
| WB-FLOAT-09 | right·4 | `clock` | Shows `{:%d %B  %I:%M%p}` inline (day, month name, glyph, 12-hour time — the only 12-hour clock among the four layouts). Click — `format-alt` shows `{:%d/%m/%Y  %T}`; click again reverts. Polls every 1s (the only clock with an explicit fast interval). Hover — tooltip shows a month calendar. Distinct from athena/full's shared clock and from vertical's own clock. | floating | B.1 |
| — | right·5 | `backlight` | **Dead definition, not a criterion — see `## Dead Definitions` below.** Referenced by this zone array (`modules-right`), unlike the other two dead-definition entries in this document, but its scroll behaviour is a no-op on this host (D-18-39: `light` binary not installed, `/sys/class/backlight/` empty). | floating | B.3 (not demonstrable on this hardware — structurally present; see D-18-39 and the Dead Definitions entry) |
| WB-FLOAT-10 | right·6 | `battery` | Shows `{icon}  {capacity}%` (glyph + percentage, unlike vertical's glyph-only form); charging/plugged both show a plug glyph variant; click — `format-alt` shows `{time} {icon}`. 5-state battery-level glyph ramp, `good`/`warning`/`critical` thresholds at 95/30/20. Distinct from vertical's own `battery`. | floating | B.1 (battery "when present" — this desktop has none, D-18-06's same precedent; the module itself renders nothing on this host regardless of layout) |
| — | right·7 | `custom/gaming-mode` | Covered above — merged into the athena section's entry (`Layouts: athena, full, floating, vertical`). | floating | not a B row |
| — | right·8 | `custom/notification` | Covered above — merged into the athena section's entry (`Layouts: athena, full, floating`). | floating | not a B row |
| WB-FLOAT-11 | right·9 | `custom/power` | Click the power glyph (a distinct glyph escape from athena/full/vertical's shared form, and a literal `bash ` prefix on the invocation, unlike their bare script-path form) — `bash ~/.config/hypr/scripts/wleave.sh` opens the wleave power menu. No `tooltip-format` key — hover shows no custom tooltip text on this layout (contrast athena/full/vertical, all three of which show "Power Menu" on hover). Distinct from the athena/full/vertical merged entry. | floating | not literally a B item; QPOWER-01..04 carry this forward structurally |

Floating zone-entry count: 16 (5 left + 1 center + 10 right, matching the interface context's
recorded count exactly).

## Layout Criteria — vertical

`config-vertical.jsonc` is the 44px **left**-edge column (see `## Not a Port Specification`
above for why the replacement's own right-edge vertical orientation must not be read off this
anchor). Every text-bearing module here uses a
stacked or abbreviated form to fit the fixed 44px width — the shape criteria below record, not
the anchor edge. Rows already merged elsewhere (`hyprland/workspaces`, `tray` with full;
`custom/gaming-mode`, `custom/power` with athena/full) are not repeated here.

### Zone: modules-left — `["clock", "hyprland/workspaces"]`

| ID | Zone·Index | Module | Checkable criterion | Layouts | GATE-02 B |
|---|---|---|---|---|---|
| WB-VERT-01 | left·0 | `clock` | Shows a two-line stacked form, `{:%H\n%M}` (hours over minutes, no glyph, no seconds — no `format-alt` key exists on this layout, so there is no click-to-toggle-detail behaviour at all, unlike every other layout's clock). Hover — tooltip shows a month calendar, byte-identical to every other layout's calendar tooltip content. Right-click/scroll actions (`mode`/`shift_up`/`shift_down`) are present and byte-identical to athena/full's shared clock's `actions` block. Distinct from athena/full's shared clock and from floating's own clock (no other layout stacks hours-over-minutes). | vertical | B.1 **and** B.4 (the stacked-text vertical-column form for a specific readout) |
| — | left·1 | `hyprland/workspaces` | Covered above — merged into the full section's entry (`Layouts: full, vertical`). | vertical | B.2, B.4 |

### Zone: modules-center — `["mpris"]`

| ID | Zone·Index | Module | Checkable criterion | Layouts | GATE-02 B |
|---|---|---|---|---|---|
| WB-VERT-02 | center·0 | `mpris` | Glyph-only (`{player_icon}`, paused shows `{status_icon}` in the same slot — no artist/title text at all, unlike `full`'s text-bearing `mpris`). Click — `ags request -i media toggle-media`. Right-click — `playerctl next`. Scroll up/down — `playerctl volume 0.05+`/`-`. Hover — tooltip shows player/status/position/length. Distinct from full's own `mpris`. | vertical | not literally named in B.1 (see the note on `full`'s `mpris` entry above) — **and** B.4 (glyph-only is this readout's 44px-column form) |

### Zone: modules-right — `["cpu", "memory", "temperature", "network", "group/audio", "battery", "custom/gaming-mode", "custom/notification", "tray", "custom/power"]`

| ID | Zone·Index | Module | Checkable criterion | Layouts | GATE-02 B |
|---|---|---|---|---|---|
| WB-VERT-03 | right·0 | `cpu` | Glyph-only (`{}`, no numeric value inline); click — `uwsm app -- kitty -e htop` opens a terminal with `htop` (the only layout whose `cpu` module opens a system monitor on click). Hover — tooltip reads `CPU: {usage}%`. Polls every 2s. Distinct from every other layout's `cpu`. | vertical | B.1 **and** B.4 (glyph-only, detail moved to tooltip — the stacked-column form) |
| WB-VERT-04 | right·1 | `memory` | Glyph-only, no numeric inline. Click — `uwsm app -- kitty -e htop`. Hover — tooltip reads `RAM: {used:.1f}G / {total:.1f}G`. Polls every 5s. Distinct from every other layout's `memory`. | vertical | B.1, B.4 |
| WB-VERT-05 | right·2 | `temperature` | Glyph-only, 5-step thermometer ramp; `critical-threshold: 80`; click — `uwsm app -- kitty -e htop`; hover — tooltip reads `Temp: {temperatureC}°C`. Distinct from athena's and full's own `temperature`; absent from `floating`. | vertical | B.1 (arguable, same note as `full`'s temperature), B.4 |
| WB-VERT-06 | right·3 | `network` | Wifi/ethernet/disconnected glyph-only (`format-wifi: "{icon}"`, no signal % inline — text detail moves entirely to the hover tooltip, which shows `{ifname}: {ipaddr}/{cidr}` + `{essid}` on wifi and up/down bandwidth on wifi/ethernet). Click — `qs ipc call panel toggle wifi`. Distinct from every other layout's `network`. | vertical | B.1, B.4 |
| WB-VERT-07 | right·4 (drawer) | `group/audio` | Hover the collapsed volume glyph — within ~400ms the drawer expands **left-to-right** (`transition-left-to-right: true` — the opposite direction convention from athena's own `group/audio`, which expands right-to-left), revealing a vertical slider. `orientation: vertical` for the group itself. `transition-duration: 400` (the fastest drawer of any group in this document). | vertical | not a B row (drawer mechanics; the audio-adjust capability itself is B.1/B.3, see the member row below) |
| WB-VERT-08 | right·4.0 | `pulseaudio` | Glyph-only, no volume % inline (detail moves to the hover tooltip: `{volume}% — {desc}`). Click — `wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle`. Right-click — `qs ipc call panel toggle audio`. **No scroll handler on the collapsed pill** — unlike `floating`'s `scroll-step`, adjusting volume on this layout requires hovering the drawer open first, then interacting with the revealed slider (the row below), not scrolling the collapsed glyph directly. Distinct from every other layout's `pulseaudio`. | vertical | B.1; **not** B.3 in the scroll-on-the-collapsed-pill sense — the drawer-then-drag shape is this layout's own B.3 equivalent |
| WB-VERT-09 | right·4.1 | `pulseaudio/slider` | With the drawer open, drag the **vertical** slider — output volume changes live, range 0-100. `orientation: vertical` (contrast athena's horizontally-oriented slider). | vertical | B.3 (drag-to-adjust, vertical-column shape — the direct precedent for how the replacement's own vertical orientation might expose the same gesture) |
| WB-VERT-10 | right·5 | `battery` | Glyph-only (`{icon}`, no percentage inline — detail moves to the hover tooltip: `{capacity}% — {time}`). Charging/plugged show a distinct plug glyph. 5-state ramp, same thresholds as `floating`'s battery (95/30/20). Distinct from floating's own `battery`. | vertical | B.1 ("when present" — none on this host), B.4 |
| — | right·6 | `custom/gaming-mode` | Covered above — merged into the athena section's entry (`Layouts: athena, full, floating, vertical`). | vertical | not a B row |
| WB-VERT-11 | right·7 | `custom/notification` | Glyph-only (`{icon}`, the count text dropped from `format` entirely — unlike athena/full/floating's shared `{icon} {text}` form). The dropped count text's replacement home is `tooltip: true` (flipped from the shared entry's `tooltip: false`) — `swaync-client -swb`'s own JSON payload already carries a `"tooltip"` field (verified live: `"tooltip":"16 Notifications"`), and waybar surfaces that automatically once `tooltip` isn't `false`, so hovering shows the unread count as text even though the inline glyph does not. Click — `swaync-client -t -sw`. Right-click — `swaync-client -d -sw`. Distinct from the athena/full/floating merged entry. | vertical | not a B row; B.4-relevant as this readout's 44px-column form |
| — | right·8 | `tray` | Covered above — merged into the full section's entry (`Layouts: full, vertical`). | vertical | B.5, B.4 |
| — | right·9 | `custom/power` | Covered above — merged into the athena section's entry (`Layouts: athena, full, vertical`). | vertical | not literally a B item |

Vertical zone-entry count: 13 (2 left + 1 center + 10 right, matching the interface context's
recorded count exactly).

**Vertical orientation collectively substantiates B.4.** UI-SPEC B.4 ("the horizontal↔vertical
toggle reaches the vertical orientation and every readout present in horizontal is still
present, in the 44px stacked-text form, with no truncation") is not one module's criterion — it
is the property that every `WB-VERT-*` row above (plus the vertical-column instances of the
merged `hyprland/workspaces` and `tray` rows) collectively demonstrates: every readout that
exists in horizontal form on `full` also has a vertical-column form here, stacked or
glyph-only, none of it truncated in the resolved config (no `max-length` clamp appears on any
vertical-layout module that isn't also present on its horizontal counterpart). `18-19`'s B.4
pass is a live re-check of this claim against the actual rendered 44px column on the new bar,
not a re-derivation of it.

## Shared Module Definitions

Every module defined once in `modules.jsonc` (23 definitions), the canonical shared layer every
layout inherits through `"include": ["modules.jsonc", ...]`. "Overrides" below means a layout
fully redefines the key (waybar's `include` is whole-key first-defined-wins — never a partial
patch), which is exactly the class of change a raw `.jsonc` read can miss and only the resolved
snapshot proves.

| Module | Referenced by | Overridden by |
|---|---|---|
| `hyprland/workspaces` | athena, full, floating, vertical | athena, floating (full and vertical use the canonical form unmodified — the full+vertical merged row) |
| `hyprland/window` | full | — (canonical, unmodified) |
| `mpris` | full, vertical | vertical (full uses the canonical form unmodified) |
| `clock` | athena, full, floating, vertical | floating, vertical (athena and full use the canonical form unmodified — the merged row in the athena section) |
| `cpu` | athena, full, floating, vertical | athena, full, floating, vertical (all four override — no layout uses the canonical form as-is) |
| `memory` | athena, full, floating, vertical | athena, full, floating, vertical (all four override) |
| `temperature` | athena, full, vertical (not floating) | athena, full, vertical (all three that reference it override) |
| `pulseaudio` | athena, full, floating, vertical | athena, full, floating, vertical (all four override) |
| `network` | athena, full, floating, vertical | athena, full, floating, vertical (all four override) |
| `custom/theme` | athena (via `group/settings`), full | — (both use the canonical form unmodified — the merged row in the athena section) |
| `custom/waybar-layout` | athena (via `group/settings`), full | — (both canonical — the merged row in the athena section) |
| `custom/gaming-mode` | athena, full, floating, vertical | — (all four canonical, unmodified — the merged row in the athena section) |
| `custom/notification` | athena, full, floating, vertical | vertical (athena/full/floating canonical, unmodified — the merged row in the athena section) |
| `custom/power` | athena, full, floating, vertical | floating (athena/full/vertical canonical, unmodified — the merged row in the athena section) |
| `tray` | athena, full, floating, vertical | athena, floating (full and vertical canonical, unmodified — the merged row in the full section) |
| `custom/media` | athena, floating | — (both canonical, unmodified — the merged row in the athena section) |
| `custom/launcher` | floating | — (canonical, unmodified) |
| `custom/updates` | athena, floating | athena, floating (both that reference it override) |
| `custom/wallpaper` | athena (via `group/settings`), floating | — (both canonical — floating's own redefinition is byte-identical to canonical, merged into one row in the athena section) |
| `custom/font` | athena (via `group/settings`) | — (canonical, unmodified) |
| `custom/icon-theme` | athena (via `group/settings`) | — (canonical, unmodified) |
| `backlight` | floating | — (canonical, unmodified — see `## Dead Definitions`) |
| `battery` | floating, vertical | vertical (floating uses the canonical form unmodified) |

## Dead Definitions

Source for UI-SPEC GATE-02 criterion **B.6**'s exclusion clause: B.6 states that only a genuine
`full`/`floating`/`vertical`-exclusive capability counts as a regression if missing from the new
bar, and that nothing deliberately cut during athena's own 08-16 evolution should be expected
back. The two rows below are exactly that — resolved-snapshot presence with zero live
instantiation, or zero working behaviour, derived mechanically rather than by inspection.

| Layout | Module | Why dead | Not a capability the replacement owes because |
|---|---|---|---|
| athena | `tray` | Present in `18-waybar-resolved/athena.json` (`icon-size: 16`, `spacing: 10` — `config-athena.jsonc` still defines the key directly) but referenced by **zero** zone arrays and **zero** group `modules` arrays — athena's `modules-left`/`-center`/`-right` never list `"tray"`. Removed at the 08-16 checkpoint iteration 2 because its nm-applet/blueman icons visually duplicated `group/connections` (the file's own comment, lines 34-38, records the user's request verbatim: "duplicate bluetooth/network next to gaming mode, remove it"). | The replacement is *not* exempt from having a tray — **D-18-04 deliberately reverses this exact removal**, making the tray always-visible at the end of the new bar. The tray's return is by explicit decision (D-18-04), not by inheritance from this table; this row documents only that athena's own bar never rendered one. |
| floating | `backlight` | Present in `18-waybar-resolved/floating.json` and, unlike `tray` above, genuinely **referenced** by `modules-right` — waybar does instantiate this widget. Its behaviour is dead: scroll up/down is bound to `light -A 5`/`light -U 5`, but the `light` binary is not installed on this host (`/usr/bin/light` does not exist) and `/sys/class/backlight/` is empty (no backlight device at all — this is a desktop board, B550 AORUS ELITE AX V2, not a laptop). Verbatim: `"on-scroll-up": "light -A 5"`, `"on-scroll-down": "light -U 5"`. | D-18-39 records the exact same precedent (compare D-18-06's battery treatment): the capability is structurally present in config today but has been a no-op on this hardware since before this phase started, so its non-functional state on the new bar (QBAR-04 ships present-but-inert, gated on hardware presence via `brightnessctl`) is not a phase-18 regression — it is carrying forward an already-dead binding, evidenced by this row rather than merely asserted. This is what makes GATE-02 **B.3** recordable as "not demonstrable on this hardware — structurally present" instead of a claimed pass. |

## Unaccounted Keys

Closure proof: every top-level key of every resolved snapshot, checked against every criterion
row, the `## Bar-Level Chrome` table, and the `## Dead Definitions` table above. All four lists
are empty.

- **athena** — 45 top-level keys in `18-waybar-resolved/athena.json`. Zero unaccounted: every
  module key is a `WB-ATH-*`/`WB-ALL-*` row or the `tray` Dead Definition; every bar-level scalar
  (`layer`, `position`, `height`, `margin-top`, `margin-left`, `margin-right`, `spacing`,
  `on-sigusr1`, `on-sigusr2`) is in `## Bar-Level Chrome`; `modules-left`/`modules-center`/
  `modules-right` are the zone-array keys named throughout this document's zone headers. **(none)**
- **full** — 27 top-level keys. Zero unaccounted: every module key is a `WB-FULL-*`/`WB-ALL-*`
  row; every bar-level scalar (`layer`, `position`, `height`, `margin-top`, `margin-left`,
  `margin-right`, `spacing`, `on-sigusr1`, `on-sigusr2`) is in `## Bar-Level Chrome`. **(none)**
- **floating** — 24 top-level keys. Zero unaccounted: every module key is a `WB-FLOAT-*`/
  `WB-ALL-*` row or the `backlight` Dead Definition; every bar-level scalar (`layer`, `position`,
  `spacing`, `on-sigusr1`, `on-sigusr2`) is in `## Bar-Level Chrome`, including the explicit
  stated absence of `height`/`margin-*` on this layout. **(none)**
- **vertical** — 27 top-level keys. Zero unaccounted: every module key is a `WB-VERT-*`/
  `WB-ALL-*` row; every bar-level scalar (`layer`, `position`, `width`, `margin-top`,
  `margin-left`, `margin-bottom`, `spacing`, `on-sigusr1`, `on-sigusr2`) is in
  `## Bar-Level Chrome`, including the deliberately-absent `output` key. **(none)**

## GATE-02 Criterion B Index

Maps UI-SPEC § "GATE-02 Render-Gate Criteria" § B's six criteria to the criterion IDs above, so
`18-19` walks this index under its blocking pass rather than re-deriving the mapping. Two rows
below carry a correction to B's own text, found mechanically while assembling this index — both
are named explicitly rather than silently absorbed, per this document's own completeness
standard.

| B# | UI-SPEC text | Substantiating criterion IDs |
|---|---|---|
| B.1 | Every readout the three retired layouts collectively exposed (clock, battery when present, network, bluetooth, audio, cpu/ram/disk) is present and live on the new bar. | clock: the athena+full merged row, floating's own clock row, vertical's own clock row. battery: floating's and vertical's own battery rows (render nothing on this host either way — no battery present, D-18-06 precedent). network: full's, floating's and vertical's own network rows. audio: full's, floating's and vertical's own pulseaudio rows. cpu/ram/disk: full's and floating's cpu+memory rows, vertical's cpu+memory rows (none of the three has a `disk` readout at all — `disk` is athena-exclusive). **Correction:** B's own text lists "bluetooth" among what the three retired layouts collectively exposed. The resolved snapshots show this is not so — `bluetooth` is referenced by **zero** of `full`/`floating`/`vertical`; it is exclusive to athena. B.1's bluetooth clause is therefore sourced from athena, not from the three-layout capability audit its own framing describes — `18-19` should read B.1's bluetooth check as inherited from D-18-32's aesthetic-baseline half, not the capability-audit half. |
| B.2 | Clicking a workspace switches to it (the capability dead under waybar 0.15.0's compiled-in dispatch — QBAR-03's whole reason for existing). | The athena `hyprland/workspaces` row, the merged full+vertical `hyprland/workspaces` row, and floating's own `hyprland/workspaces` row — all four layouts' `hyprland/workspaces` carry the same dead `"on-click": "activate"`, confirmed by `config-floating.jsonc`'s own comment (the only layout that explains why) and the shared waybar C++ code path that renders every layout's click identically. |
| B.3 | Scrolling on the audio section adjusts volume; scrolling on the brightness-bearing section adjusts brightness (parity with `config-floating`'s scroll bindings). | Audio: floating's own `pulseaudio` row (`scroll-step: 5`, the direct precedent this criterion names) and vertical's own `pulseaudio/slider` row (drawer-then-drag, a different gesture shape for the same capability — athena's own `pulseaudio/slider` row is also drag-based, not scroll). Brightness: the `backlight` Dead Definitions row — **not demonstrable on this hardware, structurally present per D-18-39**, never recordable as a pass. **Unassigned-capability flag:** floating's `hyprland/workspaces` scroll-up/down (`hl.dsp.focus`) is a live, working scroll capability on the retired bar that B.3 as written does not cover (B.3 only names audio and brightness) and that no plan in this phase currently names an owner for reproducing. Recorded here so it is not lost silently; not resolved by this document. |
| B.4 | The horizontal↔vertical toggle (settings drawer + Super-menu, D-18-30) reaches the vertical orientation and every readout present in horizontal is still present, in the 44px stacked-text form, with no truncation. | Every row in the vertical layout section, plus the vertical-orientation instances of the merged `hyprland/workspaces` and `tray` rows — see the "Vertical orientation collectively substantiates B.4" note closing the vertical section above. |
| B.5 | Tray icons render and their menus open on click, in both orientations. | The merged full+vertical `tray` row (covers the vertical-orientation half directly) and floating's own `tray` row. Athena's own `tray` definition is **not** evidence for B.5 — it is a Dead Definition, never placed on athena's bar; D-18-04 is the actual authority for the tray's return. |
| B.6 | Nothing deliberately cut during athena's own 08-16 evolution (e.g. the old tray-folded settings sub-menu) is expected back — only a genuine `full`/`floating`/`vertical`-exclusive capability counts as a regression if missing. | `## Dead Definitions` in full, above — both rows (`tray` in athena, `backlight` in floating) are the exclusion list this criterion depends on. |

**A second correction, found alongside the first while indexing B.1:** neither `mpris` (`full`,
`vertical`) nor `custom/media` (`athena`, `floating`) — the two now-playing mechanisms every
layout has exactly one of — is one of B.1's six named readouts, despite both being live,
universally-present capabilities across all four layouts. This is not a hard gap (the new bar's
own media capsule, D-18-05, is a named requirement independent of B), but it means B.1 as
literally written does not obligate `18-19` to check now-playing at all. Recorded so the pass is
not silently thinner than the document that feeds it.
