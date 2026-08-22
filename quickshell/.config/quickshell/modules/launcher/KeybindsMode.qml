// KeybindsMode.qml — Learn ▸ Keybinds table result view (quick task
// 260822-sht, Task 9, Stage 2 dmenu-consumer migration, consumer 3 of 7).
// D-1's table result view.
//
// Live-parsed on every open via `cheat-sheet-parser.sh --dump`
// (Task 9's own new guarded direct-execution path), never cached (D-31)
// — a fresh `Component.onCompleted` re-runs the parser every time this
// mode is entered, the same "parse live, every call" discipline the
// retired `cheat-sheet.sh` and `cheat-sheet-view-all.sh` both already
// honoured by SOURCING the shared parser rather than caching its output.
//
// Row format locked by UI-SPEC, reused verbatim from the retired surface:
// "{Chord} — {Description}", description text reused VERBATIM from
// keybinds.lua (never paraphrased).
//
// ── T-07-26 (hard requirement) — this is a reference, not a launcher ────
// Selecting an ordinary keybind row copies its chord to the clipboard and
// NEVER executes that bind's dispatcher. The parsed row objects below
// carry ONLY `_kind`, `chord`, `desc` — there is no command/exec field on
// an ordinary row AT ALL, so invoking one is structurally impossible, not
// merely avoided by an `if` this file could get wrong later. The pinned
// "View all keybinds ›" row is the SINGLE exception, and `activate()`
// dispatches it by checking `row._kind === "viewall"` (identity), never
// by reading a command string out of the row model.
//
// Duck-typed interface Launcher.qml's generic keyboard-nav glue reads:
// `currentIndex`, `count`, `activate()`.
import QtQuick
import Quickshell
import Quickshell.Io
import ".."
import "."
import "fuzzy.js" as Fuzzy

Item {
    id: root

    width: parent ? parent.width : 0
    height: Math.min(360, Math.max(root.count, 1) * 40)

    property var dismissCallback: null

    // Pinned first, own `_kind` — never carries `chord`/`desc`, so it can
    // never be mistaken for an ordinary row by any code path that reads
    // those fields.
    readonly property var _pinnedRow: ({
            _kind: "viewall",
            _text: "View all keybinds ›"
        })

    property var _parsedRows: []

    function _refresh() {
        dumpProcess.running = false;
        dumpProcess.running = true;
    }

    Component.onCompleted: root._refresh()

    Process {
        id: dumpProcess
        command: [Quickshell.env("HOME") + "/.config/hypr/scripts/cheat-sheet-parser.sh", "--dump"]
        stdout: StdioCollector {
            id: dumpCollector
        }
        onExited: exitCode => {
            const lines = exitCode === 0 ? (dumpCollector.text || "").split("\n").filter(function (l) {
                return l.length > 0;
            }) : [];
            const rows = [];
            for (let i = 0; i < lines.length; i++) {
                const parts = lines[i].split("\t");
                if (parts.length !== 3)
                    continue;
                const chord = parts[1];
                const desc = parts[2];
                // Structurally no command/exec field — T-07-26.
                rows.push({
                    _kind: "bind",
                    _text: chord + " — " + desc,
                    chord: chord,
                    desc: desc
                });
            }
            root._parsedRows = rows;
        }
    }

    // Same Fuzzy.score()-based filter+sort MenuMode.qml's own submenu
    // filter uses, applied to each row's own display text — the pinned
    // row is a normal row in this array (first, so it holds that
    // position at an empty query, and still reachable by typing "view",
    // exactly matching the retired surface's own per-row walker --dmenu
    // matching).
    readonly property var _rows: {
        const all = [root._pinnedRow].concat(root._parsedRows);
        const q = LauncherState.query.trim();
        if (q.length === 0)
            return all;
        const scored = [];
        for (let i = 0; i < all.length; i++) {
            const s = Fuzzy.score(q, all[i]._text);
            if (s >= 0)
                scored.push({
                    row: all[i],
                    _score: s
                });
        }
        scored.sort(function (a, b) {
            return b._score - a._score;
        });
        return scored.map(function (s) {
            return s.row;
        });
    }

    property int currentIndex: 0
    readonly property int count: root._rows.length
    onCountChanged: root.currentIndex = 0

    // ── Bug 1 fix (quick task 260822-sht) ────────────────────────────────
    // Both commands below are fire-and-forget CLI invocations (neither
    // reads stdin, and this file never needs their stdout/exit code
    // back), so `Quickshell.execDetached` — same fix as PickerMode.qml's
    // own header — spawns them independent of this Item's lifetime.
    // `dismissCallback()` a few lines down tears down this whole surface
    // (and every child `Process` on it) via shell.qml's LazyLoader the
    // instant it fires; `cheat-sheet-view-all.sh` opens its own kitty
    // window, slower than that teardown, which is why "selecting 'View
    // all keybinds' does nothing" was reported — a plain `Process` died
    // before the window ever opened.
    function activate() {
        const row = root._rows[root.currentIndex];
        if (!row)
            return;

        if (row._kind === "viewall")
            Quickshell.execDetached([Quickshell.env("HOME") + "/.config/hypr/scripts/cheat-sheet-view-all.sh"]);
        else
            Quickshell.execDetached(["wl-copy", row.chord]);

        if (typeof root.dismissCallback === "function")
            root.dismissCallback();
    }

    ListView {
        id: keybindsListView
        anchors.fill: parent
        clip: true
        interactive: false
        model: root._rows
        currentIndex: root.currentIndex

        delegate: Rectangle {
            id: keybindDelegate
            required property var modelData
            required property int index

            width: keybindsListView.width
            height: 40
            radius: 8
            color: root.currentIndex === keybindDelegate.index ? Colours.surfaceVariant : "transparent"

            Text {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: 12
                text: keybindDelegate.modelData._text
                color: keybindDelegate.modelData._kind === "viewall" ? Colours.primary : Colours.onSurface
                font.pixelSize: 13
                elide: Text.ElideRight
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    root.currentIndex = keybindDelegate.index;
                    root.activate();
                }
            }
        }
    }
}
