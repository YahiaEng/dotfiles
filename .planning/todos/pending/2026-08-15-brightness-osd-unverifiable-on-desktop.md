---
created: 2026-08-15T20:15:00.000Z
title: Brightness OSD path cannot be verified on this host — laptop-only, unproven
area: shell
severity: major
files:
  - quickshell/.config/quickshell/modules/bar/BrightnessBackend.qml
  - quickshell/.config/quickshell/modules/osd/Osd.qml
  - hypr/.config/hypr/config/keybinds.lua
---

## Problem

The brightness half of the OSD (QOSD-01/QOSD-04) cannot be exercised on the
development machine, and the user has confirmed (2026-08-15) these dotfiles
WILL be installed on a laptop. So this path ships unproven, not absent.

Measured on this host 2026-08-15:
- `/sys/class/backlight/` is **empty** — no backlight-class device at all.
- `brightnessctl -l` lists only LED-class devices (`input33::capslock`,
  `enp5s0-3::lan`).

So `brightnessctl --class=backlight set 5%+` (keybinds.lua, Phase 20 Plan 04
Task 2) has no device to act on here. The prior `swayosd-client --brightness
raise` had none either — no working behaviour was lost in the migration.

**The latent defect is the trigger, not the command.** `Osd.qml` raises the
indicator from `BrightnessBackend.onPercentChanged`. The keybind calls
`brightnessctl` directly, so `BrightnessBackend` only notices if it can observe
sysfs changing. Phase 20 GATE-01 Observation 3 measured that sysfs poll/watch
**does not fire on this kernel** (the `select.poll()` watcher printed no EVENT
on either Caps Lock LED transition). Same mechanism, same failure: on a laptop
with a real backlight, the key would change brightness while the OSD stayed
silent.

This is the same root cause as the Caps Lock indicator's mechanism problem, not
a separate bug.

## Solution

Owned by Phase 20 Plan 20-05 (the slider column). Decide deliberately between:

1. Keybind routes through a path that notifies the shell directly (e.g. the
   bind calls into Quickshell/`BrightnessBackend` rather than raw
   `brightnessctl`), so the trigger never depends on sysfs observation; or
2. `BrightnessBackend` polls while the OSD is visible / for a short window
   after a change, accepting the cost.

Option 1 is consistent with D-20-05's "trigger is backend state, never the
keybind" only if the backend remains the thing that emits the change — route
the WRITE through the backend, keep the READ reactive.

Do NOT rely on sysfs `watchChanges`/poll for backlight: measured non-functional
here (RESEARCH.md Open Question 1, and GATE-01 Observation 3 confirmed it).

## Verification debt

Whatever 20-05 implements CANNOT be confirmed on this desktop. Re-test on the
laptop at first install:
- brightness keys change the backlight, AND
- the OSD raises with a brightness row on each press, AND
- an external `brightnessctl set 30%` (no key press) also raises it (D-20-05).

Until then this path must be reported as implemented-but-unverified, never as
passing.
