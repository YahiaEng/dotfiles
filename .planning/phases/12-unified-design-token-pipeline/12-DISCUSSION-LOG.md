# Phase 12: Unified Design-Token Pipeline - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-26
**Phase:** 12-Unified Design-Token Pipeline
**Areas discussed:** Motion token source & emission, Live QML surface + per-screen fan-out, Reduced-motion axis, Motion lint & fidelity ceiling, Engine-owned state survival, First-boot seeding, theme-parity and theme-independent output, Plan sequencing and waves

**Discussion character:** the user asked repeatedly for deeper pros/cons and an explicit
recommendation on each decision, and made that a standing request partway through. Several
recommendations were revised mid-discussion when empirical testing contradicted them — most
notably the Hyprland `source =` placement, where a `--verify-config` test invalidated the
premise of a recommendation already given.

---

## Motion token source & emission

### Where the renderer lives

| Option | Description | Selected |
|--------|-------------|----------|
| `lib/motion.sh`, font.sh pattern | Theme-orthogonal axis; sibling writer inside `theme_engine_generate`; reduced-motion becomes a bash value transform | ✓ |
| Ride matugen via `--import-json` | Verified available on matugen 4.1.0; uniform template mechanism; needs import-semantics verification and `{% if %}` branching across three dialects | |
| You decide | | |

**User's choice:** `lib/motion.sh`, font.sh pattern.
**Notes:** The user asked for expanded pros/cons before answering. Reading `font.sh` changed
the recommendation — `generate.sh` already contains two non-matugen writers, so this is a
third sibling rather than a second pipeline. The decisive factor was TOKEN-05's value
transformation, not TOKEN-03's emission.

### Guard placement for malformed curves

| Option | Description | Selected |
|--------|-------------|----------|
| All three | Render-time validation + `hyprctl animations -j` readback + poisoned fixture | ✓ |
| Render-time + readback, no fixture | Skip proving the readback can fail | |
| Readback + fixture, no render-time | Guard only the introspectable target | |
| You decide | | |

**User's choice:** All three.
**Notes:** The user challenged the original framing, which presented three composable guards
as if they were alternatives on one axis. Reframed around three non-overlapping failure
modes. The decisive argument was that `hyprctl` covers only one of three targets, leaving
QML and GTK4 — including GTK4's known silent single-rule drop — unguarded.

### contract.json registration

| Option | Description | Selected |
|--------|-------------|----------|
| Full `files` entries with formats | Format-validated by theme-parity like the 17 colour files | ✓ |
| `presence_only_files`, like font fragments | Existence-checked only | |
| You decide | | |

**User's choice:** Full `files` entries.
**Notes:** Established during discussion that theme-parity validates the file at its path
regardless of which writer produced it, so option A's apparent "already validated" advantage
over a separate renderer was not real.

### How far into animations.conf

| Option | Description | Selected |
|--------|-------------|----------|
| Curves only, assignments stay | Phase 12 owns the pipeline, Phase 13 the retrofit | ✓ |
| Curves + rewire all assignments | Finishes Hyprland entirely | |
| Curves + one proof assignment | One end-to-end demonstration | |
| You decide | | |

**User's choice:** Curves only.

### motion.json schema shape

| Option | Description | Selected |
|--------|-------------|----------|
| Two-layer: durations + easings, then semantic pairs | Maps one-to-one onto Hyprland's own model | ✓ |
| Flat: one self-contained record per token | Simplest to author; duplicates curves | |
| You decide | | |

**User's choice:** Two-layer.

### Runtime tunability

| Option | Description | Selected |
|--------|-------------|----------|
| Repo-authored only, reduced-motion sole runtime axis | *(Recommended)* Keeps to TOKEN-05's wording | |
| Add a runtime speed-scale axis too | Expands past TOKEN-05; reduced-motion becomes a preset | ✓ |
| You decide | | |

**User's choice:** Add a runtime speed-scale axis — **against the recommendation.**
**Notes:** Deliberate expansion, chosen after the cost was explicitly flagged. Followed
immediately by a bounding question to contain what it drags in.

### How much of the scale axis to build

| Option | Description | Selected |
|--------|-------------|----------|
| State file + CLI only, no picker | Whole mechanism built and proven; presentation deferred | ✓ |
| Full picker wired into settings menu now | Complete and usable immediately | |
| You decide | | |

**User's choice:** State file + CLI only.

### What "reduced" means mechanically

| Option | Description | Selected |
|--------|-------------|----------|
| Scale durations, plus a distinct "off" that disables | Two mechanisms, two user intents | ✓ |
| Pure multiplier, zero means instant | One uniform mechanism | |
| You decide | | |

**User's choice:** Scale plus a distinct off.

### Rounding / collapse guard

| Option | Description | Selected |
|--------|-------------|----------|
| Clamp to non-zero, warn on collapse | Zero invites silent default substitution; collapse is imperceptible at low scale | ✓ |
| Strict — fail on any collapse | Makes low scale values unusable | |
| No guard | | |
| You decide | | |

**User's choice:** Clamp to non-zero, warn on collapse.

---

## Live QML surface + per-screen fan-out

### What surface proves criterion 1

| Option | Description | Selected |
|--------|-------------|----------|
| The summoned probe, styled from the palette | Root stays headless; fulfils Phase 11's D-04 handoff | ✓ |
| Ship a small permanent visible surface | Self-evident proof; contradicts D-02 and Phase 14's billing | |
| You decide | | |

**User's choice:** The summoned probe, styled.
**Notes:** Surfaced afterwards that this partially undercuts the roadmap's stated rationale
for moving QS-03 into Phase 12 — recorded in CONTEXT.md rather than left implicit.

### QML palette format

| Option | Description | Selected |
|--------|-------------|----------|
| JSON + repo-authored Singleton wrapper | Live in-place rebinding, animatable crossfade, existing json handler, avoids qmldir exposure | ✓ |
| JSON, consumers read the adapter directly | No wrapper layer; derived tokens redefined per use site | |
| Generated QML singleton | end-4/Caelestia shape; document reload means hard cut and discarded state | |
| You decide | | |

**User's choice:** JSON + Singleton wrapper.
**Notes:** The user rejected the first framing with *"I do not want to sacrifice graphic
fidelity."* Answered directly: transport format has zero effect on colour precision — both
paths deliver identical hex into the same QML `color` type — but it decides whether a theme
switch can animate. Verified `Quickshell/Singleton 0.0` in the installed qmltypes, which
dissolved the ergonomics tradeoff entirely.

### QS-03 re-attempt strategy

| Option | Description | Selected |
|--------|-------------|----------|
| Targeted fix, bounded, spike as escape hatch | Checked-in qmldir against FM1, LazyLoader-per-screen against FM2 | ✓ |
| Dedicated spike first, then implement | What the evidence file itself suggests | |
| Sidestep Variants entirely | Avoids the construct that broke; non-standard root | |
| You decide | | |

**User's choice:** Targeted fix, bounded.
**Notes:** Confirmed quickshell 0.3.0-2 is the latest in `extra`, so waiting for upstream
was not an option. Confirmed no `qmldir` exists on disk, making the checked-in-qmldir
hypothesis a targeted strike at FM1's documented root cause.

### Disposition if QS-03 fails twice

| Option | Description | Selected |
|--------|-------------|----------|
| Blocks Phase 12 close | *(Recommended)* Avoids shipping a permanently red gate | |
| Record and continue, hard gate before Phase 14 | House rule with a named gate | |
| Accept as a permanent limitation | Formally dropped; single-monitor host | ✓ |
| You decide | | |

**User's choice:** Accept as a permanent limitation — **against the recommendation.**
**Notes:** Accepted without re-litigation. Two consequences recorded so it lands cleanly
rather than as silent rot: the requirement moves to Out of Scope rather than deferring a
second time, and ROADMAP criterion 6 needs amending under the D-15 precedent. A follow-up
question then resolved the red-gate corrosion risk the choice left open.

### How quickshell-doctor represents the limitation

| Option | Description | Selected |
|--------|-------------|----------|
| Documented SKIP, script exits 0 | Keeps the gate credible; limitation visible in every run | ✓ |
| Remove the check entirely | Nothing reminds anyone the hole exists | |
| Keep it failing, exit 1 | Standing-red-gate outcome | |
| You decide | | |

**User's choice:** Documented SKIP.

### Preserving D-04's "never pretty" intent

| Option | Description | Selected |
|--------|-------------|----------|
| Make it a token inspector | Diagnostic by content; doubles as the criterion 4 and 5 instrument | ✓ |
| Minimal styling only | Cannot catch a mis-mapped token | |
| You decide | | |

**User's choice:** Token inspector.

### What animates for criterion 4

| Option | Description | Selected |
|--------|-------------|----------|
| Both the theme crossfade and a replay row | Real behaviour plus a fast repeatable trigger | ✓ |
| The theme crossfade only | Every re-check costs a full theme switch | |
| Replay row only | Nothing proves tokens govern real behaviour | |
| You decide | | |

**User's choice:** Both.

### Proving live re-colour

| Option | Description | Selected |
|--------|-------------|----------|
| Fold into theme-stress-test's consecutive switches | Catches a watch that dies after switch 1 | ✓ |
| Single-switch proof plus a defensive re-arm | Builds a mitigation for an unconfirmed problem | |
| You decide | | |

**User's choice:** Fold into theme-stress-test.
**Notes:** Raised after finding `commit.sh` uses `rsync` without `--inplace`, so writes are
atomic by temp-then-rename — which changes the inode and commonly breaks path-based
watchers. Phase 11 proved propagation via hand-edits, which may have written in place.

### Reload fan-out

| Option | Description | Selected |
|--------|-------------|----------|
| No quickshell step | A reload would rebuild the surface and destroy the crossfade | ✓ |
| Add a quickshell reload step now | Uniform with the other five surfaces | |
| You decide | | |

**User's choice:** No quickshell step.

---

## Reduced-motion axis

### GTK proof surface

| Option | Description | Selected |
|--------|-------------|----------|
| wleave | GTK4; already hand-copies Hyprland's md3_decel; Phase 13 opens it anyway | ✓ |
| swaync | Smallest at 6 values; GTK3 | |
| waybar | Most visible; GTK3, four layouts, two extra gates | |
| You decide | | |

**User's choice:** wleave.

### System-wide GSettings

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — "off" also sets `enable-animations false` | Third-party GTK/libadwaita apps respect it | ✓ |
| No — keep the axis to repo-authored surfaces | Cleaner blast radius | |
| You decide | | |

**User's choice:** Yes.

### Scale value representation

| Option | Description | Selected |
|--------|-------------|----------|
| Named presets, mapping table in motion.json | No sentinel overload; matches every existing state file; fits the list-picker shape | ✓ |
| Raw multiplier float | Granular; needs `0` overloaded to mean toolkit-disabled | |
| Both — names over a stored float | Inherits the sentinel problem and loses self-description | |
| You decide | | |

**User's choice:** Named presets.
**Notes:** The user asked for deeper analysis. That pass produced the decisive argument — D-08
made "off" categorically different from a small multiplier, so a float requires a magic
sentinel — and also revised the recommendation to put the mapping table in `motion.json`
rather than in `motion.sh`. Option C was honestly reassessed as strictly weaker than
presented.

### Hyprland off-state lever

| Option | Description | Selected |
|--------|-------------|----------|
| `animations.conf` reads `enabled = $motion_enabled` | Explicit at the use site; same risk profile as existing colour vars | ✓ |
| `animations.conf` drops `enabled`, generated block owns it | No indirection; invisible action-at-a-distance | |
| Source motion after animations.conf, rely on last-wins | Unproven runtime semantics; breaks Phase 13 ordering | |
| You decide | | |

**User's choice:** Variable reference.
**Notes:** The user asked for deeper analysis, prompting eight empirical `--verify-config`
tests. **Test A failed and invalidated the premise of the recommendation already given** —
`source =` cannot appear inside a category block. Test E then established that curves must
precede use, forcing the motion file before `animations.conf`, which in turn forced the
lever out of the generated block. The final recommendation reached the same option as before
but for entirely different and now-verified reasons.

---

## Motion lint & fidelity ceiling

### Enforcement scoping

| Option | Description | Selected |
|--------|-------------|----------|
| Deny by default, exemptions with reasons | Covers new Phase 14–17 surfaces automatically; debt visible; checklist shrinks to zero | ✓ |
| Opt-in registry of token-consuming files | Zero false positives; new surfaces silently unlinted | |
| You decide | | |

**User's choice:** Deny by default.
**Notes:** The user asked for deeper pros/cons and made that a standing request for all
remaining decisions. Answering it required first establishing *how* a GTK stylesheet consumes
a token at all, which produced the GTK4-has-custom-properties / GTK3-does-not finding and
made roadmap open question #2 moot.

### Token vocabulary

| Option | Description | Selected |
|--------|-------------|----------|
| Full duration + easing scales, trimmed semantic layer | Scales are inert data; semantics are taste decisions earned per phase | ✓ |
| Trimmed everywhere | Subset becomes an invention rather than a scale | |
| Full MD3 set at both layers | Seeded-empty-tree pattern Phase 11's D-19 rejected | |
| You decide | | |

**User's choice:** Full scales, trimmed semantics.

### TOKEN-06 stretch

| Option | Description | Selected |
|--------|-------------|----------|
| Attempt it, bounded to a recorded verdict | Instrument already exists; adopting springs stays a later phase's work | ✓ |
| Drop it from Phase 12 | Standing constraint 5 sanctions this | |
| Attempt only if the phase runs ahead | "If there's time" work reliably does not happen | |
| You decide | | |

**User's choice:** Attempt it, bounded.

### Human gate placement

| Option | Description | Selected |
|--------|-------------|----------|
| Per-plan gates, per the standing constraint | More specific than the config default; written out of the Phase 6/8 failures | ✓ |
| One end-of-phase gate, per config | Fewer interruptions | |
| Per-plan for the inspector, end-of-phase for wleave | Gates the surface needing it least | |
| You decide | | |

**User's choice:** Per-plan gates.
**Notes:** Surfaced as a genuine conflict between ROADMAP standing constraint 1 and
`config.json`'s `human_verify_mode: "end-of-phase"` rather than resolved silently.

### Poisoned fixture construction

| Option | Description | Selected |
|--------|-------------|----------|
| Committed fixtures via path argument, derived from real surfaces | Double precedent; zero risk to live config; rerunnable | ✓ |
| Temporarily poison a real surface, then revert | Matches criterion wording literally; git-clean hazard | |
| Both fixtures and a one-time real poisoning | Carries the hazard for a check derivation already provides | |
| You decide | | |

**User's choice:** Committed fixtures.

### Reference resolution check

| Option | Description | Selected |
|--------|-------------|----------|
| Both — no raw values AND every reference resolves | The raw-value check alone manufactures the failure it cannot see | ✓ |
| No-raw-values only | Exactly TOKEN-04's wording | |
| You decide | | |

**User's choice:** Both.

---

## Engine-owned state survival

| Option | Description | Selected |
|--------|-------------|----------|
| Manifest-driven excludes + classification gate | One array drives both; occurrence #7 becomes loud instead of silent | ✓ |
| Just add the sixth exclude line | The status quo that has failed five times | |
| Segregate engine state into its own subdirectory | Impossible by construction; eight paths move, wide blast radius | |
| You decide | | |

**User's choice:** Manifest-driven.
**Notes:** Raised after reading `commit.sh`'s exclusion comment block, which self-documents
the bug class as recurring — "CR-01 (same bug class, third occurrence)" — across eight paths
and five incidents. D-21's motion-scale state file is exactly that shape.

---

## First-boot seeding

| Option | Description | Selected |
|--------|-------------|----------|
| Seed-only-when-absent, generated by motion.sh | Guards the compositor failing to start; one source of truth | ✓ |
| Rely on the existing theme-apply seed | Consistent; but that call is `\|\| true` guarded | |
| Hand-written minimal stub in stow.sh | Drifts from motion.json; goes wrong in Phase 13 | |
| You decide | | |

**User's choice:** Seed-only-when-absent via motion.sh.
**Notes:** Grounded first: `stow.sh:135` already runs theme-apply at install and
`hyprland.conf:16` already sources a state file, so the exposure exists today for colour.
Decided on the severity asymmetry plus the `waybar-visibility.css` precedent, which guards a
strictly less severe failure.

---

## theme-parity and theme-independent output

| Option | Description | Selected |
|--------|-------------|----------|
| Byte-identity across all palettes and both branches | Strongest and cheapest; only check guarding palette-independence | ✓ |
| Standard structural parity, same as colour files | Uniform; would not catch mode-dependence | |
| Presence-only, like the font fragments | Contradicts D-03 | |
| You decide | | |

**User's choice:** Byte-identity.
**Notes:** Working this through inverted the initial read — the assertions were framed as
possibly vacuous and turned out to guard three things, two of which nothing else covers.

---

## Plan sequencing and waves

| Option | Description | Selected |
|--------|-------------|----------|
| QS-03 first, on the plain probe | Debug the scanner race against the simplest surface | ✓ |
| Inspector rewrite first, then fan-out | Delivers visible proof earliest | |
| You decide | | |

**User's choice:** QS-03 first.
**Notes:** Parallelisation was ruled out on discovering both work items modify `shell.qml`
and `modules/Probe.qml`.

---

## Claude's Discretion

The user chose "You decide" on no question. Discretion recorded in CONTEXT.md was assigned
by scope rather than deferral:

- Exact filenames for the three motion render targets and the scale state file
- Precise semantic token names in the trimmed semantic layer
- Whether the motion lint lives beside `waybar-design-lint` or in `theme-engine/`
- Exemption-list format and location
- Fixture file naming and layout
- The bounded budget for the QS-03 targeted fix before escalating to a spike
- Plan and wave decomposition within the stated ordering constraints

## Deferred Ideas

- Graphical motion-scale picker plus its Super-key settings menu entry
- `@define-color` deprecation in GTK4 4.22.4 — affects the existing colour pipeline
- GTK3 surfaces cannot consume motion tokens by variable — Phase 13 inherits the mechanism
  question for waybar, swaync and SwayOSD
- Adopting spring physics across QML surfaces if criterion 5 favours them
- Wholesale segregation of engine-owned state into its own subdirectory
- A real second-display hotplug test with genuine EDID negotiation
