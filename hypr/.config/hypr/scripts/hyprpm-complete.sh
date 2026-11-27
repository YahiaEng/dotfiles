#!/usr/bin/env bash
# Run at compositor startup on both native Arch and Weaselway.
set -u
mode=${1:---login}
case "$mode" in
    --login|--install|--repair) ;;
    *) echo "Usage: ${0##*/} [--repair]" >&2; exit 2 ;;
esac

report() {
    printf 'Dynamic cursors: %s\n' "$1" >&2
    if [[ $mode != --install ]]; then
        notify-send "Dynamic cursors" "$1" 2>/dev/null || true
    fi
    [[ $mode == --login ]] && exit 0
    exit 1
}

if [[ ! -S ${XDG_RUNTIME_DIR:-}/hypr/${HYPRLAND_INSTANCE_SIGNATURE:-}/.socket.sock ]]; then
    [[ $mode == --login ]] && exit 0
    report "Setup needs a running Hyprland session."
fi

loaded() {
    hyprctl -j plugin list | jq -e 'any(.[]; .name == "dynamic-cursors")' >/dev/null
}

loaded && exit 0
state="/var/cache/hyprpm/$(id -un)"
repo="$state/dynamic-cursors"
if [[ $mode != --repair && -f $repo/state.toml ]] && grep -qx 'enabled = false' "$repo/state.toml"; then
    exit 0
fi

# After an upgrade the running compositor may still use the previous ABI.
# Its next startup runs this helper again with matching headers.
running=$(hyprctl -j version | jq -er '.abiHash') || report "Could not read the running Hyprland ABI."
installed=$(Hyprland --version-json | jq -er '.abiHash') || report "Could not read the installed Hyprland ABI."
[[ $running == "$installed" ]] || report "Hyprland was upgraded. Cursor setup will continue at the next Hyprland login."

# Avoid hyprpm's outdated-headers notification when a rebuild is expected.
if command -v hyprpm >/dev/null && [[ -f $repo/dynamic-cursors.so ]] &&
    grep -Fqx "hash = '$running'" "$state/state.toml" 2>/dev/null &&
    timeout 20 hyprpm reload && loaded; then
    hyprctl reload
    exit $?
fi

if [[ $mode == --login ]]; then
    # Only stale or missing builds need a terminal. Kitty gives hyprpm a
    # controlling TTY for sudo even when login was started by Weaselway.
    flock -n -E 0 -o "$XDG_RUNTIME_DIR/dynamic-cursors-login.lock" \
        kitty --title "Rebuilding dynamic cursors" -- "$0" --repair ||
        report "Automatic cursor setup did not finish. It will retry at the next login."
    exit 0
fi

exec 9>"$XDG_RUNTIME_DIR/dynamic-cursors-build.lock"
flock -n 9 || exit 0
loaded && exit 0

# install.sh can be unattended. hyprpm may drop its sudo timestamp after
# each write, so check credentials separately for each installer step.
build_step() {
    if [[ $mode == --install ]]; then
        sudo -n true && timeout 10m hyprpm "$@" </dev/null
    else
        hyprpm "$@"
    fi
}

if ! command -v hyprpm >/dev/null; then
    [[ $mode == --repair ]] || report "The hyprpm package is missing."
    echo "Installing Arch's Hyprland plugin manager for dynamic cursors."
    sudo pacman -S --needed hyprpm || report "Could not install hyprpm."
fi
echo "Rebuilding dynamic cursors for the installed Hyprland. hyprpm uses sudo for its build cache."
build_step update || report "hyprpm could not update the plugin. Setup will retry at the next login."
if [[ ! -f $repo/state.toml ]]; then
    url=https://github.com/virtcode/hypr-dynamic-cursors
    [[ $mode == --install ]] && url=${HYPRPM_PLUGIN_URL:-$url}
    build_step add "$url" || report "Could not register dynamic cursors."
fi
if ! loaded; then
    build_step enable dynamic-cursors || report "Could not enable dynamic cursors."
fi
loaded || report "Hyprland did not load dynamic cursors."
timeout 10 hyprctl reload || report "Hyprland could not reapply the cursor settings."
