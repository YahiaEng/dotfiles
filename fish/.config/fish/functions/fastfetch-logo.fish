# Command entrypoint for the fastfetch logo picker (quick task 260818-srl,
# Task 3). Same `y.fish` shape (a plain wrapper function). Runs the picker
# directly in the current terminal — no floating kitty launch here, unlike
# the SUPER+SHIFT+T keybind's fastfetch-logo-switch.sh, since a user typing
# this command is already sitting in one.
function fastfetch-logo --description "Pick the fastfetch greeting logo (6 sprites, 5 ASCII, random, none)"
    ~/.config/hypr/scripts/fastfetch-logo-picker.sh
end
