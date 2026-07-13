---
phase: 07-super-key-menu
plan: 08
subsystem: ui
tags: [walker, kitty, hyprland, keybinds, cheat-sheet, nerd-font, ansi]

# Dependency graph
requires:
  - phase: 07-02
    provides: keybinds.conf fully description-backfilled (77/77, D-30) — the cheat-sheet's only source
  - phase: 07-04
    provides: the three new Phase 7 binds (Super+Space, Super-tap, Super+Escape)
  - phase: 07-05
    provides: root menu's "Keybinds" entry (a deliberate forward reference to this plan's script)
provides:
  - cheat-sheet-parser.sh — the single shared, display-only keybinds.conf parser (D-29)
  - cheat-sheet.sh — walker searchable list, "View all" pinned first
  - cheat-sheet-view-all.sh — themed kitty reference card (ASCII banner, keycaps, section icons)
affects: []

tech-stack:
  added: []
  patterns:
    - "Config text is DISPLAY DATA, never code: parse with bash's own [[ =~ ]] and emit with printf '%s' — never re-interpret a config DSL as shell to 'resolve its variables'"
    - "Theme-for-free via ANSI palette indices (0-15): a surface rendered inside kitty inherits the matugen palette with no new template, no contract.json entry, and no parity-gate surface"
    - "Glyphs resolved from the INSTALLED font's cmap AND hmtx advance width — presence is not enough; a double-width glyph silently breaks every aligned border"
    - "Never measure a string containing ANSI escapes: keep a plain twin (CAP_PLAIN) for width maths and a coloured twin (CAP_COLOR) for output"

key-files:
  created:
    - hypr/.config/hypr/scripts/cheat-sheet-parser.sh
    - hypr/.config/hypr/scripts/cheat-sheet.sh
    - hypr/.config/hypr/scripts/cheat-sheet-view-all.sh
  modified:
    - hypr/.config/hypr/config/windowrules.conf
    - elephant/.config/elephant/menus/main.toml
  deleted: []

requirements-completed: [MENU-07]

verification:
  - claim: "77/77 parity — the parser emits exactly one row per declared bind, no malformed rows"
    ref: "cheat_sheet_parse_binds | wc -l == grep -cE '^\\s*bind[a-z]*\\s*=' keybinds.conf; awk NF!=3 check empty"
    status: pass
  - claim: "Config text is inert: a command-substitution payload in a bind description does not execute"
    ref: "Appended `# $(touch /tmp/PWNED) `touch /tmp/PWNED2`` to a copy; row rendered LITERALLY, neither file created. Re-run after every later parser edit."
    status: pass
  - claim: "Both surfaces share ONE parser (D-29) — they cannot disagree"
    ref: "cheat-sheet.sh and cheat-sheet-view-all.sh both `source cheat-sheet-parser.sh`; no second extraction regex exists"
    status: pass
  - claim: "D-31 live parse — a bind added to keybinds.conf appears with no regeneration step"
    ref: "Temp bind appended, appeared immediately; removed, vanished; keybinds.conf left byte-identical"
    status: pass
  - claim: "Every glyph exists in the installed font AND is exactly 1.00 cells wide"
    ref: "fontTools cmap + hmtx advance check against FiraCodeNerdFont-Regular.ttf; all == 1.00 x 'M'. U+229E (⊞) ABSENT — U+F17A used for Super instead."
    status: pass
  - claim: "Reference card borders align"
    ref: "ANSI-stripped border-glyph column positions collapse to exactly 8 distinct columns (4 panels x 2 edges)"
    status: pass
  - claim: "'View all' is the first row, and pinning it did not desync the chord lookup"
    ref: "walker/wl-copy stubbed: row 1 == View all; rows 2/5/8 each still copy their own chord"
    status: pass
  - claim: "Human verification of both surfaces"
    ref: "Human confirmed the walker list and kitty card on the live desktop, then approved the redesign and font scaling after a reboot"
    status: pass

duration: ~90min (executor + three rounds of checkpoint-driven redesign)
completed: 2026-07-14
status: complete
---

# Phase 07 Plan 08: Keybind Cheat-Sheet Summary

## Accomplishments

- **MENU-07 delivered** — the last requirement in Phase 7. Two surfaces over one shared, display-only parser: a walker searchable list and a themed kitty reference card, both live-parsed from `keybinds.conf` on every open (D-31), with no side-car description file anywhere (D-30).
- **Security held under adversarial test.** A command-substitution payload in a bind description renders as literal text and does not execute — re-verified after *every* subsequent parser edit, not just once.
- **The card was redesigned three times against live human feedback**: flat table → reference card → ASCII banner + keycaps + section icons → soft chips → no fill at all. Final form: bold accent glyphs joined by a dim `+`, rounded section panels with Nerd Font icons, an ANSI-Shadow `KEYBINDS` banner, masonry-packed into as many columns as the window fits.

## Notable Findings

**Theming for free.** Every colour is an ANSI palette index (0–15), which kitty resolves against its own matugen-rendered palette. The card therefore re-themes on every theme switch with **no new matugen template, no `contract.json` entry, and no new parity-gate surface** — the payoff for rendering inside kitty rather than building another GTK surface.

**Glyph presence is not enough — advance width matters.** Every codepoint was checked against the installed FiraCode Nerd Font for cmap presence *and* `hmtx` advance width (all exactly 1.00 cells). This font is the non-Mono variant, where a double-width icon would have silently shifted every box border. `U+229E (⊞)`, the natural Super symbol, is **absent from the font** — `U+F17A` is used instead, rather than shipping a tofu box. This is Phase 6's rule applied: resolve glyphs from the installed font, never from a cheat-sheet copy.

**Raw PUA glyph literals do not survive being written to a file.** `_cs_icon` was silently emitting **zero bytes** for every section, so each icon contributed 0 columns instead of 1 and dragged every panel's right border one column left. Caught only because border positions were checked *programmatically* — the check reported **21 distinct border columns** where a clean 4-panel grid must have exactly 8. Codepoints are now `\uXXXX` escapes. A second, independent off-by-one sat on top of it (title pad `inner-4` where the line needs `inner-3`). Eyeballing the render would have missed both.

**Section banners were leaking planning metadata into the UI** — `Escape hatch (D-03)`, `Utilities (D-32 — freed X/Z family, MENU-07 cheat-sheet source)`. A display-only cleanup strips a trailing parenthetical **only** when it carries a decision/requirement ID or is a multi-clause note, so a genuinely useful one survives: `Special workspace (scratchpad)` is intact. `keybinds.conf` itself is untouched — presentation, not a rewrite.

**Font size is now derived from the display**, not hardcoded: the focused monitor's *logical* height (physical ÷ scale, clamped 12–22), so a 2160px panel at scale 2 correctly gets 12 rather than 21. Safe to enlarge because the renderer computes its column count from the real terminal width — a bigger font yields fewer columns (4 → 3 → 2), never a clipped grid.

## Issues Encountered

**I crashed the user's Hyprland session.** While spawning and killing throwaway kitty windows to measure real terminal geometry for the font-scaling change, Hyprland 0.55.4 segfaulted — `SIGSEGV` in `CWorkspace::isVisible()` via `CWindow::unmapWindow → CLayoutManager::newTarget → CWindow::moveToWorkspace` (an upstream null-deref on window unmap, `hyprlandCrashReport906.txt`). It auto-restarted into `--safe-mode`, which ignores the user's config entirely and loads a minimal default — presenting as 48 unfamiliar `__lua` binds, `rounding=10`, and config edits having no effect. Considerable time was then wasted chasing a phantom "config error at line 2" that was safe-mode noise.

Two lessons, both recorded because they generalise:
- **Do not spawn/kill windows on a live desktop to measure something.** The geometry could have been derived from `hyprctl monitors` arithmetic. The pinned-row change later in this plan was verified by *stubbing* `walker`/`wl-copy` — no compositor involvement — which is the pattern to follow.
- **An unscoped `sed` is a footgun.** `sed -i 's/size = 85% 85%/.../'` also resized `wallpaper-picker`, `icon-theme-picker`, `font-switcher` and `network-manager`. Reverted. Target the block, not the string.

Recovery required a reboot (safe mode cannot be exited by `hyprctl reload`). Post-reboot state verified clean: 77/77 binds, keybind-doctor 8 passed / 0 failed, themed `rounding=12`, zero config errors. No config was lost — the whole `hypr/` tree was byte-identical to its committed state throughout.

## Next Phase Readiness

Phase 7 is complete: MENU-01 … MENU-07 all delivered. Phase 8 (Waybar Evolution) is next and owns the waybar surface — including `gaming-mode-toggle.sh`'s waybar hide/show, which is marked in-script as Phase 8's re-point target, and the D-27 gaming-mode indicator that can read `~/.cache/gaming-mode`.

---

*Completed: 2026-07-14*
