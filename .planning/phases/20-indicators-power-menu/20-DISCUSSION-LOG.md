# Phase 20: Indicators & Power Menu - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-14
**Phase:** 20-indicators-power-menu
**Areas discussed:** OSD frame & placement, OSD multi-slider column, Power menu shape &
trigger, Power menu safety warning, Caps Lock + the libinput service, Lock-screen
visibility, LEDGER-02 Logout measurement, LEDGER-05 WINDOWS triage, plus a follow-up round
on the Logout wrap command, the bar power probe, layer rules, entrance motion, cross-surface
suppression and GATE-01 scope.

All eight offered areas were selected, and the user twice chose to continue past the
"ready for context" checkpoint rather than stop.

---

## OSD frame & placement

Two frictions were surfaced before asking: `Toast.qml` is anchored **top-centre** (not
top-right as assumed) and capped at 320px with a `Row` body; and it is explicitly
non-interactive (`keyboardFocus: None`, `focusable: false`), which QOSD-03's hover-hold
requirement cannot be satisfied by.

| Option | Description | Selected |
|--------|-------------|----------|
| Bottom-centre (swayosd parity) | Keeps existing muscle memory; diverges from Caelestia's right-edge region | ✓ |
| Top-centre (Toast's anchor) | Literal reuse, zero new positioning code | |
| Right-edge popout region | Caelestia's actual placement; needs geometry coordination | |

| Option | Description | Selected |
|--------|-------------|----------|
| Extend Toast with opt-in input | Add `interactive` property, default false; one frame, no 4th top-level surface | ✓ |
| OSD gets its own frame | Copies Toast's chrome; adds a 4th frame with GATE-03/GATE-04 cost | |
| Drop hover-hold from QOSD-03 | Ship auto-hide only; would amend a requirement | |

| Option | Description | Selected |
|--------|-------------|----------|
| State change on the backends | `Connections` on Audio/Brightness backends; reacts regardless of source | ✓ |
| Media-key bind only | Simpler exec-target swap; bar scroll and centre sliders would show nothing | |

| Option | Description | Selected |
|--------|-------------|----------|
| 1s (swayosd parity) | SwayOSD's own default | |
| 2s (reuse notifToastDurationMs) | No new token; doubles today's dwell | |
| New osdHideDelayMs token | Tunable independently of the DND toast | ✓ |

**User's choice:** bottom-centre, extend Toast with opt-in input, state-driven trigger,
new dedicated delay token.
**Notes:** Flagged for the planner afterwards — bottom-centre *plus* opt-in input means
`Toast.qml` needs **two** new properties, since it hardcodes `anchors.top: true`.

---

## OSD multi-slider column (QOSD-04)

Stated up front: Caelestia gates sliders on static config flags and does **not** gate on
"recently moved" — the moved-only rule is this project's own addition, so this area
diverges by requirement rather than by choice.

| Option | Description | Selected |
|--------|-------------|----------|
| Rolling recency window | Shows if changed within last N seconds; one tunable number | ✓ |
| Sticky while visible | Accumulates while on screen; stale sliders persist under hover | |
| Always show all three | Caelestia's behaviour; drops the QOSD-04 differentiator | |

| Option | Description | Selected |
|--------|-------------|----------|
| Adjustable — scroll and drag | What QOSD-04 says; cost already paid by interactive Toast | ✓ |
| Scroll only, no drag | Cheaper hit-testing; a dead drag reads as broken | |
| Read-only readout | SwayOSD parity; contradicts QOSD-04 | |

| Option | Description | Selected |
|--------|-------------|----------|
| Icon + label, replacing the column | Same shape the DND toast uses; keeps binary state out of a continuous-value column | ✓ |
| A non-slider row inside the column | More informative; two row types in one column | |
| Its own separate toast instance | Cleanest separation; two uncoordinated surfaces possible | |

| Option | Description | Selected |
|--------|-------------|----------|
| New osdWidth token, ~380px | Readable track, visibly lighter than the 430px family | ✓ |
| Reuse notifToastMaxWidth (320px) | No new token; short track under an icon gutter | |
| 430px — match centre and popups | One width across the family; a volume blip as wide as the centre | |

**User's choice:** all four recommendations.
**Notes:** none.

---

## Power menu shape & trigger

The first pass of this area was **interrupted by the user** to correct an omission and to
ask for a rendered comparison. Recorded because it changed the outcome.

**User's correction:** "The power menu glyph we already have in our bar." A scout then
found `ClockActionsCapsule.qml:1003` — a `powerCell` with the `power_settings_new` glyph
launching `wleave.sh` via `powerLaunchProcess`, guarded by a `test -x` probe at line 571.
This was a **third** consumer of `wleave.sh`, absent from the roadmap's consumer list.

**User's request:** "Show me how the third option will look like." The three shapes were
re-presented as rendered ASCII mockups rather than prose descriptions.

| Option | Description | Selected |
|--------|-------------|----------|
| Centred floating dialog | PanelDialog family, 3×2 grid, scrim; no new frame type; warning lives inside the frame | ✓ |
| Full-screen overlay (wleave parity) | Today's behaviour and end-4's; 4th frame; covers app dialogs raised beneath | |
| Inline right-edge popout (Caelestia) | D-19-00's default; contends for the notification centre's region | |

| Option | Description | Selected |
|--------|-------------|----------|
| Super+Shift+Q (repointed) | Existing keybind, retargeted | ✓ |
| Walker menu entry (repointed) | main.toml:35, retargeted | ✓ |
| A bar power capsule | Offered as *new* — user corrected that it already exists | ✓ |

| Option | Description | Selected |
|--------|-------------|----------|
| Exclusive focus + arrows + mnemonics | Diverges from D-19-18 with cause — that rule was for a non-modal centre | ✓ |
| Exclusive focus + arrows only | Matches both references exactly; loses existing shortcuts | |
| No exclusive focus | Consistent with centre/dashboard; ambiguous keys on a session-ending surface | |

| Option | Description | Selected |
|--------|-------------|----------|
| Redesign toward the reference language | The milestone's stated intent | ✓ |
| Keep the six hue capsules (Phase 9) | Most conservative; ports GTK4 design into QML | |
| Hue capsules re-expressed in shell tokens | Middle path | |

**User's choice:** centred floating dialog, all three entry points repointed, exclusive
focus with mnemonics, full redesign.
**Notes:** The selected mockup is reproduced in CONTEXT.md `<specifics>` so the visual
intent survives into UI work. The lesson recorded for downstream: **show the surface,
don't describe it.**

---

## Power menu safety warning (QPOWER-03)

| Option | Description | Selected |
|--------|-------------|----------|
| Running pacman/paru process | pgrep; cannot false-positive on a stale lock | ✓ |
| The pacman db lock file | Catches unanticipated wrappers; permanent false-positive on a stale lock | |
| Active downloads | end-4's second check; deliberately vague heuristic | ✓ |
| Unsaved-work / unkillable clients | The LEDGER-02 hazard class; no reliable detector exists | ✓ |

| Option | Description | Selected |
|--------|-------------|----------|
| Warn only — action stays available | end-4's behaviour; a stuck detector must never lock you out | ✓ |
| Warn + require a second confirm | Harder to fire off by muscle memory; adds a step to a fast menu | |
| Block while the warning is live | Strongest; a stuck detector locks you out | |

| Option | Description | Selected |
|--------|-------------|----------|
| Shutdown, Reboot, Hibernate, Logout | Everything that ends the session or cuts power mid-transaction | ✓ |
| Shutdown and Reboot only | Narrowest; Logout tears down under a running upgrade too | |
| All six, incl. Lock and Suspend | Simplest rule; warns about things Lock cannot harm | |

| Option | Description | Selected |
|--------|-------------|----------|
| On open, then poll while visible | Live while deciding; nothing runs while dismissed | ✓ |
| On open only | Cheapest; banner can be stale by the time you press | |

**User's choice:** three detectors, warn-only, four destructive actions, poll while visible.
**Notes:** The third detector was pushed back on in a follow-up as unbounded — see the
follow-up round below. The user bounded it rather than dropping it.

---

## Caps Lock + the libinput service

Live ground truth gathered before asking, and it changed the framing substantially:
`/sys/class/leds/input5::capslock/brightness` exists, is world-readable, reads `0`;
`input5` is an unstable kernel index; **two** keyboards report `capsLock` to Hyprland but
only one has an LED node; `sddm.service` is enabled; `swayosd-libinput-backend.service` is
enabled at system level, but `swayosd-server` only starts inside the Hyprland session
(`autostart.lua:192`).

| Option | Description | Selected |
|--------|-------------|----------|
| Drop it — fold into LEDGER-02 | Measure the hazard first, build a detector later | |
| Count toplevels that ignore a close request | Configured class deny-list; honest but hand-maintained | ✓ |
| Show a plain toplevel count | Zero false-positive risk, purely informational | |
| Keep it, define it during research | Risks spending the budget to learn nothing exists | |

| Option | Description | Selected |
|--------|-------------|----------|
| Glob at startup, re-resolve on failure | Handles replug without device-event watching; absent-not-broken on total miss | ✓ |
| Glob + match Hyprland's focused keyboard | Correct for two keyboards; machinery for a case where only one has an LED | |
| Poll hyprctl devices instead | Covers the LED-less keyboard; needs a timer, contradicts QOSD-02's named mechanism | |

| Option | Description | Selected |
|--------|-------------|----------|
| Measure at the SDDM prompt first, then delete | Evidence over prediction; Phase 15's own "prefer the measurement" decision | ✓ |
| Delete it with swayosd, record the loss | Faster; claims a loss without checking whether it's real | |
| Keep the service, keep swayosd installed | Blocks RETIRE-04 outright | |

| Option | Description | Selected |
|--------|-------------|----------|
| Both on and off (swayosd parity) | Confirms the key registered in both directions | |
| Only when caps turns on | Half the interruptions; loses the exit confirmation | ✓ |

**User's choice:** deny-list toplevel count, glob-and-re-resolve, measure-then-delete,
on-entry only.
**Notes:** The deny-list option was described honestly at ask time as "a hand-maintained
list pretending to be a detector"; that caveat is carried verbatim into CONTEXT.md D-20-27
so it is not later mistaken for a real detector.

---

## Lock-screen visibility (QOSD-01)

Framed with the protocol reality: hyprlock is an `ext-session-lock-v1` client and the
protocol requires the compositor to render only lock surfaces, so SwayOSD's pill is very
likely already invisible there today.

| Option | Description | Selected |
|--------|-------------|----------|
| Measure at GATE-01, let the answer define it | One check settles whether the clause describes a real capability | ✓ |
| Put the readout inside hyprlock | Genuinely works where a layer surface cannot; net-new scope | |
| Accept the gap, record it | Honest; closes without checking | |

**User's choice:** measure at GATE-01.
**Notes:** none.

---

## LEDGER-02 Logout measurement

| Option | Description | Selected |
|--------|-------------|----------|
| Skip the measurement, wrap Logout anyway | Closes the hazard by construction; satisfies SC-4's outcome, not its letter | ✓ |
| Take the full D-29 measurement | The only path satisfying SC-4 as written; session-ending and manual | |
| Reduced measurement, then wrap | Measures the case that was never in doubt | |

**User's choice:** skip the measurement, wrap anyway.
**Notes:** The option was written to state explicitly that this "must be recorded as
*wrapped without measurement*, never as a measurement taken" — the user selected it on
those terms. This is the second time this measurement has been declined (first: 2026-07-28).

---

## LEDGER-05 WINDOWS triage

Surfaced before asking: LEDGER-05 and ROADMAP SC-6 both say 16 open rows;
`.planning/WINDOWS.md` frontmatter reads `open_count: 51` (total 75). A 3× scope
difference on a success criterion.

| Option | Description | Selected |
|--------|-------------|----------|
| Triage in-scope rows, batch re-defer the rest | Meets "none left silently open" without 51 hand-written verdicts | ✓ |
| Triage all 51 individually | Most complete; large clerical load on an already-full phase | |
| Re-scope to the original 16 | Honest about drift; leaves 35 open against a criterion saying none should be | |

**User's choice:** triage in-scope, batch re-defer the rest.
**Notes:** none.

---

## Retirement sequencing

| Option | Description | Selected |
|--------|-------------|----------|
| Two independent gates, each unlocking its own deletion | The halves share no backend; a stall in one doesn't hold the other hostage | ✓ |
| One combined gate at phase end | Fewer gate sessions; Phase 19 needed twelve rounds on a single gate | |

**User's choice:** two independent gates.
**Notes:** none.

---

## Follow-up round — the mechanics

Offered as the "explore more" option and taken. Two findings preceded the questions:
`wleave/.config/wleave/layout.json` is the **only** home of the six action command strings
and dies with the package; and `windowrules.lua` sets a `^quickshell-.*` family regex with
`ignore_alpha = 0.5` that per-surface rules must be declared *after* to win.

| Option | Description | Selected |
|--------|-------------|----------|
| Mirror shape, but verify it composes first | `cliphist wipe; hyprshutdown --post-cmd 'uwsm stop'`, with a blocking research check | ✓ |
| Mirror shape, ship it | Fastest; risks a fix that changes nothing | |
| Leave Logout bare, record the decision | Contradicts the earlier choice; offered in case the redundancy concern changed it | |

| Option | Description | Selected |
|--------|-------------|----------|
| Remove the probe — glyph always available | "Menu is missing" stops being reachable once it's in-process | ✓ |
| Repoint the probe at the QML file | Keeps the defensive shape for a state that implies the shell never loaded | |

| Option | Description | Selected |
|--------|-------------|----------|
| Distinct namespaces, rules after the family regex | Matches the placement lines 499–526 already use | ✓ |
| OSD reuses quickshell-notif-toast | Free slide rule; the two surfaces could never diverge on blur/alpha | |
| Rely on the family regex only | Least config; neither surface gets an entrance animation | |

| Option | Description | Selected |
|--------|-------------|----------|
| Staggered per-action cascade | Re-expresses the approved md3_decel entrance on Motion tokens | ✓ |
| Single dialog scale + fade | Most consistent with the panel family | |
| Stagger, and settle before input | Closes the Phase 9 hover-during-entrance hazard; adds an unresponsive moment | |

**User's choice:** verified mirror wrap, remove the probe, distinct namespaces, staggered
cascade.
**Notes:** Declining the third motion option leaves WINDOWS rows 3 and 4 (the never-live-
exercised Phase 9 hover-during-entrance interaction) open — recorded as in-scope for the
LEDGER-05 triage rather than silently carried.

---

## Second follow-up round — cross-surface behaviour and GATE-01

| Option | Description | Selected |
|--------|-------------|----------|
| Never suppressed | Bottom-centre collides with nothing; suppressing key feedback is a downgrade | |
| Suppressed while the power menu is open | An OSD over a modal scrim reads as a leak | ✓ |
| Suppressed by centre or power menu | Mirrors QNOTIF-10; but an OSD duplicates nothing | |

| Option | Description | Selected |
|--------|-------------|----------|
| No — leave them | They don't overlap; silently clearing loses unseen information | |
| Yes — dismiss on open (end-4 parity) | Clean screen for a session decision; nothing lost, only unseen | ✓ |

| Option | Description | Selected |
|--------|-------------|----------|
| The two open questions this phase depends on | Without them, two decisions default rather than evidence | ✓ |
| Full behavioural baseline per the 18 protocol | The roadmap's named worked example | ✓ |
| The consumer sweep | WINDOWS #1 is the standing precedent for skipping it | ✓ |

**User's choice:** OSD suppressed by the power menu only; power menu dismisses popups on
open; GATE-01 covers all three enumerations.
**Notes:** Both cross-surface answers went **against** the stated recommendation — the user
chose the more conservative modal behaviour in both cases.

---

## Claude's Discretion

- Starting value for `Design.osdHideDelayMs` (SwayOSD's default is 1000 ms).
- The QOSD-04 recency-window value.
- Final layer-namespace strings (`quickshell-osd` / `quickshell-session` are provisional).
- Whether the OSD column reuses the centre's slider component or a lighter variant.
- Initial contents of the QPOWER-03 window-class deny-list.
- Whether the power dialog's scrim is a window property or a separate full-screen layer.

## Deferred Ideas

- A real unkillable-client detector (v5.0+; depends on a measurement being declined here).
- The D-29 teardown measurement itself — declined for the second time.
- Caps-lock state for the second, LED-less keyboard.
- A `quickshell-doctor` fault-injection check that a missing LED node degrades to
  absent-not-broken.
- The ~35 batch-re-deferred WINDOWS.md rows, each needing a named owning phase at triage.
- Reboot-to-firmware-settings (end-4's 8th action) — already out of scope per FEATURES.md.
- The audio-sink protection banner — no equivalent trigger on this audio stack.
