# Phase 2: Static ↔ Dynamic Parity & Switch Reliability - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-08
**Phase:** 2-Static ↔ Dynamic Parity & Switch Reliability
**Areas discussed:** Parity check form & depth, Stress test composition, What counts as 'correct', Tooling permanence, Contract source of truth, Divergence fix policy, Evidence & run artifacts, Walker 'open' semantics

---

## Parity check form & depth

| Option | Description | Selected |
|--------|-------------|----------|
| New theme-parity script | Dedicated rerunnable script in theme-engine/ next to theme-doctor | ✓ |
| Extend theme-doctor | Add parity section to existing doctor; blurs its read-only nature | |
| One-off diff in verification | No tooling, diff documented in VERIFICATION.md only | |

| Option | Description | Selected |
|--------|-------------|----------|
| Structure + variable names | Same file set + same variable name sets per file | |
| Add semantic value checks | Above plus valid hex/rgba in every slot, no `{{...}}` leftovers | ✓ |
| File set only | Just same files exist | |

| Option | Description | Selected |
|--------|-------------|----------|
| Render-only to temp dirs | Reuse lib/generate.sh into temp dirs; no desktop disruption | ✓ |
| Full theme-apply both modes | Real applies + restore; flashes desktop through 3 changes | |
| Hybrid with --live flag | Render-only core + optional live pair | |

| Option | Description | Selected |
|--------|-------------|----------|
| All 6 presets vs materialyou | All 7 outputs share structure/names, all slots valid | ✓ |
| One preset vs materialyou | Single representative pair | |
| You decide | Claude picks during planning | |

**User's choice:** New rerunnable `theme-parity` script, render-only snapshots, structure + names + semantic value checks, across all 6 presets + materialyou.

---

## Stress test composition

| Option | Description | Selected |
|--------|-------------|----------|
| Alternate static ↔ dynamic | Interleave presets and materialyou, rotate all 6 presets | ✓ |
| All presets then dynamic | 6 presets back-to-back then bounce to/from materialyou | |
| Random sequence | Random theme per iteration; non-reproducible | |

| Option | Description | Selected |
|--------|-------------|----------|
| Short fixed gap | 3–5s between switches; stragglers settle per D-21 | ✓ |
| Rapid-fire back-to-back | No gap; race hunting beyond PIPE-06's bar | |
| Both: paced run + rapid run | Paced as gate + rapid as diagnostic | |

| Option | Description | Selected |
|--------|-------------|----------|
| Same wallpaper throughout | Isolates theme-switch reliability | ✓ |
| Rotate wallpapers too | Couples test to awww/picker behavior | |

| Option | Description | Selected |
|--------|-------------|----------|
| Script launches & verifies them | Opens Thunar, triggers Walker, confirms elephant health | ✓ |
| Manual precondition | User opens apps; script only checks | |
| You decide | Claude picks during planning | |

**User's choice:** Alternating static↔dynamic 10-switch sequence, 3–5s gaps, fixed wallpaper, self-contained precondition setup.

---

## What counts as 'correct'

| Option | Description | Selected |
|--------|-------------|----------|
| Automated per-switch + your eyes on final | theme-doctor + content + liveness per switch; human sign-off on #10 | ✓ |
| Fully automated only | Script verdict only; can't see a wrong-colored widget | |
| Human sign-off every switch | Visual check ×10; tedious, not rerunnable | |

| Option | Description | Selected |
|--------|-------------|----------|
| Documented pass with caveat | Stale open Thunar window is not a failure (D-15); newly opened window must be themed | ✓ |
| Fail if stale | Reopens D-15, demands live GTK3 re-theming | |
| Close/reopen mid-run | Sidesteps the 'apps left open' scenario | |

| Option | Description | Selected |
|--------|-------------|----------|
| Sentinel color match | Grep a known palette color in rendered state-dir files | ✓ |
| current-theme file only | Name file check; stale render could pass | |
| Full snapshot diff | Diff vs fresh reference render each switch | |

| Option | Description | Selected |
|--------|-------------|----------|
| Abort with diagnostics | Stop at first failure, dump failing state to log | ✓ |
| Continue and report all | Scorecard at end; may smear evidence | |
| You decide | Claude picks during planning | |

**User's choice:** Automated per-switch checks with sentinel-color content proof, human final sign-off, D-15 documented pass, abort-on-failure with diagnostics.

---

## Tooling permanence

| Option | Description | Selected |
|--------|-------------|----------|
| Keeper scripts in theme-engine/ | Stowed regression tools, reused by Phase 3 VM verification | ✓ |
| Parity keeper, stress one-off | Stress test dies with the phase | |
| Both one-off phase artifacts | Nothing guards parity/reliability afterwards | |

| Option | Description | Selected |
|--------|-------------|----------|
| Parameterized with defaults | Flags for count/gap/sequence; bare run = PIPE-06 gate | ✓ |
| Fixed shape | Hardcoded 10-switch run | |
| You decide | Claude picks during planning | |

| Option | Description | Selected |
|--------|-------------|----------|
| Independent commands | doctor read-only, parity temp-render, stress mutating — separate | ✓ |
| theme-doctor --full umbrella | One entrypoint chaining doctor → parity | |
| You decide | Claude picks during planning | |

**User's choice:** Both tools stowed in theme-engine/, parameterized with PIPE-06 defaults, kept as independent commands.

---

## Contract source of truth

| Option | Description | Selected |
|--------|-------------|----------|
| Manifest file in theme-engine/ | contract file listing expected files + variable names; parity and doctor read it | ✓ |
| Derived from templates | Parse templates; 'templates agree with themselves' is weaker | |
| Hardcoded in theme-parity | Duplicates doctor's list, drifts silently | |

**User's choice:** Manifest file in theme-engine/.

---

## Divergence fix policy

| Option | Description | Selected |
|--------|-------------|----------|
| Clean full gate after last fix | Fixes may touch Phase 1 engine code; final evidence = parity all-green + fresh uninterrupted 10-switch run | ✓ |
| Resume from failure point | Stitched run; weaker than '10 consecutive' | |
| You decide | Claude picks during planning | |

**User's choice:** Clean full gate after last fix.

---

## Evidence & run artifacts

| Option | Description | Selected |
|--------|-------------|----------|
| Timestamped logs + phase report | Machine-readable run logs under ~/.local/state/theme/; VERIFICATION.md references passing runs | ✓ |
| Terminal output only | Copy-paste evidence, no trail | |
| You decide | Claude picks during planning | |

**User's choice:** Timestamped logs + phase report.

---

## Walker 'open' semantics

| Option | Description | Selected |
|--------|-------------|----------|
| Service healthy + summon at checkpoints | Per-switch service/elephant health; visible summon at human checkpoints | ✓ |
| Visibly summoned every switch | Manual burden ×10; restart closes the window anyway | |
| Service health only | Healthy process could still render wrong CSS | |

**User's choice:** Service healthy per switch + visible summon at the final (and optionally mid-run) human checkpoint.

---

## Claude's Discretion

- Exact script names and contract manifest format/filename
- Internal structure of both scripts, flag names, log format details
- Thunar window open/monitor mechanics and walker summon mechanics in the stress script
- Sentinel color key choice per theme and which files it's grepped in
- Whether optional mid-run human checkpoints are offered

## Deferred Ideas

- Rapid-fire (no-gap) race-hunting stress run — possible future diagnostic, not the gate
- Wallpaper rotation during dynamic stress — covered by D-20 picker wiring, out of scope here
