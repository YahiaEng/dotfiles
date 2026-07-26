<!-- Provenance: 11-01-PLAN.md Task 1, D-05 (quickshell-doctor + dated-record home),
     D-09/D-10 (QS-02 sole stop-trigger, everything else record-and-continue), D-11
     (registration lands before the human clicks). This file is the phase's single
     evidence artifact: it accumulates dated PASS/FAIL lines across Phase 11's plans
     (01-05) and is re-appended to by later phases (14-16) per D-05. Structural
     precedent: `.planning/milestones/v2.0-phases/08-waybar-evolution/08-BAR-02-EVIDENCE.md`. -->

# Phase 11: Quickshell Viability Gate — Evidence

**Verdict:** PENDING (QS-02 human gate not yet run — see Task 3)

## Gate table

| Gate | Criterion (verbatim) | Method | Instrument | Raw result | PASS/FAIL |
|---|---|---|---|---|---|
| QS-01 | `install.sh` installs Quickshell and its Qt6 dependencies from the official Arch `extra` repo, and `stow.sh` deploys the `quickshell/` package — both registered in the same commit that creates the package | `pacman -Qi quickshell`; `git show --stat` on the registration commit | pacman, git | Installed 0.3.0-2 from `extra`; registration commit lands in Task 2 (`install.sh` + `stow.sh` + `quickshell/` package together) | PENDING (Task 2) |
| QS-02 | A human can click a button, type into a text field, and dismiss by clicking outside on a Quickshell layer-shell surface on Hyprland 0.56.0 | Human-clicked live test at the keyboard | `PanelWindow` probe, `HyprlandFocusGrab` | — | PENDING (Task 3) |
| QS-03 | Quickshell surfaces render correctly across all connected monitors and survive monitor hotplug | `hyprctl output create/remove headless` + probe summon on each output | hyprctl | — | PENDING (plan 04) |
| QS-04 | Editing Quickshell config hot-reloads the running shell without a manual restart | `FileView`/`JsonAdapter`/`watchChanges` live hand-edit test | Text editor + probe label | — | PENDING (plan 03/04) |
| QS-05 | The Quickshell shell autostarts with the session and runs alongside waybar, swaync, SwayOSD, wleave, AGS and walker with no layer-namespace collision, no exclusive-zone layout shift, and no duplicated global keybind | `hyprctl layers -j` / `monitors -j` diff, `quickshell-doctor` | hyprctl, quickshell-doctor | Baseline (pre-Quickshell): `monitors -j` reserved `[0,46,0,0]` on DP-1; `layers -j` level 3 empty; `globalshortcuts` reports `none` | PENDING (Task 2/plan 03) |
| QS-06 | No two processes double-handle the same event source — MPRIS, PipeWire, hardware media/brightness keys and `org.freedesktop.Notifications` each retain a single owner | `busctl --user list` single-owner check | busctl, quickshell-doctor | — | PENDING (plan 03) |
| MAINT-01 | `keybind-doctor` correctly cross-checks Quickshell-claimed shortcuts against Hyprland's registered set (amended per D-15 to plain-text `hyprctl binds` parsing) | Poisoned-fixture proof (D-18) | keybind-doctor | — | PENDING (plan 02) |

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
3's screen-name check should read `DP-1`.

## Dated gate log

Appended to across Phase 11's plans (01-05) and by later phases (14-16) per D-05. Each
entry carries the date, the sub-criterion, and the raw observed result.

(No entries yet — QS-02's human gate is Task 3 of this plan.)

## Reproduce

- Binary contract: `pacman -Qi quickshell`, `pacman -Ql quickshell | grep '/bin/'`,
  `quickshell --help`, `pacman -Si quickshell | grep -A5 'Depends On'` — all run directly
  against the installed 0.3.0-2 package on this host, 2026-07-26.
- Hyprland baseline: `hyprctl version`; `hyprctl monitors -j | jq -c '[.[] | {name, reserved, focused}]'`;
  `hyprctl globalshortcuts`; `hyprctl layers -j | jq -c '[.[].levels["3"][]?]'` — all run
  live against the session on this host, 2026-07-26, before any Quickshell process existed.
