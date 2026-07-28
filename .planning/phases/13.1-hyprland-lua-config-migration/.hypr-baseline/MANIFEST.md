# hypr-equivalence-check baseline manifest

- hyprctl version: Hyprland 0.56.1 built from branch v0.56.1 at commit 5c9377c15f85c50648f35ca5a213754f95b93ca0 clean (version: bump to 0.56.1).
- config format at capture time: hyprlang (.conf) — pre-migration (D-09)
- git commit: 7ea6ba5b012d73107cfd47b6377126124992e5c4
- capture timestamp (UTC): 2026-07-28T02:24:18Z
- option keys extracted (parsed from the 8 config files at run time, not hardcoded): 46
- binds.json bind count: 80
- options.jsonl record count: 46
- uncovered.txt entry count: 4

## Documented coverage limits (D-16)

One line per key/declaration this gate cannot (or structurally does not) introspect
via `hyprctl getoption`, with the reason and its named compensating check:

- `permission-grant:/usr/bin/quickshell, screencopy, allow` — permission grants are read once at Hyprland startup and are not exposed via hyprctl getoption — no per-grant introspection key exists; compensating check: recorded side-by-side textual review in plan 13.1-06
- `permission-grant:/usr/bin/grim, screencopy, allow` — permission grants are read once at Hyprland startup and are not exposed via hyprctl getoption — no per-grant introspection key exists; compensating check: recorded side-by-side textual review in plan 13.1-06
- `permission-grant:/usr/bin/hyprpicker, screencopy, allow` — permission grants are read once at Hyprland startup and are not exposed via hyprctl getoption — no per-grant introspection key exists; compensating check: recorded side-by-side textual review in plan 13.1-06
- `permission-grant:/usr/lib/xdg-desktop-portal-hyprland, screencopy, allow` — permission grants are read once at Hyprland startup and are not exposed via hyprctl getoption — no per-grant introspection key exists; compensating check: recorded side-by-side textual review in plan 13.1-06
