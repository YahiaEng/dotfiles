---
phase: 14-dashboard-drawer
reviewed: 2026-08-01T16:55:00Z
depth: standard
files_reviewed: 27
files_reviewed_list:
  - quickshell/.config/quickshell/modules/Dashboard.qml
  - quickshell/.config/quickshell/modules/Motion.qml
  - quickshell/.config/quickshell/modules/qmldir
  - quickshell/.config/quickshell/modules/dashboard/Cascade.qml
  - quickshell/.config/quickshell/modules/dashboard/ConditionGlyph.qml
  - quickshell/.config/quickshell/modules/dashboard/DashboardTab.qml
  - quickshell/.config/quickshell/modules/dashboard/Design.qml
  - quickshell/.config/quickshell/modules/dashboard/Dial.qml
  - quickshell/.config/quickshell/modules/dashboard/MediaBackend.qml
  - quickshell/.config/quickshell/modules/dashboard/MediaTab.qml
  - quickshell/.config/quickshell/modules/dashboard/PerformanceTab.qml
  - quickshell/.config/quickshell/modules/dashboard/QuickToggles.qml
  - quickshell/.config/quickshell/modules/dashboard/SystemResources.qml
  - quickshell/.config/quickshell/modules/dashboard/WeatherBackend.qml
  - quickshell/.config/quickshell/modules/dashboard/WeatherPalette.qml
  - quickshell/.config/quickshell/modules/dashboard/WeatherTab.qml
  - quickshell/.config/quickshell/modules/dashboard/qmldir
  - quickshell/.config/quickshell/shell.qml
  - quickshell/.config/quickshell/shortcuts.json
  - hypr/.config/hypr/config/keybinds.lua
  - hypr/.config/hypr/config/windowrules.lua
  - hypr/.config/hypr/scripts/hypr-equivalence-check
  - theme-engine/.config/theme-engine/theme-doctor
  - theme-engine/.config/theme-engine/lib/motion.sh
  - theme-engine/.config/theme-engine/motion.json
  - theme-engine/.config/theme-engine/contract.json
  - swaync/.config/swaync/config.json
findings:
  critical: 1
  warning: 6
  info: 3
  total: 10
status: issues_found
---

# Phase 14: Code Review Report

**Reviewed:** 2026-08-01T16:55:00Z
**Depth:** standard
**Files Reviewed:** 27
**Status:** issues_found

## Summary

Reviewed the Dashboard drawer's QML surface (Dashboard.qml, the nine+ `modules/dashboard/` types, shell.qml wiring), the Hyprland Lua keybind/windowrule config touched by this phase, the two maintenance bash scripts (`hypr-equivalence-check`, `theme-doctor`), the motion-token pipeline (`motion.sh`/`motion.json`/`contract.json`), and `swaync/config.json`.

The two project invariants called out for this review — zero raw hex/duration literals in QML (with `WeatherPalette.qml`'s documented exemption) and zero-idle backend polling gated on `drawerOpen`/Loader lifetime — both hold across every file read; no unauthorized hex colours, no unnamed raw durations, and every timer/`Process` in `MediaBackend.qml`/`WeatherBackend.qml`/`SystemResources.qml`/`QuickToggles.qml` is correctly gated.

However, one concrete functional regression was found in the calendar's month-navigation (a MouseArea z-order bug that contradicts its own comment and, on the standard QtQuick overlapping-MouseArea input model, makes the prev/next month chevrons unclickable), plus several real robustness gaps: an un-recoverable stuck `requestInFlight` flag in `WeatherBackend.qml` on a synchronous XHR throw, a silently-droppable command race in `MediaBackend.qml`'s single shared mutator `Process`, and a ripple/clip visual bug reproduced across four ripple call sites that mirrors a bug class this same codebase already found and fixed once (for circular art) but never applied to its ripple effects.

## Critical Issues

### CR-01: Calendar month-navigation chevrons are unclickable — wheel MouseArea sits on top and swallows their presses

**File:** `quickshell/.config/quickshell/modules/dashboard/DashboardTab.qml:807-825` (vs. `:570-678`)

**Issue:** `calendarCard`'s three visual children are declared in this order:
1. `Item { id: calendarHeaderRow ... }` (:570-678) — contains the month label and two `CalendarChevron` instances, each with its own nested `MouseArea` (`onPressed`/`onClicked` at :629-666).
2. `Column { ... weekdayRow + dayGrid ... }` (:683-805).
3. `MouseArea { anchors.fill: parent; onWheel: ... }` (:813-825) — the card-wide wheel handler.

The wheel `MouseArea`'s own comment claims: *"Wheel handler scoped to this card alone — declared FIRST (paint order) so the header row's chevrons and the day grid above still receive their own presses"* (:807-809). This is false relative to the actual code: the wheel `MouseArea` is declared **last**, as a sibling of (not nested inside) `calendarHeaderRow`, with `anchors.fill: parent` covering the entire card including the chevron buttons. In QtQuick, sibling stacking order determines hit-testing priority for overlapping items — a later-declared sibling (and everything painted as part of it) sits on top of an earlier sibling's whole subtree for the same screen point. A `MouseArea`, even one that defines only `onWheel` and no `onPressed`/`onClicked`, still captures mouse press events within its bounds by default (this is the standard, well-documented "overlapping MouseArea" QtQuick gotcha this same file's own `DeepLinkSurface` component explicitly designs around a few hundred lines later: *"Declared here, FIRST in this component's own body, so any child added at instantiation... paints on top of it and is checked first for input"*, DashboardTab.qml:854-859).

The practical effect: pressing either month-navigation chevron (`chevron_left`/`chevron_right`, :669-676) will be intercepted by the full-card wheel `MouseArea` sitting on top of it, so month navigation by click does not work — only the mouse-wheel path (`onWheel`) is reachable. This regresses the calendar's own documented D-18 navigation model and the very comment attached to the offending block.

**Fix:** Move the wheel-handling `MouseArea` to be the **first** child of `calendarCard` (immediately after its `property`/`function` declarations, before `calendarHeaderRow`), matching what the comment already claims:

```qml
Rectangle {
    id: calendarCard
    ...
    // Wheel handler scoped to this card alone — declared FIRST so the
    // header row's chevrons and the day grid painted after it sit on top
    // and receive their own presses; only an UNCONSUMED wheel event
    // reaches this MouseArea.
    MouseArea {
        anchors.fill: parent
        onWheel: (wheel) => { ... }
    }

    Item {
        id: calendarHeaderRow
        ...
    }

    Column {
        ...
    }
}
```

## Warnings

### WR-01: `MediaBackend.qml`'s shared mutator `Process` can silently drop a command issued while a previous one is still in flight

**File:** `quickshell/.config/quickshell/modules/dashboard/MediaBackend.qml:235-295`

**Issue:** All five mutating verbs (`playPause`, `nextTrack`, `previousTrack`, `seekTo`, `setVolume`) funnel through one shared `Process` instance:

```qml
Process {
    id: mutatorProcess
    running: false
}

function _dispatch(argv) {
    mutatorProcess.command = argv;
    mutatorProcess.running = true;
}
```

There is no guard against re-entrancy: if `mutatorProcess.running` is already `true` (a previous dispatch's subprocess hasn't exited yet) and `_dispatch()` is called again, `mutatorProcess.command = argv` reassigns the command, but `mutatorProcess.running = true` is a no-op property write (already `true`) — Quickshell's `Process` has no documented "restart with new argv while running" semantics here, so the second command is at real risk of never actually being spawned. Unlike `QuickToggles.qml`'s chip presses (guarded by the single `pendingChip` string, :250/:322-353), `MediaBackend.qml` has no equivalent in-flight guard, and it is reachable from two different UI surfaces at once (the compact widget on the Dashboard tab and the full player on the Media tab both call into the same shared instance) — e.g. dragging the seek slider to release (`seekTo`) immediately followed by a play/pause tap, or two rapid transport-button presses, can lose the second command with no error surfaced anywhere.

**Fix:** Either queue dispatches (buffer the latest pending argv and re-dispatch `onExited`), or give the mutator its own in-flight guard mirroring `QuickToggles.qml`'s `pendingChip` pattern, e.g.:

```qml
property bool _mutatorBusy: false
Process {
    id: mutatorProcess
    running: false
    onExited: root._mutatorBusy = false
}
function _dispatch(argv) {
    if (root._mutatorBusy) return; // or: queue argv and flush onExited
    root._mutatorBusy = true;
    mutatorProcess.command = argv;
    mutatorProcess.running = true;
}
```

### WR-02: `WeatherBackend.qml` can wedge `requestInFlight` permanently true if `XMLHttpRequest.open`/`.send()` throws

**File:** `quickshell/.config/quickshell/modules/dashboard/WeatherBackend.qml:299-336`

**Issue:** `fetchIfStale()` sets `root.requestInFlight = true` (:312) before constructing and sending the XHR, but `xhr.open("GET", url)` / `xhr.send()` (:334-335) are not wrapped in `try`/`catch`. Every other parse path in this file (`applyResponse`, `loadCache`, the `onreadystatechange` handler itself) is defensively wrapped, but this pair is not. If either call throws synchronously (e.g. an unexpected `url` shape, or an environment where `XMLHttpRequest` construction/open is briefly unavailable), `requestInFlight` is never reset to `false`. Because `WeatherBackend` is mounted once at the shell root (survives every drawer open/close, per shell.qml:98-101) rather than being recreated, `fetchIfStale()`'s own re-entrancy guard (`if (root.requestInFlight) return;`, :307) would then permanently refuse every future fetch for the rest of the session — the Weather tab would be stuck showing stale/placeholder data with no self-recovery path short of restarting Quickshell.

**Fix:** Wrap the request construction/dispatch in `try`/`catch` and reset `requestInFlight` on failure, mirroring the discipline already used everywhere else in this file:

```qml
try {
    xhr.open("GET", url);
    xhr.send();
} catch (e) {
    root.requestInFlight = false;
    root._currentXhr = null;
    root.lastFetchFailed = true;
    console.log("WeatherBackend: xhr dispatch failed: " + e);
}
```

### WR-03: Ripple/state-layer effects clip to a rounded `Rectangle`'s bounding box, not its rounded shape — the same bug class this codebase already found and fixed once for circular art, left unfixed for every ripple

**Files:**
- `quickshell/.config/quickshell/modules/dashboard/DashboardTab.qml:604-619` (`CalendarChevron`'s `chevronCircle`/`rippleCircle`) and `:837-901` (`DeepLinkSurface`'s `linkSurface`/`linkRippleCircle`)
- `quickshell/.config/quickshell/modules/dashboard/MediaTab.qml:1080-1108` (`TransportButton`'s `circle`/`rippleCircle`)
- `quickshell/.config/quickshell/modules/dashboard/QuickToggles.qml:421-445` (`ToggleChip`'s `container`/`rippleCircle`)

**Issue:** Every one of these components draws its MD3 ripple as a small `Rectangle` that grows to `Math.max(width, height) * 2` inside a parent `Rectangle` that sets `radius: ...` (a circle or rounded pill) and `clip: true`. This codebase's own comments elsewhere state, correctly and explicitly, that `clip: true` on a `radius`-rounded `Rectangle` "only clips to the item's AXIS-ALIGNED BOUNDING BOX only... `clip` never follows the rounded shape `radius` paints" (MediaTab.qml:164-166, reiterated at DashboardTab.qml round-2 header notes) — and that finding was used to justify replacing plain `clip: true` art containers with a genuine `QtQuick.Effects.MultiEffect` alpha mask (MediaTab.qml:642-663, DashboardTab.qml:1017-1041). That fix was never extended to any of the four ripple call sites listed above: each one still relies on bare `clip: true` to contain a ripple that grows to twice the container's diagonal, so the ripple will visibly bleed past the rounded/circular edge into the corners of the bounding square during the press animation.

**Fix:** Apply the same masking technique already proven elsewhere in this codebase (a `layer.enabled: true` mask shape + `MultiEffect.maskEnabled`), or — cheaper — clip the ripple itself to a circle by giving the ripple `Rectangle` its own `radius: width/2` and keeping it strictly inside the parent's inscribed circle, or reduce the ripple's max grow diameter so it never exceeds the parent's own rounded inradius on the affected axis.

### WR-04: Seek/volume `Slider` controls may steal keyboard focus from the drawer's Escape/arrow-key handler

**Files:** `quickshell/.config/quickshell/modules/dashboard/MediaTab.qml:981` (`seekSlider`), `:1299` (`volumeSlider`); `quickshell/.config/quickshell/modules/Dashboard.qml:383-401` (`content` Item's `Keys.onEscapePressed`/`Keys.onLeftPressed`/`Keys.onRightPressed`, `Component.onCompleted: content.forceActiveFocus()`)

**Issue:** `content` (a plain `Item`, not a `FocusScope`) is given active focus once via `forceActiveFocus()` and relies on holding it for the drawer's whole lifetime to keep Esc-dismiss (D-10) and Left/Right-arrow tab switching (D-18) working. `QtQuick.Controls` `Slider` (Basic style, as used here) defaults to a click-accepting focus policy on most Qt versions, meaning dragging the seek or volume slider is a plausible path for active focus to move off `content` onto the `Slider`. Because `content` is a plain `Item` rather than a `FocusScope`, there is no scope boundary to automatically restore focus to it once a descendant control takes it, and neither slider explicitly sets `focusPolicy: Qt.NoFocus` to opt out. If this Qt build's Slider does grab click focus (this should be confirmed live against the installed Qt 6.11 Quick Controls Basic style), the reported "Esc always dismisses" / "arrows always switch tabs" invariants would silently stop working the moment a user has interacted with either slider.

**Fix:** Set `focusPolicy: Qt.NoFocus` on both `Slider` instances (and audit other `QtQuick.Controls` items in the drawer for the same risk), or make `content` a `FocusScope` so focus reliably returns to it.

### WR-05: `theme-doctor` writes a predictable, fixed `/tmp` filename instead of a private temp file

**File:** `theme-engine/.config/theme-engine/theme-doctor:210`

**Issue:**
```bash
(cd "$DOTFILES_DIR" && stow -n theme-engine >/dev/null 2>/tmp/theme-doctor-stow.log)
```
uses a fixed, predictable path under the world-writable `/tmp` rather than `mktemp`. On a multi-user machine this is a classic symlink/pre-creation race: another local user could pre-create `/tmp/theme-doctor-stow.log` as a symlink to an arbitrary file the invoking user can write, or simply read stow's stderr output (informational, but still an unintended disclosure) if permissions allow. Every other temp-file-needing operation in the sibling `hypr-equivalence-check` script correctly uses `mktemp -d` (`hypr-equivalence-check:784`).

**Fix:**
```bash
_stow_log="$(mktemp)"
(cd "$DOTFILES_DIR" && stow -n theme-engine >/dev/null 2>"$_stow_log")
check "stow -n theme-engine reports no conflicts" "$?"
rm -f "$_stow_log"
```

### WR-06: `SystemResources.qml`'s GPU sampler only ever reads the first `nvidia-smi` CSV line

**File:** `quickshell/.config/quickshell/modules/dashboard/SystemResources.qml:787-803` (`_onGpuProbeFinished`), `:869-894` (`_onGpuSampleFinished`)

**Issue:** Both the one-shot presence probe and the recurring sampler take `(text || "").split("\n")[0]` — i.e. only the first row of `nvidia-smi`'s CSV output. On a machine with more than one NVIDIA GPU, `nvidia-smi --query-gpu=...` emits one line per device; this reader silently reports only the first device's utilization/memory and only the first device's name, with no indication to the user that additional GPUs exist or are being ignored. This is a reasonable simplification for the single-GPU machine this was built and verified against, but is an unannounced scaling gap for any future multi-GPU host.

**Fix:** Either document the single-GPU assumption explicitly in the file header (it currently is not called out, unlike every other seam in this file), or sum/aggregate across all reported lines, or add an index/selector for which GPU to track.

## Info

### IN-01: `theme-doctor`'s elephant/walker "not found" branches bypass the shared `check()` helper

**File:** `theme-engine/.config/theme-engine/theme-doctor:232-245`

**Issue:** Every other check in this file goes through the `check "<desc>" "$?"` helper for consistent PASS/FAIL bookkeeping, but the "binary not found" branches for `elephant` and `walker` manually `echo "  [FAIL] ..."` and increment `FAIL` by hand:
```bash
else
    echo "  [FAIL] elephant binary not found"
    FAIL=$((FAIL + 1))
    echo "  [FAIL] elephant listproviders responds"
    FAIL=$((FAIL + 1))
fi
```
Functionally equivalent, but it duplicates the tally-increment logic and drifts from this file's own established convention. **Fix:** `check "elephant binary not found" "1"` (and same for `listproviders`) for consistency.

### IN-02: `Motion.qml`'s `hasMotionTokens` property is not referenced anywhere in the reviewed file set

**File:** `quickshell/.config/quickshell/modules/Motion.qml:104-111`

**Issue:** `hasMotionTokens` is computed and documented as driving a "no motion tokens loaded" UI row (ui:empty/E2), but no file in this review's scope reads `Motion.hasMotionTokens`. It may be consumed by a token-inspector surface outside this phase's file list; if not, it is dead code. **Fix:** confirm a consumer exists, or remove.

### IN-03: `swaync/config.json`'s DND toggle command direction should be re-verified against `QuickToggles.qml`'s mirrored logic

**Files:** `swaync/.config/swaync/config.json:67`, `quickshell/.config/quickshell/modules/dashboard/QuickToggles.qml:330-340`

**Issue:** `QuickToggles.qml`'s header comment claims byte-for-byte parity with swaync's own DND button logic, and the two are structurally similar (`swaync-client -dn`/`-df` chosen by the current state) but keyed off different state variables (swaync's own `$SWAYNC_TOGGLE_STATE` vs. this file's independently-watched `dndState`). I was not able to independently confirm `swaync-client`'s exact `-dn`/`-df` semantics from the files in scope, so I am not asserting a concrete mismatch — flagging only so the DASH-07 mirror-proof claim gets one more explicit live cross-check (press the swaync panel's own DND button and the drawer's DND chip side-by-side and confirm both always drive the backend the same direction from the same starting state).

---

_Reviewed: 2026-08-01T16:55:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
