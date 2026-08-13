# Phase 19: Notification Server & Centre - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-08-13
**Phase:** 19-notification-server-centre
**Areas discussed:** Popup placement & lifetime, Centre shape & summon, History/grouping/clearing, Suppression rules & the bluetooth prompt, swaync retirement sequencing, Theming the new surfaces, LEDGER-07, LEDGER-08

---

## Governing instruction issued mid-discussion

Partway through the second area the user said: *"I want you to prioritize what
caelestia shell does for every design decision. Keep it as a strong deciding
factor."* — after twice asking "what does caelestia/end4 do?" about decisions
where the options had not been annotated with reference-shell behaviour.

Effects on this session:
1. Captured as **D-19-00** in CONTEXT.md.
2. Saved to persistent memory (`reference-shell-bias`), sharpening the standing
   v3.0 bias from a tie-breaker into a leading prior with Caelestia above end-4.
3. **Four already-answered popup decisions were re-opened and reversed** — see the
   Reversals table below.
4. Every subsequent option was annotated with what Caelestia actually does, verified
   against its real source rather than from memory.

### Reversals after the instruction

| Decision | First answer | Final answer |
|---|---|---|
| Card expand | Hover-to-expand | Vertical drag past threshold (Caelestia) |
| Swipe | Right = dismiss, left = delete from history | Either direction dismisses, middle-click closes, nothing destructive (Caelestia) |
| Stack depth | Cap at 3 with "+N more" | Height clamp (Caelestia) **and** "+N more" when it truncates |
| Critical urgency | Error accent only | Whole card takes the error scheme (Caelestia) |

A fifth reversal happened *before* the instruction, on the user's own initiative:
the popup anchor was answered "always top-right", changed to "follows the bar's
edge", then changed back to "always top-right", which is final.

### Corrections made during the session

- I claimed an empty-state illustration "can't be retinted by matugen". **Wrong.**
  Caelestia's `Colouriser` is a 12-line wrapper around `QtQuick.Effects.MultiEffect`,
  and that module is installed on this host with `colorization`/`colorizationColor`.
  The real trade-off is only that the tint is a single flat colour (silhouette) plus
  one image asset in the repo. The user chose full Caelestia parity once corrected.

---

## Popup placement & lifetime

| Option | Description | Selected |
|--------|-------------|----------|
| Always top-right, clear of the bar | One geometry, margin shifts per bar edge | ✓ |
| Follows the bar's edge | Second layout to keep in step — the D-18-13 fork | |
| Top-centre under the bar | Breaks from both references | |

**User's choice:** Always top-right (after briefly selecting the edge-following variant and reverting).

| Option | Description | Selected |
|--------|-------------|----------|
| Cap at 3, overflow silently | | |
| Cap at 3 with "+N more" card | | (superseded) |
| Cap at 5 | | |
| *(re-asked)* Height clamp only — Caelestia | Stack stops before overlapping another surface | |
| *(re-asked)* Height clamp **and** "+N more" | Adaptive limit plus overflow honesty | ✓ |

| Option | Description | Selected |
|--------|-------------|----------|
| Match swaync exactly (5s / 3s low / critical never) | No change to daily rhythm on migration day | ✓ |
| Honour app `expire_timeout`, fall back to 5s | More spec-correct, changes some apps' behaviour | |
| Longer: 8s / 4s / never | | |

| Option | Description | Selected |
|--------|-------------|----------|
| swaync-parity full card | | |
| Compact by default, expand on hover | | (superseded) |
| Icon+title+body only, actions in the centre | Would weaken QNOTIF-04 | |
| *(re-asked)* Vertical drag to expand — Caelestia | Hover keeps only the timer-pause job | ✓ |

| Option | Description | Selected |
|--------|-------------|----------|
| Pause while hovered, resume on leave | What Caelestia does | ✓ |
| Reset the full timer on leave | | |
| Cancel the timer — sticky once hovered | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Right = dismiss, kept in history | | |
| Right = dismiss, left = delete from history | | (superseded) |
| *(re-asked)* Either direction dismisses + middle-click closes — Caelestia | No destructive gesture; deletion lives in the centre | ✓ |

| Option | Description | Selected |
|--------|-------------|----------|
| Update in place, restart timer, no re-animation | What QNOTIF-05 asks for; fixture will assert it | ✓ |
| Update in place, keep the original timer | Card vanishes mid-download | |
| Update in place, re-animate to top | Fights QNOTIF-02's smooth reflow | |

| Option | Description | Selected |
|--------|-------------|----------|
| Default action if present, else dismiss | Spec behaviour; what swaync does | ✓ |
| Always dismiss | Throws away the most-used interaction | |
| Open the centre | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Error accent + persistent only | | (superseded) |
| Accent + persistent + always expanded | | |
| Accent + persistent + exempt from the cap | Abusable by apps marking everything critical | |
| *(re-asked)* Whole card takes the error scheme — Caelestia | Still inside the clamp, no exemption | ✓ |

| Option | Description | Selected |
|--------|-------------|----------|
| image → named icon → desktop-entry → generic bell glyph | Never a blank slot, never two card widths | ✓ |
| … → letter avatar in a tinted circle | Needs a deterministic in-palette colour pick | |
| … → no icon, text-only reflow | Two card shapes | |

| Option | Description | Selected |
|--------|-------------|----------|
| Slide + fade from the anchored edge, timings from `Motion.qml` | | ✓ |
| Fade + scale from 96% | | |
| Slide only, no fade | Reads mechanical next to the rest of the shell | |

| Option (multi-select) | Description | Selected |
|--------|-------------|----------|
| Ring progress over the icon on `hints.value` | Caelestia | ✓ |
| Markdown body + clickable hyperlinks | Caelestia; needs `body-markup` in GetCapabilities | ✓ |
| Always-present "copy body" action | Caelestia | ✓ |

**Notes:** Popup width was not asked directly — it followed from the centre-size
answer, since Caelestia deliberately sets `sizes.notifs.width` and
`sizes.sidebar.width` to the same 430.

---

## Centre shape & summon

| Option | Description | Selected |
|--------|-------------|----------|
| Own right-edge slide-out `PanelWindow` — Caelestia `modules/sidebar/` | Third top-level frame; GATE-03/GATE-04 cost | ✓ |
| Fifth tab in the dashboard `PanelDialog` | Zero new frames, but a centred dialog isn't a slide-out | |
| Reuse the bar's `SectionPopout` | Built for small glance surfaces | |

| Option | Description | Selected |
|--------|-------------|----------|
| Bell click + `Super+N`, both toggling | Repoints D-18-33 and the existing keybind | ✓ |
| Bell only | Deletes `Super+N` rather than repointing it | |
| Bell + `Super+N` + the "+N more" card | Third summon path to keep consistent | |

| Option | Description | Selected |
|--------|-------------|----------|
| swaync's order: header → toggles → sliders → history | Zero change in reach | |
| Header → history → toggles + sliders pinned bottom | History gets the top and the space | ✓ |
| swaync's order with collapsible controls | Extra state to persist | |

| Option | Description | Selected |
|--------|-------------|----------|
| 430px, full height, matching popup width — Caelestia | Verified in `tokens.hpp` + `modules/sidebar/Wrapper.qml` | ✓ |
| 460px, full height minus gaps — end-4 | Verified in `Appearance.qml` + `SidebarRight.qml` | |
| Keep swaync's 420px | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Badge counts unread; opening the centre clears it | Caelestia + end-4 | ✓ |
| Badge counts total history | Permanently-lit bell | |
| Unread, cleared on dismiss or on open | A burst-swipe silently marks things read | |

| Option | Description | Selected |
|--------|-------------|----------|
| No exclusive focus; Escape closes | Matches the drawer, the popouts, and Caelestia's sidebar | ✓ |
| Exclusive focus with arrow-key navigation | Caelestia reserves this for its session screen | |
| OnDemand focus | Extra state when debugging focus | |

| Option | Description | Selected |
|--------|-------------|----------|
| One singleton backend, both grids are pure views | Drift structurally impossible (QNOTIF-07) | ✓ |
| Shared component, state from the shell root | Root grows a pile of toggle properties | |
| Shared component, each instance reads services | The drift the roadmap wants to end | |

| Option | Description | Selected |
|--------|-------------|----------|
| Reuse `AudioBackend` + `BrightnessBackend` as-is | | |
| Reuse both **and** add a mic slider — Caelestia's OSD trio | Beyond QNOTIF-08's literal wording | ✓ |

| Option | Description | Selected |
|--------|-------------|----------|
| Illustration + "All up to date!", tinted via MultiEffect — full Caelestia | One image asset; tints to a flat silhouette | ✓ |
| Material Symbols glyph + same text | No asset to ship | |
| Nothing at all | Reads as broken | |

| Option | Description | Selected |
|--------|-------------|----------|
| Slide + fade from off-screen right, one `offsetScale` property — Caelestia | Position and fade locked together; stops rendering when closed | ✓ |
| Fade only | Not a slide-out | |
| Slide + fade with overshoot | Feels loose on a surface opened dozens of times a day | |

**Notes:** The mic slider was flagged in its own option text as beyond QNOTIF-08's
literal wording; the user selected it anyway, so it is recorded in CONTEXT.md as a
deliberate scope note rather than silently folded in. Verified cheap afterwards —
`AudioBackend.qml` already exposes the input side.

---

## History, grouping & clearing

| Option | Description | Selected |
|--------|-------------|----------|
| Serialize to JSON, reload on start — both references | Survives hot reloads and QBAR-10 restarts | ✓ |
| In-memory only | Every hot reload wipes unread history | |
| Persist but drop anything older than a day | No age pruning in either reference | |

| Option | Description | Selected |
|--------|-------------|----------|
| Grouped per app, collapsed by default, count + chevron — Caelestia `NotifGroup` | | ✓ |
| One flat list, newest first | Neither reference does this | |
| Grouped per app, expanded by default | Loses the at-a-glance overview | |

| Option | Description | Selected |
|--------|-------------|----------|
| Most-recent activity per group, newest at top — end-4 `latestTimeForApp` | | ✓ |
| Alphabetical | end-4 explicitly rejected it | |
| Critical groups pinned first | Second sort key, abusable | |

| Option | Description | Selected |
|--------|-------------|----------|
| Icon button in the header, appears when count > 0 | Caelestia's icon + animation, moved out of the footer's way | ✓ |
| Floating bottom-right FAB — full Caelestia placement | Collides with the pinned controls footer | |
| Text "Clear All" button — what swaync has | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Per-notification + per-app-group + clear-all — Caelestia | Copy its 30-at-a-time batching | ✓ |
| Per-notification + clear-all only | | |
| Clear-all only | | |

| Option | Description | Selected |
|--------|-------------|----------|
| Cap at ~100, oldest dropped | Named divergence — Caelestia has no cap | ✓ |
| No cap — full Caelestia parity | Unbounded file rewritten on every change | |
| Cap per app group | Total still grows with app count | |

| Option | Description | Selected |
|--------|-------------|----------|
| Hide actions once the sender's session is gone | Named divergence — keeps QNOTIF-04 literal | ✓ |
| Keep them; invoking a dead one is a no-op — Caelestia | Looks like a broken server | |
| Keep them, show a "sender gone" state | Rarely-seen failure UI | |

| Option | Description | Selected |
|--------|-------------|----------|
| Relative, live-updating — Caelestia and swaync today | One shared ticker, per QBAR-11 | ✓ |
| Relative on the group header, absolute per card | | |
| Absolute clock time everywhere | Zero timers, but you do the arithmetic | |

| Option | Description | Selected |
|--------|-------------|----------|
| `~/.local/state/quickshell/notifications.json` | XDG state; outside the stow tree | ✓ |
| `~/.cache/…` | Cache cleaners would wipe it | |
| `~/.local/share/…` | Also defensible; `share` fits documents better | |

---

## Suppression rules & the bluetooth prompt

| Option | Description | Selected |
|--------|-------------|----------|
| Never shown as a popup, always recorded in history | Both references separate interruption from record | ✓ |
| Suppressed and dropped entirely under DND | No trace at all, with no rollback | |
| Suppressed then replayed when the condition clears | Burst of stale popups | |

| Option | Description | Selected |
|--------|-------------|----------|
| Fully suppress under a focused fullscreen client | QNOTIF-10's plain wording; matches the gaming tooltip | ✓ |
| Shorten the timeout — Caelestia's `fullscreenExpireTimeout` | | |
| Suppress except critical | Hole any app can drive | |

| Option | Description | Selected |
|--------|-------------|----------|
| Independent toggles, either suppresses — both references' OR-shape | | ✓ |
| Gaming mode flips DND on and off | Would clear a deliberately-set DND | |
| Drop the DND tile | QNOTIF-09 forbids it | |

| Option | Description | Selected |
|--------|-------------|----------|
| Persist in the shell state file + toast on change — Caelestia | Toast is the only feedback for a `Super+N` toggle | ✓ |
| Persist, no toast | | |
| Separate file for toggle state | One more path for install.sh and the doctor | |

| Option | Description | Selected |
|--------|-------------|----------|
| Declare capabilities; pairing renders as a normal actioned popup | The deferred item's cheap path; no bluetooth code in the server | ✓ |
| Also route the confirmation into the Bluetooth panel | Couples the server to one app | |
| Build an `org.bluez.Agent1` agent | Explicitly rejected as the expensive path | |

| Option | Description | Selected |
|--------|-------------|----------|
| `body`, `body-markup`, `body-hyperlinks`, `actions`, `icon-static`, `persistence` | Caelestia's set; `body`+`actions` load-bearing for blueman | ✓ |
| Minimum: `body`, `actions`, `icon-static` | Apps wouldn't send the Markdown just decided on | |
| Caelestia's set + `action-icons` + `sound` | Claiming unimplemented capabilities is worse than not claiming | |

| Option | Description | Selected |
|--------|-------------|----------|
| Clear the in-flight stack immediately on centre-open / DND-on | end-4's `timeoutAll()`; Caelestia suppresses on sidebar-open | ✓ |
| Let in-flight popups finish their timer | Popups overlapping the centre | |
| Different rule per condition | Two behaviours to remember | |

| Option | Description | Selected |
|--------|-------------|----------|
| Re-point the poisoned fixture, run live, plus kill-and-respawn | What the roadmap already requires | ✓ |
| Also make it a standing `quickshell-doctor` check | Live `busctl` call on every doctor run | |

| Option | Description | Selected |
|--------|-------------|----------|
| Allowlist markup subset, strip the rest, confirm before opening a link | Named divergence from Caelestia | ✓ |
| Full Caelestia parity — render markup, open links on click | Unconfirmed open of a sender-chosen URL | |
| Links copy to clipboard instead of opening | Loses the point of hyperlinks | |

---

## swaync retirement sequencing

| Option | Description | Selected |
|--------|-------------|----------|
| Server + centre ship, GATE-02 passes, then one deletion plan | Autostart swap is one atomic edit inside it | ✓ |
| Delete as soon as the bus name is owned, gate after | Deletes the comparison before the gate judges | |
| Deletion split per surface across plans | Checklist's before/after has no anchor | |

---

## Theming the new surfaces

| Option | Description | Selected |
|--------|-------------|----------|
| `BarRoles` rows extended with notification roles | 18.1 D-04/D-24; no matugen template needed at all | ✓ |
| Read `Colours.qml` directly like the dashboard panels | Would drift from the bar it sits beside | |
| Keep a matugen template for the new surfaces | Pointless — QML hot-reloads natively | |

| Option | Description | Selected |
|--------|-------------|----------|
| Drop `swaync.css` from `REPRESENTATIVE_FILES`, add nothing | Remaining four still cover every format | ✓ |
| Drop it and add a `Colours.qml` representative | Different artefact class; needs a parser branch | |

---

## LEDGER-07 — theme-stress-test clean run

| Option | Description | Selected |
|--------|-------------|----------|
| Move `current.jpg` into `~/.local/state/theme/`, repoint consumers | Runtime state doesn't belong in the stow tree | ✓ |
| Keep the path, `.gitignore` it | Leaves state in the stow tree for Phase 22 to excuse | |
| Make the stress test tolerate the dirty file | Weakens the check LEDGER-07 exists to make trustworthy | |

**Notes:** Verified during discussion that `WALLPAPER_DIR` is
`$HOME/Pictures/Wallpapers` (`lib/wallpaper.sh:14`), stow-managed from the tracked
`wallpapers/` tree, and that there are **three** `ln -sfr … current.jpg` call sites
(lines 242, 263, 336) — not the single `:65` the requirement text cites. That line
reference is stale.

---

## LEDGER-08 — panel-family security review

| Option | Description | Selected |
|--------|-------------|----------|
| Panel family **plus** the new D-Bus attack surface | Any session process can now send data that renders in the shell | ✓ |
| Strictly Phase 15's named gaps + the verifier re-run | Tightest scope; leaves the server's untrusted input unreviewed | |

---

## Claude's Discretion

- Exact px values for the drag thresholds, ring-progress stroke, and header/footer
  paddings — to come from `Motion.qml` / `Design.qml` tokens and the bar's existing
  capsule metrics.
- The specific empty-state illustration asset and its source.
- Which of the LEDGER-04 debug sessions resolve versus take a reasoned deferral —
  only the bluetooth one has its path fixed here. The live count needs verifying:
  one of the six (GradientBorder) was already closed by LEDGER-01 in Phase 18, and
  `.planning/debug/` currently shows five open files.

## Deferred Ideas

- Routing the bluetooth pairing confirmation into the Bluetooth panel (G-15-7's
  original ask) — possible via per-notification `actions` + `invoke`, declined
  because it couples the server to one app.
- An `org.bluez.Agent1` D-Bus agent — recorded as considered and rejected.
- A caps-lock / OSD indicator surface — Phase 20 owns it.
- Making the two-owner check a standing `quickshell-doctor` check on every run.
- A `Colours.qml` representative in `theme-stress-test`.
