#!/usr/bin/env bash
# Positive control for the remote read path, before trusting any negative result.
set -uo pipefail
RUNTIME="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
SPIKE001="$(cd "$(dirname "${BASH_SOURCE[0]}")/../001-highlight-repaint-completeness" && pwd)"

# find, not ls -- ls is aliased in the interactive shell and corrupts the path.
before=$(find "$RUNTIME" -maxdepth 1 -name 'nvim.*' 2>/dev/null | sort)
setsid nohup nvim --headless --cmd "set runtimepath^=$SPIKE001" >/dev/null 2>&1 </dev/null &
sleep 2
after=$(find "$RUNTIME" -maxdepth 1 -name 'nvim.*' 2>/dev/null | sort)
SOCK=$(comm -13 <(echo "$before") <(echo "$after") | head -1)
echo "sock=[$SOCK]"

peek() { nvim --server "$SOCK" --remote-expr "$1" 2>&1; }

echo "--- POSITIVE CONTROL ---"
echo "  1+1         -> [$(peek '1+1')]"
echo "  v:servername-> [$(peek 'v:servername')]"
echo "--- environment inside the running instance ---"
echo "  termguicolors -> [$(peek '&termguicolors')]"
echo "  ui count      -> [$(peek 'len(nvim_list_uis())')]"
echo "--- apply scheme, read back three ways ---"
peek "execute('colorscheme spikelive')" >/dev/null
echo "  g:colors_name -> [$(peek "get(g:,'colors_name','NONE')")]"
echo "  lua nvim_get_hl -> [$(peek "luaeval(\"string.format('#%06x', vim.api.nvim_get_hl(0,{name='Normal',link=false}).fg or 0)\")")]"
echo "  synIDattr fg# -> [$(peek "synIDattr(synIDtrans(hlID('Normal')),'fg#')")]"

nvim --server "$SOCK" --remote-expr "execute('qa!')" >/dev/null 2>&1
