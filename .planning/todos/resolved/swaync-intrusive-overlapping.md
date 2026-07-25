---
id: swaync-intrusive-overlapping
created: 2026-07-15
severity: high
source: 08-12 UAT checkpoint (user-reported)
affects_plans: [08-09]
status: resolved
resolved: 2026-07-25
resolved_by: [08-15, bedb01d]
resolution: >
  Both reported bugs are fixed in the working tree; only this tracking file
  was stale. (1) Intrusive / no blur — swaync/.config/swaync/style.css:4-14
  now sets `.control-center { background: alpha(@background, 0.72); border:
  1px solid alpha(@primary, 0.25); }`, replacing the opaque @background and
  the 3px chroma slab, with an inline comment naming this exact bug. The
  compositor half is present too: hypr/.config/hypr/config/windowrules.conf
  lines 189-190 carry `layerrule = blur on` for both swaync-control-center
  and swaync-notification-window, and lines 270-271 carry the matching
  `ignore_alpha 0.5` — and the 0.72 alpha clears that threshold, so blur
  applies. (2) Overlapping boxes — style.css:118-136 is the labelled "ONE box
  per notification (08-15 fix)" block: .notification-row,
  .notification-background and the .notification-group variants are forced
  inert (background transparent, border none, box-shadow none) and the box is
  painted on .notification only (line 138). The second-level rule that
  produced the stacked offset boxes is gone. Reconciled at v2.0 milestone
  close.
---

# swaync control centre is intrusive; notifications render as overlapping boxes

**Reported:** User, at the 08-12 visual checkpoint: "The notification center
module is intrusive (it should have a blurry background) ... the actual
notifications inside the notification center look bugged (multiple overlapped
background boxes)."

**Root cause (verified 2026-07-15) — two separate bugs:**

1. **Intrusive / no blur.** `swaync/.config/swaync/style.css` line 5:
   `.control-center { background: @background; border: 3px solid @primary; }`
   — fully opaque, plus a 3px chroma border.
   NOTE: CSS cannot blur a GTK layer-shell surface. Blur must come from the
   compositor: `layerrule = blur, swaync` in the Hyprland config, PAIRED with
   a translucent `.control-center` background so there is something to blur
   through. A CSS-only fix is impossible.

2. **Overlapping background boxes.** swaync's DOM nests
   `.notification-row > .notification-background > .notification`. style.css
   paints an opaque background AND a border at TWO levels:
     - line 119: `.notification { background: @surface_variant; border: 2px solid @outline; }`
     - line 171: `.notification-row .notification-background .notification { background: @background; border: 2px solid @primary; }`
   Result: two stacked, offset boxes with two visible borders.

Plan 08-09 is marked COMPLETE. Its gates only ever proved colour-token
resolution, never appearance — the same blind spot that produced this whole
gap-closure round.

**Fix needed:** collapse background painting to ONE level of the swaync DOM,
make `.control-center` translucent, and add the Hyprland `layerrule = blur, swaync`.
