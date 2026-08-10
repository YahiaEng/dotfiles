# Phase 13: Motion Retrofit & Existing-Surface Sweep - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-27
**Phase:** 13-motion-retrofit-existing-surface-sweep
**Areas discussed:** GTK3 token mechanism, Zero-motion surfaces, Hyprland retrofit depth, Multi-day soak gate, current.jpg / stress-test, MAINT-03 icon browse, MAINT-02 WR-01..04, MD3 sourcing, Render gate structure, Phase size & ordering, Exemption end state, Token mapping, Waybar layout vocabulary, Pipeline integration

**Mode note:** The user requested trade-off analysis with an explicit recommendation
before every decision (the `--analyze` overlay behaviour), applied from the first
question onward.

---

## GTK3 Token Mechanism

| Option | Description | Selected |
|--------|-------------|----------|
| Sass precompile | Repo authors .scss; motion.sh emits _motion.scss; theme-apply compiles to state dir; surfaces launch pointed there | ✓ |
| Sass, waybar only | Same mechanism scoped to waybar's 31 literals; swaync and SwayOSD recorded as permanent exemptions | |
| Engine emits literal rules | gtk-3.0-motion.css with complete rules @imported last; nothing moves, but selectors move into the engine | |
| Record the limitation | Keep all three exemptions permanently; amend MOTION-02 / criterion 1 to GTK4 + Hyprland | |

**User's choice:** Sass precompile
**Notes:** Verified during discussion that the two costs which would normally sink
this are already paid — `swaync -s/--style`, `swayosd-server -s/--style` and
`waybar -s` all exist on installed binaries, and `dart-sass` is already a hard
`install.sh` dependency. Scope was later narrowed to waybar + swaync (see
Zero-motion surfaces).

---

| Option | Description | Selected |
|--------|-------------|----------|
| Keep colour @import | Compiled sheet bakes in motion only; colour stays a live import | ✓ |
| Inline colour too | One self-contained sheet per surface | |

**User's choice:** Keep colour @import
**Notes:** Preserves the reload path, theme-parity's colour walk, and D-31's
motion-independent-of-colour byte-identity assertion, which inlining would break.

---

| Option | Description | Selected |
|--------|-------------|----------|
| File-for-file | All six waybar files convert; @import url() links survive sibling-relative | ✓ |
| Inline shared partials | theme + waybar-modules inlined into each of four compiled layouts | |

**User's choice:** File-for-file
**Notes:** Decided by `waybar-visibility.css`, which is rewritten at runtime by a
separate script — inlining risks freezing that live channel. Also avoids reproducing,
in the output, the four-copies duplication `waybar-equivalence-check` exists to catch.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Seed via compiler, fail loud | stow.sh invokes the real compile path; failure is loud | ✓ |
| Seed via compiler, stay soft | Same seeding under stow.sh's existing `|| true` tolerance | |
| Commit a default sheet | Ship a pre-compiled fallback in the repo | |

**User's choice:** Seed via compiler, fail loud
**Notes:** D-30 mirror with a wider blast radius. A silently unstyled desktop with no
error to search for is worse than a failed install.

---

## Zero-motion Surfaces

| Option | Description | Selected |
|--------|-------------|----------|
| Compositor-owned only | `animation = layers` already animates them; MOTION-01's retrofit makes them token-driven with no client change | ✓ |
| Add client-side motion | Design internal interaction feedback for all three | |
| Hybrid, decided in execution | Compositor-owned plus client motion where feedback is visibly lacking | |

**User's choice:** Compositor-owned only
**Notes:** Reframed by the discovery of `animations.conf:47` — walker, SwayOSD and the
AGS card were never motionless. In-surface motion deferred to Phase 14 so the
vocabulary is designed once on QML rather than twice.

---

| Option | Description | Selected |
|--------|-------------|----------|
| waybar + swaync only | SwayOSD keeps a permanent exemption; it has zero motion literals | ✓ |
| Convert all three | Uniform structure across every GTK3 surface | |
| waybar only | Leaves swaync's six literals raw | |

**User's choice:** waybar + swaync only
**Notes:** Raised as a consequence of the previous answer — converting a file with
nothing to tokenize adds a fresh-install failure path with no coverage behind it.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Split layersIn/layersOut | Consumes motion.json's already-defined, currently-unused emphasized-in / emphasized-out | ✓ |
| Split + style vocabulary now | Also assign per-namespace styles up front | |
| Keep one layers entry | One token pair for both entrance and exit | |

**User's choice:** Split layersIn/layersOut
**Notes:** Four `--verify-config` probes established that per-namespace overrides can
set **style only** — duration and curve are forced to come from the global entry, so
the shared language is structurally enforced. Per-namespace styles left to the render
gate rather than pre-decided.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Fold into the sweep | Delete the dead wofi layerrules (windowrules.conf:187,263) | ✓ |
| Note only, don't touch | Record as a deferred idea / broken-window entry | |

**User's choice:** Fold into the sweep

---

## Hyprland Retrofit Depth

| Option | Description | Selected |
|--------|-------------|----------|
| Promote character curves (recommended) | The 5 character curves keep exact control points but move into motion.json; zero perceptual change | |
| Swap duplicates only | Replace the 4 byte-identical duplicates; leave 5 hand-authored under exemption | |
| MD3 purity | Replace the character curves with MD3 equivalents | ✓ |

**User's choice:** MD3 purity — **chosen against the recommendation**
**Notes:** Recorded risk, accepted knowingly: this deliberately changes how window
open/close/move and fades feel on a daily-driver desktop, since the current curves
carry intentional overshoot and undershoot. The render gate and soak are the
instruments that judge it. Bezier audit surfaced during this area: 4 of 12 beziers are
byte-identical duplicates feeding 7 of 13 animation lines; 3 are declared and never
referenced.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Grow the scale first | Source and add the full MD3 easing set before mapping | ✓ |
| Map onto the existing four | Reuse the four current easings for all 13 animation lines | |

**User's choice:** Grow the scale first

---

| Option | Description | Selected |
|--------|-------------|----------|
| Promote that one curve (recommended) | A rejected motion's original curve moves verbatim into motion.json | |
| Tune within MD3 only | Re-map to a different MD3 curve or duration, never back to hand-authored | ✓ |
| Revert the whole decision | A rejection on any motion reverts Hyprland wholesale | |

**User's choice:** Tune within MD3 only — **chosen against the recommendation**
**Notes:** A firm purity position. This is what makes the character-curve deletion
irreversible, and it is why the pre-authorized namespaced extension (see MD3 sourcing)
was later raised and accepted as the one sanctioned landing spot.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Extreme-value observation | Set one animation to a huge speed, watch once, confirm magnitude | ✓ |
| Timed capture | Rapid grim frames or known-fps recording | |
| Trust docs + readback assert | Assume 1ds = 100ms and assert via the existing readback gate | |

**User's choice:** Extreme-value observation
**Notes:** Closes Phase 12's D-09. Smallest test that can actually fail; guards
against the hyprlock-0.9.5 / `walker -s` class where documentation was trusted over
the binary.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Stay hand-authored | Style keywords are spatial transforms, not tokens; no GTK4/QML counterpart | ✓ |
| Add a Hyprland-only style layer | motion.json gains a target-specific layer | |

**User's choice:** Stay hand-authored

---

## Multi-day Soak Gate

| Option | Description | Selected |
|--------|-------------|----------|
| Front-load the motion change | Motion lands in plan 1; soak accrues while other work proceeds | ✓ |
| Blocking soak at the end | Final plan cannot close until the period is logged | |
| Close with a deferred item | Record via the 11-VERIFICATION.md overrides pattern | |

**User's choice:** Front-load the motion change
**Notes:** Phase 14 does not depend on Phase 13 (independent branches per the
roadmap), so an open Phase 13 does not block the milestone. Plan order becomes a fixed
constraint in CONTEXT.md.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Fixed day count | A hard minimum in calendar days | |
| Session/interaction count | A minimum number of real sessions or observed interactions | ✓ |
| Whichever comes later | Both floors must be met | |

**User's choice:** Session/interaction count
**Notes:** Closer to what criterion 3 cares about, and immune to a day away from the
machine. Consequence carried into the descope discussion: the floor is incompressible.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Per-motion verdict table | One row per retrofitted motion with verdict and note | ✓ |
| Freeform daily notes | Low-friction prose | |
| Single end-of-soak verdict | One pass/fail | |

**User's choice:** Per-motion verdict table

---

| Option | Description | Selected |
|--------|-------------|----------|
| Ship it, remove at close | A/B toggle between pre-retrofit and MD3 curve sets as a temporary instrument | ✓ |
| Ship it, keep permanently | Retained after the phase like Phase 12's spring toggle | |
| No toggle | Judge the feel change against memory | |

**User's choice:** Ship it, remove at close
**Notes:** Addresses acclimatization — an absolute verdict days after a change
measures adaptation, not quality.

---

## current.jpg / theme-stress-test (WINDOWS #9)

| Option | Description | Selected |
|--------|-------------|----------|
| Untrack + seed | git rm --cached, gitignore, seed at install pointing at today's committed target | ✓ |
| Exempt the path | One narrow exemption in theme-doctor's clean-tree check | |
| Both | Untrack and seed, plus keep an exemption as a guard | |

**User's choice:** Untrack + seed
**Notes:** Decided by the structural finding that `~/Pictures/Wallpapers` resolves into
the repo working tree — `current.jpg` is runtime state committed to git, rewritten by
five code paths and read by two (including Material You's matugen source).

---

| Option | Description | Selected |
|--------|-------------|----------|
| Blocking closing gate | Full 10/10 theme-stress-test required to close the phase | ✓ |
| Run it, non-blocking | Record the result without gating close | |

**User's choice:** Blocking closing gate

---

| Option | Description | Selected |
|--------|-------------|----------|
| Reconcile stale + own | Mark 1, 2, 8, 9 resolved; open_count 9 → 5 | ✓ |
| Only this phase's own | Close 8 and 9; leave 1 and 2 | |
| Leave the ledger alone | No bookkeeping in a motion phase | |

**User's choice:** Reconcile stale + own
**Notes:** Items 1 and 2 are already fixed in reality per STATE.md and were never
marked; item 8 resolves when this phase rewrites animations.conf.

---

## MAINT-03 Icon Browse

| Option | Description | Selected |
|--------|-------------|----------|
| Ctrl-A toggle in the picker | Reuses THM-04's wallpaper-picker browse-all pattern | ✓ |
| Separate install entry | A distinct surface in the Super-key menu | |
| One merged list | Installed and available together, uninstalled marked | |

**User's choice:** Ctrl-A toggle in the picker

---

| Option | Description | Selected |
|--------|-------------|----------|
| Package metadata (recommended) | pacman -Si / paru -Si text in the preview pane | |
| Bundled screenshots | Ship or fetch preview images per theme | ✓ |
| Nothing / blank pane | Leave the preview empty in browse mode | |

**User's choice:** Bundled screenshots — **chosen against the recommendation**
**Notes:** Prompted a follow-up on sourcing, which found a better path than bundling
(see next entry).

---

| Option | Description | Selected |
|--------|-------------|----------|
| Fetch & extract real icons | pacman -Sp gives the URL without root; bsdtar extracts; existing montage pipeline renders | ✓ |
| Commit curated screenshots | Ship preview images for a hand-picked set | |
| Hybrid | Fetch for repo packages, commit for marquee AUR themes | |

**User's choice:** Fetch & extract real icons
**Notes:** Verified live that `pacman -Sp` prints the package URL without root and
`bsdtar 3.8.8` is installed. Delivers the requested real visual preview while removing
the sourcing and staleness problem that made bundling questionable. AUR falls back to
package metadata.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Included by default | AUR in browse results from the start | ✓ |
| Behind a second toggle | Repo first, a further keypress adds AUR | |
| Repos only | No AUR at all | |

**User's choice:** Included by default

---

## MAINT-02 WR-01..04

| Option | Description | Selected |
|--------|-------------|----------|
| Verify, then wrap or document | Test whether uwsm stop stalls, then decide on evidence | ✓ |
| Just wrap it | Apply hyprshutdown --post-cmd 'uwsm stop' for consistency | |
| Just document the exemption | Record that bare uwsm stop is correct | |

**User's choice:** Verify, then wrap or document
**Notes:** The review's file references are stale — `powermenu.sh` and `wlogout/` were
both deleted in Phase 9. The live target is `wleave/.config/wleave/layout.json`, whose
logout action is still bare. PROJECT.md's decision table covers shutdown/reboot and
suspend/hibernate but never logout — precisely WR-04's complaint.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Both, container gate primary (recommended) | Fault injection plus a verify/container-run.sh rerun, closing D-34/D-36 | |
| Container gate only | One fresh-Arch run proves all three | |
| Fault injection only | Per-item targeted proofs | ✓ |

**User's choice:** Fault injection only — **chosen against the recommendation**
**Notes:** Keeps phase scope tight; the D-34/D-36 container-tier rerun stays deferred
for a third milestone.

---

## MD3 Sourcing

| Option | Description | Selected |
|--------|-------------|----------|
| Pre-authorize a namespaced extension | Ship pure MD3 but pre-authorize a documented non-MD3 overshoot set as a landing spot | ✓ |
| Accept the loss | Overshoot leaves the desktop permanently | |
| Decide at the soak | Re-open only if the soak says it reads flat | |

**User's choice:** Pre-authorize a namespaced extension
**Notes:** Raised because MD3's documented easing vocabulary appears to contain no
control points outside [0,1] — MD3 Expressive expresses overshoot as spring physics,
which TOKEN-06 already evaluated and rejected. Combined with "tune within MD3 only",
that would have made overshoot's departure a one-way door. Corroborating finding:
motion.json's `linear` is [1,1,1,1] (Hyprland's convention), not CSS/MD3 linear —
the vocabulary was never strictly pure.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Material's own spec, cited | Primary source only, values reproduced in 13-RESEARCH.md | ✓ |
| Spec, with rice configs as corroboration | Accept end-4 / Caelestia token files where the spec is ambiguous | |

**User's choice:** Material's own spec, cited
**Notes:** Research blocks the phase if no primary source is reachable. Precedents:
TOKEN-06's rejection of unsourced constants, and 07-RESEARCH.md's read-the-config
failure.

---

## Render Gate Structure

| Option | Description | Selected |
|--------|-------------|----------|
| Per-plan, fidelity/taste split | Three gates asking only whether the token renders identically in QML and on the surface | ✓ |
| Per-plan, combined judgement | Each gate judges fidelity and feel together | |
| One consolidated gate | A single sitting at the end covering all three | |

**User's choice:** Per-plan, fidelity/taste split
**Notes:** Narrowed from six gates to three — walker/SwayOSD/AGS are covered by the
Hyprland gate, and wleave was gated in 12-07. The instrument already exists: Phase
12's token inspector with its replayable motion row is literally what criterion 2
describes.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Token match against the inspector | The surface's motion must visibly match the same token replayed in QML | ✓ |
| Before/after capture | Judge against a recording of pre-retrofit behaviour | |
| Both | Token match plus before/after | |

**User's choice:** Token match against the inspector

---

## Token Mapping

| Option | Description | Selected |
|--------|-------------|----------|
| Reuse + minimal additions | Existing `standard` covers swaync's six and waybar's three 0.2s cases; add one neutral 300ms pair; blinks are a separate non-semantic category | ✓ |
| A pair per distinct value | One semantic pair per timing currently in use | |
| Collapse onto the existing three | Force everything onto the current pairs | |

**User's choice:** Reuse + minimal additions
**Notes:** Grounded in a value census — swaync's six literals are the identical rule
`transition: all 0.2s ease`; waybar's are 0.3s ×13, 0.2s ×3, 0.5s ×1, 1s ×1, plus one
easeOutQuad in athena. The two outliers are infinite alternating battery-blink pulses:
state indicators, not transitions, with no MD3 or cross-target counterpart.

---

## Waybar Layout Vocabulary

| Option | Description | Selected |
|--------|-------------|----------|
| Shared vocabulary, per-layout choice | One token set; each layout picks from it, preserving today's differences | ✓ |
| Uniform across layouts | All four use the same tokens for the same interactions | |

**User's choice:** Shared vocabulary, per-layout choice
**Notes:** Phase 8 approved each layout as its own design flow on sight, so the
differences are gated design rather than drift. Athena's non-MD3 easeOutQuad is
replaced regardless under MD3 purity.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Retune, targeted re-soak, then remove | Re-soak only the motions the verdict table flagged | ✓ |
| Close with retuning as follow-up | Phase closes with named retuning deferred | |
| Keep the toggle permanently | Retain the instrument indefinitely | |

**User's choice:** Retune, targeted re-soak, then remove

---

## Exemption End State

| Option | Description | Selected |
|--------|-------------|----------|
| Hold the fence | Tokenize wleave's three 150ms literals; keep the overshoot curve under a permanent exemption | ✓ |
| Extend purity to wleave | Replace the overshoot curve with an MD3 or namespaced token | |
| Extend, using the namespaced extension | Promote wleave's curve verbatim into the pre-authorized extension | |

**User's choice:** Hold the fence
**Notes:** A knowing exception to MD3 purity, scoped to one rule whose feel was
already approved at a Phase 9 render gate.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Opt-in flag at phase close | `motion-lint --no-pending`, named as a closing gate | ✓ |
| Default check in motion-lint | Always fails on any pending-reason exemption | |
| Advisory only | Exemptions stay informational; the verifier reads the list | |

**User's choice:** Opt-in flag at phase close
**Notes:** Gets mechanical falsifiability where it matters without turning a
legitimate temporary Phase 14/15 exemption into a permanently red gate. Precedent:
`motion-lint --self-test` and `keybind-doctor`'s path-argument self-test are both
flag-gated extra assertions.

---

## Phase Size & Ordering

| Option | Description | Selected |
|--------|-------------|----------|
| MAINT-03 splits on observed overrun | Icon browse moves to its own phase only if an overrun is observed | ✓ |
| Nothing descopes; sequence MAINT-03 late | All five requirements ship; no relief valve | |
| Decide if it happens | No pre-committed policy | |

**User's choice:** MAINT-03 splits on observed overrun
**Notes:** A correction was recorded during this discussion — the roadmap's objection
was specifically to placing MAINT-03 in Phase 17 (the designated cut candidate), not
to a dedicated phase, so a split does not contradict it. With the soak floor
incompressible, an unplanned overrun would otherwise land on the render gates.

---

## Pipeline Integration

| Option | Description | Selected |
|--------|-------------|----------|
| One entrypoint, measure | Keep motion-switch.sh's single-entrypoint contract; treat latency as a finding | ✓ |
| Add a targeted fast path | Recompile-only path skipping matugen | |

**User's choice:** One entrypoint, measure
**Notes:** `motion-switch.sh:118` already states this contract explicitly, so the
decision was to preserve it rather than introduce a second render path.

---

| Option | Description | Selected |
|--------|-------------|----------|
| Full contract entries | Format-validated files entries, extending D-31's byte-identity assertion | ✓ |
| presence_only_files | Assert existence only | |

**User's choice:** Full contract entries

---

| Option | Description | Selected |
|--------|-------------|----------|
| Inside theme_engine_generate | Fourth sibling writer rendering into the tmp tree; atomicity preserved | ✓ |
| Post-commit step | Compile after the state dir is committed | |

**User's choice:** Inside theme_engine_generate

---

## Claude's Discretion

- Filenames and state-dir layout for the compiled stylesheets and the `_motion.scss`
  partial.
- How `waybar-design-lint`'s CHECK A is taught to parse `.scss` sources.
- Exact semantic token names added, and how the blink pulses are represented outside
  the semantic layer.
- Plan and wave decomposition within the stated ordering constraints (granularity is
  `coarse`).
- The concrete session/interaction count constituting the soak floor.
- Cache layout and "fetching…" presentation for the preview extraction.
- Whether `--no-pending`'s detection is a reason-string pattern or a structured field.

## Deferred Ideas

- In-surface client-side motion for walker, SwayOSD and the AGS media card → Phase 14.
- Per-namespace `layerrule` style vocabulary → on demand, if a render gate calls for it.
- Graphical motion-scale picker plus its Super-key menu entry → carried from Phase 12.
- `@define-color` → CSS custom properties migration for the GTK4 colour pipeline.
- The container-tier D-34/D-36 reproducibility rerun → explicitly not folded in.
- Wholesale segregation of engine-owned state into its own subdirectory.
- A real second-display hotplug test.
- Restoring the pre-retrofit character curves → foreclosed within this phase; the
  numbers remain in git history should the MD3 result prove unsatisfying later.
