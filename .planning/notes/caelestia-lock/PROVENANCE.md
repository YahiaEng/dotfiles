# Caelestia lock screen — vendored source

`caelestia-dots/shell` @ **a788c432d9274a123c113eed6d28a241ddfc2cdd**, fetched
2026-08-27 for quick task 260827-833 (replace hyprlock with an in-process
Quickshell QML lock screen).

Same SHA as `.planning/notes/caelestia-dashboard/`, so the two vendored trees
are internally consistent — a component shared between the dashboard and the
lock behaves the same in both.

Vendored because a "follow the reference" task without the reference files in
the tree produces an invented design reported as the reference — the failure
this repo already recorded once (`vendor-the-reference-source`).

Fetched from `https://raw.githubusercontent.com/caelestia-dots/shell/<sha>/modules/lock/…`
at the pinned SHA, not from `main`, so a later read gets the same bytes.

## The headline finding

**Caelestia does not use hyprlock.** It ships its own QML lock screen in the
same process as its bar, built on `Quickshell.Wayland`'s `WlSessionLock` and
authenticating through `Quickshell.Services.Pam`. This answers the question the
quick task opened with — there is no third-party lock binary in their stack to
adopt instead.

## File → role

| File | Role |
|------|------|
| `Lock.qml` | `Scope` holding the `WlSessionLock`, the `Pam` context, the screencopy pre-warm `Loader`, two `CustomShortcut`s, and an `IpcHandler` (target `"lock"`, methods `lock()` / `unlock()` / `isLocked()`) |
| `LockSurface.qml` | The `WlSessionLockSurface`. Owns the lock-icon→card expand animation, its reverse on unlock, and the blurred backdrop (`MultiEffect`, `blur: 1`, `blurMax: 64`) over either a `ScreencopyView` or a `CachingImage` of the wallpaper |
| `Pam.qml` | Auth state machine over `PamContext` — also where fingerprint and Howdy are sequenced |
| `Content.qml` | The three-column `RowLayout`: left `{WeatherInfo, Fetch, Media}`, `Center`, right `{Resources, NotifDock}` |
| `Center.qml` | `ColumnLayout` `{Clock, date text, ProfilePic, PasswordInput, StateMessage}`, scaled by `Math.min(1, screenHeight / 1440)` |
| `center/Clock.qml` | Hours in `m3primary`, minutes in `m3secondary`, positioned off `TextMetrics.tightBoundingRect` rather than layout height |
| `center/PasswordInput.qml`, `center/InputField.qml` | The field and its echo behaviour |
| `center/ProfilePic.qml`, `center/StateMessage.qml` | Avatar; PAM message surface |
| `Fetch.qml`, `Media.qml`, `NotifDock.qml`, `Resources.qml`, `WeatherInfo.qml` | The ambient widgets in the two side columns |
| `lockconfig.hpp` | Their `LockConfig` — `enabled`, `useWallpaper` (default **false**, i.e. screencopy is their default backdrop), `recolourLogo`, `enableFprint`, `maxFprintTries`, `enableHowdy`, `maxHowdyTries`, `triggerHowdyOnWake`, `hideNotifs` |

## Measured geometry

From `plugin/src/Caelestia/Config/tokens.hpp`, `class LockTokens`:

| Token | Value | On this 2560×1440 output |
|-------|-------|--------------------------|
| `heightMult` | `0.7` | card is 1008 px tall |
| `ratio` | `16.0 / 9.0` | card is 1792 px wide |
| `centerWidth` | `600` | centre column is exactly 600 px (`centerScale` is 1.0 at 1440 p) |

Because the output is itself 16:9, the card is a 70 %-scale copy of the screen,
centred — the side margins and the top/bottom margins are both 15 %.

## The non-obvious bit worth keeping

`Lock.qml` carries a deliberate warm-up hack, verbatim:

> `// Force a load of a screencopy so the one in the lock works`
> `// My guess is the ICC backend loads async on first request, which if the lock is`
> `// the first request it fails to capture (because it's async and the compositor`
> `// refuses capture when locked)`

A `Loader` instantiates one throwaway `ScreencopyView` at startup and sets
`active = false` in `onLoaded`. Any layout that blurs the **live desktop** needs
this; layouts that show the **wallpaper** instead do not.

## Scope note

This tree is reference material, not vendored runtime code. Nothing here is
imported by this repo's shell — it exists so the implementation can be checked
against the real thing rather than against a recollection of it.
