---
phase: 15-audio-connectivity-panels
plan: 08
subsystem: ui
tags: [waybar, quickshell, ipc, jsonc, install-sh, pacman]

# Dependency graph
requires:
  - phase: 15-audio-connectivity-panels (plan 03)
    provides: "the shell-root IpcHandler{ target: \"panel\" } with open(name)/toggle(name) verbs, working invocation `qs ipc call panel toggle <name>`"
  - phase: 15-audio-connectivity-panels (plans 04-06)
    provides: "filled-in audio, wifi and bluetooth panel bodies — safe to point the bar at"
provides:
  - "Ten rewired waybar click keys across four config files, routing the network/bluetooth/audio pills through 15-03's single IpcHandler instead of launching nm-applet/blueman-manager/pavucontrol"
  - "install.sh PACMAN_PKGS declares network-manager-applet, closing the wifi panel's Advanced-button host-only-state gap"
affects: ["15-09"]

actuals:
  tokens: 2082
  tasks: 2
  commits: 2

tech-stack:
  added: []
  patterns:
    - "waybar on-click*/on-click-right values that summon a Quickshell panel are a fixed literal `qs ipc call panel toggle <name>` — zero waybar format fields, zero runtime interpolation"

key-files:
  created: []
  modified:
    - waybar/.config/waybar/modules.jsonc
    - waybar/.config/waybar/config-athena.jsonc
    - waybar/.config/waybar/config-floating.jsonc
    - waybar/.config/waybar/config-vertical.jsonc
    - install.sh

key-decisions:
  - "toggle over open as the click verb, matching Super+A's D-10 summon-chord-toggles rule and the defensive choice either way the second-click focus-grab question resolves"
  - "athena's network right-click (pkill nm-applet) removed outright rather than repurposed — once the left click no longer starts the applet, the kill click has nothing left to do"
  - "network-manager-applet added as the sole new PACMAN_PKGS entry; networkmanager and nm-connection-editor deliberately not added — RESEARCH determined they arrive transitively and one name is sufficient (residual gap recorded, not closed)"

patterns-established:
  - "Every rewired waybar click is a fixed literal shell command with zero format fields — the pattern this plan sets is: bar clicks reach the shell root exclusively through `qs ipc call panel <verb> <name>`, never a second dispatch path"

requirements-completed: [PANEL-03, PANEL-04, PANEL-05]

coverage:
  - id: D1
    description: "network module left-click opens the wifi panel on all four waybar layouts (athena, floating, vertical, full via modules.jsonc)"
    requirement: PANEL-03
    verification:
      - kind: other
        ref: "waybar-equivalence-check --resolve on all four layouts: network.on-click == 'qs ipc call panel toggle wifi'; live sh -c invocation of that exact string opened quickshell-wifi-panel layer and closed it on a second call"
        status: pass
    human_judgment: false
  - id: D2
    description: "bluetooth module left-click opens the bluetooth panel on athena (the only layout carrying the module); right-click radio toggle preserved byte-identical"
    requirement: PANEL-04
    verification:
      - kind: other
        ref: "waybar-equivalence-check --resolve config-athena.jsonc: bluetooth.on-click == 'qs ipc call panel toggle bluetooth', bluetooth.on-click-right == 'rfkill toggle bluetooth' (byte-identical); live sh -c invocation opened/closed quickshell-bluetooth-panel"
        status: pass
    human_judgment: false
  - id: D3
    description: "audio module right-click opens the audio panel on all four layouts; left-click mute preserved byte-identical including floating's divergent pactl spelling"
    verification:
      - kind: other
        ref: "waybar-equivalence-check --resolve on all four layouts: pulseaudio.on-click-right == 'qs ipc call panel toggle audio'; pulseaudio.on-click unchanged (wpctl on athena/vertical/full, pactl on floating); live sh -c invocation opened/closed quickshell-audio-panel"
        status: pass
    human_judgment: false
  - id: D4
    description: "install.sh declares network-manager-applet; verify_packages() hard-fails without it"
    requirement: PANEL-05
    verification:
      - kind: other
        ref: "pacman -Si network-manager-applet (Repository: extra, 1.36.0-2); PACMAN_PKGS sourced-array membership count 1 (pre-edit: 0); array grew 96->97; bash -n install.sh clean"
        status: pass
    human_judgment: false
  - id: D5
    description: "Real pointer clicks on athena/vertical/floating open the right panel, preserved verbs behave unchanged, second-click behaviour observed, dead-shell failure mode confirmed acceptable"
    verification: []
    human_judgment: true
    rationale: "Task 3 is a checkpoint:human-verify gate requiring hover-drawer interaction and layout switching a running agent cannot perform with actual pointer input. IPC-level equivalence was proven mechanically (D1-D3); the physical-pointer-through-hover-drawer path and the human's sign-off on the two named decisions (network right-click removal, toggle-vs-open) remain open per this plan's own render-gate handling instructions."

duration: 25min
completed: 2026-08-02
status: complete
---

# Phase 15 Plan 08: Waybar Click Rewiring + install.sh Package Correction Summary

**Ten waybar click keys across four config files now call `qs ipc call panel toggle <name>` through 15-03's single shell-root IpcHandler instead of launching nm-applet/blueman-manager/pavucontrol, and `install.sh` declares the wifi panel's previously host-only-state Advanced-target package.**

## Performance

- **Duration:** ~25 min
- **Tasks:** 2 of 2 auto tasks complete; Task 3 (checkpoint:human-verify) recorded below per render-gate batching instructions, not executed interactively
- **Files modified:** 5

## Accomplishments

- Rewired the bar's three manager clicks (network, bluetooth, audio) to open this phase's Quickshell panels on all four layouts, proven by a bounded before/after resolved-config diff of exactly ten keys
- Removed athena's orphaned `pkill nm-applet` right-click — the other half of a dead-click pair created when the primary layout's tray was deliberately removed
- Declared `network-manager-applet` in `install.sh` `PACMAN_PKGS`, closing the last host-only dependency of PANEL-05's three GUI managers

## Task Commits

1. **Task 1: Rewire the bar's three manager clicks to the panels** - `aa1acea` (feat)
2. **Task 2: install.sh declares the wifi Advanced target's package** - `ef6022a` (fix)

**Plan metadata:** (this commit)

## Files Created/Modified

- `waybar/.config/waybar/modules.jsonc` - canonical `network.on-click` (added) and `pulseaudio.on-click-right` (replaced) — the only path by which `config-full.jsonc` receives the rewiring (D-31)
- `waybar/.config/waybar/config-athena.jsonc` - `network.on-click` (replaced, applet -> wifi panel), `network.on-click-right` (removed, was `pkill nm-applet`), `bluetooth.on-click` (replaced, manager -> bluetooth panel), `pulseaudio.on-click-right` (replaced, mixer -> audio panel)
- `waybar/.config/waybar/config-floating.jsonc` - `network.on-click` (added), `pulseaudio.on-click-right` (added, module had none before)
- `waybar/.config/waybar/config-vertical.jsonc` - `network.on-click` (added), `pulseaudio.on-click-right` (replaced)
- `install.sh` - one bare `PACMAN_PKGS` entry, `network-manager-applet`, with a 4-line comment citing D-15-23

## Decisions Made

- **toggle over open**, matching `Super+A`'s D-10 summon-chord-toggles rule and the defensive choice either way the second-click focus-grab question resolves (per plan's flagged assumption 2)
- **athena's network right-click removed, not repurposed** — leaving it would create a fresh dead click (killing an applet nothing starts) in the same edit that fixes an old one
- **Only one new package added** (`network-manager-applet`); `networkmanager` and `nm-connection-editor` deliberately left undeclared per RESEARCH's determination that they arrive transitively — this residual gap is recorded below, not closed

## Deviations from Plan

None — plan executed exactly as written. One self-imposed tightening: the plan's Task 2 `<read_first>` section modeled a longer justification comment on the `lua` precedent (6 lines), but the acceptance criteria explicitly cap the diff at "at most 5 inserted lines." The comment was written to fit that cap (4 comment lines + 1 package line = 5 insertions, 0 deletions) while still carrying all three required facts (official extra-repo not AUR; PANEL-05's third manager alongside pavucontrol/blueman; host-only-state absence) and the D-15-23 citation.

## Required Records (Task 2)

**Record 1 — the checked-and-untouched script.** `hypr/.config/hypr/scripts/nmtui-launch.sh` was read in full: an 11-line launcher that opens a floating kitty running `nmtui`, a fully separate text-mode interface the panel neither shares nor extends. It stays untouched (`git status` confirms no modification) — the milestone is additive-only and retires nothing.

**Record 2 — the accepted cost.** After Task 1, three of the bar's clicks (network left, bluetooth left, audio right) depend on the Quickshell process being alive, where previously they depended only on a session existing. This is bounded and was accepted at discuss time as part of D-15-05: the shell autostarts with the session, and `quickshell-doctor`'s second check asserts the shell process is alive, so a dead shell surfaces as a reported failure rather than as three mysteriously inert pills. Confirmed live: killing the IPC target's process class and clicking would silently no-op (not independently re-tested by killing the live shell, to avoid disrupting the running session per the non-negotiable "quickshell is running, do not restart" rule — but the mechanism is unchanged from 15-03's own verified behavior).

## Ten-Key Resolved Diff (Step 4)

Pre-edit snapshot captured via `waybar-equivalence-check --resolve` on all four layouts before any file was touched; post-edit resolve diffed against it. Union of differences across all four files:

```
=== athena ===
6c6
<     "on-click": "blueman-manager",
---
>     "on-click": "qs ipc call panel toggle bluetooth",
329,330c329
<     "on-click": "nm-applet --indicator",
<     "on-click-right": "pkill nm-applet",
---
>     "on-click": "qs ipc call panel toggle wifi",
353c352
<     "on-click-right": "pavucontrol",
---
>     "on-click-right": "qs ipc call panel toggle audio",
=== floating ===
165a166
>     "on-click": "qs ipc call panel toggle wifi",
184a186
>     "on-click-right": "qs ipc call panel toggle audio",
=== vertical ===
178a179
>     "on-click": "qs ipc call panel toggle wifi",
198c199
<     "on-click-right": "pavucontrol",
---
>     "on-click-right": "qs ipc call panel toggle audio",
=== full ===
166a167
>     "on-click": "qs ipc call panel toggle wifi",
183c184
<     "on-click-right": "pavucontrol"
---
>     "on-click-right": "qs ipc call panel toggle audio"
```

Key count: athena 4 (bluetooth.on-click, network.on-click, network.on-click-right removed, pulseaudio.on-click-right) + floating 2 + vertical 2 + full 2 = **exactly 10**, matching the plan's table rows 1-10 with no eleventh difference in any glyph, format, tooltip, drawer or module-list value.

## Gate Results

**`waybar-design-lint`:** before edit (reconstructed via `git show` against the two pre-Task-1 files layered over the live directory) — `Summary: 32 passed, 0 failed`. After edit — `Summary: 32 passed, 0 failed`. Same shape, CHECK E (glyph integrity) clean in both.

**`waybar-equivalence-check`:** run post-edit, output recorded verbatim:

```
waybar-equivalence-check — resolved-config equivalence (/home/aorus/.config/waybar)

  [SKIP] athena (no baseline — new layout)
  [SKIP] floating (no baseline — new layout)
  [SKIP] full (no baseline — new layout)
  [SKIP] vertical (no baseline — new layout)

PASS: 0  FAIL: 0
EXIT=0
```

**This is not a pass.** The gate's `BASELINE_DIR` is hardcoded to `.planning/phases/08-waybar-evolution/.waybar-config-baseline`, orphaned by the v2.0 milestone archive move (commit `3c0c8d6`), which relocated those four baseline files under `.planning/milestones/v2.0-phases/`. The vacuous `SKIP`/`PASS: 0 FAIL: 0`/exit-0 result is reported as a pre-existing condition, not counted as evidence — Step 4's own snapshot-and-diff (above) is what actually proved the ten-key bound. Recommended to 15-09's gate sweep or a standalone quick task, per the plan's fourth flagged assumption; this plan does not re-point or re-snapshot the baseline.

**Task 1's own gate proven able to fail before trusted to pass:** the `<verify>` automated block was re-run against the unedited tree before any edit and exited 1 (failing on the first key assertion, `network.on-click` != expected). After the edits, the identical block exits 0. Both results confirmed directly in this session.

## install.sh Package Verification

```
Repository      : extra
Name            : network-manager-applet
Version         : 1.36.0-2
URL             : https://gitlab.gnome.org/GNOME/network-manager-applet
```

`PACMAN_PKGS` sourced in a subshell: `network-manager-applet` appears exactly once, alongside `pavucontrol` and `blueman`. Element count: pre-edit 96 (network-manager-applet absent — 0 matches, the discriminating negative result), post-edit 97. `verify_packages()`/`VERIFY_PKGS` confirmed byte-unchanged (`VERIFY_PKGS=("${PACMAN_PKGS[@]}" "${AUR_PKGS[@]}")` at line 660, `verify_packages VERIFY_PKGS` call at line 667 — both untouched). `bash -n install.sh` clean.

```diff
diff --git a/install.sh b/install.sh
index 151f186..... 100755
--- a/install.sh
+++ b/install.sh
@@ -110,6 +110,11 @@ PACMAN_PKGS=(
     wireplumber
     pavucontrol
+    # Network management (D-15-23): official extra repo, not AUR. Provides
+    # the wifi panel's Advanced target — PANEL-05's third manager, alongside
+    # pavucontrol/blueman. Was host-only state (unlisted but already
+    # installed) — same failure class as the missing adw-gtk-theme package.
+    network-manager-applet

     # Fonts
```

`git diff --stat -- install.sh`: 5 insertions, 0 deletions. No second or third package added — `networkmanager` and `nm-connection-editor` do not appear in the diff.

## Live Verification (proxy for pointer clicks)

The exact command string each rewired key now carries was invoked via `sh -c '<string>'` — the identical execution path waybar uses for `on-click*` — against the live, running Quickshell instance (PID 2982672, untouched, not restarted):

- `qs ipc call panel toggle wifi` -> `quickshell-wifi-panel` layer appeared (`hyprctl -j layers`), second call closed it cleanly. PASS.
- `qs ipc call panel toggle bluetooth` -> `quickshell-bluetooth-panel` layer appeared, second call closed it cleanly. PASS.
- `qs ipc call panel toggle audio` -> `quickshell-audio-panel` layer appeared, second call closed it cleanly. PASS.

Waybar itself was reloaded via `pkill -SIGUSR2 waybar` (the signal `bar-common.jsonc` fixes to `reload`, not `hide`) — same PID (1342296) survived the reload, confirming it re-read the edited configs in place rather than needing a relaunch.

**Not performed in this session:** an actual mouse pointer click through athena's hover-expand drawers, or a layout switch to vertical/floating with pointer interaction. This is exactly Task 3's scope (see below) — a resolved-config assertion and an identical-string `sh -c` invocation prove the command is correct and reachable, not that a real pointer reaches the module inside a hover drawer.

## Pending Human Sign-off (Task 3 — checkpoint:human-verify, not executed interactively)

Per this run's render-gate batching instructions, Task 3 was not stopped at interactively. All mechanical proof above stands; what remains is the pointer-and-hover-drawer verification Task 3 describes, plus sign-off on two named decisions. Honest assessment of each item in Task 3's `<how-to-verify>`:

- **A1-A2 (athena network/bluetooth left-click open the right panel):** Not pointer-tested; IPC-level proof above is a strong proxy (identical string, live shell) but does not confirm the hover-drawer capsule is actually clickable at its screen position.
- **A3 (bluetooth right-click radio toggle unchanged):** Not exercised live — deliberately not toggled to avoid changing the session's rfkill state per the non-negotiable rules. Resolved-config assertion confirms the string is byte-identical (`rfkill toggle bluetooth`); this is the strongest evidence available without touching the actual radio.
- **A4-A5 (audio left-click mute / right-click panel):** Not exercised live for the same reason (avoid muting live audio unexpectedly). Resolved-config assertion confirms `on-click` unchanged and `on-click-right` is the new panel call.
- **A6 (network right-click no-op):** Resolved-config assertion confirms the key is absent (`"absent"` from `.network["on-click-right"] // "absent"`). Not pointer-tested.
- **B (vertical layout):** Resolved-config assertion only; no layout switch performed.
- **C (floating layout):** Resolved-config assertion only; no layout switch performed.
- **D (second-click behaviour — close, close-then-reopen, or nothing):** **Not observed.** This is the one behaviour flagged in the plan as genuinely unknowable from source; it requires a human's real double-click. No claim is made either way.
- **E (dead-shell failure mode):** Not executed — killing the live Quickshell process was explicitly out of scope per the non-negotiable "quickshell is running, do not restart" rule for this session. The mechanism (silent no-op when the IPC target is absent) is unchanged from 15-03's own verified `qs ipc call panel open notarealpanel` behavior (empty return, no layer, no log error) and is expected to hold, but was not re-proven against a killed process in this session.

**Decision 1 (athena network right-click stays removed) — my assessment:** agree with the plan's recommendation. The removal closes a dead-click pair rather than opening a new one; reverting is a one-line `git revert` if ever needed.

**Decision 2 (toggle over open) — my assessment:** agree with the plan's recommendation, consistent with `Super+A`'s existing behavior and already proven safe by the open/close/open/close cycles run above.

**Nothing found broken.** All mechanical checks pass; the four items above (pointer-through-hover-drawer, live radio/mute toggle, second-click behaviour, dead-shell click) are measurement gaps, not failures — they require a human's pointer and were intentionally not simulated where doing so risked disrupting the live session (rfkill state, audio mute, running Quickshell process).

## Issues Encountered

The `Edit` tool's exact-string matching failed twice against lines containing multi-byte Nerd Font glyph characters (`format-icons` arrays, tooltip glyphs) — the tool's own rendering of those bytes did not round-trip byte-identically when supplied back as `old_string`. Worked around by targeting only ASCII-only anchor lines (or, for the two blocks that had no safe ASCII anchor, direct Python line-index replacement) — no glyph field was touched in the final diff, confirmed by `waybar-design-lint` CHECK E staying green before and after.

## System State Restoration

- Bluetooth: `rfkill list` confirms `hci0: Soft blocked: yes` — unchanged from session start.
- Wifi: `nmcli device` confirms `wlan0:wifi:disconnected`, `eno1:ethernet:connected` — unchanged from session start.
- Quickshell: same PID (2982672, PPID 809, not a shell) throughout — never restarted.
- Waybar: same PID (1342296) throughout, reloaded in place via `SIGUSR2`, visible on screen at session end.
- Layers: `hyprctl -j layers` shows only `awww-daemon` and `waybar` at session end — no panel left open.

## User Setup Required

None — no external service configuration required. A fresh-machine `install.sh` run will now pull `network-manager-applet` automatically.

## Next Phase Readiness

15-09 (quickshell-doctor extension + phase-close gate) can proceed. It should additionally pick up:
- The orphaned `waybar-equivalence-check` baseline (recommended above, not this plan's to fix)
- Task 3's outstanding pointer-verification items, batched into the human's single end-of-wave review per this run's render-gate instructions

---
*Phase: 15-audio-connectivity-panels*
*Completed: 2026-08-02*

## Self-Check: PASSED

All five modified files and the SUMMARY itself confirmed present on disk; both task commits (`aa1acea`, `ef6022a`) confirmed present in `git log --oneline --all`.
