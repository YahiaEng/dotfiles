-- hypr/.config/hypr/config/keybinds.lua — Lua port of config/keybinds.conf
-- (Phase 13.1, plan 13.1-04 Task 2). All 80 bind declarations (63 `bind`,
-- 6 `bindel`, 4 `bindl`, 4 `binde`, 2 `bindm`, 1 `bindr`) ported to
-- the top-level bind-registration call (keys, dispatcher, opts), plus the
-- one `windowrule` this file carries (kept here, not relocated to
-- windowrules.lua — D-06).
--
-- Every dispatcher/flag/key-string form below was empirically confirmed
-- live against a nested hypr-lua-harness instance before being written —
-- never inferred from the hyprlang keyword (T-13.1-10). See
-- 13.1-LUA-FINDINGS.md's "13.1-04 Task 2: keybind dispatcher/key-string
-- vocabulary" section for the full evidence (commands + output). Summary
-- of what was confirmed this task, not assumed:
--   - hl.dsp.window.resize/hl.dsp.window.move BOTH validate their argument
--     shape at config-load time (configerrors), exactly like the
--     the window-rule/layer-rule/permission spec-builders' field-validator discovered
--     in 13.1-03 — a wrong shape errors loudly, it does not silently no-op.
--   - Multi-modifier key strings need EVERY modifier joined by its own
--     " + " (`"SUPER + SHIFT + Q"`) — `"SUPER SHIFT + Q"` (hyprlang's own
--     space-separated mod convention) and `"SUPER CTRL + Q"` BOTH fail to
--     parse under Lua. This is a real, previously-undocumented syntax
--     difference from hyprlang, not a cosmetic one.
--   - Direction abbreviations ("l"/"r"/"u"/"d") work identically to the
--     hyprlang originals in both `hl.dsp.focus({direction=...})` and
--     `hl.dsp.window.move({direction=...})` — behaviourally proven via a
--     live two-window focus-switch, not just accepted without error.
--   - `hl.dsp.window.resize({ x = -30, y = 0, relative = true })` was
--     dispatched directly against a real client and its `size` field
--     shrank by exactly 30px on the x axis and 0 on y — the precise
--     `resizeactive, -30 0` semantics, confirmed by live measurement.
--   - `hl.dsp.window.fullscreen(0)` / `hl.dsp.window.fullscreen(1)` both
--     accept a bare integer (matching the hyprlang arg literally) and
--     both visibly toggle a real client's `fullscreen`/`size`/`at` fields
--     between the tiled and filled state — the mechanism is proven live
--     and functioning; distinguishing "fullscreen" from "maximize" at the
--     single-tiled-window granularity available in the nested harness is
--     NOT MECHANICALLY VERIFIABLE beyond that (both produced the same
--     filled-output result with only one window present) — compensating
--     check: physically press Super+F and Super+Shift+F at the
--     end-of-phase human verification and confirm they read as distinct
--     (fullscreen vs maximize).
--   - `hl.dsp.window.float({ action = "toggle" })` and `hl.dsp.window.kill()`
--     both behaviourally confirmed (floating field flipped; client count
--     dropped to zero) via direct `hyprctl dispatch 'hl.dsp....'` calls —
--     a mechanism this task also discovered: on a Lua-config-managed
--     instance, `hyprctl dispatch` takes a Lua expression
--     (`hl.dsp.xxx(...)`), not the classic `dispatcher,args` string.
--   - `hl.dsp.global("quickshell:probe")` accepts the identifier as a bare
--     positional string with no config-load error.

local mainMod = "SUPER"
local terminal = "uwsm app -- kitty.desktop"
local fileExplorer = "uwsm app -- thunar.desktop"
local tui = 'uwsm app -- kitty --class yazi-fm --title "Yazi" -- yazi'
local appLauncher = "walker"
-- `-s <set>` panics walker 2.16.2 (src/data.rs:566, "can't find specified
-- set") — do not revert to `-s`.
local appLauncherDrun = "walker -m runner"
local lockScreen = "uwsm app -- hyprlock"
local codeEditor = "uwsm app -- codium.desktop --enable-features=UseOzonePlatform --ozone-platform=wayland --log debug"

-- ── Core ─────────────────────────────────────────────
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal)) -- Open terminal
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd(fileExplorer)) -- Open file manager
hl.bind(mainMod .. " + Y", hl.dsp.exec_cmd(tui)) -- Open file manager (TUI)
hl.bind(mainMod .. " + I", hl.dsp.exec_cmd(codeEditor)) -- Open code editor
hl.bind(mainMod .. " + Q", hl.dsp.window.kill()) -- Close active window
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.global("quickshell:power-menu")) -- Open power menu
hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" })) -- Toggle floating
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen(0)) -- Toggle fullscreen
hl.bind(mainMod .. " + SHIFT + F", hl.dsp.window.fullscreen(1)) -- Toggle maximize
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo()) -- Toggle pseudotiling
-- bind = $mainMod, J, togglesplit

-- ── Launchers (walker as primary, wofi still available) ─
-- D-01 three-way split: a bare Super tap is the menu alone (below), the
-- app launcher moved to its own dedicated Super+Space bind, and Super+R
-- (runner) stays exactly as-is. The tap-only mechanism is Hyprland's
-- native default release-bind shadowing (D-02) — proven live by keypress
-- in 07-04 Task 1 (see 07-04-SUMMARY.md) before this split was made.
--   tap Super  -> menu (main)
--   Super+Space -> app launcher (drun)
--   Super+R     -> app runner
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(appLauncher)) -- Open app launcher
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd(appLauncherDrun)) -- Open app runner
hl.bind(mainMod .. " + SUPER_L", hl.dsp.exec_cmd("uwsm app -- walker -m menus:main"), { release = true }) -- Open main menu (Super tap)

-- ── Escape hatch (D-03) ──────────────────────────────
-- Reserved, never-shadowed kill-bind. This exists so a future Super-bind
-- experiment (plan 07-04) can never lock the keyboard: Escape carries no
-- other $mainMod meaning anywhere in this file (confirmed via grep before
-- this line was added), so it can never be shadowed by anything else here.
-- Do NOT remove this bind because it "looks unused" — it is the escape
-- hatch, tested and proven in isolation before any risky Super-tap change.
hl.bind(mainMod .. " + Escape", hl.dsp.exec_cmd("pkill walker")) -- Emergency: force-close walker

-- ── Custom menus ─────────────────────────────────────
-- theme-switch.sh is a thin picker (D-01): it only prompts for a theme
-- name, then delegates to the single engine entrypoint,
-- ~/.config/theme-engine/theme-apply, for all rendering + reload.
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd("~/.config/hypr/scripts/theme-switch.sh")) -- Switch theme
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("~/.config/hypr/scripts/bar-orientation.sh")) -- Switch bar orientation
-- BAR-01/D-02/D-37: the ONLY bind that can clear a persistent
-- fullscreen/gaming-hide -- targets the owner's `keybind toggle` verb
-- (never hide/show directly), which carries the auto-clear-on-base-change
-- override semantics (D-02). Repointed to bar-visibility.sh (Phase 18
-- Plan 15/QBAR-07/D-18-29) and DELIBERATELY kept a Hyprland compositor
-- bind rather than converted to a QML GlobalShortcut: a shortcut living
-- inside the shell process cannot resurrect a bar whose process is gone
-- or hung, which is exactly the case this bind exists to recover from.
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd("~/.config/hypr/scripts/bar-visibility.sh keybind toggle")) -- Toggle bar visibility
-- Held-Super reveal (Phase 18 Plan 16, QBAR-08) — SHIPPED. Deliberately
-- shares the "SUPER + SUPER_L" chord with the tap-to-menu bind above and
-- is NOT a conflict: that one is a RELEASE bind, this one is a PRESS
-- bind, and Hyprland dispatches the two edges independently. Holding
-- Super reveals the hidden bar; tapping and releasing it opens the main
-- menu; doing both in one gesture does both, which is the intended
-- behaviour, not an accident.
--
-- 18-16 drafted this exact bind and reverted it, because keybind-doctor's
-- quickshell-manifest chord-collision check compared (modmask, key)
-- WITHOUT the release flag and so read the two binds as one chord claimed
-- twice. The doctor's own shadow check had always distinguished by
-- (modmask, key, keycode, release) and reported zero conflicts — the two
-- checks disagreed with each other. The collision check now compares the
-- edge as well, and `shortcuts.json`'s bar-reveal entry declares
-- `"release": false` to claim the press edge explicitly, so both sides of
-- the cross-check now agree these are two different claims.
--
-- Do NOT "simplify" this to a single bind or move it to another chord:
-- QBAR-08 specifies holding Super, and the escape hatch at Super+Escape
-- below exists precisely so a Super-bind experiment can never lock the
-- keyboard.
hl.bind(mainMod .. " + SUPER_L", hl.dsp.global("quickshell:bar-reveal")) -- Reveal hidden bar while Super is held
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("~/.config/hypr/scripts/wallpaper-switch.sh")) -- Change wallpaper

-- ── Clipboard ────────────────────────────────────────
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("cliphist list | walker --dmenu | cliphist decode | wl-copy")) -- Open clipboard history
-- UTIL-03/D-15 manual wipe entry — reachable without touching the Super+C
-- flow above (destructive-safe default-No confirm lives in the script).
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("~/.config/hypr/scripts/clipboard-wipe.sh")) -- Wipe clipboard history

-- ── Screenshots ──────────────────────────────────────
-- Omarchy-style Print-key family (D-05): freeze-capture into satty for
-- annotate+save+copy (SHOT-01/02). Old Super+X/Z/Shift+Print binds
-- removed — Super+X/Z freed for utilities (06-UI-SPEC D-32).
--
-- Bound by physical keycode (code:107), not the Print keysym (06-14 gap
-- closure). Keycode matching bypasses XKB keysym translation entirely,
-- which deterministically fixes the ALT case: on the us XKB keymap
-- <PRSC> is type PC_ALT_LEVEL2 with symbols [Print, Sys_Req], so holding
-- Alt selects level 2 = Sys_Req and `ALT, Print` can never match — Alt
-- never fires the keysym bind. Keycode binding is also robust against
-- keyboards whose physical PrtSc key does not emit the `Print` keysym
-- at all. If a live `wev` check shows the physical key does not emit
-- keycode 107, the remedy is the keyboard's onboard/iCUE hardware
-- profile — outside these dotfiles.
--
-- The `code:107` key-string spelling (lowercase, colon-separated) is
-- byte-identical to the hyprlang literal and confirmed via parse-error
-- contrast in 13.1-03 — `code107`/`CODE:107` both fail to parse, this
-- form does not. `hyprctl -j binds`' own `keycode` field reads back 0
-- (not 107) for a Lua-registered physical-keycode bind — a documented,
-- NOT MECHANICALLY VERIFIABLE serialization gap (13.1-03), unrelated to
-- whether the bind itself functions; compensating check: physically
-- press all four Print-key variants at the end-of-phase human
-- verification.
hl.bind("code:107", hl.dsp.exec_cmd("~/.config/hypr/scripts/capture-region.sh")) -- Screenshot region
hl.bind("SHIFT + code:107", hl.dsp.exec_cmd("~/.config/hypr/scripts/capture-window.sh")) -- Screenshot window
hl.bind("CTRL + code:107", hl.dsp.exec_cmd("~/.config/hypr/scripts/capture-full.sh")) -- Screenshot full
hl.bind("ALT + code:107", hl.dsp.exec_cmd("~/.config/hypr/scripts/record-toggle.sh")) -- Toggle screen recording

-- ── Utilities (D-32 — freed X/Z family, MENU-07 cheat-sheet source) ──
-- Chord assignments (no strong mnemonic fit across all four — documented
-- explicitly here for Phase 7's keybind cheat-sheet, per UI-SPEC
-- Interaction Contract):
--   Super+Z       -> emoji picker (UTIL-01)
--   Super+Shift+Z -> icon-theme picker (UTIL-04)
--   Super+X       -> color picker (UTIL-02)
--   Super+Shift+X -> font switcher (UTIL-05)
--   Super+C stays the fifth utility (clipboard, already bound above)
hl.bind(mainMod .. " + Z", hl.dsp.exec_cmd("~/.config/hypr/scripts/emoji-picker.sh")) -- Emoji picker
hl.bind(mainMod .. " + SHIFT + Z", hl.dsp.exec_cmd("~/.config/hypr/scripts/icon-theme-switch.sh")) -- Icon theme picker
hl.bind(mainMod .. " + X", hl.dsp.exec_cmd("~/.config/hypr/scripts/color-picker.sh")) -- Color picker
hl.bind(mainMod .. " + SHIFT + X", hl.dsp.exec_cmd("~/.config/hypr/scripts/font-switch.sh")) -- Font switcher

-- ── Quickshell probe (QS-02 viability gate, D-01/D-21) ──
-- Summons the instrumentation probe (click-counter/text-field/state-label/
-- screen-name panel) via Quickshell's own GlobalShortcut registration, not
-- a Hyprland-side exec. `G` verified free under every $mainMod combination
-- across all existing binds. Registered chord+appid+name recorded in
-- quickshell/.config/quickshell/shortcuts.json (D-17) for keybind-doctor's
-- cross-check (MAINT-01). The identifier strings below
-- ("quickshell:probe"/"quickshell:screencopy-probe") are the contract
-- with the Quickshell GlobalShortcut manifest — byte-identical to the
-- hyprlang originals, asserted equal to baseline via jq in this task's
-- verification (T-13.1-13).
hl.bind(mainMod .. " + SHIFT + G", hl.dsp.global("quickshell:probe")) -- Summon Quickshell probe (QS-02 gate)
-- Criterion-5 screencopy feasibility probe (11-05 Task 1): a second
-- Quickshell-owned chord proving the declared-manifest mechanism (D-17)
-- scales — adding it cost exactly this one bind line plus one manifest
-- entry in shortcuts.json. `K` verified free under every $mainMod
-- combination across all existing binds.
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.global("quickshell:screencopy-probe")) -- Summon Quickshell screencopy probe (criterion 5)
-- Dashboard drawer (Phase 14 tracer, D-09/DASH-01): `D` verified free under
-- every existing modifier combination. Identifier below byte-matches
-- shortcuts.json's appid:name pair — keybind-doctor's cross-check contract.
hl.bind(mainMod .. " + D", hl.dsp.global("quickshell:dashboard")) -- Summon dashboard drawer (DASH-01)
-- Audio panel (Phase 15 Plan 02 tracer, PANEL-02/PANEL-06): `A` verified
-- free under every existing $mainMod combination. Identifier below
-- byte-matches shortcuts.json's appid:name pair — keybind-doctor's
-- cross-check contract. D-15-04: Super+A is the only panel keybind of the
-- three this phase adds — see the D-15-04 comment above audioPanelShortcut
-- in shell.qml for the full asymmetry rationale.
hl.bind(mainMod .. " + A", hl.dsp.global("quickshell:audio-panel")) -- Summon audio mixer panel (PANEL-02)
-- Workspace overview (Phase 16 Plan 02 tracer, D-16-18/OVER-01): `O`
-- verified free under every existing $mainMod combination. Identifier below
-- byte-matches shortcuts.json's appid:name pair — keybind-doctor's
-- cross-check contract. Toggle-on-press shape, same as screencopy-probe's
-- own bind above — D-16-19 deliberately exempts the overview from the
-- fullscreen refusal guard dashboardShortcut/audioPanelShortcut respect,
-- so this bind (unlike those two) needs no such guard on the Quickshell
-- side either.
hl.bind(mainMod .. " + O", hl.dsp.global("quickshell:overview")) -- Summon workspace overview (OVER-01)

-- ── Notification center ──────────────────────────────
-- Phase 19 Plan 06 (D-19-16): repointed from an exec_cmd shelling to the
-- outgoing daemon's own CLI onto this repo's own established
-- hl.dsp.global("quickshell:<name>") + shortcuts.json + GlobalShortcut
-- pattern — the same idiom Super+D/Super+A/Super+O already use. Identifier
-- below byte-matches shortcuts.json's appid:name pair and shell.qml's own
-- notifCentreShortcut — keybind-doctor's cross-check contract.
hl.bind(mainMod .. " + N", hl.dsp.global("quickshell:notif-centre")) -- Toggle notification center (QNOTIF-06)

-- ── Lock screen ──────────────────────────────────────
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd(lockScreen)) -- Lock screen

-- ── Move focus ───────────────────────────────────────
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "l" })) -- Focus window left
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "r" })) -- Focus window right
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "u" })) -- Focus window up
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "d" })) -- Focus window down

-- ── Move windows ─────────────────────────────────────
hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.move({ direction = "l" })) -- Move window left
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "r" })) -- Move window right
hl.bind(mainMod .. " + SHIFT + up", hl.dsp.window.move({ direction = "u" })) -- Move window up
hl.bind(mainMod .. " + SHIFT + down", hl.dsp.window.move({ direction = "d" })) -- Move window down

-- ── Resize windows ───────────────────────────────────
hl.bind(mainMod .. " + CTRL + left", hl.dsp.window.resize({ x = -30, y = 0, relative = true }), { repeating = true }) -- Resize window narrower
hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.resize({ x = 30, y = 0, relative = true }), { repeating = true }) -- Resize window wider
hl.bind(mainMod .. " + CTRL + up", hl.dsp.window.resize({ x = 0, y = -30, relative = true }), { repeating = true }) -- Resize window shorter
hl.bind(mainMod .. " + CTRL + down", hl.dsp.window.resize({ x = 0, y = 30, relative = true }), { repeating = true }) -- Resize window taller

-- ── Switch workspaces ────────────────────────────────
hl.bind(mainMod .. " + 1", hl.dsp.focus({ workspace = 1 })) -- Switch to workspace 1
hl.bind(mainMod .. " + 2", hl.dsp.focus({ workspace = 2 })) -- Switch to workspace 2
hl.bind(mainMod .. " + 3", hl.dsp.focus({ workspace = 3 })) -- Switch to workspace 3
hl.bind(mainMod .. " + 4", hl.dsp.focus({ workspace = 4 })) -- Switch to workspace 4
hl.bind(mainMod .. " + 5", hl.dsp.focus({ workspace = 5 })) -- Switch to workspace 5
hl.bind(mainMod .. " + 6", hl.dsp.focus({ workspace = 6 })) -- Switch to workspace 6
hl.bind(mainMod .. " + 7", hl.dsp.focus({ workspace = 7 })) -- Switch to workspace 7
hl.bind(mainMod .. " + 8", hl.dsp.focus({ workspace = 8 })) -- Switch to workspace 8
hl.bind(mainMod .. " + 9", hl.dsp.focus({ workspace = 9 })) -- Switch to workspace 9
hl.bind(mainMod .. " + 0", hl.dsp.focus({ workspace = 10 })) -- Switch to workspace 10

-- ── Move to workspace ────────────────────────────────
hl.bind(mainMod .. " + SHIFT + 1", hl.dsp.window.move({ workspace = 1 })) -- Move window to workspace 1
hl.bind(mainMod .. " + SHIFT + 2", hl.dsp.window.move({ workspace = 2 })) -- Move window to workspace 2
hl.bind(mainMod .. " + SHIFT + 3", hl.dsp.window.move({ workspace = 3 })) -- Move window to workspace 3
hl.bind(mainMod .. " + SHIFT + 4", hl.dsp.window.move({ workspace = 4 })) -- Move window to workspace 4
hl.bind(mainMod .. " + SHIFT + 5", hl.dsp.window.move({ workspace = 5 })) -- Move window to workspace 5
hl.bind(mainMod .. " + SHIFT + 6", hl.dsp.window.move({ workspace = 6 })) -- Move window to workspace 6
hl.bind(mainMod .. " + SHIFT + 7", hl.dsp.window.move({ workspace = 7 })) -- Move window to workspace 7
hl.bind(mainMod .. " + SHIFT + 8", hl.dsp.window.move({ workspace = 8 })) -- Move window to workspace 8
hl.bind(mainMod .. " + SHIFT + 9", hl.dsp.window.move({ workspace = 9 })) -- Move window to workspace 9
hl.bind(mainMod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10 })) -- Move window to workspace 10

-- ── Special workspace (scratchpad) ───────────────────
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic")) -- Toggle scratchpad
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" })) -- Move window to scratchpad

-- ── Scroll through workspaces ────────────────────────
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" })) -- Next workspace
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" })) -- Previous workspace

-- ── Mouse bindings ───────────────────────────────────
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true }) -- Drag to move window
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true }) -- Drag to resize window

-- ── Audio controls ───────────────────────────────────
-- Phase 20 Plan 04 (QOSD-01, D-20-05): the pill is now raised by BACKEND
-- STATE CHANGE, not by an OSD client — `wpctl` writes PipeWire directly,
-- AudioBackend.qml's own reactive properties pick it up, and the QML
-- `quickshell-osd` indicator's own Connections block raises the surface
-- from THAT, never from this keybind. `locked = true` is still what
-- QOSD-01's in-session half rests on (the key must keep working while
-- hyprlock is up, per D-20-19's measurement) — kept verbatim, not
-- re-decided by this plan. `-l 1.0` on the raise bind caps PipeWire's own
-- software boost at 100%, which the retired OSD daemon's client used to
-- cap for us.
-- XF86AudioLowerVolume/XF86AudioMute/XF86AudioMicMute are repointed onto
-- `wpctl` the same way (Task 2 of this same plan); XF86MonBrightness{Up,Down}
-- repoint onto `brightnessctl` instead, see the comment above that pair.
-- No retired-daemon client invocation remains in this file as of Task 2.
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+ -l 1.0"), { locked = true, repeating = true }) -- Raise volume
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"), { locked = true, repeating = true }) -- Lower volume
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), { locked = true, repeating = true }) -- Mute audio
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"), { locked = true, repeating = true }) -- Mute microphone

-- ── Brightness ───────────────────────────────────────
-- Phase 20 Plan 05 (QOSD-01/QOSD-04, D-20-05, Rule 2 deviation — see
-- 20-05-SUMMARY.md and
-- .planning/todos/pending/2026-08-15-brightness-osd-unverifiable-on-desktop.md):
-- repointed OFF the raw `brightnessctl` exec Plan 04 Task 2 shipped, onto
-- `qs ipc call -- osd raise|lower` (shell.qml's own `osd` IpcHandler,
-- calling `BrightnessBackend.adjust()`). Plan 04's raw exec changed the
-- backlight directly but bypassed `BrightnessBackend.percent` entirely —
-- `Osd.qml`'s trigger watches THAT property, so the OSD never raised on a
-- real backlight-equipped host even though the hardware itself changed
-- correctly. Routing the write through the backend keeps D-20-05's
-- "trigger is backend state, never the keybind" literally true: the
-- backend is still the sole emitter, only the keybind's OWN call target
-- moved. `timeout 2` bounds the call the same way bar-visibility.sh's own
-- `_ipc_call` does; `--` is REQUIRED per T-18-17's measured CLI11
-- collision finding (a bare positional argument can collide with the
-- `ipc show` subcommand one level up) even though neither `raise` nor
-- `lower` is the literal token that collided — kept for consistency with
-- the one precedent this repo has already proven correct, not because
-- these two verbs are known to collide themselves. This host has ZERO
-- backlight-class devices (`BrightnessBackend.present` is false), so this
-- path is implemented but UNVERIFIED here — re-test on real laptop
-- hardware per the todo file's own verification-debt section. The
-- caps-lock OSD (QOSD-02, D-20-13) remains handled separately — a polled
-- (not watched — GATE-01 measured the watch dead, see
-- CapsLockBackend.qml's own header) sysfs LED node read in-process by the
-- shell, still keyless, still no root service. D-25's DDC descope still
-- holds: external-monitor brightness stays out of scope, laptop-backlight
-- path only.
-- `|| brightnessctl` fallback: routing through the shell is what lets
-- BrightnessBackend emit the change itself (D-20-05 — the trigger is backend
-- state, never the keybind), but it makes the key depend on quickshell being
-- alive. On 2026-08-15 the shell was down for several minutes on a missing
-- QML import; during that window these keys would have done nothing at all.
-- The fallback trades the OSD (which cannot render with no shell anyway) for
-- the brightness change still happening. `timeout 2` bounds a hung IPC call
-- so the fallback is reachable rather than blocking on it.
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("timeout 2 qs ipc call -- osd raise || brightnessctl --class=backlight set 5%+"), { locked = true, repeating = true }) -- Raise brightness
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("timeout 2 qs ipc call -- osd lower || brightnessctl --class=backlight set 5%-"), { locked = true, repeating = true }) -- Lower brightness

-- ── Media controls ───────────────────────────────────
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true }) -- Next track
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true }) -- Toggle play/pause
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true }) -- Toggle play/pause
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true }) -- Previous track

-- Scroll nicely in the terminal
hl.window_rule({
    name = "scroll-touchpad-kitty",
    match = { class = "kitty" },
    scroll_touchpad = 1.5,
})
