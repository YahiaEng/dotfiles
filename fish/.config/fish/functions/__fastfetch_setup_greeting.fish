function __fastfetch_setup_greeting
    if not isatty stdout; or not command -q fastfetch; or not command -q python3
        return
    end

    set -l logo arch
    set -l logo_file "$HOME/.local/state/theme/fastfetch-logo"
    if test -r "$logo_file"
        set logo (string trim < "$logo_file")
    end
    if set -q KITTY_WINDOW_ID; and command -q kitten
        and string match -rq '^(random|pulse|sweep|glitch|scan|assemble|orbit)$' -- "$logo"
        # Graphics are sent directly to the terminal, outside Fish's editable prompt.
        function fish_greeting
            fastfetch
        end
        return
    end
    if test "$logo" = random
        set logo (random choice arch star cyberpunk_mask illuminati)
    end
    set -g __fastfetch_greeting_logo "$logo"
    functions -q fish_prompt
    functions -c fish_prompt __fastfetch_original_prompt
    if set -q -g fish_transient_prompt
        set -g __fastfetch_saved_transient "$fish_transient_prompt"
    end
    set -g fish_transient_prompt 1

    function fish_prompt
        set -l prompt (__fastfetch_original_prompt $argv | string collect)
        # Keep the opening screen out of scrollback so Kitty cannot rewrap it.
        if contains -- --final-rendering $argv
            printf '%s' "$prompt"
            return
        end
        set -l size "$COLUMNS/$LINES"
        if not set -q __fastfetch_greeting_size; or test "$__fastfetch_greeting_size" != "$size"
            set -g __fastfetch_greeting_size "$size"
            set -g __fastfetch_greeting_text (
                command python3 (path dirname "$__fish_config_dir")/fastfetch/render.py \
                    --prompt --columns "$COLUMNS" --lines "$LINES" --logo "$__fastfetch_greeting_logo" | string collect
            )
        end
        if test -n "$__fastfetch_greeting_text"
            printf '%s\n' "$__fastfetch_greeting_text"
        end
        printf '%s' "$prompt"
    end

    function __fastfetch_end_greeting --on-event fish_preexec
        functions -e fish_prompt
        functions -c __fastfetch_original_prompt fish_prompt
        functions -e __fastfetch_original_prompt __fastfetch_end_greeting
        set -e __fastfetch_greeting_size __fastfetch_greeting_text __fastfetch_greeting_logo
        if set -q __fastfetch_saved_transient
            set -g fish_transient_prompt "$__fastfetch_saved_transient"
            set -e __fastfetch_saved_transient
        else
            set -e -g fish_transient_prompt
        end
    end
end
