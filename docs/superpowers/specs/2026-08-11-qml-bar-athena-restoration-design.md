# QML Bar — Athena Restoration

**Date:** 2026-08-11
**Status:** Approved, handed to GSD for planning as an inserted phase
**Blocks:** Phase 18's GATE-02 (18-19) and, transitively, 18-20 (waybar package retirement)

## Problem

Phase 18 shipped a Quickshell QML bar intended to replace the Athena waybar layout. On first
real use the operator's verdict was unambiguous:

> "The new bar looks nothing like my Athena waybar. It is so much worse. No colors, big and
> clunky, nothing expands like Athena that shows my utilities (theme changer, wallpaper
> picker, etc), the workspace only has icon for terminal (no browser, no pacman icon
> indicating the selected workspace)"

This is exactly the judgment GATE-02 exists to collect, arriving before 18-20 deleted the
waybar package rather than after. The gate fails.

### Root cause

Not four bugs. One architectural decision plus three consequences.

**Athena applies colour as background fills across three tonal roles.** Active workspace:
`background: @accent; color: @on-accent`. Clock: `background: @fill-clock` (`@secondary`).
Updates: `background: @fill-updates` (`@tertiary`).

**The QML bar applies colour as foreground tint only.** `WorkspaceCapsule.qml:349` reads
`color: slotFocused ? Colours.primary : contentColour` — it tints the numeral and never fills
the pill. Across the whole `modules/bar/` tree, `Colours.secondary` is **never referenced
once**; `tertiary` appears twice, both a Friday tint in the calendar popout. The dominant
roles are `onSurfaceVariant` (29 uses) and `surfaceVariant` (14) — neutral greys.

The failure was structurally invited: `WorkspaceCapsule.qml:90` *promises* "State is carried by
colour instead (UI-SPEC's Accent role)" while the code does no such thing. The promise lived in
a comment, where nothing could enforce it.

### Findings, mapped to the complaint

| Complaint | Finding |
|---|---|
| "No colors" | Colour applied as foreground tint, never as fill. `secondary` unused; `tertiary` near-unused. |
| "Big and clunky" | **Not geometry.** `barHeight: 40` / `barEdgeMargin: 6` / `barSideMargin: 10` are identical to Athena's `height: 40` / `margin-top: 6` / `margin-left|right: 10`. It is the always-on `4% 36% 7%` text (Athena's storage pills were icon-only until clicked), the extra tray capsule, and flat opaque grey capsules with no colour hierarchy. |
| "Nothing expands" | The drawers **exist and are complete** — an 8-entry apps launcher, and a settings drawer carrying exactly the named utilities: `theme`, `wallpaper`, `font`, `icon theme` (`ClockActionsCapsule.qml:347-352`). They are `onClicked` toggles (`:448`, `LauncherCapsule.qml:204`); Athena's waybar `group/*` drawers were hover-reveal. Nothing is missing — the trigger changed. |
| "Only terminal has an icon" | The bar's `symbolFontFamily` is `"Material Symbols Rounded"` (`Design.qml:103`), which carries none of Athena's Nerd Font codepoints. kitty's `󰆍` renders only via fontconfig fallback; zen's brand glyph renders as nothing **despite being mapped** (`{ appId: "zen", glyph: "" }`), which additionally suggests an appId/class mismatch. FiraCode Nerd Font is installed and carries both ranges — no new package needed. |
| "No pacman icon" | Deliberately dropped. `WorkspaceCapsule.qml:85-93` records that Athena's `format-icons` state set (active/default/urgent/empty) "is not carried either", slot identity being the numeral instead — and closes with "18-19's GATE-02 criterion A judges whether that reads as well." It does not. |

### What is *not* wrong

The module set is a near 1:1 match with Athena already — launcher/apps, cpu+ram+disk+updates,
workspaces, media+audio+brightness+network+bluetooth+battery, clock+gaming+notifications+
idle-inhibitor+settings+power, in Athena's order. **This is a styling and interaction job, not
a re-architecture.**

## Decisions

| Decision | Choice |
|---|---|
| Design target | **Bring Athena's look back.** Phase 18's "redesign toward end-4/Caelestia rather than straight-port" premise is reversed for this surface. |
| Colour architecture | **A bar-scoped role layer** mirroring Athena's `theme.scss`, not per-capsule edits. |
| Restore set | Filled colour pills; hover-reveal drawers; Athena glyph set + pacman; icon-only resource pills at rest. All four. |
| Tray capsule | **Dropped**, as Athena dropped it — its own config records the removal because nm-applet/blueman icons duplicated the connections group. |
| Workspace slot identity | **Athena exactly — state glyph, no numeral.** Active `󰮯`, default `󰊠`, urgent `󰧵`. Accepted cost: loses the numeral's visual mapping to Super+N. |
| GATE-02 judgment | **Side-by-side, operator decides.** Passes only when the operator says the QML bar is at least as good. |

## Design

### 1. `modules/bar/BarRoles.qml` — a bar-scoped colour role layer

A new singleton registered in the bar `qmldir`, reproducing Athena's `theme.scss` mapping onto
`Colours.*`. Every row has a named source, so the table diffs line-by-line against `theme.scss`.

| Bar role | Athena `theme.scss` | Material You source |
|---|---|---|
| `barSurface` / `barSurfaceHover` | `@bar-surface` | `alpha(surface, 0.55)` / `alpha(surface, 0.78)` |
| `capsule` | `@capsule` | `alpha(surfaceVariant, 0.85)` |
| `capsuleFg` | `@capsule-fg` | `onSurfaceVariant` |
| `capsuleHover` | `@capsule-hover` | `alpha(surfaceVariant, 0.95)` |
| `capsuleTrack` | `@capsule-track` | `alpha(outline, 0.5)` |
| `accent` / `onAccent` | `@accent` / `@on-accent` | `primary` / `onPrimary` |
| `warn` | `@warn` | `tertiary` |
| `danger` / `onDanger` | `@danger` / `@on-danger` | `error` / `onError` |
| `fillClock` / `fillClockFg` | `@fill-clock` | `secondary` / `onSecondary` |
| `fillUpdates` / `fillUpdatesFg` | `@fill-updates` | `tertiary` / `onTertiary` |
| `fillNotification` / `fillNotificationFg` | `@fill-notification` | `primary` / `onPrimary` |

**The `alpha()` values are load-bearing.** Athena's capsules are translucent — `surfaceVariant`
at 0.85 over a bar surface at 0.55, on blur. Opaque capsules read as a solid grey slab and are
a direct contributor to "clunky".

**Consumption rule:** after this change, no file under `modules/bar/` references `Colours.*`
directly. Everything goes through `BarRoles`. This is the executable form of the promise that
`WorkspaceCapsule.qml:90` made in a comment and the code broke.

### 2. Component changes

| File | Change |
|---|---|
| `WorkspaceCapsule.qml` | Focused slot: foreground tint → **filled pill** (`background: BarRoles.accent`, `color: BarRoles.onAccent`). Slot identity: numeral → Athena's state glyph set (`󰮯` active, `󰊠` default, `󰧵` urgent). Glyph cells switch to FiraCode Nerd Font; restore Athena's full window-rewrite map (kitty, firefox, zen, codium, VSCodium, discord, spotify, obsidian, lutris, steam, thunar, yazi, `󰊠` default). Diagnose and fix the appId/class mismatch. |
| `SystemCapsule.qml` | cpu/ram/disk become **icon-only at rest**, value revealed on click (Athena's `format-alt`). Updates entry takes the `fillUpdates` background. Thresholds use `warn` / `danger`. |
| `ClockActionsCapsule.qml` | Clock takes the `fillClock` background. Notification entry fills with `fillNotification` when the count is non-zero. Settings drawer: click-toggle → **hover-reveal**. |
| `LauncherCapsule.qml` | Click-toggle → **hover-reveal**. Retains desktop-entry icons — those are launcher icons and should follow the icon-theme switcher, unlike the tiny workspace glyphs. |
| `TrayCapsule.qml` | **Deleted**, with its `BarEntryModel` entry and `qmldir` line, after a consumer sweep. |
| `BarCapsule.qml` | Capsule background → `BarRoles.capsule` / `capsuleHover`, picking up Athena's translucency. |

### 3. Hover-reveal interaction

Both drawers expand on hover with a **close grace period**, so the drawer does not snap shut
when the pointer crosses the gap between trigger and drawer (Athena's waybar group used
`transition-duration: 500`).

This must not fight `BarReveal`'s existing hot-zone state machine, which already owns a 600ms
grace timer and a create/destroy `HotZone` surface. Two hover systems on one surface is the
sharpest integration risk in this design and needs explicit handling, not incidental
coexistence.

## Verification

Three layers, because the human gate alone is what good intentions in comments can defeat:

1. **A `quickshell-doctor` check** asserting no `Colours.*` reference survives under
   `modules/bar/`. The repo's `hypr/.config/hypr/scripts/quickshell-doctor` already carries
   this class of structural check. This converts the failure mode that produced today's bar
   into a check that fails loudly.
2. **The `BarRoles` table diffed line-by-line against `theme.scss`** — every row has a named
   source, so this is mechanical.
3. **Live screenshots of the workspace capsule** with a browser, terminal and file manager
   open. The glyph fix is precisely the kind that passes code review and renders tofu.

Then GATE-02: operator runs Athena and the QML bar side-by-side and judges. 18-20 stays blocked
until that passes.

## Risks

1. **Hover-reveal vs `BarReveal`.** Two hover systems on one surface — a drawer opening while
   the bar is mid-reveal, or two grace timers racing.
2. **Deleting `TrayCapsule`.** 30K, the module's largest file. Requires an explicit consumer
   sweep beyond `BarEntryModel` and `qmldir` before removal.
3. **The appId mismatch is inferred, not proven.** Concluded from zen being mapped yet blank;
   it could instead be purely the font. Diagnose before fixing, or the wrong layer gets changed.
4. **Losing the numeral** is a real usability cost against Super+N, accepted deliberately.
5. **QBAR-11's soak stays open** regardless — it needs an uninterrupted 4-hour window, and any
   of this work restarts the shell.

## Out of scope

- Any change to popout content or the `SectionPopout` framework — not complained about.
- The bar's geometry tokens — measured identical to Athena's.
- Retiring waybar (18-20), which this work unblocks but does not perform.
- QBAR-11's soak and its verdict.
