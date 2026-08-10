# Phase 11: Quickshell Viability Gate - Context

**Gathered:** 2026-07-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Prove Quickshell works on *this* machine — pointer, keyboard, focus, click-outside dismiss, multi-monitor, hot reload, suspend/resume — register it reproducibly through `install.sh` + `stow.sh`, prove it coexists peacefully with the six live GTK surfaces, repair `keybind-doctor` as the instrument for the bind-collision proof, and answer the screencopy feasibility question for Phase 16.

**This phase is a verdict, not an architecture.** It carries authority to stop the milestone. Nothing user-facing ships from it; the only thing that survives into daily use is a headless, invisible shell root and a rerunnable gate script.

Requirements: QS-01, QS-02, QS-03, QS-04, QS-05, QS-06, MAINT-01.

</domain>

<decisions>
## Implementation Decisions

### Probe Surface & What Ships

- **D-01:** The gate probe **graduates into the permanent shell root** rather than being deleted. `quickshell/` ships a minimal always-on Quickshell instance that autostarts; the interactive test bits stay behind a keybind/CLI as a **rerunnable** gate, matching how `theme-doctor`, `theme-parity`, `keybind-doctor`, `waybar-equivalence-check` and `waybar-design-lint` already work in this repo. Rationale: QS-05 requires a real client to prove coexistence against, and Phase 14's drawer then mounts into a root that has been running for weeks. — **Reversibility:** reversible — one QML file and one autostart line.

- **D-02:** The always-on root is **headless — it renders nothing in daily use.** No visible surface, no liveness widget, no idle test panel. The probe `PanelWindow` is summoned on a keybind only when re-running the proof. Zero pixels competing with waybar, zero exclusive zone and zero layout-shift risk by construction. Explicitly rejected: a small always-visible indicator (a thing to keep themed through Phases 12-13 for no user value) and leaving the test panel on screen (the "additive scaffolding drift" failure Phase 17 already names).

- **D-03:** The probe is **one panel carrying all instrumentation** — a click-counter button, a focusable text field, a label bound through `FileView`/`JsonAdapter` to a hand-editable JSON file, and the screen name it is rendering on. One summon exercises every criterion at once; one file for the gate script to launch.

- **D-04:** The probe is **deliberately unstyled — QtQuick defaults only, no colours authored at all.** The gate judges input/focus/dismiss, not looks. Hex literals in repo-authored QML are precisely what Phase 12's criterion 1 forbids and what its `theme-doctor` motion/colour gate will be built to fail on, so writing any now creates something to rip out. Explicitly rejected: reading the palette from `~/.local/state/theme/` now (Phase 12 owns choosing the QML render-target format; guessing it here means matching by luck or rewriting). The probe never being pretty is a feature — it cannot be mistaken for a shipped surface.

### Gate Machinery & Evidence

- **D-05:** A **new `quickshell-doctor` script** is the home for both the mechanical coexistence assertions and the dated pass/fail record. It sits alongside the existing gate scripts, runs the mechanical checks automatically (`hyprctl layers -j` no second non-zero exclusive-zone claimant, `busctl --user list` exactly one `org.freedesktop.Notifications` owner, one-step-per-press volume/brightness, `keybind-doctor` clean, shell process alive), summons the probe for the human pointer/keyboard/dismiss checks, and appends a dated PASS/FAIL line to an evidence artifact. Explicitly rejected: folding into `theme-doctor` (different remit — colour/CSS contract vs. layer-shell/D-Bus/keybind coexistence) and a one-shot manual record (the coexistence claims would silently rot as Phases 14-16 add surfaces and keybinds).

- **D-06:** Autostart goes through a **thin guarded launcher script, `quickshell-launch.sh`**, mirroring the existing `waybar-launch.sh`: verifies the binary and config exist, launches under `uwsm app --`, logs startup/exit to `~/.cache` so a silent death leaves a trace. `quickshell-doctor` asserts the process is alive as part of its run. Rationale: a headless root that renders nothing is also invisible when it fails to start or dies. Explicitly rejected: a plain `exec-once` (uniform with the other 11 daemons but symptomless on failure) and a systemd user unit (would be the only daemon in the repo supervised that way, breaking the consolidated `autostart.conf` pattern).

- **D-07:** **Multi-monitor (QS-03) is proven with a Hyprland headless output** — `hyprctl output create headless` adds and removes a virtual monitor on demand, exercising the real Hyprland monitor-add/remove event path and Quickshell's per-screen surface creation. Repeatable, scriptable inside `quickshell-doctor`, works on a fresh install with no hardware. **Caveat that MUST be recorded in the evidence artifact:** this proves the event handling, not real DP/HDMI EDID negotiation. Context: this host currently has exactly one physical monitor (`DP-1`, Acer ED273U, 2560×1440@165).

- **D-08:** **Suspend/resume is a manual, hand-driven gate item** — one `systemctl suspend` + wake during the phase, probe summoned before and after, result written as a dated line in the evidence artifact. It genuinely cannot be scripted into a rerunnable doctor without killing the session, so it belongs with the human gate items rather than the mechanical ones.

### Stop Authority

- **D-09:** **On gate failure, the milestone stops and v3.0 is rescoped to GTK4/AGS** — not a hard total stop. A pointer-input failure is the eww failure class in QML clothing. Phase 12's token pipeline and Phase 13's motion retrofit have real standalone value on the existing six GTK surfaces, so v3.0 rescopes to those two and drops Phases 14-17. The Quickshell reversal recorded in `PROJECT.md` Out of Scope gets reversed *back*, with the evidence artifact as the stated reason. — **Reversibility:** one-way — a STOP verdict rewrites ROADMAP.md, REQUIREMENTS.md and PROJECT.md's Out of Scope reversal; undoing it means re-scoping the milestone from the top.

- **D-10:** **QS-02 is the sole stop-trigger.** Pointer / keyboard / click-outside dismiss is the one thing no config can work around. Everything else is record-and-continue:
  - a hot-reload gap → gets a `theme-apply` fan-out hook (see D-13)
  - an exclusive-zone or D-Bus collision → gets a config fix
  - a screencopy failure → rescopes Phase 16 only, nothing else
  - a headless-output quirk → a test-harness artifact, not a defect
  Rationale: keeping the gate's authority sharp rather than diffuse. Explicitly rejected: adding unresolvable QS-05/QS-06 coexistence as a second trigger (coexistence problems are almost always config-fixable) and treating all six QS requirements as triggers (brittle — multi-monitor is being proven with a *virtual* output).

- **D-11:** **Registration lands immediately, and a failed gate reverts the whole commit set as one unit.** The same-commit stow-registration rule stays intact: `quickshell/`, `stow.sh` and `install.sh` land together in the first commit, *before* the human clicks. If the gate fails, that contiguous commit set is reverted wholesale — clean, because nothing depends on it yet. Rationale: the rule exists precisely because "we'll register it later" is what left `ags/` host-only, and a conditional version of it is a rule with a hole in it. Explicitly rejected: gating registration behind an `install.sh` flag (a dead flag encoding a temporary phase state is its own drift).

- **D-12:** **The screencopy probe is feasibility-only.** Exercise one live multi-window `ScreencopyView` capture, confirm real content rather than blank tiles, and record the exact `PERMISSION_TYPE_SCREENCOPY` mechanics and `ecosystem.conf` stanza **verbatim**. The frame/CPU budget stays with OVER-04 in Phase 16 as the roadmap assigns it — do not pull that measurement forward, and do not pre-commit to Phase 16's fallback here.

- **D-13:** **If `FileView`/`JsonAdapter` propagation turns out to need reload involvement (roadmap open question #1), that is NOT a stop.** Record the finding honestly, then add a quickshell reload step to `theme-apply`'s existing single reload fan-out — exactly what swaync (`swaync-client -rs`), waybar (`SIGUSR2`), walker and AGS already require. Needing an explicit reload puts Quickshell on par with every surface this repo already ships. Explicitly rejected: treating it as a Phase 11 FAIL (stopping v3.0 over a property no other surface has either) and open-ended QML workaround hunting (the shape of the eww episode this phase exists to prevent).

### keybind-doctor Repair (MAINT-01)

- **D-14:** **Parse the plain-text `hyprctl binds` output; drop `-j` entirely.** Root cause established during discussion: Hyprland 0.56.0's JSON serializer is **field-misaligned**, not merely malformed — values are shifted relative to keys (`"modmask": false` where it should be `64`, `"submap": "64"` holding modmask's value, `"keycode": Return` unquoted, `"allow_input_capture": ,` empty). So a syntax-only repair would yield semantically **wrong** data while appearing to work. The plain-text output was verified correct on this exact build: `modmask: 64`, `key: Return`, `dispatcher: exec`, `arg: …` across all 78 binds. Add a guard that fails loudly if the text format itself ever changes shape, and record in the evidence artifact **why** `-j` was abandoned so a future reader does not "restore" it. — **Reversibility:** reversible, but see D-15 — requires amending the ROADMAP success-criterion wording.

- **D-15:** **The roadmap's Phase 11 success criterion 4 must be amended** — it currently reads "a repaired `keybind-doctor` parses `hyprctl binds -j` on 0.56.0". D-14 honors the criterion's *intent* (reliable duplicate-chord detection) over its *letter*. Planner should treat the ROADMAP wording update as in-scope work for this phase, not a deviation.

- **D-16:** **Quickshell-claimed shortcuts are discovered by querying the live registration at runtime**, not by reading source. Quickshell registers `GlobalShortcut` through the XDG desktop portal / compositor, so ask the running system what is actually claimed. This is the same discipline `keybind-doctor` already enforces for Hyprland — its own header states it cross-checks the compositor's actual registered state, never the file alone — and it catches a shortcut that *failed* to register, which source-parsing never would. **The exact query mechanism must be verified against the installed quickshell 0.3.0** (standing constraint 2), not assumed.

- **D-17:** **Fallback if quickshell 0.3.0 exposes no runtime query: a declared manifest, with the gap recorded.** `quickshell/` ships an explicit list of the chords it owns; `keybind-doctor` cross-checks it against Hyprland's registered set, and the evidence artifact records that runtime introspection was unavailable on 0.3.0 and why. Same shape as D-13 — record the limitation, take the workable path, do not stop over it. Gives Phases 14 and 16 one obvious place to declare a new keybind. Explicitly rejected: source-grepping the QML (a rename or conditional registration slips past, and it cannot distinguish "declared" from "acquired") and deferring Quickshell-side detection to Phase 14 (defeats the whole reason MAINT-01 was placed in Phase 11).

- **D-18:** **The repaired duplicate-chord detection is proven with a poisoned fixture** — feed `keybind-doctor` a throwaway `keybinds.conf` containing a chord that collides with a Quickshell-claimed one, confirm it **FAILS**, then confirm it passes on the real config. Proven-to-fail, not merely observed-to-pass. The script already accepts a path argument for exactly this ("a gate that cannot fail is not a gate" — its own header), and this matches `theme-doctor`'s poisoned-stylesheet precedent.

### QML Package Layout & State

- **D-19:** **Minimal root now; structure is earned per phase.** `shell.qml` root plus one `modules/` directory holding the probe. Phases 12-16 add directories as they add real surfaces. Rationale: this phase is a viability gate whose job is a verdict, not an architecture — and seeding an empty end-4/Caelestia-style `modules/ services/ widgets/ config/` tree on an unproven toolkit is the abandoned-scaffolding cost Phase 17 already names. Accepted risk: Phase 14 may do a small reorganization, which is cheap while there is exactly one surface.

- **D-20:** **Shell state lives in `~/.local/state/quickshell/`** — its own state directory, separate from `~/.local/state/theme/`. This is the path the probe's `FileView`/`JsonAdapter` binds to and the pattern Phases 12-15 inherit for shell state. Rationale: preserves the existing clean split — `theme-engine` owns `~/.local/state/theme/` as a `contract.json` render target (Phase 12 will add a QML palette there), Quickshell owns its own runtime/user state. Out of git by construction, so the hand-edits criterion 2 explicitly requires never dirty the tree, preserving the git-clean invariant the stress test enforces. Explicitly rejected: `~/.local/state/theme/` (conflates generated theme output with shell-owned state; `contract.json` parity would start seeing non-render-target files) and `~/.config/quickshell/` inside the stow package (hand-editing would dirty `git status` on every test).

- **D-21:** **Layer-shell convention, established here and inherited by Phases 14-16: overlay layer, `exclusiveZone: 0`, distinct `quickshell-*` layer namespace** that no existing client uses. Phase 14 already names this as the convention it inherits, so establishing and proving it here is the point. The `hyprctl layers -j` assertion (no second non-zero exclusive-zone claimant on any edge) becomes a standing `quickshell-doctor` check rather than a one-time observation. Explicitly rejected: the `top` layer (politer to swaync/SwayOSD by default, but Phase 16's full-screen overview and Phase 14's drawer both need to sit above ordinary content, so it needs revisiting immediately) and deciding per surface (spreads collision risk across four phases instead of settling it once). — **Reversibility:** costly — four later phases build on this convention.

### Claude's Discretion

- Exact QML file/module naming within the minimal `shell.qml` + `modules/` structure (D-19).
- Which keybind summons the probe — must not collide with the existing 78 binds, and `keybind-doctor` proves it.
- The evidence artifact's exact filename and internal format, provided it carries dated PASS/FAIL lines per criterion. Precedent to follow: `08-BAR-02-EVIDENCE.md`.
- Log file path and rotation behavior for `quickshell-launch.sh` under `~/.cache`.
- Whether `quickshell-doctor` lives in `hypr/.config/hypr/scripts/` alongside `keybind-doctor` or in the new `quickshell/` package — pick whichever keeps the gate runnable on a machine where the gate has failed.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and standing rules
- `.planning/ROADMAP.md` §"Phase 11: Quickshell Viability Gate" — the five success criteria, the two open questions this phase owns, and what it Owns
- `.planning/ROADMAP.md` §"Standing constraints (apply to every v3.0 phase)" — all five apply here; constraints 1 (human render gate), 2 (verify against the installed binary), 3 (same-commit stow registration) and 4 (additive-only coexistence, incl. the named collision list) are directly load-bearing for this phase
- `.planning/REQUIREMENTS.md` §"Quickshell Foundation (QS)" (QS-01..QS-06) and §"Carried-In Maintenance" (MAINT-01), plus §Traceability
- `.planning/PROJECT.md` §"Key Decisions" — specifically the eww/AGS fail-fast gate precedent, the consumer-check-before-retiring entry (marked ⚠ Revisit), the same-commit stow registration entry, and the Quickshell adoption reversal (marked "Pending — v3.0 Phase 11 viability gate decides")
- `.planning/PROJECT.md` §"Out of Scope" — the reversed Quickshell entry that a STOP verdict would un-reverse

### Code this phase modifies or extends
- `hypr/.config/hypr/scripts/keybind-doctor` — MAINT-01 target. Read its header comment block: report-only, never mutates state, resolves `$mainMod` from the file rather than hardcoding SUPER, accepts a path argument for regression self-test
- `hypr/.config/hypr/config/autostart.conf` — where the `quickshell-launch.sh` `exec-once` line goes; note the uniform `uwsm app --` pattern across all 11 existing daemons and the ordering comments explaining placement
- `hypr/.config/hypr/scripts/waybar-launch.sh` — the guarded-launcher pattern D-06 mirrors
- `stow.sh` — `PACKAGES` array (currently 20 entries); `quickshell` registers here in the same commit that creates the package
- `install.sh` — `PACMAN_PKGS` (line ~52) for `quickshell` + Qt6 deps; `AUR_PKGS` (line ~212) is **not** needed
- `hypr/.config/hypr/config/keybinds.conf` — the 78 existing binds the probe's summon keybind must not collide with
- `hypr/.config/hypr/config/windowrules.conf` — carries the two stale inert `eww-media-popup` layerrules (lines ~259, ~272); relevant as the cautionary precedent for D-21's namespace discipline

### Precedent artifacts worth reading before writing the gate
- `.planning/phases/08-*/08-BAR-02-EVIDENCE.md` — the format precedent for a written evidence artifact backing a scope verdict
- Phase 10's plan 2 (the AGS human-clicked input-viability gate) — the direct structural precedent for this whole phase

</canonical_refs>

<code_context>
## Existing Code Insights

### Verified facts (checked on this machine during discussion — do not re-derive)
- **`extra/quickshell 0.3.0-2`** is in the official Arch `extra` repo. QS-01's package-name question is settled; no AUR involvement. Qt6 dependency set still needs enumerating for `install.sh`.
- **Hyprland `0.56.0`** (commit `36b2e0cf`, tagged v0.56.0, 2026-07-20) confirmed running.
- **No `quickshell/` package exists** in the repo yet. `stow.sh` `PACKAGES` currently lists 20 entries.
- **MAINT-01 reproduced and root-caused.** `keybind-doctor` currently dies on `jq: parse error: Invalid numeric literal at line 15, column 22`, then false-negatives **all 78** binds as "not registered" — the gate is presently worse than useless, reporting failures that are not real. The cause is field misalignment in 0.56.0's JSON serializer (see D-14), *not* a `keybind-doctor` bug. Plain-text `hyprctl binds` is correct: 781 lines, ~78 bind blocks, all fields aligned.
- **One physical monitor:** `DP-1` (Acer Technologies ED273U P, 2560×1440@165). No second output connected — hence D-07.
- `keybind-doctor`'s first three checks already PASS (mainMod resolution, description parity on all 78 binds, the `walker -s <set>` static grep). Only the `hyprctl binds` cross-check is broken — the repair is scoped, not a rewrite.

### Reusable Assets
- **`waybar-launch.sh`** — the guarded-launcher shape `quickshell-launch.sh` copies (D-06).
- **`keybind-doctor`'s path-argument self-test hook** — already exists specifically to let the gate be pointed at a poisoned fixture (D-18). No new mechanism needed.
- **`theme-doctor`'s poisoned-input discipline** — the proven-to-fail pattern D-18 follows.
- **`theme-apply`'s single reload fan-out** — the insertion point for D-13's fallback hook, if needed.
- **`contract.json`** — the render-target manifest Phase 12 will add a QML entry to. Deliberately *not* touched this phase (D-04, D-20).

### Established Patterns
- Every daemon autostarts via `exec-once = uwsm app -- <cmd>` in `autostart.conf`, with a comment block explaining its ordering. D-06 follows this.
- Generated/runtime output lives under `~/.local/state/`, never in git; `git status` staying clean after theme operations is an enforced invariant. D-20 follows this.
- Rerunnable gate scripts (`theme-doctor`, `theme-parity`, `theme-stress-test`, `keybind-doctor`, `waybar-equivalence-check`, `waybar-design-lint`) are the repo's standard mechanism for "prove it stays true". D-05 adds the seventh.
- Zero hex literals in repo-authored stylesheets; every themed surface `@import`s from `~/.local/state/theme/`. D-04 avoids pre-empting this for QML.

### Integration Points
- `autostart.conf` ← one `exec-once` line for `quickshell-launch.sh`
- `stow.sh` `PACKAGES` ← `quickshell` (same commit as the package, D-11)
- `install.sh` `PACMAN_PKGS` ← `quickshell` + Qt6 deps (same commit, D-11)
- `keybind-doctor` ← plain-text parser (D-14) + Quickshell shortcut cross-check (D-16/D-17)
- `~/.local/state/quickshell/` ← new state dir consumed by `FileView`/`JsonAdapter` (D-20)
- `ecosystem.conf` ← the `PERMISSION_TYPE_SCREENCOPY` stanza, recorded verbatim for Phase 16 (D-12)
- `.planning/ROADMAP.md` ← criterion 4 wording amendment (D-15)

</code_context>

<specifics>
## Specific Ideas

- **"The probe never being pretty is a feature"** — it must not be mistakable for a shipped surface (D-04).
- **The gate must be re-runnable, not a one-time ceremony.** Phases 14, 15 and 16 each add a surface and/or a keybind; `quickshell-doctor` is what stops the Phase 11 coexistence claims from silently rotting (D-05).
- **Record *why*, not just *what*, for the `-j` abandonment** — so a future reader doesn't "helpfully restore" structured parsing and reintroduce silently-wrong data (D-14).
- Fallback decisions (D-13 FileView, D-17 shortcut discovery) follow one consistent house rule established in this discussion: **record the limitation, take the workable path, don't stop over it.** Only QS-02 stops.

</specifics>

<deferred>
## Deferred Ideas

- **Real second-display hotplug verification** — D-07 uses a virtual headless output. A one-time real DP/HDMI hotplug test with genuine EDID negotiation was considered and set aside; if a second display becomes available during the milestone, this is worth a dated line in the evidence artifact. Not a blocker.
- **Frame/CPU budget for live multi-window screencopy** — explicitly Phase 16's OVER-04, deliberately not pulled forward (D-12).
- **QML palette render target and motion tokens** — Phase 12 owns the token schema and the `contract.json` QML entry. D-04 deliberately leaves the probe unstyled rather than guessing the format.
- **A `-j` auto-switch-back probe in `keybind-doctor`** — self-healing once upstream Hyprland emits valid aligned JSON. Considered and rejected for now (two parsers plus a correctness probe for a payoff on an unknown date). Revisit if a future Hyprland release fixes the serializer.
- **Reorganizing `quickshell/` into an end-4/Caelestia-style tree** — D-19 defers structure until surfaces earn it; Phase 14 is the natural point to revisit.
- **Any visible Quickshell surface** — D-02 ships nothing visible. Phase 14's dashboard drawer is the first real surface.

</deferred>

---

*Phase: 11-Quickshell Viability Gate*
*Context gathered: 2026-07-26*
