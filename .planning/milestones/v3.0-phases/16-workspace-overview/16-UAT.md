---
status: complete
phase: 16-workspace-overview
source: [16-01-SUMMARY.md, 16-02-SUMMARY.md, 16-03-SUMMARY.md, 16-04-SUMMARY.md, 16-05-SUMMARY.md, 16-06-SUMMARY.md, 16-07-SUMMARY.md, 16-08-SUMMARY.md]
started: 2026-08-10T13:05:00Z
updated: 2026-08-10T13:40:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Clicking a tile's empty area focuses that workspace and dismisses the overview in the same gesture
expected: Clicking a tile's empty area focuses that workspace and dismisses the overview in the same gesture
result: pass
source: automated
coverage_id: 16-02/D3

### 2. overview IPC status verb reports live tile/window/withContent counts; doctor gates pass
expected: overview IPC status verb (toggle/status) reports live tile/window/withContent counts; keybind-doctor and quickshell-doctor coexistence gates pass with the new chord and namespace
result: pass
source: automated
coverage_id: 16-02/D4

### 3. Summon and dismiss the overview
expected: |
  Press Super+O on the focused monitor. A full-screen overview layer surface appears.
  Press Super+O again — it closes. Reopen, press Esc — it closes. Reopen, click
  outside the tile block — it closes. Every dismissal path actually destroys the
  surface (no ghost layer, desktop fully interactive again).
context: 16-02/D1 (OVER-01). Prior evidence — Task 3 render gate, operator-approved round 2; reserved-array summon-and-diff via hyprctl layers/monitors passed.
result: pass

### 4. Every window renders as its own live thumbnail
expected: |
  With 3+ real windows open on the focused workspace, each one shows as its own
  live ScreencopyView thumbnail — genuinely live (not frozen or grey), correctly
  scaled to its real hyprctl geometry, non-overlapping and visually distinct.
context: 16-02/D2 (OVER-01). This is the defect class that shipped two false passes before the real fix — human eyes are the only check that has ever caught it.
result: pass

### 5. Ten fixed numbered tiles, pixel-stable across summons
expected: |
  Every summon shows ten numbered tiles in a 5-column x 2-row block mirroring the
  number row, present regardless of occupancy. Press Super+O several times in a
  row — the tiles sit at the same screen positions every time, no drift or reflow.
context: 16-03/D1 (OVER-01). Position stability is the load-bearing assumption under 16-06's drag-and-drop drop targets; a single IPC snapshot can't prove stability across time.
result: pass

### 6. Real geometry recognisable by shape alone
expected: |
  Each window thumbnail sits at its real scaled position and size — you can
  recognise which window is which from its shape and placement alone, without
  reading titles.
context: 16-03/D2 (OVER-01). Rendered through the extracted WindowThumbnail.qml type.
result: pass

### 7. Scratchpad tile always present and distinct
expected: |
  An eleventh tile sits in a permanently reserved position beneath the 5x2 block,
  visibly smaller and differently outlined. It is present on every summon whether
  or not it holds windows. Send a window to it with Super+Shift+S — it appears
  there; pull it back with Super+S — the tile remains (now empty), not missing.
context: 16-03/D3 (OVER-01). Should read as "distinct, intentional", not "broken/missing".
result: pass

### 8. Entrance cascades in three bands
expected: |
  On summon the entrance animates in three quick, distinct steps — row 1, then
  row 2, then the scratchpad — not a per-tile ripple and not an all-at-once pop.
context: 16-03/D4 (OVER-01). Logs confirm bands=3 ran; whether the timing *reads* as three quick steps is a felt-timing judgment.
result: pass

### 9. quickshell-doctor gains seven new checks with poisoned fixtures
expected: quickshell-doctor gains seven new checks (overview-namespace-conformance, overview-shortcut-single-registration, reserved-array-manifest-coverage, permissions-enforce-readback, permissions-allowlist-paths-resolve, overview-content-check, single-capture-path), each with a committed poisoned fixture proven to FAIL and a clean counterpart proven to PASS via --self-test
result: pass
source: automated
coverage_id: 16-04/D1

### 10. permissions.lua ships with enforce_permissions = true and a recovery procedure
expected: permissions.lua ships with enforce_permissions = true, no grant added or removed, no grant broadened to a pattern, recovery procedure written into the file's own header, hyprctl configerrors clean
result: pass
source: automated
coverage_id: 16-04/D2

### 11. Live permission enforcement across all five screencopy paths
expected: |
  After a real session restart (log out and back in), all five screencopy consumer
  paths work under enforcement: overview thumbnails render, screenshots capture,
  the colour picker samples, browser screen-share works, screen recording works.
  No permission dialog blocks any of them.
context: 16-04/D3. DEFERRED by explicit operator decision during execution — the executor's terminal is a child of the compositor, so it could not perform the restart. Full run-cold procedure is in deferred-items.md item 0. Answer "blocked" or "skip" if you have not restarted the session since.
result: pass
note: Operator confirmed live at UAT — closes the deferral recorded as deferred-items.md item 0.

### 12. Pending capture state
expected: A window whose capture has not yet produced a frame renders a pending state (primary-tinted loading glyph, pulsing on ambient duration/easing) and clears itself the moment the first frame lands
result: pass
source: automated
coverage_id: 16-05/D1

### 13. Failed capture state
expected: A window whose capture is still empty past a timeout renders a failed state — icon, the window's real title from Hyprland IPC, one honest non-diagnostic line — reusing the panel family's four-state vocabulary
result: pass
source: automated
coverage_id: 16-05/D2

### 14. Whole-grid empty message
expected: When no window anywhere in the grid produces content, one surface-level message is shown instead of the same failure repeated on every tile — never while any capture is still pending, bounded by a ceiling
result: pass
source: automated
coverage_id: 16-05/D3

### 15. Mixed captured/denied windows use per-window treatment only
expected: A mix of captured and denied windows uses per-window treatment only — the whole-grid catch fires solely when zero windows anywhere capture
result: pass
source: automated
coverage_id: 16-05/D4

### 16. Clicking a thumbnail focuses that window and closes
expected: |
  Click directly on a window thumbnail: that window and its workspace are focused
  and the overview closes. Click a tile's empty area instead: the workspace is
  focused and the overview closes. The mouse never does strictly less than the
  keyboard.
context: 16-05/D5 (OVER-02). NOT reproduced by the executor — no pointer-simulation tool exists on this host (ydotool/wlrctl/dotool all absent, only wtype). Verified structurally only; this is the first actual click test.
result: pass
note: Closes the executor-cannot-reproduce flag on 16-05/D5 — OVER-02's pointer path is now human-confirmed.

### 17. No client-controlled text reaches the compositor's Lua evaluator
expected: No client-controlled text ever reaches the compositor's Lua evaluator (T-16-25); the address is shape-checked at dispatch time
result: pass
source: automated
coverage_id: 16-06/D5

### 18. Drag a thumbnail to another workspace tile
expected: |
  Drag a window thumbnail onto a different workspace tile and drop it. The window
  moves to that workspace, silently — the overview stays open and your focused
  workspace does not change.
context: 16-06/D1 (OVER-03). Performed by the operator at the Task 3 render gate; no synthetic pointer tool exists on this host.
result: pass

### 19. Drop target highlights during drag
expected: |
  While a drag is in flight, exactly one drop target tile is visibly highlighted
  at a time, using the same lit-tile idiom used elsewhere — it follows the cursor
  from tile to tile without two lighting up at once.
context: 16-06/D2 (OVER-03).
result: pass

### 20. Missed drop cancels cleanly; same-tile drop is a no-op
expected: |
  Drop a thumbnail outside any tile — the snapshot animates back home at zero
  cost, nothing moves. Drop a thumbnail back onto its own tile — clean no-op,
  no window movement, no flicker.
context: 16-06/D3 (OVER-03).
result: pass

### 21. Drag works symmetrically into and out of the scratchpad
expected: |
  Drag a window into the scratchpad tile — it goes there. Drag it back out to a
  numbered tile — it comes back. The scratchpad behaves as an ordinary member of
  the workspace-target set, no special case.
context: 16-06/D4 (OVER-03, D-16-05).
result: pass

### 22. Arrow-key selection across all eleven tiles
expected: Arrow keys move a selection across all eleven tiles with no pointer click first, with edge-stop at both ends
result: pass
source: automated
coverage_id: 16-07/D1

### 23. Enter descends into a tile's windows
expected: Enter descends into a tile's windows and focuses one; Enter on an empty workspace focuses it and closes
result: pass
source: automated
coverage_id: 16-07/D2

### 24. Shift+1..0 moves the window-level selection
expected: Shift+1..0 moves the window-level selection through 16-06's guarded dispatch, overview stays open
result: pass
source: automated
coverage_id: 16-07/D3

### 25. Two-stage Esc
expected: Two-stage Esc — first press leaves window level, second dismisses
result: pass
source: automated
coverage_id: 16-07/D4

### 26. No type-to-search input anywhere in the overview
expected: No TextInput/TextField/TextEdit anywhere in the overview module tree
result: pass
source: automated
coverage_id: 16-07/D5

### 27. Visual design of the finished surface
expected: |
  The overview reads as floating frosted glass over an untouched desktop, not as
  an application window. The sweep ring picks up the current theme's colours, and
  the slot numbers are readable against the tiles.
context: 16-07/D6. Screenshot-verified across render-gate rounds 5-13; standing constraint 1 requires human render-and-look sign-off on every visual surface.
result: pass

### 28. Three-condition performance measurement with raw samples
expected: Three-condition performance measurement plus a closed-overview baseline, under the budget's own load floor, with raw samples preserved
result: pass
source: automated
coverage_id: 16-08/D1

### 29. Named OVER-04 verdict with ladder rung reached
expected: A named OVER-04 verdict with the ladder rung reached, and no code changed on a passing measurement
result: pass
source: automated
coverage_id: 16-08/D2

### 30. Ordinary-use pass over the finished surface
expected: |
  Having used the overview in ordinary work (not just a scripted test), it holds
  up: nothing about it feels wrong, slow, or surprising in day-to-day use, and
  the running use note in 16-USE-NOTE.md reflects that.
context: 16-08/D3. The 2026-08-08 use-note entry was approved with no defects reported; criterion 5 asks for observations from real use.
result: pass

## Summary

total: 30
passed: 30
issues: 0
pending: 0
skipped: 0
blocked: 0

human_reviewed: 14
auto_covered: 16

## Gaps

[none — all 30 deliverables resolved, 0 issues reported]

## Notes

Two previously-open executor limitations were closed by this session's live
operator confirmation:

- **16-04/D3** — live permission enforcement across all five screencopy consumer
  paths after a real session restart. Deferred during execution (the executor's
  terminal is a child of the compositor); recorded as `deferred-items.md` item 0.
  Operator confirmed live at UAT. The deferral can be struck.
- **16-05/D5 (OVER-02)** — pointer click on a window thumbnail focusing that
  window and dismissing. Never reproduced by the executor (no pointer-simulation
  tool on this host — ydotool/wlrctl/dotool all absent, only wtype). Verified
  structurally at execution time; now human-confirmed end to end.

Coverage-block defects found while classifying (bookkeeping only — no deliverable
was dropped; all affected entries were presented as human checkpoints):

- `16-05-SUMMARY.md` D5 — `verification[1].status: not_run` is not a valid status
  (must be one of pass/fail/unknown).
- `16-06-SUMMARY.md` D2, D3, D4 — `rationale` is required when
  `human_judgment: true` and is absent.
