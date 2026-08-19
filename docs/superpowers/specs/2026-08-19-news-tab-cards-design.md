# News Tab — Card View, Thumbnails & Tab Glyphs

**Date:** 2026-08-19
**Status:** Design — awaiting review
**Surface:** `quickshell/.config/quickshell/modules/centre/` (NotifCentre, NewsPane) + `modules/dashboard/NewsBackend.qml`
**Predecessor:** quick task 260819-6oy (news tab, shipped 2026-08-19)

---

## What this changes

Three operator-requested changes to the News tab shipped by 260819-6oy:

1. **Glyphs beside the two tabs** in the notification centre's header band.
2. **A compact ⇄ card view toggle** for the article list.
3. **Thumbnails** in card view, Reddit-classic style — image on the **left**.

Plus one source change that fell out of measuring (3): **NPR is dropped**,
replaced by **Ars Technica**, and **Phoronix** is added.

The design reference is Caelestia, as with every other surface in this shell.
Caelestia ships no news pane, so the reference is carried by its in-repo
descendant: `NotifCard.qml`, which already lives in this same surface and
whose idioms this design mirrors rather than reinvents.

---

## Measurements this design rests on

Every number below was measured on this host on 2026-08-19, not assumed.

### Feed image coverage

| Source | Items | Image tag | Dimensions | Weight | Verdict |
|---|---|---|---|---|---|
| BBC World | 15 | `media:thumbnail` | 240×135 | 4.6 KB | ✅ every item |
| LWN | 15 | — | — | — | ❌ none exist |
| NPR *(dropped)* | 10 | inside `content:encoded` HTML | — | — | ⚠️ tracker-first |
| **Ars Technica** *(new)* | 20 | `media:thumbnail` | **500×500 square** | 64 KB | ✅ every item |
| **Phoronix** *(new)* | 32 | — | — | — | ❌ none exist |

**NPR was dropped because its images are unreachable cleanly.** They exist only
inside `<content:encoded>` HTML, and the *first* `<img>` in every item is a
tracking pixel (`npr-rss-pixel.png?story=…`). Rendering it would send a
story-identifying request to NPR analytics on every scroll. Reaching the real
image needs NPR-specific HTML regex in a parser that is otherwise pure DOM.

**Ars Technica was chosen** over The Register (800×553, 92 KB), Hackaday
(1090×673, 143 KB), It's FOSS (1200×675, 213 KB), Engadget (1600×899, 850 KB)
and Tom's Hardware (1280×720, 978 KB) because it is the only candidate shipping
a **purpose-built 500×500 square** thumbnail — exactly what a square slot wants,
no cropping — at a third the weight of the nearest alternative. At 15 items per
refresh: Ars ≈ 1 MB, Tom's Hardware ≈ 14 MB for the identical 76px result.

**Phoronix ships zero images** — verified across all three of its feed
endpoints (`/rss.php`, `/rss.php?type=news`, `/rss/`): no `media:*`, no
`<enclosure>`, no `<img>`, no image URLs anywhere in 21,729 bytes. Its images
live on article pages as `og:image` only. Reaching them would cost **82 KB and
0.87 s per article page** (≈1.2 MB and ~13 s per refresh) *before* downloading
any pixels, plus browser-UA spoofing — Phoronix 403s non-browser clients.
**This design does not scrape.** Phoronix is included as a text-only source and
renders the glyph fallback, exactly as LWN's 15 items already will.

Feeds surveyed and not adopted: The Verge, Slashdot, Linuxiac and
GamingOnLinux (no per-item images, and no domain advantage over Phoronix,
which is included on domain fit despite the same limitation); The Register,
Hackaday, It's FOSS, Engadget and Tom's Hardware (images present, but heavier
than Ars for an identical 76px result).

### Geometry

- Pane width: `Design.notifSurfaceWidth` = **430**; minus `spacingMd` margins = **398** content.
- BBC 240×135 and Ars 500×500 into a 76px slot are both **downscales** — sharp on any display.
- The BBC CDN honours a width rewrite (`/standard/480/` → 480×270, `/800/` → 800×450, `/1024/` → 1024×576, all HTTP 200). **Not used** — the 240 original is already 3× oversampled for a 76px slot. Recorded so the option is known, not so it is taken.

### Glyph availability

Glyph names are **ligatures** in `Material Symbols Rounded`
(`Design.symbolFontFamily`, `Design.qml:125`) — a wrong name renders as literal
text, not a fallback glyph. Every name below was verified by HarfBuzz shaping
(PIL/Raqm), and the check was poison-tested to confirm it can fail:
`notification` (singular) shapes to **576px of literal text** vs 48px for a
real glyph.

Verified available: `notifications`, `newspaper`, `feed`, `article`,
`rss_feed`, `view_agenda`, `view_list`, `image`, `hide_image`.

---

## Design

### 1. Tab glyphs

Each `tabModel` entry gains a `glyph` role; the existing `labelRow` Row gains a
leading `Text` with `font.family: Design.symbolFontFamily`. No restructure — the
Row and its `Design.spacingXs` spacing already exist.

```
╭──────────────────────────────────────────────╮
│  ╭──────────────────────╮                    │
│  │ [bell] Notifications 12│  [paper] News  ⟳ │
│  ╰──────────────────────╯                    │
╰──────────────────────────────────────────────╯
```

- Tab 0: `notifications` — Tab 1: `newspaper`
- Glyph colour follows the label's existing selected/unselected binding
  (`BarRoles.notifSurfaceFg` / `BarRoles.capsuleFg`).
- The selected tab keeps the existing capsule fill. The band height
  (`Design.popoutHeaderHeight` = 48) does **not** change.

### 2. Card view

Left thumbnail, mirroring `NotifCard.qml`'s `iconSlot` — same surface, same
rhythm, and inheriting that card's hard rule verbatim: **the slot is always
reserved, never blank, and the card never changes width.**

```
430px pane − 32px margins = 398px content
┌─ 76 ─┐  16  ┌──────── 306 ────────┐

WITH IMAGE (BBC, Ars)
╭──────────────────────────────────────────────────╮
│ ┌────────┐  Trump pauses new tariffs on Canada  │
│ │        │  and says countries close to a deal  │
│ │ [img]  │                                      │
│ │ 76×76  │  ╭─────────╮                         │
│ └────────┘  │BBC World│  3h                     │
│             ╰─────────╯                         │
╰──────────────────────────────────────────────────╯

NO IMAGE (LWN, Phoronix) — slot holds a glyph, geometry identical
╭──────────────────────────────────────────────────╮
│ ┌────────┐  Rust 1.94.0 released with async     │
│ │        │  closures stabilised                 │
│ │ [glyph]│                                      │
│ │        │  ╭───╮                               │
│ └────────┘  │LWN│  6h                           │
│             ╰───╯                               │
╰──────────────────────────────────────────────────╯
```

**Row height is content-driven, not thumbnail-driven.** The text column is
already ≈70px (2-line title ≈42 + gap + source capsule ≈24), so:

- 42px thumb → `max(42, 70) + 32` = **102px**
- 76px thumb → `max(76, 70) + 32` = **108px**

A 76px thumbnail costs **6px per row**, not 34. Hence 76 over `NotifCard`'s 42.

**Fallback tier** (mirrors `NotifCard`'s tiered chain, one tier shorter): image
URL present and loads → the image; otherwise → a Material Symbols glyph on the
`BarRoles.capsule` fill. There is no icon-theme tier, because a feed has no
`app_icon` equivalent.

### 3. Compact view

Compact is **today's row, unchanged** — no thumbnail, transparent background,
2-line title, `Source · age` meta line. This is the default.

> **ASSUMPTION FLAGGED FOR REVIEW.** Reddit's own compact mode *does* keep a
> small thumbnail. This design reads "compact" as the denser, image-free row
> that already exists, so the toggle is genuinely image-on / image-off rather
> than two sizes of image. If you want compact to keep a small (≈40px)
> thumbnail, say so — it is a small change to this design, but it is a change,
> and it makes the toggle purely about density.

### 4. The toggle

A second chip beside the existing source filter, mirroring its inline-expand
idiom rather than introducing new chrome:

```
╭─────────────────╮  ╭──────────╮
│ [filter] All   ▾│  │ [view] Cards │   ← tap flips compact ⇄ cards
╰─────────────────╯  ╰──────────╯
```

- Glyphs: `view_agenda` (cards) / `view_list` (compact).
- It is a **toggle, not a dropdown** — one tap flips it, no expand step.

**Persistence:** stored in `news-sources.json` alongside `ttl_minutes`, as
`"view_mode": "compact" | "cards"`. That file is already operator-editable and
already registered in `contract.json`'s `engine_owned_files`, so this adds no
new state surface. Unknown or missing values fall back to `compact`.

---

## Backend changes (`NewsBackend.qml`)

### Image extraction

A general preference order, **no feed-specific code**:

```
media:thumbnail  →  media:content  →  enclosure[type^="image/"]  →  none
```

This picks Ars's 500×500 square over its 1152×648 large, and BBC's 240×135,
automatically. LWN and Phoronix fall through to `none`.

### The third fence point

`NewsBackend.qml` today enforces a `https://` scheme allowlist at **two**
points (source-URL validation, item-link acceptance; `allowedScheme`,
line 129). Image URLs are a **new remote-host class** and become the **third**
point: an image URL that is not `https://` is dropped and the item renders the
glyph fallback — the item itself is still shown. The file header's fence note
must be updated to say "three points", the same discipline 260819-6oy applied
when it widened the fence from a literal host to a scheme allowlist.

### Cache schema

Items gain one field: `image` (string, `""` when absent). Cache shape becomes:

```json
{ "fetched_at": …, "items": [ { "title":…, "link":…, "dateMs":…, "source":…, "image":… } ] }
```

Existing cached items have no `image` key. Treated as `""` — the glyph
fallback renders and the next refresh fills it in. **No migration step and no
cache invalidation needed**, because the absent-key and empty-string cases
already converge on the same render path.

### Fetch discipline

Images are requested by the QML `Image` element only when a card is realised in
the list — not prefetched at parse time, and not fetched at all in compact
mode. `sourceSize` is pinned to the 76px slot so decode is bounded regardless
of source dimensions. The existing open-gate (`NotifServer.centreOpen`) and
stale-while-revalidate behaviour are unchanged.

---

## Source-list changes

Two separate edits, because the seed is idempotent
(`[[ -f … ]] || cat > …`, `stow.sh:378`) and will **not** touch an existing file:

1. **`stow.sh` seed** — for fresh installs. NPR out; Ars Technica and Phoronix in.
2. **The live `~/.local/state/theme/news-sources.json` on this host** — hand-edited
   to match. This file is explicitly the operator's surface, so this is a
   deliberate one-off edit, called out here rather than done silently.

Resulting default source list:

```json
{ "name": "BBC World",    "url": "https://feeds.bbci.co.uk/news/world/rss.xml", "enabled": true }
{ "name": "Ars Technica", "url": "https://feeds.arstechnica.com/arstechnica/index", "enabled": true }
{ "name": "LWN",          "url": "https://lwn.net/headlines/newrss", "enabled": true }
{ "name": "Phoronix",     "url": "https://www.phoronix.com/rss.php", "enabled": true }
```

All four https. None carries an API key, token or credential, and the seed's
standing rule that it must never grow one is unchanged.

---

## Out of scope

Unchanged from 260819-6oy, plus two new exclusions:

- In-shell source editor, article bodies/reader view, refresh timers beyond the
  manual button, read/unread state, JSON Feed support, gate-script edits.
- **No og:image scraping** — measured at ~1.2 MB and ~13 s per refresh plus
  UA spoofing (see Measurements).
- **No BBC CDN width rewriting** — the 240px original is already oversampled
  for a 76px slot.

---

## Verification

Static (all must pass, as in 260819-6oy):

- `colour-lint` — no hardcoded colours; every value from `Colours.qml`/`BarRoles`.
- `motion-lint` — every animation through `Motion.qml`.
- `theme-parity`, `stow-link-check`.
- **Geometry gate** — `git diff` for window-size tokens in `NotifCentre.qml`
  must print **0**. The header band and layer surface do not move.
- **Glyph gate** — every Material Symbols ligature name introduced must shape
  to a single glyph, poison-tested against a known-bad name.

Live:

- Four sources fetch; BBC and Ars show thumbnails; LWN and Phoronix show the
  glyph fallback with identical row geometry.
- Toggle flips both ways and survives a shell restart.
- Compact mode issues **zero** image requests.
- Escape still closes the centre from both tabs.
