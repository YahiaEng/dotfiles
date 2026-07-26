---
phase: 12-unified-design-token-pipeline
plan: 07
subsystem: theming
tags: [gtk4-css, hyprland, bash, motion, wleave, lint]

# Dependency graph
requires:
  - phase: 12-03
    provides: "motion.json, lib/motion.sh, the three rendered motion targets under ~/.local/state/theme/ this plan's @import consumes"
  - phase: 12-05
    provides: "motion-lint (CHECK A reference resolution, CHECK B raw-value refusal, CHECK C scanned-count floor), the 7-entry exemption list this plan shrinks by one, and the --self-test fixture harness"
  - phase: 12-06
    provides: "confirmation that motion-lint owed this plan no follow-up from its own work (the Motion.hasMotionTokens/Motion.pairs CHECK A collision was resolved entirely inside Probe.qml); Colours.qml/Motion.qml singleton findings unrelated to this plan's CSS-only scope"
provides:
  - "wleave/style.css consuming the emitted motion tokens (var(--motion-*)) for its entrance keyframe and label-reveal/exit transition, longhand-only per Pitfall 1"
  - "motion-lint with wleave's whole-file exemption removed, a new narrower LINE_EXEMPTIONS mechanism (one entry: wleave's hover/focus rule, D-19-fenced), and a DELAY_PROPERTY_RE carve-out for animation-delay/transition-delay lines (a lint-design gap, not a wleave defect, fixed globally not just for wleave)"
  - "live GTK 4.22.4 binary verification that a :root-scoped CSS custom property reaches a button several levels down a window's widget tree (and that a window-scoped declaration resolves identically) — settles the plan's own 'verify against the binary' open question with no motion.sh change needed"
  - "D-27 blocking human render-and-look gate on wleave APPROVED — no feel regression against the Phase 9 baseline"
affects: [13-motion-retrofit]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "GTK4 CSS `:root` custom properties are visible to descendant nodes several levels down a window's widget tree — binary-verified via a live Gtk.Application probe (get_color() resolution of a var()-referenced custom property), not assumed from the CSS spec; a `window`-scoped declaration resolves identically, so 12-RESEARCH.md's 'verify :root reaches the target node' open question is now closed for GTK 4.22.4"
    - "motion-lint's exemption model now has two tiers: whole-file EXEMPTIONS (D-23, unchanged shape) for surfaces with zero token coverage, and a new narrower LINE_EXEMPTIONS (file regex + inclusive line range) for a single rule inside an otherwise fully-covered file — prevents a whole-file exemption from silently re-exempting rules a plan just retrofitted"
    - "CHECK B's raw-value scan now excludes `animation-delay`/`transition-delay` declarations universally: a stagger/choreography value is not the same category as a duration/easing value the pipeline ever emits a token for, so flagging it as 'should be a motion token' was actively wrong, not merely undercovered"

key-files:
  created: []
  modified:
    - wleave/.config/wleave/style.css
    - hypr/.config/hypr/scripts/motion-lint

key-decisions:
  - "Only the values D-19 scopes into this phase became tokens: the hover rule's transform-duration, and the label-reveal/exit transition's duration+easing, and capsule-entrance's duration+easing. The hover overshoot curve and the hover rule's three ease/150ms transitions stay hand-authored literals — human-approved feel (overshoot) and explicit 'pending Phase 13' debt (the three ease transitions), respectively, per the plan's own action text."
  - "The hover rule's remaining literals needed a lint carve-out narrower than a whole-file exemption — added LINE_EXEMPTIONS (file regex + line range), scoped to exactly that one rule, so wleave's other two retrofitted rules (capsule-entrance, the label transition) stay under full CHECK A/B scrutiny."
  - "animation-delay/transition-delay lines are EXCLUDED from CHECK B everywhere, not just for wleave — this is a permanent lint-design fix (Rule 1), not scoped debt: motion.json's data model has no delay concept at all, so there is no token these values could ever be replaced by, and flagging them as motion-token debt was simply incorrect. No later phase needs to 'close' this — it is not a TODO, it is a corrected false-positive."
  - "The plan's acceptance criterion 'scanned-surface count rose by one' does not hold literally: motion-lint's CHECK C counts every file the directory walk finds regardless of exemption status, so wleave/style.css was already counted in the scan total even while whole-file exempt. The real, verifiable signal that wleave is now covered is the two new CHECK A/CHECK B [PASS] lines for it (previously it produced no PASS/FAIL lines at all, only an [EXEMPT] line) — recorded as a documented clarification, not a defect, since CHECK C's design (count files found, not files actively checked) is correct as-is."

requirements-completed: [TOKEN-03, TOKEN-05]  # Both already marked complete in REQUIREMENTS.md prior to this plan (12-03/12-04); this plan closes wleave's specific pending-retrofit debt under TOKEN-03/D-19 and demonstrates TOKEN-05's reduced-motion criterion on wleave specifically.

coverage:
  - id: D1
    description: "wleave's capsule-entrance keyframe and label-reveal/exit transition resolve their duration/easing from the emitted motion tokens instead of hand-copied numbers, using longhand transition-*/animation-* properties throughout (no transition: shorthand survives on any rule containing a var() reference)"
    requirement: "TOKEN-03"
    verification:
      - kind: integration
        ref: "python3 headless Gtk.CssProvider().load_from_path(wleave/style.css) -> non-empty provider, no parse error; provider.to_string() shows transition-property/-duration/-timing-function each holding a distinct positional value (no shorthand-corruption fingerprint)"
        status: pass
      - kind: integration
        ref: "grep -c 'gtk-4.0-motion.css' wleave/.config/wleave/style.css -> 1; no cubic-bezier(0.05, 0.7, 0.1, 1) literal remains inside the capsule-entrance rule declaration (only inside comments)"
        status: pass
      - kind: integration
        ref: "git diff --stat wleave/ -> exactly one file changed"
        status: pass
    human_judgment: false
  - id: D2
    description: "GTK4 :root custom properties reach wleave's button nodes on the installed 4.22.4 binary (verified live, not assumed) — no fallback to a window-scoped emission needed"
    requirement: "TOKEN-03"
    verification:
      - kind: integration
        ref: "live Gtk.Application probe: :root { --probe-color: #123456 } button.probe { color: var(--probe-color) } -> btn.get_color() resolves to #123456; a window-scoped equivalent resolves identically"
        status: pass
    human_judgment: false
  - id: D3
    description: "wleave's motion-lint exemption is removed; the lint's CHECK A/B pass against the retrofitted stylesheet with only the D-19-fenced hover rule under a narrow, non-whole-file exemption; the fixture self-test still proves the lint can fail"
    requirement: "TOKEN-03"
    verification:
      - kind: integration
        ref: "motion-lint (real tree): 37 passed, 0 failed (up from 35/0) — two new [PASS] lines for wleave/style.css CHECK A/B, no [EXEMPT] line naming the whole file, one new [EXEMPT] line naming only the hover rule's line range"
        status: pass
      - kind: integration
        ref: "motion-lint --self-test: 9 passed, 0 failed (unaffected by the exemption/carve-out changes)"
        status: pass
      - kind: integration
        ref: "poisoned re-test: a dangling var(--motion-nonexistent-typo) swapped into capsule-entrance (outside the exempt line range) -> CHECK A FAIL; a raw cubic-bezier reintroduced into capsule-entrance (outside the exempt range) -> CHECK B FAIL — proves the narrow exemption does not silently cover the retrofitted rules"
        status: pass
    human_judgment: false
  - id: D4
    description: "A reduced-motion setting visibly shortens wleave's animation in the same theme-apply run that changes the QML surface and Hyprland's curves (TOKEN-05 criterion 4)"
    requirement: "TOKEN-05"
    verification:
      - kind: integration
        ref: "motion-switch.sh reduced && theme-apply catppuccin -> gtk-4.0-motion.css's --motion-duration-emphasized-in: 150ms (half of normal's 300ms); motion-switch.sh normal && theme-apply catppuccin -> restored to 300ms"
        status: pass
      - kind: manual_procedural
        ref: "D-27 blocking human render-and-look gate (Task 3) — PERFORMED, APPROVED. Group B (stagger rhythm, per-capsule settle, overall duration, hover overshoot bounce unchanged, exit fade) all reported unregressed. Group C (reduced visibly shorter, off shows no entrance, normal restores) confirmed. Group D (one motion-scale setting visibly affects wleave/GTK, the QML token inspector's Replay, and a Hyprland window animation in one session) confirmed. Group E (would you have accepted this at Phase 9) answered yes, no regression named. User response: \"approved\"."
        status: pass
    human_judgment: true
    rationale: "Whether the entrance/exit motion still 'feels right' against the Phase 9 baseline — stagger rhythm, settle quality, overall pacing — is exactly the class of judgment D-27's blocking human gate exists for; mechanical checks prove the tokens resolve, not that the feel survived. Judged and approved."

duration: multi-session (Tasks 1-2 autonomous in one continuous run; Task 3's blocking checkpoint:human-verify gate paused execution normally per D-27, resumed and closed on the coordinator's relayed "approved")
completed: 2026-07-27
status: complete
---

# Phase 12 Plan 07: Unified Design-Token Pipeline — wleave Motion Retrofit Summary

**wleave's GTK4 stylesheet now consumes the emitted `--motion-*` custom properties through longhand `transition-*`/`animation-*` properties (Pitfall 1-safe), its motion-lint whole-file exemption is gone in favor of one narrow rule-level carve-out plus a global lint-design fix for `animation-delay`, and the D-27 human render gate confirms no feel regression against the Phase 9 baseline.**

## Performance

- **Duration:** multi-session — Tasks 1-2 (autonomous) completed in one continuous run; Task 3's blocking `checkpoint:human-verify` gate then paused execution normally per the D-27 standing constraint, resumed and closed on the coordinator's relayed "approved" response
- **Started:** 2026-07-27 (approx, Task 1)
- **Completed:** 2026-07-27 (Task 3 approved)
- **Tasks:** 3 of 3 — Task 1, Task 2 (autonomous), Task 3 (blocking human render-and-look gate, D-27) **APPROVED**
- **Files modified:** 2 (0 new, 2 modified)

## Accomplishments

- `wleave/.config/wleave/style.css` retrofitted onto the emitted motion pipeline: a new `@import` pulls in `~/.local/state/theme/gtk-4.0-motion.css` alongside the existing colour import. The `button:hover, button:focus` transition and the `button label.action-name` exit transition both converted from the `transition:` shorthand to explicit longhand `transition-property`/`transition-duration`/`transition-timing-function` (12-RESEARCH.md Pattern 3/Pitfall 1: the shorthand silently corrupts every longhand into an identical raw string the instant any comma-separated item contains a `var()`). `capsule-entrance`'s `animation-duration`/`animation-timing-function` swapped from the hand-copied `md3_decel` literal to `var(--motion-duration-emphasized-in)`/`var(--motion-easing-emphasized-decelerate)` — a drop-in substitution since `animation-*` longhands were already in use.
- Only the values D-19 scopes into this phase became tokens: the hover rule's `transform` duration, and the label-reveal/exit transition's duration+easing, and `capsule-entrance`'s duration+easing. The hover overshoot curve (`cubic-bezier(0.55, 0, 0.28, 1.68)`) and the hover rule's three `150ms ease` transitions stay hand-authored literals, per the plan's explicit fence.
- **Binary-verified (standing constraint 2) that GTK 4.22.4's `:root` custom-property scope reaches wleave's button nodes**, settling 12-RESEARCH.md's open "confirm :root reaches the target node" question live rather than by assumption: a `Gtk.Application` probe with `:root { --probe-color: #123456 }` + `button.probe { color: var(--probe-color) }` resolved `btn.get_color()` to exactly `#123456`; a `window`-scoped equivalent resolved identically. No fallback to emitting against `window` was needed.
- The 09-03/09-04 hand-copy comment block (which documented the `md3_decel` drift by name) was rewritten in place — kept, not deleted — to describe the new token-driven sync mechanism (duration and curve now travel together as one semantic pair; the settle budget is a function of the active motion-scale, not a fixed figure) while preserving every piece of *design* reasoning (why decelerate over overshoot, why duration lengthened, why the hover curve stays untouched) for Phase 13's benefit.
- `motion-lint`'s whole-file `wleave/style.css` exemption removed from `EXEMPTIONS` (D-23's checklist shrinking toward zero). A new, narrower `LINE_EXEMPTIONS` mechanism (file regex + inclusive line range, printed once per entry like `EXEMPTIONS`) carries exactly one entry: wleave's `button:hover, button:focus` rule (lines 230-253), citing D-19's fence and the prior-gate approval of the overshoot feel. Proven not to over-cover: re-inserting a dangling reference or a raw literal into `capsule-entrance` (outside the exempt range) still trips CHECK A/CHECK B respectively.
- **Found and fixed a genuine motion-lint design gap, not a wleave defect:** CHECK B's raw-value regex is blind to which CSS property owns a matched `Nms` value, so it flagged wleave's six per-capsule `animation-delay` lines as "hand-rolls a raw duration value instead of a motion token" — but `motion.json`'s data model has no delay concept at all, so no token could ever replace them. Added a `DELAY_PROPERTY_RE` carve-out for `animation-delay`/`transition-delay` declarations, applied **universally** (not scoped to wleave), since any future GTK4 surface with a legitimate stagger delay would hit the identical false positive.

## Task Commits

1. **Task 1: Retrofit wleave's entrance and exit motion onto emitted tokens, longhand only** - `81d9ed7` (feat)
2. **Task 2: Remove wleave's lint exemption and re-verify the whole gate stack** - `c566cb1` (feat)
3. **Task 3: Blocking human render-and-look gate (D-27)** - **APPROVED** (human verification, no code change)

**Plan metadata:** committed alongside this SUMMARY (see final-commit step)

## Files Created/Modified

- `wleave/.config/wleave/style.css` - motion `@import`, longhand-restructured hover/focus and label-reveal transitions, token-driven `capsule-entrance`, rewritten hand-copy comment block
- `hypr/.config/hypr/scripts/motion-lint` - wleave's whole-file exemption removed; new `LINE_EXEMPTIONS` mechanism (one entry, wleave's hover rule); `DELAY_PROPERTY_RE` carve-out for `animation-delay`/`transition-delay`

## Decisions Made

See frontmatter `key-decisions` — summarized: (1) only D-19's fenced values became tokens, everything else in the hover rule stays literal by design, not oversight; (2) the hover rule's residual literals needed a lint carve-out narrower than a whole-file exemption, so `LINE_EXEMPTIONS` was added as a new, distinct mechanism from `EXEMPTIONS`; (3) `animation-delay`/`transition-delay` are excluded from CHECK B everywhere, permanently, as a corrected false positive rather than scoped debt for a later phase to close; (4) the plan's literal "scanned-surface count rose by one" acceptance wording doesn't hold given CHECK C's actual (correct) counting semantics — documented as a clarification, not treated as a defect to fix.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] CHECK B false-positive on `animation-delay` lines, found live the moment wleave's whole-file exemption was removed**
- **Found during:** Task 2, first isolated `motion-lint` run against the retrofitted stylesheet with the whole-file exemption removed
- **Issue:** CHECK B's raw-value regexes operate per-line, blind to which CSS property the matched value belongs to. wleave's six `button#id { animation-delay: Nms; }` lines were flagged as "hand-rolls a raw duration/easing value instead of a motion token" — but the motion pipeline's data model (`motion.json`) has no delay/stagger concept whatsoever; there is no `--motion-delay-*` token these values could ever resolve from. The message was not merely a false positive on an undercovered case, it was categorically wrong: pointing an author at a token that will never exist.
- **Fix:** Added `DELAY_PROPERTY_RE = re.compile(r'(?:animation|transition)-delay\s*:', re.I)` and skip CHECK B's raw-value collection for any line matching it, in `check_css_surface()`. Applied globally (not scoped to wleave or gated behind an exemption entry) since this is a correction to what CHECK B should ever flag, not scoped debt.
- **Files modified:** `hypr/.config/hypr/scripts/motion-lint`
- **Verification:** Isolated re-run against the retrofitted `wleave/style.css` dropped from 13 `[FAIL]` lines to 0; `--self-test`'s 9 fixtures (none of which contain `animation-delay`) were unaffected (still 9/9); the real-tree run's other 28 non-wleave surfaces (which also contain no `animation-delay` usage today) were unaffected.
- **Committed in:** `c566cb1` (Task 2 commit)

**2. [Rule 3 - blocking, resolved as explicitly authorized by the plan text] The hover rule needed a narrower-than-whole-file exemption, exactly as the plan anticipated**
- **Found during:** Task 2, same isolated run as above
- **Issue:** After the animation-delay fix, the hover/focus rule's three still-literal `150ms`/`ease` values and its hand-authored overshoot `cubic-bezier(0.55, 0, 0.28, 1.68)` (both explicitly kept literal by Task 1's own action text, per D-19's fence) still tripped CHECK B. The plan's Task 2 action text explicitly anticipated exactly this and authorized "ONE narrow exemption if and only if Task 1's hover rule still needs it... exempt that single rule — not the whole file."
- **Fix:** Added the `LINE_EXEMPTIONS` list (a new, narrower sibling mechanism to `EXEMPTIONS`) with one entry: `wleave/style.css`, lines 230-253 (the full `button:hover, button:focus` rule), reason citing D-19's fence and the prior-gate approval of the overshoot feel. Printed as an `[EXEMPT]` line on every run, same visibility discipline as the whole-file list.
- **Files modified:** `hypr/.config/hypr/scripts/motion-lint`
- **Verification:** Isolated run against the retrofitted stylesheet: 3 passed, 0 failed, with the new `[EXEMPT]` line naming exactly the hover rule's line range. A deliberately re-poisoned `capsule-entrance` (dangling reference, then separately a raw literal) — both OUTSIDE the exempt line range — still correctly failed CHECK A/CHECK B respectively, proving the carve-out does not silently re-cover the two rules Task 1 retrofitted.
- **Committed in:** `c566cb1` (Task 2 commit)

---

**Total deviations:** 2 auto-fixed (1 Rule-1 bug in motion-lint's own design, found live; 1 Rule-3 narrow exemption explicitly pre-authorized by the plan's own action text)
**Impact on plan:** Both were necessary for Task 2's own literal acceptance criteria ("the lint passes against the retrofitted stylesheet with both its raw-value and its reference-resolution checks live") to actually hold. Deviation 1 is a permanent, universal correctness fix to motion-lint itself — not wleave-specific debt, and not something any later phase needs to revisit or close. Deviation 2 is exactly the mechanism the plan's own text asked for; no scope creep beyond what was pre-authorized.

## Issues Encountered

- **The plan's own Task 3 checkpoint text offered a `git stash`/`git stash pop` before/after procedure that would not have worked in practice**, and the checkpoint I returned to the coordinator repeated that same offer verbatim from the plan. Task 1's change was already committed (`81d9ed7`) by the time the checkpoint was reached, so `git stash` would have found no working-tree difference to stash — a no-op, not a real "before" state. The coordinator caught this before presenting it to the user and used the correct procedure instead: `git show 81d9ed7~1:wleave/.config/wleave/style.css` copied over the live path for the "before" state, then `git checkout wleave/.config/wleave/style.css` to restore "after". The human approved the gate regardless (working from memory of the Phase 9 baseline per the plan's own "skip if fresh" allowance), but this is worth recording so a future plan's checkpoint text doesn't repeat a `git stash` offer against an already-committed change — this executor's own destructive-git-prohibition list separately forbids `git stash` regardless, which would have caught the attempt even if the timing hadn't already made it a no-op.
- **The plan's Task 2 acceptance criterion "its scanned-surface count rose by one relative to the count recorded in 12-05-SUMMARY.md" does not hold literally**, and this is not a defect — it is a wrong assumption baked into the criterion's wording. Reading `motion-lint`'s own implementation: `CHECK C`'s `total_scanned` count is computed from every file the directory walk finds, **before** the exemption filter is applied — so `wleave/style.css` was already counted in the scan total even while it carried a whole-file exemption (it produced an `[EXEMPT]` line and zero `[PASS]`/`[FAIL]` lines, but it was never excluded from the walk itself). Removing its exemption therefore contributes **zero** to `total_scanned`; the real signal of "wleave is now covered" is the appearance of two new `CHECK A`/`CHECK B` `[PASS]` lines for it. The observed count (29, up from 12-05's recorded 27) is fully explained by 12-06 adding two new `.qml` files (`Colours.qml`, `Motion.qml`) — a change from a prior plan, unrelated to this plan's exemption removal. Not fixed (nothing is broken; `CHECK C`'s design — count files found, not files actively checked — is correct as written), but recorded here so a future reader doesn't mistake the criterion's literal wording for how the mechanism actually works.

## Known Stubs

None — every retrofitted value in `wleave/style.css` resolves from the real emitted `gtk-4.0-motion.css`, proven by a headless `Gtk.CssProvider` parse, `motion-lint`'s CHECK A/B, and the D-27 human render gate against the live desktop. The hover rule's remaining literals are a documented, D-19-fenced design decision (human-approved feel; three ease transitions explicitly deferred to Phase 13), not an unwired stub.

## User Setup Required

None - no external service configuration required.

## Human Render Gate — Task 3 (D-27 blocking human render-and-look gate): APPROVED

Task 3 (`type="checkpoint:human-verify" gate="blocking"`) was presented to the user in full via the coordinator, per `config.json`'s `workflow.auto_advance: false` (interactive mode, no auto-chain active) — this gate could not be auto-approved regardless, since D-27 overrides `human_verify_mode: "end-of-phase"` specifically because wleave is a regression risk on a surface already approved once in Phase 9.

**Result: "approved" — nothing regressed.**

- **Group B (normal motion):** Stagger rhythm, per-capsule deceleration/settle, and overall entrance duration all reported unchanged from the pre-retrofit feel. The hover overshoot bounce — deliberately NOT touched by this plan — confirmed still present and identical. Exit fade confirmed unchanged.
- **Group C (reduced motion):** `motion-switch.sh reduced` produced a visibly, noticeably shorter entrance than normal; `motion-switch.sh off` produced no entrance animation at all; `motion-switch.sh normal` restored baseline behavior.
- **Group D (one run, three surfaces — TOKEN-05 criterion 4):** With the axis at `reduced` in one session, wleave (GTK), the QML token inspector's "Replay motion" control, and a Hyprland window animation were all confirmed visibly affected by the same motion-scale setting.
- **Group E (the honest question):** The user confirmed they would have accepted this at the Phase 9 gate — no part of the feel reads as regressed, even imprecisely.

This is the human-judgment half of both TOKEN-03 and TOKEN-05's closure criteria being demonstrated specifically on wleave (both requirements were already marked complete in `REQUIREMENTS.md` from 12-03/12-04's broader pipeline work; this plan closes wleave's own pending-retrofit debt under D-19/D-23 and exercises TOKEN-05's reduced-motion criterion on this specific surface). `motion-scale` was confirmed restored to `normal` and `current-theme` remained `catppuccin` throughout, matching this plan's own pre-close restoration discipline. Working tree confirmed fully clean apart from this plan's own two commits.

### Independently re-verified (cited, not re-run by this SUMMARY)

- `motion-lint` on the real deployed tree: **37 passed, 0 failed** (up from 35/0 at 12-06's close — wleave genuinely covered now, exemption removal took effect).
- `motion-lint --self-test`: 9 passed, 0 failed.
- `theme-doctor`: **180 passed, 0 failed** — fully clean. (Not 179/1 as I recorded mid-plan: the orchestrator resolved the long-standing pre-existing untracked-file failure separately via a `.gitignore` update that opts `vscodium/.local/share/applications/` out of tracking except its two deliberately-versioned desktop entries. This was NOT this plan's work and touched no file in this plan's `files_modified`.)
- `theme-parity`: 1985 passed, 0 failed (unchanged — this plan does not touch any `theme-parity`-checked render target).
- `quickshell-doctor`: 13 passed, 0 failed, exit 0.
- Motion axis confirmed restored to `normal`; working tree fully clean; commits `81d9ed7` and `c566cb1` both present.

## Next Phase Readiness

- `theme-doctor`: **180 passed / 0 failed** — fully clean for the first time this milestone. The prior "1 failure" carried since before Phase 12 (the untracked vscodium desktop file) is resolved, not merely unrelated-and-ignored.
- `theme-parity`: **1985 passed / 0 failed** — unchanged, this plan touches no parity-checked target.
- `motion-lint`: **37 passed / 0 failed** on the real deployed tree (up from 35/0) — wleave is the only surface this phase's own scope committed to closing (12-05-SUMMARY.md: "plan 12-07 removes the wleave/style.css exemption entry... that is the one exemption entry this phase itself is expected to close"). **Done.** Five exemption entries remain, all Phase 13's designated existing-surface sweep: `waybar/*.css`, `swaync/style.css`, `swayosd/style.css` (GTK3, permanent — no `var()` mechanism exists), `walker/**/style.css`, `ags/*.scss` (GTK4-capable, pending retrofit), plus `hypr/config/animations.conf`'s 13 hand-authored `animation =` lines (Hyprland-side pending retrofit). wleave's own new `LINE_EXEMPTIONS` entry (its hover rule) is a **permanent, D-19-fenced** carve-out, not additional Phase 13 debt — the overshoot curve is explicitly out of scope forever, and the three ease transitions are Phase 13's to consider alongside the other five surfaces' full retrofit, at the same "pending Phase 13" tier as the whole-file exemptions above.
- **The `DELAY_PROPERTY_RE` carve-out for `animation-delay`/`transition-delay` is a closed, permanent fix — not a follow-up item for any later phase.** If Phase 13 retrofits waybar/swaync/walker/ags/swayosd and any of them turn out to use a stagger `animation-delay` (GTK3's own `-gtk-` prefixed custom-property story is different, but the same false-positive class could recur if any surface gains a real delay property), the fix already in place will apply to them automatically — no new work needed.
- **`.planning/WINDOWS.md` entry #9 (12-06's D-17 assertion, unrun via the real committed `theme-stress-test`) is now unblocked, though not yet re-run.** Its stated blocker — the pre-existing untracked vscodium file failing `theme-stress-test`'s per-switch `theme-doctor` gate — is the exact one resolved by the orchestrator's `.gitignore` change noted above. This plan did not itself run the real `theme-stress-test` (out of scope: it lives in `theme-engine/`, not this plan's `files_modified`, and a full 10-switch run mutates the live desktop's theme ten times), so entry #9 is left `open` rather than marked `fixed` — marking it resolved would misstate that the verification actually ran, when only the obstacle to running it is gone. Whoever next touches `theme-engine/.config/theme-engine/theme-stress-test` (or runs a full gate sweep) should re-run it for the formality confirmation 12-06 deferred; it is expected to pass 10/10 identically to the scratch-copy proof 12-06 already recorded.
- No blockers for Phase 13's existing-surface sweep. `wleave/style.css` is now a working example of the longhand-retrofit pattern (motion import, longhand `transition-*`, drop-in `animation-*` substitution, narrow line-scoped lint carve-out where a literal must legitimately survive) that Phase 13 can follow for waybar/swaync/walker/ags/swayosd/`animations.conf`.

---
*Phase: 12-unified-design-token-pipeline*
*Completed: 2026-07-27*
