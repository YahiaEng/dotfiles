---
status: complete
phase: 11-quickshell-viability-gate
source:
  - 11-01-SUMMARY.md
  - 11-02-SUMMARY.md
  - 11-03-SUMMARY.md
  - 11-04-SUMMARY.md
  - 11-05-SUMMARY.md
started: 2026-07-26T12:25:00Z
updated: 2026-07-26T12:55:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Doctor scripts still green after the code-review fixes
expected: keybind-doctor 13/0 exit 0; quickshell-doctor 13 passed / 1 failed exit 1 with the ONLY failure being the known per-screen check. No new failures, no stranded probe surface, volume restored.
result: pass

### 2. Quickshell input viability — click, type, dismiss (QS-02)
expected: Press Super+Shift+G to summon the probe panel. Click its button (counter increments), type into the text field including a non-ASCII character, then click outside the panel (it dismisses). Previously human-attested as a first-attempt PASS during 11-01; this re-confirms it survived the Probe.qml CR-01 path change.
result: pass
note: "Checkpoint text as first presented said Super+K; user corrected it to Super+Shift+G. Verified against keybinds.conf:115 and shortcuts.json — probe is SUPER SHIFT + G, screencopy-probe is SUPER SHIFT + K. Test text corrected; the test itself passed."

### 3. FileView/JsonAdapter hand-edit propagation (QS-04)
expected: With the probe panel open, hand-edit ~/.local/state/quickshell/probe.json (change the label value) and save. The on-screen label updates to the new value with no restart and no reload.sh/theme-apply involvement. CR-01 changed this path from a hardcoded /home/aorus literal to Quickshell.env("HOME") — this confirms the file is still actually found.
result: pass
note: "Direct confirmation that CR-01's Quickshell.env(\"HOME\") replacement resolves to a real file — the failure mode was a silent fallback to the JsonAdapter default, not a crash, so this is the only check that could have caught a bad fix."

### 4. Suspend/resume survival (D-08)
expected: Note the quickshell PID, suspend the machine, wake it, then check the PID is unchanged and re-test click/type/dismiss on the probe. Reserved-space and GlobalShortcut registration both survive the cycle.
result: pass

### 5. Live multi-window ScreencopyView capture (criterion 5)
expected: Press Super+Shift+K to summon the screencopy probe with four windows open. The tiles render real, recognisable window content — not blank, black, or placeholder rectangles.
result: pass
note: "Confirms criterion 5's feasibility answer holds. Live enforcement of the screencopy permission remains Phase 16's OVER-04 requirement — this test proves the mechanism and the consumer path, not enforcement."

### 6. Backstop — XF86 duplicate-key handler determinism
expected: Deliberately register a second handler for an already-bound XF86Audio* key, then restart the session twice. The SAME handler fires every time — not a coin-flip. Never exercised in phase 11; flagged behavior_unverified in 11-VERIFICATION.md.
result: skipped
reason: "User answered 'skip' (no elaboration). The checkpoint offered the cost as the rationale: it requires deliberately breaking a working keybind config and restarting the session twice. REMAINS UNVERIFIED — this does not become a gap, but neither is it evidence of correct behaviour. Still carried as behavior_unverified in 11-VERIFICATION.md. Relevant to Phases 14 and 16, which each add a new global keybind."

### 7. Backstop — zero-output survival
expected: With every monitor disconnected, the quickshell process stays alive and re-creates its surfaces when an output returns. Deliberately untested in phase 11 — this host has one physical monitor and removing it kills the session.
result: skipped
reason: "User answered 'skip' — expected and correct. Physically untestable on this host: one physical monitor, and removing it kills the graphical session performing the test. Already disclosed as deliberately untested in 11-QUICKSHELL-EVIDENCE.md 'Findings and Caveats'. REMAINS UNVERIFIED. Testing it would need a nested compositor or headless session; worth revisiting in Phase 12 alongside the QS-03 per-screen fan-out work, which needs multi-output test infrastructure anyway."

### 8. install.sh + stow.sh register quickshell in one commit (QS-01)
expected: install.sh installs quickshell via one PACMAN_PKGS line and stow.sh deploys the quickshell/ package, both registered in commit 1aea012
result: pass
source: automated
coverage_id: D1
covered_by: "pacman -Qi quickshell (0.3.0-2, extra); git show --stat 1aea012"

### 9. quickshell-doctor is the seventh gate script and exits 0 (QS-05)
expected: quickshell-doctor follows house style, proves shell process alive, namespace discipline, reserved-space non-claim, keybind-doctor cleanliness
result: pass
source: automated
coverage_id: D1
covered_by: "quickshell-doctor full run 10 passed / 0 failed exit 0; mode 100755; shellcheck clean"

### 10. Single-owner event-source checks (QS-06)
expected: org.freedesktop.Notifications, 10 XF86 hardware keys, zero Quickshell MPRIS writers, one-step-per-press volume each retain a single owner
result: pass
source: automated
coverage_id: D2
covered_by: "quickshell-doctor checks 6-12"

### 11. QS-05/QS-06 results dated into the evidence artifact
expected: Results recorded in 11-QUICKSHELL-EVIDENCE.md with the two required corrections
result: pass
source: automated
coverage_id: D3
covered_by: "11-QUICKSHELL-EVIDENCE.md"

### 12. QML source hot-reload with no restart (QS-04)
expected: Editing a live QML property propagates with no restart and no theme-apply involvement; the revert propagates the same way
result: pass
source: automated
coverage_id: D2
covered_by: "hyprctl layers -j width/height diff across an implicitWidth edit, same PID throughout"

### 13. Second GlobalShortcut costs one manifest entry + one keybind line (QS-05)
expected: screencopy-probe added at D-17's predicted cost; keybind-doctor and quickshell-doctor both re-run clean against the two-entry manifest
result: pass
source: automated
coverage_id: D1
covered_by: "keybind-doctor 13 passed / 0 failed exit 0; hyprctl globalshortcuts lists both entries"

### 14. Screencopy permission mechanism verified against the binary (QS-05)
expected: Keyword syntax, type/mode strings and the restart-not-reload requirement verified directly against installed Hyprland 0.56.0
result: pass
source: automated
coverage_id: D3
covered_by: "direct binary verification, recorded in 11-QUICKSHELL-EVIDENCE.md"

### 15. Phase verdict written to evidence, ROADMAP and PROJECT (QS-02)
expected: Phase verdict (PASS) recorded, closing the Quickshell adoption decision
result: pass
source: automated
coverage_id: D4
covered_by: "11-QUICKSHELL-EVIDENCE.md, ROADMAP.md, PROJECT.md"

### 16. Per-screen surface fan-out across all connected monitors (QS-03)
expected: Quickshell surfaces render on every connected monitor including an output hotplugged after startup
result: skipped
reason: "Known, mechanically-verified gap — NOT a question for a human. Accepted for Phase 11 via the recorded override in 11-VERIFICATION.md frontmatter (overrides[0], accepted by YahiaEng 2026-07-26T12:07:57Z under D-10) and reassigned to Phase 12 as its success criterion 6. Deliberately not presented as a UAT checkpoint: it would re-collect a known failure and spawn a fix plan for work already owned by another phase."

## Summary

total: 16
passed: 13
issues: 0
pending: 0
skipped: 3

## Gaps

[none — zero issues reported]

## Unverified (carried forward, NOT gaps)

- test: 6
  truth: "XF86 duplicate-key handler resolution is deterministic across sessions"
  status: unverified
  reason: "Skipped — requires deliberately breaking a working keybind config and two session restarts"
  carried_as: "behavior_unverified in 11-VERIFICATION.md"
  relevant_to: "Phases 14 and 16 (each add a new global keybind)"

- test: 7
  truth: "quickshell survives zero connected outputs and remounts surfaces when one returns"
  status: unverified
  reason: "Physically untestable on this single-monitor host — removing the only output kills the session under test"
  carried_as: "behavior_unverified in 11-VERIFICATION.md"
  relevant_to: "Phase 12, which needs multi-output test infrastructure for QS-03 anyway"
