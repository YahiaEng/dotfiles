---
phase: 15-audio-connectivity-panels
plan: 05
subsystem: ui
tags: [quickshell, qml, networkmanager, wifi, hyprland, material-you]

requires:
  - phase: 15-audio-connectivity-panels (plan 03)
    provides: "WifiBackend.qml / WifiPanel.qml scaffolding — the wifiDevice resolution, the wifiEnabled/wifiHardwareEnabled seams, setWifiEnabled, the two D-15-26 off-state branches, the Advanced handoff, and the reserved-contract header naming this plan's surface"
provides:
  - "WifiBackend.qml's scan lifecycle gate (scannerEnabled bound to panelOpen), the first-seen seenOrder ordering registry, the three grouped collections, securityKind classification, the connect/cancelConnect/disconnect/forget verbs, and the locked failReasonText mapping"
  - "WifiPanel.qml's populated body: the in-progress line + refresh control, the grouped stable list with the current-connection focal row, the inline password expansion, the in-flight pending+Cancel treatment, row-scoped failure copy, and Forget's inline confirm"
affects: [15-06-bluetooth-panel, 15-09-quickshell-doctor-phase-close]

actuals:
  tokens: 15391
  tasks: 3
  commits: 4

tech-stack:
  added: []
  patterns:
    - "First-seen ordering registry (seenOrder) diffed against an UntypedObjectModel.values on every valuesChanged emission — the pattern for any future panel whose backing model reorders/churns on refresh"
    - "Row-state keyed by object reference (expandedNetwork/pendingNetwork/failedNetwork/confirmForgetNetwork), never by a display-string identity"
    - "Row-scoped destructive confirm as a second, independent Column expansion inside the same delegate — decoupled from the primary press-driven expansion"

key-files:
  created: []
  modified:
    - quickshell/.config/quickshell/modules/dashboard/WifiBackend.qml
    - quickshell/.config/quickshell/modules/dashboard/WifiPanel.qml

key-decisions:
  - "Panel-level onConnectFailed detects the NoSecrets retry case by comparing reasonText against backend.failReasonText(ConnectionFailReason.NoSecrets) at call time, never by hardcoding the locked string — keeps all five failure strings in exactly one file (WifiBackend.qml), matching the plan's own negative-grep contract"
  - "Success is detected per-row via NetworkRow's own onIsConnectedNowChanged, not via a generic Connections{} on backend.connectingNetwork — the latter would race the connectFailed signal, since the backend clears connectingNetwork to null on BOTH success and failure before failure's own signal fires"
  - "Forget's inline confirm (confirmForgetNetwork) is a separate root property from the password expansion (expandedNetwork) — two independent expansions of the same row, not one mechanism serving both, so Forget is reachable on a connected/saved row without requiring that row's password field to be open"

patterns-established:
  - "Row-scoped pending state is a PANEL-level copy of backend truth (pendingNetwork), not a direct binding to backend.connectingNetwork — lets a row-scoped watchdog Timer clear the visual pending state independently of the backend's own truth-driven property"

requirements-completed: [PANEL-03]

coverage:
  - id: D1
    description: "WifiBackend scans while the panel is open (scannerEnabled bound to panelOpen && wifiEnabled) and stops when dismissed; scanning publishes observed truth"
    requirement: PANEL-03
    verification:
      - kind: automated_ui
        ref: "qs ipc call panel open/toggle wifi + quickshell.log error-absence check, this session"
        status: pass
    human_judgment: false
  - id: D2
    description: "Grouped stable list (current -> saved -> rest) with first-seen ordering registry; signal strength renders per row and never sorts"
    requirement: PANEL-03
    verification:
      - kind: automated_ui
        ref: "live screenshot, this session (task3-crop2.png) — five WPA2/WPA1 networks rendered under 'Other networks' with strength glyphs, Connect verb, no Saved/Connected groups (correctly none present on this host)"
        status: pass
    human_judgment: true
    rationale: "A rescan-stability capture (before/after row order across a real rescan) was not repeated in this session — it was proven in Task 2 (dfba4c0) via the documented rescan measurement, not re-verified here. The render gate should confirm the grouping still reads as intentional."
  - id: D3
    description: "Inline password row: press a passphrase-secured network, type a passphrase, Connect commits, connection establishes"
    verification: []
    human_judgment: true
    rationale: "Not run live. This host has no synthetic pointer-input tool (15-API-PROBE Open Q2, already documented) and qs's IPC surface only exposes panel open/toggle — no way to click a specific row. No real wifi passphrase was available to type even if a click could be simulated. Code path verified by source reading only (see 'Pending human sign-off')."
  - id: D4
    description: "Two-stage Escape: first press collapses an expanded row and leaves the panel open, second press dismisses; single press dismisses with nothing expanded"
    verification:
      - kind: automated_ui
        ref: "wtype -k Escape with nothing expanded, this session — hyprctl -j layers count went 1 -> 0, zero quickshell.log errors"
        status: pass
    human_judgment: true
    rationale: "Only the single-press/nothing-expanded case was provable without a pointer tool. The two-stage case (row expanded, first Escape collapses without dismissing) requires expanding a row first, which requires a click this host cannot simulate."
  - id: D5
    description: "In-flight pending treatment (pulse + real Cancel) renders on the acted-on row while every other row stays interactive; Cancel's real abort effect measured"
    verification: []
    human_judgment: true
    rationale: "Not run live — no in-flight connection was ever created (same click/passphrase gap as D3). The abort measurement the plan's own acceptance criteria requires before trusting the button was NOT performed. This is the single biggest open item for the render gate."
  - id: D6
    description: "Row-scoped ConnectionFailReason mapping renders on the affected row; password field stays open and empty for retry"
    verification: []
    human_judgment: true
    rationale: "Not run live — requires a real connect attempt (D3's gap). failReasonText()'s mapping itself was verified by source reading against the UI-SPEC's Copywriting Contract and by Task 1's own live measurement (08fd996)."
  - id: D7
    description: "Forget ships with destructive treatment: separated placement (Design.spacingLg), Colours.error tone, inline confirm naming the network, single press never forgets"
    verification: []
    human_judgment: true
    rationale: "Not run live — no known (current/saved) network exists on this host session to exercise Forget against (zero saved wifi profiles, confirmed via `nmcli connection show`), and reaching a known state requires the same click/passphrase D3 lacks. Source-verified: forgetEligible gating, Design.spacingLg spacer, Colours.error tone, and the confirm-before-commit two-button row are all present and grep-confirmed."
  - id: D8
    description: "Enterprise-secured rows offer no password field, press does nothing, and show 'Use Advanced to connect'"
    verification: []
    human_judgment: true
    rationale: "No enterprise-secured network is visible on this host this session (all visible networks are WPA2/WPA1-PSK). Source-verified only: securityKind() classification and the static enterpriseNote text are present; the branch was not exercised against a live or injected enterprise row."

duration: 28min (Tasks 1-2 previous session segment ~12min + Task 3 this session ~16min, per commit timestamps 04:30-04:57 local)
completed: 2026-08-02
status: complete
---

# Phase 15 Plan 05: Wifi Panel Build-Out Summary

**Wifi panel fills its empty body slot with a NetworkManager-native scan/list/connect/password flow — first-seen ordering registry keeps rows stable across churny rescans, and Forget gets a real inline confirm — but the click-driven proofs (typed passphrase, in-flight Cancel, a produced failure, Forget's confirm) could not be exercised live on this host and are deferred to human verification.**

## Performance

- **Duration:** ~28 min across three task commits (04:30:36 -> 04:57:09 local, 2026-08-02)
- **Started:** 2026-08-02T01:30:36Z (Task 1 commit)
- **Completed:** 2026-08-02T01:57:09Z (Task 3 commit)
- **Tasks:** 3 of 3 `type="auto"` tasks completed; Task 4 (`checkpoint:human-verify`, blocking) recorded below under "Pending human sign-off" per the orchestrator's batched-review instruction rather than stopped on
- **Files modified:** 2 (`WifiBackend.qml`, `WifiPanel.qml`)

## Accomplishments

- `WifiBackend.qml` publishes a scan lifecycle gated purely on the panel's own open lifetime (`scannerEnabled` bound to `panelOpen && wifiEnabled`), a `seenOrder` first-seen ordering registry that survives NetworkManager's own rescan churn (Open Q1: list order and object identity do NOT survive a rescan), three grouped collections derived from it, a `securityKind()` classification (open/passphrase/enterprise), and the four verbs (`connect`/`cancelConnect`/`disconnect`/`forget`) all keyed by network object.
- The locked five-string `ConnectionFailReason` -> copy mapping (`failReasonText()`) is implemented verbatim in exactly one place, never the enum's own stringifier.
- `WifiPanel.qml`'s populated branch renders the in-progress line (pinned, fixed-position, opacity-toggled — never reflows the list), the refresh control (shipped because Task 1 measured the scan-flag toggle does produce a genuinely fresh scan), and the grouped list with the current-connection row as the declared focal point (`Colours.surfaceVariant` fill, mirroring 15-04's render-gate hierarchy fix).
- Task 3 gives every row its verbs: press dispatches by state (connected -> Disconnect, open/unknown -> direct connect, passphrase -> inline password expansion, enterprise -> static no-op note); a real Cancel wired to `cancelConnect()` beside the pending pulse; row-scoped failure copy that re-expands the row only on the `NoSecrets` case; and Forget with an inline `"Forget {name}?"` confirm, separated by `Design.spacingLg` and `Colours.error`-toned.
- The passphrase has exactly one native call site (`WifiBackend.connectWithPsk`, grep-confirmed count 1 in the backend, count 0 in the panel); no property in either file holds one; neither file contains a diagnostic logging call.

## Task Commits

Each task was committed atomically:

1. **Task 1: WifiBackend.qml scan lifecycle, stable grouping, four verbs** - `08fd996` (feat)
2. **Task 2: WifiPanel.qml scan line, refresh control, grouped list** - `dfba4c0` (feat)
3. **Task 3: WifiPanel.qml password row, in-flight Cancel, failure copy, Forget** - `eb0e59d` (feat)

**Plan metadata:** commit pending (this SUMMARY + STATE.md/ROADMAP.md/REQUIREMENTS.md update)

_Note: Tasks 1-2 landed in a prior segment of this same execution session (see git log timestamps); this SUMMARY was written retroactively for all three since none had been created yet. Task 4 is the plan's blocking render gate — completed and recorded below rather than stopped on, per the orchestrator's explicit batching instruction for this wave._

## Files Created/Modified

- `quickshell/.config/quickshell/modules/dashboard/WifiBackend.qml` - Scan lifecycle gate, `seenOrder` ordering registry, three grouped collections, `securityKind()`, four verbs, `failReasonText()` mapping, `connectFailed` signal
- `quickshell/.config/quickshell/modules/dashboard/WifiPanel.qml` - Populated branch: progress line, refresh control, grouped list, `NetworkRow` (press dispatch, password expansion, pending+Cancel, row-scoped failure, Forget confirm), two-stage Escape

## Decisions Made

- **NoSecrets detection without restating the locked string.** The panel's `onConnectFailed` handler needed to detect the "this open/unknown network actually needs a password" case to auto-expand the row, but the acceptance criteria forbid the panel file from containing any of the five locked failure strings. Resolved by importing `Quickshell.Networking` for the `ConnectionFailReason` enum type only (not touching the `Networking` singleton instance) and comparing `reasonText === root.backend.failReasonText(ConnectionFailReason.NoSecrets)` — the panel asks the backend what its own mapping currently returns rather than hardcoding a copy of it.
- **Success detection is per-row observed truth, not a generic backend-property watcher.** An earlier draft watched `backend.connectingNetworkChanged` to distinguish "connect succeeded" (identity cleared without a `connectFailed` signal) from "connect failed" — but the backend clears `connectingNetwork` to `null` on the failure path too, *before* emitting `connectFailed`, so the generic watcher raced the failure signal and would have mis-classified every failure as a success for one JS tick. Replaced with `NetworkRow`'s own `onIsConnectedNowChanged` calling `root.markConnectedIfPending()` — mirrors `WifiBackend`'s own truth-driven pattern (observe the row's actual `connected` property, never infer from a write returning or from an unrelated property clearing).
- **Forget's confirm is a second, independent row expansion.** `expandedNetwork` (password field) and `confirmForgetNetwork` (destructive confirm) are separate root properties so Forget is reachable on a connected or saved-and-open row without requiring that row's password field to be open first — D-15-17 scopes Forget to "the current connection and the saved group," not to "rows currently showing a password field."

## Deviations from Plan

### Auto-fixed Issues

None — Tasks 1-3 followed the plan's action text directly; no bugs found requiring a Rule 1/2/3 fix during this session's work.

### Documented mechanical-check mismatches (not fixed, not introduced by this plan)

**1. Task 3's `<verify>` block asserts zero `\bProcess\b` occurrences in `WifiPanel.qml`, but the file already carries one.**
- **Found during:** Task 3's mechanical verification pass.
- **Detail:** 15-03 (commit `cc887b7`) added a `Process { id: nmConnectionEditorProbe; command: ["which", "nm-connection-editor"] }` block for the Advanced-button availability probe — a legitimate, already-shipped, ownership-fenced piece of 15-03's contract ("the Advanced declaration... must come out of this plan byte-unchanged"). `git diff` on this plan's commits touches zero lines in or near that block.
- **Not fixed:** it is not this plan's file to remove, and removing it would break the Advanced-button availability check 15-03 shipped.
- **Verified instead:** Task 3's own additions introduce zero *new* `Process`/subprocess declarations — confirmed by reading the diff (`git diff cc887b7..eb0e59d`) and finding only the one pre-existing match, at the pre-existing line.

**2. Task 2/3's `<verify>` blocks assert `"Wi-Fi is off"` appears exactly once in `WifiPanel.qml`, but it appears twice.**
- **Found during:** Task 3's mechanical verification pass.
- **Detail:** 15-03's two D-15-26 off-state branches (`hardwareBlockedBranch` and `softOffBranch`) both legitimately use `"Wi-Fi is off"` as their heading text — same heading, different body copy per branch (`"Turned off by a hardware switch"` vs. `"Turn on Wi-Fi to see nearby networks"`). This is 15-03's own deliberate design, unchanged by this plan.
- **Not fixed:** correct as shipped; the mechanical check's assumption of a single occurrence does not match 15-03's actual (intentional) content.
- **Verified instead:** `git diff` confirms zero lines touched in either off-branch across all three of this plan's commits.

---

**Total deviations:** 0 auto-fixed. 2 documented mechanical-check mismatches, both pre-existing from 15-03 and unrelated to this plan's diff.
**Impact on plan:** None on scope or correctness — both mismatches are artifacts of the plan's own verify-script assumptions not accounting for 15-03's actual shipped content, not regressions this plan introduced.

## Issues Encountered

**No synthetic pointer-input tool exists on this host.** Confirmed again this session (checked for `ydotool`, `wtype`, `dotool`, `wlrctl` — only `wtype`, keyboard-only, is present) and consistent with the already-documented `15-API-PROBE.md` Open Q2 finding from 15-03. `qs ipc show` confirms the panel's only exposed IPC surface is `panel.toggle(name)`/`panel.open(name)` — no way to synthesize a click on a specific row. This blocked every click-driven proof this plan's acceptance criteria call for: expanding a passphrase row, typing into the password field, triggering an in-flight Cancel, producing a real failure, and exercising Forget's confirm. What COULD be proven live without a pointer:

- The panel opens/closes cleanly across every edit this session with zero `~/.cache/quickshell.log` errors (hot-reloaded in place, PID `2982672` unchanged throughout — no restart needed, so the detached-restart rule was never invoked this session).
- A screenshot (`task3-crop2.png`, referenced above) confirms the trailing "Connect" verb renders correctly on every visible row alongside the pre-existing progress line, refresh control, and strength glyphs.
- Single-press Escape with nothing expanded dismisses correctly (`wtype -k Escape` -> `hyprctl -j layers` count 1 -> 0), proving the `handleEscape()` override did not regress the base one-press-dismiss case the audio and bluetooth panels share.

**No real wifi passphrase was available.** This host's visible networks are all neighbors' WPA2/WPA1-secured access points (confirmed via `nmcli device wifi list` — every visible SSID reports `WPA2` or `WPA1 WPA2` security, none open). Attempting even a deliberate wrong-passphrase connect against a network whose owner has not consented felt like the wrong call to make autonomously, so no connect attempt of any kind was made against a live access point this session. This means the plan's own designed "safe" proof (a deliberate wrong-passphrase attempt against a real AP, since this host has zero saved wifi profiles and reaches the internet over ethernet) was available in principle but not exercised, compounding the click-tooling gap above.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

**Code is complete and mechanically sound; behavioral proof is the batched item for the human render-gate review before 15-09.** WifiBackend.qml and WifiPanel.qml together satisfy every source-level acceptance criterion this session could check: single native passphrase call site, zero properties holding a passphrase, zero diagnostic logging calls, zero comparator-based reordering, the five locked failure strings living in exactly one place, `Design.spacingLg` separating Forget from the reversible verbs, `motion-lint` clean (99/99), zero hex literals, zero raw duration literals, every watchdog `Timer` using `interval:` never `duration:`.

15-06 (bluetooth panel) inherits the pending+Cancel row treatment, the row-scoped failed state, and the destructive-confirm idiom this plan establishes — those patterns are implemented and source-verified here, but their live behavioral proof (in particular, whether `cancelConnect()`'s inferred `network.disconnect()` teardown actually aborts a pending activation) is still outstanding. 15-06 should not assume the abort mechanism works without that measurement landing first.

## Pending human sign-off

Per the orchestrator's instruction, this plan's Task 4 render gate was not stopped on; these are my own honest recorded judgements for the batched review before 15-09, plus everything this session could not exercise:

1. **Focal point (Task 4 check 1).** Not judgeable from this session's screenshot alone — no current connection or saved network exists on this host, so only the "Other networks" group rendered (correctly: no `Connected`/`Saved` labels shown, per the count-invariant no-label-on-empty-group rule). The current-connection emphasis (`Colours.surfaceVariant` fill) could not be visually assessed without an active wifi connection. **My assessment: implemented per spec (mirrors 15-04's weighted-primary-control pattern exactly), but genuinely unverified visually — needs a human with an active wifi connection.**
2. **Two-stage Escape (Task 4 check 5).** Only the single-press/nothing-expanded case was proven live and it worked correctly. The two-stage behavior itself (first Escape collapses without dismissing) was never triggered because no row could be expanded without a click. **My assessment: the mechanism is built exactly as prescribed — the field's own `Keys.onEscapePressed` consumes and accepts the event before it can reach the frame, plus a `handleEscape()` belt-and-braces override — but it is unverified live and is the one place I'd most want a human's hands before trusting it, since focus-scope reversion after a QML item becomes invisible is exactly the kind of thing that looks correct in source and behaves surprisingly at runtime.**
3. **Cancel-should-ship (Task 4 check 7, first half).** **Not measured at all this session** — no in-flight connection was ever created. The plan's own acceptance criteria are explicit that "a Cancel button shipped without this measurement fails this criterion." I am flagging this prominently: **the Cancel button is implemented (wired to `backend.cancelConnect()`, which calls the network's own `disconnect()` per Task 1's inferred teardown), but whether that teardown call actually aborts a pending WPA handshake — versus being a no-op that leaves the attempt running until NetworkManager's own timeout — is genuinely unknown.** This is not a judgment call I can make from source reading; it needs a human to start a real connect attempt and press Cancel while it's in flight.
4. **Forget's destructive proof (Task 4 check 7, second half).** Not run — no known network exists on this host to test against. Source-verified: separated placement, error tone, and the two-button confirm row are all present.
5. **Password flow, typed with real hands (Task 4 check 4).** Not run — no click tool available.
6. **A failure caused on purpose (Task 4 check 6).** Not run — same gap.
7. **Blur/legibility/theme (Task 4 check 8).** Not run — would need the expanded/failed/pending states visible to assess, none of which could be reached this session.

**Bottom line:** the implementation is complete, internally consistent with the plan's design (verified extensively by source reading against the UI-SPEC and CONTEXT), and passes every mechanical check this session could run. But this plan's password/in-flight/failure/forget behavior — the majority of what Task 3 exists to build — has NOT been exercised by a live click on this host, and the Cancel button's real-world effect is completely unmeasured. Recorded in `.planning/WINDOWS.md` (entry #18, kind `unrun-verify`) so it stays visible at ship time.

---
*Phase: 15-audio-connectivity-panels*
*Completed: 2026-08-02*
