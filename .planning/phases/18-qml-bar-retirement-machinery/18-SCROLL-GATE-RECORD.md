# 18-SCROLL-GATE-RECORD.md — what 18-19 must be told about scroll on this bar

This is the single place 18-19 looks for everything about scroll on this bar that a live look
cannot settle by itself. It is written for a reader who has not read `18-12-PLAN.md`.

## Section 1 — GATE-02 criterion B.3, brightness half

UI-SPEC's GATE-02 render-gate criterion **B.3** requires: scrolling the bar's audio and brightness
sections changes the corresponding system value. Its Pass bar states that any single failure
blocks the deletion commit.

**Verdict, quoted so it can be copied without being rephrased:**

> not demonstrable on this hardware — structurally present

Evidence, each item re-runnable in one command rather than taken on trust:

- `/sys/class/backlight/` is empty on this machine (`ls -la /sys/class/backlight/` shows only `.`
  and `..`) — this is a desktop board (B550 AORUS ELITE AX V2), not a laptop, with no panel and no
  backlight device to control.
- `brightnessctl -m -l -c backlight` prints nothing on stdout and exits non-zero (verified this
  session: 0 lines on stdout, exit code 1, the "Failed to read any devices of class 'backlight'."
  message on stderr).
- `light`, which the retired bar's own backlight module shelled out to (`config-floating.jsonc`'s
  `"on-scroll-up": "light -A 5"` / `"on-scroll-down": "light -U 5"`), is **not installed**
  (`command -v light` finds nothing) — so the capability being compared against was **already dead
  in the baseline**, per `18-BEHAVIOUR-BASELINE.md`'s own `## Dead Definitions` table (the
  `floating` / `backlight` row, filed under D-18-39). Cited rather than re-derived: this is the
  load-bearing point — B.3's brightness half cannot be a regression, because there is nothing on
  the other side of the comparison to have regressed from.
- What was built anyway, and what was proven about it: `BrightnessBackend.qml`'s presence gate
  (`brightnessctl -m -l --class backlight`, parsed the same way for both the negative and positive
  case) was exercised in both directions on this host this session —
  - **Presence-negative** (the real state of this machine): `brightnessctl -m -l -c backlight`
    prints 0 device lines.
  - **Presence-positive** (simulated through the real code path — the same probe, the same
    parser, the same argv builder, no test double anywhere): `brightnessctl -m -l -c leds` prints
    8 real device lines on this host (`enp5s0-{0..3}::lan`, `input35::numlock`,
    `input35::scrolllock`, `input35::capslock`, `input11::mute`), confirming the backend's
    `deviceClass` property is the one true repoint point for this proof, exactly as its own header
    comment states.
  - **Argv correctness, proven without a write**: the exact argv shape the backend's `adjust()`
    builds (`brightnessctl -m --class <class> -d <device> set <delta-form>`) was run through the
    tool's own `-p` (pretend, no write) mode against a real `leds` device and produced a
    well-formed five-field machine-readable line on exit 0.

What this verdict does **not** mean, stated plainly:

- It is not a pass.
- It is not a failure blocking the deletion commit, because the baseline had no working capability
  to lose — see the Dead Definitions citation above.
- It is not a licence to skip the audio half of B.3, which is fully demonstrable on this host and
  must be confirmed live (three wheel-up notches on the audio entry raising
  `wpctl get-volume @DEFAULT_AUDIO_SINK@` by 15 percentage points, with the bound holding at both
  ends).

**The one condition that would change this verdict, and the one command that decides it:** a
backlight device appearing on this host (a dock event, a swapped GPU with display outputs feeding
a panel, or simply running this document's checklist on different hardware). Run
`brightnessctl -m -l -c backlight`; if it prints one or more device lines, brightness has become
demonstrable and this section's verdict no longer applies — `BrightnessBackend.qml`'s own
`deviceClass` default (`"backlight"`) already targets exactly that class, so no code change is
needed to pick it up, only a re-run of this document's checklist.

## Section 2 — scroll-to-switch-workspaces: a deliberate cut, decided here

`18-09-PLAN.md` named this and routed the decision to this plan. Recorded here as **not
implemented**, with the reasoning given as routing, not difficulty:

- QBAR-04's requirement text names the audio and brightness sections and nothing else; QBAR-03's
  text names clicking. Workspace scroll belongs to neither requirement's text.
- The capability is **not lost by retiring the bar** — `keybinds.lua` already binds Super plus
  wheel, globally, to the identical next/previous workspace expressions, quoted verbatim from the
  file:

  ```
  hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" })) -- Next workspace
  hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" })) -- Previous workspace
  ```

  The only difference a user can feel is scrolling over the bar without holding Super.

**The complete remedy, pre-specified so that if 18-19's criterion B judges the difference a loss,
the fix is mechanical rather than a design decision taken while a blocking gate is red:**

- File: `quickshell/.config/quickshell/modules/bar/WorkspaceCapsule.qml` (18-09's).
- Attach to: the workspace capsule's root entry item (the element `WorkspaceCapsule.qml`'s own
  click dispatch is already attached to).
- Handler shape: identical to the two `WheelHandler`s this plan built in
  `MediaConnectivityCapsule.qml` — `target: null`, no `property:` attribute, `angleDelta.y`
  accumulated into signed whole 120-unit notches, the remainder carried forward.
- Dispatch: one wheel-up notch emits the same `hl.dsp.focus({ workspace: "e+1" })` expression form
  `keybinds.lua` already uses (adapted to whatever dispatch mechanism `WorkspaceCapsule.qml` already
  calls for its click path — the exact call surface, not a new one); one wheel-down notch emits
  the matching `"e-1"` form.
- Discipline to copy: `Overview.qml`'s validate-before-interpolate rule, which `WorkspaceCapsule.qml`
  already follows for its own click dispatch — no new validation pattern is introduced.
- No new `Design` token, no new backend, and no `BarEntryModel.qml` change are needed.

This plan chose **not to implement it** rather than being unable to, so the cut reads as a routing
decision and never as a capability someone judged beyond reach.

## Section 3 — UI-SPEC deltas this plan creates

Two, recorded in the same shape D-18-38 used to correct the exclusiveZone formula, so a later
reader trusts the document minus a known errata list rather than trusting it wholesale:

- **E3 zero-one-many.** `18-UI-SPEC.md`'s `## UI Considerations` E3 zero-one-many row states that
  battery present/absent is the ONLY count variation in the media+connectivity capsule. That claim
  is now false: brightness is a second hardware-gated member, rendering nothing on this host and a
  real percentage on hardware that has a backlight. The row's substance survives — the capsule
  re-flows without leaving a gap when either drops out, both entries following the exact same
  `visible`-gated, zero-extent-when-absent shape — but its exclusivity claim does not.
- **New Tokens table.** `18-UI-SPEC.md`'s `## New Tokens` table does not contain the scroll-step
  token this plan added: `barScrollStepPercent` (value `5`), appended to
  `quickshell/.config/quickshell/modules/dashboard/Design.qml`. Its provenance is the three places
  on this host that already agree on the same number, so the parity claim is auditable:
  `config-floating.jsonc`'s pulseaudio module (`"scroll-step": 5`), the same file's backlight
  module (`light -A 5` / `light -U 5`), and `swayosd-client`'s own default step for
  `--output-volume raise/lower` / `--brightness raise/lower`, already bound to this host's
  hardware media keys in `keybinds.lua`.

## Section 4 — the narrowed 18-08 gate

`18-08-PLAN.md`'s own acceptance criterion asserted that `MediaConnectivityCapsule.qml` contains
no pointer-handler identifiers (`HoverHandler`/`MouseArea`/`TapHandler`/`popoutDwellMs`/
`SectionPopout`/`popoutDismissGraceMs`). That was a wave-3 freeze statement, scoped to wave 3 by
18-05's own manifest header text. Wave 4 (this plan) narrows it to permit **wheel handling only**
— `WheelHandler` now appears twice in the file (once on the audio entry, once on the brightness
entry) — while every other identifier in that original list is still asserted at zero by this
plan's own acceptance criteria; those belong to 18-13's hover dwell, pin latch and popout summon.

**Operational consequence, stated in one line:** re-running 18-08's verify script unchanged after
this plan lands will report a failure on the `WheelHandler`-adjacent clause of that one criterion,
and that failure is **superseded**, not a regression — it is the expected, narrowed-on-the-record
result of this plan landing, not evidence that 18-08's other invariants (the five readout entries'
geometry, glyphs, precedences, and the media title's cap-and-elide) have been disturbed. This
plan's own acceptance criteria re-assert every one of 18-08's other file invariants and confirm
them still holding.

## Section 5 — what 18-19 must do

- **Confirm the audio half of B.3 live.** Three wheel-up notches on the audio entry must raise
  `wpctl get-volume @DEFAULT_AUDIO_SINK@` by 15 percentage points with the bar's own percent
  agreeing, and the bound must hold at both ends (no value above `1.00`, none below `0.00`).
- **Read Section 1 for the brightness half and copy its verdict line rather than re-deciding it** —
  `not demonstrable on this hardware — structurally present` — unless this host's hardware has
  changed, in which case re-run Section 1's one decisive command first.
- **Judge Section 2's difference** (scrolling the bar without holding Super vs. the global
  Super+wheel bind that remains) and, if it is judged a loss, execute Section 2's remedy exactly as
  specified — file, handler shape, and both dispatch expressions.
- **Carry Sections 3 and 4 into the phase's own errata** so the E3 zero-one-many exclusivity claim,
  the missing `barScrollStepPercent` table row, and the narrowed 18-08 pointer-handler gate are not
  rediscovered as surprises in Phase 19.
