# Phase 19: Notification Server & Centre - Research

**Researched:** 2026-08-13
**Domain:** Quickshell/QML D-Bus notification server (`org.freedesktop.Notifications`), swaync retirement, cross-cutting v3.0 debt paydown (LEDGER-04/07/08)
**Confidence:** HIGH for the Quickshell API surface, the repo's own existing seams, and swaync's retirement footprint (all read directly this session). MEDIUM for exact `replaces_id` C++ internals and Caelestia's non-goal-state behaviour (inferred from its QML consumer, not from Quickshell's own C++ source, which is not installed on this host). LOW/flagged explicitly where noted in Assumptions Log and Open Questions.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### Governing rule for this phase

- **D-19-00:** **Caelestia's shipped behaviour is the strong default for every
  design decision in this phase**, with end-4 secondary. This is the user's explicit
  instruction, sharpening the standing v3.0 reference-shell bias from a tie-breaker
  into a leading prior. Practical rule for downstream agents: check
  `.planning/research/FEATURES.md` § NOTIF (a direct read of both shells' real QML,
  with file links) — and the actual source when FEATURES.md doesn't record the
  detail — *before* proposing an approach, and name the divergence explicitly
  whenever recommending against Caelestia.

#### Popup placement and lifetime

- **D-19-01:** Popups anchor **always top-right**, in both bar orientations; only
  the margin shifts to clear whichever edge the bar occupies. Chosen over
  following the bar's edge, which would be a second layout to keep in step — the
  fork D-18-13 avoided for the bar itself.
- **D-19-02:** Popup card width is **430px** — Caelestia's `sizes.notifs.width`,
  deliberately equal to the centre width (D-19-14) so a card looks identical
  floating or in history. Supersedes swaync's 380.
- **D-19-03:** Stack depth is governed by **Caelestia's height clamp** — the stack
  grows until it would collide with another open surface, then stops — **and** a
  `+N more` summary card appears when the clamp truncates. Clicking it opens the
  centre. (Caelestia clamps only; the `+N more` card is this project's addition.)
- **D-19-04:** Timeouts **match swaync exactly**: 5s normal, 3s low urgency,
  critical never auto-dismisses. Nothing about the daily rhythm changes on
  migration day, which is the point of a no-soak swap.
- **D-19-05:** Cards are **compact by default** (icon + title + one body line) and
  **expand on a vertical drag** past a px threshold, Caelestia's `expandThreshold`
  gesture. Expanded state reveals full body, image and action buttons. Hover keeps
  its single separate job (D-19-06).
- **D-19-06:** **Hover pauses the dismiss timer and resumes it on leave.** Not a
  reset, not sticky.
- **D-19-07:** **Horizontal drag past a threshold in either direction dismisses**
  (Caelestia's `clearThreshold`), and **middle-click closes immediately** (both
  references ship middle-click). **No gesture is destructive** — a dismissed popup
  stays in history; deletion lives only in the centre, where it is deliberate and
  visible.
- **D-19-08:** A `replaces_id` re-send **updates the existing card in place,
  restarts its dismiss timer, and does not re-animate or reorder the stack**
  (QNOTIF-05). Re-animating to the top would fight QNOTIF-02's "reflow smoothly"
  for a fast-updating download.
- **D-19-09:** **A `hints.value` notification draws a circular ring progress
  indicator over the app icon** (Caelestia) — giving QNOTIF-05's in-place update a
  visible readout rather than just changing text.
- **D-19-10:** **Clicking the card body invokes the spec's `default` action** when
  the notification has one, otherwise dismisses.
- **D-19-11:** **Critical urgency swaps the whole card to the error colour scheme**
  (Caelestia), sourced from the `danger`/`onDanger` `BarRoles` pair, and the card
  never auto-dismisses. It is still subject to the height clamp — no cap exemption,
  so an app that marks everything critical cannot wall off the screen.
- **D-19-12:** Icon fallback chain: **image hint → named `app_icon` via the icon
  theme → the app's desktop-entry icon → a generic Material Symbols bell glyph.**
  Never a broken or blank slot, and never two card widths.
- **D-19-13:** Popups **slide + fade from the anchored edge**, and the stack
  reflows on the same curve. All durations and easings read from `Motion.qml`
  tokens — no bespoke numbers.

#### The centre

- **D-19-14:** The centre is **its own right-edge slide-out `PanelWindow`** —
  Caelestia's `modules/sidebar/` pattern, a sibling of the bar rather than a tab
  inside the dashboard. Its lifecycle is independent of the dashboard drawer, so
  history and DND never depend on the drawer being alive.
  — **Reversibility:** costly — this is the third top-level frame in the shell
  (after `PanelDialog` and `SectionPopout`). It must be registered in GATE-03's
  `quickshell-doctor` structural checks, covered by GATE-04's hex lint, and kept in
  visual and motion step with the other two by review rather than by construction.
  D-18-15 already knowingly added the second frame; this is the third.
- **D-19-15:** It is **430px wide and spans the full screen height** — Caelestia's
  `sizes.sidebar.width: 430` with `anchors.top`/`anchors.bottom` (verified in
  `plugin/src/Caelestia/Config/tokens.hpp` and `modules/sidebar/Wrapper.qml`).
  For the record: end-4 is 460 with height inset by `hyprlandGapsOut`; swaync today
  is 420.
- **D-19-16:** **Bar bell click and `Super+N` both toggle it.** D-18-33's
  deliberately-temporary bell binding repoints from swaync to the QML centre, and
  `Super+N`'s `swaync-client -t -sw` becomes the shell's own IPC/GlobalShortcut
  toggle. Both reference shells expose exactly this bar-button + shortcut pair on
  every top-level surface.
- **D-19-17:** Content order, top to bottom: **header (live count + clear-all) →
  grouped history → toggle grid + volume/brightness/mic sliders pinned as a bottom
  footer.** This deliberately inverts swaync's widget order
  (`title, dnd, volume, slider, buttons-grid, notifications`): in a *notification*
  centre, history gets the top and the space, and the controls become a fixed
  target that never moves.
- **D-19-18:** **No exclusive keyboard focus.** Escape closes it; typing continues
  to reach the focused application. Matches the dashboard drawer, the bar popouts,
  and Caelestia's sidebar (which reserves exclusive focus for its session screen).
- **D-19-19:** **One singleton backend owns all quick-toggle state** (DND, gaming,
  wifi, bluetooth, volume, dark); the drawer's grid and the centre's are pure views
  that render it and call into it. This is how the roadmap's "promote
  `QuickToggles.qml`, do not copy it" note is satisfied — drift becomes
  structurally impossible rather than something to test for (QNOTIF-07).
  — **Reversibility:** costly — both grids and every toggle's call path move onto
  the singleton at once; undoing it means re-pointing each toggle back at its own
  service reader and reintroducing the drift risk this milestone exists to end.
- **D-19-20:** The centre's sliders **reuse `AudioBackend.qml` and
  `BrightnessBackend.qml` as-is**, becoming a third view on backends the bar's
  audio popout and scroll-to-adjust already drive. This also kills swaync's
  `brightnessctl` `cmd_getter`/`cmd_setter` shell-out pair outright.
- **D-19-21:** **A third microphone slider joins volume and brightness** (Caelestia
  shows volume/mic/brightness as independent sliders). *Scope note:* this is a
  deliberate small addition beyond QNOTIF-08's literal "volume and brightness"
  wording, on the user's explicit call. Verified cheap: `AudioBackend.qml:67,82`
  already exposes `inputVolume`, `inputMuted` and `setInputVolume` off
  `Pipewire.defaultAudioSource`, so no new plumbing is required.
- **D-19-22:** Empty state is **full Caelestia parity** — an illustration
  cross-faded in above the headline "All up to date!", tinted to a palette colour.
  Verified feasible: Caelestia's `Colouriser` is a 12-line wrapper around
  `QtQuick.Effects.MultiEffect` (`colorization: 1`,
  `brightness: 1 - sourceColor.hslLightness`), and that module is installed on this
  host at `/usr/lib/qt6/qml/QtQuick/Effects/` with `colorization`/
  `colorizationColor` present. The tint is a single flat colour, so the asset reads
  as a palette-following silhouette. Cost: one image asset in the repo, stowed and
  installed. The controls footer stays pinned, so the surface never changes shape.
- **D-19-23:** The centre **slides from off-screen right and fades, driven by one
  property** — Caelestia's `modules/sidebar/Wrapper.qml` shape:
  `anchors.rightMargin: (-implicitWidth - 5) * offsetScale`,
  `opacity: 1 - offsetScale`, `visible: offsetScale < 1`, one `Behavior`. Position
  and fade stay in lockstep because one number drives both, and the surface stops
  rendering when fully closed. Durations from `Motion.qml`.

#### History, grouping and clearing

- **D-19-24:** **History is serialized to JSON on disk and reloaded on start** —
  both references do this independently (Caelestia's `notifs.json`, end-4's
  `Directories.notificationsPath`). It matters more here than for them: the bar
  auto-restarts (QBAR-10) and QML hot-reloads on file change, so an in-memory-only
  history would evaporate constantly during ordinary theming work.
- **D-19-25:** The store lives at **`~/.local/state/quickshell/notifications.json`**
  — XDG state, not cache (a cache cleaner would wipe it) and not the stow tree
  (which is what LEDGER-07 is in this very phase to fix).
- **D-19-26:** History is **grouped per app, collapsed by default**, each group
  showing the app name, a count badge and an `expand_more` chevron that rotates
  180° when expanded — Caelestia's `NotifGroup.qml`, including its detail that a
  group auto-collapses when it empties.
- **D-19-27:** Groups are ordered by **most-recent activity, newest at top**
  (end-4's `latestTimeForApp`, which explicitly rejects alphabetical).
- **D-19-28:** Clear-all is an **icon button in the header row that scales and
  fades in only when the count is above zero.** Caelestia uses the same `clear_all`
  icon and the same appear-when-non-empty animation but floats it bottom-right with
  `Elevation` — which D-19-17's pinned footer already occupies, so it moves into the
  header beside the live count it acts on. Named divergence, forced by the layout.
- **D-19-29:** Three levels of clearing: **per notification, per app group, and
  clear-all** (Caelestia clears app-group by app-group, filtering `notClosed` by
  `appName` in batches of 30 via a timer so a large history does not stall the UI —
  copy that batching).
- **D-19-30:** History is **capped at ~100 items, oldest dropped on overflow.**
  Named divergence: Caelestia has no cap. Justified here because the whole list is
  re-serialized on change and this shell hot-reloads constantly during theming work,
  so an unbounded file is a real recurring cost.
- **D-19-31:** **Action buttons are hidden on notifications that outlived their
  sender's session.** `ActionInvoked` is a signal back to a process that may be
  gone; a visible button that silently does nothing looks like a broken notification
  server. Keeps QNOTIF-04's promise literal: every action button you can see, works.
  Named divergence — Caelestia keeps them.
- **D-19-32:** Ages render as **relative, live-updating timestamps** ("now", "3m",
  "2h", "yesterday") — Caelestia's behaviour and swaync's `relative-timestamps: true`
  today. Implement with **one shared ticker, not a timer per card** — QBAR-11's
  idle-timer inventory discipline applies to this surface.

#### Suppression and DND

- **D-19-33:** Suppression means **never shown as a popup, but always recorded in
  history.** Both references separate the interruption from the record. It matters
  more here: with no soak window and no rollback, a silently destroyed notification
  leaves no trace at all.
- **D-19-34:** **A focused fullscreen client fully suppresses popups** (QNOTIF-10).
  Caelestia ships both modes — `fullscreenExpireTimeout` shortening *and* full
  suppression; QNOTIF-10's plain wording and the gaming tile's existing tooltip
  promise both point at suppression.
- **D-19-35:** **Gaming mode and DND are independent toggles; either one
  suppresses.** Both references use exactly this OR-shape (DND set **or** a sidebar
  open **or** fullscreen). Gaming mode must not reach in and flip the DND tile's
  visible state — leaving gaming mode would then clear a DND the user had set
  deliberately.
- **D-19-36:** **DND state persists in the shell's own state file** (alongside the
  notification history under `~/.local/state/quickshell/`) **and toggling it fires a
  toast** reading "Do not disturb enabled/disabled" (Caelestia). The toast is
  load-bearing: with DND on there is otherwise no feedback at all that the toggle
  took, especially when driven from `Super+N` rather than by clicking the tile.
- **D-19-37:** **Opening the centre — or flipping DND on — clears the in-flight
  popup stack immediately.** end-4 does this explicitly via
  `Notifications.timeoutAll()` when its media controls open; Caelestia suppresses
  whenever a sidebar is open and clamps popup height to avoid overlap. The cards are
  all in the history that just opened anyway.

#### D-Bus server and the bluetooth pairing prompt (LEDGER-04)

- **D-19-38:** `GetCapabilities` declares **`body`, `body-markup`,
  `body-hyperlinks`, `actions`, `icon-static`, `persistence`** — Caelestia's set
  (`actionsSupported`, `bodyMarkupSupported`, `imageSupported`,
  `persistenceSupported` all true), and `persistence` is honestly true here because
  of D-19-24. **Declare only what is actually implemented** — a false claim is how
  senders get silently misrendered.
  — **Reversibility:** one-way in effect — `body` and `actions` are load-bearing for
  blueman (D-19-39); dropping either later silently reintroduces the GTK-dialog
  regression, and nothing in this repo would fail to catch it.
- **D-19-39:** Bluetooth pairing containment is achieved **purely by declaring the
  capabilities** — the confirmation then renders as an ordinary actioned popup with
  working Accept/Reject, and the notification server contains no bluetooth-specific
  code. Caelestia special-cases nothing either. Grounding: blueman inspects the bus
  name owner's capabilities and, per
  `blueman/gui/Notification.py:295`, falls back to a raw GTK `_NotificationDialog`
  unless **both** `body` and `actions` are present — and that dialog, being an XDG
  toplevel, sits unconditionally *behind* every layer-shell surface in Hyprland,
  which is exactly the G-15-4 failure Phase 15 spent a plan removing for wifi.
  Explicitly **not** doing: routing the confirmation into the Bluetooth panel
  (couples the server to one app), and **not** building an `org.bluez.Agent1` agent
  (the deferred item rejects it as the expensive path).
- **D-19-40:** **Markdown is allowlisted, not passed through.** Render a small
  subset (bold / italic / link), escape everything else, and **confirm before
  opening a link** — show the URL on hover first. Named divergence from Caelestia,
  which renders markup and opens links on click unconfirmed. Justified because any
  process on the session can send a notification, so an unconfirmed click is a
  one-click launcher for a sender-chosen URL — and LEDGER-08's review now covers
  this surface (D-19-44).
- **D-19-41:** QNOTIF-11 is proved by **re-pointing the existing poisoned-two-owner
  fixture at the new owner and running it against the real session** (not
  self-tested), **then again after the server is deliberately killed and respawned.**
  The fixtures to re-point already exist at
  `hypr/.config/hypr/scripts/tests/quickshell-fixtures/`
  (`poisoned-two-owner-busctl-list.txt`, `compliant-busctl-list.txt`).

#### Retirement sequencing (RETIRE-03)

- **D-19-42:** **The server and centre ship first, GATE-02 passes, and then one
  final deletion plan removes everything.** Nothing is deleted before the human
  render gate has judged the replacement. The retirement-checklist script reports
  zero hits before *and* after that plan. **The autostart swap — dropping
  `swaync-launch.sh`'s line from `autostart.lua:140` and adding the new owner's — is
  one atomic edit inside it**, never two commits, because every boot in between
  silently runs the two-owner race.
  — **Reversibility:** one-way — there is no soak window and no rollback path; the
  package leaves the host in the same phase. This is why D-19-08 (`replaces_id`) and
  D-19-41 (live two-owner check) carry extra verification weight and must be green
  before the gate.

#### Theming the new surfaces

- **D-19-43:** The popup and centre read **`BarRoles` rows, extended with
  notification-specific roles** — not `Colours.*` directly. 18.1 D-04/D-24
  established that every bar colour is a named `BarRoles` row sourced from a
  Material You value, `quickshell-doctor` greps the literal `Colours\.` pattern as a
  violation, and the bell already uses `fillNotification`. **No matugen template is
  needed at all**: QML hot-reloads `Colours.qml` natively, which is precisely why
  waybar's `SIGUSR2` post_hook died in Phase 18. `[templates.swaync]`
  (`matugen/.config/matugen/config.toml:39-41`) and its 2 contract entries are
  deleted with nothing replacing them.

#### Debt items

- **D-19-44:** LEDGER-08's security review covers **the panel family *plus* the new
  D-Bus attack surface.** Phase 15's named gaps are the floor, but this phase takes
  a system-wide bus name any process on the session can send to — untrusted
  `summary` / `body` / `app_name` / `image` data from arbitrary senders now renders
  inside the shell, and D-19-40's markup widens that. Reviewing the panels without
  the new inbound surface would miss the larger half.
- **D-19-45:** LEDGER-07 is fixed by **moving `current.jpg` out of the stow tree
  into `~/.local/state/theme/`** and repointing its consumers. The symlink is
  runtime state, not a dotfile — the same reasoning that puts notification history
  in state (D-19-25). Grounding: `WALLPAPER_DIR="$HOME/Pictures/Wallpapers"`
  (`theme-engine/.config/theme-engine/lib/wallpaper.sh:14`) is stow-managed from the
  tracked `wallpapers/Pictures/Wallpapers/` tree, so **nothing** written there can
  avoid dirtying git — the `ln -sfr … current.jpg` calls at `wallpaper.sh:242`, `263`
  and `336` are all the same bug. Chosen over `.gitignore`, which would leave runtime
  state inside the stow tree for Phase 22's fresh-install gate to keep excusing.
- **D-19-46:** `theme-stress-test`'s `REPRESENTATIVE_FILES` (line 309) **drops
  `swaync.css` and adds nothing in its place.** The remaining
  `hyprland-tokens.lua`, `wleave.css`, `gtk-4.0-colors.css` and `kitty.conf` still
  cover the gtk-css, lua-table and conf formats, and under D-19-43 the QML surfaces
  produce no matugen artefact to check. Note the script also references `swaync.css`
  in its token-parity commentary around lines 247 and 294 — both need the same pass.

### Claude's Discretion

- Exact px values for the drag thresholds (D-19-05 expand, D-19-07 dismiss), the
  ring-progress stroke width (D-19-09), and the header/footer paddings — take them
  from `Motion.qml` / `Design.qml` tokens and the bar's existing capsule metrics
  rather than inventing numbers.
- The specific empty-state illustration asset (D-19-22) and its source.
- Which of the six LEDGER-04 debug sessions resolve versus take an
  explicitly-reasoned deferral — only the bluetooth one has its resolution path
  fixed here (D-19-39). Note one of the six (the `GradientBorder` session) is
  already closed by LEDGER-01 in Phase 18, so verify the live count before planning.

### Deferred Ideas (OUT OF SCOPE)

- **Routing the bluetooth pairing confirmation into the Bluetooth panel itself** —
  what G-15-7 originally asked for, and technically possible via
  `Quickshell.Services.Notifications`' per-notification `actions` + `invoke`.
  Deliberately not done (D-19-39): it couples the notification server to one app.
  Revisit only if the plain actioned-popup path proves insufficient in real use.
- **An `org.bluez.Agent1` D-Bus agent** — explicitly rejected as the expensive path
  by `15-…/deferred-items.md`. Not a future phase, just recorded as considered.
- **A caps-lock / OSD-style indicator surface** — Phase 20 owns this. Noted here
  only because D-19-21's mic slider brushes against Caelestia's OSD, which is where
  Caelestia puts its three-slider column.
- **Making the QNOTIF-11 two-owner check a standing `quickshell-doctor` check** run
  on every invocation rather than only as this phase's gate. Considered and not
  taken (D-19-41 keeps it to the gate); worth revisiting if a bus-ownership
  regression ever recurs.
- **A `Colours.qml` representative in `theme-stress-test`** — considered as a
  replacement for the dropped `swaync.css` (D-19-46) and declined, since it is a
  different artefact class than the CSS/conf sheets the check parses. If the QML
  palette ever needs token-parity coverage, this is the shape it would take.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| QNOTIF-01 | Shell owns `org.freedesktop.Notifications`; apps' notifications reach it directly | `NotificationServer` QML type verified in installed quickshell 0.3.0-2's own qmltypes — see § Standard Stack / Architecture Patterns |
| QNOTIF-02 | Popups stack and reflow smoothly | Caelestia's `Notifs.qml`/`NotifData.qml`/`modules/notifications/Notification.qml` read directly — see § Architecture Patterns Pattern 1 |
| QNOTIF-03 | Swipe dismiss | `MouseArea` + `drag.axis: Drag.XAxis` pattern in Caelestia's `Notification.qml:58-82`, quoted verbatim below |
| QNOTIF-04 | Action buttons work, reach the sending app | `NotificationAction.invoke()` confirmed in qmltypes; §"replaces_id / ActionInvoked" below covers the fault-injection angle and the dead-sender gap (D-19-31) |
| QNOTIF-05 | `replaces_id` in-place update | § "replaces_id mechanics" — Caelestia's `Connections` re-bind pattern is the concrete mechanism; flagged MEDIUM confidence (C++ internals not directly read) |
| QNOTIF-06 | Slide-out centre, history, clear-all | Caelestia `modules/sidebar/Wrapper.qml`, `NotifGroup.qml` read directly |
| QNOTIF-07 | Centre carries toggle grid, no drift vs Super-menu | This repo's own `QuickToggles.qml` read directly — promotion shape documented in § Architecture Patterns Pattern 4 |
| QNOTIF-08 | Working volume/brightness sliders | This repo's own `AudioBackend.qml`/`BrightnessBackend.qml` read directly — **critical finding: `BrightnessBackend` has no absolute setter**, see § Common Pitfalls |
| QNOTIF-09 | DND persists across restart | `PersistentProperties` investigated and found NOT to survive a full process restart (only QML hot-reload) — see § Common Pitfalls; confirms D-19-36's own file-based choice is correct |
| QNOTIF-10 | Suppress on centre-open / fullscreen focus | This repo's OWN already-shipped fullscreen-detection pattern found at `shell.qml:448-462` — directly reusable, not new work |
| QNOTIF-11 | Live two-owner check | Doctor fixture mechanics fully traced (`quickshell-doctor:244-246,536-542,866-894,2154-2163`) — exact repoint steps documented |
| RETIRE-03 | swaync removed, checklist zero-hits | Every reference site verified directly this session with line numbers — see § swaync Removal Surface |
| LEDGER-04 | 6 open debug sessions resolved/deferred | **Ground truth taken live**: 5 files currently in `.planning/debug/` (not 6) — see § LEDGER-04 Ground Truth |
| LEDGER-07 | `theme-stress-test` clean run | `wallpaper.sh` and `theme-stress-test` read directly, line numbers confirmed |
| LEDGER-08 | Panel-family security review + verifier re-run | `15-SECURITY.md` read in full — the "verifier" is the `gsd-security-auditor` agent; one concrete open gap (Flag #2) identified |
</phase_requirements>

## Summary

The core mechanism is not something to build from scratch: Quickshell 0.3.0-2, already
installed on this host, ships `Quickshell.Services.Notifications` with a `NotificationServer`
QML type whose capability flags map 1:1 onto D-19-38's declared set, a `Notification` type
carrying every DBus notification field as a bindable QML property, and a `NotificationAction`
type with a working `invoke()`. Both reference shells (Caelestia — checked out locally at
`~/.claude/jobs/4517c040/tmp/caelestia-shell` — and end-4) build directly on this API with no
patching, and Caelestia's actual source answers nearly every one of D-19-00's "what does
Caelestia do here" questions with quotable code, not paraphrase.

The single riskiest mechanic — `replaces_id` in-place update (QNOTIF-05) — has no dedicated
QML property or signal. Caelestia's own consumer code proves the pattern instead: a
`NotificationServer.onNotification` handler only fires once per *new* D-Bus id; a `replaces_id`
re-send reuses the same underlying `Notification` object and fires its existing
`summaryChanged`/`bodyChanged`/`expireTimeoutChanged`/... signals, which the QML layer
subscribes to via a `Connections` block. Because the object is reused and never re-emitted
through `onNotification`, the list holding it never reorders and the delegate never re-animates
— this is *why* D-19-08's "does not re-animate or reorder" requirement falls out for free from
the correct binding shape, rather than needing an explicit "don't animate" branch.

Three findings materially change what the planner should scope, beyond what CONTEXT.md's
decisions already fix:

1. **`BrightnessBackend.qml` has no absolute setter** — only a relative `adjust(steps: int)`
   verb (`brightnessctl set +N%`/`-N%`). D-19-20's "reuse as-is" is achievable for the audio
   slider (`AudioBackend` has absolute `setMasterVolume`/`setInputVolume`) but the brightness
   slider needs either a delta-computation wrapper in the centre or a small addition to
   `BrightnessBackend` itself — flagged as an open question, not resolved by CONTEXT.md.
2. **`Quickshell.PersistentProperties` does not survive a full process restart** — its
   prototype chain (`PersistentProperties` → `Reloadable`) ties it to Quickshell's QML
   *hot-reload* event, not to disk persistence across a killed-and-respawned process. Since
   QBAR-10's restart wrapper creates a genuinely new process, Caelestia's own DND-persistence
   pattern (`PersistentProperties { reloadableId: "notifs" }`) would silently fail QNOTIF-09 on
   this host. D-19-36's file-based choice is the right one and should not be second-guessed —
   this finding is recorded so nobody "simplifies" it toward Caelestia's pattern later.
3. **LEDGER-04's live count is 5, not 6** — the `GradientBorder` session was already moved to
   `.planning/debug/resolved/` by Phase 18's LEDGER-01. The five remaining files
   (`bluetooth-enable-inert.md`, `wifi-hidden-network-not-detected.md`,
   `wifi-hidden-network-unsupported.md`, `wifi-scan-progress-feedback.md`,
   `wifi-wrong-password-external-dialog.md`) are **all independent of the notification-server
   work** — D-19-39 resolves the *separate* G-15-7 bluetooth-pairing-prompt item (tracked in
   Phase 15's `deferred-items.md`, not a file in `.planning/debug/` at all), not
   `bluetooth-enable-inert.md`'s rfkill-block root cause. The planner must give each of the five
   its own resolve-or-defer disposition; none is fixed as a byproduct of QNOTIF work.

**Primary recommendation:** build directly on `Quickshell.Services.Notifications` with the
capability set in D-19-38, structure the popup/centre exactly as Caelestia's real source shows
(quoted below), persist history and DND to `~/.local/state/quickshell/*.json` via `FileView`
(never `PersistentProperties`), reuse this repo's own already-shipped fullscreen-detection
pattern at `shell.qml:448` verbatim, and treat LEDGER-04's five debug sessions as five separate,
notification-server-independent disposition decisions.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| D-Bus notification receipt (`org.freedesktop.Notifications`) | Quickshell process (shell) | — | `NotificationServer` is a QML/C++ component inside the same process as the bar (D-19 shares Phase 18's process); no separate daemon |
| Popup rendering, gestures, timers | Quickshell process (QML) | — | Pure client-side QML state; no external process |
| Centre (history, grouping, DND) | Quickshell process (QML) | `~/.local/state/quickshell/*.json` (persistence) | State lives in-process at runtime, mirrored to disk for restart survival |
| Quick-toggle grid (shared) | Quickshell process (QML singleton) | Native services (Pipewire, NetworkManager, BlueZ via existing backends) | D-19-19's singleton is the sole owner; toggles delegate writes to existing per-domain backends, never touch the native service directly from two call sites |
| Volume/brightness/mic sliders | Existing backend singletons (`AudioBackend.qml`, `BrightnessBackend.qml`) | Centre UI (view only) | D-19-20 explicitly reuses, not rebuilds, these backends — the centre is a third *view*, never a third writer |
| Fullscreen-focus suppression | Quickshell process, via `Quickshell.Hyprland`'s `Hyprland` singleton | Hyprland compositor (source of truth) | Already-proven pattern at `shell.qml:448-462`; Hyprland is the authority, Quickshell only reads `lastIpcObject` |
| swaync retirement (package, config, contract, matugen, autostart, doctor fixtures) | Filesystem / package manager / theme-engine contract | `retirement-check` script (verification) | Deletion is a repo/host-state change, not a runtime QML concern |
| Two-owner D-Bus proof (QNOTIF-11) | `quickshell-doctor` (bash, live `busctl`) | Quickshell process (subject under test) | The doctor is an external verifier; it must never be self-tested against a fixture alone for the live pass |
| Security review (LEDGER-08) | `gsd-security-auditor` agent | Threat register document (`19-SECURITY.md`) | Verifier tooling already established in this repo (Phase 15's `15-SECURITY.md`); re-run over the gap-closure round, not a new tool |

## Standard Stack

### Core

| Library/Module | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `Quickshell.Services.Notifications` | Ships with quickshell 0.3.0-2 (already installed, confirmed via `pacman -Qi quickshell`) | Owns the D-Bus name, exposes `NotificationServer`/`Notification`/`NotificationAction` | [VERIFIED: /usr/lib/qt6/qml/Quickshell/Services/Notifications/quickshell-service-notifications.qmltypes] — the only notification-server implementation this shell's toolkit ships; both reference shells use it unmodified |
| `QtQuick.Shapes` (`Shape`/`ShapePath`/`PathAngleArc`) | Ships with qt6-declarative (already installed) | The ring-progress indicator over the app icon (D-19-09) | [VERIFIED: Caelestia's `modules/notifications/Notification.qml:189-223`] — `PathAngleArc.sweepAngle: ((hints.value ?? 0)/100)*360`, not a custom `Canvas` or image-based arc |
| `QtQuick.Effects.MultiEffect` | Ships with qt6-declarative, installed at `/usr/lib/qt6/qml/QtQuick/Effects/` | Empty-state illustration tint (D-19-22) | [VERIFIED: `ls /usr/lib/qt6/qml/QtQuick/Effects/`] — `colorization`/`colorizationColor` present; already the mechanism CONTEXT.md's D-19-22 specifies |
| `Quickshell.Hyprland` (`Hyprland` singleton, `HyprlandMonitor`, `HyprlandToplevel`) | Ships with quickshell 0.3.0-2 | Fullscreen-focus detection (QNOTIF-10) | [VERIFIED: `/usr/lib/qt6/qml/Quickshell/Hyprland/_Ipc/quickshell-hyprland-ipc.qmltypes:105-404`] AND already live in this repo at `shell.qml:448` |
| `Quickshell.Io` (`FileView`, `IpcHandler`, `Process`) | Ships with quickshell 0.3.0-2 | JSON persistence (history + DND), `qs ipc call`-style summon/toggle verbs | Already the pattern this repo's `shell.qml` uses for `bar`/`panel`/`overview` IPC targets (`shell.qml:498-500,589-591`) |

**No new external packages are introduced by this phase.** `swaync` (0.12.6-1, official `extra`
repo) is *removed*, not replaced by another package — see § Package Legitimacy Audit.

### Supporting

| Item | Purpose | When to Use |
|------|---------|-------------|
| `Quickshell.iconPath(appIcon)` | Icon-theme resolution for D-19-12's fallback chain | Already used by Caelestia's `Notification.qml:168` and `NotifGroup.qml:104,149` for exactly this fallback |
| `Text.MarkdownText` | Base for D-19-40's allowlisted markdown | Qt's built-in textFormat renders CommonMark-ish markdown; D-19-40 needs a **pre-processing allowlist step** before handing text to it — see § Common Pitfalls, this is not "use MarkdownText and done" |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `Quickshell.Services.Notifications` (native) | A hand-rolled D-Bus interface via `Quickshell.DBus` | Never justified — the native service module exists precisely to avoid this; both reference shells confirm it is sufficient |
| `PersistentProperties` for DND | A `FileView`-backed JSON property (D-19-36's actual choice) | `PersistentProperties` is confirmed NOT to survive a full process kill+respawn (only a QML hot-reload) — see § Common Pitfalls. Do not substitute it in even though Caelestia uses it; Caelestia's own shell does not have this repo's `QBAR-10` auto-restart-on-crash wrapper as a normal event |
| Custom drag/swipe `MouseArea` logic | Copy Caelestia's `Notification.qml:43-90` `MouseArea` block near-verbatim | Caelestia's implementation already handles the pause-timer/expand-threshold/dismiss-threshold/middle-click interaction in ~50 lines; reinventing it risks missing an edge case (e.g., the `!containsMouse` re-arm-timer-on-release check at line 68) |

**Installation:** none — every module above ships inside already-installed `quickshell` and
`qt6-declarative` packages.

## Package Legitimacy Audit

**Not applicable — this phase installs no new external packages.** `swaync` (already installed,
`extra` repo, version 0.12.6-1, verified via `pacman -Qi swaync`) is uninstalled by RETIRE-03;
nothing replaces it at the package-manager level. If the planner discovers a need for a new
package during implementation (e.g., an icon asset generator for D-19-22), run the Package
Legitimacy Gate protocol against it at that time.

## Architecture Patterns

### System Architecture Diagram

```
D-Bus session bus
      │
      │ org.freedesktop.Notifications (Notify, GetCapabilities, CloseNotification)
      ▼
┌─────────────────────────────────────────────────────────────┐
│ Quickshell process (shared with the bar, QBAR-10 restart)    │
│                                                                │
│  NotificationServer (Quickshell.Services.Notifications)       │
│    onNotification(notif) ──────► new-id path                 │
│    replaces_id re-send ────────► SAME Notification object,    │
│                                    property-changed signals    │
│                                    only (no onNotification)    │
│         │                                                      │
│         ▼                                                      │
│  NotifData wrapper (1:1 per Notification, tracks popup/closed) │
│         │                        │                             │
│         ▼                        ▼                             │
│  Popup stack (PanelWindow,   Centre PanelWindow                │
│  top-right anchor)           (right-edge slide-out)            │
│         │                        │                             │
│         │                        ├─ QuickToggles singleton ───►│ Pipewire / NM / BlueZ
│         │                        │   (D-19-19, shared w/ drawer)│  backends (existing)
│         │                        ├─ AudioBackend (existing) ───►│ Pipewire
│         │                        └─ BrightnessBackend (existing)►│ brightnessctl
│         │                                                      │
│         ▼                                                      │
│  FileView → ~/.local/state/quickshell/notifications.json       │
│  FileView → ~/.local/state/quickshell/ (DND flag, same dir)    │
│                                                                │
│  IpcHandler target:"notifs" (clear/toggleDnd/...) ◄──── Super+N GlobalShortcut
│                                                          (keybinds.lua, replaces
│                                                           swaync-client -t -sw)
└─────────────────────────────────────────────────────────────┘
         ▲
         │ ActionInvoked signal (D-Bus) — the notification's action, invoked from the
         │ popup/centre, is routed back through NotificationServer to the ORIGINAL sender
         │ process via the NotificationAction.invoke() method.
      Sending application (e.g. blueman, a download manager)
```

### Recommended Project Structure

```
quickshell/.config/quickshell/modules/
├── notifications/               # NEW — mirrors Caelestia's own top-level split
│   ├── NotificationServer.qml   # or fold into services/ — singleton owning the D-Bus name
│   ├── NotifData.qml            # per-notification wrapper (popup/closed/lock/timeStr)
│   ├── NotifPopupStack.qml      # top-right PanelWindow, stack/clamp/+N-more
│   └── NotifCard.qml            # the popup card body (image/appIcon/summary/body/actions)
├── centre/                      # NEW — the third top-level frame (D-19-14)
│   ├── NotifCentre.qml          # right-edge PanelWindow, Wrapper.qml-style offsetScale slide
│   ├── NotifGroup.qml           # per-app grouped history row
│   └── CentreFooter.qml         # pinned toggle grid + sliders
├── dashboard/
│   └── QuickToggles.qml         # PROMOTED to a shared singleton per D-19-19, not copied
├── bar/
│   ├── ClockActionsCapsule.qml  # NotificationSource component's INTERNALS repointed;
│   │                            # its public contract (unreadCount, dndActive, available,
│   │                            # openCentre(), toggleDnd()) MUST stay unchanged (see file's
│   │                            # own comment at line 599-609)
│   ├── BarRoles.qml             # extended with notification-specific roles (D-19-43)
│   ├── AudioBackend.qml         # (in dashboard/) reused as-is
│   └── BrightnessBackend.qml    # reused, but see Common Pitfalls — needs an absolute setter
```

### Pattern 1: `NotificationServer` capability declaration and receipt

**What:** The exact QML surface for owning the bus name, verified directly against the
installed plugin's qmltypes (not paraphrased).

**Verbatim property list** [VERIFIED: /usr/lib/qt6/qml/Quickshell/Services/Notifications/quickshell-service-notifications.qmltypes:180-260] — `NotificationServerQml`, exported as `Quickshell.Services.Notifications/NotificationServer 0.0`:

```
keepOnReload: bool
persistenceSupported: bool
bodySupported: bool
bodyMarkupSupported: bool
bodyHyperlinksSupported: bool
bodyImagesSupported: bool
actionsSupported: bool
actionIconsSupported: bool
imageSupported: bool
inlineReplySupported: bool
trackedNotifications: UntypedObjectModel (readonly)
extraHints: list<string>
signal notification(Notification *notification)
```

**Mapping to D-19-38's declared capability set** (`body`, `body-markup`, `body-hyperlinks`,
`actions`, `icon-static`, `persistence`):

| D-19-38 wire capability | QML property to set `true` |
|---|---|
| `body` | `bodySupported` |
| `body-markup` | `bodyMarkupSupported` |
| `body-hyperlinks` | `bodyHyperlinksSupported` |
| `actions` | `actionsSupported` |
| `icon-static` | `imageSupported` |
| `persistence` | `persistenceSupported` |

`action-icons`, `inline-reply` and `sound` are deliberately left `false`/default — D-19-38's own
text: "declare only what is actually implemented."

**Example (adapted from Caelestia's `services/Notifs.qml:83-103`, verified live source):**

```qml
// Source: ~/.claude/jobs/4517c040/tmp/caelestia-shell/services/Notifs.qml:83-103
NotificationServer {
    id: server

    keepOnReload: false
    actionsSupported: true
    bodyHyperlinksSupported: true
    bodyImagesSupported: true      // maps to "icon-static" for images-in-body, distinct from imageSupported
    bodyMarkupSupported: true
    imageSupported: true
    persistenceSupported: true

    onNotification: notif => {
        notif.tracked = true;   // MUST set tracked=true or Quickshell may not retain the object
        // wrap `notif` in a per-notification data object here; prepend to the list
    }
}
```

**When to use:** exactly once, in a singleton mounted at shell root (same pattern as this
repo's `AudioBackend`/`MediaBackend` singletons).

### Pattern 2: `replaces_id` in-place update — the mechanism, not a property

**What:** There is no `replacesId` property anywhere in the qmltypes — [VERIFIED:
/usr/lib/qt6/qml/Quickshell/Services/Notifications/quickshell-service-notifications.qmltypes]
lists `Notification`'s full property set (`id`, `tracked`, `lastGeneration`, `expireTimeout`,
`appName`, `appIcon`, `summary`, `body`, `urgency`, `actions`, `hasActionIcons`, `resident`,
`transient`, `desktopEntry`, `image`, `hasInlineReply`, `inlineReplyPlaceholder`, `hints`) with
**no field named anything like `replaces`**. The replacement mechanism is inferred behaviourally
from Caelestia's consumer code, not read from Quickshell's C++ source (not installed on this
host) — tagged MEDIUM confidence accordingly.

**The evidence for the mechanism** [CITED: Caelestia `services/NotifData.qml:112-169`]: every
mutable field the wrapper exposes is kept live via a `Connections { target: notif.notification
}` block with one handler per `*Changed` signal (`onSummaryChanged`, `onBodyChanged`,
`onExpireTimeoutChanged`, `onUrgencyChanged`, `onActionsChanged`, `onHintsChanged`, etc.) —
never a second `NotificationServer.onNotification` firing for the same logical notification.
Combined with `services/Notifs.qml:94-102`'s `onNotification` prepending a *new* wrapper object
to the list only when a genuinely new id arrives, this means: **a `replaces_id` re-send reuses
the same underlying `Notification` QObject** (same `id`), and Quickshell fires its normal
per-property changed signals on it rather than re-emitting `NotificationServer.notification`.

**Concrete implementation shape:**

```qml
// Source: adapted from Caelestia's services/NotifData.qml:112-169
Connections {
    target: notifWrapper.notification
    function onSummaryChanged(): void { notifWrapper.summary = notifWrapper.notification.summary; }
    function onBodyChanged(): void { notifWrapper.body = notifWrapper.notification.body; }
    function onExpireTimeoutChanged(): void {
        notifWrapper.expireTimeout = notifWrapper.notification.expireTimeout;
        // restarting the dismiss Timer here (bound to expireTimeout) is what gives D-19-08's
        // "restarts its dismiss timer" for free — no extra logic needed if the Timer's
        // `interval` is bound to this property.
    }
    function onHintsChanged(): void { notifWrapper.hints = notifWrapper.notification.hints; }
    // ...one handler per field the card renders
}
```

Because the wrapper object is never destroyed and re-created, and the `ListView`/`Repeater`
model holding it never removes+re-inserts it, **the delegate is never re-created and the list
never reorders** — D-19-08's "does not re-animate or reorder the stack" is a structural
consequence of this binding shape, not something that needs an explicit `if (isReplace)` guard.

**Fault-injection fixture shape (for QNOTIF-05's extra verification weight):** send two
`org.freedesktop.Notifications.Notify` calls back-to-back with the same `replaces_id` (via
`notify-send -p` capturing the id, or a raw `busctl call` / `gdbus call` against
`org.freedesktop.Notifications`), and assert: (a) exactly one popup card exists after both
calls, not two; (b) the card's position in the stack (Y offset / list index) is unchanged
between call 1 and call 2; (c) the dismiss timer's remaining time resets to the full interval
after call 2, not continuing call 1's countdown.

### Pattern 3: Popup card gestures — drag, hover, middle-click (D-19-05/06/07/10)

**Verbatim, from the live reference source** [CITED: Caelestia `modules/notifications/Notification.qml:43-90`]:

```qml
MouseArea {
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
    preventStealing: true

    onEntered: root.modelData.timer.stop()
    onExited: {
        if (!pressed)
            root.modelData.timer.start();
    }

    drag.target: parent
    drag.axis: Drag.XAxis

    onPressed: event => {
        root.modelData.timer.stop();
        startY = event.y;
        if (event.button === Qt.MiddleButton)
            root.modelData.close();
    }
    onReleased: event => {
        if (!containsMouse)
            root.modelData.timer.start();
        if (Math.abs(root.x) < root.implicitWidth * Config.notifs.clearThreshold)
            root.x = 0;
        else
            root.modelData.popup = false;   // dismiss from popup view; stays in history
    }
    onPositionChanged: event => {
        if (pressed) {
            const diffY = event.y - startY;
            if (Math.abs(diffY) > Config.notifs.expandThreshold)
                root.expanded = diffY > 0;
        }
    }
    onClicked: event => {
        if (event.button !== Qt.LeftButton) return;
        const actions = root.modelData.actions;
        if (actions.length === 1) actions[0].invoke();   // D-19-10 default-action click
    }
}
```

Key details a paraphrase would lose: `drag.axis: Drag.XAxis` constrains the swipe to
horizontal even though `onPositionChanged` separately reads `event.y` for the *vertical*
expand gesture (D-19-05) — the two gestures share one `MouseArea` and are disambiguated by
which threshold fires first, not by two different areas. Dismissing sets `popup = false`, never
destroys the underlying data object — this is the concrete mechanism behind D-19-07's "no
gesture is destructive."

### Pattern 4: Centre slide-out frame — one-property animation

**Verbatim** [VERIFIED: Caelestia `modules/sidebar/Wrapper.qml:1-38`]:

```qml
Item {
    readonly property bool shouldBeActive: screenState.sidebar && Config.sidebar.enabled
    property real offsetScale: shouldBeActive ? 0 : 1

    visible: offsetScale < 1
    anchors.rightMargin: (-implicitWidth - 5) * offsetScale
    implicitWidth: Tokens.sizes.sidebar.width
    opacity: 1 - offsetScale

    Behavior on offsetScale { Anim {} }
}
```

Matches D-19-23 exactly. In this repo, `Anim {}` becomes a `Behavior` reading `Motion.qml`
duration/easing tokens (never a bespoke number, per D-19-13/D-19-23's own text). `visible:
offsetScale < 1` is what stops the surface from rendering (and presumably compositing) once
fully closed — carry this forward for the zero-idle-when-closed discipline this repo already
holds bar/dashboard surfaces to.

### Pattern 5: Promoting `QuickToggles.qml` to a shared singleton (D-19-19/QNOTIF-07)

**What exists today** [VERIFIED: `quickshell/.config/quickshell/modules/dashboard/QuickToggles.qml`]:
an `Item`-rooted component (not a singleton) instantiated once by the dashboard drawer, reading
truth from `swaync`'s own `buttons-grid.actions` config for DND (per its own header comment,
"Backend truth table (D-27)") and from three backend properties threaded in from
`DashboardTab.qml` (`audioBackend`, `wifiBackend`, `bluetoothBackend`). Its rendering is a
"pending model" — pressing acknowledges instantly but the lit state is a pure read of backend
truth, never assigned by the press itself.

**What D-19-19 requires:** convert this into a `pragma Singleton` type (the same conversion
`Colours.qml`/`Motion.qml`/`Design.qml` already went through per this repo's own established
pattern — see 12-06's decision log: "Colours.qml/Motion.qml need BOTH pragma Singleton and
qmldir's singleton keyword to resolve bare TypeName.property access"), moving DND ownership OFF
the `swaync-client -dn/-df` CLI call and onto the same `FileView`-backed JSON property the
notification history/DND state file already carries (D-19-36). Both the dashboard drawer's
grid instance and the new centre's grid instance then bind to the SAME singleton instance —
neither owns state, both are pure views. The "pending model" pattern (press → instant ripple →
truth-driven lit state) should be preserved unchanged; only DND's truth *source* moves from a
`swaync-client` subprocess read to the singleton's own persisted property.

**Pitfall to avoid:** the file's own header comment already documents a past mistake — assuming
a bare `id`-based lookup across separate registered component types would resolve
(`dashboardWindow.spacingLg`). It does not; only a `pragma Singleton` type resolves that way.
Do not attempt the "shared instance passed down via property" approach that this same file's
header explicitly failed at before landing on the singleton pattern for `Design`.

### Pattern 6: Fullscreen-focus detection — already shipped in this repo, reuse verbatim

**What exists today** [VERIFIED: `quickshell/.config/quickshell/shell.qml:448-462`, this repo's
own DASH-08 dashboard-drawer fullscreen guard]:

```qml
readonly property bool fullscreenBlocking: (Hyprland.activeToplevel?.lastIpcObject?.fullscreen ?? 0) === 2

Connections {
    target: Hyprland
    function onRawEvent(event) {
        if (event.name === "fullscreen") {
            Hyprland.refreshToplevels();
        }
    }
}
```

This is QNOTIF-10's exact mechanism, already proven live on this host (the comment at line 452
notes the "fullscreen" socket2 event name was "confirmed live this session via a raw socket
read — not assumed"). `Hyprland.activeToplevel` is the `Quickshell.Hyprland` singleton's
currently-focused window; `lastIpcObject` is the raw `hyprctl activewindow`-shaped JSON, whose
`fullscreen` field is `0` (none), `1` (maximized), or `2` (true fullscreen) — this repo checks
`=== 2` specifically, matching "fullscreen" not "maximized."

**Difference from Caelestia's own version** [CITED: Caelestia `services/Notifs.qml:24-30`]:
Caelestia iterates every monitor's active workspace toplevels (`monitor.activeWorkspace.toplevels.values.some(...)`),
because it must answer "is ANY monitor fullscreen" for a multi-monitor setup. This repo has one
monitor (`DP-1`, per QS-03's permanently-dropped per-screen fan-out) and already narrows to
`activeToplevel` (the focused one) rather than scanning all toplevels — the simpler,
single-monitor-correct form. Do not port Caelestia's multi-monitor loop; it would be dead code
here per D-13/QS-03.

### Anti-Patterns to Avoid

- **Copying Caelestia's `PersistentProperties`-based DND storage.** Confirmed NOT to survive a
  full process restart on this host's Quickshell version — see § Common Pitfalls. D-19-36
  already specifies the correct (file-based) approach; don't "simplify" toward Caelestia's.
- **Declaring a new `BarRoles` colour role as `property string` instead of `property color`.**
  This is the EXACT root cause of Phase 18.1's GATE-02 first-run failure (all bar surfaces
  rendering opaque black) — [VERIFIED: `ROADMAP.md`'s Phase 18.1 section, "Colours.qml:106
  declares alpha-blended roles... as `property string`, not `property color`"]. Every new
  notification-specific `BarRoles` row (D-19-43) must be `property color`, and must be probed
  for a *resolved numeric value*, not just "is an object" — the same verification-method gap
  that let the original bug ship.
- **Building a custom D-Bus interface instead of `NotificationServer`.** Not attempted by either
  reference shell; no reason to attempt it here.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| D-Bus notification receipt/ownership | A custom `org.freedesktop.Notifications` D-Bus service implementation | `Quickshell.Services.Notifications.NotificationServer` | Already ships in the installed quickshell; both reference shells use it unmodified; hand-rolling risks getting `GetCapabilities`/`CloseNotification`/id-allocation semantics subtly wrong against the freedesktop spec |
| Ring progress indicator | A `Canvas`-based arc drawn with manual trigonometry | `QtQuick.Shapes`' `PathAngleArc` (`Shape`/`ShapePath`) | Already the mechanism Caelestia ships (`Notification.qml:189-223`); native GPU-accelerated path rendering, not a raster canvas re-drawn every frame |
| Icon resolution fallback chain | Manual desktop-entry parsing + icon-theme directory walking | `Quickshell.iconPath(appIcon)` | Already the mechanism both `Notification.qml:168` and `NotifGroup.qml:104,149` use; Quickshell's own icon-theme resolver handles the XDG icon-theme spec correctly |
| Markdown rendering | A full CommonMark parser | Qt's `Text.MarkdownText` **behind a pre-processing allowlist filter** | D-19-40 wants bold/italic/link ONLY — Qt's `MarkdownText` renders the full CommonMark grammar (headers, code blocks, images, etc.), so a hand-written regex allowlist stage that strips everything except `**bold**`/`*italic*`/`[text](url)` before handing to `MarkdownText` is required either way; don't write a parser, write a filter |
| Relative timestamp formatting ("3m", "2h", "yesterday") | Per-card computation with per-card timers | One shared ticker (QBAR-11 discipline) computing all visible timestamps, copying Caelestia's `updateTimeStr()` bucket logic (`NotifData.qml:171-193`) | D-19-32 explicitly requires "one shared ticker, not a timer per card" |

**Key insight:** almost nothing in this phase needs new machinery — the Quickshell toolkit
already ships the hard parts (D-Bus server, icon resolution, path-based rendering), and both
reference shells' real source is available locally to copy interaction logic from nearly
verbatim. The actual engineering risk is in the *omissions* — no native `replaces_id` property,
no absolute brightness setter, no "sender session gone" signal (see Open Questions) — not in
reimplementing something Quickshell already provides.

## Runtime State Inventory

> Phase touches package retirement (swaync) and a state-location migration (LEDGER-07's
> `current.jpg`), so this section applies.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | swaync itself is stateless — it holds no persisted history, no database, no user_id-keyed store. Its only on-disk artefacts are its own package files, `swaync/.config/swaync/config.json`, `swaync/.config/swaync/style.scss`, and the matugen-rendered `~/.local/state/theme/swaync.css`/`swaync-style.css` (engine-owned, already covered by `contract.json`'s `engine_owned_files`). **The new notification server introduces genuinely new stored data** — `~/.local/state/quickshell/notifications.json` (history) and DND's persisted flag in the same directory — this is new data to create correctly from day one (D-19-24/25/36), not a migration of existing swaync data (swaync never persisted history). |
| Live service config | swaync runs as a plain autostart-launched process (`swaync-launch.sh`, via `hl.exec_cmd`), not a systemd unit, not D-Bus-activated — [VERIFIED: `hypr/.config/hypr/config/autostart.lua:140`]. No hidden UI-configured state exists outside `config.json`/`style.css`, both tracked in git. |
| OS-registered state | **The D-Bus name ownership itself is the OS-registered state that must transfer atomically** — this is exactly what D-19-41/QNOTIF-11's two-owner check exists to verify. No systemd unit, no XDG autostart `.desktop` file, no D-Bus service-activation file (`org.freedesktop.Notifications.service`) exists for swaync on this host — [VERIFIED: `pacman -Ql swaync` shows no `.service`/`.desktop` files; it is launched purely via the repo's own `autostart.lua` exec-once line]. |
| Secrets/env vars | None found — swaync's config carries no secrets, no env-var-driven behaviour beyond the standard `HOME`/`XDG_*` set. |
| Build artifacts / installed packages | `swaync` package itself (0.12.6-1, `extra` repo) — removed via `pacman -Rns swaync` (or equivalent in `install.sh`'s package list) as part of RETIRE-03's final deletion commit. No egg-info-style stale build artifact class applies (swaync is a compiled binary package, not a Python/pip install). |

**Canonical question answered:** after every file in the repo is updated and swaync is
uninstalled, the only runtime system that still needs coordinated handling is the D-Bus name
itself (two processes cannot legitimately both own it during the boot-order race D-19-42's
"atomic autostart swap" exists to close) — there is no cache, no database row, no OS task
scheduler entry, and no secret keyed to "swaync" anywhere on this host.

## Common Pitfalls

### Pitfall 1: `BrightnessBackend.qml` has no absolute setter — only relative `adjust(steps)`

**What goes wrong:** D-19-20 says "reuse `AudioBackend.qml` and `BrightnessBackend.qml`
as-is" for the centre's sliders. `AudioBackend` supports this cleanly (`setMasterVolume(v)`,
`setInputVolume(v)` both take an absolute 0..1 value). `BrightnessBackend` does NOT — its only
writer verb is [VERIFIED: `quickshell/.config/quickshell/modules/bar/BrightnessBackend.qml:186-195`]:

```qml
// The one public verb: a signed notch count, never a raw percent. No
// caller of this function ever needs to know a device's bounds.
function adjust(steps) {
    if (!root.present || root.deviceName === "") return;
    const delta = steps * Design.barScrollStepPercent;
    ...
}
```

A `Slider` dragged to an absolute position cannot call this directly — it would need to compute
`steps = round((targetPercent - root.percent) / Design.barScrollStepPercent)` on every drag
tick, which is awkward and imprecise (division by a fixed step size loses sub-step positions a
drag gesture naturally produces).

**Why it happens:** `BrightnessBackend` was built for QBAR-04's scroll-to-adjust use case
(Phase 18), where "relative notch" is the natural unit; a draggable slider is a genuinely new
use case this backend was never designed for.

**How to avoid:** flag this to the user/planner as a real deviation from "as-is" — either (a)
add a small absolute-set capability to `BrightnessBackend.qml` (a new `brightnessctl set N%`
Process, guarded the same way `adjustProcess` already is), which is a NEW file touch beyond
D-19-20's literal "as-is" wording, or (b) accept a coarser drag UX that snaps to
`Design.barScrollStepPercent` increments and computes the delta. This is not resolvable from
research alone — see Open Questions.

**Warning signs:** a centre brightness slider that "jumps" or lags noticeably behind the drag
handle, or one that silently does nothing on this host (brightness is present-but-inert here
per D-18-39 — no backlight device, so this bug may not even surface during local testing and
would only appear on hardware that does have one).

### Pitfall 2: `PersistentProperties` does not survive a process restart

**What goes wrong:** Caelestia persists DND via
`PersistentProperties { property bool dnd; reloadableId: "notifs" }`
[VERIFIED: `services/Notifs.qml:75-81`]. `PersistentProperties`' prototype chain
[VERIFIED: `/usr/lib/qt6/qml/Quickshell/quickshell-core.qmltypes:735-745,1330-1343`] is
`PersistentProperties → Reloadable → QObject`, and `Reloadable`'s own doc-comment-adjacent
members (`onReloadFinished`, `onGenerationDestroyed`, `reloadableId`) are all about Quickshell's
**QML hot-reload** event (`qs -c reload` / a config file changing on disk while the process
keeps running) — not about surviving the process being killed and a new PID starting, which is
exactly what QBAR-10's systemd `--user` restart wrapper does on a crash.

**Why it happens:** Caelestia's own deployment model may not rely on kill+respawn as a normal
event the way this repo's QBAR-10 restart wrapper does; its `PersistentProperties` choice is
correct for ITS failure mode (hot reload) but not for THIS repo's failure mode (process
restart).

**How to avoid:** D-19-36 already specifies the correct answer — persist DND in the shell's own
JSON state file (the same `~/.local/state/quickshell/` directory as notification history),
loaded via `FileView` at startup, same pattern as `NotifData`'s own history persistence. Do not
substitute `PersistentProperties` even though it looks like a more "native" Quickshell
mechanism — it solves a different problem.

**Warning signs:** DND surviving a QML hot-reload during development (making it LOOK like it
works) but silently resetting after `systemctl --user restart quickshell-bar.service` or a
crash-triggered auto-restart — the failure mode would only surface in exactly the scenario
QNOTIF-09 is written to guard against.

### Pitfall 3: no native signal for "the notification's sender session is gone" (D-19-31)

**What goes wrong:** D-19-31 requires hiding action buttons once "the sender's session" has
ended. The `Notification` type's `closed` signal [VERIFIED: qmltypes] carries a
`NotificationCloseReason` enum of exactly `Expired`, `Dismissed`, `CloseRequested` — there is no
fourth reason for "the D-Bus peer disconnected" and no separate signal/property anywhere in the
type for sender liveness. Caelestia does not attempt this at all (CONTEXT.md records this as a
named divergence — "Caelestia keeps them").

**Why it happens:** the freedesktop notification spec itself has no first-class "sender
disconnected" event; a notification is fire-and-forget from the sender's point of view once
sent, and D-Bus doesn't surface peer-disconnect to unrelated method-call recipients without
extra plumbing (`NameOwnerChanged` monitoring keyed to the sender's unique connection name,
which `Notification`'s QML surface does not expose either).

**How to avoid:** the one case that IS cleanly detectable is notifications reloaded from
`notifications.json` after a restart (D-19-24) — by construction, any process that sent a
notification before this shell's last restart is a different, almost-certainly-gone D-Bus
session, so **treat every notification loaded from disk as having no live sender and hide its
action buttons unconditionally on load**. For notifications received in the CURRENT live
session, there is no clean signal available from this API surface for "sender died mid-session
before I dismissed the popup" — this is a genuine gap, not an oversight; flag it as an Open
Question for the planner to make an explicit, reasoned scope call on (see below) rather than
silently under- or over-implementing D-19-31.

**Warning signs:** an implementation that tries to watch `NotificationAction.invoke()` for a
thrown error as a "sender gone" signal — untested whether Quickshell surfaces a QML-catchable
error at all when the D-Bus call underlying `invoke()` fails (no evidence found either way this
session; do not assume it does).

### Pitfall 4: `NotificationSource`'s public contract is explicitly load-bearing — don't leak internals

**What goes wrong:** `ClockActionsCapsule.qml`'s own header comment
[VERIFIED: lines 599-609] states: "Every name outside this component's own body MUST stay
confined to the five below: `unreadCount`, `dndActive`, `available`, `openCentre()`,
`toggleDnd()`. Everything else... lives inside this component and nowhere else in this file."
The bell cell's rendering logic (lines 864-893) binds ONLY to those five names. A repoint that
leaks a sixth name (e.g. a raw reference to the new `NotificationServer` singleton) into the
capsule's own layout code turns "a backend swap" into "a rewrite of a surface that already
passed its render gate," per the same comment's own warning.

**Why it happens:** it's tempting, when repointing `openCentreProcess`/`toggleDndProcess`
(currently `Process` children shelling to `swaync-client`) onto the new IPC/singleton, to also
simplify by binding the capsule's badge/tooltip logic directly to the new server. Don't.

**How to avoid:** keep the same five-name contract; only the `NotificationSource` component's
*internal* implementation (the three `Process` children and the `_dndClasses`/`_liveClasses`
parsing) changes to read from the new singleton/IPC target instead of shelling to
`swaync-client`.

## Code Examples

### `NotificationServer` full property/signal surface (verified, not paraphrased)

```
// Source: /usr/lib/qt6/qml/Quickshell/Services/Notifications/quickshell-service-notifications.qmltypes
// Component: qs::service::notifications::NotificationServerQml, exports "NotificationServer 0.0"
Property { name: "keepOnReload"; type: "bool" }
Property { name: "persistenceSupported"; type: "bool" }
Property { name: "bodySupported"; type: "bool" }
Property { name: "bodyMarkupSupported"; type: "bool" }
Property { name: "bodyHyperlinksSupported"; type: "bool" }
Property { name: "bodyImagesSupported"; type: "bool" }
Property { name: "actionsSupported"; type: "bool" }
Property { name: "actionIconsSupported"; type: "bool" }
Property { name: "imageSupported"; type: "bool" }
Property { name: "inlineReplySupported"; type: "bool" }
Property { name: "trackedNotifications"; type: "UntypedObjectModel"; isPointer: true; isReadonly: true }
Property { name: "extraHints"; type: "QString"; isList: true }
Signal { name: "notification"; Parameter { name: "notification"; type: "Notification"; isPointer: true } }
```

### `Notification` full property/method surface (verified, not paraphrased)

```
// Source: /usr/lib/qt6/qml/Quickshell/Services/Notifications/quickshell-service-notifications.qmltypes
// Component: qs::service::notifications::Notification, exports "Notification 0.0"
Property { name: "id"; type: "uint"; isReadonly: true }
Property { name: "tracked"; type: "bool" }                          // MUST set true to retain
Property { name: "lastGeneration"; type: "bool"; isReadonly: true }
Property { name: "expireTimeout"; type: "double"; isReadonly: true }
Property { name: "appName"; type: "QString"; isReadonly: true }
Property { name: "appIcon"; type: "QString"; isReadonly: true }
Property { name: "summary"; type: "QString"; isReadonly: true }
Property { name: "body"; type: "QString"; isReadonly: true }
Property { name: "urgency"; type: "NotificationUrgency::Enum"; isReadonly: true }
Property { name: "actions"; type: "QList<NotificationAction*>"; isReadonly: true }
Property { name: "hasActionIcons"; type: "bool"; isReadonly: true }
Property { name: "resident"; type: "bool"; isReadonly: true }
Property { name: "transient"; type: "bool"; isReadonly: true }
Property { name: "desktopEntry"; type: "QString"; isReadonly: true }
Property { name: "image"; type: "QString"; isReadonly: true }
Property { name: "hasInlineReply"; type: "bool"; isReadonly: true }
Property { name: "inlineReplyPlaceholder"; type: "QString"; isReadonly: true }
Property { name: "hints"; type: "QVariantMap"; isReadonly: true }
Signal { name: "closed"; Parameter { name: "reason"; type: "NotificationCloseReason::Enum" } }
Method { name: "expire" }
Method { name: "dismiss" }
Method { name: "sendInlineReply"; Parameter { name: "replyText"; type: "QString" } }
// NotificationCloseReason::Enum values: Expired, Dismissed, CloseRequested
// NotificationUrgency::Enum values: Low, Normal, Critical
```

### `NotificationAction` (verified)

```
// Component: qs::service::notifications::NotificationAction, exports "NotificationAction 0.0"
Property { name: "identifier"; type: "QString"; isReadonly: true }
Property { name: "text"; type: "QString"; isReadonly: true }
Method { name: "invoke" }   // QNOTIF-04's "reaches the sending application" — this IS the ActionInvoked round-trip
```

### DND toggle + toast on change (Caelestia pattern, applicable minus `PersistentProperties`)

```qml
// Source: adapted from ~/.claude/jobs/4517c040/tmp/caelestia-shell/services/Notifs.qml:40-48
// (dnd storage swapped from PersistentProperties to this repo's FileView-backed pattern per D-19-36)
onDndChanged: {
    if (dnd)
        Toaster.toast(qsTr("Do not disturb enabled"), qsTr("Popup notifications are now disabled"), "do_not_disturb_on");
    else
        Toaster.toast(qsTr("Do not disturb disabled"), qsTr("Popup notifications are now enabled"), "do_not_disturb_off");
}
```

### IPC handler shape for Super+N / centre toggle / DND (established repo pattern)

```qml
// Source: pattern established in this repo's shell.qml:498-500 ("bar" target), :589-591 ("panel" target);
// Caelestia's own equivalent at services/Notifs.qml:144-167
IpcHandler {
    target: "notifs"
    function clear(): void { /* clear all history */ }
    function isDndEnabled(): bool { return dndState; }
    function toggleDnd(): void { dndState = !dndState; }
}
```

Super+N's keybind repoint (D-19-16) should follow this repo's OWN established
`hl.dsp.global("quickshell:<name>")` + `shortcuts.json` entry + `GlobalShortcut` pattern
[VERIFIED: `hypr/.config/hypr/config/keybinds.lua:134,198,204,208,215,224` — e.g.
`hl.bind(mainMod .. " + N", hl.dsp.global("quickshell:notif-centre"))`], NOT a bare `qs ipc
call` shell-out from Hyprland — this matches how `Super+D`/`Super+A`/`Super+O` are already
wired, and is the more idiomatic choice than the `Super+A`-adjacent-but-different `qs ipc call
panel toggle audio` waybar-click pattern (which exists because waybar could not use
`GlobalShortcut`s at all — that constraint no longer applies to a Hyprland keybind).

## LEDGER-04 Ground Truth

**Live count taken this session** (`ls .planning/debug/`): **5 files**, not 6:

| File | Status (from own frontmatter/body) | Notification-server-related? |
|---|---|---|
| `bluetooth-enable-inert.md` | `diagnosed` — root cause: rfkill soft-block + `BluetoothAdapterState.Blocked` never read/surfaced in QML | **No.** This is a Bluetooth-panel bug (a new backend readonly bool over `adapter.state` + a third panel branch), unrelated to the notification server. D-19-39 does NOT fix this. |
| `wifi-hidden-network-not-detected.md` | "ROOT CAUSE FOUND" — a race in the panel's own probe-to-list handoff | No — wifi panel bug |
| `wifi-hidden-network-unsupported.md` | `diagnosed` (scoping investigation, feature-request) — `Quickshell.Networking` cannot express hidden networks at all; needs a subprocess route | No — wifi panel feature gap |
| `wifi-scan-progress-feedback.md` | `diagnosed` — two independent root causes (motion-token misuse as a loop period; a level-not-edge scanning flag) | No — wifi panel bug |
| `wifi-wrong-password-external-dialog.md` | `diagnosed` — nm-applet's GTK secret-agent dialog is the culprit, not the panel | No — wifi/nm-applet bug |

`panels-missing-animated-border.md` (the `GradientBorder` session, the historical "sixth")
already lives in `.planning/debug/resolved/` with `status: resolved`, closed by Phase 18's
LEDGER-01 — [VERIFIED: file frontmatter `status: resolved`, `updated: 2026-08-10T00:00:00Z`].

**The bluetooth pairing prompt is a DIFFERENT, separately-tracked item — not one of the five
files above.** It lives in `.planning/milestones/v3.0-phases/15-audio-connectivity-panels/deferred-items.md`
under the heading "Notification-server replacement MUST declare `actions` and `body`
capability" (its own internal ID reference is `G-15-7`) — [VERIFIED: read in full this session].
Its "Status: OPEN — a constraint on future work, not a defect in phase 15" and its own stated
"Owner condition: closes when the swaync replacement ships with the capability declared and a
real bluetooth pairing verified against it" is EXACTLY D-19-38/D-19-39's scope. Its closing
verification is explicit in the source document: *"pair a real phone and confirm (a) no GTK
dialog appears, (b) the confirmation renders through the new server with working Accept/Reject,
(c) `GetCapabilities` lists `body` and `actions`."*

**What this means for the planner:** ROADMAP.md's phrasing ("the six open debug sessions...
including the bluetooth pairing prompt") conflates two different ledgers — the 5 (historically
6) files literally in `.planning/debug/`, and the separate G-15-7 item in `deferred-items.md`.
Phase 19 must therefore produce SIX dispositions, not five:
1. `bluetooth-enable-inert.md` — resolve or explicitly-reasoned deferral (own scope, likely
   deferred: it needs a Bluetooth-panel backend change, arguably out of this phase's declared
   boundary, which names only QNOTIF/RETIRE-03/LEDGER-04/07/08).
2. `wifi-hidden-network-not-detected.md` — resolve or deferral.
3. `wifi-hidden-network-unsupported.md` — resolve or deferral (this one is a feature request,
   not a bug — "explicitly-reasoned deferral" is almost certainly the right call).
4. `wifi-scan-progress-feedback.md` — resolve or deferral.
5. `wifi-wrong-password-external-dialog.md` — resolve or deferral.
6. G-15-7 (bluetooth pairing containment, `deferred-items.md`) — resolved BY CONSTRUCTION via
   D-19-38/D-19-39, verified by the pair-a-real-phone test the source document itself specifies.

Whether items 1-5 are truly in scope for a phase whose declared boundary is QNOTIF/swaync/
LEDGER-04/07/08 (none of them touch notifications, wifi, or the notification server) is itself
worth an explicit scope call at plan time — see Open Questions.

## LEDGER-07 / LEDGER-08 Mechanics

### LEDGER-07 — `theme-stress-test` clean run

**Verified mechanics** (matching D-19-45's canonical refs exactly):
- `WALLPAPER_DIR="$HOME/Pictures/Wallpapers"` at
  [VERIFIED: `theme-engine/.config/theme-engine/lib/wallpaper.sh:14`].
- Three `ln -sfr … current.jpg` call sites — [VERIFIED via grep this session, matching
  CONTEXT.md's D-19-45 citation of lines 242, 263, 336] — all three write into the
  stow-tracked `wallpapers/Pictures/Wallpapers/` tree, dirtying `git status` on every static
  theme switch.
- `theme-stress-test`'s `REPRESENTATIVE_FILES` array and its two commentary blocks referencing
  `swaync.css` are at [VERIFIED via grep this session]: line 309 (`REPRESENTATIVE_FILES=(...)`),
  and commentary at lines 247 and 294 — matching D-19-46's citation exactly.

**Fix mechanics:** move the `current.jpg` symlink target out of the stow-tracked
`wallpapers/Pictures/Wallpapers/` directory into `~/.local/state/theme/` (an already-untracked,
engine-owned location per this repo's own established precedent — 13-06's decision log records
the SAME class of fix already applied once: "untrack-and-seed (not exempt-the-path); current.jpg
untracked, gitignored, seeded at install" — though that was for a DIFFERENT current.jpg path;
confirm at plan time whether that 13-06 fix and this LEDGER-07 item are the same file or two
different `current.jpg` symlinks. This is flagged as an Open Question below since research
found two mentions of a `current.jpg` untracking effort (13-06's decision log, and this phase's
D-19-45) that may or may not refer to the same underlying symlink).

**Verification:** re-run `theme-engine/.config/theme-engine/theme-stress-test` (already proven
runnable to completion once, per 13-07's decision log: "10/10 consecutive switches, 162 passed
0 failed, exit 0, tree clean after") after the wallpaper.sh repoint and the `REPRESENTATIVE_FILES`
edit, and confirm `git status` reports clean both mid-run and after.

### LEDGER-08 — panel-family security review + verifier re-run

**The "verifier" is `gsd-security-auditor`**, the same agent that produced Phase 15's own
`15-SECURITY.md` [VERIFIED: read in full this session, `Register authored at plan time... this
document consolidates those 14 registers into one phase-level register, verified against the
implementation by gsd-security-auditor on 2026-08-08`]. The `security-review` skill listed in
this environment's available skills ("Complete a security review of the pending changes on the
current branch") is very likely the invocation surface for this same tooling.

**Concrete gap already on record, not yet closed** [VERIFIED: `15-SECURITY.md:130`, "Unregistered
Flags" table, item 2]: *"`WifiPanel.qml` has zero `textFormat` pins. SSIDs arrive over the air —
the same untrusted-string class T-15-08b closed for BluetoothPanel — yet `:802-814` (row label),
`:822` (ToolTip.text, the unelided full SSID) and `:1056` (forget-confirm) are plain `Text` with
no pin... Recommend minting as a follow-up."* This is THE named "acknowledged gap" LEDGER-08's
requirement text ("Phase 15's acknowledged gaps are closed") most directly points at — it is a
below-`block_on:high` (medium-severity-class) finding that was explicitly deferred rather than
fixed in Phase 15.

**LEDGER-08's scope per D-19-44:** the panel-family review (closing the `WifiPanel.qml`
`textFormat` gap, the concrete item above) PLUS a fresh review of the phase's own new D-Bus
attack surface — untrusted `summary`/`body`/`app_name`/`image` fields from ANY session process
now render inside the shell, and D-19-40's markdown allowlist widens the injection surface
(link URLs, in particular). New threats to register for THIS phase's own security document
(`19-SECURITY.md`, following the same format as `15-SECURITY.md`) should at minimum cover:
untrusted `body`/`summary` text rendering (markup injection via `Text.MarkdownText`), untrusted
`app_icon`/`image` hint values (path traversal / arbitrary local file read via
`Quickshell.iconPath`/`Image.source`), and the D-19-40 link-confirmation flow (an unconfirmed
`Qt.openUrlExternally` on a sender-chosen URL, which D-19-40 already mitigates by design but
still needs its own threat-register row and a mitigation-verified disposition).

**"Verifier re-run over its gap-closure round"** means: after (a) closing the `WifiPanel.qml`
textFormat gap and (b) authoring the new notification-server threat register, run
`gsd-security-auditor` (or `/security-review`) again against the resulting diff, the same way
Phase 15's own document was itself the product of one such verification pass — producing a
`19-SECURITY.md` with `threats_open: 0` and a completed `Sign-Off` checklist, mirroring
`15-SECURITY.md`'s exact structure (this phase's own doctor/plan-checker likely expects the same
shape, given RETIRE-01/GATE-01's established "reuse the exact prior artifact shape" discipline
this milestone follows throughout).

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `replaces_id` C++ handling reuses the same `Notification` QObject rather than allocating a new one with the same `id` value | Architecture Patterns Pattern 2 | If wrong, the "no re-animate/reorder" behaviour (D-19-08) would need to be built explicitly (a `Connections`-only binding would silently break if a second `onNotification` DOES fire on replace) — the fault-injection fixture recommended in Pattern 2 is designed specifically to catch this at implementation time regardless of which way the assumption resolves |
| A2 | `NotificationAction.invoke()` surfaces no QML-catchable error when the underlying D-Bus call to the sender fails | Common Pitfalls Pitfall 3 | If wrong (Quickshell DOES expose a failure signal), D-19-31's "sender gone" detection could be implemented more completely than this research assumes — worth a 5-minute live probe (invoke an action on a notification from a killed process) before committing to the disk-reload-only heuristic |
| A3 | Caelestia's own deployment does not rely on process kill+respawn as a routine event the way this repo's QBAR-10 wrapper does, explaining its `PersistentProperties`-for-DND choice | Common Pitfalls Pitfall 2 | Low risk either way — regardless of WHY Caelestia chose `PersistentProperties`, the qmltypes-verified `Reloadable` prototype chain is what actually matters, and that finding stands independent of this speculation about Caelestia's own reasoning |
| A4 | 13-06's "untrack-and-seed" `current.jpg` fix and this phase's D-19-45 `current.jpg` fix refer to potentially different symlink instances | LEDGER-07 Mechanics | If they are actually the same file already fixed once, LEDGER-07's remaining work may be smaller than D-19-45 assumes, or the 13-06 fix may have partially regressed — needs a direct file-state check at plan time, not assumed from either decision-log entry alone |

**If this table is empty:** N/A — see rows above.

## Open Questions

1. **Does `BrightnessBackend.qml` need a new absolute setter, or should the centre's brightness
   slider work in `Design.barScrollStepPercent`-sized jumps?**
   - What we know: only a relative `adjust(steps)` verb exists today (verified, quoted in
     Common Pitfalls Pitfall 1).
   - What's unclear: whether D-19-20's "as-is" is meant literally (accept the coarser slider) or
     whether a small backend addition is implicitly expected.
   - Recommendation: raise explicitly at plan time as a scoped micro-decision; either answer is
     small, but CONTEXT.md's "as-is" wording doesn't resolve it and this repo's own hardware has
     no backlight device to test against locally (D-18-39 precedent), so the choice may need to
     be made on code-reading grounds alone.

2. **What is the correct disposition for the 5 non-bluetooth-pairing LEDGER-04 debug sessions,
   given none of them touch the notification server, swaync, or this phase's declared scope?**
   - What we know: all 5 are wifi-panel or bluetooth-panel bugs/feature-gaps (ground truth
     documented in § LEDGER-04 Ground Truth).
   - What's unclear: whether "explicitly-reasoned deferral" for all 5 is acceptable (likely, given
     the phase's declared boundary excludes wifi/bluetooth panel work entirely), or whether the
     roadmap's placement of LEDGER-04 in Phase 19 implies at least attempting fixes.
   - Recommendation: the phase boundary text in CONTEXT.md ("Not in scope: ... No `org.bluez.Agent1`
     D-Bus agent") never mentions wifi-panel or general bluetooth-panel work as in-scope; the
     strongest reading is that all 5 take an explicitly-reasoned deferral (their root causes are
     documented and actionable, just not by this phase's own file set), with G-15-7 (the sixth,
     bluetooth-pairing item) being the only one actually resolved here. Confirm this reading with
     the user/orchestrator before planning tasks for wifi/bluetooth-panel code changes inside a
     notification-server phase.

3. **Are the two `current.jpg`-untracking efforts (13-06's and D-19-45's) the same symlink or
   two different ones?**
   - What we know: 13-06's decision log (STATE.md) records "current.jpg untracked, gitignored,
     seeded at install" as already done; D-19-45 independently identifies three live
     `ln -sfr … current.jpg` call sites in `wallpaper.sh` still writing into the tracked
     `wallpapers/` tree.
   - What's unclear: whether 13-06's fix applied to a different `current.jpg` (e.g. a theme
     preview thumbnail vs. the active wallpaper symlink) or the same one that regressed.
   - Recommendation: `git log -p` on `wallpaper.sh` around the 13-06 commit, or a direct
     `readlink`/`git check-ignore` probe on the live file, before writing the LEDGER-07 fix task —
     this is a 2-minute check that avoids either redoing already-done work or missing that the
     prior fix already partially covers this.

4. **Does `UI-SPEC.md` need to exist before planning, per this phase's `UI hint: yes`?**
   - What we know: `.planning/phases/19-notification-server-centre/` currently contains only
     `19-CONTEXT.md` and `19-DISCUSSION-LOG.md` — no `19-UI-SPEC.md`. Prior auto-memory in this
     session's context flags "Phase 19 (Notification Server) blocked on missing UI-SPEC.md at
     plan gate."
   - What's unclear: whether the orchestrator's plan-phase workflow will invoke `gsd-ui-phase`
     automatically given `ROADMAP.md`'s `**UI hint**: yes` marker, or whether this needs an
     explicit separate step before `/gsd-plan-phase` can proceed.
   - Recommendation: flag to the orchestrator/planner directly; this RESEARCH.md's own Standard
     Stack / Architecture Patterns sections cover the mechanics UI-SPEC would need regardless
     (component API, gesture patterns, colour-role extension points), so a UI-SPEC pass should
     have everything it needs from this document plus CONTEXT.md's extensive pixel-level D-19-*
     decisions.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| `quickshell` | The entire notification server/centre | ✓ | 0.3.0-2 | — |
| `Quickshell.Services.Notifications` module | `NotificationServer`/`Notification`/`NotificationAction` | ✓ | ships with quickshell 0.3.0-2 | — |
| `Quickshell.Hyprland` module (`Hyprland`, `HyprlandMonitor`, `HyprlandToplevel`) | Fullscreen detection (QNOTIF-10) | ✓ | ships with quickshell 0.3.0-2; already imported live in `shell.qml` | — |
| `QtQuick.Shapes` (`PathAngleArc`) | Ring progress (D-19-09) | ✓ | ships with qt6-declarative | — |
| `QtQuick.Effects.MultiEffect` | Empty-state tint (D-19-22) | ✓ | ships with qt6-declarative, confirmed at `/usr/lib/qt6/qml/QtQuick/Effects/` | — |
| `busctl` | QNOTIF-11's live two-owner check | ✓ | (used live this session against the real session bus) | — |
| `brightnessctl` | Centre's brightness slider backend | present as a binary, but **no backlight device exists on this host** (`/sys/class/backlight/` empty, per D-18-39/GATE-01 precedent, re-confirmed by `BrightnessBackend.qml`'s own `present` probe) | — | slider ships present-but-inert, same precedent as QBAR-04 |
| `swaync` (being removed) | RETIRE-03 | ✓ (currently installed, to be uninstalled) | 0.12.6-1, `extra` repo | — |
| Caelestia reference source | D-19-00's governing rule | ✓ — full checkout available at `~/.claude/jobs/4517c040/tmp/caelestia-shell` this session | (git checkout, no version pin observed) | If this checkout is not present in a future session, fall back to `.planning/research/FEATURES.md` § NOTIF per CONTEXT.md's own instruction |

**Missing dependencies with no fallback:** none identified.

**Missing dependencies with fallback:** brightness hardware (present-but-inert precedent already
established and accepted by this repo for QBAR-04).

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Bash-based fixture/self-test harness (`quickshell-doctor`, `retirement-check`, `theme-doctor`) — this repo's established pattern; no unit-test framework (Jest/pytest-equivalent) exists for the QML layer |
| Config file | none — each doctor script is self-contained with an embedded fixtures directory |
| Quick run command | `hypr/.config/hypr/scripts/quickshell-doctor` (full suite includes the new checks this phase must add) |
| Full suite command | `hypr/.config/hypr/scripts/quickshell-doctor && hypr/.config/hypr/scripts/retirement-check swaync && theme-engine/.config/theme-engine/theme-stress-test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| QNOTIF-01 | Server owns the bus name | live D-Bus probe | `busctl --user list \| grep org.freedesktop.Notifications` (owner = `quickshell`) | ✅ mechanism verified live this session |
| QNOTIF-05 | `replaces_id` in-place update | fault-injection (manual `busctl call`/`notify-send -p` sequence) | new fixture — see Architecture Patterns Pattern 2's fault-injection shape | ❌ Wave 0 — no fixture exists yet, must be authored |
| QNOTIF-11 | Live two-owner check | doctor fixture re-point + live run | `hypr/.config/hypr/scripts/quickshell-doctor --self-test` (fixture path) THEN a live, un-self-tested invocation against the real session, THEN kill+respawn the server and re-check | ✅ fixture mechanism exists (`compliant-busctl-list.txt`/`poisoned-two-owner-busctl-list.txt`), ❌ needs re-pointing (owner string `swaync` → `quickshell`, lines 245, 2157, 2186 of `quickshell-doctor`) |
| RETIRE-03 | swaync fully removed | checklist script | `hypr/.config/hypr/scripts/retirement-check swaync` (must report zero blocking hits before AND after the deletion commit) | ✅ script exists (built Phase 18, generic per D-18-34), registry entry `swaync\|pending\|...\|RETIRE-03` already present, needs flipping to `retired` |
| LEDGER-04 | 5 (not 6) debug sessions + G-15-7 dispositioned | manual review, each session's own status field updated | none automatable — human-reasoned dispositions | ✅ all source files exist and were read this session |
| LEDGER-07 | `theme-stress-test` clean run | full stress-test run | `theme-engine/.config/theme-engine/theme-stress-test` (expect 10/10 switches, `git status` clean throughout and after) | ✅ script exists, previously proven runnable to completion (13-07) |
| LEDGER-08 | Security review + verifier re-run | `gsd-security-auditor` / `security-review` skill invocation | (agent invocation, not a shell command) | ✅ prior-phase artifact (`15-SECURITY.md`) exists as the format template |

### Sampling Rate

- **Per task commit:** `hypr/.config/hypr/scripts/quickshell-doctor --self-test` (fixture-only, fast)
- **Per wave merge:** full `quickshell-doctor` live run + `retirement-check swaync`
- **Phase gate:** `theme-stress-test` full run, `quickshell-doctor` live two-owner check
  (kill+respawn included), `retirement-check swaync` zero-hits, and `security-review` re-run —
  all green before GATE-02's human render gate, per D-19-42's "no old package deleted before the
  gate" rule.

### Wave 0 Gaps

- [ ] A `replaces_id` fault-injection fixture (QNOTIF-05) — no existing fixture covers this; must
      be authored as either a `quickshell-doctor` check or a standalone script issuing two
      `Notify` D-Bus calls with the same `replaces_id`.
- [ ] `quickshell-doctor`'s `QSD_NAME_OWNERS["org.freedesktop.Notifications"]` registry entry
      (currently `"swaync"` at line 245) repointed to `"quickshell"`, plus the self-test
      assertions at lines 2157 and 2186 updated to match, plus `compliant-busctl-list.txt` and
      `poisoned-two-owner-busctl-list.txt` regenerated with `quickshell` as the legitimate owner
      row (own-process PID, verified live this session as `1565745` for the CURRENT bar process —
      will differ at execution time).
- [ ] `retirement-check`'s registry row for `swaync` flipped from `pending` to `retired` only
      AFTER the deletion commit, per the existing `waybar` precedent in the same registry.
- [ ] A `19-SECURITY.md` threat register, following `15-SECURITY.md`'s exact structure (Trust
      Boundaries / Threat Register / Accepted Risks Log / Audit Trail / Sign-Off), covering both
      the panel-family gap-closure (the `WifiPanel.qml` `textFormat` pin) and the new D-Bus
      inbound-data surface.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | D-Bus session bus access is the OS's own trust boundary (any process running as this user); the notification server does not authenticate senders beyond what the bus itself provides |
| V3 Session Management | no | No session concept introduced by this phase |
| V4 Access Control | partial | The two-owner check (QNOTIF-11) IS an access-control property — exactly one process may legitimately claim the bus name; enforced by D-Bus's own name-ownership semantics plus this repo's own doctor verification, not a custom ACL |
| V5 Input Validation | **yes — the phase's primary new attack surface** | Untrusted `summary`/`body`/`app_name`/`app_icon`/`image`/`hints` fields from ANY session-bus process must be treated as untrusted text/paths. Standard control: `textFormat` pins on every `Text` element rendering sender-supplied strings (same class as the already-identified `WifiPanel.qml` gap in `15-SECURITY.md`), an explicit allowlist filter before `Text.MarkdownText` (D-19-40), and confirm-before-open on any link (D-19-40) |
| V6 Cryptography | no | Not applicable — no secrets or crypto operations in this phase |
| V12 File and Resources | yes | `image`/`app_icon` hint values ultimately resolve through `Quickshell.iconPath`/`Image.source` — a sender-controlled path should never be treated as a trusted local filesystem reference beyond what the icon-theme/desktop-entry resolution mechanism already sandboxes; do not add a code path that opens an arbitrary sender-supplied local file path directly |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Untrusted `summary`/`body` text rendered without a `textFormat` pin, allowing Qt's `Text.AutoText` to auto-detect and render HTML/rich-text from sender data | Tampering / Spoofing | Explicit `textFormat: Text.PlainText` (or the D-19-40 allowlist-then-`MarkdownText` pipeline for body specifically) on every `Text` bound to sender-controlled fields — same pattern `15-SECURITY.md`'s T-15-08b closed for `BluetoothPanel.qml` |
| Sender-chosen URL opened unconditionally on click (markdown link) | Tampering / Elevation of Privilege (drive-by local action) | D-19-40's confirm-before-open (hover shows the URL, click requires confirmation) — already the locked decision; verify it in the new threat register with a concrete code citation, mirroring `15-SECURITY.md`'s evidence-cited style |
| Second D-Bus owner of `org.freedesktop.Notifications` (spoofing the notification server) | Spoofing | QNOTIF-11's live two-owner doctor check, re-pointed and run for real (not self-tested) — already the exact mitigation Phase 15's T-15-03 established for the panel-summon case, now extended to the server's own steady-state ownership |
| Malformed/oversized `hints` values (e.g. a huge `hints.value` or a malformed image path) causing a crash or resource exhaustion | Denial of Service | Bound/clamp `hints.value` before feeding `PathAngleArc.sweepAngle` (Caelestia's own code already does `(hints.value ?? 0)/100)*360` with no explicit clamp — worth adding one, since a sender could send `value: 999999`); guard image loading with `asynchronous: true` (already Caelestia's pattern) so a slow/hostile image source doesn't block the UI thread |

## Sources

### Primary (HIGH confidence — read directly this session)

- `/usr/lib/qt6/qml/Quickshell/Services/Notifications/quickshell-service-notifications.qmltypes` — full `NotificationServer`/`Notification`/`NotificationAction`/`NotificationCloseReason`/`NotificationUrgency` API surface
- `/usr/lib/qt6/qml/Quickshell/quickshell-core.qmltypes` — `PersistentProperties`/`Reloadable` prototype chain
- `/usr/lib/qt6/qml/Quickshell/Hyprland/_Ipc/quickshell-hyprland-ipc.qmltypes` — `Hyprland`/`HyprlandMonitor`/`HyprlandToplevel` API surface
- `~/.claude/jobs/4517c040/tmp/caelestia-shell/services/Notifs.qml`, `services/NotifData.qml`, `modules/notifications/Notification.qml`, `modules/sidebar/Notif.qml`, `modules/sidebar/NotifGroup.qml`, `modules/sidebar/Wrapper.qml` — Caelestia's real, live source per D-19-00's governing rule
- This repo's own: `quickshell/.config/quickshell/shell.qml` (IPC targets, fullscreen guard), `modules/bar/ClockActionsCapsule.qml` (`NotificationSource` seam), `modules/bar/BarRoles.qml`, `modules/bar/BrightnessBackend.qml`, `modules/dashboard/AudioBackend.qml`, `modules/dashboard/QuickToggles.qml`, `modules/bar/SectionPopout.qml`
- `hypr/.config/hypr/scripts/quickshell-doctor`, `hypr/.config/hypr/scripts/retirement-check`, `hypr/.config/hypr/scripts/tests/quickshell-fixtures/{compliant,poisoned-two-owner}-busctl-list.txt`
- `matugen/.config/matugen/config.toml`, `theme-engine/.config/theme-engine/contract.json`, `theme-engine/.config/theme-engine/lib/reload.sh`, `theme-engine/.config/theme-engine/lib/wallpaper.sh`, `theme-engine/.config/theme-engine/theme-stress-test`, `hypr/.config/hypr/config/autostart.lua`, `hypr/.config/hypr/config/keybinds.lua`
- `.planning/milestones/v3.0-phases/15-audio-connectivity-panels/15-SECURITY.md`, `deferred-items.md`
- `.planning/debug/*.md` and `.planning/debug/resolved/panels-missing-animated-border.md` (live directory listing + content, this session)
- Live host state: `pacman -Qi quickshell`, `pacman -Qi swaync`, `busctl --user list`, `ps aux | grep quickshell`

### Secondary (MEDIUM confidence)

- `replaces_id`'s exact C++-level mechanism (§ Architecture Patterns Pattern 2) — inferred from Caelestia's QML consumer behaviour, not read from Quickshell's own C++ source (not installed on this host as headers)

### Tertiary (LOW confidence)

- None — no WebSearch-only claims were needed for this research; every material claim traces to a file read or a live command run this session.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — every module verified as installed and its API read directly from qmltypes
- Architecture: HIGH for popup/centre/gesture patterns (real source read), MEDIUM for `replaces_id` internals (inferred, not C++-source-verified)
- Pitfalls: HIGH — all four pitfalls are grounded in a direct file read (BrightnessBackend's missing setter, PersistentProperties' prototype chain, the qmltypes' missing sender-liveness signal, ClockActionsCapsule's own explicit contract comment)
- LEDGER-04 ground truth: HIGH — live directory listing and full file reads this session
- LEDGER-07/08 mechanics: HIGH for file/line citations, MEDIUM for whether the two `current.jpg` fixes are the same symlink (Open Question 3)

**Research date:** 2026-08-13
**Valid until:** 30 days (stable local toolkit; the Caelestia checkout at
`~/.claude/jobs/4517c040/tmp/caelestia-shell` is a job-scoped temp directory and may not persist
across sessions — if unavailable later, `.planning/research/FEATURES.md` § NOTIF is the
documented fallback per D-19-00's own text)
