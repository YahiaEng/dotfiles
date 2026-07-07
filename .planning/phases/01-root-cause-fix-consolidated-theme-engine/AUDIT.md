# Phase 1 Full-Repo Bug Audit

**Audited:** 2026-07-07
**Scope:** SCAN-01 (full-repo bug scan) + SCAN-02 (walker/elephant functional health), per D-22 audit format and D-23 fix policy.
**Method:** Direct code read (theme pipeline scripts, matugen/walker configs, uwsm env, stow.sh, install.sh) + empirical verification on this machine (`pacman`, `elephant`, `paru -Si`, `git log`, `git ls-files --stage`, `gsettings`).

**Disposition legend:** `fix-in-phase-1` (this phase — either fixed immediately alongside this audit, or informs the engine build in Plan 01-02/01-03) · `fix-in-phase-2` (parity/stress work) · `fix-in-phase-3` (install.sh hardening beyond the root cause, stow guards, dead-config removal) · `wontfix` (working as intended / mitigated elsewhere, no action needed).

---

## SCAN-02: Walker/Elephant Provider Health

Empirical comparison performed this session:

| Source | Result |
|--------|--------|
| `elephant listproviders` (live) | `calc, symbols, desktopapplications, clipboard` (4 providers) |
| `pacman -Qs elephant` (installed packages) | `elephant, elephant-calc, elephant-clipboard, elephant-desktopapplications, elephant-menus, elephant-symbols` (5 provider packages + core) |
| `walker/.config/walker/config.toml` `[providers] default` (config.toml:15-21) | `desktopapplications, calc, runner, websearch, menus` |
| `walker/.config/walker/config.toml` prefix table (config.toml:25-47) | adds `files` (prefix `/`), `providerlist` (prefix `;`), `clipboard` (prefix `:`), `symbols` (prefix `.`) |
| `paru -Si elephant-runner elephant-websearch elephant-files` (this session) | All three resolve as real, installable AUR packages (Name field present for each — RESEARCH.md assumption A2 confirmed) |

**Provider-by-provider gap table:**

| Provider | Referenced in config.toml | Package installed | Active in `elephant listproviders` | Gap |
|----------|---------------------------|--------------------|--------------------------------------|-----|
| `desktopapplications` | yes (default) | yes | yes | none |
| `calc` | yes (default) | yes | yes | none |
| `clipboard` | yes (prefix `:`) | yes | yes | none |
| `symbols` | yes (prefix `.`) | yes | yes | none |
| `menus` | yes (default) | yes (`elephant-menus`) | **no** | package installed but provider not active — cause unconfirmed (not a missing-package bug; needs runtime investigation) |
| `runner` | yes (default) | **no** | no | no `elephant-runner` package anywhere in `install.sh` |
| `websearch` | yes (default) | **no** | no | no `elephant-websearch` package anywhere in `install.sh` |
| `files` | yes (prefix `/`) | **no** | no | no `elephant-files` package anywhere in `install.sh` |
| `providerlist` | yes (prefix `;`) | listed in `install.sh:156` but **not installed** on this machine (`pacman -Qs elephant` doesn't show it) | no | same silent-AUR-failure symptom class as the `adw-gtk3` root cause |

**Consequence:** Walker's default search is silently missing "run a shell command" (`runner`) and "web search" (`websearch`) results; the `/` files prefix and `;` provider-switcher prefix are non-functional. No error is surfaced anywhere — indistinguishable from "walker is broken" without this audit.

Findings 7, 19, 20 below carry this comparison's fix dispositions.

---

## Findings — Theme Pipeline

| # | Severity | Finding | Evidence | Disposition |
|---|----------|---------|----------|--------------|
| 1 | critical | Apply+reload orchestration is duplicated **three ways**, not two: `theme-switch.sh`, `theme-init.sh`, and `wallpaper-picker.sh` each independently reimplement the full render+GTK-rebuild+reload sequence. | `hypr/.config/hypr/scripts/wallpaper-picker.sh:132-157` (Material You regeneration block — independently calls `matugen image`, rebuilds `gtk.css` via `cat`, re-fires the full reload chain); `theme-switch.sh:52-114` (`apply_static_theme`/`apply_material_you`); `theme-init.sh:43-89` | fix-in-phase-1 (PIPE-01, resolved by Plan 01-02) |
| 2 | major | Reload fan-out fires twice in dynamic mode: matugen `post_hook`s fire per-template AND a full `reload_all()`/inline reload block fires again after all templates render. | `matugen/.config/matugen/config.toml:22,28,34,45,56,72,78` (7 `post_hook` lines); `theme-switch.sh:43-50` (`reload_all()`); `theme-init.sh:54-59,83-88`; `wallpaper-picker.sh:147-152` | fix-in-phase-1 (PIPE-02) |
| 3 | critical | `adw-gtk-theme` (the real GTK3 theme package) is not installed on this machine. `install.sh` lists the nonexistent AUR package name `adw-gtk3` instead. This is the confirmed root cause of Thunar/GTK3 apps falling back to stock white. | `pacman -Q adw-gtk-theme` exits 1 (verified this session, before fix); `pacman -Si adw-gtk3` fails (package does not exist under that name); `pacman -Si adw-gtk-theme` succeeds — official `extra` repo, version 6.5-1 (verified this session); `install.sh:150` (wrong AUR name); `gtk/.config/gtk-3.0/settings.ini:3` already references `gtk-theme-name=adw-gtk3-dark`, a theme name that cannot resolve until the package is installed | fix-in-phase-1 (THEME-02 — fixed in Task 2 of this plan) |
| 4 | major | Generated per-app color files are still git-tracked at their old in-repo paths, dirtying git on every theme switch. | `git log --oneline -- gtk/.config/gtk-3.0/colors.css` → 2 commits; `git ls-files` confirms tracked: `gtk/.config/gtk-{3,4}.0/colors.css`, `hypr/.config/hypr/colors.conf`, `kitty/.config/kitty/colors.conf`, `swaync/.config/swaync/colors.css`, `waybar/.config/waybar/colors.css`, `wlogout/.config/wlogout/colors.css`, `walker/.config/walker/themes/rice/style.css`, `yazi/.config/yazi/theme.toml`, `wofi/.config/wofi/colors.css` — all are overwrite targets of `theme-switch.sh`/`theme-init.sh`/matugen | fix-in-phase-1 (PIPE-03 — this phase changes the output contract to the state dir per D-05, so the pre-existing tracked artifacts are this phase's own cleanup, not Phase 3's; future-switch cleanliness stays owned by CLEAN-02/Phase 3) |
| 5 | critical | `matugen json <path>` crashes with an unhandled panic (`internal error: entered unreachable code`, `src/helpers.rs:262`) whenever `[config.wallpaper]` has `set = true` and no image argument is given — this is the current, unmodified state of the repo's matugen config. | `matugen/.config/matugen/config.toml:8-16` (`[config.wallpaper]` block, `set = true`); reproduced directly against installed matugen 4.1.0 per RESEARCH.md Pitfall G1 | fix-in-phase-1 (blocking prerequisite for Plan 01-02's static-preset `matugen json` path, D-19) |
| 6 | major | CONTEXT.md's D-16 premise — that Walker's `hotreload_theme` config key lets theme CSS hot-reload without a restart — is false. No such key exists anywhere in walker 2.16.2's source (`src/config.rs`, exact installed tag `v2.16.2`, per RESEARCH.md Pitfall W1). CSS is loaded once at startup via `setup_css()`, no file-watcher. | `walker/.config/walker/config.toml` has no such key; `walker-restart.sh:18-29` already does kill/relaunch (the only working mechanism); `walker-theme-gen.sh` regenerates `style.css` but nothing re-reads it without a full process restart | fix-in-phase-1 (informs Plan 01-03 — design the Walker reload step as restart-only from the start, not hotreload-preferring) |
| 7 | major | SCAN-02 provider gap (see dedicated section above): `runner`, `websearch`, `files` referenced in walker's config with zero corresponding elephant-* package anywhere in `install.sh`; `elephant-providerlist` is listed but not installed; `menus` package is installed but not returned as an active provider. | `walker/.config/walker/config.toml:15-21,25-47`; `elephant listproviders` output (this session); `pacman -Qs elephant` (this session); `install.sh:146-185` (no `elephant-runner`/`elephant-websearch`/`elephant-files` entries; `elephant-providerlist` at line 156) | fix-in-phase-1 for the `install.sh` package additions (`elephant-runner`, `elephant-websearch`, `elephant-files` — Task 2 of this plan, same-shape fix as the `adw-gtk-theme` root cause); fix-in-phase-3 for the `menus`-provider-inactive-despite-installed anomaly and the `elephant-providerlist` silent-install-failure (both need a general install verification loop, owned by INST-01) |
| 8 | minor | `GTK_THEME=adw-gtk3-dark` is hardcoded/exported in three separate places instead of one source of truth. | `uwsm/.config/uwsm/env:17` (correct target per D-13); `hypr/.config/hypr/config/env.conf:15` (duplicate); `hypr/.config/hypr/scripts/gtk-reload.sh:12` (ad-hoc runtime re-export); also re-exported in `theme-init.sh:23` | fix-in-phase-1 (PIPE-05 — consolidate to `uwsm/.config/uwsm/env` only, per D-13) |
| 9 | minor | `walker-theme-gen.sh` is git-tracked without the executable bit (mode `100644`, sibling scripts are `100755`). Masked today only because `stow.sh:59` unconditionally `chmod +x`'s every script in the directory on every stow run. | `git ls-files --stage hypr/.config/hypr/scripts/walker-theme-gen.sh` → `100644` (verified this session, vs. `100755` for `theme-switch.sh`) | wontfix (mitigated by `stow.sh`'s existing `chmod +x` step; cosmetic git-hygiene issue only — note for Plan 01-02: commit new `theme-engine/` scripts with the correct exec bit from the start) |
| 10 | minor | Wofi dead config still present and still installed, despite being abandoned per PROJECT.md ("Out of Scope") and D-11 ("Wofi is never added to the new engine"). | `wofi/.config/` (tracked: `colors.css`, `style.css`); `install.sh:55` (`wofi` in `PACMAN_PKGS`); `matugen/.config/matugen/config.toml:37-39` (`[templates.wofi]` still renders into `wofi/colors.css`) | fix-in-phase-3 (CLEAN-01, physical removal, per D-11) |

## Findings — Hyprland / Keybinds

| # | Severity | Finding | Evidence | Disposition |
|---|----------|---------|----------|--------------|
| 11 | minor | Keybind and autostart wiring reference the current, pre-engine script paths directly; these will need updating once `theme-engine/` exists as the single entrypoint (D-01/D-02). Not a defect in the current state — recorded so the planner has exact line references. | `hypr/.config/hypr/config/keybinds.conf:37` (`$mainMod, T` → `theme-switch.sh`); `hypr/.config/hypr/config/autostart.conf:36` (`theme-init.sh`) | fix-in-phase-1 (informs Plan 01-02/01-03 rewiring) |
| 12 | minor | Waybar config does not set `reload_style_on_change`, relying solely on the `SIGUSR2` `post_hook`. Not currently broken (the signal reload is wired and functional today), but flagged by research as a belt-and-suspenders addition given a known upstream tooltip-CSS-refresh issue on `SIGUSR2` alone. | `grep -rn "reload_style_on_change" waybar/.config/waybar/` → no matches (verified this session); Alexays/Waybar#3986 (cited in RESEARCH.md) | fix-in-phase-1 (low-risk addition, folds naturally into Plan 01-02's single-owner `reload.sh` work) |

## Findings — uwsm

| # | Severity | Finding | Evidence | Disposition |
|---|----------|---------|----------|--------------|
| 13 | minor | `uwsm/.config/uwsm/env` is the intended single source of truth for `GTK_THEME` (D-13) but is currently one of three sources — see Theme Pipeline finding #8 for the full triplication and its fix disposition. Cross-referenced here, not double-counted. | `uwsm/.config/uwsm/env:17` | fix-in-phase-1 (see finding #8) |
| 14 | — (informational) | `uwsm/.config/uwsm/env` correctly forces Wayland-native backends (`GDK_BACKEND`, `QT_QPA_PLATFORM`, `SDL_VIDEODRIVER`, `CLUTTER_BACKEND`, `MOZ_ENABLE_WAYLAND`, etc., lines 6-16) with no `xsettingsd` or other X11-only mechanism present anywhere in the repo — confirms the GSettings/dconf + portal layer is already correctly configured, matching CLAUDE.md's "What NOT to Use" guidance. No bug found beyond the GTK_THEME triplication already recorded. | `uwsm/.config/uwsm/env:1-20`; `grep -r xsettingsd .` → no matches (verified this session) | wontfix (working as intended) |

## Findings — Stow

| # | Severity | Finding | Evidence | Disposition |
|---|----------|---------|----------|--------------|
| 15 | major | `stow.sh` performs an unconditional, unguarded `mv ~/.config/hypr/hyprland.conf ~/.config/hyprland.conf.bak` with no existence check. Because `stow.sh` runs under `set -euo pipefail`, if `hyprland.conf` does not already exist at that path (e.g., a fresh system where the `hypr` package hasn't been stowed yet, or a re-run after a prior successful stow already moved it), the `mv` fails and aborts the entire stow run before any package is symlinked. | `stow.sh:7` (`set -euo pipefail`); `stow.sh:45` (unguarded `mv`) | fix-in-phase-3 (INST-02, stow.sh unguarded operations) |
| 16 | minor | `stow.sh`'s `PACKAGES` array lists a `scripts` package that does not exist as a directory anywhere in the repo root. Non-blocking today — the stow loop already guards with an `if [[ -d "$pkg" ]]` check and prints a skip warning — but it's stale/dead config. | `stow.sh:19-38` (`scripts` in `PACKAGES`, line 25); verified via `ls -d scripts` → "No such file or directory" | fix-in-phase-3 (bundle with wofi/dead-config cleanup, CLEAN-01/INST-02) |
| 17 | major | `.stow-local-ignore` does not exclude the Walker rice-theme directory (`walker/.config/walker/themes/rice/`), which is why `theme-init.sh` and `walker-restart.sh` both carry "ensure this is a real directory, not a stow symlink" workaround logic that runs on every login and every restart. | `.stow-local-ignore` (8 lines total, no `walker/themes/rice` entry — verified this session); `theme-init.sh:27-32`; `walker-restart.sh:4-10` | fix-in-phase-1 (D-09 — directly informs Plan 01-02/01-03's one-time wiring fix; add the exclusion as part of the new stow setup) |

## Findings — Install Scripts

| # | Severity | Finding | Evidence | Disposition |
|---|----------|---------|----------|--------------|
| 18 | critical | `install.sh`'s `AUR_PKGS` array lists `adw-gtk3`, a package name that does not exist in the AUR or official repos under that name. The real package, `adw-gtk-theme`, lives in the official `extra` repo (pacman, not AUR) and every config in this repo already references the `adw-gtk3-dark` theme name it provides. | `install.sh:150` (`adw-gtk3` in `AUR_PKGS`); `pacman -Si adw-gtk3` fails; `pacman -Si adw-gtk-theme` succeeds, `Repository: extra` (verified this session) | fix-in-phase-1 — **fixed in Task 2 of this plan** |
| 19 | major | `elephant-runner`, `elephant-websearch`, `elephant-files` — all required by `walker/.config/walker/config.toml`'s configured provider set (see SCAN-02 section) — are entirely absent from `install.sh`'s `AUR_PKGS` array. | `install.sh:146-185`; `walker/.config/walker/config.toml:15-21,25-47`; `paru -Si elephant-runner elephant-websearch elephant-files` all resolve (verified this session) | fix-in-phase-1 — **fixed in Task 2 of this plan** |
| 20 | minor | `elephant-providerlist` (`install.sh:156`) is listed in `AUR_PKGS` but is not installed on this machine (`pacman -Qs elephant` does not list it) — the same silent-AUR-install-failure symptom as the `adw-gtk3` root cause, but the package name itself is valid, so the actual cause (prior partial install failure vs. something else) is unconfirmed and needs a general verification mechanism, not a one-line rename. | `install.sh:156`; `pacman -Qs elephant` output (verified this session, package absent) | fix-in-phase-3 (INST-01 — add a post-install verification loop that would have caught this) |
| 21 | major | `install.sh` has no post-install verification step. `paru -Sy --needed --noconfirm ...` exits 0 even when individual AUR packages silently fail to resolve (as demonstrated by both the `adw-gtk3` root cause historically and the `elephant-providerlist` gap above) — nothing downstream surfaces the failure to the user. | `install.sh:189` (`$AUR_HELPER -Sy --needed --noconfirm "${AUR_PKGS[@]}"`, no exit-code/package-presence check after) | fix-in-phase-3 (INST-01, explicitly a Phase 3 requirement per D-23 — "install.sh hardening beyond the root cause") |
| 22 | minor | `install.sh:193` runs `paru -R "$(pacman -Qtdq)"` (remove orphaned packages) unconditionally. If `pacman -Qtdq` returns empty (no orphans — the common case), `paru -R ""` receives an empty argument; combined with `set -euo pipefail` (line 7) this is a plausible abort-on-clean-system robustness gap. Not reproduced/confirmed to actually fail this session — flagged for Phase 3 verification, not asserted as confirmed-broken. | `install.sh:7,193` | fix-in-phase-3 (INST-01) |
| 23 | minor | Wofi remains in `install.sh`'s `PACMAN_PKGS` array despite being abandoned (PROJECT.md Out of Scope, D-11). Cross-references Theme Pipeline finding #10. | `install.sh:55` | fix-in-phase-3 (CLEAN-01) |

---

## Summary by Disposition

| Disposition | Count | Findings |
|--------------|-------|----------|
| fix-in-phase-1 (this plan, Task 2) | 3 | #3, #18, #19 |
| fix-in-phase-1 (informs Plan 01-02/01-03 engine build) | 8 | #1, #2, #4, #5, #6, #8, #11, #12, #17 (9 total — see note) |
| fix-in-phase-3 | 8 | #7 (partial), #9 is wontfix not P3, #10, #15, #16, #20, #21, #22, #23 |
| wontfix | 2 | #9, #14 |

Note: finding #13 is a cross-reference to #8 and is not separately counted. Finding #7 splits its disposition (install.sh package additions → fix-in-phase-1/this plan; provider-anomaly investigation → fix-in-phase-3).

## Verification

- `pacman -Q adw-gtk-theme` — will exit 0 after Task 2 of this plan runs (currently fails, confirming the root cause is live before the fix).
- `grep -vE '^\s*#' install.sh | grep -cw 'adw-gtk3'` — will return `0` after Task 2 removes the wrong AUR entry.
- Every finding above carries exactly one `fix-in-phase-N`/`wontfix` disposition token and a `file:line` evidence reference.
