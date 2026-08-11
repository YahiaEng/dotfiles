#!/usr/bin/env bash
# theme-engine/lib/commit.sh — atomic commit step (D-14)
#
# Only ever invoked after theme_engine_generate returns 0 — a failed render
# never reaches here, so the live desktop is never touched by a half-
# rendered theme. Moves the rendered tree into ~/.local/state/theme/ and
# wires the two apps with no native import mechanism (walker, yazi — D-07).

STATE_DIR="$HOME/.local/state/theme"

# shellcheck source=lib/contract.sh
source "$LIB_DIR/contract.sh"

# theme_engine_commit <name> <tmp_dir>
theme_engine_commit() {
    local name="$1"
    local tmp="$2"

    # matugen's -p/--prefix flag prepends $tmp to the ABSOLUTE resolved
    # output_path (~ expands to $HOME first), so the rendered tree lives at
    # $tmp$STATE_DIR, not $tmp itself (verified empirically this session).
    local rendered_dir="$tmp$STATE_DIR"

    if [[ ! -d "$rendered_dir" ]]; then
        echo "commit.sh: rendered output not found at $rendered_dir" >&2
        return 1
    fi

    mkdir -p "$STATE_DIR"

    # Atomic replace: state dir contents only change here, in one step,
    # after a fully successful render (D-14).
    #
    # Deviation (fix, Plan 02-02 Task 2, D-40): excluding the logs
    # directory is required. Without it, a bare `rsync -a --delete` treats
    # $STATE_DIR/logs/ (added in Plan 02-01 by theme-parity, D-45) as an
    # extraneous destination path not present in $rendered_dir (matugen
    # never renders a logs/ subdirectory — it is not part of the output
    # contract) and DELETES it whole on every single theme-apply commit —
    # silently destroying theme-parity's and theme-stress-test's entire
    # regression-log history on the very next real theme switch.
    # Reproduced empirically this round: a 2-switch theme-stress-test run
    # had its own in-progress log file deleted out from under it after
    # switch #1's commit. Excluding engine-owned paths by name is the
    # minimal, correct fix (no new process/sync logic invented).
    #
    # CR-01 (same bug class, third occurrence): last-wallpaper/ is a
    # second engine-owned subdirectory (D-11 per-theme last-wallpaper
    # memory, written by lib/wallpaper.sh and wallpaper-picker.sh) that is
    # never part of the rendered tree — without the exclude, --delete
    # wiped every recorded pick on each theme switch, silently defeating
    # the feature end-to-end.
    #
    # WR-02: current-theme and .last-render-error.log are engine-owned
    # ROOT-LEVEL files that are also not part of the rendered tree — a
    # bare --delete removed current-theme mid-sync (recreated only below),
    # so a concurrent reader (theme-init.sh, the picker) could observe a
    # state dir with rendered files but no current-theme, and a crash
    # between the rsync and the rewrite lost it permanently. Excluding
    # both keeps the old value visible until the atomic replace below.
    #
    # D-19/UTIL-04 (06-07): icon-theme is a third engine-owned root-level
    # state file, same bug class (WR-02/CR-01) — it holds the theme-
    # orthogonal icon-theme-picker pick, is never part of the rendered
    # tree, and must survive every switch's --delete or the picker's
    # persistence would be silently wiped on the very next theme-apply.
    #
    # D-19/UTIL-05 (06-08): font-choice is a fourth engine-owned root-level
    # state file, same bug class again — holds the theme-orthogonal
    # font-switcher pick. kitty-font.conf/waybar-font.css ARE part of the
    # rendered tree (lib/font.sh writes them every run) and are therefore
    # NOT excluded — only the root-level state file itself is.
    #
    # WR-06 (06-18, sixth occurrence of this bug class): walker-relaunch.log
    # is a fifth engine-owned root-level state file, written by reload.sh's
    # walker-relaunch path (theme_engine_reload_walker) and never part of
    # the rendered tree matugen produces. Without the exclusion, every theme
    # commit destroys the previous run's walker diagnostics — including when
    # the new run never reaches the walker step (a render/commit crash or a
    # headless-guard early return), leaving the failure notification
    # pointing the user at a log a later switch already wiped.
    #
    # 08-12 (seventh occurrence of this bug class, found live while
    # verifying this plan's own checkpoint screenshots): waybar-visibility.css
    # is a sixth engine-owned root-level state file — historically written
    # by the visibility owner in response to idle/fullscreen/gaming events
    # (and seeded empty once by stow.sh) — never part of the rendered
    # tree. As of Phase 18 Plan 15/QBAR-07 the owner (renamed
    # bar-visibility.sh) no longer writes this file at all — it actuates
    # the QML bar over Quickshell IPC instead — so stow.sh's seed is now
    # this file's ONLY writer, and it stays a permanent empty stub. It is
    # still imported LAST by every style-*.css (08-11/08-12 design_system)
    # and this exclusion still matters for exactly the reason it always
    # did: every theme-apply deleted it, the next waybar reload hit an
    # unresolvable @import, GTK3 discarded the ENTIRE stylesheet, and waybar
    # exited outright (reproduced live: "Hyprland IPC stopping..." in
    # waybar's own log immediately after the failed import) — the exact
    # WLOG-01 failure class this whole gap-closure plan exists to prevent.
    # Retained until RETIRE-02 (18-20) deletes waybar, this file, its
    # contract entry and the stow.sh seed together.
    #
    # TOKEN-03/D-29 (12-03, eighth occurrence — where the MECHANISM changes,
    # not just the count): motion-scale is a seventh engine-owned root-level
    # state file, holding the motion-scale-picker's pick (written by a
    # future motion-switch.sh, read by lib/motion.sh) and never part of the
    # rendered tree. Eight hand-added --exclude flags that must each be
    # individually remembered on every future engine-owned file IS the bug
    # class, not any one miss — this rsync call and theme-doctor's new
    # state-manifest gate below now both read contract.json's
    # engine_owned_files array instead, so adding a ninth file fixes both
    # consumers at once and they cannot drift, the same reason contract.json
    # already works for the matugen-rendered targets (D-30).
    local engine_owned
    engine_owned="$(contract_engine_owned_files)"
    if [[ -z "$engine_owned" ]]; then
        # An unreadable/empty array (jq missing, contract.json broken) must
        # never fall through to a bare `rsync --delete` with zero
        # exclusions — that IS the data-loss event this whole comment block
        # documents. Abort the commit; the previous state dir is left
        # completely untouched, which is the safe direction.
        echo "commit.sh: engine_owned_files is empty or unreadable (jq missing or contract.json broken) — aborting commit rather than rsync --delete with no exclusions" >&2
        return 1
    fi

    local -a exclude_flags=()
    while IFS= read -r entry; do
        [[ -z "$entry" ]] && continue
        # A trailing-slash-less --exclude matches BOTH a file and a
        # directory of that name (verified empirically) — the historical
        # trailing slash on logs/ and last-wallpaper/ was documentation,
        # never load-bearing, so the array can hold bare names uniformly.
        exclude_flags+=(--exclude="$entry")
    done <<< "$engine_owned"

    rsync -a --delete "${exclude_flags[@]}" "$rendered_dir"/ "$STATE_DIR"/

    # rsync -a syncs the destination directory's own mode from the source
    # (matugen creates $rendered_dir with the process umask, typically
    # 0755) — re-assert user-only permissions AFTER rsync so it isn't
    # silently overwritten (T-02-03: never leave the state dir world-
    # readable/writable).
    chmod 700 "$STATE_DIR"

    # WR-02: temp-file + mv gives per-file atomicity — readers see either
    # the old theme name or the new one, never a truncated/absent file.
    printf '%s\n' "$name" > "$STATE_DIR/current-theme.tmp" \
        && mv "$STATE_DIR/current-theme.tmp" "$STATE_DIR/current-theme"

    # D-07: walker and yazi have no @import/include mechanism, so the
    # engine wires their config path directly to the state-dir output via
    # a symlink. This is idempotent one-time wiring (D-09) — `ln -sf`
    # re-links to the same target on every call, no per-login dance.
    local walker_dir="$HOME/.config/walker/themes/rice"
    mkdir -p "$walker_dir"
    ln -sf "$STATE_DIR/walker-style.css" "$walker_dir/style.css"

    mkdir -p "$HOME/.config/yazi"
    ln -sf "$STATE_DIR/yazi.toml" "$HOME/.config/yazi/theme.toml"

    # SHOT-02/D-30: satty has no @import/include mechanism either — wire its
    # config path directly to the rendered satty.toml via the same idempotent
    # `ln -sf` idiom as walker/yazi above. Guard: if ~/.config/satty is
    # itself a folded stow symlink (pre-migration state), skip and warn
    # instead of writing through the fold into the repo tree (same posture
    # as the gtk-3.0/gtk-4.0 guards below).
    if [[ -L "$HOME/.config/satty" ]]; then
        echo "commit.sh: ~/.config/satty is a folded stow symlink — skipping satty.toml wiring (re-run stow.sh to unfold it)" >&2
    else
        mkdir -p "$HOME/.config/satty"
        ln -sf "$STATE_DIR/satty.toml" "$HOME/.config/satty/config.toml"
    fi

    # THM-01/D-08: settings.ini is now a rendered contract target — wire the
    # same idempotent symlink idiom as walker/yazi above. Guard: if the gtk
    # config dir is itself a symlink (stow dir-folded into the repo — the
    # pre-migration state), skip wiring and warn instead of writing through
    # the fold into the repo tree (would break the git-clean invariant).
    # stow.sh's mkdir pre-create (Task 3) unfolds these dirs; this guard
    # keeps commit.sh safe regardless of ordering.
    if [[ -L "$HOME/.config/gtk-3.0" ]]; then
        echo "commit.sh: ~/.config/gtk-3.0 is a folded stow symlink — skipping settings.ini wiring (re-run stow.sh to unfold it)" >&2
    else
        mkdir -p "$HOME/.config/gtk-3.0"
        ln -sf "$STATE_DIR/gtk-3.0-settings.ini" "$HOME/.config/gtk-3.0/settings.ini"
    fi

    if [[ -L "$HOME/.config/gtk-4.0" ]]; then
        echo "commit.sh: ~/.config/gtk-4.0 is a folded stow symlink — skipping settings.ini wiring (re-run stow.sh to unfold it)" >&2
    else
        mkdir -p "$HOME/.config/gtk-4.0"
        ln -sf "$STATE_DIR/gtk-4.0-settings.ini" "$HOME/.config/gtk-4.0/settings.ini"
    fi
}
