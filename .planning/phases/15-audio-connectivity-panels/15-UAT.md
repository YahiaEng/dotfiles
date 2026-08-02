---
status: complete
phase: 15-audio-connectivity-panels
source: [15-VERIFICATION.md, 15-09-SUMMARY.md, 15-10-SUMMARY.md, 15-11-SUMMARY.md, 15-12-SUMMARY.md, 15-13-SUMMARY.md, 15-14-SUMMARY.md]
started: 2026-08-02T03:30:00Z
updated: 2026-08-02T17:38:50Z
round: 2
note: |
  Round 1 recorded issues on tests 1, 2 and 4. All five resulting gaps
  (G-15-1, G-15-1b, G-15-2, G-15-4, G-15-4b) have been closed by executed
  gap-closure plans 15-10 through 15-14 and reconciled below. Those three
  tests are reset to [pending] for retest against the fixes; their round-1
  reports are preserved verbatim as `round1_reported`. Tests 5 and 6 are new
  checkpoints covering deliverables that did not exist in round 1.
  The running shell (PID 4179371, started 20:31:33) post-dates every QML
  edit in the round, so all fixes are live without a restart.
---

## Current Test

[testing complete]

## Tests

### 1. Wifi scan pace and Rescan feedback
expected: Scan progress line sweeps at a readable ~2000ms cycle. Pressing the refresh glyph gives immediate press feedback plus a persistent busy state (primary colour, animating, tooltip "Rescanning…") that clears when results land. Bluetooth's discovery line sweeps at the same corrected pace. The `reduced` motion preset must not be faster than `normal`.
how: `qs ipc call panel toggle wifi` or the Wi-Fi tile chevron. Watch the sweep, then press Rescan and watch the glyph.
closes_gap: G-15-1 (plan 15-11)
round1_reported: "Scan proggress line is moving too fast. Pressing on \"rescan\" needs to show feedback that the rescan action is underway."
result: pass

### 2. Bluetooth blocked-adapter state
expected: This host's bluetooth radio is rfkill soft-blocked. The panel renders a third empty state — heading "Bluetooth is blocked", body "A software block is holding the radio off" — with an Enable button at normal geometry but visibly dimmed. Hovering it shows "Run  rfkill unblock bluetooth  in a terminal to clear it" — the real reason, never a missing package. Pressing it does nothing at all, while hover still reaches the tooltip. Running `rfkill unblock bluetooth` externally makes the panel re-render into the ordinary off-state with a working Enable, with no restart.
how: `qs ipc call panel toggle bluetooth`. Hover the dimmed Enable, press it, then run `rfkill unblock bluetooth` in a terminal and watch the panel.
closes_gap: G-15-2 (plan 15-12)
round1_reported: "Clicking enable on bluetooth does nothing. If this is due to me missing required packages, then the bluetooth should show as disabled and label the reason when I hover on it."
scope_note: The device-list half of the original test 2 (pair / connect / disconnect / forget against a real peer) is NOT part of this checkpoint — it stays open in deferred-items.md behind a hardware blocker this repo cannot close.
result: pass

### 3. Wifi and bluetooth Advanced buttons
expected: nm-connection-editor and blueman-manager each open as a detached window that survives dismissing the panel.
result: pass

### 4. Wrong wifi password stays inside the panel
expected: A wrong passphrase produces NO external window at all — nm-applet's GTK secret dialog is gone, suppressed by a stowed autostart override. The failure renders as row-scoped copy inside the wifi panel naming a rejected passphrase, and the password row does NOT re-open as though nothing had been typed. A network that genuinely needs a passphrase you did not supply still reads "Password required" and still re-expands its row — the two cases stay distinguishable.
how: Expand a secured network, deliberately mistype the passphrase, press Connect, and watch for any window appearing behind the panel.
closes_gap: G-15-4 (plan 15-13)
round1_reported: "A wrong password opens up a different dialogue window which is rendered behind the wifi panel. This is not the behaviour I want, everything should be contained inside the wifi panel."
already_confirmed: Connect with a real password succeeds; Cancel visibly aborts an in-flight attempt; two-stage Escape works (first collapses the expanded row, second dismisses the panel). All three were confirmed in round 1 and are not being re-tested here — but flag it if plan 15-14's third Escape stage regressed either of the first two.
result: pass

### 5. Animated gradient border on all three panels
expected: Opening the audio, wifi or bluetooth panel shows the same animated gradient rim the dashboard drawer already has — same 3px thickness, tracing the same 28px bottom corners. It re-themes on a theme switch and stops rotating at the `off` motion scale, exactly as the drawer's rim does. The drawer's own rim must look unchanged.
how: `qs ipc call panel toggle audio`, then wifi, then bluetooth. Compare against the dashboard drawer (Super+D).
closes_gap: G-15-1b (plan 15-10)
round1_reported: "this is improtant for all panels not just wifi, they need to have the same animated colored border are the rest of dashboard."
result: pass

### 6. Join a hidden network
expected: The wifi panel offers a "Join a hidden network" entry point sitting between the network list and the zero-result line, at a fixed height so opening it never shifts the rows around it. Typing an SSID and pressing "Search" runs a directed probe; while probing, the button reads "Cancel". If the access point answers, it materialises as a normal row and the ENTIRE existing flow takes over unchanged — password field, Connect, pending pulse, Cancel, row-scoped failure copy. If it does not answer within 8 seconds, a form-scoped message says so. Escape gains a third stage (closing the form) without disturbing the two you confirmed in round 1.
how: Open the wifi panel, scroll to below the network list, press "Join a hidden network". Test with a real hidden SSID if you have one; otherwise type a nonsense SSID to confirm the not-found path and the Escape ordering.
closes_gap: G-15-4b (plan 15-14)
round1_reported: "Also, add an option to add a hidden wifi network (a network has it's SSID broadcast turned off)"
unproven: Route B (directed probe) was never proven against a real hidden AP — no hidden SSID on this host is known, and some APs do not answer directed probes. If it fails against a real hidden network, that is the documented Route A fallback trigger, not a regression.
result: issue
reported: "Fail. It cannot detect my hidden network. I have one that I can test on if needed"
severity: major
outcome: Route B (directed probe) did not reveal the user's real hidden AP — exactly the failure mode 15-14 documented as the Route A fallback trigger. The user has a real hidden network available for measurement, which makes the previously-unprovable step directly testable.

## Summary

total: 6
passed: 5
issues: 1
pending: 0
skipped: 0
blocked: 0

note: Round 2 confirmed all five round-1 gap closures. The single remaining issue
is test 6 — Route B's directed probe does not reveal the user's real hidden AP.
Separately, the device-list half of bluetooth (pair/connect/disconnect/forget)
remains unverified behind a hardware blocker tracked in deferred-items.md.

## Gaps

<!-- All round-1 gaps reconciled 2026-08-02 against executed gap-closure plans. -->
<!-- A resolved gap is not re-diagnosed; if the behaviour is still broken in round 2 -->
<!-- it is recorded as a fresh regression gap with a new gap_id. -->

- gap_id: G-15-1
  truth: "Rescan/scan progress communicates that a scan is underway at a readable pace"
  status: resolved
  resolved_by: 15-11-PLAN.md
  resolved_at: 2026-08-02
  severity: major
  test: 1
  debug_session: ".planning/debug/wifi-scan-progress-feedback.md"

- gap_id: G-15-1b
  truth: "Panels share the animated colored border used by the rest of the dashboard"
  status: resolved
  resolved_by: 15-10-PLAN.md
  resolved_at: 2026-08-02
  severity: major
  test: 5
  debug_session: ".planning/debug/panels-missing-animated-border.md"

- gap_id: G-15-2
  truth: "Clicking enable on the bluetooth panel powers the adapter on, or the control renders as disabled with a hover-legible reason"
  status: resolved
  resolved_by: 15-12-PLAN.md
  resolved_at: 2026-08-02
  severity: major
  test: 2
  residual: "The device-list half (pair/connect/disconnect/forget) remains unverified behind a hardware blocker — tracked in deferred-items.md, not in this gap."
  debug_session: ".planning/debug/bluetooth-enable-inert.md"

- gap_id: G-15-4
  truth: "A wrong wifi password renders row-scoped copy inside the wifi panel, with no external dialog"
  status: resolved
  resolved_by: 15-13-PLAN.md
  resolved_at: 2026-08-02
  severity: major
  test: 4
  debug_session: ".planning/debug/wifi-wrong-password-external-dialog.md"

- gap_id: G-15-4b
  truth: "The wifi panel offers a way to join a hidden network (SSID broadcast disabled)"
  status: resolved
  resolved_by: 15-14-PLAN.md
  resolved_at: 2026-08-02
  severity: minor
  test: 6
  note: "Resolved as SHIPPED — the entry point, form, handoff and Escape stage all exist. Its Route B mechanism failed in round-2 retest against a real hidden AP; that is tracked as the fresh gap G-15-6 below, not as a reopening of this one."
  debug_session: ".planning/debug/wifi-hidden-network-unsupported.md"

# ── Round 2 ──────────────────────────────────────────────────────────────────

- gap_id: G-15-6
  truth: "Typing a real hidden network's SSID into the panel's hidden-network form reveals it and hands off to the normal connect flow"
  status: failed
  reason: "User reported: Fail. It cannot detect my hidden network. I have one that I can test on if needed"
  severity: major
  test: 6
  supersedes_mechanism_of: G-15-4b
  prior_prediction: "15-14 shipped Route B (`nmcli device wifi rescan ssid <SSID>` → real Network object → existing flow) and explicitly recorded that it could NOT be proven, because no hidden SSID on this host was known and some APs do not answer directed probes. Route A was specified in advance as the documented fallback. This failure is that predicted branch being taken, not an unforeseen defect."
  measurement_now_possible: "The user has a real hidden network available to test against — the exact resource 15-14's Step Zero lacked. The blind spot that forced Route B to ship unproven is now closable by direct measurement."
  must_measure_before_fixing:
    - "Does `nmcli device wifi rescan ssid <SSID>` followed by `nmcli device wifi list` reveal the AP at all? This separates 'the AP does not answer directed probes' (Route B is dead, go Route A) from 'nmcli sees it but the panel's handoff never fires' (Route B is fine, the QML handoff is the bug)."
    - "If nmcli DOES reveal it: does the revealed AP appear in Quickshell's `wifiDevice.networks` with a non-blank SSID? Quickshell filters blank-SSID APs out entirely (15-14 measured 7 hidden APs in nmcli vs 0 in QML) — a revealed AP that stays blank-SSID to QML means the handoff can never find a receiver object regardless of probe success."
    - "Whether the panel's 8000ms probe watchdog is firing before the AP has time to materialise in QML's network list, which would produce this exact symptom even with a working probe."
  route_a_fallback_as_specified: "`nmcli device wifi connect <SSID> password <pw> hidden yes`, with the passphrase delivered via Process.stdinEnabled + write() against `nmcli --ask` so it never reaches argv (/proc/PID/cmdline is world-readable — Prohibition P3). Needs a new error mapping because nmcli returns exit codes + stderr rather than the ConnectionFailReason enum the panel's row-scoped copy is wired to."
  artifacts: []  # Filled by diagnosis
  missing: []    # Filled by diagnosis
