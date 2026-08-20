# Quick Task 260820-sqd: In-shell QML settings window — Research

**Researched:** 2026-08-20
**Domain:** Quickshell/QML control-panel surface + Hyprland live-config actuation under a Lua config manager
**Confidence:** HIGH for everything measured on this host and read from this repo; MEDIUM for the hypridle persistence design (one unverified mechanism, flagged)

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**V1 scope — all four option groups**
- **Appearance**: theme, wallpaper, icon theme, font, bar orientation — all five already have working scripts/pickers to drive.
- **Audio + connectivity**: audio mixer, wifi, bluetooth — wire in the three existing in-shell QML panels.
- **Display + input**: monitor resolution/refresh/scale and keyboard/mouse options via hyprctl/Hyprland Lua — the new territory.
- **Shell behaviour**: motion preset (normal/reduced/off), notification DND, idle/lock timing, OSD knobs the shell and scripts already own.

**Shape — standalone settings window**
- Caelestia-style centered floating window on the shell: left nav rail, one content page per group. Not a dashboard tab, not a PanelDialog accordion.
- Operator chose this from rendered previews.

**Persistence — state-dir + scripts convention**
- Every knob routes through the pipeline's existing convention: scripts own the write (theme-apply, motion-switch, …), state lives in `~/.local/state`, repo holds defaults. Git tree stays clean; no fighting theme-doctor's clean-tree invariant.
- Consequence for Display + input: persistence needs a state-dir mechanism (e.g. an overrides file the Hyprland Lua config sources), NOT edits to the stowed Lua config files.

**Reuse — mixed embed + launch**
- QML-native controls (dropdowns, toggles, sliders) live directly in the settings pages.
- The kitty-graphics pickers (wallpaper, font — anything needing image previews) and the existing audio/wifi/bluetooth panels are summoned from entries. Nothing that already works gets rebuilt.

**Scope reversal, recorded:** this reverses PROJECT.md's "Full GUI settings app" Out of Scope entry (`.planning/PROJECT.md:149`). That line must be struck through and re-recorded with the 2026-08-20 date, exactly the way the QML-rewrite reversal was recorded at `PROJECT.md:144`.

### Claude's Discretion
- Entry points (suggested: a keybind plus an entry in the walker Settings submenu; the submenu itself stays for muscle memory).
- Fate of the walker settings submenu (suggested: keep, add the window as its top entry rather than deleting the existing rows).
- Exact page layout, control styling (must go through `Colours.qml` / `Motion.qml` — colour-lint rejects hardcoded colors), nav-rail behaviour.
- How Display + input writes reach Hyprland (hyprctl live + state-dir persistence design).

### Deferred Ideas (OUT OF SCOPE)
*(CONTEXT.md declares no Deferred Ideas section — nothing recorded as deferred.)*
</user_constraints>

---

## Summary

Caelestia ships **exactly** the surface this task wants, and it is not called "settings" — it is `modules/nexus/`, a 68-file subtree added since the 2026-08-10 `FEATURES.md` sweep (which is why FEATURES.md line 170 filed a settings UI as an *anti-feature present only in end-4*; that judgement is now stale on the facts). Nexus is a left nav rail (`NavPane` = search field + category-grouped `NavLocations` list) beside a lazily-incubated single-page content area (`Pages.qml`), driven by three singletons: `PageRegistry` (the ordered `{label, icon, description, category}` metadata list), `PageCompRegistry` (the parallel `list<Component>` of page components), and `NexusState` (a plain `QtObject` holding `currentPageIdx`, a `subPageIdxStack`, and every page's selection state). Each entry in `PageCompRegistry` is a `StackPage` — a `StackView` subclass whose default property is a `list<Component>` of that group's sub-pages — so a group can drill down without any new top-level machinery. That decomposition is directly borrowable and maps 1:1 onto this task's four option groups.

The one structural piece **not** to copy verbatim is Caelestia's `WindowFactory`, which wraps `Nexus` in a `FloatingWindow` — but only because that decision needs making consciously, not because it is unavailable: `FloatingWindow` **is** present in the installed quickshell 0.3.0-2 and is reachable from a plain `import Quickshell` (`/usr/lib/qt6/qml/Quickshell/qmldir:7` declares `default import Quickshell._Window`). Choosing `FloatingWindow` — a real XDG toplevel — over this repo's usual `PanelWindow` layer surface sidesteps the single most expensive pitfall class in this codebase's memory: layer-surface resizing, blur/`ignore_alpha` layerrule ordering, `exclusionMode`, `keyboardFocus` mode, and the `quickshell-doctor` bar-surface registry all become non-issues, because none of them apply to a toplevel. The cost is that the compositor, not QML, owns placement — which is fine, because the locked decision is a *centered floating window*, which is exactly what a `windowrule` gives for free.

**Display + input is where the real risk lives, and the mechanism is already decided by a measurement made on this host today: `hyprctl keyword` is dead.** Under the Lua config manager, `hyprctl keyword monitor DP-1,...` returns `keyword can't work with non-legacy parsers. Use eval.` and exits 0 — a silent no-op. The working form is `hyprctl eval 'hl.monitor({...})'` / `hyprctl eval 'hl.config({...})'`, both verified live below, and this repo already uses exactly that shape in `gaming-mode-toggle.sh:135-138`. Worse, and load-bearing: `theme-engine/lib/reload.sh:70` calls `hyprctl reload` on **every theme apply**, and 13.1's own measurement recorded there is that reload "fully clears and re-executes the Lua config from scratch" — so any `hyprctl eval` override is **wiped by the next theme switch**. Persistence therefore cannot be eval-only; it needs a state-dir Lua overrides table that `config/monitors.lua` and `hyprland.lua` read at boot, mirroring the `lib/tokens.lua` + `~/.config/hypr/state/tokens.lua` symlink pattern that already exists for theme tokens.

**Primary recommendation:** Build `quickshell/.config/quickshell/modules/settings/` as a Caelestia-Nexus-shaped `FloatingWindow` (Settings.qml + SettingsState.qml + NavRail.qml + PageRegistry.qml + PageCompRegistry.qml + `pages/*.qml` + `common/*Row.qml`), summoned by a new `GlobalShortcut` on **`Super+comma`** (measured free) plus a new top entry in `elephant/.config/elephant/menus/settings.toml`; route every write through a script (existing ones unchanged; one new `hypr-overrides.sh` for Display+input) and extend `lib/tokens.lua`'s defensive-accessor pattern with a second `state.overrides` module so monitor/input choices survive `hyprctl reload`.

---

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Settings window chrome (nav rail, page switch, rows) | QML shell (Quickshell process) | — | Locked decision; must go through `Colours.qml`/`Motion.qml` |
| Theme / wallpaper / icon / font / bar-orientation writes | Bash scripts in `hypr/.config/hypr/scripts/` | state dir `~/.local/state/` | Existing owners; CONTEXT locks "scripts own the write" |
| Audio / wifi / bluetooth | Existing QML `PanelDialog` panels | — | Locked reuse; summoned, not rebuilt |
| Monitor + input **live application** | `hyprctl eval` (Lua expression) | — | `hyprctl keyword` is a no-op under Lua (measured) |
| Monitor + input **persistence** | state-dir Lua overrides table read by `config/monitors.lua` | — | `hyprctl reload` wipes eval overrides (measured) |
| Motion preset | `motion-switch.sh` → `~/.local/state/theme/motion-scale` | `theme-apply` re-render | Existing owner, already has `--get`/`--list` |
| Notification DND | `NotifServer` singleton (`toggleDnd()`) | `~/.local/state/quickshell/notifications.json` | Already in-process and already persisted |
| Idle / lock timing | *undecided* — see Open Questions | — | `hypridle.conf` is a tracked repo file; editing it dirties the tree |

---

## Reference Shell Patterns

### Caelestia `modules/nexus/` — the direct template

All claims below `[VERIFIED: raw.githubusercontent.com/caelestia-dots/shell/main/…, fetched 2026-08-20]`, read as actual file content.

| File | Size | Role |
|------|------|------|
| `modules/nexus/Nexus.qml` | 2950 B | Root `Item`: owns `NexusState`, lays out `NavPane` (left) beside `Pages` (right) |
| `modules/nexus/NexusState.qml` | 914 B | Plain `QtObject`: `currentPageIdx`, `subPageIdxStack`, `searchOpen` + per-page selections; `openSubPage()`/`closeSubPage()` |
| `modules/nexus/NavPane.qml` | 1199 B | `ColumnLayout`: `SearchBar` + `NavLocations` |
| `modules/nexus/navpane/NavLocations.qml` | 5253 B | Scrollable `Repeater` over `PageRegistry.pages`; category grouping by radius, not by header |
| `modules/nexus/PageRegistry.qml` | 2455 B | **Singleton**, `list<var>` of `{label, icon, description, category}` |
| `modules/nexus/PageCompRegistry.qml` | 5581 B | **Singleton**, parallel `list<Component>` + a `placeholderComp` for unbuilt pages |
| `modules/nexus/Pages.qml` | 2459 B | Content host: `incubateObject` lazy-loads the current page, destroys the previous, cross-fades + slides |
| `modules/nexus/common/StackPage.qml` | 3073 B | `StackView` whose `default property list<Component> pages` are that group's sub-pages |
| `modules/nexus/common/PageBase.qml` | 2232 B | Page chrome: title + optional back button + `VerticalFadeFlickable` body |
| `modules/nexus/WindowFactory.qml` | 1355 B | **Singleton**: creates a `FloatingWindow` wrapping `Nexus` |

**Worth borrowing (HIGH value, low cost):**

1. **The two parallel registries.** Metadata (`PageRegistry`) is separate from components (`PageCompRegistry`) so the nav rail can render labels/icons/descriptions without instantiating any page. Verbatim from `PageRegistry.qml`:

   ```qml
   readonly property list<var> pages: [
       // Appearance
       { label: qsTr("Wallpaper & style"), icon: "palette",
         description: qsTr("Wallpaper, fonts, colours"), category: "appearance" },
       ...
   ]
   ```

2. **Lazy page incubation with previous-page destruction** (`Pages.qml`): `if (currentItem) currentItem.destroy();` then `comp.incubateObject(container, { nState })`. This is the zero-idle-backend discipline this repo already enforces on `LazyLoader` panels, applied *within* the window. Only one page's bindings are ever live.

3. **Category grouping expressed as corner radii, not headers** (`NavLocations.qml`):

   ```qml
   readonly property bool isCategoryStart: index === 0 || PageRegistry.pages[index - 1].category !== modelData.category
   readonly property bool isCategoryEnd: index === list.model.length - 1 || PageRegistry.pages[index + 1].category !== modelData.category
   ```
   with `topLeftRadius: … isCurrentPage ? extraLargeIncreased : isCategoryStart ? extraLarge : extraSmall`. Four `Behavior`s animate the radii. This is a cheap, distinctive look that needs no extra chrome.

4. **The `*Row` control family** — `ToggleRow` (a `StyledSwitch` with a `subtext` line), `SliderRow` (icon + label + value label + slider, with a wheel handler), `SelectRow` (label + subtext + `SplitButton` dropdown), `StepperRow`, `TextFieldRow`, `NavRow` (a `RowButton` with `trailingIcon: "chevron_right"`). Every one is `Layout.fillWidth: true` with `first`/`last` flags feeding a `ConnectedRect` background — the M3 "connected list" idiom. **This is the exact control vocabulary this task needs** and it decomposes into ~6 small files.

5. **`PageBase` as the page contract**: `required property string title`, `required property NexusState nState`, `property bool isSubPage`, `default property Item contentChild`. Every page is a `PageBase` with one child layout. The back button is a `Loader` gated on `isSubPage`.

6. **`StackPage` for drill-down** — sub-pages push/pop with directional transitions, and `Component.onCompleted` replays `nState.subPageIdxStack` so a page restores its own depth when re-incubated. Directly useful for Display+input (monitor list → per-monitor detail).

**Worth skipping:**

| Caelestia thing | Skip because |
|---|---|
| `Caelestia.Blobs` (`BlobGroup`/`BlobInvertedRect`/`BlobRect`) | A compiled C++ QML plugin this repo does not have and will not build. Use `StyledRect`-equivalents (`Rectangle` + `Colours.*`). |
| `Caelestia.Config` (`Tokens`, `GlobalConfig`) | A C++ config plugin. This repo's equivalents are `Design.qml` (spacing/font/radius) + `Colours.qml` + `Motion.qml` — all three already exist and all three are gate-enforced. |
| The C++ `Config` object model (`plugin/src/Caelestia/Config/*.hpp`, ~48 files) | Caelestia persists settings by writing a JSON config the C++ layer watches. This repo's locked decision is scripts + state dir. Do not import this model. |
| `SearchBar` / `searchOpen` fuzzy settings search | Nine pages does not need search. Defer. |
| `WindowFactory`'s dual embedded/windowed mode (`nState.isWindow`, the `pip` button) | The locked decision is one shape: a standalone window. Carrying the second mode doubles the layout code for no requirement. |

### end-4 `ii/modules/settings/` — the second reference

`[VERIFIED: raw.githubusercontent.com/end-4/dots-hyprland/main/dots/.config/quickshell/ii/modules/…, fetched 2026-08-20]`

Component family: `common/widgets/ContentPage.qml`, `ContentSection.qml`, `ConfigSwitch.qml`, `ConfigSlider.qml`, `ConfigSpinBox.qml`, `ConfigSelectionArray.qml`. Pages: `settings/{GeneralConfig,BarConfig,InterfaceConfig,BackgroundConfig,ServicesConfig,AdvancedConfig,QuickConfig,About}.qml`.

`ContentPage` is a `StyledFlickable` with `default property alias contentData: contentColumn.data`, a `baseWidth: 600` with `width: forceWidth ? baseWidth : Math.max(baseWidth, implicitWidth)`, and `bottomContentPadding: 100`. `ContentSection` is a `ColumnLayout` with a `title`/`icon` header row. `ConfigSwitch` is a `RippleButton` whose `contentItem` is `RowLayout { OptionalMaterialSymbol; StyledText; StyledSwitch }` and whose `onClicked: checked = !checked`.

**Verdict: prefer Caelestia's decomposition, borrow end-4's one idea.** end-4's flat `ContentPage`→`ContentSection`→control shape is simpler but has no nav-rail model, no lazy page loading and no sub-page stack — it relies on a tab bar owned elsewhere. The one thing worth taking from end-4 is **`ContentSection`**: Caelestia's `SectionHeader` is a bare styled text with margin arithmetic, whereas end-4's `ContentSection` bundles the icon + title + a spaced content column into one reusable type. A `SettingsSection.qml` on end-4's shape, holding Caelestia-shaped `*Row` children, is the better hybrid.

⚠️ **`ConfigSwitch` carries the QQC2 trap this repo has already been bitten by.** Its `contentItem: RowLayout { … }` sets no anchors — correct. Caelestia's `ToggleRow` *does* anchor its `contentItem` (`anchors.left: parent.left; anchors.right: root.indicator.left`) and compensates with an explicit `implicitWidth: implicitContentWidth + implicitIndicatorWidth + horizontalPadding * 2`. Per MEMORY `qqc2-contentitem-anchors-break-sizing`, anchoring a `Control`'s `contentItem` shrinks its background below its content unless you also hand-compute `implicitWidth`. If you copy `ToggleRow`, copy **both** lines or neither.

---

## Existing Integration Points In This Repo

Every claim in this section was read from the file this session.

### Shell root: how surfaces are summoned

`quickshell/.config/quickshell/shell.qml` is a 54 KB `ShellRoot`. The established pattern is a `LazyLoader { active: false }` + a `GlobalShortcut` + (optionally) an `IpcHandler`. Verbatim, `shell.qml:489-497`:

```qml
    LazyLoader {
        id: audioPanelLoader
        active: false

        AudioPanel {
            backend: audioBackendInstance
            onDismissRequested: audioPanelLoader.active = false
        }
    }
```

The shortcut half, `shell.qml:962-978` (`dashboardShortcut`), establishes the standing rule that **an already-open surface always closes, whatever is fullscreen behind it** (D-11), while opening is gated on `!root.fullscreenBlocking`:

```qml
        onPressed: {
            if (dashboardLoader.active) {
                dashboardLoader.active = false;
            } else if (!root.fullscreenBlocking) {
                dashboardLoader.active = true;
            }
        }
```

For the guarded panel family the shortcut calls `root.openPanel("audio")` (`shell.qml:1027`) rather than writing `active` directly, so the DASH-08 refusal guard is read in exactly one place. The `IpcHandler { target: "panel" }` at `shell.qml:914-946` exposes `open(name)`/`toggle(name)` and never writes a loader's `active` itself.

**Recommendation:** a `settingsLoader` + `settingsShortcut` on the `dashboardShortcut` shape (toggle, fullscreen-guarded on open), plus an `IpcHandler { target: "settings" }` with `open()`/`toggle()`/`openPage(name)` so the walker menu entry can deep-link a group. `openPage` is the piece that makes "keep the walker submenu, add the window as its top entry" work — each existing walker row could later become `qs ipc call settings openPage appearance`.

### Keybind dispatch through Hyprland Lua

Three artifacts must change together (`keybind-doctor` and `hypr-equivalence-check` both assert this):

1. `hypr/.config/hypr/config/keybinds.lua` — `hl.bind(mainMod .. " + <KEY>", hl.dsp.global("quickshell:<name>"))`. Existing examples at lines 213 (`+ D`), 220 (`+ A`), 229 (`+ O`), 238 (`+ N`), 248 (`+ M`).
2. `quickshell/.config/quickshell/shortcuts.json` — one object `{ appid, name, chord: {mods, key}, description }`. This is `keybind-doctor`'s contract file (D-17), 9 entries today.
3. `quickshell/.config/quickshell/shell.qml` — the matching `GlobalShortcut { appid: "quickshell"; name: "<name>" }`.

**Free chord, measured live** `[VERIFIED: hyprctl binds -j on this host, 2026-08-20]`:

```
SUPER+<letter> taken: ABCDEFILMNOPQRSTVWXYZ (plus 0-9)
free letters:         G H J K U
SUPER+SHIFT+<letter> taken: B C F G K Q S T X Z (plus 0-9)
punctuation under SUPER / SUPER+SHIFT: comma, period, slash, semicolon,
  apostrophe, grave, bracketleft, bracketright — ALL FREE
```

`S` (the first-letter mnemonic D-09 would want) is taken under both plain Super and Super+Shift. **Recommend `Super+comma`** — the near-universal "preferences" chord, free under both modmasks, and it does not burn one of the five remaining plain-Super letters on a surface opened a few times a week.

### Scripts and their state files

| Knob | Script | State file / mechanism |
|------|--------|----------------------|
| Theme | `hypr/.config/hypr/scripts/theme-switch.sh` — enumerates `~/.config/theme-engine/palettes`, `exec ~/.config/theme-engine/theme-apply "$THEME"` (line 71) | `~/.local/state/theme/current-theme` |
| Wallpaper | `wallpaper-switch.sh` → `uwsm app -- kitty --class wallpaper-picker … wallpaper-picker.sh` | `~/.local/state/theme/current.jpg` symlink + `last-wallpaper/` |
| Icon theme | `icon-theme-switch.sh` → floating kitty running `icon-theme-picker.sh` | `~/.local/state/theme/icon-theme` |
| Font | `font-switch.sh` → floating kitty running `font-switcher.sh` | `~/.local/state/theme/kitty-font.conf` + gsettings |
| Bar orientation | `bar-orientation.sh` — closed allowlist `SLUGS=("horizontal" "vertical")` (lines 27-30), atomic `printf … > "$STATE_FILE.tmp" && mv` (lines 61) | `~/.local/state/quickshell/bar-orientation` |
| Motion preset | `motion-switch.sh` — has `--get` and `--list` (lines 104-118), validates against `jq -r '.scales | keys[]' motion.json` (line 130), atomic tmp+mv (lines 142-143), then re-invokes `theme-apply` | `~/.local/state/theme/motion-scale` |
| Notification DND | `NotifServer.qml` (`pragma Singleton`, line 40) — `property bool dnd` (line 74), `function toggleDnd()` (line 258) | `~/.local/state/quickshell/notifications.json` |
| Fastfetch logo | `fastfetch-logo-switch.sh` | `~/.local/state/theme/fastfetch-logo` |

**Two scripts are already settings-window-ready**: `motion-switch.sh` (`--get`/`--list`) and `bar-orientation.sh` (closed slug list). Every other picker is an *interactive fzf/kitty* program with no query interface. The three kitty-graphics pickers (wallpaper, icon, font) are launched exactly as today per the locked "mixed embed + launch" decision — a `NavRow` that runs the same `uwsm app -- kitty …` line the walker entry runs. **Theme** is the interesting case: `theme-switch.sh` is a *walker dmenu* wrapper, not a graphics picker, so the settings page should enumerate `~/.config/theme-engine/palettes` itself into a `SelectRow` and call `theme-apply <name>` directly — matching what `theme-switch.sh:13` already does ("palette filenames — never a hardcoded case ladder").

### The walker settings submenu

`elephant/.config/elephant/menus/settings.toml` — 9 entries: Theme, Wallpaper, Icon theme, Font, Bar orientation, Network (`nmtui-launch.sh`), Bluetooth (`uwsm app -- blueman-manager`), Audio (`uwsm app -- pavucontrol`), Display (`uwsm app -- nwg-displays`).

**Recommendation (discretionary):** keep all nine rows for muscle memory, prepend one row `  Settings` → `qs ipc call settings open` (or a small shim script, matching the file's own D-09 two-class convention: "shell scripts invoked bare; GUI apps via `uwsm app --`"). The **Display** row's `nwg-displays` becomes the documented Advanced escape hatch from the Display page — the same "Advanced escape hatch to pavucontrol/nm-connection-editor/blueman" pattern `PanelDialog.qml:60-63` already ships as `advancedLabel`/`advancedCommand`.

### Design tokens the surface must consume

- `modules/Colours.qml` — `pragma Singleton`; 19 `readonly property alias` roles: `primary`, `onPrimary`, `primaryContainer`, `onPrimaryContainer`, `secondary`, `onSecondary`, `secondaryContainer`, `onSecondaryContainer`, `tertiary`, `onTertiary`, `surface`, `onSurface`, `surfaceVariant`, `onSurfaceVariant`, `background`, `onBackground`, `outline`, `error`, `onError` (lines 148-166). **`colour-lint` CHECK A parses exactly these alias lines at run time** — a reference outside this set fails the gate.
- `modules/Motion.qml` — `standardDuration`/`standardEasing`, `emphasizedInDuration`/`emphasizedInEasing`, `emphasizedOutDuration`/`emphasizedOutEasing`, `staggerOffsetDuration`/`staggerOffsetEasing`, `ambientDuration`/`ambientEasing`, `borderRotateDuration` (lines 182-250).
- `modules/dashboard/Design.qml` — `spacingXs`…`spacingXl`, `panelPadding`, `fontHeading`/`fontBody`/`fontLabel`, `weightEmphasis`/`weightBody`, `iconSizeMd`, `symbolFontFamily`, `borderWidth` (consumed by `PanelDialog.qml:138-158`). ⚠️ `Design.qml` pins font *sizes* but deliberately **not** a family — the shell inherits the GTK font (recorded as an explicit non-token, Phase 19).

---

## Display + Input via Hyprland — the new territory

### The mechanism, measured on this host today

`[VERIFIED: live probes against Hyprland 0.56.2 on this host, 2026-08-20]`

```
$ hyprctl version | head -1
Hyprland 0.56.2 built from branch v0.56.2 at commit efb5099…

$ hyprctl keyword monitor "DP-1,2560x1440@165,0x0,1"
keyword can't work with non-legacy parsers. Use eval.

$ hyprctl keyword input:sensitivity 0
keyword can't work with non-legacy parsers. Use eval.

$ hyprctl keyword input:bogus_option 1
keyword can't work with non-legacy parsers. Use eval.
```

All three exit **0**. `hyprctl keyword` is a silent no-op for *every* key under the Lua config manager — including a nonsense key, so it cannot even be used as a probe. The working forms, both verified as no-op writes of the current values:

```
$ hyprctl eval 'hl.monitor({ output = "DP-1", mode = "2560x1440@165", position = "0x0", scale = 1 })'
ok
$ hyprctl eval 'hl.config({ input = { sensitivity = 0 } })'
ok
```

This is the same retarget `gaming-mode-toggle.sh` already made — `hyprctl eval 'hl.config({ decoration = { blur = { enabled = false } } })'` at lines 135-138, with the header at lines 5-8 declaring the standing rule: *"NEVER writes a Hyprland config file — every compositor change goes through `hyprctl eval`."*

⚠️ **`ok` is not evidence.** `hypridle.conf:22-24` records this repo's own hard-won finding, verbatim: *"the `ok` reply lies here — all forms reply `ok`"*. Every monitor/input write must be verified against an oracle: `hyprctl monitors -j` (`.width`, `.height`, `.refreshRate`, `.scale`) or `hyprctl getoption <key> -j`.

### The data the Display page needs is already in `hyprctl monitors -j`

`[VERIFIED: hyprctl monitors -j on this host]` — the DP-1 record carries `name`, `description`, `make`, `model`, `width`, `height`, `refreshRate` (`164.99899` — **a float, not `165`**), `x`, `y`, `scale`, `transform`, `vrr`, `dpmsStatus`, `disabled`, `mirrorOf`, and `availableModes`: a 32-entry list of strings shaped `"2560x1440@165.00Hz"`. That list is the resolution/refresh dropdown model — no probing, no `wlr-randr`, no `nwg-displays` parsing.

⚠️ Note the format mismatch: `availableModes` entries are `"2560x1440@165.00Hz"`; the `mode` field `hl.monitor` accepts is `"2560x1440@165"` (`config/monitors.lua:17`). The page must strip `Hz` and normalise `165.00` → `165` before the eval. And `refreshRate: 164.99899` will not string-match `165.00` — match on the parsed float with a tolerance, or the "currently active mode" indicator will show nothing selected.

For input, `hyprctl devices -j` enumerates keyboards (with `layout`, `main`) and mice (with `defaultSpeed`). This host reports 7 keyboards and 6 mice, most of them phantom sub-devices of the same physical hardware (`corsair-…-keyboard` **and** `corsair-…-keyboard-1` **and** `corsair-…-keyboard-mouse`). A per-device UI would be noise; the global `input { … }` block (`hyprland.lua:85-92`: `kb_layout`, `follow_mouse`, `sensitivity`, `touchpad.natural_scroll`) is the right granularity for v1.

### Persistence — the trap, and the pattern to mirror

**The trap:** `theme-engine/.config/theme-engine/lib/reload.sh:70` calls `hyprctl reload` inside the pipeline's reload fan-out, and lines 59-66 record the 13.1 measurement verbatim: *"`hyprctl reload` fully clears and re-executes the Lua config from scratch each time."* So **every theme switch silently reverts any `hyprctl eval` monitor/input override.** An eval-only design would appear to work in testing and then quietly undo itself the first time the operator changes theme. This is the single highest-severity finding in this document.

**The pattern to mirror** — the theme pipeline already solves exactly this for colours:

- `hypr/.config/hypr/lib/tokens.lua` — a defensive accessor. `M.get()` does `pcall(require, "state.tokens")`, normalises the shape, and returns `{}`-backed sub-tables so a caller can index two levels deep even when the whole file is absent. Its header records the two failure classes it catches: a missing file (which "would otherwise stop the compositor from starting at all") and a present-but-malformed file.
- `stow.sh:492-493` wires the symlink:
  ```bash
  mkdir -p "$HOME/.config/hypr/state"
  ln -sf "../../../.local/state/theme/hyprland-tokens.lua" "$HOME/.config/hypr/state/tokens.lua"
  ```
  Relative, never absolute (the reproducibility rule from quick task 260709-ciu). Live state confirmed: `~/.config/hypr/state/tokens.lua -> ../../../.local/state/theme/hyprland-tokens.lua`.
- `hyprland.lua:44` — `local tokens = require("lib.tokens").get()`, then every value uses `tokens.colors.X or "<literal fallback>"` (lines 71-77). Line 59-62 states where the guarantee lives: *"this `or` is where D-13's 'a missing token degrades to a default, never blocking compositor startup' guarantee actually lives."*

**Recommended design for Display + input persistence:**

1. New state file `~/.local/state/hypr/overrides.lua`, written atomically (tmp + `mv`) by a new `hypr-overrides.sh`, returning a plain Lua table:
   ```lua
   return {
     monitors = { ["DP-1"] = { mode = "2560x1440@165", position = "0x0", scale = 1 } },
     input = { kb_layout = "us", sensitivity = 0, follow_mouse = 1,
               touchpad = { natural_scroll = true } },
   }
   ```
2. New `hypr/.config/hypr/lib/overrides.lua` on `lib/tokens.lua`'s exact shape — `pcall(require, "state.overrides")`, shape-normalised, empty-table fallback.
3. `stow.sh` gains a second `ln -sf "../../../.local/state/hypr/overrides.lua" "$HOME/.config/hypr/state/overrides.lua"` beside the existing one, plus a seed-only-when-absent write of a `return {}` default (the same seed-only discipline `stow.sh:311`/`:331` already applies).
4. `config/monitors.lua` reads the table and merges over its repo defaults; `hyprland.lua`'s `input` block does the same. Both keep their current literals as the `or` fallback, so a missing/corrupt overrides file degrades to today's behaviour and never blocks boot.
5. The settings page writes via the script **and** applies live via `hyprctl eval` — the "live + persist" pair, verified against the JSON oracle before the row's UI state updates.

⚠️ **`hypr-equivalence-check` will fail on this.** Its `ACCEPTED_OPTION_CHANGES` table (line 384) diffs live `hyprctl getoption` against a committed 2026-08-08 baseline, and its `_derive_key_list` now parses the Lua tree (2026-08-18). A monitor/input value that differs from the baseline fails unless registered. Worse, an *operator-adjustable* value is structurally hostile to a value-equality gate — this is the same class of problem LEDGER-07 hit, where 3 of 46 tracked options carried theme-rendered colours and made the gate unsatisfiable. **Design decision required:** either (a) constrain v1 to knobs not in the 46-key baseline, or (b) teach the comparator to skip keys present in the overrides table, the way it already skips accepted changes. Do not simply re-capture the baseline — `hypr-equivalence-check:349-384` records why (it would overwrite the two deliberately un-loosened `bindm` records).

---

## Gate Obligations for a New Surface

| Gate | What it will demand |
|------|--------------------|
| `colour-lint` (GATE-04) | CHECK A: every `Colours.<name>` must resolve against the 19 aliases parsed live from `Colours.qml`. CHECK B: no quoted hex at a `color:`-family anchor (B1), no `property color x: "#…"` (B2), no `Qt.rgba(` with three numeric-literal args (B3 — a literal **fourth** arg is in-contract), no non-`transparent` quoted string at a colour anchor (B4). Currently 150/0. |
| `motion-lint` | CHECK A: every `Motion.<property>` reference must resolve against the emitted token set. CHECK B: no bare `Nms`/`cubic-bezier(...)` literal outside a `Motion.*` reference. Currently 291/0. |
| `quickshell-doctor` (GATE-03) | **If the surface is a `PanelWindow`**, it must be added to `QSD_BAR_SURFACE_ROWS` (`quickshell-doctor:302-423`) as one row `file\|namespace\|exact\|level\|reserve-or-noreserve\|lifetime`, with the source half re-deriving the namespace literal from that row's own file, plus matching self-test fixtures under `scripts/tests/quickshell-fixtures/`. **If it is a `FloatingWindow`, none of this applies** — the registry keys on `WlrLayershell.namespace`, which a toplevel does not have. Currently self-test 59/0. |
| `keybind-doctor` | The new chord must appear in **both** `shortcuts.json` and `keybinds.lua`, and pass the chord-collision check (compares modmask, key **and edge**). Currently 14/0. |
| `hypr-equivalence-check` (in `theme-doctor`) | New bind → one `ACCEPTED_ADDITIONS` entry keyed `(dispatcher_str, modmask, key, release)`; for `Super+comma` that is `("", 64, "comma", False)`. **The table fails closed on a stale entry** (line 488: an entry that "did not fire" is itself an error), so remove it if the bind is later removed. New Hyprland option → one `ACCEPTED_OPTION_CHANGES` entry. |
| `theme-doctor` clean-tree invariant | Nothing the window writes may land in the git tree. Every write goes to `~/.local/state/`. Currently 609/0. |
| `stow-link-check` | Any new symlink `stow.sh` creates must resolve; its `SWEEP_ROOTS` scope was corrected in Phase 22. |
| `qmldir` registration | **Both** `modules/qmldir` (if a type is imported from `shell.qml`'s `import "modules"`) **and** a new `modules/settings/qmldir` are required, in the same commit that creates the types. `modules/qmldir:14-21` records the binary-verified finding that a singleton needs **both** `pragma Singleton` in the file **and** the `singleton` keyword in qmldir — without the keyword, `PageRegistry.pages`-style access resolves to `undefined` forever with no load error. |

---

## Common Pitfalls (the ones that will actually bite this surface)

### Pitfall 1 — `hyprctl keyword` is a silent no-op, and `ok` lies
Covered above. Both halves are measured, not assumed. Every compositor write is `hyprctl eval`, and every write is verified against `hyprctl monitors -j` / `hyprctl getoption -j`, never against the reply string.

### Pitfall 2 — `hyprctl reload` (fired on every theme apply) wipes eval overrides
Covered above. This is why persistence must go through the Lua config, not through eval alone. **Verification step for the plan:** apply a monitor change, then run `theme-apply <some-other-theme>`, then re-read `hyprctl monitors -j`. If the change survives, persistence works; if it reverts, it does not.

### Pitfall 3 — layer-surface resizing (avoided entirely by choosing `FloatingWindow`)
MEMORY `layer-surface-must-never-resize`: a top-anchored layer surface is compositor-centred and a resizing one re-buffers every frame, dragging the content. `Dashboard.qml` handles this by anchoring **all four edges** (`Dashboard.qml:222-225`) and declaring *"No implicitWidth/implicitHeight: the surface takes its extent from the anchors"* (line 304), animating only in QML. `PanelDialog.qml` takes the other route: `anchors.top: true` alone with fixed `implicitWidth: 850` / `implicitHeight: 620` (lines 65-66, 123-126) — static, never animated.

**A settings window with dropdowns and a nav rail will want to grow** as pages change height. Under `PanelWindow` that is the forbidden shape. Under `FloatingWindow` it is free — Caelestia's own `WindowFactory` binds `implicitWidth: nexus.implicitWidth` with `minimumSize.width`/`minimumSize.height` floors, and the compositor handles it. **This alone justifies `FloatingWindow`.**

If the plan nonetheless chooses `PanelWindow`: fix the surface at a constant size on `PanelDialog`'s shape (850×620 is the house size) and clip page content into a flickable, exactly as `PageBase` already does.

### Pitfall 4 — layerrule ordering and `ignore_alpha` (only if `PanelWindow`)
MEMORY `hyprland-layerrule-order-and-alpha` + `windowrules.lua`. The family regex `hl.layer_rule({ match = { namespace = "^quickshell-.*" }, blur = true })` is at line 340 and the family `ignore_alpha = 0.5` floor at line 373. A per-surface rule that **contradicts** the family regex must be declared **after** it — `windowrules.lua:390-395` records this verbatim ("a rule that CONTRADICTS the `^quickshell-.*` family regex loses when it is [declared first]"), which is why the overview pair sits at lines 452-453 and the notif trio at 514-519. A QML surface alpha below the `ignore_alpha` floor silently kills blur.

And MEMORY `hyprctl-reload-drops-layer-rules`: layer-rule edits need `hyprctl eval` or a restart; `reload` fails silently and the symptom looks exactly like a wrong alpha. **Screenshot before tuning.** A `FloatingWindow` needs a `windowrule` instead — which `hyprctl reload` *does* re-source correctly, since it comes from the Lua config.

### Pitfall 5 — QQC2 `contentItem` anchors break `Control` sizing
MEMORY `qqc2-contentitem-anchors-break-sizing`. Anchoring a `Control`'s `contentItem` shrinks its background below its content; use the `Control`'s own padding, not a hand-rolled `implicitWidth`. Caelestia's `ToggleRow` gets away with it only because it *also* hand-computes `implicitWidth`/`implicitHeight` from `implicitContentWidth`/`implicitIndicatorWidth`. Every `*Row` type here is a `Control` subclass — this trap is live on all of them.

### Pitfall 6 — declare QML members before construction-time use
MEMORY `qml-declare-before-construction-time-use`. A later-declared member throws "is not a function" and a fallback chain turns it into a plausible wrong answer. Caelestia's `Pages.qml` calls `root.loadPage(root.nState.currentPageIdx)` from `container`'s `Component.onCompleted` — a construction-time call into a member declared *above* it in the same file. Preserve that ordering when porting. Quickshell logs only to `~/.cache/quickshell.log`.

### Pitfall 7 — a child binding lags the parent's signal
MEMORY `child-binding-lags-parent-signal`. Inside `onXChanged` the child still sees the OLD value; `Qt.callLater` it, and never let a guard return silently. Directly relevant to `onCurrentPageIdxChanged` → destroy old page → incubate new page: Caelestia sequences this through a `SequentialAnimation` with a `ScriptAction`, which sidesteps the problem by deferring the swap past the fade-out. Copy the sequencing, not just the handler.

### Pitfall 8 — do not spawn `qml6` probe windows, and screenshot carefully
MEMORY `qml6-probes-crash-hyprland` (~12 probe windows took the operator's session down) and `screenshot-crashes-hyprland` / `screenshot-quickshell-surfaces-safely`. Verify with Python, static gates, or `~/.cache/quickshell.log`. Screenshots: `grim -g` on a **layer surface** works — a full-screen `grim` capture SIGSEGVs the compositor on this NVIDIA + dynamic-cursors host. ⚠️ A `FloatingWindow` is **not** a layer surface, so the known-safe `grim -g` recipe is unproven for it. Plan the render gate around `hyprctl clients -j` geometry + `grim -g "<x>,<y> <w>x<h>"` and treat the first capture as the risky one.

### Pitfall 9 — live-probe flakiness and the pipefail/grep gate trap
MEMORY `live-probe-flaky-after-hot-reload`: `quickshell-doctor` reads differently 25 s vs 28 s after a QML edit; re-run twice before believing it. MEMORY `pipefail-grep-q-false-passes-gates`: `X | grep -q` under `pipefail` can exit 141 on a match, flipping a gate's verdict by file length — validate any gate edit with `quickshell-doctor --self-test`. MEMORY `grep-gate-matches-own-comment`: a banned-identifier gate greps its own prose; strip `//` lines.

### Pitfall 10 — the walker/elephant two-process reality
If the walker menu gains a row, remember walker 2.16.2 is a thin GTK4 UI over the separate `elephant` 2.21.0 daemon (`.claude/CLAUDE.md`). A menu TOML edit needs `elephant-restart.sh`, not a walker restart, and a stale/mismatched elephant looks like a CSS/theme problem.

---

## Code Skeleton (this repo's idiom, not Caelestia's)

```qml
// quickshell/.config/quickshell/modules/settings/SettingsState.qml
// Plain QtObject, mirroring Caelestia NexusState. NOT a singleton — one
// instance per Settings window, owned by Settings.qml.
import QtQuick

QtObject {
    property int currentPageIdx: 0
    property list<int> subPageIdxStack

    signal close
    signal subPageOpened(idx: int)
    signal subPageClosed

    function openSubPage(idx: int): void { subPageIdxStack.push(idx); subPageOpened(idx); }
    function closeSubPage(): void { subPageClosed(); subPageIdxStack.pop(); }

    onCurrentPageIdxChanged: subPageIdxStack.length = 0
}
```

```qml
// quickshell/.config/quickshell/modules/settings/Settings.qml  (FloatingWindow shape)
import QtQuick
import Quickshell            // FloatingWindow arrives via `default import Quickshell._Window`
import "../"                 // Colours, Motion
import "../dashboard"        // Design

FloatingWindow {
    id: win

    color: Colours.surface
    title: "Settings"
    minimumSize.width: 900
    minimumSize.height: 620

    // Nav rail (left) + lazily-incubated page host (right) go here.
    // Every colour reads Colours.*, every duration/easing reads Motion.*
    // — colour-lint CHECK A and motion-lint CHECK A both resolve against
    // the live singletons, so a typo'd reference fails the gate rather
    // than rendering `undefined` forever.
}
```

```bash
# hypr/.config/hypr/scripts/hypr-overrides.sh  (sketch — live + persist pair)
# Live half, on gaming-mode-toggle.sh:135's proven shape:
hyprctl eval "hl.monitor({ output = \"$OUT\", mode = \"$MODE\", position = \"$POS\", scale = $SCALE })"
# Verify against the oracle, NEVER the `ok` reply (hypridle.conf:22 — "the `ok` reply lies here"):
hyprctl monitors -j | jq -e --arg o "$OUT" '.[] | select(.name==$o) | .width == 2560'
# Persist half, atomic tmp+mv on motion-switch.sh:142's shape:
printf '%s\n' "$LUA_TABLE" > "$OVERRIDES.tmp" && mv "$OVERRIDES.tmp" "$OVERRIDES"
```

---

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | hypridle supports a `source =` include so idle/lock timings can live in the state dir. Evidence is weak: `hypridle --help` shows only `-c <path>` (verified), and `strings /usr/bin/hypridle \| grep -ci source` returns 13 (which proves nothing — "source" appears in many contexts). `[ASSUMED]` | Open Questions | The Idle/lock row has no persistence path and must be descoped or redesigned mid-plan |
| A2 | `hl.monitor()` called a second time for the same output *replaces* rather than *appends* the declaration. The no-op probe cannot distinguish these (identical values). `[ASSUMED]` | Display+input | A second call could stack declarations; the Lua overrides merge must replace at the table level rather than emit two `hl.monitor` calls |
| A3 | `FloatingWindow` on quickshell 0.3.0-2 works correctly under Hyprland 0.56.2 in practice — the type exists and is exported (verified), but no `FloatingWindow` has ever been instantiated in this repo. `[ASSUMED]` | Summary / Pitfall 3 | The whole "avoid layer-surface pitfalls" argument collapses; fall back to a fixed-size `PanelWindow` on `PanelDialog`'s shape and register it in `QSD_BAR_SURFACE_ROWS` |
| A4 | `qs ipc call settings open` from a walker menu entry reaches the shell. The IPC mechanism is proven (`shell.qml:914` `panelIpc`), but no walker entry currently calls `qs ipc`. `[ASSUMED]` | Walker submenu | The menu row needs a tiny shim script instead of a bare `qs ipc` line |
| A5 | Constraining v1 Display+input knobs to keys outside `hypr-equivalence-check`'s 46-key baseline is achievable. `input:sensitivity`, `input:kb_layout` and `input:follow_mouse` are all set in `hyprland.lua:85-92` and therefore likely **in** the baseline. `[ASSUMED]` | Gate obligations | Option (a) is unavailable and the comparator must be taught to skip override-backed keys — a larger change than the settings window itself |

---

## Open Questions

1. **Idle/lock timing persistence — the one knob with no clean home.**
   - What we know: `hypr/.config/hypr/hypridle.conf` is a **tracked repo file** in the `hypr/` stow package with five `listener` blocks at timeouts 120/300/600/900/1800 (lines 54-98). Editing it from the settings window dirties the git tree and trips `theme-doctor`'s clean-tree invariant. It is **not** a `contract.json` entry (22 entries, `hypridle.conf` absent) so the theme pipeline does not render it.
   - What's unclear: whether hypridle's hyprlang parser honours `source = ~/.local/state/hypr/idle-overrides.conf`, and whether hypridle re-reads on SIGHUP or needs a restart.
   - Recommendation: **descope idle/lock to read-only in v1** — show the five current timeouts on the Shell behaviour page with an "Advanced" row that opens `hypridle.conf` in `$EDITOR`, matching the `PanelDialog.advancedCommand` escape-hatch precedent. Promote to editable in a follow-up once the `source =` question is measured. This keeps the four locked option groups delivered without inventing a persistence mechanism mid-plan.

2. **`FloatingWindow` vs `PanelWindow` — decide before Task 1.**
   - Recommendation: `FloatingWindow`, plus a `hl.window_rule` centring it (`float`, `center`) in `windowrules.lua`. It eliminates Pitfalls 3 and 4 and the `QSD_BAR_SURFACE_ROWS` obligation entirely, and it is what Caelestia itself does. The plan should carry a Task 1 that instantiates a bare `FloatingWindow` and confirms it appears and takes pointer/keyboard input — the same "prove the toolkit before building on it" gate QS-02 established — since A3 is the only load-bearing unverified assumption in this document.

3. **`hypr-equivalence-check` and operator-adjustable options.**
   - What we know: the comparator diffs live values against a frozen baseline and fails closed on a stale accepted-change entry (line 488). LEDGER-07 already proved this shape unsatisfiable for values that legitimately vary.
   - Recommendation: raise this explicitly at plan time. The clean answer is a third table — a `VOLATILE_KEYS` set the comparator reports but does not assert on — sized to exactly the keys the overrides file can write. Do **not** re-capture the baseline.

4. **Does the Theme page enumerate palettes itself, or shell out?**
   - Recommendation: enumerate `~/.config/theme-engine/palettes` in QML (a `FileView`/`Process` listing, matching `theme-switch.sh:13`'s "never a hardcoded case ladder" rule) and call `theme-apply <name>` directly. `theme-switch.sh` is a walker-dmenu wrapper whose UI would collide with the settings window's own.

---

## Sources

### Primary (HIGH confidence — read/measured this session)
- **This host, live:** `hyprctl version` (0.56.2), `hyprctl monitors -j`, `hyprctl devices -j`, `hyprctl binds -j`, `hyprctl keyword` (×3, all no-op), `hyprctl eval 'hl.monitor(…)'`, `hyprctl eval 'hl.config(…)'`, `hyprctl getoption input:sensitivity -j`, `pacman -Q quickshell` (0.3.0-2), `/usr/lib/qt6/qml/Quickshell/qmldir`, `/usr/lib/qt6/qml/Quickshell/_Window/quickshell-window.qmltypes`, `ls ~/.local/state/{theme,quickshell}`, `ls -la ~/.config/hypr/state/`
- **This repo, read in full or in cited ranges:** `quickshell/.config/quickshell/shell.qml`, `shortcuts.json`, `modules/qmldir`, `modules/centre/qmldir`, `modules/Colours.qml`, `modules/Motion.qml`, `modules/dashboard/PanelDialog.qml`, `modules/dashboard/Dashboard.qml`, `modules/notifications/NotifServer.qml`, `hypr/.config/hypr/hyprland.lua`, `config/monitors.lua`, `config/keybinds.lua`, `config/windowrules.lua`, `hypridle.conf`, `lib/tokens.lua`, `scripts/{theme,icon-theme,font,wallpaper}-switch.sh`, `scripts/bar-orientation.sh`, `scripts/motion-switch.sh`, `scripts/gaming-mode-toggle.sh`, `scripts/quickshell-doctor`, `scripts/colour-lint`, `scripts/motion-lint`, `scripts/hypr-equivalence-check`, `theme-engine/lib/reload.sh`, `theme-engine/contract.json`, `stow.sh`, `elephant/.config/elephant/menus/settings.toml`
- **Reference shells, actual file content via `raw.githubusercontent.com`:**
  - `caelestia-dots/shell@main` — `modules/nexus/{Nexus,NavPane,NexusState,Pages,PageRegistry,PageCompRegistry,WindowFactory}.qml`, `modules/nexus/common/{PageBase,StackPage,SectionHeader,NavRow,ToggleRow,SliderRow,SelectRow}.qml`, `modules/nexus/navpane/NavLocations.qml`; full repo tree via the GitHub trees API
  - `end-4/dots-hyprland@main` — `dots/.config/quickshell/ii/modules/common/widgets/{ContentPage,ContentSection,ConfigSwitch}.qml`; settings tree listing via the GitHub trees API

### Secondary (MEDIUM)
- `.planning/research/FEATURES.md:170` — records a settings UI as an end-4-only anti-feature. **Now stale**: Caelestia's `modules/nexus/` (68 files) postdates that 2026-08-10 sweep.
- `.claude/CLAUDE.md` — stack constraints, walker/elephant two-process rule, `colour-lint` rule
- `.planning/PROJECT.md:149` — the Out of Scope entry this task reverses
- `~/.claude/.../MEMORY.md` — the ten pitfall entries cited inline

### Not consulted
No WebSearch was used. Every external claim comes from primary source files fetched directly.

---

## Metadata

**Confidence breakdown:**
- Reference-shell patterns: **HIGH** — actual QML read, not summaries
- Repo integration points: **HIGH** — every claim cites a file and line read this session
- Hyprland eval/keyword/reload mechanism: **HIGH** — measured live on this host today
- Persistence design for Display+input: **MEDIUM** — the pattern is proven for tokens, but not yet exercised for a second `state.*` module (A2, A5)
- Idle/lock persistence: **LOW** — A1 unverified; recommended descope to read-only
- `FloatingWindow` viability: **MEDIUM** — type verified present and exported, never instantiated in this repo (A3)

**Research date:** 2026-08-20
**Valid until:** 2026-09-19 (30 days) — except the reference-shell sections, which track two fast-moving upstream repos; re-verify `modules/nexus/` if more than ~7 days elapse before planning.
