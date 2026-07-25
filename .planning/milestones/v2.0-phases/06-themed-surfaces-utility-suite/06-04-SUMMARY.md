---
phase: 06-themed-surfaces-utility-suite
plan: 04
subsystem: theming
tags: [hyprlock, matugen, playerctl, hyprlang, lock-screen]

# Dependency graph
requires:
  - phase: 06-02
    provides: "~/.local/state/theme/hyprlock.conf dedicated matugen render target (D-30)"
  - phase: 04-02
    provides: "FIX-02 input-hardening block (immediate_render, ignore_empty_input, check_text, fail_text) and the lockout-recovery (second-TTY) test procedure"
provides:
  - "Info-rich hyprlock: 12-hour clock, date, playerctl now-playing, battery %, caps-lock status, conditional failed-attempts counter, re-tuned blurred-wallpaper background"
  - "hyprlock.conf decoupled onto its own dedicated theme render target (D-30)"
  - "FIX-02 input hardening preserved verbatim and re-verified live under light + dark themes"
affects: [07-utility-suite, 08-waybar-polish]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "hyprlock label blocks copy the Time/Date shape (monitor/text/color/font_size/position/halign/valign) plus shadow_passes/shadow_size for legibility over the blurred background — documented in 06-PATTERNS.md"
    - "cmd[update:Nms] polling for subprocess-backed labels (playerctl, battery, caps-lock) that degrade to an empty/hidden string when the underlying data source is absent, rather than showing an error or placeholder"
    - "hyprlock's own $ATTEMPTS[fallback] bracket-substitution form used for conditional-visibility text (invisible at 0, bare value after) instead of wrapping a literal prefix around a $VAR that always renders"

key-files:
  created: []
  modified:
    - hypr/.config/hypr/hyprlock.conf

key-decisions:
  - "$image is never rendered by the 06-02 hyprlock-colors.conf target (documented matugen limitation) — background wired directly to the theme-init/wallpaper.sh-owned ~/Pictures/Wallpapers/current.jpg symlink instead of a template variable (D-19: wallpaper-setting stays owned by the picker/init, never matugen)"
  - "Avatar (D-12 themed-initial circle) dropped entirely per user rejection at the live-lock checkpoint — no photo, no initial glyph; scope reduced from the original plan spec, approved by user"
  - "Clock switched from generic $TIME to hyprlock's native $TIME12 substitution (12-hour, zero-padded, AM/PM) per user request at checkpoint — verified present in the installed 0.9.5 binary via strings/source cross-check, no cmd[]/date fallback needed"
  - "Failed-attempts counter rendered as bare $ATTEMPTS[] (bracket-fallback form) instead of a literal-prefixed $ATTEMPTS, so it is fully invisible at 0 attempts and shows only the bare count after a failure"
  - "playerctl now-playing label built via a brace-free sh -c concatenation, not playerctl --format \"{{artist}} - {{title}}\" — hyprlang cannot parse literal {{ }} inside a text value and silently falls back to hyprlock's built-in 'Sample Text' default"

patterns-established:
  - "Any new hyprlock label sitting on the blurred background gets shadow_passes/shadow_size matching the Time/Date convention, for legibility across both light and dark palettes"
  - "Subprocess-driven lock labels (playerctl/battery/caps-lock) must degrade to empty output on absence, never an error string or stale placeholder"

requirements-completed: [LOCK-01]

coverage:
  - id: D1
    description: "hyprlock.conf sources ~/.local/state/theme/hyprlock.conf (dedicated render target, D-30) instead of hyprland.conf"
    requirement: "LOCK-01"
    verification:
      - kind: unit
        ref: "grep -q 'source = ~/.local/state/theme/hyprlock.conf' hypr/.config/hypr/hyprlock.conf && ! grep -q 'source = ~/.local/state/theme/hyprland.conf' hypr/.config/hypr/hyprlock.conf"
        status: pass
    human_judgment: false
  - id: D2
    description: "FIX-02 input hardening (immediate_render, ignore_empty_input, check_text, fail_text) preserved verbatim"
    requirement: "LOCK-01"
    verification:
      - kind: unit
        ref: "grep -q 'immediate_render = true' && grep -q 'ignore_empty_input = true' && grep -q 'check_text' && grep -q 'fail_text = <i>$FAIL</i>' hypr/.config/hypr/hyprlock.conf"
        status: pass
    human_judgment: false
  - id: D3
    description: "Info-rich lock screen (now-playing, battery, caps-lock, failed-attempts, re-tuned blur) renders correctly and FIX-02 input behavior holds live, under both light and dark themes"
    requirement: "LOCK-01"
    verification:
      - kind: manual_procedural
        ref: "Task 2 lockout-recovery-guarded live lock test (second TTY safety net), light + dark theme passes"
        status: pass
    human_judgment: true
    rationale: "Live visual legibility and password-input behavior under a real Hyprland session cannot be verified by static grep/automation — requires a human eyeballing the rendered lock surface and exercising the password field, per the plan's mandatory Task 2 checkpoint."

# Metrics
duration: 33min
completed: 2026-07-12
status: complete
---

# Phase 06 Plan 04: Info-Rich Hyprlock Redesign Summary

**Hyprlock redesigned onto its own matugen render target with a 12-hour clock, playerctl now-playing, battery/caps-lock indicators, and a conditional failed-attempts counter, while the Phase 4 FIX-02 input hardening stays verbatim — approved live under both light and dark themes.**

## Performance

- **Duration:** 33 min (19:28:04 -> 19:56:47 code work, plus live checkpoint verification)
- **Started:** 2026-07-12T19:28:04+03:00
- **Completed:** 2026-07-12T19:56:47+03:00 (code) / checkpoint approved after two feedback rounds
- **Tasks:** 2 (1 auto + 1 checkpoint:human-verify)
- **Files modified:** 1

## Accomplishments
- hyprlock.conf decoupled from hyprland.conf onto its own dedicated `~/.local/state/theme/hyprlock.conf` render target (D-30)
- Info-rich lock layout: native 12-hour `$TIME12` clock, date, playerctl now-playing (auto-hidden when nothing plays), battery %, caps-lock status, and a bracket-conditional failed-attempts counter — all styled with shared-pipeline palette variables and a consistent drop-shadow convention
- Background re-tuned (blur_passes, brightness, vibrancy) for the busier layout and wired to the live `current.jpg` wallpaper symlink
- FIX-02 hardening block (immediate_render, ignore_empty_input, check_text, fail_text = `<i>$FAIL</i>`) preserved verbatim and re-confirmed working during the live test
- Live lock-screen test performed under the mandatory lockout-recovery procedure (second TTY standby), passed for both light and dark themes; user approved after two rounds of checkpoint feedback

## Task Commits

Each task was committed atomically:

1. **Task 1: Source swap + info-rich indicator labels (initial pass)** - `36b9b29` (feat)
2. **Task 1-fix: Background wiring, avatar/clock collision, shadow convention** - `37ad716` (fix)
3. **Task 1-fix: Checkpoint feedback round — drop avatar, native 12h clock, conditional attempts, stray-text root cause** - `54cbfd3` (fix)
4. **Task 2: Lockout-recovery-guarded live lock test** - human-verify checkpoint, no file changes, **APPROVED** by user (light + dark, FIX-02 confirmed)

**Plan metadata:** (this commit) `docs(06-04): complete info-rich hyprlock redesign plan`

_Note: Task 1 required two follow-up fix commits — one for a root-cause bug pass (Rule 1) and one to apply user-requested scope changes surfaced at the Task 2 checkpoint (see Deviations)._

## Files Created/Modified
- `hypr/.config/hypr/hyprlock.conf` - Source retarget to the dedicated hyprlock theme file (D-30); new now-playing/battery/caps-lock/failed-attempts labels; re-tuned background blur; native 12-hour clock; FIX-02 block untouched

## Decisions Made
- `$image` is never rendered by the 06-02 hyprlock-colors.conf target (matugen limitation, documented in 06-02-SUMMARY.md) — background wired directly to the theme-init/wallpaper.sh-owned `~/Pictures/Wallpapers/current.jpg` symlink instead (D-19: wallpaper ownership stays with the picker/init script, never matugen)
- Avatar (D-12 themed-initial circle) dropped entirely — rejected by the user at the live checkpoint; no photo, no initial glyph, no shape{} block
- Clock switched from a generic `$TIME` expectation to hyprlock's native `$TIME12` substitution per user request — verified present in the installed 0.9.5 binary (`strings`/source cross-check), no external `cmd[]`/`date` fallback needed
- Failed-attempts counter rendered as bare `$ATTEMPTS[]` (bracket-fallback substitution), not a literal-prefixed `$ATTEMPTS`, so the label is fully invisible at 0 attempts and shows only the bare count after a failure
- playerctl now-playing label built via a brace-free `sh -c` concatenation rather than `playerctl --format "{{artist}} - {{title}}"` — root cause of the "Sample Text" stray-label bug found during checkpoint feedback

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] `$image` background variable never resolved to the wallpaper**
- **Found during:** Task 1 (first live inspection after initial pass, `37ad716`)
- **Issue:** The plan's action step specified `path = $image` for the background block, but the 06-02 hyprlock-colors.conf render target explicitly never populates `$image` (documented matugen limitation, same as hyprland-colors.conf's blank `$image =`) — the background never actually resolved to a real file.
- **Fix:** Pointed `path` directly at the theme-init/wallpaper.sh-owned `~/Pictures/Wallpapers/current.jpg` symlink, the same always-current target other consumers already read (D-19).
- **Files modified:** hypr/.config/hypr/hyprlock.conf
- **Verification:** Live lock test confirmed the blurred current wallpaper renders correctly.
- **Committed in:** `37ad716`

**2. [Rule 1 - Bug] Avatar/time label vertical collision**
- **Found during:** Task 1 (`37ad716`)
- **Issue:** The plan's avatar position (0,280) and 96px clock label overlapped in practice — 96px font renders roughly 159px tall using real Pango metrics, not the plan's assumed spacing.
- **Fix:** Repositioned to eliminate overlap (later made moot when the avatar was removed entirely per checkpoint feedback — see deviation 4).
- **Files modified:** hypr/.config/hypr/hyprlock.conf
- **Committed in:** `37ad716`

**3. [Rule 1 - Bug] Missing shadow convention on new indicator labels**
- **Found during:** Task 1 (`37ad716`)
- **Issue:** The existing Time/Date labels use `shadow_passes`/`shadow_size` for legibility over the blurred background; the newly added indicator labels (now-playing, battery, caps-lock, failed-attempts, greeting) were missing this, per 06-PATTERNS.md's documented convention.
- **Fix:** Added matching shadow_passes/shadow_size to every new label.
- **Files modified:** hypr/.config/hypr/hyprlock.conf
- **Committed in:** `37ad716`

**4. [Rule 1 - Bug, root-caused at checkpoint] Stray "Sample Text" label and hyprlang `{{ }}` parse failure**
- **Found during:** Task 2 checkpoint feedback (first live test round)
- **Issue:** `playerctl --format "{{artist}} - {{title}}"` put literal doubled curly braces into the label's `text` value; hyprlang cannot parse `{{` inside a `text` value (logs "Invalid expression type", "Proceeds ignoring faulty entries") and silently falls back to hyprlock's built-in default text, the literal string "Sample Text" — confirmed via `strings`/source inspection (ConfigManager.cpp) and a safe non-locking parse-only harness.
- **Fix:** Replaced the mustache-format invocation with a brace-free `sh -c` concatenation of `playerctl metadata artist`/`title`.
- **Files modified:** hypr/.config/hypr/hyprlock.conf
- **Verification:** Re-ran the safe parse-only harness — zero "Config has errors" — before committing; confirmed live at the second checkpoint round.
- **Committed in:** `54cbfd3`

### User-Requested Deviations (approved at checkpoint, supersede plan spec)

These are not defects — they are explicit scope changes the user requested after seeing the live lock screen, approved before proceeding:

- **Avatar removed entirely.** The plan specified a themed-initial circle avatar (D-12); the user rejected it outright at the live checkpoint. No photo, no glyph, no shape{} block ships in this plan.
- **Clock switched to 12-hour.** Plan implied a generic time display; user requested 12-hour format, delivered via hyprlock's native `$TIME12`.
- **Failed-attempts counter made conditional.** Plan's original counter rendered a literal "Attempts: " prefix unconditionally even at 0 failures; user feedback drove the switch to the bracket-fallback `$ATTEMPTS[]` form so the label is fully invisible until the first failure.

---

**Total deviations:** 4 auto-fixed (all Rule 1 - bugs found during live testing) + 3 user-requested scope changes approved at the Task 2 checkpoint.
**Impact on plan:** All auto-fixes were necessary for correctness (background actually showing the wallpaper, no label overlap, legibility, and a genuine hyprlang parsing bug). The user-requested changes reduce scope (dropped avatar) and adjust display format/behavior (12h clock, conditional counter) but do not compromise LOCK-01's must-haves — FIX-02 hardening, dedicated render target, now-playing, and battery/caps-lock indicators all remain intact and were live-verified.

## Issues Encountered
- hyprlang's inability to parse literal `{{`/`}}` in label `text` values was undocumented and only surfaced via live testing — root-caused with a safe parse-only harness (fake `$WAYLAND_DISPLAY` so hyprlock parses config and logs, then fails before touching the real session) rather than guesswork, avoiding any risk during the mandatory lockout-recovery test discipline.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness
- LOCK-01 fully delivered and live-verified under both light and dark themes; hyprlock.conf's dedicated render target (D-30) and FIX-02 hardening are stable references for any future lock-screen work (e.g. Phase 8 OLED/idle considerations should not need to touch this file's input-hardening block).
- No blockers for remaining Phase 06 plans (05-09).

---
*Phase: 06-themed-surfaces-utility-suite*
*Completed: 2026-07-12*

## Self-Check: PASSED

- FOUND: hypr/.config/hypr/hyprlock.conf
- FOUND: commit 36b9b29
- FOUND: commit 37ad716
- FOUND: commit 54cbfd3
- FOUND: .planning/phases/06-themed-surfaces-utility-suite/06-04-SUMMARY.md
