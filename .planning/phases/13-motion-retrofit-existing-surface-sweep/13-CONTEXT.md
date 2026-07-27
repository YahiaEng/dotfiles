# Phase 13: Motion Retrofit & Existing-Surface Sweep - Context

**Gathered:** 2026-07-27
**Status:** Ready for planning

<domain>
## Phase Boundary

Point every **already-existing** surface at the token pipeline Phase 12 built —
Hyprland's window/workspace/layer animations plus the live GTK surfaces — and
close the carried-in debt that sits on those same surfaces in the same sweep.

**This phase consumes a mechanism; it does not build one.** `motion.json`,
`motion.sh`, the three render targets, `motion-switch.sh` and `motion-lint` all
already exist and work (Phase 12: `motion-lint` 37/0, `theme-parity` 1985/0). What
this phase adds is a **fourth** consumption path — sass-compiled GTK3 stylesheets —
and then retires every remaining hand-authored motion value in the repo.

Requirements: MOTION-01, MOTION-02, MOTION-03, MAINT-02, MAINT-03.

**Surfaces that get retrofitted (3):** Hyprland, waybar, swaync.
**Surfaces already covered (3):** walker, SwayOSD and the AGS media card are
compositor-animated via `animation = layers` — MOTION-01's retrofit makes them
token-driven with zero client-side change (see D-05). wleave was retrofitted in
12-07.

**Explicitly NOT in this phase:** any new in-surface motion design (deferred to
Phase 14, which defines the in-surface vocabulary once on QML), any QML surface,
and any retirement of an existing surface (v3.0 standing constraint 4).

</domain>

<decisions>
## Implementation Decisions

### GTK3 Token Mechanism

- **D-01: GTK3 surfaces consume motion tokens via a sass precompile step.** Repo
  authors `.scss`; `motion.sh` emits a `_motion.scss` partial; `theme-apply`
  compiles into `~/.local/state/theme/`; surfaces launch pointed there via their
  existing style-path flags. GTK3 3.24.52 has no CSS custom-property
  implementation (binary-verified in Phase 12), so `var(--motion-*)` is
  unavailable and some form of preprocessing is the only path that keeps design
  in the repo and tokens in the engine.
  **The two costs that would normally sink this are already paid** — verified
  during discussion, do not re-derive: `swaync -s/--style`, `swayosd-server
  -s/--style <CSS File Path>` and `waybar -s` all exist on the installed binaries,
  and `dart-sass` is already a **hard** `install.sh` dependency (line 206: "without
  it `ags run` aborts"). `contract.json` already carries an `scss-vars` format
  (feeding `ags.scss`), so no new format handler is needed for the partial.
  Rejected: templating the stylesheets through `motion.sh`'s printf (pays this
  option's entire structural cost for a far weaker language); emitting complete
  literal-valued rules from the engine (moves selectors — design decisions — into
  the theme engine, against the boundary every prior phase defended); recording a
  permanent GTK3 limitation (D-13/D-15 precedent, but concedes half of criterion 1
  on day one).
  — **Reversibility:** costly — undoing means moving three launch paths back,
  reverting `contract.json` entries, re-teaching two lints to read `.css`, and
  removing a `stow.sh` seed step.

- **D-02: Scope is waybar + swaync only. SwayOSD does NOT convert.** SwayOSD's
  stylesheet contains **zero** motion literals — its motion is entirely
  compositor-delivered (D-05) — so converting it would add a fresh-install failure
  path with no coverage behind it. Its `motion-lint` entry stays, with its reason
  rewritten from "GTK3, no variable mechanism exists" to the accurate permanent
  reason "no motion literals — motion is compositor-delivered via `animation =
  layers`". D-23's recorded-reason discipline already distinguishes a permanent
  exemption from pending debt, so this does not read as unfinished work.
  Payload at stake: waybar **31** literals, swaync **6**, SwayOSD **0**.

- **D-03: The compiled sheet bakes in motion only; colour stays a live
  `@import url()`.** Reload path, `theme-parity`'s colour walk and the SIGUSR2 /
  `swaync-client -rs` fan-out are all unchanged; a recompile is triggered by a
  **motion-scale** change, not by a theme change. This preserves the
  theme-orthogonality D-01 (Phase 12) was built on — `motion.sh` follows `font.sh`'s
  theme-orthogonal axis pattern, and D-31 asserts motion output is byte-identical
  across all 22 palettes precisely to prove that independence. Inlining colour
  would break that assertion outright and couple two axes Phase 12 deliberately
  kept apart.

- **D-04: File-for-file compile — all six waybar files convert; the `@import`
  graph survives.** Each `.scss` compiles to its own `.css` in the state dir, with
  `@import url()` links rewritten sibling-relative. **Decisive reason:**
  `waybar-visibility.css` is engine-owned state rewritten *at runtime* by
  `waybar-visibility.sh` on every OLED hide/show, entirely outside `theme-apply` —
  any approach that inlines imports risks turning that live channel into a stale
  snapshot, and BAR-01's single-owner visibility mechanism is hard-won. Keeping
  every import an import means the only thing that changes is *where the files
  live*. `theme.css` converts too despite carrying no motion: a lone `.css` beside
  five `.scss` siblings is the asymmetry a future editor "fixes" wrongly.
  Rejected: inlining `theme` and `waybar-modules` as sass partials — it
  reintroduces, in the output, the four-copies duplication `waybar-equivalence-check`
  was built to detect after "four copy-pasted layout files drifted constantly"
  (Phase 8).

- **D-05: `stow.sh` seeds the compiled sheets by invoking the real compiler, and
  fails loudly.** After conversion the file waybar is launched with only exists if
  sass ran — today it is a stow symlink present the instant `stow.sh` runs. This is
  D-30's exposure with a wider blast radius, so it takes D-30's answer: seed from
  the real renderer, never a hand-written stub, mirroring the `waybar-visibility.css`
  seed at `stow.sh:112–120`. **`stow.sh:135`'s `|| true` tolerance does NOT extend
  to this step** — a silently unstyled desktop with no error to search for is worse
  than a failed install. Note `waybar-launch.sh:32`'s disk-truth validation only
  *picks a layout*; it falls back to `full`, whose sheet would be equally missing.
  Rejected: committing a pre-compiled default sheet (a generated artifact in git,
  against the repo's most-enforced invariant, and stale on the next `.scss` edit).

### Motion Coverage — What Actually Needs Retrofitting

- **D-06: walker, SwayOSD and the AGS media card need no client-side motion.**
  `animations.conf:47` already carries `animation = layers, 1, 4, md3_decel, popin
  80%` — these surfaces were never motionless; their motion is compositor-owned.
  Criterion 1's operative test is *"no raw duration left in any repo-authored
  config or stylesheet"*, and all three have **zero**. MOTION-01's retrofit of the
  layer animation makes them token-driven with no client change.
  **Why not more:** in-surface motion (walker's selection highlight, SwayOSD's
  fill bar, the AGS transport state) is *new capability*, not retrofit — three
  design surfaces and three blocking human gates on an already-full phase. Phases
  14/15 define this desktop's in-surface motion vocabulary from scratch on QML;
  inventing a separate GTK-side vocabulary one phase earlier means designing it
  twice and reconciling it later. Per-surface deviation stays available via
  `layerrule` (wleave precedent, `windowrules.conf:254`).

- **D-07: Layer motion splits into `layersIn` / `layersOut`.** Verified valid on
  0.56.0. Consumes `motion.json`'s `emphasized-in` (medium2/300ms, decelerate) and
  `emphasized-out` (short3/150ms, accelerate) — two semantic pairs that exist today
  with **no consumer**, a strong signal they were designed for exactly this. MD3
  argues exits should be shorter than entrances; a single `layers` entry cannot
  express that.
  **Per-namespace style overrides are NOT assigned up front.** They are added only
  if the render gate says a specific surface reads wrong — the phase already has
  blocking gates, so taste is decided by looking rather than by planning document.

- **D-08: Dead `wofi` layerrules (`windowrules.conf:187,263`) are deleted in this
  phase.** wofi was removed in v1.0; this is the designated existing-surface sweep
  and the file is already being edited. Same class as quick task 260725-vu6's eww
  layerrule cleanup.

### Hyprland Retrofit — MD3 Purity

- **D-09: MD3 purity — the 5 character curves are REPLACED, not promoted.**
  `wind`, `winIn`, `winOut`, `smoothIn`, `smoothOut` are replaced with MD3
  equivalents rather than moved verbatim into `motion.json`; the 3 dead beziers
  (`overshot`, `crazyshot`, `bounce` — declared, never referenced) are deleted; the
  4 byte-identical duplicates (`md3_standard`, `md3_decel`, `md3_accel`, `liner`,
  feeding 7 of 13 `animation =` lines) become token references.
  **The user chose this over the recommendation** (promote the character curves
  verbatim, which would have satisfied criterion 1 at zero perceptual change).
  Recorded risk, accepted knowingly: this deliberately changes how window
  open/close/move and fades *feel* on a daily-driver desktop. The current curves
  carry intentional overshoot (`winIn 0.1,1.1,0.1,1.1`) and undershoot
  (`winOut 0.3,-0.3,0,1`). The human render gate (D-16) and the soak (D-13) are the
  instruments that judge it.
  — **Reversibility:** costly — undoing means re-sourcing five curves that were
  deleted from the tree, and D-11's policy explicitly forecloses restoring them
  from history.

- **D-10: The easing scale grows to the full MD3 set BEFORE the retrofit, sourced
  from Material's own specification and cited in `13-RESEARCH.md`.** `motion.json`
  holds only four easings today — the MD3 *base* set, not the full scale D-25
  describes carrying. Control points must come from the primary spec with values
  reproduced in the research doc, **not** from another rice's config file. Two
  precedents make this non-negotiable: TOKEN-06's rejection was specifically about
  unsourced constants (`spring:300/damping:20/mass:1`), and `07-RESEARCH.md` claimed
  `walker -s runner` worked "based on reading the config file, never running it".
  **Research blocks the phase if no primary source is reachable.**

- **D-11: A namespaced non-MD3 extension is PRE-AUTHORIZED but not used by
  default.** Concern raised and accepted during discussion: MD3's documented
  *easing* vocabulary appears to contain no control points outside [0,1] — the
  overshoot in **MD3 Expressive** is expressed as **spring physics**, which TOKEN-06
  evaluated and rejected. If that holds, "full MD3 vocabulary" contains no overshoot
  at all, and D-12's escape policy would make overshoot's departure permanent and
  irreversible. So: ship pure MD3 as decided, but a small, documented, clearly-marked
  non-MD3 overshoot set defined **once** in `motion.json` is pre-authorized as the
  landing spot. Criterion 1 forbids *one-off* beziers, not non-MD3 ones — a curve
  defined once and referenced from three targets is by definition not a one-off.
  Costs nothing if research proves the concern wrong.
  **Corroborating finding:** `motion.json`'s `linear` is `[1,1,1,1]` — Hyprland's
  `liner` convention, **not** CSS/MD3 linear (`0,0,1,1`). The vocabulary was already
  Hyprland-flavoured rather than strictly MD3.

- **D-12: On a soak rejection, a motion is re-tuned WITHIN MD3 — never reverted to
  a hand-authored curve.** Re-map to a different MD3 curve or duration. The
  vocabulary stays strictly pure even at the cost of not recovering a specific prior
  feel. (D-11's pre-authorized extension is the one sanctioned landing spot, and it
  is a shared single-sourced token, not a revert.)
  — **Reversibility:** one-way in spirit — this policy is what makes D-09's curve
  deletion irreversible.

- **D-13: Hyprland's `speed` unit is confirmed by extreme-value observation before
  the duration conversion is written.** Set one animation to a deliberately huge
  speed, watch it once, confirm the magnitude. Closes D-09 (Phase 12), which left
  the unit unconfirmed. It is the smallest test that can actually *fail* — the
  standing bar from D-18/D-28 ("a gate that cannot fail is not a gate"). Trusting
  the documented `ds` unit and asserting via readback proves only that Hyprland
  stored what we wrote; the gate would be green while every duration is off by 10×.
  Live readback for reference: `layers` 4.0, `windowsIn` 5.0, `border` 10.0,
  `borderangle` 100.0. No string in the Hyprland binary states the unit.

- **D-14: Style keywords (`popin 60%`, `slide`, `slidevert`, `loop`) stay
  hand-authored in `animations.conf`, explicitly out of the token source.** They
  select a spatial transform, not a duration or curve, and have no GTK4/QML
  counterpart, so they cannot round-trip through `motion.json`'s two-layer
  duration+easing schema (D-05). Putting them in would break D-31's cross-target
  byte-identity premise. Recorded explicitly so a future reader does not misread
  them as missed debt.

### Token Mapping

- **D-15: Reuse existing semantic pairs; add only for genuine gaps; blink pulses
  are a separate non-semantic category.** Grounded in the actual values:
  - **swaync** is trivial — all 6 literals are the *identical* rule
    `transition: all 0.2s ease`. `motion.json`'s existing `standard` pair
    (`short4` = 200ms + `standard` easing) is an exact duration match; `ease` → MD3
    `standard` is the only change.
  - **waybar's real vocabulary:** `0.3s` ×13, `0.2s` ×3, `0.5s` ×1, `1s` ×1, one
    `cubic-bezier(0.25, 0.46, 0.45, 0.94)` (easeOutQuad, in athena), rest `ease`.
    The `0.2s` cases map to `standard`; one neutral 300ms transition pair is added
    for the dominant value (`emphasized-in` is 300ms but pairs with a decelerate
    curve, so it is not a neutral substitute).
  - **`battery-blink` (1s) and `float-battery-blink` (0.5s)** are infinite
    alternating **state indicators**, not transitions — `linear`, no MD3 counterpart,
    no cross-target meaning. Forcing them into the semantic layer would put a token
    in the shared source no other target could consume — the same objection that
    keeps D-14's style keywords out.
  Rejected: a semantic pair per distinct value (manufactures names for numbers;
  `motion-duration-300` is a literal with extra steps, against D-05's semantic
  naming); collapsing everything onto the existing three (shifts waybar's dominant
  `0.3s` to `0.2s` — thirteen timing changes to a constantly-visible bar, for
  convenience rather than design).

- **D-16: The four waybar layouts share one vocabulary but choose their own
  tokens.** Today's deliberate differences are preserved (floating snappier than
  athena). Phase 8 approved each layout as "its own design flow, user-approved on
  sight under light, dark and dynamic" — those differences are gated design, not
  drift. Consistency of *vocabulary* is the goal; consistency of *choice* is a
  different and unrequested thing. **Note:** athena's `easeOutQuad` is hand-authored
  and non-MD3, so D-09 replaces it regardless — the one waybar feel change, judged
  at its render gate.

### Gates, Soak and Evidence

- **D-17: Three per-plan render gates (Hyprland, waybar, swaync), asking only the
  FIDELITY question.** Not six — walker/SwayOSD/AGS are covered by the Hyprland gate
  under D-06, and wleave was gated in 12-07. The instrument already exists: D-15/D-16
  (Phase 12) built the token inspector with a replayable motion row fired from a
  button, which is literally what criterion 2 asks for ("a side-by-side of the token
  as QML renders it against its fitted GTK4/Hyprland rendering").
  **The pass condition is a token match:** does the same named token visibly render
  the same in the QML inspector's replay row and on this surface? Objective,
  falsifiable, answerable in a minute — a fitted curve that renders differently in
  GTK than in QML is exactly what it catches.
  **Fidelity/taste split is explicit and load-bearing:** the gate asks fidelity; the
  soak asks taste. Conflating them is how a gate becomes a rubber stamp — asked
  "does this look OK?" at plan close, the honest answer is always "yes, I guess",
  because taste needs time and fidelity is what is checkable on the spot.
  Per-plan over end-of-phase per standing constraint 1 and D-27, overriding
  `config.json`'s `human_verify_mode: "end-of-phase"`.

- **D-18: The soak is front-loaded, not appended.** The Hyprland motion change
  lands in the **first** plan; the soak accrues while the sass conversion, MAINT-02,
  MAINT-03, WINDOWS #9 and the ledger pass proceed — work that shares no files with
  the motion retrofit. No idle wait, no deferred promise. **Plan order is a fixed
  constraint in this document, not a planner preference.** Matches how this repo
  front-loads risk (Phase 10 gated at plan 2, Phase 11's tracer at plan 1, D-32's
  settle-the-risky-structure-first sequencing), and puts the riskiest change under
  the longest observation.
  Rejected: a blocking soak at the end (the phase sits idle at the finish line, a
  shape no prior phase has used); closing with a deferred verification item (the
  "record it and never do it" failure criterion 3 exists to prevent — Phase 4's
  WR-01..04 are still open two milestones later, *in this very phase*).

- **D-19: The soak floor is a session/interaction count, not calendar days.**
  Closer to what criterion 3 actually cares about (high-frequency interactions) and
  immune to a day spent away from the machine. **Consequence the planner must
  respect: the soak floor is incompressible** — an overrun cannot be absorbed by
  shortening it, which is why D-24 names a scope-shaped relief valve.

- **D-20: The soak record is a per-motion verdict table.** One row per retrofitted
  motion (window open/close/move, workspace switch, notification, layer entrance,
  fade) with verdict and note. Feeds D-12's escape policy directly, since that acts
  per-motion. Matches this project's established evidence-artifact shape
  (`12-MOTION-VERDICT.md`, `11-QUICKSHELL-EVIDENCE.md`, `08-BAR-02-EVIDENCE.md`).
  A single end-of-soak pass/fail is structurally the "single click-and-look"
  criterion 3 forbids, just delayed.

- **D-21: A temporary A/B toggle ships as the measuring instrument, removed at
  phase close.** A motion-switch-style preset flipping between the pre-retrofit
  character curves and the new MD3 set, so the soak verdict is *comparative* rather
  than judged against days-old memory after acclimatization. Near-zero cost —
  `motion.json`'s named-preset `scales` table (D-21, Phase 12) and `motion-switch.sh`
  already exist. Direct precedent: Phase 12 shipped and *kept* the spring/MD3 toggle
  in `Probe.qml` as a comparison instrument even after springs were rejected.
  The toggle is **not** a reversion path — D-12 forecloses that. It is the
  measuring device.

- **D-22: On a mixed soak verdict — retune, targeted re-soak, then remove the
  toggle.** The per-motion verdict table names exactly which motions failed, so the
  re-soak covers only those; it is well-defined rather than a full restart. The phase
  closes on a clean verdict. Rejected: closing with retuning as a follow-up (creates
  a deferred motion fix inside the phase that is cleaning up three separate deferred
  items).

### Existing-Surface Debt

- **D-23: `current.jpg` is untracked, gitignored, and seeded at install** (WINDOWS
  #9, fix option (a)). **Decisive structural fact:** `~/Pictures/Wallpapers` resolves
  into the repo working tree (the stow link sits at a parent level), so `current.jpg`
  is a **tracked file inside the repo that five code paths rewrite at runtime** —
  `wallpaper.sh:65`, `wallpaper-picker.sh`, Thunar's `uca.xml` action — and that two
  paths *read*: `generate.sh:11` (Material You's matugen source) and
  `hyprlock.conf:50`. This is not a gate bug; it is runtime state committed to git.
  Untracking makes the clean-tree invariant **actually true** rather than teaching
  the gate not to look, and directly applies PROJECT.md's most-enforced rule
  ("Generated theme output lives in `~/.local/state/theme/`, never in git").
  **The seed points at today's committed target (`catppuccin/5-alien-planet.jpg`)**
  so fresh-install behaviour is byte-identical to now. Seeding is load-bearing and
  consolidates with D-05's seeding rather than adding a new failure class; the
  container gate and graphical VM already walk this path.
  Rejected: exempting the path from `theme-doctor`'s clean-tree check — the tree
  genuinely *is* dirty after every static theme switch, so the gate would report
  clean while the stated invariant is false. That is the green-gate-over-broken-reality
  pattern behind the Phase 6 and Phase 8 failures, and it leaves the trap armed for
  anyone running plain `git status`.
  — **Reversibility:** one-way in practice — re-tracking a file that has been
  gitignored and locally rewritten means choosing a canonical target again.

- **D-24: A full 10/10 `theme-stress-test` run is a BLOCKING phase-closing gate.**
  The direct proof #9 is fixed. More importantly, this phase inserts a new sass
  compile step into `theme-apply` for two surfaces — that step must survive ten
  consecutive switches, not one. `theme-stress-test` is built for exactly the
  works-once-then-degrades class, and D-17's live re-colour assertions ride along
  free. The Phase 12 close is the counter-argument to running it non-blocking: a
  scratch-patched copy "expected to pass identically" and did not.

- **D-25: `WINDOWS.md` is reconciled — stale entries plus this phase's own.**
  Items **1** and **2** are already fixed in reality (STATE.md records the orphaned
  `eww.scss` entry dropped by quick task 260725-vu6, and `keybind-doctor` repaired in
  Phase 11) and were simply never marked. Item **8** (the 13-vs-14 `animation =`
  count) resolves the moment this phase rewrites `animations.conf`. Item **9** closes
  under D-23. `open_count` goes **9 → 5**, all genuinely open. Items 3–7 stay open
  and honest. Rationale is D-14's (Phase 12): a ship-blocking gate everyone knows is
  falsely red is a gate nobody reads.

### MAINT-03 — Icon Browse and Install

- **D-26: Browse is a Ctrl-A toggle inside the existing picker.** Exact reuse of
  THM-04's shipped, user-approved pattern — the wallpaper picker is "restricted per
  static theme with Ctrl-A browse-all". Same muscle memory, one surface, no new
  keybind or cheat-sheet entry. Rejected: a separate "Install icon theme" menu entry
  (a second surface to theme, bind, document and maintain — what Phase 7 chose
  against); one merged list (28+ packages permanently diluting a list normally used
  to pick among ~6 installed themes).

- **D-27: AUR is included in browse by default.** Criterion 5 requires "from the
  repos **or** AUR", and the repo catalog omits nearly every icon theme people
  actually want (Tela, Colloid, WhiteSur). `install.sh:304–317` already resolves an
  AUR helper (`paru`, else `yay`, else bootstraps `paru`). Build failures surface
  loudly by construction — the floating kitty is a real terminal, so `paru` prompts
  and streams output normally.

- **D-28: Browse previews are real icons, fetched and extracted without
  installing.** Verified during discussion, no root needed: `pacman -Sp <pkg>` prints
  the package URL directly (e.g.
  `https://fastly.mirror.pkgbuild.com/extra/os/x86_64/…pkg.tar.zst`) and `bsdtar
  3.8.8` is installed. Fetch → extract a handful of icons → render through the
  picker's existing `kitten icat` montage + cache pipeline. Real theme, **no
  committed blobs, no staleness, no curation table**. Previews are lazy and cached,
  with a visible "fetching…" state (icon-theme packages are tens of MB). AUR entries
  have no prebuilt package, so they fall back to `paru -Si` package metadata.
  Rejected: committing curated screenshots (binary blobs in a dotfiles repo, a list
  that ages, most entries still falling back); a hybrid (two mechanisms and two
  failure modes feeding one pane).

### MAINT-02 — Phase 4 Advisory Items

- **D-29: WR-04 is verified empirically before being wrapped or documented.**
  **The review's file references are stale; the defect is not.** `powermenu.sh` is
  **gone** (deleted with the wlogout retirement) and `wlogout/` no longer exists. The
  live logout path is `wleave/.config/wleave/layout.json`, and it still reads
  `logout -> cliphist wipe; uwsm stop` — bare — while reboot/shutdown use
  `hyprshutdown --post-cmd`. PROJECT.md's Key Decision row covers Shutdown/Reboot
  (wrapped) and suspend/hibernate (deliberately bare, with a reason); **logout is the
  one case the table never addresses**, which is exactly WR-04's complaint.
  WR-04 is written as a conditional — *if* the FIX-01 hang class applies to logout,
  wrap it; *if* it was deliberately excluded, document that — and nobody currently
  knows which. Test whether `uwsm stop` actually stalls on unclosed clients on this
  build, then decide. Rejected: wrapping unconditionally (applies a fix of unproven
  necessity to the one power action that already exits the compositor by definition,
  where `--post-cmd 'uwsm stop'` may be redundant or subtly wrong); documenting an
  exemption (the reason would be invented rather than established, which is worse
  than leaving the item open).

- **D-30: WR-01/02/03 are proven by per-item fault injection.** Point the fisher
  bootstrap `curl` at a non-200 URL, move the nvm version directory aside, confirm
  the uv guard with the file absent. Each fix must be individually falsifiable — the
  "a gate that cannot fail is not a gate" discipline behind D-18/D-28. The exact
  one-line fixes are already written out in
  `.planning/milestones/v2.0-phases/04-reliability-fixes-tech-debt/04-REVIEW.md`;
  the *proof* is the requirement, not the edit.
  **The `verify/container-run.sh` rerun is NOT folded in** — the D-34/D-36
  container-tier reproducibility proof stays deferred (user decision).

### Motion-Lint End State

- **D-31: wleave's D-19 fence HOLDS.** Its three literal `150ms ease` transitions
  are tokenized (this phase owns them — the `LINE_EXEMPTIONS` reason says "pending
  Phase 13"), but the hand-authored overshoot timing function
  `cubic-bezier(0.55, 0, 0.28, 1.68)` stays, with its exemption reason rewritten from
  "pending Phase 13" to **permanent**: human-approved feel at a prior render gate
  ("button glows and grows larger"), deliberately preserved. This is a knowing
  exception to D-09's MD3 purity, scoped to one already-gated rule.

- **D-32: Exemption list end state — zero "pending Phase 13" entries, three
  permanent ones.**

  | Entry | At close |
  |---|---|
  | `waybar/*.css` | **removed** — converted and tokenized |
  | `swaync/style.css` | **removed** — converted and tokenized |
  | `hypr/config/animations.conf` | **removed** — tokenized |
  | `swayosd/style.css` | **kept**, reason rewritten to permanent (D-02) |
  | `walker/**/style.css` | **kept**, reason rewritten to permanent (0 literals, compositor-delivered) |
  | `ags/*.scss` | **kept**, reason rewritten to permanent (0 literals, compositor-delivered) |
  | `LINE_EXEMPTIONS` wleave hover rule | **kept**, reason rewritten to permanent (D-31) |

- **D-33: "Zero pending exemptions" is asserted by an OPT-IN flag, not a default
  check.** `motion-lint --no-pending`, named here as a phase-closing gate alongside
  D-24's 10/10 stress test. Same mechanical falsifiability where it matters, without
  turning a legitimate temporary Phase 14/15 exemption into a permanently red gate
  for the next four phases. **Direct in-repo precedent:** `motion-lint --self-test`
  and `keybind-doctor`'s path-argument self-test are both flag-gated extra assertions
  rather than default behaviour — this repo has already chosen this shape twice.
  Rejected: a default check (punishes the normal workflow, and stretches
  `motion-lint` from per-file compliance into phase-completion judgement); advisory
  only (structurally the same check that left ledger items 1 and 2 marked open for
  months after being fixed).

### Pipeline Integration

- **D-34: The sass compile runs INSIDE `theme_engine_generate`**, rendering into
  the tmp tree so `commit.sh`'s atomic render-then-commit invariant holds unchanged —
  a failed compile commits nothing and leaves state consistent. It becomes a fourth
  sibling writer alongside `theme_engine_render_font_files`,
  `theme_engine_render_gtk_settings` and `motion.sh`'s renderer, which is exactly the
  shape D-01 (Phase 12) established. The tmp-path concern does not arise: under D-03
  colour stays an `@import url()`, and sass never resolves those URLs. Rejected: a
  post-commit compile (opens a window where colour is applied but stylesheets are not
  yet recompiled — a partially-applied theme, breaking the atomicity every other
  writer preserves).

- **D-35: The compiled stylesheets get full format-validated `contract.json`
  `files` entries**, not `presence_only_files`. Same reasoning D-03 (Phase 12) used
  for the motion targets: `contract.json` is PROJECT.md's declared single source of
  truth for the output contract, and a render target outside the manifest is a drift
  vector. Because the compiled sheets bake in motion and import colour, they are
  **theme-independent** — so D-31's byte-identity assertion extends to them unchanged
  (identical across all 22 palettes, both modes, both render branches, at a fixed
  motion-scale), which also proves the compile is wired into *both* the static-preset
  and materialyou branches. Nothing else checks that. Presence-only would pass a sass
  run that emitted an empty or partial sheet — the checker/renderer drift Phase 2
  exists to prevent.

- **D-36: Motion-scale switching keeps ONE entrypoint; latency is measured, not
  designed around.** `motion-switch.sh:118` already states the contract — *"One
  entrypoint, per TOKEN-05's 'driven through theme-apply's existing single
  entrypoint' — this script never writes a rendered file itself"* — so it writes the
  state file and triggers exactly one full `theme-apply` re-render, and the sass
  compile lands inside that automatically. Measure the added cost and treat slowness
  as a **finding**, not a design input. Rejected: a recompile-only fast path — a
  second render path that can drift from the first, which is exactly the class the
  consolidated `theme-engine` was created to end (PROJECT.md: "three duplicated
  orchestrators kept drifting"). Precedent: Phase 4's evidence-first perf decision,
  where profiling disproved two confident guesses.

### Sequencing and Scope

- **D-37: Fixed ordering spine.** MD3 sourcing (D-10) **before** the Hyprland
  retrofit → **Hyprland retrofit + A/B toggle FIRST** (D-18, starts the soak clock)
  → sass mechanism **before** waybar/swaync conversions → `current.jpg` untrack
  (D-23) **before** the 10/10 stress test → 10/10 stress test (D-24),
  `motion-lint --no-pending` (D-33) and the soak verdict (D-20) as **closing** gates.
  MAINT-03 sequences mid-to-late: it blocks nothing, touches only
  `icon-theme-picker.sh`, and naturally fills the soak window.

- **D-38: On an OBSERVED overrun, MAINT-03 may split to its own phase.** Not as a
  preference — the trigger is an observed overrun. Icon browse shares zero files with
  the retrofit, so the split is nearly free. **This does not contradict the roadmap:**
  its stated objection was specifically to Phase 17 ("putting it in Phase 17 would
  place twice-deferred debt inside the designated cut candidate") — a dedicated phase
  is not Phase 17. Naming the relief valve now matters because D-19's soak floor is
  incompressible, so without it, overrun pressure lands on the render gates — the
  exact mechanism protecting D-09's deliberate feel change. Unplanned deferral is this
  repo's most reliable failure mode (WR-01..04 deferred twice, the container gate
  deferred since Phase 7, the eww retirement left half-done with two layerrules
  missed) — and this phase is cleaning up three separate instances of it.

### Claude's Discretion

- Filenames and state-dir layout for the compiled stylesheets and the
  `_motion.scss` partial.
- How `waybar-design-lint`'s CHECK A (`@name` colour-reference resolution) is taught
  to parse `.scss` sources.
- Exact semantic token names added under D-15, and how the blink pulses are
  represented outside the semantic layer.
- Plan and wave decomposition within D-37's stated ordering constraints; granularity
  is `coarse` in `.planning/config.json`.
- The concrete session/interaction count that constitutes D-19's soak floor.
- Cache layout and "fetching…" presentation for D-28's preview extraction.
- Whether `motion-lint --no-pending`'s pending-detection is a reason-string pattern
  or a structured field on each exemption entry.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and standing rules
- `.planning/ROADMAP.md` §"Phase 13: Motion Retrofit & Existing-Surface Sweep" —
  the five success criteria, what it Owns, and the independent-branch note
  (Phase 14 does **not** depend on this phase)
- `.planning/ROADMAP.md` §"Standing constraints (apply to every v3.0 phase)" —
  constraint 1 (human render gate — see D-17, which resolves its conflict with
  `config.json`), constraint 2 (verify against the installed binary — heavily
  exercised in this discussion), constraint 3 (same-commit stow registration),
  constraint 4 (additive-only coexistence — no retirements)
- `.planning/ROADMAP.md` §"Carried-in maintenance placement" — the MAINT-02 and
  MAINT-03 → Phase 13 paragraphs; note D-38's reading that the Phase 17 objection
  does not extend to a dedicated phase
- `.planning/REQUIREMENTS.md` §"Motion (MOTION)" MOTION-01..03 and §"Maintenance
  (MAINT)" MAINT-02/03, plus §Traceability
- `.planning/PROJECT.md` §"Key Decisions" — the MD3-baseline/spring-stretch row
  (TOKEN-06 resolved: MD3 retained, springs NOT adopted), the "One motion source,
  three render targets" row, the human-render-gate row, and the
  consolidated-theme-engine row (D-36's rationale)
- `.planning/PROJECT.md` §"Current State" — the tech-debt list, specifically the
  `theme-stress-test` / `current.jpg` entry naming Phase 13 as owner

### Debt this phase closes
- `.planning/WINDOWS.md` **#9** — the full root-cause writeup and the two fix
  options; D-23 chooses (a). Also #1, #2, #8 (D-25's reconciliation targets)
- `.planning/milestones/v2.0-phases/04-reliability-fixes-tech-debt/04-REVIEW.md`
  §WR-01..WR-04 — the exact one-line fixes, verbatim. **WR-04's file references
  are stale** (`powermenu.sh` and `wlogout/` no longer exist); the live target is
  `wleave/.config/wleave/layout.json` (D-29)

### Prior phase context that carries forward
- `.planning/phases/12-unified-design-token-pipeline/12-CONTEXT.md` — **read in
  full.** Especially D-01 (theme-orthogonal axis pattern), D-04 (the Phase 12/13
  boundary this phase now crosses), D-05 (two-layer schema), D-19 (wleave fence —
  see D-31), D-21 (named-preset scale table), D-23/D-24 (lint design), D-25
  (semantic layer growth policy), D-27 (per-plan render gates), D-29
  (`engine_owned_files`), D-30 (seed-when-absent), D-31 (byte-identity assertion)
- `.planning/phases/12-unified-design-token-pipeline/12-MOTION-VERDICT.md` — the
  TOKEN-06 spring-vs-MD3 verdict and its framing as a *tuning-parameter* rejection
  of unsourced constants; directly informs D-10 and D-11
- `.planning/phases/11-quickshell-viability-gate/11-CONTEXT.md` — D-05
  (`quickshell-doctor`), D-13 (record-the-limitation house rule), D-15
  (ROADMAP-amendment precedent), D-18 (path-argument self-test)

### Code this phase modifies or extends
- `theme-engine/.config/theme-engine/lib/motion.sh` — emits three targets today
  (`hyprland-motion.conf`, `gtk-4.0-motion.css` with `:root` custom properties,
  `motion.json`); gains the `_motion.scss` partial (D-01)
- `theme-engine/.config/theme-engine/motion.json` — gains the full MD3 easing
  scale (D-10), D-11's pre-authorized namespaced extension, and D-15's semantic
  additions. Note `linear` is `[1,1,1,1]`, Hyprland's convention, **not** CSS
  linear
- `theme-engine/.config/theme-engine/lib/generate.sh` — `theme_engine_generate`
  gains the sass compile as a fourth sibling writer (D-34)
- `theme-engine/.config/theme-engine/lib/commit.sh` — the `rsync -a --delete` at
  line 94 and its `engine_owned_files`-driven excludes; compiled sheets must be
  contract entries or they are wiped (D-35)
- `theme-engine/.config/theme-engine/contract.json` — gains the compiled-stylesheet
  `files` entries (D-35)
- `theme-engine/.config/theme-engine/theme-parity` — D-31's byte-identity assertion
  extends to the compiled sheets (D-35)
- `theme-engine/.config/theme-engine/theme-doctor` — the `git status --porcelain`
  clean-tree check at line 639 (unchanged by D-23; the *tree* is fixed instead)
- `theme-engine/.config/theme-engine/theme-stress-test` — D-24's blocking 10/10 gate
- `theme-engine/.config/theme-engine/lib/wallpaper.sh` — line 65's
  `ln -sfr … current.jpg` on every static theme switch (D-23's root cause)
- `hypr/.config/hypr/config/animations.conf` — 12 beziers (4 duplicates, 3 dead,
  5 character curves) and 13 `animation =` lines; `enabled = $motion_enabled` stays
  (D-22, Phase 12). Gains `layersIn`/`layersOut` (D-07)
- `hypr/.config/hypr/config/windowrules.conf` — `layerrule = animation fade,
  match:namespace wleave` at line 254 (the per-namespace precedent); dead `wofi`
  rules at lines 187 and 263 (D-08)
- `hypr/.config/hypr/scripts/motion-lint` — `EXEMPTIONS` at line 355,
  `LINE_EXEMPTIONS` at line 394; gains `--no-pending` (D-33) and must learn `.scss`
- `hypr/.config/hypr/scripts/motion-switch.sh` — line 118's one-entrypoint contract
  (D-36); D-21's A/B toggle rides its preset mechanism
- `hypr/.config/hypr/scripts/waybar-launch.sh` — line 39's `waybar -c … -s …`
  invocation and line 32's disk-truth validation (D-05)
- `hypr/.config/hypr/scripts/waybar-design-lint` — CHECK A must parse `.scss`
- `hypr/.config/hypr/scripts/icon-theme-picker.sh` — the fzf + `kitten icat`
  montage picker; gains D-26's Ctrl-A browse mode and D-28's fetch-extract preview
- `hypr/.config/hypr/scripts/wallpaper-picker.sh` — the Ctrl-A browse-all pattern
  D-26 copies
- `waybar/.config/waybar/{style-full,style-athena,style-floating,style-vertical,
  theme,waybar-modules}.css` — all six convert to `.scss` (D-04)
- `swaync/.config/swaync/style.css` — six identical `transition: all 0.2s ease`
  rules (D-15)
- `swayosd/.config/swayosd/style.css` — **not** converted (D-02)
- `wleave/.config/wleave/style.css` — three literal `150ms` durations tokenized,
  overshoot curve fenced permanently (D-31)
- `fish/.config/fish/config.fish` — WR-01 (line ~46) and WR-02 (lines ~58-59)
- `zshell/.zshrc` — WR-03 (line ~123)
- `wleave/.config/wleave/layout.json` — the live logout action (D-29)
- `stow.sh` — the seed-when-absent idiom at lines 112–120 (D-05 mirrors it), and
  line 135's `|| true`-guarded first-boot `theme-apply`
- `install.sh` — line 206's `dart-sass`, lines 304–317's AUR helper resolution

</canonical_refs>

<code_context>
## Existing Code Insights

### Verified facts (checked against installed binaries during discussion — do not re-derive)

**Hyprland 0.56.0 layer/animation semantics** (via `Hyprland --verify-config`, no
session touched):

| Construct | Result |
|---|---|
| `layerrule = animation <style>, match:namespace X` | **CLEAN** |
| `layerrule = animation <style>, <speed>, <curve>, match:…` | **FAILS** — "invalid field 1: missing a value" |
| `animation = layers, …, nosuchbezier, …` | **FAILS** loudly — "no such bezier" |
| `animation = layersIn` / `layersOut` as separate slots | **CLEAN** |

**Consequence:** per-namespace overrides can set **style only** — duration and curve
are forced to come from the global `layers`/`layersIn`/`layersOut` entries. The
shared motion language is *structurally enforced* for every layer surface; a surface
physically cannot hand-tune its own timing.

**Live animation readback** (`hyprctl animations -j`): `layers` 4.0, `windowsIn` 5.0,
`workspaces` 5.0, `border` 10.0, `borderangle` 100.0, `fadeIn` 4.0. **No string in
the Hyprland binary states the speed unit** — D-13 owns confirming it.

**Style-path flags** (all present on the installed binaries):
`swaync -s, --style` · `swayosd-server -s, --style <CSS File Path>` · `waybar -s`
(already used at `waybar-launch.sh:39`).

**Toolchain:** `dart-sass` 1.102.0 installed and already a **hard** `install.sh`
dependency (line 206). `bsdtar` 3.8.8 installed. `pacman -Sp <pkg>` prints the
package URL **without root** (verified: returns a `fastly.mirror.pkgbuild.com` URL).
`pacman -Ss icon-theme` returns 28 packages and marks `[installed]`.

**Bezier duplication audit** — `animations.conf`'s 12 beziers vs `motion.json`'s
4 easings:

| Category | Curves |
|---|---|
| Byte-identical duplicates (feed 7 of 13 `animation =` lines) | `md3_standard` = `standard`, `md3_decel` = `emphasized-decelerate`, `md3_accel` = `emphasized-accelerate`, `liner` = `linear` |
| Declared, **never referenced** (dead) | `overshot`, `crazyshot`, `bounce` |
| Genuine character curves (overshoot/undershoot) | `wind`, `winIn (0.1,1.1,0.1,1.1)`, `winOut (0.3,-0.3,0,1)`, `smoothIn`, `smoothOut` |

**Motion literal census (repo-authored, current):** waybar **31** across 5 files
(`0.3s`×13, `0.2s`×3, `0.5s`×1, `1s`×1, one `cubic-bezier(0.25,0.46,0.45,0.94)`
easeOutQuad in athena, rest `ease`); swaync **6** (all the *identical* rule
`transition: all 0.2s ease`); wleave 30 (partly tokenized in 12-07);
**swayosd 0, walker 0, ags 0**.

**`~/Pictures/Wallpapers` resolves into the repo working tree** — the stow link sits
at a parent level, so `current.jpg` is a tracked repo file rewritten at runtime.

### Reusable Assets
- **Phase 12's token inspector** (`quickshell/.config/quickshell/modules/Probe.qml`)
  — D-15/D-16's swatches + replayable motion row. This *is* criterion 2's required
  side-by-side instrument; nothing new needs building for D-17's gates.
- **`motion-switch.sh`'s preset mechanism** + `motion.json`'s named-preset `scales`
  table — D-21's A/B toggle rides these unchanged.
- **`wallpaper-picker.sh`'s Ctrl-A browse-all** — the shipped, user-approved pattern
  D-26 copies for icon browse.
- **`icon-theme-picker.sh`'s `kitten icat` montage + cache dir** — D-28's fetched
  previews render through the existing pipeline.
- **`stow.sh`'s seed-when-absent idiom** (lines 112–120) — D-05 and D-23 both mirror
  it.
- **`motion-lint --self-test` / `keybind-doctor`'s path-argument self-test** — the
  flag-gated-extra-assertion shape D-33 copies.
- **`theme-stress-test`'s 10 consecutive switches** — built for the
  works-once-then-degrades class D-24 needs.

### Established Patterns
- Generated/runtime output lives under `~/.local/state/`, never in git; `git status`
  staying clean after theme operations is an enforced invariant (D-23 finally makes
  it true).
- Every themed surface reads from `~/.local/state/theme/` via `@import`, never a
  copied file; zero hex literals in repo stylesheets. D-03 extends this to motion.
- Rerunnable gate scripts are the standard "prove it stays true" mechanism —
  `theme-doctor`, `theme-parity`, `theme-stress-test`, `keybind-doctor`,
  `waybar-equivalence-check`, `waybar-design-lint`, `quickshell-doctor`,
  `motion-lint`.
- A gate must be proven able to fail before it is trusted to pass (D-18/D-28
  precedent) — D-13 and D-30 both apply this.
- One entrypoint (`theme-apply`) owns all rendering; no second render path (D-36).

### Integration Points
- `generate.sh` `theme_engine_generate` ← sass compile (fourth sibling writer)
- `contract.json` ← compiled-stylesheet `files` entries
- `commit.sh` ← excludes/manifest awareness of the new entries
- `theme-parity` ← byte-identity assertion extended to compiled sheets
- `theme-stress-test` ← blocking 10/10 closing gate
- `animations.conf` ← tokenized beziers + `layersIn`/`layersOut`
- `windowrules.conf` ← dead `wofi` layerrule removal
- `motion-lint` ← `--no-pending` flag, `.scss` parsing, exemption-list rewrite
- `waybar-design-lint` ← `.scss` parsing
- `waybar-launch.sh` / swaync autostart ← state-dir stylesheet paths
- `stow.sh` ← compiled-sheet seed + `current.jpg` seed
- `icon-theme-picker.sh` ← Ctrl-A browse mode + fetch-extract preview
- `.gitignore` ← `current.jpg`

</code_context>

<specifics>
## Specific Ideas

- **"These surfaces were never motionless."** The discovery that reframed the
  phase: `animations.conf:47`'s `animation = layers` already animates walker,
  SwayOSD, swaync's popup and the AGS card. Zero CSS literals meant their motion
  lived somewhere else, not that it was absent. Half the presumed retrofit work
  did not exist.

- **Fidelity is the gate's question; taste is the soak's.** Conflating them is how
  a render gate becomes a rubber stamp — asked "does this look OK?" at plan close
  the honest answer is always "yes, I guess", because taste needs time and fidelity
  is what is checkable on the spot (D-17).

- **You cannot judge a feel change you have acclimatized to.** After days on new
  curves, an absolute verdict measures adaptation, not quality. Hence D-21's A/B
  toggle — following Phase 12, which shipped and kept the spring/MD3 toggle as an
  instrument even after rejecting springs.

- **Criterion 1 forbids *one-off* beziers, not *non-MD3* ones.** A curve defined
  once in `motion.json` and referenced from three targets is by definition not a
  one-off. This is the reasoning that makes D-11's pre-authorized extension
  legitimate rather than a loophole.

- **MD3 Expressive's overshoot is springs, not beziers** — and springs were already
  evaluated and rejected by TOKEN-06. D-11 exists because that means "full MD3
  vocabulary" may contain no overshoot at all, which combined with D-12 would make
  overshoot's departure permanent and irreversible.

- **Verify against the binary, do not reason about it.** This discussion settled
  the `layerrule` field grammar, three style-path flags, `pacman -Sp`'s no-root
  behaviour and the bezier duplication audit empirically — and one probe
  (`layerrule` with speed/curve) overturned an assumption that was about to become
  a design option. Keep doing this.

- **Fix the tree, not the gate.** D-23's decisive framing: `current.jpg` is not a
  gate bug, it is runtime state committed to git. Exempting the check would report
  clean while the invariant is false — the pattern behind the Phase 6 and Phase 8
  failures.

</specifics>

<deferred>
## Deferred Ideas

- **In-surface client-side motion** for walker (selection highlight), SwayOSD (fill
  bar) and the AGS media card (transport state) — deferred to **Phase 14**, where
  the QML drawer defines this desktop's in-surface motion vocabulary once rather
  than twice (D-06).
- **Per-namespace `layerrule` style vocabulary** (notifications `slide`, OSD `fade`,
  menus `popin`) — available on demand, added only if a render gate says a surface
  reads wrong (D-07).
- **Graphical motion-scale picker** (`font-switcher.sh` shape) plus its Super-key
  settings menu entry — carried from Phase 12's D-07. Still not taken up here; the
  phase is already full.
- **`@define-color` is deprecated in GTK4 4.22.4** — migrating the colour pipeline
  to CSS custom properties is real tech debt, still out of scope (carried from
  Phase 12).
- **The container-tier D-34/D-36 reproducibility rerun** — explicitly NOT folded
  into MAINT-02's proof (D-30). Unblocked since the v2.0 push; deferred a third time.
- **Wholesale segregation of engine-owned state into its own subdirectory** —
  carried from Phase 12's D-29; belongs in a maintenance pass.
- **A real second-display hotplug test** — carried from Phases 11 and 12.
- **Restoring the pre-retrofit character curves** — foreclosed by D-12 within this
  phase, but recorded here so a future phase knows the numbers exist in git history
  (`animations.conf` before this phase's first commit) should the MD3 result prove
  unsatisfying long after the soak.

</deferred>

---

*Phase: 13-Motion Retrofit & Existing-Surface Sweep*
*Context gathered: 2026-07-27*
