---
status: testing
phase: 14-dashboard-drawer
source: [14-VERIFICATION.md, 14-REVIEW.md]
started: 2026-08-01T14:10:08Z
updated: 2026-08-01T14:10:08Z
---

## Current Test

number: 1
name: Calendar month navigation by chevron click (render gate — regression fix)
expected: |
  On the Dashboard tab, clicking the calendar header's prev/next chevrons steps
  the month. Scrolling the mouse wheel anywhere over the calendar card also
  steps the month, exactly as before. Neither interaction interferes with the
  other, and the day-grid cells still behave normally.
awaiting: user response

## Tests

### 1. Calendar month navigation by chevron click (render gate — regression fix)

expected: Clicking the calendar header's prev/next chevrons steps the month; mouse-wheel over the card still steps the month as before; day-grid cells unaffected.
result: [pending]

why: Code review found `calendarCard`'s wheel `MouseArea` (`anchors.fill: parent`, declared last among the card's children) was stacked above the prev/next chevrons and, with the default `acceptedButtons: Qt.LeftButton`, grabbed every click meant for them — so month navigation by click did nothing and only the wheel worked. The file's own comment claimed the MouseArea was "declared FIRST (paint order)" to prevent exactly this; it never was. Fixed in commit `9d9feb5` with `acceptedButtons: Qt.NoButton`. This is a rendered-surface behaviour change, so it needs the standing blocking human render-and-look sign-off.

### 2. Swipe indicator alignment at all four tab indices

expected: The indicator's leading/trailing edge lands flush with the active tab label at all four indices — no visible overshoot past index 3's position, and no sub-pixel gap at any index.
result: [pending]

test: Drag to each of the four tab indices and release exactly at rest (no residual velocity); zoom into the header indicator at each of the four positions.
why: 14-03 must_have tagged `verification: backstop`. Sub-pixel alignment and overshoot are a rendered-pixel judgement. The render gates confirmed general threshold-commit / spring-back behaviour, but no committed gate or SUMMARY records this pixel-level claim being checked.

### 3. Long track title elides on the Media tab

expected: Title and artist each elide with an ellipsis on one line; the tab's fixed-height frame does not grow, shrink, or reflow.
result: [pending]

test: Play a track with a long title and/or artist (e.g. a classical piece with a long composer credit, or a podcast episode title) and observe the Media tab.
why: 14-05 must_have tagged `verification: backstop`. 14-09's Task 4 check 7 exercised play/pause/seek/switch-player but did not call out a long-title elide case.

### 4. Performance tab network rate row holds width at worst case

expected: The row's fixed-width formatting absorbs the longest realistic value (e.g. "999.9 MB/s") with no layout shift, wrap, or reflow.
result: [pending]

test: Generate sustained heavy network traffic (large download/upload) so the up/down rate readout reaches its longest realistic string, and watch the row.
why: 14-06 must_have tagged `verification: backstop`. 14-10's Task 4 confirmed the row was re-centred and widened and states the anti-reflow guarantee held under that change, but no session recorded feeding it an actual worst-case value string. The claim currently rests on the fixed-width formatter's design, not an observed worst-case render.

### 5. Compact media widget title elides at compact width

expected: Title elides with an ellipsis inside the widget's fixed-width slot; nothing shifts or wraps.
result: [pending]

test: Play a track with a long title while the Dashboard tab's compact media widget is visible.
why: 14-08 must_have tagged `verification: backstop`. No SUMMARY records this test against the compact (not full-player) widget specifically.

### 6. Weather tab no longer compresses into place on entry (render gate — regression fix)

expected: Switching Performance → Weather, the weather content is at its final width from the first frame; the frame closes around it. No visible squeezing-together of the 8 hour cells or 5 day cells during the transition. At rest the Weather tab looks exactly as before (frame 760x514, content 664px wide).
result: [pending]

why: Reported live as "visible jitter/lag switching to Weather that wasn't there before". Root-caused to the content being `anchors.fill: parent` and therefore re-laid-out on every frame of the resize — measured at 15 relayouts, 992px→712px. Introduced indirectly by 14-09 widening Performance (2×2 dial grid → one wide row), which flipped Weather's entry from a ~200px expansion into a ~280px compression. Fixed in commit `4135aeb`. One relayout remains at construction by design — see the commit message.

### 7. Threaded render loop — smoothness and stability (render gate + soak)

expected: All drawer animation is visibly smoother than before. No tearing, no flicker, no crash or disappearing surface across a normal session including theme switches, motion-scale changes, and repeated summon/dismiss.
result: [pending]

why: Qt was auto-selecting the basic render loop, running animation on the GUI thread at ~60fps on this 165Hz panel. `QSG_RENDER_LOOP=threaded` measured a 16ms→6ms frame cadence on both the render thread and the GUI thread's polish phase (commit `2642e68`). The threaded loop is the more demanding option on an NVIDIA + Wayland host: one session was exercised clean, but this item exists because one session is not a soak. Revert is a single commented-out line in `quickshell-launch.sh`.

### 8. Animated gradient border matches Hyprland's window border (DASH-10 — render gate)

expected: The drawer carries a 3px gradient rim in the same pink→purple→cyan stops as a focused window's border, rotating continuously at visibly the same rate as Hyprland's own borders. It should read as the same treatment, not merely a similar one — put a focused window beside the open drawer and the two rims should stay in step rather than drifting apart. The rim follows the drawer's shape: square at the top corners, rounded at the bottom. Switching theme re-colours it along with everything else. Setting motion-scale to `off` leaves it a still gradient rather than a spinning one.
result: [pending]

why: New scope (DASH-10), minted during this UAT at your direction. Every value is a token or a live Hyprland setting rather than a taste call — stops are `Colours.primary`/`secondary`/`tertiary` (byte-identical to `general:col.active_border`), width tracks `general:border_size`, and the period is the same `border-rotate` token `borderangle` consumes, ceiling-clamped so the two stay in sync at non-default motion scales. Verified by screenshot that it renders, rotates and follows both corner styles; the *aesthetic* judgement and the side-by-side parity check are yours. Worth watching: this is the drawer's first continuously-running animation, so if it costs anything perceptible in GPU or battery while the drawer sits open, say so — it is gated behind one property (`active`) and a whole component, so it reverts cleanly.

## Summary

total: 8
passed: 0
issues: 0
pending: 8
skipped: 0
blocked: 0

## Gaps
