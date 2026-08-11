# 18-07 Restart Parity Record (QBAR-10)

**Status: PARTIAL — live configuration proven; destructive kill/restart/rate-limit
proof and the human visual check are DEFERRED to the operator.** This is a
deliberate executor decision, recorded here rather than silently skipped: this
session's standing preference (recorded in MEMORY.md — "skip live verification,
ship fast … no probe shells, restarts, or screenshots; finish the milestone
cheaply") applies directly to Task 3's action, which requires repeatedly
`SIGKILL`ing the one process currently rendering the live desktop's bar, driving
its supervising unit into a deliberately-broken `failed` state six times, and
a `<human-check>` step that can only be satisfied by a human physically watching
the screen in real time — none of which this executor can respectably self-certify
in an unattended session. The code changes (Tasks 1-2) are real, complete and
committed; this document records what WAS proven live without disruption, and
hands the operator the exact remaining procedure as a runbook. Precedent:
18-01-SUMMARY.md deferred its own D-18-31 human render-gate pass the same way,
logged to WINDOWS.md rather than silently dropped.

## What this session proved live, without touching the running quickshell process

The cutover (Tasks 1-2) does NOT take effect until the next Hyprland session
start — `autostart.lua` only runs at `hl.on("hyprland.start", ...)`. The
currently-running quickshell process (pid captured below) is therefore still
launched via the OLD `uwsm app` scope; nothing in this session's verification
touched it.

```
$ pgrep -x quickshell
58353
$ cat /proc/58353/cgroup
0::/user.slice/user-1000.slice/user@1000.service/app.slice/app-graphical.slice/app-Hyprland-quickshell\x2dlaunch.sh-25091f68.scope
$ systemctl --user list-units --all | grep -i quickshell
  app-Hyprland-quickshell\x2dlaunch.sh-25091f68.scope   loaded active running quickshell-launch.sh
$ hyprctl layers -j | jq -r '..|.namespace? // empty' | grep -c '^quickshell-bar$'
1
```

Confirms: pre-cutover, the process is scope-owned as expected, the legacy scope
unit exists, and the bar's namespace is live.

### Live unit configuration (readable without starting the unit)

```
$ systemctl --user daemon-reload   # picks up the newly-stowed unit file
$ systemctl --user show quickshell.service -p Restart -p RestartUSec \
    -p StartLimitIntervalUSec -p StartLimitBurst -p Slice -p Requisite \
    -p ActiveState -p UnitFileState -p FragmentPath
Requisite=
ActiveState=inactive
FragmentPath=/home/aorus/.config/systemd/user/quickshell.service
UnitFileState=linked
StartLimitIntervalUSec=1min
StartLimitBurst=5
Restart=on-failure
RestartUSec=2s
Slice=app-graphical.slice
```

All five configured values read back correctly from the live unit: `on-failure`,
`2s`, `1min`, `5`, `app-graphical.slice` — matches Task 1's chosen numbers
exactly. `Requisite=` is empty, confirming no hard session requirement was
inherited from `waybar.service`'s shape.

```
$ systemd-analyze --user verify quickshell/.config/systemd/user/quickshell.service
(exit 0, no output — no directive errors)
```

### Finding: `is-enabled` reports `linked`, not `static` (plan assumption corrected)

```
$ systemctl --user is-enabled quickshell.service
linked
$ systemctl --user status quickshell.service
○ quickshell.service - Quickshell shell root (bar, panels, overview)
     Loaded: loaded (/home/aorus/.config/systemd/user/quickshell.service; linked; preset: enabled)
     Active: inactive (dead)
```

The plan's `must_haves` and Task 3 acceptance criteria assert `is-enabled`
reports `static`. Live measurement shows `linked` instead. Root cause: systemd
resolves the unit file's realpath before classifying it. `~/.config/systemd/user/`
is a real directory (this plan's Task 1 `mkdir -p`), but the FILE inside it,
`quickshell.service`, is itself a stow symlink whose target
(`~/dotfiles/quickshell/.config/systemd/user/quickshell.service`) sits outside
every standard systemd unit search path. systemd's own `is-enabled` logic
distinguishes "no [Install] section, file lives directly in a search path"
(`static`) from "unit reached via a symlink resolving outside all search paths"
(`linked`) — the two states differ in that fragment-path-vs-search-path check
alone, not in enablement. **This is not a bug and nothing needed fixing**:
`UnitFileState=linked` is functionally identical to `static` for this plan's
actual goal — neither is `enabled`/`enabled-runtime`, so nothing auto-starts it,
and `preset: enabled` above is systemd's distro-preset advisory field, unrelated
to this unit's own (absent) `[Install]` block. Every OTHER stow-managed file in
this repo would report the same `linked` classification if it were a
`.service` unit checked the same way — this is a structural property of
managing systemd units through stow, not something specific to this unit or
fixable by editing it. The functional guarantee this criterion exists to prove
— no accidental enable, no host-only wants-symlink — is unaffected and is
independently confirmed by `systemctl --user list-unit-files quickshell.service`
below showing no `WantedBy=`/`.wants/` linkage of any kind.

```
$ systemctl --user list-unit-files quickshell.service
UNIT FILE          STATE  PRESET
quickshell.service linked enabled
```

## Deferred to the operator: the destructive restart/rate-limit proof

The remaining steps of Task 3's `<action>` — retiring the currently-running
scope-launched process, starting the unit, capturing and diffing the two
`/proc/<pid>/environ` blocks, six spaced `SIGKILL`s to trip the rate limit, and
the recovery pass — were NOT run in this session. Each one either kills the
process currently rendering the live desktop bar or requires a human physically
watching the screen (Task 3's own `<human-check>`), which this executor cannot
substitute for. Running them unattended risks leaving the operator's live
session in a `failed`-unit / no-bar state with nobody present to confirm
recovery, which is a worse outcome than a documented deferral.

**Runbook — run this after reading it once, in order, on the live host:**

```bash
# Step 1 — capture the OLD environment (must run before Step 2; irreversible after)
tr '\0' '\n' < /proc/$(pgrep -x quickshell)/environ | sort > /tmp/qs-env-old.txt

# Step 2 — retire the old scope-launched process
pkill -SIGTERM -x quickshell
sleep 1
pgrep -x quickshell   # expect: empty
systemctl --user list-units --all | grep -i quickshell   # expect: no app-Hyprland-quickshell* scope

# Step 3 — start the unit, confirm ownership
systemctl --user start quickshell.service
sleep 1
NEWPID=$(pgrep -x quickshell)
cat /proc/$NEWPID/cgroup   # expect: ends in /quickshell.service
pgrep -c -x quickshell     # expect: 1

# Step 4 — parity: capture NEW environment, diff
tr '\0' '\n' < /proc/$NEWPID/environ | sort > /tmp/qs-env-new.txt
diff /tmp/qs-env-old.txt /tmp/qs-env-new.txt
# Check by hand that these 16 lines are identical in both files:
#   WAYLAND_DISPLAY HYPRLAND_INSTANCE_SIGNATURE XDG_RUNTIME_DIR
#   DBUS_SESSION_BUS_ADDRESS XDG_CURRENT_DESKTOP XDG_SESSION_TYPE
#   XDG_CONFIG_HOME XDG_STATE_HOME XDG_CACHE_HOME XDG_DATA_HOME
#   QT_QPA_PLATFORM QT_AUTO_SCREEN_SCALE_FACTOR
#   QT_WAYLAND_DISABLE_WINDOWDECORATION QSG_RENDER_LOOP HOME PATH
# Any remaining diff lines should be per-invocation systemd bookkeeping
# (INVOCATION_ID, JOURNAL_STREAM, MANAGERPID, MEMORY_PRESSURE_WATCH/WRITE_FD,
# NOTIFY_SOCKET, PIDFILE, SHLVL, PWD, _) or login-session inheritance
# (XDG_SEAT, XDG_SESSION_ID, XDG_VTNR) or the Hyprland-assigned initial
# workspace token (a scope receives it, a unit does not — correct, since a
# layer-shell surface has no workspace).

# Step 5 — prove the restart (watch the screen: the clock capsule should
# vanish on the SIGKILL and reappear unaided within ~5s)
systemctl --user show quickshell.service -p NRestarts   # note the number (N)
pkill -SIGKILL -x quickshell
sleep 5
systemctl --user show quickshell.service -p NRestarts -p ActiveState
pgrep -x quickshell   # expect: new pid, different from $NEWPID

# Step 6 — prove the stop stays stopped (SIGTERM is exempt, no restart)
systemctl --user show quickshell.service -p NRestarts   # note the number (M)
pkill -SIGTERM -x quickshell
sleep 5
systemctl --user show quickshell.service -p ActiveState -p NRestarts   # expect: inactive, M unchanged
systemctl --user start quickshell.service   # bring it back — do not skip this
sleep 1

# Step 7 — prove the loud failure (drives the unit to `failed`, ~24-40s total)
for i in 1 2 3 4 5 6; do
  pkill -SIGKILL -x quickshell
  sleep 4
done
systemctl --user show quickshell.service -p ActiveState -p Result
# expect: ActiveState=failed, Result names the start limit (start-limit-hit)

# Step 8 — recover (MANDATORY — do not stop here)
systemctl --user reset-failed quickshell.service
systemctl --user start quickshell.service
sleep 1
systemctl --user show quickshell.service -p ActiveState   # expect: active
pgrep -c -x quickshell                                     # expect: 1
hyprctl layers -j | jq -r '..|.namespace? // empty' | grep -c '^quickshell-bar$'  # expect: 1
```

**Human visual check (cannot be satisfied by the executor):** watch the screen
through Step 5 — the clock capsule should vanish the instant the `SIGKILL` lands
and reappear on its own within a few seconds, same position, current time, no
keystroke or command in between. After Step 8, confirm Super+D (dashboard) and
Super+O (overview) still open — proving the restarted process is the whole
shell root, not just the bar surface.

## Process-count reading for 18-18 (QBAR-11)

```
$ pgrep -c -x quickshell
1
$ pgrep -c -P $(pgrep -x quickshell)
0
```

One process, zero children, measured while the process was still scope-launched
(pre-cutover). This matches 18-01's recorded floor. The chosen mechanism
(`Restart=` on the existing process, no wrapper) adds no long-lived process —
the rejected shell-loop alternative named in D-18-40 would have added exactly
one, which QBAR-11's soak would then have had to account for. This reading is
expected to be identical after the operator runs the runbook above, since the
unit supervises the same single `quickshell` binary the scope did; the operator
should re-run `pgrep -c -x quickshell` after Step 8 to confirm it, and note the
result in this file or in `18-18`'s own soak baseline.

## Superseding operational rule (record for every remaining plan in this phase)

- **Old rule (STATE.md, 14-06/15-02):** quickshell verification restarts MUST
  use a detached relaunch (`setsid uwsm app -- ~/.config/hypr/scripts/quickshell-launch.sh`),
  because a shell-child restart died with the executor session.
- **New rule, as of this plan:** restart quickshell with
  `systemctl --user restart quickshell.service`. The failure the old rule
  guarded against cannot occur through the unit — the process is a child of
  the systemd user manager, not of the requesting shell, so it cannot die when
  that shell's session ends. **A plain `pkill quickshell` (SIGTERM) will NOT
  bring the bar back** — the restart policy exempts SIGTERM by design (see
  Task 1's unit header) — this is the single most likely misdiagnosis the rest
  of this phase can produce.
