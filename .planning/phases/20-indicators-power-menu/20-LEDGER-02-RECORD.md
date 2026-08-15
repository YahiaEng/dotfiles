---
phase: 20-indicators-power-menu
plan: 06
record: LEDGER-02
status: wrapped-without-measurement
requirements: [LEDGER-02, MAINT-02]
---

# LEDGER-02 record — Logout wrapped without the D-29 teardown measurement

**The D-29 teardown measurement was NOT taken. Logout is wrapped anyway.** This record
states that plainly, up front, because the whole point of this document is that a later
summary must never round "wrapped" up to "measured."

## What this satisfies and what it does not

This satisfies the **OUTCOME** of ROADMAP Success Criterion 4 — "Logout is settled by the
D-29 teardown measurement being *taken* — then wrapped, or recorded with evidence as
needing no wrapping" — in the sense that Logout is now wrapped and the wrap is recorded
with evidence. It does **not** satisfy the criterion's own **LETTER**, which asks for the
measurement to be *taken*. It was not taken. **The hazard remains neither confirmed nor
falsified — the same status it has held since the 2026-07-28 waiver.**

## The concrete change

| | Before | After |
|---|---|---|
| Logout action | `cliphist wipe; uwsm stop` | `cliphist wipe; hyprshutdown --post-cmd 'uwsm stop'` |

The previous Logout action was the bare `cliphist wipe; uwsm stop`, with **no**
`hyprshutdown` wrapper at all. The new action is
`cliphist wipe; hyprshutdown --post-cmd 'uwsm stop'`. This is a genuine **ADDITION** of the
`hyprshutdown` wrap — not a re-composition of an existing wrap, and not a measurement-driven
fix — mirroring the shape Reboot and Shutdown already use. `cliphist wipe` deliberately runs
**before** teardown begins, in both the old and new action strings, because cliphist's own
daemon may already be gone once a graceful compositor exit begins.

## D-20-38's resolution — evidence, not a measurement

D-20-37 locked the wrap; D-20-38 was the open research question blocking it: does composing
`hyprshutdown --post-cmd 'uwsm stop'` do anything meaningful for Logout, or is it redundant
with (or fighting) `uwsm stop`'s own teardown? RESEARCH answered this from **live inspection
of this host's actual systemd unit topology**, not by running an actual logout (running one
would end the very session doing the research):

- `hyprshutdown`'s own `--help` is unambiguous: `--post-cmd` runs its command **strictly
  after** all apps and Hyprland's own process have already exited.
- `systemctl --user list-units --all` on this host shows `wayland-wm@hyprland.desktop.service`
  as a real (non-transient) systemd service, with `wayland-session-bindpid@1542.service`
  explicitly binding the session's whole unit graph to Hyprland's own PID, cascading up
  through `wayland-session-*@hyprland.desktop.target` to `graphical-session.target`, with a
  dedicated `wayland-session-shutdown.target` that exists specifically to fire cleanup units
  when the session ends. This is uwsm's own documented architecture — "clean shutdown" via
  systemd unit management keyed off the compositor's own lifecycle.

**Evidence from live unit topology suggests the composition has low marginal effect; it was
not empirically exercised, because doing so ends the session that would observe it.** The
reasoned conclusion: by the time `hyprshutdown --post-cmd 'uwsm stop'` actually runs `uwsm
stop`, Hyprland has already exited and systemd's own unit-dependency graph has most likely
already cascaded the session down on its own — `uwsm stop` most likely finds the compositor
already stopped. Its "removes generated units" half is separately gated behind a `-r` flag
that D-20-37's literal target string does **not** pass, so that half never engages either way.

This is worded as evidence, never as a measurement: RESEARCH's own confidence rating for
this finding is MEDIUM, explicitly flagged as "not independently measured by running an
actual logout." Assumption A3 in `20-RESEARCH.md`'s Assumptions Log names the residual risk
directly — that this conclusion, drawn from the *current* static unit topology, may not
generalize correctly to the topology that exists *at the moment Logout actually runs*, and
that if the actual cascade behavior differs, "low marginal effect" could be wrong in either
direction (it could matter more — a real gap — or be entirely inert, as suspected).

## The trap, named explicitly

`hyprshutdown --post-cmd 'uwsm stop'` **sounds** authoritative, and it mirrors the
Reboot/Shutdown pattern byte-for-byte, which invites the same confidence those two wraps
earned. But Reboot's and Shutdown's own `--post-cmd` does something unambiguous —
`systemctl reboot` / `systemctl poweroff` genuinely change the machine's power state, work
that has to happen regardless of what already tore down. Logout's `uwsm stop` very likely
finds nothing left to do by the time it runs, for the systemd-topology reasons above. Reusing
the same wrap shape for a structurally different situation is exactly the kind of change that
gets misremembered later as "the same fix, done three times" rather than "a formality applied
once and a real fix applied twice."

## Standing instruction for whoever summarises this phase

**No summary sentence may say Logout's teardown hazard is "closed", "resolved", "fixed" or
"measured".** The permitted phrasing is: **"wrapped, unmeasured, evidence suggests low
marginal risk."** Any summary that uses one of the forbidden verbs above about this hazard is
wrong and must be corrected before it ships, regardless of how confident the surrounding
prose otherwise sounds.

## Action string discipline

`PowerMenu.qml`'s Logout command is **not** upgraded to `uwsm stop -r`. Adding the `-r` flag
would change D-20-37's locked decision's literal content and would itself be a new, explicit
decision made outside this plan — not something this record or this plan is authorised to
do.

## What a future phase would need to actually take the measurement

The verbatim reproduction steps already exist and are not repeated here — they remain in
`.planning/milestones/v3.0-phases/13-motion-retrofit-existing-surface-sweep/13-03-PLAN.md`
Task 2 ("D-29 — measure whether the logout path actually has the hazard WR-04 assumes"): stage
a `trap "" TERM` blocking client, observe `hyprshutdown --dry-run`'s app-close step, then from
a **separate TTY** (because the measurement ends the session being measured) time `uwsm stop`
and record whether the blocking PID survives and whether the return is near-instant or stalls
for a fixed interval.

The real fix for the underlying hazard — an actual unkillable-client detector, rather than a
teardown-timing measurement — is explicitly deferred to v5.0+ in `20-CONTEXT.md`'s deferred
list, because nothing on this stack currently detects it reliably. QPOWER-03's own three
detectors (pacman/paru/yay, active downloads, a hand-maintained window-class deny-list) are
recorded honestly elsewhere as a bounded stand-in for that same hazard, not a solution to it.

## Cross-references

- D-20-37 (`20-CONTEXT.md`) — the locked decision to wrap Logout without taking the
  measurement.
- D-20-38 (`20-CONTEXT.md`) — the open research question this record resolves as evidence,
  not as a measurement.
- `20-RESEARCH.md` § "Priority Research Findings" item 1, § "Common Pitfalls" Pitfall 2
  ("Treating 'wrapped' as 'measured' for Logout"), § "Assumptions Log" row A3.
- ROADMAP.md Phase 20 Success Criterion 4.
- REQUIREMENTS.md LEDGER-02 (MAINT-02).
