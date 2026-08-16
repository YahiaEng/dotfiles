---
phase: 20-indicators-power-menu
verified: 2026-08-16
status: passed
verification_method: operator-attested
must_haves_verified: 0
must_haves_total: 0
requirements_satisfied: [QOSD-01, QOSD-02, QOSD-03, QOSD-04, QPOWER-01, QPOWER-02, QPOWER-03, QPOWER-04, RETIRE-04, RETIRE-05, RETIRE-07, LEDGER-02, LEDGER-05]
requirements_unsatisfied: []
carried_debt: [brightness-osd-unverified-windows-row-78, theme-stress-test-visual-human-check, quickshell-doctor-live-run-2-preexisting]
human_verification: []
---

# Phase 20: Indicators & Power Menu — Verification

**Goal:** *On-screen indicators and the power menu are the shell's own QML surfaces, and swayosd, wleave, wlogout and eww are deleted with no fallback path.*

## ⚠ This report is operator-attested, not agent-verified

**No `gsd-verifier` agent ran for this phase.** The operator explicitly declined the tail gates —
code review, regression gate and goal verification — on 2026-08-16, stating they had verified the
work themselves ("Skip running the final gates, it is not worth it. I verified it myself").

This document exists so the phase can be closed with an accurate record rather than left in limbo.
It records **what was actually established and how**, and is deliberately explicit about what was
*not* independently checked. Do not read `status: passed` here as equivalent to a verifier pass in
phases 18 or 19 — it is the operator's own attestation.

`must_haves_verified` / `must_haves_total` are `0` rather than a fabricated score: no agent scored
the must-haves, and inventing a ratio would misrepresent the basis of this verdict.

## What WAS established, and by what evidence

### GATE-02 live sitting — the strongest evidence in this phase

Both render gates were run live by the operator and recorded before any deletion:

- **Gate A (OSD)** — `20-GATE-02-A-RECORD.md`, criteria 1–7. All PASS except criterion 3's
  brightness half (`NOT-DEMONSTRABLE`, see below). `RETIRE-04 AUTHORISED` at judged sha `8b6a111`.
- **Gate B (Power menu)** — `20-GATE-02-B-RECORD.md`, criteria 1–12 PASS; criterion 13
  (Phase 15 prompt-occlusion residual) `OVERRIDDEN` as a known accepted residual.
  `RETIRE-05 AUTHORISED` at the same judged sha.

Both gates were gated on a tree-state interlock so the authorisation could not outlive the code it
judged.

### Caps Lock — a measured finding, not a tick

GATE-01 measured the sysfs LED **watch** as non-functional on this kernel (Observation 3: a
`select.poll()` watcher printed no event on either transition). The implementation therefore uses a
bounded **250ms poll**, and the operator confirmed live that it fires. This closes RESEARCH Open
Question 1 and WINDOWS row 77, and it is what made removing swayosd's Caps Lock role safe.

### Four surfaces retired, verified absent

`pacman -Q` confirms all four absent: `swayosd`, `wleave`, `wlogout`, `eww`. The operator executed
every uninstall manually; no plan ran a `pacman -R`. Each plan verified the end state rather than
performing the removal.

### Automated gates green at phase close (plan 20-10)

`theme-doctor`, `theme-parity`, `motion-lint` (+ self-test 10/10), `colour-lint`,
`quickshell-doctor --self-test` (55/55), `keybind-doctor`, `retirement-check --all`,
`hypr-lua-harness` start/status/stop cycle, and `theme-stress-test` (10/10 switches, 132 passed,
0 failed — discharging the constraint deferred from 20-09).

### Design iteration

The power menu was rejected live after its first build and rebuilt through four revisions on
operator feedback (radial ring, frost/colour treatment, interaction, dimming). Every revision was
re-synced into `20-UI-SPEC.md` and D-20-21 before the gates ran, so Gate B judged the real contract.

## What was NOT verified — carried debt

1. **Brightness OSD (WINDOWS row 78, OPEN).** `NOT-DEMONSTRABLE`. This host has no backlight
   device (`/sys/class/backlight/` empty; `brightnessctl -l` shows only LED-class devices), so
   neither the old swayosd path nor the new `BrightnessBackend`-routed path can be exercised here.
   The operator confirmed these dotfiles **also target a laptop**, where this is a real deliverable
   that remains **implemented but unproven**. RETIRE-04 proceeded on an explicitly accepted risk.
   `.planning/todos/pending/2026-08-15-brightness-osd-unverifiable-on-desktop.md` carries the
   re-test procedure and stays open.
2. **`theme-stress-test` visual human-check.** Plan 20-10's `<human-check>` (watching a live theme
   switch by eye) was not performed. The automated equivalent passed; recorded as open rather than
   self-certified.
3. **Two pre-existing `quickshell-doctor` live-run failures**, unrelated to this phase, logged in
   `deferred-items.md` from plan 20-09.
4. **Requirement marks are trusted, not confirmed.** Plan 20-01's metadata commit marked
   RETIRE-04/05/07 and QOSD-01/02 complete from plan frontmatter, before that work existed.
   Cross-referencing those IDs against the codebase is precisely the verifier's job, and no
   verifier ran. The work demonstrably shipped — both surfaces are in daily use and all four
   packages are gone — but the marks were never independently checked.

## Verdict

**Goal achieved, on operator attestation.** Both QML surfaces ship and are in use; all four
retirement targets are deleted with no fallback path; every automated gate is green. The brightness
path is the one substantive deliverable that ships unproven, and it is recorded as such rather than
absorbed into a pass.
