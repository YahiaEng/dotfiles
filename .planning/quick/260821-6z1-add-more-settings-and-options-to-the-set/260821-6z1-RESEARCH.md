# Quick Task 260821-6z1: Settings window → complete control panel — Research

**Researched:** 2026-08-21
**Domain:** Quickshell/QML settings surface + Hyprland live-config actuation under the Lua config manager
**Confidence:** HIGH on everything measured live on this host today (marked `[MEASURED]`); MEDIUM on the one upstream-reference claim (marked `[FETCHED]`); nothing here is `[ASSUMED]` unless it says so.

> **Probing disclosure (two residual state changes I made and could not fully undo — read first).**
> 1. `binds:workspace_back_and_forth` — value restored to `false`, but its `set` flag is now `true`
>    (was `false`). `hypr-equivalence-check` re-run after the fact: **PASS 3 / FAIL 0**, so no gate is
>    affected. Clears on next compositor start.
> 2. `instant-usb-gaming-mouse-` `scrollFactor` — was `-1.00` (the "inherit global" sentinel), is now
>    `1.00`. `hl.device` **rejects** `scroll_factor = -1` (`value -1.00 is less than the minimum of
>    0.00`), so the sentinel cannot be written back. `hyprctl getoption input:scroll_factor -j` →
>    `{"float": 1.000000}`, so 1.00 is behaviourally identical to inheriting the global. Clears on
>    next compositor start.
> Every other probe (gaps_in/gaps_out/border_size/rounding/blur size+passes+enabled/inactive_opacity/
> shadow:enabled/animations:enabled/sinowealth kb_layout) was applied **and verified restored** —
> final sweep output is quoted in §2.4. `git status --porcelain` clean apart from this task's own
> untracked `.planning/` dir and the pre-existing `.gsd/`.
> I did **not** run `hyprctl reload`, did not restart quickshell or Hyprland, did not spawn `qml6`,
> and took no screenshots.

---

## User Constraints (from CONTEXT.md)

### Locked Decisions

- **All four bundles ship in this task** — compositor look & feel; shell internals; system & session;
  deepen existing pages. "Scope is deliberately large; this is not to be silently narrowed."
- **Persistence is HYBRID:**
  - Shell-internal knobs → a **new `Prefs` singleton** over a JSON `FileView` (Caelestia's `Config`
    pattern). This is the store that does not exist today and must be built.
  - Compositor knobs → **extend `hypr-overrides.sh`'s allowlist**, keeping validate → apply-live →
    verify → persist. **Do NOT move that validation into QML.**
  - Existing per-feature state files (`bar-orientation`, `motion.json`, `idle-overrides.conf`,
    `overrides.json`, `font-choice`, `icon-theme`) stay where they are; no migration.
- **Navigation:** ~eight nav entries in the operator's own layout (Appearance / Wallpaper / Bar /
  Audio / Network / Display / Input / Window mgr / Notifs / Session), keeping `category` grouping.
  Existing `category` deep-link keys (`appearance`/`connectivity`/`display`/`shell`) must keep
  resolving through `shell.qml`'s `openSettingsPage(name)`.
- **F-01 search covers every row, not just page titles.**
- **Sequencing:** Prefs singleton + nav split + search bar land and are verified FIRST.

### Claude's Discretion

- Per-page allocation of the ~40-60 controls; row-primitive choice per control; Prefs JSON schema
  shape and file location under `~/.local/state/`; fuzzy vs substring search; whether the registries
  gain a per-row search index or search walks live page instances.

### Deferred Ideas (OUT OF SCOPE)

- **F-04 (`StackPage` drill-down sub-pages) was NOT selected** — flat pages + search instead.

---

## Summary

Four things are now measured rather than assumed, and each one changes what the plan can promise.

**(1) The `Prefs` write-back idiom already exists in this repo, twice, and it is NOT `JsonAdapter`.**
Every *read-only* store here (Colours, Motion, ToggleState, BarEntryModel, news-sources) uses
`FileView{watchChanges:true} + JsonAdapter`; every *writing* store (`NotifServer` state,
`WeatherBackend` cache, `NewsBackend` cache) uses `FileView{watchChanges:false; atomicWrites:true} +
manual JSON.parse/JSON.stringify + Component.onCompleted: reload()`. `onAdapterUpdated:
writeAdapter()` appears exactly once in the whole tree, in `Probe.qml` — a diagnostic, not a
settings store. Copy `NotifServer.qml:617-730` verbatim; it is the only shape in this repo that has
survived a real save-failure revert path.

**(2) Every compositor knob the operator asked for writes via `hyprctl eval` and has a real
`hyprctl getoption -j` read-back — except animation *speed*, which is not a compositor option at all
on this host, and *border colour*, which is theme-owned and would have to be taken away from the
theme pipeline to be settable.** Nine knobs were applied live and restored, with before/after/restore
output quoted below. `gaps_in`/`gaps_out` verify on a `.css` string field (`"5 5 5 5"`), not `.int` —
the same field-name class of bug that already bit `input:touchpad:natural_scroll` (`.bool`, not
`.int`) in the last task.

**(3) Search cannot walk live page instances.** `Pages.qml:_swapTo()` destroys the previous page
before incubating the next (`Pages.qml:120-137`), so exactly one page object exists at any moment.
A declarative per-row search index alongside `PageRegistry` is the only workable shape — and
Caelestia does **not** have one to borrow (its `NexusState.searchOpen` is bound by `NavPane.qml` and
consumed by nothing; there is no search-results component anywhere in `modules/nexus/`).

**(4) Per-device input (F-03) is feasible for keyboards and scroll factor, and NOT feasible for
per-device sensitivity.** `hl.device({name=…, kb_layout=…})` applies and is verifiable via
`hyprctl devices -j .keyboards[].layout`; `scroll_factor` is verifiable via `.mice[].scrollFactor`;
per-device `sensitivity` produced **no** observable change in any `hyprctl` output, and
`hyprctl getoption device:<name>:<key>` returns `no such option`. Under this script's contract
("verify against `hyprctl -j`, never the `ok` reply"), per-device sensitivity **cannot be added**.
The device-list filter has a measurable answer: udev's `ID_INPUT_KEYBOARD=1` reduces 7 keyboards to
the correct 3.

**Primary recommendation:** Build `modules/Prefs.qml` on `NotifServer.qml`'s exact write-back shape at
`~/.local/state/quickshell/prefs.json`; add a `searchTerms` array to each `PageRegistry.pages[]` entry
plus a new sibling `RowIndex.qml` singleton listing every row as `{pageIdx, section, label, keywords}`;
extend `hypr-overrides.sh` with a `look` subcommand covering the eight verifiable knobs in §2.3's
GREEN table and a `device` subcommand covering `kb_layout` + `scroll_factor` only; leave animation
speed on the existing Motion-preset row and leave border colour to the theme pipeline (say so in the
UI rather than shipping a knob the next theme switch silently reverts).

---

## 1. The `Prefs` singleton — the exact working idiom in this repo

### 1.1 Two idioms exist, and only one of them writes

`[MEASURED: grep over quickshell/.config/quickshell/**/*.qml, 2026-08-21]` — every `setText(`,
`atomicWrites`, `writeAdapter()` occurrence in the tree:

```
modules/Colours.qml:33   // deliberately omits `onAdapterUpdated: writeAdapter()` on both FileViews
modules/Probe.qml:197                       onAdapterUpdated: writeAdapter()
modules/notifications/NotifServer.qml:621        atomicWrites: true
modules/notifications/NotifServer.qml:729        stateFile.setText(JSON.stringify({ history: root.history, dnd: root.dnd }));
modules/dashboard/WeatherBackend.qml:479        atomicWrites: true
modules/dashboard/WeatherBackend.qml:551        cacheFile.setText(JSON.stringify(obj));
modules/dashboard/NewsBackend.qml:603            sourcesFile.setText(JSON.stringify(parsed, null, 2));
modules/dashboard/NewsBackend.qml:1058        cacheFile.setText(JSON.stringify(obj));
modules/dashboard/NewsBackend.qml:1181            sourcesFile.setText(JSON.stringify(parsed, null, 2));
modules/dashboard/NewsBackend.qml:1603        atomicWrites: true
```

`onAdapterUpdated: writeAdapter()` — the "obvious" JsonAdapter write-back — is used **once**, in
`Probe.qml` (a diagnostic surface). `Colours.qml:33` records that it was *deliberately omitted*.
**Do not use `writeAdapter()` for `Prefs`.** `[MEASURED]`

### 1.2 The idiom to copy, verbatim

`NotifServer.qml:617-641` `[MEASURED: file read 2026-08-21]`:

```qml
FileView {
    id: stateFile
    path: Quickshell.env("HOME") + "/.local/state/quickshell/notifications.json"
    watchChanges: false
    atomicWrites: true
    printErrors: true
    onLoaded: root._loadState()
    onLoadFailed: (error) => {
        // Never-persisted / first run is the expected state, not an error
        root._stateLoaded = true;
    }
    onSaveFailed: (error) => {
        console.log("NotifServer: state write failed: " + error);
        if (root._dndTogglePending) { root.dnd = root._dndPrevValue; }   // revert on failed write
        root._dndTogglePending = false;
    }
}

Component.onCompleted: stateFile.reload()
```

and the write half, `NotifServer.qml:713-730`:

```qml
function _writeState() {
    if (!root._stateLoaded) return;      // never write before the first read has settled
    stateFile.setText(JSON.stringify({ history: root.history, dnd: root.dnd }));
}
```

Load is guarded by an explicit shape check inside `try/catch` (`_loadState()`, lines 645-668):
a bare array is tolerated, a non-object is ignored, `typeof obj.dnd === "boolean"` gates the scalar.
`WeatherBackend.qml:495-533` does the same with a stricter `_payloadShapeValid()` gate.

**Answers to the four sub-questions:**

| Question | Answer, with evidence |
|---|---|
| Read-on-start | `Component.onCompleted: stateFile.reload()` — an explicit imperative reload, **not** implicit. `NotifServer.qml:637`, `WeatherBackend.qml:491`, `NewsBackend.qml:1614` all do this. `[MEASURED]` |
| Write-back-on-change | Manual `setText(JSON.stringify(...))` from a named function, gated on a `_stateLoaded` flag so a first-run write cannot race the first read. `NotifServer.qml:713-730`. `[MEASURED]` |
| `watchChanges` | **`false`** for a writing store — every writing FileView in this tree sets it false. `[MEASURED]` |
| Atomic-write safety | `atomicWrites: true` on the FileView; the header at `NotifServer.qml:613` names it as "WeatherBackend.qml's own cache-write idiom (T-14-26's write-tearing mitigation)". `[MEASURED]` |

### 1.3 The `watchChanges: false` trap — and why it is the RIGHT choice here anyway

Project memory (`live-shell-ignores-disk-state-edits`) records that a `watchChanges:false` FileView
keeps its value in memory and ignores on-disk edits — restarting the shell is the only way to pick
up a hand-edit. That is a **real** consequence and must be documented in `Prefs.qml`'s header, but it
is not a reason to set `watchChanges:true`:

- `FileView` exposes **no per-write completion token** (`NotifServer.qml:717-728` records this
  verbatim: "`FileView` carries no explicit 'save succeeded' signal, only `onSaveFailed`"). With
  `watchChanges:true`, this shell's own `setText()` fires `onFileChanged` → `reload()` → a round-trip
  that can clobber a second in-flight edit. Nothing in this repo does both.
- The one file that is BOTH watched and written is `news-sources.json`
  (`NewsBackend.qml:1564-1571` `watchChanges:true`, written at `:603`/`:1181`) — and note the shape
  it was forced into: a **surgical read-modify-write** (`read raw text → JSON.parse → set exactly one
  key → stringify → write`), with an explicit refusal-to-write guard, because a whole-object
  republish "risks clobbering the operator's source list" (`NewsBackend.qml:582-591`). `[MEASURED]`

**Recommendation:** `watchChanges: false`, `atomicWrites: true`, and a header comment saying "edit
this file with the shell stopped, or through the settings window — a live shell will not see your
hand-edit." If a future need for external writes appears, adopt `NewsBackend`'s surgical
read-modify-write, not a watched whole-object republish.

### 1.4 File path and schema shape

`[MEASURED: ls -la ~/.local/state/quickshell/ and ~/.local/state/theme/, 2026-08-21]`

```
/home/aorus/.local/state/quickshell/:
drwxr-xr-x  bar-orientation   doctor-baseline.json   notifications.json   probe.json   by-shell/
/home/aorus/.local/state/theme/:
drwx------  ... 40 theme-engine render targets ...
```

`~/.local/state/theme/` is mode `drwx------` and is the theme engine's render-target directory —
**do not put `Prefs` there.** `~/.local/state/quickshell/` is mode `drwxr-xr-x`, already holds the
shell's own two state files, and is where `bar-orientation` lives.

**Recommended path:** `~/.local/state/quickshell/prefs.json`.

**Recommended schema — flat top-level namespaces, one object per domain:**

```json
{
  "version": 1,
  "bar":    { "autoHide": false, "capsules": { "media": true, "workspaces": true, "clock": true } },
  "notifs": { "popupTimeoutMs": 5000, "position": "top-right", "historyCap": 100, "maxVisiblePopups": 3 },
  "osd":    { "hideDelayMs": 1200, "position": "bottom" },
  "dashboard": { "panels": { "weather": true, "news": true, "media": true, "resources": true } },
  "session": { "confirmPowerActions": true }
}
```

Rationale: `JsonAdapter`'s "top-level keys only" limitation (`Motion.qml:107-113`, verified against
the installed `quickshell-io.qmltypes`) does **not** apply — we are hand-parsing — so nesting is free
and namespacing keeps the file readable for the operator, which CLAUDE.md's own convention
(`write-configs-humans-will-edit`) requires. Add a `"version": 1` field now; `NotifServer` had to
retrofit a `_migrateHistoryKeys()` migration for a file that shipped without one
(`NotifServer.qml:672-712`).

**Defaults live in QML, not in the file.** Every consumer reads `Prefs.notifs.popupTimeoutMs`
through a `Prefs`-side `readonly property int` that falls back to the current hardcoded literal —
matching `hyprland.lua`'s `or`-fallback discipline (`hyprland.lua:100-107`). A missing prefs.json
must degrade to exactly today's behaviour.

⚠ **`false`-is-falsy footgun.** The last task shipped this bug twice in one commit
(260820-sqd deviation 6): Lua's `x and y or z` AND jq's `//` both treat `false` as absent. The same
class exists in JS: `Prefs.bar.autoHide || true` is wrong for an explicit `false`. Use
`typeof v === "boolean" ? v : <default>`, exactly as `NotifServer.qml:666` does
(`if (typeof obj.dnd === "boolean") root.dnd = obj.dnd;`). `[MEASURED]`

### 1.5 Registration requirements (both are mandatory, or the singleton is `undefined` forever)

`modules/qmldir:14-21` `[MEASURED]`: "Empirically it needs BOTH: without the qmldir keyword, bare
`Colours.primary`-style access resolves to `undefined` forever (the object is never constructed)."

So `Prefs.qml` needs:
1. `pragma Singleton` in the file, and
2. `singleton Prefs 1.0 Prefs.qml` added to `modules/qmldir` **in the same commit**.

`modules/qmldir`, `modules/settings/qmldir`, `modules/settings/common/qmldir`, and
`modules/settings/pages/qmldir` all carry a standing instruction: a `.qml` type added to that
directory that is not declared in the manifest "becomes unresolvable forever, with no load error."
**Every new page and every new row primitive this task adds needs a qmldir line.** `[MEASURED]`

### 1.6 One cross-singleton wiring detail

`modules/dashboard/Design.qml:74-79` imports only `QtQuick` and `Quickshell` `[MEASURED]`. Its
`readonly property int osdHideDelayMs: 1200` (`:435`), `notifHistoryCap: 100` (`:500`),
`notifMaxVisiblePopups: 3` (`:463`) are the constants the "shell internals" bundle wants to make
adjustable. To let them read `Prefs`, `Design.qml` must gain `import "../"` — precedented (every
`modules/dashboard/*.qml` reaches `Colours`/`Motion` that way), and `Prefs` must be registered in
`modules/qmldir` (§1.5), not `modules/dashboard/qmldir`, for the same reason `CavaService` is
(`modules/qmldir:26-33`). `[MEASURED]`

---

## 2. Extending `hypr-overrides.sh` past `monitor`/`input`

### 2.1 The exact contract shape to preserve

`hypr-overrides.sh` header, lines 7-21 `[MEASURED: file read in full, 2026-08-21]`:

```
#   VALIDATE (closed allowlist) -> APPLY LIVE (hyprctl eval) ->
#   VERIFY (hyprctl -j, never the `ok` reply) -> PERSIST (atomic write,
#   only after live apply is proven)
#
# A value never proven live cannot reach the file the compositor `require`s
# at boot (T-SQD-03) — a bad mode cannot brick the display into an
# unrecoverable blank-at-every-boot state.
#
# `hyprctl keyword` is NEVER used here — it is a silent no-op for every
# key under this repo's Lua config manager.
```

Concretely, every new subcommand must reproduce all six of these, each of which exists because it
caught a real bug:

1. **Character allowlist before any use** — `[[ "$output" =~ ^[A-Za-z0-9._-]+$ ]]` (`cmd_monitor`,
   review CR-03), independent of the membership check.
2. **Bounded numeric validation via `awk`** — `awk -v s="$scale" 'BEGIN { exit !(s >= 0.25 && s <= 4.0) }'`.
3. **Fallback-read non-empty check before use** — the `for _pair in "kb_layout:$final_kb" …` loop in
   `cmd_input`; "an unchecked empty value here would make the `--argjson` calls fail, and
   `_persist("")` would silently clobber the ENTIRE overrides file."
4. **`_luastr()` escaping at the `hyprctl eval` sink**, not just at the persist sink (CR-03 found
   the eval sink was the one that had been missed).
5. **Verify ONLY the fields the call asked to change** (CR-01/CR-02) — verifying `$final_*` is a
   tautology because the fallback always populates it.
6. **`_persist()` refuses an empty/malformed JSON payload and `cp -a`s a `.bak` first.**

Plus the two field-name/precision traps already recorded in the file:
- `input:touchpad:natural_scroll` reports under `.bool`, **not** `.int` — "a `.int == 1` read here
  always evaluated to the literal string `false` regardless of the real value."
- `.float` formats to six decimals (`"0.000000"`), so sensitivity is compared numerically with an
  `awk` tolerance, never by string equality.

### 2.2 `hyprctl eval` writes — MEASURED live, each applied then restored

Command shape used for each: `hyprctl getoption <k> -j` → `hyprctl eval '<lua>'` → `sleep 0.35` →
`getoption` → restore eval → `sleep 0.35` → `getoption`. Raw output:

```
BEFORE general:gaps_in       {"option": "general:gaps_in", "css": "5 5 5 5", "set": true }
AFTER  general:gaps_in       {"option": "general:gaps_in", "css": "7 7 7 7", "set": true }
RESTOR general:gaps_in       {"option": "general:gaps_in", "css": "5 5 5 5", "set": true }

BEFORE general:gaps_out      {"option": "general:gaps_out", "css": "10 10 10 10", "set": true }
AFTER  general:gaps_out      {"option": "general:gaps_out", "css": "12 12 12 12", "set": true }
RESTOR general:gaps_out      {"option": "general:gaps_out", "css": "10 10 10 10", "set": true }

BEFORE general:border_size   {"option": "general:border_size", "int": 3, "set": true }
AFTER  general:border_size   {"option": "general:border_size", "int": 4, "set": true }
RESTOR general:border_size   {"option": "general:border_size", "int": 3, "set": true }

BEFORE decoration:rounding   {"option": "decoration:rounding", "int": 12, "set": true }
AFTER  decoration:rounding   {"option": "decoration:rounding", "int": 14, "set": true }
RESTOR decoration:rounding   {"option": "decoration:rounding", "int": 12, "set": true }

BEFORE decoration:blur:size  {"option": "decoration:blur:size", "int": 8, "set": true }
AFTER  decoration:blur:size  {"option": "decoration:blur:size", "int": 9, "set": true }
RESTOR decoration:blur:size  {"option": "decoration:blur:size", "int": 8, "set": true }

BEFORE decoration:blur:passes  {"option": "decoration:blur:passes", "int": 3, "set": true }
AFTER  decoration:blur:passes  {"option": "decoration:blur:passes", "int": 2, "set": true }
RESTOR decoration:blur:passes  {"option": "decoration:blur:passes", "int": 3, "set": true }

BEFORE decoration:blur:enabled {"option": "decoration:blur:enabled", "bool": true, "set": true }
AFTER  decoration:blur:enabled {"option": "decoration:blur:enabled", "bool": false, "set": true }
RESTOR decoration:blur:enabled {"option": "decoration:blur:enabled", "bool": true, "set": true }

BEFORE decoration:inactive_opacity {"option": "decoration:inactive_opacity", "float": 0.920000, "set": true }
AFTER  decoration:inactive_opacity {"option": "decoration:inactive_opacity", "float": 0.850000, "set": true }
RESTOR decoration:inactive_opacity {"option": "decoration:inactive_opacity", "float": 0.920000, "set": true }

BEFORE decoration:shadow:enabled {"option": "decoration:shadow:enabled", "bool": true, "set": true }
AFTER  decoration:shadow:enabled {"option": "decoration:shadow:enabled", "bool": false, "set": true }
RESTOR decoration:shadow:enabled {"option": "decoration:shadow:enabled", "bool": true, "set": true }

BEFORE animations:enabled    {"option": "animations:enabled", "bool": true, "set": true }
AFTER  animations:enabled    {"option": "animations:enabled", "bool": false, "set": true }
RESTOR animations:enabled    {"option": "animations:enabled", "bool": true, "set": true }

BEFORE binds:workspace_back_and_forth {"option": "...", "bool": false, "set": false }
AFTER  binds:workspace_back_and_forth {"option": "...", "bool": true,  "set": true }
RESTOR binds:workspace_back_and_forth {"option": "...", "bool": false, "set": true }   <-- `set` residual, see disclosure
```

The Lua form is uniformly `hl.config({ <section> = { <key> = <value> } })`, nesting for `blur`/`shadow`:
`hl.config({ decoration = { blur = { passes = 2 } } })`. `[MEASURED]`

### 2.3 Per-knob verdict table

| Knob | `hyprctl eval` writes? | Authoritative read-back | Read-back field | Verdict |
|---|---|---|---|---|
| `general:gaps_in` | ✅ measured | `hyprctl getoption general:gaps_in -j` | **`.css`** — `"5 5 5 5"` (4-tuple string, NOT `.int`) | **GREEN** |
| `general:gaps_out` | ✅ measured | `getoption general:gaps_out -j` | **`.css`** — `"10 10 10 10"` | **GREEN** |
| `general:border_size` | ✅ measured | `getoption general:border_size -j` | `.int` | **GREEN** |
| `decoration:rounding` | ✅ measured | `getoption decoration:rounding -j` | `.int` | **GREEN** |
| `decoration:blur:enabled` | ✅ measured | `getoption decoration:blur:enabled -j` | `.bool` | **GREEN** |
| `decoration:blur:size` | ✅ measured | `getoption decoration:blur:size -j` | `.int` | **GREEN** |
| `decoration:blur:passes` | ✅ measured | `getoption decoration:blur:passes -j` | `.int` | **GREEN** |
| `decoration:inactive_opacity` | ✅ measured | `getoption decoration:inactive_opacity -j` | `.float` (6dp — use `awk` tolerance) | **GREEN** |
| `decoration:shadow:enabled` | ✅ measured | `getoption decoration:shadow:enabled -j` | `.bool` | **GREEN** |
| `animations:enabled` | ✅ measured | `getoption animations:enabled -j` | `.bool` | **AMBER** — see §2.5 |
| `binds:workspace_back_and_forth` | ✅ measured | `getoption binds:workspace_back_and_forth -j` | `.bool` | **GREEN** (workspace behaviour) |
| `binds:allow_workspace_cycles` | not probed | `getoption` returns `{"bool": false, "set": false}` — option exists | `.bool` | **GREEN (likely)** — `[ASSUMED]` on the write half; probe before shipping |
| `general:gaps_workspaces` | not probed | option exists, `{"int": 0, "set": false}` | `.int` | **GREEN (likely)** — `[ASSUMED]` on write |
| **animation SPEED (per-leaf)** | n/a | **no such option** | — | **RED — see §2.5** |
| **`general:col.active_border`** | n/a here | `getoption general:col.active_border -j` → `{"gradient": "ffff79c6 ffbd93f9 ff8be9fd 45deg"}` | `.gradient` | **RED — see §2.6** |
| `general:no_border_on_floating` | — | `no such option` on Hyprland 0.56.2 | — | **RED — does not exist** |
| `misc:vfr` | — | `no such option` | — | **RED — does not exist** |
| `dwindle:pseudotile` | — | `no such option` | — | **RED — does not exist** |
| `animations:first_launch_animation` | — | `no such option` | — | **RED — does not exist** |
| `misc:new_window_takes_over_fullscreen` | — | `no such option` | — | **RED — does not exist** |

`[MEASURED: hyprctl getoption <k> -j for 47 keys, hyprctl version = Hyprland 0.56.2 commit efb50993]`

Four names that a plausible-sounding options list would have included **do not exist on this build**
and would fail the "verify read-back exists" gate outright. That is exactly the class the
verify-options-before-recommending memory exists for.

### 2.4 Final restore verification sweep

```
general:gaps_in                {"option": "general:gaps_in", "css": "5 5 5 5", "set": true }
general:gaps_out               {"option": "general:gaps_out", "css": "10 10 10 10", "set": true }
general:border_size            {"option": "general:border_size", "int": 3, "set": true }
decoration:rounding            {"option": "decoration:rounding", "int": 12, "set": true }
decoration:blur:enabled        {"option": "decoration:blur:enabled", "bool": true, "set": true }
decoration:blur:size           {"option": "decoration:blur:size", "int": 8, "set": true }
decoration:blur:passes         {"option": "decoration:blur:passes", "int": 3, "set": true }
decoration:inactive_opacity    {"option": "decoration:inactive_opacity", "float": 0.920000, "set": true }
decoration:shadow:enabled      {"option": "decoration:shadow:enabled", "bool": true, "set": true }
animations:enabled             {"option": "animations:enabled", "bool": true, "set": true }
binds:workspace_back_and_forth {"option": "binds:workspace_back_and_forth", "bool": false, "set": true }
```

All eleven at their `hyprland.lua` values. `hypr-equivalence-check` re-run: `PASS: 3  FAIL: 0`.

### 2.5 Animation speed is NOT a compositor option — it is already the Motion preset

`config/animations.lua` registers every leaf as `hl.animation({ leaf=…, speed = tokens.motion.speed.<name>,
bezier = "motion-<curve>" })` — 15 leaves, each guarded by an explicit nil check
(`animations.lua:96-233`). `tokens.motion.speed.*` comes from
`~/.local/state/theme/hyprland-tokens.lua`, written by the theme/motion engine.
`animations.lua:39` derives `animations:enabled` from `tokens.motion.enabled` with an explicit nil
test, with a comment recording that `tokens.motion.enabled or true` "silently re-enabl[ed] animation
for a user who deliberately turned it off — this repo already shipped exactly that bug once."
`[MEASURED]`

**Consequence:** a settings "animation speed" slider MUST go through the existing **Motion preset**
row (`ShellBehaviourPage.qml`, `motion-switch.sh`), which already drives both the QML `Motion.qml`
tokens and the compositor's animation speeds through one pipeline. Adding a separate compositor
animation-speed knob would create a second owner of a value `motion.json` owns — the exact violation
`animations.lua:88-95` refuses to make ("A duration/bezier literal here would itself be exactly the
raw-value violation motion-lint's CHECK B exists to catch"). Likewise, an `animations:enabled` toggle
in the settings window would fight `motion-scale = off`. **Recommendation: no new animation knob;
label the existing Motion-preset row so it reads as the animation control it already is.**

### 2.6 Border colour WOULD be clobbered — plainly

`hyprland.lua:74-90` `[MEASURED]`:

```lua
col = {
    active_border = {
        colors = {
            tokens.colors.primary   or "rgba(ff79c6ff)",
            tokens.colors.secondary or "rgba(bd93f9ff)",
            tokens.colors.tertiary  or "rgba(8be9fdff)",
        },
        angle = 45,
    },
    inactive_border = tokens.colors.outline or "rgba(6272a4ff)",
},
```

`theme-engine/.config/theme-engine/lib/reload.sh:70` runs `hyprctl reload` on **every theme apply**,
and its own header (lines 5-6) says "No other file in this repo may invoke `hyprctl reload`".
`gaming-mode-toggle.sh:39-43` restates the mechanism: "`hyprctl reload` re-sources the exact same
static config every time." `[MEASURED]`

So: **an eval-applied border colour survives until the next theme switch and is then silently
replaced by the new palette's `primary`/`secondary`/`tertiary`.** To make it stick you would have to
invert the precedence at the consumption site — `overrides.general.col.active_border or
tokens.colors.primary` — which *permanently removes the border from the theming pipeline*. That is
directly contrary to PROJECT.md's Core Value ("One theme switch … instantly and consistently
re-themes the entire desktop").

Also note `hypr-equivalence-check:342-346` lists `general:col.active_border`,
`general:col.inactive_border`, `decoration:shadow:color` in `THEME_DRIVEN_KEYS`, where the gate
compares presence only and defers colour correctness to `theme-parity`/`theme-doctor`. Making it
operator-settable would need it moved to `VOLATILE_KEYS`, weakening the theme gate.

**Recommendation: do NOT ship a border-colour override.** If the operator wants control here, the
correct surface is an `InfoRow`/`NavRow` that says "border colour follows the active theme" and
deep-links to the Theme row — one sentence of honesty instead of a knob that undoes itself.

### 2.7 Persistence: every new knob needs an `or`-fallback consumption site

`hypr-overrides.sh`'s persistence is a **projection**: `_persist()` re-renders `overrides.lua`
wholesale from `overrides.json` via a jq template, and `hyprland.lua` reads it through
`lib/overrides.lua`'s `pcall(require, "state.overrides")` shape-normaliser. For a new knob to
survive `hyprctl reload` (and therefore a theme switch), three edits are required together:

1. `_persist()`'s jq template gains a `general = { … }` / `decoration = { … }` block — with the
   `(.x | type) != "null"` idiom, **never** jq's `//`, which treats `false` as absent (260820-sqd
   deviation 6).
2. `lib/overrides.lua`'s `M.get()` normaliser gains `overrides.general` / `overrides.decoration` /
   `overrides.decoration.blur` sub-tables so callers can index two levels deep.
3. `hyprland.lua`'s `general`/`decoration` blocks read `overrides.general.gaps_in or 5` etc. — and
   for every **boolean** knob (`blur.enabled`, `shadow.enabled`) an explicit `if … ~= nil then`
   conditional, never `and/or`, exactly as `hyprland.lua:56-59` already does for `natural_scroll`.

### 2.8 A gate that will break if you skip it

`hypr-equivalence-check:438-443` `[MEASURED]`:

```python
VOLATILE_KEYS = {
    'input:kb_layout',
    'input:follow_mouse',
    'input:sensitivity',
    'input:touchpad:natural_scroll',
}
```

Every new operator-adjustable compositor key **must** be added here or the gate FAILs the moment the
operator changes it. Its header (lines 426-433) frames each entry as "a permanent hole in this
comparator … a conscious trade of coverage for a real, operator-facing feature". This is a
gate-widening decision the plan should call out explicitly rather than bury in a diff.

---

## 3. Search over every row (F-01)

### 3.1 Live-instance search is structurally impossible

`Pages.qml:120-137` `[MEASURED]`:

```qml
function _swapTo(idx) {
    if (idx < 0 || idx >= PageCompRegistry.comps.length) { console.warn(...); return; }
    if (root.currentItem) { root.currentItem.destroy(); root.currentItem = null; }
    var comp = PageCompRegistry.comps[idx];
    var incubator = comp.incubateObject(root, { sState: root.sState }, Qt.Synchronous);
    ...
}
```

The previous page is **destroyed** before the next is incubated. At any instant exactly one page
object exists. `Pages.qml:38-52`'s `_collectFocusableRows()` — a recursive walk over
`root.currentItem` looking for `focusable === true` — proves the mechanism for enumerating rows, but
only for the page that is currently mounted.

Building a search index by instantiating all eight pages would:
- undo the whole point of the lazy incubation pattern (`Pages.qml:1-3` header);
- start eight pages' worth of live `Process`/`FileView` children at once (`DisplayInputPage.qml` runs
  `hyprctl monitors -j` and `hyprctl devices -j`; `ShellBehaviourPage.qml` reads
  `idle-overrides.conf`; `AppearancePage.qml` holds four `FileView`s) — measured file counts:
  `DisplayInputPage.qml` 407 lines, `ShellBehaviourPage.qml` 456 lines;
- and, per the 260820-sqd measurement recorded at `Pages.qml:141-152`, the destroy+incubate cost is
  0-13 ms per page, so this is not about speed — it is about side effects.

### 3.2 Caelestia has no pattern to borrow — measured negative

`[FETCHED: raw.githubusercontent.com/caelestia-dots/shell/main/modules/nexus/*, 2026-08-21]`

- `NexusState.qml` declares `property bool searchOpen`.
- `NavPane.qml` binds it: `Binding { target: root.nState; property: "searchOpen"; value: searchField.text.length > 0 }`.
- `navpane/NavLocations.qml` renders `model: PageRegistry.pages` **unfiltered** — no reference to
  `searchOpen` or to the search text anywhere in it.
- `Pages.qml` and `Nexus.qml` contain no reference to `searchOpen` either.
- The full `modules/nexus/` tree (77 entries, fetched via the GitHub trees API) contains **no**
  `SearchResults.qml`, `SearchPage.qml`, or equivalent.

**Conclusion:** `searchOpen` is an inert hook in Caelestia's main branch today. The reference-shell
bias cannot resolve this decision; the design is ours to make. `[FETCHED — confidence MEDIUM: this is
main-branch state on 2026-08-21, not a released version]`

### 3.3 Recommendation — a declarative per-row index, a new sibling singleton

Add `modules/settings/RowIndex.qml` (`pragma Singleton` + a `singleton RowIndex 1.0 RowIndex.qml`
line in `modules/settings/qmldir`, per §1.5), holding one flat `list<var>`:

```qml
readonly property list<var> rows: [
    { pageIdx: 0, section: "Theme",  label: "Theme",           keywords: "theme palette colour color scheme dracula matugen" },
    { pageIdx: 5, section: "Blur",   label: "Blur passes",     keywords: "blur passes frost glass decoration" },
    ...
]
```

Why a **separate** singleton rather than a `searchTerms` field inside `PageRegistry.pages[]`:
`PageRegistry` is per-PAGE and is index-locked to `PageCompRegistry` — "Index N in one must match
index N in the other; a mismatch renders the wrong page with no error" (`PageCompRegistry.qml:1-6`).
Rows are per-ROW and there are ~60 of them; folding a 60-entry array into a 8-entry index-locked list
makes the one invariant this module already has harder to see. A third singleton with a `pageIdx`
foreign key keeps the existing invariant untouched.

**The drift risk, named:** a row added to a page but not to `RowIndex` becomes unsearchable, silently.
Mitigate it with a **gate**, not a convention: a small check (either a new `settings-index-check`
script, or a case added to `quickshell-doctor --self-test`) asserting
`count(RowIndex.rows where pageIdx==N) == count(focusable rows in pages/<N>.qml)`. The per-page row
count is greppable statically — every row primitive declares `readonly property bool focusable: true`
(`SelectRow.qml:52`), so `grep -c` of `ToggleRow {`/`SliderRow {`/`SelectRow {`/`NavRow {` per page
file gives the denominator. Without a gate this index rots on the first follow-up commit.

**Matching:** substring, case-insensitive, over `label + " " + section + " " + keywords`. Not fuzzy.
Reason: `SelectRow`'s own live-pass history shows how much time went into a QQC2 popup's hit
geometry; a Levenshtein/subsequence matcher adds a tuning surface with no measurable payoff at ~60
rows, and a wrong fuzzy hit at the top of the list is worse than a missing substring hit. If the
operator later wants fuzziness, the `keywords` field is where synonyms go (that is what it is for).

**Selecting a result** sets `sState.currentPageIdx = row.pageIdx` (the existing, already-animated
swap path — `Pages.qml:186-197` confirms both the nav click and the IPC deep-link funnel through it)
and then sets `Pages.contentRowIdx` to the row's ordinal so the existing `_scrollRowIntoView()` +
`rowFocused` ring highlights it. **Reuse both — do not build a second highlight visual.**

⚠ The search `TextField` is a QQC2 control and falls in colour-lint's blind spot (§6.1). Style its
`background` and `color` explicitly from `Colours.qml`, and pixel-verify.

---

## 4. Wiring existing scripts as rows

`[MEASURED: file reads + live invocation of each status verb, 2026-08-21]`

| Script | CLI surface (measured) | Query/status verb? | Live output today | Row viability |
|---|---|---|---|---|
| `gaming-mode-toggle.sh` | `status` \| *(no arg = toggle)* — `main()` at `:278-294` | ✅ **`status`** → `on`/`off` | `off` | **Good.** Also readable without a subprocess: `~/.cache/gaming-mode` — `ToggleState.qml:89-96` and `NotifServer.qml:86-92` already watch it with a `FileView{watchChanges:true}`. Bind the row to `ToggleState.gamingState`; no new reader. |
| `bar-visibility.sh` | `status` \| `reassert` \| `keybind toggle` \| `idle\|fullscreen\|gaming hide\|show` — `main()` at `:326-370` | ✅ **`status`** → `visible` \| `hidden-idle` \| `hidden-hard` (`:218,231,233`) | `hidden-idle` | **Good, with a caveat.** Three-valued, not boolean — a `ToggleRow` misrepresents it. Use a `SelectRow`/`InfoRow` pair, or a toggle bound to `keybind toggle` with the current `status` string as subtext. Note `main()` takes an flock (`_acquire_lock`) before doing anything, so polling it from QML is a contention surface — poll only while the page is mounted. |
| `wallpaper-visibility.sh` | `status` \| `reassert` \| `select <x>` \| `clear` \| `snapshot` \| `restore` \| `idle\|gaming\|motion hide\|show` — `main()` at `:459-505` | ✅ **`status`** → `stopped` \| `playing:<selection>` (`:260,262`) | `stopped` | **Good.** Same flock caveat. The `playing:<sel>` form carries the selection inline — parse on `:`, do not string-compare the whole value. |
| `record-toggle.sh` | **No subcommands at all.** No `case "$1"`, no `"$@"`. The whole script is `if recording_active; then stop_recording; else start_recording; fi` (final 5 lines). | ❌ **none** | — | **Design problem — named.** The only status probe is `pgrep -f "^gpu-screen-recorder "` (`:33-41`), which its own header (`:20-22`) calls "a `pgrep` status probe a future bar module could read." A row can read state by running that `pgrep` itself, but "screen-recording **defaults**" (CONTEXT bundle 3) — resolution, audio device, fps — are **hardcoded** in `start_recording` (`-k auto -f 60 -fm cfr`) with no override path. Making them settable requires either new flags on this script or a `Prefs`-read at its top. Plan a script change, not just a row. |
| `fastfetch-logo-picker.sh` | **No arguments at all** (no `"$@"`, no `$1`). Interactive fzf-in-kitty; `fastfetch-logo-switch.sh` is a 9-line `uwsm app -- kitty … -- <picker>` launcher. | ❌ **none** — but state is readable | `~/.local/state/theme/fastfetch-logo` = `star` | **Design problem — named.** Reading current state is trivial (a one-word `FileView`, `BarEntryModel.qml:46-52`'s exact idiom). *Setting* it inline is not: the picker also regenerates a sprite GIF on selection (`python3 "$SPRITES_PY" "$SELECTED"`, ~250 ms) and writes the state file atomically. F-06 as an inline `SelectRow` needs a **non-interactive `--set <name>` path added to `fastfetch-logo-picker.sh`** (validated against the enumerated list, `SPRITE_NAMES=(pulse sweep glitch scan assemble orbit)` + `ASCII_NAMES=(arch star cyberpunk_mask illuminati)` + `random` + `none`, `:39-40,:205`). Otherwise F-06 is a `NavRow` that launches `fastfetch-logo-switch.sh`, which is what the walker row already does. |

**Rows that cannot read their own current state:** `record-toggle.sh` (no status verb — needs the
`pgrep` probe replicated in QML or a new `status` verb added) and `fastfetch-logo-picker.sh` (state
file is readable, but there is no non-interactive setter, so a `SelectRow` would be write-only).
Both are script changes, and both should be explicit plan tasks rather than assumed-away.

**Reminder from 260820-sqd deviation 7 (the one genuinely security-relevant auto-fix):** every one of
these launches must be a fixed-argv `Process.command` array. No `bash -c` string concatenation, ever
— device-supplied names (`hyprctl monitors -j .name`, `hyprctl devices -j .name`) are not this repo's
own text.

---

## 5. Per-device input (F-03)

### 5.1 The real device list on this host

`[MEASURED: hyprctl devices -j, 2026-08-21]` — 7 keyboards, 6 mice, 0 touch, 0 tablets, 0 switches.

**Keyboards** (all report `layout:"us"`, `rules:""`, `model:""` — only `main` differs):

| # | `name` | `main` |
|---|---|---|
| 1 | `corsair-corsair-k70-rgb-tkl-champion-series-mechanical-gaming-keyboard` | **true** |
| 2 | `instant-usb-gaming-mouse--keyboard` | false |
| 3 | `sinowealth-2.4g-wireless-receiver-keyboard` | false |
| 4 | `logitech-pro-x-consumer-control` | false |
| 5 | `logitech-pro-x` | false |
| 6 | `power-button` | false |
| 7 | `power-button-1` | false |

**Mice** (all `defaultSpeed: 0.00000`):

`corsair-…-keyboard-1`, `corsair-…-keyboard-mouse`, `holtek-usb-hid-device`,
`instant-usb-gaming-mouse-`, `instant-usb-gaming-mouse--keyboard-1`, `sinowealth-2.4g-wireless-receiver`

### 5.2 The filter rule — measurable, from udev, not from a name blocklist

`hyprctl devices -j` alone carries **no field** that separates a real typing keyboard from a phantom:
`rules`, `model`, `variant`, `options` are empty on all seven; `layout` is `us` on all seven; only
`main` differs, and it is true for exactly one. A pure-hyprctl filter can therefore only be a
hand-maintained name blocklist — brittle, and it would break the moment the operator plugs in a new
device.

udev has the answer, readable as a normal user:

`[MEASURED: udevadm info -q property -p /sys/class/input/event* | grep ID_INPUT_*, 2026-08-21]`

```
event0   Power Button                                       ID_INPUT_KEY=1
event1   Power Button                                       ID_INPUT_KEY=1
event2   INSTANT USB GAMING MOUSE                           ID_INPUT_MOUSE=1
event3   INSTANT USB GAMING MOUSE  Keyboard                 ID_INPUT_KEY=1 ID_INPUT_KEYBOARD=1
event4   Corsair CORSAIR K70 ... Mechanical Gaming Keyboard ID_INPUT_KEY=1 ID_INPUT_KEYBOARD=1
event5   Corsair CORSAIR K70 ... Keyboard Mouse             ID_INPUT_MOUSE=1
event6   SINOWEALTH 2.4G Wireless Receiver                  ID_INPUT_MOUSE=1
event7   SINOWEALTH 2.4G Wireless Receiver Keyboard         ID_INPUT_KEY=1 ID_INPUT_KEYBOARD=1
event8   Logitech PRO X Consumer Control                    ID_INPUT_KEY=1
event9   Logitech PRO X                                     ID_INPUT_KEY=1
event10  HOLTEK USB-HID Device                              ID_INPUT_MOUSE=1
```

`ID_INPUT_KEYBOARD=1` yields **exactly 3** keyboards — the Corsair K70, the INSTANT mouse's keyboard
endpoint, the SINOWEALTH receiver's keyboard endpoint. Both power buttons and both Logitech PRO X
(headset) nodes are `ID_INPUT_KEY` only and are correctly excluded. `ID_INPUT_MOUSE=1` yields
**4** pointers, dropping the two `-1`-suffixed keyboard-node aliases from hyprctl's list of 6.

Hyprland's name is a deterministic transform of the udev name: lowercase, each space → `-`
(`"INSTANT USB GAMING MOUSE  Keyboard"` → `instant-usb-gaming-mouse--keyboard`, double hyphen from the
double space). The join is exact on all 11 devices above. `[MEASURED]`

**Recommended rule (two tiers, so the row list is honest at both levels):**

1. **Default (what the page shows):** for keyboards, `main == true` — **one** row, the Corsair K70.
   This is the device Hyprland itself designates as primary and the only one where a layout change is
   what the operator means. For mice, the `ID_INPUT_MOUSE=1` set, minus any name that is another
   device's name with a `-1` suffix (the alias pattern) — on this host that is 4, and of those the
   two the operator actually uses are `instant-usb-gaming-mouse-` and `sinowealth-2.4g-wireless-receiver`.
2. **"Show all devices" toggle** (a `ToggleRow` on the Input page): reveals the full
   `ID_INPUT_KEYBOARD`/`ID_INPUT_MOUSE` sets. Never reveals the `ID_INPUT_KEY`-only nodes (power
   buttons, headset consumer-control) — those cannot receive a keyboard layout meaningfully and
   putting them in the list is what made F-03 look unshippable last time.

The udev read is a fixed-argv `Process.command` (`["udevadm","info","-q","property","-p",<path>]`) or,
cheaper, a small helper in `hypr-overrides.sh` that emits a filtered JSON device list — which also
keeps the name→device validation on the script side, where the closed allowlist already lives.

### 5.3 What `hl.device` can and cannot do — MEASURED

`[MEASURED: hyprctl eval, error-message introspection of the bridge]`

The full `hl` bridge surface on Hyprland 0.56.2 (obtained by `error()`-ing out a `pairs(hl)` walk,
since `hyprctl eval` prints `ok` rather than the returned value):

```
animation, bind, clear_crashed_lockscreen, config, curve, define_submap, device, dispatch, dsp,
env, exec_cmd, exec_scheduled_prop_refresh_immediately, gesture, get_active_monitor,
get_active_special_workspace, get_active_window, get_active_workspace, get_config,
get_current_submap, get_cursor_pos, get_last_window, get_last_workspace, get_layers,
get_loaded_plugins, get_monitor, get_monitor_at, get_monitor_at_cursor, get_monitors,
get_urgent_window, get_window, get_windows, get_workspace, get_workspace_windows, get_workspaces,
is_key_down, layer_rule, layout, monitor, notification, on, permission, plugin, timer, unbind,
version, window_rule, workspace_rule
```

`hl.device` exists and self-documents its contract: `hl.device({})` →
`hl.device: 'name' field is required and must be a string`. `hl.get_config` also exists and is worth
knowing about, though `hyprctl getoption -j` remains the read-back oracle the script contract names.

**Per-device keyboard layout — WORKS, with a read-back oracle:**

```
BEFORE: {"layout":"us","active_keymap":"English (US)"}
$ hyprctl eval 'return hl.device({ name = "sinowealth-2.4g-wireless-receiver-keyboard", kb_layout = "de" })'  -> ok
AFTER : {"layout":"de","active_keymap":"German"}
$ hyprctl eval 'return hl.device({ name = "sinowealth-2.4g-wireless-receiver-keyboard", kb_layout = "us" })'  -> ok
RESTOR: {"layout":"us","active_keymap":"English (US)"}
MAIN KB unchanged: {"name":"corsair-...-keyboard","layout":"us","active_keymap":"English (US)"}
```

Verify path: `hyprctl devices -j | jq -e --arg n <name> '.keyboards[]|select(.name==$n)|.layout == $l'`.
Note the change is genuinely per-device — the main keyboard was unaffected.

**Per-device mouse — PARTIAL:**

```
BEFORE: {"name":"instant-usb-gaming-mouse-","defaultSpeed":0.00000,"scrollFactor":-1.00}
$ hyprctl eval 'return hl.device({ name = "instant-usb-gaming-mouse-", sensitivity = 0.35, natural_scroll = true, scroll_factor = 1.5 })'  -> ok
AFTER : {"name":"instant-usb-gaming-mouse-","defaultSpeed":0.00000,"scrollFactor":1.50}
```

- `scroll_factor` → reflected in `.mice[].scrollFactor`. **Verifiable → shippable.**
  Bounds measured: `scroll_factor = -1.0` is rejected with
  `hl.device: field 'scroll_factor': value -1.00 is less than the minimum of 0.00` — so the validator
  floor is 0.00 and the "-1 = inherit global" sentinel is **not writable back**. A settings row must
  therefore treat "reset to default" as "write the global `input:scroll_factor` value"
  (`getoption input:scroll_factor -j` → `1.000000`), not as "write -1".
- `sensitivity` → `defaultSpeed` stayed `0.00000`. **No read-back field exists anywhere in
  `hyprctl devices -j`, and `hyprctl getoption device:<name>:sensitivity -j` returns `no such option`.
  Under this script's verify contract, per-device sensitivity CANNOT be added.** Keep the existing
  global `input:sensitivity` row (which does verify, via `getoption input:sensitivity -j .float` with
  an `awk` tolerance) and say in the row's subtext that it applies to all pointers.
- `natural_scroll` per device → no field in the mice record at all. **Same verdict: not addable.**
  The global `input:touchpad:natural_scroll` row stays.

**`hyprctl getoption device:<name>:<key> -j` → `no such option`** for both `kb_layout` and
`sensitivity`. `hyprctl devices -j` is the *only* per-device oracle; a `cmd_device` in
`hypr-overrides.sh` must verify against it, not against `getoption`.

### 5.4 Persistence for per-device settings

`lib/overrides.lua`'s normaliser would need an `overrides.devices` map keyed by device name, and
`hyprland.lua` would need a loop emitting one `hl.device({...})` per entry. Two cautions:

- Device names are **device-supplied** (T-SQD-04). The existing monitor path already applies a strict
  `^[A-Za-z0-9._-]+$` character allowlist *plus* a membership-in-live-set check before the name
  reaches a Lua string. Per-device names on this host contain only `[a-z0-9.-]` — the same allowlist
  works — but a device that is **absent at boot** must be tolerated (`hl.device` on an unknown name
  should be pcall-guarded or skipped, or an unplugged keyboard blocks compositor start).
- `hyprctl devices -j`'s membership check must happen at *write* time (device present) and be
  tolerated as absent at *boot* time. These are different rules; do not collapse them.

---

## 6. Pitfalls specific to THIS work

### 6.1 `colour-lint` cannot see default-styled QQC2 popups — the exact requirement for a new control

`colour-lint`'s own checks (header lines 14-52) `[MEASURED]`:

- **CHECK A** — every `Colours.<name>` reference must resolve against names parsed from `Colours.qml`.
- **CHECK B** — no hard-coded colour at a colour-assignment **anchor**, four shapes: B1 a
  `color:`-family assignment with a quoted hex RHS; B2 a `property color <n>:` with a quoted hex RHS;
  B3 `Qt.rgba(`/`hsla(`/`hsva(` with three numeric-literal args; B4 any B1/B2 anchor with a quoted
  string that is neither `#`-hex nor exactly `"transparent"`.
- **CHECK C** — scanned-count floor > 0.
- Deny-by-default: "every `.qml` file under the quickshell config tree is scanned; there is no
  per-file opt-in registry" — **new files are covered automatically.**

**The blind spot, stated precisely by the code that hit it** (`SelectRow.qml:195-206`) `[MEASURED]`:

> "read Qt's own installed Basic-style `Menu.qml`/`MenuItem.qml` directly. Both `Menu.background`
> (`color: control.palette.window`) and `MenuItem.background` (`color: control.down ?
> control.palette.midlight : control.highlighted ? control.palette.light : "transparent"`) use the
> QQC2 **SYSTEM PALETTE** — zero literals in this repo's own QML, which is exactly why colour-lint
> (which greps only OUR files) never caught it."

So the gate is not merely weak here — it is *structurally* unable to see the defect: the offending
colour lives in Qt's installed style, not in a file colour-lint scans. **A green colour-lint run is
not evidence that a new QQC2 control is themed.**

**Concrete mitigation — what a new `SelectRow`/`Menu`/`ComboBox`/`TextField` MUST do.** The already-fixed
`SelectRow.qml:229-302` is the reference implementation; copy its four moves:

1. **Override `Menu.background`** with an explicit `Rectangle { color: Colours.surfaceVariant;
   border.width: 1; border.color: Colours.outline; radius: 12 }` (`:234-240`). Never inherit.
2. **Override every `MenuItem.contentItem`** with a `Text { color: Colours.onSurfaceVariant }`
   (`:253-255`) — the default delegate's text colour also comes from the system palette.
3. **Override every `MenuItem.background`** with an explicit `Rectangle` whose highlight is a
   `border.color: menuItem.highlighted ? Colours.primary : "transparent"` **ring**, not a fill
   (`:297-301`). The fill-based version was invisible: it painted `surfaceVariant` on a
   `surfaceVariant` pane. `"transparent"` is explicitly in-contract for CHECK B4.
4. **Pin `implicitWidth: optionsMenu.implicitWidth` on every item** (`:250`) — the default derives it
   from per-item text metrics, so the hit region visibly jumps between differently-lengthed labels.

And the standing verification rule that goes with it, from 260820-sqd headline lesson (b):
**verify by pixel-sampling a `grim -g <region>` capture of the settings toplevel, never by reading
role names.** Four controls shipped `surfaceVariant`-on-`surfaceVariant` with entirely correct-looking
role names. Region capture of this toplevel is proven safe on this host (13+ captures); full-screen
`grim` is NOT — it SIGSEGVs the compositor into safe mode.

**Should the gate be widened?** Worth proposing as a bounded addition: a CHECK D that FAILs any
`Menu {`/`ComboBox {`/`TextField {`/`Popup {` block in a scanned file that does not declare its own
`background:` override. That is a structural, greppable invariant (the same shape CHECK B already
uses — anchor first, then assert), and it converts a documented blind spot into a gate. Note the
gate-authoring trap from project memory: a banned-identifier gate that greps its own prose fails
against clean code — strip `//` comment lines before matching, or `SelectRow.qml`'s own 30-line
explanatory comment about `Menu.background` will trip it.

### 6.2 The restart-then-edit deployment trap

From 260820-sqd headline lesson (e) `[MEASURED, quoted]`:

> "a settings PAGE can keep serving a stale compiled `Component` across a plain hot-reload
> (`PageCompRegistry`'s per-page indirection), so verifying or re-checking a page-level fix needs a
> full `systemctl --user restart quickshell.service`, not just a re-navigate."

And project memory `toplevel-screenshots-and-stale-pages`: "restart quickshell AFTER the last edit or
incubated pages serve stale QML."

**Concrete mitigation, as a hard rule for every verification step in the plan:**

```
edit → commit → systemctl --user restart quickshell.service → wait for the shell → open Super+comma
→ navigate to the page → capture/verify
```

Never restart first and edit after. Never accept a hot-reload as proof for anything under
`modules/settings/pages/`. When a verification round produces a surprising *pass*, re-run it — project
memory `live-probe-flaky-after-hot-reload` records quickshell-doctor reading 25/3 then 28/0 across two
runs after a QML edit.

Two adjacent deployment facts `[MEASURED: ls -l ~/.config/quickshell]`:

```
modules   -> ../../dotfiles/quickshell/.config/quickshell/modules   (symlinked DIRECTORY)
shell.qml -> ../../dotfiles/quickshell/.config/quickshell/shell.qml (symlinked FILE)
```

A new file **under `modules/`** is deployed the instant it is written — no `stow.sh` re-run needed,
and both `colour-lint` and `motion-lint` (which scan `$HOME/.config/quickshell`) pick it up
immediately. A new **top-level** file in `quickshell/.config/quickshell/` would need stow, and would
also need a `stow-link-check` update.

### 6.3 What the gates will check against this code, and which need updating

`[MEASURED: baseline runs, 2026-08-21]`

| Gate | Baseline today | Covers new files automatically? | What it will check | Needs updating? |
|---|---|---|---|---|
| `colour-lint` | **182 passed, 0 failed** | ✅ deny-by-default over `$HOME/.config/quickshell/**/*.qml` | CHECK A: every `Colours.<name>` resolves. CHECK B1-B4: no hex/named-colour literal at a colour anchor. | **Not required**, but see §6.1's proposed CHECK D. Note `"transparent"` is in-contract; a `Qt.rgba(base.r,base.g,base.b,0.5)` token+opacity form is in-contract; three numeric literals is a FAIL. |
| `motion-lint` | **333 passed, 0 failed** | ✅ deny-by-default over the same tree *plus* `.lua`/`.conf` under the hypr tree — including `~/.config/hypr/state/overrides.lua` (it appears in the baseline output) | CHECK A: every motion-token reference resolves. CHECK B: **no raw duration/control-point literals.** | **Not required.** But it means every animation on a new row/page must use a `Motion.*` token. `Pages.qml:141-176` records the reasoning trail for picking `standardDuration` over `emphasizedOut`/`staggerOffset` — reuse that judgement, do not hardcode. ⚠ It scans `overrides.lua` too: a *numeric* compositor value persisted there (gaps=5, rounding=12) must not read as a duration literal — check this early. |
| `quickshell-doctor --self-test` | **59 passed, 0 failed** | It is a coexistence/behaviour gate, not a QML content linter | Shell root alive; exactly ONE surface (the bar) reserves screen space, every other reserves zero; `quickshell-*` namespaces; single-handler-per-event-source. No `settings`-specific check exists today (`grep -i settings quickshell-doctor` → 0 hits). | **Should be extended** — this is the natural home for the §3.3 RowIndex-completeness check and for a "the settings toplevel reserves zero space" assertion. |
| `hypr-equivalence-check` | **PASS: 3  FAIL: 0** | Compares live `hyprctl getoption` against the frozen `.hypr-baseline/` snapshot | Every option key's value vs baseline, except `VOLATILE_KEYS` (reported, never asserted) and `THEME_DRIVEN_KEYS` (presence only). | **YES — mandatory.** Every new operator-adjustable compositor key must be added to `VOLATILE_KEYS` (currently the 4 `input:*` keys at `:438-443`) or the gate FAILs the first time the operator changes it. |
| `keybind-doctor` | 14/0 at last task's close | Contract file is `quickshell/.config/quickshell/shortcuts.json` | Only if this task adds a keybind. | Only if a new bind is added. |
| `stow-link-check` | 6/6 at last task's close | — | Only if a new stow-managed file/dir is added outside the already-symlinked `modules/`. | Only if `stow.sh` gains a seed block (e.g. if `prefs.json` is seeded rather than allowed to be absent-on-first-run — **recommend NOT seeding**, following `notifications.json`'s absent-is-normal precedent). |

### 6.4 Other traps carried into this work

- **`hyprctl keyword` is a silent no-op** under the Lua parser — exits 0, changes nothing. Every
  compositor write is `hyprctl eval`. (`hypr-overrides.sh:19-22`.) `[MEASURED, prior task]`
- **`hyprctl reload` drops layer-rule changes.** `windowrules.lua:433-450`: "`hyprctl eval '<rule>'`
  → frost appears immediately; `hyprctl reload` → frost disappears again … no error, no warning,
  `hyprctl configerrors` clean." Any "does it survive a reload?" verification round pays this cost.
  I deliberately did not run `hyprctl reload` during this research. `[MEASURED, prior task, re-read]`
- **Declare QML members before construction-time use.** `SettingsState.qml:22-30` and `Pages.qml:115-118`
  both restate it: a later-declared member throws "is not a function" and a fallback chain converts
  that into a plausible wrong answer. `Prefs.qml`'s helper functions must be declared **above** its
  `FileView` and above `Component.onCompleted`. `NewsBackend.qml:85-88,1063` enforces the same
  ordering with an explicit "do not tidy this" header. `[MEASURED]`
- **A child's binding lags the parent's signal.** Inside `onXChanged` the child still sees the OLD
  value; `Pages.qml:1-8` sequences the page swap through a `ScriptAction` for exactly this reason,
  and `NewsBackend.qml:1616-1622` wraps a post-load read in `Qt.callLater`. Any `Prefs`-consumer that
  reacts to a load must `Qt.callLater` or read from `onLoaded`, never from an `onChanged` on a
  sibling. `[MEASURED]`
- **`PageRegistry` ↔ `PageCompRegistry` index lock.** Splitting 4 pages into 8 touches both lists in
  the same commit. "A mismatch renders the wrong page with no error." Consider adding a
  `Component.onCompleted` length assertion in `PageCompRegistry.qml` as cheap insurance —
  `comps.length === PageRegistry.pages.length`, `console.warn` on mismatch. `[MEASURED]`
- **Deep-link keys must keep resolving.** `PageRegistry.qml:8-10`: `category` "is the deep-link key
  `shell.qml`'s `openSettingsPage(name)` resolves against — never renamed without also updating every
  caller." After the split, `appearance`/`connectivity`/`display`/`shell` must each still resolve to
  *some* page. If a category now spans several pages, the resolver needs a documented
  first-match-wins rule and an explicit test. `[MEASURED]`
- **QQC2 `contentItem` anchoring.** `SelectRow.qml:1-9`: never anchor a `Control`'s `contentItem`
  against the Control's own geometry — it shrinks the background below the content. Use the Control's
  padding. Applies to every new `Control`-derived row. `[MEASURED]`
- **No synthetic mouse click exists on this host.** 260820-sqd's recorded tooling gap: `wtype` is
  keyboard-only, and `hl.dsp.cursor.move` does not drive focus (measured 3×). Every click-driven path
  in this task — search-result clicks, new dropdowns, new toggles — can only be verified by the
  operator. Plan for operator checkpoints on those specifically, and instrument rather than guess when
  an agent trial passes while the operator fails.

---

## Project Constraints (from CLAUDE.md)

- **GSD workflow enforcement** — no direct repo edits outside a GSD workflow.
- **Build any new bar/shell widget as QML under the existing module tree**, coloured through
  `Colours.qml` and animated through `Motion.qml`; never introduce a second toolkit for one widget.
- **`colour-lint` rejects hardcoded colours in QML** — read palette values from `Colours.qml`.
- **Reproducibility** — everything installable from a fresh Arch system via `install.sh` + stow; no
  manual host-only state. A new `prefs.json` must therefore degrade gracefully when absent (see §1.4),
  not require a seeding step to work.
- **Theme switching must keep supporting both static preset and matugen dynamic modes through one
  pipeline** — this is the constraint that rules out the border-colour override in §2.6.
- **MEASURE-FIRST standing rule** (project memory, outranks everything): never guess or theorize; read
  the spec/code and quote it before asserting anything or writing any line.

---

## Assumptions Log

| # | Claim | Section | Risk if wrong |
|---|---|---|---|
| A1 | `binds:allow_workspace_cycles` and `general:gaps_workspaces` accept `hyprctl eval` writes | §2.3 | Both were confirmed to *exist* as options with a read-back field, but I did not apply-and-restore them. Probe before adding to the allowlist; if a write silently no-ops, the verify step catches it — the risk is wasted plan scope, not a broken session. |
| A2 | The udev name → Hyprland name transform (lowercase, space→`-`) holds for devices beyond the 11 on this host | §5.2 | An exotic device name (unicode, punctuation) could break the join, dropping a real device from the list. Mitigation: fall back to showing an unmatched hyprctl device rather than hiding it. |
| A3 | `~/.local/state/quickshell/prefs.json` needs no `stow.sh` seed block | §1.4 | Follows `notifications.json`'s precedent (absent-on-first-run is the expected state, handled by `onLoadFailed`). If a seed is added instead, `stow-link-check` needs updating. |
| A4 | Caelestia's `searchOpen` remains unconsumed | §3.2 | Fetched from `main` on 2026-08-21; upstream could land a search implementation later. Low risk — the recommendation stands on this repo's own lazy-incubation constraint regardless. |

---

## Open Questions (RESOLVED — see PLAN.md decision_ids PD-03, PD-04, PD-05)

1. **Which page does a multi-page `category` deep-link resolve to?**
   - Known: `shell.qml`'s `openSettingsPage(name)` matches on `category`; four keys must keep working.
   - Unclear: after the split, `appearance` will match at least Appearance / Wallpaper / Bar.
   - Recommendation: first-match-wins by index, documented in `PageRegistry.qml`'s header, plus a
     one-line assertion that each of the four legacy keys still matches at least one page.

2. **Where should the bar's "which capsules show" prefs be consumed?**
   - `BarEntryModel.qml` and `BarRoles.qml` already exist as the bar's own model layer; a `Prefs`
     read belongs there, not in each capsule. Not investigated in depth — out of this research's
     stated scope, flagged for the planner to open before writing bundle 2's tasks.

3. **Does the `record-toggle.sh` defaults work belong in this task at all?**
   - Making fps/audio-device/resolution settable is a script redesign (§4), not a row. It is inside
     CONTEXT's bundle 3 ("screen-recording defaults"), so it is in scope — but it is the single
     largest hidden cost in the bundle. Recommend the plan size it explicitly rather than folding it
     into "wiring existing scripts to rows".

---

## Sources

### Primary (HIGH confidence — live measurement on this host, 2026-08-21)

- `hyprctl getoption <key> -j` × 47 keys; `hyprctl eval` apply-and-restore × 11 knobs;
  `hyprctl devices -j`; `hyprctl eval` bridge introspection via forced `error()`;
  `hyprctl version` (0.56.2, commit efb50993).
- `udevadm info -q property -p /sys/class/input/event*` × 23 nodes.
- Live invocation of `gaming-mode-toggle.sh status`, `bar-visibility.sh status`,
  `wallpaper-visibility.sh status`, `pgrep -f '^gpu-screen-recorder '`.
- Gate baselines: `colour-lint` 182/0, `motion-lint` 333/0, `quickshell-doctor --self-test` 59/0,
  `hypr-equivalence-check` PASS 3/FAIL 0.
- File reads: `hypr-overrides.sh` (full), `hyprland.lua`, `lib/overrides.lua`, `config/animations.lua`,
  `config/windowrules.lua:425-470`, `theme-engine/lib/reload.sh` (grep), `NotifServer.qml`,
  `WeatherBackend.qml`, `NewsBackend.qml`, `Motion.qml`, `ToggleState.qml`, `Design.qml` (grep),
  `modules/qmldir`, `modules/settings/*` (all), `modules/settings/common/SelectRow.qml`,
  `colour-lint`/`motion-lint`/`quickshell-doctor`/`hypr-equivalence-check` headers.
- `ls -l ~/.config/quickshell`, `ls -la ~/.local/state/{quickshell,theme,hypr}`.

### Secondary (MEDIUM confidence — upstream fetch, main branch, 2026-08-21)

- `raw.githubusercontent.com/caelestia-dots/shell/main/modules/nexus/{NavPane,NexusState,Pages,Nexus,PageRegistry}.qml`
  and `navpane/NavLocations.qml`; `api.github.com/repos/caelestia-dots/shell/git/trees/main?recursive=1`
  (77-entry `modules/nexus` listing).

### Prior-artifact evidence

- `.planning/quick/260820-sqd-.../260820-sqd-SUMMARY.md` (Post-Plan Live-Pass Saga, deviations 5-7,
  headline lessons a-e).
- `.planning/quick/260820-sqd-.../260820-sqd-RESEARCH.md` (lines 48, 52, 273, 338 — the
  `hyprctl reload` wipes-eval finding and the Caelestia decomposition).

---

## Metadata

**Confidence breakdown:**
- Prefs idiom: **HIGH** — three in-repo writing stores read directly, all agreeing on one shape.
- Compositor allowlist: **HIGH** for the 9 apply-and-restore knobs and the 5 `no such option` negatives;
  **MEDIUM** (A1) for the 2 workspace knobs verified only on the read side.
- Search shape: **HIGH** on the impossibility (Pages.qml read directly); **MEDIUM** on the Caelestia
  negative (upstream main-branch snapshot).
- Script CLI surfaces: **HIGH** — every `main()` read and every status verb run live.
- Per-device input: **HIGH** — kb_layout and scroll_factor applied and read back; sensitivity's
  absence of a read-back confirmed two ways (`devices -j` field absent, `getoption device:…` →
  `no such option`).
- Gates: **HIGH** — all four baselines run today.

**Research date:** 2026-08-21
**Valid until:** ~2026-09-20 (Hyprland option names can move across releases; re-probe the
`getoption` table if `hyprctl version` changes from 0.56.2).
