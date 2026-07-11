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
- [ ] **Phase 5: Light Mode Pipeline & Theme Presets** - Extend the theme pipeline to light mode, ship more presets (incl. light), and organize per-theme wallpapers behind a redesigned picker
- [ ] **Phase 6: Themed Surfaces & Utility Suite** - Redesign and re-theme wlogout, hyprlock, SwayOSD and Zen, and ship the full screenshot + emoji/color/clipboard/icon/font utility suite
- [ ] **Phase 7: Super-Key Menu** - $SUPER-tap opens an Omarchy-style walker menu wrapping utilities, power, settings, AI dashboard, game center, and a searchable keybind cheat-sheet
- [ ] **Phase 8: Waybar Evolution** - OLED-safe waybar with an additional vertical layout, mpris media center, and one-click notification-center access

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

**Plans**: 5 plans (4 complete + 1 gap-closure)
**Wave 1**

- [x] 04-01-PLAN.md — FIX-01 wlogout shutdown/reboot hang: diagnose (keyboard-vs-mouse, journalctl/coredumpctl), apply uwsm-correct session actions; DEBT-01 rsync in PACMAN_PKGS [wave 1]
- [x] 04-02-PLAN.md — FIX-02 hyprlock first-keystroke drop: confirm #423 grace double-unlock signature, apply grace=0, lockout-recovery procedure [wave 1]
- [x] 04-03-PLAN.md — FIX-03 profile kitty/shell startup (zprof/hyperfine/fastfetch --stat), optimize zsh (local oh-my-posh, lazy nvm/bun, zinit turbo, fastfetch trim) [wave 1]

**Wave 2** *(blocked on Wave 1 completion)*

- [x] 04-04-PLAN.md — FIX-03 benchmark optimized zsh vs fish, user decision, optional full fish adoption via kitty.conf/install.sh/stow [wave 2]

**Gap closure** *(verification found fish node tooling non-functional — CR-01)*

- [ ] 04-05-PLAN.md — FIX-03 gap: fix fish nvm activation (explicit `nvm use` in config.fish; conf.d loads before config.fish) + document one-time `nvm install v24.18.0` provisioning [wave 1]

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

**Plans**: TBD
**UI hint**: yes

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

**Plans**: TBD
**UI hint**: yes

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

**Plans**: TBD
**UI hint**: yes

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
| 4. Reliability Fixes & Tech Debt | v2.0 | 4/4 | Complete   | 2026-07-11 |
| 5. Light Mode Pipeline & Theme Presets | v2.0 | 0/TBD | Not started | - |
| 6. Themed Surfaces & Utility Suite | v2.0 | 0/TBD | Not started | - |
| 7. Super-Key Menu | v2.0 | 0/TBD | Not started | - |
| 8. Waybar Evolution | v2.0 | 0/TBD | Not started | - |
