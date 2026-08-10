# Phase 15: Audio + Connectivity Panels - Context

**Gathered:** 2026-08-01
**Status:** Ready for planning

<domain>
## Phase Boundary

Three themed in-shell panels — a per-app audio mixer with device selection, a
wifi picker, and a bluetooth manager — built as instances of **one shared
dialog component**, each carrying an Advanced button that hands off to
pavucontrol / nm-connection-editor / blueman for anything past its
deliberately limited scope. Requirements: PANEL-01..06.

The panels are independent `quickshell-*` layer surfaces summoned from three
new quick-toggle tiles in Phase 14's dashboard grid, from rewired waybar
module clicks, and (for audio) from a global keybind. They inherit Phase 14's
whole vocabulary — layer posture, destroy-on-dismiss lifecycle, the D-22
truth-driven pending model, the D-41 widget-state vocabulary (which this phase
extends to a fourth state), Material Symbols Rounded, and the
`Design`/`Colours`/`Motion` singletons.

This phase **owns** the milestone's highest D-Bus conflict risk: three new
PipeWire / NetworkManager / BlueZ consumers arriving at once alongside
existing owners. It also owns the standalone-surface lifecycle that Phase 16
inherits — the roadmap sequences Workspace Overview after this phase
specifically so "the panel-lifecycle patterns are already proven."

**User lens (standing, restated by the user during this discussion):** when
design trade-offs are close, follow the **end-4 (dots-hyprland) and Caelestia
shell** conventions. Stated verbatim mid-discussion: *"When it comes to the
UI/design elements, always keep in mind our references (caelestia shell and
end4)."* This lens decided D-15-17 outright and corroborated D-15-01, D-15-06,
D-15-09, D-15-10, D-15-16, D-15-19 and D-15-21.

**Deprecation principle (carried from Phase 14):** swaync, walker and wleave
are v4.0 migration targets — spend no engineering attention coordinating with
them beyond what falls out of this phase's own mechanisms. waybar is **not** a
deprecation target, so the waybar edits in D-15-05 are legitimate work.

</domain>

<decisions>
## Implementation Decisions

21 decisions across 8 areas. Every "(reference lens)" tag means the
end-4/Caelestia convention was the deciding factor. The user asked for deep
pros/cons plus an explicit recommendation on every question and **overrode the
recommendation once** (D-15-11).

### Entry points & placement

- **D-15-01: Three new quick-toggle tiles — Volume, Wi-Fi, Bluetooth — as split tiles: pressing the tile body performs the one obvious verb (mute / wifi radio on-off / adapter on-off), a chevron affordance opens the full panel**
  (reference lens — the Android quick-settings idiom both end-4 and
  Caelestia ship). This is what the roadmap's "expand targets of the
  dashboard's quick-toggle entries" phrase asked for; Phase 14's grid shipped
  only Gaming / Do Not Disturb / Dark plus the motion-scale row, so the entries
  did not yet exist. Gives the grid its first genuinely stateful tiles.
  Tile lit-state follows **D-26's naming convention verbatim** (the tile is
  named for the state that lights it, and resting-lit tiles are the Material
  You signature): Wi-Fi lit when the radio is on, Bluetooth lit when the
  adapter is on, Volume lit when unmuted. All three sitting lit most of the
  time is the intended look, not a flaw.

- **D-15-02: Each panel is an independent layer surface with its own LazyLoader and focus grab; opening one dismisses the drawer.**
  Decided by a
  verified platform constraint, not by preference:
  `hyprland_focus_grab_v1` is **exclusive per-compositor on this build**
  (11-QUICKSHELL-EVIDENCE.md Finding 2, verified in both orders,
  order-independent) — activating a panel's `HyprlandFocusGrab` implicitly
  clears the drawer's, firing its `onCleared → dismissRequested()` and tearing
  down its LazyLoader. **D-13 turns out to describe the platform rather than
  impose policy**, so the handoff costs zero new mechanism. Enables keybind and
  waybar entry points, makes PANEL-06's "shared dialog component" structurally
  true rather than a shared tab body, and hands Phase 16 a proven standalone
  lifecycle. Rejected the in-place detail view (binds panels to drawer geometry,
  collides with D-04's fixed height, leaves Phase 16 nothing) and drawer-stays-
  behind (needs either dropping the drawer's grab or hoisting a shared grab to
  shell root, restructuring gate-passed code).
  Accepted cost: destroy-then-summon is two animations, not one morph — tuned
  via per-namespace layerrules under D-20 at the render gate.
  — **Reversibility:** costly — the standalone-surface lifecycle threads through
  the namespace scheme, the doctor checks, the waybar rewiring and Phase 16's
  inheritance; switching to in-place later re-opens all of them.

- **D-15-03: Panels anchor top-center at the drawer's width (~850px), inheriting D-03 verbatim**
  — flush to the top edge, bottom corners rounded
  only, compositor places them below waybar's reservation with no per-layout
  offset logic. The panel appears exactly where the drawer was, so the
  destroy-then-summon reads as the surface changing contents rather than one
  thing vanishing and another appearing elsewhere. One anchor rule, correct
  under all four waybar layouts. **Rejected top-right-under-the-status-cluster
  because `group/audio` and `group/connections` sit on the LEFT edge under the
  vertical layout** — anchoring there would require the waybar-layout state
  read that D-03 deliberately deferred. Accepted cost: ~850px is wide for list
  content, so panels carry generous internal margins or a centered content
  column (render-gate tuning).

- **D-15-04: `Super+A` summons the audio panel; wifi and bluetooth get no dedicated keybind.**
  Verified free plain-Super single letters: **A, G, H, J,
  K, M, O, U** — `W`, `B` and `V` are all taken (67 `mainMod` binds total), so
  D-09's first-letter mnemonic convention can only be honored for one of the
  three. Bound only where frequency justifies it: the mixer displaces the
  most-opened app (pavucontrol). Rejected `Super+Shift+W` / `Super+Shift+B`
  because three sibling panels from one shared component would carry visibly
  inconsistent chord shapes. **Requires one documented sentence** so the
  asymmetry reads as a decision, not an oversight. Cost per bind is proven, not
  estimated: one `shortcuts.json` entry + one `keybinds.lua` line +
  `keybind-doctor` re-run (11-05 demonstrated exactly this). Phase 11 Finding 1
  applies: `GlobalShortcut` registration does not hot-reload — a Quickshell
  process restart is needed to register. `Super+A` re-press toggles the panel
  closed, inheriting D-10's summon-chord-toggles rule (no new decision).

- **D-15-05: waybar's manager-clicks rewire to the panels.** `network`
  left-click → wifi panel, `bluetooth` left-click → bluetooth panel,
  `group/audio` **right**-click → audio panel. Preserves `group/audio`'s
  left-click mute toggle (a good verb with real muscle memory) and
  `bluetooth`'s `rfkill toggle bluetooth` right-click. The three GUI apps then
  live in exactly one place — behind each panel's Advanced button, where
  PANEL-05 puts them anyway. **Discovery:** athena's own config comment
  (lines 34-38) records that `tray` was deliberately removed from
  `modules-right`, and athena's module list confirms none — so its
  `nm-applet --indicator` on-click has no tray to render into. That click is a
  latent dead end on the primary layout, which this rewiring fixes. Costs: 3-4
  waybar configs plus `modules.jsonc` touched, `waybar-equivalence-check` and
  `waybar-design-lint` re-opened, and bar clicks now depend on the Quickshell
  process being alive (bounded — it autostarts and `quickshell-doctor` asserts
  it).

### Shared panel frame (PANEL-06)

- **D-15-06: One header band — panel icon + title on the left, a LABELED "Advanced" button on the right; body fills everything below. No close button.**
  Dismissal inherits D-10's set verbatim (Esc, click-outside,
  re-press the tile / `Super+A`) rather than inventing chrome the drawer
  deliberately doesn't have. Labeled-not-glyph is a direct application of
  Phase 14's render-gate lesson (*"A fresh user will not know what their
  function is"*, which forced "DND" → "Do Not Disturb" and tooltips on all six
  controls) — a bare-glyph Advanced would walk into an already-paid-for
  failure. Known risk carried to the render gate: top-right adjacency invites
  close-button mis-clicks; mitigate with spacing and explicit text.

- **D-15-07: One fixed height shared by all three panels, with a scrollable body.**
  The truest reading of PANEL-06 — three panels that are literally the
  same frame with different contents. **Decisive argument: a wifi scan
  populates progressively**, so a content-sized panel would grow under the
  cursor mid-scan, moving the blur region and click-outside hit zone — D-04's
  incoherence arriving through a different door. D-41's placeholder vocabulary
  covers the under-filled case. Accepted cost: dead space on short lists;
  height chosen for the common case.
  **This is the D-05 scroll exemption, and it is WIDER than Phase 14 predicted.**
  D-05 anticipated "Phase 15's per-app mixer list is the expected first
  legitimate exemption" — but all three panels have unbounded content (audio
  streams / visible networks / paired+discovered devices), unlike the drawer's
  four tabs which D-05 audited as bounded. Record under the exemption
  discipline with this reason.

- **D-15-08: Entrance motion — cascade the frame, render the list whole.**
  Header, title, Advanced and the panel's primary control fade+rise in
  read-order (3-5 elements, comfortably inside D-21's settled-under-700ms
  fence); the list body appears as one block. **Rejected the full cascade on
  arithmetic:** 20 networks at D-21's 30-50ms offsets is 600-1000ms for the
  list alone, breaking the fence, and staggering async-arriving scan results is
  incoherent by construction. **Reuses D-21's existing stagger token** — so
  `motion.json` does not grow and Phase 12's D-25 semantic-layer growth policy
  is not re-opened. D-20's per-namespace layer slide applies automatically.
  Insert treatment for list items arriving later from a live scan is
  discretion (including none).

- **D-15-09: Failures render inline on the affected row — a recorded FOURTH widget state.**
  D-41's vocabulary becomes **populated / pending / empty /
  failed**. Phase 14 had no failure state: D-22 only promised that failed
  operations never display a *false* state, and the watchdog silently clears
  pending — adequate for local script execs, inadequate here where wrong
  passwords and rejected pairings are ordinary daily events. **Verified:
  `Quickshell.Networking` exposes both `connectionFailed` and `reason`** — a
  real signal carrying a cause. Errors are inherently row-scoped ("which one
  failed?" is the first question in a list of twenty), and it composes with the
  wifi retry flow rather than fighting it. Rejected swaync routing on the
  deprecation principle. Phase 16 inherits the four-state vocabulary.
  — **Reversibility:** costly — the fourth state becomes part of the QML
  family's shared vocabulary; removing it later re-opens every widget that
  renders it.

### Audio panel composition

- **D-15-10: Pinned control block over a scrolling app list.** Master volume
  and both device pickers sit in a fixed block directly under the header,
  always visible; only the unbounded app list scrolls. Matches the exemption's
  own logic — scroll exactly what is unbounded and nothing else — and keeps the
  highest-frequency controls permanently reachable. **Rejected segmented
  sub-views partly because they would add a SECOND navigation model** inside a
  shell whose drawer already taught swipe-between-views. Accepted cost: the
  pinned block shortens the app list's viewport.

- **D-15-11: Full input symmetry — input device picker + input level slider + mic mute, mirroring the output block. USER OVERRODE the recommendation**
  (which was device selection + mic mute only, justified on mic-gain being
  set-once while mic-mute is moment-to-moment). This is the second recorded
  override in the project's history (cf. Phase 14 D-31, the units field).
  **PRE-AGREED FALLBACK, authorized by the user at decision time and shaped
  like D-07's blur/readability fallback:** if the render gate finds the pinned
  block too cluttered, drop the input level slider and fall back to device
  selection + mic mute — **without needing a new decision**. This exceeds
  PANEL-02's literal text ("selects the default output and input device and
  adjusts master volume") and is recorded as a deliberate widening so
  verification does not read it as drift. Adds no new backend or D-Bus surface
  — same `defaultAudioSource` properties already being read.

- **D-15-12: Device pickers are expandable inline rows.** A collapsed row shows
  the current device; pressing expands it in place into selectable rows,
  collapsing on pick. **Deliberately avoids QtQuick `Popup` entirely** —
  Popup-inside-a-Wayland-layer-shell-surface is **unverified** on this build
  (Qt 6.8+ gave `Popup` a `popupType` that can render as a real window), and
  standing constraint 2 forbids assuming it. Also reuses the same
  chevron-expand language as D-15-01's tiles, so the shell teaches one idiom
  rather than three. Render-gate call: whether expansion animates the layout or
  overlays it.

- **D-15-13: Per-app row = icon-as-mute + app name + slider.** The literal
  reading of PANEL-01's "per-app volume slider and click-to-mute", and the most
  compact — three elements means the most apps visible in the one viewport that
  scrolls. **Muted state carried twice** (icon dims with a slash overlay AND
  the slider track shifts to a muted tone) plus a hover tooltip, applying
  Phase 14's render-gate remedy rather than repeating its mistake. Peak meters
  declined for now even though Pipewire's `peaks` is available: polish,
  continuous repaint, visual noise behind a control being dragged precisely —
  D-36's no-sparkline restraint is the precedent. Addable later without
  touching the row's structure.

### Wifi flows

- **D-15-14: Password entry is an inline expanding row.** Selecting a secured
  network expands that row into a password field + Connect, in place — the
  third use of the press-to-reveal idiom (tiles, device pickers, this).
  Composes directly with D-15-09: a rejected PSK re-renders its `reason` on the
  same row with the field still open, which is exactly the retry flow wanted.
  **Named consequence: Esc becomes two-stage** — it collapses the password
  field first and dismisses the panel only on a second press.
  Enabling facts, both verified: Phase 11's QS-02 gate **proved** a human can
  type into a text field on a layer-shell surface under
  `WlrKeyboardFocus.OnDemand`, and D-12 recorded that the drawer's focus model
  "is the model Phase 15's password inputs need".
  **Security rationale reinforcing the native binding:** `connectWithPsk`
  passes the PSK over D-Bus so it **never touches a command line** — an
  `nmcli device wifi connect X password Y` wrapper would expose the passphrase
  in `/proc/<pid>/cmdline` to every process on the machine for the duration of
  the call. This matches the repo's existing T-14-13 discipline (fixed argv
  arrays, no value from any state source reaching a command array).

- **D-15-15: Scan while the panel is open, stop on dismiss.** `scannerEnabled`
  true for the panel's lifetime, off on dismiss — the same zero-idle doctrine
  D-32 and D-36 established. Criterion 2's required visible in-progress state
  is an **indeterminate progress line pinned under the header**, in a fixed
  position that never moves the list; an explicit refresh control stays
  available. Known cost — scan churn — is answered structurally by D-15-16
  rather than by scanning less.

- **D-15-16: List ordering is grouped and stable — current connection, then saved, then the rest.**
  Signal strength renders as a per-row icon but
  **never drives the sort**, so ordinary fluctuation can never reorder rows;
  churn is eliminated structurally rather than by hysteresis tuning. New
  networks append to the bottom group instead of inserting mid-list. Prevents a
  concrete failure: a rescan lands, two rows swap, and the wrong network is
  connected. Accepted cost: within the unsaved group a strong near network can
  sit below a weak far one, which reads as arbitrary until the grouping is
  noticed. Bluetooth mirrors this grammar (D-15-18).

- **D-15-17: Panels expose the required actions plus wifi `forget`; everything else lives behind Advanced.**
  Wifi: connect, disconnect, forget. Bluetooth:
  adapter toggle, connect, disconnect, forget (all required by criterion 3).
  Behind Advanced: autoconnect policy, static IP, DNS, VPN, codec selection,
  trusted-device policy. **Driving argument for including wifi forget despite
  criterion 2 not listing it:** NetworkManager saves a connection profile even
  when the passphrase was wrong, and later connects silently reuse the bad PSK
  — so without `forget`, a single typo routes the user straight back to
  nm-connection-editor, the app this phase exists to displace, triggered by the
  most common possible error. `forget` / `requestForget` are on the Networking
  surface. **`forget` requires destructive-action treatment — not a position
  adjacent to connect.**

### Bluetooth flows

- **D-15-18: Paired devices listed immediately with zero radio activity; discovery is opt-in behind an explicit "Add device" control.**
  Grouping:
  **connected → paired → discovered**, mirroring wifi's current → saved → rest
  so both panels teach one list grammar. **This is a deliberate asymmetry with
  the wifi panel and must be recorded with its reason** or it reads as
  inconsistency later. The reason: BT inquiry contends with the same radio
  carrying an A2DP stream, so continuous discovery can stutter the very audio
  the panel is being opened to manage — and the daily case (reconnect known
  headphones) needs **zero** discovery. Doing the wifi thing here would let the
  panel damage the connection it exists to manage.

- **D-15-19: Device row — press for the contextual verb, chevron to expand.**
  The row's press does the one obvious thing by state (Pair / Connect /
  Disconnect); the chevron expands to battery, address and a visually separated
  **Forget**, satisfying D-15-17's destructive-action separation. This is the
  **fourth consistent use of the split-affordance idiom** (grid tiles, device
  pickers, password rows, this). The daily path stays one press. Pairing
  pending shows progress with a **real Cancel wired to `cancelPair`** — a
  strict improvement on D-22's silent watchdog for the one operation where
  waiting is long and user-visible. Battery renders when `batteryAvailable`;
  its absence is an ordinary empty case. **Rejected the overflow menu
  specifically because it is a popup** — the same unverified path D-15-12 was
  chosen to avoid.

### Dismissal, fit, robustness, coexistence

- **D-15-20: Dismissing a panel always returns to the desktop, never to the drawer.**
  One rule across the whole QML family: Esc and click-outside mean
  *gone*, regardless of origin. No origin tracking at shell root, no
  conditional chrome, and no gesture with two outcomes based on invisible
  history. Mechanically forced context: grab exclusivity means the drawer was
  **destroyed, not hidden**, so "returning" could only ever be a fresh
  re-summon. D-14's selected-tab memory survives at shell root, so `Super+D`
  lands back on the Dashboard tab — the return costs exactly one keypress.
  Rejected the Android-style back affordance because it reintroduces the
  navigation chrome D-10 refused.

- **D-15-21: The quick-toggle grid becomes ONE row of six compact tiles**
  (reference lens — end-4 and Caelestia solve "more toggles" with many compact
  tiles in one row, never with more rows). **Zero vertical growth: the fit
  problem disappears rather than being absorbed.** D-05's 10-15% slack stays
  untouched, D-38's Dashboard-tab composition is unchanged, and no other
  widget's render gate re-opens. Arithmetic: two rows of 72px chips would cost
  ~+80px, most or all of the remaining budget; six tiles at 850px width minus
  24px padding is ~125px each, roughly Android's own tile size, where the
  chevron split affordance works comfortably.
  **HARD CONSTRAINT: "Do Not Disturb" wraps to two lines (tile grows to ~80px,
  still one row) and must NOT regress to "DND"** — Phase 14's render gate
  explicitly rejected that acronym.

- **D-15-22: An Advanced button whose target app is absent renders disabled with the reason, never hidden.**
  Availability is checked cheaply up front, so
  the user learns before clicking rather than after. Reuses **D-41's
  present-but-disabled pattern** and the tooltip mechanism already on every
  Phase 14 control, and matches how the reference shells keep full-app links
  visible. Keeps PANEL-05 ("each panel carries an Advanced button")
  unconditionally true and verifiable rather than conditional on host state.

- **D-15-23 (REQUIRED CORRECTION, not a preference): `install.sh` must install `network-manager-applet`.**
  It provides `nm-connection-editor`, PANEL-05's
  wifi Advanced target. `pavucontrol` (install.sh:111) and `blueman`
  (install.sh:212) are both present; the third is not. All three binaries exist
  on **this** host (`network-manager-applet` 1.36.0-2) — i.e. it is host-only
  state, exactly what the reproducibility constraint forbids, and the same
  failure class CLAUDE.md documents for `adw-gtk3`. Athena's waybar
  `nm-applet --indicator` click comes from the same missing package, making
  that dead click dead twice over on a fresh install. Add it to the
  **hard-fail package-verify class** so the omission cannot recur silently.

- **D-15-24: Panel volume writes do NOT fire a SwayOSD pill.** The slider being
  dragged is already on screen, so a pill restates visible information and
  stacks a second overlay while the grab situation is delicate. Keeps
  criterion 5's story clean: **SwayOSD remains the only OSD producer**,
  triggered only by hardware keys, at exactly one step and one pill per press.
  Neither end-4 nor Caelestia fire an OSD from their own in-panel sliders.
  Accepted inconsistency: keyboard and panel volume changes give different
  feedback.
  *Context that defuses most of the apparent D-Bus risk:* for PipeWire, NM and
  BlueZ the panels are additional **consumers**, not ownership claimants.
  Constraint 4 already settles that multiple readers are safe and only an
  uncoordinated third **writer** is dangerous; volume and connection state are
  idempotent state sets, not a claimed D-Bus name like
  `org.freedesktop.Notifications`. **D-22's truth-driven model is exactly what
  makes multiple writers safe here** — the panel renders actual backend state,
  so a change made by waybar's `wpctl` click or by SwayOSD shows up correctly.

- **D-15-25: Criterion 5 is proven by extending `quickshell-doctor`, with a proven-to-fail fixture.**
  New checks: the three panel namespaces conform to
  the `quickshell-*` prefix; `Super+A` registers exactly once (via
  `keybind-doctor`); no second `org.freedesktop.Notifications` owner appears
  while a panel is summoned; SwayOSD key ownership is byte-identical
  before/during/after. **Reuses the summon-and-diff mechanism Phase 11 already
  built** (it replaced an unfalsifiable grep) rather than inventing one.
  Honors the house rule *a gate must be proven able to fail before it is
  trusted to pass* with a poisoned fixture, as Phase 11 did. Rationale: the
  roadmap names this phase as owning the milestone's highest D-Bus conflict
  risk, so it ships the instrument that measures it.

- **D-15-26: Off/empty/degraded states distinguish fixable from unfixable.**
  Four distinct cases: (1) **wifi soft-off** (`wifiEnabled` false) — centered
  Material Symbol + one line + an Enable button; (2) **wifi hard-blocked**
  (`wifiHardwareEnabled` false, an rfkill hardware switch) — the same
  composition **without** the button, with the line naming the physical switch
  as the cause; (3) **bluetooth adapter disabled vs no adapter present at all**
  (`defaultAdapter` null) — the same distinction, the latter saying so plainly
  rather than implying it is switched off; (4) **audio with nothing playing** —
  *not* degraded: the pinned master, device pickers and mic controls stay fully
  live, with an in-place placeholder only where the app list would be.
  Follows D-41's "quiet Material Symbol + one line, controls
  present-but-disabled" verbatim and matches end-4/Caelestia. Cleanly
  fault-injectable via `rfkill block`/`unblock`, satisfying the
  prove-the-gate-can-fail rule the way D-33 used cache-backdating.
  **Governing principle: never offer a control that cannot work.**

### Inherited constraints (recorded, not decided)

- **QS-03 — no per-screen fan-out.** Phase 12 accepted this as a *permanent*
  limitation on quickshell 0.3.0-2 after two structurally distinct `Variants`
  arrangements both reproduced the FM2 multi-screen failure across a real
  session restart. Phases 14 and 16 inherit a shell root that cannot fan out;
  **these panels inherit it too — single instance, not per-monitor.**
- **Phase 11 Finding 1 — `GlobalShortcut` registration does not hot-reload.**
  `Super+A` needs a Quickshell process restart to register.
- **D-43 layer posture (locked by roadmap + Phase 11):** overlay layer,
  `exclusiveZone: 0`, `WlrKeyboardFocus.OnDemand` baseline,
  `quickshell-<surface>` namespace so the family-wide `^quickshell-.*`
  blur/`ignore_alpha` layerrule applies without new rules.

### Claude's Discretion

- Exact panel height, tile width/height at six-across, corner radius token,
  internal margins, and whether the ~850px frame uses a centered content column.
- Material Symbol picks per panel, tile and row; the exact "Advanced" label
  wording; tooltip copy.
- Whether expanding a device picker (D-15-12) animates the layout or overlays it.
- Insert treatment (or none) for list items arriving from a live scan after the
  frame cascade has settled (D-15-08).
- Exact scan cadence within "while open", progress-line styling, and the
  refresh control's placement in the header.
- Peak-meter deferral is a decision (D-15-13), but re-adding meters later is
  discretion within the row's existing structure.
- Bluetooth failure inference strategy once research settles it (see research
  items below).
- Plan/wave decomposition and sequencing; granularity is `coarse` in
  `.planning/config.json`. Building the shared frame before the three panels is
  the obvious ordering but is not mandated here.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and standing rules
- `.planning/ROADMAP.md` §"Phase 15: Audio + Connectivity Panels" — the five
  success criteria, the "Owns" clause (highest D-Bus conflict risk), the open
  question on `Quickshell.Networking` completeness (answered below), UI hint flag
- `.planning/ROADMAP.md` §"Standing constraints (apply to every v3.0 phase)" —
  constraint 1 (human render gate — this phase has many visual gates),
  constraint 2 (verify options against the installed binary — the QtQuick popup
  question in D-15-12, the native bindings, `cancelPair`), constraint 3
  (same-commit stow registration), constraint 4 (additive-only coexistence and
  the named collision checklist: layer namespaces, keybinds,
  `XF86Audio*`/`XF86MonBrightness*`, `org.freedesktop.Notifications` ownership)
- `.planning/REQUIREMENTS.md` PANEL-01..06 (lines 53-58) and §Traceability
  (lines 156-161)
- `.planning/PROJECT.md` §"Key Decisions" — human-render-gate row,
  additive-only row

### Prior phase context that carries forward
- `.planning/phases/14-dashboard-drawer/14-CONTEXT.md` — **the single most
  important upstream document.** D-03 (geometry inherited by D-15-03), D-04/D-05
  (fixed height, scroll exemption — widened by D-15-07), D-10 (dismissal set),
  D-13 (focus-loss coexistence rule), D-14 (destroy-on-dismiss + tab memory),
  D-20/D-21 (layer motion + cascade fences), D-22 (pending model), D-23..D-27
  (the toggle grid this phase extends), D-26 (tile naming/lit convention),
  D-28 (Material Symbols), D-38 (Dashboard tab composition), D-41 (widget-state
  vocabulary — extended to four states by D-15-09), D-42/D-43 (namespace and
  layer posture)
- `.planning/phases/11-quickshell-viability-gate/11-QUICKSHELL-EVIDENCE.md` —
  **Finding 2 at lines ~797-829 (`HyprlandFocusGrab` per-compositor
  exclusivity, verified in both orders) is what decides D-15-02.** Also
  Finding 1 (GlobalShortcut restart-to-register), the QS-02 gate result
  (typing on a layer-shell surface under OnDemand), and the summon-and-diff
  mechanism D-15-25 reuses
- `.planning/phases/12-unified-design-token-pipeline/12-CONTEXT.md` — D-13
  (QS-03 accepted as permanent), D-25 (semantic layer growth policy — D-15-08
  avoids triggering it), D-18 (no quickshell step in the reload fan-out)
- `.planning/phases/13-motion-retrofit-existing-surface-sweep/13-CONTEXT.md` —
  D-06/D-07 (layer motion split, per-namespace style-only overrides)

### Code this phase builds on (verified during discussion)
- `quickshell/.config/quickshell/shell.qml` — the shell root; three new
  LazyLoaders mount here beside `dashboardLoader`
- `quickshell/.config/quickshell/modules/Dashboard.qml` — **line 419: the
  `HyprlandFocusGrab { windows: [dashboardWindow]; active: true; onCleared:
  dismissRequested() }` block that D-15-02 relies on**; lines 191-198 the layer
  posture the panels copy
- `quickshell/.config/quickshell/modules/dashboard/QuickToggles.qml` — the grid
  D-15-01 and D-15-21 modify; its D-22 pending model, watchdog timers, fixed
  argv `Process` discipline and `ToolTip` treatment are the patterns the panels
  follow
- `quickshell/.config/quickshell/modules/dashboard/Design.qml` +
  `Colours.qml` + `Motion.qml` + both `qmldir` files — the token singletons
  every panel widget consumes
- `quickshell/.config/quickshell/shortcuts.json` — the declared-manifest
  pattern D-15-04 extends (fourth entry)
- `hypr/.config/hypr/config/keybinds.lua` — `Super+A` lands here; the Lua
  multi-modifier `' + '` joining convention (13.1 finding); 67 existing
  `mainMod` binds
- `hypr/.config/hypr/config/windowrules.lua` — layer rules; the family-wide
  `^quickshell-.*` baseline plus D-20-style per-namespace animation rules for
  the three panel namespaces
- `waybar/.config/waybar/config-athena.jsonc` — `group/audio` (line ~316) and
  `group/connections` (line ~84, modules `network` + `bluetooth`); `network`
  `on-click` at ~346, `bluetooth` `on-click`/`on-click-right` at ~356-357; the
  tray-removal comment at lines 34-38 that makes `nm-applet --indicator` dead
- `waybar/.config/waybar/modules.jsonc` (lines ~146-147),
  `config-floating.jsonc` (line ~52), `config-vertical.jsonc` (lines ~113-114)
  — the other rewire sites
- `hypr/.config/hypr/scripts/quickshell-doctor` — D-15-25 extends this
  (10 checks today, includes the reserved-space summon-and-diff)
- `hypr/.config/hypr/scripts/keybind-doctor` — re-run after `Super+A`
- `install.sh` — D-15-23's correction (line ~111 `pavucontrol`, ~212 `blueman`;
  `network-manager-applet` must join them in the hard-fail package-verify class)
- `hypr/.config/hypr/scripts/nmtui-launch.sh` — existing NM entry point, worth
  checking for overlap during planning

### Installed API surface (verified directly this discussion — do not re-derive)
- `Quickshell.Networking` (`/usr/lib/qt6/qml/Quickshell/Networking/`) —
  `wifiEnabled`, `wifiHardwareEnabled`, `scannerEnabled`, `networks`,
  `signalStrength`, `security`, `known`, `autoconnect`, `state`,
  `stateChanging`, `connect`, `connectWithPsk`, `connectWithSettings`,
  `requestConnect`, `requestConnectWithPsk`, `requestDisconnect`,
  `requestForget`, `forget`, `requestSetAutoconnect`, `connectionFailed`,
  `reason`, `connectivity`, `nmSettings`
- `Quickshell.Bluetooth` (`/usr/lib/qt6/qml/Quickshell/Bluetooth/`) —
  `adapter`, `adapters`, `defaultAdapter`, `enabled`, `discovering`,
  `discoverable`, `devices`, `pair`, `cancelPair`, `connect`, `disconnect`,
  `forget`, `paired`, `bonded`, `connected`, `trusted`, `blocked`, `battery`,
  `batteryAvailable`, `state`, `deviceName`, `address`, `icon`
- `Quickshell.Services.Pipewire` — `nodes`, `isSink`, `isStream`, `properties`,
  `nickname`, `description`, `audio` (`volume`, `volumes`, `muted`,
  `channels`), `defaultAudioSink`, `defaultAudioSource`,
  `preferredDefaultAudioSink`, `preferredDefaultAudioSource`, `peak`, `peaks`,
  `linkGroups`, `ready`
- **The roadmap's open question is effectively answered: native D-Bus bindings,
  not an `nmcli` wrapper.** The secured-network flow PANEL-03 needs is present
  (`connectWithPsk`), and D-15-14 records an additional security reason to
  prefer it. Research still verifies live behavior.

### External references (the user's standing lens)
- **end-4/dots-hyprland and Caelestia shell** — the taste baseline for every
  design-discretion call, restated by the user during this discussion.
  Researcher should source-check their current Quickshell implementations for
  component-level patterns in exactly these places: the quick-settings tile
  grid (D-15-21's six-across compact tiles), the wifi/bluetooth panel layouts
  and their empty/off states (D-15-26), the volume panel's per-app row shape
  (D-15-13), and how they present their own "open the full app" links
  (D-15-06/D-15-22).

</canonical_refs>

<code_context>
## Existing Code Insights

### Verified facts (checked during discussion — do not re-derive)
- `hyprland_focus_grab_v1` is **exclusive per-compositor** on this build; a
  second surface's grab implicitly clears the first's, tearing down its
  LazyLoader. Verified in both orders, order-independent.
- Free plain-Super single letters: **A, G, H, J, K, M, O, U**. Taken:
  B, C, D, E, F, I, L, N, P, Q, R, S, T, V, W, X, Y, Z and all digits
  (67 `mainMod` binds).
- `quickshell 0.3.0-2` ships native `Networking`, `Bluetooth` and
  `Services/Pipewire` QML modules (full member lists above).
- `pavucontrol`, `blueman-manager` and `nm-connection-editor` all resolve on
  this host, but **`network-manager-applet` is absent from `install.sh`** —
  host-only state.
- athena's waybar config has **no `tray`** (deliberately removed, comment at
  lines 34-38), so its `nm-applet --indicator` on-click is inert there;
  `config-floating.jsonc` does still carry a `tray`.
- `group/audio` and `group/connections` are in `modules-right` on the top bar
  for athena/floating, but on the **left-edge** bar under the vertical layout —
  which is why D-15-03 rejects bar-relative anchoring.
- Qt on this build renders the Material Symbols variable `FILL` axis (14-02's
  live-measured `fill-axis-renders` verdict), so the outlined→filled lit-state
  language works for the new tiles.

### Reusable Assets
- `Dashboard.qml`'s `PanelWindow` + `WlrLayershell` + `HyprlandFocusGrab`
  block — the panels' surface skeleton, copied wholesale.
- `QuickToggles.qml`'s D-22 pending model, watchdog `Timer` pattern (declared
  as `interval:` not `duration:` to stay outside motion-lint CHECK B), fixed
  argv `Process` discipline, and `ToolTip` treatment.
- `Design`/`Colours`/`Motion` singletons — note the 12-06 finding
  (`pragma Singleton` + `qmldir singleton` keyword both required).
- D-21's stagger token in `motion.json` — reused by D-15-08, not extended.
- `quickshell-doctor`'s before/during/after summon-and-diff — reused by D-15-25.
- `startDetached()` precedent from `QuickToggles.qml`'s dark chip: any panel
  action that launches a focus-stealing app (every Advanced button) must use
  it, or the panel's own dismissal kills the child mid-flight. **This applies
  directly to all three Advanced buttons.**

### Established Patterns
- Zero hex/duration literals in repo-authored UI — everything through
  `~/.local/state/theme/` tokens; motion-lint enforces (panel QML is in scope).
- A gate must be proven able to fail before it is trusted to pass — D-15-25's
  poisoned fixture and D-15-26's `rfkill` fault injection both continue it.
- Human render-and-look gates per visual plan (standing constraint 1).
- One entrypoint per state axis; views never write rendered files.
- Present-but-disabled for controls that exist but cannot act (D-41), applied
  by D-15-22 and D-15-26.

### Integration Points
- `shell.qml` ← three new LazyLoaders
- `shortcuts.json` + `keybinds.lua` ← `Super+A` (keybind-doctor re-run after)
- `windowrules.lua` ← per-namespace layer motion rules for the three panels
- `QuickToggles.qml` ← three new tiles, six-across recomposition
- `waybar/config-{athena,floating,vertical}.jsonc` + `modules.jsonc` ←
  D-15-05's rewired clicks (waybar-equivalence-check + waybar-design-lint re-run)
- `install.sh` ← `network-manager-applet` (D-15-23)
- `quickshell-doctor` ← D-15-25's new checks + fixture

</code_context>

<specifics>
## Specific Ideas

- **"When it comes to the UI/design elements, always keep in mind our
  references (caelestia shell and end4)"** — stated by the user mid-discussion,
  reaffirming Phase 14's standing lens. It decided D-15-21 outright (one row of
  six compact tiles rather than two rows — because that is how both reference
  shells scale a toggle grid) and corroborated D-15-01, D-15-06, D-15-09,
  D-15-10, D-15-16, D-15-19 and D-15-24.
- **The user asked for deep pros/cons plus an explicit recommendation on every
  single question**, stated as a standing instruction: *"Dig deeper into the
  pros and cons of each option and recommend the best choice. Do this for every
  question in the discussion before presenting it to me."* Downstream agents
  should present trade-offs at the same depth at any checkpoint or render gate,
  and always name a recommendation rather than offering a bare menu.
- **The user overrode a recommendation once** (D-15-11, full input symmetry)
  and supplied their own fallback condition unprompted — "if it proves to be
  too cluttered then fallback to device selection + mic mute". Recording
  user-authorized fallbacks alongside overrides is the pattern to repeat.

</specifics>

<deferred>
## Deferred Ideas

- **Per-app peak level meters** in the mixer rows (Pipewire's `peaks` is
  available) — declined by D-15-13 as polish; addable later without changing
  the row's structure.
- **`Super+Shift+W` / `Super+Shift+B` panel keybinds** — declined by D-15-04;
  revisit only if the tile + waybar paths measure slow for wifi/bluetooth.
- **Autoconnect toggle, trusted-device policy, per-network options** in-panel —
  fenced out by D-15-17 as Advanced's job; contradicts criterion 4's
  "deliberately limited scope".
- **A SwayOSD pill on panel volume writes** — declined by D-15-24; would make
  the panel a second OSD trigger.
- **Android-style back-to-drawer navigation** from a panel — declined by
  D-15-20; would need origin tracking and conditional header chrome.
- **Number-key or per-tile direct panel jumps** from the drawer — not raised as
  a need; the chevron is one press.
- **Bar-anchored (top-right) panel placement** — declined by D-15-03 because it
  would require the waybar-layout state read D-03 deferred; becomes viable only
  if that deferred patch is ever built.
- **Per-screen panel instances** — blocked by QS-03, accepted as a permanent
  quickshell 0.3.0-2 limitation in Phase 12, not a deferral this phase can act on.

### Open research items (named during discussion — blocking for planning)
1. **Bluetooth failure detection (D-15-09).** `Quickshell.Bluetooth` exposes no
   explicitly-named failure signal — no counterpart to Networking's
   `connectionFailed` + `reason`. Failure must be inferred from state
   transitions (a pairing that ends without `bonded` going true). Determine the
   reliable inference and what text the inline failed state can honestly show.
2. **QtQuick `Popup` viability inside a Wayland layer-shell surface.** D-15-12
   and D-15-19 both route around it, so this is not blocking — but it should be
   settled once and recorded, since Qt 6.8+ `popupType` may render popups as
   real windows. If it works, future surfaces gain an option; if it does not,
   the avoidance becomes a documented family rule.
3. **Live verification of the native bindings** (standing constraint 2):
   `connectWithPsk` against a real secured network, `requestForget`,
   `scannerEnabled` behavior and rescan cadence, `cancelPair` mid-pairing, and
   whether `peaks` costs anything meaningful if meters are ever revisited.
4. **`preferredDefaultAudioSink`/`Source` write semantics** — confirm setting
   them actually moves existing streams (or whether stream re-routing needs a
   separate step), since PANEL-02's "selects the default output device" implies
   the audible result, not just the preference.
5. **Six-across tile legibility** (D-15-21) — confirm "Do Not Disturb" wraps to
   two lines legibly at ~125px across the installed font set, since reverting to
   "DND" is explicitly forbidden.
6. **end-4/Caelestia source-check** for component-level patterns in their
   quick-settings grids, wifi/bluetooth panels, empty/off states, per-app volume
   rows, and full-app links — same discipline Phase 12 and Phase 14 applied.

</deferred>

---

*Phase: 15-audio-connectivity-panels*
*Context gathered: 2026-08-01*
