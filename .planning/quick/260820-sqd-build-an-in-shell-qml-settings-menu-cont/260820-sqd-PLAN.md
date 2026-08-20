---
phase: quick-260820-sqd
plan: 01
type: execute
wave: 1
depends_on: []
autonomous: false
requirements: [D-01, D-02, D-03, D-04, D-05, D-06]

files_modified:
  - quickshell/.config/quickshell/modules/settings/Settings.qml
  - quickshell/.config/quickshell/modules/settings/SettingsState.qml
  - quickshell/.config/quickshell/modules/settings/NavRail.qml
  - quickshell/.config/quickshell/modules/settings/PageRegistry.qml
  - quickshell/.config/quickshell/modules/settings/PageCompRegistry.qml
  - quickshell/.config/quickshell/modules/settings/Pages.qml
  - quickshell/.config/quickshell/modules/settings/qmldir
  - quickshell/.config/quickshell/modules/settings/common/PageBase.qml
  - quickshell/.config/quickshell/modules/settings/common/SettingsSection.qml
  - quickshell/.config/quickshell/modules/settings/common/SelectRow.qml
  - quickshell/.config/quickshell/modules/settings/common/ToggleRow.qml
  - quickshell/.config/quickshell/modules/settings/common/SliderRow.qml
  - quickshell/.config/quickshell/modules/settings/common/NavRow.qml
  - quickshell/.config/quickshell/modules/settings/common/InfoRow.qml
  - quickshell/.config/quickshell/modules/settings/common/qmldir
  - quickshell/.config/quickshell/modules/settings/pages/AppearancePage.qml
  - quickshell/.config/quickshell/modules/settings/pages/ConnectivityPage.qml
  - quickshell/.config/quickshell/modules/settings/pages/DisplayInputPage.qml
  - quickshell/.config/quickshell/modules/settings/pages/ShellBehaviourPage.qml
  - quickshell/.config/quickshell/modules/settings/pages/qmldir
  - quickshell/.config/quickshell/shell.qml
  - quickshell/.config/quickshell/shortcuts.json
  - hypr/.config/hypr/config/keybinds.lua
  - hypr/.config/hypr/config/windowrules.lua
  - hypr/.config/hypr/config/monitors.lua
  - hypr/.config/hypr/hyprland.lua
  - hypr/.config/hypr/lib/overrides.lua
  - hypr/.config/hypr/scripts/hypr-overrides.sh
  - hypr/.config/hypr/scripts/hypr-equivalence-check
  - hypr/.config/hypr/scripts/idle-overrides.sh
  - hypr/.config/hypr/hypridle.conf
  - elephant/.config/elephant/menus/settings.toml
  - stow.sh
  - .planning/PROJECT.md
  - .planning/WINDOWS.md

user_setup: []

estimate:
  tokens: 330000
  raw_tokens: 165000
  tasks: 4
  confidence: low          # no calibration samples for a surface of this size in this repo

must_haves:
  truths:
    - "Super+comma opens a centred floating Settings window; pressing it again closes it (D-02, D-06)."
    - "A left nav rail lists four groups — Appearance, Audio & connectivity, Display & input, Shell behaviour — and selecting one swaps the content page (D-01, D-02)."
    - "Appearance applies a theme live, flips bar orientation, and hands off wallpaper/icon/font to the existing kitty-graphics pickers (D-01, D-04)."
    - "Audio, wifi and bluetooth entries summon the three existing in-shell panels; none of the three is rebuilt (D-01, D-04)."
    - "A monitor mode/scale or input change applies live AND survives `hyprctl reload` and a theme switch (D-01, D-03)."
    - "Motion preset and notification DND change from the window and persist across a shell restart (D-01, D-03)."
    - "Idle and lock timeouts are EDITABLE from the window; a change takes effect on the running idle daemon and survives a reboot, with the git tree still clean (D-01 idle/lock override, D-03)."
    - "Every write lands under ~/.local/state; the git tree stays clean afterwards (D-03)."
    - "PROJECT.md's 'Full GUI settings app' Out of Scope entry reads as a dated, deliberate 2026-08-20 reversal, not silent drift (D-05)."
  artifacts:
    - quickshell/.config/quickshell/modules/settings/Settings.qml
    - quickshell/.config/quickshell/modules/settings/PageRegistry.qml
    - quickshell/.config/quickshell/modules/settings/PageCompRegistry.qml
    - quickshell/.config/quickshell/modules/settings/qmldir
    - quickshell/.config/quickshell/modules/settings/pages/AppearancePage.qml
    - quickshell/.config/quickshell/modules/settings/pages/ConnectivityPage.qml
    - quickshell/.config/quickshell/modules/settings/pages/DisplayInputPage.qml
    - quickshell/.config/quickshell/modules/settings/pages/ShellBehaviourPage.qml
    - hypr/.config/hypr/scripts/hypr-overrides.sh
    - hypr/.config/hypr/lib/overrides.lua
    - hypr/.config/hypr/scripts/idle-overrides.sh
  key_links:
    - "keybinds.lua bind <-> shortcuts.json entry <-> shell.qml GlobalShortcut — keybind-doctor's three-way byte-match contract; any one missing fails the gate."
    - "modules/settings/qmldir <-> every .qml in modules/settings/ — an undeclared type is unresolvable to `import \"modules/settings\"` forever, with no load error."
    - "`pragma Singleton` in PageRegistry.qml/PageCompRegistry.qml <-> the `singleton` keyword in qmldir — modules/qmldir:14-21 records that BOTH are required or access resolves to undefined forever."
    - "PageRegistry.pages[i] <-> PageCompRegistry.comps[i] — parallel arrays; a length or order mismatch silently renders the wrong page."
    - "hypr-overrides.sh write -> ~/.local/state/hypr/overrides.lua -> stow.sh symlink -> lib/overrides.lua `require(\"state.overrides\")` -> monitors.lua/hyprland.lua merge — the chain that makes a Display+input change survive `hyprctl reload` (theme-engine/lib/reload.sh:70 fires it on EVERY theme apply)."
    - "New Super+comma bind <-> hypr-equivalence-check ACCEPTED_ADDITIONS (\"\", 64, \"comma\", False) — an unregistered addition fails the comparator closed."
    - "Overrides-writable Hyprland option keys <-> hypr-equivalence-check VOLATILE_KEYS — an operator-adjustable value is structurally unsatisfiable against a frozen value-equality baseline (LEDGER-07's failure mode)."
    - "hypridle.conf `source =` line <-> ~/.local/state/hypr/idle-overrides.conf <-> stow.sh seed — MEASURED to work (see PD-03). The state-dir file holds ALL five listener blocks, because hyprlang APPENDS listener blocks rather than replacing them: a base listener left in the tracked file plus an override would fire at BOTH timeouts, making a lengthened timeout impossible."
    - "idle-overrides.sh restart path <-> `uwsm app -- hypridle` (autostart.lua:177) — NOT `systemctl --user restart hypridle`. MEASURED: hypridle.service is inactive/disabled on this host; the live process is the uwsm transient scope `app-Hyprland-hypridle-*.scope`, so a systemctl restart silently does nothing."
---

<objective>
Build an in-shell QML settings window — a Caelestia-`nexus`-shaped floating control panel — that reaches every machine and system option in the four locked groups, routing every write through this repo's existing scripts + `~/.local/state` convention.

Purpose: the desktop's settings currently live in nine walker rows that each shell out to a different tool. This gives them one home, in the shell's own palette and motion language, without rebuilding anything that already works (D-04).

Output: `quickshell/.config/quickshell/modules/settings/` (a new QML module), `hypr-overrides.sh` + `lib/overrides.lua` (the Display+input persistence pair), `idle-overrides.sh` + a restructured `hypridle.conf` (the editable idle/lock pair), a new `Super+comma` chord wired through all three keybind contract files, and the dated PROJECT.md scope reversal.

**Task count:** four, not the usual three. The operator's 2026-08-20 override making idle/lock editable added a whole persistence mechanism with its own measurement gate; folding it into Task 2 or Task 3 would have buried that gate inside an already-full task. Task 4 is a coherent shippable increment and carries the plan's single operator checkpoint.
</objective>

<decision_ids>
CONTEXT.md carries no `D-NN` numbering. These IDs are minted here, one per CONTEXT.md decision block, and are the traceability handles used in every task action below. Do not renumber them.

| ID | CONTEXT.md source | Substance |
|----|-------------------|-----------|
| D-01 | `### V1 scope — all four option groups` | Appearance / Audio+connectivity / Display+input / Shell behaviour all ship in v1 |
| D-02 | `### Shape — standalone settings window` | Caelestia-style centred floating window, left nav rail, one content page per group. Not a dashboard tab, not a PanelDialog accordion. Chosen by the operator from rendered previews. |
| D-03 | `### Persistence — state-dir + scripts convention` | Scripts own the write, state lives in `~/.local/state`, repo holds defaults, git tree stays clean. Display+input needs a state-dir overrides mechanism, NOT edits to stowed Lua config files. |
| D-04 | `### Reuse — mixed embed + launch` | QML-native controls inline; kitty-graphics pickers and the audio/wifi/bluetooth panels summoned, never rebuilt. |
| D-05 | `<domain>` — Scope reversal, recorded | PROJECT.md's "Full GUI settings app" Out of Scope entry is reversed, operator-directed 2026-08-20, recorded the way the QML-rewrite reversal was. |
| D-06 | `### Claude's Discretion` | Entry points, walker submenu fate, page layout/styling, Display+input write mechanism — resolved below as PD-01..PD-05. |

## Plan decisions (D-06 discretion, resolved)

- **PD-01 — `FloatingWindow`, not `PanelWindow`. OPERATOR-CONFIRMED 2026-08-20** (CONTEXT.md Shape section), so this is a locked decision rather than a research recommendation Claude adopted. It remains subject to the Task-1 viability probe because the type has never been instantiated in this repo, and **if the probe falsifies it the plan falls back to `PanelWindow` and surfaces that change to the operator — never a silent switch.** The type is present and exported on the installed quickshell 0.3.0-2 (`/usr/lib/qt6/qml/Quickshell/_Window/quickshell-window.qmltypes:44`) and reachable from a bare `import Quickshell` (`/usr/lib/qt6/qml/Quickshell/qmldir:7` — `default import Quickshell._Window`). A real XDG toplevel makes layer-surface resizing, layerrule ordering, `ignore_alpha`, `exclusionMode`, `keyboardFocus` and the `QSD_BAR_SURFACE_ROWS` registry all non-issues — and a settings window with dropdowns genuinely wants to grow. This is RESEARCH.md assumption A3, the only load-bearing unverified claim in the research, which is why Task 1 is a tracer that kills it first.
- **PD-02 — `Super+comma`.** Measured free under both `SUPER` and `SUPER+SHIFT` on this host (`hyprctl binds -j`, 2026-08-20). `S` is taken under both. `comma` is the near-universal preferences chord and does not burn one of the five remaining plain-Super letters (G H J K U).
- **PD-03 — idle/lock timing is EDITABLE, through a `source =` include. RESEARCH.md A1 is now MEASURED, not assumed.** The operator overrode the research's read-only descope recommendation on 2026-08-20 (CONTEXT.md V1-scope). The mechanism was measured empirically during planning against the installed binary, `hypridle v0.1.8`, and the results are decisive:

  | # | Probe | Result | What it proves |
  |---|-------|--------|----------------|
  | A | Config with a garbage keyword, no listeners | `[ERR] Config has errors: No rules configured` / `Proceeding ignoring faulty entries` | This binary DOES report config errors — so silence in probe C is meaningful. It also does NOT hard-fail on a bad config; it proceeds with whatever parsed. |
  | B | `source = <a path that does not exist>` | `[ERR] source= globbing error: found no match` cited at file+line | **`source =` is handled by the parser, not ignored.** An unsupported keyword would have produced an unknown-keyword error instead. `ldd` confirms hypridle links `libhyprlang.so.2`, where `source` is a parser builtin. |
  | C | `source = <a real file containing a listener block>` | `[LOG] Registered timeout rule for 99999s:` / `[LOG] found 1 rules` | **Sourced content is genuinely APPLIED, not merely tolerated** — the `No rules configured` error from control A is absent. Positive control with a matching negative control. |
  | D | `strings /usr/bin/hypridle` for a SIGHUP/reload handler | no match | **hypridle has no live-reload.** Applying a change requires restarting the daemon. |
  | E | `systemctl --user is-active hypridle.service` | `inactive` (unit `disabled`); live process is the uwsm transient scope `app-Hyprland-hypridle-*.scope`, launched by `hl.exec_cmd("uwsm app -- hypridle")` at `autostart.lua:177` | **`systemctl --user restart hypridle` is the WRONG restart path on this host — it would silently do nothing.** The restart must kill the running process and relaunch via `uwsm app -- hypridle`, matching autostart. |

  **Design consequence, and it is not the obvious one.** hyprlang APPENDS `listener` blocks rather than replacing them (probe C registered a rule *in addition to* the base config's). So the tempting shape — keep the five listeners in the tracked `hypridle.conf` and source an overrides file that redefines one — produces TWO rules for the same event, firing at both timeouts. The earlier one always wins, which means a timeout could be shortened but never lengthened. **Therefore all five listener blocks move to the state-dir file**, and the tracked `hypridle.conf` retains only the `general { }` block plus one `source =` line. That is a single tracked-file edit at build time, never per-adjustment, so D-03's clean-tree invariant holds.

  **Safety consequence.** Probe A shows hypridle proceeds with zero rules on a broken config — which means a corrupt overrides file leaves the machine that never locks. Idle lock is a security control, so this gets a real mitigation rather than a shrug: `stow.sh` seeds the file from repo defaults when absent, the script writes atomically, and after the restart the script verifies the effective rule count and rolls back to the previous file if it dropped. Registered as T-SQD-08.
- **PD-04 — `hypr-equivalence-check` gets a third table, `VOLATILE_KEYS`.** The comparator diffs live `hyprctl getoption` values against a frozen 2026-08-08 baseline. An operator-adjustable value is structurally unsatisfiable against value equality — this is exactly how LEDGER-07 became unreachable. Do NOT re-capture the baseline (`hypr-equivalence-check:349-384` records that it would overwrite the two deliberately un-loosened `bindm` records). `VOLATILE_KEYS` is sized to exactly the keys `overrides.lua` can write, and reports rather than asserts.
- **PD-05 — the Theme page enumerates palettes itself.** `theme-switch.sh` is a walker-dmenu wrapper whose UI would collide with this window's own. The page lists `~/.config/theme-engine/palettes` and calls `theme-apply <name>` directly — the same "palette filenames, never a hardcoded case ladder" rule `theme-switch.sh:13` already states.

## Named follow-ups (deferred, NOT dropped)

- **F-01** — settings fuzzy search (Caelestia's `SearchBar`/`searchOpen`). Four pages does not need it.
- **F-02** — ~~editable idle/lock timings~~ **WITHDRAWN.** The operator made these editable in v1 (CONTEXT.md V1-scope, 2026-08-20). The blocking question this follow-up existed to answer — does hypridle honour `source =`, and does it re-read on SIGHUP — was measured during planning and is answered in PD-03. Delivered by Task 4, not deferred.
- **F-03** — per-device keyboard/mouse configuration. `hyprctl devices -j` reports 7 keyboards and 6 mice on this host, most of them phantom sub-devices of the same physical hardware; v1 uses the global `input { }` block, which is the right granularity.
- **F-04** — `StackPage` sub-page drill-down (monitor list -> per-monitor detail). This host has one physical output; a flat list is correct until a second one exists.
- **F-05** — deep-linking the nine existing walker rows onto `qs ipc call settings openPage <name>`. v1 prepends one row and leaves the nine intact for muscle memory (D-06 suggestion, honoured).
- **F-06** — the fastfetch logo picker on the Appearance page. Not among D-01's five named Appearance items; the walker row and `Super+Shift+T` both still reach it.
</decision_ids>

<execution_context>
@$HOME/.claude/gsd-core/workflows/execute-plan.md
@$HOME/.claude/gsd-core/templates/summary.md
</execution_context>

<context>
@.planning/quick/260820-sqd-build-an-in-shell-qml-settings-menu-cont/260820-sqd-CONTEXT.md
@.planning/quick/260820-sqd-build-an-in-shell-qml-settings-menu-cont/260820-sqd-RESEARCH.md
@.claude/CLAUDE.md

Read these as you reach the task that needs them, not all up front:
@quickshell/.config/quickshell/modules/dashboard/PanelDialog.qml
@quickshell/.config/quickshell/modules/qmldir
@quickshell/.config/quickshell/modules/centre/qmldir
@hypr/.config/hypr/lib/tokens.lua
@hypr/.config/hypr/config/monitors.lua
</context>

<operator_standing_rules>
These come from the operator's own hard-won session history. Violating one costs a compositor crash or a false verdict.

1. **Never spawn `qml6` probe windows.** ~12 of them took the operator's Hyprland session down mid-diagnosis. Verify with Python, static gates, `hyprctl -j`, or `~/.cache/quickshell.log`.
2. **Never take a full-screen `grim` capture.** It SIGSEGVs the compositor into safe mode on this NVIDIA + dynamic-cursors host. `grim -g` on a *layer surface* is the known-safe recipe — and a `FloatingWindow` is NOT a layer surface, so that recipe is unproven for it. Do not attempt a capture of the settings window at all; live visual verification is the operator's job (Task 3's human-check).
3. **Restart the shell only via `systemctl --user restart quickshell.service`.** A non-detached restart from an agent shell kills it silently and the symptom reads as a broken keybind.
4. **`hypr-lua-harness` may be started at most once per task, and always stopped.** It boots a real nested compositor. Use `hypr-lua-harness stop` in every exit path.
5. **`ok` from `hyprctl eval` is not evidence.** `hypridle.conf:22-24` records this repo's own finding verbatim: *"the `ok` reply lies here — all forms reply `ok`"*. Verify every compositor write against `hyprctl monitors -j` / `hyprctl getoption <key> -j`.
6. **`hyprctl keyword` is a silent no-op under the Lua config manager** — it exits 0 for every key, including nonsense ones, so it cannot even be used as a probe. Every compositor write is `hyprctl eval`, on `gaming-mode-toggle.sh:135-138`'s proven shape.
7. **Gate greps must strip their own comments.** A banned-identifier grep matches its own explanatory prose. Filter comment lines before counting.
8. **Never write `X | grep -q` in a gate under `pipefail`.** `grep -q` exits on first match and can surface as 141, flipping the verdict by file length. Capture to a variable, then test.
9. **Re-run any live probe twice before believing it.** `quickshell-doctor` reads differently 25 s vs 28 s after a QML edit.
</operator_standing_rules>

<tasks>

<task type="tracer">
  <name>Task 1: End-to-end "open the window and change the theme" — one path through every layer</name>

  <precondition>`systemctl --user is-active quickshell.service` reports `active`, and `hyprctl version` reports Hyprland 0.56.x. Both were true on this host on 2026-08-20; halt and report if either is not.</precondition>

  <files>
quickshell/.config/quickshell/modules/settings/Settings.qml,
quickshell/.config/quickshell/modules/settings/SettingsState.qml,
quickshell/.config/quickshell/modules/settings/NavRail.qml,
quickshell/.config/quickshell/modules/settings/PageRegistry.qml,
quickshell/.config/quickshell/modules/settings/PageCompRegistry.qml,
quickshell/.config/quickshell/modules/settings/Pages.qml,
quickshell/.config/quickshell/modules/settings/qmldir,
quickshell/.config/quickshell/modules/settings/common/PageBase.qml,
quickshell/.config/quickshell/modules/settings/common/SettingsSection.qml,
quickshell/.config/quickshell/modules/settings/common/SelectRow.qml,
quickshell/.config/quickshell/modules/settings/common/NavRow.qml,
quickshell/.config/quickshell/modules/settings/common/qmldir,
quickshell/.config/quickshell/modules/settings/pages/AppearancePage.qml,
quickshell/.config/quickshell/modules/settings/pages/qmldir,
quickshell/.config/quickshell/shell.qml,
quickshell/.config/quickshell/shortcuts.json,
hypr/.config/hypr/config/keybinds.lua,
hypr/.config/hypr/config/windowrules.lua,
hypr/.config/hypr/scripts/hypr-equivalence-check,
.planning/PROJECT.md
  </files>

  <reversibility rating="costly">
PD-01 (`FloatingWindow` over `PanelWindow`) shapes every file in `modules/settings/`. Reversing it after the pages exist means re-solving fixed-size layout, layer namespacing, layerrule ordering and `QSD_BAR_SURFACE_ROWS` registration across the whole subtree. Reversing it *now*, with one page built, is cheap — which is the entire reason this task is a tracer.
  </reversibility>

  <action>
Prove the toolkit and the full dispatch chain on ONE path before building anything wide. The single path is: press the chord -> a real toplevel appears -> the nav rail shows four entries -> the Appearance page renders -> picking a theme re-colours the desktop. No second page, no second knob.

**Step 1 — the viability gate (RESEARCH.md A3), FIRST.** Before writing the nav rail or any page, create `modules/settings/Settings.qml` as a minimal `FloatingWindow` (root `import Quickshell` — the type arrives via `default import Quickshell._Window`, do not import `Quickshell._Window` explicitly), with `title: "Settings"`, `color: Colours.surface`, `minimumSize.width: 900`, `minimumSize.height: 620`, and a single `Rectangle` child painted `Colours.surfaceVariant`. Wire it behind a `LazyLoader { active: false }` in `shell.qml` and summon it via the IPC handler from Step 3. Then run the live probe in `<verify>`.

If the toplevel does not appear in `hyprctl clients -j`, **HALT and report** rather than improvising. The recorded fallback is a fixed-size `PanelWindow` on `PanelDialog.qml`'s shape (`anchors.top: true` alone, constant `implicitWidth`/`implicitHeight`, page content clipped into a flickable) plus a `QSD_BAR_SURFACE_ROWS` row in `quickshell-doctor` and matching self-test fixtures under `scripts/tests/quickshell-fixtures/`. That fallback is a different plan shape and needs the operator's call, not a mid-task improvisation.

**Step 2 — the module skeleton, on Caelestia's two-registry decomposition.** Once the window is proven:

- `SettingsState.qml` — a plain `QtObject` (NOT a singleton; one instance per window, owned by `Settings.qml`). Holds `property int currentPageIdx: 0`, a `signal close`, and per-page selection state. Declare every function ABOVE any construction-time caller in the same file — a later-declared member throws "is not a function" and a fallback chain silently turns it into a plausible wrong answer.
- `PageRegistry.qml` — `pragma Singleton`, a `readonly property list<var> pages` of `{ label, icon, description, category }` objects, one per group, in nav order: Appearance, Audio & connectivity, Display & input, Shell behaviour (D-01's four groups, that order).
- `PageCompRegistry.qml` — `pragma Singleton`, a parallel `readonly property list<Component> comps` PLUS a `placeholderComp` for pages not yet built. In this task only index 0 (Appearance) resolves to a real component; the other three point at `placeholderComp`. Task 2 and Task 3 replace them.
- `NavRail.qml` — a scrollable `Repeater` over `PageRegistry.pages`. Express category grouping through corner radii rather than section headers, Caelestia's idiom: derive `isCategoryStart`/`isCategoryEnd` by comparing `category` against the neighbouring index, and drive the four corner radii from `isCurrentPage`/`isCategoryStart`/`isCategoryEnd`, each behind a `Behavior` reading `Motion.standardDuration`/`Motion.standardEasing`.
- `Pages.qml` — the content host. Lazily `incubateObject` the current page and destroy the previous one, so only one page's bindings are ever live. **Sequence the swap through a `SequentialAnimation` with a `ScriptAction`, not a bare `onCurrentPageIdxChanged` handler** — inside `onXChanged` a child binding still sees the OLD value, and deferring the destroy/incubate past the fade-out sidesteps that entirely. Never let the guard return silently; log to `console.warn` on an out-of-range index.
- `common/PageBase.qml` — the page contract: `required property string title`, `required property SettingsState sState`, `default property Item contentChild`, title band plus a flickable body.
- `common/SettingsSection.qml` — end-4's `ContentSection` shape (icon + title header row over a spaced content column), holding Caelestia-shaped rows. This is the deliberate hybrid: Caelestia's decomposition, end-4's one better idea.
- `common/SelectRow.qml` and `common/NavRow.qml` — label + subtext + a dropdown / a chevron-trailing button. **Both are `Control` subclasses and both are exposed to the QQC2 sizing trap: do NOT anchor a `Control`'s `contentItem`.** Use the `Control`'s own padding. If you copy Caelestia's `ToggleRow` shape, which DOES anchor its `contentItem`, you must ALSO copy its hand-computed `implicitWidth: implicitContentWidth + implicitIndicatorWidth + horizontalPadding * 2` — both lines or neither, never one.
- Read every colour from `Colours.*` (19 aliases only) and every duration/easing from `Motion.*`. Read spacing/font/radius from `Design.qml` via `import "../dashboard"`, exactly as `PanelDialog.qml:138-158` does.

**Step 3 — registration and dispatch, all in this commit.**

- `modules/settings/qmldir`: header `module qs.modules.settings`, then one line per type in that directory. `PageRegistry` and `PageCompRegistry` each need the `singleton` keyword here IN ADDITION to `pragma Singleton` in their own file — `modules/qmldir:14-21` records this as binary-verified: without the qmldir keyword the object is never constructed and `PageRegistry.pages` resolves to `undefined` forever with no load error. Same treatment for `modules/settings/common/qmldir` (`module qs.modules.settings.common`) and `modules/settings/pages/qmldir` (`module qs.modules.settings.pages`). Follow the sibling manifests' standing instruction verbatim: any FUTURE type added to one of these directories must be declared in the same commit that creates it.
- `modules/qmldir` needs NO change — `Settings.qml` lives in the subdirectory, matching the `centre`/`osd`/`session` precedent (`NotifCentre` is declared only in `modules/centre/qmldir`), not the older root-level `Dashboard`/`Overview`/`Bar` shape.
- `shell.qml`: add `import "modules/settings"` beside the existing seven module imports; add `LazyLoader { id: settingsLoader; active: false; Settings { onCloseRequested: settingsLoader.active = false } }`; add `GlobalShortcut { id: settingsShortcut; appid: "quickshell"; name: "settings" }` whose `onPressed` copies `dashboardShortcut`'s shape verbatim — an already-open window ALWAYS closes whatever is fullscreen behind it, and opening is gated on `!root.fullscreenBlocking`; add `IpcHandler { target: "settings" }` exposing `open()`, `toggle()` and `openPage(name: string)`. The IPC verbs must read `settingsLoader.active` and route through one shared summon function rather than each writing `active` directly, mirroring how `panelIpc` defers to `openPanel()`. `openPage` resolves a name against `PageRegistry.pages`'s `category` field and is what makes F-05 possible later.
- `shortcuts.json`: one entry `{ "appid": "quickshell", "name": "settings", "chord": { "mods": "SUPER", "key": "comma" }, "description": ... }`. The `appid:name` pair must byte-match both the Lua bind and the `GlobalShortcut` — that is keybind-doctor's cross-check contract.
- `keybinds.lua`: `hl.bind(mainMod .. " + comma", hl.dsp.global("quickshell:settings"))` with a trailing `--` comment naming the surface. The cheat-sheet is generated by parsing exactly that trailing comment, so it IS the user-facing documentation — there is no separate doc file to update. Place it beside the other `quickshell:` binds. Note in the comment that `comma` was measured free under both `SUPER` and `SUPER+SHIFT` (PD-02), and why `S` was not used.
- `windowrules.lua`: a named float rule for the settings toplevel on the existing `float-pavucontrol`/`float-blueman` shape (`name = "float-settings"`, `float = true`, `size = "..."`, `center = true`). Match on the class the probe in `<verify>` actually reports — read it from `hyprctl clients -j`, do not assume it. This is a `window_rule`, not a `layer_rule`, so it is re-sourced correctly by `hyprctl reload` and needs no `hyprctl eval` dance.
- `hypr-equivalence-check`: one `ACCEPTED_ADDITIONS` entry keyed `("", 64, "comma", False)` (SUPER = 64), with a comment naming this quick task and the declaring `keybinds.lua` line, matching the three existing entries' style. The table fails closed on a stale entry, so this must be removed if the bind ever is.

**Step 4 — the Appearance page's single working knob (PD-05).** `pages/AppearancePage.qml` is a `PageBase` containing one `SettingsSection` with one `SelectRow` labelled Theme. Populate its model by listing `~/.config/theme-engine/palettes` at runtime (a `Process`/`FileView` listing — never a hardcoded case ladder, per `theme-switch.sh:13`'s own rule), showing the current value read from `~/.local/state/theme/current-theme`. **Read `~/.local/state/theme/current-theme`, never `~/.cache/current-theme`** — the latter is a plausible-looking orphan. On selection, run `~/.config/theme-engine/theme-apply <name>`. The page writes nothing itself; the script owns the write (D-03).

**Step 5 — the PROJECT.md reversal (D-05).** In `.planning/PROJECT.md`, strike through the `Full GUI settings app — the settings menu launches existing tools; no custom settings UI (carried from v2.0 requirements)` line and append a dated reversal note, matching the QML-rewrite reversal's own form four lines above it: `~~...~~` followed by **REVERSED 2026-08-20, operator-directed.** and two or three sentences of substance — that nine walker rows shelling to nine tools is the state being replaced, that the reversal is a deliberate decision rather than drift, and that `.planning/research/FEATURES.md:170`'s "settings UI is an end-4-only anti-feature" judgement is now stale on the facts (Caelestia's `modules/nexus/` postdates that 2026-08-10 sweep).
  </action>

  <verify>
    <automated><![CDATA[
set -uo pipefail
cd /home/aorus/dotfiles
FAIL=0

# --- A. qmldir completeness: every .qml in each settings dir is declared ---
for d in modules/settings modules/settings/common modules/settings/pages; do
  QD="quickshell/.config/quickshell/$d/qmldir"
  [ -f "$QD" ] || { echo "FAIL: missing $QD"; FAIL=1; continue; }
  DECL=$(grep -v '^[[:space:]]*#' "$QD")
  for f in quickshell/.config/quickshell/$d/*.qml; do
    [ -e "$f" ] || continue
    B=$(basename "$f")
    N=$(printf '%s\n' "$DECL" | grep -c "[[:space:]]${B}\$")
    [ "$N" -ge 1 ] || { echo "FAIL: $B unregistered in $QD"; FAIL=1; }
  done
done

# --- B. singleton double-declaration (modules/qmldir:14-21 finding) ---
for t in PageRegistry PageCompRegistry; do
  P=$(grep -c '^pragma Singleton' "quickshell/.config/quickshell/modules/settings/$t.qml")
  Q=$(grep -v '^[[:space:]]*#' quickshell/.config/quickshell/modules/settings/qmldir | grep -c "^singleton ${t} ")
  [ "$P" -eq 1 ] && [ "$Q" -eq 1 ] || { echo "FAIL: $t pragma=$P qmldir_singleton=$Q (both must be 1)"; FAIL=1; }
done

# --- C. parallel registries are the same length ---
NP=$(grep -v '^[[:space:]]*//' quickshell/.config/quickshell/modules/settings/PageRegistry.qml | grep -c 'category:')
[ "$NP" -eq 4 ] || { echo "FAIL: PageRegistry has $NP entries, expected 4"; FAIL=1; }

# --- D. three-way keybind contract + all repo gates ---
hypr/.config/hypr/scripts/keybind-doctor    || { echo "FAIL: keybind-doctor"; FAIL=1; }
hypr/.config/hypr/scripts/colour-lint       || { echo "FAIL: colour-lint";    FAIL=1; }
hypr/.config/hypr/scripts/motion-lint       || { echo "FAIL: motion-lint";    FAIL=1; }
# quickshell-doctor must be UNCHANGED: under PD-01 the new surface is a toplevel,
# so it needs no QSD_BAR_SURFACE_ROWS row. A regression here means the surface is
# being built as a layer surface after all — stop and re-read PD-01.
hypr/.config/hypr/scripts/quickshell-doctor --self-test \
  || { echo "FAIL: quickshell-doctor --self-test regressed"; FAIL=1; }

# --- E. LIVE viability probe (RESEARCH.md A3) — the gate this task exists for ---
LOGN=$(wc -l < ~/.cache/quickshell.log 2>/dev/null || echo 0)
systemctl --user restart quickshell.service
sleep 8
qs ipc call settings open || { echo "FAIL: settings IPC unreachable"; FAIL=1; }
sleep 3
for attempt in 1 2; do   # re-run twice: live probes are flaky right after a reload
  CLIENTS=$(hyprctl clients -j)
  echo "$CLIENTS" | jq -e '[.[] | select(.title == "Settings")] | length == 1' >/dev/null \
    || { echo "FAIL(attempt $attempt): no unique 'Settings' toplevel in hyprctl clients"; FAIL=1; }
  echo "$CLIENTS" | jq -e '[.[] | select(.title == "Settings")][0] | (.size[0] > 400 and .size[1] > 400 and .floating == true)' >/dev/null \
    || { echo "FAIL(attempt $attempt): Settings toplevel not floating or degenerate size"; FAIL=1; }
  sleep 4
done
echo "MEASURED CLASS (record this in windowrules.lua):"
hyprctl clients -j | jq -r '.[] | select(.title == "Settings") | .class'

# --- F. no new QML load errors since the restart ---
NEWERR=$(tail -n "+$((LOGN + 1))" ~/.cache/quickshell.log 2>/dev/null | grep -ci 'settings.*\.qml.*\(error\|is not a function\|undefined\)' || true)
[ "$NEWERR" -eq 0 ] || { echo "FAIL: $NEWERR new settings QML errors in quickshell.log"; FAIL=1; }

qs ipc call settings toggle || true
[ "$FAIL" -eq 0 ] && echo "TASK 1 VERIFY: PASS"
exit "$FAIL"
]]></automated>
  </verify>

  <done>
`Super+comma`'s full dispatch chain is live and machine-confirmed: `hyprctl clients -j` reports exactly one floating `Settings` toplevel with a real size, `qs ipc call settings open`/`toggle` both drive it, keybind-doctor/colour-lint/motion-lint are all at zero failures, and the Appearance page's Theme row re-colours the desktop through `theme-apply`. RESEARCH.md assumption A3 is now measured rather than assumed, and the measured window class is recorded in `windowrules.lua`. PROJECT.md's Out of Scope entry reads as a dated 2026-08-20 reversal. Committed.
  </done>
</task>

<task type="auto" tdd="false">
  <name>Task 2: Expand to all four pages against their existing owners — nothing rebuilt</name>

  <precondition>Task 1's live probe passed and `PageCompRegistry.comps[0]` resolves to the real Appearance page. If Task 1 halted on A3, this task does not run — the fallback needs the operator's call first.</precondition>

  <files>
quickshell/.config/quickshell/modules/settings/PageCompRegistry.qml,
quickshell/.config/quickshell/modules/settings/common/ToggleRow.qml,
quickshell/.config/quickshell/modules/settings/common/SliderRow.qml,
quickshell/.config/quickshell/modules/settings/common/InfoRow.qml,
quickshell/.config/quickshell/modules/settings/common/qmldir,
quickshell/.config/quickshell/modules/settings/pages/AppearancePage.qml,
quickshell/.config/quickshell/modules/settings/pages/ConnectivityPage.qml,
quickshell/.config/quickshell/modules/settings/pages/ShellBehaviourPage.qml,
quickshell/.config/quickshell/modules/settings/pages/qmldir,
quickshell/.config/quickshell/shell.qml,
elephant/.config/elephant/menus/settings.toml
  </files>

  <behavior>
- Appearance page: five rows — Theme (built in Task 1), Wallpaper, Icon theme, Font, Bar orientation. The three picker rows launch the existing scripts unchanged; Bar orientation is an inline two-value dropdown.
- Connectivity page: three rows — Audio, Wi-Fi, Bluetooth — each summoning the existing in-shell panel, with the settings window yielding focus.
- Shell behaviour page: motion preset dropdown (3 values) and a notification DND toggle. The idle/lock section is added to this same page by Task 4, which owns its measured persistence mechanism — this task leaves a clearly-marked seam, not a placeholder.
- Selecting a nav entry for any of the four groups renders a real page; `placeholderComp` is referenced nowhere in `PageCompRegistry.comps` after this task except at the Display & input index, which Task 3 fills.
  </behavior>

  <action>
Expand horizontally from Task 1's proven slice. Every knob here has an existing owner — a script, a state file, or an in-shell panel. **Nothing on this page is reimplemented (D-04).** Where a row's only job is to launch something, it launches; where the value is a small closed set, it is an inline control.

**Appearance page — complete it (D-01, D-04).** Add to the Task 1 section:
- **Wallpaper / Icon theme / Font** — three `NavRow`s. Each runs the exact command the corresponding walker row runs today: `~/.config/hypr/scripts/wallpaper-switch.sh`, `icon-theme-switch.sh`, `font-switch.sh`. These are kitty-graphics pickers whose image previews cannot be reproduced in a QML list, which is precisely why D-04 says summon rather than rebuild. Each row shows the current value as subtext, read from `~/.local/state/theme/{current.jpg symlink target, icon-theme, kitty-font.conf}`. Close the settings window when a picker launches, so the floating kitty is not summoned behind it.
- **Bar orientation** — a `SelectRow` over the closed set `bar-orientation.sh` already enforces (`SLUGS=("horizontal" "vertical")`, lines 27-30). Current value from `~/.local/state/quickshell/bar-orientation`. On selection, call `~/.config/hypr/scripts/bar-orientation.sh <slug>` — the script owns the atomic tmp+mv write (line 61), not the page.

**Connectivity page (D-01, D-04).** `pages/ConnectivityPage.qml`, three `NavRow`s: Audio, Wi-Fi, Bluetooth. Each summons the corresponding existing `PanelDialog` panel. Route through the shell's own guarded summon path — emit a signal from the page that `Settings.qml` re-emits and `shell.qml` handles by calling `root.openPanel("audio"|"wifi"|"bluetooth")`. **Do not write `audioPanelLoader.active` or any sibling loader's `active` directly** — `openPanel()` is where the DASH-08 fullscreen refusal guard lives, and `shell.qml:692-697` states explicitly that the guard is read in exactly one place. Close the settings window as the panel opens, so the two surfaces are never stacked. Each row's subtext shows a live summary from the panel's existing backend (current sink, connected SSID, connected device count) — read from the existing `AudioBackend`/`WifiBackend`/`BluetoothBackend` singletons, do not add a second data source.

**Shell behaviour page (D-01, D-03, PD-03).** `pages/ShellBehaviourPage.qml`:
- **Motion preset** — a `SelectRow`. `motion-switch.sh` is already settings-ready: `--list` enumerates the valid scales (validated against `jq -r '.scales | keys[]' motion.json`, line 130) and `--get` returns the current one (lines 104-118). Call both; never hardcode the preset names. On selection, call `motion-switch.sh <name>` and let it do its own atomic write plus `theme-apply` re-render.
- **Notification DND** — a `ToggleRow` bound to the `NotifServer` singleton's `dnd` property, toggled via its existing `toggleDnd()` function. This one is already in-process and already persisted to `~/.local/state/quickshell/notifications.json`; the row is a second view of state that already exists, not a new writer.
- **Idle / lock timings — NOT in this task.** They are editable in v1 (operator decision, PD-03) and Task 4 owns them end to end, because the mechanism must be re-confirmed against the installed binary before any UI is wired to it. Leave a `SettingsSection` seam at the bottom of this page with a one-line comment naming Task 4 as its owner. Do not add read-only rows here that Task 4 would immediately replace.

**New row types.** `common/ToggleRow.qml`, `common/SliderRow.qml` and `common/InfoRow.qml`, on the same `Control` discipline Task 1 established for `SelectRow`/`NavRow`: the QQC2 `contentItem`-anchoring trap applies to all three. Declare each in `common/qmldir` in this same commit.

**Registry wiring.** In `PageCompRegistry.qml`, replace the Appearance, Audio & connectivity and Shell behaviour placeholders with the real components. Display & input stays on `placeholderComp` until Task 3 — that is deliberate and visible, not an oversight. Keep `comps`'s length and order identical to `PageRegistry.pages`; a mismatch renders the wrong page with no error.

**Walker submenu (D-06, F-05).** Prepend ONE row to `elephant/.config/elephant/menus/settings.toml` opening the window, above the existing nine. Keep all nine for muscle memory — the operator's suggested disposition, honoured. RESEARCH.md A4 flags that no walker entry currently calls `qs ipc`, so if a bare `qs ipc call settings open` action does not fire, write a two-line shim script under `hypr/.config/hypr/scripts/` and point the row at it — the file's own D-09 two-class convention is shell scripts invoked bare, GUI apps via `uwsm app --`. After editing the TOML, run `~/.config/hypr/scripts/elephant-restart.sh`, NOT a walker restart: walker 2.16.2 is a thin GTK4 UI over the separate elephant 2.21.0 daemon, and a stale elephant looks exactly like a CSS/theme problem.
  </action>

  <verify>
    <automated><![CDATA[
set -uo pipefail
cd /home/aorus/dotfiles
FAIL=0
SD=quickshell/.config/quickshell/modules/settings

# --- A. qmldir completeness for the new row types ---
for d in modules/settings/common modules/settings/pages; do
  QD="quickshell/.config/quickshell/$d/qmldir"
  DECL=$(grep -v '^[[:space:]]*#' "$QD")
  for f in quickshell/.config/quickshell/$d/*.qml; do
    B=$(basename "$f")
    N=$(printf '%s\n' "$DECL" | grep -c "[[:space:]]${B}\$")
    [ "$N" -ge 1 ] || { echo "FAIL: $B unregistered in $QD"; FAIL=1; }
  done
done

# --- B. exactly one placeholder left (Display & input, Task 3's slot) ---
PH=$(grep -v '^[[:space:]]*//' "$SD/PageCompRegistry.qml" | grep -c 'placeholderComp')
[ "$PH" -eq 2 ] || { echo "FAIL: expected placeholderComp declared once + used once (2), found $PH"; FAIL=1; }

# --- C. panels are summoned through the guarded path, never by direct loader writes ---
BAD=$(grep -rn 'PanelLoader\.active' "$SD" | grep -vc '^[[:space:]]*//' || true)
[ "$BAD" -eq 0 ] || { echo "FAIL: $BAD direct panel-loader writes in settings/ (must route via openPanel)"; FAIL=1; }

# --- D. no hardcoded motion presets or orientation slugs; scripts are the source ---
for s in motion-switch.sh bar-orientation.sh; do
  N=$(grep -rc "$s" "$SD/pages" | awk -F: '{t+=$2} END{print t+0}')
  [ "$N" -ge 1 ] || { echo "FAIL: $s not invoked from any settings page"; FAIL=1; }
done

# --- E. the TRACKED hypridle.conf is never touched by the shell (D-03 clean tree).
#     Writing the STATE-DIR overrides file is required by Task 4 and must stay legal,
#     so this asserts on the tracked repo path only, never on the state-dir path.
W=$(grep -rn 'hypr/hypridle\.conf\|\.config/hypr/hypridle\.conf' "$SD" 2>/dev/null | grep -vc '^[[:space:]]*//' || true)
[ "$W" -eq 0 ] || { echo "FAIL: settings/ references the tracked hypridle.conf ($W sites) — Task 4 writes the state-dir file instead"; FAIL=1; }

# --- F. walker row added, elephant restarted, menu still parses ---
ROWS=$(grep -c '^\[\[entries\]\]' elephant/.config/elephant/menus/settings.toml)
[ "$ROWS" -eq 10 ] || { echo "FAIL: settings.toml has $ROWS entries, expected 10 (9 kept + 1 new)"; FAIL=1; }
~/.config/hypr/scripts/elephant-restart.sh || { echo "FAIL: elephant-restart"; FAIL=1; }

# --- G. gates ---
hypr/.config/hypr/scripts/colour-lint || { echo "FAIL: colour-lint"; FAIL=1; }
hypr/.config/hypr/scripts/motion-lint || { echo "FAIL: motion-lint"; FAIL=1; }

# --- H. live: all four nav entries incubate without a QML error ---
LOGN=$(wc -l < ~/.cache/quickshell.log 2>/dev/null || echo 0)
systemctl --user restart quickshell.service
sleep 8
for p in appearance connectivity display shell; do
  qs ipc call settings openPage "$p" || { echo "FAIL: openPage $p"; FAIL=1; }
  sleep 2
done
qs ipc call settings toggle || true
sleep 2
NEWERR=$(tail -n "+$((LOGN + 1))" ~/.cache/quickshell.log 2>/dev/null | grep -ci 'settings.*\.qml.*\(error\|is not a function\|undefined\)' || true)
[ "$NEWERR" -eq 0 ] || { echo "FAIL: $NEWERR new settings QML errors"; tail -n "+$((LOGN + 1))" ~/.cache/quickshell.log | grep -i 'settings.*\.qml' | head -20; FAIL=1; }

# --- I. the clean-tree invariant, the whole point of D-03 ---
DIRTY=$(git status --porcelain | grep -vc '^$' || true)
echo "tree entries dirty after live exercise: $DIRTY (expect only this task's own edits)"

[ "$FAIL" -eq 0 ] && echo "TASK 2 VERIFY: PASS"
exit "$FAIL"
]]></automated>
  </verify>

  <done>
Three of the four groups render real pages, each driven by its existing owner: Appearance reaches all five of D-01's items (Theme inline, Bar orientation inline, three pickers launched), Connectivity summons the three existing panels through `openPanel()`'s single guard, and Shell behaviour drives motion preset via `motion-switch.sh --list`/`--get` and DND via `NotifServer.toggleDnd()`, with a marked seam where Task 4 adds the editable idle/lock section (PD-03). All four nav entries incubate cleanly in a live shell with no new QML errors. The walker submenu has ten rows — the original nine plus the window on top — and elephant has been restarted, not walker. Committed.
  </done>
</task>

<task type="auto" tdd="false">
  <name>Task 3: Display + input — live via hyprctl eval, persisted through a state-dir Lua overrides table</name>

  <precondition>`~/.config/hypr/state/tokens.lua` resolves to `../../../.local/state/theme/hyprland-tokens.lua` (the symlink pattern this task mirrors), and `hyprctl monitors -j` returns at least one record carrying `availableModes`. Both were true on this host on 2026-08-20.</precondition>

  <files>
hypr/.config/hypr/scripts/hypr-overrides.sh,
hypr/.config/hypr/lib/overrides.lua,
hypr/.config/hypr/config/monitors.lua,
hypr/.config/hypr/hyprland.lua,
hypr/.config/hypr/scripts/hypr-equivalence-check,
quickshell/.config/quickshell/modules/settings/pages/DisplayInputPage.qml,
quickshell/.config/quickshell/modules/settings/PageCompRegistry.qml,
stow.sh
  </files>

  <reversibility rating="costly">
`~/.local/state/hypr/overrides.lua` becomes a file the compositor `require`s at boot, which reads like a one-way door — but it is not one, and the reason matters: the defensive accessor plus the `or` fallback on every consumed key mean deleting the file, or the whole mechanism, degrades cleanly to today's exact repo defaults. That design IS the reversibility. The cost of reversing is real but bounded: the operator loses their persisted monitor and input choices and goes back to editing stowed Lua by hand. Get the accessor discipline right the first time — if any consumed key is written WITHOUT an `or` fallback, this rating silently becomes `one-way` and a missing overrides file blocks compositor startup.
  </reversibility>

  <action>
This is the new territory, and it carries the highest-severity finding in the research: **`hyprctl reload` — which `theme-engine/lib/reload.sh:70` fires on EVERY theme apply — fully clears and re-executes the Lua config from scratch, wiping any `hyprctl eval` override.** An eval-only design passes every test and then quietly undoes itself the first time the operator changes theme. Persistence therefore lives in the Lua config, mirroring the token pipeline that already solves exactly this problem for colours.

**Step 1 — `lib/overrides.lua`, on `lib/tokens.lua`'s exact shape.** A defensive accessor: `M.get()` does `pcall(require, "state.overrides")`, normalises the result, and returns `{}`-backed sub-tables (`monitors`, `input`, `input.touchpad`) so a caller can index two levels deep even when the whole file is absent or syntactically broken. Both failure classes — missing file and malformed file — normalise to the SAME empty-table fallback, so no caller special-cases either. Write a header on `tokens.lua`'s model recording that a missing file would otherwise stop the compositor from starting at all, and that this function's job is narrower than defaulting values: it guarantees the SHAPE; individual values are defaulted with `or` at the point of use.

**Step 2 — consume it, with the repo's `or` discipline.**
- `config/monitors.lua`: `local ov = require("lib.overrides").get()`. Each existing `hl.monitor({ ... })` call keeps its current literals as the fallback: `mode = (ov.monitors["DP-1"] or {}).mode or "2560x1440@165"`, and the same for `position` and `scale`. Do the same for the `Unknown-1` duplicate declaration, which is a deliberate both-names cover, not migration noise. **Merge at the table level and emit exactly one `hl.monitor` call per output** — RESEARCH.md A2 flags that whether a second `hl.monitor()` for the same output replaces or appends is unmeasured, so never emit two.
- `hyprland.lua`'s `input` block: same treatment for `kb_layout`, `follow_mouse`, `sensitivity` and `touchpad.natural_scroll`, each keeping its current literal as the `or` fallback. Call `require("lib.overrides").get()` independently at the top beside `lib.tokens` — do NOT read a value some previously-loaded module happened to set. That independence is what makes "no module depends on another being loaded first" structurally true rather than a convention.

**Step 3 — `stow.sh` wiring.** Beside the existing `tokens.lua` block (~line 492): `mkdir -p "$HOME/.local/state/hypr"`, seed `overrides.lua` with `return {}` ONLY when absent (the same seed-only discipline `stow.sh:311`/`:331` already applies — never clobber a live operator's settings), then `ln -sf "../../../.local/state/hypr/overrides.lua" "$HOME/.config/hypr/state/overrides.lua"`. **Relative, never absolute** — the reproducibility rule established in quick task 260709-ciu. Add it to `stow-link-check`'s expectations if that gate enumerates links explicitly.

**Step 4 — `hypr-overrides.sh`, the live+persist pair.** A new script under `hypr/.config/hypr/scripts/`, owning both halves so the QML page never writes anything itself (D-03).
- **Validate first, on a closed allowlist.** Output names must appear in `hyprctl monitors -j`'s `.name` set. Mode strings must match `^[0-9]+x[0-9]+@[0-9]+(\.[0-9]+)?$` AND appear in that monitor's own `availableModes` after normalisation. Scale must parse as a bounded float. Input values must come from fixed enumerations. Anything else exits non-zero and writes nothing. This is not defensive padding — the validated string is interpolated into a Lua expression handed to the compositor and into a Lua file the compositor `require`s at boot (see `<threat_model>` T-SQD-01/T-SQD-02).
- **Normalise the format mismatch.** `availableModes` entries read `"2560x1440@165.00Hz"`; the `mode` field `hl.monitor` accepts reads `"2560x1440@165"` (`config/monitors.lua:17`). Strip the `Hz` and trim the trailing zeros. And `refreshRate` reads back as `164.99899`, which will never string-match `165.00` — compare the parsed float within a tolerance, or the currently-active-mode indicator shows nothing selected.
- **Apply live via `hyprctl eval`**, on `gaming-mode-toggle.sh:135-138`'s proven shape (`hl.monitor({...})` for outputs, `hl.config({ input = {...} })` for input). Never `hyprctl keyword` — it is a silent no-op for every key under the Lua config manager, exit 0 even for a nonsense key.
- **Verify against the JSON oracle, never the reply.** After the eval, assert against `hyprctl monitors -j` (`.width`/`.height`/`.refreshRate`/`.scale`) or `hyprctl getoption <key> -j`. `hypridle.conf:22-24` records this repo's own finding verbatim: the `ok` reply lies here.
- **Persist only after the live apply verified.** Emit the whole overrides table from validated fields through a fixed template — never raw passthrough of an input string — and write atomically with tmp + `mv`, on `motion-switch.sh:142-143`'s shape. Ordering matters: a bad mode that has not been proven live must never reach a file the compositor reads at boot (T-SQD-03).

**Step 5 — `DisplayInputPage.qml`.** A `PageBase` with two `SettingsSection`s.
- **Monitors** — build the model from `hyprctl monitors -j`; the 32-entry `availableModes` list IS the resolution/refresh dropdown model, so there is no probing, no `wlr-randr` and no `nwg-displays` parsing. Per output: a resolution+refresh `SelectRow` and a scale `SelectRow`. Flat list, one section per output (F-04 defers drill-down; this host has one).
- **Input** — global `input { }` granularity, which is the right level: `hyprctl devices -j` reports 7 keyboards and 6 mice here, most of them phantom sub-devices of the same physical hardware, so a per-device UI would be noise (F-03). Rows for keyboard layout, follow-mouse, pointer sensitivity (`SliderRow`) and touchpad natural-scroll (`ToggleRow`).
- **Advanced** — one `NavRow` running `uwsm app -- nwg-displays`, the documented escape hatch, reusing what the walker Display row already points at.
- Every change calls `hypr-overrides.sh`; the row's UI state updates only after the script exits zero. Replace the last `placeholderComp` in `PageCompRegistry.comps` with this page.

**Step 6 — `hypr-equivalence-check` gets `VOLATILE_KEYS` (PD-04).** A third table beside `ACCEPTED_OPTION_CHANGES`, holding exactly the option keys `overrides.lua` can write. The comparator REPORTS a difference on a volatile key as a note and does not assert on it. Write the rationale into the table's header comment: an operator-adjustable value is structurally unsatisfiable against a frozen value-equality baseline, and this is the same shape that made LEDGER-07 unreachable rather than merely stale. **Do not re-capture the baseline** — `hypr-equivalence-check:349-384` records that it would overwrite the two deliberately un-loosened `bindm` records. Size the table to exactly the writable keys and no wider; a `VOLATILE_KEYS` entry is a permanent hole in the comparator.

**Step 7 — fault-inject the persistence chain offline.** Use `hypr-lua-harness start --entry ~/.config/hypr/hyprland.lua` ONCE, with `hypr-lua-harness stop` on every exit path, to boot an isolated nested compositor and prove three things without touching the operator's live display: (a) a valid overrides table is honoured, (b) a syntactically broken `overrides.lua` still boots the compositor with repo defaults, (c) an absent `overrides.lua` does the same. This is the repo's own sanctioned tool for exactly this — it is not a QML probe window and it is not a screenshot.

**Step 8 — hand off, do not close.** The operator's live visual pass covers the whole window and is filed by Task 4, which is the last task to touch the surface. Do not open a `WINDOWS.md` row here and do not attempt a visual check — Task 4 owns both.
  </action>

  <verify>
    <automated><![CDATA[
set -uo pipefail
cd /home/aorus/dotfiles
FAIL=0
SD=quickshell/.config/quickshell/modules/settings

# --- A. hyprctl keyword must appear NOWHERE in the new script (it is a silent no-op) ---
KW=$(grep -v '^[[:space:]]*#' hypr/.config/hypr/scripts/hypr-overrides.sh | grep -c 'hyprctl keyword' || true)
[ "$KW" -eq 0 ] || { echo "FAIL: hypr-overrides.sh uses hyprctl keyword ($KW sites) — silent no-op under Lua"; FAIL=1; }

# --- B. the JSON oracle is consulted; the reply string is not the evidence ---
ORACLE=$(grep -v '^[[:space:]]*#' hypr/.config/hypr/scripts/hypr-overrides.sh | grep -c 'hyprctl \(monitors\|getoption\).*-j' || true)
[ "$ORACLE" -ge 1 ] || { echo "FAIL: hypr-overrides.sh never verifies against hyprctl -j"; FAIL=1; }

# --- C. atomic write (tmp + mv), on motion-switch.sh's shape ---
ATOMIC=$(grep -v '^[[:space:]]*#' hypr/.config/hypr/scripts/hypr-overrides.sh | grep -c '\.tmp.*&&.*mv\|mv .*\.tmp' || true)
[ "$ATOMIC" -ge 1 ] || { echo "FAIL: overrides write is not atomic"; FAIL=1; }

# --- D. defensive accessor: pcall + shape normalisation, tokens.lua's contract ---
PC=$(grep -c 'pcall(require, "state.overrides")' hypr/.config/hypr/lib/overrides.lua || true)
[ "$PC" -eq 1 ] || { echo "FAIL: lib/overrides.lua does not pcall-require state.overrides"; FAIL=1; }

# --- E. every consumed key keeps its literal fallback (D-13's `or` guarantee) ---
for k in mode position scale; do
  N=$(grep -v '^[[:space:]]*--' hypr/.config/hypr/config/monitors.lua | grep -c "${k} = .*or " || true)
  [ "$N" -ge 2 ] || { echo "FAIL: monitors.lua '$k' lacks an 'or' fallback on both declarations (found $N)"; FAIL=1; }
done
for k in kb_layout follow_mouse sensitivity; do
  N=$(grep -v '^[[:space:]]*--' hypr/.config/hypr/hyprland.lua | grep -c "${k} = .*or " || true)
  [ "$N" -ge 1 ] || { echo "FAIL: hyprland.lua input '$k' lacks an 'or' fallback"; FAIL=1; }
done

# --- F. exactly one hl.monitor call per output (RESEARCH.md A2 — never stack declarations) ---
HM=$(grep -v '^[[:space:]]*--' hypr/.config/hypr/config/monitors.lua | grep -c 'hl\.monitor(' || true)
[ "$HM" -eq 2 ] || { echo "FAIL: expected 2 hl.monitor calls (DP-1, Unknown-1), found $HM"; FAIL=1; }

# --- G. relative symlink, never absolute ---
REL=$(grep -v '^[[:space:]]*#' stow.sh | grep -c 'ln -sf "\.\./\.\./\.\./\.local/state/hypr/overrides\.lua"' || true)
[ "$REL" -eq 1 ] || { echo "FAIL: stow.sh overrides symlink missing or not relative"; FAIL=1; }
SEED=$(grep -v '^[[:space:]]*#' stow.sh | grep -c 'state/hypr/overrides\.lua' || true)
[ "$SEED" -ge 2 ] || { echo "FAIL: stow.sh does not seed-when-absent + link overrides.lua"; FAIL=1; }

# --- H. no placeholders left; all four pages real ---
PH=$(grep -v '^[[:space:]]*//' "$SD/PageCompRegistry.qml" | grep -c 'placeholderComp' || true)
[ "$PH" -le 1 ] || { echo "FAIL: placeholderComp still used in comps ($PH refs)"; FAIL=1; }

# --- I. offline fault injection in a NESTED compositor (never the live session) ---
trap 'hypr-lua-harness stop >/dev/null 2>&1 || true' EXIT
OV="$HOME/.local/state/hypr/overrides.lua"
cp -a "$OV" "$OV.planbak" 2>/dev/null || true
printf 'return { this is not lua\n' > "$OV"
hypr-lua-harness start --entry "$HOME/.config/hypr/hyprland.lua" >/dev/null 2>&1 \
  || { echo "FAIL: compositor did not boot with a MALFORMED overrides.lua"; FAIL=1; }
hypr-lua-harness hyprctl monitors -j | jq -e '.[0].name != null' >/dev/null \
  || { echo "FAIL: nested compositor has no monitor after malformed-overrides boot"; FAIL=1; }
hypr-lua-harness stop >/dev/null 2>&1 || true
mv "$OV.planbak" "$OV" 2>/dev/null || printf 'return {}\n' > "$OV"

# --- J. the reload-survival proof (RESEARCH.md Pitfall 2 — the headline finding) ---
#     Value-preserving round trip: write the CURRENT values through the override
#     path, reload, and confirm they still hold. Never change the operator's
#     live display to test this.
CUR=$(hyprctl monitors -j | jq -r '.[0].name')
CURSCALE=$(hyprctl monitors -j | jq -r '.[0].scale')
hypr/.config/hypr/scripts/hypr-overrides.sh monitor "$CUR" --scale "$CURSCALE" \
  || { echo "FAIL: hypr-overrides.sh rejected a round-trip of live values"; FAIL=1; }
hyprctl reload >/dev/null; sleep 3
hyprctl monitors -j | jq -e --arg n "$CUR" --argjson s "$CURSCALE" \
  '.[] | select(.name==$n) | .scale == $s' >/dev/null \
  || { echo "FAIL: override did NOT survive hyprctl reload — persistence chain broken"; FAIL=1; }

# --- K. gates, including the clean-tree invariant D-03 exists to protect ---
hypr/.config/hypr/scripts/hypr-equivalence-check || { echo "FAIL: hypr-equivalence-check"; FAIL=1; }
hypr/.config/hypr/scripts/stow-link-check        || { echo "FAIL: stow-link-check"; FAIL=1; }
hypr/.config/hypr/scripts/colour-lint            || { echo "FAIL: colour-lint"; FAIL=1; }
hypr/.config/hypr/scripts/motion-lint            || { echo "FAIL: motion-lint"; FAIL=1; }
hypr/.config/hypr/scripts/keybind-doctor         || { echo "FAIL: keybind-doctor"; FAIL=1; }
~/.config/theme-engine/theme-doctor              || { echo "FAIL: theme-doctor"; FAIL=1; }

[ "$FAIL" -eq 0 ] && echo "TASK 3 VERIFY: PASS"
exit "$FAIL"
]]></automated>

  </verify>

  <done>
Display + input is live and persistent: a monitor or input change applies through `hyprctl eval`, is verified against `hyprctl -j` rather than the lying `ok` reply, and survives `hyprctl reload` — proven by the value-preserving round trip in check J. A malformed or absent `overrides.lua` boots the compositor to repo defaults, proven offline in a nested harness rather than against the operator's display. All four pages are real; no `placeholderComp` remains in `comps`. `hypr-equivalence-check` carries a `VOLATILE_KEYS` table sized to exactly the writable keys, with the baseline untouched. Every gate is at zero failures and the git tree is clean. Committed. The operator's live pass is NOT run here — Task 4 is the last task to touch the surface and owns it.
  </done>
</task>

<task type="auto" tdd="false">
  <name>Task 4: Idle and lock timing, EDITABLE — re-measure the mechanism, then wire it</name>

  <precondition>`hypridle --version` reports v0.1.8. PD-03's mechanism table was measured against exactly that build during planning; a different version invalidates it and the Step 1 gate below must be re-run from scratch before any UI work.</precondition>

  <files>
hypr/.config/hypr/scripts/idle-overrides.sh,
hypr/.config/hypr/hypridle.conf,
quickshell/.config/quickshell/modules/settings/pages/ShellBehaviourPage.qml,
stow.sh,
.planning/WINDOWS.md
  </files>

  <reversibility rating="costly">
This moves all five `listener` blocks out of the tracked `hypridle.conf` and into a state-dir file. Reversing means copying them back and dropping the `source =` line — mechanical, but the operator loses their adjusted timeouts. The genuinely dangerous direction is not reversal but breakage: idle lock is a security control, and probe A measured that hypridle proceeds with ZERO rules on a broken config rather than failing loudly. A machine that silently never locks is the failure mode to design against (T-SQD-08).
  </reversibility>

  <behavior>
- The Shell behaviour page gains an editable Idle & lock section: one row per listener (screen dim, screen off, lock, suspend, and the DPMS resume pair as configured), each a stepper/select over a bounded set of minute values.
- Changing a timeout applies to the running idle daemon and survives a reboot.
- `git status --porcelain` is empty after any number of adjustments.
- A corrupted or deleted overrides file never leaves the machine unlockable — it is re-seeded from repo defaults and the previous good file is restored on a failed apply.
  </behavior>

  <action>
The operator overrode the read-only descope (CONTEXT.md V1-scope, 2026-08-20). These timeouts are editable. The mechanism is already measured — PD-03's table records five probes against `hypridle v0.1.8`, including a positive control proving sourced content is genuinely applied — but Step 1 re-confirms it on the executor's machine before any UI is wired, because that is the hard rule and a package update between planning and execution would silently invalidate it.

**Step 1 — the mechanism gate. Run this BEFORE touching `hypridle.conf` or the page.** Reproduce PD-03's probes B and C against the installed binary, in a scratch directory, with no listener under 30 s so nothing can fire:
- Probe B: `source =` a path that does not exist. Expect `source= globbing error: found no match` cited at file and line. That proves the keyword is *handled*.
- Probe C: `source =` a real file containing one `listener` block with `timeout = 99999`. Expect `found 1 rules` and, critically, the ABSENCE of `No rules configured`. That proves the include is *applied*, not merely tolerated.
If either probe disagrees with PD-03, **HALT and report** — the fallback shape (a script that regenerates a complete effective config into the state dir and points hypridle at it via `-c`, which `--help` confirms exists) is a different design and needs the operator's call, not an improvisation. Do not proceed to Step 2 on a failed gate.

**Step 2 — restructure `hypridle.conf` (one tracked edit, at build time only).** Move ALL five `listener` blocks out of `hypr/.config/hypr/hypridle.conf` and leave the `general { }` block plus a single `source = ~/.local/state/hypr/idle-overrides.conf` line. **All five, not some.** hyprlang APPENDS listener blocks rather than replacing them (measured, probe C), so any listener left behind in the tracked file would coexist with its override and fire at whichever timeout is shorter — meaning a timeout could be shortened but never lengthened. Keep the file's existing explanatory comments, including the `hypridle.conf:22-24` note about the lying `ok` reply, and add a short one naming the state-dir file as the live source of the listeners. This is the ONLY write this task makes to a tracked file, and it happens once at build time — never per adjustment, so D-03 holds.

**Step 3 — `stow.sh` seeding.** Beside the `overrides.lua` block Task 3 added: `mkdir -p "$HOME/.local/state/hypr"`, and seed `idle-overrides.conf` from the repo's default timeouts ONLY when absent, using the same seed-only discipline (`stow.sh:311`/`:331`) so a live operator's adjusted timeouts are never clobbered. Unlike `overrides.lua`, this file is sourced by an absolute-ish path in `hypridle.conf` rather than a symlink, so no `ln -sf` is needed — but if you do add one, it is relative, never absolute. **The seed is load-bearing for the security property**: a fresh install with no seeded file gets zero listeners and never locks.

**Step 4 — `idle-overrides.sh`, on `hypr-overrides.sh`'s validate -> apply -> verify -> persist ordering.**
- **Validate.** Timeouts are integers within a bounded range with a hard floor (no listener below 30 s — a 1 s lock timeout is indistinguishable from a denial of service). Enforce ordering sanity: dim < screen-off < lock < suspend. Reject and exit non-zero on anything else, writing nothing.
- **Persist atomically**, tmp + `mv` on `motion-switch.sh:142-143`'s shape, after first copying the current file to a backup.
- **Apply by restarting the daemon — and NOT via systemd.** MEASURED (PD-03 probe E): `hypridle.service` is `inactive`/`disabled` on this host; the live process is the uwsm transient scope `app-Hyprland-hypridle-*.scope` started by `hl.exec_cmd("uwsm app -- hypridle")` at `autostart.lua:177`. `systemctl --user restart hypridle` would exit cleanly and change nothing. Terminate the running process and relaunch it exactly as autostart does. hypridle has no SIGHUP handler (probe D), so a restart is the only path.
- **Verify, then roll back on failure.** After the restart, confirm the effective config parses to the expected number of rules — run `timeout 2 hypridle -c <config>` in a throwaway and read its `found N rules` line, which is safe because validation already guaranteed no timeout under 30 s. If the count is wrong or zero, restore the backup, restart again, and exit non-zero. **Never leave the machine with zero idle rules** (T-SQD-08).

**Step 5 — the UI section.** Fill the seam Task 2 left at the bottom of `ShellBehaviourPage.qml` with an Idle & lock `SettingsSection`: one row per listener, each a bounded select/stepper over minute values, current values parsed from the state-dir file (not from the tracked `hypridle.conf` — that no longer holds them). Every change calls `idle-overrides.sh`; the row's UI state updates only after the script exits zero, matching the Display+input discipline. Keep an Advanced `NavRow` that opens the state-dir file in `$EDITOR` for anything the bounded controls do not cover. **The page writes nothing itself** — the script owns the write (D-03).

**Step 6 — file the operator's live-pass row.** Add a row to `.planning/WINDOWS.md` (next id after 91, kind `unrun-verify`, phase `quick-260820-sqd`, status `open`) recording that the live visual pass across the whole settings window is outstanding, and increment `open_count` and `total_count` in the frontmatter. It closes on the `<human-check>` below.
  </action>

  <verify>
    <automated><![CDATA[
set -uo pipefail
cd /home/aorus/dotfiles
FAIL=0
SD=quickshell/.config/quickshell/modules/settings
SCRATCH=$(mktemp -d); trap 'rm -rf "$SCRATCH"' EXIT

# --- STEP 1 GATE: re-measure the mechanism BEFORE trusting any of the wiring ---
printf 'source = %s/nope.conf\n' "$SCRATCH" > "$SCRATCH/b.conf"
B=$(timeout 3 hypridle -c "$SCRATCH/b.conf" 2>&1 | grep -ci 'source=.*globbing error' || true)
[ "$B" -ge 1 ] || { echo "FAIL: hypridle does not handle 'source =' — PD-03 invalidated, HALT"; FAIL=1; }

printf 'listener {\n    timeout = 99999\n    on-timeout = true\n}\n' > "$SCRATCH/inc.conf"
printf 'source = %s/inc.conf\n' "$SCRATCH" > "$SCRATCH/c.conf"
COUT=$(timeout 3 hypridle -c "$SCRATCH/c.conf" 2>&1 || true)
NORULES=$(printf '%s\n' "$COUT" | grep -ci 'No rules configured' || true)
GOTRULE=$(printf '%s\n' "$COUT" | grep -ci 'found 1 rules' || true)
[ "$NORULES" -eq 0 ] && [ "$GOTRULE" -ge 1 ] \
  || { echo "FAIL: sourced listener NOT applied (norules=$NORULES gotrule=$GOTRULE) — PD-03 invalidated, HALT"; FAIL=1; }
[ "$FAIL" -eq 0 ] || { echo "MECHANISM GATE FAILED — do not evaluate the rest"; exit 1; }
echo "MECHANISM GATE: source= handled AND applied — PD-03 reconfirmed"

# --- A. ALL listeners moved out of the tracked file (append-not-replace, measured) ---
TL=$(grep -v '^[[:space:]]*#' hypr/.config/hypr/hypridle.conf | grep -c '^[[:space:]]*listener[[:space:]]*{' || true)
[ "$TL" -eq 0 ] || { echo "FAIL: $TL listener block(s) still in the TRACKED hypridle.conf — they would coexist with overrides"; FAIL=1; }
SRC=$(grep -v '^[[:space:]]*#' hypr/.config/hypr/hypridle.conf | grep -c '^[[:space:]]*source[[:space:]]*=' || true)
[ "$SRC" -eq 1 ] || { echo "FAIL: expected exactly 1 source= line in hypridle.conf, found $SRC"; FAIL=1; }

# --- B. the state-dir file holds the listeners and hypridle parses the pair ---
IO="$HOME/.local/state/hypr/idle-overrides.conf"
[ -f "$IO" ] || { echo "FAIL: $IO missing — stow.sh seed did not run"; FAIL=1; }
SL=$(grep -c '^[[:space:]]*listener[[:space:]]*{' "$IO" 2>/dev/null || echo 0)
[ "$SL" -ge 5 ] || { echo "FAIL: state-dir file has $SL listeners, expected >= 5"; FAIL=1; }
EFF=$(timeout 3 hypridle -c "$HOME/.config/hypr/hypridle.conf" 2>&1 || true)
printf '%s\n' "$EFF" | grep -ci 'No rules configured' | grep -qx 0 \
  || { echo "FAIL: effective config yields NO rules — the machine would never lock"; FAIL=1; }

# --- C. restart path is uwsm, NOT systemd (measured: the unit is inactive/disabled) ---
SYS=$(grep -v '^[[:space:]]*#' hypr/.config/hypr/scripts/idle-overrides.sh | grep -c 'systemctl .*hypridle' || true)
[ "$SYS" -eq 0 ] || { echo "FAIL: idle-overrides.sh restarts via systemctl ($SYS sites) — the unit is inactive, this is a silent no-op"; FAIL=1; }
UW=$(grep -v '^[[:space:]]*#' hypr/.config/hypr/scripts/idle-overrides.sh | grep -c 'uwsm app -- hypridle' || true)
[ "$UW" -ge 1 ] || { echo "FAIL: idle-overrides.sh never relaunches via 'uwsm app -- hypridle'"; FAIL=1; }

# --- D. validate -> apply -> verify -> persist: floor, ordering, atomic write, rollback ---
ATOMIC=$(grep -v '^[[:space:]]*#' hypr/.config/hypr/scripts/idle-overrides.sh | grep -c '\.tmp.*&&.*mv\|mv .*\.tmp' || true)
[ "$ATOMIC" -ge 1 ] || { echo "FAIL: idle-overrides.sh write is not atomic"; FAIL=1; }
RB=$(grep -v '^[[:space:]]*#' hypr/.config/hypr/scripts/idle-overrides.sh | grep -ci 'bak\|restore\|rollback' || true)
[ "$RB" -ge 1 ] || { echo "FAIL: idle-overrides.sh has no rollback path (T-SQD-08)"; FAIL=1; }

# --- E. the validator actually refuses bad input (behaviour, not just presence) ---
hypr/.config/hypr/scripts/idle-overrides.sh --set lock=1 2>/dev/null \
  && { echo "FAIL: accepted a 1-second lock timeout (below the 30s floor)"; FAIL=1; } \
  || echo "ok: sub-floor timeout rejected"
hypr/.config/hypr/scripts/idle-overrides.sh --set lock=abc 2>/dev/null \
  && { echo "FAIL: accepted a non-integer timeout"; FAIL=1; } \
  || echo "ok: non-integer rejected"

# --- F. seed-when-absent must restore, never clobber (the security property) ---
cp -a "$IO" "$SCRATCH/io.bak"
rm -f "$IO"
./stow.sh >/dev/null 2>&1 || true
[ -f "$IO" ] || { echo "FAIL: stow.sh did not re-seed a MISSING idle-overrides.conf"; FAIL=1; }
cp -a "$SCRATCH/io.bak" "$IO"

# --- G. the page reads the state-dir file, never the tracked one ---
TREF=$(grep -rn 'hypr/hypridle\.conf\|\.config/hypr/hypridle\.conf' "$SD" 2>/dev/null | grep -vc '^[[:space:]]*//' || true)
[ "$TREF" -eq 0 ] || { echo "FAIL: settings/ still references the tracked hypridle.conf ($TREF sites)"; FAIL=1; }

# --- H. gates + the clean-tree invariant this whole decision hinges on ---
hypr/.config/hypr/scripts/colour-lint || { echo "FAIL: colour-lint"; FAIL=1; }
hypr/.config/hypr/scripts/motion-lint || { echo "FAIL: motion-lint"; FAIL=1; }
~/.config/theme-engine/theme-doctor    || { echo "FAIL: theme-doctor"; FAIL=1; }
DIRTY=$(git status --porcelain | wc -l)
[ "$DIRTY" -eq 0 ] || { echo "FAIL: tree dirty after idle adjustments — D-03 broken"; git status --porcelain; FAIL=1; }

[ "$FAIL" -eq 0 ] && echo "TASK 4 VERIFY: PASS"
exit "$FAIL"
]]></automated>

    <human-check>
**Operator live pass — the only step an agent must not attempt on this host.**

Do not let an agent screenshot or drive this. A full-screen `grim` capture SIGSEGVs the compositor here, and a `FloatingWindow` is not a layer surface, so even the `grim -g` recipe is unproven for it.

Please check, in a real session:

1. `Super+comma` opens a centred floating Settings window; pressing it again closes it. The walker Settings menu's new top row opens the same window.
2. The window takes pointer AND keyboard input — a dropdown opens on click, arrow keys move the selection, Esc closes the window.
3. The nav rail shows four groups and clicking each swaps the page with no flicker or stall.
4. **Appearance:** picking a theme re-colours the desktop AND the settings window itself. Bar orientation flips the bar. Wallpaper, Icon theme and Font each open their existing kitty picker.
5. **Audio & connectivity:** each of the three rows opens the existing panel you already know.
6. **Display & input:** the resolution/refresh dropdown lists your real modes with the current one marked. Change the pointer sensitivity and feel it change. Then **switch theme** and confirm the display/input change is still in effect — that is the failure Task 3 was built around.
7. **Shell behaviour — motion and DND:** motion preset visibly changes animation speed; the DND toggle matches the notification centre's own state.
8. **Shell behaviour — idle & lock (the new editable section):** the rows show your real current timeouts. Shorten the screen-dim timeout to something you can wait out, confirm it actually dims at the new time, then set it back. **Then LENGTHEN the lock timeout and confirm it locks at the new longer time, not the old shorter one** — that is the specific failure the append-not-replace finding predicts if any listener was left behind in the tracked config.
9. Reboot (or log out and back in) and confirm your adjusted timeouts survived.
10. Nothing looks off-palette or hardcoded.

Reply with a pass/fail per item. On pass, close `.planning/WINDOWS.md`'s row with `gsd-tools windows fixed <id>`.
    </human-check>
  </verify>

  <done>
Idle and lock timeouts are editable from the settings window and the mechanism was re-measured before the UI was wired, not assumed: the Step 1 gate reconfirmed that hypridle handles `source =` AND applies the sourced content. All five listener blocks live in `~/.local/state/hypr/idle-overrides.conf`; the tracked `hypridle.conf` holds the `general` block and one `source =` line and is never written again. `idle-overrides.sh` validates against a 30 s floor and an ordering rule, writes atomically, restarts via `uwsm app -- hypridle` (never systemd — the unit is inactive here), verifies the effective rule count, and rolls back rather than leaving the machine with zero idle rules. `stow.sh` re-seeds a missing file, proven by fault injection in check F. The tree is clean, every gate is at zero failures, and the `WINDOWS.md` row is filed. This task — and the plan — is not complete until the `<human-check>` comes back green, item 8 in particular.
  </done>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| QML settings page -> `hyprctl eval` | A UI-selected string is interpolated into a Lua expression the compositor evaluates with full compositor privilege. |
| `hypr-overrides.sh` -> `~/.local/state/hypr/overrides.lua` | A generated file the compositor `require`s — i.e. executes as Lua — at every boot and every reload. |
| `idle-overrides.sh` -> `~/.local/state/hypr/idle-overrides.conf` | A generated file that now solely determines whether and when the machine locks. |
| `hyprctl monitors -j` -> settings page | Device-supplied strings (`make`, `model`, `description`, `availableModes`) originate outside this repo and flow into both the UI and the generated Lua. |
| Settings page -> existing scripts | Command strings dispatched to `theme-apply`, `bar-orientation.sh`, `motion-switch.sh` and the kitty pickers. |

## STRIDE Threat Register

| Threat ID | Category | Component | Severity | Disposition | Mitigation Plan |
|-----------|----------|-----------|----------|-------------|-----------------|
| T-SQD-01 | Tampering / Elevation | `hypr-overrides.sh` -> `hyprctl eval` | high | mitigate | Closed allowlist BEFORE any eval: output name must be in `hyprctl monitors -j`'s `.name` set; mode must match `^[0-9]+x[0-9]+@[0-9]+(\.[0-9]+)?$` AND be in that monitor's own `availableModes`; scale must parse as a bounded float; input values come from fixed enumerations. Anything else exits non-zero and writes nothing. (Task 3 Step 4.) |
| T-SQD-02 | Tampering | `~/.local/state/hypr/overrides.lua` | high | mitigate | The file is emitted from validated fields through a fixed template, never raw passthrough. `lib/overrides.lua` wraps the `require` in `pcall` and type-checks every sub-table, so a hostile or corrupt file degrades to `{}` and the compositor still boots on repo defaults. Fault-injected offline in a nested harness (Task 3 Step 7, verify check I). |
| T-SQD-03 | Denial of Service | monitor mode persistence | high | mitigate | Ordering is the mitigation: validate -> apply live -> verify against `hyprctl monitors -j` -> only then persist. A mode never proven live cannot reach the file the compositor reads at boot, so the window cannot brick the display into an unrecoverable blank-at-every-boot state. |
| T-SQD-04 | Tampering | device strings from `hyprctl monitors -j` / `devices -j` | medium | mitigate | Treated as untrusted display text: rendered as text only (never as QML markup or a shell fragment) and never interpolated into the generated Lua — only the normalised, allowlist-matched mode/scale values are. |
| T-SQD-05 | Elevation of Privilege | script dispatch from QML | medium | mitigate | Every dispatch is a fixed argv to a known repo script; no user-typed string reaches a shell. Panel summons route through `shell.qml`'s `openPanel()`, the single place the DASH-08 refusal guard is read (Task 2). |
| T-SQD-08 | Denial of Service / Elevation | `~/.local/state/hypr/idle-overrides.conf` -> idle lock | high | mitigate | **Idle lock is a security control and this file now owns it.** MEASURED (PD-03 probe A): hypridle proceeds with ZERO rules on a broken config rather than failing loudly, so a corrupt or missing overrides file silently leaves the machine that never locks. Four-part mitigation: `stow.sh` seeds from repo defaults when absent (fault-injected in Task 4 verify check F); `idle-overrides.sh` validates against a 30 s floor plus an ordering rule and rejects anything else; the write is atomic tmp+`mv` over a backup; and after the restart the script verifies the effective rule count and restores the backup if it dropped. |
| T-SQD-06 | Information Disclosure | settings window content | low | accept | The window surfaces no secrets. Wi-Fi PSK entry stays in the existing `WifiPanel`, which already owns that flow; this surface only summons it. |
| T-SQD-07 | Repudiation | state writes | low | accept | Every write goes through an existing script to `~/.local/state`, matching the repo's established convention. No new audit requirement is introduced by this task. |
| T-SQD-SC | Tampering | supply chain | n/a | accept | No `npm`/`pip`/`cargo` installs and no new packages of any kind. Every dependency (`quickshell`, `jq`, `hyprctl`, `playerctl`) is already installed and already in `install.sh`. No package-legitimacy gate applies. |
</threat_model>

<source_audit>
Every item from every source artifact, mapped to the task that delivers it. No item is silently dropped.

| Source | Item | Status | Where |
|--------|------|--------|-------|
| CONTEXT D-01 | Appearance: theme | COVERED | Task 1 (PD-05, inline `SelectRow` + `theme-apply`) |
| CONTEXT D-01 | Appearance: wallpaper, icon theme, font | COVERED | Task 2 (`NavRow` -> existing kitty pickers, D-04) |
| CONTEXT D-01 | Appearance: bar orientation | COVERED | Task 2 (inline `SelectRow` -> `bar-orientation.sh`) |
| CONTEXT D-01 | Audio mixer, wifi, bluetooth | COVERED | Task 2 (`ConnectivityPage` -> `openPanel()`) |
| CONTEXT D-01 | Display: monitor resolution / refresh / scale | COVERED | Task 3 (`DisplayInputPage` + `hypr-overrides.sh`) |
| CONTEXT D-01 | Input: keyboard / mouse options | COVERED | Task 3 (global `input { }` block; per-device deferred as F-03) |
| CONTEXT D-01 | Shell: motion preset | COVERED | Task 2 (`motion-switch.sh --list`/`--get`) |
| CONTEXT D-01 | Shell: notification DND | COVERED | Task 2 (`NotifServer.toggleDnd()`) |
| CONTEXT D-01 | Shell: idle/lock timing — **EDITABLE** (operator decision 2026-08-20, overriding the research descope) | COVERED | Task 4 — full read/write via a measured `source =` include; mechanism gate runs before the UI is wired (PD-03) |
| CONTEXT D-01 | Shell: OSD knobs | COVERED | Task 2 — the OSD's own knobs ARE the motion preset and DND rows; `Osd.qml` exposes no separate persisted setting (`modules/osd/qmldir` declares only `Osd`/`OsdSliderRow`). Recorded rather than silently absorbed. |
| CONTEXT D-02 | Centred floating window, left nav rail, page per group | COVERED | Task 1 (PD-01 `FloatingWindow` + `windowrules.lua` `center = true`) |
| CONTEXT D-02 | **`FloatingWindow` operator-confirmed 2026-08-20**, still probe-gated; fall back to `PanelWindow` and SURFACE the change if falsified | COVERED | Task 1 — PD-01 records it as locked; Task 1 Step 1 HALTs and reports rather than switching silently |
| CONTEXT D-02 | Not a dashboard tab, not a PanelDialog accordion | COVERED | Task 1 — standalone toplevel, no `PanelDialog` inheritance |
| CONTEXT D-03 | Scripts own the write, state in `~/.local/state` | COVERED | Tasks 1-3; enforced by Task 3 verify check K (theme-doctor clean-tree) |
| CONTEXT D-03 | Display+input needs a state-dir mechanism, not stowed-file edits | COVERED | Task 3 (`overrides.lua` + `stow.sh` symlink) |
| CONTEXT D-04 | QML-native controls inline | COVERED | Tasks 1-3 (`SelectRow`/`ToggleRow`/`SliderRow`) |
| CONTEXT D-04 | Kitty pickers and existing panels summoned, not rebuilt | COVERED | Task 2 |
| CONTEXT D-05 | PROJECT.md Out of Scope reversal, dated 2026-08-20 | COVERED | Task 1 Step 5 |
| CONTEXT D-06 | Entry points | COVERED | Task 1 (`Super+comma`, PD-02) + Task 2 (walker top row) |
| CONTEXT D-06 | Walker submenu fate | COVERED | Task 2 — all nine rows kept, one prepended |
| CONTEXT D-06 | Page layout / styling via Colours + Motion | COVERED | Tasks 1-3; enforced by colour-lint / motion-lint in every task's verify |
| CONTEXT D-06 | How Display+input writes reach Hyprland | COVERED | Task 3 (eval live + Lua overrides persist) |
| RESEARCH | Caelestia two-registry decomposition | COVERED | Task 1 Step 2 |
| RESEARCH | Lazy page incubation, previous-page destruction | COVERED | Task 1 Step 2 |
| RESEARCH | Category grouping via corner radii | COVERED | Task 1 Step 2 |
| RESEARCH | end-4 `ContentSection` hybrid | COVERED | Task 1 (`SettingsSection.qml`) |
| RESEARCH | Skip Caelestia Blobs / Config C++ plugins / dual-mode WindowFactory | COVERED | Not built — this repo's `Colours`/`Motion`/`Design` are used instead |
| RESEARCH | Skip `SearchBar` | DEFERRED (F-01) | Named follow-up |
| RESEARCH A1 | hypridle `source =` unverified | **MEASURED IN PLAN — assumption discharged** | PD-03's five-probe table. `source =` is handled AND applied (positive + negative controls); no SIGHUP handler; the systemd unit is inactive so the restart path is uwsm. Task 4 Step 1 re-runs the two decisive probes as a gate before wiring the UI. |
| RESEARCH A2 | Second `hl.monitor()` replace-vs-append unmeasured | HONOURED | Task 3 Step 2 emits exactly one call per output; verify check F asserts it |
| RESEARCH A3 | `FloatingWindow` never instantiated in this repo | HONOURED | Task 1 is a tracer that kills it first, with a recorded HALT-and-report fallback |
| RESEARCH A4 | `qs ipc` from a walker entry unproven | HONOURED | Task 2 carries the shim-script fallback inline |
| RESEARCH A5 | Constraining to keys outside the 46-key baseline may be impossible | HONOURED | PD-04 takes the other branch (`VOLATILE_KEYS`), which does not depend on A5 holding |
| RESEARCH OQ2 | FloatingWindow vs PanelWindow, decide before Task 1 | RESOLVED | PD-01 |
| RESEARCH OQ3 | hypr-equivalence-check and adjustable options | RESOLVED | PD-04 |
| RESEARCH OQ4 | Theme page enumerates vs shells out | RESOLVED | PD-05 |
| RESEARCH gates | colour-lint, motion-lint, keybind-doctor, hypr-equivalence-check, theme-doctor, stow-link-check, qmldir registration | COVERED | Every task's verify block |
| RESEARCH gates | `quickshell-doctor` `QSD_BAR_SURFACE_ROWS` | N/A under PD-01 | The registry keys on `WlrLayershell.namespace`, which a toplevel does not have. Becomes REQUIRED only if Task 1's probe fails and the `PanelWindow` fallback is taken. |
| CLAUDE.md | New bar/shell widgets are QML under `modules/`, coloured through `Colours.qml`, animated through `Motion.qml` | COVERED | Tasks 1-3 |
| CLAUDE.md | Walker menu edits need `elephant-restart.sh`, not a walker restart | COVERED | Task 2 |
</source_audit>

<verification>
Run after all three tasks, from the repo root, with the tree clean:

```bash
hypr/.config/hypr/scripts/colour-lint              # expect 150+ passed / 0 failed
hypr/.config/hypr/scripts/motion-lint              # expect 297+ passed / 0 failed
hypr/.config/hypr/scripts/keybind-doctor           # expect 15/0 (14 + the new chord)
hypr/.config/hypr/scripts/hypr-equivalence-check   # expect exit 0, Super+comma noted as an accepted addition
hypr/.config/hypr/scripts/stow-link-check          # expect 7/7 (6 + the overrides symlink)
hypr/.config/hypr/scripts/quickshell-doctor --self-test   # expect 59/0, unchanged
~/.config/theme-engine/theme-doctor                # expect 610+ passed / 0 failed, exit 0
git status --porcelain                             # expect empty
```

Pass counts move UP as surfaces are added; the criterion is always **failed = 0**, never the pass count itself. Re-run any live probe twice before believing it.
</verification>

<success_criteria>
- One `Super+comma` chord opens a centred floating Settings window with four working group pages (D-01, D-02).
- Every knob in all four groups routes its write through an existing script or an existing in-process owner; the QML pages write nothing directly (D-03, D-04).
- Idle and lock timeouts are editable, take effect on the running daemon, and survive a reboot — with the mechanism re-measured before the UI was wired (Task 4 Step 1 gate, PD-03).
- A lengthened lock timeout actually lengthens it — the append-not-replace check that proves no listener was left behind in the tracked config (human-check item 8).
- A Display+input change survives `hyprctl reload`, proven by the value-preserving round trip in Task 3 verify check J (RESEARCH.md Pitfall 2).
- A malformed or absent `overrides.lua` boots the compositor on repo defaults, proven offline in a nested harness (Task 3 verify check I).
- The git tree is clean after live exercise; theme-doctor exits 0.
- Every gate is at zero failures; no gate's pass count regressed.
- `.planning/PROJECT.md`'s Out of Scope entry records the reversal as a dated 2026-08-20 operator-directed decision (D-05).
- Task 3's `<human-check>` returns green from the operator and `.planning/WINDOWS.md`'s row for it is closed.
</success_criteria>

<output>
Create `.planning/quick/260820-sqd-build-an-in-shell-qml-settings-menu-cont/260820-sqd-SUMMARY.md` when done.

Record in it, at minimum:
- The **measured** `FloatingWindow` result (A3): the window class `hyprctl clients -j` reported, its geometry, and whether pointer/keyboard input worked — this is new ground truth for the repo and the next surface will want it.
- Whether `qs ipc call settings open` fired from a walker entry directly, or needed the shim script (A4).
- Whether a second `hl.monitor()` for the same output replaces or appends, if the work produced evidence either way (A2).
- The Task 4 Step 1 gate result — whether the installed hypridle still matched PD-03's measured table, and the effective rule count after the restructure. A1 is discharged in this plan; record any drift so the next surface does not re-derive it.
- The final gate pass/fail counts, and the operator's per-item verdict from the human-check.
</output>
