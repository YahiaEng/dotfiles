---
phase: 18-qml-bar-retirement-machinery
plan: 14
subsystem: ui
tags: [quickshell, qml, hyprland-layershell, popout, wifi, bluetooth, calendar, resources, media, mpris]

# Dependency graph
requires:
  - phase: 18-13
    provides: "SectionPopout.qml (the frame), PopoutController.qml (the summon path + hover contract), PopoutTrigger.qml (the per-entry wrapper), AudioPopout.qml (the template body) — all four left complete and unchanged for this plan to hang five more bodies on"
provides:
  - "WifiPopout.qml / BluetoothPopout.qml / ClockPopout.qml / ResourcesPopout.qml / MediaPopout.qml — the other five D-18-16 popout bodies, all six sections now real"
  - "WifiBackend.readinessState / BluetoothBackend.readinessState — the two connectivity readiness registers, one native (Networking.backend enum) and one built (monotonic latch + one-shot deadline, the only new timing object this plan adds)"
  - "Design.popoutListCap / Design.backendResolveDeadlineMs — two appended tokens, the shared list cap now governing all six bodies including AudioPopout's one-line retrofit"
  - "The proof that hanging five bodies on 18-13's frame needed zero changes to SectionPopout.qml, PopoutController.qml, PopoutTrigger.qml, Bar.qml or shell.qml — confirmed by every task's own git diff"
affects: [18-16, 18-17, 18-19]

# Actuals (#2632)
actuals:
  tokens: 19633
  tasks: 3
  commits: 3

tech-stack:
  added: []
  patterns:
    - "Readiness register named identically across two backends despite two different implementations (WifiBackend: native enum read, zero timer; BluetoothBackend: monotonic latch + one-shot deadline) — the popout bodies read one vocabulary regardless of which mechanism produced it."
    - "PopoutTrigger wrapping a conditionally-visible bar entry (media) needs its OWN `visible` binding mirroring the wrapped Readout's — a PopoutTrigger wraps a plain Item, not a positioner, so its implicit size does not collapse to zero just because its child is invisible. Established here for the first time since audio/wifi/bluetooth were all unconditionally visible."
    - "Per-field D-41 degradation, already shipped on PerformanceTab's Dial instances, extends cleanly to a compact multi-row popout body (ResourcesPopout) without inventing a new state vocabulary — each row reads its own metric register directly."
    - "A deliberate, documented second copy of stateless calendar arithmetic (ClockPopout vs DashboardTab's calendar card) — the review-obligation pattern for accepted duplication, recorded in the copy's own header rather than left implicit."

key-files:
  created:
    - quickshell/.config/quickshell/modules/bar/WifiPopout.qml
    - quickshell/.config/quickshell/modules/bar/BluetoothPopout.qml
    - quickshell/.config/quickshell/modules/bar/ClockPopout.qml
    - quickshell/.config/quickshell/modules/bar/ResourcesPopout.qml
    - quickshell/.config/quickshell/modules/bar/MediaPopout.qml
  modified:
    - quickshell/.config/quickshell/modules/dashboard/Design.qml
    - quickshell/.config/quickshell/modules/dashboard/WifiBackend.qml
    - quickshell/.config/quickshell/modules/dashboard/BluetoothBackend.qml
    - quickshell/.config/quickshell/modules/bar/qmldir
    - quickshell/.config/quickshell/modules/bar/MediaConnectivityCapsule.qml
    - quickshell/.config/quickshell/modules/bar/SystemCapsule.qml
    - quickshell/.config/quickshell/modules/bar/ClockActionsCapsule.qml
    - quickshell/.config/quickshell/modules/bar/AudioPopout.qml

key-decisions:
  - "Wifi readiness verdict resolved EXISTS NATIVELY, not the audit's own hedge toward 'may need a latch': `Networking.backend` (NetworkBackendType::Enum, None|NetworkManager) confirmed against the installed quickshell-network.qmltypes as a genuine two-value distinction, combined with the already-reactive `wifiDevice` null-check. No timer added on the wifi side — this keeps the plan's own final verification section's claim ('exactly one timing object across everything this plan wrote') literally true, since bluetooth's built latch+deadline is the only one."
  - "Bluetooth readiness verdict resolved DOES NOT EXIST, BUILT: confirmed against quickshell-bluetooth.qmltypes that the Bluetooth singleton exposes only defaultAdapter/adapters/devices plus one signal, no service-resolved flag. Latch on `Bluetooth.adapters.values.length > 0`, deadline read from the new `Design.backendResolveDeadlineMs` token — the single timing object this whole plan adds."
  - "Clock and Media both resolved 'no pending phase exists' — clock because it has no backend at all (pure date arithmetic), media because MediaBackend.qml's own repointed `widgetState` is a two-branch expression with the middle value structurally unreachable, confirmed by reading that file directly rather than trusting this plan's own prior claim."
  - "Resources resolved EXISTS NATIVELY, confirmed per-instance (not per-tab) by reading Dial.qml and PerformanceTab.qml directly: each Dial instance carries its own widgetState property, and PerformanceTab binds each dial from its own metric register independently."
  - "Bluetooth's 'nothing-here' state is deliberately two different sentences for two different facts (no adapter vs. adapter-enabled-with-nothing-paired), matching the plan's own instruction, rather than one collapsed message that would tell a user with working hardware it is missing."
  - "The dashboard tab indices used by ClockPopout/ResourcesPopout/MediaPopout (0/2/1) are literal integers confirmed by reading modules/Dashboard.qml's own tabIndexDashboard/tabIndexPerformance/tabIndexMedia constants directly — those constants live on a window instance the bar files cannot reach declaratively, so the literal is the correct mechanism, not a shortcut around one."

patterns-established:
  - "This phase's established 'skip live verification, ship fast' operating mode continued: every automated grep-based <verify> assertion across all three tasks was run and passed (using /usr/bin/grep directly, after `unset -f grep` — this session's interactive shell aliases `grep` to a ugrep wrapper in a mode that mis-parses several of this plan's own extended-regex verify lines, e.g. `\\{` escapes and `--include=*.qml` glob expansion under zsh — a shell-environment quirk unrelated to the plan or the shipped code, matching 18-13's own identically-diagnosed and identically-worked-around finding). The genuinely interactive halves — hovering each of the six entries live, confirming `iw dev`/`bluetoothctl show` show no scan/discovery while a popout is open, comparing the calendar cell-for-cell against the dashboard's own card, provoking the resources popout's unsampled em-dash state on a fresh restart, playing a track and confirming the transport buttons move real playback, and the theme-switch crossfade check — were NOT performed this session, for the same reason 18-13's own SUMMARY recorded: the running quickshell process predates every commit in this plan and has not been restarted or hot-reloaded against this code."
  - "Two pre-existing bugs found in this plan's own automated <verify> scripts, neither caused by this plan's edits, both documented rather than worked around silently: (1) SystemCapsule.qml's Task 2 check asserts exactly one `Process {` block in the whole file, but that file already had three (updatesProcess/upgradeProcess/notifyProcess) before this plan touched it — confirmed via `git show HEAD:...` against the pre-Task-2 commit; the correct, unduplicated updatesProcess/updatesTimer pair was verified present by direct inspection instead. (2) Task 3's `ls \"$BAR\"/*Popout.qml | wc -l -eq 6` check counts SectionPopout.qml too, since its filename also ends in \"Popout.qml\" — the glob was never going to equal 6 no matter what this plan built; the six real body files (Audio/Wifi/Bluetooth/Clock/Resources/Media) were confirmed present by name instead."

requirements-completed: [QBAR-09]

coverage:
  - id: D1
    description: "The readiness audit for all five remaining D-18-16 sections, recorded per section as one of three verdicts (exists natively / built / no pending phase exists), then the wifi and bluetooth popout bodies — current connection + radio toggle + capped saved-network list (wifi); adapter toggle + capped connected-then-paired device list (bluetooth) — with no scan, no discovery, no passphrase field and no pairing flow"
    requirement: "QBAR-09"
    verification:
      - kind: other
        ref: "Task 1 automated <verify> grep/regex script (commit 07fc674) — all assertions run and passed with /usr/bin/grep: frame/controller/trigger/Bar.qml/shell.qml untouched, two Design.qml tokens appended-only, two readiness registers strictly additive with the audit verdict recorded in each, exactly one added Timer on BluetoothBackend.qml (non-repeating), zero scan/discovery identifiers anywhere under modules/bar/, both bodies cap their lists at Design.popoutListCap with >=2 elided peer-string elements, every Text element carries an explicit textFormat (8/8 wifi, 6/6 bluetooth), zero untokened colours, wayfinding routed to the correct panel names, capsule holds exactly three PopoutTriggers with the 18-12 wheel handler intact"
        status: pass
    human_judgment: true
    rationale: "The plan's own human-check requires hovering the live network and bluetooth entries, comparing the connected network name against `nmcli`, confirming the radio toggle moves the real radio, and — the single most important check named in the plan — confirming `iw dev`/`bluetoothctl show` report no scan/discovery activity while each popout sits open. None of this is provable by static analysis alone. Not performed this session: the running quickshell process predates every commit in this plan (see patterns-established)."
  - id: D2
    description: "The two bodies that needed nothing built — ClockPopout.qml (a fixed 42-cell month grid over a handed-down date, no second clock, no navigation) and ResourcesPopout.qml (three per-metric rows degrading independently, confirmed per-instance rather than per-tab against the shipped Dial/PerformanceTab precedent), plus the ClockActionsCapsule.qml and SystemCapsule.qml wrappers that reproduce the outer positioner's own spacing exactly"
    requirement: "QBAR-09"
    verification:
      - kind: other
        ref: "Task 2 automated <verify> grep/regex script (commit 61c9ee0) — all assertions run and passed except one pre-existing script-authoring bug (SystemCapsule.qml's Process-count assertion, see patterns-established), confirmed unrelated to this plan's own edits via `git show HEAD:` against the pre-task commit. Confirmed: frame untouched, no dashboard file outside the three named changed, qmldir append-only with both types registered, ClockPopout declares no SystemClock/Timer/Process and no month-navigation identifier, `bodyState: \"populated\"` literal present, resources body reads all three per-metric registers with zero Performance-tab-only identifiers and a real em-dash literal for the unsampled case, both files' Text/textFormat counts match exactly (2/2, 4/4), SystemCapsule holds exactly one PopoutTrigger around the three readouts with the updates Process/Timer pair intact by direct inspection, ClockActionsCapsule holds exactly one PopoutTrigger around the clock cell."
        status: pass
    human_judgment: true
    rationale: "The plan's human-check is a side-by-side cell-for-cell comparison against the dashboard's own live calendar card, a percentage cross-check against `top`/`free -h`/`df -h` AND the Performance tab's own rendering of the same fractions, and — the check named as most important — restarting the shell and opening the resources popout as fast as possible to provoke the genuinely unsampled em-dash state before any real reading lands. None of this is provable without a live restart. Not performed this session for the reason recorded above."
  - id: D3
    description: "The last body (MediaPopout.qml: bounded art with an explicit decode bound, the full uncapped track title, three transport controls, a non-interactive progress line, the multi-player one-line case) and the six-section close — one shared Design.popoutListCap now governing all six bodies including AudioPopout's own one-line retrofit, all six section ids declared across the three capsules matching PopoutController's allowlist exactly"
    requirement: "QBAR-09"
    verification:
      - kind: other
        ref: "Task 3 automated <verify> grep/regex script (commit 30ee55a) — all assertions run and passed except one pre-existing script-authoring bug (the *Popout.qml glob over-matching SectionPopout.qml, see patterns-established), confirmed by name that the six real body files exist. Confirmed: frame untouched, no dashboard file outside the three named changed, qmldir append-only with MediaPopout registered, AudioPopout.qml's diff is exactly one added/one removed line (the token substitution), the media body reads artPath and never trackArtUrl, carries an explicit sourceSize decode bound, asynchronous:true/cache:false matching the Media tab's own construction, all three transport functions present, no seekTo/setVolume/selectPlayer identifier, no re-application of the bar's title cap, the unreachable 'pending' value never bound, bodyState bound exactly once, Text/textFormat counts match (7/7), capsule holds exactly four PopoutTriggers with the wheel handler intact, all six section ids present across the capsules and matching the controller's allowlist, zero timing objects across all six body files, zero scan/discovery identifiers anywhere under modules/bar/, zero fullscreenBlocking identifiers."
        status: pass
    human_judgment: true
    rationale: "The plan's human-check requires playing a real track with a long title to confirm the popout shows more of it than the bar does, pressing all three transport buttons and confirming real playback responds, stopping all players to see the quiet 'nothing is playing' placeholder, opening a second player to see the multi-player one-line case, and — the check the plan itself calls the one that must not be skipped — opening all five foot links in turn and confirming each of the five destinations is intact and unthinned. None of this is provable without a live restart. Not performed this session for the reason recorded above."

duration: ~55min
completed: 2026-08-11
status: complete
---

# Phase 18 Plan 14: Section Popout Bodies — Wifi, Bluetooth, Clock, Resources, Media Summary

**All five remaining D-18-16 popout bodies ship — wifi (current connection + radio toggle + capped saved-network list), bluetooth (adapter toggle + capped connected-then-paired device list), clock (a fixed 42-cell month grid over a handed-down date), resources (three per-metric degrading rows) and media (bounded art, full uncapped title, three transport controls) — completing the six-section popout family 18-13's frame was built to hold, with two connectivity readiness registers (one native, one built) as the only new state and one non-repeating Timer as the only new timing object across the whole plan.**

## Performance

- **Duration:** ~55 min
- **Started:** 2026-08-11 (session start)
- **Completed:** 2026-08-11
- **Tasks:** 3 (all completed)
- **Files modified:** 13 (5 new QML types, 8 modified)

## Accomplishments

- **Task 1 (readiness audit + wifi + bluetooth):** Answered the readiness question for all five remaining sections against the real backends and the installed qmltypes before writing any body. `Design.qml` gained two appended tokens (`popoutListCap` 3, `backendResolveDeadlineMs` 2000). `WifiBackend.qml` gained `readinessState` sourced natively from `Networking.backend`'s `NetworkBackendType` enum (confirmed against `/usr/lib/qt6/qml/Quickshell/Networking/quickshell-network.qmltypes`) combined with the existing `wifiDevice` null-check — no latch, no timer. `BluetoothBackend.qml` gained `readinessState` built from a monotonic latch over `Bluetooth.adapters` plus one non-repeating deadline `Timer` reading the new token — confirmed against `/usr/lib/qt6/qml/Quickshell/Bluetooth/quickshell-bluetooth.qmltypes` that no native equivalent exists, and this is the ONE timing object the whole plan adds. `WifiPopout.qml` and `BluetoothPopout.qml` shipped as new registered types with capped, order-preserving lists, row-scoped connect/action failure copy, and foot links routed to the existing panels. `MediaConnectivityCapsule.qml`'s network and bluetooth entries were each wrapped in a `PopoutTrigger`, bringing that file to three triggers alongside 18-13's own audio wrap.
- **Task 2 (clock + resources):** The two bodies that needed nothing built. `ClockPopout.qml` carries a deliberate, documented second copy of `DashboardTab.qml`'s calendar arithmetic (locale-correct weekday ordering, a fixed forty-two-cell grid, Friday tinting, today's accent circle), takes its date as a handed-down property from the clock capsule's own `SystemClock`, and declares `bodyState: "populated"` as a literal constant with the reasoning stated inline. `ResourcesPopout.qml` reads `SystemResources`' three per-metric D-41 registers independently per row — confirmed against `Dial.qml`/`PerformanceTab.qml` that the per-instance degradation precedent really does hold — rendering an empty track and an em-dash for an unsampled metric rather than a filled-to-zero bar, with the aggregate `bodyState` governing only the frame's own placeholder. `SystemCapsule.qml` and `ClockActionsCapsule.qml` each gained one `PopoutTrigger` wrapping the relevant readouts inside a nested `Grid` reproducing the outer positioner's own spacing, so wrapping changed no rendered geometry — the updates entry and the other five action cells stayed untouched siblings.
- **Task 3 (media + the six-section close):** `MediaPopout.qml` shipped as the last body — bounded album art (the already-resolved `artPath`, never the raw `trackArtUrl`, with an explicit `sourceSize` decode bound neither the Media tab nor the dashboard's compact widget carries), the full uncapped track title (deliberately not the bar's `Design.mediaTitleMaxChars` cap), three transport controls, a non-interactive progress line reading `MediaBackend`'s own existing refresh heartbeat, and the multi-player case collapsed to one line. `bodyState` binds only the two branches `MediaBackend.qml`'s repointed `widgetState` can actually reach — confirmed by reading that file directly rather than trusting this plan's own prior claim. `MediaConnectivityCapsule.qml`'s media entry was wrapped in a fourth `PopoutTrigger`, with a Rule 1 fix: the trigger's own `visible` now mirrors the wrapped `Readout`'s, since a `PopoutTrigger` wraps a plain `Item` (not a positioner) and would otherwise keep reserving bar space for an empty media entry. `AudioPopout.qml`'s sink-list literal `3` was replaced by `Design.popoutListCap` in a single-line retrofit. All six section ids now match `PopoutController`'s allowlist exactly, and every task's own diff confirms the frame, controller, trigger, `Bar.qml` and `shell.qml` needed zero changes to hold five more bodies.

## Task Commits

Each task was committed atomically:

1. **Task 1: The readiness audit and the wifi/bluetooth popout bodies** — `07fc674` (feat)
2. **Task 2: The two bodies that needed nothing built — clock and resources** — `61c9ee0` (feat)
3. **Task 3: The last body and the six-section close — media** — `30ee55a` (feat)

**Plan metadata:** pending final commit (this SUMMARY + STATE.md + ROADMAP.md + REQUIREMENTS.md)

## Files Created/Modified

- `quickshell/.config/quickshell/modules/bar/WifiPopout.qml` — new: current connection, radio toggle, capped saved-network list
- `quickshell/.config/quickshell/modules/bar/BluetoothPopout.qml` — new: adapter toggle, capped connected-then-paired device list
- `quickshell/.config/quickshell/modules/bar/ClockPopout.qml` — new: fixed 42-cell month grid over a handed-down date
- `quickshell/.config/quickshell/modules/bar/ResourcesPopout.qml` — new: three per-metric degrading rows
- `quickshell/.config/quickshell/modules/bar/MediaPopout.qml` — new: bounded art, full title, transport, progress line
- `quickshell/.config/quickshell/modules/dashboard/Design.qml` — two appended tokens (popoutListCap, backendResolveDeadlineMs)
- `quickshell/.config/quickshell/modules/dashboard/WifiBackend.qml` — readinessState register, strictly additive
- `quickshell/.config/quickshell/modules/dashboard/BluetoothBackend.qml` — readinessState register + the one Timer this plan adds
- `quickshell/.config/quickshell/modules/bar/qmldir` — five new type registrations across three commits
- `quickshell/.config/quickshell/modules/bar/MediaConnectivityCapsule.qml` — network, bluetooth and media entries each wrapped in a PopoutTrigger
- `quickshell/.config/quickshell/modules/bar/SystemCapsule.qml` — cpu/ram/disk readouts wrapped in one PopoutTrigger, updates entry untouched
- `quickshell/.config/quickshell/modules/bar/ClockActionsCapsule.qml` — clock cell wrapped in one PopoutTrigger
- `quickshell/.config/quickshell/modules/bar/AudioPopout.qml` — one-line list-cap retrofit

## Decisions Made

See `key-decisions` in the frontmatter above for the full readiness-verdict table and the tab-index sourcing decision.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] MediaPopoutTrigger's own `visible` was missing, which would have kept reserving bar space for an empty media entry**

- **Found during:** Task 3, wrapping the media entry in `MediaConnectivityCapsule.qml`
- **Issue:** Wifi, bluetooth and audio are all unconditionally visible entries, so Task 1's and 18-13's own `PopoutTrigger` wraps needed no `visible` binding of their own. The media entry is different — its `Readout` is `visible: ... hasPlayer`. A `PopoutTrigger` wraps a plain `Item`, not a positioner, so its own `implicitWidth`/`implicitHeight` (derived from `childrenRect`) does not collapse to zero merely because its child is invisible, unlike a `Grid`/`Row`/`Column` positioner which explicitly excludes invisible children from its own layout. Left unfixed, the capsule's outer `Grid` would have kept reserving space (and the spacing gap) for the media entry even with no player running — the exact regression the file's own header comments say the entry must not have.
- **Fix:** Bound `PopoutTrigger.visible` to the same `root.mediaBackend ? root.mediaBackend.hasPlayer : false` expression the wrapped `Readout` already uses, so the outer `Grid` positioner correctly excludes the whole trigger (and its spacing) when no player exists.
- **Files modified:** `quickshell/.config/quickshell/modules/bar/MediaConnectivityCapsule.qml`
- **Verification:** Confirmed by direct reasoning against `PopoutTrigger.qml`'s own implementation (`implicitWidth: contentHost.implicitWidth`, `contentHost.implicitWidth: childrenRect.width`, no visibility exclusion at that layer) and `BarCapsule.qml`'s own documented Grid-positioner exclusion rule. Live confirmation deferred with the rest of this session's interactive checks.
- **Committed in:** `30ee55a` (Task 3 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 — a real layout regression the plan's own file-ownership split did not anticipate, since Task 1's and 18-13's wraps never needed this pattern).
**Impact on plan:** No behavior change to any already-passing gate; closes a real gap that would have reserved bar space for an entry with nothing to show. No scope creep — the fix is the minimum surface (one property binding) needed to preserve the file's own already-stated "contributes zero extent and zero spacing otherwise" contract.

## Issues Encountered

- **Interactive-shell `grep` aliasing (same finding as 18-13, re-encountered).** This session's shell environment aliases `grep` to a `ugrep`-backed wrapper that mis-parses several of this plan's own verify-script extended-regex escapes (e.g. `\{` inside a BRE-style invocation) and separately trips on `--include=*.qml` glob expansion under zsh. Worked around by `unset -f grep` and invoking the real `/usr/bin/grep` for every verification command this session — a shell-environment quirk, not a defect in the plan or the shipped code.
- **Two pre-existing bugs in this plan's own automated `<verify>` scripts, neither caused by this plan's edits:**
  1. Task 2's `SystemCapsule.qml` check asserts `grep -cE "^\s*Process \{" "$SC" -eq 1`, but that file already had three `Process {` blocks (`updatesProcess`, `upgradeProcess`, `notifyProcess`) before this task touched anything — confirmed via `git show HEAD:...SystemCapsule.qml` against the commit immediately preceding this task, which returns 3, not 1. The check's own stated intent ("the updates reader process is gone or duplicated") was verified true by direct inspection instead: `updatesProcess`/`updatesTimer` remain exactly the single pair they always were, untouched by this task's edit.
  2. Task 3's six-body count check (`ls "$BAR"/*Popout.qml | wc -l -eq 6`) counts `SectionPopout.qml` too, since that filename also ends in `Popout.qml` — the glob was structurally never going to equal 6 regardless of what this plan built, since the frame itself matches its own naming convention. The six real body files (`AudioPopout`, `WifiPopout`, `BluetoothPopout`, `ClockPopout`, `ResourcesPopout`, `MediaPopout`) were confirmed present by name instead.

  Both are documented here so a future reader does not re-diagnose either as a defect in this plan's shipped code.

## User Setup Required

None — no external service configuration required. Every type this plan uses ships inside the already-installed `quickshell 0.3.0-2` or already exists in this repo, matching the phase-wide N/A `18-RESEARCH.md` already records and this plan's own `T-18-14-SC` threat-register row.

## Known Stubs

None. Every body renders exclusively live reads of its backend's real properties — no placeholder, no synthesized value, no hardcoded percentage. The resources body's per-row unsampled state (empty track + em-dash) is the designed E6-loading treatment, not a stub. Bluetooth's `pair`/`cancelPair`/discovery paths are deliberately absent by design (D-15-18, this plan's own prohibitions), not missing work.

## Live Verification — Deferred (per this phase's established skip-live-verification operating mode)

Every task's automated `<verify>` grep/regex script ran and passed this session (see Task Commits and `coverage` above), using the real `/usr/bin/grep` after working around the interactive shell's `ugrep` aliasing (see Issues Encountered). Two pre-existing bugs in the plan's own verify scripts were found, root-caused as unrelated to this plan's edits, and worked around by direct manual confirmation of the check's actual stated intent.

The genuinely interactive halves were NOT performed this session, matching 18-13's own identical, already-established precedent: the running `quickshell` process predates every commit in this plan and has not been restarted or hot-reloaded against this code, so a live pointer test right now would exercise old code, not what was just written. Specifically deferred:
- Task 1's human-check: hovering the network and bluetooth entries live, comparing against `nmcli`/`bluetoothctl`, confirming the radio/adapter toggles move real hardware state, and — the check the plan calls out as most important — confirming `iw dev`/`bluetoothctl show` report no scan/discovery activity while either popout sits open.
- Task 2's human-check: a cell-for-cell comparison of the calendar popout against the dashboard's own live calendar card, a percentage cross-check against `top`/`free -h`/`df -h` and the Performance tab, and restarting the shell to provoke the genuinely unsampled em-dash state before any real reading lands.
- Task 3's human-check: playing a real track to confirm the full uncapped title and real transport control, the quiet "nothing is playing" placeholder, the multi-player one-line case, and opening all five foot links to confirm every destination is intact and unthinned.

Logged to `.planning/WINDOWS.md` as unrun-verify entries (one per task's deferred human-check half), so all three stay visible at ship time.

## Next Plan Readiness

- All six D-18-16 popout bodies are now real: `audio` (18-13's), `wifi`, `bluetooth`, `clock`, `resources`, `media` (this plan's). `PopoutController.sections`' six-value allowlist is no longer aspirational.
- `SectionPopout.qml`'s public surface (identity/geometry/interaction/body-state/wayfinding) proved sufficient for all five of this plan's bodies with zero edits — 18-16's hot zone and reveal owner, and 18-17's structural checks, can build on a frame this plan is the second consumer of.
- `Design.popoutListCap`/`Design.backendResolveDeadlineMs` are the two tokens this plan adds; no future popout body should invent a third list-cap literal.
- The two backends' `readinessState` registers are now a proven, named pattern (native-enum vs. latch-plus-deadline) any future connectivity-adjacent surface can read by the same name.
- `18-BAR-LIVENESS-CHARGE.md`/`18-BAR-IDLE-BASELINE.md` inherit exactly one new permanent charge from this plan: the bluetooth resolution deadline Timer, non-repeating and stopped by design — 18-18's soak should confirm it never restarts.

---
*Phase: 18-qml-bar-retirement-machinery*
*Completed: 2026-08-11*

## Self-Check: PASSED

- FOUND: `quickshell/.config/quickshell/modules/bar/WifiPopout.qml`
- FOUND: `quickshell/.config/quickshell/modules/bar/BluetoothPopout.qml`
- FOUND: `quickshell/.config/quickshell/modules/bar/ClockPopout.qml`
- FOUND: `quickshell/.config/quickshell/modules/bar/ResourcesPopout.qml`
- FOUND: `quickshell/.config/quickshell/modules/bar/MediaPopout.qml`
- FOUND commit: `07fc674`
- FOUND commit: `61c9ee0`
- FOUND commit: `30ee55a`
