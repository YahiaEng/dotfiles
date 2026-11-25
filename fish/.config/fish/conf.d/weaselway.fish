# Fish does not read the Weaselway installer's /etc/profile.d script.
if set -q WSL_INTEROP; and test -x /opt/weaselway/viewer/sdl-freerdp.exe
    set -q WEASELWAY_VIEWER; or set -gx WEASELWAY_VIEWER /opt/weaselway/viewer/sdl-freerdp.exe
    set -q WEASELWAY_DEFAULT_SESSION; or set -gx WEASELWAY_DEFAULT_SESSION custom
    if test "$PULSE_SERVER" = unix:/mnt/wslg/PulseServer
        set -e PULSE_SERVER
    end

    # Only a local WSL terminal starts the desktop. Kitty, remote shells,
    # and automated commands keep their normal startup behavior.
    if status is-interactive; and test -t 0
        if not set -q HYPRLAND_INSTANCE_SIGNATURE; and not set -q KITTY_WINDOW_ID; and not set -q SSH_CONNECTION; and not set -q ARCH_WSL_TERMINAL
            command "$HOME/dotfiles/wsl/launch-desktop"
        end
    end
end
