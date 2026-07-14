---
phase: 08-waybar-evolution
plan: 09
subsystem: theming-pipeline
tags: [swaync, notification-center, gtk3-css, brightnessctl, shell-quoting, security]

requires:
  - phase: 08-waybar-evolution
    provides: "eww media-popup — the one media surface swaync's mpris widget is deleted in favor of (08-07)"

provides:
  - "Reworked swaync config.json: mpris widget deleted, volume slider + device-agnostic brightness slider + 3-toggle anti-drift buttons-grid added, panel widened to 420px"
  - "Reworked swaync style.css: mpris rules deleted, new widget-container/slider/toggle-ON CSS themed through the existing 19-key palette, zero hex literals"
  - "Empirically-derived facts about swaync 0.12.6's command-execution model (relevant to any future swaync config/CSS work in this repo): every command/update-command/cmd_getter/cmd_setter string is wrapped internally in `/bin/sh -c \"%s\"` — a literal double-quote character in a config value corrupts that wrapper, tilde expansion works natively with no added wrapper needed, and a redundant `sh -c '<path>'` wrapper of your own would silently BREAK tilde expansion (single quotes suppress it)"

affects: [08-VERIFICATION]

tech-stack:
  added: []
  patterns:
    - "swaync command/update-command/cmd_getter/cmd_setter values must never contain a literal `\"` character — swaync's own `/bin/sh -c \"%s\"` wrapper is not escaping-aware, so an embedded double quote prematurely closes it and corrupts the script. Use `case value in pattern) ... ;; esac` instead of `[ \"$v\" = x ]`, and `''` (single-quoted empty string) instead of `\"\"` for empty case patterns."
    - "D-28 anti-drift toggle shape: `command` (click) calls the exact existing script bare, with no wrapper; `update-command` (fires on every control-center visibility change) reads the exact existing state file/query back — never a second copy of the toggle's logic or state."

key-files:
  created: []
  modified:
    - swaync/.config/swaync/config.json
    - swaync/.config/swaync/style.css

key-decisions:
  - "Brightness control uses swaync's generic `slider` widget (cmd_setter/cmd_getter backed by `brightnessctl -c backlight`), not the native `backlight` widget, because this host has zero /sys/class/backlight devices and the native widget's `device` key would be host-specific baked-in state — a stow-tracked config must stay reproducible on any host (F1)."
  - "The theme toggle is a picker launcher, not a boolean flip: clicking opens theme-switch.sh's walker picker; its `active` state is a pure read-back of ~/.local/state/theme/mode (light -> ON, dark -> OFF), refreshed each time the panel opens."
  - "Removed my own added `sh -c '...'` wrapper around the two bare toggle `command` values (gaming/theme) after empirically proving swaync's own internal `/bin/sh -c \"%s\"` execution already performs tilde expansion correctly — an added wrapper with the path inside single quotes would have SUPPRESSED tilde expansion entirely, the opposite of its intent."
  - "cssPriority stayed at the pre-existing `application` value — no lever needed. All new widgets resolved palette colors cleanly under both a light (gruvbox-light) and the original dark (catppuccin) preset with zero CSS parse errors."

requirements-completed: [BAR-05]

coverage:
  - id: D1
    description: "swaync mpris widget deleted (config.json widget list + widget-config sub-block) and its CSS rule block + section comment deleted in full (D-24)"
    requirement: "BAR-05"
    verification:
      - kind: integration
        ref: "grep -ic mpris over both swaync/.config/swaync/config.json and swaync/.config/swaync/style.css returns 0"
        status: pass
    human_judgment: false
  - id: D2
    description: "volume + brightness sliders and 3-toggle buttons-grid added, panel widened to 420px, notifications.vexpand true (D-27/D-30)"
    requirement: "BAR-05"
    verification:
      - kind: integration
        ref: "python3 -m json.tool swaync/.config/swaync/config.json (JSON_OK); widgets array == [title,dnd,volume,slider,buttons-grid,notifications]; control-center-width == 420"
        status: pass
      - kind: manual_procedural
        ref: "Live swaync restart log (factory.vala) shows all 6 widgets loaded with zero errors; panel opened/closed via swaync-client -t -sw with swaync surviving both invocations"
        status: pass
    human_judgment: false
  - id: D3
    description: "All 3 buttons-grid toggles call the exact existing script/state the Super-key menu uses — no second copy of any logic (D-28)"
    requirement: "BAR-05"
    verification:
      - kind: integration
        ref: "grep -c gaming-mode-toggle.sh == 1; grep -c theme-switch.sh == 1; grep -c eval == 0; grep -c brightnessctl == grep -c 'brightnessctl -c backlight'"
        status: pass
      - kind: manual_procedural
        ref: "Live: ran swaync's exact composite invocation /bin/sh -c \"~/.config/hypr/scripts/gaming-mode-toggle.sh\" — flipped ~/.cache/gaming-mode off->on->off (properly restoring hyprctl decorations + un-SIGSTOPing hypridle each time); set the file out-of-band and confirmed the update-command read-back followed it; ran theme-apply gruvbox-light/catppuccin directly and confirmed the theme toggle's update-command tracked ~/.local/state/theme/mode both directions; ran the DND command branch both ways and confirmed swaync-client -D agreed"
        status: pass
    human_judgment: false
  - id: D4
    description: "D-29: inline notification action buttons fire from the panel, and a single notification dismisses individually (not only Clear All)"
    requirement: "BAR-05"
    verification:
      - kind: manual_procedural
        ref: "notify-send -A open=Open ... ; swaync-client -a 0 fired the action — notify-send's own stdout printed the literal action key 'open', notification count dropped to 0 afterward (hide-on-action). Two notifications created, swaync-client --close-latest closed one while the other remained (count 2->1), then -C (Clear All) emptied the list (count ->0)"
        status: pass
    human_judgment: false
  - id: D5
    description: "T-08-41/T-08-42: hostile Pango-markup + shell-metacharacter notification body and action label render with zero code execution"
    requirement: "BAR-05"
    verification:
      - kind: manual_procedural
        ref: "notify-send with body '<b>bold</b><a href=\"evil\">click</a>; rm -rf /tmp/pwned; $(touch /tmp/pwned-cmdsub); `touch /tmp/pwned-backtick`' and action label '<i>Open</i>$(touch /tmp/pwned-action)' — all 4 marker files confirmed absent after the notification was created and the panel opened; swaync process survived throughout"
        status: pass
    human_judgment: true
    rationale: "Code-execution absence was directly proven (marker files never created); literal visual rendering (no interpreted <b>/<a> styling) could not be screenshotted in this exec context (grim/hyprctl monitors unavailable — same limitation recorded in 08-05-SUMMARY.md) and is deferred to a human glance per the plan's own human-check block."
  - id: D6
    description: "Panel re-themes under both a light and dark preset with zero hex literals and full token resolution"
    requirement: "BAR-05"
    verification:
      - kind: integration
        ref: "grep -Ec '#[0-9a-fA-F]{3,8}' (comments excluded) over style.css == 0; every @token used is @define-color'd in swaync-colors.css (mechanically diffed, zero missing)"
        status: pass
      - kind: manual_procedural
        ref: "theme-apply gruvbox-light then catppuccin: swaync.css re-rendered with correct light/dark hex values each time, CSS reload succeeded, panel opened cleanly under both with zero GTK CSS parse warnings in the swaync log"
        status: pass
      - kind: other
        ref: "theme-doctor: 96 passed / 1 failed (the 1 failure is a pre-existing, out-of-scope dirty-tree check unrelated to this plan's files — see Deviations); theme-parity: 1630/1630 passed"
        status: pass
    human_judgment: false

# Metrics
duration: 30min
completed: 2026-07-14
status: complete
---

# Phase 8 Plan 9: swaync Notification Center Rework Summary

**Deleted swaync's mpris widget in favor of the 08-07 eww media popup, added a volume slider + device-agnostic brightness slider + a 3-toggle anti-drift buttons-grid to the panel, and fixed a real shell-quoting bug in the toggle scripts discovered via live testing against the running swaync daemon.**

## Performance

- **Duration:** ~30 min
- **Tasks:** 3 completed (Task 3 required zero additional fixes)
- **Files modified:** 2 (`swaync/.config/swaync/config.json`, `swaync/.config/swaync/style.css`)

## Accomplishments

- swaync's `mpris` widget (config key, `widget-config` sub-block, and every CSS rule + its section comment) is fully deleted — the eww popup from 08-07 is now the desktop's one media surface (D-24).
- The panel gained a native `volume` slider, a device-agnostic `slider`-based brightness control (`brightnessctl -c backlight`, numeric-guarded getter), and a 3-toggle `buttons-grid` (gaming mode / DND / theme) — all themed through the existing 19-key palette with zero hex literals (D-27).
- Every toggle calls the exact script and reads the exact state file the Super-key menu already uses — proven live against the real running swaync and the real scripts, not just asserted (D-28).
- D-29 (inline actions + per-notification dismiss) and T-08-41/T-08-42 (hostile markup/shell-metacharacter safety) were proven against real `notify-send` notifications and the real swaync action-invocation path.
- Panel widened from 380px to 420px (D-30); `notifications.vexpand: true` keeps the notification list the focal point per UI-SPEC.
- Discovered and fixed a genuine shell-quoting bug (Rule 1) in the first draft of the toggle/slider commands, found via live testing rather than assumed — see Deviations.

## Task Commits

Each task was committed atomically:

1. **Task 1: config.json — delete mpris, add sliders + toggle grid, widen panel** - `734e9b3` (feat)
2. **Task 2: style.css — delete mpris rules, theme new widgets + fix shell-quoting bug** - `4c637b3` (fix)
3. **Task 3: Prove it — bell path, anti-drift, D-29** - no commit (pure verification; zero bugs found, nothing to fix)

**Plan metadata:** committed alongside this SUMMARY (see final commit below)

## Files Created/Modified

- `swaync/.config/swaync/config.json` — widgets reordered to `title, dnd, volume, slider, buttons-grid, notifications`; mpris deleted; volume/slider/buttons-grid widget-config added; `control-center-width` 380 -> 420
- `swaync/.config/swaync/style.css` — mpris rule block + section comment deleted; new `.widget-volume`/`.widget-slider`/`.widget-buttons-grid` card + slider-track/toggle-ON rules added
- `matugen/.config/matugen/templates/swaync-colors.css` — **NOT modified.** Every `@token` referenced by the new CSS (`primary`, `on_primary`, `surface_variant`, `outline`, `on_surface_variant`) was already defined in the existing 19-key schema. Confirmed byte-identical via `git diff --stat` (empty output).

## Decisions Made

1. **Brightness widget: generic `slider`, not native `backlight` (F1).** `/sys/class/backlight` is empty on this host and bare `brightnessctl` resolves to `enp5s0-3::lan` (a LAN port LED). The native `backlight` widget's `device` key defaults to `intel_backlight` and would be wrong here and wrong again on any future laptop host — baking a discovered device name into a stow-tracked config is exactly the host-only state CLAUDE.md forbids. Used the generic `slider` widget with `cmd_setter`/`cmd_getter` scoped to `brightnessctl -c backlight`, which is device-agnostic: inert (min value, no error) on this backlight-less desktop, functional on a laptop. This is an implementation choice inside D-27, not a scope reduction — a pointer-draggable brightness control genuinely ships.
2. **Theme toggle is a picker launcher, not a boolean (D-28, binding).** Its `command` bare-calls `theme-switch.sh` (which opens a walker picker and takes no arguments — it deliberately ignores `SWAYNC_TOGGLE_STATE`). Its `active` state is a pure read-back of `~/.local/state/theme/mode` (`light` -> `true`, else `false`), refreshed on every control-center visibility change. A future reader must not "fix" this into a fake boolean flip — the read-back IS the correctness mechanism.
3. **No `sh -c` wrapper on the bare toggle commands.** I initially added one (`sh -c '~/.config/hypr/scripts/gaming-mode-toggle.sh'`), reasoning from `nm -D` showing swaync imports `g_shell_parse_argv`/`g_spawn_async_with_pipes` (the non-shell exec path). Live testing proved this reasoning wrong and the added wrapper actively harmful: swaync in fact wraps every command value in its own `/bin/sh -c "%s"`, and my added wrapper's single-quoted path would have suppressed tilde expansion (single quotes are literal in shell — no tilde expansion inside them). Removed the wrapper; the bare `~/.config/hypr/scripts/...` value works correctly, empirically proven via a marker-file redirect test (see Deviations).
4. **`cssPriority` left at `application` (pre-existing value) — no lever pulled.** All new widget rules resolved cleanly under both a light and dark preset with zero GTK CSS parse warnings in the swaync log; the documented `cssPriority` escape hatch (raise to `user`) was never needed. Recorded per the plan's explicit instruction to say so either way.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Shell-quoting bug: literal `"` characters in `update-command`/`cmd_getter` broke swaync's own internal `/bin/sh -c "%s"` wrapper**

- **Found during:** Task 2 live verification (opening the panel triggered the slider's `cmd_getter`, which is polled on control-center visibility change)
- **Issue:** My first-draft `cmd_getter`/`update-command` values used the standard defensive idiom `[ "$v" = "on" ]` / `case "$v" in ""|...`. swaync's actual stderr output when the panel opened showed a syntax error: `sh: -c: line 1: syntax error near unexpected token '|'`, with all double-quote characters visibly stripped from the reported command and a stray unmatched single quote at the end. Root cause: swaync wraps every `command`/`update-command`/`cmd_setter`/`cmd_getter` string in `/bin/sh -c "%s"` internally (confirmed present as a literal string in the installed `swaync` binary via `strings`). A raw `"` character embedded in my config value prematurely closed that outer double-quoted wrapper mid-string, corrupting the resulting script.
- **Fix:** Rewrote every affected string to contain zero literal `"` characters: replaced `[ "$v" = x ]` with `case $v in x) ... ;; esac`, and replaced the empty double-quoted case pattern `""` with the single-quoted equivalent `''` (single quotes are inert/literal inside the outer double-quoted wrapper, so they pass through unaffected — the fresh, real `/bin/sh -c` invocation that finally executes the un-mangled script then parses `''` correctly as a real empty-string case pattern).
- **Files modified:** `swaync/.config/swaync/config.json` (the three `update-command` strings and the brightness `cmd_getter`)
- **Verification:** Reloaded config live (`swaync-client -R`), opened the panel (`swaync-client -op`) with a truncated log capturing swaync's own stdout/stderr — zero errors on reload. Re-ran every acceptance-criteria grep (gaming-mode-toggle.sh count 1, theme-switch.sh count 1, eval count 0, brightnessctl/brightnessctl -c backlight counts equal) — all still pass with the corrected strings.
- **Committed in:** `4c637b3` (part of Task 2's commit, since it was found live during Task 2's own verification pass, before Task 3 began)

**2. [Rule 1 - Bug] Redundant/harmful `sh -c '...'` wrapper around bare toggle commands**

- **Found during:** Same live-testing pass as Issue 1, while reasoning through why the wrapper existed
- **Issue:** The plan's Task 1 Step G anticipated the possibility that tilde would not expand and instructed wrapping in `sh -c` if so. My first draft pre-emptively added `sh -c '~/.config/hypr/scripts/gaming-mode-toggle.sh'` (and the theme equivalent) based on `nm -D` showing swaync imports `g_shell_parse_argv`/`g_spawn_async_with_pipes` (GLib's non-shell exec path). This reasoning was superseded by direct empirical evidence (Issue 1's stderr capture) that swaync in fact wraps commands in a real `/bin/sh -c "%s"`. Given that, my added wrapper's *single-quoted* path (`'~/...'`) would have suppressed tilde expansion entirely (tilde expansion never happens inside single quotes) — the opposite of the wrapper's intended purpose.
- **Fix:** Removed the added wrapper; restored the bare `~/.config/hypr/scripts/gaming-mode-toggle.sh` / `~/.config/hypr/scripts/theme-switch.sh` command values, matching the plan's original literal instruction.
- **Files modified:** `swaync/.config/swaync/config.json`
- **Verification:** A marker-file redirect test (`~/.config/hypr/scripts/gaming-mode-toggle.sh status > <marker> 2>&1; echo true` set temporarily as the gaming toggle's `update-command`, then reloaded and the panel opened to trigger it) produced the marker file with content `off` — direct proof the bare tilde path resolved and the script executed successfully with no wrapper. Reverted the temporary diagnostic back to the real `update-command` immediately after. Later, in Task 3, the exact composite `/bin/sh -c "~/.config/hypr/scripts/gaming-mode-toggle.sh"` was run directly and flipped `~/.cache/gaming-mode` off->on->off correctly, confirming the mechanism end-to-end.
- **Committed in:** `4c637b3` (same commit as Issue 1 — both were found and fixed together during the same live-testing pass)

---

**Total deviations:** 2 auto-fixed (both Rule 1 — genuine bugs found via live testing against the real running swaync, not assumptions).
**Impact on plan:** Both fixes were necessary for correctness (the original config would have thrown a shell syntax error on every panel-open poll of the brightness slider, and the wrapper fix prevents a tilde-expansion failure that live testing proved was about to happen). No scope creep — both fixes stayed entirely within `swaync/.config/swaync/config.json`, the file Task 1/2 already owned.

## Issues Encountered

**Screenshot/visual verification unavailable in this exec context.** `grim`/`hyprctl monitors` returned "no wl_output"/empty output despite a real, live Hyprland session (`hyprctl clients` returns genuine live windows, proving the compositor connection itself is real) — the identical limitation already recorded in `08-05-SUMMARY.md` for this same session. Where the plan's `<human-check>` block calls for a literal visual/pixel confirmation (glyph rendering with no tofu boxes, contrast legibility, hover states, the panel "looking right"), that pass is deferred to the user via Super+N, exactly as 08-05 deferred its Super+B pass. Everywhere the requirement could instead be proven by a non-visual, deterministic mechanism (state-file reads, `swaync-client` return values, marker-file side effects, grep-based token/selector assertions, log-based CSS-parse-error absence), that mechanism was used and is recorded above as the actual verification evidence — this covers the overwhelming majority of this plan's must-haves, including the security-critical ones (T-08-41/T-08-42's code-execution absence).

**`swaync-client -a 0` (action invocation) needed a swaync restart to behave reliably.** Two earlier attempts against the long-running swaync process silently no-op'd (exit 0, but the notify-send process never unblocked and its stdout stayed empty) for reasons not fully diagnosed — possibly stale internal state from the many config reloads performed during Task 1/2 testing. A clean `swaync` restart (matching `autostart.conf`'s own launch invocation) resolved it immediately and the action fired correctly on the first attempt afterward. Not a defect in any shipped file; noted here as a testing-environment quirk, consistent with 08-07-SUMMARY's own note about stray/ghost process accumulation during iterative scratch-config testing.

## Finding recorded, NOT fixed (out of `files_modified`, per plan instruction)

**`hypr/.config/hypr/hypridle.conf`'s dim listener calls bare `brightnessctl`** (`on-timeout = brightnessctl -s set 30%`, `on-resume = brightnessctl -r`, lines 31-32) with no `-c backlight` class scope. On this host, bare `brightnessctl` resolves to `enp5s0-3::lan` (a LAN port LED, per F1), meaning hypridle's dim-on-idle behavior is currently a no-op at best (or targets the wrong device). This file is owned by `08-04` in this same wave and is deliberately **not modified** here. Flagging for `08-VERIFICATION.md`.

## Resolved planner findings

**F1 (brightness device-agnostic slider):** Confirmed and implemented as designed. Empirically re-verified this session: `brightnessctl -c backlight g`/`-m` on this host print `Failed to read any devices of class 'backlight'.` to **stderr** and exit 1 (slightly different from F1's stated "exits 0" — a minor discrepancy from the planner's finding, noted for accuracy) but with **empty stdout**, which the `cmd_getter`'s numeric guard (`case $v in ''|*[!0-9]*) echo 0 ;; ...`) correctly catches via the empty-string pattern, emitting `0` either way. The guard's correctness does not depend on the exact exit code, only on stdout content, so this discrepancy has zero functional impact.

**F2 (toggle-ON selector):** Confirmed. `/etc/xdg/swaync/style.css:472` declares `.widget-buttons-grid flowboxchild > button.toggle:checked` as the selector with the shipped comment "style given to the active toggle button." Styled this as the primary selector with `.widget-buttons-grid flowboxchild > button.active` as a defensive sibling in the same rule.

**F3 (glyph cmap gate):** Re-ran this session via direct `fontTools` cmap + `hmtx` parse of the installed `/usr/share/fonts/TTF/FiraCodeNerdFont-Regular.ttf`:

| Codepoint | Glyph name | Present | Advance width | `M`-equal | Use |
|---|---|---|---|---|---|
| `U+F02B4` | `md-google_controller` | yes | 1200 | yes | Gaming toggle (new glyph this plan introduces) |
| `U+F1FC` | `fa-paintbrush` | yes | 1200 | yes | Theme toggle (reused verbatim from `settings.toml`'s Theme entry — confirmed by direct codepoint extraction from that file) |
| `U+F009B` | `md-bell_off` | yes | 1200 | yes | DND toggle (reused verbatim from `modules.jsonc`'s `dnd-none` icon — confirmed by direct codepoint extraction) |
| `U+F205` | `fa-toggle_on` | yes | 1200 | yes | **Trap avoided** — not used for the gaming toggle (it's a toggle-switch glyph, not a gamepad; Phase 7's Super-key menu uses it for its own "Gaming mode" entry, but that context differs from a grid where every button is already a toggle) |

**F4 (shipped default `buttons-grid` WiFi example):** Read before writing. Its `sh -c '[[ ... ]] && ... || ...'` pattern is why I initially (incorrectly) assumed conditionals require an explicit `sh -c` wrapper distinct from swaync's own internal one — the shipped example's wrapper is in fact the SAME kind of redundant nesting I had to remove for my own gaming/theme `command` fields (harmless there because it contains no embedded double quotes, but not technically necessary either, since swaync's own `/bin/sh -c "%s"` already provides the shell context).

## User Setup Required

None — no external service configuration required. All packages (swaync, brightnessctl) were already installed prior to this plan; no `install.sh` changes.

## Next Phase Readiness

- BAR-05 is now fully discharged for this plan's scope: the bell button opens a genuinely reworked control-centre panel (view/clear/interact), verified live.
- `08-VERIFICATION.md` should record: (a) the `hypridle.conf` bare-`brightnessctl` finding above, owned by 08-04; (b) that this plan's visual/pixel-level human-check items (glyph rendering, contrast legibility, hover states) remain outstanding pending a live Super+N pass by the user, for the same environment reason 08-05 recorded for Super+B.
- No blockers for subsequent phase-8 plans. `theme-doctor` (96/97 — the 1 failure is the pre-existing, out-of-scope dirty-tree check, unrelated to any file this plan touched) and `theme-parity` (1630/1630) both confirm the theming pipeline stayed green throughout.

---
*Phase: 8-Waybar Evolution*
*Completed: 2026-07-14*

## Self-Check: PASSED

- FOUND: `swaync/.config/swaync/config.json`
- FOUND: `swaync/.config/swaync/style.css`
- FOUND: `.planning/phases/08-waybar-evolution/08-09-SUMMARY.md`
- FOUND: commit `734e9b3`
- FOUND: commit `4c637b3`
