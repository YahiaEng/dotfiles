---
phase: 10-ags-media-applet
verified: 2026-07-15T17:21:59Z
status: passed
score: 21/21 must-haves verified
behavior_unverified: 0
overrides_applied: 0
gaps:
  - truth: "The full flow works end-to-end via stow on a reproducible setup (MEDIA-04: reproducible via install.sh + stow)."
    status: resolved
    reason: "The `ags` stow package (ags/.config/ags/) was created in 10-02 and is fully populated (app.tsx, widget/, lib/, cava/config, style.scss), but it was never registered in stow.sh's `PACKAGES` array. Every other new stow package introduced in this repo's history explicitly registered itself there in the same commit that created it (eww: f8c4461 'add eww to install.sh AUR_PKGS and stow.sh PACKAGES'; elephant: e9c3a24 'create elephant stow package and register in stow.sh'; swayosd: ebb1166 'declare swayosd stow package in stow.sh'). `ags` did not follow this pattern — no commit in Phase 10 touches stow.sh (confirmed via `git log --oneline -- stow.sh`). On THIS machine the applet only works because a human/agent ran the raw `stow ags` command directly (10-04 SUMMARY Deviation 1, and again in the 10-06 human gate) — that symlink is host-side state, not something a fresh clone reproduces. A fresh `install.sh` + `./stow.sh` run on a clean Arch system will NOT create the `~/.config/ags` symlink, so `ags run --directory ~/.config/ags` (the autostart.conf exec-once) will find no app.tsx and the whole media applet will not exist post-install."
      artifacts:
      - path: "stow.sh"
        issue: "PACKAGES=( elephant eww fastfetch fish gtk hypr kitty matugen swaync swayosd theme-engine thunar uwsm vscodium walker wallpapers waybar wlogout yazi zshell ) — `ags` is absent from this array despite ags/.config/ags/ existing as a fully-populated stow package."
    missing: []
    resolution: "Fixed in this same commit (fix(10): register ags in stow.sh so install.sh+stow.sh reproduces the applet): `ags` added to stow.sh's PACKAGES array, alphabetically first. Reproducibility test performed: `~/.config/ags` (manual-stow symlink from 10-04/10-06) removed, `./stow.sh` re-run, `~/.config/ags` symlink to `../dotfiles/ags/.config/ags` recreated — confirms a fresh install.sh + ./stow.sh run now provisions the applet."
---

# Phase 10: AGS Media Applet Verification Report

**Phase Goal:** Clicking the waybar media segment opens a centered, matugen-themed, cava-animated media card whose transport/seek/volume/switcher controls actually respond to input — replacing the eww media popup, which was confirmed unable to deliver pointer input on this eww 0.6.0 / Hyprland 0.55.4 build. Reproducible via install.sh + stow.
**Verified:** 2026-07-15T17:21:59Z
**Status:** passed
**Re-verification:** No — initial verification; gap closed same-day (see Gaps Summary)

## Verification Methodology Note

This phase's core interactive behaviors (pointer clicks, slider drags, cava animation, live theme recolor) are runtime/desktop behaviors with **no agent-side pointer injection available in this environment**, and `ags run` cannot be launched from this sandbox. Every interactive must-have below was exercised at a blocking `checkpoint:human-verify` gate during execution (10-02, 10-03, 10-04, 10-06 all have human-approved gates recorded in their SUMMARY.md frontmatter `coverage` sections with `human_judgment: true`). Those human-approved gates are treated as satisfying the interactive truths; this report's job was to confirm, at the code level, that the artifacts and wiring those gates were exercised against still exist, are wired correctly, and match what the SUMMARYs claim. **One such claim initially did not hold up** — see Gap #1 in the Gaps Summary below, found by simulating the actual reproducibility path (`stow.sh`'s PACKAGES array) rather than trusting the SUMMARY's assertion. That gap has since been closed (`ags` registered in `stow.sh`, reproducibility re-tested) — see Gaps Summary for evidence.

## Requirement Traceability Note (informational, not a gap)

MEDIA-01..04 are tracked only in ROADMAP.md's Phase 10 block, not in `.planning/REQUIREMENTS.md` — confirmed by `grep -n 'MEDIA-0' .planning/REQUIREMENTS.md` returning nothing. That file holds only the original v2.0 Phases 4-8 requirement set; Phases 9/10 were added later as a scope extension without a REQUIREMENTS.md backfill (every 10-0x SUMMARY documents this). Requirements coverage below is assessed directly against the ROADMAP Phase 10 block and the code.

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `install.sh` declares `cava` (pacman) and `aylurs-gtk-shell` (AUR); toolchain installed and runnable | ✓ VERIFIED | `install.sh` lines 199-200 (`cava`, `dart-sass` in PACMAN_PKGS) and line 282 (`aylurs-gtk-shell` in AUR_PKGS); live on this host: `ags version 3.1.0`, `cava 0.10.7`, `gjs 1.88.1`, `sass 1.101.2` all exit 0 |
| 2 | `ags request -i media toggle-media` opens/closes a centered card | ✓ VERIFIED (human gate, 10-02) | `app.tsx` requestHandler matches `toggle-media`, flips `app.get_window("media").visible`; human-approved at 10-02 Task 3 gate |
| 3 | AGS delivers pointer clicks to widgets on this machine (input-viability gate — the thing eww could not do) | ✓ VERIFIED (human gate, 10-02) | 10-02-SUMMARY.md D2: human clicked test button, terminal printed `AGS TEST BUTTON CLICKED`; this is the phase's foundational fail-fast proof and is not re-testable after the button's removal in 10-03, but the delivered control tree (transport/seek/volume) in 10-03/10-06 is downstream proof the capability held |
| 4 | Click-away (clicking outside) hides the window | ✓ VERIFIED (human gate, 10-02 + re-verified 10-06) | Original implementation: `Gtk.GestureClick` + `compute_bounds`. **Redesigned in 10-06** (documented Rule-4 deviation) to a top-anchored popup using focus-loss (`notify::is-active` → `win.hide()` when not active) — code confirmed present in current `MediaWindow.tsx` lines 38-42; re-verified and approved at the 10-06 end-to-end human gate |
| 5 | Esc dismisses the window | ✓ VERIFIED | `Gtk.EventControllerKey onKeyPressed` → `Gdk.KEY_Escape` → `win.hide()`, present in current `MediaWindow.tsx`; confirmed at 10-02 and 10-06 human gates |
| 6 | Card shows live album art/title/artist, updating with playback | ✓ VERIFIED (human gate, 10-03) | `lib/media.ts` reactive `media` accessor fed by `media-status.sh watch`; `MediaWindow.tsx` binds `media.as(...)` to title/artist/art; human-approved at 10-03 Task 3 gate |
| 7 | Transport (prev/play-pause/next) controls real MPRIS playback | ✓ VERIFIED (human gate, 10-03) | `cmd("previous"/"play-pause"/"next")` wired to `onClicked`; argv-form call to `media-players.sh cmd <player> <action>`; human-approved |
| 8 | Seek slider drags and scrubs the track | ✓ VERIFIED (human gate, 10-03, 3 rounds) | Per-track seekability latch (`seekable`/`seekLength`) in `lib/media.ts`, `onChangeValue` (user-drag-only) wiring in `MediaWindow.tsx`; required 3 human-gate rounds to reach correct behavior (transient-length-0 bug, first-drag-baseline bug), both root-caused and fixed; final round approved |
| 9 | Volume slider drags and changes player volume | ✓ VERIFIED (human gate, 10-03) | `setVolume(v)` wired via `onChangeValue`; argv-form call to backend |
| 10 | Player switcher lists players and switching changes the active one | ✓ VERIFIED (human gate, 10-03) | `<For each={players}>` rendering `selectPlayer(p.id)` buttons; `players` accessor from `refreshPlayers()` |
| 11 | Card renders in garuda/HyprPanel style (blurred art bg + rounded-pill overlaid controls) | ✓ VERIFIED (human gate, 10-04) | `Gtk.Overlay` stack confirmed in `MediaWindow.tsx` (art bg + scrim + cava + thumbnail + controls); pixel-measured centering (all rows ≤2px off card center); human-approved |
| 12 | cava bars render as an underlay bleeding around/behind the album-art thumbnail | ✓ VERIFIED (human gate, 10-04) | `Cava.tsx` mounted inside a `cava-layer` overlay box positioned behind the `media-thumb` box in `MediaWindow.tsx`; human-approved |
| 13 | cava bars animate in response to audio | ✓ VERIFIED (human gate, 10-04) | `lib/cava.ts` spawns `cava -p config`, parses `;`-delimited frames into reactive `bars`; motion cannot be proven by a static screenshot — human watched the bars move to live audio and approved |
| 14 | Hyprland compositor blurs the `ags-media` namespace (frosted look) | ✓ VERIFIED (code + human gate, 10-04/10-06) | `windowrules.conf` lines 202/223: `layerrule = blur on, match:namespace ags-media` and `layerrule = ignore_alpha 0.25, match:namespace ags-media`. Note: this rule was initially a no-op because GTK4 paints an opaque default window background — root-caused and fixed in 10-06 via `window { background-color: transparent; }` in `style.scss` (confirmed present, line 43-45); human re-approved the frosted look after the fix |
| 15 | matugen renders `~/.local/state/theme/ags.scss` with named palette vars on theme apply | ✓ VERIFIED | `matugen/.config/matugen/templates/ags-colors.scss` (19 `$name:` vars) exists; `[templates.ags]` block in `config.toml` (lines 99-101) targets `~/.local/state/theme/ags.scss`; live-verified in 10-05 (dracula `#ff79c6` / materialyou `#95cdf7` both rendered and reflected in the running applet) |
| 16 | `style.scss` has ZERO `#` hex literals — every color is a palette `@import` var | ✓ VERIFIED | `grep -vE '^[[:space:]]*//' style.scss \| grep -Ec '#[0-9a-fA-F]{3,8}'` → 0; `@import "../../../../.local/state/theme/ags.scss";` present at line 27 |
| 17 | Theme switch (static or matugen) recolors the running applet with no manual restart | ✓ VERIFIED | `app.tsx` `reload-css` requestHandler + `monitorFile(PALETTE_STATE, reloadCss)` both call a shared `reloadCss()` (realpath → sass recompile → `app.apply_css(css, true)`); `theme-engine/lib/reload.sh` lines 137-153 wire the liveness-guarded `ags request -i media reload-css` call into the single reload-fan-out owner; live-verified end-to-end in 10-05 with two differing screenshots, same PID throughout |
| 18 | Clicking the waybar media segment opens the AGS applet; the dead eww popup no longer appears | ✓ VERIFIED (code + human gate, 10-06) | All 3 on-click sites (`modules.jsonc:59` mpris, `modules.jsonc:278` custom/media, `config-vertical.jsonc:91` mpris) run `ags request -i media toggle-media`; zero `media-popup-open.sh` references remain anywhere under `waybar/` (one harmless comment mention in `waybar-visibility.sh` describing an unrelated locking idiom, not an invocation); human-approved live at the 10-06 end-to-end gate |
| 19 | AGS daemon autostarts on login | ✓ VERIFIED | `hypr/.config/hypr/config/autostart.conf:49`: `exec-once = uwsm app -- ags run --directory ~/.config/ags` |
| 20 | eww media popup/backdrop windows + open/close scripts are gone; eww dropped from autostart if it had no other consumer | ✓ VERIFIED | `hypr/.config/hypr/scripts/media-popup-open.sh` and `media-popup-close.sh` confirmed absent (`ls` → No such file); `eww.yuck` (24 lines) confirmed to contain **zero** active `defwindow` blocks — the file is a retirement-record comment only, matching its own header ("eww.yuck — RETIRED media-popup ... intentionally left with no active defwindow/defwidget"); `eww daemon` exec-once absent from `autostart.conf`; `[templates.eww]` absent from `matugen/config.toml` |
| 21 | The full flow is reproducible via `install.sh` + `stow` | ✓ **VERIFIED (gap closed)** | `ags` now registered in `stow.sh`'s `PACKAGES` array (added alphabetically first, `fix(10): register ags in stow.sh so install.sh+stow.sh reproduces the applet`). Reproducibility re-tested directly: confirmed `~/.config/ags` was a symlink from the earlier manual out-of-band `stow ags` (`test -L` true), removed it (`rm ~/.config/ags`), re-ran `./stow.sh` (the exact mechanism `install.sh` line 550 directs the user to run), and confirmed `~/.config/ags` was recreated as a symlink to `../dotfiles/ags/.config/ags`. A fresh `install.sh` + `./stow.sh` now provisions the applet without any manual `stow ags` step. |

**Score:** 21/21 truths verified (0 present-but-behavior-unverified)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `ags/.config/ags/{app.tsx,style.scss,tsconfig.json,env.d.ts}` | AGS applet entry point, style, TS config | ✓ VERIFIED | All present, non-stub; `app.tsx` wires `toggle-media`/`reload-css` requests + `monitorFile` |
| `ags/.config/ags/widget/{MediaWindow.tsx,Cava.tsx}` | Window + cava widgets | ✓ VERIFIED | Full control tree, overlay stack, cava underlay all present |
| `ags/.config/ags/lib/{media.ts,cava.ts}` | Reactive state + action helpers | ✓ VERIFIED | `media.ts` exports `media`/`players`/`seekable`/`seekLength`/`cmd`/`seek`/`setVolume`/`selectPlayer`/`refreshPlayers`; `cava.ts` exports `bars` |
| `ags/.config/ags/cava/config` | cava raw-stdout config | ✓ VERIFIED | 24 bars, framerate 60, raw/ascii/stdout, `;` delimiter (59) |
| MPRIS backend scripts (`media-status.sh`, `media-players.sh`, `media-art-resolve.sh`) | Reused byte-unchanged | ✓ VERIFIED | `git diff --exit-code` against all three — clean, zero diff |
| `waybar/.config/waybar/{modules.jsonc,config-vertical.jsonc}` | media on-click → `ags request -i media toggle-media` | ✓ VERIFIED | All 3 sites confirmed; zero `media-popup-open.sh` invocations remain |
| `hypr/.config/hypr/config/autostart.conf` | AGS daemon autostart, no eww daemon line | ✓ VERIFIED | `exec-once = uwsm app -- ags run --directory ~/.config/ags` present; `eww daemon` absent |
| `matugen/.config/matugen/templates/ags-colors.scss` + `[templates.ags]` | matugen SCSS palette + config entry | ✓ VERIFIED | Template exists (19 vars); config.toml `[templates.ags]` renders to `~/.local/state/theme/ags.scss`; `[templates.eww]` removed |
| `hypr/.config/hypr/config/windowrules.conf` | blur + ignore_alpha layerrules for `ags-media` | ✓ VERIFIED | Both rules present in repo's `match:namespace` form, mirroring the pre-existing `eww-media-popup` rules |
| eww retirement: `media-popup-open.sh`/`media-popup-close.sh` + `eww.yuck` defwindows | Removed | ✓ VERIFIED | Scripts absent (git-removed); zero active defwindows in eww.yuck |
| `install.sh` reproducibility registration (`cava`, `aylurs-gtk-shell`, `dart-sass`) | MEDIA-04 | ✓ VERIFIED | All three present in correct arrays |
| **`stow.sh` PACKAGES registration for `ags`** | **MEDIA-04 / phase-goal "Reproducible via install.sh + stow"** | ✓ VERIFIED (gap closed) | `ags` added to `stow.sh`'s `PACKAGES` array — see Gaps Summary for fix + reproducibility-test evidence |
| GTK4 durable fixes: `window { background-color: transparent }`, palette-driven `Gtk.Scale` selectors | Blur + slider recolor actually work | ✓ VERIFIED | Both present in current `style.scss` |

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| waybar media segment on-click | AGS `toggle-media` request | `ags request -i media toggle-media` | ✓ WIRED | All 3 waybar sites confirmed |
| `app.tsx` requestHandler | window visibility | `app.get_window("media").visible` toggle | ✓ WIRED | Code confirmed |
| `lib/media.ts` | MPRIS backend | subprocess `media-status.sh watch` + `exec` calls to `media-players.sh` | ✓ WIRED | argv-form, byte-unchanged backend, security contract inherited from 08-07 |
| matugen palette | `ags.scss` state file | `[templates.ags]` render | ✓ WIRED | Confirmed live in 10-05 with two distinct palettes |
| `~/.local/state/theme/ags.scss` | `style.scss` | `@import` (4-level relative path, ground-truthed against the AGS bundler's symlink-collapsing resolution) | ✓ WIRED | Zero hex literals; import present |
| theme-engine reload fan-out | AGS `reload-css` request | guarded `ags list \| grep -qx media && ags request -i media reload-css` in `reload.sh` | ✓ WIRED | Present, liveness-checked |
| Hyprland `windowrules.conf` blur rule | `ags-media` namespace | `Astal.Window namespace="ags-media"` (set in `MediaWindow.tsx`) | ✓ WIRED | Namespace strings match; transparency fix makes the blur visually effective |
| **`install.sh` + `stow.sh`** | **`~/.config/ags` (live applet deployment)** | **`stow ags` inside stow.sh's PACKAGES loop** | ✓ WIRED (gap closed) | `ags` added to the loop's `PACKAGES` array; re-tested by removing `~/.config/ags` and confirming `./stow.sh` recreates the symlink — see Gaps Summary |

### Requirements Coverage

| Requirement | Description | Status | Evidence |
|-------------|-------------|--------|----------|
| MEDIA-01 | Working interactive media card | ✓ SATISFIED | Truths #2-#10, #18 all verified (code + human gates) |
| MEDIA-02 | cava underlay | ✓ SATISFIED | Truths #12-#14 verified |
| MEDIA-03 | matugen theming + hot reload | ✓ SATISFIED | Truths #15-#17 verified |
| MEDIA-04 | Reproducible install | ✓ SATISFIED (gap closed) | Both halves of MEDIA-04 now satisfied: `install.sh` (Truth #1, #19) and `stow` (Truth #21, gap closed — `ags` registered in `stow.sh`'s PACKAGES array, reproducibility re-tested) |

(MEDIA-01..04 are ROADMAP-only requirements; not present in `.planning/REQUIREMENTS.md` — see Traceability Note above, not a gap.)

### Anti-Patterns Found

No debt markers (`TBD`/`FIXME`/`XXX`), placeholder returns, or empty-implementation stubs found in any phase-10-authored source file (`ags/.config/ags/{app.tsx,style.scss,lib/*.ts,widget/*.tsx,cava/config}`, `waybar/*.jsonc`, `hypr/config/{autostart,windowrules}.conf`, `matugen/config.toml` + `ags-colors.scss`, `theme-engine/lib/reload.sh`). The only `TBD`/`FIXME`/`TODO`/`placeholder` hits are inside the gitignored, machine-generated `ags/.config/ags/@girs/*.d.ts` GObject-introspection type stubs (upstream library doc comments, not phase-10 code) and the legitimate `.media-art-placeholder` CSS class name (a real fallback UI state for missing album art, not a stub marker). No blockers of this kind.

### Human Verification Required

None. Every interactive behavior in this phase already went through a blocking `checkpoint:human-verify` gate during execution (10-02 Task 3, 10-03 Task 3, 10-04 Task 3, 10-06 Task 3), each recorded as `human_judgment: true` / approved in its plan's SUMMARY.md `coverage` frontmatter. This verification pass's job was to confirm the code those gates were run against is still present and correctly wired — which it is. The one exception found (the `stow.sh` registration gap, below) has since been resolved by a code-level fix, not by re-running a human gate — reproducibility is a scripted/deterministic property, not an interactive one.

### Gaps Summary

**RESOLVED — the `ags` stow package was never registered in `stow.sh`.** Everything the phase built — the AGS applet itself, its MPRIS bindings, the cava underlay, the matugen theming, and the waybar/autostart integration — is present, correctly wired, and was exercised end-to-end by a human at four separate blocking gates. The code quality here is high and none of the interactive/visual claims in the SUMMARYs are in question.

The gap was specifically in the "Reproducible via install.sh + stow" clause of the phase goal and MEDIA-04. `ags/.config/ags/` is a fully-built, git-tracked stow package (confirmed via `git ls-files`), but `stow.sh`'s `PACKAGES` array — the actual mechanism this repo uses to deploy every config package to `~/.config/` — did not include `ags`. This repo has three clear precedents (eww, elephant, swayosd) where the commit introducing a new stow package also added it to this array; Phase 10 didn't follow that pattern initially. The applet only worked on the verification machine because `stow ags` was run directly, out-of-band, twice (once in 10-04 as an unblocking workaround, once again during the 10-06 human gate) — both times documented in the SUMMARYs as a one-off command, not a repo change. 10-06-SUMMARY.md went on to assert this was automatically reproducible via `install.sh` + `stow.sh`, which was not true of the codebase at that time.

**Fix applied:** `ags` added to `stow.sh`'s `PACKAGES` array, alphabetically first (commit `fix(10): register ags in stow.sh so install.sh+stow.sh reproduces the applet`).

**Reproducibility re-verified with a concrete before/after test** (not just code inspection):
1. Confirmed `~/.config/ags` was a symlink (the pre-existing manual out-of-band stow from 10-04/10-06): `test -L ~/.config/ags` → true; `ls -ld` showed `~/.config/ags -> ../dotfiles/ags/.config/ags`.
2. Removed only that symlink to simulate a fresh machine: `rm ~/.config/ags` (verified it was a symlink, not a real directory, before removing).
3. Re-ran the repo's actual reproduction path — `./stow.sh` (the exact command `install.sh` line 550 tells the user to run).
4. Confirmed `~/.config/ags` was recreated: `ls -ld ~/.config/ags` → `lrwxrwxrwx ... ~/.config/ags -> ../dotfiles/ags/.config/ags`, `readlink -f` resolved to `/home/aorus/dotfiles/ags/.config/ags`.

This proves a fresh `install.sh` + `./stow.sh` run now provisions `~/.config/ags` without any manual, out-of-band `stow ags` step.

**Note (out of scope, pre-existing, not part of this gap):** during the re-run, `./stow.sh` hit an unrelated conflict later in its package loop — `vscodium`'s `~/.config/VSCodium/User/settings.json` exists as a real file (written live by the running VSCodium app, not stow-managed), which aborts `stow --restow` for that package with a non-zero exit. This predates and is unrelated to the `ags` change (`ags` is processed first in the loop, alphabetically, and completes successfully regardless); it does not affect this gap's resolution and is not fixed here per scope boundary — flagged for a separate follow-up.

---

_Verified: 2026-07-15T17:21:59Z_
_Verifier: Claude (gsd-verifier)_
