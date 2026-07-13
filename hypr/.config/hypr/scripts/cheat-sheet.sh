#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║        CHEAT-SHEET — walker searchable list           ║
# ║  D-29a: one of two surfaces sharing                    ║
# ║  cheat-sheet-parser.sh (D-29) — no second grep/awk      ║
# ║  extraction here. This is a REFERENCE, not a launcher: ║
# ║  selecting a keybind row never executes its dispatcher ║
# ║  (T-07-26). Live-parsed on every open, never cached     ║
# ║  (D-31).                                                ║
# ╚══════════════════════════════════════════════════════╝

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
# shellcheck source=/dev/null
source "$SCRIPT_DIR/cheat-sheet-parser.sh"

VIEW_ALL_LABEL="View all keybinds ›"

ROWS=()
CHORDS=()
while IFS=$'\t' read -r _section chord desc; do
    # Row format locked by UI-SPEC: "{Chord} — {Description}", description
    # text reused VERBATIM from keybinds.conf (never paraphrased) — the
    # exact discipline that keeps this surface incapable of diverging from
    # the kitty "View all" table (D-29).
    ROWS+=("${chord} — ${desc}")
    CHORDS+=("$chord")
done < <(cheat_sheet_parse_binds)

# D-29's bridge to the second surface.
ROWS+=("$VIEW_ALL_LABEL")

# Phase 5's 05-05 cancel-toast regression: walker 2.16.2's real cancel
# signal is exit 130 with no stdout — trusted as the sole cancel signal
# (never 0+empty). `|| rc=$?` captures it without tripping
# `set -euo pipefail` on a bare command-substitution assignment.
rc=0
SELECTED=$(printf '%s\n' "${ROWS[@]}" | walker --dmenu --placeholder "Search keybinds...") || rc=$?
if (( rc == 130 )); then
    exit 0   # user cancel — walker's own 128+SIGINT convention
elif (( rc != 0 )); then
    notify-send -a "Keybinds" "Error" "walker dmenu failed" -i dialog-error 2>/dev/null || true
    exit 1   # hard failure: not installed, elephant dead, crash
fi
[[ -z "$SELECTED" ]] && exit 0   # defensive; walker never returns 0+empty

if [[ "$SELECTED" == "$VIEW_ALL_LABEL" ]]; then
    exec "$SCRIPT_DIR/cheat-sheet-view-all.sh"
fi

# T-07-26: this is a lookup, not an invocation. Selecting an ordinary
# keybind row NEVER executes that bind's own dispatcher — it only copies
# the chord to the clipboard for reference, then exits.
for i in "${!ROWS[@]}"; do
    if [[ "${ROWS[$i]}" == "$SELECTED" ]]; then
        printf '%s' "${CHORDS[$i]}" | wl-copy 2>/dev/null || true
        break
    fi
done

exit 0
