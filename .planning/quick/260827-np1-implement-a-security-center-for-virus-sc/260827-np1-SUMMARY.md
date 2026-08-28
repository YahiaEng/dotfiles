---
quick_id: 260827-np1
slug: implement-a-security-center-for-virus-sc
date: 2026-08-27
status: complete
commits:
  - 8dc0693d  # root-side foundation
  - 92943ca6  # backend singleton, severity ramp, settings page S1+S2
  - 7ea695a2  # dashboard tab D1, bar capsule H1
  - 244196ca  # docs
  - dd8fd318  # r1: constant-size capsule, octopi conflict
  - 071bc42d  # r2: capsule beside the bell, flat tint
  - 192da2ca  # r2: !debug for AUR builds (tela "hang")
  - aa800ef1  # r3: error surfacing, one layout, sudo keepalive, SMART SATA
  - 8af9df97  # r5: stable section order
  - 45496386  # r5: collapse unfixable CVEs, rank actionable first
  - 777b63e2  # r6: folder picker for the scan target
artifact: https://claude.ai/code/artifact/ce5483c7-7f64-454d-8262-e7d99a330ba2
operator_status: ALL CONFIRMED — task closed 2026-08-28
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

## NOT verified by me — needs the operator  (ALL FOUR CLOSED, see rounds below)

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

> **Resolved 2026-08-28.** install.sh ran and placed everything (helper,
> polkit action, ruleset, units, snapshot); all four surfaces were rendered
> and operator-confirmed; the firewall was enabled through a real polkit
> prompt. `quickshell-doctor` remains unrun — still an operator-only tool.
> Item 1 is kept verbatim as the point-in-time record of the build phase.


---

# Operator rounds 1-6 (2026-08-27 → 08-28)

The build above shipped; everything below came from the operator using it.
**All confirmed; task closed.**

## What the six rounds actually taught

**Four of my defects made WORKING things look broken.** That is the pattern
worth carrying, not the individual bugs:

| Reported | Real cause |
|---|---|
| "Enable does nothing, button resets" | It worked. `pkexec` exit **127** (missing helper) was treated as "user cancelled", and nothing displayed `actionError` at all |
| "Firewall still shows off after enabling" | It was on. `nftables.service` is `Type=oneshot` with no `RemainAfterExit`, so `systemctl is-active` reports `inactive` forever |
| "Scan is hanging" | It was scanning. With `-i`, clamscan prints NOTHING until the summary, so the counter sat at 0; plus ~6.7s of silent signature loading first |
| "Weird dashboard icons" | Not my code at all. `ttf-material-symbols-variable-git` upgraded at 03:50:41; quickshell started 03:34:38 and `/proc/1440/maps` still showed the font `(deleted)` |

In every case the mechanism was found by **measuring, not reasoning** —
`journalctl`, `/proc/<pid>/maps`, `systemctl show`, a real `pkexec` exit code.

## Round-by-round

- **r1** — Bar capsule shifted the whole bar. Measured by A/B grim capture:
  centre landmarks moved exactly 23px = `(30 + 16)/2`, because endZone is
  bottom-anchored and centerZone is centred *in the gap*. Also found that
  collapsing to zero never removed the footprint anyway — a zero-height Grid
  child still consumes `spacing`. Fixed to a constant-size chip.
  Separately: `octopi` → `octopi-git` (conflicted with the installed
  `alpm_octopi_utils-git`, aborting install.sh before section_security).
- **r2** — Capsule was mispositioned and "too glowy". The notification pill is
  an ENTRY on `clockActions`, not a capsule, so security became an `ActionCell`
  beside the bell. Colour switched from a Material wash+rim to the bar's own
  flat `BarRoles` tint. `filled` was tried, screenshotted, and rejected: a
  security finding can stand for weeks, and a permanently solid glyph among
  four outline ones is what "out of place" meant.
  Also: AUR builds now run `!debug` — Arch ships `debug` in OPTIONS, so makepkg
  was copying 1.3 GB of icon-theme sources into `/usr/src/debug/` for a package
  with no binaries, which read as a hang.
- **r3** — pkexec 126/127 split + an error banner + helper pre-flight; the two
  layouts merged into one `SecurityOverview`; duplicate bar toggle removed;
  sudo keepalive (47 sudo calls, 5-min timeout, 20+ min build between them).
- **r4** — Focus grab released for EXTERNAL dialogs (the polkit prompt was
  measured as already floating — it was the exclusive grab, not a windowrule);
  oneshot-aware firewall probe; progress bar rewritten to derive x from live
  width; `Scan target` made interactive; clamscan `-v` for live progress.
- **r5** — Section order made FIXED after ordering-by-severity relocated whole
  sections on a state change. Unfixable CVEs collapsed behind one disclosure
  row; fixable ones ranked first at equal severity.
- **r6** — `FilePicker` gained a generic `selectDirectories` mode rather than a
  second picker being written; scan target became a real path.

## Facts about this host, established here

- All 17 affected packages report `status: "Vulnerable"` with `fixed: None`, and
  `arch-audit -u` returns nothing — nothing is fixable today. `AVG-2701` flags
  `linux-lts` with 21 CVEs from **2022** while the installed 6.18.47-1 is
  current: stale tracker bookkeeping, not a live exposure.
- The firewall is enabled and loaded; every listener is on loopback.
- All three drives healthy: `sda` 20705h/45°C, `nvme0` 3960h/53°C,
  `nvme1` 11538h/54°C. The SATA drive needed `smartctl` auto-detection —
  `--scan` reports it as `-d scsi`, which returned no verdict at all.

## Memory written

- [[probe-the-right-signal-for-privileged-actions]] — new
- [[second-toplevel-needs-the-focus-grab]] — extended with the external-process
  (polkit) case
- [[qml-configured-after-construction]] — extended with the animation
  `from`/`to` variant
- [[qml-syntax-tools-are-blind-here]] — extended with `top` being FINAL on `Item`
