#!/usr/bin/env bash
# Generates Walker's style.css with hardcoded hex colors
# Usage: walker-theme-gen.sh --from-css <path/to/colors.css>

WALKER_DIR="$HOME/.config/walker/themes/rice"
WALKER_STYLE="$WALKER_DIR/style.css"

[[ -L "$WALKER_DIR" ]] && rm -f "$WALKER_DIR"
mkdir -p "$WALKER_DIR"
[[ -L "$WALKER_STYLE" ]] && rm -f "$WALKER_STYLE"
rm -rf "$HOME/.local/share/walker/themes/rice" 2>/dev/null

if [[ "$1" == "--from-css" && -f "$2" ]]; then
    get_color() { grep "@define-color $1 " "$2" | sed "s/.*@define-color $1 //;s/;//" | tr -d ' '; }
    BG=$(get_color "background" "$2")
    FG=$(get_color "on_surface" "$2")
    PRIMARY=$(get_color "primary" "$2")
    ON_PRIMARY=$(get_color "on_primary" "$2")
    SECONDARY=$(get_color "secondary" "$2")
    SURFACE_VAR=$(get_color "surface_variant" "$2")
    PRIMARY_CONT=$(get_color "primary_container" "$2")
    ON_PRIMARY_CONT=$(get_color "on_primary_container" "$2")
    OUTLINE=$(get_color "outline" "$2")
else
    BG="#1e1e2e"; FG="#cdd6f4"; PRIMARY="#cba6f7"; ON_PRIMARY="#1e1e2e"
    SECONDARY="#89b4fa"; SURFACE_VAR="#313244"; PRIMARY_CONT="#45475a"
    ON_PRIMARY_CONT="#cdd6f4"; OUTLINE="#585b70"
fi

cat > "$WALKER_STYLE" << CSS
/* Auto-generated — do not edit. Regenerated on theme switch. */

window {
    background-color: transparent;
    color: ${FG};
}

#box {
    background-color: ${BG};
    border: 3px solid ${PRIMARY};
    border-radius: 16px;
    padding: 10px;
}

#search {
    background-color: ${SURFACE_VAR};
    color: ${FG};
    border: 2px solid ${PRIMARY};
    border-radius: 12px;
    padding: 10px 16px;
    margin-bottom: 8px;
    font-size: 15px;
    font-family: "FiraCode Nerd Font";
    caret-color: ${PRIMARY};
}

#search:focus {
    border-color: ${SECONDARY};
    background-color: ${PRIMARY_CONT};
    color: ${ON_PRIMARY_CONT};
}

row {
    padding: 8px 14px;
    margin: 2px 4px;
    border-radius: 10px;
    border: 2px solid transparent;
    color: ${FG};
    background-color: transparent;
}

row:selected {
    background-color: ${PRIMARY};
    color: ${ON_PRIMARY};
    border-color: ${SECONDARY};
    font-weight: bold;
}

row:hover:not(:selected) {
    background-color: ${PRIMARY_CONT};
    border-color: ${PRIMARY};
    color: ${ON_PRIMARY_CONT};
}

row label {
    color: inherit;
}

row image {
    margin-right: 8px;
}

scrollbar slider {
    background-color: ${OUTLINE};
    border-radius: 8px;
    min-width: 6px;
}

scrollbar slider:hover {
    background-color: ${PRIMARY};
}
CSS
echo "Done"
    