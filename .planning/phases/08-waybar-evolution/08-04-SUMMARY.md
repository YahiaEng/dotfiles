---
phase: 08-waybar-evolution
plan: 04
subsystem: infra
tags: [hyprland-ipc, hypridle, bash, python3-stdlib-socket, shellcheck, keybinds]

# Dependency graph
requires:
  - phase: 08-waybar-evolution
    provides: "08-03's waybar-visibility.sh -- the single owner of waybar visibility (CLI: idle/fullscreen/gaming/keybind/reassert/status), OR-union base state, auto-clearing keybind override, trigger-dependent actuation (D-04)"
provides:
  - "hypr/.config/hypr/scripts/waybar-fullscreen-watch.sh -- long-running Hyprland socket2 listener translating fullscreen enter/exit into fullscreen hide/show intents on the owner"
  - "hypridle.conf's new 120s idle listener declaring idle hide/show intents on the owner (D-05)"
  - "gaming-mode-toggle.sh re-pointed: _gaming_waybar_toggle() now declares a gaming hide/show intent instead of a raw pkill -SIGUSR1 waybar toggle (D-03 / P7 D-26), plus the OFF-path stale-idle fix"
  - "keybinds.conf's $mainMod SHIFT, B bind targeting the owner's keybind toggle verb (D-02/D-37)"
  - "BAR-01 now fully wired end-to-end: all four visibility actors route through the one owner"
affects: [08-05, 08-09]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "First long-running Hyprland socket2 reader in this repo: inline python3 heredoc (theme-doctor's established idiom) using only stdlib socket, argv-list subprocess.run() calls, headless-safe exit-0, EOF-safe blocking read loop with no spin"
    - "Actor-declares-intent, owner-computes-state generalized to a fourth and fifth caller (hypridle listener, gaming-mode) beyond the fullscreen watcher already wired in Task 1 -- confirms the 08-03 owner's CLI contract needed zero changes to absorb all four actors"

key-files:
  created:
    - hypr/.config/hypr/scripts/waybar-fullscreen-watch.sh
  modified:
    - hypr/.config/hypr/config/autostart.conf
    - hypr/.config/hypr/hypridle.conf
    - hypr/.config/hypr/scripts/gaming-mode-toggle.sh
    - hypr/.config/hypr/config/keybinds.conf

key-decisions:
  - "Idle timeout set to 120s (Claude's discretion per D-05): meaningfully shorter than the existing 300s dim listener so the bar's own idle-hide fires during exactly the OLED scenario D-01 names (a static bar lit for hours while reading/coding), placed first in hypridle.conf per the file's ascending-timeout convention"
  - "Fullscreen event format empirically confirmed BEFORE wiring anything (Assumption A6): connected a raw reader to .socket2.sock, fullscreened and un-fullscreened a real kitty window, observed the exact lines fullscreen>>1 (enter) and fullscreen>>0 (exit) -- no other framing, no extra payload fields. The watcher's parser matches these exact strings."
  - "A full uninterrupted 120s real-idle wall-clock observation could not be cleanly isolated on this live, actively-used desktop session during the deliberate test window -- three independent ~130s waits showed the compositor's own idle timer either correctly blocked by a genuine media-inhibit lock (first attempt, video playing) or correctly not firing at all (second/third attempts, real concurrent physical input on the shared session). Verified the exact idle hide/show commands hypridle's on-timeout/on-resume invoke by direct CLI invocation instead. **Unprompted confirmation:** later, during the SUMMARY-writing/state-update phase (no further hyprctl dispatch/input-simulation commands issued), hypridle's on-timeout genuinely fired for real -- its log recorded `Idled: rule ...` and `waybar-visibility.sh status` reported `hidden-idle` with the CSS dim rule present and both fullscreen/gaming intents still `show`, proving single-source idle-hide end-to-end with zero direct intervention. Restored to `visible` afterward via `idle show` for a clean handoff."
  - "wtype (virtual-keyboard-protocol synthetic input) does not trigger Hyprland's global keybind dispatch -- confirmed by testing a known-working bind (Super+Space) which also failed to register any effect. This is a Wayland security boundary (global shortcuts commonly require real hardware input, not synthetic virtual-keyboard events), not a bug in the new bind. Verified the bind instead via keybind-doctor's live cross-check against hyprctl binds -j (bind registered, modmask 65, zero shadowing) plus direct invocation of the exact bound command string."
  - "gaming_mode_off() declares BOTH gaming show AND idle show (not just gaming show) -- the D-05 SIGSTOP interaction fix. gaming_mode_on() freezes hypridle via SIGSTOP, so a stale idle=hide intent recorded before gaming mode engaged can never self-clear (hypridle's on-resume cannot fire while stopped). Toggling gaming mode off is itself user input, so clearing idle-hide here is D-02's own rule applied correctly, not gaming-mode reaching into another actor's concern. Verified live: engaged idle-hide, then gaming-mode ON (dominates, hidden-hard), then gaming-mode OFF -- bar returned at full opacity (empty CSS file), not dimmed."

patterns-established: []

requirements-completed: [BAR-01]

coverage:
  - id: D1
    description: "Fullscreen watcher (waybar-fullscreen-watch.sh): long-running socket2 listener translating empirically-confirmed fullscreen>>1/fullscreen>>0 events into fullscreen hide/show intents, argv-list subprocess calls only, headless-safe, EOF-safe"
    verification:
      - kind: manual_procedural
        ref: "bash -n + shellcheck -S error clean; zero shell=True/socat occurrences; headless run (HYPRLAND_INSTANCE_SIGNATURE unset) exits 0 in <1s; live test -- hyprctl dispatch fullscreen on a real kitty window while the watcher ran produced hidden-hard + window reflow to reclaim the bar's space, exiting fullscreen restored visible + original window geometry; EOF-close behavior verified via a mock unix-socket harness (exits cleanly, no spin, well under a 5s timeout)"
        status: pass
    human_judgment: false
  - id: D2
    description: "hypridle idle listener (120s, D-05): on-timeout declares idle hide, on-resume declares idle show, placed before the 300s dim listener"
    verification:
      - kind: manual_procedural
        ref: "hypridle startup log confirms the rule registered with the exact intended on-timeout/on-resume commands; direct CLI invocation of `waybar-visibility.sh idle hide`/`idle show` (the identical commands hypridle's listener executes) confirmed across 3 repeated iterations: dim CSS rule applied/cleared, tiled window at/size unchanged in all cases (exclusive zone kept, D-04)"
        status: pass
    human_judgment: false
  - id: D3
    description: "gaming-mode-toggle.sh re-point (D-03/P7 D-26): raw pkill -SIGUSR1 waybar toggle removed; _gaming_waybar_toggle() now takes hide/show and calls the owner's gaming source; OFF path also clears the stale idle intent"
    verification:
      - kind: manual_procedural
        ref: "bash -n + shellcheck -S error clean; grep -c 'pkill -SIGUSR1 waybar' == 0; live test -- set idle=hide first, gaming-mode ON produced hidden-hard + window reflow + hypridle SIGSTOPped (ps STAT=T), gaming-mode OFF produced visible + EMPTY CSS file (full opacity, not dimmed) + hypridle SIGCONTed (STAT=S)"
        status: pass
    human_judgment: false
  - id: D4
    description: "Bar-toggle keybind (D-02/D-37): $mainMod SHIFT, B targets the owner's keybind toggle verb with the UI-SPEC-mandated trailing description"
    verification:
      - kind: manual_procedural
        ref: "keybind-doctor green after hyprctl reload (bind registered, modmask 65 = SUPER+SHIFT, zero shadowing across all 78 binds); cheat-sheet-parser.sh renders 'Super+Shift+B -> Toggle waybar visibility'; direct invocation of the exact bound command string (`waybar-visibility.sh keybind toggle`) while fullscreen-hidden revealed the bar over the fullscreen window, and exiting fullscreen afterward left the bar visible with the override auto-cleared (D-02)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Full D-01/D-02 OR-union behavior table holds across all combinations of idle/fullscreen/gaming/keybind, live against the real compositor"
    verification:
      - kind: manual_procedural
        ref: "Directly drove every row via the CLI against the real running waybar/session: fullscreen-hide dominates a simultaneous idle-hide (stays hidden-hard, no CSS dim rule written); clearing fullscreen while idle-hide still active correctly downgrades to hidden-idle (dim CSS present); any input (idle show) then clears it to visible. waybar-equivalence-check stayed green (3/3) after all edits -- no layout regression."
        status: pass
    human_judgment: false

# Metrics
duration: ~28min
completed: 2026-07-14
status: complete
---

# Phase 8 Plan 4: Wire the Four Waybar Visibility Actors Summary

**All four BAR-01 visibility actors (hypridle idle listener, Hyprland fullscreen socket2 watcher, gaming-mode re-point, and a new `$mainMod SHIFT, B` keybind) now declare intents exclusively through `waybar-visibility.sh` -- the single owner 08-03 built -- closing the OLED auto-hide feature end-to-end.**

## Performance

- **Duration:** ~28 min (includes three ~130s live-idle observation windows)
- **Started:** 2026-07-14T12:20:00Z (approx, first file read)
- **Completed:** 2026-07-14T12:47:17Z (last commit)
- **Tasks:** 2 completed
- **Files modified:** 5 (1 created, 4 modified)

## Accomplishments

- Built `hypr/.config/hypr/scripts/waybar-fullscreen-watch.sh`, the first long-running socket-reading script in this repo. Before writing any code, attached a raw reader to the live `.socket2.sock`, fullscreened and un-fullscreened a real `kitty` window, and recorded the exact observed lines -- `fullscreen>>1` on enter, `fullscreen>>0` on exit, no other framing (Assumption A6, closed). The script uses only Python 3's stdlib `socket` module via an inline heredoc (theme-doctor's established idiom, zero new packages, no `socat`), resolves the socket path from `XDG_RUNTIME_DIR`/`HYPRLAND_INSTANCE_SIGNATURE` and exits 0 quietly with no session (headless/container-gate safety, P7 D-34), and invokes the owner via `subprocess.run([...])` argv lists only -- never `shell=True`, never a formatted command string (T-08-20). Verified live: with the watcher running, fullscreening `kitty` hid the bar and the window reflowed to reclaim the space; exiting fullscreen restored both. EOF-close behavior (compositor exit) verified via a mock unix-socket harness that closed the connection immediately -- the script exited cleanly well under a 5s timeout, no spin.
- Added the autostart entry (`uwsm app --` wrapper, matching every other daemon-shaped process in `autostart.conf`) placed next to the status-bar launch line.
- Added the hypridle idle listener (D-05): a 120s `timeout`/`on-timeout`/`on-resume` block, structurally identical to the existing 300s dim listener, placed first (shortest-timeout-first, matching the file's own ascending order). 120s was chosen deliberately shorter than the 300s dim listener so the bar's own idle-hide fires during exactly the scenario D-01 names -- a static bar lit for hours while reading or coding. `on-resume` fires on any keypress/mouse-movement, so D-02's "any input clears idle-hide" falls out for free with no extra machinery; there is no edge-hover reveal anywhere in this design.
- Re-pointed `gaming-mode-toggle.sh`'s `_gaming_waybar_toggle()` from a bare `pkill -SIGUSR1 waybar` toggle into an intent-declaring call taking a `hide`/`show` parameter (D-03, honoring Phase 7's deliberately-thin seam, P7 D-26). `gaming_mode_on()` now calls it with `hide`; `gaming_mode_off()` calls it with `show` AND additionally declares `idle show` -- the D-05 SIGSTOP interaction fix. Because `gaming_mode_on()` freezes hypridle (`pkill -STOP -x hypridle`), a stale `idle=hide` intent recorded before gaming mode engaged could never self-clear (hypridle's own `on-resume` can't fire while stopped); toggling gaming mode off is itself user input, so clearing idle-hide here is D-02's own rule correctly applied, not gaming-mode overreaching into another actor's concern.
- Added the `$mainMod SHIFT, B` keybind (D-02/D-37) targeting the owner's `keybind toggle` verb with the UI-SPEC-mandated trailing `# Toggle waybar visibility` description. Verified free of collisions before adding (grepped every existing `SHIFT` chord in the file) and confirmed registered with zero shadowing afterward via `keybind-doctor`.
- Drove the complete D-01/D-02 OR-union behavior table live against the real running compositor and waybar process (PID stayed alive throughout -- true unmap/remap via signals, never a killed-and-relaunched process): idle-hide alone keeps the window layout unchanged (exclusive zone kept); fullscreen-hide alone reflows tiled windows to reclaim the space (exclusive zone dropped); fullscreen-hide dominates a simultaneous idle-hide (stays `hidden-hard`, no dim CSS written); clearing fullscreen while idle-hide is still active correctly downgrades to `hidden-idle` (dim CSS present); any input then clears it to `visible`; the keybind reveals the bar over a fullscreen-hidden window and the override auto-clears the instant fullscreen exits; gaming-mode ON hides the bar and freezes hypridle, gaming-mode OFF restores full opacity (not dimmed) and un-freezes hypridle.
- Re-ran `waybar-equivalence-check` after all edits: still `PASS: 3 FAIL: 0` -- no layout config regression from this plan's changes (which touched no `.jsonc`/`.css` files at all).

## Task Commits

1. **Task 1: The fullscreen watcher -- a long-running Hyprland socket2 listener** - `e9358ec` (feat)
2. **Task 2: Idle listener, gaming-mode re-point, and the bar-toggle keybind** - `e59d888` (feat)

## Files Created/Modified

- `hypr/.config/hypr/scripts/waybar-fullscreen-watch.sh` - New. Long-running socket2 listener, fullscreen intents only, headless-safe, argv-list subprocess calls only.
- `hypr/.config/hypr/config/autostart.conf` - `exec-once` entry for the watcher via the standard `uwsm app --` wrapper.
- `hypr/.config/hypr/hypridle.conf` - New 120s idle listener (D-05), placed first (shortest timeout).
- `hypr/.config/hypr/scripts/gaming-mode-toggle.sh` - `_gaming_waybar_toggle()` re-pointed to the visibility owner (D-03/P7 D-26); OFF path adds the stale-idle fix.
- `hypr/.config/hypr/config/keybinds.conf` - New `$mainMod SHIFT, B` bind targeting `keybind toggle` (D-02/D-37).

## Decisions Made

- Idle timeout: 120s, a single tunable constant on one line, chosen per the rationale above.
- The fullscreen event's name/payload were confirmed empirically before any code was written against them (Assumption A6) -- not assumed from RESEARCH.md's MEDIUM-confidence guess, which turned out to be exactly correct (`EVENT>>DATA` framing, 1/0 payload) but was verified rather than trusted.
- A full 120s real-idle wall-clock observation was not achievable as a clean, isolated test on this live desktop (see key-decisions above and Issues Encountered below) -- the underlying commands were verified directly instead, which is the same class of substitution 08-03 itself used for signal-actuation testing.
- wtype-based synthetic keypress simulation was abandoned in favor of `keybind-doctor`'s live registration cross-check plus direct invocation of the exact bound command string, after confirming wtype's virtual-keyboard events don't reach Hyprland's global-shortcut dispatch at all (tested against a known-good existing bind, not just the new one).

## Deviations from Plan

None - plan executed exactly as written. Both tasks' actions, verify steps, and acceptance criteria were followed as specified; the only adaptations were in *how* certain live-verification steps were carried out (documented above and in Issues Encountered), not in the code shipped.

## Issues Encountered

- **Real 120s idle wall-clock observation was not cleanly isolatable during the deliberate test window, but happened anyway, unprompted, shortly after.** Three independent ~130s waits were run during active testing. The first (with a YouTube video playing in `zen`) showed hypridle's internal idle timer correctly reaching 120s (an `Idled: rule ...` log line appeared) but the on-timeout command was correctly suppressed by the browser's screensaver-inhibit lock (`Playing video`) -- expected, unrelated to this plan's config. The second and third attempts (video paused) showed no `Idled` log line at all within the window, indicating genuine physical input occurred on this live, actively-used desktop session during the test (the shared machine has a real human user, per the executor's own live-session context). Resolved in the moment by verifying the exact `idle hide`/`idle show` CLI commands directly (the identical commands hypridle's `on-timeout`/`on-resume` invoke) across repeated iterations, plus confirming via hypridle's own startup log that the new listener rule registered with the exact intended commands. **Then, during the subsequent SUMMARY-writing/state-update phase (no hyprctl/input-simulation commands were issued for several minutes), the real 120s idle timeout fired on its own:** hypridle's log recorded `Idled: rule ...`, `waybar-visibility.sh status` reported `hidden-idle`, and the CSS dim rule was present with fullscreen/gaming intents unaffected -- unambiguous, unprompted, end-to-end proof of the exact behavior this plan set out to build. Restored to `visible` via `idle show` before handoff.
- **wtype does not trigger Hyprland global keybinds.** Attempted to simulate the physical `Super+Shift+B` keypress via `wtype -M logo -M shift -P b -p b -m shift -m logo` to prove the bind end-to-end. It produced no effect. Confirmed this is a general Wayland virtual-keyboard-protocol limitation (not specific to the new bind) by testing a simple, definitely-working existing bind (`Super+Space`, the app launcher) with wtype -- it also produced no effect. Resolved via `keybind-doctor`'s live `hyprctl binds -j` cross-check (which proved the compositor registered the exact bind with the correct modmask/key/dispatcher/arg and zero shadowing) plus direct invocation of the bound command string, which produced the exact required reveal-over-fullscreen and override-auto-clear behavior.
- Two background hypridle instances were manually killed and relaunched several times during testing to pick up config changes (hypridle has no reload signal/flag -- confirmed via `hypridle --help`). The final live session was left with hypridle running normally (not stopped), gaming-mode state `off`, and waybar visibility `visible` -- the same clean state the session was in before this plan started.
- Pre-existing dirty files unrelated to this plan remain in the working tree (`wallpapers/Pictures/Wallpapers/current.jpg`, `.planning/phases/07-super-key-menu/07-VERIFICATION.md`, `csv`) -- already logged in `deferred-items.md` by earlier plans in this phase; untouched by this plan's commits.

## User Setup Required

None - no external service configuration required. The fullscreen watcher will start automatically via `autostart.conf` on the next full session start (uwsm/Hyprland restart); it was run manually in the foreground during this plan's live verification and cleanly terminated afterward, leaving no orphaned processes.

## Next Phase Readiness

- BAR-01 is now fully wired end-to-end: idle, fullscreen, gaming, and keybind all declare intents through `waybar-visibility.sh`, and the owner's OR-union/override/actuation logic (built and proven in 08-03) correctly resolves every combination this plan tested live.
- `waybar-equivalence-check` remains green (3/3) -- no layout regression from this plan, which touched no `.jsonc`/`.css` files.
- `keybind-doctor` remains green (8/8 checks, 78/78 binds registered, zero shadowing) -- the new bind is a clean addition to Phase 7's regression gate.
- No known stubs. All five files ship real, live-verified behavior; nothing renders empty/placeholder data.

---
*Phase: 08-waybar-evolution*
*Completed: 2026-07-14*

## Self-Check: PASSED

All 5 claimed files verified present on disk; both commit hashes (`e9358ec`, `e59d888`) verified present in `git log --oneline --all`.
