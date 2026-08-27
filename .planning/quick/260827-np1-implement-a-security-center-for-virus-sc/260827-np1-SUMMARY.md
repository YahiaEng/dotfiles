---
quick_id: 260827-np1
slug: implement-a-security-center-for-virus-sc
date: 2026-08-27
status: complete
commits:
  - 8dc0693d  # root-side foundation
  - 92943ca6  # backend singleton, severity ramp, settings page S1+S2
  - 7ea695a2  # dashboard tab D1, bar capsule H1
artifact: https://claude.ai/code/artifact/ce5483c7-7f64-454d-8262-e7d99a330ba2
---

# Security Center — shipped, all four plates

Study first, operator picked, then built — the same shape 260826-rfy and
260827-b52 used. Four surfaces, one backend.

## What the operator decided

| # | Question | Answer | How it landed |
|---|---|---|---|
| 1 | Which plate | **All four** | S1+S2 behind a settings picker, D1 and H1 behind their own toggles |
| 2 | Which scanners | **"Whichever is more secure"** | Full set — clamav, arch-audit, rkhunter, lynis — all in `extra`, all default-on, all in `VERIFY_PKGS` |
| 3 | SMART privilege | **smartd.service** | Root timer writes a world-readable JSON snapshot; the shell never runs a privileged read |
| 4 | Act or report | **Act and report** | Real buttons through one pkexec allowlist helper, armed two-step |

## The five measurements that shaped it

1. **Nothing was installed.** clamav/arch-audit/rkhunter/lynis all absent,
   all in official `extra`. So "absent" is a first-class state with an
   install affordance, not an error — on a fresh box every scanner tile
   starts that way.
2. **A real scan outlives its page.** `UpdatesPage.qml`'s own header
   states the rule: `Pages.qml:_swapTo` destroys a page on navigate-away,
   capping any page-scoped `Process`. Every existing probe is sub-second;
   a clamscan is minutes. This is why `SecurityBackend` is a **singleton**
   and why the capsule exists at all.
3. **No firewall was running**, and the stock ruleset would have broken
   Docker — `chain forward { policy drop }` shares a hook and priority
   with Docker's own `ip filter FORWARD`, and docker was active with four
   networks including two k3d clusters.
4. **SMART needs root, sensors do not**, and the user is in `wheel` with
   journal access — so device health needs zero runtime privilege.
5. **No severity ramp exists.** 19 roles, one `error`, no warning/success.
   Derived in `Severity.qml` from roles that exist, never literals.

## Four bugs my own checks caught before shipping

- **`nft -c` needs root even to validate** — so `security-action` gained a
  `firewall-check` verb that runs under pkexec, and `firewall-enable`
  validates before loading. A syntax error under `policy drop` is how a
  machine loses its network.
- **A false-pass in my own probe.** `awk` extracted 0 lines of the
  snapshot parser and `py_compile` happily compiled the empty file. Only
  the `wc -l` positive control caught it.
- **`compSlugs` is a THIRD parallel array.** My hand-rolled index check
  compared slugs to `comps` and reported "LENGTHS MATCH"; the gate's
  CHECK E saw the array I had not looked at.
- **`Prefs` has no change signal.** `getValue()` reads `_data`, which
  `setValue()` reassigns wholesale — so a *binding* is reactive but the
  `Connections { function onValuesChanged() }` I first wrote would have
  silently never fired.

## The finding worth carrying forward

**`top` is a FINAL property on `Item`, and every gate is blind to it.**
`SecurityTab.qml` declared `readonly property var top:` on a Repeater
delegate. That took the WHOLE shell down — `Failed to load configuration
… Cannot override FINAL property` — while colour-lint (521/0), motion-lint
(706/0), qml-import-check (0 unresolved) and settings-index-check (191/0)
all reported green. **Only the hot-reload line in `~/.cache/quickshell.log`
saw it, and it needed no restart to report it.** Third recorded instance
of "the gates cannot see a QML load error."

## Gates

| Gate | Result |
|---|---|
| colour-lint | 521 passed / 0 failed — ramp passes structurally, no exemption entry |
| motion-lint | 706 / 0 — two raw loop durations rebound to `Motion.ambientDuration` |
| qml-import-check | 0 unresolved across 175 files — caught a missing `import Quickshell` |
| settings-index-check | 191 / 0 — caught the `compSlugs` omission |
| stow-link-check | 2 / 0 |
| live shell | `Configuration Loaded` |

Positive control run on colour-lint and motion-lint: 15 checks each name a
`modules/security/` file, so the pass is not a skipped directory.

## NOT verified by me — needs the operator

1. **`install.sh` has not been run.** No package installed, no unit
   enabled, no ruleset placed. Until then the pane correctly shows four
   absent scanners and an empty device list (the one expected warning in
   the log: `smart.json` does not exist).
2. **No surface was rendered.** The shell loads, but the settings page,
   both layouts, the dashboard tab and the capsule have not been looked
   at. There is no input-injection path from an agent shell here.
3. **No privileged action was fired.** Nothing enabled the firewall or
   installed anything — every one of those needs a real polkit prompt.
4. **`quickshell-doctor` not run** — it restarts the shell from inside,
   which is forbidden from an agent shell.
