# Phase 18: QML Bar & Retirement Machinery - Context

**Gathered:** 2026-08-10
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase delivers the always-on Quickshell bar that replaces waybar, plus every
piece of retirement machinery the four later migrations depend on.

**In scope:** QBAR-01..12 (the bar itself — orientation switching, workspace click,
scroll actions, tray, readouts, full auto-hide, hover/Super reveal, section popouts,
auto-restart, flat soak, stable reserved zone), RETIRE-01 (the generic retirement
checklist script), RETIRE-02 (waybar deleted — package, config, 7 contract entries,
`[templates.waybar]`, its `reload.sh` fan-out, `waybar-equivalence-check`,
`waybar-design-lint`), GATE-01..04 (behaviour enumeration, human render gate,
`quickshell-doctor` structural checks, QML hex-literal lint), LEDGER-01
(documentation corrections only) and LEDGER-03 (OVER-04's frame-rate measurement).

**Not in scope:** the notification centre (Phase 19), OSD and power menu (Phase 20),
the AGS fold-in and contract close (Phase 21), the fresh-install gate (Phase 22).
No per-screen fan-out. No new bar features beyond the named additions QBAR-08 and
QBAR-09.

</domain>

<decisions>
## Implementation Decisions

### Bar contents

- **D-18-01:** Both athena drawers carry forward, redesigned — the 8-icon
  app-launcher drawer and the 5-axis settings drawer (theme / orientation / font /
  icons / wallpaper). Chosen over dropping them to the Super-key menu.
- **D-18-02:** Workspace indicators render **live per-window app icons**, athena's
  `{icon} {windows}` shape — not the reference shells' dot/pill occupancy. Needs a
  per-app glyph map maintained in QML.
- **D-18-03:** All four extras get permanent slots: power button, gaming-mode
  toggle, notification bell, and updates count + idle inhibitor. Updates and idle
  inhibitor are athena-only today; both are promoted to the one bar.
- **D-18-04:** The system tray is **always visible at the end of the bar** — no
  chevron, no threshold collapse. Athena's tray removal is reversed. Backed by
  native `Quickshell.Services.SystemTray` (verified present on 0.3.0-2), with
  `Quickshell.DBusMenu` for QBAR-05's click-to-open menus.
- **D-18-05:** Now-playing rides native `Quickshell.Services.Mpris`, **and
  `MediaBackend.qml` is repointed onto the same singleton in this phase.**
  — **Reversibility:** costly — this replaces `media-status.sh watch`'s 1 Hz poll
  loop (≈10 subprocess forks/sec: 8 `playerctl` calls plus `media-players.sh`, `jq`,
  `media-art-resolve.sh`) as the dashboard Media tab's data source. Undoing it means
  restoring the bash reader and re-widening its `drawerOpen` gate. Pulls a slice of
  QMEDIA-03 out of Phase 21 deliberately; MPRIS reader count goes 3 → 1 here.
- **D-18-06:** Battery entry **exists in the list but renders nothing when absent**,
  via native `Quickshell.Services.UPower`. Verified: `/sys/class/power_supply/` is
  empty on this host (no battery, no AC device), chassis is `desktop`, board is a
  B550 AORUS ELITE AX V2. Satisfies QBAR-06 as written and survives a laptop
  deployment.
- **D-18-07:** No focused-window-title entry. Variable width is the worst element
  for a bar that must not reflow, and D-18-02's per-workspace icons already answer
  "what is running".

### Bar shape and grouping

- **D-18-08:** Floating detached capsule (athena's posture — height ~40, ~6px edge
  margin, ~10px side margins), not flush to the screen edge. Matches QBAR-01's
  "rounded-capsule language" and the dashboard/panel family's existing surfaces.
- **D-18-09:** **Discrete section capsules with gaps**, not one continuous pill.
  Each capsule is exactly one popout target or one drawer, so visual grouping and
  interaction grouping are the same boundary.
- **D-18-10:** Roughly **5–6 capsules grouped by concern**, e.g.
  `[launcher drawer] [system: cpu/ram/disk/updates] [workspaces] [media]
  [connectivity: audio/network/bluetooth] [clock] [actions: gaming/bell/settings/power]
  [tray]`. Exact split is a design-time call within this shape.

### Vertical orientation (right edge)

- **D-18-11:** Drawers **expand inward, horizontally** — a floating strip growing
  leftward over the desktop. Left-to-right expansion is off-screen on a right-edge
  bar, and vertical expansion would reflow the column.
- **D-18-12:** Workspace slots are **fixed-height with a `+N` overflow count**.
  Nothing below the workspaces ever moves as windows open and close. Mirrors
  `Overview.qml`'s pixel-stable fixed 5×2 block.
- **D-18-13:** Zones **re-map per orientation** — resolved as **one entry list where
  each entry carries a zone per orientation** (`horizontal: right`, `vertical: top`),
  never two arrangements to keep in sync. This is what keeps QBAR-02's
  "orientation is a property of a config-driven entry list, not a forked second
  layout" true.
  — **Reversibility:** costly — the entry-list schema is what every bar section
  reads; adding the per-orientation zone field later means touching every entry.
- **D-18-14:** Text-bearing entries use **stacked/abbreviated text at the same
  column width** (~44px): clock as two stacked lines, readouts as glyph + short
  value. Not icon-only, not a wider column.

### Section popouts (QBAR-09)

- **D-18-15:** A **new lightweight popout type**, separate from `PanelDialog.qml`.
  Rationale for the record: `PanelDialog` is a fixed **850×620** window, `anchors.top`
  only (compositor-centred), `exclusiveZone: 0`, `WlrLayer.Overlay` — reusing it
  would mean the bar's audio pill opens the same centred dialog `Super+A` already
  opens, delivering nothing new for QBAR-09.
  — **Reversibility:** costly — it becomes a second frame that must be registered in
  GATE-03's `quickshell-doctor` structural checks, covered by GATE-04's hex lint, and
  kept in visual and motion step with `PanelDialog` **by review rather than by
  construction**. `PanelDialog.qml`'s own header states every panel is built from it,
  "never a bespoke `PanelWindow`" — this decision knowingly adds the second frame.
- **D-18-16:** Six sections get popouts: **audio, wifi, bluetooth, clock→calendar,
  cpu/ram/disk→resources, now-playing→media**. Backends already exist for all six
  (`AudioBackend`, `WifiBackend`, `BluetoothBackend`, `DashboardTab`'s calendar,
  `SystemResources`, and the native Mpris singleton from D-18-05).
- **D-18-17:** The dashboard drawer **keeps its full four-tab role**; popouts are the
  fast path. Same detail-surface/glance-surface relationship `Overview` (Super+O)
  already has with the workspace pills. No shipped v3.0 surface is thinned.
- **D-18-18:** Interaction is **hover-to-preview, click-to-pin** (chosen over the
  panel family's click-only model).

### Popout hover mechanics

- **D-18-19:** Hover-preview is **suppressed until the reveal animation has settled
  AND the pointer has moved at least once on the settled bar.** Without this the
  reveal gesture and the preview gesture are the same motion, and revealing the bar
  fires a popout under wherever the pointer happened to enter.
- **D-18-20:** Dwell before preview is **~400ms** — inside the MD3 duration
  vocabulary the motion tokens already speak. Sliding across the bar toward the tray
  must open nothing.
- **D-18-21:** An unpinned popout **closes when the pointer leaves both the section
  and the popout**, treated as one hover region with a short grace period so moving
  diagonally into the popout does not dismiss it mid-travel.
- **D-18-22:** A **pinned popout ignores hover entirely** and dismisses on
  click-outside — identical to the existing panel family, including the
  one-open-at-a-time invariant and the single guarded summon path in `shell.qml`.

### Auto-hide and reserved space

- **D-18-23:** **Per-driver exclusive-zone policy.** Idle **keeps** the reserved zone
  (bar renders nothing but the space stays claimed — no window reflow); fullscreen,
  gaming mode and the keybind **release** it.
  Recorded baseline this preserves: today's bar has three states, not two —
  `visible` (empty CSS + SIGUSR2, zone reserved), `hidden-idle`
  (`window#waybar { opacity: 0.05 }` + SIGUSR2, **zone still reserved, no reflow, but
  pixels faintly lit** — the exact sliver QBAR-07 exists to kill), and `hidden-hard`
  (SIGUSR1 unmap, zone released, windows reflow). This decision replaces the idle
  dim with a genuine hide while keeping idle's no-reflow property.
- **D-18-24:** Reveal uses an **invisible input-only hot zone** present only while
  hidden — not pointer-position polling, which would need a timer running while
  hidden and is exactly what QBAR-11 polices.
- **D-18-25:** The hot zone sits on the **physical screen edge, ~3–5px deep** — not
  at the floating capsule's offset position, and not the full bar footprint. The
  pointer must be able to slam to the edge without aiming.
- **D-18-26:** Re-hide is on a **grace timer**: the bar re-hides only after the
  reveal condition has ended (pointer left / Super released) AND no popout is open
  AND a short grace period has passed. The bar must never vanish under the pointer
  mid-interaction.

### Visibility ownership

- **D-18-27:** The **script stays sole owner**, renamed `bar-visibility.sh`. Its
  flock'd read-modify-write, per-source intent files under `~/.cache/`, and OR-union
  computation are untouched; only actuation changes from SIGUSR1/SIGUSR2 to
  `qs ipc call`.
  Rationale for the record: Quickshell 0.3.0-2 **cannot detect idle** — the only
  idle-related type in the entire install is
  `qs::wayland::idle_inhibit::IdleInhibitor` (the inhibit side); there is no
  `ext-idle-notify` consumer. hypridle therefore remains the idle source and invokes
  a command line no matter what. On-disk state also survives the QBAR-10 restarts,
  which in-process state would not.
  — **Reversibility:** costly — six callers declare intent today
  (`hypridle.conf:53-54`, `gaming-mode-toggle.sh:61` and `:255`,
  `waybar-fullscreen-watch.sh`, `keybinds.lua:107`, `theme-engine/lib/reload.sh:82`);
  moving ownership later means re-pointing all of them.
- **D-18-28:** `waybar-fullscreen-watch.sh` is **retired**; the shell reports
  fullscreen intent to the owner instead. `shell.qml` already watches this natively
  (`Hyprland.activeToplevel.lastIpcObject.fullscreen` plus an `onRawEvent` refresh on
  the `fullscreen` socket2 event, both proven live on 0.56.1). Deletes one
  long-running process, which QBAR-11's process-count soak measures directly.
  **Constraint this creates:** while the shell is down, nothing reports fullscreen.
  The owner's default for a missing intent file is `show`, so it degrades to a
  visible bar — safe, and stated here rather than left implicit.
- **D-18-29:** Super+Shift+B **stays a Hyprland bind** to the owner script rather
  than becoming a QML `GlobalShortcut`. A `GlobalShortcut` cannot resurrect a bar
  whose process is gone, and `keybind-doctor`'s bind inventory needs only a path
  rename.
- **D-18-30:** `waybar-switch.sh`'s four-layout picker becomes a **horizontal /
  vertical orientation toggle** in both the settings drawer and the Super-key menu's
  settings entry — preserving the discoverable path already in daily use.

### GATE-02 human render gate

- **D-18-31:** The gate runs at **checkpoints during the phase plus one blocking
  final pass** before the deletion commit — not a single end-of-phase look.
  Precedent cited at decision time: this repo has shipped visibly broken surfaces
  through fully green automated gates three times (Phase 6, Phase 8's bar, Phase 16's
  two false passes).
- **D-18-32:** The comparison baseline is **athena for the aesthetic judgment, plus a
  named-capability check against full / floating / vertical** to confirm nothing
  those three uniquely offered was silently lost. Deliberately splits an aesthetic
  judgment from a capability audit rather than asking one look to do both, and avoids
  the side-by-side screenshot shape that would invite a port-not-redesign reading.

### Notification bell

- **D-18-33:** The bell is **wired to swaync for this phase** — keeps the unread
  count from `swaync-client -swb` and opens swaync's centre, exactly as
  `custom/notification` does today, just rendered by the new bar. Phase 19 swaps what
  is behind it without touching the layout.
  — **Reversibility:** reversible — one deliberately temporary binding. Phase 19's
  own checklist run over `swaync` will catch it if it is ever forgotten.

### Retirement checklist (RETIRE-01)

- **D-18-34:** **Generic from day one** — `retirement-check <surface-name>`, not
  waybar-shaped with a Phase 19 generalisation. Phase 19 deletes swaync with no soak
  window and no rollback; that is a poor moment to be refactoring the tool that
  verifies it. Phase 18 is also the only phase that exercises it twice against a real
  deletion before anything else depends on it.
- **D-18-35:** **Blocking, folded into `theme-doctor`** — following the established
  fold pattern (`waybar-design-lint` at 08-15, `motion-lint` at 12-05, both already
  in `theme-doctor` and reporting into its tally). Standing precedent: WINDOWS #1, an
  orphaned `eww.scss` contract entry that blocked `theme-doctor` for a full milestone
  because nothing enforced this class.
- **D-18-36:** Coverage extends beyond RETIRE-01's named classes to **all four** of:
  `theme-doctor`'s own internal blocks, test fixtures and doctor registries,
  cross-script references in unrelated scripts, and planning docs / prose.
- **D-18-37:** Coverage is implemented as **two tiers in one script** —
  a **blocking tier** over live code, config, fixtures and checker internals, and a
  **reported (non-failing) tier** over `.planning/` and repo prose. Rationale:
  `.planning/` carries hundreds of historical waybar mentions in shipped milestone
  archives that must stay; counting them in the blocking tier makes "zero hits"
  unreachable and therefore meaningless.

**Resolved during plan-phase research (2026-08-10)**

- **D-18-38:** The bar's `exclusiveZone` is **`Design.barHeight + Design.barEdgeMargin`
  (= 46px), a single edge margin, not doubled.** 18-UI-SPEC.md's "Auto-Hide & Reveal
  Motion Contract" section states `barHeight + barEdgeMargin*2` (= 52px); that formula is
  wrong and must be corrected in the UI-SPEC as part of this phase. Rationale: this host's
  live, currently-working waybar reserves exactly 46px (`hyprctl monitors -j` →
  `reserved: [0, 46, 0, 0]`, verified 2026-08-10). Building to the doubled formula reserves
  6px more than the baseline GATE-02 compares the bar against pixel-for-pixel.
- **D-18-39:** QBAR-04's brightness-scroll ships **present-but-inert, gated on hardware
  presence** — a brightness section wired to `brightnessctl` (already at
  `/usr/bin/brightnessctl`) that renders **nothing** when no backlight device exists.
  Rationale: this is the exact D-18-06 battery precedent. `/sys/class/backlight/` is empty
  on this desktop board, `light` (which the existing `config-floating.jsonc` backlight
  module shells out to) is not installed, and no QML brightness backend exists — the
  capability has been a dead no-op in waybar too, so this is not a phase-18 regression.
  QBAR-04 is structurally satisfied and the code works unchanged on a laptop or DDC monitor.
  Consequence: **GATE-02 criterion B.3 cannot be demonstrated live on this host** and must
  be recorded as "not demonstrable on this hardware — structurally present", not as a pass.
- **D-18-40:** QBAR-10's auto-restart is a **new systemd `--user` unit**
  (`quickshell.service`) with an **explicit** `Restart=on-failure`, `RestartSec=`, and
  `StartLimitIntervalSec=`/`StartLimitBurst=`, replacing the `uwsm app --` launch for
  quickshell only. Rationale: backoff and crash-loop rate-limiting come from the OS instead
  of hand-rolled bash, and a genuinely broken build fails **loudly** in
  `systemctl --user status` rather than respawning forever (Pitfall 9's local-DoS vector).
  The shape is copied from the shipped-but-unused `waybar.service`. Accepted cost: this is
  the **first deviation** from this repo's `uwsm app --`-everywhere autostart convention —
  name it explicitly in the plan; do not let it read as an accident. The rejected
  alternative (a `while true` respawn loop inside `quickshell-launch.sh`) would have needed
  hand-written backoff plus a max-restarts-per-window guard, and would add a second
  long-lived wrapper process that QBAR-11's process-count soak must then account for.
- **Correction to D-18-27's recorded rationale (the decision itself stands):** D-18-27
  states that "Quickshell 0.3.0-2 cannot detect idle… there is no `ext-idle-notify`
  consumer." That is **factually wrong** — `Quickshell.Wayland._IdleNotify` ships an
  `IdleMonitor` type (`enabled`/`timeout`/`respectInhibitors`/`isIdle`) that is a genuine
  `ext-idle-notify-v1` consumer, verified in the installed `.qmltypes`. D-18-27's
  conclusion is unchanged and still correct for independent reasons (the script survives
  QBAR-10 restarts, owns on-disk state, and has six existing callers), but the false claim
  must not be repeated as fact in the plan or in any later phase's research.

### Claude's Discretion

- Exact capsule split within D-18-10's 5–6 by-concern shape.
- Grace-period and dwell tuning around D-18-20/21/26's stated values, as long as the
  suppression rule in D-18-19 holds.
- Hot-zone depth within D-18-25's 3–5px range.
- Per-app glyph map contents for D-18-02 (seed from athena's existing
  `window-rewrite` table in `waybar/.config/waybar/config-athena.jsonc`).
- All of GATE-03's `quickshell-doctor` structural checks, GATE-04's hex-literal lint
  shape, LEDGER-01's documentation corrections, and LEDGER-03's frame-rate
  measurement method — mechanical, no user preference expressed.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Phase scope and requirements
- `.planning/ROADMAP.md` § Phase 18 — goal, 5 success criteria, and the Notes block
  (GATE-01/02 recurrence, the `exclusiveZone > 0` hazard, the no-`Variants` rule)
- `.planning/REQUIREMENTS.md` § QBAR / RETIRE / GATE / LEDGER — the 20 requirement
  texts, plus § Scoping Decisions and § Placement notes
- `.planning/PROJECT.md` § Active, § Out of Scope, § Key Decisions — the
  redesign-not-port framing and the D-13 per-screen drop

### Quickshell surfaces to copy or extend
- `quickshell/.config/quickshell/shell.qml` — the shell root: LazyLoader summon
  pattern, `fullscreenBlocking` guard, `openPanel()` single guarded summon path,
  `IpcHandler` verbs, `GlobalShortcut` declarations
- `quickshell/.config/quickshell/modules/Overview.qml` — the single-`PanelWindow`
  pattern the bar must copy (QS-03 is permanently dropped; do not re-attempt
  `Variants`)
- `quickshell/.config/quickshell/modules/dashboard/PanelDialog.qml` — the 850×620
  centred frame; read to understand what the new popout type is deliberately *not*
- `quickshell/.config/quickshell/modules/Dashboard.qml` — `exclusiveZone: 0` /
  `ExclusionMode.Normal` commentary (D-03/D-08/D-43) and the layer/namespace scheme
- `quickshell/.config/quickshell/modules/dashboard/Design.qml` — spacing tokens
  (`spacingXs 4 / Sm 8 / Md 16 / Lg 24 / Xl 32`) and font scale
- `quickshell/.config/quickshell/modules/dashboard/MediaBackend.qml` — the reader
  being repointed by D-18-05
- `quickshell/.config/quickshell/modules/dashboard/GradientBorder.qml`,
  `SystemResources.qml`, `QuickToggles.qml`, `AudioBackend.qml`, `WifiBackend.qml`,
  `BluetoothBackend.qml` — reusable assets

### waybar (being enumerated per GATE-01, then deleted per RETIRE-02)
- `waybar/.config/waybar/config-athena.jsonc` — the design lineage and the
  `window-rewrite` glyph map
- `waybar/.config/waybar/config-full.jsonc`, `config-floating.jsonc`,
  `config-vertical.jsonc` — the three layouts D-18-32's capability check covers
- `waybar/.config/waybar/modules.jsonc` — canonical module definitions incl.
  `custom/notification`'s `swaync-client -swb` binding
- `waybar/.config/waybar/bar-common.jsonc` — the fixed-signal contract (D-03) the new
  owner replaces

### Visibility and launch machinery
- `hypr/.config/hypr/scripts/waybar-visibility.sh` — the owner being renamed; read
  the header's state model and lock discipline before touching it
- `hypr/.config/hypr/scripts/wallpaper-visibility.sh` — the Phase 17 clone of the
  same pattern; the convention's second instance
- `hypr/.config/hypr/scripts/waybar-fullscreen-watch.sh` — being retired (D-18-28)
- `hypr/.config/hypr/scripts/quickshell-launch.sh` — has **no restart wrapper**;
  QBAR-10 adds one. Carries the `QSG_RENDER_LOOP=threaded` export LEDGER-03 measures
  against
- `hypr/.config/hypr/hypridle.conf` §lines 41-55 — the idle intent declaration
- `hypr/.config/hypr/config/keybinds.lua:107` — Super+Shift+B
- `hypr/.config/hypr/config/autostart.lua` — launch entries
- `hypr/.config/hypr/scripts/gaming-mode-toggle.sh:61,255` — gaming intent

### Gates and contract
- `theme-engine/.config/theme-engine/theme-doctor` — the fold pattern to copy
  (`waybar-design-lint` fold at ~660, `motion-lint` fold at ~681) **and** the
  hardcoded waybar block at ~467-559 that D-18-36 requires the checklist to catch
- `hypr/.config/hypr/scripts/quickshell-doctor` — gains GATE-03's structural checks
- `hypr/.config/hypr/scripts/motion-lint` — the deny-by-default discipline GATE-04
  mirrors for hex literals
- `theme-engine/.config/theme-engine/lib/reload.sh:82` — the `reassert` call
- `hypr/.config/hypr/scripts/tests/quickshell-fixtures/` — fixtures naming waybar
- `install.sh`, `stow.sh` — package and stow lists RETIRE-02 edits

### Verified environment facts (do not re-derive)
- quickshell **0.3.0-2**. Available service modules: `Mpris`, `Notifications`,
  `SystemTray`, `UPower`, `Pipewire`, `Bluetooth`, `Polkit`, `Pam`, `Greetd`, plus
  `DBusMenu`, `Hyprland`, `Networking`, `Wayland`, `Widgets`, `WindowManager`.
- **No idle-notify client exists** — only `qs::wayland::idle_inhibit::IdleInhibitor`.
- `/sys/class/power_supply/` is **empty**; chassis `desktop`; board B550 AORUS ELITE
  AX V2.
- `media-status.sh` polls at **`POLL_INTERVAL=1`** (1 Hz), forking ~10 processes per
  tick.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`Overview.qml`** — the single-`PanelWindow` surface pattern the bar copies.
- **`shell.qml`'s summon architecture** — LazyLoader-per-surface, one guarded
  `openPanel()` owning the fullscreen rule, `IpcHandler` verbs, `GlobalShortcut`
  declarations mirrored in `shortcuts.json`. The bar is the first surface that is
  *not* summon-on-demand, so it inverts this: always active, never destroyed.
- **`AudioBackend` / `WifiBackend` / `BluetoothBackend` / `SystemResources`** — all
  six popouts in D-18-16 have an existing backend. `AudioBackend`'s gate is already
  widened by `shell.qml`'s `audioTruthNeeded` pattern — the same shape the bar needs.
- **`GradientBorder.qml`** — the animated rim, kept in step with Hyprland's own
  `borderangle` via the `indicators` motion bucket.
- **`Design.qml`** — spacing and font tokens; `Colours.qml` / `Motion.qml` singletons
  read `~/.local/state/theme/`.
- **`waybar-visibility.sh`** — a proven flock'd single-owner state machine; kept
  wholesale under D-18-27.

### Established Patterns
- **Zero-idle doctrine (D-32/D-36):** every backend is gated so it runs no timer or
  subprocess while its surface is dismissed. The bar has **no dismissed state**, so
  it inherits none of this discipline — this is the phase's named new hazard and
  what QBAR-11's soak measures. D-18-05's native Mpris and D-18-24's surface-based
  hot zone are both chosen to keep the always-on cost at zero subprocesses.
- **One shared frame per surface family** — `PanelDialog`'s header forbids bespoke
  `PanelWindow`s. D-18-15 knowingly adds a second frame; it must be brought under
  GATE-03 and GATE-04 to compensate.
- **Single-owner visibility with per-source intent files** — two instances already
  (`waybar-visibility.sh`, `wallpaper-visibility.sh`). The header records that the
  desync bug class this prevents has been deleted from this repo **twice**.
- **Checker folds into `theme-doctor`** — `waybar-design-lint` (08-15) and
  `motion-lint` (12-05) both fold into its tally. D-18-35 follows it.
- **`config-then-package` deletion in one commit** — WINDOWS #1's standing precedent.

### Integration Points
- `shell.qml` — the bar mounts here as the first always-active (non-LazyLoader)
  surface, and gains the fullscreen-intent reporter replacing
  `waybar-fullscreen-watch.sh`.
- `qs ipc` — the actuation seam between `bar-visibility.sh` and the bar.
- `hypridle.conf`, `gaming-mode-toggle.sh`, `keybinds.lua`, `reload.sh` — the four
  external intent declarers, repointed at the renamed owner.
- `contract.json` / `[templates.waybar]` / `reload.sh` — 7 contract entries and the
  matugen template removed in the same commit as the package.
- `theme-doctor` — loses its waybar block, gains the retirement-check fold.
- `quickshell-doctor` — gains structural checks for the bar and the popout type.
- `install.sh` / `stow.sh` — waybar removed from both.

</code_context>

<specifics>
## Specific Ideas

- **athena is the design lineage**, explicitly: discrete rounded capsules, live
  window-icon workspaces, hover-expand drawers, an app-launcher drawer. Its own
  header cites `github.com/haikal-hakim/athena`. The QML bar is a redesign toward
  this shape, not a port of the JSONC.
- **The bar deliberately goes denser than the reference shells.** Both end-4 and
  Caelestia were the recommended lighter option on drawers, workspace style and
  grouping; athena's richer shape was chosen each time. Planners should not "simplify
  toward the reference" — that reading is wrong for this phase.
- **The 5% idle dim is the specific thing being killed.** `IDLE_DIM_OPACITY="0.05"`
  in `waybar-visibility.sh:99` is the lit sliver QBAR-07's OLED constraint targets.
- **Windows must not reflow when you step away.** Preserving today's no-reflow-on-idle
  behaviour was the deciding factor in D-18-23.
- **The bar must never vanish under the pointer.** D-18-19/21/26 all exist for this.

</specifics>

<deferred>
## Deferred Ideas

- **Caelestia's shrink-to-a-sliver auto-hide** — already in REQUIREMENTS.md § Out of
  Scope; re-confirmed here. Leaves static pixels lit, against the OLED constraint.
- **Popouts replacing dashboard tabs** — considered and rejected under D-18-17. If
  the duplication proves annoying in daily use, thinning the drawer is a v5.0
  question, not a Phase 18 edit to a shipped v3.0 surface.
- **Orientation toggle as a keybind** — rejected under D-18-30; free plain-Super
  letters are scarce on this host and orientation changes roughly never.
- **Generalising `bar-visibility.sh` into one owner shared with
  `wallpaper-visibility.sh`** — two near-identical owners now exist. Not in scope;
  worth revisiting once a third appears.

</deferred>

---

*Phase: 18-QML Bar & Retirement Machinery*
*Context gathered: 2026-08-10*
