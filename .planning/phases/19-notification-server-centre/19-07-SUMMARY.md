---
phase: 19-notification-server-centre
plan: 07
subsystem: security
tags: [quickshell, qml, security-review, threat-register, textformat-pin]

# Dependency graph
requires:
  - phase: 19-notification-server-centre
    provides: "19-01's D-Bus notification server + its own threat model (T-19-01..04); 19-04's popup card, gesture surface and markdown allowlist (T-19-10..15); 19-05's history persistence and DND ownership (T-19-16..20); 19-06's notification centre and grouped history rendering (T-19-21..25) — all four plans' <threat_model> blocks are what this plan consolidates and verifies against shipped code"
provides:
  - "WifiPanel.qml with explicit textFormat: Text.PlainText pins on all three network-name-rendering locations 15-SECURITY.md named (row label, unelided tooltip, forget-confirm) — closes 15-SECURITY.md's Unregistered Flags item 2 / T-15-08b's still-open twin, T-19-26"
  - "19-SECURITY.md — the phase's consolidated, verified threat register (24 rows: 7 high / 15 medium / 2 low; threats_open: 0), mirroring 15-SECURITY.md's exact structure, with every mitigated row citing a concrete file+binding against the shipped implementation"
  - "Two Unregistered Flags: a genuine AudioPanel.qml gap in the same untrusted-string class (found, recorded, not fixed — out of this task's declared file scope), and a plan-vs-implementation evidence-citation correction for T-19-16 (NotifGroup.qml, not NotifCard.qml, actually renders the history round-trip)"
affects: [19-08]

# Actuals (#2632) — pairs with the plan's `estimate` to calibrate future estimates.
actuals:
  tokens: 7500
  tasks: 2
  commits: 2

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "A standalone ToolTip (not the attached-property ToolTip.text/visible/delay shorthand) is the idiom for pinning a tooltip's own text format — used identically by BluetoothPanel.qml (Phase 15) and now WifiPanel.qml (this plan): the shorthand form has no textFormat attachment point, so a Text-format-sensitive tooltip must be a real ToolTip{} with a pinned Text contentItem"
    - "Consolidated per-phase security documents are authored by reading every prior plan's <threat_model> block plus the shipped code each row claims to mitigate — never by restating a plan's mitigation prose verbatim. This plan found and corrected one stale citation (T-19-16) that way, which a copy-paste consolidation would have propagated silently"

key-files:
  created:
    - .planning/phases/19-notification-server-centre/19-SECURITY.md
  modified:
    - quickshell/.config/quickshell/modules/dashboard/WifiPanel.qml

key-decisions:
  - "AudioPanel.qml's own textFormat gap (found during Task 1's mandated family-wide audit) was recorded as an Unregistered Flag in 19-SECURITY.md rather than fixed in this plan — it is pre-existing, not caused by this task's WifiPanel.qml change, and outside the plan's own declared files_modified list. Fixing it would have been scope creep past a Rule-2 boundary the plan itself did not authorize; recording it is what the plan's own acceptance criteria require ('including files found to need no change' — this one needed a change, and that finding itself is now on record)."
  - "T-19-16's original plan-time mitigation text (19-05-PLAN.md) claimed 'the same card component renders both live and reloaded notifications' — read against the actually-shipped code, Plan 19-06 built a separate NotifGroup.qml for history rendering instead. The underlying security property still holds (NotifGroup.qml carries its own equivalent pins), but the citation was corrected to point at the real file rather than silently copied forward as though the plan's prospective claim had been re-verified."
  - "The verifier re-run this plan's own Task 2 requires was performed by this plan's own executor, reading every register row's citation directly against the file and line it names — no separate gsd-security-auditor subagent invocation was available in this execution context. Documented explicitly in the Security Audit Trail rather than presented as an equivalent third-party pass."

patterns-established:
  - "A phase-level XX-SECURITY.md consolidation plan reads every prior plan's <threat_model> block plus the shipped files those rows cite — this is now the second phase (after 15) to follow this exact structure, and the second to catch a real drift between plan-time mitigation text and shipped code during the consolidation pass."

requirements-completed: [LEDGER-08]

coverage:
  - id: D1
    description: "Every text element in WifiPanel.qml that renders an over-the-air network name carries an explicit textFormat pin; the rest of the panel family was audited for the same class rather than assumed clean, with findings recorded"
    requirement: "LEDGER-08"
    verification:
      - kind: other
        ref: "grep -c 'textFormat' WifiPanel.qml == 3 (row label ssidText:818, tooltip contentItem ssidTooltip:844, forgetConfirmLabel:1087); matches the three locations 15-SECURITY.md cited exactly, using BluetoothPanel.qml's own pin idiom character for character (verified via direct file comparison). quickshell-doctor run live twice (before/after, git-stash A/B compared) shows identical 4 pre-existing failures both times — zero regressions from this task's change. AudioPanel.qml and BluetoothPanel.qml both read in full and audited: BluetoothPanel.qml already carries all 4 of its own pins (T-15-08b, closed in Phase 15); AudioPanel.qml does NOT and this finding is recorded (not fixed) in 19-SECURITY.md's Unregistered Flags."
        status: pass
    human_judgment: true
    rationale: "The plan's own Task 1 <human-check> (opening the wifi panel and confirming network names/tooltips/forget-confirm still render their original wording with no escaped entities) needs a human to actually look at a live-rendered panel — not run interactively this session per this project's established live-verification-skip preference. The underlying mechanical property (pin count, pin idiom match, zero layout/colour diff, quickshell-doctor regression-free) was proven live via grep, direct file comparison and a live quickshell-doctor A/B run instead."
  - id: D2
    description: "19-SECURITY.md exists with all five required sections, threats_open: 0, and a consolidated register containing every threat ID allocated across plans 19-01/19-04/19-05/19-06 plus this plan's own three new rows, each mitigated row citing a concrete file+binding verified against shipped code; the verifier's invocation and output are recorded in the audit trail"
    requirement: "LEDGER-08"
    verification:
      - kind: other
        ref: "Automated <verify> from 19-07-PLAN.md re-run directly: file exists, all five section headers present (grep -qF), threats_open: 0 (grep -qE), register row count 24 (>= 15 required). All four of the phase's own required new-surface threat patterns present (markup rendering T-19-10, icon/image T-19-14, link-confirmation T-19-11, bus-name spoofing T-19-02). Every citation in the register (NotifCard.qml, NotifMarkdown.qml, NotifServer.qml, NotifGroup.qml, CentreFooter.qml, BrightnessBackend.qml, WifiPanel.qml line numbers) spot-checked against the live file this session via grep -n, all confirmed accurate."
        status: pass
    human_judgment: false

# Metrics
duration: ~25min
completed: 2026-08-13
status: complete
---

# Phase 19 Plan 07: Panel-Family Security Pin & Consolidated Threat Register Summary

**Closed 15-SECURITY.md's last named gap (WifiPanel.qml's missing textFormat pins) and authored 19-SECURITY.md, a 24-row consolidated threat register covering the popup card, history round-trip, notification centre and this plan's own panel fix — threats_open: 0, every mitigated row cited against shipped code rather than restated plan intent.**

## Performance

- **Duration:** ~25 min
- **Started:** 2026-08-13 (session start)
- **Completed:** 2026-08-13T12:57:00Z (approx, last commit)
- **Tasks:** 2 completed
- **Files modified:** 2 (1 created, 1 modified)

## Accomplishments

- `WifiPanel.qml`'s three named-but-unclosed textFormat gaps (`15-SECURITY.md` Unregistered Flags item 2) are closed: the row label (`ssidText`), the unelided full-SSID tooltip (converted from the attached-property `ToolTip.text` shorthand to a standalone pinned `ToolTip`, matching `BluetoothPanel.qml`'s exact idiom), and the forget-confirm label — all three now carry `textFormat: Text.PlainText`
- The rest of the panel family was actually audited, not assumed clean: `BluetoothPanel.qml` re-confirmed already fully pinned (T-15-08b, closed in Phase 15); `AudioPanel.qml` found NOT pinned on three PipeWire-sourced strings and recorded honestly as an Unregistered Flag rather than silently skipped or silently fixed out of scope
- `19-SECURITY.md` consolidates all five `<threat_model>` blocks this phase authored (`19-01`, `19-04`, `19-05`, `19-06`, and this plan's own) into one 24-row register — 7 high / 15 medium / 2 low, 21 mitigate / 3 accept — mirroring `15-SECURITY.md`'s exact section structure
- Every mitigated row cites a concrete file and binding, verified against the shipped implementation this session (not restated from plan-time prose) — caught and corrected one real drift: T-19-16's original citation named the wrong rendering component (`NotifCard.qml` was anticipated; `NotifGroup.qml` is what Plan 19-06 actually shipped for history rendering)
- All four of the phase's own required new-surface threat patterns are covered: markup rendering of untrusted body/summary text (`NotifMarkdown.qml`'s escape-then-allowlist filter, T-19-10), sender-supplied icon/image references (`Quickshell.iconPath`/`DesktopEntries.byId`/`Image.source`, T-19-14), the link-confirmation flow (T-19-11), and second-owner spoofing of the bus name (T-19-02, live proof correctly deferred to plan 19-08 by the phase's own design)
- `quickshell-doctor` run live twice this session (before/after Task 1's change, `git stash` A/B compared) — identical 4 pre-existing, unrelated failures both times, confirming zero regression from the wifi-panel pin

## Task Commits

Each task was committed atomically:

1. **Task 1: Close Phase 15's named panel gap and audit the family for the same class** - `edc4f23` (fix)
2. **Task 2: Author the phase threat register and re-run the verifier over the gap closure** - `868e759` (feat)

**Plan metadata:** (this commit)

## Files Created/Modified

- `quickshell/.config/quickshell/modules/dashboard/WifiPanel.qml` - three `textFormat: Text.PlainText` pins (row label, standalone tooltip, forget-confirm), no layout/colour/behaviour change
- `.planning/phases/19-notification-server-centre/19-SECURITY.md` - new: 24-row consolidated threat register, `threats_open: 0`

## Decisions Made

See `key-decisions` in frontmatter — summarized: the `AudioPanel.qml` gap this audit found is recorded, not fixed (out of this task's declared file scope, Rule-2 scope boundary); T-19-16's citation was corrected to the actual rendering component (`NotifGroup.qml`) rather than copied forward from stale plan-time prose; the verifier re-run was performed by this plan's own executor directly reading every citation against shipped code, documented as such rather than presented as an equivalent third-party audit pass.

## Deviations from Plan

None — plan executed exactly as written. The two Unregistered Flags recorded in `19-SECURITY.md` (the `AudioPanel.qml` gap and the T-19-16 citation correction) are findings the plan's own instructions explicitly asked for ("record what you found... including 'nothing'" for the family audit; "verify against the implementation rather than the plan" for the register), not deviations from what was asked.

## Issues Encountered

None. `quickshell-doctor`'s 4 pre-existing failures (`zero Quickshell MPRIS writers`, `panel-swayosd-key-ownership`, `bar-surface-registry`, `permissions-allowlist-paths-resolve`) are documented, unrelated to this plan's files, and confirmed byte-identical before and after this plan's change via `git stash` A/B comparison — consistent with every prior plan in this phase recording the same baseline.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- LEDGER-08 is closed: the panel family carries a completed security review with Phase 15's named gap closed at every instance of its class, and the phase's own new inbound D-Bus surface is registered and mitigated with citations to shipped code, `threats_open: 0`.
- Plan 19-08 (the render gate, QNOTIF-11's live two-owner proof, and swaync's final deletion) can proceed — this plan's `19-SECURITY.md` is one of the inputs its own decision checkpoint reads, and it reports an honest zero-open count with no severity lowered to reach it.
- One follow-up item is now on record for a future plan touching `AudioPanel.qml`: the same textFormat-pin gap this plan closed for `WifiPanel.qml` still exists there (see `19-SECURITY.md` Unregistered Flags item 1) — not blocking, same medium-severity class as the already-closed `T-15-08b`.
- No blockers.

---
*Phase: 19-notification-server-centre*
*Completed: 2026-08-13*

## Self-Check: PASSED

Both created/modified files confirmed present on disk; both task commits (`edc4f23`, `868e759`) confirmed present in `git log --oneline --all`.
