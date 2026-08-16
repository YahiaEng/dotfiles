# Phase 21: Media Fold-In & Contract Close - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-16
**Phase:** 21-media-fold-in-contract-close
**Areas discussed:** The cava visualiser, Cava lifecycle & cost, The orphaned bash stack, Entry point after the card, QMEDIA-01 parity gap, LEDGER-06 paperwork, RETIRE-08 contract close, plus two folded todos (frost unification, DND indicator) and the deletion gate

---

## Pre-discussion findings that reframed the phase

Three live-system findings were presented before any question was asked, because
each one invalidated a premise the roadmap was written against:

1. **cava is installed and running right now** (`cava 0.10.7-1`, PID 1990),
   `ags/lib/cava.ts` is a working streaming reader, and `MediaTab.qml` already
   imports `QtQuick.Shapes` and draws the ring via `ShapePath`/`PathAngleArc`.
   The roadmap's "blocking cava go/no-go spike" therefore had nothing left to
   establish.
2. **The AGS card has had no entry point since Phase 18** — its only opener was
   the waybar segment. The daemon, `gjs`, `media-status.sh watch` and `cava` are
   all still running for a UI nobody can open.
3. **`contract.json` carries 18 entries, not 29.** The roadmap's "29 → ~17" used
   the pre-migration total across all five retirements. 18 → 17 is the real
   change, and it does hit the stated target.

---

## The cava visualiser — rendered shape

| Option | Description | Selected |
|--------|-------------|----------|
| Radial bars (Caelestia) | N radial ShapePath bars, each length driven by its frequency band; at silence degrades to today's dashed ring | ✓ |
| Breathing ring | Existing dashed ring geometry unchanged; one scalar (mean amplitude) drives radius and stroke width | |
| Flat bar underlay | The AGS card's own 24-bar vertical treatment behind the art | |
| No-go, recorded | Record a written human verdict declining the visualiser; cava and dart-sass leave with ags | |

**User's choice:** Radial bars (Caelestia)
**Notes:** Presented as rendered ASCII previews showing each option's silence and
playing states side by side. The deciding argument was that the radial design's
silence state *is* the ring already accepted at render-gate round 3, so nothing
previously approved is put at risk. Claude's stated recommendation before the
question was "go, not no-go".

---

## The cava visualiser — cover art shape

| Option | Description | Selected |
|--------|-------------|----------|
| Keep the circle | Art stays the round-3/round-4 circle with its working MultiEffect mask; only the ring changes | |
| Squircle cutout | Superellipse mask — shows more of the cover than a circle, still reads as a soft shape; a house divergence neither reference ships | |
| Cookie cutout (Caelestia) | Hand-author the 12-lobe scalloped M3 blob; highest fidelity, highest cost | ✓ |

**User's choice:** Cookie cutout (Caelestia)
**Notes:** Chosen despite the option's own preview flagging that round 3's
feedback had already turned the cookie down once. Reconciled in CONTEXT.md rather
than treated as a contradiction: round 3's objection was to a cookie sitting
under a *static* ring; with the ring live, the cookie is the host shape those
bars were designed to orbit. Claude flagged that this re-opens round 4's
art-clipping bug, since the MultiEffect mask source becomes a hand-authored path
instead of a circular Rectangle.

---

## The cava visualiser — bar count and colour

| Option | Description | Selected |
|--------|-------------|----------|
| 60 (Caelestia's default) | `visualiserBars` default from serviceconfig.hpp; 5 bars per cookie lobe | ✓ |
| 56 (today's dash count) | The existing ring's dash/gap was tuned to land near 56 marks | |
| 24 (cava's current config) | What ags/cava/config already sets; fewer ShapePaths, visibly coarser | |

| Option | Description | Selected |
|--------|-------------|----------|
| Stay outline | No spec amendment; a recorded divergence from Caelestia's m3primary tint | |
| Accent, with a spec amendment | Add the visualiser to 14-UI-SPEC's enumerated accent list | ✓ |
| Outline at rest, accent on amplitude | Interpolate by band loudness; a third behaviour neither spec nor reference describes | |

**User's choice:** 60 bars; accent with a spec amendment
**Notes:** The spec amendment is recorded as a required deliverable, not an
implied one — the enumerated list in `14-UI-SPEC.md` must be edited, not left
contradicting the code.

---

## Cava lifecycle — placement and config location

| Option | Description | Selected |
|--------|-------------|----------|
| Dashboard Media tab only | Keeps one cava consumer and one lifecycle rule | |
| Media tab + bar popout | The popout is reachable without opening the drawer; two lifecycle owners for one process | ✓ |

| Option | Description | Selected |
|--------|-------------|----------|
| New cava/ stow package | `cava/.config/cava/config`, registered in stow.sh like every other package | ✓ |
| Inline args, no config file | Pass bars/framerate/output as argv from QML | |

**User's choice:** Media tab + bar popout; new cava/ stow package
**Notes:** These two were answered in a call whose third question the user
paused to clarify. Choosing both surfaces is what forced the shared-ownership
design in the lifecycle question below.

---

## Cava lifecycle — when the process is alive

The user paused this question to ask: *"Which option is better in terms of smooth
look vs performance?"* Claude answered with live measurements taken on this host
rather than an estimate:

| Measurement | 24 bars (today) | 60 bars (chosen) |
|---|---|---|
| CPU | 1.00% of one core | 1.20% of one core |
| RSS | 14.4 MB | 14.0 MB |
| Cold start → first frame | — | ~350 ms (348/352/353 across 3 runs) |

Plus: `Dashboard.qml` opens on `Motion.standardDuration` (200 ms), so a cold
spawn's first frame lands ~150 ms *after* the drawer has settled. The measurement
inverted the framing — performance was a non-issue, startup latency was the only
real variable — and produced a fourth option that was not in the original set.

| Option | Description | Selected |
|--------|-------------|----------|
| Refcount + linger (Recommended) | Either surface claims cava; dies a few seconds after the last releases | ✓ |
| Refcount, no linger | Dies instantly on last release; re-pays 350 ms on every reopen | |
| Dashboard/popout open, any tab | Spawns on surface open regardless of tab | |
| Always on | Today's behaviour; 1.2% of a core permanently, breaks the zero-idle rule | |

**User's choice:** Refcount + linger
**Notes:** Verbatim: *"Go with the recommended option (refcount + linger). I will
test it myself after it is done and if I don't like it I will revisit our option
of keeping it always on."* Recorded in CONTEXT.md as a binding design constraint
— always-on must be reachable by changing one knob, not by restructuring the
ownership model.

---

## The orphaned bash stack — script disposition

| Option | Description | Selected |
|--------|-------------|----------|
| Delete all three with ags (Recommended) | media-status.sh, media-players.sh and media-player.py in the same commit as the package | ✓ |
| Delete the two ags-orphans only | Leaves media-player.py, a pre-existing orphan, on disk | |
| Keep them as a CLI surface | Keeps a second MPRIS read path on disk | |

**User's choice:** Delete all three with ags
**Notes:** Precedent cited: eww's leftovers needed their own cleanup quick task
(`260725-vu6`) because they were left on disk. Claude corrected an earlier scout
error in the same message — `media-art-resolve.sh` **is** still live
(`MediaBackend.qml:242` builds its path by concatenation, which the first grep
truncated past), so it stays.

---

## The orphaned bash stack — test file and reader count

The user asked for these two to be re-explained: *"Elaborate and use human
readable terms and not gsd codes."* Both were re-presented in plain language —
what the hostile-input test actually simulates, what a request-forgery attack
through album art would look like, and what "one MPRIS reader" means — before the
question was re-asked.

| Option | Description | Selected |
|--------|-------------|----------|
| Keep the album-art tests only | Drop tests for deleted scripts, keep the network-forgery coverage | |
| Keep those, and cover the blank-art bug | Same trim, plus a test for the fragile path handoff that silently blanks album art | ✓ |
| Delete the whole test file | Cleanest diff, loses live SSRF coverage | |

| Option | Description | Selected |
|--------|-------------|----------|
| Check once, write it down | Before/after sweep recorded in the retirement record, as every prior deletion was proven | |
| Add a permanent automated check | Teach the diagnostic tool to count listeners and fail on more than one | ✓ |
| Both | Sweep for evidence, standing check for durability | |

**User's choice:** Keep those and cover the blank-art bug; add a permanent
automated check
**Notes:** Claude flagged a conflict rather than resolving it silently — the
roadmap's success criterion 3 names the before/after sweep as part of the
deletion itself. Recorded in CONTEXT.md as: the sweep still runs because every
retirement here runs one, and the standing check is what makes the guarantee
durable.

---

## Entry point after the card

| Option | Description | Selected |
|--------|-------------|----------|
| Super+M → dashboard on Media tab | Matches the one-letter-per-surface pattern; uses the existing initialTabIndex parameter | ✓ |
| Super+M → bar's media popout | Closer to what the card felt like; popouts are click-driven so needs a new path | |
| No new shortcut | Media stays reachable the two ways it already is | |

**User's choice:** Super+M → dashboard on Media tab
**Notes:** `M` was verified free before the question was asked (bound letters:
A B C D E F I L N O P Q R S T V W X Y Z). Claude noted the new global shortcut
needs a matching manifest row for the keybind cross-check contract.

---

## QMEDIA-01 parity gap

| Option | Description | Selected |
|--------|-------------|----------|
| Fold in duplicate-player dedup | Collapse near-identical entries by title match or position/length proximity | ✓ |
| Defer it | Not something the card did either, so leaving it out is not a regression | |

| Option | Description | Selected |
|--------|-------------|----------|
| One slider, follows selection | What both the card and the tab already do; requirement already met | |
| A volume control per player | Every player in the switcher gets its own level | ✓ |

| Option | Description | Selected |
|--------|-------------|----------|
| Build it before deleting | Card is not removed until the tab covers everything it did | ✓ |
| Show it to me and decide | Each gap surfaced individually with its cost | |
| Record as accepted loss | Anything not already in the tab is deliberately dropped | |

**User's choice:** Fold in dedup; per-player volume controls; build gaps before
deleting
**Notes:** Claude flagged the volume answer plainly as new capability rather than
parity — neither reference shell has per-player volume and the card did not
either — and noted it interacts with the dedup decision, since collapsing two
entries merges two independently controllable volumes. Recorded as a required
UI-phase resolution.

Claude also noted that the live card can still be summoned via
`ags request -i media toggle-media` since the daemon is running, so the
behavioural enumeration needs no keybind restoration.

---

## LEDGER-06 paperwork

| Option | Description | Selected |
|--------|-------------|----------|
| As it stood at the time | Reconstruct from the eight summaries, UAT record and measurement doc | ✓ |
| As it stood, with later fixes noted | Same, but each gap annotated with whether something since closed it | |
| Verify against today's code | Run the verifier fresh; a report about a phase four phases stale | |

| Option | Description | Selected |
|--------|-------------|----------|
| Fix the two files | Correct the illegal status value and the three missing explanations | ✓ |
| Fix them, and add a validator | Same fix plus a check that rejects malformed blocks at write time | |

| Option | Description | Selected |
|--------|-------------|----------|
| Close as already done | Record that the Lua config migration is complete, point at evidence, clear the row | ✓ |
| Recreate and re-do it | Rebuild the task from its title and carry it out | |

**User's choice:** Historical reconstruction; fix the two files; close the quick
task as done
**Notes:** Presented with the specific facts first — which two files carry which
malformed field, that the quick task's folder does not exist at all so only its
title survives, and that Phase 16's gradient-rim gap has since been fixed in
Phase 20 (which under the chosen option is deliberately *not* folded into the
report).

---

## RETIRE-08 contract close

| Option | Description | Selected |
|--------|-------------|----------|
| Rewrite without the name (Recommended) | Keep every finding, drop the dead surface's name, cite the recording plan where provenance matters | ✓ |
| Scrub them entirely | Delete all mentions; loses the recorded reason live surfaces carry their alpha values | |
| Keep them, exempt the sweep | Most faithful record; permanent comment-only blind spot in the leftover-detection tool | |

| Option | Description | Selected |
|--------|-------------|----------|
| Same as Phase 20 — attestation | Operator confirms, checkers' green run is the evidence | |
| Run the verifier | This phase closes the contract and lands the last deletion before the fresh-install proof | ✓ |

**User's choice:** Rewrite without the name; run the verifier
**Notes:** The user paused on the comments question and asked *"which option do
you recommend"*. Claude recommended rewriting, with reasoning specific to this
repo: the comments document a failure mode that has already prevented a
misdiagnosis, and exempting the sweep would institutionalise a blind spot
immediately before the phase that rebuilds the machine from scratch.

Claude also corrected a package-disposition trap in the same area:
**`dart-sass` must stay.** Its install.sh comment blames AGS entirely, but
`stow.sh:417-464` uses `sass` to seed the compiled GTK3 stylesheets at install
time. Removing it would leave GTK surfaces unstyled on a fresh install.

---

## Frost unification (folded todo)

| Option | Description | Selected |
|--------|-------------|----------|
| One value everywhere | Dashboard and overview come down to the notification/OSD threshold | ✓ |
| Two tiers, deliberately | Transient pills lighter; full-surface panels share one heavier value | |
| Keep as-is, write down why | Three values stand, each justified in a comment | |

**User's choice:** One value everywhere
**Notes:** Presented with the measured 2026-08-15 table and two constraints: fill
alpha and threshold must be chosen together (a fill at or below the threshold
silently discards blur), and the result cannot be trusted from config alone
because `hyprctl reload` silently drops layer-rule edits.

---

## The deletion gate

| Option | Description | Selected |
|--------|-------------|----------|
| Look-at-it gate on the new surface | Cookie shape and live ring approved before the package goes | |
| Parity checklist only | Behaviour parity unlocks the deletion without a separate look | |
| Both, as one gate | One sitting, one verdict covering checklist and look together | ✓ |

**User's choice:** Both, as one gate
**Notes:** Phase 20 ran two independent gates because its two surfaces shared no
backend; here there is one surface, so a single combined gate avoids two approval
rounds for one thing.

---

## The DND indicator (folded todo)

| Option | Description | Selected |
|--------|-------------|----------|
| Accent dot on the bell | Small accent dot at the glyph's corner; survives vertical layout untouched; weakest cue | |
| Tint the whole capsule | The clock/actions capsule takes an accent tint while DND is active; reads as a mode | ✓ |
| A separate DND chip | Labelled pill; clearest to read, but changes bar layout on toggle and fights the vertical glyph-only mode | |

**User's choice:** Tint the whole capsule
**Notes:** Presented as rendered ASCII previews of the bar in both states. The
option's own preview named its cost — the capsule also holds the clock, so this
is a long-lived colour change in the busiest part of the bar — and stated that if
it reads as loud, the fix is tuning tint strength rather than rethinking the
approach. That framing is carried into CONTEXT.md.

---

## Todo folding

Three pending todos matched Phase 21 on generic keywords (bar, qml, surface,
overview). None were media- or contract-related.

| Todo | Folded |
|---|---|
| Unify dashboard and overview frost values with OSD/notifications | ✓ |
| Ambient DND indicator — bell glyph swap is too easy to miss | ✓ |
| Brightness OSD path cannot be verified on this host — laptop-only, unproven | |

**Notes:** Claude flagged that the DND indicator is a bar-module concern outside
the roadmap's media/contract boundary for this phase, and recorded it as
folded-with-a-note: the planner should size it as its own small plan rather than
attach it to a media or retirement plan.

---

## Claude's Discretion

- Exact linger duration for the cava refcount.
- Bar geometry inside the ring — inner radius, bar width, cap style, minimum
  sliver length at silence.
- Exact lobe depth and corner rounding of the 12-lobe cookie path.
- cava's `framerate` in the new config.
- Whether the listener-count check lands in `quickshell-doctor` or
  `retirement-check`.
- Final wording of the rewritten comments.
- The exact single frost value and the fill/threshold pair that carries it.
- The DND capsule's tint strength.

## Deferred Ideas

- Lyrics display — no lyrics service exists in this backend.
- Shuffle and repeat transport — the verb-allowlist blocker disappears with
  `media-players.sh`, but it is not in this phase's requirements.
- Per-track dominant-colour re-tinting — permanently excluded, not deferred.
- Decorative mascot GIFs — needs an asset path outside theme-engine.
- The `BackgroundShapes` bokeh layer — needs a general shape renderer, not the
  one hand-authored shape this phase builds.
- A validator for malformed `coverage:` blocks — declined as new tooling for a
  problem that stopped recurring.
- Annotating Phase 16's report with later phases' fixes — belongs in a milestone
  audit, not a phase's own verification report.
- The OVER-04 frame-rate floor measurement — still open, still needs an owning
  phase.
- The remaining WINDOWS.md rows — batch re-deferred under Phase 20's D-20-40.
