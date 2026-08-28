// CommandMode.qml — the `cmd` word route (quick task 260829-2ov): every leaf
// of `MenuTree.qml` flattened into ONE searchable list, so a command can be
// reached by name instead of by remembering which of the 9 verb roots holds
// it.
//
// ── WHY THIS IS NOT A MODE ON MenuMode.qml ────────────────────────────────
// `MenuMode.qml` BROWSES the tree: `LauncherState.navStack` holds the path,
// the search field filters the CURRENT LEVEL only, and `menu` is listed in
// `LauncherState._stickyModes` precisely so a keystroke there cannot re-route
// the surface (typing "c" to reach "Colour picker" must not fall through to
// the router's no-match branch). This file does the opposite on both counts —
// it ignores `navStack` entirely and it is an ordinary word route, so backing
// the query out of "cmd" returns to apps mode like `pkg`/`icon`/`font` do.
// Two different jobs, so two files rather than a second behaviour switch
// inside one.
//
// ── THE FOUR ACTIVATION BRANCHES ARE MenuMode's, IN MenuMode's ORDER ──────
// `workbench` -> `PackagesBackend.openWorkbench`, `appearance` ->
// `AppearanceBackend.openAtelier`, `mode` -> a `LauncherState.mode` handoff
// that does NOT dismiss, `command` -> `Quickshell.execDetached` + dismiss.
// Deliberately a copy of that ordering rather than a refactor of it: the two
// files would have to be changed together anyway, and re-homing MenuMode's
// `activate()` into a shared helper in the same commit that introduces a new
// surface means a regression here could not be told apart from a regression
// there. The "back" row has no analogue in a flat list, so it has no branch.
//
// `Quickshell.execDetached`, never a component-scoped `Process`: this surface
// is destroyed by its LazyLoader the instant the launcher dismisses, which
// would kill a child mid-flight — the exact failure 260822-sht recorded for
// theme switching, emoji typing and clipboard paste.
//
// ── THE WALK IS RECURSIVE THOUGH THE TREE IS NOT (YET) ────────────────────
// Every `children:` in `MenuTree.qml` today sits at one indentation level —
// 9 roots, 35 leaves, no deeper nesting. The walk below recurses anyway, so a
// future sub-submenu is searchable the day it is added rather than silently
// dropping out of this list with nothing going red.
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

    // Flat leaf list, built once off the singleton's own data. A node is a
    // SUBMENU when it has `children` and a LEAF otherwise — MenuTree.qml's
    // own schema, not a second definition of one.
    readonly property var _leaves: {
        const out = [];
        function walk(nodes, trail) {
            for (let i = 0; i < nodes.length; i++) {
                const n = nodes[i];
                if (n.children !== undefined) {
                    walk(n.children, trail.length > 0 ? trail + " ▸ " + n.text : n.text);
                    continue;
                }
                out.push({
                    node: n,
                    trail: trail,
                    // Scored as one string so both halves are searchable:
                    // "region" finds Capture ▸ Region and so does "capture".
                    haystack: trail + " " + (n.text || "")
                });
            }
        }
        walk(MenuTree.roots, "");
        return out;
    }

    // Empty query keeps the tree's own declaration order, which is the
    // useful default — it is the same order the Super-tap menu presents.
    readonly property var _rows: {
        const q = LauncherState.queryArg.trim();
        if (q.length === 0)
            return root._leaves;
        const scored = [];
        for (let i = 0; i < root._leaves.length; i++) {
            const s = Fuzzy.score(q, root._leaves[i].haystack);
            if (s >= 0)
                scored.push({
                    row: root._leaves[i],
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

    function activate() {
        const row = root._rows[root.currentIndex];
        if (!row)
            return;
        const node = row.node;

        if (node.workbench) {
            PackagesBackend.openWorkbench("", node.workbench);
            if (typeof root.dismissCallback === "function")
                root.dismissCallback();
            return;
        }

        if (node.appearance) {
            AppearanceBackend.openAtelier(node.appearance);
            if (typeof root.dismissCallback === "function")
                root.dismissCallback();
            return;
        }

        // A mode handoff swaps the results Loader and leaves the surface up,
        // exactly as it does from the menu — but the query has to be cleared
        // first. It still reads "cmd theme" at this instant, and the mode it
        // hands off to (a PickerMode, the emoji grid, the clipboard list)
        // filters ITSELF on that text; leaving it in place would open the
        // picker pre-filtered to a string the user typed to FIND the picker.
        // MenuMode does not need this because a menu row is picked with an
        // empty level filter far more often than not.
        if (node.mode) {
            LauncherState.query = "";
            LauncherState.mode = node.mode;
            return;
        }

        if (node.command) {
            Quickshell.execDetached(["sh", "-c", node.command]);
            if (typeof root.dismissCallback === "function")
                root.dismissCallback();
        }
    }

    ListView {
        id: commandListView
        anchors.fill: parent
        clip: true
        interactive: false
        model: root._rows
        currentIndex: root.currentIndex

        delegate: Rectangle {
            id: commandDelegate
            required property var modelData
            required property int index

            width: commandListView.width
            height: 40
            radius: 8
            color: root.currentIndex === commandDelegate.index ? Colours.surfaceVariant : "transparent"

            // The leaf's own name leads; its root sits right-aligned as a
            // quieter category column. Both are `MenuTree.qml` strings with
            // Font Awesome Private Use Area codepoints baked in, so both need
            // the Nerd Font — the default application font renders that range
            // as tofu, which is `MenuMode.qml`'s own recorded finding.
            Text {
                id: leafLabel
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: 12
                anchors.right: trailLabel.left
                anchors.rightMargin: Design.spacingSm
                text: commandDelegate.modelData.node.text || ""
                color: Colours.onSurface
                font.family: "FiraCode Nerd Font"
                font.pixelSize: 15
                elide: Text.ElideRight
            }

            Text {
                id: trailLabel
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.rightMargin: 12
                // Never wider than half the row: a long breadcrumb must not
                // squeeze the name it is qualifying down to an ellipsis.
                width: Math.min(implicitWidth, commandDelegate.width / 2)
                horizontalAlignment: Text.AlignRight
                text: commandDelegate.modelData.trail
                color: Colours.onSurfaceVariant
                font.family: "FiraCode Nerd Font"
                font.pixelSize: 13
                elide: Text.ElideLeft
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    root.currentIndex = commandDelegate.index;
                    root.activate();
                }
            }
        }
    }
    // Scroll indicator (quick task 260828-pol). Sibling of the view, never a
    // child: a Flickable/ListView appends Item children to its scrolled
    // contentItem, so a bar declared inside scrolls away.
    ThemedScrollBar {
        flickable: commandListView
    }
}
