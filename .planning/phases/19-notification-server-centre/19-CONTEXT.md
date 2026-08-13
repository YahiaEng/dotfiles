# Phase 19: Notification Server & Centre - Context

**Gathered:** 2026-08-13
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase makes the Quickshell process itself the desktop's notification receiver —
it owns `org.freedesktop.Notifications` — delivers the full popup + slide-out-centre
experience, and deletes swaync in the same phase with no soak window and no fallback
path.

**In scope:** QNOTIF-01..11 (bus ownership, popups that stack and reflow, swipe
dismiss, working action buttons, `replaces_id` in-place updates, the slide-out centre
with history and clear-all, the shared quick-toggle grid, volume/brightness sliders,
persistent DND, suppression while the centre is open or a fullscreen client is
focused, and the live two-owner check), RETIRE-03 (swaync deleted — package, config,
2 contract entries, `[templates.swaync]`, its `reload.sh` step, its
`swaync-launch.sh` autostart line, its doctor fixtures re-pointed), LEDGER-04 (the
six open debug sessions reach `resolved` or an explicitly-reasoned deferral),
LEDGER-07 (`theme-stress-test` reaches a full clean run with the tree still clean
afterwards) and LEDGER-08 (panel-family security review + verifier re-run).

Also recurring here as standing gates: GATE-01 (enumerate swaync's live behaviour
off the running implementation before the retirement plan is written), GATE-02 (the
human render gate, blocking, before any deletion), GATE-03 (`quickshell-doctor`
structural checks cover the new frames) and GATE-04 (the QML hex-literal lint).

**Not in scope:** OSD indicators and the power menu (Phase 20), the AGS media
fold-in and contract close (Phase 21), the fresh-install container gate (Phase 22).
No per-screen fan-out (QS-03 is permanently dropped under D-13). No `org.bluez.Agent1`
D-Bus agent — the deferred item explicitly rejects that path.

</domain>

<decisions>
## Implementation Decisions

### Governing rule for this phase

- **D-19-00:** **Caelestia's shipped behaviour is the strong default for every
  design decision in this phase**, with end-4 secondary. This is the user's explicit
  instruction, sharpening the standing v3.0 reference-shell bias from a tie-breaker
  into a leading prior. Practical rule for downstream agents: check
  `.planning/research/FEATURES.md` § NOTIF (a direct read of both shells' real QML,
  with file links) — and the actual source when FEATURES.md doesn't record the
  detail — *before* proposing an approach, and name the divergence explicitly
  whenever recommending against Caelestia.

### Popup placement and lifetime

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

### The centre

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

### History, grouping and clearing

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

### Suppression and DND

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

### D-Bus server and the bluetooth pairing prompt (LEDGER-04)

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

### Retirement sequencing (RETIRE-03)

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

### Theming the new surfaces

- **D-19-43:** The popup and centre read **`BarRoles` rows, extended with
  notification-specific roles** — not `Colours.*` directly. 18.1 D-04/D-24
  established that every bar colour is a named `BarRoles` row sourced from a
  Material You value, `quickshell-doctor` greps the literal `Colours\.` pattern as a
  violation, and the bell already uses `fillNotification`. **No matugen template is
  needed at all**: QML hot-reloads `Colours.qml` natively, which is precisely why
  waybar's `SIGUSR2` post_hook died in Phase 18. `[templates.swaync]`
  (`matugen/.config/matugen/config.toml:39-41`) and its 2 contract entries are
  deleted with nothing replacing them.

### Debt items

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

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Reference-shell behaviour (governing, per D-19-00)
- `.planning/research/FEATURES.md` § NOTIF — direct-source read of Caelestia's and
  end-4's real notification QML, with per-file links. The first place to look for
  "what does Caelestia do here". Its § OSD is also relevant to D-19-21's mic slider.
- `.planning/research/SUMMARY.md` — the cross-cutting findings, incl. that both
  shells instantiate `NotificationServer` directly and both ship swipe-to-dismiss.
- `.planning/research/PITFALLS.md` — the redesign-not-port failure mode: a small
  interaction relied on unconsciously that was never written down as a requirement.
  This is the risk GATE-01's enumeration exists to contain.

### The surface being replaced
- `swaync/.config/swaync/config.json` — the live behaviour to enumerate for GATE-01:
  380px popups, 420px centre, `timeout` 5 / `timeout-low` 3 / `timeout-critical` 0,
  `relative-timestamps`, `hide-on-action`, and the widget order D-19-17 deliberately
  inverts.
- `swaync/.config/swaync/style.scss` — its themed surface.
- `.planning/phases/18-qml-bar-retirement-machinery/18-BEHAVIOUR-BASELINE.md`
  § "GATE-01 Recurrence Protocol" — the protocol and worked example for enumerating
  a live surface before replacing it. `18-02` did this for waybar; this phase does
  the same for swaync.
- `.planning/phases/18-qml-bar-retirement-machinery/18-RETIREMENT-BASELINE-waybar.md`
  and `18-RETIREMENT-AFTER-waybar.md` — the before/after checklist-run pair to mirror
  for swaync (RETIRE-03, D-19-42).

### The bluetooth pairing deferral (LEDGER-04)
- `.planning/milestones/v3.0-phases/15-audio-connectivity-panels/deferred-items.md`
  — the `GetCapabilities` finding that drives D-19-38/D-19-39, including the
  `blueman/gui/Notification.py:295` fallback logic and the closing verification
  ("pair a real phone; confirm no GTK dialog, working Accept/Reject, and `body` +
  `actions` in `GetCapabilities`"). **Read this before planning the server.**
- `.planning/debug/bluetooth-enable-inert.md` and the other open sessions in
  `.planning/debug/` — the LEDGER-04 set.

### Prior locked decisions this phase inherits
- `.planning/phases/18-qml-bar-retirement-machinery/18-CONTEXT.md` — D-18-33 (the
  bell's temporary swaync binding, repointed here), D-18-15 (why the lightweight
  popout frame is separate from `PanelDialog`), D-18-03 (the bell's permanent slot).
- `.planning/phases/18.1-qml-bar-athena-restoration/18.1-CONTEXT.md` — D-04's
  `BarRoles` row table and D-24's rule that colours come from `BarRoles`, never
  `Colours.*` directly. Governs D-19-43.
- `.planning/ROADMAP.md` § Phase 19 Notes — the four locks scoping did not reopen:
  no soak window, the atomic autostart swap, DND ownership moving into QML, and
  promote-don't-copy for `QuickToggles.qml`.

### Files the retirement and debt items touch
- `hypr/.config/hypr/config/autostart.lua:137-140` — the `swaync-launch.sh` line in
  the atomic swap (D-19-42).
- `hypr/.config/hypr/config/keybinds.lua:226-227` — `Super+N`'s
  `swaync-client -t -sw`, repointed by D-19-16.
- `theme-engine/.config/theme-engine/contract.json:4,24` — the 2 swaync entries
  (`swaync.css`, `swaync-style.css`) deleted by D-19-43.
- `matugen/.config/matugen/config.toml:38-41` — `[templates.swaync]`, deleted.
- `theme-engine/.config/theme-engine/lib/reload.sh:82-88` — the
  `swaync-client -rs` step, deleted.
- `theme-engine/.config/theme-engine/theme-stress-test:247,294,309` — the
  `swaync.css` references and `REPRESENTATIVE_FILES` (D-19-46).
- `theme-engine/.config/theme-engine/lib/wallpaper.sh:14,242,263,336` — the
  `WALLPAPER_DIR` definition and the three `ln -sfr … current.jpg` calls (D-19-45).
- `hypr/.config/hypr/scripts/tests/quickshell-fixtures/poisoned-two-owner-busctl-list.txt`
  and `compliant-busctl-list.txt` — re-pointed and run live for D-19-41.
- `hypr/.config/hypr/scripts/retirement-check`, `hypr/.config/hypr/scripts/quickshell-doctor` —
  the checklist and structural-check scripts.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `Quickshell.Services.Notifications` — verified present in the installed
  quickshell 0.3.0-2 (`18-CONTEXT.md` records `Mpris`, `Notifications`, … among the
  available service modules). No `quickshell-git` needed.
- `QtQuick.Effects.MultiEffect` — installed at `/usr/lib/qt6/qml/QtQuick/Effects/`
  with `colorization` and `colorizationColor`. This is all Caelestia's `Colouriser`
  is, so D-19-22's tinted illustration needs no plugin.
- `modules/dashboard/AudioBackend.qml` — already exposes `inputVolume`,
  `inputMuted`, `setInputVolume` (lines 67, 82-87) off `Pipewire.defaultAudioSource`,
  plus the output side. Serves D-19-20 and D-19-21 with no new plumbing.
- `modules/bar/BrightnessBackend.qml` — the brightness reader/writer already driving
  the bar's scroll-to-adjust. Replaces swaync's `brightnessctl` shell-out.
- `modules/dashboard/QuickToggles.qml` — the six-tile grid (gaming, DND, dark,
  volume, wifi, bluetooth) with its `chipModel`, tooltips and chevron-dispatch
  pattern. Promoted to a shared type under D-19-19. **Note its hard constraint,
  recorded in-file: the "Do Not Disturb" label wraps to two lines and must never be
  shortened to an acronym — a render gate explicitly rejected that.**
- `modules/bar/SectionPopout.qml` and `PopoutController.qml` — the lightweight
  non-`PanelDialog` frame family from D-18-15, and the closest existing analog for a
  new top-level surface's structure.
- `modules/bar/BarRoles.qml` — the named colour-role table D-19-43 extends;
  `fillNotification` / `fillNotificationFg` already exist for the bell.
- `modules/bar/ClockActionsCapsule.qml` — the bell cell, its badge overlay, and the
  `NotificationSource` component that D-18-33 deliberately sealed the temporary
  swaync binding behind. That component is the seam D-19-16 replaces.
- `modules/dashboard/Design.qml` and `modules/Motion.qml` — the token sources for
  every duration, easing, padding and radius in this phase.

### Established Patterns
- **Colours come from `BarRoles`, never `Colours.*` literals or hex** — GATE-04's
  lint is `color:`-anchored and folded blocking into `theme-doctor`; the doctor also
  greps the literal `Colours\.` pattern for bar-family files.
- **Every new frame must be registered in `quickshell-doctor`'s structural checks**
  (GATE-03) — D-19-14 adds the third one.
- **Idle-timer inventory discipline (QBAR-11)** — D-19-32's relative timestamps use
  one shared ticker, not one timer per card.
- **Retirement is a checklist run before and after a single deletion plan**
  (RETIRE-01), established and exercised once for real on waybar in Phase 18.

### Integration Points
- The notification server shares the bar's process, so the bar's restart wrapper
  (QBAR-10) is also this server's restart path — and D-19-41's kill-and-respawn
  round exercises exactly that.
- `Super+N` moves from an `exec_cmd` shelling out to `swaync-client` to the shell's
  own IPC/GlobalShortcut, joining the same summon pattern the dashboard and overview
  already use.
- The DND toggle stops being a `swaync-client -dn/-df` CLI call from both grids and
  becomes a property on the D-19-19 singleton — the roadmap's "DND ownership moves
  into QML" note.

</code_context>

<specifics>
## Specific Ideas

- **"Prioritize what Caelestia shell does for every design decision. Keep it as a
  strong deciding factor."** — the user's own words, captured as D-19-00. It caused
  four already-answered popup decisions to be reversed mid-discussion (expand
  gesture, swipe semantics, stack depth, critical treatment), so downstream agents
  should treat a Caelestia divergence as something to justify explicitly, not to
  decide silently.
- Verified numbers pulled from Caelestia's actual source during this discussion, so
  planning does not have to re-derive them: `SidebarTokens width = 430`,
  `NotifsTokens width = 430 / image = 42 / badge = 20`, sidebar anchored
  `top`+`bottom` with a `padding.large` left margin, and the one-property
  `offsetScale` slide in `modules/sidebar/Wrapper.qml`. For contrast, end-4's
  `Appearance.sizes.sidebarWidth: 460` (`sidebarWidthExtended: 750`) with
  `height: parent.height - hyprlandGapsOut * 2`.
- The user reversed the popup-anchor decision once mid-discussion (from
  "follows the bar's edge" back to "always top-right"). The settled answer is
  D-19-01 — do not resurrect the edge-following variant.

</specifics>

<deferred>
## Deferred Ideas

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

</deferred>

---

*Phase: 19-notification-server-centre*
*Context gathered: 2026-08-13*
