---
phase: 16-workspace-overview
reconstructed: true
reconstructed_date: 2026-08-16
as_of_date: 2026-08-10
as_of_note: "This report documents the state of Phase 16 as it stood at the v3.0 milestone close (2026-08-10), the date this phase's own UAT record closes on. It is NOT a re-verification against the current codebase."
reconstruction_sources:
  - 16-01-SUMMARY.md
  - 16-02-SUMMARY.md
  - 16-03-SUMMARY.md
  - 16-04-SUMMARY.md
  - 16-05-SUMMARY.md
  - 16-06-SUMMARY.md
  - 16-07-SUMMARY.md
  - 16-08-SUMMARY.md
  - 16-UAT.md
  - 16-OVER04-MEASUREMENT.md
status: passed
human_verified: 2026-08-10T13:40:00Z
human_verified_by: "16-UAT.md — 30/30 tests passed, 0 issues, 14 human-reviewed / 16 auto-covered"
closed_by_user_direction: true
gaps:
  - "OVER-04 frame-rate term (60fps floor, 165fps target): UNMEASURED at this phase's close. Only the CPU term was measured (INSIDE-BUDGET, 2.4x headroom). The compositor's own frame-time overlay — the only FPS instrument available on this host — froze the machine hard enough to require a physical restart when enabled against the live 11-tile grid, and was not retried."
  - "The three Phase 15 panels (audio/wifi/bluetooth) built on PanelDialog.qml carry no GradientBorder animated rim. This was diagnosed, not built by this phase, but remained an open, stated-user-expectation gap at this phase's (and the milestone's) close."
deferred: []
---

# Phase 16: Workspace Overview Verification Report

**Phase Goal:** A keybind opens a full-screen grid of workspaces showing live thumbnails
of every open window; clicking or dragging a thumbnail focuses or moves that window;
performance stays within an agreed frame/CPU budget or ships a documented fallback.
**As of:** 2026-08-10 (v3.0 milestone close — the date this phase's own `16-UAT.md` and
the v3.0 milestone both closed)
**This document was written retroactively, in Phase 21 (2026-08-16), not at Phase 16's
own close.** No `16-VERIFICATION.md` existed until now — this gap is exactly what
LEDGER-06 exists to close. See "Reconstruction Provenance" below for the full source
list and the ground rule this report follows.

## Reconstruction Provenance

This report was assembled entirely from Phase 16's own closing artifacts, all dated
2026-08-03 through 2026-08-10 — not from reading today's code, and not from re-running
any verifier against the current tree. The source set:

- The eight plan summaries — `16-01-SUMMARY.md` through `16-08-SUMMARY.md` — are the
  primary source. Every claim below traces to a specific one of these, cited inline.
- `16-UAT.md` — the operator's own acceptance record, 30/30 tests passed, 0 issues,
  closed 2026-08-10T13:40:00Z.
- `16-OVER04-MEASUREMENT.md` — the performance measurement record for OVER-04, as it
  read at the time this phase closed (its own CPU-term verdict and its own honest
  statement that the FPS terms went unmeasured).

**Ground rule, per the decision that authorized this reconstruction (D-21-23):** this
report states only what was true when Phase 16 closed. Any gap recorded as open below
was genuinely open at that time. If a later phase has since closed a gap named here,
that closure is deliberately **not** mentioned — annotating this report with
what-has-since-happened would blur the historical record this document exists to
preserve. A "what has since closed" view belongs in a milestone audit, not here.

## Goal Achievement

### Observable Truths (ROADMAP Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | A keybind (Super+O) opens a full-screen grid of workspaces showing live thumbnails of every open window. | ✓ VERIFIED | `16-02-SUMMARY.md`'s tracer proved the end-to-end path (Super+O → layer surface → `Hyprland.focusedWorkspace` → live `ScreencopyView` per window) after two false-pass rounds were caught by the operator and root-caused with a per-delegate IPC measurement (`lastIpcObject` staleness, fixed by `Hyprland.refreshToplevels()` on every summon). `16-03-SUMMARY.md` expanded this to the full ten-numbered-tile 5×2 grid plus an always-present eleventh scratchpad tile, human-confirmed pixel-stable across repeated summons. `16-UAT.md` tests 3-8 (source: human render gate + automated IPC checks) all pass. |
| 2 | Clicking a workspace tile's empty area focuses that workspace and closes the overview in the same gesture; clicking a window thumbnail directly focuses that window and closes. | ✓ VERIFIED | Tile-level click-to-focus shipped in the `16-02-SUMMARY.md` tracer. Window-level click parity shipped in `16-05-SUMMARY.md` (`activateWindow()` calling `toplevel.wayland.activate()`), but was NOT independently reproduced by the executor — no synthetic pointer tool exists on this host (`ydotool`/`wlrctl`/`dotool` absent, only keyboard-only `wtype`), so `16-05-SUMMARY.md`'s own coverage record marks this item `human_judgment: true`, structurally verified only. `16-UAT.md` test 16 is the first actual click test — human-confirmed pass, explicitly closing the executor-cannot-reproduce flag left open by 16-05. |
| 3 | Dragging a window thumbnail onto another workspace tile moves that window, with a hover-highlight on the drop target; the drag works symmetrically into and out of the scratchpad; a missed or same-tile drop is a clean no-op. | ✓ VERIFIED | `16-06-SUMMARY.md` shipped the guarded, address-shape-validated move dispatch (`hl.dsp.window.move({workspace=N, window="address:0x...", follow=false})`, locked live in `16-01-SUMMARY.md`'s spike), the single lit-tile drop-target highlight (reusing the panel family's existing lit-tile idiom), and the one shared cancel path for every non-move outcome. All four live drag proofs required a real pointer and were performed by the operator at `16-06-SUMMARY.md`'s Task 3 blocking render gate (approved 2026-08-07, no change requests) rather than executor-synthesized. `16-UAT.md` tests 18-21 confirm all four behaviors pass. |
| 4 | Live multi-window thumbnail performance is measured and stays within an agreed frame/CPU budget, with a documented fallback if it does not. | ⚠️ PARTIAL — CPU term only | `16-08-SUMMARY.md` / `16-OVER04-MEASUREMENT.md` recorded VERDICT **INSIDE-BUDGET** on the CPU term: worst observed 20.9% of one core during a sustained 12-window/5-workspace drag (2.4× headroom against the 50% ceiling), ~14% at rest and over a fullscreen client (3.1× headroom), 0.0% with the overview dismissed (zero-idle confirmed). No ladder rung was descended; no code changed. **The FPS floor (≥60fps) and FPS target (~165fps) terms are recorded UNMEASURED, not estimated or assumed.** The only FPS instrument available on this host — the compositor's own frame-time debug overlay, enabled via `hyprctl eval` + `hl.config({debug={overlay=true}})` — froze the machine hard enough to require a physical restart when tried against the live 11-tile grid, and was deliberately not retried ("a second forced restart is too high a price for a number" — `16-08-SUMMARY.md`). A qualitative note is recorded honestly as exactly that, not as a substitute: the sustained drag was performed without the operator reporting stutter or input lag, which is evidence the surface is usable but is explicitly stated to NOT be evidence the FPS floor holds. |

**Score:** 4/4 truths present and demonstrated; truth 4 is honestly partial (one of its two measured terms — CPU — passed with margin; the other — frame rate — is UNMEASURED, a real gap this phase closed on rather than papered over).

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `quickshell/.../modules/Overview.qml` | Full-screen layer surface, summon/dismiss, drag session owner, keyboard model, guarded move dispatch | ✓ VERIFIED | Created in `16-02-SUMMARY.md` (tracer), extended across `16-03` (grid/cascade), `16-05` (capture states, click parity), `16-06` (drag session), `16-07` (keyboard selection, click-outside dismiss, scrim removal) |
| `quickshell/.../modules/overview/WorkspaceTile.qml` | One workspace's tile: numbered or scratchpad, drop-target highlight, sweep-ring selection | ✓ VERIFIED | Created in `16-02-SUMMARY.md`, rewritten around `WindowThumbnail` in `16-03`, gains `dropTargetActive` in `16-06`, gains the sweep-ring/frosted-chrome redesign in `16-07` (13 render-gate rounds) |
| `quickshell/.../modules/overview/WindowThumbnail.qml` | The single general "a window drawn small" representation — sole `ScreencopyView` instantiation site | ✓ VERIFIED | Extracted in `16-03-SUMMARY.md` as the ONLY `ScreencopyView` site in `modules/overview/` (enforced by that plan's own directory-wide grep acceptance criterion); gains the three-state capture machine (populated/pending/failed) in `16-05`; gains the declarative drag input stack (`TapHandler`/`DragHandler`/`Drag`) in `16-06`; gains window-level selection outline + `MultiEffect` elevation in `16-07` |
| `quickshell/.../modules/overview/DragGhost.qml` | Cursor-following still snapshot of the dragged window | ✓ VERIFIED | Created in `16-06-SUMMARY.md`: a reused `WindowThumbnail` instance behind a `Loader` with `liveCapture:false` — a still snapshot by construction, not a second capture path |
| `hypr/.../scripts/quickshell-doctor` | 7 new checks (D-16-23) with poisoned-fixture proof | ✓ VERIFIED | `16-04-SUMMARY.md`: check count rises 15→22, self-test 19→36 entries, every new check has a committed poisoned fixture proven to FAIL and a compliant counterpart proven to PASS |
| `16-OVER04-MEASUREMENT.md` | Three-condition + baseline CPU measurement, named verdict | ✓ VERIFIED | `16-08-SUMMARY.md` — created, raw samples preserved including one deliberately-discarded pathological run (265% CPU from an unrepresentative busy-loop load generator) kept in the file specifically so a future reader does not repeat the mistake |
| `16-USE-NOTE.md` | Running use-note discharging criterion 5 (three calendar days of ordinary use) | ✓ VERIFIED | `16-08-SUMMARY.md`: opened 2026-08-08; `16-UAT.md` test 30 confirms the 2026-08-08 entry was approved with no defects reported |
| `permissions.lua` | `enforce_permissions = true`, recovery procedure in header | ✓ VERIFIED (committed), enforcement itself unproven live at close | `16-04-SUMMARY.md`: flag flipped and committed; the real session-restart proof of functional live enforcement across all five screencopy consumer paths was explicitly DEFERRED by operator decision during execution (the executor's own terminal is a child process of the compositor). `16-UAT.md` test 11 closes this deferral — the operator confirmed live at UAT time that it works. |

### Key Link Verification

| From | To | Via | Status |
|------|-----|-----|--------|
| `hypr/config/keybinds.lua` (`Super+O`) | `shell.qml` | `quickshell:overview` GlobalShortcut, `IpcHandler{target:"overview"}` (toggle/status) | ✓ WIRED (`16-02-SUMMARY.md`) |
| `Overview.qml` | `Hyprland.workspaces` / `HyprlandToplevel` | `Hyprland.refreshToplevels()` on every `Component.onCompleted` (mandatory pattern, `lastIpcObject` does not auto-populate) | ✓ WIRED (`16-02-SUMMARY.md`, re-confirmed at 11-tile scale in `16-03-SUMMARY.md`) |
| `WindowThumbnail.qml` | Hyprland compositor | `hl.dsp.window.move({workspace=N, window="address:0x...", follow=false})`, address normalised (0x-prefix) and shape-validated at dispatch time (T-16-25) | ✓ WIRED (`16-06-SUMMARY.md`) |
| `Overview.qml`'s keyboard model | `16-06`'s guarded move dispatch | `Shift+1..0` reuses the identical dispatch construction — move-dispatch call-site count stays 1 across both input paths | ✓ WIRED (`16-07-SUMMARY.md`) |
| `permissions.lua` | screencopy consumers (overview, screenshot, colour picker, browser share, screen recording) | `enforce_permissions=true` + 4 exact-path allow-list grants | ✓ WIRED per source, functional restart-proof deferred at execution time, closed by `16-UAT.md` test 11 |
| `quickshell-doctor` | `Overview.qml`'s `overview status` IPC verb | `overview-content-check` parses `windows=N withContent=M`, asserts `M>0` whenever `N>0` | ✓ WIRED, with an honestly-recorded coverage limit — see Gaps Summary |

### Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
|-------------|-----------------|--------------|--------|----------|
| OVER-01 | 16-01 … 16-05, 16-07 | Keybind opens full-screen grid with live thumbnails of every open window | ✓ SATISFIED | `16-UAT.md` tests 3-9, 12-15 all pass |
| OVER-02 | 16-02, 16-05, 16-07 | Clicking a workspace tile focuses that workspace and closes the overview | ✓ SATISFIED | `16-UAT.md` tests 1, 16, 22-26 all pass (extended to window-level click and full keyboard parity) |
| OVER-03 | 16-01, 16-06, 16-07 | Dragging a window thumbnail onto another workspace tile moves that window, with a hover-highlight on the drop target | ✓ SATISFIED | `16-UAT.md` tests 17-21, 24 all pass; all live-drag proofs human-performed (no synthetic pointer tool on this host) |
| OVER-04 | 16-04, 16-08 | Live multi-window thumbnail performance measured against an agreed frame/CPU budget, documented fallback if it fails | ⚠️ PARTIAL — CPU term only | `16-OVER04-MEASUREMENT.md`: VERDICT INSIDE-BUDGET on CPU (2.4× headroom worst case). **FPS floor and target recorded UNMEASURED** — the only available instrument (compositor debug overlay) froze the host and was not retried. No ladder rung was descended because there was no demonstrated miss to descend against, and the plan's own logic explicitly declines to descend "for a number that could not be taken." |

No orphaned requirements — OVER-01..04 all appear in at least one of this phase's eight plans' `requirements:` frontmatter fields, and every plan's declared requirements trace to this set.

### Behavioral Spot-Checks / Probe Execution

This phase's verification mechanism, as it existed at close, was `16-UAT.md` (a structured 30-test acceptance record cross-referencing each plan's own `coverage:` block) plus each plan's own live `<verify>` runs at execution time (`quickshell-doctor`, `keybind-doctor`, `motion-lint`, IPC status checks) — not a separate `scripts/*/tests/probe-*.sh` harness. `16-UAT.md` reports:

- **30 total tests, 30 passed, 0 issues, 0 pending, 0 skipped, 0 blocked.**
- **14 human-reviewed, 16 auto-covered** (source: automated IPC/log/grep checks cited directly in each plan's own coverage block).
- Two previously-open executor limitations were closed by the UAT session itself, both recorded honestly rather than silently absorbed: `16-04`'s deferred live-permission-enforcement proof (test 11), and `16-05`'s never-reproduced pointer-click test (test 16).

### Anti-Patterns Found

None reported across the eight plan summaries. `16-05-SUMMARY.md` and `16-07-SUMMARY.md` both record deliberate, honestly-labeled fault-injection and debugging artifacts (temporary `console.log` calls, a temporary diagnostic IPC verb) that were fully reverted before their respective commits — confirmed via empty `git diff --stat` in each case, not merely claimed.

### Human Verification Required (at this phase's close)

All items requiring human verification were exercised and closed by `16-UAT.md` on 2026-08-10, per the 30/30 pass record above. Nothing remained open in this category at close.

### Gaps Summary

Two genuine gaps existed when this phase closed, both recorded honestly by the phase's own plans rather than hidden:

1. **OVER-04's frame-rate term (60fps floor, ~165fps target): UNMEASURED.** `16-OVER04-MEASUREMENT.md`'s own verdict text states this plainly: "the FPS terms are recorded as unmeasured rather than estimated, guessed, or quietly dropped." The CPU term passed cleanly (INSIDE-BUDGET, 2.4× headroom worst case); the frame-rate term could not be measured on this host because the only available instrument — the compositor's own frame-time debug overlay — froze the machine hard enough to require a physical restart when tried against the live grid, and a second forced restart was judged too high a price for a number. No code was changed as a result (no ladder rung was descended — there was no demonstrated miss to descend against).

2. **The three Phase 15 panels (audio, wifi, bluetooth) built on `PanelDialog.qml` carry no `GradientBorder` animated rim.** This is not a Phase 16 deliverable — it is a real, diagnosed, deliberately-not-fixed gap in a different phase's own work that remained open at the time Phase 16 (and the v3.0 milestone) closed. It is recorded here because it stood alongside Phase 16's own missing verification report as one of the milestone's acknowledged open items at close.

Also recorded honestly at close (bookkeeping-only, no deliverable dropped): two coverage-block shape defects were found while `16-UAT.md` was being assembled — `16-05-SUMMARY.md`'s D5 entry carried an invalid `status: not_run` value, and `16-06-SUMMARY.md`'s D2/D3/D4 entries each declared `human_judgment: true` without the required `rationale` field. The UAT classifier failed safe in both cases (escalated to a human checkpoint rather than silently dropping the item), so no deliverable was lost — but the blocks themselves were malformed at this phase's close.

---

_As of: 2026-08-10 (v3.0 milestone / Phase 16 close)_
_Reconstructed: 2026-08-16, in Phase 21, from the source list in "Reconstruction Provenance" above_
_This document supersedes no other record — it fills the gap left by no `16-VERIFICATION.md` ever having been written at Phase 16's own close (LEDGER-06)._
