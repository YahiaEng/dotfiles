function fastfetch --wraps fastfetch --description "Show the themed system overview"
    if set -q argv[1]; or not isatty stdout
        command fastfetch $argv
        return
    end

    command python3 (path dirname "$__fish_config_dir")/fastfetch/render.py --columns "$COLUMNS" --lines "$LINES"
end
