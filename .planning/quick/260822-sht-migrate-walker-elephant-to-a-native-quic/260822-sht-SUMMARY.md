---
quick_id: 260822-sht
status: complete
description: migrate walker+elephant to a native Quickshell QML launcher
date: 2026-08-23
task_count: 12
tasks_completed: 12
commits: 30
first_commit: 5c522dad
last_commit: 5ba0f746
---

# Quick task 260822-sht — walker + elephant → native Quickshell QML launcher

All 12 planned tasks executed across three ordered stages, plus 18 additional
commits from live operator feedback. walker and elephant are retired from the
repo **and** uninstalled from the host; `retirement-check` reports both
`status=retired failed_classes=0`.

## What shipped

**Stage 1 — build** (`5c522dad`, `33c11805`, `08ee8808`, `43b00df8`)
A dedicated `PanelWindow` launcher package at
`quickshell/.config/quickshell/modules/launcher/`: fuzzy matcher (`fuzzy.js`),
6-route prefix router, per-mode result views, a `launcher` IPC handler, the
9 verb-based menu roots with all 30 non-clipboard leaf commands byte-identical
to the retired TOMLs, and the three new roots (R-1 Updates, R-2 System info,
R-3 Apps).

**Stage 2 — migrate** (`74407582`, `88c24cbd`, `b4444eb6`, `d7d0385e`, `4d867207`)
All 7 dmenu consumers moved off walker: generic picker (theme, bar
orientation), destructive confirm + choice pickers (clipboard wipe, record
audio), emoji grid (160 entries, `emoji.tsv`), text-only clipboard surface
taking over Super+C, and the keybinds table with a `--dump` CLI added to the
shared `cheat-sheet-parser.sh`.

**Stage 3 — retire** (`6564f7e8`, `fd6d327c`, `eed3080d`, `5ba0f746`)
Retirement registered; compositor surface stripped; theme-pipeline retirement
landed as ONE commit across all five assertion sites; `walker/`, `elephant/`
and 5 dead scripts deleted; every prose reference scrubbed; host packages
uninstalled by the operator and both registry rows flipped to `retired`.

Super+Escape moved from `pkill walker` to
`systemctl --user restart quickshell.service` (DQ-1, settled by the operator
before execution began).

## Deviations from plan

All were Rule 1/2/3 — required wiring or operator-directed. None re-scoped the task.

1. `shell.qml` and `Launcher.qml` were touched in most tasks despite not being
   in their `<files>` lists — an IPC/GlobalShortcut handler must live in
   `shell.qml`'s permanent scope, and a mode is unreachable until its
   `case`/`Component` is wired.
2. Super+Shift+C repointed to `qs ipc call launcher open clipboardwipe` —
   `clipboard-wipe.sh` no longer has a bare-invocation path.
3. A "Tools ▸ Clipboard wipe" leaf was added to `MenuTree.qml`; the plan's own
   action text called for it though no such leaf existed in the retired TOMLs.
4. `ToggleState.qml` and `ClockActionsCapsule.qml` still shelled out to the
   deleted `theme-switch.sh`; both repointed to the launcher.
5. `bar-orientation.sh`'s no-arg path was removed in Task 5, silently breaking
   the bar's Bar Orientation settings axis — fixed in `120caf84`.

## Defects found and fixed during execution

Every one was found by live operator use or by measurement, **not** by a gate:

- **Surface posture** (`26c113e4`) — the tracer shipped `anchors.top` + a
  content-tracking `implicitHeight`, the exact configuration `Dashboard.qml`
  documents as three rounds of jitter debugging. Rebuilt as a full-screen
  surface that never resizes, with all motion QML-side.
- **Click-outside dismiss** (`4c752927`) — once the surface spans the output a
  click "outside" lands inside it, so `HyprlandFocusGrab.onCleared` never sees
  it. Required the documented dismiss-scrim `MouseArea`.
- **Super-tap dead** (`e4ff1138`) — `keybinds.lua` line 82 is the only
  `release = true` bind; its handler implemented `onPressed` only, so the
  shortcut fired on an edge nothing listened for. Now handles both edges with
  a 250ms debounce.
- **Commands killed mid-flight** (`9c266834`) — every mode ran
  `process.running = true` then immediately `dismissCallback()`; the LazyLoader
  destroyed the `Process` with the surface. `theme-apply` takes ~1.3s against a
  150ms dismiss window — structurally guaranteed to lose. Moved to
  `Quickshell.execDetached`, except `ClipboardMode`'s stdin-writing processes,
  which are hosted on the `LauncherState` singleton. This had also silently
  broken emoji typing and clipboard paste since they were written.
- **Apps died on shell restart** (`0654896f`) — `entry.execute()` spawned into
  `quickshell.service`'s cgroup under `KillMode=control-group`. Now
  `uwsm app -- <id>.desktop`, which preserves `StartupWMClass` and
  `Terminal=true` handling.
- **Emoji grid unscrollable** (`8de61137`) — `interactive: false`; the wheel
  handler needs `PointerDevice.AllDevices` because Qt's Wayland backend reports
  every pointer on this host as `TouchPad`.
- **12 glyph-less menu entries** (`d440520b`) — all 9 roots and the 3 new
  entries. The Stage 1 gate verified leaf *commands* byte-for-byte; roots were
  new so nothing compared them.
- **Cheat-sheet card shattered** (`a86eaed4`) — three launcher binds carried
  their full rationale as the trailing `-- description`, one 204 characters.
  `cheat-sheet-parser.sh` reads that as the card's description column with no
  length cap, blowing the panel width past the pty.
- **`Design.*` undefined in three modes** (`0f87f3b2`) — missing
  `import "../dashboard"`. Third occurrence of this class in one task.

## Standing lessons

- **The three QML lint gates cannot see a bad import.** `qmllint`,
  `colour-lint` and `motion-lint` are static text matchers; a wrong import
  makes `Colours.*`/`Motion.*` read `undefined` at runtime with all three
  green. Only a restart plus `~/.cache/quickshell.log` reveals it — and that
  log is append-only across restarts, so compare an error's line number
  against the last `quickshell-launch.sh: starting` marker.
- **`hyprctl dispatch global <name>` does not trigger GlobalShortcuts.**
  Verified against `quickshell:dashboard`, working for months. It is a blind
  probe; `qs ipc call` is the working one.
- **No input injection exists on this host.** `xdotool`/`ydotool`/`wlrctl`/
  `dotool` are all absent and `wtype` misroutes to the focused toplevel — it
  typed into the operator's browser once. Every click/keystroke behaviour in
  this task was operator-verified, never agent-verified.

## Deferred

- **System tray capsule** — captured as
  `.planning/todos/pending/2026-08-23-add-system-tray-capsule-to-the-quickshell-bar.md`
  (severity major). No SNI host has existed since waybar's retirement, so
  tray-minimising apps cannot be closed. Found while debugging a Steam relaunch
  loop; the separate `steamwebhelper` crash loop was Steam-side and fixed by
  clearing `htmlcache` + `-cef-disable-gpu`.
- See `deferred-items.md` in this directory for the in-flight scope notes.

## Gate results at close

`retirement-check` walker/elephant `retired`, `failed_classes=0`, `--self-test`
5/5 · `quickshell-doctor` 28/0 and `--self-test` 59/59 (GATE-03
`unregistered` 1 → 0) · `keybind-doctor` 13/0 · `colour-lint` 347/0 ·
`motion-lint` 352/0 · `stow-link-check` 2/2 · `qmllint` clean.
