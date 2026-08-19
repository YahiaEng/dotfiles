---
quick_id: 260819-6oy
date: 2026-08-19
mode: quick
status: complete
one_liner: news tab added to the notification centre — hand-editable RSS/Atom feeds via a hand-rolled XML DOM walker (XmlListModel and getElementsByTagName both measured unusable), two-tab header with the surface geometry byte-identical, no confirm dialog needed on links because the parse-time https-only filter already guarantees it
---

# Quick Task 260819-6oy — Summary

## What shipped

All four tasks landed, in the load-bearing order the plan specified:

1. **`news-sources.json`/`news-cache.json` registered in `contract.json`'s
   `engine_owned_files`**, and `stow.sh` seeds three default feeds (BBC World,
   NPR, LWN) idempotently. Proven the state-manifest gate can fail (a decoy
   file was named by `theme-doctor`) before trusting it to pass.
2. **`NewsBackend.qml`** — one `Scope`, mounted in `shell.qml` as a sibling of
   `WeatherBackend`, gated on `NotifServer.centreOpen`. Fetches via
   `XMLHttpRequest` + `responseXML`, walking `childNodes` by hand for both RSS
   and Atom — `XmlListModel` and the by-tag-name DOM lookup are both measured
   unusable on this Qt6 build (see `.planning/notes/news-tab-feed-parsing.md`),
   so neither exists anywhere in this file. A two-point `https://` scheme
   allowlist (source validation + item acceptance) replaces the single-
   literal-host fence `WeatherBackend`/`GeocodeBackend` use, since the host
   list here is operator-editable JSON, not a QML literal — the widening is
   recorded in the file's own header, same discipline 260818-v3m used for its
   own correction.
3. **`NewsPane.qml`** — the source-filter chip (inline expand, not a QQC2
   popup control — none exist anywhere under `quickshell/`, so one working
   inside a Wayland layer surface is unproven), the headline list
   (`Qt.openUrlExternally`, no confirm dialog, safe because the parser's own
   acceptance filter already guarantees `https://`), and six render states
   computed from one `paneState` expression.
4. **`NotifCentre.qml`** — the header band's count capsule became a two-tab
   `TabBar` (Notifications / News); `historyRegion` became page 0 and
   `NewsPane` page 1 of a `SwipeView`, copying `Dashboard.qml`'s TabBar/
   SwipeView one-way-sync idiom verbatim. **The surface geometry guarantee
   holds** — the plan's own mechanical grep (margins/exclusiveZone/
   exclusionMode/insets/notifSurfaceWidth/popoutHeaderHeight, comment lines
   stripped) prints **0** changed lines, and `Design.qml` is untouched.

## Two live-measured bugs fixed before commit (Task 2)

**A child-binding race, from the parent-reads-child direction.** `sources`
was originally republished imperatively from `sourcesFile.onLoaded` via
`root.sources = root._validSources()`. Live on this host that raced: the
child `JsonAdapter`'s own properties hadn't settled yet at the instant
`onLoaded` fired, so `_validSources()` read the still-default `[]`. Converted
`sources` to a readonly **computed** property instead — it re-derives
automatically from `newsState.sources` with no race window at all, rather
than depending on handler-ordering.

**`JsonAdapter`'s `var` array properties don't deserialize into native JS
Arrays on this Qt build.** Measured live: `Array.isArray(newsState.sources)`
read `false` against a genuinely well-formed three-entry array that
`JSON.stringify()` rendered correctly and that indexed/`.length`'d exactly
like a real array. `Motion.qml`'s own `semantic: var` precedent never hit
this, because that property holds an object, not an array. `_validSources()`
now duck-types on `.length` instead of `Array.isArray()`.

Both fixes are recorded in the file's own comments, citing this quick task,
so a future reader finds the reasoning rather than a gap.

## A missed import (Task 4) — caught, but only after a config-load failure

`NotifCentre.qml` never imported `QtQuick.Controls`, so `TabBar`/`TabButton`/
`SwipeView` failed to resolve (`TabBar is not a type`) and the whole shell
config failed to load. Added the import; `qmllint` and a subsequent
"Configuration Loaded" log line confirmed the fix. This is the ordinary
"caught before shipping" case the plan's own deviation-rule discipline
expects — noted here only because of what happened next.

## An incident during live verification — full disclosure

A `grim` screenshot taken afterward, to visually confirm the tab bar's
render, triggered a **pre-existing Hyprland compositor bug**: SIGSEGV inside
`Screenshare::CScreenshareSession::init()`, reached via
`CToplevelExportClient::captureToplevel(...)` — the toplevel-export/
screencopy path `grim` and this repo's own Overview feature both use. The
crash report (`~/.cache/hyprland/hyprlandCrashReport2186.txt`) names an
NVIDIA GeForce RTX 3070 GPU and the `dynamic-cursors` plugin; Hyprland's own
report header states plugin crashes "might not be Hyprland's fault." This is
**unrelated to the QML changes in this task** — the backtrace has nothing to
do with QML type resolution, layer-shell geometry, or anything this plan
touched.

**Consequence:** Hyprland's own watchdog relaunched it in `--safe-mode`
(no config loaded, a synthetic `FALLBACK` monitor, a "your last session
crashed" dialog on screen), which ended the operator's entire prior desktop
session — everything that had been running for the past ~13 hours (browser,
terminals, editors) is gone. `quickshell.service` auto-restarted alongside
it (systemd `Restart=`, counter now 1) and reconnected to the safe-mode
compositor; **this task's own QML reloaded cleanly the moment quickshell
respawned** — the code is verified correct, but there is currently no real
monitor/config for it to render onto.

**What I did NOT do, deliberately:** I did not attempt to dispatch `exit` or
otherwise force-restart Hyprland to recover automatically. `wayland-wm@
hyprland.desktop.service` shows `Restart=no` and its tracked PID is the
`uwsm` wrapper, not the crashed-and-respawned Hyprland binary itself — I
could not confirm whether a clean exit would relaunch normally or end the
graphical session outright with no console access to recover from that. Per
Rule 4 (architectural/consequential decisions), this is a STOP-and-surface
situation, not one to keep experimenting on.

**Recovery (for the operator, one click):** the Safe Mode dialog already on
screen has a **"Load config"** button — clicking it loads this repo's real,
now-fixed config into the *same* running Hyprland process, no restart
needed. (The dialog's alternative path — "Restarting Hyprland will launch in
normal mode again" — is the fallback if "Load config" doesn't fully recover
bar/centre state.)

**Not completed as a result:** the plan's screen-dependent live checks —
Escape-to-close on both tabs, and the 100-notification tab-width check —
could not be performed this session. Every other verification step in the
plan (qmllint, the geometry diff gate, colour-lint, motion-lint,
theme-parity, stow-link-check, and Task 2/3's own live NewsBackend
verification, all completed *before* the crash) passed. Recommend the
operator re-run the plan's own "Human verification" checklist once the
session is restored — no code changes are expected to be needed; this is a
verification gap, not a known defect.

**No further screenshots were taken after the crash was diagnosed.** All
subsequent checks in this session used file-based/log-based verification
only (`qmllint`, `hyprctl layers -j` read-only, `~/.cache/quickshell.log`
tailing).

## Gates

`qmllint` exit 0 on all three new/changed `.qml` files · geometry diff gate
**0** · `Design.qml` untouched · `colour-lint` 150/0 · `motion-lint` 297/0 ·
`theme-parity` 1721/1721 · `stow-link-check` 2/0 · `theme-doctor` clean
except the pre-commit `git status --porcelain` check (expected mid-task,
resolves once the docs commit lands) — the `hyprctl`-dependent theme-doctor
checks (bind/animation/option equivalence, walker-process) currently read
`FAIL` too, but only because of the safe-mode incident above, not this
task's diff; they read clean immediately before it.

## Files

- `theme-engine/.config/theme-engine/contract.json` — `news-sources.json`/
  `news-cache.json` registered in `engine_owned_files`
- `stow.sh` — idempotent `news-sources.json` seed, three https-only defaults
- `quickshell/.config/quickshell/modules/dashboard/NewsBackend.qml` (new) —
  fetch/parse/merge/cache
- `quickshell/.config/quickshell/modules/dashboard/qmldir` — `NewsBackend`
  registered
- `quickshell/.config/quickshell/shell.qml` — `NewsBackend`/`newsBackend`
  seams mounted and threaded
- `quickshell/.config/quickshell/modules/centre/NewsPane.qml` (new) —
  dropdown, list, six states
- `quickshell/.config/quickshell/modules/centre/qmldir` — `NewsPane`
  registered
- `quickshell/.config/quickshell/modules/centre/NotifCentre.qml` — two-tab
  header, pager, `QtQuick.Controls` import added

## Commits

- `c11b766` — Task 1: contract registration + seed
- `09e5a08` — Task 2: `NewsBackend.qml`
- `7e35f39` — Task 3: `NewsPane.qml`
- `c2836fe` — Task 4: `NotifCentre.qml` restructure + import fix

## Known Stubs

None — every render path (populated/filtered-empty/pending/error/
unconfigured/empty) has real content, and the source list, cache, and gates
are all live-verified working end to end (Task 2's own live verification,
before the incident: 40 items across all three sources, sorted, all
`https://`, cache written, stale-while-revalidate confirmed, zero network
while closed confirmed).

## Out of scope (per the plan, unchanged)

In-shell source editor, article bodies/reader view, any refresh timer beyond
the manual button, read/unread state, JSON Feed support, gate-script edits.

## Self-Check: PASSED

All 9 files created/modified confirmed present on disk; all 4 task commits confirmed in `git log`.
