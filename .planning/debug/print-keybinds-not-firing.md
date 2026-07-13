---
status: diagnosed
trigger: "The 'Print' family shortcuts do not work on my keyboard. I tried running all the recording/screenshot scripts through terminal, they worked (with some issues)."
created: 2026-07-13T00:00:00Z
updated: 2026-07-13T00:45:00Z
---

## Current Focus

hypothesis: CONFIRMED (layered) — failure is at the key-event layer, not config/deployment/scripts: (1) ALT+Print structurally cannot match (XKB delivers Sys_Req, not Print, when Alt is held); (2) plain/Shift/Ctrl+Print binds provably never dispatched during UAT, and with every software layer verified intact, the physical PrtSc press is not delivering keysym Print (keycode 107) to Hyprland
test: complete — config/bind-table/deployment/scripts/remappers/keymap all verified; journal-channel evidence validated with a positive control (xkbcomp child stderr present in same unit journal)
expecting: n/a
next_action: return ROOT CAUSE FOUND to orchestrator (goal: find_root_cause_only — no fix applied)

reasoning_checkpoint:
  hypothesis: "Key-event layer failure: (1) bind = ALT, Print can never fire on the us keymap because <PRSC> is type PC_ALT_LEVEL2 with symbols [Print, Sys_Req] — Alt selects level 2 = Sys_Req; (2) for plain/Shift/Ctrl+Print, the binds are correctly registered but never received a matching Print key event during UAT — the press is not arriving as keysym Print from the user's keyboard"
  confirming_evidence:
    - "hyprctl binds: all 4 Print binds registered (modmask 0/1/4/8), configerrors empty, no submaps/keycode/catchall binds, scripts deployed executable, stow intact, no keyd/kanata/ckb-next/hwdb remappers"
    - "xkbcli compile-keymap --layout us: key <PRSC> { type PC_ALT_LEVEL2, symbols [Print, Sys_Req] } — deterministic Sys_Req on Alt (corroborated by upstream hyprwm/Hyprland discussion #11732 'weird alt + print bind handling')"
    - "Hyprland's uwsm unit journal (wayland-wm@hyprland.desktop.service) captures child stderr — proven by xkbcomp warnings present in it — yet contains ZERO getopt/satty/'Unrecognized image file format' lines EVER; a keybind-fired capture script post-install would have written exactly those errors there"
    - "Exactly ONE hyprshot PNG in ~ (02:49:57, matching the user's terminal run); the -r getopt bug forces hyprshot's non-raw save mode, so EVERY completed invocation leaves a PNG — zero PNGs from keypresses"
    - "Pre-install presses (tools installed 02:35, mid-UAT per pacman journal entry) would have raised a visible 'hyprshot not installed' notify-send — user (who reported every other error verbatim) reported none"
    - "Control: Super+X color-picker bind, added even later (Jul 12 21:00) than the Print binds, worked during the same UAT — config loading and newly-added-bind dispatch work in this session"
  falsification_test: "An interactive `wev` run showing the PrtSc key delivering keycode 107 / keysym Print while a plain `bind = , Print` still fails to dispatch would falsify the key-event-layer conclusion and re-point at a Hyprland 0.55.4 matcher bug (no such upstream reports found)"
  fix_rationale: "(for gap-closure planner — no fix applied here) Rebinding the family by keycode (`code:107`) bypasses keysym translation entirely: it deterministically fixes the ALT/Sys_Req case and is robust to keysym-level quirks; a 30-second wev check discriminates whether the user's keyboard emits keycode 107 at all — if it does not (e.g. Corsair iCUE onboard-profile remap), no Hyprland config can fix it and the remedy is at the keyboard hardware-profile level"
  blind_spots: "Could not observe an actual keypress (contract forbids blocking on interactive input), so the exact keyboard-side mechanism for the plain/Shift/Ctrl family (Corsair K70 onboard iCUE remap vs Fn state vs press on the secondary SINOWEALTH wireless board) is unconfirmed; a Hyprland 0.55.4 Print-keysym matching bug cannot be 100% excluded, only made unlikely (no upstream reports, all other keysym binds work)"

## Symptoms

expected: Print-family keybinds (Print / Shift+Print / Ctrl+Print / Alt+Print, per hypr/.config/hypr/config/keybinds.conf lines 54-57) trigger the screenshot/recording scripts under Hyprland
actual: Print-family shortcuts do nothing when pressed on the user's keyboard; the same scripts work when run manually from a terminal (with unrelated script-internal issues tracked in a separate gap)
errors: None surfaced by the keypress itself (no notification, no visible action)
reproduction: Press Print / Shift+Print / Ctrl+Print / Alt+Print in the live Hyprland session (UAT Test 2, .planning/phases/06-themed-surfaces-utility-suite/06-UAT.md)
started: Discovered during Phase 06 UAT, right after installing hyprshot/satty/gpu-screen-recorder/swayosd/hyprpicker/wtype (packages were missing until today); binds themselves were added by Phase 06

## Eliminated

## Evidence

- timestamp: 2026-07-13T00:00:00Z
  checked: Knowledge base (.planning/debug/knowledge-base.md)
  found: Does not exist; sibling session screenshot-script-errors.md covers the script-internal errors (separate gap)
  implication: No known-pattern candidate; proceed with fresh investigation

- timestamp: 2026-07-13T00:00:00Z
  checked: hypr/.config/hypr/config/keybinds.conf lines 50-57 (repo copy)
  found: |
    bind = , Print, exec, ~/.config/hypr/scripts/capture-region.sh
    bind = SHIFT, Print, exec, ~/.config/hypr/scripts/capture-window.sh
    bind = CTRL, Print, exec, ~/.config/hypr/scripts/capture-full.sh
    bind = ALT, Print, exec, ~/.config/hypr/scripts/record-toggle.sh
    Syntax looks valid (empty-mod comma form is correct); no submaps anywhere in the file
  implication: If these lines are loaded by the live session, binds should register; need hyprctl binds to confirm

- timestamp: 2026-07-13T00:05:00Z
  checked: Live Hyprland session — `hyprctl configerrors` and `hyprctl binds`
  found: configerrors is EMPTY. All four Print binds ARE registered (modmask 0/1/4/8 = none/Shift/Ctrl/Alt, key: Print, submap: "", catchall: false, dispatcher: exec, args pointing at ~/.config/hypr/scripts/{capture-region,capture-window,capture-full,record-toggle}.sh). 75 binds total.
  implication: Config parsing, sourcing, and bind registration all work. The failure is NOT in keybinds.conf syntax or config loading. Break is either key-event->keysym matching, or the exec'd script failing invisibly.

- timestamp: 2026-07-13T00:10:00Z
  checked: Deployment chain — ~/.config/hypr symlinks, script files, hyprland.conf sourcing
  found: ~/.config/hypr/config -> ../../dotfiles/hypr/.config/hypr/config (stow intact); deployed keybinds.conf identical to repo; hyprland.conf line 11 sources it; all four scripts exist at ~/.config/hypr/scripts/ with -rwxr-xr-x
  implication: Deployment is not the problem

- timestamp: 2026-07-13T00:12:00Z
  checked: Control test — does Hyprland log exec dispatches at all? (grep for color-picker, a bind the user CONFIRMED works, in hyprland.log)
  found: 0 matches for color-picker in the log; Hyprland 0.55.4 does not log exec args
  implication: Absence of capture-*.sh from hyprland.log proves nothing either way — need a different observability channel (user journal)

- timestamp: 2026-07-13T00:15:00Z
  checked: Keyboard hardware + timing — hyprctl devices, git history of keybinds.conf, misc:disable_autoreload
  found: Main keyboard = Corsair K70 RGB TKL Champion Series (desktop mechanical, layout us, numLock off); also a SINOWEALTH 2.4G wireless keyboard and Logitech PRO X headset present. Print binds entered keybinds.conf 2026-07-07 (commit 16d330f) — BEFORE the session started (Jul 11 15:44), so the initial config load already contained them. autoreload enabled (disable_autoreload=0). No keyd/kanata/ckb-next/interception-tools/input-remapper installed or running; no custom udev hwdb.
  implication: Binds were live in the session during UAT; no low-level remapper is intercepting the key

- timestamp: 2026-07-13T00:18:00Z
  checked: XKB keymap of the active us layout — `xkbcli compile-keymap --layout us`, key <PRSC> (keycode 107)
  found: "key <PRSC> { type= \"PC_ALT_LEVEL2\", symbols[1]= [ Print, Sys_Req ] };" — with Alt held, the key produces keysym Sys_Req, NOT Print
  implication: CONFIRMED sub-root-cause for Alt+Print (record-toggle): `bind = ALT, Print` can NEVER fire on a standard us keymap because the delivered keysym is Sys_Req. Well-known XKB/Hyprland quirk; needs `bind = ALT, code:107` or a Sys_Req keysym bind. Plain/Shift/Ctrl stay on level 1 (Print) and are unaffected by this quirk.

- timestamp: 2026-07-13T00:22:00Z
  checked: Artifact trail — hyprshot's non-raw mode saves PNGs named %Y-%m-%d-%H%M%S_hyprshot.png into ~ (per sibling session screenshot-script-errors.md); counted PNGs in ~
  found: Exactly ONE hyprshot PNG in ~ (2026-07-13-024955_hyprshot.png, 02:49:57 local — inside the UAT window, matching the user's terminal test). ~/Pictures/Screenshots is empty.
  implication: Every completed hyprshot invocation leaves a PNG (getopt bug forces non-raw save mode). One PNG = one completed terminal run. Zero additional PNGs from keybind presses.

- timestamp: 2026-07-13T00:25:00Z
  checked: DECISIVE — user journal (`journalctl --user --since "2026-07-12 20:00"`) for getopt/satty/hyprshot/capture/record output. Under uwsm, Hyprland exec'd scripts inherit stdout/stderr pointing at the journal; terminal runs print to the terminal instead.
  found: ZERO matches for getopt/satty/Unrecognized/capture-*/record-toggle stderr in the journal. Only match: the pacman install of hyprshot/satty/gpu-screen-recorder/swayosd/hyprpicker/wtype at 02:35:26.
  implication: If ANY Print bind had dispatched during UAT, the script's stderr (getopt error + satty 'Unrecognized image file format' x2) would be in the journal. It is not. The binds never dispatched — failure is at key-event -> bind matching, NOT a silently-failing script. (Also note: tools were installed at 02:35, mid-UAT; a pre-install keybind press would have raised a visible 'hyprshot not installed' notification — user reported none.)

- timestamp: 2026-07-13T00:27:00Z
  checked: /proc/bus/input/devices KEY capability bitmaps for all keyboards
  found: Both Corsair K70 and SINOWEALTH wireless keyboard advertise KEY_SYSRQ (bit 99) and have the kernel sysrq handler attached — standard full-keyboard bitmaps
  implication: Capability bitmaps cannot discriminate further; they only show the devices CAN emit PrtSc, not that the pressed key DOES

- timestamp: 2026-07-13T00:30:00Z
  checked: Shadowing — `hyprctl binds` for submap binds, keycode binds, per-key bind counts
  found: 0 binds in any submap; 0 binds by keycode; Print bound exactly 4 times (our four); no catchall binds
  implication: Nothing shadows or intercepts the Print binds inside Hyprland's bind table

## Eliminated (appended)

- hypothesis: "keybinds.conf syntax/parsing problem (empty-mod comma form, quoting, sourcing)"
  evidence: "hyprctl configerrors empty; all four binds registered with correct modmask/dispatcher/arg"
  timestamp: 2026-07-13

- hypothesis: "Stow symlinks broken / deployed config differs from repo / scripts missing or not executable"
  evidence: "Symlink chain verified; diff identical; all four scripts present with exec bits"
  timestamp: 2026-07-13

- hypothesis: "Binds not loaded at UAT time (config edited after session start, autoreload missed it)"
  evidence: "Print binds in file since 2026-07-07, session started 2026-07-11; binds registered in live session; autoreload enabled"
  timestamp: 2026-07-13

- hypothesis: "Binds fire but scripts fail silently (satty empty-stdin error, no visible UI)"
  evidence: "User journal (where uwsm-exec'd script stderr lands) contains ZERO getopt/satty errors for the whole UAT window; only one hyprshot PNG in ~ (from the terminal run); a fired region/window bind would also have shown the slurp crosshair and hyprshot's own non-raw-mode notification"
  timestamp: 2026-07-13

- hypothesis: "A submap, catchall, keycode bind, or duplicate bind shadows Print"
  evidence: "hyprctl binds: no submap binds, no keycode binds, Print bound exactly 4x, no catchall"
  timestamp: 2026-07-13

- hypothesis: "Low-level remapper (keyd/kanata/ckb-next/interception/input-remapper/udev hwdb) intercepts PrtSc"
  evidence: "None installed, none running, no custom hwdb entries"
  timestamp: 2026-07-13

- timestamp: 2026-07-13T00:40:00Z
  checked: Journal-channel validation (positive control) — does the Hyprland uwsm unit journal actually capture exec'd child stderr?
  found: wayland-wm@hyprland.desktop.service journal contains xkbcomp warnings (children writing inherited stderr) at 21:41:58 and 01:30:07 — the channel works. Same journal has 0 matches for getopt/satty/Unrecognized across its entire history.
  implication: The "no script stderr in journal" evidence is valid, not an artifact of a /dev/null stdio setup. No Print-family script was EVER spawned by a keybind in this session.

- timestamp: 2026-07-13T00:42:00Z
  checked: Timing control — Super+X color-picker bind (added Jul 12 21:00, LATER than the Print binds) worked during the same UAT
  found: User reported "Color picker is a pass" in UAT Test 2
  implication: Config reload and dispatch of newly-added binds provably work in this session; the failure is specific to the Print key events

- timestamp: 2026-07-13T00:43:00Z
  checked: Web corroboration (LOW confidence, secondary): hyprwm/Hyprland discussion #11732 "weird alt + print bind handling"; forum.hypr.land thread "Weird Print Screen behavior" (keyboards whose physical PrtSc maps to a non-Print keysym); no reports of a 0.55 Print-bind regression
  found: Upstream community documents both the Alt+Print/Sys_Req footgun and manufacturer-dependent PrtSc mappings
  implication: Both halves of the layered root cause match known ecosystem failure modes

## Resolution

root_cause: |
  Layered, at the key-event layer — the repo's binding->dispatch chain is intact (binds registered, scripts deployed+executable, no shadowing, no remappers):
  (1) CONFIRMED for Alt+Print (record-toggle, keybinds.conf line 57): the standard us XKB keymap defines key <PRSC> as type PC_ALT_LEVEL2 with symbols [Print, Sys_Req]. Holding Alt selects level 2, so the compositor receives keysym Sys_Req — `bind = ALT, Print` can NEVER match. Verified by compiling this machine's active keymap (xkbcli); corroborated upstream (hyprwm/Hyprland discussion #11732).
  (2) HIGH-CONFIDENCE for plain/Shift/Ctrl+Print (lines 54-56): the binds are correctly registered but provably never dispatched during UAT — the validated journal channel (which captures Hyprland children's stderr) contains zero getopt/satty errors, only one hyprshot PNG exists in ~ (from the user's terminal run), and pre-install presses would have raised a visible "not installed" notification (none reported). With every software layer eliminated, the user's physical PrtSc keypress is not delivering keysym Print / keycode 107 to Hyprland — most probable mechanisms, in order: Corsair K70 RGB TKL Champion onboard (iCUE) hardware-profile remap of PrtSc; the press happening on the secondary SINOWEALTH 2.4G wireless keyboard with an Fn-layered PrtSc; a Hyprland 0.55.4 Print-keysym matching bug (least likely — no upstream reports, all other keysym binds work). Discrimination needs one interactive `wev` observation, which this session was instructed not to block on.
fix: "NOT APPLIED (goal: find_root_cause_only). Direction for gap closure: rebind the family by keycode (`bind = , code:107` / SHIFT / CTRL / ALT variants) — keycode matching bypasses keysym translation and deterministically fixes the ALT/Sys_Req case; add a wev-based UAT step to confirm the physical key emits keycode 107 on the user's keyboard (if it does not, remedy is at the keyboard hardware-profile level, outside dotfiles); the hyprshot -r -> --raw fix (sibling session screenshot-script-errors.md) is prerequisite for the binds to produce the intended satty flow once they fire."
verification: ""
files_changed: []
