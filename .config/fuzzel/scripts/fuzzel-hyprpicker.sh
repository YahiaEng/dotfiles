#!/bin/bash
# A tool to pick colors from the screen using hyprpicker - fuzzel - wl-clipboard - fyi

set +u  # Disable nounset
APP_NAME="fuzzel-hyprpicker"
NOTIFY="fyi --app-name=$APP_NAME --icon=org.gnome.design.Palette"

# Set up the storage directory and file
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/fuzzel/$APP_NAME"
HISTORY_FILE="$CONFIG_DIR/colors.txt"
HISTORY_NUM=10
ICONS_DIR="$CONFIG_DIR/icons"

# Create directories and history if they don't exist
mkdir -p "$ICONS_DIR"
touch "$HISTORY_FILE"

function create_eye_dropper_svg() {
  local color="#C8D1EE"
  local icon_path="$ICONS_DIR/eyedropper.svg"

  # Create an SVG for the eyedropper icon if it doesn't exist
  if [ ! -f "$icon_path" ]; then
    cat > "$icon_path" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<svg fill="$color" width="800px" height="800px" viewBox="0 0 16 16" xmlns="http://www.w3.org/2000/svg">
  <path d="M13.354.646a1.207 1.207 0 0 0-1.708 0L8.5 3.793l-.646-.647a.5.5 0 1 0-.708.708L8.293 5l-7.147 7.146A.5.5 0 0 0 1 12.5v1.793l-.854.853a.5.5 0 1 0 .708.707L1.707 15H3.5a.5.5 0 0 0 .354-.146L11 7.707l1.146 1.147a.5.5 0 0 0 .708-.708l-.647-.646 3.147-3.146a1.207 1.207 0 0 0 0-1.708zM2 12.707l7-7L10.293 7l-7 7H2z"/>
</svg>
EOF
  fi
}


function create_trash_svg() {
  local color="#C8D1EE"
  local icon_path="$ICONS_DIR/trash.svg"

  # Create an SVG for the trash icon if it doesn't exist
  if [ ! -f "$icon_path" ]; then
    cat > "$icon_path" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<svg fill="$color" width="800px" height="800px" viewBox="0 0 256 256" id="Flat" xmlns="http://www.w3.org/2000/svg">
  <path d="M215.99609,48H176V40a24.02718,24.02718,0,0,0-24-24H104A24.02718,24.02718,0,0,0,80,40v8H39.99609a8,8,0,0,0,0,16h8V208a16.01833,16.01833,0,0,0,16,16h128a16.01833,16.01833,0,0,0,16-16V64h8a8,8,0,0,0,0-16ZM112,168a8,8,0,0,1-16,0V104a8,8,0,0,1,16,0Zm48,0a8,8,0,0,1-16,0V104a8,8,0,0,1,16,0Zm0-120H96V40a8.00917,8.00917,0,0,1,8-8h48a8.00917,8.00917,0,0,1,8,8Z"/>
</svg>
EOF
  fi
}

# Function to add a color to history
function add_color_to_history() {
  local color="$1"

  # Don't add duplicates
  if ! grep -q "^$color$" "$HISTORY_FILE"; then
    # Add to beginning of file
    echo "$color" > "$HISTORY_FILE.new"
    cat "$HISTORY_FILE" >> "$HISTORY_FILE.new"
    # Limit history to HISTORY_NUM entries
    head -n $HISTORY_NUM "$HISTORY_FILE.new" > "$HISTORY_FILE" && rm "$HISTORY_FILE.new"  
  fi
  HISTORY_LEN=$(wc -l < "$HISTORY_FILE")
}

# Function to generate color square .svg icon
function generate_svg_icon() {
  local color="$1"
  local icon_path="$ICONS_DIR/$color.svg"

  # Create an SVG for the color if it doesn't exist
  if [ ! -f "$icon_path" ]; then
    cat > "$icon_path" <<EOF
<svg width="128" height="128" xmlns="http://www.w3.org/2000/svg">
  <rect width="128" height="128" fill="#$color" />
</svg>
EOF
  fi
}

# Function to pick a color from screen
function pick_color() {
  sleep 0.5
  color=$(hyprpicker --format=hex --no-fancy --autocopy | tail -n 1)
  if [ -n "$color" ]; then
    $NOTIFY "Color Picker" "Color <span color=\"$color\">󰝤 $color</span> copied to clipboard."
    # Remove leading # if present
    color="${color#\#}"
    generate_svg_icon "$color"
    add_color_to_history "$color"
  fi
}

# Build menu options
function build_menu() {
  echo -e "Pick a color\0icon\x1f$ICONS_DIR/eyedropper.svg"
  # Add history items if they exist
  if [ -s "$HISTORY_FILE" ]; then
    while read -r color; do
      # If the preview icon doesn't exist, generate it
      if [ ! -e "$ICONS_DIR/$color.svg" ]; then
        generate_svg_icon "$color"
      fi
      # Display the color with a preview
      echo -e "#$color\0icon\x1f$ICONS_DIR/$color.svg"
    done < "$HISTORY_FILE"
  fi
  if [ "$HISTORY_LEN" -gt 0 ]; then
    echo -e "Clear history\0icon\x1f$ICONS_DIR/trash.svg"
  fi
}

create_eye_dropper_svg
create_trash_svg
HISTORY_LEN=$(wc -l < "$HISTORY_FILE")
selection=$(build_menu | fuzzel --dmenu --prompt="󰏘 " --lines=$((HISTORY_LEN + 2)) --width=24)
[[ -z "$selection" ]] && exit 0

if [[ "$selection" == "Pick a color"* ]]; then
  pick_color
elif [[ "$selection" == "Clear history"* ]]; then
  rm -f "$HISTORY_FILE"
  rm -f "$ICONS_DIR"/*.svg
  create_eye_dropper_svg
  create_trash_svg
  $NOTIFY "Color Picker" "History cleared."
else
  echo "$selection" | wl-copy --trim-newline
  $NOTIFY "Color Picker" "Color <span color=\"$selection\">󰝤 $selection</span> copied to clipboard."
fi