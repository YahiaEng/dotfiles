---
status: resolved
trigger: "this is important for all panels not just wifi, they need to have the same animated colored border as the rest of dashboard."
created: 2026-08-02T08:00:00Z
updated: 2026-08-10T00:00:00Z
---

## Current Focus

hypothesis: CONFIRMED — `GradientBorder` (DASH-10, phase 14) is instantiated at exactly one
  call site (Dashboard.qml:387). `PanelDialog.qml`, the shared frame all three panels are
  constructed FROM, declares a background `Rectangle` with NO border of any kind and never
  instantiates `GradientBorder`. This is a missing-reuse omission, not a runtime fault.
test: source enumeration (grep across the whole quickshell tree) + live A/B screenshot of the
  wifi panel vs the dashboard drawer at identical crop/zoom + an isolated qml6 experiment
  proving the `default property alias` does not capture same-file children.
expecting: exactly one GradientBorder call site; zero border declarations in PanelDialog.
next_action: return diagnosis (goal: find_root_cause_only — do NOT fix)

bug_class: Bohrbug (fully deterministic — the border is absent on every open of every panel;
  it is a static composition omission, reproducible 100% of the time)

reasoning_checkpoint:
  hypothesis: "The three panels lack the animated rim because PanelDialog.qml — the single
    shared frame all three are built from — never instantiates GradientBorder, and declares
    no border property on its background Rectangle. The component exists and is registered,
    but has exactly one consumer (Dashboard.qml)."
  confirming_evidence:
    - "grep -rn GradientBorder over the whole quickshell tree returns exactly one
       instantiation: Dashboard.qml:387. All other hits are the definition, the qmldir
       registration, and two comments."
    - "PanelDialog.qml:157-174 — the background Rectangle sets topLeft/topRight/bottomLeft/
       bottomRightRadius and color only. No border.width, no border.color, no Shape, no rim."
    - "Live A/B at identical 200% zoom on the same 300x120 bottom-left corner region: the
       drawer shows the pink->purple gradient rim tracing the 28px corner arc; the wifi panel
       shows bare surface with no rim pixel anywhere."
  falsification_test: "If any of the three panel files (AudioPanel/WifiPanel/BluetoothPanel)
    or PanelDialog.qml contained a GradientBorder instance or a border.* declaration, the
    hypothesis would be wrong. grep over all four files finds neither."
  fix_rationale: "N/A — diagnose-only mode. The root cause is an omission in one shared file;
    the fix direction is to add the component that already exists, not to change behaviour."
  blind_spots: "Not tested: whether adding a Shape+CurveRenderer rim to three additional
    layer surfaces has a measurable frame-time cost when several are open (they cannot be —
    HyprlandFocusGrab is exclusive per-compositor on this build, so at most one panel is up
    at a time, and each is destroyed on dismiss)."
  candidate_causes:
    - "code — PanelDialog.qml never instantiates GradientBorder (CONFIRMED, primary)"
    - "config — motion.json's border-rotate token missing or Motion.motionEnabled false,
       which would leave the rim static rather than absent (RULED OUT: the drawer's rim is
       visibly present and the token resolves; and absence, not stillness, is the symptom)"
    - "environment — Qt6 Shapes lacking PathRectangle/per-corner radius blocking reuse at
       panel radii (RULED OUT: GradientBorder already works around this with a hand-built
       SVG path taking four independent corner radii)"
  and_gate: "no — a single missing instantiation fully explains the symptom on all three
    panels simultaneously, because all three inherit their entire frame from one file. No
    second condition is required: adding the component to that one file would have shipped
    the rim on all three at once, and its absence there is sufficient to remove it from all
    three at once."

## Symptoms

expected: Every panel (wifi, bluetooth, audio) renders with the same animated colored border used by the dashboard drawer.
actual: Panels render with no border at all — not a different border, not a static one: zero rim geometry. The translucent surface simply ends at the frame edge.
errors: None reported. None found in the shell log either — nothing fails at runtime; the component is simply never constructed for these surfaces.
reproduction: `qs ipc call panel toggle wifi` (or the Wi-Fi tile chevron), then compare the frame edge to the dashboard drawer (Super+D). Test 1 in .planning/phases/15-audio-connectivity-panels/15-UAT.md.
started: Panels were introduced in phase 15 (15-02 built PanelDialog). The border component was built in phase 14 (DASH-10) and was only ever wired to Dashboard.qml. The panels have never had it.

## Eliminated

- hypothesis: "The panels apply a different/static border that merely looks wrong"
  evidence: PanelDialog.qml:157-174's background Rectangle declares no `border` property at
    all, and grep finds no `border.width`/`border.color`/`Shape` in PanelDialog.qml,
    AudioPanel.qml, WifiPanel.qml or BluetoothPanel.qml. The live screenshot confirms bare
    surface at the corner. The border is absent, not mis-styled.
  timestamp: 2026-08-02T08:20:00Z

- hypothesis: "GradientBorder is coupled to drawer-specific geometry (animated resize,
    drawer-only corner radii) and cannot be reused at panel dimensions"
  evidence: GradientBorder is a bare `Item` whose only geometric inputs are its own
    width/height (from anchors.fill) and four independent per-corner radius properties. The
    `_ringPath` binding recomputes from root.width/root.height, so it follows a resize but
    does not require one. It already renders correctly at three different drawer sizes
    (760x826 Dashboard tab, 1040x450 Performance tab, 760x514 Weather tab). Panel geometry
    (850x620) is inside that range with an IDENTICAL corner configuration.
  timestamp: 2026-08-02T08:30:00Z

- hypothesis: "Qt6 Shapes' lack of PathRectangle / per-corner radius blocks reuse at panel
    corner radii"
  evidence: GradientBorder.qml:110-147 documents that exact constraint and already works
    around it — `_roundedRect(x,y,w,h,tl,tr,br,bl)` builds the SVG path in JS with four
    independent radii and conditionally omits the arc when a radius is 0, precisely so the
    drawer's two square + two round corners work. The panel's corner set (0/0/28/28) is
    byte-identical to the drawer's, so this is the exact case the workaround was written for.
    The constraint is already solved, not a reuse blocker.
  timestamp: 2026-08-02T08:32:00Z

- hypothesis: "A GradientBorder declared inside PanelDialog.qml would be swallowed by
    `default property alias body: bodyContent.data` (PanelDialog.qml:64) and land inside the
    scrollable body Column instead of on the frame"
  evidence: Isolated qml6 6.11.1 experiment reproducing the exact alias shape. A child
    declared in the SAME file as the alias stays a direct child of the root; only call-site
    children are captured. Exit code 0 (all three assertions pass). Poison-proven: forcing
    the same-file child into the slot yields exit 5, restoring yields 0 — the harness can
    fail. Corroborated in-tree: PanelDialog.qml already declares `background`, `grab`,
    `content` and `advancedProcess` as bare same-file children and the panels render
    correctly (a capture would have produced a parent cycle, since `bodyContent` is a
    descendant of `content`).
  timestamp: 2026-08-02T08:40:00Z

## Evidence

- timestamp: 2026-08-02T08:10:00Z
  checked: knowledge base (.planning/debug/knowledge-base.md) and MemPalace
  found: No knowledge base file exists yet; no prior resolved session matches these symptoms.
  implication: No known-pattern shortcut; investigate from first principles.

- timestamp: 2026-08-02T08:12:00Z
  checked: `grep -rn "GradientBorder" .` over quickshell/.config/quickshell
  found: 5 hits total — GradientBorder.qml:1 (definition header), modules/dashboard/qmldir:39
    (comment) and :70 (registration `GradientBorder 1.0 GradientBorder.qml`),
    Dashboard.qml:235 (comment) and Dashboard.qml:387 (THE ONLY INSTANTIATION).
  implication: Exactly one consumer in the entire tree. The component is registered and
    reachable, but nothing except the drawer ever constructs it.

- timestamp: 2026-08-02T08:14:00Z
  checked: modules/dashboard/GradientBorder.qml in full (204 lines)
  found: Root type `Item`. Public API — `borderWidth: int = 3`, `startAngle: real = 45`,
    `topLeftRadius`/`topRightRadius`/`bottomLeftRadius`/`bottomRightRadius: real = 0`,
    `active: bool = true`, `angle: real`. Consumer applies it by declaring the component,
    setting `anchors.fill: parent`, and handing across the same four radii its background
    Rectangle uses. Draws a real two-subpath rounded-rect ring via `Shape` +
    `ShapePath.OddEvenFill` + `Shape.CurveRenderer` (analytic AA), gradient stops
    Colours.primary/secondary/tertiary, rotation via `NumberAnimation on angle`
    gated on `Motion.motionEnabled && root.active`, period `Motion.borderRotateDuration`.
  implication: Fully generic, self-contained, zero drawer-specific assumptions. Colour and
    motion both come from tokens, so it re-themes and respects motion-scale for free.

- timestamp: 2026-08-02T08:16:00Z
  checked: modules/Dashboard.qml:377-394 (the only call site) and :231/:239
  found: `GradientBorder { anchors.fill: parent; borderWidth: dashboardWindow.borderWidth;
    topLeftRadius: 0; topRightRadius: 0; bottomLeftRadius: dashboardWindow.cornerRadius;
    bottomRightRadius: dashboardWindow.cornerRadius }` — a 7-line declaration. Declared AFTER
    `background` (so it paints on top of the surface) and BEFORE `content` (so it never
    overlays the tab bar). Dashboard declares `readonly property int cornerRadius: 28` and
    `readonly property int borderWidth: 3`.
  implication: The whole consumer-side integration is 7 lines plus one constant, at one
    documented position in the child order.

- timestamp: 2026-08-02T08:18:00Z
  checked: modules/dashboard/PanelDialog.qml in full (369 lines), specifically :74 and :156-174
  found: `readonly property int cornerRadius: 28` (line 74) — IDENTICAL to the drawer's.
    The background Rectangle (lines 157-174) sets `topLeftRadius: 0; topRightRadius: 0;
    bottomLeftRadius: cornerRadius; bottomRightRadius: cornerRadius` and a translucent
    `color` with a themed `Behavior on color` — and NOTHING ELSE. No `border.width`, no
    `border.color`, no Shape, no rim of any kind. PanelDialog also declares NO `borderWidth`
    property (Dashboard's `readonly property int borderWidth: 3` has no counterpart here).
  implication: ROOT CAUSE. The panels' shared frame paints a surface and stops. Its corner
    configuration (0/0/28/28 at radius 28) is byte-identical to the drawer's, so the
    existing component's radii map 1:1 with no new geometry work.

- timestamp: 2026-08-02T08:22:00Z
  checked: `grep -rn "PanelDialog" .` plus the root declaration of each panel file
  found: Three instantiations, all using PanelDialog as their ROOT type:
    AudioPanel.qml:74, WifiPanel.qml:34, BluetoothPanel.qml:34. Each sets only
    panelTitle/panelGlyph/namespaceSuffix/advancedCommand/advancedAvailable/
    advancedUnavailableReason. None declares a background, a border, or a frame of its own.
    shell.qml mounts each behind its own LazyLoader (audioPanelLoader:137,
    wifiPanelLoader:175, bluetoothPanelLoader:196).
  implication: All three panels inherit their ENTIRE frame from PanelDialog.qml. One
    insertion there reaches all three. Panel call sites needing change: ZERO.

- timestamp: 2026-08-02T08:26:00Z
  checked: Live A/B. `qs ipc call panel toggle wifi`, geometry read from `hyprctl -j layers`
    (quickshell-wifi-panel at 855,56 850x620), `grim -o DP-1` + crop. Then
    `hyprctl eval 'hl.dispatch(hl.dsp.global("quickshell:dashboard"))'`
    (quickshell-dashboard at 900,56 760x826), same capture path. Both bottom-left corners
    cropped 300x120 and upscaled 200%.
  found: Drawer corner — a saturated pink->purple gradient rim traces the full 28px corner
    arc, ~3px thick, unmistakable. Wifi panel corner — bare translucent surface, not a single
    rim pixel; the surface just ends.
  implication: Direct visual confirmation of the source reading, at identical zoom. The
    symptom is total absence, matching the grep-verified absence exactly.

- timestamp: 2026-08-02T08:40:00Z
  checked: Isolated qml6 6.11.1 experiment on `default property alias body: slot.data`
    (the exact shape of PanelDialog.qml:64), with a same-file child and a call-site child,
    result encoded in the process exit code (console output is suppressed in this shell).
  found: Exit 0 — (bit0) the same-file child is NOT captured by the alias; (bit1) the
    call-site child IS in the slot; (bit2) the slot holds exactly 1 item. Poison run
    (forcing the same-file child into the slot) exits 5; restoring exits 0.
  implication: A `GradientBorder {}` declared directly inside PanelDialog.qml becomes a real
    sibling of `background`/`content` — exactly Dashboard.qml's arrangement — and does NOT
    land inside the scrollable body. The reuse path is unobstructed.

- timestamp: 2026-08-02T08:44:00Z
  checked: Whether a 3px rim at the frame edge would collide with panel content. Design.qml
    `panelPadding: 24`; PanelDialog's `bodyFlick` uses `anchors.margins: panelPadding`;
    headerBand's identity Row and Advanced button both use `anchors.leftMargin`/
    `rightMargin: panelPadding`. The only full-bleed Rectangles in the three panel bodies
    (WifiPanel.qml:394, BluetoothPanel.qml:315, AudioPanel.qml:659) are 1px `Colours.outline`
    group dividers living inside `bodyContent`, itself inside the 24px-inset `bodyFlick`.
  implication: A 3px rim clears all panel content by 21px. No overlap, no reflow, no
    call-site adjustment needed.

- timestamp: 2026-08-02T08:46:00Z
  checked: Type resolution — can PanelDialog.qml reference `GradientBorder` by bare name?
  found: Both files live in modules/dashboard/. PanelDialog.qml already resolves two siblings
    by bare name with only `import "../"` in scope: `Cascade {}` (line 189) and `Design.*`
    (lines 138-152). GradientBorder is registered in the same qmldir (line 70).
  implication: No import change required in PanelDialog.qml.

## Resolution

root_cause: >
  `modules/dashboard/PanelDialog.qml` — the single shared frame that AudioPanel, WifiPanel and
  BluetoothPanel are all constructed FROM (each uses it as its root type) — paints only a
  translucent background `Rectangle` (lines 157-174) with rounded bottom corners and declares
  no border of any kind. It never instantiates `GradientBorder`, the animated gradient rim
  built in phase 14 (DASH-10). That component has exactly ONE consumer in the entire quickshell
  tree: `modules/Dashboard.qml:387`. Phase 15's `PanelDialog` was written by copying
  Dashboard.qml's layer posture, corner radii, surface opacity and theme-crossfade Behavior
  (its own header records this as "copied from Dashboard.qml and parameterized") but the
  GradientBorder block — which sits between `background` and `content` in Dashboard.qml — was
  not carried across. This is a shared-component reuse omission, not a runtime fault: nothing
  errors, the component is simply never constructed for these three surfaces.
fix: >
  `GradientBorder` was instantiated inside `PanelDialog.qml` between `background` and
  `content` in commit `4f48847` (`feat(15-10): instantiate GradientBorder inside
  PanelDialog.qml`, 2026-08-02 19:35:30, +24 lines, that file only), landing at
  `PanelDialog.qml:191`. All three panels inherit it from the shared frame with zero
  call-site changes — exactly the reuse path this session's own experiments predicted
  was unobstructed.
verification: >
  Two-part evidence. Static: `PanelDialog.qml:191` instantiates `GradientBorder`
  between `background` and `content`, confirmed by direct source read. Live: operator
  visually confirmed on 2026-08-10 that the audio, wifi and bluetooth panels all
  render the glowing rim. Note: this session sat at `status: diagnosed` for eight days
  after its own fix had already shipped, because the fix landed through the normal
  Phase 15 plan track (15-10) rather than through this session, and nothing closed the
  loop back to the frontmatter — that lag is the reusable lesson and belongs in the
  record.
files_changed:
  - quickshell/.config/quickshell/modules/dashboard/PanelDialog.qml
