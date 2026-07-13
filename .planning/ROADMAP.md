# Roadmap: Arch + Hyprland Dotfiles

## Milestones

- ✅ **v1.0 Theme Pipeline Repair** — Phases 1-3 (shipped 2026-07-09) — [archive](milestones/v1.0-ROADMAP.md)
- 🚧 **v2.0 Desktop Expansion** — Phases 4-8 (planned 2026-07-09) — bug fixes, light mode, utility suite, Super-key menu, waybar evolution

## Phases

<details>
<summary>✅ v1.0 Theme Pipeline Repair (Phases 1-3) — SHIPPED 2026-07-09</summary>

- [x] Phase 1: Root-Cause Fix & Consolidated Theme Engine (3/3 plans) — completed 2026-07-07
- [x] Phase 2: Static ↔ Dynamic Parity & Switch Reliability (2/2 plans) — completed 2026-07-07
- [x] Phase 3: Repo Cleanup & Fresh-Install Reproducibility (4/4 plans) — completed 2026-07-08

Full details: [milestones/v1.0-ROADMAP.md](milestones/v1.0-ROADMAP.md)

</details>

### v2.0 Desktop Expansion (Phases 4-8)

- [x] **Phase 4: Reliability Fixes & Tech Debt** - Root-cause and fix the wlogout shutdown hang, hyprlock first-keystroke drop, and kitty slow startup, then close the rsync install.sh carry-over (completed 2026-07-11)
- [x] **Phase 5: Light Mode Pipeline & Theme Presets** - Extend the theme pipeline to light mode, ship more presets (incl. light), and organize per-theme wallpapers behind a redesigned picker (completed 2026-07-11)
- [x] **Phase 6: Themed Surfaces & Utility Suite** - Redesign and re-theme wlogout, hyprlock, SwayOSD and Zen, and ship the full screenshot + emoji/color/clipboard/icon/font utility suite (19/19 plans executed, verification passed, UAT passed, 53/53 threats closed) (completed 2026-07-13)
- [ ] **Phase 7: Super-Key Menu** - $SUPER-tap opens an Omarchy-style walker menu wrapping utilities, power, settings, AI dashboard, game center, and a searchable keybind cheat-sheet
- [ ] **Phase 8: Waybar Evolution** - OLED-safe waybar with an additional vertical layout, mpris media center, and one-click notification-center access
- [ ] **Phase 9: wlogout to wleave Migration** - Replace wlogout with wleave (GTK4) to eliminate the GTK3 whole-stylesheet-discard failure class, with no regression to the Phase 6 center-bar design

## Phase Details

### Phase 4: Reliability Fixes & Tech Debt

**Goal**: The three known reliability/performance defects are root-caused and fixed, and the v1 tech-debt carry-over is closed — de-risking the base before any redesign layers on top.
**Depends on**: Nothing (first v2.0 phase)
**Requirements**: FIX-01, FIX-02, FIX-03, DEBT-01
**Success Criteria** (what must be TRUE):

  1. Selecting shutdown/reboot from wlogout completes every time with no blank-screen hang — the root cause is diagnosed (keyboard-vs-mouse test, journalctl/coredumpctl) and documented, not patched around.
  2. After the lock screen activates, the very first keystrokes register — the user types their password in one attempt with no dropped-input failed-auth loop.
  3. Opening a new kitty terminal feels instant — startup is profiled before/after and the regression is gone.
  4. A fresh `install.sh` run installs rsync explicitly (listed in PACMAN_PKGS), so theme-engine's commit step never relies on a transitive dependency.

**Plans**: 6/6 plans complete
**Wave 1**

- [x] 04-01-PLAN.md — FIX-01 wlogout shutdown/reboot hang: diagnose (keyboard-vs-mouse, journalctl/coredumpctl), apply uwsm-correct session actions; DEBT-01 rsync in PACMAN_PKGS [wave 1]
- [x] 04-02-PLAN.md — FIX-02 hyprlock first-keystroke drop: confirm #423 grace double-unlock signature, apply grace=0, lockout-recovery procedure [wave 1]
- [x] 04-03-PLAN.md — FIX-03 profile kitty/shell startup (zprof/hyperfine/fastfetch --stat), optimize zsh (local oh-my-posh, lazy nvm/bun, zinit turbo, fastfetch trim) [wave 1]

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 04-04-PLAN.md — FIX-03 benchmark optimized zsh vs fish, user decision, optional full fish adoption via kitty.conf/install.sh/stow [wave 2]

**Gap closure** *(verification found fish node tooling non-functional — CR-01)*

- [x] 04-05-PLAN.md — FIX-03 gap: fix fish nvm activation (explicit `nvm use` in config.fish; conf.d loads before config.fish) + document one-time `nvm install v24.18.0` provisioning [wave 1]
- [x] 04-06-PLAN.md — FIX-02 gap: hyprlock ENTER-first empty-submit input drop — add `general:ignore_empty_input = true` + input-field `check_text` cue (UAT Test 2 / D-23) [wave 1]

### Phase 5: Light Mode Pipeline & Theme Presets

**Goal**: The theme pipeline gains full light-mode support and a richer, better-organized preset and wallpaper experience — light themes render correctly across every surface and the wallpaper picker looks the part.
**Depends on**: Phase 4 (bug fixes de-risk the base before pipeline extension)
**Requirements**: THM-01, THM-02, THM-03, THM-04
**Success Criteria** (what must be TRUE):

  1. Applying a light preset (e.g. catppuccin-latte) re-themes the whole desktop in light mode — both dark-hardcoded chokepoints (`lib/gtk.sh` gsettings and `gtk-3.0/settings.ini`) are fixed and GTK3/GTK4 both flip to light with no dark surfaces left behind.
  2. Theme mode (light vs dark) is auto-detected from palette lightness, and the `contract.json` + theme-parity gate passes with both a light fixture and a dark fixture.
  3. The user can choose from an expanded set of static presets, including at least one light theme, all shipped as palette JSONs through the existing pipeline.
  4. With a static theme active, the wallpaper picker offers only that theme's wallpaper set; with Material You active, any wallpaper is allowed.
  5. The redesigned wallpaper picker presents wallpapers with Omarchy-level polish (thumbnails/layout), not the old bare list.

**Plans**: 5/5 plans complete
**UI hint**: yes

Plans:
**Wave 1**

- [x] 05-01-PLAN.md — Light-mode pipeline core: mode.sh detection (D-06), materialyou-light (D-05), mode-aware gtk.sh + rendered settings.ini symlinks (D-07/D-08), uwsm GTK_THEME hardcode removed [wave 1]

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 05-02-PLAN.md — Preset expansion: 9 Omarchy dark + 5 canonical light palette JSONs, dynamic parity/stress gates with light+dark fixtures, dynamic theme picker, themes/ package deleted (D-01..D-04) [wave 2]
- [x] 05-03-PLAN.md — Wallpaper sets: folder renames to 1:1 palette names (D-09/D-10), theme-apply wallpaper auto-set with per-theme last-used memory (D-11/D-12) [wave 2]

**Wave 3** *(blocked on Wave 2 completion)*

- [x] 05-04-PLAN.md — Picker redesign: kitty-graphics previews + active marker (D-13/D-14), pipeline-themed fzf colors (D-15), theme restriction with Ctrl-A + fall-open (D-16), visual checkpoint [wave 3]

**Gap closure** *(UAT Test 4 / review WR-04 — walker Esc-cancel fires an error toast)*

- [x] 05-05-PLAN.md — Three-way walker exit-code branch (130 cancel → silent, other nonzero → toast+exit 1) in theme-switch.sh (WR-04) and waybar-switch.sh (same set -e trap); committed hermetic exit-code checker [wave 1]

### Phase 6: Themed Surfaces & Utility Suite

**Goal**: Every remaining desktop surface is redesigned and re-themed, and a full suite of everyday utility tools ships — all following the established @import-from-state-dir pattern and validated by theme-parity under both light and dark.
**Depends on**: Phase 4 (wlogout/hyprlock bug fixes must land first), Phase 5 (light-mode parity gate validates the new surfaces)
**Requirements**: WLOG-01, LOCK-01, OSD-01, THM-05, SHOT-01, SHOT-02, SHOT-03, UTIL-01, UTIL-02, UTIL-03, UTIL-04, UTIL-05
**Success Criteria** (what must be TRUE):

  1. wlogout and hyprlock both show a modern redesigned look with sharp assets and colors sourced live from the shared theme pipeline, verified under both light and dark themes, and hyprlock testing follows a documented lockout-recovery procedure (second TTY logged in).
  2. Volume, brightness, and caps-lock changes show a themed SwayOSD indicator bound to the media keys, re-themed by the pipeline like every other surface (new matugen template + contract.json entry).
  3. The user can capture region/window/full-screen screenshots (animation, freeze, save + copy, notification), annotate them (arrows, text, shapes, blur), and record screen/region to video with GIF export.
  4. The user can invoke an emoji picker, a screen color picker (hex copied), a clipboard-history picker (with a size cap and wipe policy from day one so no unbounded plaintext secrets), an icon-theme picker (applies to Thunar/GTK live), and a nerd-font switcher (kitty/vscodium/GTK/waybar).
  5. Zen browser re-themes on theme switch (matugen-rendered userChrome.css, restart-based reload), and every new themed surface (swayosd, zen, hyprlock) is a contract.json target that passes theme-parity.

**Plans**: 19/19 plans complete
**UI hint**: yes

Plans:
**Wave 1**

- [x] 06-01-PLAN.md — Packages & reproducibility: install.sh PACMAN/AUR arrays (13 official + 3 AUR-gated) + swayosd libinput service + stow.sh swayosd package [wave 1]
- [x] 06-02-PLAN.md — Themed render-target registration: 4 matugen templates (hyprlock/swayosd/zen/satty) + config.toml + contract.json 13→17 + commit.sh satty symlink [wave 1]
- [x] 06-03-PLAN.md — wlogout redesign: center-bar HUD with Nerd Font glyphs, SVG icons deleted (WLOG-01) [wave 1]

**Wave 2** *(blocked on Wave 1)*

- [x] 06-04-PLAN.md — hyprlock redesign: info-rich lock (avatar/now-playing/battery/capslock/failed-attempts), dedicated target, FIX-02 preserved, lockout-recovery checkpoint (LOCK-01) [wave 2]
- [x] 06-05-PLAN.md — Screenshot suite: hyprshot→satty capture, gpu-screen-recorder + audio picker, GIF export, Print-key family, old screenshot.sh deleted (SHOT-01/02/03) [wave 2]
- [x] 06-07-PLAN.md — Icon-theme axis: fzf-in-kitty picker, state-driven gtk-icon-theme-name, papirus-folders/variant swap, Pitfall-6 fix (UTIL-04) [wave 2]

**Wave 3** *(blocked on Wave 2)*

- [x] 06-06-PLAN.md — SwayOSD + Zen surfaces: bottom-center pill on media keys, reload.sh swayosd+zen fan-out, Zen userChrome self-heal notify-only (OSD-01, THM-05) [wave 3]
- [x] 06-08-PLAN.md — Font axis: lib/font.sh render, kitty/vscodium/GTK/waybar wire-up, fzf-in-kitty font switcher (UTIL-05) [wave 3]

**Wave 4** *(blocked on Wave 3)*

- [x] 06-09-PLAN.md — Utility pickers: emoji (wtype+copy), color (hyprpicker+swatch), clipboard cap+wipe policy, X/Z utility chords (UTIL-01/02/03) [wave 4]

**Gap closure** *(verification found 4 blockers CR-01..CR-04 + 4 warnings — SHOT-03/UTIL-04/UTIL-05 disputed)*

- [x] 06-10-PLAN.md — CR-02 picker keybinds get floating-kitty wrappers + windowrules; CR-01 remove waybar font-family literal (waybar-font.css sole owner); WR-07 theme-doctor presence-checks font fragments (UTIL-04/UTIL-05) [wave 1]
- [x] 06-11-PLAN.md — CR-03 record-toggle region flag (`-w region -region`); WR-06 capture-*.sh missing-tool guards; WR-05 color-picker success-exit fix (SHOT-03) [wave 1]
- [x] 06-12-PLAN.md — CR-04 install.sh cleanup uses $AUR_HELPER (yay-safe); WR-01 hyprlock placeholder color via render target (LOCK-01 caveat) [wave 1]

**Gap closure round 2** *(re-verification found 1 blocker — OSD-01/Truth #3: swayosd-server never launched, libinput backend on wrong bus)*

- [x] 06-13-PLAN.md — OSD-01: launch swayosd-server in autostart.conf; install.sh enables swayosd-libinput-backend on system bus (sudo, non-silenced); reload.sh restarts swayosd-server not the wrong-bus backend (OSD-01) [wave 1]

**Gap closure round 3** *(UAT Test 2 found 3 diagnosed gaps in the Print-key screenshot/recording suite)*

- [x] 06-14-PLAN.md — Print-key family rebound by keycode (`code:107`, fixes Alt→Sys_Req miss); capture-{region,full,window}.sh switch broken `-r` → `--raw` (hyprshot getopt bug), restoring the satty save flow to ~/Pictures/Screenshots (SHOT-01/02/03) [wave 1]
- [x] 06-15-PLAN.md — install.sh reproducibility: add vlc + vlc-plugins-all (gpu-screen-recorder codecs) + xdg-user-dirs to PACMAN_PKGS (SHOT-03) [wave 1]

**Gap closure round 4** *(round-4 verification + fresh code review: 1 blocker (CR-01, WLOG-01 — wlogout renders completely unthemed) + 6 carried warnings; blocker survived 4 rounds because every round grep-checked instead of parsing)*

- [x] 06-16-PLAN.md — WLOG-01 blocker, both defects: delete the 8 GTK3-invalid generated-content rulesets that make GTK discard the ENTIRE wlogout stylesheet, AND populate the six `layout` `text` fields with Nerd Font glyphs (D-10 was only half-implemented — SVGs deleted, glyphs never added). D-09 hover-label deliberately dropped: GTK3 has no generated content and wlogout gives each button one text slot, so D-09 and D-10 are mutually exclusive (WLOG-01) [wave 1]
- [x] 06-17-PLAN.md — Utility-script warnings: WR-01 color-picker classifies failures by stdout (hyprpicker never writes stderr) so real failures stop taking the silent-cancel path; WR-02 clipboard-wipe survives an empty cliphist db under `set -e`; WR-04 trap-based mktemp cleanup in both fzf pickers; WR-05 record-toggle's pgrep/pkill bounded to argv[0] so sibling GSR binaries can't invert the toggle or be killed (UTIL-02/03/04/05, SHOT-03) [wave 1]
- [x] 06-18-PLAN.md — Theme-engine warnings: WR-03 remove the `|| echo 0` idiom whose two-line `0\n0` turns the Zen installs.ini `-eq` test into an arithmetic abort; WR-06 add `--exclude=walker-relaunch.log` to commit.sh's rsync `--delete` (6th recurrence of this bug class) (THM-05) [wave 1]
- [x] 06-19-PLAN.md — Regression guard: theme-doctor runs all 9 pipeline-owned GTK stylesheets (6 GTK3 + 3 GTK4) through a REAL GTK CSS parser, asserting a non-empty provider (the discard signature a grep can't see) and zero fatal errors; headless-safe, deprecation-tolerant, and proven to fail on a poisoned sheet (WLOG-01) [wave 2, depends on 06-16]

### Phase 7: Super-Key Menu

**Goal**: Tapping $SUPER alone opens an Omarchy-style walker menu that wraps the new utilities and system actions into a coherent hierarchical menu — without breaking any existing keybind.
**Depends on**: Phase 6 (the Utilities submenu wraps the utility scripts; power/settings reference existing tools)
**Requirements**: MENU-01, MENU-02, MENU-03, MENU-04, MENU-05, MENU-06, MENU-07
**Success Criteria** (what must be TRUE):

  1. Tapping $SUPER alone opens the main walker menu with custom icons, while every existing $SUPER+key combo still works — proven by a full keybind regression sweep and an exit-bind tested first in isolation.
  2. The Utilities submenu launches each utility script (screenshot, emoji, color picker, clipboard, icon theme, font switcher).
  3. The Power menu offers lock/logout/suspend/reboot/shutdown, and the Settings menu launches theme switch / wallpaper / network tools.
  4. The AI dashboard opens a submenu of AI app launchers plus a dedicated pre-configured Hyprland AI workspace, and the Game center opens a launcher submenu (Steam etc.).
  5. A searchable keybind cheat-sheet generated from keybinds.conf is reachable from the menu.

**Plans**: 5/8 plans executed
**UI hint**: yes

Plans:
**Wave 1**

- [x] 07-01-PLAN.md — Menu engine: D-05 spike of the elephant `menus` provider (closes RESEARCH Open Q1/Q2), new `elephant/` stow package, `elephant-restart.sh`, walker `[sets.menu]` (MENU-01) [wave 1]
- [x] 07-02-PLAN.md — Keybind safety foundation: D-03 kill-bind proven in isolation FIRST, D-30 description back-fill on every bind, `keybind-doctor` rerunnable regression gate (D-04) (MENU-01/MENU-07) [wave 1]
- [x] 07-03-PLAN.md — Reproducibility: 8 official + 2 human-gated AUR packages, idempotent multilib enablement for Steam (new territory), ollama enabled with no model pull, container gate green (MENU-03/MENU-04) [wave 1]

**Wave 2** *(blocked on Wave 1)*

- [x] 07-04-PLAN.md — Headline risk: additive `bindr` Super-tap bind, live-keypress shadowing proof (closes Assumption A2), launcher relocated to Super+Space, full regression sweep (MENU-01) [wave 2, depends on 07-01, 07-02]
- [x] 07-05-PLAN.md — Core menu tree: 6-entry root (Power last), Utilities + Screenshot submenus, 9-entry Settings, `nmtui-launch.sh`, `powermenu.sh` DELETED (D-20) (MENU-02/MENU-05/MENU-06) [wave 2, depends on 07-01]

**Wave 3** *(blocked on Wave 2)*

- [ ] 07-06-PLAN.md — AI dashboard: Zen web-app windowrules (title-regex; Zen collapses all WM_CLASS to `zen`), idempotent `ai-workspace.sh` (D-24), 7-entry submenu (MENU-03) [wave 3, depends on 07-03, 07-05]
- [ ] 07-07-PLAN.md — Game center: 4 launchers + runtime-only reversible gaming-mode toggle, session reset-to-OFF (D-28 forecloses the never-locks failure mode) (MENU-04) [wave 3, depends on 07-03, 07-05]

**Wave 4** *(blocked on Wave 3)*

- [ ] 07-08-PLAN.md — Keybind cheat-sheet: one shared display-only parser (V5 control), walker searchable list + kitty "View all" table, live-parsed on every open (MENU-07) [wave 4, depends on 07-02, 07-04, 07-05]

### Phase 8: Waybar Evolution

**Goal**: Waybar gains OLED-safe behavior, an additional vertical layout, an integrated media center, and one-click access to the notification center — all still driven by the shared theme pipeline.
**Depends on**: Phase 4 (stable base); architecturally independent of the theming and menu work, so it may be pulled earlier if desired.
**Requirements**: BAR-01, BAR-02, BAR-03, BAR-04, BAR-05
**Success Criteria** (what must be TRUE):

  1. Waybar behaves OLED-safely — it auto-hides when idle/unneeded and uses translucent minimal styling, with a best-effort pixel-shift mitigation for static elements (or a documented descope with evidence if infeasible).
  2. An additional vertical (left) waybar layout exists and re-themes correctly through a theme switch (full module re-test, not copy-paste).
  3. A media center integrating mpris players (Spotify, browser/YouTube) is accessible from waybar, in the form factor chosen per modern-rice research.
  4. A waybar button opens the swaync notification center overlay to view, clear, and interact with notifications.

**Plans**: TBD
**UI hint**: yes

## Progress

| Phase | Milestone | Plans Complete | Status | Completed |
|-------|-----------|----------------|--------|-----------|
| 1. Root-Cause Fix & Consolidated Theme Engine | v1.0 | 3/3 | Complete | 2026-07-07 |
| 2. Static ↔ Dynamic Parity & Switch Reliability | v1.0 | 2/2 | Complete | 2026-07-07 |
| 3. Repo Cleanup & Fresh-Install Reproducibility | v1.0 | 4/4 | Complete | 2026-07-08 |
| 4. Reliability Fixes & Tech Debt | v2.0 | 6/6 | Complete    | 2026-07-11 |
| 5. Light Mode Pipeline & Theme Presets | v2.0 | 5/5 | Complete    | 2026-07-11 |
| 6. Themed Surfaces & Utility Suite | v2.0 | 19/19 | Complete    | 2026-07-13 |
| 7. Super-Key Menu | v2.0 | 5/8 | In Progress|  |
| 8. Waybar Evolution | v2.0 | 0/TBD | Not started | - |
| 9. wlogout to wleave Migration | v2.0 | 0/TBD | Not started | - |

### Phase 9: wlogout to wleave Migration

**Goal**: Replace wlogout with wleave (GTK4) as the power menu, eliminating the GTK3 whole-stylesheet-discard failure class that produced the WLOG-01 blocker, and moving onto an actively-maintained tool — with no regression to the Phase 6 center-bar design.
**Requirements**: WLOG-01 (re-delivered on a new engine)
**Depends on:** Phase 8
**Plans:** TBD

**Why this phase exists** (decided 2026-07-13, after Phase 6's wlogout work):

- **The real driver is the failure class, not the blur.** Verified live on this machine: GTK3 discards an *entire* stylesheet on a single invalid rule, whereas GTK4 skips the offending rule and retains the rest. WLOG-01 — six unstyled buttons — was exactly this: eight invalid `::after`/`content` rules nuked the whole sheet. On GTK4 that bug is structurally impossible. wleave 0.7.1 is GTK4 (`gtk4-layer-shell`, `libadwaita`); wlogout is GTK3 and largely unmaintained.
- **This phase will NOT fix wlogout's blur limitation.** Blur *strength* is `decoration:blur` in hyprland.conf, which is global. Hyprland 0.55.4's layerrule set (blur, blurpopups, ignorealpha, ignorezero, dimaround, xray, animation, order, abovelock) has no size/passes rule, so no layer-shell client — wlogout or wleave — can have its own blur strength. Do not plan this phase expecting to gain that.

**Carry these Phase 6 findings into planning — all three cost a cycle to discover:**

1. GTK applies `min-width`/`min-height` to the **content box**; padding and border are *added*. A "72px" button with 10px padding and a 3px border is **98px** on screen. Size the layer-shell window to the outer box or the buttons get clipped. `scripts/wlogout.sh` derives this rather than hardcoding it — carry that forward.
2. GTK does **not** vertically centre text inside a button label, and CSS has no `valign`. Phase 6 measured a +14.5px offset and corrected it with `margin-bottom: 16px` on the label. Re-measure on GTK4 — it may not be needed, and must not be copied blindly.
3. Every automated gate in Phase 6 (CSS parse, shellcheck, code review, theme-doctor) passed while the surface was visibly broken on screen. **This phase needs a render-and-look check, not just a parse check.**

**Migration surface** (touch-points inventoried during Phase 6):
`wlogout/` stow package, `matugen` render target + `contract.json` entry, `theme-doctor`'s CSS-sheet list, the layout file format, `layerrule` namespace (`logout_dialog` → wleave's), `scripts/wlogout.sh`, keybinds, `install.sh`, `stow.sh`.

Plans:

- [ ] TBD (run /gsd-plan-phase 9 to break down)
