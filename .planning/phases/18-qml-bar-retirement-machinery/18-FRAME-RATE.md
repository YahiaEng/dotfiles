# 18-18 Task 1: LEDGER-03 Frame-Rate Measurement — Methodology Captured, Live Campaign Deferred

**Status: DEFERRED.** This document records the full measurement methodology, the safe
host facts captured live this session, and the exact commands a future session runs to
complete the campaign. It does **not** report a frame-rate number for any of the five
conditions, because none of them was exercised this session — see "Why deferred" below.
Per this plan's own prohibition ("MUST NOT report a number that was not measured"), every
condition below is recorded `not measured` with its reason rather than filled with a
plausible figure.

## Why deferred

This session applied the project's standing execution policy for this plan (skip
disruptive live/interactive intervention against the user's live desktop session; capture
methodology and take the readings available without it; record the rest as a deferred,
resumable item rather than performing it unattended). Two things make Task 1's live
campaign specifically the kind of intervention that policy defers rather than performs
autonomously:

1. **The stop/restart step takes the user's bar away for the duration of the campaign.**
   Task 1 requires `systemctl --user stop quickshell.service`, running an *unsupervised*
   instrumented instance in its place for the five conditions, then restoring. This is
   exactly the "probe shells, restarts" class of live intervention this project's standing
   preference (recorded in project memory) directs against performing unattended.
2. **Conditions C2 and C4 require rearranging the user's live desktop.** OVER-04's load
   floor is at least 8 mapped windows across at least 3 numbered workspaces. Live-checked
   this session (`hyprctl clients -j`): the real desktop currently has **4 mapped windows
   across 4 workspaces** — short of the floor. Meeting it means spawning several
   application windows and moving them across the user's actual workspaces, then closing
   them again — a visible, disruptive rearrangement of a session the user may be actively
   using. Condition C3 additionally requires literal human-driven mouse input, which the
   plan's own text already treats as legitimately deferrable ("If the drag cannot be
   performed, record C3 as not measured with that reason").

Given C2/C3/C4 cannot be honestly closed without exactly this intervention, and C0/C1
alone would not close LEDGER-03 (they are bar-idle/bar-reveal conditions, not OVER-04's
Overview-surface conditions), this session defers the whole campaign rather than
delivering a partial, inconsistent state. The methodology below is complete and ready to
run in one sitting by a future session with the user present/aware.

## Instrument — required and forbidden (unchanged from the plan, restated here)

**Forbidden, unconditionally:** Hyprland's compositor frame-time debug overlay
(`hyprctl eval`, the debug overlay toggle). That exact instrument, on this exact host,
**froze the machine** hard enough to require a physical restart during Phase 16's OVER-04
measurement (`18-RESEARCH.md` Pitfall 4) — the compositor's IPC stopped answering,
including the request that would have switched the overlay back off. No measurement in
this campaign may use it, ever.

**Sanctioned instrument:** Qt's own render-timing environment variable,
`QSG_RENDER_TIMING=1`, run alongside `QSG_RENDER_LOOP=threaded` (the export
`quickshell-launch.sh` already uses on this host, line 56). This repo has already
exercised this exact instrument safely; its header records a prior measurement verbatim:
"basic loop ~16ms between frames, threaded ~6ms."

Also forbidden for the duration of the campaign: `hyprctl reload` — on this host a config
reload drops the quickshell layer rules, so the bar silently loses its blur and the
symptom looks exactly like a wrong alpha value (unrelated to this plan, but the same
prohibition list this plan carries).

## Safe host facts, captured live this session (read-only, no service interruption)

```
$ hyprctl monitors -j | jq -c '[.[] | {name, refreshRate, reserved}]'
[{"name":"DP-1","refreshRate":164.99899,"reserved":[0,46,0,0]}]

$ hyprctl version | head -3
Hyprland 0.56.2 built from branch v0.56.2 at commit efb50993780079460b0cbed1363e2166a2de1d9f clean
Date: Wed Aug 5 14:13:21 2026
Tag: v0.56.2, commits: 7661

$ pacman -Q quickshell
quickshell 0.3.0-2

$ systemctl --user show quickshell.service -p NRestarts
NRestarts=0

$ systemctl --user is-active quickshell.service
active

$ pgrep -c -x quickshell
1

$ hyprctl clients -j | jq '[.[] | select(.mapped==true)] | length'
4

$ hyprctl clients -j | jq -c '[.[] | select(.mapped==true) | .workspace.id] | unique'
[1,2,3,4]

$ ~/.config/hypr/scripts/bar-visibility.sh status
visible
```

The live refresh rate (164.99899 Hz) is what the 95%-of-live-refresh target pins to when
the campaign runs: `164.99899 * 0.95` ≈ **156.75 fps**. OVER-04's floor stays 60 fps exactly
per that document's own threshold. These are recorded here so the future session does not
re-derive them, but neither is a *measured frame figure* — both are host constants, not
outputs of the timing campaign.

## The five conditions — status

| Condition | What it reproduces | Status | Reason |
|---|---|---|---|
| C0 | Bar idle control (30s, no animation) | not measured | Requires the stop/unsupervised-instance step (see "Why deferred" #1); deferred with the rest of the campaign for one consistent resumable window rather than a partial one. |
| C1 | Bar reveal/re-hide (30s, driven by `bar-visibility.sh`) | not measured | Same as C0. |
| C2 | OVER-04 Condition A — load floor + overview at rest, 20s | not measured | Requires rearranging the live desktop to the 8-window/3-workspace floor (live check this session: only 4 windows/4 workspaces present) — see "Why deferred" #2. |
| C3 | OVER-04 Condition B — load floor + overview + human-driven drag, 20s | not measured | Requires literal human-driven pointer input; the plan's own text treats this condition as legitimately deferrable when unavailable. |
| C4 | OVER-04 Condition C — overview over a fullscreen client, 20s | not measured | Same load-floor-rearrangement reason as C2. |

None of the five conditions was fabricated, estimated, or carried over from a prior run.
Each is recorded `not measured` with its specific reason, per this plan's own prohibition.

## Exact commands to run when this campaign is picked up

Reproduced verbatim from `18-18-PLAN.md` Task 1's `<action>` so a future session does not
need to re-derive them. Run in order, on this host, with the user present:

```bash
# 1. Record the restore baseline
hyprctl monitors -j | jq -c '[.[].reserved]'
hyprctl monitors -j | jq -r '.[0].refreshRate'
hyprctl version
pacman -Q quickshell
systemctl --user show quickshell.service -p NRestarts

# 2. Stop the supervised shell and confirm the field is clear
systemctl --user stop quickshell.service
until [ -z "$(pgrep -x quickshell)" ]; do sleep 1; done

# 3. Start the instrumented instance detached, own capture file, size-capped
CAPFILE="$(mktemp -p /tmp qsg-timing.XXXXXX.log)"
setsid env QSG_RENDER_LOOP=threaded QSG_RENDER_TIMING=1 \
  quickshell -p "$HOME/.config/quickshell" >"$CAPFILE" 2>&1 </dev/null &
disown

# 4. Confirm real: exactly one pid, quickshell-bar namespace present
pgrep -c -x quickshell
hyprctl layers -j | jq -r '..|.namespace? // empty' | grep -c '^quickshell-bar$'

# 5. Read the first 20 timing lines to record the verbatim emitted format
head -20 "$CAPFILE"

# 6. Arrange the load floor for C2/C3/C4 (>=8 mapped windows across >=3 workspaces),
#    asserted from hyprctl clients -j AT SAMPLE TIME:
hyprctl clients -j | jq '[.[] | select(.mapped==true)] | length'
hyprctl clients -j | jq -c '[.[] | select(.mapped==true) | .workspace.id] | unique'

# 7. Run each condition's fixed window, with before/after marker lines written into
#    $CAPFILE, per the plan's per-condition action text (C0 30s idle, C1 30s
#    reveal/re-hide via bar-visibility.sh idle hide/show, C2 20s overview at load
#    floor, C3 20s human-driven drag over the same load floor, C4 20s overview over
#    a fullscreen client). Check $CAPFILE size before each condition; abort at 64MiB.

# 8. Compute per-condition median/p95 inter-frame interval (ms) and derived fps with
#    awk from the raw integer-ms samples. Judge against floor=60fps and
#    target=95% of the live refresh read in step 1.

# 9. Restore: kill the instrumented instance, poll pgrep -x quickshell to empty,
#    systemctl --user start quickshell.service, then confirm:
systemctl --user is-active quickshell.service
pgrep -c -x quickshell
grep -q quickshell.service /proc/"$(pgrep -x quickshell)"/cgroup
~/.config/hypr/scripts/bar-visibility.sh status
hyprctl monitors -j | jq -c '[.[].reserved]'   # compare to step 1's reading

# 10. Excerpt what the artifact needs from $CAPFILE, then delete $CAPFILE.
rm -f "$CAPFILE"
```

## Commands executed

Every command this session actually ran against the live host, in order (all read-only —
no service was stopped, no instrumented instance was started, no window was moved):

```
hyprctl monitors -j | jq -c '[.[] | {name, refreshRate, reserved}]'
hyprctl version
pacman -Q quickshell
systemctl --user show quickshell.service -p NRestarts
systemctl --user is-active quickshell.service
pgrep -c -x quickshell
hyprctl clients -j | jq '[.[] | select(.mapped==true)] | length'
hyprctl clients -j | jq -c '[.[] | select(.mapped==true) | .workspace.id] | unique'
~/.config/hypr/scripts/bar-visibility.sh status
```

No `hyprctl eval` and no `hyprctl reload` were run — verified by inspection of the list
above (both prohibited commands are absent).

## Deferred-item record

Filed to `.planning/WINDOWS.md` as an `unrun-verify` entry citing this artifact and the
"Exact commands to run" section above, so the campaign is discoverable and resumable
rather than silently dropped. LEDGER-03 (OVER-04's `FPS floor`/`FPS target` cells) remains
open — `16-OVER04-MEASUREMENT.md`, `PROJECT.md` and `MILESTONES.md` are **not** edited by
this session (Task 2 is likewise deferred; editing the ledger with numbers that do not
exist would itself violate this plan's own prohibition).
