# Phase 13 D-19/D-20 Soak Verdict — WAIVER RECORD, NOT A VERDICT

**This gate did not pass. It was WAIVED by explicit operator decision on 2026-07-28.**

The floor was not reached. No A/B comparison was performed. No motion was judged. Nothing
below should be read as "the motion retrofit was checked and found acceptable" — it was not
checked at all. This document exists so that fact is unmistakable to any future reader,
including a future audit, a future phase, or the operator's own future self.

## What happened

Plan 13-01 started the D-19 soak clock at **2026-07-27T03:40:53Z**, after its D-17 render gate
was approved. Plan 13-07 (this plan) reached Task 1 — the blocking soak-verdict gate — roughly
one calendar day later, on 2026-07-28. The executor refused to fabricate floor counts or
per-motion verdicts, since the D-19/D-20 floor is explicitly the operator's lived, multi-session
experience and not something an executor agent can measure or infer. The orchestrator then
relayed the operator's explicit decision: **waive Task 1's blocking gate to close the phase**,
rather than continue accruing soak time.

The refusal to fabricate a verdict still holds — this waiver changes what gets recorded, not
whether the record tells the truth.

## D-19 floor — measured fact, not observed-by-usage

One number below was independently measured by the orchestrator (not self-reported by the
operator as a usage estimate) and is recorded as a **measured fact**: `Hyprland` is PID 966,
started 2026-07-26 22:31:07, elapsed 1d 2h at measurement time — a single continuous compositor
process, and `journalctl --list-boots` shows one unbroken boot across the entire soak window.
That session's start (2026-07-26 22:31:07) even **predates** the soak clock (2026-07-27
03:40:53Z), meaning the entire soak window sits inside session 1, with no session boundary having
occurred since the clock started.

| Requirement | Floor | Observed |
|---|---|---|
| Distinct desktop sessions (compositor started fresh) | 3 | **1** — measured (PID 966, one unbroken boot per `journalctl --list-boots`, spanning and predating the whole soak window) |
| Workspace switches | 40 | not observed |
| Window opens | 25 | not observed |
| Window closes | 25 | not observed |
| Notification appearances | 15 | not observed |
| Layer-surface entrances (launcher / OSD) | 15 | not observed |
| A/B flips per motion category | 2 | **0** — no A/B flips were performed for any motion |

**The floor was objectively NOT met.** One of seven rows (sessions) has a measured value below
its floor (1 of 3); the remaining five interaction-count rows were never counted at all and are
recorded as `not observed` rather than guessed at. Reporting a plausible-sounding estimate for
any of them would be exactly the fabrication this document exists to avoid.

## Per-motion verdict table — NOT ASSESSED

No motion below was exercised under the A/B toggle. No verdict — `keep`, `retune`, or anything
in between — was reached for any of the thirteen rows. Every cell reads `NOT ASSESSED — soak gate
waived`, which is a statement of absence, not an affirmative judgment.

| Motion | Token | A/B comparison note | Verdict |
|---|---|---|---|
| Window open | emphasized-in / windows-in curve | none performed | NOT ASSESSED — soak gate waived |
| Window close | emphasized-out / windows-out curve | none performed | NOT ASSESSED — soak gate waived |
| Window move | standard / windows-move curve | none performed | NOT ASSESSED — soak gate waived |
| Workspace switch | emphasized-in / workspaces curve | none performed | NOT ASSESSED — soak gate waived |
| Special workspace | emphasized-in + slidevert | none performed | NOT ASSESSED — soak gate waived |
| Fade in | emphasized-in / fade-in curve | none performed | NOT ASSESSED — soak gate waived |
| Fade out | emphasized-out / fade-out curve | none performed | NOT ASSESSED — soak gate waived |
| Layer entrance (launcher, OSD, notification popup) | emphasized-in, decelerate | none performed | NOT ASSESSED — soak gate waived |
| Layer exit | emphasized-out, accelerate | none performed | NOT ASSESSED — soak gate waived |
| Border colour transition | ambient, linear | none performed | NOT ASSESSED — soak gate waived |
| Notification-centre transitions | standard | none performed | NOT ASSESSED — soak gate waived |
| waybar module transitions | slow-standard, standard | none performed | NOT ASSESSED — soak gate waived |
| Battery blink indicators | blink-slow, blink-fast | none performed | NOT ASSESSED — soak gate waived |

## Consequence — stated plainly

D-19 and D-20 exist to catch a specific failure mode: a motion that looks fine in a one-off
review-time glance but reads wrong once lived with daily, across restarts, at the actual speed a
human reacts at rather than a deliberately slowed inspection. That failure mode was **not ruled
out for any of the thirteen motions in this table.** None of them were exercised again after
plan 13-01/13-02/13-05's original render-gate approvals, none were compared against the
pre-retrofit `legacy` curves, and none were lived with across the 3-session/40-switch/25-open/
25-close/15-notification/15-layer-entrance floor this gate was built to require. If any of these
thirteen motions is in fact wrong in daily use, this document is not evidence against that — it
is evidence that the question was never asked.

## Task 2 — retune: none demanded

No retune was performed, and none was demanded — not because every motion was judged acceptable
(no motion was judged at all), but because a `retune` verdict requires an assessed `retune` row
to act on, and there are none. `animations.conf` and `motion.json`'s per-motion easing/duration
mappings are unchanged by this plan's Task 2 in the sense that no motion was individually
retuned; see Task 4 below for the separate, real removal of the temporary A/B measuring
instrument, which is unrelated to retuning and was not waived.

## Task 3 — targeted re-soak: not applicable

Task 3's targeted re-soak instructions apply only to motions Task 2 retuned. Since Task 2
retuned nothing (see above), Task 3 is a documented no-op: **"no retunes — clean verdict does
not stand, because no verdict was reached in the first place."** This is deliberately not
worded as "no retunes — clean verdict stands," since there is no clean verdict here to stand on
— only a waiver.

## Non-adoption of the marked non-MD3 (`x-*`) curve set

Because no motion was assessed, no motion adopted any of D-11's marked non-MD3 `x-*` character
curves (`x-overshoot`, `x-overshoot-in`, `x-undershoot-out`, `x-smooth-in`, `x-smooth-out`).
Per the plan's Task 4 instruction, since none survived, the object was removed entirely from
`motion.json` — the shipped easing vocabulary is now pure MD3.

## Forbidden-language check

This document does not use "deemed acceptable," "assessed as satisfactory," "no issues found,"
"effectively keep," or "implicitly approved" anywhere above, and every verdict cell reads
"NOT ASSESSED — soak gate waived" rather than "keep."

---

**Waived by:** explicit operator decision, relayed by the orchestrator, 2026-07-28
**Soak window:** 2026-07-27T03:40:53Z (13-01 render-gate approval) through 2026-07-28 (this
plan's Task 1)
**Recorded by:** 13-07 execution
