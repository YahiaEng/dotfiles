---
schema_version: 1
open_count: 8
waived_count: 0
fixed_count: 0
total_count: 8
last_updated: 2026-07-26T20:29:08.850Z
---

# Broken Windows Ledger

> Cross-phase defect register. `/gsd-ship` blocks while `open_count > 0`.
> Waive with `gsd-tools windows waive <id> "<reason>"` (reason required).
> Mark fixed with `gsd-tools windows fixed <id>`.

| id | phase | kind | file | line | description | status | reason | recorded_at | resolved_at |
|----|-------|------|------|------|-------------|--------|--------|-------------|-------------|
| 1 | 09 | unrun-verify | theme-engine/.config/theme-engine/contract.json |  | theme-doctor/theme-stress-test blocked by orphaned eww.scss entry (phase 08-06/10-06 incomplete retirement) — unrelated to wlogout->wleave, see 09-02 deferred-items.md item 3 | open |  | 2026-07-25T16:10:45.874Z |  |
| 2 | 09 | deviation | hypr/.config/hypr/scripts/keybind-doctor |  | keybind-doctor's hyprctl binds -j JSON parsing broken on Hyprland 0.56.0 (pre-existing, all 78 binds affected uniformly) — see 09-02 deferred-items.md item 1 | open |  | 2026-07-25T16:10:45.954Z |  |
| 3 | 09 | unrun-verify | wleave/.config/wleave/style.css |  | D-10 entrance-vs-hover interaction (hovering during the ~350ms entrance stagger window) was not exercised live in this session — tooling available (hyprctl dispatch movecursor / wtype) could not reliably land a synthetic pointer/focus event inside that short window. Structural mitigation (entrance transform on the base rule, hover/focus scale on a separate paired selector, animation-fill-mode:backwards) is in place per plan, but not confirmed by a live capture. | open |  | 2026-07-25T16:49:50.384Z |  |
| 4 | 09 | deviation | .planning/phases/09-wlogout-to-wleave-migration/09-03-SUMMARY.md |  | 09-03 hover evidence (09-03-hover-dark.png) was captured via keyboard focus (wtype Tab), not literal mouse hover — hyprctl dispatch movecursor warps the compositor cursor position without emitting a wl_pointer motion/enter event this GTK4 client processes, confirmed by a live jiggle test that produced no :hover activation despite a correct hyprctl cursorpos. Since :hover and :focus are byte-identical paired CSS selectors in this stylesheet, the focus-driven capture proves the same code path, but the specific input modality (real mouse hover) remains unconfirmed live. | open |  | 2026-07-25T16:49:50.463Z |  |
| 5 | 09 | deviation | wleave/.config/wleave/layout.json |  | Icon glyph size is the SVG's natural/shrink-fit size under the icon+label vertical stack (empirically ~27-29px at the tuned margin), not forced to the UI-SPEC's literal 36px Display-role token — that token assumed the retired text-glyph delivery mechanism. Visually consistent and legible per the 09-03 evidence captures; not explicitly re-pinned to a fixed pixel size. | open |  | 2026-07-25T16:49:50.541Z |  |
| 6 | 09 | deviation | hypr/.config/hypr/scripts/wleave.sh |  | Fault-injection test (09-04): moving ~/.config/wleave/layout.json aside does NOT trigger the wrapper's launch-failure notify-send. wleave has its own packaged config fallback chain and silently loads /etc/wleave/layout.json (a large unstyled 3x2 grid, version-info footer visible) instead. This is not a silently-empty scrim (satisfies the UI-Consideration-1 backstop's core requirement) but it is a third, unenumerated outcome the wrapper script's command -v/kill -0 guards do not cover — wleave.sh has no check that the user's own layout.json exists. Not fixed in 09-04 (file not in this plan's declared files_modified); flagged for future triage. | open |  | 2026-07-25T17:10:45.472Z |  |
| 7 | 09 | deviation | hypr/.config/hypr/hyprlock.conf |  | hyprlock crashed (SIGABRT) during 09-04 human render-gate testing of the lock action. Almost certainly independent of this phase: the only hyprlock coredumps on this machine are dated 2026-04-02 and 2026-07-12 (five SIGABRTs), none from the 2026-07-25 session; the lock action string (uwsm app -- hyprlock) is byte-identical to the Phase-4-audited string, unchanged by this phase; and the human independently confirmed lock working earlier in the same gate. Logged for separate triage, not chased in this phase. | open |  | 2026-07-25T18:53:00.893Z |  |
| 8 | 12 | deviation | hypr/.config/hypr/config/animations.conf |  | Plan 12-04's acceptance criterion expected 'animation = ' count of 14; live file has 13 (pre-existing, unchanged by this plan; D-04 fence proven intact via before/after count equality) | open |  | 2026-07-26T20:29:08.850Z |  |

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
  },
  {
    "id": 3,
    "kind": "unrun-verify",
    "phase": "09",
    "file": "wleave/.config/wleave/style.css",
    "line": null,
    "description": "D-10 entrance-vs-hover interaction (hovering during the ~350ms entrance stagger window) was not exercised live in this session — tooling available (hyprctl dispatch movecursor / wtype) could not reliably land a synthetic pointer/focus event inside that short window. Structural mitigation (entrance transform on the base rule, hover/focus scale on a separate paired selector, animation-fill-mode:backwards) is in place per plan, but not confirmed by a live capture.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-25T16:49:50.384Z",
    "resolved_at": null
  },
  {
    "id": 4,
    "kind": "deviation",
    "phase": "09",
    "file": ".planning/phases/09-wlogout-to-wleave-migration/09-03-SUMMARY.md",
    "line": null,
    "description": "09-03 hover evidence (09-03-hover-dark.png) was captured via keyboard focus (wtype Tab), not literal mouse hover — hyprctl dispatch movecursor warps the compositor cursor position without emitting a wl_pointer motion/enter event this GTK4 client processes, confirmed by a live jiggle test that produced no :hover activation despite a correct hyprctl cursorpos. Since :hover and :focus are byte-identical paired CSS selectors in this stylesheet, the focus-driven capture proves the same code path, but the specific input modality (real mouse hover) remains unconfirmed live.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-25T16:49:50.463Z",
    "resolved_at": null
  },
  {
    "id": 5,
    "kind": "deviation",
    "phase": "09",
    "file": "wleave/.config/wleave/layout.json",
    "line": null,
    "description": "Icon glyph size is the SVG's natural/shrink-fit size under the icon+label vertical stack (empirically ~27-29px at the tuned margin), not forced to the UI-SPEC's literal 36px Display-role token — that token assumed the retired text-glyph delivery mechanism. Visually consistent and legible per the 09-03 evidence captures; not explicitly re-pinned to a fixed pixel size.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-25T16:49:50.541Z",
    "resolved_at": null
  },
  {
    "id": 6,
    "kind": "deviation",
    "phase": "09",
    "file": "hypr/.config/hypr/scripts/wleave.sh",
    "line": null,
    "description": "Fault-injection test (09-04): moving ~/.config/wleave/layout.json aside does NOT trigger the wrapper's launch-failure notify-send. wleave has its own packaged config fallback chain and silently loads /etc/wleave/layout.json (a large unstyled 3x2 grid, version-info footer visible) instead. This is not a silently-empty scrim (satisfies the UI-Consideration-1 backstop's core requirement) but it is a third, unenumerated outcome the wrapper script's command -v/kill -0 guards do not cover — wleave.sh has no check that the user's own layout.json exists. Not fixed in 09-04 (file not in this plan's declared files_modified); flagged for future triage.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-25T17:10:45.472Z",
    "resolved_at": null
  },
  {
    "id": 7,
    "kind": "deviation",
    "phase": "09",
    "file": "hypr/.config/hypr/hyprlock.conf",
    "line": null,
    "description": "hyprlock crashed (SIGABRT) during 09-04 human render-gate testing of the lock action. Almost certainly independent of this phase: the only hyprlock coredumps on this machine are dated 2026-04-02 and 2026-07-12 (five SIGABRTs), none from the 2026-07-25 session; the lock action string (uwsm app -- hyprlock) is byte-identical to the Phase-4-audited string, unchanged by this phase; and the human independently confirmed lock working earlier in the same gate. Logged for separate triage, not chased in this phase.",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-25T18:53:00.893Z",
    "resolved_at": null
  },
  {
    "id": 8,
    "kind": "deviation",
    "phase": "12",
    "file": "hypr/.config/hypr/config/animations.conf",
    "line": null,
    "description": "Plan 12-04's acceptance criterion expected 'animation = ' count of 14; live file has 13 (pre-existing, unchanged by this plan; D-04 fence proven intact via before/after count equality)",
    "status": "open",
    "reason": "",
    "recorded_at": "2026-07-26T20:29:08.850Z",
    "resolved_at": null
  }
]
````
