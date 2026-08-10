# Milestones

## v3.0 Quickshell Foundation & Motion Language (Shipped: 2026-08-10)

**Phases completed:** 8 phases (11-17, incl. inserted 13.1), 68 plans, 190 tasks
**Scale:** 530 commits, 16 days (2026-07-26 -> 2026-08-10)
**Requirements:** 39/40 satisfied (QS-03 formally dropped one-way under D-13; MAINT-02 unfinished)
**Closeout:** override_closeout - Phase 16 shipped without a `16-VERIFICATION.md` (its evidence is `16-UAT.md`, 30/30 passed, 0 issues), so `all_phases_verified` is false. 53 open artifacts acknowledged as carried debt at close: 6 debug sessions, 1 incomplete quick task, 46 deferred items. Milestone audit status `gaps_found`, closed knowingly rather than blocked - see `milestones/v3.0-MILESTONE-AUDIT.md` and STATE.md `## Deferred Items`.

**Delivered:** Quickshell became the project's shell toolkit without displacing anything - three net-new QML surfaces (dashboard drawer, the audio/wifi/bluetooth panel family, a full-screen workspace overview), one motion language rendered from a single source to QML, GTK4 CSS and Hyprland, and the compositor moved onto Lua ahead of Hyprland 0.57's hyprlang removal. The additive-only boundary held for all 8 phases: nothing that worked on 2026-07-26 stopped working.

**Key accomplishments:**

- **Proved the toolkit before building on it.** QS-02 put a human-clicked pointer/keyboard/dismiss-outside gate on a throwaway `PanelWindow` at plan 2, with standing authority to stop the milestone. It passed on the first attempt - the same shape that caught eww's fatal pointer-input gap in v2.0 only *after* a full feature had been built on it.
- **One motion source, three render targets, all verified against the installed binaries.** `theme-engine/motion.json` renders to QML `easing.bezierCurve`, GTK4 `cubic-bezier()` and Hyprland `bezier =` in one `theme-apply`, with a runtime normal/reduced/off axis and a deny-by-default `motion-lint` (folded into `theme-doctor`) that refuses any surface hand-rolling a raw or dangling value. TOKEN-06's spring-physics stretch was closed by a recorded human verdict - MD3 retained, springs not adopted - rather than left dangling.
- **The dashboard drawer reads state the desktop already owns rather than forking it.** A Super+D four-tab swipeable QML surface sharing one MPRIS reader with waybar and the AGS card, executing byte-identical quick-toggle scripts to swaync's own grid, running zero timers and zero subprocesses while dismissed, with an animated gradient rim kept in step with Hyprland's `borderangle` at every motion scale.
- **Three in-shell panels displaced pavucontrol, nm-connection-editor and blueman from the daily workflow.** Built from one shared `PanelDialog` frame and verified against real hardware - a real AP, a real hidden network, a real Bluetooth peer. Two near-misses were avoided by measuring before acting: copying the wifi secret-agent remedy to Bluetooth would have converted a cosmetic complaint into a functional regression (pairing stops completing entirely with no agent registered).
- **A workspace overview on the protocol Hyprland already ships.** Eleven tiles - a pixel-stable 5x2 numbered block plus an always-present scratchpad - rendering every window as its own live `ScreencopyView` at real `hyprctl` geometry, with click-to-focus, two-level keyboard navigation, and drag-between-workspaces behind a strict validation boundary so no client-controlled text can reach the compositor's Lua evaluator. `hyprexpo` was rejected by three independent researchers: zero extra packages, no `hyprpm` ABI coupling.
- **The compositor moved to Lua ahead of an upstream deadline, proven rather than hand-diffed.** Phase 13.1 was inserted mid-milestone and built around `hypr-equivalence-check`, which diffs a live session against a committed pre-migration `hyprctl` baseline. 80/80 binds, `options.jsonl` and `animations.json` both PASS; the sole remaining diff is two documented `bindm` mouse-field records. Survived a genuine cold boot. Two Lua-only hazards were found empirically, not assumed: Lua 5.5's randomized string-hash seeds made `pairs()` curve registration non-deterministic per boot, and `hl.dsp.dpms` silently ignores bare-string arguments.
- **Two dead ends were closed with evidence instead of left ambiguous.** QS-03 (per-screen fan-out) was re-attempted in Phase 12 under a bounded budget across two structurally distinct arrangements plus an escape-hatch spike, reproduced an FM2-class failure both times on quickshell 0.3.0-2 - the latest in `extra`, so "wait for upstream" was not available - and was dropped one-way under D-13. D-35 (loading the cursor plugin declaratively from Lua) was tested exhaustively in Phase 17 and found to either prompt a permission dialog every login/lock or crash the compositor via infinite `CConfigManager::reload()` recursion, depending on grant state; the call was removed.
- **The human render gate kept earning its place.** Phase 16's multi-window thumbnails shipped **two false passes** through automated and screenshot-based checks - only one window was visibly painted - before the operator's own eyes caught it, and the real root cause was then traced with per-delegate IPC measurement rather than more screenshots. Phase 17's live-wallpaper hover path shipped a real state bug that the gate caught on its first pass.

**Known gaps at close:**

- **MAINT-02 - Logout wrapping.** The one genuinely unfinished requirement. 3 of 4 Phase 4 advisory items closed (fisher `-f`, nvm guard, uv env guard, all fault-injection proven, commit `baae579`); Logout stays on the bare path **by default, not by evidence** - its D-29 teardown measurement was waived by explicit operator decision on 2026-07-28 rather than performed, so the hazard is neither confirmed nor falsified. Reproduction steps remain verbatim in `13-03-PLAN.md` Task 2.
- **`GradientBorder` reuse across the 14 -> 15 seam.** The animated rim has exactly one consumer (`Dashboard.qml:387`); `PanelDialog.qml` - the single shared frame all three Phase 15 panels are built from - declares a background Rectangle with no border of any kind. Diagnosed 2026-08-02 (debug session `panels-missing-animated-border`, Bohrbug, 100% reproducible, confirmed by grep, source read and a live A/B screenshot), deliberately not fixed under diagnose-only mode. A stated user expectation the milestone left unmet, not an accepted limitation. **SUPERSEDED 2026-08-10 (LEDGER-01):** this gap was already closed in code before the milestone shipped. Commit `4f48847` (`feat(15-10): instantiate GradientBorder inside PanelDialog.qml`, 2026-08-02 19:35:30) added the rim to `PanelDialog.qml:191`, the same day as the diagnosis; all three panels inherit it from the shared frame. The audit's statement was accurate to the debug session's frontmatter, which was never updated after the fix landed. Operator visually confirmed all three panels render the rim on 2026-08-10.
- **OVER-04's frame-rate term.** The CPU half was measured and passed with 2.4x headroom (20.9% worst of one core against a 50% ceiling); the FPS floor and target are recorded UNMEASURED and the verdict does not claim them - the only instrument for it froze the machine.
- **Phase 16 has no VERIFICATION.md.** Its 30 deliverables are evidenced in `16-UAT.md` (16 auto-covered from passing refs, 14 human-confirmed live) and `16-OVER04-MEASUREMENT.md`, but the canonical verify artifact was never written. This is what makes the closeout an override rather than verified.
- **Two malformed `coverage:` blocks.** `16-05-SUMMARY.md` D5 carries an invalid `status: not_run`; `16-06-SUMMARY.md` D2/D3/D4 omit the `rationale` required when `human_judgment: true`. The classifier failed safe - every affected deliverable was escalated to a human checkpoint rather than dropped - so this is bookkeeping, not lost coverage.

**Tech debt carried into v4.0:**

- 5 unresolved debug sessions in `.planning/debug/` (4 `diagnosed`, 1 `unknown`): `bluetooth-enable-inert`, `wifi-hidden-network-not-detected`, `wifi-hidden-network-unsupported`, `wifi-scan-progress-feedback`, `wifi-wrong-password-external-dialog`. Only `.planning/debug/resolved/` has been curated. The removed session (`panels-missing-animated-border`) was resolved on 2026-08-10 under LEDGER-01; the remaining five are LEDGER-04's subject in Phase 19.
- 1 incomplete quick task: `260728-51j-write-the-hyprland-lua-config-migration-` (status `missing`).
- WINDOWS.md: 16 of 23 rows still `open`, concentrated in phases 09 (7), 13.1 (7), 15 (6), 12 (2), 13 (1). The Phase 09 rows are inherited from v2.0.
- WINDOWS #14: ~8 legacy `hyprctl dispatch global <name>` call sites in `quickshell-doctor` remain on the withdrawn string form, silently dead under the Lua config manager. Deferred by operator decision 2026-07-28. Caution: that script's headless-output add/remove test has previously SEGV-crashed the compositor during a DP-1 hotplug. **SUPERSEDED 2026-08-10 (LEDGER-01):** the file now dispatches only through `_qsd_dispatch_global()` at line 243, which emits the `hl.dsp.global()` Lua expression form; the bare string form survives only inside comments documenting its withdrawal. Zero live legacy sites remain and WINDOWS #14 is marked fixed.
- `theme-stress-test` switch #5 fails the strict `theme-doctor` gate - `lib/wallpaper.sh:65` repoints the tracked `current.jpg` symlink on every static theme switch, dirtying the tree against the clean-tree invariant. Pre-existing Phase 03 debt, not a v3.0 defect; two fix options in WINDOWS.md #9, deferred through Phase 13 and not taken.
- Phase 15 closed with acknowledged gaps: no security review, and the verifier was not re-run over the gap-closure round (see `15-VERIFICATION.md`).
- Phase 13 closed `passed_under_two_operator_waivers`: the D-19/D-20 motion soak gate and the WR-04 teardown-hazard measurement.

## v2.0 Desktop Expansion (Shipped: 2026-07-25)

**Phases completed:** 7 phases (4-10), 64 plans, 160 tasks
**Scale:** 444 commits, 488 files (+57,232 / -3,151), 16 days (2026-07-09 -> 2026-07-25)
**Requirements:** 36/36 verified
**Closeout:** verified_closeout - all 7 phases `phase_complete` with `verification_status: passed`; open-artifact audit clear at close (no acknowledged/deferred items required to close)

**Delivered:** The repaired v1.0 theming foundation grew into a complete desktop - light mode across the whole pipeline, every remaining surface re-themed, and the utility suite, Super-key menu, waybar rebuild, wleave power menu and AGS media applet all shipped and verified.

**Key accomplishments:**

- Root-caused and fixed the three known reliability defects - wlogout shutdown hang, hyprlock first-keystroke drop, kitty slow startup (shell init 641ms -> 33.9ms via fish) - plus the v1.0 rsync tech-debt carry-over. Diagnosed to source with profiling and journal evidence, not patched around.
- Extended the theme pipeline to full light mode: 22 targets (15 dark, 5 light, 2 Material You), mode auto-detected from palette lightness (20/20 correct), theme-scoped wallpaper sets behind a redesigned kitty-graphics picker.
- Re-themed every remaining desktop surface (wlogout, hyprlock, SwayOSD, Zen) and shipped the full utility suite: screenshot capture/annotate/record plus emoji, color, clipboard, icon-theme and font pickers. 19 plans, 53/53 threats closed.
- Built the $SUPER-tap walker menu as elephant TOML providers - Utilities, AI dashboard, Game center, power, settings, searchable keybind cheat-sheet - with the app launcher moved to Super+Space and a ~48-bind regression sweep finding zero regressions.
- Rebuilt waybar: four layouts composed from one shared `modules.jsonc`, OLED-safe single-owner visibility, mpris media center, notification-center access. Every layout redesigned per-flow after a blocking UAT rejection and approved by the user on sight under light, dark and dynamic.
- Migrated the power menu wlogout (GTK3) -> wleave 0.7.1 (GTK4), structurally eliminating the whole-stylesheet-discard failure class behind WLOG-01. Six per-hue capsules with hover/focus reveal, entrance cascade and compositor fade exit; `wlogout/` deleted.
- Replaced the confirmed-dead eww media popup with an AGS v3 media card: working pointer input (the thing eww could not do), cava audio-reactive underlay, matugen-themed with runtime `sass` + `apply_css` hot reload, reproducible via install.sh + stow.

**Known gaps carried into v3.0:**

- `theme-doctor` / `theme-parity` / `theme-stress-test` fail on an orphaned `eww.scss` entry in `contract.json` left by the 10-06 eww retirement - the three core regression gates are red for a bookkeeping reason until it is dropped.
- Stale, inert `eww-media-popup` layerrules in `windowrules.conf`.
- `keybind-doctor`'s `hyprctl binds -j` parsing broken on Hyprland 0.56.0 (pre-existing).
- Phase 4 advisory review items `04-REVIEW.md` WR-01..04.
- The container-tier reproducibility rerun (D-34/D-36), blocked all milestone on push authorization, is unblocked by this close's push but not yet run.

**Retrospective note:** ~12% of the milestone's plans (08-07, 08-08, 08-11..08-16) were rework caused by two avoidable misses - building a media popup on a toolkit whose ability to receive a click was never tested, and shipping a bar design that passed every mechanical gate while being visibly broken. Both produced standing rules: a fail-fast toolkit-viability gate, and a blocking human render-and-look gate on any visual surface. See `.planning/RETROSPECTIVE.md`.

---

## v1.0 Theme Pipeline Repair (Shipped: 2026-07-09)

**Delivered:** One theme switch — static preset or matugen dynamic — re-themes all ten desktop surfaces live from a single consolidated theme-engine, with the whole setup proven to reproduce unattended on a fresh Arch system.

**Phases completed:** 3 phases, 9 plans, 25 tasks
**Stats:** 98 commits, 160 files changed (+13,636 / −1,176), 3 days (2026-07-07 → 2026-07-09), git range `33c3b05` → `e8c5615`
**Closeout:** verified_closeout — all phases verified, 19/19 requirements complete, milestone audit passed (see `milestones/v1.0-MILESTONE-AUDIT.md`)

**Key accomplishments:**

- 23-finding component-grouped AUDIT.md (SCAN-01/SCAN-02) plus the verified stuck-white root-cause fix: adw-gtk-theme installed from official extra repo and install.sh's nonexistent adw-gtk3 AUR entry replaced.
- One shared `theme-apply <name>` entrypoint atomically renders static presets and Material You through the same matugen templates into `~/.local/state/theme/`, owns the entire reload fan-out, and every app config now imports from that state dir instead of the old triplicated cp/cat pipeline.
- Hardened Walker's restart-only reload with an elephant health gate, made Thunar's daemon restart survive open windows via a deduped bounded-poll watcher, wired GTK4 dark+accent through gsettings, and human-verified all ten desktop surfaces re-theme live in both static and dynamic modes with no relogin.
- Built `contract.json` + `lib/contract.sh` as the single source of truth for the 10-file theme output contract, wired `theme-doctor` to read it, and shipped `theme-parity` — a render-only checker that proved all 7 targets (6 static presets + materialyou) already produce byte-for-byte structural, name-set, and semantic-value parity with zero fixes needed.
- Built a rerunnable 10-switch alternating static↔dynamic stress harness, found and fixed a real reliability bug (commit.sh's rsync --delete silently wiping its own logs/ output), and closed on a human-signed-off D-41 clean full gate proving PIPE-06.
- Removed the wofi package tree, an orphaned matugen template, debug.txt, and a Phase-1-retired script; fixed the screenshot-in-git root cause with a stow-fold exclusion + gitignore pair; ran a reference-based dead-file hunt that surfaced three ambiguous files awaiting confirmation.
- install.sh restructured into a flagged, hardware-guarded, hard-fail-verifying installer (--core-only/--help, section_core_rice/section_hardware/section_personal, verify_packages()); stow.sh made fully idempotent, zero-prompt, and seeds the first-boot theme via theme-apply catppuccin.
- theme-doctor and theme-stress-test are now strict (menus provider-parity fixed, git-clean invariant added, all carve-outs removed), and the elephant provider gap — a Go plugin/host build-invocation mismatch, not the simple "never installed" gap the plan assumed — is closed on this machine: theme-doctor exits 0 (23 passed, 0 failed).
- Built the rerunnable `verify/container-run.sh` installer-regression harness (podman + real remote clone + install.sh --core-only + stow.sh + theme-parity gate) and the step-by-step `VERIFICATION.md` graphical-VM procedure; the gate runs peeled off six real fresh-install defects before the first genuine PASS (run-20260709T060703Z, theme-parity 287/0), and the graphical VM tier closed with human visual sign-off — INST-03 fully verified.

**Tech debt carried into v2 (non-blocking, from the milestone audit):**

- rsync is a hard runtime dependency of `theme-engine/lib/commit.sh` but only arrives transitively — add it explicitly to install.sh's PACMAN_PKGS.
- GTK3 stale-until-closed caveat (D-15/D-37): already-open GTK3 windows keep the old palette until closed — documented accepted behavior.
- theme-doctor's session-dependent checks (walker/elephant processes, D-Bus) are graphical-tier-only by design; the container gate treats them as informational.

---
