---
quick_id: 260818-nwo
date: 2026-08-18
status: complete
commits:
  - d38df38
  - e1eb19d
  - 1871c02
open_items:
  - "Bug 2 (window-edge smear): narrowed to blur:xray vs blur:new_optimizations; blocked on an operator-observed runtime A/B"
---

# Quick Task 260818-nwo — Summary

Four bugs reported. **Three fixed and verified; one narrowed and handed back**
with a two-command A/B, because isolating it needs a human eye on a moving
image and guessing between the two remaining candidates was not acceptable.

## Fixed

### 1. Kitty argument text (`d38df38`)

ANSI slots 5/6/13/14 remapped from container roles to their `on_*_container`
foreground partners.

**Measured live after `theme-apply materialyou`:**

| slot | before | after |
|---|---|---|
| color6 (cyan — fish arguments) | 1.98:1 | **14.42:1** |
| color5 (magenta) | 1.98:1 | **14.34:1** |

Across the static palettes, `on_tertiary_container` clears AA in all 20;
`on_secondary_container` clears it in all 15 dark ones.

### 2. Notifications restoring (`e1eb19d`)

Two halves, both required:

- **Release on clear.** Every clear path now untracks the underlying
  notification, so the server drops it and cannot replay it. Cap-trim releases
  too, closing an unbounded retention leak on the side.
- **Replay guard.** Entries carry a stable `key` (`id|appName|summary|body`);
  `_recordHistory` skips a key already present, refreshing the live handle
  instead of duplicating the row.

Plus `clearOne` rekeyed from the recycled D-Bus id to the stable key, and an
idempotent migration that backfills keys and drops pre-existing duplicates.

**Confirmed live.** QML hot-reload picked the change up and the migration ran on
the real state file: **100 entries → 66, all keyed, all unique.** The 34 rows it
removed are exactly the duplicates the replay bug had written. This is the
strongest available evidence short of clicking the buttons — it proves both the
diagnosis (duplicates existed and were machine-identifiable) and that the new
code path executes on the running shell.

### 3. Weather tab jitter (`1871c02`)

Both residual axes closed: `settledPaneHeight` added as the exact mirror of
`settledPaneWidth`, and `anchors.horizontalCenter` replaced with a left anchor —
that centring was introduced by the previous fix and was itself sliding the
content's left edge every animation frame.

## Not fixed — needs the operator

**Window-edge smear.** `decoration:motion_blur:enabled` is **false** — checked
precisely because the name matches the symptom word for word, and concluding
from the name would have been wrong. Remaining candidates are
`decoration:blur:xray` (set at `hyprland.lua:111`) and
`decoration:blur:new_optimizations`, with blur `size 8` / `passes 3` and
`damage_tracking 2`. Every surface named in the report is a layer surface with an
explicit `blur = true` rule, which is a tight correlation but does not choose
between the two knobs.

Handed back as a runtime A/B (`hyprctl keyword`, nothing persisted).

## Gates

- `quickshell-doctor` — **28 passed, 0 failed**
- `theme-doctor` — **580 passed, 0 failed**
- `qmllint` — clean on all five edited QML files
- `theme-apply materialyou` — exit 0

## Findings worth carrying

**The terminal bug was not where the report pointed.** "Kitty font colors"
sounds like kitty config; the actual chain was kitty → `shell fish` → fish's
`fish_color_param` default of cyan → the matugen template's cyan → a Material You
*container* role. Reading `kitty.conf` for the `shell` line is what turned a
guess into a measurement, and it also invalidated the first plausible suspect
(zsh-syntax-highlighting, which the repo does load — for a shell kitty never
launches).

**A timestamp column can prove a replay.** `history[].timestamp` is stamped at
record time, so fourteen entries sharing one second is not fourteen
notifications — it is one bulk re-record. That single observation converted
"cleared notifications come back" from a plausible story into a measured fact,
and it was available in a file on disk without touching the running shell.

**Ids that look unique are not.** 53 distinct ids across 100 rows. Anything keyed
on a D-Bus notification id addresses the wrong rows — the same shape as the
earlier MPRIS `uniqueId` trap in `MediaBackend`. Two independent defects in this
file both reduced to it.

**A previous fix's own deferral is a live lead.** The weather note named the
vertical axis as deliberately unfinished, and the follow-up report was exactly
that. Better still, the *second* cause was introduced by that same fix —
`anchors.horizontalCenter` only became a problem once the width stopped tracking
the frame. A partial fix can create the residual it warns about.

**Option names are not evidence.** `decoration:motion_blur:enabled` describes the
reported symptom verbatim and is off. Checking cost one command; asserting it
would have produced a confident wrong answer and a wasted fix.
