---
quick_id: 260828-ah9
date: 2026-08-28
status: decisions-locked
study_artifact: https://claude.ai/code/artifact/b39dc089-7b96-4dd8-a852-0a40eea9297d
study_vendored: .planning/notes/appearance-picker-studies.html
---

# Context — Appearance pickers as QML surfaces

Operator decisions, taken against **Appearance Picker Studies** (published and
vendored). These are LOCKED — do not revisit them during planning or execution.

## What the request actually replaces

There are already two pickers per axis. The QML `SelectRow`s in
`Settings > Appearance` exist and work (`AppearancePage.qml:143/:168/:206/:231`),
reading each script's `--list` and writing through its `--set`. They show a
**name only**.

What has no QML equivalent is the part worth opening: the montage icon grid and
the live font specimen inside `icon-theme-picker.sh` / `font-switcher.sh`. That
is the thing being replaced. The `--list` / `--set` contract already exists and
is proven, so the backend is not new work.

## The two measurements that shape the build

**M1 — three of eight icon themes render an identical grid.** `Papirus`,
`Papirus-Dark` and `Papirus-Light` are byte-identical (same MD5) at every 48x48
icon probed: `folder`, `utilities-terminal`, `user-trash`,
`system-file-manager`. The variants override only small glyphs — `Papirus-Dark`
ships its own 16/18/22/24px `actions,devices,places`; `Papirus-Light` its own
16/22/24px `panel,animations`. Neither touches 48px.
→ **A 48px app-icon grid cannot distinguish them. Preview at 22px.**

**M2 — 13 of 39 font entries are metrically identical twins.** 39 names = 13
families x {`Nerd Font`, `Nerd Font Mono`, `Nerd Font Propo`}. Advance widths
read straight from the TTFs (fontTools `hmtx`/`head`, advance / unitsPerEm) at
U+0041, U+F07B, U+E0B0, U+F0A0, U+E30D across FiraCode, JetBrainsMono, Hack,
Iosevka, CaskaydiaCove, MesloLGS: **`Nerd Font` and `Nerd Font Mono` are
identical on every probe.** Only `Propo` differs, and only on icon glyphs
(0.92em vs the 0.5-0.62em cell). fontconfig agrees — `Propo` reports no
`spacing`, the other two report `100`.
→ **Collapse the duplicate cut. Offer 13 families x 2 spacing behaviours.**

Scope note on M2: 5 code points, 6 of 13 families. Stated as measured, not
generalised beyond that.

**M3 — no icon name exists in all eight themes.** Adwaita is symbolic-first and
ships no `utilities-terminal`, `text-editor` or `system-file-manager` under
those names (3 of 6 probes missing); AdwaitaLegacy is PNG-only; breeze has no
`firefox`/`text-editor`. Any grid needs a per-cell fallback chain, and coverage
is information to show, not hide.

## Decisions

**D1 — Build BOTH Specimen and Atelier.**
- *Specimen*: two launcher routes, `icon` and `font`, on the `WallpaperMode.qml`
  pattern — the typed path.
- *Atelier*: one `FloatingWindow` with `Icons | Fonts | Catalogue` tabs on the
  `Workbench.qml` pattern — the keybind path, and the home for D4.

**D2 — Keybind package B.**
| Chord | After | Was | Note |
|-------|-------|-----|------|
| `Super+I` | Atelier, Icons tab | code editor | code editor moves to `Super+Shift+I` (free) |
| `Super+Shift+F` | Atelier, Fonts tab | toggle maximize | maximize moves to `Super+Shift+M` (free) |
| `Super+F` | **unchanged** — fullscreen | | never moved; it is the most reflexive bind on the machine |
| `Super+Shift+Z` | retired | icon picker | script surface being removed |
| `Super+Shift+X` | retired | font switcher | script surface being removed |

Keybinds open the **window**, not the route — mirroring `Super+P` →
`qs ipc call packages-window open` (`keybinds.lua:198`), which is the shipped
precedent for a route+window pair. Both new binds must be added to
`ACCEPTED_BIND_ADDITIONS`, and the two relocations to the equivalence gate's
accepted set, or `hypr-equivalence-check` red-lights.

**D3 — Strip the interactive half of both scripts.**
Delete the fzf / kitty-graphics / montage code and the `icon-theme-picker` and
`font-switcher` window rules in `windowrules.lua:112`/`:121`. **Keep `--list`,
`--set` and `_persist_and_apply()`** — the QML calls them, and that tail owns
the state write, the VSCodium settings merge and the `theme-apply` re-run.
Remove the two `MenuTree.qml` leaves (`:155`, `:159`) or repoint them at the new
IPC.

**D4 — Catalogue install IS in scope, now.**
The `Ctrl-A` repo/AUR browse in `icon-theme-picker.sh` becomes the Atelier's
third tab, with a real progress log. This is why Atelier is being built
alongside Specimen — neither Specimen nor Overlay has room for it.
**Consequence to record:** this consumes the standing v5.0 ICON-BROWSE
candidate in `ROADMAP.md`; that row must be struck with a pointer here, the way
the walker/elephant candidate was struck on 2026-08-27.

## Constraints carried in

- `colour-lint` (GATE-04) rejects hardcoded colours in QML — read `Colours.qml`.
- Any command that must outlive the surface uses `Quickshell.execDetached`.
- Click-outside dismissal needs `HyprlandFocusGrab`; `follow_mouse=1` makes
  Qt's `Window.active` a hover signal.
- Icon previews load real theme files; `libqsvg.so` is present so `.svg` renders,
  but `AdwaitaLegacy` is PNG-only — handle both.
- Do not restart quickshell from the agent shell. Hand live checks to the
  operator.
