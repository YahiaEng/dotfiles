# Phase 15: Audio + Connectivity Panels - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-01
**Phase:** 15-audio-connectivity-panels
**Areas discussed:** Entry points & placement, Shared panel frame (PANEL-06), Audio panel composition, Wifi + bluetooth flows, Dashboard tab fit budget, Advanced-target robustness, Coexistence & single-owner proof, Per-panel empty & degraded states

**Standing instruction from the user, applied from the second question onward:**
*"Dig deeper into the pros and cons of each option and recommend the best choice. Do this for every question in the discussion before presenting it to me."*
Every question below was preceded by a written trade-off analysis and an explicit recommendation.

**Standing design lens, restated mid-discussion:**
*"When it comes to the UI/design elements, always keep in mind our references (caelestia shell and end4)."*

---

## Entry points & placement

### Q1 — Reachability from the dashboard's quick-toggle grid

| Option | Description | Selected |
|--------|-------------|----------|
| Split tiles: press toggles, expand opens | Press body = the one obvious verb; chevron opens the panel. Android-QS idiom, end-4/Caelestia precedent. Grid grows to 6 chips. | ✓ |
| Plain tiles: press opens the panel | No inline toggle verb. Same vertical cost, simpler, but wastes the tile's state-display value. | |
| Don't touch the grid | Keybinds/waybar only. No fit-budget risk, but walks away from the roadmap's "expand targets" framing. | |

**User's choice:** Split tiles
**Notes:** Gives the grid its first genuinely stateful tiles. Consequence flagged at ask time: 6 chips would mean two rows, eating D-05's slack — later resolved by Q13 (one row of six).

### Q2 — Panel render shape and drawer fate

| Option | Description | Selected |
|--------|-------------|----------|
| Own surface; drawer dismisses | Independent layer surface per panel; the compositor's exclusive grab performs the handoff for free. | ✓ |
| In-place detail view in the drawer | One surface, one grab; sidesteps grab exclusivity, but binds panels to drawer geometry and D-04, leaves Phase 16 nothing. | |
| Own surface; drawer stays behind | Needs either dropping the drawer's grab or hoisting a shared grab to shell root, restructuring gate-passed code. | |

**User's choice:** Own surface; drawer dismisses
**Notes:** An earlier framing of this question was rejected by the user for insufficient depth. Re-asked after verifying Phase 11's Finding 2 (`hyprland_focus_grab_v1` exclusive per-compositor, verified in both orders) and reading `Dashboard.qml:419`. The corrected analysis showed option 3 was the *most* expensive, not the cheapest, and that D-13 describes the platform rather than imposing policy.

### Q3 — On-screen anchor

| Option | Description | Selected |
|--------|-------------|----------|
| Top-center, drawer's width | Panel appears where the drawer was; inherits D-03 verbatim; one anchor correct under all four waybar layouts. | ✓ |
| Top-center, narrower (~560px) | More dialog-like, better for lists, but makes the handoff a jump-cut and adds a second width constant. | |
| Top-right under the bar's status cluster | Matches swaync/status-popout idiom, but `group/audio`/`group/connections` sit on the LEFT edge under the vertical layout — needs the layout-state read D-03 deferred. | |

**User's choice:** Top-center, drawer's width
**Notes:** The vertical-layout finding was discovered by reading the waybar configs during the question's preparation.

### Q4 — Dedicated global keybinds

| Option | Description | Selected |
|--------|-------------|----------|
| Super+A for audio only | One bind where frequency justifies it; keeps D-09's first-letter convention intact. | ✓ |
| All three bound | Complete coverage, but forces Super+Shift+W/B alongside a plain Super+A — inconsistent chords for sibling panels. | |
| No dedicated keybinds | Cleanest namespace, but makes the drawer a mandatory waypoint for the mixer. | |

**User's choice:** Super+A for audio only
**Notes:** Free plain-Super letters were enumerated from `keybinds.lua` before asking: A, G, H, J, K, M, O, U free; W, B, V all taken. Requires one documented sentence so the asymmetry reads as deliberate.

### Q5 — waybar click rewiring

| Option | Description | Selected |
|--------|-------------|----------|
| Rewire manager-clicks only | network/bluetooth left-click and group/audio right-click → panels; audio's mute and BT's rfkill preserved; GUI apps live only behind Advanced. | ✓ |
| Rewire, keep GUI app on other button | Safer against quickshell-down, but duplicates Advanced's job and spends BT's useful rfkill right-click. | |
| No waybar changes this phase | Smallest blast radius, but leaves the bar pointing at the three apps this phase displaces. | |

**User's choice:** Rewire manager-clicks only
**Notes:** Discovery during preparation — athena deliberately removed `tray` (config comment lines 34-38), so its `nm-applet --indicator` click has no tray to render into and is already inert on the primary layout.

---

## Shared panel frame (PANEL-06)

### Q6 — Frame anatomy and Advanced placement

| Option | Description | Selected |
|--------|-------------|----------|
| Header band: title + Advanced | One chrome band, body fills below; no close button (inherits D-10). Labeled, not glyph-only. | ✓ |
| Header for identity, Advanced in a footer | More conventional placement (Android/GNOME), most discoverable, but two chrome bands and a permanent footer. | |
| Header + footer with explicit Close | Most dialog-like, but contradicts D-10's chrome-free dismissal. | |

**User's choice:** Header band: title + Advanced
**Notes:** Labeled-not-glyph applies Phase 14's render-gate lesson directly. Mis-click risk (top-right reads as close) carried to the render gate.

### Q7 — Height and overflow

| Option | Description | Selected |
|--------|-------------|----------|
| One fixed height, scrollable body | Same frame, three contents; immune to progressive-scan growth; one geometry constant. | ✓ |
| Content-sized with a max cap | Best proportions, no dead space, but the surface grows under the cursor during a wifi scan. | |
| Fixed height per panel type | Solves growth and dead space, but three geometry constants and the panels stop reading as one component. | |

**User's choice:** One fixed height, scrollable body
**Notes:** Established that the D-05 scroll exemption is **wider** than Phase 14 predicted — all three panels have unbounded content, not just the mixer.

### Q8 — Entrance cascade

| Option | Description | Selected |
|--------|-------------|----------|
| Cascade the frame, list renders whole | 3-5 elements inside D-21's 700ms fence; reuses the existing stagger token. | ✓ |
| Layer slide only (D-20), no cascade | Fastest to a usable control, but panels become the only family surfaces without the signature entrance. | |
| Full cascade including list items | Most striking, but 20 networks at 30-50ms offsets breaks D-21's own fence, and staggering async arrivals is incoherent. | |

**User's choice:** Cascade the frame, list renders whole
**Notes:** Rejected on arithmetic, not taste. Avoiding a new token also avoids re-opening Phase 12's D-25 growth policy.

### Q9 — Failure presentation

| Option | Description | Selected |
|--------|-------------|----------|
| Inline on the affected row | Fourth widget state; carries Networking's real `reason`; composes with the wifi retry flow. | ✓ |
| Frame-level status band | One place to style and look, covers panel-scoped failures, but can't identify which row failed. | |
| Route failures to swaync notifications | Reuses an existing channel, but builds a fresh v3.0 dependency on a deprecation target. | |

**User's choice:** Inline on the affected row
**Notes:** Verified `connectionFailed` + `reason` exist on the Networking surface. Bluetooth has no equivalent — flagged as research item 1.

---

## Audio panel composition

### Q10 — Panel layout

| Option | Description | Selected |
|--------|-------------|----------|
| Pinned controls, scrolling app list | Scrolls exactly what's unbounded; highest-frequency controls always reachable. | ✓ |
| One scrolling column with sections | Simplest, but master volume can scroll out of view. | |
| Segmented sub-views (Playback \| Devices) | Full height per view, but hides half the panel and adds a second navigation model. | |

**User's choice:** Pinned controls, scrolling app list

### Q11 — Device picker shape

| Option | Description | Selected |
|--------|-------------|----------|
| Expandable inline rows | No popup at all; reuses the chevron-expand idiom from the grid tiles. | ✓ |
| Dropdown / ComboBox | Most compact, but depends on unverified QtQuick-Popup-in-layer-shell behavior. | |
| Always-expanded radio lists | Maximum transparency, but 4-8 permanent rows crowd the app list and scale badly. | |

**User's choice:** Expandable inline rows
**Notes:** Chosen partly to avoid needing to answer the Qt popup question at all (standing constraint 2).

### Q12 — Per-app row anatomy

| Option | Description | Selected |
|--------|-------------|----------|
| Icon-as-mute + name + slider | Literal PANEL-01 reading; most compact; muted state carried twice plus tooltip. | ✓ |
| Icon + name + slider + mute button | Self-evident and matches pavucontrol, but a fourth element cramps the slider. | |
| Add a live peak meter | Uses Pipewire's `peaks`; most alive, but continuous repaint and polish rather than requirement. | |

**User's choice:** Icon-as-mute + name + slider

### Q13 — Input/mic scope

| Option | Description | Selected |
|--------|-------------|----------|
| Device selection + mic mute *(recommended)* | Gain is set-once, mute is moment-to-moment; cheap, no new backend. | |
| Device selection only | Exactly PANEL-02, cleanest discipline, but omits a most-wanted control. | |
| Full symmetry: device + level + mute | Input block mirrors output exactly; furthest from the requirement, spends scarce pinned-block height. | ✓ |

**User's choice:** **Full symmetry — user OVERRODE the recommendation.** Verbatim: *"Full symmetry — input device + level slider + mic mute. If it proves to be too cluttered then fallback to Device selection + mic mute."*
**Notes:** Second recorded override in the project's history (cf. Phase 14 D-31). The user supplied their own fallback condition unprompted; recorded as a pre-agreed render-gate escape in the shape of D-07's blur fallback, so the gate has an authorized action rather than needing a new decision.

---

## Wifi + bluetooth flows

### Q14 — Password entry

| Option | Description | Selected |
|--------|-------------|----------|
| Inline expanding row | Third use of the press-to-reveal idiom; composes with inline failure for retry. | ✓ |
| Modal card overlay in the panel | Focused and unambiguous, but a modal inside a dialog, hides the list, still needs Esc semantics. | |
| Dedicated sub-view | Most room, but heaviest navigation for one short string and needs a back affordance. | |

**User's choice:** Inline expanding row
**Notes:** Named consequence — Esc becomes two-stage. Security rationale recorded: `connectWithPsk` keeps the PSK off the command line, unlike an nmcli wrapper which would expose it in `/proc/<pid>/cmdline`.

### Q15 — Scan cadence

| Option | Description | Selected |
|--------|-------------|----------|
| Scan while open, stop on dismiss | Zero-idle doctrine of D-32/D-36; live list; indeterminate line under the header. | ✓ |
| Scan once on open, manual refresh after | Stable by construction, but goes stale silently and misleads. | |
| Manual scan only | Fully explicit, but an empty list on open is worse than the tools being displaced. | |

**User's choice:** Scan while open, stop on dismiss

### Q16 — List ordering

| Option | Description | Selected |
|--------|-------------|----------|
| Grouped: current, saved, then rest | Signal shown but never sorts; churn eliminated structurally. | ✓ |
| Live sort by signal strength | Most honest ordering, but maximizes churn and needs hysteresis tuning. | |
| Alphabetical by SSID | Perfectly stable, but buries your own network and ignores signal. | |

**User's choice:** Grouped: current, saved, then rest

### Q17 — Advanced boundary

| Option | Description | Selected |
|--------|-------------|----------|
| Required actions + wifi forget | Closes the typo trap (NM saves profiles with wrong passphrases) at the cost of one row action. | ✓ |
| Strictly the listed criteria only | Smallest surface, but knowingly ships the typo trap. | |
| Fuller control set | Fewer trips to the real apps, but contradicts criterion 4's "deliberately limited scope". | |

**User's choice:** Required actions + wifi forget
**Notes:** Forget must get destructive-action treatment, not a position next to connect — honored later by Q19.

### Q18 — Bluetooth discovery and grouping

| Option | Description | Selected |
|--------|-------------|----------|
| Paired immediately, discovery opt-in | No radio activity on open; grouping connected → paired → discovered mirrors wifi's grammar. | ✓ |
| Discovery always on while open | Symmetric with wifi, but BT inquiry can stutter the A2DP stream the panel manages. | |
| Discovery on open, auto-stop after a burst | Bounded cost, but still fires inquiry when audio is likely playing and needs an unprincipled timeout. | |

**User's choice:** Paired immediately, discovery opt-in
**Notes:** A deliberate asymmetry with the wifi panel, recorded with its reason so it doesn't read as inconsistency later.

### Q19 — Bluetooth device row

| Option | Description | Selected |
|--------|-------------|----------|
| Press for verb, chevron to expand | Fourth use of the split-affordance idiom; gives Forget separation; Cancel wired to `cancelPair`. | ✓ |
| One action, forget in an overflow menu | Simplest row, but an overflow menu is a popup — the path Q11 was chosen to avoid. | |
| All actions inline, always visible | Nothing hidden, but puts destructive Forget next to Connect in a fast-clicking list. | |

**User's choice:** Press for verb, chevron to expand

### Q20 — Dismiss destination

| Option | Description | Selected |
|--------|-------------|----------|
| Always dismiss to the desktop | One rule family-wide; no origin tracking, no conditional chrome. | ✓ |
| Return to the drawer when it came from a tile | Matches Android, but one gesture with two outcomes based on invisible history. | |
| Explicit back affordance in the header | Uniform gestures plus an explicit return, but reintroduces the chrome D-10 refused. | |

**User's choice:** Always dismiss to the desktop
**Notes:** Grab exclusivity means the drawer was destroyed, not hidden — "return" could only ever be a re-summon. D-14's tab memory makes that one keypress.

---

## Dashboard tab fit budget

### Q21 — Absorbing three new tiles

| Option | Description | Selected |
|--------|-------------|----------|
| One row of six compact tiles | Zero vertical growth; the reference-shell answer; ~125px per tile. | ✓ |
| Two rows of three at current size | No chip redesign, but +80px spends the whole budget and forces a tab-wide recomposition. | |
| Two rows of three, shorter chips (~56px) | Worst of both — still two rows, still eats slack, chips now differ from the gate-approved ones. | |
| Raise the drawer height | Honest and simple, but D-04 underpins the blur region and every other tab gains dead space. | |

**User's choice:** One row of six compact tiles
**Notes:** Decided by the reference lens — end-4 and Caelestia scale toggle grids with more compact tiles, never more rows. Hard constraint recorded: "Do Not Disturb" wraps to two lines and must not regress to "DND".

---

## Advanced-target robustness

### Q22 — Missing target app behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Show it disabled, with the reason | Keeps PANEL-05 unconditionally true; reuses D-41's present-but-disabled pattern. | ✓ |
| Hide the button when absent | Cleanest surface, but makes a requirement conditional on host state. | |
| Always enabled; fail inline on click | No availability check, covers general launch failure, but makes you click to discover. | |

**User's choice:** Show it disabled, with the reason
**Notes:** Preparation for this question found that `install.sh` never installs `network-manager-applet`, which provides `nm-connection-editor` — recorded as a required correction, not a decision.

---

## Coexistence & single-owner proof

### Q23 — SwayOSD pill on panel volume writes

| Option | Description | Selected |
|--------|-------------|----------|
| No pill from panel writes | Feedback is already on screen; SwayOSD stays the sole OSD producer. | ✓ |
| Fire a pill on panel writes too | One universal rule, but makes the panel a second OSD trigger. | |

**User's choice:** No pill from panel writes

### Q24 — Proof mechanism for criterion 5

| Option | Description | Selected |
|--------|-------------|----------|
| Extend quickshell-doctor + fail fixture | Reuses Phase 11's summon-and-diff; the phase owning the risk ships the instrument. | ✓ |
| Namespace and keybind checks only | Cheap and covers likely collisions, but the D-Bus ownership claims aren't eyeball-verifiable. | |
| No extension; UAT only | Least work, but leaves the highest-risk phase with no rerunnable instrument. | |

**User's choice:** Extend quickshell-doctor + fail fixture

---

## Per-panel empty & degraded states

### Q25 — Off/empty/degraded presentation

| Option | Description | Selected |
|--------|-------------|----------|
| Distinguish fixable from unfixable | Soft-off gets an Enable button; hard-blocked/no-adapter names the real cause without one; audio stays live. | ✓ |
| One empty treatment for all cases | Simplest, but conflates "turn this on" with "you cannot turn this on here". | |
| Panel refuses to open when off | Never shows a useless list, but hides state behind an absence. | |

**User's choice:** Distinguish fixable from unfixable
**Notes:** Fault-injectable via `rfkill block`/`unblock`, satisfying the prove-the-gate-can-fail rule.

---

## Claude's Discretion

- Exact panel height, tile dimensions at six-across, corner radius token, internal margins, and whether the ~850px frame uses a centered content column
- Material Symbol picks per panel/tile/row; exact "Advanced" label wording; tooltip copy
- Whether expanding a device picker animates the layout or overlays it
- Insert treatment (or none) for list items arriving after the frame cascade settles
- Exact scan cadence within "while open", progress-line styling, refresh control placement
- Bluetooth failure inference strategy once research settles it
- Plan/wave decomposition and sequencing (granularity `coarse`)

## Deferred Ideas

- Per-app peak level meters (Pipewire `peaks` is available)
- `Super+Shift+W` / `Super+Shift+B` panel keybinds
- Autoconnect toggle, trusted-device policy, per-network options in-panel
- A SwayOSD pill on panel volume writes
- Android-style back-to-drawer navigation
- Bar-anchored (top-right) panel placement — viable only if D-03's deferred waybar-layout state read is ever built
- Per-screen panel instances — blocked by QS-03, a permanent quickshell 0.3.0-2 limitation
