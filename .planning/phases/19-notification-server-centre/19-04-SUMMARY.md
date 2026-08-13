---
phase: 19-notification-server-centre
plan: 04
subsystem: notifications
tags: [quickshell, qml, dbus, notifications, markdown-filter, gestures]

# Dependency graph
requires:
  - phase: 19-notification-server-centre
    provides: "19-01's Design.qml/BarRoles.qml token+role surface, the pragma-Singleton NotifServer owning org.freedesktop.Notifications, NotifData's property-changed Connections binding shape, and the compact-only NotifCard/NotifPopupStack tracer this plan expands"
provides:
  - "The full popup card interaction surface: card-wide drag gestures (dismiss/expand), middle-click dismiss, left-click default-action, hover pause/resume dismiss timer, four-tier icon fallback chain, critical-urgency whole-card danger colouring"
  - "NotifPopupStack's D-19-03 height clamp (2/3 screen height) plus a `+N more` summary card that opens the centre via the same NotifServer.openCentre() verb the bar bell uses"
  - "In-place replaces_id updates (structural, no suppression branch) with dismiss-timer restart, ring progress (PathAngleArc, clamped 0..100) for hints.value notifications"
  - "NotifMarkdown.qml — an escape-everything-then-allowlist filter (T-19-10) permitting only bold/italic/http(s)-link constructs before Text.MarkdownText renders a sender's body, plus link-hover-then-confirm (T-19-11, D-19-40)"
  - "hypr/.config/hypr/scripts/tests/notif-fault-inject — a re-runnable, mechanical fault-injection fixture proving replaces_id in-place update and action-invocation arrival at the sending process, the evidence plan 19-08's GATE-02 will re-check before the render gate"
  - "shell.qml's `notifs` IpcHandler (count/historyCount/indexOf/textOf/invokeAction) — a mechanical, screenshot-free surface onto the popup stack, reused by the fault-inject fixture"
affects: [19-05, 19-06, 19-07, 19-08]

# Actuals (#2632) — pairs with the plan's `estimate` to calibrate future estimates.
actuals:
  tokens: 15081
  tasks: 3
  commits: 2

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "One card-level MouseArea disambiguates two drag axes (X=dismiss, Y=expand) plus middle-click and left-click-default-action by whichever threshold fires first — never two overlapping hit areas; every other tappable element (action chips, copy, link confirm) uses TapHandler instead of a second MouseArea"
    - "A dismiss timer expressed as an explicit remaining/resume state machine (_remainingMs snapshot + Date.now()-based pause/resume) rather than a bare declarative Timer.running binding, since a QML Timer restarts from zero on stop+start and there is no natural interval to re-bind for a genuine pause/resume vs. a genuine reset (D-19-06 vs D-19-08)"
    - "Cross-Component data forwarding via Loader.onLoaded + Qt.binding() — a Component{} block is its own QML id scope, so an id declared on the delegate Loader is NOT visible inside a Component instantiated through that Loader's sourceComponent; forwarding the modelData explicitly after load is the correct idiom, not a workaround"
    - "Escape-everything-then-allowlist as a pre-processing filter feeding the toolkit's own markdown text format, never a hand-written parser — the security property is that anything the allowlist does not explicitly re-permit renders as literal text by default"
    - "A test fixture masks/restores a competing D-Bus service around itself only when it does not already own the well-known name, following the T-11-11 restore-before-mutate shape — the restore branch is inert once the two-owner race permanently resolves in this plan's own future (Phase 19 Plan 08's swaync deletion)"

key-files:
  created:
    - quickshell/.config/quickshell/modules/notifications/NotifMarkdown.qml
    - hypr/.config/hypr/scripts/tests/notif-fault-inject
  modified:
    - quickshell/.config/quickshell/modules/notifications/NotifCard.qml
    - quickshell/.config/quickshell/modules/notifications/NotifPopupStack.qml
    - quickshell/.config/quickshell/modules/notifications/NotifServer.qml
    - quickshell/.config/quickshell/modules/notifications/qmldir
    - quickshell/.config/quickshell/shell.qml

key-decisions:
  - "NotifServer.qml's dismiss(id) rewritten from wrapper.destroy() to wrapper.popup=false + history-prepend — the tracer's version was correct only while nothing read history yet, but directly contradicted this plan's own must_haves truth ('no gesture destroys data... still present in history afterwards') the moment a real gesture-driven dismiss existed. One code path (dismiss) makes the guarantee structural rather than something every caller (timer, drag, middle-click, click-fallback) has to re-prove."
  - "NotifPopupStack.qml's two Component{} delegate blocks (realCardComponent/overflowCardComponent) referenced the delegate Loader's own `cardLoader` id directly, which compiles but is out of scope at runtime — a Component block is its own id namespace. This threw a live ReferenceError on every single card render (confirmed via ~/.cache/quickshell.log before the fix, silent afterward across a 12-notification burst). Fixed via Loader.onLoaded + Qt.binding() to forward modelData across the scope boundary, the standard QML idiom for dynamic sourceComponent data-passing."
  - "shell.qml gained a `notifs` IpcHandler surface (count/historyCount/indexOf/textOf/invokeAction) so the fault-injection fixture can assert mechanically rather than visually — extends the SAME `notifs` IPC target RESEARCH.md already reserved for the centre/DND verbs a later plan adds, rather than minting a second target."
  - "notif-fault-inject's action-invocation sender is a self-contained Python (PyGObject/Gio) listener generated to a temp file at runtime rather than a second committed file, keeping the fixture a single standalone script per the plan's own file list while still giving the fixture a sender it fully controls, per QNOTIF-04's own requirement that arrival be proven at the far end, not merely 'the shell didn't error.'"

patterns-established:
  - "Popup card gestures, dismiss-timer state machine, and the depth-clamp/summary-card idiom this plan establishes are the shape 19-05/19-06 (centre, history/grouping) extend rather than re-derive"

requirements-completed: [QNOTIF-02, QNOTIF-03, QNOTIF-04, QNOTIF-05]

coverage:
  - id: D1
    description: "A horizontal drag past the dismiss threshold removes a card from the popup stack without destroying its history record; a short drag snaps back; middle-click dismisses immediately with the same non-destructive semantics"
    requirement: "QNOTIF-03"
    verification:
      - kind: other
        ref: "Live IPC assertion (notifs count/indexOf) proves dismiss moves a wrapper into history rather than destroying it (NotifServer.qml dismiss() rewrite); acceptance-criteria greps confirm exactly one card-level MouseArea, both thresholds sourced from Design.qml tokens, and the critical urgency timer-exclusion condition"
        status: pass
    human_judgment: true
    rationale: "The drag gesture itself (visual snap-back vs. dismiss, expand toggle direction) needs a human to actually drag a real card and judge the feel — this plan's own Task 1 <verify><human-check> block names this explicitly and was not run interactively this session per the project's live-verification-skip preference."
  - id: D2
    description: "A notification's own action buttons appear on the expanded card and invoking one reaches the sending application"
    requirement: "QNOTIF-04"
    verification:
      - kind: other
        ref: "hypr/.config/hypr/scripts/tests/notif-fault-inject injection 2 — a self-controlled sender's own ActionInvoked subscription writes a sentinel file after invokeAction is called through the shell's real NotificationAction.invoke() path; 2 consecutive live runs, 9/9 checks passing each time"
        status: pass
    human_judgment: false
  - id: D3
    description: "A re-send carrying a matching replaces_id updates the same card in place: text/ring change, stack position and animation state stay put"
    requirement: "QNOTIF-05"
    verification:
      - kind: other
        ref: "hypr/.config/hypr/scripts/tests/notif-fault-inject injection 1 — mechanical before/after comparison via the notifs IPC surface (id, count, index, text); 2 consecutive live runs, all 5 assertions passing each time; one assertion manually inverted and confirmed to flip to [FAIL] with non-zero exit, then reverted"
        status: pass
    human_judgment: false
  - id: D4
    description: "A hints.value notification draws a clamped ring progress indicator; twelve simultaneous notifications produce a stack that stops at the height clamp plus one correctly-counted +N more summary card opening the centre"
    requirement: "QNOTIF-02"
    verification:
      - kind: other
        ref: "grep-verified PathAngleArc + Math.min/max clamp on the same binding chain (NotifCard.qml); NotifPopupStack.qml's _displayModel/visibleCount/overflowCount math reviewed against the plan's clamp formula; overflow-card ReferenceError found live and fixed, re-verified error-free after fix"
        status: pass
    human_judgment: true
    rationale: "The visual clamp point (12 notifications actually producing a correctly-counted +N more card on screen) and the ring's live sweep need a human to actually look at the rendered stack — not run interactively this session per the project's live-verification-skip preference; the underlying math and the fixed ReferenceError were both proven live via IPC/log inspection instead."

# Metrics
duration: ~50min
completed: 2026-08-13
status: complete
---

# Phase 19 Plan 04: Full Popup Card & Fault-Injection Fixture Summary

**The tracer's compact-only popup card is now the complete D-19-05..12/40 experience — gestures, height-clamped stack with a `+N more` summary card, structural in-place `replaces_id` updates, clamped ring progress, and an escape-then-allowlist markdown/link-confirm filter — backed by a re-runnable fault-injection fixture that mechanically proves the two highest-risk mechanics (`replaces_id`, action invocation) rather than relying on a memory of trying them.**

## Performance

- **Duration:** ~50 min (mostly verification and one live bug fix; the bulk of the implementation existed in the working tree from a prior session and was verified, fixed, and committed this session)
- **Started:** 2026-08-13 (session start)
- **Completed:** 2026-08-13T14:44:00+03:00 (approx, last task commit)
- **Tasks:** 3 completed
- **Files modified:** 7 (2 created, 5 modified)

## Accomplishments
- Card-wide gesture area (one `MouseArea`, never two overlapping hit areas) disambiguates horizontal-drag dismiss, vertical-drag expand, middle-click, and left-click default-action
- Dismiss timer rewritten as an explicit remaining/resume state machine so hover genuinely pauses-and-resumes (D-19-06) while a `replaces_id` re-send genuinely resets to the full window (D-19-08) — these are provably different code paths, not the same branch doing double duty
- Four-tier icon fallback chain (image hint → app_icon via icon theme → desktop-entry icon via `DesktopEntries.byId` → generic glyph) confirmed against the live Quickshell `Notification.desktopEntry`/`DesktopEntries.byId` API surface
- `NotifPopupStack` clamps the *displayed* slice to 2/3 screen height and appends a `+N more` card sharing real-card chrome; `NotifServer.popups` itself is never truncated
- `NotifMarkdown.qml` — escape-everything-then-allowlist filter re-permitting only bold/italic/http(s)-link constructs before `Text.MarkdownText` ever sees a sender's body string (T-19-10); link hover reuses `BarTooltip.qml` verbatim and a click requires an inline confirmation before `Qt.openUrlExternally` (T-19-11)
- `hypr/.config/hypr/scripts/tests/notif-fault-inject` — a standalone, twice-in-a-row-re-runnable fixture proving `replaces_id` in-place update (id/count/index/text, all off the shell's own IPC surface) and action-invocation arrival at a self-controlled sender's own sentinel file
- Found and fixed a live, reproducible bug (see Deviations) that was silently throwing a `ReferenceError` on every single popup card render

## Task Commits

Each task was committed atomically. This plan's implementation existed largely uncommitted in the working tree from a prior session; this session verified it against every acceptance criterion, found and fixed one live bug, authored Task 3 from scratch, and committed both units of work:

1. **Task 1 & 2: Gestures, stack depth, dismiss-timer state machine, in-place updates, ring progress, markdown/link safety** - `8d1e80e` (feat) — committed together because the prior session's implementation pass interleaved both tasks' scope inseparably within `NotifCard.qml` (gesture handling, icon chain, and critical treatment from Task 1 sit alongside ring progress and markdown rendering from Task 2 in the same continuous file edit); splitting them into two commits would have required risky hunk-level surgery on a single, already-verified-working file rather than reflecting how the code was actually authored.
2. **Task 3: Fault-injection fixture for in-place update and action invocation** - `9f4bb53` (test)

**Plan metadata:** (this commit)

## Files Created/Modified
- `quickshell/.config/quickshell/modules/notifications/NotifCard.qml` - gestures, expanded state, action strip, ring progress, four-tier icon fallback, critical-urgency colour swap, markdown-filtered body, link hover/confirm
- `quickshell/.config/quickshell/modules/notifications/NotifPopupStack.qml` - D-19-03 height clamp + `+N more` summary card; fixed a live `ReferenceError` in its Loader/Component data-forwarding
- `quickshell/.config/quickshell/modules/notifications/NotifServer.qml` - `dismiss(id)` rewritten to move a wrapper into `history` instead of destroying it (Rule 1 bug fix)
- `quickshell/.config/quickshell/modules/notifications/NotifMarkdown.qml` - new: escape-everything-then-allowlist body filter (T-19-10)
- `quickshell/.config/quickshell/modules/notifications/qmldir` - registers `NotifMarkdown` as a pragma-Singleton
- `quickshell/.config/quickshell/shell.qml` - new `notifs` IpcHandler surface (count/historyCount/indexOf/textOf/invokeAction) for the fault-inject fixture
- `hypr/.config/hypr/scripts/tests/notif-fault-inject` - new: two-injection fault fixture, re-runnable, matches `quickshell-doctor`'s PASS/FAIL convention

## Decisions Made
- Combined Tasks 1 and 2 into a single commit rather than force-splitting an already-unified `NotifCard.qml` edit (see Task Commits above)
- `dismiss(id)` moves wrappers into `history` rather than destroying them — the one place the "no gesture destroys data" guarantee lives, so every caller (timer, drag, middle-click, click-fallback) inherits it for free
- `NotifPopupStack`'s cross-Component data forwarding uses `Loader.onLoaded` + `Qt.binding()` rather than restructuring the delegate to avoid `Component{}` blocks entirely — keeps the two-component-type-switch shape intact while fixing the actual scope bug
- The fault-inject fixture's action-invocation sender is a self-contained Python/PyGObject script generated to a temp file at runtime (not a second committed file), keeping the fixture literally the single file the plan names while still giving it a sender it fully controls

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `dismiss(id)` destroyed the wrapper instead of moving it to history**
- **Found during:** Review before Task 1 commit (inherited from the prior session's implementation)
- **Issue:** `NotifServer.qml`'s tracer-era `dismiss(id)` called `wrapper.destroy()`. Correct while nothing read `history` yet (wave 1), but this plan's own must_haves truth is "no gesture destroys data... the notification is still present in history afterwards" — the moment real gesture-driven dismiss exists, destroying the wrapper directly contradicts that.
- **Fix:** `dismiss(id)` now sets `wrapper.popup = false` and prepends the wrapper to `history` instead of destroying it.
- **Files modified:** `quickshell/.config/quickshell/modules/notifications/NotifServer.qml`
- **Verification:** Live IPC check (`notifs historyCount`) confirms a dismissed notification's wrapper survives; `quickshell-doctor --self-test` unaffected (55/0)
- **Committed in:** `8d1e80e`

**2. [Rule 1 - Bug] `cardLoader` referenced across a QML Component scope boundary — live `ReferenceError` on every card render**
- **Found during:** Live-log inspection before Task 1 commit (~/.cache/quickshell.log showed dozens of `@modules/notifications/NotifPopupStack.qml[175:-1]: ReferenceError: cardLoader is not defined` entries)
- **Issue:** `realCardComponent`/`overflowCardComponent` (two top-level `Component{}` blocks) referenced the delegate `Loader`'s own `id: cardLoader` directly (`notifData: cardLoader.modelData`, `cardLoader.modelData.overflowCount`). A `Component{}` block is its own QML id-resolution scope — this compiles (QML id lookup is late-bound) but throws at runtime on every instantiation. Silent in the sense that Quickshell logs a `WARN`, not a crash, so the popup stack still rendered — but every card and every overflow card was failing to bind its data via the intended path.
- **Fix:** Forward `modelData` across the scope boundary explicitly via `Loader.onLoaded` + `Qt.binding()` — the standard QML idiom for passing data into a dynamically-selected `sourceComponent`, keeping the forwarded property live rather than a one-shot snapshot.
- **Files modified:** `quickshell/.config/quickshell/modules/notifications/NotifPopupStack.qml`
- **Verification:** Restarted `quickshell.service`, sent a 12-notification burst, confirmed zero `cardLoader`/`ReferenceError`/`TypeError` lines in the log tail (previously dozens per render). Live-verified the overflow card and real-card paths both bind correctly via the `notifs` IPC surface.
- **Committed in:** `8d1e80e`

**3. [Rule 2 - Missing Critical] No mechanical, screenshot-free surface existed to verify the popup stack or invoke an action**
- **Found during:** Starting Task 3 (fault-injection fixture)
- **Issue:** Task 3's own acceptance criteria require reading the server's in-flight count/stack index and invoking a tracked notification's action "off the shell's own IPC surface rather than off a screenshot" — no such surface existed.
- **Fix:** Added a `notifs` `IpcHandler` in `shell.qml` (`count`, `historyCount`, `indexOf`, `textOf`, `invokeAction`) — extends the same `notifs` IPC target RESEARCH.md's own "IPC handler shape" example already reserves for later centre/DND verbs, rather than minting a second target. `invokeAction` calls the real `NotificationAction.invoke()` method, the same one a card's action-button `TapHandler` calls.
- **Files modified:** `quickshell/.config/quickshell/shell.qml`
- **Verification:** Live-exercised by `notif-fault-inject` itself — 2 consecutive runs, 9/9 checks passing
- **Committed in:** `9f4bb53`

---

**Total deviations:** 3 auto-fixed (2 bugs, 1 missing critical functionality)
**Impact on plan:** All three were necessary for the plan's own must_haves truths to actually hold (no-gesture-destroys-data, error-free rendering, mechanical fixture assertions). No scope creep — no new UI surface, no new design token, no new package.

## Issues Encountered

- **Live notification-daemon bus race (documented, expected — matches Plan 19-01's precedent, not a defect):** This session's verification needed Quickshell to own `org.freedesktop.Notifications` to test real notify-send round-trips. Per the live-session note this boot, swaync had won the D-Bus-activation race at boot and quickshell was still retrying. Following Plan 19-01's own established precedent, swaync was masked+stopped for the duration of live verification (Quickshell reclaimed the name automatically within ~1s, no quickshell restart needed), verification ran, then swaync was unmasked and its failed-unit state reset. Restarting `quickshell.service` afterward (to test the fix cleanly) replayed the same bus race and Quickshell won again — deterministically forcing swaync back to ownership would require reproducing the exact boot-time timing (D-Bus activation via the bar's always-on `swaync-client -swb` subscription racing Quickshell's own near-instant re-registration), which is inherently racy and not safely scriptable without risking a longer, more invasive session interruption. **Session ends with Quickshell owning `org.freedesktop.Notifications`.** Both daemons remain installed and functional; this is the documented transitional state Plan 19-01's own key-decision names ("whichever process claims the name first wins... acknowledged, documented transitional state per D-19-42/T-19-02") and is in fact closer to Phase 19's eventual end-state (swaync is deleted in Plan 19-08). `quickshell-doctor`'s `single org.freedesktop.Notifications owner, and it is swaync` check will currently read `[FAIL] ... owner: quickshell` as a result — this is an accurate reflection of the live session's ambient bus-ownership state, not a code regression from this plan's commits (confirmed via `git stash`: the same 24-passed/4-failed baseline, unrelated to notifications, existed before this plan's changes too). It will self-correct on the next boot if swaync wins that race again, and is superseded entirely once Plan 19-08 deletes swaync.
- Per the acceptance criterion's own literal grep command (`grep -c 'MouseArea' NotifCard.qml`), the count returns 4 rather than the expected 1 — but this is because the criterion's literal grep also matches the word "MouseArea" inside three prose comment lines explaining the one-hit-area design (the same design the criterion is checking for). A precise `grep -c 'MouseArea {'` (actual instantiations) returns exactly 1, confirming the underlying property holds; the literal acceptance-criterion command is imprecise, not the code.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- The popup card is now feature-complete against D-19-05 through D-19-12/40 and QNOTIF-02 through QNOTIF-05 — ROADMAP success criterion 1 (apart from bus ownership, which 19-01 already proved) is met.
- `notif-fault-inject` is committed, executable, and proven re-runnable twice in a row with 9/9 passing — this is the exact evidence Plan 19-08's GATE-02 render gate is specified to re-run before deleting swaync; no further authoring needed there.
- The human-judgment checklist items in this plan's own Task 1 `<verify><human-check>` block (actually dragging a card, watching the ring sweep, eyeballing the `+N more` clamp at 12 notifications) were not run interactively this session, per the project's established live-verification-skip preference — the underlying mechanics were instead proven live via IPC assertions and log inspection (see coverage D1/D4 `rationale`). These remain open for a human to eyeball at the phase's own end-of-phase UAT gate (`human_verify_mode: end-of-phase` per `.planning/config.json`).
- No blockers for 19-05 (history/grouping/centre), which builds on `NotifServer.history` — now populated for real by `dismiss(id)` rather than being an always-empty stub.

---
*Phase: 19-notification-server-centre*
*Completed: 2026-08-13*
