---
phase: 09-wlogout-to-wleave-migration
plan: 03
subsystem: theming
tags: [wleave, gtk4, css-mix, layer-shell, hyprland-layerrule, material-you, m3-color-roles, icon-svg]

requires:
  - phase: 09-02
    provides: "Structurally correct wleave surface (transparent window + scrim, 96px capsule geometry, version-info suppressed) with a single neutral capsule style; the D-08 correction that a native per-button second text slot (label.action-name) exists"
provides:
  - "Six-capsule visual identity: per-action translucent frost fill, matching on-container glyph colour, and a hairline border in the same hue (D-03/D-05/D-06), two of six hues mix()-derived at the container level for the first time in this repo (D-04)"
  - "D-08's hover/focus action-name reveal, delivered via the user-selected option-b (icon+text split): glyph moved to wleave's native icon field (upstream's own shipped SVGs), Title Case action name in text, revealed on hover/focus"
  - "Entrance stagger (D-10): six capsules pop/slide in left-to-right, 35ms offset, 345ms total, inside the 350ms budget"
  - "Exit tier CONFIRMED LIVE (D-10 + RESEARCH Assumption A2): the compositor's global `layers` animation (popin/fade, md3_decel) DOES fire on wleave's client-initiated synchronous hide — Tier 1 achieved, pinned explicitly via a namespace-scoped layerrule"
  - "Blur threshold (ignore_alpha 0.25 on the wleave namespace) re-derived and confirmed against the new three-value composite (0.40 scrim / ~0.61 rest-capsule / ~0.73 hover-capsule)"
affects: [09-04-render-gate]

tech-stack:
  added: []
  patterns:
    - "wleave icon+text split (D-08 option-b): `icon` field renders an SVG glyph recoloured via the widget's CSS `color` (wleave's WleavePicturePaintable / GtkSymbolicPaintable implementation), `text` field renders a real second widget (label.action-name) independently stylable and hidden/revealed via opacity, NOT via `text` alone as 09-01/09-02 assumed"
    - "GTK CSS mix() at the container level (not just base-hue level, Phase 8-14's original use) — six @define-color derived names, each pairing a container fill, an on-container glyph colour, and a base-hue border, so the M3 contrast pairing holds for the two synthesized hues exactly as the four native roles"
    - "Empirical CSS layout-offset correction: when a GTK4 box vertically centers a [content-widget + reserved-but-hidden-label] group as one unit, the content widget sits offset above true center by half the label's rendered height — corrected here with a measured `margin-top` on the content widget, not guessed"
    - "Hyprland layerrule animation: an explicit `layerrule = animation <config-name>, match:namespace <ns>` can pin a namespace to an EXISTING top-level `animations{}` config entry by name (here: the pre-existing global `layers` config), rather than only accepting the built-in fade/slide/popin keywords"

key-files:
  created: []
  modified:
    - wleave/.config/wleave/style.css
    - wleave/.config/wleave/layout.json
    - hypr/.config/hypr/config/windowrules.conf

key-decisions:
  - "D-08 RESOLVED (user, blocking checkpoint): option-b, the icon+text split. The predecessor executor's option-c recommendation was superseded after the orchestrator empirically proved (tint-proof.png, restlayout-proof.png) that per-hue glyph tinting via `icon` works, icon+text coexist on one button, no SVG authoring is needed (wleave ships all six icons at /usr/share/wleave/icons/*.svg, already a dependency of the installed AUR package), and hiding the label via opacity produces zero layout shift. This SUPERSEDES D-09's chosen-Nerd-Font-codepoint convention for this surface only — the 09-01 cmap verification work remains valid history, but no six-codepoint glyph renders here anymore."
  - "Icon vertical centring residual (the ONE open item the decision flagged as real work): measured LIVE via a grim capture + pixel-centroid script — the icon's own allocated box centred 8.0px above the button's true vertical centre, caused by the hover-reveal label's reserved (but at-rest-invisible) layout space. Corrected with `margin-top: 16px` on `button picture`, re-measured afterwards at 0.0px residual — not a guess, a closed-loop empirical fix at this exact geometry (border:1px, padding:16px, min-width/height:62px, label 13px/400)."
  - "Exit-tier Assumption A2 (RESEARCH's flagged unknown — whether a compositor layerrule fires on wleave's client-initiated synchronous hide) is RESOLVED, not merely attempted: a live rapid 6-frame grim capture across a real Escape-dismissal shows the capsule row visibly fading across multiple frames before the surface disappears. This is the pre-existing global `animations.conf` `layers` config (`popin 80%`, `md3_decel`, duration 4) already applying — pinned explicitly to the wleave namespace via a new `layerrule = animation layers, match:namespace wleave` rule rather than left as an incidental side effect of a global default that could change for unrelated reasons (walker/waybar/swaync also use it)."
  - "Blur threshold (ignore_alpha 0.25) kept unchanged from 09-02's starting value, but re-derived: the design now composites THREE distinct alpha values at this surface (0.40 bare scrim, ~0.61 scrim+rest-fill, ~0.73 scrim+hover-fill, via standard alpha-over-alpha compositing) — 0.25 sits below all three, so every region blurs at every capsule state. Documented inline as a re-derivation, not a re-guess."
  - "Hover-state evidence was captured via keyboard focus (`wtype -k Tab`), not literal mouse hover — `hyprctl dispatch movecursor` warps the cursor position without emitting a `wl_pointer` motion/enter event this GTK4 client processes (confirmed by a live jiggle test: cursor position correct per `hyprctl cursorpos`, zero `:hover` activation). Because every interaction rule in this stylesheet is a byte-identical paired `:hover`/`:focus` selector (D-08's own requirement), the focus-driven capture exercises the exact same CSS code path as a literal hover would — a valid substitute for what the tooling in this environment cannot synthesize, not a gap in delivery. Logged to WINDOWS.md for visibility."

requirements-completed: []

coverage:
  - id: D1
    description: "Six capsules each carry a distinct per-hue fill, border, and glyph colour (rest state), two of six hues mix()-derived at the container level with matching mixed on-container glyph colours"
    requirement: "WLOG-01"
    verification:
      - kind: automated_ui
        ref: "evidence/09-03-rest-dark.png (live grim capture, all six capsules visually distinct); grep assertions for six id-selectors, six mix() derived names, all four on-container roles referenced"
        status: pass
    human_judgment: true
    rationale: "Automated selector-presence checks prove the CSS rules exist, not that they render distinctly and legibly — this requires the human render-and-look gate at 09-04, per this phase's own D-14 discipline (Phase 6 shipped selector-complete-but-visually-broken CSS)."
  - id: D2
    description: "D-08 hover/focus action-name reveal delivered via icon+text split (option-b); hover and focus render identically (paired selectors, equal counts)"
    requirement: "WLOG-01"
    verification:
      - kind: automated_ui
        ref: "evidence/09-03-hover-dark.png (keyboard-focus-driven capture, not literal mouse hover — see key-decisions and WINDOWS.md entry 4); grep assertion hover-count==focus-count==9"
        status: pass
    human_judgment: true
    rationale: "The captured evidence uses keyboard focus as a proxy for hover due to an environment tooling limitation (hyprctl movecursor doesn't emit synthetic wl_pointer motion this client processes). A human should confirm at 09-04 that literal mouse hover (not just Tab-focus) also activates the same visual state on the real desktop."
  - id: D3
    description: "Icon vertical centring: glyph measured centred within 0px of true capsule centre after the margin-top:16px correction"
    verification:
      - kind: other
        ref: "Live grim capture + PIL colour-mask centroid script, offset measured 0.0px at the final geometry (border:1px, padding:16px, min-width/height:62px)"
        status: pass
    human_judgment: true
    rationale: "The measurement used a synthetic high-contrast probe CSS (green background-color on `button picture`) to isolate the icon's allocated box precisely — a human should still confirm the REAL themed glyph (SVG icon tinted via the M3 role colours, not a green rectangle) reads as centred at the 09-04 render gate."
  - id: D4
    description: "Entrance stagger lands inside the 350ms budget; exit tier (compositor layerrule animation) confirmed live"
    requirement: "WLOG-01"
    verification:
      - kind: other
        ref: "python arithmetic assertion (max delay 175ms + duration 170ms = 345ms < 350ms); evidence/09-03-exit-frame-{1..6}.png (6-frame rapid capture showing multi-frame fade on a real Escape dismissal)"
        status: pass
    human_judgment: false
  - id: D5
    description: "Power action still fires immediately on click; delay-command-ms unchanged from 09-02's default (100ms, byte-absent from layout.json)"
    requirement: "WLOG-01"
    verification:
      - kind: other
        ref: "grep -c delay-command-ms layout.json == 0 (field never added); wleave debug log confirms 'delay-command-ms specified from config: 100' (binary default, unchanged)"
        status: pass
    human_judgment: false
  - id: D6
    description: "hyprctl configerrors clean after the layerrule/blur-threshold changes; zero references to the retired wlogout namespace"
    verification:
      - kind: other
        ref: "hyprctl configerrors (empty output after hyprctl reload); grep -c logout_dialog windowrules.conf == 0"
        status: pass
    human_judgment: false

duration: ~25min (this continuation session — the prior session's work ended at Task 1's checkpoint)
completed: 2026-07-25
status: complete
---

# Phase 9 Plan 3: Six-Capsule Hue Identity, Motion, and the D-08 Icon+Text Cutover Summary

**Six per-action hues (two mix()-derived at the container level) with hover/focus feedback delivered via wleave's native icon+text split, an empirically-tuned 0px-residual glyph centring fix, a 345ms left-to-right entrance stagger, and a live-confirmed compositor exit-fade — resolving RESEARCH's Assumption A2 by observation rather than leaving it flagged.**

## Performance

- **Duration:** ~25 min (this continuation session; the prior session's work ended at Task 1's `checkpoint:decision`, which the orchestrator resolved before spawning this continuation)
- **Completed:** 2026-07-25T16:49Z
- **Tasks:** 2/2 (Task 1 was the decision checkpoint, resolved by the user before this session began — no further executor work required for it beyond recording the decision, done below)
- **Files modified:** 3 (`wleave/.config/wleave/style.css`, `wleave/.config/wleave/layout.json`, `hypr/.config/hypr/config/windowrules.conf`), plus 13 evidence artefacts

## Accomplishments

- **Task 1 (decision, resolved before this session):** D-08's hover/focus action-name reveal mechanism resolved as **option-b** (icon+text split) by the user, based on empirical proof the orchestrator produced against the live wleave binary (tint-proof and restlayout-proof renders). Recorded here per the plan's own requirement that the choice and rationale land in this SUMMARY.
- **Task 2:** Extended `wleave/.config/wleave/style.css` with the six-capsule hue identity (D-03/D-05/D-06), two mix()-derived hues at the container level (D-04), paired hover/focus rules (equal counts, 9/9), and implemented D-08 option-b: `layout.json`'s six buttons now point `icon` at wleave's own shipped SVGs and `text` at the six Title Case action names; the label is hidden at rest via opacity and revealed on hover/focus. Solved the one open empirical question the decision flagged — the glyph's vertical centring — via a measured `margin-top: 16px` on the icon, closing the loop with a live re-measurement (0.0px residual).
- **Task 3:** Added the D-10 entrance stagger (@keyframes, six `animation-delay` values, 345ms total budget) and resolved RESEARCH's Assumption A2 by direct observation: a live rapid-capture sequence across a real dismissal proves the compositor's exit-fade animation DOES fire on wleave's synchronous client-side hide. Pinned this explicitly with a new namespace-scoped `layerrule = animation layers, match:namespace wleave` rule, and re-derived (not re-guessed) the `ignore_alpha` blur threshold against the new three-value alpha composite.

## Task Commits

Each task was committed atomically:

1. **Task 2: Six-hue capsule identity + icon/text hover reveal** — `7691c03` (feat)
2. **Task 3: Entrance stagger, exit-tier confirmation, blur threshold re-derivation** — `6807743` (feat)
3. **Evidence: D-08 decision proof + render-gate captures** — `9145667` (test)

**Plan metadata:** committed separately (see `<final_commit>`).

_Task 1 (the `checkpoint:decision`) has no code commit of its own — it was a blocking decision gate resolved by the user before this continuation began; the decision and its rationale are recorded in this SUMMARY per the plan's instruction._

## Files Created/Modified

- `wleave/.config/wleave/style.css` — six id-selector rest-state rules (fill/glyph/border per capsule), two `mix()`-derived `@define-color` hue families (vhue-teal, vhue-purple, each with a container/on-container/base triplet), paired `:hover`/`:focus` rules (fill→0.55 alpha, border to full-opacity hue, glow, shared 6% scale), the `button picture { margin-top: 16px; }` centring fix with its full empirical derivation in comments, `label.action-name` reveal styling, `@keyframes capsule-entrance` plus six per-id `animation-delay` values
- `wleave/.config/wleave/layout.json` — all six buttons: `icon` now points at `/usr/share/wleave/icons/{lock,logout,suspend,hibernate,reboot,shutdown}.svg`; `text` now carries the six Title Case action names (previously held a Nerd Font codepoint under 09-02); the old per-button `height: 0.5` field (which positioned the retired text-as-glyph) is removed
- `hypr/.config/hypr/config/windowrules.conf` — new `layerrule = animation layers, match:namespace wleave`; `ignore_alpha 0.25, match:namespace wleave` kept but its comment re-derived for the new three-value composite
- `.planning/phases/09-wlogout-to-wleave-migration/evidence/09-03-hover-dark.png`, `09-03-rest-dark.png`, `09-03-exit-frame-{1..6}.png` — new render-gate evidence
- `.planning/phases/09-wlogout-to-wleave-migration/evidence/09-03-decision-probe-{layout.json,tint.css,rest.css}`, `09-03-decision-{tint,restlayout}-proof.png` — the D-08 checkpoint's proof artefacts, committed here (were untracked from the prior session)

## Decisions Made

See `key-decisions` in frontmatter above. Summary of the most consequential:

1. **D-08 = option-b** (user-selected at the blocking checkpoint, based on the orchestrator's empirical proof) — supersedes D-09's codepoint convention for this surface.
2. **Icon centring formula, closed empirically**: an icon sitting above a reserved-but-hidden label's box is offset above true centre by ~half the label's rendered height; `margin-top` on the icon of that same amount (not half — the anchor mechanic is linear but 1:1, not 1:2, confirmed by testing multiple margin values) closes it to 0px.
3. **Exit-tier Assumption A2 resolved as YES** by direct live observation, not left flagged — the compositor's pre-existing global `layers` animation already fires on wleave's hide; pinned explicitly per-namespace for documentation/robustness.
4. **Blur threshold unchanged (0.25) but re-justified** against the new three-value alpha composite this design actually produces.
5. **Hover evidence captured via keyboard focus, not mouse hover** — an environment tooling gap (`hyprctl dispatch movecursor` doesn't emit synthetic pointer motion), not a stylesheet gap, since `:hover`/`:focus` are byte-identical selectors throughout.

## Deviations from Plan

### Auto-fixed / Adapted Issues

**1. [User-approved, per the `<decision>` block] D-08 delivered via option-b, superseding D-09's codepoint convention**
- **Found during:** Task 1 (resolved before this continuation session began)
- **Issue:** D-09 locked six specific Nerd Font codepoints as the glyph delivery mechanism; D-08 requires a hover-revealed action name, which — per the orchestrator's live proof — is only cleanly achievable by moving the glyph out of `text` and into `icon`.
- **Fix:** `layout.json`'s `icon` field now points at wleave's own shipped SVGs (`/usr/share/wleave/icons/*.svg`, zero new repo assets, already a dependency of the installed AUR package); `text` carries the six Title Case labels.
- **Files modified:** `wleave/.config/wleave/layout.json`, `wleave/.config/wleave/style.css`
- **Verification:** Live grim captures (rest and focus states) confirm all six glyphs render, tinted per-capsule, with labels revealed correctly on focus.
- **Committed in:** `7691c03`

**2. [Rule 1 - Bug, empirically closed] Icon rendered 8.0px above true capsule centre**
- **Found during:** Task 2, continuing from the decision's own flagged residual issue
- **Issue:** With the hover-reveal label's layout space reserved (even while invisible at rest), the icon's own allocated box centred measurably above the capsule's true vertical centre.
- **Fix:** `button picture { margin-top: 16px; }`, derived by testing several margin values against a live pixel-centroid measurement script and confirming the resulting relationship, not guessed.
- **Files modified:** `wleave/.config/wleave/style.css`
- **Verification:** Live grim capture + PIL centroid analysis: 0.0px residual offset at the final geometry.
- **Committed in:** `7691c03`

**3. [Documented, not a defect] Icon size follows the SVG's natural shrink-fit size, not the literal 36px Display-role token**
- **Found during:** Task 2
- **Issue:** UI-SPEC's 36px "Display (glyph)" typography role was derived assuming the retired text-glyph mechanism (font-size). Under option-b, the icon is an SVG inside a GTK box that shrinks it to fit the space left after the label's reserved region; forcing an explicit `min-width`/`min-height: 36px` on the icon shifted the measured centring off by +3px in a quick test, so it was left unconstrained.
- **Fix:** None — documented as an intentional, visually-verified deviation. Logged to `WINDOWS.md` (entry 5) for visibility.
- **Files modified:** none beyond what's already listed
- **Verification:** Evidence captures show clearly legible, appropriately-sized glyphs at all six capsules.

**4. [Documented, tooling limitation] Hover evidence captured via keyboard focus, not literal mouse hover**
- **Found during:** Task 2 verification
- **Issue:** `hyprctl dispatch movecursor` warps the compositor cursor position but does not emit a `wl_pointer` motion/enter event this GTK4 client's input handling reacts to — confirmed via a live jiggle test (cursor position correct per `hyprctl cursorpos`, zero `:hover` CSS activation observed across three different landing points).
- **Fix:** Used `wtype -k Tab` to move keyboard focus instead, which DOES activate the interaction-state CSS (confirmed live — Lock, then Suspend, each showed the correct border glow/fill/label reveal when focused). Since `:hover` and `:focus` are byte-identical paired selectors throughout this stylesheet (D-08's own requirement), this exercises the exact same rendering code path.
- **Files modified:** none — evidence-capture methodology only
- **Verification:** `evidence/09-03-hover-dark.png` shows the Suspend capsule with a distinct tertiary-hued glow, brighter fill, and revealed "Suspend" label, clearly differentiated from its five neighbours.
- **Logged to:** `WINDOWS.md` entry 4 (open, for 09-04's human render gate to confirm literal mouse hover separately if desired)

**5. [Honestly recorded, not a gap] Entrance-vs-hover interaction not exercised live**
- **Found during:** Task 3
- **Issue:** The plan asks to "confirm at the gate that hovering during the entrance window does not produce a jump." The ~350ms entrance window is too short to reliably land a synthetic pointer/focus event inside it with the tooling available in this environment (no sub-100ms-precision input synthesis tool installed).
- **Fix:** None attempted beyond the structural mitigation already in the CSS (entrance `transform` on the base `button` rule, hover/focus `transform: scale(1.06)` on a separate paired selector, `animation-fill-mode: backwards` so the entrance releases the property cleanly once finished).
- **Files modified:** none
- **Verification:** Not verified live. Logged to `WINDOWS.md` entry 3 (open) for 09-04 to confirm by eye if desired.

---

**Total deviations:** 5 (1 user-approved mechanism swap carrying forward the resolved checkpoint, 1 empirically-closed bug fix, 2 documented-but-unfixed minor deviations, 1 honestly-recorded unverified interaction). No scope creep — every deviation is either the direct, expected consequence of the user's D-08 decision or an honest gap disclosure per this plan's own discipline.

## Known Stubs

None. Every rule added carries real, theme-derived values — no hardcoded empty fills, no placeholder colours, no unwired glyph/label content.

## Threat Flags

None. This plan's STRIDE register (T-09-08/09/10) was already addressed structurally: the severity-ordered position plus the reserved error-role family for shutdown-only holds (verified: `grep -c '@error'` matches only shutdown's rule and the two `vhue-purple` mix() definitions); the entrance/hover transform-conflict mitigation (T-09-09) is structurally in place (see Deviation 5 for its unverified-live status); the command-delay value is confirmed byte-unchanged (T-09-10).

## Gate Sweep Results (this session)

| Gate | Result | Notes |
|---|---|---|
| `theme-doctor` | 135 passed, 2 failed (rc=1) | Both failures are the same pre-existing, unrelated issues 09-02 already deferred (orphaned `eww.scss` contract entry, `git status --porcelain` non-empty from long-standing unrelated repo changes). `CSS-parse: wleave/style.css (8872 bytes)` passes. |
| `hyprctl configerrors` | Clean (empty output) | Confirmed after both the `layerrule = animation` addition and the `ignore_alpha` comment update, following `hyprctl reload`. |
| Retired-namespace grep | 0 matches | `grep -c logout_dialog windowrules.conf` == 0. |
| Stagger-budget assertion | 345ms < 350ms | Python arithmetic check, not eyeballed. |

## Issues Encountered

- `hyprctl dispatch movecursor` does not generate synthetic pointer-motion events this GTK4 client's `:hover` handling responds to (see Deviation 4) — worked around with keyboard-focus capture via `wtype`, which is a valid substitute given the paired-selector design, but is logged for 09-04 to optionally re-confirm with literal mouse movement on the real desktop.
- No sub-100ms input-synthesis tool was available to test the entrance/hover interaction window live (see Deviation 5) — logged rather than silently skipped.

## User Setup Required

None — no external service configuration changes. All fixes and tuning were performed by the executor using tools already present on the system (grim, wtype, python3/PIL, hyprctl).

## Next Phase Readiness

**Ready for 09-04 (the render-and-look gate), with the following carried forward for human confirmation:**

1. **Literal mouse hover** was not exercised live in this session (keyboard focus was used as a byte-identical-selector substitute) — 09-04 should confirm hovering with a real mouse produces the same visible feedback on the actual desktop.
2. **Entrance-during-hover interaction** (does hovering mid-stagger cause a visible jump?) was not exercised live — 09-04 should eyeball this if practical.
3. **Icon size** (natural shrink-fit, not a pinned 36px) should get a visual sanity check at 09-04 alongside the rest of the six-capsule identity.
4. **mix()-derived hues at the container level** (a first for this repo) should be visually confirmed at 09-04 across both dark and light presets — the plan itself flags mix()-of-mix composited with 0.35 frost alpha as unverified until rendered; this session only rendered the dark (tokyonight) preset.
5. Both open `WINDOWS.md` entries from this plan (3 and 4) plus entry 5 are informational — none block 09-04, all are optional live re-confirmations of things this session already has strong indirect evidence for (paired selectors, structural entrance/hover separation).

---
*Phase: 09-wlogout-to-wleave-migration*
*Completed: 2026-07-25*
