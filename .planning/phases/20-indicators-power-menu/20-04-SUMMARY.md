---
phase: 20-indicators-power-menu
plan: 04
subsystem: ui
tags: [quickshell, qml, hyprland, wpctl, brightnessctl, pipewire, layer-shell, bash]

# Dependency graph
requires:
  - phase: 20-indicators-power-menu
    provides: "20-03's shared token/colour-role/layer-namespace surface (Design.osdWidth/osdHideDelayMs, BarRoles pairs, quickshell-osd layer-rule row)"
provides:
  - "Osd.qml — a Toast.qml instance, bottom-centre, backend-state-driven (D-20-05), reacting to AudioBackend.masterVolume/masterMuted/inputVolume/inputMuted and BrightnessBackend.percent"
  - "Toast.qml parameterised on edge/interactive/namespace/dismiss-interval, DND toast byte-identical"
  - "keybinds.lua fully off swayosd-client: all six media/brightness binds repointed onto wpctl/brightnessctl, locked=true preserved on every one"
  - "quickshell-doctor's panel-osd-state-driven-trigger (renamed from panel-swayosd-key-ownership) proving D-20-05's inverted differential against the quickshell-osd namespace"
  - "QSD_BAR_SURFACE_ROWS registration for osd/Osd.qml plus a Toast-instance-aware fallback in the registry's forward closure"
affects: [20-05, 20-09]

# Actuals (#2632)
actuals:
  tokens: 16500
  tasks: 3
  commits: 7

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Parameterise-and-promote a single-consumer frame (Toast.qml) into a generic type with defaulted properties, rather than forking a second frame type, when a second consumer needs different edge/namespace/dwell values"
    - "State-driven OSD trigger: Connections on a backend's own reactive property (never the keybind) so any external write raises the identical indicator"
    - "quickshell-doctor registry forward-closure fallback markers, narrowly gated on 'the direct marker count was zero', for a shared-base-type instance file that overrides a property rather than declaring WlrLayershell.namespace/exclusiveZone directly"

key-files:
  created:
    - quickshell/.config/quickshell/modules/osd/Osd.qml
    - quickshell/.config/quickshell/modules/osd/qmldir
    - hypr/.config/hypr/scripts/tests/quickshell-fixtures/compliant-bar-qml-root/osd/Osd.qml
  modified:
    - quickshell/.config/quickshell/modules/toast/Toast.qml
    - quickshell/.config/quickshell/shell.qml
    - hypr/.config/hypr/config/keybinds.lua
    - hypr/.config/hypr/scripts/quickshell-doctor

key-decisions:
  - "quickshell-osd's QSD_BAR_SURFACE_ROWS row is registered against osd/Osd.qml, not toast/Toast.qml — the forward closure's file->row resolution requires the row's namespace LITERAL to appear in that same row's file, and 'quickshell-osd' only appears in Osd.qml (Toast.qml only carries the default 'quickshell-notif-toast')"
  - "Registry forward-closure extended with two markers narrowly gated on the direct-marker-count-was-zero case, so no pre-existing row's verdict changes — validated both by a new self-test fixture and directly against the real quickshell/modules tree (forward closure: rows=9 missing=0 unexpected-reservation=0)"
  - "panel-swayosd-key-ownership renamed (not deleted) to panel-osd-state-driven-trigger — D-20-05 inverts D-15-24's premise (both write paths must now raise the indicator, not just one), so the differential instrument is re-expressed rather than discarded"
  - "_qsd_swayosd_server_reachable's guard is dropped from the renamed check (it tests quickshell-osd now, not swayosd) but the helper itself stays defined — the separate one-step-per-press volume probe (QS-06) is a second, remaining consumer, left untouched per the plan's own scope and recorded here for plan 20-09"

requirements-completed: [QOSD-01, QOSD-03]

coverage:
  - id: D1
    description: "All six media/brightness keybinds repointed off swayosd-client onto wpctl/brightnessctl, locked=true preserved on every one"
    requirement: "QOSD-01"
    verification:
      - kind: unit
        ref: "shell grep verify (Task 2 <verify><automated> block, reproduced live): grep -vE '^\\s*--' keybinds.lua | grep -c swayosd-client == 0; all five exec targets match; all six binds carry locked = true; no brightnessctl -c short flag"
        status: pass
    human_judgment: false
  - id: D2
    description: "Osd.qml's trigger widened to react to mic (inputVolume/inputMuted) and brightness (BrightnessBackend.percent) backend state, content unchanged (plan 20-05's own scope)"
    requirement: "QOSD-01"
    verification:
      - kind: unit
        ref: "colour-lint (136 passed) and motion-lint (273 passed) both exit 0 against Osd.qml; QML load check (quickshell -p shell.qml) shows no ERROR/binding-loop lines beyond the three pre-existing, explicitly-ignorable warnings"
        status: pass
    human_judgment: true
    rationale: "Live confirmation that pressing mic-mute/brightness keys actually raises the OSD (or correctly stays inert for brightness on this hardware) requires a running session; not run live per this repo's stated preference to skip live verification and let the user confirm."
  - id: D3
    description: "quickshell-doctor's panel-osd-state-driven-trigger check proves D-20-05: both a direct PipeWire write and the repointed hardware-key exec target raise quickshell-osd exactly once"
    requirement: "QOSD-03"
    verification:
      - kind: unit
        ref: "hypr/.config/hypr/scripts/quickshell-doctor --self-test — 55 passed, 0 failed"
        status: pass
      - kind: other
        ref: "Direct sourcing of quickshell-doctor's function definitions (no self-test, no live mutation) against the real quickshell/modules tree: _qsd_assert_bar_surface_registry_forward returns 'rows=9 missing=0 unexpected-reservation=0'"
        status: pass
    human_judgment: false

duration: 45min
completed: 2026-08-15
status: complete
---

# Phase 20 Plan 04: OSD Volume/Mic/Brightness Indicator Summary

**Full swayosd-client removal from keybinds.lua onto wpctl/brightnessctl, OSD trigger widened to mic and brightness backends, and quickshell-doctor's swayosd differential check re-expressed against quickshell-osd with a registry fallback for Toast-derived instance files.**

## Performance

- **Duration:** ~45 min (this continuation session; Task 1 tracer was a prior agent's session)
- **Tasks:** 3/3 complete (Task 1 tracer + human-verify gate completed by a prior session; Task 2 and Task 3 completed and committed this session)
- **Files modified:** 4 (2 created, plus 1 test fixture created)

## Accomplishments
- `keybinds.lua` no longer calls `swayosd-client` anywhere — all six media/brightness binds now change system state directly (`wpctl`/`brightnessctl`), each keeping `locked = true` verbatim, with brightness using the mandatory long `--class=backlight` flag.
- `Osd.qml`'s trigger `Connections` widened to `AudioBackend.inputVolume`/`inputMuted` and the `BrightnessBackend` singleton's `percent` — three backends now reach `show()`, sharing Task 1's single volume-row content (the multi-row column is plan 20-05's scope).
- `quickshell-doctor`'s `panel-swayosd-key-ownership` (D-15-24) renamed and re-expressed as `panel-osd-state-driven-trigger` (D-20-05): the differential proof now expects BOTH a direct PipeWire write and the hardware-key exec target to raise `quickshell-osd` exactly once (an inversion of the old "hardware key only" assertion), instrumented on the `quickshell-osd` namespace instead of `swayosd`.
- `QSD_BAR_SURFACE_ROWS` gained a row for the OSD (`osd/Osd.qml|quickshell-osd|exact|3|noreserve|transient`), and the registry's forward closure gained two narrowly-scoped fallback markers so a `Toast{}`-derived instance file (which overrides a property rather than declaring `WlrLayershell.namespace`/`exclusiveZone` directly) can satisfy the closure without loosening it for any pre-existing row.

## Task Commits

Each task was committed atomically:

1. **Task 1: End-to-end volume indicator — one path, key to pixels** (tracer) - `0d699fd`, plus four fix commits from the tracer's own human-verify gate (`1cd5362`, `e7c0fe2`, `0d056ec`, `77966cb`) — completed and verified by a prior session; preserved verbatim by this continuation.
2. **Task 2: Complete the swayosd-client removal from keybinds.lua and widen the trigger to mic and brightness** - `6058e5c` (feat)
3. **Task 3: Re-express quickshell-doctor's swayosd-instrumented check against quickshell-osd** - `71ec7d7` (feat)

_Note: Task 1 is a `type="tracer"` task, not TDD — its multiple commits are its own human-verify feedback-gate fix cycle, not a RED/GREEN/REFACTOR sequence._

## Files Created/Modified
- `quickshell/.config/quickshell/modules/osd/Osd.qml` - the OSD surface (Task 1: single volume row, four-state glyph; Task 2: widened trigger to mic/brightness)
- `quickshell/.config/quickshell/modules/osd/qmldir` - module manifest for the new `osd/` directory (Task 1)
- `quickshell/.config/quickshell/modules/toast/Toast.qml` - parameterised on edge/interactive/namespace/dismiss-interval (Task 1)
- `quickshell/.config/quickshell/shell.qml` - mounts `Osd { audioBackend: audioBackendInstance }`, widens `audioTruthNeeded` (Task 1)
- `hypr/.config/hypr/config/keybinds.lua` - all six media/brightness binds off `swayosd-client`, onto `wpctl`/`brightnessctl` (Task 1 raise-volume; Task 2 the remaining five)
- `hypr/.config/hypr/scripts/quickshell-doctor` - `panel-osd-state-driven-trigger` (renamed/re-expressed check), `_qsd_osd_activation_count` re-pointed at `quickshell-osd`, `QSD_BAR_SURFACE_ROWS` gained the OSD row, forward-closure fallback markers added (Task 3)
- `hypr/.config/hypr/scripts/tests/quickshell-fixtures/compliant-bar-qml-root/osd/Osd.qml` - new self-test fixture exercising the registry's fallback markers, mirroring the real Osd.qml's property-override shape rather than a literal `WlrLayershell.namespace` declaration (Task 3)

## Decisions Made
- See `key-decisions` in frontmatter. Two decisions in particular were forced by direct static analysis rather than the plan's own text, and are worth restating here for anyone reading only the prose: (1) the plan offered two row-placement options for the `quickshell-osd` registry row and expected one to work unmodified against the existing check body — neither did, because the forward closure requires the namespace LITERAL and the `WlrLayershell.namespace`/`exclusiveZone` markers to co-occur in the SAME file, and Task 1's parameterisation split those across `Toast.qml` (owns the binding) and `Osd.qml` (owns the value). The check body itself needed a narrow, backward-compatible extension, not just a row addition. (2) `_qsd_swayosd_server_reachable`'s guard was dropped from the renamed check (rather than kept) because gating a `quickshell-osd` differential proof on `swayosd-server`'s bus presence is backwards now that swayosd is out of the dependency path — but the helper function itself is left defined since a second, unrelated consumer (the QS-06 "one-step-per-press volume probe") still calls it directly.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Registry forward-closure could not pass against EITHER of the plan's two suggested row placements**
- **Found during:** Task 3
- **Issue:** The plan instructed registering the `quickshell-osd` row against `toast/Toast.qml` (if the registry resolves namespace→row) or falling back to `osd/Osd.qml` (if file→row resolution breaks a second row on the same file). Direct inspection of `_qsd_assert_bar_surface_registry_forward` showed it is file→row, AND requires the row's namespace literal AND a `WlrLayershell.namespace` marker to both appear in the SAME file. `toast/Toast.qml` has the marker but not the `"quickshell-osd"` literal (only `Osd.qml` has that, as a `layerNamespace` property override); `osd/Osd.qml` has the literal but not the `WlrLayershell.namespace` marker (it never writes that binding directly — `Toast.qml` owns it once). Neither of the plan's two options actually satisfied the unmodified check body.
- **Fix:** Registered the row against `osd/Osd.qml` (per the plan's own fallback direction) and extended `_qsd_assert_bar_surface_registry_forward` with two markers, each gated narrowly on "the direct marker's count was exactly zero" (so no pre-existing row, which all still declare `WlrLayershell.namespace`/`exclusiveZone` directly, can reach the fallback branch): a `layerNamespace:` property-override line accepted as an equally-valid, count-once namespace declaration, and — only when that same fallback was the reason the row matched — an inherited `exclusiveZone: 0` check against `toast/Toast.qml`'s own literal when the instance file has none of its own.
- **Files modified:** hypr/.config/hypr/scripts/quickshell-doctor, hypr/.config/hypr/scripts/tests/quickshell-fixtures/compliant-bar-qml-root/osd/Osd.qml
- **Verification:** First pass of the exclusiveZone fallback was too broad (gated only on "not Toast.qml's own row"), which let a genuinely poisoned `bar/HotZone.qml` fixture (a real `noreserve` row that legitimately declares `WlrLayershell.namespace` directly) slip through by riding the fallback to `toast/Toast.qml`'s unrelated zero-literal — caught by `--self-test` regressing `poisoned-second-reserving-surface.qml` from FAIL to a false PASS. Fixed by additionally gating the exclusiveZone fallback on `used_instance_fallback` (only reachable when the namespace-marker fallback itself was used). Re-ran `--self-test`: 55 passed, 0 failed (up from 54 passed before this row/fallback existed). Independently verified against the REAL `quickshell/modules` tree (not just the synthetic fixture) by sourcing the script's function definitions directly (no self-test, no live mutation): `_qsd_assert_bar_surface_registry_forward "quickshell/.config/quickshell/modules"` returns `rows=9 missing=0 unexpected-reservation=0`.
- **Committed in:** 71ec7d7 (Task 3 commit)

---

**Total deviations:** 1 auto-fixed (1 bug in the check-body assumptions, caught and fixed within the same task before commit — not shipped broken).
**Impact on plan:** Necessary for the registry's own correctness claim (a row without a working forward-closure check is a decorative row, not a real registration). No scope creep — the fix is scoped to the two markers this one new row needed, verified not to change any pre-existing row's verdict.

## Baseline Behaviour Comparison (mandatory, per continuation prompt)

Compared against `.planning/phases/20-indicators-power-menu/20-BEHAVIOUR-BASELINE.md`'s swayosd section.

**Volume (raise/lower/mute):** `wpctl set-volume`/`set-mute` are direct PipeWire writes; `AudioBackend.masterVolume`/`masterMuted` are LIVE reactive bindings onto `Quickshell.Services.Pipewire`, so they update regardless of which process wrote to PipeWire — the OSD raises correctly for both the hardware key and any external write (D-20-05's own requirement, and QOSD-01's stated test). Step size: the baseline document does not record swayosd-client's own internal step percentage (it is swayosd's binary-internal default, not documented in the CSS/config surfaces GATE-01 measured), so an exact step-size match against swayosd cannot be claimed either way — this is an unmeasured baseline gap, not something this plan's own exec targets could resolve. `-l 1.0` on the raise bind is a NAMED IMPROVEMENT over swayosd (caps PipeWire's own software boost at 100%, which swayosd-client used to cap for us) — already documented in Task 1's own commit.

**Mic-mute:** `wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle` is the same class of live PipeWire write as volume mute, and `AudioBackend.inputMuted` is the same kind of live reactive binding — so the trigger mechanism is symmetric with volume and correctly fires. **Named delta:** the OSD's CONTENT does not yet render a mic-specific row — pressing mic-mute today raises the frame but shows Task 1's volume row (glyph + slider bound to `masterVolume`/`masterMuted`), which does not reflect mic state at all. This is an explicitly intentional intermediate state per the plan's own Task 2 text ("Task 2 of this plan only widens the TRIGGER... never the content shown here" — plan 20-05 builds the mic row), not a bug, but it IS a real behavioural gap against swayosd's baseline (which rendered a mic-specific pill on mic-mute, distinct from the volume pill) that a reader of only this plan's `<verify>` block would not see, since that block only checks trigger wiring, not rendered content.

**Brightness:** `brightnessctl --class=backlight set 5%±` is a raw subprocess exec issued directly by the Hyprland keybind — it does NOT go through `BrightnessBackend.qml`'s own `Process`. **Named delta / latent architecture gap:** `BrightnessBackend.percent` (the property the OSD's `Connections` block watches) only updates from writes `BrightnessBackend.qml`'s OWN `adjustProcess` issues (the bar's scroll-driven `adjust()`/`setPercent()` path) — it has no live subscription to the device file the way `AudioBackend` has a live PipeWire subscription. This means: even on hardware WITH a backlight device, pressing the brightness hotkey would correctly change the ACTUAL hardware brightness (the raw `brightnessctl` exec works standalone) but would NOT raise the OSD, since nothing updates `BrightnessBackend.percent` in response to an external process's write. This is unlike volume/mic, where PipeWire's own pub-sub means ANY writer's change is observed. This gap is UNTESTABLE on this host (confirmed zero backlight-class devices — `BrightnessBackend.qml`'s own header and 20-RESEARCH.md's live-verified finding), so both the swayosd-era behaviour and this plan's new behaviour are equally inert here (not a regression on THIS hardware), but the underlying trigger-mechanism gap is real and would surface as "brightness changes but no OSD" on a host with a backlight device. The plan's own Task 2 text explicitly forbade adding a second brightness write path ("Do not add a second brightness write path... This task reads `percent`, it does not write"), so fixing this properly (e.g. having the keybind route through the shell via IPC, or having `BrightnessBackend` poll/subscribe to the device file) is out of this task's scope — flagged here for plan 20-05 or a dedicated follow-up rather than silently left undiscovered.

**No-op / OSD-on-no-write:** Not applicable to mic (toggle always changes state) or volume raise/lower at this scope (5% steps away from the 0/100 boundary in ordinary use); not testable for brightness on this hardware.

## Known Gaps (not this plan's scope, recorded for visibility)

- **`session/PowerMenu.qml` is an unregistered bar-family-shaped-namespace-declaring frame** per `_qsd_assert_bar_surface_registry_reverse` (`unregistered=1` when run against the real `quickshell/modules` tree). This is 20-06's own file (commit `b00eb02`, a concurrent, still-in-progress plan per this session's own `<concurrent_plan_state>` instructions) and its own quickshell-doctor registration is explicitly named as 20-06 Task 3's future scope — not touched by this plan, per the concurrent-plan boundary this session was instructed to respect.
- **The literal string `swayosd-client --output-volume raise` still appears once in `quickshell-doctor`**, inside the separate "one-step-per-press volume probe" (QS-06, unrelated to `panel-osd-state-driven-trigger`) — this means the plan's own Task 3 acceptance criterion "no `swayosd-client --output-volume raise` invocation [anywhere in the file]" is NOT fully met at the whole-file level, only within the renamed check this task owns. This is deliberate: Task 3's own `<action>` text never mentions the QS-06 probe, and explicitly instructs "If other consumers [of `_qsd_swayosd_server_reachable`] exist, leave it and record the remaining call sites in the summary so plan 20-09 finishes the removal" — the QS-06 probe is exactly that remaining consumer, left untouched per that instruction rather than expanded into out-of-scope territory.

## Issues Encountered
None beyond the auto-fixed registry-forward-closure bug documented above, caught and corrected before commit.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Plan 20-05 can now build the multi-row OSD column (mic/brightness/caps-lock rows) on top of an already-widened trigger — no further `Connections` wiring needed, only content.
- Plan 20-09 (RETIRE-04) has two concrete remaining swayosd-client/`_qsd_swayosd_server_reachable` call sites recorded above (the QS-06 probe) to finish removing.
- Plan 20-06 (power menu, concurrent) is unaffected — `shell.qml`, `keybinds.lua`, and `quickshell-doctor` edits in this plan were kept additive around its own `PowerMenu`/`Super+Shift+Q`/doctor-extension work, verified by reading each file fresh before editing.

## Self-Check: PASSED

All 8 files claimed above (created + modified) were verified present on disk via direct `[ -f ... ]` checks, and all 7 commit hashes (0d699fd, 1cd5362, e7c0fe2, 0d056ec, 77966cb, 6058e5c, 71ec7d7) were verified present via `git log --oneline --all`.

---
*Phase: 20-indicators-power-menu*
*Completed: 2026-08-15*
