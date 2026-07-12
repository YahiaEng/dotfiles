---
phase: 06-themed-surfaces-utility-suite
plan: 13
subsystem: infra
tags: [swayosd, systemd, autostart, uwsm, install-sh, theme-engine, reload]

# Dependency graph
requires:
  - phase: 06-themed-surfaces-utility-suite
    provides: "swayosd-client keybinds (XF86Audio*/mic-mute) already bound in keybinds.conf; swayosd package + style.css template already installed and rendered by Phase 6 earlier plans"
provides:
  - "swayosd-server launched at session start (autostart.conf), so swayosd-client has a server to talk to"
  - "swayosd-libinput-backend.service enabled on the correct (system) bus with sudo, non-silenced, for keyless caps-lock OSD"
  - "reload.sh theme-switch restarts swayosd-server (not the libinput backend) so the OSD pill re-themes with the rest of the desktop"
affects: [06-VERIFICATION, 06-REVIEW]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "swayosd-server relaunch mirrors the walker kill-then-detached-relaunch idiom (bounded exit poll, set -e-safe increment, setsid uwsm app -- <daemon> & disown) but omits walker-specific D-Bus bus-name/elephant health gates that swayosd-server has no equivalent of"

key-files:
  created: []
  modified:
    - hypr/.config/hypr/config/autostart.conf
    - install.sh
    - theme-engine/.config/theme-engine/lib/reload.sh

key-decisions:
  - "swayosd-server launched via exec-once = uwsm app -- swayosd-server, placed after hypridle and before theme-init, matching the existing uwsm-scoped daemon convention"
  - "swayosd-libinput-backend.service is a system (root) unit shipped only at /usr/lib/systemd/system/ by the extra/swayosd package — corrected from systemctl --user (which silently no-ops on a nonexistent unit) to sudo systemctl enable --now on the system bus, with failure reported to stderr instead of swallowed"
  - "reload.sh's theme-switch hook now restarts swayosd-server itself (the CSS-rendering process) rather than the libinput backend (a hardware-key forwarder with no CSS to reload) — corrected per 06-REVIEW.md WR-01"

requirements-completed: [OSD-01]

coverage:
  - id: D1
    description: "swayosd-server launched at session start via exec-once in autostart.conf, giving swayosd-client (already bound to volume/mute/mic-mute keys) a server to perform changes and render the themed pill"
    requirement: OSD-01
    verification:
      - kind: other
        ref: "grep -Fxq 'exec-once = uwsm app -- swayosd-server' hypr/.config/hypr/config/autostart.conf && single-occurrence count check"
        status: pass
    human_judgment: true
    rationale: "Static grep confirms the exec-once line exists exactly once, but only a live Hyprland session (pressing XF86AudioRaiseVolume etc. and observing the themed pill) proves the fresh-install regression is actually closed — this repo has no automated compositor-level UI test harness."
  - id: D2
    description: "install.sh enables swayosd-libinput-backend.service on the system bus with sudo (corrected from the wrong --user bus) and reports enable failure to stderr instead of silencing it"
    requirement: OSD-01
    verification:
      - kind: other
        ref: "bash -n install.sh && grep -Fq 'sudo systemctl enable --now swayosd-libinput-backend.service' install.sh && grep -Fq 'swayosd-libinput-backend enable failed' install.sh && grep -Fq 'systemctl --user enable --now dbus-broker.service' install.sh (pipewire/dbus-broker user-bus enables unchanged)"
        status: pass
    human_judgment: true
    rationale: "Syntax and grep checks confirm the correct enable invocation and non-silenced failure path are present, but only a real (or container/VM) install.sh run with `systemctl status swayosd-libinput-backend.service` can prove the system-bus enable actually succeeds against the packaged unit."
  - id: D3
    description: "reload.sh's theme-switch fan-out restarts swayosd-server (pkill + bounded exit poll + detached setsid relaunch) instead of the libinput backend, under the existing pgrep -x swayosd-server headless/no-op guard"
    requirement: OSD-01
    verification:
      - kind: other
        ref: "bash -n reload.sh && grep -Fq 'setsid uwsm app -- swayosd-server' && grep -Fq 'pkill -x swayosd-server' && grep -Fq 'pgrep -x swayosd-server' && no set -e-unsafe '(( waited++' pattern present"
        status: pass
    human_judgment: true
    rationale: "Static checks confirm the correct process is targeted and the set -e-safe increment form is used, but only a live theme switch (with swayosd-server already running) proves the pill actually re-themes and the switch doesn't hang or abort under set -e."

# Metrics
duration: 5min
completed: 2026-07-13
status: complete
---

# Phase 06 Plan 13: SwayOSD Gap Closure (OSD-01) Summary

**Fixed the last blocker from 06-VERIFICATION.md: swayosd-server was never launched anywhere in the repo, and install.sh enabled the caps-lock backend on the wrong systemd bus — both silenced, so pressing a volume/mute key did nothing on a fresh install.**

## Performance

- **Duration:** 5 min
- **Started:** 2026-07-13T01:59:00+03:00
- **Completed:** 2026-07-13T02:00:30+03:00
- **Tasks:** 3 completed
- **Files modified:** 3

## Accomplishments
- `swayosd-server` now launches at session start (`exec-once = uwsm app -- swayosd-server` in autostart.conf), so `swayosd-client` (already bound to `XF86Audio*`/mic-mute keys) has a server to perform the volume/mute change and render the themed OSD pill.
- `install.sh` now enables `swayosd-libinput-backend.service` on the correct system bus (`sudo systemctl enable --now`, not `--user`), with a stderr failure report instead of a silently swallowed error — the packaged unit only exists as a root system service, so the prior `--user` enable always no-op'd.
- `reload.sh`'s theme-switch fan-out now kills and detached-relaunches `swayosd-server` itself (the process that reads `style.css` at startup) instead of restarting `swayosd-libinput-backend.service` (which has no CSS to reload) — the pill now actually re-themes on a theme switch, mirroring the proven walker kill-then-relaunch idiom minus walker-specific gates.

## Task Commits

Each task was committed atomically:

1. **Task 1: Launch swayosd-server at session start (autostart.conf)** - `0170973` (fix)
2. **Task 2: Enable swayosd-libinput-backend on the system bus, non-silenced (install.sh)** - `60df627` (fix)
3. **Task 3: Restart swayosd-server (not the wrong-bus backend) on theme switch (reload.sh)** - `409f612` (fix)

_No TDD tasks in this plan — all mechanical launch/enable/restart corrections with static (`bash -n`/`grep`) verification._

## Files Created/Modified
- `hypr/.config/hypr/config/autostart.conf` - Added `exec-once = uwsm app -- swayosd-server` (new section, before theme-init), all other daemon entries unchanged.
- `install.sh` - Corrected the swayosd-libinput-backend enable from `systemctl --user enable --now ... 2>/dev/null || true` to `sudo systemctl enable --now ... || echo "  ⚠ swayosd-libinput-backend enable failed" >&2`; updated the adjacent comment to describe it as a system unit; pipewire/wireplumber and dbus-broker user-bus enables left untouched.
- `theme-engine/.config/theme-engine/lib/reload.sh` - Reworked the swayosd reload block: kept the `pgrep -x swayosd-server` guard, replaced the `timeout 5 systemctl --user restart swayosd-libinput-backend.service` call with `pkill -x swayosd-server` + a bounded exit poll (`osd_waited=$(( osd_waited + 1 ))`, set -e-safe) + `setsid uwsm app -- swayosd-server ... & disown`.

## Decisions Made
- Placed the new `swayosd-server` exec-once entry after `hypridle` and before the theme-init entry, so the server is up before the first theme apply paints the pill's CSS.
- Kept the `pgrep -x swayosd-server` guard as the sole headless/container safety valve in reload.sh (per 06-CONTEXT.md code_context), rather than adding a new guard — preserves the existing parity/container gate behavior unchanged.
- Did not copy walker's D-Bus bus-name (`busctl --user status`) or elephant-socket health gates into the swayosd block — swayosd-server has no equivalent well-known D-Bus name registration or backend health dependency, so those gates would be dead weight, not a mitigation.

## Deviations from Plan

None - plan executed exactly as written. One note: the plan's `verify` script for Task 3 greps for the literal pattern `(( *waited++`; my first draft of the explanatory comment (mirroring the walker section's own commentary) contained the illustrative string `(( waited++ ))` as prose, which the grep flagged as a false positive against actual code. Rephrased the comment to describe the safe form without embedding the unsafe literal — no functional change, purely a comment-wording adjustment to avoid tripping the plan's own static check.

## Issues Encountered
None.

## User Setup Required
None - no external service configuration required. On the next fresh install, `install.sh` will prompt for `sudo` when enabling `swayosd-libinput-backend.service` (same privilege-elevation pattern already used elsewhere in the script for pacman/system steps).

## Next Phase Readiness
OSD-01 is now closed at the source level (all three defects from 06-VERIFICATION.md Truth #3 corrected and statically verified). Live verification (pressing volume/mute keys on a running session, and confirming the pill re-themes across a static→dynamic switch) is left to the next `/gsd-execute-phase` verification pass or a manual re-run of `06-VERIFICATION.md`'s OSD-01 check — no blockers for that pass; all three files are syntax-valid and match the fix shapes specified in `06-REVIEW.md` (CR-01, CR-02, WR-01).

---
*Phase: 06-themed-surfaces-utility-suite*
*Completed: 2026-07-13*

## Self-Check: PASSED

- FOUND: hypr/.config/hypr/config/autostart.conf
- FOUND: install.sh
- FOUND: theme-engine/.config/theme-engine/lib/reload.sh
- FOUND: .planning/phases/06-themed-surfaces-utility-suite/06-13-SUMMARY.md
- FOUND commit: 0170973
- FOUND commit: 60df627
- FOUND commit: 409f612
- FOUND commit: 8546a25
