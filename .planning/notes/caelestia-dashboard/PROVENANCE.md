# Caelestia dashboard — vendored source

`caelestia-dots/shell` @ **a788c432d9274a123c113eed6d28a241ddfc2cdd**, fetched
2026-08-26 for quick task 260826-rfy (Dashboard + Performance redesign study).

Vendored because a "follow the reference" task without the reference files in
the tree produces an invented design reported as the reference — the failure
this repo already recorded once (`vendor-the-reference-source`).

Fetched from `https://raw.githubusercontent.com/caelestia-dots/shell/<sha>/modules/dashboard/…`
at the pinned SHA, not from `main`, so a later read gets the same bytes.

## What changed upstream since our tabs were built

Our Performance tab (Phase 14 Plans 06/09/10) was written against a Caelestia
that presented a **compact gauge cluster** — `PerformanceTab.qml`'s own round-2
comment cites "the Caelestia reference's compact-gauge-cluster composition", and
14-10 cites their `Performance.qml` `gpuCard` for the `desktop_windows` icon.
**That composition no longer exists upstream.** At this SHA their Performance tab
is a card layout with no dial row at all. Treat any of our in-tree comments that
describe the reference's gauge cluster as historical.

## File → role

### Shell of the drawer

| File | Role |
|------|------|
| `Wrapper.qml` | outermost drawer wrapper |
| `Content.qml` | tab list + the `Flickable`/`RowLayout` pager. Tabs are **config-filtered** (`Config.dashboard.showDashboard` …) and lazily `active`-gated by visible-area intersection |
| `Tabs.qml` | the tab strip itself |

### Dash tab (their tab 0)

| File | Role |
|------|------|
| `Dash.qml` | **the bento** — a `GridLayout`, 6 columns × 2 rows |
| `dash/User.qml` | avatar in a `MaterialShape.Pill`, click opens a face picker |
| `dash/SmallWeather.qml` | big weather glyph + temp + description |
| `dash/DateTime.qml` | **stacked** clock — hour / `•••` / minute on three lines, not `HH:MM` |
| `dash/Calendar.qml` | month grid; wheel changes month, middle-click resets to today |
| `dash/Resources.qml` | a **vertical** column of three full-height rings (CPU / Memory / Storage), icon centred in each |
| `dash/Media.qml` | now-playing, spans both grid rows |

`Dash.qml`'s signature move: every cell is the same `surfaceContainer` colour but
carries a **different corner radius**, so the bento reads as distinct objects
without needing distinct fills.

| Cell | Radius token |
|------|--------------|
| DateTime, Resources | `rounding.large` |
| User, Calendar | `rounding.extraLarge` |
| SmallWeather | `rounding.extraLarge * 1.5` |
| Media | `rounding.extraLarge * 2` |

### Performance tab (their tab 2)

`Performance.qml` composition: a `RowLayout` of [ main column | BatteryTank ].
The main column is a row of two `HeroCard`s (CPU, GPU) above a row of
Storage / Network / Memory cards. Every card is behind a `WrappedLoader` gated on
a per-widget config toggle, and there is a "No widgets enabled" placeholder for
the all-off case.

| File | Role |
|------|------|
| `performance/HeroCard.qml` | CPU/GPU. Small ring with the icon inside, label + `Cpu.name` beside it, **linear** temp bar bottom-left, and a **morphing `MaterialShape`** usage badge bottom-right |
| `performance/MemoryCard.qml` | **270° arc** (`startAngle: -225`, `sweepAngle: 270`), % + "Used" inside, `x / y GiB` under it |
| `performance/StorageCard.qml` | 270° arc beside a text block, plus a `SplitButton` **disk selector** menu |
| `performance/NetworkCard.qml` | **dual-line sparkline** (`SparklineItem`, up + down, fill alpha 0.15 / 0.2) over Download / Upload / Total rows |
| `performance/BatteryTank.qml` | a clipping rect that **fills bottom-up** and draws its contents **twice, inverted**, so the text flips colour as the fill line passes it |

`HeroCard`'s usage badge shape is a function of load:

| Usage | `MaterialShape` |
|---|---|
| < 40% | `Cookie4Sided` |
| 40–80% | `Sunny` |
| ≥ 80% | `SoftBurst` |

## What does not port to this stack

Read before treating any of the above as directly copyable.

| Theirs | Why it does not cross | What we would do instead |
|---|---|---|
| `MaterialShape` (`import M3Shapes`) | A **C++ QML plugin** in their `plugin/` tree. We have no compiled plugin and adding one breaks "reproduces from one script" unless it is packaged | `Shape`/`ShapePath` with hand-authored cubics, or accept a rounded-rect badge |
| `SparklineItem` (`Caelestia.Components`) | Same — C++ | `Canvas` or a `Shape` polyline fed from a ring buffer in QML |
| `Tokens.*` (`Tokens.spacing.medium`, `Tokens.rounding.extraLarge`, `Tokens.font.title.medium`) | Their token singleton. Ours is `Design.qml` with a flat `spacingXs…spacingXl` / `fontLabel…fontDisplay` scale and **no rounding scale at all** | Add a rounding scale to `Design.qml` if a bento direction is picked — the differing-radii trick needs one |
| `Colours.palette.m3primary` / `Colours.tPalette.m3surfaceContainer` | Their palette object shape. Ours is `Colours.primary`, `Colours.surfaceVariant`, … | Straight rename; **but we have no `surfaceContainer` role** — our palette stops at `surface` / `surfaceVariant`. A bento of distinct cells needs a container tint we do not currently generate |
| `Config.dashboard.performance.show*` per-widget toggles | Their config system | `Prefs.qml` already exists here and does this job |
| `Cpu.name` / `Gpu.name` device strings | Their services expose it | `SystemResources.qml` does not currently read a device name — it would have to be added |
| `UPower.displayDevice` | They read battery through UPower | Ours reads `batterySource`; this host has no battery either way |

## Confidence

**HIGH — direct read of the pinned source**, not a web summary. Every claim above
is traceable to a line in the files sitting next to this one.
