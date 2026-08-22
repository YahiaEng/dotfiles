---
title: Launcher QML migration — measured scope, reference research and design decisions
date: 2026-08-22
context: Pre-execution exploration for retiring walker+elephant into a native Quickshell launcher; reverses the deferral recorded at PROJECT.md:146
status: input to /gsd-quick (standalone task before v5.0 scoping)
sketch: https://claude.ai/code/artifact/e4522757-3067-4547-91dd-00b2879cd6a5
---

# Launcher QML migration — scope, research & decisions

Everything under "Measured" was read off this host or out of this repo.
Everything under "Researched" carries its disposition — admitted claims name a
primary source, unresolved ones stay unresolved and must not be restated as
fact downstream.

**Visual decision record:** the three candidate shapes, the mode gallery and the
full taxonomy remap are drawn at true proportion in the live palette at the
`sketch:` URL above.

---

## What this reverses

`PROJECT.md:146` recorded, at v4.0 scoping on 2026-08-10, that rebuilding
walker/elephant in QML was **explicitly out of scope**, deferred with the words
*"a v5.0+ question."* `.planning/research/FEATURES.md:7` correspondingly
excluded the launcher from the v4.0 reference-shell research, which is why no
design language exists for this surface.

Operator decision 2026-08-22: build it now, as a standalone quick task, **before**
v5.0 is scoped. Full retirement — walker and elephant both uninstalled from repo
and host, matching the RETIRE-01..05 pattern.

---

## Measured — the real surface (2026-08-22)

### Scale

**≈60 files** reference walker outside `.planning/`.

### The five roles walker actually plays

| Role | Detail |
|---|---|
| App launcher | 5 default providers: `desktopapplications`, `calc`, `runner`, `websearch`, `menus` |
| Prefix router | 6 routes: `=` calc, `/` files, `:` clipboard, `.` symbols, `;` providerlist, `@` websearch |
| Menu tree | 6 TOMLs, **36 entries** (`elephant/.config/elephant/menus/`) |
| **`--dmenu` backend** | **7 consumers** — the hidden scope |
| Theme target | `matugen/templates/walker-style.css` → `contract.json`, `reload.sh` (29 refs), `theme-doctor` (18), `theme-stress-test` (11), `commit.sh` (11) |

### The 7 dmenu consumers — the real work

These use walker as *"take a stdin list, return the pick, exit 130 on cancel."*
Each needs a native QML surface **and** a keybind/caller repoint:

1. `hypr/.config/hypr/scripts/theme-switch.sh:52`
2. `hypr/.config/hypr/scripts/emoji-picker.sh:210`
3. `hypr/.config/hypr/scripts/cheat-sheet.sh:46`
4. `hypr/.config/hypr/scripts/clipboard-wipe.sh:26`
5. `hypr/.config/hypr/scripts/record-toggle.sh:193`
6. `hypr/.config/hypr/scripts/bar-orientation.sh:88`
7. `hypr/.config/hypr/config/keybinds.lua:143` — `cliphist list | walker --dmenu | cliphist decode | wl-copy`

`icon-theme-picker.sh` and `font-switcher.sh` are **not** in this list — both
carry header comments stating they deliberately do *not* use the dmenu pattern.
Verify their actual mechanism before touching them.

### Entrypoints to repoint

- `keybinds.lua:55` — `local appLauncher = "walker"`
- `keybinds.lua:58` — `local appLauncherDrun = "walker -m runner"`
- `keybinds.lua:86` — Super tap → `uwsm app -- walker -m menus:main`
- `keybinds.lua:95` — Super+Escape → `pkill walker` (emergency close)
- `keybinds.lua:143` — Super+C clipboard pipeline
- `autostart.lua:163-164` — two processes: `elephant`, `walker --gapplication-service`

### Prior constraint that still binds

`walker -s <set>` **panics** walker 2.16.2 and kills the gapplication service
(`src/data.rs:566`), proven live in the 07-01 D-05 spike. Recorded here only so
the retirement does not resurrect a `sets` table while migrating config.

### Architecture the replacement must match

`shell.qml` is **one `LazyLoader` per surface** — dashboard, panels, overview,
power menu and settings each summon their own. This is *not* Caelestia's
single-shared-window pattern. The launcher gets its own LazyLoader.

### Live theme state at time of writing

Catppuccin Mocha, dark, `FiraCode Nerd Font Mono`. Primary `#cba6f7`,
surface `#1e1e2e`, outline `#585b70` (`~/.local/state/theme/palette.json`).

---

## Researched — Omarchy's menu

Source read directly: `bin/omarchy-menu` (893 lines) via raw.githubusercontent.com.
Researcher tier resolved to `sonnet` (above the budget tier), so the tier floor
did not arm.

**Admitted (primary source: `basecamp/omarchy/bin/omarchy-menu`):**

- The menu is **a single bash script**, not a walker `menus:` provider. A `menu()`
  helper pipes a `\n`-delimited string into `walker --dmenu`, then dispatches the
  returned string via bash `case` glob-matching. Only two leaf pickers (themes,
  unlocks) use the elephant `menus:` provider — the mechanism **this repo's entire
  tree** is built on.
- Ten root entries, verbatim:

DATA_k7Qw2mXf_START
󰀻  Apps
󰧑  Learn
󱓞  Trigger
  Style
  Setup
󰉉  Install
󰭌  Remove
  Update
  About
  System
DATA_k7Qw2mXf_END

- Submenus are separate `show_*_menu()` **bash functions**, not data. Nesting goes
  at least 3 deep (Install → Development → JavaScript → Node.js). A leaf is a
  `case` arm running a command; a submenu is a `case` arm calling another function.
- Back navigation is a `back_to <parent_fn>` helper with a `BACK_TO_EXIT` flag —
  a deep-linked submenu exits rather than chaining back into the full tree.
- **Preselect**: `menu()` computes the line index of the current value (current
  font, current power profile) and passes `-c <index>` to walker to pre-highlight
  it. Plus per-menu `-p` placeholders and Nerd Font glyphs baked into entry strings.
- **No typed-input preservation across levels** — each level is a fresh
  `walker --dmenu` process with no carried buffer.

**Unresolved:** see `research/questions.md`.

### What was taken, and what was not

- **Taken:** the verb-based root taxonomy, the Style/Setup split, preselect-the-
  current-value, per-menu placeholders.
- **Not taken:** Omarchy's package-management roots (`Install` / `Remove`) — that
  is a different product. Its bash architecture is rejected outright; the
  typed-input loss is a *consequence* of shelling out per level, and a native
  tree fixes it by construction.

---

## Researched — reference shell launchers

Source read directly: Caelestia and end-4 QML via raw.githubusercontent.com.

**Admitted:**

| | Caelestia | end-4 |
|---|---|---|
| Window | **Not its own window** — an `Item` in one shared `StyledWindow` (`ContentWindow.qml`, `WlrLayer.Top`) alongside dashboard/session/sidebar/osd | **Dedicated `PanelWindow`** (`quickshell:overview` namespace), all-4-edge anchored, `mask: Region` so only the content column is visible |
| Modes | One surface — `ContentList.qml` swaps `state: "apps"`/`"wallpapers"` | One surface — `LauncherSearch.query` branches by prefix |
| Result layout | **Varies** — apps → `StyledListView`, wallpapers → `PathView` carousel | search → `ListView`; window switcher → hand-positioned `Item`s |
| Fuzzy match | Vendored JS — `fzf.js` / `fuzzysort.js` in `utils/Searcher.qml` | `Fuzzy.go()` + Levenshtein fallback in `AppSearch.qml` |
| App enumeration | Quickshell `DesktopEntries.applications.values` | same |
| Prefix routing | `launcher.actionPrefix` (default `>`) in `stateForText()` | `Config.options.search.prefix.{app,action,clipboard,emojis,math}` |
| Calculator | delegates to Qalculate | spawns `qalc -t <expr>` |

**The one place the house Caelestia-first bias points wrong:** Caelestia folds
the launcher into a shared window; this repo uses one LazyLoader per surface.
**end-4's dedicated-`PanelWindow` shape is the correct model here.**

---

## Decisions

### D-1 — Shape: Option B, one frame with per-mode result views

One QML launcher surface, its own `LazyLoader` + `PanelWindow`. Shared search
field, chrome and motion language; the **results area swaps component per content
type**: rows for apps/menus, grid for emoji/icons, carousel for wallpaper, table
for keybinds, single-result for calc.

*Why:* both reference shells converged on one-surface-many-modes independently,
and Caelestia explicitly breaks to a `PathView` carousel rather than forcing
wallpapers into the app list. Option A (one layout for everything) is
contradicted by both references **and** would silently undo Phase 7's
launcher/menu split. Option C (two products) has no reference precedent.

**Attribution correction (2026-08-22, after Q1 resolved).** The *principle* —
result view varies by content — is reference-backed by Caelestia's carousel/list
split. The specific choice of **grid for emoji is NOT**: end-4 renders emoji in a
plain `ListView`, same as apps, and Caelestia has no emoji surface at all. Grid
is a local design judgment (16 visible vs 4), taken deliberately against the only
available precedent. Recorded so nobody downstream cites a reference for it.

**Phase 7's split is preserved.** `07-DISCUSSION-LOG.md:20-21` records that
Super+Space (launcher) and Super-tap (menu) were separated specifically because
it is *"closest to how Omarchy separates launcher from menu."* That decision
stands; this rebuild does not collapse it.

### D-2 — Menu: verb-based roots, Omarchy-influenced

Driver: the current `Settings` submenu does two unrelated jobs — appearance
(Theme, Wallpaper, Icon theme, Font, Bar orientation) and hardware config
(Network, Bluetooth, Audio, Display). Omarchy splits exactly these into **Style**
and **Setup**. The restructure is justified by an overloaded 10-entry menu that
grew by accretion, not by novelty.

**9 roots. All 36 existing entries re-homed; none dropped.**

| Root | Entries | From |
|---|---|---|
| Apps | Application list | **net-new** (R-3) |
| Capture | Region, Window, Full screen, Record toggle | Utilities ▸ Screenshot |
| Tools | Emoji, Colour picker, Clipboard | Utilities |
| Style | Theme, Wallpaper, Icon theme, Font, Bar orientation | Settings |
| Setup | Settings window, Network, Bluetooth, Audio, Display | Settings |
| Play | Steam, Lutris, Heroic, ProtonUp-Qt, Gaming mode | Game Center |
| AI | Claude, ChatGPT, Gemini, Perplexity, Claude Code, Local models, AI Workspace | AI Dashboard |
| Learn | Keybinds | root leaf |
| System | Power menu, Updates, System info | root leaf + **net-new** (R-1, R-2) |

**Naming:** Omarchy's root is `Trigger`; renamed to **Tools** here. Omarchy's
label is internal vocabulary and does not survive out of its context. Structure
was adopted, labels were not — reversible, it is one string per entry.

### D-3 — Net-new capability ships with the migration

Operator decision 2026-08-22. `PROJECT.md:31` requires additions be minted as
**named requirements at scoping time**, so they are named here rather than
invented during execution:

- **R-1 — System ▸ Updates.** Surface system/package updates from the menu.
- **R-2 — System ▸ System info.** Machine/system information readout.
- **R-3 — Apps root.** An app-list entry reachable from the menu tree, in
  addition to the existing Super+Space launcher bind.

These are the one real capability gap Omarchy exposed. They are **feature work
riding on a migration** — if verification gets noisy, they are the first thing to
cut back to like-for-like.

### D-4 — Provider replacements (verified on this host)

| Provider | Replacement | Status |
|---|---|---|
| `desktopapplications` | Quickshell `DesktopEntries` | **Already in use here** — `NotifCard.qml:243`, `NotifGroup.qml:142` |
| `calc` | `qalc -t` | **Installed** — libqalculate 5.12.0-1; `qalc -t "2+2*10"` → `22`. No new package. |
| `clipboard` | `cliphist` | **Already wired** — `keybinds.lua:143` |
| `menus` | QML tree model | To build — replaces 6 TOML files |
| `runner`, `websearch`, `files`, `symbols` | vendored fuzzy JS | To build — both references vendor `fzf.js`/`fuzzysort.js` |

### D-5 — Emoji and clipboard data sources (research question 1, resolved 2026-08-22)

**Emoji — must ship in-repo. There is no system source.**

- Measured here: **no `/usr/share/unicode/emoji/`, no `emoji-test.txt`, no package
  owns one.** Reading emoji from the system is not an available option without
  adding a package, which touches `install.sh` and fresh-install reproducibility.
- Measured here: the current list is **160 entries hardcoded inline** in
  `emoji-picker.sh` lines 46–205 (`EMOJIS=$'😀\tgrinning face…'`, literal `\t`
  that bash expands at runtime — grep for a real tab returns 0 and is blind).
- Researched (admitted, `end-4/dots-hyprland`
  `dots/.config/hypr/hyprland/scripts/fuzzel-emoji.sh` +
  `dots/.config/quickshell/ii/services/Emojis.qml`): end-4 bundles **~1,947
  entries** in a 1,953-line shell script, everything after a literal
  `### DATA ###` marker, read via a QML `FileView`. Loaded whole into a
  `list<var>`, no lazy loading, fuzzy-filtered per keystroke, rendered in a plain
  `ListView`.
- Researched (admitted): **caelestia-dots/shell has no emoji provider at all.**

**Format decision to make:** end-4's rows carry *multiple search keywords* per
glyph (`😀 grinning face face smile happy joy :D grin`); this repo's carry **one
name** (`😀\tgrinning face`), so "happy" and "joy" currently match nothing.
Whether to widen the keyword set is independent of whether to grow past 160.

**Clipboard — `cliphist`, already installed (1:0.7.0-2, wl-clipboard 1:2.3.0-1).**

Researched (admitted, `dots/.config/quickshell/ii/services/Cliphist.qml` and
`modules/common/widgets/CliphistImage.qml`) — the exact contract:

- list: `cliphist list`
- restore: `printf '<entry>' | cliphist decode | wl-copy`
- delete one: `echo '<entry>' | cliphist delete` · wipe all: `cliphist wipe`
- **image entries**: detected by regex `^\d+\t\[\[.*binary data.*\d+x\d+.*\]\]$`
  (cliphist's own marker), width/height parsed from that same string, decoded once
  to a temp file on `Component.onCompleted`, shown as a thumbnail, temp file
  deleted `onDestruction`.

**Image previews are net-new capability here.** The current Super+C pipeline
(`keybinds.lua:143`) is text-only. Treat as a scope decision, not an assumed
inclusion.

**No performance work required, and no spike.** end-4 holds ~1,947 entries in
memory and re-filters per keystroke with **no** GridView, `cacheBuffer`, proxy
model or pagination — only a debounce `Timer`. At 160 entries this is not a
performance question at all.

### D-6 — Security constraint inherited from the shell picker

`emoji-picker.sh:44` records Security Domain **T-06-17**: *"wtype must only ever
type a value we recognize, never raw, unvalidated walker stdout — glyph&lt;TAB&gt;name,
one per line."*

The QML surface inherits this. The selected glyph must be validated against the
known set before `wtype` is invoked — it cannot type back whatever the list
widget hands it. This is a requirement, not a nicety.

---

## Carried risks

- **The dmenu contract is the real work,** not the launcher. 7 consumers, each
  needing a QML surface plus a caller repoint. Scoping this as "rebuild the
  launcher" underestimates it.
- **`colour-lint` (GATE-04) rejects hardcoded colours in QML** — read palette
  values from `Colours.qml`. See also the standing lesson that a green
  token-discipline gate does not prove the tokens *resolve*
  (`Motion.qml`'s six undeclared spatial aliases, 74 call sites, `69f5912f`).
- **Theme-pipeline entries must be retired together** — `contract.json`,
  `reload.sh`, `theme-doctor`, `theme-stress-test`, `commit.sh` all assert on
  walker. A half-retirement red-lights the doctors, the way the orphaned
  `eww.scss` contract entry still does.
- `test-walker-dmenu-cancel.sh` becomes dead on retirement — delete with the rest
  of the surface.
