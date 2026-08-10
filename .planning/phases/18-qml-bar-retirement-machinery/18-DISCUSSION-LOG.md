# Phase 18: QML Bar & Retirement Machinery - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-10
**Phase:** 18-QML Bar & Retirement Machinery
**Areas discussed:** Bar contents & arrangement, Vertical orientation, Section popouts, Popout hover mechanics, Auto-hide & reserved space, Visibility ownership, Capsule grouping & GATE-02 staging, Notification bell & retirement checklist

---

## Bar contents & arrangement

### Athena's two drawers

| Option | Description | Selected |
|--------|-------------|----------|
| Neither — Super menu owns both | Phase 7's menu already carries settings and launchers; both drawers duplicate a menu one key away | |
| Settings drawer only | Keeps the five switch axes, drops the pinned-app launcher | |
| Both, redesigned | Full athena parity — two hover-expand mechanics in both orientations | ✓ |

**User's choice:** Both, redesigned
**Notes:** Chosen against the recommendation. Flagged at the time: the vertical column has far less room for an 8-icon expansion — resolved later under the vertical-orientation questions.

### Workspace indicator style

| Option | Description | Selected |
|--------|-------------|----------|
| Pill/dot occupancy, active expands | Caelestia/end-4 convention; compact, orientation-agnostic | |
| Live window icons per workspace | Athena's `{icon} {windows}`; most information, variable width | ✓ |
| Plain numbers | Simplest, mirrors the number-row binds | |

**User's choice:** Live window icons per workspace
**Notes:** Chosen against the recommendation and against the standing end-4/Caelestia bias. The variable-width consequence drove the later fixed-height-slot decision for the vertical column.

### Extras earning a permanent slot

| Option | Description | Selected |
|--------|-------------|----------|
| Power button | Direct lineage of wleave's launcher; Phase 20 replaces the target | ✓ |
| Gaming mode toggle | Also one of the four visibility-intent actors | ✓ |
| Notification bell | Phase 19's centre needs a bar button | ✓ |
| Updates count + idle inhibitor | athena-only today | ✓ |

**User's choice:** All four
**Notes:** Multi-select; the full set was taken.

### Tray placement

| Option | Description | Selected |
|--------|-------------|----------|
| Always visible, end of the bar | Simplest; athena's duplication complaint is largely obsolete | ✓ |
| Collapsed behind a chevron | Saves space, adds a second drawer mechanic | |
| Auto-collapse past a threshold | Best of both, most logic | |

**User's choice:** Always visible, end of the bar

---

## Vertical orientation (right edge)

### Drawer expansion direction

| Option | Description | Selected |
|--------|-------------|----------|
| Expand inward, horizontally | Floating strip growing leftward; only direction with room | ✓ |
| Expand along the column, vertically | Truest to a rotation; reflows the column | |
| Collapse to a popout menu when vertical | Least layout risk; different interaction per orientation | |

**User's choice:** Expand inward, horizontally

### Workspace pill growth

| Option | Description | Selected |
|--------|-------------|----------|
| Fixed-height slots, icons wrap or cap | Nothing below ever moves; mirrors Overview's stable block | ✓ |
| Let it grow, elements shift | Truest to athena's horizontal behaviour | |
| Drop window icons when vertical | Zero reflow risk; two orientations show different information | |

**User's choice:** Fixed-height slots, icons wrap or cap

### Zone mapping

| Option | Description | Selected |
|--------|-------------|----------|
| Same three zones, rotated | One zone assignment per entry; nothing to keep in sync | |
| Re-map per orientation | More natural per orientation; risks a second arrangement | ✓ |

**User's choice:** Re-map per orientation
**Notes:** Chosen against the recommendation. Resolved constructively rather than re-litigated — implemented as **one entry list where each entry carries a zone per orientation**, so QBAR-02's "orientation is a property, not a forked layout" still holds.

### Text in a narrow column

| Option | Description | Selected |
|--------|-------------|----------|
| Stacked/abbreviated text, same width | Column stays ~44px; what the reference verticals do | ✓ |
| Icon-only when vertical, value on hover | Narrowest; loses at-a-glance readouts | |
| Wider column, full text | No compromise on readability; permanent screen-width cost | |

**User's choice:** Stacked/abbreviated text, same width

### Bar shape

| Option | Description | Selected |
|--------|-------------|----------|
| Floating detached capsule | Athena's posture; matches QBAR-01's language and the panel family | ✓ |
| Flush to the edge | No margin pixels; further from the capsule language | |
| One continuous vs. separate section capsules | Deferred to the later grouping question | |

**User's choice:** Floating detached capsule

### Now-playing and the MPRIS reader

| Option | Description | Selected |
|--------|-------------|----------|
| Native Mpris, bar + dashboard both | One reader immediately; kills the 1 Hz fork loop; QMEDIA-03 satisfied early | ✓ |
| Native Mpris on the bar only | No Phase 21 scope movement; reader count stays at 3 | |
| No now-playing on the bar | Zero cost; loses glanceable track info | |

**User's choice:** Native Mpris, bar + dashboard both
**Notes:** Reframed mid-discussion after research. The initially-offered "shared MediaBackend" option was withdrawn as misleading — `MediaBackend.qml:90` runs `media-status.sh watch` at `POLL_INTERVAL=1`, forking ~10 processes per second, which an always-on bar would run permanently against QBAR-11. Native `Quickshell.Services.Mpris` was then verified present on the installed 0.3.0-2 with the full property surface, making a zero-subprocess reader available.

### Battery

| Option | Description | Selected |
|--------|-------------|----------|
| Entry exists, hides when absent | Native UPower; satisfies QBAR-06; survives a laptop deployment | ✓ |
| Drop it, amend QBAR-06 | Athena's call; needs a requirements amendment | |

**User's choice:** Entry exists, hides when absent
**Notes:** Verified before asking — `/sys/class/power_supply/` is empty (no battery, no AC device), chassis `desktop`, board B550 AORUS ELITE AX V2.

### Focused window title

| Option | Description | Selected |
|--------|-------------|----------|
| Leave it out | Variable width is the worst element for a no-reflow bar | ✓ |
| Include it, hard-truncated | Stable width; per-workspace icons already cover it | |

**User's choice:** Leave it out

---

## Section popouts (QBAR-09)

### Popout frame

| Option | Description | Selected |
|--------|-------------|----------|
| PanelDialog gains an anchored compact posture | One frame, two postures; matches the file's own "never a bespoke PanelWindow" rule | |
| New lightweight popout type | Clean separation; a second frame to keep themed and in visual step | ✓ |
| Reuse the panels as-is, centred | Zero new work; delivers nothing visibly new for QBAR-09 | |

**User's choice:** New lightweight popout type
**Notes:** Chosen against the recommendation. Two obligations recorded as constraints rather than argued: registration in GATE-03's `quickshell-doctor` checks, coverage by GATE-04's hex lint, and visual/motion parity with `PanelDialog` maintained by review rather than by construction. Research surfaced first that `PanelDialog` is a fixed 850×620 compositor-centred window, so "reuse the panels" would have meant re-opening the same surface `Super+A` already opens.

### Which sections

| Option | Description | Selected |
|--------|-------------|----------|
| Audio / Wi-Fi / Bluetooth | Backends already exist | ✓ |
| Clock → calendar | DashboardTab's calendar exists | ✓ |
| CPU / RAM / disk → resources | SystemResources exists | ✓ |
| Now playing → media | Rides the native Mpris singleton | ✓ |

**User's choice:** All four

### Dashboard drawer's role

| Option | Description | Selected |
|--------|-------------|----------|
| Drawer stays, popouts are the fast path | Same detail/glance split Overview already has | ✓ |
| Popouts primary, drawer slims down | Less duplication; edits a shipped v3.0 surface | |
| Popouts open the drawer at the right tab | Least code; exactly what QBAR-09 exists to end | |

**User's choice:** Drawer stays, popouts are the fast path

### Interaction model

| Option | Description | Selected |
|--------|-------------|----------|
| Click to open, one at a time, click-outside dismisses | Inherits the panel family's proven behaviour | |
| Hover to preview, click to pin | Feels fast; collides with the hover-reveal gesture | ✓ |
| Click to open, multiple can stay open | Breaks the one-open invariant | |

**User's choice:** Hover to preview, click to pin
**Notes:** Chosen against the recommendation. The collision with QBAR-08's hover-reveal was flagged as a gap that would ship broken, and settled in the follow-up set below rather than left to the planner.

---

## Popout hover mechanics

| Question | Options | Selected |
|----------|---------|----------|
| Reveal race | Suppressed until reveal settles + pointer moves / Suppressed only during animation / No suppression | Suppressed until reveal settles + pointer moves ✓ |
| Dwell delay | ~400ms / ~150ms / ~800ms | ~400ms ✓ |
| Unpinned dismiss | Leaves both section and popout / Any exit from section / Stays until another hovered | Leaves both section and popout ✓ |
| Pinned behaviour | Ignores hover, click-outside dismisses / Still swaps on hovering another section | Ignores hover, click-outside dismisses ✓ |

**Notes:** All four followed the recommendation. Together these make the reveal gesture and the preview gesture structurally distinct motions.

---

## Auto-hide & reserved space

### Exclusive-zone policy

| Option | Description | Selected |
|--------|-------------|----------|
| Per-driver: idle keeps it, fullscreen/gaming/keybind release it | Preserves today's no-reflow-on-idle; fixes the lit sliver | ✓ |
| Always keep the zone reserved | Zero reflow ever; QBAR-12 provable by construction; games never reclaim pixels | |
| Always release the zone | No wasted pixels; every idle timeout resizes every window twice | |

**User's choice:** Per-driver policy
**Notes:** Research reframed this question. The current bar has three states, not two — `hidden-idle` dims to `opacity: 0.05` while **keeping** the zone reserved (no reflow, but pixels lit), and only `hidden-hard` unmaps. So "does idle reflow?" was the real question, and today's answer is no.

### Reveal mechanism

| Option | Description | Selected |
|--------|-------------|----------|
| Invisible hot zone along the bar's edge | Nothing painted; standard idiom; one more surface for the doctor | ✓ |
| Pointer-position polling, no surface | No extra surface; needs a timer while hidden, against QBAR-11 | |
| No hover reveal when zone is released | Fewest moving parts; reveal stops working when most needed | |

**User's choice:** Invisible hot zone

### Hot-zone geometry

| Option | Description | Selected |
|--------|-------------|----------|
| Screen edge, ~3–5px deep | Slam-to-edge works without aiming | ✓ |
| Full bar footprint incl. margin | Most forgiving; swallows events over ~46px | |
| Screen edge, 1px | Minimum interception; slow travel can stop short | |

**User's choice:** Screen edge, ~3–5px deep

### Re-hide behaviour

| Option | Description | Selected |
|--------|-------------|----------|
| Stay revealed while interacting, re-hide on a grace timer | Never vanishes under the pointer | ✓ |
| Re-hide immediately when the condition ends | Strict; closes popouts mid-read | |
| Stay revealed until an explicit hide | Never surprises; leaves the bar lit on OLED | |

**User's choice:** Grace-timer re-hide

---

## Visibility ownership

### Owner

| Option | Description | Selected |
|--------|-------------|----------|
| Script stays sole owner, actuates via `qs ipc call` | Survives QBAR-10 restarts; six callers keep working with a rename | ✓ |
| QML owns it, actors declare intent over IPC | Most direct; state dies with the process | |
| Hybrid — QML owns, script shim persists state | Both properties; two things that look like the owner | |

**User's choice:** Script stays sole owner
**Notes:** Decided after verifying that quickshell 0.3.0-2 has **no idle-notify client** — only `qs::wayland::idle_inhibit::IdleInhibitor`. hypridle therefore remains the idle source regardless, so the external intent path could not have been eliminated.

### Fullscreen watcher

| Option | Description | Selected |
|--------|-------------|----------|
| Retire the watcher; QML reports fullscreen intent | Deletes a process QBAR-11's soak counts | ✓ |
| Keep the watcher, repoint it | Smallest diff; a second reader of the same event | |

**User's choice:** Retire the watcher
**Notes:** Consequence recorded rather than left implicit — while the shell is down nothing reports fullscreen; the owner's missing-file default is `show`, so it degrades to a visible bar.

### Keybind

| Option | Description | Selected |
|--------|-------------|----------|
| Keep it a Hyprland bind to the owner script | Works when the shell is down; keybind-doctor needs only a rename | ✓ |
| Convert to a GlobalShortcut in QML | Consistent with other surfaces; cannot resurrect a dead bar | |

**User's choice:** Keep it a Hyprland bind

### Orientation switching UX

| Option | Description | Selected |
|--------|-------------|----------|
| Orientation toggle in the settings drawer + menu | Preserves the discoverable path already in use | ✓ |
| Config value only, edited by hand | Least code; the only theme-adjacent switch with no UI | |
| Keybind toggle | Fast to test; spends a scarce keybind on a never-changed setting | |

**User's choice:** Settings drawer + menu toggle

---

## Capsule grouping & GATE-02 staging

| Question | Options | Selected |
|----------|---------|----------|
| Continuous or discrete | Discrete capsules by concern / One continuous capsule / Continuous with tray+actions split | Discrete capsules by concern ✓ |
| Capsule count | ~5–6 by concern / ~3 larger / ~12+ one per section | ~5–6 by concern ✓ |
| Gate timing | Checkpoints + blocking final pass / One pass at phase end / Per-plan gate | Checkpoints + blocking final pass ✓ |
| Comparison baseline | Athena + named-capability check / Athena only / Screenshots of all four | Athena + named-capability check ✓ |

**Notes:** All four followed the recommendation. Gate timing was argued from this repo's own record of shipping visibly broken surfaces through green gates three times (Phase 6, Phase 8's bar, Phase 16's two false passes).

---

## Notification bell & retirement checklist

| Question | Options | Selected |
|----------|---------|----------|
| Bell before Phase 19 | Wire it to swaync for now / Ship disabled with a reason / Don't ship until 19 | Wire it to swaync for now ✓ |
| Checklist genericity | Generic, takes a surface name / Waybar-shaped, generalise in 19 | Generic from day one ✓ |
| Enforcement | Blocking, folded into theme-doctor / Blocking, standalone / Advisory | Blocking, folded into theme-doctor ✓ |
| Coverage beyond RETIRE-01's list | theme-doctor internals / fixtures & registries / cross-script refs / planning prose | All four ✓ |

**Notes:** All followed the recommendation. Including planning prose in the same count would make "zero hits" unreachable — `.planning/` carries hundreds of historical waybar mentions in shipped milestone archives that must stay. Resolved as **two tiers in one script**: a blocking tier over live code, config, fixtures and checker internals, and a separate reported tier over docs and prose.

---

## Claude's Discretion

- Exact capsule split within the 5–6 by-concern shape
- Grace-period and dwell tuning around the stated values, provided the reveal-suppression rule holds
- Hot-zone depth within 3–5px
- Per-app glyph map contents (seed from athena's `window-rewrite` table)
- GATE-03's `quickshell-doctor` structural checks
- GATE-04's hex-literal lint shape
- LEDGER-01's documentation corrections
- LEDGER-03's frame-rate measurement method

## Deferred Ideas

- **Caelestia's shrink-to-a-sliver auto-hide** — already Out of Scope; re-confirmed
- **Popouts replacing dashboard tabs** — rejected; a v5.0 question if duplication annoys in daily use
- **Orientation toggle as a keybind** — rejected; scarce plain-Super letters
- **Unifying `bar-visibility.sh` and `wallpaper-visibility.sh` into one owner** — two near-identical owners now exist; revisit if a third appears
