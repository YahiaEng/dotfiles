# Phase 20: Indicators & Power Menu - Research

**Researched:** 2026-08-15
**Domain:** Quickshell/QML layer-shell surfaces (transient OSD, modal session dialog), Linux sysfs LED introspection, systemd/uwsm session teardown, Hyprland layer-rule ordering
**Confidence:** MEDIUM-HIGH — every claim below is tagged with its verification method; the one genuinely unresolved item (sysfs-LED inotify support) is flagged LOW/needs-live-test, not asserted.

## Summary

This phase is almost entirely a *reuse* exercise, not a *build-from-scratch* one. `Toast.qml` (read in full this session) already has the exact chrome the OSD needs; `PanelDialog.qml` (read in full) already has the exact focus-grab/cascade/rim pattern the power menu needs; `AudioBackend.qml` and `BrightnessBackend.qml` (both read this session) already expose the absolute setters (`setMasterVolume`, `setInputVolume`, `setPercent`) the sliders need to write through — **`BrightnessBackend.setPercent()` already exists** (Phase 19 Plan 05, Task 3), contradicting the UI-SPEC's hedge that an absolute setter is still pending. Nothing here needs a new backend, a new subprocess, or a new privilege boundary: audio goes through native `Quickshell.Services.Pipewire` bindings (no subprocess at all), brightness goes through `brightnessctl` exactly as it already does for the bar's scroll gesture, and Caps Lock goes through a plain world-readable sysfs file exactly as CONTEXT.md's D-20-13 already confirmed.

The two areas needing real judgment, not just wiring, are: (1) whether the sysfs LED brightness attribute actually emits a change notification a `FileView{watchChanges:true}` can catch — the kernel-level mechanism for this exists and is documented (LED core's `led_notify_brightness_change`, merged for exactly this poll/inotify use case), but this session could not execute a live test (no passwordless sudo, no way to safely simulate a hardware LED toggle) so this is CITED, not VERIFIED, and the plan must carry one explicit live-test task; and (2) whether `hyprshutdown --post-cmd 'uwsm stop'` does anything for Logout beyond what a plain graceful compositor exit already does — live inspection of this host's actual systemd unit topology (`wayland-wm@hyprland.desktop.service`, chained through `wayland-session@hyprland.desktop.target` / `graphical-session.target`) strongly suggests systemd's own `BindsTo`-style cascade already tears the session down the moment Hyprland's PID exits, meaning the specific string in D-20-37 (bare `uwsm stop`, no `-r`) most likely finds nothing left to do. This is not a reason to override the locked decision — it is a reason to record the composition honestly as "wrapped, evidence points to low-impact, not independently verified" rather than as a confirmed fix.

A genuine, concrete implementation trap was found and is not yet named anywhere in CONTEXT.md/UI-SPEC.md: `windowrules.lua`'s existing `ignore_alpha` override for the notification family (`quickshell-notif-toast` among them) sits at **0.2**, declared in a block *after* the family's own 0.5 floor (lines 560-565). D-20-33 mandates the OSD render under a **brand-new** namespace `quickshell-osd`, which does **not** inherit that 0.2 override — it inherits only the family's 0.5 floor unless a new `quickshell-osd` override row is added in the same commit. Toast.qml's current fill (`BarRoles.notifSurface`, alpha 0.38) was tuned specifically to clear 0.2, not 0.5 — reused unchanged under the new namespace, it would sit *below* the new floor and silently lose blur, the exact "reads like a wrong alpha" failure this repo has hit before (see `hyprctl reload drops layer rules` in project memory). This is D-20-34's own concern, made concrete with the real numbers.

**Primary recommendation:** Build both surfaces exactly as CONTEXT.md/UI-SPEC.md already specify — nothing here contradicts a locked decision — but the plan must (a) add explicit `quickshell-osd`/`quickshell-session` `ignore_alpha` override rows sized against Toast.qml's actual 0.38 fill (not just add `animation` rows and assume the family floor is enough), (b) carry one live-test task for the sysfs LED watch mechanism before treating QOSD-02 as done, and (c) record the hyprshutdown/uwsm-stop composition as "wrapped, not measured, evidence suggests low marginal effect" rather than as a settled fix.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| OSD trigger/display (volume/mic/brightness/caps) | Browser/Client (Quickshell QML, `PanelWindow` layer-shell surface) | — | Pure client-side rendering reacting to backend singleton state; no server round-trip |
| Volume/mic read+write | Browser/Client (native `Quickshell.Services.Pipewire` binding) | — | In-process PipeWire client API, not a subprocess — verified this session (`AudioBackend.qml:35` imports `Quickshell.Services.Pipewire`) |
| Brightness read+write | Browser/Client (Quickshell `Process` wrapping `brightnessctl`) | — | No daemon; a short-lived CLI subprocess per adjustment, single-flighted |
| Caps Lock read | Browser/Client (Quickshell `FileView` reading kernel sysfs) | Kernel (LED classdev / input-leds driver) | No service, no daemon, no D-Bus — a world-readable file under `/sys/class/leds/` |
| Power menu display + focus | Browser/Client (Quickshell QML, modal `PanelWindow`) | — | Same tier as the OSD; no server component |
| Session-ending actions (shutdown/reboot/suspend/hibernate/logout/lock) | Browser/Client dispatch → Compositor (Hyprland) → systemd/logind | — | QML issues `Process` calls to `hyprshutdown`/`systemctl`/`uwsm`; the actual state transition is owned by systemd-logind and the kernel, outside this shell entirely |
| Package-manager-busy / download / toplevel-count detectors | Browser/Client (Quickshell `Process` polling `pgrep`/`find`/hyprctl) | — | All three detectors are cheap, synchronous, client-launched child processes, not a service |

## Package Legitimacy Audit

**Not applicable — this phase installs no new packages.** Every tool this phase's implementation touches (`brightnessctl`, `wpctl`/PipeWire QML bindings, `hyprshutdown`, `uwsm`, `pgrep`) is already installed and already in production use elsewhere in this repo (verified below). The phase's only package-manager actions are **removals**: `swayosd`, `wleave`, `wlogout`, `eww` — all four confirmed still present via `pacman -Qi` this session (see Retirement section). No `npm view`/`pip index`/`cargo search` verification applies; this is not an npm/pypi/cargo ecosystem phase.

## Priority Research Findings (answers to the 9 blocking questions)

### 1. D-20-38 — is `hyprshutdown --post-cmd 'uwsm stop'` meaningful for Logout?

**Verification method:** live `hyprshutdown --help` [VERIFIED: `/usr/bin/hyprshutdown` `--help` output, this session], live `uwsm --help`/`uwsm stop --help` [VERIFIED: `/usr/bin/uwsm` `--help` output, this session], live `systemctl --user list-units --all` on this host [VERIFIED: this session, host `arch`].

**What `hyprshutdown` actually does** (from its own `--help`, quoted verbatim):
```
--post-cmd  -p [str]  | Set a command ran after all apps and Hyprland shut down
```
So `hyprshutdown -p '<cmd>'` = wait for apps to close gracefully → exit the Hyprland compositor process itself → **then** run `<cmd>`. This is unambiguous: `<cmd>` runs strictly after Hyprland's own process has already exited.

**What this host's actual systemd session topology looks like** (`systemctl --user list-units --all`, quoted, trimmed to the relevant chain):
```
wayland-wm@hyprland.desktop.service          loaded active running   Main service for Hyprland...
wayland-session-bindpid@1542.service         loaded active running   Bind graphical session to PID 1542
wayland-session-envelope@hyprland.desktop.target   loaded active active
wayland-session-pre@hyprland.desktop.target        loaded active active
wayland-session-xdg-autostart@hyprland.desktop.target  loaded active active
wayland-session@hyprland.desktop.target            loaded active active
graphical-session-pre.target                       loaded active active
graphical-session.target                           loaded active active
wayland-session-shutdown.target                    loaded inactive dead   Shutdown graphical session units
app-graphical.slice                                loaded active active   User Graphical Application Slice
```
`wayland-wm@hyprland.desktop.service` is a **real systemd service** (not transient), with `wayland-session-bindpid@1542.service` explicitly binding the session to Hyprland's own PID. This is uwsm's whole design: the Wayland session's systemd unit graph is bound to the compositor process's lifetime via unit dependencies (`BindsTo`/`PartOf`-style chains through the `wayland-session-*@hyprland.desktop.target` units up to `graphical-session.target`). There is also a dedicated `wayland-session-shutdown.target` that exists specifically to fire cleanup units when the session ends.

**Reasoned conclusion (MEDIUM confidence — not independently measured by running an actual logout, since doing so would end this research session):** When `hyprshutdown` causes Hyprland's process to exit gracefully, systemd's own unit-dependency graph almost certainly already cascades `wayland-wm@hyprland.desktop.service` → `wayland-session-bindpid@...` → every `wayland-session-*@hyprland.desktop.target` → `graphical-session.target` down to inactive, **without any external command** — that is the entire point of uwsm's architecture (its own `--help` describes it as providing "clean shutdown" via systemd unit management, keyed off the compositor's own lifecycle). `uwsm stop`'s own `--help` text is: *"Stops compositor and optionally removes generated units."* Two things follow:
- The **"stops compositor"** half is very likely already accomplished by hyprshutdown's own graceful exit — `uwsm stop` running *after* Hyprland has already exited (as `--post-cmd` guarantees) would find the compositor already stopped.
- The **"removes generated units"** half is gated behind the `-r` flag, which **D-20-37's exact target string does not pass** (`hyprshutdown --post-cmd 'uwsm stop'`, no `-r`). Generated unit files live under `/run/user/$UID/systemd/` by default (`uwsm stop`'s own `-U {run,home}` flag, default `run`) — a tmpfs that is cleared at reboot regardless, but is **not** cleared merely by the compositor process exiting.

**Bottom line for the planner:** the composition is very likely a **low-risk, low-marginal-effect no-op or near-no-op** as literally specified — not "actively conflicting" (nothing suggests it errors or fights hyprshutdown), but also not demonstrated to close the D-29 hazard the way D-20-37's framing implies. This matches D-20-37's own instruction to record it as *"wrapped without measurement… the hazard remains neither confirmed nor falsified."* **Do not silently upgrade the target string to `uwsm stop -r`** — that changes a locked decision's literal content; if the planner or user wants the "removes generated units" behavior, that is a new, explicit decision to make outside this research, not something to fold in here.

**Contradiction flag for planner/user:** D-20-37 frames wrapping Logout as closing "the hazard… by construction." Live topology evidence suggests the wrap is closer to a harmless formality than a construction-level fix, because the mechanism it invokes most likely has nothing left to do by the time it runs. This does not block D-20-37 — the locked decision explicitly already accepts this uncertainty ("neither confirmed nor falsified") — but the planner should not describe the resulting behavior as stronger than what this evidence supports.

### 2. Caps Lock via sysfs — node enumeration, permissions, and watchability

**Verification method:** live `ls`/`stat`/`cat` against `/sys/class/leds/` [VERIFIED: this session, host `arch`, 2026-08-15 18:0x local], `udevadm info -a` [VERIFIED: this session], live `select.poll()` test script [ATTEMPTED, INCONCLUSIVE — see below], WebSearch of kernel LED-class documentation and mailing-list history [CITED].

**Live node enumeration (this session, differs from CONTEXT.md's 2026-08-14 finding — confirms D-20-14's premise):**
```
/sys/class/leds/input33::capslock -> .../0003:1B1C:1B73.0015/input/input33/input33::capslock
```
Only **one** node exists right now (not the `input5::capslock` CONTEXT.md recorded on 2026-08-14, and not the "two keyboards" scenario D-20-15 describes — only one keyboard reports a caps-lock LED node in this session's `hyprctl devices -j` sweep, though multiple keyboards do carry a `capsLock` boolean field). **This is itself the D-20-14 finding, freshly reconfirmed less than 24 hours later: the kernel input index (`input33` here, `input5` on 2026-08-14) genuinely changes across reboots**, exactly as D-20-14 assumes. The glob-at-startup, re-glob-on-failure design is validated by this repeat observation, not merely theorized.

- **Permissions** [VERIFIED]: `stat -c '%a %U:%G'` → `644 root:root`. `cat` as the unprivileged `aorus` user succeeds and returns `0` with no `sudo`. World-readable, confirmed live, no root service needed to *read* it.
- **`udevadm info -a`** [VERIFIED] confirms this LED is bound to the kernel's own `kbd-capslock` trigger (`ATTR{trigger}=="...[kbd-capslock]..."`) — i.e., this is the standard `input-leds.c` kernel driver path, not a vendor-specific mechanism, which is relevant to whether the notification chain below applies generically.

**Watchability — the genuinely open item.** A `select.poll()` test script (POLLPRI on the open fd, the canonical sysfs-attribute-change idiom) was written and run this session, with an attempt to trigger a brightness write via `sudo`. **Both trigger attempts failed** (`sudo: a password is required` — no NOPASSWD rule for this command on this host), so the poll test timed out with no events after 8s — **this is inconclusive, not a negative result**: the write never happened, so there was nothing for poll to detect. `wtype` is installed but sends a *virtual* keyboard event (Wayland virtual-keyboard protocol), which does not reach the kernel's real evdev/LED-classdev path the same way a physical key does — using it would not have produced a trustworthy answer even if tried.

WebSearch of kernel documentation found (CITED, not locally verified): a mainline kernel patch series, *"leds: core: Add support for poll()ing the sysfs brightness attr for changes"* (Hans de Goede, merged upstream), which added `led_notify_brightness_change()` specifically so that **the standard `brightness` sysfs attribute** (not just the separate `brightness_hw_changed` attribute) supports `poll()`-based change notification — the ABI doc (`Documentation/ABI/testing/sysfs-class-led`) documents this explicitly. Separately, kernel mailing-list history confirms kernfs (the framework backing sysfs) **does** bridge `sysfs_notify()`/`kernfs_notify()` calls into genuine `fsnotify`/inotify `FS_MODIFY` events, not only into raw `poll()` wakeups — meaning both the `poll()`-based mechanism and Qt's `QFileSystemWatcher` (which is inotify-based on Linux) have a documented code path to fire.

**Chained reasoning (MEDIUM confidence, CITED — not measured on this host):** LED brightness change (caps lock toggling) → LED classdev core calls its notify helper → `sysfs_notify()`/`kernfs_notify()` → fsnotify `FS_MODIFY` event → inotify `IN_MODIFY` fires → Qt's `QFileSystemWatcher` (inotify-backed on Linux) detects it → Quickshell's `FileView{watchChanges:true}` fires `onFileChanged`. Every link in this chain is independently documented; none was independently exercised live on this host this session.

**Recommendation — do not treat this as settled.** Add one explicit live-verify task to the plan, run once real Caps Lock hardware is available to press (not simulated): open the LED brightness file with `FileView{watchChanges:true}`, press physical Caps Lock, confirm `onFileChanged` fires. **If it does not fire**, the fallback the phase must use is a lightweight poll (a `Timer` reading the file every N hundred ms while nothing else needs to run) — which would cost the phase its zero-idle claim for exactly this one indicator and should be flagged back to the user as a scope conversation, not silently substituted. Given the standing "measure, don't assume" pattern this project already uses for D-20-17/D-20-19, this is the natural third item to fold into that same GATE-01 measurement pass rather than treating it as separately resolved by citation alone.

**Quickshell mechanism, exact API** [VERIFIED: `quickshell/.config/quickshell/modules/bar/ClockActionsCapsule.qml:586-592`, quoted verbatim]:
```qml
FileView {
    id: gamingStateFile
    path: clockActionsCapsule.homeDir + "/.cache/gaming-mode"
    watchChanges: true
    onFileChanged: reload()
}
readonly property string gamingRaw: (gamingStateFile.text() || "").trim()
```
This is the exact shape to copy for the Caps Lock `FileView` — same file, same repo, already production-proven for a *different* watched file (not sysfs, a regular file — this precedent does not itself prove sysfs watchability, only the QML idiom). Quickshell version installed: `0.3.0-2` [VERIFIED: `pacman -Qi quickshell`]. `/usr/lib/qt6/qml/Quickshell/Io/FileView.qml` [VERIFIED, read this session] is a thin QML wrapper (`FileViewInternal` subclass) exposing `path`, `preload`, `watchChanges`(via the C++ side, not shown in the QML shim itself), `.text()`, `.data()` — the actual watch implementation is native C++, not introspectable from this QML file alone.

### 3. The three package-manager-busy detectors (D-20-27)

**Verification method:** live execution of each detector's exact command [VERIFIED, this session].

1. **`pgrep -x pacman` / `pgrep -x paru` / `pgrep -x yay`** — all three tested live, all exit `1` (not running) as expected when idle; `pacman`/`paru` are installed (`yay` is not installed on this host — confirmed absent, irrelevant since the check is "is it running," not "is it installed"). Timing: `time (pgrep -x pacman >/dev/null)` → **0.016s wall**, negligible cost for a low-frequency `Timer` poll while the menu is visible (D-20-30). False-positive behavior: `pgrep -x` matches on exact process name only, so a process merely named similarly would not false-positive; a genuinely-running pacman/paru process (even one waiting on a lock) would true-positive correctly, matching D-20-27's own "not `/var/lib/pacman/db.lck`" reasoning — `pgrep` on the process itself, not the lock file, is confirmed as the more conservative signal live.
2. **Active downloads heuristic** — `~/Downloads` exists and currently contains two ordinary files, no `.part`/`.crdownload` files present [VERIFIED: `find ~/Downloads -maxdepth 1 -iname "*.part" -o -iname "*.crdownload"` returns empty]. The heuristic is implementable as a cheap `find`/`Process` check exactly as D-20-27 describes; this session confirms the directory exists and the glob pattern returns cleanly (no false positive at rest).
3. **Toplevel count against a window-class deny-list** — not independently re-verified this session beyond confirming `hyprctl` is the standard mechanism for toplevel enumeration on this host (already used elsewhere in this repo, e.g. `powerAvailabilityProbe`'s sibling checks). D-20-27 itself already records this is a hand-maintained list, not a real detector — no further verification changes that framing.

All three are cheap, synchronous, non-blocking `Process` calls suitable for a `Timer`-gated poll while the power menu is visible, consistent with D-20-30.

### 4. Brightness + microphone control paths (QOSD-04, D-20-09)

**Verification method:** full read of `AudioBackend.qml` and `BrightnessBackend.qml` [VERIFIED, this session, exact line numbers below], live `wpctl status`/`brightnessctl -l` [VERIFIED, this session].

- **Audio (volume + mic):** `AudioBackend.qml` [VERIFIED, read this session] imports `Quickshell.Services.Pipewire` (line 35) and exposes `masterVolume`/`masterMuted`/`inputVolume`/`inputMuted` as reactive properties (lines 65-68) bound directly to `Pipewire.defaultAudioSink`/`defaultAudioSource`, plus **existing** write functions `setMasterVolume(v)` (line 73), `setMasterMuted(on)` (line 77), `setInputVolume(v)` (line 81), `setInputMuted(on)` (line 85). **No subprocess anywhere in this file** — this is a native PipeWire client binding, so **no privileges are needed** and no `wpctl` shelling-out occurs (the `wpctl status`/`get-volume` output pulled live this session is for host cross-reference only, confirming PipeWire/WirePlumber `1.6.8` is actually running with a real default sink at 65% and default source at 34% — the values these bindings would read).
- **Brightness:** `BrightnessBackend.qml` [VERIFIED, read in full this session, 247 lines] is a `pragma Singleton` wrapping `brightnessctl` via `Quickshell.Io.Process`, single-flighted with a coalescing pending-delta/pending-absolute mechanism. **`setPercent(percent)` already exists** (lines 234-244, added "Phase 19 Plan 05, Task 3" per its own header comment) — clamps 0-100, guarded by the same presence probe and single-flight discipline as the existing `adjust(steps)` verb. **This directly contradicts 20-UI-SPEC.md's hedge** ("once `BrightnessBackend` gains an absolute setter, an implementation-time call") — the setter is not pending, it is already shipped and already consumed by the notification centre's own slider (per the setter's own header comment). **The planner needs no new brightness-backend work for QOSD-04's write path at all**, only wiring the existing `setPercent()` into the OSD's slider `onMoved`/drag handler.
- **Critical host-specific caveat, live-verified:** `brightnessctl -l` on this host lists **zero backlight-class devices** — only LED-class devices (`input33::capslock`, three `enp5s0-*::lan` link LEDs, `input33::scrolllock`). `BrightnessBackend.qml`'s own header comment (lines 1-19) already documents this precisely: `deviceClass: "backlight"` is production-correct code that is **present-but-inert on this host**, matching the exact D-18-39 precedent already applied to the bar's own brightness capsule (and the same precedent GATE-02's Gate A criterion B.3 already marked NOT-DEMONSTRABLE for this exact reason). **Consequence for GATE-02 Gate A:** the OSD's brightness row cannot be demonstrated live on this host either — the planner should pre-empt this by citing the existing NOT-DEMONSTRABLE precedent rather than treating it as a new gap discovered mid-gate.

### 5. Layer namespaces + `ignore_alpha` — exact insertion point and the real trap

**Verification method:** full read of `windowrules.lua` lines 360-565 [VERIFIED, this session, exact line numbers below].

- **Family regex, confirmed exact lines** (matches CONTEXT.md's citation): `hl.layer_rule({ match = { namespace = "^quickshell-.*" }, blur = true })` at **line 396**; `hl.layer_rule({ match = { namespace = "^quickshell-.*" }, ignore_alpha = 0.5 })` at **line 445**.
- **Worked precedent, confirmed exact lines**: the three notification-family exact-match `animation = "slide"` rows sit at **lines 524-526**, declared after the family regex and after `quickshell-overview`'s own late pair (lines 499-500), per this file's own documented ordering finding (an inline comment records that `hyprctl reload` — not `hyprctl eval` — silently drops layer-rule edits on this build, and that a namespace rule contradicting the family regex loses if declared *before* it).
- **The concrete trap, not previously named in CONTEXT.md/UI-SPEC.md at this level of detail:** a **second**, later block overrides `ignore_alpha` for the three existing notification namespaces (`quickshell-notif-popups`, `quickshell-notif-centre`, `quickshell-notif-toast`) down from the family's 0.5 to **0.2**, at **lines 560-565** (declared last in the file, deliberately, per the same "later wins" ordering rule, with an explanatory comment: *"Round 8 sets those alphas to 0.38 resting / 0.52 hover, both comfortably clear of 0.2"*). **`Toast.qml`'s current fill is `BarRoles.notifSurface` at alpha 0.38** [VERIFIED: `BarRoles.qml:131`, `readonly property color notifSurface: Qt.rgba(..., 0.38)`], tuned specifically against that 0.2 override.

  D-20-33 mandates the OSD render under a **new, distinct** namespace `quickshell-osd` — it does **not** inherit the `quickshell-notif-toast` 0.2 override; a fresh namespace only inherits the family's own **0.5** floor unless the plan adds a matching override row. **0.38 < 0.5** — if Toast.qml's existing fill is reused unchanged (as D-20-02/UI-SPEC's "reused verbatim" instruction implies) under the new `quickshell-osd` namespace with only the family floor active, the region falls *below* the cutoff and blur silently turns off, reading exactly like "the alpha is wrong" when the real cause is a namespace that never got its own override row. **This is D-20-34's own concern ("pinned at or above the floor its own rule declares, in the same commit"), now with the specific numbers that make it concrete**: the plan must add `hl.layer_rule({ match = { namespace = "quickshell-osd" }, ignore_alpha = 0.2 })` (matching the existing notif-family precedent, since it reuses the same fill value) in the **same commit** as the `quickshell-osd` `animation` row, placed in the same late/last-declared block as lines 560-565 — not merely relying on the family's 0.5. The same reasoning applies to `quickshell-session`: whatever alpha the power dialog's card background resolves to (`Colours.surface` at `panelSurfaceOpacity` 0.78, per UI-SPEC — comfortably above 0.5, so the family floor alone is likely sufficient there) must be checked against whichever floor actually applies before assuming so.
- **`hyprctl reload` vs `hyprctl eval`** [VERIFIED via this file's own inline documentation, not independently re-tested this session — the finding is already load-bearing project history per user memory `hyprctl reload drops layer rules`]: any layer-rule edit in this phase needs `hyprctl eval '<rule>'` applied to the running session, or a full Hyprland restart — `hyprctl reload` will silently no-op the change and make correctly-written rules look broken during the gate.

### 6. GATE-01 baseline inputs

**Verification method:** direct file reads and `pacman -Qi`/`systemctl status` [VERIFIED, this session].

- **`swayosd/.config/swayosd/style.css`** [VERIFIED, read in full, 48 lines]: bottom-center pill via layer-shell built-ins (not CSS-configurable, per the file's own header comment), `#container` background `alpha(@background, 0.85)`, `16px` margin/padding, `999px` border-radius (full pill), icon scaled `1.2x`, label `FiraCode Nerd Font` 16px, progress track `alpha(@surface_variant, 0.6)` at `6px` min-height, fill `@primary` solid.
- **`swayosd-libinput-backend.service`** [VERIFIED, this session]: **enabled and actively running** system-level unit (`Loaded: loaded ... enabled; preset: disabled`, `Active: active (running) since Sat 2026-08-15 17:11:23 EEST`, PID 1318, invoked from `/usr/lib/systemd/system/swayosd-libinput-backend.service`, symlinked under `graphical.target.wants/`). This confirms D-20-17's premise (system-level enablement, independent of the Hyprland session) but **does not itself answer** whether it produces visible feedback at the SDDM prompt — that remains the one live measurement GATE-01 must still take (cannot be done from within an already-running session).
- **`swayosd-server` autostart, confirmed exact line**: `hl.exec_cmd("uwsm app -- swayosd-server")` at **`autostart.lua:192`** [VERIFIED, matches CONTEXT.md's citation exactly], preceded by comments at lines 185/190 distinguishing the libinput backend ("handled separately by the packaged... service") from the GTK client started per-session.
- **`wleave/.config/wleave/layout.json`** [VERIFIED, read in full — this is the authoritative source for D-20-26's migration, quoted verbatim]:
  ```json
  { "label": "lock", "action": "uwsm app -- hyprlock", "text": "Lock", "keybind": "l" }
  { "label": "logout", "action": "cliphist wipe; uwsm stop", "text": "Log Out", "keybind": "e" }
  { "label": "suspend", "action": "systemctl suspend", "text": "Suspend", "keybind": "u" }
  { "label": "hibernate", "action": "systemctl hibernate", "text": "Hibernate", "keybind": "h" }
  { "label": "reboot", "action": "cliphist wipe; hyprshutdown --post-cmd 'systemctl reboot'", "text": "Reboot", "keybind": "r" }
  { "label": "shutdown", "action": "cliphist wipe; hyprshutdown --post-cmd 'systemctl poweroff'", "text": "Shut Down", "keybind": "s" }
  ```
  **Important, previously-unstated detail: the CURRENT Logout action does not use `hyprshutdown` at all** — it is `cliphist wipe; uwsm stop`, bare. D-20-37's proposed new shape (`cliphist wipe; hyprshutdown --post-cmd 'uwsm stop'`) is a genuine *addition* of the hyprshutdown wrapper to Logout, not a re-composition of an existing wrap — consistent with CONTEXT.md's framing, now confirmed against the literal current string rather than assumed.
  Also confirmed: `buttons-per-row: 6`, `show-keybinds: false` (matches D-20-24's "undisplayed" claim), `margin: 36.4%`, `column-spacing: 24`.
- **`wlogout` / `eww`** [VERIFIED, `pacman -Qi` this session]: both still installed. `wlogout 1.2.2-0` (installed 2026-03-24, Explicitly installed). `eww 0.6.0-1` (installed 2026-07-14, Explicitly installed, has an install script). Both confirmed live targets for RETIRE-07.
- **Six action command strings — "only in layout.json" claim, verified**: no other file in the repo defines these six strings; `wleave.sh` (the launcher) only execs `wleave`, it does not itself carry the action strings — confirmed by the layout.json read above being the sole source. D-20-26's premise holds.

### 7. LEDGER-05 — the live WINDOWS.md ledger

**Verification method:** direct read of frontmatter and grep across the full file [VERIFIED, this session].

- **Frontmatter, confirmed exact**: `open_count: 51`, `fixed_count: 24`, `total_count: 75`, `last_updated: 2026-08-13T12:43:20.122Z` — matches D-20-39's claim exactly (the requirement text's "16" is confirmed stale).
- **Rows touching this phase's named surfaces** (`grep -n "swayosd\|wleave\|wlogout\|eww" WINDOWS.md`, status column checked per row):
  - **Row 3** (phase 09, `wleave/.config/wleave/style.css`, status `open`) — D-10 entrance-vs-hover interaction never exercised live (no synthetic-pointer tool could land inside the ~350ms stagger window).
  - **Row 4** (phase 09, `09-03-SUMMARY.md`, status `open`) — hover evidence was captured via keyboard focus (`wtype` Tab), not literal mouse hover; `:hover`/`:focus` are byte-identical selectors so the code path is proven, but the input modality is not.
  - **Row 5** (phase 09, `wleave/.config/wleave/layout.json`, status `open`) — icon glyph size is SVG natural/shrink-fit (~27-29px), not pinned to the UI-SPEC's literal 36px token.
  - **Row 6** (phase 09, `hypr/.config/hypr/scripts/wleave.sh`, status `open`) — fault-injection gap: moving the user's `layout.json` aside does not trigger the wrapper's failure notification; wleave silently falls back to its packaged `/etc/wleave/layout.json` instead.
  - **Row 10** (phase 13, `windowrules.lua`, status `open`) — D-06 boundary correction: layer-surface *exit* animations (walker/swaync/wleave) are client-owned, not compositor-owned; closed on mechanical proof rather than a valid render-gate instrument.
  - **No swayosd-specific or wlogout/eww-specific row exists** — the only `eww` mention in the whole file is row 1 (`fixed`, an orphaned `eww.scss` contract entry from Phase 08/10, already resolved 2026-07-27).
  - **Row 74** (phase 19, `Toast.qml`, status `open`) — **directly relevant to this phase's reuse of Toast.qml**: *"Task 3 human-check not run interactively: visually confirming the toast slides in top-centre with correct on/off copy, self-dismisses after ~2s, and two rapid toggles produce one toast not two — DND was flipped by directly editing the state file, never exercising the real `toggleDnd()`/`dndToggled`/`show()` path."* Since the OSD instance shares this exact `show()`/timer/self-dismiss mechanism, this phase's own GATE-02 Gate A checks (hover-pause, auto-hide) can double as the closure evidence for row 74, if the planner chooses to fold it in — flagged here rather than left for LEDGER-05's batch triage to rediscover independently.
- **Total: 5 rows individually named per D-20-40's triage scope (3, 4, 5, 6, 10)** — plus row 74 as a bonus find directly relevant to this phase's own reused frame. The remaining ~45 rows (51 − 5 − 1 already batched by this research's read, i.e. the D-20-40 "remainder") batch re-defer as CONTEXT.md's D-20-40 already specifies.

### 8. Phase 19 reuse surfaces — exact current shape

**Verification method:** full file reads [VERIFIED, this session — see full quoted excerpts in the two Read tool calls above].

- **`Toast.qml`** [VERIFIED, 193 lines, read in full]: `PanelWindow`, hardcodes `anchors.top: true` (line 96), `WlrLayershell.namespace: "quickshell-notif-toast"` (line 101, literal string — confirms D-20-33's "third property" gap the checker already flagged), `WlrLayershell.keyboardFocus: WlrKeyboardFocus.None` + `focusable: false` (lines 103-104, confirms D-20-02's `interactive` property does not exist yet and needs an actual `MouseArea`/`HoverHandler` added, not just a boolean flip), `Design.notifToastDurationMs` hardcoded directly into the `Timer.interval` (line 82 — confirms this must become an instance-settable property for `osdHideDelayMs` to work, not a second hardcoded constant), `show()`/`hide()` functions exactly as UI-SPEC describes (replace-in-place, no stacking, no replay-on-already-active), chrome via `BarRoles.notifSurface`/`GradientBorder`/`Design.popoutCornerRadius` (uniform rounding, all four corners) exactly as UI-SPEC states, content slot `default property alias body: bodyRow.data` (line 50) confirmed generic.
- **`PanelDialog.qml`** [VERIFIED, 393 lines, read in full]: `headerHeight: 72` (line 72), `cornerRadius: 28` (line 74), `panelSurfaceOpacity: 0.78` (line 154), `disabledOpacity: 0.38` (declared locally inside the Advanced-button `Item`, line 287 — NOT a `Design.qml` token, matches the UI-SPEC's own "Reused Tokens" correction about `lineHeightTight`/`lineHeightNormal` also being local, not `Design.qml`, tokens at lines 149-150), `HyprlandFocusGrab{ windows: [panelWindow]; active: true; onCleared: panelWindow.requestDismiss() }` (lines 203-208), `WlrKeyboardFocus.OnDemand` (line 131 — **not** `Exclusive`, confirming D-20-24's divergence is real and deliberate, not accidental), `Cascade{}` component with `.bands = [...]`, `.armed = true`, `.run()` (lines 213-219, and the standalone `Cascade.qml` component confirmed at `modules/dashboard/Cascade.qml` exposing exactly `bands`/`armed`/`run()`), anchors-top-only + bottom-only rounding (lines 123, 164-167 — the power menu's UI-SPEC-mandated full-screen-centered/uniform-corners geometry is a genuine, correctly-flagged divergence from this frame's own layer posture, not a copy).
- **`Design.qml` tokens** [VERIFIED via grep, this session]: `notifSurfaceWidth: 430` (line 417, confirms the 380px OSD width is deliberately narrower as UI-SPEC states), `notifToastDurationMs: 2000` (line 468), `popoutCornerRadius: 20` (line 371), `barSideMargin: 10` (line 155). **None of the seven new tokens UI-SPEC proposes** (`osdWidth`, `osdHideDelayMs`, `osdRecencyWindowMs`, `sessionDialogWidth`, `sessionTileWidth`, `sessionTileHeight`, `sessionTileRadius`, `sessionTileIconSize`, `sessionScrimOpacity`) **currently exist** — confirmed genuinely new, not an accidental redeclaration.
- **`BarRoles.qml` tokens** [VERIFIED via grep, this session]: `capsuleTrack` (line 71), `accent: Colours.primary` / `onAccent: Colours.onPrimary` (lines 76-77), `warn: Colours.tertiary` (line 78), `danger: Colours.error` / `onDanger: Colours.onError` (lines 79-80), `notifSurface` (0.38 alpha, line 131) / `notifSurfaceFg` / `notifSurfaceHover` (0.52 alpha, line 133). **`onWarn` does not currently exist** — confirmed genuinely new, matches UI-SPEC's claim exactly.
- **`Colours.qml` tokens** [VERIFIED via grep, this session]: `surface`/`onSurface`/`surfaceVariant`/`onSurfaceVariant`/`tertiary`/`onTertiary` all exist as `readonly property alias` entries pointing into a `JsonAdapter`-backed base/on-roles pair (confirmed the file's own documented X/onX singleton-collision workaround pattern, referenced in project decision history, is why these are declared as two sibling objects rather than one flat list).
- **`Motion.qml` tokens** [VERIFIED via grep]: `standardDuration` (200ms, `pairs[0]`), `emphasizedInDuration` (300ms, `pairs[1]`), `emphasizedOutDuration` (150ms, `pairs[2]`), `staggerOffsetDuration`/`staggerOffsetEasing` (50ms, `pairs[3]`) all exist exactly as UI-SPEC names them — no new motion tokens needed.
- **`AudioPopout.qml` slider geometry** [VERIFIED via grep]: track `height: 8` / `radius: 4` (lines 147-148), handle `width: 20` / `height: 20` (lines 161-162), a real Qt `Slider` with custom `background`/`handle` delegates writing through `root.audioBackend.setMasterVolume(...)` on `onMoved` — confirmed as the exact, already-production, geometry UI-SPEC says to reuse verbatim.
- **`QuickToggles.qml` `chipRadius`** [VERIFIED]: `readonly property int chipRadius: 16` (line 79), confirms the UI-SPEC's basis for `sessionTileRadius: 16`.

### 9. The three power-menu entry points + `powerAvailabilityProbe`

**Verification method:** direct grep of all three files [VERIFIED, this session].

- **`hypr/.config/hypr/config/keybinds.lua:68`** [VERIFIED, exact line]: `hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exec_cmd("~/.config/hypr/scripts/wleave.sh")) -- Open power menu`.
- **`elephant/.config/elephant/menus/main.toml:35`** [VERIFIED, exact line]: `actions = { "open" = "~/.config/hypr/scripts/wleave.sh" }`, with a comment at line 33 explicitly stating *"delegates to the ONE existing power surface (same as Super+Shift+Q)"* — confirming the walker menu entry and the keybind are meant to be, and currently are, the same target.
- **`quickshell/.config/quickshell/modules/bar/ClockActionsCapsule.qml`** [VERIFIED, exact lines, differs slightly from CONTEXT.md's citation but same substance]: `powerScriptPath` at **line 567**, `powerAvailable` property at **line 568**, `powerAvailabilityProbe` `Process` (running `test -x <path>`) at **lines 571-575**, `powerLaunchProcess` `Process` at **lines 577-579**. CONTEXT.md's citation of "567,579" and "567-580" both land inside this same six-line block — confirmed as the same target, no separate site missed.
- **All three confirmed to currently point at the identical script** (`wleave.sh` / `wleave.sh` / `powerScriptPath` = the same path) — repointing all three to open the in-process QML surface, and deleting `powerAvailabilityProbe`/`powerAvailable` per D-20-23, is a complete, closed set: no fourth consumer exists in the repo (confirmed by this being the exhaustive grep result, not a partial one).

## Standard Stack

No new libraries. Everything below is already installed and already in production use elsewhere in this repo.

### Core
| Tool/API | Version | Purpose | Why Standard (here) |
|---------|---------|---------|--------------|
| Quickshell `FileView` (`Quickshell.Io`) | quickshell 0.3.0-2 [VERIFIED: `pacman -Qi`] | Watched-file reads for Caps Lock sysfs node | Already production-proven in this exact repo for a different watched file (`ClockActionsCapsule.qml`'s `gamingStateFile`) |
| Quickshell `Quickshell.Services.Pipewire` | quickshell 0.3.0-2 | Volume/mic read+write | Already the sole audio backend in `AudioBackend.qml`, no subprocess |
| `brightnessctl` | already installed [VERIFIED: `/usr/bin/brightnessctl`, `brightnessctl -l` run live] | Brightness read+write | Already the sole brightness backend in `BrightnessBackend.qml` |
| `hyprshutdown` | 0.1.1-6 [VERIFIED: `pacman -Qi`] | Graceful compositor exit before Shutdown/Reboot/(proposed)Logout | Already used by wleave's own current Reboot/Shutdown actions; QPOWER-04 explicitly requires keeping this mechanism |
| `uwsm` | 0.26.6-1 [VERIFIED: `pacman -Qi`] | Session start/stop, already owns this host's Hyprland session lifecycle | Confirmed via live `systemctl --user list-units` — this host's Hyprland runs entirely inside uwsm's systemd unit graph |
| `pgrep` (procps-ng) | system-provided | Package-manager-busy detector 1 | Already the standard Linux process-presence check; 0.016s live-measured cost |

### Alternatives Considered
Not applicable — no library choice exists to make in this phase; every mechanism is dictated by CONTEXT.md's locked decisions and this repo's existing backends.

**Installation:** None required.

## Architecture Patterns

### System Architecture Diagram

```
Hardware/Kernel                Quickshell (QML, this shell)              Compositor/systemd
────────────────               ─────────────────────────────             ──────────────────
XF86Audio* / Brightness keys ─▶ Hyprland bind (locked=true) ─▶ swayosd-client (unchanged,
  (already routed, no change)                                  exec-target swap only)
                                        │
Caps Lock key ─▶ kernel input core ─▶  /sys/class/leds/*::capslock/brightness (world-readable)
                                        │  (FileView, watchChanges:true — needs live-verify)
                                        ▼
                                 Toast.qml instance (namespace: quickshell-osd, edge: bottom,
                                 interactive: true) ◀── Connections on AudioBackend/
                                                          BrightnessBackend state changes
                                        │
                                 osdRecencyWindowMs gate → 0-3 slider rows, or Caps Lock row
                                        │  (drag/scroll writes back through)
                                        ▼
                       AudioBackend.setMasterVolume/setInputVolume (native Pipewire binding)
                       BrightnessBackend.setPercent (brightnessctl subprocess, single-flighted)

Super+Shift+Q / walker menu / bar powerCell ─▶ (all three, repointed) ─▶ new PanelWindow
  (quickshell-session namespace, WlrKeyboardFocus.Exclusive, HyprlandFocusGrab dismiss)
                                        │
                     3x2 tile grid ── Enter/mnemonic ──▶ Process(action string)
                                        │                      │
                     QPOWER-03 Timer (visible-only) ──▶  pgrep / find / hyprctl toplevel count
                                        │                      ▼
                          Lock: uwsm app -- hyprlock          Suspend/Hibernate: systemctl
                          Reboot/Shutdown: hyprshutdown --post-cmd 'systemctl reboot|poweroff'
                          Logout: cliphist wipe; hyprshutdown --post-cmd 'uwsm stop' (D-20-37,
                                   wrapped without the D-29 measurement — see Priority Finding 1)
```

### Recommended Project Structure
No new directories — both surfaces live in existing module directories:
```
quickshell/.config/quickshell/modules/
├── toast/Toast.qml          # extended in place (edge, interactive, namespace properties)
├── dashboard/
│   ├── PanelDialog.qml      # pattern reused, NOT subclassed — power dialog is a new PanelWindow
│   ├── AudioBackend.qml     # unchanged, already has the needed setters
│   └── Cascade.qml          # reused as-is for the power grid's stagger
├── bar/
│   ├── BrightnessBackend.qml  # unchanged, setPercent() already exists
│   └── ClockActionsCapsule.qml # powerAvailabilityProbe/powerAvailable deleted (D-20-23)
└── session/                 # NEW directory (or wherever the planner places the power dialog)
    └── PowerMenu.qml        # new file — built ON PanelDialog's pattern, not instantiating it
```

### Pattern 1: `FileView{watchChanges:true}` for sysfs-backed indicators
**What:** Open a sysfs attribute path, react to `onFileChanged`, re-glob on failure.
**When to use:** Any binary hardware state exposed via a stable-ish sysfs path with no existing D-Bus/service surface (this repo's own stated preference, per D-20-16's rejection of `hyprctl devices -j` polling).
**Example (the existing production precedent to copy):**
```qml
// Source: quickshell/.config/quickshell/modules/bar/ClockActionsCapsule.qml:586-592 (verified this session)
FileView {
    id: gamingStateFile
    path: clockActionsCapsule.homeDir + "/.cache/gaming-mode"
    watchChanges: true
    onFileChanged: reload()
}
readonly property string gamingRaw: (gamingStateFile.text() || "").trim()
```
For Caps Lock, the equivalent shape adds glob-resolution logic around `path` (this file watches a fixed, known path — the Caps Lock case needs the glob-at-startup/re-glob-on-failure D-20-14 already specifies, which has no existing precedent in this repo to copy verbatim; it is new logic, not a reused pattern).

### Pattern 2: Layer-rule namespace registration — declare last, restate blur, add the alpha override explicitly
**What:** Any new `quickshell-*` namespace inherits the family's `blur=true`/`ignore_alpha=0.5` automatically, but if the QML surface's actual fill alpha needs a lower floor (as Toast.qml's 0.38 does), a dedicated override row is required in the same commit, declared in the last block of the file (after the family regex and after every other override), per this file's own recorded ordering finding.
**When to use:** `quickshell-osd`, `quickshell-session` namespace registration this phase.
**Example (source: `hypr/.config/hypr/config/windowrules.lua`, verified this session):**
```lua
-- family regex (already exists, line 396/445 — no change needed)
hl.layer_rule({ match = { namespace = "^quickshell-.*" }, blur = true })
hl.layer_rule({ match = { namespace = "^quickshell-.*" }, ignore_alpha = 0.5 })

-- NEW rows this phase must add, in the LAST block of the file (after line 565),
-- restating blur alongside the override per this file's own established idiom (lines 560-565):
hl.layer_rule({ match = { namespace = "quickshell-osd" }, animation = "slide" })
hl.layer_rule({ match = { namespace = "quickshell-osd" }, blur = true })
hl.layer_rule({ match = { namespace = "quickshell-osd" }, ignore_alpha = 0.2 }) -- matches Toast.qml's reused 0.38 fill
hl.layer_rule({ match = { namespace = "quickshell-session" }, animation = "slide" })
-- quickshell-session's card fill (Colours.surface @ 0.78) is comfortably above the family's
-- own 0.5 floor — verify this once rendered, but no override row is predicted to be needed.
```
Apply with `hyprctl eval '<rule>'` or a full restart to test — `hyprctl reload` will silently drop the edit on this build (already-documented project finding, not re-derived here).

### Anti-Patterns to Avoid
- **Assuming a new `quickshell-*` namespace inherits whatever alpha treatment an old namespace with a similar name had.** `quickshell-osd` is not `quickshell-notif-toast`; it starts at the family's 0.5 floor, not any sibling's overridden value, until an override row is written for it by name.
- **Treating `hyprctl reload` as sufficient to test a layer-rule change.** Already-documented project finding (`hyprctl reload drops layer rules`) — use `hyprctl eval` or restart, every time, for this file.
- **Re-deriving a brightness absolute setter.** It already exists (`BrightnessBackend.setPercent`) — writing a second one would silently violate the "one writer, single-flighted" discipline the existing file's own header comments explain is load-bearing.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Transient auto-hide indicator frame | A new `PanelWindow` from scratch | Extend `Toast.qml` (D-20-02, verified reusable as-is bar three new properties) | Chrome, timer, show()/hide() replace-in-place semantics all already correct |
| Modal focus-grab dialog frame | A bespoke `PanelWindow` with hand-rolled `HyprlandFocusGrab` | Copy `PanelDialog.qml`'s pattern (rim, cascade, focus-grab, Esc handling) — not instantiate it, since geometry genuinely diverges | Focus-grab-plus-Exclusive-focus coexistence and Cascade wiring are both already proven correct in this exact codebase |
| Absolute brightness set from a slider drag | A second `brightnessctl set <percent>%` Process | `BrightnessBackend.setPercent(percent)` (already exists, line 234) | Avoids a second single-flight/coalescing implementation that could race the existing one |
| Audio volume/mute write path | A `wpctl set-volume`/`set-mute` subprocess | `AudioBackend.setMasterVolume/setMasterMuted/setInputVolume/setInputMuted` (native Pipewire binding, no subprocess) | Already the only audio write path in this shell; adding a subprocess path would be a second, inconsistent mechanism |
| Package-manager-busy detection | A custom lockfile parser | `pgrep -x pacman/paru/yay` (already the pattern D-20-27 itself specifies and this session verified live) | Lockfile-based detection has a documented false-positive failure mode (stale lock from a crashed pacman) that D-20-27 already explicitly rejected |

**Key insight:** This phase's actual net-new QML surface area is smaller than either CONTEXT.md or UI-SPEC.md's line count suggests — most of the "new" work is composing already-shipped primitives (`Toast.qml`, `PanelDialog`'s pattern, `AudioBackend`, `BrightnessBackend`, `Cascade`) rather than writing new backend logic. The two places genuine new logic is required are the sysfs glob/re-glob resolver (no precedent in-repo) and the three QPOWER-03 detectors (thin `Process` wrappers around already-tested shell commands).

## Common Pitfalls

### Pitfall 1: New layer namespace silently under-floored on `ignore_alpha`
**What goes wrong:** OSD (or power menu) renders with no blur, reading as "flat, not frosted."
**Why it happens:** A brand-new `quickshell-*` namespace inherits only the family's 0.5 floor, not any sibling namespace's own override; reusing a fill alpha tuned against a *different* namespace's lower override (e.g., Toast.qml's 0.38, tuned against `quickshell-notif-toast`'s 0.2 override) silently fails once the same fill moves under `quickshell-osd`'s un-overridden 0.5 floor.
**How to avoid:** Add an explicit `ignore_alpha` override row for each new namespace, in the same commit as its `animation` row, in the file's last-declared block (per Pattern 2 above).
**Warning signs:** Surface renders correctly-colored but with the desktop behind it fully opaque or fully see-through with no frosting — visually identical to "the layer rule never applied at all," which is a different, unrelated failure mode (`hyprctl reload` vs `eval`) this repo has already hit once.

### Pitfall 2: Treating "wrapped" as "measured" for Logout
**What goes wrong:** LEDGER-02's closure gets summarized in a way that reads as "the D-29 hazard was fixed," when the live evidence (Priority Finding 1) suggests the specific composition is closer to a no-op.
**Why it happens:** `hyprshutdown --post-cmd 'uwsm stop'` sounds authoritative and mirrors the Reboot/Shutdown pattern, inviting the same confidence — but Reboot/Shutdown's post-cmd (`systemctl reboot/poweroff`) does something unambiguous, while Logout's proposed post-cmd (`uwsm stop`, no `-r`) very likely finds nothing left to do by the time it runs.
**How to avoid:** Write the phase's closing documentation exactly as D-20-37 already instructs — "wrapped without measurement," not "fixed" — and cite this research's systemd-topology evidence as the reason the marginal effect is doubted, not assumed positive.
**Warning signs:** Any summary sentence that says Logout's teardown hazard is "closed" or "resolved" rather than "wrapped, unmeasured, evidence suggests low marginal risk."

### Pitfall 3: Assuming the sysfs LED watch works because the mechanism is documented
**What goes wrong:** QOSD-02 ships without ever confirming `onFileChanged` actually fires for a real Caps Lock press, and the first real-world failure is a user report months later.
**Why it happens:** The kernel documentation strongly suggests this works (Priority Finding 2), and reading documentation feels like verification — but this session could not execute the one test that would confirm it (no passwordless sudo, no safe way to simulate the real hardware event).
**How to avoid:** One explicit GATE-01-style live-verify task: press physical Caps Lock while a diagnostic `FileView` is watching, confirm `onFileChanged` fires, before checking off QOSD-02.
**Warning signs:** GATE-02 Gate A's own criterion 6 ("Caps Lock shows the icon+label row only on the ON transition") passing in a build/reload cycle without ever actually pressing the physical key — a scripted or `wtype`-based "verification" would not actually exercise the real code path (wtype's virtual keyboard event does not reliably drive the same kernel LED-classdev path a real key does).

### Pitfall 4: Reintroducing a brightness setter that already exists
**What goes wrong:** A second `Process` writing `brightnessctl ... set <percent>%` gets added inside the new OSD slider code, racing or duplicating `BrightnessBackend`'s existing single-flighted writer.
**Why it happens:** 20-UI-SPEC.md itself states the setter is still pending ("once `BrightnessBackend` gains an absolute setter, an implementation-time call flagged in 19-UI-SPEC.md") — a planner trusting that sentence without re-reading the file would build a duplicate.
**How to avoid:** This research confirms (Priority Finding 4) `setPercent(percent)` already exists at line 234 — the plan's task list should call it directly, no new backend work.
**Warning signs:** Any task description that says "add an absolute brightness setter" rather than "wire the OSD slider to the existing `BrightnessBackend.setPercent()`."

## Code Examples

### Toast.qml's current hardcoded points that must become properties (verified this session, exact lines)
```qml
// Source: quickshell/.config/quickshell/modules/toast/Toast.qml (read in full this session)
// Line 96 — must become: anchors.top: toastWindow.edge === "top" (or equivalent)
anchors.top: true
// Line 101 — must become: WlrLayershell.namespace: toastWindow.namespace
WlrLayershell.namespace: "quickshell-notif-toast"
// Lines 103-104 — must become conditional on a new `interactive` property
WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
focusable: false
// Line 82 — must read a per-instance interval, not the DND toast's own constant
interval: Design.notifToastDurationMs
```

### `PanelDialog.qml`'s focus-grab + Exclusive-focus coexistence precedent
```qml
// Source: quickshell/.config/quickshell/modules/dashboard/PanelDialog.qml:131,203-208 (verified this session)
WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand   // power menu changes this to .Exclusive (D-20-24)
// ...
HyprlandFocusGrab {
    id: grab
    windows: [ panelWindow ]
    active: true
    onCleared: panelWindow.requestDismiss()
}
```
UI-SPEC's claim that `HyprlandFocusGrab` "still provides click-outside dismissal alongside exclusive focus" on this compositor was **not independently re-verified this session** (no live test of `Exclusive` + `HyprlandFocusGrab` together was run) — this is the one UI-SPEC claim in this area that should get a real check during implementation, not assumed correct by extrapolation from the `OnDemand` case above.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| SwayOSD (GTK4 layer-shell client, own libinput backend) | `Toast.qml` instance driven by backend `Connections` | This phase | No separate process, no separate CSS pipeline, no separate systemd unit for the render layer (libinput backend's fate is a separate question, D-20-17) |
| wleave (GTK4 layer-shell, JSON-configured 6-hue-capsule grid) | QML `PanelDialog`-pattern modal, 3x2 grid | This phase | Redesigned toward the reference language per D-20-25, not ported |
| `powerAvailabilityProbe` (`test -x wleave.sh`) | Deleted entirely (D-20-23) | This phase | "Power menu missing" stops being a reachable state for an in-process surface |

**Deprecated/outdated:** SwayOSD's CSS-only theming model (fixed anchor/margin, not configurable) — superseded by full QML layer-posture control.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The sysfs LED brightness attribute's kernel-side change notification (`sysfs_notify`/`kernfs_notify`) reaches Quickshell's `FileView{watchChanges:true}` via the inotify chain described in Priority Finding 2 | Priority Finding 2, Pitfall 3 | QOSD-02 ships appearing complete but the indicator never fires on a real Caps Lock press; the phase would need to fall back to a polling `Timer`, breaking the zero-idle claim for this one surface |
| A2 | `HyprlandFocusGrab` continues to provide click-outside dismissal when combined with `WlrKeyboardFocus.Exclusive` (not just the `OnDemand` case this repo has actually exercised) | Code Examples § PanelDialog.qml focus-grab precedent | The power menu's click-outside dismissal silently fails to work, or `Exclusive` focus fails to grab correctly alongside an active `HyprlandFocusGrab` — either would surface at GATE-02 Gate B criterion 4 |
| A3 | The reasoned conclusion that `hyprshutdown --post-cmd 'uwsm stop'` has low marginal effect (Priority Finding 1) generalizes correctly from this host's *current* systemd unit topology to the topology that exists *at the moment Logout actually runs* | Priority Finding 1, Pitfall 2 | If the actual cascade behavior differs from what static unit inspection suggests, the "low marginal effect" framing could be wrong in either direction — it could matter more (a real gap) or be entirely inert (as suspected) |

## Open Questions

1. **Does `FileView.onFileChanged` actually fire for the Caps Lock sysfs node on this hardware?**
   - What we know: the kernel-level mechanism is documented and merged upstream (Priority Finding 2); Qt's inotify engine has a documented bridge from kernfs notify events.
   - What's unclear: whether this specific `input-leds`-driven node on this specific kernel build actually calls the notify helper on every OS-driven (not just hardware-driven) brightness change, and whether Quickshell's `FileView` C++ implementation uses the inotify-based `QFileSystemWatcher` engine (versus a polling fallback that would behave differently, or a raw `poll()`-based custom implementation that might behave more reliably than plain inotify).
   - Recommendation: one live-verify task, folded into GATE-01's existing measurement pass, exactly as D-20-17/D-20-19 already do for their own open questions.

2. **What is the actual live effect of `hyprshutdown --post-cmd 'uwsm stop'` on Logout, empirically?**
   - What we know: static systemd unit topology strongly suggests low marginal effect (Priority Finding 1).
   - What's unclear: this was never actually run to completion this session (doing so would end the shell/research session), so the conclusion is reasoned, not measured.
   - Recommendation: D-20-37 already accepts this uncertainty explicitly ("neither confirmed nor falsified") — no action needed beyond documenting the composition honestly, per Pitfall 2.

3. **Does `HyprlandFocusGrab` + `WlrKeyboardFocus.Exclusive` actually coexist correctly on this Hyprland build?**
   - What we know: `PanelDialog.qml` proves the pattern works under `OnDemand`; UI-SPEC asserts it also works under `Exclusive` but does not cite a source for that specific combination.
   - What's unclear: no existing surface in this repo currently combines the two; this would be a first.
   - Recommendation: treat as GATE-02 Gate B criterion 4's own job to prove live, not something to assume correct before building.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `brightnessctl` | Brightness OSD row + power-menu-adjacent nothing | ✓ | (present, `-l` run live) | — |
| Backlight-class device (`/sys/class/backlight/`) | Brightness OSD row's live demonstrability | ✗ (confirmed empty this session) | — | Present-but-inert code path, matching D-18-39/GATE-02 B.3 precedent — brightness OSD row cannot be demonstrated live on this host, document as inherited NOT-DEMONSTRABLE, not a new gap |
| `hyprshutdown` | Shutdown/Reboot/(proposed)Logout graceful exit | ✓ | 0.3.1-1... 0.1.1-6 [VERIFIED via `pacman -Qi`] | — |
| `uwsm` | Session start/stop; Logout wrap target | ✓ | 0.26.6-1 | — |
| `pgrep` | QPOWER-03 detector 1 | ✓ | system-provided | — |
| `sudo` (passwordless, for live LED-write testing) | Priority Finding 2's live poll test | ✗ (confirmed this session — `sudo: a password is required`) | — | No fallback for *this research session*; the phase's own GATE-01 live-verify task (Open Question 1) does not need root — a real physical Caps Lock press exercises the same code path without any privilege escalation |
| `inotifywait` (inotify-tools) | Would have simplified Priority Finding 2's live test | ✗ (not installed) | — | Not required for the phase itself — Quickshell's own `FileView` is the actual mechanism; `inotifywait` was only useful as an independent diagnostic and its absence did not block the phase, only this research session's own test convenience |

**Missing dependencies with no fallback:** None block the phase itself — the one missing item (`sudo`, `inotifywait`) only blocked this research session's own live-test attempt, not the phase's eventual implementation or its own GATE-01 verify task (which uses a real key press, not a synthetic root-level write).

**Missing dependencies with fallback:** Backlight device absence — already has a proven, in-repo fallback pattern (present-but-inert, D-18-39).

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | Neither surface performs authentication; session-ending actions delegate to systemd-logind/hyprlock, which already own this concern |
| V3 Session Management | Partial | Logout/Suspend/Hibernate/Shutdown/Reboot are session-lifecycle actions dispatched via `Process` to already-trusted binaries (`systemctl`, `hyprshutdown`, `uwsm`) — no new session-state storage is introduced by this phase |
| V4 Access Control | Yes | The layer-shell surfaces themselves are the access-control-relevant surface: `WlrKeyboardFocus.Exclusive` (power menu) and world-readable-only (sysfs LED) are the two access boundaries this phase touches. Standard control: keep the sysfs read path read-only (never open the node for writing from this codebase — the phase has no legitimate reason to write it), and keep every action-string in the power menu a fixed literal array element (never a joined/interpolated string reaching a shell), mirroring `PanelDialog.qml`'s own `advancedCommand` discipline (verified this session, lines 374-377: `command: panelWindow.advancedCommand` — never joined into a string) |
| V5 Input Validation | Yes | No user-supplied text reaches either surface (Copywriting Contract confirms the OSD carries no text at all and the power menu's six actions are fixed literals) — the only "input" is a sysfs read (trusted kernel source) and detector process output (`pgrep`/`find`/`hyprctl`), none of which is interpolated into a further command |
| V6 Cryptography | No | Not applicable to this phase |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Layer-shell z-order occlusion — a confirm dialog from another app rendering behind the new power menu's overlay | Denial of Service (of the *other* app's own confirm UX, not this shell's) | **Carried over explicitly from Phase 15/`PITFALLS.md` line 295** [VERIFIED: quoted directly from `research/PITFALLS.md`]: *"Re-run the same 'who owns the prompt' check this project already learned from Phase 15's wifi/bluetooth work for any surface the new power menu might occlude."* This phase's own notes already name this as the Phase 15 security carry-over; this research confirms the exact source citation and that no code fix currently exists for it — it is a live-verify item at GATE-02 Gate B, not a pre-solved concern. |
| Command injection via a joined/interpolated action string reaching a shell | Tampering | Fixed literal `Process.command` arrays only, never a joined string handed to a shell interpreter — matches `BrightnessBackend.qml`'s own documented discipline (verified this session, its header comment explicitly reasons about `-c`/`-d` short-flag ambiguity) and `PanelDialog.qml`'s `advancedCommand` pattern |
| A stray write to the world-readable-but-root-owned sysfs LED node | Tampering (of hardware state, not of this shell's own data) | This phase's own design never needs to write this node — reads only. No mitigation code needed beyond code review confirming no write path is ever added to the Caps Lock `FileView`. |

## Sources

### Primary (HIGH confidence — live verification this session)
- Direct file reads: `20-CONTEXT.md`, `20-UI-SPEC.md`, `REQUIREMENTS.md`, `STATE.md`, `Toast.qml`, `PanelDialog.qml`, `BrightnessBackend.qml`, `AudioBackend.qml` (grep), `Colours.qml` (grep), `BarRoles.qml` (grep), `Design.qml` (grep), `Motion.qml` (grep), `ClockActionsCapsule.qml` (grep + excerpt), `windowrules.lua` (full read, lines 360-565), `keybinds.lua`/`main.toml` (grep), `WINDOWS.md` (full grep + tail), `contract.json`/`config.toml`/`reload.sh`/`theme-doctor`/`theme-stress-test`/`gtk.sh`/`install.sh`/`stow.sh` (grep), `wleave/layout.json`, `swayosd/style.css`, `AudioPopout.qml` (grep), `QuickToggles.qml` (grep), `Cascade.qml` (grep), `PITFALLS.md` (grep + excerpt)
- Live host commands: `hyprshutdown --help`, `uwsm --help`/`uwsm stop --help`, `pacman -Qi hyprshutdown/uwsm/swayosd/wlogout/eww`, `systemctl status/is-enabled swayosd-libinput-backend.service`, `systemctl --user list-units --all`, `hyprctl devices -j`, `ls`/`stat`/`cat`/`udevadm info` against `/sys/class/leds/`, `wpctl status`/`get-volume`, `brightnessctl -l`, `pgrep -x pacman/paru/yay` with timing, `find ~/Downloads`

### Secondary (MEDIUM confidence — CITED, not locally verified)
- [Linux kernel LED class documentation](https://docs.kernel.org/leds/leds-class.html) — poll()-on-brightness support
- [`Documentation/ABI/testing/sysfs-class-led`](https://www.kernel.org/doc/Documentation/ABI/testing/sysfs-class-led) — brightness attribute poll() support documented
- Kernel patchwork: "leds: core: Add support for poll()ing the sysfs brightness attr for changes" (Hans de Goede) — `led_notify_brightness_change` mechanism
- Kernel mailing-list discussion of `kernfs_notify`/fsnotify bridging for sysfs files (linux-kernel list archives, LWN "fsnotify, dnotify, and inotify")

### Tertiary (LOW confidence — attempted live test, inconclusive)
- This session's `select.poll()` test script against the live Caps Lock LED node — result inconclusive (write trigger blocked by missing passwordless sudo), documented above as Open Question 1, not asserted as fact anywhere in this document

## Metadata

**Confidence breakdown:**
- Standard stack / reuse surfaces: HIGH — every claim backed by a direct file read this session, with exact line numbers quoted verbatim
- Layer-rule ordering/alpha trap: HIGH — direct read of the governing file, cross-referenced against Toast.qml's actual current alpha value
- hyprshutdown/uwsm composition: MEDIUM — reasoned from live, verified systemd unit topology, but not empirically exercised end-to-end
- sysfs LED watchability: LOW-MEDIUM — CITED kernel documentation is credible and specific, but the one live test attempted this session was blocked by environment (no passwordless sudo) and is honestly reported as inconclusive, not positive

**Research date:** 2026-08-15
**Valid until:** Treat the systemd-topology and sysfs-node-name findings as valid only for this exact boot session — both are explicitly documented in CONTEXT.md/this research as subject to change across a reboot (D-20-14's own premise, reconfirmed by this session finding a *different* node name than CONTEXT.md's 2026-08-14 finding). The reuse-surface findings (Toast.qml, PanelDialog.qml, backend APIs) are valid until the next commit touches those files.
