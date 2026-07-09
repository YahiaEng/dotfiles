# Phase 2: Static ↔ Dynamic Parity & Switch Reliability - Context

**Gathered:** 2026-07-08
**Status:** Ready for planning

<domain>
## Phase Boundary

Prove what Phase 1 built: static presets and matugen dynamic themes are genuinely ONE pipeline producing an identical output contract (PIPE-04), and switching stays correct under repeated real-world use — 10 consecutive switches with Thunar and Walker open, 100% correct on the final switch (PIPE-06). This is a verification-and-hardening phase: it builds rerunnable proof tooling (`theme-parity`, a stress-test script) and fixes any divergence or reliability bug those tools surface. Fixes may freely touch Phase 1's theme-engine code — same pipeline, now being hardened.

Out of this phase: repo cleanup / install.sh hardening / fresh-VM verification (Phase 3), all v2 expansion (OSD, walker menus, media widget, light themes), live GTK3 re-theming of already-open windows (D-15 caveat stands).

</domain>

<decisions>
## Implementation Decisions

### Parity check (`theme-parity`)
- **D-26:** Parity proof is a new dedicated rerunnable script (working name `theme-parity`) in `theme-engine/.config/theme-engine/`, alongside `theme-doctor` — not an extension of it, not a one-off diff.
- **D-27:** Snapshots are **render-only to temp dirs**: reuse the engine's render step (`lib/generate.sh`) to render themes into temp dirs and diff those. No desktop disruption, no reloads fired, safe to run anytime. It tests exactly what PIPE-04 covers — the output contract, not the reload.
- **D-28:** Depth: structure + variable names + **semantic value checks**. Both modes must produce the exact same file set; each file must contain the same set of variable/color names; AND every color slot must hold a well-formed value (valid hex/rgba, no empty slots, no literal `{{...}}` template leftovers).
- **D-29:** Coverage: **all 6 presets vs materialyou** — all 7 rendered outputs must share identical structure/variable names and pass semantic checks. Catches a broken individual palette JSON, not just a broken mode.

### Output contract definition
- **D-30:** The canonical output contract (expected state-dir files + per-file required variable/key names) lives in a **manifest file in `theme-engine/`** (e.g. `contract.json` or sourced shell list — exact format Claude's discretion). `theme-parity` validates against it; `theme-doctor`'s existing file-list check should read the same list. Adding a future app target = one manifest update.

### Stress test composition
- **D-31:** Sequence: **alternate static ↔ dynamic** (e.g. catppuccin → materialyou → nord → materialyou → …), rotating through all 6 presets across the 10 switches, so both mode-transition directions are exercised repeatedly — that's where mode-only divergence hides.
- **D-32:** Pacing: **short fixed gap (3–5s)** between switches — enough for restart-based stragglers (Thunar daemon, walker relaunch) to settle per D-21's 1–2s window. Matches real usage; not a race-hunting rapid-fire test.
- **D-33:** Wallpaper stays **the same throughout** — materialyou iterations reuse the current wallpaper. The test isolates theme-switch reliability (PIPE-06's scope), not wallpaper-picker behavior.
- **D-34:** The script **launches and verifies its own preconditions**: opens a Thunar window, ensures walker's service + elephant are running/healthy before the first switch, and asserts both are still alive at the end. No manual setup step.

### Correctness assertions
- **D-35:** Verdict model: **automated per-switch checks + human visual sign-off on the final switch.** Per-switch: theme-doctor passes, state-dir content matches the applied theme, required processes alive. After switch #10 the user visually confirms every app is correctly themed — that human check is the success-criterion bar.
- **D-36:** Per-switch content check is a **sentinel color match**: take a known color from the applied palette (e.g. accent/primary from the palette JSON or matugen output) and grep that it landed in the rendered state-dir files. Proves THIS theme rendered, not a stale previous one — directly targets drift/stale-cache failure modes.
- **D-37:** **D-15 caveat is a documented pass:** an already-open Thunar window keeping the old palette until closed is NOT a failure. The final visual check verifies a *newly opened* Thunar window has the new palette. State the caveat explicitly in VERIFICATION.md.
- **D-38:** Walker "open" semantics: per-switch the assertion is **service health** (walker gapplication service + elephant running, version-matched); **visible summon happens at human checkpoints** — the user opens Walker at the final switch (optionally mid-run) to confirm themed rendering and working results.
- **D-39:** On mid-run failure: **abort immediately with diagnostics** — dump which check failed, at which switch, theme-doctor output, and relevant file contents to a log. First failure is the most diagnosable; PIPE-06 demands 100% anyway.

### Fix policy & gate
- **D-40:** Divergences/bugs found by parity or stress runs are **fixed in this phase**, and fixes may freely modify Phase 1 engine code.
- **D-41:** **Clean full gate after the last fix:** final evidence must be `theme-parity` all-green AND a fresh, uninterrupted 10-switch stress run with zero failures. No stitched/resumed runs as passing evidence.

### Tooling permanence
- **D-42:** Both `theme-parity` and the stress-test script are **keeper scripts stowed in `theme-engine/.config/theme-engine/`** alongside `theme-doctor` — rerunnable regression tools, reproducible on fresh installs, reused by Phase 3's fresh-VM verification (extends the D-25 precedent).
- **D-43:** Stress test is **parameterized with defaults matching PIPE-06** (10 switches, 3–5s gap, alternating sequence). A bare run reproduces the requirement gate exactly; flags allow cranking it (e.g. 50 switches) for future debugging.
- **D-44:** All three tools stay **independent commands** — `theme-doctor` remains the fast read-only invariant check; `theme-parity` renders to temp; the stress test mutates the live desktop. No umbrella flag; Phase 3 calls each explicitly.

### Evidence
- **D-45:** Runs produce **timestamped machine-readable logs** (pass/fail per check) under `~/.local/state/theme/` (or a `logs/` subdir there); the phase's VERIFICATION.md references/quotes the passing runs. Phase 3's VM verification parses the same log format.

### Claude's Discretion
- Exact names of the new scripts (`theme-parity` and the stress script's name) and the contract manifest's format/filename.
- Internal structure of both scripts, flag names, log format details.
- How the stress script opens/monitors the Thunar window and summons/kills walker mechanics.
- Which palette key serves as the sentinel color per theme, and which state-dir files it's grepped in.
- Whether mid-run optional human checkpoints (beyond the final one) are offered.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Requirements & roadmap
- `.planning/REQUIREMENTS.md` — PIPE-04 and PIPE-06, the only two requirements this phase covers
- `.planning/ROADMAP.md` — Phase 2 goal, success criteria, single-plan breakdown (02-01)

### Prior phase decisions (locked — do not re-litigate)
- `.planning/phases/01-root-cause-fix-consolidated-theme-engine/01-CONTEXT.md` — D-01..D-25; especially D-03 (single rendering path), D-06 (per-app output contract), D-14 (atomic render-then-commit), D-15 (Thunar open-window staleness accepted), D-21 (latency soft target), D-25 (theme-doctor as rerunnable regression check)
- `.planning/phases/01-root-cause-fix-consolidated-theme-engine/01-VERIFICATION.md` — what Phase 1 verified and how (5/5 pass after gap closure)

### The code being proven (Phase 1's engine)
- `theme-engine/.config/theme-engine/theme-apply` — single entrypoint; the stress test drives this
- `theme-engine/.config/theme-engine/theme-doctor` — existing invariant checks the stress test reuses per-switch; its file list should move to / read from the new contract manifest
- `theme-engine/.config/theme-engine/lib/generate.sh` — render step `theme-parity` must reuse for render-only snapshots
- `theme-engine/.config/theme-engine/lib/commit.sh`, `lib/reload.sh`, `lib/gtk.sh` — atomic commit + reload fan-out, likely fix surface if stress finds bugs
- `theme-engine/.config/theme-engine/palettes/*.json` — the 6 static palettes; source of sentinel colors and parity inputs
- `matugen/.config/matugen/config.toml` + `matugen/.config/matugen/templates/` — the shared template fan-out both modes render through

### Output under test
- `~/.local/state/theme/` — the state dir holding the canonical output contract (10 per-app files + `current-theme`); not in the repo but is the object being diffed

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `theme-doctor` (140 lines, ~15 checks): package installed, gsettings, state-dir files present, symlinks, stow conflicts, walker/elephant health + version match — the per-switch automated check reuses this wholesale
- `lib/generate.sh`: the render path `theme-parity` calls with a temp-dir target instead of the live state dir
- `theme-apply`'s atomic temp-dir render (D-14) already renders to `mktemp -d` before commit — precedent for render-only mode
- Palette JSONs contain named color keys usable as sentinel values

### Established Patterns
- Rerunnable check script pattern established by theme-doctor (D-25) — new tools follow its check/report style
- `set -euo pipefail` + counter arithmetic gotcha from 01-03 (`(( counter++ ))` aborts at 0 under `set -e`) — use `counter=$((counter+1))` in new scripts
- Stow package layout: new scripts go in `theme-engine/.config/theme-engine/`, stowed like the rest
- Notify-send feedback pattern for user-facing errors

### Integration Points
- Stress test drives `theme-apply <name>` exactly as the picker does — no new entrypoint
- theme-doctor's hardcoded state-dir file list is the natural first consumer of the contract manifest (D-30)
- `~/.local/state/theme/walker-relaunch.log` shows the state dir already hosts logs — `logs/` subdir fits (D-45)
- Phase 3's fresh-VM verification (INST-01) will invoke theme-doctor, theme-parity, and the stress script — keep them non-interactive-friendly apart from the human final check

</code_context>

<specifics>
## Specific Ideas

- The user consistently chose the recommended engineering-rigor option, then went one notch stronger on parity depth (added semantic value checks on top of structure+names) — bias tooling toward catching template-rendering rot, not just structural drift.
- "Stuck-white" history is the emotional core of this project: automated checks alone were explicitly rejected as the final verdict — the human eyes-on-final-switch step is non-negotiable evidence.
- The user asked to explore MORE gray areas after the initial four — they want this phase's edges fully pinned before planning; the plan should not introduce new undecided policy.

</specifics>

<deferred>
## Deferred Ideas

- **Rapid-fire race-hunting stress run** — a no-gap back-to-back switch test was considered and not chosen as the gate; could return as a diagnostic tool if races ever surface (noted, unowned).
- **Wallpaper-rotation during dynamic stress** — coupling wallpaper changes into the stress run was rejected for scope; wallpaper→palette behavior is covered by D-20's picker wiring.
- None other — discussion stayed within phase scope.

</deferred>

---

*Phase: 2-Static ↔ Dynamic Parity & Switch Reliability*
*Context gathered: 2026-07-08*
