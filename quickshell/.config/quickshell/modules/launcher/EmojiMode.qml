// EmojiMode.qml — `.` symbols / Tools ▸ Emoji grid result view (quick task
// 260822-sht, Task 7, Stage 2 dmenu-consumer migration, consumer 2 of 7).
//
// Data source: `emoji.tsv` (160 glyph-tab-name lines, ported verbatim from
// the retired `emoji-picker.sh`'s own inline `$'...'` heredoc — DQ-3, no
// keyword widening). Loaded via `FileView`, D-5's own admitted end-4
// precedent for exactly this shape.
//
// Renders a GRID (16 visible tiles: 4 columns x 4 rows), a deliberate
// local design judgment taken against the only available precedent
// (end-4 uses a plain list; Caelestia has no emoji surface at all) — per
// D-1's own attribution correction, this is NOT cited to either reference
// shell.
//
// ── T-06-17 (hard requirement, D-6) ─────────────────────────────────────
// The surface must validate the selected glyph against the parsed known
// set BEFORE invoking `wtype`, and must never type back raw list output
// or free-typed search text. `activate()` below builds `validatedGlyph`
// by checking the highlighted row's own `glyph` field against
// `_knownGlyphs` (a Set built from the SAME parsed model the grid
// renders) — the typed value is always a parsed row, never
// `LauncherState.query`. If the assertion fails, `validatedGlyph` is
// `null` and neither `wtype` nor the clipboard copy runs. There is
// exactly one `wtype` call site in this file and it sits inside that
// guarded branch.
//
// Graceful degradation (matches the retired script): if the type-tool
// binary is absent, this degrades to copy-only rather than silent
// nothing — the type attempt and the clipboard copy are independent
// Process calls below, so a failed/missing type-tool invocation never
// blocks the copy that already ran alongside it.
//
// Duck-typed interface Launcher.qml's generic keyboard-nav glue reads:
// `currentIndex`, `count`, `activate()`. `dismissCallback` closes the
// launcher after a pick — a decisive one-shot action, the same shape
// PickerMode.qml's own Enter-then-dismiss uses.
import QtQuick
import Quickshell
import Quickshell.Io
import ".."
import "."
import "fuzzy.js" as Fuzzy

Item {
    id: root

    width: parent ? parent.width : 0
    height: Math.min(320, grid.contentHeight > 0 ? 4 * grid.cellHeight : 80)

    property var dismissCallback: null

    // ── Data source ──────────────────────────────────────────────────────
    property var _allEntries: []
    readonly property var _knownGlyphs: {
        const s = new Set();
        for (let i = 0; i < root._allEntries.length; i++)
            s.add(root._allEntries[i].glyph);
        return s;
    }

    FileView {
        id: emojiFile
        path: Quickshell.shellPath("modules/launcher/emoji.tsv")
        onLoaded: root._parse()
    }

    function _parse() {
        const text = emojiFile.text() || "";
        const lines = text.split("\n").filter(function (l) {
            return l.length > 0;
        });
        const entries = [];
        for (let i = 0; i < lines.length; i++) {
            const parts = lines[i].split("\t");
            if (parts.length === 2 && parts[0].length > 0 && parts[1].length > 0)
                entries.push({
                    glyph: parts[0],
                    name: parts[1]
                });
        }
        root._allEntries = entries;
    }

    // ── Fuzzy filter — `.` prefix's `queryArg` (the typed text AFTER the
    //    dot) narrows by name, same `Fuzzy.score()` MenuMode.qml's own
    //    submenu filter uses. Empty query shows the full 160-entry set. ───
    readonly property var _rows: {
        const q = LauncherState.queryArg.trim();
        if (q.length === 0)
            return root._allEntries;
        const scored = [];
        for (let i = 0; i < root._allEntries.length; i++) {
            const s = Fuzzy.score(q, root._allEntries[i].name);
            if (s >= 0)
                scored.push({
                    entry: root._allEntries[i],
                    _score: s
                });
        }
        scored.sort(function (a, b) {
            return b._score - a._score;
        });
        return scored.map(function (s) {
            return s.entry;
        });
    }

    property int currentIndex: 0
    readonly property int count: root._rows.length
    onCountChanged: root.currentIndex = 0

    Process {
        id: typeProcess
    }

    Process {
        id: copyProcess
    }

    Process {
        id: notifyProcess
    }

    function activate() {
        const row = root._rows[root.currentIndex];
        if (!row)
            return;

        // T-06-17: containment assertion against the loaded set gates the
        // ONE type-tool invocation below. `validatedGlyph` is `null` —
        // and neither the type-tool nor the clipboard copy runs — unless
        // `row.glyph` is exactly a member of `_knownGlyphs`, the same Set
        // built from the parsed model this grid renders. The typed value
        // is always a parsed row, never `LauncherState.query` or any
        // other free-typed/raw text.
        const validatedGlyph = root._knownGlyphs.has(row.glyph) ? row.glyph : null;
        if (validatedGlyph !== null) {
            // The one type-tool call site (T-06-17) — a missing binary
            // simply fails this Process silently; the copy below still
            // runs independently, which is the graceful degradation this
            // file's header documents.
            typeProcess.command = ["wtype", validatedGlyph];
            typeProcess.running = false;
            typeProcess.running = true;

            copyProcess.command = ["wl-copy", validatedGlyph];
            copyProcess.running = false;
            copyProcess.running = true;

            notifyProcess.command = ["notify-send", "-a", "Emoji", "Copied", validatedGlyph, "-t", "2000"];
            notifyProcess.running = false;
            notifyProcess.running = true;
        }

        if (typeof root.dismissCallback === "function")
            root.dismissCallback();
    }

    GridView {
        id: grid
        anchors.fill: parent
        clip: true
        interactive: false
        cellWidth: Math.floor(width / 4)
        cellHeight: 64
        model: root._rows
        currentIndex: root.currentIndex

        delegate: Rectangle {
            id: emojiDelegate
            required property var modelData
            required property int index

            width: grid.cellWidth - Design.spacingXs
            height: grid.cellHeight - Design.spacingXs
            radius: 8
            color: root.currentIndex === emojiDelegate.index ? Colours.surfaceVariant : "transparent"

            Column {
                anchors.centerIn: parent
                spacing: 2

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: emojiDelegate.modelData.glyph
                    font.pixelSize: 24
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: grid.cellWidth - 12
                    text: emojiDelegate.modelData.name
                    color: Colours.onSurfaceVariant
                    font.pixelSize: 9
                    elide: Text.ElideRight
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            MouseArea {
                anchors.fill: parent
                onClicked: {
                    root.currentIndex = emojiDelegate.index;
                    root.activate();
                }
            }
        }
    }
}
