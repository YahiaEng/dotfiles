# 13-03 — PAUSED at 1/3 tasks (resume here)

**Status:** PAUSED, not complete. No `13-03-SUMMARY.md` exists and none should be
written until Tasks 2 and 3 both finish. `STATE.md` and `ROADMAP.md` have NOT
been updated to reflect plan completion — this plan is still open.

**Why paused:** Task 2 is a blocking human measurement that runs `uwsm stop`
from a TTY, which tears down the operator's graphical session. The operator
was explicitly warned of this before deciding — this is a **scheduling
deferral, not a decision to skip WR-04**. They chose to batch it for a time
when they're restarting anyway, and to proceed with plan 13-04 in the
meantime.

---

## Task 1 — DONE, committed

Commit `baae579` — WR-01, WR-02, WR-03 all fixed, each individually proven by
a fault injection that reproduced the defect before the fix and did not after
(D-30). All injected faults were restored to their original state
(`fisher.fish`, `~/.local/bin/env`, the nvm `v24.18.0` version directory).

**WR-01 (fisher bootstrap `-f`):** Added `-f` to the bootstrap curl so a
non-200 body is never sourced as fish commands.

**Second defect found live during WR-01's own AFTER check — do not lose this
finding:** fish's pipeline `$status` reflects the exit code of the *last*
command in the pipe (`source`), not `curl`. `curl -f | source` on a failed
fetch sources empty input, which trivially succeeds — so a plain
`and fisher update` immediately after it *still fired* even though curl
itself failed, and errored with `Unknown command: fisher`. Fixed by gating on
`$pipestatus[1]` (curl's own exit code) instead of the pipeline's ambient
`$status`. Both halves proven: BEFORE (bad URL + naive fix) showed the
secondary "Unknown command: fisher" error; AFTER (bad URL + `$pipestatus[1]`
gate) was silent; real URL end-to-end still installs fisher + plugins
correctly.

**WR-02 (nvm guard):** Added `test -d $nvm_data/$nvm_default_version` to the
activation guard in `fish/.config/fish/config.fish` — prevents
`nvm: Can't use Node "v24.18.0", version must be installed first` from
printing on every shell before `nvm install` has been run.

**WR-03 (uv env guard):** `zshell/.zshrc`'s unguarded `. "$HOME/.local/share/../bin/env"`
replaced with `[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"` —
resolves the obfuscated indirection to the real path and guards against the
file being absent (as it is on any machine without uv installed, which
`install.sh` does not provision).

Verified clean at pause time: `git diff baae579 -- fish/.config/fish/config.fish
zshell/.zshrc` is empty (both files are in their real committed post-fix
state, not an injected one); `fisher.fish`, `~/.local/bin/env`, and the nvm
`v24.18.0` directory are all present and correct on disk;
`wallpapers/Pictures/Wallpapers/current.jpg` is the only dirty file in
`git status --short` (pre-existing churn owned by plan 13-06, untouched by
this plan).

---

## Task 2 — NOT STARTED (resume point)

`checkpoint:human-verify`, `gate="blocking"`. This task **ends the graphical
session at step 3** — commit/push everything first (already true: Task 1 is
committed on `main` as `baae579`).

Reproduced verbatim from `13-03-PLAN.md`:

> 1. **Stage the blocking client.** In a floating terminal, run:
>    `kitty -e bash -c 'trap "" TERM; echo BLOCKING $$; sleep 300'`
>    Note the PID it prints. This process ignores the polite termination
>    signal, which is the whole point — it is the "app that will not close"
>    the hazard model is about.
>
> 2. **Safe observation first.** Run `hyprshutdown --dry-run` (shows the UI,
>    closes nothing). Watch whether its app-close step visibly enumerates or
>    waits on that blocking client. Record what you see. Cancel out of the UI.
>
> 3. **The measurement.** Switch to a TTY (`Ctrl+Alt+F2`) and log in there —
>    this must be run from OUTSIDE the session about to be torn down, or you
>    cannot observe the result. From the TTY:
>    - start a stopwatch and run `uwsm stop`
>    - record (a) the wall-clock seconds until the command returns
>    - record (b) whether the blocking PID from step 1 is still alive
>      afterwards (`ps -p <PID>`)
>    - record (c) whether it returned near-instantly (socket teardown
>      orphaning the client) or stalled for a long fixed interval (the
>      systemd stop timeout)
>
> 4. **Log back in** and report all three numbers plus what you saw in step 2.

**The three values to record:** elapsed seconds to return; whether the
blocking PID was still alive afterward; stall vs. near-instant
classification. Plus a sentence describing what `hyprshutdown --dry-run`'s
app-close step did with the blocking client in step 2.

---

## Task 3 — NOT STARTED (depends on Task 2's numbers)

Files: `wleave/.config/wleave/layout.json`, `.planning/PROJECT.md`. Take
exactly ONE branch, selected by Task 2's numbers — never both, never a hedge.

- **Near-instant, regardless of the blocking client → hazard falsified on
  this build → Branch B.** Leave `layout.json` byte-unchanged. Add a Key
  Decisions row to `PROJECT.md` recording logout as *deliberately* bare (same
  shape as the existing suspend/hibernate row), citing the measurement itself
  as the reason: elapsed time observed, and that the blocking client's fate
  was the same on both paths.

- **Long fixed-interval stall → hazard is real → Branch A.** Rewrite the
  logout button's action string in `layout.json` to mirror the reboot and
  shutdown entries' exact shape: clipboard wipe leading, then wrap the
  session stop through `hyprshutdown --post-cmd`, same quoting style. Do NOT
  write a bespoke client-close loop. Add a Key Decisions row to `PROJECT.md`
  recording that logout now shares the graceful-teardown path, citing the
  measured stall interval as evidence.

- **Anything in between → report the numbers; the next task's action states
  both branches and the numbers decide** (do not resolve this by reasoning
  about which branch seems more likely — this is explicitly the operator's
  call per the plan's checkpoint protocol).

---

## Resume instructions for a fresh session

1. Re-read `13-03-PLAN.md` Task 2 and Task 3 in full before acting.
2. Confirm `git log --oneline -3` shows `baae579` still present and
   `git status --short` shows nothing dirty except
   `wallpapers/Pictures/Wallpapers/current.jpg`.
3. Run Task 2's measurement live with the operator (this cannot be automated
   — it requires a human to physically switch TTYs, log in, and log back in).
4. Take Task 3's branch per the measured numbers.
5. Only then write `13-03-SUMMARY.md`, update `STATE.md`/`ROADMAP.md`, and
   make the final metadata commit.
6. Delete this file (or fold its content into the SUMMARY) once the plan is
   actually complete — it exists only to make the resume point unambiguous.
