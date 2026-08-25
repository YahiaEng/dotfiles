---
created: 2026-08-25
source: quick task 260825-v3u (operator selection, round 3)
status: pending
size: too big for /gsd-quick — scope as its own task or a small milestone
---

# Add the four Caelestia settings-page groups

The operator picked **all four** groups when asked which gaps against
Caelestia's settings menu to close. Deliberately NOT appended to quick task
260825-v3u — four new pages plus two page-level features is more than a quick
task carries.

## Where the comparison came from

Caelestia's settings window is `modules/nexus/`; its page list is
`modules/nexus/PageRegistry.qml` (11 pages). Ours is
`quickshell/.config/quickshell/modules/settings/PageRegistry.qml` (10 pages).
Read their source directly — the operator's original reference was a YouTube
video, not a live window.

**Not gaps:** their `Display` page is a commented-out TODO and we already ship
one; their `Plugins` page has no equivalent here (no plugin system).
**Already present:** our PageRegistry already carries `category` and
`description` per page, and NavRail already groups by category — so their
nav grouping is not something to add.

## The four groups, in the order to build them

Ordered cheapest-first so the page-registry additions are proven before the
heavier two.

### 1. About + Updates
Both backends already exist in the launcher — `modules/launcher/SystemInfoMode.qml`
gathers system info, `modules/launcher/UpdatesMode.qml` the pending-update list.
Two self-contained, read-mostly pages; mostly a settings-side presentation of
data that is already gathered.

### 2. Bluetooth page + per-app volume
Caelestia gives Bluetooth its own "Connected devices" page (pairing, per-device
info); ours is squeezed inline onto the Network page.
`modules/dashboard/BluetoothBackend.qml` and `BluetoothPanel.qml` exist.
Their Audio page carries a per-app mixer — `modules/dashboard/AudioBackend.qml`
already exposes `streams` (per-app PipeWire nodes), so the PipeWire half is
done.

### 3. Apps
Default apps, favourites, hidden apps. The QML launcher already reads
`DesktopEntries` and tracks `launchCounts`/`sortMode`, so the app list exists.
Favourites and hidden-app filtering are new `Prefs` keys plus a filter at the
launcher's existing single filter point.

### 4. Services + Language & region
The most new plumbing. Poll intervals (weather, news, resources) are hardcoded
today. Weather location currently sits oddly on the Notifications page and
would move here, alongside display units.

## Things any of these must not trip over

- **Every new page needs a `RowIndex.qml` entry per row**, or
  `settings-index-check` (126 checks) red-lights. It also guards
  PageRegistry/PageCompRegistry index alignment — page ORDER is load-bearing.
- **`shell.qml` looks pages up by `slug`, never by index** (see
  `networkPageIdx`). Adding pages before `network` is safe because of that;
  adding a hardcoded index anywhere is not.
- **New Prefs keys must be added to BOTH `_allowedKeys` and `_defaults`** in
  `modules/Prefs.qml`, in the same commit as the row that writes them.
- **`Design.settingsFont*`/`settingsIconSize`** are the settings-window type
  scale (round 3/4). New pages read those, never `fontBody`/`fontLabel`.
- **A hot reload will not show a settings-layout change** — incubated page
  components serve stale QML. Restart the shell via its unit to render.
