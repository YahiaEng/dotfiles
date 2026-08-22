// MenuTree.qml — the 9 D-2 verb-based menu roots (quick task 260822-sht,
// Task 3), replacing the retired 6-TOML / 36-entry `elephant` `menus`
// provider with a QML data model. **All 36 existing entries are re-homed;
// none is dropped** — every non-clipboard `actions.open` string below was
// copied BYTE-IDENTICAL from `elephant/.config/elephant/menus/*.toml`
// (parsed programmatically, not hand-transcribed, specifically to rule out
// a transcription slip in a Nerd Font private-use-area glyph or an escaped
// quote) — see this task's own `<verify>` gate, which re-parses those same
// six TOMLs with `tomllib` and names any leaf command missing from this
// file byte-for-byte.
//
// ── Why `command` values are BACKTICK template literals, not double-quoted
//    strings ─────────────────────────────────────────────────────────────
// Several retired commands carry embedded double quotes (`Claude Code`'s
// `--title "Claude Code"`, `Power`'s `hl.dsp.global("quickshell:power-menu")`)
// or embedded single quotes (`Power`'s own `hyprctl dispatch '...'` wrapper).
// A double-quoted QML string literal would need `\"` to hold the former; a
// single-quoted one would need `\'` for the latter — either escaping
// mutates the file's raw byte sequence away from the TOML's own resolved
// string, which is exactly what this task's `<verify>` gate string-matches
// against (`a not in src`, a plain substring test on the file's raw text,
// not a re-parsed/re-escaped comparison). A backtick template literal has
// no other reason to need `\"` or `\'` here (none of these 30 commands
// contain a literal backtick or a `${` sequence — verified by scanning all
// 30 before writing this file), so it is the one QML string form that
// reproduces every retired command's exact bytes unmodified.
//
// ── Node schema ───────────────────────────────────────────────────────────
// A node is either a SUBMENU (`children: [...]`, no `command`) or a LEAF
// (`command`, no `children`). A leaf's `command` is `null` when the entry
// carries a `mode` instead: `MenuMode.qml`'s `activate()` switches
// `LauncherState.mode` to that string and does NOT dismiss the launcher,
// the same mechanism a typed route prefix uses (Task 2's router). Three
// leaves use this today — Apps' own child (`mode: "apps"`, R-3, Task 4),
// System's Updates/System info (`mode: "updates"`/`"systeminfo"`, R-1/R-2,
// Task 4) — plus Tools ▸ Clipboard, whose retired TOML action IS still
// recorded here verbatim for reversibility even though `mode: "clipboard"`
// means it is NEVER executed — the ONE entry Task 3's own plan text named
// as the deliberate exception to "byte-identical AND executed". Task 8
// (quick task 260822-sht) has now wired `mode: "clipboard"` to a real
// component (ClipboardMode.qml). No leaf carries `placeholder: true`
// any more — Tools ▸ Emoji (`mode: "symbols"`, Task 7, EmojiMode.qml)
// and Learn ▸ Keybinds (`mode: "keybinds"`, Task 9, KeybindsMode.qml)
// were the last two, both now wired to real components.
// Style ▸ Theme and Style ▸ Bar orientation now carry `mode: "theme"` /
// `mode: "barorientation"` (quick task 260822-sht, Task 5), routing to
// `PickerMode.qml` the same way Tools ▸ Clipboard routes to its own mode
// — neither is marked `placeholder` because their `mode` is real, not a
// stand-in for a future task.
pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property var roots: [
        {
            text: "  Apps",
            children: [
                {
                    text: "  Application list",
                    command: null,
                    mode: "apps"
                },
            ]
        },
        {
            text: "  Capture",
            children: [
                {
                    text: "  Region",
                    command: `~/.config/hypr/scripts/capture-region.sh`
                },
                {
                    text: "  Window",
                    command: `~/.config/hypr/scripts/capture-window.sh`
                },
                {
                    text: "  Full screen",
                    command: `~/.config/hypr/scripts/capture-full.sh`
                },
                {
                    text: "  Record toggle",
                    command: `~/.config/hypr/scripts/record-toggle.sh`
                },
            ]
        },
        {
            text: "  Tools",
            children: [
                {
                    // Superseded by EmojiMode.qml (quick task 260822-sht,
                    // Task 7) — `mode` wins over `command` in
                    // MenuMode.qml's activate(); `command` is kept
                    // byte-identical to the retired TOML action for the
                    // record, same precedent as Style ▸ Theme/Bar
                    // orientation above.
                    text: "  Emoji",
                    command: `~/.config/hypr/scripts/emoji-picker.sh`,
                    mode: "symbols"
                },
                {
                    text: "  Colour picker",
                    command: `~/.config/hypr/scripts/color-picker.sh`
                },
                {
                    text: "  Clipboard",
                    command: `cliphist list | walker --dmenu | cliphist decode | wl-copy`,
                    mode: "clipboard"
                },
                {
                    // New leaf, no retired TOML precedent (quick task
                    // 260822-sht, Task 6, consumer 4) — routes to
                    // ConfirmMode.qml's destructive-safe confirm, which
                    // invokes `clipboard-wipe.sh --yes` only on an
                    // explicit "Yes" pick.
                    text: "  Clipboard wipe",
                    command: null,
                    mode: "clipboardwipe"
                },
            ]
        },
        {
            text: "  Style",
            children: [
                {
                    text: "  Theme",
                    // Superseded by PickerMode (quick task 260822-sht,
                    // Task 5, consumer 1) — `mode` wins over `command` in
                    // MenuMode.qml's activate(); `command` is kept
                    // byte-identical to the retired TOML action for the
                    // record, same precedent as Tools ▸ Clipboard's own
                    // `mode`+stale-`command` pairing above.
                    command: `~/.config/hypr/scripts/theme-switch.sh`,
                    mode: "theme"
                },
                {
                    text: "  Wallpaper",
                    command: `~/.config/hypr/scripts/wallpaper-switch.sh`
                },
                {
                    text: "  Icon theme",
                    command: `~/.config/hypr/scripts/icon-theme-switch.sh`
                },
                {
                    text: "  Font",
                    command: `~/.config/hypr/scripts/font-switch.sh`
                },
                {
                    text: "  Bar orientation",
                    // Superseded by PickerMode (quick task 260822-sht,
                    // Task 5, consumer 6) — same `mode`+stale-`command`
                    // pairing as Theme above. `bar-orientation.sh` no
                    // longer has an interactive path, so this `command`
                    // is unreachable dead reference text now, not a live
                    // fallback.
                    command: `~/.config/hypr/scripts/bar-orientation.sh`,
                    mode: "barorientation"
                },
            ]
        },
        {
            text: "  Setup",
            children: [
                {
                    text: "  Settings",
                    command: `qs ipc call settings open`
                },
                {
                    text: "  Network",
                    command: `~/.config/hypr/scripts/nmtui-launch.sh`
                },
                {
                    text: "  Bluetooth",
                    command: `uwsm app -- blueman-manager`
                },
                {
                    text: "  Audio",
                    command: `uwsm app -- pavucontrol`
                },
                {
                    text: "  Display",
                    command: `uwsm app -- nwg-displays`
                },
            ]
        },
        {
            text: "  Play",
            children: [
                {
                    text: "  Steam",
                    command: `uwsm app -- steam`
                },
                {
                    text: "  Lutris",
                    command: `uwsm app -- gamemoderun mangohud lutris`
                },
                {
                    text: "  Heroic",
                    command: `uwsm app -- heroic`
                },
                {
                    text: "  ProtonUp-Qt",
                    command: `uwsm app -- protonup-qt`
                },
                {
                    text: "  Gaming mode",
                    command: `~/.config/hypr/scripts/gaming-mode-toggle.sh`
                },
            ]
        },
        {
            text: "  AI",
            children: [
                {
                    text: "  Claude",
                    command: `~/.config/hypr/scripts/ai-webapp-launch.sh https://claude.ai`
                },
                {
                    text: "  ChatGPT",
                    command: `~/.config/hypr/scripts/ai-webapp-launch.sh https://chatgpt.com`
                },
                {
                    text: "  Gemini",
                    command: `~/.config/hypr/scripts/ai-webapp-launch.sh https://gemini.google.com`
                },
                {
                    text: "  Perplexity",
                    command: `~/.config/hypr/scripts/ai-webapp-launch.sh https://perplexity.ai`
                },
                {
                    text: "  Claude Code",
                    command: `uwsm app -- kitty --class ai-claude-code --title "Claude Code" -- claude`
                },
                {
                    text: "  Local models",
                    command: `~/.config/hypr/scripts/ai-local-models.sh`
                },
                {
                    text: "  AI Workspace",
                    command: `~/.config/hypr/scripts/ai-workspace.sh`
                },
            ]
        },
        {
            text: "  Learn",
            children: [
                {
                    // Superseded by KeybindsMode.qml (quick task
                    // 260822-sht, Task 9) — `mode` wins over `command` in
                    // MenuMode.qml's activate(); `command` is kept
                    // byte-identical to the retired TOML action for the
                    // record, same precedent as every other superseded
                    // leaf above.
                    text: "  Keybinds",
                    command: `~/.config/hypr/scripts/cheat-sheet.sh`,
                    mode: "keybinds"
                },
            ]
        },
        {
            text: "  System",
            children: [
                {
                    text: "  Power",
                    command: `hyprctl dispatch 'hl.dsp.global("quickshell:power-menu")'`
                },
                {
                    text: "  Updates",
                    command: null,
                    mode: "updates"
                },
                {
                    text: "  System info",
                    command: null,
                    mode: "systeminfo"
                },
            ]
        },
    ]
}
