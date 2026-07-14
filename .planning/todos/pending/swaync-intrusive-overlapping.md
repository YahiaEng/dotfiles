---
id: swaync-intrusive-overlapping
created: 2026-07-15
severity: high
source: 08-12 UAT checkpoint (user-reported)
affects_plans: [08-09]
status: pending
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
