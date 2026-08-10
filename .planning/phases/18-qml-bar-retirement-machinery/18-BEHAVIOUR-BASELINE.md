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
| WB-ATH-17 | right·1 (drawer) | `group/audio` | Hover the collapsed audio glyph — within ~650ms the drawer expands, growing **right-to-left** (`transition-left-to-right: false`), revealing the mute toggle, a volume slider, and a mic-mute toggle. `transition-duration: 650`. Distinct direction and duration from `group/apps` (500ms, left-to-right) and from vertical's own `group/audio` (400ms, vertical orientation, left-to-right — see `WB-VERT-07`). | athena | not a B row (drawer mechanics; the audio capability itself is B.1/B.3) |
| WB-ATH-18 | right·1.0 | `pulseaudio` | Click the speaker glyph — `wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle` mutes/unmutes; right-click — `qs ipc call panel toggle audio` opens the shell-root audio panel (15-08 rewiring). Hover — tooltip reads "Output: `{volume}`%". Distinct from every other layout's `pulseaudio` (all four differ). | athena | B.1 (audio readout) |
| WB-ATH-19 | right·1.1 | `pulseaudio/slider` | Drag the horizontal slider revealed by the drawer — output volume changes live, range 0-100. `orientation: horizontal` (contrast vertical's own vertically-oriented slider, `WB-VERT-09`). | athena | B.3 (scroll/adjust audio — this is drag, not scroll, but the same capability class) |
| WB-ATH-20 | right·1.2 | `pulseaudio#microphone` | Renders the microphone's mute-state icon only (`{format_source}`, no numeric value) — present **only** in athena; no other layout has a `pulseaudio#microphone` entry anywhere. | athena | not a B row (athena-only extra) |
| WB-ATH-21 | right·2 (drawer) | `group/connections` | Hover the collapsed connections glyph — within ~500ms the drawer expands right-to-left, revealing network and bluetooth icons. `transition-duration: 500`, `transition-left-to-right: false`. | athena | not a B row (drawer mechanics) |
| WB-ATH-22 | right·2.0 | `network` | Wifi connected: shows a 5-step signal-strength glyph (`format-icons`, weakest to strongest); ethernet: shows a distinct ethernet glyph (`󰈀`); disconnected: shows `󰤮`; disabled: shows `󰖪`. Hover while on wifi — tooltip reads `{essid}` + signal % + frequency + up/down bandwidth. Click — `qs ipc call panel toggle wifi` opens the shell-root wifi panel (15-08 rewiring; the old tray-applet click this replaced had been dead since athena's tray removal). Distinct from every other layout's `network` (all four differ). | athena | B.1 (network readout) |
| WB-ATH-23 | right·2.1 | `bluetooth` | Disconnected: shows `󰂯`; connected: shows `󰂱`; radio disabled: shows `󰂲`. Hover while connected — tooltip lists each connected device and, where the device reports one, its battery %. Click — `qs ipc call panel toggle bluetooth` opens the shell-root bluetooth panel; right-click — `rfkill toggle bluetooth` toggles the radio. **Present only in athena — `full`, `floating` and `vertical` never reference `bluetooth` at all**, despite UI-SPEC's B.1 listing bluetooth among "the three retired layouts collectively exposed" (see the GATE-02 Criterion B Index's B.1 note in the extension of this document for the correction). | athena | B.1 (see correction note — bluetooth is athena-sourced, not full/floating/vertical-sourced) |
| WB-ALL-02 | right·3 | `clock` | Shows `{:%H:%M}` inline (e.g. "14:32" with a clock glyph); click — switches to `format-alt`, the full date (`{:%A, %B %d, %Y}`); click again — reverts. Right-click — `mode` (same alt-toggle via the `actions` block). Scroll up/down over the clock — `shift_up`/`shift_down` the calendar month shown in the hover tooltip. Hover — tooltip shows a full month calendar (`{calendar}`) for the current month. Byte-identical between athena and full — both use the shared `modules.jsonc` definition unmodified. | athena, full | B.1 (clock readout) |
| WB-ALL-03 | right·4 | `custom/gaming-mode` | With `~/.cache/gaming-mode` containing `on`, shows the "controller-on" glyph (`󰊴`, tooltip "Gaming Mode: ON"); with any other content (including missing), shows the "controller-off" glyph (`󰊵`, tooltip "Gaming Mode: OFF") — fails safe to OFF. Click — `~/.config/hypr/scripts/gaming-mode-toggle.sh` toggles the state file. Polls the file every 2s. Byte-identical across **all four** layouts — none of them override this module. | athena, full, floating, vertical | not a B row (not one of B.1's named readouts, but present everywhere so its parity is de facto load-bearing) |
| WB-ALL-04 | right·5 | `custom/notification` | Unread notifications present: shows a bell-with-badge glyph (`format-icons`, 8 states crossing notification/none × dnd/normal × inhibited/normal) plus the unread count (`{icon} {text}`); no unread: shows a plain bell. Click — `swaync-client -t -sw` toggles swaync's control centre open/closed. Right-click — `swaync-client -d -sw` toggles do-not-disturb. Reads live via `swaync-client -swb` (`exec-if: "which swaync-client"` — module renders nothing if swaync isn't installed). Byte-identical across athena, full and floating (vertical's own version differs — glyph-only, no count text — see `WB-VERT-11`). Verbatim `exec`: `swaync-client -swb`. Phase 19 rewires what is behind this click without touching the layout (D-18-33). | athena, full, floating | not a B row (bell readout isn't one of B.1's named six, but the swaync-wiring capability is what D-18-33 explicitly carries forward) |
| WB-ATH-24 | right·6 (drawer) | `group/settings` | Hover the collapsed gear glyph (`custom/settings`, `` U+F013) — within ~500ms the drawer expands right-to-left, revealing 5 switcher icons (theme, waybar-layout, font, icon-theme, wallpaper) plus the gear itself. `transition-duration: 500`, `transition-left-to-right: false`. This is the 08-16-checkpoint settings drawer that replaced the original tray-folded settings buttons (see the file's own header comment). | athena | not a B row (drawer mechanics; D-18-01 carries this drawer forward by name) |
| WB-ATH-25 | right·6.0 | `custom/settings` | Click the collapsed gear glyph itself — toggles the `group/settings` drawer open/closed (`tooltip: false`). Athena's own definition (not in `modules.jsonc`; no other layout references it). | athena | not a B row |
| WB-ALL-05 | right·6.1 | `custom/theme` *(source: `modules.jsonc` canonical, not present in `athena.json` — see the Provenance tool-completeness note)* | With the drawer open, hover the half-filled-circle icon — tooltip reads "Switch Theme"; click it — `~/.config/hypr/scripts/theme-switch.sh` opens the theme picker. Byte-identical (verified via a forced re-resolve probe, `jq -S` zero-diff) between athena's group-referenced use and full's direct `modules-right` use. | athena, full | not a B row (theme-switch capability, not one of B.1-6's named items — carried forward structurally by D-18-30's settings-drawer redesign) |
| WB-ALL-06 | right·6.2 | `custom/waybar-layout` *(source: `modules.jsonc` canonical, not present in `athena.json` — see the Provenance tool-completeness note)* | With the drawer open, hover the grid icon — tooltip reads "Switch Waybar Layout"; click it — `~/.config/hypr/scripts/waybar-switch.sh` opens the four-layout picker. Byte-identical between athena's group-referenced use and full's direct use. **D-18-30 explicitly repurposes this exact discoverable path into the new bar's horizontal/vertical orientation toggle** — this criterion is what that decision is preserving continuity with. | athena, full | not a B row (D-18-30 names this specific UX path as the one being repurposed, not dropped) |
| WB-ATH-26 | right·6.3 | `custom/font` *(source: `modules.jsonc` canonical, not present in `athena.json`)* | With the drawer open, hover the font icon — tooltip reads "Change Font"; click it — `~/.config/hypr/scripts/font-switch.sh` opens the font picker. Referenced only by athena (no other layout lists `custom/font` in any zone or group). | athena | not a B row (athena-only extra) |
| WB-ATH-27 | right·6.4 | `custom/icon-theme` *(source: `modules.jsonc` canonical, not present in `athena.json`)* | With the drawer open, hover the paintbrush icon — tooltip reads "Change Icons"; click it — `~/.config/hypr/scripts/icon-theme-switch.sh` opens the icon-theme picker. Referenced only by athena. | athena | not a B row (athena-only extra) |
| WB-ALL-07 | right·6.5 | `custom/wallpaper` | With the drawer open, hover the picture-frame icon — click it — `bash ~/.config/hypr/scripts/wallpaper-switch.sh` opens the wallpaper picker. Byte-identical between athena's group-referenced canonical use and floating's own (redundant but matching) direct redefinition. | athena, floating | not a B row |
| WB-ALL-08 | right·7 | `custom/power` | Click the power glyph — `~/.config/hypr/scripts/wleave.sh` opens the wleave power menu. Hover — tooltip reads "Power Menu". Byte-identical across athena, full and vertical (floating's own version differs — no tooltip-format, a `bash ` prefix on the same script path, and a different glyph escape — see `WB-FLOAT-11`). Phase 20 replaces what `wleave.sh` opens with the new QML power menu, unaffected by this layout binding. | athena, full, vertical | B.1 is silent on power specifically, but the click-opens-power-menu capability is carried forward structurally by QPOWER-01..04 |

Athena zone-entry count: 14 (4 left + 2 center + 8 right, matching the interface context's
recorded count exactly). Expanded row count (every group member as its own row): 35.
