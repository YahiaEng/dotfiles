---
slug: wifi-glyph-hover-no-popout
status: awaiting_human_verify
trigger: "HOvering over thw wifi glyph does not expand into a wifi card module"
created: 2026-08-12
updated: 2026-08-12
phase: 18-qml-bar-retirement-machinery
---

# ROOT CAUSE REPORT

**Root cause.** A `HoverHandler` declared inside a `PopoutTrigger {}` block lands in
`contentHost`, because `PopoutTrigger` declares
`default property alias content: contentHost.data`. Attaching a `HoverHandler` to an item
makes that item hover-accepting, and `contentHost` is `anchors.fill: parent` at **`z: 1`**,
stacked ABOVE `triggerMouseArea`. Qt's hover walk visits children front-to-back and stops at
the first item that accepts, so it ends at `contentHost` and never reaches the MouseArea
beneath. `triggerMouseArea.onEntered` therefore never fires, `PopoutController.entryEntered`
is never called, and no dwell ever arms. Button events still reach the MouseArea (a
`HoverHandler` handles no buttons), which is exactly why click worked and hover did not.

**Why it affected exactly two sections.** Only two triggers carry such a sibling — wifi
(`MediaConnectivityCapsule.qml:935`) and audio (`:640`), both feeding the local drawer
contract. The four that worked (media, clock, bluetooth, resources) carry none. Note the
`resources` trigger DOES nest a MouseArea (the D-25 toggle, `SystemCapsule.qml:238`) inside
its content, but that MouseArea leaves `hoverEnabled` at its default false — so it accepts
clicks without accepting hover, and the walk passes through it. That is the control case
proving the mechanism is hover ACCEPTANCE, not nesting or z-order as such.

**How it got here.** `z: 1` was introduced by `d5a9698` (18.1-02) so nested click handlers —
the D-25 format-alt toggle — would receive clicks. The hover consequence was not considered,
and the two HoverHandler siblings were added by the same phase's GATE-02 item (d).

**Fix chosen: move the trigger's hover role onto a `HoverHandler` on `triggerRoot` itself.**
Buttons stay on `triggerMouseArea` (now explicitly `hoverEnabled: false`); hover
enter/exit/move is reported by the new `triggerHoverHandler`. This is a fix in
`PopoutTrigger.qml`, so it holds for ANY future trigger whose content contains a
hover-accepting item — not a two-site patch at `:640`/`:935`.

**Why this over the alternatives (requirement 3):**
- *`blocking: false` on the drawer HoverHandlers* — rejected, and verified as a non-fix
  rather than assumed: `blocking` already defaults to false (confirmed in
  `/usr/lib/qt6/qml/QtQuick/plugins.qmltypes`, `QQuickHoverHandler`). It governs the
  handler's own accept flag; what ends the walk is the PARENT ITEM's hover acceptance, which
  attaching the handler set. Also per-site, so it fails requirement 1 regardless.
- *Bridge the drawer HoverHandler's `hovered` into `entryEntered`/`entryExited`* — rejected:
  per-site, and it would couple `PopoutTrigger` to `MediaConnectivityCapsule`'s drawer
  contract, leaving the next trigger with a hover-accepting child broken.
- *Re-parent the drawer HoverHandler out of the default content slot* — rejected: also
  per-site, and it cannot actually work generically, because `acceptHoverEvents` is set on
  `contentHost` when the handler is constructed and there is no QML-reachable way to clear it
  afterwards.
- *Drop or lower `contentHost.z`* — rejected outright: that is precisely `d5a9698`'s reason
  for existing (requirement 2). The fix does not touch `z` at all.

**Measured, not assumed.** The chosen fix rests on a measurement already in the log rather
than on reading Qt's delivery code: the instrumentation's `probeHoverHandler` was attached to
`triggerRoot` — the exact position the fix now uses — and it fired on ALL SIX sections,
**1:1** with `MA.entered` on the three where the MouseArea worked at all
(bluetooth 6/6, clock 5/5, media 4/4) and 11/10 times on wifi/audio where the MouseArea got
only its single click. That 1:1 agreement is what makes this a like-for-like replacement of
the hover source rather than a new hover contract.

# Debug: wifi glyph hover never summons the WifiPopout card

## Symptoms

**Expected:** Hovering the network/wifi glyph in the QML bar dwells briefly and then
summons the `WifiPopout` card, the same surface a click produces.

**Actual:** Hovering produces nothing. The card never appears, however long the pointer
rests on the glyph.

**Errors:** None reported by the operator. The quickshell log has not yet been read for
this gesture — reading it during a live hover is an early evidence step, not a conclusion.

**Reproduction:** Hover the network glyph on the horizontal bar. One gesture, 100%
reproducible per the operator.

**Timeline (from git, not from memory):**
- `14ba175` (18-13, tracer) — `PopoutController` summon path + audio popout.
- `edebf25` (18-13) — the hover contract itself: suppression latch, **dwell**, combined-region
  grace, pinned-ignores-hover. This is when hover-to-open was built.
- `d5a9698` (**18.1-02**, "scope amendment — z-order contentHost above triggerMouseArea") —
  the ONLY commit that ever introduced `z: 1` into `PopoutTrigger.qml`. Prime suspect by
  timeline: it postdates the working hover contract and changes pointer stacking.

## Scope already established by live operator observation — do NOT re-derive

These are answers from the human at the machine. Treat as given; spending cycles
re-confirming them is waste.

1. **Other hover drawers DO expand on hover** — launcher, settings/clock, audio. Therefore
   the shared `drawerSettled` gate is TRUE and is NOT the cause:
   `MediaConnectivityCapsule.qml:299` —
   `readonly property bool drawerSettled: QsWindow.window ? (QsWindow.window.barRendered && !QsWindow.window.barTransitionRunning) : false`
2. **Clicking the wifi glyph DOES open the card.** Therefore `PopoutController.toggle()`,
   the `LazyLoader` keyed on `PopoutController.openSection`, and `WifiPopout.qml` itself
   all work. The rendering and summon machinery is sound.

**The fault is isolated to the hover-entered dwell path that should summon a popout.**

## Key files

- `quickshell/.config/quickshell/modules/bar/PopoutTrigger.qml`
  - `triggerMouseArea`: `anchors.fill: parent`, `hoverEnabled: true`,
    `onEntered` → `publishAnchor()` + `PopoutController.entryEntered(sectionId)`,
    `onExited` → `entryExited`, `onPositionChanged` → `entryMoved`, `onClicked` → `toggle()`.
  - `contentHost`: `anchors.fill: parent`, **`z: 1`**, `default property alias content: contentHost.data`.
- `quickshell/.config/quickshell/modules/bar/PopoutController.qml` — owns dwell timing and summon.
- `quickshell/.config/quickshell/modules/bar/MediaConnectivityCapsule.qml` — the wifi trigger at
  ~line 918-936, including `connectionsTriggerHoverHandler` (a `HoverHandler`) declared as a
  sibling of the `Readout` INSIDE the `PopoutTrigger {}` block.

## Leads — structural, plausible, NOT proven

**(a) The z-order/default-alias interaction.** `PopoutTrigger` declares
`default property alias content: contentHost.data`, so everything written inside a
`PopoutTrigger {}` block lands in `contentHost` — including
`MediaConnectivityCapsule.qml`'s `connectionsTriggerHoverHandler`. `contentHost` is
`anchors.fill: parent` at `z: 1`, stacked ABOVE `triggerMouseArea`. That `z` was raised
deliberately in 18.1-02 so nested click handlers would receive clicks; the hover
consequence may not have been considered. A `HoverHandler` on the item above could be
taking the hover while button events — which a plain `Item` does not accept — still fall
through to the `MouseArea` below. That asymmetry would explain click-works / hover-fails
exactly. Note `HoverHandler.blocking` defaults to false, so this must be MEASURED, not
assumed.

**(b) Scope question that splits the hypothesis space.** Determine whether hover-to-open is
dead for ALL popout sections or ONLY wifi/connections. The wifi glyph is the only trigger
that also carries a drawer `HoverHandler` sibling — which is precisely what makes it the
suspect. If hover-to-open is dead everywhere, lead (a) is wrong and the fault is in
`PopoutController`'s dwell logic instead.

## Constraints

- **MUST NOT** run `hyprctl reload` or `hyprctl eval` — both are prohibited in this phase.
- A `quickshell` restart/reload IS permitted and expected for testing. The operator has
  explicitly accepted that it voids the running QBAR-11 soak window; the orchestrator will
  re-anchor that window afterward. Do not avoid restarting on the soak's account.
- Do not run `git stash`.

## Method requirement — this is not optional here

**Instrument first.** Phase 18.1 disproved three consecutive confident code-reading
hypotheses about this exact file family; the lesson written into that phase's own record is
"a confident code-reading hypothesis was disproven by measurement — instrument first."
Both passes that finally worked instrumented the live QML (`mapToItem`) and read real
numbers from the log. Log actual hover-callback firings from the running shell — does
`onEntered` fire at all? does `entryEntered` reach the controller? does the dwell timer
start and trigger? — and read real values before committing to a cause.

## Current Focus

bug_class: Bohrbug — 100% reproducible, deterministic, one gesture.

hypothesis: The `HoverHandler` sibling declared inside the `PopoutTrigger {}` block lands in
`contentHost` (via `default property alias content: contentHost.data`), which sits at `z: 1`
ABOVE `triggerMouseArea`. It consumes the hover stream, so `triggerMouseArea.onEntered`
never fires, so `PopoutController.entryEntered` is never called and no dwell ever arms.
Button events still reach the MouseArea below (a HoverHandler handles no buttons), which is
exactly why click works and hover does not.

test: instrument `PopoutTrigger.onEntered/onExited/onPositionChanged` and
`PopoutController.entryEntered/entryMoved/dwellTimer` with HOVPROBE logging, restart, then
hover wifi (predicted broken), audio (predicted broken — it has the same HoverHandler
sibling) and bluetooth (predicted working — no HoverHandler sibling).

expecting: for wifi/audio, ZERO `HOVPROBE MA.entered` lines while the drawer visibly
expands; for bluetooth, `MA.entered` → `ctl.entryEntered` → `dwell.restart` → `dwell.fired`
→ `popout: open`.

status_of_hypothesis: **CONFIRMED by measurement 2026-08-12 02:28** — see the decisive
differential in Evidence. The HoverHandler fires; the MouseArea beneath it is never entered
(zero MA.entered / ctl.entryEntered / dwell.restart during pure hover on wifi and audio).

next_action: operator gesture round to confirm the verification matrix — see CHECKPOINT below

reasoning_checkpoint:
  hypothesis: "A HoverHandler inside a PopoutTrigger {} block lands in contentHost (default
    property alias), makes contentHost hover-accepting, and contentHost's z: 1 puts it above
    triggerMouseArea — so Qt's front-to-back hover walk stops at contentHost and the
    MouseArea's onEntered never fires, starving PopoutController.entryEntered."
  confirming_evidence:
    - "Direct observation: ZERO MA.entered / ctl.entryEntered / dwell.restart during pure
       hover on wifi and audio, while the drawer HoverHandler on the same pixels fired."
    - "The MA.entered partition (bluetooth 6, clock 5, media 4 vs audio 1, wifi 1) is exactly
       the has-no-HoverHandler-sibling vs has-one partition."
    - "The lone audio/wifi entries are clicks, not hover: both fired with pinned=<section>,
       while every working section fired with pinned empty."
    - "Control case in the same codebase: the resources trigger nests a MouseArea (D-25) with
       hoverEnabled left false — it accepts clicks but not hover, and resources hover-opens
       normally. Nesting alone is not sufficient; hover ACCEPTANCE is."
  falsification_test: "If the mechanism were geometry perturbation rather than starvation, an
    MA.entered would appear and then be cancelled by an immediate MA.exited. There is no
    MA.entered at all to cancel — measured. Conversely, if the fix's premise were wrong, a
    HoverHandler on triggerRoot would also have been starved; it was not, on any section."
  fix_rationale: "Moves the hover SOURCE to the one position measured to receive hover on all
    six sections (triggerRoot), leaving the click source and contentHost's z: 1 untouched. It
    addresses the starvation itself in PopoutTrigger.qml, so it holds for any future trigger
    whose content contains a hover-accepting item — not the two known sites only."
  blind_spots:
    - "pointChanged is proven to EXIST on HoverHandler (inherited from
       QQuickSinglePointHandler; a non-existent handler would have failed the QML load, and
       the load is clean). That it FIRES on hover motion is inferred from
       QQuickSinglePointHandler emitting it per processed event — untested until the gesture
       round. If it does not fire, pointerMovedSinceSettle never arms and NO section
       hover-opens; that failure mode is loud and unmistakable in the matrix below."
    - "Click behaviour is unchanged by inspection (z untouched, acceptedButtons untouched)
       but not yet re-measured on hardware."
    - "The ~300-460ms HoverHandler flapping is untouched and could, in principle, interact
       with the 400ms dwell on wifi/audio. See Known Debt."
  candidate_causes:
    - "code: hover-accepting item inside contentHost ends the delivery walk above the
       MouseArea (CONFIRMED)"
    - "config: z-order value in PopoutTrigger.qml raised by 18.1-02 (CONTRIBUTING — necessary
       condition, but deliberately correct for clicks and therefore not the thing to revert)"
    - "environment: Qt/Hyprland hover delivery differences — ruled out, four sections deliver
       hover correctly in the same process"
    - "data: n/a — no data path involved"
  and_gate: "yes, two conditions AND together: (1) contentHost stacks above triggerMouseArea
    (z: 1, from d5a9698) AND (2) the wrapped content contains a hover-ACCEPTING item. Neither
    alone breaks hover — proven both ways by cases already in the tree: the four sections have
    (1) without (2) and work, and the resources trigger has (1) plus a nested but
    hover-DECLINING MouseArea and works. Only wifi and audio have both. This is why the fix
    changes the hover source rather than either condition."

## Evidence

- timestamp: 2026-08-12 (source read)
  checked: `MediaConnectivityCapsule.qml` — every `PopoutTrigger {}` block and its children
  found: The debug file's own premise "the wifi trigger is the ONLY one carrying a drawer
    HoverHandler sibling inside its PopoutTrigger block" is FALSE. `audioPopoutTrigger`
    (line 572) carries `audioTriggerHoverHandler` (line 638) in exactly the same position.
    Two triggers have a HoverHandler sibling — audio and wifi. Four do not — media (220),
    bluetooth (886), clock (ClockActionsCapsule:88), resources (SystemCapsule:297).
  implication: Lead (a) is now a DIFFERENTIAL prediction, not a wifi-only story: if the
    HoverHandler is the thief, audio's hover-to-popout must be broken too and the other four
    must work. That is a falsifiable split.

- timestamp: 2026-08-12 (runtime discovery)
  checked: where QML `console.log` actually lands — the journal was empty
  found: `quickshell-launch.sh:81` execs `quickshell >>"$HOME/.cache/quickshell.log" 2>&1`,
    so NOTHING reaches `journalctl --user -u quickshell.service` except systemd's own unit
    lines. The live per-instance log is
    `/run/user/1000/quickshell/by-id/6913klmjt/log.log`, plus the cross-run
    `~/.cache/quickshell.log`.
  implication: The brief's suggested `journalctl` read would have returned an empty result
    and looked like "the callbacks never fire". Read the runtime log file instead.

- timestamp: 2026-08-12 (LIVE LOG — passive, no restart, answers lead (b) outright)
  checked: every `popout:` line in the running instance's log (session started 01:09:39)
  found: `popout: preview armed` fires (01:11:30) — the D-18-19 latch IS armed, so the
    suppression latch is NOT the cause. Six hover-opens are recorded, each an `open` with NO
    following `pin` (a click always logs `open` then `pin`, because `toggle`→`pin`→`open`):
      01:30:39 open clock      (no pin) → HOVER
      01:30:40 open clock      (no pin) → HOVER
      01:30:44 open bluetooth  (no pin) → HOVER
      01:30:59 open media      (no pin) → HOVER
      01:31:07 open resources  (no pin) → HOVER
      01:31:39 open clock      (no pin) → HOVER
    Wifi appears exactly once, WITH a pin: `01:35:15 open section=wifi` + `pin section=wifi`
    → a CLICK. Audio never appears at all, by either path.
  implication: **Lead (b) is resolved: hover-to-open is NOT globally dead.** It works for
    clock, bluetooth, media and resources. The dwell logic in `PopoutController` is sound.
    The fault is specific to wifi. And the partition of working vs non-working sections is
    EXACTLY the partition of "has no HoverHandler sibling" vs "has a HoverHandler sibling" —
    the four that hover-open are the four without one; the two with one (wifi, audio) have
    never hover-opened in this session. Lead (a) is strongly supported; it is not yet proven,
    because audio's absence could just be untested rather than broken.

- timestamp: 2026-08-12 01:44 (instrumented, instance rst438nmjt)
  checked: HOVPROBE geometry probe on all six triggers, logged 2.5s after load
  found: every trigger has non-zero size and `hoverEnabled=true`. Scene coords (bar layer
    is at screen 10,6 per `hyprctl layers`, so screen = scene + (10,6)):
      resources  scene 40.0,11.0    80.0x20.0
      media      scene 2025.0,11.0  209.0x20.0
      bluetooth  scene 2014.2,11.0  10.8x20.0   (collapsed-strip park position)
      audio      scene 2250.0,11.0  12.8x20.0
      wifi       scene 2278.8,11.0  14.8x20.0
      clock      scene 2309.7,7.0   82.3x28.0
  implication: The wifi trigger is NOT zero-sized and its MouseArea is NOT hover-disabled —
    two cheap alternative explanations ruled out before spending the operator's gesture.
    Bluetooth is unusable as a control (it is parked inside the collapsed strip), so CLOCK
    is the positive control instead — it has three recorded hover-opens.

- timestamp: 2026-08-12 02:28 (OPERATOR GESTURES PERFORMED — decisive differential)
  checked: `HOVPROBE MA.entered` counts per section in instance rst438nmjt's log, plus the
    `dwell.fired` / `pinned` state at each firing
  found: `MA.entered` counts split EXACTLY along the HoverHandler-sibling partition:
      bluetooth 6, clock 5, media 4   ← the sections WITHOUT a HoverHandler sibling
      audio 1,    wifi 1              ← the sections WITH a HoverHandler sibling
    and the lone audio/wifi entries are NOT hover — they are the click gestures, proven by
    the pinned state at dwell time:
      dwell.fired hovered=audio armed=true pinned=audio
      dwell.fired hovered=wifi  armed=true pinned=wifi
    versus the working sections, which fired with pinned EMPTY:
      dwell.fired hovered=bluetooth armed=true pinned=
      dwell.fired hovered=clock     armed=true pinned=   (x2)
      dwell.fired hovered=media     armed=true pinned=
    Timing corroborates: MA.entered audio 02:28:25.509 → open+pin audio 02:28:25.656;
    drawer.conn entered=true 02:28:30.565 → open+pin wifi 02:28:30.957.

    During the PURE HOVER phases on wifi the ONLY events are the HoverHandler's:
      02:28:30.565 drawer.conn source=trigger entered=true  / root.hover section=wifi hovered=true
      02:28:31.025 drawer.conn source=trigger entered=false / root.hover section=wifi hovered=false
      02:28:31.412 drawer.conn source=trigger entered=true  / root.hover section=wifi hovered=true
      02:28:31.711 drawer.conn source=trigger entered=false / root.hover section=wifi hovered=false
    ZERO `MA.entered`, ZERO `ctl.entryEntered`, ZERO `dwell.restart`.

    Working-section control (media), clean chain:
      02:28:17.478 MA.entered → ctl.entryEntered id=media pinned='' armed=true barSettled=true
      moved=true → dwell.restart → 02:28:17.879 dwell.fired → 02:28:17.881 popout: open section=media
  implication: **Lead (a) is PROVEN.** The `HoverHandler` fires; the `MouseArea` beneath it is
    never entered. This is the predicted starvation signature, and it also KILLS the competing
    explanation ("MA.entered followed by an immediate MA.exited from drawer-expansion geometry
    perturbation") — there is no `MA.entered` to be cancelled in the first place.

- timestamp: 2026-08-12 02:28 (secondary observation — do NOT spend another gesture round)
  checked: `drawer.conn` entered=true/false transitions during stationary-cursor hover
  found: the HoverHandler flaps entered=true/false on a ~300-460ms period on both wifi and
    audio (`drawer.conn` logged 32 times total) under a stationary cursor — consistent with the
    drawer expanding and shifting geometry beneath the pointer.
  implication: A real annoyance, but DOWNSTREAM of the starvation, not its cause. Record it;
    do not let it expand this session's scope.

- timestamp: 2026-08-12 02:35 (fix-selection evidence — no new gesture spent)
  checked: `HOVPROBE root.hover` counts per section in instance rst438nmjt's log — the probe
    HoverHandler attached to `triggerRoot`, which is the EXACT position the fix uses
  found: it fired on ALL SIX sections, and 1:1 with `MA.entered` wherever the MouseArea
    worked at all:
      bluetooth  6 root.hover / 6 MA.entered
      clock      5 / 5
      media      4 / 4
      audio     10 / 1   (MouseArea starved; only the click got through)
      wifi      11 / 1   (MouseArea starved; only the click got through)
  implication: A HoverHandler on `triggerRoot` is a measured like-for-like replacement for the
    MouseArea's hover on the working sections AND is delivered on the two broken ones. This is
    what selects the fix — the decision rests on measurement already in hand, not on reading
    Qt's delivery code, and it cost no extra operator gesture.

- timestamp: 2026-08-12 02:36 (control case — source, decisive for the AND-gate)
  checked: `SystemCapsule.qml:238` — the D-25 format-alt MouseArea nested inside
    `resourcesPopoutTrigger`'s content
  found: it sets `enabled` and `visible` but leaves `hoverEnabled` at its default FALSE, and
    the `resources` section hover-opens normally (`01:31:07 open resources`, no pin).
  implication: Nesting an interactive item inside `contentHost` does NOT break hover; only a
    hover-ACCEPTING item does. This is the in-tree control that makes the mechanism specific
    rather than a general "z: 1 broke pointer input" story — and it is why the fix must not
    touch `z`.

## Eliminated

- hypothesis: "the shared drawerSettled gate is false, so no drawer/popout can open"
  evidence: operator confirms launcher, settings/clock and audio hover drawers all expand normally
- hypothesis: "PopoutController.toggle / LazyLoader / WifiPopout.qml are broken"
  evidence: operator confirms clicking the same wifi glyph opens the card correctly

## Known Debt — recorded, deliberately NOT fixed in this session

- **HoverHandler flapping on the drawer triggers (~300-460ms period).** Measured 2026-08-12
  02:28: `drawer.conn` / `drawer.audio` log `entered=true`/`entered=false` transitions on a
  ~300-460ms cycle under a STATIONARY cursor (32 transitions in one gesture round), on both
  wifi and audio — consistent with the drawer expanding, shifting geometry beneath the
  pointer, un-hovering the trigger, collapsing, and repeating. It is downstream of the hover
  starvation, not its cause, and is explicitly out of this session's scope.
  **Why it matters later:** the flap period straddles `Design.popoutDwellMs` (400ms), so once
  hover delivery is restored the flap could intermittently cancel a dwell on exactly these two
  sections. If the gesture round shows wifi/audio hover-opening only sometimes, this is the
  first suspect — and it is a SEPARATE bug from the one fixed here.
  Likely shape of a future fix: the trigger's hover region must not be invalidated by the
  drawer's own expansion (a stable combined region, as D-18-21 already does for entry+popout).

## Resolution

root_cause: A `HoverHandler` written inside a `PopoutTrigger {}` block is placed into
  `contentHost` by `default property alias content: contentHost.data`; attaching it makes
  `contentHost` hover-accepting, and `contentHost` sits at `z: 1` above `triggerMouseArea`, so
  Qt's front-to-back hover walk stops there and never reaches the MouseArea.
  `triggerMouseArea.onEntered` therefore never fires and `PopoutController.entryEntered` is
  never called, so no dwell arms. Buttons still reach the MouseArea (a HoverHandler handles no
  buttons) — hence click worked and hover did not. Two AND-ed conditions were required: the
  z-order from `d5a9698` AND a hover-accepting item in the wrapped content; only wifi
  (`MediaConnectivityCapsule.qml:935`) and audio (`:640`) had both.

fix: In `PopoutTrigger.qml` — a general fix, not a per-site one. The trigger's hover role
  moved off `triggerMouseArea` onto a new `HoverHandler` (`triggerHoverHandler`) attached to
  `triggerRoot` itself, the one position measured to receive hover on all six sections.
  `onHoveredChanged` drives `publishAnchor()` + `entryEntered`/`entryExited`; `onPointChanged`
  (guarded on `hovered`) drives `entryMoved`, replacing `MouseArea.onPositionChanged` as the
  pointer-move report that arms D-18-19's suppression latch. `triggerMouseArea` keeps
  `acceptedButtons: Qt.LeftButton` and `onClicked` unchanged and is now explicitly
  `hoverEnabled: false`. `contentHost.z: 1` is untouched, so `d5a9698`'s reason for it (the
  D-25 format-alt nested click) is structurally preserved. A comment at the handler records
  the measurement, both rejected non-fixes (`blocking: false`, dropping `z`), and an explicit
  do-not-move-this-back instruction.

verification:
  - HOVPROBE instrumentation gate: `grep -rn HOVPROBE quickshell/` returns nothing. PASS
    (the instrumentation in PopoutController.qml and MediaConnectivityCapsule.qml was never
    committed, so its removal restores those two files byte-identical to HEAD — `git status`
    shows PopoutTrigger.qml as the only modified file).
  - QML load after `systemctl --user restart quickshell.service`: clean. "Configuration
    Loaded", `bar: visibility=visible zone=reserved`, zero errors/warnings. This also proves
    `onHoveredChanged` and `onPointChanged` are valid signals on `HoverHandler` — an invalid
    handler name is a load-time QML error, not a silent no-op. PASS
  - `HoverHandler.point` / `pointChanged` confirmed to exist by type metadata
    (`/usr/lib/qt6/qml/QtQuick/plugins.qmltypes`: `QQuickSinglePointHandler` declares
    `point` with `notify: pointChanged`; `QQuickHoverHandler` has it as prototype). PASS
  - `blocking` confirmed to default false in the same metadata, so the "set blocking: false"
    direction is a verified non-fix rather than an assumed one. PASS
  - Behavioural matrix (hover-opens on all six, click-opens, D-25 nested click): PENDING —
    requires operator gestures. The agent cannot move the physical pointer:
    `hyprctl dispatch movecursor` was attempted and Hyprland 0.56.2's new Lua dispatch form
    rejects it, and the remaining `hl.dsp.*` route is compositor Lua evaluation, i.e. the
    prohibited `hyprctl eval` in another spelling. `wtype` is keyboard-only, so clicks are
    unreachable regardless. NOT claimed as verified.

files_changed:
  - quickshell/.config/quickshell/modules/bar/PopoutTrigger.qml (the fix)
  - quickshell/.config/quickshell/modules/bar/PopoutController.qml (instrumentation removed,
    now byte-identical to HEAD)
  - quickshell/.config/quickshell/modules/bar/MediaConnectivityCapsule.qml (instrumentation
    removed, now byte-identical to HEAD)
