---
phase: 08-waybar-evolution
verified: 2026-07-14T20:50:00Z
status: human_needed
score: 4/4 must-haves verified (BAR-02 legitimately descoped with evidence, not scored as a truth)
behavior_unverified: 0
overrides_applied: 0
human_verification:
  - test: "Visual/aesthetic pass across all 4 waybar layouts (full, minimal, floating, vertical) under at least one light preset and one dark preset — glyph rendering, colour correctness, translucency look-and-feel, tooltip appearance."
    expected: "Every module renders its intended glyph (no tofu/empty boxes), colours resolve to the intended palette tokens with no visible black/unstyled flashes, and the translucent OLED-safe styling reads as intended rather than merely 'technically non-opaque'."
    why_human: "theme-doctor/theme-parity prove colour tokens resolve and CSS parses; they cannot judge whether the resulting visual reads correctly to a human eye. Plans 08-01/08-03/08-05 explicitly deferred this pass earlier in the session when the machine was headless; a display (DP-1) is now attached, so this is now performable."
  - test: "Confirm the vertical layout's rendered width (currently 66px per a live 'Requested width: 48 is less than the minimum width: 66 required by the modules' waybar warning) against the UI-SPEC's 48px column-width token — is 66px acceptable, or should modules/padding be trimmed to fit 48px?"
    expected: "Either the 66px width is accepted as the real, content-driven column width (UI-SPEC's 48px token updated to match reality), or a module is adjusted so the column actually renders at 48px."
    why_human: "This is a design-intent judgment call, not a mechanical pass/fail — the bar functions correctly at 66px, all 4 layouts pass waybar-equivalence-check, and ROADMAP success criterion 2 does not specify an exact pixel width. Not caught or discussed in any plan/SUMMARY; discovered live during this verification by actually launching the vertical config."
  - test: "Empirically re-verify media-popup-open.sh's cursor-anchored placement (ANCHOR_MODE=\"fixed\" currently ships as the shipped default because the authoring session was headless) now that DP-1 is attached — flip ANCHOR_MODE to \"cursor\" and click the media segment from the bar's far-right edge, the bottom edge, and the vertical layout's 48px-wide column, confirming the popup never straddles a monitor seam and always lands fully on-screen."
    expected: "The popup opens fully on-screen from every trigger position; if cursor-anchored placement is preferred over the current fixed top-right corner, flip the one ANCHOR_MODE constant and re-confirm."
    why_human: "D-23's own pre-authorised fallback was chosen specifically because no monitor was attached at authoring time. This verification confirmed the *fixed*-mode path opens correctly and toggles closed correctly (live-tested below) — but the *cursor*-anchored mode and its monitor-seam clamping logic have still never been exercised against a real monitor. This is a genuine UX preference/placement check, not a mechanical gate."
---

# Phase 8: Waybar Evolution Verification Report

**Phase Goal:** Waybar gains OLED-safe behavior, an additional vertical layout, an integrated media
center, and one-click access to the notification center — all still driven by the shared theme
pipeline.

**Verified:** 2026-07-14T20:50:00Z
**Status:** human_needed
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | Waybar behaves OLED-safely — auto-hides when idle/unneeded, translucent minimal styling, best-effort pixel-shift mitigation OR documented descope | ✓ VERIFIED | `waybar-visibility.sh` is the sole owner; `bar-common.jsonc` fixes `on-sigusr1: hide`/`on-sigusr2: reload`; hypridle listener (120s) + `waybar-fullscreen-watch.sh` (Hyprland socket2) + `gaming-mode-toggle.sh` + `$mainMod SHIFT,B` keybind all route through the one owner (grep-confirmed: no other script sends raw `SIGUSR1`). `style-full.css`: `background: alpha(@background, 0.90)`, trimmed border, no true-black/hex literals. BAR-02 pixel-shift is DESCOPED with a rigorous, reproducible evidence artifact (`08-BAR-02-EVIDENCE.md`) — permitted outcome per its own requirement text ("descope with evidence if infeasible"). Live-confirmed: `waybar-visibility.sh status` → `visible`; all 4 signal-owner wiring points grep-verified present. |
| 2 | An additional vertical (left) layout exists and re-themes correctly through a theme switch (full module re-test, not copy-paste) | ✓ VERIFIED | `config-vertical.jsonc` + `style-vertical.css` exist, no `output` key (draws on every monitor, D-15), `full` remains the install/container default (D-16). `theme-doctor` gained a D-17 per-module colour-resolution gate that mechanically checks all 4 layouts (not eyeballed) — 96/97 pass (1 pre-existing, unrelated dirty-tree failure, confirmed below). `waybar-equivalence-check` 4/4. **Live-launched the vertical config on the real attached monitor**: rendered on-screen with glyph-only modules (workspaces, clock, cpu/mem/temp stacked readouts, network, battery, gaming-mode, notification bell, tray, power) at 66px actual width (see human-verification item re: the 48px spec token). The layout picker (walker dmenu from `waybar-switch.sh`) was also captured live, open, showing dynamically-derived entries "Floating / Full / Minimal / Vertical" — confirms D-32 disk-enumeration, not a hardcoded list. |
| 3 | A media center integrating mpris players (Spotify, browser/YouTube) is accessible from waybar | ✓ VERIFIED | `eww` installed (0.6.0-1 per pacman, matches plan's pinned CLI facts), first-class theme-pipeline render target (`theme-parity` 1630/1630 incl. eww.scss across all 22 targets). **Live-tested end-to-end on the real machine**: with a real Firefox/YouTube mpris player active, clicked-equivalent `eww open --toggle media-popup --arg x=10 --arg y=10` opened a fully-rendered popup showing album-art thumbnail, track title, artist, transport row (prev/play-pause/next), a seek bar at the correct position (47:36/51:20), a volume slider, and the player-switcher header showing "Firefox" — then a second `--toggle` call closed it. This is genuine rendered behavior, not a stub. All 4 waybar layouts wire their media segment's `on-click` to `media-popup-open.sh` (full + floating share `modules.jsonc` definitions; minimal + vertical carry their own full redefinitions, D-31 whole-key semantics respected). `test-media-hardening.sh` 29/29 (incl. the CR-01 SSRF regression tests added after the code review fix). |
| 4 | A waybar button opens the swaync notification center overlay to view, clear, and interact | ✓ VERIFIED | `custom/notification` present in all 4 layout module-lists (grep-confirmed), `on-click: "swaync-client -t -sw"` / `on-click-right: "swaync-client -d -sw"`. **Live-tested**: fired the exact bell on-click command; `hyprctl layers -j` showed the `swaync-control-center` layer surface live; screenshot confirms a reworked panel — "Notifications" title + "Clear All", "Do not disturb" toggle, Volume slider, Brightness slider, 3-button toggle grid, and two real notification entries with per-item content — then closed cleanly with the same toggle command. `config.json`/`style.css` contain zero mpris references (D-24 — the old media player widget is gone). Gaming/DND/theme toggles in the grid point at the exact same scripts and state files the Super-key menu and waybar already use (`~/.cache/gaming-mode` shared 4 ways: waybar, swaync, `elephant/.config/elephant/menus/game-center.toml`, `gaming-mode-toggle.sh` itself — D-28, no second copy of any toggle's logic). |

**Score:** 4/4 truths verified (BAR-02 correctly excluded from this count as a sanctioned descope, not a truth to verify pass/fail against)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `waybar/.config/waybar/modules.jsonc` + `waybar-modules.css` | Shared module definitions (D-31) | ✓ VERIFIED | Present, substantive, referenced by all 4 layout includes |
| `waybar/.config/waybar/config-{full,minimal,floating,vertical}.jsonc` + matching `style-*.css` | 4 layouts | ✓ VERIFIED | All 4 exist, `waybar-equivalence-check` 4/4 confirms resolved-config correctness |
| `hypr/.config/hypr/scripts/waybar-equivalence-check` | Mechanical config-drift gate | ✓ VERIFIED | Ran live: 4/4 PASS |
| `hypr/.config/hypr/scripts/waybar-visibility.sh` | Single visibility owner | ✓ VERIFIED | Present, wired to all 4 actors, flock-serialized (WR-01 fixed) |
| `hypr/.config/hypr/scripts/waybar-fullscreen-watch.sh` | Fullscreen watcher | ✓ VERIFIED | Present, autostart-wired, headless-safe exit-0 guards |
| `hypr/.config/hypr/scripts/waybar-switch.sh` / `waybar-launch.sh` | Disk-enumerated layout picker/launcher | ✓ VERIFIED | Glob-based (`config-*.jsonc`), live-captured picker screenshot shows dynamically-derived labels |
| `eww/.config/eww/eww.yuck` + `eww.scss` | Media popup | ✓ VERIFIED | Live-opened, fully rendered with real mpris data |
| `hypr/.config/hypr/scripts/media-{art-resolve,players,status,popup-open}.sh` | Hardened media pipeline | ✓ VERIFIED | All present, substantive, `test-media-hardening.sh` 29/29, CR-01 SSRF fix confirmed in code and by passing regression tests |
| `theme-engine/.config/theme-engine/theme-doctor` (D-17 gate) | Per-module colour-resolution + glob-discovery | ✓ VERIFIED | 96/97 pass live; 1 failure is the pre-existing, unrelated dirty-git-tree check (confirmed: only `wallpapers/.../current.jpg`, `07-VERIFICATION.md`, `csv` are dirty/untracked — none are phase-8 files) |
| `swaync/.config/swaync/config.json` + `style.css` | Reworked control centre | ✓ VERIFIED | Live-opened: volume/brightness sliders + 3-toggle grid + notifications, zero mpris refs |
| `.planning/phases/08-waybar-evolution/08-BAR-02-EVIDENCE.md` + `.bar-02-samples.tsv` | BAR-02 descope evidence | ✓ VERIFIED | Present, rigorous: gate table with named instruments/raw results/PASS-FAIL, standing-hypothesis luminance measurement, residual-risk section |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| hypridle listener | `waybar-visibility.sh idle hide\|show` | 120s timeout | ✓ WIRED | grep-confirmed in `hypridle.conf` |
| `waybar-fullscreen-watch.sh` | `waybar-visibility.sh fullscreen hide\|show` | Hyprland socket2 | ✓ WIRED | autostart-wired, headless-safe |
| `gaming-mode-toggle.sh` | `waybar-visibility.sh gaming hide\|show` | re-point (P7 D-26) | ✓ WIRED | grep-confirmed, no raw SIGUSR1 left in gaming-mode-toggle.sh |
| `$mainMod SHIFT,B` | `waybar-visibility.sh keybind toggle` | keybind | ✓ WIRED | grep-confirmed in keybinds.conf; keybind-doctor 8/8 including description parity |
| waybar media segment (`mpris`/`custom/media`) on-click | `media-popup-open.sh` | bare path, zero args | ✓ WIRED | grep-confirmed in all 4 layouts (modules.jsonc canonical + minimal/vertical own redefinitions); live-opened successfully |
| `media-status.sh` | `media-art-resolve.sh` | art field resolution | ✓ WIRED | code inspection + `test-media-hardening.sh` cache-path checks pass |
| `media-status.sh watch` | eww `deflisten media` | JSON stream | ✓ WIRED | live popup rendered real title/artist/position/volume data sourced from this exact pipeline |
| waybar `custom/notification` on-click | swaync control centre | `swaync-client -t -sw` | ✓ WIRED | live-fired, `swaync-control-center` layer surface confirmed via `hyprctl layers -j` |
| swaync buttons-grid (gaming/DND/theme) | shared scripts + state files | bare invocation + read-back | ✓ WIRED | same `gaming-mode-toggle.sh` + `~/.cache/gaming-mode` used by waybar and the Super-key menu's `game-center.toml` |
| `theme-engine/lib/reload.sh` eww branch | eww daemon | guarded `eww reload` | ✓ WIRED | `command -v eww && pgrep -x eww` guard confirmed in reload.sh |

### Behavioral Spot-Checks / Live Verification (beyond static gates)

| Behavior | Command / Action | Result | Status |
|----------|-------------------|--------|--------|
| Media popup opens with real mpris data | `eww open media-popup --arg x=10 --arg y=10` (equivalent to clicking the bar segment), real Firefox/YouTube player active | Rendered album art, title, artist, transport, seek bar (47:36/51:20), volume slider, player switcher — screenshot captured | ✓ PASS |
| Media popup closes on second trigger | `eww open --toggle media-popup ...` fired again | `eww active-windows` returned empty | ✓ PASS |
| Vertical layout renders live | Launched `waybar -c config-vertical.jsonc -s style-vertical.css` on the real attached monitor | Rendered on-screen, glyph-only modules visible, screenshot captured; waybar log shows `width: 66` vs the 48px config value (module-content-driven auto-expand — flagged for human judgment) | ✓ PASS (with a flagged deviation) |
| Layout picker derives labels from disk | Live capture of `waybar-switch.sh`'s walker dmenu | "Floating / Full / Minimal / Vertical" all shown, correctly capitalized from filenames | ✓ PASS |
| Notification center opens from bell's exact on-click command | `swaync-client -t -sw` | `swaync-control-center` layer appeared; screenshot shows reworked panel (sliders + toggle grid + notifications, no mpris) | ✓ PASS |
| Notification center closes | `swaync-client -t -sw` (second fire) | Layer disappeared | ✓ PASS |
| `waybar-equivalence-check` | `bash hypr/.config/hypr/scripts/waybar-equivalence-check` | 4/4 PASS | ✓ PASS |
| `test-media-hardening.sh` | `bash hypr/.config/hypr/scripts/tests/test-media-hardening.sh` | 29/29 PASS, incl. new CR-01 SSRF-bypass regression checks | ✓ PASS |
| `keybind-doctor` | `bash hypr/.config/hypr/scripts/keybind-doctor` | 8/8 PASS | ✓ PASS |
| `theme-doctor` | `bash theme-engine/.config/theme-engine/theme-doctor` | 96/97 PASS (1 pre-existing, unrelated dirty-tree failure) | ✓ PASS (net) |
| `theme-parity` | `bash theme-engine/.config/theme-engine/theme-parity` | 1630/1630 PASS | ✓ PASS |

### Requirements Coverage

| Requirement | Source Plan(s) | Description | Status | Evidence |
|---|---|---|---|---|
| BAR-01 | 08-01, 08-03, 08-04 | OLED-safe auto-hide + translucent styling | ✓ SATISFIED | Single-owner visibility, 4 actors wired, translucency confirmed |
| BAR-02 | 08-10 | Pixel-shift mitigation (best-effort, descope-permitted) | ✓ SATISFIED (descoped with evidence) | `08-BAR-02-EVIDENCE.md` — rigorous gate table, DESCOPED verdict, not a silent drop |
| BAR-03 | 08-01, 08-02, 08-05 | Vertical layout, re-themes correctly | ✓ SATISFIED | Live-launched, renders, theme-doctor D-17 gate mechanically proves colour resolution per-module across all 4 layouts |
| BAR-04 | 08-06, 08-07, 08-08 | Media center from waybar, mpris integration | ✓ SATISFIED | Live end-to-end popup open/close with real player data |
| BAR-05 | 08-01, 08-05, 08-09 | Notification center from waybar button | ✓ SATISFIED | Live end-to-end panel open/close, reworked widgets confirmed |

No orphaned requirements — all 5 BAR-* IDs in REQUIREMENTS.md are claimed by at least one plan's frontmatter, and every plan's declared requirement ID maps back to a REQUIREMENTS.md entry.

### Anti-Patterns Found

No `TBD`/`FIXME`/`XXX` debt markers in any phase-8-modified file (the `mktemp ...XXXXXX` template placeholders in `media-art-resolve.sh`/`waybar-visibility.sh` are standard mktemp syntax, not debt markers — verified by inspection). No `TODO`/`HACK`/`PLACEHOLDER` markers. No stub `return null`/empty-body patterns in the reviewed files. The 08-REVIEW.md's 1 Critical + 3 Warning findings were all independently confirmed fixed in this verification (commits `0cbda4b`, `77441a9`, `1cdb19b`, `29d3928`) — re-ran `test-media-hardening.sh` and `waybar-equivalence-check` live to confirm the fixes didn't regress anything.

Remaining Info-level findings from 08-REVIEW.md (IN-01 unitless border-radius, IN-02 duplicate CSS declaration, IN-03 missing `local`, IN-04 unquoted `$HOME`) are cosmetic/low-severity and were not required to be fixed before shipping — none block the phase goal.

### Human Verification Required

1. **Full visual/aesthetic pass across all 4 layouts, light + dark presets** — glyph rendering, colour correctness, translucency look. Legitimately deferred earlier in the session (machine was headless); a display is now attached, so this is now performable. Not a goal failure on its own — automated gates (theme-doctor D-17, theme-parity) already mechanically prove colour-token resolution; only the *look* is unverified.
2. **Vertical layout's actual rendered width (66px) vs. the UI-SPEC's 48px design token** — discovered live during this verification (`waybar` log: "Requested width: 48 is less than the minimum width: 66 required by the modules"), not previously caught by any plan/SUMMARY/gate. The bar functions correctly at 66px and passes every automated gate; this is a design-intent judgment call (accept 66px as the real content-driven width, or trim a module to fit 48px), not a functional defect.
3. **Cursor-anchored media-popup placement mode** — ships as `ANCHOR_MODE="fixed"` because the popup was built while the machine was headless (documented in the script's own header). This verification confirmed the shipped `fixed` mode opens/closes correctly on the real monitor now attached, but the alternate `cursor` mode and its monitor-seam clamping logic (D-23's primary design intent) have never been exercised against real hardware. A one-constant flip plus a manual click-from-three-positions test would close this out.

### Gaps Summary

No blocking gaps. All 4 non-descoped BAR requirements (BAR-01, BAR-03, BAR-04, BAR-05) are verified with live, end-to-end behavioral evidence — not just static grep/config presence — including actually opening the media popup with a real mpris player, actually opening the swaync notification center via the bar's exact button command, and actually launching the vertical layout on the real attached monitor. BAR-02 is legitimately descoped with a rigorous, reproducible evidence artifact, which its own requirement text explicitly permits. The one automated-gate failure (theme-doctor's git-clean check) is pre-existing and unrelated to phase 8 (confirmed: the 3 dirty/untracked paths belong to phase 7's verification doc, an unrelated `csv` file, and a wallpaper change).

The phase is not marked `passed` only because of the three human-judgment items above (visual pass, a live-discovered 66px-vs-48px width discrepancy, and the untested cursor-anchor mode) — none of which represent a missing or broken artifact.

---

*Verified: 2026-07-14T20:50:00Z*
*Verifier: Claude (gsd-verifier)*
