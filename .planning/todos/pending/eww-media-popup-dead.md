---
id: eww-media-popup-dead
created: 2026-07-15
severity: high
source: 08-12 UAT checkpoint (user-reported)
affects_plans: [08-06, 08-07, 08-08]
status: pending
---

# eww media popup is bland and does not function

**Reported:** User, at the 08-12 visual checkpoint: "The media center module
looks so bland and does not function."

**Root cause (verified 2026-07-15):**
The `eww` daemon is NOT running, and `eww` does not appear anywhere in
`hypr/.config/hypr/config/autostart.conf`. Plan 08-06 landed the eww stow
package + matugen theming, 08-07 built the media popup widget, and 08-08
re-pointed every layout's media segment `on-click` to
`hypr/.config/hypr/scripts/media-popup-open.sh` — but nothing ever starts
`eww daemon`. Clicking the media segment therefore talks to a daemon that
does not exist and silently does nothing.

All three plans (08-06, 08-07, 08-08) are marked COMPLETE with SUMMARY.md
files. The gate suite never caught it because no gate asserts the daemon is
running or that the popup actually opens.

**Fix needed:**
1. Add eww daemon to `autostart.conf` (via `uwsm app --`, matching the
   walker/elephant pattern already used there).
2. Restyle `eww/.config/eww/eww.scss` to the translucent-island design
   language established in 08-12's `theme.css` (currently "bland").
3. Add a gate that asserts the popup actually opens — the absence of one is
   why this shipped broken.
