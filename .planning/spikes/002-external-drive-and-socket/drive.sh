#!/usr/bin/env bash
# Can an outside process find a running nvim and make it re-theme?
# This is what reload.sh will have to do on every theme switch.
#
# Reuses the colorschemes proven in spike 001.
#
# Two probe traps this script exists to avoid:
#   - use `find`, not `ls` -- ls is aliased in interactive shells and the
#     alias corrupts the socket path.
#   - read colours with nvim_get_hl via luaeval, NOT synIDattr(...,'fg#') --
#     headless nvim has no UI, so termguicolors is off and 'fg#' is empty.
set -uo pipefail

SPIKE001="$(cd "$(dirname "${BASH_SOURCE[0]}")/../001-highlight-repaint-completeness" && pwd)"
RUNTIME="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
RESULT="$(dirname "${BASH_SOURCE[0]}")/results.txt"
: > "$RESULT"
say() { echo "$*" | tee -a "$RESULT"; }

before=$(find "$RUNTIME" -maxdepth 1 -name 'nvim.*' 2>/dev/null | sort)

say "== start a detached nvim on the DEFAULT socket (no --listen) =="
setsid nohup nvim --headless --cmd "set runtimepath^=$SPIKE001" >/dev/null 2>&1 </dev/null &
sleep 2

after=$(find "$RUNTIME" -maxdepth 1 -name 'nvim.*' 2>/dev/null | sort)
SOCK=$(comm -13 <(echo "$before") <(echo "$after") | head -1)
[ -z "$SOCK" ] && { say "FAIL: no new socket under $RUNTIME"; exit 1; }
say "  discovered: $SOCK"
say "  glob that finds every live instance: $RUNTIME/nvim.*"

peek() { nvim --server "$SOCK" --remote-expr "$1" 2>&1; }
hl()   { peek "luaeval(\"string.format('#%06x', vim.api.nvim_get_hl(0,{name='$1',link=false}).fg or 0)\")"; }

say ""
say "== probe calibration (must pass before any verdict below counts) =="
CTRL=$(peek '1+1')
say "  remote-expr 1+1 -> $CTRL   $([ "$CTRL" = "2" ] && echo OK || echo BLIND)"
[ "$CTRL" = "2" ] || { say "probe is blind, aborting"; exit 1; }

write_palette() { cat > "$SPIKE001/palette.lua" <<PAL
return { fg = "$1", bg = "$2", dim = "$3", accent = "$4" }
PAL
}

say ""
say "== palette v1, applied from outside via --remote-expr =="
write_palette '#aaaaaa' '#111111' '#555555' '#ff0000'
peek "execute('colorscheme spikelive')" >/dev/null
V1_N=$(hl Normal); V1_K=$(hl '@keyword'); V1_L=$(hl '@lsp.type.function')
say "  Normal=$V1_N  @keyword=$V1_K  @lsp.type.function=$V1_L"

say ""
say "== rewrite palette on disk, re-drive from outside via --remote-expr =="
write_palette '#dddddd' '#222222' '#999999' '#00ccff'
peek "execute('colorscheme spikelive')" >/dev/null
V2_N=$(hl Normal); V2_K=$(hl '@keyword'); V2_L=$(hl '@lsp.type.function')
say "  Normal=$V2_N  @keyword=$V2_K  @lsp.type.function=$V2_L"

say ""
say "== same again, but driven with --remote-send keystrokes =="
write_palette '#eeeeee' '#333333' '#bbbbbb' '#ffcc00'
nvim --server "$SOCK" --remote-send '<C-\><C-N>:colorscheme spikelive<CR>' >/dev/null 2>&1
sleep 1
V3_N=$(hl Normal); V3_K=$(hl '@keyword')
say "  Normal=$V3_N  @keyword=$V3_K"

say ""
say "== verdict =="
[ "$V1_N" != "$V2_N" ] && say "  remote-expr drove a change:  YES  ($V1_N -> $V2_N)" || say "  remote-expr drove a change:  NO"
[ "$V2_N" != "$V3_N" ] && say "  remote-send drove a change:  YES  ($V2_N -> $V3_N)" || say "  remote-send drove a change:  NO"
[ "$V1_L" != "$V2_L" ] && say "  @lsp.* followed externally:  YES  ($V1_L -> $V2_L)" || say "  @lsp.* followed externally:  NO"

nvim --server "$SOCK" --remote-expr "execute('qa!')" >/dev/null 2>&1
sleep 1
[ -S "$SOCK" ] && say "  socket lingers after quit" || say "  socket cleaned up on quit"
