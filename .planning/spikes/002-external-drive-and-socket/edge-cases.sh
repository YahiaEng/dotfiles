#!/usr/bin/env bash
# Two things reload.sh will actually meet in the wild:
#   1. several nvim instances open at once -- all must be reached
#   2. a socket left behind by a crashed nvim -- must not hang the theme switch
set -uo pipefail
RUNTIME="${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"
SPIKE001="$(cd "$(dirname "${BASH_SOURCE[0]}")/../001-highlight-repaint-completeness" && pwd)"
OUT="$(dirname "${BASH_SOURCE[0]}")/results-edge.txt"; : > "$OUT"
say() { echo "$*" | tee -a "$OUT"; }

before=$(find "$RUNTIME" -maxdepth 1 -name 'nvim.*' 2>/dev/null | sort)

say "== 1. three instances at once =="
for i in 1 2 3; do
  setsid nohup nvim --headless --cmd "set runtimepath^=$SPIKE001" >/dev/null 2>&1 </dev/null &
done
sleep 3
after=$(find "$RUNTIME" -maxdepth 1 -name 'nvim.*' 2>/dev/null | sort)
mapfile -t SOCKS < <(comm -13 <(echo "$before") <(echo "$after"))
say "  sockets discovered: ${#SOCKS[@]}"
for s in "${SOCKS[@]}"; do say "    $s"; done

cat > "$SPIKE001/palette.lua" <<'PAL'
return { fg = "#123456", bg = "#000000", dim = "#444444", accent = "#abcdef" }
PAL
reached=0
for s in "${SOCKS[@]}"; do
  nvim --server "$s" --remote-expr "execute('colorscheme spikelive')" >/dev/null 2>&1
  got=$(nvim --server "$s" --remote-expr "luaeval(\"string.format('#%06x', vim.api.nvim_get_hl(0,{name='Normal',link=false}).fg or 0)\")" 2>&1)
  say "    $s -> Normal=$got"
  [ "$got" = "#123456" ] && reached=$((reached+1))
done
say "  instances successfully re-themed: $reached / ${#SOCKS[@]}"

say ""
say "== 2. stale socket from a hard-killed nvim =="
VICTIM="${SOCKS[0]}"
PID=$(basename "$VICTIM" | sed 's/^nvim\.\([0-9]*\)\..*/\1/')
say "  SIGKILLing pid $PID (socket $VICTIM)"
kill -9 "$PID" 2>/dev/null
sleep 1
if [ -S "$VICTIM" ]; then
  say "  socket LINGERS after SIGKILL -- reload.sh will meet dead sockets"
else
  say "  socket removed by the kernel on SIGKILL"
fi

say "  connecting to it, timing the failure..."
START=$(date +%s%N)
timeout 15 nvim --server "$VICTIM" --remote-expr "1+1" >/dev/null 2>&1
RC=$?
END=$(date +%s%N)
MS=$(( (END - START) / 1000000 ))
say "  exit=$RC after ${MS}ms  $([ $RC -eq 124 ] && echo '<-- TIMED OUT (would hang reload.sh)' || echo '<-- failed fast, safe')"

# clean up whatever is still alive
for s in "${SOCKS[@]}"; do
  nvim --server "$s" --remote-expr "execute('qa!')" >/dev/null 2>&1 || true
done
say "  cleaned up"
