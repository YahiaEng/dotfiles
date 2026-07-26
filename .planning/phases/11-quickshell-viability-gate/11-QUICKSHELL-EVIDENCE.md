<!-- Provenance: 11-01-PLAN.md Task 1, D-05 (quickshell-doctor + dated-record home),
     D-09/D-10 (QS-02 sole stop-trigger, everything else record-and-continue), D-11
     (registration lands before the human clicks). This file is the phase's single
     evidence artifact: it accumulates dated PASS/FAIL lines across Phase 11's plans
     (01-05) and is re-appended to by later phases (14-16) per D-05. Structural
     precedent: `.planning/milestones/v2.0-phases/08-waybar-evolution/08-BAR-02-EVIDENCE.md`. -->

# Phase 11: Quickshell Viability Gate — Evidence

Verdict: PASS

QS-02's human-clicked gate passed on 2026-07-26 (11-01 Task 3): pointer click, keyboard
input (including non-ASCII), and click-outside dismiss all worked on the first live test,
under `WlrKeyboardFocus.OnDemand` — no escalation to `Exclusive` was needed. v3.0 continues
as roadmapped; Phases 12-17 stand; the registration commit set (`1aea012`) stays.

## Gate table

| Gate | Criterion (verbatim) | Method | Instrument | Raw result | PASS/FAIL |
|---|---|---|---|---|---|
| QS-01 | `install.sh` installs Quickshell and its Qt6 dependencies from the official Arch `extra` repo, and `stow.sh` deploys the `quickshell/` package — both registered in the same commit that creates the package | `pacman -Qi quickshell`; `git show --stat` on the registration commit | pacman, git | Installed 0.3.0-2 from `extra`; commit `1aea012` contains `install.sh` + `stow.sh` + the whole `quickshell/` package + launcher + autostart + keybind together (D-11) | PASS |
| QS-02 | A human can click a button, type into a text field, and dismiss by clicking outside on a Quickshell layer-shell surface on Hyprland 0.56.0 | Human-clicked live test at the keyboard | `PanelWindow` probe, `HyprlandFocusGrab` | All three sub-criteria passed on first attempt under `WlrKeyboardFocus.OnDemand` — see Dated gate log below | **PASS** |
| QS-03 | Quickshell surfaces render correctly across all connected monitors and survive monitor hotplug | `hyprctl output create/remove headless` + probe summon on each output | hyprctl, `quickshell-doctor` | Hotplug mechanics (add/remove/reserved-space/PID/log-health) all PASS. Per-screen surface creation FAILS: the current single-`PanelWindow` probe only ever mounts on whichever screen existed at shell startup — a headless output added afterward gets zero surfaces, not its own. See "11-04 Task 1" below for the full finding and the fix attempts made and reverted | **PARTIAL — genuine defect found and recorded, not a stop-trigger (D-10)** — 2026-07-26 (plan 04, continues in plan 05/later) |
| QS-04 | Editing Quickshell config hot-reloads the running shell without a manual restart | `FileView`/`JsonAdapter`/`watchChanges` live hand-edit test | Text editor + probe label | (a) QML source hot-reload: **PASS**, verified mechanically (no human required — see "11-04 Task 2a" below). (b) `FileView`/`JsonAdapter` hand-edit propagation: requires a human watching the on-screen label — **PENDING**, handed to a checkpoint | **PARTIAL** — (a) PASS 2026-07-26 (plan 04); (b) PENDING human observation |
| QS-05 | The Quickshell shell autostarts with the session and runs alongside waybar, swaync, SwayOSD, wleave, AGS and walker with no layer-namespace collision, no exclusive-zone layout shift, and no duplicated global keybind | `quickshell-doctor` (full run, live desktop) | `hypr/.config/hypr/scripts/quickshell-doctor` | 10 checks run, 10 passed, 0 failed, exit 0. Namespace discipline: off-level 0, wrong-pid 0. Reserved-space summon-and-diff: `monitors -j`'s `reserved` array byte-identical before/during/after summoning every manifest surface (`[0,46,0,0]` throughout — see raw arrays below). `keybind-doctor` invoked as part of the run: exit 0, 13/13. See full verbatim transcript below | **PASS** — 2026-07-26 (plan 03) |
| QS-06 | No two processes double-handle the same event source — MPRIS, PipeWire, hardware media/brightness keys and `org.freedesktop.Notifications` each retain a single owner | `quickshell-doctor` (busctl/hyprctl/pactl/brightnessctl checks) | busctl, hyprctl, pactl, brightnessctl, quickshell-doctor | `org.freedesktop.Notifications`: exactly 1 owner, named `swaync`. All 10 XF86Audio\*/XF86MonBrightness\* keys: exactly 1 registered handler each (Hyprland bind count + manifest count summed). Zero Quickshell components reference MPRIS (0 files under `~/.config/quickshell`). Volume one-step-per-press: measured delta 3277 raw units (of 65536), seeded as baseline on first run, matched exactly on every rerun since, sink volume byte-identical before/after (including under SIGINT mid-probe — see below). Brightness one-step-per-press: `[SKIP]` — `brightnessctl -l` lists only `leds`-class devices (`enp5s0-{0..3}::lan`, `input5::capslock/scrolllock/numlock`, `input11::mute`) and no `backlight`-class device on this host | **PASS** — 2026-07-26 (plan 03) |
| MAINT-01 | `keybind-doctor` correctly cross-checks Quickshell-claimed shortcuts against Hyprland's registered set (amended per D-15 to plain-text `hyprctl binds` parsing) | Poisoned-fixture proof (D-18) | keybind-doctor | Real config: 13 passed, 0 failed, exit 0. Poisoned fixture: 12 passed, 1 failed (chord collision, named), exit 1. Full transcripts below | **PASS** — 2026-07-26 |

## Verified binary contract (2026-07-26)

Captured after `sudo pacman -S --needed quickshell` (operator-run, interactive password
prompt). Package resolved from the official `extra` repository, not AUR.

### `pacman -Qi quickshell`

```
Name            : quickshell
Version         : 0.3.0-2
Description     : Flexible toolkit for making desktop shells with QtQuick
Architecture    : x86_64
URL             : https://git.outfoxxed.me/quickshell/quickshell
Licenses        : LGPL-3.0-only
Groups          : None
Provides        : None
Depends On      : cpptrace  libcpptrace.so=1-64  glibc  hicolor-icon-theme  jemalloc  libjemalloc.so=2-64  libdrm  libgcc  libgcc_s.so=1-64  libglvnd  libEGL.so=1-64  libOpenGL.so=0-64  libpipewire  libpipewire-0.3.so=0-64  libstdc++  libstdc++.so=6-64  libxcb  mesa  pam  libpam.so=0-64  polkit  qt6-base  qt6-declarative  qt6-svg  qt6-wayland  wayland  libwayland-client.so=0-64
Optional Deps   : None
Required By     : None
Optional For    : None
Conflicts With  : None
Replaces        : None
Installed Size  : 6.00 MiB
Packager        : Peter Jung <ptr1337@archlinux.org>
Build Date      : Fri 05 Jun 2026 05:10:18 PM EEST
Install Date    : Sun 26 Jul 2026 10:26:47 AM EEST
Install Reason  : Explicitly installed
Install Script  : No
Validated By    : Signature
```

**Repository confirmation:** resolved from `extra` (official repo) — no AUR involvement.
Matches the Package Legitimacy Audit verdict in `11-RESEARCH.md` (maintainer Peter Jung,
upstream `git.outfoxxed.me/quickshell/quickshell`).

**Depends On (full closure, backs the "no hand-enumerated Qt6 lines" claim):**
`cpptrace libcpptrace.so=1-64 glibc hicolor-icon-theme jemalloc libjemalloc.so=2-64 libdrm
libgcc libgcc_s.so=1-64 libglvnd libEGL.so=1-64 libOpenGL.so=0-64 libpipewire
libpipewire-0.3.so=0-64 libstdc++ libstdc++.so=6-64 libxcb mesa pam libpam.so=0-64 polkit
qt6-base qt6-declarative qt6-svg qt6-wayland wayland libwayland-client.so=0-64`

`cpptrace` came in as a transitive dependency without any explicit `install.sh` request,
confirming RESEARCH.md's claim that pacman's own resolver handles the full Qt6/cpptrace
closure from the single `quickshell` `PACMAN_PKGS` entry.

### `pacman -Ql quickshell | grep '/bin/'` — installed binary paths

```
quickshell /usr/bin/
quickshell /usr/bin/qs
quickshell /usr/bin/quickshell
```

**Resolves RESEARCH.md Assumption A2:** the binary installs at `/usr/bin/quickshell`, the
standard Arch convention assumed in RESEARCH.md — confirmed directly, not assumed. This is
the exact path plan 05's `permission =` client-identifier must use.

**A `qs` alias/symlink DOES exist** at `/usr/bin/qs` — confirms the WebSearch snippet
referencing `qs ipc` sub-invocations in RESEARCH.md Open Question 1. Both `quickshell` and
`qs` are the same binary (pacman lists both paths for the one package).

### `quickshell --help` — full output, captured verbatim

**Wording divergence note:** the installed 0.3.0-2 binary's help text does not use the
literal word "Usage" anywhere — its usage line reads `quickshell [OPTIONS] [SUBCOMMAND]`
instead. The full raw output is captured verbatim in the fenced block below regardless.

```
quickshell [OPTIONS] [SUBCOMMAND]


OPTIONS:
  -h,     --help              Print this help message and exit
  -V,     --version           Print quickshell's version and exit.
  -n,     --no-duplicate      Exit immediately if another instance of the given config is
                              running.
  -d,     --daemonize         Detach from the controlling terminal.
[Option Group: Config Selection]
  Quickshell detects configurations as named directories under each XDG config
  directory as `<xdg dir>/quickshell/<config name>/shell.qml`.

  If `<xdg dir>/quickshell/shell.qml` exists, it will be registered as the
  'default' configuration, and no subdirectories will be considered. If --config
  is not passed, 'default' will be assumed.

  Alternatively, a config can be selected by path with --path.

  Examples:
  - `~/.config/quickshell/shell.qml` can be run with `qs`
  - `/etc/xdg/quickshell/myconfig/shell.qml` can be run with `qs -c myconfig`
  - `~/myshell/shell.qml` can be run with `qs -p ~/myshell`
  - `~/myshell/randomfile.qml` can be run with `qs -p ~/myshell/randomfile.qml`


OPTIONS:
  -p,     --path TEXT (Env:QS_CONFIG_PATH) Excludes: --config --manifest
                              Path to a QML file or config folder.
  -c,     --config TEXT (Env:QS_CONFIG_NAME) Excludes: --path
                              Name of a quickshell configuration to run.
  -m,     --manifest TEXT (Env:QS_MANIFEST) Excludes: --path
                              [DEPRECATED] Path to a quickshell manifest.
                              If a manifest is specified, configs named by -c will point to its
                              entries.
                              Defaults to $XDG_CONFIG_HOME/quickshell/manifest.conf
[Option Group: Logging]

OPTIONS:
          --no-color          Disables colored logging.
                              Colored logging can also be disabled by specifying a non empty
                              value for the NO_COLOR environment variable.
          --log-times         Log timestamps with each message.
          --log-rules TEXT    Log rules to apply, in the format of QT_LOGGING_RULES.
  -v,     --verbose           Increases log verbosity.
                              -v will show INFO level internal logs.
                              -vv will show DEBUG level internal logs.
[Option Group: Debugging]
  Options for QML debugging.


OPTIONS:
          --debug INT:INT in [0 - 65535]
                              Open the given port for a QML debugger connection.
          --waitfordebug Needs: --debug
                              Wait for a QML debugger to connect before executing the
                              configuration.

SUBCOMMANDS:
  log                         Print quickshell logs.
  list                        List running quickshell instances.
  kill                        Kill quickshell instances.
  ipc                         Communicate with other Quickshell instances.
  msg                         [DEPRECATED] Moved to `ipc call`.
```

**Resolves RESEARCH.md Open Question 1 / Assumption A1:** `-p`/`--path` exists exactly as
documented ("Path to a QML file or config folder"). Confirmed also: because
`~/.config/quickshell/shell.qml` will exist once the package is stowed, it is
auto-registered as the **'default'** configuration and a bare `qs`/`quickshell` invocation
with **no flags** runs it directly — no flag is strictly required for this repo's minimal
D-19 layout. The launcher (Task 2) uses the explicit `-p "$CONFIG_DIR"` form anyway, per
RESEARCH.md's recommendation, so the invocation is unambiguous and independent of XDG
default-config detection nuances.

**Exact flag Task 2's launcher uses:** `quickshell -p "$HOME/.config/quickshell"`

**Other findings relevant to later plans:**
- `-n`/`--no-duplicate` exists — useful if a later plan needs to guard against double-launch.
- `-d`/`--daemonize` exists — not used here; `uwsm app --` already handles session-scoped
  process supervision, matching D-06's explicit rejection of a systemd user unit.
- `ipc`/`msg` subcommands exist (`msg` deprecated in favor of `ipc call`) — relevant to a
  future D-16 spike if quickshell ever grows a `GlobalShortcut` introspection surface, but
  RESEARCH.md already confirmed no such introspection exists in 0.3.0 (D-17's manifest
  fallback stands).

## Hyprland baseline (pre-Quickshell, 2026-07-26)

Captured before any Quickshell process has ever run on this session, so
`quickshell-doctor` (plan 03) and later gates have a genuine before/after diff:

```
$ hyprctl version
Hyprland 0.56.0 built from branch v0.56.0 at commit 36b2e0cfe0c6094dbc47bd42a437431315bb3087
clean (version: bump to 0.56.0)

$ hyprctl monitors -j | jq -c '[.[] | {name, reserved, focused}]'
[{"name":"DP-1","reserved":[0,46,0,0],"focused":true}]

$ hyprctl globalshortcuts
none

$ hyprctl layers -j | jq -c '[.[].levels["3"][]?]'
[]
```

**Standing note (per plan Task 1 action):** `hyprctl globalshortcuts` currently reports the
literal string `none` — this is the pre-Quickshell baseline the plan-02 keybind-doctor
cross-check is measured against. Any later non-`none` output that contains `quickshell`/
`probe` is Quickshell's own registration, not pre-existing state.

**Display note (resume context):** an earlier session in this phase observed a synthesized
headless `FALLBACK` 1920x1080 output with all DRM connectors disconnected. That has been
resolved — `card1-DP-1` now reports `connected` and Hyprland reports a single real monitor,
`DP-1`, at 2560x1440 with `reserved=[0,46,0,0]` and `focused=true`, as captured above. Task
3's screen-name check read `DP-1`, confirmed — see the Dated gate log below.

## MAINT-01 — proven-to-fail collision detection

D-18: a collision detector that never fires is indistinguishable from a broken one. Both
runs below were captured back-to-back on 2026-07-26 against `hypr/.config/hypr/scripts/
keybind-doctor` as amended in this plan.

### Record-why: why structured `hyprctl binds -j` parsing was abandoned (D-14)

Hyprland 0.56.0's structured (`-j`) serializer for the bind query is **field-misaligned,
not merely malformed** — verified directly on this build. Its JSON parses without error,
but the values are shifted relative to their keys: `"modmask": false` where the integer
modmask belongs, the modmask's actual value (e.g. `"64"`) sitting inside the `submap`
string instead, and an unquoted bareword (e.g. `Return`) where the keycode belongs. A
syntax-only repair — retrying the call, wrapping it in more error handling — would have
kept consuming this and produced confidently **wrong** duplicate-chord answers while
looking like it worked. That is strictly worse than the loud `jq` parse-error crash
`keybind-doctor` had before this repair, which at least made the breakage visible.

A self-healing "auto-switch-back" probe (try the structured query first, fall back to
plain text only if it fails to parse) was discussed and **deliberately rejected**: a future
Hyprland build where the structured query parses cleanly but still misaligns fields would
sail straight through such a probe completely undetected, silently reintroducing wrong
data. Do not restore structured parsing for this reason.

What `keybind-doctor` parses instead: the plain-text `hyprctl binds` output, verified
field-correct across all 79 declared bind blocks on this exact build (Hyprland 0.56.0,
commit `36b2e0cfe0c6094dbc47bd42a437431315bb3087`) — `modmask:`, `submap:`, `key:`,
`keycode:`, `catchall:`, `description:`, `dispatcher:`, `arg:` all line up correctly. The
one wrinkle: each block's first line is a variable block-type token whose letters encode
the bind's flags, not a constant `"bind"` prefix — a `bindel = ...` declaration in
`keybinds.conf` surfaces here as `bindle` (letters reordered). `keybind-doctor`'s new
shape-guard check fails by name if this layout ever moves.

### D-17 gap record: Quickshell 0.3.0 has no GlobalShortcut runtime-introspection API

Per `11-RESEARCH.md` (citing quickshell.org/docs/v0.3.0/types/Quickshell.Hyprland/
GlobalShortcut/), Quickshell 0.3.0 exposes no call to read back which `GlobalShortcut`s it
has registered. `keybind-doctor` therefore treats `quickshell/.config/quickshell/
shortcuts.json` as the **declared** side (what Quickshell claims to own) and cross-checks
it against `hyprctl globalshortcuts` — Hyprland's own live registry of what actually got
claimed — as the **live** side. This gets D-16's intended benefit (live introspection)
under D-17's fallback mechanism (a declared manifest), because the compositor, not
Quickshell, is what actually exposes a queryable registry.

**`hyprctl globalshortcuts` raw output, verbatim (2026-07-26, quickshell pid running,
`Super+Shift+G` chord registered):**

```
$ hyprctl globalshortcuts
quickshell:probe ->
```

(Trailing space after `->` — the registered shortcut's `description` field is empty. An
empty registry would print the literal word `none`, as captured in the pre-Quickshell
baseline above.)

### Run 1 — poisoned fixture (must FAIL)

Fixture: the real `keybinds.conf` copied to a throwaway temp file (`mktemp -d`, never
committed — deleted immediately after this proof), with exactly one line appended:
`bind = $mainMod SHIFT, G, exec, kitty # deliberate collision fixture` — a chord the
Quickshell manifest already owns (`quickshell:probe`, `SUPER SHIFT`+`G`), bound instead to
an ordinary `exec` dispatcher.

```
$ hypr/.config/hypr/scripts/keybind-doctor "$D/poison.conf"
keybind-doctor — Hyprland keybind regression gate

  [PASS] $mainMod resolved from keybinds.conf (got: SUPER)
  [PASS] description parity (D-30): all 80 declared binds carry a trailing '#' description (missing: 0)
  [PASS] static grep: no 'walker -s <set>' invocation in keybinds.conf (known-broken flag on walker 2.16.2 — static grep only, not a runtime proof)
  [PASS] hyprctl binds returned data
  [PASS] plain-text bind block shape guard: 79 block(s) parsed from hyprctl binds, each carrying the expected 8 field labels (modmask/submap/key/keycode/catchall/description/dispatcher/arg) in order (shape errors: 0)
  [PASS] declared-vs-registered: all 80 declared binds appear in hyprctl binds (missing: 0)
  [PASS] no shadowing: zero (modmask,key,keycode,release) tuples shared by two different dispatcher targets (found: 0)
  [PASS] release-bind inventory recorded (1 release-triggered bind(s) registered)
    release-bind key: SUPER_L
  [PASS] D-03 kill-bind present and registered (Super+Escape -> pkill walker)
  [PASS] quickshell manifest schema: /home/aorus/.config/quickshell/shortcuts.json is a JSON array whose entries each carry non-empty appid/name/chord.mods/chord.key
  [PASS] no duplicate appid+name in quickshell manifest (a duplicate pair can crash Quickshell rather than reject cleanly — RESEARCH.md Pitfall 4; found: 0)
  [PASS] quickshell shortcut registered: every manifest entry's appid:name appears in hyprctl globalshortcuts (unregistered: 0, registry shape errors: 0)
    chord collision: keybinds.conf:204: bind = $mainMod SHIFT, G, exec, kitty # deliberate collision fixture collides with quickshell manifest entry quickshell:probe
  [FAIL] quickshell chord collision: zero Hyprland-declared binds claim a chord the manifest already owns without going through the matching global dispatcher (found: 1)

Summary: 12 passed, 1 failed
$ echo $?
1
```

The `chord collision` check names both the offending fixture line (`keybinds.conf:204:
bind = $mainMod SHIFT, G, exec, kitty ...`) and the manifest entry it collides with
(`quickshell:probe`) exactly as designed. `declared-vs-registered` still reports
`missing: 0` — expected, not a bug: the fixture's `(modmask,key,keycode,release)` tuple
is already live-registered by the *real* `global, quickshell:probe` bind, so the tuple
itself is present; only the exact `dispatcher:arg` combination differs, which is precisely
what the purely-static chord-collision check (not the live-state-dependent
declared-vs-registered check) is designed to catch.

**Environmental note (Rule 1 bug fix, in-scope):** `hypr/.config/hypr/config/
keybinds.conf` had no trailing newline. Appending a fixture line via `printf ... >>` onto
a file with no trailing newline concatenates the new line onto the file's last existing
line instead of starting a new one, silently producing a non-bind line (`windowrule = ...
scroll_touchpad 1.5bind = ...`) that the parser correctly ignores — making the collision
check falsely appear to pass. This would have quietly broken the *exact* self-test
mechanism this file's own header describes ("an explicit path is accepted so this gate can
be pointed at a throwaway copy for a regression self-test"). Fixed by adding the missing
trailing newline to `keybinds.conf` (whitespace-only change, no bind semantics affected) —
committed alongside this plan's `keybind-doctor` changes.

### Run 2 — real config, immediately afterward (must PASS)

```
$ hypr/.config/hypr/scripts/keybind-doctor
keybind-doctor — Hyprland keybind regression gate

  [PASS] $mainMod resolved from keybinds.conf (got: SUPER)
  [PASS] description parity (D-30): all 79 declared binds carry a trailing '#' description (missing: 0)
  [PASS] static grep: no 'walker -s <set>' invocation in keybinds.conf (known-broken flag on walker 2.16.2 — static grep only, not a runtime proof)
  [PASS] hyprctl binds returned data
  [PASS] plain-text bind block shape guard: 79 block(s) parsed from hyprctl binds, each carrying the expected 8 field labels (modmask/submap/key/keycode/catchall/description/dispatcher/arg) in order (shape errors: 0)
  [PASS] declared-vs-registered: all 79 declared binds appear in hyprctl binds (missing: 0)
  [PASS] no shadowing: zero (modmask,key,keycode,release) tuples shared by two different dispatcher targets (found: 0)
  [PASS] release-bind inventory recorded (1 release-triggered bind(s) registered)
    release-bind key: SUPER_L
  [PASS] D-03 kill-bind present and registered (Super+Escape -> pkill walker)
  [PASS] quickshell manifest schema: /home/aorus/.config/quickshell/shortcuts.json is a JSON array whose entries each carry non-empty appid/name/chord.mods/chord.key
  [PASS] no duplicate appid+name in quickshell manifest (a duplicate pair can crash Quickshell rather than reject cleanly — RESEARCH.md Pitfall 4; found: 0)
  [PASS] quickshell shortcut registered: every manifest entry's appid:name appears in hyprctl globalshortcuts (unregistered: 0, registry shape errors: 0)
  [PASS] quickshell chord collision: zero Hyprland-declared binds claim a chord the manifest already owns without going through the matching global dispatcher (found: 0)

Summary: 13 passed, 0 failed
$ echo $?
0
```

**Verdict: proven-to-fail, then proven-to-pass.** The temp fixture directory was deleted
immediately after Run 1 and is not present anywhere in this repo (`git status --porcelain`
stays clean of any `keybinds`-named file outside `hypr/.config/hypr/config/`).

## 11-03 — quickshell-doctor (QS-05/QS-06 mechanical coexistence gate)

`hypr/.config/hypr/scripts/quickshell-doctor` is the repo's seventh rerunnable gate
script, alongside `theme-doctor`, `theme-parity`, `theme-stress-test`, `keybind-doctor`,
`waybar-equivalence-check` and `waybar-design-lint`. It follows their shared house style
(`set -uo pipefail`, `check()`, `[PASS]`/`[FAIL]`, `Summary: N passed, N failed`,
`[[ "$FAIL" -eq 0 ]]; exit $?`) and lives in `hypr/.config/hypr/scripts/`, not inside the
`quickshell/` package it grades.

### Correction 1: `hyprctl layers -j` carries no reserved-space field on this build

Directly re-verified for this plan (same finding as plan 01/02's baseline): `hyprctl
layers -j` groups clients by shell-layer level (`"levels"` keys `"0"`-`"3"` =
background/bottom/top/overlay), and no client entry carries any reserved-space or anchor
field — only `address/x/y/w/h/alpha/namespace/pid`. A check written to grep this query for
such a field would report PASS whether Quickshell actually reserves screen space or not.
`quickshell-doctor`'s header comment records this explicitly so a future maintainer does
not "simplify" the check back into a `layers -j` grep. The real reserved-space accounting
lives on `hyprctl monitors -j`'s `reserved` array, and the check is a **before/during/after
diff**, never an equality against a hardcoded literal (`grep -c '0,46,0,0\|0, 46, 0, 0'
quickshell-doctor` returns 0 — the actual value never appears in the script).

**Raw pre-summon / during-summon / post-dismiss readings, captured back-to-back:**

```
$ hyprctl monitors -j | jq -c '[.[] | {name, reserved}]'   # pre-summon
[{"name":"DP-1","reserved":[0,46,0,0]}]
$ hyprctl layers -j | jq -c '[.[].levels["3"][]?]'          # pre-summon
[]

$ hyprctl dispatch global quickshell:probe                  # summon
ok
$ hyprctl monitors -j | jq -c '[.[] | {name, reserved}]'   # during summon
[{"name":"DP-1","reserved":[0,46,0,0]}]
$ hyprctl layers -j | jq -c '[.[].levels["3"][]?]'          # during summon
[{"address":"0x55e124081070","x":1100,"y":613,"w":360,"h":260,"alpha":1,"namespace":"quickshell-probe","pid":1011}]

$ hyprctl dispatch global quickshell:probe                  # dismiss
ok
$ hyprctl monitors -j | jq -c '[.[] | {name, reserved}]'   # post-dismiss
[{"name":"DP-1","reserved":[0,46,0,0]}]
$ hyprctl layers -j | jq -c '[.[].levels["3"][]?]'          # post-dismiss
[]
```

`reserved` is byte-identical across all three readings — Quickshell claims zero reserved
space summoning its one manifest surface, confirming QS-05's layout-shift criterion
mechanically rather than by literal comparison.

### Correction 2: the brightness criterion is `[SKIP]`, not PASS

`brightnessctl -l` on this host lists only `leds`-class devices
(`enp5s0-0::lan`..`enp5s0-3::lan`, `input5::capslock`, `input5::scrolllock`,
`input5::numlock`, `input11::mute`) — **no `backlight`-class device exists**. The check
detects the device *class*, not mere command presence, specifically so it does not try to
raise the capslock LED as a stand-in for a backlight. A laptop or a backlight-capable
external monitor would exercise this check; this desktop host cannot. Recorded here rather
than silently passed, per D-10's "no check silently passes when its instrument is missing"
rule.

### Full verbatim run (live desktop, shell up, 2026-07-26)

```
$ hypr/.config/hypr/scripts/quickshell-doctor
quickshell-doctor — Quickshell coexistence gate (QS-05/QS-06)

  [PASS] quickshell binary present on PATH
  [PASS] quickshell shell process alive (matches the launcher's exec'd invocation)
  [PASS] launcher log's last startup line (/home/aorus/.cache/quickshell.log:14) has no crash/abort marker after it
  [PASS] namespace discipline (D-21): every quickshell-* layer namespace sits at level 3 (overlay) and belongs to the shell's own PID (off-level: 0, wrong-pid: 0)
  [PASS] reserved-space stays unclaimed (D-21): summoning every manifest surface leaves monitors -j's reserved array byte-identical (changed: 0)
  [PASS] keybind-doctor clean (MAINT-01 bind-collision proof, exit 0)
  [PASS] single org.freedesktop.Notifications owner, and it is swaync (count: 1, owner: swaync)
  [PASS] single handler per hardware key: all 10 XF86Audio*/XF86MonBrightness* keys have exactly one registered handler (bad: 0)
    per-key counts: XF86AudioRaiseVolume=1 XF86AudioLowerVolume=1 XF86AudioMute=1 XF86AudioMicMute=1 XF86MonBrightnessUp=1 XF86MonBrightnessDown=1 XF86AudioNext=1 XF86AudioPause=1 XF86AudioPlay=1 XF86AudioPrev=1
  [PASS] zero Quickshell MPRIS writers (found in 0 file(s) under /home/aorus/.config/quickshell)
  [PASS] one-step-per-press volume probe: measured delta=3277 raw units matches recorded baseline=3277 (a later doubling would show as drift here)
  [SKIP] one-step-per-press brightness probe (no backlight-class device — brightnessctl -l lists only leds-class devices on this host)

Summary: 10 passed, 0 failed
$ echo $?
0
```

`pactl get-sink-volume @DEFAULT_SINK@` reported the identical raw values (front-left
36044, front-right 36044, 55%, -15.58 dB) before and after this run.

### Volume probe: baselined, not hardcoded

First run seeded `~/.local/state/quickshell/doctor-baseline.json` (D-20, out of git):

```json
{
  "volume_step_delta_raw": 3277
}
```

`3277` is one `swayosd-client --output-volume raise` step measured directly on this
host's sink (raw scale 0-65536, so ~5%) — not a hardcoded constant this repo owns. Every
subsequent run compares its own freshly-measured delta against this recorded value; a
future doubling (the actual double-handling symptom QS-06 guards against) would show up
as a mismatch here, not as a silent pass.

### SIGINT mid-probe: the trap fires on INT, not only on EXIT (T-11-11)

`kill -INT` sent directly to a backgrounded job's own PID is silently ignored by bash's
job-control disposition (`SIGINT` is set `SIG_IGN` for background children unless the
signal reaches the process through its controlling terminal) — this is a bash/job-control
property independent of the trap's own correctness, and was ruled out by delivering the
signal properly via `timeout --signal=INT`, which does not go through that job-control
path:

```
$ timeout --signal=INT --preserve-status 1.18 hypr/.config/hypr/scripts/quickshell-doctor
[... 9 checks printed, script interrupted mid-volume-probe before the check line or Summary print ...]
$ echo $?
130
```

`pactl get-sink-volume @DEFAULT_SINK@` reported the identical raw values before the run
and immediately after the interrupted run returned — the volume-mutation trap (armed
*before* the `swayosd-client --output-volume raise` call, per T-11-11) fired on `INT` and
restored the sink correctly even though the script never reached its own volume-probe
`check` line.

## 11-04 Task 1 — headless-output hotplug (QS-03): mechanics PASS, per-screen mounting FAILS

`quickshell-doctor` gained a fourth check group (`--no-headless-output`-gated) covering the
full `hyprctl output create/remove headless` cycle. Three of its four checks are clean,
repeatable PASSes; the fourth surfaces a genuine, previously-unproven QS-03 defect.

### What PASSes, mechanically, every run

```
$ hypr/.config/hypr/scripts/quickshell-doctor
  ...
  [PASS] headless output add: monitor count increased by exactly one (before: 1, after: 2), new output name read from the monitor list (not assumed): HEADLESS-10
  [FAIL] per-screen surface creation (QS-03): exactly one quickshell-probe surface under DP-1 (found: 1) and exactly one under HEADLESS-10 (found: 0), addresses distinct, not shared (shared: 0)
  [PASS] reserved-space unchanged across the hotplug cycle (QS-03): every baseline monitor's reserved array is byte-identical after the new screen appeared (changed: 0)
  [PASS] headless output remove (QS-03): monitor count back to baseline (1 == 1), DP-1 probe still creatable (found: 1), shell PID unchanged (185425 == 185425), no crash marker in launcher log (hits: 0)

Summary: 13 passed, 1 failed
```

- **Add**: monitor count always increases by exactly one; the new output's name is read
  back from `hyprctl monitors -j` (never assumed `HEADLESS-1` — the compositor increments
  the numeric suffix across the whole session's lifetime, confirmed directly: the same
  session produced `HEADLESS-1` through `HEADLESS-10` across this plan's testing).
- **Reserved-space unchanged**: `monitors -j`'s `reserved` array for every baseline monitor
  is byte-identical after the new screen appears — diffed, never compared against a
  hardcoded literal.
- **Remove**: monitor count returns to baseline, `DP-1`'s probe surface is still creatable
  immediately afterward, the shell process keeps the exact same PID, and no crash/abort
  marker lands in `~/.cache/quickshell.log` during the cycle.
- **Cleanup discipline verified under SIGINT**: `timeout --signal=INT --preserve-status`
  delivered mid-cycle (both immediately after "add" and immediately after "reserved-space
  unchanged") left the monitor count back at baseline every time — the removal trap (armed
  *before* the mutating `hyprctl output create headless` call, T-11-15) fires correctly on
  `INT`, mirroring the volume/brightness probes' existing discipline.
- **Pre-existing `HEADLESS*` guard verified**: with a `HEADLESS-7` output created by hand
  before the run, all four checks in the group print `[SKIP] ... a monitor named HEADLESS*
  already exists — not touching it`, and that pre-existing output is untouched and still
  present after the run.
- **`--no-headless-output` verified**: all four checks in the group downgrade to named
  `[SKIP]` lines, and the overall run exits 0.

### What FAILs, honestly and repeatably: per-screen surface creation

The current `modules/Probe.qml` is a single `PanelWindow` with no per-screen fan-out
mechanism (`shell.qml` wraps it in one `LazyLoader`, unchanged since 11-01). Verified
directly, repeatedly, before any QML was touched this plan:

```
$ hyprctl output create headless          # -> HEADLESS-1
$ hyprctl dispatch global quickshell:probe
$ hyprctl layers -j | jq -c '.'
{"DP-1":{"levels":{...,"3":[{"address":"0x...","namespace":"quickshell-probe",...}]}},
 "HEADLESS-1":{"levels":{...,"3":[]}}}
```

`DP-1` (the screen that existed when the shell started) gets its `quickshell-probe`
surface; the newly-hotplugged `HEADLESS-1` gets none. This is not a virtual-output quirk —
it is a property of the QML architecture that would identically affect a real second
physical monitor connected after the shell starts, since `PanelWindow` with no explicit
`screen:` binding renders on whichever screen Quickshell assigned it at instantiation, not
"every current and future screen." This is a real, previously-unproven QS-03 gap, not a
test-harness artifact (D-10's "headless-output quirk" carve-out does not apply here).

### Fix attempted and reverted — record-why (D-13's house rule, generalized)

A `Variants { model: Quickshell.screens }` fan-out (the standard Quickshell pattern for
per-monitor surfaces, confirmed to exist and to be correctly typed via this build's own
installed `.qmltypes` files: `Quickshell/quickshell-core.qmltypes` documents `Variants`,
`Quickshell.screens`, and `PanelWindow.screen` as a plain writable property) was
implemented and tested extensively, in several arrangements:

1. `Variants` in `shell.qml` wrapping the locally `import "modules"`-ed `Probe` type
   directly (`delegate: Component { Probe { visible: root.probeActive; ... } }`).
2. The same, with an additional lazy-loading layer between `Variants` and `Probe`
   (Quickshell's own `LazyLoader`, and separately a plain QtQuick `Loader`), in both
   nesting orders (`Variants` outer/loader inner, and loader outer/`Variants` inner).
3. The per-screen `Variants` fan-out moved entirely inside `Probe.qml` itself (rooted at
   `Variants` instead of `PanelWindow`), with `shell.qml` left touching the local `Probe`
   type only once, exactly as in the original design.

**Two independent, reproducible failure modes were found, not one:**

- **Intermittent hard config-load failure.** `Failed to load configuration / caused by
  @shell.qml[N:M]: Probe is not a type.` Verified directly with `quickshell -p ... -v -v`
  in the foreground: the synthesized `modules/qmldir` this run's scanner produced was
  completely empty (`Got intercept for ".../modules/qmldir" contains ""`), with no
  preceding `Scanning directory ".../modules"` log line at all — vs. a successful run's
  trace, which shows the scan happening and `Probe 1.0 Probe.qml` being registered before
  `shell.qml`'s document compile reaches the `Probe` reference. Across repeated
  clean-process restarts (`pkill -x quickshell` awaited to a clean `pgrep` miss, then
  relaunched via the real `quickshell-launch.sh` autostart path), **byte-identical file
  content loaded successfully in some restarts and failed in others** — one run of 10
  consecutive restarts was clean, a following run of 6 consecutive restarts of the same
  arrangement (2) failed 6/6. This points at a startup race in quickshell 0.3.0's own
  directory-based local-type scanner, not a syntax error in the QML itself — not something
  a QML source change alone can reliably close out.
- **Post-hotplug visibility break.** In arrangement (1) using `visible: root.probeActive`
  (rather than a lazy loader) to keep every screen's `Probe` object always-instantiated but
  unmapped at rest: the probe worked correctly on `DP-1` alone, and correctly gained a
  second, distinct-address instance on a headless output added afterward — but once a
  second screen existed, **the shortcut stopped toggling any screen's visibility at all**,
  including the previously-working `DP-1` instance, with no new warning or error logged.
  Repeated shortcut presses after that point produced no surface on any screen.

Both failure modes were reproduced multiple times, independently, in a live session with
the always-on autostart daemon — never in a way that crashed the process, but in ways that
left the probe unusable until a clean restart. Given standing constraint 5 ("do not
casually kill the running quickshell daemon... if a test requires restarting it, restore
it to a running state afterward and say so") and this phase's own house rule (record the
limitation, take the workable path, do not chase an open-ended workaround — this is
D-13's pattern, generalized beyond its original FileView scope), **the fix was reverted**.
`modules/Probe.qml` and `shell.qml` are confirmed byte-identical to their pre-11-04-Task-1
state (`git status --porcelain quickshell/` is empty), and the live daemon was restarted
and reconfirmed working correctly (summon/dismiss, same PID, clean log) before this plan
continued.

**This is not a QS-02 failure and does not stop the milestone (D-10).** It is recorded as
an open, non-blocking QS-03 gap: `quickshell-doctor`'s per-screen surface creation check
now honestly FAILs (13 passed, 1 failed, exit 1) until a future plan either finds a
reliable fix on a newer quickshell release, or invests a dedicated spike in the scanner
race rather than the incidental time available inside this plan's Task 1.

## 11-04 Task 2(a) — QML source hot-reload (QS-04, first half)

Verified mechanically, no human required (this half of Task 2 has no `<human-check>` in
the plan — only the `FileView`/`JsonAdapter` half does). With the shell running
(`quickshell -p /home/aorus/.config/quickshell`, pid unchanged throughout), the probe
summoned via `hyprctl dispatch global quickshell:probe`:

```
$ hyprctl layers -j | jq -c '[.[].levels["3"][]?]'   # before edit
[{"address":"0x...","w":360,"h":260,...}]
```

`modules/Probe.qml`'s `implicitWidth: 360` was edited to `420` on disk (the stowed symlink
target, the real repo file) while the shell stayed running — no restart, no `theme-apply`,
no reload command of any kind:

```
$ hyprctl layers -j | jq -c '[.[].levels["3"][]?]'   # after edit, same PID
[{"address":"0x...","w":420,"h":260,...}]
```

The running surface picked up the new width within the ~0.4s poll window (observed
latency: immediate). The edit was then reverted to `360`, and the revert propagated the
same way, confirmed by the surface's `w` returning to `360` with no restart. The shell
process PID was identical across the whole sequence (edit, observe, revert, observe), and
`git status --porcelain quickshell/` is empty after the revert
(`diff` against the pre-edit file confirms byte-for-byte identity). No colour, hex literal
or style value was introduced at any point (D-04 held throughout — confirmed via
`grep -riE '#[0-9a-f]{3,8}\b' quickshell/.config/quickshell/`, no matches).

**QML source hot-reload: PASS.** The `FileView`/`JsonAdapter` half of QS-04 (open question
#1) requires a human watching the on-screen label change while a text editor writes
`~/.local/state/quickshell/probe.json` — genuinely not mechanically provable, per the
plan's own Task 2 action text, and is handed to a checkpoint rather than assumed.

## Dated gate log

Appended to across Phase 11's plans (01-05) and by later phases (14-16) per D-05. Each
entry carries the date, the sub-criterion, and the raw observed result.

### 2026-07-26 — 11-04 Tasks 1 & 2a (QS-03 hotplug gate; QS-04 QML hot-reload)

- **[PASS] QS-03 — headless output add/remove mechanics:** monitor count diffed against
  baseline (never a hardcoded `HEADLESS-1` assumption — this session alone produced names
  through `HEADLESS-10`), reserved-space byte-identical across the cycle, monitor count and
  shell PID and launcher-log health all restored after removal. Verified clean under
  `timeout --signal=INT` delivered mid-cycle (twice, at two different points) and against a
  pre-existing `HEADLESS*` monitor (correctly `[SKIP]`ped and left untouched).
- **[FAIL, honestly recorded] QS-03 — per-screen surface creation:** the current
  single-`PanelWindow` probe design only mounts on whichever screen existed at shell
  startup; a headless output added afterward gets zero surfaces. Real defect, not a
  test-harness artifact. Fix attempted (`Variants` fan-out, multiple arrangements) and
  reverted after finding two independent failure modes (intermittent config-load race;
  post-hotplug visibility break) that risked the always-on daemon's stability. Not a
  stop-trigger (D-10) — recorded as an open gap for a future plan.
- **[PASS] QS-04(a) — QML source hot-reload:** editing `implicitWidth` on the live,
  running shell propagated within ~0.4s with no restart and no `theme-apply` involvement;
  the revert propagated the same way. Same PID throughout; `git status --porcelain
  quickshell/` empty after revert.
- **[PENDING] QS-04(b) — `FileView`/`JsonAdapter` hand-edit propagation:** requires a
  human watching the on-screen label; handed to a checkpoint (see Task 2's `<human-check>`).
- Live daemon confirmed restored to its known-good, single-instance state and running
  (same shell ID, functioning summon/dismiss) before this plan's remaining tasks proceed.

### 2026-07-26 — 11-03 (quickshell-doctor: QS-05/QS-06 full mechanical gate)

- **[PASS] QS-05 — namespace discipline (D-21):** every `quickshell-*` layer namespace
  sits at level 3 (overlay) and belongs to the shell's own PID (off-level: 0, wrong-pid: 0).
- **[PASS] QS-05 — reserved-space stays unclaimed:** `monitors -j`'s `reserved` array
  (`[0,46,0,0]`, all waybar's) is byte-identical before, during and after summoning every
  manifest surface — diffed, never compared against a hardcoded literal.
- **[PASS] QS-05 — keybind-doctor wired in:** invoked as part of the run, exit 0, 13/13.
- **[PASS] QS-06 — single Notifications owner:** `busctl --user list` reports exactly one
  owner, named `swaync`.
- **[PASS] QS-06 — single handler per hardware key:** all 10 XF86Audio\*/
  XF86MonBrightness\* keys resolve to exactly 1 registered handler (Hyprland bind count +
  Quickshell manifest count summed).
- **[PASS] QS-06 — zero Quickshell MPRIS writers:** 0 files under `~/.config/quickshell`
  reference MPRIS.
- **[PASS] QS-06 — one-step-per-press volume probe:** seeded baseline delta = 3277 raw
  units on first run; every subsequent run matches it exactly; sink volume byte-identical
  before/after, including under a SIGINT delivered mid-probe (trap fires on INT, not only
  EXIT — T-11-11).
- **[SKIP, honestly recorded] QS-06 — brightness probe:** no `backlight`-class device on
  this host (`brightnessctl -l` lists only `leds`-class devices).
- **Full gate:** 10 checks run, 10 passed, 0 failed, exit 0. `git status --porcelain`
  empty immediately after every run (baseline file lives under
  `~/.local/state/quickshell/`, out of git per D-20).

### 2026-07-26 — 11-02 (MAINT-01 keybind-doctor repair + Quickshell shortcut cross-check)

- **[PASS] Plain-text bind parser repair (D-14):** structured `hyprctl binds -j` and every
  `jq` filter over it removed from every executable line; plain-text parser verified
  field-correct across 79 blocks; shape guard added and passing.
- **[PASS] Quickshell shortcut cross-check (D-16/D-17):** manifest schema, no
  duplicate appid+name, live-registry registered check, and chord collision all added and
  passing against the real manifest and real config (13/13 checks green, exit 0).
- **[PASS] D-18 proven-to-fail proof:** poisoned fixture failed on the named
  `chord collision` check (exit 1, 12 passed/1 failed); real config passed immediately
  after (exit 0, 13 passed/0 failed).
- **ROADMAP/REQUIREMENTS amended per D-15:** criterion 4's structured-parsing and
  exclusive-zone-via-layers-query clauses replaced with the mechanisms this build actually
  delivers (`hyprctl binds` plain text; `hyprctl monitors -j`'s `reserved` array).

### 2026-07-26 — 11-01 Task 3 (QS-02 human input-viability gate)

Performed by the operator at the keyboard of the live Hyprland 0.56.0 session on `DP-1`,
against quickshell pid `305053` (`quickshell -p /home/aorus/.config/quickshell`), summoned
via `Super+Shift+G`. **All five sub-criteria PASS, human-attested:**

- **[PASS] Pointer:** clicking "Click me" incremented the visible counter; reached 4 after
  four clicks, as instructed.
- **[PASS] Keyboard:** typed input, including non-ASCII characters, appeared correctly in
  the text field in the order typed, with no mojibake and no dropped accents — under
  `WlrKeyboardFocus.OnDemand` (no escalation to `Exclusive` needed).
- **[PASS] Click-outside dismiss:** clicking anywhere outside the panel cleared
  `HyprlandFocusGrab` and hid the panel (`onCleared` -> `dismissRequested()` ->
  `probeLoader.active = false`).
- **[PASS] Screen-name check:** the panel's screen label read `DP-1`, matching the sole
  physical monitor on this host.
- **[PASS] Absent-state-file default:** `~/.local/state/quickshell/probe.json` was absent
  throughout; the state label rendered the `JsonAdapter`'s declared default (`unset`); the
  shell process did not crash (`WARN scene: ... File does not exist` logged, process stayed
  alive — orchestrator-verified pid `305053` still running).

**Supporting mechanical facts, observed live immediately before the gate was handed over**
(orchestrator-verified, used here as raw observed results rather than re-derived):
- `hyprctl layers -j | jq '[.[].levels["3"][]] | length'` = `0` while headless.
- `hyprctl globalshortcuts` reports `quickshell:probe` (baseline was the literal `none`).
- `hyprctl monitors -j | jq -c '[.[].reserved]'` = `[[0,46,0,0]]` — unchanged, zero
  exclusive zone claimed by Quickshell.
- Stow symlinks live: `~/.config/quickshell/{shell.qml,modules,shortcuts.json}` all resolve
  into the repo.
- D-11 satisfied: `install.sh` and `stow.sh` are both inside commit `1aea012`, the same
  commit that created the `quickshell/` package.

**Verdict: PASS.** v3.0 continues as roadmapped. No escalation to `WlrKeyboardFocus.Exclusive`
recorded — `OnDemand` is the standing convention Phase 14's drawer inherits.

## Reproduce

- Binary contract: `pacman -Qi quickshell`, `pacman -Ql quickshell | grep '/bin/'`,
  `quickshell --help`, `pacman -Si quickshell | grep -A5 'Depends On'` — all run directly
  against the installed 0.3.0-2 package on this host, 2026-07-26.
- Hyprland baseline: `hyprctl version`; `hyprctl monitors -j | jq -c '[.[] | {name, reserved, focused}]'`;
  `hyprctl globalshortcuts`; `hyprctl layers -j | jq -c '[.[].levels["3"][]?]'` — all run
  live against the session on this host, 2026-07-26, before any Quickshell process existed.
- `quickshell-doctor` (full mechanical gate, QS-05/QS-06): `hypr/.config/hypr/scripts/quickshell-doctor`
- `quickshell-doctor` (headless/CI-safe, no compositor summon): `hypr/.config/hypr/scripts/quickshell-doctor --no-summon`
- `keybind-doctor` (MAINT-01, invoked standalone or as part of the doctor's own run): `hypr/.config/hypr/scripts/keybind-doctor`
- Reserved-space raw check, run manually alongside a manual summon/dismiss:
  `hyprctl monitors -j | jq -c '[.[] | {name, reserved}]'` and
  `hyprctl layers -j | jq -c '[.[].levels["3"][]?]'`, before and after
  `hyprctl dispatch global quickshell:probe` (toggle summons/dismisses)
- Single-owner D-Bus check: `busctl --user list | grep org.freedesktop.Notifications`
- Baseline file (out of git, D-20): `cat ~/.local/state/quickshell/doctor-baseline.json`
