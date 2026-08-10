# Phase 11: Quickshell Viability Gate - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-26
**Phase:** 11-Quickshell Viability Gate
**Areas discussed:** Probe surface fate, Stop-authority policy, keybind-doctor repair, QML layout + config state

---

## Probe Surface Fate

### Q1 — What lives in `quickshell/` once the gate passes?

| Option | Description | Selected |
|--------|-------------|----------|
| Probe graduates to seed shell | Gate surface becomes the permanent shell root that autostarts; interactive test bits stay behind a keybind/CLI as a rerunnable gate | ✓ |
| Throwaway deleted, empty scaffold ships | Cleanest "gate is a gate" reading, but QS-05's coexistence proof has almost nothing to run against | |
| Probe kept as a hidden diagnostic-only surface | Keeps daemon count unchanged, but QS-05's autostart requirement then needs something else built this phase | |

**Notes:** Rerunnable-gate framing matches theme-doctor / theme-parity / keybind-doctor / waybar-equivalence-check precedent. Phase 14's drawer mounts into an already-proven root.

### Q2 — What does the always-on seed shell render in daily use?

| Option | Description | Selected |
|--------|-------------|----------|
| Nothing visible — headless root | No visible surface; probe summoned on keybind only. Zero exclusive zone by construction | ✓ |
| Small always-visible liveness indicator | Answers "is it running?" at a glance, but a themed widget with no user value for months | |
| Test panel stays visible but idle | Max daily mileage on pointer/focus behavior, but permanent scaffolding on the desktop | |

**Notes:** Option 3 rejected explicitly against Phase 17's named "additive scaffolding drift" failure mode.

### Q3 — Where does the dated pass/fail record and mechanical check machinery live?

| Option | Description | Selected |
|--------|-------------|----------|
| New `quickshell-doctor` script | Rerunnable gate alongside the existing five; mechanical assertions + human probe summon + dated PASS/FAIL append | ✓ |
| Extend `theme-doctor` | One entrypoint, already wired in — but conflates the colour/CSS contract with layer-shell/D-Bus/keybind coexistence | |
| One-shot phase evidence artifact only | Least code for a decision gate — but claims rot silently as Phases 14-16 add surfaces | |

### Q4 — Autostart handling for an invisible root

| Option | Description | Selected |
|--------|-------------|----------|
| Thin guarded launcher script | `quickshell-launch.sh` mirroring `waybar-launch.sh`: binary/config guard, `uwsm app --`, logs to `~/.cache` | ✓ |
| Plain `exec-once`, uniform with other daemons | Zero new files, perfectly uniform — but a failed headless root is fully symptomless | |
| `exec-once` plus a systemd user unit | Restart-on-failure and journalctl for free — but the only daemon supervised that way, breaking the consolidated pattern | |

### Q5 — Proving QS-03 multi-monitor on a single-monitor host

**Scouted mid-discussion:** only `DP-1` connected (Acer ED273U, 2560×1440@165).

| Option | Description | Selected |
|--------|-------------|----------|
| Hyprland headless output | `hyprctl output create headless` — real event path, repeatable, scriptable, no hardware | ✓ |
| Real second display for the gate | Genuine EDID/hotplug, but one-shot, unrepeatable, hardware-dependent | |
| Both — headless plus one real display | Two-tier belt-and-suspenders like the INST-03 container+VM gate | |

**Notes:** Caveat to record — proves event handling, not real EDID negotiation.

### Q6 — What the probe panel carries

| Option | Description | Selected |
|--------|-------------|----------|
| One panel with all instrumentation | Button, text field, JSON-bound label, screen name — one summon exercises every criterion | ✓ |
| Separate minimal probes per concern | Unconfounded failure attribution, but three files and three summons to maintain | |
| Minimal button + field only | Smallest QML footprint, but the FileView open question is the one most worth watching happen | |

### Q7 — Decision rule if `FileView`/`JsonAdapter` needs reload involvement (open question #1)

| Option | Description | Selected |
|--------|-------------|----------|
| Fall back to a theme-engine fan-out hook | Record it, add a reload step — exactly what swaync, waybar, walker and AGS already need. Not a stopper | ✓ |
| Treat as a Phase 11 FAIL | Maximally strict — but stops v3.0 over a property no other surface has either | |
| Investigate a QML-side workaround first | Preserves the zero-reload ideal — but risks the open-ended debugging shape eww warns against | |

### Q8 — Staging suspend/resume survival

| Option | Description | Selected |
|--------|-------------|----------|
| Manual suspend/resume during the gate, recorded | Hand-driven cycle, probe before and after, dated line in the evidence artifact | ✓ |
| `quickshell-doctor` asserts post-resume health only | Fully rerunnable — but nothing forces a run after an actual resume | |
| Both | One-time proof plus ongoing regression coverage | |

---

## Stop-Authority Policy

### Q1 — What a failed gate does to v3.0

| Option | Description | Selected |
|--------|-------------|----------|
| Milestone stops; v3.0 rescoped to GTK4/AGS | Phases 12-13 have standalone value on the six existing GTK surfaces; drop 14-17; un-reverse the PROJECT.md Out of Scope entry | ✓ |
| Hard stop — v3.0 ends entirely | Cleanest signal — but throws away Phases 12-13, which don't depend on Quickshell at all | |
| Timeboxed investigation, then decide | Fair shot at a fixable config problem — but that's how the eww episode consumed a whole feature build | |

### Q2 — Which failures carry stop authority

| Option | Description | Selected |
|--------|-------------|----------|
| Only QS-02 stops | Pointer/keyboard/dismiss is the one thing no config works around; everything else is record-and-continue | ✓ |
| QS-02 plus unresolvable QS-05/QS-06 coexistence | Protects the "retires nothing" guarantee — but coexistence problems are almost always fixable | |
| All six QS requirements are stop-triggers | Max rigor — but brittle, since multi-monitor is proven with a *virtual* output | |

### Q3 — When stow/install registration lands (rule collision)

| Option | Description | Selected |
|--------|-------------|----------|
| Register immediately; revert as one unit on failure | Same-commit rule stays whole; contiguous commit set with no dependants is clean to revert | ✓ |
| Gate first, then register in one follow-up commit | Nothing abandoned reaches the install path — but reproduces the exact host-only unregistered state the rule forbids | |
| Register behind an off-by-default `install.sh` flag | Satisfies both rules literally — but a dead flag encoding a temporary phase state is its own drift | |

**Notes:** The rule exists because "we'll register it later" is what left `ags/` host-only. A conditional version is a rule with a hole in it.

### Q4 — Screencopy probe depth

| Option | Description | Selected |
|--------|-------------|----------|
| Feasibility only — does it render, and what's the permission stanza | One live multi-window capture + verbatim `PERMISSION_TYPE_SCREENCOPY` / `ecosystem.conf` record; budget stays with OVER-04 | ✓ |
| Feasibility plus a rough cost sample | Gives Phase 16 a ballpark — but duplicates OVER-04 and a crude number risks being treated as authoritative | |
| Feasibility, cost, and a fallback decision now | Phase 16 becomes near-pure implementation — but decides the fallback without the real grid to judge against | |

---

## keybind-doctor Repair (MAINT-01)

**Root-caused during discussion.** Hyprland 0.56.0's `hyprctl binds -j` is *field-misaligned*, not merely malformed: `"modmask": false` (should be `64`), `"submap": "64"` (holds modmask's value), `"keycode": Return` (unquoted), `"allow_input_capture": ,` (empty). Values are shifted relative to keys, so a syntax-only repair would produce semantically wrong data that appears to work. Plain-text `hyprctl binds` verified correct on this build across all 78 binds.

### Q1 — How to repair

| Option | Description | Selected |
|--------|-------------|----------|
| Parse plain-text `hyprctl binds`; drop `-j` | Verified correct on this build; honors the criterion's intent over its letter; guard + recorded rationale so nobody "restores" `-j` | ✓ |
| Realign the shifted `-j` fields | Keeps literal criterion wording — but hard-codes one upstream bug's exact shape and breaks silently when it's fixed | |
| Text now, with a `-j` probe that auto-switches back | Self-healing across a future Hyprland fix — but two parsers and a correctness probe for a payoff on an unknown date | |

**Notes:** Requires amending the ROADMAP criterion, which literally says "parses `hyprctl binds -j`".

### Q2 — How keybind-doctor learns what Quickshell claimed

| Option | Description | Selected |
|--------|-------------|----------|
| Query the live registration at runtime | Same discipline the script already enforces for Hyprland; catches a shortcut that *failed* to register | ✓ |
| Grep the QML source for `GlobalShortcut` | Simple, headless-friendly — but exactly the file-only check the script's own header rejects | |
| A declared manifest both sides read | Unambiguous and gives Phases 14/16 one place to declare — but a third source of truth that can drift | |

### Q3 — Fallback if 0.3.0 exposes no runtime query

| Option | Description | Selected |
|--------|-------------|----------|
| Declared manifest, with the gap recorded | Same shape as the FileView fallback: record the limitation, take the workable path | ✓ |
| Source-grep the QML | No file to keep in sync — but renames and conditional registration slip past | |
| Skip Quickshell-side detection this phase | Nothing speculative — but defeats the entire reason MAINT-01 sits in Phase 11 | |

### Q4 — Proving the repaired detection

| Option | Description | Selected |
|--------|-------------|----------|
| Poisoned fixture with a deliberate duplicate | Proven-to-fail, not observed-to-pass; the path argument for it already exists | ✓ |
| Rely on the real-config run alone | Zero fixture to maintain — but a parser matching nothing also reports zero duplicates | |
| Poisoned fixture plus a parse-count assertion | Catches both failure modes — but the count needs updating whenever binds change | |

---

## QML Layout + Config State

### Q1 — Package layout

| Option | Description | Selected |
|--------|-------------|----------|
| Minimal root now, structure earned per phase | `shell.qml` + one `modules/`; Phases 12-16 add directories as they add surfaces | ✓ |
| Seed an end-4 / Caelestia-style layout now | Obvious slots for later phases — but empty scaffolding on an unproven toolkit | |
| Mirror this repo's own conventions | Lowest cognitive overhead — but fights strong QML/Quickshell community conventions | |

### Q2 — Where the FileView/JsonAdapter file lives

| Option | Description | Selected |
|--------|-------------|----------|
| `~/.local/state/quickshell/` — its own state dir | Preserves the theme-state vs. shell-state split; out of git, so hand-edits never dirty the tree | ✓ |
| `~/.local/state/theme/` alongside the palette | One state dir for everything — but conflates render targets with shell-owned state; confuses `contract.json` parity | |
| `~/.config/quickshell/` inside the stow package | Simplest mental model — but hand-editing dirties `git status`, breaking the v1.0 invariant | |

### Q3 — Layer-shell convention for Phases 14-16

| Option | Description | Selected |
|--------|-------------|----------|
| Overlay layer, zero exclusive zone, `quickshell-*` namespace | The convention Phase 14 already names as inherited; becomes a standing `quickshell-doctor` check | ✓ |
| `top` layer instead of overlay | Politer to swaync/SwayOSD — but Phase 14's drawer and Phase 16's overview both need to sit above content | |
| Decide per surface, prove only zero exclusive zone here | Max flexibility — but spreads collision risk across four phases instead of settling it once | |

### Q4 — Probe styling before Phase 12's tokens exist

| Option | Description | Selected |
|--------|-------------|----------|
| Deliberately unstyled — QtQuick defaults only | The gate judges input, not looks; hex literals are what Phase 12's gate will fail on | ✓ |
| Read the palette from `~/.local/state/theme/` now | Head start on the colour half — but Phase 12 owns the QML render-target format | |
| A few hardcoded colours, removed in Phase 12 | Pragmatic for a throwaway — but "temporary hex literals" is precisely the target of Phase 12's gate | |

**Notes:** "The probe never being pretty is a feature — it can't be mistaken for a shipped surface."

---

## Claude's Discretion

- Exact QML file/module naming inside `shell.qml` + `modules/`
- Which keybind summons the probe (must not collide with the existing 78; `keybind-doctor` proves it)
- The evidence artifact's filename and internal format, following the `08-BAR-02-EVIDENCE.md` precedent
- Log path and rotation for `quickshell-launch.sh` under `~/.cache`
- Whether `quickshell-doctor` lives in `hypr/.config/hypr/scripts/` or in the new `quickshell/` package

## Deferred Ideas

- Real second-display hotplug with genuine EDID negotiation — if hardware becomes available mid-milestone
- Frame/CPU budget for live multi-window screencopy — Phase 16's OVER-04, deliberately not pulled forward
- QML palette render target and motion tokens — Phase 12 owns the schema and the `contract.json` entry
- A `-j` auto-switch-back probe in `keybind-doctor` — revisit if a future Hyprland release fixes the serializer
- Reorganizing `quickshell/` into an end-4/Caelestia-style tree — Phase 14 is the natural revisit point
- Any visible Quickshell surface — Phase 14's dashboard drawer is the first
