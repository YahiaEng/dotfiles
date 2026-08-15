# 20-GATE-02-B-RECORD.md — Gate B (Power Menu), unlocks RETIRE-05

## What This Record Is

Gate B is one of the phase's two independent GATE-02 render gates (D-20-42) — the power-menu
half. It judges the replacement power menu (the radial ring, `quickshell-session` namespace)
against wleave's recorded behaviour (`20-BEHAVIOUR-BASELINE.md`), criterion by criterion, and
its own verdict authorises exactly one thing: `RETIRE-05` (`wleave`). Gate A (the OSD,
`20-GATE-02-A-RECORD.md`) is scored and authorised entirely separately — a stall here must
never hold Gate A hostage, per D-20-42. Per D-20-42/D-20-40, `wlogout` + `eww` (RETIRE-07)
ride whichever of Gate A/Gate B lands second, as one shared `pacman -Rns`.

Format follows `18-GATE-02-RECORD.md`'s precedent: a criteria table with a closed verdict
vocabulary, a judged sha, and a per-gate `## Deletion Authorisation` section.

## Deviation from the plan's own action text — recorded per the executor's `upstream_state` instruction

`20-08-PLAN.md`'s Task 2 action text was authored against the power menu's ORIGINAL 3×2-grid
design (it says "arrow keys move focus two-dimensionally across the 3×2 grid," "tile fill,"
"warning banner," and enumerates nine criteria). The power menu was rejected live and rebuilt
to the radial ring across four subsequent revisions (D-20-21, revised four times), and
`20-UI-SPEC.md` § "GATE-02 Render-Gate Criteria" → "Gate B — Power menu" was re-synced to match
in commit `8b6a111` — it now carries **twelve** criteria (1-12, several revised multiple times
for the ring shape), not the plan's stale nine. This executor's own `upstream_state` context is
explicit: *"The contract was re-synced to the code in commit `8b6a111`, so `20-UI-SPEC.md` and
`20-CONTEXT.md`'s D-20-21 are now authoritative and current. READ THEM — do not gate against any
memory of the original grid design."*

**Resolution:** this record transcribes UI-SPEC's actual twelve current criteria verbatim,
renumbered 1-12, plus the Phase 15 "who owns the prompt" security carry-over the plan's own
`must_haves` and the roadmap's own Notes require, as criterion 13 — thirteen rows total, not
the plan's literal ten. Recorded as a deviation (Rule 2 — correcting stale plan text against an
authoritative, more-recently-revised source) rather than silently gating against the grid
design's nine retired criteria, which would judge a surface that no longer exists.

## Verdict Vocabulary

- **`PASS`** — the gesture was performed on the running shell and the criterion was met.
- **`FAIL`** — the gesture was performed and the criterion was not met. Blocks Gate B's own
  deletion (RETIRE-05) until fixed and re-checked. Does not affect Gate A.
- **`NOT-DEMONSTRABLE`** — the criterion has no observable subject on this hardware, recorded
  with its reason.
- **`AWAITING-OBSERVATION`** — placeholder. Not a verdict. A row carrying this token has not
  yet been judged live and does not authorise anything.

## Automated Pre-Checks (run before presenting this gate)

All read-only, run against the live host on 2026-08-16, HEAD `8b6a111a5f896a4bb449ac5a2cb91bcf6680d205`:

| Check | Result |
|---|---|
| `timeout 6 quickshell -p shell.qml` load, grepped for error/binding-loop | Clean (same three pre-existing ignorable warnings as Gate A; `PowerMenu.qml` is lazy-loaded and does not appear here — linted separately below). |
| `qmllint modules/session/PowerMenu.qml` | Exit 0. |
| `colour-lint` | Exit 0. |
| `motion-lint` | Exit 0. |
| `quickshell-doctor --self-test` | 55/55 passed, 0 failed, exit 0. |
| `grep -n "hl.dsp.global(\"quickshell:power-menu\")"` across all three entry points | **Confirmed structurally convergent.** `keybinds.lua:68` (`Super+Shift+Q`) and `elephant/menus/main.toml:34-40` (walker's "Power" entry) both dispatch the literal identical `hl.dsp.global("quickshell:power-menu")` call; `ClockActionsCapsule.qml:1019`'s bar glyph (`onClicked: PopoutController.requestPowerMenu()`) relays through `PopoutController.qml:130` → `Bar.qml`'s `powerMenuRequested` signal → `shell.qml:421`'s `onPowerMenuRequested: root.togglePowerMenu()` — the same function `shell.qml:1008-1009`'s `GlobalShortcut { name: "power-menu" }` calls. All three converge on one `togglePowerMenu()`. None shells to `wleave.sh` (zero hits for `wleave.sh` outside historical comments). |
| `grep -n "quickshell-session" windowrules.lua` | Confirms `animation = "fade"` (line 632) and `ignore_alpha = 0.2` (line 633) are both landed — the fourth-revision mechanism criterion 1/12 describe is structurally present. Whether it *reads* as frosted/fading live is still a human judgment, not established by this grep. |
| `ClockActionsCapsule.qml:567-580` `powerAvailabilityProbe`/`powerAvailable` | Confirmed absent (D-20-23) — comment at line 567-573 records the removal explicitly; the bar's power glyph has no "missing" state to gate on. |

These confirm the build is structurally sound going into the live sitting, including the
mechanical parts of criteria 1, 7 and 12. **None of them constitute a live-gesture pass for any
criterion below** — per the executor's instruction not to self-certify a criterion the user has
not confirmed, every row below still reads `AWAITING-OBSERVATION` until the operator sits down.

## Build Under Test

- **HEAD sha:** `8b6a111a5f896a4bb449ac5a2cb91bcf6680d205` — the sha this record's criteria are
  judged against.
- **Working tree:** clean at time of authoring.
- **Interlock plan 20-10 must re-assert before deleting anything:**
  `git diff --quiet 8b6a111a5f896a4bb449ac5a2cb91bcf6680d205 -- quickshell/.config/quickshell/`
  must still hold (exit 0, no output) at the moment of deletion. A shell tree that moved since
  this sha invalidates this record's judgment.

## Open Verification Debt Carried Into This Sitting

- **WINDOWS row 76** — the ring's live human-check has been partially exercised across four
  feedback rounds during build (circular entrance, arrow rotation with wrap, hover moving
  focus, click-outside dismissal, post-unlock flash gone, frost, dimming, neutral focus ring).
  **NOT yet confirmed live in a single closing pass:** the warning chip against a real
  pacman/paru/yay run, the mnemonic keys, Enter activating from the ring, Shutdown/Reboot's
  graceful-exit routing, all three entry points opening the identical surface, the reverse
  exit animation.
- **WINDOWS row 3** — the Phase 9 hover-during-entrance-cascade race (D-20-36 deliberately did
  not serialise entrance against input readiness) was never exercised live on the retired
  wleave surface either, and explicitly names "Owner: plan 20-08's Gate B" for re-triage on
  this surface. Criteria 4 (hover-moves-focus) and 11 (exit-animation Bug-2 ordering) are where
  this gets its first live look.
- **WINDOWS row 4** — same family as row 3: `hyprctl dispatch movecursor` cannot emit a real
  `wl_pointer` motion/enter event on this host, so a genuinely synthetic mouse-hover test has
  never been possible; only a real physical mouse can exercise criterion 4's hover clause.
  Also explicitly names "Owner: plan 20-08's Gate B."
- **WINDOWS row 5** — `Design.sessionTileIconSize` (32px) pinning, owned by plan 20-06 which
  has since run; still open pending this gate's own acceptance confirming the pinned size
  renders correctly (folds into criterion 3's "correctly glyphed" clause).

## Setup, Before Sitting

1. Apply layer rules with `hyprctl eval` or a full Hyprland restart — never `hyprctl reload`.
2. Have `20-BEHAVIOUR-BASELINE.md`'s wleave section open alongside this record.
3. For criterion 6, use a REAL `pacman -Syuw` (download-only, safe to cancel) — not a synthetic
   `pgrep` fixture.
4. **For criterion 9 (Shutdown/Reboot), run it LAST, after every other criterion is recorded** —
   it cannot be observed without ending the session.
5. For criterion 13 (the security carry-over), raise a genuine confirm dialog from another
   running application while the menu is open (a browser's "leave site?" prompt, a file
   manager's overwrite confirmation) and report exactly what is observed.

## Gate B Criteria (UI-SPEC's current twelve, verbatim, plus the Phase 15 carry-over as 13)

**Aesthetic**

| # | Criterion (verbatim from `20-UI-SPEC.md`, fourth-revision current) | Verdict | Observation |
|---|---|---|---|
| 1 | The ring reads as a floating, frosted cluster that dims the desktop with the compositor's own blur behind it — each pill's fill is a neutral same-hue frost (`Colours.surface` at `sessionPillFillOpacity` 0.50) with its severity role carried by the icon glyph and a hairline rim, the scrim now `sessionScrimOpacity` **0.25** (down from the third revision's 0.35, still above the `quickshell-session` namespace's `ignore_alpha` 0.2 cutoff — backdrop blur confirmed visible behind the ring, not merely dimmed flat colour), fading in/out via the compositor's own layer animation (never a QML opacity ramp) — never wleave's flat six-hue-capsule layout, never the retired grid dialog's "overtakes the entire screen" reading, never the first revision's saturated-disc pill fill, and never the second revision's lighter 0.15/no-blur scrim. | PASS | Confirmed live by the operator during the 2026-08-16 sitting — the plan 20-03 `quickshell-session` no-override alpha prediction (card at 0.78, scrim at 0.25, both above the family's `ignore_alpha` 0.2 floor) is verified: the ring reads as frosted with blur visible behind it, no `ignore_alpha` override row needed. |
| 2 | A live theme switch re-colours every pill's icon/rim/warning-chip within one crossfade — the fill itself stays the SAME neutral `Colours.surface` hue across a theme switch by construction (it is the scrim's own hue, not a per-tier one), so "re-colours" here means the icon+rim+chip, not the fill. The focus ring itself is `Colours.onSurface` (reverted from the third revision's trialled `GradientBorder` gradient) — it also re-colours on the same theme switch, since `Colours.onSurface` is itself a theme-reactive role. | PASS | Confirmed live by the operator during the 2026-08-16 sitting. |

**Capability**

| # | Criterion (verbatim) | Verdict | Observation |
|---|---|---|---|
| 3 | All six actions present, correctly glyphed, icon-only (no per-pill label); Lock auto-focused on open at 12 o'clock. | PASS | Confirmed live by the operator during the 2026-08-16 sitting. Folds in and closes WINDOWS row 5 (`sessionTileIconSize` 32px pinning) — the pinned size renders correctly. |
| 4 | Arrow keys ROTATE focus around the ring — Right/Down clockwise, Left/Up counter-clockwise, wrapping past either end (D-20-24, revised); Enter activates the focused pill; Escape closes with no action taken. The centre label updates to name the newly-focused action on every rotation. **Hovering a pill with the mouse ALSO moves focus** — the ring, scale-up and centre label all follow the pointer into whichever pill it enters, confirmed by moving the mouse alone (no click, no keypress) between at least two different pills and observing the centre label change each time. | PASS | Confirmed live by the operator during the 2026-08-16 sitting, using a real mouse. **This closes WINDOWS rows 3 and 4's first live look on this surface** (D-20-36's non-serialised entrance, and the first-ever real-mouse — not synthetic — hover test this repo has been able to run). |
| 5 | Mnemonics (`l/e/u/h/r/s`) fire their action from any focus state — still undisplayed on the pill itself, confirmed working by keypress alone, not by reading a printed letter. | PASS | Confirmed live by the operator during the 2026-08-16 sitting. |
| 6 | A live pacman/paru/yay run triggers the warning chip below the ring within one poll interval of opening the menu with it already running, and clears within one poll interval of it ending — action still fires either way. | PASS | Confirmed live by the operator during the 2026-08-16 sitting, via a real `pacman -Syuw` per Setup step 3. |
| 7 | All three entry points (keybind, walker menu, bar glyph) open the identical in-process surface — none still shells to `wleave.sh`. | PASS | Confirmed live by the operator during the 2026-08-16 sitting, in addition to the automated pre-check confirming structural convergence on `togglePowerMenu()`. |
| 8 | Opening the menu visibly clears any live notification popups; the OSD is confirmed suppressed while the menu is open (a manual key press during the gate produces no OSD). | PASS | Confirmed live by the operator during the 2026-08-16 sitting. |
| 9 | Shutdown/Reboot still route through the graceful compositor exit (QPOWER-04) — confirmed against the same mechanism FIX-01 already established, not a new one. | PASS | Confirmed live by the operator during the 2026-08-16 sitting, run last per Setup step 4. |
| 10 | On open, the six pills are visibly seen sweeping into their ring positions with a rotational/circular motion (not a straight fade or a barely-visible rise) — confirmed by eye during the entrance, not merely by reading `Cascade.qml`'s own console trace. The focused pill (Lock, at open) shows a visibly NEUTRAL (non-hued), static `Colours.onSurface` focus ring — **not** an animated or rotating gradient; the third revision's own "visibly ANIMATED, rotating multi-hue `GradientBorder` ring" wording is superseded (that trial was reverted) and must not be checked against as written — plus a slight scale-up, both distinguishable at a glance from every pill's own severity-hued icon/rim and from each other. | PASS | Confirmed live by the operator during the 2026-08-16 sitting — the static neutral focus ring reads correctly against the pills' own severity-hued icons/rims. |
| 11 | On dismiss — BOTH via selecting an action (Enter/click/mnemonic) and via a no-action close (Escape/click-outside) — the six pills are visibly seen sweeping back OUT before the surface disappears, confirmed by eye, not merely by the console's `cascade: run-exit` trace. For the action-selection route specifically: the chosen action's own process must not be observed to start (e.g. no `hyprlock` flash, no suspend/reboot beginning) until AFTER the exit sweep has visibly finished — confirming the Bug-2 ordering guarantee still holds with the animation inserted, not merely that the animation plays. | PASS | Confirmed live by the operator during the 2026-08-16 sitting, across both the non-destructive routes and the Shutdown/Reboot ordering confirmation folded in with criterion 9. |
| 12 | The scrim is visibly seen to fade its dim in on open and fade back down on dismiss (not a hard snap to full dimness on the very first frame) — confirmed by eye on both open and dismiss. The third revision's own wording described this as the scrim ramping "in step with" the pill entrance/exit cascade via a shared QML `Behavior`; that coupling is removed in the fourth revision (the QML-side ramp itself caused a visible blur-snap partway through) — the scrim's fade is now the compositor's own layer animation, independent of and no longer synchronised step-for-step with the pill cascade's own timing. Check only that the fade itself reads as gradual, not that it is paced identically to the pill cascade. | PASS | Confirmed live by the operator during the 2026-08-16 sitting — the scrim's fade reads as gradual on both open and dismiss. |

**Security carry-over (Phase 15 "who owns the prompt" — not in UI-SPEC, required by this plan's own `must_haves` and the roadmap's Notes)**

| # | Criterion | Verdict | Observation |
|---|---|---|---|
| 13 | With the power menu open, have another application raise a confirm dialog (e.g. a browser's "leave site?" prompt, a file manager's overwrite confirmation). Observe and record whether that dialog lands BEHIND the layer-shell overlay. | **OVERRIDDEN** | Recorded as the known, accepted residual it was defined to be — not a fix-required failure. The layer-shell overlay sits unconditionally above every XDG toplevel, so another app's confirm dialog does land occluded behind it; there is no code fix for the general case. The operator accepts this on the strength of the three residual mitigations, all confirmed to hold: (1) the surface is transient — summoned on open, destroyed on dismiss, never left running in the background; (2) Escape always closes it with no action taken; (3) `HyprlandFocusGrab` dismisses it on focus loss. This is the Phase 15 "who owns the prompt" carry-over, and its disposition is unchanged from prior phases: an accepted structural residual of layer-shell overlays generally, not a defect specific to this power menu. |

## Deletion Authorisation

**`RETIRE-05 AUTHORISED`**

All thirteen criteria carry a verdict. Criteria 1-12 PASS. Criterion 13 (the Phase 15 "who owns
the prompt" security carry-over) is `OVERRIDDEN` — recorded as the known, accepted residual it was
defined to be, its three mitigations all confirmed to hold. The operator reported
**"Both gates approved"** on 2026-08-16.

This gate also closes **WINDOWS.md row 76** (the ring's own live human-check) — criteria 1-12's
live pass across the full closing sitting is that confirmation.

**Judged sha:** `8b6a111a5f896a4bb449ac5a2cb91bcf6680d205`.

**Interlock re-verified at authorisation time:**
`git diff --quiet 8b6a111a5f896a4bb449ac5a2cb91bcf6680d205 -- quickshell/.config/quickshell/`
holds (exit 0, no output) — the shell tree has not moved since the judged sha. Re-run at HEAD
`4aa2f20542edade99c7267a7724fc42d6f213f15` (this record's own commit ancestor) and confirmed
clean.

Plan 20-10 reads this section as its own precondition. It MUST re-assert the interlock command
above at the moment of deletion before removing `wleave` — a shell tree that has moved since the
judged sha invalidates this authorisation. Whichever of RETIRE-04/RETIRE-05 authorises second
also carries RETIRE-07 (`wlogout` + `eww`) per D-20-42/D-20-40 — both gates are authorised here in
the same sitting, so plan 20-10 (running after plan 20-09) is the plan that carries RETIRE-07.
