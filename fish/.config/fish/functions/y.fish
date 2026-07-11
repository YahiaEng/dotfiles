# Parity port of zshell/.zshrc's y() — yazi with cwd-follow on exit.
# Shape follows the official yazi fish wrapper (yazi-rs docs).
function y --description "yazi with cwd-follow on exit"
    set -l tmp (mktemp -t "yazi-cwd.XXXXXX")
    yazi $argv --cwd-file="$tmp"
    if read -z cwd <"$tmp"; and test -n "$cwd"; and test "$cwd" != "$PWD"
        builtin cd -- "$cwd"
    end
    rm -f -- "$tmp"
end
