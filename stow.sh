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
    cava
    fastfetch
    fish
    gtk
    hypr
    kitty
    matugen
    nvim
    quickshell
    theme-engine
    thunar
    uwsm
    vscodium
    wallpapers
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

# D-03, quick task 260820-0ha: pre-create ~/.config/zellij as a real
# directory, same fold-bug idiom as the fisher and quickshell pre-creates
# above: stow folds an unclaimed ~/.config/X into a single whole-directory
# symlink the first time it sees the directory missing, after which
# anything written there lands INSIDE THE CLONED REPO TREE, breaking the
# git-clean invariant theme-doctor's state-manifest gate exists to
# protect. No zellij stow package ships today — this is a FORWARD GUARD,
# not a fix for a current bug, so do not delete it as dead code. If a
# zellij stow package were ever added, and this guard were missing, stow
# would fold the directory into the repo, and commit.sh's `ln -sf` would
# then create config.kdl inside it — the exact failure this guard exists
# to prevent. commit.sh carries its own folded-symlink guard as the second
# layer, so the two are belt-and-braces rather than duplicates. Placement
# before the PACKAGES loop is load-bearing on its own: this mkdir must run
# before the loop reaches whatever package might one day claim
# ~/.config/zellij, or the fold happens first and this guard arrives too
# late to prevent it.
mkdir -p "$HOME/.config/zellij"

# quick task 260820-nua (themed nvim): pre-create ~/.config/nvim as a real
# directory, same fold-bug idiom as the fisher/quickshell/zellij pre-creates
# above — with one difference from the zellij guard: this is NOT a forward
# guard for a package that might arrive later. The nvim/ stow package ships
# in this same change, so without this line the very first stow run would
# fold the whole directory into the repo, and anything nvim later writes
# there (lazy.nvim's own lockfile updates included) would land inside the
# git checkout instead of a real host directory.
mkdir -p "$HOME/.config/nvim"

# 13-02 (drop-in pre-create) stood here until Phase 19 Plan 19-08 Task 5
# (RETIRE-03) deleted the notification daemon whose PACKAGED unit it
# overrode — the drop-in, its unit and its package are all gone, so the
# pre-create has nothing left to protect. The finding it recorded still
# holds and still applies to any FUTURE stowed systemd drop-in in this
# repo: systemd silently ignores an entire .d drop-in directory when the
# directory itself is a symlink, so the real directory must exist before
# stow runs (13-02-SUMMARY.md carries the DropInPaths= empty-vs-populated
# evidence).

# 18-07 (QBAR-10): pre-create ~/.config/systemd/user itself as a REAL
# directory. This line was written to be independent of the drop-in
# pre-create that used to sit directly above it, precisely BECAUSE Phase
# 19 was going to delete that daemon — otherwise the protection this
# parent incidentally received would have vanished silently along with
# it, and the resulting symptom (a unit file systemd cannot see because
# its directory became a symlink into the repo) looks nothing like a stow
# change to whoever hits it later. That deletion has now happened, and
# this line is what still guarantees the parent. Narrower than the
# drop-in case: a unit FILE (quickshell.service, unlike a drop-in
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
# "$HOME/.config/systemd/user"` further up (which no longer sits beside
# any drop-in pre-create), so — like the autostart override
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
# D-27/D-28: seed-only-when-absent — guarantees the gaming-mode state
# file exists on a fresh install so gaming-mode-toggle.sh never has to
# handle a missing-file case on first read. This is NOT the D-28 session
# reset (that's the unconditional autostart.conf exec-once hook) —
# re-running stow.sh mid-session must never clobber an active toggle's
# state.
[[ -f "$HOME/.cache/gaming-mode" ]] || echo "off" > "$HOME/.cache/gaming-mode"

# BAR-01/D-03/D-06: this section seeded the retired bar's exclusive CSS
# override file empty from Phase 8 onward, since every one of its
# stylesheets @import'd this file LAST and an unresolvable @import made
# GTK3 discard the WHOLE stylesheet. By Phase 18 Plan 15/QBAR-07 the file
# had no writer at all left besides this seed — the owner (renamed
# bar-visibility.sh) actuates the QML bar over Quickshell IPC instead and
# never touched this path. RETIRE-02 (18-20) deleted the retired bar, this
# state file, its contract.json entry and this seed together, which is
# why only the state-dir creation below survives — the remaining seeds in
# this section still need it.
mkdir -p "$HOME/.local/state/theme"

# D-06/D-07 (rebased for the style/accessibility axis split by
# quick-260821-swp): seed via theme_engine_migrate_motion_state so a fresh
# install and an upgrading one (a legacy motion-scale value present) take
# the EXACT SAME path — never a hand-written literal here that could drift
# from that function's own migration rules. An absent style file already
# reads as "md3"/"full" through the closed-set readers' own fallback, but a
# fresh install should have both files present rather than relying on
# every reader's fallback branch being exercised correctly on day one.
MOTION_LIB_SEED="$DOTFILES_DIR/theme-engine/.config/theme-engine/lib/motion.sh"
if [[ -f "$MOTION_LIB_SEED" ]]; then
    (
        set -uo pipefail
        # shellcheck source=theme-engine/.config/theme-engine/lib/motion.sh
        source "$MOTION_LIB_SEED"
        theme_engine_migrate_motion_state
    ) || echo "  ⚠ motion-state seed did not complete — see error above; theme-apply will attempt it again" >&2
else
    echo "  ⚠ $MOTION_LIB_SEED not found — skipping motion-state seed" >&2
    [[ -f "$HOME/.local/state/theme/motion-style" ]] || echo "md3" > "$HOME/.local/state/theme/motion-style"
    [[ -f "$HOME/.local/state/theme/motion-accessibility" ]] || echo "full" > "$HOME/.local/state/theme/motion-accessibility"
fi

# D-30/D-31: seed the weather location/units state axis, same seed-only-
# when-absent idiom as above (state dir already created further up — no
# second mkdir -p needed here).
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
#
# Seeded city changed Cairo -> Alexandria (quick task 260819-3mz): the
# operator is in Alexandria, so a fresh install that seeded Cairo would
# not reproduce their actual setup — it silently served a forecast for
# the wrong city ~180km away (measured 28.5C vs 25.6C at the time of the
# change). Deliberately kept at TWO decimal places, city-centroid, per
# the self-doxxing rule above: their live ~/.local/state/theme/ copy
# carries full precision, this public one must not. Verified the coarse
# value still reverse-geocodes to "Alexandria" rather than a suburb.
[[ -f "$HOME/.local/state/theme/weather.json" ]] || cat > "$HOME/.local/state/theme/weather.json" <<'WEATHER_SEED_EOF'
{
  "lat": 31.20,
  "lon": 29.92,
  "units_temp": "metric",
  "units_wind": "metric",
  "units_precip": "metric"
}
WEATHER_SEED_EOF

# news-sources.json (quick task 260819-6oy): the operator's hand-edited
# surface for the notification centre's News tab. Adding a feed means
# editing this file — there is deliberately NO in-shell editor (locked
# decision 2 in .planning/notes/news-tab-feed-parsing.md, deferred to a
# seed, same as this pattern already applies to weather.json above).
#
# It carries NO API key, token or credential of any kind, and must not
# grow one — every default feed is a public, keyless RSS/Atom endpoint.
# Same standing rule the weather.json seed above already states.
#
# Every "url" MUST be https://. NewsBackend.qml rejects and logs anything
# else rather than fetching it (the two-point scheme allowlist); this
# seed must never be the thing that teaches someone a plain-http entry
# is acceptable.
#
# "enabled": false disables a source without deleting it.
#
# The three tunables below are clamped by NewsBackend.qml (see its
# header) — a hostile or fat-fingered value here cannot turn this into
# an unbounded fetch.
#
# "view_mode" (quick task 260819-m94) — "compact" | "cards" — is the one
# key in this file the shell itself writes back, via the News tab's view
# toggle. Everything else here is the operator's own surface.
[[ -f "$HOME/.local/state/theme/news-sources.json" ]] || cat > "$HOME/.local/state/theme/news-sources.json" <<'NEWS_SEED_EOF'
{
  "sources": [
    { "name": "BBC World", "url": "https://feeds.bbci.co.uk/news/world/rss.xml", "enabled": true },
    { "name": "Ars Technica", "url": "https://feeds.arstechnica.com/arstechnica/index", "enabled": true },
    { "name": "It's FOSS", "url": "https://itsfoss.com/rss/", "enabled": true },
    { "name": "Phoronix", "url": "https://www.phoronix.com/rss.php", "enabled": true }
  ],
  "max_items_per_source": 15,
  "max_items_total": 40,
  "ttl_minutes": 15,
  "view_mode": "compact"
}
NEWS_SEED_EOF

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

# Quick task 260820-sqd, Task 3: the SAME state/-symlink treatment,
# second instance — Display+input overrides (monitor mode/position/
# scale, keyboard/mouse settings) persisted through the settings window.
# Seed-only-when-absent (the D-27/D-28 idiom above): re-running stow.sh
# must never clobber an operator's already-adjusted overrides. Relative,
# never absolute — the same reproducibility rule tokens.lua's own symlink
# follows two lines up.
mkdir -p "$HOME/.local/state/hypr"
[[ -f "$HOME/.local/state/hypr/overrides.lua" ]] || echo "return {}" > "$HOME/.local/state/hypr/overrides.lua"
ln -sf "../../../.local/state/hypr/overrides.lua" "$HOME/.config/hypr/state/overrides.lua"

# Quick task 260820-sqd, Task 4: idle/lock listeners, the SAME seed-only-
# when-absent idiom as weather.json/news-sources.json above. This seed is
# LOAD-BEARING for a security property, not just convenience: hypridle
# proceeds with ZERO rules on a broken/missing config rather than failing
# loudly (PD-03 probe A, measured) — a fresh install with no seeded file
# here would get zero idle listeners and NEVER LOCK. All five listener
# blocks moved out of the tracked hypridle.conf (Task 4 Step 2 — hyprlang
# APPENDS listener blocks rather than replacing them, so any left behind
# in the tracked file would coexist with an override and fire at
# whichever timeout is shorter). Sourced by an absolute-ish path in
# hypridle.conf itself, not a symlink — no `ln -sf` needed here.
[[ -f "$HOME/.local/state/hypr/idle-overrides.conf" ]] || cat > "$HOME/.local/state/hypr/idle-overrides.conf" <<'IDLE_SEED_EOF'
# ── Bar idle hide (BAR-01/D-05, repointed Phase 18 Plan 15/QBAR-07) ──
# Declares the "idle" intent to the visibility owner; the owner computes
# the resulting state (D-01's OR-union across idle/fullscreen/gaming) and
# actuates the QML bar over Quickshell IPC. Never calls `qs ipc call bar`
# directly. 120s is deliberately shorter than the 300s dim listener below
# it: D-01's OLED concern is "a static bar lit for hours while you read or
# code," so the bar's own idle threshold must be meaningfully shorter than
# the screen-dim listener or it never fires during exactly the scenario it
# exists for. on-resume fires on any keypress/mouse movement, so
# idle-hide clears on any input with no extra machinery (D-02).
listener {
    timeout = 120
    on-timeout = ~/.config/hypr/scripts/bar-visibility.sh idle hide
    on-resume = ~/.config/hypr/scripts/bar-visibility.sh idle show
}

# ── Dim screen after 5 minutes (D-30) ────────────────
# D-30 chains the live-wallpaper owner's idle suppression onto THIS
# existing listener rather than adding a new one. Confirmed live that
# hypridle chains multiple shell commands on one on-timeout/on-resume
# line correctly (each command fires independently, in order) — no
# wrapper script needed.
listener {
    timeout = 300
    on-timeout = brightnessctl -s set 30% && ~/.config/hypr/scripts/wallpaper-visibility.sh idle hide
    on-resume = brightnessctl -r && ~/.config/hypr/scripts/wallpaper-visibility.sh idle show
}

# ── Lock screen after 10 minutes ─────────────────────
listener {
    timeout = 600
    on-timeout = loginctl lock-session
}

# ── Turn off display after 15 minutes ────────────────
# Table form is mandatory — the bare-string dpms form is a silent no-op
# under the Lua config manager, and the string TOGGLE form (as opposed to
# the table ENABLE/DISABLE form) would switch the display back OFF on
# every wake, since wake-on-input has already turned it on by the time
# on-resume runs (misc:mouse_move_enables_dpms/misc:key_press_enables_dpms).
listener {
    timeout = 900
    on-timeout = hyprctl dispatch 'hl.dsp.dpms({action="off"})'
    on-resume = hyprctl dispatch 'hl.dsp.dpms({action="on"})'
}

# ── Suspend after 30 minutes ─────────────────────────
listener {
    timeout = 1800
    on-timeout = systemctl suspend
}
IDLE_SEED_EOF

# D-01/D-05/13-02/13-05: seed the sass-compiled GTK3 stylesheet(s) by
# INVOKING the real renderer AND the real compiler — never a
# hand-authored/pre-compiled stub. Mirrors the motion-file seed block
# immediately above, same rationale: a compiled sheet only exists if sass
# actually ran, so it is a generated artifact that must be rendered rather
# than a file present the instant stow.sh runs. Never committing a
# pre-compiled default sheet would make it a second source of truth that
# goes stale the moment a *.scss edit lands (this repo's most-enforced
# invariant). This list has shrunk twice as surfaces retired: 13-05 briefly
# extended it to seven compiled sheets (the sass partial, one belonging to
# the notification daemon, and six belonging to a bar), RETIRE-02/18-20
# dropped the bar's six, and Phase 19 Plan 19-08 Task 5 (RETIRE-03) dropped
# the notification daemon's one when it deleted that daemon — leaving the
# sass partial alone, which is what lib/motion.sh's GTK3_SCSS_TARGETS still
# compiles. Same all-or-nothing check, because a surface that starts with
# some sheets present and one missing is exactly the "unstyled surface with
# no error to search for" D-05 forbids.
# Deliberately NOT given line 135's `|| true` tolerance (D-05 explicit):
# a silently unstyled desktop with no error to search for is worse than a
# failed install, so a failure here prints a loud, specific message and
# leaves a non-zero trail rather than degrading quietly.
GTK3_SASS_SEED_FILES=(
    _motion.scss
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
                for mf in _motion.scss; do
                    [[ -f "$SEED_TMP$STATE_DIR/$mf" ]] && cp "$SEED_TMP$STATE_DIR/$mf" "$STATE_DIR/$mf"
                done
            else
                echo "  ⚠ GTK3 sass-compile seed failed — GTK3 surfaces will start UNSTYLED until theme-apply runs successfully first" >&2
                exit 1
            fi
        ) || echo "  ⚠ GTK3 sass-compile seed did not complete — see error above; run theme-apply manually to resolve" >&2
    else
        echo "  ⚠ $MOTION_LIB not found — skipping GTK3 sass-compile seed; GTK3 surfaces will start unstyled without these files" >&2
    fi
fi

# D-19-45: seed the active-wallpaper pointer, same seed-only-when-absent
# idiom as above — the pointer now lives at
# ~/.local/state/theme/current.jpg (moved OUT of the stow-managed
# Wallpapers directory entirely; superseding D-23's untrack-and-gitignore
# fix, which still left it inside the stow tree). It is runtime state,
# rewritten on every static theme switch by lib/wallpaper.sh's symlink
# repoint, never repo content, so a fresh install has nothing providing it
# unless this seed runs. theme-init.sh and hyprlock.conf both read this
# exact path directly, and generate.sh reads it as the Material You source
# image — all three degrade (no wallpaper, no lock background, no
# Material You source) but none of them, and nothing else in the boot
# path, fails to start without it. That is the opposite failure posture
# from the motion-file/GTK3-sass seeds above (whose absence is a hard
# config-parse failure that keeps Hyprland from starting at all) —
# deliberately kept as a warning, not a loud `exit 1`, because a
# themed-but-wallpaperless desktop is a degrade, not a crash.
# Must be a RELATIVE symlink (`ln -sfr`), matching the runtime writer —
# an absolute symlink for this exact file already broke fresh installs
# once before (quick task 260709-ciu). The state directory itself is
# already guaranteed real (created earlier in this file, well before this
# seed runs) — no separate mkdir -p needed for the parent here.
if [[ ! -L "$HOME/.local/state/theme/current.jpg" ]]; then
    WALLPAPER_SEED_TARGET="$DOTFILES_DIR/wallpapers/Pictures/Wallpapers/catppuccin/5-alien-planet.jpg"
    if [[ -f "$WALLPAPER_SEED_TARGET" ]]; then
        mkdir -p "$HOME/.local/state/theme"
        if ln -sfr "$WALLPAPER_SEED_TARGET" "$HOME/.local/state/theme/current.jpg" 2>/dev/null; then
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

# ── Restore nvim's plugins (quick task 260820-nua) ───
# Runs here, not in install.sh: install.sh executes BEFORE this script, so
# ~/.config/nvim does not exist yet at that point. This step needs both
# the config tree (just stowed above) AND the rendered palette (just
# seeded above) to exist, so it belongs right here.
#
# VERIFIED, not the commonly-repeated single-command form: `:Lazy restore`
# only acts on plugins lazy.nvim already considers installed (its own
# manage/init.lua filters on `plugin._.installed`) — on a genuinely fresh
# machine with nothing cloned yet, `:Lazy restore` alone is a silent no-op.
# `:Lazy install` clones everything but only checks out each plugin's spec
# constraint (branch/version/tag), not the exact commit in the lockfile.
# The two together — install, then restore — is what was measured on this
# host to land every plugin on the exact commit committed in
# nvim/.config/nvim/lazy-lock.json (confirmed by diffing every plugin's
# resolved HEAD before and after a from-scratch run).
#
# Guarded on the `nvim` binary being present, timeout-bounded, and
# non-fatal — stow.sh runs under `set -euo pipefail` and a network hiccup
# here must not abort the script after everything else already succeeded,
# the same posture the zellij plugin fetch takes further up this file.
if command -v nvim >/dev/null 2>&1; then
    echo ""
    echo "Restoring nvim plugins..."
    timeout 300 nvim --headless "+Lazy! install" "+Lazy! restore" +qa 2>&1 | tail -5 || \
        echo "  ⚠ nvim plugin restore did not complete — run it manually: nvim --headless \"+Lazy! install\" \"+Lazy! restore\" +qa" >&2
else
    echo "  ⚠ nvim not installed — skipping plugin restore"
fi

# Rebuild the user desktop-entry MIME cache. Without a mimeinfo.cache in
# ~/.local/share/applications, `gio mime <type>` reports only the system
# entries — measured on this host: it listed yazi.desktop but not the stowed
# codium.desktop, despite codium declaring inode/directory. The Settings →
# Apps default-app pickers build their candidate lists from exactly that
# `gio mime` output, so the repo's own wrapper entries (yazi-terminal,
# nvim-terminal) would never appear in them until this runs. Guarded and
# non-fatal, matching the nvim/zellij posture above.
if command -v update-desktop-database >/dev/null 2>&1; then
    echo ""
    echo "Rebuilding the desktop-entry MIME cache..."
    update-desktop-database "$HOME/.local/share/applications" || \
        echo "  ⚠ update-desktop-database failed — the Apps pickers may not list the wrapper entries" >&2
else
    echo "  ⚠ update-desktop-database not installed (desktop-file-utils) — skipping MIME cache rebuild"
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
echo "  4. Use Super+B to switch bar orientation"
echo "  5. Use Super+Shift+B to pick wallpapers"
echo "  6. Run nvim — LSP, completion, treesitter and the rest of the slate are already restored"
