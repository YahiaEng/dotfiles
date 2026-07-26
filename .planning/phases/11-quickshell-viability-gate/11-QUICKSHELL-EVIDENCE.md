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
| QS-03 | Quickshell surfaces render correctly across all connected monitors and survive monitor hotplug | `hyprctl output create/remove headless` + probe summon on each output | hyprctl | — | PENDING (plan 04) |
| QS-04 | Editing Quickshell config hot-reloads the running shell without a manual restart | `FileView`/`JsonAdapter`/`watchChanges` live hand-edit test | Text editor + probe label | — | PENDING (plan 03/04) |
| QS-05 | The Quickshell shell autostarts with the session and runs alongside waybar, swaync, SwayOSD, wleave, AGS and walker with no layer-namespace collision, no exclusive-zone layout shift, and no duplicated global keybind | `hyprctl layers -j` / `monitors -j` diff, `quickshell-doctor` | hyprctl, quickshell-doctor | Baseline (pre-Quickshell): `monitors -j` reserved `[0,46,0,0]` on DP-1; `layers -j` level 3 empty; `globalshortcuts` reports `none`. Post-Task 2/Task 3: `globalshortcuts` reports `quickshell:probe`; `reserved` unchanged at `[0,46,0,0]`; level 3 empty while headless, exactly one `quickshell-probe` entry while summoned. Full `quickshell-doctor` mechanical gate (busctl owner check etc.) is plan 03's scope | PARTIAL — record-and-continue (D-10); autostart/coexistence sub-checks this plan can observe all PASS, full gate lands in plan 03 |
| QS-06 | No two processes double-handle the same event source — MPRIS, PipeWire, hardware media/brightness keys and `org.freedesktop.Notifications` each retain a single owner | `busctl --user list` single-owner check | busctl, quickshell-doctor | — | PENDING (plan 03) |
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

## Dated gate log

Appended to across Phase 11's plans (01-05) and by later phases (14-16) per D-05. Each
entry carries the date, the sub-criterion, and the raw observed result.

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
