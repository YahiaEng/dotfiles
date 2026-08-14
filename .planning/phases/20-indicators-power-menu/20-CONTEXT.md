# Phase 20: Indicators & Power Menu - Context

**Gathered:** 2026-08-14
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase delivers two QML surfaces and three package deletions, plus two debt items:

1. **QML on-screen indicators** replacing SwayOSD — volume, microphone, brightness
   and Caps Lock feedback (QOSD-01..04).
2. **A QML power menu** replacing wleave — six actions, keyboard-navigable, with a
   pre-action safety warning (QPOWER-01..04).
3. **Retirement** — `swayosd` (incl. its libinput backend service) and `wleave` leave
   repo and host, and the still-installed `wlogout` + `eww` leftovers are uninstalled
   (RETIRE-04, RETIRE-05, RETIRE-07).
4. **Debt** — LEDGER-02 (settle MAINT-02 Logout) and LEDGER-05 (WINDOWS.md triage).

**The two surfaces share no backend** and are independently buildable. This is why they
share a phase rather than each occupying a thin one — and why each gets its own render
gate (D-20-30).

**Not in this phase:** the media fold-in (Phase 21), the fresh-install proof (Phase 22),
the launcher (out of scope for v4.0 entirely).

</domain>

<decisions>
## Implementation Decisions

### Governing rules inherited from Phase 19

- **D-19-00 still governs.** Caelestia's shipped behaviour is the strong default, end-4
  secondary; check `.planning/research/FEATURES.md` § OSD / § POWER before proposing an
  approach, and name the divergence explicitly whenever recommending against Caelestia.
  Several decisions below *do* diverge — each says so and why.
- **WINDOWS #1 precedent (standing, not re-litigated):** for each retirement, the package
  deletion, the `contract.json` entry, the matugen template, the reload step, the layer
  rules and any checker reference land in the **same commit**, config-then-package.
- **Zero-idle backends:** nothing polls or spawns a subprocess while its surface is
  dismissed (the dashboard's own standing rule).
- **No hardcoded colours or motion numbers** — `colour-lint` (GATE-04) and `motion-lint`
  both reject them; read from `Colours.qml` / `BarRoles.qml` / `Motion.qml`.

### The OSD surface

- **D-20-01:** The OSD sits **bottom-centre**, matching SwayOSD's current anchor.
  *Divergence from Caelestia*, which places OSD in its right-edge popout region — but
  Caelestia's placement is a consequence of its own right-edge stack, not a behaviour
  gained. Bottom-centre also means the OSD collides with nothing this shell already
  owns (popups top-right, centre right-edge, DND toast top-centre).
- **D-20-02:** The OSD is a **`Toast.qml` instance, not a new frame type.** `Toast.qml`
  gains exactly two opt-in properties, both defaulting to today's values so the DND
  toast is byte-unchanged in behaviour:
  - an **edge/anchor property** (it currently hardcodes `anchors.top: true`), and
  - **`interactive`** (default `false`) enabling pointer input.
  — **Reversibility:** reversible — two additive properties on one file, both defaulted
  to current behaviour; backing them out is a local edit.
- **D-20-03:** `Toast.qml`'s header currently states the frame is "never dismissible by
  click… feedback, not content." **That claim narrows rather than breaks**: it remains
  true for the DND toast and for the non-interactive default. The header must be updated
  in the same commit that adds `interactive`, so the file does not carry a statement its
  own code contradicts.
- **D-20-04:** **No new top-level frame is created for the OSD** — therefore no new
  GATE-03 `quickshell-doctor` registry entry beyond the namespace registration in D-20-25.
- **D-20-05:** The OSD is triggered by **state change on the backends**
  (`Connections` on `AudioBackend.qml` / `BrightnessBackend.qml`), never by the keybind.
  Both reference shells do this. Consequence, intended: a bar scroll (QBAR-04), a centre
  slider, or an external CLI call also raises the indicator.
- **D-20-06:** Auto-hide uses a **new `Design.osdHideDelayMs` token**, not
  `notifToastDurationMs` (2000). The OSD's dwell must be tunable independently of the DND
  toast. Starting value is the planner's call; SwayOSD's own default is 1000 ms.
- **D-20-07:** **Hover pauses the dismiss timer** and resumes on leave (QOSD-03,
  Caelestia's behaviour). *Divergence from end-4*, which hides immediately on hover.
  This is the requirement that forces `interactive` in D-20-02.

### QOSD-04 — the multi-slider column

- **D-20-08:** A control earns a slider via a **rolling recency window** — its value
  changed within the last N seconds, window sliding on each change. *This is a project
  addition, not Caelestia's behaviour*: Caelestia gates sliders on static config flags
  (`enableMicrophone` / `enableBrightness`) and shows them unconditionally. QOSD-04's
  "only if that control actually moved" is ours.
- **D-20-09:** Sliders are **adjustable in place by both scroll and drag**, writing
  through the same `AudioBackend` / `BrightnessBackend` paths the centre's sliders
  already use. A visible slider that refuses a drag reads as broken.
- **D-20-10:** Column width is a **new `Design.osdWidth` token, ~380px** — wide enough
  that a track reads as adjustable, deliberately narrower than the 430px shared by the
  notification popups and centre (D-19-02/D-19-15) so the OSD stays visibly a lighter
  surface.
- **D-20-11:** **Caps Lock replaces the column** with a single icon + label row — the
  shape the DND toast already uses — rather than joining it as a row. A binary state does
  not belong in a column built for continuous values.
- **D-20-12:** The Caps Lock indicator fires **only when caps turns on**, not on release.
  *Divergence from SwayOSD*, which flashes on both transitions.

### Caps Lock without a root service (QOSD-02)

- **D-20-13:** Read `/sys/class/leds/*::capslock/brightness` via a watched file.
  **Verified on this host 2026-08-14:** `/sys/class/leds/input5::capslock/brightness`
  exists, is world-readable, and currently reads `0`. The no-root mechanism is confirmed
  viable, not hypothetical.
- **D-20-14:** The node is resolved by **glob at startup, re-globbed on read failure**.
  `input5` is a kernel input index, not a stable name — a replug or boot-order change
  makes it `input7::capslock`. Re-globbing on failure handles that without watching for
  device events. If no node matches at all, the indicator is **absent**, never broken.
- **D-20-15:** **Known divergence, accepted:** `hyprctl devices -j` reports `capsLock`
  for **two** keyboards on this host (the Corsair K70 and an
  `instant-usb-gaming-mouse--keyboard`), but only one has an LED node. The sysfs approach
  therefore tracks one keyboard's LED, not global caps state. Matching the node to
  Hyprland's active keyboard was considered and rejected as machinery for a case where
  only one of the two has an LED at all.
- **D-20-16:** Polling `hyprctl devices -j` instead of sysfs was rejected — it needs a
  timer (no Hyprland event fires on caps), contradicting the zero-idle rule, and QOSD-02
  explicitly names the sysfs-node-via-watched-file mechanism.

### `swayosd-libinput-backend.service` — the named scope call (RETIRE-04)

- **D-20-17:** **Measure first, then delete.** Before removal, press Caps Lock at the SDDM
  prompt and record whether any indicator appears. **Ground truth as of 2026-08-14:**
  `sddm.service` is enabled, `swayosd-libinput-backend.service` is enabled at system
  level — but the thing it feeds, `swayosd-server`, is only started inside the Hyprland
  session (`autostart.lua:192`). The prediction is that its pre-session reach is already
  dead; the measurement is what converts that from a prediction to evidence. The roadmap
  requires this call be **recorded either way, BAR-02-style, not defaulted into**.
  This follows the project's own Phase 15 key decision: *prefer the measurement over the
  inherited analogy*.
  — **Reversibility:** one-way — the service is deleted with the `swayosd` package;
  restoring it means reinstalling a package this milestone exists to remove.
- **D-20-18:** If the measurement shows greeter feedback **does** work and matters, that
  blocks RETIRE-04 outright (the backend cannot run without the `swayosd` package) and
  must be escalated as a scope decision, not worked around.

### QOSD-01's lock-screen clause

- **D-20-19:** **Settle by measurement at GATE-01.** hyprlock is an `ext-session-lock-v1`
  client and the protocol requires the compositor to render only the lock surfaces; a
  layer-shell overlay — which SwayOSD also is — should already be invisible there. GATE-01
  adds one check: press volume while hyprlock is up, does the SwayOSD pill appear?
  - **If it does not:** QOSD-01's real content is "the keys keep working while locked,"
    already true via the `locked = true` binds at `keybinds.lua:297-308`. The requirement
    is **amended with the evidence**, not chased.
  - **If it does:** the clause is a genuine capability and the phase must solve it.
- **D-20-20:** Putting the readout inside hyprlock's own config was considered and
  **rejected** as net-new scope in a config the shell does not own.

### The power menu

- **D-20-21:** The menu is a **centred floating dialog on the `PanelDialog` family**, six
  actions in a **3×2 grid**, with a scrim behind. Chosen over both references: end-4's
  full-screen overlay (and today's wleave) and Caelestia's inline right-edge popout.
  Reasons: a contained frame gives QPOWER-03's warning a natural home inside the surface;
  a 3×2 grid makes arrow navigation two-dimensional and unambiguous where six-across is
  left/right only; and it adds **no new top-level frame type**, so no new GATE-03 entry.
  *Divergence from Caelestia (D-19-00) recorded explicitly:* its right-edge placement
  would contend for the same region as the notification centre built in Phase 19.
- **D-20-22:** **All three existing entry points repoint** to the shell — none may be left
  calling `wleave.sh`:
  - `hypr/.config/hypr/config/keybinds.lua:68` — `Super+Shift+Q`
  - `elephant/.config/elephant/menus/main.toml:35` — the walker menu's power entry
  - `quickshell/.config/quickshell/modules/bar/ClockActionsCapsule.qml:567,579` — the
    bar's `power_settings_new` glyph (`powerScriptPath` + `powerLaunchProcess`)
  The bar glyph was **not** in the roadmap's consumer list and is a third consumer; it
  must appear in the retirement checklist's zero-hit set.
- **D-20-23:** `ClockActionsCapsule`'s `powerAvailabilityProbe` (`test -x wleave.sh`,
  line 571) is **removed entirely**, along with the `powerAvailable` binding. The menu
  becomes an in-process QML surface, so "the power menu is missing" stops being a
  reachable state — the exact risk that probe's own comment cites.
- **D-20-24:** **Exclusive keyboard focus** (`WlrKeyboardFocus.Exclusive`), arrow-key
  navigation across the 3×2 grid, Enter activates, Escape closes, first action
  auto-focused (QPOWER-02) — **plus** wleave's existing per-action mnemonics
  `l/e/u/h/r/s`, which work today but are undisplayed (`show-keybinds: false`).
  *Deliberate divergence from D-19-18's no-exclusive-focus rule:* that rule was written
  for a non-modal centre. This surface's actions end the session.
- **D-20-25:** **Redesign toward the reference language**, not a port of wleave's six hue
  capsules. This is the milestone's stated intent and is why GATE-02 is mandatory — the
  old-vs-new equivalence check is forfeit by design.
- **D-20-26:** The six action command strings currently live **only** in
  `wleave/.config/wleave/layout.json`, which is deleted with the package. They must be
  migrated into QML **before** deletion. `hyprshutdown` itself is a separate package
  (`hyprshutdown 0.1.1-6`) and is unaffected by any deletion in this phase.

### QPOWER-03 — the safety warning

- **D-20-27:** Three detectors:
  1. **A running pacman/paru/yay process** (`pgrep`), *not* `/var/lib/pacman/db.lck` —
     a stale lock from a crashed pacman would warn on every shutdown forever, and a
     warning that always fires is one you stop reading.
  2. **Active downloads** — end-4's own second check, deliberately vague because it is a
     heuristic (recent `.part`/`.crdownload` files or Downloads-folder mtime).
  3. **A toplevel count driven by a configured window-class deny-list.** Recorded
     honestly: this is a hand-maintained list, not a detector — it warns about what it
     was told to warn about. It is the bounded stand-in for the unkillable-client hazard;
     **the hazard itself is characterised by LEDGER-02, not by this list.**
- **D-20-28:** **Warn only — the action stays available.** end-4's behaviour. Nothing is
  disabled: you are the one who knows whether that pacman run matters, and a stuck
  detector must never be able to lock you out of powering your own machine down.
- **D-20-29:** The warning applies to **Shutdown, Reboot, Hibernate and Logout** — not
  Lock or Suspend. Hibernate is included because a suspended-to-disk pacman transaction
  resumes into an inconsistent package db just as badly as a hard poweroff.
- **D-20-30:** Checked **on open, then polled on a low-frequency `Timer` while visible**.
  Nothing runs while the menu is dismissed (zero-idle rule).

### Cross-surface behaviour

- **D-20-31:** The OSD is **suppressed while the power menu is open**. The dialog is modal
  with a scrim; an indicator blipping over it reads as a leak through the modal. It is
  **not** suppressed by the notification centre — QNOTIF-10's rule exists because popups
  and the centre show the same content twice, and an OSD duplicates nothing.
- **D-20-32:** **Opening the power menu dismisses live notification popups** (end-4's
  `timeoutAll()` shape). Nothing is lost — per D-19-07 a dismissed popup stays in history;
  only the on-screen instance goes.

### Motion and layer rules

- **D-20-33:** Two **distinct layer namespaces** — `quickshell-osd` and
  `quickshell-session` (final names the planner's call) — each with its own
  animation / blur / `ignore_alpha` rows **declared AFTER the `^quickshell-.*` family
  pair** in `windowrules.lua` (the family regex is at lines 396 and 445; per-surface rows
  at 499-526 already use exactly this placement). Sharing `quickshell-notif-toast` for the
  OSD was rejected: the two surfaces could then never take different blur or alpha, and
  `hyprctl layers` could not tell a volume blip from a DND toast.
- **D-20-34:** **Each surface's QML alpha is pinned at or above the `ignore_alpha` floor
  its own rule declares, in the same commit as that rule.** The family floor is 0.5; a
  QML alpha below the active floor silently kills blur, with a symptom indistinguishable
  from a wrong rule.
- **D-20-35:** The power grid enters on a **staggered per-action cascade**, re-expressing
  wleave's md3_decel entrance that was already approved on sight — re-timed entirely on
  `Motion.qml` tokens, with no hand-rolled numbers (`motion-lint` enforces this).
- **D-20-36:** Grid entrance and input readiness were **not** serialised (the third option
  offered). WINDOWS rows 3 and 4 — the Phase 9 hover-during-entrance interaction that was
  never exercised live — remain open and are in-scope for LEDGER-05 triage.

### LEDGER-02 — settling MAINT-02 Logout

- **D-20-37:** **The D-29 teardown measurement is NOT taken. Logout is wrapped anyway.**
  Target shape: `cliphist wipe; hyprshutdown --post-cmd 'uwsm stop'`, mirroring
  Reboot/Shutdown, with the wipe *before* teardown (cliphist's daemon may already be gone
  after a graceful exit begins).
  **This must be recorded as "wrapped without measurement" and never summarised as a
  measurement taken.** Roadmap SC-4 asks for the measurement to be *taken*; this satisfies
  its outcome (the hazard is closed by construction) but not its letter. The hazard
  remains neither confirmed nor falsified — the same status it has held since the
  2026-07-28 waiver.
- **D-20-38:** **Open question for research, blocking D-20-37:** `hyprshutdown` exists to
  gracefully exit the compositor *before a systemd power transition*, and `uwsm stop`
  already tears the session down. The two may be redundant or may fight. Confirm the
  composition is meaningful before shipping — wrapping Logout in a mechanism that does
  nothing for it would be recorded as a fix while changing nothing.

### LEDGER-05 — the WINDOWS.md triage

- **D-20-39:** **The requirement's own count is stale.** LEDGER-05 and ROADMAP SC-6 say
  16 open rows; `.planning/WINDOWS.md` frontmatter reads `open_count: 51` (total 75) as
  of 2026-08-13. Planning must work from the live ledger, not the requirement text.
- **D-20-40:** Triage scope: **rows touching swayosd, wleave, wlogout, eww or this
  phase's surfaces are closed or re-deferred individually, with their own reason. The
  remainder is batch re-deferred as one entry with a single stated reason and a named
  owning phase.** This meets SC-6's actual bar — "none left silently open" — without
  producing 51 hand-written verdicts inside a phase already carrying two surfaces and
  three deletions.
- **D-20-41:** Sized at **phase start**, per the roadmap's own instruction — not closed in
  a rush at phase end.

### Retirement sequencing

- **D-20-42:** **Two independent GATE-02 render gates, each unlocking its own deletion.**
  OSD passes → `swayosd` goes (RETIRE-04, incl. the libinput backend per D-20-17).
  Power menu passes → `wleave` goes (RETIRE-05). `wlogout` + `eww` (RETIRE-07) ride
  whichever lands second, as the roadmap's single `pacman -Rns` covering both leftovers.
  The two halves genuinely share no backend, so a stall in one must not hold the other
  hostage — Phase 19 needed twelve gap-closure rounds on a single gate.
  — **Reversibility:** one-way — package deletion. Nothing is deleted before its own gate
  passes; this is the phase's one-way door and warrants a `checkpoint:decision`.
- **D-20-43:** GATE-01 enumerates **all three** of:
  1. **The two open questions this phase depends on** — does the SwayOSD pill render over
     hyprlock (D-20-19), and does Caps Lock indicate at the SDDM prompt (D-20-17).
     Without these, two decisions get defaulted rather than evidenced.
  2. **The full behavioural baseline** per `18-BEHAVIOUR-BASELINE.md` §
     "GATE-01 Recurrence Protocol" — swayosd's `style.css` structure, timings and anchor;
     wleave's `layout.json` actions, mnemonics and cascade; both packages' units.
  3. **The consumer sweep** — every reference across `install.sh`, `stow.sh`,
     `contract.json`, matugen config, `reload.sh`, `windowrules.lua`, `keybinds.lua`,
     `main.toml` and `ClockActionsCapsule.qml`, captured **before** deletion so the
     post-deletion zero-hit run has a baseline to be measured against. WINDOWS #1 is the
     standing precedent for what happens when this is skipped.

### Claude's Discretion

- Exact starting value for `Design.osdHideDelayMs` (SwayOSD's own default is 1000 ms).
- Exact value of the QOSD-04 recency window (D-20-08).
- Final layer-namespace strings (D-20-33 names them provisionally).
- Slider visual treatment inside the OSD column — whether to reuse the centre's slider
  component or build a lighter variant.
- The initial contents of the QPOWER-03 window-class deny-list (D-20-27 item 3).
- Whether the power dialog's scrim is a property of the dialog window or a separate
  full-screen layer.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Reference-shell behaviour (governing, per D-19-00)
- `.planning/research/FEATURES.md` § OSD — Caelestia's three-slider column and hover-hold
  vs end-4's single pill and hide-on-hover; and the explicit note that **neither reference
  has a caps-lock indicator**, so QOSD-02 is this project's own to preserve.
- `.planning/research/FEATURES.md` § POWER — Caelestia's 4-action inline popout with
  `KeyNavigation` + vim binds, end-4's 8-action full-screen grid with the `SessionWarnings`
  safety banner that QPOWER-03 is modelled on.
- `.planning/research/FEATURES.md` lines 138-141, 156-161, 171-174 — the differentiator
  and explicitly-excluded tables (8-action grid and the audio-sink protection banner are
  both listed as out of scope).

### The surfaces being replaced
- `swayosd/.config/swayosd/style.css` — the only file in the swayosd stow package; records
  that bottom-centre anchor and 64px edge margin are SwayOSD's built-in layer-shell
  behaviour, not CSS-configurable.
- `wleave/.config/wleave/layout.json` — **the sole source of the six action command
  strings and their `l/e/u/h/r/s` mnemonics.** Deleted with the package (D-20-26).
- `wleave/.config/wleave/style.css` — the six hue capsules being redesigned away.
- `hypr/.config/hypr/scripts/wleave.sh` — the launcher all three entry points call today.

### The frame being reused and extended
- `quickshell/.config/quickshell/modules/toast/Toast.qml` — its header explicitly names
  Phase 20's OSD as the intended second consumer and states chrome/content are separable
  at the type boundary. Also states the frame is never interactive — the claim D-20-03
  narrows.
- `quickshell/.config/quickshell/shell.qml` lines 103-147 — the DND toast, the existing
  `Toast` consumer whose behaviour must not change.

### Integration points that must be repointed or removed
- `hypr/.config/hypr/config/keybinds.lua:68` — `Super+Shift+Q` → `wleave.sh`.
- `hypr/.config/hypr/config/keybinds.lua:293-314` — the `locked = true` media-key binds
  routed through `swayosd-client`; these become the exec-target swap, and their
  `locked = true` flag is what QOSD-01's in-session half already rests on.
- `elephant/.config/elephant/menus/main.toml:35` — the walker menu's power entry.
- `quickshell/.config/quickshell/modules/bar/ClockActionsCapsule.qml:567-580` —
  `powerScriptPath`, `powerAvailabilityProbe`, `powerLaunchProcess`.
- `hypr/.config/hypr/config/autostart.lua:185-200` — `swayosd-server` autostart and the
  comment recording that the libinput backend is handled separately.
- `theme-engine/.config/theme-engine/contract.json:4` (`wleave.css`) and `:14`
  (`swayosd.css`) — two of the 29 contract entries; removal takes it to 27.
- `matugen/.config/matugen/config.toml:49-51` (`[templates.wleave]`) and `:79-81`
  (`[templates.swayosd]`), plus the template files they point at.
- `theme-engine/.config/theme-engine/lib/reload.sh:107-128` — the swayosd-server
  restart step in the reload fan-out.
- `theme-engine/.config/theme-engine/theme-doctor:359,361` — the two session CSS checks.
- `theme-engine/.config/theme-engine/theme-stress-test:296-314` — **`wleave.css` is a
  `REPRESENTATIVE_FILES` entry and the named representative of the `gtk-css` format.**
  Deleting it without repointing breaks the stress test; `gtk-4.0-colors.css` is already
  noted there as the second gtk-css file.
- `theme-engine/.config/theme-engine/lib/gtk.sh:311` — a comment referencing the
  wleave/swayosd sheets.
- `install.sh:190` (swayosd), `:317` (wleave), `:553-562` (the
  `systemctl enable --now swayosd-libinput-backend.service` block).
- `stow.sh:29` (swayosd), `:36` (wleave).
- `hypr/.config/hypr/config/windowrules.lua:216-292, 340-440` — wleave's three layer
  rules (blur, `animation = "fade"`, `ignore_alpha = 0.25`) and their tuning history.

### Layer-rule ordering and alpha (the known trap)
- `hypr/.config/hypr/config/windowrules.lua:368-397` — the `^quickshell-.*` family blur
  pair.
- `hypr/.config/hypr/config/windowrules.lua:441-446` — the family `ignore_alpha = 0.5`
  floor.
- `hypr/.config/hypr/config/windowrules.lua:499-526` — the worked example of per-surface
  rows declared **after** the family regex (overview's late pair, then the three Phase 19
  notification namespaces).

### Prior locked decisions this phase inherits
- `.planning/phases/19-notification-server-centre/19-CONTEXT.md` § decisions — D-19-00
  (Caelestia default), D-19-02/D-19-15 (the 430px width this phase deliberately undercuts),
  D-19-07 (dismissed popups stay in history — what makes D-20-32 lossless), D-19-14/D-19-18
  (the third frame and its no-exclusive-focus rule, which D-20-24 diverges from with cause),
  D-19-19 (the `ToggleState` singleton).
- `.planning/phases/18-qml-bar-retirement-machinery/18-BEHAVIOUR-BASELINE.md` §
  "GATE-01 Recurrence Protocol" — the protocol D-20-43 item 2 follows.

### Debt items
- `.planning/milestones/v3.0-phases/13-motion-retrofit-existing-surface-sweep/13-03-PLAN.md`
  Task 2 — the verbatim D-29
  reproduction steps. **Read to understand what is being skipped**, per D-20-37; the
  measurement is not being run.
- `.planning/WINDOWS.md` — the live ledger. Frontmatter `open_count: 51`, not the 16 the
  requirement text assumes (D-20-39). Rows 3, 4, 5, 6 are wleave-specific and in-scope for
  individual triage; rows 68, 69 carry QBAR-11's unmeasured soak.
- `.planning/REQUIREMENTS.md` lines 45-55, 68-71, 85, 88 — the thirteen requirements this
  phase owns.
- `.planning/ROADMAP.md` lines 299-324 — the phase entry, its six success criteria and its
  notes (incl. the "who owns the prompt" security carry-over from Phase 15).

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`modules/toast/Toast.qml`** — built in Phase 19 *explicitly* for this phase's reuse.
  Already carries the right chrome (`BarRoles.notifSurface`, `GradientBorder` rim,
  `Design.popoutCornerRadius`), a generic `default property alias body` content slot, a
  one-surface-replaced-in-place `show()`/`hide()` contract, and `ExclusionMode.Normal` so
  it auto-clears whichever edge the bar reserves — no bar-orientation branch needed.
- **`modules/dashboard/PanelDialog.qml`** — the frame the power menu builds on. Already
  instantiates `GradientBorder` internally (line ~191), which is why the audio/wifi/
  bluetooth panels inherit the rim without doing anything (LEDGER-01's closure).
- **`modules/dashboard/AudioBackend.qml`** and **`modules/bar/BrightnessBackend.qml`** —
  both exist and already drive the centre's sliders. D-20-05's state-driven trigger and
  D-20-09's write path both go through these; no new backend is needed for volume,
  microphone or brightness.
- **`modules/dashboard/GradientBorder.qml`** — the shared rim.
- **`modules/bar/ClockActionsCapsule.qml`'s `gamingStateFile`** (a `FileView` with
  `watchChanges: true`) — the exact shape D-20-13's sysfs watch should follow. A
  watched-file reader already exists in this codebase; do not invent a new one.

### Established Patterns
- **Zero-idle backends** — no timer or subprocess while a surface is dismissed. Constrains
  D-20-30's polling to the menu's visible lifetime.
- **Layer rules after the family regex, alpha at or above the floor** — the trap named in
  D-20-33/D-20-34, with three worked examples already in `windowrules.lua`.
- **Disabled-with-reason on hover** — the bluetooth panel's rfkill convention. Deliberately
  *not* applied to QPOWER-03 (D-20-28): the user has legitimate reason to press through.
- **Availability probes guard external scripts, not in-process surfaces** — which is why
  D-20-23 deletes the power probe rather than repointing it.
- **`REPRESENTATIVE_FILES` in `theme-stress-test` names one file per contract format** —
  so deleting a contract entry can break a checker that has nothing to do with the surface.

### Integration Points
- Three power-menu entry points (D-20-22) and the media-key binds (`keybinds.lua:297-308`)
  are the exec-target swaps.
- The reload fan-out (`reload.sh:107-128`) loses its swayosd-server restart step; QML hot-
  reloads natively, so nothing replaces it.
- `contract.json` 29 → 27 after both entries are removed. Phase 21 takes it to ~17.
- `quickshell-doctor`'s surface registry gains two namespaces (D-20-33), the GATE-03
  discipline Phase 19 established when `unregistered=3` was closed by registering the
  frames rather than exempting them.

</code_context>

<specifics>
## Specific Ideas

- **The power menu's shape was chosen from a rendered comparison**, not described in the
  abstract. The selected mockup: a centred `PanelDialog`-family frame with a "Session"
  header, a 3×2 action grid (Lock / Log Out / Suspend on the top row, Hibernate / Reboot /
  Shut Down on the bottom), a visible focus ring on the focused action, and the QPOWER-03
  warning line inside the frame beneath the grid — not floating on the scrim.
- **"Show me how it will look"** — the user asked to see the option rendered before
  committing to it. Downstream UI work should expect the same: show the surface, don't
  describe it.
- The three rejected shapes and *why* are recorded in D-20-21, so the planner does not
  re-derive them.

</specifics>

<deferred>
## Deferred Ideas

- **A real unkillable-client detector** — the mechanism that would actually characterise
  the D-29 hazard. Nothing on this stack detects it reliably. D-20-27 item 3 ships a
  bounded stand-in (a configured class deny-list surfaced as a count); a genuine detector
  is a v5.0+ question and depends on the measurement D-20-37 declines to take.
- **The D-29 teardown measurement itself** — declined again here (D-20-37), now with the
  hazard closed by construction rather than by evidence. Steps remain verbatim in
  `13-03-PLAN.md` Task 2 for whoever picks it up.
- **Caps-lock state for the second keyboard** (D-20-15) — the
  `instant-usb-gaming-mouse--keyboard` reports `capsLock` to Hyprland but has no LED node.
  Revisit only if that keyboard becomes a real input device in daily use.
- **`quickshell-doctor` sysfs-node fault injection** — a check that the caps-lock indicator
  degrades to absent (never broken) when the LED node is missing. Worth having; not scoped
  here.
- **The remaining ~35 WINDOWS.md rows** batch re-deferred under D-20-40 — each needs a
  named owning phase at triage time so the batch does not become a second silent backlog.
- **Reboot-to-firmware-settings** (end-4's 8th action) — already recorded as out of scope
  in `FEATURES.md` line 171; the six-action set stands.
- **The audio-sink protection banner** (end-4's `onSinkProtectionTriggered`) — no
  equivalent trigger exists on this audio stack; building a banner for a signal that never
  fires would be untestable scope (`FEATURES.md` line 173).

</deferred>

---

*Phase: 20-Indicators & Power Menu*
*Context gathered: 2026-08-14*
