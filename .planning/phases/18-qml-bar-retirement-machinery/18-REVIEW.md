---
phase: 18-qml-bar-retirement-machinery
reviewed: 2026-08-12T20:45:00Z
depth: standard
files_reviewed: 66
files_reviewed_list:
  - .claude/CLAUDE.md
  - README.md
  - VERIFICATION.md
  - install.sh
  - stow.sh
  - elephant/.config/elephant/menus/settings.toml
  - matugen/.config/matugen/config.toml
  - hypr/.config/hypr/config/autostart.lua
  - hypr/.config/hypr/config/keybinds.lua
  - hypr/.config/hypr/hypridle.conf
  - hypr/.config/hypr/scripts/bar-orientation.sh
  - hypr/.config/hypr/scripts/bar-visibility.sh
  - hypr/.config/hypr/scripts/gaming-mode-toggle.sh
  - hypr/.config/hypr/scripts/hyprpm-complete.sh
  - hypr/.config/hypr/scripts/quickshell-launch.sh
  - hypr/.config/hypr/scripts/wallpaper-visibility.sh
  - hypr/.config/hypr/scripts/tests/colour-fixtures/compliant-qml.qml
  - hypr/.config/hypr/scripts/tests/colour-fixtures/poisoned-dangling-qml.qml
  - hypr/.config/hypr/scripts/tests/colour-fixtures/poisoned-hex-assign-qml.qml
  - hypr/.config/hypr/scripts/tests/colour-fixtures/poisoned-hex-property-qml.qml
  - hypr/.config/hypr/scripts/tests/colour-fixtures/poisoned-named-colour-qml.qml
  - hypr/.config/hypr/scripts/tests/colour-fixtures/poisoned-rgba-literal-qml.qml
  - hypr/.config/hypr/scripts/tests/quickshell-fixtures/compliant-bar-design.qml
  - hypr/.config/hypr/scripts/tests/quickshell-fixtures/compliant-bar-layers.json
  - hypr/.config/hypr/scripts/tests/quickshell-fixtures/compliant-bar-reserved-post.json
  - hypr/.config/hypr/scripts/tests/quickshell-fixtures/compliant-bar-reserved-pre.json
  - hypr/.config/hypr/scripts/tests/quickshell-fixtures/compliant-quickshell-windowrules.lua
  - hypr/.config/hypr/scripts/tests/quickshell-fixtures/poisoned-injection-windowrules.lua
  - hypr/.config/hypr/scripts/tests/quickshell-fixtures/poisoned-monitor-hotplug-bar-reserved-post.json
  - hypr/.config/hypr/scripts/tests/quickshell-fixtures/poisoned-offlevel-bar-layers.json
  - hypr/.config/hypr/scripts/tests/quickshell-fixtures/poisoned-second-reserving-surface.qml
  - hypr/.config/hypr/scripts/tests/quickshell-fixtures/poisoned-two-axis-bar-reserved-post.json
  - hypr/.config/hypr/scripts/tests/quickshell-fixtures/poisoned-two-bar-layers.json
  - hypr/.config/hypr/scripts/tests/quickshell-fixtures/poisoned-unknown-bar-namespace-layers.json
  - hypr/.config/hypr/scripts/tests/quickshell-fixtures/poisoned-unregistered-frame.qml
  - hypr/.config/hypr/scripts/tests/quickshell-fixtures/poisoned-zero-delta-bar-reserved-post.json
  - quickshell/.config/quickshell/shell.qml
  - quickshell/.config/quickshell/modules/Bar.qml
  - quickshell/.config/quickshell/modules/bar/AudioPopout.qml
  - quickshell/.config/quickshell/modules/bar/BarCapsule.qml
  - quickshell/.config/quickshell/modules/bar/BarEntryModel.qml
  - quickshell/.config/quickshell/modules/bar/BarReveal.qml
  - quickshell/.config/quickshell/modules/bar/BluetoothPopout.qml
  - quickshell/.config/quickshell/modules/bar/BrightnessBackend.qml
  - quickshell/.config/quickshell/modules/bar/ClockActionsCapsule.qml
  - quickshell/.config/quickshell/modules/bar/ClockPopout.qml
  - quickshell/.config/quickshell/modules/bar/HotZone.qml
  - quickshell/.config/quickshell/modules/bar/LauncherCapsule.qml
  - quickshell/.config/quickshell/modules/bar/MediaConnectivityCapsule.qml
  - quickshell/.config/quickshell/modules/bar/MediaPopout.qml
  - quickshell/.config/quickshell/modules/bar/PopoutController.qml
  - quickshell/.config/quickshell/modules/bar/PopoutTrigger.qml
  - quickshell/.config/quickshell/modules/bar/ResourcesPopout.qml
  - quickshell/.config/quickshell/modules/bar/SectionPopout.qml
  - quickshell/.config/quickshell/modules/bar/SystemCapsule.qml
  - quickshell/.config/quickshell/modules/bar/WifiPopout.qml
  - quickshell/.config/quickshell/modules/bar/WorkspaceCapsule.qml
  - quickshell/.config/quickshell/modules/dashboard/BluetoothBackend.qml
  - quickshell/.config/quickshell/modules/dashboard/Design.qml
  - quickshell/.config/quickshell/modules/dashboard/MediaBackend.qml
  - quickshell/.config/quickshell/modules/dashboard/WifiBackend.qml
  - quickshell/.config/systemd/user/quickshell.service
  - theme-engine/.config/theme-engine/contract.json
  - theme-engine/.config/theme-engine/lib/commit.sh
  - theme-engine/.config/theme-engine/lib/reload.sh
  - theme-engine/.config/theme-engine/lib/wallpaper.sh
findings:
  critical: 0
  warning: 5
  info: 2
  total: 7
status: issues_found
---

# Phase 18: Code Review Report

**Reviewed:** 2026-08-12T20:45:00Z
**Depth:** standard
**Files Reviewed:** 66
**Status:** issues_found

## Scope note

This scope was assembled from the 20 phase SUMMARYs' `key-files` field (66
files, after filtering 10 deleted waybar paths from the raw union). A full
`git diff` cross-check against this range was **not** merged in, because this
phase's work also landed across numerous interleaved quick tasks — a file
touched only by a quick task (not named in any phase SUMMARY's `key-files`)
may therefore be out of this review's scope even though it changed during
the phase window. Treat this as a SUMMARY-declared-surface review, not a
full-diff review.

## Summary

This is an unusually well-instrumented codebase: nearly every non-obvious
decision, every reverted fix, and every measured regression is recorded
in-line, including four residuals the team already knows about (a ~3px
percent-readout overhang, a ~3px workspace-numeral offset, a ~6px clock-pill
offset, and a ~10px slider-track offset — all four traced to the same
implicit-size/parent-child measurement-cycle root cause in
`PopoutTrigger.qml` and the `Readout` components). I traced each of those
four again independently and they match what's already documented in
`18-GATE-02-RECORD.md` — no new instance of that root cause was found beyond
what's already named, and I did not find a fix that avoids reintroducing the
binding loop the team already hit twice trying to close the gap (both
attempts recorded in-line at `ClockActionsCapsule.qml:126` and
`MediaConnectivityCapsule.qml:552`/`BarCapsule.qml:144`). The colour-lint and
quickshell-doctor negative fixtures under `tests/` are all still correctly
poisoned — each one fails exactly the check its filename claims to exercise;
none has silently become a rubber stamp.

The defects below are two classes: (1) two missing `install.sh` package
declarations that would leave phase-18-introduced features silently inert
on a genuinely fresh install (this repo's own stated core value), and (2) a
handful of smaller robustness/consistency gaps in the QML and shell layers,
including one instance of the exact `grep -q` + `pipefail` SIGPIPE hazard
this repo has been bitten by before.

## Warnings

### WR-01: `checkupdates` (pacman-contrib) is invoked but never installed

**File:** `install.sh:59-250` (PACMAN_PKGS array), consumed by
`quickshell/.config/quickshell/modules/bar/SystemCapsule.qml:478,524`
**Issue:** `SystemCapsule.qml`'s `updatesProcess` runs `command: [root.updatesCheckCommand]` where `updatesCheckCommand` is the literal `"checkupdates"`, polled every 30 minutes forever via `updatesTimer` for the whole life of the bar. `checkupdates` ships in the official `pacman-contrib` package, which is **not** in `install.sh`'s `PACMAN_PKGS` (nor `AUR_PKGS`). On a genuinely fresh install — this repo's own stated core value, and the thing `verify/container-run.sh`/`VERIFICATION.md`'s INST-03 gate exists to prove — the "system updates" bar entry will never populate (it silently renders nothing, per `SystemCapsule.qml`'s own "renders nothing at all... when the pending count is zero" contract), and the timer will keep launching a binary that does not exist, indefinitely, every 30 minutes, for the life of every session.
**Fix:**
```diff
     # Misc
     libnotify
     python-gobject
     gtk3
     adw-gtk-theme
+
+    # System updates readout (SystemCapsule.qml's `updates` entry invokes
+    # `checkupdates` directly, polled every 30 minutes for the bar's whole
+    # lifetime)
+    pacman-contrib
```

### WR-02: `ffmpeg` is invoked directly but never declared as a dependency

**File:** `install.sh:59-250` (PACMAN_PKGS array), consumed by
`theme-engine/.config/theme-engine/lib/wallpaper.sh:118,124`
**Issue:** `theme_engine_wallpaper_extract_frame()` runs `ffmpeg -y -i "$source" ...` directly for every live-wallpaper still-frame extraction — the frame that both the desktop preview and, per D-06/D-08, the hyprlock lock-screen background depend on for any live-wallpaper theme. `ffmpeg` is not in `PACMAN_PKGS`; it is only reachable transitively via `mpvpaper` (AUR) → `mpv` → `ffmpeg`. This repo has an explicit, self-documented standing constraint against exactly this pattern — see `install.sh`'s own comment on the `lua` entry: *"ROADMAP standing constraint 3 requires a runtime dependency this repo's own tooling calls be declared explicitly, not inherited"* — and the `cpio` entry, added specifically because it "was present on the reference host only transitively... exactly the host-only-state class the reproducibility constraint forbids." `ffmpeg` is the same class of gap, just not yet caught. Every call site is already `|| true`-guarded so nothing crashes, but on a fresh install the failure is silent: the live-wallpaper frame extraction fails, `current.jpg` is left untouched, and any live-wallpaper theme's lock screen has no background with no error surfaced anywhere (see `wallpaper.sh:244-247`'s own comment on this exact failure mode).
**Fix:**
```diff
     lua
+
+    # theme-engine/lib/wallpaper.sh invokes `ffmpeg` directly for live-
+    # wallpaper frame extraction (feeds the lock-screen background too) —
+    # currently only reachable transitively via mpvpaper -> mpv -> ffmpeg;
+    # same "declare it explicitly" rule as lua/cpio above.
+    ffmpeg
```

### WR-03: Notification subscription process never recovers from exit

**File:** `quickshell/.config/quickshell/modules/bar/ClockActionsCapsule.qml:587-618`
**Issue:** `NotificationSource`'s `notificationSubscription` (`swaync-client -swb`) is started once with `running: true` and never restarted. `onExited` only sets `_available = false` on a non-zero exit (line 614-617) — there is no retry, backoff, or reconnect logic anywhere. swaync itself autostarts through a plain `uwsm app` scope with `Restart=` nowhere in this repo (per `quickshell.service`'s own header comment on that convention), so if swaync ever restarts (package upgrade, crash, manual kill) the subscription client exits and the bell capsule is permanently stuck showing the "unavailable" (danger-tinted) glyph — recoverable only by restarting the whole `quickshell.service`, not by swaync coming back on its own. This is exactly the class of defect the review brief calls out: a leaked/dead process in a surface with no dismissed state that runs for days.
**Fix:** Add a bounded restart in `onExited`, e.g.:
```qml
onExited: function (exitCode, exitStatus) {
    if (exitCode !== 0)
        sourceRoot._available = false;
    notificationRestartTimer.restart(); // non-repeating, e.g. 2s
}
// ...
Timer {
    id: notificationRestartTimer
    interval: 2000
    repeat: false
    onTriggered: notificationSubscription.running = true
}
```

### WR-04: `grep -q` under `pipefail` — the documented SIGPIPE gate-flip pattern

**File:** `theme-engine/.config/theme-engine/lib/reload.sh:148`
**Issue:** `if command -v ags >/dev/null 2>&1 && ags list 2>/dev/null | grep -qx 'media'; then` runs inside `theme_engine_reload()`, which executes under `theme-apply`'s `set -euo pipefail` (confirmed by this same file's sibling, `wallpaper.sh`, which explicitly notes its own functions run "under `set -euo pipefail`"). This is the exact `command | grep -q` + `pipefail` pattern that has already caused a gate-verdict flip elsewhere in this repo (documented precedent: `grep -q` can make the left-hand command exit 141 on SIGPIPE once a match is found, and `pipefail` propagates that non-zero code even though the match succeeded) — the outcome depends on how many lines `ags list` prints before the match, i.e. on how many instances are registered, not on program correctness. Today this repo runs exactly one AGS instance (`media`), so the match is very likely the first and only line and the race is unlikely to trigger in practice — but the pattern is present and will silently start misbehaving the moment a second AGS instance is ever registered (this exact scenario — "flipping a gate's verdict by [output] length" — is the documented lesson from the prior incident).
**Fix:**
```diff
-    if command -v ags >/dev/null 2>&1 && ags list 2>/dev/null | grep -qx 'media'; then
+    if command -v ags >/dev/null 2>&1; then
+        local ags_instances
+        ags_instances="$(ags list 2>/dev/null)"
+        if grep -qx 'media' <<<"$ags_instances"; then
+            ags request -i media reload-css 2>/dev/null || true
+        fi
+    fi
```

### WR-05: `BrightnessBackend.qml`'s device flag contradicts its own documented convention

**File:** `quickshell/.config/quickshell/modules/bar/BrightnessBackend.qml:56-59,138`
**Issue:** The file's header states, as a deliberate security discipline: *"The class and device flags are spelled out in their LONG form (`--class`/`--device` rather than `-c`/`-d`) deliberately: the short `-c` form... is textually indistinguishable from a shell interpreter's own `-c` flag."* The probe process (line 103) correctly uses `--class`. The adjust process (line 138) uses `--class` for the class flag but `-d` (short form) for the device flag: `command: ["brightnessctl", "-m", "--class", root.deviceClass, "-d", root.deviceName, "set", root._adjustDeltaForm]`. This is not currently exploitable (fixed argv array, no shell interpolation anywhere in the path), but the code no longer matches the audit claim the comment makes about itself, which is exactly the kind of drift that lets a future auditor trust a stale invariant.
**Fix:**
```diff
-        command: ["brightnessctl", "-m", "--class", root.deviceClass, "-d", root.deviceName, "set", root._adjustDeltaForm]
+        command: ["brightnessctl", "-m", "--class", root.deviceClass, "--device", root.deviceName, "set", root._adjustDeltaForm]
```

## Info

### IN-01: `PopoutController.entryMoved` doesn't share `entryEntered`/`entryExited`'s pinned-section guard

**File:** `quickshell/.config/quickshell/modules/bar/PopoutController.qml:224-231`
**Issue:** `entryEntered` and `entryExited` both return early when `root.pinnedSection !== ""` (lines 212-213, 234-235), but `entryMoved` has no equivalent guard. In practice this is harmless — a stray `dwellTimer.restart()` fired while a popout is pinned is caught by `dwellTimer`'s own re-check in `onTriggered` (`root.pinnedSection !== ""` returns early there too, line 173) — but the asymmetry means a reader skimming the three `entryX` functions for "does this respect pinning" will get the wrong answer for `entryMoved` without reading the timer's own body too.
**Fix:** Add the same early-return guard to `entryMoved` for readability, even though it is not currently reachable as a functional bug:
```qml
function entryMoved(sectionId) {
    if (root.pinnedSection !== "")
        return;
    root.pointerMovedSinceSettle = true;
    ...
}
```

### IN-02: Redundant one-to-one `STATUS` → `target` mapping in `bar-visibility.sh`

**File:** `hypr/.config/hypr/scripts/bar-visibility.sh:278-283`
**Issue:** `_actuate()`'s `case "$STATUS" in visible) target="visible" ;; hidden-idle) target="hidden-idle" ;; hidden-hard) target="hidden-hard" ;; esac` maps every value of `STATUS` to an identical string in `target` — `_compute()` only ever produces these three values, so this is a no-op relabeling with no `*)` default. Not a bug (there's no fourth `STATUS` value that could reach an unset `target`), just dead complexity that could be replaced with `local target="$STATUS"`.
**Fix:** `local target="$STATUS"` in place of the `case` block, if a future edit touches this function anyway.

---

_Reviewed: 2026-08-12T20:45:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
