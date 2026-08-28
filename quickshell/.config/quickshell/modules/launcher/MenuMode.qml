// MenuMode.qml — the menu drill-in rows view (quick task 260822-sht, Task
// 3). Reads `MenuTree.qml`'s 9-root data model; `LauncherState.navStack`
// (Task 1, declared empty, this task's own seam) holds the path from root
// to the currently-displayed submenu.
//
// D-2's three adopted Omarchy affordances, and nothing else (this task's
// own plan text — "do not adopt the bash architecture"):
//   - per-menu placeholder text — TODO wiring point, left for a future
//     task since no menu in this tree currently needs one beyond the
//     shared "Search…" default (none of D-2's roots carry Omarchy's own
//     `-p` per-submenu placeholders).
//   - Nerd Font glyphs already baked into MenuTree.qml's own `text`
//     strings (`Fuzzy` needs no icon-aware special-casing — it scores the
//     whole string, glyph included, which is harmless since the glyph is
//     the same one private-use codepoint on every row and contributes an
//     identical, negligible score delta).
//   - preselect-the-current-value — the STRUCTURAL seam only: a leaf may
//     declare `preselect: function` returning the row index to highlight
//     on open. No leaf in THIS task's tree uses it yet (Style's Theme/Bar
//     orientation leaves are superseded by Task 5's `PickerMode.qml`
//     before preselect would ever apply to them here) — declared now so
//     a future leaf can opt in without a MenuMode.qml change.
//
// Typed-input preservation across levels is a structural side effect of
// this being a real QML tree walked in place, not Omarchy's own
// per-level dmenu-picker respawn pattern — nothing here has to
// reimplement it.
//
// `dismissCallback` is a plain function-valued property injected by
// Launcher.qml's own `menuComponent` (`MenuMode { dismissCallback:
// launcherWindow._beginDismiss }`) — evaluated in Launcher.qml's OWN
// lexical scope where `launcherWindow` is visible, then handed down as a
// property value, since MenuMode.qml lives in a separate file and cannot
// reference `launcherWindow`'s id directly. Executing a leaf command is
// the one action in this file that closes the whole launcher (mirrors
// `launchCurrent()`'s own app-launch-then-dismiss shape); drilling in,
// going back, and routing to a `mode` all keep the surface open.
import QtQuick
import Quickshell
import ".."
import "."
import "../packages"
import "../appearance"
import "fuzzy.js" as Fuzzy

Item {
    id: root

    width: parent ? parent.width : 0
    height: Math.min(360, Math.max(root.count, 1) * 40)

    property var dismissCallback: null

    readonly property bool _atRoot: LauncherState.navStack.length === 0
    readonly property var _currentChildren: root._atRoot ? MenuTree.roots : (LauncherState.navStack[LauncherState.navStack.length - 1].children || [])

    // Rows = an optional pinned "‹ Back" row (any depth below root) plus
    // the current level's nodes, fuzzy-filtered by the shared search field
    // against each node's own `text` — same `Fuzzy.score()` apps mode
    // uses, so typing inside a submenu narrows it exactly like typing in
    // apps mode narrows the app list.
    readonly property var _rows: {
        const q = LauncherState.query.trim();
        let nodes = root._currentChildren;
        if (q.length > 0) {
            const scored = [];
            for (let i = 0; i < nodes.length; i++) {
                const s = Fuzzy.score(q, nodes[i].text || "");
                if (s >= 0)
                    scored.push({
                        node: nodes[i],
                        _score: s
                    });
            }
            scored.sort(function (a, b) {
                return b._score - a._score;
            });
            nodes = scored.map(function (s) {
                return s.node;
            });
        }
        const rows = [];
        if (!root._atRoot)
            rows.push({
                _kind: "back"
            });
        for (let i = 0; i < nodes.length; i++)
            rows.push(nodes[i]);
        return rows;
    }

    property int currentIndex: 0
    readonly property int count: root._rows.length
    onCountChanged: root.currentIndex = 0

    function _goBack() {
        const stack = LauncherState.navStack.slice();
        stack.pop();
        LauncherState.navStack = stack;
        LauncherState.query = "";
    }

    function activate() {
        const row = root._rows[root.currentIndex];
        if (!row)
            return;

        if (row._kind === "back") {
            root._goBack();
            return;
        }

        if (row.children !== undefined) {
            LauncherState.navStack = LauncherState.navStack.concat([row]);
            LauncherState.query = "";
            return;
        }

        // Mode handoff (Tools ▸ Clipboard, and future Apps/Emoji/Keybinds
        // leaves once Task 4/7/9 flip their nodes from `placeholder` to a
        // real `mode` target) — switches the results Loader without
        // closing the launcher, exactly like typing a route prefix does.
        // A leaf that opens the package workbench (quick task 260828-75k,
        // operator round 2). A direct call rather than a `command`
        // shelling out to `qs ipc call packages-window open`: the launcher
        // already resolves PackagesBackend, so spawning a process for the
        // shell to talk to itself would be pure cost — and `command` goes
        // through `sh -c`, which this leaf has no need of.
        if (row.workbench) {
            PackagesBackend.openWorkbench("", row.workbench);
            if (typeof root.dismissCallback === "function")
                root.dismissCallback();
            return;
        }

        // Style ▸ Icon theme / Style ▸ Font (quick task 260828-ah9, D-01)
        // — same direct-call shape `row.workbench` already established
        // above: the launcher already resolves AppearanceBackend, so
        // asking the shell to talk to itself over `qs ipc call` would be
        // pure cost.
        if (row.appearance) {
            AppearanceBackend.openAtelier(row.appearance);
            if (typeof root.dismissCallback === "function")
                root.dismissCallback();
            return;
        }

        if (row.mode) {
            LauncherState.mode = row.mode;
            return;
        }

        if (row.command) {
            Quickshell.execDetached(["sh", "-c", row.command]);
            if (typeof root.dismissCallback === "function")
                root.dismissCallback();
        }
    }

    ListView {
        id: menuListView
        anchors.fill: parent
        clip: true
        interactive: false
        model: root._rows
        currentIndex: root.currentIndex

        delegate: Rectangle {
            id: menuDelegate
            required property var modelData
            required property int index

            width: menuListView.width
            height: 40
            radius: 8
            color: root.currentIndex === menuDelegate.index ? Colours.surfaceVariant : "transparent"

            Text {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: 12
                text: menuDelegate.modelData._kind === "back" ? "‹ Back" : (menuDelegate.modelData.text || "")
                color: menuDelegate.modelData._kind === "back" ? Colours.onSurfaceVariant : Colours.onSurface
                // MenuTree.qml's `text` strings carry Font Awesome-range
                // Private Use Area codepoints baked in (D-2's own "Nerd
                // Font glyphs already baked into the entry strings"
                // affordance, copied verbatim from the retired TOMLs) —
                // Qt's default application font has no glyphs for that
                // range and silently renders tofu/blank. `FiraCode Nerd
                // Font` is this host's own installed Nerd Font (kitty's
                // own `font_family`, `kitty/.config/kitty/kitty.conf:12`)
                // and covers the Font Awesome PUA range these glyphs use.
                font.family: "FiraCode Nerd Font"
                font.pixelSize: 15
                elide: Text.ElideRight
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    root.currentIndex = menuDelegate.index;
                    root.activate();
                }
            }
        }
    }
}
