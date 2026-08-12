---
phase: 18-qml-bar-retirement-machinery
verified: 2026-08-12T23:59:00+03:00
status: gaps_found
score: 15/20 must-haves verified
behavior_unverified: 3
overrides_applied: 0
gaps:
  - truth: "QBAR-11: The bar's memory and process count stay flat across a multi-hour soak — no RSS creep, no accumulated subprocesses, no idle timers doing nothing"
    status: failed
    reason: >
      REQUIREMENTS.md marks QBAR-11 `[x] Complete`, but the phase's own primary evidence
      artifact explicitly disclaims a pass. `18-BAR-SOAK.md` § "Section six" states verbatim:
      "Therefore: QBAR-11 stays OPEN. No leak is claimed and no pass is claimed." Four soak-
      window anchors were attempted; the first three voided (a rebuild, a reboot, two more
      restarts). The fourth ran the full 12.5 hours (etimes 44941s) but the window was
      contaminated by live development (hot-reloads, a lost-and-restored bar surface, skipped
      end-observation) — RSS grew +162 MiB against a 32 MiB ceiling (~5x over) but this is
      explicitly NOT attributed to a leak because the window wasn't a resting one. WINDOWS.md
      row 68 is still `open` (no `resolved_at` timestamp) as of verification time, and row 69
      (also open) records that a second permanent process
      (`quickshell-bar-watchdog.service`, confirmed live and active on this host) was added
      after the soak's own inventory was written — invalidating the "exactly one permanent
      child process" assumption the soak's threshold table depends on.
    artifacts:
      - path: ".planning/phases/18-qml-bar-retirement-machinery/18-BAR-SOAK.md"
        issue: "Section six's own conclusion: 'QBAR-11 stays OPEN', no verdict reached after four anchor attempts"
      - path: ".planning/WINDOWS.md"
        issue: "Row 68 (QBAR-11 soak) and row 69 (second permanent watchdog process invalidating the soak's process-count assumption) both still read status=open with no resolved_at"
      - path: ".planning/REQUIREMENTS.md"
        issue: "Line 24/136 mark QBAR-11 `[x] Complete` with no caveat, contradicting the artifact it should be citing"
    missing:
      - "A fifth, uncontaminated 4-hour soak window (no hot reload, no monitor sleep, no restart) ending in the full Section-five procedure: end capture, >=5 spaced RSS samples, the 200-cycle hide/reveal exercise, and a real verdict"
      - "Re-inventory the soak's 'exactly one permanent process' gate against the new quickshell-bar-watchdog.service (WINDOWS row 69) before that gate can mean anything again"
      - "Correct REQUIREMENTS.md's QBAR-11 row (and its Coverage table entry) to reflect the true open status, or close the gap for real before re-marking it Complete"
  - truth: "QBAR-08: The hidden bar reveals on pointer hover AND on holding Super"
    status: partial
    reason: >
      The hover half is shipped, live-confirmed and structurally solid (HotZone.qml,
      BarReveal.qml, D-18-26 popout-hold logic). The "holding Super" half is explicitly,
      deliberately NOT shipped — confirmed in three independent first-party sources written by
      the phase's own plans: `BarReveal.qml`'s own header ("Mechanism record (Task 2, QBAR-08's
      held-Super half) — BLOCKED, NOT SHIPPED. This is the honest outcome, not the preferred
      one."), `keybinds.lua`'s comment at the would-be bind site ("Held-Super reveal (Phase 18
      Plan 16, QBAR-08) — Step 4's stop condition was applied here, NOT shipped."), and
      `18-16-SUMMARY.md` itself ("QBAR-08's Super-hold half is NOT shipped... recorded as a
      blocked item, not a silent gap."). `BarReveal.qml`'s `setSuperHeld(held)` function is
      declared but never called anywhere in the tree (confirmed by repo-wide grep) — the
      keybind that would drive it was drafted, verified against `keybind-doctor`, found to
      chord-collide with the existing tap-to-menu bind at `keybinds.lua:86`, and reverted.
      REQUIREMENTS.md nonetheless marks QBAR-08 `[x] Complete` with the full conjunctive text
      ("reveals on pointer hover **and** on holding Super") and no caveat anywhere in the file.
    artifacts:
      - path: "quickshell/.config/quickshell/modules/bar/BarReveal.qml"
        issue: "Lines 27-91: own header documents the held-Super mechanism as drafted, verified, and reverted; setSuperHeld() is a declared-but-undriven seam"
      - path: "hypr/.config/hypr/config/keybinds.lua"
        issue: "Lines 112-122: comment records the bind was drafted, staged, and NOT committed due to a chord collision with the tap-to-menu bind"
      - path: ".planning/REQUIREMENTS.md"
        issue: "Line 21/133 mark QBAR-08 `[x] Complete` with the full conjunctive requirement text and no caveat"
    missing:
      - "Either ship the held-Super reveal (the code comments name the exact recovery path: run the nested hypr-lua-harness probe to confirm Hyprland dispatches a press-triggered global-shortcut bind and a release-triggered exec_cmd bind independently on the identical chord, then restore the 3-line bind/manifest/shortcut trio), or correct REQUIREMENTS.md to record QBAR-08 as partially met with the Super-hold half named as open debt"
deferred: []
behavior_unverified_items:
  - truth: "QBAR-04: User can scroll on the bar's audio AND brightness sections to adjust them"
    test: "Scroll on the bar's brightness-bearing section (or its popout) and confirm the OS brightness level changes"
    expected: "Brightness changes one step per scroll notch, matching the audio-scroll behavior which IS confirmed (GATE-02 row B.3, audio half PASS)"
    why_human: >
      GATE-02's own record marks this row NOT-DEMONSTRABLE for the brightness half, per D-18-39
      — this host has no backlight-class device (confirmed independently: quickshell-doctor's
      own brightness probe SKIPs with "no backlight-class device — brightnessctl -l lists only
      leds-class devices on this host"). The code path (BrightnessBackend.qml,
      `brightnessctl --class ... --device ...`) is present and structurally sound, but no
      device on this machine can exercise it. This is a named, authorized exception, not a
      silent gap, but it means QBAR-04's brightness half has never been observed working end to
      end on this host.
  - truth: "QBAR-07: The bar auto-hides fully, driven by idle/fullscreen/gaming/keybind, with exactly one owner of visibility state"
    test: "Trigger a monitor-removal / no-outputs event (DPMS sleep/wake, external-monitor unplug) while the bar is visible, then check hyprctl layers -j for the quickshell-bar namespace and cross-check bar-visibility.sh status against it"
    expected: "The bar's layer surface either survives the event or bar-visibility.sh's own status/reassert verbs genuinely recover it without a full service restart"
    why_human: >
      WINDOWS.md row 67 (status: open, no resolved_at) records this exact defect, observed live
      on this host on 2026-08-12: the bar's PanelWindow does not recreate its layer surface
      after a monitor-removal/restoration event, and bar-visibility.sh's status/reassert verbs
      both falsely report/fail to fix it — only `systemctl --user restart quickshell.service`
      recovers it. Row 69 (also open) records a watchdog service added as a stopgap. This
      contradicts QBAR-07's "exactly one owner of visibility state" framing in the specific case
      where that owner's own status readback is proven to lie. Requires a live monitor-sleep/
      wake or hotplug event to reproduce; not reproducible by static inspection.
  - truth: "QBAR-12: The bar's reserved screen space survives hyprctl reload and a QML hot reload without drift or overlap"
    test: "Run `quickshell-doctor`'s bar-reserved-zone-stability check (hide/show via bar-visibility.sh keybind toggle, then verify hyprctl monitors -j's reserved array is byte-identical to the pre-toggle reading) several times in a row"
    expected: "restore-verified=1 on every run"
    why_human: >
      Reproduced live during this verification: 5 consecutive runs of quickshell-doctor's
      dedicated QBAR-12 check yielded 4 PASS (restore-verified=1) and 1 FAIL
      (restore-verified=0) — an approximately 20% intermittent failure on this exact host. The
      check's own source comments name this as an already-known live finding ("bar-visibility.sh
      status is computed purely from local intent files, never from a live readback... it can
      report visible even when the underlying qs ipc call bar show silently failed") and
      implement a bounded 3-pair retry specifically to absorb it — this is not a new discovery,
      but it does mean the "survives... without drift" claim is not 100% reliable, and ties to
      the same status-verb-lies class of defect as WINDOWS row 67.
human_verification:
  - test: "Re-observe GATE-02 row B.5 (tray icons render and menus open on click) against the current build"
    expected: "Either the row is retracted/marked N/A because TrayCapsule.qml was deleted in 18.1-04 (commit 94d58f4), before this gate iteration's build existed — or the operator confirms what was actually clicked to produce the recorded behavior"
    why_human: >
      `18-GATE-02-RECORD.md`'s B.5 row is labeled "Iteration 3, live gesture" (sha 2644ae0,
      2026-08-12) and describes clicking "the tray capsule" — "one cell per running tray
      application" — and its menu opening below (horizontal) / leftward (vertical). This is
      architecturally impossible against the current tree: `TrayCapsule.qml` was deleted along
      with all four of its consumers in phase 18.1-04 (confirmed: `find` returns nothing,
      `grep -rn "TrayCapsule\|SystemTray"` under modules/bar returns nothing), and QBAR-05 is
      independently recorded as Withdrawn in REQUIREMENTS.md. No remaining bar component
      (MediaConnectivityCapsule.qml, the closest analog) opens a per-application menu — it opens
      WifiPopout/BluetoothPopout/EthernetPopout, not a DBusMenu-style list. Rows A.5 and B.6 also
      reference "the tray" in their Iteration 3 observations. This strongly suggests these three
      rows were carried forward unrefreshed from before the tray's removal rather than genuinely
      re-observed, which — if true — would mean GATE-02's "14 PASS" headline includes at least
      one row whose observation could not have happened as described. This does not by itself
      invalidate GATE-02's other 13 rows (each of those cites orientation-specific, plausible,
      falsifiable detail with no such contradiction), and RETIRE-02's deletion is otherwise well
      supported. But it is exactly the kind of gap this project's own history warns about, and it
      deserves a direct answer from the operator before being treated as settled.
  - test: "Update REQUIREMENTS.md's GATE-02 row/coverage-table citation"
    expected: "The row should cite `18-GATE-02-RECORD.md` (sha `2644ae0`, the actual D-18-31 blocking final pass that authorized RETIRE-02) as GATE-02's closing evidence, not only `18.1-07-SUMMARY.md`/`18.1-VERIFICATION.md` (Phase 18.1's earlier, informal gap-closure approval)"
    why_human: >
      Confirmed via `git blame`: REQUIREMENTS.md's GATE-02 row (lines 76 and 170) was last
      written by commit `489169e` at 00:35:54 on 2026-08-12 — Phase 18.1's own "Gap closure
      resolution" addendum — and has not been touched since, even though the phase's actual
      mandated blocking final pass (per D-18-31: "a checkpoint verdict recorded in an earlier
      wave is evidence a criterion was once true on a partial build; it is never a substitute
      for observing it here") ran later that same day in plan 18-19, committed at 22:45:57
      (`c59f830`), producing `18-GATE-02-RECORD.md` with the actual `RETIRE-02 AUTHORISED`
      line. `18-19-PLAN.md` explicitly and deliberately excludes REQUIREMENTS.md edits from its
      own scope ("no edit to ROADMAP.md, REQUIREMENTS.md or 18-UI-SPEC.md"), and no other plan
      in this phase claims that edit either — so the citation was never corrected. GATE-02 the
      requirement IS genuinely satisfied (the interlock `git diff --quiet 2644ae0 -- quickshell/.config/quickshell/`
      exits 0, independently confirmed), but a future reader of REQUIREMENTS.md alone would
      believe Phase 18.1's approval — not this phase's own blocking pass — is what closed the
      gate.
---

# Phase 18: QML Bar & Retirement Machinery Verification Report

**Phase Goal:** The always-on bar replaces waybar, and every gate and script the later
retirements depend on is built and proven once
**Verified:** 2026-08-12T23:59:00+03:00
**Status:** gaps_found
**Re-verification:** No — initial verification
**HEAD at verification:** `af3e3aa`

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | QBAR-01: permanently-mounted, rounded-capsule surface | VERIFIED | `quickshell.service` active (systemd supervisor); GATE-02 A.1/A.2 live PASS |
| 2 | QBAR-02: one bar, horizontal/vertical from config, replaces 4 layouts | VERIFIED | `waybar/config-{full,floating,vertical,athena}.jsonc` all deleted (confirmed: `waybar/` dir absent); `Bar.qml` single-file with orientation property; GATE-02 B.4 live PASS |
| 3 | QBAR-03: click workspace to switch | VERIFIED | GATE-02 B.2 live PASS |
| 4 | QBAR-04: scroll audio and brightness sections | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED (brightness half) | Audio half: GATE-02 B.3 live PASS. Brightness half: GATE-02 marks NOT-DEMONSTRABLE per D-18-39 (authorized); independently confirmed no backlight-class device exists on this host (`quickshell-doctor`'s own brightness probe SKIPs) |
| 5 | QBAR-05: system tray (Withdrawn, superseded by D-15) | VERIFIED (as Withdrawn) | `TrayCapsule.qml` confirmed deleted (18.1-04, commit `94d58f4`); zero tray references anywhere under `modules/bar/`; REQUIREMENTS.md correctly records Withdrawn, not Complete. **See Human Verification #1: GATE-02's own record still contains a "tray" PASS row that appears stale/impossible against this state.** |
| 6 | QBAR-06: clock/battery/network/bluetooth/audio/CPU-RAM-disk readouts | VERIFIED | GATE-02 B.1 live PASS; `SystemCapsule.qml`, `MediaConnectivityCapsule.qml`, `ClockActionsCapsule.qml` all present and wired |
| 7 | QBAR-07: full auto-hide, one owner of visibility state | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | Core mechanism (bar-visibility.sh single-owner, idle/fullscreen/gaming/keybind sources) present and extensively built (18-15). **But** WINDOWS row 67 (open) documents a live, reproduced case where the owner's own status/reassert verbs lie and only a full service restart recovers a lost surface — see behavior_unverified_items |
| 8 | QBAR-08: hidden bar reveals on hover AND on holding Super | ✗ FAILED (partial) | Hover half shipped and solid. Super-hold half explicitly reverted and NOT shipped — confirmed in `BarReveal.qml`, `keybinds.lua`, and `18-16-SUMMARY.md`'s own text. See gaps. |
| 9 | QBAR-09: click a bar section opens its own popout | VERIFIED | 10 `*Popout.qml` files present (`AudioPopout`, `WifiPopout`, `BluetoothPopout`, `ClockPopout`, `EthernetPopout`, `MediaPopout`, `ResourcesPopout`, `SectionPopout`, plus controller/trigger); `PopoutController.qml` wired |
| 10 | QBAR-10: bar returns automatically if its process dies | VERIFIED | `quickshell.service` — `Restart=on-failure`, `RestartSec=2`; live-confirmed `NRestarts=0`, `ActiveState=active` |
| 11 | QBAR-11: memory/process count stay flat across a multi-hour soak | ✗ FAILED | `18-BAR-SOAK.md` § Section six: "QBAR-11 stays OPEN... no pass is claimed." WINDOWS rows 68 and 69 both still `open`. See gaps. |
| 12 | QBAR-12: reserved space survives `hyprctl reload` and QML hot reload | ⚠️ PRESENT_BEHAVIOR_UNVERIFIED | `quickshell-doctor`'s dedicated check exists and structurally covers hot-reload + toggle-restore + manifest coverage. Live-reproduced: 4/5 runs PASS, 1/5 FAIL (`restore-verified=0`) — an already-named, ~20% intermittent race on this host. See behavior_unverified_items |
| 13 | RETIRE-01: retirement checklist script, run before and after | VERIFIED | `hypr/.config/hypr/scripts/retirement-check` exists and runs live; `18-RETIREMENT-BASELINE-waybar.md` (before) and `18-RETIREMENT-AFTER-waybar.md` (after) both present |
| 14 | RETIRE-02: waybar removed (package, config, contract, matugen, checks) | VERIFIED | Live-confirmed: `waybar/` dir absent, `pacman -Q waybar` fails, `retirement-check waybar` → 13 PASS / 1 architectural SKIP (own-tree, correct terminal state) / 1 transient-scope FAIL (unrelated live systemd naming artifact, not a package remnant) |
| 15 | GATE-01: current behaviour enumerated before redesign | VERIFIED | `18-BEHAVIOUR-BASELINE.md` (512 lines) with a "GATE-01 Recurrence Protocol" section and full criteria index |
| 16 | GATE-02: human render-and-look gate; no deletion before judgment | VERIFIED (functionally) with WARNING | `18-GATE-02-RECORD.md`: Iteration 3, 14 PASS / 1 NOT-DEMONSTRABLE (authorized) / 0 FAIL; `## Deletion Authorisation` reads `RETIRE-02 AUTHORISED — sha 2644ae0...`; interlock (`git diff --quiet 2644ae0 -- quickshell/.config/quickshell/`) independently confirmed clean. **Two caveats surfaced, both in Human Verification below:** (1) REQUIREMENTS.md's own GATE-02 citation still points at Phase 18.1's earlier, superseded approval, not at this record; (2) row B.5 (and supporting mentions in A.5/B.6) describes live interaction with a "tray capsule" component deleted from the codebase before this iteration's build existed. |
| 17 | GATE-03: quickshell-doctor structural checks per new surface | VERIFIED | Live-confirmed: `bar-surface-registry`, `bar-colour-role-routing`, `bar-colour-alpha-resolution` all PASS |
| 18 | GATE-04: hex-literal colour lint, deny-by-default | VERIFIED | Live-confirmed: `colour-lint` → 112 passed, 0 failed |
| 19 | LEDGER-01: GradientBorder + doctor-dispatch bookkeeping closed | VERIFIED | `PanelDialog.qml:191` has `GradientBorder {`; WINDOWS row 14 `fixed` with `resolved_at`; `.planning/debug/resolved/panels-missing-animated-border.md` has `status: resolved` |
| 20 | LEDGER-03: OVER-04 frame-rate floor/target measured | VERIFIED | `18-FRAME-RATE.md`: 60fps floor PASS (0/81,261 iterations over 16.67ms); 165fps target honestly recorded NOT RESOLVABLE with the sanctioned instrument, not claimed; REQUIREMENTS.md's LEDGER-03 row matches this exactly |

**Score:** 15/20 truths verified (2 failed, 3 present-but-behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `quickshell/.config/quickshell/modules/bar/*.qml` (24 files) | Entry model, capsules, popouts, drawer, reveal, hot zone, tooltip host | ✓ VERIFIED | All present; `BarEntryModel.qml`, `BarCapsule.qml`, `BarDrawer.qml`, `BarReveal.qml`, `HotZone.qml`, `PopoutController.qml`, `PopoutTrigger.qml`, `BarTooltipHost.qml` + 10 popouts + 5 capsules all exist |
| `hypr/.config/hypr/scripts/retirement-check` | Registry-driven, multi-class retirement gate | ✓ VERIFIED | Live-run, 16 classes, correct verdict logic (SKIP-on-genuine-absence for own-tree) |
| `hypr/.config/systemd/user/quickshell.service` | Supervisor unit for QBAR-10 | ✓ VERIFIED | `Restart=on-failure`, live active, `NRestarts=0` |
| `waybar/` tree, `waybar-*` scripts, `waybar` package | Deleted (RETIRE-02) | ✓ VERIFIED | All absent, live-confirmed |
| `.planning/phases/18-qml-bar-retirement-machinery/18-BAR-SOAK.md` | Closed QBAR-11 soak verdict | ✗ STUB (methodology complete, verdict never reached) | Section six explicitly: "QBAR-11 stays OPEN" |
| `.planning/REQUIREMENTS.md` | Accurate ledger of what's actually Complete | ⚠️ ORPHANED CITATIONS | QBAR-08, QBAR-11 marked `[x] Complete` without matching evidence; GATE-02 row cites superseded evidence |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `BarReveal.qml` (`setSuperHeld`) | `keybinds.lua` (Super-hold bind) | Hyprland `GlobalShortcut` dispatch | ✗ NOT_WIRED | Function declared, never called; bind drafted then reverted (chord collision) |
| `quickshell-doctor`'s `bar-reserved-zone-stability` | `bar-visibility.sh keybind toggle` | Live IPC + `hyprctl monitors -j` readback | ⚠️ PARTIAL (intermittent) | Wired and functioning 4/5 runs; 1/5 runs the restore-verification loop exhausts its retries |
| `retirement-check waybar` | `contract.json`, matugen templates, install/stow lists, systemd units | Registry-driven regex/glob scan | ✓ WIRED | Live-confirmed, 13/14 blocking classes PASS |
| `18-19-PLAN.md`'s Deletion Authorisation | `18-20`'s RETIRE-02 execution | sha-pinned interlock (`git diff --quiet <sha>`) | ✓ WIRED | Independently confirmed clean against `2644ae0` |
| `REQUIREMENTS.md` GATE-02 row | `18-GATE-02-RECORD.md` (the actual authorizing evidence) | Citation | ✗ NOT_WIRED | Row cites only `18.1-07-SUMMARY.md`/`18.1-VERIFICATION.md`, never updated to point at this phase's own blocking pass |

### Data-Flow Trace (Level 4)

Not applicable in the traditional sense (no UI rendering a fetched list from a backend query) —
this phase's "data flow" is measurement-to-ledger. Traced above: `18-FRAME-RATE.md` →
`REQUIREMENTS.md` LEDGER-03 (flows correctly, honestly capped at what was measured);
`18-BAR-SOAK.md` → `REQUIREMENTS.md` QBAR-11 (does NOT flow — the ledger claims a result the
source artifact explicitly declines to give).

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|----------|---------|--------|--------|
| waybar retirement-check | `retirement-check waybar` (from repo root) | `13 PASS / 1 SKIP (own-tree, architectural) / 1 FAIL (transient scope)` | ✓ PASS (matches documented after-run) |
| colour-lint (GATE-04) | `colour-lint` | `112 passed, 0 checks failed` | ✓ PASS |
| quickshell-doctor (GATE-03 + QBAR-12) | `quickshell-doctor` x5 | `24-25 passed, 3-4 failed` across runs; `bar-reserved-zone-stability` flipped FAIL once (`restore-verified=0`), PASS the other 4 times; the 3 other failures (MPRIS writers, swayosd-key-ownership, permissions-allowlist-paths) are pre-existing and outside this phase's scope | ✓ PASS (structural), ⚠️ intermittent (QBAR-12 specifically) |
| quickshell.service supervision (QBAR-10) | `systemctl --user show quickshell.service -p NRestarts,Restart,ActiveState` | `Restart=on-failure`, `NRestarts=0`, `ActiveState=active` | ✓ PASS |
| Super-hold reveal wiring (QBAR-08) | `grep -rn setSuperHeld quickshell/.config/quickshell/` | Only the declaration, no call site | ✗ FAIL (confirms gap) |
| Tray component existence (QBAR-05 / GATE-02 B.5 cross-check) | `find ... -iname '*Tray*'`, `grep -rn TrayCapsule` | No matches anywhere under `modules/bar/` | Confirms QBAR-05's Withdrawn status; contradicts GATE-02 B.5's Iteration-3 "live gesture" description |
| quickshell-bar-watchdog.service (WINDOWS row 69) | `systemctl --user is-active quickshell-bar-watchdog.service` | `active` | Confirms a second permanent process now exists, invalidating `18-BAR-SOAK.md`'s single-process inventory |

### Probe Execution

Not applicable — this phase does not ship `scripts/*/tests/probe-*.sh`-style probes; its
"probes" are the `retirement-check` and `quickshell-doctor` checks already covered above under
Behavioral Spot-Checks, run directly from the repository root.

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| QBAR-01 | 18-01, 18-05 | Permanently-mounted, rounded-capsule surface | ✓ SATISFIED | See Observable Truths #1 |
| QBAR-02 | 18-05 | One switchable bar, replaces 4 layouts | ✓ SATISFIED | See Observable Truths #2 |
| QBAR-03 | 18-09 | Click workspace to switch | ✓ SATISFIED | GATE-02 B.2 |
| QBAR-04 | 18-12 | Scroll audio/brightness | ? NEEDS HUMAN (brightness half) | See behavior_unverified_items |
| QBAR-05 | 18-10, 18.1-04 | System tray | ✓ SATISFIED (Withdrawn per D-15) | Deletion confirmed live; see Human Verification #1 for a related record-integrity concern |
| QBAR-06 | 18-08 | Readouts | ✓ SATISFIED | GATE-02 B.1 |
| QBAR-07 | 18-15 | Full auto-hide, single owner | ? NEEDS HUMAN | WINDOWS row 67 live defect |
| QBAR-08 | 18-16 | Hover + Super-hold reveal | ✗ BLOCKED (partial) | Super-hold explicitly not shipped |
| QBAR-09 | 18-13 | Section popouts | ✓ SATISFIED | 10 popout files, PopoutController wired |
| QBAR-10 | 18-07 | Auto-restart supervisor | ✓ SATISFIED | systemd unit, live-confirmed |
| QBAR-11 | 18-18 | Multi-hour soak stays flat | ✗ BLOCKED | Explicitly open per its own artifact |
| QBAR-12 | 18-17 | Reserved space survives reload | ? NEEDS HUMAN | Intermittent live failure, ~20% |
| RETIRE-01 | 18-06 | Retirement checklist script | ✓ SATISFIED | Live-run, before/after both captured |
| RETIRE-02 | 18-20 | waybar removed | ✓ SATISFIED | Live-confirmed |
| GATE-01 | 18-02 | Behaviour baseline before redesign | ✓ SATISFIED | 18-BEHAVIOUR-BASELINE.md |
| GATE-02 | 18-19 | Human render gate before deletion | ✓ SATISFIED (functionally), citation stale | See Human Verification #1, #2 |
| GATE-03 | 18-17 | quickshell-doctor structural checks | ✓ SATISFIED | Live-confirmed 3 dedicated checks PASS |
| GATE-04 | 18-03 | Hex-literal lint | ✓ SATISFIED | Live-confirmed 112/0 |
| LEDGER-01 | 18 (bookkeeping) | GradientBorder + doctor-dispatch closure | ✓ SATISFIED | Confirmed in code + WINDOWS + debug archive |
| LEDGER-03 | 18-18 | Frame-rate floor/target measured | ✓ SATISFIED | 18-FRAME-RATE.md, honestly capped |

No orphaned requirements found — all 20 IDs given for this phase appear in at least one plan's
`requirements` field and are accounted for above.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---|---|---|---|
| `.planning/REQUIREMENTS.md` | 21, 133 | QBAR-08 marked `[x] Complete` while `BarReveal.qml`/`keybinds.lua`/`18-16-SUMMARY.md` all record its Super-hold half as reverted | 🛑 Blocker | Ledger says "done," code says "blocked" — exactly the gap this project's history warns about |
| `.planning/REQUIREMENTS.md` | 24, 136 | QBAR-11 marked `[x] Complete` while `18-BAR-SOAK.md`/WINDOWS row 68 say "stays OPEN" | 🛑 Blocker | Same class of gap, higher stakes (soak evidence explicitly disclaims a pass) |
| `.planning/REQUIREMENTS.md` | 76, 170 | GATE-02 row cites only Phase 18.1's superseded approval, not this phase's own blocking pass | ⚠️ Warning | Traceability gap, not a functional failure — GATE-02 itself did pass |
| `.planning/phases/18-qml-bar-retirement-machinery/18-GATE-02-RECORD.md` | 142 (B.5) | "Iteration 3, live gesture" description of a deleted component (`TrayCapsule.qml`) | ⚠️ Warning | Undermines confidence in the record's own "no verdict predates the observation" rule for at least this row |
| `install.sh` (per `18-REVIEW.md` WR-01/WR-02) | PACMAN_PKGS array | `pacman-contrib` (`checkupdates`) and `ffmpeg` invoked by phase-18 and pre-existing code but not declared | ⚠️ Warning | Silent feature degradation on a genuinely fresh install — against this repo's stated Reproducibility core value; already flagged in code review, not yet fixed |
| `quickshell/.config/quickshell/modules/bar/ClockActionsCapsule.qml` | 587-618 (per `18-REVIEW.md` WR-03) | Notification subscription process never restarts after exit | ⚠️ Warning | Already flagged in code review; bell capsule can get permanently stuck if swaync restarts |

No `TBD`/`FIXME`/`XXX` unreferenced debt markers found in the phase's key-files.

### Human Verification Required

1. **Re-observe GATE-02 row B.5 (tray)** — see `human_verification` frontmatter for full detail.
   The row describes clicking a "tray capsule" that was deleted from the codebase before this
   gate iteration's build existed.

2. **Correct REQUIREMENTS.md's GATE-02 citation** — see `human_verification` frontmatter. Not a
   functional gap (GATE-02 genuinely passed), but the ledger points at the wrong evidence trail.

3. **QBAR-04's brightness-scroll half** — never observed working end to end on this host (no
   backlight device); code path is present and structurally sound.

4. **QBAR-07's monitor-removal liveness gap** — WINDOWS row 67, live-reproduced once already;
   needs a deliberate re-test (DPMS sleep/wake or monitor hotplug) to confirm the watchdog
   stopgap (row 69) actually recovers it, since the soak's own inventory hasn't been reconciled
   against the watchdog's existence yet.

5. **QBAR-12's intermittent restore-after-toggle failure** — reproduced live during this
   verification (1/5 runs). Already an acknowledged, instrumented-for class of defect; not new,
   but worth a decision on whether the ~20% rate is acceptable as-is.

### Gaps Summary

Two must-haves are marked `[x] Complete` in `.planning/REQUIREMENTS.md` while the phase's own
first-party artifacts explicitly contradict that status:

- **QBAR-11** (multi-hour soak): `18-BAR-SOAK.md` itself says "QBAR-11 stays OPEN... no pass is
  claimed," after four anchor attempts, the last of which ran the full duration but was
  contaminated by live development work and a lost bar surface. WINDOWS.md rows 68 and 69 are
  both still open, and row 69 shows the soak's own "exactly one permanent process" assumption is
  now stale (a watchdog service was added afterward as an unrelated stopgap).
- **QBAR-08** (hover + Super-hold reveal): only the hover half shipped. The Super-hold half was
  drafted, verified against `keybind-doctor`, found to collide with an existing bind, and
  deliberately reverted — recorded as such in three separate first-party files, none of which
  REQUIREMENTS.md's flat "Complete" reflects.

Both are genuine, well-evidenced gaps rather than inference from absence — in both cases the
phase's own artifacts state outright that the requirement is not met, and REQUIREMENTS.md was
simply never corrected to match. This is exactly the pattern this project's history (three prior
green-but-broken ships) warns about, now recurring at the ledger level rather than the code
level: the code and its own paperwork (SUMMARYs, WINDOWS.md, `18-BAR-SOAK.md`) are honest about
both gaps — only the top-level requirements ledger is stale.

Three further items are present, wired, and mostly working, but have a demonstrated behavioral
edge case that no automated gate currently closes cleanly (QBAR-04's untestable brightness half,
QBAR-07's monitor-removal liveness gap, QBAR-12's ~20% intermittent restore failure) — these are
routed to human verification rather than treated as blockers, since in each case the phase's own
tooling was specifically built to catch (and in QBAR-12/QBAR-07's case, already caught and
recorded) the exact failure mode.

Everything else — the bar's core delivery (entry model, workspaces, readouts, popouts, both
orientations, auto-restart), RETIRE-01/02, GATE-01/03/04, and LEDGER-01/03 — is verified against
live, independently-reproduced evidence, not SUMMARY claims: `colour-lint` (112/0),
`quickshell-doctor`'s three dedicated bar checks, `retirement-check waybar` (13/1/1, matching the
documented after-run exactly), the live `quickshell.service` supervision state, and
`18-GATE-02-RECORD.md`'s 14-PASS/1-ND tally (modulo the B.5 concern above) all reproduced
independently during this verification, not merely read and trusted.

---

*Verified: 2026-08-12T23:59:00+03:00*
*Verifier: Claude (gsd-verifier)*
