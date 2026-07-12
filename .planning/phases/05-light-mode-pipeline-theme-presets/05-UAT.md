---
status: complete
phase: 05-light-mode-pipeline-theme-presets
source: [05-01-SUMMARY.md, 05-02-SUMMARY.md, 05-03-SUMMARY.md, 05-04-SUMMARY.md]
started: 2026-07-12T03:10:00Z
updated: 2026-07-12T03:25:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Wallpaper picker preview pane quality
expected: Open the wallpaper picker in the floating kitty window. Preview pane renders wallpapers pixel-perfect via kitty graphics (kitten icat), updates cleanly as you move through the list (no ghost/stacked images), shows a metadata line (filename / resolution / size), and the currently active wallpaper carries an active indicator.
result: pass
coverage_id: 05-04 D2

### 2. Per-theme restriction, Ctrl-A browse-all, fall-open header
expected: With a static theme applied (e.g. catppuccin), the picker lists only that theme's wallpaper folder; Ctrl-A expands to browse all wallpapers. For a static theme with an empty folder (e.g. a fresh light preset), the picker falls open to all wallpapers with a visible header explaining why. Under materialyou/materialyou-light, browsing is unrestricted from the start.
result: pass
coverage_id: 05-04 D3

### 3. Last-used wallpaper survives theme switches (post CR-01 fix)
expected: Pick a non-default wallpaper for theme A via the picker. Switch to theme B (`theme-apply B` or the switcher), then switch back to theme A. Theme A restores the wallpaper you picked — not the first-sorted image in its folder. Re-applying the same theme also keeps your pick.
result: pass
coverage_id: VERIFICATION gap / CR-01

### 4. Theme switcher cancel vs failure (post WR-04 fix)
expected: Open the theme switcher keybind and press Esc without selecting anything. It closes silently — no error notification (cancel is not treated as failure). Selecting a theme still applies it normally.
result: issue
reported: "An error notifications still appears"
severity: major
coverage_id: WR-04

### 5. materialyou-light renders distinct light output
expected: materialyou-light is a valid theme-apply argument and renders genuinely different output than materialyou; mode markers read dark/light respectively.
result: pass
source: automated
coverage_id: 05-01 D1

### 6. Static-preset render never passes mode flag to matugen
expected: Static-preset render branch never passes a mode flag to matugen json (Pitfall 1 regression guard); mode computed separately via mode.sh.
result: pass
source: automated
coverage_id: 05-01 D2

### 7. gtk.sh flips color-scheme/theme from committed mode marker
expected: gsettings color-scheme/gtk-theme/GTK_THEME follow the committed mode marker; settings.ini symlinks resolve into the state dir; git status stays clean after theme-apply.
result: pass
source: automated
coverage_id: 05-01 D3

### 8. Contract + theme-parity extended with settings.ini targets
expected: contract.json/theme-parity include both settings.ini targets (ini-kv) and mode state metadata; single-target parity run exits 0.
result: pass
source: automated
coverage_id: 05-01 D4

### 9. 9 Omarchy-lineup dark presets pass schema + parity
expected: matte-black, osaka-jade, ristretto, everfrost, kanagawa, hackerman, miasma, ethereal, vantablack exist as palette JSONs matching the 20-key schema; each passes theme-parity.
result: pass
source: automated
coverage_id: 05-02 D1

### 10. 5 canonical light presets pass schema + parity
expected: catppuccin-latte, rosepine-dawn, gruvbox-light, tokyonight-day, kanagawa-lotus exist as standalone palette JSONs matching the schema; each passes theme-parity.
result: pass
source: automated
coverage_id: 05-02 D2

### 11. Mode auto-detection 20/20 correct
expected: theme_engine_detect_mode classifies all 20 palettes correctly (5 light, 15 dark), no override key needed.
result: pass
source: automated
coverage_id: 05-02 D3

### 12. Full theme-parity covers all 22 targets with mode fixtures
expected: No-arg theme-parity covers every palette plus materialyou/materialyou-light (22 targets, 1102+ checks, 0 failed) and asserts dark + light fixtures.
result: pass
source: automated
coverage_id: 05-02 D4

### 13. theme-stress-test enumerates presets dynamically
expected: Stress test enumerates static presets from palettes/*.json and alternates materialyou with materialyou-light on even positions.
result: pass
source: automated
coverage_id: 05-02 D5

### 14. Walker theme picker offers all 22 entries
expected: theme-switch.sh offers every palette plus both Material You entries (22 total), no hardcoded case ladder.
result: pass
source: automated
coverage_id: 05-02 D6

### 15. Legacy themes/ stow package deleted
expected: themes/ package removed from repo and stow.sh; no references to the legacy config path remain; live symlink removed.
result: pass
source: automated
coverage_id: 05-02 D7

### 16. Wallpaper folders 1:1 with palette names
expected: Folders renamed to strict 1:1 correspondence with palette names, plus dracula/ and 5 light-variant folders with .gitkeep.
result: pass
source: automated
coverage_id: 05-03 D1

### 17. Wallpaper autoset on static theme-apply
expected: Autoset applies last-used-first, first-in-folder fallback, keep-current on empty folder, and no-ops for materialyou variants.
result: pass
source: automated
coverage_id: 05-03 D2

### 18. fzf-colors.conf as 13th contract file
expected: fzf-colors.conf renders as first-class env-kv contract file (12 hex slots + one -1 literal), validated by theme-parity across all themes (1190 checks, 0 failed).
result: pass
source: automated
coverage_id: 05-04 D1

## Summary

total: 18
passed: 17
issues: 1
pending: 0
skipped: 0
blocked: 0

## Gaps

- truth: "Pressing Esc in the theme switcher closes it silently — no error notification; cancel is not treated as failure"
  status: failed
  reason: "User reported: An error notifications still appears"
  severity: major
  test: 4
  root_cause: ""     # Filled by diagnosis
  artifacts: []      # Filled by diagnosis
  missing: []        # Filled by diagnosis
  debug_session: ""  # Filled by diagnosis
