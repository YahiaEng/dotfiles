---
quick_id: 260822-sht
phase: quick-260822-sht     # not a roadmap phase; present so phase-plan tooling can parse this file
plan: "01"                  # single-plan quick task
wave: 1
depends_on: []
type: quick-full
description: migrate walker+elephant to a native Quickshell QML launcher
spec: .planning/notes/launcher-qml-migration-design.md
autonomous: true
requirements: [R-1, R-2, R-3, 260822-sht]
task_count: 12
stages: 3

files_modified:
  # Stage 1 — build
  - quickshell/.config/quickshell/modules/launcher/          # new package (whole dir)
  - quickshell/.config/quickshell/modules/qmldir
  - quickshell/.config/quickshell/shell.qml
  - quickshell/.config/quickshell/shortcuts.json
  # Stage 2 — migrate
  - hypr/.config/hypr/scripts/bar-orientation.sh
  - hypr/.config/hypr/scripts/clipboard-wipe.sh
  - hypr/.config/hypr/scripts/record-toggle.sh
  - hypr/.config/hypr/scripts/cheat-sheet-parser.sh
  - hypr/.config/hypr/config/keybinds.lua
  # Stage 3 — retire
  - hypr/.config/hypr/config/autostart.lua
  - hypr/.config/hypr/config/windowrules.lua
  - hypr/.config/hypr/config/env.lua
  - hypr/.config/hypr/scripts/keybind-doctor
  - hypr/.config/hypr/scripts/retirement-check
  - hypr/.config/hypr/scripts/motion-lint
  - hypr/.config/hypr/scripts/quickshell-doctor
  - hypr/.config/hypr/scripts/stow-link-check
  - hypr/.config/hypr/scripts/hypr-lua-harness
  - hypr/.config/hypr/scripts/tests/quickshell-fixtures/*.lua
  - theme-engine/.config/theme-engine/contract.json
  - theme-engine/.config/theme-engine/lib/reload.sh
  - theme-engine/.config/theme-engine/lib/commit.sh
  - theme-engine/.config/theme-engine/lib/contract.sh
  - theme-engine/.config/theme-engine/lib/gtk.sh
  - theme-engine/.config/theme-engine/theme-apply
  - theme-engine/.config/theme-engine/theme-doctor
  - theme-engine/.config/theme-engine/theme-stress-test
  - matugen/.config/matugen/config.toml
  - matugen/.config/matugen/templates/zellij-config.kdl
  - nvim/.config/nvim/colors/rice.lua
  - quickshell/.config/quickshell/modules/Dashboard.qml
  - quickshell/.config/quickshell/modules/Overview.qml
  - quickshell/.config/quickshell/modules/dashboard/NewsBackend.qml
  - quickshell/.config/quickshell/modules/dashboard/ToggleState.qml
  - quickshell/.config/quickshell/modules/settings/PageRegistry.qml
  - quickshell/.config/quickshell/modules/settings/pages/DisplayPage.qml
  - quickshell/.config/systemd/user/quickshell.service
  - verify/container-run.sh
  - verify/theme-doctor-session-allowlist.txt
  - install.sh
  - stow.sh
  - .stow-local-ignore
  - .gitignore
  - README.md
  - VERIFICATION.md

files_deleted:
  - walker/                                                   # whole package
  - elephant/                                                 # whole package
  - matugen/.config/matugen/templates/walker-style.css
  - hypr/.config/hypr/scripts/elephant-restart.sh
  - hypr/.config/hypr/scripts/theme-switch.sh
  - hypr/.config/hypr/scripts/emoji-picker.sh
  - hypr/.config/hypr/scripts/cheat-sheet.sh
  - hypr/.config/hypr/scripts/tests/test-walker-dmenu-cancel.sh

estimate:
  tokens: 620000
  raw_tokens: 310000
  tasks: 12
  confidence: low            # no calibration samples for a 12-task quick task in this repo

must_haves:
  truths:
    - "Super+Space opens a native QML launcher that lists installed applications and launches the picked one."
    - "A bare Super tap opens a native QML menu whose root is the 9 verb-based groups of D-2, with all 36 existing entries reachable and each leaf running the exact command its TOML entry ran."
    - "All six prefix routes still work from the one search field: = calc, / files, : clipboard, . symbols/emoji, ; providerlist, @ websearch."
    - "All 7 dmenu consumers still work end-to-end with no external launcher process on the system: theme switch, emoji, keybinds, clipboard wipe, record audio, bar orientation, Super+C clipboard history."
    - "The emoji surface never invokes wtype with a value that is not an exact glyph from the shipped data set (T-06-17)."
    - "The keybinds surface copies a chord and never executes its dispatcher (T-07-26)."
    - "System ▸ Updates reports pending package updates (R-1); System ▸ System info reports machine information (R-2); an Apps root entry opens the launcher in apps mode (R-3)."
    - "theme-doctor, theme-stress-test, colour-lint, motion-lint, keybind-doctor, quickshell-doctor, stow-link-check and retirement-check all pass with zero references to the retired launcher or its backend anywhere outside .planning/."
    - "Neither the retired launcher nor its backend is installed on the host, and neither has a package entry in install.sh."
  artifacts:
    - quickshell/.config/quickshell/modules/launcher/Launcher.qml
    - quickshell/.config/quickshell/modules/launcher/LauncherState.qml
    - quickshell/.config/quickshell/modules/launcher/MenuTree.qml
    - quickshell/.config/quickshell/modules/launcher/qmldir
    - quickshell/.config/quickshell/modules/launcher/emoji.tsv
    - quickshell/.config/quickshell/shortcuts.json          # launcher entry
    - hypr/.config/hypr/scripts/retirement-check            # two new registry rows, status=retired
  key_links:
    - "shell.qml LazyLoader -> Launcher.qml PanelWindow -> GlobalShortcut quickshell:launcher -> shortcuts.json manifest -> keybinds.lua bind. All five must agree or the surface is unreachable."
    - "modules/launcher/qmldir must declare every new type in the SAME commit that creates it, or shell.qml's import resolves to nothing with no load error (modules/qmldir's own standing rule)."
    - "Every Colours.* and Motion.* token the launcher references must EXIST in the singleton, not merely be referenced — colour-lint CHECK A covers Colours; Motion has no equivalent gate and needs the explicit comm-based check in each task."
    - "Menu leaf command strings must stay byte-identical to the TOML actions they replace, or 36 entries silently change behaviour."
    - "contract.json / reload.sh / theme-doctor / theme-stress-test / commit.sh assert on the retired surface as one interlocked set — they must be retired in ONE commit or the doctors go permanently red (the orphaned eww.scss contract entry is the standing proof)."
    - "retirement-check registry status must not flip to retired until every blocking-class hit is zero; the registry row is the machine-checkable definition of done for stage 3."
---

<objective>
Retire walker + elephant into a native Quickshell QML launcher, per the six locked
decisions D-1..D-6 in `.planning/notes/launcher-qml-migration-design.md`.

Purpose: the launcher is the last non-QML interactive surface in this desktop. Retiring
it collapses the theme pipeline's last CSS target, removes two daemons from autostart,
and lets the launcher share `Colours.qml` / `Motion.qml` with every other surface.

Output: a `modules/launcher/` QML package, 7 migrated dmenu consumers, and a complete
walker+elephant retirement verified by `retirement-check`.

**D-1..D-6 are operator-locked as of 2026-08-22. Do not re-derive, re-research or
second-guess them.** Every design question this task raises is already answered in the
spec. Read it in full before Task 1.
</objective>

<context>
@.planning/notes/launcher-qml-migration-design.md
@.claude/CLAUDE.md
@.planning/STATE.md
</context>

<measured_ground_truth>
Verified on this host 2026-08-22 during planning — not estimated, not assumed.

| Fact | Value |
|---|---|
| Files referencing the retired launcher outside `.planning/` | **59** |
| dmenu consumers | **7** (6 shell scripts + `keybinds.lua:143`; `utilities.toml` embeds the same pipeline as a menu action) |
| Menu TOMLs / entries | **6 files, 36 entries** |
| Host packages to remove | **11** — the launcher + 10 backend provider packages |
| Replacement binaries already installed | `qalc` (22 from `qalc -t "2+2*10"`), `cliphist`, `wtype`, `wl-copy`, `fd`, `jq`, `checkupdates`, `fastfetch`, `paru` |
| New packages required | **zero** — `pacman-contrib` (install.sh:161) and `fastfetch` (install.sh:128) are already listed, so R-1 and R-2 add no install step |
| `icon-theme-picker.sh` / `font-switcher.sh` | **NOT dmenu consumers** — both are fzf-in-floating-kitty (verified: their own headers say so, and neither contains a dmenu call). Do not touch them. |
| `~/.config/quickshell/modules` | a **directory symlink** into the repo, so a new `modules/launcher/` subdir goes live with no re-stow. `~/.config/quickshell/` itself is a real dir — do NOT add a new top-level entry there without a stow step. |
| `qmllint` | present at `/usr/bin/qmllint`, exits 0 on existing repo QML — usable as a static gate |
| `qs ipc show` | lists live IPC targets **without summoning any surface** — usable as a liveness gate |

**House architecture the replacement must match** (read from `shell.qml`, 1335 lines):
`WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand` + `Component.onCompleted:
content.forceActiveFocus()` + `HyprlandFocusGrab` for dismiss. `Overview.qml:54` and
`Overview.qml:1090` are the closest analog (full-screen, focusable, own key handler).
One `LazyLoader` per surface with `active: false` at rest — **not** Caelestia's shared
window (D-1 is explicit that the house Caelestia-first bias points the wrong way here).
</measured_ground_truth>

<plan_decisions>
Four decisions this plan makes that D-1..D-6 left open. Named DQ-* so they never collide
with the spec's own D-*.

### DQ-1 — Super+Escape (the D-03 escape hatch) repoints to a service restart

`keybinds.lua:95` currently force-kills the launcher process. That process is going away,
and the replacement lives *inside* the permanently-mounted shell process. Three options
were weighed against what D-03 actually guarantees:

- A process kill of the shell is **wrong**: `quickshell.service`'s own header records that
  a plain SIGTERM is in systemd's clean-exit exemption list and will **not** restart the
  unit — the bar, notifications and OSD would stay dead.
- An IPC verb (`qs ipc call launcher close`) is **insufficient**: it cannot recover a
  wedged QML event loop, which is the exact failure D-03 exists to guard against.
- `systemctl --user restart quickshell.service` is the only repoint that keeps D-03's
  process-level guarantee. Cost: the bar/notifications/OSD cycle for ~2s (RestartSec=2).

**Decision: Super+Escape becomes `systemctl --user restart quickshell.service`.** In-launcher
Escape is an ordinary QML dismiss and is a separate mechanism. `keybind-doctor` hardcodes
the old expression in its D-03 assertion (~line 494) and five test fixtures repeat it —
all updated in the same task, Task 10.

### DQ-2 — Clipboard image previews: OUT of scope

D-5's final paragraph flags these as net-new capability and this task's own constraint
states the net-new set is exactly R-1..R-3 and **nothing else**. Text-only is precisely
today's behaviour: an image entry renders as the backend's own `[[ binary data … ]]`
marker and selecting it still restores the image through `cliphist decode | wl-copy`, so
nothing is lost functionally — only a thumbnail is not drawn. **Recorded as the named
first follow-up.** Had it been included it would have been cut-candidate #2 after R-1..R-3.

### DQ-3 — Emoji data ported verbatim, no keyword widening

The 160 entries move from the shell heredoc to
`quickshell/.config/quickshell/modules/launcher/emoji.tsv`, read via `FileView` (D-5's
end-4 precedent). Format stays one glyph + one name per line. Widening the keyword set —
D-5 explicitly leaves this open — is net-new capability and is foreclosed by the same
constraint as DQ-2. The file lives under `modules/launcher/` rather than a new top-level
`data/` dir so no re-stow is needed (see ground truth). **Second named follow-up.**

### DQ-4 — Cut ladder if verification gets noisy

D-3's own instruction: R-1..R-3 are the first things to cut back to like-for-like. Cut in
this order — **R-3 (Apps root) → R-2 (System info) → R-1 (Updates)** — cheapest and most
redundant first (R-3 duplicates a bind that already exists). Already below the line and
never to be added back mid-task: image previews (DQ-2), emoji keyword widening (DQ-3).
</plan_decisions>

<standing_hazards>
Read once, apply to every task.

1. **Token discipline is not token resolution.** `colour-lint` (GATE-04) rejects hardcoded
   colours and its CHECK A resolves every `Colours.<name>` against the names parsed from
   `Colours.qml` at run time. **`Motion` has no equivalent gate.** `Motion.qml` shipped six
   undeclared spatial aliases across 74 call sites with every gate green (commit
   `69f5912f`). Every task that touches launcher QML carries an explicit `comm`-based
   Motion-token existence check in its `<verify>`. A green gate never proves a token resolves.

2. **A grep gate can match its own comment.** When stripping a token from a file, the file's
   own header prose still matches. Either strip comments before counting
   (`grep -v '^\s*#'` / `grep -v '^\s*//'`) or — better — let `retirement-check` be the
   judge, since its blocking tier deliberately counts prose comments in live code too.
   That is why Task 12 has to rewrite comments in six QML files that only *mention* the
   retired surface.

3. **Never `| grep -q` under `pipefail`.** It can exit 141 on a match and flip a gate's
   verdict by file length. Use `grep -c` into a variable and compare with `test`.

4. **Never spawn a `qml6` probe script.** Each opens a real window and a loop of them takes
   the session down. Verification here is static (`qmllint`), doctor-driven, or
   `qs ipc show` against the already-running shell. Live visual confirmation is the
   operator's pass, listed at the end of this plan — do not fabricate a render gate.

5. **Layer-rule edits need a compositor restart, not `hyprctl reload`.** Task 10 removes two
   layer rules; `hyprctl reload` drops layer rules silently and the symptom looks exactly
   like a wrong alpha value.

<!-- planner-discipline-allow: wtype -->
<!-- planner-discipline-allow: systemctl --user restart quickshell.service -->
<!-- Both literals above are checked by POSITIVE gates (grep -c ... -eq 1), not negative ones:
     Task 7 requires exactly ONE call site, Task 10 requires exactly ONE bind. Naming them in
     the action bodies is required, not a self-invalidating leak. -->

6. **`hyprctl` on this Lua-config instance takes a Lua expression**, not the classic
   `dispatcher,args` string (`keybinds.lua:44-49`'s own recorded finding, and `main.toml`'s
   Power entry is the working precedent).

7. **Every new type MUST be registered in its `qmldir` in the SAME commit that creates it.**
   `modules/qmldir`'s header states this as a repo-wide rule. An unregistered type resolves
   to `undefined` forever with **no load error**. Singletons need BOTH `pragma Singleton` in
   the source and the `singleton` keyword in `qmldir`.
</standing_hazards>

<tasks>

<!-- ═══════════════ STAGE 1 — BUILD (D-1, D-2) ═══════════════ -->

<task type="tracer">
  <name>Task 1: Launcher surface tracer — one path, Super+Space to a launched app</name>
  <files>quickshell/.config/quickshell/modules/launcher/Launcher.qml, quickshell/.config/quickshell/modules/launcher/LauncherState.qml, quickshell/.config/quickshell/modules/launcher/qmldir, quickshell/.config/quickshell/modules/qmldir, quickshell/.config/quickshell/shell.qml, quickshell/.config/quickshell/shortcuts.json, hypr/.config/hypr/config/keybinds.lua</files>
  <action>
Wire ONE path end-to-end through every layer this migration touches, so an architectural
dead-end surfaces after one commit rather than after ten.

Create `modules/launcher/` with its own `qmldir` (`module qs.modules.launcher`) declaring
both new types in this same commit. `LauncherState.qml` is a singleton (needs `pragma
Singleton` in-source AND the `singleton` keyword in qmldir) holding the current mode, the
query string and the menu navigation stack — it is the seam every later mode plugs into.

`Launcher.qml` is a dedicated `PanelWindow` per D-1 (end-4's shape, NOT Caelestia's shared
window). Copy the focus idiom verbatim from `Overview.qml:54` and `Overview.qml:1090`:
`WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand` plus `Component.onCompleted:
content.forceActiveFocus()`, and a `HyprlandFocusGrab` for click-outside dismiss. Emit
`dismissRequested` on Escape and on grab loss.

Contents for this task: a search `TextField` and ONE result view — apps, rows, backed by
Quickshell `DesktopEntries.applications.values` (already in use at `NotifCard.qml:243`).
Plain substring filter is sufficient here; fuzzy matching arrives in Task 2. Enter launches
the highlighted entry through the same execution path `DesktopEntries` exposes.

Mount it in `shell.qml` behind a `LazyLoader` with `active: false`, exactly like
`overviewLoader` (shell.qml:700) — add `import "modules/launcher"` alongside the other
module imports. Add a `GlobalShortcut { appid: "quickshell"; name: "launcher" }` toggling
that loader, and the matching `shortcuts.json` entry with a `description` naming this task.
Follow `dashboardShortcut`'s toggle-with-`fullscreenBlocking`-guard shape: an already-open
launcher always closes, a closed one only opens when not fullscreen-blocked.

Repoint `keybinds.lua:55`/`:84` only: the app-launcher constant becomes
`hl.dsp.global("quickshell:launcher")`. Leave `:58` (Super+R runner), `:86` (Super tap
menu), `:95` (escape hatch) and `:143` (Super+C) on the old surface — those are Tasks 2, 3
and 10. Both surfaces coexist for the duration of stages 1-2; that overlap is deliberate
and is what makes retirement safely last.

Read every colour from `Colours.qml` and every duration/easing from `Motion.qml`. Do not
write a literal hex or a literal duration anywhere.
  </action>
  <verify>
    <automated>cd /home/aorus/dotfiles &amp;&amp; qmllint quickshell/.config/quickshell/modules/launcher/Launcher.qml quickshell/.config/quickshell/modules/launcher/LauncherState.qml &amp;&amp; ./hypr/.config/hypr/scripts/colour-lint quickshell/.config/quickshell/modules/launcher &amp;&amp; ./hypr/.config/hypr/scripts/motion-lint quickshell/.config/quickshell/modules/launcher &amp;&amp; test -z "$(comm -23 <(grep -rhoE 'Motion\.[a-zA-Z_][a-zA-Z0-9_]*' quickshell/.config/quickshell/modules/launcher/ | sed 's/^Motion\.//' | sort -u) <(grep -oE 'readonly property (alias|int|real|var|bool|string) [a-zA-Z_][a-zA-Z0-9_]*' quickshell/.config/quickshell/modules/Motion.qml | awk '{print $NF}' | sort -u))" &amp;&amp; test "$(grep -c 'launcher' quickshell/.config/quickshell/modules/launcher/qmldir)" -ge 2 &amp;&amp; test "$(python3 -c 'import json,sys; print(sum(1 for e in json.load(open("quickshell/.config/quickshell/shortcuts.json")) if e["name"]=="launcher"))')" -eq 1</automated>
  </verify>
  <done>`modules/launcher/` exists with a qmldir declaring both types; Super+Space opens a QML panel that lists and launches applications and dismisses on Escape; `qmllint`, `colour-lint` and `motion-lint` all pass on the new package; every `Motion.*` name the package uses is declared in `Motion.qml`; the shortcut is present in both `shell.qml` and `shortcuts.json`.</done>
</task>

<task type="auto">
  <name>Task 2: Search core — fuzzy matcher, prefix router, per-mode result views</name>
  <files>quickshell/.config/quickshell/modules/launcher/fuzzy.js, quickshell/.config/quickshell/modules/launcher/LauncherState.qml, quickshell/.config/quickshell/modules/launcher/Launcher.qml, quickshell/.config/quickshell/modules/launcher/CalcMode.qml, quickshell/.config/quickshell/modules/launcher/WebSearchMode.qml, quickshell/.config/quickshell/modules/launcher/FilesMode.qml, quickshell/.config/quickshell/modules/launcher/qmldir, hypr/.config/hypr/config/keybinds.lua</files>
  <action>
Build the mechanism D-1 Option B names: one frame, shared search field and chrome, results
area swaps component per content type.

Vendor a fuzzy matcher as `fuzzy.js` (both reference shells vendor one — Caelestia
`fzf.js`/`fuzzysort.js` in `utils/Searcher.qml`, end-4 `Fuzzy.go()` with a Levenshtein
fallback). Keep it a plain JS import, no new package. Replace Task 1's substring filter with
it in the apps mode.

Add the prefix router to `LauncherState.qml`, restoring all six routes the retired config
declared: `=` calc, `/` files, `:` clipboard, `.` symbols, `;` providerlist, `@` websearch.
The router sets a mode enum; `Launcher.qml`'s results area is a `Loader` whose
`sourceComponent` switches on that enum. Clipboard and symbols route to placeholder modes
that Tasks 7 and 8 fill — declare the enum values now so the router is complete and the
later tasks are pure additions.

Three modes ship in this task, chosen because they are the thinnest proof that the swap
works across genuinely different result shapes:
- `CalcMode.qml` — single-result view, spawns `qalc -t <expr>` via a `Process` (verified:
  `qalc -t "2+2*10"` returns `22`, libqalculate already installed, no new package). Enter
  copies the result to the clipboard.
- `WebSearchMode.qml` — single-result view, opens the query in the default browser.
- `FilesMode.qml` — rows, enumerates via `fd` (installed at `/usr/bin/fd`), scoped to
  `$HOME`, bounded depth, results capped at 50 to match the retired config's `max_results`.
  Enter opens with `xdg-open`.

Also add the `;` providerlist mode: a rows view listing the available modes and their
prefixes, which is what that route did before. This is like-for-like, not net-new.

Repoint `keybinds.lua:58` (Super+R) to open the launcher directly in apps mode — the
retired runner provider and the apps provider collapse into one mode here, which is the
whole point of D-1's single frame. Add an `IpcHandler { target: "launcher" }` exposing
`open(mode: string)` and `toggle()` so later tasks and menu leaves can summon a specific
mode; follow `panelIpc`'s shape (shell.qml:1147) — functions only, no direct `active` writes
from inside the handler beyond the existing summon function.

Do not put a fenced code block or an implementation in a comment. Read all colours from
`Colours.qml` and all motion from `Motion.qml`.
  </action>
  <verify>
    <automated>cd /home/aorus/dotfiles &amp;&amp; qmllint quickshell/.config/quickshell/modules/launcher/*.qml &amp;&amp; ./hypr/.config/hypr/scripts/colour-lint quickshell/.config/quickshell/modules/launcher &amp;&amp; ./hypr/.config/hypr/scripts/motion-lint quickshell/.config/quickshell/modules/launcher &amp;&amp; test -z "$(comm -23 <(grep -rhoE 'Motion\.[a-zA-Z_][a-zA-Z0-9_]*' quickshell/.config/quickshell/modules/launcher/ | sed 's/^Motion\.//' | sort -u) <(grep -oE 'readonly property (alias|int|real|var|bool|string) [a-zA-Z_][a-zA-Z0-9_]*' quickshell/.config/quickshell/modules/Motion.qml | awk '{print $NF}' | sort -u))" &amp;&amp; test "$(qalc -t '2+2*10')" = "22" &amp;&amp; systemctl --user restart quickshell.service &amp;&amp; sleep 4 &amp;&amp; test "$(qs ipc show | grep -c '^target launcher$')" -eq 1</automated>
  </verify>
  <done>All six prefix routes resolve to a mode; the results area swaps component per mode; calc returns a real `qalc` result; `qs ipc show` lists a `launcher` target on the live shell; every gate above passes.</done>
</task>

<task type="auto">
  <name>Task 3: Menu tree — 9 verb-based roots, all 36 entries re-homed</name>
  <files>quickshell/.config/quickshell/modules/launcher/MenuTree.qml, quickshell/.config/quickshell/modules/launcher/MenuMode.qml, quickshell/.config/quickshell/modules/launcher/LauncherState.qml, quickshell/.config/quickshell/modules/launcher/qmldir, hypr/.config/hypr/config/keybinds.lua</files>
  <action>
Replace the 6-TOML / 36-entry backend menu tree with a QML data model, restructured to
D-2's nine verb-based roots. **All 36 existing entries are re-homed; none is dropped.**

`MenuTree.qml` is a singleton holding the tree as data: each node is either a submenu
(children) or a leaf (a command string, plus an optional `preselect` provider). Roots and
membership come from D-2's table verbatim — Apps, Capture, Tools, Style, Setup, Play, AI,
Learn, System. The Apps root and System's Updates / System info are R-3 / R-1 / R-2 and are
Task 4; declare their nodes here as placeholders that Task 4 fills.

**Every leaf command string must be byte-identical to the TOML action it replaces.** Read
the six files under `elephant/.config/elephant/menus/` and copy each `actions.open` value
exactly — including the Power entry's `hyprctl dispatch` Lua-expression form (that shape is
required on this Lua-config instance, see standing hazard 6) and the Settings entry's bare
`qs ipc call settings open`. The one exception is Tools ▸ Clipboard, whose TOML action
embeds the old dmenu pipeline verbatim — that leaf routes to the in-launcher clipboard mode
instead, and Task 8 wires it. Any leaf whose command changes is a behaviour regression, not
a migration.

Measured: there are exactly **30** `actions.open` leaf commands across the six files
(36 entries minus five submenu entries minus the clipboard one). The verify below parses the
TOMLs with `tomllib` and names every one that is missing from `MenuTree.qml`, so a partial
port cannot pass. Three of those 30 are legitimately superseded **later** — the theme and bar
orientation leaves in Task 5, emoji in Task 7, keybinds in Task 9 — but at *this* task they
must still be present verbatim, so the migration stays reversible one task at a time.

`MenuMode.qml` is the rows view with drill-in, back navigation to the parent node, and
Escape closing the whole surface from any depth. Take D-2's three adopted Omarchy affordances
and nothing else: per-menu placeholder text, Nerd Font glyphs already baked into the entry
strings, and **preselect-the-current-value** — a leaf may declare a provider that returns the
value currently in effect (current theme, current bar orientation) and the list opens with
that row highlighted. Do not adopt the bash architecture; typed input is preserved across
levels by construction here because there is no per-level process spawn.

Repoint `keybinds.lua:86` (the Super-tap release bind) to
`hl.dsp.global("quickshell:launcher")` with the menu mode requested. **Phase 7's
launcher/menu split is preserved** (D-1, `07-DISCUSSION-LOG.md:20-21`): Super+Space is the
launcher, a bare Super tap is the menu, and this rebuild does not collapse them into one
entry point.

Leave `elephant/.config/elephant/menus/` on disk untouched for now — deleting it is Task 12,
so the old surface stays functional until retirement.
  </action>
  <verify>
    <automated>cd /home/aorus/dotfiles &amp;&amp; qmllint quickshell/.config/quickshell/modules/launcher/*.qml &amp;&amp; ./hypr/.config/hypr/scripts/colour-lint quickshell/.config/quickshell/modules/launcher &amp;&amp; ./hypr/.config/hypr/scripts/motion-lint quickshell/.config/quickshell/modules/launcher &amp;&amp; test -z "$(comm -23 <(grep -rhoE 'Motion\.[a-zA-Z_][a-zA-Z0-9_]*' quickshell/.config/quickshell/modules/launcher/ | sed 's/^Motion\.//' | sort -u) <(grep -oE 'readonly property (alias|int|real|var|bool|string) [a-zA-Z_][a-zA-Z0-9_]*' quickshell/.config/quickshell/modules/Motion.qml | awk '{print $NF}' | sort -u))" &amp;&amp; python3 -c "import tomllib,glob,sys; src=open('quickshell/.config/quickshell/modules/launcher/MenuTree.qml').read(); missing=[a for f in sorted(glob.glob('elephant/.config/elephant/menus/*.toml')) for e in tomllib.load(open(f,'rb')).get('entries',[]) if (a:=(e.get('actions') or {}).get('open')) and 'cliphist list' not in a and a not in src]; print('MISSING LEAF COMMANDS:', missing); sys.exit(1 if missing else 0)"</automated>
  </verify>
  <done>MenuTree.qml declares the nine D-2 roots; every non-clipboard `actions.open` string from all six TOMLs appears byte-identically in MenuTree.qml (the loop above proves it entry by entry and names any miss); a Super tap opens the menu mode at the root; drill-in, back and preselect all work; Super+Space still opens the launcher separately.</done>
</task>

<task type="auto">
  <name>Task 4: R-1 System ▸ Updates, R-2 System ▸ System info, R-3 Apps root</name>
  <files>quickshell/.config/quickshell/modules/launcher/MenuTree.qml, quickshell/.config/quickshell/modules/launcher/SystemInfoMode.qml, quickshell/.config/quickshell/modules/launcher/UpdatesMode.qml, quickshell/.config/quickshell/modules/launcher/qmldir</files>
  <action>
The three net-new requirements minted in D-3. **These are the only net-new capability in this
whole task** — nothing else may be added. Per DQ-4 they are also the first things to cut if
verification gets noisy, in the order R-3 → R-2 → R-1.

**R-3 — Apps root.** A single leaf under the Apps root that switches the surface into the
apps mode Task 1 built. No new machinery: it calls the same mode-set the `IpcHandler` and
Super+Space already use. This is the cheapest of the three and therefore the first cut.

**R-2 — System ▸ System info.** `SystemInfoMode.qml` — a read-only rows view of machine
information. Source it from `fastfetch`, which is installed and already listed in
`install.sh:128`, using its JSON output so the view parses structured fields rather than
scraping a rendered box. No new package.

**R-1 — System ▸ Updates.** `UpdatesMode.qml` — a rows view of pending package updates.
Repo updates come from `checkupdates` (`pacman-contrib`, installed and already listed at
`install.sh:161`); AUR updates come from `paru -Qua` (the helper `install.sh` bootstraps at
line 520-534). Both are read-only queries — this surface **reports**, it does not install.
Handle the documented empty-result exit codes rather than treating them as failure, the same
defensive shape `clipboard-wipe.sh` already uses for an empty clipboard database.

No new package enters `install.sh` from this task. If one seems necessary, that is the
signal to cut per DQ-4 rather than to widen the install list.
  </action>
  <verify>
    <automated>cd /home/aorus/dotfiles &amp;&amp; qmllint quickshell/.config/quickshell/modules/launcher/*.qml &amp;&amp; ./hypr/.config/hypr/scripts/colour-lint quickshell/.config/quickshell/modules/launcher &amp;&amp; ./hypr/.config/hypr/scripts/motion-lint quickshell/.config/quickshell/modules/launcher &amp;&amp; command -v checkupdates &amp;&amp; command -v fastfetch &amp;&amp; command -v paru &amp;&amp; fastfetch --format json >/dev/null &amp;&amp; test "$(git diff --stat -- install.sh | wc -l)" -eq 0 &amp;&amp; echo "R-1/R-2/R-3 deps present, install.sh untouched"</automated>
  </verify>
  <done>Apps, System ▸ Updates and System ▸ System info are all reachable from the menu tree; updates lists repo and AUR pending updates without installing anything; system info renders parsed fields; `install.sh` is unmodified by this task.</done>
</task>

<!-- ═══════════════ STAGE 2 — MIGRATE the 7 dmenu consumers ═══════════════ -->

<task type="auto">
  <name>Task 5: Generic picker mode; migrate theme switch and bar orientation</name>
  <files>quickshell/.config/quickshell/modules/launcher/PickerMode.qml, quickshell/.config/quickshell/modules/launcher/MenuTree.qml, quickshell/.config/quickshell/modules/launcher/qmldir, hypr/.config/hypr/scripts/bar-orientation.sh</files>
  <action>
The design note's own headline carried risk: the dmenu contract is the real work, not the
launcher. Consumers 1 and 6 of 7.

**The migration is an inversion of control.** The retired pattern was: script builds a list,
blocks on an external picker, reads the pick off stdout, acts. A QML surface cannot return
stdout to a blocked shell — and must not try. Instead the launcher owns the list and the
selection, and on pick it invokes the consumer **non-interactively with an argument**. Every
consumer in Tasks 5, 6 and 9 follows this one shape.

`PickerMode.qml` is the reusable half: a rows view over parallel display/value arrays, an
optional preselect index, a placeholder string, and a command template run on Enter. Escape
dismisses with no action — that is the whole of the old exit-130 cancel contract, which
disappears as a concept because there is no second process to signal.

**Style ▸ Theme** (consumer 1). The retired `theme-switch.sh` was a thin picker only: it
listed `theme-engine/palettes/*.json` basenames prettified, plus the two Material You
literals, then `exec`'d `theme-apply <name>`. Rebuild exactly that in the picker's data
provider and run `~/.config/theme-engine/theme-apply <name>` on pick. Keep the parallel
index-matched display/value arrays — never reverse-transform a prettified label back to a
name (T-05-06's own rule); `theme-apply` re-validates the name against `palettes/*.json`
regardless, so defence in depth is preserved. Preselect the current theme by reading
`~/.local/state/theme/current-theme` — **that path and not the cache one**, which is a
plausible-looking orphan. The script becomes fully dead and is deleted in Task 12, together
with `tests/test-walker-dmenu-cancel.sh`, which drives it and nothing else.

**Style ▸ Bar orientation** (consumer 6). `bar-orientation.sh` already has the argument path
this needs: an apply function taking one slug, with a closed enumeration and an atomic state
write. **Delete the interactive picker function entirely** — the one whose name the verify
below negative-greps for — and make the no-argument case a usage error, so the only entry
shape left is the non-interactive one. Do not leave a tombstone comment naming that function:
the gate strips shell comments before counting precisely because a header line describing the
removal would otherwise fail the gate against clean code. The picker's data provider carries the same two display labels
and slugs the script's arrays hold, preselected from the same state file the script writes.
On pick it runs `~/.config/hypr/scripts/bar-orientation.sh <slug>`.
  </action>
  <verify>
    <automated>cd /home/aorus/dotfiles &amp;&amp; qmllint quickshell/.config/quickshell/modules/launcher/*.qml &amp;&amp; ./hypr/.config/hypr/scripts/colour-lint quickshell/.config/quickshell/modules/launcher &amp;&amp; ./hypr/.config/hypr/scripts/motion-lint quickshell/.config/quickshell/modules/launcher &amp;&amp; bash -n hypr/.config/hypr/scripts/bar-orientation.sh &amp;&amp; shellcheck -S error hypr/.config/hypr/scripts/bar-orientation.sh &amp;&amp; test "$(grep -v '^\s*#' hypr/.config/hypr/scripts/bar-orientation.sh | grep -c '_pick')" -eq 0 &amp;&amp; ! hypr/.config/hypr/scripts/bar-orientation.sh >/dev/null 2>&amp;1 &amp;&amp; hypr/.config/hypr/scripts/bar-orientation.sh horizontal &amp;&amp; test "$(cat ~/.local/state/hypr/bar-orientation 2>/dev/null || echo horizontal)" = "horizontal"</automated>
  </verify>
  <done>A generic picker mode exists and is reused by both consumers; theme selection applies through `theme-apply` with the current theme preselected; `bar-orientation.sh` has no interactive path left, errors on no argument, and still applies correctly when given one.</done>
</task>

<task type="auto">
  <name>Task 6: Destructive confirm + choice pickers; migrate clipboard wipe and record audio</name>
  <files>quickshell/.config/quickshell/modules/launcher/ConfirmMode.qml, quickshell/.config/quickshell/modules/launcher/MenuTree.qml, quickshell/.config/quickshell/modules/launcher/qmldir, hypr/.config/hypr/scripts/clipboard-wipe.sh, hypr/.config/hypr/scripts/record-toggle.sh</files>
  <action>
Consumers 4 and 5 of 7. Both need a script-side argument path that does not exist yet.

`ConfirmMode.qml` is the destructive-confirm shape: a two-row picker whose **non-destructive
option is first and preselected**, per the UI-SPEC copywriting contract `clipboard-wipe.sh`
already honours in its own comment. Never open with the destructive row under the cursor.

**Tools ▸ Clipboard wipe** (consumer 4). Add a `--yes` argument to `clipboard-wipe.sh` that
skips the confirm and goes straight to the wipe; with no argument the script must now exit
non-zero with a usage message rather than prompt, since there is no picker left inside it.
Keep everything else in that script unchanged — the entry count read, the empty-database exit
handling, the wipe itself and the notification are real logic, not picker scaffolding. The
QML side shows the count in the confirm prompt exactly as the old placeholder did, reading it
from the same list verb D-5 records.

**Capture ▸ Record toggle audio** (consumer 5). `record-toggle.sh`'s `pick_audio()` sits
*mid-flow*, which is the one place the inversion is not free. It already has the seam:
`record-defaults.json` carries an `audio` key whose non-`ask` values bypass the prompt
entirely, and `cmd_set_default` already enforces the closed enumeration
silent / desktop / desktop+mic / ask. Add an `--audio <mode>` argument to `main()`, validated
against that same closed enumeration, which pre-seeds `AUDIO_DEVICES` and skips
`pick_audio()`. Then: when `audio` is `ask` and no `--audio` was passed, the script summons
the launcher's audio picker and exits; the picker re-invokes
`record-toggle.sh --audio <mode>`. The three display labels and their device-string mappings
move to the picker's parallel arrays unchanged. Delete `pick_audio()`'s picker branch — the
non-`ask` fast path stays exactly as it is.

Neither script may keep a code path that blocks on an interactive picker. That is the
property Task 12's retirement depends on.
  </action>
  <verify>
    <automated>cd /home/aorus/dotfiles &amp;&amp; qmllint quickshell/.config/quickshell/modules/launcher/*.qml &amp;&amp; ./hypr/.config/hypr/scripts/colour-lint quickshell/.config/quickshell/modules/launcher &amp;&amp; ./hypr/.config/hypr/scripts/motion-lint quickshell/.config/quickshell/modules/launcher &amp;&amp; bash -n hypr/.config/hypr/scripts/clipboard-wipe.sh &amp;&amp; bash -n hypr/.config/hypr/scripts/record-toggle.sh &amp;&amp; shellcheck -S error hypr/.config/hypr/scripts/clipboard-wipe.sh hypr/.config/hypr/scripts/record-toggle.sh &amp;&amp; ! hypr/.config/hypr/scripts/clipboard-wipe.sh >/dev/null 2>&amp;1 &amp;&amp; ! hypr/.config/hypr/scripts/record-toggle.sh --audio bogus >/dev/null 2>&amp;1 &amp;&amp; test "$(hypr/.config/hypr/scripts/record-toggle.sh get-defaults | jq -r '.audio')" != "null"</automated>
  </verify>
  <done>A confirm mode exists with the safe option preselected; `clipboard-wipe.sh --yes` wipes and bare invocation is a usage error; `record-toggle.sh --audio` accepts only the three enumerated modes and rejects anything else; neither script contains a blocking interactive picker.</done>
</task>

<task type="auto">
  <name>Task 7: Emoji grid surface with the T-06-17 validation gate</name>
  <files>quickshell/.config/quickshell/modules/launcher/EmojiMode.qml, quickshell/.config/quickshell/modules/launcher/emoji.tsv, quickshell/.config/quickshell/modules/launcher/qmldir, quickshell/.config/quickshell/modules/launcher/MenuTree.qml</files>
  <action>
Consumer 2 of 7, and the one carrying a hard security requirement.

Port the 160 entries currently held inline in the retired picker script (lines 46-205, a
`$'...'` heredoc using literal backslash-t that bash expands at runtime — grepping for a real
tab byte returns 0 and is blind, so extract by expanding the string, not by grepping the
source). Write them to `modules/launcher/emoji.tsv`, one glyph plus one name per line
separated by a real tab. **160 entries, single-name format, no keyword widening** — DQ-3.
The file lives inside `modules/launcher/` so no re-stow is needed (see ground truth).
Load it with a `FileView`, which is D-5's admitted end-4 precedent for exactly this.

D-5 measured that no system emoji source exists on this host and no package owns one, so
shipping the data in-repo is the only option that does not touch `install.sh` and
fresh-install reproducibility. Do not add a package.

`EmojiMode.qml` renders a **grid**. Per D-1's own attribution correction this is a local
design judgment taken deliberately against the only available precedent (end-4 uses a plain
list; Caelestia has no emoji surface at all) — 16 visible versus 4. Do not cite a reference
shell for it in a comment.

**T-06-17 is a hard requirement, not a nicety (D-6).** The surface must validate the selected
glyph against the parsed known set before invoking `wtype`, and must never type back raw list
output or free-typed search text. Concretely: the typed value comes from the parsed model
row, and an explicit containment assertion against the loaded set gates the `wtype`
invocation — if the assertion fails the surface types nothing and does nothing. There must be
exactly one `wtype` call site in the file and it must sit inside that guarded branch. After
typing, copy to the clipboard with `wl-copy` and notify, matching the retired behaviour.
Preserve the graceful degradation the old script had when `wtype` is absent: copy-only rather
than silent nothing.

Route Tools ▸ Emoji and the `.` symbols prefix to this mode. The retired picker script is
deleted in Task 12.
  </action>
  <verify>
    <automated>cd /home/aorus/dotfiles &amp;&amp; qmllint quickshell/.config/quickshell/modules/launcher/*.qml &amp;&amp; ./hypr/.config/hypr/scripts/colour-lint quickshell/.config/quickshell/modules/launcher &amp;&amp; ./hypr/.config/hypr/scripts/motion-lint quickshell/.config/quickshell/modules/launcher &amp;&amp; test "$(wc -l < quickshell/.config/quickshell/modules/launcher/emoji.tsv)" -eq 160 &amp;&amp; test "$(awk -F'\t' 'NF!=2 || $1=="" || $2==""' quickshell/.config/quickshell/modules/launcher/emoji.tsv | wc -l)" -eq 0 &amp;&amp; test "$(grep -v '^\s*//' quickshell/.config/quickshell/modules/launcher/EmojiMode.qml | grep -c 'wtype')" -eq 1 &amp;&amp; test "$(grep -v '^\s*//' quickshell/.config/quickshell/modules/launcher/EmojiMode.qml | grep -c 'validatedGlyph')" -ge 2</automated>
  </verify>
  <done>`emoji.tsv` holds exactly 160 well-formed glyph-tab-name lines; the grid renders from it; exactly one non-comment `wtype` call site exists and it is reachable only through the validation guard (the negative grep strips `//` comment lines so the gate cannot match its own prose); free-typed search text can never reach `wtype`.</done>
</task>

<task type="auto">
  <name>Task 8: Clipboard surface, text-only; migrate Super+C</name>
  <files>quickshell/.config/quickshell/modules/launcher/ClipboardMode.qml, quickshell/.config/quickshell/modules/launcher/qmldir, quickshell/.config/quickshell/modules/launcher/MenuTree.qml, hypr/.config/hypr/config/keybinds.lua</files>
  <action>
Consumer 7 of 7 — the `keybinds.lua:143` pipeline, plus the identical pipeline embedded as
the Tools ▸ Clipboard menu action.

**Read D-5 for the exact four-verb `cliphist` contract** — it is admitted against primary
source and records the list, decode-into-`wl-copy` restore, single-entry delete and wipe-all
invocations verbatim. Use them exactly as written there; do not re-derive them. `cliphist` is
installed and already wired — no new package.

`ClipboardMode.qml` is a rows view over the list verb. Enter restores the highlighted entry.
Add per-entry delete (the delete verb) since the contract is already known and it is the
natural affordance of an owned list — this is like-for-like list management, not new
capability. Wipe-all routes to the Task 6 confirm mode rather than duplicating a destructive
prompt here.

**Text-only. Image previews are OUT — DQ-2.** An image entry renders as the backend's own
placeholder marker string exactly as it does today, and selecting it still restores the image
because the decode verb handles it. **Do not add the thumbnail decode path, the temp-file
lifecycle, or D-5's marker-detection regex** — the verify below negative-greps for that
regex's distinguishing literal, so even a comment describing the deferred feature will fail
the gate. Record the deferral in the summary, not in the source. This is the named first
follow-up, not this task's work.

Repoint `keybinds.lua:143` (Super+C) from the shell pipeline to
`hl.dsp.global("quickshell:launcher")` opening in clipboard mode — or the launcher IPC verb
if a mode argument is needed; either is fine as long as `keybind-doctor` still parses the
line. Note that `keybind-doctor` has a special case (~line 95) for bind text containing an
embedded double-dash precisely because of this pipeline; once the pipeline is gone that case
may become dead, but do **not** remove it in this task — Task 10 owns `keybind-doctor`.

Route the `:` clipboard prefix and the Tools ▸ Clipboard leaf here, replacing the placeholder
Task 3 left.
  </action>
  <verify>
    <automated>cd /home/aorus/dotfiles &amp;&amp; qmllint quickshell/.config/quickshell/modules/launcher/*.qml &amp;&amp; ./hypr/.config/hypr/scripts/colour-lint quickshell/.config/quickshell/modules/launcher &amp;&amp; ./hypr/.config/hypr/scripts/motion-lint quickshell/.config/quickshell/modules/launcher &amp;&amp; test "$(grep -v '^\s*//' quickshell/.config/quickshell/modules/launcher/ClipboardMode.qml | grep -ci 'binary data')" -eq 0 &amp;&amp; test "$(grep -v '^\s*--' hypr/.config/hypr/config/keybinds.lua | grep -c 'cliphist list')" -eq 0 &amp;&amp; ./hypr/.config/hypr/scripts/keybind-doctor >/dev/null</automated>
  </verify>
  <done>The clipboard mode lists, restores, deletes one and routes wipe to the confirm mode; no image-preview code path exists (DQ-2, proven by the negative grep on non-comment lines); Super+C no longer runs a shell pipeline; `keybind-doctor` passes.</done>
</task>

<task type="auto">
  <name>Task 9: Keybinds table surface + parser CLI</name>
  <files>quickshell/.config/quickshell/modules/launcher/KeybindsMode.qml, quickshell/.config/quickshell/modules/launcher/qmldir, quickshell/.config/quickshell/modules/launcher/MenuTree.qml, hypr/.config/hypr/scripts/cheat-sheet-parser.sh</files>
  <action>
Consumer 3 of 7, and D-1's table result view.

`cheat-sheet-parser.sh` currently only *defines* `cheat_sheet_parse_binds()` for sourcing —
there is no way to invoke it as a command. Add a guarded direct-execution path so
`cheat-sheet-parser.sh --dump` emits the same tab-separated section/chord/description stream
when the file is executed, while sourcing behaves exactly as it does now. D-29's "one parser,
two surfaces" becomes one parser, three consumers; there must still be no second grep/awk
extraction anywhere.

`KeybindsMode.qml` is the table result view: columns for chord and description, fuzzy-filtered
by the shared search field, live-parsed on every open and never cached (D-31). Pin the
"View all keybinds ›" row first so it is under the cursor when the list opens and still
reachable by typing, exactly as the retired surface did; selecting it opens
`cheat-sheet-view-all.sh` (unchanged, it is not a dmenu consumer).

**T-07-26 is a hard requirement: this is a reference, not a launcher.** Selecting an ordinary
keybind row must copy the chord to the clipboard and must never execute that bind's
dispatcher. The row model must not even carry an executable command field for ordinary rows —
make it structurally impossible rather than merely avoided. The pinned view-all row is the
single exception and is dispatched by identity, not by reading a command out of the model.

Route the Learn ▸ Keybinds leaf here. The retired `cheat-sheet.sh` becomes fully dead and is
deleted in Task 12.
  </action>
  <verify>
    <automated>cd /home/aorus/dotfiles &amp;&amp; qmllint quickshell/.config/quickshell/modules/launcher/*.qml &amp;&amp; ./hypr/.config/hypr/scripts/colour-lint quickshell/.config/quickshell/modules/launcher &amp;&amp; ./hypr/.config/hypr/scripts/motion-lint quickshell/.config/quickshell/modules/launcher &amp;&amp; bash -n hypr/.config/hypr/scripts/cheat-sheet-parser.sh &amp;&amp; shellcheck -S error hypr/.config/hypr/scripts/cheat-sheet-parser.sh &amp;&amp; test "$(hypr/.config/hypr/scripts/cheat-sheet-parser.sh --dump | wc -l)" -gt 10 &amp;&amp; test "$(hypr/.config/hypr/scripts/cheat-sheet-parser.sh --dump | awk -F'\t' 'NF!=3' | wc -l)" -eq 0 &amp;&amp; bash -c 'source hypr/.config/hypr/scripts/cheat-sheet-parser.sh; cheat_sheet_parse_binds | wc -l' &amp;&amp; test "$(grep -v '^\s*//' quickshell/.config/quickshell/modules/launcher/KeybindsMode.qml | grep -cE 'exec_cmd|Hyprland\.dispatch')" -eq 0</automated>
  </verify>
  <done>`cheat-sheet-parser.sh --dump` emits well-formed 3-field TSV and sourcing still works unchanged; the table renders and fuzzy-filters; the view-all row is pinned first; no dispatch or exec call exists anywhere in the mode's non-comment source (T-07-26 proven structurally).</done>
</task>

<!-- ═══════════════ STAGE 3 — RETIRE (strictly last) ═══════════════ -->

<task type="auto">
  <name>Task 10: Register the retirement; strip the compositor surface</name>
  <files>hypr/.config/hypr/scripts/retirement-check, hypr/.config/hypr/config/keybinds.lua, hypr/.config/hypr/config/autostart.lua, hypr/.config/hypr/config/windowrules.lua, hypr/.config/hypr/config/env.lua, hypr/.config/hypr/scripts/keybind-doctor, hypr/.config/hypr/scripts/tests/quickshell-fixtures/compliant-keybinds.lua, hypr/.config/hypr/scripts/tests/quickshell-fixtures/compliant-overview-keybinds.lua, hypr/.config/hypr/scripts/tests/quickshell-fixtures/poisoned-collision-keybinds.lua, hypr/.config/hypr/scripts/tests/quickshell-fixtures/poisoned-collision-overview-keybinds.lua, hypr/.config/hypr/scripts/tests/quickshell-fixtures/compliant-quickshell-windowrules.lua</files>
  <action>
Retirement starts here and must not have started earlier. The design note names the reason:
a half-retirement red-lights `theme-doctor`, `contract.json`, `reload.sh`, `commit.sh` and
`theme-stress-test` simultaneously, and the orphaned `eww.scss` contract entry is standing
proof that a partial one leaves a permanent red.

**Register both surfaces first.** Add two rows to `retirement-check`'s `REGISTRY_RAW` with
status `pending`, own-tree set to each package's own directory (plus the backend's restart
script), and requirement `260822-sht` — the tmux row is the precedent for a quick-task
requirement id. `pending` is the correct status while blocking-class hits remain; Task 12
flips both to `retired`. From this point `retirement-check` is the machine-checkable
definition of done, and its per-class report is the executor's worklist.

**keybinds.lua** — retire all five remaining sites. The launcher constant, the runner bind
and the Super-tap menu bind were already repointed in Tasks 1-3; Super+C in Task 8. That
leaves the Super+Escape escape hatch, which becomes
`systemctl --user restart quickshell.service` per **DQ-1** — read that decision in full
before writing the line, including why an IPC verb and a process kill are both wrong.
Update the bind's trailing comment to describe what it now does.

**autostart.lua:163-164** — delete both process launches. Nothing replaces them; the
launcher is in-process and summoned.

**windowrules.lua:248 and :375** — delete both layer rules for the retired namespace. Check
whether the new launcher's own layer surface needs equivalents (blur, and an `ignore_alpha`
threshold); if it does, add them under the launcher's own namespace, remembering that
per-surface layer rules must come **after** the family regex and that a QML alpha under
`ignore_alpha` silently kills blur. Line 389's comment references the old rule's threshold —
rewrite it to reference whatever the new rule uses.

**env.lua:15** — a prose comment naming the retired client in a list; rewrite the list.

**keybind-doctor** — three things. The static guard at ~line 301 for the retired binary's
broken set flag is dead and comes out. The D-03 kill-bind assertion at ~line 494 hardcodes
the old expression string and must assert DQ-1's new one instead. The embedded double-dash
special case at ~line 95 exists for bind text that no longer exists; remove it only if
nothing else in `keybinds.lua` still needs it — grep before deleting, do not assume.

**Five test fixtures** repeat the old kill-bind line, and one repeats a layer rule. Update all
five to match the new source. `keybind-doctor` compares source Lua to live `hyprctl binds`,
so the fixtures must stay in lockstep or its self-test fails.

**Do not `hyprctl reload` to pick these up.** Layer-rule edits are dropped silently by reload
(standing hazard 5); restart the compositor session or use `hyprctl eval`, and say which you
did in the summary.
  </action>
  <verify>
    <automated>cd /home/aorus/dotfiles &amp;&amp; test "$(./hypr/.config/hypr/scripts/retirement-check --list | grep -c 'status=pending')" -eq 2 &amp;&amp; ./hypr/.config/hypr/scripts/retirement-check --self-test &amp;&amp; ./hypr/.config/hypr/scripts/hypr-lua-harness hypr/.config/hypr/config/keybinds.lua >/dev/null &amp;&amp; ./hypr/.config/hypr/scripts/keybind-doctor &amp;&amp; test "$(grep -ci 'walker\|elephant' hypr/.config/hypr/config/keybinds.lua hypr/.config/hypr/config/autostart.lua hypr/.config/hypr/config/windowrules.lua hypr/.config/hypr/config/env.lua | awk -F: '{s+=$2} END {print s}')" -eq 0 &amp;&amp; test "$(grep -c 'systemctl --user restart quickshell.service' hypr/.config/hypr/config/keybinds.lua)" -eq 1</automated>
  </verify>
  <done>Both surfaces are registered in `retirement-check` as `pending` under requirement `260822-sht` and `--self-test` still passes; all four Hyprland config files have zero references including comments; Super+Escape restarts the shell service per DQ-1; `keybind-doctor` passes against the updated fixtures; the compositor picked up the layer-rule change by restart or eval, not by reload.</done>
</task>

<task type="auto">
  <name>Task 11: Theme-pipeline retirement — one commit, all five assertion sites</name>
  <files>theme-engine/.config/theme-engine/contract.json, theme-engine/.config/theme-engine/lib/reload.sh, theme-engine/.config/theme-engine/lib/commit.sh, theme-engine/.config/theme-engine/lib/contract.sh, theme-engine/.config/theme-engine/lib/gtk.sh, theme-engine/.config/theme-engine/theme-apply, theme-engine/.config/theme-engine/theme-doctor, theme-engine/.config/theme-engine/theme-stress-test, matugen/.config/matugen/config.toml, matugen/.config/matugen/templates/walker-style.css, matugen/.config/matugen/templates/zellij-config.kdl, hypr/.config/hypr/scripts/motion-lint, verify/theme-doctor-session-allowlist.txt, verify/container-run.sh, .gitignore</files>
  <action>
**This entire task is ONE commit.** These files assert on each other: `contract.json` declares
a rendered file, `commit.sh` symlinks it, `reload.sh` restarts a process to consume it,
`theme-doctor` checks that symlink and that process, `theme-stress-test` asserts the same
across a switch loop. Splitting them leaves the doctors permanently red — the exact failure
class the orphaned `eww.scss` contract entry still demonstrates. Measured counts to work
through: 53 hits in `reload.sh`, 40 in `theme-stress-test`, 38 in `theme-doctor`, 12 in
`commit.sh`, 2 in `contract.json`.

**contract.json** — remove the rendered-file entry (the CSS one at ~line 16) and the
engine-owned relaunch-log entry (~line 110). Both, or the contract goes inconsistent.

**matugen config.toml** — remove the template block at lines 58-61, and delete the template
source file it points at.

**commit.sh** — remove the direct-wiring symlink block (~lines 150-156) and the relaunch-log
preservation logic (~lines 74-79). The comment at line 7 names the two apps with no native
import mechanism; one of them is leaving, so rewrite the comment rather than leaving it
half-true. Lines 163/176/197 reference the removed block as the pattern precedent for satty
and gtk — repoint those to the remaining precedent (yazi), do not orphan them.

**reload.sh** — delete the whole reload function (~lines 253 onward, the kill/poll/bus-name/
socket-cleanup/backend-health/version-match sequence) and its call site at ~line 138, plus
the two prose comments at lines 7 and 33.

**theme-doctor** — delete the symlink check (~lines 234-237), the health and version block
(~lines 252-288), the provider-parity block (~lines 290-325), and the path entry at ~line 359.

**theme-stress-test** — delete the bus-name constant (~line 33), the four check functions
(~lines 192-210), the four preconditions (~lines 415-425), the four per-switch assertions
(~lines 498-509) and the four postconditions (~lines 559-569), plus the header prose at
lines 16-17 and the comments at 143 and 376.

**motion-lint** — remove the exemption entry at ~line 426 and the scan root at ~line 1308.
The exemption list carries a deny-by-default self-check that fails on an empty reason, so
remove the whole entry, never blank its reason.

**verify/theme-doctor-session-allowlist.txt** — remove both session-dependent allowlist lines
(72-73). They allowlist checks that no longer exist; leaving them is a stale entry of exactly
the kind this task is eliminating. Update `verify/container-run.sh`'s prose at lines 40-41 to
match.

**Prose-only, rewrite don't orphan:** `contract.sh` lines 142 and 251, `gtk.sh` line 167,
`theme-apply` lines 10 and 51, `zellij-config.kdl` line 31, `.gitignore` lines 14-18 (the
ignore rule at line 18 goes too — the file it ignores is gone).

`theme-doctor` must exit 0 at the end of this task, and a full theme switch must still apply
end-to-end. Run `theme-apply` against the current theme to prove the pipeline is intact, then
`theme-doctor`. `theme-stress-test` is the slower proof and belongs in the operator pass.
  </action>
  <verify>
    <automated>cd /home/aorus/dotfiles &amp;&amp; test "$(grep -rci 'walker\|elephant' theme-engine/ matugen/ verify/ .gitignore | awk -F: '{s+=$2} END {print s}')" -eq 0 &amp;&amp; python3 -c 'import json; json.load(open("theme-engine/.config/theme-engine/contract.json"))' &amp;&amp; bash -n theme-engine/.config/theme-engine/lib/reload.sh theme-engine/.config/theme-engine/lib/commit.sh theme-engine/.config/theme-engine/theme-doctor theme-engine/.config/theme-engine/theme-stress-test &amp;&amp; shellcheck -S error theme-engine/.config/theme-engine/lib/reload.sh theme-engine/.config/theme-engine/lib/commit.sh &amp;&amp; ./hypr/.config/hypr/scripts/motion-lint --self-test &amp;&amp; ./hypr/.config/hypr/scripts/motion-lint --no-pending &amp;&amp; ~/.config/theme-engine/theme-apply "$(cat ~/.local/state/theme/current-theme)" &amp;&amp; ~/.config/theme-engine/theme-doctor</automated>
  </verify>
  <done>`theme-engine/`, `matugen/`, `verify/` and `.gitignore` carry zero references including comments; `contract.json` is valid JSON with both entries gone and no orphan left behind; `motion-lint --self-test` and `--no-pending` both pass; a full `theme-apply` run still renders and reloads; `theme-doctor` exits 0. All of it in one commit.</done>
</task>

<task type="auto">
  <name>Task 12: Tree and package retirement; flip the registry to retired</name>
  <files>walker/, elephant/, hypr/.config/hypr/scripts/elephant-restart.sh, hypr/.config/hypr/scripts/theme-switch.sh, hypr/.config/hypr/scripts/emoji-picker.sh, hypr/.config/hypr/scripts/cheat-sheet.sh, hypr/.config/hypr/scripts/tests/test-walker-dmenu-cancel.sh, hypr/.config/hypr/scripts/retirement-check, hypr/.config/hypr/scripts/stow-link-check, hypr/.config/hypr/scripts/quickshell-doctor, hypr/.config/hypr/scripts/hypr-lua-harness, hypr/.config/hypr/scripts/cheat-sheet-parser.sh, hypr/.config/hypr/scripts/cheat-sheet-view-all.sh, hypr/.config/hypr/scripts/icon-theme-picker.sh, hypr/.config/hypr/scripts/font-switcher.sh, quickshell/.config/quickshell/shell.qml, quickshell/.config/quickshell/modules/Dashboard.qml, quickshell/.config/quickshell/modules/Overview.qml, quickshell/.config/quickshell/modules/dashboard/NewsBackend.qml, quickshell/.config/quickshell/modules/dashboard/ToggleState.qml, quickshell/.config/quickshell/modules/settings/PageRegistry.qml, quickshell/.config/quickshell/modules/settings/pages/DisplayPage.qml, quickshell/.config/systemd/user/quickshell.service, nvim/.config/nvim/colors/rice.lua, install.sh, stow.sh, .stow-local-ignore, README.md, VERIFICATION.md</files>
  <action>
The last task. `retirement-check`'s per-class report for both surfaces is the worklist — run
it first, work the classes it names, and re-run until both are clean.

**Delete outright:** the `walker/` package, the `elephant/` package (all six menu TOMLs go
with it), `elephant-restart.sh` (it exists only to cycle those two processes),
`theme-switch.sh` (a pure picker, fully replaced in Task 5), `emoji-picker.sh` (replaced in
Task 7), `cheat-sheet.sh` (replaced in Task 9), and
`tests/test-walker-dmenu-cancel.sh` — the design note names this one explicitly as dead on
retirement; it drives `theme-switch.sh` and nothing else, so both die together.

**Package lists:** `install.sh:355-366` lists 11 packages (the launcher plus ten backend
providers) — remove all 11, and the prose at line 406 that names them as an example. Verified
during planning: **nothing is added** to `install.sh` by this migration; every replacement
binary is already installed and already listed. `stow.sh` lines 21 and 34 list both packages —
remove both. `.stow-local-ignore` line 9's comment references the deleted rice-theme wiring.
`stow-link-check` carries both package names in its expected-package lists at ~lines 205-231 —
remove them there or its own assertion goes stale.

**Prose-only comment rewrites, all in the blocking tier.** `retirement-check`'s blocking tier
deliberately counts prose comments in live code, so every one of these must be rewritten, not
skipped — this is the single largest source of a stuck-red retirement. Eight QML/config sites:
`shell.qml` (5 comment sites naming the old menu as a dispatch caller — rewrite each to name
the QML menu instead), `Dashboard.qml:715`, `Overview.qml:275`, `NewsBackend.qml:1501`
(unrelated sense of the word, still a word-boundary hit — reword),
`ToggleState.qml:85/195/201` (describes a focus-stealing interaction that no longer exists —
re-describe against the new surface, do not just delete the finding),
`PageRegistry.qml:23`, `DisplayPage.qml:201`, `quickshell.service:7`. Plus `rice.lua:3` (the
theme directory naming convention it cites is going away — say where the name comes from now),
`hypr-lua-harness:50`, `quickshell-doctor:11`, `cheat-sheet-parser.sh:5`,
`cheat-sheet-view-all.sh:70`, and the two picker headers at `icon-theme-picker.sh:7` and
`font-switcher.sh:7` that define themselves by contrast with the retired pattern — those two
scripts are **not** dmenu consumers and their logic must not be touched, only their comments.

**Docs:** `README.md` lines 3, 10, 22, 52-54, 77, 116, 142 and `VERIFICATION.md` lines 19,
227, 257-259, 349 all describe the retired surface as live. Rewrite them to describe the QML
launcher — including README's keybind table, which currently documents the Super tap as
opening the old launcher.

**Flip the registry.** Change both `retirement-check` rows from `pending` to `retired` only
after `retirement-check <surface>` reports zero blocking hits for each. Run
`retirement-check --all` and `--self-test` afterwards, since `--all` runs the full blocking
tier for every retired surface and is what `theme-doctor`'s fold calls.

**Uninstall from the host**, matching the RETIRE-01..05 pattern of retiring from repo *and*
host: remove all 11 packages. Do this last, after every gate is green, so a red gate is never
confounded with a missing binary.
  </action>
  <verify>
    <automated>cd /home/aorus/dotfiles &amp;&amp; ./hypr/.config/hypr/scripts/retirement-check walker &amp;&amp; ./hypr/.config/hypr/scripts/retirement-check elephant &amp;&amp; ./hypr/.config/hypr/scripts/retirement-check --all &amp;&amp; ./hypr/.config/hypr/scripts/retirement-check --self-test &amp;&amp; test "$(./hypr/.config/hypr/scripts/retirement-check --list | grep -c 'status=pending')" -eq 0 &amp;&amp; test "$(grep -rl 'walker\|elephant' --exclude-dir=.planning --exclude-dir=.git . 2>/dev/null | wc -l)" -eq 0 &amp;&amp; test ! -d walker &amp;&amp; test ! -d elephant &amp;&amp; ./hypr/.config/hypr/scripts/stow-link-check &amp;&amp; ./hypr/.config/hypr/scripts/keybind-doctor &amp;&amp; ./hypr/.config/hypr/scripts/colour-lint &amp;&amp; ./hypr/.config/hypr/scripts/motion-lint &amp;&amp; ~/.config/theme-engine/theme-doctor &amp;&amp; ./hypr/.config/hypr/scripts/quickshell-doctor --self-test &amp;&amp; test "$(pacman -Qq 2>/dev/null | grep -cE '^(walker|elephant)')" -eq 0</automated>
  </verify>
  <done>Zero files outside `.planning/` reference either surface (the repo-wide count that measured 59 at planning time now measures 0); both packages are deleted from the repo and uninstalled from the host; both registry rows read `retired`; `retirement-check` clean for each surface, for `--all`, and for `--self-test`; `stow-link-check`, `keybind-doctor`, `colour-lint`, `motion-lint`, `theme-doctor` and `quickshell-doctor --self-test` all pass.</done>
</task>

</tasks>

<multi_source_coverage_audit>
Every item from every source artifact, mapped to the task that covers it. No item is MISSING.

**SPEC — the seven measured roles and the retirement**

| Item | Source | Covered by |
|---|---|---|
| App launcher (5 default providers) | Measured, "five roles" | T1 (apps), T2 (calc/websearch/files/runner fold-in), T3 (menus) |
| Prefix router, 6 routes | Measured | T2 (all six declared), T7 (`.`), T8 (`:`) |
| Menu tree, 6 TOMLs / 36 entries | Measured | T3 (all 36 re-homed, byte-identical commands) |
| dmenu consumer 1 — theme switch | Measured | T5 |
| dmenu consumer 2 — emoji | Measured | T7 |
| dmenu consumer 3 — cheat sheet | Measured | T9 |
| dmenu consumer 4 — clipboard wipe | Measured | T6 |
| dmenu consumer 5 — record audio | Measured | T6 |
| dmenu consumer 6 — bar orientation | Measured | T5 |
| dmenu consumer 7 — Super+C pipeline | Measured | T8 |
| Entrypoints: launcher / runner / Super-tap / escape hatch / Super+C | Measured | T1, T2, T3, T10 (DQ-1), T8 |
| Autostart: two processes | Measured | T10 |
| Theme target: contract/reload/doctor/stress/commit | Measured | T11 |
| Dead test script | Carried risk | T12 |

**CONTEXT — the six locked decisions**

| Decision | Covered by |
|---|---|
| D-1 — Option B, one frame, per-mode result views, own LazyLoader + PanelWindow | T1 (window shape), T2 (view swap), T7 (grid), T9 (table); Phase 7 launcher/menu split preserved in T3 |
| D-2 — 9 verb-based roots, all 36 entries re-homed, Tools not Trigger | T3 |
| D-3 — R-1 / R-2 / R-3 ship with the migration, first to cut | T4; cut order in DQ-4 |
| D-4 — provider replacements (DesktopEntries, qalc, cliphist, QML tree, vendored fuzzy) | T1, T2, T3, T8 |
| D-5 — emoji bundles in-repo via FileView; cliphist contract; no spike needed | T7 (DQ-3), T8 (DQ-2) |
| D-6 — T-06-17: validate the glyph before typing | T7, with an explicit structural gate in `<verify>` |

**RESEARCH — admitted findings applied**

| Finding | Applied in |
|---|---|
| Omarchy: verb roots, Style/Setup split, preselect, per-menu placeholders — taken | T3 |
| Omarchy: bash architecture, Install/Remove roots — rejected | T3 (data model, not scripts); no package-management root exists |
| end-4: dedicated PanelWindow, prefix branching, vendored fuzzy, qalc spawn | T1, T2 |
| Caelestia: result view varies by content type | T2 |
| Caelestia-first bias points wrong here | T1, called out explicitly |
| Retired binary's set flag panics — do not resurrect | Never reintroduced; T10 removes the dead static guard |
| No performance work / no spike needed at 160 entries | T7 ships no proxy model, no pagination |

**Open questions** — Q1 RESOLVED (D-5, applied in T7/T8). Q2 moot (the surface is retired).
Neither blocks. Nothing else in `research/questions.md` touches this task.

**Excluded, correctly:** `icon-theme-picker.sh` and `font-switcher.sh` — verified during
planning as fzf-in-floating-kitty, not dmenu consumers; comments only in T12.
</multi_source_coverage_audit>

<verification>
Gates that must be green at the end, all runnable and none requiring a summon:

| Gate | Command |
|---|---|
| QML syntax | `qmllint quickshell/.config/quickshell/modules/launcher/*.qml` |
| Colour tokens (GATE-04, incl. CHECK A resolution) | `colour-lint` and `colour-lint --self-test` |
| Motion tokens | `motion-lint`, `--self-test`, `--no-pending`, plus the per-task `comm` existence check |
| Keybinds | `keybind-doctor` |
| Shell config | `hypr-lua-harness` on each edited Lua file |
| Theme pipeline | `theme-doctor` (exit 0 strictly) |
| Stow tree | `stow-link-check` |
| Shell health | `quickshell-doctor --self-test` |
| Retirement | `retirement-check walker`, `retirement-check elephant`, `--all`, `--self-test` |
| Repo-wide | zero files outside `.planning/` matching either token (was 59) |

**Deliberately not automated here.** No `qml6` probe script may be spawned — each opens a real
window and a loop of them takes the session down. No render gate is fabricated for a surface
whose correctness is visual. Live confirmation is the operator pass below.
</verification>

<operator_pass>
Nine things only a human at the keyboard can confirm. Run after Task 12 commits.

1. Super+Space opens the launcher; typing filters; Enter launches; Escape dismisses.
2. A bare Super tap opens the menu at the nine roots; drill into Style ▸ Theme, switch theme,
   confirm the whole desktop re-themes; go back a level with the back affordance.
3. Each prefix in turn from one open surface: `=2+2*10`, `/`, `:`, `.`, `;`, `@`.
4. Tools ▸ Emoji: pick a glyph, confirm it is typed into a focused text field **and** on the
   clipboard.
5. Learn ▸ Keybinds: confirm selecting a row copies the chord and launches nothing; confirm
   the pinned view-all row opens the kitty table.
6. Super+C: restore a clipboard entry; delete one; run wipe and confirm the safe option is
   preselected.
7. System ▸ Updates and System ▸ System info both render real data (R-1, R-2).
8. Super+Escape: confirm the shell service restarts and the bar/notifications/OSD come back
   (DQ-1 — this is the one behaviour change in the whole task).
9. `theme-stress-test` — the long-running proof that repeated switching stays healthy with the
   retired assertions gone.
</operator_pass>

<follow_ups>
Named here so they are not silently re-added mid-task, and not lost afterwards.

1. **Clipboard image previews** (DQ-2). D-5 records the full contract already — the binary-data
   marker regex, width/height parse, decode-once-to-temp-file on completion, delete on
   destruction. Cheap to add later precisely because the research is done.
2. **Emoji keyword widening** (DQ-3). Today "happy" and "joy" match nothing because each glyph
   carries one name. end-4 ships multiple keywords per glyph; widening is a data-file change
   with no code change.
</follow_ups>

<success_criteria>
- 12 tasks, each independently committable, executed in the stated order.
- Stage 3 begins only after stages 1 and 2 are complete and committed — retirement is strictly
  last, because a half-retirement red-lights five checkers at once.
- All 36 menu entries reachable with byte-identical leaf commands.
- All 7 dmenu consumers working with no external launcher process on the system.
- T-06-17 and T-07-26 both enforced structurally, not merely observed.
- R-1, R-2, R-3 delivered, or cut in the DQ-4 order with the cut recorded in the summary.
- Every gate in `<verification>` green; repo-wide reference count 0, down from the measured 59.
- Both packages uninstalled from the host; `install.sh` gains no package and loses 11.
</success_criteria>

<output>
Write `.planning/quick/260822-sht-migrate-walker-elephant-to-a-native-quic/260822-sht-SUMMARY.md`
when done. Record: the DQ-4 cut decision (which of R-1..R-3 shipped and which, if any, were
cut and why), whether the compositor picked up Task 10's layer-rule change by restart or by
`hyprctl eval`, the final repo-wide reference count, and anything `retirement-check` flagged
that this plan did not anticipate.

Do **not** update `ROADMAP.md` — quick tasks are separate from planned phases.
</output>
