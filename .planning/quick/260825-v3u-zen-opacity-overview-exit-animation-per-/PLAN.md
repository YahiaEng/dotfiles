---
quick_id: 260825-v3u
date: 2026-08-25
status: in-progress
---

# Quick task 260825-v3u — four polish tasks

Operator brief, verbatim:

1. Watching YouTube in Zen, the background is faintly visible through the video.
2. The Super+Tab menu does not follow the motion language. Make it follow, and
   check for any other surfaces that do not.
3. In Settings, split "Media & Connectivity" under Bar > Capsules into
   individual per-capsule toggles and remove the group toggle.
4. Make the settings menu bigger and polish it, copying Caelestia's design.

## Operator decisions (asked and answered before any edit)

- **D-1 Zen opacity scope**: opaque only while focused — `opacity 1.0 0.88`.
  Zen stays in the house translucency family but never dims what you are
  looking at. Rejected: fully opaque always; dropping translucency globally.
- **D-2 Settings size**: Caelestia's own formula — `screen.height * 0.7` at a
  16:9 ratio, `minimumSize` 800x500. Screen-relative, not a fixed pixel pair.
  On this 2560x1440 host that resolves to 1792x1008 (today: fixed 960x640).
  Rejected: a fixed 1440x900; keeping 960x640 and taking polish only.

## Measured findings that set the scope

- **T1** `hypr/.config/hypr/config/windowrules.lua:219` puts Zen in the same
  `opacity 0.90 0.88` family as kitty/yazi/thunar/codium. 0.90 on a focused
  window is the faint show-through.
- **T2** `modules/Overview.qml` arms `Cascade` on entrance
  (`Component.onCompleted`, :95-98) but **never calls `runExit()`**. All five
  dismissal routes emit `dismissRequested()` directly, and `shell.qml:1059`
  answers with `overviewLoader.active = false`, destroying the surface on
  frame one. Identical defect class to quick task 260825-x9p round 3.
  `PowerMenu.qml:411-437` is the working mirror; `shell.qml:480`'s
  `_dismissLoader()` is the helper Overview bypasses.
- **T2b** Sweep of every summonable surface for entrance/exit motion:
  Dashboard, Launcher, PowerMenu, NotifCentre, PanelDialog, SectionPopout,
  Toast and NotifPopupStack all animate. `OsdSliderRow.qml` is the only other
  gap — zero `Behavior on`, so the fill Rectangle's `width` and the handle's
  `x` jump on every volume/brightness change.
- **T2c** `motion-lint` reads 552 passed / 0 failed against both gaps. It
  checks that animation sites read tokens, not that surfaces have animations —
  a structural blind spot, not a regression.
- **T3** `bar.capsules.mediaConnectivity` gates six entries
  (`BarEntryModel.qml:189-207`: media, audio, brightness, network, bluetooth,
  battery). `MediaConnectivityCapsule.qml` never calls
  `BarEntryModel.entryVisible()`, so no per-entry toggle exists yet. The
  retirement precedent is exact: `bar.capsules.clockActions` and
  `bar.capsules.system` were removed the same way on 2026-08-21 once their
  children gained per-entry toggles (`Prefs.qml:93`).
- **T4** Caelestia's settings window is `modules/nexus/`; our `Settings.qml`
  header already records that it copied that shape. Read from source:
  `NexusTokens` (plugin/src/Caelestia/Config/tokens.hpp:212-220) —
  heightMult 0.7, ratio 16/9, minWidth 800, minHeight 500, maxNavWidth 600,
  maxContentWidth 800. `Nexus.qml` derives both dimensions from the screen;
  `Pages.qml` slides the page container by +/- one padding step alongside the
  fade; `PageBase.qml` caps content at `maxContentWidth` and uses a
  fade-edged flickable; `WindowFactory.qml` puts the current page name in the
  window title.

## Tasks

- **T1** `windowrules.lua:219` — Zen `opacity 0.90 0.88` -> `1.0 0.88`.
- **T2** `Overview.qml` — add `_dismissing`/`_beginDismiss()` mirroring
  `PowerMenu.qml:411-437`; route all five dismissal sites through it;
  `shell.qml` — `toggleOverview()`/`onDismissRequested` go through
  `_dismissLoader()`.
- **T2b** `OsdSliderRow.qml` — `Behavior on width`/`Behavior on x` for the
  fill and handle, on `Motion.standardDuration`/`standardEasing`, disabled
  while the handle is pressed so dragging stays 1:1.
- **T3** Six per-entry `ToggleRow`s in `BarPage.qml`; drop the group row;
  add the six keys to `Prefs.qml`; six `entryVisible()` bindings in
  `MediaConnectivityCapsule.qml`; update `RowIndex.qml`.
- **T4** `Settings.qml` screen-relative sizing + page name in title;
  `PageBase.qml` content-width cap; `Pages.qml` slide alongside the fade;
  `NavRail.qml` proportional width.

## Gates

`motion-lint`, `colour-lint`, `settings-index-check`, `qmllint` on every
touched QML file. `quickshell-doctor` is a LIVE probe that restarts the shell —
operator-only, never run from here.
