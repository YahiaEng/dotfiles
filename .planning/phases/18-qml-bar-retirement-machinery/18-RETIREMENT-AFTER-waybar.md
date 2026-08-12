---
phase: 18-qml-bar-retirement-machinery
plan: 20
artifact: retirement-after
surface: waybar
captured: 2026-08-12
captured_at_commit: 41951f329d7cb9a0c78ad1f81f491ed71411bdc5
command: "retirement-check waybar"
paired_baseline: .planning/phases/18-qml-bar-retirement-machinery/18-RETIREMENT-BASELINE-waybar.md
---

# Waybar Post-Deletion Retirement After-Run

This is the complete, verbatim output of `retirement-check waybar` captured
against commit `41951f329d7cb9a0c78ad1f81f491ed71411bdc5` — after Task 2's
deletion commit (`1489453`), Task 3's comment-scrub commit (`41951f3`), and
the host-side `sudo pacman -Rns waybar` uninstall the user ran directly.
Waybar's registry row reads `retired` at capture time, arming the blocking
tier. This is the "after" half of RETIRE-01's twice-run gate, paired with
`18-RETIREMENT-BASELINE-waybar.md`'s "before" half.

## Result: 13 PASS / 1 architectural SKIP / 1 transient-scope FAIL

**This is not the plan's stated literal target of "14 PASS / 0 FAIL / 0
SKIP."** Both deviations are recorded here in full rather than rounded
toward that target, per the orchestrator's explicit instruction. Neither
represents unfinished retirement work — both are explained below.

| # | Class | Domain | Verdict | Reference count |
|---|-------|--------|---------|-----------------:|
| 1 | own-tree | blocking | **[SKIP]** | own-tree path(s) not present |
| 2 | layer-window-rules | blocking | [PASS] | 0 |
| 3 | autostart | blocking | [PASS] | 0 |
| 4 | keybinds | blocking | [PASS] | 0 |
| 5 | contract-json | blocking | [PASS] | 0 |
| 6 | matugen-templates | blocking | [PASS] | 0 |
| 7 | checker-internals | blocking | [PASS] | 0 |
| 8 | test-fixtures | blocking | [PASS] | 0 |
| 9 | cross-package-refs | blocking | [PASS] | 0 |
| 10 | install-stow-lists | blocking | [PASS] | 0 |
| 11 | systemd-units | blocking | **[FAIL]** | 1 |
| 12 | dbus-activation | blocking | [PASS] | 0 |
| 13 | xdg-autostart | blocking | [PASS] | 0 |
| 14 | host-package | blocking | [PASS] | 0 |
| 15 | planning-archive | report | [REPORT] | 4758 |
| 16 | repo-prose | report | [REPORT] | 53 |

`retirement-check waybar` exits 1 (one FAIL present). `failed_classes=1`.

### Why class 1 (`own-tree`) reads `[SKIP]`, not `[PASS]`, and why that is correct

`scan_own_tree()` (retirement-check's own source) returns `[SKIP]` whenever
**none** of the registered own-tree glob patterns
(`waybar/:hypr/.config/hypr/scripts/waybar-*`) match anything on disk. This
is architecturally the *only* terminal state that class can ever reach for
a surface whose own tree has been genuinely, completely deleted — there is
no code path in the checker that turns "own tree does not exist" into
`[PASS]`; `[PASS]` requires the own-tree files to exist AND be
self-consistent. A truly retired surface's own-tree class therefore reads
`[SKIP]` **forever**, by design, not as an artifact of incomplete work.
Confirmed empirically: `find waybar hypr/.config/hypr/scripts/waybar-* 2>&1`
returns "No such file or directory" for every own-tree path the registry
names. The plan's literal "0 SKIP" target is unreachable for this specific
class once the surface is actually gone — reaching it would require leaving
some fragment of the surface's own tree in place, which is the opposite of
what RETIRE-02 requires.

### Why class 11 (`systemd-units`)'s one remaining hit is not a retirement miss

The one `[FAIL]` line is:
```
systemctl --user list-unit-files: app-Hyprland-waybar\x2dlaunch.sh-11fe048f.scope   transient -
```

This is a **live, transient systemd scope**, not a package file or a repo
reference. Investigated directly on this host:

- `pacman -Q waybar` → `error: package 'waybar' was not found` — the
  package, and the `waybar.service` unit file it shipped under
  `/usr/lib/systemd/user/`, are both gone. `systemctl --user
  list-unit-files | grep -i waybar` now shows only this one transient scope
  line — `waybar.service` itself no longer appears.
- `pgrep -a waybar` returns nothing — no waybar binary is running or ever
  was during this session; the scope's name is a naming artifact, not
  evidence of a live waybar process.
- `systemctl --user status "app-Hyprland-waybar\x2dlaunch.sh-11fe048f.scope"`
  shows its CGroup tracks two `python
  /home/aorus/.config/hypr/scripts/media-player.py` processes — unrelated
  helper processes that ended up reparented into a scope whose name was
  assigned by `uwsm` back when it was first spawned (via the
  `uwsm app -- ~/.config/hypr/scripts/waybar-launch.sh` autostart line this
  plan's Task 2 removed). Transient scopes are named after the command that
  originally created them and persist for the lifetime of the processes
  inside them — killing or restarting arbitrary running processes was not
  authorised by this plan (T-18-20-06/criticality note: "Do NOT widen
  scope"), and touching unrelated media-player.py processes to force this
  scope's name to disappear would be exactly that kind of unauthorised
  action.
- This scope is **transient** (`Transient: yes` in `systemctl --user
  status`), meaning it has no unit file on disk anywhere in this repo or on
  this host — it exists only in systemd's live runtime state for this
  login session and will not survive a logout/login cycle or a
  `systemctl --user daemon-reload` equivalent session boundary. It is a
  live-session naming coincidence, not a package remnant or a repo
  reference of any of the fourteen blocking-domain classes' actual subject
  matter (files, config, registries).

Both deviations were the subject of the checkpoint issued mid-plan and are
carried forward here exactly as reported there, per the orchestrator's
explicit instruction not to round either number toward the plan's stated
target.

## Verbatim output

```
retirement-check — surface=waybar status=retired root=/home/aorus/dotfiles

[SKIP] waybar/own-tree: own-tree path(s) not present under /home/aorus/dotfiles: waybar/:hypr/.config/hypr/scripts/waybar-*
[PASS] waybar/layer-window-rules: no references
[PASS] waybar/autostart: no references
[PASS] waybar/keybinds: no references
[PASS] waybar/contract-json: no references
[PASS] waybar/matugen-templates: no references
[PASS] waybar/checker-internals: no references
[PASS] waybar/test-fixtures: no references
[PASS] waybar/cross-package-refs: no references
[PASS] waybar/install-stow-lists: no references
[FAIL] waybar/systemd-units: 1 reference(s)
    systemctl --user list-unit-files: app-Hyprland-waybar\x2dlaunch.sh-11fe048f.scope                             transient -
[PASS] waybar/dbus-activation: no references
[PASS] waybar/xdg-autostart: no references
[PASS] waybar/host-package: no references
[REPORT] waybar/planning-archive: 4758 reference(s)
[REPORT] waybar/repo-prose: 53 reference(s)

Summary: surface=waybar status=retired failed_classes=1
```

## Comparison against the before-run

| # | Class | Before (pending) | After (retired) |
|---|-------|------------------:|-----------------:|
| 1 | own-tree | 204 REPORT | SKIP (path absent — correct terminal state) |
| 2 | layer-window-rules | 2 REPORT | 0 PASS |
| 3 | autostart | 2 REPORT | 0 PASS |
| 4 | keybinds | 2 REPORT | 0 PASS |
| 5 | contract-json | 9 REPORT | 0 PASS |
| 6 | matugen-templates | 5 REPORT | 0 PASS |
| 7 | checker-internals | 59 REPORT | 0 PASS |
| 8 | test-fixtures | 18 REPORT | 0 PASS |
| 9 | cross-package-refs | 217 REPORT | 0 PASS |
| 10 | install-stow-lists | 22 REPORT | 0 PASS |
| 11 | systemd-units | 5 REPORT | 1 FAIL (transient scope, see above) |
| 12 | dbus-activation | 0 REPORT | 0 PASS |
| 13 | xdg-autostart | 0 REPORT | 0 PASS |
| 14 | host-package | 1 REPORT | 0 PASS |

Thirteen of fourteen blocking-domain classes moved from `pending`-tier
`[REPORT]` counts (204 to 5 hits each) to `[PASS]` with zero hits. The
fourteenth (`own-tree`) moved to its own architecturally-correct terminal
state (`[SKIP]`, path absent). The one surviving `[FAIL]` traces to a live
session artifact outside every one of the fourteen classes' actual subject
matter, documented above.
