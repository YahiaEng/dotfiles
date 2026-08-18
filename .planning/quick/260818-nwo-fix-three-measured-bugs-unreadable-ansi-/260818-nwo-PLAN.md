---
quick_id: 260818-nwo
date: 2026-08-18
mode: quick
---

# Quick Task 260818-nwo — Four reported bugs

User-reported, 2026-08-18. Three fixed here; the fourth is narrowed and
awaiting a runtime A/B the operator must observe.

## 1. Kitty argument text unreadable across all themes

**Reported:** "Font colors are hard to read on kitty terminal across all themes.
More specifically, the text of arguments to commands. Example `cd dotfiles`, the
dotfiles text is hard to read."

**Root cause (measured).** `kitty.conf:9` is `shell fish` — kitty runs fish, not
zsh, so zsh-syntax-highlighting is irrelevant here. fish's `fish_color_param`
default is **cyan**, and it colours *every argument to every command*. Nothing in
`fish/.config/fish/` overrides any `fish_color_*` (verified: no universal vars
set either).

`matugen/.config/matugen/templates/kitty-colors.conf` mapped ANSI cyan and
magenta to Material You **container** roles:

```
color5  {{colors.tertiary_container...}}
color6  {{colors.secondary_container...}}   <- fish_color_param lands here
```

Container roles are surface/background colours by definition; `on_*_container`
is the foreground partner meant to sit on them. This is a category error, not a
tuning problem.

**Contrast of `color6` vs `background`, before:**

| | ratio |
|---|---|
| live matugen theme | 1.98:1 |
| all 20 static palettes | 1.10:1 – 1.56:1 (worst `rosepine-dawn`) |

WCAG AA needs 4.5:1.

**Fix:** map 5/6/13/14 to `on_tertiary_container` / `on_secondary_container`.
Operator-selected from three costed options.

**Verified residual (recorded, not hidden):** the five *light* palettes still
land under AA on cyan — but so do the already-shipped accent slots there
(`error` fails in 8 palettes, `tertiary` 6, `secondary` 5, `primary` 4). That is
palette authoring, not template mapping. Out of scope.

## 2. Window-edge smear on transitions — NARROWED, NOT FIXED

**Reported:** smear on Hyprland window edges during resize/transition, worst on
the drawer switching tabs and the bottom edge as notification popouts slide up.

**Ruled out by measurement:** `decoration:motion_blur:enabled` is **false**. The
option name matches the symptom exactly, which is why it was checked rather than
assumed.

**Live state:** blur on, `size 8`, `passes 3`, `xray = true` (set at
`hyprland.lua:111`), `new_optimizations = true`, `damage_tracking = 2`. Every
surface named in the report is a quickshell **layer** surface carrying an
explicit `blur = true` rule (`windowrules.lua:330-331, 489`) — exact correlation,
but two candidate knobs remain and guessing between them is not allowed.

**Blocked on:** a runtime A/B the operator runs and observes (`hyprctl keyword`,
nothing written to disk). Not fixed in this task.

## 3. Cleared notifications restored on next arrival

**Reported:** "The 'x' button and the 'clear all' buttons visually remove
notifications but all the notifications are restored immediately whenever a new
notification arrives."

**Root cause.** `NotifServer.qml:453` sets `notif.tracked = true`; nothing ever
set it false. With `keepOnReload: true` the server retains every notification for
the process's life and re-emits the retained set. `_recordHistory` records
unconditionally by explicit design (D-19-33). So every replay re-added everything
cleared. `clearOne`/`clearAll`/`clearGroup` pruned only the `history` array —
they never released the notification, so the server handed it back.

**Proven from the live state file:**

- 36 of 100 entries shared a wall-clock second with another — 14 at `19:25:31`,
  7 at `19:03:50`, 6 at `19:03:47`. `timestamp` is stamped at *record* time, so a
  14-way tie is one bulk re-record.
- 53 distinct ids across 100 entries — duplicate rows, visible in the centre.
- History spanned 08-16 19:03 → now, pinned at the 100 cap: never drained.

**Second defect found on the way:** `clearOne(id)` filtered by notification id,
and D-Bus ids are recycled (14 duplicated ids measured) — one click could delete
up to nine unrelated rows.

**Fix:** release the tracked notification on every clear path (the half that
actually stops the replay) + a stable `key` (`id|appName|summary|body`) with a
replay guard in `_recordHistory` (the half that stops duplicate rows), plus a
one-time idempotent migration that backfills keys and drops the duplicates the
bug already wrote.

## 4. Weather tab still jitters as it settles

**Reported:** "The weather dashboard tab still jitters as it settles into place."

**Root cause.** The earlier fix pinned the horizontal *size* only, and its own
note said the vertical axis was deliberately left tracking the frame. Two
residuals:

1. Height tracked the animating frame — no `settledPaneHeight` existed.
2. `anchors.horizontalCenter`, introduced *by that fix*: pinning width while
   centring in a frame animating 992→712 holds the size constant but slides the
   left edge every frame.

**Loop check done before writing the fix:** every band self-sizes from its own
content (`heroInner.height`, `hourColumnsRow.height`, `dayColumnsRow.height`,
`root.separatorHeight`); none reads `parent.height`. `asynchronous: false`, so
lazy incubation is ruled out.

## Out of scope

- Bug 2 (blocked on operator A/B)
- Light-palette accent contrast (5 palette files, separate concern)
