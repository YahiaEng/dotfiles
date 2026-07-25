---
phase: 09-wlogout-to-wleave-migration
plan: 02
subsystem: theming
tags: [wleave, wlogout, hyprland, gtk4, layer-shell, matugen, waybar, elephant, m3-color-roles, stow]

requires:
  - phase: 09-01
    provides: "wleave 0.7.1-1 installed and human-approved; installed-artefact config schema facts (layout.json filename, top-level+per-button keys, spacing key, D-08 second-text-slot finding); matugen dry-run proof of the four new M3 container roles"
provides:
  - "A fully wired, themed, six-capsule wleave power menu reachable from all three UI entry points (Super+Shift+Q, both waybar layouts' custom/power, elephant menus Power entry)"
  - "install.sh + stow.sh reproduce the power menu on a fresh Arch system with zero host-only manual state"
  - "The GTK3 wlogout engine fully retired from the repo (config/repo level only — the wlogout package itself stays installed, D-11)"
  - "theme-engine contract.json / theme-doctor / theme-stress-test all repointed at the wleave GTK4 render target, in the correct format family (D-16)"
  - "The version-info footer wleave renders by default is suppressed via a native config key, not a CSS hack"
  - "A corrected finding for 09-03: a native per-button second text slot (label.action-name) DOES exist on this engine, contradicting 09-01's D-08 conclusion"
affects: [09-03-checkpoint-decision, 09-04-render-gate]

tech-stack:
  added: []
  patterns:
    - "wleave layout.json top-level keys ARE accepted as JSON (not CLI-flag-only as 09-01's man-page-only research left unconfirmed) — confirmed live via the config-mode debug log printing 'specified from config' for every key set in layout.json"
    - "wleave's shipped default /etc/wleave/style.css proves button#<label> id-selectors work and drives per-button colour via --view-fg-color — a concrete pattern 09-03 can build on for per-capsule hue identity"

key-files:
  created:
    - wleave/.config/wleave/layout.json
    - wleave/.config/wleave/style.css
    - hypr/.config/hypr/scripts/wleave.sh
    - matugen/.config/matugen/templates/wleave-colors.css
    - .planning/phases/09-wlogout-to-wleave-migration/deferred-items.md
    - .planning/WINDOWS.md
  modified:
    - matugen/.config/matugen/config.toml
    - hypr/.config/hypr/config/windowrules.conf
    - hypr/.config/hypr/config/keybinds.conf
    - hypr/.config/hypr/config/autostart.conf
    - hypr/.config/hypr/scripts/ai-workspace.sh
    - waybar/.config/waybar/modules.jsonc
    - waybar/.config/waybar/config-floating.jsonc
    - elephant/.config/elephant/menus/main.toml
    - install.sh
    - stow.sh
    - theme-engine/.config/theme-engine/contract.json
    - theme-engine/.config/theme-engine/theme-doctor
    - theme-engine/.config/theme-engine/theme-stress-test
    - VERIFICATION.md
    - .claude/CLAUDE.md
    - theme-engine/.config/theme-engine/palettes/*.json (all 20, Task 1 deviation)

key-decisions:
  - "wleave's content wrapper (GtkCenterBox) does not vertically expand to fill the window — the plan's window > box scrim selector only dims the button row's own height, not the full screen. Fixed by painting the 0.40 scrim on `window` directly instead (window > box kept as a transparent no-op so the capsule row is never double-tinted). Empirically proven against the installed 0.7.1 binary, not assumed."
  - "wleave's grid stretches buttons to fill available cell space with no aspect constraint by default (min-width/height are a floor, not a target) — fixed natively via layout.json's button-aspect-ratio: 1.0 plus a percentage-based margin: '36.4%' (scales with monitor size, no hardcoded pixel geometry), confirmed live via screenshot to hit the 96px capsule / 24px gap target."
  - "All 20 static preset palette JSON files were missing on_tertiary_container/error_container/on_error_container (09-01's blocking finding). Added all three to every palette, derived from each palette's own hues (error_container = blend(error, background, 0.50), mirroring the already-documented tertiary_container formula; on_*_container reuses the on_surface convention verified 20/20 against the existing on_primary_container role) — no invented literal hex, no homogenised palette."
  - "The version-info footer (orchestrator finding A, user-approved fold-in) is suppressed via layout.json's native top-level no-version-info: true key, NOT via CSS display:none — that CSS property is empirically confirmed unsupported by this GTK4 install ('CSS Parse error: ... No property named display'). A CSS-only defence-in-depth rule using supported properties (opacity/font-size/min-size/padding/margin: 0) is kept in style.css as a fallback in case a future wleave version drops the config key."
  - "The wleave binary self-reports version 0.7.0 via --version and its about-dialog footer links to the 0.6.0 GitHub release tag, while pacman -Q wleave correctly reports 0.7.1-1 (the pinned, human-audited PKGBUILD tag). This is upstream's own internal version-string metadata lagging its release-tag bump, not a wrong-package installation. Recorded plainly so 09-04's render gate does not misread it as a wrong-version failure."
  - "09-01's D-08 conclusion (\"no native second text slot exists\") is WRONG and is corrected here for 09-03: wleave's own shipped /etc/wleave/style.css styles button label.action-name, a real per-button text node. Our layout.json sets text: \"\" on all six buttons, which is the only reason nothing currently renders there. The per-button label key becomes the CSS id (button#lock, button#logout, etc.); the text key becomes the label.action-name content. This plan does NOT populate text or add hover-reveal CSS (09-02's must-have truths require the rest state to be glyph-only) — this is 09-03's decision to make with the correct engine capability in hand."
  - "wlogout retirement is a repo/config change only (D-11): the wlogout/ stow package directory was deleted and the now-dangling ~/.config/wlogout symlink was removed, but pacman -Rns wlogout was never run — the retired binary stays installed on the machine, mirroring Phase 10-06's precedent for eww."

patterns-established:
  - "Empirical-first CSS debugging on wleave/GTK4: when a plan-specified selector or property doesn't behave as expected, launch the live compositor, read the config-mode debug log and any 'CSS Parse error' lines, and adjust based on what the installed binary actually accepts rather than what documentation assumes."

requirements-completed: [WLOG-01]

coverage:
  - id: D1
    description: "All three UI entry points (Super+Shift+Q keybind, both waybar custom/power layouts, elephant Power menu entry) invoke the new wleave.sh wrapper"
    requirement: "WLOG-01"
    verification:
      - kind: other
        ref: "grep -c 'hypr/scripts/wleave.sh' across modules.jsonc, config-floating.jsonc, main.toml, keybinds.conf == 4"
        status: pass
    human_judgment: false
  - id: D2
    description: "install.sh AUR_PKGS and stow.sh PACKAGES repointed from wlogout to wleave, same array positions, so a fresh Arch system reproduces the power menu with no host-only manual state"
    requirement: "WLOG-01"
    verification:
      - kind: other
        ref: "bash -n install.sh && bash -n stow.sh; grep assertions for a bare-indented wleave line in both arrays"
        status: pass
    human_judgment: false
  - id: D3
    description: "The version-info footer ('Wleave 0.7.0. Missing or broken icons?') no longer renders on the live surface"
    verification:
      - kind: manual_procedural
        ref: "evidence/09-02-version-info-fixed.png — fresh grim capture with the footer text absent, six capsules intact"
        status: pass
    human_judgment: true
    rationale: "Visual absence of rendered text on a live-compositor screenshot requires a human (or the 09-04 render gate) to confirm; not machine-verifiable beyond the config-key assertion already made in the automated checks."
  - id: D4
    description: "GTK3 wlogout engine retired from the repo/config surface: wlogout/ directory deleted, contract.json/theme-doctor/theme-stress-test repointed at wleave, VERIFICATION.md/.claude/CLAUDE.md prose updated, repo-wide grep for the retired name returns zero matches (excluding .planning/, .git/, settings.local.json)"
    requirement: "WLOG-01"
    verification:
      - kind: other
        ref: "grep -rIl 'wlogout' --exclude-dir=.planning --exclude-dir=.git --exclude=settings.local.json . | wc -l == 0"
        status: pass
      - kind: other
        ref: "python3 contract.json assertion: 'wleave.css' present, len(files)==18"
        status: pass
    human_judgment: false
  - id: D5
    description: "Full regression-gate sweep (theme-doctor, theme-parity, theme-stress-test, keybind-doctor) run and results honestly recorded, including two pre-existing unrelated failures that are NOT this plan's responsibility"
    verification:
      - kind: manual_procedural
        ref: "See 'Gate Sweep Results' section below — theme-parity rc=0, keybind-doctor rc=0, theme-doctor rc=1 (2 pre-existing unrelated failures), theme-stress-test aborts on the same pre-existing theme-doctor gate"
        status: unknown
    human_judgment: true
    rationale: "The gate sweep is genuinely mixed (some scripts pre-existingly tolerate FAIL lines and still exit 0, theme-doctor does not) and requires a human to confirm the wleave-specific portions are clean before accepting the deferred, unrelated failures as out of scope."

duration: ~50min (this continuation session; Task 1's tracer landed in a prior session)
completed: 2026-07-25
status: complete
---

# Phase 9 Plan 2: The Atomic wlogout → wleave Cutover Summary

**wleave 0.7.1 fully replaces wlogout as the desktop's power menu across all three UI entry points and both installer scripts, themed end-to-end through matugen, with the GTK3 engine's repo footprint fully retired — three genuine pre-existing, unrelated defects (an orphaned eww.scss contract entry, a broken hyprctl JSON parser, a permanently-dirty-tree check) discovered and deferred rather than silently absorbed into this plan's scope.**

## Performance

- **Duration:** ~50 min (this continuation session, Tasks 2-3; Task 1's tracer was executed and committed in the prior session, then approved at the tracer feedback gate)
- **Completed:** 2026-07-25T16:11:24Z
- **Tasks:** 3/3 (Task 1 tracer — prior session; Tasks 2-3 — this session)
- **Files modified:** 20 modified/created across the three task commits, plus the wlogout/ package (2 files) deleted

## Accomplishments

- **Task 1 (tracer, prior session, approved at the gate):** wired one complete path — keybind → layout.json → style.css → matugen render target → compositor layerrule → wrapper script — and proved it live against the compositor (`hyprctl -j layers` reports `wleave`, grim screenshot shows six correctly-ordered, correctly-glyphed capsules over a full-screen scrim).
- **Task 2:** repointed the remaining two waybar `custom/power` modules and the elephant `menus/main.toml` Power entry at `wleave.sh`; repointed `install.sh` AUR_PKGS and `stow.sh` PACKAGES from `wlogout` to `wleave` in the same array positions; reworded two dangling comments (autostart.conf clipboard note, ai-workspace.sh idiom citation) that named the retired script. Folded in the orchestrator-approved version-info footer fix using wleave's native `no-version-info` config key.
- **Task 3:** deleted the `wlogout/` stow package and its now-dangling `~/.config/wlogout` symlink; renamed the `contract.json` render-target entry; moved the deployed stylesheet from `theme-doctor`'s GTK3 to GTK4 sheet family (D-16); updated `theme-stress-test`'s representative-file list; reworded prose in `VERIFICATION.md` and `.claude/CLAUDE.md`; proved a repo-wide grep for the retired tool's name returns zero matches (one incidental hit — a rationale comment describing a past incident — reworded rather than left as a false-positive residual reference).

## Task Commits

Each task was committed atomically:

1. **Task 1: End-to-end tracer** — `7d0d98f` (feat) — prior session, approved by the human at the tracer feedback gate before this continuation began.
2. **Task 2: Repoint remaining entry points + close the reproducibility loop** — `4218659` (feat)
3. **Task 3: Retire the GTK3 engine, move regression-gate file lists** — `75ea48c` (feat)

**Plan metadata:** committed separately (see `<final_commit>`).

## Files Created/Modified

- `wleave/.config/wleave/layout.json` — six-button wrapped JSON schema (Task 1); `no-version-info: true` added (Task 2, orchestrator finding A)
- `wleave/.config/wleave/style.css` — transparent/scrim window, 96px capsules (Task 1); version-info suppression comment + defence-in-depth fallback rule added (Task 2)
- `hypr/.config/hypr/scripts/wleave.sh` — open-only launcher (Task 1)
- `matugen/.config/matugen/templates/wleave-colors.css` — 23-key M3 template (Task 1)
- `matugen/.config/matugen/config.toml` — `[templates.wleave]` registration (Task 1)
- `hypr/.config/hypr/config/windowrules.conf` — layerrules retargeted to `wleave` namespace (Task 1)
- `hypr/.config/hypr/config/keybinds.conf` — Super+Shift+Q repointed (Task 1)
- `waybar/.config/waybar/modules.jsonc`, `waybar/.config/waybar/config-floating.jsonc` — `custom/power` on-click repointed (Task 2)
- `elephant/.config/elephant/menus/main.toml` — Power entry repointed (Task 2)
- `install.sh`, `stow.sh` — `wlogout` → `wleave` in AUR_PKGS / PACKAGES (Task 2)
- `hypr/.config/hypr/config/autostart.conf`, `hypr/.config/hypr/scripts/ai-workspace.sh` — dangling comment citations reworded (Task 2)
- `theme-engine/.config/theme-engine/contract.json`, `theme-engine/.config/theme-engine/theme-doctor`, `theme-engine/.config/theme-engine/theme-stress-test` — render-target/gate-list repoint (Task 3)
- `VERIFICATION.md`, `.claude/CLAUDE.md` — prose repoint (Task 3)
- `wlogout/.config/wlogout/layout`, `wlogout/.config/wlogout/style.css` — **deleted** (Task 3)
- `theme-engine/.config/theme-engine/palettes/*.json` (all 20) — three new M3 container-role keys each (Task 1 deviation, discharging 09-01's blocking finding)
- `.planning/phases/09-wlogout-to-wleave-migration/deferred-items.md` — new; records the three pre-existing, out-of-scope issues found during verification
- `.planning/WINDOWS.md` — new; cross-phase defect ledger, two entries appended for the deferred items

## Decisions Made

See `key-decisions` in frontmatter above. Summary of the most consequential:

1. **Scrim selector re-diagnosis (Task 1, live-verified):** `window > box` does not fill the screen on this engine because wleave's `GtkCenterBox` content wrapper doesn't vertically expand — the scrim is painted on `window` itself instead.
2. **Button-stretch fix (Task 1, live-verified):** wleave's grid stretches buttons with no default aspect constraint — fixed with `button-aspect-ratio: 1.0` plus a percentage `margin` in `layout.json`.
3. **Static-palette container-role gap (Task 1, discharging 09-01's blocking finding):** all 20 palettes were missing 3 of 4 new M3 container-role keys — added with real derived hex, no literal fallbacks.
4. **Version-info footer (Task 2, orchestrator finding A, user-approved fold-in):** fixed via the native `no-version-info` config key after empirically confirming CSS `display: none` is unsupported on this GTK4 install.
5. **Version-string discrepancy (Task 1 finding, recorded not fixed):** `wleave --version` prints `0.7.0`; `pacman -Q wleave` correctly reports `0.7.1-1`. Upstream's own metadata lag, not a wrong install.
6. **D-08 correction for 09-03 (orchestrator finding C):** a native per-button second text slot (`label.action-name`, addressed via `button#<label>`) DOES exist, contradicting 09-01's conclusion. Not acted on in this plan — flagged for 09-03's decision.

## Deviations from Plan

### Auto-fixed / Adapted Issues

**1. [Rule 1 - Bug, empirically live-verified] Scrim selector doesn't produce a full-screen dim**
- **Found during:** Task 1 (prior session)
- **Issue:** The plan's `window > box` scrim rule only dims the button row's own height, not the full screen, because wleave's `GtkCenterBox` content wrapper doesn't vertically expand to fill the window by default.
- **Fix:** Paint the 0.40 black scrim on `window` directly (always sized to the full layer-shell surface); keep `window > box` as a transparent no-op so the capsule row is never double-tinted.
- **Files modified:** `wleave/.config/wleave/style.css`
- **Verification:** Live `hyprctl -j layers` + grim screenshot confirming full-screen dim.
- **Committed in:** `7d0d98f`

**2. [Rule 1 - Bug, empirically live-verified] Buttons stretch to fill grid cells with no aspect constraint**
- **Found during:** Task 1 (prior session)
- **Issue:** With no `button-aspect-ratio`/`margin` config, six buttons rendered as ~237px-tall stretched pills, not compact 96px capsules.
- **Fix:** `layout.json`'s `button-aspect-ratio: 1.0` (square) plus a percentage-based `margin: "36.4%"` (scales with monitor size) to hit the 6×96px+5×24px = 696px target.
- **Files modified:** `wleave/.config/wleave/layout.json`
- **Verification:** Live screenshot confirming 96px square capsules at the correct total width.
- **Committed in:** `7d0d98f`

**3. [Rule 2 - Missing Critical, discharging 09-01's blocking finding] Static palettes missing 3 of 4 new M3 container-role keys**
- **Found during:** Task 1 (prior session), predicted by 09-01
- **Issue:** matugen hard-errors resolving `on_tertiary_container`/`error_container`/`on_error_container` for every static preset (20/20), since none of the 20 palette JSON files had these keys.
- **Fix:** Added all three to every palette, derived from each palette's own hues (no invented literal hex).
- **Files modified:** all 20 files in `theme-engine/.config/theme-engine/palettes/`
- **Verification:** `theme-apply tokyonight` renders 23/23 colours, 0 unresolved tokens.
- **Committed in:** `7d0d98f`

**4. [Rule 2 - Missing Critical, orchestrator finding A, user-approved fold-in] version-info footer never addressed**
- **Found during:** Task 2, orchestrator spot-check of the tracer evidence
- **Issue:** wleave unconditionally renders a "Wleave 0.7.0. Missing or broken icons?" footer with CSS node name `version-info`. Not an error, not icon-related, always draws, visible in the tracer screenshot.
- **Fix:** First attempted a CSS `#version-info { display: none; }` rule — empirically failed (`CSS Parse error: ... No property named "display"`, confirmed via the live wleave debug log). Replaced with `layout.json`'s native top-level `"no-version-info": true` key, which is confirmed live in the config-mode debug log (`"no-version-info" specified from config: true`) to drop the widget entirely. A CSS-only fallback rule using properties GTK CSS does support (`opacity`, `font-size`, `min-width`, `min-height`, `padding`, `margin`, all `0`) is kept as defence-in-depth.
- **Files modified:** `wleave/.config/wleave/layout.json`, `wleave/.config/wleave/style.css`
- **Verification:** Fresh grim capture (`evidence/09-02-version-info-fixed.png`) confirms the footer text is gone and six capsules remain intact.
- **Committed in:** `4218659`

**5. [Rule 1 - Bug fix to a stale comment, discipline note compliance] theme-doctor's historical-incident comment named the retired tool**
- **Found during:** Task 3, repo-wide grep sweep
- **Issue:** A rationale comment in `theme-engine/.config/theme-engine/theme-doctor` describing a past GTK3 CSS-discard incident named the retired tool by name, which would have made the repo-wide grep report a false-positive residual reference.
- **Fix:** Reworded the comment to describe the incident ("the retired GTK3 power-menu engine's stylesheet") without naming the tool, per the plan's own discipline note about rationale comments in tracked source files.
- **Files modified:** `theme-engine/.config/theme-engine/theme-doctor`
- **Verification:** Repo-wide grep for the retired tool's name (excluding `.planning/`, `.git/`, `settings.local.json`) returns zero matches.
- **Committed in:** `75ea48c`

**6. [Rule 1-adjacent, host-state cleanup, not a repo change] Dangling ~/.config/wlogout symlink after package deletion**
- **Found during:** Task 3
- **Issue:** Deleting the `wlogout/` stow package directory left a dangling `~/.config/wlogout` symlink pointing at a now-nonexistent path.
- **Fix:** Removed the dangling symlink directly (`rm -f ~/.config/wlogout`) — a machine-state cleanup only, not a repo file change, and does not touch the still-installed `wlogout` binary (D-11).
- **Files modified:** none (host state only)
- **Verification:** `ls ~/.config/wlogout` now reports "No such file or directory."
- **Committed in:** n/a (host state, not a repo change)

---

**Total deviations:** 6 (2 Rule-1 live-verified bug fixes carried from Task 1's tracer, 1 Rule-2 missing-critical carried from Task 1, 1 Rule-2 missing-critical fold-in this session, 1 Rule-1 stale-comment fix, 1 host-state cleanup). All were necessary for correctness (scrim/capsule geometry, static-theme support, footer suppression, grep-sweep accuracy) or are pure cleanup with no repo-file footprint. No scope creep beyond the plan's declared touch-points.

## Gate Sweep Results (Task 3, run this session)

Per the plan's own instruction: green gates are **necessary but not sufficient** — every one of these gates passed in Phase 6 while the surface was visibly broken on screen. 09-04's human render-and-look gate remains the load-bearing control.

| Gate | Result | Notes |
|---|---|---|
| `theme-doctor` | **rc=1** (135 passed, 2 failed) | Every wleave-specific check PASSES: `CSS-parse: wleave/style.css (2343 bytes)`, the wleave GTK4 sheet is listed (not SKIP), all `custom/power` module-gates resolve. The 2 failures are **pre-existing and unrelated** to this plan (see Deferred Items below): an orphaned `eww.scss` contract entry from phase 08-06/10-06's incomplete eww retirement, and a `git status --porcelain is empty` check that cannot pass given this repo's pre-existing unrelated pending changes (wallpapers, `monitors.conf`, etc. — none of which this plan is scoped or permitted to touch). |
| `theme-parity` | **rc=0** (1542 passed, 22 failed) | All 22 failures are 100% `eww.scss`-scoped (`grep -c eww.scss` on FAIL lines == 22). Zero wleave-related failures. |
| `keybind-doctor` | **rc=0** (6 passed, 2 failed) | The 2 failures trace to a single pre-existing root cause: `hyprctl binds -j` emits malformed JSON on the installed Hyprland 0.56.0 (unquoted barewords, empty values) uniformly across all 78 binds, not specific to the wleave bind. Direct `grep` of the raw `hyprctl binds -j` output confirms the Super+Shift+Q bind IS registered with `"dispatcher": "exec"`, `"arg": "~/.config/hypr/scripts/wleave.sh"`. |
| `theme-stress-test` | **Aborted on switch #1** | Strictly requires `theme-doctor`'s exit code (D-66); blocked by the same 2 pre-existing failures above. Its precondition block and switch #1's `theme-apply catppuccin` step both passed before the abort — no wleave-specific failure occurred. |

**Repo-wide grep for the retired tool's name** (excluding `.planning/`, `.git/`, `settings.local.json`): **zero matches** — confirmed after rewording the one incidental historical-comment hit (deviation #5 above).

## Deferred Items (logged, NOT fixed — out of this plan's scope)

Full detail in `.planning/phases/09-wlogout-to-wleave-migration/deferred-items.md`; both also appended to `.planning/WINDOWS.md`:

1. **`keybind-doctor`'s `hyprctl binds -j` JSON parsing broken on Hyprland 0.56.0** — pre-existing, affects all 78 binds uniformly, not caused by this migration.
2. **This plan's own JSONC verify one-liner doesn't strip `/* */` block comments** — a limitation of the plan's verify command, not a real defect in the repo files (both waybar jsonc files parse cleanly with proper block-comment stripping).
3. **`theme-doctor`/`theme-stress-test` blocked by an orphaned `eww.scss` contract entry** — phase 08-06 added it, phase 10-06 retired eww's matugen template but never removed the `contract.json`/`theme-doctor` entry. A distinct, already-completed phase's incomplete cleanup; out of this plan's 18-item touch-point ledger.

None of these three items are caused by, or fixable within, this plan's declared scope (wlogout → wleave migration specifically). All are logged for separate future triage.

## Known Stubs

None. Every file this plan touches carries real, functional content — no hardcoded empty values flowing to UI rendering, no placeholder text, no unwired data sources.

## Issues Encountered

None beyond the deviations and deferred items documented above — all were anticipated categories of finding (empirical CSS/engine mismatches, pre-existing cross-phase debt) rather than unplanned problems with this plan's own approach.

## User Setup Required

None — this plan makes no external service configuration changes. The one host-state action (removing the dangling `~/.config/wlogout` symlink) was performed by the executor, not deferred to the user.

## Next Phase Readiness

**Ready for 09-03 (per-action hue identity / motion), with two must-address items carried forward:**

1. **D-08 correction (orchestrator finding C, corrects 09-01):** a native per-button second text slot (`label.action-name`, addressed via `button#<label>` id-selectors) DOES exist on wleave 0.7.1 — 09-01's "no free second text slot exists" conclusion was wrong. 09-03's checkpoint:decision on the hover-revealed action name should start from this corrected engine capability, not from 09-01's negative finding. wleave's own shipped default stylesheet (`/etc/wleave/style.css`) already proves the `button#<label>` id pattern and per-button colour via `--view-fg-color` — a concrete precedent to build on.
2. **Version-string discrepancy is cosmetic, not a blocker:** `wleave --version` prints `0.7.0` (upstream's own lagging metadata); `pacman -Q wleave` correctly confirms `0.7.1-1`. 09-04's render gate should not treat this as a wrong-version failure.
3. wleave surface is live, themed, and reachable from all three UI entry points; the theme pipeline renders 23/23 colours with zero unresolved tokens for both static presets and Material You. 09-03 can proceed directly to per-capsule tinted-frost-plus-on-colour pairing (D-03/D-04) without further pipeline work.
4. The three deferred items above are pre-existing and unrelated to the wlogout→wleave surface itself — they do not block 09-03 or 09-04, but should be triaged separately (likely as small standalone fix plans) before they accumulate further.

---
*Phase: 09-wlogout-to-wleave-migration*
*Completed: 2026-07-25*
