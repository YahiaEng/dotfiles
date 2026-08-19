---
title: News tab — measured feed-parsing constraints and design decisions
date: 2026-08-19
context: Pre-planning exploration for the news-tab quick task (third of three operator-requested features)
status: input to /gsd-quick
---

# News tab — feed parsing constraints & design decisions

All findings below were **measured on this host**, not inferred from docs.
Build under test: `quickshell 0.3.0-2`, `qt6-declarative 6.11.1-3`, `qt6-base 6.11.1-1`.

## 1. Probe method (read this before re-measuring anything)

`qml6` on this host **swallows every logging channel**: `print()`, `console.log()`,
`console.warn()` all produce nothing on stdout *or* stderr, with or without
`QT_LOGGING_RULES='*=true'` (no `qtlogging.ini` exists, no QT_* env set).
`Component.onCompleted` *does* fire — verified with `Qt.exit(42)` returning 42.

**Therefore: exit codes are the only reliable probe channel.** Encode results as
`Qt.exit(base + count)`. An `XMLHttpRequest` PUT to a `file://` URL also silently
fails to write, so it is not a usable reporting fallback.

Corollary trap hit twice during this session: a bail `Timer` around a handler that
throws makes a *code* fault look like a *network* timeout. Always give the catch
block its own distinct exit code and encode which step threw.

## 2. XmlListModel — RULED OUT

`import QtQml.XmlListModel` resolves fine (control: a bogus module exits 2, this
exits 0) and it genuinely parses — it returned all 30 `<item>` elements of the BBC
World feed with roles resolved. It is nonetheless **unusable for this feature**:

| Capability | Qt6 status | Consequence |
|---|---|---|
| `xml` string property | **removed in Qt6** (only `source`, a QUrl) | cannot parse an in-memory string; must load from a URL |
| `get(i)` | **does not exist** | cannot read items from JS at all |
| available methods | only `reload()`, `errorString()` | — |
| available properties | `status`, `progress`, `source`, `query`, `roles`, `count` | — |

Verified against `/usr/lib/qt6/qml/QtQml/XmlListModel/plugins.qmltypes` and by a
live `typeof mm.get !== "function"` probe (exit 6).

Because there is no `get()`, XmlListModel can **only** drive a view delegate. You
could never filter, merge multiple sources, sort by date, or persist items to a
cache file — which would make the repo's established backend idiom
(`WeatherBackend` → `weather-cache.json`) impossible to follow.

## 3. Chosen architecture — XHR + responseXML + manual walk

Measured working end to end:

- `XMLHttpRequest` GET over HTTPS — works (HTTP 200, full body)
- custom `User-Agent` via `setRequestHeader` — works (as `GeocodeBackend` already does)
- `x.responseXML` — non-null, `documentElement` present
- **`getElementsByTagName` is ABSENT** — this was the real thrower in the first DOM
  probe. Walk `childNodes` manually.
- CDATA — handled transparently by concatenating child `nodeValue`s (BBC wraps
  every `<title>` in CDATA and it extracted correctly)
- attributes — `node.attributes[i].nodeValue` works (needed for Atom `<link href>`)

Results: **RSS** (BBC World) → 30/30 items with title + link + pubDate all parsed.
**Atom** (github releases.atom) → 4/4 entries with title + `href` attribute parsed.
One ~20-line walker covers both formats. JSON Feed is trivial via `JSON.parse`.

Feeds confirmed reachable and their content types:
- `https://feeds.bbci.co.uk/news/world/rss.xml` → `text/xml`, rss, 30 items
- `https://feeds.npr.org/1001/rss.xml` → `text/xml`, rss, 10 items
- `https://lwn.net/headlines/newrss` → `application/xml`, rss

Note: remote fetch is **not** broken (an early reading suggested it was — that was
the `get()` exception masked by the bail timer).

## 4. Design decisions

**Tab layout — TabBar in the existing header band.**
`TabBar` + `SwipeView` synced one-way *from* the pager, copying `modules/Dashboard.qml`
(which already does exactly this across four panes). Tabs occupy the header band's
existing height, so **no vertical space is added** and the history region keeps its
full height. The notification count folds into the tab label ("Notifications 3")
rather than keeping a separate capsule.

**CRITICAL:** `NotifCentre` is a layer surface. Per the 260818-nwo lesson, a
top-anchored layer surface is compositor-centred, so any surface resize drags
content sideways and re-buffers every frame. The surface geometry must stay
**identical**; only content inside swaps.

**Source list — seeded, hand-editable JSON.**
`news-sources.json`, engine-owned, read via a watched `FileView` + `JsonAdapter`.
Defaults ship as BBC World, NPR, LWN. Adding a feed = edit the file + stow.
No in-shell editor UI (deferred — see the seed).

**MANDATORY:** register the new file in `theme-engine/contract.json` under
`engine_owned_files`, alongside the existing `weather.json` / `weather-cache.json`
entries. The "seeded but unregistered" bug class has recurred 8 times in this repo.

**Refresh — open-gated with stale-while-revalidate.**
Mirrors `WeatherBackend`'s `drawerOpen` gate (D-32) using `NotifServer.centreOpen`:
zero timers and zero network while the centre is closed. On open, paint cached
headlines from `news-cache.json` immediately, then refetch only if cache age
exceeds a ~15 min TTL. Manual ⟳ button for on-demand refresh. Cache written via
an unwatched `atomicWrites` FileView, same as weather.

## 5. Constraints inherited from the repo

- **One network host per fenced file.** `WeatherBackend`→Open-Meteo,
  `GeocodeBackend`→Nominatim. The feed fetcher owns its hosts in its own file;
  the fence is verified by grep.
- Backends live in `modules/dashboard/`, mounted in `shell.qml` as siblings of
  `dashboardLoader` (D-14).
- `colour-lint` rejects hardcoded colours — read `Colours.qml`.
  `motion-lint` rejects raw durations — read `Motion.qml`.
- Declare QML members **above** any construction-time call site or they throw
  "is not a function".
- A child's binding to a parent property is not updated inside the parent's own
  `onXChanged` — use `Qt.callLater`.
- Guards that return silently make total failure look like a plausible wrong
  answer. Log them.
- quickshell journals nothing; all QML output goes to `~/.cache/quickshell.log`.
- Drive the centre with:
  `hyprctl dispatch 'hl.dsp.global("quickshell:notif-centre")'`
  (`hyprctl dispatch global <name>` FAILS under this repo's Lua config.)
- Gates: quickshell-doctor 28/0, colour-lint 146/0, motion-lint 293/0,
  theme-doctor 586/0, theme-parity 1721/1721, stow-link-check.
  quickshell-doctor probes the LIVE shell and reads flaky for seconds after a
  QML hot reload — re-run before believing a failure.
