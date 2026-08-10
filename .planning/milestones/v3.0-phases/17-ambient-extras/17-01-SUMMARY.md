---
phase: 17-ambient-extras
plan: 01
subsystem: infra
tags: [mpvpaper, hyprland, wlr-layer-shell, wlr-foreign-toplevel-management, bash, ffmpeg, live-wallpaper]

# Dependency graph
requires: []
provides:
  - "mpvpaper declared as a hard AUR dependency in install.sh"
  - "~/Pictures/Wallpapers/<theme>/live/ layout reproducing from stow.sh for all 21 themes"
  - "hypr/.config/hypr/scripts/wallpaper-visibility.sh — sole owner of the live-wallpaper player's process lifecycle (D-14), select/clear/reassert/status verbs, idle/gaming/motion source allowlist declared (no callers wired)"
  - "Measured D-26 verdict: -p -a full ships as-is, D-27 fallback watcher NOT built"
  - "Measured -a mode decision: option-a (-a full) selected; -a max confirmed a no-op on this compositor build"
  - "Live proof that mp4/gif/webp all play as live wallpapers through one mpvpaper backend (D-01/D-04), loop-file=inf locked against regression"
affects: [17-02, 17-03, 17-04, 17-06]

# Actuals (#2632)
actuals:
  tokens: 5705
  tasks: 3
  commits: 4

tech-stack:
  added: [mpvpaper]
  patterns:
    - "Single-owner intent arbitration for a start/stop process (not a signal-driven daemon) — waybar-visibility.sh's shape adapted per D-29: never touch the child's own pause/IPC state, only start/stop it"
    - "Zombie-excluding process-liveness check (_mpvpaper_running, filters ps -o stat= for a leading Z) wherever a bare pgrep -x <name> would otherwise be trusted as a single-instance/liveness signal"
    - "SIGTERM-then-SIGKILL escalation on stop, bounded at each stage, when a target process may be CPU-heavy enough to defer signal handling"

key-files:
  created:
    - hypr/.config/hypr/scripts/wallpaper-visibility.sh
  modified:
    - install.sh
    - stow.sh
    - .gitignore

key-decisions:
  - "D-26 verdict: PASS. -p -a full pauses on a real fullscreen toggle (Zen Browser), confirmed via mpvpaper's own 'Pause triggered by:' log line and a /proc-delta CPU drop to 0.00-0.50% from a ~2-6.5% baseline, with resume confirmed on release. D-27's watcher was NOT built; stays scoped-but-unbuilt."
  - "-a mode: option-a (-a full) selected by the user after a corrected probe. -a max was initially miscredited with covering a distinct 'maximized' state; a direct -p -a full vs hl.dsp.window.fullscreen(1) control probe proved fullscreen(1) ('maximize', SUPER+SHIFT+F) enters the SAME compositor state as literal fullscreen on this Hyprland 0.56.2 build (fullscreen:2, edge-to-edge geometry, zwlr FULLSCREEN event) — -a full already pauses on it (CPU delta 0.00%). -a max is a confirmed no-op on this machine; this corroborates and explains the Phase 14 DASH-08 finding that Hyprland's IPC exposes no signal distinguishing 'fullscreen' from 'maximize' (they are, in fact, the same underlying state here, not merely unreported)."
  - "Neither -a full nor -a max covers a plain tiled window that merely fills its workspace (measured: steady CPU across a full loop boundary, zero pause trigger). Accepted knowingly — this repo's gaps_out leaves a visible border around such a window (2534x1368 on a 2560x1440 monitor), so it is not genuinely full occlusion."
  - "Rule 1 fix: the backgrounded mpvpaper child was inheriting the owner's flock fd (8), so a live wallpaper process silently held the lock open forever, deadlocking every later invocation — fixed with 8>&- on the launch."
  - "Rule 1 fix: the async launch could race a rapid consecutive invocation's own liveness check before the process registered, occasionally leaving two processes — fixed with a bounded post-launch registration wait, symmetric to the existing stop-side wait."
  - "Rule 1 fix: a bare pgrep -x mpvpaper is not a safe liveness/single-instance check — a defunct (zombie) mpvpaper still matches by name. Added _mpvpaper_running (filters ps -o stat= excluding Z) and used it everywhere a liveness check gates control flow."
  - "Rule 1 fix: animated-WebP decode is measurably far more CPU-expensive than mp4/gif (260-300% CPU sustained, measured live) and did not respond to a plain SIGTERM within the original 2s bounded wait (confirmed independently via a manual kill -TERM, still alive 3s later) — _stop_player now escalates to SIGKILL (cannot be caught/deferred) if the graceful window expires."
  - "Probe methodology finding, recorded for any future fullscreen/maximize probe on this repo: mpvpaper's -a tracks ANY tracked toplevel, not just the focused one. The agent's own terminal being genuinely fullscreen=2 on another workspace silently contaminated the first D-26-style probe attempt against -a max. Any future probe must confirm no window anywhere is fullscreen=2 before dispatching a test toggle."

patterns-established:
  - "_mpvpaper_running helper: never trust a bare `pgrep -x <name>` as a liveness/single-instance signal for a process that can leave a zombie entry — filter by ps -o stat= excluding a leading Z."
  - "_stop_player: SIGTERM with a bounded wait, then escalate to SIGKILL with a second bounded wait, for any process whose CPU load profile is not known to be light — a plain SIGTERM is not guaranteed prompt under heavy decode load."

requirements-completed: [AMB-01]

coverage:
  - id: D1
    description: "mpvpaper declared as a hard AUR dependency in install.sh (legitimacy-audited comment header) and installed on the machine"
    requirement: AMB-01
    verification:
      - kind: other
        ref: "grep -c '^ *mpvpaper$' install.sh (==1, inside AUR_PKGS); command -v mpvpaper && mpvpaper --help"
        status: pass
    human_judgment: false
  - id: D2
    description: "~/Pictures/Wallpapers/<theme>/live/ reproduces from stow.sh as a real (non-symlink) directory for every repo theme, with a matching .gitignore exclusion for media under it"
    requirement: AMB-01
    verification:
      - kind: other
        ref: "./stow.sh run live; ls -ld on all 21 theme live/ dirs (leading d, not l); git check-ignore -q on a probe path (exit 0)"
        status: pass
    human_judgment: false
  - id: D3
    description: "wallpaper-visibility.sh built as the sole owner of mpvpaper's process lifecycle (select/clear/reassert/status, intent-file arbitration, T-17-01 path validator, argv-array launch, D-29 no-IPC/no-pause discipline) and proven end-to-end: a real probe clip plays beneath the desktop on a mpvpaper-namespaced background layer surface"
    requirement: AMB-01
    verification:
      - kind: other
        ref: "select+reassert against a real ffmpeg-generated probe clip; hyprctl layers -j namespace==mpvpaper; pgrep -x mpvpaper single real PID; T-17-01 rejection cases (/etc/passwd, path-traversal) both exit nonzero and leave .selection unchanged"
        status: pass
    human_judgment: true
    rationale: "Task 1 is a type=tracer task; the plan's own D-26 checkpoint bundled a human confirmation that the visible wallpaper matched the executor's report ('approved') — the visual read is a human judgment, not purely mechanical."
  - id: D4
    description: "D-26 fullscreen probe: -p -a full pauses mpvpaper on a real fullscreen toggle and resumes on release, settled by execution against the installed binary rather than by reading upstream source"
    requirement: AMB-01
    verification:
      - kind: other
        ref: "mpvpaper -v log grep 'Pause triggered by:' (matched); /proc-delta CPU 0.00-0.50% during pause vs ~2-6.5% baseline; resumed after release"
        status: pass
    human_judgment: true
    rationale: "Plan-mandated blocking checkpoint (gate=blocking) — the human explicitly confirmed the branch taken ('approved') before Task 3 proceeded, per the plan's own design (an architecture branch, not a pure test result)."
  - id: D5
    description: "-a mode decision: option-a (-a full) selected after a corrected control probe proved -a max is a no-op on this compositor build"
    requirement: AMB-01
    verification:
      - kind: other
        ref: "-p -a full launched standalone, hl.dsp.window.fullscreen(1) dispatched, log grep 'Pause triggered by:' matched, /proc-delta CPU 0.00%"
        status: pass
    human_judgment: true
    rationale: "Plan-mandated blocking decision checkpoint — the user selected option-a explicitly after two rounds of corrected measurement; not an executor auto-decision."
  - id: D6
    description: "Animated GIF (150 frames) and animated WebP (format webp_anim) both play as live wallpapers through the same mpvpaper backend as the mp4 and are proven still advancing past their first pass (D-01/D-04, Pitfall 3)"
    requirement: AMB-01
    verification:
      - kind: other
        ref: "ffprobe nb_frames>1 for gif, format_name==webp_anim for webp; two grim captures per file taken after clip duration elapsed, cmp -s nonzero (not byte-identical) for both"
        status: pass
    human_judgment: false
  - id: D7
    description: "Sole-ownership and process-hygiene invariants: nothing outside wallpaper-visibility.sh starts/stops mpvpaper; switching between mp4/gif/webp never leaves two real processes or two layer surfaces; zombie entries are correctly excluded from every liveness check; a CPU-heavy decode that ignores SIGTERM is force-killed rather than silently leaving a duplicate process"
    requirement: AMB-01
    verification:
      - kind: other
        ref: "grep -rn mpvpaper across hypr/theme-engine/quickshell/waybar excluding wallpaper-visibility.sh (no other starter/killer found); full mp4->gif->webp->mp4 switch cycle re-verified post-fix, exactly one real (non-zombie) process and one layer surface at every step; double-reassert stays at one process"
        status: pass
    human_judgment: false

duration: ~50min (includes 3 human checkpoint round-trips: mpvpaper install auth gate, D-26 verdict confirmation, and a two-round corrected -a mode decision)
completed: 2026-08-09
status: complete
---

# Phase 17 Plan 01: Live Wallpaper Tracer Summary

**mpvpaper-backed live wallpaper proven end-to-end on Hyprland 0.56.2 — one video, one path, real fullscreen-pause measured against the installed binary, `-a max` measured and rejected as a no-op, GIF/WebP proven to advance past their first loop, and two real process-lifecycle races found and fixed live.**

## Performance

- **Duration:** ~50 min (multiple human checkpoint round-trips)
- **Started:** 2026-08-09T02:42:35Z (orchestrator phase-start marker)
- **Completed:** 2026-08-09T03:27:52Z
- **Tasks:** 3 (Task 1 tracer, Task 2 D-26 probe, Task 3 GIF/WebP proof) + 2 plan checkpoints (D-26 verdict confirmation, -a mode decision)
- **Files modified:** 4 (`install.sh`, `stow.sh`, `.gitignore`, `hypr/.config/hypr/scripts/wallpaper-visibility.sh` new)

## Accomplishments

- `mpvpaper` installed and declared as a hard `AUR_PKGS` dependency in `install.sh`, with a legitimacy-audit comment matching the repo's D-16/D-33/D-28 convention.
- `~/Pictures/Wallpapers/<theme>/live/` reproduces as a real directory for all 21 repo themes via a `stow.sh` pre-create loop placed before the `PACKAGES` loop (same fold-bug class already documented in that file).
- `hypr/.config/hypr/scripts/wallpaper-visibility.sh` built as the sole owner of the player's process lifecycle: intent files, blocking `flock`, atomic mktemp+mv publishes, compute/actuate split, `reassert` force path, the T-17-01 selection path validator, and D-29's no-IPC/no-pause discipline.
- Proven live: a real ffmpeg-generated probe clip plays beneath the desktop on a `background`-layer surface namespaced `mpvpaper`.
- D-26 settled by execution: `-p -a full` genuinely pauses decoding on a real fullscreen toggle (mpvpaper's own log line + a clean CPU drop to 0.00-0.50%) and resumes on release. D-27's fallback watcher was **not** built.
- The `-a` mode decision was corrected twice through direct measurement before the user picked: `-a max`'s claimed "covers the common maximized case" benefit does not hold on this compositor — `-a full` already pauses on the `SUPER+SHIFT+F` maximize bind, because it enters the same compositor state as literal fullscreen here.
- Animated GIF and animated WebP both proven to play as live wallpapers exactly like the mp4, still advancing past their first loop (two `grim` captures per file, taken after clip duration elapsed, are not byte-identical).
- Two real process-lifecycle races were found live and fixed: a flock-fd inheritance deadlock, and a CPU-heavy decode (WebP, 260-300% CPU) that ignored `SIGTERM` and let a duplicate process spawn — closed with a `SIGKILL` escalation.

## Task Commits

Each task was committed atomically:

1. **Task 1: End-to-end live wallpaper tracer** - `e1f2276` (feat)
2. **(fix found during Task 2's D-26 probe) Zombie-liveness hardening** - `0bda435` (fix)
3. **Task 2: D-26 runtime probe** - no commit (PASS branch: plan explicitly requires adding/deleting nothing — verdict recorded here and confirmed by the human checkpoint)
4. **Task 3: GIF/WebP proof + SIGKILL escalation fix** - `9e9cfce` (fix)

_Note: Task 2's PASS branch produces no file diff by design — the D-26 verdict and its evidence are recorded in this SUMMARY and were confirmed live by the human checkpoint before Task 3 proceeded._

## Files Created/Modified

- `install.sh` - `mpvpaper` added to `AUR_PKGS` with a legitimacy-audit comment header
- `stow.sh` - per-theme `live/` pre-create loop, placed before the `PACKAGES` stow loop
- `.gitignore` - excludes media under `wallpapers/Pictures/Wallpapers/*/live/`
- `hypr/.config/hypr/scripts/wallpaper-visibility.sh` (new) - sole owner of mpvpaper's process lifecycle

## Decisions Made

See `key-decisions` in frontmatter for the full list with rationale. Summary:
- D-26: **PASS** — ship `-p -a full` as built, no D-27 watcher.
- `-a` mode: **option-a** (`-a full`) selected by the user, after measurement showed `-a max` is a confirmed no-op on this compositor build (both dispatcher paths for "fullscreen" and "maximize" enter the same internal state here).
- Two Rule-1 process-hygiene bugs found and fixed live (flock-fd inheritance deadlock; SIGTERM-unresponsive CPU-heavy decode).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Backgrounded mpvpaper child inherited the owner's flock fd, deadlocking every later invocation**
- **Found during:** Task 1 (`select` then `reassert` hung for the full 2-minute Bash tool timeout)
- **Issue:** `setsid "${cmd[@]}" >/dev/null 2>&1 </dev/null &` did not close fd 8 (the `flock` reference `_acquire_lock` holds), so the long-running mpvpaper child inherited it across the fork/exec boundary and kept the lock held indefinitely after the launching script exited.
- **Fix:** Added `8>&-` to the launch redirection, closing fd 8 for the child.
- **Files modified:** `hypr/.config/hypr/scripts/wallpaper-visibility.sh`
- **Verification:** Re-ran `select`/`reassert`/`reassert` — all completed in under a second each, exactly one process, one layer surface.
- **Committed in:** `e1f2276` (Task 1 commit)

**2. [Rule 1 - Bug] Async launch raced a rapid consecutive invocation into a duplicate process**
- **Found during:** Task 1 (same live proof — two real `mpvpaper` PIDs with identical argv found running simultaneously)
- **Issue:** The launch backgrounds mpvpaper via `uwsm app --` (which itself goes through a `systemd-run` scope before the real binary is visible to `pgrep`); a rapid consecutive invocation's own "is anything running" check could run before that registration completed, seeing nothing and launching a second process.
- **Fix:** Added a bounded post-launch wait (poll until the process registers, ≤3s), symmetric to the existing stop-side bounded wait.
- **Files modified:** `hypr/.config/hypr/scripts/wallpaper-visibility.sh`
- **Verification:** `reassert` twice back to back, both immediately, left exactly one process (confirmed with `pgrep -x mpvpaper | wc -l`).
- **Committed in:** `e1f2276` (Task 1 commit)

**3. [Rule 1 - Bug] Grep-based acceptance criterion for `eval` tripped on a substring match, not an actual `eval` call**
- **Found during:** Task 1 self-verification (`grep -c 'eval'` returned 3, all inside the identifier `revalidated`)
- **Issue:** No actual `eval` command exists in the script, but the literal `grep -c 'eval'` acceptance criterion is a substring match, and `revalidated` contains the substring "eval".
- **Fix:** Renamed the local variable `revalidated` → `rechecked`.
- **Files modified:** `hypr/.config/hypr/scripts/wallpaper-visibility.sh`
- **Verification:** `grep -v '^\s*#' ... | grep -c 'eval'` now returns 0.
- **Committed in:** `e1f2276` (Task 1 commit)

**4. [Rule 1 - Bug] A bare `pgrep -x mpvpaper` is not a safe liveness/single-instance check — matches zombie entries**
- **Found during:** Orchestrator spot-check after the D-26 probe (killing a standalone probe instance left a defunct `Zsl` entry still matching `pgrep -x mpvpaper` by name)
- **Issue:** The single-instance launch guard, the stop-side bounded wait, and the post-launch registration wait all used a bare `pgrep -x mpvpaper`, which a zombie satisfies without being alive, running, or rendering anything — this could make the stop-side wait spin its full bound uselessly, or worse, make the post-launch wait return immediately on a stale zombie match instead of actually waiting for a newly-launched process.
- **Fix:** Added `_mpvpaper_running`, filtering `pgrep`'s matches by `ps -o stat=` excluding a leading `Z`, and used it in all three call sites.
- **Files modified:** `hypr/.config/hypr/scripts/wallpaper-visibility.sh`
- **Verification:** With a real zombie sitting alongside a real running process, consecutive `reassert` calls still left exactly one real process and one layer surface.
- **Committed in:** `0bda435`

**5. [Rule 1 - Bug] Animated-WebP decode's CPU load defeated the stop-side bounded SIGTERM wait, leaving two real processes**
- **Found during:** Task 3 (switching the selection from WebP to mp4 left two real `mpvpaper` processes and two layer surfaces)
- **Issue:** Animated-WebP decode measured 260-300% sustained CPU — far higher than mp4/gif — and the old process did not respond to `pkill -x mpvpaper` (SIGTERM) within `_stop_player`'s original 2-second bounded wait (independently confirmed: a manual `kill -TERM` left it alive 3 seconds later). The bounded wait timed out and gave up, and the caller's launch-guard proceeded to start a second process anyway.
- **Fix:** `_stop_player` now escalates to `pkill -9` (SIGKILL, uncatchable/undeferrable) if the process is still alive after the graceful SIGTERM window, with a second bounded wait for confirmation.
- **Files modified:** `hypr/.config/hypr/scripts/wallpaper-visibility.sh`
- **Verification:** Manually confirmed SIGKILL terminates the same stuck process within ~1s; re-ran the full mp4→gif→webp→mp4 switch cycle post-fix, exactly one real process and one layer surface at every step.
- **Committed in:** `9e9cfce` (Task 3 commit)

---

**Total deviations:** 5 auto-fixed (all Rule 1 — bugs found and fixed during live verification, none architectural)
**Impact on plan:** All five fixes were necessary for the script's core correctness invariant (never two real players/layer surfaces at once) and were found only because this plan insisted on running the tracer against the real installed binary rather than trusting source-reading alone — exactly the purpose RESEARCH.md assigned this plan. No scope creep; all fixes are confined to `wallpaper-visibility.sh`.

## Issues Encountered

- **Package install required interactive sudo.** `paru -S --needed mpvpaper` needs a TTY-interactive sudo password that this sandboxed executor cannot supply. Surfaced as a `checkpoint:human-action` (authentication gate) after completing every file-level part of Task 1 that didn't require the binary; the user installed it and confirmed, and execution resumed exactly where it stopped.
- **Probe contamination from the agent's own terminal.** During the `-a max` probe, the agent's own Claude Code terminal window was genuinely `fullscreen=2` on a separate workspace — `mpvpaper`'s `-a` mechanism tracks any tracked toplevel, not just the focused one, so the first probe attempt paused on "Claude Code" rather than the intended zen test target. Isolated by un-fullscreening the terminal (confirmed via `hyprctl clients -j`) before every subsequent probe. Recorded as a standing methodology note for any future probe on this repo.
- **An initially-wrong (c) conclusion in the `-a` mode decision, corrected on request.** The first probe round measured that `-a max` pauses on `fullscreen(1)` ("maximize") and concluded this was added coverage beyond `-a full`. The coordinator correctly identified that this inference was backwards without a control measurement — a direct `-p -a full` vs `fullscreen(1)` probe showed `-a full` *already* pauses on it (CPU delta 0.00%), meaning `-a max` adds nothing on this compositor. The corrected finding is what's recorded above; the retracted first answer is not restated as fact anywhere in this document.
- **A transient false "identical" screenshot pair during the WebP advance-and-loop test.** The first two `grim` captures (2s apart, immediately after selecting the WebP) were byte-identical — likely an early startup/buffering transient given the WebP's much higher CPU cost. A retest with a longer settle time before the first capture, and three samples spaced 3s apart, showed all three pairwise different, confirming genuine advancement. Recorded honestly rather than silently discarding the first (failing) result.

## User Setup Required

None — no external service configuration required. `mpvpaper` was installed interactively by the user during the plan's authentication-gate checkpoint (see Issues Encountered above); no further manual step remains.

## AMB-01 Flagged Assumption — Still Open

Restated per the plan's `<flagged_assumptions>` block: Phase 17 has no SPEC.md, so the deterministic edge-coverage probe returned `category: unclassified, status: unresolved` for AMB-01, and per protocol this was **not** auto-resolved with a backstop and **not** dropped. The edge cases this plan verified for AMB-01 (fullscreen enter/exit, animated GIF, animated WebP, loop-past-end, path-traversal rejection, an invalid/deleted selection) were chosen by the planner from CONTEXT.md/RESEARCH.md, not derived from a verified edge inventory. This remains an explicit, carried-forward gap — not silently considered closed by this plan's execution.

## Next Phase Readiness

- The `live/` layout, the package dependency, and the sole-owner intent interface (`select`/`clear`/`reassert`/`status`, plus the declared-but-unwired `idle`/`gaming`/`motion` source names) are all in place for 17-02 (frame extraction, `contract.json`, `last-wallpaper` validator widening) and 17-03 (the picker, `theme-apply`/login wiring, the three suppression call sites, the blocking render-and-look gate).
- The `-a full` invocation and the D-26/D-29 process-lifecycle discipline (no IPC, no pause-property writes, SIGTERM-then-SIGKILL stop) are locked and proven; 17-03's suppression call sites can be wired against this owner's existing verbs without re-litigating the process model.
- No blockers. The desktop is left in a working state: the owner-managed `tracer-probe.mp4` is playing on the current theme's `live/` directory, exactly one real process, one layer surface.
- Carried-forward, not this plan's scope: the AMB-01 flagged assumption above; D-27's watcher remains scoped-but-unbuilt (available if 17-03 or later ever needs the `fullscreen` source name); the `-a max` no-op finding is now recorded so no future plan re-spends probe time re-discovering it.

---
*Phase: 17-ambient-extras*
*Completed: 2026-08-09*
