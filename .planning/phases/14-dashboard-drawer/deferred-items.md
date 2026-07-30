# Deferred Items — Phase 14 (dashboard-drawer)

Out-of-scope discoveries logged per the executor's scope-boundary rule: only
auto-fixed if directly caused by the current task's changes. Pre-existing
failures in unrelated subsystems are recorded here, not fixed.

## 14-03 Task 3 (render-gate revision pass, 2026-07-29)

- **`quickshell-doctor` FAIL: headless output remove (QS-03)** — "monitor
  count back to baseline (1 == 1), DP-1 probe still creatable (found: 0),
  shell PID unchanged (389777 == 389777), no crash marker in launcher log
  (hits: 0)". Observed while re-running `quickshell-doctor` as part of this
  plan's render-gate verification pass. This check exercises headless-monitor
  hotplug + `ScreencopyProbe` re-creatability (11-05 / QS-03 territory) —
  entirely unrelated to `modules/Dashboard.qml`'s per-tab dynamic sizing,
  which is the only surface this pass touched. Not investigated or fixed
  here; all other `quickshell-doctor` checks (namespace discipline, reserved-
  space non-claim across summon/dismiss, keybind-doctor, notifications
  ownership, hardware-key handler counts, MPRIS-writer count, hotplug
  reserved-space stability) passed clean both before and after this pass's
  edits.

## 14-06 Task 2 (Performance tab render-gate prep, 2026-07-29)

- **`Dashboard.qml`'s `activeContentWidth` does not shrink the drawer frame
  when navigating BACKWARD (arrow-Left) from a wider tab to a narrower one —
  only the height updates.** Reproduced live and cleanly isolated: from a
  freshly-restarted shell, summoning the drawer and stepping forward
  Dashboard(1008x572) -> Media(760x424) -> Performance(760x690) ->
  Weather(1068x512) via repeated `Right` correctly resizes the frame at
  every step. Stepping back ONE tab with `Left` (Weather -> Performance)
  settles at `w=1068, h=690` — Weather's width frozen alongside Performance's
  own correct height — and stays there indefinitely (checked at +1.5s and
  +6s, well past `Motion.standardDuration`). Performance's own content is
  confirmed correct throughout (real CPU/memory/storage/battery/network
  values render at the right positions) — this is a frame-sizing defect in
  `Dashboard.qml`'s `activeContentWidth`/Loader-priority mechanism itself,
  not in `PerformanceTab.qml`. Out of this plan's ownership fence
  (`Dashboard.qml` is 14-03's frozen file); not investigated further or
  fixed here. Flagged to the render-gate checkpoint and to 14-08/14-09 as a
  pager-level bug affecting every tab pair, not something specific to the
  Performance surface.

  **RESOLVED by 14-09 Task 4 (2026-07-30):** re-tested with Performance at
  its new non-floor width (1040px, one-row-of-four dial layout) — the first
  tab pair in the whole phase where the width axis is actually live rather
  than pinned at the shared 760 floor. Forward `760/826 → 760/424 →
  1040/498 → 760/514` and backward the exact reverse: no stuck width in
  either direction. A rapid mid-transition poll during a live
  Performance→Weather swipe captured genuine animated intermediate values
  (`1040→1011→928→870→833→808→791→779→768→762→760` on `Behavior on
  implicitWidth`), collapsing to a hard jump at `off` motion scale (zero
  intermediates) and tightening correctly at `reduced` (5 samples vs 8 at
  `normal`). The mechanism this item originally flagged as broken now
  handles a genuinely non-floor width correctly; no `Dashboard.qml` change
  was needed. Full evidence in `14-09-SUMMARY.md` Task 4 section B2.

## 14-09 Task 4 (phase-close render-gate approval, carried-forward requests, 2026-07-30)

Two follow-up requests the human raised at the Task 4 re-gate approval.
Both are deliberately NOT implemented in this plan — both are new scope,
and one touches a file outside 14-09's declared `files_modified`. Recorded
here with enough technical detail that a future planner does not have to
re-derive the findings.

### Item A — two-tone the composite weather glyphs

The human noticed the "sunny with clouds" glyph (`partly_cloudy_day` /
`partly_cloudy_night`) renders entirely white and asked whether the sun
could be yellow while the clouds stay white, within the same glyph.

**Finding, verified directly this session, not to be re-derived:** the
installed `MaterialSymbolsRounded[FILL,GRAD,opsz,wght].ttf` has **no COLR,
no CPAL and no SVG table** — it is a pure monochrome `glyf` outline font.
Each condition (including the composite ones) is a single glyph, and a
text-rendered glyph takes exactly one colour, so per-path colouring inside
one glyph is structurally impossible with this font. The current
single-tone result is the only thing that glyph can produce as-is.

Three routes, in recommended order:

1. **Recommended — layer two glyphs.** Render `wb_sunny` in
   `WeatherPalette.sun` beneath `cloud` in `WeatherPalette.cloudLit`,
   offset so the cloud overlaps the sun's lower portion. Keeps the icon
   font and keeps both colours themeable via the existing `WeatherPalette`
   singleton this plan added. Scope strictly to the two composite
   conditions (`partly_cloudy_day`, `partly_cloudy_night`) — every other
   condition is a single-concept icon already correctly single-coloured.
   **Honest caveat to carry forward:** Material's composite glyph is
   purpose-drawn with its two elements balanced by a designer; a
   hand-offset stack of two independent glyphs may read WORSE — the filled
   cloud will occlude part of the sun unless offset and relative sizes are
   tuned carefully. Treat this as an experiment with "revert to
   single-tone" as the defined fallback, and put it through its own render
   gate before accepting it.
2. Inline SVG or `QtQuick.Shapes` per condition — true per-path colour on a
   purpose-drawn shape, but means authoring/vendoring 8+ icons and
   abandoning the icon font for weather specifically.
3. A COLRv1 colour icon font — a second font dependency in a different
   visual language from the rest of the drawer; against the grain of this
   stack's existing icon-font convention.

### Item B — a fifth dial for GPU usage on the Performance tab

The human asked for a GPU-usage dial, explicitly requesting that the dial
size shrink so it fits without cramming and without increasing panel
width.

**Findings, verified directly this session:**

- `nvidia-smi` is present at `/usr/bin/nvidia-smi` and reports what is
  needed: `NVIDIA GeForce RTX 3070, 28 %, 825 MiB, 8192 MiB` via
  `--query-gpu=name,utilization.gpu,memory.used,memory.total
  --format=csv,noheader`.
- The sizing arithmetic closes exactly with **no panel-width change**. The
  dial row is currently 4 x `dialDiameter 224` + 3 x `spacingMd 16` = 944
  content -> 1040 frame (per 14-09 Task 4's own B1 measurement). For five
  dials in that same 1040-wide frame: `5d + 4*16 = 944` -> **d = 176**,
  with ring thickness scaling proportionally from the current `22`:
  `22 * (176/224) ~= 17`. These numbers are the starting point for the
  next plan, not to be re-derived.

**Two reasons this needs its own plan rather than a late addition here,**
both recorded as open questions for it:

1. It extends `SystemResources.qml`, which belongs to plan 14-06 and is
   outside 14-09's declared `files_modified` — an edit here would be scope
   creep on the last commit of the phase, exactly the class this plan's
   own "Ownership fence" section warns against.
2. `nvidia-smi` is a **subprocess spawn per sample**, unlike the `/proc`
   reads every other metric in `SystemResources.qml` uses. It needs a
   deliberate sampling design against that module's zero-idle polling
   architecture, not a naive timer reusing the existing poll interval.
3. It needs a **D-41 widget-state answer for a machine with no NVIDIA
   GPU** — not optional, given this project's "installable on a fresh Arch
   system, no host-only state" constraint (`.claude/CLAUDE.md`
   Constraints). The battery dial's existing "no battery" placeholder
   (Task 4 check 8, this same plan) is the precedent to follow: a designed
   empty/absent state, not a broken dial.
