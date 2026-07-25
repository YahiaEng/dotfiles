# Milestones

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
