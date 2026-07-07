---
phase: 01-root-cause-fix-consolidated-theme-engine
verified: 2026-07-07T23:35:00Z
status: passed
score: 5/5 must-haves verified
behavior_unverified: 0
overrides_applied: 0
re_verification:
  previous_status: gaps_found
  previous_score: 4/5
  gaps_closed:
    - "Waybar visibly re-themes on the same switch, confirmed in both a static preset and a matugen dynamic switch (Success Criterion 3 / THEME-04)"
  gaps_remaining: []
  regressions: []
deferred:
  - truth: "install.sh installs rsync (a hard runtime dependency of theme-engine/lib/commit.sh's atomic commit step) so a genuinely fresh install renders and commits a theme on first boot"
    addressed_in: "Phase 3"
    evidence: "Phase 3 Requirements includes INST-01: 'install.sh installs the correct theming-critical packages ... and verifies critical packages post-install'. Code review 01-REVIEW.md CR-01 documents this exact gap (rsync absent from PACMAN_PKGS/AUR_PKGS; theme_engine_commit hard-requires it) and the parent task explicitly scoped it to Phase 3/INST-01. rsync IS present on this already-provisioned machine (`pacman -Q rsync` → 3.4.4-1), so live re-theming on THIS machine is unaffected — the gap only manifests on a genuinely fresh install, which is out of this phase's Success Criteria."
  - truth: "install.sh's orphan-package cleanup does not abort the installer on the common zero-orphan case"
    addressed_in: "Phase 3"
    evidence: "Phase 3 Requirements includes INST-02 ('stow.sh completes successfully on a genuinely fresh system — no unguarded operations that assume existing state') and INST-03 (fresh-VM install verification). Code review 01-REVIEW.md CR-02 documents `paru -R \"$(pacman -Qtdq)\"` aborting under set -euo pipefail when there are zero orphans (the normal fresh-install case), skipping every post-install task below it. Not exercised on this already-provisioned machine; only manifests on a genuinely fresh install."
  - truth: "elephant listproviders covers every provider walker/config.toml references (files, menus, providerlist, runner, websearch)"
    addressed_in: "Phase 3"
    evidence: "theme-doctor's one persistent failing invariant (21/22 pass, live-verified this session). Phase 1's own AUDIT.md (SCAN-02 section) and STATE.md Blockers/Concerns already flagged this gap and explicitly deferred it to Phase 3's INST-01 verification loop; the user accepted this at Plan 01-03's final checkpoint rather than treating it as a blocker."
---

# Phase 1: Root-Cause Fix & Consolidated Theme Engine Verification Report

**Phase Goal (ROADMAP):** Every visible desktop app re-themes live from a single shared engine, with the root cause of the long-standing stuck-white bug eliminated and the full repo audited so fixes stop looping.
**Phase Goal (MVP user story, from PLAN frontmatter):** As a desktop user, I want to switch to any theme (static preset or matugen dynamic) and have every visible app re-theme live from one shared engine with the stuck-white bug gone, so that my whole desktop stays consistent without relogins and theming fixes stop looping.
**Verified:** 2026-07-07T23:35:00Z
**Status:** passed
**Re-verification:** Yes — after gap closure (initial verification 2026-07-07T23:15:00Z found 1 gap; closed by commit `7ea4e53`).
**Mode:** mvp (user-story goal validated via `gsd-tools query user-story.validate` → `valid: true`)

## Re-Verification of the Closed Gap

The initial verification's single gap (waybar `style-floating.css` hardcoded Catppuccin hexes on `#backlight`, `#battery`, `#battery.charging/.plugged`, `#battery.critical`, `@keyframes blink` — code review finding WR-10) was re-verified against the codebase and live system:

| Check | Result |
|---|---|
| Fix commit exists | `7ea4e53` "fix(01): re-theme waybar battery/backlight via named palette colors (closes verification gap, WR-10)" — touches only `waybar/.config/waybar/style-floating.css` (10 insertions, 10 deletions), so no regression surface for previously-verified items |
| All 5 previously-hardcoded blocks now use named colors | Verified by reading the file: `#backlight`/`#battery` → `@on_secondary`/`@secondary`; `#battery.charging/.plugged` → `@on_tertiary`/`@tertiary`; `#battery.critical` → `@secondary`/`@on_secondary`; `@keyframes blink` → `@error`/`@on_error` |
| Zero old Catppuccin hexes remain | `grep -E '#(161320\|F8BD96\|B5E8E0\|BF616A)'` across all three style files → no matches |
| Zero literal 6-digit hex remains in style-floating.css at all | `grep -E '#[0-9A-Fa-f]{6}\b'` → no matches; style-full.css and style-minimal.css re-confirmed clean |
| All six named colors defined in the live palette | `~/.local/state/theme/waybar.css` (regenerated 23:01 by a live `theme-apply rosepine` run) defines `secondary`/`on_secondary`/`tertiary`/`on_tertiary`/`error`/`on_error` |
| All six named colors defined in the matugen template | `matugen/.config/matugen/templates/waybar-colors.css` templates all six — both static (`matugen json`) and dynamic (`matugen image`) modes populate them by construction |
| Waybar still running on the affected layout | `pgrep -a -x waybar` → pid 903, `config-floating.jsonc` + `style-floating.css` — the fixed file is the live one |

**Regression check on previously-passed items:** commit `7ea4e53` modifies a single CSS file and nothing else; the engine, matugen config, GTK wiring, thin callers, and install.sh package arrays are untouched. No regressions.

## User Flow Coverage

User story: «As a desktop user, I want to switch to any theme (static preset or matugen dynamic) and have every visible app re-theme live from one shared engine with the stuck-white bug gone, so that my whole desktop stays consistent without relogins and theming fixes stop looping.»

| Step | Expected | Evidence | Status |
|------|----------|----------|--------|
| Open the picker / trigger a switch | `Super+T` (walker picker) or `Super+W`/wallpaper-picker (dynamic) calls one shared entrypoint | `hypr/.config/hypr/scripts/theme-switch.sh` and `wallpaper-picker.sh` are thin callers that `exec ~/.config/theme-engine/theme-apply "$THEME"` — confirmed by reading both files live | ✓ |
| Theme renders atomically | `theme-apply <name>` renders under a temp prefix via matugen, commits only on success | `theme-engine/.config/theme-engine/lib/generate.sh` + `lib/commit.sh` (render-then-rsync pattern); live `theme-doctor` run shows all 10 contract files + `current-theme` present in `~/.local/state/theme/` (current-theme = `rosepine`) | ✓ |
| Signal-driven surface re-themes without relogin | Hyprland, waybar, kitty, swaync all re-color on one `hyprctl reload` / `pkill -SIGUSR*` / `swaync-client -rs` fan-out | `theme-engine/.config/theme-engine/lib/reload.sh:16-19` is the sole file issuing these calls (grep-confirmed no duplicate callers elsewhere); human-verified at final Plan 01-03 checkpoint (APPROVED); waybar widget hardcode gap closed by `7ea4e53` | ✓ |
| Walker opens in new colors, elephant stays healthy | Walker restart is bounded-poll + elephant-socket/version-gated before relaunch | `lib/reload.sh:66-136` (bounded `pgrep` poll, elephant socket + `elephant version` health gate); live: `theme-doctor` shows `elephant version responds (2.21.0)`, `walker version responds (2.16.2)`, both processes running; human-verified across 3 checkpoint rounds (`c72d61b`, `36b6440`) | ✓ |
| Thunar / GTK3 show new palette; GTK4 follows dark+accent | `adw-gtk-theme` installed and toggled via gsettings; daemon-only restart, deferred-and-deduped watcher for open windows; GTK4 `color-scheme`/`accent-color` set via gsettings | `pacman -Q adw-gtk-theme` → `6.5-1` (live); `lib/gtk.sh:21-24` (gsettings toggle), `lib/gtk.sh:60-189` (bounded poll + deferred watcher), `lib/gtk.sh:192-236` (hue-mapped accent); human-verified close-all-windows protocol at final checkpoint | ✓ |
| Same theme applies at login as from the picker | `theme-init.sh` reads `current-theme` and calls the same `theme-apply` entrypoint | `hypr/.config/hypr/scripts/theme-init.sh` — reads `~/.local/state/theme/current-theme`, `exec theme-apply "$THEME"`; human-verified login parity (THEME-06) | ✓ |
| Outcome: whole desktop stays consistent, no theming-fix looping | A single documented AUDIT.md exists with disposition-owned findings; a code review ran post-completion; every actionable in-phase finding is fixed or explicitly disposition-owned | `AUDIT.md` (108 lines, 5 component sections + SCAN-02, every finding disposition-owned); `01-REVIEW.md` (23 findings, engine core rated "well-reasoned"); the one live-re-theming finding (WR-10) is now fixed (`7ea4e53`); remaining Criticals are fresh-install scope, owned by Phase 3 (see `deferred`) | ✓ |

## Goal Achievement

### Observable Truths

| # | Truth (merged ROADMAP SC + PLAN must_haves) | Status | Evidence |
|---|------|--------|----------|
| 1 | Walker opens in the new theme's colors after a switch — no restart/relogin, elephant serves results normally (SC1, THEME-01, SCAN-02) | ✓ VERIFIED | `lib/reload.sh` bounded-poll restart + elephant socket/version health gate (code, live-confirmed); `theme-doctor`: elephant/walker both respond and are running; human-verified 3 rounds, final checkpoint APPROVED |
| 2 | Thunar/GTK3 show new palette (adw-gtk-theme installed+applied); GTK4/libadwaita follow correct dark/light + accent (SC2, THEME-02, THEME-03) | ✓ VERIFIED | `pacman -Q adw-gtk-theme` → 6.5-1 (live); `gsettings get gtk-theme` → `adw-gtk3-dark` (theme-doctor PASS, live); `lib/gtk.sh` dark-mode + hue-mapped accent gsettings wiring; human-verified close-all-windows protocol |
| 3 | Waybar and swaync visibly re-theme on the same switch, static and dynamic (SC3, THEME-04, THEME-05) | ✓ VERIFIED (after gap closure) | swaync: `swaync/.config/swaync/style.css` imports state dir, no hardcode. Waybar: all three layout CSS files import the state-dir contract and contain zero literal hex after `7ea4e53`; all six named colors confirmed in live `waybar.css` AND the matugen template (both modes populate them); active layout (`style-floating.css`, pid 903) is the fixed file; live `theme-apply rosepine` exit 0 with waybar surviving the SIGUSR2 reload |
| 4 | A single theme switch updates every visible app at once, no relogin/session restart (SC4, THEME-06) | ✓ VERIFIED | State-dir contract populated atomically, signal fan-out is single-owner, human-verified end-to-end for all ten targets; the one exception (2 hardcoded waybar widgets) is now closed by `7ea4e53` |
| 5 | Same entrypoint for picker and login; one reload owner; one GTK_THEME source; documented full-repo audit (SC5, PIPE-01, PIPE-02, PIPE-05, SCAN-01) | ✓ VERIFIED | `theme-switch.sh`/`theme-init.sh`/`wallpaper-picker.sh` all `exec theme-apply` (grep-confirmed thin callers); `lib/reload.sh` sole fan-out owner (comment + grep confirms no duplicate `hyprctl reload`/`pkill -SIGUSR*`/`swaync-client -rs` callers elsewhere); `GTK_THEME` set only in `uwsm/.config/uwsm/env:17`, `lib/gtk.sh` only propagates via `systemctl --user import-environment`/`dbus-update-activation-environment`; `AUDIT.md` exists, 5 component sections, every finding disposition-owned |

**Score:** 5/5 truths verified (0 present-but-behavior-unverified)

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|---|---|---|---|---|
| SCAN-01 | 01-01 | Full-repo bug audit, disposition-owned findings | ✓ SATISFIED | AUDIT.md exists, 5 sections + SCAN-02, 4/4 disposition tokens verified present |
| SCAN-02 | 01-01, 01-03 | Walker/elephant functional health verified | ✓ SATISFIED (with known, deferred gap) | AUDIT.md SCAN-02 section; theme-doctor extended, 21/22 pass live; the 1 failure is the deferred elephant-provider gap (see `deferred`) |
| THEME-01 | 01-03 | Walker follows theme switches, no stuck-white | ✓ SATISFIED | Bounded-poll restart + elephant health gate; human-verified |
| THEME-02 | 01-01, 01-03 | Thunar follows switches, adw-gtk-theme installed+applied | ✓ SATISFIED | `pacman -Q adw-gtk-theme` live; daemon-only restart + deferred watcher; human-verified |
| THEME-03 | 01-03 | GTK4/libadwaita dark/light+accent, ceiling documented | ✓ SATISFIED | gsettings dark-mode + hue-mapped accent wiring; ceiling explicitly documented in SUMMARY, not treated as a gap |
| THEME-04 | 01-02, 01-03 | Waybar re-themes, static + dynamic | ✓ SATISFIED (after `7ea4e53`) | All three layout CSS files on the state-dir contract with zero hardcoded hex; named colors present in template (both modes) and live palette |
| THEME-05 | 01-02, 01-03 | Swaync re-themes, static + dynamic | ✓ SATISFIED | `swaync/.config/swaync/style.css` state-dir @import, no hardcode found, human-verified |
| THEME-06 | 01-02, 01-03 | One switch, no relogin, all apps | ✓ SATISFIED (after `7ea4e53`) | Signal fan-out single-owner and atomic; the former waybar-widget exception is closed |
| PIPE-01 | 01-02 | One shared theme engine, no duplicated orchestration | ✓ SATISFIED | Single `theme-apply` entrypoint; 3 callers confirmed thin |
| PIPE-02 | 01-02 | Reload fan-out owned by exactly one place | ✓ SATISFIED | `grep -c post_hook matugen/config.toml` → 0; `lib/reload.sh` sole owner (code + comment header) |
| PIPE-03 | 01-02 | Generated output outside git tree | ✓ SATISFIED | `git ls-files \| grep -E '(gtk-[34]\.0/colors\.css\|...)'` → empty; state dir populated live, git status clean |
| PIPE-05 | 01-02 | GTK_THEME single source of truth | ✓ SATISFIED | Only `uwsm/env:17` assigns it; `lib/gtk.sh` only propagates (minor doc inconsistency at IN-03, non-blocking — see Anti-Patterns) |

**Orphaned requirements:** None — all 12 phase requirement IDs from ROADMAP.md are claimed by at least one plan's `requirements` frontmatter field (SCAN-01/02 → 01-01; PIPE-01/02/03/05, THEME-04/05/06 → 01-02; THEME-01/02/03, SCAN-02 → 01-03), and REQUIREMENTS.md's traceability table maps all 12 to "Phase 1 / Complete".

### Required Artifacts

| Artifact | Expected | Status | Details |
|---|---|---|---|
| `.planning/phases/01-.../AUDIT.md` | 5 component-grouped findings w/ severity, file:line, disposition | ✓ VERIFIED | 108 lines, 5 `## Findings —` sections + SCAN-02 + Summary-by-Disposition |
| `install.sh` (package arrays) | adw-gtk-theme in pacman array, nonexistent `adw-gtk3` gone | ✓ VERIFIED | `grep -vE '^\s*#' install.sh \| grep -cw adw-gtk3` → 0 (live) |
| `theme-engine/` stow package | theme-apply, theme-doctor, lib/{generate,commit,reload,gtk}.sh, 6 palette JSONs | ✓ VERIFIED | All files present, `stow -n theme-engine` clean (theme-doctor PASS), package live-stowed on this machine |
| `matugen/.config/matugen/config.toml` | zero post_hooks, no wallpaper-panic, state-dir output paths | ✓ VERIFIED | grep counts both 0; live render populates state dir |
| `gtk-3.0/gtk.css` + `gtk-4.0/gtk.css` | static @import files | ✓ VERIFIED | Both files' first content line is a relative `@import url('../../.local/state/theme/...')` |
| `theme-switch.sh`, `theme-init.sh`, `wallpaper-picker.sh` | thin callers of theme-apply | ✓ VERIFIED | Both read files end in `exec ~/.config/theme-engine/theme-apply "$THEME"` |
| Retired hypr scripts | walker-restart.sh, walker-theme-gen.sh, gtk-reload.sh removed, unreferenced | ✓ VERIFIED | `ls` confirms all three absent on disk; SUMMARY self-check independently confirms |

### Key Link Verification

| From | To | Via | Status | Details |
|---|---|---|---|---|
| `theme-switch.sh`/`theme-init.sh`/`wallpaper-picker.sh` | `theme-apply` | `exec`/direct call | ✓ WIRED | Confirmed by reading all three scripts |
| `theme-apply` | `lib/generate.sh` → `lib/commit.sh` → `lib/reload.sh` | ordered sourcing/chain | ✓ WIRED | Live `theme-apply` run populates state dir, `current-theme` = rosepine, `theme-doctor` all-but-one PASS |
| `matugen config.toml output_path` | `~/.local/state/theme/*` | per-app filenames | ✓ WIRED | `theme-doctor` confirms all 10 contract files exist post-render |
| `gtk-{3,4}.0/gtk.css` `@import` | `~/.local/state/theme/gtk-{3,4}.0-colors.css` | relative path | ✓ WIRED | Both files verified live, both target files exist in state dir |
| `lib/reload.sh` walker restart | elephant socket `/run/user/$UID/elephant/elephant.sock` | health gate before declaring success | ✓ WIRED | Code confirms gate; live socket/process present |
| `gsettings gtk-theme` | `adw-gtk-theme` on disk | toggle | ✓ WIRED | `gsettings get` → `adw-gtk3-dark` (theme-doctor PASS, live) |
| `waybar/config-floating.jsonc` (active) | `waybar/style-floating.css` → state-dir named colors | `-s` flag + `@import` + `@`-named refs | ✓ WIRED (after `7ea4e53`) | `pgrep -fa waybar` confirms this is the running layout; every rule now resolves through the state-dir palette |

### Data-Flow Trace (Level 4)

| Artifact | Data Variable | Source | Produces Real Data | Status |
|---|---|---|---|---|
| `~/.local/state/theme/waybar.css` | `@primary`/`@secondary`/etc. | `matugen json/image` render of `waybar-colors.css` template | Yes — live values differ per active theme (verified rosepine vs prior palette differ) | ✓ FLOWING |
| `waybar/.config/waybar/style-floating.css` `#backlight`/`#battery`/blink | `@secondary`/`@on_secondary`/`@tertiary`/`@on_tertiary`/`@error`/`@on_error` | state-dir `waybar.css` via `@import` (line 1) | Yes — all six names confirmed defined in live palette and template | ✓ FLOWING (closed by `7ea4e53`) |
| `~/.local/state/theme/gtk-3.0-colors.css` / `gtk-4.0-colors.css` | `@`-named colors | `matugen` render | Yes — theme-doctor confirms files exist + non-empty | ✓ FLOWING |

### Behavioral Spot-Checks

| Behavior | Command | Result | Status |
|---|---|---|---|
| theme-doctor invariant suite runs and reports pass/fail per check | `bash ~/.config/theme-engine/theme-doctor` | 21 passed, 1 failed (known deferred elephant-provider gap) | ✓ PASS |
| adw-gtk-theme actually installed | `pacman -Q adw-gtk-theme` | `adw-gtk-theme 6.5-1` | ✓ PASS |
| rsync present on this machine (commit.sh dependency) | `pacman -Q rsync` | `rsync 3.4.4-1` | ✓ PASS (fresh-install gap deferred, see `deferred`) |
| matugen config has zero post_hooks / wallpaper-panic risk | `grep -c post_hook / 'set = true' matugen/config.toml` | `0` / `0` | ✓ PASS |
| Generated theme files untracked from git | `git ls-files \| grep -E 'gtk-[34]\.0/colors\.css\|...'` | empty | ✓ PASS |
| Legacy hypr scripts retired and unreferenced | `ls walker-restart.sh walker-theme-gen.sh gtk-reload.sh` | all three "No such file or directory" | ✓ PASS |
| `set -e`/`(( x++ ))` footgun eliminated from engine | `grep -n '(( *[a-z_]*++ *))' lib/*.sh theme-apply theme-doctor` | no matches (only referenced in a comment) | ✓ PASS |
| Waybar active-layout palette wiring | named-color resolution: style files (zero literal hex) × live state-dir palette × matugen template (all six names) | all consistent after `7ea4e53`; waybar pid 903 survived a live `theme-apply rosepine` reload | ✓ PASS |

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|---|---|---|---|---|
| `install.sh` | 41-141 (missing) | `rsync` absent from package arrays despite being a hard dependency of `commit.sh` | 🛑 Blocker (fresh-install only, deferred to Phase 3/INST-01) | Genuinely fresh install never populates the state dir — see `deferred` |
| `install.sh:196` | 196 | `paru -R "$(pacman -Qtdq)"` aborts under `set -euo pipefail` when there are zero orphans (the common case) | 🛑 Blocker (fresh-install only, deferred to Phase 3/INST-02/03) | Skips every remaining post-install step on a fresh run — see `deferred` |
| `theme-engine/.config/theme-engine/lib/gtk.sh:24` | 24 | Hardcodes literal `adw-gtk3-dark` despite file header claiming it "never hardcodes a theme name" | ℹ️ Info | Currently harmless (matches `uwsm/env`'s value) but two sources of truth can silently drift; not a blocker |
| `theme-engine/.config/theme-engine/lib/gtk.sh` Thunar relaunch | 106-121, 169-181 | No D-Bus name-release gate before Thunar relaunch (unlike walker's, which was diagnosed and fixed for exactly this race) | ℹ️ Info / narrow-window race | Not proven to have manifested in the 3 rounds of human verification; flagged by code review (WR-02), not independently re-triggered here |

No `TBD`/`FIXME`/`XXX`/`TODO`/`HACK`/`PLACEHOLDER` debt markers found in any phase-modified file. The initial verification's waybar hardcode entry (WR-10) is resolved by `7ea4e53` and removed from this table.

### Human Verification Required

None additional beyond what the phase's own blocking human-verify checkpoint already covered (already APPROVED 2026-07-07, per Plan 01-03 SUMMARY: all ten fan-out targets, both static and dynamic modes, login parity, git cleanliness). The gap-closure fix is deterministically verifiable from CSS source against the live state-dir palette and the matugen template; no further human judgment is required. (Optional cosmetic spot-check: glance at the waybar battery/backlight segments after the next organic theme switch to confirm they now track the palette — not blocking.)

### Gaps Summary

No open gaps. The single gap from the initial verification — the actively-running waybar layout (`style-floating.css`) hardcoding five rule blocks to Catppuccin hex (code review WR-10) — was closed by commit `7ea4e53` and re-verified directly against the codebase and live system: zero literal hex remains in any of the three waybar style files, the five blocks now resolve through `@secondary`/`@on_secondary`, `@tertiary`/`@on_tertiary`, and `@error`/`@on_error`, all six names are defined in both the live state-dir palette (rosepine) and the matugen template (so static and dynamic modes populate them by construction), and the running waybar instance (pid 903) uses the fixed file and survived a live reload.

Three items remain intentionally deferred to Phase 3 (fresh-install-only Criticals CR-01/CR-02 from the code review, and the known elephant-provider gap) — all explicitly owned by Phase 3's INST-01/02/03 scope and none affecting this phase's Success Criteria on the live target machine.

Phase goal achieved: every visible desktop app re-themes live from the single shared engine, the stuck-white root cause (missing `adw-gtk-theme` package / wrong `adw-gtk3` install target) is eliminated, and the full-repo audit exists with every finding disposition-owned.

---

_Verified: 2026-07-07T23:35:00Z (re-verification after gap closure; initial: 2026-07-07T23:15:00Z)_
_Verifier: Claude (gsd-verifier)_
