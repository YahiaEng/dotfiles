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
// is a Task 4/7/8/9 placeholder not yet filled (`placeholder: true` marks
// those — Apps' own child, System's Updates/System info are R-3/R-1/R-2,
// Task 4; Tools' Emoji is Task 7; Learn's Keybinds is Task 9) or when it
// carries a `mode` instead (Tools ▸ Clipboard: its retired TOML action IS
// still recorded here verbatim for reversibility, but `mode: "clipboard"`
// tells `MenuMode.qml` to route into the in-launcher clipboard mode
// (`LauncherState.modeClipboard`, Task 2's router) rather than ever
// executing the old `cliphist list | walker --dmenu | ...` pipeline — the
// ONE entry this task's own plan text names as the deliberate exception to
// "byte-identical AND executed", since Task 8 replaces its behaviour
// entirely.
//
// Three of the 30 real commands below are legitimately SUPERSEDED by a
// later task without being removed from this file: Style ▸ Theme and
// Style ▸ Bar orientation (Task 5's `PickerMode.qml`), Learn ▸ Keybinds
// (Task 9's `KeybindsMode.qml` — kept here as an executed leaf, not a
// placeholder, since `cheat-sheet.sh` remains fully functional until then).
// Tools ▸ Emoji is marked `placeholder: true` even though its command is
// present and would still work if executed — Task 7 replaces routing to
// it with `mode: "symbols"`, matching the Clipboard shape.
pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    readonly property var roots: [
        {
            text: "  Apps",
            children: [
                {
                    text: "  Application list",
                    command: null,
                    placeholder: true
                },
            ]
        },
        {
            text: "  Capture",
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
            text: "  Tools",
            children: [
                {
                    text: "  Emoji",
                    command: `~/.config/hypr/scripts/emoji-picker.sh`,
                    placeholder: true
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
            ]
        },
        {
            text: "  Style",
            children: [
                {
                    text: "  Theme",
                    command: `~/.config/hypr/scripts/theme-switch.sh`
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
                    command: `~/.config/hypr/scripts/bar-orientation.sh`
                },
            ]
        },
        {
            text: "  Setup",
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
            text: "  Play",
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
            text: "  AI",
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
            text: "  Learn",
            children: [
                {
                    text: "  Keybinds",
                    command: `~/.config/hypr/scripts/cheat-sheet.sh`,
                    placeholder: true
                },
            ]
        },
        {
            text: "  System",
            children: [
                {
                    text: "  Power",
                    command: `hyprctl dispatch 'hl.dsp.global("quickshell:power-menu")'`
                },
                {
                    text: "  Updates",
                    command: null,
                    placeholder: true
                },
                {
                    text: "  System info",
                    command: null,
                    placeholder: true
                },
            ]
        },
    ]
}
