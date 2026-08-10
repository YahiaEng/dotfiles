# Roadmap: Arch + Hyprland Dotfiles

## Milestones

- ✅ **v1.0 Theme Pipeline Repair** — Phases 1-3 (shipped 2026-07-09) — [archive](milestones/v1.0-ROADMAP.md)
- ✅ **v2.0 Desktop Expansion** — Phases 4-10 (shipped 2026-07-25) — [archive](milestones/v2.0-ROADMAP.md)
- ✅ **v3.0 Quickshell Foundation & Motion Language** — Phases 11-17 (shipped 2026-08-10) — [archive](milestones/v3.0-ROADMAP.md)

## Phases

<details>
<summary>✅ v1.0 Theme Pipeline Repair (Phases 1-3) — SHIPPED 2026-07-09</summary>

- [x] Phase 1: Root-Cause Fix & Consolidated Theme Engine (3/3 plans) — completed 2026-07-07
- [x] Phase 2: Static ↔ Dynamic Parity & Switch Reliability (2/2 plans) — completed 2026-07-07
- [x] Phase 3: Repo Cleanup & Fresh-Install Reproducibility (4/4 plans) — completed 2026-07-08

Full details: [milestones/v1.0-ROADMAP.md](milestones/v1.0-ROADMAP.md)

</details>

<details>
<summary>✅ v2.0 Desktop Expansion (Phases 4-10) — SHIPPED 2026-07-25</summary>

- [x] Phase 4: Reliability Fixes & Tech Debt (6/6 plans) — completed 2026-07-11
- [x] Phase 5: Light Mode Pipeline & Theme Presets (5/5 plans) — completed 2026-07-11
- [x] Phase 6: Themed Surfaces & Utility Suite (19/19 plans) — completed 2026-07-13
- [x] Phase 7: Super-Key Menu (8/8 plans) — completed 2026-07-13
- [x] Phase 8: Waybar Evolution (16/16 plans) — completed 2026-07-15
- [x] Phase 9: wlogout to wleave Migration (4/4 plans) — completed 2026-07-25
- [x] Phase 10: AGS Media Applet (6/6 plans) — completed 2026-07-15

Originally scoped as Phases 4-8; Phases 9 and 10 were added mid-milestone in
response to findings (GTK3 stylesheet-discard failure class; eww pointer-input
dead end).

Full details: [milestones/v2.0-ROADMAP.md](milestones/v2.0-ROADMAP.md)

</details>

<details>
<summary>✅ v3.0 Quickshell Foundation & Motion Language (Phases 11-17) — SHIPPED 2026-08-10</summary>

- [x] Phase 11: Quickshell Viability Gate (5/5 plans) — completed 2026-07-26
- [x] Phase 12: Unified Design-Token Pipeline (8/8 plans) — completed 2026-07-27
- [x] Phase 13: Motion Retrofit & Existing-Surface Sweep (7/7 plans) — completed 2026-07-28
- [x] Phase 13.1: Hyprland Lua Config Migration (10/10 plans) — completed 2026-07-28 (INSERTED — urgent, upstream deadline)
- [x] Phase 14: Dashboard Drawer (10/10 plans) — completed 2026-08-01
- [x] Phase 15: Audio + Connectivity Panels (14/14 plans) — completed 2026-08-02
- [x] Phase 16: Workspace Overview (8/8 plans) — completed 2026-08-08 (UAT 30/30, 2026-08-10)
- [x] Phase 17: Ambient Extras (6/6 plans) — completed 2026-08-10

Phase 13.1 was inserted mid-milestone against a real upstream deadline —
Hyprland 0.57 removes hyprlang `.conf` support — and was not discretionary.
Phase 17 was scoped as the first thing to cut if the milestone ran long; it
shipped in full.

Closed as an **override closeout**: Phase 16 has no VERIFICATION.md (its
evidence is `16-UAT.md`, 30/30 passed), and 53 open artifacts were acknowledged
as carried debt. See `milestones/v3.0-MILESTONE-AUDIT.md` and STATE.md
`## Deferred Items`.

Full details: [milestones/v3.0-ROADMAP.md](milestones/v3.0-ROADMAP.md)

</details>

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Root-Cause Fix & Consolidated Theme Engine | v1.0 | 3/3 | Complete | 2026-07-07 |
| 2. Static ↔ Dynamic Parity & Switch Reliability | v1.0 | 2/2 | Complete | 2026-07-07 |
| 3. Repo Cleanup & Fresh-Install Reproducibility | v1.0 | 4/4 | Complete | 2026-07-08 |
| 4. Reliability Fixes & Tech Debt | v2.0 | 6/6 | Complete | 2026-07-11 |
| 5. Light Mode Pipeline & Theme Presets | v2.0 | 5/5 | Complete | 2026-07-11 |
| 6. Themed Surfaces & Utility Suite | v2.0 | 19/19 | Complete | 2026-07-13 |
| 7. Super-Key Menu | v2.0 | 8/8 | Complete | 2026-07-13 |
| 8. Waybar Evolution | v2.0 | 16/16 | Complete | 2026-07-15 |
| 9. wlogout to wleave Migration | v2.0 | 4/4 | Complete | 2026-07-25 |
| 10. AGS Media Applet | v2.0 | 6/6 | Complete | 2026-07-15 |
| 11. Quickshell Viability Gate | v3.0 | 5/5 | Complete | 2026-07-26 |
| 12. Unified Design-Token Pipeline | v3.0 | 8/8 | Complete | 2026-07-27 |
| 13. Motion Retrofit & Existing-Surface Sweep | v3.0 | 7/7 | Complete | 2026-07-28 |
| 13.1. Hyprland Lua Config Migration | v3.0 | 10/10 | Complete | 2026-07-28 |
| 14. Dashboard Drawer | v3.0 | 10/10 | Complete | 2026-08-01 |
| 15. Audio + Connectivity Panels | v3.0 | 14/14 | Complete | 2026-08-02 |
| 16. Workspace Overview | v3.0 | 8/8 | Complete | 2026-08-08 |
| 17. Ambient Extras | v3.0 | 6/6 | Complete | 2026-08-10 |

**Totals:** 18 phases · 141 plans complete · 3 milestones shipped

## Next Milestone

v4.0 is not yet scoped. Run `/gsd-new-milestone` to define it.

Carry-ins it must decide on (from `milestones/v3.0-MILESTONE-AUDIT.md` and
PROJECT.md § Active):

- Migrating and retiring the existing GTK surfaces onto QML — the deferred half
  of the decomposed rewrite v3.0 deliberately did not start
- `GradientBorder` reuse across the panel family (real gap, stated user
  expectation unmet)
- MAINT-02 — wrap Logout like Shutdown/Reboot (the one unfinished v3.0
  requirement; its measurement gate was waived, not performed)
- OVER-04's frame-rate term, still unmeasured
- Curating the 6 open debug sessions
