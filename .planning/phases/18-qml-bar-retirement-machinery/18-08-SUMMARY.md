---
phase: 18-qml-bar-retirement-machinery
plan: 08
subsystem: ui
tags: [quickshell, qml, mpris, pipewire, upower, networkmanager, bluez, wlr-layer-shell]

# Dependency graph
requires:
  - phase: 18-05
    provides: "BarCapsule shared chrome, SystemCapsule.qml/MediaConnectivityCapsule.qml empty slots, five backend handles threaded through BarCapsule, BarEntryModel's entry list and three requiresResources/requiresMedia/requiresAudio aggregates"
provides:
  - "SystemCapsule.qml filled — cpu/ram/disk from SystemResources, an updates entry with its own 30-minute checkupdates reader and click-to-upgrade action"
  - "MediaConnectivityCapsule.qml filled — media/audio/network/bluetooth/battery from the four inherited backend handles plus native UPower"
  - "MediaBackend.qml repointed onto Quickshell.Services.Mpris (D-18-05) — public surface unchanged, MediaTab.qml/Dashboard.qml/shell.qml byte-unchanged"
  - "Design.qml + mediaTitleMaxChars (30)"
  - "18-BAR-LIVENESS-CHARGE.md — the measured, per-backend always-on cost and 18-18's soak brief"
affects: [18-09, 18-10, 18-11, 18-12, 18-13, 18-14, 18-18, 18-19]

actuals:
  tokens: 18773
  tasks: 5
  commits: 6

tech-stack:
  added: []
  patterns:
    - "One reusable inline `component Readout: Item { ... }` per capsule file, declared once and instantiated per entry — glyph + Design.spacingXs gap + right-aligned width-reserved value, one bound Grid (never a Row/Column pair) for the horizontal/vertical swap. Declared separately (not shared cross-file) in both SystemCapsule.qml and MediaConnectivityCapsule.qml since QML has no cross-file import for an unregistered inline type; both declarations are kept to the identical visual geometry deliberately, recorded so a later reader does not read the duplication as drift."
    - "Opacity-graded glyph over a fixed ligature name (network's signal-strength bucket) rather than swapping to a per-bar-count icon name — copied directly from WifiPanel.qml's own strengthGlyph() idiom rather than re-invented."
    - "Multi-state entries that share one glyph across several backend states, differentiated by text elsewhere (bluetooth's no-adapter/blocked/off all render bluetooth_disabled; network's blocked/off both render wifi_off) — copied directly from BluetoothPanel.qml's and WifiPanel.qml's own established branch conventions rather than inventing new glyphs the installed font may not ship."
    - "A local one-shot backend (the updates poll) living inside a bar capsule component rather than as a new modules/dashboard/ type, specifically because shell.qml is frozen for wave 3 and a new backend type would need a qmldir registration plus a shell.qml mount to reach it."
    - "A Timer-forced heartbeat property read (positionSeconds) to force a QML binding to re-evaluate a property whose change notification is not guaranteed to fire every tick, without inventing an unverified refresh() method call — the binding reads a bare property (positionSeconds) but depends on a ticking counter so it re-evaluates on a fixed cadence."

key-files:
  created:
    - .planning/phases/18-qml-bar-retirement-machinery/18-BAR-LIVENESS-CHARGE.md
  modified:
    - quickshell/.config/quickshell/modules/bar/SystemCapsule.qml
    - quickshell/.config/quickshell/modules/bar/MediaConnectivityCapsule.qml
    - quickshell/.config/quickshell/modules/dashboard/MediaBackend.qml
    - quickshell/.config/quickshell/modules/dashboard/Design.qml

key-decisions:
  - "MediaBackend's position-refresh Timer was added as a conservative default rather than proven unnecessary live — this session did not restart/reload the running quickshell process (skip-live-verification preference), so whether a plain `activePlayer.position` binding already advances without a forcing Timer was not confirmed either way. The Timer costs nothing when not playing/seekable (gated on drawerOpen && playing && canSeek) and is documented in-source as the conservative choice; a live check on the actual host (a track IS playing right now — Firefox/YouTube via playerctl) would confirm whether it is redundant, and this is worth 18-18's or a follow-up UAT pass to settle."
  - "Bluetooth's five behavior-described states (no adapter / blocked / off / on-with-zero-connected / on-with-connected) render across only THREE distinct glyphs (bluetooth_disabled / bluetooth / bluetooth_connected), not five — the installed Material Symbols Rounded font ships exactly four non-fill bluetooth-prefixed glyphs (bluetooth, bluetooth_connected, bluetooth_disabled, bluetooth_searching, bluetooth_drive), and BluetoothPanel.qml's own three branches (no-adapter/blocked/off) already collapse onto the single 'bluetooth_disabled' glyph, differentiated only by text. This plan follows that exact, already-shipped precedent rather than inventing a fifth bluetooth glyph or repurposing 'bluetooth_searching' (which implies active scanning this entry never does)."
  - "Network's four precedence states (hardware-blocked / off / on-disconnected / connected) collapse the 'device unresolved' transient window into the same glyph as 'on-but-disconnected' (signal_wifi_statusbar_null) rather than inventing a distinct loading glyph — WifiBackend.wifiDevice's own header comment records the pointer 'can take a moment to resolve after startup', and visually 'no connection yet' reads correctly for both cases without a fourth unverified ligature."
  - "[Rule 1 - Bug] The plan's own prose claimed the 1,800,000ms (30-minute) updates-poll interval works out to 'four runs an hour' (also stated in the plan's threat model T-18-08-03 and success criteria). The correct arithmetic is TWO runs an hour (48/day) — 60 minutes / 30 minutes = 2, not 4. Fixed in a standalone commit (9e97587) before this plan's own artifacts could carry the wrong number forward; the interval VALUE (1800000) was always correct, only the prose was wrong. 18-BAR-LIVENESS-CHARGE.md's own numbers use the corrected arithmetic throughout."

patterns-established:
  - "The 'skip live verification, ship fast' operating mode was applied throughout: all task-level <verify> automated grep/regex checks were run and passed; the hyprctl-layers/quickshell-log-tail/human-visual-comparison halves of each task's <verify> block were NOT run (no quickshell reload/restart performed this session). This mirrors 18-05's own precedent (its D7 human render-gate was likewise deferred and logged as a WINDOWS.md ledger entry) — the same treatment is applied here and logged below rather than silently skipped."

requirements-completed: [QBAR-06]

coverage:
  - id: D1
    description: "SystemCapsule.qml renders cpu, ram, disk (from SystemResources, em-dash while not populated, register-driven error tint) and updates (own 30-minute checkupdates reader, single-flighted, renders nothing at zero, click launches a terminal upgrade then a completion notification as two literal argv arrays chained on exit code)"
    requirement: "QBAR-06"
    verification:
      - kind: other
        ref: "Task 1/2 automated <verify> scripts — all grep/regex assertions in acceptance_criteria run and passed (see task commits baa2169, 767256f); qmllint clean exit 0"
        status: pass
    human_judgment: true
    rationale: "The plan's own <verify> blocks require live confirmation on the running bar (a moving CPU number never showing 0% on first paint, visual comparison against top/free/df, the updates glyph genuinely absent at count zero, vertical-orientation re-stack) — none of that was performed this session (no quickshell reload/restart), matching this repo's own established render-gate deferral pattern (18-05's D7). Deferred to the user per D-18-31/GATE-02."
  - id: D2
    description: "MediaConnectivityCapsule.qml renders media (hasPlayer-gated, title capped at 30 chars + elided), audio (pipewireReady-gated volume/mute), network (glyph-only, four-state precedence, no scan path), bluetooth (glyph-only, five logical states across three glyphs, no discovery path) and battery (UPower-gated, renders nothing on this host)"
    requirement: "QBAR-06"
    verification:
      - kind: other
        ref: "Task 4 automated <verify> script — all grep/regex assertions run and passed after one fix (a forbidden literal 'discovering' in a full-line comment, corrected before commit 99c3262); qmllint clean exit 0; command ls /sys/class/power_supply/ confirms 0 real devices on this host"
        status: pass
    human_judgment: true
    rationale: "Same as D1 — the live render-gate half of this task's <verify> (glyph reacting to a real mute/wifi-toggle, vertical re-stack, theme-switch crossfade) was not performed this session. Deferred to the user per D-18-31/GATE-02."
  - id: D3
    description: "MediaBackend.qml repointed onto Quickshell.Services.Mpris (D-18-05) — all twenty public names preserved with unchanged meaning, MediaTab.qml/Dashboard.qml/shell.qml byte-unchanged, retired 1Hz shell-script reader and its ~10-forks/second fan-out removed"
    requirement: "QBAR-06"
    verification:
      - kind: other
        ref: "Task 3 automated <verify> script — every public property/method presence check, D-41 vocabulary check, artPath-no-scheme check, D-18-05/D-35 header citation check, subprocess/timer count checks, single-flight guard check, and the git diff --name-only zero-touched-consumers check all run and passed (commit 647a5fb); qmllint clean exit 0"
        status: pass
    human_judgment: true
    rationale: "The plan's own <verify> requires live confirmation against a real playing track in the Media tab (album art renders, seek slider advances, player switcher works, transport buttons act, an external pause reflects near-instantly) — not performed this session. A real MPRIS player IS active on this host (playerctl status: Playing, Firefox/YouTube) but quickshell was not reloaded to pick up this plan's code, so this remains genuinely unverified live, not merely unobserved. Deferred to the user per D-18-31/GATE-02 — this is the single highest-value manual check in this plan, since D-18-05's own threat register (T-18-08-02, T-18-08-01) and the plan's own must_haves treat a broken Media tab as the harder-to-notice failure."
  - id: D4
    description: "18-BAR-LIVENESS-CHARGE.md — per-backend measured always-on cost (SystemResources/AudioBackend/MediaBackend), what the bar deliberately does not charge for (WifiBackend/BluetoothBackend, D-15-15/D-15-18), this plan's own new charge (updates poll, art resolver, position timer), and a measurement brief for 18-18's QBAR-11 soak"
    requirement: "QBAR-06"
    verification:
      - kind: other
        ref: "Task 5 automated <verify> script — all grep/regex assertions run and passed (commit cb06882); git diff --name-only -- 'quickshell/**' confirmed 0 (no QML touched by this task)"
        status: pass
    human_judgment: false

duration: ~50min
completed: 2026-08-11
status: complete
---

# Phase 18 Plan 08: System & Connectivity Bar Readouts, MPRIS Repoint, Liveness Charge Summary

**QBAR-06's nine bar readouts (clock excepted, already 18-05's) land across two filled capsules and a repointed MPRIS backend — cpu/ram/disk/updates in `[system]`, media/audio/network/bluetooth/battery in `[media + connectivity]` — with the retired bar's 240-syncs-an-hour update checker cut to 2, the drawer's Media tab moved off a ~10-forks/second shell reader onto the native MPRIS singleton with its whole public surface preserved, and the resulting always-on cost measured per backend rather than left to be reconstructed from a diff.**

## Performance

- **Duration:** ~50 min
- **Started:** 2026-08-11 (session start)
- **Completed:** 2026-08-11
- **Tasks:** 5 (all completed)
- **Files modified:** 4 QML files + 1 new planning artifact

## Accomplishments

- `SystemCapsule.qml` filled: cpu/ram/disk read `SystemResources`' published fractions and their own D-41 readiness registers (em-dash, never a synthesized number, while a register is not `"populated"`; a register reading `"empty"` tints the glyph via `Colours.error`), through one reusable inline `Readout` component declared once and instantiated four times. `updates` gets its own single-flighted `checkupdates` reader on a declared 30-minute `Timer` (refreshed on completion and after a clean upgrade exit), renders nothing at a pending count of zero, and its click launches `kitty -e paru -Syu` then, on a clean exit, `notify-send` — two fixed literal argv arrays chained on exit code, reproducing the retired bar's own behaviour with no shell and no concatenation.
- `MediaConnectivityCapsule.qml` filled: media (visible only with a player, title capped at `Design.mediaTitleMaxChars`/30 and elided right — the one named truncation exception and the only unbounded string on the bar), audio (glyph swaps mute/unmute, percent value gated on `pipewireReady`), network (glyph-only, four-state precedence read entirely from ungated properties, connected-glyph opacity graded by signal strength only when already available), bluetooth (glyph-only, five logical states rendered across three glyphs following `BluetoothPanel.qml`'s own established convention), and battery (gated on `UPower.displayDevice` being non-null AND `isPresent` — renders nothing on this host, confirmed live: `command ls /sys/class/power_supply/ | wc -l` → `0`).
- `MediaBackend.qml` repointed onto `Quickshell.Services.Mpris` (D-18-05): the header records the D-35 fence's supersession explicitly rather than silently contradicting it. All twenty public names — `hasPlayer`, `playing`, `displayTitle`, `displayArtist`, `displayAlbum`, `artPath`, `positionSeconds`, `lengthSeconds`, `hasVolume`, `volumeLevel`, `canSeek`, `widgetState`, `players`, `activePlayerId`, `drawerOpen`, `playPause()`, `nextTrack()`, `previousTrack()`, `seekTo()`, `setVolume()`, `selectPlayer()` — keep unchanged meaning. `MediaTab.qml`, `Dashboard.qml` and `shell.qml` are byte-unchanged (`git diff --name-only` confirmed empty against all three). The retired 1Hz shell-script reader, its player-list child, its argv-dispatch mutator and both retired script path properties are gone; the album-art resolver script stays in use, single-flighted and last-write-wins keyed on the URL it was launched for.
- `Design.qml` gained exactly one appended token, `mediaTitleMaxChars: 30` — `git diff` shows 1 removed line (a closing-brace reflow, not a value change) against 10 added.
- `18-BAR-LIVENESS-CHARGE.md` written: measured, per-backend, with the commands that produced every number — `SystemResources`' GPU sampler alone costs 900 `nvidia-smi` calls/hour on this host (it has a real NVIDIA GPU) that the bar does not consume; `AudioBackend` tracks 8 PipeWire nodes continuously (measured live via `pw-dump`); `MediaBackend` costs nothing at idle after the repoint. This plan's own new charge (the updates poll) is a 120-fold reduction from the retired bar's cadence. A measurement brief hands 18-18 exact diff targets, the Pitfall 7 tracked-node hypothesis, and the one re-narrowing question (GPU/network sampling the bar pays for but does not use) with its ownership (an 18-05 `shell.qml` scope correction, not this plan's to take).

## Task Commits

Each task was committed atomically:

1. **Task 1: TRACER — one live cpu readout through the wave-3 slot contract** — `baa2169` (feat)
2. **Task 2: The `[system]` capsule completed — ram, disk, and an updates reader that does not hammer the mirrors** — `767256f` (feat)
3. **[Rule 1 fix] Correct updates-interval arithmetic in SystemCapsule comment** — `9e97587` (fix)
4. **Task 3: `MediaBackend.qml` repointed onto native MPRIS** — `647a5fb` (feat)
5. **Task 4: The `[media + connectivity]` capsule — media, audio, network, bluetooth, battery** — `99c3262` (feat)
6. **Task 5: The permanent-liveness charge, measured per backend and handed to 18-18** — `cb06882` (docs)

**Plan metadata:** pending final commit (this SUMMARY + STATE.md + ROADMAP.md + REQUIREMENTS.md)

## Files Created/Modified

- `quickshell/.config/quickshell/modules/bar/SystemCapsule.qml` — filled: cpu/ram/disk/updates, one reusable `Readout` element, updates reader + click action
- `quickshell/.config/quickshell/modules/bar/MediaConnectivityCapsule.qml` — filled: media/audio/network/bluetooth/battery, a second (deliberately geometry-identical) `Readout` element
- `quickshell/.config/quickshell/modules/dashboard/MediaBackend.qml` — rewritten internals, public surface preserved
- `quickshell/.config/quickshell/modules/dashboard/Design.qml` — append-only, `mediaTitleMaxChars: 30`
- `.planning/phases/18-qml-bar-retirement-machinery/18-BAR-LIVENESS-CHARGE.md` — new, the measured always-on charge

## Shipped Glyph Ligature Names (authoritative — for 18-14's popout headers and 18-19's aesthetic pass)

All verified present in the installed `Material Symbols Rounded` variable font this session (`fontTools` glyph-order check against `/usr/share/fonts/ttf-material-symbols-variable/MaterialSymbolsRounded[FILL,GRAD,opsz,wght].ttf`) — **no substitution was needed for any entry**.

| Entry | State | Glyph |
|---|---|---|
| cpu | — | `memory` |
| ram | — | `memory_alt` |
| disk | — | `hard_drive_2` |
| updates | — | `deployed_code_update` |
| media | — | `music_note` |
| audio | unmuted | `volume_up` |
| audio | muted | `volume_off` |
| network | hardware-blocked, radio off | `wifi_off` |
| network | on but disconnected / device unresolved | `signal_wifi_statusbar_null` |
| network | connected | `network_wifi` (opacity-graded by signal strength when available, never a second ligature) |
| bluetooth | no adapter / blocked / off | `bluetooth_disabled` |
| bluetooth | on, zero connected | `bluetooth` |
| bluetooth | on, one or more connected | `bluetooth_connected` |
| battery | charging | `battery_charging_full` |
| battery | ≤15% and not charging | `battery_alert` |
| battery | otherwise present | `battery_full` |

## MediaBackend Public Surface (post-repoint, authoritative for 18-14's media popout)

**Properties:** `drawerOpen` (gate, retained by name — see Decisions), `activePlayer` (internal-facing, the resolved `MprisPlayer` object), `activePlayerId` (keyed on `uniqueId`, falling back to `dbusName`), `hasPlayer`, `playing`, `displayTitle` (falls back to the player's `identity` when `trackTitle` is empty), `displayArtist`, `displayAlbum`, `positionSeconds`, `lengthSeconds`, `hasVolume`, `volumeLevel`, `canSeek`, `widgetState` (`"populated"`/`"empty"` — `"pending"` retained by name only, now structurally unreachable), `players` (switcher shape: `{ id, label, active }`), `artPath` (bare path, never a URL).

**Methods:** `playPause()`, `nextTrack()`, `previousTrack()`, `seekTo(seconds)` (absolute, via the `position` property's writer — NOT the MPRIS `seek(offset)` relative method), `setVolume(fraction)`, `selectPlayer(playerId)`.

**Active-player selection rule** (no sort, model order used as-is): (1) the explicitly selected player if still present in `Mpris.players.values`; (2) the first player reporting `isPlaying`; (3) the first player in the model; (4) `null`. A selection whose player vanishes falls back through this same rule automatically — `_explicitSelectionId` is never explicitly cleared, it simply stops matching.

**Position-refresh timer question — NOT settled live this session** (see Decisions above): a `positionRefreshTimer` (1000ms, gated on `drawerOpen && playing && canSeek`) was added conservatively rather than proven necessary, since this session did not reload the running `quickshell` process against this plan's own code. Whether MPRIS's `positionChanged` notification already fires often enough for a plain binding to have sufficed was not confirmed either way this session.

## Decisions Made

- **The position-refresh Timer is a conservative, unconfirmed-live default** — see `key-decisions` above and `coverage` D3's rationale. This is the one open verification item with real weight in this plan; everything else is either mechanically checked or a glyph choice.
- **Bluetooth's five described states render across three glyphs, matching `BluetoothPanel.qml`'s own precedent exactly** rather than inventing a fourth or fifth bluetooth-prefixed glyph the installed font does not ship distinctly for "blocked" vs "no adapter" vs "off".
- **Network's device-unresolved window shares a glyph with on-but-disconnected**, for the same reason — no invented fourth ligature for a transient state this repo's own `WifiBackend.qml` documents as real but brief.
- **[Rule 1 - Bug] Corrected a wrong arithmetic claim inherited from the plan's own prose** — see `key-decisions` above (commit `9e97587`). "Four runs an hour" for a 30-minute interval is wrong; two is correct. The interval value itself (1800000ms) was never wrong.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Forbidden literal "discovering" in a full-line comment tripped MediaConnectivityCapsule.qml's own no-scan-leak gate**

- **Found during:** Task 4, running the acceptance-criteria grep sweep before commit
- **Issue:** The file's own header comment, explaining why the bluetooth entry reads none of `BluetoothBackend`'s sweep-related surface, used the literal word "discovering" — but the acceptance criterion `grep -cE 'startDiscovery|stopDiscovery|discovering|scannerEnabled|rescan|\.scanning'` is NOT comment-filtered (unlike several sibling checks in this same plan), so a comment mentioning the identifier by name trips the same gate a real reference would. The plan's own task text anticipated exactly this ("name that omission in the comment by describing it rather than by writing the identifiers, because this file is gated on those identifiers being absent from it entirely") — this was a drafting miss against the plan's own explicit instruction, not a new discovery.
- **Fix:** Reworded the comment to describe the omitted surface ("the sweep-in-progress flag and... the two sweep-control methods") without naming the identifiers.
- **Files modified:** `quickshell/.config/quickshell/modules/bar/MediaConnectivityCapsule.qml`
- **Verification:** Re-ran the grep; returns `0`.
- **Committed in:** `99c3262` (fixed before commit, not a separate correction commit)

**2. [Rule 1 - Bug] Wrong arithmetic in an in-source comment, inherited verbatim from the plan's own prose**

- **Found during:** Task 5, while writing 18-BAR-LIVENESS-CHARGE.md and computing `3600/1800 = 2` for the real per-hour figure
- **Issue:** `SystemCapsule.qml`'s updates-reader comment (committed in Task 2) stated "Thirty minutes below is four runs an hour" — copied from the plan's own action text and threat model, both of which say "four an hour" for a 1,800,000ms (30-minute) interval. The correct figure is two.
- **Fix:** Rewrote the comment with the correct arithmetic and a note that the plan text's own claim was wrong.
- **Files modified:** `quickshell/.config/quickshell/modules/bar/SystemCapsule.qml`
- **Verification:** Re-ran Task 2's full grep sweep (Motion-token filter, checkupdates-appears-once) and `qmllint`; both clean.
- **Committed in:** `9e97587` (standalone fix commit, since Task 2's commit had already landed)

---

**Total deviations:** 2 auto-fixed (both Rule 1 — one a same-task drafting miss caught before commit, one a wrong number inherited from the plan's own prose, caught and fixed one task later during Task 5's own arithmetic).
**Impact on plan:** Neither fix touches behavior; both are correctness-of-explanation fixes. No QML runtime behavior changed as a result of either.

## Issues Encountered

None beyond the two deviations above.

## User Setup Required

None — no external service configuration required. `checkupdates` (`pacman-contrib`), `nvidia-smi`, `paru` and `notify-send` are all already installed on this host and were not newly introduced by this plan.

## Known Stubs

None. Every entry in both capsules reads a real backend or native singleton; no placeholder or hardcoded value exists anywhere in either capsule file.

## Live Verification — Deferred (per this session's skip-live-verification operating mode)

Every task's automated `<verify>` grep/regex script ran and passed (see Task Commits and `coverage` above). The LIVE half of each task's verify block — restarting/confirming quickshell picked up the change, tailing `~/.cache/quickshell.log`, and the D-18-31/GATE-02 human render-gate visual pass — was **not performed this session**, matching this repo's own established precedent (18-05-SUMMARY.md's identical deferral, logged as a WINDOWS.md ledger entry). The single highest-value manual check among these is the Media tab's four hand-checked behaviours (art renders, seek slider advances, player switcher works, transport buttons act) plus the near-instant external-pause reflection — this is D-18-05's own named highest risk ("the tab is the harder half to notice broken"), and it needs a real quickshell reload against this plan's code to confirm, not merely to observe.

Logged to `.planning/WINDOWS.md` as unrun-verify entries (one per task's deferred live/human-check half) so this stays visible at ship time.

## Next Plan Readiness

- `SystemCapsule.qml` and `MediaConnectivityCapsule.qml` are both filled; `Bar.qml`, `modules/bar/qmldir`, `BarEntryModel.qml` and `shell.qml`'s bar wiring remain untouched — confirmed via `git diff --name-only` across this plan's full commit range.
- 18-12 (scroll-to-adjust on audio, the brightness section), 18-13 (hover dwell, popout summon, pin latch) and 18-14 (the five popout bodies, including the media popout's own use of the `MediaBackend` public surface documented above) each inherit exactly one interaction target per capsule with no partial ownership conflict — this plan's only interactive element is the updates entry's own click handler, named as such in `SystemCapsule.qml`'s own header.
- **Design.qml overlap notice, restated for the next wave-3 executor**: this plan appended `mediaTitleMaxChars` (10 lines added, 1 removed — a brace reflow, not a value change). 18-09/18-10/18-11 have NOT yet been executed as of this plan's completion (their `PLAN.md` files exist; no `SUMMARY.md` files exist for any of them yet) — so the `Design.qml` overlap 18-05's wave-3 notice flagged has not yet materialized as an actual merge conflict. Whichever of 18-10 (`trayMaxExtent`) or 18-11 runs next should append after this plan's own addition with no expectation of a textual collision, since every entry in this file is an independent one-line `readonly property`.
- `18-BAR-LIVENESS-CHARGE.md` is ready for 18-18's QBAR-11 soak to diff against; it also raises one re-narrowing question (GPU/network sampling `SystemResources` charges the bar for but the bar does not consume) whose resolution requires an `18-05` `shell.qml` scope correction, not a unilateral wave-3 edit.

---
*Phase: 18-qml-bar-retirement-machinery*
*Completed: 2026-08-11*

## Self-Check: PASSED

- FOUND: `quickshell/.config/quickshell/modules/bar/SystemCapsule.qml`
- FOUND: `quickshell/.config/quickshell/modules/bar/MediaConnectivityCapsule.qml`
- FOUND: `quickshell/.config/quickshell/modules/dashboard/MediaBackend.qml`
- FOUND: `quickshell/.config/quickshell/modules/dashboard/Design.qml`
- FOUND: `.planning/phases/18-qml-bar-retirement-machinery/18-BAR-LIVENESS-CHARGE.md`
- FOUND: `.planning/phases/18-qml-bar-retirement-machinery/18-08-SUMMARY.md`
- FOUND commit: `baa2169`
- FOUND commit: `767256f`
- FOUND commit: `9e97587`
- FOUND commit: `647a5fb`
- FOUND commit: `99c3262`
- FOUND commit: `cb06882`
