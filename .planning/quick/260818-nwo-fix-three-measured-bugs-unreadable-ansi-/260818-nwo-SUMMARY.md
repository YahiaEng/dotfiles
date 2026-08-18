---
quick_id: 260818-nwo
date: 2026-08-18
status: complete
commits:
  - d38df38
  - e1eb19d
  - 1871c02
  - cf002da
  - 14a9f0e
  - a63788b
  - 7e8a3f2
  - dd9f81e
  - d1d9b54
  - da81f39
  - db35f2f
open_items: []
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

---

## Follow-up round (`cf002da`), after operator feedback

**Reported back:** (1) kitty is legible now but lost the colour distinction
between a command and its arguments; (2) weather jitter is better; (3) the
`hyprctl keyword` A/B could not run — this repo's Hyprland config is Lua and
needs `hyprctl eval`.

### 1. Command/argument distinction restored

`d38df38` fixed legibility and created a second problem: `on_secondary_container`
renders near-white, so arguments became indistinguishable from the default
foreground.

The real bind: fish resolved every class through the 16 ANSI slots, forcing one
mapping to be both a faithful ANSI palette and a readable command line. Material
You has four chromatic roles; ANSI wants six hues. The command line always lost.

Fixed by giving fish its own matugen-rendered palette
(`matugen/.config/matugen/templates/fish-colors.fish` → `[templates.fish]` →
sourced by `config.fish`), which decouples the two problems.

Measured: `fish_color_command` defaults to **`normal`** — plain foreground — so
commands were never accented in the first place; they now take `primary`.
Arguments take `on_surface`, the only role class clearing AA in **all 20**
palettes (worst 4.5:1). Command-vs-param CIE76 ΔE: worst 13.2 across the static
themes, 29.5 live, both at ≥10.9:1.

**A silent no-op caught only by reading the values back.** `#` opens a comment
in fish, so `set -g fish_color_command #b3c5ff` sets the variable EMPTY, sources
cleanly, and exits 0. The file looked correct and did nothing. Every value is
single-quoted now. Trusting the exit code would have shipped it.

New `fish-set` contract format added so the file is covered by parity rather
than presence-only. `theme-parity` **1633 passed / 0 failed** across all 22
render dirs; `theme-doctor` **580 passed**.

### 2. Weather jitter — improved, not confirmed closed

Operator reports "better". Left open pending a definite verdict rather than
recorded as fixed.

### 3. The A/B was un-runnable as issued — my error

`hyprctl keyword` is the hyprlang idiom; this repo migrated to Lua in Phase 13.1,
where the live-set path is `hyprctl eval 'hl.config({...})'` — the form
`gaming-mode-toggle.sh:135` has used all along. Corrected commands verified by
setting, reading back with `getoption`, and restoring.

**Do not restore with `hyprctl reload`** — it drops layer rules on this config,
which would look like a second, unrelated bug. Restore by setting the value back
via `eval`.

---

## Round 3 (`14a9f0e`)

**Reported back:** (1) distinction restored but the argument colour is not
liked; (2) jitter slightly noticeable — *the glyphs themselves* shift left and
right before settling; (3) neither blur knob killed the smear.

### 1. Argument colour → `tertiary`

The first pass optimised the wrong thing. `on_surface` was picked because it is
the only role clearing AA in all 20 palettes — but it *is* the default text
colour, so arguments read as plain body text. Legibility solved, distinction
still absent.

Three candidates measured and put to the operator with numbers rather than
adjectives; `tertiary` chosen (#e1bbdc, 10.9:1, ΔE 22.8 from the command and
21.8 from plain white). The AA-safe-everywhere alternative
(`on_primary_container`, worst 4.52:1) was too close to white to solve the
reported problem. Quotes/operators moved off `tertiary` so a quoted argument
does not collapse into a bare one.

### 2. Glyph jitter — fractional cell widths

A genuinely different symptom from round 1's frame-level jitter, and one that
**pinning the width could never have fixed** — the width was already constant,
it just was not a whole number:

- `dayCellWidth = (664 − 4×4)/5 = **129.6**` — fractional unconditionally
- `hourCellWidth = 664/hourColumns` — integer **only** at exactly 8 columns
  (664/6 = 110.667, /7 = 94.857, /9 = 73.778, /10 = 66.4), and `hourColumns`
  is backend-driven

Fractional cells sit at fractional x; each cell centres its content; so glyphs
landed on fractional coordinates and Qt re-rasterised them at a shifting
subpixel phase while the frame animated.

Both rows now round cell boundaries **cumulatively** — cell *i* spans
`round(i·W/n)` to `round((i+1)·W/n)` — so every width and edge is integral and
they still sum to exactly W. Verified for 6/7/8/9/10/12 columns and the 5-day
row. Rounding each width independently would have drifted the total by up to
n/2 px and left a ragged right edge.

### 3. Smear — both blur knobs exonerated

`blur:xray` and `blur:new_optimizations` both ruled out by operator A/B, on top
of `motion_blur` already being off. Next round bisects rather than guesses:
blur off **entirely** first, which either implicates or clears the whole blur
subsystem in one observation, then `render:expand_undersized_textures` (whose
documented job — stretching a texture that has not yet resized — is the closest
description of the symptom remaining), then `debug:damage_tracking 0`.

All three verified to apply and restore via `hyprctl eval` + `getoption`
readback before being handed over.

---

## Rounds 4-6 — the drawer architecture (all operator-verified)

### Smear (`a63788b`) — CLOSED

`render:expand_undersized_textures` (default true) stretches a surface's
existing texture to fill new geometry when the client has not yet committed a
buffer at that size — i.e. every frame of an animated resize. Those stretched
edge pixels were the smear. Found by elimination: `motion_blur` (already off,
checked first *because* its name describes the symptom verbatim), then
`blur:new_optimizations`, then `blur:xray`, then blur off entirely as a
bisect, then this.

### Weather jitter — CLOSED, after three wrong attempts

The operator's observation closed it: *"only Performance ↔ Weather, and
Performance has a different width."*

`anchors.top: true` alone makes the compositor **horizontally centre** the
surface, so any width change drags the whole surface sideways. 7210 samples of
`hyprctl layers` (committed as `drawer-geometry-trace.txt`): x travelled
875→735 = **140px, exactly the 280px width delta halved**. The centring is also
non-atomic — `2x + w` held at rest but swung 2416–2599 mid-animation, the
per-frame error oscillating ±11px. That oscillation was the jitter.

Both earlier fixes made the *contents* stable relative to the surface. **The
surface itself was what moved.**

The final correction needed one more iteration: anchoring top+left+right fixed
the width but let *height* animate, and the jitter returned. That isolated the
real rule — **the surface must not resize on any axis** — so it is anchored on
all four edges with no implicit size, and every motion happens in QML.

### Three regressions from that refactor — all CLOSED

- **Slid up from the bottom** (`dd9f81e`, `d1d9b54`): a `slide` on an
  all-four-anchored surface has no edge to slide from. Layer rule → `fade`
  (as `quickshell-session` already ships) with the drop-down done in QML.
- **Content escaping the panel** (`dd9f81e`): a wl_surface clips implicitly;
  a plain `Item` does not. `clip: true` restored what the surface boundary
  used to provide for free.
- **Dismiss too slow** (`da81f39`): measured — the surface unmaps in 38–42ms,
  so the lag was the panel sitting *still* under a fade. Exit now mirrors the
  entrance on the emphasized-out token pair, gated so the drawer is never
  destroyed mid-animation (`PowerMenu._beginDismiss` pattern).

### Media slowness (`d1d9b54`) — CLOSED

Not the surface size. `Component.onCompleted: CavaService.claim()` **fork/execs
`/usr/bin/cava`** on the first frame of the switch animation, followed by 60
`ShapePath`s tessellating at 60fps. Window-creation latency was equal across
tabs (23–36ms), which ruled out construction. The claim is deferred by one
motion duration; the condition is unchanged, only its timing.

### Non-uniform transition speed (`db35f2f`) — CLOSED

Measured via a temporary IPC rig (since removed; the surface no longer reflects
the panel size): Dashboard 760×826, Media 760×439, Performance 1040×448,
Weather 760×502. Fixed 250ms over distances of 63–470px gave a **7.5× speed
spread** across transitions (43× on the height axis alone).

Duration now derives from distance, clamped to the 187–375ms token range.
Five of six pairs land at 1278–1281 px/s — constant to within **0.3%** — with
only the 63px Media↔Weather move hitting the floor by design.

## Closing note

Six of the seven fixes in this task were found by measurement; the three that
went wrong all went wrong the same way — asserting a cause from a plausible
mechanism instead of instrumenting first. The jitter in particular cost three
attempts because each fix targeted the layer the *previous* symptom pointed at,
and only a direct geometry trace showed the surface itself was moving.

