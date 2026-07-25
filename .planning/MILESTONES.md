# Milestones

## v2.0 Desktop Expansion (Shipped: 2026-07-25)

**Phases completed:** 7 phases, 64 plans, 160 tasks

**Key accomplishments:**

- journalctl grep across last 3 boots
- FIX-02 root cause revised from the #423 grace-race to "config options silently invalid after hyprlock upgrade + startup input race" — hyprlock.conf migrated to the real 0.9.5 schema with immediate_render on and fadeIn disabled; 10-trial verification deferred to end-of-phase UAT.
- Profiled kitty/zsh startup with zprof+hyperfine+fastfetch --stat, found nvm lazy-sourcing as the dominant ~400ms cost center (53.5% of shell init), vendored the oh-my-posh theme locally to remove a ~214ms remote GitHub fetch, and left fastfetch/disk/gpu/zinit untouched because the evidence showed they weren't slow.
- Benchmarked Plan 03's optimized zsh (95.5ms warm) against a full-parity fish 4.8.0 config (32.7ms warm, ~2.9x faster), the user picked fish at the D-08 checkpoint, and the switch was wired declaratively — `shell fish` in kitty.conf (no chsh, login shell stays zsh), fish in install.sh PACMAN_PKGS and stow.sh PACKAGES, zshell retained as fallback.
- Fixed fish's silent node-tooling activation gap (04-REVIEW.md CR-01) by adding an explicit, guarded `nvm use --silent` call in config.fish's interactive block, plus documented the one-time fresh-machine `nvm install v24.18.0` provisioning step in install.sh.
- Closed the FIX-02 UAT gap by adding `general:ignore_empty_input = true` and `input-field:check_text` to hyprlock.conf, both pre-verified against the installed hyprlock 0.9.5 binary schema.
- Threaded a mode (light/dark) concept through the theme-engine pipeline: `materialyou-light` entry, `mode.sh` lightness/override detection, mode-aware `gtk.sh` gsettings + GTK_THEME propagation, and `settings.ini` migrated to a rendered contract target — closing all three dark-hardcoded chokepoints named in the phase objective.
- Expanded the static preset library from 6 to 20 palette JSONs (9 Omarchy-lineup dark + 5 canonical-upstream light), fixed the two hardcoded preset-name arrays that would have silently excluded them from every gate, and deleted the legacy per-app themes/ stow package.
- Renamed wallpaper folders to strict 1:1 correspondence with palette names, completed the folder set for all 20 presets, and added `theme_engine_wallpaper_autoset()` so `theme-apply <static-preset>` lands a matching wallpaper alongside the color switch.
- Redesigned the wallpaper picker to Omarchy-level polish: pixel-perfect kitty-graphics previews, a new fzf-colors.conf pipeline render target (13th contract file) replacing hardcoded catppuccin fzf theming, per-theme restriction with Ctrl-A browse-all and visible fall-open, an active-wallpaper marker, and materialyou/materialyou-light-aware selection re-apply — all human-verified live on the desktop.
- Fixed the UAT Test 4 / WR-04 gap where every Esc-cancel in the theme and waybar-layout switchers fired an error toast, by capturing walker 2.16.2's real exit-130 cancel signal instead of assuming exit-0-plus-empty-output.
- Extended install.sh with 16 new packages (13 official-repo, 3 human-approved AUR) and swayosd-libinput-backend systemd service; declared swayosd in stow.sh — full reproducibility foundation for the themed-surfaces-utility-suite phase.
- 4 new matugen render targets (hyprlock, SwayOSD, Zen chrome, satty) registered in the single Wave-1 hub — contract.json 13->17, theme-parity green across 22 palettes incl. light+dark fixtures
- wlogout rebuilt from a full-screen SVG tile grid into a compact 72px Nerd Font glyph center bar (D-09/D-10), with codepoints verified against the installed font's actual cmap rather than assumed
- Hyprlock redesigned onto its own matugen render target with a 12-hour clock, playerctl now-playing, battery/caps-lock indicators, and a conditional failed-attempts counter, while the Phase 4 FIX-02 input hardening stays verbatim — approved live under both light and dark themes.
- Omarchy-style Print-key capture suite — hyprshot -z --raw piped into satty for freeze/annotate/save/copy (region/window/full), plus Alt+Print gpu-screen-recorder toggle with an explicit walker audio picker and ffmpeg palettegen/paletteuse GIF export as a notification action
- Bottom-center themed SwayOSD pill wired to swayosd-client media keys, plus a lazy Zen browser profile self-heal (installs.ini/profiles.ini resolution + userChrome.css symlink + notify-only reload) added to reload.sh's single guarded fan-out.
- Theme-orthogonal icon-theme state axis (UTIL-04) closing Pitfall 6: an fzf-in-kitty picker persists icon-theme picks through a state file generate.sh reads and commit.sh's rsync excludes, with gtk.sh tracking folder-accent colors for Papirus (papirus-folders) and nearest-baked-variant swaps for Tela/Colloid.
- fzf-in-kitty nerd-font switcher (UTIL-05) with a live rendered specimen preview, wiring a new theme-orthogonal font-choice state axis across kitty, vscodium, GTK, and waybar via a brand-new `lib/font.sh` render module.
- Emoji picker (curated glyph list via walker --dmenu, wtype+wl-copy), hyprpicker-backed color picker with a swatch notification, cliphist 100-entry cap + session-end wipe + manual wipe entry, and the freed Super+X/Z utility chord family
- Closed CR-02 (fzf pickers had no controlling TTY), CR-01 (waybar's hardcoded font-family literal shadowed the font-switch mechanism), and WR-07 (theme-doctor had no presence coverage for font render targets) — the invocation and render-sink bugs blocking UTIL-04/UTIL-05 are now fixed.
- Fixed gpu-screen-recorder's region-capture flag shape (`-w region -region <geom>`), added hyprshot/satty presence guards to all three capture scripts, and corrected color-picker.sh's set -e exit-status bug on its success path.
- Fixed install.sh's hardcoded `paru` in cleanup (yay-safe reproducibility, CR-04) and hyprlock's hardcoded Catppuccin placeholder hex (pipeline-sourced, WR-01)
- Fixed the last blocker from 06-VERIFICATION.md: swayosd-server was never launched anywhere in the repo, and install.sh enabled the caps-lock backend on the wrong systemd bus — both silenced, so pressing a volume/mute key did nothing on a fresh install.
- Rebound the Print-key family to physical keycode 107 and swapped hyprshot's broken `-r` for the working `--raw` long form in all three capture scripts, closing SHOT-01/02/03's two UAT-blocking gaps.
- Added vlc, vlc-plugins-all, and xdg-user-dirs to install.sh's PACMAN_PKGS so fresh installs can decode gpu-screen-recorder output and get a deterministic ~/Pictures dir.
- Populated six Nerd Font glyphs on wlogout buttons and deleted 8 GTK3-unsupported generated-content rulesets that were causing GTK3 to discard the entire stylesheet with 0 bytes output — both defects proven closed via a real `Gtk.CssProvider` parse, not a grep.
- Hardened color-picker (stdout-based failure classification + hex format guard), clipboard-wipe (empty-db tolerant), font-switcher/icon-theme-picker (trap-based mktemp cleanup), and record-toggle (argv[0]-bounded process matching) — closing WR-01, WR-02, WR-04, WR-05 from 06-REVIEW.md
- Closed the last two carried 06-REVIEW.md warnings — a latent set -e abort in the Zen installs.ini section counter (WR-03) and a sixth-occurrence engine-owned-file deletion in commit.sh's rsync --delete (WR-06)
- theme-doctor now parses all 6 GTK3 and 3 GTK4 pipeline-owned stylesheets through a real `Gtk.CssProvider`, asserting a non-empty provider and zero fatal errors — proven with a synthetic regression that reproduces CR-01's exact discard signature (0 bytes) and fails, closing the exact blind spot that let four prior grep-only verification rounds pass on a completely unthemed wlogout surface.
- 1. [Rule 1 - Bug] `[placeholders]` key `"menus"` renders an empty placeholder under `walker -m menus:main`; `"menus:main"` is required
- 1. [Rule 1 - Bug] keybind-doctor's own comment text tripped its own no-eval/no-source acceptance grep
- Idempotent multilib enablement plus 10 new packages (8 official-repo, 2 AUR human-verified) wired into install.sh for Steam/Lutris/Heroic/ProtonUp-Qt and ollama/aichat, with the container-gate D-34 proof deferred pending a push authorization the executor is not permitted to grant itself
- Bare Super tap now opens the main menu exclusively; the app launcher moved to Super+Space; D-02/Assumption A2 (default bind-shadowing on Hyprland 0.55.4) closed by live human keypress across five tests; the human's full ~48-bind regression sweep found zero regressions — PLAN COMPLETE, MENU-01 fully delivered.
- Root/Utilities/Screenshot/Settings menu tree shipped as elephant TOML providers; a stow-parity gap that left three menus invisible to elephant (despite every repo-side gate passing) is now root-caused, fixed live, and permanently closed with a self-healing guard.
- The executor agent confabulated a concurrent session and halted before closeout.
- All six pacman packages and both AUR packages were declared in `install.sh` (07-03) but never installed on this machine
- Theming for free.
- Extracted waybar's four copy-pasted layout files into one `modules.jsonc` + `waybar-modules.css` shared-definition pair, converted all three layouts (full/minimal/floating) to `include`/`@import` composition, and built a rerunnable resolved-config equivalence gate that mechanically proves zero behavior change.
- Translucent/low-luminance bar styling (D-06) plus a single visibility-owner script (`waybar-visibility.sh`) that replaces the desync-prone shared-SIGUSR1-toggle pattern with fixed signal actions, per-source intent files, and a live-verified CSS-dim-vs-true-unmap split for the exclusive zone (D-03/D-04).
- All four BAR-01 visibility actors (hypridle idle listener, Hyprland fullscreen socket2 watcher, gaming-mode re-point, and a new `$mainMod SHIFT, B` keybind) now declare intents exclusively through `waybar-visibility.sh` -- the single owner 08-03 built -- closing the OLED auto-hide feature end-to-end.
- Authored the 4th (left-column) waybar layout entirely through 08-01/08-03's shared-include mechanism, added a `custom/gaming-mode` indicator (D-35) that reads Phase 7's state file read-only, closed the live `custom/notification`-missing-from-floating parity bug (D-26), and folded a rerunnable per-module colour-resolution gate into `theme-doctor` that hard-fails on an unresolved `@token` — proven capable of failing via a self-test before being trusted.
- eww 0.6.0 lands as a human-gated AUR package and a first-class theme-pipeline render target (theme-parity green across all 22 palettes), with its real CLI surface pinned against the installed binary for 08-07/08-08 to build on; the container-tier D-36 rerun is blocked on a pre-existing stale-origin precondition (255 unpushed commits) and is deferred to human push authorization, following this repo's own established precedent.
- The full-fat D-21 media popup — 220x220 album art, title/artist/album, prev/play-pause/next, a draggable seek bar, a volume slider, and an explicit player switcher — ships as a real eww window backed by three hardened bash helpers that keep player-supplied MPRIS metadata (attacker-controlled D-Bus data) out of every shell command and output context, proven by a 19-check hermetic adversarial gate and verified live end-to-end against the real running eww daemon and a real Firefox/Zen player.
- Every waybar layout's media segment now opens the eww media popup on click via a new cursor-anchored, monitor-clamped opener script — closing BAR-04 — but ships with D-23's pre-authorised fixed-position fallback as the active default because every physical display was hardware-disconnected this session, making live on-screen verification of the cursor-anchored math categorically impossible.
- Deleted swaync's mpris widget in favor of the 08-07 eww media popup, added a volume slider + device-agnostic brightness slider + a 3-toggle anti-drift buttons-grid to the panel, and fixed a real shell-quoting bug in the toggle scripts discovered via live testing against the running swaync daemon.
- D-09's timeboxed spike measured a real, reproducible flash and transient window reflow on waybar's only CSS-actuation signal path (SIGUSR2/reload) — mechanism-independent, so it kills any CSS-based jitter before the 2px displacement question is even reached — and closes BAR-02 as DESCOPED with a written, reproducible evidence artifact per D-10, plus a real (not asserted) luminance-delta measurement of the D-06 OLED trim.
- Rerunnable design/token lint gate (waybar-design-lint) + a fully-glyphed modules.jsonc (27 cmap-name-verified codepoints) + theme.css semantic alias layer — zero visual design change, all three closing the exact holes that let a "complete failure" bar ship through every prior green gate.
- `full` layout: APPROVED by the user on sight
- APPROVED by the user on sight
- APPROVED by the user on sight
- APPROVED by the user on sight
- APPROVED by the user on sight
- wleave 0.7.1-1 installed and human-approved; installed-artefact config schema fully probed via man pages/--help/binary strings/shipped defaults; matugen dry-run proves Material You resolves all four new M3 container roles but every static preset (20/20) hard-fails on three of them — a blocking finding for 09-02.
- wleave 0.7.1 fully replaces wlogout as the desktop's power menu across all three UI entry points and both installer scripts, themed end-to-end through matugen, with the GTK3 engine's repo footprint fully retired — three genuine pre-existing, unrelated defects (an orphaned eww.scss contract entry, a broken hyprctl JSON parser, a permanently-dirty-tree check) discovered and deferred rather than silently absorbed into this plan's scope.
- Six per-action hues (two mix()-derived at the container level) with hover/focus feedback delivered via wleave's native icon+text split, an empirically-tuned 0px-residual glyph centring fix, a 345ms left-to-right entrance stagger, and a live-confirmed compositor exit-fade — resolving RESEARCH's Assumption A2 by observation rather than leaving it flagged.
- The D-14 human render-gate is closed on nine explicitly-approved items across four live review rounds; all three UI entry points confirmed live (command-string-executed, layer-verified); all six power-action strings confirmed byte-identical to the Phase-4-audited strings; and the final gate sweep is carried forward unchanged, every failure re-confirmed pre-existing and unrelated to this phase.
- Registered `cava` (official extra) and `aylurs-gtk-shell` (AUR) in install.sh's package arrays; verified all three toolchain binaries (ags 3.1.0, cava 0.10.7, gjs 1.88.1) already present and working on this host.
- Standalone AGS v3 (GTK4) `media` window — centered dark card, click-away + Esc dismiss, `toggle-media` request verb — with a human-confirmed test-button click proving AGS delivers pointer input where eww could not.
- AGS media card bound to live MPRIS state — working transport / seek / volume / player-switcher over the unchanged bash backend, with a per-track seekability latch that survives Firefox/YouTube's unreliable `mpris:length` and a startup seed for a correct first-drag baseline.
- AGS media card restyled to the garuda/HyprPanel look — a Gtk.Overlay stack with a blurred album-art background, a cava audio-reactive bar underlay bleeding around a centered thumbnail, and centered rounded-pill controls — with a Hyprland `ags-media` blur layerrule frosting the card, human-confirmed animating to audio (MEDIA-02).
- AGS media applet wired into the matugen pipeline — a new `ags-colors.scss` template renders `~/.local/state/theme/ags.scss`, `style.scss` imports it with zero hex literals, and a runtime `sass` recompile + `app.apply_css(css, true)` hot-reloads the running applet on both static and matugen theme switches, with zero manual restarts (MEDIA-03).
- Waybar media segment repointed to `ags request -i media toggle-media`, AGS daemon autostarted, and the dead eww media popup fully retired (defwindows, scripts, daemon autostart, matugen template) after a clean consumer check — closing MEDIA-01 and MEDIA-04 with a human-approved live end-to-end gate.

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
