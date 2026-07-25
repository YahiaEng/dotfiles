---
schema_version: 1
open_count: 2
waived_count: 0
fixed_count: 0
total_count: 2
last_updated: 2026-07-25T16:10:45.954Z
---

# Broken Windows Ledger

> Cross-phase defect register. `/gsd-ship` blocks while `open_count > 0`.
> Waive with `gsd-tools windows waive <id> "<reason>"` (reason required).
> Mark fixed with `gsd-tools windows fixed <id>`.

| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |
|----|-------|------|------|------|-------------|--------|--------|-------------|-------------|
| 1 | 09 | unrun-verify | theme-engine/.config/theme-engine/contract.json |  | theme-doctor/theme-stress-test blocked by orphaned eww.scss entry (phase 08-06/10-06 incomplete retirement) — unrelated to wlogout->wleave, see 09-02 deferred-items.md item 3 | open |  | 2026-07-25T16:10:45.874Z |  |
| 2 | 09 | deviation | hypr/.config/hypr/scripts/keybind-doctor |  | keybind-doctor's hyprctl binds -j JSON parsing broken on Hyprland 0.56.0 (pre-existing, all 78 binds affected uniformly) — see 09-02 deferred-items.md item 1 | open |  | 2026-07-25T16:10:45.954Z |  |

````json
[
  {
    "id": 1,
    "kind": "unrun-verify",
    "phase": "09",
    "file": "theme-engine/.config/theme-engine/contract.json",
    "line": null,
    "description": "theme-doctor/theme-stress-test blocked by orphaned eww.scss entry (phase 08-06/10-06 incomplete retirement) — unrelated to wlogout->wleave, see 09-02 deferred-items.md item 3",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-25T16:10:45.874Z",
    "resolved_at": null
  },
  {
    "id": 2,
    "kind": "deviation",
    "phase": "09",
    "file": "hypr/.config/hypr/scripts/keybind-doctor",
    "line": null,
    "description": "keybind-doctor's hyprctl binds -j JSON parsing broken on Hyprland 0.56.0 (pre-existing, all 78 binds affected uniformly) — see 09-02 deferred-items.md item 1",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-25T16:10:45.954Z",
    "resolved_at": null
  }
]
````
