---
created: 2026-08-15T19:55:00.000Z
title: Unify dashboard and overview frost values with OSD/notifications
area: ui
severity: minor
files:
  - hypr/.config/hypr/config/windowrules.lua
  - quickshell/.config/quickshell/modules/bar/BarRoles.qml
---

## Problem

Frost (surface alpha + `ignore_alpha`) is currently inconsistent across the
shell's layer surfaces. Measured on 2026-08-15 during Phase 20 Plan 04:

| namespace | fill alpha | `blur` | `ignore_alpha` |
|---|---|---|---|
| `quickshell-notif-toast` | 0.38 (`notifSurface`) | true | 0.2 |
| `quickshell-notif-popups` | 0.38 | true | 0.2 |
| `quickshell-notif-centre` | 0.38 | true | 0.2 |
| `quickshell-osd` | 0.38 | true | 0.2 |
| `quickshell-dashboard` | — | true | 0.5 |
| `quickshell-overview` | — | true | 0.25 |
| `^quickshell-.*` (family floor) | — | true | 0.5 |
| bar (`barSurface`) | 0.55 | — | 0.5 (family) |

The notification family and the new OSD are already mutually consistent — the
OSD is a `Toast.qml` instance, so it inherits `BarRoles.notifSurface` and Plan
03 gave it the same `blur`/`ignore_alpha` rows the notification namespaces
carry. That group is NOT what needs changing.

The dashboard (0.5) and overview (0.25) sit at their own values, so the same
wallpaper reads through three different frost strengths depending on which
surface is open. User raised this on 2026-08-15 while verifying the OSD.

## Solution

TBD — decide whether one frost value should govern all panel-class surfaces, or
whether the tiers are intentional (e.g. transient pills lighter than
full-screen surfaces). Note that `ignore_alpha` interacts with each surface's
own fill alpha, so the two must be chosen together: a fill at or below the
`ignore_alpha` threshold silently discards blur, and the symptom looks like a
design problem rather than a blur bug.

Also note `hyprctl keyword` is rejected on this config (`keyword can't work
with non-legacy parsers`) and `hyprctl reload` silently drops layer-rule
edits — use `hyprctl eval 'hl.layer_rule({...})'` or a full restart when
testing candidate values live.

Deferred out of Phase 20 deliberately: Phase 20's scope is the OSD and power
menu, and re-tuning dashboard/overview frost would change surfaces the phase
does not otherwise touch.
