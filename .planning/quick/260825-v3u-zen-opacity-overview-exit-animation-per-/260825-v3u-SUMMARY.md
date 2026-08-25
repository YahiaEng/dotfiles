---
quick_id: 260825-v3u
date: 2026-08-25
status: complete
commits: [4ef1ee6f, 9fcad661, 962415ed, 116ebbbe]
---

# 260825-v3u — four polish tasks

Four operator-reported items, four commits, one per task. Two operator
decisions were taken before any edit (Zen opacity scope; settings window
size), both offered as options with the alternatives named.

## 1. Zen shows the wallpaper through a playing video — `4ef1ee6f`

`windowrules.lua:219` had Zen in the same translucency family as
kitty/yazi/thunar/codium at `opacity 0.90 0.88`. Focused is now `1.0`;
unfocused stays at the family's `0.88`, so a background browser still
recedes. **Operator decision D-1** — "fully opaque always" (`1.0 1.0`) and
"drop translucency everywhere" were both offered and rejected.

Not mechanically verifiable, and the block's own header says why: there is
no `hyprctl clients -j` opacity projection (13.1-LUA-FINDINGS.md Spike A).
`luac -p` parses clean. **Needs `hyprctl reload` to take effect** — left to
the operator, since a reload also re-applies `~/.local/state/hypr/overrides.lua`.

## 2. Super+Tab does not follow the motion language — `9fcad661`

**Root cause, and it was not the animation being wrong — there was none.**
`Overview.qml` arms and runs `Cascade` on `Component.onCompleted` (:95-98),
but **`Cascade.runExit()` was never called from that file at all**. All five
dismissal routes emitted `dismissRequested()` straight at shell.qml, which
answered `overviewLoader.active = false` — destroying the wl_surface on
frame one. What looked like the dismiss was Hyprland's own layer-close.

Identical in shape to quick task 260825-x9p round 3, and fixed the same way:
`dismissRequested` now means "the exit finished, tear me down"; a new
`_beginDismiss()` is the request half. It mirrors `PowerMenu.qml:411-437` —
the other `Cascade` consumer, unchanged since Phase 20 — rather than
inventing a second pattern. `toggleOverview()` routes its close through
`_dismissLoader()` (:480), the helper the launcher and drawer already use.

**One deliberate divergence from PowerMenu:** the workspace switch is NOT
deferred behind the exit. D-16-19 makes navigation the overview's whole job,
so the tiles sweep out above the workspace already switched to. PowerMenu
defers because poweroff must not fire with a frame still on screen; nothing
here is destructive that way.

**A second-order break, caught and fixed in the same commit:**
`overviewIpc.toggle()` read `overviewLoader.active` after calling
`toggleOverview()`. Once the close became asynchronous that read returns
"nothing happened" on every successful close, silently breaking
`qs ipc call overview toggle` for scripts. It now reports on `_dismissing`,
which `_beginDismiss()` sets synchronously.

### The sweep the operator asked for

Every summonable surface checked for entrance/exit motion. Dashboard,
Launcher, PowerMenu, NotifCentre, PanelDialog, SectionPopout, Toast and
NotifPopupStack all animate both. **`OsdSliderRow.qml` was the only other
gap** — no `Behavior on` anywhere, so the fill's width and the handle's x
snapped on every volume/brightness step while the Toast frame around them
animated. Both now ease on `Motion.standardDuration`/`standardEasing`,
**disabled while the handle is pressed** so a drag tracks the pointer 1:1
instead of chasing it.

**`motion-lint` reads 552 passed / 0 failed against both gaps, before and
after.** CHECK B inspects animation sites for raw literals; an absent
animation has no site to inspect. A green gate proved only what it could see.

## 3. Split "Media & connectivity" into per-capsule toggles — `962415ed`

One switch covered six independent things (`BarEntryModel.qml:189-207`).
Each now has its own row; the group row is gone, and
`bar.capsules.mediaConnectivity` comes off Prefs' allowlist so no stale
write can strand the capsule hidden with no UI to restore it. Third time
this retirement has run — "Clock & actions" and "System" went the same way
on 2026-08-21 for the same reason.

`MediaConnectivityCapsule.qml` had never called `entryVisible()` at all, so
eight bindings were added: six entries plus the two hover-drawer hosts that
ride them (`audioStripHost` with audio, `connectionsStripHost` with
bluetooth, whose extent is literally `bluetoothPopoutTrigger.implicitWidth`).
Ethernet rides `network` rather than becoming a seventh key.

**One combination is honest rather than clean, and is stated in the row's
own subtext:** the bar reveals Bluetooth by hovering the network glyph, so
Network off + Bluetooth on leaves Bluetooth rendering with nothing to hide
behind. That follows from wiring toggles to capabilities rather than to
rendering containers, which is what was asked for.

All six default true, so an install that never opens this page renders
exactly the capsule it did before.

## 4. Bigger, Caelestia-styled settings window — `116ebbbe`

The reference the operator pointed at (a Zen tab in workspace 1) turned out
to be a **YouTube video**, not a live settings window. Read Caelestia's
actual source instead — its settings window is `modules/nexus/`, and
`Settings.qml`'s own header already recorded that this repo copied that
composition. **Operator decision D-2**: adopt the formula.

Sizing now comes from `NexusTokens`
(plugin/src/Caelestia/Config/tokens.hpp:212-220): height x 0.7 at 16:9,
min 800x500. Resolved with the same arithmetic the QML runs:

| screen | window | nav rail | content column |
|---|---|---|---|
| 2560x1440 (this host) | 1792x1008 | 340 | 800 |
| 1920x1080 | 1344x756 | 336 | 800 |
| 3840x2160 | 2688x1512 | 340 | 800 |

Copying the formula rather than its output is the point: 960x640 was 37% of
this host's width and would be a different fraction everywhere else.
`screen` is guarded, not dereferenced — it is null until the window maps,
and an unguarded `win.screen.height` throws at construction and pins
implicitHeight at 0 forever.

Three pieces of polish, each answering something the resize would otherwise
have broken:

- **Content capped at 800** (`maxContentWidth`). Uncapped, `SettingsSection`
  binds `width: parent.width`, so at 1792 every row would strand its label
  left and its switch right. Capped on the content, not the Flickable, so
  the whole pane still catches wheel and drag.
- **Nav rail proportional**, `min(340, width/4)`. Caelestia uses `width/3`,
  but their nav rows are taller and more spacious than this rail's compact
  list — `width/3` of 1792 is 597px of mostly empty rail.
- **Page swap slides in the direction of travel**, forward from below,
  backward from above, as Caelestia's `Pages.qml` does. **Total duration
  deliberately unchanged**: that file records two rounds of operator
  pushback on this swap feeling laggy, both settled by shortening it, so
  the slide runs inside the existing fade-in stage, in parallel, on the same
  token. It adds a dimension to the motion, never a millisecond.

Window title now carries the current page ("Settings — Bar").

**A real bug caught by not trusting the linter:** `Pages.qml` needed an
`import "../dashboard"` it never had — `Design` is registered in
`modules/dashboard/qmldir`, and **qmllint returns 0 on a missing QML
import**. Every singleton these edits introduced was checked against the
qmldir that declares it.

## Gates

Run once each, after the edits they cover.

| gate | result |
|---|---|
| `motion-lint` | 552 passed / 0 failed |
| `colour-lint` | 365 passed / 0 failed |
| `settings-index-check` | 126 passed / 0 failed |
| `qmllint` | 0 on every edited file except `shell.qml` and `RowIndex.qml` |
| `luac -p` | 0 on `windowrules.lua` |

`shell.qml` and `RowIndex.qml` return 255 to `qmllint` **unmodified at
HEAD as well** — pre-existing import noise, the same class already recorded
for `EdgeBar.qml`/`Dashboard.qml`. Verified by linting a checkout of HEAD's
own copy of each file, not assumed.

`quickshell-doctor` was NOT run: it is a live probe that restarts the shell
internally, which is operator-only on this host.

## What still needs the operator

Nothing here was verified against live pixels — by standing preference, and
because two of the four changes cannot be verified any other way.

1. `hyprctl reload` for the Zen opacity change (T1).
2. Restart quickshell for the QML changes (T2-T4) — never from the agent
   shell.
3. Then look at: Super+Tab closing (the tiles should sweep out, not vanish);
   a volume key press (the OSD fill should ease); Bar > Capsules (six new
   rows, no group row); Super+comma (a 1792x1008 window, page name in the
   title, content in a centred-left 800px column, pages sliding by direction).

---

# Round 2 — the resize was inert, and it always had been

Operator live-check: 1, 2, 3 and 5 pass; **4 "the settings menu look is
unchanged"**.

**Cause: this repo's own window rule, not the QML.** `windowrules.lua`'s
`float-settings` carried `size = "960 640"`, written by the task that first
created the window (260820-sqd), and **a Hyprland size rule overrides the
client's requested geometry**. `Settings.qml`'s implicitWidth/implicitHeight
had therefore never had any effect at all — not merely since round 1, but
since the window existed.

Measured live before touching anything (`hyprctl clients -j`, class
`org.quickshell`): `at [775,400] size [960,640]` against a QML asking for
1792x1008.

Everything round 1 derived from `width` had been computing against 960 and
landing within a few pixels of the old design: nav rail `min(340, 960/4)` =
240 (against 260 before), and the 800px content cap never engaged because the
content pane was only 672 wide. **The one piece that did show was the window
title** — `Settings — Appearance` — which is what proved the QML changes were
live at all rather than unstowed or unreloaded.

**Fix:** remove the `size` term. No literal replaces it: only the QML knows the
screen, so only the QML can size this window, and a number here would re-pin it
to one display's pixels and defeat the formula again. `float` and `center`
stay — placement genuinely is the compositor's business.

**Measured after:** `size [1792,1008] at [359,216]` — centred in the *usable*
area to the pixel, `(2560-50)/2 - 896 = 359` and `(1440-12)/2 - 504 + 6 = 216`.

Commit `1a28478c`. `luac -p` clean, `hyprctl reload` ok, `configerrors` empty.

## What this should have caught earlier

Round 1 changed a window's size in QML without checking whether the compositor
was already dictating it. The repo's own standing habit —
"absence claims need a tree-wide grep" — was applied to `windowrules.lua` for
`zen` and `opacity` in the very same session, and not for the surface being
resized. **When changing a surface's geometry, grep the compositor config for
that surface's class or namespace first**: a `size`/`move`/`maxsize` rule wins
over anything the client asks for, and it fails silently — the QML binding is
correct, evaluates correctly, and is simply ignored.
