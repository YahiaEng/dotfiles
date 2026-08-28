---
gsd_summary_version: 1.0
quick_id: 260828-so7
slug: fix-three-quickshell-doctor-failures-lau
date: 2026-08-28
status: complete
tasks_completed: 3
commits: 4
commit_range: 334064e9..HEAD
gates:
  quickshell-doctor-self-test: "61 passed, 0 failed"
  quickshell-doctor-live: "28 passed, 0 failed"
  colour-lint: "569 passed, 0 failed"
  motion-lint: "784 passed, 0 failed"
  qml-import-check: "0 unresolved across 191 files"
  button-lint: "9 passed, 0 failed"
  transparent-lint: "192 passed, 0 failed"
---

# Fix the three quickshell-doctor failures

`quickshell-doctor` went from **25 passed / 3 failed** to **28 passed / 0
failed**, and its self-test from 59 to 61 fixtures. The shell was never
restarted; PID 18909 throughout.

## The headline finding is about the gate, not the code

Two of the three defects shipped *because the gate was never run*. It had been
recorded as operator-only on the belief that it restarts the shell. That belief
was over-broad and cost real coverage:

- `WITH_COMPOSITOR_RELOAD=0` is the default. The
  `systemctl --user restart quickshell.service` lives in
  `_qsd_restore_quickshell_layer_rules`, reachable **only** from the trap on the
  opt-in `--with-compositor-reload` path. A plain run prints
  `compositor-reload=SKIPPED` and never restarts.
- The agent shell's cgroup (`…/kitty-4292-0.scope`) is disjoint from
  `quickshell.service`, so even the opt-in path could not reach this session.

This is the same failure shape as the `hyprctl reload` rule already recorded: a
true narrow fact widened into a false broad rule. **A gate you refuse to run
reports nothing.**

## Task 1 — the launcher-log check was skipping its own assertion

`~/.cache/quickshell.log` carries NUL bytes (`file` reports `data`), so GNU grep
short-circuited to "binary file matches" and returned nothing.

The false FAIL was the *smaller* half. Because the line number came back empty,
the `else` branch never ran and **the crash/abort-marker assertion — the only
thing that block exists to prove — was silently skipped on every run this file
has ever had.** Manually confirmed 0 crash markers, so nothing was actually
wrong; the check simply could not have told us.

Fixed: `-a` on both greps; the body extracted into `_qsd_launcher_log_verdict()`
**defined above the `--self-test` dispatch** (as an inline block it was the only
check in the file with no callable seam, which is exactly why the bug survived
every self-test ever run); a `QSD_FIXTURE_LAUNCHER_LOG` seam matching the 15
siblings; two NUL-containing fixtures.

**The trap inside the fix.** Reverting the `-a` to poison-test it showed the
compliant fixture go RED (60/1) — but **the poisoned fixture still PASSED**.
Without `-a` it returns 1 for the wrong reason (no-startup-line, never reaching
the crash branch), and a test asserting only `rc != 0` cannot tell the two
apart. The poison alone would have shipped this bug a second time. Recorded at
the site so nobody deletes the compliant half as redundant.

## Task 2 — an unregistered layer-shell frame

`modules/screensaver/ScreensaverSurface.qml` (added by `1d6fa3b2`) declares
`WlrLayershell.namespace: "quickshell-screensaver"` and appeared in neither
`QSD_BAR_SURFACE_ROWS` nor `QSD_KNOWN_NONBAR_FRAMES` — precisely the debt the
reverse-closure half exists to make unshippable. Enumerated all 17 declaring
files against the 11 rows + 6 known frames; it was the only one unaccounted for.

Registered rather than waved through `QSD_KNOWN_NONBAR_FRAMES` (that set is for
frames predating the registry; this postdates it). Every field verified against
the file — notably `noreserve` on `exclusiveZone: -1`, which
`_qsd_zone_is_noreserve` accepts alongside `0`; the `-1` is what lets the saver
cover the bar and is not a typo.

**Adding the row broke the compliant fixture tree** (`missing=1`) — a row
requires its file to exist there. Re-poisoned in the same commit, as the
fixing-a-gate-breaks-its-fixture rule requires. The new stand-in is now the only
fixture exercising `_qsd_zone_is_noreserve`'s `-1` branch.

## Task 3 — routed, not exempted

`UpdatesPopout.qml` held 7 direct `Colours.*` references. Its nine sibling
popouts are exempt, but that exemption is phase 18.1's **scope fence**, and this
file postdates it (`45401821`) — so the rationale never covered it. `WINDOWS.md`
row 57 is still open and says the exemption should **shrink, not grow**, so a
tenth entry would have widened a blind spot the ledger wants narrowed.

Six of seven mapped to existing roles (`warn`, `outlineColour`, `accent`,
`onAccent`, `capsuleFg`). Added exactly one — `BarRoles.popoutFg` — kept separate
from the value-identical `notifSurfaceFg`, which is notification-scoped by name
and would tie popout text to future notification changes. Same value today,
different reason to change tomorrow. `QSD_BAR_COLOUR_ROLE_EXEMPT` is untouched
at 10 entries.

Every mapping is value-identical, so the card's appearance did not change.

**A stale header corrected.** The file claimed to live in `packages/` and that
`modules/bar/` has no qmldir. Both false: one copy exists, here, declared at
`modules/bar/qmldir:131`, and that qmldir also carries the `singleton BarRoles`
line this change now depends on. The real cause of the original "is not a type"
failure was an undeclared type — exactly what 260828-75k's own SUMMARY records.
The trap is kept; the diagnosis is corrected.

**Import resolution proven, not assumed.** No lint can see a QML import error.
`SystemCapsule.qml` — same directory, identical import block, the very file that
instantiates this popout — already resolves `BarRoles` five times.

> **CORRECTION, 2026-08-28 (quick task 260828-t22).** This section originally
> added: "Then verified on the live reload *by line position*: last
> `Configuration Loaded` at line 7199 of 7209, with 0 errors after it." **That
> was not evidence for this change.** Measured afterwards: quickshell watches
> only files it has actually LOADED — a comment touch on the loaded
> `SystemCapsule.qml` produces a reload, the same touch on the lazily-loaded
> `UpdatesPopout.qml` produces zero log lines. That file has never been loaded
> this session, so the reload never exercised it; the `Configuration Loaded`
> lines cited came from other activity. The static gates were real and stand.
> The runtime claim did not, and is withdrawn.
>
> The gap it exposed is now closed by `singleton-prop-check` (260828-t22),
> which resolves every `BarRoles.<member>` reference statically and therefore
> *does* cover lazily-loaded surfaces. Re-run against this file: clean.

## Not done / out of scope

- The other nine popouts stay exempt; **WINDOWS.md row 57 remains open.** This
  task supplies the first anchor role for that migration, not the migration.
- Pre-existing and untouched: `SelectRow.qml:100` logs
  `Unable to assign [undefined] to QQuickTapHandler::GesturePolicy` repeatedly,
  and `NotifCentre.qml:1092` cannot open
  `~/.local/state/quickshell/notif-centre-picture.png`. Both predate this task
  and neither is a load error. Worth a look, separately.
- `--with-compositor-reload` was never run and its half remains unproven here.
