# Phase 20 GATE-01: Live Measurements

Three observations RESEARCH.md and this plan's own Task 3 could not take from within an
in-session agent — the SDDM greeter (pre-session), the hyprlock lock surface, and a real
physical Caps Lock key press. All three were taken by the operator at the physical machine on
2026-08-15 and reported back verbatim. Recorded here exactly as given — no observation below is
softened, re-interpreted, or re-run. Where the operator did not report a sub-detail, it is
recorded as NOT CAPTURED rather than inferred or reconstructed.

---

## § SDDM greeter Caps Lock (D-20-17)

**Question:** Does any on-screen indicator appear when Caps Lock is pressed at the SDDM login
prompt, before any Hyprland session exists? This decides whether
`swayosd-libinput-backend.service`'s pre-session reach is real or already dead.

**Procedure run:** Operator logged out to the SDDM greeter and pressed Caps Lock at the login
prompt, on physical hardware.

**Observed outcome:** NO on-screen indicator appeared at the greeter.

**Observed outcome:** The keyboard's own hardware LED DID light at the greeter.

These are two distinct facts, recorded separately per this plan's own instruction — confusing
them would produce a wrong RETIRE-04 verdict:

- The keypress reached the kernel and the keyboard firmware's own LED responded (this is
  hardware behaviour, independent of `swayosd` entirely — every USB/PS2 keyboard does this on
  its own regardless of what software is or isn't running).
- Separately, and the actual measured fact this observation exists to establish: no *software*
  on-screen indicator appeared. `swayosd-libinput-backend.service` is enabled and running at
  system level at the greeter (confirmed live in `20-BEHAVIOUR-BASELINE.md` § "Two-unit
  topology"), but the thing that renders anything visible — `swayosd-server` — is only started
  inside the already-authenticated Hyprland session at `autostart.lua:192`. This observation is
  the clean negative that confirms the backend's pre-session reach produces no visible feedback
  on its own; it is not an inconclusive "nothing happened."

**Date:** 2026-08-15.

**Consequence (D-20-17 / D-20-18):**

**RETIRE-04 proceeds, including `swayosd-libinput-backend.service`.** The measured outcome is
NO on-screen indicator at the greeter, so per D-20-17's own decision rule the backend's
pre-session reach is confirmed dead by measurement, not assumed dead by inherited analogy.
Plan 20-09 reads this verdict directly: `swayosd-libinput-backend.service` is in scope for
deletion, along with the rest of the `swayosd` package, with no scope escalation required.
D-20-18's BLOCKED branch does not apply — no greeter feedback was observed.

**Verdict token:** `RETIRE-04 proceeds`

---

## § SwayOSD over hyprlock (D-20-19)

**Question:** Does the SwayOSD pill appear over the hyprlock lock surface when a volume key is
pressed while the session is locked? This settles QOSD-01's lock-screen clause.

**Procedure run:** Operator locked the session and, with hyprlock up, pressed a volume key on
physical hardware.

**Observed outcome:** NO — the SwayOSD pill did NOT appear over the hyprlock lock surface.

**Date:** 2026-08-15.

**Consequence (D-20-19):**

Per D-20-19's negative branch, QOSD-01 is **amended with the evidence, not chased**. The
requirement's real content was never "render a pill over the lock surface" — it was "the keys
keep working while locked" — and that is already true today via the six `locked = true`
`swayosd-client` binds at `keybinds.lua:297-308` (transcribed verbatim in
`20-BEHAVIOUR-BASELINE.md` § "The six `swayosd-client` invocations"). The measurement confirms
hyprlock's `ext-session-lock-v1` surface correctly suppresses the layer-shell overlay, exactly as
the protocol is supposed to behave, and no new lock-surface-integration work is needed for
QOSD-01's replacement OSD.

D-20-20 (putting the readout inside hyprlock's own config was already considered and rejected as
net-new scope in a config this shell does not own) is not reopened by this amendment — the
amendment is "the keys already work locked," not "render something inside hyprlock."

**Verdict token:** `amended — locked-key-functionality already satisfied, no lock-surface render required`

---

## § sysfs Caps Lock watch (RESEARCH Open Question 1 / Assumption A1)

**Question:** Does a `select.poll()`/`FileView{watchChanges:true}`-class watcher on
`/sys/class/leds/*::capslock/brightness` actually observe a change event when the physical Caps
Lock key is pressed? This decides QOSD-02's implementation mechanism (event-driven watch vs.
polling `Timer` fallback).

**Procedure run:** Operator ran a `select.poll()` watcher against the resolved
`/sys/class/leds/*::capslock/brightness` node and pressed the physical Caps Lock key twice — once
to turn it on, once to turn it off. No `wtype`, no root write — a real physical key press, per
this task's own instruction that a synthetic event would not exercise the real evdev/LED-classdev
path.

**Observed outcome:** NO — the watcher printed no EVENT line on EITHER transition (neither the
ON edge nor the OFF edge).

**Resolved node path:** NOT CAPTURED. The operator did not report back the resolved
`/sys/class/leds/*::capslock/brightness` node path the watcher printed. Per this plan's own
instruction, this is recorded as NOT CAPTURED rather than re-resolved and presented as what was
observed — the session index (`inputNN`) is documented as unstable per D-20-14 (already
confirmed to differ across boots: `input5` on 2026-08-14, `input33` on 2026-08-15), so a
freshly re-resolved path taken now would not be evidence of what this watcher actually watched
during the operator's test. This gap is itself the third data point: it independently confirms
why D-20-14's glob-at-startup / re-glob-on-failure design exists — the concrete node cannot be
assumed stable enough to hardcode or to retroactively reconstruct.

**Date:** 2026-08-15.

**Consequence (RESEARCH Open Question 1 / Assumption A1):**

The negative result is recorded plainly, per this plan's own instruction, and is flagged to the
developer as a **SCOPE CONVERSATION**, not silently substituted around: the event-driven
`FileView{watchChanges:true}` mechanism QOSD-02 specified did NOT fire on either edge of a real
physical Caps Lock press in this test. Assumption A1's risk ("QOSD-02 ships appearing complete
but the indicator never fires on a real Caps Lock press") is now a measured fact, not a
theoretical risk.

The fallback is a polling `Timer`, which costs the phase its zero-idle claim for this one
indicator (D-20-16 had explicitly rejected polling `hyprctl devices -j` on zero-idle grounds —
the same zero-idle tension now applies to the sysfs node itself). This substitution is **not
pre-authorised here** — plan 20-05 Task 2's implementation path is a decision the developer makes
with this evidence in hand, not one this document makes for them.

**Verdict token:** `did-not-fire`

