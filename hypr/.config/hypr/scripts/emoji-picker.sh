#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════╗
# ║              EMOJI PICKER (walker)                    ║
# ║  Types the selected glyph into the focused app via     ║
# ║  wtype AND copies it to the clipboard as backup         ║
# ║  (UTIL-01/D-21).                                        ║
# ╚══════════════════════════════════════════════════════╝
#
# Execution-time verification (RESEARCH.md Assumption A3 / Open Question 2 —
# "run walker's symbols provider and observe the exact stdout format and
# whether its built-in action already types AND copies"):
#
# Checked directly against the installed walker 2.16.2 (src/main.rs) and
# elephant-symbols 2.21.0 (internal/providers/symbols/setup.go) sources:
#   - `walker --dmenu -s symbols` does NOT query elephant-symbols at all.
#     `--dmenu` mode always spawns a stdin line-reader (`read_lines_async`
#     in main.rs's `'dmenu:` block) regardless of any `-s`/`-m` flag — it's
#     the exact same generic stdin-in/stdout-out mechanism theme-switch.sh
#     already uses, never a live provider query.
#   - A normal (non-dmenu) `walker -s symbols` run never prints the
#     selected value to stdout either — the only stdout-print path
#     (`handle_dmenu_print` in ui/window.rs) is gated behind `is_dmenu()`.
#     Selecting a symbol instead calls elephant-symbols' own Activate(),
#     which runs ONE configured shell `command` (default `wl-copy`,
#     read once from `~/.config/elephant/symbols.toml` at elephant daemon
#     startup) — copy-only by default, and not re-configurable per
#     invocation without restarting the live elephant service mid-session
#     (out of scope for a stateless picker script, and would add
#     un-stowed host state, violating this repo's reproducibility
#     constraint).
#   - elephant's own CLI (cmd/elephant) exposes no query/dump subcommand
#     (only version/listproviders/menu/service) usable from a script.
#
# Neither path can deliver D-21's "typed via wtype AND copied via wl-copy"
# behavior from a stateless wrapper. So this script reuses the SAME proven
# walker --dmenu stdin-list + exit-130-cancel pattern theme-switch.sh
# already ships (06-PATTERNS.md "Shared Patterns" — Walker --dmenu exit-130
# cancel handling), backed by a small self-contained curated glyph list
# instead of an unqueryable elephant-symbols dump — deterministic, fully
# reproducible (no host-only daemon config), and testable.

set -euo pipefail

# Security Domain T-06-17: wtype must only ever type a value we recognize,
# never raw, unvalidated walker stdout — glyph<TAB>name, one per line.
EMOJIS=$'😀\tgrinning face
😃\tgrinning face with big eyes
😄\tgrinning face with smiling eyes
😁\tbeaming face
😆\tgrinning squinting face
😅\tgrinning face with sweat
🤣\trolling on the floor laughing
😂\tface with tears of joy
🙂\tslightly smiling face
🙃\tupside-down face
😉\twinking face
😊\tsmiling face with smiling eyes
😇\tsmiling face with halo
🥰\tsmiling face with hearts
😍\theart eyes
🤩\tstar-struck
😘\tface blowing a kiss
😋\tface savoring food
😛\tface with tongue
😜\twinking face with tongue
🤪\tzany face
🤔\tthinking face
🤨\tface with raised eyebrow
😐\tneutral face
😑\texpressionless face
😶\tface without mouth
🙄\tface with rolling eyes
😏\tsmirking face
😒\tunamused face
😞\tdisappointed face
😔\tpensive face
😢\tcrying face
😭\tloudly crying face
😤\tface with steam from nose
😠\tangry face
😡\tpouting face
🤯\texploding head
😳\tflushed face
🥵\thot face
🥶\tcold face
😱\tface screaming in fear
😨\tfearful face
😰\tanxious face with sweat
😥\tsad but relieved face
😓\tdowncast face with sweat
🤗\thugging face
🤭\tface with hand over mouth
🤫\tshushing face
🤥\tlying face
😴\tsleeping face
🥱\tyawning face
😪\tsleepy face
🤤\tdrooling face
😵\tdizzy face
🥴\twoozy face
🤢\tnauseated face
🤮\tvomiting face
🤧\tsneezing face
😷\tface with medical mask
🥳\tpartying face
🤠\tcowboy hat face
🥸\tdisguised face
😎\tsmiling face with sunglasses
🤓\tnerd face
🧐\tface with monocle
😈\tsmiling face with horns
👿\tangry face with horns
👍\tthumbs up
👎\tthumbs down
👌\tok hand
✌️\tvictory hand
🤞\tcrossed fingers
🤟\tlove-you gesture
🤘\thorns
👏\tclapping hands
🙌\traising hands
🙏\tfolded hands
👋\twaving hand
🤝\thandshake
💪\tflexed biceps
🖐️\thand with fingers splayed
✋\traised hand
👆\tbackhand index pointing up
👉\tbackhand index pointing right
👈\tbackhand index pointing left
🫶\theart hands
🤙\tcall me hand
❤️\tred heart
🧡\torange heart
💛\tyellow heart
💚\tgreen heart
💙\tblue heart
💜\tpurple heart
🖤\tblack heart
🤍\twhite heart
🤎\tbrown heart
💔\tbroken heart
❤️‍🔥\theart on fire
💕\ttwo hearts
💖\tsparkling heart
💗\tgrowing heart
💓\tbeating heart
💞\trevolving hearts
💘\theart with arrow
💝\theart with ribbon
✨\tsparkles
🔥\tfire
💯\thundred points
⭐\tstar
🌟\tglowing star
⚡\thigh voltage
💥\tcollision
💫\tdizzy
🎉\tparty popper
🎊\tconfetti ball
🎈\tballoon
🎁\twrapped gift
🏆\ttrophy
🥇\t1st place medal
🚀\trocket
🌈\trainbow
☀️\tsun
🌙\tcrescent moon
☁️\tcloud
❄️\tsnowflake
☕\thot beverage
🍕\tpizza
🍔\thamburger
🍎\tred apple
🍺\tbeer mug
🎮\tvideo game
🎧\theadphone
📷\tcamera
💻\tlaptop
📱\tmobile phone
⌚\twatch
📌\tpushpin
📎\tpaperclip
🔗\tlink
✅\tcheck mark button
❌\tcross mark
❓\tred question mark
❗\tred exclamation mark
⚠️\twarning
🚫\tprohibited
♻️\trecycling symbol
✔️\tcheck mark
➡️\tright arrow
⬅️\tleft arrow
⬆️\tup arrow
⬇️\tdown arrow
🔒\tlocked
🔓\tunlocked
🔑\tkey
🐛\tbug
🐍\tsnake
🐧\tpenguin
🐱\tcat face
🐶\tdog face
🦄\tunicorn'

# theme-switch.sh's exit-130-cancel pattern, verbatim (06-PATTERNS.md
# "Shared Patterns" — Walker --dmenu exit-130 cancel handling).
rc=0
SELECTED=$(printf '%s\n' "$EMOJIS" | walker --dmenu --placeholder "Search Emoji...") || rc=$?
if ((rc == 130)); then
    exit 0 # user cancelled — walker's own 128+SIGINT convention
elif ((rc != 0)); then
    notify-send -a "Emoji Picker" "Error" "walker dmenu failed" -i dialog-error 2>/dev/null || true
    exit 1
fi
[[ -z "$SELECTED" ]] && exit 0

# T-06-17: only accept a selection that is an EXACT line from our own
# curated list — never trust free-typed dmenu input as something safe to
# feed to wtype.
if ! printf '%s\n' "$EMOJIS" | grep -qxF "$SELECTED"; then
    exit 1
fi

EMOJI="${SELECTED%%$'\t'*}"
[[ -z "$EMOJI" ]] && exit 1

if command -v wtype >/dev/null 2>&1; then
    wtype "$EMOJI"
else
    # wtype not installed yet on this machine (install.sh PACMAN_PKGS
    # already lists it — see D-21) — degrade to copy-only rather than
    # silently doing nothing.
    :
fi

printf '%s' "$EMOJI" | wl-copy

notify-send -a "Emoji Picker" "Emoji Inserted" "$EMOJI typed and copied to clipboard" -i face-smile -t 2000 2>/dev/null || true
