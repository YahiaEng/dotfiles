#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║              STOW DOTFILES SETUP                     ║
# ║   Creates symlinks from ~/dotfiles → ~/.config       ║
# ╚══════════════════════════════════════════════════════╝

set -euo pipefail

DOTFILES_DIR="$HOME/dotfiles"

if [[ ! -d "$DOTFILES_DIR" ]]; then
    echo "Error: $DOTFILES_DIR does not exist."
    exit 1
fi

cd "$DOTFILES_DIR"

# ── Stow packages ───────────────────────────────────
PACKAGES=(
    ags
    elephant
    fastfetch
    fish
    gtk
    hypr
    kitty
    matugen
    quickshell
    swaync
    swayosd
    theme-engine
    thunar
    uwsm
    vscodium
    walker
    wallpapers
    waybar
    wleave
    yazi
    zshell
)

echo "╔══════════════════════════════════════════╗"
echo "║       Stowing dotfile packages...        ║"
echo "╚══════════════════════════════════════════╝"

# Remove and backup existing hyprland conf, if a real (non-stow-owned) file
# exists (Pitfall 2/D-62). The hyprland pacman package ships no default
# config, so a genuinely fresh system has nothing here — the guard skips
# instead of aborting. On a re-run, the path is already a stow-owned
# symlink, so it's left alone (no pointless .bak churn).
HYPR_CONF="$HOME/.config/hypr/hyprland.conf"
HYPR_BAK="$HOME/.config/hyprland.conf.bak"
if [[ -e "$HYPR_CONF" && ! -L "$HYPR_CONF" ]]; then
    mv "$HYPR_CONF" "$HYPR_BAK"
fi

# Pre-create fish's plugin dirs as real directories so stow links individual
# files instead of dir-folding ~/.config/fish into the repo — fisher writes
# generated plugin files (fisher.fish, nvm.fish, ...) into these dirs at
# first run, and they must live host-side, never inside the repo tree
# (git-clean invariant).
mkdir -p "$HOME/.config/fish/functions" "$HOME/.config/fish/conf.d" "$HOME/.config/fish/completions"

# THM-01/D-08: pre-create the gtk-3.0/gtk-4.0 config dirs as real
# directories, same rationale as the fish dirs above — settings.ini is now
# a rendered state-dir target symlinked in by commit.sh (never stow-
# tracked content), and it must land in a real directory, never inside the
# repo via a folded stow symlink.
mkdir -p "$HOME/.config/gtk-3.0" "$HOME/.config/gtk-4.0"

# D-19: pre-create ~/.config/quickshell as a real directory, same
# rationale as fish/gtk-3.0/gtk-4.0 above — a genuinely fresh target keeps
# quickshell/ eligible for stow's whole-directory fold (a single symlink
# at ~/.config/quickshell), but this repo's convention (and the phase 11
# tracer's own verification) expects per-file symlinks
# (~/.config/quickshell/shell.qml itself resolving as a symlink), so the
# parent must already exist as a real directory before stow runs.
mkdir -p "$HOME/.config/quickshell"

# 15-13 (G-15-4): pre-create ~/.config/autostart as a REAL directory. It does
# not exist on a fresh machine, and the `quickshell` package is about to
# become its ONLY occupant (nm-applet.desktop, the secret-agent suppression
# override). Without this guard stow folds the whole directory into the repo
# — after which any application that writes its own autostart entry writes
# it into the cloned repo tree, silently turning user state into tracked
# dotfiles. Same fold hazard as the quickshell guard above, different
# consequence.
mkdir -p "$HOME/.config/autostart"

# 13-02: pre-create swaync.service's systemd drop-in directory as a REAL
# directory — a stow/systemd interaction discovered empirically this plan,
# not a style preference: systemd 261 silently ignores an entire .d
# drop-in directory when it is itself a symlink (verified directly —
# `systemctl --user show swaync.service -p DropInPaths` stayed EMPTY with
# stow's normal whole-directory fold in place, and only became non-empty
# once the parent existed as a real directory before stow ran). Same
# pre-create-before-stow idiom as fish/gtk-3.0/gtk-4.0/quickshell above:
# with the real directory already present, stow descends into it and
# symlinks only override.conf, which systemd DOES trust. Any FUTURE
# stowed systemd unit/drop-in in this repo needs the same treatment — see
# 13-02-SUMMARY.md for the full DropInPaths= empty-vs-populated evidence.
mkdir -p "$HOME/.config/systemd/user/swaync.service.d"

# 18-07 (QBAR-10): pre-create ~/.config/systemd/user itself as a REAL
# directory, independent of the swaync drop-in pre-create just above. That
# line only guarantees this parent as a SIDE EFFECT of creating its own
# drop-in subdirectory, and Phase 19 deletes swaync entirely — when that
# line goes, the protection it incidentally provided for this parent would
# vanish silently with it, and the resulting symptom (a unit file systemd
# cannot see because its directory became a symlink into the repo) looks
# nothing like a stow change to whoever hits it later. This line makes the
# guarantee explicit and independent of swaync's survival. Narrower than
# the swaync case: a unit FILE (quickshell.service, unlike a drop-in
# DIRECTORY) is followed by systemd even when reached through a symlink,
# so only the PARENT directory needs to be real — this mkdir -p is what
# guarantees that.
mkdir -p "$HOME/.config/systemd/user"

# 13.1-10: pre-create ~/.config/hypr as a REAL directory — a genuine,
# previously-undiscovered fresh-machine reproducibility bug found live by
# this task's own throwaway-home-directory reproduction proof (Criterion
# 7), not a style preference. On a genuinely fresh machine (no prior
# ~/.config/hypr at all), nothing existing prevented stow from folding
# the ENTIRE hypr package into one whole-directory symlink
# (~/.config/hypr -> dotfiles/hypr/.config/hypr) — which every real
# development machine so far has accidentally avoided only because
# ~/.config/hypr/state/ already existed as a real directory from a MUCH
# earlier stow run, long before 13.1-02 introduced this line's own
# `mkdir -p "$HOME/.config/hypr/state"` below. On a true first-ever run,
# that later mkdir -p follows the fold and creates state/ (and the
# tokens.lua symlink `ln -sf` right after it) INSIDE THE CLONED REPO
# TREE instead of under the user's real config directory — a relative
# symlink that then resolves to nothing usable and, worse, writes into
# what should be a clean git checkout. Same pre-create-before-stow idiom
# as fish/gtk-3.0/gtk-4.0/quickshell/systemd above: with the real
# directory already present, stow descends into it and symlinks only its
# individual top-level entries (config/, hyprland.lua, hyprlock.conf,
# hypridle.conf, lib/, scripts/), leaving state/ to be created for real
# right where this file's own later code already assumes it lives.
mkdir -p "$HOME/.config/hypr"

# 13.1-10: pre-create ~/.local as a REAL directory — the SAME fold bug
# just fixed for ~/.config/hypr above, found by the same reproduction run,
# one level higher up the tree and with a wider blast radius: EVERY
# theme-engine generated file lives under ~/.local/state/theme/, not just
# the Hyprland ones. On a genuinely fresh machine, nothing existed at
# ~/.local before this script ran, and the `vscodium` package (stowed
# earlier in the PACKAGES loop below, before this file's later
# `mkdir -p "$HOME/.local/state/theme"` line ever runs) ships a single
# file at .local/share/applications/ — enough for stow to fold the ENTIRE
# ~/.local into one whole-directory symlink pointing at
# dotfiles/vscodium/.local, since nothing blocked the fold. Every real
# development machine so far avoided this purely by accident: ~/.local
# already held unrelated, long-pre-existing content (bin/, share/ from
# years of ordinary system use) before this repo's packages were ever
# stowed, so the fold never had a chance to happen. On a true first-ever
# run, the later `mkdir -p "$HOME/.local/state/theme"` (and every
# theme-apply run after it) follows that fold and writes the ENTIRE
# theme-engine state directory INSIDE THE CLONED REPO TREE
# (dotfiles/vscodium/.local/state/theme/) rather than under the user's
# real state directory — directly contradicting this project's own core
# value ("the whole setup reproduces from scratch with one script") and
# the git-clean invariant theme-doctor's state-manifest gate exists to
# protect. Pre-creating ~/.local here is sufficient: it only needs to
# stop the TOP-LEVEL fold, so vscodium's own ~/.local/share/applications
# entry is still free to fold one level down as before.
mkdir -p "$HOME/.local"

# CR-01/13.1-REVIEW.md: pre-create ~/Pictures/{Wallpapers,Screenshots} as
# REAL directories — the SAME fold-bug class just fixed for ~/.config/hypr
# and ~/.local above, one more instance the code review caught that the
# 13.1-10 reproduction pass didn't (that pass only exercised the `hypr`
# and `vscodium` packages' own targets). The `wallpapers` package
# (PACKAGES array above) ships wallpapers/Pictures/{Wallpapers/**,
# Screenshots/}, and unlike every other package in this file, its target
# (~/Pictures) is NOT nested under ~/.config or ~/.local — so it is not
# covered by either of the two pre-creates above. On a genuinely fresh
# machine, nothing existing prevents `stow --restow wallpapers` from
# folding the ENTIRE ~/Pictures into one whole-directory symlink into the
# repo the moment it is stowed; this file's own later wallpaper-pointer
# seed (`mkdir -p "$HOME/Pictures/Wallpapers"` + `ln -sfr ...
# current.jpg`, below) would then silently write inside the cloned repo
# tree instead of under the user's real Pictures directory, and every
# later wallpaper-switch/theme-apply write and every hyprshot/grim
# screenshot would do the same from then on. Same
# pre-create-before-stow idiom as fish/gtk-3.0/gtk-4.0/quickshell/
# systemd/hypr/.local above: with both leaf directories already real,
# stow descends into ~/Pictures/Wallpapers/<theme>/ and
# ~/Pictures/Screenshots/ and symlinks only their individual file
# entries, never the parent.
#
# Audit note (13.1 gap-closure session): every OTHER package in the
# PACKAGES array below ships exclusively under ~/.config/<pkg>/... or
# ~/.local/<pkg>/... (checked directly against each package's shipped
# tree) — both of those roots are already guaranteed real directories by
# the mkdir -p calls above (each uses `mkdir -p`, which creates every
# missing parent, so ~/.config and ~/.local themselves are real before
# this loop runs regardless of stow order). `wallpapers` is the ONLY
# package whose shipped tree roots at something other than .config/ or
# .local/ directly under $HOME, so it is the only remaining instance of
# this bug class.
#
# Audit-note correction (15-13, G-15-4): the claim above is now narrower
# than it reads. `quickshell` ships a SECOND tree outside its own
# ~/.config/quickshell/ namespace — ~/.config/autostart/nm-applet.desktop,
# the secret-agent suppression override. It is guarded by its own
# `mkdir -p "$HOME/.config/autostart"` further up, so it is not an
# instance of the fold bug; but "every OTHER package ships exclusively
# under ~/.config/<pkg>/" is no longer literally true, and leaving a
# now-false audit claim standing is exactly the failure this correction
# prevents. Two exceptions, then: `wallpapers` (roots outside .config/)
# and `quickshell` (a second .config/ subtree not named for the package).
# vscodium's ~/.local/share/applications entry is still
# free to fold one level below ~/.local (as the ~/.local comment above
# already documents) — harmless, since nothing this script writes
# targets ~/.local/share/ at runtime.
#
# Audit-note correction (18-07, QBAR-10): the 15-13 correction just above
# is itself now narrower than it reads. `quickshell` ships a THIRD tree
# outside its own ~/.config/quickshell/ namespace —
# ~/.config/systemd/user/quickshell.service, this repo's first custom
# systemd --user unit. It is guarded by its own `mkdir -p
# "$HOME/.config/systemd/user"` further up (independent of the swaync
# drop-in pre-create it sits beside), so — like the autostart override
# before it — it is not itself an instance of the fold bug; but leaving
# the 15-13 correction's "two exceptions" claim standing as though it
# were still complete is exactly the failure that correction exists to
# prevent applying to itself. Three exceptions to the "every OTHER
# package ships exclusively under ~/.config/<pkg>/" claim, then:
# `wallpapers` (roots outside .config/), `quickshell`'s
# ~/.config/autostart/ entry, and now `quickshell`'s
# ~/.config/systemd/user/ entry.
mkdir -p "$HOME/Pictures/Wallpapers" "$HOME/Pictures/Screenshots"

# D-02/AMB-01: pre-create each theme's live/ directory as a REAL directory,
# BEFORE the PACKAGES stow loop below — same fold-bug class documented at
# length in the comment block just above (13.1-10/CR-01/G-15-4 precedent).
# Video/animated wallpapers never ship inside the `wallpapers` stow package
# (git must never carry large binaries), so nothing here would otherwise
# create ~/Pictures/Wallpapers/<theme>/live/ on a fresh machine. If this
# loop ran AFTER stowing `wallpapers`, and stow had already folded a theme
# directory into a whole-directory symlink back into the repo (the same
# hazard the comment above just walked through for ~/Pictures itself), the
# mkdir here would write live/ INSIDE THE CLONED REPO TREE instead of under
# the user's real Pictures directory. Placement before the loop is
# load-bearing, not incidental. Enumerate the repo's own theme directories
# so the layout always matches whatever presets are actually shipped —
# same dynamic-enumeration convention as theme-parity/stress-test/picker
# (05-P02, "no hardcoded theme lists").
for theme_dir in "$DOTFILES_DIR"/wallpapers/Pictures/Wallpapers/*/; do
    [[ -d "$theme_dir" ]] || continue
    theme_name="$(basename "$theme_dir")"
    mkdir -p "$HOME/Pictures/Wallpapers/$theme_name/live"
done

for pkg in "${PACKAGES[@]}"; do
    if [[ -d "$pkg" ]]; then
        echo "  → Stowing: $pkg"
        # CR-02: under `set -euo pipefail`, a stow conflict on ANY package
        # here (non-zero exit propagating through the `| sed` pipe) would
        # abort the WHOLE script before ever reaching the motion-file seed
        # below — silently skipping the one seed step this file's own
        # comments call the most critical, "must fail loudly, not silently"
        # write. `if ! ... ; then` short-circuits set -e's abort for just
        # this one pipeline so one package's conflict doesn't take down
        # every later package (and the motion seed) with it; re-running
        # stow.sh after resolving the conflict is the existing, documented
        # recovery path (WR-05: seed only when absent — stow.sh is
        # re-runnable).
        if ! stow --restow "$pkg" --target="$HOME" 2>&1 | sed 's/^/    /'; then
            echo "  ⚠ stow failed for $pkg — continuing with remaining packages" >&2
        fi
    else
        echo "  ⚠ Skipping: $pkg (directory not found)"
    fi
done

# ── Make scripts executable ──────────────────────────
echo ""
echo "Making scripts executable..."
chmod +x "$HOME/.config/hypr/scripts/"*.sh 2>/dev/null || true

# ── Initialize cache ─────────────────────────────────
# Theme state now lives in ~/.local/state/theme/ (D-05) — theme-init.sh
# falls back to catppuccin automatically when no state exists yet (D-10),
# so no pre-seed is needed here.
mkdir -p "$HOME/.cache"
# WR-05: seed only when absent — stow.sh is re-runnable, and an
# unconditional write clobbers the user's currently selected layout.
[[ -f "$HOME/.cache/current-waybar-layout" ]] || echo "full" > "$HOME/.cache/current-waybar-layout"

# D-27/D-28: seed-only-when-absent (same idiom as above) — guarantees the
# gaming-mode state file exists on a fresh install so gaming-mode-toggle.sh
# never has to handle a missing-file case on first read. This is NOT the
# D-28 session reset (that's the unconditional autostart.conf exec-once
# hook) — re-running stow.sh mid-session must never clobber an active
# toggle's state.
[[ -f "$HOME/.cache/gaming-mode" ]] || echo "off" > "$HOME/.cache/gaming-mode"

# BAR-01/D-03/D-06: seed waybar's exclusive CSS override file empty, same
# seed-only-when-absent idiom as above — every
# style-{full,athena,floating,vertical}.css @imports this file LAST, and an
# unresolvable @import makes GTK3 discard the WHOLE stylesheet. As of
# Phase 18 Plan 15/QBAR-07 this file has NO writer at all — the owner
# (renamed bar-visibility.sh) actuates the QML bar over Quickshell IPC
# instead and no longer touches this path — so THIS SEED IS THE FILE'S
# ONLY REMAINING WRITER. It stays seed-only-when-absent rather than
# unconditional purely for re-run safety (a stow.sh re-run must never
# clobber whatever is on disk). Do NOT remove this seed before RETIRE-02
# (18-20) — waybar's four stylesheets still resolve their @import against
# this exact path until that plan deletes waybar, this file, its
# contract.json entry and this seed together.
mkdir -p "$HOME/.local/state/theme"
[[ -f "$HOME/.local/state/theme/waybar-visibility.css" ]] || : > "$HOME/.local/state/theme/waybar-visibility.css"

# D-06/D-07: seed the motion-scale axis to its default, same seed-only-
# when-absent idiom as above — an absent file already reads as "normal"
# through theme_engine_read_motion_scale's closed case, but a fresh
# install should have the file present rather than relying on every
# reader's fallback branch being exercised correctly on day one.
[[ -f "$HOME/.local/state/theme/motion-scale" ]] || echo "normal" > "$HOME/.local/state/theme/motion-scale"

# D-30/D-31: seed the weather location/units state axis, same seed-only-
# when-absent idiom as above (state dir already created by the
# waybar-visibility.css seed further up — no second mkdir -p needed here).
# Every key is a top-level SCALAR — never a nested object. `JsonAdapter`
# (Quickshell.Io) binds only top-level JSON keys to declared properties
# (verified directly against the installed qmltypes, and already
# documented in Motion.qml's own header, which is why THAT file receives
# its `semantic` sub-object into a bare `var` and destructures by hand); a
# nested `{location: {lat, lon}, units: {...}}` shape would bind nothing
# and 14-07's weather widget would silently render its defaults forever
# with no error anywhere (14-RESEARCH.md Pitfall 5). This is the
# pipeline's first deliberately multi-key flat state file — read it as an
# intentional pattern deviation, not drift.
#
# 30.04/31.24 is the Cairo city centroid at two decimal places, derived
# from this host's Africa/Cairo system timezone — NOT this user's actual
# home coordinates. Two decimals is deliberately city-level, not
# street-level: the repo is public, and precise home coordinates
# committed to git are self-doxxing (D-30). A GeoIP/ip-api.com-class
# lookup is a REJECTED mechanism here, not a missing feature — do not
# "improve" this seed into one (14-07 owns that prohibition). Refinements
# to the actual seeded value belong in this file, in
# ~/.local/state/theme/, which is never git-tracked, so they never reach
# a public repo either.
#
# Metric-seeded per D-31 (the user chose this over a fixed-metric
# recommendation specifically so the axis stays switchable): three
# separate unit keys, one per quantity, because 14-07's formatting layer
# is unit-aware for temperature, wind and precipitation independently.
# No API key, token, secret or credential of any kind belongs in this
# file — Open-Meteo (D-29) is keyless precisely so that stays true.
[[ -f "$HOME/.local/state/theme/weather.json" ]] || cat > "$HOME/.local/state/theme/weather.json" <<'WEATHER_SEED_EOF'
{
  "lat": 30.04,
  "lon": 31.24,
  "units_temp": "metric",
  "units_wind": "metric",
  "units_precip": "metric"
}
WEATHER_SEED_EOF

# D-30: seed the rendered motion files by INVOKING motion.sh's own
# renderer — never a hand-authored stub. A stub is a second source of
# truth that goes stale the instant a motion.json edit lands; D-30's whole
# point is that motion.json stays the ONLY place these numbers are
# written. This is the one seed among all the ones in this file whose
# absence is worst: 13.1-10 retired the hyprlang hyprland-motion.conf
# emitter (its old failure mode here was a hard `source=` globbing error),
# so the failure being guarded against on the Hyprland side is now a
# missing `require()` target for hyprland-tokens.lua — module-not-found
# stops the compositor from starting at all, which is strictly HARDER to
# recover from at a TTY than a missing hyprlang source glob ever was, not
# easier. An absent/never-rendered motion-scale separately leaves
# $motion_enabled undefined in animations.lua's own token read — also a
# config-parse failure that keeps Hyprland from starting, debugged from a
# TTY, not a graceful degrade. The unconditional `|| true` guard on the
# surrounding block still applies (this must never abort stow.sh under
# set -e), but unlike the other seeds here, a failure here is loud, not
# silent — WR-07's "first impression is a themed desktop" only holds if
# this succeeds.
if [[ ! -f "$HOME/.local/state/theme/gtk-4.0-motion.css" ]] || \
   [[ ! -f "$HOME/.local/state/theme/motion.json" ]] || \
   [[ ! -f "$HOME/.local/state/theme/hyprland-tokens.lua" ]]; then
    MOTION_LIB="$DOTFILES_DIR/theme-engine/.config/theme-engine/lib/motion.sh"
    if [[ -f "$MOTION_LIB" ]]; then
        (
            set -uo pipefail
            STATE_DIR="$HOME/.local/state/theme"
            # shellcheck source=theme-engine/.config/theme-engine/lib/motion.sh
            source "$MOTION_LIB"
            SEED_TMP="$(mktemp -d)"
            trap 'rm -rf "$SEED_TMP"' EXIT
            if theme_engine_render_motion_files "$SEED_TMP"; then
                mkdir -p "$STATE_DIR"
                # Phase 13.1/D-30: hyprland-tokens.lua joins this seed list
                # — a missing require() target is a HARDER failure than a
                # missing hyprlang `source=` glob ever was (module-not-found
                # stops the compositor from starting at all, not just one
                # fragment), so it gets the identical loud-failure
                # treatment as the other motion targets, never a
                # hand-authored stub. 13.1-10 removed hyprland-motion.conf
                # from this list — the hyprlang emitter that produced it no
                # longer exists.
                for mf in motion.json gtk-4.0-motion.css hyprland-tokens.lua; do
                    [[ -f "$SEED_TMP$STATE_DIR/$mf" ]] && cp "$SEED_TMP$STATE_DIR/$mf" "$STATE_DIR/$mf"
                done
            else
                echo "  ⚠ motion.sh seed render failed — a fresh install's first Hyprland start WILL fail until theme-apply runs successfully first" >&2
                exit 1
            fi
        ) || echo "  ⚠ motion-file seed did not complete — see error above; Hyprland will NOT start until this is resolved (run theme-apply manually)" >&2
    else
        echo "  ⚠ $MOTION_LIB not found — skipping motion-file seed; Hyprland will NOT start without these files" >&2
    fi
fi

# Phase 13.1/D-02/D-05: pre-create ~/.config/hypr/state/ as a REAL
# directory (same "create it real so stow does not fold it" treatment as
# fish/gtk-3.0/gtk-4.0/quickshell above) and wire
# hypr/.config/hypr/state/tokens.lua as a RELATIVE symlink to the merged
# token file the seed block immediately above this one just guaranteed
# exists. Relative, never absolute — the same reproducibility rule that
# made the wallpaper symlink relative in quick task 260709-ciu. Three
# levels up from ~/.config/hypr/state/ is $HOME: state/ -> hypr/ ->
# .config/ -> $HOME. Deliberately NOT added to the hypr/ stow package
# itself — state/ is a host-side symlink target, not repo content.
mkdir -p "$HOME/.config/hypr/state"
ln -sf "../../../.local/state/theme/hyprland-tokens.lua" "$HOME/.config/hypr/state/tokens.lua"

# D-01/D-05/13-02/13-05: seed the sass-compiled GTK3 stylesheet(s) by
# INVOKING the real renderer AND the real compiler — never a
# hand-authored/pre-compiled stub. Mirrors the motion-file seed block
# immediately above, same rationale: after swaync's AND waybar's
# conversion, the files swaync-launch.sh/waybar-launch.sh point at only
# exist if sass actually ran — today they are stow symlinks present the
# instant stow.sh runs; after these plans they are generated artifacts
# that must be rendered. Never committing a pre-compiled default sheet
# would make it a second source of truth that goes stale the moment a
# swaync/*.scss or waybar/*.scss edit lands (this repo's most-enforced
# invariant). 13-05 extends the seed list from swaync's two outputs to
# all seven compiled sheets (the sass partial + swaync's one sheet + all
# six waybar sheets) — same seed mechanism, same all-or-nothing check
# (all seven must already exist or the whole seed re-runs), because a bar
# that starts with five sheets present and one missing is exactly the
# "unstyled bar with no error to search for" D-05 forbids.
# Deliberately NOT given line 135's `|| true` tolerance (D-05 explicit):
# a silently unstyled desktop with no error to search for is worse than a
# failed install, so a failure here prints a loud, specific message and
# leaves a non-zero trail rather than degrading quietly.
GTK3_SASS_SEED_FILES=(
    _motion.scss
    swaync-style.css
    waybar-theme.css
    waybar-modules.css
    waybar-style-full.css
    waybar-style-athena.css
    waybar-style-floating.css
    waybar-style-vertical.css
)
GTK3_SASS_SEED_MISSING=0
for _sf in "${GTK3_SASS_SEED_FILES[@]}"; do
    [[ -f "$HOME/.local/state/theme/$_sf" ]] || GTK3_SASS_SEED_MISSING=1
done
if [[ "$GTK3_SASS_SEED_MISSING" == "1" ]]; then
    MOTION_LIB="$DOTFILES_DIR/theme-engine/.config/theme-engine/lib/motion.sh"
    if [[ -f "$MOTION_LIB" ]]; then
        (
            set -uo pipefail
            STATE_DIR="$HOME/.local/state/theme"
            # shellcheck source=theme-engine/.config/theme-engine/lib/motion.sh
            source "$MOTION_LIB"
            SEED_TMP="$(mktemp -d)"
            trap 'rm -rf "$SEED_TMP"' EXIT
            if theme_engine_render_motion_files "$SEED_TMP" && theme_engine_compile_gtk3_stylesheets "$SEED_TMP"; then
                mkdir -p "$STATE_DIR"
                for mf in _motion.scss swaync-style.css waybar-theme.css waybar-modules.css \
                          waybar-style-full.css waybar-style-athena.css \
                          waybar-style-floating.css waybar-style-vertical.css; do
                    [[ -f "$SEED_TMP$STATE_DIR/$mf" ]] && cp "$SEED_TMP$STATE_DIR/$mf" "$STATE_DIR/$mf"
                done
            else
                echo "  ⚠ GTK3 sass-compile seed failed — swaync/waybar will start UNSTYLED (or fail to start, depending on the failure) until theme-apply runs successfully first" >&2
                exit 1
            fi
        ) || echo "  ⚠ GTK3 sass-compile seed did not complete — see error above; run theme-apply manually to resolve" >&2
    else
        echo "  ⚠ $MOTION_LIB not found — skipping GTK3 sass-compile seed; swaync/waybar will start unstyled without these files" >&2
    fi
fi

# D-23: seed the wallpaper pointer, same seed-only-when-absent idiom as
# above — current.jpg is now untracked and gitignored (WINDOWS.md entry 9:
# it is runtime state, rewritten on every static theme switch by
# lib/wallpaper.sh's `ln -sfr`, never repo content), so a fresh install has
# nothing providing it unless this seed runs. theme-init.sh and
# hyprlock.conf both read this exact path directly, and generate.sh reads
# it as the Material You source image — all three degrade (no wallpaper,
# no lock background, no Material You source) but none of them, and
# nothing else in the boot path, fails to start without it. That is the
# opposite failure posture from the motion-file/GTK3-sass seeds above
# (whose absence is a hard config-parse failure that keeps Hyprland from
# starting at all) — deliberately kept as a warning, not a loud `exit 1`,
# because a themed-but-wallpaperless desktop is a degrade, not a crash.
# Must be a RELATIVE symlink (`ln -sfr`), matching the runtime writer —
# an absolute symlink for this exact file already broke fresh installs
# once before (quick task 260709-ciu).
if [[ ! -L "$HOME/Pictures/Wallpapers/current.jpg" ]]; then
    WALLPAPER_SEED_TARGET="$DOTFILES_DIR/wallpapers/Pictures/Wallpapers/catppuccin/5-alien-planet.jpg"
    if [[ -f "$WALLPAPER_SEED_TARGET" ]]; then
        mkdir -p "$HOME/Pictures/Wallpapers"
        if ln -sfr "$WALLPAPER_SEED_TARGET" "$HOME/Pictures/Wallpapers/current.jpg" 2>/dev/null; then
            :
        else
            echo "  ⚠ wallpaper pointer seed failed — no wallpaper, lock-screen background, or Material You source until a theme switch runs successfully" >&2
        fi
    else
        echo "  ⚠ $WALLPAPER_SEED_TARGET not found — skipping wallpaper pointer seed" >&2
    fi
fi

# ── Switch to zshell ─────────────────────────────────
# Pitfall 6/D-59: a non-root `chsh` prompts for the invoking user's login
# password via PAM, breaking the strictly-zero-prompts requirement. A
# root-privileged shell change bypasses that PAM prompt entirely.
# WR-03: guarded — the shell change is cosmetic relative to the first-boot
# theme seed below, so a missing zsh or a failed sudo/chsh must never abort
# the script under set -e before that seed runs.
if command -v zsh >/dev/null 2>&1; then
    sudo chsh -s "$(command -v zsh)" "$USER" || echo "  ⚠ chsh failed — change shell manually" >&2
else
    echo "  ⚠ zsh not installed — skipping shell change" >&2
fi

# ── Seed first-boot theme baseline (D-60/WR-07) ──────
# Run theme-apply once now that theme-engine is stowed, so
# ~/.local/state/theme/ exists before first login (first impression is a
# fully themed desktop, not an empty state dir). theme-apply's reload step
# already degrades harmlessly without a running Hyprland session (every
# reload call is `|| true`-guarded internally) — the `|| true` here is
# belt-and-suspenders so a missing entrypoint never aborts stow.sh under
# set -e; the rendered state files are what matters, not the reload.
echo ""
echo "Seeding first-boot theme baseline..."
THEME_APPLY="$HOME/.config/theme-engine/theme-apply"
if [[ -x "$THEME_APPLY" ]]; then
    # theme-apply catppuccin — seeds ~/.local/state/theme/ with the
    # catppuccin baseline before first login.
    "$THEME_APPLY" catppuccin || true
else
    echo "  ⚠ theme-apply not found at $THEME_APPLY — skipping seed"
fi

echo ""
echo "╔══════════════════════════════════════════╗"
echo "║       Dotfiles stowed successfully!      ║"
echo "╚══════════════════════════════════════════╝"
echo ""
echo "Next steps:"
echo "  1. Add wallpapers to ~/Pictures/Wallpapers/"
echo "  2. Log into Hyprland"
echo "  3. Use Super+Shift+T to switch themes"
echo "  4. Use Super+Shift+W to switch waybar layouts"
echo "  5. Use Super+Shift+B to pick wallpapers"
