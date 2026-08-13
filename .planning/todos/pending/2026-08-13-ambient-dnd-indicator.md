---
created: 2026-08-13T14:30:00.000Z
title: Ambient DND indicator — bell glyph swap is too easy to miss
area: ui
severity: minor
files:
  - quickshell/.config/quickshell/modules/bar/ClockActionsCapsule.qml
  - quickshell/.config/quickshell/modules/centre/CentreFooter.qml
  - quickshell/.config/quickshell/modules/notifications/NotifServer.qml
---

## Problem

When do-not-disturb is active, the only cues are the bell glyph swapping to
`notifications_paused` in the bar and the toggle tile inside the dashboard/centre
(requires opening a panel). During Phase 19 GATE-02 this caused a false "popups
are broken" report: DND had been left on after the B.7 restart-persistence test
and notifications were being correctly suppressed with no visible explanation.
User confirmed on 2026-08-13 they want a clearer always-visible cue.

## Solution

TBD — options: an accent-coloured badge/dot on the bell, a bar-capsule tint via
the established BarRoles hover/accent tokens, or a persistent count-style chip.
Follow the shell's existing token system (Design.qml/Colours.qml/BarRoles.qml);
colour-lint rejects literals. Keep NotifServer.dnd as the single source of truth.
