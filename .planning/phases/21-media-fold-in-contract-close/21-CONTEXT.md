# Phase 21: Media Fold-In & Contract Close - Context

**Gathered:** 2026-08-16
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase delivers one media surface, one package deletion, one contract close,
and three debt items:

1. **The dashboard Media tab absorbs the standalone AGS card** — full parity plus
   a live cava-driven radial visualiser around a shaped cover art
   (QMEDIA-01, QMEDIA-02).
2. **Exactly one MPRIS reader remains** anywhere in the desktop, enforced by a
   standing check rather than a one-time sweep (QMEDIA-03).
3. **Retirement** — `ags` leaves repo and host with its contract entry, its
   matugen template, its reload step and its layer rules; its three orphaned
   bash scripts go in the same commit (RETIRE-06).
4. **Contract close** — `contract.json` reaches its post-migration size with
   `theme-doctor` and `theme-parity` green and no orphaned entries (RETIRE-08).
5. **Debt** — LEDGER-06 (Phase 16's missing verification report, its two malformed
   `coverage:` blocks, and quick task `260728-51j`), plus two folded todos: frost
   unification and the ambient DND indicator.

**Correction to the roadmap's stated numbers.** The roadmap says `contract.json`
goes "29 → ~17". The live file carries **18** `files` entries today, not 29 —
the 29 was the pre-migration total across all five retirements. Removing
`ags.scss` takes it to **17**, which does match the roadmap's target. Plan
against 18 → 17, not 29 → 17.

**Not in this phase:** the fresh-install proof (Phase 22), the launcher (out of
scope for v4.0 entirely).

</domain>

<decisions>
## Implementation Decisions

### Governing rules inherited from Phases 19 and 20

- **D-19-00 [informational] still governs:** Caelestia's shipped behaviour is the
  strong default, end-4 secondary; check `.planning/research/FEATURES.md` § MEDIA
  before proposing an approach, and name the divergence explicitly whenever
  recommending against Caelestia. Every visual decision below follows Caelestia.
- **WINDOWS #1 precedent (standing, not re-litigated):** for each retirement, the
  package deletion, the `contract.json` entry, the matugen template, the reload
  step, the layer rules and any checker reference land in the **same commit**,
  config-then-package.
- **Zero-idle backends:** nothing polls or spawns a subprocess while its surface
  is dismissed. D-21-06 is this rule applied to cava.
- **No hardcoded colours or motion numbers** — `colour-lint` (GATE-04) and
  `motion-lint` both reject them; read from `Colours.qml` / `BarRoles.qml` /
  `Motion.qml`. D-21-05's accent must be a token read, never a literal.

### The visualiser (QMEDIA-02)

- **D-21-00 — the cava go/no-go resolves to GO.** The roadmap frames this as a
  blocking opening spike. Three findings collapse it before planning starts:
  1. `cava 0.10.7-1` is installed **and running right now** (PID 1990), feeding
     the unreachable AGS card.
  2. `ags/.config/ags/lib/cava.ts` is a working streaming reader — `cava -p
     <config>`, one line per frame, `;`-delimited ascii 0..100, normalised to
     0..1, blank/partial lines ignored rather than clobbering the last good
     frame. That is exactly the shape a Quickshell `Process` + `SplitParser`
     takes.
  3. `MediaTab.qml` **already imports `QtQuick.Shapes`** and already draws the
     ring at lines 525-551 as one `ShapePath` + `PathAngleArc`.
  The Phase 14 premise recorded in `MediaTab.qml`'s own header — "this repo has
  no cava/audio-analysis service anywhere in its QML toolkit" — is now false in
  two directions. **A spike to establish feasibility is not needed; the phase
  opens on the build, not on the go/no-go.** Success criterion 2's alternative
  (a recorded human no-go verdict) is not being taken.
  — **Measured, not asserted** (2026-08-16, this host): 24-bar cava = 1.00% of
  one core / 14.4 MB RSS; 60-bar cava = **1.20% of one core / 14.0 MB RSS**;
  cold start to first output frame = **~350 ms** (348/352/353 ms across three
  runs). `Dashboard.qml` opens on `Motion.standardDuration` (200 ms default), so
  a cold spawn's first frame lands roughly 150 ms *after* the drawer has settled.

- **D-21-01: Live radial bars, replacing the dashed ring.** Caelestia's
  `CoverVisualiser.qml` technique: N radial `ShapePath` bars around the cover,
  each bar's **length** driven by its own frequency band's live amplitude, each
  holding a minimum sliver at silence. The silence state of this design **is**
  today's dashed ring — nothing about the round-3-accepted look is lost.
  Build: swap the single `ShapePath`/`PathAngleArc` at `MediaTab.qml:525-551`
  for a `Repeater` of `ShapePath`s.
  Rejected: a whole-ring "breathe" driven by mean amplitude (no frequency
  detail — a bass hit and a cymbal look identical); a flat vertical bar underlay
  behind the art (the AGS card's own treatment, which `FEATURES.md:162` names as
  the thing the radial version is "a genuine visual upgrade" over).
  — **Reversibility:** reversible — one file's Shape block plus one process
  reader; backing out restores the static ring.

- **D-21-02: The cover art becomes a hand-authored 12-lobe scalloped blob**
  (Caelestia's `MaterialShape.Cookie12Sided`), not the current circle.
  `MediaTab.qml`'s header records that this geometry "has no equivalent in this
  repo (no `M3Shapes` import, no `Caelestia.Config`)" — so the path is authored
  by hand as a `ShapePath` of arcs, never transplanted as a library import.
  **Reconciliation with round-3 feedback, recorded so the planner does not read
  this as a contradiction:** round 3 asked for "something rounder and dotted,
  closer to the ring's own idle silhouette than to the cookie-blob host shape
  underneath it" — that feedback was about a *static* ring, where the cookie had
  nothing orbiting it to justify its lobes. With the ring now live, the cookie is
  the host shape those bars were designed to orbit. The operator selected it on a
  rendered comparison against a plain circle and a squircle.
  — **Known risk this re-opens:** round 4 fixed an art-clipping bug by replacing
  `clip: true` (which only clips to the axis-aligned bounding box, never the
  painted rounded shape) with `QtQuick.Effects`' `MultiEffect.maskEnabled` /
  `maskSource` against a circular `Rectangle` mask. The mask **mechanism** is
  unchanged by this decision, but its **source** becomes the hand-authored cookie
  path instead of a `Rectangle`. Re-run round 4's clipping check at non-square
  cover aspect ratios.
  — **Reversibility:** reversible — the mask source is one property; reverting to
  the circular `Rectangle` restores round 4's proven state.
  — **⚠ REVERSED BY THE OPERATOR, 2026-08-16, during 21-06 execution.** On first
  sight of the rendered 12-lobe cookie the operator said: *"I don't like this new
  album art style. Restore the circular look."* The cookie is **rejected**; the
  cover art is a plain circle on both `MediaTab.qml` and `MediaPopout.qml`
  (commit `2b99609`). This is consistent with the round-3 feedback already
  recorded in `MediaTab.qml`'s header, which asked for *"something rounder and
  dotted, closer to the ring's own idle silhouette than to the cookie-blob host
  shape underneath it"* — the round-3 reconciliation argument above (that a live
  ring justifies the lobes) did not survive contact with the rendered result.
  `_circlePath()` is now the mask source in both files; `_cookiePath()` is
  retained but unused so the decision stays cheaply reversible. The mask
  **mechanism** (`MultiEffect.maskEnabled`/`maskSource`, plus the load-bearing
  `layer.enabled: true`) is untouched, so round 4's proven state is what is
  restored — the "known risk" above is therefore closed, not merely deferred.
  — **Downstream impact:** D-21-03's "pairs evenly with the 12 lobes (5 bars per
  lobe)" rationale below no longer applies. The 60-bar count is unaffected — it
  is locked to Caelestia's `visualiserBars` default independently of the host
  shape — but any artifact justifying 60 *by the lobe pairing* is now stale.
  Anything still describing the cover art as a cookie (21-06's SUMMARY, and
  D-21-20's combined render gate in 21-08) must be read as superseded by this
  entry.

- **D-21-03: 60 bars**, matching Caelestia's `visualiserBars` default from
  `serviceconfig.hpp`. Pairs evenly with the 12 lobes (5 bars per lobe). Note the
  existing ring's dash/gap was tuned to land near 56 marks and `ags/cava/config`
  sets 24 — both are superseded; cava's bar count is config-driven, so this is a
  free choice with no upstream constraint.

- **D-21-04: The ring takes the accent role, and `14-UI-SPEC.md` is amended to say so.** The spec currently reserves primary/accent for an enumerated list
  (tab indicator, lit toggle chips, active motion-scale segment, play/pause
  pressed state, calendar "today", pending-pulse) and explicitly forbids it as
  "a general interactive-element default" — which is why the static ring was
  given `Colours.outline`. The amendment's rationale: the reservation exists to
  stop accent being spent on decorative chrome, and a ring carrying live audio
  signal is not decorative chrome. Caelestia tints its own ring `m3primary`, so
  this also removes a recorded divergence.
  **The amendment is a required deliverable, not an implied one** — add the
  visualiser to the enumerated list in `14-UI-SPEC.md`, do not simply use the
  accent and leave the spec contradicting the code.
  Rejected: staying on `outline` (a recorded divergence from Caelestia with no
  gain); interpolating outline→primary by amplitude (a third behaviour neither
  the spec nor Caelestia describes).

- **D-21-05: The ring renders on BOTH the dashboard Media tab and the bar's `MediaPopout`.** QMEDIA-02's wording names only the Media tab; the operator
  extended it to the popout because that is the surface actually reachable
  without opening the drawer. This is what forces D-21-06's shared ownership —
  two independent surfaces claim one process.

- **D-21-06: cava is a shared, reference-counted process with a short linger.**
  Either surface claims it; it dies a few seconds after the **last** claimant
  releases. Nothing runs while every media surface is dismissed (the zero-idle
  rule holds), and bouncing between the popout and the dashboard never re-pays
  the measured ~350 ms cold start.
  Rejected: refcount with no linger (re-pays 350 ms on every reopen, including
  an accidental close-and-reopen); spawn-while-any-surface-open without refcount
  (two owners racing one process); always-on (1.20% of a core permanently, and
  openly breaks the zero-idle rule).
  — **Operator revisit clause, binding on the implementation:** the operator
  will test this in use and may revert to always-on if the linger does not feel
  right. **Therefore always-on must be reachable by changing a single knob**
  (one property or one config value), not by restructuring the ownership model.
  Build the refcount so that pinning the claim count to a permanent 1 is the
  whole change.
  — **Linger duration is Claude's discretion** (see below).

- **D-21-07: cava's config moves to its own `cava/` stow package** —
  `cava/.config/cava/config`, registered in `stow.sh` alongside every other
  package. `ags/.config/ags/cava/config` dies with the ags tree. Rejected:
  passing bars/framerate/output settings as inline argv from QML (one less file,
  but it moves tuning into QML and breaks the pattern every other tool here
  follows, including for the Phase 22 fresh-install proof).
  **No `contract.json` entry is needed** — cava's config carries no colours.

### Parity (QMEDIA-01)

- **D-21-08: GATE-01's behavioural enumeration is taken off the LIVE card, and no keybind restoration is required to do it.** The AGS daemon is running
  (PID 1705 + `gjs` 1796) and still answers its request handler, so
  `ags request -i media toggle-media` summons the card on demand. Enumerate
  against the running surface per `18-BEHAVIOUR-BASELINE.md` §
  "GATE-01 Recurrence Protocol", not from source alone.
  **Context for the enumerator — the gap looks small.** `MediaTab.qml` (1339
  lines) already carries transport, seek, cover art, a volume band gated on
  `volumeSupported`, and the player-switcher pill. The card's one capability the
  tab lacks is the cava underlay, which D-21-01 supersedes with a better
  treatment. Expect the enumeration to confirm parity rather than discover
  a backlog — but it is still run, because the deletion is one-way.

- **D-21-09: Cross-source player dedup is IN SCOPE.** With some browsers one
  track appears twice in the switcher — once from the browser, once from the
  site's embedded player. Both reference shells collapse these; neither this
  repo's backend nor the AGS card does. Port the heuristic: match by track-title
  substring or by position/length proximity (`FEATURES.md:163` — "small,
  well-specified algorithm, cheap to port").
  **This is an addition beyond parity**, accepted deliberately: it makes the
  switcher trustworthy, and QMEDIA-01's own premise (the tab must be a credible
  replacement) is undermined by a switcher that shows one song twice.

- **D-21-10: "per-player volume" resolves to a volume control PER PLAYER**, not
  one slider that follows the selection.
  **Flagged honestly as new capability, not parity.** Neither reference shell has
  per-player volume (`FEATURES.md`: "No per-player volume control exists anywhere
  in either Media file"), and the AGS card's own `setVolume` acted on the
  selected player only. The requirement's wording genuinely reads both ways; the
  operator settled the ambiguity toward the fuller reading, so the Media tab
  ships something the card never had.
  **Interaction the UI phase MUST resolve before this is built:** D-21-09
  collapses two duplicate entries into one, which merges two independently
  controllable volumes. Render that interaction — where the per-player controls
  live, and what a collapsed pair's volume control does — before implementing.
  The native `Mpris.players.values` already exposes `.volume`/`.volumeSupported`
  per player, so the data layer needs no new reader.

- **D-21-11: Any genuine gap the enumeration finds is BUILT before the card is deleted.** No accepted losses, no case-by-case ruling mid-phase. Rationale:
  the deletion is irreversible and nothing is lost by waiting.

- **D-21-12: `Super+M` opens the dashboard directly on the Media tab.** A new
  `quickshell:media` global shortcut, matching the established one-letter-per-
  surface pattern (`Super+D` dashboard, `Super+O` overview, `Super+N` notification
  centre). `M` is verified free — bound letters are A B C D E F I L N O P Q R S
  T V W X Y Z. The dashboard already exposes `initialTabIndex` and
  `tabIndexMedia = 1`, so opening to a specific tab is an existing parameter, not
  new machinery.
  **Requires a matching manifest row** for the keybind cross-check contract
  (`keybinds.lua:233` names it) — a `GlobalShortcut` without its manifest entry
  fails `keybind-doctor`.
  Context: the AGS card's own opener died with waybar in Phase 18; nothing binds
  `toggle-media` today, so this is a restoration of reachability, not a new
  entry point competing with an existing one.

### Retirement (RETIRE-06) and the reader count (QMEDIA-03)

- **D-21-13: The three orphaned bash scripts are deleted in the SAME commit as the `ags` package.** Verified consumer sweep:
  - `media-status.sh` (running now, PID 1960) — consumed **only** by
    `ags/lib/media.ts`. Orphaned by this deletion.
  - `media-players.sh` — consumed **only** by `ags/lib/media.ts`. Orphaned.
  - `media-player.py` — **zero consumers already**. A pre-existing orphan,
    swept up here rather than left behind.
  - Remaining references in `MediaTab.qml` (lines 67, 117-118, 276, 280, 428,
    433) are **comment-only** and fall under D-21-19.
  Rejected: keeping `media-players.sh` as a CLI surface (it is a second MPRIS
  read path on disk, which is exactly what QMEDIA-03 ends).
  Precedent: eww's leftovers needed their own cleanup quick task
  (`260725-vu6`, "complete the eww retirement, drop orphaned…") because they were
  left on disk.
  — **Reversibility:** one-way — package deletion plus script deletion. Warrants
  a `checkpoint:decision`, gated behind D-21-20.

- **D-21-14: `media-art-resolve.sh` STAYS.** It is `MediaBackend.qml`'s only
  subprocess (`MediaBackend.qml:242` builds its path by string concatenation —
  a naive grep for the filename misses it) and it carries the scheme allowlist
  and the loopback/RFC1918 pre-flight rejection that mitigate request forgery
  against this machine. Do not delete it with the others.

- **D-21-15: `test-media-hardening.sh` is trimmed to its surviving coverage AND gains one new check.**
  - **Drop** checks 1/2/3 (hostile title/artist through `media-status.sh once`),
    4-7 (`media-players.sh` id/verb/arg allowlist) and 11 (the zero-player gate)
    — they test deleted files.
  - **Keep** checks 8, 9, 9b and 10 — `media-art-resolve.sh`'s scheme gate,
    loopback rejection, literal-encoding SSRF bypass rejection, and cache
    separation for two distinct art URLs.
  - **Add** coverage for the handoff `MediaBackend.qml`'s own header calls "the
    breakable link": `artPath` must remain a bare local filesystem path because
    `MediaTab.qml:613` prefixes `file://` itself — a URL-valued `artPath`
    produces a doubled scheme and a **silently blank art circle** with no error
    and no log. Nothing tests this today.
  Rejected: deleting the whole file (throws away live network-forgery coverage
  for a script that still runs on every non-`file://` album art fetch).

- **D-21-16: QMEDIA-03 is proven by a PERMANENT automated check**, not only by a
  one-time sweep. Add a music-player-listener count assertion to
  `quickshell-doctor` (or `retirement-check`) that fails when more than one
  reader exists.
  **Reconciliation with the roadmap, recorded rather than silently resolved:**
  success criterion 3 names "checklist-verified zero-hits before and after" as
  part of the deletion itself, and every prior retirement here was proven that
  way. The operator's answer selects the standing check as the *durable*
  guarantee — so **both happen**: the before/after sweep runs because every
  retirement in this project runs one and the criterion requires it, and the
  standing check is what stops a future phase silently reintroducing a second
  reader. The sweep is evidence for this phase; the check is the line held
  afterwards.
  Context for why this matters: the desktop had **three** independent MPRIS
  readers (waybar's module, the AGS card's bash reader, the QML backend) and
  acquired them one at a time without anything noticing.

### Contract close (RETIRE-08)

- **D-21-17: `contract.json` goes 18 → 17 `files` entries** by removing the
  `ags.scss` / `scss-vars` entry. `_motion.scss` is the second `scss-vars` entry,
  so the format family stays represented and no placeholder or repoint is needed.
  **No `theme-stress-test` trap here:** `REPRESENTATIVE_FILES` is
  `(hyprland-tokens.lua gtk-4.0-colors.css kitty.conf)` — `ags.scss` is not a
  member, unlike `wleave.css` which was the named `gtk-css` representative and
  broke the stress test when Phase 20 removed it. Verify, do not assume.

- **D-21-18: `dart-sass` STAYS — do NOT remove it with `ags`.**
  `install.sh:240-242`'s comment attributes it entirely to AGS ("the `sass`
  binary AGS invokes at load… without it `ags run` aborts"), and that comment is
  **wrong**. `stow.sh:417-464` shells out to `sass` to seed the compiled GTK3
  stylesheets at install time, and `lib/motion.sh`'s `GTK3_SCSS_TARGETS` depends
  on the same binary. Removing it would leave GTK3 surfaces unstyled on a fresh
  install — a failure Phase 22's fresh-install proof would catch expensively.
  **Correct the comment as part of this phase.**
  Package dispositions in `install.sh`:
  - `aylurs-gtk-shell` (line 353) — **removed**.
  - `cava` (line 243) — **stays**, comment rewritten: it now feeds the QML
    visualiser, not the AGS applet.
  - `dart-sass` (line 244) — **stays**, comment corrected per above.

- **D-21-19: Comments naming the dead surface are REWRITTEN, not scrubbed and not exempted.** `ags-media` appears in `windowrules.lua` as **two real layer rules** (line 305 `blur = true`, line 352 `ignore_alpha = 0.25`) and **seven comments** (lines 228, 278, 295, 301, 418, 461, 465, 527), plus one in
  `theme-parity:239` and several in `MediaTab.qml`. The rules go; the comments
  are rewritten so the **finding survives and the name goes** — e.g. "a fill
  alpha at or below the threshold silently discards blur" stated on its own
  terms. Where provenance genuinely matters, cite the recording plan ID rather
  than the namespace string: a plan ID is a planning artifact, not a surface, so
  it does not trip the leftover sweep and does not imply the surface still
  exists.
  Rationale for rejecting the alternatives: **scrubbing** deletes the only
  written record of why several *live* surfaces carry the alpha values they do,
  and that record has already prevented a misdiagnosis (the symptom of a fill at
  or below the threshold looks like a design problem, not a blur bug).
  **Exempting the sweep** puts a permanent comment-only blind spot into the tool
  whose entire job is catching what deletions leave behind — and Phase 20's final
  plan already stalled on a comment-only-drift interlock needing an operator
  ruling, so the exemption would institutionalise a recurring judgement call
  immediately before the phase that rebuilds this machine from scratch.

- **D-21-20: ONE combined gate unlocks the deletion — parity checklist and rendered look in a single sitting, one verdict.** The gate covers both
  D-21-11's parity checklist and a live look at the cookie shape and the running
  ring. Rationale: Phase 20 ran two independent gates because its two surfaces
  shared no backend; here there is one surface, so two approval rounds for one
  thing is pure overhead. Nothing is deleted before the gate passes.
  — **Reversibility:** one-way — this gate is what stands between the phase and
  an irreversible package deletion. Warrants a `checkpoint:decision`.

- **D-21-21: `retirement-check`'s registry row `ags|pending|ags/|RETIRE-06` (line 92) flips to retired** in the same commit, per the standing precedent.

- **D-21-22: The phase closes on a VERIFIER RUN, not on operator attestation.**
  Phase 20 closed on attestation with no verifier run (commit `8cefc5a`). This
  phase does not repeat that: it closes the theme contract and lands the final
  deletion before Phase 22 rebuilds from scratch, so it is the one phase where
  an automated pass earns its cost — Phase 22 inherits whatever this phase gets
  wrong.

### Debt — LEDGER-06

- **D-21-23: Phase 16's `16-VERIFICATION.md` is reconstructed AS IT STOOD AT THE TIME**, from the eight plan summaries, `16-UAT.md` and
  `16-OVER04-MEASUREMENT.md`. An honest historical record including the gaps
  Phase 16 actually left open — notably the OVER-04 frame-rate floor/target
  recorded UNMEASURED (only the CPU half passed, at 2.4× headroom) and the
  `GradientBorder` rim missing from the three Phase 15 panels.
  Rejected: annotating each gap with whether a later phase closed it (more useful
  to read, but blurs the historical record); running the verifier fresh against
  today's code (a report about a phase that closed months ago, written against
  code four phases newer — arguably fiction).
  **Note for the writer:** the `GradientBorder` gap has since been closed by
  Phase 20's LEDGER-01. Under this decision that closure is **not** folded into
  the Phase 16 report; the report says what was true at Phase 16's close.

- **D-21-24: The two malformed `coverage` blocks are fixed in place, with no validator added.**
  - `16-05-SUMMARY.md` D5 — invalid `status: not_run`.
  - `16-06-SUMMARY.md` D2/D3/D4 — missing the required `rationale` field.
  The classifier failed safe (escalated rather than dropping), so nothing was
  lost. Rejected: adding a validator that rejects malformed blocks at write time
  — new tooling to maintain for a problem two files old that has not recurred,
  since every later phase writes these correctly.

- **D-21-25: Quick task `260728-51j` is closed as already done.** Its directory
  does not exist under `.planning/quick/` — only a `missing` row in STATE.md
  (line 653) remembers it, so its scope is unrecoverable beyond the title
  "write-the-hyprland-lua-config-migration-". The underlying work is
  demonstrably complete on disk: the Lua config tree is live
  (`keybinds.lua`/`windowrules.lua`/`autostart.lua`) and the hyprlang
  `[templates.hyprland]` block was retired in Phase 13.1 in favour of the
  `hyprland-tokens.lua` pipeline (recorded in `matugen/config.toml`'s header).
  Record the evidence and clear the row. Rejected: recreating the task record
  from the title and re-doing it — risks redoing finished work off a guess.

### Folded todos

- **D-21-26: Frost unification — ONE value governs every layer surface.** The
  dashboard and the overview come down to the notification/OSD threshold so the
  same wallpaper reads identically no matter which surface is open. Measured
  2026-08-15: notifications (toast/popups/centre) + OSD at fill `0.38` /
  `ignore_alpha 0.2`; dashboard at `0.5` (the `^quickshell-.*` family default —
  no real override); overview at `0.25`; bar at fill `0.55` / `0.5`.
  The notification family and the OSD are **already** mutually consistent and are
  not what changes — the dashboard and overview move to join them.
  Rejected: two deliberate tiers (transient pills lighter than full-surface
  panels); documenting the three values as intentional.
  **Two constraints the implementer must respect:**
  1. Fill alpha and `ignore_alpha` are chosen **together** — a fill at or below
     the threshold silently discards blur, and the symptom reads as a design
     problem rather than a blur bug.
  2. The result cannot be trusted from config alone. `hyprctl keyword` is
     rejected on this config ("keyword can't work with non-legacy parsers") and
     `hyprctl reload` **silently drops layer-rule edits** — use
     `hyprctl eval 'hl.layer_rule({...})'` or a full restart, and take a
     screenshot before tuning.
  3. Per-surface rows must be declared **after** the `^quickshell-.*` family
     regex or they do not override it.

- **D-21-27: The DND indicator tints the whole clock/actions capsule.** For as
  long as do-not-disturb is active the capsule shifts to an accent tint — not a
  badge on one glyph, but a whole bar element changing state, which is what a
  *mode* should look like. Selected from a rendered comparison.
  Rejected: an accent dot at the bell glyph's corner (survives the vertical
  layout most cheaply, but is the weakest cue from across the screen — the same
  weakness that caused the original false report); a separate "DND" text chip
  (clearest to read, but it changes the bar's **layout** so everything beside it
  shifts on toggle, and the vertical bar renders capsules glyph-only so a text
  pill needs either a glyph-only variant — back to the same problem — or an
  exception to the vertical rule).
  **Constraints:** the capsule also holds the clock, so this is a long-lived
  colour change in the busiest part of the bar; if it reads as visually loud the
  fix is **tuning the tint strength, not rethinking the approach**. Keep
  `NotifServer.dnd` as the single source of truth. Tint must come from the
  existing token system (`Design.qml`/`Colours.qml`/`BarRoles.qml`) —
  `colour-lint` rejects literals. Must hold in the vertical bar layout.

### Claude's Discretion

- The exact linger duration for D-21-06's cava refcount.
- Bar geometry inside the ring — inner radius, bar width, cap style, minimum
  sliver length at silence.
- The exact lobe depth and corner rounding of D-21-02's 12-lobe path.
- cava's `framerate` in the new config (the AGS config used 60).
- Whether D-21-16's listener-count check lands in `quickshell-doctor` or
  `retirement-check`.
- The precise final wording of D-21-19's rewritten comments.
- The exact single frost value chosen in D-21-26, and the fill/threshold pair
  that carries it — subject to the live-verification constraints named there.
- D-21-27's tint strength.

### Execution-Time Amendments (recorded 2026-08-16, during Wave 1/2)

These were decided live against rendered results, after the decisions above were
written. They supersede any earlier text they contradict.

- **D-21-02 REVERSED — circular cover art.** See the reversal note on D-21-02
  itself. Commit `2b99609`.

- **A-21-01: `Repeater { ShapePath {} }` does not work — Item-wrapper required.**
  `21-RESEARCH.md:311` asserted the 60-bar ring was "not new machinery, it is the
  existing `Shape` extended with a `Repeater` as its content". **That research
  claim is false.** `Repeater` instantiates only `Item`-derived delegates, and
  `ShapePath` is not an `Item`, so the construct creates **zero** objects and
  fails **completely silently** — no QML error, no warning. Shipped in 21-06 and
  rendered a bare, empty ring. Qt Forum topic 104917 documents both the
  limitation ("The Repeater cannot reside inside the ShapePath item… but only
  outside of the Shape item") and the workaround now used in both files: wrap each
  `ShapePath` in an `Item` delegate and push it into `Shape.data` in
  `Component.onCompleted`. Commit `063e331`.

- **A-21-02: visualiser response is curved, not linear.** Operator judged the
  working ring "too subtle". Measured live for 3s against this repo's own cava
  config: **median band amplitude 0, p90 19/100, max 100** — so under linear
  mapping a typical bar sat at ~5px of a 14px range. Added
  `visualiserResponseExponent: 0.45` (`pow(a, 0.45)`, endpoints fixed at 0 and 1
  so the silence sliver and full-amplitude cap are unchanged and D-21-01's
  silence-equivalence argument still holds), plus max extension 14→18 and bar
  stroke 2→3 (8→... and 1→1.5 on the popout). Layout headroom was measured before
  choosing: the binding constraint is the **8px vertical gap to the player pill**,
  not the 24px `sectionGap` to the details column. All three remain one-constant
  render-gate tunables per 21-UI-SPEC.md. Commit `ad7a894`. **Operator-verified
  live**: *"Yes, the bars are there and react to sound"*, then *"Visualizer looks
  good"*.

- **A-21-03 [process]: green gates certified three broken surfaces this phase.**
  A `Colours.error` visualiser passed `colour-lint` 144/0 (the lint checks that a
  colour IS a token, never that it is the RIGHT token); a spec-rejected
  `PathAngleArc` passed every check because nothing compared the build to the
  spec; and the zero-bar `Repeater` passed a `grep -q "Repeater"` assertion while
  rendering nothing. **Consequence for D-21-20's combined deletion gate in 21-08:
  it must not be passed on greps or lints alone.** The `ags` deletion is
  irreversible in-tree; it requires eyes on the rendered surface.

### Folded Todos

- **`2026-08-15-unify-frost-values-across-surfaces.md`** — "Unify dashboard and
  overview frost values with OSD/notifications". Folded because this phase edits
  the dashboard anyway and the measured table is already in hand. Resolved by
  D-21-26. Files: `hypr/.config/hypr/config/windowrules.lua`,
  `quickshell/.config/quickshell/modules/bar/BarRoles.qml`.
- **`2026-08-13-ambient-dnd-indicator.md`** — "Ambient DND indicator — bell glyph
  swap is too easy to miss". Caused a false "popups are broken" report during
  Phase 19's render gate when DND was left on after a restart-persistence test.
  Resolved by D-21-27. Files:
  `quickshell/.config/quickshell/modules/bar/ClockActionsCapsule.qml`,
  `quickshell/.config/quickshell/modules/centre/CentreFooter.qml`,
  `quickshell/.config/quickshell/modules/notifications/NotifServer.qml`.
  **Scope note for the planner:** this one is a bar-module concern outside the
  roadmap's media/contract boundary for Phase 21. It was folded on an explicit
  operator decision, not because it belongs. **Size it as its own small plan** —
  do not smuggle it into a media or retirement plan where it would blur that
  plan's scope and its commit's diff.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Reference-shell behaviour (governing, per D-19-00)
- `.planning/research/FEATURES.md` § MEDIA (lines 103-119) — Caelestia's
  dashboard-only media placement (no bar entry, no standalone popup) as the
  validated precedent for this fold-in; `CoverVisualiser.qml`'s radial cava bars
  orbiting a `Cookie9Sided` cutout; `Details.qml`'s wavy seek slider; the
  explicit finding that **no per-player volume exists in either reference**
  (relevant to D-21-10); both refs' duplicate-source dedup heuristics
  (D-21-09).
- `.planning/research/FEATURES.md:143-147` — the MEDIA differentiator table rows
  (transport, seek, cover art, player switching, audio-reactive element) and
  their cost estimates.
- `.planning/research/FEATURES.md:162` — the radial-visualiser-around-shaped-art
  row, naming it "a genuine visual upgrade over the current AGS card's flat
  blurred-art-plus-underlay cava treatment" and flagging that Quickshell's
  `Shape`/`ShapePath`/`PathAngleArc` API was observed but **not independently
  researched** — the named gap for phase research.
- `.planning/research/FEATURES.md:172` — per-track dominant-colour re-tinting
  (end-4's `ColorQuantizer`) listed as **explicitly excluded**: it would be a
  second competing colour source against the theme-engine palette. Do not
  reintroduce it.
- `.planning/research/FEATURES.md:251` — the recorded research gap on the exact
  Qt Quick Shapes API for the radial visualiser.

### The surface being replaced
- `ags/.config/ags/widget/MediaWindow.tsx` — the card's full layout: the
  five-layer `Gtk.Overlay` stack (blurred art background → scrim → cava layer →
  thumbnail → controls panel), the `notify::is-active` click-away, `Esc`
  handling, the `ags-media` namespace and `TOP` anchor with `marginTop: 54`.
- `ags/.config/ags/widget/Cava.tsx` — the 24 fixed boxes with reactively bound
  `heightRequest`, and the recorded reason they are static rather than a `For`
  over the raw array (avoids recreating 24 widgets at ~60fps).
- `ags/.config/ags/lib/cava.ts` — **the reader D-21-01's QML `Process` mirrors.**
  `cava -p <config>`, `;`-delimited ascii 0..100 normalised to 0..1, blank and
  partial lines ignored so a torn frame never clobbers the last good one.
- `ags/.config/ags/cava/config` — bars/framerate/raw-ascii output settings; the
  content that moves to the new `cava/` stow package under D-21-07.
- `ags/.config/ags/lib/media.ts` — the card's MPRIS reader and the **only**
  consumer of `media-status.sh` and `media-players.sh`; also carries the
  per-track seekability latch and the reason it exists (Firefox/Gecko report
  `mpris:length` unreliably, and a seek re-triggers metadata without length).
- `ags/.config/ags/app.tsx` — the `toggle-media` request handler, the
  `reload-css` path, and the recorded stow-symlink/`sass` `@import` asymmetry.
- `ags/.config/ags/style.scss` — the compiled sheet; the `.media-scrim` /
  `.media-controls` backgrounds the Hyprland blur rule frosts through.

### The surface being extended
- `quickshell/.config/quickshell/modules/dashboard/MediaTab.qml` — **read the
  header in full before planning.** Records all four render-gate rounds, the
  Caelestia study, why the ring is static (the premise D-21-00 invalidates), why
  shuffle/repeat and lyrics were not built, the round-3 player-switcher
  supersession, and round 4's `MultiEffect` mask fix. Lines **525-551** are the
  `Shape`/`ShapePath`/`PathAngleArc` block D-21-01 replaces. Line **613** is the
  `file://` prefix that makes `artPath` "the breakable link".
- `quickshell/.config/quickshell/modules/dashboard/MediaBackend.qml` — the single
  MPRIS reader. Native `Quickshell.Services.Mpris` since D-18-05 (which
  superseded D-35's import fence). Line **242** builds `media-art-resolve.sh`'s
  path by concatenation. `players`/`activePlayer` are pure projections of
  `Mpris.players`; `selectPlayer` and the clamped volume write are the dispatch
  surface D-21-09/D-21-10 extend.
- `quickshell/.config/quickshell/modules/bar/MediaPopout.qml` and
  `modules/bar/MediaConnectivityCapsule.qml` — the bar-side surfaces; the popout
  is D-21-05's second visualiser host.
- `quickshell/.config/quickshell/modules/Dashboard.qml` — `initialTabIndex`
  (line 285), `tabIndexMedia = 1` (line 255), `currentTabIndex` alias (286), and
  the `Motion.standardDuration` open animation (lines 178-190) that D-21-00's
  350 ms measurement is compared against.

### Integration points that must be repointed or removed
- `theme-engine/.config/theme-engine/contract.json` — the `ags.scss` /
  `scss-vars` entry; 18 `files` entries today, 17 after (D-21-17).
- `matugen/.config/matugen/config.toml` — the `[templates.ags]` block and its
  header comment, plus `matugen/.config/matugen/templates/ags-colors.scss`.
- `theme-engine/.config/theme-engine/lib/reload.sh:116-129` — the
  `ags list | grep -qx 'media'` guard and the `ags request -i media reload-css`
  step in the reload fan-out. QML hot-reloads natively; nothing replaces it.
- `theme-engine/.config/theme-engine/theme-parity:239` — a comment naming
  `ags.scss` as the `scss-vars` example (D-21-19).
- `theme-engine/.config/theme-engine/theme-stress-test` — `REPRESENTATIVE_FILES`
  is `(hyprland-tokens.lua gtk-4.0-colors.css kitty.conf)`; `ags.scss` is **not**
  a member. Verify before deleting, per the `wleave.css` precedent.
- `hypr/.config/hypr/config/windowrules.lua:305` (blur) and `:352`
  (`ignore_alpha = 0.25`) — the two real `ags-media` layer rules. Comments at
  228, 278, 295, 301, 418, 461, 465, 527 fall under D-21-19.
- `hypr/.config/hypr/config/autostart.lua:164-165` — the
  `uwsm app -- ags run --directory ~/.config/ags` autostart and its
  `toggle-media` comment.
- `hypr/.config/hypr/config/keybinds.lua` — where `Super+M` is added (D-21-12);
  line 233 names the keybind-doctor cross-check contract the new shortcut needs a
  manifest row for. Lines 205-233 are the existing surface-shortcut precedents.
- `hypr/.config/hypr/scripts/media-status.sh`,
  `hypr/.config/hypr/scripts/media-players.sh`,
  `hypr/.config/hypr/scripts/media-player.py` — deleted (D-21-13).
- `hypr/.config/hypr/scripts/media-art-resolve.sh` — **retained** (D-21-14).
- `hypr/.config/hypr/scripts/tests/test-media-hardening.sh` — checks 1-7 and 11
  removed, 8/9/9b/10 retained, one added (D-21-15).
- `hypr/.config/hypr/scripts/retirement-check:92` — the
  `ags|pending|ags/|RETIRE-06` registry row (D-21-21). Lines 661-663 record the
  known precision limit of the short-token sweep for `ags` vs
  `tags`/`flags`/`images` — relevant when running the zero-hit check.
- `install.sh:239-244` (cava + dart-sass with the incorrect AGS-only comment) and
  `:349-353` (`aylurs-gtk-shell`) — D-21-18.
- `stow.sh:20` (`ags`) and `stow.sh:417-464` (**the GTK3 `sass` seed that proves
  `dart-sass` is not AGS-only**).

### Layer-rule ordering and alpha (the known trap, now also D-21-26's constraint)
- `hypr/.config/hypr/config/windowrules.lua:368-397` — the `^quickshell-.*`
  family blur pair.
- `hypr/.config/hypr/config/windowrules.lua:441-446` — the family
  `ignore_alpha = 0.5` floor the dashboard currently inherits.
- `hypr/.config/hypr/config/windowrules.lua:499-526` — the worked example of
  per-surface rows declared **after** the family regex.

### Prior locked decisions this phase inherits
- `.planning/phases/20-indicators-power-menu/20-CONTEXT.md` § decisions — the
  retirement sequencing pattern (D-20-42/D-20-43), the GATE-01 three-part
  enumeration, and the `REPRESENTATIVE_FILES` trap that broke the stress test.
- `.planning/phases/19-notification-server-centre/19-CONTEXT.md` § decisions —
  D-19-00 (Caelestia default) and the retirement-sequencing precedent.
- `.planning/phases/18-qml-bar-retirement-machinery/18-BEHAVIOUR-BASELINE.md` §
  "GATE-01 Recurrence Protocol" — the protocol D-21-08 follows.

### Debt items
- `.planning/milestones/v3.0-phases/16-workspace-overview/` — the eight
  `16-0N-SUMMARY.md` files, `16-UAT.md` and `16-OVER04-MEASUREMENT.md` that
  D-21-23 reconstructs from. `16-05-SUMMARY.md:50` and `16-06-SUMMARY.md:52` are
  the two malformed `coverage:` blocks (D-21-24).
- `.planning/STATE.md:645-655` — the audit rows recording Phase 16's open items,
  the `260728-51j` `missing` row (line 653) and the malformed-block row (655).
- `.planning/REQUIREMENTS.md` lines 59-61, 70, 72, 89 — the six requirements this
  phase owns.
- `.planning/ROADMAP.md` § "Phase 21" — the phase entry, its five success
  criteria and its notes (incl. the cava-spike framing D-21-00 resolves and the
  "second of three, not third" reader-count honesty note).
- `.planning/todos/pending/2026-08-15-unify-frost-values-across-surfaces.md` —
  the measured frost table and the `hyprctl` testing constraints (D-21-26).
- `.planning/todos/pending/2026-08-13-ambient-dnd-indicator.md` — the false
  "popups are broken" report that motivates D-21-27.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`MediaTab.qml:525-551`** — a working `Shape` with `preferredRendererType:
  Shape.CurveRenderer`, a `ShapePath` (`DashLine`, `RoundCap`, `dashPattern:
  [1,3]`) and a `PathAngleArc`. The radial visualiser is a `Repeater` over this
  same machinery, not a new rendering technique.
- **`ags/.config/ags/lib/cava.ts`** — a proven cava streaming reader on this
  host. The QML `Process` + `SplitParser` mirrors its line handling exactly,
  including the "ignore blank/partial lines" rule.
- **`MediaBackend.qml`'s native `Mpris` projection** — `players`,
  `activePlayer`, `selectPlayer`, `hasVolume`/`volumeLevel` and the clamped
  volume write already exist. D-21-09's dedup and D-21-10's per-player volume
  extend this file; no new reader is introduced.
- **`MediaBackend.qml`'s single-flighted `Process` pattern** (the album-art
  resolver, with its request-URL last-write-wins key and its in-flight chase) —
  the established shape for a QML-owned subprocess here.
- **`Dashboard.qml`'s `initialTabIndex` / `tabIndexMedia`** — D-21-12's
  open-to-a-specific-tab is a parameter that already exists.

### Established Patterns
- **Zero-idle backends** — nothing runs while its surface is dismissed. D-21-06
  is this rule applied to a process that currently violates it 24/7.
- **Layer rules after the family regex, alpha at or above the floor** — three
  worked examples already in `windowrules.lua`; now also D-21-26's constraint.
- **Config-then-package, one commit** — the WINDOWS #1 retirement precedent,
  applied four times already this milestone.
- **`REPRESENTATIVE_FILES` names one file per contract format** — deleting a
  contract entry can break a checker unrelated to the surface. Verified clear
  here, but verified rather than assumed.
- **Comment-only references survive deletions and trip the leftover sweep** —
  Phase 20's final plan stalled on exactly this; D-21-19 resolves it by rewriting
  rather than exempting.

### Integration Points
- Three surfaces read media state today; after this phase, one reader
  (`MediaBackend.qml`) feeds three views (Media tab, bar capsule, bar popout).
- The reload fan-out loses its `ags request reload-css` step; QML hot-reloads
  natively, so nothing replaces it.
- `contract.json` 18 → 17. This is the **fifth and final** contract entry removed
  in this milestone; Phase 22 proves the result on a fresh install.
- A new `cava/` stow package joins `stow.sh` — the only package **added** during
  a milestone otherwise defined by deletions.

</code_context>

<specifics>
## Specific Ideas

- **The visualiser and the cover shape were both chosen from rendered ASCII
  comparisons**, not from prose descriptions. The operator has now selected
  visual options from rendered previews across three consecutive phases. **Show
  the surface, do not describe it** — and treat a live rejection after a first
  render as a normal part of this process, not a failure of it.
- **The silence-state argument is what carried D-21-01.** The radial-bar design
  was accepted specifically because at silence it degrades to the ring already
  accepted at round 3 — nothing previously approved is put at risk. Preserve that
  property in the implementation: at silence the ring must still read as the
  round-3 ring, which means the minimum sliver length and the bar spacing have to
  land near the existing `dashPattern: [1,3]` density at 60 bars.
- **The operator explicitly reserved the right to revisit D-21-06.** They will
  test the linger in daily use and may revert to always-on. That is a stated
  expectation of a follow-up conversation, not a hypothetical — build the knob.
- **"Which option is better in terms of smooth look vs performance?"** was
  answered with a live measurement rather than an estimate, and the measurement
  changed the recommendation (performance turned out to be a non-issue; startup
  latency was the only real variable). Downstream agents should expect the same
  standard: **measure on this host rather than asserting a cost.**
- **Plain language was explicitly requested** during this discussion — the
  operator asked for "human readable terms and not gsd codes". When surfacing
  choices or findings to the operator, explain the thing rather than citing the
  requirement ID.

</specifics>

<deferred>
## Deferred Ideas

- **Lyrics display** (Caelestia's `LyricsAndSelector`/`LyricList`) — no lyrics
  service exists anywhere in this backend. Recorded as not-attempted in
  `MediaTab.qml`'s header and still out of scope.
- **Shuffle and repeat transport** — was blocked by `media-players.sh cmd`'s verb
  allowlist, which this phase deletes. The native `MprisPlayer` object may expose
  loop/shuffle properties, so the original blocker no longer applies — but it is
  not in this phase's requirements. Revisit as its own item.
- **Per-track dominant-colour re-tinting** (end-4's `ColorQuantizer`) —
  permanently excluded, not deferred: it is a second competing colour source
  against the theme-engine palette (`FEATURES.md:172`).
- **Decorative mascot GIFs** (Caelestia's BPM-synced bongocat) — needs an asset
  path outside theme-engine for a purely cosmetic feature (`FEATURES.md:174`).
- **The `BackgroundShapes` bokeh layer** — depends on an `M3Shapes`-style path
  renderer this repo does not have. D-21-02 hand-authors one shape, not a shape
  library; a general renderer remains out of scope.
- **A validator for malformed `coverage:` blocks** — declined at D-21-24 as new
  tooling for a problem that stopped recurring on its own.
- **Annotating Phase 16's reconstructed report with later phases' fixes** —
  declined at D-21-23 in favour of a clean historical record. If a
  "what has since closed" view is wanted, it belongs in a milestone audit, not
  in a phase's own verification report.
- **The OVER-04 frame-rate floor measurement** — Phase 16 left it UNMEASURED and
  D-21-23 records that faithfully rather than closing it. Still open; still needs
  an owning phase.
- **The remaining WINDOWS.md rows** batch re-deferred under Phase 20's D-20-40 —
  each needs a named owning phase at triage time.

</deferred>

---

*Phase: 21-Media Fold-In & Contract Close*
*Context gathered: 2026-08-16*
